import Base
import ../bend2/selfhost/ast.bend as AST
import ../bend2/selfhost/path.bend as Path
import ../bend2/selfhost/loaded_module.bend as Loader
import ../bend2/selfhost/index_lookup.bend as IndexLookup

type EmitResult is Data:
  EmitSuccess{source: String}
  EmitFailure{message: String, span: AST.SourceSpan}

# A closure keeps dependent types in their declaration/lexical scope. Extending
# an environment never rewrites (or accidentally captures) a signature.
# Modules are the checker's elaborated output: law completion is not repeated
# here. Telescope closures share the original AST instead of synthesizing
# lambda/arrow nodes or substituting a whole dependent signature per argument.
# Original owners, not inferred closures, are indexed once per emission. Value
# and constructor hits use flat maps; only type owners need ordered fallback.
# Module-local first owners still block later same-module declarations.
type EmitConstructorOwner is Data:
  EmitConstructorOwner{family: AST.TypeDecl, constructor: AST.ConstructorDecl}
# Alias layouts share resolved namespaces, prefixes and metadata source across
# every scope for a module. The path index is built once, with first-owner wins.
type EmitAlias is Data:
  EmitAlias{alias: String, prefix: String, namespace: String, length: Nat}
# This shared layout records Base authority and exact operation identities.
# Missing entries are negative results, not suffix-based fallbacks.
type EmitAliases is Data:
  EmitAliases{entries: List<&2, EmitAlias>, source: String, native: Bool, operations: Map<&2, String>}
type EmitModuleIndex is Data:
  EmitModuleIndex{namespace: String, imports: EmitAliases, values: Map<&2, AST.Definition>, constructors: Map<&2, EmitConstructorOwner>, types: Map<&2, List<&2, AST.TopLevel>>}
type EmitCatalog is Data:
  EmitCatalog{layouts: List<&2, EmitModuleIndex>, values: Map<&2, EmitModuleIndex>, constructors: Map<&2, EmitModuleIndex>, types: Map<&2, List<&2, EmitModuleIndex>>}
type EmitScope is Data:
  EmitScope{namespace: String, imports: EmitAliases, catalog: EmitCatalog}
# Captures are self-recursive, not mutually recursive through EmitEnv/Binding.
# Their parallel lists share the original environment tails; env_bind and
# env_insert_binding extend all three lists together.
type EmitClosure is Data:
  EmitClosure{term: AST.SyntaxTerm, scope: EmitScope, names: List<&2, String>, types: List<&2, Maybe<&2, EmitClosure>>, values: List<&2, Maybe<&2, EmitClosure>>, depth: Nat}
  EmitInferred{binders: List<&2, AST.TelescopeItem>, body: AST.SyntaxTerm, scope: EmitScope, names: List<&2, String>, types: List<&2, Maybe<&2, EmitClosure>>, values: List<&2, Maybe<&2, EmitClosure>>, depth: Nat}
  EmitDeclared{binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, scope: EmitScope, names: List<&2, String>, types: List<&2, Maybe<&2, EmitClosure>>, values: List<&2, Maybe<&2, EmitClosure>>, depth: Nat}
  EmitDefinition{key: String, binders: List<&2, AST.TelescopeItem>, body: AST.SyntaxTerm, scope: EmitScope, names: List<&2, String>, types: List<&2, Maybe<&2, EmitClosure>>, values: List<&2, Maybe<&2, EmitClosure>>, depth: Nat}
type EmitEnv is Data:
  EmitEnv{scope: EmitScope, names: List<&2, String>, types: List<&2, Maybe<&2, EmitClosure>>, values: List<&2, Maybe<&2, EmitClosure>>, depth: Nat}
type EmitBinding is Data:
  EmitBinding{name: String, ty: Maybe<&2, EmitClosure>, value: Maybe<&2, EmitClosure>}
type EmitPatternResult is Data:
  EmitMatched{env: EmitEnv}
  EmitDifferent{}
  EmitNeutral{}
type EmitConstructor is Data:
  EmitConstructor{key: String, family: String, params: List<&2, AST.TelescopeItem>, fields: List<&2, AST.TelescopeItem>, env: EmitEnv}
type EmitTypeDefinition is Data:
  EmitTypeDefinition{key: String, binders: List<&2, AST.TelescopeItem>, body: AST.SyntaxTerm, env: EmitEnv}
type EmitTypeNeeded is Data:
  EmitTypeNeeded{definitions: List<&2, EmitTypeDefinition>, seen: Map<&2, Bool>}
type EmitSwitchRow is Data:
  EmitSwitchRow{tag: String, term: AST.SyntaxTerm}
type EmitNamed is Data:
  EmitNamed{key: String, definition: AST.Definition, env: EmitEnv}
  EmitNamedNative{key: String, binders: List<&2, AST.TelescopeItem>, env: EmitEnv}
  EmitNamedBlocked{}
type EmitPrimitive is Data:
  EmitPrimitive{parameters: List<&2, String>, body: String}
def js_value_indices(modules: List<&2, Loader.LoadedModule>) -> EmitCatalog:
  js_catalog(js_value_indices_at(modules, js_namespace_indices(modules), modules))
def js_catalog(+layouts: List<&2, EmitModuleIndex>) -> EmitCatalog:
  js_catalog_at(layouts, EmitCatalog{layouts, MTip{}, MTip{}, MTip{}})
def js_catalog_at(remaining: List<&2, EmitModuleIndex>, catalog: EmitCatalog) -> EmitCatalog:
  match remaining:
    case Nil{}: catalog
    case +layout <> rest: js_catalog_module(layout, js_catalog_at(rest, catalog))
def js_catalog_module(+layout: EmitModuleIndex, catalog: EmitCatalog) -> EmitCatalog:
  match layout catalog:
    case EmitModuleIndex{_, _, values, constructors, types} EmitCatalog{layouts, value_owners, constructor_owners, type_owners}:
      EmitCatalog{layouts, js_catalog_values(values, layout, value_owners), js_catalog_constructors(constructors, layout, constructor_owners), js_catalog_types(types, layout, type_owners)}
def js_catalog_values(entries: Map<&2, AST.Definition>, layout: EmitModuleIndex, owners: Map<&2, EmitModuleIndex>) -> Map<&2, EmitModuleIndex>:
  match entries:
    case MTip{}: owners
    case MLeaf{key, AST.Definition{_, _, _, AST.DefTerm{_}, _, _}}: Map.set(&2, EmitModuleIndex, owners, key, layout)
    case MLeaf{_, _}: owners
    case MNode{_, lo, hi}: js_catalog_values(lo, layout, js_catalog_values(hi, layout, owners))
def js_catalog_constructors(entries: Map<&2, EmitConstructorOwner>, layout: EmitModuleIndex, owners: Map<&2, EmitModuleIndex>) -> Map<&2, EmitModuleIndex>:
  match entries:
    case MTip{}: owners
    case MLeaf{key, _}: Map.set(&2, EmitModuleIndex, owners, key, layout)
    case MNode{_, lo, hi}: js_catalog_constructors(lo, layout, js_catalog_constructors(hi, layout, owners))
def js_catalog_types(entries: Map<&2, List<&2, AST.TopLevel>>, layout: EmitModuleIndex, owners: Map<&2, List<&2, EmitModuleIndex>>) -> Map<&2, List<&2, EmitModuleIndex>>:
  match entries:
    case MTip{}: owners
    case MLeaf{key, _}: js_catalog_type_insert(IndexLookup.find(List<&2, EmitModuleIndex>, owners, key), key, layout, owners)
    case MNode{_, lo, hi}: js_catalog_types(lo, layout, js_catalog_types(hi, layout, owners))
def js_catalog_type_insert(found: Maybe<&2, List<&2, EmitModuleIndex>>, key: String, layout: EmitModuleIndex, owners: Map<&2, List<&2, EmitModuleIndex>>) -> Map<&2, List<&2, EmitModuleIndex>>:
  match found:
    case None{}: Map.set(&2, List<&2, EmitModuleIndex>, owners, key, [layout])
    case Some{rest}: Map.set(&2, List<&2, EmitModuleIndex>, owners, key, layout <> rest)
def js_catalog_layouts(catalog: EmitCatalog) -> List<&2, EmitModuleIndex>:
  match catalog:
    case EmitCatalog{layouts, _, _, _}: layouts
def js_namespace_indices(modules: List<&2, Loader.LoadedModule>) -> Map<&2, String>:
  match modules:
    case Nil{}: MTip{}
    case Loader.LoadedModule{namespace, AST.Module{path, _, _}} <> rest:
      Map.set(&2, String, js_namespace_indices(rest), Path.normalize(path), namespace)
def js_value_indices_at(modules: List<&2, Loader.LoadedModule>, paths: Map<&2, String>, all_modules: List<&2, Loader.LoadedModule>) -> List<&2, EmitModuleIndex>:
  match modules:
    case Nil{}: Nil{}
    case Loader.LoadedModule{namespace, AST.Module{path, imports, declarations}} <> rest:
      native = js_base_source(path, all_modules)
      EmitModuleIndex{namespace, js_resolved_aliases(js_resolved_alias_entries(imports, paths), native, js_native_operations(native, namespace, declarations)), js_value_declarations(namespace, declarations), js_constructor_indices(namespace, declarations), js_type_indices(namespace, declarations)} <> js_value_indices_at(rest, paths, all_modules)
def js_value_declarations(namespace: String, declarations: List<&2, AST.TopLevel>) -> Map<&2, AST.Definition>:
  match declarations:
    case Nil{}: MTip{}
    case AST.DefTop{definition} <> rest:
      js_value_declaration(definition, namespace, js_value_declarations(namespace, rest))
    case _ <> rest: js_value_declarations(namespace, rest)
def js_value_declaration(+definition: AST.Definition, namespace: String, index: Map<&2, AST.Definition>) -> Map<&2, AST.Definition>:
  match definition:
    case AST.Definition{key, _, _, _, _, _}:
      Map.set(&2, AST.Definition, index, qualify(namespace, key), definition)
def js_constructor_indices(namespace: String, declarations: List<&2, AST.TopLevel>) -> Map<&2, EmitConstructorOwner>:
  match declarations:
    case Nil{}: MTip{}
    case AST.TypeTop{family} <> rest:
      js_constructor_index_family(family, namespace, js_constructor_indices(namespace, rest))
    case _ <> rest: js_constructor_indices(namespace, rest)
def js_constructor_index_family(+family: AST.TypeDecl, namespace: String, index: Map<&2, EmitConstructorOwner>) -> Map<&2, EmitConstructorOwner>:
  match family:
    case AST.TypeDecl{_, _, _, constructors, _}:
      js_constructor_index_items(constructors, family, namespace, index)
def js_constructor_index_items(constructors: List<&2, AST.ConstructorDecl>, +family: AST.TypeDecl, namespace: String, index: Map<&2, EmitConstructorOwner>) -> Map<&2, EmitConstructorOwner>:
  match constructors:
    case Nil{}: index
    case +constructor <> rest:
      match constructor:
        case AST.Constructor{key, _, _}:
          Map.set(&2, EmitConstructorOwner, js_constructor_index_items(rest, family, namespace, index), qualify(namespace, key), EmitConstructorOwner{family, constructor})

# Same-key declarations retain source order. Ordinary laws can fall through,
# while a matching definition or native law still blocks later declarations.
def js_type_indices(namespace: String, declarations: List<&2, AST.TopLevel>) -> Map<&2, List<&2, AST.TopLevel>>:
  match declarations:
    case Nil{}: MTip{}
    case +declaration <> rest:
      js_type_index_declaration(declaration, namespace, js_type_indices(namespace, rest))
def js_type_index_declaration(+declaration: AST.TopLevel, namespace: String, index: Map<&2, List<&2, AST.TopLevel>>) -> Map<&2, List<&2, AST.TopLevel>>:
  match declaration:
    case AST.DefTop{AST.Definition{key, _, _, _, _, _}}:
      js_type_index_insert(qualify(namespace, key), declaration, index)
    case AST.TypeTop{AST.TypeDecl{key, _, _, _, _}}:
      js_type_index_insert(qualify(namespace, key), declaration, index)
    case AST.LawTop{AST.LawDecl{key, _, _, _}}:
      js_type_index_insert(qualify(namespace, key), declaration, index)
def js_type_index_insert(key: String, declaration: AST.TopLevel, +index: Map<&2, List<&2, AST.TopLevel>>) -> Map<&2, List<&2, AST.TopLevel>>:
  js_type_index_found(IndexLookup.find(List<&2, AST.TopLevel>, index, key), key, declaration, index)
def js_type_index_found(found: Maybe<&2, List<&2, AST.TopLevel>>, key: String, declaration: AST.TopLevel, index: Map<&2, List<&2, AST.TopLevel>>) -> Map<&2, List<&2, AST.TopLevel>>:
  match found:
    case None{}: Map.set(&2, List<&2, AST.TopLevel>, index, key, [declaration])
    case Some{rest}: Map.set(&2, List<&2, AST.TopLevel>, index, key, declaration <> rest)

def js_escape_char(char: Char) -> String:
  match char:
    case '\"': "\\\""
    case '\\': "\\\\"
    case '\n': "\\n"
    case '\r': "\\r"
    case '\t': "\\t"
    case '\u{0}': "\\u0000"
    case _: String.from_list([char])

def js_comma_prefix(first: Bool) -> String:
  match first:
    case True{}: ""
    case False{}: ","

def js_quote_chars(chars: List<&2, Char>, acc: String) -> String:
  match chars:
    case Nil{}: String.append(acc, "\"")
    case +char <> rest:
      escaped = js_escape_char(char)
      js_quote_chars(rest, String.append(acc, escaped))

def js_quote(text: String) -> String:
  js_quote_chars(String.to_list(text), "\"")

# Injective ASCII identifiers for statically resolved entries. Dollar and every
# non-alphanumeric/non-underscore scalar are escaped, including separators.
def js_named_identifier_char(plain: Bool, char: Char, code: U32) -> String:
  match plain:
    case True{}: Char.show(char)
    case False{}: String.append("$", String.append(U32.show(code), "$"))
def js_named_identifier_chars(text: String, acc: String) -> String:
  match text:
    case SNil{}: acc
    case SCon{+char, rest}:
      code = Char.to_u32(char)
      plain = Bool.or(U32.is_eq(code, 95), Bool.or(Bool.and(U32.is_ge(code, 48), U32.is_le(code, 57)), Bool.or(Bool.and(U32.is_ge(code, 65), U32.is_le(code, 90)), Bool.and(U32.is_ge(code, 97), U32.is_le(code, 122)))))
      js_named_identifier_chars(rest, String.append(acc, js_named_identifier_char(plain, char, code)))
def js_named_identifier(key: String) -> String:
  js_named_identifier_chars(key, "$u$")


def env_binding(env: EmitEnv, index: Nat) -> Maybe<&2, EmitBinding>:
  match env:
    case EmitEnv{_, names, types, values, _}: env_binding_at(names, types, values, index)
def env_binding_at(names: List<&2, String>, types: List<&2, Maybe<&2, EmitClosure>>, values: List<&2, Maybe<&2, EmitClosure>>, index: Nat) -> Maybe<&2, EmitBinding>:
  match names types values:
    case +name <> more_names +ty <> more_types +value <> more_values:
      match index:
        case 0n: Some{EmitBinding{name, ty, value}}
        case _: env_binding_at(more_names, more_types, more_values, (index - 1n : Nat))
    case _ _ _: None{}
# Computed lookups enter typed helpers so native matches inspect parameters.
def env_at_binding(binding: Maybe<&2, EmitBinding>) -> String:
  match binding:
    case None{}: "undefined"
    case Some{EmitBinding{name, _, _}}: name
def env_at(env: EmitEnv, index: Nat) -> String:
  env_at_binding(env_binding(env, index))
def env_bind(name: String, ty: Maybe<&2, EmitClosure>, value: Maybe<&2, EmitClosure>, env: EmitEnv) -> EmitEnv:
  match env:
    case EmitEnv{scope, names, types, values, depth}: EmitEnv{scope, name <> names, ty <> types, value <> values, (depth + 1n : Nat)}
def env_push(name: String, env: EmitEnv) -> EmitEnv:
  env_bind(name, None{}, None{}, env)
def js_close(term: AST.SyntaxTerm, env: EmitEnv) -> EmitClosure:
  match env:
    case EmitEnv{scope, names, types, values, depth}: EmitClosure{term, scope, names, types, values, depth}
def js_close_inferred(binders: List<&2, AST.TelescopeItem>, body: AST.SyntaxTerm, env: EmitEnv) -> EmitClosure:
  match env:
    case EmitEnv{scope, names, types, values, depth}: EmitInferred{binders, body, scope, names, types, values, depth}
def js_close_declared(binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, env: EmitEnv) -> EmitClosure:
  match env:
    case EmitEnv{scope, names, types, values, depth}: EmitDeclared{binders, result, scope, names, types, values, depth}
def js_close_definition(key: String, binders: List<&2, AST.TelescopeItem>, body: AST.SyntaxTerm, env: EmitEnv) -> EmitClosure:
  match env:
    case EmitEnv{scope, names, types, values, depth}: EmitDefinition{key, binders, body, scope, names, types, values, depth}
def js_closure_env(value: EmitClosure) -> EmitEnv:
  match value:
    case EmitClosure{_, scope, names, types, values, depth}: EmitEnv{scope, names, types, values, depth}
    case EmitInferred{_, _, scope, names, types, values, depth}: EmitEnv{scope, names, types, values, depth}
    case EmitDeclared{_, _, scope, names, types, values, depth}: EmitEnv{scope, names, types, values, depth}
    case EmitDefinition{_, _, _, scope, names, types, values, depth}: EmitEnv{scope, names, types, values, depth}


# Resolve aliases by the same longest-prefix rule as the emitted $key.
def js_scope_key(key: String, scope: EmitScope) -> String:
  match scope:
    case EmitScope{namespace, EmitAliases{entries, _, _, _}, _}:
      js_scope_alias(key, entries, qualify(namespace, key), 0n)
def js_scope_alias(key: String, imports: List<&2, EmitAlias>, found: String, length: Nat) -> String:
  match imports:
    case Nil{}: found
    case EmitAlias{_, prefix, namespace, prefix_length} <> rest:
      js_scope_alias_match(Bool.and(String.starts_with(key, prefix), Nat.is_gt(prefix_length, length)), key, prefix_length, namespace, rest, found, length)
def js_scope_alias_match(matches: Bool, key: String, prefix_length: Nat, namespace: String, rest: List<&2, EmitAlias>, found: String, length: Nat) -> String:
  match matches:
    case False{}: js_scope_alias(key, rest, found, length)
    case True{}:
      js_scope_alias(key, rest, qualify(namespace, String.drop(key, prefix_length)), prefix_length)

def js_global(key: String, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match env:
    case EmitEnv{scope, _, _, _, _}:
      match scope:
        case EmitScope{_, _, catalog}:
          js_global_fallback(js_global_lookup(js_scope_key(key, scope), catalog), key, catalog)
def js_global_fallback(found: Maybe<&2, EmitClosure>, key: String, catalog: EmitCatalog) -> Maybe<&2, EmitClosure>:
  match found:
    case Some{_}: found
    case None{}: js_global_lookup(key, catalog)
def js_global_lookup(key: String, +catalog: EmitCatalog) -> Maybe<&2, EmitClosure>:
  match catalog:
    case EmitCatalog{_, owners, _, _}:
      js_global_owner(IndexLookup.find(EmitModuleIndex, owners, key), key, catalog)
def js_global_owner(found: Maybe<&2, EmitModuleIndex>, key: String, catalog: EmitCatalog) -> Maybe<&2, EmitClosure>:
  match found:
    case None{}: None{}
    case Some{+layout}:
      match layout:
        case EmitModuleIndex{_, _, values, _, _}:
          js_global_definition(IndexLookup.find(AST.Definition, values, key), key, js_owner_env(layout, catalog))
def js_owner_env(layout: EmitModuleIndex, catalog: EmitCatalog) -> EmitEnv:
  match layout:
    case EmitModuleIndex{namespace, imports, _, _, _}:
      EmitEnv{EmitScope{namespace, imports, catalog}, Nil{}, Nil{}, Nil{}, 0n}
def js_global_definition(found: Maybe<&2, AST.Definition>, key: String, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match found:
    case Some{AST.Definition{_, binders, _, AST.DefTerm{term}, _, _}}:
      Some{js_close_definition(key, binders, term, env)}
    case _: None{}

def js_global_type(key: String, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match env:
    case EmitEnv{scope, _, _, _, _}:
      match scope:
        case EmitScope{_, _, catalog}:
          js_global_type_fallback(js_global_type_lookup(js_scope_key(key, scope), catalog), key, catalog)
def js_global_type_fallback(found: Maybe<&2, EmitClosure>, key: String, catalog: EmitCatalog) -> Maybe<&2, EmitClosure>:
  match found:
    case Some{_}: found
    case None{}: js_global_type_lookup(key, catalog)
def js_global_type_lookup(key: String, +catalog: EmitCatalog) -> Maybe<&2, EmitClosure>:
  match catalog:
    case EmitCatalog{_, _, _, owners}:
      js_global_type_owners(IndexLookup.find(List<&2, EmitModuleIndex>, owners, key), key, catalog)
def js_global_type_owners(found: Maybe<&2, List<&2, EmitModuleIndex>>, key: String, catalog: EmitCatalog) -> Maybe<&2, EmitClosure>:
  match found:
    case None{}: None{}
    case Some{owners}: js_global_type_modules(key, owners, catalog)
def js_global_type_modules(key: String, rest: List<&2, EmitModuleIndex>, catalog: EmitCatalog) -> Maybe<&2, EmitClosure>:
  match rest:
    case Nil{}: None{}
    case EmitModuleIndex{namespace, imports, _, _, types} <> more:
      env = EmitEnv{EmitScope{namespace, imports, catalog}, Nil{}, Nil{}, Nil{}, 0n}
      js_global_type_next(js_global_type_index(IndexLookup.find(List<&2, AST.TopLevel>, types, key), env), key, more, catalog)

def js_global_type_next(found: Maybe<&2, EmitClosure>, key: String, rest: List<&2, EmitModuleIndex>, catalog: EmitCatalog) -> Maybe<&2, EmitClosure>:
  match found:
    case Some{_}: found
    case None{}: js_global_type_modules(key, rest, catalog)

def js_global_type_index(found: Maybe<&2, List<&2, AST.TopLevel>>, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match found:
    case None{}: None{}
    case Some{declarations}: js_global_type_decls(declarations, env)

def js_global_type_decls(declarations: List<&2, AST.TopLevel>, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match declarations:
    case Nil{}: None{}
    case AST.DefTop{AST.Definition{_, binders, result, body, _, _}} <> _:
      js_global_type_definition(binders, result, body, env)
    case AST.TypeTop{AST.TypeDecl{_, params, kind, _, _}} <> _:
      Some{js_close_declared(params, AST.SomeTerm{kind}, env)}
    case AST.LawTop{AST.LawDecl{name, clauses, body, _}} <> rest:
      js_global_native_law_operation(js_native_operation(name, env), clauses, body, rest, env)

def js_global_type_definition(binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, body: AST.DefBody, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match result:
    case AST.SomeTerm{_}: Some{js_close_declared(binders, result, env)}
    case AST.NoTerm{}:
      match body:
        case AST.DefTerm{term}: js_type_definition(binders, term, env)
        case AST.DefImports{_}: None{}

def js_global_native_law_operation(operation: Maybe<&2, String>, clauses: List<&2, AST.Clause>, body: AST.SyntaxTerm, rest: List<&2, AST.TopLevel>, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match operation:
    case Some{_}: js_native_law_type(js_native_law_binders(clauses, 0n), body, env)
    case None{}: js_global_type_decls(rest, env)

def js_native_law_type(binders: Maybe<&2, List<&2, AST.TelescopeItem>>, body: AST.SyntaxTerm, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match binders:
    case Some{items}: Some{js_close_declared(items, AST.SomeTerm{body}, env)}
    case None{}: None{}
def js_native_law_binders(clauses: List<&2, AST.Clause>, index: Nat) -> Maybe<&2, List<&2, AST.TelescopeItem>>:
  match clauses:
    case Nil{}: Some{Nil{}}
    case AST.ClauseFor{True{}, quantity, key, ty, None{}, span} <> rest:
      js_native_law_binder(AST.Binder{quantity, key, index, ty, span}, js_native_law_binders(rest, (index + 1n : Nat)))
    case _ <> _: None{}
def js_native_law_binder(binder: AST.TelescopeItem, rest: Maybe<&2, List<&2, AST.TelescopeItem>>) -> Maybe<&2, List<&2, AST.TelescopeItem>>:
  match rest:
    case Some{items}: Some{binder <> items}
    case None{}: None{}
def js_type_definition(binders: List<&2, AST.TelescopeItem>, term: AST.SyntaxTerm, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match binders:
    case Nil{}: js_type(term, env)
    case _: Some{js_close_inferred(binders, term, env)}

# Only type computation is reduced; emitted arguments are never evaluated here.
def js_reduce_env(value: EmitClosure, env: EmitEnv) -> EmitClosure:
  match value:
    case EmitDefinition{_, Nil{}, body, _, _, _, _, _}: js_reduce(js_close(body, env))
    case EmitDefinition{_, _, _, _, _, _, _, _}: value
    case EmitDeclared{Nil{}, AST.SomeTerm{result}, _, _, _, _, _}: js_reduce(js_close(result, env))
    case EmitDeclared{_, _, _, _, _, _, _}: value
    case EmitInferred{Nil{}, body, _, _, _, _, _}: js_reduce_inferred(js_type(body, env), value)
    case EmitInferred{_, _, _, _, _, _, _}: value
    case EmitClosure{term, _, _, _, _, _}:
      match term:
        case AST.TermAnn{inner, _, _}: js_reduce(js_close(inner, env))
        case AST.TermVar{_, index, _}: js_reduce_binding(env_binding(env, index), value)
        case AST.TermRef{key, _}: js_reduce_global(js_global(key, env), value)
        case AST.TermApp{fn, arg, _}: js_reduce_app(js_reduce(js_close(fn, env)), js_close(arg, env), value)
        case AST.TermSub{index, inner, body, _}: js_reduce(js_close(body, env_insert_binding(env, index, EmitBinding{"null", js_type(inner, env), Some{js_close(inner, env)}})))
        case AST.TermLet{_, _, _, values, body, _}: js_reduce(js_close(body, js_value_env(values, env)))
        case AST.BodyReply{inner, _}: js_reduce(js_close(inner, env))
        case AST.BodyLocal{patterns, _, values, body, _}:
          js_reduce_local(js_reduce_patterns(patterns, js_closure_terms(values, env), env), body, value)
        case AST.BodyMatch{scrutinees, cases, _}:
          js_reduce_cases(cases, js_closure_terms(scrutinees, env), env, value)
        case AST.TermRewrite{_, _, body, _}: js_reduce(js_close(body, env))
        case _: value
def js_reduce(value: EmitClosure) -> EmitClosure:
  js_reduce_env(value, js_closure_env(value))
def js_reduce_inferred(found: Maybe<&2, EmitClosure>, original: EmitClosure) -> EmitClosure:
  match found:
    case Some{ty}: js_reduce(ty)
    case None{}: original
def js_reduce_binding(found: Maybe<&2, EmitBinding>, original: EmitClosure) -> EmitClosure:
  match found:
    case Some{EmitBinding{_, _, Some{value}}}: js_reduce(value)
    case _: original
def js_reduce_global(found: Maybe<&2, EmitClosure>, original: EmitClosure) -> EmitClosure:
  match found:
    case None{}: original
    case Some{value}: js_reduce(value)
def js_reduce_app_env(fn: EmitClosure, arg: EmitClosure, original: EmitClosure, env: EmitEnv) -> EmitClosure:
  match fn:
    case EmitClosure{AST.TermLam{_, _, _, body, _}, _, _, _, _, _}:
      js_reduce(js_close(body, env_bind("null", None{}, Some{arg}, env)))
    case EmitDefinition{key, AST.Binder{_, _, _, domain, _} <> rest, body, _, _, _, _, _}:
      js_reduce(js_close_definition(key, rest, body, env_bind("null", Some{js_close(domain, env)}, Some{arg}, env)))
    case _: original
def js_reduce_app(fn: EmitClosure, arg: EmitClosure, original: EmitClosure) -> EmitClosure:
  js_reduce_app_env(fn, arg, original, js_closure_env(fn))
def js_reduce_patterns(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, EmitClosure>, env: EmitEnv) -> EmitPatternResult:
  match patterns values:
    case Nil{} Nil{}: EmitMatched{env}
    case +pattern <> rest +value <> more:
      js_reduce_patterns_next(js_reduce_pattern(pattern, value, env), rest, more)
    case _ _: EmitDifferent{}
def js_reduce_patterns_next(result: EmitPatternResult, patterns: List<&2, AST.SyntaxPattern>, values: List<&2, EmitClosure>) -> EmitPatternResult:
  match result:
    case EmitMatched{env}: js_reduce_patterns(patterns, values, env)
    case _: result
def js_reduce_pattern(pattern: AST.SyntaxPattern, value: EmitClosure, env: EmitEnv) -> EmitPatternResult:
  match pattern:
    case AST.PatternVar{_, _, _, _}: EmitMatched{env_bind("null", None{}, Some{value}, env)}
    case AST.PatternCtr{key, fields, _}: js_reduce_pattern_view(key, fields, js_reduce(value), env)
def js_reduce_pattern_view_env(key: String, fields: List<&2, AST.SyntaxPattern>, value: EmitClosure, env: EmitEnv, value_env: EmitEnv) -> EmitPatternResult:
  match value:
    case EmitClosure{AST.TermCtr{name, args, _}, _, _, _, _, _}:
      js_reduce_pattern_key(js_same_scoped_key(key, env, name, value_env), fields, js_closure_terms(args, value_env), env)
    case EmitClosure{AST.TermString{chars, names, span}, _, _, _, _, _}:
      js_reduce_pattern_view(key, fields, js_close(AST.string_unfold(chars, names, span), value_env), env)
    case _: EmitNeutral{}
def js_reduce_pattern_view(key: String, fields: List<&2, AST.SyntaxPattern>, value: EmitClosure, env: EmitEnv) -> EmitPatternResult:
  js_reduce_pattern_view_env(key, fields, value, env, js_closure_env(value))
def js_same_scoped_key(left: String, left_env: EmitEnv, right: String, right_env: EmitEnv) -> Bool:
  js_same_constructor_key(js_constructor_decl(left, left_env), js_constructor_decl(right, right_env))
def js_same_constructor_key(left: Maybe<&2, EmitConstructor>, right: Maybe<&2, EmitConstructor>) -> Bool:
  match left right:
    case Some{EmitConstructor{left_key, _, _, _, _}} Some{EmitConstructor{right_key, _, _, _, _}}: String.eq(left_key, right_key)
    case _ _: False{}
def js_reduce_pattern_key(equal: Bool, fields: List<&2, AST.SyntaxPattern>, args: List<&2, EmitClosure>, env: EmitEnv) -> EmitPatternResult:
  match equal:
    case True{}: js_reduce_patterns(fields, args, env)
    case False{}: EmitDifferent{}
def js_reduce_local(result: EmitPatternResult, body: AST.SyntaxTerm, original: EmitClosure) -> EmitClosure:
  match result:
    case EmitMatched{env}: js_reduce(js_close(body, env))
    case _: original
def js_reduce_cases(cases: List<&2, AST.SyntaxTerm>, values: List<&2, EmitClosure>, env: EmitEnv, original: EmitClosure) -> EmitClosure:
  match cases:
    case Nil{}: original
    case AST.BodyCase{patterns, body, _} <> rest:
      js_reduce_case_result(js_reduce_patterns(patterns, values, env), body, rest, values, env, original)
    case _ <> rest: js_reduce_cases(rest, values, env, original)
def js_reduce_case_result(result: EmitPatternResult, body: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, values: List<&2, EmitClosure>, env: EmitEnv, original: EmitClosure) -> EmitClosure:
  match result:
    case EmitMatched{bound}: js_reduce(js_close(body, bound))
    case EmitDifferent{}: js_reduce_cases(rest, values, env, original)
    case EmitNeutral{}: original
def js_value_env(values: List<&2, AST.SyntaxTerm>, env: EmitEnv) -> EmitEnv:
  js_value_env_at(values, env, env)
def js_value_env_at(values: List<&2, AST.SyntaxTerm>, source: EmitEnv, env: EmitEnv) -> EmitEnv:
  match values:
    case Nil{}: env
    case +value <> rest:
      js_value_env_at(rest, source, env_bind("null", js_type(value, source), Some{js_close(value, source)}, env))

def js_type(term: AST.SyntaxTerm, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match term:
    case AST.TermVar{_, index, _}: js_binding_type(env_binding(env, index))
    case AST.TermRef{key, _}: js_global_type(key, env)
    case AST.TermAdt{key, args, _, _}: js_apply_type_args(js_global_type(key, env), js_closure_terms(args, env))
    case AST.TermAnn{_, ty, _}: Some{js_close(ty, env)}
    case AST.TermBang{inner, _}: js_type(inner, env)
    case AST.TermPlus{head, Nil{}, _}: js_type(head, env)
    case AST.TermApp{fn, arg, _}: js_apply_type(js_type(fn, env), js_close(arg, env))
    case AST.TermSub{index, value, body, _}: js_type(body, env_insert_binding(env, index, EmitBinding{"null", js_type(value, env), Some{js_close(value, env)}}))
    case AST.TermLet{_, _, _, values, body, _}: js_type(body, js_value_env(values, env))
    case AST.TermRewrite{_, _, body, _}: js_type(body, env)
    case AST.BodyReply{inner, _}: js_type(inner, env)
    case AST.BodyLocal{patterns, _, values, body, _}: js_type_local(patterns, values, body, env)
    case AST.BodyMatch{scrutinees, cases, _}: js_type_cases(cases, scrutinees, env)
    case AST.BodyCase{_, body, _}: js_type(body, env)
    case _: None{}
def js_binding_type(found: Maybe<&2, EmitBinding>) -> Maybe<&2, EmitClosure>:
  match found:
    case Some{EmitBinding{_, None{}, Some{value}}}: js_type_value(value)
    case Some{EmitBinding{_, ty, _}}: ty
    case None{}: None{}
def js_type_value(value: EmitClosure) -> Maybe<&2, EmitClosure>:
  match value:
    case EmitClosure{term, _, _, _, _, _}: js_type(term, js_closure_env(value))
    case _: None{}
def js_type_local(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, AST.SyntaxTerm>, body: AST.SyntaxTerm, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  types = js_pattern_types(patterns, js_scrutinee_types(values, env), env)
  names = patterns_vars(patterns, scrutinee_names(List.length(&2, AST.SyntaxTerm, values), env), env)
  neutral = env_names_typed(names, types, env)
  matched = js_reduce_patterns(patterns, js_closure_terms(values, env), env)
  js_type_local_refined(matched, types, body, env, neutral)
def js_type_local_refined(result: EmitPatternResult, types: List<&2, Maybe<&2, EmitClosure>>, body: AST.SyntaxTerm, source: EmitEnv, neutral: EmitEnv) -> Maybe<&2, EmitClosure>:
  match result source:
    case EmitMatched{EmitEnv{scope, names, _, values, depth}} EmitEnv{_, _, source_types, _, _}:
      refined_types = List.append(&2, Maybe<&2, EmitClosure>, List.reverse(&2, Maybe<&2, EmitClosure>, types), source_types)
      js_type(body, EmitEnv{scope, names, refined_types, values, depth})
    case _ _: js_type(body, neutral)
def js_apply_type_args(found: Maybe<&2, EmitClosure>, args: List<&2, EmitClosure>) -> Maybe<&2, EmitClosure>:
  match args:
    case Nil{}: found
    case +arg <> rest: js_apply_type_args(js_apply_type(found, arg), rest)
def js_apply_type(found: Maybe<&2, EmitClosure>, arg: EmitClosure) -> Maybe<&2, EmitClosure>:
  match found:
    case None{}: None{}
    case Some{ty}: js_apply_type_view(js_reduce(ty), arg)
def js_apply_type_view_env(ty: EmitClosure, arg: EmitClosure, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match ty:
    case EmitClosure{AST.TermAll{_, _, _, domain, body, _}, _, _, _, _, _}:
      Some{js_close(body, env_bind("null", Some{js_close(domain, env)}, Some{arg}, env))}
    case EmitInferred{AST.Binder{_, _, _, domain, _} <> rest, body, _, _, _, _, _}:
      js_type_definition(rest, body, env_bind("null", Some{js_close(domain, env)}, Some{arg}, env))
    case EmitDeclared{AST.Binder{_, _, _, domain, _} <> rest, result, _, _, _, _, _}:
      Some{js_close_declared(rest, result, env_bind("null", Some{js_close(domain, env)}, Some{arg}, env))}
    case _: None{}
def js_apply_type_view(ty: EmitClosure, arg: EmitClosure) -> Maybe<&2, EmitClosure>:
  js_apply_type_view_env(ty, arg, js_closure_env(ty))
def js_type_cases(cases: List<&2, AST.SyntaxTerm>, scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  match cases:
    case Nil{}: None{}
    case AST.BodyCase{patterns, body, _} <> _:
      types = js_pattern_types(patterns, js_scrutinee_types(scrutinees, env), env)
      js_type(body, env_names_typed(patterns_vars(patterns, scrutinee_names(List.length(&2, AST.SyntaxTerm, scrutinees), env), env), types, env))
    case _ <> rest: js_type_cases(rest, scrutinees, env)

def env_insert_binding(env: EmitEnv, index: Nat, binding: EmitBinding) -> EmitEnv:
  match env binding:
    case EmitEnv{scope, names, types, values, depth} EmitBinding{name, ty, value}:
      EmitEnv{scope, env_insert_names(names, index, name), env_insert_closures(types, index, ty), env_insert_closures(values, index, value), (depth + 1n : Nat)}
def env_insert_names(names: List<&2, String>, index: Nat, name: String) -> List<&2, String>:
  match names:
    case Nil{}: [name]
    case +value <> rest:
      match index:
        case 0n: name <> (value <> rest)
        case _: value <> env_insert_names(rest, (index - 1n : Nat), name)
def env_insert_closures(values: List<&2, Maybe<&2, EmitClosure>>, index: Nat, value: Maybe<&2, EmitClosure>) -> List<&2, Maybe<&2, EmitClosure>>:
  match values:
    case Nil{}: [value]
    case +found <> rest:
      match index:
        case 0n: value <> (found <> rest)
        case _: found <> env_insert_closures(rest, (index - 1n : Nat), value)
def env_names_typed(names: List<&2, String>, types: List<&2, Maybe<&2, EmitClosure>>, env: EmitEnv) -> EmitEnv:
  match names types:
    case +name <> rest +ty <> more: env_names_typed(rest, more, env_bind(name, ty, None{}, env))
    case +name <> rest Nil{}: env_names_typed(rest, Nil{}, env_push(name, env))
    case Nil{} _: env
def js_scrutinee_types(terms: List<&2, AST.SyntaxTerm>, env: EmitEnv) -> List<&2, Maybe<&2, EmitClosure>>:
  match terms:
    case Nil{}: Nil{}
    case +term <> rest: js_type(term, env) <> js_scrutinee_types(rest, env)
def js_pattern_types(patterns: List<&2, AST.SyntaxPattern>, types: List<&2, Maybe<&2, EmitClosure>>, env: EmitEnv) -> List<&2, Maybe<&2, EmitClosure>>:
  match patterns types:
    case +pattern <> rest +ty <> more:
      List.append(&2, Maybe<&2, EmitClosure>, js_pattern_type(pattern, ty, env), js_pattern_types(rest, more, env))
    case +pattern <> rest Nil{}:
      List.append(&2, Maybe<&2, EmitClosure>, js_pattern_type(pattern, None{}, env), js_pattern_types(rest, Nil{}, env))
    case Nil{} _: Nil{}
def js_pattern_type(pattern: AST.SyntaxPattern, ty: Maybe<&2, EmitClosure>, env: EmitEnv) -> List<&2, Maybe<&2, EmitClosure>>:
  match pattern:
    case AST.PatternVar{_, _, _, _}: [ty]
    case AST.PatternCtr{key, fields, _}:
      js_pattern_types(fields, js_field_types(js_constructor_signature(key, ty, env)), env)
def js_field_types(found: Maybe<&2, EmitClosure>) -> List<&2, Maybe<&2, EmitClosure>>:
  match found:
    case None{}: Nil{}
    case Some{ty}: js_field_types_view(js_reduce(ty))
def js_field_types_view_env(ty: EmitClosure, env: EmitEnv) -> List<&2, Maybe<&2, EmitClosure>>:
  match ty:
    case EmitClosure{AST.TermAll{_, _, _, domain, body, _}, _, _, _, _, _}:
      Some{js_close(domain, env)} <> js_field_types(Some{js_close(body, env_bind("null", Some{js_close(domain, env)}, None{}, env))})
    case EmitDeclared{AST.Binder{_, _, _, domain, _} <> rest, result, _, _, _, _, _}:
      Some{js_close(domain, env)} <> js_field_types(Some{js_close_declared(rest, result, env_bind("null", Some{js_close(domain, env)}, None{}, env))})
    case _: Nil{}
def js_field_types_view(ty: EmitClosure) -> List<&2, Maybe<&2, EmitClosure>>:
  js_field_types_view_env(ty, js_closure_env(ty))

def js_constructor_decl(key: String, env: EmitEnv) -> Maybe<&2, EmitConstructor>:
  match env:
    case EmitEnv{scope, _, _, _, _}:
      match scope:
        case EmitScope{_, _, catalog}:
          js_constructor_decl_fallback(js_constructor_lookup(js_scope_key(key, scope), catalog), key, catalog)
def js_constructor_decl_fallback(found: Maybe<&2, EmitConstructor>, key: String, catalog: EmitCatalog) -> Maybe<&2, EmitConstructor>:
  match found:
    case Some{_}: found
    case None{}: js_constructor_lookup(key, catalog)
def js_constructor_lookup(key: String, +catalog: EmitCatalog) -> Maybe<&2, EmitConstructor>:
  match catalog:
    case EmitCatalog{_, _, owners, _}:
      js_constructor_index_owner(IndexLookup.find(EmitModuleIndex, owners, key), key, catalog)
def js_constructor_index_owner(found: Maybe<&2, EmitModuleIndex>, key: String, catalog: EmitCatalog) -> Maybe<&2, EmitConstructor>:
  match found:
    case None{}: None{}
    case Some{+layout}:
      match layout:
        case EmitModuleIndex{_, _, _, constructors, _}:
          js_constructor_owner(IndexLookup.find(EmitConstructorOwner, constructors, key), key, js_owner_env(layout, catalog))
def js_constructor_owner(found: Maybe<&2, EmitConstructorOwner>, key: String, env: EmitEnv) -> Maybe<&2, EmitConstructor>:
  match found:
    case Some{EmitConstructorOwner{AST.TypeDecl{family, params, _, _, _}, AST.Constructor{_, fields, _}}}:
      Some{EmitConstructor{key, family, params, fields, env}}
    case None{}: None{}
def js_constructor_signature(key: String, ty: Maybe<&2, EmitClosure>, env: EmitEnv) -> Maybe<&2, EmitClosure>:
  js_constructor_signature_found(js_constructor_decl(key, env), ty)
def js_constructor_signature_found(found: Maybe<&2, EmitConstructor>, ty: Maybe<&2, EmitClosure>) -> Maybe<&2, EmitClosure>:
  match found:
    case None{}: None{}
    case Some{EmitConstructor{_, _, params, fields, env}}:
      js_constructor_parameter_types(params, fields, env, js_family_parameter_arguments(params, ty))
def js_family_parameter_arguments(params: List<&2, AST.TelescopeItem>, ty: Maybe<&2, EmitClosure>) -> List<&2, EmitClosure>:
  match ty:
    case None{}: Nil{}
    case Some{value}: js_family_parameter_view(params, js_reduce(value))
def js_family_parameter_view_env(params: List<&2, AST.TelescopeItem>, value: EmitClosure, env: EmitEnv) -> List<&2, EmitClosure>:
  match value:
    case EmitClosure{AST.TermFill{head, args, span}, _, _, _, _, _}:
      supplied = List.append(&2, EmitClosure, js_family_arguments_view(js_close(head, env)), js_closure_terms(args, env))
      js_family_fill_arguments(params, supplied, AST.QOne{}, span, env)
    case EmitClosure{AST.TermPlus{head, args, span}, _, _, _, _, _}:
      supplied = List.append(&2, EmitClosure, js_family_arguments_view(js_close(head, env)), js_closure_terms(args, env))
      js_family_fill_arguments(params, supplied, AST.QMany{}, span, env)
    case _: js_family_arguments_view(value)
def js_family_parameter_view(params: List<&2, AST.TelescopeItem>, value: EmitClosure) -> List<&2, EmitClosure>:
  js_family_parameter_view_env(params, value, js_closure_env(value))
def js_family_arguments_view_env(value: EmitClosure, env: EmitEnv) -> List<&2, EmitClosure>:
  match value:
    case EmitClosure{AST.TermAdt{_, args, _, _}, _, _, _, _, _}: js_closure_terms(args, env)
    case EmitClosure{AST.TermApp{fn, arg, _}, _, _, _, _, _}:
      List.append(&2, EmitClosure, js_family_arguments_view(js_close(fn, env)), [js_close(arg, env)])
    case EmitClosure{AST.TermAnn{inner, _, _}, _, _, _, _, _}: js_family_arguments_view(js_close(inner, env))
    case _: Nil{}
def js_family_arguments_view(value: EmitClosure) -> List<&2, EmitClosure>:
  js_family_arguments_view_env(value, js_closure_env(value))
def js_family_fill_arguments(params: List<&2, AST.TelescopeItem>, supplied: List<&2, EmitClosure>, quantity: AST.Quantity, span: AST.SourceSpan, env: EmitEnv) -> List<&2, EmitClosure>:
  count = js_family_quant_prefix(params, env)
  js_family_fill_missing(Nat.is_eq((List.length(&2, EmitClosure, supplied) + count : Nat), List.length(&2, AST.TelescopeItem, params)), supplied, count, quantity, span, env)
def js_family_quant_prefix(params: List<&2, AST.TelescopeItem>, env: EmitEnv) -> Nat:
  match params:
    case AST.Binder{_, _, _, domain, _} <> rest:
      js_family_quant_domain(js_reduce(js_close(domain, env)), rest, env)
    case _: 0n
def js_family_quant_domain(domain: EmitClosure, rest: List<&2, AST.TelescopeItem>, env: EmitEnv) -> Nat:
  match domain:
    case EmitClosure{AST.TermQuant{}, _, _, _, _, _}: (1n + js_family_quant_prefix(rest, env_push("null", env)) : Nat)
    case _: 0n
def js_family_fill_missing(missing: Bool, supplied: List<&2, EmitClosure>, count: Nat, quantity: AST.Quantity, span: AST.SourceSpan, env: EmitEnv) -> List<&2, EmitClosure>:
  match missing:
    case True{}: List.append(&2, EmitClosure, js_quantity_closures(count, quantity, span, env), supplied)
    case False{}:
      match quantity:
        case AST.QMany{}: js_family_promote_arguments(supplied, count, span, env)
        case _: supplied
def js_quantity_closures(count: Nat, quantity: AST.Quantity, span: AST.SourceSpan, env: EmitEnv) -> List<&2, EmitClosure>:
  match count:
    case 0n: Nil{}
    case _: js_close(AST.TermQuantity{quantity, span}, env) <> js_quantity_closures((count - 1n : Nat), quantity, span, env)
def js_family_promote_arguments(args: List<&2, EmitClosure>, count: Nat, span: AST.SourceSpan, env: EmitEnv) -> List<&2, EmitClosure>:
  match args count:
    case _ 0n: args
    case +_ <> rest _: js_close(AST.TermQuantity{AST.QMany{}, span}, env) <> js_family_promote_arguments(rest, (count - 1n : Nat), span, env)
    case Nil{} _: Nil{}
def js_closure_terms(terms: List<&2, AST.SyntaxTerm>, env: EmitEnv) -> List<&2, EmitClosure>:
  match terms:
    case Nil{}: Nil{}
    case +term <> rest: js_close(term, env) <> js_closure_terms(rest, env)
def js_constructor_parameter_types(params: List<&2, AST.TelescopeItem>, fields: List<&2, AST.TelescopeItem>, env: EmitEnv, args: List<&2, EmitClosure>) -> Maybe<&2, EmitClosure>:
  match params args:
    case Nil{} _: Some{js_close_declared(fields, AST.NoTerm{}, env)}
    case AST.Binder{_, _, _, domain, _} <> rest +arg <> more:
      js_constructor_parameter_types(rest, fields, env_bind("null", Some{js_close(domain, env)}, Some{arg}, env), more)
    case AST.Binder{_, _, _, domain, _} <> rest Nil{}:
      js_constructor_parameter_types(rest, fields, env_bind("null", Some{js_close(domain, env)}, None{}, env), Nil{})
    case _ _: None{}




def js_choose(key: String, suffix: String, expression: String, other: String) -> String:
  js_choose_result(js_key_matches(key, suffix), expression, other)
def js_key_matches(key: String, name: String) -> Bool:
  Bool.pick(Bool, String.eq(key, name), True{}, Bool.pick(Bool, String.ends_with(key, String.append(".", name)), True{}, String.ends_with(key, String.append("/", name))))
def js_choose_exact(key: String, name: String, expression: String, other: String) -> String:
  js_choose_result(String.eq(key, name), expression, other)

def js_choose_result(matches: Bool, expression: String, other: String) -> String:
  match matches:
    case True{}: expression
    case False{}: other
def js_reference(key: String) -> String:
  String.append("$resolve(", String.append(js_quote(key), ", $scope, $aliases)"))
# Native operation identities are local declaration names, never user suffixes.
def js_native_operations(native: Bool, namespace: String, declarations: List<&2, AST.TopLevel>) -> Map<&2, String>:
  match native:
    case False{}: MTip{}
    case True{}: js_native_operation_declarations(namespace, declarations)
def js_native_operation_declarations(namespace: String, declarations: List<&2, AST.TopLevel>) -> Map<&2, String>:
  match declarations:
    case Nil{}: MTip{}
    case AST.DefTop{AST.Definition{key, _, _, _, _, _}} <> rest:
      js_native_operation_insert_keys(namespace, key, js_native_operation_declarations(namespace, rest))
    case AST.LawTop{AST.LawDecl{key, _, _, _}} <> rest:
      js_native_operation_insert_keys(namespace, key, js_native_operation_declarations(namespace, rest))
    case _ <> rest: js_native_operation_declarations(namespace, rest)
def js_native_operation_insert_keys(namespace: String, key: String, operations: Map<&2, String>) -> Map<&2, String>:
  match namespace:
    case "": js_native_operation_insert(key, operations)
    case _: js_native_operation_insert(qualify(namespace, key), js_native_operation_insert(key, operations))
def js_native_operation_insert(key: String, operations: Map<&2, String>) -> Map<&2, String>:
  js_native_operation_insert_found(js_native_operation_origin(True{}, key), key, operations)
def js_native_operation_insert_found(found: Maybe<&2, String>, key: String, operations: Map<&2, String>) -> Map<&2, String>:
  match found:
    case None{}: operations
    case Some{operation}: Map.set(&2, String, operations, key, operation)
def js_native_operation_origin(native: Bool, key: String) -> Maybe<&2, String>:
  match native:
    case False{}: None{}
    case True{}:
      operation = js_native_operation_name(key)
      js_native_operation_known(js_is_native(operation), operation)
def js_native_operation(key: String, env: EmitEnv) -> Maybe<&2, String>:
  match env:
    case EmitEnv{EmitScope{_, EmitAliases{_, _, _, operations}, _}, _, _, _, _}:
      IndexLookup.find(String, operations, key)
def js_native_operation_known(known: Bool, operation: String) -> Maybe<&2, String>:
  match known:
    case True{}: Some{operation}
    case False{}: None{}
def js_native_operation_name(key: String) -> String:
  chars = String.to_list(String.to_lower(key))
  String.from_list(List.reverse(&2, Char, js_native_operation_chars(chars, Nil{})))
def js_native_operation_chars(chars: List<&2, Char>, acc: List<&2, Char>) -> List<&2, Char>:
  match chars:
    case Nil{}: acc
    case '.' <> rest: js_native_operation_chars(rest, '_' <> acc)
    case '/' <> rest: js_native_operation_chars(rest, '_' <> acc)
    case +char <> rest: js_native_operation_chars(rest, char <> acc)

def suffix_any(key: String, first: String, rest: String) -> Bool:
  Bool.pick(Bool, js_key_matches(key, first), True{}, js_key_matches(key, rest))

def js_native_u32(key: String) -> Bool:
  Bool.pick(Bool, js_native_u32_1(key), True{}, js_native_u32_2(key))
def js_native_u32_1(key: String) -> Bool:
  Bool.pick(Bool, suffix_any(key, "u32_add", "u32_sub"), True{}, Bool.pick(Bool, suffix_any(key, "u32_mul", "u32_div"), True{}, Bool.pick(Bool, suffix_any(key, "u32_mod", "u32_and"), True{}, Bool.pick(Bool, suffix_any(key, "u32_or", "u32_xor"), True{}, Bool.pick(Bool, suffix_any(key, "u32_is_eq", "u32_is_ne"), True{}, suffix_any(key, "u32_is_lt", "u32_is_le"))))))

def js_native_u32_2(key: String) -> Bool:
  Bool.pick(Bool, suffix_any(key, "u32_is_gt", "u32_is_ge"), True{}, Bool.pick(Bool, suffix_any(key, "u32_inc", "u32_not"), True{}, Bool.pick(Bool, suffix_any(key, "u32_shl", "u32_shr"), True{}, Bool.pick(Bool, suffix_any(key, "u32_shln", "u32_shrn"), True{}, Bool.pick(Bool, suffix_any(key, "u32_cmp", "u32_is_zero"), True{}, Bool.pick(Bool, suffix_any(key, "u32_to_nat", "u32_from_nat"), True{}, suffix_any(key, "u32_to_f32", "u32_to_f32")))))))

def js_native_f32(key: String) -> Bool:
  Bool.pick(Bool, js_native_f32_1(key), True{}, js_native_f32_2(key))
def js_native_f32_1(key: String) -> Bool:
  Bool.pick(Bool, suffix_any(key, "f32_add", "f32_sub"), True{}, Bool.pick(Bool, suffix_any(key, "f32_mul", "f32_div"), True{}, Bool.pick(Bool, suffix_any(key, "f32_mod", "f32_neg"), True{}, Bool.pick(Bool, suffix_any(key, "f32_is_eq", "f32_is_ne"), True{}, Bool.pick(Bool, suffix_any(key, "f32_is_lt", "f32_is_le"), True{}, Bool.pick(Bool, suffix_any(key, "f32_is_gt", "f32_is_ge"), True{}, Bool.pick(Bool, suffix_any(key, "f32_sqrt", "f32_abs"), True{}, suffix_any(key, "f32_exp", "f32_log"))))))))

def js_native_f32_2(key: String) -> Bool:
  Bool.pick(Bool, suffix_any(key, "f32_log2", "f32_log10"), True{}, Bool.pick(Bool, suffix_any(key, "f32_sin", "f32_cos"), True{}, Bool.pick(Bool, suffix_any(key, "f32_tan", "f32_pow"), True{}, Bool.pick(Bool, suffix_any(key, "f32_atan2", "f32_floor"), True{}, Bool.pick(Bool, suffix_any(key, "f32_ceil", "f32_trunc"), True{}, Bool.pick(Bool, suffix_any(key, "f32_to_u32", "f32_bits"), True{}, Bool.pick(Bool, suffix_any(key, "f32_show", "f32_read"), True{}, Bool.pick(Bool, suffix_any(key, "u32_to_f32", "u32_to_f32"), True{}, js_native_f32_extra(key)))))))))
def js_native_f32_extra(key: String) -> Bool:
  Bool.pick(Bool, suffix_any(key, "f32_asin", "f32_acos"), True{}, Bool.pick(Bool, suffix_any(key, "f32_atan", "f32_sinh"), True{}, suffix_any(key, "f32_cosh", "f32_tanh")))

def js_native_misc(key: String) -> Bool:
  Bool.pick(Bool, js_native_misc_1(key), True{}, js_native_misc_2(key))
def js_native_misc_1(key: String) -> Bool:
  Bool.or(suffix_any(key, "nat_min", "nat_max"), Bool.or(suffix_any(key, "map_bit", "string_cmp"), Bool.or(suffix_any(key, "string_to_list", "string_eq"), Bool.pick(Bool, suffix_any(key, "nat_add", "nat_sub"), True{}, Bool.pick(Bool, suffix_any(key, "nat_mul", "nat_double"), True{}, Bool.pick(Bool, suffix_any(key, "nat_cmp", "nat_is_lt"), True{}, Bool.pick(Bool, suffix_any(key, "nat_divmod", "string_append"), True{}, suffix_any(key, "string_length", "bool_or"))))))))

def js_native_misc_2(key: String) -> Bool:
  Bool.pick(Bool, suffix_any(key, "bool_xor", "array_new"), True{}, Bool.pick(Bool, suffix_any(key, "array_set", "array_get"), True{}, Bool.pick(Bool, suffix_any(key, "array_swap", "array_size"), True{}, suffix_any(key, "array_clone", "array_clone"))))

def js_is_native(key: String) -> Bool:
  Bool.pick(Bool, js_native_u32(key), True{}, Bool.pick(Bool, js_native_f32(key), True{}, js_native_misc(key)))

# Only decode the exact lambda shapes in the existing primitive expression
# table. Its reachable fallback remains unsupported (notably ordinary F32).
def js_native_primitive(operation: String) -> Maybe<&2, EmitPrimitive>:
  js_native_primitive_shape(js_reference_old(operation))
def js_native_primitive_shape(expression: String) -> Maybe<&2, EmitPrimitive>:
  js_native_primitive_shape_match(String.starts_with(expression, "(a)=>(i)=>(v)=>"), expression)
def js_native_primitive_shape_match(matches: Bool, expression: String) -> Maybe<&2, EmitPrimitive>:
  match matches:
    case True{}: Some{EmitPrimitive{"a" <> "i" <> "v" <> Nil{}, String.drop(expression, 15n)}}
    case False{}: js_native_primitive_binary(expression)
def js_native_primitive_binary(expression: String) -> Maybe<&2, EmitPrimitive>:
  js_native_primitive_binary_match(String.starts_with(expression, "(a)=>(b)=>"), expression)
def js_native_primitive_binary_match(matches: Bool, expression: String) -> Maybe<&2, EmitPrimitive>:
  match matches:
    case True{}: Some{EmitPrimitive{"a" <> "b" <> Nil{}, String.drop(expression, 10n)}}
    case False{}: js_native_primitive_indexed(expression)
def js_native_primitive_indexed(expression: String) -> Maybe<&2, EmitPrimitive>:
  js_native_primitive_indexed_match(String.starts_with(expression, "(a)=>(i)=>"), expression)
def js_native_primitive_indexed_match(matches: Bool, expression: String) -> Maybe<&2, EmitPrimitive>:
  match matches:
    case True{}: Some{EmitPrimitive{"a" <> "i" <> Nil{}, String.drop(expression, 10n)}}
    case False{}: js_native_primitive_position(expression)
def js_native_primitive_position(expression: String) -> Maybe<&2, EmitPrimitive>:
  js_native_primitive_position_match(String.starts_with(expression, "(key)=>(position)=>"), expression)
def js_native_primitive_position_match(matches: Bool, expression: String) -> Maybe<&2, EmitPrimitive>:
  match matches:
    case True{}: Some{EmitPrimitive{"key" <> "position" <> Nil{}, String.drop(expression, 19n)}}
    case False{}: js_native_primitive_unary(expression)
def js_native_primitive_unary(expression: String) -> Maybe<&2, EmitPrimitive>:
  js_native_primitive_unary_match(String.starts_with(expression, "(a)=>"), expression)
def js_native_primitive_unary_match(matches: Bool, expression: String) -> Maybe<&2, EmitPrimitive>:
  match matches:
    case True{}: Some{EmitPrimitive{"a" <> Nil{}, String.drop(expression, 5n)}}
    case False{}: js_native_primitive_text(expression)
def js_native_primitive_text(expression: String) -> Maybe<&2, EmitPrimitive>:
  js_native_primitive_text_match(String.starts_with(expression, "(text)=>"), expression)
def js_native_primitive_text_match(matches: Bool, expression: String) -> Maybe<&2, EmitPrimitive>:
  match matches:
    case True{}: Some{EmitPrimitive{"text" <> Nil{}, String.drop(expression, 8n)}}
    case False{}: None{}
def js_native_primitive_binders(binders: List<&2, AST.TelescopeItem>) -> Maybe<&2, Nat>:
  match binders:
    case Nil{}: Some{0n}
    case AST.Binder{quantity, _, _, _, _} <> rest:
      js_native_primitive_count(js_native_primitive_binders(rest), quantity)
    case AST.TemplateBinder{_, _, _, _} <> _: None{}
def js_native_primitive_count(rest: Maybe<&2, Nat>, quantity: AST.Quantity) -> Maybe<&2, Nat>:
  match rest quantity:
    case Some{count} AST.QZero{}: Some{count}
    case Some{count} _: Some{Nat.add(count, 1n)}
    case None{} _: None{}
def js_native_primitive_checked(operation: Maybe<&2, String>, binders: List<&2, AST.TelescopeItem>) -> Maybe<&2, EmitPrimitive>:
  match operation:
    case None{}: None{}
    case Some{name}: js_native_primitive_arity(js_native_primitive(name), js_native_primitive_binders(binders))
def js_native_primitive_arity(primitive: Maybe<&2, EmitPrimitive>, count: Maybe<&2, Nat>) -> Maybe<&2, EmitPrimitive>:
  match primitive count:
    case Some{EmitPrimitive{parameters, body}} Some{live}:
      js_native_primitive_arity_match(Nat.is_eq(List.length(&2, String, parameters), live), parameters, body)
    case _ _: None{}
def js_native_primitive_arity_match(matches: Bool, parameters: List<&2, String>, body: String) -> Maybe<&2, EmitPrimitive>:
  match matches:
    case True{}: Some{EmitPrimitive{parameters, body}}
    case False{}: None{}

def js_reference_old(key: String) -> String:
  js_choose(key, "u32_add", "(a)=>(b)=>((a+b)>>>0)", js_reference_2(key))

def js_reference_2(key: String) -> String:
  js_choose(key, "u32_sub", "(a)=>(b)=>((a-b)>>>0)", js_reference_3(key))

def js_reference_3(key: String) -> String:
  js_choose(key, "u32_mul", "(a)=>(b)=>(Math.imul(a,b)>>>0)", js_reference_4(key))

def js_reference_4(key: String) -> String:
  js_choose(key, "u32_div", "(a)=>(b)=>(b===0?0:(a/b)>>>0)", js_reference_5(key))

def js_reference_5(key: String) -> String:
  js_choose(key, "nat_add", "(a)=>(b)=>nat_chk(a+b)", js_reference_6(key))

def js_reference_6(key: String) -> String:
  js_choose(key, "nat_sub", "(a)=>(b)=>(a<b?0:a-b)", js_reference_7(key))

def js_reference_7(key: String) -> String:
  js_choose(key, "nat_mul", "(a)=>(b)=>nat_chk(a*b)", js_reference_8(key))

def js_reference_8(key: String) -> String:
  js_choose(key, "nat_cmp", "(a)=>(b)=>cmp_new(a,b)", js_reference_nat_bounds(key))
def js_reference_nat_bounds(key: String) -> String:
  js_choose(key, "nat_min", "(a)=>(b)=>(a<b?a:b)", js_choose(key, "nat_max", "(a)=>(b)=>(a>b?a:b)", js_reference_9(key)))

def js_reference_9(key: String) -> String:
  js_choose(key, "string_append", "(a)=>(b)=>a+b", js_reference_10(key))

def js_reference_10(key: String) -> String:
  js_choose(key, "bool_or", "(a)=>(b)=>a||b", js_reference_11(key))

def js_reference_11(key: String) -> String:
  js_choose(key, "bool_xor", "(a)=>(b)=>a!==b", js_reference_12(key))

def js_reference_12(key: String) -> String:
  js_choose(key, "u32_is_zero", "(a)=>a===0", js_reference_more(key))


def js_reference_more(key: String) -> String:
  js_ref_f32_extra(key)

def js_ref_f32_extra(key: String) -> String:
  js_choose(key, "f32_asin", "(a)=>Math.fround(Math.asin(a))", js_choose(key, "f32_acos", "(a)=>Math.fround(Math.acos(a))", js_choose(key, "f32_atan", "(a)=>Math.fround(Math.atan(a))", js_choose(key, "f32_sinh", "(a)=>Math.fround(Math.sinh(a))", js_choose(key, "f32_cosh", "(a)=>Math.fround(Math.cosh(a))", js_choose(key, "f32_tanh", "(a)=>Math.fround(Math.tanh(a))", js_ref_strings(key)))))))

def js_ref_u32(key: String) -> String:
  js_choose(key, "u32_mod", "(a)=>(b)=>(b===0?a:a%b)", js_choose(key, "u32_and", "(a)=>(b)=>((a&b)>>>0)", js_choose(key, "u32_or", "(a)=>(b)=>((a|b)>>>0)", js_choose(key, "u32_xor", "(a)=>(b)=>((a^b)>>>0)", js_choose(key, "u32_is_eq", "(a)=>(b)=>a===b", js_choose(key, "u32_is_ne", "(a)=>(b)=>a!==b", js_choose(key, "u32_is_lt", "(a)=>(b)=>a<b", js_choose(key, "u32_is_le", "(a)=>(b)=>a<=b", js_ref_u32_2(key)))))))))

def js_ref_u32_2(key: String) -> String:
  js_choose(key, "u32_is_gt", "(a)=>(b)=>a>b", js_choose(key, "u32_is_ge", "(a)=>(b)=>a>=b", js_ref_u32_3(key)))

def js_ref_u32_3(key: String) -> String:
  js_choose(key, "u32_inc", "(a)=>(a+1)>>>0", js_choose(key, "u32_not", "(a)=>(~a)>>>0", js_choose(key, "u32_shl", "(a)=>(a<<1)>>>0", js_choose(key, "u32_shr", "(a)=>a>>>1", js_choose(key, "u32_shln", "(a)=>(b)=>b>=32?0:(a<<b)>>>0", js_choose(key, "u32_shrn", "(a)=>(b)=>b>=32?0:a>>>b", js_choose(key, "u32_cmp", "(a)=>(b)=>cmp_new(a,b)", js_choose(key, "u32_to_nat", "(a)=>a", js_choose(key, "u32_from_nat", "(a)=>a>>>0", js_ref_nat(key))))))))))
def js_ref_f32(key: String) -> String:
  js_choose(key, "f32_add", "(a)=>(b)=>Math.fround(a+b)", js_choose(key, "f32_sub", "(a)=>(b)=>Math.fround(a-b)", js_choose(key, "f32_mul", "(a)=>(b)=>Math.fround(a*b)", js_choose(key, "f32_div", "(a)=>(b)=>Math.fround(a/b)", js_choose(key, "f32_mod", "(a)=>(b)=>Math.fround(a%b)", js_choose(key, "f32_neg", "(a)=>-a", js_choose(key, "f32_sqrt", "(a)=>Math.fround(Math.sqrt(a))", js_choose(key, "f32_abs", "(a)=>Math.fround(Math.abs(a))", js_ref_f32_2(key)))))))))

def js_ref_f32_2(key: String) -> String:
  js_choose(key, "f32_to_u32", "(a)=>(a>=1&&a<4294967296?Math.floor(a):0)", js_choose(key, "f32_bits", "(a)=>f32_bits(a)", js_choose(key, "f32_show", "(a)=>f32_show(a)", js_choose(key, "f32_read", "(a)=>f32_read(a)", js_ref_f32_3(key)))))

def js_ref_f32_3(key: String) -> String:
  js_choose(key, "f32_is_eq", "(a)=>(b)=>a===b", js_choose(key, "f32_is_ne", "(a)=>(b)=>a!==b", js_choose(key, "f32_is_lt", "(a)=>(b)=>a<b", js_choose(key, "f32_is_le", "(a)=>(b)=>a<=b", js_choose(key, "f32_is_gt", "(a)=>(b)=>a>b", js_choose(key, "f32_is_ge", "(a)=>(b)=>a>=b", js_choose(key, "f32_pow", "(a)=>(b)=>Math.fround(Math.pow(a,b))", js_choose(key, "f32_atan2", "(a)=>(b)=>Math.fround(Math.atan2(a,b))", js_choose(key, "f32_exp", "(a)=>Math.fround(Math.exp(a))", js_choose(key, "f32_log", "(a)=>Math.fround(Math.log(a))", js_choose(key, "f32_log2", "(a)=>Math.fround(Math.log2(a))", js_choose(key, "f32_log10", "(a)=>Math.fround(Math.log10(a))", js_choose(key, "f32_sin", "(a)=>Math.fround(Math.sin(a))", js_choose(key, "f32_cos", "(a)=>Math.fround(Math.cos(a))", js_choose(key, "f32_tan", "(a)=>Math.fround(Math.tan(a))", js_choose(key, "f32_floor", "(a)=>Math.fround(Math.floor(a))", js_choose(key, "f32_ceil", "(a)=>Math.fround(Math.ceil(a))", js_choose(key, "f32_trunc", "(a)=>Math.fround(Math.trunc(a))", js_choose(key, "f32_to_nat", "(a)=>Math.floor(a)", js_choose(key, "u32_to_f32", "(a)=>Math.fround(a)", String.append("$D[", String.append(js_quote(key), "]"))))))))))))))))))))))
def js_ref_nat(key: String) -> String:
  js_choose(key, "nat_double", "(a)=>nat_chk(a+a)", js_choose(key, "nat_is_lt", "(a)=>(b)=>a<b", js_choose(key, "nat_divmod", "(a)=>(b)=>nat_divmod(a,b)", String.append("$D[", String.append(js_quote(key), "]")))))
def js_ref_strings(key: String) -> String:
  js_choose(key, "string_eq", "(a)=>(b)=>a===b", js_choose(key, "map_bit", "(key)=>(position)=>{const character=Math.floor(position/33);if(character>=key.length)return tuple(key,false);const offset=position%33;let at=0;for(let i=0;i<character&&at<key.length;i++)at+=key.codePointAt(at)>65535?2:1;return tuple(key,at<key.length&&(offset===0||((key.codePointAt(at)>>>(32-offset))&1)!==0));}", js_choose(key, "string_cmp", "(a)=>(b)=>{let i=0,j=0,order=0;if(a!==b){while(i<a.length&&j<b.length){const x=a.codePointAt(i),y=b.codePointAt(j);if(x!==y){order=x<y?-1:1;break;}i+=x>65535?2:1;j+=y>65535?2:1;}if(order===0)order=i<a.length?1:j<b.length?-1:0;}return tuple(tuple(a,b),cmp_new(order,0));}", js_ref_array(key))))

def js_ref_array(key: String) -> String:
  js_choose(key, "string_to_list", "(text)=>{let tail={$:\"Nil\"};for(let i=text.length;i>0;){const end=i,low=text.charCodeAt(--i);if(low>=0xDC00&&low<=0xDFFF&&i>0){const high=text.charCodeAt(i-1);if(high>=0xD800&&high<=0xDBFF)--i;}tail={$:\"Con\",head:text.slice(i,end),tail};}return tail;}", js_choose(key, "string_length", "(a)=>[...a].length", js_choose(key, "array_new", "(a)=>(b)=>array_new(a,b)", js_choose(key, "array_set", "(a)=>(i)=>(v)=>(a[i%a.length]=v,a)", js_choose(key, "array_get", "(a)=>(i)=>tuple(a,a[i%a.length])", js_choose(key, "array_swap", "(a)=>(i)=>(v)=>array_swap(a,i,v)", js_choose(key, "array_size", "(a)=>tuple(a,a.length)", js_choose(key, "array_clone", "(a)=>tuple(a,a.slice())", js_ref_u32(key)))))))))

def js_term(term: AST.SyntaxTerm, env: EmitEnv) -> String:
  js_term_expected(term, env, None{})
def js_term_expected(term: AST.SyntaxTerm, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match term:
    case AST.TermVar{_, index, _}: env_at(env, index)
    case AST.TermRef{key, _}: js_reference(key)
    case AST.TermBang{AST.TermRef{key, _}, _}: js_reference(key)
    case AST.TermCtr{key, args, _}: js_constructor(key, args, env, expected)
    case AST.TermString{chars, names, span}: js_string_literal(chars, names, span, env, expected)
    case AST.TermType{_, _}: "null"
    case AST.TermQuant{}: "null"
    case AST.TermQuantity{_, _}: "null"
    case AST.TermMin{_, _, _}: "null"
    case AST.TermAll{_, _, _, _, _, _}: "null"
    case AST.TermAdt{_, _, _, _}: "null"
    case AST.TermEqual{_, _, _, _}: "null"
    case AST.TermRefl{_}: "null"
    case AST.TermAnn{inner, ty, _}: js_term_expected(inner, env, Some{js_close(ty, env)})
    case AST.TermFill{head, _, _}: js_term_expected(head, env, None{})
    case AST.TermPlus{head, _, _}: js_term_expected(head, env, None{})
    case AST.TermApp{_, _, _}: String.append("run_loop(", String.append(js_app_spine(term, env, True{}), ")"))
    case _: String.append("run_loop(", String.append(js_term_tail_expected(term, env, expected), ")"))
#
# Runtime binders receive strict operands; constructor fields are emitted strict.
# Named function entries are closures, and deferred $D getters force their value
# on every access (never cache a nullary mutable factory). Keep the resolver's
# alias/shadow order. A lambda's expected formal quantity may erase its binder
# and expose its body's request, so every lambda retains the outer force.
# Tail expressions may return a request. Strict operands still use js_term.
# No request escapes a source closure's public curried calling convention.
def js_term_tail_expected(term: AST.SyntaxTerm, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match term:
    case AST.TermVar{ _, index,  _}: env_at(env, index)
    case AST.TermRef{key,  _}: js_reference(key)

    case AST.TermSub{index, value, body, _}: js_term_sub(index, value, body, env, expected)
    case AST.TermLet{keys,  _, quantities, values, body,  _}:
      js_term_let(keys, quantities, values, body, env, env, expected, 0n)
    case AST.TermType{ _,  _}: "null"
    case AST.TermQuant{}: "null"
    case AST.TermQuantity{ _,  _}: "null"
    case AST.TermMin{ _,  _,  _}: "null"
    case AST.TermAll{ _,  _,  _,  _,  _,  _}: "null"
    case AST.TermLam{quantity, _, _, body, _}: js_lambda(quantity, body, env, expected)
    case AST.TermAnn{term, ty, _}: js_term_tail_expected(term, env, Some{js_close(ty, env)})
    case AST.TermBang{ AST.TermRef{key,  _},  _}: js_reference(key)
    case AST.TermBang{ _,  _}: "(()=>{throw \"bend: bang head must be a named reference\"})()"
    case AST.TermFill{head,  _,  _}: js_term_tail_expected(head, env, None{})
    case AST.TermPlus{head,  _,  _}: js_term_tail_expected(head, env, None{})
    case AST.TermApp{ _,  _,  _}: js_app_spine(term, env, False{})
    case AST.TermAdt{ _,  _,  _,  _}: "null"
    case AST.TermCtr{key, args, _}: js_constructor(key, args, env, expected)
    case AST.TermString{chars, names, span}: js_string_literal(chars, names, span, env, expected)
    case AST.TermMat{_, head, matched, _}: js_match(head, matched, env, expected)
    case AST.TermAbsurd{span}: "(()=>{throw \"bend: runtime fail-stop\"})()"
    case AST.TermEqual{ _,  _,  _,  _}: "null"
    case AST.TermRefl{ _}: "null"
    case AST.TermRewrite{ _,  _, body,  _}: js_term_tail_expected(body, env, expected)
    case AST.TermHole{key, span}: String.append("(()=>{throw ", String.append(js_quote(String.append("bend: unsolved hole ", key)), "})()"))
    case AST.BodyReply{term,  _}: js_term_tail_expected(term, env, expected)
    case AST.BodyLocal{patterns, _, values, body, _}:
      js_body_local(patterns, values, body, env, env, expected)
    case AST.BodyCase{_, body, _}: js_term_tail_expected(body, env, expected)
    case AST.BodyMatch{scrutinees, cases, _}:
      js_body_match(scrutinees, cases, env, expected)
    case AST.TermTemplate{_, _}: "(()=>{throw \"bend: unexpanded template\"})()"

# Function and case bodies already own a lexical block. Emit their local
# bindings and matches there rather than allocating an immediately invoked
# closure for each syntax node. Value operands still use the strict emitter.
def js_statement_tail(term: AST.SyntaxTerm, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match term:
    case AST.BodyReply{inner, _}: js_statement_tail(inner, env, expected)
    case AST.BodyCase{_, inner, _}: js_statement_tail(inner, env, expected)
    case AST.TermAnn{inner, ty, _}: js_statement_tail(inner, env, Some{js_close(ty, env)})
    case AST.TermRewrite{_, _, inner, _}: js_statement_tail(inner, env, expected)
    case AST.BodyLocal{patterns, _, values, body, _}:
      js_statement_local(patterns, values, body, env, env, expected)
    case AST.BodyMatch{scrutinees, cases, _}:
      js_statement_match(scrutinees, cases, env, expected)
    case _: String.append("return ", String.append(js_term_tail_expected(term, env, expected), ";"))
def js_statement_local(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, AST.SyntaxTerm>, body: AST.SyntaxTerm, source: EmitEnv, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match patterns values:
    case Nil{} Nil{}: js_statement_tail(body, env, expected)
    case AST.PatternVar{_, _, AST.QZero{}, _} <> rest +value <> more:
      js_statement_local(rest, more, body, source, env_bind("null", js_type(value, source), Some{js_close(value, source)}, env), expected)
    case AST.PatternVar{_, _, _, _} <> rest +value <> more:
      name = String.append("$local", Nat.show(env_depth(env)))
      bound = env_bind(name, js_type(value, source), Some{js_close(value, source)}, env)
      prefix = String.append("const ", String.append(name, String.append(" = ", String.append(js_term(value, source), ";\n"))))
      String.append(prefix, js_statement_local(rest, more, body, source, bound, expected))
    case AST.PatternCtr{_, _, _} <> _ +_ <> _:
      String.append("return ", String.append(js_body_local_constructor(patterns, values, body, source, env, expected), ";"))
    case _ _: "throw \"bend: malformed local bindings\";"
def js_statement_match(scrutinees: List<&2, AST.SyntaxTerm>, cases: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  count = List.length(&2, AST.SyntaxTerm, scrutinees)
  values = scrutinee_names(count, env)
  branch_env = env_reserve_names(count, env)
  String.append(js_scrutinees(scrutinees, env, 0n), js_cases_dispatch(cases, values, scrutinees, branch_env, expected))
def js_statement_result(body: AST.SyntaxTerm, env: EmitEnv, result: AST.OptionalTerm) -> String:
  match result:
    case AST.SomeTerm{ty}: js_statement_tail(body, env, Some{js_close(ty, env)})
    case AST.NoTerm{}: js_statement_tail(body, env, None{})

def js_app_spine(term: AST.SyntaxTerm, env: EmitEnv, strict: Bool) -> String:
  js_app_spine_result(js_app_spine_at(term, Nil{}), env, strict)

def js_app_spine_result(spine: AST.SyntaxTerm & List<&2, AST.SyntaxTerm>, env: EmitEnv, strict: Bool) -> String:
  match spine:
    case (head, args):
      js_app_dispatch(head, args, env, strict)

def js_app_dispatch(head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, env: EmitEnv, strict: Bool) -> String:
  match head:
    case AST.TermRef{key, _}: js_named_app(key, args, env, strict)
    case AST.TermBang{AST.TermRef{key, _}, _}:
      js_named_app(key, args, env, strict)
    case AST.TermBang{_, _}: "(()=>{throw \"bend: bang head must be a named reference\"})()"
    case _: js_app_chain(js_term(head, env), js_type(head, env), args, env)
# Resolve through the same immutable ordered type owners as checked signatures.
# A foreign/native/type owner blocks a global fallback even when unsupported.
def js_named_owner(key: String, env: EmitEnv) -> Maybe<&2, EmitNamed>:
  match env:
    case EmitEnv{+scope, _, _, _, _}:
      match scope:
        case EmitScope{_, _, catalog}:
          js_named_fallback(js_named_lookup(js_scope_key(key, scope), catalog), key, catalog)
def js_named_fallback(found: Maybe<&2, EmitNamed>, key: String, catalog: EmitCatalog) -> Maybe<&2, EmitNamed>:
  match found:
    case Some{_}: found
    case None{}: js_named_lookup(key, catalog)
def js_named_lookup(key: String, +catalog: EmitCatalog) -> Maybe<&2, EmitNamed>:
  match catalog:
    case EmitCatalog{_, _, _, owners}:
      js_named_layouts(IndexLookup.find(List<&2, EmitModuleIndex>, owners, key), key, catalog)
def js_named_layouts(found: Maybe<&2, List<&2, EmitModuleIndex>>, key: String, catalog: EmitCatalog) -> Maybe<&2, EmitNamed>:
  match found:
    case None{}: None{}
    case Some{Nil{}}: None{}
    case Some{+layout <> rest}:
      match layout:
        case EmitModuleIndex{_, _, _, _, types}:
          js_named_next(js_named_declarations(IndexLookup.find(List<&2, AST.TopLevel>, types, key), key, js_owner_env(layout, catalog)), rest, key, catalog)
def js_named_next(found: Maybe<&2, EmitNamed>, rest: List<&2, EmitModuleIndex>, key: String, catalog: EmitCatalog) -> Maybe<&2, EmitNamed>:
  match found:
    case Some{_}: found
    case None{}: js_named_layouts(Some{rest}, key, catalog)
def js_named_declarations(found: Maybe<&2, List<&2, AST.TopLevel>>, key: String, env: EmitEnv) -> Maybe<&2, EmitNamed>:
  match found:
    case None{}: None{}
    case Some{Nil{}}: None{}
    case Some{AST.DefTop{definition} <> _}: Some{EmitNamed{key, definition, env}}
    case Some{AST.TypeTop{_} <> _}: Some{EmitNamedBlocked{}}
    case Some{AST.LawTop{AST.LawDecl{name, clauses, _, _}} <> rest}:
      js_named_native_law(js_native_operation(name, env), js_native_law_binders(clauses, 0n), rest, key, env)
def js_named_native_law(operation: Maybe<&2, String>, binders: Maybe<&2, List<&2, AST.TelescopeItem>>, rest: List<&2, AST.TopLevel>, key: String, env: EmitEnv) -> Maybe<&2, EmitNamed>:
  match operation binders:
    case Some{_} Some{items}: Some{EmitNamedNative{key, items, env}}
    case Some{_} None{}: Some{EmitNamedBlocked{}}
    case None{} _: js_named_declarations(Some{rest}, key, env)
def js_named_app(key: String, args: List<&2, AST.SyntaxTerm>, env: EmitEnv, strict: Bool) -> String:
  js_named_app_found(js_named_owner(key, env), key, args, env, strict)
def js_named_app_found(found: Maybe<&2, EmitNamed>, key: String, args: List<&2, AST.SyntaxTerm>, env: EmitEnv, strict: Bool) -> String:
  match found:
    case Some{EmitNamed{resolved, AST.Definition{_, +binders, +result, AST.DefTerm{+term}, _, _}, +owner}}:
      js_named_app_native(js_native_primitive_checked(js_native_operation(resolved, owner), binders), resolved, binders, result, term, args, owner, key, env, strict)
    case Some{EmitNamedNative{resolved, +binders, +owner}}:
      js_named_native_law_app(js_native_primitive_checked(js_native_operation(resolved, owner), binders), resolved, binders, args, owner, key, env)
    case _: js_app_chain(js_reference(key), js_global_type(key, env), args, env)
# Native laws use the same checked telescope and fixed primitive shape that
# emitted their $U entry. Unsupported laws retain the curried resolver path.
def js_named_native_law_app(primitive: Maybe<&2, EmitPrimitive>, resolved: String, binders: List<&2, AST.TelescopeItem>, args: List<&2, AST.SyntaxTerm>, owner: EmitEnv, key: String, env: EmitEnv) -> String:
  match primitive:
    case Some{_}: js_native_app_args(js_named_args(binders, args, owner, env), resolved, key, args, env)
    case None{}: js_app_chain(js_reference(key), js_global_type(key, env), args, env)
def js_named_app_native(primitive: Maybe<&2, EmitPrimitive>, resolved: String, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, term: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, owner: EmitEnv, key: String, env: EmitEnv, strict: Bool) -> String:
  match primitive:
    case Some{_}: js_native_app_args(js_named_args(binders, args, owner, env), resolved, key, args, env)
    case None{}: js_named_app_eligible(js_named_eligible(resolved, binders, result, term, owner), resolved, binders, args, owner, key, env, strict)
def js_native_app_args(found: Maybe<&2, List<&2, String>>, resolved: String, key: String, args: List<&2, AST.SyntaxTerm>, env: EmitEnv) -> String:
  match found:
    case Some{values}:
      String.append(js_named_identifier(resolved), String.append("(", String.append(String.join(values, ","), ")")))
    case None{}: js_app_chain(js_reference(key), js_global_type(key, env), args, env)
def js_named_app_eligible(eligible: Bool, resolved: String, binders: List<&2, AST.TelescopeItem>, args: List<&2, AST.SyntaxTerm>, owner: EmitEnv, key: String, env: EmitEnv, strict: Bool) -> String:
  match eligible:
    case True{}: js_named_app_args(js_named_args(binders, args, owner, env), resolved, key, args, env, strict)
    case False{}: js_app_chain(js_reference(key), js_global_type(key, env), args, env)
def js_named_tail_selected(resolved: String, +values: List<&2, String>, count: Nat, selected: Bool) -> String:
  match selected:
    case True{}:
      prefix = String.append("run_named", String.append(Nat.show(count), String.append("(", String.append(js_named_identifier(resolved), ","))))
      String.append(prefix, String.append(String.join(values, ","), ",$td)"))
    case False{}: String.append("run_many(", String.append(js_named_identifier(resolved), String.append(",[", String.append(String.join(values, ","), "],$td)"))))

def js_named_tail(resolved: String, +values: List<&2, String>) -> String:
  count = List.length(&2, String, values)
  js_named_tail_selected(resolved, values, count, Bool.and(Nat.is_gt(count, 0n), Nat.is_le(count, 32n)))

def js_named_app_args(found: Maybe<&2, List<&2, String>>, resolved: String, key: String, args: List<&2, AST.SyntaxTerm>, env: EmitEnv, strict: Bool) -> String:
  match found:
    case Some{values}:
      match strict:
        case True{}: String.append(js_named_identifier(resolved), String.append("(", String.append(String.join(values, ","), ")")))
        case False{}: js_named_tail(resolved, values)
    case None{}: js_app_chain(js_reference(key), js_global_type(key, env), args, env)
# Consume dependent metadata in declaration scope, evaluating only live operands
# in the caller's scope. Both JS call operands and array literals are left-to-right.
# Strict calls retain their caller's run_loop. Ordinary tail calls batch at
# most sixty-four direct calls before yielding the same trampoline request.
# The private depth argument is local to each chain; dynamic closures keep
# the existing trampoline. Strict recursion still needs nested forcing.
def js_named_args(binders: List<&2, AST.TelescopeItem>, args: List<&2, AST.SyntaxTerm>, owner: EmitEnv, env: EmitEnv) -> Maybe<&2, List<&2, String>>:
  match binders args:
    case Nil{} Nil{}: Some{Nil{}}
    case AST.Binder{quantity, _, _, domain, _} <> rest +arg <> more:
      bound = env_bind("null", Some{js_close(domain, owner)}, Some{js_close(arg, env)}, owner)
      js_named_arg(js_named_args(rest, more, bound, env), quantity, arg, domain, owner, env)
    case _ _: None{}
def js_named_arg(rest: Maybe<&2, List<&2, String>>, quantity: AST.Quantity, arg: AST.SyntaxTerm, domain: AST.SyntaxTerm, owner: EmitEnv, env: EmitEnv) -> Maybe<&2, List<&2, String>>:
  match rest:
    case None{}: None{}
    case Some{values}:
      match quantity:
        case AST.QZero{}: Some{values}
        case _: Some{js_term_expected(arg, env, Some{js_close(domain, owner)}) <> values}
def js_app_spine_at(term: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>) -> AST.SyntaxTerm & List<&2, AST.SyntaxTerm>:
  match term:
    case AST.TermApp{fn, arg,  _}: js_app_spine_at(fn, arg <> args)
    case _: (term, args)
# Source argument syntax is not an erasure test. Consume every formal slot,
# but emit a call (and its argument expression) only for a live quantity.
# Consequently partial applications retain exactly the declaration/lambda ABI,
# including erased value arguments and arrows in a declared result type.
def js_app_chain_args(args: List<&2, AST.SyntaxTerm>, ty: Maybe<&2, EmitClosure>, fn: String, env: EmitEnv) -> String:
  match args:
    case Nil{}: fn
    case +arg <> rest:
      match ty:
        case None{}: "(()=>{throw \"bend: application has no checked signature\"})()"
        case Some{value}: js_app_arrow(fn, js_reduce(value), arg, rest, env)
def js_app_chain(fn: String, ty: Maybe<&2, EmitClosure>, args: List<&2, AST.SyntaxTerm>, env: EmitEnv) -> String:
  js_app_chain_args(args, ty, fn, env)
def js_app_arrow_env(fn: String, ty: EmitClosure, arg: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, env: EmitEnv, type_env: EmitEnv) -> String:
  match ty:
    case EmitClosure{AST.TermAll{quantity, _, _, domain, codomain, _}, _, _, _, _, _}:
      next = Some{js_close(codomain, env_bind("null", Some{js_close(domain, type_env)}, Some{js_close(arg, env)}, type_env))}
      js_app_quantity(quantity, fn, Some{js_close(domain, type_env)}, next, arg, rest, env)
    case EmitInferred{AST.Binder{quantity, _, _, domain, _} <> more, body, _, _, _, _, _}:
      bound = env_bind("null", Some{js_close(domain, type_env)}, Some{js_close(arg, env)}, type_env)
      js_app_quantity(quantity, fn, Some{js_close(domain, type_env)}, Some{js_close_inferred(more, body, bound)}, arg, rest, env)
    case EmitDeclared{AST.Binder{quantity, _, _, domain, _} <> more, result, _, _, _, _, _}:
      bound = env_bind("null", Some{js_close(domain, type_env)}, Some{js_close(arg, env)}, type_env)
      js_app_quantity(quantity, fn, Some{js_close(domain, type_env)}, Some{js_close_declared(more, result, bound)}, arg, rest, env)
    case _: "(()=>{throw \"bend: application signature is not a function\"})()"
def js_app_arrow(fn: String, ty: EmitClosure, arg: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, env: EmitEnv) -> String:
  js_app_arrow_env(fn, ty, arg, rest, env, js_closure_env(ty))
def js_app_quantity(quantity: AST.Quantity, fn: String, domain: Maybe<&2, EmitClosure>, next: Maybe<&2, EmitClosure>, arg: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, env: EmitEnv) -> String:
  match quantity:
    case AST.QZero{}: js_app_chain(fn, next, rest, env)
    case _:
      source = String.append("run_tail(run_loop(", String.append(fn, String.append("),", String.append(js_term_expected(arg, env, domain), ")"))))
      js_app_chain(source, next, rest, env)

def js_lambda(quantity: Maybe<&2, AST.Quantity>, body: AST.SyntaxTerm, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match expected:
    case Some{ty}: js_lambda_view(quantity, body, env, js_reduce(ty))
    case None{}: js_lambda_untyped(quantity, body, env)
def js_lambda_view_env(quantity: Maybe<&2, AST.Quantity>, body: AST.SyntaxTerm, env: EmitEnv, expected: EmitClosure, type_env: EmitEnv) -> String:
  match expected:
    case EmitClosure{AST.TermAll{formal, _, _, domain, codomain, _}, _, _, _, _, _}:
      name = js_binder_name(formal, String.append("$x", Nat.show(env_depth(env))))
      bound = env_bind(name, Some{js_close(domain, type_env)}, None{}, env)
      next = Some{js_close(codomain, env_bind(name, Some{js_close(domain, type_env)}, None{}, type_env))}
      js_lambda_quantity(formal, name, body, bound, next)
    case _: "(()=>{throw \"bend: lambda signature is not a function\"})()"
def js_lambda_view(quantity: Maybe<&2, AST.Quantity>, body: AST.SyntaxTerm, env: EmitEnv, expected: EmitClosure) -> String:
  js_lambda_view_env(quantity, body, env, expected, js_closure_env(expected))
def js_binder_name(quantity: AST.Quantity, name: String) -> String:
  match quantity:
    case AST.QZero{}: "null"
    case _: name
def js_lambda_untyped(quantity: Maybe<&2, AST.Quantity>, body: AST.SyntaxTerm, env: EmitEnv) -> String:
  match quantity:
    case Some{AST.QZero{}}: js_term_tail_expected(body, env_push("null", env), None{})
    case _: "(()=>{throw \"bend: lambda has no checked signature\"})()"
def js_lambda_quantity(quantity: AST.Quantity, name: String, body: AST.SyntaxTerm, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match quantity:
    case AST.QZero{}: js_term_tail_expected(body, env, expected)
    case _: js_closure(name, js_term_tail_expected(body, env, expected))
#
# One callable serves strict foreign calls and raw trampoline entry. The private
# symbol selects raw mode; incidental extra callback arguments cannot select it.
# A defaulted second formal preserves the public one-argument function length.
def js_closure(name: String, body: String) -> String:
  String.append("run_clo((", String.append(name, String.append(",$raw=undefined)=>run_force(", String.append(body, ",$raw))"))))
def env_depth(env: EmitEnv) -> Nat:
  match env:
    case EmitEnv{_, _, _, _, depth}: depth
# Depth allocates fresh JS identifiers; binder lookup uses the captured lists.
# Reserving a match scope never inserts or shifts a source-language binder.
def env_reserve_names(count: Nat, env: EmitEnv) -> EmitEnv:
  match env:
    case EmitEnv{scope, names, types, values, depth}:
      EmitEnv{scope, names, types, values, ((depth + count : Nat) + 1n : Nat)}

def js_term_sub(index: Nat, value: AST.SyntaxTerm, body: AST.SyntaxTerm, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  name = String.append("$sub", Nat.show(env_depth(env)))
  bound = env_insert_binding(env, index, EmitBinding{name, js_type(value, env), Some{js_close(value, env)}})
  String.append("((", String.append(name, String.append(") => ", String.append(js_term_tail_expected(body, bound, expected), String.append(")(", String.append(js_term(value, env), ")"))))))
def js_term_let(keys: List<&2, String>, quantities: List<&2, AST.Quantity>, values: List<&2, AST.SyntaxTerm>, body: AST.SyntaxTerm, source_env: EmitEnv, env: EmitEnv, expected: Maybe<&2, EmitClosure>, index: Nat) -> String:
  match keys quantities values:
    case Nil{} Nil{} Nil{}: js_term_tail_expected(body, env, expected)
    case +key <> more_keys AST.QZero{} <> more_quantities +value <> more_values:
      bound = env_bind("null", js_type(value, source_env), Some{js_close(value, source_env)}, env)
      js_term_let(more_keys, more_quantities, more_values, body, source_env, bound, expected, (index + 1n : Nat))
    case +key <> more_keys +quantity <> more_quantities +value <> more_values:
      name = String.append("$l", Nat.show(env_depth(env)))
      bound = env_bind(name, js_type(value, source_env), Some{js_close(value, source_env)}, env)
      String.append("((", String.append(name, String.append(") => ", String.append(js_term_let(more_keys, more_quantities, more_values, body, source_env, bound, expected, (index + 1n : Nat)), String.append(")(", String.append(js_term(value, source_env), ")"))))))
    case _ _ _: "(()=>{throw \"bend: malformed let bindings\"})()"
def js_body_local(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, AST.SyntaxTerm>, body: AST.SyntaxTerm, source: EmitEnv, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match patterns values:
    case Nil{} Nil{}: js_term_tail_expected(body, env, expected)
    case AST.PatternVar{_, _, AST.QZero{}, _} <> rest +value <> more:
      js_body_local(rest, more, body, source, env_bind("null", js_type(value, source), Some{js_close(value, source)}, env), expected)
    case AST.PatternVar{_, _, _, _} <> rest +value <> more:
      name = String.append("$local", Nat.show(env_depth(env)))
      bound = env_bind(name, js_type(value, source), Some{js_close(value, source)}, env)
      String.append("((", String.append(name, String.append(") => ", String.append(js_body_local(rest, more, body, source, bound, expected), String.append(")(", String.append(js_term(value, source), ")"))))))
    case AST.PatternCtr{_, _, _} <> _ +_ <> _:
      js_body_local_constructor(patterns, values, body, source, env, expected)
    case _ _: "(()=>{throw \"bend: malformed local bindings\"})()"
def js_body_local_constructor(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, AST.SyntaxTerm>, body: AST.SyntaxTerm, source: EmitEnv, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  count = List.length(&2, AST.SyntaxTerm, values)
  names = scrutinee_names(count, source)
  types = js_pattern_types(patterns, js_scrutinee_types(values, source), source)
  branch = js_case_typed(patterns, body, names, types, env_reserve_names(count, env), expected)
  prefix = String.append("(()=>{", js_scrutinees(values, source, 0n))
  String.append(prefix, String.append(branch, "throw \"bend: runtime fail-stop\";})()"))

def js_constructor(key: String, args: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  native = js_constructor_native(js_constructor_native_identity(key, env))
  js_constructor_literal(js_native_word_literal(native, key, args, env), native, key, args, env, expected)
def js_constructor_literal(literal: Maybe<&2, String>, native: String, key: String, args: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match literal:
    case Some{source}: source
    case None{}: js_constructor_render(native, key, js_constructor_args(args, js_constructor_signature(key, expected, env), env), env)
# Only native scalar wrappers consume a closed Word; explicit Word values retain
# their constructor representation. Decode source nodes, never emitted JS text.
def js_native_word_literal(native: String, key: String, args: List<&2, AST.SyntaxTerm>, env: EmitEnv) -> Maybe<&2, String>:
  match native args:
    case "U" +word <> Nil{}: js_native_word_declared(js_word_identity(js_constructor_decl(key, env)), native, word, env)
    case "F" +word <> Nil{}: js_native_word_declared(js_word_identity(js_constructor_decl(key, env)), native, word, env)
    case _ _: None{}
def js_native_word_declared(identity: String, native: String, word: AST.SyntaxTerm, env: EmitEnv) -> Maybe<&2, String>:
  match identity native:
    case "U32.U32" "U": js_word_literal_render(js_closed_word(32n, word, env), False{})
    case "F32.F32" "F": js_word_literal_render(js_closed_word(32n, word, env), True{})
    case _ _: None{}
def js_word_literal_render(value: Maybe<&2, Nat>, floating: Bool) -> Maybe<&2, String>:
  match value floating:
    case Some{bits} False{}: Some{Nat.show(bits)}
    case Some{bits} True{}: Some{String.append("f32_from_bits(", String.append(Nat.show(bits), ")"))}
    case None{} _: None{}
# Unlike the general native identity fallback, folding requires a declaration
# whose original environment proves that it comes from the canonical Base.
def js_word_identity(found: Maybe<&2, EmitConstructor>) -> String:
  match found:
    case Some{EmitConstructor{canonical, family, _, _, declaration_env}}:
      js_constructor_native_origin(js_base_origin(declaration_env), family, canonical)
    case None{}: ""
def js_closed_word(+remaining: Nat, term: AST.SyntaxTerm, env: EmitEnv) -> Maybe<&2, Nat>:
  match term:
    case AST.TermAnn{inner, _, _}: js_closed_word(remaining, inner, env)
    case AST.TermCtr{key, args, _}:
      js_closed_word_constructor(remaining, js_word_identity(js_constructor_decl(key, env)), args, env)
    case _: None{}
def js_closed_word_constructor(+remaining: Nat, identity: String, args: List<&2, AST.SyntaxTerm>, env: EmitEnv) -> Maybe<&2, Nat>:
  match remaining identity args:
    case 0n "Word.Nil.WNil" Nil{}: Some{0n}
    case 1n+rest "Word.Con.WCon" +bit <> +tail <> Nil{}:
      js_closed_word_bit(js_closed_bit(bit, env), rest, tail, env)
    case _ _ _: None{}
def js_closed_bit(term: AST.SyntaxTerm, env: EmitEnv) -> Maybe<&2, Nat>:
  match term:
    case AST.TermAnn{inner, _, _}: js_closed_bit(inner, env)
    case AST.TermCtr{key, Nil{}, _}: js_closed_bit_identity(js_word_identity(js_constructor_decl(key, env)))
    case _: None{}
def js_closed_bit_identity(identity: String) -> Maybe<&2, Nat>:
  match identity:
    case "Bool.False": Some{0n}
    case "Bool.True": Some{1n}
    case _: None{}
def js_closed_word_bit(bit: Maybe<&2, Nat>, remaining: Nat, tail: AST.SyntaxTerm, env: EmitEnv) -> Maybe<&2, Nat>:
  match bit:
    case None{}: None{}
    case Some{low}: js_closed_word_combine(low, js_closed_word(remaining, tail, env))
def js_closed_word_combine(low: Nat, tail: Maybe<&2, Nat>) -> Maybe<&2, Nat>:
  match tail:
    case Some{high}: Some{((high * 2n : Nat) + low : Nat)}
    case None{}: None{}

def js_string_literal(+chars: List<&2, U32>, +names: AST.StringLiteralNames, +span: AST.SourceSpan, +env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  js_string_literal_authorized(js_string_names_native(names, env), chars, names, span, env, expected)
def js_string_literal_authorized(authorized: Bool, +chars: List<&2, U32>, names: AST.StringLiteralNames, span: AST.SourceSpan, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match authorized:
    case True{}: js_string_literal_payload(js_string_scalar_chars(chars), chars, names, span, env, expected)
    case False{}: js_term_expected(AST.string_desugar(chars, names, span), env, expected)
def js_string_literal_payload(payload: Maybe<&2, List<&2, Char>>, chars: List<&2, U32>, names: AST.StringLiteralNames, span: AST.SourceSpan, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match payload:
    case Some{values}: js_quote(String.from_list(values))
    case None{}: js_term_expected(AST.string_desugar(chars, names, span), env, expected)
def js_string_scalar_chars(chars: List<&2, U32>) -> Maybe<&2, List<&2, Char>>:
  match chars:
    case Nil{}: Some{Nil{}}
    case +value <> rest:
      js_string_scalar_char(Bool.and(U32.is_le(value, 1114111), Bool.or(U32.is_lt(value, 55296), U32.is_gt(value, 57343))), value, rest)
def js_string_scalar_char(valid: Bool, value: U32, rest: List<&2, U32>) -> Maybe<&2, List<&2, Char>>:
  match valid:
    case False{}: None{}
    case True{}: js_string_scalar_cons(js_string_scalar_chars(rest), value)
def js_string_scalar_cons(rest: Maybe<&2, List<&2, Char>>, value: U32) -> Maybe<&2, List<&2, Char>>:
  match rest:
    case None{}: None{}
    case Some{values}: Some{Char.from_u32(value) <> values}
def js_string_names_native(names: AST.StringLiteralNames, +env: EmitEnv) -> Bool:
  match names:
    case AST.StringLiteralNames{nil, cons, char, uint, word_nil, word_cons, bit_false, bit_true}:
      Bool.and(js_string_constructor_native(nil, "String.SNil", env), Bool.and(js_string_constructor_native(cons, "String.SCon", env), Bool.and(js_string_constructor_native(char, "Char.Chr", env), Bool.and(js_string_constructor_native(uint, "U32.U32", env), Bool.and(js_string_constructor_native(word_nil, "Word.Nil.WNil", env), Bool.and(js_string_constructor_native(word_cons, "Word.Con.WCon", env), Bool.and(js_string_constructor_native(bit_false, "Bool.False", env), js_string_constructor_native(bit_true, "Bool.True", env))))))))
def js_string_constructor_native(+key: String, +identity: String, +env: EmitEnv) -> Bool:
  Bool.and(String.eq(js_word_identity(js_constructor_decl(key, env)), identity), js_string_constructor_schema(key, identity, env))
def js_string_constructor_schema(key: String, identity: String, env: EmitEnv) -> Bool:
  match env:
    case EmitEnv{+scope, _, _, _, _}:
      match scope:
        case EmitScope{_, _, EmitCatalog{_, _, owners, _}}:
          js_string_schema_owner(IndexLookup.find(EmitModuleIndex, owners, js_scope_key(key, scope)), key, identity, scope)
def js_string_schema_owner(found: Maybe<&2, EmitModuleIndex>, key: String, identity: String, scope: EmitScope) -> Bool:
  match found:
    case Some{EmitModuleIndex{namespace, _, _, constructors, _}}:
      js_string_schema_decl(IndexLookup.find(EmitConstructorOwner, constructors, js_scope_key(key, scope)), identity, namespace)
    case None{}:
      match scope:
        case EmitScope{_, _, EmitCatalog{_, _, owners, _}}:
          js_string_schema_global(IndexLookup.find(EmitModuleIndex, owners, key), key, identity)
def js_string_schema_global(found: Maybe<&2, EmitModuleIndex>, key: String, identity: String) -> Bool:
  match found:
    case Some{EmitModuleIndex{namespace, _, _, constructors, _}}: js_string_schema_decl(IndexLookup.find(EmitConstructorOwner, constructors, key), identity, namespace)
    case None{}: False{}
def js_string_schema_decl(found: Maybe<&2, EmitConstructorOwner>, identity: String, namespace: String) -> Bool:
  match found:
    case Some{EmitConstructorOwner{AST.TypeDecl{_, params, AST.TermType{AST.TermQuantity{AST.QMany{}, _}, _}, _, _}, AST.Constructor{_, fields, _}}}:
      js_string_schema_fields(identity, params, fields, namespace)
    case _: False{}
def js_string_schema_fields(identity: String, params: List<&2, AST.TelescopeItem>, fields: List<&2, AST.TelescopeItem>, +namespace: String) -> Bool:
  match identity params fields:
    case "String.SNil" Nil{} Nil{}: True{}
    case "Bool.False" Nil{} Nil{}: True{}
    case "Bool.True" Nil{} Nil{}: True{}
    case "Word.Nil.WNil" Nil{} Nil{}: True{}
    case "String.SCon" Nil{} AST.Binder{AST.QOne{}, _, 0n, head, _} <> AST.Binder{AST.QOne{}, _, 1n, tail, _} <> Nil{}:
      Bool.and(js_string_schema_ref(head, "Char", namespace), js_string_schema_ref(tail, "String", namespace))
    case "Char.Chr" Nil{} AST.Binder{AST.QOne{}, _, 0n, code, _} <> Nil{}: js_string_schema_ref(code, "U32", namespace)
    case "U32.U32" Nil{} AST.Binder{AST.QOne{}, _, 0n, AST.TermApp{word, count, _}, _} <> Nil{}:
      Bool.and(js_string_schema_ref(word, "Word", namespace), js_string_schema_nat(count, 32n, namespace))
    case "Word.Con.WCon" AST.Binder{AST.QZero{}, _, 0n, param, _} <> Nil{} AST.Binder{AST.QOne{}, _, 1n, head, _} <> AST.Binder{AST.QOne{}, _, 2n, AST.TermApp{word, AST.TermVar{_, 1n, _}, _}, _} <> Nil{}:
      Bool.and(js_string_schema_ref(param, "Nat", namespace), Bool.and(js_string_schema_ref(head, "Bool", namespace), js_string_schema_ref(word, "Word", namespace)))
    case _ _ _: False{}
def js_string_schema_nat(term: AST.SyntaxTerm, count: Nat, +namespace: String) -> Bool:
  match term count:
    case AST.TermCtr{key, Nil{}, _} 0n: js_string_schema_key(key, "Zero", namespace)
    case AST.TermCtr{key, [rest], _} 1n+more:
      Bool.and(js_string_schema_key(key, "Succ", namespace), js_string_schema_nat(rest, more, namespace))
    case _ _: False{}
def js_string_schema_ref(term: AST.SyntaxTerm, expected: String, namespace: String) -> Bool:
  match term:
    case AST.TermRef{key, _}: js_string_schema_key(key, expected, namespace)
    case _: False{}
def js_string_schema_key(+key: String, +expected: String, namespace: String) -> Bool:
  Bool.or(String.eq(key, expected), String.eq(key, qualify(namespace, expected)))
# Keep formal slots aligned while rendering; literal records omit erased slots.
# Erased arguments become no expressions, so even a proof with effects is unused.
def js_constructor_args(args: List<&2, AST.SyntaxTerm>, signature: Maybe<&2, EmitClosure>, env: EmitEnv) -> List<&2, String>:
  match args:
    case Nil{}: Nil{}
    case +arg <> rest:
      match signature:
        case Some{ty}: js_constructor_arg_view(arg, rest, js_reduce(ty), env)
        case None{}: js_term(arg, env) <> js_constructor_args(rest, None{}, env)
def js_constructor_arg_view_env(arg: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, signature: EmitClosure, env: EmitEnv, type_env: EmitEnv) -> List<&2, String>:
  match signature:
    case EmitClosure{AST.TermAll{quantity, _, _, domain, body, _}, _, _, _, _, _}:
      next = Some{js_close(body, env_bind("null", Some{js_close(domain, type_env)}, Some{js_close(arg, env)}, type_env))}
      js_constructor_arg_quantity(quantity, arg, Some{js_close(domain, type_env)}, env) <> js_constructor_args(rest, next, env)
    case EmitDeclared{AST.Binder{quantity, _, _, domain, _} <> rest_fields, result, _, _, _, _, _}:
      bound = env_bind("null", Some{js_close(domain, type_env)}, Some{js_close(arg, env)}, type_env)
      js_constructor_arg_quantity(quantity, arg, Some{js_close(domain, type_env)}, env) <> js_constructor_args(rest, Some{js_close_declared(rest_fields, result, bound)}, env)
    case _: js_term(arg, env) <> js_constructor_args(rest, None{}, env)
def js_constructor_arg_view(arg: AST.SyntaxTerm, rest: List<&2, AST.SyntaxTerm>, signature: EmitClosure, env: EmitEnv) -> List<&2, String>:
  js_constructor_arg_view_env(arg, rest, signature, env, js_closure_env(signature))
def js_constructor_arg_quantity(quantity: AST.Quantity, arg: AST.SyntaxTerm, domain: Maybe<&2, EmitClosure>, env: EmitEnv) -> String:
  match quantity:
    case AST.QZero{}: "null"
    case _: js_term_expected(arg, env, domain)
def js_constructor_native(key: String) -> String:
  js_choose_exact(key, "Nat.Zero", "NZ", js_choose_exact(key, "Bool.False", "BF", js_choose_exact(key, "Bool.True", "BT", js_choose_exact(key, "String.SNil", "SN", js_choose_exact(key, "Nat.Succ", "NS", js_choose_exact(key, "Char.Chr", "CH", js_choose_exact(key, "String.SCon", "SC", js_choose_exact(key, "U32.U32", "U", js_choose_exact(key, "F32.F32", "F", js_choose_exact(key, "Array.ALeaf", "AL", js_choose_exact(key, "Array.ANode", "AN", "")))))))))))
def js_constructor_native_identity_found(found: Maybe<&2, EmitConstructor>, key: String) -> String:
  match found:
    case Some{EmitConstructor{canonical, family, _, _, declaration_env}}:
      js_constructor_native_origin(js_base_origin(declaration_env), family, canonical)
    case None{}: key
def js_constructor_native_identity(key: String, env: EmitEnv) -> String:
  js_constructor_native_identity_found(js_constructor_decl(key, env), key)
def js_constructor_native_origin(native: Bool, family: String, key: String) -> String:
  match native:
    case True{}: String.append(family, String.append(".", ctor_short(key)))
    case False{}: String.append("Data.", key)
def js_base_origin(env: EmitEnv) -> Bool:
  match env:
    case EmitEnv{EmitScope{_, EmitAliases{_, _, native, _}, _}, _, _, _, _}:
      native
def js_base_source_suffix(matches: Bool, modules: List<&2, Loader.LoadedModule>) -> Bool:
  match matches:
    case True{}: js_base_imported(modules)
    case False{}: False{}
def js_base_source_exact(matches: Bool, path: String, modules: List<&2, Loader.LoadedModule>) -> Bool:
  match matches:
    case True{}: js_base_imported(modules)
    case False{}: js_base_source_suffix(String.ends_with(path, "/bend2/base.bend"), modules)
def js_base_source(path: String, modules: List<&2, Loader.LoadedModule>) -> Bool:
  js_base_source_exact(String.eq(path, "bend2/base.bend"), path, modules)
def js_base_imported(modules: List<&2, Loader.LoadedModule>) -> Bool:
  match modules:
    case Nil{}: False{}
    case Loader.LoadedModule{_, AST.Module{_, imports, _}} <> rest:
      js_base_imported_next(js_base_imports(imports), rest)
def js_base_imported_next(found: Bool, rest: List<&2, Loader.LoadedModule>) -> Bool:
  match found:
    case True{}: True{}
    case False{}: js_base_imported(rest)
def js_base_imports(imports: List<&2, AST.ModuleImport>) -> Bool:
  match imports:
    case Nil{}: False{}
    case AST.ModuleImport{path, _, _} <> rest:
      js_base_imports_next(String.eq(path, "Base"), rest)
def js_base_imports_next(found: Bool, rest: List<&2, AST.ModuleImport>) -> Bool:
  match found:
    case True{}: True{}
    case False{}: js_base_imports(rest)
def js_source_at(sources: List<&2, String>, index: Nat) -> String:
  match sources:
    case Nil{}: "undefined"
    case +source <> rest:
      match index:
        case 0n: source
        case _: js_source_at(rest, (index - 1n : Nat))
def js_sources(sources: List<&2, String>) -> String:
  match sources:
    case Nil{}: ""
    case +source <> rest:
      match rest:
        case Nil{}: source
        case _: String.append(source, String.append(", ", js_sources(rest)))
def js_constructor_render(native: String, key: String, sources: List<&2, String>, env: EmitEnv) -> String:
  match native:
    case "NZ": "0"
    case "BF": "false"
    case "BT": "true"
    case "SN": "\"\""
    case "NS": String.append("nat_chk(", String.append(js_source_at(sources, 0n), " + 1)"))
    case "CH": String.append("char_new(", String.append(js_source_at(sources, 0n), ")"))
    case "SC": String.append("(", String.append(js_source_at(sources, 0n), String.append(" + ", String.append(js_source_at(sources, 1n), ")"))))
    case "U": String.append("word_to_u32(", String.append(js_source_at(sources, 0n), ")"))
    case "F": String.append("f32_from_bits(word_to_u32(", String.append(js_source_at(sources, 0n), "))"))
    case "AL": String.append("[", String.append(js_source_at(sources, 0n), "]"))
    case "AN": String.append("array_node(", String.append(js_source_at(sources, 0n), String.append(", ", String.append(js_source_at(sources, 1n), ")"))))
    case _: js_constructor_record(js_constructor_decl(key, env), key, sources)
def js_constructor_record(found: Maybe<&2, EmitConstructor>, key: String, sources: List<&2, String>) -> String:
  match found:
    case Some{EmitConstructor{canonical, _, _, fields, _}}:
      js_constructor_record_exact(js_constructor_record_fields(fields, sources), canonical)
    case None{}: String.append("$ctr(", String.append(js_quote(key), String.append(", [", String.append(js_sources(sources), "], $scope, $aliases)"))))
def js_constructor_record_exact(fields: Maybe<&2, String>, key: String) -> String:
  match fields:
    case Some{source}: String.append("({$:", String.append(js_quote(key), String.append(source, "})")))
    case None{}: "(()=>{throw \"bend: constructor field count mismatch\"})()"
# Literal properties evaluate live arguments left-to-right; erased slots never
# become expressions or properties. __proto__ must be an own data property.
def js_constructor_record_fields(fields: List<&2, AST.TelescopeItem>, sources: List<&2, String>) -> Maybe<&2, String>:
  match fields sources:
    case Nil{} Nil{}: Some{""}
    case AST.Binder{AST.QZero{}, _, _, _, _} <> rest _ <> more:
      js_constructor_record_fields(rest, more)
    case AST.Binder{_, name, _, _, _} <> rest +source <> more:
      js_constructor_record_field(js_constructor_record_fields(rest, more), name, source)
    case _ _: None{}
def js_constructor_record_field(rest: Maybe<&2, String>, name: String, source: String) -> Maybe<&2, String>:
  match rest:
    case None{}: None{}
    case Some{suffix}: Some{String.append(", ", String.append(js_object_key(name), String.append(source, suffix)))}
def js_object_key(name: String) -> String:
  match name:
    case "__proto__": "[\"__proto__\"]:"
    case _: String.append(js_quote(name), ":")
def ctor_short(key: String) -> String:
  ctor_short_chars(List.reverse(&2, Char, String.to_list(key)), Nil{})

def ctor_short_chars(reversed_key: List<&2, Char>, suffix: List<&2, Char>) -> String:
  match reversed_key:
    case Nil{}: String.from_list(suffix)
    case +char <> rest:
      match char:
        case '.': String.from_list(suffix)
        case '/': String.from_list(suffix)
        case _: ctor_short_chars(rest, char <> suffix)

def js_match(head: AST.SyntaxTerm, matched: AST.SyntaxTerm, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  name = String.append("$v", Nat.show(env_depth(env)))
  bound = env_bind(name, js_type(matched, env), Some{js_close(matched, env)}, env)
  prefix = String.append("(()=>{const ", String.append(name, "="))
  String.append(prefix, String.append(js_term(matched, env), String.append("; return ", String.append(js_term_tail_expected(head, bound, expected), ";})()"))))


def pattern_test(pattern: AST.SyntaxPattern, value: String, env: EmitEnv) -> String:
  match pattern:
    case AST.PatternVar{ _,  _,  _,  _}: "true"
    case AST.PatternCtr{key, fields, _}: pattern_test_constructor(js_constructor_decl(key, env), key, fields, value, env)

def pattern_test_constructor(found: Maybe<&2, EmitConstructor>, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match found:
    case None{}: pattern_test_ctor(key, fields, value, env)
    case Some{EmitConstructor{canonical, family, _, binders, declaration_env}}:
      identity = js_constructor_native_origin(js_base_origin(declaration_env), family, canonical)
      pattern_test_native_literal(js_native_word_pattern(identity, fields, env), identity, canonical, fields, binders, value, env)
def pattern_test_constructor_tagged(tagged: Bool, key: String, tag: String, fields: List<&2, AST.SyntaxPattern>, binders: List<&2, AST.TelescopeItem>, value: String, env: EmitEnv) -> String:
  match tagged:
    case False{}: pattern_test_ctor(key, fields, value, env)
    case True{}:
      String.append("(", String.append(value, String.append(" && ", String.append(value, String.append(".$ === ", String.append(js_quote(tag), String.append(" && ", String.append(pattern_decl_fields_test(fields, binders, value, env), ")"))))))))
# A native scalar's complete Base Word pattern observes only its 32 bits.
# Open/nested consumer patterns and explicit Word values keep normal projections.
def pattern_test_native_literal(bits: Maybe<&2, Nat>, key: String, tag: String, fields: List<&2, AST.SyntaxPattern>, binders: List<&2, AST.TelescopeItem>, value: String, env: EmitEnv) -> String:
  match bits:
    case None{}: pattern_test_constructor_tagged(String.eq(js_constructor_native(key), ""), key, tag, fields, binders, value, env)
    case Some{number}:
      pattern_test_native_bits(String.eq(key, "F32.F32"), number, value)
def pattern_test_native_bits(floating: Bool, bits: Nat, value: String) -> String:
  match floating:
    case False{}: String.append("((", String.append(value, String.append(" >>> 0) === ", String.append(Nat.show(bits), ")"))))
    case True{}: String.append("(f32_bits(", String.append(value, String.append(") === ", String.append(Nat.show(bits), ")"))))
def js_native_word_pattern(identity: String, fields: List<&2, AST.SyntaxPattern>, env: EmitEnv) -> Maybe<&2, Nat>:
  match identity fields:
    case "U32.U32" +word <> Nil{}: js_closed_word_pattern(32n, word, env)
    case "F32.F32" +word <> Nil{}: js_closed_word_pattern(32n, word, env)
    case _ _: None{}
def js_closed_word_pattern(+remaining: Nat, pattern: AST.SyntaxPattern, env: EmitEnv) -> Maybe<&2, Nat>:
  match pattern:
    case AST.PatternCtr{key, fields, _}:
      js_closed_word_pattern_constructor(remaining, js_word_identity(js_constructor_decl(key, env)), fields, env)
    case _: None{}
def js_closed_word_pattern_constructor(+remaining: Nat, identity: String, fields: List<&2, AST.SyntaxPattern>, env: EmitEnv) -> Maybe<&2, Nat>:
  match remaining identity fields:
    case 0n "Word.Nil.WNil" Nil{}: Some{0n}
    case 1n+rest "Word.Con.WCon" +bit <> +tail <> Nil{}:
      js_closed_word_pattern_bit(js_closed_bit_pattern(bit, env), rest, tail, env)
    case _ _ _: None{}
def js_closed_bit_pattern(pattern: AST.SyntaxPattern, env: EmitEnv) -> Maybe<&2, Nat>:
  match pattern:
    case AST.PatternCtr{key, Nil{}, _}: js_closed_bit_identity(js_word_identity(js_constructor_decl(key, env)))
    case _: None{}
def js_closed_word_pattern_bit(bit: Maybe<&2, Nat>, remaining: Nat, tail: AST.SyntaxPattern, env: EmitEnv) -> Maybe<&2, Nat>:
  match bit:
    case None{}: None{}
    case Some{low}: js_closed_word_combine(low, js_closed_word_pattern(remaining, tail, env))
# Both source and native constructors expose ordinary named data properties.
def js_field_projection(value: String, name: String) -> String:
  String.append("(", String.append(value, String.append(")[", String.append(js_quote(name), "]"))))
def pattern_decl_fields_test(fields: List<&2, AST.SyntaxPattern>, binders: List<&2, AST.TelescopeItem>, value: String, env: EmitEnv) -> String:
  match fields binders:
    case Nil{} Nil{}: "true"
    case _ <> rest AST.Binder{AST.QZero{}, _, _, _, _} <> more:
      pattern_decl_fields_test(rest, more, value, env)
    case +field <> rest AST.Binder{_, name, _, _, _} <> more:
      field_value = js_field_projection(value, name)
      String.append("(", String.append(pattern_test(field, field_value, env), String.append(" && ", String.append(pattern_decl_fields_test(rest, more, value, env), ")"))))
    case _ _: "false"

# Select the representation before recursively emitting child patterns.
# Eager choice arguments multiply nested work and build discarded huge strings.
def pattern_test_ctor(key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  pattern_test_true(String.eq(key, "Bool.True"), key, fields, value, env)

def pattern_test_true(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}: String.append("(", String.append(value, " === true)"))
    case False{}: pattern_test_false(String.eq(key, "Bool.False"), key, fields, value, env)

def pattern_test_false(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}: String.append("(", String.append(value, " === false)"))
    case False{}: pattern_test_zero(String.eq(key, "Nat.Zero"), key, fields, value, env)

def pattern_test_zero(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}: String.append("(", String.append(value, " === 0)"))
    case False{}: pattern_test_succ(String.eq(key, "Nat.Succ"), key, fields, value, env)

def pattern_test_succ(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}:
      child = String.append("(", String.append(value, " - 1)"))
      String.append("(", String.append(value, String.append(" > 0 && ", String.append(patterns_test(fields, [child], env), ")"))))
    case False{}: pattern_test_snil(String.eq(key, "String.SNil"), key, fields, value, env)

def pattern_test_snil(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}: String.append("(", String.append(value, " === \"\")"))
    case False{}: pattern_test_scon(String.eq(key, "String.SCon"), key, fields, value, env)

def pattern_test_scon(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}:
      children = {[pattern_string_field_value(value, 0n), pattern_string_field_value(value, 1n)]: List<&2, String>}
      String.append("(", String.append(value, String.append(" !== \"\" && ", String.append(patterns_test(fields, children, env), ")"))))
    case False{}: pattern_test_u32(String.eq(key, "U32.U32"), key, fields, value, env)

def pattern_test_u32(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}:
      child = String.append("u32_to_word(", String.append(value, ")"))
      patterns_test(fields, [child], env)
    case False{}: pattern_test_f32(String.eq(key, "F32.F32"), key, fields, value, env)

def pattern_test_f32(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}:
      child = String.append("u32_to_word(f32_bits(", String.append(value, "))"))
      patterns_test(fields, [child], env)
    case False{}: pattern_test_aleaf(String.eq(key, "Array.ALeaf"), key, fields, value, env)

def pattern_test_aleaf(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}:
      String.append("(", String.append(value, String.append(".length === 1 && ", String.append(patterns_test(fields, [String.append(value, "[0]")], env), ")"))))
    case False{}: pattern_test_anode(String.eq(key, "Array.ANode"), key, fields, value, env)

def pattern_test_anode(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}:
      children = {[pattern_array_field_value(value, 0n), pattern_array_field_value(value, 1n)]: List<&2, String>}
      String.append("(", String.append(value, String.append(".length !== 1 && ", String.append(patterns_test(fields, children, env), ")"))))
    case False{}: pattern_test_char(String.eq(key, "Char.Chr"), key, fields, value, env)

def pattern_test_char(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> String:
  match matches:
    case True{}: patterns_test(fields, [String.append(value, ".codePointAt(0)")], env)
    case False{}:
      String.append("(", String.append(value, String.append(" && ", String.append(value, String.append(".$ === ", String.append(js_quote(key), String.append(" && ", String.append(pattern_fields_test(fields, key, value, 0n, env), ")"))))))))
def pattern_fields_test(fields: List<&2, AST.SyntaxPattern>, key: String, value: String, index: Nat, env: EmitEnv) -> String:
  match fields:
    case Nil{}: "true"
    case AST.PatternVar{_, _, AST.QZero{}, _} <> rest:
      pattern_fields_test(rest, key, value, index, env)
    case +field <> rest:
      field_value = js_positional_projection(value, key, index)
      String.append("(", String.append(pattern_test(field, field_value, env), String.append(" && ", String.append(pattern_fields_test(rest, key, value, (index + 1n : Nat), env), ")"))))

def patterns_test(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, String>, env: EmitEnv) -> String:
  match patterns values:
    case Nil{} Nil{}: "true"
    case +pattern <> more_patterns +value <> more_values:
      String.append("(", String.append(pattern_test(pattern, value, env), String.append(" && ", String.append(patterns_test(more_patterns, more_values, env), ")"))))
    case _ _: "false"

def pattern_vars(pattern: AST.SyntaxPattern, value: String, env: EmitEnv) -> List<&2, String>:
  match pattern:
    case AST.PatternVar{ _,  _,  AST.QZero{},  _}: ["null"]
    case AST.PatternVar{ _,  _,  _,  _}: [value]
    case AST.PatternCtr{key, fields, _}: pattern_vars_constructor(js_constructor_decl(key, env), key, fields, value, env)

def pattern_vars_constructor(found: Maybe<&2, EmitConstructor>, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> List<&2, String>:
  match found:
    case None{}: pattern_vars_ctr(key, fields, value, env)
    case Some{EmitConstructor{canonical, family, _, binders, declaration_env}}:
      identity = js_constructor_native_origin(js_base_origin(declaration_env), family, canonical)
      pattern_vars_constructor_tagged(String.eq(js_constructor_native(identity), ""), identity, fields, binders, value, env)
def pattern_vars_constructor_tagged(tagged: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, binders: List<&2, AST.TelescopeItem>, value: String, env: EmitEnv) -> List<&2, String>:
  match tagged:
    case False{}: pattern_vars_ctr(key, fields, value, env)
    case True{}: pattern_decl_fields_vars(fields, binders, value, env)
def pattern_erased_vars(pattern: AST.SyntaxPattern) -> List<&2, String>:
  match pattern:
    case AST.PatternVar{_, _, _, _}: ["null"]
    case AST.PatternCtr{_, fields, _}: patterns_erased_vars(fields)
def patterns_erased_vars(patterns: List<&2, AST.SyntaxPattern>) -> List<&2, String>:
  match patterns:
    case Nil{}: Nil{}
    case +pattern <> rest:
      List.append(&2, String, pattern_erased_vars(pattern), patterns_erased_vars(rest))
def pattern_decl_fields_vars(fields: List<&2, AST.SyntaxPattern>, binders: List<&2, AST.TelescopeItem>, value: String, env: EmitEnv) -> List<&2, String>:
  match fields binders:
    case Nil{} Nil{}: Nil{}
    case +field <> rest AST.Binder{AST.QZero{}, _, _, _, _} <> more:
      List.append(&2, String, pattern_erased_vars(field), pattern_decl_fields_vars(rest, more, value, env))
    case +field <> rest AST.Binder{_, name, _, _, _} <> more:
      field_value = js_field_projection(value, name)
      List.append(&2, String, pattern_vars(field, field_value, env), pattern_decl_fields_vars(rest, more, value, env))
    case _ _: Nil{}

def pattern_vars_ctr(key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> List<&2, String>:
  pattern_vars_succ(String.eq(key, "Nat.Succ"), key, fields, value, env)

def pattern_vars_succ(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> List<&2, String>:
  match matches:
    case True{}:
      child = String.append("(", String.append(value, " - 1)"))
      patterns_vars(fields, [child], env)
    case False{}: pattern_vars_scon(String.eq(key, "String.SCon"), key, fields, value, env)

def pattern_vars_scon(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> List<&2, String>:
  match matches:
    case True{}: pattern_string_fields(fields, value, 0n, env)
    case False{}: pattern_vars_char(String.eq(key, "Char.Chr"), key, fields, value, env)

def pattern_vars_char(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> List<&2, String>:
  match matches:
    case True{}: patterns_vars(fields, [String.append(value, ".codePointAt(0)")], env)
    case False{}: pattern_vars_u32(String.eq(key, "U32.U32"), key, fields, value, env)

def pattern_vars_u32(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> List<&2, String>:
  match matches:
    case True{}:
      child = String.append("u32_to_word(", String.append(value, ")"))
      patterns_vars(fields, [child], env)
    case False{}: pattern_vars_f32(String.eq(key, "F32.F32"), key, fields, value, env)

def pattern_vars_f32(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> List<&2, String>:
  match matches:
    case True{}:
      child = String.append("u32_to_word(f32_bits(", String.append(value, "))"))
      patterns_vars(fields, [child], env)
    case False{}: pattern_vars_aleaf(String.eq(key, "Array.ALeaf"), key, fields, value, env)

def pattern_vars_aleaf(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> List<&2, String>:
  match matches:
    case True{}: patterns_vars(fields, [String.append(value, "[0]")], env)
    case False{}: pattern_vars_anode(String.eq(key, "Array.ANode"), key, fields, value, env)

def pattern_vars_anode(matches: Bool, key: String, fields: List<&2, AST.SyntaxPattern>, value: String, env: EmitEnv) -> List<&2, String>:
  match matches:
    case True{}: pattern_array_fields(fields, value, 0n, env)
    case False{}: pattern_fields_vars(fields, key, value, 0n, env)

def pattern_array_field_value(value: String, index: Nat) -> String:
  match index:
    case 0n: String.append(value, String.append(".slice(0, ", String.append(value, String.append(".length >> 1", ")"))))
    case _: String.append(value, String.append(".slice(", String.append(value, String.append(".length >> 1", ")"))))

def pattern_array_fields(fields: List<&2, AST.SyntaxPattern>, value: String, index: Nat, env: EmitEnv) -> List<&2, String>:
  match fields:
    case Nil{}: Nil{}
    case +field <> rest:
      field_value = pattern_array_field_value(value, index)
      List.append(&2, String, pattern_vars(field, field_value, env), pattern_array_fields(rest, value, (index + 1n : Nat), env))

def pattern_string_field_value(value: String, index: Nat) -> String:
  match index:
    case 0n: String.append("String.fromCodePoint(", String.append(value, ".codePointAt(0))"))
    case _: String.append("$string_tail(", String.append(value, ")"))

def pattern_string_fields(fields: List<&2, AST.SyntaxPattern>, value: String, index: Nat, env: EmitEnv) -> List<&2, String>:
  match fields:
    case Nil{}: Nil{}
    case +field <> rest:
      field_value = pattern_string_field_value(value, index)
      List.append(&2, String, pattern_vars(field, field_value, env), pattern_string_fields(rest, value, (index + 1n : Nat), env))

def pattern_fields_vars(fields: List<&2, AST.SyntaxPattern>, key: String, value: String, index: Nat, env: EmitEnv) -> List<&2, String>:
  match fields:
    case Nil{}: Nil{}
    case AST.PatternVar{_, _, AST.QZero{}, _} <> rest:
      "null" <> pattern_fields_vars(rest, key, value, index, env)
    case +field <> rest:
      field_value = js_positional_projection(value, key, index)
      List.append(&2, String, pattern_vars(field, field_value, env), pattern_fields_vars(rest, key, value, (index + 1n : Nat), env))
def js_positional_projection(value: String, key: String, index: Nat) -> String:
  String.append("$project(", String.append(value, String.append(",", String.append(js_quote(key), String.append(",", String.append(Nat.show(index), ",$scope,$aliases)"))))))

def patterns_vars(patterns: List<&2, AST.SyntaxPattern>, values: List<&2, String>, env: EmitEnv) -> List<&2, String>:
  match patterns values:
    case Nil{} Nil{}: Nil{}
    case +pattern <> more_patterns +value <> more_values:
      List.append(&2, String, pattern_vars(pattern, value, env), patterns_vars(more_patterns, more_values, env))
    case _ _: Nil{}

def js_case(patterns: List<&2, AST.SyntaxPattern>, body: AST.SyntaxTerm, values: List<&2, String>, scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  types = js_pattern_types(patterns, js_scrutinee_types(scrutinees, env), env)
  js_case_typed(patterns, body, values, types, env, expected)
def js_case_typed(patterns: List<&2, AST.SyntaxPattern>, body: AST.SyntaxTerm, values: List<&2, String>, types: List<&2, Maybe<&2, EmitClosure>>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  test = patterns_test(patterns, values, env)
  String.append("if (", String.append(test, String.append(") ", js_case_block_typed(patterns, body, values, types, env, expected))))
def js_case_block_typed(patterns: List<&2, AST.SyntaxPattern>, body: AST.SyntaxTerm, values: List<&2, String>, types: List<&2, Maybe<&2, EmitClosure>>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  projections = patterns_vars(patterns, values, env)
  names = js_case_binding_names(projections, env_depth(env))
  case_env = env_names_typed(names, types, env)
  bindings = js_case_bindings(projections, names)
  String.append("{ ", String.append(bindings, String.append(js_statement_tail(body, case_env, expected), " }")))
# Snapshot branch projections before nested matches can shadow their scrutinees.
# Erased pattern slots stay null and never evaluate a projection.
def js_case_binding_names(values: List<&2, String>, index: Nat) -> List<&2, String>:
  match values:
    case Nil{}: Nil{}
    case +value <> rest:
      js_case_binding_name(String.eq(value, "null"), index) <> js_case_binding_names(rest, (index + 1n : Nat))
def js_case_binding_name(erased: Bool, index: Nat) -> String:
  match erased:
    case True{}: "null"
    case False{}: String.append("$p", Nat.show(index))
def js_case_bindings(values: List<&2, String>, names: List<&2, String>) -> String:
  match values names:
    case Nil{} Nil{}: ""
    case +value <> rest +name <> more:
      js_case_binding_source(String.eq(name, "null"), name, value, js_case_bindings(rest, more))
    case _ _: "throw \"bend: malformed pattern bindings\";"
def js_case_binding_source(erased: Bool, name: String, value: String, rest: String) -> String:
  match erased:
    case True{}: rest
    case False{}:
      String.append("const ", String.append(name, String.append("=", String.append(value, String.append(";", rest)))))

def js_cases(cases: List<&2, AST.SyntaxTerm>, values: List<&2, String>, scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match cases:
    case Nil{}: "throw \"bend: runtime fail-stop\";"
    case +term <> rest:
      match term:
        case AST.BodyCase{patterns, body, _}:
          String.append(js_case(patterns, body, values, scrutinees, env, expected), String.append("\n", js_cases(rest, values, scrutinees, env, expected)))
        case _: js_cases(rest, values, scrutinees, env, expected)

# A single pass records resolved canonical tags in the existing persistent Map.
# Any native head, nested field, unknown row or tag collision keeps ordered tests.
def js_switch_tags(cases: List<&2, AST.SyntaxTerm>, env: EmitEnv, seen: Map<&2, Bool>) -> Maybe<&2, List<&2, String>>:
  match cases:
    case Nil{}: Some{Nil{}}
    case AST.BodyCase{AST.PatternCtr{key, fields, _} <> Nil{}, _, _} <> rest:
      js_switch_tag_fields(js_switch_fields(fields), key, rest, env, seen)
    case _ <> _: None{}
def js_switch_fields(fields: List<&2, AST.SyntaxPattern>) -> Bool:
  match fields:
    case Nil{}: True{}
    case AST.PatternVar{_, _, _, _} <> rest: js_switch_fields(rest)
    case _ <> _: False{}
def js_switch_tag_constructor(found: Maybe<&2, EmitConstructor>, rest: List<&2, AST.SyntaxTerm>, env: EmitEnv, seen: Map<&2, Bool>) -> Maybe<&2, List<&2, String>>:
  match found:
    case None{}: None{}
    case Some{EmitConstructor{canonical, family, _, _, declaration_env}}:
      identity = js_constructor_native_origin(js_base_origin(declaration_env), family, canonical)
      js_switch_tag_native(String.eq(js_constructor_native(identity), ""), canonical, rest, env, seen)
def js_switch_tag_fields(variables: Bool, key: String, rest: List<&2, AST.SyntaxTerm>, env: EmitEnv, seen: Map<&2, Bool>) -> Maybe<&2, List<&2, String>>:
  match variables:
    case False{}: None{}
    case True{}: js_switch_tag_constructor(js_constructor_decl(key, env), rest, env, seen)
def js_switch_tag_seen(found: Maybe<&2, Bool>, tag: String, rest: List<&2, AST.SyntaxTerm>, env: EmitEnv, seen: Map<&2, Bool>) -> Maybe<&2, List<&2, String>>:
  match found:
    case Some{_}: None{}
    case None{}:
      js_switch_tag_rest(tag, js_switch_tags(rest, env, Map.set(&2, Bool, seen, tag, True{})))
def js_switch_tag_native(tagged: Bool, tag: String, rest: List<&2, AST.SyntaxTerm>, env: EmitEnv, seen: Map<&2, Bool>) -> Maybe<&2, List<&2, String>>:
  match tagged:
    case False{}: None{}
    case True{}: js_switch_tag_ordered(js_switch_bmp_tag(tag), tag, rest, env, seen)
def js_switch_tag_ordered(ordered: Bool, tag: String, rest: List<&2, AST.SyntaxTerm>, env: EmitEnv, seen: Map<&2, Bool>) -> Maybe<&2, List<&2, String>>:
  match ordered:
    case False{}: None{}
    case True{}: js_switch_tag_seen(IndexLookup.find(Bool, seen, tag), tag, rest, env, seen)
# Code-point and UTF-16 order agree for BMP tags. Astral namespace paths retain
# ordered case tests instead of a binary tree sorted with a different comparator.
def js_switch_bmp_tag(tag: String) -> Bool:
  match tag:
    case SNil{}: True{}
    case SCon{char, rest}: js_switch_bmp_tail(U32.is_le(Char.to_u32(char), 65535), rest)
def js_switch_bmp_tail(bmp: Bool, rest: String) -> Bool:
  match bmp:
    case False{}: False{}
    case True{}: js_switch_bmp_tag(rest)
def js_switch_tag_rest(tag: String, rest: Maybe<&2, List<&2, String>>) -> Maybe<&2, List<&2, String>>:
  match rest:
    case None{}: None{}
    case Some{tags}: Some{tag <> tags}
def js_switch_cases(cases: List<&2, AST.SyntaxTerm>, tags: List<&2, String>, values: List<&2, String>, scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match cases tags:
    case Nil{} Nil{}: "default: { throw \"bend: runtime fail-stop\"; }\n"
    case AST.BodyCase{patterns, body, _} <> rest +tag <> more:
      types = js_pattern_types(patterns, js_scrutinee_types(scrutinees, env), env)
      branch = String.append("case ", String.append(js_quote(tag), String.append(": ", js_case_block_typed(patterns, body, values, types, env, expected))))
      String.append(branch, String.append("\n", js_switch_cases(rest, more, values, scrutinees, env, expected)))
    case _ _: "default: { throw \"bend: malformed switch cases\"; }\n"

# Pair each resolved canonical tag with its original case before sorting; no AST
# or field layout is rewritten. The BMP eligibility certificate above guarantees
# that String.is_le agrees with the generated JavaScript UTF-16 comparison.
def js_switch_pairs(cases: List<&2, AST.SyntaxTerm>, tags: List<&2, String>) -> List<&2, EmitSwitchRow>:
  match cases tags:
    case +term <> rest +tag <> more:
      EmitSwitchRow{tag, term} <> js_switch_pairs(rest, more)
    case _ _: Nil{}
def js_switch_row_le(left: EmitSwitchRow, right: EmitSwitchRow) -> Bool:
  match left right:
    case EmitSwitchRow{left_tag, _} EmitSwitchRow{right_tag, _}:
      String.is_le(left_tag, right_tag)

# Keep the comparator a saturated source call: typed steps cannot pass a pending
# computation as the higher-order callback of the native Base List.sort.
def js_switch_sort(count: Nat, +rows: List<&2, EmitSwitchRow>) -> List<&2, EmitSwitchRow>:
  match count:
    case 0n: Nil{}
    case 1n: rows
    case _:
      half = Nat.div(count, 2n)
      left = List.take(&2, EmitSwitchRow, rows, half)
      right = List.drop(&2, EmitSwitchRow, rows, half)
      js_switch_merge(js_switch_sort(half, left), js_switch_sort((count - half : Nat), right))
def js_switch_merge(left: List<&2, EmitSwitchRow>, right: List<&2, EmitSwitchRow>) -> List<&2, EmitSwitchRow>:
  match left:
    case Nil{}: right
    case +head <> +tail:
      js_switch_merge_right(right, head, tail)
def js_switch_merge_right(right: List<&2, EmitSwitchRow>, +head: EmitSwitchRow, +tail: List<&2, EmitSwitchRow>) -> List<&2, EmitSwitchRow>:
  match right:
    case Nil{}: head <> tail
    case +other <> +rest:
      js_switch_merge_order(js_switch_row_le(head, other), head, tail, other, rest)
def js_switch_merge_order(first: Bool, +head: EmitSwitchRow, +tail: List<&2, EmitSwitchRow>, +other: EmitSwitchRow, +rest: List<&2, EmitSwitchRow>) -> List<&2, EmitSwitchRow>:
  match first:
    case True{}: head <> js_switch_merge(tail, other <> rest)
    case False{}: other <> js_switch_merge(head <> tail, rest)

# Only exact equality at a leaf selects a case. Missing tags fall through the
# entire tree to the one original fail-stop after it, not one per leaf.
def js_switch_tree(count: Nat, rows: List<&2, EmitSwitchRow>, name: String, values: List<&2, String>, scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match count:
    case 0n: ""
    case 1n: js_switch_tree_leaf(rows, name, values, scrutinees, env, expected)
    case _:
      half = Nat.div(count, 2n)
      left = List.take(&2, EmitSwitchRow, rows, half)
      right = List.drop(&2, EmitSwitchRow, rows, half)
      js_switch_tree_split(right, left, half, (count - half : Nat), name, values, scrutinees, env, expected)
def js_switch_tree_leaf(rows: List<&2, EmitSwitchRow>, name: String, values: List<&2, String>, scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match rows:
    case EmitSwitchRow{tag, AST.BodyCase{patterns, body, _}} <> Nil{}:
      types = js_pattern_types(patterns, js_scrutinee_types(scrutinees, env), env)
      branch = js_case_block_typed(patterns, body, values, types, env, expected)
      String.append("if (", String.append(name, String.append(" === ", String.append(js_quote(tag), String.append(") ", String.append(branch, "\n"))))))
    case _: "throw \"bend: malformed switch cases\";"
def js_switch_tree_split(right: List<&2, EmitSwitchRow>, left: List<&2, EmitSwitchRow>, left_count: Nat, right_count: Nat, name: String, values: List<&2, String>, scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match right:
    case EmitSwitchRow{pivot, _} <> _:
      left_source = js_switch_tree(left_count, left, name, values, scrutinees, env, expected)
      right_source = js_switch_tree(right_count, right, name, values, scrutinees, env, expected)
      test = String.append("if (", String.append(name, String.append(" < ", String.append(js_quote(pivot), ") {\n"))))
      String.append(test, String.append(left_source, String.append("} else {\n", String.append(right_source, "}\n"))))
    case Nil{}: "throw \"bend: malformed switch cases\";"
def js_cases_dispatch_size(large: Bool, count: Nat, keys: List<&2, String>, value: String, cases: List<&2, AST.SyntaxTerm>, values: List<&2, String>, scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match large:
    case False{}:
      prefix = String.append("switch (", String.append(value, String.append(" && ", String.append(value, ".$) {\n"))))
      String.append(prefix, String.append(js_switch_cases(cases, keys, values, scrutinees, env, expected), "}"))
    case True{}:
      name = String.append("$tag", Nat.show(env_depth(env)))
      branch_env = env_reserve_names(1n, env)
      rows = js_switch_sort(count, js_switch_pairs(cases, keys))
      prefix = String.append("const ", String.append(name, String.append(" = ", String.append(value, String.append(" && ", String.append(value, ".$;\n"))))))
      tree = js_switch_tree(count, rows, name, values, scrutinees, branch_env, expected)
      guarded = String.append("if (typeof ", String.append(name, String.append(" === \"string\") {\n", String.append(tree, "}\n"))))
      String.append(prefix, String.append(guarded, "throw \"bend: runtime fail-stop\";"))
def js_cases_dispatch_values(values: List<&2, String>, scrutinees: List<&2, AST.SyntaxTerm>, cases: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match values scrutinees cases:
    case +value <> Nil{} _ <> Nil{} _ <> _:
      js_cases_dispatch_switch(js_switch_tags(cases, env, MTip{}), value, cases, values, scrutinees, env, expected)
    case _ _ _: js_cases(cases, values, scrutinees, env, expected)
def js_cases_dispatch(cases: List<&2, AST.SyntaxTerm>, values: List<&2, String>, scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  js_cases_dispatch_values(values, scrutinees, cases, env, expected)
def js_cases_dispatch_switch(tags: Maybe<&2, List<&2, String>>, value: String, cases: List<&2, AST.SyntaxTerm>, values: List<&2, String>, scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  match tags:
    case None{}: js_cases(cases, values, scrutinees, env, expected)
    case Some{keys}:
      count = List.length(&2, String, keys)
      js_cases_dispatch_size(Nat.is_ge(count, 32n), count, keys, value, cases, values, scrutinees, env, expected)

def js_scrutinees(scrutinees: List<&2, AST.SyntaxTerm>, env: EmitEnv, index: Nat) -> String:
  match scrutinees:
    case Nil{}: ""
    case +term <> rest:
      name = String.append("$s", Nat.show((env_depth(env) + index : Nat)))
      String.append("const ", String.append(name, String.append(" = ", String.append(js_term(term, env), String.append(";\n", js_scrutinees(rest, env, (index + 1n : Nat)))))))

def scrutinee_names(count: Nat, env: EmitEnv) -> List<&2, String>:
  scrutinee_names_at(count, env_depth(env))

def scrutinee_names_at(count: Nat, index: Nat) -> List<&2, String>:
  match count:
    case 0n: Nil{}
    case _: String.append("$s", Nat.show(index)) <> scrutinee_names_at((count - 1n : Nat), (index + 1n : Nat))

def js_body_match(scrutinees: List<&2, AST.SyntaxTerm>, cases: List<&2, AST.SyntaxTerm>, env: EmitEnv, expected: Maybe<&2, EmitClosure>) -> String:
  String.append("(()=>{", String.append(js_statement_match(scrutinees, cases, env, expected), "})()"))

def js_binders(binders: List<&2, AST.TelescopeItem>, env: EmitEnv, body: AST.SyntaxTerm, result: AST.OptionalTerm) -> String:
  match binders:
    case Nil{}:
      match result:
        case AST.SomeTerm{ty}: js_term_tail_expected(body, env, Some{js_close(ty, env)})
        case AST.NoTerm{}: js_term_tail_expected(body, env, None{})
    case AST.Binder{AST.QZero{}, _, _, ty, _} <> rest:
      js_binders(rest, env_bind("null", Some{js_close(ty, env)}, None{}, env), body, result)
    case AST.Binder{_, _, _, ty, _} <> rest:
      name = String.append("$a", Nat.show(env_depth(env)))
      js_closure(name, js_binders(rest, env_bind(name, Some{js_close(ty, env)}, None{}, env), body, result))
    case AST.TemplateBinder{_, _, _, _} <> rest: js_binders(rest, env_push("null", env), body, result)
def js_decl(namespace: String, source_path: String, declaration: AST.TopLevel, env: EmitEnv) -> String:
  match declaration:
    case AST.DefTop{AST.Definition{key, binders, result, body, _, _}}:
      match body:
        case AST.DefTerm{term}:
          js_decl_term(js_definition_is_type(binders, result, term, env), qualify(namespace, key), binders, result, term, env)
        case AST.DefImports{paths}:
          full_key = qualify(namespace, key)
          js_decl_deferred_value(full_key, js_foreign(paths, key, source_path, binders))
    case AST.TypeTop{ _}: ""
    case AST.LawTop{AST.LawDecl{key, clauses, _, _}}:
      js_decl_native_law(js_native_operation(key, env), js_native_law_binders(clauses, 0n), qualify(namespace, key))
def js_decl_term(type_only: Bool, key: String, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, term: AST.SyntaxTerm, env: EmitEnv) -> String:
  match type_only:
    case True{}: ""
    case False{}:
      js_decl_term_operation(js_native_operation(key, env), key, binders, result, term, env)
def js_decl_term_operation(operation: Maybe<&2, String>, key: String, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, term: AST.SyntaxTerm, env: EmitEnv) -> String:
  match operation:
    case Some{name}: js_decl_native_value(key, name, binders)
    case None{}: js_decl_named(js_named_eligible(key, binders, result, term, env), key, binders, result, term, env)
# Only a fixed, explicitly checked telescope has an uncurried entry. Nullary
# factories, templates, native/foreign bodies and inferred signatures keep ABI.
def js_named_eligible(key: String, +binders: List<&2, AST.TelescopeItem>, +result: AST.OptionalTerm, +term: AST.SyntaxTerm, +env: EmitEnv) -> Bool:
  js_named_eligible_operation(js_native_operation(key, env), binders, result, term, env)
def js_named_eligible_operation(operation: Maybe<&2, String>, +binders: List<&2, AST.TelescopeItem>, +result: AST.OptionalTerm, +term: AST.SyntaxTerm, +env: EmitEnv) -> Bool:
  match operation:
    case Some{_}: False{}
    case None{}:
      Bool.and(js_named_fixed(binders, result), Bool.and(js_definition_has_live_binder(binders), Bool.not(js_definition_is_type(binders, result, term, env))))
def js_named_fixed(binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm) -> Bool:
  match binders:
    case AST.Binder{_, _, _, _, _} <> rest: js_named_fixed(rest, result)
    case AST.TemplateBinder{_, _, _, _} <> _: False{}
    case Nil{}:
      match result:
        case AST.SomeTerm{_}: True{}
        case AST.NoTerm{}: False{}
def js_decl_named(eligible: Bool, key: String, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, term: AST.SyntaxTerm, env: EmitEnv) -> String:
  match eligible:
    case False{}: js_decl_value(js_definition_has_live_binder(binders), key, js_binders(binders, env, term, result))
    case True{}:
      prefix = String.append("var ", String.append(js_named_identifier(key), " = ("))
      body = js_named_body(binders, env, term, result, True{})
      String.append(prefix, String.append(body, String.append(";\n", js_decl_value(True{}, key, js_named_facade(binders, env, key, Nil{})))))
def js_named_body(binders: List<&2, AST.TelescopeItem>, env: EmitEnv, body: AST.SyntaxTerm, result: AST.OptionalTerm, first: Bool) -> String:
  match binders:
    case Nil{}: String.append(",$td=0) => {", String.append(js_statement_result(body, env, result), "}"))
    case AST.Binder{AST.QZero{}, _, _, ty, _} <> rest:
      js_named_body(rest, env_bind("null", Some{js_close(ty, env)}, None{}, env), body, result, first)
    case AST.Binder{_, _, _, ty, _} <> rest:
      name = String.append("$a", Nat.show(env_depth(env)))
      String.append(js_comma_prefix(first), String.append(name, js_named_body(rest, env_bind(name, Some{js_close(ty, env)}, None{}, env), body, result, False{})))
    case AST.TemplateBinder{_, _, _, _} <> rest: js_named_body(rest, env_push("null", env), body, result, first)
def js_named_facade(binders: List<&2, AST.TelescopeItem>, env: EmitEnv, key: String, names: List<&2, String>) -> String:
  match binders:
    case Nil{}:
      js_named_tail(key, List.reverse(&2, String, names))
    case AST.Binder{AST.QZero{}, _, _, ty, _} <> rest:
      js_named_facade(rest, env_bind("null", Some{js_close(ty, env)}, None{}, env), key, names)
    case AST.Binder{_, _, _, ty, _} <> rest:
      name = String.append("$a", Nat.show(env_depth(env)))
      js_closure(name, js_named_facade(rest, env_bind(name, Some{js_close(ty, env)}, None{}, env), key, name <> names))
    case AST.TemplateBinder{_, _, _, _} <> rest: js_named_facade(rest, env_push("null", env), key, names)
def js_decl_native_law(operation: Maybe<&2, String>, binders: Maybe<&2, List<&2, AST.TelescopeItem>>, key: String) -> String:
  match operation binders:
    case Some{name} Some{items}: js_decl_native_value(key, name, items)
    case _ _: ""
def js_decl_native_value(key: String, operation: String, binders: List<&2, AST.TelescopeItem>) -> String:
  runtime = js_decl_native_runtime(js_native_primitive_checked(Some{operation}, binders), key, operation)
  prefix = String.append("$TYPEF[", String.append(js_quote(key), String.append("]={n:", Nat.show(List.length(&2, AST.TelescopeItem, binders)))))
  quantities = String.append(",q:[", String.append(js_type_field_quantities(binders, True{}), "],intrinsic:$D["))
  metadata = String.append(prefix, String.append(quantities, String.append(js_quote(key), "]};\n")))
  String.append(runtime, metadata)
def js_decl_native_runtime(primitive: Maybe<&2, EmitPrimitive>, key: String, operation: String) -> String:
  match primitive:
    case None{}: js_decl_value(True{}, key, js_reference_old(operation))
    case Some{EmitPrimitive{parameters, body}}:
      entry = String.append("var ", String.append(js_named_identifier(key), String.append("=(", String.append(String.join(parameters, ","), String.append(")=>", String.append(body, ";\n"))))))
      String.append(entry, js_decl_value(True{}, key, js_native_facade(parameters, parameters, key)))
def js_native_facade(parameters: List<&2, String>, names: List<&2, String>, key: String) -> String:
  match parameters:
    case Nil{}:
      String.append(js_named_identifier(key), String.append("(", String.append(String.join(names, ","), ")")))
    case name <> rest:
      String.append("(", String.append(name, String.append(")=>", js_native_facade(rest, names, key))))
# Register functions directly; evaluate nullary definitions on every reference.
# Affine results may own mutable arrays, so even successful results cannot be cached.
# Unused values and foreign module initializers never execute during registration.
def js_definition_has_live_binder(binders: List<&2, AST.TelescopeItem>) -> Bool:
  match binders:
    case Nil{}: False{}
    case AST.Binder{AST.QZero{}, _, _, _, _} <> rest: js_definition_has_live_binder(rest)
    case AST.Binder{_, _, _, _, _} <> _: True{}
    case AST.TemplateBinder{_, _, _, _} <> rest: js_definition_has_live_binder(rest)
def js_decl_value(function_value: Bool, key: String, value: String) -> String:
  match function_value:
    case True{}:
      String.append("$D[", String.append(js_quote(key), String.append("] = ", String.append(value, ";"))))
    case False{}: js_decl_deferred_value(key, value)
def js_decl_deferred_value(key: String, value: String) -> String:
  quoted = js_quote(key)
  prefix = String.append("Object.defineProperty($D,", String.append(quoted, ",{enumerable:true,configurable:true,get(){return run_loop("))
  String.append(prefix, String.append(value, ");}});"))
def js_definition_is_type(binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, body: AST.SyntaxTerm, env: EmitEnv) -> Bool:
  match binders:
    case AST.Binder{_, _, _, domain, _} <> rest:
      js_definition_is_type(rest, result, body, env_bind("null", Some{js_close(domain, env)}, None{}, env))
    case AST.TemplateBinder{_, _, _, _} <> _: False{}
    case Nil{}:
      match result:
        case AST.SomeTerm{ty}: js_type_is_sort(js_reduce(js_close(ty, env)))
        case AST.NoTerm{}: js_inferred_is_sort(js_type(body, env))
def js_inferred_is_sort(found: Maybe<&2, EmitClosure>) -> Bool:
  match found:
    case Some{ty}: js_type_is_sort(js_reduce(ty))
    case None{}: False{}
def js_type_is_sort(ty: EmitClosure) -> Bool:
  match ty:
    case EmitClosure{AST.TermType{_, _}, _, _, _, _, _}: True{}
    case EmitClosure{AST.TermAll{_, _, _, domain, body, _}, _, _, _, _, _}:
      env = js_closure_env(ty)
      js_type_is_sort(js_reduce(js_close(body, env_bind("null", Some{js_close(domain, env)}, None{}, env))))
    case _: False{}

def js_live_binders(binders: List<&2, AST.TelescopeItem>) -> Nat:
  match binders:
    case Nil{}: 0n
    case +binder <> rest:
      match binder:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}: js_live_binders(rest)
        case AST.Binder{ _,  _,  _,  _,  _}: (1n + js_live_binders(rest) : Nat)
        case AST.TemplateBinder{ _,  _,  _,  _}: js_live_binders(rest)
def js_foreign(paths: List<&2, String>, key: String, source_path: String, binders: List<&2, AST.TelescopeItem>) -> String:
  match paths:
    case Nil{}: "undefined"
    case +path <> rest:
      js_foreign_path(String.ends_with(path, ".js"), rest, path, key, source_path, binders)

def js_foreign_path(is_js: Bool, rest: List<&2, String>, path: String, key: String, source_path: String, binders: List<&2, AST.TelescopeItem>) -> String:
  match is_js:
    case True{}: String.append("$effect(require(", String.append(js_quote(Path.resolve(source_path, path)), String.append(")[", String.append(js_quote(key), String.append("], require(", String.append(js_quote(Path.resolve(source_path, path)), String.append(")[", String.append(js_quote(String.append(key, "_need")), String.append("], ", String.append(Nat.show(js_live_binders(binders)), ")"))))))))))
    case False{}: js_foreign(rest, key, source_path, binders)

def js_decls(namespace: String, source_path: String, declarations: List<&2, AST.TopLevel>, env: EmitEnv) -> String:
  match declarations:
    case Nil{}: ""
    case +declaration <> rest: String.append(js_decl(namespace, source_path, declaration, env), String.append("\n", js_decls(namespace, source_path, rest, env)))

def alias_namespace(module_path: String, import_path: String, paths: Map<&2, String>) -> String:
  alias_namespace_base(String.eq(import_path, "Base"), module_path, import_path, paths)

def alias_namespace_base(is_base: Bool, module_path: String, import_path: String, paths: Map<&2, String>) -> String:
  match is_base:
    case True{}: ""
    case False{}:
      alias_namespace_found(IndexLookup.find(String, paths, Path.resolve(module_path, import_path)))

def alias_namespace_found(found: Maybe<&2, String>) -> String:
  match found:
    case Some{value}: value
    case None{}: ""

def js_resolved_alias_entries(imports: List<&2, AST.ModuleImport>, paths: Map<&2, String>) -> List<&2, EmitAlias>:
  match imports:
    case Nil{}: Nil{}
    case AST.ModuleImport{path, alias, AST.SpanOf{file, _, _}} <> rest:
      prefix = String.append(alias, ".")
      EmitAlias{alias, prefix, alias_namespace(file, path, paths), String.length(prefix)} <> js_resolved_alias_entries(rest, paths)
def js_resolved_aliases(+entries: List<&2, EmitAlias>, native: Bool, operations: Map<&2, String>) -> EmitAliases:
  EmitAliases{entries, js_alias_source(entries), native, operations}
def js_aliases(imports: EmitAliases) -> String:
  match imports:
    case EmitAliases{_, source, _, _}: source
def js_alias_source(imports: List<&2, EmitAlias>) -> String:
  match imports:
    case Nil{}: "{}"
    case EmitAlias{alias, _, namespace, _} <> rest:
      prefix = String.append("{", js_quote(alias))
      named = String.append(prefix, String.append(":", js_quote(namespace)))
      String.append(named, String.append(js_alias_entries(rest), "}"))
def js_alias_entries(imports: List<&2, EmitAlias>) -> String:
  match imports:
    case Nil{}: ""
    case EmitAlias{alias, _, namespace, _} <> rest:
      entry = String.append(",", js_quote(alias))
      named = String.append(entry, String.append(":", js_quote(namespace)))
      String.append(named, js_alias_entries(rest))

# Lexical blocks retain each module's scope/aliases. Var entries are hoisted to
# the shared JS module, preserving forward calls and ordered duplicate writes.
def js_module(namespace: String, module: AST.Module, imports: EmitAliases, catalog: EmitCatalog) -> String:
  match module:
    case AST.Module{path, _, declarations}:
      opener = String.append("{const $scope=", js_quote(namespace))
      aliases = String.append(";const $aliases=", js_aliases(imports))
      env = EmitEnv{EmitScope{namespace, imports, catalog}, Nil{}, Nil{}, Nil{}, 0n}
      body = String.append(opener, String.append(aliases, String.append(";\n", js_decls(namespace, path, declarations, env))))
      String.append(body, "}\n")

def js_modules(modules: List<&2, Loader.LoadedModule>, catalog: EmitCatalog) -> String:
  js_modules_at(modules, catalog, js_catalog_layouts(catalog))
def js_modules_at(remaining: List<&2, Loader.LoadedModule>, catalog: EmitCatalog, layouts: List<&2, EmitModuleIndex>) -> String:
  match remaining layouts:
    case Loader.LoadedModule{namespace, module} <> rest EmitModuleIndex{_, imports, _, _, _} <> next:
      String.append(js_module(namespace, module, imports, catalog), js_modules_at(rest, catalog, next))
    case _ _: ""
def qualify(namespace: String, key: String) -> String:
  qualify_result(String.eq(namespace, ""), namespace, key)

def qualify_result(empty: Bool, namespace: String, key: String) -> String:
  match empty:
    case True{}: key
    case False{}: String.append(namespace, String.append(".", key))
def first_span(left: Maybe<&2, AST.SourceSpan>, right: Maybe<&2, AST.SourceSpan>) -> Maybe<&2, AST.SourceSpan>:
  match left:
    case Some{value}: Some(value)
    case None{}: right

def error_terms(terms: List<&2, AST.SyntaxTerm>) -> Maybe<&2, AST.SourceSpan>:
  match terms:
    case Nil{}: None{}
    case +term <> rest: first_span(error_term(term), error_terms(rest))

def error_term(term: AST.SyntaxTerm) -> Maybe<&2, AST.SourceSpan>:
  match term:
    case AST.TermHole{ _, span}: Some(span)
    case AST.TermVar{ _,  _,  _}: None{}
    case AST.TermRef{ _,  _}: None{}
    case AST.TermBang{term,  _}: error_term(term)
    case AST.TermSub{ _, value, body,  _}: first_span(error_term(value), error_term(body))
    case AST.TermLet{ _,  _,  _, values, body,  _}: first_span(error_terms(values), error_term(body))
    case AST.TermType{kind,  _}: error_term(kind)
    case AST.TermAnn{term, ty,  _}: first_span(error_term(term), error_term(ty))
    case AST.TermTemplate{term,  _}: error_term(term)
    case AST.TermQuant{}: None{}
    case AST.TermQuantity{ _,  _}: None{}
    case AST.TermMin{left, right,  _}: first_span(error_term(left), error_term(right))
    case AST.TermAll{ _,  _,  _, ty, body,  _}: first_span(error_term(ty), error_term(body))
    case AST.TermLam{ _,  _,  _, body,  _}: error_term(body)
    case AST.TermApp{fn, arg,  _}: first_span(error_term(fn), error_term(arg))
    case AST.TermAdt{ _, args,  _,  _}: error_terms(args)
    case AST.TermCtr{ _, args,  _}: error_terms(args)
    case AST.TermString{_, _, _}: None{}
    case AST.TermFill{head, args,  _}: first_span(error_term(head), error_terms(args))
    case AST.TermPlus{head, args,  _}: first_span(error_term(head), error_terms(args))
    case AST.TermMat{ _, head, matched,  _}: first_span(error_term(head), error_term(matched))
    case AST.TermAbsurd{ _}: None{}
    case AST.TermEqual{left, right, ty,  _}: first_span(error_term(left), first_span(error_term(right), error_term(ty)))
    case AST.TermRefl{ _}: None{}
    case AST.TermRewrite{equation, proof, body,  _}: first_span(error_term(equation), first_span(error_term(proof), error_term(body)))
    case AST.BodyMatch{scrutinees, cases,  _}: first_span(error_terms(scrutinees), error_terms(cases))
    case AST.BodyCase{ _, body,  _}: error_term(body)
    case AST.BodyLocal{ _,  _, values, body,  _}: first_span(error_terms(values), error_term(body))
    case AST.BodyReply{term,  _}: error_term(term)

def error_optional_term(result: AST.OptionalTerm) -> Maybe<&2, AST.SourceSpan>:
  match result:
    case AST.NoTerm{}: None{}
    case AST.SomeTerm{term}: error_term(term)
def error_def_body(body: AST.DefBody) -> Maybe<&2, AST.SourceSpan>:
  match body:
    case AST.DefTerm{term}: error_term(term)
    case AST.DefImports{ _}: None{}

def error_decl(declaration: AST.TopLevel) -> Maybe<&2, AST.SourceSpan>:
  match declaration:
    case AST.DefTop{ AST.Definition{ _, binders, result, body,  _, span}}:
      result_error = error_optional_term(result)
      binder_errors = error_binders(binders)
      body_error = error_def_body(body)
      first_span(result_error, first_span(binder_errors, body_error))
    case AST.TypeTop{ AST.TypeDecl{ _, params, kind, constructors,  _}}:
      first_span(error_term(kind), first_span(error_binders(params), error_constructors(constructors)))
    case AST.LawTop{ AST.LawDecl{ _, clauses, body,  _}}:
      first_span(error_clauses(clauses), error_term(body))

def error_binders(binders: List<&2, AST.TelescopeItem>) -> Maybe<&2, AST.SourceSpan>:
  match binders:
    case Nil{}: None{}
    case +binder <> rest:
      match binder:
        case AST.Binder{ _,  _,  _, ty,  _}: first_span(error_term(ty), error_binders(rest))
        case AST.TemplateBinder{ _,  _, ty,  _}: first_span(error_term(ty), error_binders(rest))

def error_constructors(constructors: List<&2, AST.ConstructorDecl>) -> Maybe<&2, AST.SourceSpan>:
  match constructors:
    case Nil{}: None{}
    case +constructor <> rest:
      match constructor:
        case AST.Constructor{ _, fields,  _}: first_span(error_binders(fields), error_constructors(rest))

def error_condition(condition: Maybe<&2, AST.SyntaxTerm>) -> Maybe<&2, AST.SourceSpan>:
  match condition:
    case None{}: None{}
    case Some{term}: error_term(term)

def error_clauses(clauses: List<&2, AST.Clause>) -> Maybe<&2, AST.SourceSpan>:
  match clauses:
    case Nil{}: None{}
    case +clause <> rest:
      match clause:
        case AST.ClauseFor{ _,  _,  _, ty, condition,  _}:
          condition_error = error_condition(condition)
          first_span(error_term(ty), first_span(condition_error, error_clauses(rest)))

def error_decls(declarations: List<&2, AST.TopLevel>) -> Maybe<&2, AST.SourceSpan>:
  match declarations:
    case Nil{}: None{}
    case +declaration <> rest: first_span(error_decl(declaration), error_decls(rest))

def error_modules(modules: List<&2, Loader.LoadedModule>) -> Maybe<&2, AST.SourceSpan>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{ _,  AST.Module{ _,  _, declarations}}:
          first_span(error_decls(declarations), error_modules(rest))
def template_terms(terms: List<&2, AST.SyntaxTerm>) -> Maybe<&2, AST.SourceSpan>:
  match terms:
    case Nil{}: None{}
    case +term <> rest: first_span(template_term(term), template_terms(rest))
def template_term(term: AST.SyntaxTerm) -> Maybe<&2, AST.SourceSpan>:
  match term:
    case AST.TermTemplate{ _, span}: Some(span)
    case AST.TermVar{ _,  _,  _}: None{}
    case AST.TermRef{ _,  _}: None{}
    case AST.TermBang{term,  _}: template_term(term)
    case AST.TermSub{ _, value, body,  _}: first_span(template_term(value), template_term(body))
    case AST.TermLet{ _,  _,  _, values, body,  _}: first_span(template_terms(values), template_term(body))
    case AST.TermAnn{term, ty,  _}: first_span(template_term(term), template_term(ty))
    case AST.TermType{kind,  _}: template_term(kind)
    case AST.TermQuant{}: None{}
    case AST.TermQuantity{ _,  _}: None{}
    case AST.TermMin{left, right,  _}: first_span(template_term(left), template_term(right))
    case AST.TermAll{ _,  _,  _, ty, body,  _}: first_span(template_term(ty), template_term(body))
    case AST.TermLam{ _,  _,  _, body,  _}: template_term(body)
    case AST.TermApp{fn, arg,  _}: first_span(template_term(fn), template_term(arg))
    case AST.TermAdt{ _, args,  _,  _}: template_terms(args)
    case AST.TermFill{head, args,  _}: first_span(template_term(head), template_terms(args))
    case AST.TermPlus{head, args,  _}: first_span(template_term(head), template_terms(args))
    case AST.TermCtr{ _, args,  _}: template_terms(args)
    case AST.TermString{_, _, _}: None{}
    case AST.TermMat{ _, head, matched,  _}: first_span(template_term(head), template_term(matched))
    case AST.TermAbsurd{ _}: None{}
    case AST.TermEqual{left, right, ty,  _}: first_span(template_term(left), first_span(template_term(right), template_term(ty)))
    case AST.TermRefl{ _}: None{}
    case AST.TermRewrite{equation, proof, body,  _}: first_span(template_term(equation), first_span(template_term(proof), template_term(body)))
    case AST.TermHole{ _,  _}: None{}
    case AST.BodyMatch{scrutinees, cases,  _}: first_span(template_terms(scrutinees), template_terms(cases))
    case AST.BodyCase{ _, body,  _}: template_term(body)
    case AST.BodyLocal{ _,  _, values, body,  _}: first_span(template_terms(values), template_term(body))
    case AST.BodyReply{term,  _}: template_term(term)
def template_binders(binders: List<&2, AST.TelescopeItem>) -> Maybe<&2, AST.SourceSpan>:
  match binders:
    case Nil{}: None{}
    case +binder <> rest:
      match binder:
        case AST.Binder{ _,  _,  _, ty,  _}: first_span(template_term(ty), template_binders(rest))
        case AST.TemplateBinder{ _,  _,  _, span}: Some(span)
def template_constructors(constructors: List<&2, AST.ConstructorDecl>) -> Maybe<&2, AST.SourceSpan>:
  match constructors:
    case Nil{}: None{}
    case +constructor <> rest:
      match constructor:
        case AST.Constructor{ _, fields,  _}: first_span(template_binders(fields), template_constructors(rest))
def template_condition(condition: Maybe<&2, AST.SyntaxTerm>) -> Maybe<&2, AST.SourceSpan>:
  match condition:
    case None{}: None{}
    case Some{term}: template_term(term)

def template_clauses(clauses: List<&2, AST.Clause>) -> Maybe<&2, AST.SourceSpan>:
  match clauses:
    case Nil{}: None{}
    case +clause <> rest:
      match clause:
        case AST.ClauseFor{ _,  _,  _, ty, condition,  _}:
          condition_template = template_condition(condition)
          first_span(template_term(ty), first_span(condition_template, template_clauses(rest)))
def template_optional_term(result: AST.OptionalTerm) -> Maybe<&2, AST.SourceSpan>:
  match result:
    case AST.NoTerm{}: None{}
    case AST.SomeTerm{term}: template_term(term)
def template_def_body(body: AST.DefBody) -> Maybe<&2, AST.SourceSpan>:
  match body:
    case AST.DefTerm{term}: template_term(term)
    case AST.DefImports{ _}: None{}

def template_decl(declaration: AST.TopLevel) -> Maybe<&2, AST.SourceSpan>:
  match declaration:
    case AST.DefTop{ AST.Definition{ _, binders, result, body,  _,  _}}:
      result_template = template_optional_term(result)
      body_template = template_def_body(body)
      first_span(result_template, first_span(template_binders(binders), body_template))
    case AST.TypeTop{ AST.TypeDecl{ _, params, kind, constructors,  _}}:
      first_span(template_term(kind), first_span(template_binders(params), template_constructors(constructors)))
    case AST.LawTop{ AST.LawDecl{ _, clauses, body,  _}}:
      first_span(template_clauses(clauses), template_term(body))
def template_decls(declarations: List<&2, AST.TopLevel>) -> Maybe<&2, AST.SourceSpan>:
  match declarations:
    case Nil{}: None{}
    case +declaration <> rest: first_span(template_decl(declaration), template_decls(rest))
def template_modules(modules: List<&2, Loader.LoadedModule>) -> Maybe<&2, AST.SourceSpan>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{ _,  AST.Module{ _,  _, declarations}}:
          first_span(template_decls(declarations), template_modules(rest))
def has_js_import(paths: List<&2, String>) -> Bool:
  match paths:
    case Nil{}: False{}
    case +path <> rest: Bool.or(String.ends_with(path, ".js"), has_js_import(rest))

def foreign_error_decl(declaration: AST.TopLevel) -> Maybe<&2, AST.SourceSpan>:
  match declaration:
    case AST.DefTop{ AST.Definition{ _,  _,  _, body,  _, span}}:
      match body:
        case AST.DefImports{paths}: foreign_error_js(has_js_import(paths), span)
        case AST.DefTerm{ _}: None{}
    case AST.TypeTop{ _}: None{}
    case AST.LawTop{ _}: None{}

def foreign_error_js(found: Bool, span: AST.SourceSpan) -> Maybe<&2, AST.SourceSpan>:
  match found:
    case True{}: None{}
    case False{}: Some(span)

def foreign_error_decls(declarations: List<&2, AST.TopLevel>) -> Maybe<&2, AST.SourceSpan>:
  match declarations:
    case Nil{}: None{}
    case +declaration <> rest: first_span(foreign_error_decl(declaration), foreign_error_decls(rest))

def foreign_error_modules(modules: List<&2, Loader.LoadedModule>) -> Maybe<&2, AST.SourceSpan>:
  match modules:
    case Nil{}: None{}
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{ _,  AST.Module{ _,  _, declarations}}:
          first_span(foreign_error_decls(declarations), foreign_error_modules(rest))


# Match the native JS ABI: ordinary objects with named, writable, configurable
# data properties, and no positional symbol or per-instance getter closures.
# Runtime metadata retains erased formal slots but never stores them in values.
# Strict operands and public facades force every private tail request before it
# can enter a Bend value. One module-local register bank therefore owns the only
# pending request. The loop captures and clears every argument before invoking
# its target, so strict nested/reentrant calls can safely reuse the same bank.
def js_runtime() -> String:
  "const $D = Object.create(null);\nconst $BEND_TAIL = Symbol(\"bend.tail\");\nconst $td = 64;\nconst $TAIL_PENDING = Object.create(null), $tailArgs = Array(32);\nlet $tailFn, $tailCount=0, $tailUnary, $tailRest;\nfunction tail_many(f,a) { $tailFn=f; $tailCount=-2; $tailRest=a; return $TAIL_PENDING; }\nfunction tail_unary(f,x) { $tailFn=f; $tailCount=-1; $tailUnary=x; return $TAIL_PENDING; }\nfunction tail_named(f,n) { $tailFn=f; $tailCount=n; return $TAIL_PENDING; }\nfunction $run(f, xs) { let x=run_loop(f); for (const a of xs) x=run_loop(x(a)); return x; }\nfunction run_loop(x) { while (x===$TAIL_PENDING) { const f=$tailFn, count=$tailCount; $tailFn=undefined; $tailCount=0; if(count===-1) { const a=$tailUnary; $tailUnary=undefined; x=f(a,$BEND_TAIL); } else x=tail_dispatch(f,count); } return x; }\nfunction tail_dispatch(f,count) { switch(count) {\ncase -2: { const a=$tailRest; $tailRest=undefined; return f(...a); }\ncase 1: { const a0=$tailArgs[0]; $tailArgs[0]=undefined; return f(a0); }\ncase 2: { const a0=$tailArgs[0],a1=$tailArgs[1]; $tailArgs[0]=$tailArgs[1]=undefined; return f(a0,a1); }\ncase 3: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=undefined; return f(a0,a1,a2); }\ncase 4: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=undefined; return f(a0,a1,a2,a3); }\ncase 5: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=undefined; return f(a0,a1,a2,a3,a4); }\ncase 6: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=undefined; return f(a0,a1,a2,a3,a4,a5); }\ncase 7: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=undefined; return f(a0,a1,a2,a3,a4,a5,a6); }\ncase 8: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7); }\ncase 9: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8); }\ncase 10: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9); }\ncase 11: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10); }\ncase 12: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11); }\ncase 13: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12); }\ncase 14: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13); }\ncase 15: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14); }\ncase 16: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15); }\ncase 17: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16); }\ncase 18: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17); }\ncase 19: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18); }\ncase 20: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19); }\ncase 21: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20); }\ncase 22: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21); }\ncase 23: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22); }\ncase 24: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23); }\ncase 25: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24); }\ncase 26: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25); }\ncase 27: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26); }\ncase 28: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27); }\ncase 29: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28); }\ncase 30: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29); }\ncase 31: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30); }\ncase 32: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30],a31=$tailArgs[31]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=$tailArgs[31]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31); }\ndefault: throw \"bend: invalid private tail frame\";\n} }\nfunction run_force(x,raw) { return raw===$BEND_TAIL?x:run_loop(x); }\nfunction run_many(f,a,d=$td) { return d<64?f(...a,d+1):tail_many(f,a); }\nfunction run_tail(f,x) { const j=f[$BEND_TAIL]; return j ? tail_unary(j,x) : f(x); }\nfunction run_clo(j) { j[$BEND_TAIL]=j; return j; }\nfunction nat_chk(x) { if(x>281474976710655) throw \"bend: a Nat past the largest immediate 2^48-1\"; return x; }\nfunction char_new(x) { if(x>0x10ffff || (x>=0xd800 && x<=0xdfff)) throw \"bend: \"+x+\" is not a Unicode scalar value\"; return String.fromCodePoint(x); }\nfunction cmp_new(a,b) { return {$:a<b?\"LT\":a===b?\"EQ\":\"GT\"}; }\nfunction word_to_u32(w) { let x=0; for(let i=0;w.$===\"WCon\";i++,w=w.tail) if(w.head)x|=1<<i; return x>>>0; }\nfunction u32_to_word(x) { let w={$:\"WNil\"}; for(let i=31;i>=0;i--) w={$:\"WCon\",head:!!((x>>>i)&1),tail:w}; return w; }\nfunction run_named1(f,a0,d) { return d<64?f(a0,d+1):($tailArgs[0]=a0,tail_named(f,1)); }\nfunction run_named2(f,a0,a1,d) { return d<64?f(a0,a1,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,tail_named(f,2)); }\nfunction run_named3(f,a0,a1,a2,d) { return d<64?f(a0,a1,a2,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,tail_named(f,3)); }\nfunction run_named4(f,a0,a1,a2,a3,d) { return d<64?f(a0,a1,a2,a3,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,tail_named(f,4)); }\nfunction run_named5(f,a0,a1,a2,a3,a4,d) { return d<64?f(a0,a1,a2,a3,a4,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,tail_named(f,5)); }\nfunction run_named6(f,a0,a1,a2,a3,a4,a5,d) { return d<64?f(a0,a1,a2,a3,a4,a5,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,tail_named(f,6)); }\nfunction run_named7(f,a0,a1,a2,a3,a4,a5,a6,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,tail_named(f,7)); }\nfunction run_named8(f,a0,a1,a2,a3,a4,a5,a6,a7,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,tail_named(f,8)); }\nfunction run_named9(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,tail_named(f,9)); }\nfunction run_named10(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,tail_named(f,10)); }\nfunction run_named11(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,tail_named(f,11)); }\nfunction run_named12(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,tail_named(f,12)); }\nfunction run_named13(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,tail_named(f,13)); }\nfunction run_named14(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,tail_named(f,14)); }\nfunction run_named15(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,tail_named(f,15)); }\nfunction run_named16(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,tail_named(f,16)); }\nfunction run_named17(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,tail_named(f,17)); }\nfunction run_named18(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,tail_named(f,18)); }\nfunction run_named19(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,tail_named(f,19)); }\nfunction run_named20(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,tail_named(f,20)); }\nfunction run_named21(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,tail_named(f,21)); }\nfunction run_named22(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,tail_named(f,22)); }\nfunction run_named23(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,tail_named(f,23)); }\nfunction run_named24(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,tail_named(f,24)); }\nfunction run_named25(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,tail_named(f,25)); }\nfunction run_named26(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,tail_named(f,26)); }\nfunction run_named27(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,tail_named(f,27)); }\nfunction run_named28(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,tail_named(f,28)); }\nfunction run_named29(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,tail_named(f,29)); }\nfunction run_named30(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,tail_named(f,30)); }\nfunction run_named31(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,tail_named(f,31)); }\nfunction run_named32(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,$tailArgs[31]=a31,tail_named(f,32)); }\n"
def js_runtime_extra() -> String:
  "function f32_from_bits(x) { return new Float32Array(new Uint32Array([x]).buffer)[0]; }\nfunction f32_bits(x) { return new Uint32Array(new Float32Array([x]).buffer)[0]; }\nfunction tuple(a,b) { return {$:\"Tuple\",fst:a,snd:b}; }\nfunction f32_show(x) { if(x!==x) return \"nan\"; if(!Number.isFinite(x)||Object.is(x,-0)) return x<0?\"-inf\":x===0?\"-0\":\"inf\"; let s=\"x\"; for(let p=1;p<=9&&Math.fround(Number(s))!==x;p++) s=String(Number(x.toExponential(p-1))); return s; }\nfunction f32_read(s) { const re=/^\\s*[+-]?((\\d+\\.?\\d*|\\.\\d+)(e[+-]?\\d+)?|inf(inity)?|nan)$/i; const v=Number(s.replace(/inf\\w*/i,\"Infinity\")); return re.test(s)?{$:\"Some\",value:Math.fround(v)}:{$:\"None\"}; }\nfunction nat_divmod(a,b) { return b===0?tuple(0,a):tuple(Math.trunc(a/b),a%b); }\nfunction array_new(n,v) { if(n>31) throw \"bend: an array past the deepest block class 31\"; return Array(2 ** n).fill(v); }\nfunction array_node(a,b) { if(a.length!==b.length) throw \"bend: runtime fail-stop\"; return a.concat(b); }\n"
def js_runtime_array() -> String:
  "function array_swap(a,i,v) { const at=i%a.length, old=a[at]; a[at]=v; return tuple(a,old); }\nfunction $string_tail(s) { return s.slice(s.codePointAt(0)>0xFFFF?2:1); }\n"
def js_runtime_foreign() -> String:
  "function $curry(f,n,xs=[]) { return n===0 ? f(...xs) : x => $curry(f,n-1,[...xs,x]); }\nfunction io_emit(value) { return {$:\"Emit\",value}; }\nfunction $effect(f,need,n) { return $curry((...args)=>({$:\"$FFI\",run:f,need,args,kont:io_emit}),n); }\n"
def js_runtime_namespace() -> String:
  "function $key(k,s,a) { let p=null; for (const alias of Object.keys(a)) if(k.startsWith(alias+\".\") && (p===null || alias.length>p.length)) p=alias; const n=p===null?undefined:a[p]; return n===undefined?(s?s+\".\"+k:k):(n?n+\".\":\"\")+k.slice(p.length+1); }\nfunction $resolve(k,s,a) { const q=$key(k,s,a); return $D[Object.hasOwn($D,q)?q:k]; }\nconst $FIELDS=Object.create(null), $PRIMITIVES=Object.create(null), $TYPE=Object.create(null), $TYPEF=Object.create(null), $PARAMS=Object.create(null);\nfunction $ctr(k,x,s,a) { const q=$key(k,s,a), key=Object.hasOwn($FIELDS,q)?q:k, fs=$FIELDS[key]; if(!fs||fs.length!==x.length)throw \"bend: unresolved constructor layout\"; const v={$:key}; for(let i=0;i<fs.length;i++){const f=fs[i];if(f!==null){if(f===\"__proto__\")Object.defineProperty(v,f,{value:x[i],enumerable:true,writable:true,configurable:true});else v[f]=x[i];}} return v; }\nfunction $project(v,k,i,s,a) { const q=$key(k,s,a),fs=$FIELDS[q]||$FIELDS[k]; if(!fs)throw \"bend: unresolved constructor layout\"; for(const f of fs)if(f!==null&&i--===0)return v[f]; throw \"bend: constructor field count mismatch\"; }\n"

def js_runtime_field_names(fields: List<&2, AST.TelescopeItem>) -> String:
  js_runtime_field_names_at(fields, True{})
def js_runtime_field_names_at(fields: List<&2, AST.TelescopeItem>, first: Bool) -> String:
  match fields:
    case Nil{}: ""
    case +field <> rest:
      match field:
        case AST.Binder{ AST.QZero{},  _,  _,  _,  _}:
          prefix = js_comma_prefix(first)
          String.append(prefix, String.append("null", js_runtime_field_names_at(rest, False{})))
        case AST.Binder{ _, key,  _,  _,  _}:
          prefix = js_comma_prefix(first)
          String.append(prefix, String.append(js_quote(key), js_runtime_field_names_at(rest, False{})))
        case AST.TemplateBinder{ _,  _,  _,  _}: String.append("null", js_runtime_field_names_at(rest, False{}))
def js_constructor_fields_one(namespace: String, family: String, native: Bool, constructor: AST.ConstructorDecl) -> String:
  match constructor:
    case AST.Constructor{key, fields,  _}:
      full_key = qualify(namespace, key)
      fields_info = String.append("$FIELDS[", String.append(js_quote(full_key), String.append("] = [", String.append(js_runtime_field_names(fields), "];\n"))))
      native_key = js_constructor_native_origin(native, family, full_key)
      native_info = String.append("$PRIMITIVES[", String.append(js_quote(full_key), String.append("] = ", String.append(js_quote(native_key), ";\n"))))
      String.append(fields_info, native_info)
def js_constructor_fields_constructors(namespace: String, family: String, native: Bool, constructors: List<&2, AST.ConstructorDecl>) -> String:
  match constructors:
    case Nil{}: ""
    case +constructor <> rest:
      String.append(js_constructor_fields_one(namespace, family, native, constructor), js_constructor_fields_constructors(namespace, family, native, rest))
def js_constructor_fields_decl(namespace: String, native: Bool, declaration: AST.TopLevel) -> String:
  match declaration:
    case AST.TypeTop{ AST.TypeDecl{family, _, _, constructors, _}}:
      js_constructor_fields_constructors(namespace, family, native, constructors)
    case _: ""
def js_constructor_fields_decls(namespace: String, native: Bool, declarations: List<&2, AST.TopLevel>) -> String:
  match declarations:
    case Nil{}: ""
    case +declaration <> rest:
      String.append(js_constructor_fields_decl(namespace, native, declaration), js_constructor_fields_decls(namespace, native, rest))
def js_constructor_fields_modules(modules: List<&2, Loader.LoadedModule>) -> String:
  js_constructor_fields_modules_at(modules, modules)
def js_constructor_fields_modules_at(remaining: List<&2, Loader.LoadedModule>, modules: List<&2, Loader.LoadedModule>) -> String:
  match remaining:
    case Nil{}: ""
    case +loaded <> rest:
      match loaded:
        case Loader.LoadedModule{namespace, AST.Module{path, _, declarations}}:
          String.append(js_constructor_fields_decls(namespace, js_base_source(path, modules), declarations), js_constructor_fields_modules_at(rest, modules))

def js_type_ref(key: String, args: List<&2, AST.SyntaxTerm>, scope: String, aliases: String) -> String:
  String.append("({r:", String.append(js_quote(key), String.append(",a:[", String.append(js_type_args(args, scope, aliases, True{}), String.append("],s:", String.append(js_quote(scope), String.append(",i:", String.append(aliases, "})"))))))))
def js_type_args(args: List<&2, AST.SyntaxTerm>, scope: String, aliases: String, first: Bool) -> String:
  match args:
    case Nil{}: ""
    case +term <> rest:
      prefix = js_comma_prefix(first)
      String.append(prefix, String.append(js_type_term(term, scope, aliases), js_type_args(rest, scope, aliases, False{})))
def js_type_sugar_descriptor(key: String, args: List<&2, AST.SyntaxTerm>, head: AST.SyntaxTerm, mode: String, scope: String, aliases: String) -> String:
  String.append("({r:", String.append(js_quote(key), String.append(",a:[", String.append(js_type_args(args, scope, aliases, True{}), String.append("],s:", String.append(js_quote(scope), String.append(",i:", String.append(aliases, String.append(",f:", String.append(mode, String.append(",h:", String.append(js_type_term(head, scope, aliases), "})"))))))))))))
def js_type_sugar(head: AST.SyntaxTerm, args: List<&2, AST.SyntaxTerm>, mode: String, scope: String, aliases: String) -> String:
  match head:
    case AST.TermAnn{term,  _,  _}: js_type_sugar(term, args, mode, scope, aliases)
    case AST.TermRef{key,  _}: js_type_sugar_descriptor(key, args, head, mode, scope, aliases)
    case AST.TermAdt{key,  head_args,  _,  _}:
      js_type_sugar_descriptor(key, List.append(&2, AST.SyntaxTerm, head_args, args), head, mode, scope, aliases)
    case AST.TermApp{fn, arg,  _}:
      js_type_sugar(fn, arg <> args, mode, scope, aliases)
    case AST.TermBang{inner, _}: js_type_sugar(inner, args, mode, scope, aliases)
    case _:
      prefix = String.append("({sugar:", String.append(js_type_term(head, scope, aliases), ",a:["))
      String.append(prefix, String.append(js_type_args(args, scope, aliases, True{}), String.append("],f:", String.append(mode, "})"))))
def js_type_term(term: AST.SyntaxTerm, scope: String, aliases: String) -> String:
  match term:
    case AST.TermFill{head, args,  _}: js_type_sugar(head, args, "1", scope, aliases)
    case AST.TermPlus{head, args,  _}: js_type_sugar(head, args, "2", scope, aliases)
    case AST.TermTemplate{ _,  _}: "(()=>{throw \"bend: unexpanded template\"})()"
    case AST.TermBang{inner, _}: js_type_term(inner, scope, aliases)
    case AST.TermAnn{term,  _,  _}: js_type_term(term, scope, aliases)
    case AST.TermRef{key,  _}: js_type_ref(key, Nil{}, scope, aliases)
    case AST.TermAdt{key, args,  _,  _}: js_type_ref(key, args, scope, aliases)
    case AST.TermApp{_, _, _}: js_type_application(js_app_spine_at(term, Nil{}), scope, aliases)
    case AST.TermVar{_, index, _}:
      String.append("({p:", String.append(Nat.show(index), "})"))
    case AST.TermQuant{}: "({k:\"QK\"})"
    case AST.TermQuantity{ AST.QZero{},  _}: "({k:\"Q\",v:0})"
    case AST.TermQuantity{ AST.QOne{},  _}: "({k:\"Q\",v:1})"
    case AST.TermQuantity{ AST.QMany{},  _}: "({k:\"Q\",v:2})"
    case AST.TermType{kind, _}: String.append("({kind:", String.append(js_type_term(kind, scope, aliases), "})"))
    case AST.TermMin{left, right, _}: js_type_binary("min", left, "right", right, scope, aliases)
    case AST.TermAll{quantity, _, _, domain, body, _}:
      prefix = String.append("({all:", String.append(js_type_term(domain, scope, aliases), String.append(",q:", js_type_quantity(quantity))))
      String.append(prefix, String.append(",body:", String.append(js_type_term(body, scope, aliases), "})")))
    case AST.TermLam{quantity, _, _, body, _}:
      prefix = String.append("({lam:", js_type_term(body, scope, aliases))
      String.append(prefix, String.append(",q:", String.append(js_type_optional_quantity(quantity), "})")))
    case AST.TermCtr{key, args, _}: js_type_constructor(key, args, scope, aliases)
    case AST.TermString{chars, names, span}: js_type_term(AST.string_desugar(chars, names, span), scope, aliases)
    case AST.TermSub{index, value, body, _}:
      prefix = String.append("({sub:", String.append(Nat.show(index), String.append(",value:", js_type_term(value, scope, aliases))))
      String.append(prefix, String.append(",body:", String.append(js_type_term(body, scope, aliases), "})")))
    case AST.TermLet{_, _, _, values, body, _}: js_type_let(values, body, scope, aliases)
    case AST.BodyLocal{patterns, _, values, body, _}:
      prefix = String.append("({local:[", String.append(js_type_args(values, scope, aliases, True{}), "],pat:["))
      bindings = String.append(js_type_patterns_source(patterns, scope, aliases, True{}), "],body:")
      String.append(prefix, String.append(bindings, String.append(js_type_term(body, scope, aliases), "})")))
    case AST.BodyMatch{scrutinees, cases, _}:
      prefix = String.append("({match:[", String.append(js_type_args(scrutinees, scope, aliases, True{}), "],cases:["))
      String.append(prefix, String.append(js_type_cases_source(cases, scope, aliases, True{}), "]})"))
    case AST.BodyCase{_, body, _}: js_type_term(body, scope, aliases)
    case AST.BodyReply{inner, _}: js_type_term(inner, scope, aliases)
    case AST.TermMat{_, head, matched, _}: js_type_binary("bind", matched, "body", head, scope, aliases)
    case AST.TermRewrite{_, _, body, _}: js_type_term(body, scope, aliases)
    case AST.TermEqual{left, right, ty, _}:
      prefix = String.append("({k:\"E\",left:", String.append(js_type_term(left, scope, aliases), String.append(",right:", js_type_term(right, scope, aliases))))
      String.append(prefix, String.append(",ty:", String.append(js_type_term(ty, scope, aliases), "})")))
    case AST.TermRefl{_}: "({k:\"Refl\"})"
    case AST.TermAbsurd{_}: "({fail:\"bend: runtime fail-stop\"})"
    case AST.TermHole{key, _}: String.append("({fail:", String.append(js_quote(String.append("bend: unsolved hole ", key)), "})"))
def js_type_quantity(quantity: AST.Quantity) -> String:
  match quantity:
    case AST.QZero{}: "0"
    case AST.QOne{}: "1"
    case AST.QMany{}: "2"
def js_type_optional_quantity(quantity: Maybe<&2, AST.Quantity>) -> String:
  match quantity:
    case None{}: "null"
    case Some{value}: js_type_quantity(value)
def js_type_binary(first: String, left: AST.SyntaxTerm, second: String, right: AST.SyntaxTerm, scope: String, aliases: String) -> String:
  prefix = String.append("({", String.append(first, String.append(":", js_type_term(left, scope, aliases))))
  String.append(prefix, String.append(",", String.append(second, String.append(":", String.append(js_type_term(right, scope, aliases), "})")))))
def js_type_constructor(key: String, args: List<&2, AST.SyntaxTerm>, scope: String, aliases: String) -> String:
  String.append("({c:", String.append(js_quote(key), String.append(",a:[", String.append(js_type_args(args, scope, aliases, True{}), String.append("],s:", String.append(js_quote(scope), String.append(",i:", String.append(aliases, "})"))))))))
def js_type_application(spine: AST.SyntaxTerm & List<&2, AST.SyntaxTerm>, scope: String, aliases: String) -> String:
  match spine:
    case (AST.TermRef{key, _}, args): js_type_ref(key, args, scope, aliases)
    case (AST.TermBang{AST.TermRef{key, _}, _}, args): js_type_ref(key, args, scope, aliases)
    case (AST.TermAdt{key, head_args, _, _}, args): js_type_ref(key, List.append(&2, AST.SyntaxTerm, head_args, args), scope, aliases)
    case (head, args): js_type_application_args(js_type_term(head, scope, aliases), args, scope, aliases)
def js_type_application_args(fn: String, args: List<&2, AST.SyntaxTerm>, scope: String, aliases: String) -> String:
  match args:
    case Nil{}: fn
    case +arg <> rest:
      source = String.append("({app:", String.append(fn, String.append(",arg:", String.append(js_type_term(arg, scope, aliases), "})"))))
      js_type_application_args(source, rest, scope, aliases)
def js_type_let(values: List<&2, AST.SyntaxTerm>, body: AST.SyntaxTerm, scope: String, aliases: String) -> String:
  String.append("({let:[", String.append(js_type_args(values, scope, aliases, True{}), String.append("],body:", String.append(js_type_term(body, scope, aliases), "})"))))
def js_type_patterns_source(patterns: List<&2, AST.SyntaxPattern>, scope: String, aliases: String, first: Bool) -> String:
  match patterns:
    case Nil{}: ""
    case +pattern <> rest:
      prefix = js_comma_prefix(first)
      String.append(prefix, String.append(js_type_pattern_source(pattern, scope, aliases), js_type_patterns_source(rest, scope, aliases, False{})))
def js_type_pattern_source(pattern: AST.SyntaxPattern, scope: String, aliases: String) -> String:
  match pattern:
    case AST.PatternVar{_, _, quantity, _}:
      String.append("({v:true,q:", String.append(js_type_quantity(quantity), "})"))
    case AST.PatternCtr{key, fields, _}:
      prefix = String.append("({c:", String.append(js_quote(key), String.append(",s:", String.append(js_quote(scope), String.append(",i:", String.append(aliases, ",fields:["))))))
      String.append(prefix, String.append(js_type_patterns_source(fields, scope, aliases, True{}), "]})"))
def js_type_cases_source(cases: List<&2, AST.SyntaxTerm>, scope: String, aliases: String, first: Bool) -> String:
  match cases:
    case Nil{}: ""
    case AST.BodyCase{patterns, body, _} <> rest:
      prefix = String.append(js_comma_prefix(first), String.append("({pat:[", String.append(js_type_patterns_source(patterns, scope, aliases, True{}), "],body:")))
      source = String.append(prefix, String.append(js_type_term(body, scope, aliases), "})"))
      String.append(source, js_type_cases_source(rest, scope, aliases, False{}))
    case _ <> _: "(()=>{throw \"bend: malformed type match\"})()"
def js_type_field_terms(fields: List<&2, AST.TelescopeItem>, scope: String, aliases: String, first: Bool) -> String:
  match fields:
    case Nil{}: ""
    case +field <> rest:
      match field:
        case AST.Binder{_, _, _, ty, _}:
          prefix = js_comma_prefix(first)
          String.append(prefix, String.append(js_type_term(ty, scope, aliases), js_type_field_terms(rest, scope, aliases, False{})))
        case AST.TemplateBinder{ _,  _,  _,  _}: js_type_field_terms(rest, scope, aliases, first)
def js_type_arm(constructor: AST.ConstructorDecl, scope: String, aliases: String) -> String:
  match constructor:
    case AST.Constructor{key, fields,  _}:
      prefix = String.append(js_object_key(qualify(scope, key)), String.append("{types:[", String.append(js_type_field_terms(fields, scope, aliases, True{}), "],q:[")))
      names = String.append("],fields:[", String.append(js_runtime_field_names(fields), "]}"))
      String.append(prefix, String.append(js_type_field_quantities(fields, True{}), names))
def js_type_field_quantities(fields: List<&2, AST.TelescopeItem>, first: Bool) -> String:
  match fields:
    case Nil{}: ""
    case AST.Binder{quantity, _, _, _, _} <> rest:
      String.append(js_comma_prefix(first), String.append(js_type_quantity(quantity), js_type_field_quantities(rest, False{})))
    case AST.TemplateBinder{_, _, _, _} <> rest:
      String.append(js_comma_prefix(first), String.append("0", js_type_field_quantities(rest, False{})))
def js_type_arms(constructors: List<&2, AST.ConstructorDecl>, scope: String, aliases: String, first: Bool) -> String:
  match constructors:
    case Nil{}: ""
    case +constructor <> rest:
      prefix = js_comma_prefix(first)
      String.append(prefix, String.append(js_type_arm(constructor, scope, aliases), js_type_arms(rest, scope, aliases, False{})))
def js_type_decl(namespace: String, imports: EmitAliases, declaration: AST.TopLevel, catalog: EmitCatalog) -> String:
  match declaration:
    case AST.TypeTop{ AST.TypeDecl{key, params,  _, constructors,  _}}:
      aliases = js_aliases(imports)
      full_key = qualify(namespace, key)
      env = EmitEnv{EmitScope{namespace, imports, catalog}, Nil{}, Nil{}, Nil{}, 0n}
      quant_prefix = js_family_quant_prefix(params, env)
      parameter_info = String.append("$PARAMS[", String.append(js_quote(full_key), String.append("]={q:", String.append(Nat.show(quant_prefix), String.append(",n:", String.append(Nat.show(List.length(&2, AST.TelescopeItem, params)), "};\n"))))))
      name_info = String.append("$TYPE[", String.append(js_quote(full_key), String.append("]={name:", String.append(js_quote(key), String.append(",native:", js_type_native_marker(js_base_origin(env), key))))))
      arm_info = String.append(",arms:{", String.append(js_type_arms(constructors, namespace, aliases, True{}), "}};\n"))
      String.append(parameter_info, String.append(name_info, arm_info))
    case _: ""
def js_type_native_marker(native: Bool, key: String) -> String:
  match native:
    case True{}: js_quote(key)
    case False{}: "null"
def js_type_decls(namespace: String, imports: EmitAliases, declarations: List<&2, AST.TopLevel>, catalog: EmitCatalog) -> String:
  match declarations:
    case Nil{}: ""
    case +declaration <> rest:
      String.append(js_type_decl(namespace, imports, declaration, catalog), js_type_decls(namespace, imports, rest, catalog))
def js_type_modules(modules: List<&2, Loader.LoadedModule>, catalog: EmitCatalog) -> String:
  js_type_modules_needed(js_type_needed_modules(modules, EmitTypeNeeded{Nil{}, MTip{}}, catalog), modules, catalog)
def js_type_modules_needed(needed: EmitTypeNeeded, modules: List<&2, Loader.LoadedModule>, catalog: EmitCatalog) -> String:
  match needed:
    case EmitTypeNeeded{definitions, _}:
      String.append(js_type_modules_at(modules, catalog, js_catalog_layouts(catalog)), js_type_function_sources(definitions))
def js_type_modules_at(remaining: List<&2, Loader.LoadedModule>, catalog: EmitCatalog, layouts: List<&2, EmitModuleIndex>) -> String:
  match remaining layouts:
    case Loader.LoadedModule{namespace, AST.Module{_, _, declarations}} <> rest EmitModuleIndex{_, imports, _, _, _} <> next:
      String.append(js_type_decls(namespace, imports, declarations, catalog), js_type_modules_at(rest, catalog, next))
    case _ _: ""
# Collect only actual definition dependencies of type expressions. Register a
# definition before traversing its body so recursive families terminate this
# graph walk without a fuel bound or duplicate emitted bodies.
def js_type_needed_ref(key: String, env: EmitEnv, needed: EmitTypeNeeded) -> EmitTypeNeeded:
  js_type_needed_found(js_global(key, env), needed)
def js_type_needed_found(found: Maybe<&2, EmitClosure>, +needed: EmitTypeNeeded) -> EmitTypeNeeded:
  match found:
    case Some{value}:
      match value:
        case EmitDefinition{key, binders, body, _, _, _, _, _}:
          match needed:
            case EmitTypeNeeded{_, seen}:
              js_type_needed_definition(IndexLookup.find(Bool, seen, key), key, binders, body, js_closure_env(value), needed)
        case _: needed
    case None{}: needed
def js_type_needed_definition(found: Maybe<&2, Bool>, key: String, binders: List<&2, AST.TelescopeItem>, body: AST.SyntaxTerm, env: EmitEnv, needed: EmitTypeNeeded) -> EmitTypeNeeded:
  match found:
    case Some{_}: needed
    case None{}:
      match needed:
        case EmitTypeNeeded{definitions, seen}:
          js_type_needed_term(body, env, EmitTypeNeeded{EmitTypeDefinition{key, binders, body, env} <> definitions, Map.set(&2, Bool, seen, key, True{})})
def js_type_needed_terms(terms: List<&2, AST.SyntaxTerm>, env: EmitEnv, needed: EmitTypeNeeded) -> EmitTypeNeeded:
  match terms:
    case Nil{}: needed
    case +term <> rest: js_type_needed_terms(rest, env, js_type_needed_term(term, env, needed))
def js_type_needed_term(term: AST.SyntaxTerm, env: EmitEnv, needed: EmitTypeNeeded) -> EmitTypeNeeded:
  match term:
    case AST.TermRef{key, _}: js_type_needed_ref(key, env, needed)
    case AST.TermBang{inner, _}: js_type_needed_term(inner, env, needed)
    case AST.TermSub{_, value, body, _}: js_type_needed_terms([value, body], env, needed)
    case AST.TermLet{_, _, _, values, body, _}: js_type_needed_term(body, env, js_type_needed_terms(values, env, needed))
    case AST.TermAnn{inner, ty, _}: js_type_needed_terms([inner, ty], env, needed)
    case AST.TermType{kind, _}: js_type_needed_term(kind, env, needed)
    case AST.TermMin{left, right, _}: js_type_needed_terms([left, right], env, needed)
    case AST.TermAll{_, _, _, domain, body, _}: js_type_needed_terms([domain, body], env, needed)
    case AST.TermLam{_, _, _, body, _}: js_type_needed_term(body, env, needed)
    case AST.TermApp{fn, arg, _}: js_type_needed_terms([fn, arg], env, needed)
    case AST.TermAdt{_, args, _, _}: js_type_needed_terms(args, env, needed)
    case AST.TermFill{head, args, _}: js_type_needed_term(head, env, js_type_needed_terms(args, env, needed))
    case AST.TermPlus{head, args, _}: js_type_needed_term(head, env, js_type_needed_terms(args, env, needed))
    case AST.TermCtr{_, args, _}: js_type_needed_terms(args, env, needed)
    case AST.TermString{_, _, _}: needed
    case AST.TermMat{_, head, matched, _}: js_type_needed_terms([head, matched], env, needed)
    case AST.TermEqual{_, _, ty, _}: js_type_needed_term(ty, env, needed)
    case AST.TermRewrite{_, _, body, _}: js_type_needed_term(body, env, needed)
    case AST.BodyMatch{scrutinees, cases, _}: js_type_needed_terms(cases, env, js_type_needed_terms(scrutinees, env, needed))
    case AST.BodyCase{_, body, _}: js_type_needed_term(body, env, needed)
    case AST.BodyLocal{_, _, values, body, _}: js_type_needed_term(body, env, js_type_needed_terms(values, env, needed))
    case AST.BodyReply{inner, _}: js_type_needed_term(inner, env, needed)
    case _: needed
def js_type_needed_binders(binders: List<&2, AST.TelescopeItem>, env: EmitEnv, needed: EmitTypeNeeded) -> EmitTypeNeeded:
  match binders:
    case Nil{}: needed
    case AST.Binder{_, _, _, ty, _} <> rest: js_type_needed_binders(rest, env, js_type_needed_term(ty, env, needed))
    case AST.TemplateBinder{_, _, ty, _} <> rest: js_type_needed_binders(rest, env, js_type_needed_term(ty, env, needed))
def js_type_needed_result(result: AST.OptionalTerm, env: EmitEnv, needed: EmitTypeNeeded) -> EmitTypeNeeded:
  match result:
    case AST.NoTerm{}: needed
    case AST.SomeTerm{term}: js_type_needed_term(term, env, needed)
def js_type_needed_constructors(constructors: List<&2, AST.ConstructorDecl>, env: EmitEnv, needed: EmitTypeNeeded) -> EmitTypeNeeded:
  match constructors:
    case Nil{}: needed
    case AST.Constructor{_, fields, _} <> rest:
      js_type_needed_constructors(rest, env, js_type_needed_binders(fields, env, needed))
def js_type_needed_declarations(declarations: List<&2, AST.TopLevel>, env: EmitEnv, needed: EmitTypeNeeded) -> EmitTypeNeeded:
  match declarations:
    case Nil{}: needed
    case AST.DefTop{AST.Definition{key, binders, result, body, _, _}} <> rest:
      required = js_type_needed_result(result, env, js_type_needed_binders(binders, env, needed))
      js_type_needed_declarations(rest, env, js_type_needed_definition_root(key, binders, result, body, env, required))
    case AST.TypeTop{AST.TypeDecl{_, params, kind, constructors, _}} <> rest:
      required = js_type_needed_constructors(constructors, env, js_type_needed_term(kind, env, js_type_needed_binders(params, env, needed)))
      js_type_needed_declarations(rest, env, required)
    case AST.LawTop{_} <> rest: js_type_needed_declarations(rest, env, needed)
def js_type_needed_definition_root(key: String, binders: List<&2, AST.TelescopeItem>, result: AST.OptionalTerm, body: AST.DefBody, env: EmitEnv, needed: EmitTypeNeeded) -> EmitTypeNeeded:
  match body:
    case AST.DefImports{_}: needed
    case AST.DefTerm{term}:
      js_type_needed_definition_root_kind(js_definition_is_type(binders, result, term, env), key, env, needed)
def js_type_needed_definition_root_kind(type_only: Bool, key: String, env: EmitEnv, needed: EmitTypeNeeded) -> EmitTypeNeeded:
  match type_only:
    case True{}: js_type_needed_ref(key, env, needed)
    case False{}: needed
def js_type_needed_modules(remaining: List<&2, Loader.LoadedModule>, needed: EmitTypeNeeded, catalog: EmitCatalog) -> EmitTypeNeeded:
  js_type_needed_modules_at(remaining, needed, catalog, js_catalog_layouts(catalog))
def js_type_needed_modules_at(remaining: List<&2, Loader.LoadedModule>, needed: EmitTypeNeeded, catalog: EmitCatalog, layouts: List<&2, EmitModuleIndex>) -> EmitTypeNeeded:
  match remaining layouts:
    case Loader.LoadedModule{namespace, AST.Module{_, _, declarations}} <> rest EmitModuleIndex{_, imports, _, _, _} <> next:
      env = EmitEnv{EmitScope{namespace, imports, catalog}, Nil{}, Nil{}, Nil{}, 0n}
      js_type_needed_modules_at(rest, js_type_needed_declarations(declarations, env, needed), catalog, next)
    case _ _: needed
def js_type_function_sources(definitions: List<&2, EmitTypeDefinition>) -> String:
  match definitions:
    case Nil{}: ""
    case EmitTypeDefinition{key, binders, body, env} <> rest:
      match env:
        case EmitEnv{EmitScope{namespace, imports, _}, _, _, _, _}:
          aliases = js_aliases(imports)
          arity = Nat.show(List.length(&2, AST.TelescopeItem, binders))
          parameters = String.append("$PARAMS[", String.append(js_quote(key), String.append("]={n:", String.append(arity, String.append(",q:", String.append(Nat.show(js_family_quant_prefix(binders, env)), "};\n"))))))
          prefix = String.append("$TYPEF[", String.append(js_quote(key), String.append("]={n:", arity)))
          native = js_type_native_marker(js_base_origin(env), key)
          entry = String.append(parameters, String.append(prefix, String.append(",native:", String.append(native, String.append(",body:", String.append(js_type_term(body, namespace, aliases), "};\n"))))))
          String.append(entry, js_type_function_sources(rest))

def main_type_expr_declaration(declaration: AST.TopLevel, namespace: String, aliases: String) -> String:
  match declaration:
    case AST.DefTop{ AST.Definition{key,  _, result,  _,  _,  _}}:
      main_type_expr_is_main(String.eq(key, "main"), result, namespace, aliases)
    case _: ""

def main_type_expr_is_main(is_main: Bool, result: AST.OptionalTerm, namespace: String, aliases: String) -> String:
  match is_main:
    case False{}: ""
    case True{}:
      match result:
        case AST.SomeTerm{term}: js_type_term(term, namespace, aliases)
        case AST.NoTerm{}: ""

def main_type_expr_declarations(declarations: List<&2, AST.TopLevel>, namespace: String, aliases: String) -> String:
  match declarations:
    case Nil{}: ""
    case +declaration <> rest:
      main_type_expr_declaration_result(main_type_expr_declaration(declaration, namespace, aliases), rest, namespace, aliases)

def main_type_expr_declaration_result(found: String, rest: List<&2, AST.TopLevel>, namespace: String, aliases: String) -> String:
  main_type_expr_declaration_empty(String.eq(found, ""), found, rest, namespace, aliases)

def main_type_expr_declaration_empty(empty: Bool, found: String, rest: List<&2, AST.TopLevel>, namespace: String, aliases: String) -> String:
  match empty:
    case True{}: main_type_expr_declarations(rest, namespace, aliases)
    case False{}: found

def main_type_expr_modules(modules: List<&2, Loader.LoadedModule>, catalog: EmitCatalog) -> String:
  main_type_expr_modules_at(modules, js_catalog_layouts(catalog))
def main_type_expr_modules_at(remaining: List<&2, Loader.LoadedModule>, layouts: List<&2, EmitModuleIndex>) -> String:
  match remaining layouts:
    case Loader.LoadedModule{namespace, AST.Module{_, _, declarations}} <> rest EmitModuleIndex{_, imports, _, _, _} <> next:
      main_type_expr_module_scope(String.eq(namespace, ""), namespace, imports, declarations, rest, next)
    case _ _: "null"

def main_type_expr_module_scope(is_root: Bool, namespace: String, imports: EmitAliases, declarations: List<&2, AST.TopLevel>, rest: List<&2, Loader.LoadedModule>, layouts: List<&2, EmitModuleIndex>) -> String:
  match is_root:
    case False{}: main_type_expr_modules_at(rest, layouts)
    case True{}:
      main_type_expr_module_result(main_type_expr_declarations(declarations, namespace, js_aliases(imports)), rest, layouts)

def main_type_expr_module_result(found: String, rest: List<&2, Loader.LoadedModule>, layouts: List<&2, EmitModuleIndex>) -> String:
  main_type_expr_module_empty(String.eq(found, ""), found, rest, layouts)

def main_type_expr_module_empty(empty: Bool, found: String, rest: List<&2, Loader.LoadedModule>, layouts: List<&2, EmitModuleIndex>) -> String:
  match empty:
    case True{}: main_type_expr_modules_at(rest, layouts)
    case False{}: found

def js_runtime_cli() -> String:
  "const cli_args=[];\nfunction cli(argv) { for(let i=0;i<argv.length;i++){ if(argv[i]===\"--\"){cli_args.push(...argv.slice(i+1));break;} if(argv[i]===\"--help\"){process.stdout.write(\"usage: \"+process.argv[1]+\"\\n\");process.exit(0);} if(argv[i]===\"--threads\"||argv[i]===\"--gpu\"){i++;} else cli_args.push(argv[i]); } }\n"
def js_runtime_io() -> String:
  "function io_out(fd,data) { const fs=require(\"fs\"), b=Buffer.from(data); let at=0; while(at<b.length) at+=fs.writeSync(fd,b,at,b.length-at); }\nfunction io_errs(message) { io_out(2,io_bytes(message+\"\\n\")); }\nfunction io_bytes(text) { return new TextEncoder().encode(text); }\nfunction io_text(bytes,n) { return new TextDecoder(\"utf-8\",{ignoreBOM:true}).decode(bytes.subarray(0,n)); }\nfunction io_tuple_pair(snd,fst) { return tuple(fst,snd); }\nfunction io_tup(...xs) { if(xs.length!==2)return xs.reduceRight(io_tuple_pair); return tuple(xs[0],xs[1]); }\nfunction io_done(value) { return {$:\"Done\",value}; }\nfunction io_sys() { if(globalThis.BEND_SYS===undefined){const ffi=require(\"bun:ffi\"), mac=process.platform===\"darwin\", err=mac?\"__error\":\"__errno_location\", T={i:\"i32\",u:\"u32\",U:\"u64\",I:\"i64\",p:\"ptr\",c:\"cstring\"}, vari=mac&&process.arch===\"arm64\", lib=ffi.dlopen(mac?\"libSystem.dylib\":\"libc.so.6\",Object.fromEntries((\"socket:iii>i bind:ipu>i listen:ii>i connect:ipu>i accept:ipp>i send:ipUi>I recv:ipUi>I read:ipU>I pread:ipUI>I sendto:ipUipu>I recvfrom:ipUipp>I close:i>i poll:pui>i setsockopt:iiipu>i\"+(vari?\" fcntl:iiiiiiiii>i\":\" fcntl:iii>i\")+\" getsockopt:iiipp>i strerror:i>c \"+err+\":>p\").split(\" \").map(s=>{const [name,args,ret]=s.split(/[:>]/);return [name,{args:[...args].map(a=>T[a]),returns:T[ret]}]}))), fcntl=(fd,cmd,arg)=>vari?lib.symbols.fcntl(fd,cmd,0,0,0,0,0,0,arg):lib.symbols.fcntl(fd,cmd,arg); globalThis.BEND_SYS={...lib.symbols,fcntl,ptr:ffi.ptr,mac,errno:()=>ffi.read.i32(lib.symbols[err](),0)};} return globalThis.BEND_SYS; }\nfunction io_fail(code) { return {$:\"Fail\",error:io_tup(code>>>0,String(io_sys().strerror(code)))}; }\nfunction io_push(fun,arg,fresh) { const io=globalThis.BEND_IO; io.runs.push({fun,arg}); io.live+=fresh?1:0; }\nfunction io_park_on(fd,out,k,more) { globalThis.BEND_IO.waits.push({fd,out,k,more}); }\nfunction io_wait(io) { const soon=io.waits.reduce((m,w)=>Math.min(m,w.at??m),Infinity); let ms=-1; if(soon!==Infinity)ms=Math.min(Math.max(0,Math.ceil(soon-performance.now())),2147483647); const fds=io.waits.filter(w=>w.fd!==undefined), buf=Int32Array.from(fds.flatMap(w=>[w.fd,w.out?4:1])); io_sys().poll(fds.length?io_sys().ptr(buf):null,fds.length,ms); const now=performance.now(), fire=io.waits.filter((w)=>(buf[2*fds.indexOf(w)+1]>>>16)!==0||w.at<=now); io.waits=io.waits.filter(w=>!fire.includes(w)); for(const w of fire)io_push(io_wake,w,false); }\nfunction io_wake(w) { const x=w.more(); return x===undefined?undefined:w.k(x); }\nfunction io_run(m) { const io={runs:[],live:0,waits:[]}; globalThis.BEND_IO=io; try{io_push(run_loop(m()),io_emit,true); for(;;){if(io.runs.length===0){if(io.live===0)return 0;if(io.waits.length===0){io_errs(\"bend: deadlock: every computation waits on a channel\");return 1;}io_wait(io);continue;}const s=io.runs.shift();let op=s.fun(s.arg);for(;;){if(op===undefined)break;if(op.$===\"Emit\"){io.live-=1;break;}if(op.$===\"Halt\"){io_errs(op.message);return op.code;}const need=op.need?.()||{},fd=need.read?op.args[0]:null;if(need.time||fd!==null){const more=()=>op.run(...op.args,op.kont);io.waits.push(fd===null?{at:performance.now()+Number(op.args[0]),k:op.kont,more}:{fd,k:op.kont,more});break;}const x=op.run(...op.args,op.kont);if(x===undefined)break;op=op.kont(x);}}}catch(req){if(req instanceof RangeError)throw \"bend: memory fault (machine stack overflow?)\";if(req?.$!==\"$FFI\")throw req;io_errs(\"bend: an FFI operation failed\");return 1;} }\nfunction chan_wake(row,x) { const w=row.wait.shift(); io_push(w.cont,x,false); return w.item; }\nfunction chan_take(row) { const v=row.ring.shift(); if(row.wait.length>0)row.ring.push(chan_wake(row,true)); return v; }\nfunction chan_shut(row) { row.shut=true; while(row.wait.length>0)chan_wake(row,row.wait[0].item===null?{$:\"None\"}:false); }\nfunction io_exit(main,type) { if(type&&type.name===\"IO\")return io_run(main); try{io_out(1,io_bytes($show_value(type,run_loop(main()),0)+\"\\n\"));return 0;}catch(e){io_errs(String(e));return 1;} }\n"
def js_runtime_show() -> String:
  String.append(js_runtime_type(), "function $show_chr(x,q) { const c=[...x][0]||\"\\0\", n=c.codePointAt(0), k=({10:\"n\",9:\"t\",13:\"r\",0:\"0\",92:\"\\\\\"})[n]??(c===q?q:null); return k!==null?\"\\\\\"+k:n<32||n===127?\"\\\\u{\"+n.toString(16)+\"}\":c; }\nfunction $show_list(t,x) { const xs=[]; while(x&&x.$===\"Con\") { const fs=t.arms.Con; if(!fs||!Object.hasOwn(x,\"head\")||!Object.hasOwn(x,\"tail\")) throw \"bend: malformed List.Con\"; xs.push($show_value($type(fs.types[0],t.args),x.head,0)); const next=$type(fs.types[1],t.args.concat([x.head])); x=x.tail; t=next; } if(!x||x.$!==\"Nil\") throw \"bend: malformed List.Nil\"; return \"[\"+xs.join(\", \")+\"]\"; }\nfunction $show_fields(t,x,chain) { const fs=t.arms[x.$]; if(!fs) throw \"bend: constructor absent from result datatype\"; const out=[],env=t.args.slice(); let at=0; for(let j=0;j<fs.types.length;j++) { if(fs.q[j]===0) { env.push(null); continue; } const name=fs.fields[j]; if(!Object.hasOwn(x,name))throw \"bend: constructor field count mismatch\"; const v=x[name]; at++; out.push($show_value($type(fs.types[j],env),v,chain&&at===2?\"(\":0)); env.push(v); } return out.join(\", \"); }\nfunction $show_value(t,x,chain) { if(!t) return String(x); if(t.k===\"U\") return String(x); if(t.k===\"F\") { const s=f32_show(x); return s.replace(/^-?\\d+(?=e|$)/i,\"$&.0\"); } if(t.k===\"N\") return x+\"n\"; if(t.k===\"C\") return \"'\"+$show_chr(x,\"'\")+\"'\"; if(t.k===\"S\") return \"\\\"\"+[...x].map(c=>$show_chr(c,\"\\\"\")).join(\"\")+\"\\\"\"; if(t.k===\"E\") return \"{==}\"; if(t.k===\"A\") return \"[\"+x.map(v=>$show_value(t.e,v,0)).join(\", \")+\"]\"; if(typeof x===\"boolean\") return x?\"True{}\":\"False{}\"; if(!x||typeof x!==\"object\"||!x.$) return String(x); if(t.native===\"List\") return $show_list(t,x); if(t.native===\"Sigma\"&&x.$===\"Tuple\") { const c=chain===\"(\"; return (c?\"\":\"(\")+$show_fields(t,x,true)+(c?\"\":\")\"); } if(t.k!==\"D\") throw \"bend: expected a datatype result\"; return x.$+\"{\"+$show_fields(t,x,false)+\"}\"; }\n")
# Metadata evaluation retains every source formal slot, including erased type
# arguments, but delays terms until reduction needs them. It never calls an
# ordinary erased-value function or executes an unused proof/index expression.
def js_runtime_type() -> String:
  String.append(js_runtime_native_type(), String.append(js_runtime_type_names(), String.append(js_runtime_type_patterns(), js_runtime_type_eval())))
def js_runtime_type_names() -> String:
  "function $type_key(k,s,i) { const q=$key(k,s,i||{}); return $TYPE[q]!==undefined||$TYPEF[q]!==undefined?q:k; }\nfunction $type_ctor_key(k,s,i) { const q=$key(k,s,i||{}); return $FIELDS[q]!==undefined?q:k; }\nfunction $type_delay(t,a) { if(t.k)return t; if(t.p!==undefined&&a[a.length-1-t.p]!==undefined)return a[a.length-1-t.p]; return {k:\"Thunk\",term:t,env:a,depth:a.length,done:false}; }\nfunction $type_force(v) { if(v&&v.k===\"Thunk\") { if(!v.done) { v.value=$type(v.term,v.env.length===v.depth?v.env:v.env.slice(0,v.depth)); v.done=true; } return v.value; } return v; }\nfunction $type_apply(f,x) { f=$type_force(f); if(f.k===\"L\") return $type(f.body,f.env.concat([x])); if(f.k===\"TF\"||f.k===\"DF\") return $type_named(f.key,f.args.concat([x])); throw \"bend: type expression applied a non-function\"; }\nfunction $type_named(q,ps) { const f=$TYPEF[q]; if(f) { if(ps.length<f.n)return {k:\"TF\",key:q,args:ps}; let v=f.intrinsic?$type_native_invoke(f,ps):$type(f.body,ps.length===f.n?ps:ps.slice(0,f.n)); for(let i=f.n;i<ps.length;i++)v=$type_apply(v,ps[i]); if(f.native===\"IO\")v.name=\"IO\"; return v; } const d=$TYPE[q]; if(!d) throw \"bend: unresolved type expression \"+q; const p=$PARAMS[q]; if(ps.length<p.n)return {k:\"DF\",key:q,args:ps}; if(ps.length!==p.n)throw \"bend: datatype parameter count mismatch\"; if(d.native===\"Array\") return {k:\"A\",e:$type_force(ps[0])}; const k=({U32:\"U\",F32:\"F\",Nat:\"N\",Char:\"C\",String:\"S\",Eql:\"E\"})[d.native]; return k?{k}:{k:\"D\",key:q,name:d.name,native:d.native,arms:d.arms,args:ps}; }\n"
def js_runtime_type_patterns() -> String:
  "function $type_sugar(t,a) { const h=$type(t.sugar,a),more=t.a.map(x=>$type_delay(x,a)); if(h.k===\"TF\"||h.k===\"DF\"||h.k===\"D\") { const q=h.key,p=$PARAMS[q]; let xs=h.args.concat(more); if(p&&xs.length+p.q===p.n)xs=Array.from({length:p.q},()=>({k:\"Q\",v:t.f})).concat(xs); if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x); return $type_named(q,xs); } let v=h; for(const x of more)v=$type_apply(v,x); return v; }\nfunction $type_pattern(p,v,bindings) { if(p.v) { bindings.push(v); return true; } v=$type_force(v); const q=$type_ctor_key(p.c,p.s,p.i),c=$PRIMITIVES[q]||($FIELDS[q]===undefined?q:\"\"); let fields,complete=false; if(v&&v.k===\"V\") { if(v.c!==q)return false; fields=v.args; complete=true; } else if(v&&v.$===q) { const names=$FIELDS[q]; if(!names||names.length!==p.fields.length)return false; for(let j=0;j<names.length;j++){if(names[j]===null){bindings.push(null);continue;}if(!$type_pattern(p.fields[j],v[names[j]],bindings))return false;}return true; } else if(c===\"Bool.True\"&&v===true||c===\"Bool.False\"&&v===false||c===\"Nat.Zero\"&&v===0||c===\"String.SNil\"&&v===\"\") fields=[]; else if(c===\"Nat.Succ\"&&typeof v===\"number\"&&v>0)fields=[v-1]; else if(c===\"String.SCon\"&&typeof v===\"string\"&&v.length)fields=[String.fromCodePoint(v.codePointAt(0)),v.slice(v.codePointAt(0)>0xFFFF?2:1)]; else if(c===\"Char.Chr\"&&typeof v===\"string\")fields=[v.codePointAt(0)]; else if(c===\"U32.U32\"&&typeof v===\"number\")fields=[u32_to_word(v)]; else if(c===\"F32.F32\"&&typeof v===\"number\")fields=[u32_to_word(f32_bits(v))]; else if(c===\"Array.ALeaf\"&&Array.isArray(v)&&v.length===1)fields=[v[0]]; else if(c===\"Array.ANode\"&&Array.isArray(v)&&v.length!==1)fields=[v.slice(0,v.length>>1),v.slice(v.length>>1)]; else return false; let at=0; for(const field of p.fields) { if(!complete&&field.v&&field.q===0) { bindings.push(null); continue; } if(at>=fields.length||!$type_pattern(field,fields[at++],bindings))return false; } return at===fields.length; }\nfunction $type_bind(patterns,values) { if(patterns.length!==values.length)return null; const bindings=[]; for(let j=0;j<values.length;j++)if(!$type_pattern(patterns[j],values[j],bindings))return null; return bindings; }\n"
def js_runtime_type_eval() -> String:
  "function $type(t,a=[]) { if(t===null)return null; if(t===undefined)throw \"bend: missing type expression\"; if(t.p!==undefined) { const v=$type_force(a[a.length-1-t.p]); if(v===undefined||v===null)throw \"bend: unavailable type-expression binder\"; return v; } if(t.k)return $type_force(t); if(t.fail)throw t.fail; if(t.kind!==undefined)return {k:\"K\",q:$type(t.kind,a)}; if(t.min!==undefined)return {k:\"Q\",v:Math.min($type(t.min,a).v,$type(t.right,a).v)}; if(t.all!==undefined)return {k:\"Fn\",q:t.q,domain:$type(t.all,a),body:t.body,env:a}; if(t.lam!==undefined)return {k:\"L\",body:t.lam,env:a}; if(t.app!==undefined)return $type_apply($type(t.app,a),$type_delay(t.arg,a)); if(t.sub!==undefined) { const env=a.slice(); env.splice(env.length-t.sub,0,$type_delay(t.value,a)); return $type(t.body,env); } if(t.let!==undefined)return $type(t.body,a.concat(t.let.map(x=>$type_delay(x,a)))); if(t.local!==undefined) { const bs=$type_bind(t.pat,t.local.map(x=>$type_delay(x,a))); if(bs===null)throw \"bend: type expression local pattern failed\"; return $type(t.body,a.concat(bs)); } if(t.bind!==undefined)return $type(t.body,a.concat([$type_delay(t.bind,a)])); if(t.match!==undefined) { const vs=t.match.map(x=>$type_delay(x,a)); for(const c of t.cases) { const bs=$type_bind(c.pat,vs); if(bs!==null)return $type(c.body,a.concat(bs)); } throw \"bend: type expression match failed\"; } if(t.c!==undefined)return {k:\"V\",c:$type_ctor_key(t.c,t.s,t.i),args:t.a.map(x=>$type_delay(x,a))}; if(t.sugar!==undefined)return $type_sugar(t,a); if(t.f) { const q=$type_key(t.r,t.s,t.i),p=$PARAMS[q]; if(!p&&t.f===2)return $type(t.h,a); let xs=t.a||[]; if(p&&xs.length+p.q===p.n)xs=Array.from({length:p.q},()=>({k:\"Q\",v:1})).concat(xs); if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x); return $type_named(q,xs.map(x=>$type_delay(x,a))); } if(t.r!==undefined)return $type_named($type_key(t.r,t.s,t.i),(t.a||[]).map(x=>$type_delay(x,a))); throw \"bend: unsupported type-expression descriptor\"; }\n"
def js_runtime_native_type() -> String:
  "function $type_native_invoke(f,ps) { let value=f.intrinsic; for(let i=0;i<f.n;i++)if(f.q[i]!==0)value=value($type_runtime_value(ps[i])); return value; }\nfunction $type_runtime_value(value) { const v=$type_force(value); if(!v||v.k!==\"V\")return v; const c=$PRIMITIVES[v.c]||($FIELDS[v.c]===undefined?v.c:\"\"),xs=v.args; switch(c) { case \"Nat.Zero\":return 0; case \"Nat.Succ\":return nat_chk($type_runtime_value(xs[0])+1); case \"Bool.False\":return false; case \"Bool.True\":return true; case \"String.SNil\":return \"\"; case \"String.SCon\":return $type_runtime_value(xs[0])+$type_runtime_value(xs[1]); case \"Char.Chr\":return char_new($type_runtime_value(xs[0])); case \"U32.U32\":return word_to_u32($type_runtime_value(xs[0])); case \"F32.F32\":return f32_from_bits(word_to_u32($type_runtime_value(xs[0]))); case \"Array.ALeaf\":return [$type_runtime_value(xs[0])]; case \"Array.ANode\":return $type_runtime_value(xs[0]).concat($type_runtime_value(xs[1])); } const fs=$FIELDS[v.c]; if(!fs||fs.length!==xs.length)throw \"bend: unresolved metadata constructor\"; const args=xs.map((x,i)=>fs[i]===null?null:$type_runtime_value(x)); return $ctr(v.c,args,\"\",{}); }\n"
def js_main(type_expression: String) -> String:
  String.append("if (typeof process !== \"undefined\" && process.argv[1] && /\\.js$/.test(process.argv[1])) { cli(process.argv.slice(2)); if(Object.hasOwn($D,\"main\")) { process.exitCode=io_exit(()=>$D[\"main\"],$type(", String.append(type_expression, ")); } }\n"))

def emit(modules: List<&2, Loader.LoadedModule>) -> EmitResult:
  js_emit_template(template_modules(modules), modules, None{})

def js_emit_template(found: Maybe<&2, AST.SourceSpan>, modules: List<&2, Loader.LoadedModule>, exports: Maybe<&2, List<&2, String>>) -> EmitResult:
  match found:
    case Some{span}: EmitFailure{ "unexpanded compile-time template", span}
    case None{}: js_emit_holes(error_modules(modules), modules, exports)

def js_emit_holes(found: Maybe<&2, AST.SourceSpan>, modules: List<&2, Loader.LoadedModule>, exports: Maybe<&2, List<&2, String>>) -> EmitResult:
  match found:
    case Some{span}: EmitFailure{ "cannot compile a hole", span}
    case None{}: js_emit_foreign(foreign_error_modules(modules), modules, exports)

def js_emit_foreign(found: Maybe<&2, AST.SourceSpan>, modules: List<&2, Loader.LoadedModule>, exports: Maybe<&2, List<&2, String>>) -> EmitResult:
  match found:
    case Some{span}: EmitFailure{ "a foreign def without a .js import", span}
    case None{}:
      catalog = js_value_indices(modules)
      source = String.append(js_runtime(), String.append(js_runtime_extra(), String.append(js_runtime_show(), String.append(js_runtime_cli(), String.append(js_runtime_io(), String.append(js_runtime_array(), String.append(js_runtime_foreign(), String.append(js_runtime_namespace(), String.append(js_constructor_fields_modules(modules), String.append(js_type_modules(modules, catalog), String.append(js_modules(modules, catalog), js_emit_ending(exports, modules, catalog))))))))))))
      EmitSuccess{source}

def js_library_exports(exports: List<&2, String>) -> String:
  String.append("export default {", String.append(js_library_export_fields(exports), "};\n"))

def js_library_export_fields(exports: List<&2, String>) -> String:
  match exports:
    case Nil{}: ""
    case +key <> rest:
      quoted = js_quote(key)
      String.append(quoted, String.append(":(...args)=>$run($D[", String.append(quoted, String.append("],args),", js_library_export_fields(rest)))))

def emit_library(modules: List<&2, Loader.LoadedModule>, exports: List<&2, String>) -> EmitResult:
  js_emit_template(template_modules(modules), modules, Some{exports})

def js_emit_ending(exports: Maybe<&2, List<&2, String>>, modules: List<&2, Loader.LoadedModule>, catalog: EmitCatalog) -> String:
  match exports:
    case None{}: js_main(main_type_expr_modules(modules, catalog))
    case Some{keys}: js_library_exports(keys)
