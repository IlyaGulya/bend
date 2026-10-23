import Base
import ./ast.bend as Ast
import ./checker_arena.bend as Arena
import ./checker_ir.bend as IR
import ./path.bend as Path
import ./template.bend as Template
import ./loaded_module.bend as Loader
import ./index_lookup.bend as IndexLookup
import ./scope_lookup.bend as Scope

type Diagnostic is Data:
  Diagnostic{file: String, span: Ast.SourceSpan, message: String, expected: String, observed: String}
type CheckResult is Data:
  CheckSuccess{modules: List<&2, Loader.LoadedModule>}
  CheckFailure{diagnostic: Diagnostic}
type PrivateResult is Data:
  PrivateSuccess{modules: List<&2, IR.LoadedModule>}
  PrivateFailure{diagnostic: Diagnostic}
type ArenaStore is Type:
  ArenaStore{source: Arena.Arena, transient: Arena.Arena}
type ArenaResult<-T: Type> is Type:
  ArenaResult{store: ArenaStore, value: T}
type CasePrefixBuild is Type:
  CasePrefixBuild{start: U32, count: U32, cursor: U32, offset: U32, remaining: Nat, heads: Map<&2, U32>}
type CasePrefixSelect is Type:
  CasePrefixSelect{cases: IR.Words, scrutinees: IR.Words, argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope, heads: Map<&2, U32>, offset: U32}
type PatternRowIndex is Data:
  PatternRowIndex{rows: List<&2, IR.Words>, heads: Map<&2, List<&2, IR.Words>>, other: List<&2, IR.Words>, ranks: Map<&2, List<&2, Nat>>, other_ranks: List<&2, Nat>, count: Nat}
type PatternRowSelection is Data:
  PatternRowSelection{rows: List<&2, IR.Words>, ranks: List<&2, Nat>}
type Binding is Data:
  Binding{key: String, quantity: Ast.Quantity, ty: U32, type_depth: Nat}
type UsageEntry is Data:
  Usage{index: Nat, quantity: Ast.Quantity}
type TermOrder is Data:
  OrderLess{}
  OrderEqual{}
  OrderGreater{}
type Inference is Data:
  Inferred{term: U32, ty: U32}
  InferenceFailure{diagnostic: Diagnostic}
type ScrutineeTyping is Data:
  ScrutineeTypes{types: IR.Words}
  ScrutineeTypeFailure{diagnostic: Diagnostic}
type PatternTyping is Data:
  PatternTyped{env: List<&2, Binding>, value: U32}
  PatternTypeFailure{diagnostic: Diagnostic}
type CheckedLocalEnv is Data:
  CheckedLocalEnv{env: List<&2, Binding>}
  CheckedLocalEnvFailure{diagnostic: Diagnostic}
type PatternFields is Data:
  PatternFieldsTyped{env: List<&2, Binding>, values: IR.Words, result: U32}
  PatternFieldsFailure{diagnostic: Diagnostic}
type FamilyLowering is Data:
  FamilyTerm{term: U32}
  FamilyFailure{diagnostic: Diagnostic}
type State is Data:
  State{globals: List<&2, Scope.ArenaGlobal>}
  StateFailure{diagnostic: Diagnostic}
type ScopedState is Data:
  ScopedState{globals: Scope.ArenaGlobalScope}
  ScopedStateFailure{diagnostic: Diagnostic}
type DefinitionElaboration is Data:
  DefinitionElaborated{definition: IR.Definition}
  DefinitionElaborationFailure{diagnostic: Diagnostic}
type Declarations is Data:
  DeclarationsChecked{globals: List<&2, Scope.ArenaGlobal>, declarations: List<&2, IR.TopLevel>}
  DeclarationsFailure{diagnostic: Diagnostic}
type PatternReduction is Data:
  PatternValues{values: IR.Words}
  PatternMismatch{}
  PatternStuck{}
type ScalarLiteralNames is Data:
  ScalarLiteralNames{word: Maybe<&2, U32>, first_bit: Maybe<&2, U32>, second_bit: Maybe<&2, U32>}
type ScalarLiteralBit is Data:
  ScalarLiteralBit{names: ScalarLiteralNames, valid: Bool}

# Private algorithms use handles and flat tape cursors. These are mechanically
# state-threaded versions of the original checker, Core, and Scope algorithms;
# no computed type, substitution, match, or normalization result is memoized.

def span_file(v_0: Ast.SourceSpan) -> String:
  match v_0:
    case Ast.SpanOf{+v_20032506, +v_20032507, +v_20032508}:
      v_5 = v_20032506
      v_5

def term_span(v_20032509: ArenaStore, v_0: U32) -> ArenaResult<Ast.SourceSpan>:
  ArenaResult{v_20032510, +v_20032511} = arena_get_node(v_20032509, v_0)
  match v_20032511:
    case Arena.TermVar{+v_20032512, +v_20032514, +v_20032515}:
      v_6 = v_20032515
      {ArenaResult{v_20032510, v_6} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermRef{+v_20032516, +v_20032518}:
      v_10 = v_20032518
      {ArenaResult{v_20032510, v_10} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermBang{+v_20032519, +v_20032520}:
      v_14 = v_20032520
      {ArenaResult{v_20032510, v_14} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermSub{+v_20032521, +v_20032522, +v_20032523, +v_20032524}:
      v_22 = v_20032524
      {ArenaResult{v_20032510, v_22} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermLet{+v_20032525, +v_20032526, +v_20032528, +v_20032529, +v_20032531, +v_20032532, +v_20032534, +v_20032535, +v_20032537, +v_20032538}:
      v_34 = v_20032538
      {ArenaResult{v_20032510, v_34} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermAnn{+v_20032539, +v_20032540, +v_20032541}:
      v_40 = v_20032541
      {ArenaResult{v_20032510, v_40} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermTemplate{+v_20032542, +v_20032543}:
      v_44 = v_20032543
      {ArenaResult{v_20032510, v_44} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermType{+v_20032544, +v_20032545}:
      v_48 = v_20032545
      {ArenaResult{v_20032510, v_48} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermQuant{}:
      {ArenaResult{v_20032510, Ast.SpanOf{"", 0n, 0n}} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermQuantity{+v_20032546, +v_20032547}:
      v_52 = v_20032547
      {ArenaResult{v_20032510, v_52} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermMin{+v_20032548, +v_20032549, +v_20032550}:
      v_58 = v_20032550
      {ArenaResult{v_20032510, v_58} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermAll{+v_20032551, +v_20032552, +v_20032554, +v_20032555, +v_20032556, +v_20032557}:
      v_70 = v_20032557
      {ArenaResult{v_20032510, v_70} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermLam{+v_20032558, +v_20032559, +v_20032561, +v_20032562, +v_20032563}:
      v_80 = v_20032563
      {ArenaResult{v_20032510, v_80} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermApp{+v_20032564, +v_20032565, +v_20032566}:
      v_86 = v_20032566
      {ArenaResult{v_20032510, v_86} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermAdt{+v_20032567, +v_20032569, +v_20032570, +v_20032572, +v_20032573, +v_20032575}:
      v_94 = v_20032575
      {ArenaResult{v_20032510, v_94} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermFill{+v_20032576, +v_20032577, +v_20032578, +v_20032580}:
      v_100 = v_20032580
      {ArenaResult{v_20032510, v_100} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermPlus{+v_20032581, +v_20032582, +v_20032583, +v_20032585}:
      v_106 = v_20032585
      {ArenaResult{v_20032510, v_106} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermString{_, _, span}:
      {ArenaResult{v_20032510, span} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermCtr{+v_20032586, +v_20032588, +v_20032589, +v_20032591}:
      v_112 = v_20032591
      {ArenaResult{v_20032510, v_112} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermMat{+v_20032592, +v_20032594, +v_20032595, +v_20032596}:
      v_120 = v_20032596
      {ArenaResult{v_20032510, v_120} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermAbsurd{+v_20032597}:
      v_122 = v_20032597
      {ArenaResult{v_20032510, v_122} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermEqual{+v_20032598, +v_20032599, +v_20032600, +v_20032601}:
      v_130 = v_20032601
      {ArenaResult{v_20032510, v_130} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermRefl{+v_20032602}:
      v_132 = v_20032602
      {ArenaResult{v_20032510, v_132} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermRewrite{+v_20032603, +v_20032604, +v_20032605, +v_20032606}:
      v_140 = v_20032606
      {ArenaResult{v_20032510, v_140} : ArenaResult<Ast.SourceSpan>}
    case Arena.TermHole{+v_20032607, +v_20032609}:
      v_144 = v_20032609
      {ArenaResult{v_20032510, v_144} : ArenaResult<Ast.SourceSpan>}
    case Arena.BodyMatch{+v_20032610, +v_20032611, +v_20032613, +v_20032614, +v_20032616}:
      v_150 = v_20032616
      {ArenaResult{v_20032510, v_150} : ArenaResult<Ast.SourceSpan>}
    case Arena.BodyCase{+v_20032617, +v_20032618, +v_20032620, +v_20032621}:
      v_156 = v_20032621
      {ArenaResult{v_20032510, v_156} : ArenaResult<Ast.SourceSpan>}
    case Arena.BodyLocal{+v_20032622, +v_20032623, +v_20032625, +v_20032626, +v_20032627, +v_20032629, +v_20032630}:
      v_166 = v_20032630
      {ArenaResult{v_20032510, v_166} : ArenaResult<Ast.SourceSpan>}
    case Arena.BodyReply{+v_20032631, +v_20032632}:
      v_170 = v_20032632
      {ArenaResult{v_20032510, v_170} : ArenaResult<Ast.SourceSpan>}

def fail(+v_0: Ast.SourceSpan, v_2: String, v_4: String, v_6: String) -> Inference:
  v_50000000 = span_file(v_0)
  v_50000001 = Diagnostic{v_50000000, v_0, v_2, v_4, v_6}
  InferenceFailure{v_50000001}

def same_quantity(v_0: Ast.Quantity, v_1: Ast.Quantity) -> Bool:
  match v_0:
    case Ast.QZero{}:
      match v_1:
        case Ast.QZero{}:
          True{}
        case _:
          False{}
    case Ast.QOne{}:
      match v_1:
        case Ast.QOne{}:
          True{}
        case _:
          False{}
    case Ast.QMany{}:
      match v_1:
        case Ast.QMany{}:
          True{}
        case _:
          False{}
    case _:
      False{}

def quantity_join(v_0: Ast.Quantity, v_1: Ast.Quantity) -> Ast.Quantity:
  match v_0:
    case Ast.QMany{}:
      Ast.QMany{}
    case Ast.QOne{}:
      match v_1:
        case Ast.QMany{}:
          Ast.QMany{}
        case Ast.QOne{}:
          Ast.QMany{}
        case _:
          v_0
    case Ast.QZero{}:
      match v_1:
        case Ast.QMany{}:
          Ast.QMany{}
        case _:
          v_1
    case _:
      match v_1:
        case Ast.QMany{}:
          Ast.QMany{}
        case _:
          v_0

def quantity_alternative(v_0: Ast.Quantity, v_1: Ast.Quantity) -> Ast.Quantity:
  match v_0:
    case Ast.QMany{}:
      Ast.QMany{}
    case Ast.QZero{}:
      match v_1:
        case Ast.QMany{}:
          Ast.QMany{}
        case Ast.QZero{}:
          v_1
        case _:
          v_1
    case _:
      match v_1:
        case Ast.QMany{}:
          Ast.QMany{}
        case Ast.QZero{}:
          v_0
        case _:
          Ast.QOne{}

def quantity_fits(v_0: Ast.Quantity, v_1: Ast.Quantity) -> Bool:
  match v_0:
    case Ast.QZero{}:
      True{}
    case Ast.QOne{}:
      match v_1:
        case Ast.QZero{}:
          False{}
        case Ast.QOne{}:
          True{}
        case _:
          True{}
    case Ast.QMany{}:
      match v_1:
        case Ast.QZero{}:
          False{}
        case Ast.QOne{}:
          False{}
        case _:
          True{}
    case _:
      True{}

def constructor_field_demand(+v_0: Ast.Quantity, v_1: Ast.Quantity) -> Ast.Quantity:
  match v_1:
    case Ast.QZero{}:
      Ast.QZero{}
    case Ast.QOne{}:
      v_0
    case Ast.QMany{}:
      quantity_join(v_0, v_0)

def pattern_quantity_allowed(v_0: Ast.Quantity, v_1: Ast.Quantity) -> Bool:
  match v_0:
    case Ast.QZero{}:
      match v_1:
        case Ast.QZero{}:
          True{}
        case _:
          False{}
    case Ast.QOne{}:
      match v_1:
        case Ast.QZero{}:
          True{}
        case Ast.QOne{}:
          True{}
        case _:
          False{}
    case Ast.QMany{}:
      True{}
    case _:
      False{}

def lookup_binding(v_1: Nat, v_4: List<&2, Binding>) -> Maybe<&2, Binding>:
  match v_4:
    case +v_20032650 <> +v_20032651:
      +v_9 = v_20032650
      v_10 = v_20032651
      lookup_binding_head(v_1, v_9, v_10)
    case []:
      None{}

def lookup_binding_head(v_1: Nat, v_3: Binding, v_6: List<&2, Binding>) -> Maybe<&2, Binding>:
  match v_1:
    case 0n:
      Some{v_3}
    case 1n++v_20032652:
      v_11 = v_20032652
      lookup_binding(v_11, v_6)

def global_bucket_prepend(+v_0: Scope.ArenaGlobal, v_1: Scope.ArenaGlobalBucket) -> Scope.ArenaGlobalBucket:
  match v_0:
    case Scope.ArenaGlobal{+v_20032653, +v_20032654, +v_20032655, +v_20032656, +v_20032657, +v_20032658}:
      match v_20032658:
        case Scope.GlobalFamily{}:
          match v_1:
            case Scope.ArenaGlobalBucket{+v_20032659, +v_20032660, +v_20032661, +v_20032662}:
              v_18 = v_20032661
              v_19 = v_20032662
              Scope.ArenaGlobalBucket{v_0, Some{v_0}, v_18, v_19}
        case Scope.GlobalConstructor{}:
          match v_1:
            case Scope.ArenaGlobalBucket{+v_20032663, +v_20032664, +v_20032665, +v_20032666}:
              v_35 = v_20032664
              v_37 = v_20032666
              Scope.ArenaGlobalBucket{v_0, v_35, Some{v_0}, v_37}
        case Scope.GlobalDefinition{}:
          match v_1:
            case Scope.ArenaGlobalBucket{+v_20032667, +v_20032668, +v_20032669, +v_20032670}:
              v_53 = v_20032668
              v_54 = v_20032669
              Scope.ArenaGlobalBucket{v_0, v_53, v_54, Some{v_0}}

def global_bucket_new(+v_0: Scope.ArenaGlobal) -> Scope.ArenaGlobalBucket:
  global_bucket_prepend(v_0, Scope.ArenaGlobalBucket{v_0, None{}, None{}, None{}})

def global_index_insert(+v_1: String, v_2: Scope.ArenaGlobal, v_3: Scope.ArenaGlobalIndex) -> Scope.ArenaGlobalIndex:
  match v_3:
    case Scope.ArenaGlobalIndex{+v_8, +v_9, +v_10, +v_11}:
      +v_13 = v_8
      v_15 = v_9
      v_17 = v_10
      v_19 = v_11
      +v_21 = IndexLookup.find(Scope.ArenaGlobalBucket, v_13, v_1)
      match v_21:
        case None{}:
          v_50000002 = Map.set(&2, Scope.ArenaGlobalBucket, v_13, v_1, global_bucket_new(v_2))
          Scope.ArenaGlobalIndex{v_50000002, v_15, v_17, v_19}
        case Some{+v_24}:
          v_26 = v_24
          v_50000003 = Map.set(&2, Scope.ArenaGlobalBucket, v_13, v_1, global_bucket_prepend(v_2, v_26))
          Scope.ArenaGlobalIndex{v_50000003, v_15, v_17, v_19}

def global_index_incomplete(v_0: Scope.ArenaGlobalIndex) -> Scope.ArenaGlobalIndex:
  match v_0:
    case Scope.ArenaGlobalIndex{+v_20032677, +v_20032678, +v_20032679, +v_20032680}:
      v_5 = v_20032677
      v_6 = v_20032678
      v_7 = v_20032679
      Scope.ArenaGlobalIndex{v_5, v_6, v_7, False{}}

def global_index_constructor_entries(v_2: Maybe<&2, List<&2, Scope.ArenaGlobal>>, v_4: String, v_5: Scope.ArenaGlobal, v_6: Scope.ArenaGlobalIndex) -> Scope.ArenaGlobalIndex:
  match v_6:
    case Scope.ArenaGlobalIndex{+v_20032681, +v_20032682, +v_20032683, +v_20032684}:
      v_11 = v_20032681
      v_12 = v_20032682
      v_13 = v_20032683
      v_14 = v_20032684
      match v_2:
        case None{}:
          Scope.ArenaGlobalIndex{v_11, Map.set(&2, List<&2, Scope.ArenaGlobal>, v_12, v_4, [v_5]), v_13, v_14}
        case Some{+v_20032685}:
          v_17 = v_20032685
          Scope.ArenaGlobalIndex{v_11, Map.set(&2, List<&2, Scope.ArenaGlobal>, v_12, v_4, v_5 <> v_17), v_13, v_14}

def global_index_constructor_parent(v_1: Maybe<&2, Scope.ArenaGlobal>, v_3: String, v_4: Scope.ArenaGlobal, v_5: Scope.ArenaGlobalIndex) -> Scope.ArenaGlobalIndex:
  match v_1:
    case None{}:
      global_index_incomplete(v_5)
    case Some{+v_20032686}:
      match v_20032686:
        case Scope.ArenaGlobal{+v_20032687, +v_20032688, +v_20032689, +v_20032690, +v_20032691, +v_20032692}:
          v_14 = v_20032688
          v_15 = v_20032689
          +v_20032693 = String.eq(v_3, canonical_key(v_14, v_15))
          match v_20032693:
            case False{}:
              global_index_incomplete(v_5)
            case True{}:
              match v_5:
                case Scope.ArenaGlobalIndex{+v_20032694, +v_20032695, +v_20032696, +v_20032697}:
                  v_26 = v_20032695
                  global_index_constructor_entries(IndexLookup.find(List<&2, Scope.ArenaGlobal>, v_26, v_3), v_3, v_4, v_5)

def global_index_constructor_owner(v_2: Maybe<&2, String>, v_3: Scope.ArenaGlobal, v_4: Scope.ArenaGlobalIndex) -> Scope.ArenaGlobalIndex:
  match v_2:
    case None{}:
      global_index_incomplete(v_4)
    case Some{+v_20032698}:
      v_7 = v_20032698
      global_index_constructor_parent(Scope.index_kind(v_7, Scope.GlobalFamily{}, v_4), v_7, v_3, v_4)

def global_index_alias_keys(v_20032699: ArenaStore, v_1: String, v_3: String, v_6: IR.Names) -> ArenaResult<IR.Names>:
  +v_20032702 = String.eq(v_1, v_3)
  match v_20032702:
    case False{}:
      ArenaResult{v_20032703, +v_20032704} = arena_names_cons(v_20032699, v_3, v_6)
      ArenaResult{v_20032705, +v_20032706} = arena_names_cons(v_20032703, v_1, v_20032704)
      +v_20032700 = v_20032706
      v_20032701 = v_20032705
      {ArenaResult{v_20032701, v_20032700} : ArenaResult<IR.Names>}
    case True{}:
      ArenaResult{v_20032707, +v_20032708} = arena_names_cons(v_20032699, v_1, v_6)
      +v_20032700 = v_20032708
      v_20032701 = v_20032707
      {ArenaResult{v_20032701, v_20032700} : ArenaResult<IR.Names>}

def global_index_aliases(v_20032709: ArenaStore, v_3: Maybe<&2, IR.Names>, v_5: String, v_7: String, v_8: Scope.ArenaGlobalIndex) -> ArenaResult<Scope.ArenaGlobalIndex>:
  match v_8:
    case Scope.ArenaGlobalIndex{+v_20032710, +v_20032711, +v_20032712, +v_20032713}:
      v_13 = v_20032710
      v_14 = v_20032711
      v_15 = v_20032712
      v_16 = v_20032713
      match v_3:
        case None{}:
          ArenaResult{v_20032714, +v_20032715} = global_index_alias_keys(v_20032709, v_5, v_7, IR.Names{0, 0})
          ArenaResult{v_20032716, +v_20032717} = arena_publish_names(v_20032714, v_20032715)
          {ArenaResult{v_20032716, Scope.ArenaGlobalIndex{v_13, v_14, Map.set(&2, IR.Names, v_15, v_7, v_20032717), v_16}} : ArenaResult<Scope.ArenaGlobalIndex>}
        case Some{+v_20032718}:
          v_21 = v_20032718
          ArenaResult{v_20032719, +v_20032720} = global_index_alias_keys(v_20032709, v_5, v_7, v_21)
          ArenaResult{v_20032721, +v_20032722} = arena_publish_names(v_20032719, v_20032720)
          {ArenaResult{v_20032721, Scope.ArenaGlobalIndex{v_13, v_14, Map.set(&2, IR.Names, v_15, v_7, v_20032722), v_16}} : ArenaResult<Scope.ArenaGlobalIndex>}

def global_index_alias_declaration(v_20032723: ArenaStore, v_1: String, +v_3: String, v_4: Scope.ArenaGlobalIndex) -> ArenaResult<Scope.ArenaGlobalIndex>:
  match v_4:
    case Scope.ArenaGlobalIndex{+v_20032724, +v_20032725, +v_20032726, +v_20032727}:
      v_11 = v_20032726
      ArenaResult{v_20032728, +v_20032729} = global_index_aliases(v_20032723, IndexLookup.find(IR.Names, v_11, v_3), v_1, v_3, v_4)
      {ArenaResult{v_20032728, v_20032729} : ArenaResult<Scope.ArenaGlobalIndex>}

def global_index_family_declaration(v_1: String, v_3: String, v_4: Scope.ArenaGlobalIndex) -> Scope.ArenaGlobalIndex:
  match v_4:
    case Scope.ArenaGlobalIndex{+v_20032730, +v_20032731, +v_20032732, +v_20032733}:
      v_10 = v_20032731
      +v_20032734 = String.eq(v_1, v_3)
      match v_20032734:
        case True{}:
          v_4
        case False{}:
          +v_20032735 = IndexLookup.find(List<&2, Scope.ArenaGlobal>, v_10, v_1)
          match v_20032735:
            case Some{+v_20032736}:
              global_index_incomplete(v_4)
            case None{}:
              v_4

def global_index_declaration(v_1: ArenaStore, v_2: Scope.ArenaGlobal, v_3: Scope.ArenaGlobalIndex) -> ArenaResult<Scope.ArenaGlobalIndex>:
  match v_3:
    case Scope.ArenaGlobalIndex{+v_10, +v_11, +v_12, +v_13}:
      match v_13:
        case False{}:
          {ArenaResult{v_1, v_3} : ArenaResult<Scope.ArenaGlobalIndex>}
        case _:
          match v_2:
            case Scope.ArenaGlobal{+v_22, +v_23, +v_24, +v_25, +v_26, +v_27}:
              match v_27:
                case Scope.GlobalFamily{}:
                  v_29 = v_22
                  v_31 = v_23
                  v_33 = v_24
                  v_50000004 = global_index_family_declaration(v_29, canonical_key(v_31, v_33), v_3)
                  {ArenaResult{v_1, v_50000004} : ArenaResult<Scope.ArenaGlobalIndex>}
                case Scope.GlobalConstructor{}:
                  v_37 = v_25
                  ArenaResult{v_41, +v_42} = arena_constructor_owner(v_1, v_37)
                  v_50000005 = global_index_constructor_owner(v_42, v_2, v_3)
                  {ArenaResult{v_41, v_50000005} : ArenaResult<Scope.ArenaGlobalIndex>}
                case _:
                  {ArenaResult{v_1, v_3} : ArenaResult<Scope.ArenaGlobalIndex>}
            case _:
              {ArenaResult{v_1, v_3} : ArenaResult<Scope.ArenaGlobalIndex>}
    case _:
      match v_2:
        case Scope.ArenaGlobal{+v_56, +v_57, +v_58, +v_59, +v_60, +v_61}:
          match v_61:
            case Scope.GlobalFamily{}:
              v_63 = v_56
              v_65 = v_57
              v_67 = v_58
              v_50000006 = global_index_family_declaration(v_63, canonical_key(v_65, v_67), v_3)
              {ArenaResult{v_1, v_50000006} : ArenaResult<Scope.ArenaGlobalIndex>}
            case Scope.GlobalConstructor{}:
              v_71 = v_59
              ArenaResult{v_75, +v_76} = arena_constructor_owner(v_1, v_71)
              v_50000007 = global_index_constructor_owner(v_76, v_2, v_3)
              {ArenaResult{v_75, v_50000007} : ArenaResult<Scope.ArenaGlobalIndex>}
            case _:
              {ArenaResult{v_1, v_3} : ArenaResult<Scope.ArenaGlobalIndex>}
        case _:
          {ArenaResult{v_1, v_3} : ArenaResult<Scope.ArenaGlobalIndex>}

def global_index_prepend(v_20032780: ArenaStore, +v_0: Scope.ArenaGlobal, v_1: Scope.ArenaGlobalIndex) -> ArenaResult<Scope.ArenaGlobalIndex>:
  match v_0:
    case Scope.ArenaGlobal{+v_20032781, +v_20032782, +v_20032783, +v_20032784, +v_20032785, +v_20032786}:
      +v_8 = v_20032781
      v_9 = v_20032782
      v_10 = v_20032783
      +v_16 = canonical_key(v_9, v_10)
      ArenaResult{v_20032787, +v_20032788} = global_index_alias_declaration(v_20032780, v_8, v_16, global_index_insert(v_8, v_0, v_1))
      v_20 = v_20032788
      +v_20032789 = String.eq(v_8, v_16)
      match v_20032789:
        case True{}:
          ArenaResult{v_20032790, +v_20032791} = global_index_declaration(v_20032787, v_0, v_20)
          {ArenaResult{v_20032790, v_20032791} : ArenaResult<Scope.ArenaGlobalIndex>}
        case False{}:
          ArenaResult{v_20032792, +v_20032793} = global_index_declaration(v_20032787, v_0, global_index_insert(v_16, v_0, v_20))
          {ArenaResult{v_20032792, v_20032793} : ArenaResult<Scope.ArenaGlobalIndex>}

def global_index_build(v_20032794: ArenaStore, v_1: List<&2, Scope.ArenaGlobal>) -> ArenaResult<Scope.ArenaGlobalIndex>:
  match v_1:
    case []:
      {ArenaResult{v_20032794, Scope.ArenaGlobalIndex{MTip{}, MTip{}, MTip{}, True{}}} : ArenaResult<Scope.ArenaGlobalIndex>}
    case +v_20032795 <> +v_20032796:
      +v_4 = v_20032795
      v_5 = v_20032796
      ArenaResult{v_20032797, +v_20032798} = global_index_build(v_20032794, v_5)
      ArenaResult{v_20032799, +v_20032800} = global_index_prepend(v_20032797, v_4, v_20032798)
      {ArenaResult{v_20032799, v_20032800} : ArenaResult<Scope.ArenaGlobalIndex>}

def global_scope(v_20032801: ArenaStore, +v_1: List<&2, Scope.ArenaGlobal>) -> ArenaResult<Scope.ArenaGlobalScope>:
  ArenaResult{v_20032802, +v_20032803} = global_index_build(v_20032801, v_1)
  {ArenaResult{v_20032802, Scope.ArenaGlobalScope{v_1, v_20032803, List.length(&2, Scope.ArenaGlobal, v_1)}} : ArenaResult<Scope.ArenaGlobalScope>}

def global_segment(v_20032804: ArenaStore, v_1: Bool, v_3: String, v_5: String, +v_7: List<&2, Scope.ArenaGlobal>) -> ArenaResult<Scope.ArenaGlobalSegment>:
  ArenaResult{v_20032805, +v_20032806} = global_index_build(v_20032804, v_7)
  {ArenaResult{v_20032805, Scope.ArenaGlobalSegment{v_1, v_3, v_5, v_7, v_20032806}} : ArenaResult<Scope.ArenaGlobalSegment>}

def global_segment_prepend(v_20032807: ArenaStore, +v_0: Scope.ArenaGlobal, v_1: Scope.ArenaGlobalSegment) -> ArenaResult<Scope.ArenaGlobalSegment>:
  match v_1:
    case Scope.ArenaGlobalSegment{+v_20032808, +v_20032809, +v_20032810, +v_20032811, +v_20032812}:
      v_7 = v_20032808
      v_8 = v_20032809
      v_9 = v_20032810
      v_10 = v_20032811
      v_11 = v_20032812
      ArenaResult{v_20032813, +v_20032814} = global_index_prepend(v_20032807, v_0, v_11)
      {ArenaResult{v_20032813, Scope.ArenaGlobalSegment{v_7, v_8, v_9, v_0 <> v_10, v_20032814}} : ArenaResult<Scope.ArenaGlobalSegment>}

# Earlier segments supply the generic first entry and the first of each kind.
# Scope.bucket selects any family before the generic first entry.
def visible_bucket_first(+first: Maybe<&2, Scope.ArenaGlobal>, later: Maybe<&2, Scope.ArenaGlobal>) -> Maybe<&2, Scope.ArenaGlobal>:
  match first:
    case Some{entry}: first
    case None{}: later

def visible_bucket_merge(earlier: Scope.ArenaGlobalBucket, later: Scope.ArenaGlobalBucket) -> Scope.ArenaGlobalBucket:
  match earlier:
    case Scope.ArenaGlobalBucket{first, family, constructor, definition}:
      match later:
        case Scope.ArenaGlobalBucket{ignored, later_family, later_constructor, later_definition}:
          Scope.ArenaGlobalBucket{first, visible_bucket_first(family, later_family), visible_bucket_first(constructor, later_constructor), visible_bucket_first(definition, later_definition)}

def visible_bucket_merge_result(earlier: Scope.ArenaGlobalBucket, later: Maybe<&2, Scope.ArenaGlobalBucket>) -> Scope.ArenaGlobalBucket:
  match later:
    case None{}: earlier
    case Some{bucket}: visible_bucket_merge(earlier, bucket)

# Walk real map leaf keys: canonical aliases need not equal bucket.first.key.
# Empty-side merges reuse the original persistent dictionary.
def visible_lookup_merge(earlier: Map<&2, Scope.ArenaGlobalBucket>, +later: Map<&2, Scope.ArenaGlobalBucket>) -> Map<&2, Scope.ArenaGlobalBucket>:
  match later:
    case MTip{}: earlier
    case _:
      match earlier:
        case MTip{}: later
        case MLeaf{+key, bucket}:
          Map.set(&2, Scope.ArenaGlobalBucket, later, key, visible_bucket_merge_result(bucket, IndexLookup.find(Scope.ArenaGlobalBucket, later, key)))
        case MNode{pos, lo, hi}:
          visible_lookup_merge(hi, visible_lookup_merge(lo, later))

def visible_lookup_build(segments: List<&2, Scope.ArenaGlobalSegment>) -> Map<&2, Scope.ArenaGlobalBucket>:
  match segments:
    case []: MTip{}
    case segment <> rest:
      match segment:
        case Scope.ArenaGlobalSegment{current, owner, alias, entries, index}:
          match index:
            case Scope.ArenaGlobalIndex{values, constructors, aliases, complete}:
              visible_lookup_merge(values, visible_lookup_build(rest))

def visible_scope_indexed(+segments: List<&2, Scope.ArenaGlobalSegment>) -> Scope.ArenaGlobalScope:
  Scope.ArenaVisibleScope{segments, visible_lookup_build(segments)}

def visible_lookup_insert(+key: String, entry: Scope.ArenaGlobal, +lookup: Map<&2, Scope.ArenaGlobalBucket>) -> Map<&2, Scope.ArenaGlobalBucket>:
  +previous = IndexLookup.find(Scope.ArenaGlobalBucket, lookup, key)
  match previous:
    case None{}:
      Map.set(&2, Scope.ArenaGlobalBucket, lookup, key, global_bucket_new(entry))
    case Some{bucket}:
      Map.set(&2, Scope.ArenaGlobalBucket, lookup, key, global_bucket_prepend(entry, bucket))

# Prepending the first segment has unconditional first-entry/kind priority.
def visible_lookup_prepend(+entry: Scope.ArenaGlobal, lookup: Map<&2, Scope.ArenaGlobalBucket>) -> Map<&2, Scope.ArenaGlobalBucket>:
  match entry:
    case Scope.ArenaGlobal{+key, namespace, local_key, ty, value, kind}:
      +canonical = canonical_key(namespace, local_key)
      next = visible_lookup_insert(key, entry, lookup)
      +same = String.eq(key, canonical)
      match same:
        case True{}: next
        case False{}: visible_lookup_insert(canonical, entry, next)

# Only declaration-touched keys are refolded after updating non-head segments.
# This preserves earlier imported heads without revisiting their dictionaries.
def visible_lookup_key_merge(earlier: Maybe<&2, Scope.ArenaGlobalBucket>, later: Maybe<&2, Scope.ArenaGlobalBucket>) -> Maybe<&2, Scope.ArenaGlobalBucket>:
  match earlier:
    case None{}: later
    case Some{bucket}: Some{visible_bucket_merge_result(bucket, later)}

def visible_lookup_key(+key: String, segments: List<&2, Scope.ArenaGlobalSegment>) -> Maybe<&2, Scope.ArenaGlobalBucket>:
  match segments:
    case []: None{}
    case segment <> rest:
      match segment:
        case Scope.ArenaGlobalSegment{current, owner, alias, entries, index}:
          match index:
            case Scope.ArenaGlobalIndex{values, constructors, aliases, complete}:
              visible_lookup_key_merge(IndexLookup.find(Scope.ArenaGlobalBucket, values, key), visible_lookup_key(key, rest))

def visible_lookup_refresh_key(+key: String, segments: List<&2, Scope.ArenaGlobalSegment>, lookup: Map<&2, Scope.ArenaGlobalBucket>) -> Map<&2, Scope.ArenaGlobalBucket>:
  +resolved = visible_lookup_key(key, segments)
  match resolved:
    case None{}: lookup
    case Some{bucket}: Map.set(&2, Scope.ArenaGlobalBucket, lookup, key, bucket)

def visible_lookup_refresh_alias(+local_key: String, current: Bool, +alias: String, +segments: List<&2, Scope.ArenaGlobalSegment>, lookup: Map<&2, Scope.ArenaGlobalBucket>) -> Map<&2, Scope.ArenaGlobalBucket>:
  match current:
    case True{}: visible_lookup_refresh_key(local_key, segments, lookup)
    case False{}:
      next = visible_lookup_refresh_key(String.append(alias, String.append(".", local_key)), segments, lookup)
      +base = String.eq(alias, "Base")
      match base:
        case False{}: next
        case True{}: visible_lookup_refresh_key(local_key, segments, next)

def visible_lookup_refresh_segments(+namespace: String, +local_key: String, remaining: List<&2, Scope.ArenaGlobalSegment>, +segments: List<&2, Scope.ArenaGlobalSegment>, lookup: Map<&2, Scope.ArenaGlobalBucket>) -> Map<&2, Scope.ArenaGlobalBucket>:
  match remaining:
    case []: lookup
    case segment <> rest:
      match segment:
        case Scope.ArenaGlobalSegment{current, owner, alias, entries, index}:
          +same_owner = String.eq(namespace, owner)
          match same_owner:
            case False{}: visible_lookup_refresh_segments(namespace, local_key, rest, segments, lookup)
            case True{}:
              next = visible_lookup_refresh_alias(local_key, current, alias, segments, lookup)
              visible_lookup_refresh_segments(namespace, local_key, rest, segments, next)

def visible_lookup_refresh(entry: Scope.ArenaGlobal, +segments: List<&2, Scope.ArenaGlobalSegment>, lookup: Map<&2, Scope.ArenaGlobalBucket>) -> Map<&2, Scope.ArenaGlobalBucket>:
  match entry:
    case Scope.ArenaGlobal{key, +namespace, +local_key, ty, value, kind}:
      next = visible_lookup_refresh_key(canonical_key(namespace, local_key), segments, lookup)
      visible_lookup_refresh_segments(namespace, local_key, segments, segments, next)

def global_segments_entries(v_1: List<&2, Scope.ArenaGlobalSegment>) -> List<&2, Scope.ArenaGlobal>:
  match v_1:
    case []:
      []
    case +v_20032815 <> +v_20032816:
      +v_5 = v_20032815
      v_6 = v_20032816
      match v_5:
        case Scope.ArenaGlobalSegment{+v_20032817, +v_20032818, +v_20032819, +v_20032820, +v_20032821}:
          v_15 = v_20032820
          match v_6:
            case []:
              v_15
            case _:
              List.append(&2, Scope.ArenaGlobal, v_15, global_segments_entries(v_6))

def global_segments_size(v_1: List<&2, Scope.ArenaGlobalSegment>) -> Nat:
  match v_1:
    case []:
      0n
    case +v_20032823 <> +v_20032824:
      +v_5 = v_20032823
      v_6 = v_20032824
      match v_5:
        case Scope.ArenaGlobalSegment{+v_20032825, +v_20032826, +v_20032827, +v_20032828, +v_20032829}:
          v_15 = v_20032828
          Nat.add(List.length(&2, Scope.ArenaGlobal, v_15), global_segments_size(v_6))

def definition_scope(v_1: Bool, v_2: Scope.ArenaGlobalScope) -> Scope.ArenaGlobalScope:
  match v_1:
    case False{}:
      v_2
    case True{}:
      Scope.ArenaUnsafeScope{v_2}

def domain_quantity(v_0: Ast.Quantity, v_1: Scope.ArenaGlobalScope) -> Ast.Quantity:
  match v_1:
    case Scope.ArenaUnsafeScope{+v_20032831}:
      match v_0:
        case Ast.QMany{}:
          Ast.QOne{}
        case _:
          v_0
    case _:
      v_0

def global_scope_entries(v_0: Scope.ArenaGlobalScope) -> List<&2, Scope.ArenaGlobal>:
  match v_0:
    case Scope.ArenaGlobalScope{+v_20032834, +v_20032835, +v_20032836}:
      v_5 = v_20032834
      v_5
    case Scope.ArenaVisibleScope{+v_20032837, ignored_lookup}:
      v_9 = v_20032837
      global_segments_entries(v_9)
    case Scope.ArenaUnsafeScope{+v_20032838}:
      v_12 = v_20032838
      global_scope_entries(v_12)

def global_scope_prepend(v_20032839: ArenaStore, +v_0: Scope.ArenaGlobal, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Scope.ArenaGlobalScope>:
  match v_1:
    case Scope.ArenaGlobalScope{+v_20032840, +v_20032841, +v_20032842}:
      v_5 = v_20032840
      v_6 = v_20032841
      v_7 = v_20032842
      ArenaResult{v_20032843, +v_20032844} = global_index_prepend(v_20032839, v_0, v_6)
      {ArenaResult{v_20032843, Scope.ArenaGlobalScope{v_0 <> v_5, v_20032844, Nat.add(v_7, 1n)}} : ArenaResult<Scope.ArenaGlobalScope>}
    case Scope.ArenaVisibleScope{+v_20032845, lookup}:
      v_10 = v_20032845
      match v_10:
        case []:
          match v_0:
            case Scope.ArenaGlobal{+v_20032846, +v_20032847, +v_20032848, +v_20032849, +v_20032850, +v_20032851}:
              v_18 = v_20032847
              ArenaResult{v_20032852, +v_20032853} = global_segment(v_20032839, True{}, v_18, "", [v_0])
              {ArenaResult{v_20032852, visible_scope_indexed([v_20032853])} : ArenaResult<Scope.ArenaGlobalScope>}
        case +v_20032854 <> +v_20032855:
          +v_26 = v_20032854
          v_27 = v_20032855
          ArenaResult{v_20032856, +v_20032857} = global_segment_prepend(v_20032839, v_0, v_26)
          {ArenaResult{v_20032856, Scope.ArenaVisibleScope{v_20032857 <> v_27, visible_lookup_prepend(v_0, lookup)}} : ArenaResult<Scope.ArenaGlobalScope>}
    case Scope.ArenaUnsafeScope{+v_20032858}:
      v_30 = v_20032858
      ArenaResult{v_20032859, +v_20032860} = global_scope_prepend(v_20032839, v_0, v_30)
      {ArenaResult{v_20032859, Scope.ArenaUnsafeScope{v_20032860}} : ArenaResult<Scope.ArenaGlobalScope>}

def global_scope_size(v_0: Scope.ArenaGlobalScope) -> Nat:
  match v_0:
    case Scope.ArenaGlobalScope{+v_20032861, +v_20032862, +v_20032863}:
      v_7 = v_20032863
      v_7
    case Scope.ArenaVisibleScope{+v_20032864, ignored_lookup}:
      v_9 = v_20032864
      global_segments_size(v_9)
    case Scope.ArenaUnsafeScope{+v_20032865}:
      v_12 = v_20032865
      global_scope_size(v_12)

def global_local_alias(v_0: Scope.ArenaGlobal) -> Scope.ArenaGlobal:
  match v_0:
    case Scope.ArenaGlobal{+v_20032866, +v_20032867, +v_20032868, +v_20032869, +v_20032870, +v_20032871}:
      v_8 = v_20032867
      +v_9 = v_20032868
      v_10 = v_20032869
      v_11 = v_20032870
      v_12 = v_20032871
      Scope.ArenaGlobal{v_9, v_8, v_9, v_10, v_11, v_12}

def global_segment_import_prepend(v_20032872: ArenaStore, +v_0: Scope.ArenaGlobal, +v_2: String, v_3: Scope.ArenaGlobalSegment) -> ArenaResult<Scope.ArenaGlobalSegment>:
  match v_0:
    case Scope.ArenaGlobal{+v_20032873, +v_20032874, +v_20032875, +v_20032876, +v_20032877, +v_20032878}:
      v_11 = v_20032874
      +v_12 = v_20032875
      v_13 = v_20032876
      v_14 = v_20032877
      v_15 = v_20032878
      ArenaResult{v_20032879, +v_20032880} = arena_publish_global(v_20032872, Scope.ArenaGlobal{String.append(v_2, String.append(".", v_12)), v_11, v_12, v_13, v_14, v_15})
      v_17 = v_20032880
      ArenaResult{v_20032881, +v_20032882} = global_segment_prepend(v_20032879, v_17, v_3)
      v_20 = v_20032882
      +v_20032883 = String.eq(v_2, "Base")
      match v_20032883:
        case True{}:
          ArenaResult{v_20032884, +v_20032885} = global_segment_prepend(v_20032881, global_local_alias(v_0), v_20)
          {ArenaResult{v_20032884, v_20032885} : ArenaResult<Scope.ArenaGlobalSegment>}
        case False{}:
          {ArenaResult{v_20032881, v_20} : ArenaResult<Scope.ArenaGlobalSegment>}

def global_segment_update(v_20032886: ArenaStore, +v_0: Scope.ArenaGlobal, +v_1: Scope.ArenaGlobalSegment) -> ArenaResult<Scope.ArenaGlobalSegment>:
  match v_0:
    case Scope.ArenaGlobal{+v_20032887, +v_20032888, +v_20032889, +v_20032890, +v_20032891, +v_20032892}:
      v_9 = v_20032888
      match v_1:
        case Scope.ArenaGlobalSegment{+v_20032893, +v_20032894, +v_20032895, +v_20032896, +v_20032897}:
          v_19 = v_20032893
          v_20 = v_20032894
          v_21 = v_20032895
          +v_20032898 = String.eq(v_9, v_20)
          match v_20032898:
            case False{}:
              {ArenaResult{v_20032886, v_1} : ArenaResult<Scope.ArenaGlobalSegment>}
            case True{}:
              match v_19:
                case True{}:
                  ArenaResult{v_20032899, +v_20032900} = global_segment_prepend(v_20032886, global_local_alias(v_0), v_1)
                  {ArenaResult{v_20032899, v_20032900} : ArenaResult<Scope.ArenaGlobalSegment>}
                case False{}:
                  ArenaResult{v_20032901, +v_20032902} = global_segment_import_prepend(v_20032886, v_0, v_21, v_1)
                  {ArenaResult{v_20032901, v_20032902} : ArenaResult<Scope.ArenaGlobalSegment>}

def global_segments_update(v_20032903: ArenaStore, +v_0: Scope.ArenaGlobal, v_2: List<&2, Scope.ArenaGlobalSegment>) -> ArenaResult<List<&2, Scope.ArenaGlobalSegment>>:
  match v_2:
    case []:
      {ArenaResult{v_20032903, []} : ArenaResult<List<&2, Scope.ArenaGlobalSegment>>}
    case +v_20032904 <> +v_20032905:
      +v_6 = v_20032904
      v_7 = v_20032905
      ArenaResult{v_20032906, +v_20032907} = global_segment_update(v_20032903, v_0, v_6)
      ArenaResult{v_20032908, +v_20032909} = global_segments_update(v_20032906, v_0, v_7)
      {ArenaResult{v_20032908, v_20032907 <> v_20032909} : ArenaResult<List<&2, Scope.ArenaGlobalSegment>>}

def visible_scope_prepend(v_20032910: ArenaStore, +v_0: Scope.ArenaGlobal, +v_1: Scope.ArenaGlobalScope) -> ArenaResult<Scope.ArenaGlobalScope>:
  match v_1:
    case Scope.ArenaGlobalScope{+v_20032911, +v_20032912, +v_20032913}:
      ArenaResult{v_20032914, +v_20032915} = global_scope_prepend(v_20032910, global_local_alias(v_0), v_1)
      {ArenaResult{v_20032914, v_20032915} : ArenaResult<Scope.ArenaGlobalScope>}
    case Scope.ArenaVisibleScope{+v_20032916, lookup}:
      v_11 = v_20032916
      ArenaResult{v_20032917, +v_20032918} = global_segments_update(v_20032910, v_0, v_11)
      {ArenaResult{v_20032917, Scope.ArenaVisibleScope{v_20032918, visible_lookup_refresh(v_0, v_20032918, lookup)}} : ArenaResult<Scope.ArenaGlobalScope>}
    case Scope.ArenaUnsafeScope{+v_20032919}:
      v_14 = v_20032919
      ArenaResult{v_20032920, +v_20032921} = visible_scope_prepend(v_20032910, v_0, v_14)
      {ArenaResult{v_20032920, Scope.ArenaUnsafeScope{v_20032921}} : ArenaResult<Scope.ArenaGlobalScope>}

def visible_scope_update(v_20032922: ArenaStore, v_1: Nat, v_3: List<&2, Scope.ArenaGlobal>, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Scope.ArenaGlobalScope>:
  match v_1:
    case 0n:
      {ArenaResult{v_20032922, v_4} : ArenaResult<Scope.ArenaGlobalScope>}
    case 1n++v_20032923:
      v_6 = v_20032923
      match v_3:
        case []:
          {ArenaResult{v_20032922, v_4} : ArenaResult<Scope.ArenaGlobalScope>}
        case +v_20032924 <> +v_20032925:
          +v_9 = v_20032924
          v_10 = v_20032925
          ArenaResult{v_20032926, +v_20032927} = visible_scope_update(v_20032922, v_6, v_10, v_4)
          ArenaResult{v_20032928, +v_20032929} = visible_scope_prepend(v_20032926, v_9, v_20032927)
          {ArenaResult{v_20032928, v_20032929} : ArenaResult<Scope.ArenaGlobalScope>}

def canonical_key(+v_1: String, +v_3: String) -> String:
  +v_20032931 = String.eq(v_1, "")
  match v_20032931:
    case False{}:
      +v_20032930 = String.append(v_1, String.append(".", v_3))
      v_20032930
    case True{}:
      +v_20032930 = v_3
      v_20032930

def current_scope(v_1: List<&2, Scope.ArenaGlobal>, +v_3: String) -> List<&2, Scope.ArenaGlobal>:
  match v_1:
    case []:
      []
    case +v_20032932 <> +v_20032933:
      +v_7 = v_20032932
      v_8 = v_20032933
      match v_7:
        case Scope.ArenaGlobal{+v_20032934, +v_20032935, +v_20032936, +v_20032937, +v_20032938, +v_20032939}:
          +v_16 = v_20032935
          +v_17 = v_20032936
          v_18 = v_20032937
          v_19 = v_20032938
          v_20 = v_20032939
          +v_23 = current_scope(v_8, v_3)
          +v_20032941 = String.eq(v_3, v_16)
          match v_20032941:
            case False{}:
              +v_20032940 = v_23
              v_20032940
            case True{}:
              +v_20032940 = Scope.ArenaGlobal{v_17, v_16, v_17, v_18, v_19, v_20} <> v_23
              v_20032940

def import_scope_base(+v_1: String, +v_3: String, +v_5: String, +v_6: U32, +v_7: IR.OptionalTerm, +v_8: Scope.GlobalKind, +v_10: List<&2, Scope.ArenaGlobal>) -> List<&2, Scope.ArenaGlobal>:
  +v_13 = {Scope.ArenaGlobal{String.append(v_1, String.append(".", v_3)), v_5, v_3, v_6, v_7, v_8} : Scope.ArenaGlobal}
  +v_20032943 = String.eq(v_1, "Base")
  match v_20032943:
    case False{}:
      +v_20032942 = v_13 <> v_10
      v_20032942
    case True{}:
      +v_20032942 = {Scope.ArenaGlobal{v_3, v_5, v_3, v_6, v_7, v_8} <> v_13 <> v_10 : List<&2, Scope.ArenaGlobal>}
      v_20032942

def import_scope_target(+v_1: String, v_3: String, v_5: String, v_7: String, v_8: U32, v_9: IR.OptionalTerm, v_10: Scope.GlobalKind, +v_12: List<&2, Scope.ArenaGlobal>) -> List<&2, Scope.ArenaGlobal>:
  +v_20032945 = String.eq(v_1, v_5)
  match v_20032945:
    case False{}:
      +v_20032944 = v_12
      v_20032944
    case True{}:
      +v_20032944 = import_scope_base(v_3, v_7, v_1, v_8, v_9, v_10, v_12)
      v_20032944

def import_scope(v_1: List<&2, Scope.ArenaGlobal>, +v_3: String, +v_5: String) -> List<&2, Scope.ArenaGlobal>:
  match v_1:
    case []:
      []
    case +v_20032946 <> +v_20032947:
      +v_9 = v_20032946
      v_10 = v_20032947
      match v_9:
        case Scope.ArenaGlobal{+v_20032948, +v_20032949, +v_20032950, +v_20032951, +v_20032952, +v_20032953}:
          v_18 = v_20032949
          v_19 = v_20032950
          v_20 = v_20032951
          v_21 = v_20032952
          v_22 = v_20032953
          v_25 = import_scope(v_10, v_3, v_5)
          import_scope_target(v_18, v_3, v_5, v_19, v_20, v_21, v_22, v_25)

def imported_segments(v_20032954: ArenaStore, v_1: List<&2, Ast.ModuleImport>, +v_3: List<&2, Scope.ArenaGlobal>, +v_5: String) -> ArenaResult<List<&2, Scope.ArenaGlobalSegment>>:
  match v_1:
    case []:
      {ArenaResult{v_20032954, []} : ArenaResult<List<&2, Scope.ArenaGlobalSegment>>}
    case +v_20032955 <> +v_20032956:
      +v_9 = v_20032955
      v_10 = v_20032956
      match v_9:
        case Ast.ModuleImport{+v_20032957, +v_20032958, +v_20032959}:
          v_14 = v_20032957
          +v_15 = v_20032958
          +v_18 = Path.namespace(v_5, v_14)
          ArenaResult{v_20032960, +v_20032961} = global_segment(v_20032954, False{}, v_18, v_15, import_scope(v_3, v_15, v_18))
          ArenaResult{v_20032962, +v_20032963} = imported_segments(v_20032960, v_10, v_3, v_5)
          {ArenaResult{v_20032962, v_20032961 <> v_20032963} : ArenaResult<List<&2, Scope.ArenaGlobalSegment>>}

def base_scope(v_1: List<&2, Scope.ArenaGlobal>) -> List<&2, Scope.ArenaGlobal>:
  import_scope(v_1, "Base", "")

def visible_globals(v_20032964: ArenaStore, +v_1: List<&2, Scope.ArenaGlobal>, +v_3: String, v_5: List<&2, Ast.ModuleImport>) -> ArenaResult<Scope.ArenaGlobalScope>:
  ArenaResult{v_20032965, +v_20032966} = global_segment(v_20032964, True{}, v_3, "", current_scope(v_1, v_3))
  v_9 = v_20032966
  ArenaResult{v_20032967, +v_20032968} = imported_segments(v_20032965, v_5, v_1, v_3)
  v_12 = v_20032968
  ArenaResult{v_20032969, +v_20032970} = global_segment(v_20032967, False{}, "", "Base", base_scope(v_1))
  v_16 = v_20032970
  {ArenaResult{v_20032969, visible_scope_indexed(v_9 <> List.append(&2, Scope.ArenaGlobalSegment, v_12, [v_16]))} : ArenaResult<Scope.ArenaGlobalScope>}

def declaration_visible_scope(v_20032971: ArenaStore, +v_0: Scope.ArenaGlobalScope, v_2: Nat, v_3: Scope.ArenaGlobalScope) -> ArenaResult<Scope.ArenaGlobalScope>:
  ArenaResult{v_20032972, +v_20032973} = visible_scope_update(v_20032971, Nat.sub(global_scope_size(v_0), v_2), global_scope_entries(v_0), v_3)
  {ArenaResult{v_20032972, v_20032973} : ArenaResult<Scope.ArenaGlobalScope>}

def family_lowered_whnf(v_20032974: ArenaStore, v_1: Nat, v_2: U32, v_3: Scope.ArenaGlobalScope, v_5: FamilyLowering) -> ArenaResult<U32>:
  match v_5:
    case FamilyTerm{+v_20032975}:
      v_7 = v_20032975
      ArenaResult{v_20032976, +v_20032977} = whnf(v_20032974, v_1, v_7, v_3)
      {ArenaResult{v_20032976, v_20032977} : ArenaResult<U32>}
    case FamilyFailure{+v_20032978}:
      {ArenaResult{v_20032974, v_2} : ArenaResult<U32>}

def whnf_ref_type(v_20032979: ArenaStore, v_0: U32, v_2: Nat, v_3: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_20032980, +v_20032981} = arena_get_node(v_20032979, v_0)
  match v_20032981:
    case Arena.TermAll{+v_20032988, +v_20032989, +v_20032991, +v_20032992, +v_20032993, +v_20032994}:
      {ArenaResult{v_20032980, v_3} : ArenaResult<U32>}
    case _:
      ArenaResult{v_20032996, +v_20032997} = whnf(v_20032980, v_2, v_4, v_5)
      {ArenaResult{v_20032996, v_20032997} : ArenaResult<U32>}

def whnf_ref_global(v_20032998: ArenaStore, v_0: Scope.ArenaGlobal, +v_2: Nat, v_3: U32, +v_4: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  match v_0:
    case Scope.ArenaGlobal{+v_20033005, +v_20033006, +v_20033007, +v_20033008, +v_20033009, +v_20033010}:
      match v_20033009:
        case IR.SomeTerm{+v_20033012}:
          match v_20033010:
            case Scope.GlobalFamily{}:
              v_14 = v_20033012
              ArenaResult{v_20033013, +v_20033014} = whnf(v_20032998, v_2, v_14, v_4)
              {ArenaResult{v_20033013, v_20033014} : ArenaResult<U32>}
            case _:
              v_26 = v_20033012
              v_25 = v_20033008
              ArenaResult{v_20033016, +v_20033017} = whnf(v_20032998, v_2, v_25, v_4)
              ArenaResult{v_20033018, +v_20033019} = whnf_ref_type(v_20033016, v_20033017, v_2, v_3, v_26, v_4)
              {ArenaResult{v_20033018, v_20033019} : ArenaResult<U32>}
        case _:
          {ArenaResult{v_20032998, v_3} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_20032998, v_3} : ArenaResult<U32>}

def whnf_ref_result(v_20033022: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_3: Nat, v_4: U32, v_5: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  match v_1:
    case Some{+v_20033023}:
      v_7 = v_20033023
      ArenaResult{v_20033024, +v_20033025} = whnf_ref_global(v_20033022, v_7, v_3, v_4, v_5)
      {ArenaResult{v_20033024, v_20033025} : ArenaResult<U32>}
    case None{}:
      {ArenaResult{v_20033022, v_4} : ArenaResult<U32>}

def whnf_application_global(v_20033026: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_3: Nat, v_4: U32, v_5: U32, v_6: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  match v_1:
    case Some{+v_20033028}:
      match v_20033028:
        case Scope.ArenaGlobal{+v_20033035, +v_20033036, +v_20033037, +v_20033038, +v_20033039, +v_20033040}:
          match v_20033039:
            case IR.SomeTerm{+v_20033042}:
              match v_20033040:
                case Scope.GlobalDefinition{}:
                  v_16 = v_20033042
                  ArenaResult{v_20033043, +v_20033044} = term_span(v_20033026, v_4)
                  ArenaResult{v_20033045, +v_20033046} = arena_put_node(v_20033043, Arena.TermApp{v_16, v_5, v_20033044})
                  ArenaResult{v_20033047, +v_20033048} = whnf(v_20033045, v_3, v_20033046, v_6)
                  {ArenaResult{v_20033047, v_20033048} : ArenaResult<U32>}
                case _:
                  {ArenaResult{v_20033026, v_4} : ArenaResult<U32>}
            case _:
              {ArenaResult{v_20033026, v_4} : ArenaResult<U32>}
        case _:
          {ArenaResult{v_20033026, v_4} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_20033026, v_4} : ArenaResult<U32>}

# Select a beta-reduced match before touching case bodies. Only the selected
# body's lambda binder is removed at the original pattern depth; the existing
# matcher and substitute_many then remove the pattern binders in their order.
# Transparent whnf wrappers consume fuel normally. Any inconclusive selection
# retains the original whole-body substitution and normalization path.
def whnf_beta_fallback(store: ArenaStore, fuel: Nat, argument: U32, body: U32, globals: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{next, reduced} = core_subst(store, 0n, argument, body)
  whnf(next, fuel, reduced, globals)

def whnf_beta_finish(fuel: Nat, argument: U32, body: U32, globals: Scope.ArenaGlobalScope, result: ArenaResult<Maybe<&2, U32>>) -> ArenaResult<U32>:
  match result:
    case ArenaResult{store, selected}:
      match selected:
        case Some{output}: {ArenaResult{store, output} : ArenaResult<U32>}
        case None{}: whnf_beta_fallback(store, fuel, argument, body, globals)

def whnf_beta(store: ArenaStore, +fuel: Nat, +argument: U32, +body: U32, +globals: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  whnf_beta_finish(fuel, argument, body, globals, whnf_beta_try(store, fuel, argument, body, globals))

def whnf_beta_try(store: ArenaStore, fuel: Nat, argument: U32, body: U32, globals: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  match fuel:
    case 0n: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, U32>>}
    case 1n++remaining:
      whnf_beta_body(argument, remaining, globals, arena_get_node(store, body))

def whnf_beta_body(argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope, result: ArenaResult<Arena.Node>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, node}:
      match node:
        case Arena.TermAnn{inner, _, _}: whnf_beta_try(store, fuel, argument, inner, globals)
        case Arena.BodyReply{inner, _}: whnf_beta_try(store, fuel, argument, inner, globals)
        case Arena.BodyMatch{start, count, cases_start, cases_count, _}:
          whnf_beta_scrutinee_count(store, count, start, IR.Words{cases_start, cases_count}, argument, fuel, globals)
        case _: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, U32>>}

def whnf_beta_scrutinee_single(store: ArenaStore, start: U32, cases: IR.Words, argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope, single: Bool) -> ArenaResult<Maybe<&2, U32>>:
  match single:
    case True{}: whnf_beta_scrutinee(cases, argument, fuel, globals, arena_words_view(store, IR.Words{start, 1}))
    case False{}: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, U32>>}

def whnf_beta_scrutinee_count(store: ArenaStore, count: U32, start: U32, cases: IR.Words, argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  whnf_beta_scrutinee_single(store, start, cases, argument, fuel, globals, U32.is_eq(count, 1))

def whnf_beta_scrutinee(cases: IR.Words, argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope, result: ArenaResult<IR.WordView>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, view}:
      match view:
        case IR.WordCons{scrutinee, _}:
          whnf_beta_variable(cases, argument, fuel, globals, arena_get_node(store, scrutinee))
        case _: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, U32>>}

def whnf_beta_variable(cases: IR.Words, +argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope, result: ArenaResult<Arena.Node>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, node}:
      match node:
        case Arena.TermVar{_, index, _}:
          match index:
            case 0n: whnf_beta_argument(cases, argument, fuel, globals, arena_words_cons(store, argument, IR.Words{0, 0}))
            case _: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, U32>>}
        case _: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, U32>>}

def whnf_beta_argument(cases: IR.Words, argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope, result: ArenaResult<IR.Words>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, scrutinees}: whnf_beta_index(cases, scrutinees, argument, fuel, globals, arena_case_prefix_index(store, cases))

# Normalize with precisely the pattern matcher's allowance, and retain the
# original argument/scrutinees for its verification (including nested fields).
# Alias enumeration uses the current scope, not the lifetime of the raw cache.
def whnf_beta_index(cases: IR.Words, +scrutinees: IR.Words, +argument: U32, +fuel: Nat, +globals: Scope.ArenaGlobalScope, result: ArenaResult<Arena.CasePrefixEntry>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, entry}:
      match entry:
        case Arena.CasePrefixEmpty{}: whnf_beta_cases(store, cases, scrutinees, argument, fuel, globals)
        case Arena.CasePrefixSaved{_, _, heads, barrier, _}:
          whnf_beta_index_normal(CasePrefixSelect{cases, scrutinees, argument, fuel, globals, heads, barrier}, whnf(store, fuel, argument, globals))

def whnf_beta_index_normal(request: CasePrefixSelect, result: ArenaResult<U32>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, id}: whnf_beta_index_node(request, arena_get_node(store, id))

def whnf_beta_index_node(request: CasePrefixSelect, result: ArenaResult<Arena.Node>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, node}:
      match node:
        case Arena.TermCtr{key_id, _, _, _}: whnf_beta_index_name(request, arena_name_text(store, key_id))
        case _:
          match request:
            case CasePrefixSelect{cases, scrutinees, argument, fuel, globals, _, _}: whnf_beta_cases(store, cases, scrutinees, argument, fuel, globals)

def whnf_beta_index_name(request: CasePrefixSelect, result: ArenaResult<String>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, +name}:
      match request:
        case CasePrefixSelect{cases, scrutinees, argument, fuel, +globals, heads, offset}:
          whnf_beta_index_aliases(CasePrefixSelect{cases, scrutinees, argument, fuel, globals, heads, offset}, name, scope_canonical_name_aliases(store, Scope.canonical_name(name, globals), globals))

def whnf_beta_index_aliases(request: CasePrefixSelect, name: String, result: ArenaResult<IR.Names>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, names}: whnf_beta_index_names(request, arena_names_cons(store, name, names))

def whnf_beta_index_names(request: CasePrefixSelect, result: ArenaResult<IR.Names>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, names}: whnf_beta_index_names_view(request, arena_names_view(store, names))

def whnf_beta_index_names_view(request: CasePrefixSelect, result: ArenaResult<IR.NameView>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, view}:
      match view:
        case IR.NameNil{}:
          match request:
            case CasePrefixSelect{cases, scrutinees, argument, fuel, globals, _, +offset}:
              match cases:
                case IR.Words{start, +count}:
                  whnf_beta_cases(store, arena_case_prefix_suffix(start, count, offset, U32.is_eq(offset, count)), scrutinees, argument, fuel, globals)
        case IR.NameCons{name, rest}:
          match request:
            case CasePrefixSelect{cases, scrutinees, argument, fuel, globals, heads, offset}:
              whnf_beta_index_offset(store, cases, scrutinees, argument, fuel, globals, offset, rest, arena_case_prefix_name(heads, name))

def whnf_beta_index_offset(store: ArenaStore, cases: IR.Words, scrutinees: IR.Words, argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope, offset: U32, names: IR.Names, result: Map<&2, U32> & U32) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case Tuple{heads, first}:
      whnf_beta_index_names(CasePrefixSelect{cases, scrutinees, argument, fuel, globals, heads, arena_bound_min(offset, first)}, {ArenaResult{store, names} : ArenaResult<IR.Names>})

def whnf_beta_cases(store: ArenaStore, cases: IR.Words, scrutinees: IR.Words, argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  whnf_beta_cases_view(scrutinees, argument, fuel, globals, arena_words_view(store, cases))

def whnf_beta_cases_view(scrutinees: IR.Words, argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope, result: ArenaResult<IR.WordView>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, view}:
      match view:
        case IR.WordCons{case_id, rest}:
          whnf_beta_case(rest, scrutinees, argument, fuel, globals, arena_get_node(store, case_id))
        case _: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, U32>>}

def whnf_beta_case(cases: IR.Words, +scrutinees: IR.Words, argument: U32, +fuel: Nat, +globals: Scope.ArenaGlobalScope, result: ArenaResult<Arena.Node>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, node}:
      match node:
        case Arena.BodyCase{+start, +count, body, _}:
          whnf_beta_pattern_result(IR.Words{start, count}, body, cases, scrutinees, argument, fuel, globals, whnf_patterns(store, IR.Words{start, count}, scrutinees, fuel, globals))
        case _: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, U32>>}

def whnf_beta_pattern_result(patterns: IR.Words, body: U32, cases: IR.Words, scrutinees: IR.Words, argument: U32, fuel: Nat, globals: Scope.ArenaGlobalScope, result: ArenaResult<PatternReduction>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, reduction}:
      match reduction:
        case PatternValues{values}:
          whnf_beta_selected(argument, body, values, fuel, globals, core_pattern_list_depth(store, patterns))
        case PatternMismatch{}: whnf_beta_cases(store, cases, scrutinees, argument, fuel, globals)
        case PatternStuck{}: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, U32>>}

def whnf_beta_selected(argument: U32, body: U32, values: IR.Words, fuel: Nat, globals: Scope.ArenaGlobalScope, result: ArenaResult<Nat>) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case ArenaResult{store, depth}:
      ArenaResult{next, substituted} = core_subst_at(store, 0n, argument, depth, body)
      ArenaResult{reversed_store, reversed} = arena_words_reverse(next, values)
      ArenaResult{reduced_store, reduced} = substitute_many(reversed_store, reversed, substituted)
      ArenaResult{output_store, output} = whnf(reduced_store, fuel, reduced, globals)
      {ArenaResult{output_store, Some{output}} : ArenaResult<Maybe<&2, U32>>}

def whnf_application(v_20033053: ArenaStore, v_0: U32, v_2: Nat, v_3: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_20033054, +v_20033055} = arena_get_node(v_20033053, v_0)
  match v_20033055:
    case Arena.TermLam{+v_20033061, +v_20033062, +v_20033064, +v_20033065, +v_20033066}:
      v_14 = v_20033065
      ArenaResult{v_20033069, +v_20033070} = whnf_beta(v_20033054, v_2, v_4, v_14, v_5)
      {ArenaResult{v_20033069, v_20033070} : ArenaResult<U32>}
    case Arena.TermRef{+v_20033073, +v_20033075}:
      ArenaResult{v_20033076, +v_20033077} = arena_name_text(v_20033054, v_20033073)
      +v_20033074 = v_20033077
      v_19 = v_20033074
      ArenaResult{v_20033078, +v_20033079} = whnf_application_global(v_20033076, Scope.lookup(v_19, v_5), v_2, v_3, v_4, v_5)
      {ArenaResult{v_20033078, v_20033079} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_20033054, v_3} : ArenaResult<U32>}

def whnf_pattern_append(v_20033081: ArenaStore, v_1: PatternReduction, v_3: IR.Words) -> ArenaResult<PatternReduction>:
  match v_1:
    case PatternValues{+v_20033082}:
      v_6 = v_20033082
      ArenaResult{v_20033083, +v_20033084} = arena_words_append(v_20033081, v_3, v_6)
      {ArenaResult{v_20033083, PatternValues{v_20033084}} : ArenaResult<PatternReduction>}
    case PatternMismatch{}:
      {ArenaResult{v_20033081, PatternMismatch{}} : ArenaResult<PatternReduction>}
    case PatternStuck{}:
      {ArenaResult{v_20033081, PatternStuck{}} : ArenaResult<PatternReduction>}

def whnf_patterns_step(v_20033085: ArenaStore, v_1: PatternReduction, v_3: IR.Words, v_5: IR.Words, v_7: Nat, v_8: Scope.ArenaGlobalScope) -> ArenaResult<PatternReduction>:
  match v_1:
    case PatternValues{+v_20033086}:
      v_11 = v_20033086
      ArenaResult{v_20033087, +v_20033088} = whnf_patterns(v_20033085, v_3, v_5, v_7, v_8)
      ArenaResult{v_20033089, +v_20033090} = whnf_pattern_append(v_20033087, v_20033088, v_11)
      {ArenaResult{v_20033089, v_20033090} : ArenaResult<PatternReduction>}
    case PatternMismatch{}:
      {ArenaResult{v_20033085, PatternMismatch{}} : ArenaResult<PatternReduction>}
    case PatternStuck{}:
      {ArenaResult{v_20033085, PatternStuck{}} : ArenaResult<PatternReduction>}

def whnf_patterns(v_20033091: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_5: Nat, v_6: Scope.ArenaGlobalScope) -> ArenaResult<PatternReduction>:
  ArenaResult{v_20033092, +v_20033093} = arena_words_view(v_20033091, v_1)
  match v_20033093:
    case IR.WordNil{}:
      ArenaResult{v_20033094, +v_20033095} = arena_words_view(v_20033092, v_3)
      match v_20033095:
        case IR.WordNil{}:
          {ArenaResult{v_20033094, PatternValues{IR.Words{0, 0}}} : ArenaResult<PatternReduction>}
        case _:
          {ArenaResult{v_20033094, PatternMismatch{}} : ArenaResult<PatternReduction>}
    case IR.WordCons{+v_20033099, +v_20033100}:
      ArenaResult{v_20033101, +v_20033102} = arena_words_view(v_20033092, v_3)
      match v_20033102:
        case IR.WordCons{+v_20033105, +v_20033106}:
          +v_14 = v_20033105
          v_15 = v_20033106
          +v_12 = v_20033099
          v_13 = v_20033100
          ArenaResult{v_20033107, +v_20033108} = whnf_pattern(v_20033101, v_12, v_14, v_5, v_6)
          ArenaResult{v_20033109, +v_20033110} = whnf_patterns_step(v_20033107, v_20033108, v_13, v_15, v_5, v_6)
          {ArenaResult{v_20033109, v_20033110} : ArenaResult<PatternReduction>}
        case _:
          {ArenaResult{v_20033101, PatternMismatch{}} : ArenaResult<PatternReduction>}
    case _:
      {ArenaResult{v_20033092, PatternMismatch{}} : ArenaResult<PatternReduction>}

def whnf_pattern_constructor(v_20033113: ArenaStore, v_0: U32, v_2: String, v_4: IR.Words, v_6: Nat, v_7: Scope.ArenaGlobalScope) -> ArenaResult<PatternReduction>:
  ArenaResult{v_20033114, +v_20033115} = arena_get_node(v_20033113, v_0)
  match v_20033115:
    case Arena.TermCtr{+v_20033119, +v_20033121, +v_20033122, +v_20033124}:
      ArenaResult{v_20033125, +v_20033126} = arena_name_text(v_20033114, v_20033119)
      +v_20033120 = v_20033126
      +v_20033123 = IR.Words{v_20033121, v_20033122}
      v_12 = v_20033120
      v_13 = v_20033123
      +v_20033129 = Scope.equal_names(v_2, v_12, v_7)
      match v_20033129:
        case False{}:
          +v_20033127 = PatternMismatch{}
          v_20033128 = v_20033125
          {ArenaResult{v_20033128, v_20033127} : ArenaResult<PatternReduction>}
        case True{}:
          ArenaResult{v_20033130, +v_20033131} = whnf_patterns(v_20033125, v_4, v_13, v_6, v_7)
          +v_20033127 = v_20033131
          v_20033128 = v_20033130
          {ArenaResult{v_20033128, v_20033127} : ArenaResult<PatternReduction>}
    case _:
      {ArenaResult{v_20033114, PatternStuck{}} : ArenaResult<PatternReduction>}

def whnf_pattern(v_20033133: ArenaStore, v_0: U32, v_1: U32, v_3: Nat, v_4: Scope.ArenaGlobalScope) -> ArenaResult<PatternReduction>:
  ArenaResult{v_20033134, +v_20033135} = arena_get_pattern(v_20033133, v_0)
  match v_20033135:
    case Arena.PatternVar{+v_20033136, +v_20033138, +v_20033139, +v_20033140}:
      ArenaResult{v_20033141, +v_20033142} = arena_words_cons(v_20033134, v_1, IR.Words{0, 0})
      {ArenaResult{v_20033141, PatternValues{v_20033142}} : ArenaResult<PatternReduction>}
    case Arena.PatternCtr{+v_20033143, +v_20033145, +v_20033146, +v_20033148}:
      ArenaResult{v_20033149, +v_20033150} = arena_name_text(v_20033134, v_20033143)
      +v_20033144 = v_20033150
      +v_20033147 = IR.Words{v_20033145, v_20033146}
      v_17 = v_20033144
      v_18 = v_20033147
      ArenaResult{v_20033151, +v_20033152} = whnf(v_20033149, v_3, v_1, v_4)
      ArenaResult{v_20033153, +v_20033154} = whnf_pattern_constructor(v_20033151, v_20033152, v_17, v_18, v_3, v_4)
      {ArenaResult{v_20033153, v_20033154} : ArenaResult<PatternReduction>}

def substitute_many(v_20033155: ArenaStore, v_1: IR.Words, v_2: U32) -> ArenaResult<U32>:
  ArenaResult{v_20033156, +v_20033157} = arena_words_view(v_20033155, v_1)
  match v_20033157:
    case IR.WordNil{}:
      {ArenaResult{v_20033156, v_2} : ArenaResult<U32>}
    case IR.WordCons{+v_20033158, +v_20033159}:
      +v_5 = v_20033158
      v_6 = v_20033159
      +v_20033160 = arena_words_length(v_6)
      match v_20033160:
        case 0n:
          ArenaResult{v_20033161, +v_20033162} = core_subst(v_20033156, 0n, v_5, v_2)
          {ArenaResult{v_20033161, v_20033162} : ArenaResult<U32>}
        case _:
          v_8 = v_20033160
          ArenaResult{v_20033164, +v_20033165} = core_shift(v_20033156, 0n, v_8, v_5)
          v_10 = v_20033165
          ArenaResult{v_20033166, +v_20033167} = core_subst(v_20033164, 0n, v_10, v_2)
          ArenaResult{v_20033168, +v_20033169} = substitute_many(v_20033166, v_6, v_20033167)
          {ArenaResult{v_20033168, v_20033169} : ArenaResult<U32>}

def whnf_match_result(v_20033170: ArenaStore, v_1: PatternReduction, v_2: U32, v_4: IR.Words, v_6: IR.Words, v_8: Nat, v_9: U32, v_10: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  match v_1:
    case PatternValues{+v_20033171}:
      v_12 = v_20033171
      ArenaResult{v_20033172, +v_20033173} = arena_words_reverse(v_20033170, v_12)
      ArenaResult{v_20033174, +v_20033175} = substitute_many(v_20033172, v_20033173, v_2)
      ArenaResult{v_20033176, +v_20033177} = whnf(v_20033174, v_8, v_20033175, v_10)
      {ArenaResult{v_20033176, v_20033177} : ArenaResult<U32>}
    case PatternMismatch{}:
      ArenaResult{v_20033178, +v_20033179} = whnf_match_cases(v_20033170, v_4, v_6, v_8, v_9, v_10)
      {ArenaResult{v_20033178, v_20033179} : ArenaResult<U32>}
    case PatternStuck{}:
      {ArenaResult{v_20033170, v_9} : ArenaResult<U32>}

def whnf_match_cases(v_20033180: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_5: Nat, v_6: U32, v_7: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_20033181, +v_20033182} = arena_words_view(v_20033180, v_3)
  match v_20033182:
    case IR.WordCons{+v_20033185, +v_20033186}:
      ArenaResult{v_20033187, +v_20033188} = arena_get_node(v_20033181, v_20033185)
      match v_20033188:
        case Arena.TermCtr{+v_20033192, +v_20033194, +v_20033195, +v_20033197}:
          ArenaResult{v_20033198, +v_20033199} = arena_name_text(v_20033187, v_20033192)
          +v_20033193 = v_20033199
          v_12 = v_20033193
          ArenaResult{v_20033200, +v_20033201} = scope_body_cases_for_constructor(v_20033198, v_1, v_12, v_7)
          ArenaResult{v_20033202, +v_20033203} = whnf_match_cases_general(v_20033200, v_20033201, v_3, v_5, v_6, v_7)
          {ArenaResult{v_20033202, v_20033203} : ArenaResult<U32>}
        case _:
          ArenaResult{v_20033205, +v_20033206} = whnf_match_cases_general(v_20033187, v_1, v_3, v_5, v_6, v_7)
          {ArenaResult{v_20033205, v_20033206} : ArenaResult<U32>}
    case _:
      ArenaResult{v_20033208, +v_20033209} = whnf_match_cases_general(v_20033181, v_1, v_3, v_5, v_6, v_7)
      {ArenaResult{v_20033208, v_20033209} : ArenaResult<U32>}

def whnf_match_cases_general(v_20033210: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_5: Nat, v_6: U32, v_7: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_20033211, +v_20033212} = arena_words_view(v_20033210, v_1)
  match v_20033212:
    case IR.WordNil{}:
      {ArenaResult{v_20033211, v_6} : ArenaResult<U32>}
    case IR.WordCons{+v_20033215, +v_20033216}:
      ArenaResult{v_20033217, +v_20033218} = arena_get_node(v_20033211, v_20033215)
      match v_20033218:
        case Arena.BodyCase{+v_20033222, +v_20033223, +v_20033225, +v_20033226}:
          +v_20033224 = IR.Words{v_20033222, v_20033223}
          v_12 = v_20033224
          v_13 = v_20033225
          v_15 = v_20033216
          ArenaResult{v_20033227, +v_20033228} = whnf_patterns(v_20033217, v_12, v_3, v_5, v_7)
          ArenaResult{v_20033229, +v_20033230} = whnf_match_result(v_20033227, v_20033228, v_13, v_15, v_3, v_5, v_6, v_7)
          {ArenaResult{v_20033229, v_20033230} : ArenaResult<U32>}
        case _:
          {ArenaResult{v_20033217, v_6} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_20033211, v_6} : ArenaResult<U32>}

def destructuring_local_match(v_1: ArenaStore, v_3: String, v_4: IR.Words, v_5: Ast.SourceSpan, v_7: U32, v_9: U32, v_10: Ast.SourceSpan) -> ArenaResult<U32>:
  ArenaResult{v_17, +v_18} = arena_name(v_1, v_3)
  v_50000008 = arena_words_start(v_4)
  v_50000009 = arena_words_count(v_4)
  ArenaResult{v_24, +v_25} = arena_put_pattern(v_17, Arena.PatternCtr{v_18, v_50000008, v_50000009, v_5})
  v_27 = v_25
  ArenaResult{v_31, +v_32} = arena_words_cons(v_24, v_7, IR.Words{0, 0})
  ArenaResult{v_36, +v_37} = arena_words_cons(v_31, v_27, IR.Words{0, 0})
  v_50000010 = arena_words_start(v_37)
  v_50000011 = arena_words_count(v_37)
  ArenaResult{v_43, +v_44} = arena_put_node(v_36, Arena.BodyCase{v_50000010, v_50000011, v_9, v_10})
  ArenaResult{v_48, +v_49} = arena_words_cons(v_43, v_44, IR.Words{0, 0})
  v_50000012 = arena_words_start(v_32)
  v_50000013 = arena_words_count(v_32)
  v_50000014 = arena_words_start(v_49)
  v_50000015 = arena_words_count(v_49)
  ArenaResult{v_57, +v_58} = arena_put_node(v_48, Arena.BodyMatch{v_50000012, v_50000013, v_50000014, v_50000015, v_10})
  {ArenaResult{v_57, v_58} : ArenaResult<U32>}

def whnf(v_20033248: ArenaStore, v_1: Nat, v_2: U32, v_3: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  match v_1:
    case 0n:
      string_observe_zero(v_20033248, v_2)
    case 1n++v_20033249:
      v_5 = v_20033249
      ArenaResult{v_20033250, +v_20033251} = arena_get_node(v_20033248, v_2)
      match v_20033251:
        case Arena.TermString{chars, names, span}:
          string_unfold_store(v_20033250, chars, names, span)
        case Arena.TermSub{+v_20033256, +v_20033257, +v_20033258, +v_20033259}:
          v_10 = v_20033256
          v_11 = v_20033257
          v_12 = v_20033258
          ArenaResult{v_20033260, +v_20033261} = core_subst(v_20033250, v_10, v_11, v_12)
          ArenaResult{v_20033262, +v_20033263} = whnf(v_20033260, v_5, v_20033261, v_3)
          {ArenaResult{v_20033262, v_20033263} : ArenaResult<U32>}
        case Arena.TermAnn{+v_20033267, +v_20033268, +v_20033269}:
          v_18 = v_20033267
          ArenaResult{v_20033270, +v_20033271} = whnf(v_20033250, v_5, v_18, v_3)
          {ArenaResult{v_20033270, v_20033271} : ArenaResult<U32>}
        case Arena.BodyReply{+v_20033274, +v_20033275}:
          v_24 = v_20033274
          ArenaResult{v_20033276, +v_20033277} = whnf(v_20033250, v_5, v_24, v_3)
          {ArenaResult{v_20033276, v_20033277} : ArenaResult<U32>}
        case Arena.TermFill{+v_20033281, +v_20033282, +v_20033283, +v_20033285}:
          +v_20033284 = IR.Words{v_20033282, v_20033283}
          v_30 = v_20033281
          v_31 = v_20033284
          v_32 = v_20033285
          ArenaResult{v_20033286, +v_20033287} = lower_family_sugar(v_20033250, v_30, v_31, False{}, v_32, v_3)
          ArenaResult{v_20033288, +v_20033289} = family_lowered_whnf(v_20033286, v_5, v_2, v_3, v_20033287)
          {ArenaResult{v_20033288, v_20033289} : ArenaResult<U32>}
        case Arena.TermPlus{+v_20033293, +v_20033294, +v_20033295, +v_20033297}:
          +v_20033296 = IR.Words{v_20033294, v_20033295}
          v_38 = v_20033293
          v_39 = v_20033296
          v_40 = v_20033297
          ArenaResult{v_20033298, +v_20033299} = lower_family_sugar(v_20033250, v_38, v_39, True{}, v_40, v_3)
          ArenaResult{v_20033300, +v_20033301} = family_lowered_whnf(v_20033298, v_5, v_2, v_3, v_20033299)
          {ArenaResult{v_20033300, v_20033301} : ArenaResult<U32>}
        case Arena.TermRef{+v_20033304, +v_20033306}:
          ArenaResult{v_20033307, +v_20033308} = arena_name_text(v_20033250, v_20033304)
          +v_20033305 = v_20033308
          v_45 = v_20033305
          ArenaResult{v_20033309, +v_20033310} = whnf_ref_result(v_20033307, Scope.lookup(v_45, v_3), v_5, v_2, v_3)
          {ArenaResult{v_20033309, v_20033310} : ArenaResult<U32>}
        case Arena.TermApp{+v_20033314, +v_20033315, +v_20033316}:
          v_51 = v_20033314
          v_52 = v_20033315
          v_53 = v_20033316
          ArenaResult{v_20033317, +v_20033318} = application_type_view(v_20033250, v_51)
          ArenaResult{v_20033319, +v_20033320} = whnf(v_20033317, v_5, v_20033318, v_3)
          ArenaResult{v_20033321, +v_20033322} = whnf_application(v_20033319, v_20033320, v_5, v_2, v_52, v_3)
          {ArenaResult{v_20033321, v_20033322} : ArenaResult<U32>}
        case Arena.BodyLocal{+v_20033328, +v_20033329, +v_20033331, +v_20033332, +v_20033333, +v_20033335, +v_20033336}:
          +v_20033330 = IR.Words{v_20033328, v_20033329}
          +v_20033334 = IR.Words{v_20033332, v_20033333}
          ArenaResult{v_20033337, +v_20033338} = arena_words_view(v_20033250, v_20033330)
          match v_20033338:
            case IR.WordCons{+v_20033341, +v_20033342}:
              ArenaResult{v_20033343, +v_20033344} = arena_get_pattern(v_20033337, v_20033341)
              match v_20033344:
                case Arena.PatternCtr{+v_20033348, +v_20033350, +v_20033351, +v_20033353}:
                  ArenaResult{v_20033354, +v_20033355} = arena_name_text(v_20033343, v_20033348)
                  +v_20033349 = v_20033355
                  +v_20033352 = IR.Words{v_20033350, v_20033351}
                  ArenaResult{v_20033356, +v_20033357} = arena_words_view(v_20033354, v_20033342)
                  match v_20033357:
                    case IR.WordNil{}:
                      match v_20033331:
                        case Ast.QOne{}:
                          ArenaResult{v_20033358, +v_20033359} = arena_words_view(v_20033356, v_20033334)
                          match v_20033359:
                            case IR.WordCons{+v_20033362, +v_20033363}:
                              ArenaResult{v_20033364, +v_20033365} = arena_words_view(v_20033358, v_20033363)
                              match v_20033365:
                                case IR.WordNil{}:
                                  v_66 = v_20033362
                                  v_63 = v_20033349
                                  v_64 = v_20033352
                                  v_65 = v_20033353
                                  v_67 = v_20033335
                                  v_68 = v_20033336
                                  ArenaResult{v_20033366, +v_20033367} = destructuring_local_match(v_20033364, v_63, v_64, v_65, v_66, v_67, v_68)
                                  ArenaResult{v_20033368, +v_20033369} = whnf(v_20033366, v_5, v_20033367, v_3)
                                  {ArenaResult{v_20033368, v_20033369} : ArenaResult<U32>}
                                case _:
                                  {ArenaResult{v_20033364, v_2} : ArenaResult<U32>}
                            case _:
                              {ArenaResult{v_20033358, v_2} : ArenaResult<U32>}
                        case _:
                          {ArenaResult{v_20033356, v_2} : ArenaResult<U32>}
                    case _:
                      {ArenaResult{v_20033356, v_2} : ArenaResult<U32>}
                case _:
                  {ArenaResult{v_20033343, v_2} : ArenaResult<U32>}
            case _:
              {ArenaResult{v_20033337, v_2} : ArenaResult<U32>}
        case Arena.BodyMatch{+v_20033379, +v_20033380, +v_20033382, +v_20033383, +v_20033385}:
          +v_20033381 = IR.Words{v_20033379, v_20033380}
          +v_20033384 = IR.Words{v_20033382, v_20033383}
          v_74 = v_20033381
          v_75 = v_20033384
          ArenaResult{v_20033386, +v_20033387} = whnf_match_cases(v_20033250, v_75, v_74, v_5, v_2, v_3)
          {ArenaResult{v_20033386, v_20033387} : ArenaResult<U32>}
        case _:
          {ArenaResult{v_20033250, v_2} : ArenaResult<U32>}

def equal_term(v_20033389: ArenaStore, v_0: U32, v_1: U32, +v_2: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20033390, +v_20033391} = equal_raw(v_20033389, v_0, v_1, v_2)
  match v_20033391:
    case True{}:
      {ArenaResult{v_20033390, True{}} : ArenaResult<Bool>}
    case False{}:
      ArenaResult{v_20033392, +v_20033393} = whnf(v_20033390, 64n, v_0, v_2)
      ArenaResult{v_20033394, +v_20033395} = whnf(v_20033392, 64n, v_1, v_2)
      ArenaResult{v_20033396, +v_20033397} = equal_raw(v_20033394, v_20033393, v_20033395, v_2)
      {ArenaResult{v_20033396, v_20033397} : ArenaResult<Bool>}

def fits_kind_whnf(v_20033398: ArenaStore, v_0: U32, v_1: U32, v_2: U32, v_3: U32, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20033399, +v_20033400} = arena_get_node(v_20033398, v_0)
  match v_20033400:
    case Arena.TermQuantity{+v_20033409, +v_20033410}:
      match v_20033409:
        case Ast.QMany{}:
          {ArenaResult{v_20033399, True{}} : ArenaResult<Bool>}
        case _:
          ArenaResult{v_20033412, +v_20033413} = arena_get_node(v_20033399, v_1)
          match v_20033413:
            case Arena.TermQuantity{+v_20033416, +v_20033417}:
              match v_20033416:
                case Ast.QZero{}:
                  {ArenaResult{v_20033412, True{}} : ArenaResult<Bool>}
                case Ast.QOne{}:
                  {ArenaResult{v_20033412, True{}} : ArenaResult<Bool>}
                case _:
                  ArenaResult{v_20033419, +v_20033420} = equal_term(v_20033412, v_2, v_3, v_4)
                  {ArenaResult{v_20033419, v_20033420} : ArenaResult<Bool>}
            case Arena.TermMin{+v_20033424, +v_20033425, +v_20033426}:
              v_29 = v_20033424
              v_30 = v_20033425
              ArenaResult{v_20033427, +v_20033428} = fits_kind(v_20033412, v_2, v_29, v_4)
              ArenaResult{v_20033429, +v_20033430} = fits_kind(v_20033427, v_2, v_30, v_4)
              {ArenaResult{v_20033429, Bool.or(v_20033428, v_20033430)} : ArenaResult<Bool>}
            case _:
              ArenaResult{v_20033432, +v_20033433} = equal_term(v_20033412, v_2, v_3, v_4)
              {ArenaResult{v_20033432, v_20033433} : ArenaResult<Bool>}
    case Arena.TermMin{+v_20033446, +v_20033447, +v_20033448}:
      ArenaResult{v_20033449, +v_20033450} = arena_get_node(v_20033399, v_1)
      match v_20033450:
        case Arena.TermQuantity{+v_20033455, +v_20033456}:
          match v_20033455:
            case Ast.QZero{}:
              {ArenaResult{v_20033449, True{}} : ArenaResult<Bool>}
            case Ast.QOne{}:
              {ArenaResult{v_20033449, True{}} : ArenaResult<Bool>}
            case _:
              v_20 = v_20033446
              v_21 = v_20033447
              ArenaResult{v_20033458, +v_20033459} = fits_kind(v_20033449, v_20, v_3, v_4)
              ArenaResult{v_20033460, +v_20033461} = fits_kind(v_20033458, v_21, v_3, v_4)
              {ArenaResult{v_20033460, Bool.and(v_20033459, v_20033461)} : ArenaResult<Bool>}
        case Arena.TermMin{+v_20033468, +v_20033469, +v_20033470}:
          v_20 = v_20033446
          v_21 = v_20033447
          ArenaResult{v_20033471, +v_20033472} = fits_kind(v_20033449, v_20, v_3, v_4)
          ArenaResult{v_20033473, +v_20033474} = fits_kind(v_20033471, v_21, v_3, v_4)
          {ArenaResult{v_20033473, Bool.and(v_20033472, v_20033474)} : ArenaResult<Bool>}
        case _:
          v_20 = v_20033446
          v_21 = v_20033447
          ArenaResult{v_20033476, +v_20033477} = fits_kind(v_20033449, v_20, v_3, v_4)
          ArenaResult{v_20033478, +v_20033479} = fits_kind(v_20033476, v_21, v_3, v_4)
          {ArenaResult{v_20033478, Bool.and(v_20033477, v_20033479)} : ArenaResult<Bool>}
    case _:
      ArenaResult{v_20033481, +v_20033482} = arena_get_node(v_20033399, v_1)
      match v_20033482:
        case Arena.TermQuantity{+v_20033485, +v_20033486}:
          match v_20033485:
            case Ast.QZero{}:
              {ArenaResult{v_20033481, True{}} : ArenaResult<Bool>}
            case Ast.QOne{}:
              {ArenaResult{v_20033481, True{}} : ArenaResult<Bool>}
            case _:
              ArenaResult{v_20033488, +v_20033489} = equal_term(v_20033481, v_2, v_3, v_4)
              {ArenaResult{v_20033488, v_20033489} : ArenaResult<Bool>}
        case Arena.TermMin{+v_20033493, +v_20033494, +v_20033495}:
          v_29 = v_20033493
          v_30 = v_20033494
          ArenaResult{v_20033496, +v_20033497} = fits_kind(v_20033481, v_2, v_29, v_4)
          ArenaResult{v_20033498, +v_20033499} = fits_kind(v_20033496, v_2, v_30, v_4)
          {ArenaResult{v_20033498, Bool.or(v_20033497, v_20033499)} : ArenaResult<Bool>}
        case _:
          ArenaResult{v_20033501, +v_20033502} = equal_term(v_20033481, v_2, v_3, v_4)
          {ArenaResult{v_20033501, v_20033502} : ArenaResult<Bool>}

def fits_kind(v_20033503: ArenaStore, v_0: U32, v_1: U32, v_2: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20033504, +v_20033505} = whnf(v_20033503, 64n, v_0, v_2)
  ArenaResult{v_20033506, +v_20033507} = whnf(v_20033504, 64n, v_1, v_2)
  ArenaResult{v_20033508, +v_20033509} = fits_kind_whnf(v_20033506, v_20033505, v_20033507, v_0, v_1, v_2)
  {ArenaResult{v_20033508, v_20033509} : ArenaResult<Bool>}

def refs_contain_all(v_20033510: ArenaStore, v_2: IR.Names, v_5: IR.Names, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20033511, +v_20033512} = arena_names_view(v_20033510, v_2)
  match v_20033512:
    case IR.NameNil{}:
      {ArenaResult{v_20033511, True{}} : ArenaResult<Bool>}
    case IR.NameCons{+v_20033513, +v_20033514}:
      +v_10 = v_20033513
      v_11 = v_20033514
      ArenaResult{v_20033517, +v_20033518} = has_canonical_name(v_20033511, v_10, v_5, v_6)
      +v_20033519 = v_20033518
      match v_20033519:
        case False{}:
          +v_20033515 = False{}
          v_20033516 = v_20033517
          {ArenaResult{v_20033516, v_20033515} : ArenaResult<Bool>}
        case True{}:
          ArenaResult{v_20033520, +v_20033521} = refs_contain_all(v_20033517, v_11, v_5, v_6)
          +v_20033515 = v_20033521
          v_20033516 = v_20033520
          {ArenaResult{v_20033516, v_20033515} : ArenaResult<Bool>}

def fits_term_whnf(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_13, +v_14} = arena_get_node(v_1, v_3)
  match v_14:
    case Arena.TermType{+v_17, +v_18}:
      ArenaResult{v_22, +v_23} = arena_get_node(v_13, v_5)
      match v_23:
        case Arena.TermType{+v_26, +v_27}:
          v_29 = v_26
          v_31 = v_17
          ArenaResult{v_35, +v_36} = fits_kind(v_22, v_31, v_29, v_6)
          {ArenaResult{v_35, v_36} : ArenaResult<Bool>}
        case _:
          ArenaResult{v_42, +v_43} = equal_term(v_22, v_3, v_5, v_6)
          {ArenaResult{v_42, v_43} : ArenaResult<Bool>}
    case Arena.TermAll{+v_50, +v_51, +v_52, +v_53, +v_54, +v_55}:
      ArenaResult{v_59, +v_60} = arena_get_node(v_13, v_5)
      match v_60:
        case Arena.TermAll{+v_67, +v_68, +v_69, +v_70, +v_71, +v_72}:
          v_74 = v_67
          v_76 = v_70
          v_78 = v_71
          v_80 = v_50
          v_82 = v_53
          v_84 = v_54
          ArenaResult{v_88, +v_89} = fits_term(v_59, v_76, v_82, v_6)
          ArenaResult{v_93, +v_94} = fits_term(v_88, v_84, v_78, v_6)
          v_50000016 = Bool.and(same_quantity(v_80, v_74), Bool.and(v_89, v_94))
          {ArenaResult{v_93, v_50000016} : ArenaResult<Bool>}
        case _:
          ArenaResult{v_101, +v_102} = equal_term(v_59, v_3, v_5, v_6)
          {ArenaResult{v_101, v_102} : ArenaResult<Bool>}
    case Arena.TermAdt{+v_109, +v_110, +v_111, +v_112, +v_113, +v_114}:
      ArenaResult{v_118, +v_119} = arena_name_text(v_13, v_109)
      +v_121 = v_119
      +v_123 = IR.Words{v_110, v_111}
      +v_125 = IR.Names{v_112, v_113}
      ArenaResult{v_129, +v_130} = arena_get_node(v_118, v_5)
      match v_130:
        case Arena.TermAdt{+v_137, +v_138, +v_139, +v_140, +v_141, +v_142}:
          ArenaResult{v_146, +v_147} = arena_name_text(v_129, v_137)
          +v_149 = v_147
          +v_151 = IR.Words{v_138, v_139}
          +v_153 = IR.Names{v_140, v_141}
          v_155 = v_149
          v_157 = v_151
          v_159 = v_153
          v_161 = v_121
          v_163 = v_123
          v_165 = v_125
          ArenaResult{v_169, +v_170} = equal_lists(v_146, v_163, v_157, v_6)
          ArenaResult{v_174, +v_175} = refs_contain_all(v_169, v_159, v_165, v_6)
          v_50000017 = Bool.and(Scope.equal_names(v_161, v_155, v_6), Bool.and(v_170, v_175))
          {ArenaResult{v_174, v_50000017} : ArenaResult<Bool>}
        case _:
          ArenaResult{v_182, +v_183} = equal_term(v_129, v_3, v_5, v_6)
          {ArenaResult{v_182, v_183} : ArenaResult<Bool>}
    case _:
      ArenaResult{v_189, +v_190} = equal_term(v_13, v_3, v_5, v_6)
      {ArenaResult{v_189, v_190} : ArenaResult<Bool>}

def fits_term(v_20033617: ArenaStore, v_0: U32, v_1: U32, v_2: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20033618, +v_20033619} = equal_raw(v_20033617, v_0, v_1, v_2)
  match v_20033619:
    case True{}:
      {ArenaResult{v_20033618, True{}} : ArenaResult<Bool>}
    case False{}:
      ArenaResult{v_20033620, +v_20033621} = whnf(v_20033618, 64n, v_0, v_2)
      ArenaResult{v_20033622, +v_20033623} = whnf(v_20033620, 64n, v_1, v_2)
      ArenaResult{v_20033624, +v_20033625} = fits_term_whnf(v_20033622, v_20033621, v_20033623, v_2)
      {ArenaResult{v_20033624, v_20033625} : ArenaResult<Bool>}

def fits_term_target_view(v_20033626: ArenaStore, v_0: U32, v_1: U32, v_2: U32, v_3: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20033627, +v_20033628} = equal_raw(v_20033626, v_0, v_1, v_3)
  match v_20033628:
    case True{}:
      {ArenaResult{v_20033627, True{}} : ArenaResult<Bool>}
    case False{}:
      ArenaResult{v_20033629, +v_20033630} = whnf(v_20033627, 64n, v_0, v_3)
      ArenaResult{v_20033631, +v_20033632} = fits_term_whnf(v_20033629, v_20033630, v_2, v_3)
      {ArenaResult{v_20033631, v_20033632} : ArenaResult<Bool>}

# Full handles identify one immutable term in this threaded store and scope.
# Reflexivity must precede unfolding: neutral recursive branch bodies can
# otherwise re-enter equality on the exact same source handle indefinitely.
def equal_raw(store: ArenaStore, left: U32, right: U32, scope: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  equal_raw_identity(U32.is_eq(left, right), store, left, right, scope)

def equal_raw_identity(same: Bool, store: ArenaStore, left: U32, right: U32, scope: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match same:
    case True{}: {ArenaResult{store, True{}} : ArenaResult<Bool>}
    case False{}: equal_raw_distinct(store, left, right, scope)

def equal_raw_ordinary(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_13, +v_14} = arena_get_node(v_1, v_3)
  match v_14:
    case Arena.TermType{+v_17, +v_18}:
      ArenaResult{v_22, +v_23} = arena_get_node(v_13, v_5)
      match v_23:
        case Arena.TermType{+v_26, +v_27}:
          v_29 = v_26
          v_31 = v_17
          ArenaResult{v_35, +v_36} = equal_term(v_22, v_31, v_29, v_6)
          {ArenaResult{v_35, v_36} : ArenaResult<Bool>}
        case Arena.TermBang{+v_39, +v_40}:
          v_42 = v_39
          ArenaResult{v_46, +v_47} = equal_term(v_22, v_3, v_42, v_6)
          {ArenaResult{v_46, v_47} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_22, False{}} : ArenaResult<Bool>}
    case Arena.TermQuantity{+v_52, +v_53}:
      ArenaResult{v_57, +v_58} = arena_get_node(v_13, v_5)
      match v_58:
        case Arena.TermQuantity{+v_61, +v_62}:
          v_64 = v_61
          v_66 = v_52
          v_50000018 = same_quantity(v_66, v_64)
          {ArenaResult{v_57, v_50000018} : ArenaResult<Bool>}
        case Arena.TermBang{+v_70, +v_71}:
          v_73 = v_70
          ArenaResult{v_77, +v_78} = equal_term(v_57, v_3, v_73, v_6)
          {ArenaResult{v_77, v_78} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_57, False{}} : ArenaResult<Bool>}
    case Arena.TermQuant{}:
      ArenaResult{v_84, +v_85} = arena_get_node(v_13, v_5)
      match v_85:
        case Arena.TermQuant{}:
          {ArenaResult{v_84, True{}} : ArenaResult<Bool>}
        case Arena.TermBang{+v_88, +v_89}:
          v_91 = v_88
          ArenaResult{v_95, +v_96} = equal_term(v_84, v_3, v_91, v_6)
          {ArenaResult{v_95, v_96} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_84, False{}} : ArenaResult<Bool>}
    case Arena.TermBang{+v_101, +v_102}:
      ArenaResult{v_106, +v_107} = arena_get_node(v_13, v_5)
      match v_107:
        case Arena.TermBang{+v_110, +v_111}:
          v_113 = v_110
          v_115 = v_101
          ArenaResult{v_119, +v_120} = equal_term(v_106, v_115, v_113, v_6)
          {ArenaResult{v_119, v_120} : ArenaResult<Bool>}
        case _:
          v_124 = v_101
          ArenaResult{v_128, +v_129} = equal_term(v_106, v_124, v_5, v_6)
          {ArenaResult{v_128, v_129} : ArenaResult<Bool>}
    case Arena.TermVar{+v_133, +v_134, +v_135}:
      ArenaResult{v_139, +v_140} = arena_get_node(v_13, v_5)
      match v_140:
        case Arena.TermBang{+v_143, +v_144}:
          v_146 = v_143
          ArenaResult{v_150, +v_151} = equal_term(v_139, v_3, v_146, v_6)
          {ArenaResult{v_150, v_151} : ArenaResult<Bool>}
        case Arena.TermVar{+v_155, +v_156, +v_157}:
          v_159 = v_156
          v_161 = v_134
          {ArenaResult{v_139, Nat.is_eq(v_161, v_159)} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_139, False{}} : ArenaResult<Bool>}
    case Arena.TermRef{+v_166, +v_167}:
      ArenaResult{v_171, +v_172} = arena_name_text(v_13, v_166)
      +v_174 = v_172
      ArenaResult{v_178, +v_179} = arena_get_node(v_171, v_5)
      match v_179:
        case Arena.TermBang{+v_182, +v_183}:
          v_185 = v_182
          ArenaResult{v_189, +v_190} = equal_term(v_178, v_3, v_185, v_6)
          {ArenaResult{v_189, v_190} : ArenaResult<Bool>}
        case Arena.TermRef{+v_193, +v_194}:
          ArenaResult{v_198, +v_199} = arena_name_text(v_178, v_193)
          +v_201 = v_199
          v_203 = v_201
          v_205 = v_174
          v_50000019 = Scope.equal_names(v_205, v_203, v_6)
          {ArenaResult{v_198, v_50000019} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_178, False{}} : ArenaResult<Bool>}
    case Arena.TermAll{+v_215, +v_216, +v_217, +v_218, +v_219, +v_220}:
      ArenaResult{v_224, +v_225} = arena_get_node(v_13, v_5)
      match v_225:
        case Arena.TermBang{+v_228, +v_229}:
          v_231 = v_228
          ArenaResult{v_235, +v_236} = equal_term(v_224, v_3, v_231, v_6)
          {ArenaResult{v_235, v_236} : ArenaResult<Bool>}
        case Arena.TermAll{+v_243, +v_244, +v_245, +v_246, +v_247, +v_248}:
          v_250 = v_243
          v_252 = v_246
          v_254 = v_247
          v_256 = v_215
          v_258 = v_218
          v_260 = v_219
          +v_263 = same_quantity(v_256, v_250)
          match v_263:
            case False{}:
              +v_265 = False{}
              v_267 = v_224
              {ArenaResult{v_267, v_265} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_272, +v_273} = equal_term(v_224, v_258, v_252, v_6)
              +v_275 = v_273
              match v_275:
                case False{}:
                  +v_277 = False{}
                  v_279 = v_272
                  {ArenaResult{v_279, v_277} : ArenaResult<Bool>}
                case True{}:
                  ArenaResult{v_284, +v_285} = equal_term(v_272, v_260, v_254, v_6)
                  +v_287 = v_285
                  v_289 = v_284
                  {ArenaResult{v_289, v_287} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_224, False{}} : ArenaResult<Bool>}
    case Arena.TermLam{+v_298, +v_299, +v_300, +v_301, +v_302}:
      ArenaResult{v_306, +v_307} = arena_get_node(v_13, v_5)
      match v_307:
        case Arena.TermBang{+v_310, +v_311}:
          v_313 = v_310
          ArenaResult{v_317, +v_318} = equal_term(v_306, v_3, v_313, v_6)
          {ArenaResult{v_317, v_318} : ArenaResult<Bool>}
        case Arena.TermLam{+v_324, +v_325, +v_326, +v_327, +v_328}:
          v_330 = v_327
          v_332 = v_301
          ArenaResult{v_336, +v_337} = equal_term(v_306, v_332, v_330, v_6)
          {ArenaResult{v_336, v_337} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_306, False{}} : ArenaResult<Bool>}
    case Arena.TermApp{+v_343, +v_344, +v_345}:
      ArenaResult{v_349, +v_350} = arena_get_node(v_13, v_5)
      match v_350:
        case Arena.TermBang{+v_353, +v_354}:
          v_356 = v_353
          ArenaResult{v_360, +v_361} = equal_term(v_349, v_3, v_356, v_6)
          {ArenaResult{v_360, v_361} : ArenaResult<Bool>}
        case Arena.TermApp{+v_365, +v_366, +v_367}:
          v_369 = v_365
          v_371 = v_366
          v_373 = v_343
          v_375 = v_344
          ArenaResult{v_379, +v_380} = equal_term(v_349, v_373, v_369, v_6)
          +v_382 = v_380
          match v_382:
            case False{}:
              +v_384 = False{}
              v_386 = v_379
              {ArenaResult{v_386, v_384} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_391, +v_392} = equal_term(v_379, v_375, v_371, v_6)
              +v_394 = v_392
              v_396 = v_391
              {ArenaResult{v_396, v_394} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_349, False{}} : ArenaResult<Bool>}
    case Arena.TermAdt{+v_406, +v_407, +v_408, +v_409, +v_410, +v_411}:
      ArenaResult{v_415, +v_416} = arena_name_text(v_13, v_406)
      +v_418 = v_416
      +v_420 = IR.Words{v_407, v_408}
      +v_422 = IR.Names{v_409, v_410}
      ArenaResult{v_426, +v_427} = arena_get_node(v_415, v_5)
      match v_427:
        case Arena.TermBang{+v_430, +v_431}:
          v_433 = v_430
          ArenaResult{v_437, +v_438} = equal_term(v_426, v_3, v_433, v_6)
          {ArenaResult{v_437, v_438} : ArenaResult<Bool>}
        case Arena.TermAdt{+v_445, +v_446, +v_447, +v_448, +v_449, +v_450}:
          ArenaResult{v_454, +v_455} = arena_name_text(v_426, v_445)
          +v_457 = v_455
          +v_459 = IR.Words{v_446, v_447}
          +v_461 = IR.Names{v_448, v_449}
          v_463 = v_457
          v_465 = v_459
          v_467 = v_461
          v_469 = v_418
          v_471 = v_420
          v_473 = v_422
          +v_476 = Scope.equal_names(v_469, v_463, v_6)
          match v_476:
            case False{}:
              +v_478 = False{}
              v_480 = v_454
              {ArenaResult{v_480, v_478} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_485, +v_486} = equal_lists(v_454, v_471, v_465, v_6)
              +v_488 = v_486
              match v_488:
                case False{}:
                  +v_490 = False{}
                  v_492 = v_485
                  {ArenaResult{v_492, v_490} : ArenaResult<Bool>}
                case True{}:
                  ArenaResult{v_497, +v_498} = equal_refs(v_485, v_473, v_467, v_6)
                  +v_500 = v_498
                  v_502 = v_497
                  {ArenaResult{v_502, v_500} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_426, False{}} : ArenaResult<Bool>}
    case Arena.TermCtr{+v_510, +v_511, +v_512, +v_513}:
      ArenaResult{v_517, +v_518} = arena_name_text(v_13, v_510)
      +v_520 = v_518
      +v_522 = IR.Words{v_511, v_512}
      ArenaResult{v_526, +v_527} = arena_get_node(v_517, v_5)
      match v_527:
        case Arena.TermBang{+v_530, +v_531}:
          v_533 = v_530
          ArenaResult{v_537, +v_538} = equal_term(v_526, v_3, v_533, v_6)
          {ArenaResult{v_537, v_538} : ArenaResult<Bool>}
        case Arena.TermCtr{+v_543, +v_544, +v_545, +v_546}:
          ArenaResult{v_550, +v_551} = arena_name_text(v_526, v_543)
          +v_553 = v_551
          +v_555 = IR.Words{v_544, v_545}
          v_557 = v_553
          v_559 = v_555
          v_561 = v_520
          v_563 = v_522
          +v_566 = Scope.equal_names(v_561, v_557, v_6)
          match v_566:
            case False{}:
              +v_568 = False{}
              v_570 = v_550
              {ArenaResult{v_570, v_568} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_575, +v_576} = equal_lists(v_550, v_563, v_559, v_6)
              +v_578 = v_576
              v_580 = v_575
              {ArenaResult{v_580, v_578} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_526, False{}} : ArenaResult<Bool>}
    case Arena.TermEqual{+v_588, +v_589, +v_590, +v_591}:
      ArenaResult{v_595, +v_596} = arena_get_node(v_13, v_5)
      match v_596:
        case Arena.TermBang{+v_599, +v_600}:
          v_602 = v_599
          ArenaResult{v_606, +v_607} = equal_term(v_595, v_3, v_602, v_6)
          {ArenaResult{v_606, v_607} : ArenaResult<Bool>}
        case Arena.TermEqual{+v_612, +v_613, +v_614, +v_615}:
          v_617 = v_612
          v_619 = v_613
          v_621 = v_614
          v_623 = v_588
          v_625 = v_589
          v_627 = v_590
          ArenaResult{v_631, +v_632} = equal_term(v_595, v_623, v_617, v_6)
          +v_634 = v_632
          match v_634:
            case False{}:
              +v_636 = False{}
              v_638 = v_631
              {ArenaResult{v_638, v_636} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_643, +v_644} = equal_term(v_631, v_625, v_619, v_6)
              +v_646 = v_644
              match v_646:
                case False{}:
                  +v_648 = False{}
                  v_650 = v_643
                  {ArenaResult{v_650, v_648} : ArenaResult<Bool>}
                case True{}:
                  ArenaResult{v_655, +v_656} = equal_term(v_643, v_627, v_621, v_6)
                  +v_658 = v_656
                  v_660 = v_655
                  {ArenaResult{v_660, v_658} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_595, False{}} : ArenaResult<Bool>}
    case Arena.BodyMatch{+v_669, +v_670, +v_671, +v_672, +v_673}:
      +v_675 = IR.Words{v_669, v_670}
      +v_677 = IR.Words{v_671, v_672}
      ArenaResult{v_681, +v_682} = arena_get_node(v_13, v_5)
      match v_682:
        case Arena.TermBang{+v_685, +v_686}:
          v_688 = v_685
          ArenaResult{v_692, +v_693} = equal_term(v_681, v_3, v_688, v_6)
          {ArenaResult{v_692, v_693} : ArenaResult<Bool>}
        case Arena.BodyMatch{+v_699, +v_700, +v_701, +v_702, +v_703}:
          +v_705 = IR.Words{v_699, v_700}
          +v_707 = IR.Words{v_701, v_702}
          v_709 = v_705
          v_711 = v_707
          v_713 = v_675
          v_715 = v_677
          ArenaResult{v_719, +v_720} = equal_lists(v_681, v_713, v_709, v_6)
          +v_722 = v_720
          match v_722:
            case False{}:
              +v_724 = False{}
              v_726 = v_719
              {ArenaResult{v_726, v_724} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_731, +v_732} = equal_match_cases(v_719, v_715, v_711, v_6)
              +v_734 = v_732
              v_736 = v_731
              {ArenaResult{v_736, v_734} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_681, False{}} : ArenaResult<Bool>}
    case Arena.TermHole{+v_742, +v_743}:
      ArenaResult{v_747, +v_748} = arena_name_text(v_13, v_742)
      +v_750 = v_748
      ArenaResult{v_754, +v_755} = arena_get_node(v_747, v_5)
      match v_755:
        case Arena.TermBang{+v_758, +v_759}:
          v_761 = v_758
          ArenaResult{v_765, +v_766} = equal_term(v_754, v_3, v_761, v_6)
          {ArenaResult{v_765, v_766} : ArenaResult<Bool>}
        case Arena.TermHole{+v_769, +v_770}:
          ArenaResult{v_774, +v_775} = arena_name_text(v_754, v_769)
          +v_777 = v_775
          v_779 = v_777
          v_781 = v_750
          {ArenaResult{v_774, String.eq(v_781, v_779)} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_754, False{}} : ArenaResult<Bool>}
    case _:
      ArenaResult{v_789, +v_790} = arena_get_node(v_13, v_5)
      match v_790:
        case Arena.TermBang{+v_793, +v_794}:
          v_796 = v_793
          ArenaResult{v_800, +v_801} = equal_term(v_789, v_3, v_796, v_6)
          {ArenaResult{v_800, v_801} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_789, False{}} : ArenaResult<Bool>}

def equal_refs(v_20034084: ArenaStore, v_2: IR.Names, v_5: IR.Names, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20034085, +v_20034086} = arena_names_view(v_20034084, v_2)
  match v_20034086:
    case IR.NameNil{}:
      ArenaResult{v_20034087, +v_20034088} = arena_names_view(v_20034085, v_5)
      match v_20034088:
        case IR.NameNil{}:
          {ArenaResult{v_20034087, True{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20034087, False{}} : ArenaResult<Bool>}
    case IR.NameCons{+v_20034092, +v_20034093}:
      ArenaResult{v_20034094, +v_20034095} = arena_names_view(v_20034085, v_5)
      match v_20034095:
        case IR.NameCons{+v_20034098, +v_20034099}:
          +v_14 = v_20034098
          v_15 = v_20034099
          +v_12 = v_20034092
          v_13 = v_20034093
          +v_20034102 = Scope.equal_names(v_12, v_14, v_6)
          match v_20034102:
            case False{}:
              +v_20034100 = False{}
              v_20034101 = v_20034094
              {ArenaResult{v_20034101, v_20034100} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_20034103, +v_20034104} = equal_refs(v_20034094, v_13, v_15, v_6)
              +v_20034100 = v_20034104
              v_20034101 = v_20034103
              {ArenaResult{v_20034101, v_20034100} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20034094, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20034085, False{}} : ArenaResult<Bool>}

def equal_lists_constructor_result(v_20034107: ArenaStore, v_2: Maybe<&2, Bool>, v_4: IR.Words, v_6: IR.Words, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_2:
    case Some{+v_20034108}:
      v_10 = v_20034108
      {ArenaResult{v_20034107, v_10} : ArenaResult<Bool>}
    case None{}:
      ArenaResult{v_20034109, +v_20034110} = equal_lists_general(v_20034107, v_4, v_6, v_7)
      {ArenaResult{v_20034109, v_20034110} : ArenaResult<Bool>}

def equal_lists(v_20034111: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20034112, +v_20034113} = scope_constructor_lists_equal(v_20034111, v_1, v_3, v_4)
  ArenaResult{v_20034114, +v_20034115} = equal_lists_constructor_result(v_20034112, v_20034113, v_1, v_3, v_4)
  {ArenaResult{v_20034114, v_20034115} : ArenaResult<Bool>}

def equal_lists_general(v_20034116: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20034117, +v_20034118} = arena_words_view(v_20034116, v_1)
  match v_20034118:
    case IR.WordNil{}:
      ArenaResult{v_20034119, +v_20034120} = arena_words_view(v_20034117, v_3)
      match v_20034120:
        case IR.WordNil{}:
          {ArenaResult{v_20034119, True{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20034119, False{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20034124, +v_20034125}:
      ArenaResult{v_20034126, +v_20034127} = arena_words_view(v_20034117, v_3)
      match v_20034127:
        case IR.WordCons{+v_20034130, +v_20034131}:
          +v_12 = v_20034130
          v_13 = v_20034131
          +v_10 = v_20034124
          v_11 = v_20034125
          ArenaResult{v_20034134, +v_20034135} = equal_term(v_20034126, v_10, v_12, v_4)
          +v_20034136 = v_20034135
          match v_20034136:
            case False{}:
              +v_20034132 = False{}
              v_20034133 = v_20034134
              {ArenaResult{v_20034133, v_20034132} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_20034137, +v_20034138} = equal_lists(v_20034134, v_11, v_13, v_4)
              +v_20034132 = v_20034138
              v_20034133 = v_20034137
              {ArenaResult{v_20034133, v_20034132} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20034126, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20034117, False{}} : ArenaResult<Bool>}

def equal_match_patterns(v_20034141: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20034142, +v_20034143} = arena_words_view(v_20034141, v_1)
  match v_20034143:
    case IR.WordNil{}:
      ArenaResult{v_20034144, +v_20034145} = arena_words_view(v_20034142, v_3)
      match v_20034145:
        case IR.WordNil{}:
          {ArenaResult{v_20034144, True{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20034144, False{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20034149, +v_20034150}:
      ArenaResult{v_20034151, +v_20034152} = arena_get_pattern(v_20034142, v_20034149)
      match v_20034152:
        case Arena.PatternVar{+v_20034157, +v_20034159, +v_20034160, +v_20034161}:
          ArenaResult{v_20034162, +v_20034163} = arena_words_view(v_20034151, v_3)
          match v_20034163:
            case IR.WordCons{+v_20034166, +v_20034167}:
              ArenaResult{v_20034168, +v_20034169} = arena_get_pattern(v_20034162, v_20034166)
              match v_20034169:
                case Arena.PatternVar{+v_20034174, +v_20034176, +v_20034177, +v_20034178}:
                  v_23 = v_20034177
                  v_25 = v_20034167
                  v_18 = v_20034160
                  v_20 = v_20034150
                  +v_20034181 = same_quantity(v_18, v_23)
                  match v_20034181:
                    case False{}:
                      +v_20034179 = False{}
                      v_20034180 = v_20034168
                      {ArenaResult{v_20034180, v_20034179} : ArenaResult<Bool>}
                    case True{}:
                      ArenaResult{v_20034182, +v_20034183} = equal_match_patterns(v_20034168, v_20, v_25, v_4)
                      +v_20034179 = v_20034183
                      v_20034180 = v_20034182
                      {ArenaResult{v_20034180, v_20034179} : ArenaResult<Bool>}
                case _:
                  {ArenaResult{v_20034168, False{}} : ArenaResult<Bool>}
            case _:
              {ArenaResult{v_20034162, False{}} : ArenaResult<Bool>}
        case Arena.PatternCtr{+v_20034189, +v_20034191, +v_20034192, +v_20034194}:
          ArenaResult{v_20034195, +v_20034196} = arena_name_text(v_20034151, v_20034189)
          +v_20034190 = v_20034196
          +v_20034193 = IR.Words{v_20034191, v_20034192}
          ArenaResult{v_20034197, +v_20034198} = arena_words_view(v_20034195, v_3)
          match v_20034198:
            case IR.WordCons{+v_20034201, +v_20034202}:
              ArenaResult{v_20034203, +v_20034204} = arena_get_pattern(v_20034197, v_20034201)
              match v_20034204:
                case Arena.PatternCtr{+v_20034208, +v_20034210, +v_20034211, +v_20034213}:
                  ArenaResult{v_20034214, +v_20034215} = arena_name_text(v_20034203, v_20034208)
                  +v_20034209 = v_20034215
                  +v_20034212 = IR.Words{v_20034210, v_20034211}
                  v_41 = v_20034209
                  v_42 = v_20034212
                  v_44 = v_20034202
                  v_37 = v_20034190
                  v_38 = v_20034193
                  v_40 = v_20034150
                  +v_20034218 = Scope.equal_names(v_37, v_41, v_4)
                  match v_20034218:
                    case False{}:
                      +v_20034216 = False{}
                      v_20034217 = v_20034214
                      {ArenaResult{v_20034217, v_20034216} : ArenaResult<Bool>}
                    case True{}:
                      ArenaResult{v_20034221, +v_20034222} = equal_match_patterns(v_20034214, v_38, v_42, v_4)
                      +v_20034223 = v_20034222
                      match v_20034223:
                        case False{}:
                          +v_20034219 = False{}
                          v_20034220 = v_20034221
                          {ArenaResult{v_20034220, v_20034219} : ArenaResult<Bool>}
                        case True{}:
                          ArenaResult{v_20034224, +v_20034225} = equal_match_patterns(v_20034221, v_40, v_44, v_4)
                          +v_20034219 = v_20034225
                          v_20034220 = v_20034224
                          {ArenaResult{v_20034220, v_20034219} : ArenaResult<Bool>}
                case _:
                  {ArenaResult{v_20034203, False{}} : ArenaResult<Bool>}
            case _:
              {ArenaResult{v_20034197, False{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20034151, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20034142, False{}} : ArenaResult<Bool>}

def equal_match_case_bodies(v_20034230: ArenaStore, v_1: Bool, v_2: U32, v_3: U32, v_5: IR.Words, v_7: IR.Words, v_8: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_1:
    case True{}:
      ArenaResult{v_20034233, +v_20034234} = equal_term(v_20034230, v_2, v_3, v_8)
      +v_20034235 = v_20034234
      match v_20034235:
        case False{}:
          +v_20034231 = False{}
          v_20034232 = v_20034233
          {ArenaResult{v_20034232, v_20034231} : ArenaResult<Bool>}
        case True{}:
          ArenaResult{v_20034236, +v_20034237} = equal_match_cases(v_20034233, v_5, v_7, v_8)
          +v_20034231 = v_20034237
          v_20034232 = v_20034236
          {ArenaResult{v_20034232, v_20034231} : ArenaResult<Bool>}
    case False{}:
      {ArenaResult{v_20034230, False{}} : ArenaResult<Bool>}

def equal_match_cases(v_20034238: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20034239, +v_20034240} = arena_words_view(v_20034238, v_1)
  match v_20034240:
    case IR.WordNil{}:
      ArenaResult{v_20034241, +v_20034242} = arena_words_view(v_20034239, v_3)
      match v_20034242:
        case IR.WordNil{}:
          {ArenaResult{v_20034241, True{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20034241, False{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20034246, +v_20034247}:
      ArenaResult{v_20034248, +v_20034249} = arena_get_node(v_20034239, v_20034246)
      match v_20034249:
        case Arena.BodyCase{+v_20034253, +v_20034254, +v_20034256, +v_20034257}:
          +v_20034255 = IR.Words{v_20034253, v_20034254}
          ArenaResult{v_20034258, +v_20034259} = arena_words_view(v_20034248, v_3)
          match v_20034259:
            case IR.WordCons{+v_20034262, +v_20034263}:
              ArenaResult{v_20034264, +v_20034265} = arena_get_node(v_20034258, v_20034262)
              match v_20034265:
                case Arena.BodyCase{+v_20034269, +v_20034270, +v_20034272, +v_20034273}:
                  +v_20034271 = IR.Words{v_20034269, v_20034270}
                  v_18 = v_20034271
                  v_19 = v_20034272
                  v_21 = v_20034263
                  v_14 = v_20034255
                  v_15 = v_20034256
                  v_17 = v_20034247
                  ArenaResult{v_20034274, +v_20034275} = equal_match_patterns(v_20034264, v_14, v_18, v_4)
                  ArenaResult{v_20034276, +v_20034277} = equal_match_case_bodies(v_20034274, v_20034275, v_15, v_19, v_17, v_21, v_4)
                  {ArenaResult{v_20034276, v_20034277} : ArenaResult<Bool>}
                case _:
                  {ArenaResult{v_20034264, False{}} : ArenaResult<Bool>}
            case _:
              {ArenaResult{v_20034258, False{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20034248, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20034239, False{}} : ArenaResult<Bool>}

def infer_adt_args_view(v_1: ArenaStore, v_2: IR.Words, v_4: U32, v_6: U32, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope, v_12: U32, v_13: Ast.SourceSpan) -> ArenaResult<Inference>:
  ArenaResult{v_20, +v_21} = arena_words_view(v_1, v_2)
  match v_21:
    case IR.WordNil{}:
      ArenaResult{v_25, +v_26} = arena_get_node(v_20, v_6)
      match v_26:
        case Arena.TermAll{+v_33, +v_34, +v_35, +v_36, +v_37, +v_38}:
          v_50000020 = fail(v_13, "datatype has too few parameters", "all family parameters", "an underapplied family")
          {ArenaResult{v_25, v_50000020} : ArenaResult<Inference>}
        case _:
          {ArenaResult{v_25, Inferred{v_12, v_4}} : ArenaResult<Inference>}
    case IR.WordCons{+v_44, +v_45}:
      +v_47 = v_44
      v_49 = v_45
      ArenaResult{v_53, +v_54} = arena_get_node(v_20, v_6)
      match v_54:
        case Arena.TermAll{+v_61, +v_62, +v_63, +v_64, +v_65, +v_66}:
          v_68 = v_64
          v_70 = v_65
          ArenaResult{v_74, +v_75} = check_term(v_53, v_47, v_9, v_10, v_68)
          ArenaResult{v_79, +v_80} = infer_adt_arg_check(v_74, v_75, v_49, v_70, v_9, v_10, v_12, v_13)
          {ArenaResult{v_79, v_80} : ArenaResult<Inference>}
        case _:
          v_50000021 = fail(v_13, "datatype has too many parameters", "a remaining parameter", "an extra parameter")
          {ArenaResult{v_53, v_50000021} : ArenaResult<Inference>}

def infer_adt_arg_check(v_20034323: ArenaStore, v_1: Inference, v_3: IR.Words, v_4: U32, v_7: List<&2, Binding>, v_8: Scope.ArenaGlobalScope, v_9: U32, v_10: Ast.SourceSpan) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20034324, +v_20034325}:
      v_14 = v_20034324
      ArenaResult{v_20034326, +v_20034327} = core_subst(v_20034323, 0n, v_14, v_4)
      ArenaResult{v_20034328, +v_20034329} = infer_adt_args(v_20034326, v_3, v_20034327, v_7, v_8, v_9, v_10)
      {ArenaResult{v_20034328, v_20034329} : ArenaResult<Inference>}
    case InferenceFailure{+v_20034330}:
      v_18 = v_20034330
      {ArenaResult{v_20034323, InferenceFailure{v_18}} : ArenaResult<Inference>}

def infer_adt_args(v_20034331: ArenaStore, v_1: IR.Words, v_2: U32, v_5: List<&2, Binding>, v_6: Scope.ArenaGlobalScope, v_7: U32, v_8: Ast.SourceSpan) -> ArenaResult<Inference>:
  ArenaResult{v_20034332, +v_20034333} = whnf(v_20034331, 64n, v_2, v_6)
  ArenaResult{v_20034334, +v_20034335} = infer_adt_args_view(v_20034332, v_1, v_2, v_20034333, v_5, v_6, v_7, v_8)
  {ArenaResult{v_20034334, v_20034335} : ArenaResult<Inference>}

def validate_terms_result(v_20034336: ArenaStore, v_1: Inference, v_3: IR.Words, v_6: List<&2, Binding>, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Diagnostic>>:
  match v_1:
    case Inferred{+v_20034337, +v_20034338}:
      ArenaResult{v_20034339, +v_20034340} = validate_terms(v_20034336, v_3, v_6, v_7)
      {ArenaResult{v_20034339, v_20034340} : ArenaResult<Maybe<&2, Diagnostic>>}
    case InferenceFailure{+v_20034341}:
      v_16 = v_20034341
      {ArenaResult{v_20034336, Some{v_16}} : ArenaResult<Maybe<&2, Diagnostic>>}

def validate_terms(v_20034342: ArenaStore, v_1: IR.Words, v_4: List<&2, Binding>, v_5: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Diagnostic>>:
  ArenaResult{v_20034343, +v_20034344} = arena_words_view(v_20034342, v_1)
  match v_20034344:
    case IR.WordNil{}:
      {ArenaResult{v_20034343, None{}} : ArenaResult<Maybe<&2, Diagnostic>>}
    case IR.WordCons{+v_20034345, +v_20034346}:
      +v_10 = v_20034345
      v_11 = v_20034346
      ArenaResult{v_20034347, +v_20034348} = infer(v_20034343, v_10, v_4, v_5)
      ArenaResult{v_20034349, +v_20034350} = validate_terms_result(v_20034347, v_20034348, v_11, v_4, v_5)
      {ArenaResult{v_20034349, v_20034350} : ArenaResult<Maybe<&2, Diagnostic>>}

def check_local_quantity_map(v_1: ArenaStore, v_2: IR.Names, v_3: IR.Quantities, v_6: List<&2, UsageEntry>, v_8: Nat, v_9: Ast.SourceSpan) -> ArenaResult<Maybe<&2, Diagnostic>>:
  ArenaResult{v_17, +v_18} = arena_names_view(v_1, v_2)
  match v_18:
    case IR.NameNil{}:
      ArenaResult{v_22, +v_23} = arena_quantities_view(v_17, v_3)
      match v_23:
        case IR.QuantityNil{}:
          {ArenaResult{v_22, None{}} : ArenaResult<Maybe<&2, Diagnostic>>}
        case _:
          v_50000022 = span_file(v_9)
          v_50000023 = Diagnostic{v_50000022, v_9, "let binding lists have different lengths", "parallel names and quantities", "inconsistent let binders"}
          v_50000024 = Some{v_50000023}
          {ArenaResult{v_22, v_50000024} : ArenaResult<Maybe<&2, Diagnostic>>}
    case IR.NameCons{+v_29, +v_30}:
      ArenaResult{v_34, +v_35} = arena_quantities_view(v_17, v_3)
      match v_35:
        case IR.QuantityCons{+v_38, +v_39}:
          +v_41 = v_38
          v_43 = v_39
          +v_45 = v_29
          v_47 = v_30
          v_49 = Nat.sub(v_8, 1n)
          +v_53 = quantity_fits(usage_get(v_49, v_6), v_41)
          match v_53:
            case False{}:
              v_50000025 = span_file(v_9)
              v_50000026 = Diagnostic{v_50000025, v_9, String.append("invalid local binding use quantity for ", v_45), "within the declared quantity", "too many uses"}
              +v_56 = Some{v_50000026}
              v_58 = v_34
              {ArenaResult{v_58, v_56} : ArenaResult<Maybe<&2, Diagnostic>>}
            case True{}:
              ArenaResult{v_63, +v_64} = check_local_quantity_map(v_34, v_47, v_43, v_6, v_49, v_9)
              +v_66 = v_64
              v_68 = v_63
              {ArenaResult{v_68, v_66} : ArenaResult<Maybe<&2, Diagnostic>>}
        case _:
          v_50000027 = span_file(v_9)
          v_50000028 = Diagnostic{v_50000027, v_9, "let binding lists have different lengths", "parallel names and quantities", "inconsistent let binders"}
          v_50000029 = Some{v_50000028}
          {ArenaResult{v_34, v_50000029} : ArenaResult<Maybe<&2, Diagnostic>>}
    case _:
      v_50000030 = span_file(v_9)
      v_50000031 = Diagnostic{v_50000030, v_9, "let binding lists have different lengths", "parallel names and quantities", "inconsistent let binders"}
      v_50000032 = Some{v_50000031}
      {ArenaResult{v_17, v_50000032} : ArenaResult<Maybe<&2, Diagnostic>>}

def check_local_pattern_usage_map(v_1: ArenaStore, v_2: IR.Words, v_5: List<&2, UsageEntry>, v_7: Nat) -> ArenaResult<Maybe<&2, Diagnostic>>:
  ArenaResult{v_15, +v_16} = arena_words_view(v_1, v_2)
  match v_16:
    case IR.WordNil{}:
      {ArenaResult{v_15, None{}} : ArenaResult<Maybe<&2, Diagnostic>>}
    case IR.WordCons{+v_19, +v_20}:
      +v_22 = v_19
      v_24 = v_20
      ArenaResult{v_28, +v_29} = arena_get_pattern(v_15, v_22)
      match v_29:
        case Arena.PatternVar{+v_34, +v_35, +v_36, +v_37}:
          ArenaResult{v_41, +v_42} = arena_name_text(v_28, v_34)
          +v_44 = v_42
          v_46 = v_44
          v_48 = v_36
          v_50 = v_37
          v_52 = Nat.sub(v_7, 1n)
          +v_56 = quantity_fits(usage_get(v_52, v_5), v_48)
          match v_56:
            case False{}:
              v_50000033 = span_file(v_50)
              v_50000034 = Diagnostic{v_50000033, v_50, String.append("invalid local binding use quantity for ", v_46), "within the declared quantity", "too many uses"}
              +v_59 = Some{v_50000034}
              v_61 = v_41
              {ArenaResult{v_61, v_59} : ArenaResult<Maybe<&2, Diagnostic>>}
            case True{}:
              ArenaResult{v_66, +v_67} = check_local_pattern_usage_map(v_41, v_24, v_5, v_52)
              +v_69 = v_67
              v_71 = v_66
              {ArenaResult{v_71, v_69} : ArenaResult<Maybe<&2, Diagnostic>>}
        case Arena.PatternCtr{+v_77, +v_78, +v_79, +v_80}:
          v_82 = v_80
          v_50000035 = span_file(v_82)
          v_50000036 = Diagnostic{v_50000035, v_82, "local bindings require identifier patterns", "one identifier per local value", "a constructor pattern"}
          v_50000037 = Some{v_50000036}
          {ArenaResult{v_28, v_50000037} : ArenaResult<Maybe<&2, Diagnostic>>}

def local_pattern_quantities_match(v_1: ArenaStore, v_2: IR.Words, v_3: Ast.Quantity) -> ArenaResult<Bool>:
  ArenaResult{v_10, +v_11} = arena_words_view(v_1, v_2)
  match v_11:
    case IR.WordNil{}:
      {ArenaResult{v_10, True{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_14, +v_15}:
      +v_17 = v_14
      v_19 = v_15
      ArenaResult{v_23, +v_24} = arena_get_pattern(v_10, v_17)
      match v_24:
        case Arena.PatternVar{+v_29, +v_30, +v_31, +v_32}:
          v_34 = v_31
          ArenaResult{v_38, +v_39} = local_pattern_quantities_match(v_23, v_19, v_3)
          v_50000038 = Bool.and(same_quantity(v_34, v_3), v_39)
          {ArenaResult{v_38, v_50000038} : ArenaResult<Bool>}
        case Arena.PatternCtr{+v_45, +v_46, +v_47, +v_48}:
          {ArenaResult{v_23, False{}} : ArenaResult<Bool>}

def check_body_local_uses_result(v_20034419: ArenaStore, v_2: Maybe<&2, Diagnostic>, v_4: IR.Words, v_6: IR.Words, v_7: U32, v_8: Ast.SourceSpan, v_11: List<&2, Binding>, v_12: Scope.ArenaGlobalScope, v_15: List<&2, Binding>) -> ArenaResult<Inference>:
  match v_2:
    case Some{+v_20034420}:
      v_18 = v_20034420
      {ArenaResult{v_20034419, InferenceFailure{v_18}} : ArenaResult<Inference>}
    case None{}:
      ArenaResult{v_20034421, +v_20034422} = arena_words_reverse(v_20034419, v_6)
      ArenaResult{v_20034423, +v_20034424} = substitute_many(v_20034421, v_20034422, v_7)
      ArenaResult{v_20034425, +v_20034426} = infer(v_20034423, v_20034424, v_11, v_12)
      {ArenaResult{v_20034425, v_20034426} : ArenaResult<Inference>}

def checked_local_env_inference(v_20034427: ArenaStore, v_1: Inference, v_3: String, v_4: Ast.Quantity, v_6: IR.Words, v_8: IR.Words, v_11: List<&2, Binding>, v_14: List<&2, Binding>, v_15: Scope.ArenaGlobalScope, v_16: Ast.SourceSpan) -> ArenaResult<CheckedLocalEnv>:
  match v_1:
    case Inferred{+v_20034428, +v_20034429}:
      v_21 = v_20034429
      ArenaResult{v_20034430, +v_20034431} = checked_local_env(v_20034427, v_6, v_8, v_11, Binding{v_3, v_4, v_21, List.length(&2, Binding, v_11)} <> v_14, v_15, v_16)
      {ArenaResult{v_20034430, v_20034431} : ArenaResult<CheckedLocalEnv>}
    case InferenceFailure{+v_20034432}:
      v_25 = v_20034432
      {ArenaResult{v_20034427, CheckedLocalEnvFailure{v_25}} : ArenaResult<CheckedLocalEnv>}

def checked_local_env(v_1: ArenaStore, v_2: IR.Words, v_3: IR.Words, v_6: List<&2, Binding>, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope, v_11: Ast.SourceSpan) -> ArenaResult<CheckedLocalEnv>:
  ArenaResult{v_18, +v_19} = arena_words_view(v_1, v_2)
  match v_19:
    case IR.WordNil{}:
      ArenaResult{v_23, +v_24} = arena_words_view(v_18, v_3)
      match v_24:
        case IR.WordNil{}:
          {ArenaResult{v_23, CheckedLocalEnv{v_9}} : ArenaResult<CheckedLocalEnv>}
        case _:
          v_50000039 = span_file(v_11)
          v_50000040 = Diagnostic{v_50000039, v_11, "local binding names and values have different lengths", "one value per identifier", "inconsistent local bindings"}
          v_50000041 = CheckedLocalEnvFailure{v_50000040}
          {ArenaResult{v_23, v_50000041} : ArenaResult<CheckedLocalEnv>}
    case IR.WordCons{+v_30, +v_31}:
      ArenaResult{v_35, +v_36} = arena_get_pattern(v_18, v_30)
      match v_36:
        case Arena.PatternVar{+v_41, +v_42, +v_43, +v_44}:
          ArenaResult{v_48, +v_49} = arena_name_text(v_35, v_41)
          +v_51 = v_49
          ArenaResult{v_55, +v_56} = arena_words_view(v_48, v_3)
          match v_56:
            case IR.WordCons{+v_59, +v_60}:
              v_62 = v_59
              v_64 = v_60
              v_66 = v_51
              v_68 = v_43
              v_70 = v_31
              ArenaResult{v_74, +v_75} = infer(v_55, v_62, v_6, v_10)
              ArenaResult{v_79, +v_80} = checked_local_env_inference(v_74, v_75, v_66, v_68, v_70, v_64, v_6, v_9, v_10, v_11)
              {ArenaResult{v_79, v_80} : ArenaResult<CheckedLocalEnv>}
            case _:
              v_50000042 = span_file(v_11)
              v_50000043 = Diagnostic{v_50000042, v_11, "local binding names and values have different lengths", "one value per identifier", "inconsistent local bindings"}
              v_50000044 = CheckedLocalEnvFailure{v_50000043}
              {ArenaResult{v_55, v_50000044} : ArenaResult<CheckedLocalEnv>}
        case _:
          v_50000045 = span_file(v_11)
          v_50000046 = Diagnostic{v_50000045, v_11, "local binding names and values have different lengths", "one value per identifier", "inconsistent local bindings"}
          v_50000047 = CheckedLocalEnvFailure{v_50000046}
          {ArenaResult{v_35, v_50000047} : ArenaResult<CheckedLocalEnv>}
    case _:
      v_50000048 = span_file(v_11)
      v_50000049 = Diagnostic{v_50000048, v_11, "local binding names and values have different lengths", "one value per identifier", "inconsistent local bindings"}
      v_50000050 = CheckedLocalEnvFailure{v_50000049}
      {ArenaResult{v_18, v_50000050} : ArenaResult<CheckedLocalEnv>}

def check_body_local_env_result(v_20034469: ArenaStore, v_1: CheckedLocalEnv, v_3: IR.Words, v_5: IR.Words, v_6: U32, v_7: Ast.SourceSpan, v_10: List<&2, Binding>, v_11: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_1:
    case CheckedLocalEnvFailure{+v_20034470}:
      v_14 = v_20034470
      {ArenaResult{v_20034469, InferenceFailure{v_14}} : ArenaResult<Inference>}
    case CheckedLocalEnv{+v_20034471}:
      v_16 = v_20034471
      v_18 = arena_words_length(v_3)
      ArenaResult{v_20034472, +v_20034473} = binder_usage_map(v_20034469, v_18, v_6, v_16, v_11, None{}, False{})
      ArenaResult{v_20034474, +v_20034475} = check_local_pattern_usage_map(v_20034472, v_3, v_20034473, v_18)
      ArenaResult{v_20034476, +v_20034477} = check_body_local_uses_result(v_20034474, v_20034475, v_3, v_5, v_6, v_7, v_10, v_11, v_16)
      {ArenaResult{v_20034476, v_20034477} : ArenaResult<Inference>}

def check_body_local_quantity_result(v_1: ArenaStore, v_3: Bool, v_4: IR.Words, v_5: Ast.Quantity, v_6: IR.Words, v_8: U32, v_9: Ast.SourceSpan, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_3:
    case True{}:
      ArenaResult{v_20, +v_21} = checked_local_env(v_1, v_4, v_6, v_12, v_12, v_13, v_9)
      ArenaResult{v_25, +v_26} = check_body_local_env_result(v_20, v_21, v_4, v_6, v_8, v_9, v_12, v_13)
      {ArenaResult{v_25, v_26} : ArenaResult<Inference>}
    case False{}:
      v_50000051 = fail(v_9, "local binder quantity differs from its pattern quantity", "the declared local quantity", "an inconsistent pattern quantity")
      {ArenaResult{v_1, v_50000051} : ArenaResult<Inference>}

def check_body_local_length_result(v_1: ArenaStore, v_3: Bool, v_4: IR.Words, v_5: Ast.Quantity, v_6: IR.Words, v_8: U32, v_9: Ast.SourceSpan, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_3:
    case True{}:
      ArenaResult{v_20, +v_21} = local_pattern_quantities_match(v_1, v_4, v_5)
      ArenaResult{v_25, +v_26} = check_body_local_quantity_result(v_20, v_21, v_4, v_5, v_6, v_8, v_9, v_12, v_13)
      {ArenaResult{v_25, v_26} : ArenaResult<Inference>}
    case False{}:
      v_50000052 = fail(v_9, "local binding names and values have different lengths", "one value per name", "mismatched local bindings")
      {ArenaResult{v_1, v_50000052} : ArenaResult<Inference>}

def check_body_local(v_20034488: ArenaStore, v_1: IR.Words, v_2: Ast.Quantity, v_4: IR.Words, v_5: U32, v_6: Ast.SourceSpan, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  ArenaResult{v_20034489, +v_20034490} = check_body_local_length_result(v_20034488, Nat.is_eq(arena_words_length(v_1), arena_words_length(v_4)), v_1, v_2, v_4, v_5, v_6, v_9, v_10)
  {ArenaResult{v_20034489, v_20034490} : ArenaResult<Inference>}

def family_head_key(v_20034491: ArenaStore, v_0: U32) -> ArenaResult<Maybe<&2, String>>:
  ArenaResult{v_20034492, +v_20034493} = arena_get_node(v_20034491, v_0)
  match v_20034493:
    case Arena.TermRef{+v_20034496, +v_20034498}:
      ArenaResult{v_20034499, +v_20034500} = arena_name_text(v_20034492, v_20034496)
      +v_20034497 = v_20034500
      v_5 = v_20034497
      {ArenaResult{v_20034499, Some{v_5}} : ArenaResult<Maybe<&2, String>>}
    case Arena.TermAdt{+v_20034505, +v_20034507, +v_20034508, +v_20034510, +v_20034511, +v_20034513}:
      ArenaResult{v_20034514, +v_20034515} = arena_name_text(v_20034492, v_20034505)
      +v_20034506 = v_20034515
      v_12 = v_20034506
      {ArenaResult{v_20034514, Some{v_12}} : ArenaResult<Maybe<&2, String>>}
    case Arena.TermAnn{+v_20034519, +v_20034520, +v_20034521}:
      v_20 = v_20034519
      ArenaResult{v_20034522, +v_20034523} = family_head_key(v_20034492, v_20)
      {ArenaResult{v_20034522, v_20034523} : ArenaResult<Maybe<&2, String>>}
    case _:
      {ArenaResult{v_20034492, None{}} : ArenaResult<Maybe<&2, String>>}

def family_head_args(v_20034525: ArenaStore, v_0: U32) -> ArenaResult<IR.Words>:
  ArenaResult{v_20034526, +v_20034527} = arena_get_node(v_20034525, v_0)
  match v_20034527:
    case Arena.TermAdt{+v_20034532, +v_20034534, +v_20034535, +v_20034537, +v_20034538, +v_20034540}:
      +v_20034536 = IR.Words{v_20034534, v_20034535}
      v_7 = v_20034536
      {ArenaResult{v_20034526, v_7} : ArenaResult<IR.Words>}
    case Arena.TermAnn{+v_20034544, +v_20034545, +v_20034546}:
      v_13 = v_20034544
      ArenaResult{v_20034547, +v_20034548} = family_head_args(v_20034526, v_13)
      {ArenaResult{v_20034547, v_20034548} : ArenaResult<IR.Words>}
    case _:
      {ArenaResult{v_20034526, IR.Words{0, 0}} : ArenaResult<IR.Words>}

def family_head_refs(v_20034550: ArenaStore, v_0: U32) -> ArenaResult<IR.Names>:
  ArenaResult{v_20034551, +v_20034552} = arena_get_node(v_20034550, v_0)
  match v_20034552:
    case Arena.TermAdt{+v_20034557, +v_20034559, +v_20034560, +v_20034562, +v_20034563, +v_20034565}:
      +v_20034564 = IR.Names{v_20034562, v_20034563}
      v_9 = v_20034564
      {ArenaResult{v_20034551, v_9} : ArenaResult<IR.Names>}
    case Arena.TermAnn{+v_20034569, +v_20034570, +v_20034571}:
      v_14 = v_20034569
      ArenaResult{v_20034572, +v_20034573} = family_head_refs(v_20034551, v_14)
      {ArenaResult{v_20034572, v_20034573} : ArenaResult<IR.Names>}
    case _:
      {ArenaResult{v_20034551, IR.Names{0, 0}} : ArenaResult<IR.Names>}

def family_arity_view(v_20034575: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Nat>:
  ArenaResult{v_20034576, +v_20034577} = arena_get_node(v_20034575, v_0)
  match v_20034577:
    case Arena.TermAll{+v_20034584, +v_20034585, +v_20034587, +v_20034588, +v_20034589, +v_20034590}:
      v_13 = v_20034589
      ArenaResult{v_20034591, +v_20034592} = family_arity(v_20034576, v_13, v_1)
      {ArenaResult{v_20034591, Nat.add(1n, v_20034592)} : ArenaResult<Nat>}
    case _:
      {ArenaResult{v_20034576, 0n} : ArenaResult<Nat>}

def family_arity(v_20034594: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Nat>:
  ArenaResult{v_20034595, +v_20034596} = whnf(v_20034594, 64n, v_0, v_1)
  ArenaResult{v_20034597, +v_20034598} = family_arity_view(v_20034595, v_20034596, v_1)
  {ArenaResult{v_20034597, v_20034598} : ArenaResult<Nat>}

def family_quant_prefix_domain(v_20034599: ArenaStore, v_0: U32, v_1: U32, v_2: Scope.ArenaGlobalScope) -> ArenaResult<Nat>:
  ArenaResult{v_20034600, +v_20034601} = arena_get_node(v_20034599, v_0)
  match v_20034601:
    case Arena.TermQuant{}:
      ArenaResult{v_20034602, +v_20034603} = family_quant_prefix(v_20034600, v_1, v_2)
      {ArenaResult{v_20034602, Nat.add(1n, v_20034603)} : ArenaResult<Nat>}
    case _:
      {ArenaResult{v_20034600, 0n} : ArenaResult<Nat>}

def family_quant_prefix_view(v_20034605: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Nat>:
  ArenaResult{v_20034606, +v_20034607} = arena_get_node(v_20034605, v_0)
  match v_20034607:
    case Arena.TermAll{+v_20034614, +v_20034615, +v_20034617, +v_20034618, +v_20034619, +v_20034620}:
      v_12 = v_20034618
      v_13 = v_20034619
      ArenaResult{v_20034621, +v_20034622} = whnf(v_20034606, 64n, v_12, v_1)
      ArenaResult{v_20034623, +v_20034624} = family_quant_prefix_domain(v_20034621, v_20034622, v_13, v_1)
      {ArenaResult{v_20034623, v_20034624} : ArenaResult<Nat>}
    case _:
      {ArenaResult{v_20034606, 0n} : ArenaResult<Nat>}

def family_quant_prefix(v_20034626: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Nat>:
  ArenaResult{v_20034627, +v_20034628} = whnf(v_20034626, 64n, v_0, v_1)
  ArenaResult{v_20034629, +v_20034630} = family_quant_prefix_view(v_20034627, v_20034628, v_1)
  {ArenaResult{v_20034629, v_20034630} : ArenaResult<Nat>}

def quantity_arguments(v_20034631: ArenaStore, v_1: Nat, +v_2: Ast.Quantity, +v_3: Ast.SourceSpan) -> ArenaResult<IR.Words>:
  match v_1:
    case 0n:
      {ArenaResult{v_20034631, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case 1n++v_20034632:
      v_6 = v_20034632
      ArenaResult{v_20034633, +v_20034634} = arena_put_node(v_20034631, Arena.TermQuantity{v_2, v_3})
      ArenaResult{v_20034635, +v_20034636} = quantity_arguments(v_20034633, v_6, v_2, v_3)
      ArenaResult{v_20034637, +v_20034638} = arena_words_cons(v_20034635, v_20034634, v_20034636)
      {ArenaResult{v_20034637, v_20034638} : ArenaResult<IR.Words>}

def set_quantity_prefix(v_20034639: ArenaStore, v_1: IR.Words, v_3: Nat, +v_4: Ast.Quantity, +v_5: Ast.SourceSpan) -> ArenaResult<IR.Words>:
  match v_3:
    case 0n:
      {ArenaResult{v_20034639, v_1} : ArenaResult<IR.Words>}
    case 1n++v_20034641:
      ArenaResult{v_20034642, +v_20034643} = arena_words_view(v_20034639, v_1)
      match v_20034643:
        case IR.WordCons{+v_20034644, +v_20034645}:
          v_13 = v_20034645
          v_14 = v_20034641
          ArenaResult{v_20034646, +v_20034647} = arena_put_node(v_20034642, Arena.TermQuantity{v_4, v_5})
          ArenaResult{v_20034648, +v_20034649} = set_quantity_prefix(v_20034646, v_13, v_14, v_4, v_5)
          ArenaResult{v_20034650, +v_20034651} = arena_words_cons(v_20034648, v_20034647, v_20034649)
          {ArenaResult{v_20034650, v_20034651} : ArenaResult<IR.Words>}
        case IR.WordNil{}:
          {ArenaResult{v_20034642, IR.Words{0, 0}} : ArenaResult<IR.Words>}

def family_failure(+v_0: Ast.SourceSpan, v_2: String, v_4: String, v_6: String) -> FamilyLowering:
  v_50000053 = span_file(v_0)
  v_50000054 = Diagnostic{v_50000053, v_0, v_2, v_4, v_6}
  FamilyFailure{v_50000054}

def lower_family_sugar_filled(v_20034655: ArenaStore, v_1: Bool, +v_3: IR.Words, v_5: Nat, v_6: Ast.SourceSpan) -> ArenaResult<IR.Words>:
  +v_20034658 = v_1
  match v_20034658:
    case False{}:
      +v_20034656 = v_3
      v_20034657 = v_20034655
      {ArenaResult{v_20034657, v_20034656} : ArenaResult<IR.Words>}
    case True{}:
      ArenaResult{v_20034659, +v_20034660} = quantity_arguments(v_20034655, v_5, Ast.QOne{}, v_6)
      ArenaResult{v_20034661, +v_20034662} = arena_words_append(v_20034659, v_20034660, v_3)
      +v_20034656 = v_20034662
      v_20034657 = v_20034661
      {ArenaResult{v_20034657, v_20034656} : ArenaResult<IR.Words>}

def lower_family_sugar_complete(v_1: ArenaStore, v_3: Bool, v_5: String, v_7: U32, v_8: IR.Words, v_10: Nat, +v_11: Ast.SourceSpan, v_12: Scope.ArenaGlobalScope) -> ArenaResult<FamilyLowering>:
  +v_17 = v_3
  match v_17:
    case False{}:
      +v_20 = family_failure(v_11, "plus datatype application is missing parameters", "a complete family instance", "an incomplete family application")
      v_22 = v_1
      {ArenaResult{v_22, v_20} : ArenaResult<FamilyLowering>}
    case True{}:
      ArenaResult{v_27, +v_28} = set_quantity_prefix(v_1, v_8, v_10, Ast.QMany{}, v_11)
      ArenaResult{v_32, +v_33} = family_head_refs(v_27, v_7)
      ArenaResult{v_38, +v_39} = arena_name(v_32, Scope.canonical_name(v_5, v_12))
      v_50000055 = arena_words_start(v_28)
      v_50000056 = arena_words_count(v_28)
      v_50000057 = arena_names_start(v_33)
      v_50000058 = arena_names_count(v_33)
      ArenaResult{v_47, +v_48} = arena_put_node(v_38, Arena.TermAdt{v_39, v_50000055, v_50000056, v_50000057, v_50000058, v_11})
      +v_50 = FamilyTerm{v_48}
      v_52 = v_47
      {ArenaResult{v_52, v_50} : ArenaResult<FamilyLowering>}

def lower_family_sugar_plus_quantity(v_1: ArenaStore, +v_3: Nat, v_5: Bool, v_7: String, v_9: U32, v_10: IR.Words, v_11: Ast.SourceSpan, v_12: Scope.ArenaGlobalScope) -> ArenaResult<FamilyLowering>:
  match v_3:
    case 0n:
      v_50000059 = family_failure(v_11, "plus requires a datatype with quantity parameters", "a family with quantified parameters", "a family without quantity parameters")
      {ArenaResult{v_1, v_50000059} : ArenaResult<FamilyLowering>}
    case _:
      ArenaResult{v_22, +v_23} = lower_family_sugar_complete(v_1, v_5, v_7, v_9, v_10, v_3, v_11, v_12)
      {ArenaResult{v_22, v_23} : ArenaResult<FamilyLowering>}

def lower_family_sugar_promote(v_1: ArenaStore, v_3: Bool, v_5: Bool, v_7: String, v_9: U32, v_10: IR.Words, v_12: Nat, v_13: Ast.SourceSpan, v_14: Scope.ArenaGlobalScope) -> ArenaResult<FamilyLowering>:
  match v_3:
    case True{}:
      ArenaResult{v_21, +v_22} = lower_family_sugar_plus_quantity(v_1, v_12, v_5, v_7, v_9, v_10, v_13, v_14)
      {ArenaResult{v_21, v_22} : ArenaResult<FamilyLowering>}
    case False{}:
      ArenaResult{v_26, +v_27} = family_head_refs(v_1, v_9)
      ArenaResult{v_32, +v_33} = arena_name(v_26, Scope.canonical_name(v_7, v_14))
      v_50000060 = arena_words_start(v_10)
      v_50000061 = arena_words_count(v_10)
      v_50000062 = arena_names_start(v_27)
      v_50000063 = arena_names_count(v_27)
      ArenaResult{v_41, +v_42} = arena_put_node(v_32, Arena.TermAdt{v_33, v_50000060, v_50000061, v_50000062, v_50000063, v_13})
      {ArenaResult{v_41, FamilyTerm{v_42}} : ArenaResult<FamilyLowering>}

def lower_family_sugar_family(v_20034688: ArenaStore, +v_0: U32, v_2: String, +v_3: U32, v_5: IR.Words, v_7: Bool, +v_8: Ast.SourceSpan, +v_9: Scope.ArenaGlobalScope) -> ArenaResult<FamilyLowering>:
  ArenaResult{v_20034689, +v_20034690} = family_arity(v_20034688, v_0, v_9)
  +v_13 = v_20034690
  ArenaResult{v_20034691, +v_20034692} = family_quant_prefix(v_20034689, v_0, v_9)
  +v_16 = v_20034692
  ArenaResult{v_20034693, +v_20034694} = family_head_args(v_20034691, v_3)
  ArenaResult{v_20034695, +v_20034696} = arena_words_append(v_20034693, v_20034694, v_5)
  +v_19 = v_20034696
  ArenaResult{v_20034697, +v_20034698} = lower_family_sugar_filled(v_20034695, Nat.is_eq(Nat.add(arena_words_length(v_19), v_16), v_13), v_19, v_16, v_8)
  +v_22 = v_20034698
  ArenaResult{v_20034699, +v_20034700} = lower_family_sugar_promote(v_20034697, v_7, Nat.is_eq(arena_words_length(v_22), v_13), v_2, v_3, v_22, v_16, v_8, v_9)
  {ArenaResult{v_20034699, v_20034700} : ArenaResult<FamilyLowering>}

def lower_family_sugar_global(v_1: ArenaStore, v_2: Scope.ArenaGlobal, +v_4: String, v_6: U32, v_7: IR.Words, v_9: Bool, v_10: Ast.SourceSpan, v_11: Scope.ArenaGlobalScope) -> ArenaResult<FamilyLowering>:
  match v_2:
    case Scope.ArenaGlobal{+v_21, +v_22, +v_23, +v_24, +v_25, +v_26}:
      match v_26:
        case Scope.GlobalFamily{}:
          v_28 = v_24
          ArenaResult{v_32, +v_33} = lower_family_sugar_family(v_1, v_28, v_4, v_6, v_7, v_9, v_10, v_11)
          {ArenaResult{v_32, v_33} : ArenaResult<FamilyLowering>}
        case _:
          v_50000064 = family_failure(v_10, String.append("name is not a datatype: ", v_4), "a declared datatype", v_4)
          {ArenaResult{v_1, v_50000064} : ArenaResult<FamilyLowering>}

def lower_family_sugar_global_result(v_1: ArenaStore, v_3: Maybe<&2, Scope.ArenaGlobal>, +v_5: String, v_7: U32, v_8: IR.Words, v_10: Bool, v_11: Ast.SourceSpan, v_12: Scope.ArenaGlobalScope) -> ArenaResult<FamilyLowering>:
  match v_3:
    case None{}:
      v_50000065 = family_failure(v_11, String.append("unknown datatype ", v_5), "a declared datatype", v_5)
      {ArenaResult{v_1, v_50000065} : ArenaResult<FamilyLowering>}
    case Some{+v_18}:
      v_20 = v_18
      ArenaResult{v_24, +v_25} = lower_family_sugar_global(v_1, v_20, v_5, v_7, v_8, v_10, v_11, v_12)
      {ArenaResult{v_24, v_25} : ArenaResult<FamilyLowering>}

def lower_family_sugar_key_result(v_1: ArenaStore, v_4: Maybe<&2, String>, v_6: U32, v_7: IR.Words, v_9: Bool, v_10: Ast.SourceSpan, +v_11: Scope.ArenaGlobalScope) -> ArenaResult<FamilyLowering>:
  match v_4:
    case None{}:
      v_50000066 = family_failure(v_10, "datatype sugar requires a family name", "a declared datatype", "a non-family expression")
      {ArenaResult{v_1, v_50000066} : ArenaResult<FamilyLowering>}
    case Some{+v_17}:
      +v_19 = v_17
      ArenaResult{v_24, +v_25} = lower_family_sugar_global_result(v_1, Scope.lookup(v_19, v_11), v_19, v_6, v_7, v_9, v_10, v_11)
      {ArenaResult{v_24, v_25} : ArenaResult<FamilyLowering>}

def lower_family_sugar_variable(v_1: Bool, v_2: U32, v_3: Ast.SourceSpan) -> FamilyLowering:
  +v_20034720 = v_1
  match v_20034720:
    case False{}:
      +v_20034719 = family_failure(v_3, "datatype sugar requires a declared datatype", "a datatype family head", "a variable or invalid head")
      v_20034719
    case True{}:
      +v_20034719 = FamilyTerm{v_2}
      v_20034719

def lower_family_sugar(v_1: ArenaStore, v_3: U32, v_4: IR.Words, v_6: Bool, v_7: Ast.SourceSpan, v_8: Scope.ArenaGlobalScope) -> ArenaResult<FamilyLowering>:
  ArenaResult{v_15, +v_16} = arena_get_node(v_1, v_3)
  match v_16:
    case Arena.TermVar{+v_20, +v_21, +v_22}:
      v_50000067 = lower_family_sugar_variable(Bool.and(v_6, arena_words_is_empty(v_4)), v_3, v_7)
      {ArenaResult{v_15, v_50000067} : ArenaResult<FamilyLowering>}
    case _:
      ArenaResult{v_30, +v_31} = family_head_key(v_15, v_3)
      ArenaResult{v_35, +v_36} = lower_family_sugar_key_result(v_30, v_31, v_3, v_4, v_6, v_7, v_8)
      {ArenaResult{v_35, v_36} : ArenaResult<FamilyLowering>}

def infer_family_sugar_result(v_20034736: ArenaStore, v_1: FamilyLowering, v_4: List<&2, Binding>, v_5: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_1:
    case FamilyTerm{+v_20034737}:
      v_8 = v_20034737
      ArenaResult{v_20034738, +v_20034739} = infer(v_20034736, v_8, v_4, v_5)
      {ArenaResult{v_20034738, v_20034739} : ArenaResult<Inference>}
    case FamilyFailure{+v_20034740}:
      v_11 = v_20034740
      {ArenaResult{v_20034736, InferenceFailure{v_11}} : ArenaResult<Inference>}

def infer_family_sugar(v_20034741: ArenaStore, v_0: U32, v_2: IR.Words, v_4: Bool, v_5: Ast.SourceSpan, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  ArenaResult{v_20034742, +v_20034743} = lower_family_sugar(v_20034741, v_0, v_2, v_4, v_5, v_9)
  ArenaResult{v_20034744, +v_20034745} = infer_family_sugar_result(v_20034742, v_20034743, v_8, v_9)
  {ArenaResult{v_20034744, v_20034745} : ArenaResult<Inference>}

def infer_application_check(v_20034746: ArenaStore, v_1: Inference, v_2: U32, v_3: U32) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20034747, +v_20034748}:
      v_7 = v_20034747
      ArenaResult{v_20034749, +v_20034750} = core_subst(v_20034746, 0n, v_7, v_3)
      {ArenaResult{v_20034749, Inferred{v_2, v_20034750}} : ArenaResult<Inference>}
    case InferenceFailure{+v_20034751}:
      v_10 = v_20034751
      {ArenaResult{v_20034746, InferenceFailure{v_10}} : ArenaResult<Inference>}

def infer_application_result_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_7: U32, v_8: Ast.SourceSpan, v_11: List<&2, Binding>, v_12: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  ArenaResult{v_19, +v_20} = arena_get_node(v_1, v_3)
  match v_20:
    case Arena.TermAll{+v_27, +v_28, +v_29, +v_30, +v_31, +v_32}:
      v_34 = v_30
      v_36 = v_31
      ArenaResult{v_40, +v_41} = check_term(v_19, v_7, v_11, v_12, v_34)
      ArenaResult{v_45, +v_46} = infer_application_check(v_40, v_41, v_5, v_36)
      {ArenaResult{v_45, v_46} : ArenaResult<Inference>}
    case _:
      v_50000068 = fail(v_8, "application target is not a function", "a function type", "a non-function type")
      {ArenaResult{v_19, v_50000068} : ArenaResult<Inference>}

def infer_application_result(v_20034773: ArenaStore, v_0: U32, v_1: U32, v_2: U32, v_3: Ast.SourceSpan, v_6: List<&2, Binding>, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  ArenaResult{v_20034774, +v_20034775} = whnf(v_20034773, 64n, v_2, v_7)
  ArenaResult{v_20034776, +v_20034777} = infer_application_result_view(v_20034774, v_20034775, v_0, v_1, v_3, v_6, v_7)
  {ArenaResult{v_20034776, v_20034777} : ArenaResult<Inference>}

def check_infer_term_sort(v_1: ArenaStore, v_3: Inference, v_5: U32, v_6: Ast.SourceSpan) -> ArenaResult<Inference>:
  match v_3:
    case Inferred{+v_12, +v_13}:
      ArenaResult{v_17, +v_18} = arena_get_node(v_1, v_13)
      match v_18:
        case Arena.TermType{+v_21, +v_22}:
          ArenaResult{v_26, +v_27} = arena_put_node(v_17, Arena.TermQuantity{Ast.QOne{}, v_6})
          ArenaResult{v_31, +v_32} = arena_put_node(v_26, Arena.TermType{v_27, v_6})
          {ArenaResult{v_31, Inferred{v_5, v_32}} : ArenaResult<Inference>}
        case _:
          v_50000069 = fail(v_6, "function codomain is not a type", "a type", "a term")
          {ArenaResult{v_17, v_50000069} : ArenaResult<Inference>}
    case InferenceFailure{+v_37}:
      v_39 = v_37
      {ArenaResult{v_1, InferenceFailure{v_39}} : ArenaResult<Inference>}

def infer_global_reference(v_1: Maybe<&2, Scope.ArenaGlobal>, v_3: String, v_4: U32, v_5: Ast.SourceSpan) -> Inference:
  match v_1:
    case Some{+v_20034793}:
      v_8 = v_20034793
      match v_8:
        case Scope.ArenaGlobal{+v_20034794, +v_20034795, +v_20034796, +v_20034797, +v_20034798, +v_20034799}:
          v_18 = v_20034797
          Inferred{v_4, v_18}
    case None{}:
      fail(v_5, String.append("unknown name ", v_3), "a declared name", v_3)

def infer_global_adt(v_1: ArenaStore, v_3: Maybe<&2, Scope.ArenaGlobal>, v_5: String, v_6: IR.Words, v_8: U32, v_9: Ast.SourceSpan, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_3:
    case Some{+v_18}:
      v_20 = v_18
      match v_20:
        case Scope.ArenaGlobal{+v_27, +v_28, +v_29, +v_30, +v_31, +v_32}:
          v_34 = v_30
          ArenaResult{v_38, +v_39} = infer_adt_args(v_1, v_6, v_34, v_12, v_13, v_8, v_9)
          {ArenaResult{v_38, v_39} : ArenaResult<Inference>}
    case None{}:
      v_50000070 = fail(v_9, String.append("unknown datatype ", v_5), "a declared datatype", v_5)
      {ArenaResult{v_1, v_50000070} : ArenaResult<Inference>}

def binding_type_at(v_20034810: ArenaStore, v_1: Binding, v_3: Nat) -> ArenaResult<U32>:
  match v_1:
    case Binding{+v_20034811, +v_20034812, +v_20034813, +v_20034814}:
      v_10 = v_20034813
      v_11 = v_20034814
      v_13 = Nat.sub(v_3, v_11)
      match v_13:
        case 0n:
          {ArenaResult{v_20034810, v_10} : ArenaResult<U32>}
        case _:
          ArenaResult{v_20034816, +v_20034817} = core_shift(v_20034810, 0n, v_13, v_10)
          {ArenaResult{v_20034816, v_20034817} : ArenaResult<U32>}

def infer_local_reference(v_1: ArenaStore, v_4: Maybe<&2, Binding>, v_6: String, v_8: Nat, v_10: U32, v_11: Ast.SourceSpan) -> ArenaResult<Inference>:
  match v_4:
    case Some{+v_16}:
      v_18 = v_16
      ArenaResult{v_22, +v_23} = binding_type_at(v_1, v_18, v_8)
      {ArenaResult{v_22, Inferred{v_10, v_23}} : ArenaResult<Inference>}
    case None{}:
      v_50000071 = fail(v_11, String.append("unbound variable ", v_6), "a bound variable", v_6)
      {ArenaResult{v_1, v_50000071} : ArenaResult<Inference>}

def infer_term_annotation_result(v_20034822: ArenaStore, v_1: Inference, v_2: U32, v_3: U32, v_4: Ast.SourceSpan, v_7: List<&2, Binding>, v_8: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20034823, +v_20034824}:
      v_12 = v_20034823
      ArenaResult{v_20034825, +v_20034826} = check_term(v_20034822, v_2, v_7, v_8, v_12)
      ArenaResult{v_20034827, +v_20034828} = infer_term_annotation_inner(v_20034825, v_20034826, v_12, v_3, v_4)
      {ArenaResult{v_20034827, v_20034828} : ArenaResult<Inference>}
    case InferenceFailure{+v_20034829}:
      v_17 = v_20034829
      {ArenaResult{v_20034822, InferenceFailure{v_17}} : ArenaResult<Inference>}

def infer_term_annotation_inner(v_20034830: ArenaStore, v_1: Inference, v_2: U32, v_3: U32, v_4: Ast.SourceSpan) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20034831, +v_20034832}:
      v_8 = v_20034831
      ArenaResult{v_20034833, +v_20034834} = arena_put_node(v_20034830, Arena.TermAnn{v_8, v_2, v_4})
      {ArenaResult{v_20034833, Inferred{v_20034834, v_2}} : ArenaResult<Inference>}
    case InferenceFailure{+v_20034835}:
      v_11 = v_20034835
      {ArenaResult{v_20034830, InferenceFailure{v_11}} : ArenaResult<Inference>}

def infer_type_annotation_result(v_1: ArenaStore, v_3: Inference, v_5: U32, v_6: Ast.SourceSpan) -> ArenaResult<Inference>:
  match v_3:
    case Inferred{+v_12, +v_13}:
      ArenaResult{v_17, +v_18} = arena_get_node(v_1, v_13)
      match v_18:
        case Arena.TermQuant{}:
          ArenaResult{v_22, +v_23} = arena_put_node(v_17, Arena.TermQuantity{Ast.QOne{}, v_6})
          ArenaResult{v_27, +v_28} = arena_put_node(v_22, Arena.TermType{v_23, v_6})
          {ArenaResult{v_27, Inferred{v_5, v_28}} : ArenaResult<Inference>}
        case _:
          v_50000072 = fail(v_6, "kind annotation is not a quantity", "Quant", "a non-quantity")
          {ArenaResult{v_17, v_50000072} : ArenaResult<Inference>}
    case InferenceFailure{+v_33}:
      v_35 = v_33
      {ArenaResult{v_1, InferenceFailure{v_35}} : ArenaResult<Inference>}

def infer_min_results(v_1: ArenaStore, v_3: Inference, v_5: Inference, v_7: U32, v_8: Ast.SourceSpan) -> ArenaResult<Inference>:
  match v_3:
    case Inferred{+v_14, +v_15}:
      ArenaResult{v_19, +v_20} = arena_get_node(v_1, v_15)
      match v_20:
        case Arena.TermQuant{}:
          match v_5:
            case Inferred{+v_23, +v_24}:
              ArenaResult{v_28, +v_29} = arena_get_node(v_19, v_24)
              match v_29:
                case Arena.TermQuant{}:
                  ArenaResult{v_33, +v_34} = arena_put_node(v_28, Arena.TermQuant{})
                  {ArenaResult{v_33, Inferred{v_7, v_34}} : ArenaResult<Inference>}
                case _:
                  v_50000073 = fail(v_8, "minimum operands must be quantities", "Quant", "a non-quantity")
                  {ArenaResult{v_28, v_50000073} : ArenaResult<Inference>}
            case InferenceFailure{+v_39}:
              v_41 = v_39
              {ArenaResult{v_19, InferenceFailure{v_41}} : ArenaResult<Inference>}
            case _:
              v_50000074 = fail(v_8, "minimum operands must be quantities", "Quant", "a non-quantity")
              {ArenaResult{v_19, v_50000074} : ArenaResult<Inference>}
        case _:
          match v_5:
            case InferenceFailure{+v_48}:
              v_50 = v_48
              {ArenaResult{v_19, InferenceFailure{v_50}} : ArenaResult<Inference>}
            case _:
              v_50000075 = fail(v_8, "minimum operands must be quantities", "Quant", "a non-quantity")
              {ArenaResult{v_19, v_50000075} : ArenaResult<Inference>}
    case InferenceFailure{+v_55}:
      v_57 = v_55
      {ArenaResult{v_1, InferenceFailure{v_57}} : ArenaResult<Inference>}
    case _:
      match v_5:
        case InferenceFailure{+v_61}:
          v_63 = v_61
          {ArenaResult{v_1, InferenceFailure{v_63}} : ArenaResult<Inference>}
        case _:
          v_50000076 = fail(v_8, "minimum operands must be quantities", "Quant", "a non-quantity")
          {ArenaResult{v_1, v_50000076} : ArenaResult<Inference>}

def infer_equal_endpoints(v_20034879: ArenaStore, v_1: Inference, v_3: Inference, v_4: U32, v_5: Ast.SourceSpan) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20034882, +v_20034883}:
      match v_3:
        case Inferred{+v_20034884, +v_20034885}:
          ArenaResult{v_20034886, +v_20034887} = arena_put_node(v_20034879, Arena.TermQuantity{Ast.QMany{}, v_5})
          ArenaResult{v_20034888, +v_20034889} = arena_put_node(v_20034886, Arena.TermType{v_20034887, v_5})
          {ArenaResult{v_20034888, Inferred{v_4, v_20034889}} : ArenaResult<Inference>}
        case InferenceFailure{+v_20034890}:
          v_22 = v_20034890
          {ArenaResult{v_20034879, InferenceFailure{v_22}} : ArenaResult<Inference>}
    case InferenceFailure{+v_20034892}:
      v_17 = v_20034892
      {ArenaResult{v_20034879, InferenceFailure{v_17}} : ArenaResult<Inference>}

def infer_equal_type(v_1: ArenaStore, v_3: Inference, v_5: U32, v_7: U32, v_9: U32, v_10: Ast.SourceSpan, v_13: List<&2, Binding>, v_14: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_3:
    case Inferred{+v_20, +v_21}:
      ArenaResult{v_25, +v_26} = arena_get_node(v_1, v_21)
      match v_26:
        case Arena.TermType{+v_29, +v_30}:
          v_32 = v_20
          ArenaResult{v_36, +v_37} = check_term(v_25, v_5, v_13, v_14, v_32)
          ArenaResult{v_41, +v_42} = check_term(v_36, v_7, v_13, v_14, v_32)
          ArenaResult{v_46, +v_47} = infer_equal_endpoints(v_41, v_37, v_42, v_9, v_10)
          {ArenaResult{v_46, v_47} : ArenaResult<Inference>}
        case _:
          v_50000077 = fail(v_10, "equation annotation is not a type", "a type", "a non-type")
          {ArenaResult{v_25, v_50000077} : ArenaResult<Inference>}
    case InferenceFailure{+v_52}:
      v_54 = v_52
      {ArenaResult{v_1, InferenceFailure{v_54}} : ArenaResult<Inference>}
    case _:
      v_50000078 = fail(v_10, "equation annotation is not a type", "a type", "a non-type")
      {ArenaResult{v_1, v_50000078} : ArenaResult<Inference>}

def infer_application_result_of_function(v_20034916: ArenaStore, v_1: Inference, v_2: U32, v_3: U32, v_4: Ast.SourceSpan, v_7: List<&2, Binding>, v_8: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20034917, +v_20034918}:
      v_13 = v_20034918
      ArenaResult{v_20034919, +v_20034920} = infer_application_result(v_20034916, v_2, v_3, v_13, v_4, v_7, v_8)
      {ArenaResult{v_20034919, v_20034920} : ArenaResult<Inference>}
    case InferenceFailure{+v_20034921}:
      v_16 = v_20034921
      {ArenaResult{v_20034916, InferenceFailure{v_16}} : ArenaResult<Inference>}

def infer_application_valid(v_20034922: ArenaStore, v_1: Bool, v_2: U32, v_3: U32, v_4: U32, v_5: Ast.SourceSpan, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  +v_20034925 = v_1
  match v_20034925:
    case False{}:
      +v_20034923 = fail(v_5, "bang marker is only valid on a named application head", "a named function application", "a bang on a non-name")
      v_20034924 = v_20034922
      {ArenaResult{v_20034924, v_20034923} : ArenaResult<Inference>}
    case True{}:
      ArenaResult{v_20034926, +v_20034927} = application_type_view(v_20034922, v_2)
      ArenaResult{v_20034928, +v_20034929} = infer(v_20034926, v_20034927, v_8, v_9)
      ArenaResult{v_20034930, +v_20034931} = infer_application_result_of_function(v_20034928, v_20034929, v_4, v_3, v_5, v_8, v_9)
      +v_20034923 = v_20034931
      v_20034924 = v_20034930
      {ArenaResult{v_20034924, v_20034923} : ArenaResult<Inference>}

def infer_all_domain(v_1: ArenaStore, v_3: Inference, v_4: Ast.Quantity, v_6: String, v_8: U32, v_10: U32, v_12: U32, v_13: Ast.SourceSpan, v_16: List<&2, Binding>, v_17: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_3:
    case Inferred{+v_23, +v_24}:
      v_26 = v_24
      v_50000079 = domain_quantity(v_4, v_17)
      ArenaResult{v_31, +v_32} = arena_put_node(v_1, Arena.TermQuantity{v_50000079, v_13})
      ArenaResult{v_36, +v_37} = arena_put_node(v_31, Arena.TermType{v_32, v_13})
      v_39 = v_37
      ArenaResult{v_43, +v_44} = fits_term(v_36, v_26, v_39, v_17)
      +v_46 = v_44
      match v_46:
        case False{}:
          +v_49 = fail(v_13, "function domain has insufficient kind", "the binder quantity's kind", "a smaller kind")
          v_51 = v_43
          {ArenaResult{v_51, v_49} : ArenaResult<Inference>}
        case True{}:
          ArenaResult{v_57, +v_58} = infer(v_43, v_10, Binding{v_6, v_4, v_8, List.length(&2, Binding, v_16)} <> v_16, v_17)
          ArenaResult{v_62, +v_63} = check_infer_term_sort(v_57, v_58, v_12, v_13)
          +v_65 = v_63
          v_67 = v_62
          {ArenaResult{v_67, v_65} : ArenaResult<Inference>}
    case InferenceFailure{+v_70}:
      v_72 = v_70
      {ArenaResult{v_1, InferenceFailure{v_72}} : ArenaResult<Inference>}

def infer_let_values(v_20034949: ArenaStore, v_2: Maybe<&2, Diagnostic>, v_5: IR.Names, v_7: IR.Words, v_8: U32, v_9: Ast.SourceSpan, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_2:
    case Some{+v_20034950}:
      v_16 = v_20034950
      {ArenaResult{v_20034949, InferenceFailure{v_16}} : ArenaResult<Inference>}
    case None{}:
      ArenaResult{v_20034951, +v_20034952} = infer_let_lengths(v_20034949, Nat.is_eq(arena_names_length(v_5), arena_words_length(v_7)), v_7, v_8, v_9, v_12, v_13)
      {ArenaResult{v_20034951, v_20034952} : ArenaResult<Inference>}

def infer_let_validated(v_20034953: ArenaStore, v_2: Maybe<&2, Diagnostic>, v_4: IR.Words, v_5: U32, v_6: Ast.SourceSpan, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_2:
    case None{}:
      ArenaResult{v_20034954, +v_20034955} = arena_words_reverse(v_20034953, v_4)
      ArenaResult{v_20034956, +v_20034957} = substitute_many(v_20034954, v_20034955, v_5)
      ArenaResult{v_20034958, +v_20034959} = infer(v_20034956, v_20034957, v_9, v_10)
      {ArenaResult{v_20034958, v_20034959} : ArenaResult<Inference>}
    case Some{+v_20034960}:
      v_15 = v_20034960
      {ArenaResult{v_20034953, InferenceFailure{v_15}} : ArenaResult<Inference>}

def infer_let_lengths(v_20034961: ArenaStore, v_1: Bool, v_3: IR.Words, v_4: U32, v_5: Ast.SourceSpan, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  +v_20034964 = v_1
  match v_20034964:
    case False{}:
      +v_20034962 = fail(v_5, "let binding names and values have different lengths", "one value per name", "mismatched let")
      v_20034963 = v_20034961
      {ArenaResult{v_20034963, v_20034962} : ArenaResult<Inference>}
    case True{}:
      ArenaResult{v_20034965, +v_20034966} = validate_terms(v_20034961, v_3, v_8, v_9)
      ArenaResult{v_20034967, +v_20034968} = infer_let_validated(v_20034965, v_20034966, v_3, v_4, v_5, v_8, v_9)
      +v_20034962 = v_20034968
      v_20034963 = v_20034967
      {ArenaResult{v_20034963, v_20034962} : ArenaResult<Inference>}

def infer(v_1: ArenaStore, v_3: U32, v_6: List<&2, Binding>, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  ArenaResult{v_14, +v_15} = arena_get_node(v_1, v_3)
  match v_15:
    case Arena.TermString{chars, names, span}:
      ArenaResult{next, expanded} = string_desugar_store(v_14, chars, names, span)
      infer(next, expanded, v_6, v_7)
    case Arena.TermVar{+v_19, +v_20, +v_21}:
      ArenaResult{v_25, +v_26} = arena_name_text(v_14, v_19)
      +v_28 = v_26
      v_30 = v_28
      v_32 = v_20
      v_34 = v_21
      ArenaResult{v_40, +v_41} = infer_local_reference(v_25, lookup_binding(v_32, v_6), v_30, List.length(&2, Binding, v_6), v_3, v_34)
      {ArenaResult{v_40, v_41} : ArenaResult<Inference>}
    case Arena.TermBang{+v_44, +v_45}:
      v_47 = v_45
      v_50000080 = fail(v_47, "bang marker is only valid on a named application head", "a named function application", "a standalone bang marker")
      {ArenaResult{v_14, v_50000080} : ArenaResult<Inference>}
    case Arena.TermRef{+v_51, +v_52}:
      ArenaResult{v_56, +v_57} = arena_name_text(v_14, v_51)
      +v_59 = v_57
      v_61 = v_59
      v_63 = v_52
      v_50000081 = infer_global_reference(Scope.lookup(v_61, v_7), v_61, v_3, v_63)
      {ArenaResult{v_56, v_50000081} : ArenaResult<Inference>}
    case Arena.TermAdt{+v_72, +v_73, +v_74, +v_75, +v_76, +v_77}:
      ArenaResult{v_81, +v_82} = arena_name_text(v_14, v_72)
      +v_84 = v_82
      +v_86 = IR.Words{v_73, v_74}
      v_88 = v_84
      v_90 = v_86
      v_92 = v_77
      ArenaResult{v_97, +v_98} = infer_global_adt(v_81, Scope.lookup(v_88, v_7), v_88, v_90, v_3, v_92, v_6, v_7)
      {ArenaResult{v_97, v_98} : ArenaResult<Inference>}
    case Arena.TermFill{+v_103, +v_104, +v_105, +v_106}:
      +v_108 = IR.Words{v_104, v_105}
      v_110 = v_103
      v_112 = v_108
      v_114 = v_106
      ArenaResult{v_118, +v_119} = infer_family_sugar(v_14, v_110, v_112, False{}, v_114, v_6, v_7)
      {ArenaResult{v_118, v_119} : ArenaResult<Inference>}
    case Arena.TermPlus{+v_124, +v_125, +v_126, +v_127}:
      +v_129 = IR.Words{v_125, v_126}
      v_131 = v_124
      v_133 = v_129
      v_135 = v_127
      ArenaResult{v_139, +v_140} = infer_family_sugar(v_14, v_131, v_133, True{}, v_135, v_6, v_7)
      {ArenaResult{v_139, v_140} : ArenaResult<Inference>}
    case Arena.TermAnn{+v_144, +v_145, +v_146}:
      v_148 = v_144
      v_150 = v_145
      v_152 = v_146
      ArenaResult{v_156, +v_157} = arena_put_node(v_14, Arena.TermQuantity{Ast.QOne{}, v_152})
      ArenaResult{v_161, +v_162} = arena_put_node(v_156, Arena.TermType{v_157, v_152})
      ArenaResult{v_166, +v_167} = check_term(v_161, v_150, v_6, v_7, v_162)
      ArenaResult{v_171, +v_172} = infer_term_annotation_result(v_166, v_167, v_148, v_3, v_152, v_6, v_7)
      {ArenaResult{v_171, v_172} : ArenaResult<Inference>}
    case Arena.TermTemplate{+v_175, +v_176}:
      v_178 = v_176
      v_50000082 = fail(v_178, "template term must be expanded before semantic checking", "an expanded term", "an unexpanded template")
      {ArenaResult{v_14, v_50000082} : ArenaResult<Inference>}
    case Arena.TermType{+v_182, +v_183}:
      v_185 = v_182
      v_187 = v_183
      ArenaResult{v_191, +v_192} = infer(v_14, v_185, v_6, v_7)
      ArenaResult{v_196, +v_197} = infer_type_annotation_result(v_191, v_192, v_3, v_187)
      {ArenaResult{v_196, v_197} : ArenaResult<Inference>}
    case Arena.TermQuantity{+v_200, +v_201}:
      ArenaResult{v_205, +v_206} = arena_put_node(v_14, Arena.TermQuant{})
      {ArenaResult{v_205, Inferred{v_3, v_206}} : ArenaResult<Inference>}
    case Arena.TermQuant{}:
      ArenaResult{v_210, +v_211} = arena_put_node(v_14, Arena.TermQuantity{Ast.QOne{}, Ast.SpanOf{"", 0n, 0n}})
      ArenaResult{v_215, +v_216} = arena_put_node(v_210, Arena.TermType{v_211, Ast.SpanOf{"", 0n, 0n}})
      {ArenaResult{v_215, Inferred{v_3, v_216}} : ArenaResult<Inference>}
    case Arena.TermMin{+v_220, +v_221, +v_222}:
      v_224 = v_220
      v_226 = v_221
      v_228 = v_222
      ArenaResult{v_232, +v_233} = infer(v_14, v_224, v_6, v_7)
      ArenaResult{v_237, +v_238} = infer(v_232, v_226, v_6, v_7)
      ArenaResult{v_242, +v_243} = infer_min_results(v_237, v_233, v_238, v_3, v_228)
      {ArenaResult{v_242, v_243} : ArenaResult<Inference>}
    case Arena.TermAll{+v_250, +v_251, +v_252, +v_253, +v_254, +v_255}:
      ArenaResult{v_259, +v_260} = arena_name_text(v_14, v_251)
      +v_262 = v_260
      v_264 = v_250
      v_266 = v_262
      v_268 = v_253
      v_270 = v_254
      v_272 = v_255
      ArenaResult{v_276, +v_277} = infer(v_259, v_268, v_6, v_7)
      ArenaResult{v_281, +v_282} = infer_all_domain(v_276, v_277, v_264, v_266, v_268, v_270, v_3, v_272, v_6, v_7)
      {ArenaResult{v_281, v_282} : ArenaResult<Inference>}
    case Arena.TermApp{+v_286, +v_287, +v_288}:
      v_290 = v_286
      v_292 = v_287
      v_294 = v_288
      ArenaResult{v_298, +v_299} = application_bangs_valid(v_14, v_290)
      ArenaResult{v_303, +v_304} = application_argument_bangs_valid(v_298, v_292)
      ArenaResult{v_308, +v_309} = infer_application_valid(v_303, Bool.and(v_299, v_304), v_290, v_292, v_3, v_294, v_6, v_7)
      {ArenaResult{v_308, v_309} : ArenaResult<Inference>}
    case Arena.TermEqual{+v_314, +v_315, +v_316, +v_317}:
      v_319 = v_314
      v_321 = v_315
      v_323 = v_316
      v_325 = v_317
      ArenaResult{v_329, +v_330} = infer(v_14, v_323, v_6, v_7)
      ArenaResult{v_334, +v_335} = infer_equal_type(v_329, v_330, v_319, v_321, v_3, v_325, v_6, v_7)
      {ArenaResult{v_334, v_335} : ArenaResult<Inference>}
    case Arena.TermLet{+v_346, +v_347, +v_348, +v_349, +v_350, +v_351, +v_352, +v_353, +v_354, +v_355}:
      +v_357 = IR.Names{v_346, v_347}
      +v_359 = IR.Quantities{v_350, v_351}
      +v_361 = IR.Words{v_352, v_353}
      v_363 = v_357
      v_365 = v_359
      v_367 = v_361
      v_369 = v_354
      v_371 = v_355
      ArenaResult{v_375, +v_376} = usage_let_env(v_14, v_363, v_365, v_367, v_6, v_6, v_7, False{})
      v_378 = v_376
      v_381 = arena_names_length(v_363)
      ArenaResult{v_385, +v_386} = binder_usage_map(v_375, v_381, v_369, v_378, v_7, None{}, False{})
      ArenaResult{v_390, +v_391} = check_local_quantity_map(v_385, v_363, v_365, v_386, v_381, v_371)
      ArenaResult{v_395, +v_396} = infer_let_values(v_390, v_391, v_363, v_367, v_369, v_371, v_6, v_7)
      {ArenaResult{v_395, v_396} : ArenaResult<Inference>}
    case Arena.BodyLocal{+v_404, +v_405, +v_406, +v_407, +v_408, +v_409, +v_410}:
      +v_412 = IR.Words{v_404, v_405}
      +v_414 = IR.Words{v_407, v_408}
      v_416 = v_412
      v_418 = v_406
      v_420 = v_414
      v_422 = v_409
      v_424 = v_410
      ArenaResult{v_428, +v_429} = check_body_local(v_14, v_416, v_418, v_420, v_422, v_424, v_6, v_7)
      {ArenaResult{v_428, v_429} : ArenaResult<Inference>}
    case Arena.BodyReply{+v_432, +v_433}:
      v_435 = v_432
      ArenaResult{v_439, +v_440} = infer(v_14, v_435, v_6, v_7)
      {ArenaResult{v_439, v_440} : ArenaResult<Inference>}
    case Arena.TermHole{+v_443, +v_444}:
      ArenaResult{v_448, +v_449} = arena_name_text(v_14, v_443)
      +v_451 = v_449
      v_453 = v_451
      v_455 = v_444
      v_50000083 = fail(v_455, String.append("unsolved hole ", v_453), "a complete term", "a hole")
      {ArenaResult{v_448, v_50000083} : ArenaResult<Inference>}
    case _:
      ArenaResult{v_462, +v_463} = term_span(v_14, v_3)
      v_50000084 = fail(v_463, "term form cannot infer", "an inferable term", "an annotated expression")
      {ArenaResult{v_462, v_50000084} : ArenaResult<Inference>}

def constructor_family_view(v_20035182: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, String>>:
  ArenaResult{v_20035183, +v_20035184} = arena_get_node(v_20035182, v_0)
  match v_20035184:
    case Arena.TermAll{+v_20035191, +v_20035192, +v_20035194, +v_20035195, +v_20035196, +v_20035197}:
      v_14 = v_20035196
      ArenaResult{v_20035198, +v_20035199} = whnf(v_20035183, 64n, v_14, v_1)
      ArenaResult{v_20035200, +v_20035201} = constructor_family_view(v_20035198, v_20035199, v_1)
      {ArenaResult{v_20035200, v_20035201} : ArenaResult<Maybe<&2, String>>}
    case Arena.TermAdt{+v_20035206, +v_20035208, +v_20035209, +v_20035211, +v_20035212, +v_20035214}:
      ArenaResult{v_20035215, +v_20035216} = arena_name_text(v_20035183, v_20035206)
      +v_20035207 = v_20035216
      v_22 = v_20035207
      {ArenaResult{v_20035215, Some{v_22}} : ArenaResult<Maybe<&2, String>>}
    case _:
      {ArenaResult{v_20035183, None{}} : ArenaResult<Maybe<&2, String>>}

def constructor_family_literal(v_20035218: ArenaStore, v_2: Maybe<&2, String>, v_3: U32, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, String>>:
  match v_2:
    case Some{+v_20035219}:
      v_8 = v_20035219
      {ArenaResult{v_20035218, Some{v_8}} : ArenaResult<Maybe<&2, String>>}
    case None{}:
      ArenaResult{v_20035220, +v_20035221} = whnf(v_20035218, 64n, v_3, v_4)
      ArenaResult{v_20035222, +v_20035223} = constructor_family_view(v_20035220, v_20035221, v_4)
      {ArenaResult{v_20035222, v_20035223} : ArenaResult<Maybe<&2, String>>}

def constructor_family(v_20035224: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, String>>:
  ArenaResult{v_20035225, +v_20035226} = arena_constructor_owner(v_20035224, v_0)
  ArenaResult{v_20035227, +v_20035228} = constructor_family_literal(v_20035225, v_20035226, v_0, v_1)
  {ArenaResult{v_20035227, v_20035228} : ArenaResult<Maybe<&2, String>>}

def has_canonical_name(v_20035229: ArenaStore, v_1: String, v_4: IR.Names, v_5: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20035230, +v_20035231} = arena_names_view(v_20035229, v_4)
  match v_20035231:
    case IR.NameNil{}:
      {ArenaResult{v_20035230, False{}} : ArenaResult<Bool>}
    case IR.NameCons{+v_20035232, +v_20035233}:
      +v_9 = v_20035232
      v_10 = v_20035233
      v_12 = Scope.canonical_name(v_1, v_5)
      +v_20035236 = String.eq(v_12, Scope.canonical_name(v_9, v_5))
      match v_20035236:
        case False{}:
          ArenaResult{v_20035237, +v_20035238} = has_canonical_name(v_20035230, v_1, v_10, v_5)
          +v_20035234 = v_20035238
          v_20035235 = v_20035237
          {ArenaResult{v_20035235, v_20035234} : ArenaResult<Bool>}
        case True{}:
          +v_20035234 = True{}
          v_20035235 = v_20035230
          {ArenaResult{v_20035235, v_20035234} : ArenaResult<Bool>}

def canonicalize_strings(v_20035239: ArenaStore, v_2: IR.Names, v_3: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  ArenaResult{v_20035240, +v_20035241} = arena_names_view(v_20035239, v_2)
  match v_20035241:
    case IR.NameNil{}:
      {ArenaResult{v_20035240, IR.Names{0, 0}} : ArenaResult<IR.Names>}
    case IR.NameCons{+v_20035242, +v_20035243}:
      +v_8 = v_20035242
      v_9 = v_20035243
      ArenaResult{v_20035244, +v_20035245} = canonicalize_strings(v_20035240, v_9, v_3)
      ArenaResult{v_20035246, +v_20035247} = arena_names_cons(v_20035244, Scope.canonical_name(v_8, v_3), v_20035245)
      {ArenaResult{v_20035246, v_20035247} : ArenaResult<IR.Names>}

def canonicalize_patterns(v_20035248: ArenaStore, v_1: IR.Words, v_2: Scope.ArenaGlobalScope) -> ArenaResult<IR.Words>:
  ArenaResult{v_20035249, +v_20035250} = arena_words_view(v_20035248, v_1)
  match v_20035250:
    case IR.WordNil{}:
      {ArenaResult{v_20035249, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20035251, +v_20035252}:
      +v_6 = v_20035251
      v_7 = v_20035252
      ArenaResult{v_20035253, +v_20035254} = canonicalize_pattern(v_20035249, v_6, v_2)
      ArenaResult{v_20035255, +v_20035256} = canonicalize_patterns(v_20035253, v_7, v_2)
      ArenaResult{v_20035257, +v_20035258} = arena_words_cons(v_20035255, v_20035254, v_20035256)
      {ArenaResult{v_20035257, v_20035258} : ArenaResult<IR.Words>}

def canonicalize_pattern(v_1: ArenaStore, v_3: U32, v_4: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_11, +v_12} = arena_get_pattern(v_1, v_3)
  match v_12:
    case Arena.PatternVar{+v_17, +v_18, +v_19, +v_20}:
      ArenaResult{v_24, +v_25} = arena_name_text(v_11, v_17)
      +v_27 = v_25
      v_29 = v_27
      v_31 = v_18
      v_33 = v_19
      v_35 = v_20
      ArenaResult{v_39, +v_40} = arena_name(v_24, v_29)
      ArenaResult{v_44, +v_45} = arena_put_pattern(v_39, Arena.PatternVar{v_40, v_31, v_33, v_35})
      {ArenaResult{v_44, v_45} : ArenaResult<U32>}
    case Arena.PatternCtr{+v_50, +v_51, +v_52, +v_53}:
      ArenaResult{v_57, +v_58} = arena_name_text(v_11, v_50)
      +v_60 = v_58
      +v_62 = IR.Words{v_51, v_52}
      v_64 = v_60
      v_66 = v_62
      v_68 = v_53
      ArenaResult{v_72, +v_73} = canonicalize_patterns(v_57, v_66, v_4)
      ArenaResult{v_78, +v_79} = arena_name(v_72, Scope.canonical_name(v_64, v_4))
      v_50000085 = arena_words_start(v_73)
      v_50000086 = arena_words_count(v_73)
      ArenaResult{v_85, +v_86} = arena_put_pattern(v_78, Arena.PatternCtr{v_79, v_50000085, v_50000086, v_68})
      {ArenaResult{v_85, v_86} : ArenaResult<U32>}

def canonicalize_terms(v_20035287: ArenaStore, v_1: IR.Words, v_2: Scope.ArenaGlobalScope) -> ArenaResult<IR.Words>:
  ArenaResult{v_20035288, +v_20035289} = arena_words_view(v_20035287, v_1)
  match v_20035289:
    case IR.WordNil{}:
      {ArenaResult{v_20035288, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20035290, +v_20035291}:
      +v_6 = v_20035290
      v_7 = v_20035291
      ArenaResult{v_20035292, +v_20035293} = canonicalize_term(v_20035288, v_6, v_2)
      ArenaResult{v_20035294, +v_20035295} = canonicalize_terms(v_20035292, v_7, v_2)
      ArenaResult{v_20035296, +v_20035297} = arena_words_cons(v_20035294, v_20035293, v_20035295)
      {ArenaResult{v_20035296, v_20035297} : ArenaResult<IR.Words>}

def canonicalize_term(v_1: ArenaStore, v_3: U32, v_4: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_11, +v_12} = arena_get_node(v_1, v_3)
  match v_12:
    case Arena.TermVar{+v_16, +v_17, +v_18}:
      ArenaResult{v_22, +v_23} = arena_name_text(v_11, v_16)
      +v_25 = v_23
      v_27 = v_25
      v_29 = v_17
      v_31 = v_18
      ArenaResult{v_35, +v_36} = arena_name(v_22, v_27)
      ArenaResult{v_40, +v_41} = arena_put_node(v_35, Arena.TermVar{v_36, v_29, v_31})
      {ArenaResult{v_40, v_41} : ArenaResult<U32>}
    case Arena.TermRef{+v_44, +v_45}:
      ArenaResult{v_49, +v_50} = arena_name_text(v_11, v_44)
      +v_52 = v_50
      v_54 = v_52
      v_56 = v_45
      ArenaResult{v_61, +v_62} = arena_name(v_49, Scope.canonical_name(v_54, v_4))
      ArenaResult{v_66, +v_67} = arena_put_node(v_61, Arena.TermRef{v_62, v_56})
      {ArenaResult{v_66, v_67} : ArenaResult<U32>}
    case Arena.TermBang{+v_70, +v_71}:
      v_73 = v_70
      v_75 = v_71
      ArenaResult{v_79, +v_80} = canonicalize_term(v_11, v_73, v_4)
      ArenaResult{v_84, +v_85} = arena_put_node(v_79, Arena.TermBang{v_80, v_75})
      {ArenaResult{v_84, v_85} : ArenaResult<U32>}
    case Arena.TermSub{+v_90, +v_91, +v_92, +v_93}:
      v_95 = v_90
      v_97 = v_91
      v_99 = v_92
      v_101 = v_93
      ArenaResult{v_105, +v_106} = canonicalize_term(v_11, v_97, v_4)
      ArenaResult{v_110, +v_111} = canonicalize_term(v_105, v_99, v_4)
      ArenaResult{v_115, +v_116} = arena_put_node(v_110, Arena.TermSub{v_95, v_106, v_111, v_101})
      {ArenaResult{v_115, v_116} : ArenaResult<U32>}
    case Arena.TermAnn{+v_120, +v_121, +v_122}:
      v_124 = v_120
      v_126 = v_121
      v_128 = v_122
      ArenaResult{v_132, +v_133} = canonicalize_term(v_11, v_124, v_4)
      ArenaResult{v_137, +v_138} = canonicalize_term(v_132, v_126, v_4)
      ArenaResult{v_142, +v_143} = arena_put_node(v_137, Arena.TermAnn{v_133, v_138, v_128})
      {ArenaResult{v_142, v_143} : ArenaResult<U32>}
    case Arena.TermTemplate{+v_146, +v_147}:
      v_149 = v_146
      v_151 = v_147
      ArenaResult{v_155, +v_156} = canonicalize_term(v_11, v_149, v_4)
      ArenaResult{v_160, +v_161} = arena_put_node(v_155, Arena.TermTemplate{v_156, v_151})
      {ArenaResult{v_160, v_161} : ArenaResult<U32>}
    case Arena.TermLet{+v_172, +v_173, +v_174, +v_175, +v_176, +v_177, +v_178, +v_179, +v_180, +v_181}:
      +v_183 = IR.Names{v_172, v_173}
      +v_185 = IR.Naturals{v_174, v_175}
      +v_187 = IR.Quantities{v_176, v_177}
      +v_189 = IR.Words{v_178, v_179}
      v_191 = v_183
      v_193 = v_185
      v_195 = v_187
      v_197 = v_189
      v_199 = v_180
      v_201 = v_181
      ArenaResult{v_205, +v_206} = canonicalize_terms(v_11, v_197, v_4)
      ArenaResult{v_210, +v_211} = canonicalize_term(v_205, v_199, v_4)
      v_50000087 = arena_names_start(v_191)
      v_50000088 = arena_names_count(v_191)
      v_50000089 = arena_naturals_start(v_193)
      v_50000090 = arena_naturals_count(v_193)
      v_50000091 = arena_quantities_start(v_195)
      v_50000092 = arena_quantities_count(v_195)
      v_50000093 = arena_words_start(v_206)
      v_50000094 = arena_words_count(v_206)
      ArenaResult{v_223, +v_224} = arena_put_node(v_210, Arena.TermLet{v_50000087, v_50000088, v_50000089, v_50000090, v_50000091, v_50000092, v_50000093, v_50000094, v_211, v_201})
      {ArenaResult{v_223, v_224} : ArenaResult<U32>}
    case Arena.TermType{+v_227, +v_228}:
      v_230 = v_227
      v_232 = v_228
      ArenaResult{v_236, +v_237} = canonicalize_term(v_11, v_230, v_4)
      ArenaResult{v_241, +v_242} = arena_put_node(v_236, Arena.TermType{v_237, v_232})
      {ArenaResult{v_241, v_242} : ArenaResult<U32>}
    case Arena.TermQuant{}:
      {ArenaResult{v_11, v_3} : ArenaResult<U32>}
    case Arena.TermQuantity{+v_245, +v_246}:
      v_248 = v_245
      v_250 = v_246
      ArenaResult{v_254, +v_255} = arena_put_node(v_11, Arena.TermQuantity{v_248, v_250})
      {ArenaResult{v_254, v_255} : ArenaResult<U32>}
    case Arena.TermMin{+v_259, +v_260, +v_261}:
      v_263 = v_259
      v_265 = v_260
      v_267 = v_261
      ArenaResult{v_271, +v_272} = canonicalize_term(v_11, v_263, v_4)
      ArenaResult{v_276, +v_277} = canonicalize_term(v_271, v_265, v_4)
      ArenaResult{v_281, +v_282} = arena_put_node(v_276, Arena.TermMin{v_272, v_277, v_267})
      {ArenaResult{v_281, v_282} : ArenaResult<U32>}
    case Arena.TermAll{+v_289, +v_290, +v_291, +v_292, +v_293, +v_294}:
      ArenaResult{v_298, +v_299} = arena_name_text(v_11, v_290)
      +v_301 = v_299
      v_303 = v_289
      v_305 = v_301
      v_307 = v_291
      v_309 = v_292
      v_311 = v_293
      v_313 = v_294
      ArenaResult{v_317, +v_318} = canonicalize_term(v_298, v_309, v_4)
      ArenaResult{v_322, +v_323} = canonicalize_term(v_317, v_311, v_4)
      ArenaResult{v_327, +v_328} = arena_name(v_322, v_305)
      ArenaResult{v_332, +v_333} = arena_put_node(v_327, Arena.TermAll{v_303, v_328, v_307, v_318, v_323, v_313})
      {ArenaResult{v_332, v_333} : ArenaResult<U32>}
    case Arena.TermLam{+v_339, +v_340, +v_341, +v_342, +v_343}:
      ArenaResult{v_347, +v_348} = arena_name_text(v_11, v_340)
      +v_350 = v_348
      v_352 = v_339
      v_354 = v_350
      v_356 = v_341
      v_358 = v_342
      v_360 = v_343
      ArenaResult{v_364, +v_365} = canonicalize_term(v_347, v_358, v_4)
      ArenaResult{v_369, +v_370} = arena_name(v_364, v_354)
      ArenaResult{v_374, +v_375} = arena_put_node(v_369, Arena.TermLam{v_352, v_370, v_356, v_365, v_360})
      {ArenaResult{v_374, v_375} : ArenaResult<U32>}
    case Arena.TermApp{+v_379, +v_380, +v_381}:
      v_383 = v_379
      v_385 = v_380
      v_387 = v_381
      ArenaResult{v_391, +v_392} = canonicalize_term(v_11, v_383, v_4)
      ArenaResult{v_396, +v_397} = canonicalize_term(v_391, v_385, v_4)
      ArenaResult{v_401, +v_402} = arena_put_node(v_396, Arena.TermApp{v_392, v_397, v_387})
      {ArenaResult{v_401, v_402} : ArenaResult<U32>}
    case Arena.TermFill{+v_407, +v_408, +v_409, +v_410}:
      +v_412 = IR.Words{v_408, v_409}
      v_414 = v_407
      v_416 = v_412
      v_418 = v_410
      ArenaResult{v_422, +v_423} = canonicalize_term(v_11, v_414, v_4)
      ArenaResult{v_427, +v_428} = canonicalize_terms(v_422, v_416, v_4)
      v_50000095 = arena_words_start(v_428)
      v_50000096 = arena_words_count(v_428)
      ArenaResult{v_434, +v_435} = arena_put_node(v_427, Arena.TermFill{v_423, v_50000095, v_50000096, v_418})
      {ArenaResult{v_434, v_435} : ArenaResult<U32>}
    case Arena.TermPlus{+v_440, +v_441, +v_442, +v_443}:
      +v_445 = IR.Words{v_441, v_442}
      v_447 = v_440
      v_449 = v_445
      v_451 = v_443
      ArenaResult{v_455, +v_456} = canonicalize_term(v_11, v_447, v_4)
      ArenaResult{v_460, +v_461} = canonicalize_terms(v_455, v_449, v_4)
      v_50000097 = arena_words_start(v_461)
      v_50000098 = arena_words_count(v_461)
      ArenaResult{v_467, +v_468} = arena_put_node(v_460, Arena.TermPlus{v_456, v_50000097, v_50000098, v_451})
      {ArenaResult{v_467, v_468} : ArenaResult<U32>}
    case Arena.TermAdt{+v_475, +v_476, +v_477, +v_478, +v_479, +v_480}:
      ArenaResult{v_484, +v_485} = arena_name_text(v_11, v_475)
      +v_487 = v_485
      +v_489 = IR.Words{v_476, v_477}
      +v_491 = IR.Names{v_478, v_479}
      v_493 = v_487
      v_495 = v_489
      v_497 = v_491
      v_499 = v_480
      ArenaResult{v_503, +v_504} = canonicalize_terms(v_484, v_495, v_4)
      ArenaResult{v_508, +v_509} = canonicalize_strings(v_503, v_497, v_4)
      ArenaResult{v_514, +v_515} = arena_name(v_508, Scope.canonical_name(v_493, v_4))
      v_50000099 = arena_words_start(v_504)
      v_50000100 = arena_words_count(v_504)
      v_50000101 = arena_names_start(v_509)
      v_50000102 = arena_names_count(v_509)
      ArenaResult{v_523, +v_524} = arena_put_node(v_514, Arena.TermAdt{v_515, v_50000099, v_50000100, v_50000101, v_50000102, v_499})
      {ArenaResult{v_523, v_524} : ArenaResult<U32>}
    case Arena.TermString{chars, names, span}:
      arena_put_node(v_11, Arena.TermString{chars, string_canonical_names(names, v_4), span})
    case Arena.TermCtr{+v_529, +v_530, +v_531, +v_532}:
      ArenaResult{v_536, +v_537} = arena_name_text(v_11, v_529)
      +v_539 = v_537
      +v_541 = IR.Words{v_530, v_531}
      v_543 = v_539
      v_545 = v_541
      v_547 = v_532
      ArenaResult{v_551, +v_552} = canonicalize_terms(v_536, v_545, v_4)
      ArenaResult{v_557, +v_558} = arena_name(v_551, Scope.canonical_name(v_543, v_4))
      v_50000103 = arena_words_start(v_552)
      v_50000104 = arena_words_count(v_552)
      ArenaResult{v_564, +v_565} = arena_put_node(v_557, Arena.TermCtr{v_558, v_50000103, v_50000104, v_547})
      {ArenaResult{v_564, v_565} : ArenaResult<U32>}
    case Arena.TermMat{+v_570, +v_571, +v_572, +v_573}:
      ArenaResult{v_577, +v_578} = arena_name_text(v_11, v_570)
      +v_580 = v_578
      v_582 = v_580
      v_584 = v_571
      v_586 = v_572
      v_588 = v_573
      ArenaResult{v_592, +v_593} = canonicalize_term(v_577, v_584, v_4)
      ArenaResult{v_597, +v_598} = canonicalize_term(v_592, v_586, v_4)
      ArenaResult{v_603, +v_604} = arena_name(v_597, Scope.canonical_name(v_582, v_4))
      ArenaResult{v_608, +v_609} = arena_put_node(v_603, Arena.TermMat{v_604, v_593, v_598, v_588})
      {ArenaResult{v_608, v_609} : ArenaResult<U32>}
    case Arena.TermAbsurd{+v_611}:
      {ArenaResult{v_11, v_3} : ArenaResult<U32>}
    case Arena.TermEqual{+v_616, +v_617, +v_618, +v_619}:
      v_621 = v_616
      v_623 = v_617
      v_625 = v_618
      v_627 = v_619
      ArenaResult{v_631, +v_632} = canonicalize_term(v_11, v_621, v_4)
      ArenaResult{v_636, +v_637} = canonicalize_term(v_631, v_623, v_4)
      ArenaResult{v_641, +v_642} = canonicalize_term(v_636, v_625, v_4)
      ArenaResult{v_646, +v_647} = arena_put_node(v_641, Arena.TermEqual{v_632, v_637, v_642, v_627})
      {ArenaResult{v_646, v_647} : ArenaResult<U32>}
    case Arena.TermRefl{+v_649}:
      {ArenaResult{v_11, v_3} : ArenaResult<U32>}
    case Arena.TermRewrite{+v_654, +v_655, +v_656, +v_657}:
      v_659 = v_654
      v_661 = v_655
      v_663 = v_656
      v_665 = v_657
      ArenaResult{v_669, +v_670} = canonicalize_term(v_11, v_659, v_4)
      ArenaResult{v_674, +v_675} = canonicalize_term(v_669, v_661, v_4)
      ArenaResult{v_679, +v_680} = canonicalize_term(v_674, v_663, v_4)
      ArenaResult{v_684, +v_685} = arena_put_node(v_679, Arena.TermRewrite{v_670, v_675, v_680, v_665})
      {ArenaResult{v_684, v_685} : ArenaResult<U32>}
    case Arena.TermHole{+v_688, +v_689}:
      {ArenaResult{v_11, v_3} : ArenaResult<U32>}
    case Arena.BodyMatch{+v_695, +v_696, +v_697, +v_698, +v_699}:
      +v_701 = IR.Words{v_695, v_696}
      +v_703 = IR.Words{v_697, v_698}
      v_705 = v_701
      v_707 = v_703
      v_709 = v_699
      ArenaResult{v_713, +v_714} = canonicalize_terms(v_11, v_705, v_4)
      ArenaResult{v_718, +v_719} = canonicalize_terms(v_713, v_707, v_4)
      v_50000105 = arena_words_start(v_714)
      v_50000106 = arena_words_count(v_714)
      v_50000107 = arena_words_start(v_719)
      v_50000108 = arena_words_count(v_719)
      ArenaResult{v_727, +v_728} = arena_put_node(v_718, Arena.BodyMatch{v_50000105, v_50000106, v_50000107, v_50000108, v_709})
      {ArenaResult{v_727, v_728} : ArenaResult<U32>}
    case Arena.BodyCase{+v_733, +v_734, +v_735, +v_736}:
      +v_738 = IR.Words{v_733, v_734}
      v_740 = v_738
      v_742 = v_735
      v_744 = v_736
      ArenaResult{v_748, +v_749} = canonicalize_patterns(v_11, v_740, v_4)
      ArenaResult{v_753, +v_754} = canonicalize_term(v_748, v_742, v_4)
      v_50000109 = arena_words_start(v_749)
      v_50000110 = arena_words_count(v_749)
      ArenaResult{v_760, +v_761} = arena_put_node(v_753, Arena.BodyCase{v_50000109, v_50000110, v_754, v_744})
      {ArenaResult{v_760, v_761} : ArenaResult<U32>}
    case Arena.BodyLocal{+v_769, +v_770, +v_771, +v_772, +v_773, +v_774, +v_775}:
      +v_777 = IR.Words{v_769, v_770}
      +v_779 = IR.Words{v_772, v_773}
      v_781 = v_777
      v_783 = v_771
      v_785 = v_779
      v_787 = v_774
      v_789 = v_775
      ArenaResult{v_793, +v_794} = canonicalize_patterns(v_11, v_781, v_4)
      ArenaResult{v_798, +v_799} = canonicalize_terms(v_793, v_785, v_4)
      ArenaResult{v_803, +v_804} = canonicalize_term(v_798, v_787, v_4)
      v_50000111 = arena_words_start(v_794)
      v_50000112 = arena_words_count(v_794)
      v_50000113 = arena_words_start(v_799)
      v_50000114 = arena_words_count(v_799)
      ArenaResult{v_812, +v_813} = arena_put_node(v_803, Arena.BodyLocal{v_50000111, v_50000112, v_783, v_50000113, v_50000114, v_804, v_789})
      {ArenaResult{v_812, v_813} : ArenaResult<U32>}
    case Arena.BodyReply{+v_816, +v_817}:
      v_819 = v_816
      v_821 = v_817
      ArenaResult{v_825, +v_826} = canonicalize_term(v_11, v_819, v_4)
      ArenaResult{v_830, +v_831} = arena_put_node(v_825, Arena.BodyReply{v_826, v_821})
      {ArenaResult{v_830, v_831} : ArenaResult<U32>}

def mat_branch_goal_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_7: String, v_8: IR.Words, v_10: Nat, v_11: Ast.SourceSpan, v_12: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_19, +v_20} = arena_get_node(v_1, v_3)
  match v_20:
    case Arena.TermAll{+v_27, +v_28, +v_29, +v_30, +v_31, +v_32}:
      ArenaResult{v_36, +v_37} = arena_name_text(v_19, v_28)
      +v_39 = v_37
      v_41 = v_27
      v_43 = v_39
      v_45 = v_29
      v_47 = v_30
      v_49 = v_31
      v_51 = v_32
      ArenaResult{v_55, +v_56} = arena_name(v_36, v_43)
      ArenaResult{v_60, +v_61} = arena_put_node(v_55, Arena.TermVar{v_56, 0n, v_11})
      ArenaResult{v_65, +v_66} = shift_terms(v_60, v_8, 1n)
      ArenaResult{v_70, +v_71} = arena_words_cons(v_65, v_61, v_66)
      v_73 = v_71
      ArenaResult{v_77, +v_78} = whnf(v_70, 64n, v_49, v_12)
      ArenaResult{v_82, +v_83} = core_shift(v_77, 0n, 1n, v_5)
      ArenaResult{v_87, +v_88} = mat_branch_goal_view(v_82, v_78, v_83, v_7, v_73, Nat.add(v_10, 1n), v_11, v_12)
      v_90 = v_88
      ArenaResult{v_94, +v_95} = arena_name(v_87, v_43)
      ArenaResult{v_99, +v_100} = arena_put_node(v_94, Arena.TermAll{v_41, v_95, v_45, v_47, v_90, v_51})
      {ArenaResult{v_99, v_100} : ArenaResult<U32>}
    case _:
      ArenaResult{v_106, +v_107} = arena_name(v_19, v_7)
      v_50000115 = arena_words_start(v_8)
      v_50000116 = arena_words_count(v_8)
      ArenaResult{v_113, +v_114} = arena_put_node(v_106, Arena.TermCtr{v_107, v_50000115, v_50000116, v_11})
      v_116 = v_114
      ArenaResult{v_120, +v_121} = core_subst(v_113, v_10, v_116, v_5)
      {ArenaResult{v_120, v_121} : ArenaResult<U32>}

def mat_branch_goal(v_20035619: ArenaStore, v_0: U32, v_1: U32, v_3: String, v_5: IR.Words, v_7: Nat, v_8: Ast.SourceSpan, v_9: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_20035620, +v_20035621} = whnf(v_20035619, 64n, v_0, v_9)
  ArenaResult{v_20035622, +v_20035623} = mat_branch_goal_view(v_20035620, v_20035621, v_1, v_3, v_5, v_7, v_8, v_9)
  {ArenaResult{v_20035622, v_20035623} : ArenaResult<U32>}

def check_match_default_result(v_1: Inference, v_2: U32, v_3: U32) -> Inference:
  match v_1:
    case Inferred{+v_20035624, +v_20035625}:
      Inferred{v_2, v_3}
    case InferenceFailure{+v_20035626}:
      v_10 = v_20035626
      InferenceFailure{v_10}

def check_match_head_result(v_1: ArenaStore, v_3: Inference, v_5: U32, v_7: U32, v_9: U32, v_11: U32, v_14: List<&2, Binding>, v_15: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_3:
    case Inferred{+v_21, +v_22}:
      ArenaResult{v_26, +v_27} = check_term(v_1, v_5, v_14, v_15, v_7)
      v_50000117 = check_match_default_result(v_27, v_9, v_11)
      {ArenaResult{v_26, v_50000117} : ArenaResult<Inference>}
    case InferenceFailure{+v_30}:
      v_32 = v_30
      {ArenaResult{v_1, InferenceFailure{v_32}} : ArenaResult<Inference>}

def check_match_applied(v_1: ArenaStore, v_4: Maybe<&2, U32>, v_6: String, v_8: U32, v_10: U32, v_11: Ast.SourceSpan, v_13: U32, v_16: List<&2, Binding>, v_17: Scope.ArenaGlobalScope, v_19: U32, v_21: String, v_22: IR.Words, v_23: IR.Names, v_24: Ast.Quantity, v_26: String, v_28: Nat, v_30: U32, v_32: String) -> ArenaResult<Inference>:
  match v_4:
    case Some{+v_37}:
      v_39 = v_37
      ArenaResult{v_43, +v_44} = mat_branch_goal(v_1, v_39, v_30, v_6, IR.Words{0, 0}, 0n, v_11, v_17)
      v_46 = v_44
      ArenaResult{v_51, +v_52} = arena_names_cons(v_43, Scope.canonical_name(v_6, v_17), IR.Names{0, 0})
      ArenaResult{v_56, +v_57} = arena_names_append(v_51, v_23, v_52)
      v_59 = v_57
      ArenaResult{v_63, +v_64} = arena_name(v_56, v_21)
      v_50000118 = arena_words_start(v_22)
      v_50000119 = arena_words_count(v_22)
      v_50000120 = arena_names_start(v_59)
      v_50000121 = arena_names_count(v_59)
      ArenaResult{v_72, +v_73} = arena_put_node(v_63, Arena.TermAdt{v_64, v_50000118, v_50000119, v_50000120, v_50000121, v_11})
      v_75 = v_73
      ArenaResult{v_79, +v_80} = arena_name(v_72, v_26)
      ArenaResult{v_84, +v_85} = arena_put_node(v_79, Arena.TermAll{v_24, v_80, v_28, v_75, v_30, v_11})
      v_87 = v_85
      ArenaResult{v_91, +v_92} = check_term(v_84, v_8, v_16, v_17, v_46)
      ArenaResult{v_96, +v_97} = check_match_head_result(v_91, v_92, v_10, v_87, v_19, v_13, v_16, v_17)
      {ArenaResult{v_96, v_97} : ArenaResult<Inference>}
    case None{}:
      v_50000122 = fail(v_11, "constructor parameters do not match the datatype", "matching parameter telescope", "incompatible parameters")
      {ArenaResult{v_1, v_50000122} : ArenaResult<Inference>}

def check_match_family_equal(v_20035653: ArenaStore, v_1: Bool, v_3: String, v_5: String, v_6: U32, v_7: U32, v_8: Ast.SourceSpan, v_9: U32, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope, v_14: U32, v_16: String, v_18: IR.Words, v_21: IR.Names, v_22: Ast.Quantity, v_24: String, v_26: Nat, v_27: U32, v_28: U32) -> ArenaResult<Inference>:
  +v_20035656 = v_1
  match v_20035656:
    case False{}:
      +v_20035654 = fail(v_8, "constructor belongs to another datatype", v_16, v_3)
      v_20035655 = v_20035653
      {ArenaResult{v_20035655, v_20035654} : ArenaResult<Inference>}
    case True{}:
      ArenaResult{v_20035657, +v_20035658} = apply_prefix(v_20035653, v_18, v_28)
      ArenaResult{v_20035659, +v_20035660} = check_match_applied(v_20035657, v_20035658, v_5, v_6, v_7, v_8, v_9, v_12, v_13, v_14, v_16, v_18, v_21, v_22, v_24, v_26, v_27, v_3)
      +v_20035654 = v_20035660
      v_20035655 = v_20035659
      {ArenaResult{v_20035655, v_20035654} : ArenaResult<Inference>}

def check_match_family_result(v_1: ArenaStore, v_4: Maybe<&2, String>, v_6: String, v_8: U32, v_10: U32, v_11: Ast.SourceSpan, v_13: U32, v_16: List<&2, Binding>, v_17: Scope.ArenaGlobalScope, v_19: U32, v_21: String, v_23: String, v_24: IR.Words, v_25: IR.Names, v_26: Ast.Quantity, v_28: String, v_30: Nat, v_32: U32, v_34: U32) -> ArenaResult<Inference>:
  match v_4:
    case Some{+v_39}:
      v_41 = v_39
      ArenaResult{v_45, +v_46} = check_match_family_equal(v_1, String.eq(v_41, v_23), v_41, v_6, v_8, v_10, v_11, v_13, v_16, v_17, v_19, v_21, v_24, v_25, v_26, v_28, v_30, v_32, v_34)
      {ArenaResult{v_45, v_46} : ArenaResult<Inference>}
    case None{}:
      v_50000123 = fail(v_11, "match branch is not a constructor", "a constructor of the scrutinee datatype", v_6)
      {ArenaResult{v_1, v_50000123} : ArenaResult<Inference>}

def check_match_global(v_20035665: ArenaStore, v_0: Scope.ArenaGlobal, v_2: String, v_3: U32, v_4: U32, v_5: Ast.SourceSpan, v_6: U32, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope, v_11: U32, v_13: String, v_15: String, v_17: IR.Words, v_20: IR.Names, v_21: Ast.Quantity, v_23: String, v_25: Nat, v_26: U32) -> ArenaResult<Inference>:
  match v_0:
    case Scope.ArenaGlobal{+v_20035666, +v_20035667, +v_20035668, +v_20035669, +v_20035670, +v_20035671}:
      v_37 = v_20035669
      ArenaResult{v_20035672, +v_20035673} = constructor_family(v_20035665, v_37, v_10)
      ArenaResult{v_20035674, +v_20035675} = check_match_family_result(v_20035672, v_20035673, v_2, v_3, v_4, v_5, v_6, v_9, v_10, v_11, v_13, v_15, v_17, v_20, v_21, v_23, v_25, v_26, v_37)
      {ArenaResult{v_20035674, v_20035675} : ArenaResult<Inference>}

def check_match_constructor(v_1: ArenaStore, v_3: Maybe<&2, Scope.ArenaGlobal>, v_5: String, v_7: U32, v_9: U32, v_10: Ast.SourceSpan, v_12: U32, v_15: List<&2, Binding>, v_16: Scope.ArenaGlobalScope, v_18: U32, v_20: String, v_22: String, v_23: IR.Words, v_24: IR.Names, v_25: Ast.Quantity, v_27: String, v_29: Nat, v_31: U32) -> ArenaResult<Inference>:
  match v_3:
    case Some{+v_36}:
      v_38 = v_36
      ArenaResult{v_42, +v_43} = check_match_global(v_1, v_38, v_5, v_7, v_9, v_10, v_12, v_15, v_16, v_18, v_20, v_22, v_23, v_24, v_25, v_27, v_29, v_31)
      {ArenaResult{v_42, v_43} : ArenaResult<Inference>}
    case None{}:
      v_50000124 = fail(v_10, String.append("unknown constructor ", v_5), "a declared constructor", v_5)
      {ArenaResult{v_1, v_50000124} : ArenaResult<Inference>}

def check_match_unexcluded(v_1: ArenaStore, v_3: Bool, v_5: String, v_7: U32, v_9: U32, v_10: Ast.SourceSpan, v_12: U32, v_15: List<&2, Binding>, v_16: Scope.ArenaGlobalScope, v_18: U32, v_20: String, v_22: String, v_23: IR.Words, v_24: IR.Names, v_25: Ast.Quantity, v_27: String, v_29: Nat, v_31: U32) -> ArenaResult<Inference>:
  match v_3:
    case True{}:
      v_50000125 = fail(v_10, "constructor is already excluded from this match", "an unmatched constructor", v_5)
      {ArenaResult{v_1, v_50000125} : ArenaResult<Inference>}
    case False{}:
      ArenaResult{v_40, +v_41} = check_match_constructor(v_1, Scope.lookup_kind(v_5, Scope.GlobalConstructor{}, v_16), v_5, v_7, v_9, v_10, v_12, v_15, v_16, v_18, v_20, v_22, v_23, v_24, v_25, v_27, v_29, v_31)
      {ArenaResult{v_40, v_41} : ArenaResult<Inference>}

def check_match_input_view(v_1: ArenaStore, v_3: U32, v_5: String, v_7: U32, v_9: U32, v_10: Ast.SourceSpan, v_12: U32, v_15: List<&2, Binding>, v_16: Scope.ArenaGlobalScope, v_18: U32, v_19: Ast.Quantity, v_21: String, v_23: Nat, v_25: U32) -> ArenaResult<Inference>:
  ArenaResult{v_32, +v_33} = arena_get_node(v_1, v_3)
  match v_33:
    case Arena.TermAdt{+v_40, +v_41, +v_42, +v_43, +v_44, +v_45}:
      ArenaResult{v_49, +v_50} = arena_name_text(v_32, v_40)
      +v_52 = v_50
      +v_54 = IR.Words{v_41, v_42}
      +v_56 = IR.Names{v_43, v_44}
      v_58 = v_52
      v_60 = v_54
      v_62 = v_56
      ArenaResult{v_66, +v_67} = has_canonical_name(v_49, v_5, v_62, v_16)
      ArenaResult{v_72, +v_73} = check_match_unexcluded(v_66, v_67, v_5, v_7, v_9, v_10, v_12, v_15, v_16, v_18, v_58, Scope.canonical_name(v_58, v_16), v_60, v_62, v_19, v_21, v_23, v_25)
      {ArenaResult{v_72, v_73} : ArenaResult<Inference>}
    case _:
      v_50000126 = fail(v_10, "match scrutinee is not a datatype", "a datatype", "a non-datatype")
      {ArenaResult{v_32, v_50000126} : ArenaResult<Inference>}

def check_match_goal_view(v_1: ArenaStore, v_3: U32, v_5: String, v_7: U32, v_9: U32, v_10: Ast.SourceSpan, v_12: U32, v_15: List<&2, Binding>, v_16: Scope.ArenaGlobalScope, v_18: U32) -> ArenaResult<Inference>:
  ArenaResult{v_25, +v_26} = arena_get_node(v_1, v_3)
  match v_26:
    case Arena.TermAll{+v_33, +v_34, +v_35, +v_36, +v_37, +v_38}:
      ArenaResult{v_42, +v_43} = arena_name_text(v_25, v_34)
      +v_45 = v_43
      v_47 = v_33
      v_49 = v_45
      v_51 = v_35
      v_53 = v_36
      v_55 = v_37
      ArenaResult{v_59, +v_60} = whnf(v_42, 64n, v_53, v_16)
      ArenaResult{v_64, +v_65} = check_match_input_view(v_59, v_60, v_5, v_7, v_9, v_10, v_12, v_15, v_16, v_18, v_47, v_49, v_51, v_55)
      {ArenaResult{v_64, v_65} : ArenaResult<Inference>}
    case _:
      v_50000127 = fail(v_10, "match requires a function goal", "a dependent function type", "a non-function type")
      {ArenaResult{v_25, v_50000127} : ArenaResult<Inference>}

def check_match(v_20035729: ArenaStore, v_1: String, v_2: U32, v_3: U32, v_4: Ast.SourceSpan, v_5: U32, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope, v_10: U32) -> ArenaResult<Inference>:
  ArenaResult{v_20035730, +v_20035731} = whnf(v_20035729, 64n, v_5, v_9)
  ArenaResult{v_20035732, +v_20035733} = check_match_goal_view(v_20035730, v_20035731, v_1, v_2, v_3, v_4, v_5, v_8, v_9, v_10)
  {ArenaResult{v_20035732, v_20035733} : ArenaResult<Inference>}

def scrutinee_variable_index(v_20035734: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Nat>>:
  ArenaResult{v_20035735, +v_20035736} = arena_get_node(v_20035734, v_0)
  match v_20035736:
    case Arena.TermVar{+v_20035740, +v_20035742, +v_20035743}:
      v_8 = v_20035742
      {ArenaResult{v_20035735, Some{v_8}} : ArenaResult<Maybe<&2, Nat>>}
    case _:
      {ArenaResult{v_20035735, None{}} : ArenaResult<Maybe<&2, Nat>>}

def match_scrutinee_binding(v_20035745: ArenaStore, v_2: Maybe<&2, Binding>, v_4: IR.Words, v_7: List<&2, Binding>) -> ArenaResult<Bool>:
  match v_2:
    case Some{+v_20035746}:
      ArenaResult{v_20035747, +v_20035748} = match_scrutinees_valid(v_20035745, v_4, v_7)
      {ArenaResult{v_20035747, v_20035748} : ArenaResult<Bool>}
    case None{}:
      {ArenaResult{v_20035745, False{}} : ArenaResult<Bool>}

def match_scrutinees_valid(v_20035749: ArenaStore, v_1: IR.Words, v_4: List<&2, Binding>) -> ArenaResult<Bool>:
  ArenaResult{v_20035750, +v_20035751} = arena_words_view(v_20035749, v_1)
  match v_20035751:
    case IR.WordNil{}:
      {ArenaResult{v_20035750, True{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20035752, +v_20035753}:
      +v_8 = v_20035752
      v_9 = v_20035753
      ArenaResult{v_20035754, +v_20035755} = arena_get_node(v_20035750, v_8)
      match v_20035755:
        case Arena.TermVar{+v_20035759, +v_20035761, +v_20035762}:
          v_14 = v_20035761
          ArenaResult{v_20035763, +v_20035764} = match_scrutinee_binding(v_20035754, lookup_binding(v_14, v_4), v_9, v_4)
          {ArenaResult{v_20035763, v_20035764} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20035754, False{}} : ArenaResult<Bool>}

def replace_free_terms(v_20035766: ArenaStore, v_1: IR.Words, v_3: Nat, v_4: U32, v_6: Nat) -> ArenaResult<IR.Words>:
  ArenaResult{v_20035767, +v_20035768} = arena_words_view(v_20035766, v_1)
  match v_20035768:
    case IR.WordNil{}:
      {ArenaResult{v_20035767, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20035769, +v_20035770}:
      +v_10 = v_20035769
      v_11 = v_20035770
      ArenaResult{v_20035771, +v_20035772} = replace_free_term(v_20035767, v_10, v_3, v_4, v_6)
      ArenaResult{v_20035773, +v_20035774} = replace_free_terms(v_20035771, v_11, v_3, v_4, v_6)
      ArenaResult{v_20035775, +v_20035776} = arena_words_cons(v_20035773, v_20035772, v_20035774)
      {ArenaResult{v_20035775, v_20035776} : ArenaResult<IR.Words>}

def replace_free_cases(v_1: ArenaStore, v_2: IR.Words, v_4: Nat, v_6: U32, v_8: Nat) -> ArenaResult<IR.Words>:
  ArenaResult{v_14, +v_15} = arena_words_view(v_1, v_2)
  match v_15:
    case IR.WordNil{}:
      {ArenaResult{v_14, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_18, +v_19}:
      +v_21 = v_18
      v_23 = v_19
      ArenaResult{v_27, +v_28} = arena_get_node(v_14, v_21)
      match v_28:
        case Arena.BodyCase{+v_33, +v_34, +v_35, +v_36}:
          +v_38 = IR.Words{v_33, v_34}
          v_40 = v_38
          v_42 = v_35
          v_44 = v_36
          ArenaResult{v_48, +v_49} = core_pattern_list_depth(v_27, v_40)
          ArenaResult{v_53, +v_54} = replace_free_term(v_48, v_42, v_4, v_6, Nat.add(v_8, v_49))
          v_50000128 = arena_words_start(v_40)
          v_50000129 = arena_words_count(v_40)
          ArenaResult{v_60, +v_61} = arena_put_node(v_53, Arena.BodyCase{v_50000128, v_50000129, v_54, v_44})
          ArenaResult{v_65, +v_66} = replace_free_cases(v_60, v_23, v_4, v_6, v_8)
          ArenaResult{v_70, +v_71} = arena_words_cons(v_65, v_61, v_66)
          {ArenaResult{v_70, v_71} : ArenaResult<IR.Words>}
        case _:
          ArenaResult{v_77, +v_78} = replace_free_term(v_27, v_21, v_4, v_6, v_8)
          ArenaResult{v_82, +v_83} = replace_free_cases(v_77, v_23, v_4, v_6, v_8)
          ArenaResult{v_87, +v_88} = arena_words_cons(v_82, v_78, v_83)
          {ArenaResult{v_87, v_88} : ArenaResult<IR.Words>}

# Reuse conservative arena certificates before rebuilding capture types.
# Unknown bounds retain the original traversal. Closed bounds need no index
# arithmetic, including when index/depth are large native Nat values.
def replace_free_unaffected(store: ArenaStore, unaffected: Bool, id: U32, index: Nat, value: U32, depth: Nat) -> ArenaResult<U32>:
  match unaffected:
    case True{}: {ArenaResult{store, id} : ArenaResult<U32>}
    case False{}: replace_free_open(store, id, index, value, depth)

def replace_free_bound(result: ArenaResult<Nat>, id: U32, index: Nat, value: U32, depth: Nat) -> ArenaResult<U32>:
  match result:
    case ArenaResult{store, encoded}:
      match encoded:
        case 0n: replace_free_open(store, id, index, value, depth)
        case 1n: {ArenaResult{store, id} : ArenaResult<U32>}
        case remaining: replace_free_unaffected(store, core_bound_unaffected(remaining, Nat.add(index, depth)), id, index, value, depth)

def replace_free_term(store: ArenaStore, +id: U32, +index: Nat, value: U32, +depth: Nat) -> ArenaResult<U32>:
  replace_free_bound(arena_node_bound(store, id), id, index, value, depth)

def replace_free_open(v_1: ArenaStore, v_3: U32, v_5: Nat, v_7: U32, v_9: Nat) -> ArenaResult<U32>:
  ArenaResult{v_16, +v_17} = arena_get_node(v_1, v_3)
  match v_17:
    case Arena.TermVar{+v_21, +v_22, +v_23}:
      v_25 = v_22
      +v_27 = Nat.is_eq(v_25, Nat.add(v_5, v_9))
      match v_27:
        case True{}:
          match v_9:
            case 0n:
              {ArenaResult{v_16, v_7} : ArenaResult<U32>}
            case _:
              ArenaResult{v_33, +v_34} = core_shift(v_16, 0n, v_9, v_7)
              {ArenaResult{v_33, v_34} : ArenaResult<U32>}
        case False{}:
          {ArenaResult{v_16, v_3} : ArenaResult<U32>}
    case Arena.TermBang{+v_37, +v_38}:
      v_40 = v_37
      v_42 = v_38
      ArenaResult{v_46, +v_47} = replace_free_term(v_16, v_40, v_5, v_7, v_9)
      ArenaResult{v_51, +v_52} = arena_put_node(v_46, Arena.TermBang{v_47, v_42})
      {ArenaResult{v_51, v_52} : ArenaResult<U32>}
    case Arena.TermRef{+v_55, +v_56}:
      {ArenaResult{v_16, v_3} : ArenaResult<U32>}
    case Arena.TermSub{+v_61, +v_62, +v_63, +v_64}:
      v_66 = v_61
      v_68 = v_62
      v_70 = v_63
      ArenaResult{v_74, +v_75} = core_subst(v_16, v_66, v_68, v_70)
      ArenaResult{v_79, +v_80} = replace_free_term(v_74, v_75, v_5, v_7, v_9)
      {ArenaResult{v_79, v_80} : ArenaResult<U32>}
    case Arena.TermLet{+v_91, +v_92, +v_93, +v_94, +v_95, +v_96, +v_97, +v_98, +v_99, +v_100}:
      +v_102 = IR.Names{v_91, v_92}
      +v_104 = IR.Naturals{v_93, v_94}
      +v_106 = IR.Quantities{v_95, v_96}
      +v_108 = IR.Words{v_97, v_98}
      v_110 = v_102
      v_112 = v_104
      v_114 = v_106
      v_116 = v_108
      v_118 = v_99
      v_120 = v_100
      ArenaResult{v_124, +v_125} = replace_free_terms(v_16, v_116, v_5, v_7, v_9)
      ArenaResult{v_130, +v_131} = replace_free_term(v_124, v_118, v_5, v_7, Nat.add(v_9, arena_names_length(v_110)))
      v_50000130 = arena_names_start(v_110)
      v_50000131 = arena_names_count(v_110)
      v_50000132 = arena_naturals_start(v_112)
      v_50000133 = arena_naturals_count(v_112)
      v_50000134 = arena_quantities_start(v_114)
      v_50000135 = arena_quantities_count(v_114)
      v_50000136 = arena_words_start(v_125)
      v_50000137 = arena_words_count(v_125)
      ArenaResult{v_143, +v_144} = arena_put_node(v_130, Arena.TermLet{v_50000130, v_50000131, v_50000132, v_50000133, v_50000134, v_50000135, v_50000136, v_50000137, v_131, v_120})
      {ArenaResult{v_143, v_144} : ArenaResult<U32>}
    case Arena.TermAnn{+v_148, +v_149, +v_150}:
      v_152 = v_148
      v_154 = v_149
      v_156 = v_150
      ArenaResult{v_160, +v_161} = replace_free_term(v_16, v_152, v_5, v_7, v_9)
      ArenaResult{v_165, +v_166} = replace_free_term(v_160, v_154, v_5, v_7, v_9)
      ArenaResult{v_170, +v_171} = arena_put_node(v_165, Arena.TermAnn{v_161, v_166, v_156})
      {ArenaResult{v_170, v_171} : ArenaResult<U32>}
    case Arena.TermTemplate{+v_174, +v_175}:
      v_177 = v_174
      v_179 = v_175
      ArenaResult{v_183, +v_184} = replace_free_term(v_16, v_177, v_5, v_7, v_9)
      ArenaResult{v_188, +v_189} = arena_put_node(v_183, Arena.TermTemplate{v_184, v_179})
      {ArenaResult{v_188, v_189} : ArenaResult<U32>}
    case Arena.TermType{+v_192, +v_193}:
      v_195 = v_192
      v_197 = v_193
      ArenaResult{v_201, +v_202} = replace_free_term(v_16, v_195, v_5, v_7, v_9)
      ArenaResult{v_206, +v_207} = arena_put_node(v_201, Arena.TermType{v_202, v_197})
      {ArenaResult{v_206, v_207} : ArenaResult<U32>}
    case Arena.TermMin{+v_211, +v_212, +v_213}:
      v_215 = v_211
      v_217 = v_212
      v_219 = v_213
      ArenaResult{v_223, +v_224} = replace_free_term(v_16, v_215, v_5, v_7, v_9)
      ArenaResult{v_228, +v_229} = replace_free_term(v_223, v_217, v_5, v_7, v_9)
      ArenaResult{v_233, +v_234} = arena_put_node(v_228, Arena.TermMin{v_224, v_229, v_219})
      {ArenaResult{v_233, v_234} : ArenaResult<U32>}
    case Arena.TermAll{+v_241, +v_242, +v_243, +v_244, +v_245, +v_246}:
      ArenaResult{v_250, +v_251} = arena_name_text(v_16, v_242)
      +v_253 = v_251
      v_255 = v_241
      v_257 = v_253
      v_259 = v_243
      v_261 = v_244
      v_263 = v_245
      v_265 = v_246
      ArenaResult{v_269, +v_270} = replace_free_term(v_250, v_261, v_5, v_7, v_9)
      ArenaResult{v_274, +v_275} = replace_free_term(v_269, v_263, v_5, v_7, Nat.add(v_9, 1n))
      ArenaResult{v_279, +v_280} = arena_name(v_274, v_257)
      ArenaResult{v_284, +v_285} = arena_put_node(v_279, Arena.TermAll{v_255, v_280, v_259, v_270, v_275, v_265})
      {ArenaResult{v_284, v_285} : ArenaResult<U32>}
    case Arena.TermLam{+v_291, +v_292, +v_293, +v_294, +v_295}:
      ArenaResult{v_299, +v_300} = arena_name_text(v_16, v_292)
      +v_302 = v_300
      v_304 = v_291
      v_306 = v_302
      v_308 = v_293
      v_310 = v_294
      v_312 = v_295
      ArenaResult{v_316, +v_317} = replace_free_term(v_299, v_310, v_5, v_7, Nat.add(v_9, 1n))
      ArenaResult{v_321, +v_322} = arena_name(v_316, v_306)
      ArenaResult{v_326, +v_327} = arena_put_node(v_321, Arena.TermLam{v_304, v_322, v_308, v_317, v_312})
      {ArenaResult{v_326, v_327} : ArenaResult<U32>}
    case Arena.TermApp{+v_331, +v_332, +v_333}:
      v_335 = v_331
      v_337 = v_332
      v_339 = v_333
      ArenaResult{v_343, +v_344} = replace_free_term(v_16, v_335, v_5, v_7, v_9)
      ArenaResult{v_348, +v_349} = replace_free_term(v_343, v_337, v_5, v_7, v_9)
      ArenaResult{v_353, +v_354} = arena_put_node(v_348, Arena.TermApp{v_344, v_349, v_339})
      {ArenaResult{v_353, v_354} : ArenaResult<U32>}
    case Arena.TermAdt{+v_361, +v_362, +v_363, +v_364, +v_365, +v_366}:
      ArenaResult{v_370, +v_371} = arena_name_text(v_16, v_361)
      +v_373 = v_371
      +v_375 = IR.Words{v_362, v_363}
      +v_377 = IR.Names{v_364, v_365}
      v_379 = v_373
      v_381 = v_375
      v_383 = v_377
      v_385 = v_366
      ArenaResult{v_389, +v_390} = replace_free_terms(v_370, v_381, v_5, v_7, v_9)
      ArenaResult{v_394, +v_395} = arena_name(v_389, v_379)
      v_50000138 = arena_words_start(v_390)
      v_50000139 = arena_words_count(v_390)
      v_50000140 = arena_names_start(v_383)
      v_50000141 = arena_names_count(v_383)
      ArenaResult{v_403, +v_404} = arena_put_node(v_394, Arena.TermAdt{v_395, v_50000138, v_50000139, v_50000140, v_50000141, v_385})
      {ArenaResult{v_403, v_404} : ArenaResult<U32>}
    case Arena.TermFill{+v_409, +v_410, +v_411, +v_412}:
      +v_414 = IR.Words{v_410, v_411}
      v_416 = v_409
      v_418 = v_414
      v_420 = v_412
      ArenaResult{v_424, +v_425} = replace_free_term(v_16, v_416, v_5, v_7, v_9)
      ArenaResult{v_429, +v_430} = replace_free_terms(v_424, v_418, v_5, v_7, v_9)
      v_50000142 = arena_words_start(v_430)
      v_50000143 = arena_words_count(v_430)
      ArenaResult{v_436, +v_437} = arena_put_node(v_429, Arena.TermFill{v_425, v_50000142, v_50000143, v_420})
      {ArenaResult{v_436, v_437} : ArenaResult<U32>}
    case Arena.TermPlus{+v_442, +v_443, +v_444, +v_445}:
      +v_447 = IR.Words{v_443, v_444}
      v_449 = v_442
      v_451 = v_447
      v_453 = v_445
      ArenaResult{v_457, +v_458} = replace_free_term(v_16, v_449, v_5, v_7, v_9)
      ArenaResult{v_462, +v_463} = replace_free_terms(v_457, v_451, v_5, v_7, v_9)
      v_50000144 = arena_words_start(v_463)
      v_50000145 = arena_words_count(v_463)
      ArenaResult{v_469, +v_470} = arena_put_node(v_462, Arena.TermPlus{v_458, v_50000144, v_50000145, v_453})
      {ArenaResult{v_469, v_470} : ArenaResult<U32>}
    case Arena.TermString{_, _, _}:
      {ArenaResult{v_16, v_3} : ArenaResult<U32>}
    case Arena.TermCtr{+v_475, +v_476, +v_477, +v_478}:
      ArenaResult{v_482, +v_483} = arena_name_text(v_16, v_475)
      +v_485 = v_483
      +v_487 = IR.Words{v_476, v_477}
      v_489 = v_485
      v_491 = v_487
      v_493 = v_478
      ArenaResult{v_497, +v_498} = replace_free_terms(v_482, v_491, v_5, v_7, v_9)
      ArenaResult{v_502, +v_503} = arena_name(v_497, v_489)
      v_50000146 = arena_words_start(v_498)
      v_50000147 = arena_words_count(v_498)
      ArenaResult{v_509, +v_510} = arena_put_node(v_502, Arena.TermCtr{v_503, v_50000146, v_50000147, v_493})
      {ArenaResult{v_509, v_510} : ArenaResult<U32>}
    case Arena.TermMat{+v_515, +v_516, +v_517, +v_518}:
      ArenaResult{v_522, +v_523} = arena_name_text(v_16, v_515)
      +v_525 = v_523
      v_527 = v_525
      v_529 = v_516
      v_531 = v_517
      v_533 = v_518
      ArenaResult{v_537, +v_538} = replace_free_term(v_522, v_529, v_5, v_7, v_9)
      ArenaResult{v_542, +v_543} = replace_free_term(v_537, v_531, v_5, v_7, v_9)
      ArenaResult{v_547, +v_548} = arena_name(v_542, v_527)
      ArenaResult{v_552, +v_553} = arena_put_node(v_547, Arena.TermMat{v_548, v_538, v_543, v_533})
      {ArenaResult{v_552, v_553} : ArenaResult<U32>}
    case Arena.TermEqual{+v_558, +v_559, +v_560, +v_561}:
      v_563 = v_558
      v_565 = v_559
      v_567 = v_560
      v_569 = v_561
      ArenaResult{v_573, +v_574} = replace_free_term(v_16, v_563, v_5, v_7, v_9)
      ArenaResult{v_578, +v_579} = replace_free_term(v_573, v_565, v_5, v_7, v_9)
      ArenaResult{v_583, +v_584} = replace_free_term(v_578, v_567, v_5, v_7, v_9)
      ArenaResult{v_588, +v_589} = arena_put_node(v_583, Arena.TermEqual{v_574, v_579, v_584, v_569})
      {ArenaResult{v_588, v_589} : ArenaResult<U32>}
    case Arena.TermRewrite{+v_594, +v_595, +v_596, +v_597}:
      v_599 = v_594
      v_601 = v_595
      v_603 = v_596
      v_605 = v_597
      ArenaResult{v_609, +v_610} = replace_free_term(v_16, v_599, v_5, v_7, v_9)
      ArenaResult{v_614, +v_615} = replace_free_term(v_609, v_601, v_5, v_7, v_9)
      ArenaResult{v_619, +v_620} = replace_free_term(v_614, v_603, v_5, v_7, v_9)
      ArenaResult{v_624, +v_625} = arena_put_node(v_619, Arena.TermRewrite{v_610, v_615, v_620, v_605})
      {ArenaResult{v_624, v_625} : ArenaResult<U32>}
    case Arena.BodyMatch{+v_631, +v_632, +v_633, +v_634, +v_635}:
      +v_637 = IR.Words{v_631, v_632}
      +v_639 = IR.Words{v_633, v_634}
      v_641 = v_637
      v_643 = v_639
      v_645 = v_635
      ArenaResult{v_649, +v_650} = replace_free_terms(v_16, v_641, v_5, v_7, v_9)
      ArenaResult{v_654, +v_655} = replace_free_cases(v_649, v_643, v_5, v_7, v_9)
      v_50000148 = arena_words_start(v_650)
      v_50000149 = arena_words_count(v_650)
      v_50000150 = arena_words_start(v_655)
      v_50000151 = arena_words_count(v_655)
      ArenaResult{v_663, +v_664} = arena_put_node(v_654, Arena.BodyMatch{v_50000148, v_50000149, v_50000150, v_50000151, v_645})
      {ArenaResult{v_663, v_664} : ArenaResult<U32>}
    case Arena.BodyCase{+v_669, +v_670, +v_671, +v_672}:
      +v_674 = IR.Words{v_669, v_670}
      v_676 = v_674
      v_678 = v_671
      v_680 = v_672
      ArenaResult{v_684, +v_685} = core_pattern_list_depth(v_16, v_676)
      ArenaResult{v_689, +v_690} = replace_free_term(v_684, v_678, v_5, v_7, Nat.add(v_9, v_685))
      v_50000152 = arena_words_start(v_676)
      v_50000153 = arena_words_count(v_676)
      ArenaResult{v_696, +v_697} = arena_put_node(v_689, Arena.BodyCase{v_50000152, v_50000153, v_690, v_680})
      {ArenaResult{v_696, v_697} : ArenaResult<U32>}
    case Arena.BodyLocal{+v_705, +v_706, +v_707, +v_708, +v_709, +v_710, +v_711}:
      +v_713 = IR.Words{v_705, v_706}
      +v_715 = IR.Words{v_708, v_709}
      v_717 = v_713
      v_719 = v_707
      v_721 = v_715
      v_723 = v_710
      v_725 = v_711
      ArenaResult{v_729, +v_730} = replace_free_terms(v_16, v_721, v_5, v_7, v_9)
      ArenaResult{v_734, +v_735} = core_pattern_list_depth(v_729, v_717)
      ArenaResult{v_739, +v_740} = replace_free_term(v_734, v_723, v_5, v_7, Nat.add(v_9, v_735))
      v_50000154 = arena_words_start(v_717)
      v_50000155 = arena_words_count(v_717)
      v_50000156 = arena_words_start(v_730)
      v_50000157 = arena_words_count(v_730)
      ArenaResult{v_748, +v_749} = arena_put_node(v_739, Arena.BodyLocal{v_50000154, v_50000155, v_719, v_50000156, v_50000157, v_740, v_725})
      {ArenaResult{v_748, v_749} : ArenaResult<U32>}
    case Arena.BodyReply{+v_752, +v_753}:
      v_755 = v_752
      v_757 = v_753
      ArenaResult{v_761, +v_762} = replace_free_term(v_16, v_755, v_5, v_7, v_9)
      ArenaResult{v_766, +v_767} = arena_put_node(v_761, Arena.BodyReply{v_762, v_757})
      {ArenaResult{v_766, v_767} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_16, v_3} : ArenaResult<U32>}

def optional_source_quantity(v_2: Maybe<&2, Nat>, v_5: List<&2, Binding>) -> Ast.Quantity:
  match v_2:
    case Some{+v_20036146}:
      v_7 = v_20036146
      binding_quantity_or_one(v_7, v_5)
    case None{}:
      Ast.QOne{}

def replace_match_expected(v_20036147: ArenaStore, v_2: Maybe<&2, Nat>, v_4: Nat, v_5: U32, v_6: U32) -> ArenaResult<U32>:
  match v_2:
    case Some{+v_20036148}:
      v_8 = v_20036148
      ArenaResult{v_20036149, +v_20036150} = core_shift(v_20036147, 0n, v_4, v_5)
      ArenaResult{v_20036151, +v_20036152} = replace_free_term(v_20036149, v_20036150, Nat.add(v_8, v_4), v_6, 0n)
      {ArenaResult{v_20036151, v_20036152} : ArenaResult<U32>}
    case None{}:
      ArenaResult{v_20036153, +v_20036154} = core_shift(v_20036147, 0n, v_4, v_5)
      {ArenaResult{v_20036153, v_20036154} : ArenaResult<U32>}

def refine_binding_types(v_20036155: ArenaStore, v_2: List<&2, Binding>, v_4: Nat, v_5: U32, v_7: Nat) -> ArenaResult<List<&2, Binding>>:
  match v_2:
    case []:
      {ArenaResult{v_20036155, []} : ArenaResult<List<&2, Binding>>}
    case +v_20036156 <> +v_20036157:
      +v_12 = v_20036156
      v_13 = v_20036157
      match v_12:
        case Binding{+v_20036158, +v_20036159, +v_20036160, +v_20036161}:
          v_18 = v_20036158
          v_19 = v_20036159
          ArenaResult{v_20036162, +v_20036163} = binding_type_at(v_20036155, v_12, v_7)
          v_24 = v_20036163
          ArenaResult{v_20036164, +v_20036165} = replace_free_term(v_20036162, v_24, v_4, v_5, 0n)
          v_27 = v_20036165
          ArenaResult{v_20036166, +v_20036167} = refine_binding_types(v_20036164, v_13, v_4, v_5, v_7)
          {ArenaResult{v_20036166, Binding{v_18, v_19, v_27, v_7} <> v_20036167} : ArenaResult<List<&2, Binding>>}

def refine_match_env(v_20036168: ArenaStore, v_2: Maybe<&2, Nat>, v_4: Nat, v_7: List<&2, Binding>, v_8: U32) -> ArenaResult<List<&2, Binding>>:
  match v_2:
    case Some{+v_20036169}:
      v_12 = v_20036169
      ArenaResult{v_20036170, +v_20036171} = refine_binding_types(v_20036168, v_7, Nat.add(v_12, v_4), v_8, List.length(&2, Binding, v_7))
      {ArenaResult{v_20036170, v_20036171} : ArenaResult<List<&2, Binding>>}
    case None{}:
      {ArenaResult{v_20036168, v_7} : ArenaResult<List<&2, Binding>>}

def check_body_matrix_result(v_1: Bool, v_2: Ast.SourceSpan, v_3: U32, v_4: U32) -> Inference:
  +v_20036173 = v_1
  match v_20036173:
    case False{}:
      +v_20036172 = fail(v_2, "match is not exhaustive", "all nested constructor cases", "an uncovered nested constructor")
      v_20036172
    case True{}:
      +v_20036172 = Inferred{v_4, v_3}
      v_20036172

def case_pattern_rows_cons(v_1: IR.Words, v_5: Maybe<&2, List<&2, IR.Words>>) -> Maybe<&2, List<&2, IR.Words>>:
  match v_5:
    case None{}:
      None{}
    case Some{+v_20036174}:
      v_10 = v_20036174
      Some{v_1 <> v_10}

def case_pattern_rows(v_1: ArenaStore, v_2: IR.Words) -> ArenaResult<Maybe<&2, List<&2, IR.Words>>>:
  ArenaResult{v_10, +v_11} = arena_words_view(v_1, v_2)
  match v_11:
    case IR.WordNil{}:
      {ArenaResult{v_10, Some{[]}} : ArenaResult<Maybe<&2, List<&2, IR.Words>>>}
    case IR.WordCons{+v_14, +v_15}:
      +v_17 = v_14
      v_19 = v_15
      ArenaResult{v_23, +v_24} = arena_get_node(v_10, v_17)
      match v_24:
        case Arena.BodyCase{+v_29, +v_30, +v_31, +v_32}:
          +v_34 = IR.Words{v_29, v_30}
          v_36 = v_34
          ArenaResult{v_40, +v_41} = case_pattern_rows(v_23, v_19)
          v_50000158 = case_pattern_rows_cons(v_36, v_41)
          {ArenaResult{v_40, v_50000158} : ArenaResult<Maybe<&2, List<&2, IR.Words>>>}
        case _:
          {ArenaResult{v_23, None{}} : ArenaResult<Maybe<&2, List<&2, IR.Words>>>}

def check_body_matrix_rows(v_1: ArenaStore, v_4: Maybe<&2, List<&2, IR.Words>>, v_5: IR.Words, v_6: Scope.ArenaGlobalScope, v_7: Ast.SourceSpan, v_9: U32, v_11: U32) -> ArenaResult<Inference>:
  match v_4:
    case Some{+v_16}:
      v_18 = v_16
      ArenaResult{v_22, +v_23} = matrix_covers(v_1, v_5, v_18, v_6)
      v_50000159 = check_body_matrix_result(v_23, v_7, v_9, v_11)
      {ArenaResult{v_22, v_50000159} : ArenaResult<Inference>}
    case None{}:
      v_50000160 = fail(v_7, "invalid match case", "a checked case pattern", "an invalid case")
      {ArenaResult{v_1, v_50000160} : ArenaResult<Inference>}

def check_body_match_type_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: IR.Words, v_8: U32, v_9: Ast.SourceSpan, v_11: U32, v_14: List<&2, Binding>, v_15: Scope.ArenaGlobalScope, v_17: U32) -> ArenaResult<Inference>:
  ArenaResult{v_24, +v_25} = arena_get_node(v_1, v_3)
  match v_25:
    case Arena.TermAdt{+v_32, +v_33, +v_34, +v_35, +v_36, +v_37}:
      ArenaResult{v_41, +v_42} = arena_words_cons(v_24, v_8, IR.Words{0, 0})
      ArenaResult{v_46, +v_47} = arena_words_cons(v_41, v_5, IR.Words{0, 0})
      ArenaResult{v_51, +v_52} = check_body_pattern_rows(v_46, v_6, v_42, v_47, v_11, v_17, v_14, v_15, v_9, pattern_row_index_empty())
      ArenaResult{v_56, +v_57} = arena_words_cons(v_51, v_8, IR.Words{0, 0})
      ArenaResult{v_61, +v_62} = arena_words_cons(v_56, v_5, IR.Words{0, 0})
      ArenaResult{v_66, +v_67} = check_body_match_many_rows_result(v_61, v_52, v_57, v_62, v_6, v_9, v_11, v_14, v_15, v_17)
      {ArenaResult{v_66, v_67} : ArenaResult<Inference>}
    case _:
      v_50000161 = fail(v_9, "match scrutinee is not a datatype", "a datatype", "a non-datatype")
      {ArenaResult{v_24, v_50000161} : ArenaResult<Inference>}

def check_body_match_type(v_20036226: ArenaStore, v_0: U32, v_2: IR.Words, v_3: U32, v_4: Ast.SourceSpan, v_5: U32, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope, v_10: U32) -> ArenaResult<Inference>:
  ArenaResult{v_20036227, +v_20036228} = whnf(v_20036226, 64n, v_3, v_9)
  ArenaResult{v_20036229, +v_20036230} = check_body_match_type_view(v_20036227, v_20036228, v_0, v_2, v_3, v_4, v_5, v_8, v_9, v_10)
  {ArenaResult{v_20036229, v_20036230} : ArenaResult<Inference>}

def infer_scrutinee_types_rest(v_20036231: ArenaStore, v_1: ScrutineeTyping, v_2: U32) -> ArenaResult<ScrutineeTyping>:
  match v_1:
    case ScrutineeTypes{+v_20036232}:
      v_5 = v_20036232
      ArenaResult{v_20036233, +v_20036234} = arena_words_cons(v_20036231, v_2, v_5)
      {ArenaResult{v_20036233, ScrutineeTypes{v_20036234}} : ArenaResult<ScrutineeTyping>}
    case ScrutineeTypeFailure{+v_20036235}:
      v_7 = v_20036235
      {ArenaResult{v_20036231, ScrutineeTypeFailure{v_7}} : ArenaResult<ScrutineeTyping>}

def infer_scrutinee_types_result(v_20036236: ArenaStore, v_1: Inference, v_3: IR.Words, v_6: List<&2, Binding>, v_7: Scope.ArenaGlobalScope) -> ArenaResult<ScrutineeTyping>:
  match v_1:
    case Inferred{+v_20036237, +v_20036238}:
      v_12 = v_20036238
      ArenaResult{v_20036239, +v_20036240} = infer_scrutinee_types(v_20036236, v_3, v_6, v_7)
      ArenaResult{v_20036241, +v_20036242} = infer_scrutinee_types_rest(v_20036239, v_20036240, v_12)
      {ArenaResult{v_20036241, v_20036242} : ArenaResult<ScrutineeTyping>}
    case InferenceFailure{+v_20036243}:
      v_16 = v_20036243
      {ArenaResult{v_20036236, ScrutineeTypeFailure{v_16}} : ArenaResult<ScrutineeTyping>}

def infer_scrutinee_types(v_20036244: ArenaStore, v_1: IR.Words, v_4: List<&2, Binding>, v_5: Scope.ArenaGlobalScope) -> ArenaResult<ScrutineeTyping>:
  ArenaResult{v_20036245, +v_20036246} = arena_words_view(v_20036244, v_1)
  match v_20036246:
    case IR.WordNil{}:
      {ArenaResult{v_20036245, ScrutineeTypes{IR.Words{0, 0}}} : ArenaResult<ScrutineeTyping>}
    case IR.WordCons{+v_20036247, +v_20036248}:
      +v_9 = v_20036247
      v_10 = v_20036248
      ArenaResult{v_20036249, +v_20036250} = infer(v_20036245, v_9, v_4, v_5)
      ArenaResult{v_20036251, +v_20036252} = infer_scrutinee_types_result(v_20036249, v_20036250, v_10, v_4, v_5)
      {ArenaResult{v_20036251, v_20036252} : ArenaResult<ScrutineeTyping>}

def family_constructor_keys_seen(v_20036253: ArenaStore, v_2: IR.Names, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, Bool>) -> ArenaResult<Map<&2, Bool>>:
  ArenaResult{v_20036254, +v_20036255} = arena_names_view(v_20036253, v_2)
  match v_20036255:
    case IR.NameNil{}:
      {ArenaResult{v_20036254, v_6} : ArenaResult<Map<&2, Bool>>}
    case IR.NameCons{+v_20036256, +v_20036257}:
      +v_11 = v_20036256
      v_12 = v_20036257
      ArenaResult{v_20036258, +v_20036259} = family_constructor_keys_seen(v_20036254, v_12, v_3, Map.set(&2, Bool, v_6, Scope.canonical_name(v_11, v_3), True{}))
      {ArenaResult{v_20036258, v_20036259} : ArenaResult<Map<&2, Bool>>}

def family_constructor_keys_membership(v_20036260: ArenaStore, v_2: Maybe<&2, Bool>, v_4: String, v_6: String, v_8: List<&2, Scope.ArenaGlobal>, v_10: String, v_13: Map<&2, Bool>, v_16: IR.Names, v_17: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  match v_2:
    case Some{+v_20036261}:
      ArenaResult{v_20036262, +v_20036263} = family_constructor_keys_inner(v_20036260, v_8, v_10, v_13, v_16, v_17)
      {ArenaResult{v_20036262, v_20036263} : ArenaResult<IR.Names>}
    case None{}:
      ArenaResult{v_20036264, +v_20036265} = arena_names_cons(v_20036260, v_4, v_16)
      ArenaResult{v_20036266, +v_20036267} = family_constructor_keys_inner(v_20036264, v_8, v_10, Map.set(&2, Bool, v_13, v_6, True{}), v_20036265, v_17)
      {ArenaResult{v_20036266, v_20036267} : ArenaResult<IR.Names>}

def family_constructor_keys_equal(v_20036268: ArenaStore, v_1: Bool, v_3: String, v_5: List<&2, Scope.ArenaGlobal>, v_7: String, +v_10: Map<&2, Bool>, v_13: IR.Names, v_14: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  match v_1:
    case False{}:
      ArenaResult{v_20036269, +v_20036270} = family_constructor_keys_inner(v_20036268, v_5, v_7, v_10, v_13, v_14)
      {ArenaResult{v_20036269, v_20036270} : ArenaResult<IR.Names>}
    case True{}:
      +v_19 = Scope.canonical_name(v_3, v_14)
      +v_21 = Scope.canonical_name(v_19, v_14)
      ArenaResult{v_20036271, +v_20036272} = family_constructor_keys_membership(v_20036268, IndexLookup.find(Bool, v_10, v_21), v_19, v_21, v_5, v_7, v_10, v_13, v_14)
      {ArenaResult{v_20036271, v_20036272} : ArenaResult<IR.Names>}

def family_constructor_keys_for_type(v_20036273: ArenaStore, v_2: Maybe<&2, String>, v_4: String, v_6: List<&2, Scope.ArenaGlobal>, v_8: String, v_11: Map<&2, Bool>, v_14: IR.Names, v_15: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  match v_2:
    case Some{+v_20036274}:
      v_19 = v_20036274
      ArenaResult{v_20036275, +v_20036276} = family_constructor_keys_equal(v_20036273, Scope.equal_names(v_19, v_8, v_15), v_4, v_6, v_8, v_11, v_14, v_15)
      {ArenaResult{v_20036275, v_20036276} : ArenaResult<IR.Names>}
    case None{}:
      ArenaResult{v_20036277, +v_20036278} = family_constructor_keys_inner(v_20036273, v_6, v_8, v_11, v_14, v_15)
      {ArenaResult{v_20036277, v_20036278} : ArenaResult<IR.Names>}

def family_constructor_keys_inner(v_20036279: ArenaStore, v_1: List<&2, Scope.ArenaGlobal>, v_3: String, v_6: Map<&2, Bool>, v_9: IR.Names, v_10: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  match v_1:
    case []:
      ArenaResult{v_20036280, +v_20036281} = arena_names_reverse(v_20036279, v_9)
      {ArenaResult{v_20036280, v_20036281} : ArenaResult<IR.Names>}
    case +v_20036282 <> +v_20036283:
      +v_16 = v_20036282
      v_17 = v_20036283
      match v_16:
        case Scope.ArenaGlobal{+v_20036290, +v_20036291, +v_20036292, +v_20036293, +v_20036294, +v_20036295}:
          match v_20036295:
            case Scope.GlobalConstructor{}:
              v_23 = v_20036290
              v_26 = v_20036293
              ArenaResult{v_20036296, +v_20036297} = constructor_family(v_20036279, v_26, v_10)
              ArenaResult{v_20036298, +v_20036299} = family_constructor_keys_for_type(v_20036296, v_20036297, v_23, v_17, v_3, v_6, v_9, v_10)
              {ArenaResult{v_20036298, v_20036299} : ArenaResult<IR.Names>}
            case _:
              ArenaResult{v_20036301, +v_20036302} = family_constructor_keys_inner(v_20036279, v_17, v_3, v_6, v_9, v_10)
              {ArenaResult{v_20036301, v_20036302} : ArenaResult<IR.Names>}
        case _:
          ArenaResult{v_20036304, +v_20036305} = family_constructor_keys_inner(v_20036279, v_17, v_3, v_6, v_9, v_10)
          {ArenaResult{v_20036304, v_20036305} : ArenaResult<IR.Names>}

def global_index_constructor_candidates(v_0: Scope.ArenaGlobalIndex, v_2: String) -> Maybe<&2, List<&2, Scope.ArenaGlobal>>:
  match v_0:
    case Scope.ArenaGlobalIndex{+v_20036310, +v_20036311, +v_20036312, +v_20036313}:
      match v_20036313:
        case True{}:
          v_9 = v_20036311
          +v_20036314 = IndexLookup.find(List<&2, Scope.ArenaGlobal>, v_9, v_2)
          match v_20036314:
            case None{}:
              Some{[]}
            case Some{+v_20036315}:
              v_13 = v_20036315
              Some{v_13}
        case _:
          None{}
    case _:
      None{}

def global_segments_constructor_candidates_result(v_2: Maybe<&2, List<&2, Scope.ArenaGlobal>>, v_4: List<&2, Scope.ArenaGlobal>) -> Maybe<&2, List<&2, Scope.ArenaGlobal>>:
  match v_2:
    case None{}:
      None{}
    case Some{+v_20036318}:
      v_8 = v_20036318
      Some{List.append(&2, Scope.ArenaGlobal, v_4, v_8)}

def global_segments_constructor_candidates_head(v_2: Maybe<&2, List<&2, Scope.ArenaGlobal>>, v_4: List<&2, Scope.ArenaGlobalSegment>, v_6: String) -> Maybe<&2, List<&2, Scope.ArenaGlobal>>:
  match v_2:
    case None{}:
      None{}
    case Some{+v_20036319}:
      v_10 = v_20036319
      global_segments_constructor_candidates_result(global_segments_constructor_candidates(v_4, v_6), v_10)

def global_segments_constructor_candidates(v_1: List<&2, Scope.ArenaGlobalSegment>, v_3: String) -> Maybe<&2, List<&2, Scope.ArenaGlobal>>:
  match v_1:
    case []:
      Some{[]}
    case +v_20036320 <> +v_20036321:
      match v_20036320:
        case Scope.ArenaGlobalSegment{+v_20036322, +v_20036323, +v_20036324, +v_20036325, +v_20036326}:
          v_16 = v_20036326
          v_17 = v_20036321
          global_segments_constructor_candidates_head(global_index_constructor_candidates(v_16, v_3), v_17, v_3)

def global_scope_constructor_candidates(v_0: Scope.ArenaGlobalScope, v_2: String) -> Maybe<&2, List<&2, Scope.ArenaGlobal>>:
  match v_0:
    case Scope.ArenaGlobalScope{+v_20036327, +v_20036328, +v_20036329}:
      v_9 = v_20036328
      global_index_constructor_candidates(v_9, v_2)
    case Scope.ArenaVisibleScope{+v_20036330, ignored_lookup}:
      v_13 = v_20036330
      global_segments_constructor_candidates(v_13, v_2)
    case Scope.ArenaUnsafeScope{+v_20036331}:
      v_16 = v_20036331
      global_scope_constructor_candidates(v_16, v_2)

def global_index_family_aliases_for(v_0: Scope.ArenaGlobalIndex, v_2: String) -> IR.Names:
  match v_0:
    case Scope.ArenaGlobalIndex{+v_20036332, +v_20036333, +v_20036334, +v_20036335}:
      v_11 = v_20036334
      +v_20036336 = IndexLookup.find(IR.Names, v_11, v_2)
      match v_20036336:
        case None{}:
          IR.Names{0, 0}
        case Some{+v_20036337}:
          v_16 = v_20036337
          v_16

def global_segments_family_aliases(v_20036338: ArenaStore, v_1: List<&2, Scope.ArenaGlobalSegment>, v_3: String) -> ArenaResult<IR.Names>:
  match v_1:
    case []:
      {ArenaResult{v_20036338, IR.Names{0, 0}} : ArenaResult<IR.Names>}
    case +v_20036339 <> +v_20036340:
      match v_20036339:
        case Scope.ArenaGlobalSegment{+v_20036341, +v_20036342, +v_20036343, +v_20036344, +v_20036345}:
          v_16 = v_20036345
          v_17 = v_20036340
          ArenaResult{v_20036346, +v_20036347} = global_segments_family_aliases(v_20036338, v_17, v_3)
          ArenaResult{v_20036348, +v_20036349} = arena_names_append(v_20036346, global_index_family_aliases_for(v_16, v_3), v_20036347)
          {ArenaResult{v_20036348, v_20036349} : ArenaResult<IR.Names>}

def global_scope_family_aliases(v_1: ArenaStore, v_2: Scope.ArenaGlobalScope, v_4: String) -> ArenaResult<IR.Names>:
  match v_2:
    case Scope.ArenaGlobalScope{+v_10, +v_11, +v_12}:
      v_14 = v_11
      v_50000162 = global_index_family_aliases_for(v_14, v_4)
      {ArenaResult{v_1, v_50000162} : ArenaResult<IR.Names>}
    case Scope.ArenaVisibleScope{+v_17, ignored_lookup}:
      v_19 = v_17
      ArenaResult{v_23, +v_24} = global_segments_family_aliases(v_1, v_19, v_4)
      {ArenaResult{v_23, v_24} : ArenaResult<IR.Names>}
    case Scope.ArenaUnsafeScope{+v_26}:
      v_28 = v_26
      ArenaResult{v_32, +v_33} = global_scope_family_aliases(v_1, v_28, v_4)
      {ArenaResult{v_32, v_33} : ArenaResult<IR.Names>}

def global_index_has_constructor_owner(v_0: Scope.ArenaGlobalIndex, v_2: String) -> Bool:
  match v_0:
    case Scope.ArenaGlobalIndex{+v_20036360, +v_20036361, +v_20036362, +v_20036363}:
      v_9 = v_20036361
      +v_20036364 = IndexLookup.find(List<&2, Scope.ArenaGlobal>, v_9, v_2)
      match v_20036364:
        case None{}:
          False{}
        case Some{+v_20036365}:
          v_14 = v_20036365
          Bool.not(List.is_empty(&2, Scope.ArenaGlobal, v_14))

def global_segments_has_constructor_owner(v_1: List<&2, Scope.ArenaGlobalSegment>, v_3: String) -> Bool:
  match v_1:
    case []:
      False{}
    case +v_20036366 <> +v_20036367:
      match v_20036366:
        case Scope.ArenaGlobalSegment{+v_20036368, +v_20036369, +v_20036370, +v_20036371, +v_20036372}:
          v_15 = v_20036372
          v_16 = v_20036367
          +v_20036373 = global_index_has_constructor_owner(v_15, v_3)
          match v_20036373:
            case True{}:
              True{}
            case False{}:
              global_segments_has_constructor_owner(v_16, v_3)

def global_scope_has_constructor_owner(v_0: Scope.ArenaGlobalScope, v_2: String) -> Bool:
  match v_0:
    case Scope.ArenaGlobalScope{+v_20036374, +v_20036375, +v_20036376}:
      v_8 = v_20036375
      global_index_has_constructor_owner(v_8, v_2)
    case Scope.ArenaVisibleScope{+v_20036377, ignored_lookup}:
      v_12 = v_20036377
      global_segments_has_constructor_owner(v_12, v_2)
    case Scope.ArenaUnsafeScope{+v_20036378}:
      v_15 = v_20036378
      global_scope_has_constructor_owner(v_15, v_2)

def global_scope_constructor_alias_collision(v_20036379: ArenaStore, v_2: IR.Names, v_4: String, v_5: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20036380, +v_20036381} = arena_names_view(v_20036379, v_2)
  match v_20036381:
    case IR.NameNil{}:
      {ArenaResult{v_20036380, False{}} : ArenaResult<Bool>}
    case IR.NameCons{+v_20036382, +v_20036383}:
      +v_9 = v_20036382
      v_10 = v_20036383
      +v_20036384 = String.eq(v_9, v_4)
      match v_20036384:
        case True{}:
          ArenaResult{v_20036385, +v_20036386} = global_scope_constructor_alias_collision(v_20036380, v_10, v_4, v_5)
          {ArenaResult{v_20036385, v_20036386} : ArenaResult<Bool>}
        case False{}:
          +v_20036387 = global_scope_has_constructor_owner(v_5, v_9)
          match v_20036387:
            case False{}:
              ArenaResult{v_20036388, +v_20036389} = global_scope_constructor_alias_collision(v_20036380, v_10, v_4, v_5)
              {ArenaResult{v_20036388, v_20036389} : ArenaResult<Bool>}
            case True{}:
              +v_20036390 = String.eq(Scope.canonical_name(v_9, v_5), v_4)
              match v_20036390:
                case True{}:
                  {ArenaResult{v_20036380, True{}} : ArenaResult<Bool>}
                case False{}:
                  ArenaResult{v_20036391, +v_20036392} = global_scope_constructor_alias_collision(v_20036380, v_10, v_4, v_5)
                  {ArenaResult{v_20036391, v_20036392} : ArenaResult<Bool>}

def family_constructor_keys_candidates(v_20036393: ArenaStore, v_2: Maybe<&2, List<&2, Scope.ArenaGlobal>>, v_4: String, v_5: Scope.ArenaGlobalScope, v_7: String, v_10: Map<&2, Bool>) -> ArenaResult<IR.Names>:
  match v_2:
    case None{}:
      ArenaResult{v_20036394, +v_20036395} = family_constructor_keys_inner(v_20036393, global_scope_entries(v_5), v_7, v_10, IR.Names{0, 0}, v_5)
      {ArenaResult{v_20036394, v_20036395} : ArenaResult<IR.Names>}
    case Some{+v_20036396}:
      v_16 = v_20036396
      ArenaResult{v_20036397, +v_20036398} = global_scope_family_aliases(v_20036393, v_5, v_4)
      ArenaResult{v_20036399, +v_20036400} = global_scope_constructor_alias_collision(v_20036397, v_20036398, v_4, v_5)
      match v_20036400:
        case True{}:
          ArenaResult{v_20036401, +v_20036402} = family_constructor_keys_inner(v_20036399, global_scope_entries(v_5), v_7, v_10, IR.Names{0, 0}, v_5)
          {ArenaResult{v_20036401, v_20036402} : ArenaResult<IR.Names>}
        case False{}:
          ArenaResult{v_20036403, +v_20036404} = family_constructor_keys_inner(v_20036399, v_16, v_7, v_10, IR.Names{0, 0}, v_5)
          {ArenaResult{v_20036403, v_20036404} : ArenaResult<IR.Names>}

def family_constructor_keys(v_20036405: ArenaStore, v_0: Scope.ArenaGlobalScope, v_2: String, v_5: IR.Names) -> ArenaResult<IR.Names>:
  v_9 = Scope.canonical_name(v_2, v_0)
  ArenaResult{v_20036406, +v_20036407} = family_constructor_keys_seen(v_20036405, v_5, v_0, MTip{})
  ArenaResult{v_20036408, +v_20036409} = family_constructor_keys_candidates(v_20036406, global_scope_constructor_candidates(v_0, v_9), v_9, v_0, v_2, v_20036407)
  {ArenaResult{v_20036408, v_20036409} : ArenaResult<IR.Names>}

def residual_has_reachable_constructor(v_1: ArenaStore, v_3: String, v_4: IR.Words, v_5: IR.Names, v_6: Ast.SourceSpan, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_14, +v_15} = arena_name(v_1, v_3)
  v_50000163 = arena_words_start(v_4)
  v_50000164 = arena_words_count(v_4)
  v_50000165 = arena_names_start(v_5)
  v_50000166 = arena_names_count(v_5)
  ArenaResult{v_23, +v_24} = arena_put_node(v_14, Arena.TermAdt{v_15, v_50000163, v_50000164, v_50000165, v_50000166, v_6})
  v_26 = v_24
  ArenaResult{v_30, +v_31} = constructors_for_type(v_23, v_26, v_7)
  v_50000167 = Bool.not(arena_names_is_empty(v_31))
  {ArenaResult{v_30, v_50000167} : ArenaResult<Bool>}

def constructor_pattern_reachable_result(v_20036417: ArenaStore, v_1: PatternTyping, v_2: U32, v_4: String, v_5: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_1:
    case PatternTyped{+v_20036418, +v_20036419}:
      {ArenaResult{v_20036417, True{}} : ArenaResult<Bool>}
    case PatternTypeFailure{+v_20036420}:
      ArenaResult{v_20036421, +v_20036422} = constructor_result_possible(v_20036417, v_2, v_4, v_5)
      {ArenaResult{v_20036421, v_20036422} : ArenaResult<Bool>}

def constructor_pattern_reachable(v_1: ArenaStore, v_3: U32, v_5: String, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  v_11 = Ast.SpanOf{"", 0n, 0n}
  ArenaResult{v_15, +v_16} = arena_name(v_1, v_5)
  v_50000168 = arena_words_start(IR.Words{0, 0})
  v_50000169 = arena_words_count(IR.Words{0, 0})
  ArenaResult{v_22, +v_23} = arena_put_pattern(v_15, Arena.PatternCtr{v_16, v_50000168, v_50000169, v_11})
  v_25 = v_23
  ArenaResult{v_29, +v_30} = check_pattern_typed(v_22, v_25, v_3, Some{Ast.QOne{}}, 0n, [], v_6)
  ArenaResult{v_34, +v_35} = constructor_pattern_reachable_result(v_29, v_30, v_3, v_5, v_6)
  {ArenaResult{v_34, v_35} : ArenaResult<Bool>}

def index_terms_compatible_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_13, +v_14} = arena_get_node(v_1, v_3)
  match v_14:
    case Arena.TermVar{+v_18, +v_19, +v_20}:
      {ArenaResult{v_13, True{}} : ArenaResult<Bool>}
    case Arena.TermHole{+v_23, +v_24}:
      ArenaResult{v_28, +v_29} = arena_get_node(v_13, v_5)
      match v_29:
        case Arena.TermVar{+v_33, +v_34, +v_35}:
          {ArenaResult{v_28, True{}} : ArenaResult<Bool>}
        case Arena.TermHole{+v_38, +v_39}:
          {ArenaResult{v_28, True{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_28, True{}} : ArenaResult<Bool>}
    case Arena.TermCtr{+v_46, +v_47, +v_48, +v_49}:
      ArenaResult{v_53, +v_54} = arena_name_text(v_13, v_46)
      +v_56 = v_54
      +v_58 = IR.Words{v_47, v_48}
      ArenaResult{v_62, +v_63} = arena_get_node(v_53, v_5)
      match v_63:
        case Arena.TermVar{+v_67, +v_68, +v_69}:
          {ArenaResult{v_62, True{}} : ArenaResult<Bool>}
        case Arena.TermHole{+v_72, +v_73}:
          {ArenaResult{v_62, True{}} : ArenaResult<Bool>}
        case Arena.TermCtr{+v_78, +v_79, +v_80, +v_81}:
          ArenaResult{v_85, +v_86} = arena_name_text(v_62, v_78)
          +v_88 = v_86
          +v_90 = IR.Words{v_79, v_80}
          v_92 = v_88
          v_94 = v_90
          v_96 = v_56
          v_98 = v_58
          ArenaResult{v_102, +v_103} = index_term_lists_compatible(v_85, v_98, v_94, v_6)
          v_50000170 = Bool.and(String.eq(v_96, v_92), Bool.and(Nat.is_eq(arena_words_length(v_98), arena_words_length(v_94)), v_103))
          {ArenaResult{v_102, v_50000170} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_62, True{}} : ArenaResult<Bool>}
    case Arena.TermAdt{+v_114, +v_115, +v_116, +v_117, +v_118, +v_119}:
      ArenaResult{v_123, +v_124} = arena_name_text(v_13, v_114)
      +v_126 = v_124
      +v_128 = IR.Words{v_115, v_116}
      ArenaResult{v_132, +v_133} = arena_get_node(v_123, v_5)
      match v_133:
        case Arena.TermVar{+v_137, +v_138, +v_139}:
          {ArenaResult{v_132, True{}} : ArenaResult<Bool>}
        case Arena.TermHole{+v_142, +v_143}:
          {ArenaResult{v_132, True{}} : ArenaResult<Bool>}
        case Arena.TermAdt{+v_150, +v_151, +v_152, +v_153, +v_154, +v_155}:
          ArenaResult{v_159, +v_160} = arena_name_text(v_132, v_150)
          +v_162 = v_160
          +v_164 = IR.Words{v_151, v_152}
          v_166 = v_162
          v_168 = v_164
          v_170 = v_126
          v_172 = v_128
          ArenaResult{v_176, +v_177} = index_term_lists_compatible(v_159, v_172, v_168, v_6)
          v_50000171 = Bool.and(Scope.equal_names(v_170, v_166, v_6), Bool.and(Nat.is_eq(arena_words_length(v_172), arena_words_length(v_168)), v_177))
          {ArenaResult{v_176, v_50000171} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_132, True{}} : ArenaResult<Bool>}
    case _:
      ArenaResult{v_188, +v_189} = arena_get_node(v_13, v_5)
      match v_189:
        case Arena.TermVar{+v_193, +v_194, +v_195}:
          {ArenaResult{v_188, True{}} : ArenaResult<Bool>}
        case Arena.TermHole{+v_198, +v_199}:
          {ArenaResult{v_188, True{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_188, True{}} : ArenaResult<Bool>}

def index_terms_compatible(v_20036593: ArenaStore, v_0: U32, v_1: U32, v_2: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20036594, +v_20036595} = equal_term(v_20036593, v_0, v_1, v_2)
  ArenaResult{v_20036596, +v_20036597} = whnf(v_20036594, 64n, v_0, v_2)
  ArenaResult{v_20036598, +v_20036599} = whnf(v_20036596, 64n, v_1, v_2)
  ArenaResult{v_20036600, +v_20036601} = index_terms_compatible_view(v_20036598, v_20036597, v_20036599, v_2)
  {ArenaResult{v_20036600, Bool.or(v_20036595, v_20036601)} : ArenaResult<Bool>}

def index_term_lists_compatible(v_20036602: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20036603, +v_20036604} = arena_words_view(v_20036602, v_1)
  match v_20036604:
    case IR.WordNil{}:
      ArenaResult{v_20036605, +v_20036606} = arena_words_view(v_20036603, v_3)
      match v_20036606:
        case IR.WordNil{}:
          {ArenaResult{v_20036605, True{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20036605, False{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20036610, +v_20036611}:
      ArenaResult{v_20036612, +v_20036613} = arena_words_view(v_20036603, v_3)
      match v_20036613:
        case IR.WordCons{+v_20036616, +v_20036617}:
          +v_12 = v_20036616
          v_13 = v_20036617
          +v_10 = v_20036610
          v_11 = v_20036611
          ArenaResult{v_20036620, +v_20036621} = index_terms_compatible(v_20036612, v_10, v_12, v_4)
          +v_20036622 = v_20036621
          match v_20036622:
            case False{}:
              +v_20036618 = False{}
              v_20036619 = v_20036620
              {ArenaResult{v_20036619, v_20036618} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_20036623, +v_20036624} = index_term_lists_compatible(v_20036620, v_11, v_13, v_4)
              +v_20036618 = v_20036624
              v_20036619 = v_20036623
              {ArenaResult{v_20036619, v_20036618} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20036612, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20036603, False{}} : ArenaResult<Bool>}

def constructor_result_term(v_1: ArenaStore, v_3: U32, v_5: String, v_6: IR.Words, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_14, +v_15} = arena_get_node(v_1, v_3)
  match v_15:
    case Arena.TermAll{+v_22, +v_23, +v_24, +v_25, +v_26, +v_27}:
      {ArenaResult{v_14, True{}} : ArenaResult<Bool>}
    case Arena.TermAdt{+v_34, +v_35, +v_36, +v_37, +v_38, +v_39}:
      ArenaResult{v_43, +v_44} = arena_name_text(v_14, v_34)
      +v_46 = v_44
      +v_48 = IR.Words{v_35, v_36}
      v_50 = v_46
      v_52 = v_48
      ArenaResult{v_56, +v_57} = index_term_lists_compatible(v_43, v_52, v_6, v_7)
      v_50000172 = Bool.and(Scope.equal_names(v_50, v_5, v_7), v_57)
      {ArenaResult{v_56, v_50000172} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_14, True{}} : ArenaResult<Bool>}

def constructor_result_applied(v_20036661: ArenaStore, v_1: Maybe<&2, U32>, v_3: String, v_5: IR.Words, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_1:
    case None{}:
      {ArenaResult{v_20036661, False{}} : ArenaResult<Bool>}
    case Some{+v_20036662}:
      v_9 = v_20036662
      ArenaResult{v_20036663, +v_20036664} = whnf(v_20036661, 64n, v_9, v_6)
      ArenaResult{v_20036665, +v_20036666} = constructor_result_term(v_20036663, v_20036664, v_3, v_5, v_6)
      {ArenaResult{v_20036665, v_20036666} : ArenaResult<Bool>}

def constructor_result_global(v_20036667: ArenaStore, v_0: Scope.ArenaGlobal, v_2: String, v_4: IR.Words, v_5: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_0:
    case Scope.ArenaGlobal{+v_20036668, +v_20036669, +v_20036670, +v_20036671, +v_20036672, +v_20036673}:
      v_16 = v_20036671
      ArenaResult{v_20036674, +v_20036675} = apply_prefix(v_20036667, v_4, v_16)
      ArenaResult{v_20036676, +v_20036677} = constructor_result_applied(v_20036674, v_20036675, v_2, v_4, v_5)
      {ArenaResult{v_20036676, v_20036677} : ArenaResult<Bool>}

def constructor_result_lookup(v_20036678: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_3: String, v_5: IR.Words, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_1:
    case None{}:
      {ArenaResult{v_20036678, False{}} : ArenaResult<Bool>}
    case Some{+v_20036679}:
      v_9 = v_20036679
      ArenaResult{v_20036680, +v_20036681} = constructor_result_global(v_20036678, v_9, v_3, v_5, v_6)
      {ArenaResult{v_20036680, v_20036681} : ArenaResult<Bool>}

def constructor_result_view(v_20036682: ArenaStore, v_0: U32, v_2: String, v_3: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20036683, +v_20036684} = arena_get_node(v_20036682, v_0)
  match v_20036684:
    case Arena.TermAdt{+v_20036689, +v_20036691, +v_20036692, +v_20036694, +v_20036695, +v_20036697}:
      ArenaResult{v_20036698, +v_20036699} = arena_name_text(v_20036683, v_20036689)
      +v_20036690 = v_20036699
      +v_20036693 = IR.Words{v_20036691, v_20036692}
      v_9 = v_20036690
      v_10 = v_20036693
      ArenaResult{v_20036700, +v_20036701} = constructor_result_lookup(v_20036698, Scope.lookup_kind(v_2, Scope.GlobalConstructor{}, v_3), v_9, v_10, v_3)
      {ArenaResult{v_20036700, v_20036701} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20036683, False{}} : ArenaResult<Bool>}

def constructor_result_possible(v_20036703: ArenaStore, v_0: U32, v_2: String, v_3: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20036704, +v_20036705} = whnf(v_20036703, 64n, v_0, v_3)
  ArenaResult{v_20036706, +v_20036707} = constructor_result_view(v_20036704, v_20036705, v_2, v_3)
  {ArenaResult{v_20036706, v_20036707} : ArenaResult<Bool>}

def filter_reachable_result(v_20036708: ArenaStore, v_1: Bool, v_3: String, v_6: IR.Names, v_7: U32, v_8: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  match v_1:
    case True{}:
      ArenaResult{v_20036709, +v_20036710} = filter_reachable_constructors(v_20036708, v_6, v_7, v_8)
      ArenaResult{v_20036711, +v_20036712} = arena_names_cons(v_20036709, v_3, v_20036710)
      {ArenaResult{v_20036711, v_20036712} : ArenaResult<IR.Names>}
    case False{}:
      ArenaResult{v_20036713, +v_20036714} = filter_reachable_constructors(v_20036708, v_6, v_7, v_8)
      {ArenaResult{v_20036713, v_20036714} : ArenaResult<IR.Names>}

def filter_reachable_constructors(v_20036715: ArenaStore, v_2: IR.Names, v_3: U32, v_4: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  ArenaResult{v_20036716, +v_20036717} = arena_names_view(v_20036715, v_2)
  match v_20036717:
    case IR.NameNil{}:
      {ArenaResult{v_20036716, IR.Names{0, 0}} : ArenaResult<IR.Names>}
    case IR.NameCons{+v_20036718, +v_20036719}:
      +v_9 = v_20036718
      v_10 = v_20036719
      ArenaResult{v_20036720, +v_20036721} = constructor_pattern_reachable(v_20036716, v_3, v_9, v_4)
      ArenaResult{v_20036722, +v_20036723} = filter_reachable_result(v_20036720, v_20036721, v_9, v_10, v_3, v_4)
      {ArenaResult{v_20036722, v_20036723} : ArenaResult<IR.Names>}

def constructors_for_type_view(v_20036724: ArenaStore, v_0: U32, v_1: U32, v_2: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  ArenaResult{v_20036725, +v_20036726} = arena_get_node(v_20036724, v_0)
  match v_20036726:
    case Arena.TermAdt{+v_20036731, +v_20036733, +v_20036734, +v_20036736, +v_20036737, +v_20036739}:
      ArenaResult{v_20036740, +v_20036741} = arena_name_text(v_20036725, v_20036731)
      +v_20036732 = v_20036741
      +v_20036738 = IR.Names{v_20036736, v_20036737}
      v_9 = v_20036732
      v_11 = v_20036738
      v_14 = Scope.canonical_name(v_9, v_2)
      ArenaResult{v_20036742, +v_20036743} = family_constructor_keys(v_20036740, v_2, v_14, v_11)
      ArenaResult{v_20036744, +v_20036745} = filter_reachable_constructors(v_20036742, v_20036743, v_1, v_2)
      {ArenaResult{v_20036744, v_20036745} : ArenaResult<IR.Names>}
    case _:
      {ArenaResult{v_20036725, IR.Names{0, 0}} : ArenaResult<IR.Names>}

def constructors_for_type(v_20036747: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  ArenaResult{v_20036748, +v_20036749} = whnf(v_20036747, 64n, v_0, v_1)
  ArenaResult{v_20036750, +v_20036751} = constructors_for_type_view(v_20036748, v_20036749, v_0, v_1)
  {ArenaResult{v_20036750, v_20036751} : ArenaResult<IR.Names>}

def collect_constructor_field_types_view(v_20036752: ArenaStore, v_0: U32, v_1: Ast.SourceSpan, v_2: Scope.ArenaGlobalScope, v_4: Nat) -> ArenaResult<IR.Words>:
  ArenaResult{v_20036753, +v_20036754} = arena_get_node(v_20036752, v_0)
  match v_20036754:
    case Arena.TermAll{+v_20036761, +v_20036762, +v_20036764, +v_20036765, +v_20036766, +v_20036767}:
      ArenaResult{v_20036768, +v_20036769} = arena_name_text(v_20036753, v_20036762)
      +v_20036763 = v_20036769
      v_13 = v_20036763
      v_15 = v_20036765
      v_16 = v_20036766
      ArenaResult{v_20036770, +v_20036771} = arena_name(v_20036768, v_13)
      ArenaResult{v_20036772, +v_20036773} = arena_put_node(v_20036770, Arena.TermVar{v_20036771, v_4, v_1})
      v_19 = v_20036773
      ArenaResult{v_20036774, +v_20036775} = core_subst(v_20036772, 0n, v_19, v_16)
      v_21 = v_20036775
      ArenaResult{v_20036776, +v_20036777} = whnf(v_20036774, 64n, v_21, v_2)
      ArenaResult{v_20036778, +v_20036779} = collect_constructor_field_types_view(v_20036776, v_20036777, v_1, v_2, Nat.add(v_4, 1n))
      ArenaResult{v_20036780, +v_20036781} = arena_words_cons(v_20036778, v_15, v_20036779)
      {ArenaResult{v_20036780, v_20036781} : ArenaResult<IR.Words>}
    case _:
      {ArenaResult{v_20036753, IR.Words{0, 0}} : ArenaResult<IR.Words>}

def collect_constructor_field_types(v_20036783: ArenaStore, v_0: U32, v_1: Ast.SourceSpan, v_2: Scope.ArenaGlobalScope, v_4: Nat) -> ArenaResult<IR.Words>:
  ArenaResult{v_20036784, +v_20036785} = whnf(v_20036783, 64n, v_0, v_2)
  ArenaResult{v_20036786, +v_20036787} = collect_constructor_field_types_view(v_20036784, v_20036785, v_1, v_2, v_4)
  {ArenaResult{v_20036786, v_20036787} : ArenaResult<IR.Words>}

def constructor_field_types_applied(v_20036788: ArenaStore, v_1: Maybe<&2, U32>, v_2: Ast.SourceSpan, v_3: Scope.ArenaGlobalScope) -> ArenaResult<IR.Words>:
  match v_1:
    case Some{+v_20036789}:
      v_6 = v_20036789
      ArenaResult{v_20036790, +v_20036791} = collect_constructor_field_types(v_20036788, v_6, v_2, v_3, 0n)
      {ArenaResult{v_20036790, v_20036791} : ArenaResult<IR.Words>}
    case None{}:
      {ArenaResult{v_20036788, IR.Words{0, 0}} : ArenaResult<IR.Words>}

def constructor_field_types_family(v_20036792: ArenaStore, v_2: Maybe<&2, String>, v_4: String, v_6: IR.Words, v_7: U32, v_8: Ast.SourceSpan, v_9: Scope.ArenaGlobalScope) -> ArenaResult<IR.Words>:
  match v_2:
    case None{}:
      {ArenaResult{v_20036792, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case Some{+v_20036793}:
      v_12 = v_20036793
      +v_20036796 = Scope.equal_names(v_12, v_4, v_9)
      match v_20036796:
        case False{}:
          +v_20036794 = IR.Words{0, 0}
          v_20036795 = v_20036792
          {ArenaResult{v_20036795, v_20036794} : ArenaResult<IR.Words>}
        case True{}:
          ArenaResult{v_20036797, +v_20036798} = apply_prefix(v_20036792, v_6, v_7)
          ArenaResult{v_20036799, +v_20036800} = constructor_field_types_applied(v_20036797, v_20036798, v_8, v_9)
          +v_20036794 = v_20036800
          v_20036795 = v_20036799
          {ArenaResult{v_20036795, v_20036794} : ArenaResult<IR.Words>}

def constructor_field_types_global(v_20036801: ArenaStore, v_0: Scope.ArenaGlobal, v_2: String, v_4: IR.Words, v_5: Ast.SourceSpan, v_6: Scope.ArenaGlobalScope) -> ArenaResult<IR.Words>:
  match v_0:
    case Scope.ArenaGlobal{+v_20036802, +v_20036803, +v_20036804, +v_20036805, +v_20036806, +v_20036807}:
      v_17 = v_20036805
      ArenaResult{v_20036808, +v_20036809} = constructor_family(v_20036801, v_17, v_6)
      ArenaResult{v_20036810, +v_20036811} = constructor_field_types_family(v_20036808, v_20036809, v_2, v_4, v_17, v_5, v_6)
      {ArenaResult{v_20036810, v_20036811} : ArenaResult<IR.Words>}

def constructor_field_types_lookup(v_20036812: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_3: String, v_5: IR.Words, v_6: Ast.SourceSpan, v_7: Scope.ArenaGlobalScope) -> ArenaResult<IR.Words>:
  match v_1:
    case None{}:
      {ArenaResult{v_20036812, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case Some{+v_20036813}:
      v_10 = v_20036813
      ArenaResult{v_20036814, +v_20036815} = constructor_field_types_global(v_20036812, v_10, v_3, v_5, v_6, v_7)
      {ArenaResult{v_20036814, v_20036815} : ArenaResult<IR.Words>}

def constructor_field_types_view(v_20036816: ArenaStore, v_0: U32, v_2: String, v_3: U32, v_4: Scope.ArenaGlobalScope) -> ArenaResult<IR.Words>:
  ArenaResult{v_20036817, +v_20036818} = arena_get_node(v_20036816, v_0)
  match v_20036818:
    case Arena.TermAdt{+v_20036823, +v_20036825, +v_20036826, +v_20036828, +v_20036829, +v_20036831}:
      ArenaResult{v_20036832, +v_20036833} = arena_name_text(v_20036817, v_20036823)
      +v_20036824 = v_20036833
      +v_20036827 = IR.Words{v_20036825, v_20036826}
      v_10 = v_20036824
      v_11 = v_20036827
      v_13 = v_20036831
      ArenaResult{v_20036834, +v_20036835} = constructor_field_types_lookup(v_20036832, Scope.lookup_kind(v_2, Scope.GlobalConstructor{}, v_4), v_10, v_11, v_13, v_4)
      {ArenaResult{v_20036834, v_20036835} : ArenaResult<IR.Words>}
    case _:
      {ArenaResult{v_20036817, IR.Words{0, 0}} : ArenaResult<IR.Words>}

def constructor_field_types_for_type(v_20036837: ArenaStore, v_0: U32, v_2: String, v_3: Scope.ArenaGlobalScope) -> ArenaResult<IR.Words>:
  ArenaResult{v_20036838, +v_20036839} = whnf(v_20036837, 64n, v_0, v_3)
  ArenaResult{v_20036840, +v_20036841} = constructor_field_types_view(v_20036838, v_20036839, v_2, v_0, v_3)
  {ArenaResult{v_20036840, v_20036841} : ArenaResult<IR.Words>}

def matrix_covers_recursive_result(v_20036842: ArenaStore, v_1: Bool, v_4: IR.Names, v_5: U32, v_8: PatternRowIndex, v_10: IR.Words, v_11: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_1:
    case True{}:
      ArenaResult{v_20036843, +v_20036844} = matrix_covers_constructors(v_20036842, v_4, v_5, v_8, v_10, v_11)
      {ArenaResult{v_20036843, v_20036844} : ArenaResult<Bool>}
    case False{}:
      {ArenaResult{v_20036842, False{}} : ArenaResult<Bool>}

def matrix_covers_constructors(v_20036845: ArenaStore, v_2: IR.Names, v_3: U32, +v_6: PatternRowIndex, v_8: IR.Words, v_9: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20036846, +v_20036847} = arena_names_view(v_20036845, v_2)
  match v_20036847:
    case IR.NameNil{}:
      {ArenaResult{v_20036846, True{}} : ArenaResult<Bool>}
    case IR.NameCons{+v_20036848, +v_20036849}:
      +v_13 = v_20036848
      v_14 = v_20036849
      ArenaResult{v_20036850, +v_20036851} = constructor_field_types_for_type(v_20036846, v_3, v_13, v_9)
      v_17 = v_20036851
      v_19 = arena_words_length(v_17)
      ArenaResult{v_20036852, +v_20036853} = scope_specialize_pattern_rows(v_20036850, v_6, v_13, v_19, v_9)
      v_21 = v_20036853
      +v_20036856 = List.is_empty(&2, IR.Words, v_21)
      match v_20036856:
        case False{}:
          ArenaResult{v_20036857, +v_20036858} = arena_words_append(v_20036852, v_17, v_8)
          ArenaResult{v_20036859, +v_20036860} = matrix_covers(v_20036857, v_20036858, v_21, v_9)
          ArenaResult{v_20036861, +v_20036862} = matrix_covers_recursive_result(v_20036859, v_20036860, v_14, v_3, v_6, v_8, v_9)
          +v_20036854 = v_20036862
          v_20036855 = v_20036861
          {ArenaResult{v_20036855, v_20036854} : ArenaResult<Bool>}
        case True{}:
          +v_20036854 = False{}
          v_20036855 = v_20036852
          {ArenaResult{v_20036855, v_20036854} : ArenaResult<Bool>}

def matrix_variable_column(v_20036863: ArenaStore, v_2: List<&2, IR.Words>) -> ArenaResult<Bool>:
  match v_2:
    case []:
      {ArenaResult{v_20036863, True{}} : ArenaResult<Bool>}
    case +v_20036866 <> +v_20036867:
      ArenaResult{v_20036868, +v_20036869} = arena_words_view(v_20036863, v_20036866)
      match v_20036869:
        case IR.WordCons{+v_20036872, +v_20036873}:
          ArenaResult{v_20036874, +v_20036875} = arena_get_pattern(v_20036868, v_20036872)
          match v_20036875:
            case Arena.PatternVar{+v_20036880, +v_20036882, +v_20036883, +v_20036884}:
              v_15 = v_20036867
              ArenaResult{v_20036885, +v_20036886} = matrix_variable_column(v_20036874, v_15)
              {ArenaResult{v_20036885, v_20036886} : ArenaResult<Bool>}
            case _:
              {ArenaResult{v_20036874, False{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20036868, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20036863, False{}} : ArenaResult<Bool>}

def matrix_drop_column(v_20036890: ArenaStore, v_2: List<&2, IR.Words>) -> ArenaResult<List<&2, IR.Words>>:
  match v_2:
    case []:
      {ArenaResult{v_20036890, []} : ArenaResult<List<&2, IR.Words>>}
    case +v_20036891 <> +v_20036892:
      ArenaResult{v_20036893, +v_20036894} = arena_words_view(v_20036890, v_20036891)
      match v_20036894:
        case IR.WordCons{+v_20036895, +v_20036896}:
          v_9 = v_20036896
          v_10 = v_20036892
          ArenaResult{v_20036897, +v_20036898} = matrix_drop_column(v_20036893, v_10)
          {ArenaResult{v_20036897, v_9 <> v_20036898} : ArenaResult<List<&2, IR.Words>>}
        case IR.WordNil{}:
          v_13 = v_20036892
          ArenaResult{v_20036899, +v_20036900} = matrix_drop_column(v_20036893, v_13)
          {ArenaResult{v_20036899, IR.Words{0, 0} <> v_20036900} : ArenaResult<List<&2, IR.Words>>}

def matrix_covers_types(v_20036901: ArenaStore, v_1: IR.Words, +v_4: List<&2, IR.Words>, v_5: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20036902, +v_20036903} = arena_words_view(v_20036901, v_1)
  match v_20036903:
    case IR.WordNil{}:
      {ArenaResult{v_20036902, False{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20036904, +v_20036905}:
      v_9 = v_20036904
      v_10 = v_20036905
      ArenaResult{v_20036906, +v_20036907} = matrix_variable_column(v_20036902, v_4)
      match v_20036907:
        case True{}:
          ArenaResult{v_20036908, +v_20036909} = matrix_drop_column(v_20036906, v_4)
          ArenaResult{v_20036910, +v_20036911} = matrix_covers(v_20036908, v_10, v_20036909, v_5)
          {ArenaResult{v_20036910, v_20036911} : ArenaResult<Bool>}
        case False{}:
          ArenaResult{v_20036912, +v_20036913} = constructors_for_type(v_20036906, v_9, v_5)
          ArenaResult{indexed_store, row_index} = pattern_row_index_build(v_20036912, v_4)
          ArenaResult{v_20036914, +v_20036915} = matrix_covers_constructors(indexed_store, v_20036913, v_9, row_index, v_10, v_5)
          {ArenaResult{v_20036914, v_20036915} : ArenaResult<Bool>}

def empty_constructor_family(v_1: ArenaStore, v_3: Maybe<&2, Scope.ArenaGlobal>, v_5: String, v_6: IR.Names, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_3:
    case Some{+v_12}:
      match v_12:
        case Scope.ArenaGlobal{+v_19, +v_20, +v_21, +v_22, +v_23, +v_24}:
          match v_24:
            case Scope.GlobalFamily{}:
              ArenaResult{v_28, +v_29} = family_constructor_keys(v_1, v_7, v_5, v_6)
              v_50000173 = arena_names_is_empty(v_29)
              {ArenaResult{v_28, v_50000173} : ArenaResult<Bool>}
            case _:
              {ArenaResult{v_1, False{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_1, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_1, False{}} : ArenaResult<Bool>}

def empty_constructor_type_view(v_20036936: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20036937, +v_20036938} = arena_get_node(v_20036936, v_0)
  match v_20036938:
    case Arena.TermAdt{+v_20036943, +v_20036945, +v_20036946, +v_20036948, +v_20036949, +v_20036951}:
      ArenaResult{v_20036952, +v_20036953} = arena_name_text(v_20036937, v_20036943)
      +v_20036944 = v_20036953
      +v_20036950 = IR.Names{v_20036948, v_20036949}
      v_7 = v_20036944
      v_9 = v_20036950
      v_12 = Scope.canonical_name(v_7, v_1)
      ArenaResult{v_20036954, +v_20036955} = empty_constructor_family(v_20036952, Scope.lookup_kind(v_12, Scope.GlobalFamily{}, v_1), v_12, v_9, v_1)
      {ArenaResult{v_20036954, v_20036955} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20036937, False{}} : ArenaResult<Bool>}

def matrix_empty_rows(v_20036957: ArenaStore, v_1: IR.Words, v_2: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20036958, +v_20036959} = arena_words_view(v_20036957, v_1)
  match v_20036959:
    case IR.WordNil{}:
      {ArenaResult{v_20036958, False{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20036960, +v_20036961}:
      +v_6 = v_20036960
      v_7 = v_20036961
      ArenaResult{v_20036962, +v_20036963} = whnf(v_20036958, 64n, v_6, v_2)
      ArenaResult{v_20036964, +v_20036965} = empty_constructor_type_view(v_20036962, v_20036963, v_2)
      match v_20036965:
        case True{}:
          {ArenaResult{v_20036964, True{}} : ArenaResult<Bool>}
        case False{}:
          ArenaResult{v_20036966, +v_20036967} = matrix_empty_rows(v_20036964, v_7, v_2)
          {ArenaResult{v_20036966, v_20036967} : ArenaResult<Bool>}

def matrix_covers(v_20036968: ArenaStore, v_1: IR.Words, v_4: List<&2, IR.Words>, v_5: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_4:
    case +v_20036969 <> +v_20036970:
      +v_9 = v_20036969
      ArenaResult{v_20036973, +v_20036974} = all_variable_patterns(v_20036968, v_9)
      +v_20036975 = v_20036974
      match v_20036975:
        case False{}:
          ArenaResult{v_20036976, +v_20036977} = matrix_covers_types(v_20036973, v_1, v_4, v_5)
          +v_20036971 = v_20036977
          v_20036972 = v_20036976
          {ArenaResult{v_20036972, v_20036971} : ArenaResult<Bool>}
        case True{}:
          +v_20036971 = True{}
          v_20036972 = v_20036973
          {ArenaResult{v_20036972, v_20036971} : ArenaResult<Bool>}
    case []:
      ArenaResult{v_20036978, +v_20036979} = matrix_empty_rows(v_20036968, v_1, v_5)
      {ArenaResult{v_20036978, v_20036979} : ArenaResult<Bool>}

def all_variable_patterns(v_20036980: ArenaStore, v_1: IR.Words) -> ArenaResult<Bool>:
  ArenaResult{v_20036981, +v_20036982} = arena_words_view(v_20036980, v_1)
  match v_20036982:
    case IR.WordNil{}:
      {ArenaResult{v_20036981, True{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20036983, +v_20036984}:
      +v_5 = v_20036983
      v_6 = v_20036984
      ArenaResult{v_20036985, +v_20036986} = arena_get_pattern(v_20036981, v_5)
      match v_20036986:
        case Arena.PatternVar{+v_20036991, +v_20036993, +v_20036994, +v_20036995}:
          ArenaResult{v_20036996, +v_20036997} = all_variable_patterns(v_20036985, v_6)
          {ArenaResult{v_20036996, v_20036997} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20036985, False{}} : ArenaResult<Bool>}

def matrix_pattern_covered_constructors(v_20036999: ArenaStore, v_2: IR.Names, v_3: U32, v_5: IR.Words, +v_8: PatternRowIndex, v_10: IR.Words, v_11: Ast.SourceSpan, v_12: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20037000, +v_20037001} = arena_names_view(v_20036999, v_2)
  match v_20037001:
    case IR.NameNil{}:
      {ArenaResult{v_20037000, True{}} : ArenaResult<Bool>}
    case IR.NameCons{+v_20037002, +v_20037003}:
      +v_16 = v_20037002
      v_17 = v_20037003
      ArenaResult{v_20037004, +v_20037005} = constructor_field_types_for_type(v_20037000, v_3, v_16, v_12)
      v_20 = v_20037005
      v_22 = arena_words_length(v_20)
      ArenaResult{v_20037006, +v_20037007} = scope_specialize_pattern_rows(v_20037004, v_8, v_16, v_22, v_12)
      v_24 = v_20037007
      ArenaResult{v_20037008, +v_20037009} = scope_wildcard_patterns(v_20037006, v_22, v_11)
      ArenaResult{v_20037010, +v_20037011} = arena_words_append(v_20037008, v_20037009, v_10)
      v_26 = v_20037011
      ArenaResult{v_20037012, +v_20037013} = arena_words_append(v_20037010, v_20, v_5)
      ArenaResult{v_20037014, +v_20037015} = matrix_pattern_covered(v_20037012, v_20037013, v_24, v_26, v_12)
      match v_20037015:
        case True{}:
          ArenaResult{v_20037016, +v_20037017} = matrix_pattern_covered_constructors(v_20037014, v_17, v_3, v_5, v_8, v_10, v_11, v_12)
          {ArenaResult{v_20037016, v_20037017} : ArenaResult<Bool>}
        case False{}:
          {ArenaResult{v_20037014, False{}} : ArenaResult<Bool>}

def matrix_pattern_covered_variable(v_1: ArenaStore, v_3: U32, v_4: IR.Words, +v_6: PatternRowIndex, v_7: IR.Words, v_8: Ast.SourceSpan, v_9: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_16, +v_17} = matrix_variable_column(v_1, pattern_row_index_rows(v_6))
  match v_17:
    case True{}:
      ArenaResult{v_21, +v_22} = matrix_drop_column(v_16, pattern_row_index_rows(v_6))
      ArenaResult{v_26, +v_27} = matrix_pattern_covered(v_21, v_4, v_22, v_7, v_9)
      {ArenaResult{v_26, v_27} : ArenaResult<Bool>}
    case False{}:
      ArenaResult{v_31, +v_32} = constructors_for_type(v_16, v_3, v_9)
      v_34 = v_32
      ArenaResult{v_38, +v_39} = matrix_pattern_covered_constructors(v_31, v_34, v_3, v_4, v_6, v_7, v_8, v_9)
      v_50000174 = Bool.and(Bool.not(arena_names_is_empty(v_34)), v_39)
      {ArenaResult{v_38, v_50000174} : ArenaResult<Bool>}

def matrix_pattern_covered(store: ArenaStore, types: IR.Words, rows: List<&2, IR.Words>, target: IR.Words, scope: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store1, index} = pattern_row_index_build(store, rows)
  matrix_pattern_covered_indexed(store1, types, index, target, scope)

def matrix_pattern_covered_indexed(v_20037029: ArenaStore, v_1: IR.Words, +v_4: PatternRowIndex, v_6: IR.Words, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  rows = pattern_row_index_rows(v_4)
  match rows:
    case []:
      {ArenaResult{v_20037029, False{}} : ArenaResult<Bool>}
    case +v_20037030 <> +v_20037031:
      ArenaResult{v_20037032, +v_20037033} = arena_words_view(v_20037029, v_1)
      match v_20037033:
        case IR.WordNil{}:
          ArenaResult{v_20037034, +v_20037035} = arena_words_view(v_20037032, v_6)
          match v_20037035:
            case IR.WordNil{}:
              {ArenaResult{v_20037034, True{}} : ArenaResult<Bool>}
            case _:
              {ArenaResult{v_20037034, False{}} : ArenaResult<Bool>}
        case IR.WordCons{+v_20037039, +v_20037040}:
          ArenaResult{v_20037041, +v_20037042} = arena_words_view(v_20037032, v_6)
          match v_20037042:
            case IR.WordCons{+v_20037045, +v_20037046}:
              ArenaResult{v_20037047, +v_20037048} = arena_get_pattern(v_20037041, v_20037045)
              match v_20037048:
                case Arena.PatternVar{+v_20037053, +v_20037055, +v_20037056, +v_20037057}:
                  v_25 = v_20037057
                  v_26 = v_20037046
                  +v_20 = v_20037039
                  v_21 = v_20037040
                  ArenaResult{v_20037058, +v_20037059} = matrix_pattern_covered_variable(v_20037047, v_20, v_21, v_4, v_26, v_25, v_7)
                  {ArenaResult{v_20037058, v_20037059} : ArenaResult<Bool>}
                case Arena.PatternCtr{+v_20037063, +v_20037065, +v_20037066, +v_20037068}:
                  ArenaResult{v_20037069, +v_20037070} = arena_name_text(v_20037047, v_20037063)
                  +v_20037064 = v_20037070
                  +v_20037067 = IR.Words{v_20037065, v_20037066}
                  v_36 = v_20037064
                  v_37 = v_20037067
                  v_39 = v_20037046
                  +v_34 = v_20037039
                  v_35 = v_20037040
                  ArenaResult{v_20037071, +v_20037072} = constructor_field_types_for_type(v_20037069, v_34, v_36, v_7)
                  v_42 = v_20037072
                  ArenaResult{v_20037073, +v_20037074} = scope_specialize_pattern_rows(v_20037071, v_4, Scope.canonical_name(v_36, v_7), arena_words_length(v_42), v_7)
                  v_44 = v_20037074
                  ArenaResult{v_20037075, +v_20037076} = arena_words_append(v_20037073, v_42, v_35)
                  ArenaResult{v_20037077, +v_20037078} = arena_words_append(v_20037075, v_37, v_39)
                  ArenaResult{v_20037079, +v_20037080} = matrix_pattern_covered(v_20037077, v_20037076, v_44, v_20037078, v_7)
                  {ArenaResult{v_20037079, v_20037080} : ArenaResult<Bool>}
                case _:
                  {ArenaResult{v_20037047, False{}} : ArenaResult<Bool>}
            case _:
              {ArenaResult{v_20037041, False{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20037032, False{}} : ArenaResult<Bool>}

def pattern_row_covered(v_20037084: ArenaStore, v_1: IR.Words, +v_4: PatternRowIndex, v_6: IR.Words, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20037085, +v_20037086} = scope_pattern_rows_subsume(v_20037084, v_4, v_6, v_7)
  match v_20037086:
    case True{}:
      {ArenaResult{v_20037085, True{}} : ArenaResult<Bool>}
    case False{}:
      ArenaResult{v_20037087, +v_20037088} = matrix_pattern_covered_indexed(v_20037085, v_1, v_4, v_6, v_7)
      {ArenaResult{v_20037087, v_20037088} : ArenaResult<Bool>}

def check_pattern_fields_empty_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_8: List<&2, Binding>, v_9: Ast.SourceSpan) -> ArenaResult<PatternFields>:
  ArenaResult{v_16, +v_17} = arena_get_node(v_1, v_3)
  match v_17:
    case Arena.TermAll{+v_24, +v_25, +v_26, +v_27, +v_28, +v_29}:
      v_50000175 = span_file(v_9)
      v_50000176 = Diagnostic{v_50000175, v_9, "constructor pattern omits fields", "one pattern per constructor field", "too few field patterns"}
      v_50000177 = PatternFieldsFailure{v_50000176}
      {ArenaResult{v_16, v_50000177} : ArenaResult<PatternFields>}
    case _:
      {ArenaResult{v_16, PatternFieldsTyped{v_8, IR.Words{0, 0}, v_5}} : ArenaResult<PatternFields>}

def check_pattern_fields_recursive_result(v_20037106: ArenaStore, v_1: PatternFields, v_3: IR.Words, v_4: U32) -> ArenaResult<PatternFields>:
  match v_1:
    case PatternFieldsFailure{+v_20037107}:
      v_7 = v_20037107
      {ArenaResult{v_20037106, PatternFieldsFailure{v_7}} : ArenaResult<PatternFields>}
    case PatternFieldsTyped{+v_20037108, +v_20037109, +v_20037110}:
      v_10 = v_20037108
      v_11 = v_20037109
      v_12 = v_20037110
      ArenaResult{v_20037111, +v_20037112} = core_pattern_list_depth(v_20037106, v_3)
      ArenaResult{v_20037113, +v_20037114} = core_shift(v_20037111, 0n, v_20037112, v_4)
      ArenaResult{v_20037115, +v_20037116} = arena_words_cons(v_20037113, v_20037114, v_11)
      {ArenaResult{v_20037115, PatternFieldsTyped{v_10, v_20037116, v_12}} : ArenaResult<PatternFields>}

def check_pattern_fields_typed_result(v_20037117: ArenaStore, v_1: PatternTyping, v_3: IR.Words, v_4: U32, v_6: Nat, v_7: Ast.Quantity, v_10: List<&2, Binding>, v_11: Scope.ArenaGlobalScope, v_12: Ast.SourceSpan) -> ArenaResult<PatternFields>:
  match v_1:
    case PatternTypeFailure{+v_20037118}:
      v_15 = v_20037118
      {ArenaResult{v_20037117, PatternFieldsFailure{v_15}} : ArenaResult<PatternFields>}
    case PatternTyped{+v_20037119, +v_20037120}:
      v_18 = v_20037119
      v_19 = v_20037120
      v_23 = Nat.sub(List.length(&2, Binding, v_18), List.length(&2, Binding, v_10))
      ArenaResult{v_20037121, +v_20037122} = core_shift(v_20037117, 1n, v_23, v_4)
      ArenaResult{v_20037123, +v_20037124} = core_subst(v_20037121, 0n, v_19, v_20037122)
      v_25 = v_20037124
      ArenaResult{v_20037125, +v_20037126} = check_pattern_typed_fields(v_20037123, v_3, v_25, v_6, v_7, v_18, v_11, v_12)
      ArenaResult{v_20037127, +v_20037128} = check_pattern_fields_recursive_result(v_20037125, v_20037126, v_3, v_19)
      {ArenaResult{v_20037127, v_20037128} : ArenaResult<PatternFields>}

def check_pattern_fields_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: IR.Words, v_8: Nat, v_9: Ast.Quantity, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope, v_14: Ast.SourceSpan) -> ArenaResult<PatternFields>:
  ArenaResult{v_21, +v_22} = arena_get_node(v_1, v_3)
  match v_22:
    case Arena.TermAll{+v_29, +v_30, +v_31, +v_32, +v_33, +v_34}:
      v_36 = v_29
      v_38 = v_32
      v_40 = v_33
      ArenaResult{v_44, +v_45} = core_pattern_depth(v_21, v_5)
      v_48 = Nat.add(List.length(&2, Binding, v_12), v_45)
      v_51 = constructor_field_demand(v_9, v_36)
      ArenaResult{v_55, +v_56} = check_pattern_typed(v_44, v_5, v_38, Some{v_51}, v_48, v_12, v_13)
      ArenaResult{v_60, +v_61} = check_pattern_fields_typed_result(v_55, v_56, v_6, v_40, v_8, v_9, v_12, v_13, v_14)
      {ArenaResult{v_60, v_61} : ArenaResult<PatternFields>}
    case _:
      v_50000178 = span_file(v_14)
      v_50000179 = Diagnostic{v_50000178, v_14, "constructor pattern has too many fields", "a remaining constructor field", "an extra field pattern"}
      v_50000180 = PatternFieldsFailure{v_50000179}
      {ArenaResult{v_21, v_50000180} : ArenaResult<PatternFields>}

def check_pattern_typed_fields(v_20037152: ArenaStore, v_1: IR.Words, v_2: U32, v_4: Nat, v_5: Ast.Quantity, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope, v_10: Ast.SourceSpan) -> ArenaResult<PatternFields>:
  ArenaResult{v_20037153, +v_20037154} = arena_words_view(v_20037152, v_1)
  match v_20037154:
    case IR.WordNil{}:
      ArenaResult{v_20037155, +v_20037156} = whnf(v_20037153, 64n, v_2, v_9)
      ArenaResult{v_20037157, +v_20037158} = check_pattern_fields_empty_view(v_20037155, v_20037156, v_2, v_8, v_10)
      {ArenaResult{v_20037157, v_20037158} : ArenaResult<PatternFields>}
    case IR.WordCons{+v_20037159, +v_20037160}:
      +v_16 = v_20037159
      v_17 = v_20037160
      ArenaResult{v_20037161, +v_20037162} = whnf(v_20037153, 64n, v_2, v_9)
      ArenaResult{v_20037163, +v_20037164} = check_pattern_fields_view(v_20037161, v_20037162, v_16, v_17, v_4, v_5, v_8, v_9, v_10)
      {ArenaResult{v_20037163, v_20037164} : ArenaResult<PatternFields>}

def binding_quantity_result(v_2: Maybe<&2, Binding>) -> Ast.Quantity:
  match v_2:
    case Some{+v_20037165}:
      v_4 = v_20037165
      match v_4:
        case Binding{+v_20037166, +v_20037167, +v_20037168, +v_20037169}:
          v_10 = v_20037167
          v_10
    case None{}:
      Ast.QOne{}

def binding_quantity_or_one(v_1: Nat, v_4: List<&2, Binding>) -> Ast.Quantity:
  binding_quantity_result(lookup_binding(v_1, v_4))

def maybe_quantity_or_one(v_1: Maybe<&2, Ast.Quantity>) -> Ast.Quantity:
  match v_1:
    case Some{+v_20037170}:
      v_3 = v_20037170
      v_3
    case None{}:
      Ast.QOne{}

def check_pattern_variable_result(v_1: ArenaStore, v_3: Bool, v_5: U32, v_7: String, v_8: Ast.Quantity, v_10: U32, v_12: Nat, v_15: List<&2, Binding>, v_16: Ast.SourceSpan) -> ArenaResult<PatternTyping>:
  +v_21 = v_3
  match v_21:
    case False{}:
      v_50000181 = span_file(v_16)
      v_50000182 = Diagnostic{v_50000181, v_16, "pattern quantity exceeds constructor field quantity", "within the field quantity", "an excessive pattern quantity"}
      +v_24 = PatternTypeFailure{v_50000182}
      v_26 = v_1
      {ArenaResult{v_26, v_24} : ArenaResult<PatternTyping>}
    case True{}:
      ArenaResult{v_31, +v_32} = pattern_value(v_1, v_5, v_12)
      +v_35 = PatternTyped{Binding{v_7, v_8, v_10, List.length(&2, Binding, v_15)} <> v_15, v_32}
      v_37 = v_31
      {ArenaResult{v_37, v_35} : ArenaResult<PatternTyping>}

def pattern_quantity_valid(v_1: ArenaStore, v_2: Ast.Quantity, v_3: Ast.Quantity, v_5: U32, v_6: Ast.SourceSpan, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_2:
    case Ast.QZero{}:
      {ArenaResult{v_1, True{}} : ArenaResult<Bool>}
    case Ast.QOne{}:
      match v_3:
        case Ast.QMany{}:
          ArenaResult{v_17, +v_18} = promotion_domain_valid(v_1, v_5, v_6, v_9, v_10)
          {ArenaResult{v_17, v_18} : ArenaResult<Bool>}
        case _:
          v_50000183 = pattern_quantity_allowed(v_2, v_3)
          {ArenaResult{v_1, v_50000183} : ArenaResult<Bool>}
    case _:
      v_50000184 = pattern_quantity_allowed(v_2, v_3)
      {ArenaResult{v_1, v_50000184} : ArenaResult<Bool>}

def check_pattern_variable_field_quantity(v_20037182: ArenaStore, v_1: Maybe<&2, Ast.Quantity>, v_2: U32, v_4: String, v_5: Ast.Quantity, v_6: U32, v_8: Nat, v_11: List<&2, Binding>, v_12: Ast.SourceSpan, v_13: Scope.ArenaGlobalScope) -> ArenaResult<PatternTyping>:
  match v_1:
    case Some{+v_20037183}:
      v_16 = v_20037183
      v_19 = constructor_field_demand(v_16, v_5)
      ArenaResult{v_20037184, +v_20037185} = pattern_quantity_valid(v_20037182, v_16, v_5, v_6, v_12, v_11, v_13)
      ArenaResult{v_20037186, +v_20037187} = check_pattern_variable_result(v_20037184, v_20037185, v_2, v_4, v_19, v_6, v_8, v_11, v_12)
      {ArenaResult{v_20037186, v_20037187} : ArenaResult<PatternTyping>}
    case None{}:
      ArenaResult{v_20037188, +v_20037189} = pattern_value(v_20037182, v_2, v_8)
      {ArenaResult{v_20037188, PatternTyped{Binding{v_4, v_5, v_6, List.length(&2, Binding, v_11)} <> v_11, v_20037189}} : ArenaResult<PatternTyping>}

def pattern_result_fits_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_13, +v_14} = arena_get_node(v_1, v_3)
  match v_14:
    case Arena.TermAdt{+v_21, +v_22, +v_23, +v_24, +v_25, +v_26}:
      ArenaResult{v_30, +v_31} = arena_name_text(v_13, v_21)
      +v_33 = v_31
      +v_35 = IR.Words{v_22, v_23}
      ArenaResult{v_39, +v_40} = arena_get_node(v_30, v_5)
      match v_40:
        case Arena.TermAdt{+v_47, +v_48, +v_49, +v_50, +v_51, +v_52}:
          ArenaResult{v_56, +v_57} = arena_name_text(v_39, v_47)
          +v_59 = v_57
          +v_61 = IR.Words{v_48, v_49}
          v_63 = v_59
          v_65 = v_61
          v_67 = v_33
          v_69 = v_35
          ArenaResult{v_73, +v_74} = equal_lists(v_56, v_69, v_65, v_6)
          v_50000185 = Bool.and(Scope.equal_names(v_67, v_63, v_6), v_74)
          {ArenaResult{v_73, v_50000185} : ArenaResult<Bool>}
        case _:
          ArenaResult{v_81, +v_82} = fits_term(v_39, v_3, v_5, v_6)
          {ArenaResult{v_81, v_82} : ArenaResult<Bool>}
    case _:
      ArenaResult{v_88, +v_89} = fits_term(v_13, v_3, v_5, v_6)
      {ArenaResult{v_88, v_89} : ArenaResult<Bool>}

def pattern_result_fits(v_20037233: ArenaStore, v_0: U32, v_1: U32, v_2: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20037234, +v_20037235} = whnf(v_20037233, 64n, v_1, v_2)
  ArenaResult{v_20037236, +v_20037237} = pattern_result_fits_view(v_20037234, v_0, v_20037235, v_2)
  {ArenaResult{v_20037236, v_20037237} : ArenaResult<Bool>}

def check_pattern_result_view(v_1: ArenaStore, v_3: U32, v_5: String, v_6: IR.Words, v_9: List<&2, Binding>, v_11: U32, v_12: Ast.SourceSpan, v_13: Scope.ArenaGlobalScope) -> ArenaResult<PatternTyping>:
  ArenaResult{v_20, +v_21} = arena_get_node(v_1, v_3)
  match v_21:
    case Arena.TermAll{+v_28, +v_29, +v_30, +v_31, +v_32, +v_33}:
      v_50000186 = span_file(v_12)
      v_50000187 = Diagnostic{v_50000186, v_12, "constructor pattern omits fields", "one pattern per constructor field", "too few field patterns"}
      v_50000188 = PatternTypeFailure{v_50000187}
      {ArenaResult{v_20, v_50000188} : ArenaResult<PatternTyping>}
    case _:
      ArenaResult{v_40, +v_41} = pattern_result_fits(v_20, v_3, v_11, v_13)
      +v_43 = v_41
      match v_43:
        case False{}:
          v_50000189 = span_file(v_12)
          v_50000190 = Diagnostic{v_50000189, v_12, "constructor parameters do not match scrutinee", "the scrutinee datatype instance", "different parameters"}
          +v_46 = PatternTypeFailure{v_50000190}
          v_48 = v_40
          {ArenaResult{v_48, v_46} : ArenaResult<PatternTyping>}
        case True{}:
          ArenaResult{v_54, +v_55} = arena_name(v_40, Scope.canonical_name(v_5, v_13))
          v_50000191 = arena_words_start(v_6)
          v_50000192 = arena_words_count(v_6)
          ArenaResult{v_61, +v_62} = arena_put_node(v_54, Arena.TermCtr{v_55, v_50000191, v_50000192, v_12})
          +v_64 = PatternTyped{v_9, v_62}
          v_66 = v_61
          {ArenaResult{v_66, v_64} : ArenaResult<PatternTyping>}

def check_pattern_fields_result(v_20037264: ArenaStore, v_1: PatternFields, v_3: String, v_4: U32, v_5: Ast.SourceSpan, v_6: Scope.ArenaGlobalScope) -> ArenaResult<PatternTyping>:
  match v_1:
    case PatternFieldsFailure{+v_20037265}:
      v_9 = v_20037265
      {ArenaResult{v_20037264, PatternTypeFailure{v_9}} : ArenaResult<PatternTyping>}
    case PatternFieldsTyped{+v_20037266, +v_20037267, +v_20037268}:
      v_12 = v_20037266
      v_13 = v_20037267
      v_14 = v_20037268
      ArenaResult{v_20037269, +v_20037270} = whnf(v_20037264, 64n, v_14, v_6)
      ArenaResult{v_20037271, +v_20037272} = check_pattern_result_view(v_20037269, v_20037270, v_3, v_13, v_12, v_4, v_5, v_6)
      {ArenaResult{v_20037271, v_20037272} : ArenaResult<PatternTyping>}

def check_pattern_applied_result(v_1: ArenaStore, v_4: Maybe<&2, U32>, v_5: IR.Words, v_7: Maybe<&2, Ast.Quantity>, v_9: String, v_11: U32, v_13: Nat, v_16: List<&2, Binding>, v_17: Ast.SourceSpan, v_18: Scope.ArenaGlobalScope) -> ArenaResult<PatternTyping>:
  match v_4:
    case None{}:
      v_50000193 = span_file(v_17)
      v_50000194 = Diagnostic{v_50000193, v_17, "constructor parameters do not match datatype", "matching family parameters", "an incompatible constructor"}
      v_50000195 = PatternTypeFailure{v_50000194}
      {ArenaResult{v_1, v_50000195} : ArenaResult<PatternTyping>}
    case Some{+v_24}:
      v_26 = v_24
      ArenaResult{v_30, +v_31} = core_pattern_list_depth(v_1, v_5)
      ArenaResult{v_35, +v_36} = core_shift(v_30, 0n, v_31, v_11)
      v_38 = v_36
      ArenaResult{v_43, +v_44} = check_pattern_typed_fields(v_35, v_5, v_26, v_13, maybe_quantity_or_one(v_7), v_16, v_18, v_17)
      ArenaResult{v_48, +v_49} = check_pattern_fields_result(v_43, v_44, v_9, v_38, v_17, v_18)
      {ArenaResult{v_48, v_49} : ArenaResult<PatternTyping>}

def check_pattern_family_result(v_1: ArenaStore, v_4: Maybe<&2, String>, v_6: String, v_7: IR.Words, v_9: U32, v_10: IR.Words, v_12: Maybe<&2, Ast.Quantity>, v_14: String, v_16: U32, v_18: Nat, v_21: List<&2, Binding>, v_22: Ast.SourceSpan, v_23: Scope.ArenaGlobalScope) -> ArenaResult<PatternTyping>:
  match v_4:
    case None{}:
      v_50000196 = span_file(v_22)
      v_50000197 = Diagnostic{v_50000196, v_22, "match pattern is not a constructor", "a datatype constructor", v_14}
      v_50000198 = PatternTypeFailure{v_50000197}
      {ArenaResult{v_1, v_50000198} : ArenaResult<PatternTyping>}
    case Some{+v_29}:
      v_31 = v_29
      +v_34 = Scope.equal_names(v_31, v_6, v_23)
      match v_34:
        case False{}:
          v_50000199 = span_file(v_22)
          v_50000200 = Diagnostic{v_50000199, v_22, "match constructor belongs to another datatype", v_6, v_31}
          +v_37 = PatternTypeFailure{v_50000200}
          v_39 = v_1
          {ArenaResult{v_39, v_37} : ArenaResult<PatternTyping>}
        case True{}:
          ArenaResult{v_44, +v_45} = apply_prefix(v_1, v_7, v_9)
          ArenaResult{v_49, +v_50} = check_pattern_applied_result(v_44, v_45, v_10, v_12, v_14, v_16, v_18, v_21, v_22, v_23)
          +v_52 = v_50
          v_54 = v_49
          {ArenaResult{v_54, v_52} : ArenaResult<PatternTyping>}

def check_pattern_global(v_20037292: ArenaStore, v_0: Scope.ArenaGlobal, v_2: String, v_4: IR.Words, v_6: IR.Words, v_8: Maybe<&2, Ast.Quantity>, v_10: String, v_11: U32, v_13: Nat, v_16: List<&2, Binding>, v_17: Ast.SourceSpan, v_18: Scope.ArenaGlobalScope) -> ArenaResult<PatternTyping>:
  match v_0:
    case Scope.ArenaGlobal{+v_20037293, +v_20037294, +v_20037295, +v_20037296, +v_20037297, +v_20037298}:
      v_29 = v_20037296
      ArenaResult{v_20037299, +v_20037300} = constructor_family(v_20037292, v_29, v_18)
      ArenaResult{v_20037301, +v_20037302} = check_pattern_family_result(v_20037299, v_20037300, v_2, v_4, v_29, v_6, v_8, v_10, v_11, v_13, v_16, v_17, v_18)
      {ArenaResult{v_20037301, v_20037302} : ArenaResult<PatternTyping>}

def check_pattern_global_result(v_1: ArenaStore, v_3: Maybe<&2, Scope.ArenaGlobal>, v_5: String, v_6: IR.Words, v_7: IR.Words, v_9: Maybe<&2, Ast.Quantity>, v_11: String, v_13: U32, v_15: Nat, v_18: List<&2, Binding>, v_19: Ast.SourceSpan, v_20: Scope.ArenaGlobalScope) -> ArenaResult<PatternTyping>:
  match v_3:
    case None{}:
      v_50000201 = span_file(v_19)
      v_50000202 = Diagnostic{v_50000201, v_19, String.append("unknown constructor ", v_11), "a declared constructor", v_11}
      v_50000203 = PatternTypeFailure{v_50000202}
      {ArenaResult{v_1, v_50000203} : ArenaResult<PatternTyping>}
    case Some{+v_26}:
      v_28 = v_26
      ArenaResult{v_32, +v_33} = check_pattern_global(v_1, v_28, v_5, v_6, v_7, v_9, v_11, v_13, v_15, v_18, v_19, v_20)
      {ArenaResult{v_32, v_33} : ArenaResult<PatternTyping>}

def check_pattern_exclusion_result(v_1: ArenaStore, v_3: Bool, v_5: String, v_6: IR.Names, v_8: String, v_9: IR.Words, v_10: IR.Words, v_12: Maybe<&2, Ast.Quantity>, v_14: U32, v_16: Nat, v_19: List<&2, Binding>, v_20: Ast.SourceSpan, v_21: Scope.ArenaGlobalScope) -> ArenaResult<PatternTyping>:
  +v_26 = v_3
  match v_26:
    case False{}:
      ArenaResult{v_31, +v_32} = check_pattern_global_result(v_1, Scope.lookup_kind(v_5, Scope.GlobalConstructor{}, v_21), v_8, v_9, v_10, v_12, v_5, v_14, v_16, v_19, v_20, v_21)
      +v_34 = v_32
      v_36 = v_31
      {ArenaResult{v_36, v_34} : ArenaResult<PatternTyping>}
    case True{}:
      v_50000204 = span_file(v_20)
      v_50000205 = Diagnostic{v_50000204, v_20, "constructor is excluded from this datatype goal", "a remaining constructor", v_5}
      +v_40 = PatternTypeFailure{v_50000205}
      v_42 = v_1
      {ArenaResult{v_42, v_40} : ArenaResult<PatternTyping>}

def check_pattern_typed_view(v_1: ArenaStore, v_3: U32, v_4: IR.Words, v_6: Maybe<&2, Ast.Quantity>, v_8: String, v_10: U32, v_12: Nat, v_15: List<&2, Binding>, v_16: Ast.SourceSpan, v_17: Scope.ArenaGlobalScope) -> ArenaResult<PatternTyping>:
  ArenaResult{v_24, +v_25} = arena_get_node(v_1, v_3)
  match v_25:
    case Arena.TermAdt{+v_32, +v_33, +v_34, +v_35, +v_36, +v_37}:
      ArenaResult{v_41, +v_42} = arena_name_text(v_24, v_32)
      +v_44 = v_42
      +v_46 = IR.Words{v_33, v_34}
      +v_48 = IR.Names{v_35, v_36}
      v_50 = v_44
      v_52 = v_46
      v_54 = v_48
      ArenaResult{v_58, +v_59} = has_canonical_name(v_41, v_8, v_54, v_17)
      ArenaResult{v_63, +v_64} = check_pattern_exclusion_result(v_58, v_59, v_8, v_54, v_50, v_52, v_4, v_6, v_10, v_12, v_15, v_16, v_17)
      {ArenaResult{v_63, v_64} : ArenaResult<PatternTyping>}
    case _:
      v_50000206 = span_file(v_16)
      v_50000207 = Diagnostic{v_50000206, v_16, "match scrutinee is not a datatype", "a datatype", "a non-datatype"}
      v_50000208 = PatternTypeFailure{v_50000207}
      {ArenaResult{v_24, v_50000208} : ArenaResult<PatternTyping>}

def check_pattern_typed(v_20037336: ArenaStore, v_0: U32, v_1: U32, v_3: Maybe<&2, Ast.Quantity>, v_5: Nat, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope) -> ArenaResult<PatternTyping>:
  ArenaResult{v_20037337, +v_20037338} = arena_get_pattern(v_20037336, v_0)
  match v_20037338:
    case Arena.PatternVar{+v_20037339, +v_20037341, +v_20037342, +v_20037343}:
      ArenaResult{v_20037344, +v_20037345} = arena_name_text(v_20037337, v_20037339)
      +v_20037340 = v_20037345
      v_15 = v_20037340
      v_17 = v_20037342
      v_18 = v_20037343
      ArenaResult{v_20037346, +v_20037347} = check_pattern_variable_field_quantity(v_20037344, v_3, v_0, v_15, v_17, v_1, v_5, v_8, v_18, v_9)
      {ArenaResult{v_20037346, v_20037347} : ArenaResult<PatternTyping>}
    case Arena.PatternCtr{+v_20037348, +v_20037350, +v_20037351, +v_20037353}:
      ArenaResult{v_20037354, +v_20037355} = arena_name_text(v_20037337, v_20037348)
      +v_20037349 = v_20037355
      +v_20037352 = IR.Words{v_20037350, v_20037351}
      v_23 = v_20037349
      v_24 = v_20037352
      v_25 = v_20037353
      ArenaResult{v_20037356, +v_20037357} = whnf(v_20037354, 64n, v_1, v_9)
      ArenaResult{v_20037358, +v_20037359} = check_pattern_typed_view(v_20037356, v_20037357, v_24, v_3, v_23, v_1, v_5, v_8, v_25, v_9)
      {ArenaResult{v_20037358, v_20037359} : ArenaResult<PatternTyping>}

def pattern_source_span(v_20037360: ArenaStore, v_0: U32) -> ArenaResult<Ast.SourceSpan>:
  ArenaResult{v_20037361, +v_20037362} = arena_get_pattern(v_20037360, v_0)
  match v_20037362:
    case Arena.PatternVar{+v_20037363, +v_20037365, +v_20037366, +v_20037367}:
      v_8 = v_20037367
      {ArenaResult{v_20037361, v_8} : ArenaResult<Ast.SourceSpan>}
    case Arena.PatternCtr{+v_20037368, +v_20037370, +v_20037371, +v_20037373}:
      v_14 = v_20037373
      {ArenaResult{v_20037361, v_14} : ArenaResult<Ast.SourceSpan>}

def pattern_binding_usage_valid(v_2: Maybe<&2, Binding>, v_5: List<&2, UsageEntry>, v_7: Nat) -> Bool:
  match v_2:
    case Some{+v_20037374}:
      match v_20037374:
        case Binding{+v_20037375, +v_20037376, +v_20037377, +v_20037378}:
          v_14 = v_20037376
          quantity_fits(usage_get(v_7, v_5), v_14)
    case None{}:
      False{}

def pattern_usage_valid(v_1: ArenaStore, v_3: U32, v_6: List<&2, UsageEntry>, v_8: Nat, v_11: List<&2, Binding>) -> ArenaResult<Bool>:
  ArenaResult{v_18, +v_19} = arena_get_pattern(v_1, v_3)
  match v_19:
    case Arena.PatternVar{+v_24, +v_25, +v_26, +v_27}:
      v_29 = Nat.sub(v_8, 1n)
      v_50000209 = pattern_binding_usage_valid(lookup_binding(v_29, v_11), v_6, v_29)
      {ArenaResult{v_18, v_50000209} : ArenaResult<Bool>}
    case Arena.PatternCtr{+v_36, +v_37, +v_38, +v_39}:
      +v_41 = IR.Words{v_37, v_38}
      v_43 = v_41
      ArenaResult{v_47, +v_48} = pattern_usage_valid_list(v_18, v_43, v_6, v_8, v_11)
      {ArenaResult{v_47, v_48} : ArenaResult<Bool>}

def pattern_usage_valid_list(v_20037395: ArenaStore, v_1: IR.Words, v_4: List<&2, UsageEntry>, v_6: Nat, v_9: List<&2, Binding>) -> ArenaResult<Bool>:
  ArenaResult{v_20037396, +v_20037397} = arena_words_view(v_20037395, v_1)
  match v_20037397:
    case IR.WordNil{}:
      {ArenaResult{v_20037396, True{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20037398, +v_20037399}:
      +v_13 = v_20037398
      v_14 = v_20037399
      ArenaResult{v_20037402, +v_20037403} = pattern_usage_valid(v_20037396, v_13, v_4, v_6, v_9)
      +v_20037404 = v_20037403
      match v_20037404:
        case False{}:
          +v_20037400 = False{}
          v_20037401 = v_20037402
          {ArenaResult{v_20037401, v_20037400} : ArenaResult<Bool>}
        case True{}:
          ArenaResult{v_20037405, +v_20037406} = core_pattern_depth(v_20037402, v_13)
          ArenaResult{v_20037407, +v_20037408} = pattern_usage_valid_list(v_20037405, v_14, v_4, Nat.sub(v_6, v_20037406), v_9)
          +v_20037400 = v_20037408
          v_20037401 = v_20037407
          {ArenaResult{v_20037401, v_20037400} : ArenaResult<Bool>}

def maybe_shift_index(v_2: Maybe<&2, Nat>, v_4: Nat) -> Maybe<&2, Nat>:
  match v_2:
    case Some{+v_20037409}:
      v_8 = v_20037409
      Some{Nat.add(v_8, v_4)}
    case None{}:
      None{}

def match_branch_body(v_20037410: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_4: U32, v_6: Nat, v_8: Nat, v_9: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_20037411, +v_20037412} = arena_words_view(v_20037410, v_1)
  match v_20037412:
    case IR.WordCons{+v_20037415, +v_20037416}:
      ArenaResult{v_20037417, +v_20037418} = arena_words_view(v_20037411, v_3)
      match v_20037418:
        case IR.WordCons{+v_20037421, +v_20037422}:
          +v_16 = v_20037421
          v_17 = v_20037422
          +v_14 = v_20037415
          v_15 = v_20037416
          ArenaResult{v_20037423, +v_20037424} = scrutinee_variable_index(v_20037417, v_16, v_9)
          ArenaResult{v_20037425, +v_20037426} = match_branch_body_source(v_20037423, v_20037424, v_14, v_4, v_6, v_8)
          v_21 = v_20037426
          ArenaResult{v_20037427, +v_20037428} = match_branch_body(v_20037425, v_15, v_17, v_21, v_6, v_8, v_9)
          {ArenaResult{v_20037427, v_20037428} : ArenaResult<U32>}
        case _:
          {ArenaResult{v_20037417, v_4} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_20037411, v_4} : ArenaResult<U32>}

def match_branch_body_source(v_20037431: ArenaStore, v_2: Maybe<&2, Nat>, v_3: U32, v_4: U32, v_6: Nat, v_8: Nat) -> ArenaResult<U32>:
  match v_2:
    case Some{+v_20037432}:
      v_10 = v_20037432
      ArenaResult{v_20037433, +v_20037434} = pattern_value(v_20037431, v_3, v_8)
      ArenaResult{v_20037435, +v_20037436} = replace_free_term(v_20037433, v_4, Nat.add(v_10, v_6), v_20037434, 0n)
      {ArenaResult{v_20037435, v_20037436} : ArenaResult<U32>}
    case None{}:
      {ArenaResult{v_20037431, v_4} : ArenaResult<U32>}

def replace_match_types(v_20037437: ArenaStore, v_2: Maybe<&2, Nat>, v_4: Nat, v_6: IR.Words, v_7: U32) -> ArenaResult<IR.Words>:
  match v_2:
    case Some{+v_20037438}:
      v_10 = v_20037438
      ArenaResult{v_20037439, +v_20037440} = shift_terms(v_20037437, v_6, v_4)
      ArenaResult{v_20037441, +v_20037442} = replace_free_terms(v_20037439, v_20037440, Nat.add(v_10, v_4), v_7, 0n)
      {ArenaResult{v_20037441, v_20037442} : ArenaResult<IR.Words>}
    case None{}:
      ArenaResult{v_20037443, +v_20037444} = shift_terms(v_20037437, v_6, v_4)
      {ArenaResult{v_20037443, v_20037444} : ArenaResult<IR.Words>}

def check_body_pattern_vector_typed(v_20037445: ArenaStore, v_1: PatternTyping, v_3: IR.Words, v_5: Nat, v_7: IR.Words, v_9: IR.Words, v_11: IR.Words, v_12: U32, v_13: U32, v_14: Scope.ArenaGlobalScope, v_16: Nat, v_18: Nat, v_19: Ast.SourceSpan, v_22: Maybe<&2, Nat>, v_24: Nat) -> ArenaResult<Inference>:
  match v_1:
    case PatternTypeFailure{+v_20037446}:
      v_27 = v_20037446
      {ArenaResult{v_20037445, InferenceFailure{v_27}} : ArenaResult<Inference>}
    case PatternTyped{+v_20037447, +v_20037448}:
      v_30 = v_20037447
      v_31 = v_20037448
      v_34 = maybe_shift_index(v_22, v_18)
      ArenaResult{v_20037449, +v_20037450} = replace_match_expected(v_20037445, v_34, v_24, v_13, v_31)
      v_37 = v_20037450
      ArenaResult{v_20037451, +v_20037452} = replace_match_types(v_20037449, v_34, v_24, v_9, v_31)
      v_40 = v_20037452
      ArenaResult{v_20037453, +v_20037454} = refine_match_env(v_20037451, v_34, v_24, v_30, v_31)
      v_43 = v_20037454
      ArenaResult{v_20037455, +v_20037456} = check_body_pattern_vector(v_20037453, v_3, v_5, v_7, v_40, v_11, v_12, v_37, v_43, v_14, Nat.sub(v_16, v_24), Nat.add(v_18, v_24), v_19)
      {ArenaResult{v_20037455, v_20037456} : ArenaResult<Inference>}

def check_body_pattern_vector(v_1: ArenaStore, v_2: IR.Words, v_4: Nat, v_5: IR.Words, v_6: IR.Words, v_7: IR.Words, v_9: U32, v_11: U32, v_14: List<&2, Binding>, v_15: Scope.ArenaGlobalScope, v_17: Nat, v_19: Nat, v_20: Ast.SourceSpan) -> ArenaResult<Inference>:
  ArenaResult{v_27, +v_28} = arena_words_view(v_1, v_5)
  match v_28:
    case IR.WordNil{}:
      ArenaResult{v_32, +v_33} = arena_words_view(v_27, v_6)
      match v_33:
        case IR.WordNil{}:
          ArenaResult{v_37, +v_38} = arena_words_view(v_32, v_7)
          match v_38:
            case IR.WordNil{}:
              ArenaResult{v_42, +v_43} = binder_usage_map(v_37, v_4, v_9, v_14, v_15, Some{v_11}, False{})
              ArenaResult{v_47, +v_48} = pattern_usage_valid_list(v_42, v_2, v_43, v_4, v_14)
              +v_50 = v_48
              match v_50:
                case False{}:
                  +v_53 = fail(v_20, "invalid use quantity for pattern binder", "within the pattern binder quantity", "too many uses")
                  v_55 = v_47
                  {ArenaResult{v_55, v_53} : ArenaResult<Inference>}
                case True{}:
                  ArenaResult{v_60, +v_61} = check_term(v_47, v_9, v_14, v_15, v_11)
                  +v_63 = v_61
                  v_65 = v_60
                  {ArenaResult{v_65, v_63} : ArenaResult<Inference>}
            case _:
              v_50000210 = fail(v_20, "case pattern count differs from scrutinee count", "one pattern and type per scrutinee", "a mismatched pattern vector")
              {ArenaResult{v_37, v_50000210} : ArenaResult<Inference>}
        case _:
          v_50000211 = fail(v_20, "case pattern count differs from scrutinee count", "one pattern and type per scrutinee", "a mismatched pattern vector")
          {ArenaResult{v_32, v_50000211} : ArenaResult<Inference>}
    case IR.WordCons{+v_75, +v_76}:
      ArenaResult{v_80, +v_81} = arena_words_view(v_27, v_6)
      match v_81:
        case IR.WordCons{+v_84, +v_85}:
          ArenaResult{v_89, +v_90} = arena_words_view(v_80, v_7)
          match v_90:
            case IR.WordCons{+v_93, +v_94}:
              +v_96 = v_93
              v_98 = v_94
              +v_100 = v_84
              v_102 = v_85
              +v_104 = v_75
              v_106 = v_76
              ArenaResult{v_110, +v_111} = core_pattern_depth(v_89, v_104)
              v_113 = v_111
              ArenaResult{v_117, +v_118} = scrutinee_variable_index(v_110, v_96, v_15)
              v_120 = v_118
              v_50000212 = optional_source_quantity(maybe_shift_index(v_120, v_19), v_14)
              ArenaResult{v_127, +v_128} = check_pattern_typed(v_117, v_104, v_100, Some{v_50000212}, Nat.add(List.length(&2, Binding, v_14), v_113), v_14, v_15)
              ArenaResult{v_132, +v_133} = check_body_pattern_vector_typed(v_127, v_128, v_2, v_4, v_106, v_102, v_98, v_9, v_11, v_15, v_17, v_19, v_20, v_120, v_113)
              {ArenaResult{v_132, v_133} : ArenaResult<Inference>}
            case _:
              v_50000213 = fail(v_20, "case pattern count differs from scrutinee count", "one pattern and type per scrutinee", "a mismatched pattern vector")
              {ArenaResult{v_89, v_50000213} : ArenaResult<Inference>}
        case _:
          v_50000214 = fail(v_20, "case pattern count differs from scrutinee count", "one pattern and type per scrutinee", "a mismatched pattern vector")
          {ArenaResult{v_80, v_50000214} : ArenaResult<Inference>}
    case _:
      v_50000215 = fail(v_20, "case pattern count differs from scrutinee count", "one pattern and type per scrutinee", "a mismatched pattern vector")
      {ArenaResult{v_27, v_50000215} : ArenaResult<Inference>}

def check_body_pattern_rows_result(v_20037502: ArenaStore, v_1: Inference, v_3: IR.Words, v_5: IR.Words, v_7: IR.Words, v_9: IR.Words, v_10: U32, v_11: U32, v_14: List<&2, Binding>, v_15: Scope.ArenaGlobalScope, v_16: Ast.SourceSpan, v_19: PatternRowIndex) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20037503, +v_20037504}:
      ArenaResult{history_store, history} = pattern_row_index_add(v_20037502, v_3, v_19)
      ArenaResult{v_20037505, +v_20037506} = check_body_pattern_rows(history_store, v_5, v_7, v_9, v_10, v_11, v_14, v_15, v_16, history)
      {ArenaResult{v_20037505, v_20037506} : ArenaResult<Inference>}
    case InferenceFailure{+v_20037507}:
      v_27 = v_20037507
      {ArenaResult{v_20037502, InferenceFailure{v_27}} : ArenaResult<Inference>}

def check_body_pattern_rows_useful(v_20037508: ArenaStore, v_1: Bool, v_3: IR.Words, v_4: U32, v_5: Ast.SourceSpan, v_7: IR.Words, v_9: IR.Words, v_11: IR.Words, v_12: U32, v_13: U32, v_16: List<&2, Binding>, v_17: Scope.ArenaGlobalScope, v_18: Ast.SourceSpan, v_21: PatternRowIndex) -> ArenaResult<Inference>:
  match v_1:
    case True{}:
      ArenaResult{v_20037509, +v_20037510} = check_body_pattern_rows(v_20037508, v_7, v_9, v_11, v_12, v_13, v_16, v_17, v_18, v_21)
      {ArenaResult{v_20037509, v_20037510} : ArenaResult<Inference>}
    case False{}:
      ArenaResult{v_20037511, +v_20037512} = core_pattern_list_depth(v_20037508, v_3)
      v_25 = v_20037512
      ArenaResult{v_20037513, +v_20037514} = match_branch_body(v_20037511, v_3, v_11, v_4, v_25, Nat.add(List.length(&2, Binding, v_16), v_25), v_17)
      v_29 = v_20037514
      ArenaResult{v_20037515, +v_20037516} = check_body_pattern_vector(v_20037513, v_3, v_25, v_3, v_9, v_11, v_29, v_12, v_16, v_17, v_25, 0n, v_5)
      ArenaResult{v_20037517, +v_20037518} = check_body_pattern_rows_result(v_20037515, v_20037516, v_3, v_7, v_9, v_11, v_12, v_13, v_16, v_17, v_18, v_21)
      {ArenaResult{v_20037517, v_20037518} : ArenaResult<Inference>}

def check_body_pattern_rows_length(v_1: ArenaStore, v_3: Bool, v_4: IR.Words, v_6: U32, v_7: Ast.SourceSpan, v_8: IR.Words, v_9: IR.Words, v_10: IR.Words, v_12: U32, v_14: U32, v_17: List<&2, Binding>, v_18: Scope.ArenaGlobalScope, v_19: Ast.SourceSpan, +v_21: PatternRowIndex) -> ArenaResult<Inference>:
  match v_3:
    case True{}:
      ArenaResult{v_28, +v_29} = pattern_row_covered(v_1, v_9, v_21, v_4, v_18)
      ArenaResult{v_33, +v_34} = check_body_pattern_rows_useful(v_28, v_29, v_4, v_6, v_7, v_8, v_9, v_10, v_12, v_14, v_17, v_18, v_19, v_21)
      {ArenaResult{v_33, v_34} : ArenaResult<Inference>}
    case False{}:
      v_50000216 = fail(v_7, "case pattern count differs from scrutinee count", "one pattern per scrutinee", "a mismatched pattern vector")
      {ArenaResult{v_1, v_50000216} : ArenaResult<Inference>}

def check_body_pattern_rows_case(v_1: ArenaStore, v_3: U32, v_4: IR.Words, v_5: IR.Words, v_6: IR.Words, v_8: U32, v_10: U32, v_13: List<&2, Binding>, v_14: Scope.ArenaGlobalScope, v_15: Ast.SourceSpan, v_17: PatternRowIndex) -> ArenaResult<Inference>:
  ArenaResult{v_24, +v_25} = arena_get_node(v_1, v_3)
  match v_25:
    case Arena.BodyCase{+v_30, +v_31, +v_32, +v_33}:
      +v_35 = IR.Words{v_30, v_31}
      v_37 = v_35
      v_39 = v_32
      v_41 = v_33
      ArenaResult{v_47, +v_48} = check_body_pattern_rows_length(v_24, Nat.is_eq(arena_words_length(v_37), arena_words_length(v_5)), v_37, v_39, v_41, v_4, v_5, v_6, v_8, v_10, v_13, v_14, v_15, v_17)
      {ArenaResult{v_47, v_48} : ArenaResult<Inference>}
    case _:
      v_50000217 = fail(v_15, "invalid match case", "a checked case pattern", "an invalid case")
      {ArenaResult{v_24, v_50000217} : ArenaResult<Inference>}

def check_body_pattern_rows(v_20037538: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_5: IR.Words, v_6: U32, v_7: U32, v_10: List<&2, Binding>, v_11: Scope.ArenaGlobalScope, v_12: Ast.SourceSpan, v_15: PatternRowIndex) -> ArenaResult<Inference>:
  ArenaResult{v_20037539, +v_20037540} = arena_words_view(v_20037538, v_1)
  match v_20037540:
    case IR.WordNil{}:
      {ArenaResult{v_20037539, Inferred{v_7, v_6}} : ArenaResult<Inference>}
    case IR.WordCons{+v_20037541, +v_20037542}:
      +v_19 = v_20037541
      v_20 = v_20037542
      ArenaResult{v_20037543, +v_20037544} = check_body_pattern_rows_case(v_20037539, v_19, v_20, v_3, v_5, v_6, v_7, v_10, v_11, v_12, v_15)
      {ArenaResult{v_20037543, v_20037544} : ArenaResult<Inference>}

def check_body_match_many_rows_result(v_20037545: ArenaStore, v_1: Inference, v_3: IR.Words, v_5: IR.Words, v_7: IR.Words, v_8: Ast.SourceSpan, v_9: U32, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope, v_14: U32) -> ArenaResult<Inference>:
  match v_1:
    case InferenceFailure{+v_20037546}:
      v_17 = v_20037546
      {ArenaResult{v_20037545, InferenceFailure{v_17}} : ArenaResult<Inference>}
    case Inferred{+v_20037547, +v_20037548}:
      ArenaResult{v_20037549, +v_20037550} = case_pattern_rows(v_20037545, v_7)
      ArenaResult{v_20037551, +v_20037552} = check_body_matrix_rows(v_20037549, v_20037550, v_3, v_13, v_8, v_9, v_14)
      {ArenaResult{v_20037551, v_20037552} : ArenaResult<Inference>}

def check_body_match_many_types_result(v_20037553: ArenaStore, v_1: ScrutineeTyping, v_3: IR.Words, v_5: IR.Words, v_6: Ast.SourceSpan, v_7: U32, v_10: List<&2, Binding>, v_11: Scope.ArenaGlobalScope, v_12: U32) -> ArenaResult<Inference>:
  match v_1:
    case ScrutineeTypeFailure{+v_20037554}:
      v_15 = v_20037554
      {ArenaResult{v_20037553, InferenceFailure{v_15}} : ArenaResult<Inference>}
    case ScrutineeTypes{+v_20037555}:
      v_17 = v_20037555
      ArenaResult{v_20037556, +v_20037557} = check_body_pattern_rows(v_20037553, v_5, v_17, v_3, v_7, v_12, v_10, v_11, v_6, pattern_row_index_empty())
      ArenaResult{v_20037558, +v_20037559} = check_body_match_many_rows_result(v_20037556, v_20037557, v_17, v_3, v_5, v_6, v_7, v_10, v_11, v_12)
      {ArenaResult{v_20037558, v_20037559} : ArenaResult<Inference>}

def check_body_match_many(v_20037560: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_4: Ast.SourceSpan, v_5: U32, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope, v_10: U32) -> ArenaResult<Inference>:
  ArenaResult{v_20037561, +v_20037562} = infer_scrutinee_types(v_20037560, v_1, v_8, v_9)
  ArenaResult{v_20037563, +v_20037564} = check_body_match_many_types_result(v_20037561, v_20037562, v_1, v_3, v_4, v_5, v_8, v_9, v_10)
  {ArenaResult{v_20037563, v_20037564} : ArenaResult<Inference>}

def check_body_match_first_result(v_20037565: ArenaStore, v_1: Inference, v_2: U32, v_4: IR.Words, v_5: Ast.SourceSpan, v_6: U32, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope, v_11: U32) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20037566, +v_20037567}:
      v_16 = v_20037567
      ArenaResult{v_20037568, +v_20037569} = check_body_match_type(v_20037565, v_2, v_4, v_16, v_5, v_6, v_9, v_10, v_11)
      {ArenaResult{v_20037568, v_20037569} : ArenaResult<Inference>}
    case InferenceFailure{+v_20037570}:
      v_19 = v_20037570
      {ArenaResult{v_20037565, InferenceFailure{v_19}} : ArenaResult<Inference>}

def check_body_match_scrutinees(v_1: ArenaStore, v_2: IR.Words, v_3: IR.Words, v_4: Ast.SourceSpan, v_6: U32, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope, v_12: U32) -> ArenaResult<Inference>:
  ArenaResult{v_19, +v_20} = arena_words_view(v_1, v_2)
  match v_20:
    case IR.WordNil{}:
      v_50000218 = fail(v_4, "match requires at least one scrutinee", "a nonempty scrutinee list", "an empty match")
      {ArenaResult{v_19, v_50000218} : ArenaResult<Inference>}
    case IR.WordCons{+v_24, +v_25}:
      +v_27 = v_24
      v_29 = v_25
      ArenaResult{v_33, +v_34} = arena_words_view(v_19, v_29)
      match v_34:
        case IR.WordNil{}:
          ArenaResult{v_38, +v_39} = infer(v_33, v_27, v_9, v_10)
          ArenaResult{v_43, +v_44} = check_body_match_first_result(v_38, v_39, v_27, v_3, v_4, v_6, v_9, v_10, v_12)
          {ArenaResult{v_43, v_44} : ArenaResult<Inference>}
        case _:
          ArenaResult{v_50, +v_51} = check_body_match_many(v_33, v_2, v_3, v_4, v_6, v_9, v_10, v_12)
          {ArenaResult{v_50, v_51} : ArenaResult<Inference>}

def check_body_match_valid(v_1: ArenaStore, v_3: Bool, v_4: IR.Words, v_5: IR.Words, v_6: Ast.SourceSpan, v_8: U32, v_11: List<&2, Binding>, v_12: Scope.ArenaGlobalScope, v_14: U32) -> ArenaResult<Inference>:
  match v_3:
    case False{}:
      v_50000219 = fail(v_6, "match scrutinees must be parameters or bound fields", "a parameter or field variable", "a computed, constructed, or local value")
      {ArenaResult{v_1, v_50000219} : ArenaResult<Inference>}
    case True{}:
      ArenaResult{v_22, +v_23} = check_body_match_scrutinees(v_1, v_4, v_5, v_6, v_8, v_11, v_12, v_14)
      {ArenaResult{v_22, v_23} : ArenaResult<Inference>}

def check_body_match(v_20037588: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_4: Ast.SourceSpan, v_5: U32, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope, v_10: U32) -> ArenaResult<Inference>:
  ArenaResult{v_20037589, +v_20037590} = match_scrutinees_valid(v_20037588, v_1, v_8)
  ArenaResult{v_20037591, +v_20037592} = check_body_match_valid(v_20037589, v_20037590, v_1, v_3, v_4, v_5, v_8, v_9, v_10)
  {ArenaResult{v_20037591, v_20037592} : ArenaResult<Inference>}

def rewrite_body_result(v_1: Inference, v_2: U32, v_3: U32) -> Inference:
  match v_1:
    case Inferred{+v_20037593, +v_20037594}:
      Inferred{v_2, v_3}
    case InferenceFailure{+v_20037595}:
      v_10 = v_20037595
      InferenceFailure{v_10}

def rewrite_motive_application(v_20037596: ArenaStore, v_0: U32, v_1: U32, v_2: U32, v_3: Ast.SourceSpan) -> ArenaResult<U32>:
  ArenaResult{v_20037597, +v_20037598} = arena_put_node(v_20037596, Arena.TermApp{v_0, v_1, v_3})
  ArenaResult{v_20037599, +v_20037600} = arena_put_node(v_20037597, Arena.TermApp{v_20037598, v_2, v_3})
  {ArenaResult{v_20037599, v_20037600} : ArenaResult<U32>}

def rewrite_fits_result(v_1: ArenaStore, v_3: Bool, v_5: U32, v_7: U32, v_9: U32, v_10: Ast.SourceSpan, v_12: U32, v_15: List<&2, Binding>, v_16: Scope.ArenaGlobalScope, v_18: U32) -> ArenaResult<Inference>:
  match v_3:
    case True{}:
      ArenaResult{v_25, +v_26} = arena_put_node(v_1, Arena.TermRefl{v_10})
      ArenaResult{v_30, +v_31} = rewrite_motive_application(v_25, v_7, v_5, v_26, v_10)
      ArenaResult{v_35, +v_36} = whnf(v_30, 64n, v_31, v_16)
      v_38 = v_36
      ArenaResult{v_42, +v_43} = check_term(v_35, v_9, v_15, v_16, v_38)
      v_50000220 = rewrite_body_result(v_43, v_18, v_12)
      {ArenaResult{v_42, v_50000220} : ArenaResult<Inference>}
    case False{}:
      v_50000221 = fail(v_10, "rewrite result does not fit the goal", "the expected type", "an incompatible rewritten type")
      {ArenaResult{v_1, v_50000221} : ArenaResult<Inference>}

def rewrite_proof_result(v_20037610: ArenaStore, v_1: Inference, v_2: U32, v_3: U32, v_4: U32, v_5: U32, v_6: Ast.SourceSpan, v_7: U32, v_10: List<&2, Binding>, v_11: Scope.ArenaGlobalScope, v_12: U32) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20037611, +v_20037612}:
      v_16 = v_20037611
      ArenaResult{v_20037613, +v_20037614} = rewrite_motive_application(v_20037610, v_16, v_2, v_4, v_6)
      ArenaResult{v_20037615, +v_20037616} = whnf(v_20037613, 64n, v_20037614, v_11)
      v_21 = v_20037616
      ArenaResult{v_20037617, +v_20037618} = fits_term(v_20037615, v_21, v_7, v_11)
      ArenaResult{v_20037619, +v_20037620} = rewrite_fits_result(v_20037617, v_20037618, v_3, v_16, v_5, v_6, v_7, v_10, v_11, v_12)
      {ArenaResult{v_20037619, v_20037620} : ArenaResult<Inference>}
    case InferenceFailure{+v_20037621}:
      v_25 = v_20037621
      {ArenaResult{v_20037610, InferenceFailure{v_25}} : ArenaResult<Inference>}

def rewrite_equation_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_7: U32, v_9: U32, v_10: Ast.SourceSpan, v_12: U32, v_15: List<&2, Binding>, v_16: Scope.ArenaGlobalScope, v_18: U32) -> ArenaResult<Inference>:
  ArenaResult{v_25, +v_26} = arena_get_node(v_1, v_3)
  match v_26:
    case Arena.TermEqual{+v_31, +v_32, +v_33, +v_34}:
      v_36 = v_31
      v_38 = v_32
      v_40 = v_33
      ArenaResult{v_44, +v_45} = arena_name(v_25, "x")
      ArenaResult{v_49, +v_50} = arena_put_node(v_44, Arena.TermVar{v_45, 0n, v_10})
      v_52 = v_50
      ArenaResult{v_56, +v_57} = core_shift(v_49, 0n, 1n, v_36)
      v_59 = v_57
      ArenaResult{v_63, +v_64} = core_shift(v_56, 0n, 1n, v_40)
      v_66 = v_64
      ArenaResult{v_70, +v_71} = arena_put_node(v_63, Arena.TermEqual{v_59, v_52, v_66, v_10})
      v_73 = v_71
      ArenaResult{v_77, +v_78} = arena_put_node(v_70, Arena.TermQuantity{Ast.QOne{}, v_10})
      ArenaResult{v_82, +v_83} = arena_put_node(v_77, Arena.TermType{v_78, v_10})
      v_85 = v_83
      ArenaResult{v_89, +v_90} = arena_name(v_82, "e")
      ArenaResult{v_94, +v_95} = arena_put_node(v_89, Arena.TermAll{Ast.QOne{}, v_90, 0n, v_73, v_85, v_10})
      ArenaResult{v_99, +v_100} = arena_name(v_94, "x")
      ArenaResult{v_104, +v_105} = arena_put_node(v_99, Arena.TermAll{Ast.QOne{}, v_100, 0n, v_40, v_95, v_10})
      v_107 = v_105
      ArenaResult{v_111, +v_112} = check_term(v_104, v_7, v_15, v_16, v_107)
      ArenaResult{v_116, +v_117} = rewrite_proof_result(v_111, v_112, v_38, v_36, v_5, v_9, v_10, v_12, v_15, v_16, v_18)
      {ArenaResult{v_116, v_117} : ArenaResult<Inference>}
    case _:
      v_50000222 = fail(v_10, "rewrite evidence is not an equation", "an equation {a == b : T}", "a non-equation")
      {ArenaResult{v_25, v_50000222} : ArenaResult<Inference>}

def rewrite_equation_result(v_20037660: ArenaStore, v_1: Inference, v_2: U32, v_3: U32, v_4: Ast.SourceSpan, v_5: U32, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope, v_10: U32) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20037661, +v_20037662}:
      v_14 = v_20037661
      v_15 = v_20037662
      ArenaResult{v_20037663, +v_20037664} = whnf(v_20037660, 64n, v_15, v_9)
      ArenaResult{v_20037665, +v_20037666} = rewrite_equation_view(v_20037663, v_20037664, v_14, v_2, v_3, v_4, v_5, v_8, v_9, v_10)
      {ArenaResult{v_20037665, v_20037666} : ArenaResult<Inference>}
    case InferenceFailure{+v_20037667}:
      v_19 = v_20037667
      {ArenaResult{v_20037660, InferenceFailure{v_19}} : ArenaResult<Inference>}

def check_rewrite(v_20037668: ArenaStore, v_0: U32, v_1: U32, v_2: U32, v_3: Ast.SourceSpan, v_4: U32, v_7: List<&2, Binding>, v_8: Scope.ArenaGlobalScope, v_9: U32) -> ArenaResult<Inference>:
  ArenaResult{v_20037669, +v_20037670} = infer(v_20037668, v_0, v_7, v_8)
  ArenaResult{v_20037671, +v_20037672} = rewrite_equation_result(v_20037669, v_20037670, v_1, v_2, v_3, v_4, v_7, v_8, v_9)
  {ArenaResult{v_20037671, v_20037672} : ArenaResult<Inference>}

def lambda_quantity(v_1: Maybe<&2, Ast.Quantity>, v_2: Ast.Quantity) -> Maybe<&2, Ast.Quantity>:
  match v_1:
    case None{}:
      Some{v_2}
    case Some{+v_20037673}:
      v_6 = v_20037673
      +v_20037675 = same_quantity(v_6, v_2)
      match v_20037675:
        case False{}:
          +v_20037674 = lambda_quantity_mismatch(v_6, v_2)
          v_20037674
        case True{}:
          +v_20037674 = Some{v_2}
          v_20037674

def lambda_quantity_mismatch(v_0: Ast.Quantity, v_1: Ast.Quantity) -> Maybe<&2, Ast.Quantity>:
  match v_0:
    case Ast.QMany{}:
      match v_1:
        case Ast.QOne{}:
          Some{Ast.QMany{}}
        case _:
          None{}
    case _:
      None{}

def lambda_promotes(v_1: Maybe<&2, Ast.Quantity>, v_2: Ast.Quantity) -> Bool:
  match v_1:
    case Some{+v_20037679}:
      match v_20037679:
        case Ast.QMany{}:
          match v_2:
            case Ast.QOne{}:
              True{}
            case _:
              False{}
        case _:
          False{}
    case _:
      False{}

def promotion_domain_valid(v_20037683: ArenaStore, v_0: U32, v_1: Ast.SourceSpan, v_4: List<&2, Binding>, v_5: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20037684, +v_20037685} = infer(v_20037683, v_0, v_4, v_5)
  ArenaResult{v_20037686, +v_20037687} = promotion_domain_inference(v_20037684, v_20037685, v_0, v_1, v_4, v_5)
  {ArenaResult{v_20037686, v_20037687} : ArenaResult<Bool>}

def promotion_domain_inference(v_20037688: ArenaStore, v_1: Inference, v_2: U32, v_3: Ast.SourceSpan, v_6: List<&2, Binding>, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_1:
    case Inferred{+v_20037689, +v_20037690}:
      ArenaResult{v_20037691, +v_20037692} = promotion_domain_valid_result(v_20037688, v_1, v_3, v_7)
      {ArenaResult{v_20037691, v_20037692} : ArenaResult<Bool>}
    case InferenceFailure{+v_20037693}:
      ArenaResult{v_20037694, +v_20037695} = whnf(v_20037688, 64n, v_2, v_7)
      ArenaResult{v_20037696, +v_20037697} = infer(v_20037694, v_20037695, v_6, v_7)
      ArenaResult{v_20037698, +v_20037699} = promotion_domain_valid_result(v_20037696, v_20037697, v_3, v_7)
      {ArenaResult{v_20037698, v_20037699} : ArenaResult<Bool>}

def promotion_domain_valid_result(v_1: ArenaStore, v_3: Inference, v_4: Ast.SourceSpan, v_5: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_3:
    case Inferred{+v_11, +v_12}:
      v_14 = v_12
      v_50000223 = domain_quantity(Ast.QMany{}, v_5)
      ArenaResult{v_19, +v_20} = arena_put_node(v_1, Arena.TermQuantity{v_50000223, v_4})
      ArenaResult{v_24, +v_25} = arena_put_node(v_19, Arena.TermType{v_20, v_4})
      ArenaResult{v_29, +v_30} = fits_term(v_24, v_14, v_25, v_5)
      {ArenaResult{v_29, v_30} : ArenaResult<Bool>}
    case InferenceFailure{+v_32}:
      {ArenaResult{v_1, False{}} : ArenaResult<Bool>}

def check_lambda_domain_result(v_1: ArenaStore, v_3: Bool, +v_5: Maybe<&2, Ast.Quantity>, +v_7: String, +v_9: U32, +v_10: Ast.Quantity, +v_12: U32, +v_14: U32, +v_15: Ast.SourceSpan, +v_17: U32, +v_20: List<&2, Binding>, +v_21: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_3:
    case True{}:
      ArenaResult{v_29, +v_30} = check_term(v_1, v_9, Binding{v_7, v_10, v_12, List.length(&2, Binding, v_20)} <> v_20, v_21, v_14)
      ArenaResult{v_34, +v_35} = check_lambda_body_result(v_29, v_30, v_5, v_7, v_9, v_10, v_12, v_14, v_15, v_17, v_20, v_21)
      {ArenaResult{v_34, v_35} : ArenaResult<Inference>}
    case False{}:
      v_50000224 = fail(v_15, "promoted lambda domain has insufficient kind", "a domain valid at Kind(&2)", "a lower-kind domain")
      {ArenaResult{v_1, v_50000224} : ArenaResult<Inference>}

def check_lambda_promotes_result(v_20037715: ArenaStore, v_1: Bool, +v_3: Maybe<&2, Ast.Quantity>, +v_5: String, +v_6: U32, +v_7: Ast.Quantity, +v_8: U32, +v_9: U32, +v_10: Ast.SourceSpan, +v_11: U32, +v_14: List<&2, Binding>, +v_15: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_1:
    case True{}:
      ArenaResult{v_20037716, +v_20037717} = promotion_domain_valid(v_20037715, v_8, v_10, v_14, v_15)
      ArenaResult{v_20037718, +v_20037719} = check_lambda_domain_result(v_20037716, v_20037717, v_3, v_5, v_6, v_7, v_8, v_9, v_10, v_11, v_14, v_15)
      {ArenaResult{v_20037718, v_20037719} : ArenaResult<Inference>}
    case False{}:
      ArenaResult{v_20037720, +v_20037721} = check_term(v_20037715, v_6, Binding{v_5, v_7, v_8, List.length(&2, Binding, v_14)} <> v_14, v_15, v_9)
      ArenaResult{v_20037722, +v_20037723} = check_lambda_body_result(v_20037720, v_20037721, v_3, v_5, v_6, v_7, v_8, v_9, v_10, v_11, v_14, v_15)
      {ArenaResult{v_20037722, v_20037723} : ArenaResult<Inference>}

def check_lambda_quantity_result(v_1: ArenaStore, v_3: Maybe<&2, Ast.Quantity>, v_5: Maybe<&2, Ast.Quantity>, v_7: String, v_9: U32, v_11: U32, v_13: U32, v_14: Ast.SourceSpan, v_15: Ast.Quantity, v_17: U32, v_20: List<&2, Binding>, v_21: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_3:
    case None{}:
      v_50000225 = fail(v_14, "lambda quantity annotation does not match its function type", "the expected binder quantity (or an explicit Many promotion)", "an incompatible lambda quantity")
      {ArenaResult{v_1, v_50000225} : ArenaResult<Inference>}
    case Some{+v_27}:
      v_29 = v_27
      ArenaResult{v_34, +v_35} = check_lambda_promotes_result(v_1, lambda_promotes(v_5, v_15), v_5, v_7, v_9, v_29, v_11, v_13, v_14, v_17, v_20, v_21)
      {ArenaResult{v_34, v_35} : ArenaResult<Inference>}

def check_lambda_body(v_20037728: ArenaStore, v_1: Maybe<&2, Ast.Quantity>, v_3: String, v_4: U32, v_5: Ast.Quantity, v_6: U32, v_7: U32, v_8: Ast.SourceSpan, v_9: U32, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  ArenaResult{v_20037729, +v_20037730} = check_lambda_quantity_result(v_20037728, lambda_quantity(v_1, v_5), v_1, v_3, v_4, v_6, v_7, v_8, v_5, v_9, v_12, v_13)
  {ArenaResult{v_20037729, v_20037730} : ArenaResult<Inference>}

def check_lambda_body_use(v_20037731: ArenaStore, v_1: Bool, v_2: U32, v_4: Maybe<&2, Ast.Quantity>, v_6: String, v_7: Ast.SourceSpan, v_8: U32) -> ArenaResult<Inference>:
  +v_20037734 = v_1
  match v_20037734:
    case False{}:
      +v_20037732 = fail(v_7, String.append("invalid use quantity for ", v_6), "within the lambda quantity", "too many uses")
      v_20037733 = v_20037731
      {ArenaResult{v_20037733, v_20037732} : ArenaResult<Inference>}
    case True{}:
      ArenaResult{v_20037735, +v_20037736} = arena_name(v_20037731, v_6)
      ArenaResult{v_20037737, +v_20037738} = arena_put_node(v_20037735, Arena.TermLam{v_4, v_20037736, 0n, v_2, v_7})
      +v_20037732 = Inferred{v_20037738, v_8}
      v_20037733 = v_20037737
      {ArenaResult{v_20037733, v_20037732} : ArenaResult<Inference>}

def lambda_usage_valid(v_1: ArenaStore, v_2: Ast.Quantity, v_4: U32, v_7: List<&2, Binding>, v_8: Scope.ArenaGlobalScope, v_10: U32) -> ArenaResult<Bool>:
  match v_2:
    case Ast.QMany{}:
      {ArenaResult{v_1, True{}} : ArenaResult<Bool>}
    case _:
      ArenaResult{v_19, +v_20} = use_count_with_expected(v_1, v_4, 0n, v_7, v_8, v_10)
      v_50000226 = quantity_fits(v_20, v_2)
      {ArenaResult{v_19, v_50000226} : ArenaResult<Bool>}

def check_lambda_body_result(v_20037743: ArenaStore, v_1: Inference, v_3: Maybe<&2, Ast.Quantity>, v_5: String, v_6: U32, v_7: Ast.Quantity, v_8: U32, v_9: U32, v_10: Ast.SourceSpan, v_11: U32, v_14: List<&2, Binding>, v_15: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20037744, +v_20037745}:
      v_19 = v_20037744
      ArenaResult{v_20037746, +v_20037747} = lambda_usage_valid(v_20037743, v_7, v_6, Binding{v_5, v_7, v_8, List.length(&2, Binding, v_14)} <> v_14, v_15, v_9)
      ArenaResult{v_20037748, +v_20037749} = check_lambda_body_use(v_20037746, v_20037747, v_19, v_3, v_5, v_10, v_11)
      {ArenaResult{v_20037748, v_20037749} : ArenaResult<Inference>}
    case InferenceFailure{+v_20037750}:
      v_25 = v_20037750
      {ArenaResult{v_20037743, InferenceFailure{v_25}} : ArenaResult<Inference>}

def check_term_lambda_view(v_1: ArenaStore, v_3: U32, v_5: Maybe<&2, Ast.Quantity>, v_7: String, v_9: U32, v_10: Ast.SourceSpan, v_12: U32, v_15: List<&2, Binding>, v_16: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  ArenaResult{v_23, +v_24} = arena_get_node(v_1, v_3)
  match v_24:
    case Arena.TermAll{+v_31, +v_32, +v_33, +v_34, +v_35, +v_36}:
      v_38 = v_31
      v_40 = v_34
      v_42 = v_35
      ArenaResult{v_46, +v_47} = check_lambda_body(v_23, v_5, v_7, v_9, v_38, v_40, v_42, v_10, v_12, v_15, v_16)
      {ArenaResult{v_46, v_47} : ArenaResult<Inference>}
    case _:
      v_50000227 = fail(v_10, "lambda requires a function type", "a function type", "a non-function type")
      {ArenaResult{v_23, v_50000227} : ArenaResult<Inference>}

def check_term_constructor_apply(v_1: ArenaStore, v_4: Maybe<&2, U32>, v_6: String, v_7: IR.Words, v_8: Ast.SourceSpan, v_9: IR.Words, v_11: U32, v_14: List<&2, Binding>, v_15: Scope.ArenaGlobalScope, v_17: U32, v_19: U32) -> ArenaResult<Inference>:
  match v_4:
    case Some{+v_24}:
      v_26 = v_24
      ArenaResult{v_30, +v_31} = check_ctr_fields(v_1, v_7, v_26, v_11, v_14, v_15, v_17, v_8, v_19)
      {ArenaResult{v_30, v_31} : ArenaResult<Inference>}
    case None{}:
      v_50000228 = fail(v_8, "constructor parameter telescope does not match datatype", "constructor parameters", "an incompatible telescope")
      {ArenaResult{v_1, v_50000228} : ArenaResult<Inference>}

def check_term_constructor_global(v_20037774: ArenaStore, v_0: Scope.ArenaGlobal, v_2: String, v_4: IR.Words, v_5: Ast.SourceSpan, v_7: IR.Words, v_8: U32, v_11: List<&2, Binding>, v_12: Scope.ArenaGlobalScope, v_13: U32, v_14: U32) -> ArenaResult<Inference>:
  match v_0:
    case Scope.ArenaGlobal{+v_20037775, +v_20037776, +v_20037777, +v_20037778, +v_20037779, +v_20037780}:
      v_25 = v_20037778
      ArenaResult{v_20037781, +v_20037782} = apply_prefix(v_20037774, v_7, v_25)
      ArenaResult{v_20037783, +v_20037784} = check_term_constructor_apply(v_20037781, v_20037782, v_2, v_4, v_5, v_7, v_8, v_11, v_12, v_13, v_14)
      {ArenaResult{v_20037783, v_20037784} : ArenaResult<Inference>}

def check_term_constructor_global_result(v_1: ArenaStore, v_3: Maybe<&2, Scope.ArenaGlobal>, v_5: String, v_6: IR.Words, v_7: Ast.SourceSpan, v_8: IR.Words, v_10: U32, v_13: List<&2, Binding>, v_14: Scope.ArenaGlobalScope, v_16: U32, v_18: U32) -> ArenaResult<Inference>:
  match v_3:
    case Some{+v_23}:
      v_25 = v_23
      ArenaResult{v_29, +v_30} = check_term_constructor_global(v_1, v_25, v_5, v_6, v_7, v_8, v_10, v_13, v_14, v_16, v_18)
      {ArenaResult{v_29, v_30} : ArenaResult<Inference>}
    case None{}:
      v_50000229 = fail(v_7, String.append("unknown constructor ", v_5), "a declared constructor", v_5)
      {ArenaResult{v_1, v_50000229} : ArenaResult<Inference>}

def check_term_constructor_allowed(v_1: ArenaStore, v_3: Bool, v_5: String, v_6: IR.Words, v_7: Ast.SourceSpan, v_8: IR.Words, v_9: IR.Names, v_11: U32, v_14: List<&2, Binding>, v_15: Scope.ArenaGlobalScope, v_17: U32, v_19: U32) -> ArenaResult<Inference>:
  match v_3:
    case True{}:
      v_50000230 = fail(v_7, "constructor is excluded from this datatype goal", "a remaining constructor", v_5)
      {ArenaResult{v_1, v_50000230} : ArenaResult<Inference>}
    case False{}:
      ArenaResult{v_28, +v_29} = check_term_constructor_global_result(v_1, Scope.lookup_kind(v_5, Scope.GlobalConstructor{}, v_15), v_5, v_6, v_7, v_8, v_11, v_14, v_15, v_17, v_19)
      {ArenaResult{v_28, v_29} : ArenaResult<Inference>}

# Exact bounded scalar typing proof. Names select scope entries; every selected
# datatype, constructor signature and Word equation is independently verified.
# Unsupported descriptors retain the general checker and its original spans.
# Bind U32 descriptor counts instead of matching nested numeric patterns, which
# the canonical source parser does not admit. Typed equality guards enclose all
# child reads; an incorrect arity returns False without touching its tape range.
# Canonical text alone is not a resolver witness: distinct alias records may
# advertise the same namespace/local key. Require the exact validated type and
# value handles, as well as owner and kind, before using a declaration equation.
def scalar_optional_identity(left: IR.OptionalTerm, right: IR.OptionalTerm) -> Bool:
  match left right:
    case IR.NoTerm{} IR.NoTerm{}: True{}
    case IR.SomeTerm{a} IR.SomeTerm{b}: U32.is_eq(a, b)
    case _ _: False{}

def scalar_kind_identity(left: Scope.GlobalKind, right: Scope.GlobalKind) -> Bool:
  match left right:
    case Scope.GlobalFamily{} Scope.GlobalFamily{}: True{}
    case Scope.GlobalConstructor{} Scope.GlobalConstructor{}: True{}
    case Scope.GlobalDefinition{} Scope.GlobalDefinition{}: True{}
    case _ _: False{}

def scalar_global_identity(left: Maybe<&2, Scope.ArenaGlobal>, right: Maybe<&2, Scope.ArenaGlobal>) -> Bool:
  match left right:
    case Some{Scope.ArenaGlobal{_, owner_a, local_a, type_a, value_a, kind_a}} Some{Scope.ArenaGlobal{_, owner_b, local_b, type_b, value_b, kind_b}}:
      Bool.and(String.eq(owner_a, owner_b), Bool.and(String.eq(local_a, local_b), Bool.and(U32.is_eq(type_a, type_b), Bool.and(scalar_optional_identity(value_a, value_b), scalar_kind_identity(kind_a, kind_b)))))
    case _ _: False{}

def scalar_reference_constructor(expected: String) -> Bool:
  Bool.or(String.eq(expected, "True"), Bool.or(String.eq(expected, "False"), Bool.or(String.eq(expected, "Zero"), Bool.or(String.eq(expected, "Succ"), Bool.or(String.eq(expected, "WNil"), String.eq(expected, "WCon"))))))

def scalar_reference_identity(+name: String, +ns: String, +globals: Scope.ArenaGlobalScope, +expected: String) -> Bool:
  match scalar_reference_constructor(expected):
    case True{}:
      scalar_global_identity(Scope.lookup_kind(name, Scope.GlobalConstructor{}, globals), Scope.lookup_kind(canonical_key(ns, expected), Scope.GlobalConstructor{}, globals))
    case False{}:
      match String.eq(expected, "Word"):
        case True{}:
          scalar_global_identity(Scope.lookup(name, globals), Scope.lookup_kind(canonical_key(ns, expected), Scope.GlobalDefinition{}, globals))
        case False{}:
          scalar_global_identity(Scope.lookup(name, globals), Scope.lookup_kind(canonical_key(ns, expected), Scope.GlobalFamily{}, globals))


def scalar_schema_name(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope, +expected: String, canonical: Bool) -> ArenaResult<Bool>:
  ArenaResult{store, +name} = arena_name_text(store, id)
  match canonical:
    case True{}: {ArenaResult{store, scalar_reference_identity(name, ns, globals, expected)} : ArenaResult<Bool>}
    case False{}: {ArenaResult{store, String.eq(name, expected)} : ArenaResult<Bool>}

def scalar_schema_1(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermQuantity{Ast.QMany{}, _}:
      {ArenaResult{store, True{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_0(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermType{kind_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_1(store, kind_id, ns, globals)
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_2(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAdt{key_id, args_start, args_count, refs_start, refs_count, _}:
      match Bool.and(U32.is_eq(args_count, 0), U32.is_eq(refs_count, 0)):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Bool", True{})
          {ArenaResult{store, valid_0} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_Bool_GlobalFamily(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "Bool"), Scope.GlobalFamily{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.SomeTerm{value}, Scope.GlobalFamily{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_0(store, ty, ns, globals)
      ArenaResult{store, +valid_value} = scalar_schema_2(store, value, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "Bool")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "Bool"), Bool.and(valid_ty, valid_value))))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_False_GlobalConstructor(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "False"), Scope.GlobalConstructor{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_2(store, ty, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "False")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "False"), valid_ty)))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_True_GlobalConstructor(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "True"), Scope.GlobalConstructor{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_2(store, ty, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "True")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "True"), valid_ty)))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_3(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAdt{key_id, args_start, args_count, refs_start, refs_count, _}:
      match Bool.and(U32.is_eq(args_count, 0), U32.is_eq(refs_count, 0)):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Nat", True{})
          {ArenaResult{store, valid_0} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_Nat_GlobalFamily(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "Nat"), Scope.GlobalFamily{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.SomeTerm{value}, Scope.GlobalFamily{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_0(store, ty, ns, globals)
      ArenaResult{store, +valid_value} = scalar_schema_3(store, value, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "Nat")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "Nat"), Bool.and(valid_ty, valid_value))))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_Zero_GlobalConstructor(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "Zero"), Scope.GlobalConstructor{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_3(store, ty, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "Zero")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "Zero"), valid_ty)))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_5(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermRef{key_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Nat", True{})
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_4(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAll{Ast.QOne{}, key_id, 0n, ty_id, body_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "pred", False{})
      ArenaResult{store, +valid_1} = scalar_schema_5(store, ty_id, ns, globals)
      ArenaResult{store, +valid_2} = scalar_schema_3(store, body_id, ns, globals)
      {ArenaResult{store, Bool.and(Bool.and(valid_0, valid_1), valid_2)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_Succ_GlobalConstructor(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "Succ"), Scope.GlobalConstructor{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_4(store, ty, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "Succ")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "Succ"), valid_ty)))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_6(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAdt{key_id, args_start, args_count, refs_start, refs_count, _}:
      match Bool.and(U32.is_eq(args_count, 0), U32.is_eq(refs_count, 0)):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Word.Nil", True{})
          {ArenaResult{store, valid_0} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_Word_Nil_GlobalFamily(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "Word.Nil"), Scope.GlobalFamily{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.SomeTerm{value}, Scope.GlobalFamily{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_0(store, ty, ns, globals)
      ArenaResult{store, +valid_value} = scalar_schema_6(store, value, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "Word.Nil")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "Word.Nil"), Bool.and(valid_ty, valid_value))))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_WNil_GlobalConstructor(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "WNil"), Scope.GlobalConstructor{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_6(store, ty, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "WNil")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "WNil"), valid_ty)))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_7(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAll{Ast.QZero{}, key_id, 0n, ty_id, body_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "p", False{})
      ArenaResult{store, +valid_1} = scalar_schema_5(store, ty_id, ns, globals)
      ArenaResult{store, +valid_2} = scalar_schema_0(store, body_id, ns, globals)
      {ArenaResult{store, Bool.and(Bool.and(valid_0, valid_1), valid_2)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_10(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermVar{key_id, 0n, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "p", False{})
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_9(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAdt{key_id, args_start, args_count, refs_start, refs_count, _}:
      match Bool.and(U32.is_eq(args_count, 1), U32.is_eq(refs_count, 0)):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Word.Con", True{})
          ArenaResult{store, +item_0} = arena_get_word(store, arena_range_index(args_start, 0))
          ArenaResult{store, +valid_1} = scalar_schema_10(store, item_0, ns, globals)
          {ArenaResult{store, Bool.and(valid_0, valid_1)} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_8(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermLam{Some{Ast.QZero{}}, key_id, 0n, body_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "p", False{})
      ArenaResult{store, +valid_1} = scalar_schema_9(store, body_id, ns, globals)
      {ArenaResult{store, Bool.and(valid_0, valid_1)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_Word_Con_GlobalFamily(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "Word.Con"), Scope.GlobalFamily{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.SomeTerm{value}, Scope.GlobalFamily{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_7(store, ty, ns, globals)
      ArenaResult{store, +valid_value} = scalar_schema_8(store, value, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "Word.Con")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "Word.Con"), Bool.and(valid_ty, valid_value))))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_13(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermRef{key_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Bool", True{})
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_16(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermRef{key_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Word", True{})
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_17(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermVar{key_id, 1n, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "p", False{})
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_15(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermApp{fn_id, arg_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_16(store, fn_id, ns, globals)
      ArenaResult{store, +valid_1} = scalar_schema_17(store, arg_id, ns, globals)
      {ArenaResult{store, Bool.and(valid_0, valid_1)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_19(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermVar{key_id, 2n, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "p", False{})
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_18(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAdt{key_id, args_start, args_count, refs_start, refs_count, _}:
      match Bool.and(U32.is_eq(args_count, 1), U32.is_eq(refs_count, 0)):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Word.Con", True{})
          ArenaResult{store, +item_0} = arena_get_word(store, arena_range_index(args_start, 0))
          ArenaResult{store, +valid_1} = scalar_schema_19(store, item_0, ns, globals)
          {ArenaResult{store, Bool.and(valid_0, valid_1)} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_14(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAll{Ast.QOne{}, key_id, 2n, ty_id, body_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "tail", False{})
      ArenaResult{store, +valid_1} = scalar_schema_15(store, ty_id, ns, globals)
      ArenaResult{store, +valid_2} = scalar_schema_18(store, body_id, ns, globals)
      {ArenaResult{store, Bool.and(Bool.and(valid_0, valid_1), valid_2)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_12(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAll{Ast.QOne{}, key_id, 1n, ty_id, body_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "head", False{})
      ArenaResult{store, +valid_1} = scalar_schema_13(store, ty_id, ns, globals)
      ArenaResult{store, +valid_2} = scalar_schema_14(store, body_id, ns, globals)
      {ArenaResult{store, Bool.and(Bool.and(valid_0, valid_1), valid_2)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_11(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAll{Ast.QZero{}, key_id, 0n, ty_id, body_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "p", False{})
      ArenaResult{store, +valid_1} = scalar_schema_5(store, ty_id, ns, globals)
      ArenaResult{store, +valid_2} = scalar_schema_12(store, body_id, ns, globals)
      {ArenaResult{store, Bool.and(Bool.and(valid_0, valid_1), valid_2)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_WCon_GlobalConstructor(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "WCon"), Scope.GlobalConstructor{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_11(store, ty, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "WCon")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "WCon"), valid_ty)))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_20(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAll{Ast.QOne{}, key_id, 0n, ty_id, body_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "n", False{})
      ArenaResult{store, +valid_1} = scalar_schema_5(store, ty_id, ns, globals)
      ArenaResult{store, +valid_2} = scalar_schema_0(store, body_id, ns, globals)
      {ArenaResult{store, Bool.and(Bool.and(valid_0, valid_1), valid_2)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_23(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermVar{key_id, 0n, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "n", False{})
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_26(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermRef{key_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Word.Nil", True{})
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_25(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.BodyReply{term_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_26(store, term_id, ns, globals)
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_27(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_pattern(store, id)
  match node:
    case Arena.PatternCtr{key_id, fields_start, fields_count, _}:
      match U32.is_eq(fields_count, 0):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Zero", True{})
          {ArenaResult{store, valid_0} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_24(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.BodyCase{patterns_start, patterns_count, body_id, _}:
      match U32.is_eq(patterns_count, 1):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_25(store, body_id, ns, globals)
          ArenaResult{store, +item_0} = arena_get_word(store, arena_range_index(patterns_start, 0))
          ArenaResult{store, +valid_1} = scalar_schema_27(store, item_0, ns, globals)
          {ArenaResult{store, Bool.and(valid_0, valid_1)} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_31(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermRef{key_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Word.Con", True{})
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_30(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermFill{head_id, args_start, args_count, _}:
      match U32.is_eq(args_count, 1):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_31(store, head_id, ns, globals)
          ArenaResult{store, +item_0} = arena_get_word(store, arena_range_index(args_start, 0))
          ArenaResult{store, +valid_1} = scalar_schema_10(store, item_0, ns, globals)
          {ArenaResult{store, Bool.and(valid_0, valid_1)} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_29(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.BodyReply{term_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_30(store, term_id, ns, globals)
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_33(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_pattern(store, id)
  match node:
    case Arena.PatternVar{key_id, 1n, Ast.QOne{}, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "p", False{})
      {ArenaResult{store, valid_0} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_32(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_pattern(store, id)
  match node:
    case Arena.PatternCtr{key_id, fields_start, fields_count, _}:
      match U32.is_eq(fields_count, 1):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "Succ", True{})
          ArenaResult{store, +item_0} = arena_get_word(store, arena_range_index(fields_start, 0))
          ArenaResult{store, +valid_1} = scalar_schema_33(store, item_0, ns, globals)
          {ArenaResult{store, Bool.and(valid_0, valid_1)} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_28(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.BodyCase{patterns_start, patterns_count, body_id, _}:
      match U32.is_eq(patterns_count, 1):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_29(store, body_id, ns, globals)
          ArenaResult{store, +item_0} = arena_get_word(store, arena_range_index(patterns_start, 0))
          ArenaResult{store, +valid_1} = scalar_schema_32(store, item_0, ns, globals)
          {ArenaResult{store, Bool.and(valid_0, valid_1)} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_22(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.BodyMatch{scrutinees_start, scrutinees_count, cases_start, cases_count, _}:
      match Bool.and(U32.is_eq(scrutinees_count, 1), U32.is_eq(cases_count, 2)):
        case True{}:
          ArenaResult{store, +item_0} = arena_get_word(store, arena_range_index(scrutinees_start, 0))
          ArenaResult{store, +valid_0} = scalar_schema_23(store, item_0, ns, globals)
          ArenaResult{store, +item_1} = arena_get_word(store, arena_range_index(cases_start, 0))
          ArenaResult{store, +valid_1} = scalar_schema_24(store, item_1, ns, globals)
          ArenaResult{store, +item_2} = arena_get_word(store, arena_range_index(cases_start, 1))
          ArenaResult{store, +valid_2} = scalar_schema_28(store, item_2, ns, globals)
          {ArenaResult{store, Bool.and(Bool.and(valid_0, valid_1), valid_2)} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_21(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermLam{Some{Ast.QOne{}}, key_id, 0n, body_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "n", False{})
      ArenaResult{store, +valid_1} = scalar_schema_22(store, body_id, ns, globals)
      {ArenaResult{store, Bool.and(valid_0, valid_1)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_Word_GlobalDefinition(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "Word"), Scope.GlobalDefinition{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.SomeTerm{value}, Scope.GlobalDefinition{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_20(store, ty, ns, globals)
      ArenaResult{store, +valid_value} = scalar_schema_21(store, value, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "Word")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "Word"), Bool.and(valid_ty, valid_value))))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_34(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAdt{key_id, args_start, args_count, refs_start, refs_count, _}:
      match Bool.and(U32.is_eq(args_count, 0), U32.is_eq(refs_count, 0)):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "U32", True{})
          {ArenaResult{store, valid_0} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_U32_GlobalFamily(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "U32"), Scope.GlobalFamily{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.SomeTerm{value}, Scope.GlobalFamily{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_0(store, ty, ns, globals)
      ArenaResult{store, +valid_value} = scalar_schema_34(store, value, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "U32")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "U32"), Bool.and(valid_ty, valid_value))))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_nat(remaining: Nat, store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match remaining node:
    case 0n Arena.TermCtr{key, _, count, _}:
      match U32.is_eq(count, 0):
        case True{}:
          scalar_schema_name(store, key, ns, globals, "Zero", True{})
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case 1n+rest Arena.TermCtr{key, start, count, _}:
      match U32.is_eq(count, 1):
        case True{}:
          ArenaResult{store, +valid_owner} = scalar_schema_name(store, key, ns, globals, "Succ", True{})
          ArenaResult{store, +tail} = arena_get_word(store, start)
          ArenaResult{store, +valid_tail} = scalar_schema_nat(rest, store, tail, ns, globals)
          {ArenaResult{store, Bool.and(valid_owner, valid_tail)} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _ _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_36(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermApp{fn_id, arg_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_16(store, fn_id, ns, globals)
      ArenaResult{store, +valid_1} = scalar_schema_nat(32n, store, arg_id, ns, globals)
      {ArenaResult{store, Bool.and(valid_0, valid_1)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_35(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAll{Ast.QOne{}, key_id, 0n, ty_id, body_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "data", False{})
      ArenaResult{store, +valid_1} = scalar_schema_36(store, ty_id, ns, globals)
      ArenaResult{store, +valid_2} = scalar_schema_34(store, body_id, ns, globals)
      {ArenaResult{store, Bool.and(Bool.and(valid_0, valid_1), valid_2)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_U32_GlobalConstructor(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "U32"), Scope.GlobalConstructor{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_35(store, ty, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "U32")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "U32"), valid_ty)))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_70(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAdt{key_id, args_start, args_count, refs_start, refs_count, _}:
      match Bool.and(U32.is_eq(args_count, 0), U32.is_eq(refs_count, 0)):
        case True{}:
          ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "F32", True{})
          {ArenaResult{store, valid_0} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_F32_GlobalFamily(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "F32"), Scope.GlobalFamily{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.SomeTerm{value}, Scope.GlobalFamily{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_0(store, ty, ns, globals)
      ArenaResult{store, +valid_value} = scalar_schema_70(store, value, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "F32")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "F32"), Bool.and(valid_ty, valid_value))))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_schema_71(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermAll{Ast.QOne{}, key_id, 0n, ty_id, body_id, _}:
      ArenaResult{store, +valid_0} = scalar_schema_name(store, key_id, ns, globals, "data", False{})
      ArenaResult{store, +valid_1} = scalar_schema_36(store, ty_id, ns, globals)
      ArenaResult{store, +valid_2} = scalar_schema_70(store, body_id, ns, globals)
      {ArenaResult{store, Bool.and(Bool.and(valid_0, valid_1), valid_2)} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_global_F32_GlobalConstructor(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, "F32"), Scope.GlobalConstructor{}, globals):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_71(store, ty, ns, globals)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, "F32")), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, "F32"), valid_ty)))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

# One traversal retains at most three successfully resolved, exact name IDs.
# Full tagged IDs are compared; a different alias ID takes the original
# resolver-identity proof. Scope and both name pools remain the same throughout
# this traversal. No fact survives the scalar_closed_word entry/exit boundary.
def scalar_literal_name_hit(key: U32, saved: Maybe<&2, U32>) -> Bool:
  match saved:
    case Some{other}: U32.is_eq(key, other)
    case None{}: False{}

def scalar_closed_bit_name(store: ArenaStore, key: U32, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +name} = arena_name_text(store, key)
  {ArenaResult{store, Bool.or(scalar_reference_identity(name, ns, globals, "True"), scalar_reference_identity(name, ns, globals, "False"))} : ArenaResult<Bool>}

def scalar_literal_bit_names(+names: ScalarLiteralNames, key: U32, valid: Bool) -> ScalarLiteralNames:
  match valid:
    case False{}: names
    case True{}:
      match names:
        case ScalarLiteralNames{word, None{}, second}: ScalarLiteralNames{word, Some{key}, second}
        case ScalarLiteralNames{word, first, None{}}: ScalarLiteralNames{word, first, Some{key}}
        case _: names

def scalar_literal_bit_result(+names: ScalarLiteralNames, key: U32, result: ArenaResult<Bool>) -> ArenaResult<ScalarLiteralBit>:
  match result:
    case ArenaResult{store, +valid}:
      {ArenaResult{store, ScalarLiteralBit{scalar_literal_bit_names(names, key, valid), valid}} : ArenaResult<ScalarLiteralBit>}

def scalar_literal_bit_key(store: ArenaStore, key: U32, +ns: String, +globals: Scope.ArenaGlobalScope, +names: ScalarLiteralNames) -> ArenaResult<ScalarLiteralBit>:
  match names:
    case ScalarLiteralNames{_, first, second}:
      match Bool.or(scalar_literal_name_hit(key, first), scalar_literal_name_hit(key, second)):
        case True{}: {ArenaResult{store, ScalarLiteralBit{names, True{}}} : ArenaResult<ScalarLiteralBit>}
        case False{}: scalar_literal_bit_result(names, key, scalar_closed_bit_name(store, key, ns, globals))

def scalar_closed_bit(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope, names: ScalarLiteralNames) -> ArenaResult<ScalarLiteralBit>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match node:
    case Arena.TermCtr{key, _, count, _}:
      match U32.is_eq(count, 0):
        case True{}: scalar_literal_bit_key(store, key, ns, globals, names)
        case False{}: {ArenaResult{store, ScalarLiteralBit{names, False{}}} : ArenaResult<ScalarLiteralBit>}
    case _: {ArenaResult{store, ScalarLiteralBit{names, False{}}} : ArenaResult<ScalarLiteralBit>}

def scalar_literal_word_owner(store: ArenaStore, key: U32, +ns: String, +globals: Scope.ArenaGlobalScope, names: ScalarLiteralNames) -> ArenaResult<Bool>:
  match names:
    case ScalarLiteralNames{word, _, _}:
      match scalar_literal_name_hit(key, word):
        case True{}: {ArenaResult{store, True{}} : ArenaResult<Bool>}
        case False{}: scalar_schema_name(store, key, ns, globals, "WCon", True{})

def scalar_literal_word_names(+names: ScalarLiteralNames, key: U32, valid: Bool) -> ScalarLiteralNames:
  match valid:
    case False{}: names
    case True{}:
      match names:
        case ScalarLiteralNames{None{}, first, second}: ScalarLiteralNames{Some{key}, first, second}
        case _: names

def scalar_closed_word_walk(store: ArenaStore, id: U32, +ns: String, +globals: Scope.ArenaGlobalScope, remaining: Nat, +names: ScalarLiteralNames) -> ArenaResult<Bool>:
  ArenaResult{store, +node} = arena_get_node(store, id)
  match remaining:
    case 0n:
      match node:
        case Arena.TermCtr{key, _, count, _}:
          match U32.is_eq(count, 0):
            case True{}:
              scalar_schema_name(store, key, ns, globals, "WNil", True{})
            case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
        case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case 1n+rest:
      match node:
        case Arena.TermCtr{key, start, count, _}:
          match U32.is_eq(count, 2):
            case True{}:
              ArenaResult{store, +valid_owner} = scalar_literal_word_owner(store, key, ns, globals, names)
              +names = scalar_literal_word_names(names, key, valid_owner)
              ArenaResult{store, +bit} = arena_get_word(store, start)
              ArenaResult{store, ScalarLiteralBit{names, valid_bit}} = scalar_closed_bit(store, bit, ns, globals, names)
              ArenaResult{store, +tail} = arena_get_word(store, arena_range_index(start, 1))
              ArenaResult{store, +valid_tail} = scalar_closed_word_walk(store, tail, ns, globals, rest, names)
              {ArenaResult{store, Bool.and(valid_owner, Bool.and(valid_bit, valid_tail))} : ArenaResult<Bool>}
            case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
        case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_closed_word(store: ArenaStore, id: U32, ns: String, globals: Scope.ArenaGlobalScope, remaining: Nat) -> ArenaResult<Bool>:
  scalar_closed_word_walk(store, id, ns, globals, remaining, ScalarLiteralNames{None{}, None{}, None{}})

def scalar_schema_common(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +bool_family} = scalar_global_Bool_GlobalFamily(store, ns, globals)
  ArenaResult{store, +false_ctor} = scalar_global_False_GlobalConstructor(store, ns, globals)
  ArenaResult{store, +true_ctor} = scalar_global_True_GlobalConstructor(store, ns, globals)
  ArenaResult{store, +nat_family} = scalar_global_Nat_GlobalFamily(store, ns, globals)
  ArenaResult{store, +zero_ctor} = scalar_global_Zero_GlobalConstructor(store, ns, globals)
  ArenaResult{store, +succ_ctor} = scalar_global_Succ_GlobalConstructor(store, ns, globals)
  ArenaResult{store, +nil_family} = scalar_global_Word_Nil_GlobalFamily(store, ns, globals)
  ArenaResult{store, +nil_ctor} = scalar_global_WNil_GlobalConstructor(store, ns, globals)
  ArenaResult{store, +con_family} = scalar_global_Word_Con_GlobalFamily(store, ns, globals)
  ArenaResult{store, +con_ctor} = scalar_global_WCon_GlobalConstructor(store, ns, globals)
  ArenaResult{store, +word_definition} = scalar_global_Word_GlobalDefinition(store, ns, globals)
  {ArenaResult{store, Bool.and(bool_family, Bool.and(false_ctor, Bool.and(true_ctor, Bool.and(nat_family, Bool.and(zero_ctor, Bool.and(succ_ctor, Bool.and(nil_family, Bool.and(nil_ctor, Bool.and(con_family, Bool.and(con_ctor, word_definition))))))))))} : ArenaResult<Bool>}

def scalar_schema_builtin(store: ArenaStore, +ns: String, +globals: Scope.ArenaGlobalScope, name: String) -> ArenaResult<Bool>:
  match String.eq(name, "U32"):
    case True{}:
      ArenaResult{store, +family} = scalar_global_U32_GlobalFamily(store, ns, globals)
      ArenaResult{store, +constructor} = scalar_global_U32_GlobalConstructor(store, ns, globals)
      ArenaResult{store, +common} = scalar_schema_common(store, ns, globals)
      {ArenaResult{store, Bool.and(family, Bool.and(constructor, common))} : ArenaResult<Bool>}
    case False{}:
      match String.eq(name, "F32"):
        case True{}:
          ArenaResult{store, +family} = scalar_global_F32_GlobalFamily(store, ns, globals)
          ArenaResult{store, +constructor} = scalar_global_F32_GlobalConstructor(store, ns, globals)
          ArenaResult{store, +common} = scalar_schema_common(store, ns, globals)
          {ArenaResult{store, Bool.and(family, Bool.and(constructor, common))} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}

# Reuse is confined to one definition_term_inference invocation. That entry
# installs ScalarSchemaOpen with its exact immutable scope; its typing closure
# threads this scope unchanged, and scalar_frame_finish clears the lane before
# declaration publication, alias refresh or another definition can change it.
# Literal observation may append source nodes, but never changes existing scope
# records/handles or rewinds source storage. Memo collisions invalidate reuse.
# The selected constructor comparison is not a general scope-equality key.
# General callers without an owned definition frame validate the whole schema.
def scalar_frame_store(store: ArenaStore, entry: Arena.SubstMemoEntry) -> ArenaStore:
  match store:
    case ArenaStore{source, transient}: ArenaStore{Arena.scalar_frame_set(source, entry), transient}

def scalar_schema_prepare_result(+scope: Scope.ArenaGlobalScope, +selected: Scope.ArenaGlobal, result: ArenaResult<Bool>) -> ArenaResult<Bool>:
  match result:
    case ArenaResult{store, +valid}:
      {ArenaResult{scalar_frame_store(store, Arena.ScalarSchemaSaved{scope, selected, valid}), valid} : ArenaResult<Bool>}

def scalar_schema_prepare(store: ArenaStore, +scope: Scope.ArenaGlobalScope, +selected: Scope.ArenaGlobal, +ns: String, +globals: Scope.ArenaGlobalScope, local: String) -> ArenaResult<Bool>:
  scalar_schema_prepare_result(scope, selected, scalar_schema_builtin(store, ns, globals, local))

def scalar_schema_prepared_entry(store: ArenaStore, entry: Arena.SubstMemoEntry, +selected: Scope.ArenaGlobal, +ns: String, +globals: Scope.ArenaGlobalScope, local: String) -> ArenaResult<Bool>:
  match entry:
    case Arena.ScalarSchemaOpen{scope}:
      scalar_schema_prepare(store, scope, selected, ns, globals, local)
    case Arena.StringSchemaSaved{scope, _, _}:
      scalar_schema_prepare(store, scope, selected, ns, globals, local)
    case Arena.ScalarSchemaSaved{scope, saved, valid}:
      match scalar_global_identity(Some{selected}, Some{saved}):
        case True{}: {ArenaResult{store, valid} : ArenaResult<Bool>}
        case False{}: scalar_schema_prepare(store, scope, selected, ns, globals, local)
    case _: scalar_schema_builtin(store, ns, globals, local)

def scalar_schema_prepared_result(transient: Arena.Arena, +selected: Scope.ArenaGlobal, +ns: String, +globals: Scope.ArenaGlobalScope, local: String, result: Arena.Arena & Arena.SubstMemoEntry) -> ArenaResult<Bool>:
  match result:
    case Tuple{source, entry}:
      scalar_schema_prepared_entry(ArenaStore{source, transient}, entry, selected, ns, globals, local)

def scalar_schema_prepared(store: ArenaStore, +selected: Scope.ArenaGlobal, +ns: String, +globals: Scope.ArenaGlobalScope, local: String) -> ArenaResult<Bool>:
  match store:
    case ArenaStore{source, transient}:
      scalar_schema_prepared_result(transient, selected, ns, globals, local, Arena.scalar_frame_get(source))

def scalar_certificate_global(store: ArenaStore, +selected: Maybe<&2, Scope.ArenaGlobal>, +goal: String, start: U32, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match selected:
    case Some{Scope.ArenaGlobal{key, ns, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}}:
      match Bool.and(String.eq(Scope.canonical_name(goal, globals), key), Bool.and(scalar_global_identity(selected, Scope.lookup_kind(canonical_key(ns, local), Scope.GlobalConstructor{}, globals)), scalar_reference_identity(goal, ns, globals, local))):
        case True{}:
          ArenaResult{store, +schemas} = scalar_schema_prepared(store, Scope.ArenaGlobal{key, ns, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}, ns, globals, local)
          match schemas:
            case True{}:
              ArenaResult{store, +word} = arena_get_word(store, start)
              scalar_closed_word(store, word, ns, globals, 32n)
            case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_constructor_certificate(store: ArenaStore, goal_key: U32, goal_args: U32, exclusions: U32, +name: String, fields: IR.Words, +globals: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match U32.is_eq(goal_args, 0):
    case True{}:
      match U32.is_eq(exclusions, 0):
        case True{}:
          match fields:
            case IR.Words{start, count}:
              match U32.is_eq(count, 1):
                case True{}:
                  ArenaResult{store, +goal} = arena_name_text(store, goal_key)
                  scalar_certificate_global(store, Scope.lookup_kind(name, Scope.GlobalConstructor{}, globals), goal, start, globals)
                case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
            case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def scalar_constructor_dispatch(store: ArenaStore, certified: Bool, name: String, fields: IR.Words, span: Ast.SourceSpan, parameters: IR.Words, exclusions: IR.Names, goal: U32, env: List<&2, Binding>, globals: Scope.ArenaGlobalScope, term: U32, view: U32) -> ArenaResult<Inference>:
  match certified:
    case True{}: {ArenaResult{store, Inferred{term, goal}} : ArenaResult<Inference>}
    case False{}:
      ArenaResult{store, +excluded} = has_canonical_name(store, name, exclusions, globals)
      check_term_constructor_allowed(store, excluded, name, fields, span, parameters, exclusions, goal, env, globals, term, view)


def check_term_constructor_view(v_1: ArenaStore, v_3: U32, v_5: String, v_6: IR.Words, v_7: Ast.SourceSpan, v_9: U32, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope, v_15: U32) -> ArenaResult<Inference>:
  ArenaResult{v_22, +v_23} = arena_get_node(v_1, v_3)
  match v_23:
    case Arena.TermAdt{+v_30, +v_31, +v_32, +v_33, +v_34, +v_35}:
      +v_37 = IR.Words{v_31, v_32}
      +v_39 = IR.Names{v_33, v_34}
      v_41 = v_37
      v_43 = v_39
      ArenaResult{v_47, +v_48} = scalar_constructor_certificate(v_22, v_30, v_32, v_34, v_5, v_6, v_13)
      ArenaResult{v_52, +v_53} = scalar_constructor_dispatch(v_47, v_48, v_5, v_6, v_7, v_41, v_43, v_9, v_12, v_13, v_15, v_3)
      {ArenaResult{v_52, v_53} : ArenaResult<Inference>}
    case _:
      v_50000231 = fail(v_7, "constructor requires a datatype goal", "a datatype", "a non-datatype type")
      {ArenaResult{v_22, v_50000231} : ArenaResult<Inference>}

def check_term_absurd_residual(v_1: Bool, v_2: U32, v_3: Ast.SourceSpan, v_4: U32) -> Inference:
  +v_20037814 = v_1
  match v_20037814:
    case False{}:
      +v_20037813 = Inferred{v_2, v_4}
      v_20037813
    case True{}:
      +v_20037813 = fail(v_3, "match is not exhaustive", "all remaining constructors", "an uncovered constructor")
      v_20037813

def check_term_absurd_input_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: Ast.SourceSpan, v_8: U32, v_9: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  ArenaResult{v_16, +v_17} = arena_get_node(v_1, v_3)
  match v_17:
    case Arena.TermAdt{+v_24, +v_25, +v_26, +v_27, +v_28, +v_29}:
      ArenaResult{v_33, +v_34} = arena_name_text(v_16, v_24)
      +v_36 = v_34
      +v_38 = IR.Words{v_25, v_26}
      +v_40 = IR.Names{v_27, v_28}
      v_42 = v_36
      v_44 = v_38
      v_46 = v_40
      v_48 = v_29
      ArenaResult{v_53, +v_54} = residual_has_reachable_constructor(v_33, Scope.canonical_name(v_42, v_9), v_44, v_46, v_48, v_9)
      v_50000232 = check_term_absurd_residual(v_54, v_5, v_6, v_8)
      {ArenaResult{v_53, v_50000232} : ArenaResult<Inference>}
    case _:
      v_50000233 = fail(v_6, "absurd match requires a datatype", "a datatype", "a non-datatype")
      {ArenaResult{v_16, v_50000233} : ArenaResult<Inference>}

def check_term_absurd_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: Ast.SourceSpan, v_8: U32, v_9: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  ArenaResult{v_16, +v_17} = arena_get_node(v_1, v_3)
  match v_17:
    case Arena.TermAll{+v_24, +v_25, +v_26, +v_27, +v_28, +v_29}:
      v_31 = v_27
      ArenaResult{v_35, +v_36} = whnf(v_16, 64n, v_31, v_9)
      ArenaResult{v_40, +v_41} = check_term_absurd_input_view(v_35, v_36, v_5, v_6, v_8, v_9)
      {ArenaResult{v_40, v_41} : ArenaResult<Inference>}
    case _:
      v_50000234 = fail(v_6, "absurd match requires a function goal", "a dependent function type", "a non-function type")
      {ArenaResult{v_16, v_50000234} : ArenaResult<Inference>}

def check_term_refl_equal(v_1: Bool, v_2: U32, v_3: Ast.SourceSpan, v_4: U32) -> Inference:
  +v_20037858 = v_1
  match v_20037858:
    case False{}:
      +v_20037857 = fail(v_3, "refl endpoints are not convertible", "equal endpoints", "unequal endpoints")
      v_20037857
    case True{}:
      +v_20037857 = Inferred{v_2, v_4}
      v_20037857

def check_term_refl_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: Ast.SourceSpan, v_8: U32, v_9: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  ArenaResult{v_16, +v_17} = arena_get_node(v_1, v_3)
  match v_17:
    case Arena.TermEqual{+v_22, +v_23, +v_24, +v_25}:
      v_27 = v_22
      v_29 = v_23
      ArenaResult{v_33, +v_34} = equal_term(v_16, v_27, v_29, v_9)
      v_50000235 = check_term_refl_equal(v_34, v_5, v_6, v_8)
      {ArenaResult{v_33, v_50000235} : ArenaResult<Inference>}
    case _:
      v_50000236 = fail(v_6, "refl requires an equation type", "an equation type", "a non-equation")
      {ArenaResult{v_16, v_50000236} : ArenaResult<Inference>}

def check_term_inferred(v_20037873: ArenaStore, v_1: Inference, v_2: U32, v_3: U32, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_1:
    case Inferred{+v_20037874, +v_20037875}:
      v_8 = v_20037874
      v_9 = v_20037875
      ArenaResult{v_20037878, +v_20037879} = fits_term(v_20037873, v_9, v_2, v_4)
      +v_20037880 = v_20037879
      match v_20037880:
        case False{}:
          ArenaResult{v_20037881, +v_20037882} = term_span(v_20037878, v_3)
          +v_20037876 = fail(v_20037882, "term has the wrong type", "the expected type", "an incompatible type")
          v_20037877 = v_20037881
          {ArenaResult{v_20037877, v_20037876} : ArenaResult<Inference>}
        case True{}:
          +v_20037876 = Inferred{v_8, v_2}
          v_20037877 = v_20037878
          {ArenaResult{v_20037877, v_20037876} : ArenaResult<Inference>}
    case InferenceFailure{+v_20037883}:
      v_15 = v_20037883
      {ArenaResult{v_20037873, InferenceFailure{v_15}} : ArenaResult<Inference>}

def check_term(v_20037884: ArenaStore, v_0: U32, v_3: List<&2, Binding>, v_4: Scope.ArenaGlobalScope, v_5: U32) -> ArenaResult<Inference>:
  ArenaResult{v_20037885, +v_20037886} = arena_get_node(v_20037884, v_0)
  match v_20037886:
    case Arena.TermHole{+v_20037889, +v_20037891}:
      ArenaResult{v_20037892, +v_20037893} = arena_name_text(v_20037885, v_20037889)
      +v_20037890 = v_20037893
      v_9 = v_20037890
      v_10 = v_20037891
      +v_20037896 = String.eq(v_9, "TODO")
      match v_20037896:
        case False{}:
          +v_20037894 = fail(v_10, String.append("unsolved hole ", v_9), "a complete term", "a hole")
          v_20037895 = v_20037892
          {ArenaResult{v_20037895, v_20037894} : ArenaResult<Inference>}
        case True{}:
          +v_20037894 = Inferred{v_0, v_5}
          v_20037895 = v_20037892
          {ArenaResult{v_20037895, v_20037894} : ArenaResult<Inference>}
    case Arena.TermLam{+v_20037902, +v_20037903, +v_20037905, +v_20037906, +v_20037907}:
      ArenaResult{v_20037908, +v_20037909} = arena_name_text(v_20037885, v_20037903)
      +v_20037904 = v_20037909
      v_18 = v_20037902
      v_19 = v_20037904
      v_21 = v_20037906
      v_22 = v_20037907
      ArenaResult{v_20037910, +v_20037911} = whnf(v_20037908, 64n, v_5, v_4)
      ArenaResult{v_20037912, +v_20037913} = check_term_lambda_view(v_20037910, v_20037911, v_18, v_19, v_21, v_22, v_5, v_3, v_4)
      {ArenaResult{v_20037912, v_20037913} : ArenaResult<Inference>}
    case Arena.TermString{chars, names, span}:
      check_string_literal(v_20037885, v_0, chars, names, span, v_3, v_4, v_5)
    case Arena.TermCtr{+v_20037917, +v_20037919, +v_20037920, +v_20037922}:
      ArenaResult{v_20037923, +v_20037924} = arena_name_text(v_20037885, v_20037917)
      +v_20037918 = v_20037924
      +v_20037921 = IR.Words{v_20037919, v_20037920}
      v_28 = v_20037918
      v_29 = v_20037921
      v_30 = v_20037922
      ArenaResult{v_20037925, +v_20037926} = whnf(v_20037923, 64n, v_5, v_4)
      ArenaResult{v_20037927, +v_20037928} = check_term_constructor_view(v_20037925, v_20037926, v_28, v_29, v_30, v_5, v_3, v_4, v_0)
      {ArenaResult{v_20037927, v_20037928} : ArenaResult<Inference>}
    case Arena.TermMat{+v_20037933, +v_20037935, +v_20037936, +v_20037937}:
      ArenaResult{v_20037938, +v_20037939} = arena_name_text(v_20037885, v_20037933)
      +v_20037934 = v_20037939
      v_37 = v_20037934
      v_38 = v_20037935
      v_39 = v_20037936
      v_40 = v_20037937
      ArenaResult{v_20037940, +v_20037941} = check_match(v_20037938, v_37, v_38, v_39, v_40, v_5, v_3, v_4, v_0)
      {ArenaResult{v_20037940, v_20037941} : ArenaResult<Inference>}
    case Arena.TermAbsurd{+v_20037943}:
      v_43 = v_20037943
      ArenaResult{v_20037944, +v_20037945} = whnf(v_20037885, 64n, v_5, v_4)
      ArenaResult{v_20037946, +v_20037947} = check_term_absurd_view(v_20037944, v_20037945, v_0, v_43, v_5, v_4)
      {ArenaResult{v_20037946, v_20037947} : ArenaResult<Inference>}
    case Arena.TermRefl{+v_20037949}:
      v_47 = v_20037949
      ArenaResult{v_20037950, +v_20037951} = whnf(v_20037885, 64n, v_5, v_4)
      ArenaResult{v_20037952, +v_20037953} = check_term_refl_view(v_20037950, v_20037951, v_0, v_47, v_5, v_4)
      {ArenaResult{v_20037952, v_20037953} : ArenaResult<Inference>}
    case Arena.TermRewrite{+v_20037958, +v_20037959, +v_20037960, +v_20037961}:
      v_54 = v_20037958
      v_55 = v_20037959
      v_56 = v_20037960
      v_57 = v_20037961
      ArenaResult{v_20037962, +v_20037963} = check_rewrite(v_20037885, v_54, v_55, v_56, v_57, v_5, v_3, v_4, v_0)
      {ArenaResult{v_20037962, v_20037963} : ArenaResult<Inference>}
    case Arena.BodyLocal{+v_20037969, +v_20037970, +v_20037972, +v_20037973, +v_20037974, +v_20037976, +v_20037977}:
      +v_20037971 = IR.Words{v_20037969, v_20037970}
      +v_20037975 = IR.Words{v_20037973, v_20037974}
      ArenaResult{v_20037978, +v_20037979} = arena_words_view(v_20037885, v_20037971)
      match v_20037979:
        case IR.WordCons{+v_20037984, +v_20037985}:
          ArenaResult{v_20037986, +v_20037987} = arena_get_pattern(v_20037978, v_20037984)
          match v_20037987:
            case Arena.PatternCtr{+v_20037994, +v_20037996, +v_20037997, +v_20037999}:
              ArenaResult{v_20038000, +v_20038001} = arena_name_text(v_20037986, v_20037994)
              +v_20037995 = v_20038001
              +v_20037998 = IR.Words{v_20037996, v_20037997}
              ArenaResult{v_20038002, +v_20038003} = arena_words_view(v_20038000, v_20037985)
              match v_20038003:
                case IR.WordNil{}:
                  match v_20037972:
                    case Ast.QOne{}:
                      ArenaResult{v_20038004, +v_20038005} = arena_words_view(v_20038002, v_20037975)
                      match v_20038005:
                        case IR.WordCons{+v_20038010, +v_20038011}:
                          ArenaResult{v_20038012, +v_20038013} = arena_words_view(v_20038004, v_20038011)
                          match v_20038013:
                            case IR.WordNil{}:
                              v_68 = v_20038010
                              v_65 = v_20037995
                              v_66 = v_20037998
                              v_67 = v_20037999
                              v_69 = v_20037976
                              v_70 = v_20037977
                              ArenaResult{v_20038014, +v_20038015} = destructuring_local_match(v_20038012, v_65, v_66, v_67, v_68, v_69, v_70)
                              ArenaResult{v_20038016, +v_20038017} = check_term(v_20038014, v_20038015, v_3, v_4, v_5)
                              {ArenaResult{v_20038016, v_20038017} : ArenaResult<Inference>}
                            case _:
                              v_78 = v_20037971
                              v_79 = v_20037972
                              v_80 = v_20037975
                              v_81 = v_20037976
                              v_82 = v_20037977
                              ArenaResult{v_20038019, +v_20038020} = core_pattern_list_depth(v_20038012, v_78)
                              ArenaResult{v_20038021, +v_20038022} = core_shift(v_20038019, 0n, v_20038020, v_5)
                              v_84 = v_20038022
                              ArenaResult{v_20038023, +v_20038024} = arena_put_node(v_20038021, Arena.TermAnn{v_81, v_84, v_82})
                              ArenaResult{v_20038025, +v_20038026} = check_body_local(v_20038023, v_78, v_79, v_80, v_20038024, v_82, v_3, v_4)
                              {ArenaResult{v_20038025, v_20038026} : ArenaResult<Inference>}
                        case _:
                          v_78 = v_20037971
                          v_79 = v_20037972
                          v_80 = v_20037975
                          v_81 = v_20037976
                          v_82 = v_20037977
                          ArenaResult{v_20038028, +v_20038029} = core_pattern_list_depth(v_20038004, v_78)
                          ArenaResult{v_20038030, +v_20038031} = core_shift(v_20038028, 0n, v_20038029, v_5)
                          v_84 = v_20038031
                          ArenaResult{v_20038032, +v_20038033} = arena_put_node(v_20038030, Arena.TermAnn{v_81, v_84, v_82})
                          ArenaResult{v_20038034, +v_20038035} = check_body_local(v_20038032, v_78, v_79, v_80, v_20038033, v_82, v_3, v_4)
                          {ArenaResult{v_20038034, v_20038035} : ArenaResult<Inference>}
                    case _:
                      v_78 = v_20037971
                      v_79 = v_20037972
                      v_80 = v_20037975
                      v_81 = v_20037976
                      v_82 = v_20037977
                      ArenaResult{v_20038037, +v_20038038} = core_pattern_list_depth(v_20038002, v_78)
                      ArenaResult{v_20038039, +v_20038040} = core_shift(v_20038037, 0n, v_20038038, v_5)
                      v_84 = v_20038040
                      ArenaResult{v_20038041, +v_20038042} = arena_put_node(v_20038039, Arena.TermAnn{v_81, v_84, v_82})
                      ArenaResult{v_20038043, +v_20038044} = check_body_local(v_20038041, v_78, v_79, v_80, v_20038042, v_82, v_3, v_4)
                      {ArenaResult{v_20038043, v_20038044} : ArenaResult<Inference>}
                case _:
                  v_78 = v_20037971
                  v_79 = v_20037972
                  v_80 = v_20037975
                  v_81 = v_20037976
                  v_82 = v_20037977
                  ArenaResult{v_20038046, +v_20038047} = core_pattern_list_depth(v_20038002, v_78)
                  ArenaResult{v_20038048, +v_20038049} = core_shift(v_20038046, 0n, v_20038047, v_5)
                  v_84 = v_20038049
                  ArenaResult{v_20038050, +v_20038051} = arena_put_node(v_20038048, Arena.TermAnn{v_81, v_84, v_82})
                  ArenaResult{v_20038052, +v_20038053} = check_body_local(v_20038050, v_78, v_79, v_80, v_20038051, v_82, v_3, v_4)
                  {ArenaResult{v_20038052, v_20038053} : ArenaResult<Inference>}
            case _:
              v_78 = v_20037971
              v_79 = v_20037972
              v_80 = v_20037975
              v_81 = v_20037976
              v_82 = v_20037977
              ArenaResult{v_20038055, +v_20038056} = core_pattern_list_depth(v_20037986, v_78)
              ArenaResult{v_20038057, +v_20038058} = core_shift(v_20038055, 0n, v_20038056, v_5)
              v_84 = v_20038058
              ArenaResult{v_20038059, +v_20038060} = arena_put_node(v_20038057, Arena.TermAnn{v_81, v_84, v_82})
              ArenaResult{v_20038061, +v_20038062} = check_body_local(v_20038059, v_78, v_79, v_80, v_20038060, v_82, v_3, v_4)
              {ArenaResult{v_20038061, v_20038062} : ArenaResult<Inference>}
        case _:
          v_78 = v_20037971
          v_79 = v_20037972
          v_80 = v_20037975
          v_81 = v_20037976
          v_82 = v_20037977
          ArenaResult{v_20038064, +v_20038065} = core_pattern_list_depth(v_20037978, v_78)
          ArenaResult{v_20038066, +v_20038067} = core_shift(v_20038064, 0n, v_20038065, v_5)
          v_84 = v_20038067
          ArenaResult{v_20038068, +v_20038069} = arena_put_node(v_20038066, Arena.TermAnn{v_81, v_84, v_82})
          ArenaResult{v_20038070, +v_20038071} = check_body_local(v_20038068, v_78, v_79, v_80, v_20038069, v_82, v_3, v_4)
          {ArenaResult{v_20038070, v_20038071} : ArenaResult<Inference>}
    case Arena.BodyMatch{+v_20038075, +v_20038076, +v_20038078, +v_20038079, +v_20038081}:
      +v_20038077 = IR.Words{v_20038075, v_20038076}
      +v_20038080 = IR.Words{v_20038078, v_20038079}
      v_89 = v_20038077
      v_90 = v_20038080
      v_91 = v_20038081
      ArenaResult{v_20038082, +v_20038083} = check_body_match(v_20037885, v_89, v_90, v_91, v_5, v_3, v_4, v_0)
      {ArenaResult{v_20038082, v_20038083} : ArenaResult<Inference>}
    case Arena.BodyReply{+v_20038086, +v_20038087}:
      v_94 = v_20038086
      ArenaResult{v_20038088, +v_20038089} = check_term(v_20037885, v_94, v_3, v_4, v_5)
      {ArenaResult{v_20038088, v_20038089} : ArenaResult<Inference>}
    case _:
      ArenaResult{v_20038091, +v_20038092} = infer(v_20037885, v_0, v_3, v_4)
      ArenaResult{v_20038093, +v_20038094} = check_term_inferred(v_20038091, v_20038092, v_5, v_0, v_4)
      {ArenaResult{v_20038093, v_20038094} : ArenaResult<Inference>}

def usage_get(v_1: Nat, v_4: List<&2, UsageEntry>) -> Ast.Quantity:
  match v_4:
    case []:
      Ast.QZero{}
    case +v_20038095 <> +v_20038096:
      +v_7 = v_20038095
      v_8 = v_20038096
      match v_7:
        case Usage{+v_20038097, +v_20038098}:
          v_11 = v_20038097
          v_12 = v_20038098
          +v_20038100 = Nat.is_eq(v_11, v_1)
          match v_20038100:
            case False{}:
              +v_20038099 = usage_get(v_1, v_8)
              v_20038099
            case True{}:
              +v_20038099 = v_12
              v_20038099

def usage_set(v_1: Nat, v_2: Ast.Quantity, v_5: List<&2, UsageEntry>) -> List<&2, UsageEntry>:
  match v_5:
    case []:
      [Usage{v_1, v_2}]
    case +v_10 <> +v_11:
      +v_13 = v_10
      v_15 = v_11
      match v_13:
        case Usage{+v_18, +v_19}:
          v_21 = v_18
          +v_23 = Nat.is_eq(v_21, v_1)
          match v_23:
            case False{}:
              v_50000237 = usage_set(v_1, v_2, v_15)
              +v_26 = v_13 <> v_50000237
              v_26
            case True{}:
              +v_29 = Usage{v_1, v_2} <> v_15
              v_29

def usage_merge(v_2: List<&2, UsageEntry>, v_5: List<&2, UsageEntry>, v_7: Bool) -> List<&2, UsageEntry>:
  match v_5:
    case []:
      v_2
    case +v_20038107 <> +v_20038108:
      +v_12 = v_20038107
      v_13 = v_20038108
      match v_12:
        case Usage{+v_20038109, +v_20038110}:
          v_16 = v_20038109
          v_17 = v_20038110
          v_20 = usage_get(v_16, v_2)
          v_23 = usage_merge_quantity(v_7, v_20, v_17)
          usage_merge(usage_set(v_16, v_23, v_2), v_13, v_7)

def usage_merge_quantity(v_1: Bool, v_2: Ast.Quantity, v_3: Ast.Quantity) -> Ast.Quantity:
  match v_1:
    case True{}:
      quantity_alternative(v_2, v_3)
    case False{}:
      quantity_join(v_2, v_3)

def function_type_of_binding_result(v_20038111: ArenaStore, v_2: Maybe<&2, Binding>, v_4: Nat) -> ArenaResult<Maybe<&2, U32>>:
  match v_2:
    case None{}:
      {ArenaResult{v_20038111, None{}} : ArenaResult<Maybe<&2, U32>>}
    case Some{+v_20038112}:
      v_7 = v_20038112
      ArenaResult{v_20038113, +v_20038114} = binding_type_at(v_20038111, v_7, v_4)
      {ArenaResult{v_20038113, Some{v_20038114}} : ArenaResult<Maybe<&2, U32>>}

def function_type_of_global_result(v_1: Maybe<&2, Scope.ArenaGlobal>) -> Maybe<&2, U32>:
  match v_1:
    case None{}:
      None{}
    case Some{+v_20038115}:
      v_4 = v_20038115
      match v_4:
        case Scope.ArenaGlobal{+v_20038116, +v_20038117, +v_20038118, +v_20038119, +v_20038120, +v_20038121}:
          v_14 = v_20038119
          Some{v_14}

def function_type_of_application_view(v_20038122: ArenaStore, v_0: U32, v_1: U32) -> ArenaResult<Maybe<&2, U32>>:
  ArenaResult{v_20038123, +v_20038124} = arena_get_node(v_20038122, v_0)
  match v_20038124:
    case Arena.TermAll{+v_20038131, +v_20038132, +v_20038134, +v_20038135, +v_20038136, +v_20038137}:
      v_13 = v_20038136
      ArenaResult{v_20038138, +v_20038139} = core_subst(v_20038123, 0n, v_1, v_13)
      {ArenaResult{v_20038138, Some{v_20038139}} : ArenaResult<Maybe<&2, U32>>}
    case _:
      {ArenaResult{v_20038123, None{}} : ArenaResult<Maybe<&2, U32>>}

def function_type_of_application_result(v_20038141: ArenaStore, v_1: Maybe<&2, U32>, v_2: U32, v_5: List<&2, Binding>, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  match v_1:
    case None{}:
      {ArenaResult{v_20038141, None{}} : ArenaResult<Maybe<&2, U32>>}
    case Some{+v_20038142}:
      v_9 = v_20038142
      ArenaResult{v_20038143, +v_20038144} = whnf(v_20038141, 64n, v_9, v_6)
      ArenaResult{v_20038145, +v_20038146} = function_type_of_application_view(v_20038143, v_20038144, v_2)
      {ArenaResult{v_20038145, v_20038146} : ArenaResult<Maybe<&2, U32>>}

def function_type_of(v_1: ArenaStore, v_3: U32, v_6: List<&2, Binding>, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  ArenaResult{v_15, +v_16} = arena_get_node(v_1, v_3)
  match v_16:
    case Arena.TermBang{+v_19, +v_20}:
      v_22 = v_19
      ArenaResult{v_26, +v_27} = function_type_of(v_15, v_22, v_6, v_7)
      {ArenaResult{v_26, v_27} : ArenaResult<Maybe<&2, U32>>}
    case Arena.TermSub{+v_32, +v_33, +v_34, +v_35}:
      v_37 = v_32
      v_39 = v_33
      v_41 = v_34
      ArenaResult{v_45, +v_46} = core_subst(v_15, v_37, v_39, v_41)
      ArenaResult{v_50, +v_51} = function_type_of(v_45, v_46, v_6, v_7)
      {ArenaResult{v_50, v_51} : ArenaResult<Maybe<&2, U32>>}
    case Arena.TermAnn{+v_55, +v_56, +v_57}:
      v_59 = v_56
      {ArenaResult{v_15, Some{v_59}} : ArenaResult<Maybe<&2, U32>>}
    case Arena.TermVar{+v_63, +v_64, +v_65}:
      v_67 = v_64
      ArenaResult{v_73, +v_74} = function_type_of_binding_result(v_15, lookup_binding(v_67, v_6), List.length(&2, Binding, v_6))
      {ArenaResult{v_73, v_74} : ArenaResult<Maybe<&2, U32>>}
    case Arena.TermRef{+v_77, +v_78}:
      ArenaResult{v_82, +v_83} = arena_name_text(v_15, v_77)
      +v_85 = v_83
      v_87 = v_85
      v_50000238 = function_type_of_global_result(Scope.lookup(v_87, v_7))
      {ArenaResult{v_82, v_50000238} : ArenaResult<Maybe<&2, U32>>}
    case Arena.TermApp{+v_93, +v_94, +v_95}:
      v_97 = v_93
      v_99 = v_94
      ArenaResult{v_103, +v_104} = function_type_of(v_15, v_97, v_6, v_7)
      ArenaResult{v_108, +v_109} = function_type_of_application_result(v_103, v_104, v_99, v_6, v_7)
      {ArenaResult{v_108, v_109} : ArenaResult<Maybe<&2, U32>>}
    case _:
      {ArenaResult{v_15, None{}} : ArenaResult<Maybe<&2, U32>>}

def function_quantity_from_type_view(v_20038201: ArenaStore, v_0: U32) -> ArenaResult<Maybe<&2, Ast.Quantity>>:
  ArenaResult{v_20038202, +v_20038203} = arena_get_node(v_20038201, v_0)
  match v_20038203:
    case Arena.TermAll{+v_20038210, +v_20038211, +v_20038213, +v_20038214, +v_20038215, +v_20038216}:
      v_8 = v_20038210
      {ArenaResult{v_20038202, Some{v_8}} : ArenaResult<Maybe<&2, Ast.Quantity>>}
    case _:
      {ArenaResult{v_20038202, None{}} : ArenaResult<Maybe<&2, Ast.Quantity>>}

def function_quantity_from_type(v_20038218: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Ast.Quantity>>:
  ArenaResult{v_20038219, +v_20038220} = whnf(v_20038218, 64n, v_0, v_1)
  ArenaResult{v_20038221, +v_20038222} = function_quantity_from_type_view(v_20038219, v_20038220)
  {ArenaResult{v_20038221, v_20038222} : ArenaResult<Maybe<&2, Ast.Quantity>>}

def function_argument_quantity_result(v_20038223: ArenaStore, v_1: Maybe<&2, U32>, v_2: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Ast.Quantity>>:
  match v_1:
    case Some{+v_20038224}:
      v_5 = v_20038224
      ArenaResult{v_20038225, +v_20038226} = function_quantity_from_type(v_20038223, v_5, v_2)
      {ArenaResult{v_20038225, v_20038226} : ArenaResult<Maybe<&2, Ast.Quantity>>}
    case None{}:
      {ArenaResult{v_20038223, None{}} : ArenaResult<Maybe<&2, Ast.Quantity>>}

def function_argument_quantity(v_20038227: ArenaStore, v_0: U32, v_3: List<&2, Binding>, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Ast.Quantity>>:
  ArenaResult{v_20038228, +v_20038229} = function_type_of(v_20038227, v_0, v_3, v_4)
  ArenaResult{v_20038230, +v_20038231} = function_argument_quantity_result(v_20038228, v_20038229, v_4)
  {ArenaResult{v_20038230, v_20038231} : ArenaResult<Maybe<&2, Ast.Quantity>>}

def collect_telescope_quantities_view(v_20038232: ArenaStore, v_0: U32, v_1: U32, v_3: Nat, v_4: Scope.ArenaGlobalScope) -> ArenaResult<IR.Quantities>:
  ArenaResult{v_20038233, +v_20038234} = arena_get_node(v_20038232, v_0)
  match v_20038234:
    case Arena.TermAll{+v_20038241, +v_20038242, +v_20038244, +v_20038245, +v_20038246, +v_20038247}:
      ArenaResult{v_20038248, +v_20038249} = arena_name_text(v_20038233, v_20038242)
      +v_20038243 = v_20038249
      v_12 = v_20038241
      v_13 = v_20038243
      v_15 = v_20038245
      v_16 = v_20038246
      ArenaResult{v_20038250, +v_20038251} = term_span(v_20038248, v_15)
      ArenaResult{v_20038252, +v_20038253} = arena_name(v_20038250, v_13)
      ArenaResult{v_20038254, +v_20038255} = arena_put_node(v_20038252, Arena.TermVar{v_20038253, v_3, v_20038251})
      v_20 = v_20038255
      ArenaResult{v_20038256, +v_20038257} = core_subst(v_20038254, 0n, v_20, v_16)
      ArenaResult{v_20038258, +v_20038259} = whnf(v_20038256, 64n, v_20038257, v_4)
      ArenaResult{v_20038260, +v_20038261} = core_subst(v_20038258, 0n, v_20, v_16)
      ArenaResult{v_20038262, +v_20038263} = collect_telescope_quantities_view(v_20038260, v_20038259, v_20038261, Nat.add(v_3, 1n), v_4)
      ArenaResult{v_20038264, +v_20038265} = arena_quantities_cons(v_20038262, v_12, v_20038263)
      {ArenaResult{v_20038264, v_20038265} : ArenaResult<IR.Quantities>}
    case _:
      {ArenaResult{v_20038233, IR.Quantities{0, 0}} : ArenaResult<IR.Quantities>}

def collect_telescope_quantities(v_20038267: ArenaStore, v_0: U32, v_2: Nat, v_3: Scope.ArenaGlobalScope) -> ArenaResult<IR.Quantities>:
  ArenaResult{v_20038268, +v_20038269} = whnf(v_20038267, 64n, v_0, v_3)
  ArenaResult{v_20038270, +v_20038271} = collect_telescope_quantities_view(v_20038268, v_20038269, v_0, v_2, v_3)
  {ArenaResult{v_20038270, v_20038271} : ArenaResult<IR.Quantities>}

def family_parameter_quantities_result(v_20038272: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_2: Scope.ArenaGlobalScope) -> ArenaResult<IR.Quantities>:
  match v_1:
    case None{}:
      {ArenaResult{v_20038272, IR.Quantities{0, 0}} : ArenaResult<IR.Quantities>}
    case Some{+v_20038273}:
      v_5 = v_20038273
      match v_5:
        case Scope.ArenaGlobal{+v_20038274, +v_20038275, +v_20038276, +v_20038277, +v_20038278, +v_20038279}:
          v_15 = v_20038277
          ArenaResult{v_20038280, +v_20038281} = collect_telescope_quantities(v_20038272, v_15, 0n, v_2)
          {ArenaResult{v_20038280, v_20038281} : ArenaResult<IR.Quantities>}

def family_parameter_quantities(v_20038282: ArenaStore, v_1: String, v_2: Scope.ArenaGlobalScope) -> ArenaResult<IR.Quantities>:
  ArenaResult{v_20038283, +v_20038284} = family_parameter_quantities_result(v_20038282, Scope.lookup(v_1, v_2), v_2)
  {ArenaResult{v_20038283, v_20038284} : ArenaResult<IR.Quantities>}

def constructor_field_quantities_family_global(v_20038285: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_2: U32, v_3: Scope.ArenaGlobalScope) -> ArenaResult<IR.Quantities>:
  match v_1:
    case None{}:
      {ArenaResult{v_20038285, IR.Quantities{0, 0}} : ArenaResult<IR.Quantities>}
    case Some{+v_20038286}:
      v_6 = v_20038286
      match v_6:
        case Scope.ArenaGlobal{+v_20038287, +v_20038288, +v_20038289, +v_20038290, +v_20038291, +v_20038292}:
          v_16 = v_20038290
          ArenaResult{v_20038293, +v_20038294} = initial_telescope_count(v_20038285, v_16, v_3)
          v_21 = v_20038294
          ArenaResult{v_20038295, +v_20038296} = drop_telescope(v_20038293, v_21, v_2, v_3)
          ArenaResult{v_20038297, +v_20038298} = collect_telescope_quantities(v_20038295, v_20038296, 0n, v_3)
          {ArenaResult{v_20038297, v_20038298} : ArenaResult<IR.Quantities>}

def constructor_field_quantities_family(v_20038299: ArenaStore, v_2: Maybe<&2, String>, v_3: U32, v_4: Scope.ArenaGlobalScope) -> ArenaResult<IR.Quantities>:
  match v_2:
    case None{}:
      {ArenaResult{v_20038299, IR.Quantities{0, 0}} : ArenaResult<IR.Quantities>}
    case Some{+v_20038300}:
      v_7 = v_20038300
      ArenaResult{v_20038301, +v_20038302} = constructor_field_quantities_family_global(v_20038299, Scope.lookup(Scope.canonical_name(v_7, v_4), v_4), v_3, v_4)
      {ArenaResult{v_20038301, v_20038302} : ArenaResult<IR.Quantities>}

def constructor_field_quantities_global(v_20038303: ArenaStore, v_0: Scope.ArenaGlobal, v_1: Scope.ArenaGlobalScope) -> ArenaResult<IR.Quantities>:
  match v_0:
    case Scope.ArenaGlobal{+v_20038304, +v_20038305, +v_20038306, +v_20038307, +v_20038308, +v_20038309}:
      v_12 = v_20038307
      ArenaResult{v_20038310, +v_20038311} = constructor_family(v_20038303, v_12, v_1)
      ArenaResult{v_20038312, +v_20038313} = constructor_field_quantities_family(v_20038310, v_20038311, v_12, v_1)
      {ArenaResult{v_20038312, v_20038313} : ArenaResult<IR.Quantities>}

def constructor_field_quantities_result(v_20038314: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_2: Scope.ArenaGlobalScope) -> ArenaResult<IR.Quantities>:
  match v_1:
    case None{}:
      {ArenaResult{v_20038314, IR.Quantities{0, 0}} : ArenaResult<IR.Quantities>}
    case Some{+v_20038315}:
      v_5 = v_20038315
      ArenaResult{v_20038316, +v_20038317} = constructor_field_quantities_global(v_20038314, v_5, v_2)
      {ArenaResult{v_20038316, v_20038317} : ArenaResult<IR.Quantities>}

def constructor_field_quantities(v_20038318: ArenaStore, v_1: String, v_2: Scope.ArenaGlobalScope) -> ArenaResult<IR.Quantities>:
  ArenaResult{v_20038319, +v_20038320} = constructor_field_quantities_result(v_20038318, Scope.lookup_kind(v_1, Scope.GlobalConstructor{}, v_2), v_2)
  {ArenaResult{v_20038319, v_20038320} : ArenaResult<IR.Quantities>}

def usage_unknown_type(v_20038321: ArenaStore, v_0: Ast.SourceSpan) -> ArenaResult<U32>:
  ArenaResult{v_20038322, +v_20038323} = arena_put_node(v_20038321, Arena.TermQuantity{Ast.QMany{}, v_0})
  ArenaResult{v_20038324, +v_20038325} = arena_put_node(v_20038322, Arena.TermType{v_20038323, v_0})
  {ArenaResult{v_20038324, v_20038325} : ArenaResult<U32>}

def usage_inferred_type(v_20038326: ArenaStore, v_1: Inference, v_2: Ast.SourceSpan) -> ArenaResult<U32>:
  match v_1:
    case Inferred{+v_20038327, +v_20038328}:
      v_6 = v_20038328
      {ArenaResult{v_20038326, v_6} : ArenaResult<U32>}
    case InferenceFailure{+v_20038329}:
      ArenaResult{v_20038330, +v_20038331} = usage_unknown_type(v_20038326, v_2)
      {ArenaResult{v_20038330, v_20038331} : ArenaResult<U32>}

def usage_annotation_type(v_20038332: ArenaStore, v_0: U32, v_1: U32, v_2: U32, v_3: Ast.SourceSpan, v_6: List<&2, Binding>, v_7: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_20038333, +v_20038334} = arena_get_node(v_20038332, v_1)
  match v_20038334:
    case Arena.TermCtr{+v_20038338, +v_20038340, +v_20038341, +v_20038343}:
      +v_20038342 = IR.Words{v_20038340, v_20038341}
      ArenaResult{v_20038344, +v_20038345} = arena_get_node(v_20038333, v_2)
      match v_20038345:
        case Arena.TermRef{+v_20038348, +v_20038350}:
          v_14 = v_20038342
          ArenaResult{v_20038353, +v_20038354} = scope_constructor_trees_are_closed(v_20038344, v_14)
          +v_20038355 = v_20038354
          match v_20038355:
            case False{}:
              ArenaResult{v_20038356, +v_20038357} = infer(v_20038353, v_0, v_6, v_7)
              ArenaResult{v_20038358, +v_20038359} = usage_inferred_type(v_20038356, v_20038357, v_3)
              +v_20038351 = v_20038359
              v_20038352 = v_20038358
              {ArenaResult{v_20038352, v_20038351} : ArenaResult<U32>}
            case True{}:
              ArenaResult{v_20038360, +v_20038361} = arena_put_node(v_20038353, Arena.TermQuantity{Ast.QOne{}, v_3})
              ArenaResult{v_20038362, +v_20038363} = arena_put_node(v_20038360, Arena.TermType{v_20038361, v_3})
              ArenaResult{v_20038364, +v_20038365} = check_term(v_20038362, v_2, v_6, v_7, v_20038363)
              ArenaResult{v_20038366, +v_20038367} = usage_inferred_type(v_20038364, v_20038365, v_3)
              +v_20038351 = v_20038367
              v_20038352 = v_20038366
              {ArenaResult{v_20038352, v_20038351} : ArenaResult<U32>}
        case _:
          ArenaResult{v_20038369, +v_20038370} = infer(v_20038344, v_0, v_6, v_7)
          ArenaResult{v_20038371, +v_20038372} = usage_inferred_type(v_20038369, v_20038370, v_3)
          {ArenaResult{v_20038371, v_20038372} : ArenaResult<U32>}
    case _:
      ArenaResult{v_20038374, +v_20038375} = infer(v_20038333, v_0, v_6, v_7)
      ArenaResult{v_20038376, +v_20038377} = usage_inferred_type(v_20038374, v_20038375, v_3)
      {ArenaResult{v_20038376, v_20038377} : ArenaResult<U32>}

# Usage needs the local's result type, not a second validation of every argument.
# The existing usage projection preserves dependent substitution and binder depth.
# Unsupported shapes retain full inference; actual body validation is unchanged.
def usage_value_type_projected(arena: ArenaStore, projected: Maybe<&2, U32>, value: U32, env: List<&2, Binding>, globals: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  match projected:
    case Some{ty}:
      {ArenaResult{arena, ty} : ArenaResult<U32>}
    case None{}:
      ArenaResult{inferred_arena, +inferred} = infer(arena, value, env, globals)
      ArenaResult{span_arena, +span} = term_span(inferred_arena, value)
      usage_inferred_type(span_arena, inferred, span)

def usage_value_type(v_20038378: ArenaStore, v_0: U32, v_3: List<&2, Binding>, v_4: Scope.ArenaGlobalScope, v_6: Bool) -> ArenaResult<U32>:
  match v_6:
    case True{}:
      ArenaResult{v_20038379, +v_20038380} = arena_get_node(v_20038378, v_0)
      match v_20038380:
        case Arena.TermAnn{+v_20038384, +v_20038385, +v_20038386}:
          v_10 = v_20038384
          v_11 = v_20038385
          v_12 = v_20038386
          ArenaResult{v_20038387, +v_20038388} = usage_annotation_type(v_20038379, v_0, v_10, v_11, v_12, v_3, v_4)
          {ArenaResult{v_20038387, v_20038388} : ArenaResult<U32>}
        case _:
          ArenaResult{v_20038390, +v_20038391} = infer(v_20038379, v_0, v_3, v_4)
          ArenaResult{v_20038392, +v_20038393} = term_span(v_20038390, v_0)
          ArenaResult{v_20038394, +v_20038395} = usage_inferred_type(v_20038392, v_20038391, v_20038393)
          {ArenaResult{v_20038394, v_20038395} : ArenaResult<U32>}
    case _:
      ArenaResult{projected_arena, +projected} = function_type_of(v_20038378, v_0, v_3, v_4)
      usage_value_type_projected(projected_arena, projected, v_0, v_3, v_4)

def usage_let_env(v_20038403: ArenaStore, v_2: IR.Names, v_4: IR.Quantities, v_6: IR.Words, v_9: List<&2, Binding>, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope, v_15: Bool) -> ArenaResult<List<&2, Binding>>:
  ArenaResult{v_20038404, +v_20038405} = arena_names_view(v_20038403, v_2)
  match v_20038405:
    case IR.NameNil{}:
      ArenaResult{v_20038406, +v_20038407} = arena_quantities_view(v_20038404, v_4)
      match v_20038407:
        case IR.QuantityNil{}:
          ArenaResult{v_20038408, +v_20038409} = arena_words_view(v_20038406, v_6)
          match v_20038409:
            case IR.WordNil{}:
              {ArenaResult{v_20038408, v_12} : ArenaResult<List<&2, Binding>>}
            case _:
              {ArenaResult{v_20038408, v_12} : ArenaResult<List<&2, Binding>>}
        case _:
          {ArenaResult{v_20038406, v_12} : ArenaResult<List<&2, Binding>>}
    case IR.NameCons{+v_20038414, +v_20038415}:
      ArenaResult{v_20038416, +v_20038417} = arena_quantities_view(v_20038404, v_4)
      match v_20038417:
        case IR.QuantityCons{+v_20038420, +v_20038421}:
          ArenaResult{v_20038422, +v_20038423} = arena_words_view(v_20038416, v_6)
          match v_20038423:
            case IR.WordCons{+v_20038426, +v_20038427}:
              +v_28 = v_20038426
              v_29 = v_20038427
              +v_26 = v_20038420
              v_27 = v_20038421
              +v_24 = v_20038414
              v_25 = v_20038415
              ArenaResult{v_20038428, +v_20038429} = usage_value_type(v_20038422, v_28, v_9, v_13, v_15)
              v_32 = v_20038429
              ArenaResult{v_20038430, +v_20038431} = usage_let_env(v_20038428, v_25, v_27, v_29, v_9, Binding{v_24, v_26, v_32, List.length(&2, Binding, v_9)} <> v_12, v_13, v_15)
              {ArenaResult{v_20038430, v_20038431} : ArenaResult<List<&2, Binding>>}
            case _:
              {ArenaResult{v_20038422, v_12} : ArenaResult<List<&2, Binding>>}
        case _:
          {ArenaResult{v_20038416, v_12} : ArenaResult<List<&2, Binding>>}
    case _:
      {ArenaResult{v_20038404, v_12} : ArenaResult<List<&2, Binding>>}

def usage_local_env(v_20038435: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_6: List<&2, Binding>, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope, v_12: Bool) -> ArenaResult<List<&2, Binding>>:
  ArenaResult{v_20038436, +v_20038437} = arena_words_view(v_20038435, v_1)
  match v_20038437:
    case IR.WordNil{}:
      ArenaResult{v_20038438, +v_20038439} = arena_words_view(v_20038436, v_3)
      match v_20038439:
        case IR.WordNil{}:
          {ArenaResult{v_20038438, v_9} : ArenaResult<List<&2, Binding>>}
        case _:
          {ArenaResult{v_20038438, v_9} : ArenaResult<List<&2, Binding>>}
    case IR.WordCons{+v_20038443, +v_20038444}:
      ArenaResult{v_20038445, +v_20038446} = arena_get_pattern(v_20038436, v_20038443)
      match v_20038446:
        case Arena.PatternVar{+v_20038451, +v_20038453, +v_20038454, +v_20038455}:
          ArenaResult{v_20038456, +v_20038457} = arena_name_text(v_20038445, v_20038451)
          +v_20038452 = v_20038457
          ArenaResult{v_20038458, +v_20038459} = arena_words_view(v_20038456, v_3)
          match v_20038459:
            case IR.WordCons{+v_20038462, +v_20038463}:
              +v_27 = v_20038462
              v_28 = v_20038463
              v_22 = v_20038452
              v_24 = v_20038454
              v_26 = v_20038444
              ArenaResult{v_20038464, +v_20038465} = usage_value_type(v_20038458, v_27, v_6, v_10, v_12)
              v_31 = v_20038465
              ArenaResult{v_20038466, +v_20038467} = usage_local_env(v_20038464, v_26, v_28, v_6, Binding{v_22, v_24, v_31, List.length(&2, Binding, v_6)} <> v_9, v_10, v_12)
              {ArenaResult{v_20038466, v_20038467} : ArenaResult<List<&2, Binding>>}
            case _:
              {ArenaResult{v_20038458, v_9} : ArenaResult<List<&2, Binding>>}
        case Arena.PatternCtr{+v_20038472, +v_20038474, +v_20038475, +v_20038477}:
          ArenaResult{v_20038478, +v_20038479} = arena_words_view(v_20038445, v_3)
          match v_20038479:
            case IR.WordCons{+v_20038482, +v_20038483}:
              {ArenaResult{v_20038478, v_9} : ArenaResult<List<&2, Binding>>}
            case _:
              {ArenaResult{v_20038478, v_9} : ArenaResult<List<&2, Binding>>}
        case _:
          {ArenaResult{v_20038445, v_9} : ArenaResult<List<&2, Binding>>}
    case _:
      {ArenaResult{v_20038436, v_9} : ArenaResult<List<&2, Binding>>}

def usage_pattern_env_result(v_20038487: ArenaStore, v_1: PatternTyping, v_3: IR.Words, v_5: IR.Words, v_7: IR.Words, v_10: List<&2, Binding>, v_11: Scope.ArenaGlobalScope, v_13: Nat, v_15: Nat, v_17: Nat, v_20: Maybe<&2, Nat>) -> ArenaResult<List<&2, Binding>>:
  match v_1:
    case PatternTypeFailure{+v_20038488}:
      {ArenaResult{v_20038487, v_10} : ArenaResult<List<&2, Binding>>}
    case PatternTyped{+v_20038489, +v_20038490}:
      v_27 = v_20038489
      v_28 = v_20038490
      ArenaResult{v_20038491, +v_20038492} = replace_match_types(v_20038487, v_20, v_17, v_5, v_28)
      v_31 = v_20038492
      ArenaResult{v_20038493, +v_20038494} = refine_match_env(v_20038491, v_20, v_17, v_27, v_28)
      v_34 = v_20038494
      ArenaResult{v_20038495, +v_20038496} = usage_pattern_env(v_20038493, v_3, v_31, v_7, v_34, v_11, Nat.sub(v_13, v_17), Nat.add(v_15, v_17))
      {ArenaResult{v_20038495, v_20038496} : ArenaResult<List<&2, Binding>>}

def usage_pattern_env(v_1: ArenaStore, v_2: IR.Words, v_3: IR.Words, v_4: IR.Words, v_7: List<&2, Binding>, v_8: Scope.ArenaGlobalScope, v_10: Nat, v_12: Nat) -> ArenaResult<List<&2, Binding>>:
  ArenaResult{v_20, +v_21} = arena_words_view(v_1, v_2)
  match v_21:
    case IR.WordNil{}:
      ArenaResult{v_25, +v_26} = arena_words_view(v_20, v_3)
      match v_26:
        case IR.WordNil{}:
          ArenaResult{v_30, +v_31} = arena_words_view(v_25, v_4)
          match v_31:
            case IR.WordNil{}:
              {ArenaResult{v_30, v_7} : ArenaResult<List<&2, Binding>>}
            case _:
              {ArenaResult{v_30, v_7} : ArenaResult<List<&2, Binding>>}
        case _:
          {ArenaResult{v_25, v_7} : ArenaResult<List<&2, Binding>>}
    case IR.WordCons{+v_38, +v_39}:
      ArenaResult{v_43, +v_44} = arena_words_view(v_20, v_3)
      match v_44:
        case IR.WordCons{+v_47, +v_48}:
          ArenaResult{v_52, +v_53} = arena_words_view(v_43, v_4)
          match v_53:
            case IR.WordCons{+v_56, +v_57}:
              +v_59 = v_56
              v_61 = v_57
              +v_63 = v_47
              v_65 = v_48
              +v_67 = v_38
              v_69 = v_39
              ArenaResult{v_73, +v_74} = core_pattern_depth(v_52, v_67)
              v_76 = v_74
              ArenaResult{v_80, +v_81} = scrutinee_variable_index(v_73, v_59, v_8)
              v_84 = maybe_shift_index(v_81, v_12)
              v_50000239 = optional_source_quantity(v_84, v_7)
              v_87 = Some{v_50000239}
              ArenaResult{v_92, +v_93} = check_pattern_typed(v_80, v_67, v_63, v_87, Nat.add(List.length(&2, Binding, v_7), v_76), v_7, v_8)
              ArenaResult{v_97, +v_98} = usage_pattern_env_result(v_92, v_93, v_69, v_65, v_61, v_7, v_8, v_10, v_12, v_76, v_84)
              {ArenaResult{v_97, v_98} : ArenaResult<List<&2, Binding>>}
            case _:
              {ArenaResult{v_52, v_7} : ArenaResult<List<&2, Binding>>}
        case _:
          {ArenaResult{v_43, v_7} : ArenaResult<List<&2, Binding>>}
    case _:
      {ArenaResult{v_20, v_7} : ArenaResult<List<&2, Binding>>}

def constructor_usage_expected_view(v_20038533: ArenaStore, v_0: U32, v_2: String, v_4: Nat, v_5: U32, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  ArenaResult{v_20038534, +v_20038535} = arena_get_node(v_20038533, v_0)
  match v_20038535:
    case Arena.TermAdt{+v_20038540, +v_20038542, +v_20038543, +v_20038545, +v_20038546, +v_20038548}:
      ArenaResult{v_20038549, +v_20038550} = arena_name_text(v_20038534, v_20038540)
      +v_20038541 = v_20038550
      +v_20038544 = IR.Words{v_20038542, v_20038543}
      v_12 = v_20038541
      v_13 = v_20038544
      v_17 = String.eq(Scope.canonical_name(v_12, v_6), Scope.canonical_name(v_2, v_6))
      +v_20038553 = v_17
      match v_20038553:
        case False{}:
          ArenaResult{v_20038554, +v_20038555} = drop_telescope(v_20038549, v_4, v_5, v_6)
          +v_20038551 = Some{v_20038555}
          v_20038552 = v_20038554
          {ArenaResult{v_20038552, v_20038551} : ArenaResult<Maybe<&2, U32>>}
        case True{}:
          ArenaResult{v_20038556, +v_20038557} = apply_prefix(v_20038549, v_13, v_5)
          +v_20038551 = v_20038557
          v_20038552 = v_20038556
          {ArenaResult{v_20038552, v_20038551} : ArenaResult<Maybe<&2, U32>>}
    case _:
      ArenaResult{v_20038559, +v_20038560} = drop_telescope(v_20038534, v_4, v_5, v_6)
      {ArenaResult{v_20038559, Some{v_20038560}} : ArenaResult<Maybe<&2, U32>>}

def constructor_usage_expected(v_20038561: ArenaStore, v_1: Maybe<&2, U32>, v_3: String, v_5: Nat, v_6: U32, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  match v_1:
    case Some{+v_20038562}:
      v_10 = v_20038562
      ArenaResult{v_20038563, +v_20038564} = whnf(v_20038561, 64n, v_10, v_7)
      ArenaResult{v_20038565, +v_20038566} = constructor_usage_expected_view(v_20038563, v_20038564, v_3, v_5, v_6, v_7)
      {ArenaResult{v_20038565, v_20038566} : ArenaResult<Maybe<&2, U32>>}
    case None{}:
      ArenaResult{v_20038567, +v_20038568} = drop_telescope(v_20038561, v_5, v_6, v_7)
      {ArenaResult{v_20038567, Some{v_20038568}} : ArenaResult<Maybe<&2, U32>>}

def constructor_usage_family_global(v_20038569: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_3: String, v_4: U32, v_6: Maybe<&2, U32>, v_7: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  match v_1:
    case None{}:
      {ArenaResult{v_20038569, None{}} : ArenaResult<Maybe<&2, U32>>}
    case Some{+v_20038570}:
      v_10 = v_20038570
      match v_10:
        case Scope.ArenaGlobal{+v_20038571, +v_20038572, +v_20038573, +v_20038574, +v_20038575, +v_20038576}:
          v_20 = v_20038574
          ArenaResult{v_20038577, +v_20038578} = initial_telescope_count(v_20038569, v_20, v_7)
          v_25 = v_20038578
          ArenaResult{v_20038579, +v_20038580} = constructor_usage_expected(v_20038577, v_6, v_3, v_25, v_4, v_7)
          {ArenaResult{v_20038579, v_20038580} : ArenaResult<Maybe<&2, U32>>}

def constructor_usage_family(v_20038581: ArenaStore, v_2: Maybe<&2, String>, v_3: U32, v_5: Maybe<&2, U32>, v_6: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  match v_2:
    case None{}:
      {ArenaResult{v_20038581, None{}} : ArenaResult<Maybe<&2, U32>>}
    case Some{+v_20038582}:
      v_9 = v_20038582
      ArenaResult{v_20038583, +v_20038584} = constructor_usage_family_global(v_20038581, Scope.lookup(Scope.canonical_name(v_9, v_6), v_6), v_9, v_3, v_5, v_6)
      {ArenaResult{v_20038583, v_20038584} : ArenaResult<Maybe<&2, U32>>}

def constructor_usage_global(v_20038585: ArenaStore, v_0: Scope.ArenaGlobal, v_2: Maybe<&2, U32>, v_3: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  match v_0:
    case Scope.ArenaGlobal{+v_20038586, +v_20038587, +v_20038588, +v_20038589, +v_20038590, +v_20038591}:
      v_14 = v_20038589
      ArenaResult{v_20038592, +v_20038593} = constructor_family(v_20038585, v_14, v_3)
      ArenaResult{v_20038594, +v_20038595} = constructor_usage_family(v_20038592, v_20038593, v_14, v_2, v_3)
      {ArenaResult{v_20038594, v_20038595} : ArenaResult<Maybe<&2, U32>>}

def constructor_usage_global_result(v_20038596: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_3: Maybe<&2, U32>, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  match v_1:
    case None{}:
      {ArenaResult{v_20038596, None{}} : ArenaResult<Maybe<&2, U32>>}
    case Some{+v_20038597}:
      v_7 = v_20038597
      ArenaResult{v_20038598, +v_20038599} = constructor_usage_global(v_20038596, v_7, v_3, v_4)
      {ArenaResult{v_20038598, v_20038599} : ArenaResult<Maybe<&2, U32>>}

def constructor_usage_field_type(v_20038600: ArenaStore, v_1: String, v_3: Maybe<&2, U32>, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  ArenaResult{v_20038601, +v_20038602} = constructor_usage_global_result(v_20038600, Scope.lookup_kind(v_1, Scope.GlobalConstructor{}, v_4), v_3, v_4)
  {ArenaResult{v_20038601, v_20038602} : ArenaResult<Maybe<&2, U32>>}

def term_usage_map_constructor_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: IR.Words, v_7: IR.Words, v_9: U32, v_11: Nat, v_14: List<&2, Binding>, v_15: Scope.ArenaGlobalScope, v_17: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  ArenaResult{v_25, +v_26} = arena_get_node(v_1, v_3)
  match v_26:
    case Arena.TermAll{+v_33, +v_34, +v_35, +v_36, +v_37, +v_38}:
      v_40 = v_33
      v_42 = v_36
      v_44 = v_37
      ArenaResult{v_48, +v_49} = constructor_argument_usage(v_25, v_40, v_5, v_42, v_11, v_14, v_15, v_17)
      v_51 = v_49
      ArenaResult{v_55, +v_56} = core_subst(v_48, 0n, v_5, v_44)
      ArenaResult{v_60, +v_61} = term_usage_map_constructor_args(v_55, v_6, v_56, v_11, v_14, v_15, v_17)
      v_50000240 = usage_merge(v_51, v_61, False{})
      {ArenaResult{v_60, v_50000240} : ArenaResult<List<&2, UsageEntry>>}
    case _:
      ArenaResult{v_68, +v_69} = term_usage_map_list(v_25, v_7, v_11, v_14, v_15, v_17)
      {ArenaResult{v_68, v_69} : ArenaResult<List<&2, UsageEntry>>}

def constructor_argument_usage(v_20038628: ArenaStore, v_0: Ast.Quantity, v_1: U32, v_2: U32, v_4: Nat, v_7: List<&2, Binding>, v_8: Scope.ArenaGlobalScope, v_10: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  match v_0:
    case Ast.QZero{}:
      {ArenaResult{v_20038628, []} : ArenaResult<List<&2, UsageEntry>>}
    case _:
      ArenaResult{v_20038630, +v_20038631} = term_usage_map(v_20038628, v_1, v_4, v_7, v_8, Some{v_2}, v_10)
      {ArenaResult{v_20038630, v_20038631} : ArenaResult<List<&2, UsageEntry>>}

def term_usage_map_constructor_args(v_20038632: ArenaStore, v_1: IR.Words, v_2: U32, v_4: Nat, v_7: List<&2, Binding>, v_8: Scope.ArenaGlobalScope, v_10: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  ArenaResult{v_20038633, +v_20038634} = arena_words_view(v_20038632, v_1)
  match v_20038634:
    case IR.WordNil{}:
      {ArenaResult{v_20038633, []} : ArenaResult<List<&2, UsageEntry>>}
    case IR.WordCons{+v_20038635, +v_20038636}:
      +v_15 = v_20038635
      v_16 = v_20038636
      ArenaResult{v_20038637, +v_20038638} = whnf(v_20038633, 64n, v_2, v_8)
      ArenaResult{v_20038639, +v_20038640} = term_usage_map_constructor_view(v_20038637, v_20038638, v_15, v_16, v_1, v_2, v_4, v_7, v_8, v_10)
      {ArenaResult{v_20038639, v_20038640} : ArenaResult<List<&2, UsageEntry>>}

def shift_expected(v_20038641: ArenaStore, v_1: Maybe<&2, U32>, v_3: Nat) -> ArenaResult<Maybe<&2, U32>>:
  match v_1:
    case Some{+v_20038642}:
      v_6 = v_20038642
      ArenaResult{v_20038643, +v_20038644} = core_shift(v_20038641, 0n, v_3, v_6)
      {ArenaResult{v_20038643, Some{v_20038644}} : ArenaResult<Maybe<&2, U32>>}
    case None{}:
      {ArenaResult{v_20038641, None{}} : ArenaResult<Maybe<&2, U32>>}

def term_usage_map_lambda_quantity(v_20038645: ArenaStore, v_1: Maybe<&2, Ast.Quantity>, v_3: String, v_4: U32, v_5: Ast.SourceSpan, v_7: Nat, v_10: List<&2, Binding>, v_11: Scope.ArenaGlobalScope, v_12: U32, v_13: U32, v_15: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  match v_1:
    case Some{+v_20038646}:
      v_19 = v_20038646
      ArenaResult{v_20038647, +v_20038648} = term_usage_map(v_20038645, v_4, Nat.add(v_7, 1n), Binding{v_3, v_19, v_12, List.length(&2, Binding, v_10)} <> v_10, v_11, Some{v_13}, v_15)
      {ArenaResult{v_20038647, v_20038648} : ArenaResult<List<&2, UsageEntry>>}
    case None{}:
      ArenaResult{v_20038649, +v_20038650} = usage_unknown_type(v_20038645, v_5)
      v_25 = v_20038650
      ArenaResult{v_20038651, +v_20038652} = term_usage_map(v_20038649, v_4, Nat.add(v_7, 1n), Binding{v_3, Ast.QMany{}, v_25, List.length(&2, Binding, v_10)} <> v_10, v_11, None{}, v_15)
      {ArenaResult{v_20038651, v_20038652} : ArenaResult<List<&2, UsageEntry>>}

def term_usage_map_lambda_view(v_20038653: ArenaStore, v_0: U32, v_2: Maybe<&2, Ast.Quantity>, v_4: String, v_5: U32, v_6: Ast.SourceSpan, v_8: Nat, v_11: List<&2, Binding>, v_12: Scope.ArenaGlobalScope, v_14: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  ArenaResult{v_20038654, +v_20038655} = arena_get_node(v_20038653, v_0)
  match v_20038655:
    case Arena.TermAll{+v_20038662, +v_20038663, +v_20038665, +v_20038666, +v_20038667, +v_20038668}:
      v_23 = v_20038662
      v_26 = v_20038666
      v_27 = v_20038667
      ArenaResult{v_20038669, +v_20038670} = term_usage_map_lambda_quantity(v_20038654, lambda_quantity(v_2, v_23), v_4, v_5, v_6, v_8, v_11, v_12, v_26, v_27, v_14)
      {ArenaResult{v_20038669, v_20038670} : ArenaResult<List<&2, UsageEntry>>}
    case _:
      ArenaResult{v_20038672, +v_20038673} = usage_unknown_type(v_20038654, v_6)
      v_35 = v_20038673
      ArenaResult{v_20038674, +v_20038675} = term_usage_map(v_20038672, v_5, Nat.add(v_8, 1n), Binding{v_4, Ast.QMany{}, v_35, List.length(&2, Binding, v_11)} <> v_11, v_12, None{}, v_14)
      {ArenaResult{v_20038674, v_20038675} : ArenaResult<List<&2, UsageEntry>>}

def term_usage_map_lambda_expected(v_20038676: ArenaStore, v_1: Maybe<&2, U32>, v_3: Maybe<&2, Ast.Quantity>, v_5: String, v_6: U32, v_7: Ast.SourceSpan, v_9: Nat, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope, v_15: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  match v_1:
    case Some{+v_20038677}:
      v_19 = v_20038677
      ArenaResult{v_20038678, +v_20038679} = whnf(v_20038676, 64n, v_19, v_13)
      ArenaResult{v_20038680, +v_20038681} = term_usage_map_lambda_view(v_20038678, v_20038679, v_3, v_5, v_6, v_7, v_9, v_12, v_13, v_15)
      {ArenaResult{v_20038680, v_20038681} : ArenaResult<List<&2, UsageEntry>>}
    case None{}:
      ArenaResult{v_20038682, +v_20038683} = usage_unknown_type(v_20038676, v_7)
      v_24 = v_20038683
      ArenaResult{v_20038684, +v_20038685} = term_usage_map(v_20038682, v_6, Nat.add(v_9, 1n), Binding{v_5, Ast.QMany{}, v_24, List.length(&2, Binding, v_12)} <> v_12, v_13, None{}, v_15)
      {ArenaResult{v_20038684, v_20038685} : ArenaResult<List<&2, UsageEntry>>}

def term_usage_map_argument_expected_view(v_20038686: ArenaStore, v_0: U32) -> ArenaResult<Maybe<&2, U32>>:
  ArenaResult{v_20038687, +v_20038688} = arena_get_node(v_20038686, v_0)
  match v_20038688:
    case Arena.TermAll{+v_20038695, +v_20038696, +v_20038698, +v_20038699, +v_20038700, +v_20038701}:
      v_11 = v_20038699
      {ArenaResult{v_20038687, Some{v_11}} : ArenaResult<Maybe<&2, U32>>}
    case _:
      {ArenaResult{v_20038687, None{}} : ArenaResult<Maybe<&2, U32>>}

def term_usage_map_argument_expected(v_20038703: ArenaStore, v_1: Maybe<&2, U32>, v_2: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  match v_1:
    case Some{+v_20038704}:
      v_5 = v_20038704
      ArenaResult{v_20038705, +v_20038706} = whnf(v_20038703, 64n, v_5, v_2)
      ArenaResult{v_20038707, +v_20038708} = term_usage_map_argument_expected_view(v_20038705, v_20038706)
      {ArenaResult{v_20038707, v_20038708} : ArenaResult<Maybe<&2, U32>>}
    case None{}:
      {ArenaResult{v_20038703, None{}} : ArenaResult<Maybe<&2, U32>>}

def term_usage_map_application_quantity(v_1: ArenaStore, v_3: Maybe<&2, Ast.Quantity>, v_5: U32, v_7: U32, v_9: Nat, v_12: List<&2, Binding>, v_13: Scope.ArenaGlobalScope, v_15: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  match v_3:
    case Some{+v_21}:
      match v_21:
        case Ast.QZero{}:
          ArenaResult{v_25, +v_26} = term_usage_map(v_1, v_5, v_9, v_12, v_13, None{}, v_15)
          {ArenaResult{v_25, v_26} : ArenaResult<List<&2, UsageEntry>>}
        case _:
          ArenaResult{v_32, +v_33} = function_type_of(v_1, v_5, v_12, v_13)
          ArenaResult{v_37, +v_38} = term_usage_map_argument_expected(v_32, v_33, v_13)
          v_40 = v_38
          ArenaResult{v_44, +v_45} = term_usage_map(v_37, v_5, v_9, v_12, v_13, None{}, v_15)
          ArenaResult{v_49, +v_50} = term_usage_map(v_44, v_7, v_9, v_12, v_13, v_40, v_15)
          v_50000241 = usage_merge(v_45, v_50, False{})
          {ArenaResult{v_49, v_50000241} : ArenaResult<List<&2, UsageEntry>>}
    case _:
      ArenaResult{v_57, +v_58} = function_type_of(v_1, v_5, v_12, v_13)
      ArenaResult{v_62, +v_63} = term_usage_map_argument_expected(v_57, v_58, v_13)
      v_65 = v_63
      ArenaResult{v_69, +v_70} = term_usage_map(v_62, v_5, v_9, v_12, v_13, None{}, v_15)
      ArenaResult{v_74, +v_75} = term_usage_map(v_69, v_7, v_9, v_12, v_13, v_65, v_15)
      v_50000242 = usage_merge(v_70, v_75, False{})
      {ArenaResult{v_74, v_50000242} : ArenaResult<List<&2, UsageEntry>>}

def term_usage_map_family_result(v_1: ArenaStore, v_3: FamilyLowering, v_5: U32, v_6: IR.Words, v_8: Nat, v_11: List<&2, Binding>, v_12: Scope.ArenaGlobalScope, v_15: Maybe<&2, U32>, v_17: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  match v_3:
    case FamilyTerm{+v_23}:
      v_25 = v_23
      ArenaResult{v_29, +v_30} = term_usage_map(v_1, v_25, v_8, v_11, v_12, v_15, v_17)
      {ArenaResult{v_29, v_30} : ArenaResult<List<&2, UsageEntry>>}
    case FamilyFailure{+v_32}:
      ArenaResult{v_36, +v_37} = term_usage_map(v_1, v_5, v_8, v_11, v_12, None{}, v_17)
      ArenaResult{v_41, +v_42} = term_usage_map_list(v_36, v_6, v_8, v_11, v_12, v_17)
      v_50000243 = usage_merge(v_37, v_42, False{})
      {ArenaResult{v_41, v_50000243} : ArenaResult<List<&2, UsageEntry>>}

def term_usage_map_constructor_result(v_20038741: ArenaStore, v_1: Maybe<&2, U32>, v_3: String, v_5: IR.Words, v_7: Nat, v_10: List<&2, Binding>, v_11: Scope.ArenaGlobalScope, v_13: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  match v_1:
    case Some{+v_20038742}:
      v_17 = v_20038742
      ArenaResult{v_20038743, +v_20038744} = term_usage_map_constructor_args(v_20038741, v_5, v_17, v_7, v_10, v_11, v_13)
      {ArenaResult{v_20038743, v_20038744} : ArenaResult<List<&2, UsageEntry>>}
    case None{}:
      ArenaResult{v_20038745, +v_20038746} = constructor_field_quantities(v_20038741, v_3, v_11)
      ArenaResult{v_20038747, +v_20038748} = term_usage_map_quantified_list(v_20038745, v_5, v_20038746, v_7, v_10, v_11, v_13)
      {ArenaResult{v_20038747, v_20038748} : ArenaResult<List<&2, UsageEntry>>}

def term_usage_map_scrutinee_result(v_1: ArenaStore, v_3: ScrutineeTyping, v_4: IR.Words, v_5: IR.Words, v_8: List<&2, UsageEntry>, v_10: Nat, v_13: List<&2, Binding>, v_14: Scope.ArenaGlobalScope, v_17: Maybe<&2, U32>, v_19: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  match v_3:
    case ScrutineeTypes{+v_25}:
      v_27 = v_25
      ArenaResult{v_31, +v_32} = term_usage_map_cases(v_1, v_5, v_4, v_27, v_10, v_13, v_14, v_17, v_19)
      v_50000244 = usage_merge(v_8, v_32, False{})
      {ArenaResult{v_31, v_50000244} : ArenaResult<List<&2, UsageEntry>>}
    case ScrutineeTypeFailure{+v_35}:
      ArenaResult{v_39, +v_40} = term_usage_map_cases(v_1, v_5, v_4, IR.Words{0, 0}, v_10, v_13, v_14, v_17, v_19)
      v_50000245 = usage_merge(v_8, v_40, False{})
      {ArenaResult{v_39, v_50000245} : ArenaResult<List<&2, UsageEntry>>}

def substituted_usage_expected(v_20038756: ArenaStore, v_1: Maybe<&2, U32>, v_3: Nat, v_4: U32) -> ArenaResult<Maybe<&2, U32>>:
  match v_1:
    case Some{+v_20038757}:
      v_7 = v_20038757
      ArenaResult{v_20038758, +v_20038759} = core_subst(v_20038756, v_3, v_4, v_7)
      {ArenaResult{v_20038758, Some{v_20038759}} : ArenaResult<Maybe<&2, U32>>}
    case None{}:
      {ArenaResult{v_20038756, None{}} : ArenaResult<Maybe<&2, U32>>}

def term_usage_map(v_1: ArenaStore, v_3: U32, v_5: Nat, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope, v_12: Maybe<&2, U32>, v_14: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  ArenaResult{v_22, +v_23} = arena_get_node(v_1, v_3)
  match v_23:
    case Arena.TermVar{+v_27, +v_28, +v_29}:
      v_31 = v_28
      +v_33 = Nat.is_ge(v_31, v_5)
      match v_33:
        case False{}:
          +v_35 = {[] : List<&2, UsageEntry>}
          v_37 = v_22
          {ArenaResult{v_37, v_35} : ArenaResult<List<&2, UsageEntry>>}
        case True{}:
          +v_40 = {[Usage{Nat.sub(v_31, v_5), Ast.QOne{}}] : List<&2, UsageEntry>}
          v_42 = v_22
          {ArenaResult{v_42, v_40} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermBang{+v_46, +v_47}:
      v_49 = v_46
      ArenaResult{v_53, +v_54} = term_usage_map(v_22, v_49, v_5, v_8, v_9, v_12, v_14)
      {ArenaResult{v_53, v_54} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermSub{+v_59, +v_60, +v_61, +v_62}:
      v_64 = v_59
      v_66 = v_60
      v_68 = v_61
      ArenaResult{v_72, +v_73} = substituted_usage_expected(v_22, v_12, v_64, v_66)
      v_75 = v_73
      ArenaResult{v_79, +v_80} = core_subst(v_72, v_64, v_66, v_68)
      ArenaResult{v_84, +v_85} = term_usage_map(v_79, v_80, v_5, v_8, v_9, v_75, v_14)
      {ArenaResult{v_84, v_85} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermAnn{+v_89, +v_90, +v_91}:
      v_93 = v_89
      v_95 = v_90
      ArenaResult{v_99, +v_100} = term_usage_map(v_22, v_93, v_5, v_8, v_9, Some{v_95}, v_14)
      {ArenaResult{v_99, v_100} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermTemplate{+v_103, +v_104}:
      {ArenaResult{v_22, []} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermType{+v_107, +v_108}:
      {ArenaResult{v_22, []} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermMin{+v_112, +v_113, +v_114}:
      v_116 = v_112
      v_118 = v_113
      ArenaResult{v_122, +v_123} = term_usage_map(v_22, v_116, v_5, v_8, v_9, None{}, v_14)
      ArenaResult{v_127, +v_128} = term_usage_map(v_122, v_118, v_5, v_8, v_9, None{}, v_14)
      v_50000246 = usage_merge(v_123, v_128, False{})
      {ArenaResult{v_127, v_50000246} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermAll{+v_136, +v_137, +v_138, +v_139, +v_140, +v_141}:
      {ArenaResult{v_22, []} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermLam{+v_147, +v_148, +v_149, +v_150, +v_151}:
      ArenaResult{v_155, +v_156} = arena_name_text(v_22, v_148)
      +v_158 = v_156
      v_160 = v_147
      v_162 = v_158
      v_164 = v_150
      v_166 = v_151
      ArenaResult{v_170, +v_171} = term_usage_map_lambda_expected(v_155, v_12, v_160, v_162, v_164, v_166, v_5, v_8, v_9, v_14)
      {ArenaResult{v_170, v_171} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermLet{+v_182, +v_183, +v_184, +v_185, +v_186, +v_187, +v_188, +v_189, +v_190, +v_191}:
      +v_193 = IR.Names{v_182, v_183}
      +v_195 = IR.Quantities{v_186, v_187}
      +v_197 = IR.Words{v_188, v_189}
      v_199 = v_193
      v_201 = v_195
      v_203 = v_197
      v_205 = v_190
      ArenaResult{v_209, +v_210} = usage_let_env(v_22, v_199, v_201, v_203, v_8, v_8, v_9, v_14)
      v_212 = v_210
      ArenaResult{v_217, +v_218} = shift_expected(v_209, v_12, arena_names_length(v_199))
      v_220 = v_218
      ArenaResult{v_224, +v_225} = term_usage_map_quantified_list(v_217, v_203, v_201, v_5, v_8, v_9, v_14)
      ArenaResult{v_230, +v_231} = term_usage_map(v_224, v_205, Nat.add(v_5, arena_names_length(v_199)), v_212, v_9, v_220, v_14)
      v_50000247 = usage_merge(v_225, v_231, False{})
      {ArenaResult{v_230, v_50000247} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermApp{+v_236, +v_237, +v_238}:
      ArenaResult{v_242, +v_243} = arena_get_node(v_22, v_236)
      match v_243:
        case Arena.TermLam{+v_249, +v_250, +v_251, +v_252, +v_253}:
          v_255 = v_252
          v_257 = v_237
          ArenaResult{v_261, +v_262} = core_subst(v_242, 0n, v_257, v_255)
          ArenaResult{v_266, +v_267} = term_usage_map(v_261, v_262, v_5, v_8, v_9, v_12, v_14)
          {ArenaResult{v_266, v_267} : ArenaResult<List<&2, UsageEntry>>}
        case _:
          v_271 = v_236
          v_273 = v_237
          ArenaResult{v_277, +v_278} = function_argument_quantity(v_242, v_271, v_8, v_9)
          ArenaResult{v_282, +v_283} = term_usage_map_application_quantity(v_277, v_278, v_271, v_273, v_5, v_8, v_9, v_14)
          {ArenaResult{v_282, v_283} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermFill{+v_288, +v_289, +v_290, +v_291}:
      +v_293 = IR.Words{v_289, v_290}
      v_295 = v_288
      v_297 = v_293
      v_299 = v_291
      ArenaResult{v_303, +v_304} = lower_family_sugar(v_22, v_295, v_297, False{}, v_299, v_9)
      ArenaResult{v_308, +v_309} = term_usage_map_family_result(v_303, v_304, v_295, v_297, v_5, v_8, v_9, v_12, v_14)
      {ArenaResult{v_308, v_309} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermPlus{+v_314, +v_315, +v_316, +v_317}:
      +v_319 = IR.Words{v_315, v_316}
      v_321 = v_314
      v_323 = v_319
      v_325 = v_317
      ArenaResult{v_329, +v_330} = lower_family_sugar(v_22, v_321, v_323, True{}, v_325, v_9)
      ArenaResult{v_334, +v_335} = term_usage_map_family_result(v_329, v_330, v_321, v_323, v_5, v_8, v_9, v_12, v_14)
      {ArenaResult{v_334, v_335} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermAdt{+v_342, +v_343, +v_344, +v_345, +v_346, +v_347}:
      ArenaResult{v_351, +v_352} = arena_name_text(v_22, v_342)
      +v_354 = v_352
      +v_356 = IR.Words{v_343, v_344}
      v_358 = v_354
      v_360 = v_356
      ArenaResult{v_365, +v_366} = family_parameter_quantities(v_351, Scope.canonical_name(v_358, v_9), v_9)
      ArenaResult{v_370, +v_371} = term_usage_map_quantified_list(v_365, v_360, v_366, v_5, v_8, v_9, v_14)
      {ArenaResult{v_370, v_371} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermString{_, _, _}:
      {ArenaResult{v_22, []} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermCtr{+v_376, +v_377, +v_378, +v_379}:
      ArenaResult{v_383, +v_384} = arena_name_text(v_22, v_376)
      +v_386 = v_384
      +v_388 = IR.Words{v_377, v_378}
      v_390 = v_386
      v_392 = v_388
      ArenaResult{v_396, +v_397} = scope_constructor_trees_are_closed(v_383, v_392)
      +v_399 = v_397
      match v_399:
        case False{}:
          ArenaResult{v_403, +v_404} = constructor_usage_field_type(v_396, v_390, v_12, v_9)
          ArenaResult{v_408, +v_409} = term_usage_map_constructor_result(v_403, v_404, v_390, v_392, v_5, v_8, v_9, v_14)
          +v_411 = v_409
          v_413 = v_408
          {ArenaResult{v_413, v_411} : ArenaResult<List<&2, UsageEntry>>}
        case True{}:
          +v_416 = {[] : List<&2, UsageEntry>}
          v_418 = v_396
          {ArenaResult{v_418, v_416} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermMat{+v_424, +v_425, +v_426, +v_427}:
      v_429 = v_425
      v_431 = v_426
      ArenaResult{v_435, +v_436} = term_usage_map(v_22, v_429, v_5, v_8, v_9, None{}, v_14)
      ArenaResult{v_440, +v_441} = term_usage_map(v_435, v_431, v_5, v_8, v_9, None{}, v_14)
      v_50000248 = usage_merge(v_436, v_441, False{})
      {ArenaResult{v_440, v_50000248} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermEqual{+v_447, +v_448, +v_449, +v_450}:
      {ArenaResult{v_22, []} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.TermRewrite{+v_455, +v_456, +v_457, +v_458}:
      v_460 = v_455
      v_462 = v_457
      ArenaResult{v_466, +v_467} = term_usage_map(v_22, v_460, v_5, v_8, v_9, None{}, v_14)
      ArenaResult{v_471, +v_472} = term_usage_map(v_466, v_462, v_5, v_8, v_9, v_12, v_14)
      v_50000249 = usage_merge(v_467, v_472, False{})
      {ArenaResult{v_471, v_50000249} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.BodyMatch{+v_479, +v_480, +v_481, +v_482, +v_483}:
      +v_485 = IR.Words{v_479, v_480}
      +v_487 = IR.Words{v_481, v_482}
      v_489 = v_485
      v_491 = v_487
      ArenaResult{v_495, +v_496} = term_usage_map_list(v_22, v_489, v_5, v_8, v_9, v_14)
      v_498 = v_496
      ArenaResult{v_502, +v_503} = infer_scrutinee_types(v_495, v_489, v_8, v_9)
      ArenaResult{v_507, +v_508} = term_usage_map_scrutinee_result(v_502, v_503, v_489, v_491, v_498, v_5, v_8, v_9, v_12, v_14)
      {ArenaResult{v_507, v_508} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.BodyCase{+v_513, +v_514, +v_515, +v_516}:
      +v_518 = IR.Words{v_513, v_514}
      v_520 = v_518
      v_522 = v_515
      ArenaResult{v_526, +v_527} = core_pattern_list_depth(v_22, v_520)
      ArenaResult{v_531, +v_532} = core_pattern_list_depth(v_526, v_520)
      ArenaResult{v_536, +v_537} = shift_expected(v_531, v_12, v_532)
      ArenaResult{v_541, +v_542} = term_usage_map(v_536, v_522, Nat.add(v_5, v_527), v_8, v_9, v_537, v_14)
      {ArenaResult{v_541, v_542} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.BodyLocal{+v_550, +v_551, +v_552, +v_553, +v_554, +v_555, +v_556}:
      +v_558 = IR.Words{v_550, v_551}
      +v_560 = IR.Words{v_553, v_554}
      ArenaResult{v_564, +v_565} = arena_words_view(v_22, v_558)
      match v_565:
        case IR.WordCons{+v_568, +v_569}:
          ArenaResult{v_573, +v_574} = arena_get_pattern(v_564, v_568)
          match v_574:
            case Arena.PatternCtr{+v_579, +v_580, +v_581, +v_582}:
              ArenaResult{v_586, +v_587} = arena_name_text(v_573, v_579)
              +v_589 = v_587
              +v_591 = IR.Words{v_580, v_581}
              ArenaResult{v_595, +v_596} = arena_words_view(v_586, v_569)
              match v_596:
                case IR.WordNil{}:
                  match v_552:
                    case Ast.QOne{}:
                      ArenaResult{v_600, +v_601} = arena_words_view(v_595, v_560)
                      match v_601:
                        case IR.WordCons{+v_604, +v_605}:
                          ArenaResult{v_609, +v_610} = arena_words_view(v_600, v_605)
                          match v_610:
                            case IR.WordNil{}:
                              v_612 = v_604
                              v_614 = v_589
                              v_616 = v_591
                              v_618 = v_582
                              v_620 = v_555
                              v_622 = v_556
                              ArenaResult{v_626, +v_627} = destructuring_local_match(v_609, v_614, v_616, v_618, v_612, v_620, v_622)
                              ArenaResult{v_631, +v_632} = term_usage_map(v_626, v_627, v_5, v_8, v_9, v_12, v_14)
                              {ArenaResult{v_631, v_632} : ArenaResult<List<&2, UsageEntry>>}
                            case _:
                              v_636 = v_558
                              v_638 = v_560
                              v_640 = v_555
                              ArenaResult{v_644, +v_645} = usage_local_env(v_609, v_636, v_638, v_8, v_8, v_9, v_14)
                              v_647 = v_645
                              ArenaResult{v_651, +v_652} = term_usage_map_list(v_644, v_638, v_5, v_8, v_9, v_14)
                              ArenaResult{v_656, +v_657} = core_pattern_list_depth(v_651, v_636)
                              ArenaResult{v_661, +v_662} = core_pattern_list_depth(v_656, v_636)
                              ArenaResult{v_666, +v_667} = shift_expected(v_661, v_12, v_662)
                              ArenaResult{v_671, +v_672} = term_usage_map(v_666, v_640, Nat.add(v_5, v_657), v_647, v_9, v_667, v_14)
                              v_50000250 = usage_merge(v_652, v_672, False{})
                              {ArenaResult{v_671, v_50000250} : ArenaResult<List<&2, UsageEntry>>}
                        case _:
                          v_677 = v_558
                          v_679 = v_560
                          v_681 = v_555
                          ArenaResult{v_685, +v_686} = usage_local_env(v_600, v_677, v_679, v_8, v_8, v_9, v_14)
                          v_688 = v_686
                          ArenaResult{v_692, +v_693} = term_usage_map_list(v_685, v_679, v_5, v_8, v_9, v_14)
                          ArenaResult{v_697, +v_698} = core_pattern_list_depth(v_692, v_677)
                          ArenaResult{v_702, +v_703} = core_pattern_list_depth(v_697, v_677)
                          ArenaResult{v_707, +v_708} = shift_expected(v_702, v_12, v_703)
                          ArenaResult{v_712, +v_713} = term_usage_map(v_707, v_681, Nat.add(v_5, v_698), v_688, v_9, v_708, v_14)
                          v_50000251 = usage_merge(v_693, v_713, False{})
                          {ArenaResult{v_712, v_50000251} : ArenaResult<List<&2, UsageEntry>>}
                    case _:
                      v_718 = v_558
                      v_720 = v_560
                      v_722 = v_555
                      ArenaResult{v_726, +v_727} = usage_local_env(v_595, v_718, v_720, v_8, v_8, v_9, v_14)
                      v_729 = v_727
                      ArenaResult{v_733, +v_734} = term_usage_map_list(v_726, v_720, v_5, v_8, v_9, v_14)
                      ArenaResult{v_738, +v_739} = core_pattern_list_depth(v_733, v_718)
                      ArenaResult{v_743, +v_744} = core_pattern_list_depth(v_738, v_718)
                      ArenaResult{v_748, +v_749} = shift_expected(v_743, v_12, v_744)
                      ArenaResult{v_753, +v_754} = term_usage_map(v_748, v_722, Nat.add(v_5, v_739), v_729, v_9, v_749, v_14)
                      v_50000252 = usage_merge(v_734, v_754, False{})
                      {ArenaResult{v_753, v_50000252} : ArenaResult<List<&2, UsageEntry>>}
                case _:
                  v_759 = v_558
                  v_761 = v_560
                  v_763 = v_555
                  ArenaResult{v_767, +v_768} = usage_local_env(v_595, v_759, v_761, v_8, v_8, v_9, v_14)
                  v_770 = v_768
                  ArenaResult{v_774, +v_775} = term_usage_map_list(v_767, v_761, v_5, v_8, v_9, v_14)
                  ArenaResult{v_779, +v_780} = core_pattern_list_depth(v_774, v_759)
                  ArenaResult{v_784, +v_785} = core_pattern_list_depth(v_779, v_759)
                  ArenaResult{v_789, +v_790} = shift_expected(v_784, v_12, v_785)
                  ArenaResult{v_794, +v_795} = term_usage_map(v_789, v_763, Nat.add(v_5, v_780), v_770, v_9, v_790, v_14)
                  v_50000253 = usage_merge(v_775, v_795, False{})
                  {ArenaResult{v_794, v_50000253} : ArenaResult<List<&2, UsageEntry>>}
            case _:
              v_800 = v_558
              v_802 = v_560
              v_804 = v_555
              ArenaResult{v_808, +v_809} = usage_local_env(v_573, v_800, v_802, v_8, v_8, v_9, v_14)
              v_811 = v_809
              ArenaResult{v_815, +v_816} = term_usage_map_list(v_808, v_802, v_5, v_8, v_9, v_14)
              ArenaResult{v_820, +v_821} = core_pattern_list_depth(v_815, v_800)
              ArenaResult{v_825, +v_826} = core_pattern_list_depth(v_820, v_800)
              ArenaResult{v_830, +v_831} = shift_expected(v_825, v_12, v_826)
              ArenaResult{v_835, +v_836} = term_usage_map(v_830, v_804, Nat.add(v_5, v_821), v_811, v_9, v_831, v_14)
              v_50000254 = usage_merge(v_816, v_836, False{})
              {ArenaResult{v_835, v_50000254} : ArenaResult<List<&2, UsageEntry>>}
        case _:
          v_841 = v_558
          v_843 = v_560
          v_845 = v_555
          ArenaResult{v_849, +v_850} = usage_local_env(v_564, v_841, v_843, v_8, v_8, v_9, v_14)
          v_852 = v_850
          ArenaResult{v_856, +v_857} = term_usage_map_list(v_849, v_843, v_5, v_8, v_9, v_14)
          ArenaResult{v_861, +v_862} = core_pattern_list_depth(v_856, v_841)
          ArenaResult{v_866, +v_867} = core_pattern_list_depth(v_861, v_841)
          ArenaResult{v_871, +v_872} = shift_expected(v_866, v_12, v_867)
          ArenaResult{v_876, +v_877} = term_usage_map(v_871, v_845, Nat.add(v_5, v_862), v_852, v_9, v_872, v_14)
          v_50000255 = usage_merge(v_857, v_877, False{})
          {ArenaResult{v_876, v_50000255} : ArenaResult<List<&2, UsageEntry>>}
    case Arena.BodyReply{+v_881, +v_882}:
      v_884 = v_881
      ArenaResult{v_888, +v_889} = term_usage_map(v_22, v_884, v_5, v_8, v_9, v_12, v_14)
      {ArenaResult{v_888, v_889} : ArenaResult<List<&2, UsageEntry>>}
    case _:
      {ArenaResult{v_22, []} : ArenaResult<List<&2, UsageEntry>>}

def usage_expected_known(v_20039175: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_4: U32, v_6: Nat, v_8: Nat, v_9: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  ArenaResult{v_20039176, +v_20039177} = arena_words_view(v_20039175, v_1)
  match v_20039177:
    case IR.WordNil{}:
      ArenaResult{v_20039178, +v_20039179} = arena_words_view(v_20039176, v_3)
      match v_20039179:
        case IR.WordNil{}:
          {ArenaResult{v_20039178, Some{v_4}} : ArenaResult<Maybe<&2, U32>>}
        case _:
          {ArenaResult{v_20039178, Some{v_4}} : ArenaResult<Maybe<&2, U32>>}
    case IR.WordCons{+v_20039183, +v_20039184}:
      ArenaResult{v_20039185, +v_20039186} = arena_words_view(v_20039176, v_3)
      match v_20039186:
        case IR.WordCons{+v_20039189, +v_20039190}:
          +v_18 = v_20039189
          v_19 = v_20039190
          +v_16 = v_20039183
          v_17 = v_20039184
          ArenaResult{v_20039191, +v_20039192} = core_pattern_depth(v_20039185, v_16)
          v_21 = v_20039192
          ArenaResult{v_20039193, +v_20039194} = scrutinee_variable_index(v_20039191, v_18, v_9)
          v_25 = maybe_shift_index(v_20039194, v_8)
          ArenaResult{v_20039195, +v_20039196} = pattern_value(v_20039193, v_16, Nat.add(v_6, v_21))
          v_28 = v_20039196
          ArenaResult{v_20039197, +v_20039198} = replace_match_expected(v_20039195, v_25, v_21, v_4, v_28)
          v_31 = v_20039198
          ArenaResult{v_20039199, +v_20039200} = usage_expected_known(v_20039197, v_17, v_19, v_31, Nat.add(v_6, v_21), Nat.add(v_8, v_21), v_9)
          {ArenaResult{v_20039199, v_20039200} : ArenaResult<Maybe<&2, U32>>}
        case _:
          {ArenaResult{v_20039185, Some{v_4}} : ArenaResult<Maybe<&2, U32>>}
    case _:
      {ArenaResult{v_20039176, Some{v_4}} : ArenaResult<Maybe<&2, U32>>}

def usage_expected_patterns(v_20039203: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_5: Maybe<&2, U32>, v_7: Nat, v_9: Nat, v_10: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, U32>>:
  match v_5:
    case None{}:
      {ArenaResult{v_20039203, None{}} : ArenaResult<Maybe<&2, U32>>}
    case Some{+v_20039204}:
      v_13 = v_20039204
      ArenaResult{v_20039205, +v_20039206} = usage_expected_known(v_20039203, v_1, v_3, v_13, v_7, v_9, v_10)
      {ArenaResult{v_20039205, v_20039206} : ArenaResult<Maybe<&2, U32>>}

def term_usage_map_cases(v_1: ArenaStore, v_2: IR.Words, v_3: IR.Words, v_4: IR.Words, v_6: Nat, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope, v_13: Maybe<&2, U32>, v_15: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  ArenaResult{v_23, +v_24} = arena_words_view(v_1, v_2)
  match v_24:
    case IR.WordNil{}:
      {ArenaResult{v_23, []} : ArenaResult<List<&2, UsageEntry>>}
    case IR.WordCons{+v_27, +v_28}:
      +v_30 = v_27
      v_32 = v_28
      ArenaResult{v_36, +v_37} = term_usage_map_case(v_23, v_30, v_3, v_4, v_6, v_9, v_10, v_13, v_15)
      v_39 = v_37
      ArenaResult{v_43, +v_44} = term_usage_map_cases(v_36, v_32, v_3, v_4, v_6, v_9, v_10, v_13, v_15)
      v_50000256 = usage_merge(v_39, v_44, True{})
      {ArenaResult{v_43, v_50000256} : ArenaResult<List<&2, UsageEntry>>}

def term_usage_map_case(v_20039216: ArenaStore, v_0: U32, v_2: IR.Words, v_4: IR.Words, v_6: Nat, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope, v_12: Maybe<&2, U32>, v_14: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  ArenaResult{v_20039217, +v_20039218} = arena_get_node(v_20039216, v_0)
  match v_20039218:
    case Arena.BodyCase{+v_20039222, +v_20039223, +v_20039225, +v_20039226}:
      +v_20039224 = IR.Words{v_20039222, v_20039223}
      v_20 = v_20039224
      v_21 = v_20039225
      ArenaResult{v_20039227, +v_20039228} = core_pattern_list_depth(v_20039217, v_20)
      ArenaResult{v_20039229, +v_20039230} = usage_pattern_env(v_20039227, v_20, v_4, v_2, v_9, v_10, v_20039228, 0n)
      v_25 = v_20039230
      ArenaResult{v_20039231, +v_20039232} = usage_expected_patterns(v_20039229, v_20, v_2, v_12, List.length(&2, Binding, v_9), 0n, v_10)
      v_29 = v_20039232
      ArenaResult{v_20039233, +v_20039234} = core_pattern_list_depth(v_20039231, v_20)
      v_31 = v_20039234
      ArenaResult{v_20039235, +v_20039236} = match_branch_body(v_20039233, v_20, v_2, v_21, v_31, Nat.add(List.length(&2, Binding, v_9), v_31), v_10)
      v_35 = v_20039236
      ArenaResult{v_20039237, +v_20039238} = term_usage_map(v_20039235, v_35, Nat.add(v_6, v_31), v_25, v_10, v_29, v_14)
      {ArenaResult{v_20039237, v_20039238} : ArenaResult<List<&2, UsageEntry>>}
    case _:
      ArenaResult{v_20039240, +v_20039241} = term_usage_map(v_20039217, v_0, v_6, v_9, v_10, v_12, v_14)
      {ArenaResult{v_20039240, v_20039241} : ArenaResult<List<&2, UsageEntry>>}

def term_usage_map_list(v_1: ArenaStore, v_2: IR.Words, v_4: Nat, v_7: List<&2, Binding>, v_8: Scope.ArenaGlobalScope, v_10: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  ArenaResult{v_18, +v_19} = arena_words_view(v_1, v_2)
  match v_19:
    case IR.WordNil{}:
      {ArenaResult{v_18, []} : ArenaResult<List<&2, UsageEntry>>}
    case IR.WordCons{+v_22, +v_23}:
      +v_25 = v_22
      v_27 = v_23
      ArenaResult{v_31, +v_32} = term_usage_map(v_18, v_25, v_4, v_7, v_8, None{}, v_10)
      ArenaResult{v_36, +v_37} = term_usage_map_list(v_31, v_27, v_4, v_7, v_8, v_10)
      v_50000257 = usage_merge(v_32, v_37, False{})
      {ArenaResult{v_36, v_50000257} : ArenaResult<List<&2, UsageEntry>>}

def term_usage_map_quantified_list(v_1: ArenaStore, v_2: IR.Words, v_3: IR.Quantities, v_5: Nat, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope, v_11: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  ArenaResult{v_19, +v_20} = arena_words_view(v_1, v_2)
  match v_20:
    case IR.WordNil{}:
      ArenaResult{v_24, +v_25} = arena_quantities_view(v_19, v_3)
      match v_25:
        case IR.QuantityNil{}:
          {ArenaResult{v_24, []} : ArenaResult<List<&2, UsageEntry>>}
        case _:
          ArenaResult{v_31, +v_32} = term_usage_map_list(v_24, v_2, v_5, v_8, v_9, v_11)
          {ArenaResult{v_31, v_32} : ArenaResult<List<&2, UsageEntry>>}
    case IR.WordCons{+v_35, +v_36}:
      ArenaResult{v_40, +v_41} = arena_quantities_view(v_19, v_3)
      match v_41:
        case IR.QuantityCons{+v_44, +v_45}:
          +v_47 = v_44
          v_49 = v_45
          +v_51 = v_35
          v_53 = v_36
          match v_47:
            case Ast.QZero{}:
              ArenaResult{v_57, +v_58} = term_usage_map_quantified_list(v_40, v_53, v_49, v_5, v_8, v_9, v_11)
              {ArenaResult{v_57, v_58} : ArenaResult<List<&2, UsageEntry>>}
            case _:
              ArenaResult{v_64, +v_65} = term_usage_map(v_40, v_51, v_5, v_8, v_9, None{}, v_11)
              ArenaResult{v_69, +v_70} = term_usage_map_quantified_list(v_64, v_53, v_49, v_5, v_8, v_9, v_11)
              v_50000258 = usage_merge(v_65, v_70, False{})
              {ArenaResult{v_69, v_50000258} : ArenaResult<List<&2, UsageEntry>>}
        case _:
          ArenaResult{v_77, +v_78} = term_usage_map_list(v_40, v_2, v_5, v_8, v_9, v_11)
          {ArenaResult{v_77, v_78} : ArenaResult<List<&2, UsageEntry>>}
    case _:
      ArenaResult{v_84, +v_85} = term_usage_map_list(v_19, v_2, v_5, v_8, v_9, v_11)
      {ArenaResult{v_84, v_85} : ArenaResult<List<&2, UsageEntry>>}

def use_count_with_globals(v_1: ArenaStore, v_3: U32, v_5: Nat, v_7: Nat, v_8: Scope.ArenaGlobalScope) -> ArenaResult<Ast.Quantity>:
  ArenaResult{v_14, +v_15} = term_usage_map(v_1, v_3, v_7, [], v_8, None{}, False{})
  v_50000259 = usage_get(v_5, v_15)
  {ArenaResult{v_14, v_50000259} : ArenaResult<Ast.Quantity>}

def use_count_with_expected(v_1: ArenaStore, v_3: U32, v_5: Nat, v_8: List<&2, Binding>, v_9: Scope.ArenaGlobalScope, v_11: U32) -> ArenaResult<Ast.Quantity>:
  ArenaResult{v_17, +v_18} = term_usage_map(v_1, v_3, 0n, v_8, v_9, Some{v_11}, False{})
  v_50000260 = usage_get(v_5, v_18)
  {ArenaResult{v_17, v_50000260} : ArenaResult<Ast.Quantity>}

def binder_count(v_20039288: ArenaStore, v_1: IR.Words) -> ArenaResult<Nat>:
  ArenaResult{v_20039289, +v_20039290} = arena_words_view(v_20039288, v_1)
  match v_20039290:
    case IR.WordNil{}:
      {ArenaResult{v_20039289, 0n} : ArenaResult<Nat>}
    case IR.WordCons{+v_20039291, +v_20039292}:
      v_6 = v_20039292
      ArenaResult{v_20039293, +v_20039294} = binder_count(v_20039289, v_6)
      {ArenaResult{v_20039293, Nat.add(1n, v_20039294)} : ArenaResult<Nat>}

def binder_usage_map(v_20039295: ArenaStore, v_1: Nat, v_2: U32, v_5: List<&2, Binding>, v_6: Scope.ArenaGlobalScope, v_8: Maybe<&2, U32>, v_10: Bool) -> ArenaResult<List<&2, UsageEntry>>:
  match v_1:
    case 0n:
      {ArenaResult{v_20039295, []} : ArenaResult<List<&2, UsageEntry>>}
    case _:
      ArenaResult{v_20039297, +v_20039298} = term_usage_map(v_20039295, v_2, 0n, v_5, v_6, v_8, v_10)
      {ArenaResult{v_20039297, v_20039298} : ArenaResult<List<&2, UsageEntry>>}

def check_binder_usage_map(v_1: ArenaStore, v_2: IR.Words, v_4: Nat, v_7: List<&2, UsageEntry>) -> ArenaResult<Maybe<&2, Diagnostic>>:
  ArenaResult{v_15, +v_16} = arena_words_view(v_1, v_2)
  match v_16:
    case IR.WordNil{}:
      {ArenaResult{v_15, None{}} : ArenaResult<Maybe<&2, Diagnostic>>}
    case IR.WordCons{+v_19, +v_20}:
      +v_22 = v_19
      v_24 = v_20
      ArenaResult{v_28, +v_29} = arena_get_binder(v_15, v_22)
      match v_29:
        case Arena.Binder{+v_35, +v_36, +v_37, +v_38, +v_39}:
          ArenaResult{v_43, +v_44} = arena_name_text(v_28, v_36)
          +v_46 = v_44
          v_48 = v_35
          v_50 = v_46
          v_52 = v_39
          v_54 = Nat.sub(v_4, 1n)
          +v_58 = quantity_fits(usage_get(v_54, v_7), v_48)
          match v_58:
            case False{}:
              v_50000261 = span_file(v_52)
              v_50000262 = Diagnostic{v_50000261, v_52, String.append("invalid use quantity for ", v_50), "within the binder quantity", "too many uses"}
              +v_61 = Some{v_50000262}
              v_63 = v_43
              {ArenaResult{v_63, v_61} : ArenaResult<Maybe<&2, Diagnostic>>}
            case True{}:
              ArenaResult{v_68, +v_69} = check_binder_usage_map(v_43, v_24, v_54, v_7)
              +v_71 = v_69
              v_73 = v_68
              {ArenaResult{v_73, v_71} : ArenaResult<Maybe<&2, Diagnostic>>}
        case Arena.TemplateBinder{+v_79, +v_80, +v_81, +v_82}:
          ArenaResult{v_86, +v_87} = arena_name_text(v_28, v_79)
          +v_89 = v_87
          v_91 = v_89
          v_93 = v_82
          v_95 = Nat.sub(v_4, 1n)
          +v_99 = quantity_fits(usage_get(v_95, v_7), Ast.QZero{})
          match v_99:
            case False{}:
              v_50000263 = span_file(v_93)
              v_50000264 = Diagnostic{v_50000263, v_93, String.append("compile-time template binder used at runtime: ", v_91), "no runtime uses", "a runtime use"}
              +v_102 = Some{v_50000264}
              v_104 = v_86
              {ArenaResult{v_104, v_102} : ArenaResult<Maybe<&2, Diagnostic>>}
            case True{}:
              ArenaResult{v_109, +v_110} = check_binder_usage_map(v_86, v_24, v_95, v_7)
              +v_112 = v_110
              v_114 = v_109
              {ArenaResult{v_114, v_112} : ArenaResult<Maybe<&2, Diagnostic>>}

def binders_env(v_20039331: ArenaStore, v_1: IR.Words, v_4: List<&2, Binding>) -> ArenaResult<List<&2, Binding>>:
  ArenaResult{v_20039332, +v_20039333} = arena_words_view(v_20039331, v_1)
  match v_20039333:
    case IR.WordNil{}:
      {ArenaResult{v_20039332, v_4} : ArenaResult<List<&2, Binding>>}
    case IR.WordCons{+v_20039334, +v_20039335}:
      +v_9 = v_20039334
      v_10 = v_20039335
      ArenaResult{v_20039336, +v_20039337} = arena_get_binder(v_20039332, v_9)
      match v_20039337:
        case Arena.Binder{+v_20039338, +v_20039339, +v_20039341, +v_20039342, +v_20039343}:
          ArenaResult{v_20039344, +v_20039345} = arena_name_text(v_20039336, v_20039339)
          +v_20039340 = v_20039345
          v_16 = v_20039338
          v_17 = v_20039340
          v_19 = v_20039342
          ArenaResult{v_20039346, +v_20039347} = binders_env(v_20039344, v_10, Binding{v_17, v_16, v_19, List.length(&2, Binding, v_4)} <> v_4)
          {ArenaResult{v_20039346, v_20039347} : ArenaResult<List<&2, Binding>>}
        case Arena.TemplateBinder{+v_20039348, +v_20039350, +v_20039351, +v_20039352}:
          ArenaResult{v_20039353, +v_20039354} = arena_name_text(v_20039336, v_20039348)
          +v_20039349 = v_20039354
          v_27 = v_20039349
          v_29 = v_20039351
          ArenaResult{v_20039355, +v_20039356} = binders_env(v_20039353, v_10, Binding{v_27, Ast.QZero{}, v_29, List.length(&2, Binding, v_4)} <> v_4)
          {ArenaResult{v_20039355, v_20039356} : ArenaResult<List<&2, Binding>>}

def binders_type(v_20039357: ArenaStore, v_1: IR.Words, v_2: U32) -> ArenaResult<U32>:
  ArenaResult{v_20039358, +v_20039359} = arena_words_view(v_20039357, v_1)
  match v_20039359:
    case IR.WordNil{}:
      {ArenaResult{v_20039358, v_2} : ArenaResult<U32>}
    case IR.WordCons{+v_20039360, +v_20039361}:
      +v_5 = v_20039360
      v_6 = v_20039361
      ArenaResult{v_20039362, +v_20039363} = arena_get_binder(v_20039358, v_5)
      match v_20039363:
        case Arena.Binder{+v_20039364, +v_20039365, +v_20039367, +v_20039368, +v_20039369}:
          ArenaResult{v_20039370, +v_20039371} = arena_name_text(v_20039362, v_20039365)
          +v_20039366 = v_20039371
          v_12 = v_20039364
          v_13 = v_20039366
          v_14 = v_20039367
          v_15 = v_20039368
          v_16 = v_20039369
          ArenaResult{v_20039372, +v_20039373} = binders_type(v_20039370, v_6, v_2)
          ArenaResult{v_20039374, +v_20039375} = arena_name(v_20039372, v_13)
          ArenaResult{v_20039376, +v_20039377} = arena_put_node(v_20039374, Arena.TermAll{v_12, v_20039375, v_14, v_15, v_20039373, v_16})
          {ArenaResult{v_20039376, v_20039377} : ArenaResult<U32>}
        case Arena.TemplateBinder{+v_20039378, +v_20039380, +v_20039381, +v_20039382}:
          ArenaResult{v_20039383, +v_20039384} = arena_name_text(v_20039362, v_20039378)
          +v_20039379 = v_20039384
          v_22 = v_20039379
          v_23 = v_20039380
          v_24 = v_20039381
          v_25 = v_20039382
          ArenaResult{v_20039385, +v_20039386} = binders_type(v_20039383, v_6, v_2)
          ArenaResult{v_20039387, +v_20039388} = arena_name(v_20039385, v_22)
          ArenaResult{v_20039389, +v_20039390} = arena_put_node(v_20039387, Arena.TermAll{Ast.QZero{}, v_20039388, v_23, v_24, v_20039386, v_25})
          {ArenaResult{v_20039389, v_20039390} : ArenaResult<U32>}

def binders_lambda(v_20039391: ArenaStore, v_1: IR.Words, v_2: U32) -> ArenaResult<U32>:
  ArenaResult{v_20039392, +v_20039393} = arena_words_view(v_20039391, v_1)
  match v_20039393:
    case IR.WordNil{}:
      {ArenaResult{v_20039392, v_2} : ArenaResult<U32>}
    case IR.WordCons{+v_20039394, +v_20039395}:
      +v_5 = v_20039394
      v_6 = v_20039395
      ArenaResult{v_20039396, +v_20039397} = arena_get_binder(v_20039392, v_5)
      match v_20039397:
        case Arena.Binder{+v_20039398, +v_20039399, +v_20039401, +v_20039402, +v_20039403}:
          ArenaResult{v_20039404, +v_20039405} = arena_name_text(v_20039396, v_20039399)
          +v_20039400 = v_20039405
          v_12 = v_20039398
          v_13 = v_20039400
          v_14 = v_20039401
          v_16 = v_20039403
          ArenaResult{v_20039406, +v_20039407} = binders_lambda(v_20039404, v_6, v_2)
          ArenaResult{v_20039408, +v_20039409} = arena_name(v_20039406, v_13)
          ArenaResult{v_20039410, +v_20039411} = arena_put_node(v_20039408, Arena.TermLam{Some{v_12}, v_20039409, v_14, v_20039407, v_16})
          {ArenaResult{v_20039410, v_20039411} : ArenaResult<U32>}
        case Arena.TemplateBinder{+v_20039412, +v_20039414, +v_20039415, +v_20039416}:
          ArenaResult{v_20039417, +v_20039418} = arena_name_text(v_20039396, v_20039412)
          +v_20039413 = v_20039418
          v_22 = v_20039413
          v_23 = v_20039414
          v_25 = v_20039416
          ArenaResult{v_20039419, +v_20039420} = binders_lambda(v_20039417, v_6, v_2)
          ArenaResult{v_20039421, +v_20039422} = arena_name(v_20039419, v_22)
          ArenaResult{v_20039423, +v_20039424} = arena_put_node(v_20039421, Arena.TermLam{Some{Ast.QZero{}}, v_20039422, v_23, v_20039420, v_25})
          {ArenaResult{v_20039423, v_20039424} : ArenaResult<U32>}

def parameter_vars(v_20039425: ArenaStore, v_1: IR.Words, v_3: Nat, v_4: Ast.SourceSpan) -> ArenaResult<IR.Words>:
  ArenaResult{v_20039426, +v_20039427} = arena_words_view(v_20039425, v_1)
  match v_20039427:
    case IR.WordNil{}:
      {ArenaResult{v_20039426, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20039428, +v_20039429}:
      +v_8 = v_20039428
      v_9 = v_20039429
      ArenaResult{v_20039430, +v_20039431} = arena_get_binder(v_20039426, v_8)
      match v_20039431:
        case Arena.Binder{+v_20039432, +v_20039433, +v_20039435, +v_20039436, +v_20039437}:
          ArenaResult{v_20039438, +v_20039439} = arena_name_text(v_20039430, v_20039433)
          +v_20039434 = v_20039439
          v_16 = v_20039434
          v_21 = Nat.sub(v_3, 1n)
          ArenaResult{v_20039440, +v_20039441} = arena_name(v_20039438, v_16)
          ArenaResult{v_20039442, +v_20039443} = arena_put_node(v_20039440, Arena.TermVar{v_20039441, v_21, v_4})
          ArenaResult{v_20039444, +v_20039445} = parameter_vars(v_20039442, v_9, v_21, v_4)
          ArenaResult{v_20039446, +v_20039447} = arena_words_cons(v_20039444, v_20039443, v_20039445)
          {ArenaResult{v_20039446, v_20039447} : ArenaResult<IR.Words>}
        case Arena.TemplateBinder{+v_20039448, +v_20039450, +v_20039451, +v_20039452}:
          ArenaResult{v_20039453, +v_20039454} = arena_name_text(v_20039430, v_20039448)
          +v_20039449 = v_20039454
          v_27 = v_20039449
          v_32 = Nat.sub(v_3, 1n)
          ArenaResult{v_20039455, +v_20039456} = arena_name(v_20039453, v_27)
          ArenaResult{v_20039457, +v_20039458} = arena_put_node(v_20039455, Arena.TermVar{v_20039456, v_32, v_4})
          ArenaResult{v_20039459, +v_20039460} = parameter_vars(v_20039457, v_9, v_32, v_4)
          ArenaResult{v_20039461, +v_20039462} = arena_words_cons(v_20039459, v_20039458, v_20039460)
          {ArenaResult{v_20039461, v_20039462} : ArenaResult<IR.Words>}

def shift_terms(v_20039463: ArenaStore, v_1: IR.Words, v_3: Nat) -> ArenaResult<IR.Words>:
  ArenaResult{v_20039464, +v_20039465} = arena_words_view(v_20039463, v_1)
  match v_20039465:
    case IR.WordNil{}:
      {ArenaResult{v_20039464, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20039466, +v_20039467}:
      +v_7 = v_20039466
      v_8 = v_20039467
      ArenaResult{v_20039468, +v_20039469} = core_shift(v_20039464, 0n, v_3, v_7)
      ArenaResult{v_20039470, +v_20039471} = shift_terms(v_20039468, v_8, v_3)
      ArenaResult{v_20039472, +v_20039473} = arena_words_cons(v_20039470, v_20039469, v_20039471)
      {ArenaResult{v_20039472, v_20039473} : ArenaResult<IR.Words>}

def apply_prefix(v_20039474: ArenaStore, v_1: IR.Words, v_2: U32) -> ArenaResult<Maybe<&2, U32>>:
  ArenaResult{v_20039475, +v_20039476} = arena_words_view(v_20039474, v_1)
  match v_20039476:
    case IR.WordNil{}:
      {ArenaResult{v_20039475, Some{v_2}} : ArenaResult<Maybe<&2, U32>>}
    case IR.WordCons{+v_20039477, +v_20039478}:
      +v_7 = v_20039477
      v_8 = v_20039478
      ArenaResult{v_20039479, +v_20039480} = arena_get_node(v_20039475, v_2)
      match v_20039480:
        case Arena.TermAll{+v_20039487, +v_20039488, +v_20039490, +v_20039491, +v_20039492, +v_20039493}:
          v_19 = v_20039492
          ArenaResult{v_20039494, +v_20039495} = core_subst(v_20039479, 0n, v_7, v_19)
          ArenaResult{v_20039496, +v_20039497} = apply_prefix(v_20039494, v_8, v_20039495)
          {ArenaResult{v_20039496, v_20039497} : ArenaResult<Maybe<&2, U32>>}
        case _:
          {ArenaResult{v_20039479, None{}} : ArenaResult<Maybe<&2, U32>>}

def check_ctr_fields_result(v_1: Inference, v_2: U32) -> Inference:
  match v_1:
    case Inferred{+v_20039499, +v_20039500}:
      v_7 = v_20039500
      Inferred{v_2, v_7}
    case InferenceFailure{+v_20039501}:
      v_9 = v_20039501
      InferenceFailure{v_9}

def check_ctr_fields_arg(v_1: ArenaStore, v_3: Inference, v_4: IR.Words, v_6: U32, v_8: U32, v_11: List<&2, Binding>, v_12: Scope.ArenaGlobalScope, v_14: U32, v_15: Ast.SourceSpan, v_17: U32) -> ArenaResult<Inference>:
  match v_3:
    case Inferred{+v_23, +v_24}:
      v_26 = v_23
      ArenaResult{v_30, +v_31} = core_subst(v_1, 0n, v_26, v_6)
      ArenaResult{v_35, +v_36} = check_ctr_fields(v_30, v_4, v_31, v_8, v_11, v_12, v_14, v_15, v_17)
      v_50000265 = check_ctr_fields_result(v_36, v_14)
      {ArenaResult{v_35, v_50000265} : ArenaResult<Inference>}
    case InferenceFailure{+v_39}:
      v_41 = v_39
      {ArenaResult{v_1, InferenceFailure{v_41}} : ArenaResult<Inference>}

def check_ctr_fields_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: IR.Words, v_8: U32, v_11: List<&2, Binding>, v_12: Scope.ArenaGlobalScope, v_14: U32, v_15: Ast.SourceSpan, v_17: U32) -> ArenaResult<Inference>:
  ArenaResult{v_24, +v_25} = arena_get_node(v_1, v_3)
  match v_25:
    case Arena.TermAll{+v_32, +v_33, +v_34, +v_35, +v_36, +v_37}:
      v_39 = v_35
      v_41 = v_36
      ArenaResult{v_45, +v_46} = check_term(v_24, v_5, v_11, v_12, v_39)
      ArenaResult{v_50, +v_51} = check_ctr_fields_arg(v_45, v_46, v_6, v_41, v_8, v_11, v_12, v_14, v_15, v_17)
      {ArenaResult{v_50, v_51} : ArenaResult<Inference>}
    case _:
      v_50000266 = fail(v_15, "constructor has too many fields", "a remaining field", "an extra field")
      {ArenaResult{v_24, v_50000266} : ArenaResult<Inference>}

def check_ctr_fields_fit(v_1: Bool, v_2: U32, v_3: U32, v_4: Ast.SourceSpan) -> Inference:
  +v_20039532 = v_1
  match v_20039532:
    case False{}:
      +v_20039531 = fail(v_4, "constructor result does not match expected datatype", "the expected datatype", "a different result type")
      v_20039531
    case True{}:
      +v_20039531 = Inferred{v_3, v_2}
      v_20039531

def check_ctr_fields(v_1: ArenaStore, v_2: IR.Words, v_4: U32, v_6: U32, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope, v_12: U32, v_13: Ast.SourceSpan, v_15: U32) -> ArenaResult<Inference>:
  ArenaResult{v_22, +v_23} = arena_words_view(v_1, v_2)
  match v_23:
    case IR.WordNil{}:
      ArenaResult{v_27, +v_28} = fits_term_target_view(v_22, v_4, v_6, v_15, v_10)
      v_50000267 = check_ctr_fields_fit(v_28, v_6, v_12, v_13)
      {ArenaResult{v_27, v_50000267} : ArenaResult<Inference>}
    case IR.WordCons{+v_32, +v_33}:
      +v_35 = v_32
      v_37 = v_33
      ArenaResult{v_41, +v_42} = whnf(v_22, 64n, v_4, v_10)
      ArenaResult{v_46, +v_47} = check_ctr_fields_view(v_41, v_42, v_35, v_37, v_6, v_9, v_10, v_12, v_13, v_15)
      {ArenaResult{v_46, v_47} : ArenaResult<Inference>}

def check_live_fields_result(v_20039544: ArenaStore, v_1: Inference, v_3: IR.Words, v_4: U32, v_6: Nat, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope, v_12: String, v_13: Ast.Quantity, v_14: U32, v_15: Ast.SourceSpan) -> ArenaResult<Maybe<&2, Diagnostic>>:
  match v_1:
    case Inferred{+v_20039545, +v_20039546}:
      ArenaResult{v_20039547, +v_20039548} = check_live_fields(v_20039544, v_3, v_4, Nat.add(v_6, 1n), Binding{v_12, v_13, v_14, List.length(&2, Binding, v_9)} <> v_9, v_10)
      {ArenaResult{v_20039547, v_20039548} : ArenaResult<Maybe<&2, Diagnostic>>}
    case InferenceFailure{+v_20039549}:
      v_25 = v_20039549
      {ArenaResult{v_20039544, Some{v_25}} : ArenaResult<Maybe<&2, Diagnostic>>}

def check_live_fields(v_1: ArenaStore, v_2: IR.Words, v_4: U32, v_6: Nat, v_9: List<&2, Binding>, v_10: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Diagnostic>>:
  ArenaResult{v_18, +v_19} = arena_words_view(v_1, v_2)
  match v_19:
    case IR.WordNil{}:
      {ArenaResult{v_18, None{}} : ArenaResult<Maybe<&2, Diagnostic>>}
    case IR.WordCons{+v_22, +v_23}:
      +v_25 = v_22
      v_27 = v_23
      ArenaResult{v_31, +v_32} = arena_get_binder(v_18, v_25)
      match v_32:
        case Arena.Binder{+v_38, +v_39, +v_40, +v_41, +v_42}:
          ArenaResult{v_46, +v_47} = arena_name_text(v_31, v_39)
          +v_49 = v_47
          v_51 = v_38
          v_53 = v_49
          v_55 = v_41
          v_57 = v_42
          ArenaResult{v_61, +v_62} = live_field_goal(v_46, v_51, v_6, v_4, v_57)
          v_64 = v_62
          ArenaResult{v_68, +v_69} = check_term(v_61, v_55, v_9, v_10, v_64)
          ArenaResult{v_73, +v_74} = check_live_fields_result(v_68, v_69, v_27, v_4, v_6, v_9, v_10, v_53, v_51, v_55, v_57)
          {ArenaResult{v_73, v_74} : ArenaResult<Maybe<&2, Diagnostic>>}
        case Arena.TemplateBinder{+v_79, +v_80, +v_81, +v_82}:
          ArenaResult{v_86, +v_87} = arena_name_text(v_31, v_79)
          +v_89 = v_87
          v_91 = v_89
          v_93 = v_82
          v_50000268 = span_file(v_93)
          v_50000269 = Diagnostic{v_50000268, v_93, String.append("constructor field cannot be a compile-time template binder: ", v_91), "a runtime constructor field", "a template binder"}
          v_50000270 = Some{v_50000269}
          {ArenaResult{v_86, v_50000270} : ArenaResult<Maybe<&2, Diagnostic>>}

def live_field_goal(v_20039578: ArenaStore, v_0: Ast.Quantity, v_2: Nat, v_3: U32, v_4: Ast.SourceSpan) -> ArenaResult<U32>:
  match v_0:
    case Ast.QOne{}:
      ArenaResult{v_20039579, +v_20039580} = core_shift(v_20039578, 0n, v_2, v_3)
      {ArenaResult{v_20039579, v_20039580} : ArenaResult<U32>}
    case _:
      ArenaResult{v_20039582, +v_20039583} = arena_put_node(v_20039578, Arena.TermQuantity{v_0, v_4})
      ArenaResult{v_20039584, +v_20039585} = arena_put_node(v_20039582, Arena.TermType{v_20039583, v_4})
      {ArenaResult{v_20039584, v_20039585} : ArenaResult<U32>}

def check_constructors_fields_result(v_1: ArenaStore, v_4: Maybe<&2, Diagnostic>, v_6: List<&2, IR.ConstructorDecl>, v_8: String, v_9: IR.Words, v_11: U32, v_13: String, v_14: Scope.ArenaGlobalScope, v_15: Scope.ArenaGlobalScope, v_16: Ast.SourceSpan, v_18: String, v_19: Ast.SourceSpan, v_21: U32) -> ArenaResult<ScopedState>:
  match v_4:
    case Some{+v_26}:
      v_28 = v_26
      {ArenaResult{v_1, ScopedStateFailure{v_28}} : ArenaResult<ScopedState>}
    case None{}:
      ArenaResult{v_32, +v_33} = canonicalize_term(v_1, v_21, v_15)
      v_50000271 = canonical_key(v_13, v_18)
      ArenaResult{v_38, +v_39} = arena_publish_global(v_32, Scope.ArenaGlobal{v_50000271, v_13, v_18, v_33, IR.NoTerm{}, Scope.GlobalConstructor{}})
      v_41 = v_39
      ArenaResult{v_45, +v_46} = arena_publish_global(v_38, Scope.ArenaGlobal{v_18, v_13, v_18, v_21, IR.NoTerm{}, Scope.GlobalConstructor{}})
      v_48 = v_46
      ArenaResult{v_52, +v_53} = global_scope_prepend(v_45, v_41, v_14)
      ArenaResult{v_57, +v_58} = global_scope_prepend(v_52, v_48, v_15)
      ArenaResult{v_62, +v_63} = check_constructors(v_57, v_6, v_8, v_9, v_11, v_13, v_53, v_58, v_16)
      {ArenaResult{v_62, v_63} : ArenaResult<ScopedState>}

def check_constructors_type_result(v_1: ArenaStore, v_3: Inference, v_4: IR.Words, v_6: List<&2, IR.ConstructorDecl>, v_8: String, v_9: IR.Words, v_11: U32, v_13: String, v_14: Scope.ArenaGlobalScope, v_15: Scope.ArenaGlobalScope, v_16: Ast.SourceSpan, v_18: String, v_19: Ast.SourceSpan, v_21: U32) -> ArenaResult<ScopedState>:
  match v_3:
    case Inferred{+v_27, +v_28}:
      ArenaResult{v_32, +v_33} = arena_get_node(v_1, v_28)
      match v_33:
        case Arena.TermType{+v_36, +v_37}:
          ArenaResult{v_41, +v_42} = binders_env(v_32, v_9, [])
          ArenaResult{v_46, +v_47} = check_live_fields(v_41, v_4, v_11, 0n, v_42, v_15)
          ArenaResult{v_51, +v_52} = check_constructors_fields_result(v_46, v_47, v_6, v_8, v_9, v_11, v_13, v_14, v_15, v_16, v_18, v_19, v_21)
          {ArenaResult{v_51, v_52} : ArenaResult<ScopedState>}
        case _:
          v_50000272 = span_file(v_19)
          v_50000273 = Diagnostic{v_50000272, v_19, String.append("constructor type is invalid: ", v_18), "a constructor telescope returning its family", "an invalid telescope"}
          v_50000274 = ScopedStateFailure{v_50000273}
          {ArenaResult{v_32, v_50000274} : ArenaResult<ScopedState>}
    case InferenceFailure{+v_57}:
      v_59 = v_57
      {ArenaResult{v_1, ScopedStateFailure{v_59}} : ArenaResult<ScopedState>}

def check_constructors_unique(v_1: ArenaStore, v_3: Maybe<&2, Scope.ArenaGlobal>, v_4: IR.Words, v_6: List<&2, IR.ConstructorDecl>, v_8: String, v_9: IR.Words, v_11: U32, v_13: String, v_14: Scope.ArenaGlobalScope, v_15: Scope.ArenaGlobalScope, v_16: Ast.SourceSpan, v_18: String, v_19: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_3:
    case Some{+v_24}:
      v_50000275 = span_file(v_19)
      v_50000276 = Diagnostic{v_50000275, v_19, String.append("duplicate constructor: ", v_18), "a fresh constructor name", "an existing declaration"}
      v_50000277 = ScopedStateFailure{v_50000276}
      {ArenaResult{v_1, v_50000277} : ArenaResult<ScopedState>}
    case None{}:
      ArenaResult{v_29, +v_30} = binder_count(v_1, v_9)
      ArenaResult{v_34, +v_35} = parameter_vars(v_29, v_9, v_30, v_19)
      v_37 = v_35
      ArenaResult{v_41, +v_42} = binder_count(v_34, v_4)
      ArenaResult{v_46, +v_47} = shift_terms(v_41, v_37, v_42)
      v_49 = v_47
      ArenaResult{v_53, +v_54} = arena_name(v_46, v_8)
      v_50000278 = arena_words_start(v_49)
      v_50000279 = arena_words_count(v_49)
      v_50000280 = arena_names_start(IR.Names{0, 0})
      v_50000281 = arena_names_count(IR.Names{0, 0})
      ArenaResult{v_62, +v_63} = arena_put_node(v_53, Arena.TermAdt{v_54, v_50000278, v_50000279, v_50000280, v_50000281, v_19})
      v_65 = v_63
      ArenaResult{v_69, +v_70} = binders_type(v_62, v_4, v_65)
      ArenaResult{v_74, +v_75} = binders_type(v_69, v_9, v_70)
      v_77 = v_75
      ArenaResult{v_81, +v_82} = infer(v_74, v_77, [], v_15)
      ArenaResult{v_86, +v_87} = check_constructors_type_result(v_81, v_82, v_4, v_6, v_8, v_9, v_11, v_13, v_14, v_15, v_16, v_18, v_19, v_77)
      {ArenaResult{v_86, v_87} : ArenaResult<ScopedState>}

def check_constructors(v_20039639: ArenaStore, v_1: List<&2, IR.ConstructorDecl>, v_3: String, v_5: IR.Words, v_6: U32, v_8: String, v_9: Scope.ArenaGlobalScope, v_10: Scope.ArenaGlobalScope, v_11: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_1:
    case []:
      {ArenaResult{v_20039639, ScopedState{v_9}} : ArenaResult<ScopedState>}
    case +v_20039640 <> +v_20039641:
      +v_15 = v_20039640
      v_16 = v_20039641
      match v_15:
        case IR.Constructor{+v_20039642, +v_20039643, +v_20039644}:
          v_20 = v_20039642
          v_21 = v_20039643
          v_22 = v_20039644
          ArenaResult{v_20039645, +v_20039646} = check_constructors_unique(v_20039639, Scope.lookup_kind(canonical_key(v_8, v_20), Scope.GlobalConstructor{}, v_9), v_21, v_16, v_3, v_5, v_6, v_8, v_9, v_10, v_11, v_20, v_22)
          {ArenaResult{v_20039645, v_20039646} : ArenaResult<ScopedState>}

def check_type_decl_result(v_1: ArenaStore, v_3: Inference, v_5: String, v_6: IR.Words, v_8: U32, v_10: List<&2, IR.ConstructorDecl>, v_11: Scope.ArenaGlobal, v_12: Scope.ArenaGlobal, v_14: U32, v_16: String, v_17: Scope.ArenaGlobalScope, v_18: Scope.ArenaGlobalScope, v_19: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_3:
    case Inferred{+v_25, +v_26}:
      ArenaResult{v_30, +v_31} = arena_get_node(v_1, v_26)
      match v_31:
        case Arena.TermType{+v_34, +v_35}:
          ArenaResult{v_39, +v_40} = global_scope_prepend(v_30, v_11, v_17)
          ArenaResult{v_44, +v_45} = global_scope_prepend(v_39, v_12, v_18)
          ArenaResult{v_49, +v_50} = global_scope_prepend(v_44, v_11, v_45)
          ArenaResult{v_55, +v_56} = check_constructors(v_49, v_10, canonical_key(v_16, v_5), v_6, v_8, v_16, v_40, v_50, v_19)
          {ArenaResult{v_55, v_56} : ArenaResult<ScopedState>}
        case _:
          v_50000282 = span_file(v_19)
          v_50000283 = Diagnostic{v_50000282, v_19, String.append("datatype signature is invalid: ", v_5), "a kinded family signature", "an invalid signature"}
          v_50000284 = ScopedStateFailure{v_50000283}
          {ArenaResult{v_30, v_50000284} : ArenaResult<ScopedState>}
    case InferenceFailure{+v_61}:
      v_63 = v_61
      {ArenaResult{v_1, ScopedStateFailure{v_63}} : ArenaResult<ScopedState>}

def check_import_foreign_head(v_1: ArenaStore, v_4: Maybe<&2, String>, v_6: U32, v_8: String, v_10: String, v_11: Scope.ArenaGlobalScope, v_12: Scope.ArenaGlobalScope, v_13: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_4:
    case Some{+v_18}:
      v_20 = v_18
      +v_24 = String.eq(Scope.canonical_name(v_20, v_12), Scope.canonical_name("IO", v_12))
      match v_24:
        case False{}:
          v_50000285 = span_file(v_13)
          v_50000286 = Diagnostic{v_50000285, v_13, "foreign definition must return base IO directly", "an IO result", "a non-IO result"}
          +v_27 = ScopedStateFailure{v_50000286}
          v_29 = v_1
          {ArenaResult{v_29, v_27} : ArenaResult<ScopedState>}
        case True{}:
          ArenaResult{v_34, +v_35} = canonicalize_term(v_1, v_6, v_12)
          v_50000287 = canonical_key(v_10, v_8)
          ArenaResult{v_40, +v_41} = arena_publish_global(v_34, Scope.ArenaGlobal{v_50000287, v_10, v_8, v_35, IR.NoTerm{}, Scope.GlobalDefinition{}})
          ArenaResult{v_45, +v_46} = global_scope_prepend(v_40, v_41, v_11)
          +v_48 = ScopedState{v_46}
          v_50 = v_45
          {ArenaResult{v_50, v_48} : ArenaResult<ScopedState>}
    case None{}:
      v_50000288 = span_file(v_13)
      v_50000289 = Diagnostic{v_50000288, v_13, "foreign definition must return base IO directly", "an IO result", "a non-IO result"}
      v_50000290 = ScopedStateFailure{v_50000289}
      {ArenaResult{v_1, v_50000290} : ArenaResult<ScopedState>}

def check_import_type_result(v_1: ArenaStore, v_3: Inference, v_5: String, v_7: U32, v_9: U32, v_11: String, v_12: Scope.ArenaGlobalScope, v_13: Scope.ArenaGlobalScope, v_14: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_3:
    case Inferred{+v_20, +v_21}:
      ArenaResult{v_25, +v_26} = arena_get_node(v_1, v_21)
      match v_26:
        case Arena.TermType{+v_29, +v_30}:
          ArenaResult{v_34, +v_35} = foreign_head(v_25, v_9)
          ArenaResult{v_39, +v_40} = check_import_foreign_head(v_34, v_35, v_7, v_5, v_11, v_12, v_13, v_14)
          {ArenaResult{v_39, v_40} : ArenaResult<ScopedState>}
        case _:
          v_50000291 = span_file(v_14)
          v_50000292 = Diagnostic{v_50000291, v_14, String.append("foreign signature is not a type: ", v_5), "a type", "a non-type"}
          v_50000293 = ScopedStateFailure{v_50000292}
          {ArenaResult{v_25, v_50000293} : ArenaResult<ScopedState>}
    case InferenceFailure{+v_45}:
      v_47 = v_45
      {ArenaResult{v_1, ScopedStateFailure{v_47}} : ArenaResult<ScopedState>}

def check_type_decl(v_1: ArenaStore, v_2: IR.TypeDecl, v_4: String, v_5: Scope.ArenaGlobalScope, v_6: Scope.ArenaGlobalScope) -> ArenaResult<ScopedState>:
  match v_2:
    case IR.TypeDecl{+v_15, +v_16, +v_17, +v_18, +v_19}:
      v_21 = v_15
      v_23 = v_16
      v_25 = v_17
      v_27 = v_18
      v_29 = v_19
      ArenaResult{v_33, +v_34} = binders_type(v_1, v_23, v_25)
      v_36 = v_34
      ArenaResult{v_40, +v_41} = binder_count(v_33, v_23)
      ArenaResult{v_45, +v_46} = parameter_vars(v_40, v_23, v_41, v_29)
      ArenaResult{v_51, +v_52} = arena_name(v_45, canonical_key(v_4, v_21))
      v_50000294 = arena_words_start(v_46)
      v_50000295 = arena_words_count(v_46)
      v_50000296 = arena_names_start(IR.Names{0, 0})
      v_50000297 = arena_names_count(IR.Names{0, 0})
      ArenaResult{v_60, +v_61} = arena_put_node(v_51, Arena.TermAdt{v_52, v_50000294, v_50000295, v_50000296, v_50000297, v_29})
      ArenaResult{v_65, +v_66} = binders_lambda(v_60, v_23, v_61)
      v_68 = v_66
      ArenaResult{v_72, +v_73} = canonicalize_term(v_65, v_36, v_6)
      ArenaResult{v_77, +v_78} = canonicalize_term(v_72, v_68, v_6)
      v_50000298 = canonical_key(v_4, v_21)
      ArenaResult{v_83, +v_84} = arena_publish_global(v_77, Scope.ArenaGlobal{v_50000298, v_4, v_21, v_73, IR.SomeTerm{v_78}, Scope.GlobalFamily{}})
      v_86 = v_84
      ArenaResult{v_90, +v_91} = arena_publish_global(v_83, Scope.ArenaGlobal{v_21, v_4, v_21, v_36, IR.SomeTerm{v_68}, Scope.GlobalFamily{}})
      v_93 = v_91
      ArenaResult{v_97, +v_98} = infer(v_90, v_36, [], v_6)
      ArenaResult{v_102, +v_103} = check_type_decl_result(v_97, v_98, v_21, v_23, v_25, v_27, v_86, v_93, v_36, v_4, v_5, v_6, v_29)
      {ArenaResult{v_102, v_103} : ArenaResult<ScopedState>}

def foreign_head(v_20039722: ArenaStore, v_0: U32) -> ArenaResult<Maybe<&2, String>>:
  ArenaResult{v_20039723, +v_20039724} = arena_get_node(v_20039722, v_0)
  match v_20039724:
    case Arena.TermRef{+v_20039727, +v_20039729}:
      ArenaResult{v_20039730, +v_20039731} = arena_name_text(v_20039723, v_20039727)
      +v_20039728 = v_20039731
      v_5 = v_20039728
      {ArenaResult{v_20039730, Some{v_5}} : ArenaResult<Maybe<&2, String>>}
    case Arena.TermApp{+v_20039735, +v_20039736, +v_20039737}:
      v_11 = v_20039735
      ArenaResult{v_20039738, +v_20039739} = foreign_head(v_20039723, v_11)
      {ArenaResult{v_20039738, v_20039739} : ArenaResult<Maybe<&2, String>>}
    case Arena.TermAnn{+v_20039743, +v_20039744, +v_20039745}:
      v_18 = v_20039743
      ArenaResult{v_20039746, +v_20039747} = foreign_head(v_20039723, v_18)
      {ArenaResult{v_20039746, v_20039747} : ArenaResult<Maybe<&2, String>>}
    case Arena.TermAll{+v_20039754, +v_20039755, +v_20039757, +v_20039758, +v_20039759, +v_20039760}:
      ArenaResult{v_20039761, +v_20039762} = arena_name_text(v_20039723, v_20039755)
      +v_20039756 = v_20039762
      v_29 = v_20039756
      v_30 = v_20039757
      v_32 = v_20039759
      v_33 = v_20039760
      ArenaResult{v_20039763, +v_20039764} = arena_name(v_20039761, v_29)
      ArenaResult{v_20039765, +v_20039766} = arena_put_node(v_20039763, Arena.TermVar{v_20039764, 0n, v_33})
      ArenaResult{v_20039767, +v_20039768} = core_subst(v_20039765, 0n, v_20039766, v_32)
      ArenaResult{v_20039769, +v_20039770} = foreign_head(v_20039767, v_20039768)
      {ArenaResult{v_20039769, v_20039770} : ArenaResult<Maybe<&2, String>>}
    case _:
      {ArenaResult{v_20039723, None{}} : ArenaResult<Maybe<&2, String>>}

def check_import_definition(v_1: ArenaStore, v_3: String, v_4: IR.Words, v_5: IR.OptionalTerm, v_6: IR.Names, v_8: String, v_9: Scope.ArenaGlobalScope, v_10: Scope.ArenaGlobalScope, v_11: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_5:
    case IR.SomeTerm{+v_16}:
      v_18 = v_16
      ArenaResult{v_22, +v_23} = binders_type(v_1, v_4, v_18)
      v_25 = v_23
      ArenaResult{v_29, +v_30} = infer(v_22, v_25, [], v_10)
      ArenaResult{v_34, +v_35} = check_import_type_result(v_29, v_30, v_3, v_25, v_18, v_8, v_9, v_10, v_11)
      {ArenaResult{v_34, v_35} : ArenaResult<ScopedState>}
    case IR.NoTerm{}:
      v_50000299 = span_file(v_11)
      v_50000300 = Diagnostic{v_50000299, v_11, String.append("foreign definition has no signature: ", v_3), "a declared result type", "no result type"}
      v_50000301 = ScopedStateFailure{v_50000300}
      {ArenaResult{v_1, v_50000301} : ArenaResult<ScopedState>}

def application_argument_bangs_valid_terms(v_20039780: ArenaStore, v_1: IR.Words) -> ArenaResult<Bool>:
  ArenaResult{v_20039781, +v_20039782} = arena_words_view(v_20039780, v_1)
  match v_20039782:
    case IR.WordNil{}:
      {ArenaResult{v_20039781, True{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20039783, +v_20039784}:
      +v_5 = v_20039783
      v_6 = v_20039784
      ArenaResult{v_20039785, +v_20039786} = application_argument_bangs_valid(v_20039781, v_5)
      ArenaResult{v_20039787, +v_20039788} = application_argument_bangs_valid_terms(v_20039785, v_6)
      {ArenaResult{v_20039787, Bool.and(v_20039786, v_20039788)} : ArenaResult<Bool>}

def application_argument_bangs_valid(v_20039789: ArenaStore, v_0: U32) -> ArenaResult<Bool>:
  ArenaResult{v_20039790, +v_20039791} = arena_get_node(v_20039789, v_0)
  match v_20039791:
    case Arena.TermBang{+v_20039794, +v_20039795}:
      {ArenaResult{v_20039790, False{}} : ArenaResult<Bool>}
    case Arena.TermSub{+v_20039800, +v_20039801, +v_20039802, +v_20039803}:
      v_10 = v_20039800
      v_11 = v_20039801
      v_12 = v_20039802
      ArenaResult{v_20039804, +v_20039805} = core_subst(v_20039790, v_10, v_11, v_12)
      ArenaResult{v_20039806, +v_20039807} = application_argument_bangs_valid(v_20039804, v_20039805)
      {ArenaResult{v_20039806, v_20039807} : ArenaResult<Bool>}
    case Arena.TermLet{+v_20039814, +v_20039815, +v_20039817, +v_20039818, +v_20039820, +v_20039821, +v_20039823, +v_20039824, +v_20039826, +v_20039827}:
      +v_20039825 = IR.Words{v_20039823, v_20039824}
      v_24 = v_20039825
      v_25 = v_20039826
      ArenaResult{v_20039828, +v_20039829} = application_argument_bangs_valid_terms(v_20039790, v_24)
      ArenaResult{v_20039830, +v_20039831} = application_argument_bangs_valid(v_20039828, v_25)
      {ArenaResult{v_20039830, Bool.and(v_20039829, v_20039831)} : ArenaResult<Bool>}
    case Arena.TermAnn{+v_20039835, +v_20039836, +v_20039837}:
      v_32 = v_20039835
      v_33 = v_20039836
      ArenaResult{v_20039838, +v_20039839} = application_argument_bangs_valid(v_20039790, v_32)
      ArenaResult{v_20039840, +v_20039841} = application_argument_bangs_valid(v_20039838, v_33)
      {ArenaResult{v_20039840, Bool.and(v_20039839, v_20039841)} : ArenaResult<Bool>}
    case Arena.TermTemplate{+v_20039844, +v_20039845}:
      v_39 = v_20039844
      ArenaResult{v_20039846, +v_20039847} = application_argument_bangs_valid(v_20039790, v_39)
      {ArenaResult{v_20039846, v_20039847} : ArenaResult<Bool>}
    case Arena.TermType{+v_20039850, +v_20039851}:
      v_44 = v_20039850
      ArenaResult{v_20039852, +v_20039853} = application_argument_bangs_valid(v_20039790, v_44)
      {ArenaResult{v_20039852, v_20039853} : ArenaResult<Bool>}
    case Arena.TermMin{+v_20039857, +v_20039858, +v_20039859}:
      v_50 = v_20039857
      v_51 = v_20039858
      ArenaResult{v_20039860, +v_20039861} = application_argument_bangs_valid(v_20039790, v_50)
      ArenaResult{v_20039862, +v_20039863} = application_argument_bangs_valid(v_20039860, v_51)
      {ArenaResult{v_20039862, Bool.and(v_20039861, v_20039863)} : ArenaResult<Bool>}
    case Arena.TermAll{+v_20039870, +v_20039871, +v_20039873, +v_20039874, +v_20039875, +v_20039876}:
      v_64 = v_20039874
      v_65 = v_20039875
      ArenaResult{v_20039877, +v_20039878} = application_argument_bangs_valid(v_20039790, v_64)
      ArenaResult{v_20039879, +v_20039880} = application_argument_bangs_valid(v_20039877, v_65)
      {ArenaResult{v_20039879, Bool.and(v_20039878, v_20039880)} : ArenaResult<Bool>}
    case Arena.TermLam{+v_20039886, +v_20039887, +v_20039889, +v_20039890, +v_20039891}:
      v_77 = v_20039890
      ArenaResult{v_20039892, +v_20039893} = application_argument_bangs_valid(v_20039790, v_77)
      {ArenaResult{v_20039892, v_20039893} : ArenaResult<Bool>}
    case Arena.TermApp{+v_20039897, +v_20039898, +v_20039899}:
      v_83 = v_20039897
      v_84 = v_20039898
      ArenaResult{v_20039900, +v_20039901} = application_bangs_valid(v_20039790, v_83)
      ArenaResult{v_20039902, +v_20039903} = application_argument_bangs_valid(v_20039900, v_84)
      {ArenaResult{v_20039902, Bool.and(v_20039901, v_20039903)} : ArenaResult<Bool>}
    case Arena.TermAdt{+v_20039908, +v_20039910, +v_20039911, +v_20039913, +v_20039914, +v_20039916}:
      +v_20039912 = IR.Words{v_20039910, v_20039911}
      v_93 = v_20039912
      ArenaResult{v_20039917, +v_20039918} = application_argument_bangs_valid_terms(v_20039790, v_93)
      {ArenaResult{v_20039917, v_20039918} : ArenaResult<Bool>}
    case Arena.TermFill{+v_20039922, +v_20039923, +v_20039924, +v_20039926}:
      +v_20039925 = IR.Words{v_20039923, v_20039924}
      v_100 = v_20039922
      v_101 = v_20039925
      ArenaResult{v_20039927, +v_20039928} = application_argument_bangs_valid(v_20039790, v_100)
      ArenaResult{v_20039929, +v_20039930} = application_argument_bangs_valid_terms(v_20039927, v_101)
      {ArenaResult{v_20039929, Bool.and(v_20039928, v_20039930)} : ArenaResult<Bool>}
    case Arena.TermPlus{+v_20039934, +v_20039935, +v_20039936, +v_20039938}:
      +v_20039937 = IR.Words{v_20039935, v_20039936}
      v_108 = v_20039934
      v_109 = v_20039937
      ArenaResult{v_20039939, +v_20039940} = application_argument_bangs_valid(v_20039790, v_108)
      ArenaResult{v_20039941, +v_20039942} = application_argument_bangs_valid_terms(v_20039939, v_109)
      {ArenaResult{v_20039941, Bool.and(v_20039940, v_20039942)} : ArenaResult<Bool>}
    case Arena.TermString{_, _, _}:
      {ArenaResult{v_20039790, True{}} : ArenaResult<Bool>}
    case Arena.TermCtr{+v_20039946, +v_20039948, +v_20039949, +v_20039951}:
      +v_20039950 = IR.Words{v_20039948, v_20039949}
      v_117 = v_20039950
      ArenaResult{v_20039952, +v_20039953} = application_argument_bangs_valid_terms(v_20039790, v_117)
      {ArenaResult{v_20039952, v_20039953} : ArenaResult<Bool>}
    case Arena.TermMat{+v_20039958, +v_20039960, +v_20039961, +v_20039962}:
      v_125 = v_20039960
      v_126 = v_20039961
      ArenaResult{v_20039963, +v_20039964} = application_argument_bangs_valid(v_20039790, v_125)
      ArenaResult{v_20039965, +v_20039966} = application_argument_bangs_valid(v_20039963, v_126)
      {ArenaResult{v_20039965, Bool.and(v_20039964, v_20039966)} : ArenaResult<Bool>}
    case Arena.TermEqual{+v_20039971, +v_20039972, +v_20039973, +v_20039974}:
      v_134 = v_20039971
      v_135 = v_20039972
      v_136 = v_20039973
      ArenaResult{v_20039975, +v_20039976} = application_argument_bangs_valid(v_20039790, v_134)
      ArenaResult{v_20039977, +v_20039978} = application_argument_bangs_valid(v_20039975, v_135)
      ArenaResult{v_20039979, +v_20039980} = application_argument_bangs_valid(v_20039977, v_136)
      {ArenaResult{v_20039979, Bool.and(Bool.and(v_20039976, v_20039978), v_20039980)} : ArenaResult<Bool>}
    case Arena.TermRewrite{+v_20039985, +v_20039986, +v_20039987, +v_20039988}:
      v_145 = v_20039985
      v_146 = v_20039986
      v_147 = v_20039987
      ArenaResult{v_20039989, +v_20039990} = application_argument_bangs_valid(v_20039790, v_145)
      ArenaResult{v_20039991, +v_20039992} = application_argument_bangs_valid(v_20039989, v_146)
      ArenaResult{v_20039993, +v_20039994} = application_argument_bangs_valid(v_20039991, v_147)
      {ArenaResult{v_20039993, Bool.and(Bool.and(v_20039990, v_20039992), v_20039994)} : ArenaResult<Bool>}
    case Arena.BodyMatch{+v_20039998, +v_20039999, +v_20040001, +v_20040002, +v_20040004}:
      +v_20040000 = IR.Words{v_20039998, v_20039999}
      +v_20040003 = IR.Words{v_20040001, v_20040002}
      v_155 = v_20040000
      v_156 = v_20040003
      ArenaResult{v_20040005, +v_20040006} = application_argument_bangs_valid_terms(v_20039790, v_155)
      ArenaResult{v_20040007, +v_20040008} = application_argument_bangs_valid_terms(v_20040005, v_156)
      {ArenaResult{v_20040007, Bool.and(v_20040006, v_20040008)} : ArenaResult<Bool>}
    case Arena.BodyCase{+v_20040012, +v_20040013, +v_20040015, +v_20040016}:
      v_164 = v_20040015
      ArenaResult{v_20040017, +v_20040018} = application_argument_bangs_valid(v_20039790, v_164)
      {ArenaResult{v_20040017, v_20040018} : ArenaResult<Bool>}
    case Arena.BodyLocal{+v_20040024, +v_20040025, +v_20040027, +v_20040028, +v_20040029, +v_20040031, +v_20040032}:
      +v_20040030 = IR.Words{v_20040028, v_20040029}
      v_174 = v_20040030
      v_175 = v_20040031
      ArenaResult{v_20040033, +v_20040034} = application_argument_bangs_valid_terms(v_20039790, v_174)
      ArenaResult{v_20040035, +v_20040036} = application_argument_bangs_valid(v_20040033, v_175)
      {ArenaResult{v_20040035, Bool.and(v_20040034, v_20040036)} : ArenaResult<Bool>}
    case Arena.BodyReply{+v_20040039, +v_20040040}:
      v_181 = v_20040039
      ArenaResult{v_20040041, +v_20040042} = application_argument_bangs_valid(v_20039790, v_181)
      {ArenaResult{v_20040041, v_20040042} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20039790, True{}} : ArenaResult<Bool>}

def application_has_bang(v_20040044: ArenaStore, v_0: U32) -> ArenaResult<Bool>:
  ArenaResult{v_20040045, +v_20040046} = arena_get_node(v_20040044, v_0)
  match v_20040046:
    case Arena.TermBang{+v_20040049, +v_20040050}:
      ArenaResult{v_20040051, +v_20040052} = arena_get_node(v_20040045, v_20040049)
      match v_20040052:
        case Arena.TermRef{+v_20040055, +v_20040057}:
          {ArenaResult{v_20040051, True{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20040051, False{}} : ArenaResult<Bool>}
    case Arena.TermApp{+v_20040062, +v_20040063, +v_20040064}:
      v_11 = v_20040062
      ArenaResult{v_20040065, +v_20040066} = application_has_bang(v_20040045, v_11)
      {ArenaResult{v_20040065, v_20040066} : ArenaResult<Bool>}
    case Arena.TermAnn{+v_20040070, +v_20040071, +v_20040072}:
      v_18 = v_20040070
      ArenaResult{v_20040073, +v_20040074} = application_has_bang(v_20040045, v_18)
      {ArenaResult{v_20040073, v_20040074} : ArenaResult<Bool>}
    case Arena.TermSub{+v_20040079, +v_20040080, +v_20040081, +v_20040082}:
      v_26 = v_20040079
      v_27 = v_20040080
      v_28 = v_20040081
      ArenaResult{v_20040083, +v_20040084} = core_subst(v_20040045, v_26, v_27, v_28)
      ArenaResult{v_20040085, +v_20040086} = application_has_bang(v_20040083, v_20040084)
      {ArenaResult{v_20040085, v_20040086} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20040045, False{}} : ArenaResult<Bool>}

def application_bangs_valid(v_20040088: ArenaStore, v_0: U32) -> ArenaResult<Bool>:
  ArenaResult{v_20040089, +v_20040090} = arena_get_node(v_20040088, v_0)
  match v_20040090:
    case Arena.TermBang{+v_20040093, +v_20040094}:
      ArenaResult{v_20040095, +v_20040096} = arena_get_node(v_20040089, v_20040093)
      match v_20040096:
        case Arena.TermRef{+v_20040101, +v_20040103}:
          {ArenaResult{v_20040095, True{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20040095, False{}} : ArenaResult<Bool>}
    case Arena.TermApp{+v_20040108, +v_20040109, +v_20040110}:
      v_15 = v_20040108
      v_16 = v_20040109
      ArenaResult{v_20040111, +v_20040112} = application_bangs_valid(v_20040089, v_15)
      ArenaResult{v_20040113, +v_20040114} = application_argument_bangs_valid(v_20040111, v_16)
      {ArenaResult{v_20040113, Bool.and(v_20040112, v_20040114)} : ArenaResult<Bool>}
    case Arena.TermAnn{+v_20040118, +v_20040119, +v_20040120}:
      v_23 = v_20040118
      v_24 = v_20040119
      ArenaResult{v_20040121, +v_20040122} = application_bangs_valid(v_20040089, v_23)
      ArenaResult{v_20040123, +v_20040124} = application_argument_bangs_valid(v_20040121, v_24)
      {ArenaResult{v_20040123, Bool.and(v_20040122, v_20040124)} : ArenaResult<Bool>}
    case Arena.TermSub{+v_20040129, +v_20040130, +v_20040131, +v_20040132}:
      v_32 = v_20040129
      v_33 = v_20040130
      v_34 = v_20040131
      ArenaResult{v_20040133, +v_20040134} = core_subst(v_20040089, v_32, v_33, v_34)
      ArenaResult{v_20040135, +v_20040136} = application_bangs_valid(v_20040133, v_20040134)
      {ArenaResult{v_20040135, v_20040136} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20040089, True{}} : ArenaResult<Bool>}

def application_type_view(v_20040138: ArenaStore, v_0: U32) -> ArenaResult<U32>:
  ArenaResult{v_20040139, +v_20040140} = arena_get_node(v_20040138, v_0)
  match v_20040140:
    case Arena.TermBang{+v_20040143, +v_20040144}:
      ArenaResult{v_20040145, +v_20040146} = arena_get_node(v_20040139, v_20040143)
      match v_20040146:
        case Arena.TermRef{_, _}:
          {ArenaResult{v_20040145, v_20040143} : ArenaResult<U32>}
        case _:
          {ArenaResult{v_20040145, v_0} : ArenaResult<U32>}
    case Arena.TermApp{+v_20040162, +v_20040163, +v_20040164}:
      v_10 = v_20040162
      v_11 = v_20040163
      v_12 = v_20040164
      ArenaResult{v_20040165, +v_20040166} = application_type_view(v_20040139, v_10)
      unchanged = U32.is_eq(v_20040166, v_10)
      match unchanged:
        case True{}:
          {ArenaResult{v_20040165, v_0} : ArenaResult<U32>}
        case False{}:
          ArenaResult{v_20040167, +v_20040168} = arena_put_node(v_20040165, Arena.TermApp{v_20040166, v_11, v_12})
          {ArenaResult{v_20040167, v_20040168} : ArenaResult<U32>}
    case Arena.TermAnn{+v_20040172, +v_20040173, +v_20040174}:
      v_17 = v_20040172
      v_18 = v_20040173
      v_19 = v_20040174
      ArenaResult{v_20040175, +v_20040176} = application_type_view(v_20040139, v_17)
      unchanged = U32.is_eq(v_20040176, v_17)
      match unchanged:
        case True{}:
          {ArenaResult{v_20040175, v_0} : ArenaResult<U32>}
        case False{}:
          ArenaResult{v_20040177, +v_20040178} = arena_put_node(v_20040175, Arena.TermAnn{v_20040176, v_18, v_19})
          {ArenaResult{v_20040177, v_20040178} : ArenaResult<U32>}
    case Arena.TermSub{+v_20040183, +v_20040184, +v_20040185, +v_20040186}:
      v_25 = v_20040183
      v_26 = v_20040184
      v_27 = v_20040185
      ArenaResult{v_20040187, +v_20040188} = core_subst(v_20040139, v_25, v_26, v_27)
      ArenaResult{v_20040189, +v_20040190} = application_type_view(v_20040187, v_20040188)
      {ArenaResult{v_20040189, v_20040190} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_20040139, v_0} : ArenaResult<U32>}

def application_head(v_20040192: ArenaStore, v_0: U32) -> ArenaResult<U32>:
  ArenaResult{v_20040193, +v_20040194} = arena_get_node(v_20040192, v_0)
  match v_20040194:
    case Arena.TermBang{+v_20040197, +v_20040198}:
      v_3 = v_20040197
      ArenaResult{v_20040199, +v_20040200} = application_head(v_20040193, v_3)
      {ArenaResult{v_20040199, v_20040200} : ArenaResult<U32>}
    case Arena.TermApp{+v_20040204, +v_20040205, +v_20040206}:
      v_9 = v_20040204
      ArenaResult{v_20040207, +v_20040208} = application_head(v_20040193, v_9)
      {ArenaResult{v_20040207, v_20040208} : ArenaResult<U32>}
    case Arena.TermAnn{+v_20040212, +v_20040213, +v_20040214}:
      v_16 = v_20040212
      ArenaResult{v_20040215, +v_20040216} = application_head(v_20040193, v_16)
      {ArenaResult{v_20040215, v_20040216} : ArenaResult<U32>}
    case Arena.TermSub{+v_20040221, +v_20040222, +v_20040223, +v_20040224}:
      v_24 = v_20040221
      v_25 = v_20040222
      v_26 = v_20040223
      ArenaResult{v_20040225, +v_20040226} = core_subst(v_20040193, v_24, v_25, v_26)
      ArenaResult{v_20040227, +v_20040228} = application_head(v_20040225, v_20040226)
      {ArenaResult{v_20040227, v_20040228} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_20040193, v_0} : ArenaResult<U32>}

def application_args(v_20040230: ArenaStore, v_0: U32) -> ArenaResult<IR.Words>:
  ArenaResult{v_20040231, +v_20040232} = arena_get_node(v_20040230, v_0)
  match v_20040232:
    case Arena.TermApp{+v_20040236, +v_20040237, +v_20040238}:
      v_5 = v_20040236
      v_6 = v_20040237
      ArenaResult{v_20040239, +v_20040240} = application_args(v_20040231, v_5)
      ArenaResult{v_20040241, +v_20040242} = arena_words_cons(v_20040239, v_6, IR.Words{0, 0})
      ArenaResult{v_20040243, +v_20040244} = arena_words_append(v_20040241, v_20040240, v_20040242)
      {ArenaResult{v_20040243, v_20040244} : ArenaResult<IR.Words>}
    case Arena.TermAnn{+v_20040248, +v_20040249, +v_20040250}:
      v_12 = v_20040248
      ArenaResult{v_20040251, +v_20040252} = application_args(v_20040231, v_12)
      {ArenaResult{v_20040251, v_20040252} : ArenaResult<IR.Words>}
    case Arena.TermSub{+v_20040257, +v_20040258, +v_20040259, +v_20040260}:
      v_20 = v_20040257
      v_21 = v_20040258
      v_22 = v_20040259
      ArenaResult{v_20040261, +v_20040262} = core_subst(v_20040231, v_20, v_21, v_22)
      ArenaResult{v_20040263, +v_20040264} = application_args(v_20040261, v_20040262)
      {ArenaResult{v_20040263, v_20040264} : ArenaResult<IR.Words>}
    case _:
      {ArenaResult{v_20040231, IR.Words{0, 0}} : ArenaResult<IR.Words>}

def strip_order_annotation(v_20040266: ArenaStore, v_0: U32) -> ArenaResult<U32>:
  ArenaResult{v_20040267, +v_20040268} = arena_get_node(v_20040266, v_0)
  match v_20040268:
    case Arena.TermAnn{+v_20040272, +v_20040273, +v_20040274}:
      v_4 = v_20040272
      ArenaResult{v_20040275, +v_20040276} = strip_order_annotation(v_20040267, v_4)
      {ArenaResult{v_20040275, v_20040276} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_20040267, v_0} : ArenaResult<U32>}

def term_descend(v_20040278: ArenaStore, v_0: Ast.Quantity, v_1: U32, v_2: U32) -> ArenaResult<TermOrder>:
  ArenaResult{v_20040279, +v_20040280} = strip_order_annotation(v_20040278, v_1)
  ArenaResult{v_20040281, +v_20040282} = strip_order_annotation(v_20040279, v_2)
  ArenaResult{v_20040283, +v_20040284} = term_descend_raw(v_20040281, v_0, v_20040280, v_20040282)
  {ArenaResult{v_20040283, v_20040284} : ArenaResult<TermOrder>}

def term_descend_raw(v_20040285: ArenaStore, v_0: Ast.Quantity, v_1: U32, v_2: U32) -> ArenaResult<TermOrder>:
  match v_0:
    case Ast.QZero{}:
      {ArenaResult{v_20040285, OrderEqual{}} : ArenaResult<TermOrder>}
    case _:
      ArenaResult{v_20040287, +v_20040288} = term_descend_live(v_20040285, v_1, v_2)
      {ArenaResult{v_20040287, v_20040288} : ArenaResult<TermOrder>}

def term_descend_ordinary(v_20040289: ArenaStore, v_0: U32, v_1: U32) -> ArenaResult<TermOrder>:
  ArenaResult{v_20040290, +v_20040291} = arena_get_node(v_20040289, v_0)
  match v_20040291:
    case Arena.TermVar{+v_20040298, +v_20040300, +v_20040301}:
      ArenaResult{v_20040302, +v_20040303} = arena_get_node(v_20040290, v_1)
      match v_20040303:
        case Arena.TermVar{+v_20040307, +v_20040309, +v_20040310}:
          v_13 = v_20040309
          v_10 = v_20040300
          +v_20040313 = Nat.is_eq(v_10, v_13)
          match v_20040313:
            case False{}:
              +v_20040311 = OrderGreater{}
              v_20040312 = v_20040302
              {ArenaResult{v_20040312, v_20040311} : ArenaResult<TermOrder>}
            case True{}:
              +v_20040311 = OrderEqual{}
              v_20040312 = v_20040302
              {ArenaResult{v_20040312, v_20040311} : ArenaResult<TermOrder>}
        case Arena.TermCtr{+v_20040317, +v_20040319, +v_20040320, +v_20040322}:
          +v_20040321 = IR.Words{v_20040319, v_20040320}
          v_38 = v_20040321
          ArenaResult{v_20040323, +v_20040324} = term_is_subterm(v_20040302, v_0, v_38)
          {ArenaResult{v_20040323, v_20040324} : ArenaResult<TermOrder>}
        case _:
          {ArenaResult{v_20040302, OrderGreater{}} : ArenaResult<TermOrder>}
    case Arena.TermCtr{+v_20040332, +v_20040334, +v_20040335, +v_20040337}:
      ArenaResult{v_20040338, +v_20040339} = arena_name_text(v_20040290, v_20040332)
      +v_20040333 = v_20040339
      +v_20040336 = IR.Words{v_20040334, v_20040335}
      ArenaResult{v_20040340, +v_20040341} = arena_get_node(v_20040338, v_1)
      match v_20040341:
        case Arena.TermCtr{+v_20040345, +v_20040347, +v_20040348, +v_20040350}:
          ArenaResult{v_20040351, +v_20040352} = arena_name_text(v_20040340, v_20040345)
          +v_20040346 = v_20040352
          +v_20040349 = IR.Words{v_20040347, v_20040348}
          v_25 = v_20040346
          v_26 = v_20040349
          v_22 = v_20040333
          v_23 = v_20040336
          +v_20040355 = String.eq(v_22, v_25)
          match v_20040355:
            case False{}:
              ArenaResult{v_20040356, +v_20040357} = term_is_subterm(v_20040351, v_0, v_26)
              +v_20040353 = v_20040357
              v_20040354 = v_20040356
              {ArenaResult{v_20040354, v_20040353} : ArenaResult<TermOrder>}
            case True{}:
              ArenaResult{v_20040358, +v_20040359} = term_descend_list(v_20040351, v_23, v_26)
              ArenaResult{v_20040360, +v_20040361} = term_descend_constructor_result(v_20040358, v_20040359, v_0, v_26)
              +v_20040353 = v_20040361
              v_20040354 = v_20040360
              {ArenaResult{v_20040354, v_20040353} : ArenaResult<TermOrder>}
        case _:
          {ArenaResult{v_20040340, OrderGreater{}} : ArenaResult<TermOrder>}
    case _:
      ArenaResult{v_20040364, +v_20040365} = arena_get_node(v_20040290, v_1)
      match v_20040365:
        case Arena.TermCtr{+v_20040369, +v_20040371, +v_20040372, +v_20040374}:
          +v_20040373 = IR.Words{v_20040371, v_20040372}
          v_38 = v_20040373
          ArenaResult{v_20040375, +v_20040376} = term_is_subterm(v_20040364, v_0, v_38)
          {ArenaResult{v_20040375, v_20040376} : ArenaResult<TermOrder>}
        case _:
          {ArenaResult{v_20040364, OrderGreater{}} : ArenaResult<TermOrder>}

def term_descend_constructor_result(v_20040378: ArenaStore, v_1: TermOrder, v_2: U32, v_4: IR.Words) -> ArenaResult<TermOrder>:
  match v_1:
    case OrderEqual{}:
      {ArenaResult{v_20040378, OrderEqual{}} : ArenaResult<TermOrder>}
    case OrderLess{}:
      {ArenaResult{v_20040378, OrderLess{}} : ArenaResult<TermOrder>}
    case OrderGreater{}:
      ArenaResult{v_20040379, +v_20040380} = term_is_subterm(v_20040378, v_2, v_4)
      {ArenaResult{v_20040379, v_20040380} : ArenaResult<TermOrder>}

def term_descend_list_result(v_20040381: ArenaStore, v_1: TermOrder, v_3: IR.Words, v_5: IR.Words) -> ArenaResult<TermOrder>:
  match v_1:
    case OrderEqual{}:
      ArenaResult{v_20040382, +v_20040383} = term_descend_list(v_20040381, v_3, v_5)
      {ArenaResult{v_20040382, v_20040383} : ArenaResult<TermOrder>}
    case OrderLess{}:
      {ArenaResult{v_20040381, OrderLess{}} : ArenaResult<TermOrder>}
    case OrderGreater{}:
      {ArenaResult{v_20040381, OrderGreater{}} : ArenaResult<TermOrder>}

def term_descend_list(v_20040384: ArenaStore, v_1: IR.Words, v_3: IR.Words) -> ArenaResult<TermOrder>:
  ArenaResult{v_20040385, +v_20040386} = arena_words_view(v_20040384, v_1)
  match v_20040386:
    case IR.WordNil{}:
      ArenaResult{v_20040387, +v_20040388} = arena_words_view(v_20040385, v_3)
      match v_20040388:
        case IR.WordNil{}:
          {ArenaResult{v_20040387, OrderEqual{}} : ArenaResult<TermOrder>}
        case _:
          {ArenaResult{v_20040387, OrderGreater{}} : ArenaResult<TermOrder>}
    case IR.WordCons{+v_20040392, +v_20040393}:
      ArenaResult{v_20040394, +v_20040395} = arena_words_view(v_20040385, v_3)
      match v_20040395:
        case IR.WordCons{+v_20040398, +v_20040399}:
          +v_11 = v_20040398
          v_12 = v_20040399
          +v_9 = v_20040392
          v_10 = v_20040393
          ArenaResult{v_20040400, +v_20040401} = term_descend(v_20040394, Ast.QOne{}, v_9, v_11)
          ArenaResult{v_20040402, +v_20040403} = term_descend_list_result(v_20040400, v_20040401, v_10, v_12)
          {ArenaResult{v_20040402, v_20040403} : ArenaResult<TermOrder>}
        case _:
          {ArenaResult{v_20040394, OrderGreater{}} : ArenaResult<TermOrder>}
    case _:
      {ArenaResult{v_20040385, OrderGreater{}} : ArenaResult<TermOrder>}

def term_is_subterm_result(v_20040406: ArenaStore, v_1: TermOrder, v_2: U32, v_4: IR.Words) -> ArenaResult<TermOrder>:
  match v_1:
    case OrderGreater{}:
      ArenaResult{v_20040407, +v_20040408} = term_is_subterm(v_20040406, v_2, v_4)
      {ArenaResult{v_20040407, v_20040408} : ArenaResult<TermOrder>}
    case _:
      {ArenaResult{v_20040406, OrderLess{}} : ArenaResult<TermOrder>}

def term_is_subterm(v_20040410: ArenaStore, v_0: U32, v_2: IR.Words) -> ArenaResult<TermOrder>:
  ArenaResult{v_20040411, +v_20040412} = arena_words_view(v_20040410, v_2)
  match v_20040412:
    case IR.WordNil{}:
      {ArenaResult{v_20040411, OrderGreater{}} : ArenaResult<TermOrder>}
    case IR.WordCons{+v_20040413, +v_20040414}:
      +v_6 = v_20040413
      v_7 = v_20040414
      ArenaResult{v_20040415, +v_20040416} = term_descend(v_20040411, Ast.QOne{}, v_0, v_6)
      ArenaResult{v_20040417, +v_20040418} = term_is_subterm_result(v_20040415, v_20040416, v_0, v_7)
      {ArenaResult{v_20040417, v_20040418} : ArenaResult<TermOrder>}

def recursive_call_decrease_result(v_20040419: ArenaStore, v_1: TermOrder, v_3: IR.Words, v_5: IR.Words, v_7: IR.Quantities) -> ArenaResult<Bool>:
  match v_1:
    case OrderLess{}:
      {ArenaResult{v_20040419, True{}} : ArenaResult<Bool>}
    case OrderEqual{}:
      ArenaResult{v_20040420, +v_20040421} = recursive_call_decreases(v_20040419, v_3, v_5, v_7)
      {ArenaResult{v_20040420, v_20040421} : ArenaResult<Bool>}
    case OrderGreater{}:
      {ArenaResult{v_20040419, False{}} : ArenaResult<Bool>}

def recursive_call_decreases(v_20040422: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_5: IR.Quantities) -> ArenaResult<Bool>:
  ArenaResult{v_20040423, +v_20040424} = arena_words_view(v_20040422, v_1)
  match v_20040424:
    case IR.WordNil{}:
      {ArenaResult{v_20040423, False{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20040429, +v_20040430}:
      ArenaResult{v_20040431, +v_20040432} = arena_words_view(v_20040423, v_3)
      match v_20040432:
        case IR.WordNil{}:
          {ArenaResult{v_20040431, False{}} : ArenaResult<Bool>}
        case IR.WordCons{+v_20040435, +v_20040436}:
          ArenaResult{v_20040437, +v_20040438} = arena_quantities_view(v_20040431, v_5)
          match v_20040438:
            case IR.QuantityNil{}:
              {ArenaResult{v_20040437, False{}} : ArenaResult<Bool>}
            case IR.QuantityCons{+v_20040439, +v_20040440}:
              +v_29 = v_20040439
              v_30 = v_20040440
              +v_27 = v_20040435
              v_28 = v_20040436
              +v_25 = v_20040429
              v_26 = v_20040430
              ArenaResult{v_20040441, +v_20040442} = term_descend(v_20040437, v_29, v_25, v_27)
              ArenaResult{v_20040443, +v_20040444} = recursive_call_decrease_result(v_20040441, v_20040442, v_26, v_28, v_30)
              {ArenaResult{v_20040443, v_20040444} : ArenaResult<Bool>}

def binders_quantities(v_20040454: ArenaStore, v_1: IR.Words) -> ArenaResult<IR.Quantities>:
  ArenaResult{v_20040455, +v_20040456} = arena_words_view(v_20040454, v_1)
  match v_20040456:
    case IR.WordNil{}:
      {ArenaResult{v_20040455, IR.Quantities{0, 0}} : ArenaResult<IR.Quantities>}
    case IR.WordCons{+v_20040457, +v_20040458}:
      +v_5 = v_20040457
      v_6 = v_20040458
      ArenaResult{v_20040459, +v_20040460} = arena_get_binder(v_20040455, v_5)
      match v_20040460:
        case Arena.Binder{+v_20040461, +v_20040462, +v_20040464, +v_20040465, +v_20040466}:
          v_12 = v_20040461
          ArenaResult{v_20040467, +v_20040468} = binders_quantities(v_20040459, v_6)
          ArenaResult{v_20040469, +v_20040470} = arena_quantities_cons(v_20040467, v_12, v_20040468)
          {ArenaResult{v_20040469, v_20040470} : ArenaResult<IR.Quantities>}
        case Arena.TemplateBinder{+v_20040471, +v_20040473, +v_20040474, +v_20040475}:
          ArenaResult{v_20040476, +v_20040477} = binders_quantities(v_20040459, v_6)
          ArenaResult{v_20040478, +v_20040479} = arena_quantities_cons(v_20040476, Ast.QZero{}, v_20040477)
          {ArenaResult{v_20040478, v_20040479} : ArenaResult<IR.Quantities>}

def pattern_value(v_1: ArenaStore, v_3: U32, v_5: Nat) -> ArenaResult<U32>:
  ArenaResult{v_12, +v_13} = arena_get_pattern(v_1, v_3)
  match v_13:
    case Arena.PatternVar{+v_18, +v_19, +v_20, +v_21}:
      ArenaResult{v_25, +v_26} = arena_name_text(v_12, v_18)
      +v_28 = v_26
      v_30 = v_28
      v_32 = v_19
      v_34 = v_21
      ArenaResult{v_38, +v_39} = arena_name(v_25, v_30)
      ArenaResult{v_43, +v_44} = arena_put_node(v_38, Arena.TermVar{v_39, Nat.sub(Nat.sub(v_5, v_32), 1n), v_34})
      {ArenaResult{v_43, v_44} : ArenaResult<U32>}
    case Arena.PatternCtr{+v_49, +v_50, +v_51, +v_52}:
      ArenaResult{v_56, +v_57} = arena_name_text(v_12, v_49)
      +v_59 = v_57
      +v_61 = IR.Words{v_50, v_51}
      v_63 = v_59
      v_65 = v_61
      v_67 = v_52
      ArenaResult{v_71, +v_72} = pattern_values(v_56, v_65, v_5)
      ArenaResult{v_76, +v_77} = arena_name(v_71, v_63)
      v_50000302 = arena_words_start(v_72)
      v_50000303 = arena_words_count(v_72)
      ArenaResult{v_83, +v_84} = arena_put_node(v_76, Arena.TermCtr{v_77, v_50000302, v_50000303, v_67})
      {ArenaResult{v_83, v_84} : ArenaResult<U32>}

def pattern_values(v_20040508: ArenaStore, v_1: IR.Words, v_3: Nat) -> ArenaResult<IR.Words>:
  ArenaResult{v_20040509, +v_20040510} = arena_words_view(v_20040508, v_1)
  match v_20040510:
    case IR.WordNil{}:
      {ArenaResult{v_20040509, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20040511, +v_20040512}:
      +v_7 = v_20040511
      v_8 = v_20040512
      ArenaResult{v_20040513, +v_20040514} = pattern_value(v_20040509, v_7, v_3)
      ArenaResult{v_20040515, +v_20040516} = pattern_values(v_20040513, v_8, v_3)
      ArenaResult{v_20040517, +v_20040518} = arena_words_cons(v_20040515, v_20040514, v_20040516)
      {ArenaResult{v_20040517, v_20040518} : ArenaResult<IR.Words>}

def replace_order_var(v_1: ArenaStore, v_3: U32, v_5: Nat, v_7: U32) -> ArenaResult<U32>:
  ArenaResult{v_14, +v_15} = arena_get_node(v_1, v_3)
  match v_15:
    case Arena.TermVar{+v_19, +v_20, +v_21}:
      ArenaResult{v_25, +v_26} = arena_name_text(v_14, v_19)
      +v_28 = v_26
      v_30 = v_28
      v_32 = v_20
      v_34 = v_21
      +v_36 = Nat.is_eq(v_32, v_5)
      match v_36:
        case False{}:
          ArenaResult{v_40, +v_41} = arena_name(v_25, v_30)
          ArenaResult{v_45, +v_46} = arena_put_node(v_40, Arena.TermVar{v_41, v_32, v_34})
          +v_48 = v_46
          v_50 = v_45
          {ArenaResult{v_50, v_48} : ArenaResult<U32>}
        case True{}:
          +v_53 = v_7
          v_55 = v_25
          {ArenaResult{v_55, v_53} : ArenaResult<U32>}
    case Arena.TermCtr{+v_61, +v_62, +v_63, +v_64}:
      ArenaResult{v_68, +v_69} = arena_name_text(v_14, v_61)
      +v_71 = v_69
      +v_73 = IR.Words{v_62, v_63}
      v_75 = v_71
      v_77 = v_73
      v_79 = v_64
      ArenaResult{v_83, +v_84} = replace_order_vars(v_68, v_77, v_5, v_7)
      ArenaResult{v_88, +v_89} = arena_name(v_83, v_75)
      v_50000304 = arena_words_start(v_84)
      v_50000305 = arena_words_count(v_84)
      ArenaResult{v_95, +v_96} = arena_put_node(v_88, Arena.TermCtr{v_89, v_50000304, v_50000305, v_79})
      {ArenaResult{v_95, v_96} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_14, v_3} : ArenaResult<U32>}

def replace_order_vars(v_20040556: ArenaStore, v_1: IR.Words, v_3: Nat, v_4: U32) -> ArenaResult<IR.Words>:
  ArenaResult{v_20040557, +v_20040558} = arena_words_view(v_20040556, v_1)
  match v_20040558:
    case IR.WordNil{}:
      {ArenaResult{v_20040557, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20040559, +v_20040560}:
      +v_8 = v_20040559
      v_9 = v_20040560
      ArenaResult{v_20040561, +v_20040562} = replace_order_var(v_20040557, v_8, v_3, v_4)
      ArenaResult{v_20040563, +v_20040564} = replace_order_vars(v_20040561, v_9, v_3, v_4)
      ArenaResult{v_20040565, +v_20040566} = arena_words_cons(v_20040563, v_20040562, v_20040564)
      {ArenaResult{v_20040565, v_20040566} : ArenaResult<IR.Words>}

def branch_order_column(v_20040567: ArenaStore, v_0: U32, v_2: IR.Words, v_4: IR.Words, v_6: Nat, v_8: Nat) -> ArenaResult<U32>:
  ArenaResult{v_20040568, +v_20040569} = arena_words_view(v_20040567, v_2)
  match v_20040569:
    case IR.WordNil{}:
      {ArenaResult{v_20040568, v_0} : ArenaResult<U32>}
    case IR.WordCons{+v_20040572, +v_20040573}:
      ArenaResult{v_20040574, +v_20040575} = arena_words_view(v_20040568, v_4)
      match v_20040575:
        case IR.WordNil{}:
          {ArenaResult{v_20040574, v_0} : ArenaResult<U32>}
        case IR.WordCons{+v_20040576, +v_20040577}:
          ArenaResult{v_20040578, +v_20040579} = arena_get_node(v_20040574, v_20040572)
          match v_20040579:
            case Arena.TermVar{+v_20040583, +v_20040585, +v_20040586}:
              v_20 = v_20040585
              +v_23 = v_20040576
              v_24 = v_20040577
              v_22 = v_20040573
              ArenaResult{v_20040587, +v_20040588} = pattern_value(v_20040578, v_23, v_6)
              v_27 = v_20040588
              ArenaResult{v_20040589, +v_20040590} = replace_order_var(v_20040587, v_0, Nat.add(v_20, v_8), v_27)
              ArenaResult{v_20040591, +v_20040592} = branch_order_column(v_20040589, v_20040590, v_22, v_24, v_6, v_8)
              {ArenaResult{v_20040591, v_20040592} : ArenaResult<U32>}
            case _:
              v_37 = v_20040577
              v_35 = v_20040573
              ArenaResult{v_20040594, +v_20040595} = branch_order_column(v_20040578, v_0, v_35, v_37, v_6, v_8)
              {ArenaResult{v_20040594, v_20040595} : ArenaResult<U32>}

def branch_order_columns(v_20040599: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_5: IR.Words, v_7: Nat, v_9: Nat) -> ArenaResult<IR.Words>:
  ArenaResult{v_20040600, +v_20040601} = arena_words_view(v_20040599, v_1)
  match v_20040601:
    case IR.WordNil{}:
      {ArenaResult{v_20040600, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20040602, +v_20040603}:
      +v_13 = v_20040602
      v_14 = v_20040603
      ArenaResult{v_20040604, +v_20040605} = core_shift(v_20040600, 0n, v_9, v_13)
      ArenaResult{v_20040606, +v_20040607} = branch_order_column(v_20040604, v_20040605, v_3, v_5, v_7, v_9)
      ArenaResult{v_20040608, +v_20040609} = branch_order_columns(v_20040606, v_14, v_3, v_5, v_7, v_9)
      ArenaResult{v_20040610, +v_20040611} = arena_words_cons(v_20040608, v_20040607, v_20040609)
      {ArenaResult{v_20040610, v_20040611} : ArenaResult<IR.Words>}

def initial_telescope_count_view(v_20040612: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Nat>:
  ArenaResult{v_20040613, +v_20040614} = arena_get_node(v_20040612, v_0)
  match v_20040614:
    case Arena.TermAll{+v_20040621, +v_20040622, +v_20040624, +v_20040625, +v_20040626, +v_20040627}:
      v_13 = v_20040626
      ArenaResult{v_20040628, +v_20040629} = initial_telescope_count(v_20040613, v_13, v_1)
      {ArenaResult{v_20040628, Nat.add(1n, v_20040629)} : ArenaResult<Nat>}
    case _:
      {ArenaResult{v_20040613, 0n} : ArenaResult<Nat>}

def initial_telescope_count(v_20040631: ArenaStore, v_0: U32, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Nat>:
  ArenaResult{v_20040632, +v_20040633} = whnf(v_20040631, 64n, v_0, v_1)
  ArenaResult{v_20040634, +v_20040635} = initial_telescope_count_view(v_20040632, v_20040633, v_1)
  {ArenaResult{v_20040634, v_20040635} : ArenaResult<Nat>}

def drop_telescope_view(v_20040636: ArenaStore, v_0: U32, v_2: Nat, v_3: U32, v_4: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  ArenaResult{v_20040637, +v_20040638} = arena_get_node(v_20040636, v_0)
  match v_20040638:
    case Arena.TermAll{+v_20040645, +v_20040646, +v_20040648, +v_20040649, +v_20040650, +v_20040651}:
      v_15 = v_20040650
      ArenaResult{v_20040652, +v_20040653} = drop_telescope(v_20040637, v_2, v_15, v_4)
      {ArenaResult{v_20040652, v_20040653} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_20040637, v_3} : ArenaResult<U32>}

def drop_telescope(v_20040655: ArenaStore, v_1: Nat, v_2: U32, v_3: Scope.ArenaGlobalScope) -> ArenaResult<U32>:
  match v_1:
    case 0n:
      {ArenaResult{v_20040655, v_2} : ArenaResult<U32>}
    case 1n++v_20040656:
      v_5 = v_20040656
      ArenaResult{v_20040657, +v_20040658} = whnf(v_20040655, 64n, v_2, v_3)
      ArenaResult{v_20040659, +v_20040660} = drop_telescope_view(v_20040657, v_20040658, v_5, v_2, v_3)
      {ArenaResult{v_20040659, v_20040660} : ArenaResult<U32>}

def constructor_field_arity_family_global(v_20040661: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_2: U32, v_3: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Nat>>:
  match v_1:
    case None{}:
      {ArenaResult{v_20040661, None{}} : ArenaResult<Maybe<&2, Nat>>}
    case Some{+v_20040662}:
      v_7 = v_20040662
      match v_7:
        case Scope.ArenaGlobal{+v_20040663, +v_20040664, +v_20040665, +v_20040666, +v_20040667, +v_20040668}:
          v_17 = v_20040666
          ArenaResult{v_20040669, +v_20040670} = initial_telescope_count(v_20040661, v_17, v_3)
          v_22 = v_20040670
          ArenaResult{v_20040671, +v_20040672} = drop_telescope(v_20040669, v_22, v_2, v_3)
          ArenaResult{v_20040673, +v_20040674} = initial_telescope_count(v_20040671, v_20040672, v_3)
          {ArenaResult{v_20040673, Some{v_20040674}} : ArenaResult<Maybe<&2, Nat>>}

def constructor_field_arity_family(v_20040675: ArenaStore, v_2: Maybe<&2, String>, v_3: U32, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Nat>>:
  match v_2:
    case None{}:
      {ArenaResult{v_20040675, None{}} : ArenaResult<Maybe<&2, Nat>>}
    case Some{+v_20040676}:
      v_8 = v_20040676
      ArenaResult{v_20040677, +v_20040678} = constructor_field_arity_family_global(v_20040675, Scope.lookup(v_8, v_4), v_3, v_4)
      {ArenaResult{v_20040677, v_20040678} : ArenaResult<Maybe<&2, Nat>>}

def constructor_field_arity_global(v_20040679: ArenaStore, v_0: Scope.ArenaGlobal, v_1: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Nat>>:
  match v_0:
    case Scope.ArenaGlobal{+v_20040680, +v_20040681, +v_20040682, +v_20040683, +v_20040684, +v_20040685}:
      v_13 = v_20040683
      ArenaResult{v_20040686, +v_20040687} = constructor_family(v_20040679, v_13, v_1)
      ArenaResult{v_20040688, +v_20040689} = constructor_field_arity_family(v_20040686, v_20040687, v_13, v_1)
      {ArenaResult{v_20040688, v_20040689} : ArenaResult<Maybe<&2, Nat>>}

def constructor_field_arity_result(v_20040690: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_2: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Nat>>:
  match v_1:
    case None{}:
      {ArenaResult{v_20040690, None{}} : ArenaResult<Maybe<&2, Nat>>}
    case Some{+v_20040691}:
      v_6 = v_20040691
      ArenaResult{v_20040692, +v_20040693} = constructor_field_arity_global(v_20040690, v_6, v_2)
      {ArenaResult{v_20040692, v_20040693} : ArenaResult<Maybe<&2, Nat>>}

def constructor_field_arity(v_20040694: ArenaStore, v_1: String, v_2: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Nat>>:
  ArenaResult{v_20040695, +v_20040696} = constructor_field_arity_result(v_20040694, Scope.lookup_kind(v_1, Scope.GlobalConstructor{}, v_2), v_2)
  {ArenaResult{v_20040695, v_20040696} : ArenaResult<Maybe<&2, Nat>>}

def replace_first_column_with_value(v_20040697: ArenaStore, v_1: IR.Words, v_2: U32) -> ArenaResult<IR.Words>:
  ArenaResult{v_20040698, +v_20040699} = arena_words_view(v_20040697, v_1)
  match v_20040699:
    case IR.WordNil{}:
      {ArenaResult{v_20040698, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20040700, +v_20040701}:
      v_7 = v_20040701
      ArenaResult{v_20040702, +v_20040703} = arena_words_cons(v_20040698, v_2, v_7)
      {ArenaResult{v_20040702, v_20040703} : ArenaResult<IR.Words>}

def recursion_terminates_mat_head(v_1: ArenaStore, v_3: U32, v_5: String, v_7: String, v_9: Nat, v_10: IR.Words, v_11: IR.Quantities, v_13: Nat, v_14: IR.Words, v_15: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_9:
    case 0n:
      ArenaResult{v_22, +v_23} = term_span(v_1, v_3)
      ArenaResult{v_27, +v_28} = arena_name(v_22, v_7)
      v_50000306 = arena_words_start(v_14)
      v_50000307 = arena_words_count(v_14)
      ArenaResult{v_34, +v_35} = arena_put_node(v_27, Arena.TermCtr{v_28, v_50000306, v_50000307, v_23})
      v_37 = v_35
      ArenaResult{v_42, +v_43} = shift_terms(v_34, v_10, arena_words_length(v_14))
      ArenaResult{v_47, +v_48} = replace_first_column_with_value(v_42, v_43, v_37)
      v_50 = v_48
      ArenaResult{v_55, +v_56} = recursion_terminates(v_47, v_3, v_5, v_50, v_11, Nat.add(v_13, arena_words_length(v_14)), v_15)
      {ArenaResult{v_55, v_56} : ArenaResult<Bool>}
    case 1n++v_58:
      ArenaResult{v_62, +v_63} = arena_get_node(v_1, v_3)
      match v_63:
        case Arena.TermLam{+v_69, +v_70, +v_71, +v_72, +v_73}:
          match v_69:
            case Some{+v_75}:
              match v_75:
                case Ast.QZero{}:
                  {ArenaResult{v_62, True{}} : ArenaResult<Bool>}
                case _:
                  v_79 = v_72
                  v_81 = v_73
                  v_83 = v_58
                  ArenaResult{v_87, +v_88} = shift_terms(v_62, v_14, 1n)
                  ArenaResult{v_92, +v_93} = arena_name(v_87, "")
                  ArenaResult{v_97, +v_98} = arena_put_node(v_92, Arena.TermVar{v_93, 0n, v_81})
                  ArenaResult{v_102, +v_103} = arena_words_cons(v_97, v_98, IR.Words{0, 0})
                  ArenaResult{v_107, +v_108} = arena_words_append(v_102, v_88, v_103)
                  v_110 = v_108
                  ArenaResult{v_114, +v_115} = recursion_terminates_mat_head(v_107, v_79, v_5, v_7, v_83, v_10, v_11, v_13, v_110, v_15)
                  {ArenaResult{v_114, v_115} : ArenaResult<Bool>}
            case _:
              v_119 = v_72
              v_121 = v_73
              v_123 = v_58
              ArenaResult{v_127, +v_128} = shift_terms(v_62, v_14, 1n)
              ArenaResult{v_132, +v_133} = arena_name(v_127, "")
              ArenaResult{v_137, +v_138} = arena_put_node(v_132, Arena.TermVar{v_133, 0n, v_121})
              ArenaResult{v_142, +v_143} = arena_words_cons(v_137, v_138, IR.Words{0, 0})
              ArenaResult{v_147, +v_148} = arena_words_append(v_142, v_128, v_143)
              v_150 = v_148
              ArenaResult{v_154, +v_155} = recursion_terminates_mat_head(v_147, v_119, v_5, v_7, v_123, v_10, v_11, v_13, v_150, v_15)
              {ArenaResult{v_154, v_155} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_62, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_1, False{}} : ArenaResult<Bool>}

def recursion_terminates_application_view(v_20040763: ArenaStore, v_0: U32, v_1: U32, v_2: U32, v_3: U32, v_5: String, v_7: IR.Words, v_9: IR.Quantities, v_11: Nat, v_12: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20040764, +v_20040765} = arena_get_node(v_20040763, v_0)
  match v_20040765:
    case Arena.TermRef{+v_20040768, +v_20040770}:
      ArenaResult{v_20040771, +v_20040772} = arena_name_text(v_20040764, v_20040768)
      +v_20040769 = v_20040772
      v_16 = v_20040769
      +v_20040773 = String.eq(v_16, v_5)
      match v_20040773:
        case True{}:
          ArenaResult{v_20040774, +v_20040775} = application_args(v_20040771, v_1)
          v_20 = v_20040775
          ArenaResult{v_20040776, +v_20040777} = recursive_call_decreases(v_20040774, v_20, v_7, v_9)
          match v_20040777:
            case True{}:
              ArenaResult{v_20040778, +v_20040779} = recursion_terminates_call_args(v_20040776, v_20, v_5, v_7, v_9, v_9, v_11, v_12)
              {ArenaResult{v_20040778, v_20040779} : ArenaResult<Bool>}
            case False{}:
              {ArenaResult{v_20040776, False{}} : ArenaResult<Bool>}
        case False{}:
          ArenaResult{v_20040780, +v_20040781} = recursion_terminates(v_20040771, v_2, v_5, v_7, v_9, v_11, v_12)
          ArenaResult{v_20040782, +v_20040783} = recursion_terminates(v_20040780, v_3, v_5, v_7, v_9, v_11, v_12)
          {ArenaResult{v_20040782, Bool.and(v_20040781, v_20040783)} : ArenaResult<Bool>}
    case _:
      ArenaResult{v_20040785, +v_20040786} = recursion_terminates(v_20040764, v_2, v_5, v_7, v_9, v_11, v_12)
      ArenaResult{v_20040787, +v_20040788} = recursion_terminates(v_20040785, v_3, v_5, v_7, v_9, v_11, v_12)
      {ArenaResult{v_20040787, Bool.and(v_20040786, v_20040788)} : ArenaResult<Bool>}

def recursion_terminates_mat_arity(v_20040789: ArenaStore, v_2: Maybe<&2, Nat>, v_3: U32, v_4: U32, v_6: String, v_8: String, v_10: IR.Words, v_12: IR.Quantities, v_14: Nat, v_15: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_2:
    case Some{+v_20040790}:
      v_18 = v_20040790
      ArenaResult{v_20040791, +v_20040792} = recursion_terminates_mat_head(v_20040789, v_3, v_8, Scope.canonical_name(v_6, v_15), v_18, v_10, v_12, v_14, IR.Words{0, 0}, v_15)
      ArenaResult{v_20040793, +v_20040794} = recursion_terminates(v_20040791, v_4, v_8, v_10, v_12, v_14, v_15)
      {ArenaResult{v_20040793, Bool.and(v_20040792, v_20040794)} : ArenaResult<Bool>}
    case None{}:
      ArenaResult{v_20040795, +v_20040796} = recursion_terminates(v_20040789, v_3, v_8, v_10, v_12, v_14, v_15)
      ArenaResult{v_20040797, +v_20040798} = recursion_terminates(v_20040795, v_4, v_8, v_10, v_12, v_14, v_15)
      {ArenaResult{v_20040797, Bool.and(v_20040796, v_20040798)} : ArenaResult<Bool>}

def recursion_terminates(v_20040799: ArenaStore, v_0: U32, v_2: String, v_4: IR.Words, v_6: IR.Quantities, v_8: Nat, v_9: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20040800, +v_20040801} = arena_get_node(v_20040799, v_0)
  match v_20040801:
    case Arena.TermRef{+v_20040804, +v_20040806}:
      ArenaResult{v_20040807, +v_20040808} = arena_name_text(v_20040800, v_20040804)
      +v_20040805 = v_20040808
      v_13 = v_20040805
      {ArenaResult{v_20040807, Bool.not(String.eq(v_13, v_2))} : ArenaResult<Bool>}
    case Arena.TermBang{+v_20040811, +v_20040812}:
      v_17 = v_20040811
      ArenaResult{v_20040813, +v_20040814} = recursion_terminates(v_20040800, v_17, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20040813, v_20040814} : ArenaResult<Bool>}
    case Arena.TermApp{+v_20040818, +v_20040819, +v_20040820}:
      v_23 = v_20040818
      v_24 = v_20040819
      ArenaResult{v_20040821, +v_20040822} = application_head(v_20040800, v_0)
      ArenaResult{v_20040823, +v_20040824} = recursion_terminates_application_view(v_20040821, v_20040822, v_0, v_23, v_24, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20040823, v_20040824} : ArenaResult<Bool>}
    case Arena.TermFill{+v_20040828, +v_20040829, +v_20040830, +v_20040832}:
      +v_20040831 = IR.Words{v_20040829, v_20040830}
      v_31 = v_20040828
      v_32 = v_20040831
      ArenaResult{v_20040833, +v_20040834} = recursion_terminates(v_20040800, v_31, v_2, v_4, v_6, v_8, v_9)
      ArenaResult{v_20040835, +v_20040836} = recursion_terminates_list(v_20040833, v_32, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20040835, Bool.and(v_20040834, v_20040836)} : ArenaResult<Bool>}
    case Arena.TermPlus{+v_20040840, +v_20040841, +v_20040842, +v_20040844}:
      +v_20040843 = IR.Words{v_20040841, v_20040842}
      v_39 = v_20040840
      v_40 = v_20040843
      ArenaResult{v_20040845, +v_20040846} = recursion_terminates(v_20040800, v_39, v_2, v_4, v_6, v_8, v_9)
      ArenaResult{v_20040847, +v_20040848} = recursion_terminates_list(v_20040845, v_40, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20040847, Bool.and(v_20040846, v_20040848)} : ArenaResult<Bool>}
    case Arena.TermMat{+v_20040853, +v_20040855, +v_20040856, +v_20040857}:
      ArenaResult{v_20040858, +v_20040859} = arena_name_text(v_20040800, v_20040853)
      +v_20040854 = v_20040859
      v_48 = v_20040854
      v_49 = v_20040855
      v_50 = v_20040856
      ArenaResult{v_20040860, +v_20040861} = constructor_field_arity(v_20040858, v_48, v_9)
      ArenaResult{v_20040862, +v_20040863} = recursion_terminates_mat_arity(v_20040860, v_20040861, v_49, v_50, v_48, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20040862, v_20040863} : ArenaResult<Bool>}
    case Arena.TermLam{+v_20040869, +v_20040870, +v_20040872, +v_20040873, +v_20040874}:
      match v_20040869:
        case Some{+v_20040877}:
          match v_20040877:
            case Ast.QZero{}:
              {ArenaResult{v_20040800, True{}} : ArenaResult<Bool>}
            case _:
              v_70 = v_20040873
              ArenaResult{v_20040879, +v_20040880} = shift_terms(v_20040800, v_4, 1n)
              ArenaResult{v_20040881, +v_20040882} = recursion_terminates(v_20040879, v_70, v_2, v_20040880, v_6, Nat.add(v_8, 1n), v_9)
              {ArenaResult{v_20040881, v_20040882} : ArenaResult<Bool>}
        case _:
          v_70 = v_20040873
          ArenaResult{v_20040884, +v_20040885} = shift_terms(v_20040800, v_4, 1n)
          ArenaResult{v_20040886, +v_20040887} = recursion_terminates(v_20040884, v_70, v_2, v_20040885, v_6, Nat.add(v_8, 1n), v_9)
          {ArenaResult{v_20040886, v_20040887} : ArenaResult<Bool>}
    case Arena.TermAll{+v_20040894, +v_20040895, +v_20040897, +v_20040898, +v_20040899, +v_20040900}:
      {ArenaResult{v_20040800, True{}} : ArenaResult<Bool>}
    case Arena.TermType{+v_20040903, +v_20040904}:
      {ArenaResult{v_20040800, True{}} : ArenaResult<Bool>}
    case Arena.TermMin{+v_20040908, +v_20040909, +v_20040910}:
      v_93 = v_20040908
      v_94 = v_20040909
      ArenaResult{v_20040911, +v_20040912} = recursion_terminates(v_20040800, v_93, v_2, v_4, v_6, v_8, v_9)
      ArenaResult{v_20040913, +v_20040914} = recursion_terminates(v_20040911, v_94, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20040913, Bool.and(v_20040912, v_20040914)} : ArenaResult<Bool>}
    case Arena.TermAdt{+v_20040919, +v_20040921, +v_20040922, +v_20040924, +v_20040925, +v_20040927}:
      {ArenaResult{v_20040800, True{}} : ArenaResult<Bool>}
    case Arena.TermString{_, _, _}:
      {ArenaResult{v_20040800, True{}} : ArenaResult<Bool>}
    case Arena.TermCtr{+v_20040931, +v_20040933, +v_20040934, +v_20040936}:
      +v_20040935 = IR.Words{v_20040933, v_20040934}
      v_110 = v_20040935
      ArenaResult{v_20040937, +v_20040938} = recursion_terminates_list(v_20040800, v_110, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20040937, v_20040938} : ArenaResult<Bool>}
    case Arena.TermEqual{+v_20040943, +v_20040944, +v_20040945, +v_20040946}:
      {ArenaResult{v_20040800, True{}} : ArenaResult<Bool>}
    case Arena.TermRewrite{+v_20040951, +v_20040952, +v_20040953, +v_20040954}:
      v_125 = v_20040951
      v_127 = v_20040953
      ArenaResult{v_20040955, +v_20040956} = recursion_terminates(v_20040800, v_125, v_2, v_4, v_6, v_8, v_9)
      ArenaResult{v_20040957, +v_20040958} = recursion_terminates(v_20040955, v_127, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20040957, Bool.and(v_20040956, v_20040958)} : ArenaResult<Bool>}
    case Arena.TermAnn{+v_20040962, +v_20040963, +v_20040964}:
      v_134 = v_20040962
      ArenaResult{v_20040965, +v_20040966} = recursion_terminates(v_20040800, v_134, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20040965, v_20040966} : ArenaResult<Bool>}
    case Arena.TermTemplate{+v_20040969, +v_20040970}:
      {ArenaResult{v_20040800, True{}} : ArenaResult<Bool>}
    case Arena.TermLet{+v_20040977, +v_20040978, +v_20040980, +v_20040981, +v_20040983, +v_20040984, +v_20040986, +v_20040987, +v_20040989, +v_20040990}:
      +v_20040979 = IR.Names{v_20040977, v_20040978}
      +v_20040988 = IR.Words{v_20040986, v_20040987}
      v_148 = v_20040979
      v_151 = v_20040988
      v_152 = v_20040989
      ArenaResult{v_20040991, +v_20040992} = recursion_terminates_list(v_20040800, v_151, v_2, v_4, v_6, v_8, v_9)
      ArenaResult{v_20040993, +v_20040994} = shift_terms(v_20040991, v_4, arena_names_length(v_148))
      ArenaResult{v_20040995, +v_20040996} = recursion_terminates(v_20040993, v_152, v_2, v_20040994, v_6, Nat.add(v_8, arena_names_length(v_148)), v_9)
      {ArenaResult{v_20040995, Bool.and(v_20040992, v_20040996)} : ArenaResult<Bool>}
    case Arena.TermSub{+v_20041001, +v_20041002, +v_20041003, +v_20041004}:
      v_163 = v_20041001
      v_164 = v_20041002
      v_165 = v_20041003
      ArenaResult{v_20041005, +v_20041006} = core_subst(v_20040800, v_163, v_164, v_165)
      ArenaResult{v_20041007, +v_20041008} = recursion_terminates(v_20041005, v_20041006, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20041007, v_20041008} : ArenaResult<Bool>}
    case Arena.BodyMatch{+v_20041012, +v_20041013, +v_20041015, +v_20041016, +v_20041018}:
      +v_20041014 = IR.Words{v_20041012, v_20041013}
      +v_20041017 = IR.Words{v_20041015, v_20041016}
      v_171 = v_20041014
      v_172 = v_20041017
      ArenaResult{v_20041019, +v_20041020} = recursion_terminates_list(v_20040800, v_171, v_2, v_4, v_6, v_8, v_9)
      ArenaResult{v_20041021, +v_20041022} = recursion_terminates_cases(v_20041019, v_172, v_171, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20041021, Bool.and(v_20041020, v_20041022)} : ArenaResult<Bool>}
    case Arena.BodyCase{+v_20041026, +v_20041027, +v_20041029, +v_20041030}:
      v_180 = v_20041029
      ArenaResult{v_20041031, +v_20041032} = recursion_terminates(v_20040800, v_180, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20041031, v_20041032} : ArenaResult<Bool>}
    case Arena.BodyLocal{+v_20041038, +v_20041039, +v_20041041, +v_20041042, +v_20041043, +v_20041045, +v_20041046}:
      +v_20041040 = IR.Words{v_20041038, v_20041039}
      +v_20041044 = IR.Words{v_20041042, v_20041043}
      ArenaResult{v_20041047, +v_20041048} = arena_words_view(v_20040800, v_20041040)
      match v_20041048:
        case IR.WordCons{+v_20041053, +v_20041054}:
          ArenaResult{v_20041055, +v_20041056} = arena_get_pattern(v_20041047, v_20041053)
          match v_20041056:
            case Arena.PatternCtr{+v_20041063, +v_20041065, +v_20041066, +v_20041068}:
              ArenaResult{v_20041069, +v_20041070} = arena_name_text(v_20041055, v_20041063)
              +v_20041064 = v_20041070
              +v_20041067 = IR.Words{v_20041065, v_20041066}
              ArenaResult{v_20041071, +v_20041072} = arena_words_view(v_20041069, v_20041054)
              match v_20041072:
                case IR.WordNil{}:
                  match v_20041041:
                    case Ast.QOne{}:
                      ArenaResult{v_20041073, +v_20041074} = arena_words_view(v_20041071, v_20041044)
                      match v_20041074:
                        case IR.WordCons{+v_20041079, +v_20041080}:
                          ArenaResult{v_20041081, +v_20041082} = arena_words_view(v_20041073, v_20041080)
                          match v_20041082:
                            case IR.WordNil{}:
                              v_192 = v_20041079
                              v_189 = v_20041064
                              v_190 = v_20041067
                              v_191 = v_20041068
                              v_193 = v_20041045
                              v_194 = v_20041046
                              ArenaResult{v_20041083, +v_20041084} = destructuring_local_match(v_20041081, v_189, v_190, v_191, v_192, v_193, v_194)
                              ArenaResult{v_20041085, +v_20041086} = recursion_terminates(v_20041083, v_20041084, v_2, v_4, v_6, v_8, v_9)
                              {ArenaResult{v_20041085, v_20041086} : ArenaResult<Bool>}
                            case _:
                              v_202 = v_20041040
                              v_204 = v_20041044
                              v_205 = v_20041045
                              ArenaResult{v_20041088, +v_20041089} = recursion_terminates_list(v_20041081, v_204, v_2, v_4, v_6, v_8, v_9)
                              ArenaResult{v_20041090, +v_20041091} = core_pattern_list_depth(v_20041088, v_202)
                              ArenaResult{v_20041092, +v_20041093} = shift_terms(v_20041090, v_4, v_20041091)
                              ArenaResult{v_20041094, +v_20041095} = core_pattern_list_depth(v_20041092, v_202)
                              ArenaResult{v_20041096, +v_20041097} = recursion_terminates(v_20041094, v_205, v_2, v_20041093, v_6, Nat.add(v_8, v_20041095), v_9)
                              {ArenaResult{v_20041096, Bool.and(v_20041089, v_20041097)} : ArenaResult<Bool>}
                        case _:
                          v_202 = v_20041040
                          v_204 = v_20041044
                          v_205 = v_20041045
                          ArenaResult{v_20041099, +v_20041100} = recursion_terminates_list(v_20041073, v_204, v_2, v_4, v_6, v_8, v_9)
                          ArenaResult{v_20041101, +v_20041102} = core_pattern_list_depth(v_20041099, v_202)
                          ArenaResult{v_20041103, +v_20041104} = shift_terms(v_20041101, v_4, v_20041102)
                          ArenaResult{v_20041105, +v_20041106} = core_pattern_list_depth(v_20041103, v_202)
                          ArenaResult{v_20041107, +v_20041108} = recursion_terminates(v_20041105, v_205, v_2, v_20041104, v_6, Nat.add(v_8, v_20041106), v_9)
                          {ArenaResult{v_20041107, Bool.and(v_20041100, v_20041108)} : ArenaResult<Bool>}
                    case _:
                      v_202 = v_20041040
                      v_204 = v_20041044
                      v_205 = v_20041045
                      ArenaResult{v_20041110, +v_20041111} = recursion_terminates_list(v_20041071, v_204, v_2, v_4, v_6, v_8, v_9)
                      ArenaResult{v_20041112, +v_20041113} = core_pattern_list_depth(v_20041110, v_202)
                      ArenaResult{v_20041114, +v_20041115} = shift_terms(v_20041112, v_4, v_20041113)
                      ArenaResult{v_20041116, +v_20041117} = core_pattern_list_depth(v_20041114, v_202)
                      ArenaResult{v_20041118, +v_20041119} = recursion_terminates(v_20041116, v_205, v_2, v_20041115, v_6, Nat.add(v_8, v_20041117), v_9)
                      {ArenaResult{v_20041118, Bool.and(v_20041111, v_20041119)} : ArenaResult<Bool>}
                case _:
                  v_202 = v_20041040
                  v_204 = v_20041044
                  v_205 = v_20041045
                  ArenaResult{v_20041121, +v_20041122} = recursion_terminates_list(v_20041071, v_204, v_2, v_4, v_6, v_8, v_9)
                  ArenaResult{v_20041123, +v_20041124} = core_pattern_list_depth(v_20041121, v_202)
                  ArenaResult{v_20041125, +v_20041126} = shift_terms(v_20041123, v_4, v_20041124)
                  ArenaResult{v_20041127, +v_20041128} = core_pattern_list_depth(v_20041125, v_202)
                  ArenaResult{v_20041129, +v_20041130} = recursion_terminates(v_20041127, v_205, v_2, v_20041126, v_6, Nat.add(v_8, v_20041128), v_9)
                  {ArenaResult{v_20041129, Bool.and(v_20041122, v_20041130)} : ArenaResult<Bool>}
            case _:
              v_202 = v_20041040
              v_204 = v_20041044
              v_205 = v_20041045
              ArenaResult{v_20041132, +v_20041133} = recursion_terminates_list(v_20041055, v_204, v_2, v_4, v_6, v_8, v_9)
              ArenaResult{v_20041134, +v_20041135} = core_pattern_list_depth(v_20041132, v_202)
              ArenaResult{v_20041136, +v_20041137} = shift_terms(v_20041134, v_4, v_20041135)
              ArenaResult{v_20041138, +v_20041139} = core_pattern_list_depth(v_20041136, v_202)
              ArenaResult{v_20041140, +v_20041141} = recursion_terminates(v_20041138, v_205, v_2, v_20041137, v_6, Nat.add(v_8, v_20041139), v_9)
              {ArenaResult{v_20041140, Bool.and(v_20041133, v_20041141)} : ArenaResult<Bool>}
        case _:
          v_202 = v_20041040
          v_204 = v_20041044
          v_205 = v_20041045
          ArenaResult{v_20041143, +v_20041144} = recursion_terminates_list(v_20041047, v_204, v_2, v_4, v_6, v_8, v_9)
          ArenaResult{v_20041145, +v_20041146} = core_pattern_list_depth(v_20041143, v_202)
          ArenaResult{v_20041147, +v_20041148} = shift_terms(v_20041145, v_4, v_20041146)
          ArenaResult{v_20041149, +v_20041150} = core_pattern_list_depth(v_20041147, v_202)
          ArenaResult{v_20041151, +v_20041152} = recursion_terminates(v_20041149, v_205, v_2, v_20041148, v_6, Nat.add(v_8, v_20041150), v_9)
          {ArenaResult{v_20041151, Bool.and(v_20041144, v_20041152)} : ArenaResult<Bool>}
    case Arena.BodyReply{+v_20041155, +v_20041156}:
      v_212 = v_20041155
      ArenaResult{v_20041157, +v_20041158} = recursion_terminates(v_20040800, v_212, v_2, v_4, v_6, v_8, v_9)
      {ArenaResult{v_20041157, v_20041158} : ArenaResult<Bool>}
    case Arena.TermHole{+v_20041161, +v_20041163}:
      {ArenaResult{v_20040800, True{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20040800, True{}} : ArenaResult<Bool>}

def recursion_terminates_cases(v_20041165: ArenaStore, v_1: IR.Words, v_3: IR.Words, v_5: String, v_7: IR.Words, v_9: IR.Quantities, v_11: Nat, v_12: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20041166, +v_20041167} = arena_words_view(v_20041165, v_1)
  match v_20041167:
    case IR.WordNil{}:
      {ArenaResult{v_20041166, True{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20041168, +v_20041169}:
      +v_16 = v_20041168
      v_17 = v_20041169
      ArenaResult{v_20041170, +v_20041171} = arena_get_node(v_20041166, v_16)
      match v_20041171:
        case Arena.BodyCase{+v_20041175, +v_20041176, +v_20041178, +v_20041179}:
          +v_20041177 = IR.Words{v_20041175, v_20041176}
          v_21 = v_20041177
          v_22 = v_20041178
          ArenaResult{v_20041180, +v_20041181} = core_pattern_list_depth(v_20041170, v_21)
          v_25 = v_20041181
          ArenaResult{v_20041182, +v_20041183} = branch_order_columns(v_20041180, v_7, v_3, v_21, Nat.add(v_11, v_25), v_25)
          v_28 = v_20041183
          ArenaResult{v_20041184, +v_20041185} = match_branch_body(v_20041182, v_21, v_3, v_22, v_25, Nat.add(v_11, v_25), v_12)
          v_31 = v_20041185
          ArenaResult{v_20041186, +v_20041187} = recursion_terminates(v_20041184, v_31, v_5, v_28, v_9, Nat.add(v_11, v_25), v_12)
          ArenaResult{v_20041188, +v_20041189} = recursion_terminates_cases(v_20041186, v_17, v_3, v_5, v_7, v_9, v_11, v_12)
          {ArenaResult{v_20041188, Bool.and(v_20041187, v_20041189)} : ArenaResult<Bool>}
        case _:
          ArenaResult{v_20041191, +v_20041192} = recursion_terminates(v_20041170, v_16, v_5, v_7, v_9, v_11, v_12)
          ArenaResult{v_20041193, +v_20041194} = recursion_terminates_cases(v_20041191, v_17, v_3, v_5, v_7, v_9, v_11, v_12)
          {ArenaResult{v_20041193, Bool.and(v_20041192, v_20041194)} : ArenaResult<Bool>}

def recursion_terminates_list(v_20041195: ArenaStore, v_1: IR.Words, v_3: String, v_5: IR.Words, v_7: IR.Quantities, v_9: Nat, v_10: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20041196, +v_20041197} = arena_words_view(v_20041195, v_1)
  match v_20041197:
    case IR.WordNil{}:
      {ArenaResult{v_20041196, True{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20041198, +v_20041199}:
      +v_14 = v_20041198
      v_15 = v_20041199
      ArenaResult{v_20041200, +v_20041201} = recursion_terminates(v_20041196, v_14, v_3, v_5, v_7, v_9, v_10)
      ArenaResult{v_20041202, +v_20041203} = recursion_terminates_list(v_20041200, v_15, v_3, v_5, v_7, v_9, v_10)
      {ArenaResult{v_20041202, Bool.and(v_20041201, v_20041203)} : ArenaResult<Bool>}

def recursion_terminates_call_args(v_20041204: ArenaStore, v_1: IR.Words, v_3: String, v_5: IR.Words, v_7: IR.Quantities, v_9: IR.Quantities, v_11: Nat, v_12: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20041205, +v_20041206} = arena_words_view(v_20041204, v_1)
  match v_20041206:
    case IR.WordNil{}:
      {ArenaResult{v_20041205, True{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20041207, +v_20041208}:
      ArenaResult{v_20041209, +v_20041210} = arena_quantities_view(v_20041205, v_9)
      match v_20041210:
        case IR.QuantityCons{+v_20041211, +v_20041212}:
          +v_22 = v_20041211
          v_23 = v_20041212
          +v_20 = v_20041207
          v_21 = v_20041208
          match v_22:
            case Ast.QZero{}:
              ArenaResult{v_20041213, +v_20041214} = recursion_terminates_call_args(v_20041209, v_21, v_3, v_5, v_7, v_23, v_11, v_12)
              {ArenaResult{v_20041213, v_20041214} : ArenaResult<Bool>}
            case _:
              ArenaResult{v_20041216, +v_20041217} = recursion_terminates(v_20041209, v_20, v_3, v_5, v_7, v_11, v_12)
              ArenaResult{v_20041218, +v_20041219} = recursion_terminates_call_args(v_20041216, v_21, v_3, v_5, v_7, v_23, v_11, v_12)
              {ArenaResult{v_20041218, Bool.and(v_20041217, v_20041219)} : ArenaResult<Bool>}
        case IR.QuantityNil{}:
          +v_31 = v_20041207
          v_32 = v_20041208
          ArenaResult{v_20041220, +v_20041221} = recursion_terminates(v_20041209, v_31, v_3, v_5, v_7, v_11, v_12)
          ArenaResult{v_20041222, +v_20041223} = recursion_terminates_list(v_20041220, v_32, v_3, v_5, v_7, v_11, v_12)
          {ArenaResult{v_20041222, Bool.and(v_20041221, v_20041223)} : ArenaResult<Bool>}

def check_termination_result(v_1: Bool, v_3: String, v_4: Ast.SourceSpan) -> Maybe<&2, Diagnostic>:
  +v_8 = v_1
  match v_8:
    case False{}:
      v_50000308 = span_file(v_4)
      v_50000309 = Diagnostic{v_50000308, v_4, String.append("definition is not structurally terminating: ", v_3), "a strictly decreasing recursive call", "a non-decreasing or unguarded call"}
      +v_11 = Some{v_50000309}
      v_11
    case True{}:
      +v_14 = {None{} : Maybe<&2, Diagnostic>}
      v_14

def check_termination(v_1: ArenaStore, v_3: Bool, v_5: String, v_6: IR.Words, v_8: U32, v_9: Ast.SourceSpan, v_10: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Diagnostic>>:
  match v_3:
    case True{}:
      {ArenaResult{v_1, None{}} : ArenaResult<Maybe<&2, Diagnostic>>}
    case False{}:
      ArenaResult{v_18, +v_19} = binder_count(v_1, v_6)
      v_21 = v_19
      ArenaResult{v_25, +v_26} = parameter_vars(v_18, v_6, v_21, v_9)
      v_28 = v_26
      ArenaResult{v_32, +v_33} = binders_quantities(v_25, v_6)
      v_35 = v_33
      ArenaResult{v_39, +v_40} = recursion_terminates(v_32, v_8, v_5, v_28, v_35, v_21, v_10)
      v_50000310 = check_termination_result(v_40, v_5, v_9)
      {ArenaResult{v_39, v_50000310} : ArenaResult<Maybe<&2, Diagnostic>>}

def validate_definition_termination(v_20041235: ArenaStore, v_2: Maybe<&2, Diagnostic>, v_4: IR.Words, v_5: U32, v_6: U32, v_7: Scope.ArenaGlobalScope, v_9: Bool) -> ArenaResult<Maybe<&2, Diagnostic>>:
  match v_2:
    case Some{+v_20041236}:
      v_13 = v_20041236
      {ArenaResult{v_20041235, Some{v_13}} : ArenaResult<Maybe<&2, Diagnostic>>}
    case None{}:
      ArenaResult{v_20041237, +v_20041238} = binder_count(v_20041235, v_4)
      v_17 = v_20041238
      ArenaResult{v_20041239, +v_20041240} = binders_env(v_20041237, v_4, [])
      ArenaResult{v_20041241, +v_20041242} = binder_usage_map(v_20041239, v_17, v_5, v_20041240, v_7, Some{v_6}, v_9)
      ArenaResult{v_20041243, +v_20041244} = check_binder_usage_map(v_20041241, v_4, v_17, v_20041242)
      {ArenaResult{v_20041243, v_20041244} : ArenaResult<Maybe<&2, Diagnostic>>}

def validate_definition_uses(v_20041245: ArenaStore, v_1: Bool, v_3: String, v_5: IR.Words, v_6: U32, v_7: U32, v_8: Ast.SourceSpan, v_9: Scope.ArenaGlobalScope, v_11: Bool) -> ArenaResult<Maybe<&2, Diagnostic>>:
  ArenaResult{v_20041246, +v_20041247} = check_termination(v_20041245, v_1, v_3, v_5, v_6, v_8, v_9)
  ArenaResult{v_20041248, +v_20041249} = validate_definition_termination(v_20041246, v_20041247, v_5, v_6, v_7, v_9, v_11)
  {ArenaResult{v_20041248, v_20041249} : ArenaResult<Maybe<&2, Diagnostic>>}

def store_definition_declared(v_1: ArenaStore, v_2: Scope.ArenaGlobal, v_4: String, v_6: String, v_8: U32, v_10: U32, v_11: Scope.ArenaGlobalScope, v_12: Scope.ArenaGlobalScope, v_13: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_2:
    case Scope.ArenaGlobal{+v_23, +v_24, +v_25, +v_26, +v_27, +v_28}:
      match v_27:
        case IR.NoTerm{}:
          match v_28:
            case Scope.GlobalDefinition{}:
              v_30 = v_26
              ArenaResult{v_34, +v_35} = canonicalize_term(v_1, v_30, v_12)
              v_37 = v_35
              ArenaResult{v_41, +v_42} = fits_term(v_34, v_8, v_37, v_12)
              +v_44 = v_42
              match v_44:
                case False{}:
                  v_50000311 = span_file(v_13)
                  v_50000312 = Diagnostic{v_50000311, v_13, String.append("definition does not fill its declared type: ", v_4), "the existing declaration type", "an incompatible inferred type"}
                  +v_47 = ScopedStateFailure{v_50000312}
                  v_49 = v_41
                  {ArenaResult{v_49, v_47} : ArenaResult<ScopedState>}
                case True{}:
                  v_50000313 = canonical_key(v_6, v_4)
                  ArenaResult{v_55, +v_56} = arena_publish_global(v_41, Scope.ArenaGlobal{v_50000313, v_6, v_4, v_37, IR.SomeTerm{v_10}, Scope.GlobalDefinition{}})
                  ArenaResult{v_60, +v_61} = global_scope_prepend(v_55, v_56, v_11)
                  +v_63 = ScopedState{v_61}
                  v_65 = v_60
                  {ArenaResult{v_65, v_63} : ArenaResult<ScopedState>}
            case _:
              v_50000314 = span_file(v_13)
              v_50000315 = Diagnostic{v_50000314, v_13, String.append("duplicate declaration: ", v_4), "a fresh declaration name", "an existing definition"}
              v_50000316 = ScopedStateFailure{v_50000315}
              {ArenaResult{v_1, v_50000316} : ArenaResult<ScopedState>}
        case _:
          v_50000317 = span_file(v_13)
          v_50000318 = Diagnostic{v_50000317, v_13, String.append("duplicate declaration: ", v_4), "a fresh declaration name", "an existing definition"}
          v_50000319 = ScopedStateFailure{v_50000318}
          {ArenaResult{v_1, v_50000319} : ArenaResult<ScopedState>}
    case _:
      v_50000320 = span_file(v_13)
      v_50000321 = Diagnostic{v_50000320, v_13, String.append("duplicate declaration: ", v_4), "a fresh declaration name", "an existing definition"}
      v_50000322 = ScopedStateFailure{v_50000321}
      {ArenaResult{v_1, v_50000322} : ArenaResult<ScopedState>}

def store_definition_result(v_1: ArenaStore, v_3: Maybe<&2, Scope.ArenaGlobal>, v_5: String, v_7: String, v_9: U32, v_11: U32, v_12: Scope.ArenaGlobalScope, v_13: Scope.ArenaGlobalScope, v_14: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_3:
    case None{}:
      v_50000323 = canonical_key(v_7, v_5)
      ArenaResult{v_22, +v_23} = arena_publish_global(v_1, Scope.ArenaGlobal{v_50000323, v_7, v_5, v_9, IR.SomeTerm{v_11}, Scope.GlobalDefinition{}})
      ArenaResult{v_27, +v_28} = global_scope_prepend(v_22, v_23, v_12)
      {ArenaResult{v_27, ScopedState{v_28}} : ArenaResult<ScopedState>}
    case Some{+v_30}:
      v_32 = v_30
      ArenaResult{v_36, +v_37} = store_definition_declared(v_1, v_32, v_5, v_7, v_9, v_11, v_12, v_13, v_14)
      {ArenaResult{v_36, v_37} : ArenaResult<ScopedState>}

def store_definition(v_20041285: ArenaStore, v_1: String, v_3: String, v_4: U32, v_5: U32, v_6: Scope.ArenaGlobalScope, v_7: Scope.ArenaGlobalScope, v_8: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  ArenaResult{v_20041286, +v_20041287} = canonicalize_term(v_20041285, v_4, v_7)
  v_12 = v_20041287
  ArenaResult{v_20041288, +v_20041289} = canonicalize_term(v_20041286, v_5, v_7)
  v_15 = v_20041289
  ArenaResult{v_20041290, +v_20041291} = store_definition_result(v_20041288, Scope.lookup(canonical_key(v_3, v_1), v_6), v_1, v_3, v_12, v_15, v_6, v_7, v_8)
  {ArenaResult{v_20041290, v_20041291} : ArenaResult<ScopedState>}

def check_definition_declared_type(v_1: ArenaStore, v_3: Inference, v_5: String, v_7: U32, v_9: U32, v_11: U32, v_13: U32, v_15: String, v_16: Scope.ArenaGlobalScope, v_17: Scope.ArenaGlobalScope, v_18: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_3:
    case Inferred{+v_24, +v_25}:
      ArenaResult{v_29, +v_30} = arena_get_node(v_1, v_25)
      match v_30:
        case Arena.TermType{+v_33, +v_34}:
          ArenaResult{v_38, +v_39} = fits_term(v_29, v_13, v_9, v_17)
          +v_41 = v_39
          match v_41:
            case False{}:
              v_50000324 = span_file(v_18)
              v_50000325 = Diagnostic{v_50000324, v_18, String.append("definition body has the wrong type: ", v_5), "the declared result type", "an incompatible inferred type"}
              +v_44 = ScopedStateFailure{v_50000325}
              v_46 = v_38
              {ArenaResult{v_46, v_44} : ArenaResult<ScopedState>}
            case True{}:
              ArenaResult{v_51, +v_52} = store_definition(v_38, v_5, v_15, v_7, v_11, v_16, v_17, v_18)
              +v_54 = v_52
              v_56 = v_51
              {ArenaResult{v_56, v_54} : ArenaResult<ScopedState>}
        case _:
          v_50000326 = span_file(v_18)
          v_50000327 = Diagnostic{v_50000326, v_18, "definition signature is not a type", "a type", "a non-type"}
          v_50000328 = ScopedStateFailure{v_50000327}
          {ArenaResult{v_29, v_50000328} : ArenaResult<ScopedState>}
    case InferenceFailure{+v_62}:
      v_64 = v_62
      {ArenaResult{v_1, ScopedStateFailure{v_64}} : ArenaResult<ScopedState>}

def check_definition_inferred_type(v_1: ArenaStore, v_3: Inference, v_5: String, v_7: U32, v_9: U32, v_11: String, v_12: Scope.ArenaGlobalScope, v_13: Scope.ArenaGlobalScope, v_14: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_3:
    case Inferred{+v_20, +v_21}:
      ArenaResult{v_25, +v_26} = arena_get_node(v_1, v_21)
      match v_26:
        case Arena.TermType{+v_29, +v_30}:
          ArenaResult{v_34, +v_35} = store_definition(v_25, v_5, v_11, v_7, v_9, v_12, v_13, v_14)
          {ArenaResult{v_34, v_35} : ArenaResult<ScopedState>}
        case _:
          v_50000329 = span_file(v_14)
          v_50000330 = Diagnostic{v_50000329, v_14, "inferred definition signature is not a type", "a type", "a non-type"}
          v_50000331 = ScopedStateFailure{v_50000330}
          {ArenaResult{v_25, v_50000331} : ArenaResult<ScopedState>}
    case InferenceFailure{+v_40}:
      v_42 = v_40
      {ArenaResult{v_1, ScopedStateFailure{v_42}} : ArenaResult<ScopedState>}

def check_definition_finish(v_20041323: ArenaStore, v_0: IR.OptionalTerm, v_2: String, v_4: IR.Words, v_5: U32, v_6: U32, v_8: String, v_9: Scope.ArenaGlobalScope, v_10: Scope.ArenaGlobalScope, v_11: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_0:
    case IR.SomeTerm{+v_20041324}:
      v_14 = v_20041324
      ArenaResult{v_20041325, +v_20041326} = binders_type(v_20041323, v_4, v_14)
      v_17 = v_20041326
      ArenaResult{v_20041327, +v_20041328} = infer(v_20041325, v_17, [], v_10)
      ArenaResult{v_20041329, +v_20041330} = binders_lambda(v_20041327, v_4, v_5)
      ArenaResult{v_20041331, +v_20041332} = check_definition_declared_type(v_20041329, v_20041328, v_2, v_17, v_14, v_20041330, v_6, v_8, v_9, v_10, v_11)
      {ArenaResult{v_20041331, v_20041332} : ArenaResult<ScopedState>}
    case IR.NoTerm{}:
      ArenaResult{v_20041333, +v_20041334} = binders_type(v_20041323, v_4, v_6)
      v_23 = v_20041334
      ArenaResult{v_20041335, +v_20041336} = infer(v_20041333, v_23, [], v_10)
      ArenaResult{v_20041337, +v_20041338} = binders_lambda(v_20041335, v_4, v_5)
      ArenaResult{v_20041339, +v_20041340} = check_definition_inferred_type(v_20041337, v_20041336, v_2, v_23, v_20041338, v_8, v_9, v_10, v_11)
      {ArenaResult{v_20041339, v_20041340} : ArenaResult<ScopedState>}

def check_definition_uses_result(v_20041341: ArenaStore, v_2: Maybe<&2, Diagnostic>, v_3: IR.OptionalTerm, v_5: String, v_7: IR.Words, v_8: U32, v_9: U32, v_10: U32, v_12: Bool, v_14: String, v_15: Scope.ArenaGlobalScope, v_16: Scope.ArenaGlobalScope, v_17: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_2:
    case Some{+v_20041342}:
      v_20 = v_20041342
      {ArenaResult{v_20041341, ScopedStateFailure{v_20}} : ArenaResult<ScopedState>}
    case None{}:
      ArenaResult{v_20041343, +v_20041344} = check_definition_finish(v_20041341, v_3, v_5, v_7, v_9, v_10, v_14, v_15, v_16, v_17)
      {ArenaResult{v_20041343, v_20041344} : ArenaResult<ScopedState>}

def check_definition_term_result(v_20041345: ArenaStore, v_1: Inference, v_2: IR.OptionalTerm, v_4: String, v_6: IR.Words, v_7: U32, v_9: Bool, v_11: String, v_12: Scope.ArenaGlobalScope, v_13: Scope.ArenaGlobalScope, v_14: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_1:
    case Inferred{+v_20041346, +v_20041347}:
      v_18 = v_20041346
      v_19 = v_20041347
      v_22 = definition_expected_body(v_2, v_19)
      ArenaResult{v_20041348, +v_20041349} = validate_definition_uses(v_20041345, v_9, v_4, v_6, v_7, v_22, v_14, v_13, True{})
      ArenaResult{v_20041350, +v_20041351} = check_definition_uses_result(v_20041348, v_20041349, v_2, v_4, v_6, v_7, v_18, v_19, v_9, v_11, v_12, v_13, v_14)
      {ArenaResult{v_20041350, v_20041351} : ArenaResult<ScopedState>}
    case InferenceFailure{+v_20041352}:
      v_26 = v_20041352
      {ArenaResult{v_20041345, ScopedStateFailure{v_26}} : ArenaResult<ScopedState>}

def definition_expected_body(v_0: IR.OptionalTerm, v_1: U32) -> U32:
  match v_0:
    case IR.SomeTerm{+v_20041353}:
      v_3 = v_20041353
      v_3
    case IR.NoTerm{}:
      v_1

def check_definition_body(v_20041354: ArenaStore, v_0: IR.DefBody, v_2: String, v_4: IR.Words, v_5: IR.OptionalTerm, v_7: Bool, v_9: String, v_10: Scope.ArenaGlobalScope, v_11: Scope.ArenaGlobalScope, v_12: Ast.SourceSpan) -> ArenaResult<ScopedState>:
  match v_0:
    case IR.DefTerm{+v_20041355}:
      v_15 = v_20041355
      ArenaResult{v_20041356, +v_20041357} = definition_visible_self(v_20041354, v_5, v_2, v_9, v_4, v_11)
      v_18 = v_20041357
      ArenaResult{v_20041358, +v_20041359} = definition_term_inference(v_20041356, v_5, v_15, v_4, v_18)
      v_21 = v_20041359
      ArenaResult{v_20041360, +v_20041361} = check_definition_term_result(v_20041358, v_21, v_5, v_2, v_4, v_15, v_7, v_9, v_10, v_18, v_12)
      {ArenaResult{v_20041360, v_20041361} : ArenaResult<ScopedState>}
    case IR.DefImports{+v_20041362}:
      v_24 = v_20041362
      ArenaResult{v_20041363, +v_20041364} = check_import_definition(v_20041354, v_2, v_4, v_5, v_24, v_9, v_10, v_11, v_12)
      {ArenaResult{v_20041363, v_20041364} : ArenaResult<ScopedState>}

def definition_visible_self(v_1: ArenaStore, v_2: IR.OptionalTerm, v_4: String, v_6: String, v_7: IR.Words, v_8: Scope.ArenaGlobalScope) -> ArenaResult<Scope.ArenaGlobalScope>:
  match v_2:
    case IR.SomeTerm{+v_12}:
      v_14 = v_12
      ArenaResult{v_18, +v_19} = binders_type(v_1, v_7, v_14)
      v_21 = v_19
      ArenaResult{v_25, +v_26} = arena_publish_global(v_18, Scope.ArenaGlobal{v_4, v_6, v_4, v_21, IR.NoTerm{}, Scope.GlobalDefinition{}})
      v_50000332 = canonical_key(v_6, v_4)
      ArenaResult{v_31, +v_32} = arena_publish_global(v_25, Scope.ArenaGlobal{v_50000332, v_6, v_4, v_21, IR.NoTerm{}, Scope.GlobalDefinition{}})
      ArenaResult{v_36, +v_37} = global_scope_prepend(v_31, v_32, v_8)
      ArenaResult{v_41, +v_42} = global_scope_prepend(v_36, v_26, v_37)
      {ArenaResult{v_41, v_42} : ArenaResult<Scope.ArenaGlobalScope>}
    case IR.NoTerm{}:
      {ArenaResult{v_1, v_8} : ArenaResult<Scope.ArenaGlobalScope>}

def definition_term_inference_uncached(v_20041377: ArenaStore, v_0: IR.OptionalTerm, v_1: U32, v_3: IR.Words, v_4: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  match v_0:
    case IR.SomeTerm{+v_20041378}:
      v_7 = v_20041378
      ArenaResult{v_20041379, +v_20041380} = binders_env(v_20041377, v_3, [])
      ArenaResult{v_20041381, +v_20041382} = check_term(v_20041379, v_1, v_20041380, v_4, v_7)
      {ArenaResult{v_20041381, v_20041382} : ArenaResult<Inference>}
    case IR.NoTerm{}:
      ArenaResult{v_20041383, +v_20041384} = binders_env(v_20041377, v_3, [])
      ArenaResult{v_20041385, +v_20041386} = infer(v_20041383, v_1, v_20041384, v_4)
      {ArenaResult{v_20041385, v_20041386} : ArenaResult<Inference>}

def scalar_frame_finish(result: ArenaResult<Inference>) -> ArenaResult<Inference>:
  match result:
    case ArenaResult{store, value}:
      {ArenaResult{scalar_frame_store(store, Arena.SubstMemoEmpty{}), value} : ArenaResult<Inference>}

def definition_term_inference(store: ArenaStore, ty: IR.OptionalTerm, term: U32, binders: IR.Words, +scope: Scope.ArenaGlobalScope) -> ArenaResult<Inference>:
  scalar_frame_finish(definition_term_inference_uncached(scalar_frame_store(store, Arena.ScalarSchemaOpen{scope}), ty, term, binders, scope))

def check_definition(v_20041387: ArenaStore, v_0: IR.Definition, v_2: String, v_3: Scope.ArenaGlobalScope, v_4: Scope.ArenaGlobalScope) -> ArenaResult<ScopedState>:
  match v_0:
    case IR.Definition{+v_20041388, +v_20041389, +v_20041390, +v_20041391, +v_20041392, +v_20041393}:
      v_12 = v_20041388
      v_13 = v_20041389
      v_14 = v_20041390
      v_15 = v_20041391
      v_16 = v_20041392
      v_17 = v_20041393
      ArenaResult{v_20041394, +v_20041395} = check_definition_body(v_20041387, v_15, v_12, v_13, v_14, v_16, v_2, v_3, definition_scope(v_16, v_4), v_17)
      {ArenaResult{v_20041394, v_20041395} : ArenaResult<ScopedState>}

def law_body_type(v_20041396: ArenaStore, v_0: U32) -> ArenaResult<U32>:
  ArenaResult{v_20041397, +v_20041398} = arena_get_node(v_20041396, v_0)
  match v_20041398:
    case Arena.BodyReply{+v_20041401, +v_20041402}:
      v_3 = v_20041401
      {ArenaResult{v_20041397, v_3} : ArenaResult<U32>}
    case _:
      {ArenaResult{v_20041397, v_0} : ArenaResult<U32>}

def law_type(v_20041404: ArenaStore, v_1: List<&2, IR.Clause>, v_2: U32) -> ArenaResult<U32>:
  match v_1:
    case []:
      ArenaResult{v_20041405, +v_20041406} = law_body_type(v_20041404, v_2)
      {ArenaResult{v_20041405, v_20041406} : ArenaResult<U32>}
    case +v_20041407 <> +v_20041408:
      +v_6 = v_20041407
      v_7 = v_20041408
      match v_6:
        case IR.ClauseFor{+v_20041409, +v_20041410, +v_20041411, +v_20041412, +v_20041413, +v_20041414}:
          v_14 = v_20041409
          v_15 = v_20041410
          v_16 = v_20041411
          v_17 = v_20041412
          v_18 = v_20041413
          v_19 = v_20041414
          ArenaResult{v_20041415, +v_20041416} = law_domain(v_20041404, v_18, v_17, v_16, v_19)
          v_22 = v_20041416
          ArenaResult{v_20041417, +v_20041418} = law_type(v_20041415, v_7, v_2)
          v_25 = v_20041418
          ArenaResult{v_20041419, +v_20041420} = law_quantifier(v_20041417, v_14, v_15, v_16, v_22, v_25, v_19)
          {ArenaResult{v_20041419, v_20041420} : ArenaResult<U32>}

def law_domain(v_20041421: ArenaStore, v_1: Maybe<&2, U32>, v_2: U32, v_4: String, v_5: Ast.SourceSpan) -> ArenaResult<U32>:
  match v_1:
    case None{}:
      {ArenaResult{v_20041421, v_2} : ArenaResult<U32>}
    case Some{+v_20041422}:
      v_7 = v_20041422
      ArenaResult{v_20041423, +v_20041424} = arena_name(v_20041421, "Exists")
      ArenaResult{v_20041425, +v_20041426} = arena_put_node(v_20041423, Arena.TermRef{v_20041424, v_5})
      ArenaResult{v_20041427, +v_20041428} = arena_put_node(v_20041425, Arena.TermApp{v_20041426, v_2, v_5})
      ArenaResult{v_20041429, +v_20041430} = arena_name(v_20041427, v_4)
      ArenaResult{v_20041431, +v_20041432} = arena_put_node(v_20041429, Arena.TermLam{None{}, v_20041430, 0n, v_7, v_5})
      ArenaResult{v_20041433, +v_20041434} = arena_put_node(v_20041431, Arena.TermApp{v_20041428, v_20041432, v_5})
      {ArenaResult{v_20041433, v_20041434} : ArenaResult<U32>}

def law_quantifier(v_20041435: ArenaStore, v_1: Bool, v_2: Ast.Quantity, v_4: String, v_5: U32, v_6: U32, v_7: Ast.SourceSpan) -> ArenaResult<U32>:
  match v_1:
    case True{}:
      ArenaResult{v_20041436, +v_20041437} = arena_name(v_20041435, v_4)
      ArenaResult{v_20041438, +v_20041439} = arena_put_node(v_20041436, Arena.TermAll{v_2, v_20041437, 0n, v_5, v_6, v_7})
      {ArenaResult{v_20041438, v_20041439} : ArenaResult<U32>}
    case False{}:
      ArenaResult{v_20041440, +v_20041441} = arena_name(v_20041435, "Exists")
      ArenaResult{v_20041442, +v_20041443} = arena_put_node(v_20041440, Arena.TermRef{v_20041441, v_7})
      ArenaResult{v_20041444, +v_20041445} = arena_put_node(v_20041442, Arena.TermApp{v_20041443, v_5, v_7})
      ArenaResult{v_20041446, +v_20041447} = arena_name(v_20041444, v_4)
      ArenaResult{v_20041448, +v_20041449} = arena_put_node(v_20041446, Arena.TermLam{None{}, v_20041447, 0n, v_6, v_7})
      ArenaResult{v_20041450, +v_20041451} = arena_put_node(v_20041448, Arena.TermApp{v_20041445, v_20041449, v_7})
      {ArenaResult{v_20041450, v_20041451} : ArenaResult<U32>}

def check_law_result(v_1: ArenaStore, v_3: Inference, v_5: String, v_7: U32, v_9: String, v_10: Scope.ArenaGlobalScope, v_11: Scope.ArenaGlobalScope) -> ArenaResult<ScopedState>:
  match v_3:
    case Inferred{+v_17, +v_18}:
      ArenaResult{v_22, +v_23} = canonicalize_term(v_1, v_7, v_11)
      v_50000333 = canonical_key(v_9, v_5)
      ArenaResult{v_28, +v_29} = arena_publish_global(v_22, Scope.ArenaGlobal{v_50000333, v_9, v_5, v_23, IR.NoTerm{}, Scope.GlobalDefinition{}})
      ArenaResult{v_33, +v_34} = global_scope_prepend(v_28, v_29, v_10)
      {ArenaResult{v_33, ScopedState{v_34}} : ArenaResult<ScopedState>}
    case InferenceFailure{+v_36}:
      v_38 = v_36
      {ArenaResult{v_1, ScopedStateFailure{v_38}} : ArenaResult<ScopedState>}

def check_law(v_20041462: ArenaStore, v_0: IR.LawDecl, v_2: String, v_3: Scope.ArenaGlobalScope, v_4: Scope.ArenaGlobalScope) -> ArenaResult<ScopedState>:
  match v_0:
    case IR.LawDecl{+v_20041463, +v_20041464, +v_20041465, +v_20041466}:
      v_10 = v_20041463
      v_11 = v_20041464
      v_12 = v_20041465
      v_13 = v_20041466
      ArenaResult{v_20041467, +v_20041468} = law_type(v_20041462, v_11, v_12)
      v_16 = v_20041468
      ArenaResult{v_20041469, +v_20041470} = arena_put_node(v_20041467, Arena.TermQuantity{Ast.QOne{}, v_13})
      ArenaResult{v_20041471, +v_20041472} = arena_put_node(v_20041469, Arena.TermType{v_20041470, v_13})
      ArenaResult{v_20041473, +v_20041474} = check_term(v_20041471, v_16, [], v_4, v_20041472)
      ArenaResult{v_20041475, +v_20041476} = check_law_result(v_20041473, v_20041474, v_10, v_16, v_2, v_3, v_4)
      {ArenaResult{v_20041475, v_20041476} : ArenaResult<ScopedState>}

def has_string(v_20041477: ArenaStore, v_1: String, v_4: IR.Names) -> ArenaResult<Bool>:
  ArenaResult{v_20041478, +v_20041479} = arena_names_view(v_20041477, v_4)
  match v_20041479:
    case IR.NameNil{}:
      {ArenaResult{v_20041478, False{}} : ArenaResult<Bool>}
    case IR.NameCons{+v_20041480, +v_20041481}:
      +v_8 = v_20041480
      v_9 = v_20041481
      ArenaResult{v_20041482, +v_20041483} = has_string(v_20041478, v_1, v_9)
      {ArenaResult{v_20041482, Bool.or(String.eq(v_1, v_8), v_20041483)} : ArenaResult<Bool>}

def law_signature_scope(v_1: List<&2, Scope.ArenaGlobal>) -> List<&2, Scope.ArenaGlobal>:
  match v_1:
    case []:
      []
    case +v_5 <> +v_6:
      +v_8 = v_5
      v_10 = v_6
      match v_8:
        case Scope.ArenaGlobal{+v_17, +v_18, +v_19, +v_20, +v_21, +v_22}:
          v_24 = v_17
          v_26 = v_18
          v_28 = v_19
          v_30 = v_20
          v_32 = v_21
          v_34 = v_22
          v_50000334 = canonical_key(v_26, v_28)
          v_50000335 = Scope.ArenaGlobal{v_50000334, "", v_24, v_30, v_32, v_34}
          v_50000336 = law_signature_scope(v_10)
          v_50000335 <> v_50000336

def completion_binder_fits(v_1: ArenaStore, v_2: Ast.Quantity, v_4: U32, v_5: Ast.Quantity, v_7: U32, v_8: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_2:
    case Ast.QZero{}:
      ArenaResult{v_15, +v_16} = arena_get_node(v_1, v_4)
      match v_16:
        case Arena.TermQuant{}:
          {ArenaResult{v_15, True{}} : ArenaResult<Bool>}
        case _:
          ArenaResult{v_22, +v_23} = equal_term(v_15, v_4, v_7, v_8)
          v_50000337 = Bool.and(same_quantity(v_2, v_5), v_23)
          {ArenaResult{v_22, v_50000337} : ArenaResult<Bool>}
    case _:
      ArenaResult{v_30, +v_31} = equal_term(v_1, v_4, v_7, v_8)
      v_50000338 = Bool.and(same_quantity(v_2, v_5), v_31)
      {ArenaResult{v_30, v_50000338} : ArenaResult<Bool>}

def inherit_law_result(v_1: ArenaStore, v_2: IR.OptionalTerm, v_4: U32, v_6: String, v_7: IR.Words, v_8: IR.DefBody, v_10: Bool, v_11: Ast.SourceSpan, v_12: Scope.ArenaGlobalScope) -> ArenaResult<DefinitionElaboration>:
  match v_2:
    case IR.NoTerm{}:
      ArenaResult{v_19, +v_20} = arena_words_reverse(v_1, v_7)
      {ArenaResult{v_19, DefinitionElaborated{IR.Definition{v_6, v_20, IR.SomeTerm{v_4}, v_8, v_10, v_11}}} : ArenaResult<DefinitionElaboration>}
    case IR.SomeTerm{+v_22}:
      v_24 = v_22
      ArenaResult{v_28, +v_29} = equal_term(v_1, v_24, v_4, v_12)
      +v_31 = v_29
      match v_31:
        case False{}:
          v_50000339 = span_file(v_11)
          v_50000340 = Diagnostic{v_50000339, v_11, String.append("completion result differs from its law: ", v_6), "the declared law result", "an incompatible result annotation"}
          +v_34 = DefinitionElaborationFailure{v_50000340}
          v_36 = v_28
          {ArenaResult{v_36, v_34} : ArenaResult<DefinitionElaboration>}
        case True{}:
          ArenaResult{v_41, +v_42} = arena_words_reverse(v_28, v_7)
          +v_44 = DefinitionElaborated{IR.Definition{v_6, v_42, IR.SomeTerm{v_4}, v_8, v_10, v_11}}
          v_46 = v_41
          {ArenaResult{v_46, v_44} : ArenaResult<DefinitionElaboration>}

def inherit_law_binder_view(v_1: ArenaStore, v_3: U32, v_5: U32, v_6: IR.Words, v_7: IR.Words, v_9: Nat, v_10: IR.OptionalTerm, v_12: String, v_13: IR.DefBody, v_15: Bool, v_16: Ast.SourceSpan, v_17: Scope.ArenaGlobalScope) -> ArenaResult<DefinitionElaboration>:
  ArenaResult{v_24, +v_25} = arena_get_node(v_1, v_3)
  match v_25:
    case Arena.TermAll{+v_32, +v_33, +v_34, +v_35, +v_36, +v_37}:
      ArenaResult{v_41, +v_42} = arena_get_binder(v_24, v_5)
      match v_42:
        case Arena.Binder{+v_48, +v_49, +v_50, +v_51, +v_52}:
          ArenaResult{v_56, +v_57} = arena_name_text(v_41, v_49)
          +v_59 = v_57
          v_61 = v_48
          v_63 = v_59
          v_65 = v_51
          v_67 = v_52
          v_69 = v_32
          v_71 = v_35
          v_73 = v_36
          ArenaResult{v_77, +v_78} = arena_name(v_56, v_63)
          ArenaResult{v_82, +v_83} = arena_put_binder(v_77, Arena.Binder{v_69, v_78, v_9, v_71, v_67})
          v_85 = v_83
          ArenaResult{v_89, +v_90} = arena_name(v_82, v_63)
          ArenaResult{v_94, +v_95} = arena_put_node(v_89, Arena.TermVar{v_90, 0n, v_67})
          ArenaResult{v_99, +v_100} = replace_free_term(v_94, v_73, 0n, v_95, 0n)
          v_102 = v_100
          ArenaResult{v_106, +v_107} = completion_binder_fits(v_99, v_61, v_65, v_69, v_71, v_17)
          +v_109 = v_107
          match v_109:
            case False{}:
              v_50000341 = span_file(v_67)
              v_50000342 = Diagnostic{v_50000341, v_67, String.append("completion binder differs from its law: ", v_63), "the declared law quantity and domain", "an incompatible binder annotation"}
              +v_112 = DefinitionElaborationFailure{v_50000342}
              v_114 = v_106
              {ArenaResult{v_114, v_112} : ArenaResult<DefinitionElaboration>}
            case True{}:
              ArenaResult{v_119, +v_120} = arena_words_cons(v_106, v_85, v_7)
              ArenaResult{v_124, +v_125} = inherit_law_binders(v_119, v_6, v_102, v_120, Nat.add(v_9, 1n), v_10, v_12, v_13, v_15, v_16, v_17)
              +v_127 = v_125
              v_129 = v_124
              {ArenaResult{v_129, v_127} : ArenaResult<DefinitionElaboration>}
        case Arena.TemplateBinder{+v_135, +v_136, +v_137, +v_138}:
          v_140 = v_138
          v_50000343 = span_file(v_140)
          v_50000344 = Diagnostic{v_50000343, v_140, "law completion cannot introduce a template binder", "a law parameter name", "a compile-time template binder"}
          v_50000345 = DefinitionElaborationFailure{v_50000344}
          {ArenaResult{v_41, v_50000345} : ArenaResult<DefinitionElaboration>}
    case _:
      ArenaResult{v_147, +v_148} = arena_get_binder(v_24, v_5)
      match v_148:
        case Arena.TemplateBinder{+v_153, +v_154, +v_155, +v_156}:
          v_158 = v_156
          v_50000346 = span_file(v_158)
          v_50000347 = Diagnostic{v_50000346, v_158, "law completion cannot introduce a template binder", "a law parameter name", "a compile-time template binder"}
          v_50000348 = DefinitionElaborationFailure{v_50000347}
          {ArenaResult{v_147, v_50000348} : ArenaResult<DefinitionElaboration>}
        case Arena.Binder{+v_165, +v_166, +v_167, +v_168, +v_169}:
          ArenaResult{v_173, +v_174} = arena_name_text(v_147, v_166)
          +v_176 = v_174
          v_178 = v_176
          v_180 = v_169
          v_50000349 = span_file(v_180)
          v_50000350 = Diagnostic{v_50000349, v_180, String.append("law completion has too many parameters: ", v_12), "a remaining law parameter", v_178}
          v_50000351 = DefinitionElaborationFailure{v_50000350}
          {ArenaResult{v_173, v_50000351} : ArenaResult<DefinitionElaboration>}

def inherit_law_binders(v_20041584: ArenaStore, v_1: IR.Words, v_2: U32, v_4: IR.Words, v_6: Nat, v_7: IR.OptionalTerm, v_9: String, v_10: IR.DefBody, v_12: Bool, v_13: Ast.SourceSpan, v_14: Scope.ArenaGlobalScope) -> ArenaResult<DefinitionElaboration>:
  ArenaResult{v_20041585, +v_20041586} = arena_words_view(v_20041584, v_1)
  match v_20041586:
    case IR.WordNil{}:
      ArenaResult{v_20041587, +v_20041588} = inherit_law_result(v_20041585, v_7, v_2, v_9, v_4, v_10, v_12, v_13, v_14)
      {ArenaResult{v_20041587, v_20041588} : ArenaResult<DefinitionElaboration>}
    case IR.WordCons{+v_20041589, +v_20041590}:
      +v_19 = v_20041589
      v_20 = v_20041590
      ArenaResult{v_20041591, +v_20041592} = whnf(v_20041585, 64n, v_2, v_14)
      ArenaResult{v_20041593, +v_20041594} = inherit_law_binder_view(v_20041591, v_20041592, v_19, v_20, v_4, v_6, v_7, v_9, v_10, v_12, v_13, v_14)
      {ArenaResult{v_20041593, v_20041594} : ArenaResult<DefinitionElaboration>}

def inherit_law_definition(v_20041595: ArenaStore, v_0: IR.Definition, v_1: U32, v_2: Scope.ArenaGlobalScope) -> ArenaResult<DefinitionElaboration>:
  match v_0:
    case IR.Definition{+v_20041596, +v_20041597, +v_20041598, +v_20041599, +v_20041600, +v_20041601}:
      v_10 = v_20041596
      v_11 = v_20041597
      v_12 = v_20041598
      v_13 = v_20041599
      v_14 = v_20041600
      v_15 = v_20041601
      ArenaResult{v_20041602, +v_20041603} = global_scope(v_20041595, law_signature_scope(global_scope_entries(v_2)))
      ArenaResult{v_20041604, +v_20041605} = canonicalize_term(v_20041602, v_1, v_20041603)
      v_21 = v_20041605
      ArenaResult{v_20041606, +v_20041607} = inherit_law_binders(v_20041604, v_11, v_21, IR.Words{0, 0}, 0n, v_12, v_10, v_13, v_14, v_15, v_2)
      {ArenaResult{v_20041606, v_20041607} : ArenaResult<DefinitionElaboration>}

def elaborate_definition_global(v_1: ArenaStore, v_2: Scope.ArenaGlobal, v_3: IR.Definition, v_4: Scope.ArenaGlobalScope, v_6: String, v_7: Ast.SourceSpan, v_8: IR.Names) -> ArenaResult<DefinitionElaboration>:
  match v_2:
    case Scope.ArenaGlobal{+v_18, +v_19, +v_20, +v_21, +v_22, +v_23}:
      match v_22:
        case IR.NoTerm{}:
          match v_23:
            case Scope.GlobalDefinition{}:
              v_25 = v_21
              ArenaResult{v_29, +v_30} = has_string(v_1, v_6, v_8)
              +v_32 = v_30
              match v_32:
                case False{}:
                  v_50000352 = span_file(v_7)
                  v_50000353 = Diagnostic{v_50000352, v_7, String.append("duplicate declaration: ", v_6), "a fresh declaration name", "an existing declaration"}
                  +v_35 = DefinitionElaborationFailure{v_50000353}
                  v_37 = v_29
                  {ArenaResult{v_37, v_35} : ArenaResult<DefinitionElaboration>}
                case True{}:
                  ArenaResult{v_42, +v_43} = inherit_law_definition(v_29, v_3, v_25, v_4)
                  +v_45 = v_43
                  v_47 = v_42
                  {ArenaResult{v_47, v_45} : ArenaResult<DefinitionElaboration>}
            case _:
              v_50000354 = span_file(v_7)
              v_50000355 = Diagnostic{v_50000354, v_7, String.append("duplicate declaration: ", v_6), "a fresh declaration name", "an existing definition"}
              v_50000356 = DefinitionElaborationFailure{v_50000355}
              {ArenaResult{v_1, v_50000356} : ArenaResult<DefinitionElaboration>}
        case _:
          v_50000357 = span_file(v_7)
          v_50000358 = Diagnostic{v_50000357, v_7, String.append("duplicate declaration: ", v_6), "a fresh declaration name", "an existing definition"}
          v_50000359 = DefinitionElaborationFailure{v_50000358}
          {ArenaResult{v_1, v_50000359} : ArenaResult<DefinitionElaboration>}
    case _:
      v_50000360 = span_file(v_7)
      v_50000361 = Diagnostic{v_50000360, v_7, String.append("duplicate declaration: ", v_6), "a fresh declaration name", "an existing definition"}
      v_50000362 = DefinitionElaborationFailure{v_50000361}
      {ArenaResult{v_1, v_50000362} : ArenaResult<DefinitionElaboration>}

def elaborate_definition_result(v_20041631: ArenaStore, v_1: Maybe<&2, Scope.ArenaGlobal>, v_2: IR.Definition, v_3: Scope.ArenaGlobalScope, v_5: String, v_6: Ast.SourceSpan, v_9: IR.Names) -> ArenaResult<DefinitionElaboration>:
  match v_1:
    case None{}:
      {ArenaResult{v_20041631, DefinitionElaborated{v_2}} : ArenaResult<DefinitionElaboration>}
    case Some{+v_20041632}:
      v_12 = v_20041632
      ArenaResult{v_20041633, +v_20041634} = elaborate_definition_global(v_20041631, v_12, v_2, v_3, v_5, v_6, v_9)
      {ArenaResult{v_20041633, v_20041634} : ArenaResult<DefinitionElaboration>}

def elaborate_definition(v_20041635: ArenaStore, v_0: IR.Definition, v_2: String, v_3: Scope.ArenaGlobalScope, v_4: Scope.ArenaGlobalScope, v_6: String, v_7: Ast.SourceSpan, v_10: IR.Names) -> ArenaResult<DefinitionElaboration>:
  ArenaResult{v_20041636, +v_20041637} = elaborate_definition_result(v_20041635, Scope.lookup(canonical_key(v_2, v_6), v_3), v_0, v_4, v_6, v_7, v_10)
  {ArenaResult{v_20041636, v_20041637} : ArenaResult<DefinitionElaboration>}

def check_declarations_prepend(v_1: Declarations, v_2: IR.TopLevel) -> Declarations:
  match v_1:
    case DeclarationsChecked{+v_20041638, +v_20041639}:
      v_6 = v_20041638
      v_7 = v_20041639
      DeclarationsChecked{v_6, v_2 <> v_7}
    case DeclarationsFailure{+v_20041640}:
      v_9 = v_20041640
      DeclarationsFailure{v_9}

def check_declarations_step(v_1: ArenaStore, v_3: ScopedState, v_4: IR.TopLevel, v_6: List<&2, IR.TopLevel>, +v_8: String, +v_10: List<&2, Ast.ModuleImport>, v_11: IR.Names, v_13: Nat, v_14: Scope.ArenaGlobalScope) -> ArenaResult<Declarations>:
  match v_3:
    case ScopedState{+v_19}:
      +v_21 = v_19
      ArenaResult{v_25, +v_26} = arena_publish_top_level(v_1, v_4)
      # The open-law tape is carried across declarations, so it must survive rewind
      # just like the published declaration and scope entries.
      ArenaResult{retained_store, +retained_laws} = arena_publish_names(v_25, v_11)
      ArenaResult{v_30, +v_31} = arena_release(retained_store)
      +v_32 = v_26
      ArenaResult{v_36, +v_37} = declaration_visible_scope(v_30, v_21, v_13, v_14)
      v_39 = v_37
      ArenaResult{v_43, +v_44} = check_declarations(v_36, v_6, v_8, v_10, v_21, retained_laws, v_39)
      v_50000363 = check_declarations_prepend(v_44, v_32)
      {ArenaResult{v_43, v_50000363} : ArenaResult<Declarations>}
    case ScopedStateFailure{+v_47}:
      v_49 = v_47
      {ArenaResult{v_1, DeclarationsFailure{v_49}} : ArenaResult<Declarations>}

def check_declarations_definition(v_20041652: ArenaStore, v_1: DefinitionElaboration, v_3: List<&2, IR.TopLevel>, v_5: String, v_7: List<&2, Ast.ModuleImport>, v_8: Scope.ArenaGlobalScope, v_9: Scope.ArenaGlobalScope, v_12: IR.Names) -> ArenaResult<Declarations>:
  match v_1:
    case DefinitionElaborated{+v_20041653}:
      v_15 = v_20041653
      ArenaResult{v_20041654, +v_20041655} = check_definition(v_20041652, v_15, v_5, v_8, v_9)
      ArenaResult{v_20041656, +v_20041657} = check_declarations_step(v_20041654, v_20041655, IR.DefTop{v_15}, v_3, v_5, v_7, v_12, global_scope_size(v_8), v_9)
      {ArenaResult{v_20041656, v_20041657} : ArenaResult<Declarations>}
    case DefinitionElaborationFailure{+v_20041658}:
      v_20 = v_20041658
      {ArenaResult{v_20041652, DeclarationsFailure{v_20}} : ArenaResult<Declarations>}

def check_declarations_type_result(v_1: ArenaStore, v_3: Maybe<&2, Scope.ArenaGlobal>, v_4: IR.TypeDecl, v_6: List<&2, IR.TopLevel>, v_8: String, v_10: List<&2, Ast.ModuleImport>, v_11: Scope.ArenaGlobalScope, v_12: Scope.ArenaGlobalScope, v_13: IR.Names, v_15: String, v_16: Ast.SourceSpan) -> ArenaResult<Declarations>:
  match v_3:
    case Some{+v_21}:
      v_50000364 = span_file(v_16)
      v_50000365 = Diagnostic{v_50000364, v_16, String.append("duplicate declaration: ", v_15), "a fresh datatype name", "an existing declaration"}
      v_50000366 = DeclarationsFailure{v_50000365}
      {ArenaResult{v_1, v_50000366} : ArenaResult<Declarations>}
    case None{}:
      ArenaResult{v_26, +v_27} = check_type_decl(v_1, v_4, v_8, v_11, v_12)
      ArenaResult{v_32, +v_33} = check_declarations_step(v_26, v_27, IR.TypeTop{v_4}, v_6, v_8, v_10, v_13, global_scope_size(v_11), v_12)
      {ArenaResult{v_32, v_33} : ArenaResult<Declarations>}

def check_declarations_law_result(v_1: ArenaStore, v_3: Maybe<&2, Scope.ArenaGlobal>, v_4: IR.LawDecl, v_6: List<&2, IR.TopLevel>, v_8: String, v_10: List<&2, Ast.ModuleImport>, v_11: Scope.ArenaGlobalScope, v_12: Scope.ArenaGlobalScope, v_13: IR.Names, v_15: String, v_16: Ast.SourceSpan) -> ArenaResult<Declarations>:
  match v_3:
    case Some{+v_21}:
      v_50000367 = span_file(v_16)
      v_50000368 = Diagnostic{v_50000367, v_16, String.append("duplicate declaration: ", v_15), "a fresh law name", "an existing declaration"}
      v_50000369 = DeclarationsFailure{v_50000368}
      {ArenaResult{v_1, v_50000369} : ArenaResult<Declarations>}
    case None{}:
      ArenaResult{v_26, +v_27} = check_law(v_1, v_4, v_8, v_11, v_12)
      ArenaResult{v_31, +v_32} = arena_names_cons(v_26, v_15, v_13)
      ArenaResult{v_37, +v_38} = check_declarations_step(v_31, v_27, IR.LawTop{v_4}, v_6, v_8, v_10, v_32, global_scope_size(v_11), v_12)
      {ArenaResult{v_37, v_38} : ArenaResult<Declarations>}

def check_declarations(v_1: ArenaStore, v_3: List<&2, IR.TopLevel>, v_5: String, v_7: List<&2, Ast.ModuleImport>, v_8: Scope.ArenaGlobalScope, v_9: IR.Names, v_10: Scope.ArenaGlobalScope) -> ArenaResult<Declarations>:
  match v_3:
    case []:
      v_50000370 = global_scope_entries(v_8)
      v_50000371 = DeclarationsChecked{v_50000370, []}
      {ArenaResult{v_1, v_50000371} : ArenaResult<Declarations>}
    case +v_17 <> +v_18:
      +v_20 = v_17
      v_22 = v_18
      match v_20:
        case IR.DefTop{+v_24}:
          v_26 = v_24
          match v_26:
            case IR.Definition{+v_33, +v_34, +v_35, +v_36, +v_37, +v_38}:
              v_40 = v_33
              v_42 = v_38
              ArenaResult{v_46, +v_47} = elaborate_definition(v_1, v_26, v_5, v_8, v_10, v_40, v_42, v_9)
              ArenaResult{v_51, +v_52} = check_declarations_definition(v_46, v_47, v_22, v_5, v_7, v_8, v_10, v_9)
              {ArenaResult{v_51, v_52} : ArenaResult<Declarations>}
        case IR.TypeTop{+v_54}:
          v_56 = v_54
          match v_56:
            case IR.TypeDecl{+v_62, +v_63, +v_64, +v_65, +v_66}:
              v_68 = v_62
              v_70 = v_66
              ArenaResult{v_76, +v_77} = check_declarations_type_result(v_1, Scope.lookup(canonical_key(v_5, v_68), v_8), v_56, v_22, v_5, v_7, v_8, v_10, v_9, v_68, v_70)
              {ArenaResult{v_76, v_77} : ArenaResult<Declarations>}
        case IR.LawTop{+v_79}:
          v_81 = v_79
          match v_81:
            case IR.LawDecl{+v_86, +v_87, +v_88, +v_89}:
              v_91 = v_86
              v_93 = v_89
              ArenaResult{v_99, +v_100} = check_declarations_law_result(v_1, Scope.lookup(canonical_key(v_5, v_91), v_8), v_81, v_22, v_5, v_7, v_8, v_10, v_9, v_91, v_93)
              {ArenaResult{v_99, v_100} : ArenaResult<Declarations>}

def check_modules_result(v_1: PrivateResult, v_2: IR.LoadedModule) -> PrivateResult:
  match v_1:
    case PrivateSuccess{+v_20041702}:
      v_5 = v_20041702
      PrivateSuccess{v_2 <> v_5}
    case PrivateFailure{+v_20041703}:
      v_7 = v_20041703
      PrivateFailure{v_7}

def check_modules_declarations(v_1: ArenaStore, v_3: Declarations, v_5: String, v_7: String, v_9: List<&2, Ast.ModuleImport>, v_11: List<&2, IR.LoadedModule>) -> ArenaResult<PrivateResult>:
  match v_3:
    case DeclarationsChecked{+v_17, +v_18}:
      v_20 = v_17
      v_22 = v_18
      v_24 = IR.LoadedModule{v_5, IR.Module{v_7, v_9, v_22}}
      ArenaResult{v_28, v_29} = check_modules_private(v_1, v_11, v_20)
      v_50000372 = check_modules_result(v_29, v_24)
      {ArenaResult{v_28, v_50000372} : ArenaResult<PrivateResult>}
    case DeclarationsFailure{+v_32}:
      v_34 = v_32
      {ArenaResult{v_1, PrivateFailure{v_34}} : ArenaResult<PrivateResult>}

# Forward references use published signatures, never unchecked definition values.
# Keep these entries out of the checked declaration scope: duplicate, signature,
# body and affine validation still run once in source order.
def predeclare_definition_signatures(store: ArenaStore, declarations: List<&2, IR.TopLevel>, +namespace: String, visible: Scope.ArenaGlobalScope) -> ArenaResult<Scope.ArenaGlobalScope>:
  match declarations:
    case Nil{}:
      {ArenaResult{store, visible} : ArenaResult<Scope.ArenaGlobalScope>}
    case IR.DefTop{IR.Definition{key, binders, result, _, _, _}} <> rest:
      ArenaResult{next, scope} = definition_visible_self(store, result, key, namespace, binders, visible)
      predeclare_definition_signatures(next, rest, namespace, scope)
    case _ <> rest:
      predeclare_definition_signatures(store, rest, namespace, visible)

def check_modules_module(v_20041707: ArenaStore, v_0: IR.Module, v_2: String, v_4: List<&2, IR.LoadedModule>, v_6: List<&2, Scope.ArenaGlobal>) -> ArenaResult<PrivateResult>:
  match v_0:
    case IR.Module{+v_20041708, +v_20041709, +v_20041710}:
      v_11 = v_20041708
      v_12 = v_20041709
      +v_13 = v_20041710
      ArenaResult{v_20041711, +v_20041712} = global_scope(v_20041707, v_6)
      ArenaResult{v_20041713, +v_20041714} = visible_globals(v_20041711, v_6, v_2, v_12)
      ArenaResult{prepared_store, prepared_visible} = predeclare_definition_signatures(v_20041713, v_13, v_2, v_20041714)
      ArenaResult{v_20041715, +v_20041716} = check_declarations(prepared_store, v_13, v_2, v_12, v_20041712, IR.Names{0, 0}, prepared_visible)
      check_modules_declarations(v_20041715, v_20041716, v_2, v_11, v_12, v_4)

def check_modules_private(v_20041717: ArenaStore, v_1: List<&2, IR.LoadedModule>, v_3: List<&2, Scope.ArenaGlobal>) -> ArenaResult<PrivateResult>:
  match v_1:
    case []:
      {ArenaResult{v_20041717, PrivateSuccess{[]}} : ArenaResult<PrivateResult>}
    case +v_20041718 <> +v_20041719:
      +v_7 = v_20041718
      v_8 = v_20041719
      match v_7:
        case IR.LoadedModule{+v_20041720, +v_20041721}:
          v_11 = v_20041720
          v_12 = v_20041721
          ArenaResult{v_20041722, +v_20041723} = check_modules_module(v_20041717, v_12, v_11, v_8, v_3)
          {ArenaResult{v_20041722, v_20041723} : ArenaResult<PrivateResult>}


def scope_index_name_aliases_result(v_3: Maybe<&2, IR.Names>) -> IR.Names:
  match v_3:
    case None{}:
      IR.Names{0, 0}
    case Some{+v_20041797}:
      v_7 = v_20041797
      v_7

def scope_index_name_aliases(+v_1: String, +v_3: Scope.ArenaGlobalIndex) -> IR.Names:
  match v_3:
    case Scope.ArenaGlobalIndex{+v_20041798, +v_20041799, +v_20041800, +v_20041801}:
      v_12 = v_20041800
      scope_index_name_aliases_result(IndexLookup.find(IR.Names, v_12, v_1))

def scope_segment_name_aliases(v_20041802: ArenaStore, +v_1: String, +v_4: List<&2, Scope.ArenaGlobalSegment>) -> ArenaResult<IR.Names>:
  match v_4:
    case []:
      {ArenaResult{v_20041802, IR.Names{0, 0}} : ArenaResult<IR.Names>}
    case +v_20041803 <> +v_20041804:
      match v_20041803:
        case Scope.ArenaGlobalSegment{+v_20041805, +v_20041806, +v_20041807, +v_20041808, +v_20041809}:
          v_17 = v_20041809
          v_18 = v_20041804
          ArenaResult{v_20041810, +v_20041811} = scope_segment_name_aliases(v_20041802, v_1, v_18)
          ArenaResult{v_20041812, +v_20041813} = arena_names_append(v_20041810, scope_index_name_aliases(v_1, v_17), v_20041811)
          {ArenaResult{v_20041812, v_20041813} : ArenaResult<IR.Names>}

def scope_scope_name_aliases(v_1: ArenaStore, +v_3: String, +v_4: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  match v_4:
    case Scope.ArenaGlobalScope{+v_10, +v_11, +v_12}:
      v_14 = v_11
      v_50000373 = scope_index_name_aliases(v_3, v_14)
      {ArenaResult{v_1, v_50000373} : ArenaResult<IR.Names>}
    case Scope.ArenaVisibleScope{+v_17, ignored_lookup}:
      v_19 = v_17
      ArenaResult{v_23, +v_24} = scope_segment_name_aliases(v_1, v_3, v_19)
      {ArenaResult{v_23, v_24} : ArenaResult<IR.Names>}
    case Scope.ArenaUnsafeScope{+v_26}:
      v_28 = v_26
      ArenaResult{v_32, +v_33} = scope_scope_name_aliases(v_1, v_3, v_28)
      {ArenaResult{v_32, v_33} : ArenaResult<IR.Names>}

def scope_name_is_in(v_20041824: ArenaStore, +v_1: String, +v_4: IR.Names) -> ArenaResult<Bool>:
  ArenaResult{v_20041825, +v_20041826} = arena_names_view(v_20041824, v_4)
  match v_20041826:
    case IR.NameNil{}:
      {ArenaResult{v_20041825, False{}} : ArenaResult<Bool>}
    case IR.NameCons{+v_20041827, +v_20041828}:
      v_8 = v_20041827
      v_9 = v_20041828
      +v_20041831 = String.eq(v_1, v_8)
      match v_20041831:
        case False{}:
          ArenaResult{v_20041832, +v_20041833} = scope_name_is_in(v_20041825, v_1, v_9)
          +v_20041829 = v_20041833
          v_20041830 = v_20041832
          {ArenaResult{v_20041830, v_20041829} : ArenaResult<Bool>}
        case True{}:
          +v_20041829 = True{}
          v_20041830 = v_20041825
          {ArenaResult{v_20041830, v_20041829} : ArenaResult<Bool>}

def scope_canonical_alias_valid(v_20041834: ArenaStore, +v_1: String, +v_3: Scope.ArenaGlobalScope, +v_5: String, +v_8: IR.Names) -> ArenaResult<IR.Names>:
  ArenaResult{v_20041837, +v_20041838} = scope_name_is_in(v_20041834, v_5, v_8)
  +v_20041839 = v_20041838
  match v_20041839:
    case False{}:
      +v_20041842 = String.eq(Scope.canonical_name(v_5, v_3), v_1)
      match v_20041842:
        case False{}:
          +v_20041840 = v_8
          v_20041841 = v_20041837
          {ArenaResult{v_20041841, v_20041840} : ArenaResult<IR.Names>}
        case True{}:
          ArenaResult{v_20041843, +v_20041844} = arena_names_cons(v_20041837, v_5, v_8)
          +v_20041840 = v_20041844
          v_20041841 = v_20041843
          {ArenaResult{v_20041841, v_20041840} : ArenaResult<IR.Names>}
    case True{}:
      +v_20041835 = v_8
      v_20041836 = v_20041837
      {ArenaResult{v_20041836, v_20041835} : ArenaResult<IR.Names>}

def scope_canonical_aliases_filter(v_20041845: ArenaStore, +v_1: String, +v_3: Scope.ArenaGlobalScope, v_6: IR.Names) -> ArenaResult<IR.Names>:
  ArenaResult{v_20041846, +v_20041847} = arena_names_view(v_20041845, v_6)
  match v_20041847:
    case IR.NameNil{}:
      {ArenaResult{v_20041846, IR.Names{0, 0}} : ArenaResult<IR.Names>}
    case IR.NameCons{+v_20041848, +v_20041849}:
      v_11 = v_20041848
      v_12 = v_20041849
      ArenaResult{v_20041850, +v_20041851} = scope_canonical_aliases_filter(v_20041846, v_1, v_3, v_12)
      ArenaResult{v_20041852, +v_20041853} = scope_canonical_alias_valid(v_20041850, v_1, v_3, v_11, v_20041851)
      {ArenaResult{v_20041852, v_20041853} : ArenaResult<IR.Names>}

def scope_canonical_name_aliases(v_20041854: ArenaStore, +v_1: String, +v_3: Scope.ArenaGlobalScope) -> ArenaResult<IR.Names>:
  ArenaResult{v_20041855, +v_20041856} = scope_scope_name_aliases(v_20041854, v_1, v_3)
  ArenaResult{v_20041857, +v_20041858} = arena_names_cons(v_20041855, v_1, v_20041856)
  ArenaResult{v_20041859, +v_20041860} = scope_canonical_aliases_filter(v_20041857, v_1, v_3, v_20041858)
  {ArenaResult{v_20041859, v_20041860} : ArenaResult<IR.Names>}

# Matrix-local raw descriptor index. Ordinals merge only selected buckets in
# original row order; tapes (including region/direction tags) remain untouched.
# No scoped alias conclusion survives a query.
def pattern_row_index_empty() -> PatternRowIndex:
  PatternRowIndex{[], Map.new(&2, List<&2, IR.Words>), [], Map.new(&2, List<&2, Nat>), [], 0n}

def pattern_row_index_rows(index: PatternRowIndex) -> List<&2, IR.Words>:
  match index:
    case PatternRowIndex{rows, heads, other, ranks, other_ranks, count}: rows

def pattern_row_index_bucket(found: Maybe<&2, List<&2, IR.Words>>) -> List<&2, IR.Words>:
  match found:
    case None{}: []
    case Some{rows}: rows

def pattern_row_index_ranks(found: Maybe<&2, List<&2, Nat>>) -> List<&2, Nat>:
  match found:
    case None{}: []
    case Some{ranks}: ranks

def pattern_row_index_add_head(+row: IR.Words, name: Maybe<&2, String>, index: PatternRowIndex) -> PatternRowIndex:
  match index:
    case PatternRowIndex{rows, +heads, other, +ranks, other_ranks, +count}:
      match name:
        case None{}:
          PatternRowIndex{row <> rows, heads, row <> other, ranks, count <> other_ranks, Nat.add(count, 1n)}
        case Some{+key}:
          bucket = pattern_row_index_bucket(IndexLookup.find(List<&2, IR.Words>, heads, key))
          positions = pattern_row_index_ranks(IndexLookup.find(List<&2, Nat>, ranks, key))
          PatternRowIndex{row <> rows, Map.set(&2, List<&2, IR.Words>, heads, key, row <> bucket), other, Map.set(&2, List<&2, Nat>, ranks, key, count <> positions), other_ranks, Nat.add(count, 1n)}

def pattern_row_index_region_result(other: Arena.Arena, result: Arena.Arena & Bool, temporary: Bool) -> ArenaResult<Bool>:
  match result:
    case Tuple{arena, valid}:
      match temporary:
        case False{}: {ArenaResult{ArenaStore{arena, other}, valid} : ArenaResult<Bool>}
        case True{}: {ArenaResult{ArenaStore{other, arena}, valid} : ArenaResult<Bool>}

def pattern_row_index_range_region(store: ArenaStore, start: U32, count: U32, temporary: Bool) -> ArenaResult<Bool>:
  match store:
    case ArenaStore{source, transient}:
      match temporary:
        case False{}: pattern_row_index_region_result(transient, Arena.case_prefix_range_valid(source, start, count), False{})
        case True{}: pattern_row_index_region_result(source, Arena.case_prefix_range_valid(transient, U32.and(start, 2147483647), count), True{})

def pattern_row_index_range_empty(store: ArenaStore, +start: U32, count: U32, empty: Bool) -> ArenaResult<Bool>:
  match empty:
    case True{}: {ArenaResult{store, True{}} : ArenaResult<Bool>}
    case False{}: pattern_row_index_range_region(store, start, count, arena_is_transient(start))

def pattern_row_index_range(store: ArenaStore, range: IR.Words) -> ArenaResult<Bool>:
  match range:
    case IR.Words{start, +count}: pattern_row_index_range_empty(store, start, count, U32.is_eq(count, 0))

def pattern_row_index_pattern_region(store: ArenaStore, id: U32, temporary: Bool) -> ArenaResult<Bool>:
  match store:
    case ArenaStore{source, transient}:
      match temporary:
        case False{}: pattern_row_index_region_result(transient, Arena.case_prefix_pattern_valid(source, id), False{})
        case True{}: pattern_row_index_region_result(source, Arena.case_prefix_pattern_valid(transient, arena_node_offset(id)), True{})

def pattern_row_index_name_result(+row: IR.Words, index: PatternRowIndex, +name: U32, result: ArenaResult<Bool>) -> ArenaResult<PatternRowIndex>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, pattern_row_index_add_head(row, None{}, index)} : ArenaResult<PatternRowIndex>}
        case True{}:
          ArenaResult{store1, key} = arena_name_text(store, name)
          {ArenaResult{store1, pattern_row_index_add_head(row, Some{key}, index)} : ArenaResult<PatternRowIndex>}

def pattern_row_index_fields_result(row: IR.Words, index: PatternRowIndex, +name: U32, result: ArenaResult<Bool>) -> ArenaResult<PatternRowIndex>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, pattern_row_index_add_head(row, None{}, index)} : ArenaResult<PatternRowIndex>}
        case True{}:
          match store:
            case ArenaStore{source, transient}:
              pattern_row_index_name_result(row, index, name, pattern_row_index_region_result(transient, Arena.case_prefix_name_valid(source, name), False{}))

def pattern_row_index_pattern_result(+row: IR.Words, index: PatternRowIndex, pattern: U32, result: ArenaResult<Bool>) -> ArenaResult<PatternRowIndex>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, pattern_row_index_add_head(row, None{}, index)} : ArenaResult<PatternRowIndex>}
        case True{}:
          ArenaResult{store1, descriptor} = arena_get_pattern(store, pattern)
          match descriptor:
            case Arena.PatternCtr{name, fields_start, fields_count, span}:
              pattern_row_index_fields_result(row, index, name, pattern_row_index_range(store1, IR.Words{fields_start, fields_count}))
            case _:
              {ArenaResult{store1, pattern_row_index_add_head(row, None{}, index)} : ArenaResult<PatternRowIndex>}

def pattern_row_index_range_result(+row: IR.Words, index: PatternRowIndex, result: ArenaResult<Bool>) -> ArenaResult<PatternRowIndex>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, pattern_row_index_add_head(row, None{}, index)} : ArenaResult<PatternRowIndex>}
        case True{}:
          ArenaResult{store1, view} = arena_words_view(store, row)
          match view:
            case IR.WordCons{+pattern, rest}:
              pattern_row_index_pattern_result(row, index, pattern, pattern_row_index_pattern_region(store1, pattern, arena_is_transient(pattern)))
            case _:
              {ArenaResult{store1, pattern_row_index_add_head(row, None{}, index)} : ArenaResult<PatternRowIndex>}

def pattern_row_index_add(store: ArenaStore, +row: IR.Words, index: PatternRowIndex) -> ArenaResult<PatternRowIndex>:
  pattern_row_index_range_result(row, index, pattern_row_index_range(store, row))

def pattern_row_index_build(store: ArenaStore, rows: List<&2, IR.Words>) -> ArenaResult<PatternRowIndex>:
  match rows:
    case []:
      {ArenaResult{store, pattern_row_index_empty()} : ArenaResult<PatternRowIndex>}
    case row <> rest:
      ArenaResult{store1, index} = pattern_row_index_build(store, rest)
      pattern_row_index_add(store1, row, index)

def pattern_row_selection_cons(row: IR.Words, rank: Nat, selection: PatternRowSelection) -> PatternRowSelection:
  match selection:
    case PatternRowSelection{rows, ranks}: PatternRowSelection{row <> rows, rank <> ranks}

def pattern_row_selection_merge(left: PatternRowSelection, right: PatternRowSelection) -> PatternRowSelection:
  match left:
    case PatternRowSelection{rows, ranks}:
      match rows:
        case []: right
        case +row <> rest:
          match ranks:
            case +rank <> positions:
              match right:
                case PatternRowSelection{other, other_ranks}:
                  match other:
                    case []: PatternRowSelection{row <> rest, rank <> positions}
                    case +other_row <> other_rest:
                      match other_ranks:
                        case +other_rank <> other_positions:
                          pattern_row_selection_merge_order(Nat.is_ge(rank, other_rank), row, rest, rank, positions, other_row, other_rest, other_rank, other_positions)
                        case []: PatternRowSelection{row <> rest, rank <> positions}
            case []: right

def pattern_row_selection_merge_order(order: Bool, +row: IR.Words, rest: List<&2, IR.Words>, +rank: Nat, positions: List<&2, Nat>, +other_row: IR.Words, other_rest: List<&2, IR.Words>, +other_rank: Nat, other_positions: List<&2, Nat>) -> PatternRowSelection:
  match order:
    case True{}:
      pattern_row_selection_cons(row, rank, pattern_row_selection_merge(PatternRowSelection{rest, positions}, PatternRowSelection{other_row <> other_rest, other_rank <> other_positions}))
    case False{}:
      pattern_row_selection_cons(other_row, other_rank, pattern_row_selection_merge(PatternRowSelection{row <> rest, rank <> positions}, PatternRowSelection{other_rest, other_positions}))

def pattern_row_index_select_seen(store: ArenaStore, seen_name: Maybe<&2, Bool>, +key: String, rest: IR.Names, +heads: Map<&2, List<&2, IR.Words>>, +ranks: Map<&2, List<&2, Nat>>, seen: Map<&2, Bool>, selected: PatternRowSelection) -> ArenaResult<PatternRowSelection>:
  match seen_name:
    case Some{found}:
      pattern_row_index_select(store, rest, heads, ranks, seen, selected)
    case None{}:
      rows = pattern_row_index_bucket(IndexLookup.find(List<&2, IR.Words>, heads, key))
      positions = pattern_row_index_ranks(IndexLookup.find(List<&2, Nat>, ranks, key))
      pattern_row_index_select(store, rest, heads, ranks, Map.set(&2, Bool, seen, key, True{}), pattern_row_selection_merge(selected, PatternRowSelection{rows, positions}))

def pattern_row_index_select(store: ArenaStore, names: IR.Names, +heads: Map<&2, List<&2, IR.Words>>, +ranks: Map<&2, List<&2, Nat>>, +seen: Map<&2, Bool>, selected: PatternRowSelection) -> ArenaResult<PatternRowSelection>:
  ArenaResult{store1, view} = arena_names_view(store, names)
  match view:
    case IR.NameNil{}:
      {ArenaResult{store1, selected} : ArenaResult<PatternRowSelection>}
    case IR.NameCons{+key, rest}:
      pattern_row_index_select_seen(store1, IndexLookup.find(Bool, seen, key), key, rest, heads, ranks, seen, selected)

def pattern_row_index_candidates_result(result: ArenaResult<PatternRowSelection>) -> ArenaResult<List<&2, IR.Words>>:
  match result:
    case ArenaResult{store, selection}:
      match selection:
        case PatternRowSelection{rows, ranks}: {ArenaResult{store, rows} : ArenaResult<List<&2, IR.Words>>}

def pattern_row_index_candidates(store: ArenaStore, index: PatternRowIndex, names: IR.Names) -> ArenaResult<List<&2, IR.Words>>:
  match index:
    case PatternRowIndex{rows, heads, other, ranks, other_ranks, count}:
      pattern_row_index_candidates_result(pattern_row_index_select(store, names, heads, ranks, Map.new(&2, Bool), PatternRowSelection{other, other_ranks}))

# Filtering is safe only when every visible alias source is complete. Unsafe
# scopes keep the original full-row traversal, even if their inner index is full.
def pattern_row_index_global_complete(index: Scope.ArenaGlobalIndex) -> Bool:
  match index:
    case Scope.ArenaGlobalIndex{keys, constructors, aliases, complete}: complete

def pattern_row_index_segments_complete(segments: List<&2, Scope.ArenaGlobalSegment>) -> Bool:
  match segments:
    case []: True{}
    case segment <> rest:
      match segment:
        case Scope.ArenaGlobalSegment{a, b, c, d, index}:
          Bool.and(pattern_row_index_global_complete(index), pattern_row_index_segments_complete(rest))

def pattern_row_index_scope_complete(scope: Scope.ArenaGlobalScope) -> Bool:
  match scope:
    case Scope.ArenaGlobalScope{globals, index, module}: pattern_row_index_global_complete(index)
    case Scope.ArenaVisibleScope{segments, ignored_lookup}: pattern_row_index_segments_complete(segments)
    case Scope.ArenaUnsafeScope{inner}: False{}

def pattern_row_index_query(store: ArenaStore, complete: Bool, index: PatternRowIndex, names: IR.Names) -> ArenaResult<List<&2, IR.Words>>:
  match complete:
    case False{}: {ArenaResult{store, pattern_row_index_rows(index)} : ArenaResult<List<&2, IR.Words>>}
    case True{}: pattern_row_index_candidates(store, index, names)

def scope_wildcard_patterns(v_20041861: ArenaStore, v_1: Nat, +v_2: Ast.SourceSpan) -> ArenaResult<IR.Words>:
  match v_1:
    case 0n:
      {ArenaResult{v_20041861, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case 1n++v_20041862:
      v_5 = v_20041862
      ArenaResult{v_20041863, +v_20041864} = arena_name(v_20041861, "")
      ArenaResult{v_20041865, +v_20041866} = arena_put_pattern(v_20041863, Arena.PatternVar{v_20041864, 0n, Ast.QZero{}, v_2})
      ArenaResult{v_20041867, +v_20041868} = scope_wildcard_patterns(v_20041865, v_5, v_2)
      ArenaResult{v_20041869, +v_20041870} = arena_words_cons(v_20041867, v_20041866, v_20041868)
      {ArenaResult{v_20041869, v_20041870} : ArenaResult<IR.Words>}

def scope_specialize_pattern_row(v_20041871: ArenaStore, +v_1: IR.Words, +v_4: List<&2, IR.Words>, +v_7: IR.Names, +v_9: Nat) -> ArenaResult<List<&2, IR.Words>>:
  ArenaResult{v_20041872, +v_20041873} = arena_words_view(v_20041871, v_1)
  match v_20041873:
    case IR.WordNil{}:
      {ArenaResult{v_20041872, IR.Words{0, 0} <> v_4} : ArenaResult<List<&2, IR.Words>>}
    case IR.WordCons{+v_20041874, +v_20041875}:
      +v_14 = v_20041874
      v_15 = v_20041875
      ArenaResult{v_20041876, +v_20041877} = arena_get_pattern(v_20041872, v_14)
      match v_20041877:
        case Arena.PatternVar{+v_20041878, +v_20041880, +v_20041881, +v_20041882}:
          v_23 = v_20041882
          ArenaResult{v_20041883, +v_20041884} = scope_wildcard_patterns(v_20041876, v_9, v_23)
          ArenaResult{v_20041885, +v_20041886} = arena_words_append(v_20041883, v_20041884, v_15)
          {ArenaResult{v_20041885, v_20041886 <> v_4} : ArenaResult<List<&2, IR.Words>>}
        case Arena.PatternCtr{+v_20041887, +v_20041889, +v_20041890, +v_20041892}:
          ArenaResult{v_20041893, +v_20041894} = arena_name_text(v_20041876, v_20041887)
          +v_20041888 = v_20041894
          +v_20041891 = IR.Words{v_20041889, v_20041890}
          v_28 = v_20041888
          v_29 = v_20041891
          ArenaResult{v_20041897, +v_20041898} = scope_name_is_in(v_20041893, v_28, v_7)
          +v_20041899 = Bool.and(v_20041898, Nat.is_eq(arena_words_length(v_29), v_9))
          match v_20041899:
            case False{}:
              +v_20041895 = v_4
              v_20041896 = v_20041897
              {ArenaResult{v_20041896, v_20041895} : ArenaResult<List<&2, IR.Words>>}
            case True{}:
              ArenaResult{v_20041900, +v_20041901} = arena_words_append(v_20041897, v_29, v_15)
              +v_20041895 = v_20041901 <> v_4
              v_20041896 = v_20041900
              {ArenaResult{v_20041896, v_20041895} : ArenaResult<List<&2, IR.Words>>}

def scope_specialize_pattern_rows_named(v_20041902: ArenaStore, +v_2: List<&2, IR.Words>, +v_5: IR.Names, +v_7: Nat) -> ArenaResult<List<&2, IR.Words>>:
  match v_2:
    case []:
      {ArenaResult{v_20041902, []} : ArenaResult<List<&2, IR.Words>>}
    case +v_20041903 <> +v_20041904:
      v_12 = v_20041903
      v_13 = v_20041904
      ArenaResult{v_20041905, +v_20041906} = scope_specialize_pattern_rows_named(v_20041902, v_13, v_5, v_7)
      ArenaResult{v_20041907, +v_20041908} = scope_specialize_pattern_row(v_20041905, v_12, v_20041906, v_5, v_7)
      {ArenaResult{v_20041907, v_20041908} : ArenaResult<List<&2, IR.Words>>}

def scope_specialize_pattern_rows(store: ArenaStore, index: PatternRowIndex, +name: String, arity: Nat, +scope: Scope.ArenaGlobalScope) -> ArenaResult<List<&2, IR.Words>>:
  ArenaResult{store1, +names} = scope_canonical_name_aliases(store, name, scope)
  ArenaResult{store2, query_names} = arena_names_cons(store1, name, names)
  ArenaResult{store3, candidates} = pattern_row_index_query(store2, pattern_row_index_scope_complete(scope), index, query_names)
  scope_specialize_pattern_rows_named(store3, candidates, names, arity)

def scope_pattern_row_subsumes(v_20041915: ArenaStore, +v_1: IR.Words, +v_3: IR.Words, +v_5: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20041916, +v_20041917} = arena_words_view(v_20041915, v_1)
  match v_20041917:
    case IR.WordNil{}:
      ArenaResult{v_20041918, +v_20041919} = arena_words_view(v_20041916, v_3)
      match v_20041919:
        case IR.WordNil{}:
          {ArenaResult{v_20041918, True{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20041918, False{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20041923, +v_20041924}:
      ArenaResult{v_20041925, +v_20041926} = arena_get_pattern(v_20041916, v_20041923)
      match v_20041926:
        case Arena.PatternVar{+v_20041931, +v_20041933, +v_20041934, +v_20041935}:
          ArenaResult{v_20041936, +v_20041937} = arena_words_view(v_20041925, v_3)
          match v_20041937:
            case IR.WordCons{+v_20041940, +v_20041941}:
              v_20 = v_20041941
              v_18 = v_20041924
              ArenaResult{v_20041942, +v_20041943} = scope_pattern_row_subsumes(v_20041936, v_18, v_20, v_5)
              {ArenaResult{v_20041942, v_20041943} : ArenaResult<Bool>}
            case _:
              {ArenaResult{v_20041936, False{}} : ArenaResult<Bool>}
        case Arena.PatternCtr{+v_20041948, +v_20041950, +v_20041951, +v_20041953}:
          ArenaResult{v_20041954, +v_20041955} = arena_name_text(v_20041925, v_20041948)
          +v_20041949 = v_20041955
          +v_20041952 = IR.Words{v_20041950, v_20041951}
          ArenaResult{v_20041956, +v_20041957} = arena_words_view(v_20041954, v_3)
          match v_20041957:
            case IR.WordCons{+v_20041960, +v_20041961}:
              ArenaResult{v_20041962, +v_20041963} = arena_get_pattern(v_20041956, v_20041960)
              match v_20041963:
                case Arena.PatternCtr{+v_20041967, +v_20041969, +v_20041970, +v_20041972}:
                  ArenaResult{v_20041973, +v_20041974} = arena_name_text(v_20041962, v_20041967)
                  +v_20041968 = v_20041974
                  +v_20041971 = IR.Words{v_20041969, v_20041970}
                  v_34 = v_20041968
                  v_35 = v_20041971
                  v_37 = v_20041961
                  v_30 = v_20041949
                  v_31 = v_20041952
                  v_33 = v_20041924
                  +v_20041977 = Scope.equal_names(v_30, v_34, v_5)
                  match v_20041977:
                    case False{}:
                      +v_20041975 = False{}
                      v_20041976 = v_20041973
                      {ArenaResult{v_20041976, v_20041975} : ArenaResult<Bool>}
                    case True{}:
                      ArenaResult{v_20041980, +v_20041981} = scope_pattern_row_subsumes(v_20041973, v_31, v_35, v_5)
                      +v_20041982 = v_20041981
                      match v_20041982:
                        case False{}:
                          +v_20041978 = False{}
                          v_20041979 = v_20041980
                          {ArenaResult{v_20041979, v_20041978} : ArenaResult<Bool>}
                        case True{}:
                          ArenaResult{v_20041983, +v_20041984} = scope_pattern_row_subsumes(v_20041980, v_33, v_37, v_5)
                          +v_20041978 = v_20041984
                          v_20041979 = v_20041983
                          {ArenaResult{v_20041979, v_20041978} : ArenaResult<Bool>}
                case _:
                  {ArenaResult{v_20041962, False{}} : ArenaResult<Bool>}
            case _:
              {ArenaResult{v_20041956, False{}} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20041925, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20041916, False{}} : ArenaResult<Bool>}

def scope_pattern_rows_subsume_other(v_20041989: ArenaStore, +v_2: List<&2, IR.Words>, +v_4: IR.Words, +v_6: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_2:
    case []:
      {ArenaResult{v_20041989, False{}} : ArenaResult<Bool>}
    case +v_20041990 <> +v_20041991:
      v_10 = v_20041990
      v_11 = v_20041991
      ArenaResult{v_20041994, +v_20041995} = scope_pattern_row_subsumes(v_20041989, v_10, v_4, v_6)
      +v_20041996 = v_20041995
      match v_20041996:
        case False{}:
          ArenaResult{v_20041997, +v_20041998} = scope_pattern_rows_subsume_other(v_20041994, v_11, v_4, v_6)
          +v_20041992 = v_20041998
          v_20041993 = v_20041997
          {ArenaResult{v_20041993, v_20041992} : ArenaResult<Bool>}
        case True{}:
          +v_20041992 = True{}
          v_20041993 = v_20041994
          {ArenaResult{v_20041993, v_20041992} : ArenaResult<Bool>}

def scope_pattern_row_subsumes_named(v_20041999: ArenaStore, v_1: IR.Words, +v_3: IR.Words, +v_5: IR.Words, +v_8: IR.Names, +v_10: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{v_20042000, +v_20042001} = arena_words_view(v_20041999, v_1)
  match v_20042001:
    case IR.WordCons{+v_20042004, +v_20042005}:
      ArenaResult{v_20042006, +v_20042007} = arena_get_pattern(v_20042000, v_20042004)
      match v_20042007:
        case Arena.PatternVar{+v_20042012, +v_20042014, +v_20042015, +v_20042016}:
          v_21 = v_20042005
          ArenaResult{v_20042017, +v_20042018} = scope_pattern_row_subsumes(v_20042006, v_21, v_5, v_10)
          {ArenaResult{v_20042017, v_20042018} : ArenaResult<Bool>}
        case Arena.PatternCtr{+v_20042022, +v_20042024, +v_20042025, +v_20042027}:
          ArenaResult{v_20042028, +v_20042029} = arena_name_text(v_20042006, v_20042022)
          +v_20042023 = v_20042029
          +v_20042026 = IR.Words{v_20042024, v_20042025}
          v_27 = v_20042023
          v_28 = v_20042026
          v_30 = v_20042005
          ArenaResult{v_20042032, +v_20042033} = scope_name_is_in(v_20042028, v_27, v_8)
          +v_20042034 = v_20042033
          match v_20042034:
            case False{}:
              +v_20042030 = False{}
              v_20042031 = v_20042032
              {ArenaResult{v_20042031, v_20042030} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_20042037, +v_20042038} = scope_pattern_row_subsumes(v_20042032, v_28, v_3, v_10)
              +v_20042039 = v_20042038
              match v_20042039:
                case False{}:
                  +v_20042035 = False{}
                  v_20042036 = v_20042037
                  {ArenaResult{v_20042036, v_20042035} : ArenaResult<Bool>}
                case True{}:
                  ArenaResult{v_20042040, +v_20042041} = scope_pattern_row_subsumes(v_20042037, v_30, v_5, v_10)
                  +v_20042035 = v_20042041
                  v_20042036 = v_20042040
                  {ArenaResult{v_20042036, v_20042035} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20042006, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20042000, False{}} : ArenaResult<Bool>}

def scope_pattern_rows_subsume_named(v_20042044: ArenaStore, v_2: List<&2, IR.Words>, +v_4: IR.Words, +v_6: IR.Words, +v_9: IR.Names, +v_11: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match v_2:
    case []:
      {ArenaResult{v_20042044, False{}} : ArenaResult<Bool>}
    case +v_20042045 <> +v_20042046:
      v_15 = v_20042045
      v_16 = v_20042046
      ArenaResult{v_20042049, +v_20042050} = scope_pattern_row_subsumes_named(v_20042044, v_15, v_4, v_6, v_9, v_11)
      +v_20042051 = v_20042050
      match v_20042051:
        case False{}:
          ArenaResult{v_20042052, +v_20042053} = scope_pattern_rows_subsume_named(v_20042049, v_16, v_4, v_6, v_9, v_11)
          +v_20042047 = v_20042053
          v_20042048 = v_20042052
          {ArenaResult{v_20042048, v_20042047} : ArenaResult<Bool>}
        case True{}:
          +v_20042047 = True{}
          v_20042048 = v_20042049
          {ArenaResult{v_20042048, v_20042047} : ArenaResult<Bool>}

def scope_pattern_rows_subsume(store: ArenaStore, index: PatternRowIndex, +target: IR.Words, +scope: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store1, view} = arena_words_view(store, target)
  match view:
    case IR.WordCons{pattern, rest}:
      ArenaResult{store2, descriptor} = arena_get_pattern(store1, pattern)
      match descriptor:
        case Arena.PatternCtr{name, fields_start, fields_count, span}:
          ArenaResult{store3, +key} = arena_name_text(store2, name)
          ArenaResult{store4, +names} = scope_canonical_name_aliases(store3, Scope.canonical_name(key, scope), scope)
          ArenaResult{store5, query_names} = arena_names_cons(store4, key, names)
          ArenaResult{store6, candidates} = pattern_row_index_query(store5, pattern_row_index_scope_complete(scope), index, query_names)
          scope_pattern_rows_subsume_named(store6, candidates, IR.Words{fields_start, fields_count}, rest, names, scope)
        case _:
          scope_pattern_rows_subsume_other(store2, pattern_row_index_rows(index), target, scope)
    case _:
      scope_pattern_rows_subsume_other(store1, pattern_row_index_rows(index), target, scope)

def scope_constructor_trees_are_closed(v_20042085: ArenaStore, v_1: IR.Words) -> ArenaResult<Bool>:
  ArenaResult{v_20042086, +v_20042087} = arena_words_view(v_20042085, v_1)
  match v_20042087:
    case IR.WordNil{}:
      {ArenaResult{v_20042086, True{}} : ArenaResult<Bool>}
    case IR.WordCons{+v_20042090, +v_20042091}:
      ArenaResult{v_20042092, +v_20042093} = arena_get_node(v_20042086, v_20042090)
      match v_20042093:
        case Arena.TermString{_, _, _}:
          scope_constructor_trees_are_closed(v_20042092, v_20042091)
        case Arena.TermCtr{+v_20042097, +v_20042099, +v_20042100, +v_20042102}:
          +v_20042101 = IR.Words{v_20042099, v_20042100}
          v_8 = v_20042101
          v_10 = v_20042091
          ArenaResult{v_20042105, +v_20042106} = scope_constructor_trees_are_closed(v_20042092, v_8)
          +v_20042107 = v_20042106
          match v_20042107:
            case False{}:
              +v_20042103 = False{}
              v_20042104 = v_20042105
              {ArenaResult{v_20042104, v_20042103} : ArenaResult<Bool>}
            case True{}:
              ArenaResult{v_20042108, +v_20042109} = scope_constructor_trees_are_closed(v_20042105, v_10)
              +v_20042103 = v_20042109
              v_20042104 = v_20042108
              {ArenaResult{v_20042104, v_20042103} : ArenaResult<Bool>}
        case _:
          {ArenaResult{v_20042092, False{}} : ArenaResult<Bool>}
    case _:
      {ArenaResult{v_20042086, False{}} : ArenaResult<Bool>}

# Reflexivity applies only to an exact full tagged source range with a positive
# constructor-only shape witness. No scope/name-alias conclusion is cached:
# unsupported terms and every uncertain range use the original comparator.
def arena_constructor_trees_are_closed_result(transient: Arena.Arena, result: Arena.Arena & Bool) -> ArenaResult<Bool>:
  match result:
    case Tuple{source, closed}: {ArenaResult{ArenaStore{source, transient}, closed} : ArenaResult<Bool>}

def arena_constructor_range_valid(store: ArenaStore, start: U32, count: U32) -> ArenaResult<Bool>:
  match store:
    case ArenaStore{source, transient}:
      arena_constructor_trees_are_closed_result(transient, Arena.ctor_source_range_valid(source, start, count))

def arena_constructor_node_valid(store: ArenaStore, id: U32) -> ArenaResult<Bool>:
  match store:
    case ArenaStore{source, transient}:
      arena_constructor_trees_are_closed_result(transient, Arena.case_prefix_node_valid(source, id))

def arena_constructor_name_valid(store: ArenaStore, id: U32) -> ArenaResult<Bool>:
  match store:
    case ArenaStore{source, transient}:
      arena_constructor_trees_are_closed_result(transient, Arena.case_prefix_name_valid(source, id))

def arena_constructor_node_has_witness_source(store: ArenaStore, id: U32, temporary: Bool) -> ArenaResult<Bool>:
  match temporary:
    case True{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case False{}:
      match store:
        case ArenaStore{source, transient}:
          arena_constructor_trees_are_closed_result(transient, Arena.node_has_flag(source, id, 16))

def arena_constructor_node_has_witness(store: ArenaStore, +id: U32) -> ArenaResult<Bool>:
  arena_constructor_node_has_witness_source(store, id, arena_is_transient(id))

def arena_constructor_node_certify(store: ArenaStore, id: U32) -> ArenaStore:
  match store:
    case ArenaStore{source, transient}: ArenaStore{Arena.node_ctor_certify(source, id), transient}

# The unbounded walk remains typed checker code. Native calls only validate
# bounded owner-local metadata or read/write a single positive flag.
def arena_constructor_trees_loop(remaining: Nat, +start: U32, +parent: U32, result: ArenaResult<Bool>) -> ArenaResult<Bool>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
        case True{}:
          match remaining:
            case 0n: {ArenaResult{store, True{}} : ArenaResult<Bool>}
            case 1n+rest: arena_constructor_trees_word(rest, arena_range_index(start, 1), parent, arena_get_word(store, start))

def arena_constructor_trees_child(remaining: Nat, start: U32, parent: U32, store: ArenaStore, id: U32, older: Bool) -> ArenaResult<Bool>:
  match older:
    case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case True{}: arena_constructor_trees_loop(remaining, start, parent, arena_constructor_node_is_tree(store, id))

def arena_constructor_trees_word(remaining: Nat, start: U32, +parent: U32, result: ArenaResult<U32>) -> ArenaResult<Bool>:
  match result:
    case ArenaResult{store, +id}:
      arena_constructor_trees_child(remaining, start, parent, store, id, Bool.and(Bool.not(arena_is_transient(id)), Arena.case_prefix_less(U32.cmp(id, parent))))

def arena_constructor_trees_valid(start: U32, count: U32, parent: U32, result: ArenaResult<Bool>) -> ArenaResult<Bool>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
        case True{}: arena_constructor_trees_loop(U32.to_nat(count), start, parent, {ArenaResult{store, True{}} : ArenaResult<Bool>})

def arena_constructor_trees(store: ArenaStore, +start: U32, +count: U32, parent: U32) -> ArenaResult<Bool>:
  arena_constructor_trees_valid(start, count, parent, arena_constructor_range_valid(store, start, count))

def arena_constructor_node_tree_certify(id: U32, result: ArenaResult<Bool>) -> ArenaResult<Bool>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
        case True{}: {ArenaResult{arena_constructor_node_certify(store, id), True{}} : ArenaResult<Bool>}

def arena_constructor_node_tree_name(+id: U32, start: U32, count: U32, result: ArenaResult<Bool>) -> ArenaResult<Bool>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
        case True{}: arena_constructor_node_tree_certify(id, arena_constructor_trees(store, start, count, id))

def arena_constructor_node_tree_descriptor(id: U32, result: ArenaResult<Arena.Node>) -> ArenaResult<Bool>:
  match result:
    case ArenaResult{store, descriptor}:
      match descriptor:
        case Arena.TermCtr{+name, start, count, _}: arena_constructor_node_tree_name(id, start, count, arena_constructor_name_valid(store, name))
        case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def arena_constructor_node_tree_valid(+id: U32, result: ArenaResult<Bool>) -> ArenaResult<Bool>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
        case True{}: arena_constructor_node_tree_descriptor(id, arena_get_node(store, id))

def arena_constructor_node_tree_cached(+id: U32, result: ArenaResult<Bool>) -> ArenaResult<Bool>:
  match result:
    case ArenaResult{store, certified}:
      match certified:
        case True{}: {ArenaResult{store, True{}} : ArenaResult<Bool>}
        case False{}: arena_constructor_node_tree_valid(id, arena_constructor_node_valid(store, id))

def arena_constructor_node_is_tree(store: ArenaStore, +id: U32) -> ArenaResult<Bool>:
  arena_constructor_node_tree_cached(id, arena_constructor_node_has_witness(store, id))

def arena_constructor_trees_are_closed(store: ArenaStore, words: IR.Words) -> ArenaResult<Bool>:
  match words:
    case IR.Words{start, count}: arena_constructor_trees(store, start, count, 2147483648)

def scope_constructor_lists_equal_witness(left: IR.Words, right: IR.Words, scope: Scope.ArenaGlobalScope, result: ArenaResult<Bool>) -> ArenaResult<Maybe<&2, Bool>>:
  match result:
    case ArenaResult{store, closed}:
      match closed:
        case True{}: {ArenaResult{store, Some{True{}}} : ArenaResult<Maybe<&2, Bool>>}
        case False{}: scope_constructor_lists_equal_open(store, left, right, scope)

def scope_constructor_lists_equal_exact(store: ArenaStore, +left: IR.Words, right: IR.Words, scope: Scope.ArenaGlobalScope, same: Bool) -> ArenaResult<Maybe<&2, Bool>>:
  match same:
    case False{}: scope_constructor_lists_equal_open(store, left, right, scope)
    case True{}: scope_constructor_lists_equal_witness(left, right, scope, arena_constructor_trees_are_closed(store, left))

def scope_constructor_lists_equal_empty(store: ArenaStore, +left: IR.Words, +right: IR.Words, scope: Scope.ArenaGlobalScope, empty: Bool) -> ArenaResult<Maybe<&2, Bool>>:
  match empty:
    case True{}: {ArenaResult{store, Some{True{}}} : ArenaResult<Maybe<&2, Bool>>}
    case False{}:
      scope_constructor_lists_equal_exact(store, left, right, scope, Bool.and(U32.is_eq(arena_words_start(left), arena_words_start(right)), U32.is_eq(arena_words_count(left), arena_words_count(right))))

def scope_constructor_lists_equal(store: ArenaStore, +left: IR.Words, +right: IR.Words, scope: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Bool>>:
  scope_constructor_lists_equal_empty(store, left, right, scope, Bool.and(arena_words_is_empty(left), arena_words_is_empty(right)))

def scope_constructor_lists_equal_open(v_20042112: ArenaStore, v_1: IR.Words, v_3: IR.Words, +v_5: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Bool>>:
  ArenaResult{v_20042113, +v_20042114} = arena_words_view(v_20042112, v_1)
  match v_20042114:
    case IR.WordNil{}:
      ArenaResult{v_20042115, +v_20042116} = arena_words_view(v_20042113, v_3)
      match v_20042116:
        case IR.WordNil{}:
          {ArenaResult{v_20042115, Some{True{}}} : ArenaResult<Maybe<&2, Bool>>}
        case _:
          {ArenaResult{v_20042115, Some{False{}}} : ArenaResult<Maybe<&2, Bool>>}
    case IR.WordCons{+v_20042122, +v_20042123}:
      ArenaResult{v_20042124, +v_20042125} = arena_words_view(v_20042113, v_3)
      match v_20042125:
        case IR.WordNil{}:
          {ArenaResult{v_20042124, Some{False{}}} : ArenaResult<Maybe<&2, Bool>>}
        case IR.WordCons{+v_20042128, +v_20042129}:
          ArenaResult{v_20042130, +v_20042131} = arena_get_node(v_20042124, v_20042128)
          match v_20042131:
            case Arena.TermCtr{+v_20042135, +v_20042137, +v_20042138, +v_20042140}:
              ArenaResult{v_20042141, +v_20042142} = arena_name_text(v_20042130, v_20042135)
              +v_20042136 = v_20042142
              +v_20042139 = IR.Words{v_20042137, v_20042138}
              ArenaResult{v_20042143, +v_20042144} = arena_get_node(v_20042141, v_20042122)
              match v_20042144:
                case Arena.TermCtr{+v_20042148, +v_20042150, +v_20042151, +v_20042153}:
                  ArenaResult{v_20042154, +v_20042155} = arena_name_text(v_20042143, v_20042148)
                  +v_20042149 = v_20042155
                  +v_20042152 = IR.Words{v_20042150, v_20042151}
                  v_20 = v_20042149
                  v_21 = v_20042152
                  v_24 = v_20042136
                  v_25 = v_20042139
                  v_27 = v_20042129
                  v_23 = v_20042123
                  +v_20042158 = Scope.equal_names(v_20, v_24, v_5)
                  match v_20042158:
                    case False{}:
                      +v_20042156 = Some{False{}}
                      v_20042157 = v_20042154
                      {ArenaResult{v_20042157, v_20042156} : ArenaResult<Maybe<&2, Bool>>}
                    case True{}:
                      ArenaResult{v_20042159, +v_20042160} = scope_constructor_lists_equal(v_20042154, v_21, v_25, v_5)
                      ArenaResult{v_20042161, +v_20042162} = scope_constructor_equality_after(v_20042159, v_20042160, v_23, v_27, v_5)
                      +v_20042156 = v_20042162
                      v_20042157 = v_20042161
                      {ArenaResult{v_20042157, v_20042156} : ArenaResult<Maybe<&2, Bool>>}
                case _:
                  {ArenaResult{v_20042143, None{}} : ArenaResult<Maybe<&2, Bool>>}
            case _:
              {ArenaResult{v_20042130, None{}} : ArenaResult<Maybe<&2, Bool>>}
        case _:
          {ArenaResult{v_20042124, None{}} : ArenaResult<Maybe<&2, Bool>>}
    case _:
      ArenaResult{v_20042167, +v_20042168} = arena_words_view(v_20042113, v_3)
      match v_20042168:
        case IR.WordNil{}:
          {ArenaResult{v_20042167, Some{False{}}} : ArenaResult<Maybe<&2, Bool>>}
        case _:
          {ArenaResult{v_20042167, None{}} : ArenaResult<Maybe<&2, Bool>>}

def scope_body_cases_for_names(v_20042170: ArenaStore, +v_1: IR.Words, +v_4: IR.Names) -> ArenaResult<IR.Words>:
  ArenaResult{v_20042171, +v_20042172} = arena_words_view(v_20042170, v_1)
  match v_20042172:
    case IR.WordNil{}:
      {ArenaResult{v_20042171, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20042175, +v_20042176}:
      ArenaResult{v_20042177, +v_20042178} = arena_get_node(v_20042171, v_20042175)
      match v_20042178:
        case Arena.BodyCase{+v_20042182, +v_20042183, +v_20042185, +v_20042186}:
          +v_20042184 = IR.Words{v_20042182, v_20042183}
          ArenaResult{v_20042187, +v_20042188} = arena_words_view(v_20042177, v_20042184)
          match v_20042188:
            case IR.WordCons{+v_20042191, +v_20042192}:
              ArenaResult{v_20042193, +v_20042194} = arena_get_pattern(v_20042187, v_20042191)
              match v_20042194:
                case Arena.PatternCtr{+v_20042198, +v_20042200, +v_20042201, +v_20042203}:
                  ArenaResult{v_20042204, +v_20042205} = arena_name_text(v_20042193, v_20042198)
                  +v_20042199 = v_20042205
                  v_13 = v_20042199
                  v_19 = v_20042176
                  ArenaResult{v_20042208, +v_20042209} = scope_name_is_in(v_20042204, v_13, v_4)
                  +v_20042210 = v_20042209
                  match v_20042210:
                    case False{}:
                      ArenaResult{v_20042211, +v_20042212} = scope_body_cases_for_names(v_20042208, v_19, v_4)
                      +v_20042206 = v_20042212
                      v_20042207 = v_20042211
                      {ArenaResult{v_20042207, v_20042206} : ArenaResult<IR.Words>}
                    case True{}:
                      +v_20042206 = v_1
                      v_20042207 = v_20042208
                      {ArenaResult{v_20042207, v_20042206} : ArenaResult<IR.Words>}
                case _:
                  {ArenaResult{v_20042193, v_1} : ArenaResult<IR.Words>}
            case _:
              {ArenaResult{v_20042187, v_1} : ArenaResult<IR.Words>}
        case _:
          {ArenaResult{v_20042177, v_1} : ArenaResult<IR.Words>}
    case _:
      {ArenaResult{v_20042171, v_1} : ArenaResult<IR.Words>}

def scope_body_cases_for_constructor(v_20042217: ArenaStore, +v_1: IR.Words, +v_3: String, +v_5: Scope.ArenaGlobalScope) -> ArenaResult<IR.Words>:
  ArenaResult{v_20042218, +v_20042219} = arena_words_view(v_20042217, v_1)
  match v_20042219:
    case IR.WordNil{}:
      {ArenaResult{v_20042218, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case _:
      ArenaResult{v_20042221, +v_20042222} = scope_canonical_name_aliases(v_20042218, Scope.canonical_name(v_3, v_5), v_5)
      ArenaResult{v_20042223, +v_20042224} = arena_names_cons(v_20042221, v_3, v_20042222)
      ArenaResult{v_20042225, +v_20042226} = scope_body_cases_for_names(v_20042223, v_1, v_20042224)
      {ArenaResult{v_20042225, v_20042226} : ArenaResult<IR.Words>}

# Pattern bounds already encode the exact binder count as 1+depth. Reuse only
# source-owned entries: transient patterns can contain source-tagged children,
# so their arena-local metadata is not a certificate. Unknown source entries
# and transient descriptors retain the structural count. This fact depends on
# neither typing scope nor de Bruijn depth, and creates no new cache lifetime.
def core_pattern_list_depth(store: ArenaStore, patterns: IR.Words) -> ArenaResult<Nat>:
  ArenaResult{store, view} = arena_words_view(store, patterns)
  match view:
    case IR.WordNil{}: {ArenaResult{store, 0n} : ArenaResult<Nat>}
    case IR.WordCons{pattern, rest}:
      ArenaResult{store, depth} = core_pattern_depth(store, pattern)
      ArenaResult{store, remaining} = core_pattern_list_depth(store, rest)
      {ArenaResult{store, Nat.add(depth, remaining)} : ArenaResult<Nat>}

def core_pattern_depth_bound(id: U32, result: ArenaResult<Nat>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, encoded}:
      match encoded:
        case 0n: core_pattern_depth_open(store, id)
        case 1n+depth: {ArenaResult{store, depth} : ArenaResult<Nat>}

def core_pattern_depth_region(store: ArenaStore, +id: U32, temporary: Bool) -> ArenaResult<Nat>:
  match temporary:
    case True{}: core_pattern_depth_open(store, id)
    case False{}:
      match store:
        case ArenaStore{source, transient}:
          core_pattern_depth_bound(id, arena_bound_source(Arena.bound_read(source, id, True{}), transient))

def core_pattern_depth(store: ArenaStore, +id: U32) -> ArenaResult<Nat>:
  core_pattern_depth_region(store, id, arena_is_transient(id))

def core_pattern_depth_open(store: ArenaStore, id: U32) -> ArenaResult<Nat>:
  ArenaResult{store, pattern} = arena_get_pattern(store, id)
  match pattern:
    case Arena.PatternVar{_, _, _, _}: {ArenaResult{store, 1n} : ArenaResult<Nat>}
    case Arena.PatternCtr{_, start, count, _}: core_pattern_list_depth(store, IR.Words{start, count})

def core_shift_var(v_20042271: ArenaStore, v_1: Bool, v_3: String, v_5: Nat, v_7: Nat, v_8: Ast.SourceSpan) -> ArenaResult<U32>:
  match v_1:
    case True{}:
      ArenaResult{v_20042272, +v_20042273} = arena_name(v_20042271, v_3)
      ArenaResult{v_20042274, +v_20042275} = arena_put_node(v_20042272, Arena.TermVar{v_20042273, Nat.add(v_5, v_7), v_8})
      {ArenaResult{v_20042274, v_20042275} : ArenaResult<U32>}
    case False{}:
      ArenaResult{v_20042276, +v_20042277} = arena_name(v_20042271, v_3)
      ArenaResult{v_20042278, +v_20042279} = arena_put_node(v_20042276, Arena.TermVar{v_20042277, v_5, v_8})
      {ArenaResult{v_20042278, v_20042279} : ArenaResult<U32>}

# Immutable subtrees below the operation's cutoff retain their original handle.
# Certificates are queried with the original region tag; no arena IDs escape.
# All free variables below the operation's cutoff are unaffected, even when
# the subtree is open. Unknown metadata always retains the ordinary traversal.
def core_bound_unaffected(encoded: Nat, target: Nat) -> Bool:
  match encoded:
    case 0n: False{}
    case 1n+bound: Nat.is_ge(target, bound)

def core_shift_unaffected(arena: ArenaStore, unaffected: Bool, id: U32, cut: Nat, add: Nat, depth: Nat) -> ArenaResult<U32>:
  match unaffected:
    case True{}: {ArenaResult{arena, id} : ArenaResult<U32>}
    case False{}: core_shift_open(arena, id, cut, add, depth)

def core_shift_at(arena: ArenaStore, +id: U32, +cut: Nat, add: Nat, +depth: Nat) -> ArenaResult<U32>:
  ArenaResult{next, encoded} = arena_node_bound(arena, id)
  core_shift_unaffected(next, core_bound_unaffected(encoded, Nat.add(cut, depth)), id, cut, add, depth)

def core_shift_open(v_1: ArenaStore, v_3: U32, +v_5: Nat, +v_7: Nat, +v_9: Nat) -> ArenaResult<U32>:
  ArenaResult{v_16, +v_17} = arena_get_node(v_1, v_3)
  match v_17:
    case Arena.TermVar{+v_21, +v_22, +v_23}:
      ArenaResult{v_27, +v_28} = arena_name_text(v_16, v_21)
      +v_30 = v_28
      v_32 = v_30
      +v_34 = v_22
      v_36 = v_23
      ArenaResult{v_40, +v_41} = core_shift_var(v_27, Nat.is_ge(v_34, Nat.add(v_5, v_9)), v_32, v_34, v_7, v_36)
      {ArenaResult{v_40, v_41} : ArenaResult<U32>}
    case Arena.TermRef{+v_44, +v_45}:
      {ArenaResult{v_16, v_3} : ArenaResult<U32>}
    case Arena.TermBang{+v_69, +v_70}:
      v_72 = v_69
      v_74 = v_70
      ArenaResult{v_78, +v_79} = core_shift_at(v_16, v_72, v_5, v_7, v_9)
      ArenaResult{v_83, +v_84} = arena_put_node(v_78, Arena.TermBang{v_79, v_74})
      {ArenaResult{v_83, v_84} : ArenaResult<U32>}
    case Arena.TermSub{+v_89, +v_90, +v_91, +v_92}:
      v_94 = v_89
      v_96 = v_90
      v_98 = v_91
      v_100 = v_92
      ArenaResult{v_104, +v_105} = core_shift_at(v_16, v_96, v_5, v_7, v_9)
      ArenaResult{v_109, +v_110} = core_shift_at(v_104, v_98, v_5, v_7, Nat.add(v_9, 1n))
      ArenaResult{v_114, +v_115} = arena_put_node(v_109, Arena.TermSub{v_94, v_105, v_110, v_100})
      {ArenaResult{v_114, v_115} : ArenaResult<U32>}
    case Arena.TermLet{+v_126, +v_127, +v_128, +v_129, +v_130, +v_131, +v_132, +v_133, +v_134, +v_135}:
      +v_137 = IR.Names{v_126, v_127}
      +v_139 = IR.Naturals{v_128, v_129}
      +v_141 = IR.Quantities{v_130, v_131}
      +v_143 = IR.Words{v_132, v_133}
      +v_145 = v_137
      v_147 = v_139
      v_149 = v_141
      v_151 = v_143
      v_153 = v_134
      v_155 = v_135
      ArenaResult{v_159, +v_160} = core_shift_terms(v_16, v_5, v_7, v_9, v_151)
      ArenaResult{v_165, +v_166} = core_shift_at(v_159, v_153, v_5, v_7, Nat.add(v_9, arena_names_length(v_145)))
      v_50000374 = arena_names_start(v_145)
      v_50000375 = arena_names_count(v_145)
      v_50000376 = arena_naturals_start(v_147)
      v_50000377 = arena_naturals_count(v_147)
      v_50000378 = arena_quantities_start(v_149)
      v_50000379 = arena_quantities_count(v_149)
      v_50000380 = arena_words_start(v_160)
      v_50000381 = arena_words_count(v_160)
      ArenaResult{v_178, +v_179} = arena_put_node(v_165, Arena.TermLet{v_50000374, v_50000375, v_50000376, v_50000377, v_50000378, v_50000379, v_50000380, v_50000381, v_166, v_155})
      {ArenaResult{v_178, v_179} : ArenaResult<U32>}
    case Arena.TermAnn{+v_183, +v_184, +v_185}:
      v_187 = v_183
      v_189 = v_184
      v_191 = v_185
      ArenaResult{v_195, +v_196} = core_shift_at(v_16, v_187, v_5, v_7, v_9)
      ArenaResult{v_200, +v_201} = core_shift_at(v_195, v_189, v_5, v_7, v_9)
      ArenaResult{v_205, +v_206} = arena_put_node(v_200, Arena.TermAnn{v_196, v_201, v_191})
      {ArenaResult{v_205, v_206} : ArenaResult<U32>}
    case Arena.TermTemplate{+v_209, +v_210}:
      v_212 = v_209
      v_214 = v_210
      ArenaResult{v_218, +v_219} = core_shift_at(v_16, v_212, v_5, v_7, v_9)
      ArenaResult{v_223, +v_224} = arena_put_node(v_218, Arena.TermTemplate{v_219, v_214})
      {ArenaResult{v_223, v_224} : ArenaResult<U32>}
    case Arena.TermType{+v_227, +v_228}:
      v_230 = v_227
      v_232 = v_228
      ArenaResult{v_236, +v_237} = core_shift_at(v_16, v_230, v_5, v_7, v_9)
      ArenaResult{v_241, +v_242} = arena_put_node(v_236, Arena.TermType{v_237, v_232})
      {ArenaResult{v_241, v_242} : ArenaResult<U32>}
    case Arena.TermQuant{}:
      ArenaResult{v_246, +v_247} = arena_put_node(v_16, Arena.TermQuant{})
      {ArenaResult{v_246, v_247} : ArenaResult<U32>}
    case Arena.TermQuantity{+v_250, +v_251}:
      v_253 = v_250
      v_255 = v_251
      ArenaResult{v_259, +v_260} = arena_put_node(v_16, Arena.TermQuantity{v_253, v_255})
      {ArenaResult{v_259, v_260} : ArenaResult<U32>}
    case Arena.TermMin{+v_264, +v_265, +v_266}:
      v_268 = v_264
      v_270 = v_265
      v_272 = v_266
      ArenaResult{v_276, +v_277} = core_shift_at(v_16, v_268, v_5, v_7, v_9)
      ArenaResult{v_281, +v_282} = core_shift_at(v_276, v_270, v_5, v_7, v_9)
      ArenaResult{v_286, +v_287} = arena_put_node(v_281, Arena.TermMin{v_277, v_282, v_272})
      {ArenaResult{v_286, v_287} : ArenaResult<U32>}
    case Arena.TermAll{+v_294, +v_295, +v_296, +v_297, +v_298, +v_299}:
      ArenaResult{v_303, +v_304} = arena_name_text(v_16, v_295)
      +v_306 = v_304
      v_308 = v_294
      v_310 = v_306
      v_312 = v_296
      v_314 = v_297
      v_316 = v_298
      v_318 = v_299
      ArenaResult{v_322, +v_323} = core_shift_at(v_303, v_314, v_5, v_7, v_9)
      ArenaResult{v_327, +v_328} = core_shift_at(v_322, v_316, v_5, v_7, Nat.add(v_9, 1n))
      ArenaResult{v_332, +v_333} = arena_name(v_327, v_310)
      ArenaResult{v_337, +v_338} = arena_put_node(v_332, Arena.TermAll{v_308, v_333, v_312, v_323, v_328, v_318})
      {ArenaResult{v_337, v_338} : ArenaResult<U32>}
    case Arena.TermLam{+v_344, +v_345, +v_346, +v_347, +v_348}:
      ArenaResult{v_352, +v_353} = arena_name_text(v_16, v_345)
      +v_355 = v_353
      v_357 = v_344
      v_359 = v_355
      v_361 = v_346
      v_363 = v_347
      v_365 = v_348
      ArenaResult{v_369, +v_370} = core_shift_at(v_352, v_363, v_5, v_7, Nat.add(v_9, 1n))
      ArenaResult{v_374, +v_375} = arena_name(v_369, v_359)
      ArenaResult{v_379, +v_380} = arena_put_node(v_374, Arena.TermLam{v_357, v_375, v_361, v_370, v_365})
      {ArenaResult{v_379, v_380} : ArenaResult<U32>}
    case Arena.TermApp{+v_384, +v_385, +v_386}:
      v_388 = v_384
      v_390 = v_385
      v_392 = v_386
      ArenaResult{v_396, +v_397} = core_shift_at(v_16, v_388, v_5, v_7, v_9)
      ArenaResult{v_401, +v_402} = core_shift_at(v_396, v_390, v_5, v_7, v_9)
      ArenaResult{v_406, +v_407} = arena_put_node(v_401, Arena.TermApp{v_397, v_402, v_392})
      {ArenaResult{v_406, v_407} : ArenaResult<U32>}
    case Arena.TermAdt{+v_414, +v_415, +v_416, +v_417, +v_418, +v_419}:
      ArenaResult{v_423, +v_424} = arena_name_text(v_16, v_414)
      +v_426 = v_424
      +v_428 = IR.Words{v_415, v_416}
      +v_430 = IR.Names{v_417, v_418}
      v_432 = v_426
      v_434 = v_428
      v_436 = v_430
      v_438 = v_419
      ArenaResult{v_442, +v_443} = core_shift_terms(v_423, v_5, v_7, v_9, v_434)
      ArenaResult{v_447, +v_448} = arena_name(v_442, v_432)
      v_50000382 = arena_words_start(v_443)
      v_50000383 = arena_words_count(v_443)
      v_50000384 = arena_names_start(v_436)
      v_50000385 = arena_names_count(v_436)
      ArenaResult{v_456, +v_457} = arena_put_node(v_447, Arena.TermAdt{v_448, v_50000382, v_50000383, v_50000384, v_50000385, v_438})
      {ArenaResult{v_456, v_457} : ArenaResult<U32>}
    case Arena.TermFill{+v_462, +v_463, +v_464, +v_465}:
      +v_467 = IR.Words{v_463, v_464}
      v_469 = v_462
      v_471 = v_467
      v_473 = v_465
      ArenaResult{v_477, +v_478} = core_shift_at(v_16, v_469, v_5, v_7, v_9)
      ArenaResult{v_482, +v_483} = core_shift_terms(v_477, v_5, v_7, v_9, v_471)
      v_50000386 = arena_words_start(v_483)
      v_50000387 = arena_words_count(v_483)
      ArenaResult{v_489, +v_490} = arena_put_node(v_482, Arena.TermFill{v_478, v_50000386, v_50000387, v_473})
      {ArenaResult{v_489, v_490} : ArenaResult<U32>}
    case Arena.TermPlus{+v_495, +v_496, +v_497, +v_498}:
      +v_500 = IR.Words{v_496, v_497}
      v_502 = v_495
      v_504 = v_500
      v_506 = v_498
      ArenaResult{v_510, +v_511} = core_shift_at(v_16, v_502, v_5, v_7, v_9)
      ArenaResult{v_515, +v_516} = core_shift_terms(v_510, v_5, v_7, v_9, v_504)
      v_50000388 = arena_words_start(v_516)
      v_50000389 = arena_words_count(v_516)
      ArenaResult{v_522, +v_523} = arena_put_node(v_515, Arena.TermPlus{v_511, v_50000388, v_50000389, v_506})
      {ArenaResult{v_522, v_523} : ArenaResult<U32>}
    case Arena.TermString{_, _, _}:
      {ArenaResult{v_16, v_3} : ArenaResult<U32>}
    case Arena.TermCtr{+v_528, +v_529, +v_530, +v_531}:
      ArenaResult{v_535, +v_536} = arena_name_text(v_16, v_528)
      +v_538 = v_536
      +v_540 = IR.Words{v_529, v_530}
      v_542 = v_538
      v_544 = v_540
      v_546 = v_531
      ArenaResult{v_550, +v_551} = core_shift_terms(v_535, v_5, v_7, v_9, v_544)
      ArenaResult{v_555, +v_556} = arena_name(v_550, v_542)
      v_50000390 = arena_words_start(v_551)
      v_50000391 = arena_words_count(v_551)
      ArenaResult{v_562, +v_563} = arena_put_node(v_555, Arena.TermCtr{v_556, v_50000390, v_50000391, v_546})
      {ArenaResult{v_562, v_563} : ArenaResult<U32>}
    case Arena.TermMat{+v_568, +v_569, +v_570, +v_571}:
      ArenaResult{v_575, +v_576} = arena_name_text(v_16, v_568)
      +v_578 = v_576
      v_580 = v_578
      v_582 = v_569
      v_584 = v_570
      v_586 = v_571
      ArenaResult{v_590, +v_591} = core_shift_at(v_575, v_582, v_5, v_7, v_9)
      ArenaResult{v_595, +v_596} = core_shift_at(v_590, v_584, v_5, v_7, v_9)
      ArenaResult{v_600, +v_601} = arena_name(v_595, v_580)
      ArenaResult{v_605, +v_606} = arena_put_node(v_600, Arena.TermMat{v_601, v_591, v_596, v_586})
      {ArenaResult{v_605, v_606} : ArenaResult<U32>}
    case Arena.TermAbsurd{+v_608}:
      v_610 = v_608
      ArenaResult{v_614, +v_615} = arena_put_node(v_16, Arena.TermAbsurd{v_610})
      {ArenaResult{v_614, v_615} : ArenaResult<U32>}
    case Arena.TermEqual{+v_620, +v_621, +v_622, +v_623}:
      v_625 = v_620
      v_627 = v_621
      v_629 = v_622
      v_631 = v_623
      ArenaResult{v_635, +v_636} = core_shift_at(v_16, v_625, v_5, v_7, v_9)
      ArenaResult{v_640, +v_641} = core_shift_at(v_635, v_627, v_5, v_7, v_9)
      ArenaResult{v_645, +v_646} = core_shift_at(v_640, v_629, v_5, v_7, v_9)
      ArenaResult{v_650, +v_651} = arena_put_node(v_645, Arena.TermEqual{v_636, v_641, v_646, v_631})
      {ArenaResult{v_650, v_651} : ArenaResult<U32>}
    case Arena.TermRefl{+v_653}:
      v_655 = v_653
      ArenaResult{v_659, +v_660} = arena_put_node(v_16, Arena.TermRefl{v_655})
      {ArenaResult{v_659, v_660} : ArenaResult<U32>}
    case Arena.TermRewrite{+v_665, +v_666, +v_667, +v_668}:
      v_670 = v_665
      v_672 = v_666
      v_674 = v_667
      v_676 = v_668
      ArenaResult{v_680, +v_681} = core_shift_at(v_16, v_670, v_5, v_7, v_9)
      ArenaResult{v_685, +v_686} = core_shift_at(v_680, v_672, v_5, v_7, v_9)
      ArenaResult{v_690, +v_691} = core_shift_at(v_685, v_674, v_5, v_7, v_9)
      ArenaResult{v_695, +v_696} = arena_put_node(v_690, Arena.TermRewrite{v_681, v_686, v_691, v_676})
      {ArenaResult{v_695, v_696} : ArenaResult<U32>}
    case Arena.TermHole{+v_699, +v_700}:
      ArenaResult{v_704, +v_705} = arena_name_text(v_16, v_699)
      +v_707 = v_705
      v_709 = v_707
      v_711 = v_700
      ArenaResult{v_715, +v_716} = arena_name(v_704, v_709)
      ArenaResult{v_720, +v_721} = arena_put_node(v_715, Arena.TermHole{v_716, v_711})
      {ArenaResult{v_720, v_721} : ArenaResult<U32>}
    case Arena.BodyMatch{+v_727, +v_728, +v_729, +v_730, +v_731}:
      +v_733 = IR.Words{v_727, v_728}
      +v_735 = IR.Words{v_729, v_730}
      v_737 = v_733
      v_739 = v_735
      v_741 = v_731
      ArenaResult{v_745, +v_746} = core_shift_terms(v_16, v_5, v_7, v_9, v_737)
      ArenaResult{v_750, +v_751} = core_shift_terms(v_745, v_5, v_7, v_9, v_739)
      v_50000392 = arena_words_start(v_746)
      v_50000393 = arena_words_count(v_746)
      v_50000394 = arena_words_start(v_751)
      v_50000395 = arena_words_count(v_751)
      ArenaResult{v_759, +v_760} = arena_put_node(v_750, Arena.BodyMatch{v_50000392, v_50000393, v_50000394, v_50000395, v_741})
      {ArenaResult{v_759, v_760} : ArenaResult<U32>}
    case Arena.BodyCase{+v_765, +v_766, +v_767, +v_768}:
      +v_770 = IR.Words{v_765, v_766}
      +v_772 = v_770
      v_774 = v_767
      v_776 = v_768
      ArenaResult{v_780, +v_781} = core_pattern_list_depth(v_16, v_772)
      ArenaResult{v_785, +v_786} = core_shift_at(v_780, v_774, v_5, v_7, Nat.add(v_9, v_781))
      v_50000396 = arena_words_start(v_772)
      v_50000397 = arena_words_count(v_772)
      ArenaResult{v_792, +v_793} = arena_put_node(v_785, Arena.BodyCase{v_50000396, v_50000397, v_786, v_776})
      {ArenaResult{v_792, v_793} : ArenaResult<U32>}
    case Arena.BodyLocal{+v_801, +v_802, +v_803, +v_804, +v_805, +v_806, +v_807}:
      +v_809 = IR.Words{v_801, v_802}
      +v_811 = IR.Words{v_804, v_805}
      +v_813 = v_809
      v_815 = v_803
      v_817 = v_811
      v_819 = v_806
      v_821 = v_807
      ArenaResult{v_825, +v_826} = core_shift_terms(v_16, v_5, v_7, v_9, v_817)
      ArenaResult{v_830, +v_831} = core_pattern_list_depth(v_825, v_813)
      ArenaResult{v_835, +v_836} = core_shift_at(v_830, v_819, v_5, v_7, Nat.add(v_9, v_831))
      v_50000398 = arena_words_start(v_813)
      v_50000399 = arena_words_count(v_813)
      v_50000400 = arena_words_start(v_826)
      v_50000401 = arena_words_count(v_826)
      ArenaResult{v_844, +v_845} = arena_put_node(v_835, Arena.BodyLocal{v_50000398, v_50000399, v_815, v_50000400, v_50000401, v_836, v_821})
      {ArenaResult{v_844, v_845} : ArenaResult<U32>}
    case Arena.BodyReply{+v_848, +v_849}:
      v_851 = v_848
      v_853 = v_849
      ArenaResult{v_857, +v_858} = core_shift_at(v_16, v_851, v_5, v_7, v_9)
      ArenaResult{v_862, +v_863} = arena_put_node(v_857, Arena.BodyReply{v_858, v_853})
      {ArenaResult{v_862, v_863} : ArenaResult<U32>}

def core_shift(v_20042566: ArenaStore, v_1: Nat, v_3: Nat, v_4: U32) -> ArenaResult<U32>:
  match v_3:
    case 0n:
      {ArenaResult{v_20042566, v_4} : ArenaResult<U32>}
    case _:
      ArenaResult{v_20042568, +v_20042569} = core_shift_at(v_20042566, v_4, v_1, v_3, 0n)
      {ArenaResult{v_20042568, v_20042569} : ArenaResult<U32>}

def core_subst_var(v_20042570: ArenaStore, v_1: Bool, v_3: Bool, v_5: Nat, v_6: U32, v_8: String, v_10: Nat, v_11: Ast.SourceSpan) -> ArenaResult<U32>:
  match v_1:
    case True{}:
      ArenaResult{v_20042571, +v_20042572} = core_shift(v_20042570, 0n, v_5, v_6)
      {ArenaResult{v_20042571, v_20042572} : ArenaResult<U32>}
    case False{}:
      match v_3:
        case True{}:
          ArenaResult{v_20042573, +v_20042574} = arena_name(v_20042570, v_8)
          ArenaResult{v_20042575, +v_20042576} = arena_put_node(v_20042573, Arena.TermVar{v_20042574, Nat.sub(v_10, 1n), v_11})
          {ArenaResult{v_20042575, v_20042576} : ArenaResult<U32>}
        case False{}:
          ArenaResult{v_20042577, +v_20042578} = arena_name(v_20042570, v_8)
          ArenaResult{v_20042579, +v_20042580} = arena_put_node(v_20042577, Arena.TermVar{v_20042578, v_10, v_11})
          {ArenaResult{v_20042579, v_20042580} : ArenaResult<U32>}

# Memoize immutable published source/transient signatures until rewind. The guard
# runs first; misses execute the complete original substitution before publishing
# a result handle. Hits retain the current threaded store, not a saved snapshot.
def core_subst_memo_saved(index: Nat, value: U32, depth: Nat, id: U32, result: ArenaResult<U32>) -> ArenaResult<U32>:
  match result:
    case ArenaResult{store, +output}:
      {ArenaResult{arena_subst_memo_store(store, id, index, value, depth, output), output} : ArenaResult<U32>}

def core_subst_memo_found(+index: Nat, +value: U32, +depth: Nat, +id: U32, result: ArenaResult<Maybe<&2, U32>>) -> ArenaResult<U32>:
  match result:
    case ArenaResult{store, found}:
      match found:
        case Some{output}: {ArenaResult{store, output} : ArenaResult<U32>}
        case None{}: core_subst_memo_saved(index, value, depth, id, core_subst_open(store, index, value, depth, id))

def core_subst_unaffected(arena: ArenaStore, unaffected: Bool, +index: Nat, +value: U32, +depth: Nat, +id: U32) -> ArenaResult<U32>:
  match unaffected:
    case True{}: {ArenaResult{arena, id} : ArenaResult<U32>}
    case False{}: core_subst_memo_found(index, value, depth, id, arena_subst_memo_lookup(arena, id, index, value, depth))

def core_subst_at(arena: ArenaStore, +index: Nat, value: U32, +depth: Nat, +id: U32) -> ArenaResult<U32>:
  ArenaResult{next, encoded} = arena_node_bound(arena, id)
  core_subst_unaffected(next, core_bound_unaffected(encoded, Nat.add(index, depth)), index, value, depth, id)

def core_subst_open(v_1: ArenaStore, +v_3: Nat, +v_5: U32, +v_7: Nat, v_9: U32) -> ArenaResult<U32>:
  ArenaResult{v_16, +v_17} = arena_get_node(v_1, v_9)
  match v_17:
    case Arena.TermVar{+v_21, +v_22, +v_23}:
      ArenaResult{v_27, +v_28} = arena_name_text(v_16, v_21)
      +v_30 = v_28
      v_32 = v_30
      +v_34 = v_22
      v_36 = v_23
      +v_38 = Nat.add(v_3, v_7)
      ArenaResult{v_42, +v_43} = core_subst_var(v_27, Nat.is_eq(v_34, v_38), Nat.is_gt(v_34, v_38), v_7, v_5, v_32, v_34, v_36)
      {ArenaResult{v_42, v_43} : ArenaResult<U32>}
    case Arena.TermRef{+v_46, +v_47}:
      {ArenaResult{v_16, v_9} : ArenaResult<U32>}
    case Arena.TermBang{+v_71, +v_72}:
      v_74 = v_71
      v_76 = v_72
      ArenaResult{v_80, +v_81} = core_subst_at(v_16, v_3, v_5, v_7, v_74)
      ArenaResult{v_85, +v_86} = arena_put_node(v_80, Arena.TermBang{v_81, v_76})
      {ArenaResult{v_85, v_86} : ArenaResult<U32>}
    case Arena.TermSub{+v_91, +v_92, +v_93, +v_94}:
      v_96 = v_91
      v_98 = v_92
      v_100 = v_93
      v_102 = v_94
      ArenaResult{v_106, +v_107} = core_subst_at(v_16, v_3, v_5, v_7, v_98)
      ArenaResult{v_111, +v_112} = core_subst_at(v_106, v_3, v_5, Nat.add(v_7, 1n), v_100)
      ArenaResult{v_116, +v_117} = arena_put_node(v_111, Arena.TermSub{v_96, v_107, v_112, v_102})
      {ArenaResult{v_116, v_117} : ArenaResult<U32>}
    case Arena.TermLet{+v_128, +v_129, +v_130, +v_131, +v_132, +v_133, +v_134, +v_135, +v_136, +v_137}:
      +v_139 = IR.Names{v_128, v_129}
      +v_141 = IR.Naturals{v_130, v_131}
      +v_143 = IR.Quantities{v_132, v_133}
      +v_145 = IR.Words{v_134, v_135}
      +v_147 = v_139
      v_149 = v_141
      v_151 = v_143
      v_153 = v_145
      v_155 = v_136
      v_157 = v_137
      ArenaResult{v_161, +v_162} = core_subst_terms(v_16, v_3, v_5, v_7, v_153)
      ArenaResult{v_167, +v_168} = core_subst_at(v_161, v_3, v_5, Nat.add(v_7, arena_names_length(v_147)), v_155)
      v_50000402 = arena_names_start(v_147)
      v_50000403 = arena_names_count(v_147)
      v_50000404 = arena_naturals_start(v_149)
      v_50000405 = arena_naturals_count(v_149)
      v_50000406 = arena_quantities_start(v_151)
      v_50000407 = arena_quantities_count(v_151)
      v_50000408 = arena_words_start(v_162)
      v_50000409 = arena_words_count(v_162)
      ArenaResult{v_180, +v_181} = arena_put_node(v_167, Arena.TermLet{v_50000402, v_50000403, v_50000404, v_50000405, v_50000406, v_50000407, v_50000408, v_50000409, v_168, v_157})
      {ArenaResult{v_180, v_181} : ArenaResult<U32>}
    case Arena.TermAnn{+v_185, +v_186, +v_187}:
      v_189 = v_185
      v_191 = v_186
      v_193 = v_187
      ArenaResult{v_197, +v_198} = core_subst_at(v_16, v_3, v_5, v_7, v_189)
      ArenaResult{v_202, +v_203} = core_subst_at(v_197, v_3, v_5, v_7, v_191)
      ArenaResult{v_207, +v_208} = arena_put_node(v_202, Arena.TermAnn{v_198, v_203, v_193})
      {ArenaResult{v_207, v_208} : ArenaResult<U32>}
    case Arena.TermTemplate{+v_211, +v_212}:
      v_214 = v_211
      v_216 = v_212
      ArenaResult{v_220, +v_221} = core_subst_at(v_16, v_3, v_5, v_7, v_214)
      ArenaResult{v_225, +v_226} = arena_put_node(v_220, Arena.TermTemplate{v_221, v_216})
      {ArenaResult{v_225, v_226} : ArenaResult<U32>}
    case Arena.TermType{+v_229, +v_230}:
      v_232 = v_229
      v_234 = v_230
      ArenaResult{v_238, +v_239} = core_subst_at(v_16, v_3, v_5, v_7, v_232)
      ArenaResult{v_243, +v_244} = arena_put_node(v_238, Arena.TermType{v_239, v_234})
      {ArenaResult{v_243, v_244} : ArenaResult<U32>}
    case Arena.TermQuant{}:
      ArenaResult{v_248, +v_249} = arena_put_node(v_16, Arena.TermQuant{})
      {ArenaResult{v_248, v_249} : ArenaResult<U32>}
    case Arena.TermQuantity{+v_252, +v_253}:
      v_255 = v_252
      v_257 = v_253
      ArenaResult{v_261, +v_262} = arena_put_node(v_16, Arena.TermQuantity{v_255, v_257})
      {ArenaResult{v_261, v_262} : ArenaResult<U32>}
    case Arena.TermMin{+v_266, +v_267, +v_268}:
      v_270 = v_266
      v_272 = v_267
      v_274 = v_268
      ArenaResult{v_278, +v_279} = core_subst_at(v_16, v_3, v_5, v_7, v_270)
      ArenaResult{v_283, +v_284} = core_subst_at(v_278, v_3, v_5, v_7, v_272)
      ArenaResult{v_288, +v_289} = arena_put_node(v_283, Arena.TermMin{v_279, v_284, v_274})
      {ArenaResult{v_288, v_289} : ArenaResult<U32>}
    case Arena.TermAll{+v_296, +v_297, +v_298, +v_299, +v_300, +v_301}:
      ArenaResult{v_305, +v_306} = arena_name_text(v_16, v_297)
      +v_308 = v_306
      v_310 = v_296
      v_312 = v_308
      v_314 = v_298
      v_316 = v_299
      v_318 = v_300
      v_320 = v_301
      ArenaResult{v_324, +v_325} = core_subst_at(v_305, v_3, v_5, v_7, v_316)
      ArenaResult{v_329, +v_330} = core_subst_at(v_324, v_3, v_5, Nat.add(v_7, 1n), v_318)
      ArenaResult{v_334, +v_335} = arena_name(v_329, v_312)
      ArenaResult{v_339, +v_340} = arena_put_node(v_334, Arena.TermAll{v_310, v_335, v_314, v_325, v_330, v_320})
      {ArenaResult{v_339, v_340} : ArenaResult<U32>}
    case Arena.TermLam{+v_346, +v_347, +v_348, +v_349, +v_350}:
      ArenaResult{v_354, +v_355} = arena_name_text(v_16, v_347)
      +v_357 = v_355
      v_359 = v_346
      v_361 = v_357
      v_363 = v_348
      v_365 = v_349
      v_367 = v_350
      ArenaResult{v_371, +v_372} = core_subst_at(v_354, v_3, v_5, Nat.add(v_7, 1n), v_365)
      ArenaResult{v_376, +v_377} = arena_name(v_371, v_361)
      ArenaResult{v_381, +v_382} = arena_put_node(v_376, Arena.TermLam{v_359, v_377, v_363, v_372, v_367})
      {ArenaResult{v_381, v_382} : ArenaResult<U32>}
    case Arena.TermApp{+v_386, +v_387, +v_388}:
      v_390 = v_386
      v_392 = v_387
      v_394 = v_388
      ArenaResult{v_398, +v_399} = core_subst_at(v_16, v_3, v_5, v_7, v_390)
      ArenaResult{v_403, +v_404} = core_subst_at(v_398, v_3, v_5, v_7, v_392)
      ArenaResult{v_408, +v_409} = arena_put_node(v_403, Arena.TermApp{v_399, v_404, v_394})
      {ArenaResult{v_408, v_409} : ArenaResult<U32>}
    case Arena.TermAdt{+v_416, +v_417, +v_418, +v_419, +v_420, +v_421}:
      ArenaResult{v_425, +v_426} = arena_name_text(v_16, v_416)
      +v_428 = v_426
      +v_430 = IR.Words{v_417, v_418}
      +v_432 = IR.Names{v_419, v_420}
      v_434 = v_428
      v_436 = v_430
      v_438 = v_432
      v_440 = v_421
      ArenaResult{v_444, +v_445} = core_subst_terms(v_425, v_3, v_5, v_7, v_436)
      ArenaResult{v_449, +v_450} = arena_name(v_444, v_434)
      v_50000410 = arena_words_start(v_445)
      v_50000411 = arena_words_count(v_445)
      v_50000412 = arena_names_start(v_438)
      v_50000413 = arena_names_count(v_438)
      ArenaResult{v_458, +v_459} = arena_put_node(v_449, Arena.TermAdt{v_450, v_50000410, v_50000411, v_50000412, v_50000413, v_440})
      {ArenaResult{v_458, v_459} : ArenaResult<U32>}
    case Arena.TermFill{+v_464, +v_465, +v_466, +v_467}:
      +v_469 = IR.Words{v_465, v_466}
      v_471 = v_464
      v_473 = v_469
      v_475 = v_467
      ArenaResult{v_479, +v_480} = core_subst_at(v_16, v_3, v_5, v_7, v_471)
      ArenaResult{v_484, +v_485} = core_subst_terms(v_479, v_3, v_5, v_7, v_473)
      v_50000414 = arena_words_start(v_485)
      v_50000415 = arena_words_count(v_485)
      ArenaResult{v_491, +v_492} = arena_put_node(v_484, Arena.TermFill{v_480, v_50000414, v_50000415, v_475})
      {ArenaResult{v_491, v_492} : ArenaResult<U32>}
    case Arena.TermPlus{+v_497, +v_498, +v_499, +v_500}:
      +v_502 = IR.Words{v_498, v_499}
      v_504 = v_497
      v_506 = v_502
      v_508 = v_500
      ArenaResult{v_512, +v_513} = core_subst_at(v_16, v_3, v_5, v_7, v_504)
      ArenaResult{v_517, +v_518} = core_subst_terms(v_512, v_3, v_5, v_7, v_506)
      v_50000416 = arena_words_start(v_518)
      v_50000417 = arena_words_count(v_518)
      ArenaResult{v_524, +v_525} = arena_put_node(v_517, Arena.TermPlus{v_513, v_50000416, v_50000417, v_508})
      {ArenaResult{v_524, v_525} : ArenaResult<U32>}
    case Arena.TermString{_, _, _}:
      {ArenaResult{v_16, v_9} : ArenaResult<U32>}
    case Arena.TermCtr{+v_530, +v_531, +v_532, +v_533}:
      ArenaResult{v_537, +v_538} = arena_name_text(v_16, v_530)
      +v_540 = v_538
      +v_542 = IR.Words{v_531, v_532}
      v_544 = v_540
      v_546 = v_542
      v_548 = v_533
      ArenaResult{v_552, +v_553} = core_subst_terms(v_537, v_3, v_5, v_7, v_546)
      ArenaResult{v_557, +v_558} = arena_name(v_552, v_544)
      v_50000418 = arena_words_start(v_553)
      v_50000419 = arena_words_count(v_553)
      ArenaResult{v_564, +v_565} = arena_put_node(v_557, Arena.TermCtr{v_558, v_50000418, v_50000419, v_548})
      {ArenaResult{v_564, v_565} : ArenaResult<U32>}
    case Arena.TermMat{+v_570, +v_571, +v_572, +v_573}:
      ArenaResult{v_577, +v_578} = arena_name_text(v_16, v_570)
      +v_580 = v_578
      v_582 = v_580
      v_584 = v_571
      v_586 = v_572
      v_588 = v_573
      ArenaResult{v_592, +v_593} = core_subst_at(v_577, v_3, v_5, v_7, v_584)
      ArenaResult{v_597, +v_598} = core_subst_at(v_592, v_3, v_5, v_7, v_586)
      ArenaResult{v_602, +v_603} = arena_name(v_597, v_582)
      ArenaResult{v_607, +v_608} = arena_put_node(v_602, Arena.TermMat{v_603, v_593, v_598, v_588})
      {ArenaResult{v_607, v_608} : ArenaResult<U32>}
    case Arena.TermAbsurd{+v_610}:
      v_612 = v_610
      ArenaResult{v_616, +v_617} = arena_put_node(v_16, Arena.TermAbsurd{v_612})
      {ArenaResult{v_616, v_617} : ArenaResult<U32>}
    case Arena.TermEqual{+v_622, +v_623, +v_624, +v_625}:
      v_627 = v_622
      v_629 = v_623
      v_631 = v_624
      v_633 = v_625
      ArenaResult{v_637, +v_638} = core_subst_at(v_16, v_3, v_5, v_7, v_627)
      ArenaResult{v_642, +v_643} = core_subst_at(v_637, v_3, v_5, v_7, v_629)
      ArenaResult{v_647, +v_648} = core_subst_at(v_642, v_3, v_5, v_7, v_631)
      ArenaResult{v_652, +v_653} = arena_put_node(v_647, Arena.TermEqual{v_638, v_643, v_648, v_633})
      {ArenaResult{v_652, v_653} : ArenaResult<U32>}
    case Arena.TermRefl{+v_655}:
      v_657 = v_655
      ArenaResult{v_661, +v_662} = arena_put_node(v_16, Arena.TermRefl{v_657})
      {ArenaResult{v_661, v_662} : ArenaResult<U32>}
    case Arena.TermRewrite{+v_667, +v_668, +v_669, +v_670}:
      v_672 = v_667
      v_674 = v_668
      v_676 = v_669
      v_678 = v_670
      ArenaResult{v_682, +v_683} = core_subst_at(v_16, v_3, v_5, v_7, v_672)
      ArenaResult{v_687, +v_688} = core_subst_at(v_682, v_3, v_5, v_7, v_674)
      ArenaResult{v_692, +v_693} = core_subst_at(v_687, v_3, v_5, v_7, v_676)
      ArenaResult{v_697, +v_698} = arena_put_node(v_692, Arena.TermRewrite{v_683, v_688, v_693, v_678})
      {ArenaResult{v_697, v_698} : ArenaResult<U32>}
    case Arena.TermHole{+v_701, +v_702}:
      ArenaResult{v_706, +v_707} = arena_name_text(v_16, v_701)
      +v_709 = v_707
      v_711 = v_709
      v_713 = v_702
      ArenaResult{v_717, +v_718} = arena_name(v_706, v_711)
      ArenaResult{v_722, +v_723} = arena_put_node(v_717, Arena.TermHole{v_718, v_713})
      {ArenaResult{v_722, v_723} : ArenaResult<U32>}
    case Arena.BodyMatch{+v_729, +v_730, +v_731, +v_732, +v_733}:
      +v_735 = IR.Words{v_729, v_730}
      +v_737 = IR.Words{v_731, v_732}
      v_739 = v_735
      v_741 = v_737
      v_743 = v_733
      ArenaResult{v_747, +v_748} = core_subst_terms(v_16, v_3, v_5, v_7, v_739)
      ArenaResult{v_752, +v_753} = core_subst_terms(v_747, v_3, v_5, v_7, v_741)
      v_50000420 = arena_words_start(v_748)
      v_50000421 = arena_words_count(v_748)
      v_50000422 = arena_words_start(v_753)
      v_50000423 = arena_words_count(v_753)
      ArenaResult{v_761, +v_762} = arena_put_node(v_752, Arena.BodyMatch{v_50000420, v_50000421, v_50000422, v_50000423, v_743})
      {ArenaResult{v_761, v_762} : ArenaResult<U32>}
    case Arena.BodyCase{+v_767, +v_768, +v_769, +v_770}:
      +v_772 = IR.Words{v_767, v_768}
      +v_774 = v_772
      v_776 = v_769
      v_778 = v_770
      ArenaResult{v_782, +v_783} = core_pattern_list_depth(v_16, v_774)
      ArenaResult{v_787, +v_788} = core_subst_at(v_782, v_3, v_5, Nat.add(v_7, v_783), v_776)
      v_50000424 = arena_words_start(v_774)
      v_50000425 = arena_words_count(v_774)
      ArenaResult{v_794, +v_795} = arena_put_node(v_787, Arena.BodyCase{v_50000424, v_50000425, v_788, v_778})
      {ArenaResult{v_794, v_795} : ArenaResult<U32>}
    case Arena.BodyLocal{+v_803, +v_804, +v_805, +v_806, +v_807, +v_808, +v_809}:
      +v_811 = IR.Words{v_803, v_804}
      +v_813 = IR.Words{v_806, v_807}
      +v_815 = v_811
      v_817 = v_805
      v_819 = v_813
      v_821 = v_808
      v_823 = v_809
      ArenaResult{v_827, +v_828} = core_subst_terms(v_16, v_3, v_5, v_7, v_819)
      ArenaResult{v_832, +v_833} = core_pattern_list_depth(v_827, v_815)
      ArenaResult{v_837, +v_838} = core_subst_at(v_832, v_3, v_5, Nat.add(v_7, v_833), v_821)
      v_50000426 = arena_words_start(v_815)
      v_50000427 = arena_words_count(v_815)
      v_50000428 = arena_words_start(v_828)
      v_50000429 = arena_words_count(v_828)
      ArenaResult{v_846, +v_847} = arena_put_node(v_837, Arena.BodyLocal{v_50000426, v_50000427, v_817, v_50000428, v_50000429, v_838, v_823})
      {ArenaResult{v_846, v_847} : ArenaResult<U32>}
    case Arena.BodyReply{+v_850, +v_851}:
      v_853 = v_850
      v_855 = v_851
      ArenaResult{v_859, +v_860} = core_subst_at(v_16, v_3, v_5, v_7, v_853)
      ArenaResult{v_864, +v_865} = arena_put_node(v_859, Arena.BodyReply{v_860, v_855})
      {ArenaResult{v_864, v_865} : ArenaResult<U32>}

def core_subst(v_20042867: ArenaStore, v_1: Nat, v_2: U32, v_3: U32) -> ArenaResult<U32>:
  ArenaResult{v_20042868, +v_20042869} = core_subst_at(v_20042867, v_1, v_2, 0n, v_3)
  {ArenaResult{v_20042868, v_20042869} : ArenaResult<U32>}

def core_shift_terms(v_20042870: ArenaStore, +v_1: Nat, +v_3: Nat, +v_5: Nat, v_7: IR.Words) -> ArenaResult<IR.Words>:
  ArenaResult{v_20042871, +v_20042872} = arena_words_view(v_20042870, v_7)
  match v_20042872:
    case IR.WordNil{}:
      {ArenaResult{v_20042871, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20042873, +v_20042874}:
      v_11 = v_20042873
      v_12 = v_20042874
      ArenaResult{v_20042875, +v_20042876} = core_shift_at(v_20042871, v_11, v_1, v_3, v_5)
      ArenaResult{v_20042877, +v_20042878} = core_shift_terms(v_20042875, v_1, v_3, v_5, v_12)
      ArenaResult{v_20042879, +v_20042880} = arena_words_cons(v_20042877, v_20042876, v_20042878)
      {ArenaResult{v_20042879, v_20042880} : ArenaResult<IR.Words>}

def core_subst_terms(v_20042881: ArenaStore, +v_1: Nat, +v_2: U32, +v_4: Nat, v_6: IR.Words) -> ArenaResult<IR.Words>:
  ArenaResult{v_20042882, +v_20042883} = arena_words_view(v_20042881, v_6)
  match v_20042883:
    case IR.WordNil{}:
      {ArenaResult{v_20042882, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case IR.WordCons{+v_20042884, +v_20042885}:
      v_10 = v_20042884
      v_11 = v_20042885
      ArenaResult{v_20042886, +v_20042887} = core_subst_at(v_20042882, v_1, v_2, v_4, v_10)
      ArenaResult{v_20042888, +v_20042889} = core_subst_terms(v_20042886, v_1, v_2, v_4, v_11)
      ArenaResult{v_20042890, +v_20042891} = arena_words_cons(v_20042888, v_20042887, v_20042889)
      {ArenaResult{v_20042890, v_20042891} : ArenaResult<IR.Words>}


# Source storage is immutable except append-only publication. The second region
# contains per-declaration computations; only published handles may escape rewind.
def arena_is_transient(+id: U32) -> Bool:
  U32.is_ne(U32.and(id, 2147483648), 0)

def arena_is_reverse(+start: U32) -> Bool:
  U32.is_ne(U32.and(start, 1073741824), 0)

def arena_node_offset(id: U32) -> U32:
  U32.and(id, 2147483647)

def arena_tape_offset(id: U32) -> U32:
  U32.and(id, 1073741823)

def arena_range_index_direction(start: U32, offset: U32, reverse: Bool) -> U32:
  match reverse:
    case False{}: U32.add(start, offset)
    case True{}: U32.sub(start, offset)

def arena_range_index(+start: U32, offset: U32) -> U32:
  arena_range_index_direction(start, offset, arena_is_reverse(start))

def arena_range_flip_empty(start: U32, count: U32, empty: Bool) -> U32:
  match empty:
    case True{}: start
    case False{}: U32.xor(arena_range_index(start, U32.sub(count, 1)), 1073741824)

def arena_range_flip(start: U32, +count: U32) -> U32:
  arena_range_flip_empty(start, count, U32.is_eq(count, 0))

# This source-owned cache contains only immutable raw heads, never alias
# conclusions. Complete tape bounds and each indexed head are owner-local;
# any uncertain row becomes a barrier that the original matcher still visits.
def arena_case_prefix_result(transient: Arena.Arena, result: Arena.Arena & Arena.CasePrefixEntry) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case Tuple{source, entry}: {ArenaResult{ArenaStore{source, transient}, entry} : ArenaResult<Arena.CasePrefixEntry>}

def arena_case_prefix_head_result(transient: Arena.Arena, result: Arena.Arena & Maybe<&2, String>) -> ArenaResult<Maybe<&2, String>>:
  match result:
    case Tuple{source, head}: {ArenaResult{ArenaStore{source, transient}, head} : ArenaResult<Maybe<&2, String>>}

def arena_case_prefix_head(store: ArenaStore, id: U32) -> ArenaResult<Maybe<&2, String>>:
  match store:
    case ArenaStore{source, transient}: arena_case_prefix_head_result(transient, Arena.case_prefix_head(source, id))

def arena_case_prefix_save(store: ArenaStore, +start: U32, +count: U32, +heads: Map<&2, U32>, +barrier: U32) -> ArenaResult<Arena.CasePrefixEntry>:
  match store:
    case ArenaStore{source, transient}:
      {ArenaResult{ArenaStore{Arena.case_prefix_put(source, start, count, heads, barrier, 0n), transient}, Arena.CasePrefixSaved{start, count, heads, barrier, 0n}} : ArenaResult<Arena.CasePrefixEntry>}

def arena_case_prefix_build_head(request: CasePrefixBuild, result: ArenaResult<Maybe<&2, String>>) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case ArenaResult{store, head}:
      match request:
        case CasePrefixBuild{+start, +count, cursor, +offset, remaining, heads}:
          match head:
            case None{}: arena_case_prefix_save(store, start, count, heads, offset)
            case Some{name}:
              arena_case_prefix_build(store, CasePrefixBuild{start, count, arena_range_index(cursor, 1), U32.add(offset, 1), remaining, Arena.case_prefix_first(heads, name, offset)})

def arena_case_prefix_build_word(request: CasePrefixBuild, result: ArenaResult<U32>) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case ArenaResult{store, id}: arena_case_prefix_build_head(request, arena_case_prefix_head(store, id))

def arena_case_prefix_build(store: ArenaStore, request: CasePrefixBuild) -> ArenaResult<Arena.CasePrefixEntry>:
  match request:
    case CasePrefixBuild{+start, +count, +cursor, offset, remaining, heads}:
      match remaining:
        case 0n: arena_case_prefix_save(store, start, count, heads, offset)
        case 1n+rest:
          arena_case_prefix_build_word(CasePrefixBuild{start, count, cursor, offset, rest, heads}, arena_get_word(store, cursor))

def arena_case_prefix_valid(transient: Arena.Arena, +start: U32, +count: U32, result: Arena.Arena & Bool) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case Tuple{source, valid}:
      match valid:
        case False{}: {ArenaResult{ArenaStore{source, transient}, Arena.CasePrefixEmpty{}} : ArenaResult<Arena.CasePrefixEntry>}
        case True{}:
          arena_case_prefix_build(ArenaStore{source, transient}, CasePrefixBuild{start, count, start, 0, U32.to_nat(count), Map.new(&2, U32)})

def arena_case_prefix_miss(store: ArenaStore, +start: U32, +count: U32) -> ArenaResult<Arena.CasePrefixEntry>:
  match store:
    case ArenaStore{source, transient}: arena_case_prefix_valid(transient, start, count, Arena.case_prefix_range_valid(source, start, count))

def arena_case_prefix_cached_exact(store: ArenaStore, start: U32, count: U32, entry: Arena.CasePrefixEntry, same: Bool) -> ArenaResult<Arena.CasePrefixEntry>:
  match same:
    case False{}: arena_case_prefix_miss(store, start, count)
    case True{}: {ArenaResult{store, entry} : ArenaResult<Arena.CasePrefixEntry>}

def arena_case_prefix_cached(+start: U32, +count: U32, result: ArenaResult<Arena.CasePrefixEntry>) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case ArenaResult{store, entry}:
      match entry:
        case Arena.CasePrefixEmpty{}: arena_case_prefix_miss(store, start, count)
        case Arena.CasePrefixSaved{+saved_start, +saved_count, heads, barrier, generation}:
          arena_case_prefix_cached_exact(store, start, count, Arena.CasePrefixSaved{saved_start, saved_count, heads, barrier, generation}, Bool.and(U32.is_eq(start, saved_start), U32.is_eq(count, saved_count)))

# Transient raw-head indexes survive append-only computation within a declaration.
# Rewind discards their owning cache; a source rewind generation also invalidates
# mixed-owner indexes. Aliases and the original ordered matcher remain uncached.
def arena_case_prefix_local_valid_result(other: Arena.Arena, result: Arena.Arena & Bool, temporary: Bool) -> ArenaResult<Bool>:
  match result:
    case Tuple{arena, valid}:
      match temporary:
        case False{}: {ArenaResult{ArenaStore{arena, other}, valid} : ArenaResult<Bool>}
        case True{}: {ArenaResult{ArenaStore{other, arena}, valid} : ArenaResult<Bool>}

def arena_case_prefix_local_range_region(source: Arena.Arena, transient: Arena.Arena, start: U32, count: U32, temporary: Bool) -> ArenaResult<Bool>:
  match temporary:
    case False{}: arena_case_prefix_local_valid_result(transient, Arena.case_prefix_range_valid(source, start, count), False{})
    case True{}: arena_case_prefix_local_valid_result(source, Arena.case_prefix_range_valid(transient, U32.and(start, 2147483647), count), True{})

def arena_case_prefix_local_range(store: ArenaStore, +start: U32, count: U32) -> ArenaResult<Bool>:
  match store:
    case ArenaStore{source, transient}: arena_case_prefix_local_range_region(source, transient, start, count, arena_is_transient(start))

def arena_case_prefix_local_descriptor(arena: Arena.Arena, id: U32, pattern: Bool) -> Arena.Arena & Bool:
  match pattern:
    case False{}: Arena.case_prefix_node_valid(arena, id)
    case True{}: Arena.case_prefix_pattern_valid(arena, id)

def arena_case_prefix_local_descriptor_region(source: Arena.Arena, transient: Arena.Arena, id: U32, pattern: Bool, temporary: Bool) -> ArenaResult<Bool>:
  match temporary:
    case False{}: arena_case_prefix_local_valid_result(transient, arena_case_prefix_local_descriptor(source, id, pattern), False{})
    case True{}: arena_case_prefix_local_valid_result(source, arena_case_prefix_local_descriptor(transient, arena_node_offset(id), pattern), True{})

def arena_case_prefix_local_descriptor_valid(store: ArenaStore, +id: U32, pattern: Bool) -> ArenaResult<Bool>:
  match store:
    case ArenaStore{source, transient}: arena_case_prefix_local_descriptor_region(source, transient, id, pattern, arena_is_transient(id))

def arena_case_prefix_local_text_result(other: Arena.Arena, result: Arena.Arena & Maybe<&2, String>, temporary: Bool) -> ArenaResult<Maybe<&2, String>>:
  match result:
    case Tuple{arena, head}:
      match temporary:
        case False{}: {ArenaResult{ArenaStore{arena, other}, head} : ArenaResult<Maybe<&2, String>>}
        case True{}: {ArenaResult{ArenaStore{other, arena}, head} : ArenaResult<Maybe<&2, String>>}

def arena_case_prefix_local_name_text(result: Arena.Arena & String) -> Arena.Arena & Maybe<&2, String>:
  match result:
    case Tuple{arena, text}: (arena, Some{text})

def arena_case_prefix_local_name_valid(+id: U32, result: Arena.Arena & Bool) -> Arena.Arena & Maybe<&2, String>:
  match result:
    case Tuple{arena, valid}:
      match valid:
        case False{}: (arena, None{})
        case True{}: arena_case_prefix_local_name_text(Arena.name_text(arena, id))

def arena_case_prefix_local_name_region(source: Arena.Arena, transient: Arena.Arena, +id: U32, temporary: Bool) -> ArenaResult<Maybe<&2, String>>:
  match temporary:
    case False{}: arena_case_prefix_local_text_result(transient, arena_case_prefix_local_name_valid(id, Arena.case_prefix_name_valid(source, id)), False{})
    case True{}:
      +offset = arena_node_offset(id)
      arena_case_prefix_local_text_result(source, arena_case_prefix_local_name_valid(offset, Arena.case_prefix_name_valid(transient, offset)), True{})

def arena_case_prefix_local_name(store: ArenaStore, +id: U32) -> ArenaResult<Maybe<&2, String>>:
  match store:
    case ArenaStore{source, transient}: arena_case_prefix_local_name_region(source, transient, id, arena_is_transient(id))

def arena_case_prefix_local_pattern_value(result: ArenaResult<Arena.Pattern>) -> ArenaResult<Maybe<&2, String>>:
  match result:
    case ArenaResult{store, pattern}:
      match pattern:
        case Arena.PatternCtr{name, _, _, _}: arena_case_prefix_local_name(store, name)
        case _: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, String>>}

def arena_case_prefix_local_pattern_valid(id: U32, result: ArenaResult<Bool>) -> ArenaResult<Maybe<&2, String>>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, String>>}
        case True{}: arena_case_prefix_local_pattern_value(arena_get_pattern(store, id))

def arena_case_prefix_local_pattern(result: ArenaResult<U32>) -> ArenaResult<Maybe<&2, String>>:
  match result:
    case ArenaResult{store, +id}: arena_case_prefix_local_pattern_valid(id, arena_case_prefix_local_descriptor_valid(store, id, True{}))

def arena_case_prefix_local_single_valid(start: U32, result: ArenaResult<Bool>) -> ArenaResult<Maybe<&2, String>>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, String>>}
        case True{}: arena_case_prefix_local_pattern(arena_get_word(store, start))

def arena_case_prefix_local_single(store: ArenaStore, +start: U32, single: Bool) -> ArenaResult<Maybe<&2, String>>:
  match single:
    case False{}: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, String>>}
    case True{}: arena_case_prefix_local_single_valid(start, arena_case_prefix_local_range(store, start, 1))

def arena_case_prefix_local_node(result: ArenaResult<Arena.Node>) -> ArenaResult<Maybe<&2, String>>:
  match result:
    case ArenaResult{store, node}:
      match node:
        case Arena.BodyCase{start, +count, _, _}: arena_case_prefix_local_single(store, start, U32.is_eq(count, 1))
        case _: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, String>>}

def arena_case_prefix_local_head_valid(id: U32, result: ArenaResult<Bool>) -> ArenaResult<Maybe<&2, String>>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, String>>}
        case True{}: arena_case_prefix_local_node(arena_get_node(store, id))

def arena_case_prefix_local_head(store: ArenaStore, +id: U32) -> ArenaResult<Maybe<&2, String>>:
  arena_case_prefix_local_head_valid(id, arena_case_prefix_local_descriptor_valid(store, id, False{}))

def arena_case_prefix_local_save(transient: Arena.Arena, +start: U32, +count: U32, +heads: Map<&2, U32>, +barrier: U32, result: Arena.Arena & Nat) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case Tuple{source, +generation}:
      {ArenaResult{ArenaStore{source, Arena.case_prefix_put(transient, start, count, heads, barrier, generation)}, Arena.CasePrefixSaved{start, count, heads, barrier, generation}} : ArenaResult<Arena.CasePrefixEntry>}

def arena_case_prefix_local_finish_region(store: ArenaStore, +start: U32, +count: U32, +heads: Map<&2, U32>, +barrier: U32, temporary: Bool) -> ArenaResult<Arena.CasePrefixEntry>:
  match temporary:
    case False{}: {ArenaResult{store, Arena.CasePrefixSaved{start, count, heads, barrier, 0n}} : ArenaResult<Arena.CasePrefixEntry>}
    case True{}:
      match store:
        case ArenaStore{source, transient}:
          arena_case_prefix_local_save(transient, start, count, heads, barrier, Arena.generation(source))

def arena_case_prefix_local_finish(store: ArenaStore, +start: U32, count: U32, heads: Map<&2, U32>, barrier: U32) -> ArenaResult<Arena.CasePrefixEntry>:
  arena_case_prefix_local_finish_region(store, start, count, heads, barrier, arena_is_transient(start))

def arena_case_prefix_local_build_head(request: CasePrefixBuild, result: ArenaResult<Maybe<&2, String>>) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case ArenaResult{store, head}:
      match request:
        case CasePrefixBuild{start, count, +cursor, +offset, remaining, heads}:
          match head:
            case None{}: arena_case_prefix_local_finish(store, start, count, heads, offset)
            case Some{name}:
              arena_case_prefix_local_build(store, CasePrefixBuild{start, count, arena_range_index(cursor, 1), U32.add(offset, 1), remaining, Arena.case_prefix_first(heads, name, offset)})

def arena_case_prefix_local_build_word(request: CasePrefixBuild, result: ArenaResult<U32>) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case ArenaResult{store, id}: arena_case_prefix_local_build_head(request, arena_case_prefix_local_head(store, id))

def arena_case_prefix_local_build(store: ArenaStore, request: CasePrefixBuild) -> ArenaResult<Arena.CasePrefixEntry>:
  match request:
    case CasePrefixBuild{start, count, +cursor, offset, remaining, heads}:
      match remaining:
        case 0n: arena_case_prefix_local_finish(store, start, count, heads, offset)
        case 1n+rest:
          arena_case_prefix_local_build_word(CasePrefixBuild{start, count, cursor, offset, rest, heads}, arena_get_word(store, cursor))

def arena_case_prefix_local_range_valid(+start: U32, +count: U32, result: ArenaResult<Bool>) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case ArenaResult{store, valid}:
      match valid:
        case False{}: {ArenaResult{store, Arena.CasePrefixEmpty{}} : ArenaResult<Arena.CasePrefixEntry>}
        case True{}: arena_case_prefix_local_build(store, CasePrefixBuild{start, count, start, 0, U32.to_nat(count), Map.new(&2, U32)})

def arena_case_prefix_local_index(store: ArenaStore, +start: U32, +count: U32) -> ArenaResult<Arena.CasePrefixEntry>:
  arena_case_prefix_local_range_valid(start, count, arena_case_prefix_local_range(store, start, count))

def arena_case_prefix_local_cached_exact(store: ArenaStore, start: U32, count: U32, entry: Arena.CasePrefixEntry, same: Bool) -> ArenaResult<Arena.CasePrefixEntry>:
  match same:
    case False{}: arena_case_prefix_local_index(store, start, count)
    case True{}: {ArenaResult{store, entry} : ArenaResult<Arena.CasePrefixEntry>}

def arena_case_prefix_local_cached_generation(transient: Arena.Arena, +start: U32, +count: U32, entry: Arena.CasePrefixEntry, same_range: Bool, saved_generation: Nat, result: Arena.Arena & Nat) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case Tuple{source, generation}:
      arena_case_prefix_local_cached_exact(ArenaStore{source, transient}, start, count, entry, Bool.and(same_range, Nat.is_eq(saved_generation, generation)))

def arena_case_prefix_local_cached(source: Arena.Arena, +start: U32, +count: U32, result: Arena.Arena & Arena.CasePrefixEntry) -> ArenaResult<Arena.CasePrefixEntry>:
  match result:
    case Tuple{transient, entry}:
      match entry:
        case Arena.CasePrefixEmpty{}: arena_case_prefix_local_index(ArenaStore{source, transient}, start, count)
        case Arena.CasePrefixSaved{+saved_start, +saved_count, heads, barrier, +generation}:
          arena_case_prefix_local_cached_generation(transient, start, count, Arena.CasePrefixSaved{saved_start, saved_count, heads, barrier, generation}, Bool.and(U32.is_eq(start, saved_start), U32.is_eq(count, saved_count)), generation, Arena.generation(source))

def arena_case_prefix_eligible(store: ArenaStore, +start: U32, +count: U32, eligible: Bool) -> ArenaResult<Arena.CasePrefixEntry>:
  match eligible:
    case False{}: {ArenaResult{store, Arena.CasePrefixEmpty{}} : ArenaResult<Arena.CasePrefixEntry>}
    case True{}:
      match store:
        case ArenaStore{source, transient}:
          arena_case_prefix_cached(start, count, arena_case_prefix_result(transient, Arena.case_prefix_get(source, start, count)))

def arena_case_prefix_region(store: ArenaStore, start: U32, count: U32, temporary: Bool) -> ArenaResult<Arena.CasePrefixEntry>:
  match temporary:
    case False{}: arena_case_prefix_eligible(store, start, count, True{})
    case True{}:
      match store:
        case ArenaStore{source, transient}:
          arena_case_prefix_local_cached(source, start, count, Arena.case_prefix_get(transient, start, count))

def arena_case_prefix_large(store: ArenaStore, +start: U32, count: U32, large: Bool) -> ArenaResult<Arena.CasePrefixEntry>:
  match large:
    case False{}: {ArenaResult{store, Arena.CasePrefixEmpty{}} : ArenaResult<Arena.CasePrefixEntry>}
    case True{}: arena_case_prefix_region(store, start, count, arena_is_transient(start))

def arena_case_prefix_index(store: ArenaStore, cases: IR.Words) -> ArenaResult<Arena.CasePrefixEntry>:
  match cases:
    case IR.Words{+start, +count}:
      arena_case_prefix_large(store, start, count, Arena.case_prefix_at_most(U32.cmp(64, count)))

def arena_case_prefix_name(heads: Map<&2, U32>, name: String) -> Map<&2, U32> & U32:
  Arena.case_prefix_name(heads, name)

def arena_case_prefix_suffix(start: U32, count: U32, offset: U32, empty: Bool) -> IR.Words:
  match empty:
    case True{}: IR.Words{start, 0}
    case False{}: IR.Words{arena_range_index(start, offset), U32.sub(count, offset)}

# The table lives only in transient Arena. Full tagged IDs distinguish regions;
# neither arbitrary Nat key is narrowed, and hash collisions are exact misses.
# Published descriptors/tapes are immutable. Rewind clears the entire memo,
# including no-op marks, before any input/value/output handle can be reused.
def arena_subst_memo_exact(output_id: U32, same: Bool) -> Maybe<&2, U32>:
  match same:
    case False{}: None{}
    case True{}: Some{output_id}

def arena_subst_memo_entry(node_id: U32, index: Nat, value_id: U32, depth: Nat, entry: Arena.SubstMemoEntry) -> Maybe<&2, U32>:
  match entry:
    case Arena.SubstMemoEmpty{}: None{}
    case Arena.SubstMemoSaved{saved_node, saved_index, saved_value, saved_depth, output_id}:
      arena_subst_memo_exact(output_id, Bool.and(Bool.and(U32.is_eq(node_id, saved_node), U32.is_eq(value_id, saved_value)), Bool.and(Nat.is_eq(index, saved_index), Nat.is_eq(depth, saved_depth))))
    case _: None{}

def arena_subst_memo_lookup_result(source: Arena.Arena, node_id: U32, index: Nat, value_id: U32, depth: Nat, result: Arena.Arena & Arena.SubstMemoEntry) -> ArenaResult<Maybe<&2, U32>>:
  match result:
    case Tuple{transient, entry}:
      {ArenaResult{ArenaStore{source, transient}, arena_subst_memo_entry(node_id, index, value_id, depth, entry)} : ArenaResult<Maybe<&2, U32>>}

def arena_subst_memo_lookup(store: ArenaStore, +node_id: U32, index: Nat, +value_id: U32, depth: Nat) -> ArenaResult<Maybe<&2, U32>>:
  match store:
    case ArenaStore{source, transient}:
      arena_subst_memo_lookup_result(source, node_id, index, value_id, depth, Arena.subst_memo_get(transient, node_id, value_id))

def arena_subst_memo_store(store: ArenaStore, node_id: U32, index: Nat, value_id: U32, depth: Nat, output_id: U32) -> ArenaStore:
  match store:
    case ArenaStore{source, transient}:
      ArenaStore{source, Arena.subst_memo_put(transient, node_id, index, value_id, depth, output_id)}

def arena_release(store: ArenaStore) -> ArenaResult<Unit>:
  match store:
    case ArenaStore{source, transient}:
      {ArenaResult{ArenaStore{source, Arena.rewind(transient, Arena.Mark{0, 0, 0, 0, 0, 0})}, Unit{}} : ArenaResult<Unit>}

def arena_name(store: ArenaStore, text: String) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_name_name_result_0(Arena.name(source, text), transient)

def arena_name_text_name_text_result_1(result: Arena.Arena & String, transient: Arena.Arena) -> ArenaResult<String>:
  match result:
    case Tuple{source, text}:
      {ArenaResult{ArenaStore{source, transient}, text} : ArenaResult<String>}

def arena_name_text(store: ArenaStore, id: U32) -> ArenaResult<String>:
  match store:
    case ArenaStore{source, transient}:
      arena_name_text_name_text_result_1(Arena.name_text(source, id), transient)

def arena_get_node_region(source: Arena.Arena, transient: Arena.Arena, id: U32, temporary: Bool) -> ArenaResult<Arena.Node>:
  match temporary:
    case False{}:
      arena_get_node_region_get_node_result_2(Arena.get_node(source, arena_node_offset(id)), transient)
    case True{}:
      arena_get_node_region_get_node_result_3(Arena.get_node(transient, arena_node_offset(id)), source)

def arena_get_node(store: ArenaStore, +id: U32) -> ArenaResult<Arena.Node>:
  match store:
    case ArenaStore{source, transient}: arena_get_node_region(source, transient, id, arena_is_transient(id))

def arena_node_is_closed_source(result: Arena.Arena & Bool, transient: Arena.Arena) -> ArenaResult<Bool>:
  match result:
    case Tuple{source, closed}: {ArenaResult{ArenaStore{source, transient}, closed} : ArenaResult<Bool>}

def arena_node_is_closed_transient(result: Arena.Arena & Bool, source: Arena.Arena) -> ArenaResult<Bool>:
  match result:
    case Tuple{transient, closed}: {ArenaResult{ArenaStore{source, transient}, closed} : ArenaResult<Bool>}

def arena_node_is_closed_region(source: Arena.Arena, transient: Arena.Arena, +id: U32, temporary: Bool) -> ArenaResult<Bool>:
  match temporary:
    case False{}: arena_node_is_closed_source(Arena.node_is_closed(source, id), transient)
    case True{}: arena_node_is_closed_transient(Arena.node_is_trusted_closed(transient, id), source)

def arena_node_is_closed(store: ArenaStore, +id: U32) -> ArenaResult<Bool>:
  match store:
    case ArenaStore{source, transient}: arena_node_is_closed_region(source, transient, id, arena_is_transient(id))

def arena_put_node_bound(value: Arena.Node, result: ArenaResult<Nat>) -> ArenaResult<U32>:
  match result:
    case ArenaResult{store, encoded}:
      match store:
        case ArenaStore{source, transient}:
          arena_put_node_put_node_result_4(Arena.put_node_certified(transient, value, encoded), source)

def arena_put_node(store: ArenaStore, +value: Arena.Node) -> ArenaResult<U32>:
  arena_put_node_bound(value, arena_bound_node(store, value))

def arena_put_source_node(store: ArenaStore, value: Arena.Node) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_put_source_node_put_node_result_5(Arena.put_node(source, value), transient)

def arena_get_pattern_region(source: Arena.Arena, transient: Arena.Arena, id: U32, temporary: Bool) -> ArenaResult<Arena.Pattern>:
  match temporary:
    case False{}:
      arena_get_pattern_region_get_pattern_result_6(Arena.get_pattern(source, arena_node_offset(id)), transient)
    case True{}:
      arena_get_pattern_region_get_pattern_result_7(Arena.get_pattern(transient, arena_node_offset(id)), source)

def arena_get_pattern(store: ArenaStore, +id: U32) -> ArenaResult<Arena.Pattern>:
  match store:
    case ArenaStore{source, transient}: arena_get_pattern_region(source, transient, id, arena_is_transient(id))

def arena_put_pattern(store: ArenaStore, value: Arena.Pattern) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_put_pattern_put_pattern_result_8(Arena.put_pattern(transient, value), source)

def arena_put_source_pattern(store: ArenaStore, value: Arena.Pattern) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_put_source_pattern_put_pattern_result_9(Arena.put_pattern(source, value), transient)

def arena_get_binder_region(source: Arena.Arena, transient: Arena.Arena, id: U32, temporary: Bool) -> ArenaResult<Arena.Binder>:
  match temporary:
    case False{}:
      arena_get_binder_region_get_binder_result_10(Arena.get_binder(source, arena_node_offset(id)), transient)
    case True{}:
      arena_get_binder_region_get_binder_result_11(Arena.get_binder(transient, arena_node_offset(id)), source)

def arena_get_binder(store: ArenaStore, +id: U32) -> ArenaResult<Arena.Binder>:
  match store:
    case ArenaStore{source, transient}: arena_get_binder_region(source, transient, id, arena_is_transient(id))

def arena_put_binder(store: ArenaStore, value: Arena.Binder) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_put_binder_put_binder_result_12(Arena.put_binder(transient, value), source)

def arena_put_source_binder(store: ArenaStore, value: Arena.Binder) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_put_source_binder_put_binder_result_13(Arena.put_binder(source, value), transient)

def arena_get_word_region(source: Arena.Arena, transient: Arena.Arena, id: U32, temporary: Bool) -> ArenaResult<U32>:
  match temporary:
    case False{}:
      arena_get_word_region_word_result_14(Arena.word(source, arena_tape_offset(id)), transient)
    case True{}:
      arena_get_word_region_word_result_15(Arena.word(transient, arena_tape_offset(id)), source)

def arena_get_word(store: ArenaStore, +id: U32) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}: arena_get_word_region(source, transient, id, arena_is_transient(id))

def arena_put_word(store: ArenaStore, value: U32) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_put_word_put_word_result_16(Arena.put_word(transient, value), source)

def arena_put_source_word(store: ArenaStore, value: U32) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_put_source_word_put_word_result_17(Arena.put_word(source, value), transient)

def arena_get_natural_region(source: Arena.Arena, transient: Arena.Arena, id: U32, temporary: Bool) -> ArenaResult<Nat>:
  match temporary:
    case False{}:
      arena_get_natural_region_natural_result_18(Arena.natural(source, arena_tape_offset(id)), transient)
    case True{}:
      arena_get_natural_region_natural_result_19(Arena.natural(transient, arena_tape_offset(id)), source)

def arena_get_natural(store: ArenaStore, +id: U32) -> ArenaResult<Nat>:
  match store:
    case ArenaStore{source, transient}: arena_get_natural_region(source, transient, id, arena_is_transient(id))

def arena_put_natural(store: ArenaStore, value: Nat) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_put_natural_put_natural_result_20(Arena.put_natural(transient, value), source)

def arena_put_source_natural(store: ArenaStore, value: Nat) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_put_source_natural_put_natural_result_21(Arena.put_natural(source, value), transient)

def arena_reserve_words(store: ArenaStore, count: U32) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_reserve_words_reserve_words_result_22(Arena.reserve_words(transient, count), source)

def arena_reserve_source_words(store: ArenaStore, count: U32) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_reserve_source_words_reserve_words_result_23(Arena.reserve_words(source, count), transient)

def arena_set_word_region(v_0: Arena.Arena, v_1: Arena.Arena, v_3: U32, v_5: U32, v_7: Bool) -> ArenaStore:
  match v_7:
    case False{}:
      v_50000430 = Arena.set_word(v_0, arena_tape_offset(v_3), v_5)
      ArenaStore{v_50000430, v_1}
    case True{}:
      v_50000431 = Arena.set_word(v_1, arena_tape_offset(v_3), v_5)
      ArenaStore{v_0, v_50000431}

def arena_set_word(store: ArenaStore, +id: U32, value: U32) -> ArenaStore:
  match store:
    case ArenaStore{source, transient}: arena_set_word_region(source, transient, id, value, arena_is_transient(id))

def arena_word_cursor(store: ArenaStore) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_word_cursor_word_count_result_24(Arena.word_count(transient), source)

def arena_copy_word_range(store: ArenaStore, +source: U32, +destination: U32, remaining: Nat, +offset: U32) -> ArenaStore:
  match remaining:
    case 0n: store
    case 1n+rest:
      ArenaResult{next, value} = arena_get_word(store, arena_range_index(source, offset))
      arena_copy_word_range(arena_set_word(next, arena_range_index(destination, offset), value), source, destination, rest, U32.add(offset, 1))

def arena_reserve_naturals(store: ArenaStore, count: U32) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_reserve_naturals_reserve_naturals_result_25(Arena.reserve_naturals(transient, count), source)

def arena_reserve_source_naturals(store: ArenaStore, count: U32) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_reserve_source_naturals_reserve_naturals_result_26(Arena.reserve_naturals(source, count), transient)

def arena_set_natural_region(v_0: Arena.Arena, v_1: Arena.Arena, v_3: U32, v_5: Nat, v_7: Bool) -> ArenaStore:
  match v_7:
    case False{}:
      v_50000432 = Arena.set_natural(v_0, arena_tape_offset(v_3), v_5)
      ArenaStore{v_50000432, v_1}
    case True{}:
      v_50000433 = Arena.set_natural(v_1, arena_tape_offset(v_3), v_5)
      ArenaStore{v_0, v_50000433}

def arena_set_natural(store: ArenaStore, +id: U32, value: Nat) -> ArenaStore:
  match store:
    case ArenaStore{source, transient}: arena_set_natural_region(source, transient, id, value, arena_is_transient(id))

def arena_natural_cursor(store: ArenaStore) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      arena_natural_cursor_natural_count_result_27(Arena.natural_count(transient), source)

# Bounds are encoded as 0 (unknown) or 1+bound, without narrowing Nat.
# Choose an owner using the full handle before passing any local offset.
def arena_bound_source(result: Arena.Arena & Nat, transient: Arena.Arena) -> ArenaResult<Nat>:
  match result:
    case Tuple{source, encoded}: {ArenaResult{ArenaStore{source, transient}, encoded} : ArenaResult<Nat>}

def arena_bound_transient(result: Arena.Arena & Nat, source: Arena.Arena) -> ArenaResult<Nat>:
  match result:
    case Tuple{transient, encoded}: {ArenaResult{ArenaStore{source, transient}, encoded} : ArenaResult<Nat>}

def arena_bound_read_region(source: Arena.Arena, transient: Arena.Arena, id: U32, temporary: Bool) -> ArenaResult<Nat>:
  match temporary:
    case False{}: arena_bound_source(Arena.node_bound(source, arena_node_offset(id), False{}), transient)
    case True{}: arena_bound_transient(Arena.node_bound(transient, arena_node_offset(id), True{}), source)

def arena_node_bound(store: ArenaStore, +id: U32) -> ArenaResult<Nat>:
  match store:
    case ArenaStore{source, transient}: arena_bound_read_region(source, transient, id, arena_is_transient(id))

def arena_bound_merge(left: Nat, result: ArenaResult<Nat>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, encoded}:
      match encoded:
        case 0n: {ArenaResult{store, 0n} : ArenaResult<Nat>}
        case 1n+right: {ArenaResult{store, Nat.add(Arena.bound_max(left, right), 1n)} : ArenaResult<Nat>}

def arena_bound_then(id: U32, result: ArenaResult<Nat>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, encoded}:
      match encoded:
        case 0n: {ArenaResult{store, 0n} : ArenaResult<Nat>}
        case 1n+left: arena_bound_merge(left, arena_node_bound(store, id))

def arena_bound_two(store: ArenaStore, first: U32, second: U32) -> ArenaResult<Nat>:
  arena_bound_then(second, arena_node_bound(store, first))

def arena_bound_three(store: ArenaStore, first: U32, second: U32, third: U32) -> ArenaResult<Nat>:
  arena_bound_then(third, arena_bound_two(store, first, second))

def arena_bound_remove(depth: Nat, result: ArenaResult<Nat>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, encoded}:
      match encoded:
        case 0n: {ArenaResult{store, 0n} : ArenaResult<Nat>}
        case 1n+bound: {ArenaResult{store, Nat.add(Nat.sub(bound, depth), 1n)} : ArenaResult<Nat>}

def arena_bound_binder(body: U32, depth: Nat, result: ArenaResult<Nat>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, encoded}:
      match encoded:
        case 0n: {ArenaResult{store, 0n} : ArenaResult<Nat>}
        case 1n+left: arena_bound_merge(left, arena_bound_remove(depth, arena_node_bound(store, body)))

def arena_bound_min_order(left: U32, right: U32, order: Cmp) -> U32:
  match order:
    case GT{}: right
    case _: left

def arena_bound_min(+left: U32, +right: U32) -> U32:
  arena_bound_min_order(left, right, U32.cmp(left, right))

# Transient pattern descriptors are resolved, not their unsafe arena-local
# metadata. Descending publication indices reject malformed cycles/future IDs.
def arena_bound_pattern_value(store: ArenaStore, limit: U32, value: Arena.Pattern) -> ArenaResult<Nat>:
  match value:
    case Arena.PatternVar{_, _, _, _}: {ArenaResult{store, 2n} : ArenaResult<Nat>}
    case Arena.PatternCtr{_, start, count, _}: arena_bound_range(store, start, count, True{}, limit)

def arena_bound_pattern_get(limit: U32, result: ArenaResult<Arena.Pattern>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, value}: arena_bound_pattern_value(store, limit, value)

def arena_bound_pattern_order(source: Arena.Arena, transient: Arena.Arena, +id: U32, order: Cmp) -> ArenaResult<Nat>:
  match order:
    case LT{}: arena_bound_pattern_get(arena_node_offset(id), arena_get_pattern(ArenaStore{source, transient}, id))
    case _: {ArenaResult{ArenaStore{source, transient}, 0n} : ArenaResult<Nat>}

def arena_bound_pattern_count(source: Arena.Arena, +id: U32, +limit: U32, result: Arena.Arena & U32) -> ArenaResult<Nat>:
  match result:
    case Tuple{transient, used}:
      arena_bound_pattern_order(source, transient, id, U32.cmp(arena_node_offset(id), arena_bound_min(used, limit)))

def arena_bound_pattern_region(source: Arena.Arena, transient: Arena.Arena, id: U32, limit: U32, temporary: Bool) -> ArenaResult<Nat>:
  match temporary:
    case False{}: arena_bound_source(Arena.bound_read(source, id, True{}), transient)
    case True{}: arena_bound_pattern_count(source, id, limit, Arena.pattern_count(transient))

def arena_bound_pattern(store: ArenaStore, +id: U32, limit: U32) -> ArenaResult<Nat>:
  match store:
    case ArenaStore{source, transient}: arena_bound_pattern_region(source, transient, id, limit, arena_is_transient(id))

def arena_bound_range_combine(left: Nat, pattern: Bool, result: ArenaResult<Nat>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, encoded}:
      match encoded:
        case 0n: {ArenaResult{store, 0n} : ArenaResult<Nat>}
        case 1n+right:
          match pattern:
            case False{}: {ArenaResult{store, Nat.add(Arena.bound_max(left, right), 1n)} : ArenaResult<Nat>}
            case True{}: {ArenaResult{store, Nat.add(Nat.add(left, right), 1n)} : ArenaResult<Nat>}

def arena_bound_range_word(left: Nat, +pattern: Bool, limit: U32, result: ArenaResult<U32>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, id}:
      match pattern:
        case False{}: arena_bound_range_combine(left, pattern, arena_node_bound(store, id))
        case True{}: arena_bound_range_combine(left, pattern, arena_bound_pattern(store, id, limit))

def arena_bound_range_loop(remaining: Nat, +start: U32, +offset: U32, +pattern: Bool, +limit: U32, result: ArenaResult<Nat>) -> ArenaResult<Nat>:
  match remaining:
    case 0n: result
    case 1n+rest:
      match result:
        case ArenaResult{store, encoded}:
          match encoded:
            case 0n: {ArenaResult{store, 0n} : ArenaResult<Nat>}
            case 1n+left:
              arena_bound_range_loop(rest, start, U32.add(offset, 1), pattern, limit, arena_bound_range_word(left, pattern, limit, arena_get_word(store, arena_range_index(start, offset))))

def arena_bound_range_length(store: ArenaStore, start: U32, +count: U32, pattern: Bool, limit: U32, order: Cmp) -> ArenaResult<Nat>:
  match order:
    case GT{}: {ArenaResult{store, 0n} : ArenaResult<Nat>}
    case _: arena_bound_range_loop(U32.to_nat(count), start, 0, pattern, limit, {ArenaResult{store, 1n} : ArenaResult<Nat>})

def arena_bound_range_start(store: ArenaStore, +start: U32, +count: U32, +used: U32, pattern: Bool, limit: U32, order: Cmp) -> ArenaResult<Nat>:
  match order:
    case LT{}:
      +offset = arena_tape_offset(start)
      +reverse = arena_is_reverse(start)
      match reverse:
        case False{}: arena_bound_range_length(store, start, count, pattern, limit, U32.cmp(count, U32.sub(used, offset)))
        case True{}: arena_bound_range_length(store, start, count, pattern, limit, U32.cmp(count, U32.add(offset, 1)))
    case _: {ArenaResult{store, 0n} : ArenaResult<Nat>}

def arena_bound_range_source(+start: U32, count: U32, pattern: Bool, limit: U32, result: Arena.Arena & U32, transient: Arena.Arena) -> ArenaResult<Nat>:
  match result:
    case Tuple{source, used}:
      +bounded = arena_bound_min(used, 1073741824)
      arena_bound_range_start(ArenaStore{source, transient}, start, count, bounded, pattern, limit, U32.cmp(arena_tape_offset(start), bounded))

def arena_bound_range_transient(+start: U32, count: U32, pattern: Bool, limit: U32, result: Arena.Arena & U32, source: Arena.Arena) -> ArenaResult<Nat>:
  match result:
    case Tuple{transient, used}:
      +bounded = arena_bound_min(used, 1073741824)
      arena_bound_range_start(ArenaStore{source, transient}, start, count, bounded, pattern, limit, U32.cmp(arena_tape_offset(start), bounded))

def arena_bound_range_region(source: Arena.Arena, transient: Arena.Arena, start: U32, count: U32, pattern: Bool, limit: U32, temporary: Bool) -> ArenaResult<Nat>:
  match temporary:
    case False{}: arena_bound_range_source(start, count, pattern, limit, Arena.word_count(source), transient)
    case True{}: arena_bound_range_transient(start, count, pattern, limit, Arena.word_count(transient), source)

def arena_bound_range_empty(store: ArenaStore, start: U32, count: U32, pattern: Bool, limit: U32, empty: Bool) -> ArenaResult<Nat>:
  match empty:
    case True{}: {ArenaResult{store, 1n} : ArenaResult<Nat>}
    case False{}:
      match store:
        case ArenaStore{source, transient}: arena_bound_range_region(source, transient, start, count, pattern, limit, arena_is_transient(start))

def arena_bound_range(store: ArenaStore, start: U32, +count: U32, pattern: Bool, limit: U32) -> ArenaResult<Nat>:
  arena_bound_range_empty(store, start, count, pattern, limit, U32.is_eq(count, 0))

def arena_bound_terms(store: ArenaStore, start: U32, count: U32) -> ArenaResult<Nat>:
  arena_bound_range(store, start, count, False{}, 2147483648)

def arena_bound_range_then(start: U32, count: U32, result: ArenaResult<Nat>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, encoded}:
      match encoded:
        case 0n: {ArenaResult{store, 0n} : ArenaResult<Nat>}
        case 1n+left: arena_bound_merge(left, arena_bound_terms(store, start, count))

def arena_bound_case(body: U32, result: ArenaResult<Nat>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, encoded}:
      match encoded:
        case 0n: {ArenaResult{store, 0n} : ArenaResult<Nat>}
        case 1n+depth: arena_bound_remove(depth, arena_node_bound(store, body))

def arena_bound_local(body: U32, start: U32, count: U32, result: ArenaResult<Nat>) -> ArenaResult<Nat>:
  match result:
    case ArenaResult{store, encoded}:
      match encoded:
        case 0n: {ArenaResult{store, 0n} : ArenaResult<Nat>}
        case 1n+depth: arena_bound_binder(body, depth, arena_bound_terms(store, start, count))

def arena_bound_node(store: ArenaStore, value: Arena.Node) -> ArenaResult<Nat>:
  match value:
    case Arena.TermVar{_, index, _}: {ArenaResult{store, Nat.add(index, 2n)} : ArenaResult<Nat>}
    case Arena.TermRef{_, _}: {ArenaResult{store, 1n} : ArenaResult<Nat>}
    case Arena.TermBang{term_id, _}: arena_node_bound(store, term_id)
    case Arena.TermSub{_, value_id, body_id, _}: arena_bound_binder(body_id, 1n, arena_node_bound(store, value_id))
    case Arena.TermLet{_, keys_count, _, _, _, _, start, count, body_id, _}: arena_bound_binder(body_id, U32.to_nat(keys_count), arena_bound_terms(store, start, count))
    case Arena.TermAnn{term_id, ty_id, _}: arena_bound_two(store, term_id, ty_id)
    case Arena.TermTemplate{term_id, _}: arena_node_bound(store, term_id)
    case Arena.TermType{kind_id, _}: arena_node_bound(store, kind_id)
    case Arena.TermQuant{}: {ArenaResult{store, 1n} : ArenaResult<Nat>}
    case Arena.TermQuantity{_, _}: {ArenaResult{store, 1n} : ArenaResult<Nat>}
    case Arena.TermMin{left_id, right_id, _}: arena_bound_two(store, left_id, right_id)
    case Arena.TermAll{_, _, _, ty_id, body_id, _}: arena_bound_binder(body_id, 1n, arena_node_bound(store, ty_id))
    case Arena.TermLam{_, _, _, body_id, _}: arena_bound_remove(1n, arena_node_bound(store, body_id))
    case Arena.TermApp{fn_id, arg_id, _}: arena_bound_two(store, fn_id, arg_id)
    case Arena.TermAdt{_, start, count, _, _, _}: arena_bound_terms(store, start, count)
    case Arena.TermFill{head_id, start, count, _}: arena_bound_range_then(start, count, arena_node_bound(store, head_id))
    case Arena.TermPlus{head_id, start, count, _}: arena_bound_range_then(start, count, arena_node_bound(store, head_id))
    case Arena.TermCtr{_, start, count, _}: arena_bound_terms(store, start, count)
    case Arena.TermString{_, _, _}: {ArenaResult{store, 1n} : ArenaResult<Nat>}
    case Arena.TermMat{_, head_id, matched_id, _}: arena_bound_two(store, head_id, matched_id)
    case Arena.TermAbsurd{_}: {ArenaResult{store, 1n} : ArenaResult<Nat>}
    case Arena.TermEqual{left_id, right_id, ty_id, _}: arena_bound_three(store, left_id, right_id, ty_id)
    case Arena.TermRefl{_}: {ArenaResult{store, 1n} : ArenaResult<Nat>}
    case Arena.TermRewrite{equation_id, proof_id, body_id, _}: arena_bound_three(store, equation_id, proof_id, body_id)
    case Arena.TermHole{_, _}: {ArenaResult{store, 1n} : ArenaResult<Nat>}
    case Arena.BodyMatch{start, count, cases_start, cases_count, _}: arena_bound_range_then(cases_start, cases_count, arena_bound_terms(store, start, count))
    case Arena.BodyCase{start, count, body_id, _}: arena_bound_case(body_id, arena_bound_range(store, start, count, True{}, 2147483648))
    case Arena.BodyLocal{start, count, _, values_start, values_count, body_id, _}: arena_bound_local(body_id, values_start, values_count, arena_bound_range(store, start, count, True{}, 2147483648))
    case Arena.BodyReply{term_id, _}: arena_node_bound(store, term_id)

def arena_copy_natural_range(store: ArenaStore, +source: U32, +destination: U32, remaining: Nat, +offset: U32) -> ArenaStore:
  match remaining:
    case 0n: store
    case 1n+rest:
      ArenaResult{next, value} = arena_get_natural(store, arena_range_index(source, offset))
      arena_copy_natural_range(arena_set_natural(next, arena_range_index(destination, offset), value), source, destination, rest, U32.add(offset, 1))

def arena_words_start(range: IR.Words) -> U32:
  match range:
    case IR.Words{start, _}: start

def arena_words_count(range: IR.Words) -> U32:
  match range:
    case IR.Words{_, count}: count

def arena_words_length(range: IR.Words) -> Nat:
  U32.to_nat(arena_words_count(range))

def arena_words_is_empty(range: IR.Words) -> Bool:
  U32.is_eq(arena_words_count(range), 0)

def arena_words_view_nonempty(v_1: ArenaStore, +v_3: U32, v_5: U32, v_7: Bool) -> ArenaResult<IR.WordView>:
  match v_7:
    case True{}:
      {ArenaResult{v_1, IR.WordNil{}} : ArenaResult<IR.WordView>}
    case False{}:
      ArenaResult{v_12, v_13} = arena_get_word(v_1, v_3)
      v_50000434 = arena_range_index(v_3, 1)
      v_50000435 = IR.Words{v_50000434, U32.sub(v_5, 1)}
      v_50000436 = IR.WordCons{v_13, v_50000435}
      {ArenaResult{v_12, v_50000436} : ArenaResult<IR.WordView>}

def arena_words_view(store: ArenaStore, range: IR.Words) -> ArenaResult<IR.WordView>:
  match range:
    case IR.Words{start, +count}: arena_words_view_nonempty(store, start, count, U32.is_eq(count, 0))

def arena_words_prepend_copy(v_1: ArenaStore, v_3: U32, +v_5: U32, +v_7: U32) -> ArenaResult<IR.Words>:
  ArenaResult{v_12, v_13} = arena_reserve_words(v_1, U32.add(v_7, 1))
  +v_15 = U32.or(U32.add(v_13, v_7), 1073741824)
  v_19 = arena_copy_word_range(v_12, v_5, arena_range_index(v_15, 1), U32.to_nat(v_7), 0)
  v_50000437 = arena_set_word(v_19, v_15, v_3)
  {ArenaResult{v_50000437, IR.Words{v_15, U32.add(v_7, 1)}} : ArenaResult<IR.Words>}

def arena_words_prepend_fast(store: ArenaStore, head: U32, start: U32, +count: U32, contiguous: Bool) -> ArenaResult<IR.Words>:
  match contiguous:
    case True{}:
      ArenaResult{next, index} = arena_put_word(store, head)
      {ArenaResult{next, IR.Words{U32.or(index, 1073741824), U32.add(count, 1)}} : ArenaResult<IR.Words>}
    case False{}: arena_words_prepend_copy(store, head, start, count)

def arena_words_prepend_count(store: ArenaStore, head: U32, +start: U32, +count: U32, cursor: U32) -> ArenaResult<IR.Words>:
  arena_words_prepend_fast(store, head, start, count, Bool.or(U32.is_eq(count, 0), Bool.and(Bool.and(arena_is_transient(start), arena_is_reverse(start)), U32.is_eq(U32.add(arena_tape_offset(start), 1), cursor))))

def arena_words_cons(store: ArenaStore, head: U32, tail: IR.Words) -> ArenaResult<IR.Words>:
  match tail:
    case IR.Words{start, count}:
      ArenaResult{next, cursor} = arena_word_cursor(store)
      arena_words_prepend_count(next, head, start, count, cursor)

def arena_words_append_copy(store: ArenaStore, +left: U32, +left_count: U32, +right: U32, +right_count: U32) -> ArenaResult<IR.Words>:
  +count = U32.add(left_count, right_count)
  ArenaResult{next, start} = arena_reserve_words(store, count)
  +destination = U32.or(U32.add(start, U32.sub(count, 1)), 1073741824)
  copied = arena_copy_word_range(next, left, destination, U32.to_nat(left_count), 0)
  last = arena_copy_word_range(copied, right, arena_range_index(destination, left_count), U32.to_nat(right_count), 0)
  {ArenaResult{last, IR.Words{destination, count}} : ArenaResult<IR.Words>}

def arena_words_append_select(store: ArenaStore, +left: U32, +left_count: U32, +right: U32, +right_count: U32, empty_left: Bool, empty_right: Bool, adjacent: Bool) -> ArenaResult<IR.Words>:
  match empty_left empty_right adjacent:
    case True{} _ _: {ArenaResult{store, IR.Words{right, right_count}} : ArenaResult<IR.Words>}
    case _ True{} _: {ArenaResult{store, IR.Words{left, left_count}} : ArenaResult<IR.Words>}
    case _ _ True{}: {ArenaResult{store, IR.Words{left, U32.add(left_count, right_count)}} : ArenaResult<IR.Words>}
    case _ _ _: arena_words_append_copy(store, left, left_count, right, right_count)

def arena_words_append(store: ArenaStore, left: IR.Words, right: IR.Words) -> ArenaResult<IR.Words>:
  match left right:
    case IR.Words{+start, +count} IR.Words{+next, +size}:
      arena_words_append_select(store, start, count, next, size, U32.is_eq(count, 0), U32.is_eq(size, 0), U32.is_eq(arena_range_index(start, count), next))

def arena_words_reverse(v_1: ArenaStore, v_2: IR.Words) -> ArenaResult<IR.Words>:
  match v_2:
    case IR.Words{v_6, +v_7}:
      v_50000438 = arena_range_flip(v_6, v_7)
      v_50000439 = IR.Words{v_50000438, v_7}
      {ArenaResult{v_1, v_50000439} : ArenaResult<IR.Words>}

def arena_names_start(range: IR.Names) -> U32:
  match range:
    case IR.Names{start, _}: start

def arena_names_count(range: IR.Names) -> U32:
  match range:
    case IR.Names{_, count}: count

def arena_names_length(range: IR.Names) -> Nat:
  U32.to_nat(arena_names_count(range))

def arena_names_is_empty(range: IR.Names) -> Bool:
  U32.is_eq(arena_names_count(range), 0)

def arena_names_view_nonempty(v_1: ArenaStore, +v_3: U32, v_5: U32, v_7: Bool) -> ArenaResult<IR.NameView>:
  match v_7:
    case True{}:
      {ArenaResult{v_1, IR.NameNil{}} : ArenaResult<IR.NameView>}
    case False{}:
      ArenaResult{v_12, v_13} = arena_get_word(v_1, v_3)
      ArenaResult{v_17, v_18} = arena_name_text(v_12, v_13)
      v_50000440 = arena_range_index(v_3, 1)
      v_50000441 = IR.Names{v_50000440, U32.sub(v_5, 1)}
      v_50000442 = IR.NameCons{v_18, v_50000441}
      {ArenaResult{v_17, v_50000442} : ArenaResult<IR.NameView>}

def arena_names_view(store: ArenaStore, range: IR.Names) -> ArenaResult<IR.NameView>:
  match range:
    case IR.Names{start, +count}: arena_names_view_nonempty(store, start, count, U32.is_eq(count, 0))

def arena_names_prepend_copy(v_1: ArenaStore, v_3: U32, +v_5: U32, +v_7: U32) -> ArenaResult<IR.Names>:
  ArenaResult{v_12, v_13} = arena_reserve_words(v_1, U32.add(v_7, 1))
  +v_15 = U32.or(U32.add(v_13, v_7), 1073741824)
  v_19 = arena_copy_word_range(v_12, v_5, arena_range_index(v_15, 1), U32.to_nat(v_7), 0)
  v_50000443 = arena_set_word(v_19, v_15, v_3)
  {ArenaResult{v_50000443, IR.Names{v_15, U32.add(v_7, 1)}} : ArenaResult<IR.Names>}

def arena_names_prepend_fast(store: ArenaStore, head: U32, start: U32, +count: U32, contiguous: Bool) -> ArenaResult<IR.Names>:
  match contiguous:
    case True{}:
      ArenaResult{next, index} = arena_put_word(store, head)
      {ArenaResult{next, IR.Names{U32.or(index, 1073741824), U32.add(count, 1)}} : ArenaResult<IR.Names>}
    case False{}: arena_names_prepend_copy(store, head, start, count)

def arena_names_prepend_count(store: ArenaStore, head: U32, +start: U32, +count: U32, cursor: U32) -> ArenaResult<IR.Names>:
  arena_names_prepend_fast(store, head, start, count, Bool.or(U32.is_eq(count, 0), Bool.and(Bool.and(arena_is_transient(start), arena_is_reverse(start)), U32.is_eq(U32.add(arena_tape_offset(start), 1), cursor))))

def arena_names_cons(store: ArenaStore, head: String, tail: IR.Names) -> ArenaResult<IR.Names>:
  match tail:
    case IR.Names{start, count}:
      ArenaResult{named, raw} = arena_name(store, head)
      ArenaResult{next, cursor} = arena_word_cursor(named)
      arena_names_prepend_count(next, raw, start, count, cursor)

def arena_names_append_copy(store: ArenaStore, +left: U32, +left_count: U32, +right: U32, +right_count: U32) -> ArenaResult<IR.Names>:
  +count = U32.add(left_count, right_count)
  ArenaResult{next, start} = arena_reserve_words(store, count)
  +destination = U32.or(U32.add(start, U32.sub(count, 1)), 1073741824)
  copied = arena_copy_word_range(next, left, destination, U32.to_nat(left_count), 0)
  last = arena_copy_word_range(copied, right, arena_range_index(destination, left_count), U32.to_nat(right_count), 0)
  {ArenaResult{last, IR.Names{destination, count}} : ArenaResult<IR.Names>}

def arena_names_append_select(store: ArenaStore, +left: U32, +left_count: U32, +right: U32, +right_count: U32, empty_left: Bool, empty_right: Bool, adjacent: Bool) -> ArenaResult<IR.Names>:
  match empty_left empty_right adjacent:
    case True{} _ _: {ArenaResult{store, IR.Names{right, right_count}} : ArenaResult<IR.Names>}
    case _ True{} _: {ArenaResult{store, IR.Names{left, left_count}} : ArenaResult<IR.Names>}
    case _ _ True{}: {ArenaResult{store, IR.Names{left, U32.add(left_count, right_count)}} : ArenaResult<IR.Names>}
    case _ _ _: arena_names_append_copy(store, left, left_count, right, right_count)

def arena_names_append(store: ArenaStore, left: IR.Names, right: IR.Names) -> ArenaResult<IR.Names>:
  match left right:
    case IR.Names{+start, +count} IR.Names{+next, +size}:
      arena_names_append_select(store, start, count, next, size, U32.is_eq(count, 0), U32.is_eq(size, 0), U32.is_eq(arena_range_index(start, count), next))

def arena_names_reverse(v_1: ArenaStore, v_2: IR.Names) -> ArenaResult<IR.Names>:
  match v_2:
    case IR.Names{v_6, +v_7}:
      v_50000444 = arena_range_flip(v_6, v_7)
      v_50000445 = IR.Names{v_50000444, v_7}
      {ArenaResult{v_1, v_50000445} : ArenaResult<IR.Names>}

def arena_naturals_start(range: IR.Naturals) -> U32:
  match range:
    case IR.Naturals{start, _}: start

def arena_naturals_count(range: IR.Naturals) -> U32:
  match range:
    case IR.Naturals{_, count}: count

def arena_naturals_length(range: IR.Naturals) -> Nat:
  U32.to_nat(arena_naturals_count(range))

def arena_naturals_is_empty(range: IR.Naturals) -> Bool:
  U32.is_eq(arena_naturals_count(range), 0)

def arena_naturals_view_nonempty(v_1: ArenaStore, +v_3: U32, v_5: U32, v_7: Bool) -> ArenaResult<IR.NaturalView>:
  match v_7:
    case True{}:
      {ArenaResult{v_1, IR.NaturalNil{}} : ArenaResult<IR.NaturalView>}
    case False{}:
      ArenaResult{v_12, v_13} = arena_get_natural(v_1, v_3)
      v_50000446 = arena_range_index(v_3, 1)
      v_50000447 = IR.Naturals{v_50000446, U32.sub(v_5, 1)}
      v_50000448 = IR.NaturalCons{v_13, v_50000447}
      {ArenaResult{v_12, v_50000448} : ArenaResult<IR.NaturalView>}

def arena_naturals_view(store: ArenaStore, range: IR.Naturals) -> ArenaResult<IR.NaturalView>:
  match range:
    case IR.Naturals{start, +count}: arena_naturals_view_nonempty(store, start, count, U32.is_eq(count, 0))

def arena_naturals_prepend_copy(v_1: ArenaStore, v_3: Nat, +v_5: U32, +v_7: U32) -> ArenaResult<IR.Naturals>:
  ArenaResult{v_12, v_13} = arena_reserve_naturals(v_1, U32.add(v_7, 1))
  +v_15 = U32.or(U32.add(v_13, v_7), 1073741824)
  v_19 = arena_copy_natural_range(v_12, v_5, arena_range_index(v_15, 1), U32.to_nat(v_7), 0)
  v_50000449 = arena_set_natural(v_19, v_15, v_3)
  {ArenaResult{v_50000449, IR.Naturals{v_15, U32.add(v_7, 1)}} : ArenaResult<IR.Naturals>}

def arena_naturals_prepend_fast(store: ArenaStore, head: Nat, start: U32, +count: U32, contiguous: Bool) -> ArenaResult<IR.Naturals>:
  match contiguous:
    case True{}:
      ArenaResult{next, index} = arena_put_natural(store, head)
      {ArenaResult{next, IR.Naturals{U32.or(index, 1073741824), U32.add(count, 1)}} : ArenaResult<IR.Naturals>}
    case False{}: arena_naturals_prepend_copy(store, head, start, count)

def arena_naturals_prepend_count(store: ArenaStore, head: Nat, +start: U32, +count: U32, cursor: U32) -> ArenaResult<IR.Naturals>:
  arena_naturals_prepend_fast(store, head, start, count, Bool.or(U32.is_eq(count, 0), Bool.and(Bool.and(arena_is_transient(start), arena_is_reverse(start)), U32.is_eq(U32.add(arena_tape_offset(start), 1), cursor))))

def arena_naturals_cons(store: ArenaStore, head: Nat, tail: IR.Naturals) -> ArenaResult<IR.Naturals>:
  match tail:
    case IR.Naturals{start, count}:
      ArenaResult{next, cursor} = arena_natural_cursor(store)
      arena_naturals_prepend_count(next, head, start, count, cursor)

def arena_naturals_append_copy(store: ArenaStore, +left: U32, +left_count: U32, +right: U32, +right_count: U32) -> ArenaResult<IR.Naturals>:
  +count = U32.add(left_count, right_count)
  ArenaResult{next, start} = arena_reserve_naturals(store, count)
  +destination = U32.or(U32.add(start, U32.sub(count, 1)), 1073741824)
  copied = arena_copy_natural_range(next, left, destination, U32.to_nat(left_count), 0)
  last = arena_copy_natural_range(copied, right, arena_range_index(destination, left_count), U32.to_nat(right_count), 0)
  {ArenaResult{last, IR.Naturals{destination, count}} : ArenaResult<IR.Naturals>}

def arena_naturals_append_select(store: ArenaStore, +left: U32, +left_count: U32, +right: U32, +right_count: U32, empty_left: Bool, empty_right: Bool, adjacent: Bool) -> ArenaResult<IR.Naturals>:
  match empty_left empty_right adjacent:
    case True{} _ _: {ArenaResult{store, IR.Naturals{right, right_count}} : ArenaResult<IR.Naturals>}
    case _ True{} _: {ArenaResult{store, IR.Naturals{left, left_count}} : ArenaResult<IR.Naturals>}
    case _ _ True{}: {ArenaResult{store, IR.Naturals{left, U32.add(left_count, right_count)}} : ArenaResult<IR.Naturals>}
    case _ _ _: arena_naturals_append_copy(store, left, left_count, right, right_count)

def arena_naturals_append(store: ArenaStore, left: IR.Naturals, right: IR.Naturals) -> ArenaResult<IR.Naturals>:
  match left right:
    case IR.Naturals{+start, +count} IR.Naturals{+next, +size}:
      arena_naturals_append_select(store, start, count, next, size, U32.is_eq(count, 0), U32.is_eq(size, 0), U32.is_eq(arena_range_index(start, count), next))

def arena_naturals_reverse(v_1: ArenaStore, v_2: IR.Naturals) -> ArenaResult<IR.Naturals>:
  match v_2:
    case IR.Naturals{v_6, +v_7}:
      v_50000450 = arena_range_flip(v_6, v_7)
      v_50000451 = IR.Naturals{v_50000450, v_7}
      {ArenaResult{v_1, v_50000451} : ArenaResult<IR.Naturals>}

def arena_quantities_start(range: IR.Quantities) -> U32:
  match range:
    case IR.Quantities{start, _}: start

def arena_quantities_count(range: IR.Quantities) -> U32:
  match range:
    case IR.Quantities{_, count}: count

def arena_quantities_length(range: IR.Quantities) -> Nat:
  U32.to_nat(arena_quantities_count(range))

def arena_quantities_is_empty(range: IR.Quantities) -> Bool:
  U32.is_eq(arena_quantities_count(range), 0)

def arena_quantities_view_nonempty(v_1: ArenaStore, +v_3: U32, v_5: U32, v_7: Bool) -> ArenaResult<IR.QuantityView>:
  match v_7:
    case True{}:
      {ArenaResult{v_1, IR.QuantityNil{}} : ArenaResult<IR.QuantityView>}
    case False{}:
      ArenaResult{v_12, v_13} = arena_get_word(v_1, v_3)
      v_50000452 = Arena.word_quantity(v_13)
      v_50000453 = arena_range_index(v_3, 1)
      v_50000454 = IR.Quantities{v_50000453, U32.sub(v_5, 1)}
      v_50000455 = IR.QuantityCons{v_50000452, v_50000454}
      {ArenaResult{v_12, v_50000455} : ArenaResult<IR.QuantityView>}

def arena_quantities_view(store: ArenaStore, range: IR.Quantities) -> ArenaResult<IR.QuantityView>:
  match range:
    case IR.Quantities{start, +count}: arena_quantities_view_nonempty(store, start, count, U32.is_eq(count, 0))

def arena_quantities_prepend_copy(v_1: ArenaStore, v_3: U32, +v_5: U32, +v_7: U32) -> ArenaResult<IR.Quantities>:
  ArenaResult{v_12, v_13} = arena_reserve_words(v_1, U32.add(v_7, 1))
  +v_15 = U32.or(U32.add(v_13, v_7), 1073741824)
  v_19 = arena_copy_word_range(v_12, v_5, arena_range_index(v_15, 1), U32.to_nat(v_7), 0)
  v_50000456 = arena_set_word(v_19, v_15, v_3)
  {ArenaResult{v_50000456, IR.Quantities{v_15, U32.add(v_7, 1)}} : ArenaResult<IR.Quantities>}

def arena_quantities_prepend_fast(store: ArenaStore, head: U32, start: U32, +count: U32, contiguous: Bool) -> ArenaResult<IR.Quantities>:
  match contiguous:
    case True{}:
      ArenaResult{next, index} = arena_put_word(store, head)
      {ArenaResult{next, IR.Quantities{U32.or(index, 1073741824), U32.add(count, 1)}} : ArenaResult<IR.Quantities>}
    case False{}: arena_quantities_prepend_copy(store, head, start, count)

def arena_quantities_prepend_count(store: ArenaStore, head: U32, +start: U32, +count: U32, cursor: U32) -> ArenaResult<IR.Quantities>:
  arena_quantities_prepend_fast(store, head, start, count, Bool.or(U32.is_eq(count, 0), Bool.and(Bool.and(arena_is_transient(start), arena_is_reverse(start)), U32.is_eq(U32.add(arena_tape_offset(start), 1), cursor))))

def arena_quantities_cons(store: ArenaStore, head: Ast.Quantity, tail: IR.Quantities) -> ArenaResult<IR.Quantities>:
  match tail:
    case IR.Quantities{start, count}:
      ArenaResult{next, cursor} = arena_word_cursor(store)
      arena_quantities_prepend_count(next, Arena.quantity_word(head), start, count, cursor)

def arena_quantities_append_copy(store: ArenaStore, +left: U32, +left_count: U32, +right: U32, +right_count: U32) -> ArenaResult<IR.Quantities>:
  +count = U32.add(left_count, right_count)
  ArenaResult{next, start} = arena_reserve_words(store, count)
  +destination = U32.or(U32.add(start, U32.sub(count, 1)), 1073741824)
  copied = arena_copy_word_range(next, left, destination, U32.to_nat(left_count), 0)
  last = arena_copy_word_range(copied, right, arena_range_index(destination, left_count), U32.to_nat(right_count), 0)
  {ArenaResult{last, IR.Quantities{destination, count}} : ArenaResult<IR.Quantities>}

def arena_quantities_append_select(store: ArenaStore, +left: U32, +left_count: U32, +right: U32, +right_count: U32, empty_left: Bool, empty_right: Bool, adjacent: Bool) -> ArenaResult<IR.Quantities>:
  match empty_left empty_right adjacent:
    case True{} _ _: {ArenaResult{store, IR.Quantities{right, right_count}} : ArenaResult<IR.Quantities>}
    case _ True{} _: {ArenaResult{store, IR.Quantities{left, left_count}} : ArenaResult<IR.Quantities>}
    case _ _ True{}: {ArenaResult{store, IR.Quantities{left, U32.add(left_count, right_count)}} : ArenaResult<IR.Quantities>}
    case _ _ _: arena_quantities_append_copy(store, left, left_count, right, right_count)

def arena_quantities_append(store: ArenaStore, left: IR.Quantities, right: IR.Quantities) -> ArenaResult<IR.Quantities>:
  match left right:
    case IR.Quantities{+start, +count} IR.Quantities{+next, +size}:
      arena_quantities_append_select(store, start, count, next, size, U32.is_eq(count, 0), U32.is_eq(size, 0), U32.is_eq(arena_range_index(start, count), next))

def arena_quantities_reverse(v_1: ArenaStore, v_2: IR.Quantities) -> ArenaResult<IR.Quantities>:
  match v_2:
    case IR.Quantities{v_6, +v_7}:
      v_50000457 = arena_range_flip(v_6, v_7)
      v_50000458 = IR.Quantities{v_50000457, v_7}
      {ArenaResult{v_1, v_50000458} : ArenaResult<IR.Quantities>}

def arena_publish_terms_copy(store: ArenaStore, +start: U32, +destination: U32, remaining: Nat, +offset: U32) -> ArenaStore:
  match remaining:
    case 0n: store
    case 1n+rest:
      ArenaResult{next, value} = arena_get_word(store, arena_range_index(start, offset))
      ArenaResult{published, retained} = arena_publish_term(next, value)
      arena_publish_terms_copy(arena_set_word(published, U32.add(destination, offset), retained), start, destination, rest, U32.add(offset, 1))

def arena_publish_terms_select(v_1: ArenaStore, +v_3: U32, +v_5: U32, v_7: Bool, v_9: Bool) -> ArenaResult<IR.Words>:
  match v_7, v_9:
    case True{}, _:
      {ArenaResult{v_1, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case _, True{}:
      {ArenaResult{v_1, IR.Words{v_3, v_5}} : ArenaResult<IR.Words>}
    case _, _:
      ArenaResult{v_22, v_23} = arena_reserve_source_words(v_1, v_5)
      v_50000459 = arena_publish_terms_copy(v_22, v_3, v_23, U32.to_nat(v_5), 0)
      {ArenaResult{v_50000459, IR.Words{v_23, v_5}} : ArenaResult<IR.Words>}

def arena_publish_terms(store: ArenaStore, range: IR.Words) -> ArenaResult<IR.Words>:
  match range:
    case IR.Words{+start, +count}: arena_publish_terms_select(store, start, count, U32.is_eq(count, 0), Bool.and(Bool.not(arena_is_transient(start)), Bool.not(arena_is_reverse(start))))

def arena_publish_patterns_copy(store: ArenaStore, +start: U32, +destination: U32, remaining: Nat, +offset: U32) -> ArenaStore:
  match remaining:
    case 0n: store
    case 1n+rest:
      ArenaResult{next, value} = arena_get_word(store, arena_range_index(start, offset))
      ArenaResult{published, retained} = arena_publish_pattern(next, value)
      arena_publish_patterns_copy(arena_set_word(published, U32.add(destination, offset), retained), start, destination, rest, U32.add(offset, 1))

def arena_publish_patterns_select(v_1: ArenaStore, +v_3: U32, +v_5: U32, v_7: Bool, v_9: Bool) -> ArenaResult<IR.Words>:
  match v_7, v_9:
    case True{}, _:
      {ArenaResult{v_1, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case _, True{}:
      {ArenaResult{v_1, IR.Words{v_3, v_5}} : ArenaResult<IR.Words>}
    case _, _:
      ArenaResult{v_22, v_23} = arena_reserve_source_words(v_1, v_5)
      v_50000460 = arena_publish_patterns_copy(v_22, v_3, v_23, U32.to_nat(v_5), 0)
      {ArenaResult{v_50000460, IR.Words{v_23, v_5}} : ArenaResult<IR.Words>}

def arena_publish_patterns(store: ArenaStore, range: IR.Words) -> ArenaResult<IR.Words>:
  match range:
    case IR.Words{+start, +count}: arena_publish_patterns_select(store, start, count, U32.is_eq(count, 0), Bool.and(Bool.not(arena_is_transient(start)), Bool.not(arena_is_reverse(start))))

def arena_publish_binders_copy(store: ArenaStore, +start: U32, +destination: U32, remaining: Nat, +offset: U32) -> ArenaStore:
  match remaining:
    case 0n: store
    case 1n+rest:
      ArenaResult{next, value} = arena_get_word(store, arena_range_index(start, offset))
      ArenaResult{published, retained} = arena_publish_binder(next, value)
      arena_publish_binders_copy(arena_set_word(published, U32.add(destination, offset), retained), start, destination, rest, U32.add(offset, 1))

def arena_publish_binders_select(v_1: ArenaStore, +v_3: U32, +v_5: U32, v_7: Bool, v_9: Bool) -> ArenaResult<IR.Words>:
  match v_7, v_9:
    case True{}, _:
      {ArenaResult{v_1, IR.Words{0, 0}} : ArenaResult<IR.Words>}
    case _, True{}:
      {ArenaResult{v_1, IR.Words{v_3, v_5}} : ArenaResult<IR.Words>}
    case _, _:
      ArenaResult{v_22, v_23} = arena_reserve_source_words(v_1, v_5)
      v_50000461 = arena_publish_binders_copy(v_22, v_3, v_23, U32.to_nat(v_5), 0)
      {ArenaResult{v_50000461, IR.Words{v_23, v_5}} : ArenaResult<IR.Words>}

def arena_publish_binders(store: ArenaStore, range: IR.Words) -> ArenaResult<IR.Words>:
  match range:
    case IR.Words{+start, +count}: arena_publish_binders_select(store, start, count, U32.is_eq(count, 0), Bool.and(Bool.not(arena_is_transient(start)), Bool.not(arena_is_reverse(start))))

def arena_publish_names_copy(store: ArenaStore, +start: U32, +destination: U32, remaining: Nat, +offset: U32) -> ArenaStore:
  match remaining:
    case 0n: store
    case 1n+rest:
      ArenaResult{next, value} = arena_get_word(store, arena_range_index(start, offset))
      arena_publish_names_copy(arena_set_word(next, U32.add(destination, offset), value), start, destination, rest, U32.add(offset, 1))

def arena_publish_names_select(v_1: ArenaStore, +v_3: U32, +v_5: U32, v_7: Bool, v_9: Bool) -> ArenaResult<IR.Names>:
  match v_7, v_9:
    case True{}, _:
      {ArenaResult{v_1, IR.Names{0, 0}} : ArenaResult<IR.Names>}
    case _, True{}:
      {ArenaResult{v_1, IR.Names{v_3, v_5}} : ArenaResult<IR.Names>}
    case _, _:
      ArenaResult{v_22, v_23} = arena_reserve_source_words(v_1, v_5)
      v_50000462 = arena_publish_names_copy(v_22, v_3, v_23, U32.to_nat(v_5), 0)
      {ArenaResult{v_50000462, IR.Names{v_23, v_5}} : ArenaResult<IR.Names>}

def arena_publish_names(store: ArenaStore, range: IR.Names) -> ArenaResult<IR.Names>:
  match range:
    case IR.Names{+start, +count}: arena_publish_names_select(store, start, count, U32.is_eq(count, 0), Bool.and(Bool.not(arena_is_transient(start)), Bool.not(arena_is_reverse(start))))

def arena_publish_quantities_copy(store: ArenaStore, +start: U32, +destination: U32, remaining: Nat, +offset: U32) -> ArenaStore:
  match remaining:
    case 0n: store
    case 1n+rest:
      ArenaResult{next, value} = arena_get_word(store, arena_range_index(start, offset))
      arena_publish_quantities_copy(arena_set_word(next, U32.add(destination, offset), value), start, destination, rest, U32.add(offset, 1))

def arena_publish_quantities_select(v_1: ArenaStore, +v_3: U32, +v_5: U32, v_7: Bool, v_9: Bool) -> ArenaResult<IR.Quantities>:
  match v_7, v_9:
    case True{}, _:
      {ArenaResult{v_1, IR.Quantities{0, 0}} : ArenaResult<IR.Quantities>}
    case _, True{}:
      {ArenaResult{v_1, IR.Quantities{v_3, v_5}} : ArenaResult<IR.Quantities>}
    case _, _:
      ArenaResult{v_22, v_23} = arena_reserve_source_words(v_1, v_5)
      v_50000463 = arena_publish_quantities_copy(v_22, v_3, v_23, U32.to_nat(v_5), 0)
      {ArenaResult{v_50000463, IR.Quantities{v_23, v_5}} : ArenaResult<IR.Quantities>}

def arena_publish_quantities(store: ArenaStore, range: IR.Quantities) -> ArenaResult<IR.Quantities>:
  match range:
    case IR.Quantities{+start, +count}: arena_publish_quantities_select(store, start, count, U32.is_eq(count, 0), Bool.and(Bool.not(arena_is_transient(start)), Bool.not(arena_is_reverse(start))))

def arena_publish_naturals_copy(store: ArenaStore, +start: U32, +destination: U32, remaining: Nat, +offset: U32) -> ArenaStore:
  match remaining:
    case 0n: store
    case 1n+rest:
      ArenaResult{next, value} = arena_get_natural(store, arena_range_index(start, offset))
      arena_publish_naturals_copy(arena_set_natural(next, U32.add(destination, offset), value), start, destination, rest, U32.add(offset, 1))

def arena_publish_naturals_select(v_1: ArenaStore, +v_3: U32, +v_5: U32, v_7: Bool, v_9: Bool) -> ArenaResult<IR.Naturals>:
  match v_7, v_9:
    case True{}, _:
      {ArenaResult{v_1, IR.Naturals{0, 0}} : ArenaResult<IR.Naturals>}
    case _, True{}:
      {ArenaResult{v_1, IR.Naturals{v_3, v_5}} : ArenaResult<IR.Naturals>}
    case _, _:
      ArenaResult{v_22, v_23} = arena_reserve_source_naturals(v_1, v_5)
      v_50000464 = arena_publish_naturals_copy(v_22, v_3, v_23, U32.to_nat(v_5), 0)
      {ArenaResult{v_50000464, IR.Naturals{v_23, v_5}} : ArenaResult<IR.Naturals>}

def arena_publish_naturals(store: ArenaStore, range: IR.Naturals) -> ArenaResult<IR.Naturals>:
  match range:
    case IR.Naturals{+start, +count}: arena_publish_naturals_select(store, start, count, U32.is_eq(count, 0), Bool.and(Bool.not(arena_is_transient(start)), Bool.not(arena_is_reverse(start))))

def arena_publish_term_region(store: ArenaStore, id: U32, temporary: Bool) -> ArenaResult<U32>:
  match temporary:
    case False{}: {ArenaResult{store, id} : ArenaResult<U32>}
    case True{}:
      ArenaResult{next, view} = arena_get_node(store, id)
      arena_publish_term_view(next, view)

def arena_publish_term(store: ArenaStore, +id: U32) -> ArenaResult<U32>:
  arena_publish_term_region(store, id, arena_is_transient(id))

def arena_publish_term_view(v_1: ArenaStore, v_2: Arena.Node) -> ArenaResult<U32>:
  match v_2:
    case Arena.TermVar{v_8, v_9, v_10}:
      arena_put_source_node(v_1, Arena.TermVar{v_8, v_9, v_10})
    case Arena.TermRef{v_14, v_15}:
      arena_put_source_node(v_1, Arena.TermRef{v_14, v_15})
    case Arena.TermBang{v_19, v_20}:
      ArenaResult{v_24, v_25} = arena_publish_term(v_1, v_19)
      arena_put_source_node(v_24, Arena.TermBang{v_25, v_20})
    case Arena.TermSub{v_31, v_32, v_33, v_34}:
      ArenaResult{v_38, v_39} = arena_publish_term(v_1, v_32)
      ArenaResult{v_43, v_44} = arena_publish_term(v_38, v_33)
      arena_put_source_node(v_43, Arena.TermSub{v_31, v_39, v_44, v_34})
    case Arena.TermLet{v_56, v_57, v_58, v_59, v_60, v_61, v_62, v_63, v_64, v_65}:
      ArenaResult{v_69, v_70} = arena_publish_names(v_1, IR.Names{v_56, v_57})
      ArenaResult{v_74, v_75} = arena_publish_naturals(v_69, IR.Naturals{v_58, v_59})
      ArenaResult{v_79, v_80} = arena_publish_quantities(v_74, IR.Quantities{v_60, v_61})
      ArenaResult{v_84, v_85} = arena_publish_terms(v_79, IR.Words{v_62, v_63})
      ArenaResult{v_89, v_90} = arena_publish_term(v_84, v_64)
      v_50000465 = arena_names_start(v_70)
      v_50000466 = arena_names_count(v_70)
      v_50000467 = arena_naturals_start(v_75)
      v_50000468 = arena_naturals_count(v_75)
      v_50000469 = arena_quantities_start(v_80)
      v_50000470 = arena_quantities_count(v_80)
      v_50000471 = arena_words_start(v_85)
      v_50000472 = arena_words_count(v_85)
      arena_put_source_node(v_89, Arena.TermLet{v_50000465, v_50000466, v_50000467, v_50000468, v_50000469, v_50000470, v_50000471, v_50000472, v_90, v_65})
    case Arena.TermAnn{v_103, v_104, v_105}:
      ArenaResult{v_109, v_110} = arena_publish_term(v_1, v_103)
      ArenaResult{v_114, v_115} = arena_publish_term(v_109, v_104)
      arena_put_source_node(v_114, Arena.TermAnn{v_110, v_115, v_105})
    case Arena.TermTemplate{v_119, v_120}:
      ArenaResult{v_124, v_125} = arena_publish_term(v_1, v_119)
      arena_put_source_node(v_124, Arena.TermTemplate{v_125, v_120})
    case Arena.TermType{v_129, v_130}:
      ArenaResult{v_134, v_135} = arena_publish_term(v_1, v_129)
      arena_put_source_node(v_134, Arena.TermType{v_135, v_130})
    case Arena.TermQuant{}:
      arena_put_source_node(v_1, Arena.TermQuant{})
    case Arena.TermQuantity{v_140, v_141}:
      arena_put_source_node(v_1, Arena.TermQuantity{v_140, v_141})
    case Arena.TermMin{v_146, v_147, v_148}:
      ArenaResult{v_152, v_153} = arena_publish_term(v_1, v_146)
      ArenaResult{v_157, v_158} = arena_publish_term(v_152, v_147)
      arena_put_source_node(v_157, Arena.TermMin{v_153, v_158, v_148})
    case Arena.TermAll{v_166, v_167, v_168, v_169, v_170, v_171}:
      ArenaResult{v_175, v_176} = arena_publish_term(v_1, v_169)
      ArenaResult{v_180, v_181} = arena_publish_term(v_175, v_170)
      arena_put_source_node(v_180, Arena.TermAll{v_166, v_167, v_168, v_176, v_181, v_171})
    case Arena.TermLam{v_188, v_189, v_190, v_191, v_192}:
      ArenaResult{v_196, v_197} = arena_publish_term(v_1, v_191)
      arena_put_source_node(v_196, Arena.TermLam{v_188, v_189, v_190, v_197, v_192})
    case Arena.TermApp{v_202, v_203, v_204}:
      ArenaResult{v_208, v_209} = arena_publish_term(v_1, v_202)
      ArenaResult{v_213, v_214} = arena_publish_term(v_208, v_203)
      arena_put_source_node(v_213, Arena.TermApp{v_209, v_214, v_204})
    case Arena.TermAdt{v_222, v_223, v_224, v_225, v_226, v_227}:
      ArenaResult{v_231, v_232} = arena_publish_terms(v_1, IR.Words{v_223, v_224})
      ArenaResult{v_236, v_237} = arena_publish_names(v_231, IR.Names{v_225, v_226})
      v_50000473 = arena_words_start(v_232)
      v_50000474 = arena_words_count(v_232)
      v_50000475 = arena_names_start(v_237)
      v_50000476 = arena_names_count(v_237)
      arena_put_source_node(v_236, Arena.TermAdt{v_222, v_50000473, v_50000474, v_50000475, v_50000476, v_227})
    case Arena.TermFill{v_247, v_248, v_249, v_250}:
      ArenaResult{v_254, v_255} = arena_publish_term(v_1, v_247)
      ArenaResult{v_259, v_260} = arena_publish_terms(v_254, IR.Words{v_248, v_249})
      v_50000477 = arena_words_start(v_260)
      v_50000478 = arena_words_count(v_260)
      arena_put_source_node(v_259, Arena.TermFill{v_255, v_50000477, v_50000478, v_250})
    case Arena.TermPlus{v_268, v_269, v_270, v_271}:
      ArenaResult{v_275, v_276} = arena_publish_term(v_1, v_268)
      ArenaResult{v_280, v_281} = arena_publish_terms(v_275, IR.Words{v_269, v_270})
      v_50000479 = arena_words_start(v_281)
      v_50000480 = arena_words_count(v_281)
      arena_put_source_node(v_280, Arena.TermPlus{v_276, v_50000479, v_50000480, v_271})
    case Arena.TermString{chars, names, span}:
      arena_put_source_node(v_1, Arena.TermString{chars, names, span})
    case Arena.TermCtr{v_289, v_290, v_291, v_292}:
      ArenaResult{v_296, v_297} = arena_publish_terms(v_1, IR.Words{v_290, v_291})
      v_50000481 = arena_words_start(v_297)
      v_50000482 = arena_words_count(v_297)
      arena_put_source_node(v_296, Arena.TermCtr{v_289, v_50000481, v_50000482, v_292})
    case Arena.TermMat{v_305, v_306, v_307, v_308}:
      ArenaResult{v_312, v_313} = arena_publish_term(v_1, v_306)
      ArenaResult{v_317, v_318} = arena_publish_term(v_312, v_307)
      arena_put_source_node(v_317, Arena.TermMat{v_305, v_313, v_318, v_308})
    case Arena.TermAbsurd{v_321}:
      arena_put_source_node(v_1, Arena.TermAbsurd{v_321})
    case Arena.TermEqual{v_327, v_328, v_329, v_330}:
      ArenaResult{v_334, v_335} = arena_publish_term(v_1, v_327)
      ArenaResult{v_339, v_340} = arena_publish_term(v_334, v_328)
      ArenaResult{v_344, v_345} = arena_publish_term(v_339, v_329)
      arena_put_source_node(v_344, Arena.TermEqual{v_335, v_340, v_345, v_330})
    case Arena.TermRefl{v_348}:
      arena_put_source_node(v_1, Arena.TermRefl{v_348})
    case Arena.TermRewrite{v_354, v_355, v_356, v_357}:
      ArenaResult{v_361, v_362} = arena_publish_term(v_1, v_354)
      ArenaResult{v_366, v_367} = arena_publish_term(v_361, v_355)
      ArenaResult{v_371, v_372} = arena_publish_term(v_366, v_356)
      arena_put_source_node(v_371, Arena.TermRewrite{v_362, v_367, v_372, v_357})
    case Arena.TermHole{v_376, v_377}:
      arena_put_source_node(v_1, Arena.TermHole{v_376, v_377})
    case Arena.BodyMatch{v_384, v_385, v_386, v_387, v_388}:
      ArenaResult{v_392, v_393} = arena_publish_terms(v_1, IR.Words{v_384, v_385})
      ArenaResult{v_397, v_398} = arena_publish_terms(v_392, IR.Words{v_386, v_387})
      v_50000483 = arena_words_start(v_393)
      v_50000484 = arena_words_count(v_393)
      v_50000485 = arena_words_start(v_398)
      v_50000486 = arena_words_count(v_398)
      arena_put_source_node(v_397, Arena.BodyMatch{v_50000483, v_50000484, v_50000485, v_50000486, v_388})
    case Arena.BodyCase{v_408, v_409, v_410, v_411}:
      ArenaResult{v_415, v_416} = arena_publish_patterns(v_1, IR.Words{v_408, v_409})
      ArenaResult{v_420, v_421} = arena_publish_term(v_415, v_410)
      v_50000487 = arena_words_start(v_416)
      v_50000488 = arena_words_count(v_416)
      arena_put_source_node(v_420, Arena.BodyCase{v_50000487, v_50000488, v_421, v_411})
    case Arena.BodyLocal{v_432, v_433, v_434, v_435, v_436, v_437, v_438}:
      ArenaResult{v_442, v_443} = arena_publish_patterns(v_1, IR.Words{v_432, v_433})
      ArenaResult{v_447, v_448} = arena_publish_terms(v_442, IR.Words{v_435, v_436})
      ArenaResult{v_452, v_453} = arena_publish_term(v_447, v_437)
      v_50000489 = arena_words_start(v_443)
      v_50000490 = arena_words_count(v_443)
      v_50000491 = arena_words_start(v_448)
      v_50000492 = arena_words_count(v_448)
      arena_put_source_node(v_452, Arena.BodyLocal{v_50000489, v_50000490, v_434, v_50000491, v_50000492, v_453, v_438})
    case Arena.BodyReply{v_461, v_462}:
      ArenaResult{v_466, v_467} = arena_publish_term(v_1, v_461)
      arena_put_source_node(v_466, Arena.BodyReply{v_467, v_462})

def arena_publish_pattern_region(store: ArenaStore, id: U32, temporary: Bool) -> ArenaResult<U32>:
  match temporary:
    case False{}: {ArenaResult{store, id} : ArenaResult<U32>}
    case True{}:
      ArenaResult{next, view} = arena_get_pattern(store, id)
      arena_publish_pattern_view(next, view)

def arena_publish_pattern(store: ArenaStore, +id: U32) -> ArenaResult<U32>:
  arena_publish_pattern_region(store, id, arena_is_transient(id))

def arena_publish_pattern_view(v_1: ArenaStore, v_2: Arena.Pattern) -> ArenaResult<U32>:
  match v_2:
    case Arena.PatternVar{v_9, v_10, v_11, v_12}:
      arena_put_source_pattern(v_1, Arena.PatternVar{v_9, v_10, v_11, v_12})
    case Arena.PatternCtr{v_18, v_19, v_20, v_21}:
      ArenaResult{v_25, v_26} = arena_publish_patterns(v_1, IR.Words{v_19, v_20})
      v_50000493 = arena_words_start(v_26)
      v_50000494 = arena_words_count(v_26)
      arena_put_source_pattern(v_25, Arena.PatternCtr{v_18, v_50000493, v_50000494, v_21})

def arena_publish_binder_region(store: ArenaStore, id: U32, temporary: Bool) -> ArenaResult<U32>:
  match temporary:
    case False{}: {ArenaResult{store, id} : ArenaResult<U32>}
    case True{}:
      ArenaResult{next, view} = arena_get_binder(store, id)
      arena_publish_binder_view(next, view)

def arena_publish_binder(store: ArenaStore, +id: U32) -> ArenaResult<U32>:
  arena_publish_binder_region(store, id, arena_is_transient(id))

def arena_publish_binder_view(store: ArenaStore, view: Arena.Binder) -> ArenaResult<U32>:
  match view:
    case Arena.Binder{field_0, field_1, field_2, field_3, field_4}:
      ArenaResult{next_0, retained_3} = arena_publish_term(store, field_3)
      arena_put_source_binder(next_0, Arena.Binder{field_0, field_1, field_2, retained_3, field_4})
    case Arena.TemplateBinder{field_0, field_1, field_2, field_3}:
      ArenaResult{next_0, retained_2} = arena_publish_term(store, field_2)
      arena_put_source_binder(next_0, Arena.TemplateBinder{field_0, field_1, retained_2, field_3})

# Checker-local lossless AST packing boundary; the unchanged source/step
# generators lower mutual AST/list recursion here, never in imported storage.

def arena_pack_terms_length(items: List<&2, Ast.SyntaxTerm>) -> U32:
  match items:
    case Nil{}: 0
    case _ <> rest: U32.add(1, arena_pack_terms_length(rest))

def arena_pack_terms_at(arena: Arena.Arena, items: List<&2, Ast.SyntaxTerm>, +offset: U32) -> Arena.Arena:
  match items:
    case Nil{}: arena
    case item <> rest:
      (arena2, id) = arena_pack_term(arena, item)
      arena_pack_terms_at(Arena.set_word(arena2, offset, id), rest, U32.add(offset, 1))

def arena_pack_terms(v_0: Arena.Arena, +v_2: List<&2, Ast.SyntaxTerm>) -> Pair(Arena.Arena, Pair(U32, U32)):
  +v_7 = arena_pack_terms_length(v_2)
  arena_pack_terms_reserve_words_result_28(Arena.reserve_words(v_0, v_7), v_2, v_7)

def arena_pack_patterns_length(items: List<&2, Ast.SyntaxPattern>) -> U32:
  match items:
    case Nil{}: 0
    case _ <> rest: U32.add(1, arena_pack_patterns_length(rest))

def arena_pack_patterns_at(arena: Arena.Arena, items: List<&2, Ast.SyntaxPattern>, +offset: U32) -> Arena.Arena:
  match items:
    case Nil{}: arena
    case item <> rest:
      (arena2, id) = arena_pack_pattern(arena, item)
      arena_pack_patterns_at(Arena.set_word(arena2, offset, id), rest, U32.add(offset, 1))

def arena_pack_patterns(v_0: Arena.Arena, +v_2: List<&2, Ast.SyntaxPattern>) -> Pair(Arena.Arena, Pair(U32, U32)):
  +v_7 = arena_pack_patterns_length(v_2)
  arena_pack_patterns_reserve_words_result_29(Arena.reserve_words(v_0, v_7), v_2, v_7)

def arena_pack_binders_length(items: List<&2, Ast.TelescopeItem>) -> U32:
  match items:
    case Nil{}: 0
    case _ <> rest: U32.add(1, arena_pack_binders_length(rest))

def arena_pack_binders_at(arena: Arena.Arena, items: List<&2, Ast.TelescopeItem>, +offset: U32) -> Arena.Arena:
  match items:
    case Nil{}: arena
    case item <> rest:
      (arena2, id) = arena_pack_binder(arena, item)
      arena_pack_binders_at(Arena.set_word(arena2, offset, id), rest, U32.add(offset, 1))

def arena_pack_binders(v_0: Arena.Arena, +v_2: List<&2, Ast.TelescopeItem>) -> Pair(Arena.Arena, Pair(U32, U32)):
  +v_7 = arena_pack_binders_length(v_2)
  arena_pack_binders_reserve_words_result_30(Arena.reserve_words(v_0, v_7), v_2, v_7)

def arena_pack_names_length(items: List<&2, String>) -> U32:
  match items:
    case Nil{}: 0
    case _ <> rest: U32.add(1, arena_pack_names_length(rest))

def arena_pack_names_at(arena: Arena.Arena, items: List<&2, String>, +offset: U32) -> Arena.Arena:
  match items:
    case Nil{}: arena
    case item <> rest:
      arena_pack_names_at_name_result_31(Arena.name(arena, item), offset, rest)

def arena_pack_names(v_0: Arena.Arena, +v_3: List<&2, String>) -> Pair(Arena.Arena, Pair(U32, U32)):
  +v_8 = arena_pack_names_length(v_3)
  arena_pack_names_reserve_words_result_32(Arena.reserve_words(v_0, v_8), v_3, v_8)

def arena_pack_naturals_length(items: List<&2, Nat>) -> U32:
  match items:
    case Nil{}: 0
    case _ <> rest: U32.add(1, arena_pack_naturals_length(rest))

def arena_pack_naturals_at(arena: Arena.Arena, items: List<&2, Nat>, +offset: U32) -> Arena.Arena:
  match items:
    case Nil{}: arena
    case item <> rest:
      arena_pack_naturals_at(Arena.set_natural(arena, offset, item), rest, U32.add(offset, 1))

def arena_pack_naturals(v_0: Arena.Arena, +v_3: List<&2, Nat>) -> Pair(Arena.Arena, Pair(U32, U32)):
  +v_8 = arena_pack_naturals_length(v_3)
  arena_pack_naturals_reserve_naturals_result_33(Arena.reserve_naturals(v_0, v_8), v_3, v_8)

def arena_pack_quantities_length(items: List<&2, Ast.Quantity>) -> U32:
  match items:
    case Nil{}: 0
    case _ <> rest: U32.add(1, arena_pack_quantities_length(rest))

def arena_pack_quantities_at(arena: Arena.Arena, items: List<&2, Ast.Quantity>, +offset: U32) -> Arena.Arena:
  match items:
    case Nil{}: arena
    case item <> rest:
      arena_pack_quantities_at(Arena.set_word(arena, offset, Arena.quantity_word(item)), rest, U32.add(offset, 1))

def arena_pack_quantities(v_0: Arena.Arena, +v_2: List<&2, Ast.Quantity>) -> Pair(Arena.Arena, Pair(U32, U32)):
  +v_7 = arena_pack_quantities_length(v_2)
  arena_pack_quantities_reserve_words_result_34(Arena.reserve_words(v_0, v_7), v_2, v_7)

def arena_pack_term(arena: Arena.Arena, value: Ast.SyntaxTerm) -> Arena.Arena & U32:
  match value:
    case Ast.TermVar{key, index, span}:
      arena_pack_term_name_result_35(Arena.name(arena, key), index, span)
    case Ast.TermRef{key, span}:
      arena_pack_term_name_result_36(Arena.name(arena, key), span)
    case Ast.TermBang{term, span}:
      (arena1, term_id) = arena_pack_term(arena, term)
      Arena.put_node(arena1, Arena.TermBang{term_id, span})
    case Ast.TermSub{index, value, body, span}:
      (arena1, value_id) = arena_pack_term(arena, value)
      (arena2, body_id) = arena_pack_term(arena1, body)
      Arena.put_node(arena2, Arena.TermSub{index, value_id, body_id, span})
    case Ast.TermLet{keys, indexes, quantities, values, body, span}:
      (arena1, (keys_start, keys_count)) = arena_pack_names(arena, keys)
      (arena2, (indexes_start, indexes_count)) = arena_pack_naturals(arena1, indexes)
      (arena3, (quantities_start, quantities_count)) = arena_pack_quantities(arena2, quantities)
      (arena4, (values_start, values_count)) = arena_pack_terms(arena3, values)
      (arena5, body_id) = arena_pack_term(arena4, body)
      Arena.put_node(arena5, Arena.TermLet{keys_start, keys_count, indexes_start, indexes_count, quantities_start, quantities_count, values_start, values_count, body_id, span})
    case Ast.TermAnn{term, ty, span}:
      (arena1, term_id) = arena_pack_term(arena, term)
      (arena2, ty_id) = arena_pack_term(arena1, ty)
      Arena.put_node(arena2, Arena.TermAnn{term_id, ty_id, span})
    case Ast.TermTemplate{term, span}:
      (arena1, term_id) = arena_pack_term(arena, term)
      Arena.put_node(arena1, Arena.TermTemplate{term_id, span})
    case Ast.TermType{kind, span}:
      (arena1, kind_id) = arena_pack_term(arena, kind)
      Arena.put_node(arena1, Arena.TermType{kind_id, span})
    case Ast.TermQuant{}:
      Arena.put_node(arena, Arena.TermQuant{})
    case Ast.TermQuantity{quantity, span}:
      Arena.put_node(arena, Arena.TermQuantity{quantity, span})
    case Ast.TermMin{left, right, span}:
      (arena1, left_id) = arena_pack_term(arena, left)
      (arena2, right_id) = arena_pack_term(arena1, right)
      Arena.put_node(arena2, Arena.TermMin{left_id, right_id, span})
    case Ast.TermAll{quantity, key, index, ty, body, span}:
      arena_pack_term_name_result_37(Arena.name(arena, key), ty, body, quantity, index, span)
    case Ast.TermLam{quantity, key, index, body, span}:
      arena_pack_term_name_result_38(Arena.name(arena, key), body, quantity, index, span)
    case Ast.TermApp{fn, arg, span}:
      (arena1, fn_id) = arena_pack_term(arena, fn)
      (arena2, arg_id) = arena_pack_term(arena1, arg)
      Arena.put_node(arena2, Arena.TermApp{fn_id, arg_id, span})
    case Ast.TermAdt{key, args, refs, span}:
      arena_pack_term_name_result_39(Arena.name(arena, key), args, refs, span)
    case Ast.TermFill{head, args, span}:
      (arena1, head_id) = arena_pack_term(arena, head)
      (arena2, (args_start, args_count)) = arena_pack_terms(arena1, args)
      Arena.put_node(arena2, Arena.TermFill{head_id, args_start, args_count, span})
    case Ast.TermPlus{head, args, span}:
      (arena1, head_id) = arena_pack_term(arena, head)
      (arena2, (args_start, args_count)) = arena_pack_terms(arena1, args)
      Arena.put_node(arena2, Arena.TermPlus{head_id, args_start, args_count, span})
    case Ast.TermString{chars, names, span}:
      Arena.put_node(arena, Arena.TermString{chars, names, span})
    case Ast.TermCtr{key, args, span}:
      arena_pack_term_name_result_40(Arena.name(arena, key), args, span)
    case Ast.TermMat{key, head, matched, span}:
      arena_pack_term_name_result_41(Arena.name(arena, key), head, matched, span)
    case Ast.TermAbsurd{span}:
      Arena.put_node(arena, Arena.TermAbsurd{span})
    case Ast.TermEqual{left, right, ty, span}:
      (arena1, left_id) = arena_pack_term(arena, left)
      (arena2, right_id) = arena_pack_term(arena1, right)
      (arena3, ty_id) = arena_pack_term(arena2, ty)
      Arena.put_node(arena3, Arena.TermEqual{left_id, right_id, ty_id, span})
    case Ast.TermRefl{span}:
      Arena.put_node(arena, Arena.TermRefl{span})
    case Ast.TermRewrite{equation, proof, body, span}:
      (arena1, equation_id) = arena_pack_term(arena, equation)
      (arena2, proof_id) = arena_pack_term(arena1, proof)
      (arena3, body_id) = arena_pack_term(arena2, body)
      Arena.put_node(arena3, Arena.TermRewrite{equation_id, proof_id, body_id, span})
    case Ast.TermHole{key, span}:
      arena_pack_term_name_result_42(Arena.name(arena, key), span)
    case Ast.BodyMatch{scrutinees, cases, span}:
      (arena1, (scrutinees_start, scrutinees_count)) = arena_pack_terms(arena, scrutinees)
      (arena2, (cases_start, cases_count)) = arena_pack_terms(arena1, cases)
      Arena.put_node(arena2, Arena.BodyMatch{scrutinees_start, scrutinees_count, cases_start, cases_count, span})
    case Ast.BodyCase{patterns, body, span}:
      (arena1, (patterns_start, patterns_count)) = arena_pack_patterns(arena, patterns)
      (arena2, body_id) = arena_pack_term(arena1, body)
      Arena.put_node(arena2, Arena.BodyCase{patterns_start, patterns_count, body_id, span})
    case Ast.BodyLocal{patterns, quantity, values, body, span}:
      (arena1, (patterns_start, patterns_count)) = arena_pack_patterns(arena, patterns)
      (arena2, (values_start, values_count)) = arena_pack_terms(arena1, values)
      (arena3, body_id) = arena_pack_term(arena2, body)
      Arena.put_node(arena3, Arena.BodyLocal{patterns_start, patterns_count, quantity, values_start, values_count, body_id, span})
    case Ast.BodyReply{term, span}:
      (arena1, term_id) = arena_pack_term(arena, term)
      Arena.put_node(arena1, Arena.BodyReply{term_id, span})

def arena_pack_pattern(arena: Arena.Arena, value: Ast.SyntaxPattern) -> Arena.Arena & U32:
  match value:
    case Ast.PatternVar{key, index, quantity, span}:
      arena_pack_pattern_name_result_43(Arena.name(arena, key), index, quantity, span)
    case Ast.PatternCtr{key, fields, span}:
      arena_pack_pattern_name_result_44(Arena.name(arena, key), fields, span)

def arena_pack_binder(arena: Arena.Arena, value: Ast.TelescopeItem) -> Arena.Arena & U32:
  match value:
    case Ast.Binder{quantity, key, index, ty, span}:
      arena_pack_binder_name_result_45(Arena.name(arena, key), ty, quantity, index, span)
    case Ast.TemplateBinder{key, index, ty, span}:
      arena_pack_binder_name_result_46(Arena.name(arena, key), ty, index, span)


def arena_pack_clause(arena: Arena.Arena, value: Ast.Clause) -> Arena.Arena & IR.Clause:
  match value:
    case Ast.ClauseFor{field_0, field_1, field_2, field_3, field_4, field_5}:
      (next_0, result_3) = arena_pack_term(arena, field_3)
      (next_1, result_4) = arena_pack_maybe_term(next_0, field_4)
      (next_1, IR.ClauseFor{field_0, field_1, field_2, result_3, result_4, field_5})

def arena_pack_constructor_decl(arena: Arena.Arena, value: Ast.ConstructorDecl) -> Arena.Arena & IR.ConstructorDecl:
  match value:
    case Ast.Constructor{field_0, field_1, field_2}:
      (next_0, positions_1) = arena_pack_binders(arena, field_1)
      (start_1, count_1) = positions_1
      result_1 = IR.Words{start_1, count_1}
      (next_0, IR.Constructor{field_0, result_1, field_2})

def arena_pack_def_body(arena: Arena.Arena, value: Ast.DefBody) -> Arena.Arena & IR.DefBody:
  match value:
    case Ast.DefTerm{field_0}:
      (next_0, result_0) = arena_pack_term(arena, field_0)
      (next_0, IR.DefTerm{result_0})
    case Ast.DefImports{field_0}:
      (next_0, positions_0) = arena_pack_names(arena, field_0)
      (start_0, count_0) = positions_0
      result_0 = IR.Names{start_0, count_0}
      (next_0, IR.DefImports{result_0})

def arena_pack_optional_term(arena: Arena.Arena, value: Ast.OptionalTerm) -> Arena.Arena & IR.OptionalTerm:
  match value:
    case Ast.NoTerm{}:
      (arena, IR.NoTerm{})
    case Ast.SomeTerm{field_0}:
      (next_0, result_0) = arena_pack_term(arena, field_0)
      (next_0, IR.SomeTerm{result_0})

def arena_pack_definition(arena: Arena.Arena, value: Ast.Definition) -> Arena.Arena & IR.Definition:
  match value:
    case Ast.Definition{field_0, field_1, field_2, field_3, field_4, field_5}:
      (next_0, positions_1) = arena_pack_binders(arena, field_1)
      (start_1, count_1) = positions_1
      result_1 = IR.Words{start_1, count_1}
      (next_1, result_2) = arena_pack_optional_term(next_0, field_2)
      (next_2, result_3) = arena_pack_def_body(next_1, field_3)
      (next_2, IR.Definition{field_0, result_1, result_2, result_3, field_4, field_5})

def arena_pack_type_decl(arena: Arena.Arena, value: Ast.TypeDecl) -> Arena.Arena & IR.TypeDecl:
  match value:
    case Ast.TypeDecl{field_0, field_1, field_2, field_3, field_4}:
      (next_0, positions_1) = arena_pack_binders(arena, field_1)
      (start_1, count_1) = positions_1
      result_1 = IR.Words{start_1, count_1}
      (next_1, result_2) = arena_pack_term(next_0, field_2)
      (next_2, result_3) = arena_pack_constructor_decl_list(next_1, field_3)
      (next_2, IR.TypeDecl{field_0, result_1, result_2, result_3, field_4})

def arena_pack_law_decl(arena: Arena.Arena, value: Ast.LawDecl) -> Arena.Arena & IR.LawDecl:
  match value:
    case Ast.LawDecl{field_0, field_1, field_2, field_3}:
      (next_0, result_1) = arena_pack_clause_list(arena, field_1)
      (next_1, result_2) = arena_pack_term(next_0, field_2)
      (next_1, IR.LawDecl{field_0, result_1, result_2, field_3})

def arena_pack_top_level(arena: Arena.Arena, value: Ast.TopLevel) -> Arena.Arena & IR.TopLevel:
  match value:
    case Ast.DefTop{field_0}:
      (next_0, result_0) = arena_pack_definition(arena, field_0)
      (next_0, IR.DefTop{result_0})
    case Ast.TypeTop{field_0}:
      (next_0, result_0) = arena_pack_type_decl(arena, field_0)
      (next_0, IR.TypeTop{result_0})
    case Ast.LawTop{field_0}:
      (next_0, result_0) = arena_pack_law_decl(arena, field_0)
      (next_0, IR.LawTop{result_0})

def arena_pack_module(arena: Arena.Arena, value: Ast.Module) -> Arena.Arena & IR.Module:
  match value:
    case Ast.Module{field_0, field_1, field_2}:
      (next_0, result_2) = arena_pack_top_level_list(arena, field_2)
      (next_0, IR.Module{field_0, field_1, result_2})

def arena_pack_maybe_term(arena: Arena.Arena, value: Maybe<&2, Ast.SyntaxTerm>) -> Arena.Arena & Maybe<&2, U32>:
  match value:
    case None{}: (arena, None{})
    case Some{term}:
      (next, checked) = arena_pack_term(arena, term)
      (next, Some{checked})

def arena_pack_constructor_decl_list(arena: Arena.Arena, values: List<&2, Ast.ConstructorDecl>) -> Arena.Arena & List<&2, IR.ConstructorDecl>:
  match values:
    case Nil{}: (arena, Nil{})
    case head <> tail:
      (next, checked) = arena_pack_constructor_decl(arena, head)
      (last, rest) = arena_pack_constructor_decl_list(next, tail)
      (last, checked <> rest)

def arena_pack_clause_list(arena: Arena.Arena, values: List<&2, Ast.Clause>) -> Arena.Arena & List<&2, IR.Clause>:
  match values:
    case Nil{}: (arena, Nil{})
    case head <> tail:
      (next, checked) = arena_pack_clause(arena, head)
      (last, rest) = arena_pack_clause_list(next, tail)
      (last, checked <> rest)

def arena_pack_top_level_list(arena: Arena.Arena, values: List<&2, Ast.TopLevel>) -> Arena.Arena & List<&2, IR.TopLevel>:
  match values:
    case Nil{}: (arena, Nil{})
    case head <> tail:
      (next, checked) = arena_pack_top_level(arena, head)
      (last, rest) = arena_pack_top_level_list(next, tail)
      (last, checked <> rest)

def arena_publish_clause(arena: ArenaStore, value: IR.Clause) -> ArenaResult<IR.Clause>:
  match value:
    case IR.ClauseFor{field_0, field_1, field_2, field_3, field_4, field_5}:
      ArenaResult{next_0, result_3} = arena_publish_term(arena, field_3)
      ArenaResult{next_1, result_4} = arena_publish_maybe_term(next_0, field_4)
      {ArenaResult{next_1, IR.ClauseFor{field_0, field_1, field_2, result_3, result_4, field_5}} : ArenaResult<IR.Clause>}

def arena_publish_constructor_decl(arena: ArenaStore, value: IR.ConstructorDecl) -> ArenaResult<IR.ConstructorDecl>:
  match value:
    case IR.Constructor{field_0, field_1, field_2}:
      ArenaResult{next_0, result_1} = arena_publish_binders(arena, field_1)
      {ArenaResult{next_0, IR.Constructor{field_0, result_1, field_2}} : ArenaResult<IR.ConstructorDecl>}

def arena_publish_def_body(arena: ArenaStore, value: IR.DefBody) -> ArenaResult<IR.DefBody>:
  match value:
    case IR.DefTerm{field_0}:
      ArenaResult{next_0, result_0} = arena_publish_term(arena, field_0)
      {ArenaResult{next_0, IR.DefTerm{result_0}} : ArenaResult<IR.DefBody>}
    case IR.DefImports{field_0}:
      ArenaResult{next_0, result_0} = arena_publish_names(arena, field_0)
      {ArenaResult{next_0, IR.DefImports{result_0}} : ArenaResult<IR.DefBody>}

def arena_publish_optional_term(arena: ArenaStore, value: IR.OptionalTerm) -> ArenaResult<IR.OptionalTerm>:
  match value:
    case IR.NoTerm{}:
      {ArenaResult{arena, IR.NoTerm{}} : ArenaResult<IR.OptionalTerm>}
    case IR.SomeTerm{field_0}:
      ArenaResult{next_0, result_0} = arena_publish_term(arena, field_0)
      {ArenaResult{next_0, IR.SomeTerm{result_0}} : ArenaResult<IR.OptionalTerm>}

def arena_publish_definition(arena: ArenaStore, value: IR.Definition) -> ArenaResult<IR.Definition>:
  match value:
    case IR.Definition{field_0, field_1, field_2, field_3, field_4, field_5}:
      ArenaResult{next_0, result_1} = arena_publish_binders(arena, field_1)
      ArenaResult{next_1, result_2} = arena_publish_optional_term(next_0, field_2)
      ArenaResult{next_2, result_3} = arena_publish_def_body(next_1, field_3)
      {ArenaResult{next_2, IR.Definition{field_0, result_1, result_2, result_3, field_4, field_5}} : ArenaResult<IR.Definition>}

def arena_publish_type_decl(arena: ArenaStore, value: IR.TypeDecl) -> ArenaResult<IR.TypeDecl>:
  match value:
    case IR.TypeDecl{field_0, field_1, field_2, field_3, field_4}:
      ArenaResult{next_0, result_1} = arena_publish_binders(arena, field_1)
      ArenaResult{next_1, result_2} = arena_publish_term(next_0, field_2)
      ArenaResult{next_2, result_3} = arena_publish_constructor_decl_list(next_1, field_3)
      {ArenaResult{next_2, IR.TypeDecl{field_0, result_1, result_2, result_3, field_4}} : ArenaResult<IR.TypeDecl>}

def arena_publish_law_decl(arena: ArenaStore, value: IR.LawDecl) -> ArenaResult<IR.LawDecl>:
  match value:
    case IR.LawDecl{field_0, field_1, field_2, field_3}:
      ArenaResult{next_0, result_1} = arena_publish_clause_list(arena, field_1)
      ArenaResult{next_1, result_2} = arena_publish_term(next_0, field_2)
      {ArenaResult{next_1, IR.LawDecl{field_0, result_1, result_2, field_3}} : ArenaResult<IR.LawDecl>}

def arena_publish_top_level(arena: ArenaStore, value: IR.TopLevel) -> ArenaResult<IR.TopLevel>:
  match value:
    case IR.DefTop{field_0}:
      ArenaResult{next_0, result_0} = arena_publish_definition(arena, field_0)
      {ArenaResult{next_0, IR.DefTop{result_0}} : ArenaResult<IR.TopLevel>}
    case IR.TypeTop{field_0}:
      ArenaResult{next_0, result_0} = arena_publish_type_decl(arena, field_0)
      {ArenaResult{next_0, IR.TypeTop{result_0}} : ArenaResult<IR.TopLevel>}
    case IR.LawTop{field_0}:
      ArenaResult{next_0, result_0} = arena_publish_law_decl(arena, field_0)
      {ArenaResult{next_0, IR.LawTop{result_0}} : ArenaResult<IR.TopLevel>}

def arena_publish_module(arena: ArenaStore, value: IR.Module) -> ArenaResult<IR.Module>:
  match value:
    case IR.Module{field_0, field_1, field_2}:
      ArenaResult{next_0, result_2} = arena_publish_top_level_list(arena, field_2)
      {ArenaResult{next_0, IR.Module{field_0, field_1, result_2}} : ArenaResult<IR.Module>}

def arena_publish_maybe_term(arena: ArenaStore, value: Maybe<&2, U32>) -> ArenaResult<Maybe<&2, U32>>:
  match value:
    case None{}: {ArenaResult{arena, None{}} : ArenaResult<Maybe<&2, U32>>}
    case Some{term}:
      ArenaResult{next, checked} = arena_publish_term(arena, term)
      {ArenaResult{next, Some{checked}} : ArenaResult<Maybe<&2, U32>>}

def arena_publish_constructor_decl_list(arena: ArenaStore, values: List<&2, IR.ConstructorDecl>) -> ArenaResult<List<&2, IR.ConstructorDecl>>:
  match values:
    case Nil{}: {ArenaResult{arena, []} : ArenaResult<List<&2, IR.ConstructorDecl>>}
    case head <> tail:
      ArenaResult{next, checked} = arena_publish_constructor_decl(arena, head)
      ArenaResult{last, rest} = arena_publish_constructor_decl_list(next, tail)
      {ArenaResult{last, checked <> rest} : ArenaResult<List<&2, IR.ConstructorDecl>>}

def arena_publish_clause_list(arena: ArenaStore, values: List<&2, IR.Clause>) -> ArenaResult<List<&2, IR.Clause>>:
  match values:
    case Nil{}: {ArenaResult{arena, []} : ArenaResult<List<&2, IR.Clause>>}
    case head <> tail:
      ArenaResult{next, checked} = arena_publish_clause(arena, head)
      ArenaResult{last, rest} = arena_publish_clause_list(next, tail)
      {ArenaResult{last, checked <> rest} : ArenaResult<List<&2, IR.Clause>>}

def arena_publish_top_level_list(arena: ArenaStore, values: List<&2, IR.TopLevel>) -> ArenaResult<List<&2, IR.TopLevel>>:
  match values:
    case Nil{}: {ArenaResult{arena, []} : ArenaResult<List<&2, IR.TopLevel>>}
    case head <> tail:
      ArenaResult{next, checked} = arena_publish_top_level(arena, head)
      ArenaResult{last, rest} = arena_publish_top_level_list(next, tail)
      {ArenaResult{last, checked <> rest} : ArenaResult<List<&2, IR.TopLevel>>}

def arena_decode_clause(arena: Arena.Arena, value: IR.Clause) -> Arena.Arena & Ast.Clause:
  match value:
    case IR.ClauseFor{field_0, field_1, field_2, field_3, field_4, field_5}:
      (next_0, result_3) = arena_decode_term(arena, field_3)
      (next_1, result_4) = arena_decode_maybe_term(next_0, field_4)
      (next_1, Ast.ClauseFor{field_0, field_1, field_2, result_3, result_4, field_5})

def arena_decode_constructor_decl(arena: Arena.Arena, value: IR.ConstructorDecl) -> Arena.Arena & Ast.ConstructorDecl:
  match value:
    case IR.Constructor{field_0, field_1, field_2}:
      (next_0, result_1) = arena_decode_binders(arena, arena_words_start(field_1), arena_words_count(field_1))
      (next_0, Ast.Constructor{field_0, result_1, field_2})

def arena_decode_def_body(arena: Arena.Arena, value: IR.DefBody) -> Arena.Arena & Ast.DefBody:
  match value:
    case IR.DefTerm{field_0}:
      (next_0, result_0) = arena_decode_term(arena, field_0)
      (next_0, Ast.DefTerm{result_0})
    case IR.DefImports{field_0}:
      (next_0, result_0) = arena_decode_names(arena, arena_names_start(field_0), arena_names_count(field_0))
      (next_0, Ast.DefImports{result_0})

def arena_decode_optional_term(arena: Arena.Arena, value: IR.OptionalTerm) -> Arena.Arena & Ast.OptionalTerm:
  match value:
    case IR.NoTerm{}:
      (arena, Ast.NoTerm{})
    case IR.SomeTerm{field_0}:
      (next_0, result_0) = arena_decode_term(arena, field_0)
      (next_0, Ast.SomeTerm{result_0})

def arena_decode_definition(arena: Arena.Arena, value: IR.Definition) -> Arena.Arena & Ast.Definition:
  match value:
    case IR.Definition{field_0, field_1, field_2, field_3, field_4, field_5}:
      (next_0, result_1) = arena_decode_binders(arena, arena_words_start(field_1), arena_words_count(field_1))
      (next_1, result_2) = arena_decode_optional_term(next_0, field_2)
      (next_2, result_3) = arena_decode_def_body(next_1, field_3)
      (next_2, Ast.Definition{field_0, result_1, result_2, result_3, field_4, field_5})

def arena_decode_type_decl(arena: Arena.Arena, value: IR.TypeDecl) -> Arena.Arena & Ast.TypeDecl:
  match value:
    case IR.TypeDecl{field_0, field_1, field_2, field_3, field_4}:
      (next_0, result_1) = arena_decode_binders(arena, arena_words_start(field_1), arena_words_count(field_1))
      (next_1, result_2) = arena_decode_term(next_0, field_2)
      (next_2, result_3) = arena_decode_constructor_decl_list(next_1, field_3)
      (next_2, Ast.TypeDecl{field_0, result_1, result_2, result_3, field_4})

def arena_decode_law_decl(arena: Arena.Arena, value: IR.LawDecl) -> Arena.Arena & Ast.LawDecl:
  match value:
    case IR.LawDecl{field_0, field_1, field_2, field_3}:
      (next_0, result_1) = arena_decode_clause_list(arena, field_1)
      (next_1, result_2) = arena_decode_term(next_0, field_2)
      (next_1, Ast.LawDecl{field_0, result_1, result_2, field_3})

def arena_decode_top_level(arena: Arena.Arena, value: IR.TopLevel) -> Arena.Arena & Ast.TopLevel:
  match value:
    case IR.DefTop{field_0}:
      (next_0, result_0) = arena_decode_definition(arena, field_0)
      (next_0, Ast.DefTop{result_0})
    case IR.TypeTop{field_0}:
      (next_0, result_0) = arena_decode_type_decl(arena, field_0)
      (next_0, Ast.TypeTop{result_0})
    case IR.LawTop{field_0}:
      (next_0, result_0) = arena_decode_law_decl(arena, field_0)
      (next_0, Ast.LawTop{result_0})

def arena_decode_module(arena: Arena.Arena, value: IR.Module) -> Arena.Arena & Ast.Module:
  match value:
    case IR.Module{field_0, field_1, field_2}:
      (next_0, result_2) = arena_decode_top_level_list(arena, field_2)
      (next_0, Ast.Module{field_0, field_1, result_2})

def arena_decode_maybe_term(arena: Arena.Arena, value: Maybe<&2, U32>) -> Arena.Arena & Maybe<&2, Ast.SyntaxTerm>:
  match value:
    case None{}: (arena, None{})
    case Some{term}:
      (next, checked) = arena_decode_term(arena, term)
      (next, Some{checked})

def arena_decode_constructor_decl_list(arena: Arena.Arena, values: List<&2, IR.ConstructorDecl>) -> Arena.Arena & List<&2, Ast.ConstructorDecl>:
  match values:
    case Nil{}: (arena, Nil{})
    case head <> tail:
      (next, checked) = arena_decode_constructor_decl(arena, head)
      (last, rest) = arena_decode_constructor_decl_list(next, tail)
      (last, checked <> rest)

def arena_decode_clause_list(arena: Arena.Arena, values: List<&2, IR.Clause>) -> Arena.Arena & List<&2, Ast.Clause>:
  match values:
    case Nil{}: (arena, Nil{})
    case head <> tail:
      (next, checked) = arena_decode_clause(arena, head)
      (last, rest) = arena_decode_clause_list(next, tail)
      (last, checked <> rest)

def arena_decode_top_level_list(arena: Arena.Arena, values: List<&2, IR.TopLevel>) -> Arena.Arena & List<&2, Ast.TopLevel>:
  match values:
    case Nil{}: (arena, Nil{})
    case head <> tail:
      (next, checked) = arena_decode_top_level(arena, head)
      (last, rest) = arena_decode_top_level_list(next, tail)
      (last, checked <> rest)

# Checker-local boundary adapters. These ID-recursive definitions must remain
# local to checker.bend so the unchanged checker source/step generators lower
# their recursion. Arena storage itself contains no recursive-ID decoders.

def arena_decode_terms_go(arena: Arena.Arena, +start: U32, remaining: Nat) -> Arena.Arena & List<&2, Ast.SyntaxTerm>:
  match remaining:
    case 0n: (arena, Nil{})
    case 1n+rest:
      arena_decode_terms_go_word_result_47(Arena.word(arena, start), start, rest)

def arena_decode_terms(arena: Arena.Arena, start: U32, count: U32) -> Arena.Arena & List<&2, Ast.SyntaxTerm>:
  arena_decode_terms_go(arena, start, U32.to_nat(count))

def arena_decode_patterns_go(arena: Arena.Arena, +start: U32, remaining: Nat) -> Arena.Arena & List<&2, Ast.SyntaxPattern>:
  match remaining:
    case 0n: (arena, Nil{})
    case 1n+rest:
      arena_decode_patterns_go_word_result_48(Arena.word(arena, start), start, rest)

def arena_decode_patterns(arena: Arena.Arena, start: U32, count: U32) -> Arena.Arena & List<&2, Ast.SyntaxPattern>:
  arena_decode_patterns_go(arena, start, U32.to_nat(count))

def arena_decode_binders_go(arena: Arena.Arena, +start: U32, remaining: Nat) -> Arena.Arena & List<&2, Ast.TelescopeItem>:
  match remaining:
    case 0n: (arena, Nil{})
    case 1n+rest:
      arena_decode_binders_go_word_result_49(Arena.word(arena, start), start, rest)

def arena_decode_binders(arena: Arena.Arena, start: U32, count: U32) -> Arena.Arena & List<&2, Ast.TelescopeItem>:
  arena_decode_binders_go(arena, start, U32.to_nat(count))

def arena_decode_names_go(arena: Arena.Arena, +start: U32, remaining: Nat) -> Arena.Arena & List<&2, String>:
  match remaining:
    case 0n: (arena, Nil{})
    case 1n+rest:
      arena_decode_names_go_word_result_50(Arena.word(arena, start), start, rest)

def arena_decode_names(arena: Arena.Arena, start: U32, count: U32) -> Arena.Arena & List<&2, String>:
  arena_decode_names_go(arena, start, U32.to_nat(count))

def arena_decode_naturals_go(arena: Arena.Arena, +start: U32, remaining: Nat) -> Arena.Arena & List<&2, Nat>:
  match remaining:
    case 0n: (arena, Nil{})
    case 1n+rest:
      arena_decode_naturals_go_natural_result_52(Arena.natural(arena, start), start, rest)

def arena_decode_naturals(arena: Arena.Arena, start: U32, count: U32) -> Arena.Arena & List<&2, Nat>:
  arena_decode_naturals_go(arena, start, U32.to_nat(count))

def arena_decode_quantities_go(arena: Arena.Arena, +start: U32, remaining: Nat) -> Arena.Arena & List<&2, Ast.Quantity>:
  match remaining:
    case 0n: (arena, Nil{})
    case 1n+rest:
      arena_decode_quantities_go_word_result_53(Arena.word(arena, start), start, rest)

def arena_decode_quantities(arena: Arena.Arena, start: U32, count: U32) -> Arena.Arena & List<&2, Ast.Quantity>:
  arena_decode_quantities_go(arena, start, U32.to_nat(count))

def arena_decode_term(arena: Arena.Arena, id: U32) -> Arena.Arena & Ast.SyntaxTerm:
  arena_decode_term_get_node_result_54(Arena.get_node(arena, id))

def arena_decode_pattern(arena: Arena.Arena, id: U32) -> Arena.Arena & Ast.SyntaxPattern:
  arena_decode_pattern_get_pattern_result_63(Arena.get_pattern(arena, id))

def arena_decode_binder(arena: Arena.Arena, id: U32) -> Arena.Arena & Ast.TelescopeItem:
  arena_decode_binder_get_binder_result_66(Arena.get_binder(arena, id))

def arena_publish_global(store: ArenaStore, global: Scope.ArenaGlobal) -> ArenaResult<Scope.ArenaGlobal>:
  match global:
    case Scope.ArenaGlobal{key, namespace, local_key, ty, value, kind}:
      ArenaResult{next, retained_ty} = arena_publish_term(store, ty)
      ArenaResult{last, retained_value} = arena_publish_optional_term(next, value)
      {ArenaResult{last, Scope.ArenaGlobal{key, namespace, local_key, retained_ty, retained_value, kind}} : ArenaResult<Scope.ArenaGlobal>}

def arena_constructor_owner(store: ArenaStore, ty: U32) -> ArenaResult<Maybe<&2, String>>:
  ArenaResult{next, view} = arena_get_node(store, ty)
  arena_constructor_owner_view(next, view)

def arena_constructor_owner_view(store: ArenaStore, view: Arena.Node) -> ArenaResult<Maybe<&2, String>>:
  match view:
    case Arena.TermAll{_, _, _, _, body, _}: arena_constructor_owner(store, body)
    case Arena.TermAdt{key, _, _, _, _, _}:
      ArenaResult{next, text} = arena_name_text(store, key)
      {ArenaResult{next, Some{text}} : ArenaResult<Maybe<&2, String>>}
    case _: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, String>>}

def scope_constructor_equality_after(store: ArenaStore, result: Maybe<&2, Bool>, a: IR.Words, b: IR.Words, scope: Scope.ArenaGlobalScope) -> ArenaResult<Maybe<&2, Bool>>:
  match result:
    case Some{True{}}: scope_constructor_lists_equal(store, a, b, scope)
    case Some{False{}}: {ArenaResult{store, Some{False{}}} : ArenaResult<Maybe<&2, Bool>>}
    case None{}: {ArenaResult{store, None{}} : ArenaResult<Maybe<&2, Bool>>}

def arena_pack_globals(arena: Arena.Arena, globals: List<&2, Scope.Global>) -> Arena.Arena & List<&2, Scope.ArenaGlobal>:
  match globals:
    case Nil{}: (arena, Nil{})
    case Scope.Global{key, namespace, local_key, ty, value, kind} <> rest:
      (typed, packed_ty) = arena_pack_term(arena, ty)
      (valued, packed_value) = arena_pack_optional_term(typed, value)
      (last, packed_rest) = arena_pack_globals(valued, rest)
      (last, Scope.ArenaGlobal{key, namespace, local_key, packed_ty, packed_value, kind} <> packed_rest)

def arena_pack_modules(arena: Arena.Arena, modules: List<&2, Loader.LoadedModule>) -> Arena.Arena & List<&2, IR.LoadedModule>:
  match modules:
    case Nil{}: (arena, Nil{})
    case Loader.LoadedModule{namespace, module} <> rest:
      (next, packed) = arena_pack_module(arena, module)
      (last, tail) = arena_pack_modules(next, rest)
      (last, IR.LoadedModule{namespace, packed} <> tail)

def arena_decode_modules(arena: Arena.Arena, modules: List<&2, IR.LoadedModule>) -> Arena.Arena & List<&2, Loader.LoadedModule>:
  match modules:
    case Nil{}: (arena, Nil{})
    case IR.LoadedModule{namespace, module} <> rest:
      (next, decoded) = arena_decode_module(arena, module)
      (last, tail) = arena_decode_modules(next, rest)
      (last, Loader.LoadedModule{namespace, decoded} <> tail)

def arena_check_exit(source: Arena.Arena, result: PrivateResult) -> CheckResult:
  match result:
    case PrivateFailure{diagnostic}: CheckFailure{diagnostic}
    case PrivateSuccess{modules}:
      (released, decoded) = arena_decode_modules(source, modules)
      CheckSuccess{decoded}

def arena_check_result(result: ArenaResult<PrivateResult>) -> CheckResult:
  match result:
    case ArenaResult{ArenaStore{source, _}, checked}: arena_check_exit(source, checked)

def arena_check_entry(modules: List<&2, Loader.LoadedModule>, globals: List<&2, Scope.Global>) -> CheckResult:
  (packed, private_modules) = arena_pack_modules(Arena.empty(), modules)
  (source, private_globals) = arena_pack_globals(packed, globals)
  arena_check_result(check_modules_private(ArenaStore{source, Arena.empty()}, private_modules, private_globals))

def check_modules(modules: List<&2, Loader.LoadedModule>, globals: List<&2, Scope.Global>) -> CheckResult:
  arena_check_entry(modules, globals)

# Match imported affine storage results through typed parameters: native
# lowering cannot keep constructor-pattern locals with computed right-hand sides.

def arena_name_name_result_0(v_70000000: Pair(Arena.Arena, U32), v_9: Arena.Arena) -> ArenaResult<U32>:
  match v_70000000:
    case (v_12, v_13):
      {ArenaResult{ArenaStore{v_12, v_9}, v_13} : ArenaResult<U32>}

def arena_get_node_region_get_node_result_2(v_70000002: Pair(Arena.Arena, Arena.Node), v_1: Arena.Arena) -> ArenaResult<Arena.Node>:
  match v_70000002:
    case (v_10, v_11):
      {ArenaResult{ArenaStore{v_10, v_1}, v_11} : ArenaResult<Arena.Node>}

def arena_get_node_region_get_node_result_3(v_70000003: Pair(Arena.Arena, Arena.Node), v_0: Arena.Arena) -> ArenaResult<Arena.Node>:
  match v_70000003:
    case (v_15, v_16):
      {ArenaResult{ArenaStore{v_0, v_15}, v_16} : ArenaResult<Arena.Node>}

def arena_put_node_put_node_result_4(v_70000004: Pair(Arena.Arena, U32), v_7: Arena.Arena) -> ArenaResult<U32>:
  match v_70000004:
    case (v_11, v_12):
      {ArenaResult{ArenaStore{v_7, v_11}, U32.or(v_12, 2147483648)} : ArenaResult<U32>}

def arena_put_source_node_put_node_result_5(v_70000005: Pair(Arena.Arena, U32), v_8: Arena.Arena) -> ArenaResult<U32>:
  match v_70000005:
    case (v_11, v_12):
      {ArenaResult{ArenaStore{v_11, v_8}, v_12} : ArenaResult<U32>}

def arena_get_pattern_region_get_pattern_result_6(v_70000006: Pair(Arena.Arena, Arena.Pattern), v_1: Arena.Arena) -> ArenaResult<Arena.Pattern>:
  match v_70000006:
    case (v_10, v_11):
      {ArenaResult{ArenaStore{v_10, v_1}, v_11} : ArenaResult<Arena.Pattern>}

def arena_get_pattern_region_get_pattern_result_7(v_70000007: Pair(Arena.Arena, Arena.Pattern), v_0: Arena.Arena) -> ArenaResult<Arena.Pattern>:
  match v_70000007:
    case (v_15, v_16):
      {ArenaResult{ArenaStore{v_0, v_15}, v_16} : ArenaResult<Arena.Pattern>}

def arena_put_pattern_put_pattern_result_8(v_70000008: Pair(Arena.Arena, U32), v_7: Arena.Arena) -> ArenaResult<U32>:
  match v_70000008:
    case (v_11, v_12):
      {ArenaResult{ArenaStore{v_7, v_11}, U32.or(v_12, 2147483648)} : ArenaResult<U32>}

def arena_put_source_pattern_put_pattern_result_9(v_70000009: Pair(Arena.Arena, U32), v_8: Arena.Arena) -> ArenaResult<U32>:
  match v_70000009:
    case (v_11, v_12):
      {ArenaResult{ArenaStore{v_11, v_8}, v_12} : ArenaResult<U32>}

def arena_get_binder_region_get_binder_result_10(v_70000010: Pair(Arena.Arena, Arena.Binder), v_1: Arena.Arena) -> ArenaResult<Arena.Binder>:
  match v_70000010:
    case (v_10, v_11):
      {ArenaResult{ArenaStore{v_10, v_1}, v_11} : ArenaResult<Arena.Binder>}

def arena_get_binder_region_get_binder_result_11(v_70000011: Pair(Arena.Arena, Arena.Binder), v_0: Arena.Arena) -> ArenaResult<Arena.Binder>:
  match v_70000011:
    case (v_15, v_16):
      {ArenaResult{ArenaStore{v_0, v_15}, v_16} : ArenaResult<Arena.Binder>}

def arena_put_binder_put_binder_result_12(v_70000012: Pair(Arena.Arena, U32), v_7: Arena.Arena) -> ArenaResult<U32>:
  match v_70000012:
    case (v_11, v_12):
      {ArenaResult{ArenaStore{v_7, v_11}, U32.or(v_12, 2147483648)} : ArenaResult<U32>}

def arena_put_source_binder_put_binder_result_13(v_70000013: Pair(Arena.Arena, U32), v_8: Arena.Arena) -> ArenaResult<U32>:
  match v_70000013:
    case (v_11, v_12):
      {ArenaResult{ArenaStore{v_11, v_8}, v_12} : ArenaResult<U32>}

def arena_get_word_region_word_result_14(v_70000014: Pair(Arena.Arena, U32), v_1: Arena.Arena) -> ArenaResult<U32>:
  match v_70000014:
    case (v_11, v_12):
      {ArenaResult{ArenaStore{v_11, v_1}, v_12} : ArenaResult<U32>}

def arena_get_word_region_word_result_15(v_70000015: Pair(Arena.Arena, U32), v_0: Arena.Arena) -> ArenaResult<U32>:
  match v_70000015:
    case (v_16, v_17):
      {ArenaResult{ArenaStore{v_0, v_16}, v_17} : ArenaResult<U32>}

def arena_put_word_put_word_result_16(v_70000016: Pair(Arena.Arena, U32), v_8: Arena.Arena) -> ArenaResult<U32>:
  match v_70000016:
    case (v_12, v_13):
      {ArenaResult{ArenaStore{v_8, v_12}, U32.or(v_13, 2147483648)} : ArenaResult<U32>}

def arena_put_source_word_put_word_result_17(v_70000017: Pair(Arena.Arena, U32), v_9: Arena.Arena) -> ArenaResult<U32>:
  match v_70000017:
    case (v_12, v_13):
      {ArenaResult{ArenaStore{v_12, v_9}, v_13} : ArenaResult<U32>}

def arena_get_natural_region_natural_result_18(v_70000018: Pair(Arena.Arena, Nat), v_1: Arena.Arena) -> ArenaResult<Nat>:
  match v_70000018:
    case (v_11, v_12):
      {ArenaResult{ArenaStore{v_11, v_1}, v_12} : ArenaResult<Nat>}

def arena_get_natural_region_natural_result_19(v_70000019: Pair(Arena.Arena, Nat), v_0: Arena.Arena) -> ArenaResult<Nat>:
  match v_70000019:
    case (v_16, v_17):
      {ArenaResult{ArenaStore{v_0, v_16}, v_17} : ArenaResult<Nat>}

def arena_put_natural_put_natural_result_20(v_70000020: Pair(Arena.Arena, U32), v_8: Arena.Arena) -> ArenaResult<U32>:
  match v_70000020:
    case (v_12, v_13):
      {ArenaResult{ArenaStore{v_8, v_12}, U32.or(v_13, 2147483648)} : ArenaResult<U32>}

def arena_put_source_natural_put_natural_result_21(v_70000021: Pair(Arena.Arena, U32), v_9: Arena.Arena) -> ArenaResult<U32>:
  match v_70000021:
    case (v_12, v_13):
      {ArenaResult{ArenaStore{v_12, v_9}, v_13} : ArenaResult<U32>}

def arena_reserve_words_reserve_words_result_22(v_70000022: Pair(Arena.Arena, U32), v_8: Arena.Arena) -> ArenaResult<U32>:
  match v_70000022:
    case (v_12, v_13):
      {ArenaResult{ArenaStore{v_8, v_12}, U32.or(v_13, 2147483648)} : ArenaResult<U32>}

def arena_reserve_source_words_reserve_words_result_23(v_70000023: Pair(Arena.Arena, U32), v_9: Arena.Arena) -> ArenaResult<U32>:
  match v_70000023:
    case (v_12, v_13):
      {ArenaResult{ArenaStore{v_12, v_9}, v_13} : ArenaResult<U32>}

def arena_word_cursor_word_count_result_24(v_70000024: Pair(Arena.Arena, U32), v_6: Arena.Arena) -> ArenaResult<U32>:
  match v_70000024:
    case (v_10, v_11):
      {ArenaResult{ArenaStore{v_6, v_10}, v_11} : ArenaResult<U32>}

def arena_reserve_naturals_reserve_naturals_result_25(v_70000025: Pair(Arena.Arena, U32), v_8: Arena.Arena) -> ArenaResult<U32>:
  match v_70000025:
    case (v_12, v_13):
      {ArenaResult{ArenaStore{v_8, v_12}, U32.or(v_13, 2147483648)} : ArenaResult<U32>}

def arena_reserve_source_naturals_reserve_naturals_result_26(v_70000026: Pair(Arena.Arena, U32), v_9: Arena.Arena) -> ArenaResult<U32>:
  match v_70000026:
    case (v_12, v_13):
      {ArenaResult{ArenaStore{v_12, v_9}, v_13} : ArenaResult<U32>}

def arena_natural_cursor_natural_count_result_27(v_70000027: Pair(Arena.Arena, U32), v_6: Arena.Arena) -> ArenaResult<U32>:
  match v_70000027:
    case (v_10, v_11):
      {ArenaResult{ArenaStore{v_6, v_10}, v_11} : ArenaResult<U32>}

def arena_pack_terms_reserve_words_result_28(v_70000028: Pair(Arena.Arena, U32), +v_2: List<&2, Ast.SyntaxTerm>, +v_9: U32) -> Pair(Arena.Arena, Pair(U32, U32)):
  match v_70000028:
    case (v_12, +v_13):
      v_16 = arena_pack_terms_at(v_12, v_2, v_13)
      (v_16, v_13, v_9)

def arena_pack_patterns_reserve_words_result_29(v_70000029: Pair(Arena.Arena, U32), +v_2: List<&2, Ast.SyntaxPattern>, +v_9: U32) -> Pair(Arena.Arena, Pair(U32, U32)):
  match v_70000029:
    case (v_12, +v_13):
      v_16 = arena_pack_patterns_at(v_12, v_2, v_13)
      (v_16, v_13, v_9)

def arena_pack_binders_reserve_words_result_30(v_70000030: Pair(Arena.Arena, U32), +v_2: List<&2, Ast.TelescopeItem>, +v_9: U32) -> Pair(Arena.Arena, Pair(U32, U32)):
  match v_70000030:
    case (v_12, +v_13):
      v_16 = arena_pack_binders_at(v_12, v_2, v_13)
      (v_16, v_13, v_9)

def arena_pack_names_at_name_result_31(v_70000031: Pair(Arena.Arena, U32), +v_5: U32, v_9: List<&2, String>) -> Arena.Arena:
  match v_70000031:
    case (v_12, v_13):
      arena_pack_names_at(Arena.set_word(v_12, v_5, v_13), v_9, U32.add(v_5, 1))

def arena_pack_names_reserve_words_result_32(v_70000032: Pair(Arena.Arena, U32), +v_3: List<&2, String>, +v_10: U32) -> Pair(Arena.Arena, Pair(U32, U32)):
  match v_70000032:
    case (v_13, +v_14):
      v_17 = arena_pack_names_at(v_13, v_3, v_14)
      (v_17, v_14, v_10)

def arena_pack_naturals_reserve_naturals_result_33(v_70000033: Pair(Arena.Arena, U32), +v_3: List<&2, Nat>, +v_10: U32) -> Pair(Arena.Arena, Pair(U32, U32)):
  match v_70000033:
    case (v_13, +v_14):
      v_17 = arena_pack_naturals_at(v_13, v_3, v_14)
      (v_17, v_14, v_10)

def arena_pack_quantities_reserve_words_result_34(v_70000034: Pair(Arena.Arena, U32), +v_2: List<&2, Ast.Quantity>, +v_9: U32) -> Pair(Arena.Arena, Pair(U32, U32)):
  match v_70000034:
    case (v_12, +v_13):
      v_16 = arena_pack_quantities_at(v_12, v_2, v_13)
      (v_16, v_13, v_9)

def arena_pack_term_name_result_35(v_70000035: Pair(Arena.Arena, U32), v_7: Nat, v_8: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000035:
    case (v_11, v_12):
      Arena.put_node(v_11, Arena.TermVar{v_12, v_7, v_8})

def arena_pack_term_name_result_36(v_70000036: Pair(Arena.Arena, U32), v_16: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000036:
    case (v_19, v_20):
      Arena.put_node(v_19, Arena.TermRef{v_20, v_16})

def arena_pack_term_name_result_37(v_70000037: Pair(Arena.Arena, U32), v_155: Ast.SyntaxTerm, v_156: Ast.SyntaxTerm, v_152: Ast.Quantity, v_154: Nat, v_157: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000037:
    case (v_160, v_161):
      (v_165, v_166) = arena_pack_term(v_160, v_155)
      (v_170, v_171) = arena_pack_term(v_165, v_156)
      Arena.put_node(v_170, Arena.TermAll{v_152, v_161, v_154, v_166, v_171, v_157})

def arena_pack_term_name_result_38(v_70000038: Pair(Arena.Arena, U32), v_180: Ast.SyntaxTerm, v_177: Maybe<&2, Ast.Quantity>, v_179: Nat, v_181: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000038:
    case (v_184, v_185):
      (v_189, v_190) = arena_pack_term(v_184, v_180)
      Arena.put_node(v_189, Arena.TermLam{v_177, v_185, v_179, v_190, v_181})

def arena_pack_term_name_result_39(v_70000039: Pair(Arena.Arena, U32), v_212: List<&2, Ast.SyntaxTerm>, v_213: List<&2, String>, v_214: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000039:
    case (v_217, v_218):
      (v_223, v_224, v_225) = arena_pack_terms(v_217, v_212)
      (v_230, v_231, v_232) = arena_pack_names(v_223, v_213)
      Arena.put_node(v_230, Arena.TermAdt{v_218, v_224, v_225, v_231, v_232, v_214})

def arena_pack_term_name_result_40(v_70000040: Pair(Arena.Arena, U32), v_273: List<&2, Ast.SyntaxTerm>, v_274: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000040:
    case (v_277, v_278):
      match v_273:
        case Nil{}: Arena.put_ctr_leaf(v_277, v_278, v_274)
        case _:
          (v_283, v_284, v_285) = arena_pack_terms(v_277, v_273)
          Arena.put_node(v_283, Arena.TermCtr{v_278, v_284, v_285, v_274})

def arena_pack_term_name_result_41(v_70000041: Pair(Arena.Arena, U32), v_291: Ast.SyntaxTerm, v_292: Ast.SyntaxTerm, v_293: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000041:
    case (v_296, v_297):
      (v_301, v_302) = arena_pack_term(v_296, v_291)
      (v_306, v_307) = arena_pack_term(v_301, v_292)
      Arena.put_node(v_306, Arena.TermMat{v_297, v_302, v_307, v_293})

def arena_pack_term_name_result_42(v_70000042: Pair(Arena.Arena, U32), v_361: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000042:
    case (v_364, v_365):
      Arena.put_node(v_364, Arena.TermHole{v_365, v_361})

def arena_pack_pattern_name_result_43(v_70000043: Pair(Arena.Arena, U32), v_8: Nat, v_9: Ast.Quantity, v_10: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000043:
    case (v_13, v_14):
      Arena.put_pattern(v_13, Arena.PatternVar{v_14, v_8, v_9, v_10})

def arena_pack_pattern_name_result_44(v_70000044: Pair(Arena.Arena, U32), v_19: List<&2, Ast.SyntaxPattern>, v_20: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000044:
    case (v_23, v_24):
      (v_29, v_30, v_31) = arena_pack_patterns(v_23, v_19)
      Arena.put_pattern(v_29, Arena.PatternCtr{v_24, v_30, v_31, v_20})

def arena_pack_binder_name_result_45(v_70000045: Pair(Arena.Arena, U32), v_11: Ast.SyntaxTerm, v_8: Ast.Quantity, v_10: Nat, v_12: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000045:
    case (v_15, v_16):
      (v_20, v_21) = arena_pack_term(v_15, v_11)
      Arena.put_binder(v_20, Arena.Binder{v_8, v_16, v_10, v_21, v_12})

def arena_pack_binder_name_result_46(v_70000046: Pair(Arena.Arena, U32), v_28: Ast.SyntaxTerm, v_27: Nat, v_29: Ast.SourceSpan) -> Pair(Arena.Arena, U32):
  match v_70000046:
    case (v_32, v_33):
      (v_37, v_38) = arena_pack_term(v_32, v_28)
      Arena.put_binder(v_37, Arena.TemplateBinder{v_33, v_27, v_38, v_29})

def arena_decode_terms_go_word_result_47(v_70000047: Pair(Arena.Arena, U32), +v_2: U32, v_7: Nat) -> Pair(Arena.Arena, List<&2, Ast.SyntaxTerm>):
  match v_70000047:
    case (v_10, v_11):
      (v_15, v_16) = arena_decode_term(v_10, v_11)
      (v_20, v_21) = arena_decode_terms_go(v_15, U32.add(v_2, 1), v_7)
      (v_20, v_16 <> v_21)

def arena_decode_patterns_go_word_result_48(v_70000048: Pair(Arena.Arena, U32), +v_2: U32, v_7: Nat) -> Pair(Arena.Arena, List<&2, Ast.SyntaxPattern>):
  match v_70000048:
    case (v_10, v_11):
      (v_15, v_16) = arena_decode_pattern(v_10, v_11)
      (v_20, v_21) = arena_decode_patterns_go(v_15, U32.add(v_2, 1), v_7)
      (v_20, v_16 <> v_21)

def arena_decode_binders_go_word_result_49(v_70000049: Pair(Arena.Arena, U32), +v_2: U32, v_7: Nat) -> Pair(Arena.Arena, List<&2, Ast.TelescopeItem>):
  match v_70000049:
    case (v_10, v_11):
      (v_15, v_16) = arena_decode_binder(v_10, v_11)
      (v_20, v_21) = arena_decode_binders_go(v_15, U32.add(v_2, 1), v_7)
      (v_20, v_16 <> v_21)

def arena_decode_names_go_name_text_result_51(v_70000050: Pair(Arena.Arena, String), +v_2: U32, v_8: Nat) -> Pair(Arena.Arena, List<&2, String>):
  match v_70000050:
    case (v_15, v_16):
      (v_20, v_21) = arena_decode_names_go(v_15, U32.add(v_2, 1), v_8)
      (v_20, v_16 <> v_21)

def arena_decode_names_go_word_result_50(v_70000051: Pair(Arena.Arena, U32), +v_2: U32, v_8: Nat) -> Pair(Arena.Arena, List<&2, String>):
  match v_70000051:
    case (v_11, v_12):
      arena_decode_names_go_name_text_result_51(Arena.name_text(v_11, v_12), v_2, v_8)

def arena_decode_naturals_go_natural_result_52(v_70000052: Pair(Arena.Arena, Nat), +v_2: U32, v_8: Nat) -> Pair(Arena.Arena, List<&2, Nat>):
  match v_70000052:
    case (v_11, v_12):
      (v_16, v_17) = arena_decode_naturals_go(v_11, U32.add(v_2, 1), v_8)
      (v_16, v_12 <> v_17)

def arena_decode_quantities_go_word_result_53(v_70000053: Pair(Arena.Arena, U32), +v_2: U32, v_7: Nat) -> Pair(Arena.Arena, List<&2, Ast.Quantity>):
  match v_70000053:
    case (v_10, v_11):
      v_13 = Arena.word_quantity(v_11)
      (v_17, v_18) = arena_decode_quantities_go(v_10, U32.add(v_2, 1), v_7)
      (v_17, v_13 <> v_18)

def arena_decode_term_name_text_result_55(v_70000054: Pair(Arena.Arena, String), v_11: Nat, v_12: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.SyntaxTerm):
  match v_70000054:
    case (v_15, v_16):
      (v_15, Ast.TermVar{v_16, v_11, v_12})

def arena_decode_term_name_text_result_56(v_70000055: Pair(Arena.Arena, String), v_20: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.SyntaxTerm):
  match v_70000055:
    case (v_23, v_24):
      (v_23, Ast.TermRef{v_24, v_20})

def arena_decode_term_name_text_result_57(v_70000056: Pair(Arena.Arena, String), v_159: U32, v_160: U32, v_156: Ast.Quantity, v_158: Nat, v_161: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.SyntaxTerm):
  match v_70000056:
    case (v_164, v_165):
      (v_169, v_170) = arena_decode_term(v_164, v_159)
      (v_174, v_175) = arena_decode_term(v_169, v_160)
      (v_174, Ast.TermAll{v_156, v_165, v_158, v_170, v_175, v_161})

def arena_decode_term_name_text_result_58(v_70000057: Pair(Arena.Arena, String), v_184: U32, v_181: Maybe<&2, Ast.Quantity>, v_183: Nat, v_185: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.SyntaxTerm):
  match v_70000057:
    case (v_188, v_189):
      (v_193, v_194) = arena_decode_term(v_188, v_184)
      (v_193, Ast.TermLam{v_181, v_189, v_183, v_194, v_185})

def arena_decode_term_name_text_result_59(v_70000058: Pair(Arena.Arena, String), v_218: U32, v_219: U32, v_220: U32, v_221: U32, v_222: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.SyntaxTerm):
  match v_70000058:
    case (v_225, v_226):
      (v_230, v_231) = arena_decode_terms(v_225, v_218, v_219)
      (v_235, v_236) = arena_decode_names(v_230, v_220, v_221)
      (v_235, Ast.TermAdt{v_226, v_231, v_236, v_222})

def arena_decode_term_name_text_result_60(v_70000059: Pair(Arena.Arena, String), v_278: U32, v_279: U32, v_280: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.SyntaxTerm):
  match v_70000059:
    case (v_283, v_284):
      (v_288, v_289) = arena_decode_terms(v_283, v_278, v_279)
      (v_288, Ast.TermCtr{v_284, v_289, v_280})

def arena_decode_term_name_text_result_61(v_70000060: Pair(Arena.Arena, String), v_295: U32, v_296: U32, v_297: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.SyntaxTerm):
  match v_70000060:
    case (v_300, v_301):
      (v_305, v_306) = arena_decode_term(v_300, v_295)
      (v_310, v_311) = arena_decode_term(v_305, v_296)
      (v_310, Ast.TermMat{v_301, v_306, v_311, v_297})

def arena_decode_term_name_text_result_62(v_70000061: Pair(Arena.Arena, String), v_365: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.SyntaxTerm):
  match v_70000061:
    case (v_368, v_369):
      (v_368, Ast.TermHole{v_369, v_365})

def arena_decode_term_get_node_result_54(v_70000062: Pair(Arena.Arena, Arena.Node)) -> Pair(Arena.Arena, Ast.SyntaxTerm):
  match v_70000062:
    case (v_5, v_6):
      match v_6:
        case Arena.TermVar{v_10, v_11, v_12}:
          arena_decode_term_name_text_result_55(Arena.name_text(v_5, v_10), v_11, v_12)
        case Arena.TermRef{v_19, v_20}:
          arena_decode_term_name_text_result_56(Arena.name_text(v_5, v_19), v_20)
        case Arena.TermBang{v_27, v_28}:
          (v_32, v_33) = arena_decode_term(v_5, v_27)
          (v_32, Ast.TermBang{v_33, v_28})
        case Arena.TermSub{v_38, v_39, v_40, v_41}:
          (v_44, v_45) = arena_decode_term(v_5, v_39)
          (v_49, v_50) = arena_decode_term(v_44, v_40)
          (v_49, Ast.TermSub{v_38, v_45, v_50, v_41})
        case Arena.TermLet{v_61, v_62, v_63, v_64, v_65, v_66, v_67, v_68, v_69, v_70}:
          (v_74, v_75) = arena_decode_names(v_5, v_61, v_62)
          (v_79, v_80) = arena_decode_naturals(v_74, v_63, v_64)
          (v_84, v_85) = arena_decode_quantities(v_79, v_65, v_66)
          (v_89, v_90) = arena_decode_terms(v_84, v_67, v_68)
          (v_94, v_95) = arena_decode_term(v_89, v_69)
          (v_94, Ast.TermLet{v_75, v_80, v_85, v_90, v_95, v_70})
        case Arena.TermAnn{v_99, v_100, v_101}:
          (v_105, v_106) = arena_decode_term(v_5, v_99)
          (v_110, v_111) = arena_decode_term(v_105, v_100)
          (v_110, Ast.TermAnn{v_106, v_111, v_101})
        case Arena.TermTemplate{v_114, v_115}:
          (v_119, v_120) = arena_decode_term(v_5, v_114)
          (v_119, Ast.TermTemplate{v_120, v_115})
        case Arena.TermType{v_123, v_124}:
          (v_128, v_129) = arena_decode_term(v_5, v_123)
          (v_128, Ast.TermType{v_129, v_124})
        case Arena.TermQuant{}:
          (v_5, Ast.TermQuant{})
        case Arena.TermQuantity{v_132, v_133}:
          (v_5, Ast.TermQuantity{v_132, v_133})
        case Arena.TermMin{v_137, v_138, v_139}:
          (v_143, v_144) = arena_decode_term(v_5, v_137)
          (v_148, v_149) = arena_decode_term(v_143, v_138)
          (v_148, Ast.TermMin{v_144, v_149, v_139})
        case Arena.TermAll{v_156, v_157, v_158, v_159, v_160, v_161}:
          arena_decode_term_name_text_result_57(Arena.name_text(v_5, v_157), v_159, v_160, v_156, v_158, v_161)
        case Arena.TermLam{v_181, v_182, v_183, v_184, v_185}:
          arena_decode_term_name_text_result_58(Arena.name_text(v_5, v_182), v_184, v_181, v_183, v_185)
        case Arena.TermApp{v_198, v_199, v_200}:
          (v_204, v_205) = arena_decode_term(v_5, v_198)
          (v_209, v_210) = arena_decode_term(v_204, v_199)
          (v_209, Ast.TermApp{v_205, v_210, v_200})
        case Arena.TermAdt{v_217, v_218, v_219, v_220, v_221, v_222}:
          arena_decode_term_name_text_result_59(Arena.name_text(v_5, v_217), v_218, v_219, v_220, v_221, v_222)
        case Arena.TermFill{v_241, v_242, v_243, v_244}:
          (v_248, v_249) = arena_decode_term(v_5, v_241)
          (v_253, v_254) = arena_decode_terms(v_248, v_242, v_243)
          (v_253, Ast.TermFill{v_249, v_254, v_244})
        case Arena.TermPlus{v_259, v_260, v_261, v_262}:
          (v_266, v_267) = arena_decode_term(v_5, v_259)
          (v_271, v_272) = arena_decode_terms(v_266, v_260, v_261)
          (v_271, Ast.TermPlus{v_267, v_272, v_262})
        case Arena.TermString{chars, names, span}:
          (v_5, Ast.TermString{chars, names, span})
        case Arena.TermCtr{v_277, v_278, v_279, v_280}:
          arena_decode_term_name_text_result_60(Arena.name_text(v_5, v_277), v_278, v_279, v_280)
        case Arena.TermMat{v_294, v_295, v_296, v_297}:
          arena_decode_term_name_text_result_61(Arena.name_text(v_5, v_294), v_295, v_296, v_297)
        case Arena.TermAbsurd{v_313}:
          (v_5, Ast.TermAbsurd{v_313})
        case Arena.TermEqual{v_318, v_319, v_320, v_321}:
          (v_325, v_326) = arena_decode_term(v_5, v_318)
          (v_330, v_331) = arena_decode_term(v_325, v_319)
          (v_335, v_336) = arena_decode_term(v_330, v_320)
          (v_335, Ast.TermEqual{v_326, v_331, v_336, v_321})
        case Arena.TermRefl{v_338}:
          (v_5, Ast.TermRefl{v_338})
        case Arena.TermRewrite{v_343, v_344, v_345, v_346}:
          (v_350, v_351) = arena_decode_term(v_5, v_343)
          (v_355, v_356) = arena_decode_term(v_350, v_344)
          (v_360, v_361) = arena_decode_term(v_355, v_345)
          (v_360, Ast.TermRewrite{v_351, v_356, v_361, v_346})
        case Arena.TermHole{v_364, v_365}:
          arena_decode_term_name_text_result_62(Arena.name_text(v_5, v_364), v_365)
        case Arena.BodyMatch{v_375, v_376, v_377, v_378, v_379}:
          (v_383, v_384) = arena_decode_terms(v_5, v_375, v_376)
          (v_388, v_389) = arena_decode_terms(v_383, v_377, v_378)
          (v_388, Ast.BodyMatch{v_384, v_389, v_379})
        case Arena.BodyCase{v_394, v_395, v_396, v_397}:
          (v_401, v_402) = arena_decode_patterns(v_5, v_394, v_395)
          (v_406, v_407) = arena_decode_term(v_401, v_396)
          (v_406, Ast.BodyCase{v_402, v_407, v_397})
        case Arena.BodyLocal{v_415, v_416, v_417, v_418, v_419, v_420, v_421}:
          (v_425, v_426) = arena_decode_patterns(v_5, v_415, v_416)
          (v_430, v_431) = arena_decode_terms(v_425, v_418, v_419)
          (v_435, v_436) = arena_decode_term(v_430, v_420)
          (v_435, Ast.BodyLocal{v_426, v_417, v_431, v_436, v_421})
        case Arena.BodyReply{v_439, v_440}:
          (v_444, v_445) = arena_decode_term(v_5, v_439)
          (v_444, Ast.BodyReply{v_445, v_440})

def arena_decode_pattern_name_text_result_64(v_70000063: Pair(Arena.Arena, String), v_12: Nat, v_13: Ast.Quantity, v_14: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.SyntaxPattern):
  match v_70000063:
    case (v_17, v_18):
      (v_17, Ast.PatternVar{v_18, v_12, v_13, v_14})

def arena_decode_pattern_name_text_result_65(v_70000064: Pair(Arena.Arena, String), v_24: U32, v_25: U32, v_26: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.SyntaxPattern):
  match v_70000064:
    case (v_29, v_30):
      (v_34, v_35) = arena_decode_patterns(v_29, v_24, v_25)
      (v_34, Ast.PatternCtr{v_30, v_35, v_26})

def arena_decode_pattern_get_pattern_result_63(v_70000065: Pair(Arena.Arena, Arena.Pattern)) -> Pair(Arena.Arena, Ast.SyntaxPattern):
  match v_70000065:
    case (v_5, v_6):
      match v_6:
        case Arena.PatternVar{v_11, v_12, v_13, v_14}:
          arena_decode_pattern_name_text_result_64(Arena.name_text(v_5, v_11), v_12, v_13, v_14)
        case Arena.PatternCtr{v_23, v_24, v_25, v_26}:
          arena_decode_pattern_name_text_result_65(Arena.name_text(v_5, v_23), v_24, v_25, v_26)

def arena_decode_binder_name_text_result_67(v_70000066: Pair(Arena.Arena, String), v_15: U32, v_12: Ast.Quantity, v_14: Nat, v_16: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.TelescopeItem):
  match v_70000066:
    case (v_19, v_20):
      (v_24, v_25) = arena_decode_term(v_19, v_15)
      (v_24, Ast.Binder{v_12, v_20, v_14, v_25, v_16})

def arena_decode_binder_name_text_result_68(v_70000067: Pair(Arena.Arena, String), v_32: U32, v_31: Nat, v_33: Ast.SourceSpan) -> Pair(Arena.Arena, Ast.TelescopeItem):
  match v_70000067:
    case (v_36, v_37):
      (v_41, v_42) = arena_decode_term(v_36, v_32)
      (v_41, Ast.TemplateBinder{v_37, v_31, v_42, v_33})

def arena_decode_binder_get_binder_result_66(v_70000068: Pair(Arena.Arena, Arena.Binder)) -> Pair(Arena.Arena, Ast.TelescopeItem):
  match v_70000068:
    case (v_5, v_6):
      match v_6:
        case Arena.Binder{v_12, v_13, v_14, v_15, v_16}:
          arena_decode_binder_name_text_result_67(Arena.name_text(v_5, v_13), v_15, v_12, v_14, v_16)
        case Arena.TemplateBinder{v_30, v_31, v_32, v_33}:
          arena_decode_binder_name_text_result_68(Arena.name_text(v_5, v_30), v_32, v_31, v_33)

def check_template_result(result: Template.ExpandResult) -> CheckResult:
  match result:
    case Template.ExpandSuccess{ expanded}: check_modules(expanded, Nil{})
    case Template.ExpandFailure{message, span}:
      CheckFailure{ Diagnostic{ span_file(span), span, message,  "a valid template application",  "template expansion failed"}}

def check(modules: List<&2, Loader.LoadedModule>) -> CheckResult:
  check_template_result(Template.expand(modules))

# A compact literal is closed syntax, not a typing certificate. Observation
# expands exactly the historical constructor layer; unsuccessful schema proofs
# use the complete historical tree and the ordinary checker.
def string_pack_store(store: ArenaStore, term: Ast.SyntaxTerm) -> ArenaResult<U32>:
  match store:
    case ArenaStore{source, transient}:
      (source, id) = arena_pack_term(source, term)
      {ArenaResult{ArenaStore{source, transient}, id} : ArenaResult<U32>}

def string_unfold_store(store: ArenaStore, chars: List<&2, U32>, names: Ast.StringLiteralNames, span: Ast.SourceSpan) -> ArenaResult<U32>:
  string_pack_store(store, Ast.string_unfold(chars, names, span))

def string_desugar_store(store: ArenaStore, chars: List<&2, U32>, names: Ast.StringLiteralNames, span: Ast.SourceSpan) -> ArenaResult<U32>:
  string_pack_store(store, Ast.string_desugar(chars, names, span))

def string_canonical_names(names: Ast.StringLiteralNames, +scope: Scope.ArenaGlobalScope) -> Ast.StringLiteralNames:
  match names:
    case Ast.StringLiteralNames{nil, cons, char, uint, word_nil, word_cons, bit_false, bit_true}:
      Ast.StringLiteralNames{Scope.canonical_name(nil, scope), Scope.canonical_name(cons, scope), Scope.canonical_name(char, scope), Scope.canonical_name(uint, scope), Scope.canonical_name(word_nil, scope), Scope.canonical_name(word_cons, scope), Scope.canonical_name(bit_false, scope), Scope.canonical_name(bit_true, scope)}

def string_names_equal(left: Ast.StringLiteralNames, right: Ast.StringLiteralNames, +scope: Scope.ArenaGlobalScope) -> Bool:
  match left right:
    case Ast.StringLiteralNames{a, b, c, d, e, f, g, h} Ast.StringLiteralNames{i, j, k, l, m, n, o, p}:
      Bool.and(Scope.equal_names(a, i, scope), Bool.and(Scope.equal_names(b, j, scope), Bool.and(Scope.equal_names(c, k, scope), Bool.and(Scope.equal_names(d, l, scope), Bool.and(Scope.equal_names(e, m, scope), Bool.and(Scope.equal_names(f, n, scope), Bool.and(Scope.equal_names(g, o, scope), Scope.equal_names(h, p, scope))))))))

def string_chars_equal(left: List<&2, U32>, right: List<&2, U32>) -> Bool:
  match left right:
    case Nil{} Nil{}: True{}
    case a <> rest_a b <> rest_b:
      match U32.is_eq(a, b):
        case False{}: False{}
        case True{}: string_chars_equal(rest_a, rest_b)
    case _ _: False{}

# Identical payloads and constructor identities prove the same old tree under
# every schema. A mismatch proves nothing: aliases can collapse the two bit
# constructors, so only ordinary unfolding may decide a negative comparison.
def string_literal_positive(same_names: Bool, left: List<&2, U32>, right: List<&2, U32>) -> Bool:
  match same_names:
    case False{}: False{}
    case True{}: string_chars_equal(left, right)

def equal_raw_distinct(store: ArenaStore, +left: U32, +right: U32, +scope: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +a} = arena_get_node(store, left)
  ArenaResult{store, +b} = arena_get_node(store, right)
  match a b:
    case Arena.TermString{+chars_a, +names_a, +span_a} Arena.TermString{+chars_b, +names_b, +span_b}:
      match string_literal_positive(string_names_equal(names_a, names_b, scope), chars_a, chars_b):
        case True{}: {ArenaResult{store, True{}} : ArenaResult<Bool>}
        case False{}:
          ArenaResult{store, expanded_a} = string_unfold_store(store, chars_a, names_a, span_a)
          ArenaResult{store, expanded_b} = string_unfold_store(store, chars_b, names_b, span_b)
          equal_raw(store, expanded_a, expanded_b, scope)
    case Arena.TermString{chars, names, span} _:
      ArenaResult{store, expanded} = string_unfold_store(store, chars, names, span)
      equal_raw(store, expanded, right, scope)
    case _ Arena.TermString{chars, names, span}:
      ArenaResult{store, expanded} = string_unfold_store(store, chars, names, span)
      equal_raw(store, left, expanded, scope)
    case _ _: equal_raw_ordinary(store, left, right, scope)

# These checks resolve real scope records (including type/value handles and
# kind), not spellings or source filenames. Unrecognized but legitimate schemas
# deliberately decline the optimization.
def string_constructor_identity(+name: String, +ns: String, +scope: Scope.ArenaGlobalScope, +expected: String) -> Bool:
  scalar_global_identity(Scope.lookup_kind(name, Scope.GlobalConstructor{}, scope), Scope.lookup_kind(canonical_key(ns, expected), Scope.GlobalConstructor{}, scope))

def string_names_schema(names: Ast.StringLiteralNames, +ns: String, +scope: Scope.ArenaGlobalScope) -> Bool:
  match names:
    case Ast.StringLiteralNames{nil, cons, char, uint, word_nil, word_cons, bit_false, bit_true}:
      Bool.and(string_constructor_identity(nil, ns, scope, "SNil"), Bool.and(string_constructor_identity(cons, ns, scope, "SCon"), Bool.and(string_constructor_identity(char, ns, scope, "Chr"), Bool.and(string_constructor_identity(uint, ns, scope, "U32"), Bool.and(string_constructor_identity(word_nil, ns, scope, "WNil"), Bool.and(string_constructor_identity(word_cons, ns, scope, "WCon"), Bool.and(string_constructor_identity(bit_false, ns, scope, "False"), string_constructor_identity(bit_true, ns, scope, "True"))))))))

def string_schema_ref(store: ArenaStore, id: U32, +ns: String, +scope: Scope.ArenaGlobalScope, expected: String) -> ArenaResult<Bool>:
  ArenaResult{store, node} = arena_get_node(store, id)
  match node:
    case Arena.TermRef{key, _}: scalar_schema_name(store, key, ns, scope, expected, True{})
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def string_schema_adt(store: ArenaStore, id: U32, +ns: String, +scope: Scope.ArenaGlobalScope, expected: String) -> ArenaResult<Bool>:
  ArenaResult{store, node} = arena_get_node(store, id)
  match node:
    case Arena.TermAdt{key, _, args_count, _, refs_count, _}:
      match Bool.and(U32.is_eq(args_count, 0), U32.is_eq(refs_count, 0)):
        case True{}: scalar_schema_name(store, key, ns, scope, expected, True{})
        case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def string_schema_family(store: ArenaStore, +ns: String, +scope: Scope.ArenaGlobalScope, +name: String) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, name), Scope.GlobalFamily{}, scope):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.SomeTerm{value}, Scope.GlobalFamily{}}}:
      ArenaResult{store, +valid_ty} = scalar_schema_0(store, ty, ns, scope)
      ArenaResult{store, +valid_value} = string_schema_adt(store, value, ns, scope, name)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, name)), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, name), Bool.and(valid_ty, valid_value))))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

# fields/result are descriptions of the exact expected checked constructor
# telescope, not generated character values. Quantities and de Bruijn indices
# are checked at every binder, and the final family is nullary/unrestricted.
def string_schema_fields(store: ArenaStore, id: U32, fields: List<&2, String>, +result: String, +index: Nat, +ns: String, +scope: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match fields:
    case Nil{}: string_schema_adt(store, id, ns, scope, result)
    case field <> rest:
      ArenaResult{store, node} = arena_get_node(store, id)
      match node:
        case Arena.TermAll{Ast.QOne{}, _, actual_index, ty, body, _}:
          ArenaResult{store, +valid_ty} = string_schema_ref(store, ty, ns, scope, field)
          ArenaResult{store, +valid_rest} = string_schema_fields(store, body, rest, result, Nat.add(index, 1n), ns, scope)
          {ArenaResult{store, Bool.and(Nat.is_eq(index, actual_index), Bool.and(valid_ty, valid_rest))} : ArenaResult<Bool>}
        case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def string_schema_constructor(store: ArenaStore, +ns: String, +scope: Scope.ArenaGlobalScope, +name: String, fields: List<&2, String>, result: String) -> ArenaResult<Bool>:
  match Scope.lookup_kind(canonical_key(ns, name), Scope.GlobalConstructor{}, scope):
    case Some{Scope.ArenaGlobal{key, owner, local, ty, IR.NoTerm{}, Scope.GlobalConstructor{}}}:
      ArenaResult{store, +valid_ty} = string_schema_fields(store, ty, fields, result, 0n, ns, scope)
      {ArenaResult{store, Bool.and(String.eq(key, canonical_key(ns, name)), Bool.and(String.eq(owner, ns), Bool.and(String.eq(local, name), valid_ty)))} : ArenaResult<Bool>}
    case _: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def string_schema(store: ArenaStore, +ns: String, +scope: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  ArenaResult{store, +scalar} = scalar_schema_builtin(store, ns, scope, "U32")
  ArenaResult{store, +char_family} = string_schema_family(store, ns, scope, "Char")
  ArenaResult{store, +string_family} = string_schema_family(store, ns, scope, "String")
  ArenaResult{store, +char_ctor} = string_schema_constructor(store, ns, scope, "Chr", ["U32"], "Char")
  ArenaResult{store, +nil_ctor} = string_schema_constructor(store, ns, scope, "SNil", [], "String")
  ArenaResult{store, +cons_ctor} = string_schema_constructor(store, ns, scope, "SCon", ["Char", "String"], "String")
  {ArenaResult{store, Bool.and(scalar, Bool.and(char_family, Bool.and(string_family, Bool.and(char_ctor, Bool.and(nil_ctor, cons_ctor)))))} : ArenaResult<Bool>}

def string_schema_prepare(+frame: Scope.ArenaGlobalScope, +selected: Scope.ArenaGlobal, result: ArenaResult<Bool>) -> ArenaResult<Bool>:
  match result:
    case ArenaResult{store, +valid}:
      {ArenaResult{scalar_frame_store(store, Arena.StringSchemaSaved{frame, selected, valid}), valid} : ArenaResult<Bool>}

# Like ScalarSchemaSaved, this is a fact owned by the active definition frame,
# not a cache usable under arbitrary scopes sharing SNil. Only the exact scope
# installed by definition_term_inference reaches here while that frame is live;
# no typing helper replaces aliases/constructors, and finish clears both saved
# variants. Without that frame, the default branch re-proves every schema.
def string_schema_entry(store: ArenaStore, entry: Arena.SubstMemoEntry, +selected: Scope.ArenaGlobal, +ns: String, +scope: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match entry:
    case Arena.ScalarSchemaOpen{frame}:
      string_schema_prepare(frame, selected, string_schema(store, ns, scope))
    case Arena.ScalarSchemaSaved{frame, _, _}:
      string_schema_prepare(frame, selected, string_schema(store, ns, scope))
    case Arena.StringSchemaSaved{frame, saved, valid}:
      match scalar_global_identity(Some{selected}, Some{saved}):
        case True{}: {ArenaResult{store, valid} : ArenaResult<Bool>}
        case False{}: string_schema_prepare(frame, selected, string_schema(store, ns, scope))
    case _: string_schema(store, ns, scope)

def string_schema_frame(transient: Arena.Arena, selected: Scope.ArenaGlobal, ns: String, scope: Scope.ArenaGlobalScope, result: Arena.Arena & Arena.SubstMemoEntry) -> ArenaResult<Bool>:
  match result:
    case Tuple{source, entry}: string_schema_entry(ArenaStore{source, transient}, entry, selected, ns, scope)

def string_schema_prepared(store: ArenaStore, selected: Scope.ArenaGlobal, ns: String, scope: Scope.ArenaGlobalScope) -> ArenaResult<Bool>:
  match store:
    case ArenaStore{source, transient}: string_schema_frame(transient, selected, ns, scope, Arena.scalar_frame_get(source))

def string_certificate(store: ArenaStore, +names: Ast.StringLiteralNames, +scope: Scope.ArenaGlobalScope, view: U32) -> ArenaResult<Bool>:
  match names:
    case Ast.StringLiteralNames{nil, _, _, _, _, _, _, _}:
      match Scope.lookup_kind(nil, Scope.GlobalConstructor{}, scope):
        case Some{+selected}:
          match selected:
            case Scope.ArenaGlobal{_, +ns, _, _, _, _}:
              match string_names_schema(names, ns, scope):
                case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
                case True{}:
                  ArenaResult{store, +goal} = string_schema_adt(store, view, ns, scope, "String")
                  match goal:
                    case False{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}
                    case True{}: string_schema_prepared(store, selected, ns, scope)
        case None{}: {ArenaResult{store, False{}} : ArenaResult<Bool>}

def check_string_literal(store: ArenaStore, +term: U32, +chars: List<&2, U32>, +names: Ast.StringLiteralNames, +span: Ast.SourceSpan, +env: List<&2, Binding>, +scope: Scope.ArenaGlobalScope, +goal: U32) -> ArenaResult<Inference>:
  ArenaResult{store, view} = whnf(store, 64n, goal, scope)
  ArenaResult{store, valid} = string_certificate(store, names, scope, view)
  match valid:
    case True{}: {ArenaResult{store, Inferred{term, goal}} : ArenaResult<Inference>}
    case False{}:
      ArenaResult{store, expanded} = string_desugar_store(store, chars, names, span)
      check_term(store, expanded, env, scope, goal)

def term_descend_live(store: ArenaStore, +left: U32, +right: U32) -> ArenaResult<TermOrder>:
  ArenaResult{store, a} = arena_get_node(store, left)
  ArenaResult{store, b} = arena_get_node(store, right)
  match a b:
    case Arena.TermString{chars, names, span} _:
      ArenaResult{store, expanded} = string_unfold_store(store, chars, names, span)
      term_descend_live(store, expanded, right)
    case _ Arena.TermString{chars, names, span}:
      ArenaResult{store, expanded} = string_unfold_store(store, chars, names, span)
      term_descend_live(store, left, expanded)
    case _ _: term_descend_ordinary(store, left, right)

# Representation exposure is not a reduction step: even exhausted reduction
# fuel must expose the constructor that the old syntax already contained.
def string_observe_zero(store: ArenaStore, +id: U32) -> ArenaResult<U32>:
  ArenaResult{store, node} = arena_get_node(store, id)
  match node:
    case Arena.TermString{chars, names, span}: string_unfold_store(store, chars, names, span)
    case _: {ArenaResult{store, id} : ArenaResult<U32>}
