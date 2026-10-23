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
  Foreign{path: String, key: String, arity: Nat}
  ForeignMissing{key: String, arity: Nat}
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

def descriptor(source: Arena.Arena, id: U32, scope: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  Tuple{source, node} = Arena.get_node(source, id)
  descriptor_node(source, node, scope)
def descriptor_name(source: Arena.Arena, id: U32, scope: Scope.ArenaGlobalScope, constructor: Bool) -> CatalogResult<String>:
  Tuple{source, key} = Arena.name_text(source, id)
  CatalogResult{source, canonical(key, scope, constructor)}
def descriptors(source: Arena.Arena, start: U32, count: U32, scope: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match count:
    case 0: CatalogResult{source, Nil{}}
    case _:
      Tuple{source, id} = Arena.word(source, IR.arena_tape_offset(start))
      CatalogResult{source, item} = descriptor(source, id, scope)
      CatalogResult{source, rest} = descriptors(source, IR.arena_range_index(start, 1), U32.sub(count, 1), scope)
      CatalogResult{source, item <> rest}
def descriptor_patterns(source: Arena.Arena, start: U32, count: U32, scope: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.DescriptorPattern>>:
  match count:
    case 0: CatalogResult{source, Nil{}}
    case _:
      Tuple{source, id} = Arena.word(source, IR.arena_tape_offset(start))
      Tuple{source, pattern} = Arena.get_pattern(source, id)
      CatalogResult{source, item} = descriptor_pattern(source, pattern, scope)
      CatalogResult{source, rest} = descriptor_patterns(source, IR.arena_range_index(start, 1), U32.sub(count, 1), scope)
      CatalogResult{source, item <> rest}
def descriptor_pattern(source: Arena.Arena, pattern: Arena.Pattern, scope: Scope.ArenaGlobalScope) -> CatalogResult<BIR.DescriptorPattern>:
  match pattern:
    case Arena.PatternVar{_, _, q, _}: CatalogResult{source, BIR.DescriptorBinder{quantity(q)}}
    case Arena.PatternCtr{key, start, count, _}:
      CatalogResult{source, name} = descriptor_name(source, key, scope, True{})
      CatalogResult{source, fields} = descriptor_patterns(source, start, count, scope)
      CatalogResult{source, BIR.DescriptorConstructorPattern{name, fields}}
def descriptor_apply(fn: BIR.Descriptor, arg: BIR.Descriptor) -> BIR.Descriptor:
  match fn:
    case BIR.DescriptorRef{key, args}: BIR.DescriptorRef{key, List.append(&2, BIR.Descriptor, args, [arg])}
    case _: BIR.DescriptorApplication{fn, arg}
def descriptor_sugar(source: Arena.Arena, head: U32, args: List<&2, BIR.Descriptor>, plus: Bool, scope: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  Tuple{source, node} = Arena.get_node(source, head)
  match node:
    case Arena.TermAnn{inner, _, _}: descriptor_sugar(source, inner, args, plus, scope)
    case Arena.TermBang{inner, _}: descriptor_sugar(source, inner, args, plus, scope)
    case Arena.TermApp{fn, arg, _}:
      CatalogResult{source, arg} = descriptor(source, arg, scope)
      descriptor_sugar(source, fn, arg <> args, plus, scope)
    case Arena.TermRef{key, _}:
      CatalogResult{source, key} = descriptor_name(source, key, scope, False{})
      CatalogResult{source, named_sugar(key, BIR.DescriptorRef{key, Nil{}}, args, plus)}
    case Arena.TermAdt{key, start, count, _, _, _}:
      CatalogResult{source, key} = descriptor_name(source, key, scope, False{})
      CatalogResult{source, old} = descriptors(source, start, count, scope)
      CatalogResult{source, named_sugar(key, BIR.DescriptorRef{key, old}, List.append(&2, BIR.Descriptor, old, args), plus)}
    case _:
      CatalogResult{source, head} = descriptor_node(source, node, scope)
      CatalogResult{source, unnamed_sugar(head, args, plus)}
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
def descriptor_node(source: Arena.Arena, node: Arena.Node, scope: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  match node:
    case Arena.TermVar{_, index, _}: CatalogResult{source, BIR.DescriptorParameter{index}}
    case Arena.TermRef{key, _}:
      CatalogResult{source, name} = descriptor_name(source, key, scope, False{})
      CatalogResult{source, BIR.DescriptorRef{name, Nil{}}}
    case Arena.TermBang{inner, _}: descriptor(source, inner, scope)
    case Arena.TermSub{index, value, body, _}:
      CatalogResult{source, value} = descriptor(source, value, scope)
      CatalogResult{source, body} = descriptor(source, body, scope)
      CatalogResult{source, BIR.DescriptorSubstitution{index, value, body}}
    case Arena.TermLet{_, _, _, _, _, _, start, count, body, _}:
      CatalogResult{source, values} = descriptors(source, start, count, scope)
      CatalogResult{source, body} = descriptor(source, body, scope)
      CatalogResult{source, BIR.DescriptorLet{values, body}}
    case Arena.TermAnn{inner, _, _}: descriptor(source, inner, scope)
    case Arena.TermTemplate{_, _}: CatalogResult{source, BIR.DescriptorFailure{"bend: unexpanded template"}}
    case Arena.TermType{kind, _}:
      CatalogResult{source, kind} = descriptor(source, kind, scope)
      CatalogResult{source, BIR.DescriptorKind{kind}}
    case Arena.TermQuant{}: CatalogResult{source, BIR.DescriptorQuantityKind{}}
    case Arena.TermQuantity{value, _}: CatalogResult{source, BIR.DescriptorQuantity{quantity(value)}}
    case Arena.TermMin{left, right, _}:
      CatalogResult{source, left} = descriptor(source, left, scope)
      CatalogResult{source, right} = descriptor(source, right, scope)
      CatalogResult{source, BIR.DescriptorMinimum{left, right}}
    case Arena.TermAll{q, _, _, domain, body, _}:
      CatalogResult{source, domain} = descriptor(source, domain, scope)
      CatalogResult{source, body} = descriptor(source, body, scope)
      CatalogResult{source, BIR.DescriptorArrow{quantity(q), domain, body}}
    case Arena.TermLam{q, _, _, body, _}:
      CatalogResult{source, body} = descriptor(source, body, scope)
      CatalogResult{source, BIR.DescriptorLambda{optional_quantity(q), body}}
    case Arena.TermApp{fn, arg, _}:
      CatalogResult{source, fn} = descriptor(source, fn, scope)
      CatalogResult{source, arg} = descriptor(source, arg, scope)
      CatalogResult{source, descriptor_apply(fn, arg)}
    case Arena.TermAdt{key, start, count, _, _, _}:
      CatalogResult{source, key} = descriptor_name(source, key, scope, False{})
      CatalogResult{source, args} = descriptors(source, start, count, scope)
      CatalogResult{source, BIR.DescriptorRef{key, args}}
    case Arena.TermFill{head, start, count, _}:
      CatalogResult{source, args} = descriptors(source, start, count, scope)
      descriptor_sugar(source, head, args, False{}, scope)
    case Arena.TermPlus{head, start, count, _}:
      CatalogResult{source, args} = descriptors(source, start, count, scope)
      descriptor_sugar(source, head, args, True{}, scope)
    case Arena.TermCtr{key, start, count, _}:
      CatalogResult{source, key} = descriptor_name(source, key, scope, True{})
      CatalogResult{source, args} = descriptors(source, start, count, scope)
      CatalogResult{source, BIR.DescriptorConstructor{key, args}}
    case Arena.TermString{chars, names, _}: CatalogResult{source, string_descriptor(chars, string_names(names, scope))}
    case Arena.TermMat{_, head, value, _}:
      CatalogResult{source, value} = descriptor(source, value, scope)
      CatalogResult{source, head} = descriptor(source, head, scope)
      CatalogResult{source, BIR.DescriptorBind{value, head}}
    case Arena.TermAbsurd{_}: CatalogResult{source, BIR.DescriptorFailure{"bend: runtime fail-stop"}}
    case Arena.TermEqual{left, right, ty, _}:
      CatalogResult{source, left} = descriptor(source, left, scope)
      CatalogResult{source, right} = descriptor(source, right, scope)
      CatalogResult{source, ty} = descriptor(source, ty, scope)
      CatalogResult{source, BIR.DescriptorEquality{left, right, ty}}
    case Arena.TermRefl{_}: CatalogResult{source, BIR.DescriptorReflexivity{}}
    case Arena.TermRewrite{_, _, body, _}: descriptor(source, body, scope)
    case Arena.TermHole{key, _}:
      Tuple{source, key} = Arena.name_text(source, key)
      CatalogResult{source, BIR.DescriptorFailure{String.append("bend: unsolved hole ", key)}}
    case Arena.BodyMatch{start, count, cases_start, cases_count, _}:
      CatalogResult{source, values} = descriptors(source, start, count, scope)
      CatalogResult{source, cases} = descriptor_cases(source, cases_start, cases_count, scope)
      CatalogResult{source, BIR.DescriptorMatch{values, cases}}
    case Arena.BodyCase{_, _, body, _}: descriptor(source, body, scope)
    case Arena.BodyLocal{start, count, _, values_start, values_count, body, _}:
      CatalogResult{source, patterns} = descriptor_patterns(source, start, count, scope)
      CatalogResult{source, values} = descriptors(source, values_start, values_count, scope)
      CatalogResult{source, body} = descriptor(source, body, scope)
      CatalogResult{source, BIR.DescriptorLocal{patterns, values, body}}
    case Arena.BodyReply{inner, _}: descriptor(source, inner, scope)

def descriptor_cases(source: Arena.Arena, start: U32, count: U32, scope: Scope.ArenaGlobalScope) -> CatalogResult<List<&2, BIR.Descriptor>>:
  match count:
    case 0: CatalogResult{source, Nil{}}
    case _:
      Tuple{source, id} = Arena.word(source, IR.arena_tape_offset(start))
      Tuple{source, node} = Arena.get_node(source, id)
      CatalogResult{source, entry} = descriptor_case(source, node, scope)
      CatalogResult{source, rest} = descriptor_cases(source, IR.arena_range_index(start, 1), U32.sub(count, 1), scope)
      CatalogResult{source, entry <> rest}
def descriptor_case(source: Arena.Arena, node: Arena.Node, scope: Scope.ArenaGlobalScope) -> CatalogResult<BIR.Descriptor>:
  match node:
    case Arena.BodyCase{start, count, body, _}:
      CatalogResult{source, patterns} = descriptor_patterns(source, start, count, scope)
      CatalogResult{source, body} = descriptor(source, body, scope)
      CatalogResult{source, BIR.DescriptorCase{patterns, body}}
    case _: CatalogResult{source, BIR.DescriptorFailure{"bend: malformed type match"}}

def telescope(source: Arena.Arena, words: IR.Words, offset: U32, scope: Scope.ArenaGlobalScope) -> CatalogResult<Telescope>:
  match words:
    case IR.Words{start, 0}: CatalogResult{source, Telescope{Nil{}, Nil{}, Nil{}, True{}}}
    case IR.Words{start, count}:
      Tuple{source, id} = Arena.word(source, IR.arena_tape_offset(start))
      Tuple{source, binder} = Arena.get_binder(source, id)
      CatalogResult{source, rest} = telescope(source, IR.Words{IR.arena_range_index(start, 1), U32.sub(count, 1)}, U32.add(offset, 1), scope)
      telescope_binder(source, binder, offset, scope, rest)
def telescope_binder(source: Arena.Arena, binder: Arena.Binder, offset: U32, scope: Scope.ArenaGlobalScope, rest: Telescope) -> CatalogResult<Telescope>:
  match binder rest:
    case Arena.Binder{q, key, _, ty, _} Telescope{parameters, quantities, fields, fixed}:
      Tuple{source, key} = Arena.name_text(source, key)
      CatalogResult{source, ty} = descriptor(source, ty, scope)
      q = quantity(q)
      CatalogResult{source, Telescope{parameter(offset, q, parameters), q <> quantities, BIR.DescriptorField{field_key(key, q), q, ty} <> fields, fixed}}
    case Arena.TemplateBinder{_, _, ty, _} Telescope{parameters, quantities, fields, _}:
      CatalogResult{source, ty} = descriptor(source, ty, scope)
      CatalogResult{source, Telescope{parameters, BIR.Erased{} <> quantities, BIR.DescriptorField{None{}, BIR.Erased{}, ty} <> fields, False{}}}
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
def insert_definition(+key: String, value: Definition, +index: Map<&2, Definition>) -> Map<&2, Definition>:
  match IndexLookup.find(Definition, index, key):
    case Some{_}: index
    case None{}: Map.set(&2, Definition, index, key, value)
def insert_constructor(+key: String, value: Constructor, +index: Map<&2, Constructor>) -> Map<&2, Constructor>:
  match IndexLookup.find(Constructor, index, key):
    case Some{_}: index
    case None{}: Map.set(&2, Constructor, index, key, value)
def export_entry(value: Maybe<&2, DefinitionHeader>) -> Maybe<&2, BIR.Entry>:
  match value:
    case Some{DefinitionHeader{_, _, code, parameters, _, _, _, _, True{}}}:
      Some{BIR.Entry{code, List.length(&2, BIR.Parameter, parameters)}}
    case _: None{}
def exports(keys: List<&2, String>, registry: Registry) -> List<&2, BIR.Export>:
  match keys:
    case Nil{}: Nil{}
    case key <> rest: BIR.Export{key, export_entry(definition_key(registry, key))} <> exports(rest, registry)

# Reachability is a visited-set walk, not reduction and not fuel-bounded.
# Register before traversing a body so recursive descriptor functions terminate.
def needed_ref(source: Arena.Arena, key: String, index: Map<&2, Definition>, needed: Needed) -> CatalogResult<Needed>:
  match needed:
    case Needed{functions, seen}:
      match IndexLookup.find(Bool, seen, key):
        case Some{_}: CatalogResult{source, needed}
        case None{}: needed_definition(source, IndexLookup.find(Definition, index, key), index, functions, Map.set(&2, Bool, seen, key, True{}))
def needed_definition(source: Arena.Arena, found: Maybe<&2, Definition>, index: Map<&2, Definition>, functions: List<&2, BIR.TypeFunction>, seen: Map<&2, Bool>) -> CatalogResult<Needed>:
  match found:
    case Some{Definition{DefinitionHeader{_, key, _, _, quantities, _, _, None{}, _}, _, _, IR.DefTerm{body}, _, scope, native, prefix}}:
      CatalogResult{source, value} = descriptor(source, body, scope)
      entry = BIR.TypeFunction{key, native, prefix, List.length(&2, BIR.Quantity, quantities), value}
      needed_term(source, body, scope, index, Needed{entry <> functions, seen})
    case _: CatalogResult{source, Needed{functions, seen}}
def needed_terms(source: Arena.Arena, start: U32, count: U32, scope: Scope.ArenaGlobalScope, index: Map<&2, Definition>, needed: Needed) -> CatalogResult<Needed>:
  match count:
    case 0: CatalogResult{source, needed}
    case _:
      Tuple{source, term} = Arena.word(source, IR.arena_tape_offset(start))
      CatalogResult{source, needed} = needed_term(source, term, scope, index, needed)
      needed_terms(source, IR.arena_range_index(start, 1), U32.sub(count, 1), scope, index, needed)
def needed_pair(source: Arena.Arena, first: U32, second: U32, scope: Scope.ArenaGlobalScope, index: Map<&2, Definition>, needed: Needed) -> CatalogResult<Needed>:
  CatalogResult{source, needed} = needed_term(source, first, scope, index, needed)
  needed_term(source, second, scope, index, needed)
def needed_term(source: Arena.Arena, term: U32, scope: Scope.ArenaGlobalScope, index: Map<&2, Definition>, needed: Needed) -> CatalogResult<Needed>:
  Tuple{source, node} = Arena.get_node(source, term)
  match node:
    case Arena.TermRef{key, _}:
      CatalogResult{source, key} = descriptor_name(source, key, scope, False{})
      needed_ref(source, key, index, needed)
    case Arena.TermBang{inner, _}: needed_term(source, inner, scope, index, needed)
    case Arena.TermSub{_, value, body, _}: needed_pair(source, value, body, scope, index, needed)
    case Arena.TermLet{_, _, _, _, _, _, start, count, body, _}:
      CatalogResult{source, needed} = needed_terms(source, start, count, scope, index, needed)
      needed_term(source, body, scope, index, needed)
    case Arena.TermAnn{inner, ty, _}: needed_pair(source, inner, ty, scope, index, needed)
    case Arena.TermType{kind, _}: needed_term(source, kind, scope, index, needed)
    case Arena.TermMin{left, right, _}: needed_pair(source, left, right, scope, index, needed)
    case Arena.TermAll{_, _, _, domain, body, _}: needed_pair(source, domain, body, scope, index, needed)
    case Arena.TermLam{_, _, _, body, _}: needed_term(source, body, scope, index, needed)
    case Arena.TermApp{fn, arg, _}: needed_pair(source, fn, arg, scope, index, needed)
    case Arena.TermAdt{_, start, count, _, _, _}: needed_terms(source, start, count, scope, index, needed)
    case Arena.TermFill{head, start, count, _}:
      CatalogResult{source, needed} = needed_terms(source, start, count, scope, index, needed)
      needed_term(source, head, scope, index, needed)
    case Arena.TermPlus{head, start, count, _}:
      CatalogResult{source, needed} = needed_terms(source, start, count, scope, index, needed)
      needed_term(source, head, scope, index, needed)
    case Arena.TermCtr{_, start, count, _}: needed_terms(source, start, count, scope, index, needed)
    case Arena.TermMat{_, head, matched, _}: needed_pair(source, head, matched, scope, index, needed)
    case Arena.TermEqual{_, _, ty, _}: needed_term(source, ty, scope, index, needed)
    case Arena.TermRewrite{_, _, body, _}: needed_term(source, body, scope, index, needed)
    case Arena.BodyMatch{start, count, cases_start, cases_count, _}:
      CatalogResult{source, needed} = needed_terms(source, start, count, scope, index, needed)
      needed_terms(source, cases_start, cases_count, scope, index, needed)
    case Arena.BodyCase{_, _, body, _}: needed_term(source, body, scope, index, needed)
    case Arena.BodyLocal{_, _, _, start, count, body, _}:
      CatalogResult{source, needed} = needed_terms(source, start, count, scope, index, needed)
      needed_term(source, body, scope, index, needed)
    case Arena.BodyReply{inner, _}: needed_term(source, inner, scope, index, needed)
    case Arena.TermVar{_, _, _}: CatalogResult{source, needed}
    case Arena.TermTemplate{_, _}: CatalogResult{source, needed}
    case Arena.TermQuant{}: CatalogResult{source, needed}
    case Arena.TermQuantity{_, _}: CatalogResult{source, needed}
    case Arena.TermString{_, _, _}: CatalogResult{source, needed}
    case Arena.TermAbsurd{_}: CatalogResult{source, needed}
    case Arena.TermRefl{_}: CatalogResult{source, needed}
    case Arena.TermHole{_, _}: CatalogResult{source, needed}
def needed_roots(source: Arena.Arena, roots: List<&2, Root>, index: Map<&2, Definition>, needed: Needed) -> CatalogResult<Needed>:
  match roots:
    case Nil{}: CatalogResult{source, needed}
    case TermRoot{term, scope} <> rest:
      CatalogResult{source, needed} = needed_term(source, term, scope, index, needed)
      needed_roots(source, rest, index, needed)
    case DefinitionRoot{key} <> rest:
      CatalogResult{source, needed} = needed_ref(source, key, index, needed)
      needed_roots(source, rest, index, needed)
def binder_roots(source: Arena.Arena, words: IR.Words, scope: Scope.ArenaGlobalScope, roots: List<&2, Root>) -> CatalogResult<List<&2, Root>>:
  match words:
    case IR.Words{_, 0}: CatalogResult{source, roots}
    case IR.Words{start, count}:
      Tuple{source, id} = Arena.word(source, IR.arena_tape_offset(start))
      Tuple{source, binder} = Arena.get_binder(source, id)
      binder_roots(source, IR.Words{IR.arena_range_index(start, 1), U32.sub(count, 1)}, scope, TermRoot{binder_type(binder), scope} <> roots)
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
def header_insert(+key: String, header: DefinitionHeader, +headers: Map<&2, DefinitionHeader>) -> Map<&2, DefinitionHeader>:
  match IndexLookup.find(DefinitionHeader, headers, key):
    case Some{_}: headers
    case None{}: Map.set(&2, DefinitionHeader, headers, key, header)
def value_insert(first: Maybe<&2, Bool>, body: IR.DefBody, key: String, definition: Definition, index: Map<&2, Definition>) -> Map<&2, Definition>:
  match first body:
    case None{} IR.DefTerm{_}: insert_definition(key, definition, index)
    case _ _: index
def foreign_path(source: Arena.Arena, paths: IR.Names, source_path: String, key: String, arity: Nat) -> CatalogResult<Foreign>:
  match paths:
    case IR.Names{_, 0}: CatalogResult{source, ForeignMissing{key, arity}}
    case IR.Names{start, count}:
      Tuple{source, name} = Arena.word(source, IR.arena_tape_offset(start))
      Tuple{source, path} = Arena.name_text(source, name)
      match String.ends_with(path, ".js"):
        case True{}: CatalogResult{source, Foreign{Path.resolve(source_path, path), key, arity}}
        case False{}: foreign_path(source, IR.Names{IR.arena_range_index(start, 1), U32.sub(count, 1)}, source_path, key, arity)
def definition_foreign(source: Arena.Arena, body: IR.DefBody, source_path: String, key: String, arity: Nat) -> CatalogResult<Maybe<&2, Foreign>>:
  match body:
    case IR.DefTerm{_}: CatalogResult{source, None{}}
    case IR.DefImports{paths}:
      CatalogResult{source, value} = foreign_path(source, paths, source_path, key, arity)
      CatalogResult{source, Some{value}}
def definition_fast(fixed: Bool, type_only: Bool, parameters: List<&2, BIR.Parameter>, primitive: Maybe<&2, BIR.Primitive>, foreign: Maybe<&2, Foreign>) -> Bool:
  match parameters primitive foreign:
    case _ <> _ None{} None{}: Bool.and(fixed, Bool.not(type_only))
    case _ _ _: False{}
def definition_primitive(type_only: Bool, foreign: Maybe<&2, Foreign>, native: Bool, key: String) -> Maybe<&2, BIR.Primitive>:
  match type_only foreign:
    case False{} None{}: primitive(native, key)
    case _ _: None{}
def main_descriptor(source: Arena.Arena, key: String, result: IR.OptionalTerm, scope: Scope.ArenaGlobalScope, old: Maybe<&2, BIR.Descriptor>) -> CatalogResult<Maybe<&2, BIR.Descriptor>>:
  match old:
    case Some{_}: CatalogResult{source, old}
    case None{}:
      match String.eq(key, "main") result:
        case True{} IR.SomeTerm{term}:
          CatalogResult{source, value} = descriptor(source, term, scope)
          CatalogResult{source, Some{value}}
        case _ _: CatalogResult{source, None{}}
def signature_symbol(value: Scope.ArenaGlobal) -> IR.Symbol:
  match value:
    case Scope.ArenaGlobal{_, owner, local, ty, _, Scope.GlobalDefinition{}}: IR.Symbol{owner, local, IR.DefinitionSymbol{}, ty}
    case Scope.ArenaGlobal{_, owner, local, ty, _, Scope.GlobalFamily{}}: IR.Symbol{owner, local, IR.FamilySymbol{}, ty}
    case Scope.ArenaGlobal{_, owner, local, ty, _, Scope.GlobalConstructor{}}: IR.Symbol{owner, local, IR.ConstructorSymbol{}, ty}

def prepare_definition(source: Arena.Arena, definition: IR.Definition, namespace: String, source_path: String, native: Bool, scope: Scope.ArenaGlobalScope, state: Preparation) -> CatalogResult<Preparation>:
  match definition:
    case IR.Definition{key, binders, result, body, _, _, checked, Some{IR.DefinitionFacts{type_only, fixed, prefix}}}:
      prepare_definition_symbol(source, Scope.lookup_kind(qualify(namespace, key), Scope.GlobalDefinition{}, scope), qualify(namespace, key), key, binders, result, body, checked, Bool.and(type_only, is_term(body)), fixed, prefix, source_path, native, scope, state)
    case IR.Definition{key, _, _, _, _, _, _, None{}}:
      CatalogResult{source, preparation_failure(state, String.append("bend: missing checked declaration facts for ", qualify(namespace, key)))}
def prepare_definition_symbol(source: Arena.Arena, found: Maybe<&2, Scope.ArenaGlobal>, key: String, local: String, binders: IR.Words, result: IR.OptionalTerm, body: IR.DefBody, checked: Maybe<&2, IR.Occurrence>, type_only: Bool, fixed: Bool, prefix: Nat, source_path: String, native: Bool, scope: Scope.ArenaGlobalScope, state: Preparation) -> CatalogResult<Preparation>:
  match found:
    case None{}: CatalogResult{source, preparation_failure(state, String.append("bend: missing published definition signature for ", key))}
    case Some{global}:
      CatalogResult{source, Telescope{parameters, quantities, _, _}} = live_telescope(source, binders, 0)
      CatalogResult{source, foreign} = definition_foreign(source, body, source_path, local, List.length(&2, BIR.Parameter, parameters))
      operation = definition_primitive(type_only, foreign, native, key)
      fast = definition_fast(fixed, type_only, parameters, operation, foreign)
      match state:
        case Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, failure, owners}:
          header = DefinitionHeader{signature_symbol(global), key, code, parameters, quantities, type_only, operation, foreign, fast}
          definition = Definition{header, binders, result, body, checked, scope, native_marker(native, key), prefix}
          CatalogResult{source, roots} = binder_roots(source, binders, scope, roots)
          roots = type_root(Bool.and(type_only, is_term(body)), key, result_roots(result, scope, roots))
          CatalogResult{source, main} = main_descriptor(source, key, result, scope, main)
          index = value_insert(IndexLookup.find(Bool, owners, key), body, key, definition, index)
          CatalogResult{source, Preparation{definition <> defs, index, header_insert(key, header, headers), ctors, ci, families, U32.add(code, 1), ctr, roots, main, failure, Map.set(&2, Bool, owners, key, True{})}}
def is_term(body: IR.DefBody) -> Bool:
  match body:
    case IR.DefTerm{_}: True{}
    case IR.DefImports{_}: False{}
def prepare_constructors(source: Arena.Arena, constructors: List<&2, IR.ConstructorDecl>, namespace: String, family: String, parameter_count: Nat, native: Bool, scope: Scope.ArenaGlobalScope, state: Preparation) -> CatalogResult<Arms>:
  match constructors:
    case Nil{}: CatalogResult{source, Arms{Nil{}, state}}
    case IR.Constructor{local, binders, _} <> rest:
      CatalogResult{source, Telescope{_, quantities, fields, _}} = telescope(source, binders, 0, scope)
      key = qualify(namespace, local)
      match state:
        case Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, failure, owners}:
          layout = BIR.ConstructorLayout{ctr, key, constructor_native(native, family, key), field_names(fields)}
          constructor = Constructor{layout, quantities, parameter_count, qualify(namespace, family)}
          CatalogResult{source, roots} = binder_roots(source, binders, scope, roots)
          state = Preparation{defs, index, headers, layout <> ctors, insert_constructor(key, constructor, ci), families, code, U32.add(ctr, 1), roots, main, failure, owners}
          CatalogResult{source, Arms{arms, state}} = prepare_constructors(source, rest, namespace, family, parameter_count, native, scope, state)
          CatalogResult{source, Arms{BIR.DescriptorArm{key, fields} <> arms, state}}
def prepare_family(source: Arena.Arena, declaration: IR.TypeDecl, namespace: String, native: Bool, scope: Scope.ArenaGlobalScope, prefix: Nat, state: Preparation) -> CatalogResult<Preparation>:
  match declaration:
    case IR.TypeDecl{local, binders, kind, constructors, _}:
      count = words_count(binders)
      CatalogResult{source, Arms{arms, state}} = prepare_constructors(source, constructors, namespace, local, count, native, scope, state)
      match state:
        case Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, failure, owners}:
          key = qualify(namespace, local)
          CatalogResult{source, roots} = binder_roots(source, binders, scope, roots)
          family = BIR.Family{key, local, native_marker(native, local), prefix, count, arms}
          state = Preparation{defs, index, headers, ctors, ci, family <> families, code, ctr, TermRoot{kind, scope} <> roots, main, failure, owners}
          CatalogResult{source, block_family(Scope.lookup_kind(key, Scope.GlobalFamily{}, scope), key, state)}
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
def prepare_declarations(source: Arena.Arena, declarations: List<&2, IR.TopLevel>, namespace: String, source_path: String, native: Bool, scope: Scope.ArenaGlobalScope, metadata: List<&2, Checked.FamilyMetadata>, state: Preparation) -> CatalogResult<Preparation>:
  match declarations:
    case Nil{}:
      match metadata:
        case Nil{}: CatalogResult{source, state}
        case _ <> _: CatalogResult{source, preparation_failure(state, "bend: unmatched checked family metadata")}
    case IR.DefTop{definition} <> rest:
      CatalogResult{source, state} = prepare_definition(source, definition, namespace, source_path, native, scope, state)
      prepare_declarations(source, rest, namespace, source_path, native, scope, metadata, state)
    case IR.TypeTop{family} <> rest:
      match metadata:
        case Nil{}: CatalogResult{source, preparation_failure(state, "bend: missing checked family metadata")}
        case Checked.FamilyMetadata{key, prefix} <> remaining:
          match String.eq(key, family_key(family, namespace)):
            case False{}: CatalogResult{source, preparation_failure(state, "bend: checked family metadata identity mismatch")}
            case True{}:
              CatalogResult{source, state} = prepare_family(source, family, namespace, native, scope, prefix, state)
              prepare_declarations(source, rest, namespace, source_path, native, scope, remaining, state)
    case IR.LawTop{declaration} <> rest:
      CatalogResult{source, state} = prepare_law(source, declaration, namespace, native, scope, state)
      prepare_declarations(source, rest, namespace, source_path, native, scope, metadata, state)
def reset_module(state: Preparation) -> Preparation:
  match state:
    case Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, failure, _}:
      Preparation{defs, index, headers, ctors, ci, families, code, ctr, roots, main, failure, MTip{}}
def prepare_modules(source: Arena.Arena, modules: List<&2, IR.LoadedModule>, metadata: List<&2, Checked.ModuleMetadata>, imported: Bool, state: Preparation) -> CatalogResult<Preparation>:
  match modules metadata:
    case Nil{} Nil{}: CatalogResult{source, state}
    case IR.LoadedModule{namespace, IR.Module{path, _, declarations}} <> rest Checked.ModuleMetadata{owner, origin, scope, families} <> remaining:
      match Bool.and(String.eq(namespace, owner), String.eq(path, origin)):
        case False{}: CatalogResult{source, preparation_failure(state, "bend: checked module metadata identity mismatch")}
        case True{}:
          CatalogResult{source, state} = prepare_declarations(source, declarations, namespace, path, base_source(path, imported), scope, families, reset_module(state))
          prepare_modules(source, rest, remaining, imported, state)
    case _ _: CatalogResult{source, preparation_failure(state, "bend: missing or unmatched checked module metadata")}
def ending(requested: Maybe<&2, List<&2, String>>, main: Maybe<&2, BIR.Descriptor>, registry: Registry) -> BIR.Ending:
  match requested:
    case Some{keys}: BIR.Library{exports(keys, registry)}
    case None{}:
      match main:
        case Some{ty}: BIR.Executable{ty}
        case None{}: BIR.Executable{BIR.DescriptorNull{}}
def build_finish(source: Arena.Arena, modules: List<&2, IR.LoadedModule>, signatures: List<&2, Scope.ArenaGlobal>, metadata: List<&2, Checked.ModuleMetadata>, requested: Maybe<&2, List<&2, String>>, state: Preparation) -> BuildResult:
  match state:
    case Preparation{defs, index, headers, ctors, ci, families, next_code, _, roots, main, None{}, _}:
      CatalogResult{source, Needed{functions, _}} = needed_roots(source, List.reverse(&2, Root, roots), index, Needed{Nil{}, MTip{}})
      registry = Registry{headers, ci}
      catalog = Catalog{List.reverse(&2, Definition, defs), registry, List.reverse(&2, BIR.ConstructorLayout, ctors), List.reverse(&2, BIR.Family, families), functions, next_code, ending(requested, main, registry)}
      Built{Checked.CheckedProgram{source, modules, signatures, metadata}, catalog}
    case Preparation{_, _, _, _, _, _, _, _, _, _, Some{message}, _}:
      BuildFailure{Checked.CheckedProgram{source, modules, signatures, metadata}, message}

# Proof obligations for the integrated compiler gate, not assumed Bend laws:
# - semantic reads preserve the Arena owner and all published handles;
# - first-owner insertion agrees with checked symbol identity and source order;
# - quantity erasure removes only runtime parameters, never descriptor slots;
# - code/constructor allocation is deterministic and disjoint from lifted IDs;
# - descriptors preserve dependent environments, constructor identities and ABI;
# - native ownership requires the imported authoritative Base source;
# - the visited set includes a function before its outgoing dependencies.
# The Registry deliberately retains no body, occurrence tree or module list.
def build(program: Checked.CheckedProgram, requested: Maybe<&2, List<&2, String>>) -> BuildResult:
  match program:
    case Checked.CheckedProgram{source, modules, signatures, metadata}:
      initial = Preparation{Nil{}, MTip{}, MTip{}, Nil{}, MTip{}, Nil{}, 0, 0, Nil{}, None{}, None{}, MTip{}}
      CatalogResult{source, state} = prepare_modules(source, modules, metadata, base_imported(modules), initial)
      build_finish(source, modules, signatures, metadata, requested, state)

# Unlike constructor telescopes, declaration parameters do not need field-type
# descriptor allocation. Their semantic domains are visited only as roots.
def live_telescope(source: Arena.Arena, words: IR.Words, offset: U32) -> CatalogResult<Telescope>:
  match words:
    case IR.Words{_, 0}: CatalogResult{source, Telescope{Nil{}, Nil{}, Nil{}, True{}}}
    case IR.Words{start, count}:
      Tuple{source, id} = Arena.word(source, IR.arena_tape_offset(start))
      Tuple{source, binder} = Arena.get_binder(source, id)
      CatalogResult{source, rest} = live_telescope(source, IR.Words{IR.arena_range_index(start, 1), U32.sub(count, 1)}, U32.add(offset, 1))
      CatalogResult{source, live_binder(binder, offset, rest)}
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
