import Base
import ../bend2/selfhost/ast.bend as Ast
import ../bend2/selfhost/core.bend as Core
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/sha256.bend as SHA256
import ../bend2/selfhost/path.bend as Path

type ExpandResult is Data:
  ExpandSuccess{modules: List<&2, Loader.LoadedModule>}
  ExpandFailure{message: String, span: Ast.SourceSpan}

type ApplicationSpine is Data:
  ApplicationSpine{head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan}

# Capture names describe only the caller's actual current/import/Base scope.
# Canonical identities are not a catalog-wide visibility escape hatch.
type CaptureName is Data:
  CaptureName{key: String, canonical: String, family: Bool, constructor: Bool}

type TemplateDef is Data:
  TemplateDef{key: String, namespace: String, imports: List<&2, Ast.ModuleImport>, existing_keys: List<&2, String>, alias_key: String, definition: Ast.Definition, captures: List<&2, CaptureName>}

# Raw occurrences are round-local; expansion still uses the requesting
# template suffix and the supplying module's complete caller scope.
type ActualSite is Data:
  ActualSite{key: String, values: List<&2, Ast.SyntaxTerm>}

type ActualModule is Data:
  ActualModule{namespace: String, imports: List<&2, Ast.ModuleImport>, sites: List<&2, ActualSite>, captures: List<&2, CaptureName>}

type GeneratedIdentity is Data:
  GeneratedIdentity{key: String, template_key: String, local_key: String, identity: String}

type GeneratedBuild is Data:
  GeneratedBuild{definitions: List<&2, Ast.TopLevel>, identities: List<&2, GeneratedIdentity>, collision: Maybe<&2, Ast.SourceSpan>}

type GeneratedRound is Data:
  GeneratedRound{modules: List<&2, Loader.LoadedModule>, changed: Bool, identities: List<&2, GeneratedIdentity>, collision: Maybe<&2, Ast.SourceSpan>}

def span_of(term: Ast.SyntaxTerm) -> Ast.SourceSpan:
  match term:
    case Ast.TermVar{_, _, span}: span
    case Ast.TermRef{_, span}: span
    case Ast.TermBang{_, span}: span
    case Ast.TermSub{_, _, _, span}: span
    case Ast.TermLet{_, _, _, _, _, span}: span
    case Ast.TermAnn{_, _, span}: span
    case Ast.TermTemplate{_, span}: span
    case Ast.TermType{_, span}: span
    case Ast.TermQuantity{_, span}: span
    case Ast.TermMin{_, _, span}: span
    case Ast.TermAll{_, _, _, _, _, span}: span
    case Ast.TermLam{_, _, _, _, span}: span
    case Ast.TermApp{_, _, span}: span
    case Ast.TermAdt{_, _, _, span}: span
    case Ast.TermFill{_, _, span}: span
    case Ast.TermPlus{_, _, span}: span
    case Ast.TermCtr{_, _, span}: span
    case Ast.TermString{_, _, span}: span
    case Ast.TermMat{_, _, _, span}: span
    case Ast.TermAbsurd{span}: span
    case Ast.TermEqual{_, _, _, span}: span
    case Ast.TermRefl{span}: span
    case Ast.TermRewrite{_, _, _, span}: span
    case Ast.TermHole{_, span}: span
    case Ast.BodyMatch{_, _, span}: span
    case Ast.BodyCase{_, _, span}: span
    case Ast.BodyLocal{_, _, _, _, span}: span
    case Ast.BodyReply{_, span}: span
    case Ast.TermQuant{}: Ast.SpanOf{ "",  0n,  0n}


def collect_templates(modules: List<&2, Loader.LoadedModule>) -> List<&2, TemplateDef>:
  match modules:
    case Nil{}: Nil{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  Ast.Module{ _, imports, declarations}}:
          List.append(&2, TemplateDef, collect_template_decls(namespace, imports, top_keys(declarations), declarations), collect_templates(rest))

def top_keys(declarations: List<&2, Ast.TopLevel>) -> List<&2, String>:
  match declarations:
    case Nil{}: Nil{}
    case +declaration <> rest:
      match declaration:
        case Ast.DefTop{ Ast.Definition{key,  _,  _,  _,  _,  _}}: key <> top_keys(rest)
        case Ast.TypeTop{ Ast.TypeDecl{key,  _,  _,  _,  _}}: key <> top_keys(rest)
        case Ast.LawTop{ Ast.LawDecl{key,  _,  _,  _}}: key <> top_keys(rest)

def collect_template_decls(namespace: String, imports: List<&2, Ast.ModuleImport>, existing_keys: List<&2, String>, declarations: List<&2, Ast.TopLevel>) -> List<&2, TemplateDef>:
  match declarations:
    case Nil{}: Nil{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{key, binders, result, body, unsafe, span}}:
          collect_template_decl(namespace, imports, existing_keys, key, binders, result, body, unsafe, span, rest, has_template_binder(binders))
        case _: collect_template_decls(namespace, imports, existing_keys, rest)

def collect_template_decl(namespace: String, imports: List<&2, Ast.ModuleImport>, existing_keys: List<&2, String>, key: String, binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, body: Ast.DefBody, unsafe: Bool, span: Ast.SourceSpan, rest: List<&2, Ast.TopLevel>, is_template: Bool) -> List<&2, TemplateDef>:
  match is_template:
    case True{}:
      canonical = qualify(namespace, key)
      d = Ast.Definition{key, binders, result, body, unsafe, span}
      TemplateDef{ canonical, namespace, imports, existing_keys,  "",  d, Nil{}} <> collect_template_decls(namespace, imports, existing_keys, rest)
    case False{}: collect_template_decls(namespace, imports, existing_keys, rest)

def has_template_binder(binders: List<&2, Ast.TelescopeItem>) -> Bool:
  match binders:
    case Nil{}: False{}
    case +binder <> rest:
      match binder:
        case Ast.TemplateBinder{ _,  _,  _,  _}: True{}
        case Ast.Binder{ _,  _,  _,  _,  _}: has_template_binder(rest)

def qualify(namespace: String, key: String) -> String:
  qualify_match(namespace, key, String.eq(namespace, ""))

def qualify_match(namespace: String, key: String, empty: Bool) -> String:
  match empty:
    case True{}: key
    case False{}: namespace ++ "." ++ key

def find_template(key: String, templates: List<&2, TemplateDef>) -> Maybe<&2, TemplateDef>:
  match templates:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case TemplateDef{ found,  _,  _,  _, alias_key,  _, _}:
          find_template_match(key, item, rest, Bool.or(String.eq(found, key), String.eq(alias_key, key)))

def find_template_match(key: String, item: TemplateDef, rest: List<&2, TemplateDef>, matches: Bool) -> Maybe<&2, TemplateDef>:
  match matches:
    case True{}: Some{item}
    case False{}: find_template(key, rest)
def flatten_application(term: Ast.SyntaxTerm) -> ApplicationSpine:
  match term:
    case Ast.TermApp{fn, arg, span}:
      flatten_append(flatten_application(fn), arg, span)

    case _:
      ApplicationSpine{ term,  Nil{},  span_of(term)}
def flatten_append(spine: ApplicationSpine, arg: Ast.SyntaxTerm, span: Ast.SourceSpan) -> ApplicationSpine:
  match spine:
    case ApplicationSpine{head, args,  _}: ApplicationSpine{head,  List.append(&2, Ast.SyntaxTerm, args, [arg]), span}

def leading_template_count(binders: List<&2, Ast.TelescopeItem>) -> Nat:
  match binders:
    case Ast.TemplateBinder{ _,  _,  _,  _} <> rest: (1n + leading_template_count(rest) : Nat)
    case _: 0n

def template_for_head(head: Ast.SyntaxTerm, templates: List<&2, TemplateDef>) -> Maybe<&2, TemplateDef>:
  match head:
    case Ast.TermRef{key,  _}: find_template(key, templates)
    case Ast.TermBang{term,  _}: template_for_head(term, templates)
    case _: None{}

def take_template_args(args: List<&2, Ast.SyntaxTerm>, count: Nat) -> Maybe<&2, List<&2, Ast.SyntaxTerm>>:
  match args count:
    case _ 0n: Some{Nil{}}
    case Ast.TermTemplate{term, _} <> rest 1n+more:
      take_template_arg(term, take_template_args(rest, more))
    case _ _: None{}

def take_template_arg(term: Ast.SyntaxTerm, result: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> Maybe<&2, List<&2, Ast.SyntaxTerm>>:
  match result:
    case Some{value}: Some{term <> value}
    case None{}: None{}

def reapply_args(head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan) -> Ast.SyntaxTerm:
  match args:
    case Nil{}: head
    case +arg <> rest:
      reapply_args(Ast.TermApp{ head, arg, span}, rest, span)


def generated_local_key(template: TemplateDef, values: List<&2, Ast.SyntaxTerm>) -> String:
  match template:
    case TemplateDef{key,  _,  _,  _,  _,  _, _}:
      generated_local_key_for_identity(template, encode_string(key) ++ serialize_terms(values))

# The identity string is `encode_string(template key) ++ serialize_terms(values)`.
# Callers that already built it must not serialize and hash the same values again.
def generated_local_key_for_identity(template: TemplateDef, identity: String) -> String:
  match template:
    case TemplateDef{ _,  _,  _, existing_keys,  _,  _, _}:
      fresh_generated_key("T~" ++ SHA256.hash(identity), existing_keys, 0n)

def fresh_generated_key(base: String, existing: List<&2, String>, attempt: Nat) -> String:
  candidate = generated_candidate(base, attempt)
  fresh_generated_key_match(base, existing, attempt, candidate, has_string(candidate, existing))

def fresh_generated_key_match(base: String, existing: List<&2, String>, attempt: Nat, candidate: String, found: Bool) -> String:
  match found:
    case True{}: fresh_generated_key(base, existing, (attempt + 1n : Nat))
    case False{}: candidate

def generated_candidate(base: String, attempt: Nat) -> String:
  match attempt:
    case 0n: base
    case _: base ++ "~" ++ Nat.show(attempt)

def generated_canonical_key(template: TemplateDef, local_key: String) -> String:
  match template:
    case TemplateDef{ _, namespace,  _,  _,  _,  _, _}:
      qualify(namespace, local_key)

def generated_key(template: TemplateDef, values: List<&2, Ast.SyntaxTerm>) -> String:
  generated_canonical_key(template, generated_local_key(template, values))

def encode_string(value: String) -> String:
  Nat.show(String.length(value)) ++ ":" ++ value

def encode_quantity(quantity: Ast.Quantity) -> String:
  match quantity:
    case Ast.QZero{}: "0"
    case Ast.QOne{}: "1"
    case Ast.QMany{}: "m"

def serialize_strings(values: List<&2, String>) -> String:
  match values:
    case Nil{}: "]"
    case +value <> rest: encode_string(value) ++ ";" ++ serialize_strings(rest)

def serialize_nats(values: List<&2, Nat>) -> String:
  match values:
    case Nil{}: "]"
    case +value <> rest: Nat.show(value) ++ ";" ++ serialize_nats(rest)

def serialize_quantities(values: List<&2, Ast.Quantity>) -> String:
  match values:
    case Nil{}: "]"
    case +value <> rest: encode_quantity(value) ++ ";" ++ serialize_quantities(rest)

def serialize_patterns(values: List<&2, Ast.SyntaxPattern>) -> String:
  match values:
    case Nil{}: "]"
    case +value <> rest: serialize_pattern(value) ++ ";" ++ serialize_patterns(rest)

def serialize_pattern(pattern: Ast.SyntaxPattern) -> String:
  match pattern:
    case Ast.PatternVar{ _, index, quantity,  _}: "v" ++ Nat.show(index) ++ encode_quantity(quantity) ++ ";"
    case Ast.PatternCtr{key, fields,  _}: "c" ++ encode_string(key) ++ serialize_patterns(fields)

def serialize_terms(values: List<&2, Ast.SyntaxTerm>) -> String:
  match values:
    case Nil{}: "]"
    case +value <> rest: serialize_term(value) ++ ";" ++ serialize_terms(rest)

def serialize_term(term: Ast.SyntaxTerm) -> String:
  match term:
    case Ast.TermVar{_, index, _}: "v" ++ Nat.show(index) ++ ";"
    case Ast.TermRef{key,  _}: "r" ++ encode_string(key)
    case Ast.TermBang{ value,  _}: "!" ++ serialize_term(value)
    case Ast.TermSub{index, value, body,  _}: "s" ++ Nat.show(index) ++ ";" ++ serialize_term(value) ++ serialize_term(body)
    case Ast.TermLet{keys, indexes, quantities, values, body,  _}: "l" ++ serialize_strings(keys) ++ serialize_nats(indexes) ++ serialize_quantities(quantities) ++ serialize_terms(values) ++ serialize_term(body)
    case Ast.TermAnn{ value, ty,  _}: "a" ++ serialize_term(value) ++ serialize_term(ty)
    case Ast.TermTemplate{ value,  _}: "t" ++ serialize_term(value)
    case Ast.TermType{kind,  _}: "T" ++ serialize_term(kind)
    case Ast.TermQuant{}: "q;"
    case Ast.TermQuantity{quantity,  _}: "Q" ++ encode_quantity(quantity) ++ ";"
    case Ast.TermMin{left, right,  _}: "m" ++ serialize_term(left) ++ serialize_term(right)
    case Ast.TermAll{quantity, _, _, ty, body, _}: "A" ++ encode_quantity(quantity) ++ serialize_term(ty) ++ serialize_term(body)
    case Ast.TermLam{quantity, _, _, body, _}: "L" ++ serialize_optional_quantity(quantity) ++ serialize_term(body)
    case Ast.TermApp{fn, arg,  _}: "p" ++ serialize_term(fn) ++ serialize_term(arg)
    case Ast.TermAdt{key, args, refs,  _}: "d" ++ encode_string(key) ++ serialize_terms(args) ++ serialize_strings(refs)
    case Ast.TermFill{head, args,  _}: "f" ++ serialize_term(head) ++ serialize_terms(args)
    case Ast.TermPlus{head, args,  _}: "+" ++ serialize_term(head) ++ serialize_terms(args)
    case Ast.TermCtr{key, args,  _}: "c" ++ encode_string(key) ++ serialize_terms(args)
    case Ast.TermString{chars, names, span}: serialize_term(Ast.string_desugar(chars, names, span))
    case Ast.TermMat{key, head, matched,  _}: "M" ++ encode_string(key) ++ serialize_term(head) ++ serialize_term(matched)
    case Ast.TermAbsurd{ _}: "!"
    case Ast.TermEqual{left, right, ty,  _}: "=" ++ serialize_term(left) ++ serialize_term(right) ++ serialize_term(ty)
    case Ast.TermRefl{ _}: "R"
    case Ast.TermRewrite{equation, proof, body,  _}: "w" ++ serialize_term(equation) ++ serialize_term(proof) ++ serialize_term(body)
    case Ast.TermHole{key,  _}: "h" ++ encode_string(key)
    case Ast.BodyMatch{scrutinees, cases,  _}: "B" ++ serialize_terms(scrutinees) ++ serialize_terms(cases)
    case Ast.BodyCase{patterns, body,  _}: "C" ++ serialize_patterns(patterns) ++ serialize_term(body)
    case Ast.BodyLocal{patterns, quantity, values, body,  _}: "D" ++ serialize_patterns(patterns) ++ encode_quantity(quantity) ++ serialize_terms(values) ++ serialize_term(body)
    case Ast.BodyReply{ value,  _}: "Y" ++ serialize_term(value)

def serialize_optional_quantity(value: Maybe<&2, Ast.Quantity>) -> String:
  match value:
    case None{}: "n"
    case Some{value}: "s" ++ encode_quantity(value)

def strip_namespace(key: String, namespace: String) -> String:
  strip_namespace_match(key, namespace, String.eq(namespace, ""))

def strip_namespace_match(key: String, namespace: String, empty: Bool) -> String:
  match empty:
    case True{}: key
    case False{}: strip_namespace_prefix(key, namespace ++ ".")

def strip_namespace_prefix(key: String, prefix: String) -> String:
  strip_namespace_prefix_match(key, prefix, String.starts_with(key, prefix))

def strip_namespace_prefix_match(key: String, prefix: String, starts: Bool) -> String:
  match starts:
    case True{}: String.drop(key, String.length(prefix))
    case False{}: key

# Relocate only supplied values, before substitution and identity serialization.
# The template's own binders/result/body retain their original lexical scope.
def template_capture_names(template: TemplateDef) -> List<&2, CaptureName>:
  match template:
    case TemplateDef{_, _, _, _, _, _, captures}: captures

def scoped_templates(namespace: String, imports: List<&2, Ast.ModuleImport>, templates: List<&2, TemplateDef>, modules: List<&2, Loader.LoadedModule>) -> List<&2, TemplateDef>:
  match templates:
    case Nil{}: Nil{}
    case +_ <> _: templates_with_captures(visible_templates(namespace, imports, templates), scope_capture_names(namespace, imports, modules))

def templates_with_captures(templates: List<&2, TemplateDef>, captures: List<&2, CaptureName>) -> List<&2, TemplateDef>:
  match templates:
    case Nil{}: Nil{}
    case TemplateDef{key, owner, imports, existing_keys, alias, definition, _} <> rest:
      TemplateDef{key, owner, imports, existing_keys, alias, definition, captures} <> templates_with_captures(rest, captures)

def scope_capture_names(namespace: String, imports: List<&2, Ast.ModuleImport>, modules: List<&2, Loader.LoadedModule>) -> List<&2, CaptureName>:
  current = capture_module_names(namespace, "", modules)
  imported = capture_import_names(namespace, imports, modules)
  base = capture_module_names("", "Base", modules)
  List.append(&2, CaptureName, current, List.append(&2, CaptureName, imported, base))

def capture_import_names(namespace: String, imports: List<&2, Ast.ModuleImport>, modules: List<&2, Loader.LoadedModule>) -> List<&2, CaptureName>:
  match imports:
    case Nil{}: Nil{}
    case Ast.ModuleImport{path, alias, _} <> rest:
      List.append(&2, CaptureName, capture_module_names(Path.namespace(namespace, path), alias, modules), capture_import_names(namespace, rest, modules))

def native_match_capture_module_names_0(v_22: Bool, v_1: String, v_3: String, v_16: List<&2, Ast.TopLevel>, v_17: List<&2, Loader.LoadedModule>) -> List<&2, CaptureName>:
  match v_22:
    case False{}:
      capture_module_names(v_1, v_3, v_17)
    case True{}:
      List.append(&2, CaptureName, capture_declaration_names(v_1, v_3, v_16), capture_module_names(v_1, v_3, v_17))

def native_match_capture_module_names_1(v_5: List<&2, Loader.LoadedModule>, v_1: String, v_3: String) -> List<&2, CaptureName>:
  match v_5:
    case []:
      []
    case Loader.LoadedModule{v_13, Ast.Module{_, _, v_16}} <> v_17:
      native_match_capture_module_names_0(String.eq(v_1, v_13), v_1, v_3, v_16, v_17)

def capture_module_names(v_1: String, v_3: String, v_5: List<&2, Loader.LoadedModule>) -> List<&2, CaptureName>:
  native_match_capture_module_names_1(v_5, v_1, v_3)

def native_match_capture_declaration_names_0(+v_10: Ast.TopLevel, v_1: String, v_3: String, v_14: List<&2, CaptureName>) -> List<&2, CaptureName>:
  match v_10:
    case Ast.DefTop{Ast.Definition{v_21, _, _, _, _, _}}:
      capture_declared_name(v_1, v_3, v_21, False{}, False{}, v_14)
    case Ast.TypeTop{Ast.TypeDecl{v_33, _, _, v_36, _}}:
      capture_declared_name(v_1, v_3, v_33, True{}, False{}, List.append(&2, CaptureName, capture_constructor_names(v_1, v_3, v_36), v_14))
    case Ast.LawTop{Ast.LawDecl{v_45, _, _, _}}:
      capture_declared_name(v_1, v_3, v_45, False{}, False{}, v_14)

def native_match_capture_declaration_names_1(v_5: List<&2, Ast.TopLevel>, v_1: String, v_3: String) -> List<&2, CaptureName>:
  match v_5:
    case []:
      []
    case +v_10 <> v_11:
      v_14 = capture_declaration_names(v_1, v_3, v_11)
      native_match_capture_declaration_names_0(v_10, v_1, v_3, v_14)

def capture_declaration_names(v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>) -> List<&2, CaptureName>:
  native_match_capture_declaration_names_1(v_5, v_1, v_3)

def capture_constructor_names(owner: String, alias: String, constructors: List<&2, Ast.ConstructorDecl>) -> List<&2, CaptureName>:
  match constructors:
    case Nil{}: Nil{}
    case Ast.Constructor{key, _, _} <> rest:
      capture_declared_name(owner, alias, key, False{}, True{}, capture_constructor_names(owner, alias, rest))

def native_match_capture_declared_name_0(v_21: Bool, v_5: String, v_7: Bool, v_9: Bool, v_17: String, v_20: List<&2, CaptureName>) -> List<&2, CaptureName>:
  match v_21:
    case True{}:
      CaptureName{v_5, v_17, v_7, v_9} <> v_20
    case False{}:
      v_20

def capture_declared_name(v_1: String, v_3: String, v_5: String, v_7: Bool, v_9: Bool, v_12: List<&2, CaptureName>) -> List<&2, CaptureName>:
  v_17 = qualify(v_1, v_5)
  v_20 = CaptureName{qualify(v_3, v_5), v_17, v_7, v_9} <> v_12
  native_match_capture_declared_name_0(String.eq(v_3, "Base"), v_5, v_7, v_9, v_17, v_20)

def native_match_capture_name_0(v_20: Bool, v_1: String, v_3: Bool, v_9: Maybe<&2, String>, v_18: String, v_21: List<&2, CaptureName>) -> Maybe<&2, String>:
  match v_20:
    case True{}:
      Some{v_18}
    case False{}:
      capture_name(v_1, v_3, v_21, v_9)

def native_match_capture_name_1(v_9: Maybe<&2, String>, v_1: String, v_3: Bool, v_18: String, v_21: List<&2, CaptureName>) -> Maybe<&2, String>:
  match v_9:
    case Some{_}:
      capture_name(v_1, v_3, v_21, v_9)
    case None{}:
      capture_name(v_1, v_3, v_21, Some{v_18})

def native_match_capture_name_2(v_19: Bool, v_1: String, v_3: Bool, v_9: Maybe<&2, String>, v_18: String, v_21: List<&2, CaptureName>) -> Maybe<&2, String>:
  match v_19:
    case True{}:
      Some{v_18}
    case False{}:
      native_match_capture_name_1(v_9, v_1, v_3, v_18, v_21)

def native_match_capture_name_3(v_3: Bool, v_1: String, v_9: Maybe<&2, String>, v_18: String, v_19: Bool, v_20: Bool, v_21: List<&2, CaptureName>) -> Maybe<&2, String>:
  match v_3:
    case True{}:
      native_match_capture_name_0(v_20, v_1, v_3, v_9, v_18, v_21)
    case False{}:
      native_match_capture_name_2(v_19, v_1, v_3, v_9, v_18, v_21)

def native_match_capture_name_4(v_27: Bool, v_1: String, v_3: Bool, v_9: Maybe<&2, String>, v_18: String, v_19: Bool, v_20: Bool, v_21: List<&2, CaptureName>) -> Maybe<&2, String>:
  match v_27:
    case False{}:
      capture_name(v_1, v_3, v_21, v_9)
    case True{}:
      native_match_capture_name_3(v_3, v_1, v_9, v_18, v_19, v_20, v_21)

def native_match_capture_name_5(v_6: List<&2, CaptureName>, v_1: String, v_3: Bool, v_9: Maybe<&2, String>) -> Maybe<&2, String>:
  match v_6:
    case []:
      v_9
    case CaptureName{v_17, v_18, v_19, v_20} <> v_21:
      native_match_capture_name_4(Bool.or(String.eq(v_1, v_17), String.eq(v_1, v_18)), v_1, v_3, v_9, v_18, v_19, v_20, v_21)

def capture_name(v_1: String, v_3: Bool, v_6: List<&2, CaptureName>, v_9: Maybe<&2, String>) -> Maybe<&2, String>:
  native_match_capture_name_5(v_6, v_1, v_3, v_9)

def native_match_capture_key_0(v_11: Maybe<&2, String>, v_1: String) -> String:
  match v_11:
    case None{}:
      v_1
    case Some{v_10}:
      v_10

def capture_key(v_1: String, v_3: Bool, v_6: List<&2, CaptureName>) -> String:
  native_match_capture_key_0(capture_name(v_1, v_3, v_6, None{}), v_1)

def capture_strings(keys: List<&2, String>, captures: List<&2, CaptureName>) -> List<&2, String>:
  match keys:
    case Nil{}: Nil{}
    case +key <> rest: capture_key(key, True{}, captures) <> capture_strings(rest, captures)

def capture_patterns(patterns: List<&2, Ast.SyntaxPattern>, captures: List<&2, CaptureName>) -> List<&2, Ast.SyntaxPattern>:
  match patterns:
    case Nil{}: Nil{}
    case +pattern <> rest: capture_pattern(pattern, captures) <> capture_patterns(rest, captures)

def capture_pattern(pattern: Ast.SyntaxPattern, captures: List<&2, CaptureName>) -> Ast.SyntaxPattern:
  match pattern:
    case Ast.PatternVar{_, _, _, _}: pattern
    case Ast.PatternCtr{key, fields, span}: Ast.PatternCtr{capture_key(key, True{}, captures), capture_patterns(fields, captures), span}

def capture_terms(terms: List<&2, Ast.SyntaxTerm>, captures: List<&2, CaptureName>) -> List<&2, Ast.SyntaxTerm>:
  match terms:
    case Nil{}: Nil{}
    case +term <> rest: capture_term(term, captures) <> capture_terms(rest, captures)

# This traversal never changes spans, local names/indices, quantities, or holes.
# Its only changes are real declared reference identities throughout the value,
# including higher-order lambda bodies, match patterns and exclusion references.
# Native core lowering gives unqualified operator references the Nat namespace;
# parenthesized annotations have already selected any other namespace in Syntax.
def native_match_reference_key_0(v_3: Bool, v_1: String) -> String:
  match v_3:
    case True{}:
      v_1
    case False{}:
      String.append("Nat", v_1)

def native_match_reference_key_1(v_2: Bool, v_1: String) -> String:
  match v_2:
    case False{}:
      v_1
    case True{}:
      native_match_reference_key_0(String.starts_with(v_1, ".."), v_1)

def reference_key(v_1: String) -> String:
  native_match_reference_key_1(String.starts_with(v_1, "."), v_1)

def capture_string_names(names: Ast.StringLiteralNames, +captures: List<&2, CaptureName>) -> Ast.StringLiteralNames:
  match names:
    case Ast.StringLiteralNames{nil, cons, char, uint, word_nil, word_cons, bit_false, bit_true}:
      Ast.StringLiteralNames{capture_key(nil, True{}, captures), capture_key(cons, True{}, captures), capture_key(char, True{}, captures), capture_key(uint, True{}, captures), capture_key(word_nil, True{}, captures), capture_key(word_cons, True{}, captures), capture_key(bit_false, True{}, captures), capture_key(bit_true, True{}, captures)}

def capture_term(term: Ast.SyntaxTerm, captures: List<&2, CaptureName>) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermVar{_, _, _}: term
    case Ast.TermRef{key, span}: Ast.TermRef{capture_key(reference_key(key), False{}, captures), span}
    case Ast.TermBang{inner, span}: Ast.TermBang{capture_term(inner, captures), span}
    case Ast.TermSub{index, value, body, span}: Ast.TermSub{index, capture_term(value, captures), capture_term(body, captures), span}
    case Ast.TermLet{keys, indexes, quantities, values, body, span}: Ast.TermLet{keys, indexes, quantities, capture_terms(values, captures), capture_term(body, captures), span}
    case Ast.TermAnn{inner, ty, span}: Ast.TermAnn{capture_term(inner, captures), capture_term(ty, captures), span}
    case Ast.TermTemplate{inner, span}: Ast.TermTemplate{capture_term(inner, captures), span}
    case Ast.TermType{kind, span}: Ast.TermType{capture_term(kind, captures), span}
    case Ast.TermQuant{}: term
    case Ast.TermQuantity{_, _}: term
    case Ast.TermMin{left, right, span}: Ast.TermMin{capture_term(left, captures), capture_term(right, captures), span}
    case Ast.TermAll{quantity, key, index, ty, body, span}: Ast.TermAll{quantity, key, index, capture_term(ty, captures), capture_term(body, captures), span}
    case Ast.TermLam{quantity, key, index, body, span}: Ast.TermLam{quantity, key, index, capture_term(body, captures), span}
    case Ast.TermApp{fn, arg, span}: Ast.TermApp{capture_term(fn, captures), capture_term(arg, captures), span}
    case Ast.TermAdt{key, args, refs, span}: Ast.TermAdt{capture_key(key, False{}, captures), capture_terms(args, captures), capture_strings(refs, captures), span}
    case Ast.TermFill{head, args, span}: Ast.TermFill{capture_term(head, captures), capture_terms(args, captures), span}
    case Ast.TermPlus{head, args, span}: Ast.TermPlus{capture_term(head, captures), capture_terms(args, captures), span}
    case Ast.TermCtr{key, args, span}: Ast.TermCtr{capture_key(key, True{}, captures), capture_terms(args, captures), span}
    case Ast.TermString{chars, names, span}: Ast.TermString{chars, capture_string_names(names, captures), span}
    case Ast.TermMat{key, head, matched, span}: Ast.TermMat{capture_key(key, True{}, captures), capture_term(head, captures), capture_term(matched, captures), span}
    case Ast.TermAbsurd{_}: term
    case Ast.TermEqual{left, right, ty, span}: Ast.TermEqual{capture_term(left, captures), capture_term(right, captures), capture_term(ty, captures), span}
    case Ast.TermRefl{_}: term
    case Ast.TermRewrite{equation, proof, body, span}: Ast.TermRewrite{capture_term(equation, captures), capture_term(proof, captures), capture_term(body, captures), span}
    case Ast.TermHole{_, _}: term
    case Ast.BodyMatch{scrutinees, cases, span}: Ast.BodyMatch{capture_terms(scrutinees, captures), capture_terms(cases, captures), span}
    case Ast.BodyCase{patterns, body, span}: Ast.BodyCase{capture_patterns(patterns, captures), capture_term(body, captures), span}
    case Ast.BodyLocal{patterns, quantity, values, body, span}: Ast.BodyLocal{capture_patterns(patterns, captures), quantity, capture_terms(values, captures), capture_term(body, captures), span}
    case Ast.BodyReply{inner, span}: Ast.BodyReply{capture_term(inner, captures), span}

def expand_term(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>) -> Ast.SyntaxTerm:
  match term:
    case Ast.TermVar{key, index, span}: Ast.TermVar{key, index, span}
    case Ast.TermRef{key, span}: Ast.TermRef{reference_key(key), span}
    case Ast.TermBang{ inner, span}: Ast.TermBang{ expand_term(inner, templates), span}
    case Ast.TermSub{index, value, body, span}: Ast.TermSub{index,  expand_term(value, templates),  expand_term(body, templates), span}
    case Ast.TermLet{keys, indexes, quantities, values, body, span}: Ast.TermLet{keys, indexes, quantities,  expand_terms(values, templates),  expand_term(body, templates), span}
    case Ast.TermAnn{ inner, ty, span}: Ast.TermAnn{ expand_term(inner, templates),  expand_term(ty, templates), span}
    case Ast.TermTemplate{ inner, span}: Ast.TermTemplate{ expand_term(inner, templates), span}
    case Ast.TermType{kind, span}: Ast.TermType{ expand_term(kind, templates), span}
    case Ast.TermQuant{}: term
    case Ast.TermQuantity{quantity, span}: Ast.TermQuantity{quantity, span}
    case Ast.TermMin{left, right, span}: Ast.TermMin{ expand_term(left, templates),  expand_term(right, templates), span}
    case Ast.TermAll{quantity, key, index, ty, body, span}: Ast.TermAll{quantity, key, index,  expand_term(ty, templates),  expand_term(body, templates), span}
    case Ast.TermLam{quantity, key, index, body, span}: Ast.TermLam{quantity, key, index,  expand_term(body, templates), span}
    case Ast.TermApp{fn, arg, span}: expand_application(fn, arg, span, templates)
    case Ast.TermAdt{key, args, refs, span}: Ast.TermAdt{key,  expand_terms(args, templates), refs, span}
    case Ast.TermFill{head, args, span}: Ast.TermFill{ expand_term(head, templates),  expand_terms(args, templates), span}
    case Ast.TermPlus{head, args, span}: Ast.TermPlus{ expand_term(head, templates),  expand_terms(args, templates), span}
    case Ast.TermCtr{key, args, span}: expand_constructor_stable(expand_stable_terms(args), term, key, args, span, templates)
    case Ast.TermString{_, _, _}: term
    case Ast.TermMat{key, head, matched, span}: Ast.TermMat{key,  expand_term(head, templates),  expand_term(matched, templates), span}
    case Ast.TermAbsurd{span}: term
    case Ast.TermEqual{left, right, ty, span}: Ast.TermEqual{ expand_term(left, templates),  expand_term(right, templates),  expand_term(ty, templates), span}
    case Ast.TermRefl{span}: term
    case Ast.TermRewrite{equation, proof, body, span}: Ast.TermRewrite{ expand_term(equation, templates),  expand_term(proof, templates),  expand_term(body, templates), span}
    case Ast.TermHole{key, span}: term
    case Ast.BodyMatch{scrutinees, cases, span}: Ast.BodyMatch{ expand_terms(scrutinees, templates),  expand_terms(cases, templates), span}
    case Ast.BodyCase{patterns, body, span}: Ast.BodyCase{patterns,  expand_term(body, templates), span}
    case Ast.BodyLocal{patterns, quantity, values, body, span}: Ast.BodyLocal{patterns, quantity,  expand_terms(values, templates),  expand_term(body, templates), span}
    case Ast.BodyReply{ inner, span}: Ast.BodyReply{ expand_term(inner, templates), span}

# Expansion never changes these leaves or constructor names. Reuse the complete
# immutable subtree rather than copying every Word bit and string character.
# References and every potentially transforming syntax node take the old path.
def expand_stable_term(term: Ast.SyntaxTerm) -> Bool:
  match term:
    case Ast.TermVar{_, _, _}: True{}
    case Ast.TermCtr{_, args, _}: expand_stable_terms(args)
    case Ast.TermString{_, _, _}: True{}
    case Ast.TermQuant{}: True{}
    case Ast.TermQuantity{_, _}: True{}
    case Ast.TermAbsurd{_}: True{}
    case Ast.TermRefl{_}: True{}
    case Ast.TermHole{_, _}: True{}
    case _: False{}

def expand_stable_terms(terms: List<&2, Ast.SyntaxTerm>) -> Bool:
  match terms:
    case Nil{}: True{}
    case term <> rest: expand_stable_tail(expand_stable_term(term), rest)

def expand_stable_tail(stable: Bool, rest: List<&2, Ast.SyntaxTerm>) -> Bool:
  match stable:
    case True{}: expand_stable_terms(rest)
    case False{}: False{}

def expand_constructor_stable(stable: Bool, original: Ast.SyntaxTerm, key: String, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, templates: List<&2, TemplateDef>) -> Ast.SyntaxTerm:
  match stable:
    case True{}: original
    case False{}: Ast.TermCtr{key, expand_terms(args, templates), span}

def expand_application(fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, templates: List<&2, TemplateDef>) -> Ast.SyntaxTerm:
  application = Ast.TermApp{fn, arg, span}
  expand_application_spine(fn, arg, span, templates, flatten_application(application))

def expand_application_spine(fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, templates: List<&2, TemplateDef>, spine: ApplicationSpine) -> Ast.SyntaxTerm:
  match spine:
    case ApplicationSpine{head, args, _}:
      expand_application_template(fn, arg, span, templates, head, args, template_for_head(head, templates))

def expand_application_template(fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, templates: List<&2, TemplateDef>, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, found: Maybe<&2, TemplateDef>) -> Ast.SyntaxTerm:
  match found:
    case None{}: Ast.TermApp{ expand_term(fn, templates), expand_term(arg, templates), span}
    case Some{ template}:
      arity = template_arity(template)
      expand_application_arguments(fn, arg, span, templates, head, args, template, arity, take_template_args(args, arity))

def template_arity(template: TemplateDef) -> Nat:
  match template:
    case TemplateDef{_, _, _, _, _, Ast.Definition{_, binders, _, _, _, _}, _}: leading_template_count(binders)

def expand_application_arguments(fn: Ast.SyntaxTerm, arg: Ast.SyntaxTerm, span: Ast.SourceSpan, templates: List<&2, TemplateDef>, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, template: TemplateDef, arity: Nat, values: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> Ast.SyntaxTerm:
  match values:
    case None{}: Ast.TermApp{ expand_term(fn, templates), expand_term(arg, templates), span}
    case Some{ actuals}:
      runtime_args = drop_args(args, arity)
      expanded_values = capture_terms(expand_terms(actuals, templates), template_capture_names(template))
      specialized = specialize_head(head, generated_key(template, expanded_values))
      reapply_args(specialized, expand_terms(runtime_args, templates), span)

def specialize_head(head: Ast.SyntaxTerm, key: String) -> Ast.SyntaxTerm:
  match head:
    case Ast.TermRef{_, span}: Ast.TermRef{key, span}
    case Ast.TermBang{ _, span}: Ast.TermBang{ Ast.TermRef{key, span}, span}
    case _: head

def drop_args(args: List<&2, Ast.SyntaxTerm>, count: Nat) -> List<&2, Ast.SyntaxTerm>:
  match args count:
    case _ 0n: args
    case +_ <> rest 1n+more: drop_args(rest, more)
    case Nil{} _: Nil{}


def specialize_definition(template: TemplateDef, local_key: String, values: List<&2, Ast.SyntaxTerm>) -> Ast.Definition:
  match template:
    case TemplateDef{ _,  _,  _,  _,  _,  Ast.Definition{_, binders, result, body, unsafe, span}, _}:
      specialized = specialize_prefix(binders, values, result, body)
      specialize_definition_result(local_key, unsafe, span, specialized)

def specialize_definition_result(key: String, unsafe: Bool, span: Ast.SourceSpan, specialized: List<&2, Ast.TelescopeItem> & Ast.OptionalTerm & Ast.DefBody) -> Ast.Definition:
  match specialized:
    case (binders, result, body): Ast.Definition{key, binders, result, body, unsafe, span}

def specialize_prefix(binders: List<&2, Ast.TelescopeItem>, values: List<&2, Ast.SyntaxTerm>, result: Ast.OptionalTerm, body: Ast.DefBody) -> List<&2, Ast.TelescopeItem> & Ast.OptionalTerm & Ast.DefBody:
  match binders values:
    case Ast.TemplateBinder{_, _, ty, _} <> rest_binders +value <> rest_values:
      substitution_index = binder_count(rest_binders)
      replacement = Ast.TermAnn{value, ty, span_of(value)}
      next_binders = substitute_binders(rest_binders, 0n, replacement)
      next_result = substitute_optional(result, substitution_index, replacement)
      next_body = substitute_body(body, substitution_index, replacement)
      specialize_prefix(next_binders, rest_values, next_result, next_body)
    case _, _:
      (binders, result, body)

def binder_count(binders: List<&2, Ast.TelescopeItem>) -> Nat:
  match binders:
    case Nil{}: 0n
    case +_ <> rest: (1n + binder_count(rest) : Nat)

def substitute_binders(binders: List<&2, Ast.TelescopeItem>, index: Nat, replacement: Ast.SyntaxTerm) -> List<&2, Ast.TelescopeItem>:
  match binders:
    case Nil{}: Nil{}
    case +binder <> rest:
      match binder:
        case Ast.Binder{quantity, key,  binder_index, ty, span}:
          Ast.Binder{quantity, key,  binder_index,  Core.subst(index, replacement, ty), span} <> substitute_binders(rest, (index + 1n : Nat), replacement)
        case Ast.TemplateBinder{key,  binder_index, ty, span}:
          Ast.TemplateBinder{key,  binder_index,  Core.subst(index, replacement, ty), span} <> substitute_binders(rest, (index + 1n : Nat), replacement)

def substitute_optional(value: Ast.OptionalTerm, index: Nat, replacement: Ast.SyntaxTerm) -> Ast.OptionalTerm:
  match value:
    case Ast.NoTerm{}: value
    case Ast.SomeTerm{term}: Ast.SomeTerm{Core.subst(index, replacement, term)}

def substitute_body(value: Ast.DefBody, index: Nat, replacement: Ast.SyntaxTerm) -> Ast.DefBody:
  match value:
    case Ast.DefTerm{term}: Ast.DefTerm{Core.subst(index, replacement, term)}
    case Ast.DefImports{paths}: value
def expand_terms(terms: List<&2, Ast.SyntaxTerm>, templates: List<&2, TemplateDef>) -> List<&2, Ast.SyntaxTerm>:
  match terms:
    case Nil{}: Nil{}
    case +term <> rest: expand_term(term, templates) <> expand_terms(rest, templates)

def strip_template_decls(namespace: String, declarations: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> List<&2, Ast.TopLevel>:
  match declarations:
    case Nil{}: Nil{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{key, binders, result, body, unsafe, span}}:
          strip_template_definition(namespace, key, binders, result, body, unsafe, span, rest, templates, identities, has_template_binder(binders))
        case Ast.TypeTop{ Ast.TypeDecl{key, params, kind, constructors, span}}:
          Ast.TypeTop{ Ast.TypeDecl{key,  expand_binders(params, templates),  expand_term(kind, templates),  expand_constructors(constructors, templates), span}} <> strip_template_decls(namespace, rest, templates, identities)
        case Ast.LawTop{ Ast.LawDecl{key, clauses, body, span}}:
          Ast.LawTop{ Ast.LawDecl{key,  expand_clauses(clauses, templates),  expand_term(body, templates), span}} <> strip_template_decls(namespace, rest, templates, identities)

def strip_template_definition(namespace: String, key: String, binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, body: Ast.DefBody, unsafe: Bool, span: Ast.SourceSpan, rest: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>, is_template: Bool) -> List<&2, Ast.TopLevel>:
  match is_template:
    case True{}:
      strip_canonical_template(namespace, rest, templates, identities, canonical_template_key(key, templates))
    case False{}:
      strip_instance_or_definition(namespace, key, Ast.Definition{key, binders, result, body, unsafe, span}, rest, templates, identities, is_template_instance(namespace, key, identities))

def strip_canonical_template(namespace: String, rest: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>, canonical: Maybe<&2, String>) -> List<&2, Ast.TopLevel>:
  match canonical:
    case Some{ value}: List.append(&2, Ast.TopLevel, template_instances(rest, value, templates, identities), strip_template_decls(namespace, rest, templates, identities))
    case None{}: strip_template_decls(namespace, rest, templates, identities)

def strip_instance_or_definition(namespace: String, key: String, definition: Ast.Definition, rest: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>, is_instance: Bool) -> List<&2, Ast.TopLevel>:
  match is_instance:
    case True{}: strip_template_decls(namespace, rest, templates, identities)
    case False{}: Ast.DefTop{ expand_definition(definition, templates)} <> strip_template_decls(namespace, rest, templates, identities)

def canonical_template_key(local_key: String, templates: List<&2, TemplateDef>) -> Maybe<&2, String>:
  match templates:
    case Nil{}: None{}
    case +template <> rest:
      match template:
        case TemplateDef{key, namespace,  _,  _,  _,  _, _}:
          canonical_template_match(local_key, key, rest, String.eq(local_key, strip_namespace(key, namespace)))

def canonical_template_match(local_key: String, key: String, rest: List<&2, TemplateDef>, matches: Bool) -> Maybe<&2, String>:
  match matches:
    case True{}: Some{key}
    case False{}: canonical_template_key(local_key, rest)

def generated_local_keys(template_key: String, identities: List<&2, GeneratedIdentity>) -> List<&2, String>:
  match identities:
    case Nil{}: Nil{}
    case +entry <> rest:
      match entry:
        case GeneratedIdentity{_, owner, local_key, _}:
          generated_local_key_match(template_key, local_key, rest, String.eq(template_key, owner))

def generated_local_key_match(template_key: String, local_key: String, rest: List<&2, GeneratedIdentity>, matches: Bool) -> List<&2, String>:
  match matches:
    case True{}: local_key <> generated_local_keys(template_key, rest)
    case False{}: generated_local_keys(template_key, rest)

def has_generated_local_key(key: String, local_keys: List<&2, String>) -> Bool:
  has_string(key, local_keys)

def is_template_instance(namespace: String, local_key: String, identities: List<&2, GeneratedIdentity>) -> Bool:
  canonical_key = qualify(namespace, local_key)
  generated_identity_found(find_generated_identity(canonical_key, identities))

def generated_identity_found(identity: Maybe<&2, GeneratedIdentity>) -> Bool:
  match identity:
    case Some{ _}: True{}
    case None{}: False{}

def template_instances(declarations: List<&2, Ast.TopLevel>, template_key: String, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> List<&2, Ast.TopLevel>:
  local_keys = generated_local_keys(template_key, identities)
  template_instances_for_keys(declarations, local_keys, templates)

def template_instances_for_keys(declarations: List<&2, Ast.TopLevel>, local_keys: List<&2, String>, templates: List<&2, TemplateDef>) -> List<&2, Ast.TopLevel>:
  match declarations:
    case Nil{}: Nil{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{key, binders, result, body, unsafe, span}}:
          template_instance_definition(key, binders, result, body, unsafe, span, rest, templates, local_keys, has_generated_local_key(key, local_keys))
        case _: template_instances_for_keys(rest, local_keys, templates)

def template_instance_definition(key: String, binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, body: Ast.DefBody, unsafe: Bool, span: Ast.SourceSpan, rest: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, local_keys: List<&2, String>, is_instance: Bool) -> List<&2, Ast.TopLevel>:
  match is_instance:
    case True{}: Ast.DefTop{ expand_definition(Ast.Definition{key, binders, result, body, unsafe, span}, templates)} <> template_instances_for_keys(rest, local_keys, templates)
    case False{}: template_instances_for_keys(rest, local_keys, templates)

def expand_constructors(constructors: List<&2, Ast.ConstructorDecl>, templates: List<&2, TemplateDef>) -> List<&2, Ast.ConstructorDecl>:
  match constructors:
    case Nil{}: Nil{}
    case +constructor <> rest:
      match constructor:
        case Ast.Constructor{key, fields, span}:
          Ast.Constructor{key,  expand_binders(fields, templates), span} <> expand_constructors(rest, templates)

def expand_clauses(clauses: List<&2, Ast.Clause>, templates: List<&2, TemplateDef>) -> List<&2, Ast.Clause>:
  match clauses:
    case Nil{}: Nil{}
    case +clause <> rest:
      match clause:
        case Ast.ClauseFor{universal, quantity, key, ty, condition, span}:
          Ast.ClauseFor{universal, quantity, key, expand_term(ty, templates), expand_maybe(condition, templates), span} <> expand_clauses(rest, templates)

def expand_maybe(value: Maybe<&2, Ast.SyntaxTerm>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SyntaxTerm>:
  match value:
    case None{}: None{}
    case Some{value}: Some{expand_term(value, templates)}
def expand_definition(d: Ast.Definition, templates: List<&2, TemplateDef>) -> Ast.Definition:
  match d:
    case Ast.Definition{key, binders, result, body, unsafe, span}:
      Ast.Definition{key,  expand_binders(binders, templates),  expand_optional(result, templates),  expand_body(body, templates), unsafe, span}

def expand_body(body: Ast.DefBody, templates: List<&2, TemplateDef>) -> Ast.DefBody:
  match body:
    case Ast.DefTerm{term}: Ast.DefTerm{ expand_term(term, templates)}
    case Ast.DefImports{paths}: body

def expand_optional(result: Ast.OptionalTerm, templates: List<&2, TemplateDef>) -> Ast.OptionalTerm:
  match result:
    case Ast.NoTerm{}: result
    case Ast.SomeTerm{term}: Ast.SomeTerm{ expand_term(term, templates)}

def expand_binders(binders: List<&2, Ast.TelescopeItem>, templates: List<&2, TemplateDef>) -> List<&2, Ast.TelescopeItem>:
  match binders:
    case Nil{}: Nil{}
    case +item <> rest:
      match item:
        case Ast.Binder{quantity, key, index, ty, span}: Ast.Binder{quantity, key, index,  expand_term(ty, templates), span} <> expand_binders(rest, templates)
        case Ast.TemplateBinder{key, index, ty, span}: Ast.TemplateBinder{key, index,  expand_term(ty, templates), span} <> expand_binders(rest, templates)

def collect_actual_term(term: Ast.SyntaxTerm, tail: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match term:
    case Ast.TermApp{_, _, _}: collect_actual_application(term, Nil{}, tail)
    case Ast.TermBang{term, _}: collect_actual_term(term, tail)
    case Ast.TermSub{_, value, body, _}: collect_actual_term(value, collect_actual_term(body, tail))
    case Ast.TermLet{_, _, _, values, body, _}: collect_actual_terms(values, collect_actual_term(body, tail))
    case Ast.TermAnn{inner, ty, _}: collect_actual_term(inner, collect_actual_term(ty, tail))
    case Ast.TermTemplate{inner, _}: collect_actual_term(inner, tail)
    case Ast.TermType{kind, _}: collect_actual_term(kind, tail)
    case Ast.TermMin{left, right, _}: collect_actual_term(left, collect_actual_term(right, tail))
    case Ast.TermAll{_, _, _, ty, body, _}: collect_actual_term(ty, collect_actual_term(body, tail))
    case Ast.TermLam{_, _, _, body, _}: collect_actual_term(body, tail)
    case Ast.TermAdt{_, args, _, _}: collect_actual_terms(args, tail)
    case Ast.TermFill{head, args, _}: collect_actual_term(head, collect_actual_terms(args, tail))
    case Ast.TermPlus{head, args, _}: collect_actual_term(head, collect_actual_terms(args, tail))
    case Ast.TermCtr{_, args, _}: collect_actual_terms(args, tail)
    case Ast.TermString{_, _, _}: tail
    case Ast.TermMat{_, head, matched, _}: collect_actual_term(head, collect_actual_term(matched, tail))
    case Ast.TermEqual{left, right, ty, _}: collect_actual_term(left, collect_actual_term(right, collect_actual_term(ty, tail)))
    case Ast.TermRewrite{equation, proof, body, _}: collect_actual_term(equation, collect_actual_term(proof, collect_actual_term(body, tail)))
    case Ast.BodyMatch{scrutinees, cases, _}: collect_actual_terms(scrutinees, collect_actual_terms(cases, tail))
    case Ast.BodyCase{_, body, _}: collect_actual_term(body, tail)
    case Ast.BodyLocal{_, _, values, body, _}: collect_actual_terms(values, collect_actual_term(body, tail))
    case Ast.BodyReply{inner, _}: collect_actual_term(inner, tail)
    case _: tail

# A matching outer spine suppresses its partial applications, but not sites
# within its arguments. For any other key those partial applications cannot
# match, so walking the flattened head and arguments preserves the same order.
# Accumulating arguments with cons also avoids copying every partial spine.
# wrapped_prefix always returns Some, including for an empty prefix.
def native_match_collect_actual_application_0(v_24: Maybe<&2, String>, v_2: List<&2, Ast.SyntaxTerm>, v_20: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match v_24:
    case None{}:
      v_20
    case Some{v_23}:
      collect_actual_prefix(v_23, wrapped_prefix(v_2), v_20)

def native_match_collect_actual_application_1(v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>, v_5: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match v_0:
    case Ast.TermApp{v_11, v_12, _}:
      collect_actual_application(v_11, v_12 <> v_2, v_5)
    case _:
      v_20 = collect_actual_term(v_0, collect_actual_terms(v_2, v_5))
      native_match_collect_actual_application_0(head_key(v_0), v_2, v_20)

def collect_actual_application(v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>, v_5: List<&2, ActualSite>) -> List<&2, ActualSite>:
  native_match_collect_actual_application_1(v_0, v_2, v_5)

def collect_actual_prefix(key: String, prefix: Maybe<&2, List<&2, Ast.SyntaxTerm>>, tail: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match prefix:
    case Some{Nil{}}: tail
    case Some{values}: ActualSite{key, values} <> tail
    case None{}: tail

def head_key(head: Ast.SyntaxTerm) -> Maybe<&2, String>:
  match head:
    case Ast.TermRef{key,  _}: Some{key}
    case Ast.TermBang{term,  _}: head_key(term)
    case _: None{}

def wrapped_prefix(args: List<&2, Ast.SyntaxTerm>) -> Maybe<&2, List<&2, Ast.SyntaxTerm>>:
  match args:
    case Ast.TermTemplate{term,  _} <> rest:
      wrapped_prefix_cons(term, wrapped_prefix(rest))
    case _: Some{Nil{}}

def wrapped_prefix_cons(term: Ast.SyntaxTerm, result: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> Maybe<&2, List<&2, Ast.SyntaxTerm>>:
  match result:
    case Some{value}: Some{term <> value}
    case None{}: None{}

def collect_actual_terms(terms: List<&2, Ast.SyntaxTerm>, tail: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match terms:
    case Nil{}: tail
    case +term <> rest: collect_actual_term(term, collect_actual_terms(rest, tail))

def first_actual(left: List<&2, List<&2, Ast.SyntaxTerm>>, right: List<&2, List<&2, Ast.SyntaxTerm>>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  List.append(&2, List<&2, Ast.SyntaxTerm>, left, right)

def native_match_collect_actual_declarations_0(+v_9: Ast.TopLevel, v_13: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match v_9:
    case Ast.DefTop{Ast.Definition{_, v_21, v_22, v_23, _, _}}:
      collect_actual_definition(v_21, v_22, v_23, v_13, has_template_binder(v_21))
    case Ast.TypeTop{Ast.TypeDecl{_, v_34, v_35, v_36, _}}:
      collect_actual_binders(v_34, collect_actual_term(v_35, collect_actual_constructors(v_36, v_13)))
    case Ast.LawTop{Ast.LawDecl{_, v_46, v_47, _}}:
      collect_actual_clauses(v_46, collect_actual_term(v_47, v_13))

def native_match_collect_actual_declarations_1(v_1: List<&2, Ast.TopLevel>, v_4: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match v_1:
    case []:
      v_4
    case +v_9 <> v_10:
      v_13 = collect_actual_declarations(v_10, v_4)
      native_match_collect_actual_declarations_0(v_9, v_13)

def collect_actual_declarations(v_1: List<&2, Ast.TopLevel>, v_4: List<&2, ActualSite>) -> List<&2, ActualSite>:
  native_match_collect_actual_declarations_1(v_1, v_4)

def collect_actual_definition(binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, body: Ast.DefBody, tail: List<&2, ActualSite>, is_template: Bool) -> List<&2, ActualSite>:
  match is_template:
    case True{}: tail
    case False{}:
      collect_actual_binders(binders, collect_actual_optional(result, collect_actual_body(body, tail)))

def collect_actual_body(body: Ast.DefBody, tail: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match body:
    case Ast.DefTerm{term}: collect_actual_term(term, tail)
    case Ast.DefImports{_}: tail

def collect_actual_modules(modules: List<&2, Loader.LoadedModule>, catalog: List<&2, Loader.LoadedModule>) -> List<&2, ActualModule>:
  match modules:
    case Nil{}: Nil{}
    case Loader.LoadedModule{namespace, Ast.Module{_, imports, declarations}} <> rest:
      collect_actual_module(namespace, imports, collect_actual_declarations(declarations, Nil{}), catalog, collect_actual_modules(rest, catalog))

def collect_actual_module(namespace: String, imports: List<&2, Ast.ModuleImport>, sites: List<&2, ActualSite>, catalog: List<&2, Loader.LoadedModule>, tail: List<&2, ActualModule>) -> List<&2, ActualModule>:
  match sites:
    case Nil{}: tail
    case +_ <> _:
      ActualModule{namespace, imports, sites, scope_capture_names(namespace, imports, catalog)} <> tail

# Expansion still uses the requesting template suffix (`templates` is the list
# starting at the template currently being generated), so the scoped context is
# rebuilt from that suffix. Only the template-independent lookup is hoisted:
# find_template depends on the key and the same suffix for every module.
def actual_in_catalog(catalog: List<&2, ActualModule>, template_key: String, templates: List<&2, TemplateDef>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  actual_in_catalog_found(catalog, template_key, templates, find_template(template_key, templates))

def native_match_actual_in_catalog_found_0(v_26: List<&2, List<&2, Ast.SyntaxTerm>>, v_4: String, v_7: List<&2, TemplateDef>, v_10: Maybe<&2, TemplateDef>, v_18: String, v_19: List<&2, Ast.ModuleImport>, v_21: List<&2, CaptureName>, v_22: List<&2, ActualModule>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match v_26:
    case []:
      actual_in_catalog_found(v_22, v_4, v_7, v_10)
    case +_ <> _:
      v_35 = templates_with_captures(visible_templates(v_18, v_19, v_7), v_21)
      first_actual(expand_actual_values(v_26, v_35, v_21), actual_in_catalog_found(v_22, v_4, v_7, v_10))

def native_match_actual_in_catalog_found_1(v_2: List<&2, ActualModule>, v_4: String, v_7: List<&2, TemplateDef>, v_10: Maybe<&2, TemplateDef>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match v_2:
    case []:
      []
    case ActualModule{v_18, v_19, v_20, v_21} <> v_22:
      v_26 = actual_in_aliases(v_20, template_aliases_found(v_18, v_19, v_4, v_10))
      native_match_actual_in_catalog_found_0(v_26, v_4, v_7, v_10, v_18, v_19, v_21, v_22)

def actual_in_catalog_found(v_2: List<&2, ActualModule>, v_4: String, v_7: List<&2, TemplateDef>, v_10: Maybe<&2, TemplateDef>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  native_match_actual_in_catalog_found_1(v_2, v_4, v_7, v_10)

def template_aliases_found(namespace: String, imports: List<&2, Ast.ModuleImport>, template_key: String, found: Maybe<&2, TemplateDef>) -> List<&2, String>:
  match found:
    case None{}: [template_key]
    case Some{ TemplateDef{ _,  owner,  _,  _,  _,  _, _}}:
      local = strip_namespace(template_key, owner)
      local_names = template_local_alias(namespace, owner, local, String.eq(namespace, owner))
      List.append(&2, String, [template_key], List.append(&2, String, local_names, imported_alias_names(namespace, imports, owner, local)))

def template_local_alias(namespace: String, owner: String, local: String, is_local: Bool) -> List<&2, String>:
  match is_local:
    case True{}: [local]
    case False{}: Nil{}

def imported_alias_names(namespace: String, imports: List<&2, Ast.ModuleImport>, owner: String, local: String) -> List<&2, String>:
  match imports:
    case Nil{}: Nil{}
    case +item <> rest:
      match item:
        case Ast.ModuleImport{path, alias,  _}:
          imported_alias_match(namespace, rest, owner, local, alias, String.eq(Path.namespace(namespace, path), owner))

def imported_alias_match(namespace: String, rest: List<&2, Ast.ModuleImport>, owner: String, local: String, alias: String, matches: Bool) -> List<&2, String>:
  match matches:
    case True{}: (alias ++ "." ++ local) <> imported_alias_names(namespace, rest, owner, local)
    case False{}: imported_alias_names(namespace, rest, owner, local)

def actual_in_aliases(sites: List<&2, ActualSite>, aliases: List<&2, String>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match aliases:
    case Nil{}: Nil{}
    case +alias <> rest: first_actual(actual_sites_for_key(sites, alias), actual_in_aliases(sites, rest))

def native_match_actual_sites_for_key_0(v_14: Bool, v_4: String, v_11: List<&2, Ast.SyntaxTerm>, v_12: List<&2, ActualSite>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match v_14:
    case True{}:
      v_11 <> actual_sites_for_key(v_12, v_4)
    case False{}:
      actual_sites_for_key(v_12, v_4)

def native_match_actual_sites_for_key_1(v_2: List<&2, ActualSite>, v_4: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match v_2:
    case []:
      []
    case ActualSite{v_10, v_11} <> v_12:
      native_match_actual_sites_for_key_0(String.eq(v_4, v_10), v_4, v_11, v_12)

def actual_sites_for_key(v_2: List<&2, ActualSite>, v_4: String) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  native_match_actual_sites_for_key_1(v_2, v_4)

def expand_actual_values(actuals: List<&2, List<&2, Ast.SyntaxTerm>>, templates: List<&2, TemplateDef>, captures: List<&2, CaptureName>) -> List<&2, List<&2, Ast.SyntaxTerm>>:
  match actuals:
    case Nil{}: Nil{}
    case +values <> rest: capture_terms(expand_terms(values, templates), captures) <> expand_actual_values(rest, templates, captures)

def collect_actual_binders(binders: List<&2, Ast.TelescopeItem>, tail: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match binders:
    case Nil{}: tail
    case +binder <> rest:
      match binder:
        case Ast.Binder{_, _, _, ty, _}: collect_actual_term(ty, collect_actual_binders(rest, tail))
        case Ast.TemplateBinder{_, _, ty, _}: collect_actual_term(ty, collect_actual_binders(rest, tail))

def collect_actual_optional(value: Ast.OptionalTerm, tail: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match value:
    case Ast.NoTerm{}: tail
    case Ast.SomeTerm{term}: collect_actual_term(term, tail)

def collect_actual_constructors(constructors: List<&2, Ast.ConstructorDecl>, tail: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match constructors:
    case Nil{}: tail
    case Ast.Constructor{_, fields, _} <> rest:
      collect_actual_binders(fields, collect_actual_constructors(rest, tail))

def collect_actual_clauses(clauses: List<&2, Ast.Clause>, tail: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match clauses:
    case Nil{}: tail
    case Ast.ClauseFor{_, _, _, ty, condition, _} <> rest:
      collect_actual_term(ty, collect_actual_maybe(condition, collect_actual_clauses(rest, tail)))

def collect_actual_maybe(value: Maybe<&2, Ast.SyntaxTerm>, tail: List<&2, ActualSite>) -> List<&2, ActualSite>:
  match value:
    case None{}: tail
    case Some{value}: collect_actual_term(value, tail)

def has_string(value: String, values: List<&2, String>) -> Bool:
  match values:
    case Nil{}: False{}
    case +found <> rest:
      has_string_match(value, found, rest, String.eq(value, found))

def has_string_match(value: String, found: String, rest: List<&2, String>, matches: Bool) -> Bool:
  match matches:
    case True{}: True{}
    case False{}: has_string(value, rest)

def has_top_key(key: String, declarations: List<&2, Ast.TopLevel>) -> Bool:
  match declarations:
    case Nil{}: False{}
    case +declaration <> rest:
      match declaration:
        case Ast.DefTop{ Ast.Definition{ found,  _,  _,  _,  _,  _}}:
          Bool.or(String.eq(key, found), has_top_key(key, rest))
        case Ast.TypeTop{ Ast.TypeDecl{ found,  _,  _,  _,  _}}:
          Bool.or(String.eq(key, found), has_top_key(key, rest))
        case Ast.LawTop{ Ast.LawDecl{ found,  _,  _,  _}}:
          Bool.or(String.eq(key, found), has_top_key(key, rest))

def find_generated_identity(key: String, identities: List<&2, GeneratedIdentity>) -> Maybe<&2, GeneratedIdentity>:
  match identities:
    case Nil{}: None{}
    case +entry <> rest:
      match entry:
        case GeneratedIdentity{ found,  _,  _,  _}:
          find_generated_identity_match(key, entry, rest, found, String.eq(key, found))

def find_generated_identity_match(key: String, entry: GeneratedIdentity, rest: List<&2, GeneratedIdentity>, found: String, matches: Bool) -> Maybe<&2, GeneratedIdentity>:
  match matches:
    case True{}: Some{entry}
    case False{}: find_generated_identity(key, rest)

def template_span(template: TemplateDef) -> Ast.SourceSpan:
  match template:
    case TemplateDef{ _,  _,  _,  _,  _,  Ast.Definition{_, _, _, _, _, span}, _}: span

def generated_actuals(template: TemplateDef, actuals: List<&2, List<&2, Ast.SyntaxTerm>>, existing: List<&2, Ast.TopLevel>, identities: List<&2, GeneratedIdentity>) -> GeneratedBuild:
  match actuals:
    case Nil{}: GeneratedBuild{ Nil{}, identities,  None{}}
    case +values <> rest:
      # actual_in_catalog already expanded each value under the requesting
      # module's scoped, captured context built from this same template suffix.
      # Re-expanding it with that suffix's raw list cannot specialize anything
      # new: the scoped context already carried every canonical suffix entry
      # plus the local/imported alias forms, capture only renames references
      # (never arity or TermTemplate wrappers), and applications of templates
      # outside this suffix stay unspecialized in both passes. Reuse the value.
      template_key = template_name(template)
      identity = encode_string(template_key) ++ serialize_terms(values)
      local_key = generated_local_key_for_identity(template, identity)
      canonical_key = generated_canonical_key(template, local_key)
      generated_actual_case(template, rest, existing, identities, template_key, identity, local_key, canonical_key, values, find_generated_identity(canonical_key, identities))

def template_name(template: TemplateDef) -> String:
  match template:
    case TemplateDef{key, _, _, _, _, _, _}: key

def generated_actual_case(template: TemplateDef, rest: List<&2, List<&2, Ast.SyntaxTerm>>, existing: List<&2, Ast.TopLevel>, identities: List<&2, GeneratedIdentity>, template_key: String, identity: String, local_key: String, canonical_key: String, values: List<&2, Ast.SyntaxTerm>, previous: Maybe<&2, GeneratedIdentity>) -> GeneratedBuild:
  match previous:
    case Some{ GeneratedIdentity{ _,  _,  _,  found_identity}}:
      generated_identity_collision(template, rest, existing, identities, identity, found_identity, String.eq(identity, found_identity))
    case None{}: generated_actual_new(template, rest, existing, identities, template_key, identity, local_key, canonical_key, values, has_top_key(local_key, existing))

def generated_identity_collision(template: TemplateDef, rest: List<&2, List<&2, Ast.SyntaxTerm>>, existing: List<&2, Ast.TopLevel>, identities: List<&2, GeneratedIdentity>, identity: String, found_identity: String, matches: Bool) -> GeneratedBuild:
  match matches:
    case False{}: GeneratedBuild{ Nil{}, identities, Some{template_span(template)}}
    case True{}: generated_actuals(template, rest, existing, identities)

def generated_actual_new(template: TemplateDef, rest: List<&2, List<&2, Ast.SyntaxTerm>>, existing: List<&2, Ast.TopLevel>, identities: List<&2, GeneratedIdentity>, template_key: String, identity: String, local_key: String, canonical_key: String, values: List<&2, Ast.SyntaxTerm>, collision: Bool) -> GeneratedBuild:
  match collision:
    case True{}: GeneratedBuild{ Nil{}, identities, Some{template_span(template)}}
    case False{}:
      definition = specialize_definition(template, local_key, values)
      entry = GeneratedIdentity{ canonical_key, template_key, local_key, identity}
      generated_actual_complete(definition, generated_actuals(template, rest, existing, entry <> identities))

def generated_actual_complete(definition: Ast.Definition, result: GeneratedBuild) -> GeneratedBuild:
  match result:
    case GeneratedBuild{ rest_definitions, next_identities, collision}: GeneratedBuild{ Ast.DefTop{definition} <> rest_definitions, next_identities, collision}

# Loader namespaces need not uniquely identify a source module. Generation
# belongs to the original declaration's file and key, never a namespace peer.
def template_source_span_equal(a: Ast.SourceSpan, b: Ast.SourceSpan) -> Bool:
  match a b:
    case Ast.SpanOf{af, ab, ae} Ast.SpanOf{bf, bb, be}:
      Bool.and(String.eq(af, bf), Bool.and(Nat.is_eq(ab, bb), Nat.is_eq(ae, be)))

def native_match_has_template_source_definition_0(v_30: Bool, v_1: String, v_2: Ast.SourceSpan, v_19: List<&2, Ast.TopLevel>) -> Bool:
  match v_30:
    case True{}:
      True{}
    case False{}:
      has_template_source_definition(v_1, v_2, v_19)

def native_match_has_template_source_definition_1(v_29: Bool, v_1: String, v_2: Ast.SourceSpan, v_18: Ast.SourceSpan, v_19: List<&2, Ast.TopLevel>) -> Bool:
  match v_29:
    case True{}:
      native_match_has_template_source_definition_0(template_source_span_equal(v_2, v_18), v_1, v_2, v_19)
    case False{}:
      has_template_source_definition(v_1, v_2, v_19)

def native_match_has_template_source_definition_2(v_4: List<&2, Ast.TopLevel>, v_1: String, v_2: Ast.SourceSpan) -> Bool:
  match v_4:
    case []:
      False{}
    case Ast.DefTop{Ast.Definition{v_13, _, _, _, _, v_18}} <> v_19:
      native_match_has_template_source_definition_1(String.eq(v_1, v_13), v_1, v_2, v_18, v_19)
    case +_ <> v_26:
      has_template_source_definition(v_1, v_2, v_26)

def has_template_source_definition(v_1: String, v_2: Ast.SourceSpan, v_4: List<&2, Ast.TopLevel>) -> Bool:
  native_match_has_template_source_definition_2(v_4, v_1, v_2)

def native_match_template_owned_by_module_0(v_41: Bool, v_5: List<&2, Ast.TopLevel>, v_26: String, v_31: Ast.SourceSpan) -> Bool:
  match v_41:
    case False{}:
      False{}
    case True{}:
      has_template_source_definition(v_26, v_31, v_5)

def native_match_template_owned_by_module_1(v_31: Ast.SourceSpan, v_3: String, v_5: List<&2, Ast.TopLevel>, v_26: String) -> Bool:
  match v_31:
    case Ast.SpanOf{v_36, _, _}:
      native_match_template_owned_by_module_0(String.eq(v_3, v_36), v_5, v_26, v_31)

def native_match_template_owned_by_module_2(v_40: Bool, v_3: String, v_5: List<&2, Ast.TopLevel>, v_26: String, v_31: Ast.SourceSpan) -> Bool:
  match v_40:
    case False{}:
      False{}
    case True{}:
      native_match_template_owned_by_module_1(v_31, v_3, v_5, v_26)

def native_match_template_owned_by_module_3(v_7: TemplateDef, v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>) -> Bool:
  match v_7:
    case TemplateDef{_, v_22, _, _, _, Ast.Definition{v_26, _, _, _, _, v_31}, _}:
      native_match_template_owned_by_module_2(String.eq(v_1, v_22), v_3, v_5, v_26, v_31)

def template_owned_by_module(v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_7: TemplateDef) -> Bool:
  native_match_template_owned_by_module_3(v_7, v_1, v_3, v_5)

def generated_for_module(namespace: String, path: String, declarations: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, catalog: List<&2, ActualModule>, identities: List<&2, GeneratedIdentity>) -> GeneratedBuild:
  match templates:
    case Nil{}: GeneratedBuild{ Nil{}, identities,  None{}}
    case +template <> rest:
      match template:
        case TemplateDef{template_key, _, _, _, _, _, _}:
          generated_for_module_match(namespace, path, declarations, templates, catalog, identities, template, template_key, rest, template_owned_by_module(namespace, path, declarations, template))

def generated_for_module_match(namespace: String, path: String, declarations: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, catalog: List<&2, ActualModule>, identities: List<&2, GeneratedIdentity>, template: TemplateDef, template_key: String, rest: List<&2, TemplateDef>, is_owner: Bool) -> GeneratedBuild:
  match is_owner:
    case False{}: generated_for_module(namespace, path, declarations, rest, catalog, identities)
    case True{}:
      generated_for_module_here(namespace, path, declarations, templates, catalog, identities, rest, generated_actuals(template, actual_in_catalog(catalog, template_key, templates), declarations, identities))

def generated_for_module_here(namespace: String, path: String, declarations: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, catalog: List<&2, ActualModule>, identities: List<&2, GeneratedIdentity>, rest: List<&2, TemplateDef>, here: GeneratedBuild) -> GeneratedBuild:
  match here:
    case GeneratedBuild{ here_definitions, here_identities, Some{span}}: GeneratedBuild{here_definitions, here_identities, Some{span}}
    case GeneratedBuild{ here_definitions, here_identities, None{}}:
      generated_for_module_merge(here_definitions, generated_for_module(namespace, path, declarations, rest, catalog, here_identities))

def generated_for_module_merge(here_definitions: List<&2, Ast.TopLevel>, rest: GeneratedBuild) -> GeneratedBuild:
  match rest:
    case GeneratedBuild{rest_definitions, rest_identities, collision}: GeneratedBuild{List.append(&2, Ast.TopLevel, here_definitions, rest_definitions), rest_identities, collision}

def generate_round(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> GeneratedRound:
  match templates:
    case Nil{}: GeneratedRound{modules, False{}, identities, None{}}
    case +_ <> _: generate_scoped_round(modules, collect_actual_modules(modules, modules), templates, identities)

def generate_scoped_round(modules: List<&2, Loader.LoadedModule>, catalog: List<&2, ActualModule>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> GeneratedRound:
  match modules:
    case Nil{}: GeneratedRound{ Nil{},  False{}, identities,  None{}}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  Ast.Module{path, imports, declarations}}:
          generate_round_loaded(namespace, path, imports, declarations, rest, catalog, templates, generated_for_module(namespace, path, declarations, templates, catalog, identities))

def generate_round_loaded(namespace: String, path: String, imports: List<&2, Ast.ModuleImport>, declarations: List<&2, Ast.TopLevel>, rest: List<&2, Loader.LoadedModule>, catalog: List<&2, ActualModule>, templates: List<&2, TemplateDef>, generated: GeneratedBuild) -> GeneratedRound:
  match generated:
    case GeneratedBuild{definitions, next_identities, build_collision}:
      generate_round_merge(namespace, path, imports, declarations, definitions, build_collision, generate_scoped_round(rest, catalog, templates, next_identities))

def generate_round_merge(namespace: String, path: String, imports: List<&2, Ast.ModuleImport>, declarations: List<&2, Ast.TopLevel>, definitions: List<&2, Ast.TopLevel>, build_collision: Maybe<&2, Ast.SourceSpan>, next: GeneratedRound) -> GeneratedRound:
  match next:
    case GeneratedRound{next_modules, changed, final_identities, next_collision}:
      GeneratedRound{
        Loader.LoadedModule{namespace, Ast.Module{path, imports, List.append(&2, Ast.TopLevel, declarations, definitions)}} <> next_modules,
        Bool.or(changed, Bool.not(List.is_empty(&2, Ast.TopLevel, definitions))),
        final_identities,
        first_invalid(build_collision, next_collision)
      }

def generate_until_stable(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> GeneratedRound:
  generate_until_result(templates, generate_round(modules, templates, identities))

def generate_until_result(templates: List<&2, TemplateDef>, result: GeneratedRound) -> GeneratedRound:
  match result:
    case GeneratedRound{ next,  _,  next_identities,  Some{ span}}:
      GeneratedRound{ next,  False{},  next_identities,  Some{ span}}
    case GeneratedRound{ next,  True{},  next_identities,  None{}}:
      generate_until_stable(next, templates, next_identities)
    case GeneratedRound{ next,  False{},  next_identities,  None{}}:
      GeneratedRound{ next,  False{},  next_identities,  None{}}

def visible_templates(namespace: String, imports: List<&2, Ast.ModuleImport>, templates: List<&2, TemplateDef>) -> List<&2, TemplateDef>:
  List.append(&2, TemplateDef, local_templates(namespace, templates), List.append(&2, TemplateDef, imported_templates(namespace, imports, templates), templates))

def local_templates(namespace: String, templates: List<&2, TemplateDef>) -> List<&2, TemplateDef>:
  match templates:
    case Nil{}: Nil{}
    case +template <> rest:
      match template:
        case TemplateDef{key,  owner, imports, existing_keys,  _, definition, _}:
          local_template_match(namespace, rest, key, owner, imports, existing_keys, definition, String.eq(namespace, owner))

def local_template_match(namespace: String, rest: List<&2, TemplateDef>, key: String, owner: String, imports: List<&2, Ast.ModuleImport>, existing_keys: List<&2, String>, definition: Ast.Definition, is_local: Bool) -> List<&2, TemplateDef>:
  match is_local:
    case True{}: TemplateDef{key, owner, imports, existing_keys, strip_namespace(key, owner), definition, Nil{}} <> local_templates(namespace, rest)
    case False{}: local_templates(namespace, rest)

def imported_templates(namespace: String, imports: List<&2, Ast.ModuleImport>, templates: List<&2, TemplateDef>) -> List<&2, TemplateDef>:
  match imports:
    case Nil{}: Nil{}
    case +item <> rest:
      match item:
        case Ast.ModuleImport{path, alias,  _}:
          target = Path.namespace(namespace, path)
          List.append(&2, TemplateDef, imported_from(target, alias, templates), imported_templates(namespace, rest, templates))

def imported_from(target: String, alias: String, templates: List<&2, TemplateDef>) -> List<&2, TemplateDef>:
  match templates:
    case Nil{}: Nil{}
    case +template <> rest:
      match template:
        case TemplateDef{key,  owner, imports, existing_keys,  _, definition, _}:
          imported_from_match(target, alias, rest, key, owner, imports, existing_keys, definition, String.eq(target, owner))

def imported_from_match(target: String, alias: String, rest: List<&2, TemplateDef>, key: String, owner: String, imports: List<&2, Ast.ModuleImport>, existing_keys: List<&2, String>, definition: Ast.Definition, is_owner: Bool) -> List<&2, TemplateDef>:
  match is_owner:
    case True{}:
      local = strip_namespace(key, owner)
      (TemplateDef{key, owner, imports, existing_keys, alias ++ "." ++ local, definition, Nil{}}) <> imported_from(target, alias, rest)
    case False{}: imported_from(target, alias, rest)

def expand_modules(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> List<&2, Loader.LoadedModule>:
  expand_scoped_modules(modules, modules, templates, identities)

def expand_scoped_modules(modules: List<&2, Loader.LoadedModule>, catalog: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, identities: List<&2, GeneratedIdentity>) -> List<&2, Loader.LoadedModule>:
  match modules:
    case Nil{}: Nil{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  Ast.Module{path, imports, declarations}}:
          context = scoped_templates(namespace, imports, templates, catalog)
          expanded = strip_template_decls(namespace, declarations, context, identities)
          Loader.LoadedModule{namespace,  Ast.Module{path, imports,  expanded}} <> expand_scoped_modules(rest, catalog, templates, identities)
 

def has_late_template_binder(binders: List<&2, Ast.TelescopeItem>, saw_runtime: Bool) -> Bool:
  match binders:
    case Nil{}: False{}
    case +binder <> rest:
      match binder:
        case Ast.TemplateBinder{ _,  _,  _,  _}:
          Bool.or(saw_runtime, has_late_template_binder(rest, saw_runtime))
        case Ast.Binder{ _,  _,  _,  _,  _}:
          has_late_template_binder(rest, True{})

def invalid_template_definitions(modules: List<&2, Loader.LoadedModule>) -> Maybe<&2, Ast.SourceSpan>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{_, Ast.Module{_, _, declarations}}:
          first_invalid(invalid_template_decls(declarations), invalid_template_definitions(rest))

def invalid_template_decls(declarations: List<&2, Ast.TopLevel>) -> Maybe<&2, Ast.SourceSpan>:
  match declarations:
    case Nil{}: None{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{_, binders, _, _, _, span}}:
          invalid_template_decl(binders, span, rest, has_late_template_binder(binders, False{}))
        case _: invalid_template_decls(rest)

def invalid_template_decl(binders: List<&2, Ast.TelescopeItem>, span: Ast.SourceSpan, rest: List<&2, Ast.TopLevel>, invalid: Bool) -> Maybe<&2, Ast.SourceSpan>:
  match invalid:
    case True{}: Some{span}
    case False{}: invalid_template_decls(rest)

def invalid_application(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:

  match term:
    case Ast.TermRef{key, span}:
      invalid_reference(span, find_template(key, templates))
    case Ast.TermApp{ _,  _,  _}:
      invalid_application_spine(term, templates, flatten_application(term))
    case Ast.TermTemplate{ inner, span}: first_invalid(Some{span}, invalid_application(inner, templates))
    case Ast.TermBang{ inner,  _}: invalid_application(inner, templates)
    case Ast.TermSub{_, value, body, _}: first_invalid(invalid_application(value, templates), invalid_application(body, templates))
    case Ast.TermLet{_, _, _, values, body, _}: first_invalid(invalid_terms(values, templates), invalid_application(body, templates))
    case Ast.TermAnn{ inner, ty,  _}: first_invalid(invalid_application(inner, templates), invalid_application(ty, templates))
    case Ast.TermType{kind,  _}: invalid_application(kind, templates)
    case Ast.TermMin{left, right,  _}: first_invalid(invalid_application(left, templates), invalid_application(right, templates))
    case Ast.TermAll{_, _, _, ty, body, _}: first_invalid(invalid_application(ty, templates), invalid_application(body, templates))
    case Ast.TermLam{_, _, _, body, _}: invalid_application(body, templates)
    case Ast.TermAdt{_, args, _, _}: invalid_terms(args, templates)
    case Ast.TermFill{head, args,  _}: first_invalid(invalid_application(head, templates), invalid_terms(args, templates))
    case Ast.TermPlus{head, args,  _}: first_invalid(invalid_application(head, templates), invalid_terms(args, templates))
    case Ast.TermCtr{_, args, _}: invalid_terms(args, templates)
    case Ast.TermString{_, _, _}: None{}
    case Ast.TermMat{_, head, matched, _}: first_invalid(invalid_application(head, templates), invalid_application(matched, templates))
    case Ast.TermEqual{left, right, ty,  _}: first_invalid(invalid_application(left, templates), first_invalid(invalid_application(right, templates), invalid_application(ty, templates)))
    case Ast.TermRewrite{equation, proof, body,  _}: first_invalid(invalid_application(equation, templates), first_invalid(invalid_application(proof, templates), invalid_application(body, templates)))
    case Ast.BodyMatch{scrutinees, cases,  _}: first_invalid(invalid_terms(scrutinees, templates), invalid_terms(cases, templates))
    case Ast.BodyCase{_, body, _}: invalid_application(body, templates)
    case Ast.BodyLocal{_, _, values, body, _}: first_invalid(invalid_terms(values, templates), invalid_application(body, templates))
    case Ast.BodyReply{ inner,  _}: invalid_application(inner, templates)
    case _: None{}

def invalid_reference(span: Ast.SourceSpan, found: Maybe<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match found:
    case Some{ _}: Some{span}
    case None{}: None{}

def invalid_application_spine(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>, spine: ApplicationSpine) -> Maybe<&2, Ast.SourceSpan>:
  match spine:
    case ApplicationSpine{head, args, span}:
      invalid_application_head(term, templates, head, args, span, template_for_head(head, templates))

def invalid_application_head(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>, head: Ast.SyntaxTerm, args: List<&2, Ast.SyntaxTerm>, span: Ast.SourceSpan, found: Maybe<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match found:
    case Some{ template}:
      arity = template_arity(template)
      invalid_application_arity(args, arity, span, templates, Nat.is_ge(List.length(&2, Ast.SyntaxTerm, args), arity))
    case None{}: invalid_application_parts(term, templates)

def invalid_application_arity(args: List<&2, Ast.SyntaxTerm>, arity: Nat, span: Ast.SourceSpan, templates: List<&2, TemplateDef>, enough: Bool) -> Maybe<&2, Ast.SourceSpan>:
  match enough:
    case False{}: Some{span}
    case True{}: invalid_application_arguments(args, arity, span, templates, take_template_args(args, arity))

def invalid_application_arguments(args: List<&2, Ast.SyntaxTerm>, arity: Nat, span: Ast.SourceSpan, templates: List<&2, TemplateDef>, values: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> Maybe<&2, Ast.SourceSpan>:
  match values:
    case None{}: Some{span}
    case Some{_}: first_invalid(invalid_template_args(args, arity, span, templates), invalid_terms(drop_args(args, arity), templates))

def invalid_application_parts(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match term:
    case Ast.TermApp{fn, arg, _}: first_invalid(invalid_application(fn, templates), invalid_application(arg, templates))
    case _: None{}

def invalid_template_args(args: List<&2, Ast.SyntaxTerm>, count: Nat, app_span: Ast.SourceSpan, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match args count:
    case _ 0n: None{}
    case Ast.TermTemplate{+term, _} <> rest 1n+more:
      invalid_template_argument(term, rest, (1n + more : Nat), app_span, templates, has_open_vars(term, 0n))
    case _ _: Some{app_span}

def invalid_template_argument(term: Ast.SyntaxTerm, rest: List<&2, Ast.SyntaxTerm>, count: Nat, app_span: Ast.SourceSpan, templates: List<&2, TemplateDef>, has_open: Bool) -> Maybe<&2, Ast.SourceSpan>:
  match has_open:
    case True{}: Some{app_span}
    case False{}:
      first_invalid(first_invalid(invalid_application(term, templates), invalid_capture_context(term, templates)), invalid_template_args(rest, (count - 1n : Nat), app_span, templates))

# An unresolved caller name must not acquire a meaning merely because the
# generated definition's owner happens to declare that spelling.
def invalid_capture_context(term: Ast.SyntaxTerm, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match templates:
    case Nil{}: None{}
    case +template <> _: invalid_capture(term, template_capture_names(template))

def native_match_invalid_capture_key_0(v_12: Maybe<&2, String>, v_4: Ast.SourceSpan) -> Maybe<&2, Ast.SourceSpan>:
  match v_12:
    case Some{_}:
      None{}
    case None{}:
      Some{v_4}

def invalid_capture_key(v_1: String, v_3: Bool, v_4: Ast.SourceSpan, v_7: List<&2, CaptureName>) -> Maybe<&2, Ast.SourceSpan>:
  native_match_invalid_capture_key_0(capture_name(v_1, v_3, v_7, None{}), v_4)

def invalid_capture_strings(keys: List<&2, String>, span: Ast.SourceSpan, captures: List<&2, CaptureName>) -> Maybe<&2, Ast.SourceSpan>:
  match keys:
    case Nil{}: None{}
    case +key <> rest: first_invalid(invalid_capture_key(key, True{}, span, captures), invalid_capture_strings(rest, span, captures))

def invalid_capture_patterns(patterns: List<&2, Ast.SyntaxPattern>, captures: List<&2, CaptureName>) -> Maybe<&2, Ast.SourceSpan>:
  match patterns:
    case Nil{}: None{}
    case Ast.PatternVar{_, _, _, _} <> rest: invalid_capture_patterns(rest, captures)
    case Ast.PatternCtr{key, fields, span} <> rest:
      first_invalid(invalid_capture_key(key, True{}, span, captures), first_invalid(invalid_capture_patterns(fields, captures), invalid_capture_patterns(rest, captures)))

def invalid_capture_terms(terms: List<&2, Ast.SyntaxTerm>, captures: List<&2, CaptureName>) -> Maybe<&2, Ast.SourceSpan>:
  match terms:
    case Nil{}: None{}
    case +term <> rest: first_invalid(invalid_capture(term, captures), invalid_capture_terms(rest, captures))

# Validate only constructors present in the historical sugar, in its preorder.
# In particular an empty literal does not require Char/Word/Bool constructors.
def invalid_capture_string_bit(zero: Bool, names: Ast.StringLiteralNames, span: Ast.SourceSpan, captures: List<&2, CaptureName>) -> Maybe<&2, Ast.SourceSpan>:
  match zero names:
    case True{} Ast.StringLiteralNames{_, _, _, _, _, _, bit_false, _}: invalid_capture_key(bit_false, True{}, span, captures)
    case False{} Ast.StringLiteralNames{_, _, _, _, _, _, _, bit_true}: invalid_capture_key(bit_true, True{}, span, captures)

def invalid_capture_string_word(remaining: Nat, +value: U32, +names: Ast.StringLiteralNames, +span: Ast.SourceSpan, +captures: List<&2, CaptureName>) -> Maybe<&2, Ast.SourceSpan>:
  match remaining names:
    case 0n Ast.StringLiteralNames{_, _, _, _, word_nil, _, _, _}: invalid_capture_key(word_nil, True{}, span, captures)
    case 1n+rest Ast.StringLiteralNames{_, _, _, _, _, word_cons, _, _}:
      first_invalid(invalid_capture_key(word_cons, True{}, span, captures), first_invalid(invalid_capture_string_bit(U32.is_zero(U32.and(value, 1)), names, span, captures), invalid_capture_string_word(rest, U32.shr(value), names, span, captures)))

def invalid_capture_string(chars: List<&2, U32>, +names: Ast.StringLiteralNames, +span: Ast.SourceSpan, +captures: List<&2, CaptureName>) -> Maybe<&2, Ast.SourceSpan>:
  match chars names:
    case Nil{} Ast.StringLiteralNames{nil, _, _, _, _, _, _, _}: invalid_capture_key(nil, True{}, span, captures)
    case value <> rest Ast.StringLiteralNames{_, cons, char, uint, _, _, _, _}:
      first_invalid(invalid_capture_key(cons, True{}, span, captures), first_invalid(invalid_capture_key(char, True{}, span, captures), first_invalid(invalid_capture_key(uint, True{}, span, captures), first_invalid(invalid_capture_string_word(32n, value, names, span, captures), invalid_capture_string(rest, names, span, captures)))))

def invalid_capture(term: Ast.SyntaxTerm, captures: List<&2, CaptureName>) -> Maybe<&2, Ast.SourceSpan>:
  match term:
    case Ast.TermRef{key, span}: invalid_capture_key(reference_key(key), False{}, span, captures)
    case Ast.TermBang{inner, _}: invalid_capture(inner, captures)
    case Ast.TermSub{_, value, body, _}: first_invalid(invalid_capture(value, captures), invalid_capture(body, captures))
    case Ast.TermLet{_, _, _, values, body, _}: first_invalid(invalid_capture_terms(values, captures), invalid_capture(body, captures))
    case Ast.TermAnn{inner, ty, _}: first_invalid(invalid_capture(inner, captures), invalid_capture(ty, captures))
    case Ast.TermTemplate{inner, _}: invalid_capture(inner, captures)
    case Ast.TermType{kind, _}: invalid_capture(kind, captures)
    case Ast.TermMin{left, right, _}: first_invalid(invalid_capture(left, captures), invalid_capture(right, captures))
    case Ast.TermAll{_, _, _, ty, body, _}: first_invalid(invalid_capture(ty, captures), invalid_capture(body, captures))
    case Ast.TermLam{_, _, _, body, _}: invalid_capture(body, captures)
    case Ast.TermApp{fn, arg, _}: first_invalid(invalid_capture(fn, captures), invalid_capture(arg, captures))
    case Ast.TermAdt{key, args, refs, span}:
      first_invalid(invalid_capture_key(key, False{}, span, captures), first_invalid(invalid_capture_terms(args, captures), invalid_capture_strings(refs, span, captures)))
    case Ast.TermFill{head, args, _}: first_invalid(invalid_capture(head, captures), invalid_capture_terms(args, captures))
    case Ast.TermPlus{head, args, _}: first_invalid(invalid_capture(head, captures), invalid_capture_terms(args, captures))
    case Ast.TermCtr{key, args, span}: first_invalid(invalid_capture_key(key, True{}, span, captures), invalid_capture_terms(args, captures))
    case Ast.TermString{chars, names, span}: invalid_capture_string(chars, names, span, captures)
    case Ast.TermMat{key, head, matched, span}:
      first_invalid(invalid_capture_key(key, True{}, span, captures), first_invalid(invalid_capture(head, captures), invalid_capture(matched, captures)))
    case Ast.TermEqual{left, right, ty, _}: first_invalid(invalid_capture(left, captures), first_invalid(invalid_capture(right, captures), invalid_capture(ty, captures)))
    case Ast.TermRewrite{equation, proof, body, _}: first_invalid(invalid_capture(equation, captures), first_invalid(invalid_capture(proof, captures), invalid_capture(body, captures)))
    case Ast.BodyMatch{scrutinees, cases, _}: first_invalid(invalid_capture_terms(scrutinees, captures), invalid_capture_terms(cases, captures))
    case Ast.BodyCase{patterns, body, _}: first_invalid(invalid_capture_patterns(patterns, captures), invalid_capture(body, captures))
    case Ast.BodyLocal{patterns, _, values, body, _}:
      first_invalid(invalid_capture_patterns(patterns, captures), first_invalid(invalid_capture_terms(values, captures), invalid_capture(body, captures)))
    case Ast.BodyReply{inner, _}: invalid_capture(inner, captures)
    case _: None{}

def has_open_vars(term: Ast.SyntaxTerm, depth: Nat) -> Bool:
  match term:
    case Ast.TermVar{_, index, _}: Nat.is_ge(index, depth)
    case Ast.TermSub{_, value, body, _}: Bool.or(has_open_vars(value, depth), has_open_vars(body, (depth + 1n : Nat)))
    case Ast.TermLet{keys, _, _, values, body, _}: Bool.or(has_open_vars_terms(values, depth), has_open_vars(body, (depth + List.length(&2, String, keys) : Nat)))
    case Ast.TermAnn{ value, ty,  _}: Bool.or(has_open_vars(value, depth), has_open_vars(ty, depth))
    case Ast.TermTemplate{ value,  _}: has_open_vars(value, depth)
    case Ast.TermBang{ inner,  _}: has_open_vars(inner, depth)
    case Ast.TermType{kind,  _}: has_open_vars(kind, depth)
    case Ast.TermMin{left, right,  _}: Bool.or(has_open_vars(left, depth), has_open_vars(right, depth))
    case Ast.TermAll{_, _, _, ty, body, _}: Bool.or(has_open_vars(ty, depth), has_open_vars(body, (depth + 1n : Nat)))
    case Ast.TermLam{_, _, _, body, _}: has_open_vars(body, (depth + 1n : Nat))
    case Ast.TermApp{fn, arg,  _}: Bool.or(has_open_vars(fn, depth), has_open_vars(arg, depth))
    case Ast.TermAdt{_, args, _, _}: has_open_vars_terms(args, depth)
    case Ast.TermFill{head, args,  _}: Bool.or(has_open_vars(head, depth), has_open_vars_terms(args, depth))
    case Ast.TermPlus{head, args,  _}: Bool.or(has_open_vars(head, depth), has_open_vars_terms(args, depth))
    case Ast.TermCtr{_, args, _}: has_open_vars_terms(args, depth)
    case Ast.TermString{_, _, _}: False{}
    case Ast.TermMat{_, head, matched, _}: Bool.or(has_open_vars(head, depth), has_open_vars(matched, depth))
    case Ast.TermEqual{left, right, ty,  _}: Bool.or(has_open_vars(left, depth), Bool.or(has_open_vars(right, depth), has_open_vars(ty, depth)))
    case Ast.TermRewrite{equation, proof, body,  _}: Bool.or(has_open_vars(equation, depth), Bool.or(has_open_vars(proof, depth), has_open_vars(body, depth)))
    case Ast.BodyMatch{scrutinees, cases,  _}: Bool.or(has_open_vars_terms(scrutinees, depth), has_open_vars_terms(cases, depth))
    case Ast.BodyCase{patterns, body,  _}: has_open_vars(body, (depth + Core.pattern_list_depth(patterns) : Nat))
    case Ast.BodyLocal{patterns, _, values, body, _}: Bool.or(has_open_vars_terms(values, depth), has_open_vars(body, (depth + Core.pattern_list_depth(patterns) : Nat)))
    case Ast.BodyReply{ value,  _}: has_open_vars(value, depth)
    case _: False{}

def has_open_vars_terms(terms: List<&2, Ast.SyntaxTerm>, depth: Nat) -> Bool:
  match terms:
    case Nil{}: False{}
    case +term <> rest: Bool.or(has_open_vars(term, depth), has_open_vars_terms(rest, depth))
def invalid_terms(terms: List<&2, Ast.SyntaxTerm>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match terms:
    case Nil{}: None{}
    case +term <> rest: first_invalid(invalid_application(term, templates), invalid_terms(rest, templates))

def first_invalid(left: Maybe<&2, Ast.SourceSpan>, right: Maybe<&2, Ast.SourceSpan>) -> Maybe<&2, Ast.SourceSpan>:
  match left:
    case Some{value}: Some{value}
    case None{}: right

def invalid_definitions(declarations: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match declarations:
    case Nil{}: None{}
    case +decl <> rest:
      match decl:
        case Ast.DefTop{ Ast.Definition{_, binders, result, body, _, _}}:
          invalid_definition(binders, result, body, rest, templates, has_template_binder(binders))
        case Ast.TypeTop{ Ast.TypeDecl{_, params, kind, constructors, _}}:
          first_invalid(first_invalid(invalid_binders(params, templates), invalid_application(kind, templates)), first_invalid(invalid_constructors(constructors, templates), invalid_definitions(rest, templates)))
        case Ast.LawTop{ Ast.LawDecl{_, clauses, body, _}}:
          first_invalid(first_invalid(invalid_clauses(clauses, templates), invalid_application(body, templates)), invalid_definitions(rest, templates))

def invalid_definition(binders: List<&2, Ast.TelescopeItem>, result: Ast.OptionalTerm, body: Ast.DefBody, rest: List<&2, Ast.TopLevel>, templates: List<&2, TemplateDef>, is_template: Bool) -> Maybe<&2, Ast.SourceSpan>:
  match is_template:
    case True{}: invalid_definitions(rest, templates)
    case False{}:
      invalid_body = invalid_def_body(body, templates)
      first_invalid(first_invalid(invalid_binders(binders, templates), invalid_optional(result, templates)), first_invalid(invalid_body, invalid_definitions(rest, templates)))

def invalid_def_body(body: Ast.DefBody, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match body:
    case Ast.DefTerm{term}: invalid_application(term, templates)
    case Ast.DefImports{_}: None{}

def invalid_optional(value: Ast.OptionalTerm, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match value:
    case Ast.NoTerm{}: None{}
    case Ast.SomeTerm{term}: invalid_application(term, templates)

def invalid_binders(binders: List<&2, Ast.TelescopeItem>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match binders:
    case Nil{}: None{}
    case +item <> rest:
      match item:
        case Ast.Binder{_, _, _, ty, _}: first_invalid(invalid_application(ty, templates), invalid_binders(rest, templates))
        case Ast.TemplateBinder{_, _, ty, _}: first_invalid(invalid_application(ty, templates), invalid_binders(rest, templates))

def invalid_constructors(constructors: List<&2, Ast.ConstructorDecl>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match constructors:
    case Nil{}: None{}
    case +constructor <> rest:
      match constructor:
        case Ast.Constructor{_, fields, _}: first_invalid(invalid_binders(fields, templates), invalid_constructors(rest, templates))

def invalid_clauses(clauses: List<&2, Ast.Clause>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match clauses:
    case Nil{}: None{}
    case +clause <> rest:
      match clause:
        case Ast.ClauseFor{_, _, _, ty, condition, _}: first_invalid(invalid_application(ty, templates), first_invalid(invalid_maybe(condition, templates), invalid_clauses(rest, templates)))

def invalid_maybe(value: Maybe<&2, Ast.SyntaxTerm>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match value:
    case None{}: None{}
    case Some{value}: invalid_application(value, templates)

def expand(modules: List<&2, Loader.LoadedModule>) -> ExpandResult:
  template_expand_templates(modules, collect_templates(modules), invalid_template_definitions(modules))

def template_expand_templates(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, template_error: Maybe<&2, Ast.SourceSpan>) -> ExpandResult:
  match template_error:
    case Some{span}: ExpandFailure{"template binders must precede runtime binders", span}
    case None{}:
      template_expand_modules(modules, templates, invalid_modules(modules, templates))

def template_expand_modules(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>, module_error: Maybe<&2, Ast.SourceSpan>) -> ExpandResult:
  match module_error:
    case Some{span}: ExpandFailure{"template application requires a compile-time template argument", span}
    case None{}:
      template_expand_round(templates, generate_until_stable(modules, templates, Nil{}))

# Generated definitions are appended after the source declarations of their
# template owner (generate_round_merge). Source declarations already passed the
# pre-generation invalid_modules pass with the same templates; appending defs
# whose local keys begin "T~" cannot change a source declaration's result,
# because the lexer admits only alpha/digit/'_'/'.' in names, so no source key
# or reference can equal a generated canonical or visible name, and capture
# resolution for existing keys is order-stable. The full modules stay the
# capture catalog; only the unchanged-and-already-valid source declarations are
# skipped, preserving the first generated failure and its span.
def native_match_generated_declarations_0(v_24: Bool, +v_5: Ast.TopLevel, v_6: List<&2, Ast.TopLevel>) -> List<&2, Ast.TopLevel>:
  match v_24:
    case True{}:
      v_5 <> generated_declarations(v_6)
    case False{}:
      generated_declarations(v_6)

def native_match_generated_declarations_1(+v_5: Ast.TopLevel, v_6: List<&2, Ast.TopLevel>) -> List<&2, Ast.TopLevel>:
  match v_5:
    case Ast.DefTop{Ast.Definition{v_13, _, _, _, _, _}}:
      native_match_generated_declarations_0(String.starts_with(v_13, "T~"), v_5, v_6)
    case _:
      generated_declarations(v_6)

def native_match_generated_declarations_2(v_1: List<&2, Ast.TopLevel>) -> List<&2, Ast.TopLevel>:
  match v_1:
    case []:
      []
    case +v_5 <> v_6:
      native_match_generated_declarations_1(v_5, v_6)

def generated_declarations(v_1: List<&2, Ast.TopLevel>) -> List<&2, Ast.TopLevel>:
  native_match_generated_declarations_2(v_1)

def generated_modules(modules: List<&2, Loader.LoadedModule>) -> List<&2, Loader.LoadedModule>:
  match modules:
    case Nil{}: Nil{}
    case Loader.LoadedModule{namespace, Ast.Module{path, imports, declarations}} <> rest:
      Loader.LoadedModule{namespace, Ast.Module{path, imports, generated_declarations(declarations)}} <> generated_modules(rest)

def template_expand_round(templates: List<&2, TemplateDef>, generated: GeneratedRound) -> ExpandResult:
  match generated:
    case GeneratedRound{modules, _, _, Some{span}}: ExpandFailure{"template specialization hash collision", span}
    case GeneratedRound{modules, _, identities, None{}}:
      template_expand_generated(modules, identities, templates, invalid_scoped_modules(generated_modules(modules), modules, templates))

def template_expand_generated(modules: List<&2, Loader.LoadedModule>, identities: List<&2, GeneratedIdentity>, templates: List<&2, TemplateDef>, module_error: Maybe<&2, Ast.SourceSpan>) -> ExpandResult:
  match module_error:
    case Some{span}: ExpandFailure{"template application requires a closed compile-time argument", span}
    case None{}: ExpandSuccess{expand_modules(modules, templates, identities)}

def invalid_modules(modules: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  invalid_scoped_modules(modules, modules, templates)

def invalid_scoped_modules(modules: List<&2, Loader.LoadedModule>, catalog: List<&2, Loader.LoadedModule>, templates: List<&2, TemplateDef>) -> Maybe<&2, Ast.SourceSpan>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace,  Ast.Module{ _, imports, declarations}}:
          context = scoped_templates(namespace, imports, templates, catalog)
          first_invalid(invalid_definitions(declarations, context), invalid_scoped_modules(rest, catalog, templates))
