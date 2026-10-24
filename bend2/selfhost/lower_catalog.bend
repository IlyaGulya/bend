import Base
import ./ast.bend as Ast
import ./checker_arena.bend as Arena
import ./checker_ir.bend as IR
import ./checked_frontend.bend as Checked
import ./scope_lookup.bend as Scope
import ./index_lookup.bend as IndexLookup
import ./backend_ir.bend as BIR
import ./path.bend as Path

# Catalog construction only reads published semantic nodes. Its sole linear
# owner is returned to runtime lowering; descriptors are a separate Data tree.
type BuildResult is Type:
  Built{program: Checked.CheckedProgram, catalog: Catalog}
  BuildFailure{program: Checked.CheckedProgram, message: String}
type Foreign is Data:
  Foreign{namespace: String, imported: String, sources: List<&2, String>, span: Ast.SourceSpan, parameter_types: List<&2, BIR.Descriptor>, result: BIR.Descriptor}
type DefinitionHeader is Data:
  DefinitionHeader{symbol: IR.Symbol, key: String, code: U32, parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, type_only: Bool, primitive: Maybe<&2, BIR.Primitive>, foreign: Maybe<&2, Foreign>, fast: Bool}
type Definition is Data:
  Definition{header: DefinitionHeader, binders: IR.Words, result: IR.OptionalTerm, body: IR.DefBody, checked: Maybe<&2, IR.Occurrence>, scope: Scope.ArenaGlobalScope, native: Maybe<&2, String>, quantity_prefix: Nat}
type Constructor is Data:
  Constructor{layout: BIR.ConstructorLayout, quantities: List<&2, BIR.Quantity>, parameters: Nat, family: String}
type Registry is Data:
  Registry{definitions: Map<&2, DefinitionHeader>, constructors: Map<&2, Constructor>}
type Catalog is Data:
  Catalog{definitions: List<&2, Definition>, registry: Registry, constructors: List<&2, BIR.ConstructorLayout>, families: List<&2, BIR.Family>, type_functions: List<&2, BIR.TypeFunction>, next_code: U32, ending: BIR.Ending}
type CatalogResult<-T: Type> is Type:
  CatalogResult{source: Arena.Arena, value: T}
type Telescope is Data:
  Telescope{parameters: List<&2, BIR.Parameter>, quantities: List<&2, BIR.Quantity>, fields: List<&2, BIR.DescriptorField>, fixed: Bool}
type Needed is Data:
  Needed{functions: List<&2, BIR.TypeFunction>, seen: Map<&2, Bool>}
type Root is Data:
  TermRoot{term: U32, scope: Scope.ArenaGlobalScope}
  DefinitionRoot{key: String}
type Preparation is Data:
  Preparation{definitions: List<&2, Definition>, index: Map<&2, Definition>, headers: Map<&2, DefinitionHeader>, constructors: List<&2, BIR.ConstructorLayout>, constructor_index: Map<&2, Constructor>, families: List<&2, BIR.Family>, next_code: U32, next_constructor: U32, roots: List<&2, Root>, main: Maybe<&2, BIR.Descriptor>, failure: Maybe<&2, String>, module_values: Map<&2, Bool>}

type Arms is Data:
  Arms{arms: List<&2, BIR.DescriptorArm>, state: Preparation}
type ExportFacts is Data:
  ExportFacts{parameter_types: List<&2, BIR.Descriptor>, result: BIR.Descriptor}
# Field identities are source-slot ordinals, including erased positions. The
# named property exists only for a live field; slot lookup never compacts IDs.
type ConstructorField is Data:
  ConstructorField{identity: U32, key: Maybe<&2, String>, quantity: BIR.Quantity}
def qualify(+owner: String, local: String) -> String:
  Scope.canonical_key(owner, local, String.eq(owner, ""))
def symbol_key(symbol: IR.Symbol) -> String:
  match symbol:
    case IR.Symbol{owner, local, _, _}: qualify(owner, local)
def quantity(value: Ast.Quantity) -> BIR.Quantity:
  match value:
    case Ast.QZero{}: BIR.Erased{}
    case Ast.QOne{}: BIR.Once{}
    case Ast.QMany{}: BIR.Unrestricted{}
def optional_quantity(value: Maybe<&2, Ast.Quantity>) -> Maybe<&2, BIR.Quantity>:
  match value:
    case None{}: None{}
    case Some{item}: Some{quantity(item)}
def parameter(id: U32, value: BIR.Quantity, rest: List<&2, BIR.Parameter>) -> List<&2, BIR.Parameter>:
  match value:
    case BIR.Erased{}: rest
    case BIR.Once{}: BIR.Parameter{id, BIR.Affine{}} <> rest
    case BIR.Unrestricted{}: BIR.Parameter{id, BIR.Many{}} <> rest
def field_key(key: String, value: BIR.Quantity) -> Maybe<&2, String>:
  match value:
    case BIR.Erased{}: None{}
    case _: Some{key}
def canonical(name: String, scope: Scope.ArenaGlobalScope, constructor: Bool) -> String:
  match constructor:
    case True{}: Scope.canonical_name_result(name, Scope.lookup_kind(name, Scope.GlobalConstructor{}, scope))
    case False{}: Scope.canonical_name(name, scope)

def native_match_descriptor_0(v_8: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_3: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  match v_8:
    case (v_6, v_7):
      descriptor_node(v_6, v_7, v_3)

def descriptor(v_0: Arena.Arena, v_2: U32, v_3: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  native_match_descriptor_0(Arena.get_node(v_0, v_2), v_3)

def native_match_descriptor_name_0(v_11: Sigma<&1, &1, Arena.Arena, _ => String>, v_3: Scope.ArenaGlobalScope, v_5: Bool) -> CatalogResult<String>:
  match v_11:
    case (v_9, v_10):
      CatalogResult{v_9, canonical(v_10, v_3, v_5)}

def descriptor_name(v_0: Arena.Arena, v_2: U32, v_3: Scope.ArenaGlobalScope, v_5: Bool) -> CatalogResult<String>:
  native_match_descriptor_name_0(Arena.name_text(v_0, v_2), v_3, v_5)

def native_match_descriptors_0(v_86: CatalogResult<List<&2, BIR.Descriptor>>, v_16: BIR.Descriptor) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_86:
    case CatalogResult{v_19, v_20}:
      CatalogResult{v_19, v_16 <> v_20}

def native_match_descriptors_1(v_87: CatalogResult<BIR.Descriptor>, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_87:
    case CatalogResult{v_15, v_16}:
      native_match_descriptors_0(descriptors(v_15, IR.arena_range_index(v_2, 1), U32.sub(v_4, 1), v_5), v_16)

def native_match_descriptors_2(v_88: Sigma<&1, &1, Arena.Arena, _ => U32>, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_88:
    case (v_11, v_12):
      native_match_descriptors_1(descriptor(v_11, v_12, v_5), v_2, v_4, v_5)

def native_match_descriptors_3(v_4: U32, v_0: Arena.Arena, v_2: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_4:
    case 0:
      CatalogResult{v_0, []}
    case _:
      native_match_descriptors_2(Arena.word(v_0, IR.arena_tape_offset(v_2)), v_2, v_4, v_5)

def descriptors(v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  native_match_descriptors_3(v_4, v_0, v_2, v_5)

def native_match_descriptor_patterns_0(v_89: CatalogResult<List<&2, BIR.DescriptorPattern>>, v_19: BIR.DescriptorPattern) -> CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match v_89:
    case CatalogResult{v_22, v_23}:
      CatalogResult{v_22, v_19 <> v_23}

def native_match_descriptor_patterns_1(v_90: CatalogResult<BIR.DescriptorPattern>, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match v_90:
    case CatalogResult{v_18, v_19}:
      native_match_descriptor_patterns_0(descriptor_patterns(v_18, IR.arena_range_index(v_2, 1), U32.sub(v_4, 1), v_5), v_19)

def native_match_descriptor_patterns_2(v_91: Sigma<&1, &1, Arena.Arena, _ => Arena.Pattern>, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match v_91:
    case (v_14, v_15):
      native_match_descriptor_patterns_1(descriptor_pattern(v_14, v_15, v_5), v_2, v_4, v_5)

def native_match_descriptor_patterns_3(v_92: Sigma<&1, &1, Arena.Arena, _ => U32>, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match v_92:
    case (v_11, v_12):
      native_match_descriptor_patterns_2(Arena.get_pattern(v_11, v_12), v_2, v_4, v_5)

def native_match_descriptor_patterns_4(v_4: U32, v_0: Arena.Arena, v_2: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match v_4:
    case 0:
      CatalogResult{v_0, []}
    case _:
      native_match_descriptor_patterns_3(Arena.word(v_0, IR.arena_tape_offset(v_2)), v_2, v_4, v_5)

def descriptor_patterns(v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.DescriptorPattern>>:
  native_match_descriptor_patterns_4(v_4, v_0, v_2, v_5)

def native_match_descriptor_pattern_0(v_29: CatalogResult<List<&2, BIR.DescriptorPattern>>, v_24: String) -> CatalogResult<BIR.DescriptorPattern>:
  match v_29:
    case CatalogResult{v_27, v_28}:
      CatalogResult{v_27, BIR.DescriptorConstructorPattern{v_24, v_28}}

def native_match_descriptor_pattern_1(v_30: CatalogResult<String>, v_2: Scope.ArenaGlobalScope, v_18: U32, v_19: U32) -> CatalogResult<BIR.DescriptorPattern>:
  match v_30:
    case CatalogResult{v_23, v_24}:
      native_match_descriptor_pattern_0(descriptor_patterns(v_23, v_18, v_19, v_2), v_24)

def native_match_descriptor_pattern_2(v_1: Arena.Pattern, v_0: Arena.Arena, v_2: Scope.ArenaGlobalScope) -> CatalogResult<BIR.DescriptorPattern>:
  match v_1:
    case Arena.PatternVar{_, _, v_10, _}:
      CatalogResult{v_0, BIR.DescriptorBinder{quantity(v_10)}}
    case Arena.PatternCtr{v_17, v_18, v_19, _}:
      native_match_descriptor_pattern_1(descriptor_name(v_0, v_17, v_2, True{}), v_2, v_18, v_19)

def descriptor_pattern(v_0: Arena.Arena, v_1: Arena.Pattern, v_2: Scope.ArenaGlobalScope) -> CatalogResult<BIR.DescriptorPattern>:
  native_match_descriptor_pattern_2(v_1, v_0, v_2)

def descriptor_apply(fn: BIR.Descriptor, arg: BIR.Descriptor) -> BIR.Descriptor:
  match fn:
    case BIR.DescriptorRef{key, args}: BIR.DescriptorRef{key, List.append(&2, BIR.Descriptor, args, [arg])}
    case _: BIR.DescriptorApplication{fn, arg}
def native_match_descriptor_sugar_0(v_67: CatalogResult<BIR.Descriptor>, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_7: Scope.ArenaGlobalScope, v_27: U32) -> CatalogResult<BIR.Descriptor>:
  match v_67:
    case CatalogResult{v_31, v_32}:
      descriptor_sugar(v_31, v_27, v_32 <> v_4, v_6, v_7)

def native_match_descriptor_sugar_1(v_68: CatalogResult<String>, v_4: List<&2, BIR.Descriptor>, v_6: Bool) -> CatalogResult<BIR.Descriptor>:
  match v_68:
    case CatalogResult{v_39, v_40}:
      CatalogResult{v_39, named_sugar(v_40, BIR.DescriptorRef{v_40, []}, v_4, v_6)}

def native_match_descriptor_sugar_2(v_69: CatalogResult<List<&2, BIR.Descriptor>>, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_56: String) -> CatalogResult<BIR.Descriptor>:
  match v_69:
    case CatalogResult{v_59, v_60}:
      CatalogResult{v_59, named_sugar(v_56, BIR.DescriptorRef{v_56, v_60}, List.append(&2, BIR.Descriptor, v_60, v_4), v_6)}

def native_match_descriptor_sugar_3(v_70: CatalogResult<String>, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_7: Scope.ArenaGlobalScope, v_49: U32, v_50: U32) -> CatalogResult<BIR.Descriptor>:
  match v_70:
    case CatalogResult{v_55, v_56}:
      native_match_descriptor_sugar_2(descriptors(v_55, v_49, v_50, v_7), v_4, v_6, v_56)

def native_match_descriptor_sugar_4(v_71: CatalogResult<BIR.Descriptor>, v_4: List<&2, BIR.Descriptor>, v_6: Bool) -> CatalogResult<BIR.Descriptor>:
  match v_71:
    case CatalogResult{v_65, v_66}:
      CatalogResult{v_65, unnamed_sugar(v_66, v_4, v_6)}

def native_match_descriptor_sugar_5(v_11: Arena.Node, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_7: Scope.ArenaGlobalScope, v_10: Arena.Arena) -> CatalogResult<BIR.Descriptor>:
  match v_11:
    case Arena.TermAnn{v_15, _, _}:
      descriptor_sugar(v_10, v_15, v_4, v_6, v_7)
    case Arena.TermBang{v_21, _}:
      descriptor_sugar(v_10, v_21, v_4, v_6, v_7)
    case Arena.TermApp{v_27, v_28, _}:
      native_match_descriptor_sugar_0(descriptor(v_10, v_28, v_7), v_4, v_6, v_7, v_27)
    case Arena.TermRef{v_36, _}:
      native_match_descriptor_sugar_1(descriptor_name(v_10, v_36, v_7, False{}), v_4, v_6)
    case Arena.TermAdt{v_48, v_49, v_50, _, _, _}:
      native_match_descriptor_sugar_3(descriptor_name(v_10, v_48, v_7, False{}), v_4, v_6, v_7, v_49, v_50)
    case _:
      native_match_descriptor_sugar_4(descriptor_node(v_10, v_11, v_7), v_4, v_6)

def native_match_descriptor_sugar_6(v_72: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_7: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  match v_72:
    case (v_10, v_11):
      native_match_descriptor_sugar_5(v_11, v_4, v_6, v_7, v_10)

def descriptor_sugar(v_0: Arena.Arena, v_2: U32, v_4: List<&2, BIR.Descriptor>, v_6: Bool, v_7: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  native_match_descriptor_sugar_6(Arena.get_node(v_0, v_2), v_4, v_6, v_7)

def named_sugar(key: String, head: BIR.Descriptor, args: List<&2, BIR.Descriptor>, plus: Bool) -> BIR.Descriptor:
  match plus:
    case False{}: BIR.DescriptorNamedFill{key, head, args}
    case True{}: BIR.DescriptorNamedPlus{key, head, args}
def unnamed_sugar(head: BIR.Descriptor, args: List<&2, BIR.Descriptor>, plus: Bool) -> BIR.Descriptor:
  match plus:
    case False{}: BIR.DescriptorFill{head, args}
    case True{}: BIR.DescriptorPlus{head, args}
def string_names(names: Ast.StringLiteralNames, scope: Scope.ArenaGlobalScope) -> Ast.StringLiteralNames:
  match names:
    case Ast.StringLiteralNames{nil, cons, char, uint, wn, wc, bf, bt}:
      Ast.StringLiteralNames{canonical(nil, scope, True{}), canonical(cons, scope, True{}), canonical(char, scope, True{}), canonical(uint, scope, True{}), canonical(wn, scope, True{}), canonical(wc, scope, True{}), canonical(bf, scope, True{}), canonical(bt, scope, True{})}
def string_bit(bit: U32, names: Ast.StringLiteralNames) -> BIR.Descriptor:
  match bit names:
    case 0 Ast.StringLiteralNames{_, _, _, _, _, _, key, _}: BIR.DescriptorConstructor{key, Nil{}}
    case _ Ast.StringLiteralNames{_, _, _, _, _, _, _, key}: BIR.DescriptorConstructor{key, Nil{}}
def string_word(count: Nat, bits: U32, names: Ast.StringLiteralNames) -> BIR.Descriptor:
  match count names:
    case 0n Ast.StringLiteralNames{_, _, _, _, key, _, _, _}: BIR.DescriptorConstructor{key, Nil{}}
    case 1n+rest Ast.StringLiteralNames{_, _, _, _, _, key, _, _}:
      BIR.DescriptorConstructor{key, [string_bit(U32.and(bits, 1), names), string_word(rest, U32.shr(bits), names)]}
def string_descriptor(chars: List<&2, U32>, names: Ast.StringLiteralNames) -> BIR.Descriptor:
  match chars names:
    case Nil{} Ast.StringLiteralNames{key, _, _, _, _, _, _, _}: BIR.DescriptorConstructor{key, Nil{}}
    case char <> rest Ast.StringLiteralNames{_, cons, chr, uint, _, _, _, _}:
      BIR.DescriptorConstructor{cons, [BIR.DescriptorConstructor{chr, [BIR.DescriptorConstructor{uint, [string_word(32n, char, names)]}]}, string_descriptor(rest, names)]}
def native_match_descriptor_node_0(v_319: CatalogResult<String>) -> CatalogResult<BIR.Descriptor>:
  match v_319:
    case CatalogResult{v_16, v_17}:
      CatalogResult{v_16, BIR.DescriptorRef{v_17, []}}

def native_match_descriptor_node_1(v_320: CatalogResult<BIR.Descriptor>, v_27: Nat, v_33: BIR.Descriptor) -> CatalogResult<BIR.Descriptor>:
  match v_320:
    case CatalogResult{v_35, v_36}:
      CatalogResult{v_35, BIR.DescriptorSubstitution{v_27, v_33, v_36}}

def native_match_descriptor_node_2(v_321: CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_27: Nat, v_29: U32) -> CatalogResult<BIR.Descriptor>:
  match v_321:
    case CatalogResult{v_32, v_33}:
      native_match_descriptor_node_1(descriptor(v_32, v_29, v_2), v_27, v_33)

def native_match_descriptor_node_3(v_322: CatalogResult<BIR.Descriptor>, v_60: List<&2, BIR.Descriptor>) -> CatalogResult<BIR.Descriptor>:
  match v_322:
    case CatalogResult{v_62, v_63}:
      CatalogResult{v_62, BIR.DescriptorLet{v_60, v_63}}

def native_match_descriptor_node_4(v_323: CatalogResult<List<&2, BIR.Descriptor>>, v_2: Scope.ArenaGlobalScope, v_55: U32) -> CatalogResult<BIR.Descriptor>:
  match v_323:
    case CatalogResult{v_59, v_60}:
      native_match_descriptor_node_3(descriptor(v_59, v_55, v_2), v_60)

def native_match_descriptor_node_5(v_324: CatalogResult<BIR.Descriptor>) -> CatalogResult<BIR.Descriptor>:
  match v_324:
    case CatalogResult{v_80, v_81}:
      CatalogResult{v_80, BIR.DescriptorKind{v_81}}

def native_match_descriptor_node_6(v_325: CatalogResult<BIR.Descriptor>, v_95: BIR.Descriptor) -> CatalogResult<BIR.Descriptor>:
  match v_325:
    case CatalogResult{v_97, v_98}:
      CatalogResult{v_97, BIR.DescriptorMinimum{v_95, v_98}}

def native_match_descriptor_node_7(v_326: CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_91: U32) -> CatalogResult<BIR.Descriptor>:
  match v_326:
    case CatalogResult{v_94, v_95}:
      native_match_descriptor_node_6(descriptor(v_94, v_91, v_2), v_95)

def native_match_descriptor_node_8(v_327: CatalogResult<BIR.Descriptor>, v_105: Ast.Quantity, v_113: BIR.Descriptor) -> CatalogResult<BIR.Descriptor>:
  match v_327:
    case CatalogResult{v_115, v_116}:
      CatalogResult{v_115, BIR.DescriptorArrow{quantity(v_105), v_113, v_116}}

def native_match_descriptor_node_9(v_328: CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_105: Ast.Quantity, v_109: U32) -> CatalogResult<BIR.Descriptor>:
  match v_328:
    case CatalogResult{v_112, v_113}:
      native_match_descriptor_node_8(descriptor(v_112, v_109, v_2), v_105, v_113)

def native_match_descriptor_node_10(v_329: CatalogResult<BIR.Descriptor>, v_123: Maybe<&2, Ast.Quantity>) -> CatalogResult<BIR.Descriptor>:
  match v_329:
    case CatalogResult{v_129, v_130}:
      CatalogResult{v_129, BIR.DescriptorLambda{optional_quantity(v_123), v_130}}

def native_match_descriptor_node_11(v_330: CatalogResult<BIR.Descriptor>, v_140: BIR.Descriptor) -> CatalogResult<BIR.Descriptor>:
  match v_330:
    case CatalogResult{v_142, v_143}:
      CatalogResult{v_142, descriptor_apply(v_140, v_143)}

def native_match_descriptor_node_12(v_331: CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_136: U32) -> CatalogResult<BIR.Descriptor>:
  match v_331:
    case CatalogResult{v_139, v_140}:
      native_match_descriptor_node_11(descriptor(v_139, v_136, v_2), v_140)

def native_match_descriptor_node_13(v_332: CatalogResult<List<&2, BIR.Descriptor>>, v_159: String) -> CatalogResult<BIR.Descriptor>:
  match v_332:
    case CatalogResult{v_162, v_163}:
      CatalogResult{v_162, BIR.DescriptorRef{v_159, v_163}}

def native_match_descriptor_node_14(v_333: CatalogResult<String>, v_2: Scope.ArenaGlobalScope, v_152: U32, v_153: U32) -> CatalogResult<BIR.Descriptor>:
  match v_333:
    case CatalogResult{v_158, v_159}:
      native_match_descriptor_node_13(descriptors(v_158, v_152, v_153, v_2), v_159)

def native_match_descriptor_node_15(v_334: CatalogResult<List<&2, BIR.Descriptor>>, v_2: Scope.ArenaGlobalScope, v_168: U32) -> CatalogResult<BIR.Descriptor>:
  match v_334:
    case CatalogResult{v_174, v_175}:
      descriptor_sugar(v_174, v_168, v_175, False{}, v_2)

def native_match_descriptor_node_16(v_335: CatalogResult<List<&2, BIR.Descriptor>>, v_2: Scope.ArenaGlobalScope, v_181: U32) -> CatalogResult<BIR.Descriptor>:
  match v_335:
    case CatalogResult{v_187, v_188}:
      descriptor_sugar(v_187, v_181, v_188, True{}, v_2)

def native_match_descriptor_node_17(v_336: CatalogResult<List<&2, BIR.Descriptor>>, v_200: String) -> CatalogResult<BIR.Descriptor>:
  match v_336:
    case CatalogResult{v_203, v_204}:
      CatalogResult{v_203, BIR.DescriptorConstructor{v_200, v_204}}

def native_match_descriptor_node_18(v_337: CatalogResult<String>, v_2: Scope.ArenaGlobalScope, v_195: U32, v_196: U32) -> CatalogResult<BIR.Descriptor>:
  match v_337:
    case CatalogResult{v_199, v_200}:
      native_match_descriptor_node_17(descriptors(v_199, v_195, v_196, v_2), v_200)

def native_match_descriptor_node_19(v_338: CatalogResult<BIR.Descriptor>, v_223: BIR.Descriptor) -> CatalogResult<BIR.Descriptor>:
  match v_338:
    case CatalogResult{v_225, v_226}:
      CatalogResult{v_225, BIR.DescriptorBind{v_223, v_226}}

def native_match_descriptor_node_20(v_339: CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_218: U32) -> CatalogResult<BIR.Descriptor>:
  match v_339:
    case CatalogResult{v_222, v_223}:
      native_match_descriptor_node_19(descriptor(v_222, v_218, v_2), v_223)

def native_match_descriptor_node_21(v_340: CatalogResult<BIR.Descriptor>, v_239: BIR.Descriptor, v_242: BIR.Descriptor) -> CatalogResult<BIR.Descriptor>:
  match v_340:
    case CatalogResult{v_244, v_245}:
      CatalogResult{v_244, BIR.DescriptorEquality{v_239, v_242, v_245}}

def native_match_descriptor_node_22(v_341: CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_235: U32, v_239: BIR.Descriptor) -> CatalogResult<BIR.Descriptor>:
  match v_341:
    case CatalogResult{v_241, v_242}:
      native_match_descriptor_node_21(descriptor(v_241, v_235, v_2), v_239, v_242)

def native_match_descriptor_node_23(v_342: CatalogResult<BIR.Descriptor>, v_2: Scope.ArenaGlobalScope, v_234: U32, v_235: U32) -> CatalogResult<BIR.Descriptor>:
  match v_342:
    case CatalogResult{v_238, v_239}:
      native_match_descriptor_node_22(descriptor(v_238, v_234, v_2), v_2, v_235, v_239)

def native_match_descriptor_node_24(v_343: Sigma<&1, &1, Arena.Arena, _ => String>) -> CatalogResult<BIR.Descriptor>:
  match v_343:
    case (v_261, v_262):
      CatalogResult{v_261, BIR.DescriptorFailure{String.append("bend: unsolved hole ", v_262)}}

def native_match_descriptor_node_25(v_344: CatalogResult<List<&2, BIR.Descriptor>>, v_276: List<&2, BIR.Descriptor>) -> CatalogResult<BIR.Descriptor>:
  match v_344:
    case CatalogResult{v_279, v_280}:
      CatalogResult{v_279, BIR.DescriptorMatch{v_276, v_280}}

def native_match_descriptor_node_26(v_345: CatalogResult<List<&2, BIR.Descriptor>>, v_2: Scope.ArenaGlobalScope, v_270: U32, v_271: U32) -> CatalogResult<BIR.Descriptor>:
  match v_345:
    case CatalogResult{v_275, v_276}:
      native_match_descriptor_node_25(descriptor_cases(v_275, v_270, v_271, v_2), v_276)

def native_match_descriptor_node_27(v_346: CatalogResult<BIR.Descriptor>, v_307: List<&2, BIR.DescriptorPattern>, v_311: List<&2, BIR.Descriptor>) -> CatalogResult<BIR.Descriptor>:
  match v_346:
    case CatalogResult{v_313, v_314}:
      CatalogResult{v_313, BIR.DescriptorLocal{v_307, v_311, v_314}}

def native_match_descriptor_node_28(v_347: CatalogResult<List<&2, BIR.Descriptor>>, v_2: Scope.ArenaGlobalScope, v_302: U32, v_307: List<&2, BIR.DescriptorPattern>) -> CatalogResult<BIR.Descriptor>:
  match v_347:
    case CatalogResult{v_310, v_311}:
      native_match_descriptor_node_27(descriptor(v_310, v_302, v_2), v_307, v_311)

def native_match_descriptor_node_29(v_348: CatalogResult<List<&2, BIR.DescriptorPattern>>, v_2: Scope.ArenaGlobalScope, v_300: U32, v_301: U32, v_302: U32) -> CatalogResult<BIR.Descriptor>:
  match v_348:
    case CatalogResult{v_306, v_307}:
      native_match_descriptor_node_28(descriptors(v_306, v_300, v_301, v_2), v_2, v_302, v_307)

def native_match_descriptor_node_30(v_1: Arena.Node, v_0: Arena.Arena, v_2: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  match v_1:
    case Arena.TermVar{_, v_8, _}:
      CatalogResult{v_0, BIR.DescriptorParameter{v_8}}
    case Arena.TermRef{v_12, _}:
      native_match_descriptor_node_0(descriptor_name(v_0, v_12, v_2, False{}))
    case Arena.TermBang{v_20, _}:
      descriptor(v_0, v_20, v_2)
    case Arena.TermSub{v_27, v_28, v_29, _}:
      native_match_descriptor_node_2(descriptor(v_0, v_28, v_2), v_2, v_27, v_29)
    case Arena.TermLet{_, _, _, _, _, _, v_53, v_54, v_55, _}:
      native_match_descriptor_node_4(descriptors(v_0, v_53, v_54, v_2), v_2, v_55)
    case Arena.TermAnn{v_67, _, _}:
      descriptor(v_0, v_67, v_2)
    case Arena.TermTemplate{_, _}:
      CatalogResult{v_0, BIR.DescriptorFailure{"bend: unexpanded template"}}
    case Arena.TermType{v_77, _}:
      native_match_descriptor_node_5(descriptor(v_0, v_77, v_2))
    case Arena.TermQuant{}:
      CatalogResult{v_0, BIR.DescriptorQuantityKind{}}
    case Arena.TermQuantity{v_84, _}:
      CatalogResult{v_0, BIR.DescriptorQuantity{quantity(v_84)}}
    case Arena.TermMin{v_90, v_91, _}:
      native_match_descriptor_node_7(descriptor(v_0, v_90, v_2), v_2, v_91)
    case Arena.TermAll{v_105, _, _, v_108, v_109, _}:
      native_match_descriptor_node_9(descriptor(v_0, v_108, v_2), v_2, v_105, v_109)
    case Arena.TermLam{v_123, _, _, v_126, _}:
      native_match_descriptor_node_10(descriptor(v_0, v_126, v_2), v_123)
    case Arena.TermApp{v_135, v_136, _}:
      native_match_descriptor_node_12(descriptor(v_0, v_135, v_2), v_2, v_136)
    case Arena.TermAdt{v_151, v_152, v_153, _, _, _}:
      native_match_descriptor_node_14(descriptor_name(v_0, v_151, v_2, False{}), v_2, v_152, v_153)
    case Arena.TermFill{v_168, v_169, v_170, _}:
      native_match_descriptor_node_15(descriptors(v_0, v_169, v_170, v_2), v_2, v_168)
    case Arena.TermPlus{v_181, v_182, v_183, _}:
      native_match_descriptor_node_16(descriptors(v_0, v_182, v_183, v_2), v_2, v_181)
    case Arena.TermCtr{v_194, v_195, v_196, _}:
      native_match_descriptor_node_18(descriptor_name(v_0, v_194, v_2, True{}), v_2, v_195, v_196)
    case Arena.TermString{v_208, v_209, _}:
      CatalogResult{v_0, string_descriptor(v_208, string_names(v_209, v_2))}
    case Arena.TermMat{_, v_218, v_219, _}:
      native_match_descriptor_node_20(descriptor(v_0, v_219, v_2), v_2, v_218)
    case Arena.TermAbsurd{_}:
      CatalogResult{v_0, BIR.DescriptorFailure{"bend: runtime fail-stop"}}
    case Arena.TermEqual{v_233, v_234, v_235, _}:
      native_match_descriptor_node_23(descriptor(v_0, v_233, v_2), v_2, v_234, v_235)
    case Arena.TermRefl{_}:
      CatalogResult{v_0, BIR.DescriptorReflexivity{}}
    case Arena.TermRewrite{_, _, v_254, _}:
      descriptor(v_0, v_254, v_2)
    case Arena.TermHole{v_259, _}:
      native_match_descriptor_node_24(Arena.name_text(v_0, v_259))
    case Arena.BodyMatch{v_268, v_269, v_270, v_271, _}:
      native_match_descriptor_node_26(descriptors(v_0, v_268, v_269, v_2), v_2, v_270, v_271)
    case Arena.BodyCase{_, _, v_287, _}:
      descriptor(v_0, v_287, v_2)
    case Arena.BodyLocal{v_297, v_298, _, v_300, v_301, v_302, _}:
      native_match_descriptor_node_29(descriptor_patterns(v_0, v_297, v_298, v_2), v_2, v_300, v_301, v_302)
    case Arena.BodyReply{v_317, _}:
      descriptor(v_0, v_317, v_2)

def descriptor_node(v_0: Arena.Arena, v_1: Arena.Node, v_2: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  native_match_descriptor_node_30(v_1, v_0, v_2)

def native_match_descriptor_cases_0(v_89: CatalogResult<List<&2, BIR.Descriptor>>, v_19: BIR.Descriptor) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_89:
    case CatalogResult{v_22, v_23}:
      CatalogResult{v_22, v_19 <> v_23}

def native_match_descriptor_cases_1(v_90: CatalogResult<BIR.Descriptor>, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_90:
    case CatalogResult{v_18, v_19}:
      native_match_descriptor_cases_0(descriptor_cases(v_18, IR.arena_range_index(v_2, 1), U32.sub(v_4, 1), v_5), v_19)

def native_match_descriptor_cases_2(v_91: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_91:
    case (v_14, v_15):
      native_match_descriptor_cases_1(descriptor_case(v_14, v_15, v_5), v_2, v_4, v_5)

def native_match_descriptor_cases_3(v_92: Sigma<&1, &1, Arena.Arena, _ => U32>, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_92:
    case (v_11, v_12):
      native_match_descriptor_cases_2(Arena.get_node(v_11, v_12), v_2, v_4, v_5)

def native_match_descriptor_cases_4(v_4: U32, v_0: Arena.Arena, v_2: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_4:
    case 0:
      CatalogResult{v_0, []}
    case _:
      native_match_descriptor_cases_3(Arena.word(v_0, IR.arena_tape_offset(v_2)), v_2, v_4, v_5)

def descriptor_cases(v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  native_match_descriptor_cases_4(v_4, v_0, v_2, v_5)

def native_match_descriptor_case_0(v_21: CatalogResult<BIR.Descriptor>, v_15: List<&2, BIR.DescriptorPattern>) -> CatalogResult<BIR.Descriptor>:
  match v_21:
    case CatalogResult{v_17, v_18}:
      CatalogResult{v_17, BIR.DescriptorCase{v_15, v_18}}

def native_match_descriptor_case_1(v_22: CatalogResult<List<&2, BIR.DescriptorPattern>>, v_2: Scope.ArenaGlobalScope, v_10: U32) -> CatalogResult<BIR.Descriptor>:
  match v_22:
    case CatalogResult{v_14, v_15}:
      native_match_descriptor_case_0(descriptor(v_14, v_10, v_2), v_15)

def native_match_descriptor_case_2(v_1: Arena.Node, v_0: Arena.Arena, v_2: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  match v_1:
    case Arena.BodyCase{v_8, v_9, v_10, _}:
      native_match_descriptor_case_1(descriptor_patterns(v_0, v_8, v_9, v_2), v_2, v_10)
    case _:
      CatalogResult{v_0, BIR.DescriptorFailure{"bend: malformed type match"}}

def descriptor_case(v_0: Arena.Arena, v_1: Arena.Node, v_2: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  native_match_descriptor_case_2(v_1, v_0, v_2)

def native_match_telescope_0(v_89: CatalogResult<Telescope>, v_3: U32, v_4: Scope.ArenaGlobalScope, v_18: Arena.Binder) -> CatalogResult<Telescope>:
  match v_89:
    case CatalogResult{v_21, v_22}:
      telescope_binder(v_21, v_18, v_3, v_4, v_22)

def native_match_telescope_1(v_90: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_3: U32, v_4: Scope.ArenaGlobalScope, v_11: U32, v_12: U32) -> CatalogResult<Telescope>:
  match v_90:
    case (v_17, v_18):
      native_match_telescope_0(telescope(v_17, IR.Words{IR.arena_range_index(v_11, 1), U32.sub(v_12, 1)}, U32.add(v_3, 1), v_4), v_3, v_4, v_18)

def native_match_telescope_2(v_91: Sigma<&1, &1, Arena.Arena, _ => U32>, v_3: U32, v_4: Scope.ArenaGlobalScope, v_11: U32, v_12: U32) -> CatalogResult<Telescope>:
  match v_91:
    case (v_14, v_15):
      native_match_telescope_1(Arena.get_binder(v_14, v_15), v_3, v_4, v_11, v_12)

def native_match_telescope_3(v_1: IR.Words, v_0: Arena.Arena, v_3: U32, v_4: Scope.ArenaGlobalScope) -> CatalogResult<Telescope>:
  match v_1:
    case IR.Words{v_8, 0}:
      CatalogResult{v_0, Telescope{[], [], [], True{}}}
    case IR.Words{v_11, v_12}:
      native_match_telescope_2(Arena.word(v_0, IR.arena_tape_offset(v_11)), v_3, v_4, v_11, v_12)

def telescope(v_0: Arena.Arena, v_1: IR.Words, v_3: U32, v_4: Scope.ArenaGlobalScope) -> CatalogResult<Telescope>:
  native_match_telescope_3(v_1, v_0, v_3, v_4)

def native_match_telescope_binder_0(v_55: CatalogResult<BIR.Descriptor>, v_3: U32, v_18: Ast.Quantity, v_23: List<&2, BIR.Parameter>, v_24: List<&2, BIR.Quantity>, v_25: List<&2, BIR.DescriptorField>, v_26: Bool, v_28: String) -> CatalogResult<Telescope>:
  match v_55:
    case CatalogResult{v_30, v_31}:
      v_33 = quantity(v_18)
      CatalogResult{v_30, Telescope{parameter(v_3, v_33, v_23), v_33 <> v_24, BIR.DescriptorField{field_key(v_28, v_33), v_33, v_31} <> v_25, v_26}}

def native_match_telescope_binder_1(v_56: Sigma<&1, &1, Arena.Arena, _ => String>, v_3: U32, v_4: Scope.ArenaGlobalScope, v_18: Ast.Quantity, v_21: U32, v_23: List<&2, BIR.Parameter>, v_24: List<&2, BIR.Quantity>, v_25: List<&2, BIR.DescriptorField>, v_26: Bool) -> CatalogResult<Telescope>:
  match v_56:
    case (v_27, v_28):
      native_match_telescope_binder_0(descriptor(v_27, v_21, v_4), v_3, v_18, v_23, v_24, v_25, v_26, v_28)

def native_match_telescope_binder_2(v_57: CatalogResult<BIR.Descriptor>, v_48: List<&2, BIR.Parameter>, v_49: List<&2, BIR.Quantity>, v_50: List<&2, BIR.DescriptorField>) -> CatalogResult<Telescope>:
  match v_57:
    case CatalogResult{v_53, v_54}:
      CatalogResult{v_53, Telescope{v_48, BIR.Erased{} <> v_49, BIR.DescriptorField{None{}, BIR.Erased{}, v_54} <> v_50, False{}}}

def native_match_telescope_binder_3(v_1: Arena.Binder, v_6: Telescope, v_0: Arena.Arena, v_3: U32, v_4: Scope.ArenaGlobalScope) -> CatalogResult<Telescope>:
  match v_1, v_6:
    case Arena.Binder{v_18, v_19, _, v_21, _}, Telescope{v_23, v_24, v_25, v_26}:
      native_match_telescope_binder_1(Arena.name_text(v_0, v_19), v_3, v_4, v_18, v_21, v_23, v_24, v_25, v_26)
    case Arena.TemplateBinder{_, _, v_46, _}, Telescope{v_48, v_49, v_50, _}:
      native_match_telescope_binder_2(descriptor(v_0, v_46, v_4), v_48, v_49, v_50)

def telescope_binder(v_0: Arena.Arena, v_1: Arena.Binder, v_3: U32, v_4: Scope.ArenaGlobalScope, v_6: Telescope) -> CatalogResult<Telescope>:
  native_match_telescope_binder_3(v_1, v_6, v_0, v_3, v_4)

def field_names(fields: List<&2, BIR.DescriptorField>) -> List<&2, Maybe<&2, String>>:
  match fields:
    case Nil{}: Nil{}
    case BIR.DescriptorField{key, _, _} <> rest: key <> field_names(rest)
def fields_quantities(fields: List<&2, BIR.DescriptorField>) -> List<&2, BIR.Quantity>:
  match fields:
    case Nil{}: Nil{}
    case BIR.DescriptorField{_, q, _} <> rest: q <> fields_quantities(rest)
def base_imports(imports: List<&2, Ast.ModuleImport>) -> Bool:
  match imports:
    case Nil{}: False{}
    case Ast.ModuleImport{path, _, _} <> rest: Bool.or(String.eq(path, "Base"), base_imports(rest))
def base_imported(modules: List<&2, IR.LoadedModule>) -> Bool:
  match modules:
    case Nil{}: False{}
    case IR.LoadedModule{_, IR.Module{_, imports, _}} <> rest: Bool.or(base_imports(imports), base_imported(rest))
def base_source(path: String, imported: Bool) -> Bool:
  Bool.and(imported, Bool.or(String.eq(path, "bend2/base.bend"), String.ends_with(path, "/bend2/base.bend")))
def native_marker(native: Bool, key: String) -> Maybe<&2, String>:
  match native:
    case True{}: Some{key}
    case False{}: None{}
def short_key(key: String) -> String:
  short_chars(String.to_list(key), Nil{})
def short_chars(chars: List<&2, Char>, reversed: List<&2, Char>) -> String:
  match chars:
    case Nil{}: String.from_list(List.reverse(&2, Char, reversed))
    case '.' <> rest: short_chars(rest, Nil{})
    case '/' <> rest: short_chars(rest, Nil{})
    case char <> rest: short_chars(rest, char <> reversed)
def constructor_native(native: Bool, family: String, key: String) -> Maybe<&2, String>:
  match native:
    case True{}: Some{String.append(family, String.append(".", short_key(key)))}
    case False{}: Some{String.append("Data.", key)}
def primitive_name(key: String) -> String:
  String.from_list(primitive_chars(String.to_list(String.to_lower(key))))
def primitive_chars(chars: List<&2, Char>) -> List<&2, Char>:
  match chars:
    case Nil{}: Nil{}
    case '.' <> rest: '_' <> primitive_chars(rest)
    case '/' <> rest: '_' <> primitive_chars(rest)
    case char <> rest: char <> primitive_chars(rest)
def primitive(native: Bool, key: String) -> Maybe<&2, BIR.Primitive>:
  match native:
    case False{}: None{}
    case True{}: primitive_named(primitive_name(key))
def primitive_named(name: String) -> Maybe<&2, BIR.Primitive>:
  match name:
    case "u32_add": Some{BIR.PrimU32Add{}}
    case "u32_sub": Some{BIR.PrimU32Sub{}}
    case "u32_mul": Some{BIR.PrimU32Mul{}}
    case "u32_div": Some{BIR.PrimU32Div{}}
    case "u32_mod": Some{BIR.PrimU32Mod{}}
    case "u32_and": Some{BIR.PrimU32And{}}
    case "u32_or": Some{BIR.PrimU32Or{}}
    case "u32_xor": Some{BIR.PrimU32Xor{}}
    case "u32_is_eq": Some{BIR.PrimU32IsEq{}}
    case "u32_is_ne": Some{BIR.PrimU32IsNe{}}
    case "u32_is_lt": Some{BIR.PrimU32IsLt{}}
    case "u32_is_le": Some{BIR.PrimU32IsLe{}}
    case "u32_is_gt": Some{BIR.PrimU32IsGt{}}
    case "u32_is_ge": Some{BIR.PrimU32IsGe{}}
    case "u32_inc": Some{BIR.PrimU32Inc{}}
    case "u32_not": Some{BIR.PrimU32Not{}}
    case "u32_shl": Some{BIR.PrimU32Shl{}}
    case "u32_shr": Some{BIR.PrimU32Shr{}}
    case "u32_shln": Some{BIR.PrimU32Shln{}}
    case "u32_shrn": Some{BIR.PrimU32Shrn{}}
    case "u32_cmp": Some{BIR.PrimU32Cmp{}}
    case "u32_is_zero": Some{BIR.PrimU32IsZero{}}
    case "u32_to_nat": Some{BIR.PrimU32ToNat{}}
    case "u32_from_nat": Some{BIR.PrimU32FromNat{}}
    case "u32_to_f32": Some{BIR.PrimU32ToF32{}}
    case "f32_add": Some{BIR.PrimF32Add{}}
    case "f32_sub": Some{BIR.PrimF32Sub{}}
    case "f32_mul": Some{BIR.PrimF32Mul{}}
    case "f32_div": Some{BIR.PrimF32Div{}}
    case "f32_mod": Some{BIR.PrimF32Mod{}}
    case "f32_neg": Some{BIR.PrimF32Neg{}}
    case "f32_is_eq": Some{BIR.PrimF32IsEq{}}
    case "f32_is_ne": Some{BIR.PrimF32IsNe{}}
    case "f32_is_lt": Some{BIR.PrimF32IsLt{}}
    case "f32_is_le": Some{BIR.PrimF32IsLe{}}
    case "f32_is_gt": Some{BIR.PrimF32IsGt{}}
    case "f32_is_ge": Some{BIR.PrimF32IsGe{}}
    case "f32_sqrt": Some{BIR.PrimF32Sqrt{}}
    case "f32_abs": Some{BIR.PrimF32Abs{}}
    case "f32_exp": Some{BIR.PrimF32Exp{}}
    case "f32_log": Some{BIR.PrimF32Log{}}
    case "f32_log2": Some{BIR.PrimF32Log2{}}
    case "f32_log10": Some{BIR.PrimF32Log10{}}
    case "f32_sin": Some{BIR.PrimF32Sin{}}
    case "f32_cos": Some{BIR.PrimF32Cos{}}
    case "f32_tan": Some{BIR.PrimF32Tan{}}
    case "f32_asin": Some{BIR.PrimF32Asin{}}
    case "f32_acos": Some{BIR.PrimF32Acos{}}
    case "f32_atan": Some{BIR.PrimF32Atan{}}
    case "f32_sinh": Some{BIR.PrimF32Sinh{}}
    case "f32_cosh": Some{BIR.PrimF32Cosh{}}
    case "f32_tanh": Some{BIR.PrimF32Tanh{}}
    case "f32_pow": Some{BIR.PrimF32Pow{}}
    case "f32_atan2": Some{BIR.PrimF32Atan2{}}
    case "f32_floor": Some{BIR.PrimF32Floor{}}
    case "f32_ceil": Some{BIR.PrimF32Ceil{}}
    case "f32_trunc": Some{BIR.PrimF32Trunc{}}
    case "f32_to_u32": Some{BIR.PrimF32ToU32{}}
    case "f32_bits": Some{BIR.PrimF32Bits{}}
    case "f32_show": Some{BIR.PrimF32Show{}}
    case "f32_read": Some{BIR.PrimF32Read{}}
    case "nat_add": Some{BIR.PrimNatAdd{}}
    case "nat_sub": Some{BIR.PrimNatSub{}}
    case "nat_mul": Some{BIR.PrimNatMul{}}
    case "nat_double": Some{BIR.PrimNatDouble{}}
    case "nat_cmp": Some{BIR.PrimNatCmp{}}
    case "nat_is_lt": Some{BIR.PrimNatIsLt{}}
    case "nat_divmod": Some{BIR.PrimNatDivmod{}}
    case "nat_min": Some{BIR.PrimNatMin{}}
    case "nat_max": Some{BIR.PrimNatMax{}}
    case "map_bit": Some{BIR.PrimMapBit{}}
    case "string_cmp": Some{BIR.PrimStringCmp{}}
    case "string_to_list": Some{BIR.PrimStringToList{}}
    case "string_eq": Some{BIR.PrimStringEq{}}
    case "string_append": Some{BIR.PrimStringAppend{}}
    case "string_length": Some{BIR.PrimStringLength{}}
    case "bool_or": Some{BIR.PrimBoolOr{}}
    case "bool_xor": Some{BIR.PrimBoolXor{}}
    case "array_new": Some{BIR.PrimArrayNew{}}
    case "array_set": Some{BIR.PrimArraySet{}}
    case "array_get": Some{BIR.PrimArrayGet{}}
    case "array_swap": Some{BIR.PrimArraySwap{}}
    case "array_size": Some{BIR.PrimArraySize{}}
    case "array_clone": Some{BIR.PrimArrayClone{}}
    case _: None{}

def definition_key(registry: Registry, key: String) -> Maybe<&2, DefinitionHeader>:
  match registry:
    case Registry{index, _}: IndexLookup.find(DefinitionHeader, index, key)
def constructor_key(registry: Registry, key: String) -> Maybe<&2, Constructor>:
  match registry:
    case Registry{_, index}: IndexLookup.find(Constructor, index, key)
def lookup_definition(registry: Registry, symbol: IR.Symbol) -> Maybe<&2, DefinitionHeader>:
  definition_key(registry, symbol_key(symbol))
def lookup_constructor(registry: Registry, symbol: IR.Symbol) -> Maybe<&2, Constructor>:
  constructor_key(registry, symbol_key(symbol))
def get_definitions(catalog: Catalog) -> List<&2, Definition>:
  match catalog:
    case Catalog{values, _, _, _, _, _, _}: values
def get_registry(catalog: Catalog) -> Registry:
  match catalog:
    case Catalog{_, value, _, _, _, _, _}: value
def get_constructors(catalog: Catalog) -> List<&2, BIR.ConstructorLayout>:
  match catalog:
    case Catalog{_, _, values, _, _, _, _}: values
def get_families(catalog: Catalog) -> List<&2, BIR.Family>:
  match catalog:
    case Catalog{_, _, _, values, _, _, _}: values
def get_type_functions(catalog: Catalog) -> List<&2, BIR.TypeFunction>:
  match catalog:
    case Catalog{_, _, _, _, values, _, _}: values
def get_next_code(catalog: Catalog) -> U32:
  match catalog:
    case Catalog{_, _, _, _, _, value, _}: value
def get_ending(catalog: Catalog) -> BIR.Ending:
  match catalog:
    case Catalog{_, _, _, _, _, _, value}: value
def native_match_insert_definition_0(v_13: Maybe<&2, Definition>, +v_1: String, v_3: Definition, +v_6: Map<&2, Definition>) -> Map<&2, Definition>:
  match v_13:
    case Some{_}:
      v_6
    case None{}:
      Map.set(&2, Definition, v_6, v_1, v_3)

def insert_definition(+v_1: String, v_3: Definition, +v_6: Map<&2, Definition>) -> Map<&2, Definition>:
  native_match_insert_definition_0(IndexLookup.find(Definition, v_6, v_1), v_1, v_3, v_6)

def native_match_insert_constructor_0(v_13: Maybe<&2, Constructor>, +v_1: String, v_3: Constructor, +v_6: Map<&2, Constructor>) -> Map<&2, Constructor>:
  match v_13:
    case Some{_}:
      v_6
    case None{}:
      Map.set(&2, Constructor, v_6, v_1, v_3)

def insert_constructor(+v_1: String, v_3: Constructor, +v_6: Map<&2, Constructor>) -> Map<&2, Constructor>:
  native_match_insert_constructor_0(IndexLookup.find(Constructor, v_6, v_1), v_1, v_3, v_6)

def export_entry(value: Maybe<&2, DefinitionHeader>) -> Maybe<&2, BIR.Entry>:
  match value:
    case Some{DefinitionHeader{_, _, code, parameters, _, _, _, _, True{}}}:
      Some{BIR.Entry{code, List.length(&2, BIR.Parameter, parameters)}}
    case _: None{}

def export_definition(key: String, definitions: List<&2, Definition>) -> Maybe<&2, Definition>:
  match definitions:
    case Nil{}: None{}
    case +definition <> rest:
      match definition:
        case Definition{DefinitionHeader{_, known, _, _, _, _, _, _, _}, _, _, _, _, _, _, _}:
          match String.eq(key, known):
            case True{}: Some{definition}
            case False{}: export_definition(key, rest)

def export_result_type(source: Arena.Arena, result: IR.OptionalTerm, scope: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  match result:
    case IR.NoTerm{}:
      CatalogResult{source, BIR.DescriptorFailure{"bend: exported definition has no checked result type"}}
    case IR.SomeTerm{term}:
      descriptor(source, term, scope)

# Export host ABI facts are computed once from the published checked signature
# and law telescope of the exported definition. A missing prepared definition
# is an explicit descriptor failure, never a guessed type.
def export_facts(v_0: Arena.Arena, key: String, definitions: List<&2, Definition>) -> CatalogResult<ExportFacts>:
  match export_definition(key, definitions):
    case None{}:
      CatalogResult{v_0, ExportFacts{[], BIR.DescriptorFailure{String.append("bend: exported definition is not prepared: ", key)}}}
    case Some{Definition{_, binders, result, _, _, scope, _, _}}:
      match live_parameter_types(v_0, binders, scope, Nil{}):
        case CatalogResult{v_20, parameter_types}:
          match export_result_type(v_20, result, scope):
            case CatalogResult{v_21, result_type}:
              CatalogResult{v_21, ExportFacts{parameter_types, result_type}}

def exports(keys: List<&2, String>, registry: Registry, v_0: Arena.Arena, definitions: List<&2, Definition>) -> CatalogResult<List<&2, BIR.Export>>:
  match keys:
    case Nil{}: CatalogResult{v_0, Nil{}}
    case key <> rest:
      match export_facts(v_0, key, definitions):
        case CatalogResult{v_20, ExportFacts{parameter_types, result_type}}:
          match exports(rest, registry, v_20, definitions):
            case CatalogResult{v_21, tail}:
              CatalogResult{v_21, BIR.Export{key, export_entry(definition_key(registry, key)), parameter_types, result_type} <> tail}

# Reachability is a visited-set walk, not reduction and not fuel-bounded.
# Register before traversing a body so recursive descriptor functions terminate.
def native_match_needed_ref_0(v_20: Maybe<&2, Bool>, v_0: Arena.Arena, v_2: String, v_5: Map<&2, Definition>, v_7: Needed, v_12: List<&2, BIR.TypeFunction>, v_13: Map<&2, Bool>) -> CatalogResult<Needed>:
  match v_20:
    case Some{_}:
      CatalogResult{v_0, v_7}
    case None{}:
      needed_definition(v_0, IndexLookup.find(Definition, v_5, v_2), v_5, v_12, Map.set(&2, Bool, v_13, v_2, True{}))

def native_match_needed_ref_1(v_7: Needed, v_0: Arena.Arena, v_2: String, v_5: Map<&2, Definition>) -> CatalogResult<Needed>:
  match v_7:
    case Needed{v_12, v_13}:
      native_match_needed_ref_0(IndexLookup.find(Bool, v_13, v_2), v_0, v_2, v_5, v_7, v_12, v_13)

def needed_ref(v_0: Arena.Arena, v_2: String, v_5: Map<&2, Definition>, v_7: Needed) -> CatalogResult<Needed>:
  native_match_needed_ref_1(v_7, v_0, v_2, v_5)

def native_match_needed_definition_0(v_57: CatalogResult<BIR.Descriptor>, v_6: Map<&2, Definition>, v_8: List<&2, BIR.TypeFunction>, v_11: Map<&2, Bool>, v_30: String, v_33: List<&2, BIR.Quantity>, v_39: U32, v_41: Scope.ArenaGlobalScope, v_42: Maybe<&2, String>, v_43: Nat) -> CatalogResult<Needed>:
  match v_57:
    case CatalogResult{v_46, v_47}:
      v_49 = BIR.TypeFunction{v_30, v_42, v_43, List.length(&2, BIR.Quantity, v_33), v_47}
      needed_term(v_46, v_39, v_41, v_6, Needed{v_49 <> v_8, v_11})

def native_match_needed_definition_1(v_3: Maybe<&2, Definition>, v_0: Arena.Arena, v_6: Map<&2, Definition>, v_8: List<&2, BIR.TypeFunction>, v_11: Map<&2, Bool>) -> CatalogResult<Needed>:
  match v_3:
    case Some{Definition{DefinitionHeader{_, v_30, _, _, v_33, _, _, None{}, _}, _, _, IR.DefTerm{v_39}, _, v_41, v_42, v_43}}:
      native_match_needed_definition_0(descriptor(v_0, v_39, v_41), v_6, v_8, v_11, v_30, v_33, v_39, v_41, v_42, v_43)
    case _:
      CatalogResult{v_0, Needed{v_8, v_11}}

def needed_definition(v_0: Arena.Arena, v_3: Maybe<&2, Definition>, v_6: Map<&2, Definition>, v_8: List<&2, BIR.TypeFunction>, v_11: Map<&2, Bool>) -> CatalogResult<Needed>:
  native_match_needed_definition_1(v_3, v_0, v_6, v_8, v_11)

def native_match_needed_terms_0(v_86: CatalogResult<Needed>, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, Definition>) -> CatalogResult<Needed>:
  match v_86:
    case CatalogResult{v_19, v_20}:
      needed_terms(v_19, IR.arena_range_index(v_2, 1), U32.sub(v_4, 1), v_5, v_8, v_20)

def native_match_needed_terms_1(v_87: Sigma<&1, &1, Arena.Arena, _ => U32>, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, Definition>, v_10: Needed) -> CatalogResult<Needed>:
  match v_87:
    case (v_16, v_17):
      native_match_needed_terms_0(needed_term(v_16, v_17, v_5, v_8, v_10), v_2, v_4, v_5, v_8)

def native_match_needed_terms_2(v_4: U32, v_0: Arena.Arena, v_2: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, Definition>, v_10: Needed) -> CatalogResult<Needed>:
  match v_4:
    case 0:
      CatalogResult{v_0, v_10}
    case _:
      native_match_needed_terms_1(Arena.word(v_0, IR.arena_tape_offset(v_2)), v_2, v_4, v_5, v_8, v_10)

def needed_terms(v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, Definition>, v_10: Needed) -> CatalogResult<Needed>:
  native_match_needed_terms_2(v_4, v_0, v_2, v_5, v_8, v_10)

def native_match_needed_pair_0(v_16: CatalogResult<Needed>, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, Definition>) -> CatalogResult<Needed>:
  match v_16:
    case CatalogResult{v_14, v_15}:
      needed_term(v_14, v_4, v_5, v_8, v_15)

def needed_pair(v_0: Arena.Arena, v_2: U32, v_4: U32, v_5: Scope.ArenaGlobalScope, v_8: Map<&2, Definition>, v_10: Needed) -> CatalogResult<Needed>:
  native_match_needed_pair_0(needed_term(v_0, v_2, v_5, v_8, v_10), v_4, v_5, v_8)

def native_match_needed_term_0(v_257: CatalogResult<String>, v_6: Map<&2, Definition>, v_8: Needed) -> CatalogResult<Needed>:
  match v_257:
    case CatalogResult{v_19, v_20}:
      needed_ref(v_19, v_20, v_6, v_8)

def native_match_needed_term_1(v_258: CatalogResult<Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, Definition>, v_54: U32) -> CatalogResult<Needed>:
  match v_258:
    case CatalogResult{v_57, v_58}:
      needed_term(v_57, v_54, v_3, v_6, v_58)

def native_match_needed_term_2(v_259: CatalogResult<Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, Definition>, v_127: U32) -> CatalogResult<Needed>:
  match v_259:
    case CatalogResult{v_132, v_133}:
      needed_term(v_132, v_127, v_3, v_6, v_133)

def native_match_needed_term_3(v_260: CatalogResult<Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, Definition>, v_139: U32) -> CatalogResult<Needed>:
  match v_260:
    case CatalogResult{v_144, v_145}:
      needed_term(v_144, v_139, v_3, v_6, v_145)

def native_match_needed_term_4(v_261: CatalogResult<Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, Definition>, v_190: U32, v_191: U32) -> CatalogResult<Needed>:
  match v_261:
    case CatalogResult{v_194, v_195}:
      needed_terms(v_194, v_190, v_191, v_3, v_6, v_195)

def native_match_needed_term_5(v_262: CatalogResult<Needed>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, Definition>, v_218: U32) -> CatalogResult<Needed>:
  match v_262:
    case CatalogResult{v_221, v_222}:
      needed_term(v_221, v_218, v_3, v_6, v_222)

def native_match_needed_term_6(v_13: Arena.Node, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, Definition>, v_8: Needed, v_12: Arena.Arena) -> CatalogResult<Needed>:
  match v_13:
    case Arena.TermRef{v_16, _}:
      native_match_needed_term_0(descriptor_name(v_12, v_16, v_3, False{}), v_6, v_8)
    case Arena.TermBang{v_24, _}:
      needed_term(v_12, v_24, v_3, v_6, v_8)
    case Arena.TermSub{_, v_32, v_33, _}:
      needed_pair(v_12, v_32, v_33, v_3, v_6, v_8)
    case Arena.TermLet{_, _, _, _, _, _, v_52, v_53, v_54, _}:
      native_match_needed_term_1(needed_terms(v_12, v_52, v_53, v_3, v_6, v_8), v_3, v_6, v_54)
    case Arena.TermAnn{v_63, v_64, _}:
      needed_pair(v_12, v_63, v_64, v_3, v_6, v_8)
    case Arena.TermType{v_69, _}:
      needed_term(v_12, v_69, v_3, v_6, v_8)
    case Arena.TermMin{v_75, v_76, _}:
      needed_pair(v_12, v_75, v_76, v_3, v_6, v_8)
    case Arena.TermAll{_, _, _, v_88, v_89, _}:
      needed_pair(v_12, v_88, v_89, v_3, v_6, v_8)
    case Arena.TermLam{_, _, _, v_100, _}:
      needed_term(v_12, v_100, v_3, v_6, v_8)
    case Arena.TermApp{v_106, v_107, _}:
      needed_pair(v_12, v_106, v_107, v_3, v_6, v_8)
    case Arena.TermAdt{_, v_117, v_118, _, _, _}:
      needed_terms(v_12, v_117, v_118, v_3, v_6, v_8)
    case Arena.TermFill{v_127, v_128, v_129, _}:
      native_match_needed_term_2(needed_terms(v_12, v_128, v_129, v_3, v_6, v_8), v_3, v_6, v_127)
    case Arena.TermPlus{v_139, v_140, v_141, _}:
      native_match_needed_term_3(needed_terms(v_12, v_140, v_141, v_3, v_6, v_8), v_3, v_6, v_139)
    case Arena.TermCtr{_, v_152, v_153, _}:
      needed_terms(v_12, v_152, v_153, v_3, v_6, v_8)
    case Arena.TermMat{_, v_161, v_162, _}:
      needed_pair(v_12, v_161, v_162, v_3, v_6, v_8)
    case Arena.TermEqual{_, _, v_171, _}:
      needed_term(v_12, v_171, v_3, v_6, v_8)
    case Arena.TermRewrite{_, _, v_180, _}:
      needed_term(v_12, v_180, v_3, v_6, v_8)
    case Arena.BodyMatch{v_188, v_189, v_190, v_191, _}:
      native_match_needed_term_4(needed_terms(v_12, v_188, v_189, v_3, v_6, v_8), v_3, v_6, v_190, v_191)
    case Arena.BodyCase{_, _, v_203, _}:
      needed_term(v_12, v_203, v_3, v_6, v_8)
    case Arena.BodyLocal{_, _, _, v_216, v_217, v_218, _}:
      native_match_needed_term_5(needed_terms(v_12, v_216, v_217, v_3, v_6, v_8), v_3, v_6, v_218)
    case Arena.BodyReply{v_226, _}:
      needed_term(v_12, v_226, v_3, v_6, v_8)
    case Arena.TermVar{_, _, _}:
      CatalogResult{v_12, v_8}
    case Arena.TermTemplate{_, _}:
      CatalogResult{v_12, v_8}
    case Arena.TermQuant{}:
      CatalogResult{v_12, v_8}
    case Arena.TermQuantity{_, _}:
      CatalogResult{v_12, v_8}
    case Arena.TermString{_, _, _}:
      CatalogResult{v_12, v_8}
    case Arena.TermAbsurd{_}:
      CatalogResult{v_12, v_8}
    case Arena.TermRefl{_}:
      CatalogResult{v_12, v_8}
    case Arena.TermHole{_, _}:
      CatalogResult{v_12, v_8}

def native_match_needed_term_7(v_263: Sigma<&1, &1, Arena.Arena, _ => Arena.Node>, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, Definition>, v_8: Needed) -> CatalogResult<Needed>:
  match v_263:
    case (v_12, v_13):
      native_match_needed_term_6(v_13, v_3, v_6, v_8, v_12)

def needed_term(v_0: Arena.Arena, v_2: U32, v_3: Scope.ArenaGlobalScope, v_6: Map<&2, Definition>, v_8: Needed) -> CatalogResult<Needed>:
  native_match_needed_term_7(Arena.get_node(v_0, v_2), v_3, v_6, v_8)

def native_match_needed_roots_0(v_29: CatalogResult<Needed>, v_6: Map<&2, Definition>, v_16: List<&2, Root>) -> CatalogResult<Needed>:
  match v_29:
    case CatalogResult{v_18, v_19}:
      needed_roots(v_18, v_16, v_6, v_19)

def native_match_needed_roots_1(v_30: CatalogResult<Needed>, v_6: Map<&2, Definition>, v_24: List<&2, Root>) -> CatalogResult<Needed>:
  match v_30:
    case CatalogResult{v_26, v_27}:
      needed_roots(v_26, v_24, v_6, v_27)

def native_match_needed_roots_2(v_3: List<&2, Root>, v_0: Arena.Arena, v_6: Map<&2, Definition>, v_8: Needed) -> CatalogResult<Needed>:
  match v_3:
    case []:
      CatalogResult{v_0, v_8}
    case TermRoot{v_14, v_15} <> v_16:
      native_match_needed_roots_0(needed_term(v_0, v_14, v_15, v_6, v_8), v_6, v_16)
    case DefinitionRoot{v_23} <> v_24:
      native_match_needed_roots_1(needed_ref(v_0, v_23, v_6, v_8), v_6, v_24)

def needed_roots(v_0: Arena.Arena, v_3: List<&2, Root>, v_6: Map<&2, Definition>, v_8: Needed) -> CatalogResult<Needed>:
  native_match_needed_roots_2(v_3, v_0, v_6, v_8)

def native_match_binder_roots_0(v_87: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_2: Scope.ArenaGlobalScope, v_5: List<&2, Root>, v_13: U32, v_14: U32) -> CatalogResult<List<&2, Root>>:
  match v_87:
    case (v_19, v_20):
      binder_roots(v_19, IR.Words{IR.arena_range_index(v_13, 1), U32.sub(v_14, 1)}, v_2, TermRoot{binder_type(v_20), v_2} <> v_5)

def native_match_binder_roots_1(v_88: Sigma<&1, &1, Arena.Arena, _ => U32>, v_2: Scope.ArenaGlobalScope, v_5: List<&2, Root>, v_13: U32, v_14: U32) -> CatalogResult<List<&2, Root>>:
  match v_88:
    case (v_16, v_17):
      native_match_binder_roots_0(Arena.get_binder(v_16, v_17), v_2, v_5, v_13, v_14)

def native_match_binder_roots_2(v_1: IR.Words, v_0: Arena.Arena, v_2: Scope.ArenaGlobalScope, v_5: List<&2, Root>) -> CatalogResult<List<&2, Root>>:
  match v_1:
    case IR.Words{_, 0}:
      CatalogResult{v_0, v_5}
    case IR.Words{v_13, v_14}:
      native_match_binder_roots_1(Arena.word(v_0, IR.arena_tape_offset(v_13)), v_2, v_5, v_13, v_14)

def binder_roots(v_0: Arena.Arena, v_1: IR.Words, v_2: Scope.ArenaGlobalScope, v_5: List<&2, Root>) -> CatalogResult<List<&2, Root>>:
  native_match_binder_roots_2(v_1, v_0, v_2, v_5)

def binder_type(binder: Arena.Binder) -> U32:
  match binder:
    case Arena.Binder{_, _, _, ty, _}: ty
    case Arena.TemplateBinder{_, _, ty, _}: ty
def result_roots(result: IR.OptionalTerm, scope: Scope.ArenaGlobalScope, roots: List<&2, Root>) -> List<&2, Root>:
  match result:
    case IR.NoTerm{}: roots
    case IR.SomeTerm{term}: TermRoot{term, scope} <> roots
def type_root(type_only: Bool, key: String, roots: List<&2, Root>) -> List<&2, Root>:
  match type_only:
    case True{}: DefinitionRoot{key} <> roots
    case False{}: roots

def preparation_failure(state: Preparation, message: String) -> Preparation:
  match state:
    case Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, failure, owners}:
      Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, first_failure(failure, message), owners}
def first_failure(old: Maybe<&2, String>, message: String) -> Maybe<&2, String>:
  match old:
    case Some{_}: old
    case None{}: Some{message}
def native_match_header_insert_0(v_13: Maybe<&2, DefinitionHeader>, +v_1: String, v_3: DefinitionHeader, +v_6: Map<&2, DefinitionHeader>) -> Map<&2, DefinitionHeader>:
  match v_13:
    case Some{_}:
      v_6
    case None{}:
      Map.set(&2, DefinitionHeader, v_6, v_1, v_3)

def header_insert(+v_1: String, v_3: DefinitionHeader, +v_6: Map<&2, DefinitionHeader>) -> Map<&2, DefinitionHeader>:
  native_match_header_insert_0(IndexLookup.find(DefinitionHeader, v_6, v_1), v_1, v_3, v_6)

def value_insert(first: Maybe<&2, Bool>, body: IR.DefBody, key: String, definition: Definition, index: Map<&2, Definition>) -> Map<&2, Definition>:
  match first body:
    case None{} IR.DefTerm{_}: insert_definition(key, definition, index)
    case _ _: index
# A foreign definition retains every declared import alternative, resolved
# against its module and in source order. Targets select by extension from
# these authoritative paths; lowering never chooses one or invents another.
def native_match_foreign_sources_1(v_90: Sigma<&1, &1, Arena.Arena, _ => String>, v_3: String, v_14: U32, v_15: U32, v_22: List<&2, String>) -> CatalogResult<List<&2, String>>:
  match v_90:
    case (v_20, v_21):
      foreign_sources(v_20, IR.Names{IR.arena_range_index(v_14, 1), U32.sub(v_15, 1)}, v_3, Path.resolve(v_3, v_21) <> v_22)

def native_match_foreign_sources_0(v_89: Sigma<&1, &1, Arena.Arena, _ => U32>, v_3: String, v_14: U32, v_15: U32, v_22: List<&2, String>) -> CatalogResult<List<&2, String>>:
  match v_89:
    case (v_17, v_18):
      native_match_foreign_sources_1(Arena.name_text(v_17, v_18), v_3, v_14, v_15, v_22)

def foreign_sources(v_0: Arena.Arena, v_1: IR.Names, v_3: String, v_22: List<&2, String>) -> CatalogResult<List<&2, String>>:
  match v_1:
    case IR.Names{_, 0}:
      CatalogResult{v_0, List.reverse(&2, String, v_22)}
    case IR.Names{v_14, v_15}:
      native_match_foreign_sources_0(Arena.word(v_0, IR.arena_tape_offset(v_14)), v_3, v_14, v_15, v_22)

def foreign_namespace(qualified: String, imported: String) -> String:
  match String.eq(qualified, imported):
    case True{}: ""
    case False{}: String.take(qualified, Nat.sub(String.length(qualified), Nat.add(String.length(imported), 1n)))

def foreign_result_type(source: Arena.Arena, result: IR.OptionalTerm, scope: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  match result:
    case IR.NoTerm{}:
      CatalogResult{source, BIR.DescriptorFailure{"bend: foreign definition has no checked result type"}}
    case IR.SomeTerm{term}:
      descriptor(source, term, scope)

# One descriptor per LIVE parameter, in live order. Erased binders are dropped
# exactly as BIR.Parameter/quantities drop them, so this list aligns with the
# request constructor's [arguments..., continuation] fields.
def live_parameter_types(v_0: Arena.Arena, v_1: IR.Words, v_4: Scope.ArenaGlobalScope, v_22: List<&2, BIR.Descriptor>) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_1:
    case IR.Words{_, 0}:
      CatalogResult{v_0, List.reverse(&2, BIR.Descriptor, v_22)}
    case IR.Words{v_10, v_11}:
      native_match_live_parameter_types_2(Arena.word(v_0, IR.arena_tape_offset(v_10)), v_4, v_22, v_10, v_11)

def native_match_live_parameter_types_2(v_90: Sigma<&1, &1, Arena.Arena, _ => U32>, v_4: Scope.ArenaGlobalScope, v_22: List<&2, BIR.Descriptor>, v_10: U32, v_11: U32) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_90:
    case (v_13, v_14):
      native_match_live_parameter_types_1(Arena.get_binder(v_13, v_14), v_4, v_22, v_10, v_11)

def native_match_live_parameter_types_1(v_89: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_4: Scope.ArenaGlobalScope, v_22: List<&2, BIR.Descriptor>, v_10: U32, v_11: U32) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_89:
    case (v_16, v_17):
      live_parameter_binder(v_16, v_17, v_4, v_22, v_10, v_11)

def live_parameter_binder(v_0: Arena.Arena, v_1: Arena.Binder, v_4: Scope.ArenaGlobalScope, v_22: List<&2, BIR.Descriptor>, v_10: U32, v_11: U32) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_1:
    case Arena.Binder{q, _, _, ty, _}:
      live_parameter_quantity(quantity(q), v_0, ty, v_4, v_22, v_10, v_11)
    case Arena.TemplateBinder{_, _, _, _}:
      live_parameter_types(v_0, IR.Words{IR.arena_range_index(v_10, 1), U32.sub(v_11, 1)}, v_4, v_22)

def live_parameter_quantity(v_1: BIR.Quantity, v_0: Arena.Arena, v_2: U32, v_4: Scope.ArenaGlobalScope, v_22: List<&2, BIR.Descriptor>, v_10: U32, v_11: U32) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match v_1:
    case BIR.Erased{}:
      live_parameter_types(v_0, IR.Words{IR.arena_range_index(v_10, 1), U32.sub(v_11, 1)}, v_4, v_22)
    case _:
      match descriptor(v_0, v_2, v_4):
        case CatalogResult{v_20, v_21}:
          live_parameter_types(v_20, IR.Words{IR.arena_range_index(v_10, 1), U32.sub(v_11, 1)}, v_4, v_21 <> v_22)

def definition_foreign(source: Arena.Arena, body: IR.DefBody, module_path: String, qualified: String, imported: String, span: Ast.SourceSpan, binders: IR.Words, result: IR.OptionalTerm, scope: Scope.ArenaGlobalScope) -> CatalogResult<Maybe<&2, Foreign>>:
  match body:
    case IR.DefTerm{_}:
      CatalogResult{source, None{}}
    case IR.DefImports{paths}:
      match foreign_sources(source, paths, module_path, Nil{}):
        case CatalogResult{source_path, sources}:
          match live_parameter_types(source_path, binders, scope, Nil{}):
            case CatalogResult{source_types, parameter_types}:
              match foreign_result_type(source_types, result, scope):
                case CatalogResult{source_done, result_type}:
                  CatalogResult{source_done, Some{Foreign{foreign_namespace(qualified, imported), imported, sources, span, parameter_types, result_type}}}

def definition_fast(fixed: Bool, type_only: Bool, parameters: List<&2, BIR.Parameter>, primitive: Maybe<&2, BIR.Primitive>, foreign: Maybe<&2, Foreign>) -> Bool:
  match parameters primitive foreign:
    case _ <> _ None{} None{}: Bool.and(fixed, Bool.not(type_only))
    case _ _ _: False{}
def definition_primitive(type_only: Bool, foreign: Maybe<&2, Foreign>, native: Bool, key: String) -> Maybe<&2, BIR.Primitive>:
  match type_only foreign:
    case False{} None{}: primitive(native, key)
    case _ _: None{}
def native_match_main_descriptor_0(v_22: CatalogResult<BIR.Descriptor>) -> CatalogResult<Maybe<&2, BIR.Descriptor>>:
  match v_22:
    case CatalogResult{v_15, v_16}:
      CatalogResult{v_15, Some{v_16}}

def native_match_main_descriptor_1(v_21: Bool, v_3: IR.OptionalTerm, v_0: Arena.Arena, v_4: Scope.ArenaGlobalScope) -> CatalogResult<Maybe<&2, BIR.Descriptor>>:
  match v_21, v_3:
    case True{}, IR.SomeTerm{v_12}:
      native_match_main_descriptor_0(descriptor(v_0, v_12, v_4))
    case _, _:
      CatalogResult{v_0, None{}}

def native_match_main_descriptor_2(v_6: Maybe<&2, BIR.Descriptor>, v_0: Arena.Arena, v_2: String, v_3: IR.OptionalTerm, v_4: Scope.ArenaGlobalScope) -> CatalogResult<Maybe<&2, BIR.Descriptor>>:
  match v_6:
    case Some{_}:
      CatalogResult{v_0, v_6}
    case None{}:
      native_match_main_descriptor_1(String.eq(v_2, "main"), v_3, v_0, v_4)

def main_descriptor(v_0: Arena.Arena, v_2: String, v_3: IR.OptionalTerm, v_4: Scope.ArenaGlobalScope, v_6: Maybe<&2, BIR.Descriptor>) -> CatalogResult<Maybe<&2, BIR.Descriptor>>:
  native_match_main_descriptor_2(v_6, v_0, v_2, v_3, v_4)

def signature_symbol(value: Scope.ArenaGlobal) -> IR.Symbol:
  match value:
    case Scope.ArenaGlobal{_, owner, local, ty, _, Scope.GlobalDefinition{}}: IR.Symbol{owner, local, IR.DefinitionSymbol{}, ty}
    case Scope.ArenaGlobal{_, owner, local, ty, _, Scope.GlobalFamily{}}: IR.Symbol{owner, local, IR.FamilySymbol{}, ty}
    case Scope.ArenaGlobal{_, owner, local, ty, _, Scope.GlobalConstructor{}}: IR.Symbol{owner, local, IR.ConstructorSymbol{}, ty}

def prepare_definition(source: Arena.Arena, definition: IR.Definition, namespace: String, source_path: String, native: Bool, scope: Scope.ArenaGlobalScope, state: Preparation) -> CatalogResult<Preparation>:
  match definition:
    case IR.Definition{key, binders, result, body, _, span, checked, Some{IR.DefinitionFacts{type_only, fixed, prefix}}}:
      prepare_definition_symbol(source, Scope.lookup_kind(qualify(namespace, key), Scope.GlobalDefinition{}, scope), qualify(namespace, key), key, binders, result, body, checked, Bool.and(type_only, is_term(body)), fixed, prefix, source_path, native, scope, state, span)
    case IR.Definition{key, _, _, _, _, _, _, None{}}:
      CatalogResult{source, preparation_failure(state, String.append("bend: missing checked declaration facts for ", qualify(namespace, key)))}
def native_match_prepare_definition_symbol_0(v_95: CatalogResult<Maybe<&2, BIR.Descriptor>>, v_4: String, v_9: IR.DefBody, v_62: List<&2, Definition>, v_63: Map<&2, Definition>, v_64: Map<&2, DefinitionHeader>, v_65: List<&2, BIR.ConstructorLayout>, v_66: Map<&2, Constructor>, v_67: List<&2, BIR.Family>, v_68: U32, v_69: U32, v_72: Maybe<&2, String>, v_73: Map<&2, Bool>, v_76: DefinitionHeader, v_79: Definition, v_86: List<&2, Root>) -> CatalogResult<Preparation>:
  match v_95:
    case CatalogResult{v_88, v_89}:
      v_92 = value_insert(IndexLookup.find(Bool, v_73, v_4), v_9, v_4, v_79, v_63)
      CatalogResult{v_88, Preparation{v_79 <> v_62, v_92, header_insert(v_4, v_76, v_64), v_65, v_66, v_67, U32.add(v_68, 1), v_69, v_86, v_89, v_72, Map.set(&2, Bool, v_73, v_4, True{})}}

def native_match_prepare_definition_symbol_1(v_96: CatalogResult<List<&2, Root>>, v_4: String, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_13: Bool, v_22: Scope.ArenaGlobalScope, v_62: List<&2, Definition>, v_63: Map<&2, Definition>, v_64: Map<&2, DefinitionHeader>, v_65: List<&2, BIR.ConstructorLayout>, v_66: Map<&2, Constructor>, v_67: List<&2, BIR.Family>, v_68: U32, v_69: U32, v_71: Maybe<&2, BIR.Descriptor>, v_72: Maybe<&2, String>, v_73: Map<&2, Bool>, v_76: DefinitionHeader, v_79: Definition) -> CatalogResult<Preparation>:
  match v_96:
    case CatalogResult{v_81, v_82}:
      v_86 = type_root(Bool.and(v_13, is_term(v_9)), v_4, result_roots(v_8, v_22, v_82))
      native_match_prepare_definition_symbol_0(main_descriptor(v_81, v_4, v_8, v_22, v_71), v_4, v_9, v_62, v_63, v_64, v_65, v_66, v_67, v_68, v_69, v_72, v_73, v_76, v_79, v_86)

def native_match_prepare_definition_symbol_2(v_24: Preparation, v_4: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_17: Nat, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_29: Scope.ArenaGlobal, v_36: List<&2, BIR.Parameter>, v_37: List<&2, BIR.Quantity>, v_42: Arena.Arena, v_43: Maybe<&2, Foreign>, v_46: Maybe<&2, BIR.Primitive>, v_49: Bool) -> CatalogResult<Preparation>:
  match v_24:
    case Preparation{v_62, v_63, v_64, v_65, v_66, v_67, v_68, v_69, v_70, v_71, v_72, v_73}:
      v_76 = DefinitionHeader{signature_symbol(v_29), v_4, v_68, v_36, v_37, v_13, v_46, v_43, v_49}
      v_79 = Definition{v_76, v_7, v_8, v_9, v_11, v_22, native_marker(v_21, v_4), v_17}
      native_match_prepare_definition_symbol_1(binder_roots(v_42, v_7, v_22, v_70), v_4, v_8, v_9, v_13, v_22, v_62, v_63, v_64, v_65, v_66, v_67, v_68, v_69, v_71, v_72, v_73, v_76, v_79)

def native_match_prepare_definition_symbol_3(v_97: CatalogResult<Maybe<&2, Foreign>>, v_4: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_15: Bool, v_17: Nat, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_24: Preparation, v_29: Scope.ArenaGlobal, v_36: List<&2, BIR.Parameter>, v_37: List<&2, BIR.Quantity>) -> CatalogResult<Preparation>:
  match v_97:
    case CatalogResult{v_42, v_43}:
      v_46 = definition_primitive(v_13, v_43, v_21, v_4)
      v_49 = definition_fast(v_15, v_13, v_36, v_46, v_43)
      native_match_prepare_definition_symbol_2(v_24, v_4, v_7, v_8, v_9, v_11, v_13, v_17, v_21, v_22, v_29, v_36, v_37, v_42, v_43, v_46, v_49)

def native_match_prepare_definition_symbol_4(v_98: CatalogResult<Telescope>, v_4: String, v_6: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_15: Bool, v_17: Nat, v_19: String, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_24: Preparation, v_29: Scope.ArenaGlobal, v_30: Ast.SourceSpan) -> CatalogResult<Preparation>:
  match v_98:
    case CatalogResult{v_35, Telescope{v_36, v_37, _, _}}:
      native_match_prepare_definition_symbol_3(definition_foreign(v_35, v_9, v_19, v_4, v_6, v_30, v_7, v_8, v_22), v_4, v_7, v_8, v_9, v_11, v_13, v_15, v_17, v_21, v_22, v_24, v_29, v_36, v_37)

def native_match_prepare_definition_symbol_5(v_2: Maybe<&2, Scope.ArenaGlobal>, v_0: Arena.Arena, v_4: String, v_6: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_15: Bool, v_17: Nat, v_19: String, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_24: Preparation, v_30: Ast.SourceSpan) -> CatalogResult<Preparation>:
  match v_2:
    case None{}:
      CatalogResult{v_0, preparation_failure(v_24, String.append("bend: missing published definition signature for ", v_4))}
    case Some{v_29}:
      native_match_prepare_definition_symbol_4(live_telescope(v_0, v_7, 0), v_4, v_6, v_7, v_8, v_9, v_11, v_13, v_15, v_17, v_19, v_21, v_22, v_24, v_29, v_30)

def prepare_definition_symbol(v_0: Arena.Arena, v_2: Maybe<&2, Scope.ArenaGlobal>, v_4: String, v_6: String, v_7: IR.Words, v_8: IR.OptionalTerm, v_9: IR.DefBody, v_11: Maybe<&2, IR.Occurrence>, v_13: Bool, v_15: Bool, v_17: Nat, v_19: String, v_21: Bool, v_22: Scope.ArenaGlobalScope, v_24: Preparation, v_30: Ast.SourceSpan) -> CatalogResult<Preparation>:
  native_match_prepare_definition_symbol_5(v_2, v_0, v_4, v_6, v_7, v_8, v_9, v_11, v_13, v_15, v_17, v_19, v_21, v_22, v_24, v_30)

def is_term(body: IR.DefBody) -> Bool:
  match body:
    case IR.DefTerm{_}: True{}
    case IR.DefImports{_}: False{}
def native_match_prepare_constructors_0(v_79: CatalogResult<Arms>, v_32: List<&2, BIR.DescriptorField>, v_36: String) -> CatalogResult<Arms>:
  match v_79:
    case CatalogResult{v_75, Arms{v_76, v_77}}:
      CatalogResult{v_75, Arms{BIR.DescriptorArm{v_36, v_32} <> v_76, v_77}}

def native_match_prepare_constructors_1(v_80: CatalogResult<List<&2, Root>>, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_23: List<&2, IR.ConstructorDecl>, v_32: List<&2, BIR.DescriptorField>, v_36: String, v_49: List<&2, Definition>, v_50: Map<&2, Definition>, v_51: Map<&2, DefinitionHeader>, v_52: List<&2, BIR.ConstructorLayout>, v_53: Map<&2, Constructor>, v_54: List<&2, BIR.Family>, v_55: U32, v_56: U32, v_58: Maybe<&2, BIR.Descriptor>, v_59: Maybe<&2, String>, v_60: Map<&2, Bool>, v_64: BIR.ConstructorLayout, v_67: Constructor) -> CatalogResult<Arms>:
  match v_80:
    case CatalogResult{v_69, v_70}:
      v_72 = Preparation{v_49, v_50, v_51, v_64 <> v_52, insert_constructor(v_36, v_67, v_53), v_54, v_55, U32.add(v_56, 1), v_70, v_58, v_59, v_60}
      native_match_prepare_constructors_0(prepare_constructors(v_69, v_23, v_4, v_6, v_8, v_10, v_11, v_72), v_32, v_36)

def native_match_prepare_constructors_2(v_13: Preparation, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_21: IR.Words, v_23: List<&2, IR.ConstructorDecl>, v_29: Arena.Arena, v_31: List<&2, BIR.Quantity>, v_32: List<&2, BIR.DescriptorField>, v_36: String) -> CatalogResult<Arms>:
  match v_13:
    case Preparation{v_49, v_50, v_51, v_52, v_53, v_54, v_55, v_56, v_57, v_58, v_59, v_60}:
      v_64 = BIR.ConstructorLayout{v_56, v_36, constructor_native(v_10, v_6, v_36), field_names(v_32)}
      v_67 = Constructor{v_64, v_31, v_8, qualify(v_4, v_6)}
      native_match_prepare_constructors_1(binder_roots(v_29, v_21, v_11, v_57), v_4, v_6, v_8, v_10, v_11, v_23, v_32, v_36, v_49, v_50, v_51, v_52, v_53, v_54, v_55, v_56, v_58, v_59, v_60, v_64, v_67)

def native_match_prepare_constructors_3(v_81: CatalogResult<Telescope>, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_13: Preparation, v_20: String, v_21: IR.Words, v_23: List<&2, IR.ConstructorDecl>) -> CatalogResult<Arms>:
  match v_81:
    case CatalogResult{v_29, Telescope{_, v_31, v_32, _}}:
      v_36 = qualify(v_4, v_20)
      native_match_prepare_constructors_2(v_13, v_4, v_6, v_8, v_10, v_11, v_21, v_23, v_29, v_31, v_32, v_36)

def native_match_prepare_constructors_4(v_2: List<&2, IR.ConstructorDecl>, v_0: Arena.Arena, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_13: Preparation) -> CatalogResult<Arms>:
  match v_2:
    case []:
      CatalogResult{v_0, Arms{[], v_13}}
    case IR.Constructor{v_20, v_21, _} <> v_23:
      native_match_prepare_constructors_3(telescope(v_0, v_21, 0, v_11), v_4, v_6, v_8, v_10, v_11, v_13, v_20, v_21, v_23)

def prepare_constructors(v_0: Arena.Arena, v_2: List<&2, IR.ConstructorDecl>, v_4: String, v_6: String, v_8: Nat, v_10: Bool, v_11: Scope.ArenaGlobalScope, v_13: Preparation) -> CatalogResult<Arms>:
  native_match_prepare_constructors_4(v_2, v_0, v_4, v_6, v_8, v_10, v_11, v_13)

def native_match_prepare_family_0(v_65: CatalogResult<List<&2, Root>>, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_18: String, v_20: U32, v_25: Nat, v_29: List<&2, BIR.DescriptorArm>, v_43: List<&2, Definition>, v_44: Map<&2, Definition>, v_45: Map<&2, DefinitionHeader>, v_46: List<&2, BIR.ConstructorLayout>, v_47: Map<&2, Constructor>, v_48: List<&2, BIR.Family>, v_49: U32, v_50: U32, v_52: Maybe<&2, BIR.Descriptor>, v_53: Maybe<&2, String>, v_54: Map<&2, Bool>, v_57: String) -> CatalogResult<Preparation>:
  match v_65:
    case CatalogResult{v_59, v_60}:
      v_63 = BIR.Family{v_57, v_18, native_marker(v_5, v_18), v_8, v_25, v_29}
      v_64 = Preparation{v_43, v_44, v_45, v_46, v_47, v_63 <> v_48, v_49, v_50, TermRoot{v_20, v_6} <> v_60, v_52, v_53, v_54}
      CatalogResult{v_59, block_family(Scope.lookup_kind(v_57, Scope.GlobalFamily{}, v_6), v_57, v_64)}

def native_match_prepare_family_1(v_30: Preparation, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_18: String, v_19: IR.Words, v_20: U32, v_25: Nat, v_28: Arena.Arena, v_29: List<&2, BIR.DescriptorArm>) -> CatalogResult<Preparation>:
  match v_30:
    case Preparation{v_43, v_44, v_45, v_46, v_47, v_48, v_49, v_50, v_51, v_52, v_53, v_54}:
      v_57 = qualify(v_3, v_18)
      native_match_prepare_family_0(binder_roots(v_28, v_19, v_6, v_51), v_5, v_6, v_8, v_18, v_20, v_25, v_29, v_43, v_44, v_45, v_46, v_47, v_48, v_49, v_50, v_52, v_53, v_54, v_57)

def native_match_prepare_family_2(v_66: CatalogResult<Arms>, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_18: String, v_19: IR.Words, v_20: U32, v_25: Nat) -> CatalogResult<Preparation>:
  match v_66:
    case CatalogResult{v_28, Arms{v_29, v_30}}:
      native_match_prepare_family_1(v_30, v_3, v_5, v_6, v_8, v_18, v_19, v_20, v_25, v_28, v_29)

def native_match_prepare_family_3(v_1: IR.TypeDecl, v_0: Arena.Arena, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_10: Preparation) -> CatalogResult<Preparation>:
  match v_1:
    case IR.TypeDecl{v_18, v_19, v_20, v_21, _}:
      v_25 = words_count(v_19)
      native_match_prepare_family_2(prepare_constructors(v_0, v_21, v_3, v_18, v_25, v_5, v_6, v_10), v_3, v_5, v_6, v_8, v_18, v_19, v_20, v_25)

def prepare_family(v_0: Arena.Arena, v_1: IR.TypeDecl, v_3: String, v_5: Bool, v_6: Scope.ArenaGlobalScope, v_8: Nat, v_10: Preparation) -> CatalogResult<Preparation>:
  native_match_prepare_family_3(v_1, v_0, v_3, v_5, v_6, v_8, v_10)

def words_count(words: IR.Words) -> Nat:
  match words:
    case IR.Words{_, count}: U32.to_nat(count)
def block_family(found: Maybe<&2, Scope.ArenaGlobal>, key: String, state: Preparation) -> Preparation:
  match found state:
    case Some{global} Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, failure, owners}:
      blocked = DefinitionHeader{signature_symbol(global), key, code, Nil{}, Nil{}, True{}, None{}, None{}, False{}}
      Preparation{defs, index, header_insert(key, blocked, headers), ctors, ci, families, code, ctr, roots, main, failure, owners}
    case None{} _:
      preparation_failure(state, String.append("bend: missing published family signature for ", key))
def law_telescope(clauses: List<&2, IR.Clause>, offset: U32) -> Maybe<&2, Telescope>:
  match clauses:
    case Nil{}: Some{Telescope{Nil{}, Nil{}, Nil{}, True{}}}
    case IR.ClauseFor{True{}, q, _, _, None{}, _} <> rest:
      law_telescope_cons(quantity(q), offset, law_telescope(rest, U32.add(offset, 1)))
    case _ <> _: None{}
def law_telescope_cons(q: BIR.Quantity, offset: U32, rest: Maybe<&2, Telescope>) -> Maybe<&2, Telescope>:
  match rest:
    case None{}: None{}
    case Some{Telescope{parameters, quantities, fields, fixed}}:
      Some{Telescope{parameter(offset, q, parameters), q <> quantities, fields, fixed}}
def prepare_law(source: Arena.Arena, declaration: IR.LawDecl, namespace: String, native: Bool, scope: Scope.ArenaGlobalScope, state: Preparation) -> CatalogResult<Preparation>:
  match declaration:
    case IR.LawDecl{local, clauses, body, _}:
      prepare_native_law(source, primitive(native, local), law_telescope(clauses, 0), Scope.lookup_kind(qualify(namespace, local), Scope.GlobalDefinition{}, scope), qualify(namespace, local), body, scope, state)
def prepare_native_law(source: Arena.Arena, primitive: Maybe<&2, BIR.Primitive>, telescope: Maybe<&2, Telescope>, global: Maybe<&2, Scope.ArenaGlobal>, key: String, body: U32, scope: Scope.ArenaGlobalScope, state: Preparation) -> CatalogResult<Preparation>:
  match primitive telescope:
    case None{} _: CatalogResult{source, state}
    case Some{operation} None{}:
      CatalogResult{source, block_family(global, key, state)}
    case Some{operation} Some{Telescope{parameters, quantities, _, _}}:
      match global:
        case None{}: CatalogResult{source, preparation_failure(state, String.append("bend: missing published native law signature for ", key))}
        case Some{global}:
          match state:
            case Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, failure, owners}:
              header = DefinitionHeader{signature_symbol(global), key, code, parameters, quantities, False{}, Some{operation}, None{}, False{}}
              definition = Definition{header, IR.Words{0, 0}, IR.SomeTerm{body}, IR.DefTerm{body}, None{}, scope, Some{key}, 0n}
              CatalogResult{source, Preparation{definition <> defs, index, header_insert(key, header, headers), ctors, ci, families, U32.add(code, 1), ctr, roots, main, failure, owners}}

def family_key(declaration: IR.TypeDecl, namespace: String) -> String:
  match declaration:
    case IR.TypeDecl{local, _, _, _, _}: qualify(namespace, local)
def native_match_prepare_declarations_0(v_11: List<&2, Checked.FamilyMetadata>, v_0: Arena.Arena, v_13: Preparation) -> CatalogResult<Preparation>:
  match v_11:
    case []:
      CatalogResult{v_0, v_13}
    case _ <> _:
      CatalogResult{v_0, preparation_failure(v_13, "bend: unmatched checked family metadata")}

def native_match_prepare_declarations_1(v_54: CatalogResult<Preparation>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_24: List<&2, IR.TopLevel>) -> CatalogResult<Preparation>:
  match v_54:
    case CatalogResult{v_26, v_27}:
      prepare_declarations(v_26, v_24, v_4, v_6, v_8, v_9, v_11, v_27)

def native_match_prepare_declarations_2(v_56: CatalogResult<Preparation>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_32: List<&2, IR.TopLevel>, v_39: List<&2, Checked.FamilyMetadata>) -> CatalogResult<Preparation>:
  match v_56:
    case CatalogResult{v_43, v_44}:
      prepare_declarations(v_43, v_32, v_4, v_6, v_8, v_9, v_39, v_44)

def native_match_prepare_declarations_3(v_55: Bool, v_0: Arena.Arena, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_13: Preparation, v_31: IR.TypeDecl, v_32: List<&2, IR.TopLevel>, v_38: Nat, v_39: List<&2, Checked.FamilyMetadata>) -> CatalogResult<Preparation>:
  match v_55:
    case False{}:
      CatalogResult{v_0, preparation_failure(v_13, "bend: checked family metadata identity mismatch")}
    case True{}:
      native_match_prepare_declarations_2(prepare_family(v_0, v_31, v_4, v_8, v_9, v_38, v_13), v_4, v_6, v_8, v_9, v_32, v_39)

def native_match_prepare_declarations_4(v_11: List<&2, Checked.FamilyMetadata>, v_0: Arena.Arena, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_13: Preparation, v_31: IR.TypeDecl, v_32: List<&2, IR.TopLevel>) -> CatalogResult<Preparation>:
  match v_11:
    case []:
      CatalogResult{v_0, preparation_failure(v_13, "bend: missing checked family metadata")}
    case Checked.FamilyMetadata{v_37, v_38} <> v_39:
      native_match_prepare_declarations_3(String.eq(v_37, family_key(v_31, v_4)), v_0, v_4, v_6, v_8, v_9, v_13, v_31, v_32, v_38, v_39)

def native_match_prepare_declarations_5(v_57: CatalogResult<Preparation>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_49: List<&2, IR.TopLevel>) -> CatalogResult<Preparation>:
  match v_57:
    case CatalogResult{v_51, v_52}:
      prepare_declarations(v_51, v_49, v_4, v_6, v_8, v_9, v_11, v_52)

def native_match_prepare_declarations_6(v_2: List<&2, IR.TopLevel>, v_0: Arena.Arena, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_13: Preparation) -> CatalogResult<Preparation>:
  match v_2:
    case []:
      native_match_prepare_declarations_0(v_11, v_0, v_13)
    case IR.DefTop{v_23} <> v_24:
      native_match_prepare_declarations_1(prepare_definition(v_0, v_23, v_4, v_6, v_8, v_9, v_13), v_4, v_6, v_8, v_9, v_11, v_24)
    case IR.TypeTop{v_31} <> v_32:
      native_match_prepare_declarations_4(v_11, v_0, v_4, v_6, v_8, v_9, v_13, v_31, v_32)
    case IR.LawTop{v_48} <> v_49:
      native_match_prepare_declarations_5(prepare_law(v_0, v_48, v_4, v_8, v_9, v_13), v_4, v_6, v_8, v_9, v_11, v_49)

def prepare_declarations(v_0: Arena.Arena, v_2: List<&2, IR.TopLevel>, v_4: String, v_6: String, v_8: Bool, v_9: Scope.ArenaGlobalScope, v_11: List<&2, Checked.FamilyMetadata>, v_13: Preparation) -> CatalogResult<Preparation>:
  native_match_prepare_declarations_6(v_2, v_0, v_4, v_6, v_8, v_9, v_11, v_13)

def reset_module(state: Preparation) -> Preparation:
  match state:
    case Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, failure, _}:
      Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, failure, MTip{}}
def native_match_prepare_modules_0(v_46: CatalogResult<Preparation>, v_6: Bool, v_25: List<&2, IR.LoadedModule>, v_30: List<&2, Checked.ModuleMetadata>) -> CatalogResult<Preparation>:
  match v_46:
    case CatalogResult{v_35, v_36}:
      prepare_modules(v_35, v_25, v_30, v_6, v_36)

def native_match_prepare_modules_1(v_45: Bool, v_0: Arena.Arena, v_6: Bool, v_8: Preparation, v_21: String, v_22: String, v_24: List<&2, IR.TopLevel>, v_25: List<&2, IR.LoadedModule>, v_28: Scope.ArenaGlobalScope, v_29: List<&2, Checked.FamilyMetadata>, v_30: List<&2, Checked.ModuleMetadata>) -> CatalogResult<Preparation>:
  match v_45:
    case False{}:
      CatalogResult{v_0, preparation_failure(v_8, "bend: checked module metadata identity mismatch")}
    case True{}:
      native_match_prepare_modules_0(prepare_declarations(v_0, v_24, v_21, v_22, base_source(v_22, v_6), v_28, v_29, reset_module(v_8)), v_6, v_25, v_30)

def native_match_prepare_modules_2(v_2: List<&2, IR.LoadedModule>, v_4: List<&2, Checked.ModuleMetadata>, v_0: Arena.Arena, v_6: Bool, v_8: Preparation) -> CatalogResult<Preparation>:
  match v_2, v_4:
    case [], []:
      CatalogResult{v_0, v_8}
    case IR.LoadedModule{v_21, IR.Module{v_22, _, v_24}} <> v_25, Checked.ModuleMetadata{v_26, v_27, v_28, v_29} <> v_30:
      native_match_prepare_modules_1(Bool.and(String.eq(v_21, v_26), String.eq(v_22, v_27)), v_0, v_6, v_8, v_21, v_22, v_24, v_25, v_28, v_29, v_30)
    case _, _:
      CatalogResult{v_0, preparation_failure(v_8, "bend: missing or unmatched checked module metadata")}

def prepare_modules(v_0: Arena.Arena, v_2: List<&2, IR.LoadedModule>, v_4: List<&2, Checked.ModuleMetadata>, v_6: Bool, v_8: Preparation) -> CatalogResult<Preparation>:
  native_match_prepare_modules_2(v_2, v_4, v_0, v_6, v_8)

def ending(requested: Maybe<&2, List<&2, String>>, main: Maybe<&2, BIR.Descriptor>, registry: Registry, v_0: Arena.Arena, definitions: List<&2, Definition>) -> CatalogResult<BIR.Ending>:
  match requested:
    case Some{keys}:
      match exports(keys, registry, v_0, definitions):
        case CatalogResult{v_20, values}: CatalogResult{v_20, BIR.Library{values}}
    case None{}:
      match main:
        case Some{ty}: CatalogResult{v_0, BIR.Executable{ty}}
        case None{}: CatalogResult{v_0, BIR.Executable{BIR.DescriptorNull{}}}
def native_match_build_finish_0(v_74: CatalogResult<Needed>, v_2: List<&2, IR.LoadedModule>, v_4: List<&2, Scope.ArenaGlobal>, v_6: List<&2, Checked.ModuleMetadata>, v_10: Maybe<&2, List<&2, String>>, v_25: List<&2, Definition>, v_27: Map<&2, DefinitionHeader>, v_28: List<&2, BIR.ConstructorLayout>, v_29: Map<&2, Constructor>, v_30: List<&2, BIR.Family>, v_31: U32, v_34: Maybe<&2, BIR.Descriptor>) -> BuildResult:
  match v_74:
    case CatalogResult{v_40, Needed{v_41, _}}:
      v_44 = Registry{v_27, v_29}
      match ending(v_10, v_34, v_44, v_40, v_25):
        case CatalogResult{v_42, v_43}:
          v_48 = Catalog{List.reverse(&2, Definition, v_25), v_44, List.reverse(&2, BIR.ConstructorLayout, v_28), List.reverse(&2, BIR.Family, v_30), v_41, v_31, v_43}
          Built{Checked.CheckedProgram{v_42, v_2, v_4, v_6}, v_48}

def native_match_build_finish_1(v_12: Preparation, v_0: Arena.Arena, v_2: List<&2, IR.LoadedModule>, v_4: List<&2, Scope.ArenaGlobal>, v_6: List<&2, Checked.ModuleMetadata>, v_10: Maybe<&2, List<&2, String>>) -> BuildResult:
  match v_12:
    case Preparation{v_25, v_26, v_27, v_28, v_29, v_30, v_31, _, v_33, v_34, None{}, _}:
      native_match_build_finish_0(needed_roots(v_0, List.reverse(&2, Root, v_33), v_26, Needed{[], MTip{}}), v_2, v_4, v_6, v_10, v_25, v_27, v_28, v_29, v_30, v_31, v_34)
    case Preparation{_, _, _, _, _, _, _, _, _, _, Some{v_71}, _}:
      BuildFailure{Checked.CheckedProgram{v_0, v_2, v_4, v_6}, v_71}

def build_finish(v_0: Arena.Arena, v_2: List<&2, IR.LoadedModule>, v_4: List<&2, Scope.ArenaGlobal>, v_6: List<&2, Checked.ModuleMetadata>, v_10: Maybe<&2, List<&2, String>>, v_12: Preparation) -> BuildResult:
  native_match_build_finish_1(v_12, v_0, v_2, v_4, v_6, v_10)

def native_match_build_0(v_21: CatalogResult<Preparation>, v_4: Maybe<&2, List<&2, String>>, v_11: List<&2, IR.LoadedModule>, v_12: List<&2, Scope.ArenaGlobal>, v_13: List<&2, Checked.ModuleMetadata>) -> BuildResult:
  match v_21:
    case CatalogResult{v_19, v_20}:
      build_finish(v_19, v_11, v_12, v_13, v_4, v_20)

def native_match_build_1(v_0: Checked.CheckedProgram, v_4: Maybe<&2, List<&2, String>>) -> BuildResult:
  match v_0:
    case Checked.CheckedProgram{v_10, v_11, v_12, v_13}:
      v_15 = Preparation{[], MTip{}, MTip{}, [], MTip{}, [], 0, 0, [], None{}, None{}, MTip{}}
      native_match_build_0(prepare_modules(v_10, v_11, v_13, base_imported(v_11), v_15), v_4, v_11, v_12, v_13)

def build(v_0: Checked.CheckedProgram, v_4: Maybe<&2, List<&2, String>>) -> BuildResult:
  native_match_build_1(v_0, v_4)

def native_match_live_telescope_0(v_88: CatalogResult<Telescope>, v_3: U32, v_17: Arena.Binder) -> CatalogResult<Telescope>:
  match v_88:
    case CatalogResult{v_20, v_21}:
      CatalogResult{v_20, live_binder(v_17, v_3, v_21)}

def native_match_live_telescope_1(v_89: Sigma<&1, &1, Arena.Arena, _ => Arena.Binder>, v_3: U32, v_10: U32, v_11: U32) -> CatalogResult<Telescope>:
  match v_89:
    case (v_16, v_17):
      native_match_live_telescope_0(live_telescope(v_16, IR.Words{IR.arena_range_index(v_10, 1), U32.sub(v_11, 1)}, U32.add(v_3, 1)), v_3, v_17)

def native_match_live_telescope_2(v_90: Sigma<&1, &1, Arena.Arena, _ => U32>, v_3: U32, v_10: U32, v_11: U32) -> CatalogResult<Telescope>:
  match v_90:
    case (v_13, v_14):
      native_match_live_telescope_1(Arena.get_binder(v_13, v_14), v_3, v_10, v_11)

def native_match_live_telescope_3(v_1: IR.Words, v_0: Arena.Arena, v_3: U32) -> CatalogResult<Telescope>:
  match v_1:
    case IR.Words{_, 0}:
      CatalogResult{v_0, Telescope{[], [], [], True{}}}
    case IR.Words{v_10, v_11}:
      native_match_live_telescope_2(Arena.word(v_0, IR.arena_tape_offset(v_10)), v_3, v_10, v_11)

def live_telescope(v_0: Arena.Arena, v_1: IR.Words, v_3: U32) -> CatalogResult<Telescope>:
  native_match_live_telescope_3(v_1, v_0, v_3)

def live_binder(binder: Arena.Binder, offset: U32, rest: Telescope) -> Telescope:
  match binder rest:
    case Arena.Binder{q, _, _, _, _} Telescope{parameters, quantities, fields, fixed}:
      q = quantity(q)
      Telescope{parameter(offset, q, parameters), q <> quantities, fields, fixed}
    case Arena.TemplateBinder{_, _, _, _} Telescope{parameters, quantities, fields, _}:
      Telescope{parameters, BIR.Erased{} <> quantities, fields, False{}}

def primitive_arity(value: BIR.Primitive) -> Nat:
  match value:
    case BIR.PrimU32Add{}: 2n
    case BIR.PrimU32Sub{}: 2n
    case BIR.PrimU32Mul{}: 2n
    case BIR.PrimU32Div{}: 2n
    case BIR.PrimNatAdd{}: 2n
    case BIR.PrimNatSub{}: 2n
    case BIR.PrimNatMul{}: 2n
    case BIR.PrimNatCmp{}: 2n
    case BIR.PrimNatMin{}: 2n
    case BIR.PrimNatMax{}: 2n
    case BIR.PrimStringAppend{}: 2n
    case BIR.PrimBoolOr{}: 2n
    case BIR.PrimBoolXor{}: 2n
    case BIR.PrimU32IsZero{}: 1n
    case BIR.PrimF32Asin{}: 1n
    case BIR.PrimF32Acos{}: 1n
    case BIR.PrimF32Atan{}: 1n
    case BIR.PrimF32Sinh{}: 1n
    case BIR.PrimF32Cosh{}: 1n
    case BIR.PrimF32Tanh{}: 1n
    case BIR.PrimU32Mod{}: 2n
    case BIR.PrimU32And{}: 2n
    case BIR.PrimU32Or{}: 2n
    case BIR.PrimU32Xor{}: 2n
    case BIR.PrimU32IsEq{}: 2n
    case BIR.PrimU32IsNe{}: 2n
    case BIR.PrimU32IsLt{}: 2n
    case BIR.PrimU32IsLe{}: 2n
    case BIR.PrimU32IsGt{}: 2n
    case BIR.PrimU32IsGe{}: 2n
    case BIR.PrimU32Inc{}: 1n
    case BIR.PrimU32Not{}: 1n
    case BIR.PrimU32Shl{}: 1n
    case BIR.PrimU32Shr{}: 1n
    case BIR.PrimU32Shln{}: 2n
    case BIR.PrimU32Shrn{}: 2n
    case BIR.PrimU32Cmp{}: 2n
    case BIR.PrimU32ToNat{}: 1n
    case BIR.PrimU32FromNat{}: 1n
    case BIR.PrimF32Add{}: 2n
    case BIR.PrimF32Sub{}: 2n
    case BIR.PrimF32Mul{}: 2n
    case BIR.PrimF32Div{}: 2n
    case BIR.PrimF32Mod{}: 2n
    case BIR.PrimF32Neg{}: 1n
    case BIR.PrimF32Sqrt{}: 1n
    case BIR.PrimF32Abs{}: 1n
    case BIR.PrimF32ToU32{}: 1n
    case BIR.PrimF32Bits{}: 1n
    case BIR.PrimF32Show{}: 1n
    case BIR.PrimF32Read{}: 1n
    case BIR.PrimF32IsEq{}: 2n
    case BIR.PrimF32IsNe{}: 2n
    case BIR.PrimF32IsLt{}: 2n
    case BIR.PrimF32IsLe{}: 2n
    case BIR.PrimF32IsGt{}: 2n
    case BIR.PrimF32IsGe{}: 2n
    case BIR.PrimF32Pow{}: 2n
    case BIR.PrimF32Atan2{}: 2n
    case BIR.PrimF32Exp{}: 1n
    case BIR.PrimF32Log{}: 1n
    case BIR.PrimF32Log2{}: 1n
    case BIR.PrimF32Log10{}: 1n
    case BIR.PrimF32Sin{}: 1n
    case BIR.PrimF32Cos{}: 1n
    case BIR.PrimF32Tan{}: 1n
    case BIR.PrimF32Floor{}: 1n
    case BIR.PrimF32Ceil{}: 1n
    case BIR.PrimF32Trunc{}: 1n
    case BIR.PrimF32ToNat{}: 1n
    case BIR.PrimU32ToF32{}: 1n
    case BIR.PrimNatDouble{}: 1n
    case BIR.PrimNatIsLt{}: 2n
    case BIR.PrimNatDivmod{}: 2n
    case BIR.PrimStringEq{}: 2n
    case BIR.PrimMapBit{}: 2n
    case BIR.PrimStringCmp{}: 2n
    case BIR.PrimStringToList{}: 1n
    case BIR.PrimStringLength{}: 1n
    case BIR.PrimArrayNew{}: 2n
    case BIR.PrimArraySet{}: 3n
    case BIR.PrimArrayGet{}: 2n
    case BIR.PrimArraySwap{}: 3n
    case BIR.PrimArraySize{}: 1n
    case BIR.PrimArrayClone{}: 1n
    case BIR.PrimNatPredecessor{}: 1n
    case BIR.PrimNatSuccessor{}: 1n
    case BIR.PrimCharNew{}: 1n
    case BIR.PrimCharCode{}: 1n
    case BIR.PrimStringHead{}: 1n
    case BIR.PrimStringTail{}: 1n
    case BIR.PrimWordToU32{}: 1n
    case BIR.PrimU32ToWord{}: 1n
    case BIR.PrimF32FromBits{}: 1n
    case BIR.PrimF32FromWord{}: 1n
    case BIR.PrimF32ToWord{}: 1n
    case BIR.PrimArrayLeaf{}: 1n
    case BIR.PrimArrayNode{}: 2n
    case BIR.PrimArrayLeafValue{}: 1n
    case BIR.PrimArrayLeft{}: 1n
    case BIR.PrimArrayRight{}: 1n
    case BIR.PrimIsArrayLeaf{}: 1n
    case BIR.PrimIsArrayNode{}: 1n
    case BIR.PrimIsNatZero{}: 1n
    case BIR.PrimIsNatSuccessor{}: 1n
    case BIR.PrimIsStringEmpty{}: 1n
    case BIR.PrimIsStringNonempty{}: 1n
    case BIR.PrimIsTrue{}: 1n
    case BIR.PrimIsFalse{}: 1n
    case BIR.PrimSameValue{}: 2n
    case BIR.PrimFloatBitsEqual{}: 2n

def constructor_field(constructor: Constructor, identity: U32) -> Maybe<&2, ConstructorField>:
  match constructor:
    case Constructor{BIR.ConstructorLayout{_, _, _, fields}, quantities, _, _}:
      constructor_field_at(fields, quantities, U32.to_nat(identity), identity)
def constructor_field_at(fields: List<&2, Maybe<&2, String>>, quantities: List<&2, BIR.Quantity>, remaining: Nat, identity: U32) -> Maybe<&2, ConstructorField>:
  match fields quantities remaining:
    case key <> _ q <> _ 0n: Some{ConstructorField{identity, key, q}}
    case _ <> rest _ <> more 1n+next: constructor_field_at(rest, more, next, identity)
    case _ _ _: None{}
