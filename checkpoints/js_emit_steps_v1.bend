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

# Bounded typed request groups; every source declaration retains its checked signature.
type EmitterRequestGroup0 is Type:
  EmitterRequest_js_value_indices{v_1: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_catalog{+v_2: List<&2, EmitModuleIndex>}
  EmitterRequest_js_catalog_at{v_2: List<&2, EmitModuleIndex>, v_4: EmitCatalog}
  EmitterRequest_js_catalog_module{+v_1: EmitModuleIndex, v_3: EmitCatalog}
  EmitterRequest_js_catalog_values{v_1: Map<&2, AST.Definition>, v_3: EmitModuleIndex, v_6: Map<&2, EmitModuleIndex>}
  EmitterRequest_js_catalog_constructors{v_2: Map<&2, EmitConstructorOwner>, v_4: EmitModuleIndex, v_7: Map<&2, EmitModuleIndex>}
  EmitterRequest_js_catalog_types{v_2: Map<&2, List<&2, AST.TopLevel>>, v_4: EmitModuleIndex, v_8: Map<&2, List<&2, EmitModuleIndex>>}
  EmitterRequest_js_catalog_type_insert{v_3: Maybe<&2, List<&2, EmitModuleIndex>>, v_5: String, v_7: EmitModuleIndex, v_11: Map<&2, List<&2, EmitModuleIndex>>}
  EmitterRequest_js_catalog_layouts{v_1: EmitCatalog}
  EmitterRequest_js_namespace_indices{v_1: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_value_indices_at{v_1: List<&2, Loader.LoadedModule>, v_4: Map<&2, String>, v_6: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_value_declarations{v_1: String, v_3: List<&2, AST.TopLevel>}
  EmitterRequest_js_value_declaration{+v_0: AST.Definition, v_2: String, v_4: Map<&2, AST.Definition>}
  EmitterRequest_js_constructor_indices{v_1: String, v_3: List<&2, AST.TopLevel>}
  EmitterRequest_js_constructor_index_family{+v_0: AST.TypeDecl, v_2: String, v_5: Map<&2, EmitConstructorOwner>}
  EmitterRequest_js_constructor_index_items{v_1: List<&2, AST.ConstructorDecl>, +v_2: AST.TypeDecl, v_4: String, v_7: Map<&2, EmitConstructorOwner>}
  EmitterRequest_js_type_indices{v_1: String, v_3: List<&2, AST.TopLevel>}
  EmitterRequest_js_type_index_declaration{+v_0: AST.TopLevel, v_2: String, v_5: Map<&2, List<&2, AST.TopLevel>>}
  EmitterRequest_js_type_index_insert{v_1: String, v_2: AST.TopLevel, +v_5: Map<&2, List<&2, AST.TopLevel>>}
  EmitterRequest_js_type_index_found{v_2: Maybe<&2, List<&2, AST.TopLevel>>, v_4: String, v_5: AST.TopLevel, v_8: Map<&2, List<&2, AST.TopLevel>>}
  EmitterRequest_js_escape_char{v_1: Char}
  EmitterRequest_js_comma_prefix{v_1: Bool}
  EmitterRequest_js_quote_chars{v_2: List<&2, Char>, v_4: String}
  EmitterRequest_js_quote{v_1: String}
  EmitterRequest_js_named_identifier_char{v_1: Bool, v_3: Char, v_5: U32}
  EmitterRequest_js_named_identifier_chars{v_1: String, v_3: String}
  EmitterRequest_js_named_identifier{v_1: String}
  EmitterRequest_env_binding{v_1: EmitEnv, v_3: Nat}
  EmitterRequest_env_binding_at{v_2: List<&2, String>, v_6: List<&2, Maybe<&2, EmitClosure>>, v_10: List<&2, Maybe<&2, EmitClosure>>, v_12: Nat}
  EmitterRequest_env_at_binding{v_2: Maybe<&2, EmitBinding>}
  EmitterRequest_env_at{v_1: EmitEnv, v_3: Nat}
  EmitterRequest_env_bind{v_1: String, v_4: Maybe<&2, EmitClosure>, v_7: Maybe<&2, EmitClosure>, v_9: EmitEnv}
  EmitterRequest_env_push{v_1: String, v_3: EmitEnv}
  EmitterRequest_js_close{v_0: AST.SyntaxTerm, v_2: EmitEnv}
  EmitterRequest_js_close_inferred{v_1: List<&2, AST.TelescopeItem>, v_2: AST.SyntaxTerm, v_4: EmitEnv}
  EmitterRequest_js_close_declared{v_1: List<&2, AST.TelescopeItem>, v_2: AST.OptionalTerm, v_4: EmitEnv}
  EmitterRequest_js_close_definition{v_1: String, v_3: List<&2, AST.TelescopeItem>, v_4: AST.SyntaxTerm, v_6: EmitEnv}
  EmitterRequest_js_closure_env{v_1: EmitClosure}
  EmitterRequest_js_scope_key{v_1: String, v_3: EmitScope}
  EmitterRequest_js_scope_alias{v_1: String, v_4: List<&2, EmitAlias>, v_6: String, v_8: Nat}
  EmitterRequest_js_scope_alias_match{v_1: Bool, v_3: String, v_5: Nat, v_7: String, v_10: List<&2, EmitAlias>, v_12: String, v_14: Nat}
  EmitterRequest_js_global{v_1: String, v_3: EmitEnv}
  EmitterRequest_js_global_fallback{v_2: Maybe<&2, EmitClosure>, v_4: String, v_6: EmitCatalog}
  EmitterRequest_js_global_lookup{v_1: String, +v_3: EmitCatalog}
  EmitterRequest_js_global_owner{v_2: Maybe<&2, EmitModuleIndex>, v_4: String, v_6: EmitCatalog}
  EmitterRequest_js_owner_env{v_1: EmitModuleIndex, v_3: EmitCatalog}
  EmitterRequest_js_global_definition{v_1: Maybe<&2, AST.Definition>, v_3: String, v_5: EmitEnv}
  EmitterRequest_js_global_type{v_1: String, v_3: EmitEnv}
  EmitterRequest_js_global_type_fallback{v_2: Maybe<&2, EmitClosure>, v_4: String, v_6: EmitCatalog}
  EmitterRequest_js_global_type_lookup{v_1: String, +v_3: EmitCatalog}
  EmitterRequest_js_global_type_owners{v_3: Maybe<&2, List<&2, EmitModuleIndex>>, v_5: String, v_7: EmitCatalog}
  EmitterRequest_js_global_type_modules{v_1: String, v_4: List<&2, EmitModuleIndex>, v_6: EmitCatalog}
  EmitterRequest_js_global_type_next{v_2: Maybe<&2, EmitClosure>, v_4: String, v_7: List<&2, EmitModuleIndex>, v_9: EmitCatalog}
  EmitterRequest_js_global_type_index{v_2: Maybe<&2, List<&2, AST.TopLevel>>, v_4: EmitEnv}
  EmitterRequest_js_global_type_decls{v_1: List<&2, AST.TopLevel>, v_3: EmitEnv}
  EmitterRequest_js_global_type_definition{v_1: List<&2, AST.TelescopeItem>, v_2: AST.OptionalTerm, v_3: AST.DefBody, v_5: EmitEnv}
  EmitterRequest_js_global_native_law_operation{v_2: Maybe<&2, String>, v_4: List<&2, AST.Clause>, v_5: AST.SyntaxTerm, v_7: List<&2, AST.TopLevel>, v_9: EmitEnv}
  EmitterRequest_js_native_law_type{v_2: Maybe<&2, List<&2, AST.TelescopeItem>>, v_3: AST.SyntaxTerm, v_5: EmitEnv}
  EmitterRequest_js_native_law_binders{v_1: List<&2, AST.Clause>, v_3: Nat}
  EmitterRequest_js_native_law_binder{v_0: AST.TelescopeItem, v_3: Maybe<&2, List<&2, AST.TelescopeItem>>}
  EmitterRequest_js_type_definition{v_1: List<&2, AST.TelescopeItem>, v_2: AST.SyntaxTerm, v_4: EmitEnv}
  EmitterRequest_js_reduce_env{v_1: EmitClosure, v_3: EmitEnv}
  EmitterRequest_js_reduce{v_1: EmitClosure}
  EmitterRequest_js_reduce_inferred{v_2: Maybe<&2, EmitClosure>, v_4: EmitClosure}

type EmitterRequestGroup1 is Type:
  EmitterRequest_js_reduce_binding{v_2: Maybe<&2, EmitBinding>, v_4: EmitClosure}
  EmitterRequest_js_reduce_global{v_2: Maybe<&2, EmitClosure>, v_4: EmitClosure}
  EmitterRequest_js_reduce_app_env{v_1: EmitClosure, v_3: EmitClosure, v_5: EmitClosure, v_7: EmitEnv}
  EmitterRequest_js_reduce_app{v_1: EmitClosure, v_3: EmitClosure, v_5: EmitClosure}
  EmitterRequest_js_reduce_patterns{v_1: List<&2, AST.SyntaxPattern>, v_4: List<&2, EmitClosure>, v_6: EmitEnv}
  EmitterRequest_js_reduce_patterns_next{v_1: EmitPatternResult, v_3: List<&2, AST.SyntaxPattern>, v_6: List<&2, EmitClosure>}
  EmitterRequest_js_reduce_pattern{v_0: AST.SyntaxPattern, v_2: EmitClosure, v_4: EmitEnv}
  EmitterRequest_js_reduce_pattern_view_env{v_1: String, v_3: List<&2, AST.SyntaxPattern>, v_5: EmitClosure, v_7: EmitEnv, v_9: EmitEnv}
  EmitterRequest_js_reduce_pattern_view{v_1: String, v_3: List<&2, AST.SyntaxPattern>, v_5: EmitClosure, v_7: EmitEnv}
  EmitterRequest_js_same_scoped_key{v_1: String, v_3: EmitEnv, v_5: String, v_7: EmitEnv}
  EmitterRequest_js_same_constructor_key{v_2: Maybe<&2, EmitConstructor>, v_5: Maybe<&2, EmitConstructor>}
  EmitterRequest_js_reduce_pattern_key{v_1: Bool, v_3: List<&2, AST.SyntaxPattern>, v_6: List<&2, EmitClosure>, v_8: EmitEnv}
  EmitterRequest_js_reduce_local{v_1: EmitPatternResult, v_2: AST.SyntaxTerm, v_4: EmitClosure}
  EmitterRequest_js_reduce_cases{v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, EmitClosure>, v_6: EmitEnv, v_8: EmitClosure}
  EmitterRequest_js_reduce_case_result{v_1: EmitPatternResult, v_2: AST.SyntaxTerm, v_4: List<&2, AST.SyntaxTerm>, v_7: List<&2, EmitClosure>, v_9: EmitEnv, v_11: EmitClosure}
  EmitterRequest_js_value_env{v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv}
  EmitterRequest_js_value_env_at{v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv, v_5: EmitEnv}
  EmitterRequest_js_type{v_0: AST.SyntaxTerm, v_2: EmitEnv}
  EmitterRequest_js_binding_type{v_2: Maybe<&2, EmitBinding>}
  EmitterRequest_js_type_value{v_1: EmitClosure}
  EmitterRequest_js_type_local{v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, v_6: EmitEnv}
  EmitterRequest_js_type_local_refined{v_1: EmitPatternResult, v_5: List<&2, Maybe<&2, EmitClosure>>, v_6: AST.SyntaxTerm, v_8: EmitEnv, v_10: EmitEnv}
  EmitterRequest_js_apply_type_args{v_2: Maybe<&2, EmitClosure>, v_5: List<&2, EmitClosure>}
  EmitterRequest_js_apply_type{v_2: Maybe<&2, EmitClosure>, v_4: EmitClosure}
  EmitterRequest_js_apply_type_view_env{v_1: EmitClosure, v_3: EmitClosure, v_5: EmitEnv}
  EmitterRequest_js_apply_type_view{v_1: EmitClosure, v_3: EmitClosure}
  EmitterRequest_js_type_cases{v_1: List<&2, AST.SyntaxTerm>, v_3: List<&2, AST.SyntaxTerm>, v_5: EmitEnv}
  EmitterRequest_env_insert_binding{v_1: EmitEnv, v_3: Nat, v_5: EmitBinding}
  EmitterRequest_env_insert_names{v_2: List<&2, String>, v_4: Nat, v_6: String}
  EmitterRequest_env_insert_closures{v_3: List<&2, Maybe<&2, EmitClosure>>, v_5: Nat, v_8: Maybe<&2, EmitClosure>}
  EmitterRequest_env_names_typed{v_2: List<&2, String>, v_6: List<&2, Maybe<&2, EmitClosure>>, v_8: EmitEnv}
  EmitterRequest_js_scrutinee_types{v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv}
  EmitterRequest_js_pattern_types{v_1: List<&2, AST.SyntaxPattern>, v_5: List<&2, Maybe<&2, EmitClosure>>, v_7: EmitEnv}
  EmitterRequest_js_pattern_type{v_0: AST.SyntaxPattern, v_3: Maybe<&2, EmitClosure>, v_5: EmitEnv}
  EmitterRequest_js_field_types{v_2: Maybe<&2, EmitClosure>}
  EmitterRequest_js_field_types_view_env{v_1: EmitClosure, v_3: EmitEnv}
  EmitterRequest_js_field_types_view{v_1: EmitClosure}
  EmitterRequest_js_constructor_decl{v_1: String, v_3: EmitEnv}
  EmitterRequest_js_constructor_decl_fallback{v_2: Maybe<&2, EmitConstructor>, v_4: String, v_6: EmitCatalog}
  EmitterRequest_js_constructor_lookup{v_1: String, +v_3: EmitCatalog}
  EmitterRequest_js_constructor_index_owner{v_2: Maybe<&2, EmitModuleIndex>, v_4: String, v_6: EmitCatalog}
  EmitterRequest_js_constructor_owner{v_2: Maybe<&2, EmitConstructorOwner>, v_4: String, v_6: EmitEnv}
  EmitterRequest_js_constructor_signature{v_1: String, v_4: Maybe<&2, EmitClosure>, v_6: EmitEnv}
  EmitterRequest_js_constructor_signature_found{v_2: Maybe<&2, EmitConstructor>, v_5: Maybe<&2, EmitClosure>}
  EmitterRequest_js_family_parameter_arguments{v_1: List<&2, AST.TelescopeItem>, v_4: Maybe<&2, EmitClosure>}
  EmitterRequest_js_family_parameter_view_env{v_1: List<&2, AST.TelescopeItem>, v_3: EmitClosure, v_5: EmitEnv}
  EmitterRequest_js_family_parameter_view{v_1: List<&2, AST.TelescopeItem>, v_3: EmitClosure}
  EmitterRequest_js_family_arguments_view_env{v_1: EmitClosure, v_3: EmitEnv}
  EmitterRequest_js_family_arguments_view{v_1: EmitClosure}
  EmitterRequest_js_family_fill_arguments{v_1: List<&2, AST.TelescopeItem>, v_4: List<&2, EmitClosure>, v_5: AST.Quantity, v_6: AST.SourceSpan, v_8: EmitEnv}
  EmitterRequest_js_family_quant_prefix{v_1: List<&2, AST.TelescopeItem>, v_3: EmitEnv}
  EmitterRequest_js_family_quant_domain{v_1: EmitClosure, v_3: List<&2, AST.TelescopeItem>, v_5: EmitEnv}
  EmitterRequest_js_family_fill_missing{v_1: Bool, v_4: List<&2, EmitClosure>, v_6: Nat, v_7: AST.Quantity, v_8: AST.SourceSpan, v_10: EmitEnv}
  EmitterRequest_js_quantity_closures{v_1: Nat, v_2: AST.Quantity, v_3: AST.SourceSpan, v_5: EmitEnv}
  EmitterRequest_js_family_promote_arguments{v_2: List<&2, EmitClosure>, v_4: Nat, v_5: AST.SourceSpan, v_7: EmitEnv}
  EmitterRequest_js_closure_terms{v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv}
  EmitterRequest_js_constructor_parameter_types{v_1: List<&2, AST.TelescopeItem>, v_3: List<&2, AST.TelescopeItem>, v_5: EmitEnv, v_8: List<&2, EmitClosure>}
  EmitterRequest_js_choose{v_1: String, v_3: String, v_5: String, v_7: String}
  EmitterRequest_js_key_matches{v_1: String, v_3: String}
  EmitterRequest_js_choose_exact{v_1: String, v_3: String, v_5: String, v_7: String}
  EmitterRequest_js_choose_result{v_1: Bool, v_3: String, v_5: String}
  EmitterRequest_js_reference{v_1: String}
  EmitterRequest_js_native_operations{v_1: Bool, v_3: String, v_5: List<&2, AST.TopLevel>}
  EmitterRequest_js_native_operation_declarations{v_1: String, v_3: List<&2, AST.TopLevel>}

type EmitterRequestGroup2 is Type:
  EmitterRequest_js_native_operation_insert_keys{v_1: String, v_3: String, v_6: Map<&2, String>}
  EmitterRequest_js_native_operation_insert{v_1: String, v_4: Map<&2, String>}
  EmitterRequest_js_native_operation_insert_found{v_2: Maybe<&2, String>, v_4: String, v_7: Map<&2, String>}
  EmitterRequest_js_native_operation_origin{v_1: Bool, v_3: String}
  EmitterRequest_js_native_operation{v_1: String, v_3: EmitEnv}
  EmitterRequest_js_native_operation_known{v_1: Bool, v_3: String}
  EmitterRequest_js_native_operation_name{v_1: String}
  EmitterRequest_js_native_operation_chars{v_2: List<&2, Char>, v_5: List<&2, Char>}
  EmitterRequest_suffix_any{v_1: String, v_3: String, v_5: String}
  EmitterRequest_js_native_u32{v_1: String}
  EmitterRequest_js_native_u32_1{v_1: String}
  EmitterRequest_js_native_u32_2{v_1: String}
  EmitterRequest_js_native_f32{v_1: String}
  EmitterRequest_js_native_f32_1{v_1: String}
  EmitterRequest_js_native_f32_2{v_1: String}
  EmitterRequest_js_native_f32_extra{v_1: String}
  EmitterRequest_js_native_misc{v_1: String}
  EmitterRequest_js_native_misc_1{v_1: String}
  EmitterRequest_js_native_misc_2{v_1: String}
  EmitterRequest_js_is_native{v_1: String}
  EmitterRequest_js_native_primitive{v_1: String}
  EmitterRequest_js_native_primitive_shape{v_1: String}
  EmitterRequest_js_native_primitive_shape_match{v_1: Bool, v_3: String}
  EmitterRequest_js_native_primitive_binary{v_1: String}
  EmitterRequest_js_native_primitive_binary_match{v_1: Bool, v_3: String}
  EmitterRequest_js_native_primitive_indexed{v_1: String}
  EmitterRequest_js_native_primitive_indexed_match{v_1: Bool, v_3: String}
  EmitterRequest_js_native_primitive_position{v_1: String}
  EmitterRequest_js_native_primitive_position_match{v_1: Bool, v_3: String}
  EmitterRequest_js_native_primitive_unary{v_1: String}
  EmitterRequest_js_native_primitive_unary_match{v_1: Bool, v_3: String}
  EmitterRequest_js_native_primitive_text{v_1: String}
  EmitterRequest_js_native_primitive_text_match{v_1: Bool, v_3: String}
  EmitterRequest_js_native_primitive_binders{v_1: List<&2, AST.TelescopeItem>}
  EmitterRequest_js_native_primitive_count{v_2: Maybe<&2, Nat>, v_3: AST.Quantity}
  EmitterRequest_js_native_primitive_checked{v_2: Maybe<&2, String>, v_4: List<&2, AST.TelescopeItem>}
  EmitterRequest_js_native_primitive_arity{v_2: Maybe<&2, EmitPrimitive>, v_5: Maybe<&2, Nat>}
  EmitterRequest_js_native_primitive_arity_match{v_1: Bool, v_4: List<&2, String>, v_6: String}
  EmitterRequest_js_reference_old{v_1: String}
  EmitterRequest_js_reference_2{v_1: String}
  EmitterRequest_js_reference_3{v_1: String}
  EmitterRequest_js_reference_4{v_1: String}
  EmitterRequest_js_reference_5{v_1: String}
  EmitterRequest_js_reference_6{v_1: String}
  EmitterRequest_js_reference_7{v_1: String}
  EmitterRequest_js_reference_8{v_1: String}
  EmitterRequest_js_reference_nat_bounds{v_1: String}
  EmitterRequest_js_reference_9{v_1: String}
  EmitterRequest_js_reference_10{v_1: String}
  EmitterRequest_js_reference_11{v_1: String}
  EmitterRequest_js_reference_12{v_1: String}
  EmitterRequest_js_reference_more{v_1: String}
  EmitterRequest_js_ref_f32_extra{v_1: String}
  EmitterRequest_js_ref_u32{v_1: String}
  EmitterRequest_js_ref_u32_2{v_1: String}
  EmitterRequest_js_ref_u32_3{v_1: String}
  EmitterRequest_js_ref_f32{v_1: String}
  EmitterRequest_js_ref_f32_2{v_1: String}
  EmitterRequest_js_ref_f32_3{v_1: String}
  EmitterRequest_js_ref_nat{v_1: String}
  EmitterRequest_js_ref_strings{v_1: String}
  EmitterRequest_js_ref_array{v_1: String}
  EmitterRequest_js_term{v_0: AST.SyntaxTerm, v_2: EmitEnv}
  EmitterRequest_js_term_expected{v_0: AST.SyntaxTerm, v_2: EmitEnv, v_5: Maybe<&2, EmitClosure>}

type EmitterRequestGroup3 is Type:
  EmitterRequest_js_term_tail_expected{v_0: AST.SyntaxTerm, v_2: EmitEnv, v_5: Maybe<&2, EmitClosure>}
  EmitterRequest_js_statement_tail{v_0: AST.SyntaxTerm, v_2: EmitEnv, v_5: Maybe<&2, EmitClosure>}
  EmitterRequest_js_statement_local{v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, v_6: EmitEnv, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>}
  EmitterRequest_js_statement_match{v_1: List<&2, AST.SyntaxTerm>, v_3: List<&2, AST.SyntaxTerm>, v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>}
  EmitterRequest_js_statement_result{v_0: AST.SyntaxTerm, v_2: EmitEnv, v_3: AST.OptionalTerm}
  EmitterRequest_js_app_spine{v_0: AST.SyntaxTerm, v_2: EmitEnv, v_4: Bool}
  EmitterRequest_js_app_spine_result{v_1: Pair(AST.SyntaxTerm, List<&2, AST.SyntaxTerm>), v_3: EmitEnv, v_5: Bool}
  EmitterRequest_js_app_dispatch{v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>, v_4: EmitEnv, v_6: Bool}
  EmitterRequest_js_named_owner{v_1: String, v_3: EmitEnv}
  EmitterRequest_js_named_fallback{v_2: Maybe<&2, EmitNamed>, v_4: String, v_6: EmitCatalog}
  EmitterRequest_js_named_lookup{v_1: String, +v_3: EmitCatalog}
  EmitterRequest_js_named_layouts{v_3: Maybe<&2, List<&2, EmitModuleIndex>>, v_5: String, v_7: EmitCatalog}
  EmitterRequest_js_named_next{v_2: Maybe<&2, EmitNamed>, v_5: List<&2, EmitModuleIndex>, v_7: String, v_9: EmitCatalog}
  EmitterRequest_js_named_declarations{v_2: Maybe<&2, List<&2, AST.TopLevel>>, v_4: String, v_6: EmitEnv}
  EmitterRequest_js_named_native_law{v_2: Maybe<&2, String>, v_5: Maybe<&2, List<&2, AST.TelescopeItem>>, v_7: List<&2, AST.TopLevel>, v_9: String, v_11: EmitEnv}
  EmitterRequest_js_named_app{v_1: String, v_3: List<&2, AST.SyntaxTerm>, v_5: EmitEnv, v_7: Bool}
  EmitterRequest_js_named_app_found{v_2: Maybe<&2, EmitNamed>, v_4: String, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_10: Bool}
  EmitterRequest_js_named_native_law_app{v_2: Maybe<&2, EmitPrimitive>, v_4: String, v_6: List<&2, AST.TelescopeItem>, v_8: List<&2, AST.SyntaxTerm>, v_10: EmitEnv, v_12: String, v_14: EmitEnv}
  EmitterRequest_js_named_app_native{v_2: Maybe<&2, EmitPrimitive>, v_4: String, v_6: List<&2, AST.TelescopeItem>, v_7: AST.OptionalTerm, v_8: AST.SyntaxTerm, v_10: List<&2, AST.SyntaxTerm>, v_12: EmitEnv, v_14: String, v_16: EmitEnv, v_18: Bool}
  EmitterRequest_js_native_app_args{v_3: Maybe<&2, List<&2, String>>, v_5: String, v_7: String, v_9: List<&2, AST.SyntaxTerm>, v_11: EmitEnv}
  EmitterRequest_js_named_app_eligible{v_1: Bool, v_3: String, v_5: List<&2, AST.TelescopeItem>, v_7: List<&2, AST.SyntaxTerm>, v_9: EmitEnv, v_11: String, v_13: EmitEnv, v_15: Bool}
  EmitterRequest_js_named_tail_selected{v_1: String, +v_4: List<&2, String>, v_6: Nat, v_8: Bool}
  EmitterRequest_js_named_tail{v_1: String, +v_4: List<&2, String>}
  EmitterRequest_js_named_app_args{v_3: Maybe<&2, List<&2, String>>, v_5: String, v_7: String, v_9: List<&2, AST.SyntaxTerm>, v_11: EmitEnv, v_13: Bool}
  EmitterRequest_js_named_args{v_1: List<&2, AST.TelescopeItem>, v_3: List<&2, AST.SyntaxTerm>, v_5: EmitEnv, v_7: EmitEnv}
  EmitterRequest_js_named_arg{v_3: Maybe<&2, List<&2, String>>, v_4: AST.Quantity, v_5: AST.SyntaxTerm, v_6: AST.SyntaxTerm, v_8: EmitEnv, v_10: EmitEnv}
  EmitterRequest_js_app_spine_at{v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>}
  EmitterRequest_js_app_chain_args{v_1: List<&2, AST.SyntaxTerm>, v_4: Maybe<&2, EmitClosure>, v_6: String, v_8: EmitEnv}
  EmitterRequest_js_app_chain{v_1: String, v_4: Maybe<&2, EmitClosure>, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv}
  EmitterRequest_js_app_arrow_env{v_1: String, v_3: EmitClosure, v_4: AST.SyntaxTerm, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_10: EmitEnv}
  EmitterRequest_js_app_arrow{v_1: String, v_3: EmitClosure, v_4: AST.SyntaxTerm, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv}
  EmitterRequest_js_app_quantity{v_0: AST.Quantity, v_2: String, v_5: Maybe<&2, EmitClosure>, v_8: Maybe<&2, EmitClosure>, v_9: AST.SyntaxTerm, v_11: List<&2, AST.SyntaxTerm>, v_13: EmitEnv}
  EmitterRequest_js_lambda{v_1: Maybe<&2, AST.Quantity>, v_2: AST.SyntaxTerm, v_4: EmitEnv, v_7: Maybe<&2, EmitClosure>}
  EmitterRequest_js_lambda_view_env{v_1: Maybe<&2, AST.Quantity>, v_2: AST.SyntaxTerm, v_4: EmitEnv, v_6: EmitClosure, v_8: EmitEnv}
  EmitterRequest_js_lambda_view{v_1: Maybe<&2, AST.Quantity>, v_2: AST.SyntaxTerm, v_4: EmitEnv, v_6: EmitClosure}
  EmitterRequest_js_binder_name{v_0: AST.Quantity, v_2: String}
  EmitterRequest_js_lambda_untyped{v_1: Maybe<&2, AST.Quantity>, v_2: AST.SyntaxTerm, v_4: EmitEnv}
  EmitterRequest_js_lambda_quantity{v_0: AST.Quantity, v_2: String, v_3: AST.SyntaxTerm, v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>}
  EmitterRequest_js_closure{v_1: String, v_3: String}
  EmitterRequest_env_depth{v_1: EmitEnv}
  EmitterRequest_env_reserve_names{v_1: Nat, v_3: EmitEnv}
  EmitterRequest_js_term_sub{v_1: Nat, v_2: AST.SyntaxTerm, v_3: AST.SyntaxTerm, v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>}
  EmitterRequest_js_term_let{v_2: List<&2, String>, v_4: List<&2, AST.Quantity>, v_6: List<&2, AST.SyntaxTerm>, v_7: AST.SyntaxTerm, v_9: EmitEnv, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>, v_16: Nat}
  EmitterRequest_js_body_local{v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, v_6: EmitEnv, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>}
  EmitterRequest_js_body_local_constructor{v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, v_6: EmitEnv, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>}
  EmitterRequest_js_constructor{v_1: String, v_3: List<&2, AST.SyntaxTerm>, v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>}
  EmitterRequest_js_constructor_literal{v_2: Maybe<&2, String>, v_4: String, v_6: String, v_8: List<&2, AST.SyntaxTerm>, v_10: EmitEnv, v_13: Maybe<&2, EmitClosure>}
  EmitterRequest_js_native_word_literal{v_1: String, v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv}
  EmitterRequest_js_native_word_declared{v_1: String, v_3: String, v_4: AST.SyntaxTerm, v_6: EmitEnv}
  EmitterRequest_js_word_literal_render{v_2: Maybe<&2, Nat>, v_4: Bool}
  EmitterRequest_js_word_identity{v_2: Maybe<&2, EmitConstructor>}
  EmitterRequest_js_closed_word{+v_1: Nat, v_2: AST.SyntaxTerm, v_4: EmitEnv}
  EmitterRequest_js_closed_word_constructor{+v_1: Nat, v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv}
  EmitterRequest_js_closed_bit{v_0: AST.SyntaxTerm, v_2: EmitEnv}
  EmitterRequest_js_closed_bit_identity{v_1: String}
  EmitterRequest_js_closed_word_bit{v_2: Maybe<&2, Nat>, v_4: Nat, v_5: AST.SyntaxTerm, v_7: EmitEnv}
  EmitterRequest_js_closed_word_combine{v_1: Nat, v_4: Maybe<&2, Nat>}
  EmitterRequest_js_string_literal{+v_2: List<&2, U32>, +v_3: AST.StringLiteralNames, +v_4: AST.SourceSpan, +v_6: EmitEnv, v_9: Maybe<&2, EmitClosure>}
  EmitterRequest_js_string_literal_authorized{v_1: Bool, +v_4: List<&2, U32>, v_5: AST.StringLiteralNames, v_6: AST.SourceSpan, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>}
  EmitterRequest_js_string_literal_payload{v_3: Maybe<&2, List<&2, Char>>, v_6: List<&2, U32>, v_7: AST.StringLiteralNames, v_8: AST.SourceSpan, v_10: EmitEnv, v_13: Maybe<&2, EmitClosure>}
  EmitterRequest_js_string_scalar_chars{v_2: List<&2, U32>}
  EmitterRequest_js_string_scalar_char{v_1: Bool, v_3: U32, v_6: List<&2, U32>}
  EmitterRequest_js_string_scalar_cons{v_3: Maybe<&2, List<&2, Char>>, v_5: U32}
  EmitterRequest_js_string_names_native{v_0: AST.StringLiteralNames, +v_2: EmitEnv}

type EmitterRequestGroup4 is Type:
  EmitterRequest_js_string_constructor_native{+v_1: String, +v_3: String, +v_5: EmitEnv}
  EmitterRequest_js_string_constructor_schema{v_1: String, v_3: String, v_5: EmitEnv}
  EmitterRequest_js_string_schema_owner{v_2: Maybe<&2, EmitModuleIndex>, v_4: String, v_6: String, v_8: EmitScope}
  EmitterRequest_js_string_schema_global{v_2: Maybe<&2, EmitModuleIndex>, v_4: String, v_6: String}
  EmitterRequest_js_string_schema_decl{v_2: Maybe<&2, EmitConstructorOwner>, v_4: String, v_6: String}
  EmitterRequest_js_string_schema_fields{v_1: String, v_3: List<&2, AST.TelescopeItem>, v_5: List<&2, AST.TelescopeItem>, +v_7: String}
  EmitterRequest_js_string_schema_nat{v_0: AST.SyntaxTerm, v_2: Nat, +v_4: String}
  EmitterRequest_js_string_schema_ref{v_0: AST.SyntaxTerm, v_2: String, v_4: String}
  EmitterRequest_js_string_schema_key{+v_1: String, +v_3: String, v_5: String}
  EmitterRequest_js_constructor_args{v_1: List<&2, AST.SyntaxTerm>, v_4: Maybe<&2, EmitClosure>, v_6: EmitEnv}
  EmitterRequest_js_constructor_arg_view_env{v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>, v_4: EmitClosure, v_6: EmitEnv, v_8: EmitEnv}
  EmitterRequest_js_constructor_arg_view{v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>, v_4: EmitClosure, v_6: EmitEnv}
  EmitterRequest_js_constructor_arg_quantity{v_0: AST.Quantity, v_1: AST.SyntaxTerm, v_4: Maybe<&2, EmitClosure>, v_6: EmitEnv}
  EmitterRequest_js_constructor_native{v_1: String}
  EmitterRequest_js_constructor_native_identity_found{v_2: Maybe<&2, EmitConstructor>, v_4: String}
  EmitterRequest_js_constructor_native_identity{v_1: String, v_3: EmitEnv}
  EmitterRequest_js_constructor_native_origin{v_1: Bool, v_3: String, v_5: String}
  EmitterRequest_js_base_origin{v_1: EmitEnv}
  EmitterRequest_js_base_source_suffix{v_1: Bool, v_3: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_base_source_exact{v_1: Bool, v_3: String, v_5: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_base_source{v_1: String, v_3: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_base_imported{v_1: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_base_imported_next{v_1: Bool, v_3: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_base_imports{v_1: List<&2, AST.ModuleImport>}
  EmitterRequest_js_base_imports_next{v_1: Bool, v_3: List<&2, AST.ModuleImport>}
  EmitterRequest_js_source_at{v_2: List<&2, String>, v_4: Nat}
  EmitterRequest_js_sources{v_2: List<&2, String>}
  EmitterRequest_js_constructor_render{v_1: String, v_3: String, v_6: List<&2, String>, v_8: EmitEnv}
  EmitterRequest_js_constructor_record{v_2: Maybe<&2, EmitConstructor>, v_4: String, v_7: List<&2, String>}
  EmitterRequest_js_constructor_record_exact{v_2: Maybe<&2, String>, v_4: String}
  EmitterRequest_js_constructor_record_fields{v_1: List<&2, AST.TelescopeItem>, v_4: List<&2, String>}
  EmitterRequest_js_constructor_record_field{v_2: Maybe<&2, String>, v_4: String, v_6: String}
  EmitterRequest_js_object_key{v_1: String}
  EmitterRequest_ctor_short{v_1: String}
  EmitterRequest_ctor_short_chars{v_2: List<&2, Char>, v_5: List<&2, Char>}
  EmitterRequest_js_match{v_0: AST.SyntaxTerm, v_1: AST.SyntaxTerm, v_3: EmitEnv, v_6: Maybe<&2, EmitClosure>}
  EmitterRequest_pattern_test{v_0: AST.SyntaxPattern, v_2: String, v_4: EmitEnv}
  EmitterRequest_pattern_test_constructor{v_2: Maybe<&2, EmitConstructor>, v_4: String, v_6: List<&2, AST.SyntaxPattern>, v_8: String, v_10: EmitEnv}
  EmitterRequest_pattern_test_constructor_tagged{v_1: Bool, v_3: String, v_5: String, v_7: List<&2, AST.SyntaxPattern>, v_9: List<&2, AST.TelescopeItem>, v_11: String, v_13: EmitEnv}
  EmitterRequest_pattern_test_native_literal{v_2: Maybe<&2, Nat>, v_4: String, v_6: String, v_8: List<&2, AST.SyntaxPattern>, v_10: List<&2, AST.TelescopeItem>, v_12: String, v_14: EmitEnv}
  EmitterRequest_pattern_test_native_bits{v_1: Bool, v_3: Nat, v_5: String}
  EmitterRequest_js_native_word_pattern{v_1: String, v_3: List<&2, AST.SyntaxPattern>, v_5: EmitEnv}
  EmitterRequest_js_closed_word_pattern{+v_1: Nat, v_2: AST.SyntaxPattern, v_4: EmitEnv}
  EmitterRequest_js_closed_word_pattern_constructor{+v_1: Nat, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: EmitEnv}
  EmitterRequest_js_closed_bit_pattern{v_0: AST.SyntaxPattern, v_2: EmitEnv}
  EmitterRequest_js_closed_word_pattern_bit{v_2: Maybe<&2, Nat>, v_4: Nat, v_5: AST.SyntaxPattern, v_7: EmitEnv}
  EmitterRequest_js_field_projection{v_1: String, v_3: String}
  EmitterRequest_pattern_decl_fields_test{v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.TelescopeItem>, v_5: String, v_7: EmitEnv}
  EmitterRequest_pattern_test_ctor{v_1: String, v_3: List<&2, AST.SyntaxPattern>, v_5: String, v_7: EmitEnv}
  EmitterRequest_pattern_test_true{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_test_false{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_test_zero{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_test_succ{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_test_snil{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_test_scon{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_test_u32{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_test_f32{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_test_aleaf{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_test_anode{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_test_char{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_fields_test{v_1: List<&2, AST.SyntaxPattern>, v_3: String, v_5: String, v_7: Nat, v_9: EmitEnv}
  EmitterRequest_patterns_test{v_1: List<&2, AST.SyntaxPattern>, v_4: List<&2, String>, v_6: EmitEnv}
  EmitterRequest_pattern_vars{v_0: AST.SyntaxPattern, v_2: String, v_4: EmitEnv}
  EmitterRequest_pattern_vars_constructor{v_2: Maybe<&2, EmitConstructor>, v_4: String, v_6: List<&2, AST.SyntaxPattern>, v_8: String, v_10: EmitEnv}

type EmitterRequestGroup5 is Type:
  EmitterRequest_pattern_vars_constructor_tagged{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: List<&2, AST.TelescopeItem>, v_9: String, v_11: EmitEnv}
  EmitterRequest_pattern_erased_vars{v_0: AST.SyntaxPattern}
  EmitterRequest_patterns_erased_vars{v_1: List<&2, AST.SyntaxPattern>}
  EmitterRequest_pattern_decl_fields_vars{v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.TelescopeItem>, v_5: String, v_7: EmitEnv}
  EmitterRequest_pattern_vars_ctr{v_1: String, v_3: List<&2, AST.SyntaxPattern>, v_5: String, v_7: EmitEnv}
  EmitterRequest_pattern_vars_succ{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_vars_scon{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_vars_char{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_vars_u32{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_vars_f32{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_vars_aleaf{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_vars_anode{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv}
  EmitterRequest_pattern_array_field_value{v_1: String, v_3: Nat}
  EmitterRequest_pattern_array_fields{v_1: List<&2, AST.SyntaxPattern>, v_3: String, v_5: Nat, v_7: EmitEnv}
  EmitterRequest_pattern_string_field_value{v_1: String, v_3: Nat}
  EmitterRequest_pattern_string_fields{v_1: List<&2, AST.SyntaxPattern>, v_3: String, v_5: Nat, v_7: EmitEnv}
  EmitterRequest_pattern_fields_vars{v_1: List<&2, AST.SyntaxPattern>, v_3: String, v_5: String, v_7: Nat, v_9: EmitEnv}
  EmitterRequest_js_positional_projection{v_1: String, v_3: String, v_5: Nat}
  EmitterRequest_patterns_vars{v_1: List<&2, AST.SyntaxPattern>, v_4: List<&2, String>, v_6: EmitEnv}
  EmitterRequest_js_case{v_1: List<&2, AST.SyntaxPattern>, v_2: AST.SyntaxTerm, v_5: List<&2, String>, v_7: List<&2, AST.SyntaxTerm>, v_9: EmitEnv, v_12: Maybe<&2, EmitClosure>}
  EmitterRequest_js_case_typed{v_1: List<&2, AST.SyntaxPattern>, v_2: AST.SyntaxTerm, v_5: List<&2, String>, v_9: List<&2, Maybe<&2, EmitClosure>>, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>}
  EmitterRequest_js_case_block_typed{v_1: List<&2, AST.SyntaxPattern>, v_2: AST.SyntaxTerm, v_5: List<&2, String>, v_9: List<&2, Maybe<&2, EmitClosure>>, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>}
  EmitterRequest_js_case_binding_names{v_2: List<&2, String>, v_4: Nat}
  EmitterRequest_js_case_binding_name{v_1: Bool, v_3: Nat}
  EmitterRequest_js_case_bindings{v_2: List<&2, String>, v_5: List<&2, String>}
  EmitterRequest_js_case_binding_source{v_1: Bool, v_3: String, v_5: String, v_7: String}
  EmitterRequest_js_cases{v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, String>, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>}
  EmitterRequest_js_switch_tags{v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv, v_6: Map<&2, Bool>}
  EmitterRequest_js_switch_fields{v_1: List<&2, AST.SyntaxPattern>}
  EmitterRequest_js_switch_tag_constructor{v_2: Maybe<&2, EmitConstructor>, v_4: List<&2, AST.SyntaxTerm>, v_6: EmitEnv, v_9: Map<&2, Bool>}
  EmitterRequest_js_switch_tag_fields{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv, v_10: Map<&2, Bool>}
  EmitterRequest_js_switch_tag_seen{v_2: Maybe<&2, Bool>, v_4: String, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_11: Map<&2, Bool>}
  EmitterRequest_js_switch_tag_native{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv, v_10: Map<&2, Bool>}
  EmitterRequest_js_switch_tag_ordered{v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv, v_10: Map<&2, Bool>}
  EmitterRequest_js_switch_bmp_tag{v_1: String}
  EmitterRequest_js_switch_bmp_tail{v_1: Bool, v_3: String}
  EmitterRequest_js_switch_tag_rest{v_1: String, v_5: Maybe<&2, List<&2, String>>}
  EmitterRequest_js_switch_cases{v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, String>, v_7: List<&2, String>, v_9: List<&2, AST.SyntaxTerm>, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>}
  EmitterRequest_js_switch_pairs{v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, String>}
  EmitterRequest_js_switch_row_le{v_1: EmitSwitchRow, v_3: EmitSwitchRow}
  EmitterRequest_js_switch_sort{v_1: Nat, +v_4: List<&2, EmitSwitchRow>}
  EmitterRequest_js_switch_merge{v_2: List<&2, EmitSwitchRow>, v_5: List<&2, EmitSwitchRow>}
  EmitterRequest_js_switch_merge_right{v_2: List<&2, EmitSwitchRow>, +v_4: EmitSwitchRow, +v_7: List<&2, EmitSwitchRow>}
  EmitterRequest_js_switch_merge_order{v_1: Bool, +v_3: EmitSwitchRow, +v_6: List<&2, EmitSwitchRow>, +v_8: EmitSwitchRow, +v_11: List<&2, EmitSwitchRow>}
  EmitterRequest_js_switch_tree{v_1: Nat, v_4: List<&2, EmitSwitchRow>, v_6: String, v_9: List<&2, String>, v_11: List<&2, AST.SyntaxTerm>, v_13: EmitEnv, v_16: Maybe<&2, EmitClosure>}
  EmitterRequest_js_switch_tree_leaf{v_2: List<&2, EmitSwitchRow>, v_4: String, v_7: List<&2, String>, v_9: List<&2, AST.SyntaxTerm>, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>}
  EmitterRequest_js_switch_tree_split{v_2: List<&2, EmitSwitchRow>, v_5: List<&2, EmitSwitchRow>, v_7: Nat, v_9: Nat, v_11: String, v_14: List<&2, String>, v_16: List<&2, AST.SyntaxTerm>, v_18: EmitEnv, v_21: Maybe<&2, EmitClosure>}
  EmitterRequest_js_cases_dispatch_size{v_1: Bool, v_3: Nat, v_6: List<&2, String>, v_8: String, v_10: List<&2, AST.SyntaxTerm>, v_13: List<&2, String>, v_15: List<&2, AST.SyntaxTerm>, v_17: EmitEnv, v_20: Maybe<&2, EmitClosure>}
  EmitterRequest_js_cases_dispatch_values{v_2: List<&2, String>, v_4: List<&2, AST.SyntaxTerm>, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>}
  EmitterRequest_js_cases_dispatch{v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, String>, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>}
  EmitterRequest_js_cases_dispatch_switch{v_3: Maybe<&2, List<&2, String>>, v_5: String, v_7: List<&2, AST.SyntaxTerm>, v_10: List<&2, String>, v_12: List<&2, AST.SyntaxTerm>, v_14: EmitEnv, v_17: Maybe<&2, EmitClosure>}
  EmitterRequest_js_scrutinees{v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv, v_5: Nat}
  EmitterRequest_scrutinee_names{v_1: Nat, v_3: EmitEnv}
  EmitterRequest_scrutinee_names_at{v_1: Nat, v_3: Nat}
  EmitterRequest_js_body_match{v_1: List<&2, AST.SyntaxTerm>, v_3: List<&2, AST.SyntaxTerm>, v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>}
  EmitterRequest_js_binders{v_1: List<&2, AST.TelescopeItem>, v_3: EmitEnv, v_4: AST.SyntaxTerm, v_5: AST.OptionalTerm}
  EmitterRequest_js_decl{v_1: String, v_3: String, v_4: AST.TopLevel, v_6: EmitEnv}
  EmitterRequest_js_decl_term{v_1: Bool, v_3: String, v_5: List<&2, AST.TelescopeItem>, v_6: AST.OptionalTerm, v_7: AST.SyntaxTerm, v_9: EmitEnv}
  EmitterRequest_js_decl_term_operation{v_2: Maybe<&2, String>, v_4: String, v_6: List<&2, AST.TelescopeItem>, v_7: AST.OptionalTerm, v_8: AST.SyntaxTerm, v_10: EmitEnv}
  EmitterRequest_js_named_eligible{v_1: String, +v_3: List<&2, AST.TelescopeItem>, +v_4: AST.OptionalTerm, +v_5: AST.SyntaxTerm, +v_7: EmitEnv}
  EmitterRequest_js_named_eligible_operation{v_2: Maybe<&2, String>, +v_4: List<&2, AST.TelescopeItem>, +v_5: AST.OptionalTerm, +v_6: AST.SyntaxTerm, +v_8: EmitEnv}
  EmitterRequest_js_named_fixed{v_1: List<&2, AST.TelescopeItem>, v_2: AST.OptionalTerm}
  EmitterRequest_js_decl_named{v_1: Bool, v_3: String, v_5: List<&2, AST.TelescopeItem>, v_6: AST.OptionalTerm, v_7: AST.SyntaxTerm, v_9: EmitEnv}
  EmitterRequest_js_named_body{v_1: List<&2, AST.TelescopeItem>, v_3: EmitEnv, v_4: AST.SyntaxTerm, v_5: AST.OptionalTerm, v_7: Bool}

type EmitterRequestGroup6 is Type:
  EmitterRequest_js_named_facade{v_1: List<&2, AST.TelescopeItem>, v_3: EmitEnv, v_5: String, v_8: List<&2, String>}
  EmitterRequest_js_decl_native_law{v_2: Maybe<&2, String>, v_5: Maybe<&2, List<&2, AST.TelescopeItem>>, v_7: String}
  EmitterRequest_js_decl_native_value{v_1: String, v_3: String, v_5: List<&2, AST.TelescopeItem>}
  EmitterRequest_js_decl_native_runtime{v_2: Maybe<&2, EmitPrimitive>, v_4: String, v_6: String}
  EmitterRequest_js_native_facade{v_2: List<&2, String>, v_5: List<&2, String>, v_7: String}
  EmitterRequest_js_definition_has_live_binder{v_1: List<&2, AST.TelescopeItem>}
  EmitterRequest_js_decl_value{v_1: Bool, v_3: String, v_5: String}
  EmitterRequest_js_decl_deferred_value{v_1: String, v_3: String}
  EmitterRequest_js_definition_is_type{v_1: List<&2, AST.TelescopeItem>, v_2: AST.OptionalTerm, v_3: AST.SyntaxTerm, v_5: EmitEnv}
  EmitterRequest_js_inferred_is_sort{v_2: Maybe<&2, EmitClosure>}
  EmitterRequest_js_type_is_sort{v_1: EmitClosure}
  EmitterRequest_js_live_binders{v_1: List<&2, AST.TelescopeItem>}
  EmitterRequest_js_foreign{v_2: List<&2, String>, v_4: String, v_6: String, v_8: List<&2, AST.TelescopeItem>}
  EmitterRequest_js_foreign_path{v_1: Bool, v_4: List<&2, String>, v_6: String, v_8: String, v_10: String, v_12: List<&2, AST.TelescopeItem>}
  EmitterRequest_js_decls{v_1: String, v_3: String, v_5: List<&2, AST.TopLevel>, v_7: EmitEnv}
  EmitterRequest_alias_namespace{v_1: String, v_3: String, v_6: Map<&2, String>}
  EmitterRequest_alias_namespace_base{v_1: Bool, v_3: String, v_5: String, v_8: Map<&2, String>}
  EmitterRequest_alias_namespace_found{v_2: Maybe<&2, String>}
  EmitterRequest_js_resolved_alias_entries{v_1: List<&2, AST.ModuleImport>, v_4: Map<&2, String>}
  EmitterRequest_js_resolved_aliases{+v_2: List<&2, EmitAlias>, v_4: Bool, v_7: Map<&2, String>}
  EmitterRequest_js_aliases{v_1: EmitAliases}
  EmitterRequest_js_alias_source{v_2: List<&2, EmitAlias>}
  EmitterRequest_js_alias_entries{v_2: List<&2, EmitAlias>}
  EmitterRequest_js_module{v_1: String, v_2: AST.Module, v_4: EmitAliases, v_6: EmitCatalog}
  EmitterRequest_js_modules{v_1: List<&2, Loader.LoadedModule>, v_3: EmitCatalog}
  EmitterRequest_js_modules_at{v_1: List<&2, Loader.LoadedModule>, v_3: EmitCatalog, v_6: List<&2, EmitModuleIndex>}
  EmitterRequest_qualify{v_1: String, v_3: String}
  EmitterRequest_qualify_result{v_1: Bool, v_3: String, v_5: String}
  EmitterRequest_first_span{v_1: Maybe<&2, AST.SourceSpan>, v_3: Maybe<&2, AST.SourceSpan>}
  EmitterRequest_error_terms{v_1: List<&2, AST.SyntaxTerm>}
  EmitterRequest_error_term{v_0: AST.SyntaxTerm}
  EmitterRequest_error_optional_term{v_0: AST.OptionalTerm}
  EmitterRequest_error_def_body{v_0: AST.DefBody}
  EmitterRequest_error_decl{v_0: AST.TopLevel}
  EmitterRequest_error_binders{v_1: List<&2, AST.TelescopeItem>}
  EmitterRequest_error_constructors{v_1: List<&2, AST.ConstructorDecl>}
  EmitterRequest_error_condition{v_1: Maybe<&2, AST.SyntaxTerm>}
  EmitterRequest_error_clauses{v_1: List<&2, AST.Clause>}
  EmitterRequest_error_decls{v_1: List<&2, AST.TopLevel>}
  EmitterRequest_error_modules{v_1: List<&2, Loader.LoadedModule>}
  EmitterRequest_template_terms{v_1: List<&2, AST.SyntaxTerm>}
  EmitterRequest_template_term{v_0: AST.SyntaxTerm}
  EmitterRequest_template_binders{v_1: List<&2, AST.TelescopeItem>}
  EmitterRequest_template_constructors{v_1: List<&2, AST.ConstructorDecl>}
  EmitterRequest_template_condition{v_1: Maybe<&2, AST.SyntaxTerm>}
  EmitterRequest_template_clauses{v_1: List<&2, AST.Clause>}
  EmitterRequest_template_optional_term{v_0: AST.OptionalTerm}
  EmitterRequest_template_def_body{v_0: AST.DefBody}
  EmitterRequest_template_decl{v_0: AST.TopLevel}
  EmitterRequest_template_decls{v_1: List<&2, AST.TopLevel>}
  EmitterRequest_template_modules{v_1: List<&2, Loader.LoadedModule>}
  EmitterRequest_has_js_import{v_2: List<&2, String>}
  EmitterRequest_foreign_error_decl{v_0: AST.TopLevel}
  EmitterRequest_foreign_error_js{v_1: Bool, v_2: AST.SourceSpan}
  EmitterRequest_foreign_error_decls{v_1: List<&2, AST.TopLevel>}
  EmitterRequest_foreign_error_modules{v_1: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_runtime{}
  EmitterRequest_js_runtime_extra{}
  EmitterRequest_js_runtime_array{}
  EmitterRequest_js_runtime_foreign{}
  EmitterRequest_js_runtime_namespace{}
  EmitterRequest_js_runtime_field_names{v_1: List<&2, AST.TelescopeItem>}
  EmitterRequest_js_runtime_field_names_at{v_1: List<&2, AST.TelescopeItem>, v_3: Bool}
  EmitterRequest_js_constructor_fields_one{v_1: String, v_3: String, v_5: Bool, v_6: AST.ConstructorDecl}

type EmitterRequestGroup7 is Type:
  EmitterRequest_js_constructor_fields_constructors{v_1: String, v_3: String, v_5: Bool, v_7: List<&2, AST.ConstructorDecl>}
  EmitterRequest_js_constructor_fields_decl{v_1: String, v_3: Bool, v_4: AST.TopLevel}
  EmitterRequest_js_constructor_fields_decls{v_1: String, v_3: Bool, v_5: List<&2, AST.TopLevel>}
  EmitterRequest_js_constructor_fields_modules{v_1: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_constructor_fields_modules_at{v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>}
  EmitterRequest_js_type_ref{v_1: String, v_3: List<&2, AST.SyntaxTerm>, v_5: String, v_7: String}
  EmitterRequest_js_type_args{v_1: List<&2, AST.SyntaxTerm>, v_3: String, v_5: String, v_7: Bool}
  EmitterRequest_js_type_sugar_descriptor{v_1: String, v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, v_6: String, v_8: String, v_10: String}
  EmitterRequest_js_type_sugar{v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>, v_4: String, v_6: String, v_8: String}
  EmitterRequest_js_type_term{v_0: AST.SyntaxTerm, v_2: String, v_4: String}
  EmitterRequest_js_type_quantity{v_0: AST.Quantity}
  EmitterRequest_js_type_optional_quantity{v_1: Maybe<&2, AST.Quantity>}
  EmitterRequest_js_type_binary{v_1: String, v_2: AST.SyntaxTerm, v_4: String, v_5: AST.SyntaxTerm, v_7: String, v_9: String}
  EmitterRequest_js_type_constructor{v_1: String, v_3: List<&2, AST.SyntaxTerm>, v_5: String, v_7: String}
  EmitterRequest_js_type_application{v_1: Pair(AST.SyntaxTerm, List<&2, AST.SyntaxTerm>), v_3: String, v_5: String}
  EmitterRequest_js_type_application_args{v_1: String, v_3: List<&2, AST.SyntaxTerm>, v_5: String, v_7: String}
  EmitterRequest_js_type_let{v_1: List<&2, AST.SyntaxTerm>, v_2: AST.SyntaxTerm, v_4: String, v_6: String}
  EmitterRequest_js_type_patterns_source{v_1: List<&2, AST.SyntaxPattern>, v_3: String, v_5: String, v_7: Bool}
  EmitterRequest_js_type_pattern_source{v_0: AST.SyntaxPattern, v_2: String, v_4: String}
  EmitterRequest_js_type_cases_source{v_1: List<&2, AST.SyntaxTerm>, v_3: String, v_5: String, v_7: Bool}
  EmitterRequest_js_type_field_terms{v_1: List<&2, AST.TelescopeItem>, v_3: String, v_5: String, v_7: Bool}
  EmitterRequest_js_type_arm{v_0: AST.ConstructorDecl, v_2: String, v_4: String}
  EmitterRequest_js_type_field_quantities{v_1: List<&2, AST.TelescopeItem>, v_3: Bool}
  EmitterRequest_js_type_arms{v_1: List<&2, AST.ConstructorDecl>, v_3: String, v_5: String, v_7: Bool}
  EmitterRequest_js_type_decl{v_1: String, v_3: EmitAliases, v_4: AST.TopLevel, v_6: EmitCatalog}
  EmitterRequest_js_type_native_marker{v_1: Bool, v_3: String}
  EmitterRequest_js_type_decls{v_1: String, v_3: EmitAliases, v_5: List<&2, AST.TopLevel>, v_7: EmitCatalog}
  EmitterRequest_js_type_modules{v_1: List<&2, Loader.LoadedModule>, v_3: EmitCatalog}
  EmitterRequest_js_type_modules_needed{v_1: EmitTypeNeeded, v_3: List<&2, Loader.LoadedModule>, v_5: EmitCatalog}
  EmitterRequest_js_type_modules_at{v_1: List<&2, Loader.LoadedModule>, v_3: EmitCatalog, v_6: List<&2, EmitModuleIndex>}
  EmitterRequest_js_type_needed_ref{v_1: String, v_3: EmitEnv, v_5: EmitTypeNeeded}
  EmitterRequest_js_type_needed_found{v_2: Maybe<&2, EmitClosure>, +v_4: EmitTypeNeeded}
  EmitterRequest_js_type_needed_definition{v_2: Maybe<&2, Bool>, v_4: String, v_6: List<&2, AST.TelescopeItem>, v_7: AST.SyntaxTerm, v_9: EmitEnv, v_11: EmitTypeNeeded}
  EmitterRequest_js_type_needed_terms{v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv, v_5: EmitTypeNeeded}
  EmitterRequest_js_type_needed_term{v_0: AST.SyntaxTerm, v_2: EmitEnv, v_4: EmitTypeNeeded}
  EmitterRequest_js_type_needed_binders{v_1: List<&2, AST.TelescopeItem>, v_3: EmitEnv, v_5: EmitTypeNeeded}
  EmitterRequest_js_type_needed_result{v_0: AST.OptionalTerm, v_2: EmitEnv, v_4: EmitTypeNeeded}
  EmitterRequest_js_type_needed_constructors{v_1: List<&2, AST.ConstructorDecl>, v_3: EmitEnv, v_5: EmitTypeNeeded}
  EmitterRequest_js_type_needed_declarations{v_1: List<&2, AST.TopLevel>, v_3: EmitEnv, v_5: EmitTypeNeeded}
  EmitterRequest_js_type_needed_definition_root{v_1: String, v_3: List<&2, AST.TelescopeItem>, v_4: AST.OptionalTerm, v_5: AST.DefBody, v_7: EmitEnv, v_9: EmitTypeNeeded}
  EmitterRequest_js_type_needed_definition_root_kind{v_1: Bool, v_3: String, v_5: EmitEnv, v_7: EmitTypeNeeded}
  EmitterRequest_js_type_needed_modules{v_1: List<&2, Loader.LoadedModule>, v_3: EmitTypeNeeded, v_5: EmitCatalog}
  EmitterRequest_js_type_needed_modules_at{v_1: List<&2, Loader.LoadedModule>, v_3: EmitTypeNeeded, v_5: EmitCatalog, v_8: List<&2, EmitModuleIndex>}
  EmitterRequest_js_type_function_sources{v_2: List<&2, EmitTypeDefinition>}
  EmitterRequest_main_type_expr_declaration{v_0: AST.TopLevel, v_2: String, v_4: String}
  EmitterRequest_main_type_expr_is_main{v_1: Bool, v_2: AST.OptionalTerm, v_4: String, v_6: String}
  EmitterRequest_main_type_expr_declarations{v_1: List<&2, AST.TopLevel>, v_3: String, v_5: String}
  EmitterRequest_main_type_expr_declaration_result{v_1: String, v_3: List<&2, AST.TopLevel>, v_5: String, v_7: String}
  EmitterRequest_main_type_expr_declaration_empty{v_1: Bool, v_3: String, v_5: List<&2, AST.TopLevel>, v_7: String, v_9: String}
  EmitterRequest_main_type_expr_modules{v_1: List<&2, Loader.LoadedModule>, v_3: EmitCatalog}
  EmitterRequest_main_type_expr_modules_at{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, EmitModuleIndex>}
  EmitterRequest_main_type_expr_module_scope{v_1: Bool, v_3: String, v_5: EmitAliases, v_7: List<&2, AST.TopLevel>, v_9: List<&2, Loader.LoadedModule>, v_12: List<&2, EmitModuleIndex>}
  EmitterRequest_main_type_expr_module_result{v_1: String, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, EmitModuleIndex>}
  EmitterRequest_main_type_expr_module_empty{v_1: Bool, v_3: String, v_5: List<&2, Loader.LoadedModule>, v_8: List<&2, EmitModuleIndex>}
  EmitterRequest_js_runtime_cli{}
  EmitterRequest_js_runtime_io{}
  EmitterRequest_js_runtime_show{}
  EmitterRequest_js_runtime_type{}
  EmitterRequest_js_runtime_type_names{}
  EmitterRequest_js_runtime_type_patterns{}
  EmitterRequest_js_runtime_type_eval{}
  EmitterRequest_js_runtime_native_type{}
  EmitterRequest_js_main{v_1: String}
  EmitterRequest_emit{v_1: List<&2, Loader.LoadedModule>}

type EmitterRequestGroup8 is Type:
  EmitterRequest_js_emit_template{v_1: Maybe<&2, AST.SourceSpan>, v_3: List<&2, Loader.LoadedModule>, v_7: Maybe<&2, List<&2, String>>}
  EmitterRequest_js_emit_holes{v_1: Maybe<&2, AST.SourceSpan>, v_3: List<&2, Loader.LoadedModule>, v_7: Maybe<&2, List<&2, String>>}
  EmitterRequest_js_emit_foreign{v_1: Maybe<&2, AST.SourceSpan>, v_3: List<&2, Loader.LoadedModule>, v_7: Maybe<&2, List<&2, String>>}
  EmitterRequest_js_library_exports{v_2: List<&2, String>}
  EmitterRequest_js_library_export_fields{v_2: List<&2, String>}
  EmitterRequest_emit_library{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, String>}
  EmitterRequest_js_emit_ending{v_3: Maybe<&2, List<&2, String>>, v_5: List<&2, Loader.LoadedModule>, v_7: EmitCatalog}

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

def emitter_result_group_0(request: EmitterRequestGroup0) -> Type:
  match request:
    case EmitterRequest_js_value_indices{_}: EmitCatalog
    case EmitterRequest_js_catalog{_}: EmitCatalog
    case EmitterRequest_js_catalog_at{_, _}: EmitCatalog
    case EmitterRequest_js_catalog_module{_, _}: EmitCatalog
    case EmitterRequest_js_catalog_values{_, _, _}: Map<&2, EmitModuleIndex>
    case EmitterRequest_js_catalog_constructors{_, _, _}: Map<&2, EmitModuleIndex>
    case EmitterRequest_js_catalog_types{_, _, _}: Map<&2, List<&2, EmitModuleIndex>>
    case EmitterRequest_js_catalog_type_insert{_, _, _, _}: Map<&2, List<&2, EmitModuleIndex>>
    case EmitterRequest_js_catalog_layouts{_}: List<&2, EmitModuleIndex>
    case EmitterRequest_js_namespace_indices{_}: Map<&2, String>
    case EmitterRequest_js_value_indices_at{_, _, _}: List<&2, EmitModuleIndex>
    case EmitterRequest_js_value_declarations{_, _}: Map<&2, AST.Definition>
    case EmitterRequest_js_value_declaration{_, _, _}: Map<&2, AST.Definition>
    case EmitterRequest_js_constructor_indices{_, _}: Map<&2, EmitConstructorOwner>
    case EmitterRequest_js_constructor_index_family{_, _, _}: Map<&2, EmitConstructorOwner>
    case EmitterRequest_js_constructor_index_items{_, _, _, _}: Map<&2, EmitConstructorOwner>
    case EmitterRequest_js_type_indices{_, _}: Map<&2, List<&2, AST.TopLevel>>
    case EmitterRequest_js_type_index_declaration{_, _, _}: Map<&2, List<&2, AST.TopLevel>>
    case EmitterRequest_js_type_index_insert{_, _, _}: Map<&2, List<&2, AST.TopLevel>>
    case EmitterRequest_js_type_index_found{_, _, _, _}: Map<&2, List<&2, AST.TopLevel>>
    case EmitterRequest_js_escape_char{_}: String
    case EmitterRequest_js_comma_prefix{_}: String
    case EmitterRequest_js_quote_chars{_, _}: String
    case EmitterRequest_js_quote{_}: String
    case EmitterRequest_js_named_identifier_char{_, _, _}: String
    case EmitterRequest_js_named_identifier_chars{_, _}: String
    case EmitterRequest_js_named_identifier{_}: String
    case EmitterRequest_env_binding{_, _}: Maybe<&2, EmitBinding>
    case EmitterRequest_env_binding_at{_, _, _, _}: Maybe<&2, EmitBinding>
    case EmitterRequest_env_at_binding{_}: String
    case EmitterRequest_env_at{_, _}: String
    case EmitterRequest_env_bind{_, _, _, _}: EmitEnv
    case EmitterRequest_env_push{_, _}: EmitEnv
    case EmitterRequest_js_close{_, _}: EmitClosure
    case EmitterRequest_js_close_inferred{_, _, _}: EmitClosure
    case EmitterRequest_js_close_declared{_, _, _}: EmitClosure
    case EmitterRequest_js_close_definition{_, _, _, _}: EmitClosure
    case EmitterRequest_js_closure_env{_}: EmitEnv
    case EmitterRequest_js_scope_key{_, _}: String
    case EmitterRequest_js_scope_alias{_, _, _, _}: String
    case EmitterRequest_js_scope_alias_match{_, _, _, _, _, _, _}: String
    case EmitterRequest_js_global{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_fallback{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_lookup{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_owner{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_owner_env{_, _}: EmitEnv
    case EmitterRequest_js_global_definition{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_type{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_type_fallback{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_type_lookup{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_type_owners{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_type_modules{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_type_next{_, _, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_type_index{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_type_decls{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_type_definition{_, _, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_global_native_law_operation{_, _, _, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_native_law_type{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_native_law_binders{_, _}: Maybe<&2, List<&2, AST.TelescopeItem>>
    case EmitterRequest_js_native_law_binder{_, _}: Maybe<&2, List<&2, AST.TelescopeItem>>
    case EmitterRequest_js_type_definition{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_reduce_env{_, _}: EmitClosure
    case EmitterRequest_js_reduce{_}: EmitClosure
    case EmitterRequest_js_reduce_inferred{_, _}: EmitClosure

def emitter_result_group_1(request: EmitterRequestGroup1) -> Type:
  match request:
    case EmitterRequest_js_reduce_binding{_, _}: EmitClosure
    case EmitterRequest_js_reduce_global{_, _}: EmitClosure
    case EmitterRequest_js_reduce_app_env{_, _, _, _}: EmitClosure
    case EmitterRequest_js_reduce_app{_, _, _}: EmitClosure
    case EmitterRequest_js_reduce_patterns{_, _, _}: EmitPatternResult
    case EmitterRequest_js_reduce_patterns_next{_, _, _}: EmitPatternResult
    case EmitterRequest_js_reduce_pattern{_, _, _}: EmitPatternResult
    case EmitterRequest_js_reduce_pattern_view_env{_, _, _, _, _}: EmitPatternResult
    case EmitterRequest_js_reduce_pattern_view{_, _, _, _}: EmitPatternResult
    case EmitterRequest_js_same_scoped_key{_, _, _, _}: Bool
    case EmitterRequest_js_same_constructor_key{_, _}: Bool
    case EmitterRequest_js_reduce_pattern_key{_, _, _, _}: EmitPatternResult
    case EmitterRequest_js_reduce_local{_, _, _}: EmitClosure
    case EmitterRequest_js_reduce_cases{_, _, _, _}: EmitClosure
    case EmitterRequest_js_reduce_case_result{_, _, _, _, _, _}: EmitClosure
    case EmitterRequest_js_value_env{_, _}: EmitEnv
    case EmitterRequest_js_value_env_at{_, _, _}: EmitEnv
    case EmitterRequest_js_type{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_binding_type{_}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_type_value{_}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_type_local{_, _, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_type_local_refined{_, _, _, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_apply_type_args{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_apply_type{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_apply_type_view_env{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_apply_type_view{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_type_cases{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_env_insert_binding{_, _, _}: EmitEnv
    case EmitterRequest_env_insert_names{_, _, _}: List<&2, String>
    case EmitterRequest_env_insert_closures{_, _, _}: List<&2, Maybe<&2, EmitClosure>>
    case EmitterRequest_env_names_typed{_, _, _}: EmitEnv
    case EmitterRequest_js_scrutinee_types{_, _}: List<&2, Maybe<&2, EmitClosure>>
    case EmitterRequest_js_pattern_types{_, _, _}: List<&2, Maybe<&2, EmitClosure>>
    case EmitterRequest_js_pattern_type{_, _, _}: List<&2, Maybe<&2, EmitClosure>>
    case EmitterRequest_js_field_types{_}: List<&2, Maybe<&2, EmitClosure>>
    case EmitterRequest_js_field_types_view_env{_, _}: List<&2, Maybe<&2, EmitClosure>>
    case EmitterRequest_js_field_types_view{_}: List<&2, Maybe<&2, EmitClosure>>
    case EmitterRequest_js_constructor_decl{_, _}: Maybe<&2, EmitConstructor>
    case EmitterRequest_js_constructor_decl_fallback{_, _, _}: Maybe<&2, EmitConstructor>
    case EmitterRequest_js_constructor_lookup{_, _}: Maybe<&2, EmitConstructor>
    case EmitterRequest_js_constructor_index_owner{_, _, _}: Maybe<&2, EmitConstructor>
    case EmitterRequest_js_constructor_owner{_, _, _}: Maybe<&2, EmitConstructor>
    case EmitterRequest_js_constructor_signature{_, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_constructor_signature_found{_, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_family_parameter_arguments{_, _}: List<&2, EmitClosure>
    case EmitterRequest_js_family_parameter_view_env{_, _, _}: List<&2, EmitClosure>
    case EmitterRequest_js_family_parameter_view{_, _}: List<&2, EmitClosure>
    case EmitterRequest_js_family_arguments_view_env{_, _}: List<&2, EmitClosure>
    case EmitterRequest_js_family_arguments_view{_}: List<&2, EmitClosure>
    case EmitterRequest_js_family_fill_arguments{_, _, _, _, _}: List<&2, EmitClosure>
    case EmitterRequest_js_family_quant_prefix{_, _}: Nat
    case EmitterRequest_js_family_quant_domain{_, _, _}: Nat
    case EmitterRequest_js_family_fill_missing{_, _, _, _, _, _}: List<&2, EmitClosure>
    case EmitterRequest_js_quantity_closures{_, _, _, _}: List<&2, EmitClosure>
    case EmitterRequest_js_family_promote_arguments{_, _, _, _}: List<&2, EmitClosure>
    case EmitterRequest_js_closure_terms{_, _}: List<&2, EmitClosure>
    case EmitterRequest_js_constructor_parameter_types{_, _, _, _}: Maybe<&2, EmitClosure>
    case EmitterRequest_js_choose{_, _, _, _}: String
    case EmitterRequest_js_key_matches{_, _}: Bool
    case EmitterRequest_js_choose_exact{_, _, _, _}: String
    case EmitterRequest_js_choose_result{_, _, _}: String
    case EmitterRequest_js_reference{_}: String
    case EmitterRequest_js_native_operations{_, _, _}: Map<&2, String>
    case EmitterRequest_js_native_operation_declarations{_, _}: Map<&2, String>

def emitter_result_group_2(request: EmitterRequestGroup2) -> Type:
  match request:
    case EmitterRequest_js_native_operation_insert_keys{_, _, _}: Map<&2, String>
    case EmitterRequest_js_native_operation_insert{_, _}: Map<&2, String>
    case EmitterRequest_js_native_operation_insert_found{_, _, _}: Map<&2, String>
    case EmitterRequest_js_native_operation_origin{_, _}: Maybe<&2, String>
    case EmitterRequest_js_native_operation{_, _}: Maybe<&2, String>
    case EmitterRequest_js_native_operation_known{_, _}: Maybe<&2, String>
    case EmitterRequest_js_native_operation_name{_}: String
    case EmitterRequest_js_native_operation_chars{_, _}: List<&2, Char>
    case EmitterRequest_suffix_any{_, _, _}: Bool
    case EmitterRequest_js_native_u32{_}: Bool
    case EmitterRequest_js_native_u32_1{_}: Bool
    case EmitterRequest_js_native_u32_2{_}: Bool
    case EmitterRequest_js_native_f32{_}: Bool
    case EmitterRequest_js_native_f32_1{_}: Bool
    case EmitterRequest_js_native_f32_2{_}: Bool
    case EmitterRequest_js_native_f32_extra{_}: Bool
    case EmitterRequest_js_native_misc{_}: Bool
    case EmitterRequest_js_native_misc_1{_}: Bool
    case EmitterRequest_js_native_misc_2{_}: Bool
    case EmitterRequest_js_is_native{_}: Bool
    case EmitterRequest_js_native_primitive{_}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_shape{_}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_shape_match{_, _}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_binary{_}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_binary_match{_, _}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_indexed{_}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_indexed_match{_, _}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_position{_}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_position_match{_, _}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_unary{_}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_unary_match{_, _}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_text{_}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_text_match{_, _}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_binders{_}: Maybe<&2, Nat>
    case EmitterRequest_js_native_primitive_count{_, _}: Maybe<&2, Nat>
    case EmitterRequest_js_native_primitive_checked{_, _}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_arity{_, _}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_native_primitive_arity_match{_, _, _}: Maybe<&2, EmitPrimitive>
    case EmitterRequest_js_reference_old{_}: String
    case EmitterRequest_js_reference_2{_}: String
    case EmitterRequest_js_reference_3{_}: String
    case EmitterRequest_js_reference_4{_}: String
    case EmitterRequest_js_reference_5{_}: String
    case EmitterRequest_js_reference_6{_}: String
    case EmitterRequest_js_reference_7{_}: String
    case EmitterRequest_js_reference_8{_}: String
    case EmitterRequest_js_reference_nat_bounds{_}: String
    case EmitterRequest_js_reference_9{_}: String
    case EmitterRequest_js_reference_10{_}: String
    case EmitterRequest_js_reference_11{_}: String
    case EmitterRequest_js_reference_12{_}: String
    case EmitterRequest_js_reference_more{_}: String
    case EmitterRequest_js_ref_f32_extra{_}: String
    case EmitterRequest_js_ref_u32{_}: String
    case EmitterRequest_js_ref_u32_2{_}: String
    case EmitterRequest_js_ref_u32_3{_}: String
    case EmitterRequest_js_ref_f32{_}: String
    case EmitterRequest_js_ref_f32_2{_}: String
    case EmitterRequest_js_ref_f32_3{_}: String
    case EmitterRequest_js_ref_nat{_}: String
    case EmitterRequest_js_ref_strings{_}: String
    case EmitterRequest_js_ref_array{_}: String
    case EmitterRequest_js_term{_, _}: String
    case EmitterRequest_js_term_expected{_, _, _}: String

def emitter_result_group_3(request: EmitterRequestGroup3) -> Type:
  match request:
    case EmitterRequest_js_term_tail_expected{_, _, _}: String
    case EmitterRequest_js_statement_tail{_, _, _}: String
    case EmitterRequest_js_statement_local{_, _, _, _, _, _}: String
    case EmitterRequest_js_statement_match{_, _, _, _}: String
    case EmitterRequest_js_statement_result{_, _, _}: String
    case EmitterRequest_js_app_spine{_, _, _}: String
    case EmitterRequest_js_app_spine_result{_, _, _}: String
    case EmitterRequest_js_app_dispatch{_, _, _, _}: String
    case EmitterRequest_js_named_owner{_, _}: Maybe<&2, EmitNamed>
    case EmitterRequest_js_named_fallback{_, _, _}: Maybe<&2, EmitNamed>
    case EmitterRequest_js_named_lookup{_, _}: Maybe<&2, EmitNamed>
    case EmitterRequest_js_named_layouts{_, _, _}: Maybe<&2, EmitNamed>
    case EmitterRequest_js_named_next{_, _, _, _}: Maybe<&2, EmitNamed>
    case EmitterRequest_js_named_declarations{_, _, _}: Maybe<&2, EmitNamed>
    case EmitterRequest_js_named_native_law{_, _, _, _, _}: Maybe<&2, EmitNamed>
    case EmitterRequest_js_named_app{_, _, _, _}: String
    case EmitterRequest_js_named_app_found{_, _, _, _, _}: String
    case EmitterRequest_js_named_native_law_app{_, _, _, _, _, _, _}: String
    case EmitterRequest_js_named_app_native{_, _, _, _, _, _, _, _, _, _}: String
    case EmitterRequest_js_native_app_args{_, _, _, _, _}: String
    case EmitterRequest_js_named_app_eligible{_, _, _, _, _, _, _, _}: String
    case EmitterRequest_js_named_tail_selected{_, _, _, _}: String
    case EmitterRequest_js_named_tail{_, _}: String
    case EmitterRequest_js_named_app_args{_, _, _, _, _, _}: String
    case EmitterRequest_js_named_args{_, _, _, _}: Maybe<&2, List<&2, String>>
    case EmitterRequest_js_named_arg{_, _, _, _, _, _}: Maybe<&2, List<&2, String>>
    case EmitterRequest_js_app_spine_at{_, _}: AST.SyntaxTerm & List<&2, AST.SyntaxTerm>
    case EmitterRequest_js_app_chain_args{_, _, _, _}: String
    case EmitterRequest_js_app_chain{_, _, _, _}: String
    case EmitterRequest_js_app_arrow_env{_, _, _, _, _, _}: String
    case EmitterRequest_js_app_arrow{_, _, _, _, _}: String
    case EmitterRequest_js_app_quantity{_, _, _, _, _, _, _}: String
    case EmitterRequest_js_lambda{_, _, _, _}: String
    case EmitterRequest_js_lambda_view_env{_, _, _, _, _}: String
    case EmitterRequest_js_lambda_view{_, _, _, _}: String
    case EmitterRequest_js_binder_name{_, _}: String
    case EmitterRequest_js_lambda_untyped{_, _, _}: String
    case EmitterRequest_js_lambda_quantity{_, _, _, _, _}: String
    case EmitterRequest_js_closure{_, _}: String
    case EmitterRequest_env_depth{_}: Nat
    case EmitterRequest_env_reserve_names{_, _}: EmitEnv
    case EmitterRequest_js_term_sub{_, _, _, _, _}: String
    case EmitterRequest_js_term_let{_, _, _, _, _, _, _, _}: String
    case EmitterRequest_js_body_local{_, _, _, _, _, _}: String
    case EmitterRequest_js_body_local_constructor{_, _, _, _, _, _}: String
    case EmitterRequest_js_constructor{_, _, _, _}: String
    case EmitterRequest_js_constructor_literal{_, _, _, _, _, _}: String
    case EmitterRequest_js_native_word_literal{_, _, _, _}: Maybe<&2, String>
    case EmitterRequest_js_native_word_declared{_, _, _, _}: Maybe<&2, String>
    case EmitterRequest_js_word_literal_render{_, _}: Maybe<&2, String>
    case EmitterRequest_js_word_identity{_}: String
    case EmitterRequest_js_closed_word{_, _, _}: Maybe<&2, Nat>
    case EmitterRequest_js_closed_word_constructor{_, _, _, _}: Maybe<&2, Nat>
    case EmitterRequest_js_closed_bit{_, _}: Maybe<&2, Nat>
    case EmitterRequest_js_closed_bit_identity{_}: Maybe<&2, Nat>
    case EmitterRequest_js_closed_word_bit{_, _, _, _}: Maybe<&2, Nat>
    case EmitterRequest_js_closed_word_combine{_, _}: Maybe<&2, Nat>
    case EmitterRequest_js_string_literal{_, _, _, _, _}: String
    case EmitterRequest_js_string_literal_authorized{_, _, _, _, _, _}: String
    case EmitterRequest_js_string_literal_payload{_, _, _, _, _, _}: String
    case EmitterRequest_js_string_scalar_chars{_}: Maybe<&2, List<&2, Char>>
    case EmitterRequest_js_string_scalar_char{_, _, _}: Maybe<&2, List<&2, Char>>
    case EmitterRequest_js_string_scalar_cons{_, _}: Maybe<&2, List<&2, Char>>
    case EmitterRequest_js_string_names_native{_, _}: Bool

def emitter_result_group_4(request: EmitterRequestGroup4) -> Type:
  match request:
    case EmitterRequest_js_string_constructor_native{_, _, _}: Bool
    case EmitterRequest_js_string_constructor_schema{_, _, _}: Bool
    case EmitterRequest_js_string_schema_owner{_, _, _, _}: Bool
    case EmitterRequest_js_string_schema_global{_, _, _}: Bool
    case EmitterRequest_js_string_schema_decl{_, _, _}: Bool
    case EmitterRequest_js_string_schema_fields{_, _, _, _}: Bool
    case EmitterRequest_js_string_schema_nat{_, _, _}: Bool
    case EmitterRequest_js_string_schema_ref{_, _, _}: Bool
    case EmitterRequest_js_string_schema_key{_, _, _}: Bool
    case EmitterRequest_js_constructor_args{_, _, _}: List<&2, String>
    case EmitterRequest_js_constructor_arg_view_env{_, _, _, _, _}: List<&2, String>
    case EmitterRequest_js_constructor_arg_view{_, _, _, _}: List<&2, String>
    case EmitterRequest_js_constructor_arg_quantity{_, _, _, _}: String
    case EmitterRequest_js_constructor_native{_}: String
    case EmitterRequest_js_constructor_native_identity_found{_, _}: String
    case EmitterRequest_js_constructor_native_identity{_, _}: String
    case EmitterRequest_js_constructor_native_origin{_, _, _}: String
    case EmitterRequest_js_base_origin{_}: Bool
    case EmitterRequest_js_base_source_suffix{_, _}: Bool
    case EmitterRequest_js_base_source_exact{_, _, _}: Bool
    case EmitterRequest_js_base_source{_, _}: Bool
    case EmitterRequest_js_base_imported{_}: Bool
    case EmitterRequest_js_base_imported_next{_, _}: Bool
    case EmitterRequest_js_base_imports{_}: Bool
    case EmitterRequest_js_base_imports_next{_, _}: Bool
    case EmitterRequest_js_source_at{_, _}: String
    case EmitterRequest_js_sources{_}: String
    case EmitterRequest_js_constructor_render{_, _, _, _}: String
    case EmitterRequest_js_constructor_record{_, _, _}: String
    case EmitterRequest_js_constructor_record_exact{_, _}: String
    case EmitterRequest_js_constructor_record_fields{_, _}: Maybe<&2, String>
    case EmitterRequest_js_constructor_record_field{_, _, _}: Maybe<&2, String>
    case EmitterRequest_js_object_key{_}: String
    case EmitterRequest_ctor_short{_}: String
    case EmitterRequest_ctor_short_chars{_, _}: String
    case EmitterRequest_js_match{_, _, _, _}: String
    case EmitterRequest_pattern_test{_, _, _}: String
    case EmitterRequest_pattern_test_constructor{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_constructor_tagged{_, _, _, _, _, _, _}: String
    case EmitterRequest_pattern_test_native_literal{_, _, _, _, _, _, _}: String
    case EmitterRequest_pattern_test_native_bits{_, _, _}: String
    case EmitterRequest_js_native_word_pattern{_, _, _}: Maybe<&2, Nat>
    case EmitterRequest_js_closed_word_pattern{_, _, _}: Maybe<&2, Nat>
    case EmitterRequest_js_closed_word_pattern_constructor{_, _, _, _}: Maybe<&2, Nat>
    case EmitterRequest_js_closed_bit_pattern{_, _}: Maybe<&2, Nat>
    case EmitterRequest_js_closed_word_pattern_bit{_, _, _, _}: Maybe<&2, Nat>
    case EmitterRequest_js_field_projection{_, _}: String
    case EmitterRequest_pattern_decl_fields_test{_, _, _, _}: String
    case EmitterRequest_pattern_test_ctor{_, _, _, _}: String
    case EmitterRequest_pattern_test_true{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_false{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_zero{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_succ{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_snil{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_scon{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_u32{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_f32{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_aleaf{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_anode{_, _, _, _, _}: String
    case EmitterRequest_pattern_test_char{_, _, _, _, _}: String
    case EmitterRequest_pattern_fields_test{_, _, _, _, _}: String
    case EmitterRequest_patterns_test{_, _, _}: String
    case EmitterRequest_pattern_vars{_, _, _}: List<&2, String>
    case EmitterRequest_pattern_vars_constructor{_, _, _, _, _}: List<&2, String>

def emitter_result_group_5(request: EmitterRequestGroup5) -> Type:
  match request:
    case EmitterRequest_pattern_vars_constructor_tagged{_, _, _, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_erased_vars{_}: List<&2, String>
    case EmitterRequest_patterns_erased_vars{_}: List<&2, String>
    case EmitterRequest_pattern_decl_fields_vars{_, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_vars_ctr{_, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_vars_succ{_, _, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_vars_scon{_, _, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_vars_char{_, _, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_vars_u32{_, _, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_vars_f32{_, _, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_vars_aleaf{_, _, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_vars_anode{_, _, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_array_field_value{_, _}: String
    case EmitterRequest_pattern_array_fields{_, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_string_field_value{_, _}: String
    case EmitterRequest_pattern_string_fields{_, _, _, _}: List<&2, String>
    case EmitterRequest_pattern_fields_vars{_, _, _, _, _}: List<&2, String>
    case EmitterRequest_js_positional_projection{_, _, _}: String
    case EmitterRequest_patterns_vars{_, _, _}: List<&2, String>
    case EmitterRequest_js_case{_, _, _, _, _, _}: String
    case EmitterRequest_js_case_typed{_, _, _, _, _, _}: String
    case EmitterRequest_js_case_block_typed{_, _, _, _, _, _}: String
    case EmitterRequest_js_case_binding_names{_, _}: List<&2, String>
    case EmitterRequest_js_case_binding_name{_, _}: String
    case EmitterRequest_js_case_bindings{_, _}: String
    case EmitterRequest_js_case_binding_source{_, _, _, _}: String
    case EmitterRequest_js_cases{_, _, _, _, _}: String
    case EmitterRequest_js_switch_tags{_, _, _}: Maybe<&2, List<&2, String>>
    case EmitterRequest_js_switch_fields{_}: Bool
    case EmitterRequest_js_switch_tag_constructor{_, _, _, _}: Maybe<&2, List<&2, String>>
    case EmitterRequest_js_switch_tag_fields{_, _, _, _, _}: Maybe<&2, List<&2, String>>
    case EmitterRequest_js_switch_tag_seen{_, _, _, _, _}: Maybe<&2, List<&2, String>>
    case EmitterRequest_js_switch_tag_native{_, _, _, _, _}: Maybe<&2, List<&2, String>>
    case EmitterRequest_js_switch_tag_ordered{_, _, _, _, _}: Maybe<&2, List<&2, String>>
    case EmitterRequest_js_switch_bmp_tag{_}: Bool
    case EmitterRequest_js_switch_bmp_tail{_, _}: Bool
    case EmitterRequest_js_switch_tag_rest{_, _}: Maybe<&2, List<&2, String>>
    case EmitterRequest_js_switch_cases{_, _, _, _, _, _}: String
    case EmitterRequest_js_switch_pairs{_, _}: List<&2, EmitSwitchRow>
    case EmitterRequest_js_switch_row_le{_, _}: Bool
    case EmitterRequest_js_switch_sort{_, _}: List<&2, EmitSwitchRow>
    case EmitterRequest_js_switch_merge{_, _}: List<&2, EmitSwitchRow>
    case EmitterRequest_js_switch_merge_right{_, _, _}: List<&2, EmitSwitchRow>
    case EmitterRequest_js_switch_merge_order{_, _, _, _, _}: List<&2, EmitSwitchRow>
    case EmitterRequest_js_switch_tree{_, _, _, _, _, _, _}: String
    case EmitterRequest_js_switch_tree_leaf{_, _, _, _, _, _}: String
    case EmitterRequest_js_switch_tree_split{_, _, _, _, _, _, _, _, _}: String
    case EmitterRequest_js_cases_dispatch_size{_, _, _, _, _, _, _, _, _}: String
    case EmitterRequest_js_cases_dispatch_values{_, _, _, _, _}: String
    case EmitterRequest_js_cases_dispatch{_, _, _, _, _}: String
    case EmitterRequest_js_cases_dispatch_switch{_, _, _, _, _, _, _}: String
    case EmitterRequest_js_scrutinees{_, _, _}: String
    case EmitterRequest_scrutinee_names{_, _}: List<&2, String>
    case EmitterRequest_scrutinee_names_at{_, _}: List<&2, String>
    case EmitterRequest_js_body_match{_, _, _, _}: String
    case EmitterRequest_js_binders{_, _, _, _}: String
    case EmitterRequest_js_decl{_, _, _, _}: String
    case EmitterRequest_js_decl_term{_, _, _, _, _, _}: String
    case EmitterRequest_js_decl_term_operation{_, _, _, _, _, _}: String
    case EmitterRequest_js_named_eligible{_, _, _, _, _}: Bool
    case EmitterRequest_js_named_eligible_operation{_, _, _, _, _}: Bool
    case EmitterRequest_js_named_fixed{_, _}: Bool
    case EmitterRequest_js_decl_named{_, _, _, _, _, _}: String
    case EmitterRequest_js_named_body{_, _, _, _, _}: String

def emitter_result_group_6(request: EmitterRequestGroup6) -> Type:
  match request:
    case EmitterRequest_js_named_facade{_, _, _, _}: String
    case EmitterRequest_js_decl_native_law{_, _, _}: String
    case EmitterRequest_js_decl_native_value{_, _, _}: String
    case EmitterRequest_js_decl_native_runtime{_, _, _}: String
    case EmitterRequest_js_native_facade{_, _, _}: String
    case EmitterRequest_js_definition_has_live_binder{_}: Bool
    case EmitterRequest_js_decl_value{_, _, _}: String
    case EmitterRequest_js_decl_deferred_value{_, _}: String
    case EmitterRequest_js_definition_is_type{_, _, _, _}: Bool
    case EmitterRequest_js_inferred_is_sort{_}: Bool
    case EmitterRequest_js_type_is_sort{_}: Bool
    case EmitterRequest_js_live_binders{_}: Nat
    case EmitterRequest_js_foreign{_, _, _, _}: String
    case EmitterRequest_js_foreign_path{_, _, _, _, _, _}: String
    case EmitterRequest_js_decls{_, _, _, _}: String
    case EmitterRequest_alias_namespace{_, _, _}: String
    case EmitterRequest_alias_namespace_base{_, _, _, _}: String
    case EmitterRequest_alias_namespace_found{_}: String
    case EmitterRequest_js_resolved_alias_entries{_, _}: List<&2, EmitAlias>
    case EmitterRequest_js_resolved_aliases{_, _, _}: EmitAliases
    case EmitterRequest_js_aliases{_}: String
    case EmitterRequest_js_alias_source{_}: String
    case EmitterRequest_js_alias_entries{_}: String
    case EmitterRequest_js_module{_, _, _, _}: String
    case EmitterRequest_js_modules{_, _}: String
    case EmitterRequest_js_modules_at{_, _, _}: String
    case EmitterRequest_qualify{_, _}: String
    case EmitterRequest_qualify_result{_, _, _}: String
    case EmitterRequest_first_span{_, _}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_terms{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_term{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_optional_term{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_def_body{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_decl{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_binders{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_constructors{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_condition{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_clauses{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_decls{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_error_modules{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_terms{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_term{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_binders{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_constructors{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_condition{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_clauses{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_optional_term{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_def_body{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_decl{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_decls{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_template_modules{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_has_js_import{_}: Bool
    case EmitterRequest_foreign_error_decl{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_foreign_error_js{_, _}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_foreign_error_decls{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_foreign_error_modules{_}: Maybe<&2, AST.SourceSpan>
    case EmitterRequest_js_runtime{}: String
    case EmitterRequest_js_runtime_extra{}: String
    case EmitterRequest_js_runtime_array{}: String
    case EmitterRequest_js_runtime_foreign{}: String
    case EmitterRequest_js_runtime_namespace{}: String
    case EmitterRequest_js_runtime_field_names{_}: String
    case EmitterRequest_js_runtime_field_names_at{_, _}: String
    case EmitterRequest_js_constructor_fields_one{_, _, _, _}: String

def emitter_result_group_7(request: EmitterRequestGroup7) -> Type:
  match request:
    case EmitterRequest_js_constructor_fields_constructors{_, _, _, _}: String
    case EmitterRequest_js_constructor_fields_decl{_, _, _}: String
    case EmitterRequest_js_constructor_fields_decls{_, _, _}: String
    case EmitterRequest_js_constructor_fields_modules{_}: String
    case EmitterRequest_js_constructor_fields_modules_at{_, _}: String
    case EmitterRequest_js_type_ref{_, _, _, _}: String
    case EmitterRequest_js_type_args{_, _, _, _}: String
    case EmitterRequest_js_type_sugar_descriptor{_, _, _, _, _, _}: String
    case EmitterRequest_js_type_sugar{_, _, _, _, _}: String
    case EmitterRequest_js_type_term{_, _, _}: String
    case EmitterRequest_js_type_quantity{_}: String
    case EmitterRequest_js_type_optional_quantity{_}: String
    case EmitterRequest_js_type_binary{_, _, _, _, _, _}: String
    case EmitterRequest_js_type_constructor{_, _, _, _}: String
    case EmitterRequest_js_type_application{_, _, _}: String
    case EmitterRequest_js_type_application_args{_, _, _, _}: String
    case EmitterRequest_js_type_let{_, _, _, _}: String
    case EmitterRequest_js_type_patterns_source{_, _, _, _}: String
    case EmitterRequest_js_type_pattern_source{_, _, _}: String
    case EmitterRequest_js_type_cases_source{_, _, _, _}: String
    case EmitterRequest_js_type_field_terms{_, _, _, _}: String
    case EmitterRequest_js_type_arm{_, _, _}: String
    case EmitterRequest_js_type_field_quantities{_, _}: String
    case EmitterRequest_js_type_arms{_, _, _, _}: String
    case EmitterRequest_js_type_decl{_, _, _, _}: String
    case EmitterRequest_js_type_native_marker{_, _}: String
    case EmitterRequest_js_type_decls{_, _, _, _}: String
    case EmitterRequest_js_type_modules{_, _}: String
    case EmitterRequest_js_type_modules_needed{_, _, _}: String
    case EmitterRequest_js_type_modules_at{_, _, _}: String
    case EmitterRequest_js_type_needed_ref{_, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_found{_, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_definition{_, _, _, _, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_terms{_, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_term{_, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_binders{_, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_result{_, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_constructors{_, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_declarations{_, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_definition_root{_, _, _, _, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_definition_root_kind{_, _, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_modules{_, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_needed_modules_at{_, _, _, _}: EmitTypeNeeded
    case EmitterRequest_js_type_function_sources{_}: String
    case EmitterRequest_main_type_expr_declaration{_, _, _}: String
    case EmitterRequest_main_type_expr_is_main{_, _, _, _}: String
    case EmitterRequest_main_type_expr_declarations{_, _, _}: String
    case EmitterRequest_main_type_expr_declaration_result{_, _, _, _}: String
    case EmitterRequest_main_type_expr_declaration_empty{_, _, _, _, _}: String
    case EmitterRequest_main_type_expr_modules{_, _}: String
    case EmitterRequest_main_type_expr_modules_at{_, _}: String
    case EmitterRequest_main_type_expr_module_scope{_, _, _, _, _, _}: String
    case EmitterRequest_main_type_expr_module_result{_, _, _}: String
    case EmitterRequest_main_type_expr_module_empty{_, _, _, _}: String
    case EmitterRequest_js_runtime_cli{}: String
    case EmitterRequest_js_runtime_io{}: String
    case EmitterRequest_js_runtime_show{}: String
    case EmitterRequest_js_runtime_type{}: String
    case EmitterRequest_js_runtime_type_names{}: String
    case EmitterRequest_js_runtime_type_patterns{}: String
    case EmitterRequest_js_runtime_type_eval{}: String
    case EmitterRequest_js_runtime_native_type{}: String
    case EmitterRequest_js_main{_}: String
    case EmitterRequest_emit{_}: EmitResult

def emitter_result_group_8(request: EmitterRequestGroup8) -> Type:
  match request:
    case EmitterRequest_js_emit_template{_, _, _}: EmitResult
    case EmitterRequest_js_emit_holes{_, _, _}: EmitResult
    case EmitterRequest_js_emit_foreign{_, _, _}: EmitResult
    case EmitterRequest_js_library_exports{_}: String
    case EmitterRequest_js_library_export_fields{_}: String
    case EmitterRequest_emit_library{_, _}: EmitResult
    case EmitterRequest_js_emit_ending{_, _, _}: String

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

def emitter_resume_type_group_0(-B: Type, request: EmitterRequestGroup0) -> Type:
  match request:
    case EmitterRequest_js_value_indices{_}: (@+value: EmitCatalog -> B)
    case EmitterRequest_js_catalog{_}: (@+value: EmitCatalog -> B)
    case EmitterRequest_js_catalog_at{_, _}: (@+value: EmitCatalog -> B)
    case EmitterRequest_js_catalog_module{_, _}: (@+value: EmitCatalog -> B)
    case EmitterRequest_js_catalog_values{_, _, _}: (@+value: Map<&2, EmitModuleIndex> -> B)
    case EmitterRequest_js_catalog_constructors{_, _, _}: (@+value: Map<&2, EmitModuleIndex> -> B)
    case EmitterRequest_js_catalog_types{_, _, _}: (@+value: Map<&2, List<&2, EmitModuleIndex>> -> B)
    case EmitterRequest_js_catalog_type_insert{_, _, _, _}: (@+value: Map<&2, List<&2, EmitModuleIndex>> -> B)
    case EmitterRequest_js_catalog_layouts{_}: (@+value: List<&2, EmitModuleIndex> -> B)
    case EmitterRequest_js_namespace_indices{_}: (@+value: Map<&2, String> -> B)
    case EmitterRequest_js_value_indices_at{_, _, _}: (@+value: List<&2, EmitModuleIndex> -> B)
    case EmitterRequest_js_value_declarations{_, _}: (@+value: Map<&2, AST.Definition> -> B)
    case EmitterRequest_js_value_declaration{_, _, _}: (@+value: Map<&2, AST.Definition> -> B)
    case EmitterRequest_js_constructor_indices{_, _}: (@+value: Map<&2, EmitConstructorOwner> -> B)
    case EmitterRequest_js_constructor_index_family{_, _, _}: (@+value: Map<&2, EmitConstructorOwner> -> B)
    case EmitterRequest_js_constructor_index_items{_, _, _, _}: (@+value: Map<&2, EmitConstructorOwner> -> B)
    case EmitterRequest_js_type_indices{_, _}: (@+value: Map<&2, List<&2, AST.TopLevel>> -> B)
    case EmitterRequest_js_type_index_declaration{_, _, _}: (@+value: Map<&2, List<&2, AST.TopLevel>> -> B)
    case EmitterRequest_js_type_index_insert{_, _, _}: (@+value: Map<&2, List<&2, AST.TopLevel>> -> B)
    case EmitterRequest_js_type_index_found{_, _, _, _}: (@+value: Map<&2, List<&2, AST.TopLevel>> -> B)
    case EmitterRequest_js_escape_char{_}: (@+value: String -> B)
    case EmitterRequest_js_comma_prefix{_}: (@+value: String -> B)
    case EmitterRequest_js_quote_chars{_, _}: (@+value: String -> B)
    case EmitterRequest_js_quote{_}: (@+value: String -> B)
    case EmitterRequest_js_named_identifier_char{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_identifier_chars{_, _}: (@+value: String -> B)
    case EmitterRequest_js_named_identifier{_}: (@+value: String -> B)
    case EmitterRequest_env_binding{_, _}: (@+value: Maybe<&2, EmitBinding> -> B)
    case EmitterRequest_env_binding_at{_, _, _, _}: (@+value: Maybe<&2, EmitBinding> -> B)
    case EmitterRequest_env_at_binding{_}: (@+value: String -> B)
    case EmitterRequest_env_at{_, _}: (@+value: String -> B)
    case EmitterRequest_env_bind{_, _, _, _}: (@+value: EmitEnv -> B)
    case EmitterRequest_env_push{_, _}: (@+value: EmitEnv -> B)
    case EmitterRequest_js_close{_, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_close_inferred{_, _, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_close_declared{_, _, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_close_definition{_, _, _, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_closure_env{_}: (@+value: EmitEnv -> B)
    case EmitterRequest_js_scope_key{_, _}: (@+value: String -> B)
    case EmitterRequest_js_scope_alias{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_scope_alias_match{_, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_global{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_fallback{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_lookup{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_owner{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_owner_env{_, _}: (@+value: EmitEnv -> B)
    case EmitterRequest_js_global_definition{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_type{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_type_fallback{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_type_lookup{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_type_owners{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_type_modules{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_type_next{_, _, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_type_index{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_type_decls{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_type_definition{_, _, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_global_native_law_operation{_, _, _, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_native_law_type{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_native_law_binders{_, _}: (@+value: Maybe<&2, List<&2, AST.TelescopeItem>> -> B)
    case EmitterRequest_js_native_law_binder{_, _}: (@+value: Maybe<&2, List<&2, AST.TelescopeItem>> -> B)
    case EmitterRequest_js_type_definition{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_reduce_env{_, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_reduce{_}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_reduce_inferred{_, _}: (@+value: EmitClosure -> B)

def emitter_resume_type_group_1(-B: Type, request: EmitterRequestGroup1) -> Type:
  match request:
    case EmitterRequest_js_reduce_binding{_, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_reduce_global{_, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_reduce_app_env{_, _, _, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_reduce_app{_, _, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_reduce_patterns{_, _, _}: (@+value: EmitPatternResult -> B)
    case EmitterRequest_js_reduce_patterns_next{_, _, _}: (@+value: EmitPatternResult -> B)
    case EmitterRequest_js_reduce_pattern{_, _, _}: (@+value: EmitPatternResult -> B)
    case EmitterRequest_js_reduce_pattern_view_env{_, _, _, _, _}: (@+value: EmitPatternResult -> B)
    case EmitterRequest_js_reduce_pattern_view{_, _, _, _}: (@+value: EmitPatternResult -> B)
    case EmitterRequest_js_same_scoped_key{_, _, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_same_constructor_key{_, _}: (@+value: Bool -> B)
    case EmitterRequest_js_reduce_pattern_key{_, _, _, _}: (@+value: EmitPatternResult -> B)
    case EmitterRequest_js_reduce_local{_, _, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_reduce_cases{_, _, _, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_reduce_case_result{_, _, _, _, _, _}: (@+value: EmitClosure -> B)
    case EmitterRequest_js_value_env{_, _}: (@+value: EmitEnv -> B)
    case EmitterRequest_js_value_env_at{_, _, _}: (@+value: EmitEnv -> B)
    case EmitterRequest_js_type{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_binding_type{_}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_type_value{_}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_type_local{_, _, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_type_local_refined{_, _, _, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_apply_type_args{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_apply_type{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_apply_type_view_env{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_apply_type_view{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_type_cases{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_env_insert_binding{_, _, _}: (@+value: EmitEnv -> B)
    case EmitterRequest_env_insert_names{_, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_env_insert_closures{_, _, _}: (@+value: List<&2, Maybe<&2, EmitClosure>> -> B)
    case EmitterRequest_env_names_typed{_, _, _}: (@+value: EmitEnv -> B)
    case EmitterRequest_js_scrutinee_types{_, _}: (@+value: List<&2, Maybe<&2, EmitClosure>> -> B)
    case EmitterRequest_js_pattern_types{_, _, _}: (@+value: List<&2, Maybe<&2, EmitClosure>> -> B)
    case EmitterRequest_js_pattern_type{_, _, _}: (@+value: List<&2, Maybe<&2, EmitClosure>> -> B)
    case EmitterRequest_js_field_types{_}: (@+value: List<&2, Maybe<&2, EmitClosure>> -> B)
    case EmitterRequest_js_field_types_view_env{_, _}: (@+value: List<&2, Maybe<&2, EmitClosure>> -> B)
    case EmitterRequest_js_field_types_view{_}: (@+value: List<&2, Maybe<&2, EmitClosure>> -> B)
    case EmitterRequest_js_constructor_decl{_, _}: (@+value: Maybe<&2, EmitConstructor> -> B)
    case EmitterRequest_js_constructor_decl_fallback{_, _, _}: (@+value: Maybe<&2, EmitConstructor> -> B)
    case EmitterRequest_js_constructor_lookup{_, _}: (@+value: Maybe<&2, EmitConstructor> -> B)
    case EmitterRequest_js_constructor_index_owner{_, _, _}: (@+value: Maybe<&2, EmitConstructor> -> B)
    case EmitterRequest_js_constructor_owner{_, _, _}: (@+value: Maybe<&2, EmitConstructor> -> B)
    case EmitterRequest_js_constructor_signature{_, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_constructor_signature_found{_, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_family_parameter_arguments{_, _}: (@+value: List<&2, EmitClosure> -> B)
    case EmitterRequest_js_family_parameter_view_env{_, _, _}: (@+value: List<&2, EmitClosure> -> B)
    case EmitterRequest_js_family_parameter_view{_, _}: (@+value: List<&2, EmitClosure> -> B)
    case EmitterRequest_js_family_arguments_view_env{_, _}: (@+value: List<&2, EmitClosure> -> B)
    case EmitterRequest_js_family_arguments_view{_}: (@+value: List<&2, EmitClosure> -> B)
    case EmitterRequest_js_family_fill_arguments{_, _, _, _, _}: (@+value: List<&2, EmitClosure> -> B)
    case EmitterRequest_js_family_quant_prefix{_, _}: (@+value: Nat -> B)
    case EmitterRequest_js_family_quant_domain{_, _, _}: (@+value: Nat -> B)
    case EmitterRequest_js_family_fill_missing{_, _, _, _, _, _}: (@+value: List<&2, EmitClosure> -> B)
    case EmitterRequest_js_quantity_closures{_, _, _, _}: (@+value: List<&2, EmitClosure> -> B)
    case EmitterRequest_js_family_promote_arguments{_, _, _, _}: (@+value: List<&2, EmitClosure> -> B)
    case EmitterRequest_js_closure_terms{_, _}: (@+value: List<&2, EmitClosure> -> B)
    case EmitterRequest_js_constructor_parameter_types{_, _, _, _}: (@+value: Maybe<&2, EmitClosure> -> B)
    case EmitterRequest_js_choose{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_key_matches{_, _}: (@+value: Bool -> B)
    case EmitterRequest_js_choose_exact{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_choose_result{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_reference{_}: (@+value: String -> B)
    case EmitterRequest_js_native_operations{_, _, _}: (@+value: Map<&2, String> -> B)
    case EmitterRequest_js_native_operation_declarations{_, _}: (@+value: Map<&2, String> -> B)

def emitter_resume_type_group_2(-B: Type, request: EmitterRequestGroup2) -> Type:
  match request:
    case EmitterRequest_js_native_operation_insert_keys{_, _, _}: (@+value: Map<&2, String> -> B)
    case EmitterRequest_js_native_operation_insert{_, _}: (@+value: Map<&2, String> -> B)
    case EmitterRequest_js_native_operation_insert_found{_, _, _}: (@+value: Map<&2, String> -> B)
    case EmitterRequest_js_native_operation_origin{_, _}: (@+value: Maybe<&2, String> -> B)
    case EmitterRequest_js_native_operation{_, _}: (@+value: Maybe<&2, String> -> B)
    case EmitterRequest_js_native_operation_known{_, _}: (@+value: Maybe<&2, String> -> B)
    case EmitterRequest_js_native_operation_name{_}: (@+value: String -> B)
    case EmitterRequest_js_native_operation_chars{_, _}: (@+value: List<&2, Char> -> B)
    case EmitterRequest_suffix_any{_, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_native_u32{_}: (@+value: Bool -> B)
    case EmitterRequest_js_native_u32_1{_}: (@+value: Bool -> B)
    case EmitterRequest_js_native_u32_2{_}: (@+value: Bool -> B)
    case EmitterRequest_js_native_f32{_}: (@+value: Bool -> B)
    case EmitterRequest_js_native_f32_1{_}: (@+value: Bool -> B)
    case EmitterRequest_js_native_f32_2{_}: (@+value: Bool -> B)
    case EmitterRequest_js_native_f32_extra{_}: (@+value: Bool -> B)
    case EmitterRequest_js_native_misc{_}: (@+value: Bool -> B)
    case EmitterRequest_js_native_misc_1{_}: (@+value: Bool -> B)
    case EmitterRequest_js_native_misc_2{_}: (@+value: Bool -> B)
    case EmitterRequest_js_is_native{_}: (@+value: Bool -> B)
    case EmitterRequest_js_native_primitive{_}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_shape{_}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_shape_match{_, _}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_binary{_}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_binary_match{_, _}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_indexed{_}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_indexed_match{_, _}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_position{_}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_position_match{_, _}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_unary{_}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_unary_match{_, _}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_text{_}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_text_match{_, _}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_binders{_}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_native_primitive_count{_, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_native_primitive_checked{_, _}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_arity{_, _}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_native_primitive_arity_match{_, _, _}: (@+value: Maybe<&2, EmitPrimitive> -> B)
    case EmitterRequest_js_reference_old{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_2{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_3{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_4{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_5{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_6{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_7{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_8{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_nat_bounds{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_9{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_10{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_11{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_12{_}: (@+value: String -> B)
    case EmitterRequest_js_reference_more{_}: (@+value: String -> B)
    case EmitterRequest_js_ref_f32_extra{_}: (@+value: String -> B)
    case EmitterRequest_js_ref_u32{_}: (@+value: String -> B)
    case EmitterRequest_js_ref_u32_2{_}: (@+value: String -> B)
    case EmitterRequest_js_ref_u32_3{_}: (@+value: String -> B)
    case EmitterRequest_js_ref_f32{_}: (@+value: String -> B)
    case EmitterRequest_js_ref_f32_2{_}: (@+value: String -> B)
    case EmitterRequest_js_ref_f32_3{_}: (@+value: String -> B)
    case EmitterRequest_js_ref_nat{_}: (@+value: String -> B)
    case EmitterRequest_js_ref_strings{_}: (@+value: String -> B)
    case EmitterRequest_js_ref_array{_}: (@+value: String -> B)
    case EmitterRequest_js_term{_, _}: (@+value: String -> B)
    case EmitterRequest_js_term_expected{_, _, _}: (@+value: String -> B)

def emitter_resume_type_group_3(-B: Type, request: EmitterRequestGroup3) -> Type:
  match request:
    case EmitterRequest_js_term_tail_expected{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_statement_tail{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_statement_local{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_statement_match{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_statement_result{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_app_spine{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_app_spine_result{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_app_dispatch{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_owner{_, _}: (@+value: Maybe<&2, EmitNamed> -> B)
    case EmitterRequest_js_named_fallback{_, _, _}: (@+value: Maybe<&2, EmitNamed> -> B)
    case EmitterRequest_js_named_lookup{_, _}: (@+value: Maybe<&2, EmitNamed> -> B)
    case EmitterRequest_js_named_layouts{_, _, _}: (@+value: Maybe<&2, EmitNamed> -> B)
    case EmitterRequest_js_named_next{_, _, _, _}: (@+value: Maybe<&2, EmitNamed> -> B)
    case EmitterRequest_js_named_declarations{_, _, _}: (@+value: Maybe<&2, EmitNamed> -> B)
    case EmitterRequest_js_named_native_law{_, _, _, _, _}: (@+value: Maybe<&2, EmitNamed> -> B)
    case EmitterRequest_js_named_app{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_app_found{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_native_law_app{_, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_app_native{_, _, _, _, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_native_app_args{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_app_eligible{_, _, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_tail_selected{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_tail{_, _}: (@+value: String -> B)
    case EmitterRequest_js_named_app_args{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_args{_, _, _, _}: (@+value: Maybe<&2, List<&2, String>> -> B)
    case EmitterRequest_js_named_arg{_, _, _, _, _, _}: (@+value: Maybe<&2, List<&2, String>> -> B)
    case EmitterRequest_js_app_spine_at{_, _}: (@value: AST.SyntaxTerm & List<&2, AST.SyntaxTerm> -> B)
    case EmitterRequest_js_app_chain_args{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_app_chain{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_app_arrow_env{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_app_arrow{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_app_quantity{_, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_lambda{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_lambda_view_env{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_lambda_view{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_binder_name{_, _}: (@+value: String -> B)
    case EmitterRequest_js_lambda_untyped{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_lambda_quantity{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_closure{_, _}: (@+value: String -> B)
    case EmitterRequest_env_depth{_}: (@+value: Nat -> B)
    case EmitterRequest_env_reserve_names{_, _}: (@+value: EmitEnv -> B)
    case EmitterRequest_js_term_sub{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_term_let{_, _, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_body_local{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_body_local_constructor{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_literal{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_native_word_literal{_, _, _, _}: (@+value: Maybe<&2, String> -> B)
    case EmitterRequest_js_native_word_declared{_, _, _, _}: (@+value: Maybe<&2, String> -> B)
    case EmitterRequest_js_word_literal_render{_, _}: (@+value: Maybe<&2, String> -> B)
    case EmitterRequest_js_word_identity{_}: (@+value: String -> B)
    case EmitterRequest_js_closed_word{_, _, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_closed_word_constructor{_, _, _, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_closed_bit{_, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_closed_bit_identity{_}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_closed_word_bit{_, _, _, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_closed_word_combine{_, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_string_literal{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_string_literal_authorized{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_string_literal_payload{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_string_scalar_chars{_}: (@+value: Maybe<&2, List<&2, Char>> -> B)
    case EmitterRequest_js_string_scalar_char{_, _, _}: (@+value: Maybe<&2, List<&2, Char>> -> B)
    case EmitterRequest_js_string_scalar_cons{_, _}: (@+value: Maybe<&2, List<&2, Char>> -> B)
    case EmitterRequest_js_string_names_native{_, _}: (@+value: Bool -> B)

def emitter_resume_type_group_4(-B: Type, request: EmitterRequestGroup4) -> Type:
  match request:
    case EmitterRequest_js_string_constructor_native{_, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_string_constructor_schema{_, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_string_schema_owner{_, _, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_string_schema_global{_, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_string_schema_decl{_, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_string_schema_fields{_, _, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_string_schema_nat{_, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_string_schema_ref{_, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_string_schema_key{_, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_constructor_args{_, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_js_constructor_arg_view_env{_, _, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_js_constructor_arg_view{_, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_js_constructor_arg_quantity{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_native{_}: (@+value: String -> B)
    case EmitterRequest_js_constructor_native_identity_found{_, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_native_identity{_, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_native_origin{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_base_origin{_}: (@+value: Bool -> B)
    case EmitterRequest_js_base_source_suffix{_, _}: (@+value: Bool -> B)
    case EmitterRequest_js_base_source_exact{_, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_base_source{_, _}: (@+value: Bool -> B)
    case EmitterRequest_js_base_imported{_}: (@+value: Bool -> B)
    case EmitterRequest_js_base_imported_next{_, _}: (@+value: Bool -> B)
    case EmitterRequest_js_base_imports{_}: (@+value: Bool -> B)
    case EmitterRequest_js_base_imports_next{_, _}: (@+value: Bool -> B)
    case EmitterRequest_js_source_at{_, _}: (@+value: String -> B)
    case EmitterRequest_js_sources{_}: (@+value: String -> B)
    case EmitterRequest_js_constructor_render{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_record{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_record_exact{_, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_record_fields{_, _}: (@+value: Maybe<&2, String> -> B)
    case EmitterRequest_js_constructor_record_field{_, _, _}: (@+value: Maybe<&2, String> -> B)
    case EmitterRequest_js_object_key{_}: (@+value: String -> B)
    case EmitterRequest_ctor_short{_}: (@+value: String -> B)
    case EmitterRequest_ctor_short_chars{_, _}: (@+value: String -> B)
    case EmitterRequest_js_match{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test{_, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_constructor{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_constructor_tagged{_, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_native_literal{_, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_native_bits{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_native_word_pattern{_, _, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_closed_word_pattern{_, _, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_closed_word_pattern_constructor{_, _, _, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_closed_bit_pattern{_, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_closed_word_pattern_bit{_, _, _, _}: (@+value: Maybe<&2, Nat> -> B)
    case EmitterRequest_js_field_projection{_, _}: (@+value: String -> B)
    case EmitterRequest_pattern_decl_fields_test{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_ctor{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_true{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_false{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_zero{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_succ{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_snil{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_scon{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_u32{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_f32{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_aleaf{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_anode{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_test_char{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_fields_test{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_patterns_test{_, _, _}: (@+value: String -> B)
    case EmitterRequest_pattern_vars{_, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_vars_constructor{_, _, _, _, _}: (@+value: List<&2, String> -> B)

def emitter_resume_type_group_5(-B: Type, request: EmitterRequestGroup5) -> Type:
  match request:
    case EmitterRequest_pattern_vars_constructor_tagged{_, _, _, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_erased_vars{_}: (@+value: List<&2, String> -> B)
    case EmitterRequest_patterns_erased_vars{_}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_decl_fields_vars{_, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_vars_ctr{_, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_vars_succ{_, _, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_vars_scon{_, _, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_vars_char{_, _, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_vars_u32{_, _, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_vars_f32{_, _, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_vars_aleaf{_, _, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_vars_anode{_, _, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_array_field_value{_, _}: (@+value: String -> B)
    case EmitterRequest_pattern_array_fields{_, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_string_field_value{_, _}: (@+value: String -> B)
    case EmitterRequest_pattern_string_fields{_, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_pattern_fields_vars{_, _, _, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_js_positional_projection{_, _, _}: (@+value: String -> B)
    case EmitterRequest_patterns_vars{_, _, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_js_case{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_case_typed{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_case_block_typed{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_case_binding_names{_, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_js_case_binding_name{_, _}: (@+value: String -> B)
    case EmitterRequest_js_case_bindings{_, _}: (@+value: String -> B)
    case EmitterRequest_js_case_binding_source{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_cases{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_switch_tags{_, _, _}: (@+value: Maybe<&2, List<&2, String>> -> B)
    case EmitterRequest_js_switch_fields{_}: (@+value: Bool -> B)
    case EmitterRequest_js_switch_tag_constructor{_, _, _, _}: (@+value: Maybe<&2, List<&2, String>> -> B)
    case EmitterRequest_js_switch_tag_fields{_, _, _, _, _}: (@+value: Maybe<&2, List<&2, String>> -> B)
    case EmitterRequest_js_switch_tag_seen{_, _, _, _, _}: (@+value: Maybe<&2, List<&2, String>> -> B)
    case EmitterRequest_js_switch_tag_native{_, _, _, _, _}: (@+value: Maybe<&2, List<&2, String>> -> B)
    case EmitterRequest_js_switch_tag_ordered{_, _, _, _, _}: (@+value: Maybe<&2, List<&2, String>> -> B)
    case EmitterRequest_js_switch_bmp_tag{_}: (@+value: Bool -> B)
    case EmitterRequest_js_switch_bmp_tail{_, _}: (@+value: Bool -> B)
    case EmitterRequest_js_switch_tag_rest{_, _}: (@+value: Maybe<&2, List<&2, String>> -> B)
    case EmitterRequest_js_switch_cases{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_switch_pairs{_, _}: (@+value: List<&2, EmitSwitchRow> -> B)
    case EmitterRequest_js_switch_row_le{_, _}: (@+value: Bool -> B)
    case EmitterRequest_js_switch_sort{_, _}: (@+value: List<&2, EmitSwitchRow> -> B)
    case EmitterRequest_js_switch_merge{_, _}: (@+value: List<&2, EmitSwitchRow> -> B)
    case EmitterRequest_js_switch_merge_right{_, _, _}: (@+value: List<&2, EmitSwitchRow> -> B)
    case EmitterRequest_js_switch_merge_order{_, _, _, _, _}: (@+value: List<&2, EmitSwitchRow> -> B)
    case EmitterRequest_js_switch_tree{_, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_switch_tree_leaf{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_switch_tree_split{_, _, _, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_cases_dispatch_size{_, _, _, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_cases_dispatch_values{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_cases_dispatch{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_cases_dispatch_switch{_, _, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_scrutinees{_, _, _}: (@+value: String -> B)
    case EmitterRequest_scrutinee_names{_, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_scrutinee_names_at{_, _}: (@+value: List<&2, String> -> B)
    case EmitterRequest_js_body_match{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_binders{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_decl{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_decl_term{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_decl_term_operation{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_eligible{_, _, _, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_named_eligible_operation{_, _, _, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_named_fixed{_, _}: (@+value: Bool -> B)
    case EmitterRequest_js_decl_named{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_named_body{_, _, _, _, _}: (@+value: String -> B)

def emitter_resume_type_group_6(-B: Type, request: EmitterRequestGroup6) -> Type:
  match request:
    case EmitterRequest_js_named_facade{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_decl_native_law{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_decl_native_value{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_decl_native_runtime{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_native_facade{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_definition_has_live_binder{_}: (@+value: Bool -> B)
    case EmitterRequest_js_decl_value{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_decl_deferred_value{_, _}: (@+value: String -> B)
    case EmitterRequest_js_definition_is_type{_, _, _, _}: (@+value: Bool -> B)
    case EmitterRequest_js_inferred_is_sort{_}: (@+value: Bool -> B)
    case EmitterRequest_js_type_is_sort{_}: (@+value: Bool -> B)
    case EmitterRequest_js_live_binders{_}: (@+value: Nat -> B)
    case EmitterRequest_js_foreign{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_foreign_path{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_decls{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_alias_namespace{_, _, _}: (@+value: String -> B)
    case EmitterRequest_alias_namespace_base{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_alias_namespace_found{_}: (@+value: String -> B)
    case EmitterRequest_js_resolved_alias_entries{_, _}: (@+value: List<&2, EmitAlias> -> B)
    case EmitterRequest_js_resolved_aliases{_, _, _}: (@+value: EmitAliases -> B)
    case EmitterRequest_js_aliases{_}: (@+value: String -> B)
    case EmitterRequest_js_alias_source{_}: (@+value: String -> B)
    case EmitterRequest_js_alias_entries{_}: (@+value: String -> B)
    case EmitterRequest_js_module{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_modules{_, _}: (@+value: String -> B)
    case EmitterRequest_js_modules_at{_, _, _}: (@+value: String -> B)
    case EmitterRequest_qualify{_, _}: (@+value: String -> B)
    case EmitterRequest_qualify_result{_, _, _}: (@+value: String -> B)
    case EmitterRequest_first_span{_, _}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_terms{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_term{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_optional_term{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_def_body{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_decl{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_binders{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_constructors{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_condition{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_clauses{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_decls{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_error_modules{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_terms{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_term{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_binders{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_constructors{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_condition{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_clauses{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_optional_term{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_def_body{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_decl{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_decls{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_template_modules{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_has_js_import{_}: (@+value: Bool -> B)
    case EmitterRequest_foreign_error_decl{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_foreign_error_js{_, _}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_foreign_error_decls{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_foreign_error_modules{_}: (@+value: Maybe<&2, AST.SourceSpan> -> B)
    case EmitterRequest_js_runtime{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_extra{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_array{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_foreign{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_namespace{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_field_names{_}: (@+value: String -> B)
    case EmitterRequest_js_runtime_field_names_at{_, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_fields_one{_, _, _, _}: (@+value: String -> B)

def emitter_resume_type_group_7(-B: Type, request: EmitterRequestGroup7) -> Type:
  match request:
    case EmitterRequest_js_constructor_fields_constructors{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_fields_decl{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_fields_decls{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_constructor_fields_modules{_}: (@+value: String -> B)
    case EmitterRequest_js_constructor_fields_modules_at{_, _}: (@+value: String -> B)
    case EmitterRequest_js_type_ref{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_args{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_sugar_descriptor{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_sugar{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_term{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_quantity{_}: (@+value: String -> B)
    case EmitterRequest_js_type_optional_quantity{_}: (@+value: String -> B)
    case EmitterRequest_js_type_binary{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_constructor{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_application{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_application_args{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_let{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_patterns_source{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_pattern_source{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_cases_source{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_field_terms{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_arm{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_field_quantities{_, _}: (@+value: String -> B)
    case EmitterRequest_js_type_arms{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_decl{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_native_marker{_, _}: (@+value: String -> B)
    case EmitterRequest_js_type_decls{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_modules{_, _}: (@+value: String -> B)
    case EmitterRequest_js_type_modules_needed{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_modules_at{_, _, _}: (@+value: String -> B)
    case EmitterRequest_js_type_needed_ref{_, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_found{_, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_definition{_, _, _, _, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_terms{_, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_term{_, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_binders{_, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_result{_, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_constructors{_, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_declarations{_, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_definition_root{_, _, _, _, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_definition_root_kind{_, _, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_modules{_, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_needed_modules_at{_, _, _, _}: (@+value: EmitTypeNeeded -> B)
    case EmitterRequest_js_type_function_sources{_}: (@+value: String -> B)
    case EmitterRequest_main_type_expr_declaration{_, _, _}: (@+value: String -> B)
    case EmitterRequest_main_type_expr_is_main{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_main_type_expr_declarations{_, _, _}: (@+value: String -> B)
    case EmitterRequest_main_type_expr_declaration_result{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_main_type_expr_declaration_empty{_, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_main_type_expr_modules{_, _}: (@+value: String -> B)
    case EmitterRequest_main_type_expr_modules_at{_, _}: (@+value: String -> B)
    case EmitterRequest_main_type_expr_module_scope{_, _, _, _, _, _}: (@+value: String -> B)
    case EmitterRequest_main_type_expr_module_result{_, _, _}: (@+value: String -> B)
    case EmitterRequest_main_type_expr_module_empty{_, _, _, _}: (@+value: String -> B)
    case EmitterRequest_js_runtime_cli{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_io{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_show{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_type{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_type_names{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_type_patterns{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_type_eval{}: (@+value: String -> B)
    case EmitterRequest_js_runtime_native_type{}: (@+value: String -> B)
    case EmitterRequest_js_main{_}: (@+value: String -> B)
    case EmitterRequest_emit{_}: (@+value: EmitResult -> B)

def emitter_resume_type_group_8(-B: Type, request: EmitterRequestGroup8) -> Type:
  match request:
    case EmitterRequest_js_emit_template{_, _, _}: (@+value: EmitResult -> B)
    case EmitterRequest_js_emit_holes{_, _, _}: (@+value: EmitResult -> B)
    case EmitterRequest_js_emit_foreign{_, _, _}: (@+value: EmitResult -> B)
    case EmitterRequest_js_library_exports{_}: (@+value: String -> B)
    case EmitterRequest_js_library_export_fields{_}: (@+value: String -> B)
    case EmitterRequest_emit_library{_, _}: (@+value: EmitResult -> B)
    case EmitterRequest_js_emit_ending{_, _, _}: (@+value: String -> B)

def emitter_resume_type(-B: Type, request: EmitterRequest) -> Type:
  match request:
    case EmitterRequestGroup_0{inner}: emitter_resume_type_group_0(B, inner)
    case EmitterRequestGroup_1{inner}: emitter_resume_type_group_1(B, inner)
    case EmitterRequestGroup_2{inner}: emitter_resume_type_group_2(B, inner)
    case EmitterRequestGroup_3{inner}: emitter_resume_type_group_3(B, inner)
    case EmitterRequestGroup_4{inner}: emitter_resume_type_group_4(B, inner)
    case EmitterRequestGroup_5{inner}: emitter_resume_type_group_5(B, inner)
    case EmitterRequestGroup_6{inner}: emitter_resume_type_group_6(B, inner)
    case EmitterRequestGroup_7{inner}: emitter_resume_type_group_7(B, inner)
    case EmitterRequestGroup_8{inner}: emitter_resume_type_group_8(B, inner)

type EmitterProgress<-A: Type> is Type:
  EmitterFinished{value: A}
  EmitterPending{request: EmitterRequest, resume: emitter_resume_type(EmitterProgress<A>, request)}
  EmitterDirect{-R: Type, -request: EmitterRequest, arguments: R, invoke: (@arguments: R -> EmitterProgress<emitter_result(request)>), resume: emitter_resume_type(EmitterProgress<A>, request)}

def emitter_pure_js_catalog_layouts(v_1: EmitCatalog) -> List<&2, EmitModuleIndex>:
  match v_1:
    case EmitCatalog{v_8, _, _, _}:
      v_8

def emitter_pure_js_choose_result(v_1: Bool, v_3: String, v_5: String) -> String:
  match v_1:
    case True{}:
      v_3
    case False{}:
      v_5

def emitter_pure_env_depth(v_1: EmitEnv) -> Nat:
  match v_1:
    case EmitEnv{_, _, _, _, v_12}:
      v_12

def emitter_pure_js_base_origin(v_1: EmitEnv) -> Bool:
  match v_1:
    case EmitEnv{EmitScope{_, EmitAliases{_, _, v_16, _}, _}, _, _, _, _}:
      v_16

def emitter_pure_alias_namespace_found(v_2: Maybe<&2, String>) -> String:
  match v_2:
    case Some{v_5}:
      v_5
    case None{}:
      ""

def emitter_pure_js_aliases(v_1: EmitAliases) -> String:
  match v_1:
    case EmitAliases{_, v_8, _, _}:
      v_8

def emitter_body_js_value_indices(+v_1: List<&2, Loader.LoadedModule>) -> EmitterProgress<EmitCatalog>:
  v_1000000 = {v_1 : List<&2, Loader.LoadedModule>}
  EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_namespace_indices{v_1}}, +v_1000001 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_value_indices_at{v_1000000, v_1000001, v_1}}, +v_1000002 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog{v_1000002}}, +v_1000003 => EmitterFinished{v_1000003}}}}

def emitter_body_js_catalog(+v_2: List<&2, EmitModuleIndex>) -> EmitterProgress<EmitCatalog>:
  EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_at{v_2, EmitCatalog{v_2, MTip{}, MTip{}, MTip{}}}}, +v_1000004 => EmitterFinished{v_1000004}}

def emitter_body_js_catalog_at(v_2: List<&2, EmitModuleIndex>, v_4: EmitCatalog) -> EmitterProgress<EmitCatalog>:
  match v_2:
    case []:
      EmitterFinished{v_4}
    case +v_8 <> v_9:
      +v_1000005 = {v_8 : EmitModuleIndex}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_at{v_9, v_4}}, +v_1000006 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_module{v_1000005, v_1000006}}, +v_1000007 => EmitterFinished{v_1000007}}}

def emitter_body_js_catalog_module(+v_1: EmitModuleIndex, v_3: EmitCatalog) -> EmitterProgress<EmitCatalog>:
  match v_1, v_3:
    case EmitModuleIndex{_, _, v_16, v_17, v_18}, EmitCatalog{v_19, v_20, v_21, v_22}:
      v_1000008 = {v_19 : List<&2, EmitModuleIndex>}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_values{v_16, v_1, v_20}}, +v_1000009 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_constructors{v_17, v_1, v_21}}, +v_1000010 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_types{v_18, v_1, v_22}}, +v_1000011 => EmitterFinished{EmitCatalog{v_1000008, v_1000009, v_1000010, v_1000011}}}}}

def emitter_match_8(v_1: Map<&2, AST.Definition>, v_6: Map<&2, EmitModuleIndex>, +v_3: EmitModuleIndex) -> EmitterProgress<Map<&2, EmitModuleIndex>>:
  match v_1:
    case MTip{}:
      EmitterFinished{v_6}
    case MLeaf{v_16, AST.Definition{_, _, _, AST.DefTerm{_}, _, _}}:
      EmitterFinished{Map.set(&2, EmitModuleIndex, v_6, v_16, v_3)}
    case MLeaf{_, _}:
      EmitterFinished{v_6}
    case MNode{_, v_32, v_33}:
      v_1000012 = {v_32 : Map<&2, AST.Definition>}
      v_1000013 = {v_3 : EmitModuleIndex}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_values{v_33, v_3, v_6}}, +v_1000014 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_values{v_1000012, v_1000013, v_1000014}}, +v_1000015 => EmitterFinished{v_1000015}}}

def emitter_body_js_catalog_values(v_1: Map<&2, AST.Definition>, v_3: EmitModuleIndex, v_6: Map<&2, EmitModuleIndex>) -> EmitterProgress<Map<&2, EmitModuleIndex>>:
  emitter_match_8(v_1, v_6, v_3)

def emitter_match_9(v_2: Map<&2, EmitConstructorOwner>, v_7: Map<&2, EmitModuleIndex>, +v_4: EmitModuleIndex) -> EmitterProgress<Map<&2, EmitModuleIndex>>:
  match v_2:
    case MTip{}:
      EmitterFinished{v_7}
    case MLeaf{v_12, _}:
      EmitterFinished{Map.set(&2, EmitModuleIndex, v_7, v_12, v_4)}
    case MNode{_, v_19, v_20}:
      v_1000016 = {v_19 : Map<&2, EmitConstructorOwner>}
      v_1000017 = {v_4 : EmitModuleIndex}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_constructors{v_20, v_4, v_7}}, +v_1000018 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_constructors{v_1000016, v_1000017, v_1000018}}, +v_1000019 => EmitterFinished{v_1000019}}}

def emitter_body_js_catalog_constructors(v_2: Map<&2, EmitConstructorOwner>, v_4: EmitModuleIndex, v_7: Map<&2, EmitModuleIndex>) -> EmitterProgress<Map<&2, EmitModuleIndex>>:
  emitter_match_9(v_2, v_7, v_4)

def emitter_match_10(v_2: Map<&2, List<&2, AST.TopLevel>>, +v_8: Map<&2, List<&2, EmitModuleIndex>>, +v_4: EmitModuleIndex) -> EmitterProgress<Map<&2, List<&2, EmitModuleIndex>>>:
  match v_2:
    case MTip{}:
      EmitterFinished{v_8}
    case MLeaf{+v_14, _}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_type_insert{IndexLookup.find(List<&2, EmitModuleIndex>, v_8, v_14), v_14, v_4, v_8}}, +v_1000020 => EmitterFinished{v_1000020}}
    case MNode{_, v_23, v_24}:
      v_1000021 = {v_23 : Map<&2, List<&2, AST.TopLevel>>}
      v_1000022 = {v_4 : EmitModuleIndex}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_types{v_24, v_4, v_8}}, +v_1000023 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_catalog_types{v_1000021, v_1000022, v_1000023}}, +v_1000024 => EmitterFinished{v_1000024}}}

def emitter_body_js_catalog_types(v_2: Map<&2, List<&2, AST.TopLevel>>, v_4: EmitModuleIndex, v_8: Map<&2, List<&2, EmitModuleIndex>>) -> EmitterProgress<Map<&2, List<&2, EmitModuleIndex>>>:
  emitter_match_10(v_2, v_8, v_4)

def emitter_match_11(v_3: Maybe<&2, List<&2, EmitModuleIndex>>, v_11: Map<&2, List<&2, EmitModuleIndex>>, v_5: String, v_7: EmitModuleIndex) -> EmitterProgress<Map<&2, List<&2, EmitModuleIndex>>>:
  match v_3:
    case None{}:
      EmitterFinished{Map.set(&2, List<&2, EmitModuleIndex>, v_11, v_5, [v_7])}
    case Some{v_18}:
      EmitterFinished{Map.set(&2, List<&2, EmitModuleIndex>, v_11, v_5, v_7 <> v_18)}

def emitter_body_js_catalog_type_insert(v_3: Maybe<&2, List<&2, EmitModuleIndex>>, v_5: String, v_7: EmitModuleIndex, v_11: Map<&2, List<&2, EmitModuleIndex>>) -> EmitterProgress<Map<&2, List<&2, EmitModuleIndex>>>:
  emitter_match_11(v_3, v_11, v_5, v_7)

def emitter_body_js_catalog_layouts(v_1: EmitCatalog) -> EmitterProgress<List<&2, EmitModuleIndex>>:
  EmitterFinished{emitter_pure_js_catalog_layouts(v_1)}

def emitter_body_js_namespace_indices(v_1: List<&2, Loader.LoadedModule>) -> EmitterProgress<Map<&2, String>>:
  match v_1:
    case []:
      EmitterFinished{MTip{}}
    case Loader.LoadedModule{v_9, AST.Module{v_10, _, _}} <> v_13:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_namespace_indices{v_13}}, +v_1000025 => EmitterFinished{Map.set(&2, String, v_1000025, Path.normalize(v_10), v_9)}}

def emitter_continuation_13(+v_21: Bool, +v_14: String, +v_17: List<&2, AST.TopLevel>, +v_1000028: List<&2, EmitAlias>, v_18: List<&2, Loader.LoadedModule>, v_4: Map<&2, String>, v_6: List<&2, Loader.LoadedModule>, v_1000027: String) -> EmitterProgress<List<&2, EmitModuleIndex>>:
  v_1000029 = {v_21 : Bool}
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_native_operations{v_21, v_14, v_17}}, +v_1000030 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_resolved_aliases{v_1000028, v_1000029, v_1000030}}, +v_1000031 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_value_declarations{v_14, v_17}}, +v_1000032 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_constructor_indices{v_14, v_17}}, +v_1000033 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_type_indices{v_14, v_17}}, +v_1000034 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_value_indices_at{v_18, v_4, v_6}}, +v_1000035 => EmitterFinished{EmitModuleIndex{v_1000027, v_1000031, v_1000032, v_1000033, v_1000034} <> v_1000035}}}}}}}

def emitter_continuation_14(+v_1000026: Bool, +v_14: String, v_16: List<&2, AST.ModuleImport>, +v_4: Map<&2, String>, v_17: List<&2, AST.TopLevel>, v_18: List<&2, Loader.LoadedModule>, v_6: List<&2, Loader.LoadedModule>) -> EmitterProgress<List<&2, EmitModuleIndex>>:
  v_21 = v_1000026
  v_1000027 = {v_14 : String}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_resolved_alias_entries{v_16, v_4}}, +v_1000028 => emitter_continuation_13(v_21, v_14, v_17, v_1000028, v_18, v_4, v_6, v_1000027)}

def emitter_match_15(v_1: List<&2, Loader.LoadedModule>, +v_6: List<&2, Loader.LoadedModule>, v_4: Map<&2, String>) -> EmitterProgress<List<&2, EmitModuleIndex>>:
  match v_1:
    case []:
      EmitterFinished{[]}
    case Loader.LoadedModule{v_14, AST.Module{v_15, v_16, v_17}} <> v_18:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_base_source{v_15, v_6}}, +v_1000026 => emitter_continuation_14(v_1000026, v_14, v_16, v_4, v_17, v_18, v_6)}

def emitter_body_js_value_indices_at(v_1: List<&2, Loader.LoadedModule>, v_4: Map<&2, String>, v_6: List<&2, Loader.LoadedModule>) -> EmitterProgress<List<&2, EmitModuleIndex>>:
  emitter_match_15(v_1, v_6, v_4)

def emitter_match_16(v_3: List<&2, AST.TopLevel>, +v_1: String) -> EmitterProgress<Map<&2, AST.Definition>>:
  match v_3:
    case []:
      EmitterFinished{MTip{}}
    case AST.DefTop{v_7} <> v_8:
      +v_1000036 = {v_7 : AST.Definition}
      v_1000037 = {v_1 : String}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_value_declarations{v_1, v_8}}, +v_1000038 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_value_declaration{v_1000036, v_1000037, v_1000038}}, +v_1000039 => EmitterFinished{v_1000039}}}
    case _ <> v_14:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_value_declarations{v_1, v_14}}, +v_1000040 => EmitterFinished{v_1000040}}

def emitter_body_js_value_declarations(v_1: String, v_3: List<&2, AST.TopLevel>) -> EmitterProgress<Map<&2, AST.Definition>>:
  emitter_match_16(v_3, v_1)

def emitter_match_17(+v_0: AST.Definition, v_4: Map<&2, AST.Definition>, v_2: String) -> EmitterProgress<Map<&2, AST.Definition>>:
  match v_0:
    case AST.Definition{v_12, _, _, _, _, _}:
      v_1000041 = {v_4 : Map<&2, AST.Definition>}
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_2, v_12}}, +v_1000042 => EmitterFinished{Map.set(&2, AST.Definition, v_1000041, v_1000042, v_0)}}

def emitter_body_js_value_declaration(+v_0: AST.Definition, v_2: String, v_4: Map<&2, AST.Definition>) -> EmitterProgress<Map<&2, AST.Definition>>:
  emitter_match_17(v_0, v_4, v_2)

def emitter_match_18(v_3: List<&2, AST.TopLevel>, +v_1: String) -> EmitterProgress<Map<&2, EmitConstructorOwner>>:
  match v_3:
    case []:
      EmitterFinished{MTip{}}
    case AST.TypeTop{v_8} <> v_9:
      +v_1000043 = {v_8 : AST.TypeDecl}
      v_1000044 = {v_1 : String}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_constructor_indices{v_1, v_9}}, +v_1000045 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_constructor_index_family{v_1000043, v_1000044, v_1000045}}, +v_1000046 => EmitterFinished{v_1000046}}}
    case _ <> v_15:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_constructor_indices{v_1, v_15}}, +v_1000047 => EmitterFinished{v_1000047}}

def emitter_body_js_constructor_indices(v_1: String, v_3: List<&2, AST.TopLevel>) -> EmitterProgress<Map<&2, EmitConstructorOwner>>:
  emitter_match_18(v_3, v_1)

def emitter_body_js_constructor_index_family(+v_0: AST.TypeDecl, v_2: String, v_5: Map<&2, EmitConstructorOwner>) -> EmitterProgress<Map<&2, EmitConstructorOwner>>:
  match v_0:
    case AST.TypeDecl{_, _, _, v_16, _}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_constructor_index_items{v_16, v_0, v_2, v_5}}, +v_1000048 => EmitterFinished{v_1000048}}

def emitter_match_20(+v_12: AST.ConstructorDecl, v_13: List<&2, AST.ConstructorDecl>, +v_2: AST.TypeDecl, +v_4: String, v_7: Map<&2, EmitConstructorOwner>) -> EmitterProgress<Map<&2, EmitConstructorOwner>>:
  match v_12:
    case AST.Constructor{v_17, _, _}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_constructor_index_items{v_13, v_2, v_4, v_7}}, +v_1000049 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_4, v_17}}, +v_1000050 => EmitterFinished{Map.set(&2, EmitConstructorOwner, v_1000049, v_1000050, EmitConstructorOwner{v_2, v_12})}}}

def emitter_match_21(v_1: List<&2, AST.ConstructorDecl>, v_7: Map<&2, EmitConstructorOwner>, +v_2: AST.TypeDecl, v_4: String) -> EmitterProgress<Map<&2, EmitConstructorOwner>>:
  match v_1:
    case []:
      EmitterFinished{v_7}
    case +v_12 <> v_13:
      emitter_match_20(v_12, v_13, v_2, v_4, v_7)

def emitter_body_js_constructor_index_items(v_1: List<&2, AST.ConstructorDecl>, +v_2: AST.TypeDecl, v_4: String, v_7: Map<&2, EmitConstructorOwner>) -> EmitterProgress<Map<&2, EmitConstructorOwner>>:
  emitter_match_21(v_1, v_7, v_2, v_4)

def emitter_match_22(v_3: List<&2, AST.TopLevel>, +v_1: String) -> EmitterProgress<Map<&2, List<&2, AST.TopLevel>>>:
  match v_3:
    case []:
      EmitterFinished{MTip{}}
    case +v_8 <> v_9:
      +v_1000051 = {v_8 : AST.TopLevel}
      v_1000052 = {v_1 : String}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_type_indices{v_1, v_9}}, +v_1000053 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_type_index_declaration{v_1000051, v_1000052, v_1000053}}, +v_1000054 => EmitterFinished{v_1000054}}}

def emitter_body_js_type_indices(v_1: String, v_3: List<&2, AST.TopLevel>) -> EmitterProgress<Map<&2, List<&2, AST.TopLevel>>>:
  emitter_match_22(v_3, v_1)

def emitter_body_js_type_index_declaration(+v_0: AST.TopLevel, v_2: String, v_5: Map<&2, List<&2, AST.TopLevel>>) -> EmitterProgress<Map<&2, List<&2, AST.TopLevel>>>:
  match v_0:
    case AST.DefTop{AST.Definition{v_14, _, _, _, _, _}}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_2, v_14}}, +v_1000055 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_type_index_insert{v_1000055, v_0, v_5}}, +v_1000056 => EmitterFinished{v_1000056}}}
    case AST.TypeTop{AST.TypeDecl{v_27, _, _, _, _}}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_2, v_27}}, +v_1000057 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_type_index_insert{v_1000057, v_0, v_5}}, +v_1000058 => EmitterFinished{v_1000058}}}
    case AST.LawTop{AST.LawDecl{v_38, _, _, _}}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_2, v_38}}, +v_1000059 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_type_index_insert{v_1000059, v_0, v_5}}, +v_1000060 => EmitterFinished{v_1000060}}}

def emitter_body_js_type_index_insert(+v_1: String, v_2: AST.TopLevel, +v_5: Map<&2, List<&2, AST.TopLevel>>) -> EmitterProgress<Map<&2, List<&2, AST.TopLevel>>>:
  EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_type_index_found{IndexLookup.find(List<&2, AST.TopLevel>, v_5, v_1), v_1, v_2, v_5}}, +v_1000061 => EmitterFinished{v_1000061}}

def emitter_match_24(v_2: Maybe<&2, List<&2, AST.TopLevel>>, v_8: Map<&2, List<&2, AST.TopLevel>>, v_4: String, v_5: AST.TopLevel) -> EmitterProgress<Map<&2, List<&2, AST.TopLevel>>>:
  match v_2:
    case None{}:
      EmitterFinished{Map.set(&2, List<&2, AST.TopLevel>, v_8, v_4, [v_5])}
    case Some{v_13}:
      EmitterFinished{Map.set(&2, List<&2, AST.TopLevel>, v_8, v_4, v_5 <> v_13)}

def emitter_body_js_type_index_found(v_2: Maybe<&2, List<&2, AST.TopLevel>>, v_4: String, v_5: AST.TopLevel, v_8: Map<&2, List<&2, AST.TopLevel>>) -> EmitterProgress<Map<&2, List<&2, AST.TopLevel>>>:
  emitter_match_24(v_2, v_8, v_4, v_5)

def emitter_match_25(+v_1: Char) -> EmitterProgress<String>:
  match v_1:
    case '"':
      EmitterFinished{"\\\""}
    case '\\':
      EmitterFinished{"\\\\"}
    case '\n':
      EmitterFinished{"\\n"}
    case '\r':
      EmitterFinished{"\\r"}
    case '\t':
      EmitterFinished{"\\t"}
    case '\0':
      EmitterFinished{"\\u0000"}
    case _:
      EmitterFinished{String.from_list([v_1])}

def emitter_body_js_escape_char(v_1: Char) -> EmitterProgress<String>:
  emitter_match_25(v_1)

def emitter_body_js_comma_prefix(v_1: Bool) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{""}
    case False{}:
      EmitterFinished{","}

def emitter_continuation_27(+v_1000062: String, v_9: List<&2, Char>, v_4: String) -> EmitterProgress<String>:
  v_12 = v_1000062
  EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_quote_chars{v_9, String.append(v_4, v_12)}}, +v_1000063 => EmitterFinished{v_1000063}}

def emitter_body_js_quote_chars(v_2: List<&2, Char>, v_4: String) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterFinished{String.append(v_4, "\"")}
    case +v_8 <> v_9:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_escape_char{v_8}}, False{}, v_1000064 => emitter_body_js_escape_char(v_8), +v_1000062 => emitter_continuation_27(v_1000062, v_9, v_4)}

def emitter_body_js_quote(v_1: String) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote_chars{String.to_list(v_1), "\""}}, False{}, v_1000066 => emitter_body_js_quote_chars(String.to_list(v_1), "\""), +v_1000065 => EmitterFinished{v_1000065}}

def emitter_body_js_named_identifier_char(v_1: Bool, v_3: Char, v_5: U32) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{Char.show(v_3)}
    case False{}:
      EmitterFinished{String.append("$", String.append(U32.show(v_5), "$"))}

def emitter_body_js_named_identifier_chars(v_1: String, v_3: String) -> EmitterProgress<String>:
  match v_1:
    case "":
      EmitterFinished{v_3}
    case SCon{+v_7, v_8}:
      +v_10 = Char.to_u32(v_7)
      v_12 = Bool.or(U32.is_eq(v_10, 95), Bool.or(Bool.and(U32.is_ge(v_10, 48), U32.is_le(v_10, 57)), Bool.or(Bool.and(U32.is_ge(v_10, 65), U32.is_le(v_10, 90)), Bool.and(U32.is_ge(v_10, 97), U32.is_le(v_10, 122)))))
      v_1000067 = {v_8 : String}
      v_1000068 = {v_3 : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_named_identifier_char{v_12, v_7, v_10}}, False{}, v_1000071 => emitter_body_js_named_identifier_char(v_12, v_7, v_10), +v_1000069 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_named_identifier_chars{v_1000067, String.append(v_1000068, v_1000069)}}, +v_1000070 => EmitterFinished{v_1000070}}}

def emitter_body_js_named_identifier(v_1: String) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_named_identifier_chars{v_1, "$u$"}}, False{}, v_1000073 => emitter_body_js_named_identifier_chars(v_1, "$u$"), +v_1000072 => EmitterFinished{v_1000072}}

def emitter_body_env_binding(v_1: EmitEnv, v_3: Nat) -> EmitterProgress<Maybe<&2, EmitBinding>>:
  match v_1:
    case EmitEnv{_, v_12, v_13, v_14, _}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_env_binding_at{v_12, v_13, v_14, v_3}}, +v_1000074 => EmitterFinished{v_1000074}}

def emitter_match_32(+v_12: Nat, +v_21: String, +v_23: Maybe<&2, EmitClosure>, +v_25: Maybe<&2, EmitClosure>, v_22: List<&2, String>, v_24: List<&2, Maybe<&2, EmitClosure>>, v_26: List<&2, Maybe<&2, EmitClosure>>) -> EmitterProgress<Maybe<&2, EmitBinding>>:
  match v_12:
    case 0n:
      EmitterFinished{Some{EmitBinding{v_21, v_23, v_25}}}
    case _:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_env_binding_at{v_22, v_24, v_26, Nat.sub(v_12, 1n)}}, +v_1000075 => EmitterFinished{v_1000075}}

def emitter_body_env_binding_at(v_2: List<&2, String>, v_6: List<&2, Maybe<&2, EmitClosure>>, v_10: List<&2, Maybe<&2, EmitClosure>>, v_12: Nat) -> EmitterProgress<Maybe<&2, EmitBinding>>:
  match v_2, v_6, v_10:
    case +v_21 <> v_22, +v_23 <> v_24, +v_25 <> v_26:
      emitter_match_32(v_12, v_21, v_23, v_25, v_22, v_24, v_26)
    case _, _, _:
      EmitterFinished{None{}}

def emitter_body_env_at_binding(v_2: Maybe<&2, EmitBinding>) -> EmitterProgress<String>:
  match v_2:
    case None{}:
      EmitterFinished{"undefined"}
    case Some{EmitBinding{v_7, _, _}}:
      EmitterFinished{v_7}

def emitter_body_env_at(v_1: EmitEnv, v_3: Nat) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_binding{v_1, v_3}}, False{}, v_1000078 => emitter_body_env_binding(v_1, v_3), +v_1000076 => emitter_body_env_at_binding(v_1000076)}

def emitter_match_35(v_9: EmitEnv, v_1: String, v_4: Maybe<&2, EmitClosure>, v_7: Maybe<&2, EmitClosure>) -> EmitterProgress<EmitEnv>:
  match v_9:
    case EmitEnv{v_16, v_17, v_18, v_19, v_20}:
      EmitterFinished{EmitEnv{v_16, v_1 <> v_17, v_4 <> v_18, v_7 <> v_19, Nat.add(v_20, 1n)}}

def emitter_body_env_bind(v_1: String, v_4: Maybe<&2, EmitClosure>, v_7: Maybe<&2, EmitClosure>, v_9: EmitEnv) -> EmitterProgress<EmitEnv>:
  emitter_match_35(v_9, v_1, v_4, v_7)

def emitter_body_env_push(v_1: String, v_3: EmitEnv) -> EmitterProgress<EmitEnv>:
  emitter_body_env_bind(v_1, None{}, None{}, v_3)

def emitter_match_36(v_2: EmitEnv, v_0: AST.SyntaxTerm) -> EmitterProgress<EmitClosure>:
  match v_2:
    case EmitEnv{v_9, v_10, v_11, v_12, v_13}:
      EmitterFinished{EmitClosure{v_0, v_9, v_10, v_11, v_12, v_13}}

def emitter_body_js_close(v_0: AST.SyntaxTerm, v_2: EmitEnv) -> EmitterProgress<EmitClosure>:
  emitter_match_36(v_2, v_0)

def emitter_match_37(v_4: EmitEnv, v_1: List<&2, AST.TelescopeItem>, v_2: AST.SyntaxTerm) -> EmitterProgress<EmitClosure>:
  match v_4:
    case EmitEnv{v_11, v_12, v_13, v_14, v_15}:
      EmitterFinished{EmitInferred{v_1, v_2, v_11, v_12, v_13, v_14, v_15}}

def emitter_body_js_close_inferred(v_1: List<&2, AST.TelescopeItem>, v_2: AST.SyntaxTerm, v_4: EmitEnv) -> EmitterProgress<EmitClosure>:
  emitter_match_37(v_4, v_1, v_2)

def emitter_match_38(v_4: EmitEnv, v_1: List<&2, AST.TelescopeItem>, v_2: AST.OptionalTerm) -> EmitterProgress<EmitClosure>:
  match v_4:
    case EmitEnv{v_11, v_12, v_13, v_14, v_15}:
      EmitterFinished{EmitDeclared{v_1, v_2, v_11, v_12, v_13, v_14, v_15}}

def emitter_body_js_close_declared(v_1: List<&2, AST.TelescopeItem>, v_2: AST.OptionalTerm, v_4: EmitEnv) -> EmitterProgress<EmitClosure>:
  emitter_match_38(v_4, v_1, v_2)

def emitter_match_39(v_6: EmitEnv, v_1: String, v_3: List<&2, AST.TelescopeItem>, v_4: AST.SyntaxTerm) -> EmitterProgress<EmitClosure>:
  match v_6:
    case EmitEnv{v_13, v_14, v_15, v_16, v_17}:
      EmitterFinished{EmitDefinition{v_1, v_3, v_4, v_13, v_14, v_15, v_16, v_17}}

def emitter_body_js_close_definition(v_1: String, v_3: List<&2, AST.TelescopeItem>, v_4: AST.SyntaxTerm, v_6: EmitEnv) -> EmitterProgress<EmitClosure>:
  emitter_match_39(v_6, v_1, v_3, v_4)

def emitter_body_js_closure_env(v_1: EmitClosure) -> EmitterProgress<EmitEnv>:
  match v_1:
    case EmitClosure{_, v_10, v_11, v_12, v_13, v_14}:
      EmitterFinished{EmitEnv{v_10, v_11, v_12, v_13, v_14}}
    case EmitInferred{_, _, v_24, v_25, v_26, v_27, v_28}:
      EmitterFinished{EmitEnv{v_24, v_25, v_26, v_27, v_28}}
    case EmitDeclared{_, _, v_38, v_39, v_40, v_41, v_42}:
      EmitterFinished{EmitEnv{v_38, v_39, v_40, v_41, v_42}}
    case EmitDefinition{_, _, _, v_54, v_55, v_56, v_57, v_58}:
      EmitterFinished{EmitEnv{v_54, v_55, v_56, v_57, v_58}}

def emitter_match_41(v_3: EmitScope, +v_1: String) -> EmitterProgress<String>:
  match v_3:
    case EmitScope{v_11, EmitAliases{v_12, _, _, _}, _}:
      v_1000080 = {v_1 : String}
      v_1000081 = {v_12 : List<&2, EmitAlias>}
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_11, v_1}}, +v_1000082 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_scope_alias{v_1000080, v_1000081, v_1000082, 0n}}, +v_1000083 => EmitterFinished{v_1000083}}}

def emitter_body_js_scope_key(v_1: String, v_3: EmitScope) -> EmitterProgress<String>:
  emitter_match_41(v_3, v_1)

def emitter_match_42(v_4: List<&2, EmitAlias>, v_6: String, +v_1: String, +v_8: Nat) -> EmitterProgress<String>:
  match v_4:
    case []:
      EmitterFinished{v_6}
    case EmitAlias{_, v_16, v_17, +v_18} <> v_19:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_scope_alias_match{Bool.and(String.starts_with(v_1, v_16), Nat.is_gt(v_18, v_8)), v_1, v_18, v_17, v_19, v_6, v_8}}, +v_1000084 => EmitterFinished{v_1000084}}

def emitter_body_js_scope_alias(v_1: String, v_4: List<&2, EmitAlias>, v_6: String, v_8: Nat) -> EmitterProgress<String>:
  emitter_match_42(v_4, v_6, v_1, v_8)

def emitter_match_43(v_1: Bool, +v_3: String, v_10: List<&2, EmitAlias>, v_12: String, v_14: Nat, v_7: String, +v_5: Nat) -> EmitterProgress<String>:
  match v_1:
    case False{}:
      emitter_body_js_scope_alias(v_3, v_10, v_12, v_14)
    case True{}:
      v_1000086 = {v_3 : String}
      v_1000087 = {v_10 : List<&2, EmitAlias>}
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_7, String.drop(v_3, v_5)}}, +v_1000088 => emitter_body_js_scope_alias(v_1000086, v_1000087, v_1000088, v_5)}

def emitter_body_js_scope_alias_match(v_1: Bool, v_3: String, v_5: Nat, v_7: String, v_10: List<&2, EmitAlias>, v_12: String, v_14: Nat) -> EmitterProgress<String>:
  emitter_match_43(v_1, v_3, v_10, v_12, v_14, v_7, v_5)

def emitter_match_44(+v_11: EmitScope, +v_1: String) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_11:
    case EmitScope{_, _, +v_21}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_scope_key{v_1, v_11}}, False{}, v_1000093 => emitter_body_js_scope_key(v_1, v_11), +v_1000090 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_lookup{v_1000090, v_21}}, +v_1000091 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_fallback{v_1000091, v_1, v_21}}, +v_1000092 => EmitterFinished{v_1000092}}}}

def emitter_match_45(v_3: EmitEnv, v_1: String) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_3:
    case EmitEnv{v_11, _, _, _, _}:
      emitter_match_44(v_11, v_1)

def emitter_body_js_global(v_1: String, v_3: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_45(v_3, v_1)

def emitter_match_46(+v_2: Maybe<&2, EmitClosure>, v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case Some{_}:
      EmitterFinished{v_2}
    case None{}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_lookup{v_4, v_6}}, +v_1000094 => EmitterFinished{v_1000094}}

def emitter_body_js_global_fallback(v_2: Maybe<&2, EmitClosure>, v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_46(v_2, v_4, v_6)

def emitter_match_47(+v_3: EmitCatalog, +v_1: String) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_3:
    case EmitCatalog{_, v_11, _, _}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_owner{IndexLookup.find(EmitModuleIndex, v_11, v_1), v_1, v_3}}, +v_1000095 => EmitterFinished{v_1000095}}

def emitter_body_js_global_lookup(v_1: String, +v_3: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_47(v_3, v_1)

def emitter_match_48(+v_10: EmitModuleIndex, +v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_10:
    case EmitModuleIndex{_, _, v_18, _, _}:
      v_1000096 = {IndexLookup.find(AST.Definition, v_18, v_4) : Maybe<&2, AST.Definition>}
      v_1000097 = {v_4 : String}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_owner_env{v_10, v_6}}, +v_1000098 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_definition{v_1000096, v_1000097, v_1000098}}, +v_1000099 => EmitterFinished{v_1000099}}}

def emitter_body_js_global_owner(v_2: Maybe<&2, EmitModuleIndex>, v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{+v_10}:
      emitter_match_48(v_10, v_4, v_6)

def emitter_body_js_owner_env(v_1: EmitModuleIndex, v_3: EmitCatalog) -> EmitterProgress<EmitEnv>:
  match v_1:
    case EmitModuleIndex{v_10, v_11, _, _, _}:
      EmitterFinished{EmitEnv{EmitScope{v_10, v_11, v_3}, [], [], [], 0n}}

def emitter_body_js_global_definition(v_1: Maybe<&2, AST.Definition>, v_3: String, v_5: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_1:
    case Some{AST.Definition{_, v_15, _, AST.DefTerm{v_17}, _, _}}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_definition{v_3, v_15, v_17, v_5}}, False{}, v_1000101 => emitter_body_js_close_definition(v_3, v_15, v_17, v_5), +v_1000100 => EmitterFinished{Some{v_1000100}}}
    case _:
      EmitterFinished{None{}}

def emitter_match_52(+v_11: EmitScope, +v_1: String) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_11:
    case EmitScope{_, _, +v_21}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_scope_key{v_1, v_11}}, False{}, v_1000105 => emitter_body_js_scope_key(v_1, v_11), +v_1000102 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_type_lookup{v_1000102, v_21}}, +v_1000103 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_type_fallback{v_1000103, v_1, v_21}}, +v_1000104 => EmitterFinished{v_1000104}}}}

def emitter_match_53(v_3: EmitEnv, v_1: String) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_3:
    case EmitEnv{v_11, _, _, _, _}:
      emitter_match_52(v_11, v_1)

def emitter_body_js_global_type(v_1: String, v_3: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_53(v_3, v_1)

def emitter_match_54(+v_2: Maybe<&2, EmitClosure>, v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case Some{_}:
      EmitterFinished{v_2}
    case None{}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_type_lookup{v_4, v_6}}, +v_1000106 => EmitterFinished{v_1000106}}

def emitter_body_js_global_type_fallback(v_2: Maybe<&2, EmitClosure>, v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_54(v_2, v_4, v_6)

def emitter_match_55(+v_3: EmitCatalog, +v_1: String) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_3:
    case EmitCatalog{_, _, _, v_13}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_type_owners{IndexLookup.find(List<&2, EmitModuleIndex>, v_13, v_1), v_1, v_3}}, +v_1000107 => EmitterFinished{v_1000107}}

def emitter_body_js_global_type_lookup(v_1: String, +v_3: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_55(v_3, v_1)

def emitter_body_js_global_type_owners(v_3: Maybe<&2, List<&2, EmitModuleIndex>>, v_5: String, v_7: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_3:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_11}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_type_modules{v_5, v_11, v_7}}, +v_1000108 => EmitterFinished{v_1000108}}

def emitter_match_57(v_4: List<&2, EmitModuleIndex>, +v_6: EmitCatalog, +v_1: String) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_4:
    case []:
      EmitterFinished{None{}}
    case EmitModuleIndex{v_15, v_16, _, _, v_19} <> v_20:
      v_22 = {EmitEnv{EmitScope{v_15, v_16, v_6}, [], [], [], 0n} : EmitEnv}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_type_index{IndexLookup.find(List<&2, AST.TopLevel>, v_19, v_1), v_22}}, +v_1000109 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_type_next{v_1000109, v_1, v_20, v_6}}, +v_1000110 => EmitterFinished{v_1000110}}}

def emitter_body_js_global_type_modules(v_1: String, v_4: List<&2, EmitModuleIndex>, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_57(v_4, v_6, v_1)

def emitter_match_58(+v_2: Maybe<&2, EmitClosure>, v_4: String, v_7: List<&2, EmitModuleIndex>, v_9: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case Some{_}:
      EmitterFinished{v_2}
    case None{}:
      emitter_body_js_global_type_modules(v_4, v_7, v_9)

def emitter_body_js_global_type_next(v_2: Maybe<&2, EmitClosure>, v_4: String, v_7: List<&2, EmitModuleIndex>, v_9: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_58(v_2, v_4, v_7, v_9)

def emitter_body_js_global_type_index(v_2: Maybe<&2, List<&2, AST.TopLevel>>, v_4: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_8}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_type_decls{v_8, v_4}}, +v_1000112 => EmitterFinished{v_1000112}}

def emitter_match_60(v_1: List<&2, AST.TopLevel>, +v_3: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case AST.DefTop{AST.Definition{_, v_14, v_15, v_16, _, _}} <> _:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_type_definition{v_14, v_15, v_16, v_3}}, +v_1000113 => EmitterFinished{v_1000113}}
    case AST.TypeTop{AST.TypeDecl{_, v_28, v_29, _, _}} <> _:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_declared{v_28, AST.SomeTerm{v_29}, v_3}}, False{}, v_1000115 => emitter_body_js_close_declared(v_28, AST.SomeTerm{v_29}, v_3), +v_1000114 => EmitterFinished{Some{v_1000114}}}
    case AST.LawTop{AST.LawDecl{v_39, v_40, v_41, _}} <> v_43:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation{v_39, v_3}}, +v_1000116 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_global_native_law_operation{v_1000116, v_40, v_41, v_43, v_3}}, +v_1000117 => EmitterFinished{v_1000117}}}

def emitter_body_js_global_type_decls(v_1: List<&2, AST.TopLevel>, v_3: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_60(v_1, v_3)

def emitter_match_61(v_3: AST.DefBody, v_1: List<&2, AST.TelescopeItem>, v_5: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_3:
    case AST.DefTerm{v_12}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_type_definition{v_1, v_12, v_5}}, +v_1000120 => EmitterFinished{v_1000120}}
    case AST.DefImports{_}:
      EmitterFinished{None{}}

def emitter_match_62(+v_2: AST.OptionalTerm, v_1: List<&2, AST.TelescopeItem>, v_5: EmitEnv, v_3: AST.DefBody) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case AST.SomeTerm{_}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_declared{v_1, v_2, v_5}}, False{}, v_1000119 => emitter_body_js_close_declared(v_1, v_2, v_5), +v_1000118 => EmitterFinished{Some{v_1000118}}}
    case AST.NoTerm{}:
      emitter_match_61(v_3, v_1, v_5)

def emitter_body_js_global_type_definition(v_1: List<&2, AST.TelescopeItem>, v_2: AST.OptionalTerm, v_3: AST.DefBody, v_5: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_62(v_2, v_1, v_5, v_3)

def emitter_match_63(v_2: Maybe<&2, String>, v_4: List<&2, AST.Clause>, v_5: AST.SyntaxTerm, v_9: EmitEnv, v_7: List<&2, AST.TopLevel>) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case Some{_}:
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_native_law_binders{v_4, 0n}}, +v_1000121 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_native_law_type{v_1000121, v_5, v_9}}, +v_1000122 => EmitterFinished{v_1000122}}}
    case None{}:
      emitter_body_js_global_type_decls(v_7, v_9)

def emitter_body_js_global_native_law_operation(v_2: Maybe<&2, String>, v_4: List<&2, AST.Clause>, v_5: AST.SyntaxTerm, v_7: List<&2, AST.TopLevel>, v_9: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_63(v_2, v_4, v_5, v_9, v_7)

def emitter_body_js_native_law_type(v_2: Maybe<&2, List<&2, AST.TelescopeItem>>, v_3: AST.SyntaxTerm, v_5: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case Some{v_9}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_declared{v_9, AST.SomeTerm{v_3}, v_5}}, False{}, v_1000125 => emitter_body_js_close_declared(v_9, AST.SomeTerm{v_3}, v_5), +v_1000124 => EmitterFinished{Some{v_1000124}}}
    case None{}:
      EmitterFinished{None{}}

def emitter_match_65(v_1: List<&2, AST.Clause>, +v_3: Nat) -> EmitterProgress<Maybe<&2, List<&2, AST.TelescopeItem>>>:
  match v_1:
    case []:
      EmitterFinished{Some{[]}}
    case AST.ClauseFor{True{}, v_11, v_12, v_13, None{}, v_14} <> v_15:
      v_1000126 = {AST.Binder{v_11, v_12, v_3, v_13, v_14} : AST.TelescopeItem}
      EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_native_law_binders{v_15, Nat.add(v_3, 1n)}}, +v_1000127 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_native_law_binder{v_1000126, v_1000127}}, +v_1000128 => EmitterFinished{v_1000128}}}
    case _ <> _:
      EmitterFinished{None{}}

def emitter_body_js_native_law_binders(v_1: List<&2, AST.Clause>, v_3: Nat) -> EmitterProgress<Maybe<&2, List<&2, AST.TelescopeItem>>>:
  emitter_match_65(v_1, v_3)

def emitter_match_66(v_3: Maybe<&2, List<&2, AST.TelescopeItem>>, v_0: AST.TelescopeItem) -> EmitterProgress<Maybe<&2, List<&2, AST.TelescopeItem>>>:
  match v_3:
    case Some{v_7}:
      EmitterFinished{Some{v_0 <> v_7}}
    case None{}:
      EmitterFinished{None{}}

def emitter_body_js_native_law_binder(v_0: AST.TelescopeItem, v_3: Maybe<&2, List<&2, AST.TelescopeItem>>) -> EmitterProgress<Maybe<&2, List<&2, AST.TelescopeItem>>>:
  emitter_match_66(v_3, v_0)

def emitter_match_67(+v_1: List<&2, AST.TelescopeItem>, v_2: AST.SyntaxTerm, v_4: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_1:
    case []:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_2, v_4}}, +v_1000129 => EmitterFinished{v_1000129}}
    case _:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_inferred{v_1, v_2, v_4}}, False{}, v_1000131 => emitter_body_js_close_inferred(v_1, v_2, v_4), +v_1000130 => EmitterFinished{Some{v_1000130}}}

def emitter_body_js_type_definition(v_1: List<&2, AST.TelescopeItem>, v_2: AST.SyntaxTerm, v_4: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_67(v_1, v_2, v_4)

def emitter_match_68(v_99: AST.SyntaxTerm, +v_3: EmitEnv, v_1: EmitClosure) -> EmitterProgress<EmitClosure>:
  match v_99:
    case AST.TermAnn{v_108, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_108, v_3}}, False{}, v_1000142 => emitter_body_js_close(v_108, v_3), +v_1000140 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1000140}}, +v_1000141 => EmitterFinished{v_1000141}}}
    case AST.TermVar{_, v_117, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_binding{v_3, v_117}}, False{}, v_1000145 => emitter_body_env_binding(v_3, v_117), +v_1000143 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_binding{v_1000143, v_1}}, +v_1000144 => EmitterFinished{v_1000144}}}
    case AST.TermRef{v_123, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_global{v_123, v_3}}, False{}, v_1000148 => emitter_body_js_global(v_123, v_3), +v_1000146 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_global{v_1000146, v_1}}, +v_1000147 => EmitterFinished{v_1000147}}}
    case AST.TermApp{v_130, v_131, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_130, v_3}}, False{}, v_1000154 => emitter_body_js_close(v_130, v_3), +v_1000149 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1000149}}, +v_1000150 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_131, v_3}}, False{}, v_1000153 => emitter_body_js_close(v_131, v_3), +v_1000151 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_app{v_1000150, v_1000151, v_1}}, +v_1000152 => EmitterFinished{v_1000152}}}}}
    case AST.TermSub{v_141, +v_142, v_143, _}:
      v_1000155 = {v_143 : AST.SyntaxTerm}
      v_1000156 = {v_3 : EmitEnv}
      v_1000157 = {v_141 : Nat}
      v_1000158 = {"null" : String}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_142, v_3}}, +v_1000159 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_142, v_3}}, False{}, v_1000165 => emitter_body_js_close(v_142, v_3), +v_1000160 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_insert_binding{v_1000156, v_1000157, EmitBinding{v_1000158, v_1000159, Some{v_1000160}}}}, +v_1000161 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_1000155, v_1000161}}, False{}, v_1000164 => emitter_body_js_close(v_1000155, v_1000161), +v_1000162 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1000162}}, +v_1000163 => EmitterFinished{v_1000163}}}}}}
    case AST.TermLet{_, _, _, v_159, v_160, _}:
      v_1000166 = {v_160 : AST.SyntaxTerm}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_value_env{v_159, v_3}}, +v_1000167 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_1000166, v_1000167}}, False{}, v_1000170 => emitter_body_js_close(v_1000166, v_1000167), +v_1000168 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1000168}}, +v_1000169 => EmitterFinished{v_1000169}}}}
    case AST.BodyReply{v_167, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_167, v_3}}, False{}, v_1000173 => emitter_body_js_close(v_167, v_3), +v_1000171 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1000171}}, +v_1000172 => EmitterFinished{v_1000172}}}
    case AST.BodyLocal{v_176, _, v_178, v_179, _}:
      v_1000174 = {v_176 : List<&2, AST.SyntaxPattern>}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_closure_terms{v_178, v_3}}, +v_1000175 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_patterns{v_1000174, v_1000175, v_3}}, +v_1000176 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_local{v_1000176, v_179, v_1}}, +v_1000177 => EmitterFinished{v_1000177}}}}
    case AST.BodyMatch{v_187, v_188, _}:
      v_1000178 = {v_188 : List<&2, AST.SyntaxTerm>}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_closure_terms{v_187, v_3}}, +v_1000179 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_cases{v_1000178, v_1000179, v_3, v_1}}, +v_1000180 => EmitterFinished{v_1000180}}}
    case AST.TermRewrite{_, _, v_198, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_198, v_3}}, False{}, v_1000183 => emitter_body_js_close(v_198, v_3), +v_1000181 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1000181}}, +v_1000182 => EmitterFinished{v_1000182}}}
    case _:
      EmitterFinished{v_1}

def emitter_match_69(+v_1: EmitClosure, v_3: EmitEnv) -> EmitterProgress<EmitClosure>:
  match v_1:
    case EmitDefinition{_, [], v_13, _, _, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_13, v_3}}, False{}, v_1000134 => emitter_body_js_close(v_13, v_3), +v_1000132 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1000132}}, +v_1000133 => EmitterFinished{v_1000133}}}
    case EmitDefinition{_, _, _, _, _, _, _, _}:
      EmitterFinished{v_1}
    case EmitDeclared{[], AST.SomeTerm{v_43}, _, _, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_43, v_3}}, False{}, v_1000137 => emitter_body_js_close(v_43, v_3), +v_1000135 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1000135}}, +v_1000136 => EmitterFinished{v_1000136}}}
    case EmitDeclared{_, _, _, _, _, _, _}:
      EmitterFinished{v_1}
    case EmitInferred{[], v_71, _, _, _, _, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_71, v_3}}, +v_1000138 => EmitterPending{EmitterRequestGroup_0{EmitterRequest_js_reduce_inferred{v_1000138, v_1}}, +v_1000139 => EmitterFinished{v_1000139}}}
    case EmitInferred{_, _, _, _, _, _, _}:
      EmitterFinished{v_1}
    case EmitClosure{v_99, _, _, _, _, _}:
      emitter_match_68(v_99, v_3, v_1)

def emitter_body_js_reduce_env(v_1: EmitClosure, v_3: EmitEnv) -> EmitterProgress<EmitClosure>:
  emitter_match_69(v_1, v_3)

def emitter_body_js_reduce(+v_1: EmitClosure) -> EmitterProgress<EmitClosure>:
  v_1000184 = {v_1 : EmitClosure}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_1}}, False{}, v_1000187 => emitter_body_js_closure_env(v_1), +v_1000185 => emitter_body_js_reduce_env(v_1000184, v_1000185)}

def emitter_body_js_reduce_inferred(v_2: Maybe<&2, EmitClosure>, v_4: EmitClosure) -> EmitterProgress<EmitClosure>:
  match v_2:
    case Some{v_7}:
      emitter_body_js_reduce(v_7)
    case None{}:
      EmitterFinished{v_4}

def emitter_body_js_reduce_binding(v_2: Maybe<&2, EmitBinding>, v_4: EmitClosure) -> EmitterProgress<EmitClosure>:
  match v_2:
    case Some{EmitBinding{_, _, Some{v_11}}}:
      emitter_body_js_reduce(v_11)
    case _:
      EmitterFinished{v_4}

def emitter_body_js_reduce_global(v_2: Maybe<&2, EmitClosure>, v_4: EmitClosure) -> EmitterProgress<EmitClosure>:
  match v_2:
    case None{}:
      EmitterFinished{v_4}
    case Some{v_7}:
      emitter_body_js_reduce(v_7)

def emitter_match_73(v_1: EmitClosure, v_3: EmitClosure, +v_7: EmitEnv, v_5: EmitClosure) -> EmitterProgress<EmitClosure>:
  match v_1:
    case EmitClosure{AST.TermLam{_, _, _, v_22, _}, _, _, _, _, _}:
      v_1000191 = {v_22 : AST.SyntaxTerm}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{"null", None{}, Some{v_3}, v_7}}, False{}, v_1000196 => emitter_body_env_bind("null", None{}, Some{v_3}, v_7), +v_1000192 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_1000191, v_1000192}}, False{}, v_1000195 => emitter_body_js_close(v_1000191, v_1000192), +v_1000193 => emitter_body_js_reduce(v_1000193)}}
    case EmitDefinition{v_45, AST.Binder{_, _, _, v_49, _} <> v_51, v_52, _, _, _, _, _}:
      v_1000197 = {v_45 : String}
      v_1000198 = {v_51 : List<&2, AST.TelescopeItem>}
      v_1000199 = {v_52 : AST.SyntaxTerm}
      v_1000200 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_49, v_7}}, False{}, v_1000207 => emitter_body_js_close(v_49, v_7), +v_1000201 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1000200, Some{v_1000201}, Some{v_3}, v_7}}, False{}, v_1000206 => emitter_body_env_bind(v_1000200, Some{v_1000201}, Some{v_3}, v_7), +v_1000202 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_definition{v_1000197, v_1000198, v_1000199, v_1000202}}, False{}, v_1000205 => emitter_body_js_close_definition(v_1000197, v_1000198, v_1000199, v_1000202), +v_1000203 => emitter_body_js_reduce(v_1000203)}}}
    case _:
      EmitterFinished{v_5}

def emitter_body_js_reduce_app_env(v_1: EmitClosure, v_3: EmitClosure, v_5: EmitClosure, v_7: EmitEnv) -> EmitterProgress<EmitClosure>:
  emitter_match_73(v_1, v_3, v_7, v_5)

def emitter_body_js_reduce_app(+v_1: EmitClosure, v_3: EmitClosure, v_5: EmitClosure) -> EmitterProgress<EmitClosure>:
  v_1000208 = {v_1 : EmitClosure}
  v_1000209 = {v_3 : EmitClosure}
  v_1000210 = {v_5 : EmitClosure}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_1}}, False{}, v_1000213 => emitter_body_js_closure_env(v_1), +v_1000211 => emitter_body_js_reduce_app_env(v_1000208, v_1000209, v_1000210, v_1000211)}

def emitter_body_js_reduce_patterns(v_1: List<&2, AST.SyntaxPattern>, v_4: List<&2, EmitClosure>, v_6: EmitEnv) -> EmitterProgress<EmitPatternResult>:
  match v_1, v_4:
    case [], []:
      EmitterFinished{EmitMatched{v_6}}
    case +v_12 <> v_13, +v_14 <> v_15:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_pattern{v_12, v_14, v_6}}, +v_1000214 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_patterns_next{v_1000214, v_13, v_15}}, +v_1000215 => EmitterFinished{v_1000215}}}
    case _, _:
      EmitterFinished{EmitDifferent{}}

def emitter_match_75(+v_1: EmitPatternResult, v_3: List<&2, AST.SyntaxPattern>, v_6: List<&2, EmitClosure>) -> EmitterProgress<EmitPatternResult>:
  match v_1:
    case EmitMatched{v_9}:
      emitter_body_js_reduce_patterns(v_3, v_6, v_9)
    case _:
      EmitterFinished{v_1}

def emitter_body_js_reduce_patterns_next(v_1: EmitPatternResult, v_3: List<&2, AST.SyntaxPattern>, v_6: List<&2, EmitClosure>) -> EmitterProgress<EmitPatternResult>:
  emitter_match_75(v_1, v_3, v_6)

def emitter_body_js_reduce_pattern(v_0: AST.SyntaxPattern, v_2: EmitClosure, v_4: EmitEnv) -> EmitterProgress<EmitPatternResult>:
  match v_0:
    case AST.PatternVar{_, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{"null", None{}, Some{v_2}, v_4}}, False{}, v_1000218 => emitter_body_env_bind("null", None{}, Some{v_2}, v_4), +v_1000217 => EmitterFinished{EmitMatched{v_1000217}}}
    case AST.PatternCtr{v_18, v_19, _}:
      v_1000219 = {v_18 : String}
      v_1000220 = {v_19 : List<&2, AST.SyntaxPattern>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_2}}, False{}, v_1000223 => emitter_body_js_reduce(v_2), +v_1000221 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_pattern_view{v_1000219, v_1000220, v_1000221, v_4}}, +v_1000222 => EmitterFinished{v_1000222}}}

def emitter_continuation_77(v_3: List<&2, AST.SyntaxPattern>, v_20: List<&2, AST.SyntaxTerm>, v_9: EmitEnv, +v_1000224: Bool, v_7: EmitEnv) -> EmitterProgress<EmitPatternResult>:
  v_1000225 = {v_3 : List<&2, AST.SyntaxPattern>}
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_closure_terms{v_20, v_9}}, +v_1000226 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_pattern_key{v_1000224, v_1000225, v_1000226, v_7}}, +v_1000227 => EmitterFinished{v_1000227}}}

def emitter_match_78(v_5: EmitClosure, v_1: String, +v_7: EmitEnv, +v_9: EmitEnv, v_3: List<&2, AST.SyntaxPattern>) -> EmitterProgress<EmitPatternResult>:
  match v_5:
    case EmitClosure{AST.TermCtr{v_19, v_20, _}, _, _, _, _, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_same_scoped_key{v_1, v_7, v_19, v_9}}, +v_1000224 => emitter_continuation_77(v_3, v_20, v_9, v_1000224, v_7)}
    case EmitClosure{AST.TermString{v_38, v_39, v_40}, _, _, _, _, _}:
      v_1000228 = {v_1 : String}
      v_1000229 = {v_3 : List<&2, AST.SyntaxPattern>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{AST.string_unfold(v_38, v_39, v_40), v_9}}, False{}, v_1000232 => emitter_body_js_close(AST.string_unfold(v_38, v_39, v_40), v_9), +v_1000230 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_pattern_view{v_1000228, v_1000229, v_1000230, v_7}}, +v_1000231 => EmitterFinished{v_1000231}}}
    case _:
      EmitterFinished{EmitNeutral{}}

def emitter_body_js_reduce_pattern_view_env(v_1: String, v_3: List<&2, AST.SyntaxPattern>, v_5: EmitClosure, v_7: EmitEnv, v_9: EmitEnv) -> EmitterProgress<EmitPatternResult>:
  emitter_match_78(v_5, v_1, v_7, v_9, v_3)

def emitter_body_js_reduce_pattern_view(v_1: String, v_3: List<&2, AST.SyntaxPattern>, +v_5: EmitClosure, v_7: EmitEnv) -> EmitterProgress<EmitPatternResult>:
  v_1000233 = {v_1 : String}
  v_1000234 = {v_3 : List<&2, AST.SyntaxPattern>}
  v_1000235 = {v_5 : EmitClosure}
  v_1000236 = {v_7 : EmitEnv}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_5}}, False{}, v_1000239 => emitter_body_js_closure_env(v_5), +v_1000237 => emitter_body_js_reduce_pattern_view_env(v_1000233, v_1000234, v_1000235, v_1000236, v_1000237)}

def emitter_body_js_same_scoped_key(v_1: String, v_3: EmitEnv, v_5: String, v_7: EmitEnv) -> EmitterProgress<Bool>:
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_1, v_3}}, +v_1000240 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_5, v_7}}, +v_1000241 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_same_constructor_key{v_1000240, v_1000241}}, +v_1000242 => EmitterFinished{v_1000242}}}}

def emitter_body_js_same_constructor_key(v_2: Maybe<&2, EmitConstructor>, v_5: Maybe<&2, EmitConstructor>) -> EmitterProgress<Bool>:
  match v_2, v_5:
    case Some{EmitConstructor{v_17, _, _, _, _}}, Some{EmitConstructor{v_22, _, _, _, _}}:
      EmitterFinished{String.eq(v_17, v_22)}
    case _, _:
      EmitterFinished{False{}}

def emitter_body_js_reduce_pattern_key(v_1: Bool, v_3: List<&2, AST.SyntaxPattern>, v_6: List<&2, EmitClosure>, v_8: EmitEnv) -> EmitterProgress<EmitPatternResult>:
  match v_1:
    case True{}:
      emitter_body_js_reduce_patterns(v_3, v_6, v_8)
    case False{}:
      EmitterFinished{EmitDifferent{}}

def emitter_body_js_reduce_local(v_1: EmitPatternResult, v_2: AST.SyntaxTerm, v_4: EmitClosure) -> EmitterProgress<EmitClosure>:
  match v_1:
    case EmitMatched{v_7}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_2, v_7}}, False{}, v_1000246 => emitter_body_js_close(v_2, v_7), +v_1000244 => emitter_body_js_reduce(v_1000244)}
    case _:
      EmitterFinished{v_4}

def emitter_match_82(v_1: List<&2, AST.SyntaxTerm>, v_8: EmitClosure, +v_4: List<&2, EmitClosure>, +v_6: EmitEnv) -> EmitterProgress<EmitClosure>:
  match v_1:
    case []:
      EmitterFinished{v_8}
    case AST.BodyCase{v_14, v_15, _} <> v_17:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_reduce_patterns{v_14, v_4, v_6}}, False{}, v_1000249 => emitter_body_js_reduce_patterns(v_14, v_4, v_6), +v_1000247 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_case_result{v_1000247, v_15, v_17, v_4, v_6, v_8}}, +v_1000248 => EmitterFinished{v_1000248}}}
    case _ <> v_23:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_reduce_cases{v_23, v_4, v_6, v_8}}, +v_1000250 => EmitterFinished{v_1000250}}

def emitter_body_js_reduce_cases(v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, EmitClosure>, v_6: EmitEnv, v_8: EmitClosure) -> EmitterProgress<EmitClosure>:
  emitter_match_82(v_1, v_8, v_4, v_6)

def emitter_body_js_reduce_case_result(v_1: EmitPatternResult, v_2: AST.SyntaxTerm, v_4: List<&2, AST.SyntaxTerm>, v_7: List<&2, EmitClosure>, v_9: EmitEnv, v_11: EmitClosure) -> EmitterProgress<EmitClosure>:
  match v_1:
    case EmitMatched{v_14}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_2, v_14}}, False{}, v_1000253 => emitter_body_js_close(v_2, v_14), +v_1000251 => emitter_body_js_reduce(v_1000251)}
    case EmitDifferent{}:
      emitter_body_js_reduce_cases(v_4, v_7, v_9, v_11)
    case EmitNeutral{}:
      EmitterFinished{v_11}

def emitter_body_js_value_env(v_1: List<&2, AST.SyntaxTerm>, +v_3: EmitEnv) -> EmitterProgress<EmitEnv>:
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_value_env_at{v_1, v_3, v_3}}, +v_1000255 => EmitterFinished{v_1000255}}

def emitter_match_84(v_1: List<&2, AST.SyntaxTerm>, v_5: EmitEnv, +v_3: EmitEnv) -> EmitterProgress<EmitEnv>:
  match v_1:
    case []:
      EmitterFinished{v_5}
    case +v_9 <> v_10:
      v_1000256 = {v_10 : List<&2, AST.SyntaxTerm>}
      v_1000257 = {v_3 : EmitEnv}
      v_1000258 = {"null" : String}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_9, v_3}}, +v_1000259 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_9, v_3}}, False{}, v_1000264 => emitter_body_js_close(v_9, v_3), +v_1000260 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1000258, v_1000259, Some{v_1000260}, v_5}}, False{}, v_1000263 => emitter_body_env_bind(v_1000258, v_1000259, Some{v_1000260}, v_5), +v_1000261 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_value_env_at{v_1000256, v_1000257, v_1000261}}, +v_1000262 => EmitterFinished{v_1000262}}}}}

def emitter_body_js_value_env_at(v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv, v_5: EmitEnv) -> EmitterProgress<EmitEnv>:
  emitter_match_84(v_1, v_5, v_3)

def emitter_match_85(v_0: AST.SyntaxTerm, +v_2: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_0:
    case AST.TermVar{_, v_9, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_binding{v_2, v_9}}, False{}, v_1000267 => emitter_body_env_binding(v_2, v_9), +v_1000265 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_binding_type{v_1000265}}, +v_1000266 => EmitterFinished{v_1000266}}}
    case AST.TermRef{v_15, _}:
      emitter_body_js_global_type(v_15, v_2)
    case AST.TermAdt{v_22, v_23, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_global_type{v_22, v_2}}, False{}, v_1000272 => emitter_body_js_global_type(v_22, v_2), +v_1000269 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_closure_terms{v_23, v_2}}, +v_1000270 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_apply_type_args{v_1000269, v_1000270}}, +v_1000271 => EmitterFinished{v_1000271}}}}
    case AST.TermAnn{_, v_33, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_33, v_2}}, False{}, v_1000274 => emitter_body_js_close(v_33, v_2), +v_1000273 => EmitterFinished{Some{v_1000273}}}
    case AST.TermBang{v_38, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_38, v_2}}, +v_1000275 => EmitterFinished{v_1000275}}
    case AST.TermPlus{v_43, [], _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_43, v_2}}, +v_1000276 => EmitterFinished{v_1000276}}
    case AST.TermApp{v_49, v_50, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_49, v_2}}, +v_1000277 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_50, v_2}}, False{}, v_1000280 => emitter_body_js_close(v_50, v_2), +v_1000278 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_apply_type{v_1000277, v_1000278}}, +v_1000279 => EmitterFinished{v_1000279}}}}
    case AST.TermSub{v_59, +v_60, v_61, _}:
      v_1000281 = {v_61 : AST.SyntaxTerm}
      v_1000282 = {v_2 : EmitEnv}
      v_1000283 = {v_59 : Nat}
      v_1000284 = {"null" : String}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_60, v_2}}, +v_1000285 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_60, v_2}}, False{}, v_1000289 => emitter_body_js_close(v_60, v_2), +v_1000286 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_insert_binding{v_1000282, v_1000283, EmitBinding{v_1000284, v_1000285, Some{v_1000286}}}}, +v_1000287 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_1000281, v_1000287}}, +v_1000288 => EmitterFinished{v_1000288}}}}}
    case AST.TermLet{_, _, _, v_76, v_77, _}:
      v_1000290 = {v_77 : AST.SyntaxTerm}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_value_env{v_76, v_2}}, False{}, v_1000293 => emitter_body_js_value_env(v_76, v_2), +v_1000291 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_1000290, v_1000291}}, +v_1000292 => EmitterFinished{v_1000292}}}
    case AST.TermRewrite{_, _, v_87, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_87, v_2}}, +v_1000294 => EmitterFinished{v_1000294}}
    case AST.BodyReply{v_92, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_92, v_2}}, +v_1000295 => EmitterFinished{v_1000295}}
    case AST.BodyLocal{v_100, _, v_102, v_103, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type_local{v_100, v_102, v_103, v_2}}, +v_1000296 => EmitterFinished{v_1000296}}
    case AST.BodyMatch{v_109, v_110, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type_cases{v_110, v_109, v_2}}, +v_1000297 => EmitterFinished{v_1000297}}
    case AST.BodyCase{_, v_117, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type{v_117, v_2}}, +v_1000298 => EmitterFinished{v_1000298}}
    case _:
      EmitterFinished{None{}}

def emitter_body_js_type(v_0: AST.SyntaxTerm, v_2: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_85(v_0, v_2)

def emitter_body_js_binding_type(v_2: Maybe<&2, EmitBinding>) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case Some{EmitBinding{_, None{}, Some{v_8}}}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type_value{v_8}}, +v_1000299 => EmitterFinished{v_1000299}}
    case Some{EmitBinding{_, v_14, _}}:
      EmitterFinished{v_14}
    case None{}:
      EmitterFinished{None{}}

def emitter_match_87(+v_1: EmitClosure) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_1:
    case EmitClosure{v_10, _, _, _, _, _}:
      v_1000300 = {v_10 : AST.SyntaxTerm}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_1}}, False{}, v_1000303 => emitter_body_js_closure_env(v_1), +v_1000301 => emitter_body_js_type(v_1000300, v_1000301)}
    case _:
      EmitterFinished{None{}}

def emitter_body_js_type_value(v_1: EmitClosure) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_87(v_1)

def emitter_continuation_88(+v_1000313: EmitPatternResult, v_12: List<&2, Maybe<&2, EmitClosure>>, v_4: AST.SyntaxTerm, v_6: EmitEnv, v_19: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  v_23 = v_1000313
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type_local_refined{v_23, v_12, v_4, v_6, v_19}}, +v_1000314 => EmitterFinished{v_1000314}}

def emitter_continuation_89(+v_1000310: EmitEnv, v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.SyntaxTerm>, +v_6: EmitEnv, v_12: List<&2, Maybe<&2, EmitClosure>>, v_4: AST.SyntaxTerm) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  v_19 = v_1000310
  v_1000311 = {v_1 : List<&2, AST.SyntaxPattern>}
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_closure_terms{v_3, v_6}}, +v_1000312 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_reduce_patterns{v_1000311, v_1000312, v_6}}, False{}, v_1000315 => emitter_body_js_reduce_patterns(v_1000311, v_1000312, v_6), +v_1000313 => emitter_continuation_88(v_1000313, v_12, v_4, v_6, v_19)}}

def emitter_continuation_90(+v_1000309: List<&2, String>, +v_12: List<&2, Maybe<&2, EmitClosure>>, +v_6: EmitEnv, v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  v_16 = v_1000309
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_names_typed{v_16, v_12, v_6}}, +v_1000310 => emitter_continuation_89(v_1000310, v_1, v_3, v_6, v_12, v_4)}

def emitter_continuation_91(+v_1000306: List<&2, Maybe<&2, EmitClosure>>, +v_1: List<&2, AST.SyntaxPattern>, +v_3: List<&2, AST.SyntaxTerm>, +v_6: EmitEnv, v_4: AST.SyntaxTerm) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  v_12 = v_1000306
  v_1000307 = {v_1 : List<&2, AST.SyntaxPattern>}
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_scrutinee_names{List.length(&2, AST.SyntaxTerm, v_3), v_6}}, +v_1000308 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_patterns_vars{v_1000307, v_1000308, v_6}}, +v_1000309 => emitter_continuation_90(v_1000309, v_12, v_6, v_1, v_3, v_4)}}

def emitter_body_js_type_local(+v_1: List<&2, AST.SyntaxPattern>, +v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, +v_6: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  v_1000304 = {v_1 : List<&2, AST.SyntaxPattern>}
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_scrutinee_types{v_3, v_6}}, +v_1000305 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_pattern_types{v_1000304, v_1000305, v_6}}, +v_1000306 => emitter_continuation_91(v_1000306, v_1, v_3, v_6, v_4)}}

def emitter_match_92(v_1: EmitPatternResult, v_8: EmitEnv, v_5: List<&2, Maybe<&2, EmitClosure>>, v_6: AST.SyntaxTerm, v_10: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_1, v_8:
    case EmitMatched{EmitEnv{v_23, v_24, _, v_26, v_27}}, EmitEnv{_, _, v_30, _, _}:
      v_38 = List.append(&2, Maybe<&2, EmitClosure>, List.reverse(&2, Maybe<&2, EmitClosure>, v_5), v_30)
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_6, EmitEnv{v_23, v_24, v_38, v_26, v_27}}}, False{}, v_1000317 => emitter_body_js_type(v_6, EmitEnv{v_23, v_24, v_38, v_26, v_27}), +v_1000316 => EmitterFinished{v_1000316}}
    case _, _:
      emitter_body_js_type(v_6, v_10)

def emitter_body_js_type_local_refined(v_1: EmitPatternResult, v_5: List<&2, Maybe<&2, EmitClosure>>, v_6: AST.SyntaxTerm, v_8: EmitEnv, v_10: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_92(v_1, v_8, v_5, v_6, v_10)

def emitter_match_93(v_5: List<&2, EmitClosure>, v_2: Maybe<&2, EmitClosure>) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_5:
    case []:
      EmitterFinished{v_2}
    case +v_10 <> v_11:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_apply_type{v_2, v_10}}, +v_1000319 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_apply_type_args{v_1000319, v_11}}, +v_1000320 => EmitterFinished{v_1000320}}}

def emitter_body_js_apply_type_args(v_2: Maybe<&2, EmitClosure>, v_5: List<&2, EmitClosure>) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_93(v_5, v_2)

def emitter_body_js_apply_type(v_2: Maybe<&2, EmitClosure>, v_4: EmitClosure) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_8}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_8}}, False{}, v_1000323 => emitter_body_js_reduce(v_8), +v_1000321 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_apply_type_view{v_1000321, v_4}}, +v_1000322 => EmitterFinished{v_1000322}}}

def emitter_match_95(v_1: EmitClosure, +v_5: EmitEnv, v_3: EmitClosure) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_1:
    case EmitClosure{AST.TermAll{_, _, _, v_22, v_23, _}, _, _, _, _, _}:
      v_1000324 = {v_23 : AST.SyntaxTerm}
      v_1000325 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_22, v_5}}, False{}, v_1000331 => emitter_body_js_close(v_22, v_5), +v_1000326 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1000325, Some{v_1000326}, Some{v_3}, v_5}}, False{}, v_1000330 => emitter_body_env_bind(v_1000325, Some{v_1000326}, Some{v_3}, v_5), +v_1000327 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_1000324, v_1000327}}, False{}, v_1000329 => emitter_body_js_close(v_1000324, v_1000327), +v_1000328 => EmitterFinished{Some{v_1000328}}}}}
    case EmitInferred{AST.Binder{_, _, _, v_48, _} <> v_50, v_51, _, _, _, _, _}:
      v_1000332 = {v_50 : List<&2, AST.TelescopeItem>}
      v_1000333 = {v_51 : AST.SyntaxTerm}
      v_1000334 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_48, v_5}}, False{}, v_1000339 => emitter_body_js_close(v_48, v_5), +v_1000335 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1000334, Some{v_1000335}, Some{v_3}, v_5}}, False{}, v_1000338 => emitter_body_env_bind(v_1000334, Some{v_1000335}, Some{v_3}, v_5), +v_1000336 => emitter_body_js_type_definition(v_1000332, v_1000333, v_1000336)}}
    case EmitDeclared{AST.Binder{_, _, _, v_75, _} <> v_77, v_78, _, _, _, _, _}:
      v_1000340 = {v_77 : List<&2, AST.TelescopeItem>}
      v_1000341 = {v_78 : AST.OptionalTerm}
      v_1000342 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_75, v_5}}, False{}, v_1000348 => emitter_body_js_close(v_75, v_5), +v_1000343 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1000342, Some{v_1000343}, Some{v_3}, v_5}}, False{}, v_1000347 => emitter_body_env_bind(v_1000342, Some{v_1000343}, Some{v_3}, v_5), +v_1000344 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_declared{v_1000340, v_1000341, v_1000344}}, False{}, v_1000346 => emitter_body_js_close_declared(v_1000340, v_1000341, v_1000344), +v_1000345 => EmitterFinished{Some{v_1000345}}}}}
    case _:
      EmitterFinished{None{}}

def emitter_body_js_apply_type_view_env(v_1: EmitClosure, v_3: EmitClosure, v_5: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_95(v_1, v_5, v_3)

def emitter_body_js_apply_type_view(+v_1: EmitClosure, v_3: EmitClosure) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  v_1000349 = {v_1 : EmitClosure}
  v_1000350 = {v_3 : EmitClosure}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_1}}, False{}, v_1000353 => emitter_body_js_closure_env(v_1), +v_1000351 => emitter_body_js_apply_type_view_env(v_1000349, v_1000350, v_1000351)}

def emitter_continuation_96(+v_1000356: List<&2, Maybe<&2, EmitClosure>>, v_13: AST.SyntaxTerm, v_12: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.SyntaxTerm>, +v_5: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  v_19 = v_1000356
  v_1000357 = {v_13 : AST.SyntaxTerm}
  v_1000358 = {v_12 : List<&2, AST.SyntaxPattern>}
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_scrutinee_names{List.length(&2, AST.SyntaxTerm, v_3), v_5}}, +v_1000359 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_patterns_vars{v_1000358, v_1000359, v_5}}, +v_1000360 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_names_typed{v_1000360, v_19, v_5}}, +v_1000361 => emitter_body_js_type(v_1000357, v_1000361)}}}

def emitter_match_97(v_1: List<&2, AST.SyntaxTerm>, +v_3: List<&2, AST.SyntaxTerm>, +v_5: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case AST.BodyCase{+v_12, v_13, _} <> _:
      v_1000354 = {v_12 : List<&2, AST.SyntaxPattern>}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_scrutinee_types{v_3, v_5}}, +v_1000355 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_pattern_types{v_1000354, v_1000355, v_5}}, +v_1000356 => emitter_continuation_96(v_1000356, v_13, v_12, v_3, v_5)}}
    case _ <> v_27:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_type_cases{v_27, v_3, v_5}}, +v_1000363 => EmitterFinished{v_1000363}}

def emitter_body_js_type_cases(v_1: List<&2, AST.SyntaxTerm>, v_3: List<&2, AST.SyntaxTerm>, v_5: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_97(v_1, v_3, v_5)

def emitter_match_98(v_1: EmitEnv, v_5: EmitBinding, +v_3: Nat) -> EmitterProgress<EmitEnv>:
  match v_1, v_5:
    case EmitEnv{v_15, v_16, v_17, v_18, v_19}, EmitBinding{v_20, v_21, v_22}:
      v_1000364 = {v_15 : EmitScope}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_insert_names{v_16, v_3, v_20}}, +v_1000365 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_insert_closures{v_17, v_3, v_21}}, +v_1000366 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_insert_closures{v_18, v_3, v_22}}, +v_1000367 => EmitterFinished{EmitEnv{v_1000364, v_1000365, v_1000366, v_1000367, Nat.add(v_19, 1n)}}}}}

def emitter_body_env_insert_binding(v_1: EmitEnv, v_3: Nat, v_5: EmitBinding) -> EmitterProgress<EmitEnv>:
  emitter_match_98(v_1, v_5, v_3)

def emitter_match_99(+v_4: Nat, v_6: String, +v_11: String, v_12: List<&2, String>) -> EmitterProgress<List<&2, String>>:
  match v_4:
    case 0n:
      EmitterFinished{v_6 <> v_11 <> v_12}
    case _:
      v_1000368 = {v_11 : String}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_insert_names{v_12, Nat.sub(v_4, 1n), v_6}}, +v_1000369 => EmitterFinished{v_1000368 <> v_1000369}}

def emitter_match_100(v_2: List<&2, String>, v_6: String, v_4: Nat) -> EmitterProgress<List<&2, String>>:
  match v_2:
    case []:
      EmitterFinished{[v_6]}
    case +v_11 <> v_12:
      emitter_match_99(v_4, v_6, v_11, v_12)

def emitter_body_env_insert_names(v_2: List<&2, String>, v_4: Nat, v_6: String) -> EmitterProgress<List<&2, String>>:
  emitter_match_100(v_2, v_6, v_4)

def emitter_match_101(+v_5: Nat, v_8: Maybe<&2, EmitClosure>, +v_14: Maybe<&2, EmitClosure>, v_15: List<&2, Maybe<&2, EmitClosure>>) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  match v_5:
    case 0n:
      EmitterFinished{v_8 <> v_14 <> v_15}
    case _:
      v_1000370 = {v_14 : Maybe<&2, EmitClosure>}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_insert_closures{v_15, Nat.sub(v_5, 1n), v_8}}, +v_1000371 => EmitterFinished{v_1000370 <> v_1000371}}

def emitter_match_102(v_3: List<&2, Maybe<&2, EmitClosure>>, v_8: Maybe<&2, EmitClosure>, v_5: Nat) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  match v_3:
    case []:
      EmitterFinished{[v_8]}
    case +v_14 <> v_15:
      emitter_match_101(v_5, v_8, v_14, v_15)

def emitter_body_env_insert_closures(v_3: List<&2, Maybe<&2, EmitClosure>>, v_5: Nat, v_8: Maybe<&2, EmitClosure>) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  emitter_match_102(v_3, v_8, v_5)

def emitter_body_env_names_typed(v_2: List<&2, String>, v_6: List<&2, Maybe<&2, EmitClosure>>, v_8: EmitEnv) -> EmitterProgress<EmitEnv>:
  match v_2, v_6:
    case +v_14 <> v_15, +v_16 <> v_17:
      v_1000372 = {v_15 : List<&2, String>}
      v_1000373 = {v_17 : List<&2, Maybe<&2, EmitClosure>>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_14, v_16, None{}, v_8}}, False{}, v_1000376 => emitter_body_env_bind(v_14, v_16, None{}, v_8), +v_1000374 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_names_typed{v_1000372, v_1000373, v_1000374}}, +v_1000375 => EmitterFinished{v_1000375}}}
    case +v_22 <> v_23, []:
      v_1000377 = {v_23 : List<&2, String>}
      v_1000378 = {[] : List<&2, Maybe<&2, EmitClosure>>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_push{v_22, v_8}}, False{}, v_1000381 => emitter_body_env_push(v_22, v_8), +v_1000379 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_env_names_typed{v_1000377, v_1000378, v_1000379}}, +v_1000380 => EmitterFinished{v_1000380}}}
    case [], _:
      EmitterFinished{v_8}

def emitter_match_104(v_1: List<&2, AST.SyntaxTerm>, +v_3: EmitEnv) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  match v_1:
    case []:
      EmitterFinished{[]}
    case +v_9 <> v_10:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_9, v_3}}, False{}, v_1000384 => emitter_body_js_type(v_9, v_3), +v_1000382 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_scrutinee_types{v_10, v_3}}, +v_1000383 => EmitterFinished{v_1000382 <> v_1000383}}}

def emitter_body_js_scrutinee_types(v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  emitter_match_104(v_1, v_3)

def emitter_match_105(v_1: List<&2, AST.SyntaxPattern>, v_5: List<&2, Maybe<&2, EmitClosure>>, +v_7: EmitEnv) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  match v_1, v_5:
    case +v_15 <> v_16, +v_17 <> v_18:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_pattern_type{v_15, v_17, v_7}}, +v_1000385 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_pattern_types{v_16, v_18, v_7}}, +v_1000386 => EmitterFinished{List.append(&2, Maybe<&2, EmitClosure>, v_1000385, v_1000386)}}}
    case +v_25 <> v_26, []:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_pattern_type{v_25, None{}, v_7}}, +v_1000387 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_pattern_types{v_26, [], v_7}}, +v_1000388 => EmitterFinished{List.append(&2, Maybe<&2, EmitClosure>, v_1000387, v_1000388)}}}
    case [], _:
      EmitterFinished{[]}

def emitter_body_js_pattern_types(v_1: List<&2, AST.SyntaxPattern>, v_5: List<&2, Maybe<&2, EmitClosure>>, v_7: EmitEnv) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  emitter_match_105(v_1, v_5, v_7)

def emitter_match_106(v_0: AST.SyntaxPattern, v_3: Maybe<&2, EmitClosure>, +v_5: EmitEnv) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  match v_0:
    case AST.PatternVar{_, _, _, _}:
      EmitterFinished{[v_3]}
    case AST.PatternCtr{v_20, v_21, _}:
      v_1000389 = {v_21 : List<&2, AST.SyntaxPattern>}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_signature{v_20, v_3, v_5}}, +v_1000390 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_field_types{v_1000390}}, +v_1000391 => emitter_body_js_pattern_types(v_1000389, v_1000391, v_5)}}

def emitter_body_js_pattern_type(v_0: AST.SyntaxPattern, v_3: Maybe<&2, EmitClosure>, v_5: EmitEnv) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  emitter_match_106(v_0, v_3, v_5)

def emitter_body_js_field_types(v_2: Maybe<&2, EmitClosure>) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  match v_2:
    case None{}:
      EmitterFinished{[]}
    case Some{v_7}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_7}}, False{}, v_1000395 => emitter_body_js_reduce(v_7), +v_1000393 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_field_types_view{v_1000393}}, +v_1000394 => EmitterFinished{v_1000394}}}

def emitter_continuation_108(v_22: AST.SyntaxTerm, v_21: AST.SyntaxTerm, +v_3: EmitEnv, +v_1000396: EmitClosure) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  v_1000397 = {v_22 : AST.SyntaxTerm}
  v_1000398 = {"null" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_21, v_3}}, False{}, v_1000406 => emitter_body_js_close(v_21, v_3), +v_1000399 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1000398, Some{v_1000399}, None{}, v_3}}, False{}, v_1000405 => emitter_body_env_bind(v_1000398, Some{v_1000399}, None{}, v_3), +v_1000400 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_1000397, v_1000400}}, False{}, v_1000404 => emitter_body_js_close(v_1000397, v_1000400), +v_1000401 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_field_types{Some{v_1000401}}}, False{}, v_1000403 => emitter_body_js_field_types(Some{v_1000401}), +v_1000402 => EmitterFinished{Some{v_1000396} <> v_1000402}}}}}

def emitter_continuation_109(v_51: List<&2, AST.TelescopeItem>, v_52: AST.OptionalTerm, v_49: AST.SyntaxTerm, +v_3: EmitEnv, +v_1000408: EmitClosure) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  v_1000409 = {v_51 : List<&2, AST.TelescopeItem>}
  v_1000410 = {v_52 : AST.OptionalTerm}
  v_1000411 = {"null" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_49, v_3}}, False{}, v_1000419 => emitter_body_js_close(v_49, v_3), +v_1000412 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1000411, Some{v_1000412}, None{}, v_3}}, False{}, v_1000418 => emitter_body_env_bind(v_1000411, Some{v_1000412}, None{}, v_3), +v_1000413 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_declared{v_1000409, v_1000410, v_1000413}}, False{}, v_1000417 => emitter_body_js_close_declared(v_1000409, v_1000410, v_1000413), +v_1000414 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_field_types{Some{v_1000414}}}, False{}, v_1000416 => emitter_body_js_field_types(Some{v_1000414}), +v_1000415 => EmitterFinished{Some{v_1000408} <> v_1000415}}}}}

def emitter_match_110(v_1: EmitClosure, +v_3: EmitEnv) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  match v_1:
    case EmitClosure{AST.TermAll{_, _, _, +v_21, v_22, _}, _, _, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_21, v_3}}, False{}, v_1000407 => emitter_body_js_close(v_21, v_3), +v_1000396 => emitter_continuation_108(v_22, v_21, v_3, v_1000396)}
    case EmitDeclared{AST.Binder{_, _, _, +v_49, _} <> v_51, v_52, _, _, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_49, v_3}}, False{}, v_1000420 => emitter_body_js_close(v_49, v_3), +v_1000408 => emitter_continuation_109(v_51, v_52, v_49, v_3, v_1000408)}
    case _:
      EmitterFinished{[]}

def emitter_body_js_field_types_view_env(v_1: EmitClosure, v_3: EmitEnv) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  emitter_match_110(v_1, v_3)

def emitter_body_js_field_types_view(+v_1: EmitClosure) -> EmitterProgress<List<&2, Maybe<&2, EmitClosure>>>:
  v_1000421 = {v_1 : EmitClosure}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_1}}, False{}, v_1000424 => emitter_body_js_closure_env(v_1), +v_1000422 => emitter_body_js_field_types_view_env(v_1000421, v_1000422)}

def emitter_match_111(+v_11: EmitScope, +v_1: String) -> EmitterProgress<Maybe<&2, EmitConstructor>>:
  match v_11:
    case EmitScope{_, _, +v_21}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_scope_key{v_1, v_11}}, False{}, v_1000428 => emitter_body_js_scope_key(v_1, v_11), +v_1000425 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_lookup{v_1000425, v_21}}, +v_1000426 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_decl_fallback{v_1000426, v_1, v_21}}, +v_1000427 => EmitterFinished{v_1000427}}}}

def emitter_match_112(v_3: EmitEnv, v_1: String) -> EmitterProgress<Maybe<&2, EmitConstructor>>:
  match v_3:
    case EmitEnv{v_11, _, _, _, _}:
      emitter_match_111(v_11, v_1)

def emitter_body_js_constructor_decl(v_1: String, v_3: EmitEnv) -> EmitterProgress<Maybe<&2, EmitConstructor>>:
  emitter_match_112(v_3, v_1)

def emitter_match_113(+v_2: Maybe<&2, EmitConstructor>, v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitConstructor>>:
  match v_2:
    case Some{_}:
      EmitterFinished{v_2}
    case None{}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_lookup{v_4, v_6}}, +v_1000429 => EmitterFinished{v_1000429}}

def emitter_body_js_constructor_decl_fallback(v_2: Maybe<&2, EmitConstructor>, v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitConstructor>>:
  emitter_match_113(v_2, v_4, v_6)

def emitter_match_114(+v_3: EmitCatalog, +v_1: String) -> EmitterProgress<Maybe<&2, EmitConstructor>>:
  match v_3:
    case EmitCatalog{_, _, v_12, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_index_owner{IndexLookup.find(EmitModuleIndex, v_12, v_1), v_1, v_3}}, +v_1000430 => EmitterFinished{v_1000430}}

def emitter_body_js_constructor_lookup(v_1: String, +v_3: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitConstructor>>:
  emitter_match_114(v_3, v_1)

def emitter_match_115(+v_10: EmitModuleIndex, +v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitConstructor>>:
  match v_10:
    case EmitModuleIndex{_, _, _, v_19, _}:
      v_1000431 = {IndexLookup.find(EmitConstructorOwner, v_19, v_4) : Maybe<&2, EmitConstructorOwner>}
      v_1000432 = {v_4 : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_owner_env{v_10, v_6}}, False{}, v_1000435 => emitter_body_js_owner_env(v_10, v_6), +v_1000433 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_owner{v_1000431, v_1000432, v_1000433}}, +v_1000434 => EmitterFinished{v_1000434}}}

def emitter_body_js_constructor_index_owner(v_2: Maybe<&2, EmitModuleIndex>, v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitConstructor>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{+v_10}:
      emitter_match_115(v_10, v_4, v_6)

def emitter_body_js_constructor_owner(v_2: Maybe<&2, EmitConstructorOwner>, v_4: String, v_6: EmitEnv) -> EmitterProgress<Maybe<&2, EmitConstructor>>:
  match v_2:
    case Some{EmitConstructorOwner{AST.TypeDecl{v_17, v_18, _, _, _}, AST.Constructor{_, v_23, _}}}:
      EmitterFinished{Some{EmitConstructor{v_4, v_17, v_18, v_23, v_6}}}
    case None{}:
      EmitterFinished{None{}}

def emitter_body_js_constructor_signature(v_1: String, v_4: Maybe<&2, EmitClosure>, v_6: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_1, v_6}}, False{}, v_1000438 => emitter_body_js_constructor_decl(v_1, v_6), +v_1000436 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_signature_found{v_1000436, v_4}}, +v_1000437 => EmitterFinished{v_1000437}}}

def emitter_body_js_constructor_signature_found(v_2: Maybe<&2, EmitConstructor>, v_5: Maybe<&2, EmitClosure>) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{EmitConstructor{_, _, +v_15, v_16, v_17}}:
      v_1000439 = {v_15 : List<&2, AST.TelescopeItem>}
      v_1000440 = {v_16 : List<&2, AST.TelescopeItem>}
      v_1000441 = {v_17 : EmitEnv}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_parameter_arguments{v_15, v_5}}, +v_1000442 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_parameter_types{v_1000439, v_1000440, v_1000441, v_1000442}}, +v_1000443 => EmitterFinished{v_1000443}}}

def emitter_match_119(v_4: Maybe<&2, EmitClosure>, v_1: List<&2, AST.TelescopeItem>) -> EmitterProgress<List<&2, EmitClosure>>:
  match v_4:
    case None{}:
      EmitterFinished{[]}
    case Some{v_8}:
      v_1000444 = {v_1 : List<&2, AST.TelescopeItem>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_8}}, False{}, v_1000447 => emitter_body_js_reduce(v_8), +v_1000445 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_parameter_view{v_1000444, v_1000445}}, +v_1000446 => EmitterFinished{v_1000446}}}

def emitter_body_js_family_parameter_arguments(v_1: List<&2, AST.TelescopeItem>, v_4: Maybe<&2, EmitClosure>) -> EmitterProgress<List<&2, EmitClosure>>:
  emitter_match_119(v_4, v_1)

def emitter_continuation_120(+v_1000449: List<&2, EmitClosure>, +v_1000450: List<&2, EmitClosure>, v_1: List<&2, AST.TelescopeItem>, v_18: AST.SourceSpan, v_5: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  v_29 = List.append(&2, EmitClosure, v_1000449, v_1000450)
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_fill_arguments{v_1, v_29, AST.QOne{}, v_18, v_5}}, +v_1000451 => EmitterFinished{v_1000451}}

def emitter_continuation_121(+v_1000454: List<&2, EmitClosure>, +v_1000455: List<&2, EmitClosure>, v_1: List<&2, AST.TelescopeItem>, v_41: AST.SourceSpan, v_5: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  v_52 = List.append(&2, EmitClosure, v_1000454, v_1000455)
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_fill_arguments{v_1, v_52, AST.QMany{}, v_41, v_5}}, +v_1000456 => EmitterFinished{v_1000456}}

def emitter_match_122(+v_3: EmitClosure, +v_5: EmitEnv, v_1: List<&2, AST.TelescopeItem>) -> EmitterProgress<List<&2, EmitClosure>>:
  match v_3:
    case EmitClosure{AST.TermFill{v_16, v_17, v_18}, _, _, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_16, v_5}}, False{}, v_1000452 => emitter_body_js_close(v_16, v_5), +v_1000448 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_arguments_view{v_1000448}}, +v_1000449 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_closure_terms{v_17, v_5}}, +v_1000450 => emitter_continuation_120(v_1000449, v_1000450, v_1, v_18, v_5)}}}
    case EmitClosure{AST.TermPlus{v_39, v_40, v_41}, _, _, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_39, v_5}}, False{}, v_1000457 => emitter_body_js_close(v_39, v_5), +v_1000453 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_arguments_view{v_1000453}}, +v_1000454 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_closure_terms{v_40, v_5}}, +v_1000455 => emitter_continuation_121(v_1000454, v_1000455, v_1, v_41, v_5)}}}
    case _:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_arguments_view{v_3}}, +v_1000458 => EmitterFinished{v_1000458}}

def emitter_body_js_family_parameter_view_env(v_1: List<&2, AST.TelescopeItem>, v_3: EmitClosure, v_5: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  emitter_match_122(v_3, v_5, v_1)

def emitter_body_js_family_parameter_view(v_1: List<&2, AST.TelescopeItem>, +v_3: EmitClosure) -> EmitterProgress<List<&2, EmitClosure>>:
  v_1000459 = {v_1 : List<&2, AST.TelescopeItem>}
  v_1000460 = {v_3 : EmitClosure}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_3}}, False{}, v_1000463 => emitter_body_js_closure_env(v_3), +v_1000461 => emitter_body_js_family_parameter_view_env(v_1000459, v_1000460, v_1000461)}

def emitter_match_123(v_1: EmitClosure, +v_3: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  match v_1:
    case EmitClosure{AST.TermAdt{_, v_16, _, _}, _, _, _, _, _}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_closure_terms{v_16, v_3}}, +v_1000464 => EmitterFinished{v_1000464}}
    case EmitClosure{AST.TermApp{v_33, v_34, _}, _, _, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_33, v_3}}, False{}, v_1000469 => emitter_body_js_close(v_33, v_3), +v_1000465 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_arguments_view{v_1000465}}, +v_1000466 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_34, v_3}}, False{}, v_1000468 => emitter_body_js_close(v_34, v_3), +v_1000467 => EmitterFinished{List.append(&2, EmitClosure, v_1000466, [v_1000467])}}}}
    case EmitClosure{AST.TermAnn{v_53, _, _}, _, _, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_53, v_3}}, False{}, v_1000472 => emitter_body_js_close(v_53, v_3), +v_1000470 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_arguments_view{v_1000470}}, +v_1000471 => EmitterFinished{v_1000471}}}
    case _:
      EmitterFinished{[]}

def emitter_body_js_family_arguments_view_env(v_1: EmitClosure, v_3: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  emitter_match_123(v_1, v_3)

def emitter_body_js_family_arguments_view(+v_1: EmitClosure) -> EmitterProgress<List<&2, EmitClosure>>:
  v_1000473 = {v_1 : EmitClosure}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_1}}, False{}, v_1000476 => emitter_body_js_closure_env(v_1), +v_1000474 => emitter_body_js_family_arguments_view_env(v_1000473, v_1000474)}

def emitter_continuation_124(+v_1000477: Nat, +v_4: List<&2, EmitClosure>, v_1: List<&2, AST.TelescopeItem>, v_5: AST.Quantity, v_6: AST.SourceSpan, v_8: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  +v_13 = v_1000477
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_fill_missing{Nat.is_eq(Nat.add(List.length(&2, EmitClosure, v_4), v_13), List.length(&2, AST.TelescopeItem, v_1)), v_4, v_13, v_5, v_6, v_8}}, +v_1000478 => EmitterFinished{v_1000478}}

def emitter_body_js_family_fill_arguments(+v_1: List<&2, AST.TelescopeItem>, v_4: List<&2, EmitClosure>, v_5: AST.Quantity, v_6: AST.SourceSpan, +v_8: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_quant_prefix{v_1, v_8}}, +v_1000477 => emitter_continuation_124(v_1000477, v_4, v_1, v_5, v_6, v_8)}

def emitter_match_125(v_1: List<&2, AST.TelescopeItem>, +v_3: EmitEnv) -> EmitterProgress<Nat>:
  match v_1:
    case AST.Binder{_, _, _, v_14, _} <> v_16:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_14, v_3}}, False{}, v_1000483 => emitter_body_js_close(v_14, v_3), +v_1000479 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1000479}}, False{}, v_1000482 => emitter_body_js_reduce(v_1000479), +v_1000480 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_quant_domain{v_1000480, v_16, v_3}}, +v_1000481 => EmitterFinished{v_1000481}}}}
    case _:
      EmitterFinished{0n}

def emitter_body_js_family_quant_prefix(v_1: List<&2, AST.TelescopeItem>, v_3: EmitEnv) -> EmitterProgress<Nat>:
  emitter_match_125(v_1, v_3)

def emitter_body_js_family_quant_domain(v_1: EmitClosure, v_3: List<&2, AST.TelescopeItem>, v_5: EmitEnv) -> EmitterProgress<Nat>:
  match v_1:
    case EmitClosure{AST.TermQuant{}, _, _, _, _, _}:
      v_1000484 = {1n : Nat}
      v_1000485 = {v_3 : List<&2, AST.TelescopeItem>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_push{"null", v_5}}, False{}, v_1000489 => emitter_body_env_push("null", v_5), +v_1000486 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_family_quant_prefix{v_1000485, v_1000486}}, False{}, v_1000488 => emitter_body_js_family_quant_prefix(v_1000485, v_1000486), +v_1000487 => EmitterFinished{Nat.add(v_1000484, v_1000487)}}}
    case _:
      EmitterFinished{0n}

def emitter_match_127(v_7: AST.Quantity, v_4: List<&2, EmitClosure>, v_6: Nat, v_8: AST.SourceSpan, v_10: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  match v_7:
    case AST.QMany{}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_promote_arguments{v_4, v_6, v_8, v_10}}, +v_1000491 => EmitterFinished{v_1000491}}
    case _:
      EmitterFinished{v_4}

def emitter_match_128(v_1: Bool, v_6: Nat, v_7: AST.Quantity, v_8: AST.SourceSpan, v_10: EmitEnv, v_4: List<&2, EmitClosure>) -> EmitterProgress<List<&2, EmitClosure>>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_quantity_closures{v_6, v_7, v_8, v_10}}, +v_1000490 => EmitterFinished{List.append(&2, EmitClosure, v_1000490, v_4)}}
    case False{}:
      emitter_match_127(v_7, v_4, v_6, v_8, v_10)

def emitter_body_js_family_fill_missing(v_1: Bool, v_4: List<&2, EmitClosure>, v_6: Nat, v_7: AST.Quantity, v_8: AST.SourceSpan, v_10: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  emitter_match_128(v_1, v_6, v_7, v_8, v_10, v_4)

def emitter_match_129(+v_1: Nat, +v_2: AST.Quantity, +v_3: AST.SourceSpan, +v_5: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  match v_1:
    case 0n:
      EmitterFinished{[]}
    case _:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{AST.TermQuantity{v_2, v_3}, v_5}}, False{}, v_1000494 => emitter_body_js_close(AST.TermQuantity{v_2, v_3}, v_5), +v_1000492 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_quantity_closures{Nat.sub(v_1, 1n), v_2, v_3, v_5}}, +v_1000493 => EmitterFinished{v_1000492 <> v_1000493}}}

def emitter_body_js_quantity_closures(v_1: Nat, v_2: AST.Quantity, v_3: AST.SourceSpan, v_5: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  emitter_match_129(v_1, v_2, v_3, v_5)

def emitter_match_130(+v_2: List<&2, EmitClosure>, +v_4: Nat, +v_5: AST.SourceSpan, +v_7: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  match v_2, v_4:
    case _, 0n:
      EmitterFinished{v_2}
    case +_ <> v_16, _:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{AST.TermQuantity{AST.QMany{}, v_5}, v_7}}, False{}, v_1000497 => emitter_body_js_close(AST.TermQuantity{AST.QMany{}, v_5}, v_7), +v_1000495 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_family_promote_arguments{v_16, Nat.sub(v_4, 1n), v_5, v_7}}, +v_1000496 => EmitterFinished{v_1000495 <> v_1000496}}}
    case [], _:
      EmitterFinished{[]}

def emitter_body_js_family_promote_arguments(v_2: List<&2, EmitClosure>, v_4: Nat, v_5: AST.SourceSpan, v_7: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  emitter_match_130(v_2, v_4, v_5, v_7)

def emitter_match_131(v_1: List<&2, AST.SyntaxTerm>, +v_3: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  match v_1:
    case []:
      EmitterFinished{[]}
    case +v_8 <> v_9:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_8, v_3}}, False{}, v_1000500 => emitter_body_js_close(v_8, v_3), +v_1000498 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_closure_terms{v_9, v_3}}, +v_1000499 => EmitterFinished{v_1000498 <> v_1000499}}}

def emitter_body_js_closure_terms(v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv) -> EmitterProgress<List<&2, EmitClosure>>:
  emitter_match_131(v_1, v_3)

def emitter_match_132(v_1: List<&2, AST.TelescopeItem>, v_8: List<&2, EmitClosure>, v_3: List<&2, AST.TelescopeItem>, +v_5: EmitEnv) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  match v_1, v_8:
    case [], _:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_declared{v_3, AST.NoTerm{}, v_5}}, False{}, v_1000502 => emitter_body_js_close_declared(v_3, AST.NoTerm{}, v_5), +v_1000501 => EmitterFinished{Some{v_1000501}}}
    case AST.Binder{_, _, _, v_25, _} <> v_27, +v_28 <> v_29:
      v_1000503 = {v_27 : List<&2, AST.TelescopeItem>}
      v_1000504 = {v_3 : List<&2, AST.TelescopeItem>}
      v_1000505 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_25, v_5}}, False{}, v_1000510 => emitter_body_js_close(v_25, v_5), +v_1000506 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1000505, Some{v_1000506}, Some{v_28}, v_5}}, False{}, v_1000509 => emitter_body_env_bind(v_1000505, Some{v_1000506}, Some{v_28}, v_5), +v_1000507 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_parameter_types{v_1000503, v_1000504, v_1000507, v_29}}, +v_1000508 => EmitterFinished{v_1000508}}}}
    case AST.Binder{_, _, _, v_42, _} <> v_44, []:
      v_1000511 = {v_44 : List<&2, AST.TelescopeItem>}
      v_1000512 = {v_3 : List<&2, AST.TelescopeItem>}
      v_1000513 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_42, v_5}}, False{}, v_1000518 => emitter_body_js_close(v_42, v_5), +v_1000514 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1000513, Some{v_1000514}, None{}, v_5}}, False{}, v_1000517 => emitter_body_env_bind(v_1000513, Some{v_1000514}, None{}, v_5), +v_1000515 => EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_constructor_parameter_types{v_1000511, v_1000512, v_1000515, []}}, +v_1000516 => EmitterFinished{v_1000516}}}}
    case _, _:
      EmitterFinished{None{}}

def emitter_body_js_constructor_parameter_types(v_1: List<&2, AST.TelescopeItem>, v_3: List<&2, AST.TelescopeItem>, v_5: EmitEnv, v_8: List<&2, EmitClosure>) -> EmitterProgress<Maybe<&2, EmitClosure>>:
  emitter_match_132(v_1, v_8, v_3, v_5)

def emitter_body_js_choose(v_1: String, v_3: String, v_5: String, v_7: String) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_key_matches{v_1, v_3}}, +v_1000519 => EmitterFinished{emitter_pure_js_choose_result(v_1000519, v_5, v_7)}}

def emitter_match_133(v_1000521: Bool, v_1: String, v_3: String) -> EmitterProgress<Bool>:
  match v_1000521:
    case False{}:
      EmitterFinished{String.ends_with(v_1, String.append("/", v_3))}
    case True{}:
      EmitterFinished{True{}}

def emitter_match_134(v_1000520: Bool, +v_1: String, +v_3: String) -> EmitterProgress<Bool>:
  match v_1000520:
    case False{}:
      v_1000521 = String.ends_with(v_1, String.append(".", v_3))
      emitter_match_133(v_1000521, v_1, v_3)
    case True{}:
      EmitterFinished{True{}}

def emitter_body_js_key_matches(+v_1: String, +v_3: String) -> EmitterProgress<Bool>:
  v_1000520 = String.eq(v_1, v_3)
  emitter_match_134(v_1000520, v_1, v_3)

def emitter_body_js_choose_exact(v_1: String, v_3: String, v_5: String, v_7: String) -> EmitterProgress<String>:
  EmitterFinished{emitter_pure_js_choose_result(String.eq(v_1, v_3), v_5, v_7)}

def emitter_body_js_choose_result(v_1: Bool, v_3: String, v_5: String) -> EmitterProgress<String>:
  EmitterFinished{emitter_pure_js_choose_result(v_1, v_3, v_5)}

def emitter_body_js_reference(v_1: String) -> EmitterProgress<String>:
  v_1000522 = {"$resolve(" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1000524 => emitter_body_js_quote(v_1), +v_1000523 => EmitterFinished{String.append(v_1000522, String.append(v_1000523, ", $scope, $aliases)"))}}

def emitter_body_js_native_operations(v_1: Bool, v_3: String, v_5: List<&2, AST.TopLevel>) -> EmitterProgress<Map<&2, String>>:
  match v_1:
    case False{}:
      EmitterFinished{MTip{}}
    case True{}:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_native_operation_declarations{v_3, v_5}}, +v_1000525 => EmitterFinished{v_1000525}}

def emitter_match_136(v_3: List<&2, AST.TopLevel>, +v_1: String) -> EmitterProgress<Map<&2, String>>:
  match v_3:
    case []:
      EmitterFinished{MTip{}}
    case AST.DefTop{AST.Definition{v_13, _, _, _, _, _}} <> v_19:
      v_1000526 = {v_1 : String}
      v_1000527 = {v_13 : String}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_native_operation_declarations{v_1, v_19}}, +v_1000528 => EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_insert_keys{v_1000526, v_1000527, v_1000528}}, +v_1000529 => EmitterFinished{v_1000529}}}
    case AST.LawTop{AST.LawDecl{v_27, _, _, _}} <> v_31:
      v_1000530 = {v_1 : String}
      v_1000531 = {v_27 : String}
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_native_operation_declarations{v_1, v_31}}, +v_1000532 => EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_insert_keys{v_1000530, v_1000531, v_1000532}}, +v_1000533 => EmitterFinished{v_1000533}}}
    case _ <> v_37:
      EmitterPending{EmitterRequestGroup_1{EmitterRequest_js_native_operation_declarations{v_1, v_37}}, +v_1000534 => EmitterFinished{v_1000534}}

def emitter_body_js_native_operation_declarations(v_1: String, v_3: List<&2, AST.TopLevel>) -> EmitterProgress<Map<&2, String>>:
  emitter_match_136(v_3, v_1)

def emitter_match_137(+v_1: String, +v_3: String, v_6: Map<&2, String>) -> EmitterProgress<Map<&2, String>>:
  match v_1:
    case "":
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_insert{v_3, v_6}}, +v_1000535 => EmitterFinished{v_1000535}}
    case _:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_1, v_3}}, +v_1000536 => EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_insert{v_3, v_6}}, +v_1000537 => EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_insert{v_1000536, v_1000537}}, +v_1000538 => EmitterFinished{v_1000538}}}}

def emitter_body_js_native_operation_insert_keys(v_1: String, v_3: String, v_6: Map<&2, String>) -> EmitterProgress<Map<&2, String>>:
  emitter_match_137(v_1, v_3, v_6)

def emitter_body_js_native_operation_insert(+v_1: String, v_4: Map<&2, String>) -> EmitterProgress<Map<&2, String>>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_origin{True{}, v_1}}, +v_1000539 => EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_insert_found{v_1000539, v_1, v_4}}, +v_1000540 => EmitterFinished{v_1000540}}}

def emitter_match_138(v_2: Maybe<&2, String>, v_7: Map<&2, String>, v_4: String) -> EmitterProgress<Map<&2, String>>:
  match v_2:
    case None{}:
      EmitterFinished{v_7}
    case Some{v_11}:
      EmitterFinished{Map.set(&2, String, v_7, v_4, v_11)}

def emitter_body_js_native_operation_insert_found(v_2: Maybe<&2, String>, v_4: String, v_7: Map<&2, String>) -> EmitterProgress<Map<&2, String>>:
  emitter_match_138(v_2, v_7, v_4)

def emitter_continuation_139(+v_1000541: String) -> EmitterProgress<Maybe<&2, String>>:
  +v_8 = v_1000541
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_is_native{v_8}}, +v_1000542 => EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_known{v_1000542, v_8}}, +v_1000543 => EmitterFinished{v_1000543}}}

def emitter_body_js_native_operation_origin(v_1: Bool, v_3: String) -> EmitterProgress<Maybe<&2, String>>:
  match v_1:
    case False{}:
      EmitterFinished{None{}}
    case True{}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_name{v_3}}, +v_1000541 => emitter_continuation_139(v_1000541)}

def emitter_match_141(v_3: EmitEnv, v_1: String) -> EmitterProgress<Maybe<&2, String>>:
  match v_3:
    case EmitEnv{EmitScope{_, EmitAliases{_, _, _, v_20}, _}, _, _, _, _}:
      EmitterFinished{IndexLookup.find(String, v_20, v_1)}

def emitter_body_js_native_operation(v_1: String, v_3: EmitEnv) -> EmitterProgress<Maybe<&2, String>>:
  emitter_match_141(v_3, v_1)

def emitter_body_js_native_operation_known(v_1: Bool, v_3: String) -> EmitterProgress<Maybe<&2, String>>:
  match v_1:
    case True{}:
      EmitterFinished{Some{v_3}}
    case False{}:
      EmitterFinished{None{}}

def emitter_body_js_native_operation_name(v_1: String) -> EmitterProgress<String>:
  v_4 = String.to_list(String.to_lower(v_1))
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_chars{v_4, []}}, +v_1000544 => EmitterFinished{String.from_list(List.reverse(&2, Char, v_1000544))}}

def emitter_body_js_native_operation_chars(v_2: List<&2, Char>, v_5: List<&2, Char>) -> EmitterProgress<List<&2, Char>>:
  match v_2:
    case []:
      EmitterFinished{v_5}
    case '.' <> v_9:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_chars{v_9, '_' <> v_5}}, +v_1000545 => EmitterFinished{v_1000545}}
    case '/' <> v_12:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_chars{v_12, '_' <> v_5}}, +v_1000546 => EmitterFinished{v_1000546}}
    case +v_16 <> v_17:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_operation_chars{v_17, v_16 <> v_5}}, +v_1000547 => EmitterFinished{v_1000547}}

def emitter_match_144(v_1000549: Bool, v_1: String, v_5: String) -> EmitterProgress<Bool>:
  match v_1000549:
    case False{}:
      emitter_body_js_key_matches(v_1, v_5)
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_145(+v_1000548: Bool, v_1: String, v_5: String) -> EmitterProgress<Bool>:
  v_1000549 = v_1000548
  emitter_match_144(v_1000549, v_1, v_5)

def emitter_body_suffix_any(+v_1: String, v_3: String, v_5: String) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_key_matches{v_1, v_3}}, False{}, v_1000551 => emitter_body_js_key_matches(v_1, v_3), +v_1000548 => emitter_continuation_145(v_1000548, v_1, v_5)}

def emitter_match_146(v_1000553: Bool, v_1: String) -> EmitterProgress<Bool>:
  match v_1000553:
    case False{}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_u32_2{v_1}}, +v_1000554 => EmitterFinished{v_1000554}}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_147(+v_1000552: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000553 = v_1000552
  emitter_match_146(v_1000553, v_1)

def emitter_body_js_native_u32(+v_1: String) -> EmitterProgress<Bool>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_u32_1{v_1}}, +v_1000552 => emitter_continuation_147(v_1000552, v_1)}

def emitter_match_148(v_1000564: Bool, v_1: String) -> EmitterProgress<Bool>:
  match v_1000564:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_is_lt", "u32_is_le"}}, False{}, v_1000566 => emitter_body_suffix_any(v_1, "u32_is_lt", "u32_is_le"), +v_1000565 => EmitterFinished{v_1000565}}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_149(+v_1000563: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000564 = v_1000563
  emitter_match_148(v_1000564, v_1)

def emitter_match_150(v_1000562: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000562:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_is_eq", "u32_is_ne"}}, False{}, v_1000567 => emitter_body_suffix_any(v_1, "u32_is_eq", "u32_is_ne"), +v_1000563 => emitter_continuation_149(v_1000563, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_151(+v_1000561: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000562 = v_1000561
  emitter_match_150(v_1000562, v_1)

def emitter_match_152(v_1000560: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000560:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_or", "u32_xor"}}, False{}, v_1000568 => emitter_body_suffix_any(v_1, "u32_or", "u32_xor"), +v_1000561 => emitter_continuation_151(v_1000561, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_153(+v_1000559: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000560 = v_1000559
  emitter_match_152(v_1000560, v_1)

def emitter_match_154(v_1000558: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000558:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_mod", "u32_and"}}, False{}, v_1000569 => emitter_body_suffix_any(v_1, "u32_mod", "u32_and"), +v_1000559 => emitter_continuation_153(v_1000559, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_155(+v_1000557: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000558 = v_1000557
  emitter_match_154(v_1000558, v_1)

def emitter_match_156(v_1000556: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000556:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_mul", "u32_div"}}, False{}, v_1000570 => emitter_body_suffix_any(v_1, "u32_mul", "u32_div"), +v_1000557 => emitter_continuation_155(v_1000557, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_157(+v_1000555: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000556 = v_1000555
  emitter_match_156(v_1000556, v_1)

def emitter_body_js_native_u32_1(+v_1: String) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_add", "u32_sub"}}, False{}, v_1000571 => emitter_body_suffix_any(v_1, "u32_add", "u32_sub"), +v_1000555 => emitter_continuation_157(v_1000555, v_1)}

def emitter_match_158(v_1000583: Bool, v_1: String) -> EmitterProgress<Bool>:
  match v_1000583:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_to_f32", "u32_to_f32"}}, False{}, v_1000585 => emitter_body_suffix_any(v_1, "u32_to_f32", "u32_to_f32"), +v_1000584 => EmitterFinished{v_1000584}}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_159(+v_1000582: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000583 = v_1000582
  emitter_match_158(v_1000583, v_1)

def emitter_match_160(v_1000581: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000581:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_to_nat", "u32_from_nat"}}, False{}, v_1000586 => emitter_body_suffix_any(v_1, "u32_to_nat", "u32_from_nat"), +v_1000582 => emitter_continuation_159(v_1000582, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_161(+v_1000580: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000581 = v_1000580
  emitter_match_160(v_1000581, v_1)

def emitter_match_162(v_1000579: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000579:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_cmp", "u32_is_zero"}}, False{}, v_1000587 => emitter_body_suffix_any(v_1, "u32_cmp", "u32_is_zero"), +v_1000580 => emitter_continuation_161(v_1000580, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_163(+v_1000578: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000579 = v_1000578
  emitter_match_162(v_1000579, v_1)

def emitter_match_164(v_1000577: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000577:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_shln", "u32_shrn"}}, False{}, v_1000588 => emitter_body_suffix_any(v_1, "u32_shln", "u32_shrn"), +v_1000578 => emitter_continuation_163(v_1000578, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_165(+v_1000576: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000577 = v_1000576
  emitter_match_164(v_1000577, v_1)

def emitter_match_166(v_1000575: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000575:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_shl", "u32_shr"}}, False{}, v_1000589 => emitter_body_suffix_any(v_1, "u32_shl", "u32_shr"), +v_1000576 => emitter_continuation_165(v_1000576, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_167(+v_1000574: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000575 = v_1000574
  emitter_match_166(v_1000575, v_1)

def emitter_match_168(v_1000573: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000573:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_inc", "u32_not"}}, False{}, v_1000590 => emitter_body_suffix_any(v_1, "u32_inc", "u32_not"), +v_1000574 => emitter_continuation_167(v_1000574, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_169(+v_1000572: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000573 = v_1000572
  emitter_match_168(v_1000573, v_1)

def emitter_body_js_native_u32_2(+v_1: String) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_is_gt", "u32_is_ge"}}, False{}, v_1000591 => emitter_body_suffix_any(v_1, "u32_is_gt", "u32_is_ge"), +v_1000572 => emitter_continuation_169(v_1000572, v_1)}

def emitter_match_170(v_1000593: Bool, v_1: String) -> EmitterProgress<Bool>:
  match v_1000593:
    case False{}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_f32_2{v_1}}, +v_1000594 => EmitterFinished{v_1000594}}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_171(+v_1000592: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000593 = v_1000592
  emitter_match_170(v_1000593, v_1)

def emitter_body_js_native_f32(+v_1: String) -> EmitterProgress<Bool>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_f32_1{v_1}}, +v_1000592 => emitter_continuation_171(v_1000592, v_1)}

def emitter_match_172(v_1000608: Bool, v_1: String) -> EmitterProgress<Bool>:
  match v_1000608:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_exp", "f32_log"}}, False{}, v_1000610 => emitter_body_suffix_any(v_1, "f32_exp", "f32_log"), +v_1000609 => EmitterFinished{v_1000609}}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_173(+v_1000607: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000608 = v_1000607
  emitter_match_172(v_1000608, v_1)

def emitter_match_174(v_1000606: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000606:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_sqrt", "f32_abs"}}, False{}, v_1000611 => emitter_body_suffix_any(v_1, "f32_sqrt", "f32_abs"), +v_1000607 => emitter_continuation_173(v_1000607, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_175(+v_1000605: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000606 = v_1000605
  emitter_match_174(v_1000606, v_1)

def emitter_match_176(v_1000604: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000604:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_is_gt", "f32_is_ge"}}, False{}, v_1000612 => emitter_body_suffix_any(v_1, "f32_is_gt", "f32_is_ge"), +v_1000605 => emitter_continuation_175(v_1000605, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_177(+v_1000603: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000604 = v_1000603
  emitter_match_176(v_1000604, v_1)

def emitter_match_178(v_1000602: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000602:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_is_lt", "f32_is_le"}}, False{}, v_1000613 => emitter_body_suffix_any(v_1, "f32_is_lt", "f32_is_le"), +v_1000603 => emitter_continuation_177(v_1000603, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_179(+v_1000601: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000602 = v_1000601
  emitter_match_178(v_1000602, v_1)

def emitter_match_180(v_1000600: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000600:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_is_eq", "f32_is_ne"}}, False{}, v_1000614 => emitter_body_suffix_any(v_1, "f32_is_eq", "f32_is_ne"), +v_1000601 => emitter_continuation_179(v_1000601, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_181(+v_1000599: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000600 = v_1000599
  emitter_match_180(v_1000600, v_1)

def emitter_match_182(v_1000598: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000598:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_mod", "f32_neg"}}, False{}, v_1000615 => emitter_body_suffix_any(v_1, "f32_mod", "f32_neg"), +v_1000599 => emitter_continuation_181(v_1000599, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_183(+v_1000597: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000598 = v_1000597
  emitter_match_182(v_1000598, v_1)

def emitter_match_184(v_1000596: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000596:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_mul", "f32_div"}}, False{}, v_1000616 => emitter_body_suffix_any(v_1, "f32_mul", "f32_div"), +v_1000597 => emitter_continuation_183(v_1000597, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_185(+v_1000595: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000596 = v_1000595
  emitter_match_184(v_1000596, v_1)

def emitter_body_js_native_f32_1(+v_1: String) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_add", "f32_sub"}}, False{}, v_1000617 => emitter_body_suffix_any(v_1, "f32_add", "f32_sub"), +v_1000595 => emitter_continuation_185(v_1000595, v_1)}

def emitter_match_186(v_1000633: Bool, v_1: String) -> EmitterProgress<Bool>:
  match v_1000633:
    case False{}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_f32_extra{v_1}}, +v_1000634 => EmitterFinished{v_1000634}}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_187(+v_1000632: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000633 = v_1000632
  emitter_match_186(v_1000633, v_1)

def emitter_match_188(v_1000631: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000631:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "u32_to_f32", "u32_to_f32"}}, False{}, v_1000635 => emitter_body_suffix_any(v_1, "u32_to_f32", "u32_to_f32"), +v_1000632 => emitter_continuation_187(v_1000632, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_189(+v_1000630: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000631 = v_1000630
  emitter_match_188(v_1000631, v_1)

def emitter_match_190(v_1000629: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000629:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_show", "f32_read"}}, False{}, v_1000636 => emitter_body_suffix_any(v_1, "f32_show", "f32_read"), +v_1000630 => emitter_continuation_189(v_1000630, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_191(+v_1000628: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000629 = v_1000628
  emitter_match_190(v_1000629, v_1)

def emitter_match_192(v_1000627: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000627:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_to_u32", "f32_bits"}}, False{}, v_1000637 => emitter_body_suffix_any(v_1, "f32_to_u32", "f32_bits"), +v_1000628 => emitter_continuation_191(v_1000628, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_193(+v_1000626: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000627 = v_1000626
  emitter_match_192(v_1000627, v_1)

def emitter_match_194(v_1000625: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000625:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_ceil", "f32_trunc"}}, False{}, v_1000638 => emitter_body_suffix_any(v_1, "f32_ceil", "f32_trunc"), +v_1000626 => emitter_continuation_193(v_1000626, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_195(+v_1000624: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000625 = v_1000624
  emitter_match_194(v_1000625, v_1)

def emitter_match_196(v_1000623: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000623:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_atan2", "f32_floor"}}, False{}, v_1000639 => emitter_body_suffix_any(v_1, "f32_atan2", "f32_floor"), +v_1000624 => emitter_continuation_195(v_1000624, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_197(+v_1000622: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000623 = v_1000622
  emitter_match_196(v_1000623, v_1)

def emitter_match_198(v_1000621: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000621:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_tan", "f32_pow"}}, False{}, v_1000640 => emitter_body_suffix_any(v_1, "f32_tan", "f32_pow"), +v_1000622 => emitter_continuation_197(v_1000622, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_199(+v_1000620: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000621 = v_1000620
  emitter_match_198(v_1000621, v_1)

def emitter_match_200(v_1000619: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000619:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_sin", "f32_cos"}}, False{}, v_1000641 => emitter_body_suffix_any(v_1, "f32_sin", "f32_cos"), +v_1000620 => emitter_continuation_199(v_1000620, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_201(+v_1000618: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000619 = v_1000618
  emitter_match_200(v_1000619, v_1)

def emitter_body_js_native_f32_2(+v_1: String) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_log2", "f32_log10"}}, False{}, v_1000642 => emitter_body_suffix_any(v_1, "f32_log2", "f32_log10"), +v_1000618 => emitter_continuation_201(v_1000618, v_1)}

def emitter_match_202(v_1000646: Bool, v_1: String) -> EmitterProgress<Bool>:
  match v_1000646:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_cosh", "f32_tanh"}}, False{}, v_1000648 => emitter_body_suffix_any(v_1, "f32_cosh", "f32_tanh"), +v_1000647 => EmitterFinished{v_1000647}}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_203(+v_1000645: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000646 = v_1000645
  emitter_match_202(v_1000646, v_1)

def emitter_match_204(v_1000644: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000644:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_atan", "f32_sinh"}}, False{}, v_1000649 => emitter_body_suffix_any(v_1, "f32_atan", "f32_sinh"), +v_1000645 => emitter_continuation_203(v_1000645, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_205(+v_1000643: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000644 = v_1000643
  emitter_match_204(v_1000644, v_1)

def emitter_body_js_native_f32_extra(+v_1: String) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "f32_asin", "f32_acos"}}, False{}, v_1000650 => emitter_body_suffix_any(v_1, "f32_asin", "f32_acos"), +v_1000643 => emitter_continuation_205(v_1000643, v_1)}

def emitter_match_206(v_1000652: Bool, v_1: String) -> EmitterProgress<Bool>:
  match v_1000652:
    case False{}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_misc_2{v_1}}, +v_1000653 => EmitterFinished{v_1000653}}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_207(+v_1000651: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000652 = v_1000651
  emitter_match_206(v_1000652, v_1)

def emitter_body_js_native_misc(+v_1: String) -> EmitterProgress<Bool>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_misc_1{v_1}}, +v_1000651 => emitter_continuation_207(v_1000651, v_1)}

def emitter_match_208(v_1000664: Bool, v_1: String, +v_1000654: Bool, +v_1000655: Bool, +v_1000656: Bool) -> EmitterProgress<Bool>:
  match v_1000664:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "string_length", "bool_or"}}, False{}, v_1000666 => emitter_body_suffix_any(v_1, "string_length", "bool_or"), +v_1000665 => EmitterFinished{Bool.or(v_1000654, Bool.or(v_1000655, Bool.or(v_1000656, v_1000665)))}}
    case True{}:
      EmitterFinished{Bool.or(v_1000654, Bool.or(v_1000655, Bool.or(v_1000656, True{})))}

def emitter_continuation_209(+v_1000663: Bool, v_1: String, +v_1000654: Bool, +v_1000655: Bool, +v_1000656: Bool) -> EmitterProgress<Bool>:
  v_1000664 = v_1000663
  emitter_match_208(v_1000664, v_1, v_1000654, v_1000655, v_1000656)

def emitter_match_210(v_1000662: Bool, +v_1: String, +v_1000654: Bool, +v_1000655: Bool, +v_1000656: Bool) -> EmitterProgress<Bool>:
  match v_1000662:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "nat_divmod", "string_append"}}, False{}, v_1000667 => emitter_body_suffix_any(v_1, "nat_divmod", "string_append"), +v_1000663 => emitter_continuation_209(v_1000663, v_1, v_1000654, v_1000655, v_1000656)}
    case True{}:
      EmitterFinished{Bool.or(v_1000654, Bool.or(v_1000655, Bool.or(v_1000656, True{})))}

def emitter_continuation_211(+v_1000661: Bool, v_1: String, +v_1000654: Bool, +v_1000655: Bool, +v_1000656: Bool) -> EmitterProgress<Bool>:
  v_1000662 = v_1000661
  emitter_match_210(v_1000662, v_1, v_1000654, v_1000655, v_1000656)

def emitter_match_212(v_1000660: Bool, +v_1: String, +v_1000654: Bool, +v_1000655: Bool, +v_1000656: Bool) -> EmitterProgress<Bool>:
  match v_1000660:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "nat_cmp", "nat_is_lt"}}, False{}, v_1000668 => emitter_body_suffix_any(v_1, "nat_cmp", "nat_is_lt"), +v_1000661 => emitter_continuation_211(v_1000661, v_1, v_1000654, v_1000655, v_1000656)}
    case True{}:
      EmitterFinished{Bool.or(v_1000654, Bool.or(v_1000655, Bool.or(v_1000656, True{})))}

def emitter_continuation_213(+v_1000659: Bool, v_1: String, +v_1000654: Bool, +v_1000655: Bool, +v_1000656: Bool) -> EmitterProgress<Bool>:
  v_1000660 = v_1000659
  emitter_match_212(v_1000660, v_1, v_1000654, v_1000655, v_1000656)

def emitter_match_214(v_1000658: Bool, +v_1: String, +v_1000654: Bool, +v_1000655: Bool, +v_1000656: Bool) -> EmitterProgress<Bool>:
  match v_1000658:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "nat_mul", "nat_double"}}, False{}, v_1000669 => emitter_body_suffix_any(v_1, "nat_mul", "nat_double"), +v_1000659 => emitter_continuation_213(v_1000659, v_1, v_1000654, v_1000655, v_1000656)}
    case True{}:
      EmitterFinished{Bool.or(v_1000654, Bool.or(v_1000655, Bool.or(v_1000656, True{})))}

def emitter_continuation_215(+v_1000657: Bool, v_1: String, +v_1000654: Bool, +v_1000655: Bool, +v_1000656: Bool) -> EmitterProgress<Bool>:
  v_1000658 = v_1000657
  emitter_match_214(v_1000658, v_1, v_1000654, v_1000655, v_1000656)

def emitter_body_js_native_misc_1(+v_1: String) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "nat_min", "nat_max"}}, False{}, v_1000673 => emitter_body_suffix_any(v_1, "nat_min", "nat_max"), +v_1000654 => EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "map_bit", "string_cmp"}}, False{}, v_1000672 => emitter_body_suffix_any(v_1, "map_bit", "string_cmp"), +v_1000655 => EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "string_to_list", "string_eq"}}, False{}, v_1000671 => emitter_body_suffix_any(v_1, "string_to_list", "string_eq"), +v_1000656 => EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "nat_add", "nat_sub"}}, False{}, v_1000670 => emitter_body_suffix_any(v_1, "nat_add", "nat_sub"), +v_1000657 => emitter_continuation_215(v_1000657, v_1, v_1000654, v_1000655, v_1000656)}}}}

def emitter_match_216(v_1000679: Bool, v_1: String) -> EmitterProgress<Bool>:
  match v_1000679:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "array_clone", "array_clone"}}, False{}, v_1000681 => emitter_body_suffix_any(v_1, "array_clone", "array_clone"), +v_1000680 => EmitterFinished{v_1000680}}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_217(+v_1000678: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000679 = v_1000678
  emitter_match_216(v_1000679, v_1)

def emitter_match_218(v_1000677: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000677:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "array_swap", "array_size"}}, False{}, v_1000682 => emitter_body_suffix_any(v_1, "array_swap", "array_size"), +v_1000678 => emitter_continuation_217(v_1000678, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_219(+v_1000676: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000677 = v_1000676
  emitter_match_218(v_1000677, v_1)

def emitter_match_220(v_1000675: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000675:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "array_set", "array_get"}}, False{}, v_1000683 => emitter_body_suffix_any(v_1, "array_set", "array_get"), +v_1000676 => emitter_continuation_219(v_1000676, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_221(+v_1000674: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000675 = v_1000674
  emitter_match_220(v_1000675, v_1)

def emitter_body_js_native_misc_2(+v_1: String) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_suffix_any{v_1, "bool_xor", "array_new"}}, False{}, v_1000684 => emitter_body_suffix_any(v_1, "bool_xor", "array_new"), +v_1000674 => emitter_continuation_221(v_1000674, v_1)}

def emitter_match_222(v_1000688: Bool, v_1: String) -> EmitterProgress<Bool>:
  match v_1000688:
    case False{}:
      emitter_body_js_native_misc(v_1)
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_223(+v_1000687: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000688 = v_1000687
  emitter_match_222(v_1000688, v_1)

def emitter_match_224(v_1000686: Bool, +v_1: String) -> EmitterProgress<Bool>:
  match v_1000686:
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_f32{v_1}}, False{}, v_1000690 => emitter_body_js_native_f32(v_1), +v_1000687 => emitter_continuation_223(v_1000687, v_1)}
    case True{}:
      EmitterFinished{True{}}

def emitter_continuation_225(+v_1000685: Bool, v_1: String) -> EmitterProgress<Bool>:
  v_1000686 = v_1000685
  emitter_match_224(v_1000686, v_1)

def emitter_body_js_is_native(+v_1: String) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_u32{v_1}}, False{}, v_1000691 => emitter_body_js_native_u32(v_1), +v_1000685 => emitter_continuation_225(v_1000685, v_1)}

def emitter_body_js_native_primitive(v_1: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_old{v_1}}, +v_1000692 => EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_shape{v_1000692}}, +v_1000693 => EmitterFinished{v_1000693}}}

def emitter_body_js_native_primitive_shape(+v_1: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_shape_match{String.starts_with(v_1, "(a)=>(i)=>(v)=>"), v_1}}, +v_1000694 => EmitterFinished{v_1000694}}

def emitter_body_js_native_primitive_shape_match(v_1: Bool, v_3: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  match v_1:
    case True{}:
      EmitterFinished{Some{EmitPrimitive{["a", "i", "v"], String.drop(v_3, 15n)}}}
    case False{}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_binary{v_3}}, +v_1000695 => EmitterFinished{v_1000695}}

def emitter_body_js_native_primitive_binary(+v_1: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_binary_match{String.starts_with(v_1, "(a)=>(b)=>"), v_1}}, +v_1000696 => EmitterFinished{v_1000696}}

def emitter_body_js_native_primitive_binary_match(v_1: Bool, v_3: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  match v_1:
    case True{}:
      EmitterFinished{Some{EmitPrimitive{["a", "b"], String.drop(v_3, 10n)}}}
    case False{}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_indexed{v_3}}, +v_1000697 => EmitterFinished{v_1000697}}

def emitter_body_js_native_primitive_indexed(+v_1: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_indexed_match{String.starts_with(v_1, "(a)=>(i)=>"), v_1}}, +v_1000698 => EmitterFinished{v_1000698}}

def emitter_body_js_native_primitive_indexed_match(v_1: Bool, v_3: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  match v_1:
    case True{}:
      EmitterFinished{Some{EmitPrimitive{["a", "i"], String.drop(v_3, 10n)}}}
    case False{}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_position{v_3}}, +v_1000699 => EmitterFinished{v_1000699}}

def emitter_body_js_native_primitive_position(+v_1: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_position_match{String.starts_with(v_1, "(key)=>(position)=>"), v_1}}, +v_1000700 => EmitterFinished{v_1000700}}

def emitter_body_js_native_primitive_position_match(v_1: Bool, v_3: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  match v_1:
    case True{}:
      EmitterFinished{Some{EmitPrimitive{["key", "position"], String.drop(v_3, 19n)}}}
    case False{}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_unary{v_3}}, +v_1000701 => EmitterFinished{v_1000701}}

def emitter_body_js_native_primitive_unary(+v_1: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_unary_match{String.starts_with(v_1, "(a)=>"), v_1}}, +v_1000702 => EmitterFinished{v_1000702}}

def emitter_body_js_native_primitive_unary_match(v_1: Bool, v_3: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  match v_1:
    case True{}:
      EmitterFinished{Some{EmitPrimitive{["a"], String.drop(v_3, 5n)}}}
    case False{}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_text{v_3}}, +v_1000703 => EmitterFinished{v_1000703}}

def emitter_body_js_native_primitive_text(+v_1: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_text_match{String.starts_with(v_1, "(text)=>"), v_1}}, +v_1000704 => EmitterFinished{v_1000704}}

def emitter_body_js_native_primitive_text_match(v_1: Bool, v_3: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  match v_1:
    case True{}:
      EmitterFinished{Some{EmitPrimitive{["text"], String.drop(v_3, 8n)}}}
    case False{}:
      EmitterFinished{None{}}

def emitter_body_js_native_primitive_binders(v_1: List<&2, AST.TelescopeItem>) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_1:
    case []:
      EmitterFinished{Some{0n}}
    case AST.Binder{v_10, _, _, _, _} <> v_15:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_binders{v_15}}, +v_1000705 => EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_count{v_1000705, v_10}}, +v_1000706 => EmitterFinished{v_1000706}}}
    case AST.TemplateBinder{_, _, _, _} <> _:
      EmitterFinished{None{}}

def emitter_body_js_native_primitive_count(v_2: Maybe<&2, Nat>, v_3: AST.Quantity) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_2, v_3:
    case Some{v_7}, AST.QZero{}:
      EmitterFinished{Some{v_7}}
    case Some{v_10}, _:
      EmitterFinished{Some{Nat.add(v_10, 1n)}}
    case None{}, _:
      EmitterFinished{None{}}

def emitter_body_js_native_primitive_checked(v_2: Maybe<&2, String>, v_4: List<&2, AST.TelescopeItem>) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_8}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_primitive{v_8}}, False{}, v_1000711 => emitter_body_js_native_primitive(v_8), +v_1000707 => EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_primitive_binders{v_4}}, False{}, v_1000710 => emitter_body_js_native_primitive_binders(v_4), +v_1000708 => EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_arity{v_1000707, v_1000708}}, +v_1000709 => EmitterFinished{v_1000709}}}}

def emitter_body_js_native_primitive_arity(v_2: Maybe<&2, EmitPrimitive>, v_5: Maybe<&2, Nat>) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  match v_2, v_5:
    case Some{EmitPrimitive{+v_11, v_12}}, Some{v_13}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_native_primitive_arity_match{Nat.is_eq(List.length(&2, String, v_11), v_13), v_11, v_12}}, +v_1000712 => EmitterFinished{v_1000712}}
    case _, _:
      EmitterFinished{None{}}

def emitter_body_js_native_primitive_arity_match(v_1: Bool, v_4: List<&2, String>, v_6: String) -> EmitterProgress<Maybe<&2, EmitPrimitive>>:
  match v_1:
    case True{}:
      EmitterFinished{Some{EmitPrimitive{v_4, v_6}}}
    case False{}:
      EmitterFinished{None{}}

def emitter_body_js_reference_old(+v_1: String) -> EmitterProgress<String>:
  v_1000713 = {v_1 : String}
  v_1000714 = {"u32_add" : String}
  v_1000715 = {"(a)=>(b)=>((a+b)>>>0)" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_2{v_1}}, +v_1000716 => emitter_body_js_choose(v_1000713, v_1000714, v_1000715, v_1000716)}

def emitter_body_js_reference_2(+v_1: String) -> EmitterProgress<String>:
  v_1000718 = {v_1 : String}
  v_1000719 = {"u32_sub" : String}
  v_1000720 = {"(a)=>(b)=>((a-b)>>>0)" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_3{v_1}}, +v_1000721 => emitter_body_js_choose(v_1000718, v_1000719, v_1000720, v_1000721)}

def emitter_body_js_reference_3(+v_1: String) -> EmitterProgress<String>:
  v_1000723 = {v_1 : String}
  v_1000724 = {"u32_mul" : String}
  v_1000725 = {"(a)=>(b)=>(Math.imul(a,b)>>>0)" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_4{v_1}}, +v_1000726 => emitter_body_js_choose(v_1000723, v_1000724, v_1000725, v_1000726)}

def emitter_body_js_reference_4(+v_1: String) -> EmitterProgress<String>:
  v_1000728 = {v_1 : String}
  v_1000729 = {"u32_div" : String}
  v_1000730 = {"(a)=>(b)=>(b===0?0:(a/b)>>>0)" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_5{v_1}}, +v_1000731 => emitter_body_js_choose(v_1000728, v_1000729, v_1000730, v_1000731)}

def emitter_body_js_reference_5(+v_1: String) -> EmitterProgress<String>:
  v_1000733 = {v_1 : String}
  v_1000734 = {"nat_add" : String}
  v_1000735 = {"(a)=>(b)=>nat_chk(a+b)" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_6{v_1}}, +v_1000736 => emitter_body_js_choose(v_1000733, v_1000734, v_1000735, v_1000736)}

def emitter_body_js_reference_6(+v_1: String) -> EmitterProgress<String>:
  v_1000738 = {v_1 : String}
  v_1000739 = {"nat_sub" : String}
  v_1000740 = {"(a)=>(b)=>(a<b?0:a-b)" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_7{v_1}}, +v_1000741 => emitter_body_js_choose(v_1000738, v_1000739, v_1000740, v_1000741)}

def emitter_body_js_reference_7(+v_1: String) -> EmitterProgress<String>:
  v_1000743 = {v_1 : String}
  v_1000744 = {"nat_mul" : String}
  v_1000745 = {"(a)=>(b)=>nat_chk(a*b)" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_8{v_1}}, +v_1000746 => emitter_body_js_choose(v_1000743, v_1000744, v_1000745, v_1000746)}

def emitter_body_js_reference_8(+v_1: String) -> EmitterProgress<String>:
  v_1000748 = {v_1 : String}
  v_1000749 = {"nat_cmp" : String}
  v_1000750 = {"(a)=>(b)=>cmp_new(a,b)" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_nat_bounds{v_1}}, +v_1000751 => emitter_body_js_choose(v_1000748, v_1000749, v_1000750, v_1000751)}

def emitter_body_js_reference_nat_bounds(+v_1: String) -> EmitterProgress<String>:
  v_1000753 = {v_1 : String}
  v_1000754 = {"nat_min" : String}
  v_1000755 = {"(a)=>(b)=>(a<b?a:b)" : String}
  v_1000756 = {v_1 : String}
  v_1000757 = {"nat_max" : String}
  v_1000758 = {"(a)=>(b)=>(a>b?a:b)" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_9{v_1}}, +v_1000759 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000756, v_1000757, v_1000758, v_1000759}}, False{}, v_1000762 => emitter_body_js_choose(v_1000756, v_1000757, v_1000758, v_1000759), +v_1000760 => emitter_body_js_choose(v_1000753, v_1000754, v_1000755, v_1000760)}}

def emitter_body_js_reference_9(+v_1: String) -> EmitterProgress<String>:
  v_1000763 = {v_1 : String}
  v_1000764 = {"string_append" : String}
  v_1000765 = {"(a)=>(b)=>a+b" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_10{v_1}}, +v_1000766 => emitter_body_js_choose(v_1000763, v_1000764, v_1000765, v_1000766)}

def emitter_body_js_reference_10(+v_1: String) -> EmitterProgress<String>:
  v_1000768 = {v_1 : String}
  v_1000769 = {"bool_or" : String}
  v_1000770 = {"(a)=>(b)=>a||b" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_11{v_1}}, +v_1000771 => emitter_body_js_choose(v_1000768, v_1000769, v_1000770, v_1000771)}

def emitter_body_js_reference_11(+v_1: String) -> EmitterProgress<String>:
  v_1000773 = {v_1 : String}
  v_1000774 = {"bool_xor" : String}
  v_1000775 = {"(a)=>(b)=>a!==b" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_12{v_1}}, +v_1000776 => emitter_body_js_choose(v_1000773, v_1000774, v_1000775, v_1000776)}

def emitter_body_js_reference_12(+v_1: String) -> EmitterProgress<String>:
  v_1000778 = {v_1 : String}
  v_1000779 = {"u32_is_zero" : String}
  v_1000780 = {"(a)=>a===0" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_reference_more{v_1}}, +v_1000781 => emitter_body_js_choose(v_1000778, v_1000779, v_1000780, v_1000781)}

def emitter_body_js_reference_more(v_1: String) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_ref_f32_extra{v_1}}, +v_1000783 => EmitterFinished{v_1000783}}

def emitter_body_js_ref_f32_extra(+v_1: String) -> EmitterProgress<String>:
  v_1000784 = {v_1 : String}
  v_1000785 = {"f32_asin" : String}
  v_1000786 = {"(a)=>Math.fround(Math.asin(a))" : String}
  v_1000787 = {v_1 : String}
  v_1000788 = {"f32_acos" : String}
  v_1000789 = {"(a)=>Math.fround(Math.acos(a))" : String}
  v_1000790 = {v_1 : String}
  v_1000791 = {"f32_atan" : String}
  v_1000792 = {"(a)=>Math.fround(Math.atan(a))" : String}
  v_1000793 = {v_1 : String}
  v_1000794 = {"f32_sinh" : String}
  v_1000795 = {"(a)=>Math.fround(Math.sinh(a))" : String}
  v_1000796 = {v_1 : String}
  v_1000797 = {"f32_cosh" : String}
  v_1000798 = {"(a)=>Math.fround(Math.cosh(a))" : String}
  v_1000799 = {v_1 : String}
  v_1000800 = {"f32_tanh" : String}
  v_1000801 = {"(a)=>Math.fround(Math.tanh(a))" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_ref_strings{v_1}}, +v_1000802 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000799, v_1000800, v_1000801, v_1000802}}, False{}, v_1000813 => emitter_body_js_choose(v_1000799, v_1000800, v_1000801, v_1000802), +v_1000803 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000796, v_1000797, v_1000798, v_1000803}}, False{}, v_1000812 => emitter_body_js_choose(v_1000796, v_1000797, v_1000798, v_1000803), +v_1000804 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000793, v_1000794, v_1000795, v_1000804}}, False{}, v_1000811 => emitter_body_js_choose(v_1000793, v_1000794, v_1000795, v_1000804), +v_1000805 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000790, v_1000791, v_1000792, v_1000805}}, False{}, v_1000810 => emitter_body_js_choose(v_1000790, v_1000791, v_1000792, v_1000805), +v_1000806 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000787, v_1000788, v_1000789, v_1000806}}, False{}, v_1000809 => emitter_body_js_choose(v_1000787, v_1000788, v_1000789, v_1000806), +v_1000807 => emitter_body_js_choose(v_1000784, v_1000785, v_1000786, v_1000807)}}}}}}

def emitter_body_js_ref_u32(+v_1: String) -> EmitterProgress<String>:
  v_1000814 = {v_1 : String}
  v_1000815 = {"u32_mod" : String}
  v_1000816 = {"(a)=>(b)=>(b===0?a:a%b)" : String}
  v_1000817 = {v_1 : String}
  v_1000818 = {"u32_and" : String}
  v_1000819 = {"(a)=>(b)=>((a&b)>>>0)" : String}
  v_1000820 = {v_1 : String}
  v_1000821 = {"u32_or" : String}
  v_1000822 = {"(a)=>(b)=>((a|b)>>>0)" : String}
  v_1000823 = {v_1 : String}
  v_1000824 = {"u32_xor" : String}
  v_1000825 = {"(a)=>(b)=>((a^b)>>>0)" : String}
  v_1000826 = {v_1 : String}
  v_1000827 = {"u32_is_eq" : String}
  v_1000828 = {"(a)=>(b)=>a===b" : String}
  v_1000829 = {v_1 : String}
  v_1000830 = {"u32_is_ne" : String}
  v_1000831 = {"(a)=>(b)=>a!==b" : String}
  v_1000832 = {v_1 : String}
  v_1000833 = {"u32_is_lt" : String}
  v_1000834 = {"(a)=>(b)=>a<b" : String}
  v_1000835 = {v_1 : String}
  v_1000836 = {"u32_is_le" : String}
  v_1000837 = {"(a)=>(b)=>a<=b" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_ref_u32_2{v_1}}, +v_1000838 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000835, v_1000836, v_1000837, v_1000838}}, False{}, v_1000853 => emitter_body_js_choose(v_1000835, v_1000836, v_1000837, v_1000838), +v_1000839 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000832, v_1000833, v_1000834, v_1000839}}, False{}, v_1000852 => emitter_body_js_choose(v_1000832, v_1000833, v_1000834, v_1000839), +v_1000840 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000829, v_1000830, v_1000831, v_1000840}}, False{}, v_1000851 => emitter_body_js_choose(v_1000829, v_1000830, v_1000831, v_1000840), +v_1000841 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000826, v_1000827, v_1000828, v_1000841}}, False{}, v_1000850 => emitter_body_js_choose(v_1000826, v_1000827, v_1000828, v_1000841), +v_1000842 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000823, v_1000824, v_1000825, v_1000842}}, False{}, v_1000849 => emitter_body_js_choose(v_1000823, v_1000824, v_1000825, v_1000842), +v_1000843 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000820, v_1000821, v_1000822, v_1000843}}, False{}, v_1000848 => emitter_body_js_choose(v_1000820, v_1000821, v_1000822, v_1000843), +v_1000844 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000817, v_1000818, v_1000819, v_1000844}}, False{}, v_1000847 => emitter_body_js_choose(v_1000817, v_1000818, v_1000819, v_1000844), +v_1000845 => emitter_body_js_choose(v_1000814, v_1000815, v_1000816, v_1000845)}}}}}}}}

def emitter_body_js_ref_u32_2(+v_1: String) -> EmitterProgress<String>:
  v_1000854 = {v_1 : String}
  v_1000855 = {"u32_is_gt" : String}
  v_1000856 = {"(a)=>(b)=>a>b" : String}
  v_1000857 = {v_1 : String}
  v_1000858 = {"u32_is_ge" : String}
  v_1000859 = {"(a)=>(b)=>a>=b" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_ref_u32_3{v_1}}, +v_1000860 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000857, v_1000858, v_1000859, v_1000860}}, False{}, v_1000863 => emitter_body_js_choose(v_1000857, v_1000858, v_1000859, v_1000860), +v_1000861 => emitter_body_js_choose(v_1000854, v_1000855, v_1000856, v_1000861)}}

def emitter_body_js_ref_u32_3(+v_1: String) -> EmitterProgress<String>:
  v_1000864 = {v_1 : String}
  v_1000865 = {"u32_inc" : String}
  v_1000866 = {"(a)=>(a+1)>>>0" : String}
  v_1000867 = {v_1 : String}
  v_1000868 = {"u32_not" : String}
  v_1000869 = {"(a)=>(~a)>>>0" : String}
  v_1000870 = {v_1 : String}
  v_1000871 = {"u32_shl" : String}
  v_1000872 = {"(a)=>(a<<1)>>>0" : String}
  v_1000873 = {v_1 : String}
  v_1000874 = {"u32_shr" : String}
  v_1000875 = {"(a)=>a>>>1" : String}
  v_1000876 = {v_1 : String}
  v_1000877 = {"u32_shln" : String}
  v_1000878 = {"(a)=>(b)=>b>=32?0:(a<<b)>>>0" : String}
  v_1000879 = {v_1 : String}
  v_1000880 = {"u32_shrn" : String}
  v_1000881 = {"(a)=>(b)=>b>=32?0:a>>>b" : String}
  v_1000882 = {v_1 : String}
  v_1000883 = {"u32_cmp" : String}
  v_1000884 = {"(a)=>(b)=>cmp_new(a,b)" : String}
  v_1000885 = {v_1 : String}
  v_1000886 = {"u32_to_nat" : String}
  v_1000887 = {"(a)=>a" : String}
  v_1000888 = {v_1 : String}
  v_1000889 = {"u32_from_nat" : String}
  v_1000890 = {"(a)=>a>>>0" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_ref_nat{v_1}}, +v_1000891 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000888, v_1000889, v_1000890, v_1000891}}, False{}, v_1000908 => emitter_body_js_choose(v_1000888, v_1000889, v_1000890, v_1000891), +v_1000892 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000885, v_1000886, v_1000887, v_1000892}}, False{}, v_1000907 => emitter_body_js_choose(v_1000885, v_1000886, v_1000887, v_1000892), +v_1000893 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000882, v_1000883, v_1000884, v_1000893}}, False{}, v_1000906 => emitter_body_js_choose(v_1000882, v_1000883, v_1000884, v_1000893), +v_1000894 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000879, v_1000880, v_1000881, v_1000894}}, False{}, v_1000905 => emitter_body_js_choose(v_1000879, v_1000880, v_1000881, v_1000894), +v_1000895 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000876, v_1000877, v_1000878, v_1000895}}, False{}, v_1000904 => emitter_body_js_choose(v_1000876, v_1000877, v_1000878, v_1000895), +v_1000896 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000873, v_1000874, v_1000875, v_1000896}}, False{}, v_1000903 => emitter_body_js_choose(v_1000873, v_1000874, v_1000875, v_1000896), +v_1000897 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000870, v_1000871, v_1000872, v_1000897}}, False{}, v_1000902 => emitter_body_js_choose(v_1000870, v_1000871, v_1000872, v_1000897), +v_1000898 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000867, v_1000868, v_1000869, v_1000898}}, False{}, v_1000901 => emitter_body_js_choose(v_1000867, v_1000868, v_1000869, v_1000898), +v_1000899 => emitter_body_js_choose(v_1000864, v_1000865, v_1000866, v_1000899)}}}}}}}}}

def emitter_body_js_ref_f32(+v_1: String) -> EmitterProgress<String>:
  v_1000909 = {v_1 : String}
  v_1000910 = {"f32_add" : String}
  v_1000911 = {"(a)=>(b)=>Math.fround(a+b)" : String}
  v_1000912 = {v_1 : String}
  v_1000913 = {"f32_sub" : String}
  v_1000914 = {"(a)=>(b)=>Math.fround(a-b)" : String}
  v_1000915 = {v_1 : String}
  v_1000916 = {"f32_mul" : String}
  v_1000917 = {"(a)=>(b)=>Math.fround(a*b)" : String}
  v_1000918 = {v_1 : String}
  v_1000919 = {"f32_div" : String}
  v_1000920 = {"(a)=>(b)=>Math.fround(a/b)" : String}
  v_1000921 = {v_1 : String}
  v_1000922 = {"f32_mod" : String}
  v_1000923 = {"(a)=>(b)=>Math.fround(a%b)" : String}
  v_1000924 = {v_1 : String}
  v_1000925 = {"f32_neg" : String}
  v_1000926 = {"(a)=>-a" : String}
  v_1000927 = {v_1 : String}
  v_1000928 = {"f32_sqrt" : String}
  v_1000929 = {"(a)=>Math.fround(Math.sqrt(a))" : String}
  v_1000930 = {v_1 : String}
  v_1000931 = {"f32_abs" : String}
  v_1000932 = {"(a)=>Math.fround(Math.abs(a))" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_ref_f32_2{v_1}}, +v_1000933 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000930, v_1000931, v_1000932, v_1000933}}, False{}, v_1000948 => emitter_body_js_choose(v_1000930, v_1000931, v_1000932, v_1000933), +v_1000934 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000927, v_1000928, v_1000929, v_1000934}}, False{}, v_1000947 => emitter_body_js_choose(v_1000927, v_1000928, v_1000929, v_1000934), +v_1000935 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000924, v_1000925, v_1000926, v_1000935}}, False{}, v_1000946 => emitter_body_js_choose(v_1000924, v_1000925, v_1000926, v_1000935), +v_1000936 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000921, v_1000922, v_1000923, v_1000936}}, False{}, v_1000945 => emitter_body_js_choose(v_1000921, v_1000922, v_1000923, v_1000936), +v_1000937 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000918, v_1000919, v_1000920, v_1000937}}, False{}, v_1000944 => emitter_body_js_choose(v_1000918, v_1000919, v_1000920, v_1000937), +v_1000938 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000915, v_1000916, v_1000917, v_1000938}}, False{}, v_1000943 => emitter_body_js_choose(v_1000915, v_1000916, v_1000917, v_1000938), +v_1000939 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000912, v_1000913, v_1000914, v_1000939}}, False{}, v_1000942 => emitter_body_js_choose(v_1000912, v_1000913, v_1000914, v_1000939), +v_1000940 => emitter_body_js_choose(v_1000909, v_1000910, v_1000911, v_1000940)}}}}}}}}

def emitter_body_js_ref_f32_2(+v_1: String) -> EmitterProgress<String>:
  v_1000949 = {v_1 : String}
  v_1000950 = {"f32_to_u32" : String}
  v_1000951 = {"(a)=>(a>=1&&a<4294967296?Math.floor(a):0)" : String}
  v_1000952 = {v_1 : String}
  v_1000953 = {"f32_bits" : String}
  v_1000954 = {"(a)=>f32_bits(a)" : String}
  v_1000955 = {v_1 : String}
  v_1000956 = {"f32_show" : String}
  v_1000957 = {"(a)=>f32_show(a)" : String}
  v_1000958 = {v_1 : String}
  v_1000959 = {"f32_read" : String}
  v_1000960 = {"(a)=>f32_read(a)" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_ref_f32_3{v_1}}, +v_1000961 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000958, v_1000959, v_1000960, v_1000961}}, False{}, v_1000968 => emitter_body_js_choose(v_1000958, v_1000959, v_1000960, v_1000961), +v_1000962 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000955, v_1000956, v_1000957, v_1000962}}, False{}, v_1000967 => emitter_body_js_choose(v_1000955, v_1000956, v_1000957, v_1000962), +v_1000963 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000952, v_1000953, v_1000954, v_1000963}}, False{}, v_1000966 => emitter_body_js_choose(v_1000952, v_1000953, v_1000954, v_1000963), +v_1000964 => emitter_body_js_choose(v_1000949, v_1000950, v_1000951, v_1000964)}}}}

def emitter_body_js_ref_f32_3(+v_1: String) -> EmitterProgress<String>:
  v_1000969 = {v_1 : String}
  v_1000970 = {"f32_is_eq" : String}
  v_1000971 = {"(a)=>(b)=>a===b" : String}
  v_1000972 = {v_1 : String}
  v_1000973 = {"f32_is_ne" : String}
  v_1000974 = {"(a)=>(b)=>a!==b" : String}
  v_1000975 = {v_1 : String}
  v_1000976 = {"f32_is_lt" : String}
  v_1000977 = {"(a)=>(b)=>a<b" : String}
  v_1000978 = {v_1 : String}
  v_1000979 = {"f32_is_le" : String}
  v_1000980 = {"(a)=>(b)=>a<=b" : String}
  v_1000981 = {v_1 : String}
  v_1000982 = {"f32_is_gt" : String}
  v_1000983 = {"(a)=>(b)=>a>b" : String}
  v_1000984 = {v_1 : String}
  v_1000985 = {"f32_is_ge" : String}
  v_1000986 = {"(a)=>(b)=>a>=b" : String}
  v_1000987 = {v_1 : String}
  v_1000988 = {"f32_pow" : String}
  v_1000989 = {"(a)=>(b)=>Math.fround(Math.pow(a,b))" : String}
  v_1000990 = {v_1 : String}
  v_1000991 = {"f32_atan2" : String}
  v_1000992 = {"(a)=>(b)=>Math.fround(Math.atan2(a,b))" : String}
  v_1000993 = {v_1 : String}
  v_1000994 = {"f32_exp" : String}
  v_1000995 = {"(a)=>Math.fround(Math.exp(a))" : String}
  v_1000996 = {v_1 : String}
  v_1000997 = {"f32_log" : String}
  v_1000998 = {"(a)=>Math.fround(Math.log(a))" : String}
  v_1000999 = {v_1 : String}
  v_1001000 = {"f32_log2" : String}
  v_1001001 = {"(a)=>Math.fround(Math.log2(a))" : String}
  v_1001002 = {v_1 : String}
  v_1001003 = {"f32_log10" : String}
  v_1001004 = {"(a)=>Math.fround(Math.log10(a))" : String}
  v_1001005 = {v_1 : String}
  v_1001006 = {"f32_sin" : String}
  v_1001007 = {"(a)=>Math.fround(Math.sin(a))" : String}
  v_1001008 = {v_1 : String}
  v_1001009 = {"f32_cos" : String}
  v_1001010 = {"(a)=>Math.fround(Math.cos(a))" : String}
  v_1001011 = {v_1 : String}
  v_1001012 = {"f32_tan" : String}
  v_1001013 = {"(a)=>Math.fround(Math.tan(a))" : String}
  v_1001014 = {v_1 : String}
  v_1001015 = {"f32_floor" : String}
  v_1001016 = {"(a)=>Math.fround(Math.floor(a))" : String}
  v_1001017 = {v_1 : String}
  v_1001018 = {"f32_ceil" : String}
  v_1001019 = {"(a)=>Math.fround(Math.ceil(a))" : String}
  v_1001020 = {v_1 : String}
  v_1001021 = {"f32_trunc" : String}
  v_1001022 = {"(a)=>Math.fround(Math.trunc(a))" : String}
  v_1001023 = {v_1 : String}
  v_1001024 = {"f32_to_nat" : String}
  v_1001025 = {"(a)=>Math.floor(a)" : String}
  v_1001026 = {v_1 : String}
  v_1001027 = {"u32_to_f32" : String}
  v_1001028 = {"(a)=>Math.fround(a)" : String}
  v_1001029 = {"$D[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1001070 => emitter_body_js_quote(v_1), +v_1001030 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001026, v_1001027, v_1001028, String.append(v_1001029, String.append(v_1001030, "]"))}}, False{}, v_1001069 => emitter_body_js_choose(v_1001026, v_1001027, v_1001028, String.append(v_1001029, String.append(v_1001030, "]"))), +v_1001031 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001023, v_1001024, v_1001025, v_1001031}}, False{}, v_1001068 => emitter_body_js_choose(v_1001023, v_1001024, v_1001025, v_1001031), +v_1001032 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001020, v_1001021, v_1001022, v_1001032}}, False{}, v_1001067 => emitter_body_js_choose(v_1001020, v_1001021, v_1001022, v_1001032), +v_1001033 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001017, v_1001018, v_1001019, v_1001033}}, False{}, v_1001066 => emitter_body_js_choose(v_1001017, v_1001018, v_1001019, v_1001033), +v_1001034 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001014, v_1001015, v_1001016, v_1001034}}, False{}, v_1001065 => emitter_body_js_choose(v_1001014, v_1001015, v_1001016, v_1001034), +v_1001035 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001011, v_1001012, v_1001013, v_1001035}}, False{}, v_1001064 => emitter_body_js_choose(v_1001011, v_1001012, v_1001013, v_1001035), +v_1001036 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001008, v_1001009, v_1001010, v_1001036}}, False{}, v_1001063 => emitter_body_js_choose(v_1001008, v_1001009, v_1001010, v_1001036), +v_1001037 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001005, v_1001006, v_1001007, v_1001037}}, False{}, v_1001062 => emitter_body_js_choose(v_1001005, v_1001006, v_1001007, v_1001037), +v_1001038 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001002, v_1001003, v_1001004, v_1001038}}, False{}, v_1001061 => emitter_body_js_choose(v_1001002, v_1001003, v_1001004, v_1001038), +v_1001039 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000999, v_1001000, v_1001001, v_1001039}}, False{}, v_1001060 => emitter_body_js_choose(v_1000999, v_1001000, v_1001001, v_1001039), +v_1001040 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000996, v_1000997, v_1000998, v_1001040}}, False{}, v_1001059 => emitter_body_js_choose(v_1000996, v_1000997, v_1000998, v_1001040), +v_1001041 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000993, v_1000994, v_1000995, v_1001041}}, False{}, v_1001058 => emitter_body_js_choose(v_1000993, v_1000994, v_1000995, v_1001041), +v_1001042 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000990, v_1000991, v_1000992, v_1001042}}, False{}, v_1001057 => emitter_body_js_choose(v_1000990, v_1000991, v_1000992, v_1001042), +v_1001043 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000987, v_1000988, v_1000989, v_1001043}}, False{}, v_1001056 => emitter_body_js_choose(v_1000987, v_1000988, v_1000989, v_1001043), +v_1001044 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000984, v_1000985, v_1000986, v_1001044}}, False{}, v_1001055 => emitter_body_js_choose(v_1000984, v_1000985, v_1000986, v_1001044), +v_1001045 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000981, v_1000982, v_1000983, v_1001045}}, False{}, v_1001054 => emitter_body_js_choose(v_1000981, v_1000982, v_1000983, v_1001045), +v_1001046 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000978, v_1000979, v_1000980, v_1001046}}, False{}, v_1001053 => emitter_body_js_choose(v_1000978, v_1000979, v_1000980, v_1001046), +v_1001047 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000975, v_1000976, v_1000977, v_1001047}}, False{}, v_1001052 => emitter_body_js_choose(v_1000975, v_1000976, v_1000977, v_1001047), +v_1001048 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1000972, v_1000973, v_1000974, v_1001048}}, False{}, v_1001051 => emitter_body_js_choose(v_1000972, v_1000973, v_1000974, v_1001048), +v_1001049 => emitter_body_js_choose(v_1000969, v_1000970, v_1000971, v_1001049)}}}}}}}}}}}}}}}}}}}}

def emitter_body_js_ref_nat(+v_1: String) -> EmitterProgress<String>:
  v_1001071 = {v_1 : String}
  v_1001072 = {"nat_double" : String}
  v_1001073 = {"(a)=>nat_chk(a+a)" : String}
  v_1001074 = {v_1 : String}
  v_1001075 = {"nat_is_lt" : String}
  v_1001076 = {"(a)=>(b)=>a<b" : String}
  v_1001077 = {v_1 : String}
  v_1001078 = {"nat_divmod" : String}
  v_1001079 = {"(a)=>(b)=>nat_divmod(a,b)" : String}
  v_1001080 = {"$D[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1001087 => emitter_body_js_quote(v_1), +v_1001081 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001077, v_1001078, v_1001079, String.append(v_1001080, String.append(v_1001081, "]"))}}, False{}, v_1001086 => emitter_body_js_choose(v_1001077, v_1001078, v_1001079, String.append(v_1001080, String.append(v_1001081, "]"))), +v_1001082 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001074, v_1001075, v_1001076, v_1001082}}, False{}, v_1001085 => emitter_body_js_choose(v_1001074, v_1001075, v_1001076, v_1001082), +v_1001083 => emitter_body_js_choose(v_1001071, v_1001072, v_1001073, v_1001083)}}}

def emitter_body_js_ref_strings(+v_1: String) -> EmitterProgress<String>:
  v_1001088 = {v_1 : String}
  v_1001089 = {"string_eq" : String}
  v_1001090 = {"(a)=>(b)=>a===b" : String}
  v_1001091 = {v_1 : String}
  v_1001092 = {"map_bit" : String}
  v_1001093 = {"(key)=>(position)=>{const character=Math.floor(position/33);if(character>=key.length)return tuple(key,false);const offset=position%33;let at=0;for(let i=0;i<character&&at<key.length;i++)at+=key.codePointAt(at)>65535?2:1;return tuple(key,at<key.length&&(offset===0||((key.codePointAt(at)>>>(32-offset))&1)!==0));}" : String}
  v_1001094 = {v_1 : String}
  v_1001095 = {"string_cmp" : String}
  v_1001096 = {"(a)=>(b)=>{let i=0,j=0,order=0;if(a!==b){while(i<a.length&&j<b.length){const x=a.codePointAt(i),y=b.codePointAt(j);if(x!==y){order=x<y?-1:1;break;}i+=x>65535?2:1;j+=y>65535?2:1;}if(order===0)order=i<a.length?1:j<b.length?-1:0;}return tuple(tuple(a,b),cmp_new(order,0));}" : String}
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_ref_array{v_1}}, +v_1001097 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001094, v_1001095, v_1001096, v_1001097}}, False{}, v_1001102 => emitter_body_js_choose(v_1001094, v_1001095, v_1001096, v_1001097), +v_1001098 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001091, v_1001092, v_1001093, v_1001098}}, False{}, v_1001101 => emitter_body_js_choose(v_1001091, v_1001092, v_1001093, v_1001098), +v_1001099 => emitter_body_js_choose(v_1001088, v_1001089, v_1001090, v_1001099)}}}

def emitter_body_js_ref_array(+v_1: String) -> EmitterProgress<String>:
  v_1001103 = {v_1 : String}
  v_1001104 = {"string_to_list" : String}
  v_1001105 = {"(text)=>{let tail={$:\"Nil\"};for(let i=text.length;i>0;){const end=i,low=text.charCodeAt(--i);if(low>=0xDC00&&low<=0xDFFF&&i>0){const high=text.charCodeAt(i-1);if(high>=0xD800&&high<=0xDBFF)--i;}tail={$:\"Con\",head:text.slice(i,end),tail};}return tail;}" : String}
  v_1001106 = {v_1 : String}
  v_1001107 = {"string_length" : String}
  v_1001108 = {"(a)=>[...a].length" : String}
  v_1001109 = {v_1 : String}
  v_1001110 = {"array_new" : String}
  v_1001111 = {"(a)=>(b)=>array_new(a,b)" : String}
  v_1001112 = {v_1 : String}
  v_1001113 = {"array_set" : String}
  v_1001114 = {"(a)=>(i)=>(v)=>(a[i%a.length]=v,a)" : String}
  v_1001115 = {v_1 : String}
  v_1001116 = {"array_get" : String}
  v_1001117 = {"(a)=>(i)=>tuple(a,a[i%a.length])" : String}
  v_1001118 = {v_1 : String}
  v_1001119 = {"array_swap" : String}
  v_1001120 = {"(a)=>(i)=>(v)=>array_swap(a,i,v)" : String}
  v_1001121 = {v_1 : String}
  v_1001122 = {"array_size" : String}
  v_1001123 = {"(a)=>tuple(a,a.length)" : String}
  v_1001124 = {v_1 : String}
  v_1001125 = {"array_clone" : String}
  v_1001126 = {"(a)=>tuple(a,a.slice())" : String}
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_ref_u32{v_1}}, False{}, v_1001143 => emitter_body_js_ref_u32(v_1), +v_1001127 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001124, v_1001125, v_1001126, v_1001127}}, False{}, v_1001142 => emitter_body_js_choose(v_1001124, v_1001125, v_1001126, v_1001127), +v_1001128 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001121, v_1001122, v_1001123, v_1001128}}, False{}, v_1001141 => emitter_body_js_choose(v_1001121, v_1001122, v_1001123, v_1001128), +v_1001129 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001118, v_1001119, v_1001120, v_1001129}}, False{}, v_1001140 => emitter_body_js_choose(v_1001118, v_1001119, v_1001120, v_1001129), +v_1001130 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001115, v_1001116, v_1001117, v_1001130}}, False{}, v_1001139 => emitter_body_js_choose(v_1001115, v_1001116, v_1001117, v_1001130), +v_1001131 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001112, v_1001113, v_1001114, v_1001131}}, False{}, v_1001138 => emitter_body_js_choose(v_1001112, v_1001113, v_1001114, v_1001131), +v_1001132 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001109, v_1001110, v_1001111, v_1001132}}, False{}, v_1001137 => emitter_body_js_choose(v_1001109, v_1001110, v_1001111, v_1001132), +v_1001133 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose{v_1001106, v_1001107, v_1001108, v_1001133}}, False{}, v_1001136 => emitter_body_js_choose(v_1001106, v_1001107, v_1001108, v_1001133), +v_1001134 => emitter_body_js_choose(v_1001103, v_1001104, v_1001105, v_1001134)}}}}}}}}

def emitter_body_js_term(v_0: AST.SyntaxTerm, v_2: EmitEnv) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_term_expected{v_0, v_2, None{}}}, +v_1001144 => EmitterFinished{v_1001144}}

def emitter_match_237(+v_0: AST.SyntaxTerm, +v_2: EmitEnv, v_5: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_0:
    case AST.TermVar{_, v_11, _}:
      emitter_body_env_at(v_2, v_11)
    case AST.TermRef{v_16, _}:
      emitter_body_js_reference(v_16)
    case AST.TermBang{AST.TermRef{v_22, _}, _}:
      emitter_body_js_reference(v_22)
    case AST.TermCtr{v_29, v_30, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_constructor{v_29, v_30, v_2, v_5}}, +v_1001148 => EmitterFinished{v_1001148}}
    case AST.TermString{v_36, v_37, v_38}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_string_literal{v_36, v_37, v_38, v_2, v_5}}, +v_1001149 => EmitterFinished{v_1001149}}
    case AST.TermType{_, _}:
      EmitterFinished{"null"}
    case AST.TermQuant{}:
      EmitterFinished{"null"}
    case AST.TermQuantity{_, _}:
      EmitterFinished{"null"}
    case AST.TermMin{_, _, _}:
      EmitterFinished{"null"}
    case AST.TermAll{_, _, _, _, _, _}:
      EmitterFinished{"null"}
    case AST.TermAdt{_, _, _, _}:
      EmitterFinished{"null"}
    case AST.TermEqual{_, _, _, _}:
      EmitterFinished{"null"}
    case AST.TermRefl{_}:
      EmitterFinished{"null"}
    case AST.TermAnn{v_87, v_88, _}:
      v_1001150 = {v_87 : AST.SyntaxTerm}
      v_1001151 = {v_2 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_88, v_2}}, False{}, v_1001154 => emitter_body_js_close(v_88, v_2), +v_1001152 => EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_term_expected{v_1001150, v_1001151, Some{v_1001152}}}, +v_1001153 => EmitterFinished{v_1001153}}}
    case AST.TermFill{v_95, _, _}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_term_expected{v_95, v_2, None{}}}, +v_1001155 => EmitterFinished{v_1001155}}
    case AST.TermPlus{v_102, _, _}:
      EmitterPending{EmitterRequestGroup_2{EmitterRequest_js_term_expected{v_102, v_2, None{}}}, +v_1001156 => EmitterFinished{v_1001156}}
    case AST.TermApp{_, _, _}:
      v_1001157 = {"run_loop(" : String}
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_spine{v_0, v_2, True{}}}, +v_1001158 => EmitterFinished{String.append(v_1001157, String.append(v_1001158, ")"))}}
    case _:
      v_1001159 = {"run_loop(" : String}
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_0, v_2, v_5}}, +v_1001160 => EmitterFinished{String.append(v_1001159, String.append(v_1001160, ")"))}}

def emitter_body_js_term_expected(v_0: AST.SyntaxTerm, v_2: EmitEnv, v_5: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_237(v_0, v_2, v_5)

def emitter_match_238(+v_0: AST.SyntaxTerm, +v_2: EmitEnv, v_5: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_0:
    case AST.TermVar{_, v_11, _}:
      emitter_body_env_at(v_2, v_11)
    case AST.TermRef{v_16, _}:
      emitter_body_js_reference(v_16)
    case AST.TermSub{v_23, v_24, v_25, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_sub{v_23, v_24, v_25, v_2, v_5}}, +v_1001163 => EmitterFinished{v_1001163}}
    case AST.TermLet{v_34, _, v_36, v_37, v_38, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_let{v_34, v_36, v_37, v_38, v_2, v_2, v_5, 0n}}, +v_1001164 => EmitterFinished{v_1001164}}
    case AST.TermType{_, _}:
      EmitterFinished{"null"}
    case AST.TermQuant{}:
      EmitterFinished{"null"}
    case AST.TermQuantity{_, _}:
      EmitterFinished{"null"}
    case AST.TermMin{_, _, _}:
      EmitterFinished{"null"}
    case AST.TermAll{_, _, _, _, _, _}:
      EmitterFinished{"null"}
    case AST.TermLam{v_72, _, _, v_75, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_lambda{v_72, v_75, v_2, v_5}}, +v_1001165 => EmitterFinished{v_1001165}}
    case AST.TermAnn{v_80, v_81, _}:
      v_1001166 = {v_80 : AST.SyntaxTerm}
      v_1001167 = {v_2 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_81, v_2}}, False{}, v_1001170 => emitter_body_js_close(v_81, v_2), +v_1001168 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_1001166, v_1001167, Some{v_1001168}}}, +v_1001169 => EmitterFinished{v_1001169}}}
    case AST.TermBang{AST.TermRef{v_88, _}, _}:
      emitter_body_js_reference(v_88)
    case AST.TermBang{_, _}:
      EmitterFinished{"(()=>{throw \"bend: bang head must be a named reference\"})()"}
    case AST.TermFill{v_99, _, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_99, v_2, None{}}}, +v_1001172 => EmitterFinished{v_1001172}}
    case AST.TermPlus{v_106, _, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_106, v_2, None{}}}, +v_1001173 => EmitterFinished{v_1001173}}
    case AST.TermApp{_, _, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_spine{v_0, v_2, False{}}}, +v_1001174 => EmitterFinished{v_1001174}}
    case AST.TermAdt{_, _, _, _}:
      EmitterFinished{"null"}
    case AST.TermCtr{v_128, v_129, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_constructor{v_128, v_129, v_2, v_5}}, +v_1001175 => EmitterFinished{v_1001175}}
    case AST.TermString{v_135, v_136, v_137}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_string_literal{v_135, v_136, v_137, v_2, v_5}}, +v_1001176 => EmitterFinished{v_1001176}}
    case AST.TermMat{_, v_144, v_145, _}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_match{v_144, v_145, v_2, v_5}}, +v_1001177 => EmitterFinished{v_1001177}}
    case AST.TermAbsurd{v_149}:
      EmitterFinished{"(()=>{throw \"bend: runtime fail-stop\"})()"}
    case AST.TermEqual{_, _, _, _}:
      EmitterFinished{"null"}
    case AST.TermRefl{_}:
      EmitterFinished{"null"}
    case AST.TermRewrite{_, _, v_166, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_166, v_2, v_5}}, +v_1001178 => EmitterFinished{v_1001178}}
    case AST.TermHole{v_171, v_172}:
      v_1001179 = {"(()=>{throw " : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{String.append("bend: unsolved hole ", v_171)}}, False{}, v_1001181 => emitter_body_js_quote(String.append("bend: unsolved hole ", v_171)), +v_1001180 => EmitterFinished{String.append(v_1001179, String.append(v_1001180, "})()"))}}
    case AST.BodyReply{v_175, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_175, v_2, v_5}}, +v_1001182 => EmitterFinished{v_1001182}}
    case AST.BodyLocal{v_183, _, v_185, v_186, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_body_local{v_183, v_185, v_186, v_2, v_2, v_5}}, +v_1001183 => EmitterFinished{v_1001183}}
    case AST.BodyCase{_, v_193, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_193, v_2, v_5}}, +v_1001184 => EmitterFinished{v_1001184}}
    case AST.BodyMatch{v_199, v_200, _}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_body_match{v_199, v_200, v_2, v_5}}, +v_1001185 => EmitterFinished{v_1001185}}
    case AST.TermTemplate{_, _}:
      EmitterFinished{"(()=>{throw \"bend: unexpanded template\"})()"}

def emitter_body_js_term_tail_expected(v_0: AST.SyntaxTerm, v_2: EmitEnv, v_5: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_238(v_0, v_2, v_5)

def emitter_match_239(+v_0: AST.SyntaxTerm, +v_2: EmitEnv, v_5: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_0:
    case AST.BodyReply{v_9, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_statement_tail{v_9, v_2, v_5}}, +v_1001186 => EmitterFinished{v_1001186}}
    case AST.BodyCase{_, v_16, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_statement_tail{v_16, v_2, v_5}}, +v_1001187 => EmitterFinished{v_1001187}}
    case AST.TermAnn{v_22, v_23, _}:
      v_1001188 = {v_22 : AST.SyntaxTerm}
      v_1001189 = {v_2 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_23, v_2}}, False{}, v_1001192 => emitter_body_js_close(v_23, v_2), +v_1001190 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_statement_tail{v_1001188, v_1001189, Some{v_1001190}}}, +v_1001191 => EmitterFinished{v_1001191}}}
    case AST.TermRewrite{_, _, v_33, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_statement_tail{v_33, v_2, v_5}}, +v_1001193 => EmitterFinished{v_1001193}}
    case AST.BodyLocal{v_41, _, v_43, v_44, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_statement_local{v_41, v_43, v_44, v_2, v_2, v_5}}, +v_1001194 => EmitterFinished{v_1001194}}
    case AST.BodyMatch{v_50, v_51, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_statement_match{v_50, v_51, v_2, v_5}}, +v_1001195 => EmitterFinished{v_1001195}}
    case _:
      v_1001196 = {"return " : String}
      EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_0, v_2, v_5}}, False{}, v_1001198 => emitter_body_js_term_tail_expected(v_0, v_2, v_5), +v_1001197 => EmitterFinished{String.append(v_1001196, String.append(v_1001197, ";"))}}

def emitter_body_js_statement_tail(v_0: AST.SyntaxTerm, v_2: EmitEnv, v_5: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_239(v_0, v_2, v_5)

def emitter_continuation_240(v_1001216: String, v_1001217: String, v_1001218: String, +v_1001219: String, v_41: List<&2, AST.SyntaxPattern>, v_43: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, v_6: EmitEnv, v_51: EmitEnv, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_54 = String.append(v_1001216, String.append(v_1001217, String.append(v_1001218, String.append(v_1001219, ";\n"))))
  v_1001220 = {v_54 : String}
  EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_statement_local{v_41, v_43, v_4, v_6, v_51, v_11}}, +v_1001221 => EmitterFinished{String.append(v_1001220, v_1001221)}}

def emitter_continuation_241(+v_1001215: EmitEnv, v_46: String, +v_42: AST.SyntaxTerm, +v_6: EmitEnv, v_41: List<&2, AST.SyntaxPattern>, v_43: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_51 = v_1001215
  v_1001216 = {"const " : String}
  v_1001217 = {v_46 : String}
  v_1001218 = {" = " : String}
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term{v_42, v_6}}, False{}, v_1001222 => emitter_body_js_term(v_42, v_6), +v_1001219 => emitter_continuation_240(v_1001216, v_1001217, v_1001218, v_1001219, v_41, v_43, v_4, v_6, v_51, v_11)}

def emitter_match_242(+v_1: List<&2, AST.SyntaxPattern>, +v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, +v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>, +v_6: EmitEnv) -> EmitterProgress<String>:
  match v_1, v_3:
    case [], []:
      emitter_body_js_statement_tail(v_4, v_8, v_11)
    case AST.PatternVar{_, _, AST.QZero{}, _} <> v_23, +v_24 <> v_25:
      v_1001200 = {v_23 : List<&2, AST.SyntaxPattern>}
      v_1001201 = {v_25 : List<&2, AST.SyntaxTerm>}
      v_1001202 = {v_4 : AST.SyntaxTerm}
      v_1001203 = {v_6 : EmitEnv}
      v_1001204 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_24, v_6}}, False{}, v_1001211 => emitter_body_js_type(v_24, v_6), +v_1001205 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_24, v_6}}, False{}, v_1001210 => emitter_body_js_close(v_24, v_6), +v_1001206 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001204, v_1001205, Some{v_1001206}, v_8}}, False{}, v_1001209 => emitter_body_env_bind(v_1001204, v_1001205, Some{v_1001206}, v_8), +v_1001207 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_statement_local{v_1001200, v_1001201, v_1001202, v_1001203, v_1001207, v_11}}, +v_1001208 => EmitterFinished{v_1001208}}}}}
    case AST.PatternVar{_, _, _, _} <> v_41, +v_42 <> v_43:
      +v_46 = String.append("$local", Nat.show(emitter_pure_env_depth(v_8)))
      v_1001212 = {v_46 : String}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_42, v_6}}, False{}, v_1001225 => emitter_body_js_type(v_42, v_6), +v_1001213 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_42, v_6}}, False{}, v_1001224 => emitter_body_js_close(v_42, v_6), +v_1001214 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001212, v_1001213, Some{v_1001214}, v_8}}, False{}, v_1001223 => emitter_body_env_bind(v_1001212, v_1001213, Some{v_1001214}, v_8), +v_1001215 => emitter_continuation_241(v_1001215, v_46, v_42, v_6, v_41, v_43, v_4, v_11)}}}
    case AST.PatternCtr{_, _, _} <> _, +_ <> _:
      v_1001226 = {"return " : String}
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_body_local_constructor{v_1, v_3, v_4, v_6, v_8, v_11}}, +v_1001227 => EmitterFinished{String.append(v_1001226, String.append(v_1001227, ";"))}}
    case _, _:
      EmitterFinished{"throw \"bend: malformed local bindings\";"}

def emitter_body_js_statement_local(v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, v_6: EmitEnv, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_242(v_1, v_3, v_4, v_8, v_11, v_6)

def emitter_continuation_243(+v_1001229: EmitEnv, +v_1: List<&2, AST.SyntaxTerm>, v_5: EmitEnv, v_3: List<&2, AST.SyntaxTerm>, v_14: List<&2, String>, v_8: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_17 = v_1001229
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_scrutinees{v_1, v_5, 0n}}, +v_1001230 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_cases_dispatch{v_3, v_14, v_1, v_17, v_8}}, +v_1001231 => EmitterFinished{String.append(v_1001230, v_1001231)}}}

def emitter_continuation_244(+v_1001228: List<&2, String>, v_11: Nat, +v_5: EmitEnv, v_1: List<&2, AST.SyntaxTerm>, v_3: List<&2, AST.SyntaxTerm>, v_8: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_14 = v_1001228
  EmitterPending{EmitterRequestGroup_3{EmitterRequest_env_reserve_names{v_11, v_5}}, +v_1001229 => emitter_continuation_243(v_1001229, v_1, v_5, v_3, v_14, v_8)}

def emitter_body_js_statement_match(+v_1: List<&2, AST.SyntaxTerm>, v_3: List<&2, AST.SyntaxTerm>, +v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  +v_11 = List.length(&2, AST.SyntaxTerm, v_1)
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_scrutinee_names{v_11, v_5}}, +v_1001228 => emitter_continuation_244(v_1001228, v_11, v_5, v_1, v_3, v_8)}

def emitter_match_245(v_3: AST.OptionalTerm, v_0: AST.SyntaxTerm, +v_2: EmitEnv) -> EmitterProgress<String>:
  match v_3:
    case AST.SomeTerm{v_6}:
      v_1001232 = {v_0 : AST.SyntaxTerm}
      v_1001233 = {v_2 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_6, v_2}}, False{}, v_1001237 => emitter_body_js_close(v_6, v_2), +v_1001234 => EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_statement_tail{v_1001232, v_1001233, Some{v_1001234}}}, False{}, v_1001236 => emitter_body_js_statement_tail(v_1001232, v_1001233, Some{v_1001234}), +v_1001235 => EmitterFinished{v_1001235}}}
    case AST.NoTerm{}:
      emitter_body_js_statement_tail(v_0, v_2, None{})

def emitter_body_js_statement_result(v_0: AST.SyntaxTerm, v_2: EmitEnv, v_3: AST.OptionalTerm) -> EmitterProgress<String>:
  emitter_match_245(v_3, v_0, v_2)

def emitter_body_js_app_spine(v_0: AST.SyntaxTerm, v_2: EmitEnv, v_4: Bool) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_spine_at{v_0, []}}, v_1001239 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_spine_result{v_1001239, v_2, v_4}}, +v_1001240 => EmitterFinished{v_1001240}}}

def emitter_body_js_app_spine_result(v_1: Pair(AST.SyntaxTerm, List<&2, AST.SyntaxTerm>), v_3: EmitEnv, v_5: Bool) -> EmitterProgress<String>:
  match v_1:
    case (v_9, v_10):
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_dispatch{v_9, v_10, v_3, v_5}}, +v_1001241 => EmitterFinished{v_1001241}}

def emitter_match_247(+v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>, +v_4: EmitEnv, v_6: Bool) -> EmitterProgress<String>:
  match v_0:
    case AST.TermRef{v_10, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_app{v_10, v_2, v_4, v_6}}, +v_1001242 => EmitterFinished{v_1001242}}
    case AST.TermBang{AST.TermRef{v_16, _}, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_app{v_16, v_2, v_4, v_6}}, +v_1001243 => EmitterFinished{v_1001243}}
    case AST.TermBang{_, _}:
      EmitterFinished{"(()=>{throw \"bend: bang head must be a named reference\"})()"}
    case _:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term{v_0, v_4}}, False{}, v_1001248 => emitter_body_js_term(v_0, v_4), +v_1001244 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_0, v_4}}, False{}, v_1001247 => emitter_body_js_type(v_0, v_4), +v_1001245 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_chain{v_1001244, v_1001245, v_2, v_4}}, +v_1001246 => EmitterFinished{v_1001246}}}}

def emitter_body_js_app_dispatch(v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>, v_4: EmitEnv, v_6: Bool) -> EmitterProgress<String>:
  emitter_match_247(v_0, v_2, v_4, v_6)

def emitter_match_248(+v_11: EmitScope, +v_1: String) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  match v_11:
    case EmitScope{_, _, +v_21}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_scope_key{v_1, v_11}}, False{}, v_1001252 => emitter_body_js_scope_key(v_1, v_11), +v_1001249 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_lookup{v_1001249, v_21}}, +v_1001250 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_fallback{v_1001250, v_1, v_21}}, +v_1001251 => EmitterFinished{v_1001251}}}}

def emitter_match_249(v_3: EmitEnv, v_1: String) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  match v_3:
    case EmitEnv{+v_11, _, _, _, _}:
      emitter_match_248(v_11, v_1)

def emitter_body_js_named_owner(v_1: String, v_3: EmitEnv) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  emitter_match_249(v_3, v_1)

def emitter_match_250(+v_2: Maybe<&2, EmitNamed>, v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  match v_2:
    case Some{_}:
      EmitterFinished{v_2}
    case None{}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_lookup{v_4, v_6}}, +v_1001253 => EmitterFinished{v_1001253}}

def emitter_body_js_named_fallback(v_2: Maybe<&2, EmitNamed>, v_4: String, v_6: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  emitter_match_250(v_2, v_4, v_6)

def emitter_match_251(+v_3: EmitCatalog, +v_1: String) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  match v_3:
    case EmitCatalog{_, _, _, v_13}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_layouts{IndexLookup.find(List<&2, EmitModuleIndex>, v_13, v_1), v_1, v_3}}, +v_1001254 => EmitterFinished{v_1001254}}

def emitter_body_js_named_lookup(v_1: String, +v_3: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  emitter_match_251(v_3, v_1)

def emitter_match_252(+v_12: EmitModuleIndex, +v_5: String, +v_7: EmitCatalog, v_13: List<&2, EmitModuleIndex>) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  match v_12:
    case EmitModuleIndex{_, _, _, _, v_23}:
      v_1001255 = {IndexLookup.find(List<&2, AST.TopLevel>, v_23, v_5) : Maybe<&2, List<&2, AST.TopLevel>>}
      v_1001256 = {v_5 : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_owner_env{v_12, v_7}}, False{}, v_1001260 => emitter_body_js_owner_env(v_12, v_7), +v_1001257 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_declarations{v_1001255, v_1001256, v_1001257}}, +v_1001258 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_next{v_1001258, v_13, v_5, v_7}}, +v_1001259 => EmitterFinished{v_1001259}}}}

def emitter_body_js_named_layouts(v_3: Maybe<&2, List<&2, EmitModuleIndex>>, v_5: String, v_7: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  match v_3:
    case None{}:
      EmitterFinished{None{}}
    case Some{[]}:
      EmitterFinished{None{}}
    case Some{+v_12 <> v_13}:
      emitter_match_252(v_12, v_5, v_7, v_13)

def emitter_match_254(+v_2: Maybe<&2, EmitNamed>, v_5: List<&2, EmitModuleIndex>, v_7: String, v_9: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  match v_2:
    case Some{_}:
      EmitterFinished{v_2}
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_named_layouts{Some{v_5}, v_7, v_9}}, False{}, v_1001262 => emitter_body_js_named_layouts(Some{v_5}, v_7, v_9), +v_1001261 => EmitterFinished{v_1001261}}

def emitter_body_js_named_next(v_2: Maybe<&2, EmitNamed>, v_5: List<&2, EmitModuleIndex>, v_7: String, v_9: EmitCatalog) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  emitter_match_254(v_2, v_5, v_7, v_9)

def emitter_match_255(v_2: Maybe<&2, List<&2, AST.TopLevel>>, v_4: String, +v_6: EmitEnv) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{[]}:
      EmitterFinished{None{}}
    case Some{AST.DefTop{v_11} <> _}:
      EmitterFinished{Some{EmitNamed{v_4, v_11, v_6}}}
    case Some{AST.TypeTop{_} <> _}:
      EmitterFinished{Some{EmitNamedBlocked{}}}
    case Some{AST.LawTop{AST.LawDecl{v_22, v_23, _, _}} <> v_26}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_operation{v_22, v_6}}, False{}, v_1001267 => emitter_body_js_native_operation(v_22, v_6), +v_1001263 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_native_law_binders{v_23, 0n}}, False{}, v_1001266 => emitter_body_js_native_law_binders(v_23, 0n), +v_1001264 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_native_law{v_1001263, v_1001264, v_26, v_4, v_6}}, +v_1001265 => EmitterFinished{v_1001265}}}}

def emitter_body_js_named_declarations(v_2: Maybe<&2, List<&2, AST.TopLevel>>, v_4: String, v_6: EmitEnv) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  emitter_match_255(v_2, v_4, v_6)

def emitter_match_256(v_2: Maybe<&2, String>, v_5: Maybe<&2, List<&2, AST.TelescopeItem>>, v_9: String, v_11: EmitEnv, v_7: List<&2, AST.TopLevel>) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  match v_2, v_5:
    case Some{_}, Some{v_17}:
      EmitterFinished{Some{EmitNamedNative{v_9, v_17, v_11}}}
    case Some{_}, None{}:
      EmitterFinished{Some{EmitNamedBlocked{}}}
    case None{}, _:
      EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_named_declarations{Some{v_7}, v_9, v_11}}, False{}, v_1001269 => emitter_body_js_named_declarations(Some{v_7}, v_9, v_11), +v_1001268 => EmitterFinished{v_1001268}}

def emitter_body_js_named_native_law(v_2: Maybe<&2, String>, v_5: Maybe<&2, List<&2, AST.TelescopeItem>>, v_7: List<&2, AST.TopLevel>, v_9: String, v_11: EmitEnv) -> EmitterProgress<Maybe<&2, EmitNamed>>:
  emitter_match_256(v_2, v_5, v_9, v_11, v_7)

def emitter_body_js_named_app(+v_1: String, v_3: List<&2, AST.SyntaxTerm>, +v_5: EmitEnv, v_7: Bool) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_named_owner{v_1, v_5}}, False{}, v_1001272 => emitter_body_js_named_owner(v_1, v_5), +v_1001270 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_app_found{v_1001270, v_1, v_3, v_5, v_7}}, +v_1001271 => EmitterFinished{v_1001271}}}

def emitter_match_257(v_2: Maybe<&2, EmitNamed>, v_6: List<&2, AST.SyntaxTerm>, +v_4: String, +v_8: EmitEnv, v_10: Bool) -> EmitterProgress<String>:
  match v_2:
    case Some{EmitNamed{+v_20, AST.Definition{_, +v_22, +v_23, AST.DefTerm{+v_24}, _, _}, +v_27}}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_operation{v_20, v_27}}, False{}, v_1001277 => emitter_body_js_native_operation(v_20, v_27), +v_1001273 => EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_primitive_checked{v_1001273, v_22}}, False{}, v_1001276 => emitter_body_js_native_primitive_checked(v_1001273, v_22), +v_1001274 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_app_native{v_1001274, v_20, v_22, v_23, v_24, v_6, v_27, v_4, v_8, v_10}}, +v_1001275 => EmitterFinished{v_1001275}}}}
    case Some{EmitNamedNative{+v_34, +v_35, +v_36}}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_operation{v_34, v_36}}, False{}, v_1001282 => emitter_body_js_native_operation(v_34, v_36), +v_1001278 => EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_primitive_checked{v_1001278, v_35}}, False{}, v_1001281 => emitter_body_js_native_primitive_checked(v_1001278, v_35), +v_1001279 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_native_law_app{v_1001279, v_34, v_35, v_6, v_36, v_4, v_8}}, +v_1001280 => EmitterFinished{v_1001280}}}}
    case _:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_reference{v_4}}, False{}, v_1001287 => emitter_body_js_reference(v_4), +v_1001283 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_global_type{v_4, v_8}}, False{}, v_1001286 => emitter_body_js_global_type(v_4, v_8), +v_1001284 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_chain{v_1001283, v_1001284, v_6, v_8}}, +v_1001285 => EmitterFinished{v_1001285}}}}

def emitter_body_js_named_app_found(v_2: Maybe<&2, EmitNamed>, v_4: String, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_10: Bool) -> EmitterProgress<String>:
  emitter_match_257(v_2, v_6, v_4, v_8, v_10)

def emitter_match_258(v_2: Maybe<&2, EmitPrimitive>, v_6: List<&2, AST.TelescopeItem>, +v_8: List<&2, AST.SyntaxTerm>, v_10: EmitEnv, +v_14: EmitEnv, v_4: String, +v_12: String) -> EmitterProgress<String>:
  match v_2:
    case Some{_}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_args{v_6, v_8, v_10, v_14}}, +v_1001288 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_native_app_args{v_1001288, v_4, v_12, v_8, v_14}}, +v_1001289 => EmitterFinished{v_1001289}}}
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_reference{v_12}}, False{}, v_1001294 => emitter_body_js_reference(v_12), +v_1001290 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_global_type{v_12, v_14}}, False{}, v_1001293 => emitter_body_js_global_type(v_12, v_14), +v_1001291 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_chain{v_1001290, v_1001291, v_8, v_14}}, +v_1001292 => EmitterFinished{v_1001292}}}}

def emitter_body_js_named_native_law_app(v_2: Maybe<&2, EmitPrimitive>, v_4: String, v_6: List<&2, AST.TelescopeItem>, v_8: List<&2, AST.SyntaxTerm>, v_10: EmitEnv, v_12: String, v_14: EmitEnv) -> EmitterProgress<String>:
  emitter_match_258(v_2, v_6, v_8, v_10, v_14, v_4, v_12)

def emitter_match_259(v_2: Maybe<&2, EmitPrimitive>, +v_6: List<&2, AST.TelescopeItem>, +v_10: List<&2, AST.SyntaxTerm>, +v_12: EmitEnv, +v_16: EmitEnv, +v_4: String, v_14: String, v_7: AST.OptionalTerm, v_8: AST.SyntaxTerm, v_18: Bool) -> EmitterProgress<String>:
  match v_2:
    case Some{_}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_args{v_6, v_10, v_12, v_16}}, +v_1001295 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_native_app_args{v_1001295, v_4, v_14, v_10, v_16}}, +v_1001296 => EmitterFinished{v_1001296}}}
    case None{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_named_eligible{v_4, v_6, v_7, v_8, v_12}}, +v_1001297 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_app_eligible{v_1001297, v_4, v_6, v_10, v_12, v_14, v_16, v_18}}, +v_1001298 => EmitterFinished{v_1001298}}}

def emitter_body_js_named_app_native(v_2: Maybe<&2, EmitPrimitive>, v_4: String, v_6: List<&2, AST.TelescopeItem>, v_7: AST.OptionalTerm, v_8: AST.SyntaxTerm, v_10: List<&2, AST.SyntaxTerm>, v_12: EmitEnv, v_14: String, v_16: EmitEnv, v_18: Bool) -> EmitterProgress<String>:
  emitter_match_259(v_2, v_6, v_10, v_12, v_16, v_4, v_14, v_7, v_8, v_18)

def emitter_match_260(v_3: Maybe<&2, List<&2, String>>, v_5: String, +v_7: String, +v_11: EmitEnv, v_9: List<&2, AST.SyntaxTerm>) -> EmitterProgress<String>:
  match v_3:
    case Some{v_14}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_named_identifier{v_5}}, False{}, v_1001300 => emitter_body_js_named_identifier(v_5), +v_1001299 => EmitterFinished{String.append(v_1001299, String.append("(", String.append(String.join(v_14, ","), ")")))}}
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_reference{v_7}}, False{}, v_1001305 => emitter_body_js_reference(v_7), +v_1001301 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_global_type{v_7, v_11}}, False{}, v_1001304 => emitter_body_js_global_type(v_7, v_11), +v_1001302 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_chain{v_1001301, v_1001302, v_9, v_11}}, +v_1001303 => EmitterFinished{v_1001303}}}}

def emitter_body_js_native_app_args(v_3: Maybe<&2, List<&2, String>>, v_5: String, v_7: String, v_9: List<&2, AST.SyntaxTerm>, v_11: EmitEnv) -> EmitterProgress<String>:
  emitter_match_260(v_3, v_5, v_7, v_11, v_9)

def emitter_match_261(v_1: Bool, v_5: List<&2, AST.TelescopeItem>, +v_7: List<&2, AST.SyntaxTerm>, v_9: EmitEnv, +v_13: EmitEnv, v_3: String, +v_11: String, v_15: Bool) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_args{v_5, v_7, v_9, v_13}}, +v_1001306 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_app_args{v_1001306, v_3, v_11, v_7, v_13, v_15}}, +v_1001307 => EmitterFinished{v_1001307}}}
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_reference{v_11}}, False{}, v_1001312 => emitter_body_js_reference(v_11), +v_1001308 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_global_type{v_11, v_13}}, False{}, v_1001311 => emitter_body_js_global_type(v_11, v_13), +v_1001309 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_chain{v_1001308, v_1001309, v_7, v_13}}, +v_1001310 => EmitterFinished{v_1001310}}}}

def emitter_body_js_named_app_eligible(v_1: Bool, v_3: String, v_5: List<&2, AST.TelescopeItem>, v_7: List<&2, AST.SyntaxTerm>, v_9: EmitEnv, v_11: String, v_13: EmitEnv, v_15: Bool) -> EmitterProgress<String>:
  emitter_match_261(v_1, v_5, v_7, v_9, v_13, v_3, v_11, v_15)

def emitter_continuation_262(v_1001313: String, v_1001314: String, v_1001315: String, +v_1001316: String, +v_4: List<&2, String>) -> EmitterProgress<String>:
  v_12 = String.append(v_1001313, String.append(v_1001314, String.append(v_1001315, String.append(v_1001316, ","))))
  EmitterFinished{String.append(v_12, String.append(String.join(v_4, ","), ",$td)"))}

def emitter_match_263(v_8: Bool, v_6: Nat, v_1: String, +v_4: List<&2, String>) -> EmitterProgress<String>:
  match v_8:
    case True{}:
      v_1001313 = {"run_named" : String}
      v_1001314 = {Nat.show(v_6) : String}
      v_1001315 = {"(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_named_identifier{v_1}}, False{}, v_1001317 => emitter_body_js_named_identifier(v_1), +v_1001316 => emitter_continuation_262(v_1001313, v_1001314, v_1001315, v_1001316, v_4)}
    case False{}:
      v_1001318 = {"run_many(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_named_identifier{v_1}}, False{}, v_1001320 => emitter_body_js_named_identifier(v_1), +v_1001319 => EmitterFinished{String.append(v_1001318, String.append(v_1001319, String.append(",[", String.append(String.join(v_4, ","), "],$td)"))))}}

def emitter_body_js_named_tail_selected(v_1: String, +v_4: List<&2, String>, v_6: Nat, v_8: Bool) -> EmitterProgress<String>:
  emitter_match_263(v_8, v_6, v_1, v_4)

def emitter_body_js_named_tail(v_1: String, +v_4: List<&2, String>) -> EmitterProgress<String>:
  +v_8 = List.length(&2, String, v_4)
  EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_named_tail_selected{v_1, v_4, v_8, Bool.and(Nat.is_gt(v_8, 0n), Nat.is_le(v_8, 32n))}}, False{}, v_1001322 => emitter_body_js_named_tail_selected(v_1, v_4, v_8, Bool.and(Nat.is_gt(v_8, 0n), Nat.is_le(v_8, 32n))), +v_1001321 => EmitterFinished{v_1001321}}

def emitter_match_264(v_13: Bool, v_5: String, v_16: List<&2, String>) -> EmitterProgress<String>:
  match v_13:
    case True{}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_named_identifier{v_5}}, False{}, v_1001324 => emitter_body_js_named_identifier(v_5), +v_1001323 => EmitterFinished{String.append(v_1001323, String.append("(", String.append(String.join(v_16, ","), ")")))}}
    case False{}:
      emitter_body_js_named_tail(v_5, v_16)

def emitter_match_265(v_3: Maybe<&2, List<&2, String>>, v_13: Bool, v_5: String, +v_7: String, +v_11: EmitEnv, v_9: List<&2, AST.SyntaxTerm>) -> EmitterProgress<String>:
  match v_3:
    case Some{v_16}:
      emitter_match_264(v_13, v_5, v_16)
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_reference{v_7}}, False{}, v_1001330 => emitter_body_js_reference(v_7), +v_1001326 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_global_type{v_7, v_11}}, False{}, v_1001329 => emitter_body_js_global_type(v_7, v_11), +v_1001327 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_chain{v_1001326, v_1001327, v_9, v_11}}, +v_1001328 => EmitterFinished{v_1001328}}}}

def emitter_body_js_named_app_args(v_3: Maybe<&2, List<&2, String>>, v_5: String, v_7: String, v_9: List<&2, AST.SyntaxTerm>, v_11: EmitEnv, v_13: Bool) -> EmitterProgress<String>:
  emitter_match_265(v_3, v_13, v_5, v_7, v_11, v_9)

def emitter_continuation_266(+v_1001334: EmitEnv, v_24: List<&2, AST.TelescopeItem>, v_26: List<&2, AST.SyntaxTerm>, +v_7: EmitEnv, v_19: AST.Quantity, +v_25: AST.SyntaxTerm, v_22: AST.SyntaxTerm, v_5: EmitEnv) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  v_31 = v_1001334
  EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_args{v_24, v_26, v_31, v_7}}, +v_1001335 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_named_arg{v_1001335, v_19, v_25, v_22, v_5, v_7}}, +v_1001336 => EmitterFinished{v_1001336}}}

def emitter_match_267(v_1: List<&2, AST.TelescopeItem>, v_3: List<&2, AST.SyntaxTerm>, +v_5: EmitEnv, +v_7: EmitEnv) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  match v_1, v_3:
    case [], []:
      EmitterFinished{Some{[]}}
    case AST.Binder{v_19, _, _, +v_22, _} <> v_24, +v_25 <> v_26:
      v_1001331 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_22, v_5}}, False{}, v_1001339 => emitter_body_js_close(v_22, v_5), +v_1001332 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_25, v_7}}, False{}, v_1001338 => emitter_body_js_close(v_25, v_7), +v_1001333 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001331, Some{v_1001332}, Some{v_1001333}, v_5}}, False{}, v_1001337 => emitter_body_env_bind(v_1001331, Some{v_1001332}, Some{v_1001333}, v_5), +v_1001334 => emitter_continuation_266(v_1001334, v_24, v_26, v_7, v_19, v_25, v_22, v_5)}}}
    case _, _:
      EmitterFinished{None{}}

def emitter_body_js_named_args(v_1: List<&2, AST.TelescopeItem>, v_3: List<&2, AST.SyntaxTerm>, v_5: EmitEnv, v_7: EmitEnv) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  emitter_match_267(v_1, v_3, v_5, v_7)

def emitter_match_268(v_4: AST.Quantity, v_15: List<&2, String>, v_5: AST.SyntaxTerm, v_10: EmitEnv, v_6: AST.SyntaxTerm, v_8: EmitEnv) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  match v_4:
    case AST.QZero{}:
      EmitterFinished{Some{v_15}}
    case _:
      v_1001340 = {v_5 : AST.SyntaxTerm}
      v_1001341 = {v_10 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_6, v_8}}, False{}, v_1001345 => emitter_body_js_close(v_6, v_8), +v_1001342 => EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term_expected{v_1001340, v_1001341, Some{v_1001342}}}, False{}, v_1001344 => emitter_body_js_term_expected(v_1001340, v_1001341, Some{v_1001342}), +v_1001343 => EmitterFinished{Some{v_1001343 <> v_15}}}}

def emitter_match_269(v_3: Maybe<&2, List<&2, String>>, v_4: AST.Quantity, v_5: AST.SyntaxTerm, v_10: EmitEnv, v_6: AST.SyntaxTerm, v_8: EmitEnv) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  match v_3:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_15}:
      emitter_match_268(v_4, v_15, v_5, v_10, v_6, v_8)

def emitter_body_js_named_arg(v_3: Maybe<&2, List<&2, String>>, v_4: AST.Quantity, v_5: AST.SyntaxTerm, v_6: AST.SyntaxTerm, v_8: EmitEnv, v_10: EmitEnv) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  emitter_match_269(v_3, v_4, v_5, v_10, v_6, v_8)

def emitter_match_270(+v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>) -> EmitterProgress<Pair(AST.SyntaxTerm, List<&2, AST.SyntaxTerm>)>:
  match v_0:
    case AST.TermApp{v_7, v_8, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_spine_at{v_7, v_8 <> v_2}}, v_1001346 => EmitterFinished{v_1001346}}
    case _:
      EmitterFinished{(v_0, v_2)}

def emitter_body_js_app_spine_at(v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>) -> EmitterProgress<Pair(AST.SyntaxTerm, List<&2, AST.SyntaxTerm>)>:
  emitter_match_270(v_0, v_2)

def emitter_match_271(v_4: Maybe<&2, EmitClosure>, v_6: String, +v_12: AST.SyntaxTerm, v_13: List<&2, AST.SyntaxTerm>, v_8: EmitEnv) -> EmitterProgress<String>:
  match v_4:
    case None{}:
      EmitterFinished{"(()=>{throw \"bend: application has no checked signature\"})()"}
    case Some{v_15}:
      v_1001347 = {v_6 : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_15}}, False{}, v_1001350 => emitter_body_js_reduce(v_15), +v_1001348 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_arrow{v_1001347, v_1001348, v_12, v_13, v_8}}, +v_1001349 => EmitterFinished{v_1001349}}}

def emitter_match_272(v_1: List<&2, AST.SyntaxTerm>, v_6: String, v_4: Maybe<&2, EmitClosure>, v_8: EmitEnv) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{v_6}
    case +v_12 <> v_13:
      emitter_match_271(v_4, v_6, v_12, v_13, v_8)

def emitter_body_js_app_chain_args(v_1: List<&2, AST.SyntaxTerm>, v_4: Maybe<&2, EmitClosure>, v_6: String, v_8: EmitEnv) -> EmitterProgress<String>:
  emitter_match_272(v_1, v_6, v_4, v_8)

def emitter_body_js_app_chain(v_1: String, v_4: Maybe<&2, EmitClosure>, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv) -> EmitterProgress<String>:
  emitter_body_js_app_chain_args(v_6, v_4, v_1, v_8)

def emitter_continuation_273(+v_1001357: EmitClosure, v_23: AST.Quantity, v_1: String, v_26: AST.SyntaxTerm, v_10: EmitEnv, v_4: AST.SyntaxTerm, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv) -> EmitterProgress<String>:
  v_39 = {Some{v_1001357} : Maybe<&2, EmitClosure>}
  v_1001358 = {v_23 : AST.Quantity}
  v_1001359 = {v_1 : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_26, v_10}}, False{}, v_1001362 => emitter_body_js_close(v_26, v_10), +v_1001360 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_quantity{v_1001358, v_1001359, Some{v_1001360}, v_39, v_4, v_6, v_8}}, +v_1001361 => EmitterFinished{v_1001361}}}

def emitter_continuation_274(+v_1001370: EmitEnv, v_54: AST.Quantity, v_1: String, v_57: AST.SyntaxTerm, v_10: EmitEnv, v_59: List<&2, AST.TelescopeItem>, v_60: AST.SyntaxTerm, v_4: AST.SyntaxTerm, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv) -> EmitterProgress<String>:
  v_70 = v_1001370
  v_1001371 = {v_54 : AST.Quantity}
  v_1001372 = {v_1 : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_57, v_10}}, False{}, v_1001377 => emitter_body_js_close(v_57, v_10), +v_1001373 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_inferred{v_59, v_60, v_70}}, False{}, v_1001376 => emitter_body_js_close_inferred(v_59, v_60, v_70), +v_1001374 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_quantity{v_1001371, v_1001372, Some{v_1001373}, Some{v_1001374}, v_4, v_6, v_8}}, +v_1001375 => EmitterFinished{v_1001375}}}}

def emitter_continuation_275(+v_1001384: EmitEnv, v_86: AST.Quantity, v_1: String, v_89: AST.SyntaxTerm, v_10: EmitEnv, v_91: List<&2, AST.TelescopeItem>, v_92: AST.OptionalTerm, v_4: AST.SyntaxTerm, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv) -> EmitterProgress<String>:
  v_102 = v_1001384
  v_1001385 = {v_86 : AST.Quantity}
  v_1001386 = {v_1 : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_89, v_10}}, False{}, v_1001391 => emitter_body_js_close(v_89, v_10), +v_1001387 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_declared{v_91, v_92, v_102}}, False{}, v_1001390 => emitter_body_js_close_declared(v_91, v_92, v_102), +v_1001388 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_app_quantity{v_1001385, v_1001386, Some{v_1001387}, Some{v_1001388}, v_4, v_6, v_8}}, +v_1001389 => EmitterFinished{v_1001389}}}}

def emitter_match_276(v_3: EmitClosure, +v_10: EmitEnv, +v_4: AST.SyntaxTerm, +v_8: EmitEnv, v_1: String, v_6: List<&2, AST.SyntaxTerm>) -> EmitterProgress<String>:
  match v_3:
    case EmitClosure{AST.TermAll{v_23, _, _, +v_26, v_27, _}, _, _, _, _, _}:
      v_1001352 = {v_27 : AST.SyntaxTerm}
      v_1001353 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_26, v_10}}, False{}, v_1001366 => emitter_body_js_close(v_26, v_10), +v_1001354 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_4, v_8}}, False{}, v_1001365 => emitter_body_js_close(v_4, v_8), +v_1001355 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001353, Some{v_1001354}, Some{v_1001355}, v_10}}, False{}, v_1001364 => emitter_body_env_bind(v_1001353, Some{v_1001354}, Some{v_1001355}, v_10), +v_1001356 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_1001352, v_1001356}}, False{}, v_1001363 => emitter_body_js_close(v_1001352, v_1001356), +v_1001357 => emitter_continuation_273(v_1001357, v_23, v_1, v_26, v_10, v_4, v_6, v_8)}}}}
    case EmitInferred{AST.Binder{v_54, _, _, +v_57, _} <> v_59, v_60, _, _, _, _, _}:
      v_1001367 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_57, v_10}}, False{}, v_1001380 => emitter_body_js_close(v_57, v_10), +v_1001368 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_4, v_8}}, False{}, v_1001379 => emitter_body_js_close(v_4, v_8), +v_1001369 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001367, Some{v_1001368}, Some{v_1001369}, v_10}}, False{}, v_1001378 => emitter_body_env_bind(v_1001367, Some{v_1001368}, Some{v_1001369}, v_10), +v_1001370 => emitter_continuation_274(v_1001370, v_54, v_1, v_57, v_10, v_59, v_60, v_4, v_6, v_8)}}}
    case EmitDeclared{AST.Binder{v_86, _, _, +v_89, _} <> v_91, v_92, _, _, _, _, _}:
      v_1001381 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_89, v_10}}, False{}, v_1001394 => emitter_body_js_close(v_89, v_10), +v_1001382 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_4, v_8}}, False{}, v_1001393 => emitter_body_js_close(v_4, v_8), +v_1001383 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001381, Some{v_1001382}, Some{v_1001383}, v_10}}, False{}, v_1001392 => emitter_body_env_bind(v_1001381, Some{v_1001382}, Some{v_1001383}, v_10), +v_1001384 => emitter_continuation_275(v_1001384, v_86, v_1, v_89, v_10, v_91, v_92, v_4, v_6, v_8)}}}
    case _:
      EmitterFinished{"(()=>{throw \"bend: application signature is not a function\"})()"}

def emitter_body_js_app_arrow_env(v_1: String, v_3: EmitClosure, v_4: AST.SyntaxTerm, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_10: EmitEnv) -> EmitterProgress<String>:
  emitter_match_276(v_3, v_10, v_4, v_8, v_1, v_6)

def emitter_body_js_app_arrow(v_1: String, +v_3: EmitClosure, v_4: AST.SyntaxTerm, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv) -> EmitterProgress<String>:
  v_1001395 = {v_1 : String}
  v_1001396 = {v_3 : EmitClosure}
  v_1001397 = {v_4 : AST.SyntaxTerm}
  v_1001398 = {v_6 : List<&2, AST.SyntaxTerm>}
  v_1001399 = {v_8 : EmitEnv}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_3}}, False{}, v_1001402 => emitter_body_js_closure_env(v_3), +v_1001400 => emitter_body_js_app_arrow_env(v_1001395, v_1001396, v_1001397, v_1001398, v_1001399, v_1001400)}

def emitter_continuation_277(v_1001404: String, v_1001405: String, v_1001406: String, +v_1001407: String, v_8: Maybe<&2, EmitClosure>, v_11: List<&2, AST.SyntaxTerm>, v_13: EmitEnv) -> EmitterProgress<String>:
  v_20 = String.append(v_1001404, String.append(v_1001405, String.append(v_1001406, String.append(v_1001407, ")"))))
  emitter_body_js_app_chain(v_20, v_8, v_11, v_13)

def emitter_match_278(v_0: AST.Quantity, v_2: String, v_8: Maybe<&2, EmitClosure>, v_11: List<&2, AST.SyntaxTerm>, +v_13: EmitEnv, v_9: AST.SyntaxTerm, v_5: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_0:
    case AST.QZero{}:
      emitter_body_js_app_chain(v_2, v_8, v_11, v_13)
    case _:
      v_1001404 = {"run_tail(run_loop(" : String}
      v_1001405 = {v_2 : String}
      v_1001406 = {")," : String}
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term_expected{v_9, v_13, v_5}}, False{}, v_1001409 => emitter_body_js_term_expected(v_9, v_13, v_5), +v_1001407 => emitter_continuation_277(v_1001404, v_1001405, v_1001406, v_1001407, v_8, v_11, v_13)}

def emitter_body_js_app_quantity(v_0: AST.Quantity, v_2: String, v_5: Maybe<&2, EmitClosure>, v_8: Maybe<&2, EmitClosure>, v_9: AST.SyntaxTerm, v_11: List<&2, AST.SyntaxTerm>, v_13: EmitEnv) -> EmitterProgress<String>:
  emitter_match_278(v_0, v_2, v_8, v_11, v_13, v_9, v_5)

def emitter_match_279(v_7: Maybe<&2, EmitClosure>, v_1: Maybe<&2, AST.Quantity>, v_2: AST.SyntaxTerm, v_4: EmitEnv) -> EmitterProgress<String>:
  match v_7:
    case Some{v_10}:
      v_1001410 = {v_1 : Maybe<&2, AST.Quantity>}
      v_1001411 = {v_2 : AST.SyntaxTerm}
      v_1001412 = {v_4 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_10}}, False{}, v_1001415 => emitter_body_js_reduce(v_10), +v_1001413 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_lambda_view{v_1001410, v_1001411, v_1001412, v_1001413}}, +v_1001414 => EmitterFinished{v_1001414}}}
    case None{}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_lambda_untyped{v_1, v_2, v_4}}, +v_1001416 => EmitterFinished{v_1001416}}

def emitter_body_js_lambda(v_1: Maybe<&2, AST.Quantity>, v_2: AST.SyntaxTerm, v_4: EmitEnv, v_7: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_279(v_7, v_1, v_2, v_4)

def emitter_continuation_280(+v_1001425: EmitClosure, v_21: AST.Quantity, v_35: String, v_2: AST.SyntaxTerm, v_39: EmitEnv) -> EmitterProgress<String>:
  v_44 = {Some{v_1001425} : Maybe<&2, EmitClosure>}
  EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_lambda_quantity{v_21, v_35, v_2, v_39, v_44}}, +v_1001426 => EmitterFinished{v_1001426}}

def emitter_continuation_281(+v_1001420: EmitEnv, v_25: AST.SyntaxTerm, +v_35: String, v_24: AST.SyntaxTerm, +v_8: EmitEnv, v_21: AST.Quantity, v_2: AST.SyntaxTerm) -> EmitterProgress<String>:
  v_39 = v_1001420
  v_1001421 = {v_25 : AST.SyntaxTerm}
  v_1001422 = {v_35 : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_24, v_8}}, False{}, v_1001429 => emitter_body_js_close(v_24, v_8), +v_1001423 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001422, Some{v_1001423}, None{}, v_8}}, False{}, v_1001428 => emitter_body_env_bind(v_1001422, Some{v_1001423}, None{}, v_8), +v_1001424 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_1001421, v_1001424}}, False{}, v_1001427 => emitter_body_js_close(v_1001421, v_1001424), +v_1001425 => emitter_continuation_280(v_1001425, v_21, v_35, v_2, v_39)}}}

def emitter_continuation_282(+v_1001417: String, +v_24: AST.SyntaxTerm, +v_8: EmitEnv, v_4: EmitEnv, v_25: AST.SyntaxTerm, v_21: AST.Quantity, v_2: AST.SyntaxTerm) -> EmitterProgress<String>:
  +v_35 = v_1001417
  v_1001418 = {v_35 : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_24, v_8}}, False{}, v_1001431 => emitter_body_js_close(v_24, v_8), +v_1001419 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001418, Some{v_1001419}, None{}, v_4}}, False{}, v_1001430 => emitter_body_env_bind(v_1001418, Some{v_1001419}, None{}, v_4), +v_1001420 => emitter_continuation_281(v_1001420, v_25, v_35, v_24, v_8, v_21, v_2)}}

def emitter_match_283(v_6: EmitClosure, +v_4: EmitEnv, v_8: EmitEnv, v_2: AST.SyntaxTerm) -> EmitterProgress<String>:
  match v_6:
    case EmitClosure{AST.TermAll{+v_21, _, _, v_24, v_25, _}, _, _, _, _, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_binder_name{v_21, String.append("$x", Nat.show(emitter_pure_env_depth(v_4)))}}, +v_1001417 => emitter_continuation_282(v_1001417, v_24, v_8, v_4, v_25, v_21, v_2)}
    case _:
      EmitterFinished{"(()=>{throw \"bend: lambda signature is not a function\"})()"}

def emitter_body_js_lambda_view_env(v_1: Maybe<&2, AST.Quantity>, v_2: AST.SyntaxTerm, v_4: EmitEnv, v_6: EmitClosure, v_8: EmitEnv) -> EmitterProgress<String>:
  emitter_match_283(v_6, v_4, v_8, v_2)

def emitter_body_js_lambda_view(v_1: Maybe<&2, AST.Quantity>, v_2: AST.SyntaxTerm, v_4: EmitEnv, +v_6: EmitClosure) -> EmitterProgress<String>:
  v_1001432 = {v_1 : Maybe<&2, AST.Quantity>}
  v_1001433 = {v_2 : AST.SyntaxTerm}
  v_1001434 = {v_4 : EmitEnv}
  v_1001435 = {v_6 : EmitClosure}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_6}}, False{}, v_1001438 => emitter_body_js_closure_env(v_6), +v_1001436 => emitter_body_js_lambda_view_env(v_1001432, v_1001433, v_1001434, v_1001435, v_1001436)}

def emitter_body_js_binder_name(v_0: AST.Quantity, v_2: String) -> EmitterProgress<String>:
  match v_0:
    case AST.QZero{}:
      EmitterFinished{"null"}
    case _:
      EmitterFinished{v_2}

def emitter_body_js_lambda_untyped(v_1: Maybe<&2, AST.Quantity>, v_2: AST.SyntaxTerm, v_4: EmitEnv) -> EmitterProgress<String>:
  match v_1:
    case Some{AST.QZero{}}:
      v_1001439 = {v_2 : AST.SyntaxTerm}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_push{"null", v_4}}, False{}, v_1001442 => emitter_body_env_push("null", v_4), +v_1001440 => emitter_body_js_term_tail_expected(v_1001439, v_1001440, None{})}
    case _:
      EmitterFinished{"(()=>{throw \"bend: lambda has no checked signature\"})()"}

def emitter_match_286(v_0: AST.Quantity, v_3: AST.SyntaxTerm, v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>, v_2: String) -> EmitterProgress<String>:
  match v_0:
    case AST.QZero{}:
      emitter_body_js_term_tail_expected(v_3, v_5, v_8)
    case _:
      v_1001444 = {v_2 : String}
      EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_3, v_5, v_8}}, False{}, v_1001447 => emitter_body_js_term_tail_expected(v_3, v_5, v_8), +v_1001445 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_closure{v_1001444, v_1001445}}, +v_1001446 => EmitterFinished{v_1001446}}}

def emitter_body_js_lambda_quantity(v_0: AST.Quantity, v_2: String, v_3: AST.SyntaxTerm, v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_286(v_0, v_3, v_5, v_8, v_2)

def emitter_body_js_closure(v_1: String, v_3: String) -> EmitterProgress<String>:
  EmitterFinished{String.append("run_clo((", String.append(v_1, String.append(",$raw=undefined)=>run_force(", String.append(v_3, ",$raw))"))))}

def emitter_body_env_depth(v_1: EmitEnv) -> EmitterProgress<Nat>:
  EmitterFinished{emitter_pure_env_depth(v_1)}

def emitter_match_287(v_3: EmitEnv, v_1: Nat) -> EmitterProgress<EmitEnv>:
  match v_3:
    case EmitEnv{v_10, v_11, v_12, v_13, v_14}:
      EmitterFinished{EmitEnv{v_10, v_11, v_12, v_13, Nat.add(Nat.add(v_14, v_1), 1n)}}

def emitter_body_env_reserve_names(v_1: Nat, v_3: EmitEnv) -> EmitterProgress<EmitEnv>:
  emitter_match_287(v_3, v_1)

def emitter_continuation_288(v_2: AST.SyntaxTerm, v_5: EmitEnv, v_1001454: String, v_1001455: String, v_1001456: String, +v_1001457: String) -> EmitterProgress<String>:
  v_1001458 = {")(" : String}
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term{v_2, v_5}}, False{}, v_1001460 => emitter_body_js_term(v_2, v_5), +v_1001459 => EmitterFinished{String.append(v_1001454, String.append(v_1001455, String.append(v_1001456, String.append(v_1001457, String.append(v_1001458, String.append(v_1001459, ")"))))))}}

def emitter_continuation_289(+v_1001453: EmitEnv, v_12: String, v_3: AST.SyntaxTerm, v_8: Maybe<&2, EmitClosure>, v_2: AST.SyntaxTerm, v_5: EmitEnv) -> EmitterProgress<String>:
  v_17 = v_1001453
  v_1001454 = {"((" : String}
  v_1001455 = {v_12 : String}
  v_1001456 = {") => " : String}
  EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_3, v_17, v_8}}, False{}, v_1001461 => emitter_body_js_term_tail_expected(v_3, v_17, v_8), +v_1001457 => emitter_continuation_288(v_2, v_5, v_1001454, v_1001455, v_1001456, v_1001457)}

def emitter_body_js_term_sub(v_1: Nat, +v_2: AST.SyntaxTerm, v_3: AST.SyntaxTerm, +v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  +v_12 = String.append("$sub", Nat.show(emitter_pure_env_depth(v_5)))
  v_1001448 = {v_5 : EmitEnv}
  v_1001449 = {v_1 : Nat}
  v_1001450 = {v_12 : String}
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_2, v_5}}, False{}, v_1001464 => emitter_body_js_type(v_2, v_5), +v_1001451 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_2, v_5}}, False{}, v_1001463 => emitter_body_js_close(v_2, v_5), +v_1001452 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_env_insert_binding{v_1001448, v_1001449, EmitBinding{v_1001450, v_1001451, Some{v_1001452}}}}, False{}, v_1001462 => emitter_body_env_insert_binding(v_1001448, v_1001449, EmitBinding{v_1001450, v_1001451, Some{v_1001452}}), +v_1001453 => emitter_continuation_289(v_1001453, v_12, v_3, v_8, v_2, v_5)}}}

def emitter_continuation_290(+v_1001469: EmitEnv, v_25: List<&2, String>, v_26: List<&2, AST.Quantity>, v_28: List<&2, AST.SyntaxTerm>, v_7: AST.SyntaxTerm, v_9: EmitEnv, v_14: Maybe<&2, EmitClosure>, v_16: Nat) -> EmitterProgress<String>:
  v_33 = v_1001469
  EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_let{v_25, v_26, v_28, v_7, v_9, v_33, v_14, Nat.add(v_16, 1n)}}, +v_1001470 => EmitterFinished{v_1001470}}

def emitter_continuation_291(+v_47: AST.SyntaxTerm, v_9: EmitEnv, v_1001478: String, v_1001479: String, v_1001480: String, +v_1001481: String) -> EmitterProgress<String>:
  v_1001482 = {")(" : String}
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term{v_47, v_9}}, False{}, v_1001484 => emitter_body_js_term(v_47, v_9), +v_1001483 => EmitterFinished{String.append(v_1001478, String.append(v_1001479, String.append(v_1001480, String.append(v_1001481, String.append(v_1001482, String.append(v_1001483, ")"))))))}}

def emitter_continuation_292(+v_1001477: EmitEnv, v_51: String, v_44: List<&2, String>, v_46: List<&2, AST.Quantity>, v_48: List<&2, AST.SyntaxTerm>, v_7: AST.SyntaxTerm, +v_9: EmitEnv, v_14: Maybe<&2, EmitClosure>, v_16: Nat, +v_47: AST.SyntaxTerm) -> EmitterProgress<String>:
  v_56 = v_1001477
  v_1001478 = {"((" : String}
  v_1001479 = {v_51 : String}
  v_1001480 = {") => " : String}
  EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_term_let{v_44, v_46, v_48, v_7, v_9, v_56, v_14, Nat.add(v_16, 1n)}}, +v_1001481 => emitter_continuation_291(v_47, v_9, v_1001478, v_1001479, v_1001480, v_1001481)}

def emitter_match_293(v_2: List<&2, String>, v_4: List<&2, AST.Quantity>, v_6: List<&2, AST.SyntaxTerm>, v_7: AST.SyntaxTerm, +v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>, +v_9: EmitEnv, v_16: Nat) -> EmitterProgress<String>:
  match v_2, v_4, v_6:
    case [], [], []:
      emitter_body_js_term_tail_expected(v_7, v_11, v_14)
    case +v_24 <> v_25, AST.QZero{} <> v_26, +v_27 <> v_28:
      v_1001466 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_27, v_9}}, False{}, v_1001473 => emitter_body_js_type(v_27, v_9), +v_1001467 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_27, v_9}}, False{}, v_1001472 => emitter_body_js_close(v_27, v_9), +v_1001468 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001466, v_1001467, Some{v_1001468}, v_11}}, False{}, v_1001471 => emitter_body_env_bind(v_1001466, v_1001467, Some{v_1001468}, v_11), +v_1001469 => emitter_continuation_290(v_1001469, v_25, v_26, v_28, v_7, v_9, v_14, v_16)}}}
    case +v_43 <> v_44, +v_45 <> v_46, +v_47 <> v_48:
      +v_51 = String.append("$l", Nat.show(emitter_pure_env_depth(v_11)))
      v_1001474 = {v_51 : String}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_47, v_9}}, False{}, v_1001487 => emitter_body_js_type(v_47, v_9), +v_1001475 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_47, v_9}}, False{}, v_1001486 => emitter_body_js_close(v_47, v_9), +v_1001476 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001474, v_1001475, Some{v_1001476}, v_11}}, False{}, v_1001485 => emitter_body_env_bind(v_1001474, v_1001475, Some{v_1001476}, v_11), +v_1001477 => emitter_continuation_292(v_1001477, v_51, v_44, v_46, v_48, v_7, v_9, v_14, v_16, v_47)}}}
    case _, _, _:
      EmitterFinished{"(()=>{throw \"bend: malformed let bindings\"})()"}

def emitter_body_js_term_let(v_2: List<&2, String>, v_4: List<&2, AST.Quantity>, v_6: List<&2, AST.SyntaxTerm>, v_7: AST.SyntaxTerm, v_9: EmitEnv, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>, v_16: Nat) -> EmitterProgress<String>:
  emitter_match_293(v_2, v_4, v_6, v_7, v_11, v_14, v_9, v_16)

def emitter_continuation_294(+v_42: AST.SyntaxTerm, v_6: EmitEnv, v_1001505: String, v_1001506: String, v_1001507: String, +v_1001508: String) -> EmitterProgress<String>:
  v_1001509 = {")(" : String}
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term{v_42, v_6}}, False{}, v_1001511 => emitter_body_js_term(v_42, v_6), +v_1001510 => EmitterFinished{String.append(v_1001505, String.append(v_1001506, String.append(v_1001507, String.append(v_1001508, String.append(v_1001509, String.append(v_1001510, ")"))))))}}

def emitter_continuation_295(+v_1001504: EmitEnv, v_46: String, v_41: List<&2, AST.SyntaxPattern>, v_43: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, +v_6: EmitEnv, v_11: Maybe<&2, EmitClosure>, +v_42: AST.SyntaxTerm) -> EmitterProgress<String>:
  v_51 = v_1001504
  v_1001505 = {"((" : String}
  v_1001506 = {v_46 : String}
  v_1001507 = {") => " : String}
  EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_body_local{v_41, v_43, v_4, v_6, v_51, v_11}}, +v_1001508 => emitter_continuation_294(v_42, v_6, v_1001505, v_1001506, v_1001507, v_1001508)}

def emitter_match_296(+v_1: List<&2, AST.SyntaxPattern>, +v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, +v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>, +v_6: EmitEnv) -> EmitterProgress<String>:
  match v_1, v_3:
    case [], []:
      emitter_body_js_term_tail_expected(v_4, v_8, v_11)
    case AST.PatternVar{_, _, AST.QZero{}, _} <> v_23, +v_24 <> v_25:
      v_1001489 = {v_23 : List<&2, AST.SyntaxPattern>}
      v_1001490 = {v_25 : List<&2, AST.SyntaxTerm>}
      v_1001491 = {v_4 : AST.SyntaxTerm}
      v_1001492 = {v_6 : EmitEnv}
      v_1001493 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_24, v_6}}, False{}, v_1001500 => emitter_body_js_type(v_24, v_6), +v_1001494 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_24, v_6}}, False{}, v_1001499 => emitter_body_js_close(v_24, v_6), +v_1001495 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001493, v_1001494, Some{v_1001495}, v_8}}, False{}, v_1001498 => emitter_body_env_bind(v_1001493, v_1001494, Some{v_1001495}, v_8), +v_1001496 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_body_local{v_1001489, v_1001490, v_1001491, v_1001492, v_1001496, v_11}}, +v_1001497 => EmitterFinished{v_1001497}}}}}
    case AST.PatternVar{_, _, _, _} <> v_41, +v_42 <> v_43:
      +v_46 = String.append("$local", Nat.show(emitter_pure_env_depth(v_8)))
      v_1001501 = {v_46 : String}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_42, v_6}}, False{}, v_1001514 => emitter_body_js_type(v_42, v_6), +v_1001502 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_42, v_6}}, False{}, v_1001513 => emitter_body_js_close(v_42, v_6), +v_1001503 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001501, v_1001502, Some{v_1001503}, v_8}}, False{}, v_1001512 => emitter_body_env_bind(v_1001501, v_1001502, Some{v_1001503}, v_8), +v_1001504 => emitter_continuation_295(v_1001504, v_46, v_41, v_43, v_4, v_6, v_11, v_42)}}}
    case AST.PatternCtr{_, _, _} <> _, +_ <> _:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_body_local_constructor{v_1, v_3, v_4, v_6, v_8, v_11}}, +v_1001515 => EmitterFinished{v_1001515}}
    case _, _:
      EmitterFinished{"(()=>{throw \"bend: malformed local bindings\"})()"}

def emitter_body_js_body_local(v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, v_6: EmitEnv, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_296(v_1, v_3, v_4, v_8, v_11, v_6)

def emitter_continuation_297(v_1001526: String, +v_1001527: String, v_25: String) -> EmitterProgress<String>:
  v_28 = String.append(v_1001526, v_1001527)
  EmitterFinished{String.append(v_28, String.append(v_25, "throw \"bend: runtime fail-stop\";})()"))}

def emitter_continuation_298(+v_1001525: String, v_3: List<&2, AST.SyntaxTerm>, v_6: EmitEnv) -> EmitterProgress<String>:
  v_25 = v_1001525
  v_1001526 = {"(()=>{" : String}
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_scrutinees{v_3, v_6, 0n}}, +v_1001527 => emitter_continuation_297(v_1001526, v_1001527, v_25)}

def emitter_continuation_299(+v_1001519: List<&2, Maybe<&2, EmitClosure>>, v_1: List<&2, AST.SyntaxPattern>, v_4: AST.SyntaxTerm, v_17: List<&2, String>, v_14: Nat, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>, v_3: List<&2, AST.SyntaxTerm>, v_6: EmitEnv) -> EmitterProgress<String>:
  v_21 = v_1001519
  v_1001520 = {v_1 : List<&2, AST.SyntaxPattern>}
  v_1001521 = {v_4 : AST.SyntaxTerm}
  v_1001522 = {v_17 : List<&2, String>}
  v_1001523 = {v_21 : List<&2, Maybe<&2, EmitClosure>>}
  EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_env_reserve_names{v_14, v_8}}, False{}, v_1001528 => emitter_body_env_reserve_names(v_14, v_8), +v_1001524 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_case_typed{v_1001520, v_1001521, v_1001522, v_1001523, v_1001524, v_11}}, +v_1001525 => emitter_continuation_298(v_1001525, v_3, v_6)}}

def emitter_continuation_300(+v_1001516: List<&2, String>, +v_1: List<&2, AST.SyntaxPattern>, +v_3: List<&2, AST.SyntaxTerm>, +v_6: EmitEnv, v_4: AST.SyntaxTerm, v_14: Nat, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_17 = v_1001516
  v_1001517 = {v_1 : List<&2, AST.SyntaxPattern>}
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_scrutinee_types{v_3, v_6}}, False{}, v_1001530 => emitter_body_js_scrutinee_types(v_3, v_6), +v_1001518 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_pattern_types{v_1001517, v_1001518, v_6}}, False{}, v_1001529 => emitter_body_js_pattern_types(v_1001517, v_1001518, v_6), +v_1001519 => emitter_continuation_299(v_1001519, v_1, v_4, v_17, v_14, v_8, v_11, v_3, v_6)}}

def emitter_body_js_body_local_constructor(v_1: List<&2, AST.SyntaxPattern>, +v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, +v_6: EmitEnv, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  +v_14 = List.length(&2, AST.SyntaxTerm, v_3)
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_scrutinee_names{v_14, v_6}}, +v_1001516 => emitter_continuation_300(v_1001516, v_1, v_3, v_6, v_4, v_14, v_8, v_11)}

def emitter_continuation_301(+v_1001532: String, +v_1: String, +v_3: List<&2, AST.SyntaxTerm>, +v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  +v_13 = v_1001532
  EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_native_word_literal{v_13, v_1, v_3, v_5}}, +v_1001533 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_constructor_literal{v_1001533, v_13, v_1, v_3, v_5, v_8}}, +v_1001534 => EmitterFinished{v_1001534}}}

def emitter_body_js_constructor(+v_1: String, v_3: List<&2, AST.SyntaxTerm>, +v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_native_identity{v_1, v_5}}, +v_1001531 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_native{v_1001531}}, +v_1001532 => emitter_continuation_301(v_1001532, v_1, v_3, v_5, v_8)}}

def emitter_match_302(v_2: Maybe<&2, String>, v_4: String, +v_6: String, v_8: List<&2, AST.SyntaxTerm>, v_13: Maybe<&2, EmitClosure>, +v_10: EmitEnv) -> EmitterProgress<String>:
  match v_2:
    case Some{v_16}:
      EmitterFinished{v_16}
    case None{}:
      v_1001535 = {v_4 : String}
      v_1001536 = {v_6 : String}
      v_1001537 = {v_8 : List<&2, AST.SyntaxTerm>}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_signature{v_6, v_13, v_10}}, False{}, v_1001541 => emitter_body_js_constructor_signature(v_6, v_13, v_10), +v_1001538 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_args{v_1001537, v_1001538, v_10}}, +v_1001539 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_render{v_1001535, v_1001536, v_1001539, v_10}}, +v_1001540 => EmitterFinished{v_1001540}}}}

def emitter_body_js_constructor_literal(v_2: Maybe<&2, String>, v_4: String, v_6: String, v_8: List<&2, AST.SyntaxTerm>, v_10: EmitEnv, v_13: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_302(v_2, v_4, v_6, v_8, v_13, v_10)

def emitter_match_303(+v_1: String, v_5: List<&2, AST.SyntaxTerm>, v_3: String, +v_7: EmitEnv) -> EmitterProgress<Maybe<&2, String>>:
  match v_1, v_5:
    case "U", [+v_11]:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_3, v_7}}, False{}, v_1001545 => emitter_body_js_constructor_decl(v_3, v_7), +v_1001542 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_word_identity{v_1001542}}, +v_1001543 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_native_word_declared{v_1001543, v_1, v_11, v_7}}, +v_1001544 => EmitterFinished{v_1001544}}}}
    case "F", [+v_16]:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_3, v_7}}, False{}, v_1001549 => emitter_body_js_constructor_decl(v_3, v_7), +v_1001546 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_word_identity{v_1001546}}, +v_1001547 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_native_word_declared{v_1001547, v_1, v_16, v_7}}, +v_1001548 => EmitterFinished{v_1001548}}}}
    case _, _:
      EmitterFinished{None{}}

def emitter_body_js_native_word_literal(v_1: String, v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv) -> EmitterProgress<Maybe<&2, String>>:
  emitter_match_303(v_1, v_5, v_3, v_7)

def emitter_body_js_native_word_declared(v_1: String, v_3: String, v_4: AST.SyntaxTerm, v_6: EmitEnv) -> EmitterProgress<Maybe<&2, String>>:
  match v_1, v_3:
    case "U32.U32", "U":
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_closed_word{32n, v_4, v_6}}, +v_1001550 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_word_literal_render{v_1001550, False{}}}, +v_1001551 => EmitterFinished{v_1001551}}}
    case "F32.F32", "F":
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_closed_word{32n, v_4, v_6}}, +v_1001552 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_word_literal_render{v_1001552, True{}}}, +v_1001553 => EmitterFinished{v_1001553}}}
    case _, _:
      EmitterFinished{None{}}

def emitter_body_js_word_literal_render(v_2: Maybe<&2, Nat>, v_4: Bool) -> EmitterProgress<Maybe<&2, String>>:
  match v_2, v_4:
    case Some{v_8}, False{}:
      EmitterFinished{Some{Nat.show(v_8)}}
    case Some{v_10}, True{}:
      EmitterFinished{Some{String.append("f32_from_bits(", String.append(Nat.show(v_10), ")"))}}
    case None{}, _:
      EmitterFinished{None{}}

def emitter_body_js_word_identity(v_2: Maybe<&2, EmitConstructor>) -> EmitterProgress<String>:
  match v_2:
    case Some{EmitConstructor{v_9, v_10, _, _, v_13}}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_native_origin{emitter_pure_js_base_origin(v_13), v_10, v_9}}, +v_1001554 => EmitterFinished{v_1001554}}
    case None{}:
      EmitterFinished{""}

def emitter_match_307(v_2: AST.SyntaxTerm, +v_1: Nat, +v_4: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_2:
    case AST.TermAnn{v_10, _, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_closed_word{v_1, v_10, v_4}}, +v_1001555 => EmitterFinished{v_1001555}}
    case AST.TermCtr{v_17, v_18, _}:
      +v_1001556 = {v_1 : Nat}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_17, v_4}}, False{}, v_1001561 => emitter_body_js_constructor_decl(v_17, v_4), +v_1001557 => EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_word_identity{v_1001557}}, False{}, v_1001560 => emitter_body_js_word_identity(v_1001557), +v_1001558 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_closed_word_constructor{v_1001556, v_1001558, v_18, v_4}}, +v_1001559 => EmitterFinished{v_1001559}}}}
    case _:
      EmitterFinished{None{}}

def emitter_body_js_closed_word(+v_1: Nat, v_2: AST.SyntaxTerm, v_4: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  emitter_match_307(v_2, v_1, v_4)

def emitter_match_308(+v_1: Nat, v_3: String, v_5: List<&2, AST.SyntaxTerm>, +v_7: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_1, v_3, v_5:
    case 0n, "Word.Nil.WNil", []:
      EmitterFinished{Some{0n}}
    case 1n+v_13, "Word.Con.WCon", [+v_14, +v_15]:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_closed_bit{v_14, v_7}}, +v_1001562 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_closed_word_bit{v_1001562, v_13, v_15, v_7}}, +v_1001563 => EmitterFinished{v_1001563}}}
    case _, _, _:
      EmitterFinished{None{}}

def emitter_body_js_closed_word_constructor(+v_1: Nat, v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  emitter_match_308(v_1, v_3, v_5, v_7)

def emitter_body_js_closed_bit(v_0: AST.SyntaxTerm, v_2: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_0:
    case AST.TermAnn{v_8, _, _}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_closed_bit{v_8, v_2}}, +v_1001564 => EmitterFinished{v_1001564}}
    case AST.TermCtr{v_14, [], _}:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_14, v_2}}, False{}, v_1001569 => emitter_body_js_constructor_decl(v_14, v_2), +v_1001565 => EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_word_identity{v_1001565}}, False{}, v_1001568 => emitter_body_js_word_identity(v_1001565), +v_1001566 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_closed_bit_identity{v_1001566}}, +v_1001567 => EmitterFinished{v_1001567}}}}
    case _:
      EmitterFinished{None{}}

def emitter_body_js_closed_bit_identity(v_1: String) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_1:
    case "Bool.False":
      EmitterFinished{Some{0n}}
    case "Bool.True":
      EmitterFinished{Some{1n}}
    case _:
      EmitterFinished{None{}}

def emitter_body_js_closed_word_bit(v_2: Maybe<&2, Nat>, v_4: Nat, v_5: AST.SyntaxTerm, v_7: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_11}:
      v_1001570 = {v_11 : Nat}
      EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_closed_word{v_4, v_5, v_7}}, False{}, v_1001573 => emitter_body_js_closed_word(v_4, v_5, v_7), +v_1001571 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_closed_word_combine{v_1001570, v_1001571}}, +v_1001572 => EmitterFinished{v_1001572}}}

def emitter_match_312(v_4: Maybe<&2, Nat>, v_1: Nat) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_4:
    case Some{v_8}:
      EmitterFinished{Some{Nat.add(Nat.mul(v_8, 2n), v_1)}}
    case None{}:
      EmitterFinished{None{}}

def emitter_body_js_closed_word_combine(v_1: Nat, v_4: Maybe<&2, Nat>) -> EmitterProgress<Maybe<&2, Nat>>:
  emitter_match_312(v_4, v_1)

def emitter_body_js_string_literal(+v_2: List<&2, U32>, +v_3: AST.StringLiteralNames, +v_4: AST.SourceSpan, +v_6: EmitEnv, v_9: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_string_names_native{v_3, v_6}}, +v_1001574 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_string_literal_authorized{v_1001574, v_2, v_3, v_4, v_6, v_9}}, +v_1001575 => EmitterFinished{v_1001575}}}

def emitter_body_js_string_literal_authorized(v_1: Bool, +v_4: List<&2, U32>, v_5: AST.StringLiteralNames, v_6: AST.SourceSpan, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_string_scalar_chars{v_4}}, +v_1001576 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_string_literal_payload{v_1001576, v_4, v_5, v_6, v_8, v_11}}, +v_1001577 => EmitterFinished{v_1001577}}}
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term_expected{AST.string_desugar(v_4, v_5, v_6), v_8, v_11}}, False{}, v_1001579 => emitter_body_js_term_expected(AST.string_desugar(v_4, v_5, v_6), v_8, v_11), +v_1001578 => EmitterFinished{v_1001578}}

def emitter_body_js_string_literal_payload(v_3: Maybe<&2, List<&2, Char>>, v_6: List<&2, U32>, v_7: AST.StringLiteralNames, v_8: AST.SourceSpan, v_10: EmitEnv, v_13: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_3:
    case Some{v_16}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{String.from_list(v_16)}}, False{}, v_1001581 => emitter_body_js_quote(String.from_list(v_16)), +v_1001580 => EmitterFinished{v_1001580}}
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term_expected{AST.string_desugar(v_6, v_7, v_8), v_10, v_13}}, False{}, v_1001583 => emitter_body_js_term_expected(AST.string_desugar(v_6, v_7, v_8), v_10, v_13), +v_1001582 => EmitterFinished{v_1001582}}

def emitter_body_js_string_scalar_chars(v_2: List<&2, U32>) -> EmitterProgress<Maybe<&2, List<&2, Char>>>:
  match v_2:
    case []:
      EmitterFinished{Some{[]}}
    case +v_8 <> v_9:
      EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_string_scalar_char{Bool.and(U32.is_le(v_8, 1114111), Bool.or(U32.is_lt(v_8, 55296), U32.is_gt(v_8, 57343))), v_8, v_9}}, +v_1001584 => EmitterFinished{v_1001584}}

def emitter_match_316(v_1: Bool, v_6: List<&2, U32>, v_3: U32) -> EmitterProgress<Maybe<&2, List<&2, Char>>>:
  match v_1:
    case False{}:
      EmitterFinished{None{}}
    case True{}:
      EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_string_scalar_chars{v_6}}, False{}, v_1001587 => emitter_body_js_string_scalar_chars(v_6), +v_1001585 => EmitterPending{EmitterRequestGroup_3{EmitterRequest_js_string_scalar_cons{v_1001585, v_3}}, +v_1001586 => EmitterFinished{v_1001586}}}

def emitter_body_js_string_scalar_char(v_1: Bool, v_3: U32, v_6: List<&2, U32>) -> EmitterProgress<Maybe<&2, List<&2, Char>>>:
  emitter_match_316(v_1, v_6, v_3)

def emitter_body_js_string_scalar_cons(v_3: Maybe<&2, List<&2, Char>>, v_5: U32) -> EmitterProgress<Maybe<&2, List<&2, Char>>>:
  match v_3:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_10}:
      EmitterFinished{Some{Char.from_u32(v_5) <> v_10}}

def emitter_body_js_string_names_native(v_0: AST.StringLiteralNames, +v_2: EmitEnv) -> EmitterProgress<Bool>:
  match v_0:
    case AST.StringLiteralNames{v_12, v_13, v_14, v_15, v_16, v_17, v_18, v_19}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_constructor_native{v_12, "String.SNil", v_2}}, +v_1001588 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_constructor_native{v_13, "String.SCon", v_2}}, +v_1001589 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_constructor_native{v_14, "Char.Chr", v_2}}, +v_1001590 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_constructor_native{v_15, "U32.U32", v_2}}, +v_1001591 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_constructor_native{v_16, "Word.Nil.WNil", v_2}}, +v_1001592 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_constructor_native{v_17, "Word.Con.WCon", v_2}}, +v_1001593 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_constructor_native{v_18, "Bool.False", v_2}}, +v_1001594 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_constructor_native{v_19, "Bool.True", v_2}}, +v_1001595 => EmitterFinished{Bool.and(v_1001588, Bool.and(v_1001589, Bool.and(v_1001590, Bool.and(v_1001591, Bool.and(v_1001592, Bool.and(v_1001593, Bool.and(v_1001594, v_1001595)))))))}}}}}}}}}

def emitter_body_js_string_constructor_native(+v_1: String, +v_3: String, +v_5: EmitEnv) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_1, v_5}}, False{}, v_1001600 => emitter_body_js_constructor_decl(v_1, v_5), +v_1001596 => EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_word_identity{v_1001596}}, False{}, v_1001599 => emitter_body_js_word_identity(v_1001596), +v_1001597 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_constructor_schema{v_1, v_3, v_5}}, +v_1001598 => EmitterFinished{Bool.and(String.eq(v_1001597, v_3), v_1001598)}}}}

def emitter_match_319(+v_12: EmitScope, +v_1: String, v_3: String) -> EmitterProgress<Bool>:
  match v_12:
    case EmitScope{_, _, EmitCatalog{_, _, v_27, _}}:
      +v_1001601 = {v_27 : Map<&2, EmitModuleIndex>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_scope_key{v_1, v_12}}, False{}, v_1001604 => emitter_body_js_scope_key(v_1, v_12), +v_1001602 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_owner{IndexLookup.find(EmitModuleIndex, v_1001601, v_1001602), v_1, v_3, v_12}}, +v_1001603 => EmitterFinished{v_1001603}}}

def emitter_match_320(v_5: EmitEnv, v_1: String, v_3: String) -> EmitterProgress<Bool>:
  match v_5:
    case EmitEnv{+v_12, _, _, _, _}:
      emitter_match_319(v_12, v_1, v_3)

def emitter_body_js_string_constructor_schema(v_1: String, v_3: String, v_5: EmitEnv) -> EmitterProgress<Bool>:
  emitter_match_320(v_5, v_1, v_3)

def emitter_match_321(v_8: EmitScope, +v_4: String, v_6: String) -> EmitterProgress<Bool>:
  match v_8:
    case EmitScope{_, _, EmitCatalog{_, _, v_33, _}}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_global{IndexLookup.find(EmitModuleIndex, v_33, v_4), v_4, v_6}}, +v_1001609 => EmitterFinished{v_1001609}}

def emitter_match_322(v_2: Maybe<&2, EmitModuleIndex>, v_4: String, v_8: EmitScope, v_6: String) -> EmitterProgress<Bool>:
  match v_2:
    case Some{EmitModuleIndex{v_15, _, _, v_18, _}}:
      +v_1001605 = {v_18 : Map<&2, EmitConstructorOwner>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_scope_key{v_4, v_8}}, False{}, v_1001608 => emitter_body_js_scope_key(v_4, v_8), +v_1001606 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_decl{IndexLookup.find(EmitConstructorOwner, v_1001605, v_1001606), v_6, v_15}}, +v_1001607 => EmitterFinished{v_1001607}}}
    case None{}:
      emitter_match_321(v_8, v_4, v_6)

def emitter_body_js_string_schema_owner(v_2: Maybe<&2, EmitModuleIndex>, v_4: String, v_6: String, v_8: EmitScope) -> EmitterProgress<Bool>:
  emitter_match_322(v_2, v_4, v_8, v_6)

def emitter_body_js_string_schema_global(v_2: Maybe<&2, EmitModuleIndex>, v_4: String, v_6: String) -> EmitterProgress<Bool>:
  match v_2:
    case Some{EmitModuleIndex{v_13, _, _, v_16, _}}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_decl{IndexLookup.find(EmitConstructorOwner, v_16, v_4), v_6, v_13}}, +v_1001610 => EmitterFinished{v_1001610}}
    case None{}:
      EmitterFinished{False{}}

def emitter_body_js_string_schema_decl(v_2: Maybe<&2, EmitConstructorOwner>, v_4: String, v_6: String) -> EmitterProgress<Bool>:
  match v_2:
    case Some{EmitConstructorOwner{AST.TypeDecl{_, v_18, AST.TermType{AST.TermQuantity{AST.QMany{}, _}, _}, _, _}, AST.Constructor{_, v_24, _}}}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_fields{v_4, v_18, v_24, v_6}}, +v_1001611 => EmitterFinished{v_1001611}}
    case _:
      EmitterFinished{False{}}

def emitter_body_js_string_schema_fields(v_1: String, v_3: List<&2, AST.TelescopeItem>, v_5: List<&2, AST.TelescopeItem>, +v_7: String) -> EmitterProgress<Bool>:
  match v_1, v_3, v_5:
    case "String.SNil", [], []:
      EmitterFinished{True{}}
    case "Bool.False", [], []:
      EmitterFinished{True{}}
    case "Bool.True", [], []:
      EmitterFinished{True{}}
    case "Word.Nil.WNil", [], []:
      EmitterFinished{True{}}
    case "String.SCon", [], [AST.Binder{AST.QOne{}, _, 0n, v_16, _}, AST.Binder{AST.QOne{}, _, 1n, v_19, _}]:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_ref{v_16, "Char", v_7}}, +v_1001612 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_ref{v_19, "String", v_7}}, +v_1001613 => EmitterFinished{Bool.and(v_1001612, v_1001613)}}}
    case "Char.Chr", [], [AST.Binder{AST.QOne{}, _, 0n, v_27, _}]:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_ref{v_27, "U32", v_7}}, +v_1001614 => EmitterFinished{v_1001614}}
    case "U32.U32", [], [AST.Binder{AST.QOne{}, _, 0n, AST.TermApp{v_36, v_37, _}, _}]:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_ref{v_36, "Word", v_7}}, +v_1001615 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_nat{v_37, 32n, v_7}}, +v_1001616 => EmitterFinished{Bool.and(v_1001615, v_1001616)}}}
    case "Word.Con.WCon", [AST.Binder{AST.QZero{}, _, 0n, v_55, _}], [AST.Binder{AST.QOne{}, _, 1n, v_58, _}, AST.Binder{AST.QOne{}, _, 2n, AST.TermApp{v_61, AST.TermVar{_, 1n, _}, _}, _}]:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_ref{v_55, "Nat", v_7}}, +v_1001617 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_ref{v_58, "Bool", v_7}}, +v_1001618 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_ref{v_61, "Word", v_7}}, +v_1001619 => EmitterFinished{Bool.and(v_1001617, Bool.and(v_1001618, v_1001619))}}}}
    case _, _, _:
      EmitterFinished{False{}}

def emitter_body_js_string_schema_nat(v_0: AST.SyntaxTerm, v_2: Nat, +v_4: String) -> EmitterProgress<Bool>:
  match v_0, v_2:
    case AST.TermCtr{v_8, [], _}, 0n:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_key{v_8, "Zero", v_4}}, +v_1001620 => EmitterFinished{v_1001620}}
    case AST.TermCtr{v_15, [v_16], _}, 1n+v_18:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_key{v_15, "Succ", v_4}}, +v_1001621 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_nat{v_16, v_18, v_4}}, +v_1001622 => EmitterFinished{Bool.and(v_1001621, v_1001622)}}}
    case _, _:
      EmitterFinished{False{}}

def emitter_body_js_string_schema_ref(v_0: AST.SyntaxTerm, v_2: String, v_4: String) -> EmitterProgress<Bool>:
  match v_0:
    case AST.TermRef{v_8, _}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_string_schema_key{v_8, v_2, v_4}}, +v_1001623 => EmitterFinished{v_1001623}}
    case _:
      EmitterFinished{False{}}

def emitter_body_js_string_schema_key(+v_1: String, +v_3: String, v_5: String) -> EmitterProgress<Bool>:
  v_1001624 = {String.eq(v_1, v_3) : Bool}
  v_1001625 = {v_1 : String}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_5, v_3}}, +v_1001626 => EmitterFinished{Bool.or(v_1001624, String.eq(v_1001625, v_1001626))}}

def emitter_match_328(v_4: Maybe<&2, EmitClosure>, +v_11: AST.SyntaxTerm, v_12: List<&2, AST.SyntaxTerm>, +v_6: EmitEnv) -> EmitterProgress<List<&2, String>>:
  match v_4:
    case Some{v_14}:
      v_1001627 = {v_11 : AST.SyntaxTerm}
      v_1001628 = {v_12 : List<&2, AST.SyntaxTerm>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_14}}, False{}, v_1001631 => emitter_body_js_reduce(v_14), +v_1001629 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_arg_view{v_1001627, v_1001628, v_1001629, v_6}}, +v_1001630 => EmitterFinished{v_1001630}}}
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term{v_11, v_6}}, False{}, v_1001634 => emitter_body_js_term(v_11, v_6), +v_1001632 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_args{v_12, None{}, v_6}}, +v_1001633 => EmitterFinished{v_1001632 <> v_1001633}}}

def emitter_body_js_constructor_args(v_1: List<&2, AST.SyntaxTerm>, v_4: Maybe<&2, EmitClosure>, v_6: EmitEnv) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case []:
      EmitterFinished{[]}
    case +v_11 <> v_12:
      emitter_match_328(v_4, v_11, v_12, v_6)

def emitter_continuation_330(+v_1001640: EmitClosure, v_22: AST.Quantity, v_0: AST.SyntaxTerm, v_25: AST.SyntaxTerm, v_8: EmitEnv, +v_6: EmitEnv, v_2: List<&2, AST.SyntaxTerm>) -> EmitterProgress<List<&2, String>>:
  v_38 = {Some{v_1001640} : Maybe<&2, EmitClosure>}
  v_1001641 = {v_22 : AST.Quantity}
  v_1001642 = {v_0 : AST.SyntaxTerm}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_25, v_8}}, False{}, v_1001647 => emitter_body_js_close(v_25, v_8), +v_1001643 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_arg_quantity{v_1001641, v_1001642, Some{v_1001643}, v_6}}, +v_1001644 => EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_constructor_args{v_2, v_38, v_6}}, False{}, v_1001646 => emitter_body_js_constructor_args(v_2, v_38, v_6), +v_1001645 => EmitterFinished{v_1001644 <> v_1001645}}}}

def emitter_continuation_331(v_2: List<&2, AST.SyntaxTerm>, v_59: List<&2, AST.TelescopeItem>, v_60: AST.OptionalTerm, v_70: EmitEnv, v_6: EmitEnv, +v_1001659: String) -> EmitterProgress<List<&2, String>>:
  v_1001660 = {v_2 : List<&2, AST.SyntaxTerm>}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close_declared{v_59, v_60, v_70}}, False{}, v_1001664 => emitter_body_js_close_declared(v_59, v_60, v_70), +v_1001661 => EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_constructor_args{v_1001660, Some{v_1001661}, v_6}}, False{}, v_1001663 => emitter_body_js_constructor_args(v_1001660, Some{v_1001661}, v_6), +v_1001662 => EmitterFinished{v_1001659 <> v_1001662}}}

def emitter_continuation_332(+v_1001655: EmitEnv, v_54: AST.Quantity, v_0: AST.SyntaxTerm, v_57: AST.SyntaxTerm, v_8: EmitEnv, +v_6: EmitEnv, v_2: List<&2, AST.SyntaxTerm>, v_59: List<&2, AST.TelescopeItem>, v_60: AST.OptionalTerm) -> EmitterProgress<List<&2, String>>:
  v_70 = v_1001655
  v_1001656 = {v_54 : AST.Quantity}
  v_1001657 = {v_0 : AST.SyntaxTerm}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_57, v_8}}, False{}, v_1001665 => emitter_body_js_close(v_57, v_8), +v_1001658 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_arg_quantity{v_1001656, v_1001657, Some{v_1001658}, v_6}}, +v_1001659 => emitter_continuation_331(v_2, v_59, v_60, v_70, v_6, v_1001659)}}

def emitter_match_333(v_4: EmitClosure, +v_8: EmitEnv, +v_0: AST.SyntaxTerm, +v_6: EmitEnv, v_2: List<&2, AST.SyntaxTerm>) -> EmitterProgress<List<&2, String>>:
  match v_4:
    case EmitClosure{AST.TermAll{v_22, _, _, +v_25, v_26, _}, _, _, _, _, _}:
      v_1001635 = {v_26 : AST.SyntaxTerm}
      v_1001636 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_25, v_8}}, False{}, v_1001651 => emitter_body_js_close(v_25, v_8), +v_1001637 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_0, v_6}}, False{}, v_1001650 => emitter_body_js_close(v_0, v_6), +v_1001638 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001636, Some{v_1001637}, Some{v_1001638}, v_8}}, False{}, v_1001649 => emitter_body_env_bind(v_1001636, Some{v_1001637}, Some{v_1001638}, v_8), +v_1001639 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_1001635, v_1001639}}, False{}, v_1001648 => emitter_body_js_close(v_1001635, v_1001639), +v_1001640 => emitter_continuation_330(v_1001640, v_22, v_0, v_25, v_8, v_6, v_2)}}}}
    case EmitDeclared{AST.Binder{v_54, _, _, +v_57, _} <> v_59, v_60, _, _, _, _, _}:
      v_1001652 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_57, v_8}}, False{}, v_1001668 => emitter_body_js_close(v_57, v_8), +v_1001653 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_0, v_6}}, False{}, v_1001667 => emitter_body_js_close(v_0, v_6), +v_1001654 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001652, Some{v_1001653}, Some{v_1001654}, v_8}}, False{}, v_1001666 => emitter_body_env_bind(v_1001652, Some{v_1001653}, Some{v_1001654}, v_8), +v_1001655 => emitter_continuation_332(v_1001655, v_54, v_0, v_57, v_8, v_6, v_2, v_59, v_60)}}}
    case _:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term{v_0, v_6}}, False{}, v_1001672 => emitter_body_js_term(v_0, v_6), +v_1001669 => EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_constructor_args{v_2, None{}, v_6}}, False{}, v_1001671 => emitter_body_js_constructor_args(v_2, None{}, v_6), +v_1001670 => EmitterFinished{v_1001669 <> v_1001670}}}

def emitter_body_js_constructor_arg_view_env(v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>, v_4: EmitClosure, v_6: EmitEnv, v_8: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_333(v_4, v_8, v_0, v_6, v_2)

def emitter_body_js_constructor_arg_view(v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>, +v_4: EmitClosure, v_6: EmitEnv) -> EmitterProgress<List<&2, String>>:
  v_1001673 = {v_0 : AST.SyntaxTerm}
  v_1001674 = {v_2 : List<&2, AST.SyntaxTerm>}
  v_1001675 = {v_4 : EmitClosure}
  v_1001676 = {v_6 : EmitEnv}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_4}}, False{}, v_1001679 => emitter_body_js_closure_env(v_4), +v_1001677 => emitter_body_js_constructor_arg_view_env(v_1001673, v_1001674, v_1001675, v_1001676, v_1001677)}

def emitter_match_334(v_0: AST.Quantity, v_1: AST.SyntaxTerm, v_6: EmitEnv, v_4: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_0:
    case AST.QZero{}:
      EmitterFinished{"null"}
    case _:
      emitter_body_js_term_expected(v_1, v_6, v_4)

def emitter_body_js_constructor_arg_quantity(v_0: AST.Quantity, v_1: AST.SyntaxTerm, v_4: Maybe<&2, EmitClosure>, v_6: EmitEnv) -> EmitterProgress<String>:
  emitter_match_334(v_0, v_1, v_6, v_4)

def emitter_body_js_constructor_native(+v_1: String) -> EmitterProgress<String>:
  v_1001681 = {v_1 : String}
  v_1001682 = {"Nat.Zero" : String}
  v_1001683 = {"NZ" : String}
  v_1001684 = {v_1 : String}
  v_1001685 = {"Bool.False" : String}
  v_1001686 = {"BF" : String}
  v_1001687 = {v_1 : String}
  v_1001688 = {"Bool.True" : String}
  v_1001689 = {"BT" : String}
  v_1001690 = {v_1 : String}
  v_1001691 = {"String.SNil" : String}
  v_1001692 = {"SN" : String}
  v_1001693 = {v_1 : String}
  v_1001694 = {"Nat.Succ" : String}
  v_1001695 = {"NS" : String}
  v_1001696 = {v_1 : String}
  v_1001697 = {"Char.Chr" : String}
  v_1001698 = {"CH" : String}
  v_1001699 = {v_1 : String}
  v_1001700 = {"String.SCon" : String}
  v_1001701 = {"SC" : String}
  v_1001702 = {v_1 : String}
  v_1001703 = {"U32.U32" : String}
  v_1001704 = {"U" : String}
  v_1001705 = {v_1 : String}
  v_1001706 = {"F32.F32" : String}
  v_1001707 = {"F" : String}
  v_1001708 = {v_1 : String}
  v_1001709 = {"Array.ALeaf" : String}
  v_1001710 = {"AL" : String}
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose_exact{v_1, "Array.ANode", "AN", ""}}, False{}, v_1001731 => emitter_body_js_choose_exact(v_1, "Array.ANode", "AN", ""), +v_1001711 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose_exact{v_1001708, v_1001709, v_1001710, v_1001711}}, False{}, v_1001730 => emitter_body_js_choose_exact(v_1001708, v_1001709, v_1001710, v_1001711), +v_1001712 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose_exact{v_1001705, v_1001706, v_1001707, v_1001712}}, False{}, v_1001729 => emitter_body_js_choose_exact(v_1001705, v_1001706, v_1001707, v_1001712), +v_1001713 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose_exact{v_1001702, v_1001703, v_1001704, v_1001713}}, False{}, v_1001728 => emitter_body_js_choose_exact(v_1001702, v_1001703, v_1001704, v_1001713), +v_1001714 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose_exact{v_1001699, v_1001700, v_1001701, v_1001714}}, False{}, v_1001727 => emitter_body_js_choose_exact(v_1001699, v_1001700, v_1001701, v_1001714), +v_1001715 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose_exact{v_1001696, v_1001697, v_1001698, v_1001715}}, False{}, v_1001726 => emitter_body_js_choose_exact(v_1001696, v_1001697, v_1001698, v_1001715), +v_1001716 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose_exact{v_1001693, v_1001694, v_1001695, v_1001716}}, False{}, v_1001725 => emitter_body_js_choose_exact(v_1001693, v_1001694, v_1001695, v_1001716), +v_1001717 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose_exact{v_1001690, v_1001691, v_1001692, v_1001717}}, False{}, v_1001724 => emitter_body_js_choose_exact(v_1001690, v_1001691, v_1001692, v_1001717), +v_1001718 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose_exact{v_1001687, v_1001688, v_1001689, v_1001718}}, False{}, v_1001723 => emitter_body_js_choose_exact(v_1001687, v_1001688, v_1001689, v_1001718), +v_1001719 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_choose_exact{v_1001684, v_1001685, v_1001686, v_1001719}}, False{}, v_1001722 => emitter_body_js_choose_exact(v_1001684, v_1001685, v_1001686, v_1001719), +v_1001720 => emitter_body_js_choose_exact(v_1001681, v_1001682, v_1001683, v_1001720)}}}}}}}}}}

def emitter_body_js_constructor_native_identity_found(v_2: Maybe<&2, EmitConstructor>, v_4: String) -> EmitterProgress<String>:
  match v_2:
    case Some{EmitConstructor{v_11, v_12, _, _, v_15}}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_native_origin{emitter_pure_js_base_origin(v_15), v_12, v_11}}, +v_1001732 => EmitterFinished{v_1001732}}
    case None{}:
      EmitterFinished{v_4}

def emitter_body_js_constructor_native_identity(+v_1: String, v_3: EmitEnv) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_1, v_3}}, False{}, v_1001735 => emitter_body_js_constructor_decl(v_1, v_3), +v_1001733 => emitter_body_js_constructor_native_identity_found(v_1001733, v_1)}

def emitter_body_js_constructor_native_origin(v_1: Bool, v_3: String, v_5: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      v_1001736 = {v_3 : String}
      v_1001737 = {"." : String}
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_ctor_short{v_5}}, +v_1001738 => EmitterFinished{String.append(v_1001736, String.append(v_1001737, v_1001738))}}
    case False{}:
      EmitterFinished{String.append("Data.", v_5)}

def emitter_body_js_base_origin(v_1: EmitEnv) -> EmitterProgress<Bool>:
  EmitterFinished{emitter_pure_js_base_origin(v_1)}

def emitter_body_js_base_source_suffix(v_1: Bool, v_3: List<&2, Loader.LoadedModule>) -> EmitterProgress<Bool>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_base_imported{v_3}}, +v_1001739 => EmitterFinished{v_1001739}}
    case False{}:
      EmitterFinished{False{}}

def emitter_match_338(v_1: Bool, v_5: List<&2, Loader.LoadedModule>, v_3: String) -> EmitterProgress<Bool>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_base_imported{v_5}}, +v_1001740 => EmitterFinished{v_1001740}}
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_base_source_suffix{String.ends_with(v_3, "/bend2/base.bend"), v_5}}, False{}, v_1001742 => emitter_body_js_base_source_suffix(String.ends_with(v_3, "/bend2/base.bend"), v_5), +v_1001741 => EmitterFinished{v_1001741}}

def emitter_body_js_base_source_exact(v_1: Bool, v_3: String, v_5: List<&2, Loader.LoadedModule>) -> EmitterProgress<Bool>:
  emitter_match_338(v_1, v_5, v_3)

def emitter_body_js_base_source(+v_1: String, v_3: List<&2, Loader.LoadedModule>) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_base_source_exact{String.eq(v_1, "bend2/base.bend"), v_1, v_3}}, False{}, v_1001744 => emitter_body_js_base_source_exact(String.eq(v_1, "bend2/base.bend"), v_1, v_3), +v_1001743 => EmitterFinished{v_1001743}}

def emitter_body_js_base_imported(v_1: List<&2, Loader.LoadedModule>) -> EmitterProgress<Bool>:
  match v_1:
    case []:
      EmitterFinished{False{}}
    case Loader.LoadedModule{_, AST.Module{_, v_10, _}} <> v_12:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_base_imports{v_10}}, +v_1001745 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_base_imported_next{v_1001745, v_12}}, +v_1001746 => EmitterFinished{v_1001746}}}

def emitter_body_js_base_imported_next(v_1: Bool, v_3: List<&2, Loader.LoadedModule>) -> EmitterProgress<Bool>:
  match v_1:
    case True{}:
      EmitterFinished{True{}}
    case False{}:
      emitter_body_js_base_imported(v_3)

def emitter_body_js_base_imports(v_1: List<&2, AST.ModuleImport>) -> EmitterProgress<Bool>:
  match v_1:
    case []:
      EmitterFinished{False{}}
    case AST.ModuleImport{v_7, _, _} <> v_10:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_base_imports_next{String.eq(v_7, "Base"), v_10}}, +v_1001748 => EmitterFinished{v_1001748}}

def emitter_body_js_base_imports_next(v_1: Bool, v_3: List<&2, AST.ModuleImport>) -> EmitterProgress<Bool>:
  match v_1:
    case True{}:
      EmitterFinished{True{}}
    case False{}:
      emitter_body_js_base_imports(v_3)

def emitter_match_343(+v_4: Nat, +v_8: String, v_9: List<&2, String>) -> EmitterProgress<String>:
  match v_4:
    case 0n:
      EmitterFinished{v_8}
    case _:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_source_at{v_9, Nat.sub(v_4, 1n)}}, +v_1001750 => EmitterFinished{v_1001750}}

def emitter_body_js_source_at(v_2: List<&2, String>, v_4: Nat) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterFinished{"undefined"}
    case +v_8 <> v_9:
      emitter_match_343(v_4, v_8, v_9)

def emitter_match_345(+v_7: List<&2, String>, +v_6: String) -> EmitterProgress<String>:
  match v_7:
    case []:
      EmitterFinished{v_6}
    case _:
      v_1001751 = {v_6 : String}
      v_1001752 = {", " : String}
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_sources{v_7}}, +v_1001753 => EmitterFinished{String.append(v_1001751, String.append(v_1001752, v_1001753))}}

def emitter_body_js_sources(v_2: List<&2, String>) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterFinished{""}
    case +v_6 <> v_7:
      emitter_match_345(v_7, v_6)

def emitter_continuation_347(v_6: List<&2, String>, v_1001760: String, +v_1001761: String) -> EmitterProgress<String>:
  v_1001762 = {" + " : String}
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_source_at{v_6, 1n}}, False{}, v_1001764 => emitter_body_js_source_at(v_6, 1n), +v_1001763 => EmitterFinished{String.append(v_1001760, String.append(v_1001761, String.append(v_1001762, String.append(v_1001763, ")"))))}}

def emitter_continuation_348(v_6: List<&2, String>, v_1001775: String, +v_1001776: String) -> EmitterProgress<String>:
  v_1001777 = {", " : String}
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_source_at{v_6, 1n}}, False{}, v_1001779 => emitter_body_js_source_at(v_6, 1n), +v_1001778 => EmitterFinished{String.append(v_1001775, String.append(v_1001776, String.append(v_1001777, String.append(v_1001778, ")"))))}}

def emitter_match_349(v_1: String, +v_6: List<&2, String>, +v_3: String, v_8: EmitEnv) -> EmitterProgress<String>:
  match v_1:
    case "NZ":
      EmitterFinished{"0"}
    case "BF":
      EmitterFinished{"false"}
    case "BT":
      EmitterFinished{"true"}
    case "SN":
      EmitterFinished{"\"\""}
    case "NS":
      v_1001754 = {"nat_chk(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_source_at{v_6, 0n}}, False{}, v_1001756 => emitter_body_js_source_at(v_6, 0n), +v_1001755 => EmitterFinished{String.append(v_1001754, String.append(v_1001755, " + 1)"))}}
    case "CH":
      v_1001757 = {"char_new(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_source_at{v_6, 0n}}, False{}, v_1001759 => emitter_body_js_source_at(v_6, 0n), +v_1001758 => EmitterFinished{String.append(v_1001757, String.append(v_1001758, ")"))}}
    case "SC":
      v_1001760 = {"(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_source_at{v_6, 0n}}, False{}, v_1001765 => emitter_body_js_source_at(v_6, 0n), +v_1001761 => emitter_continuation_347(v_6, v_1001760, v_1001761)}
    case "U":
      v_1001766 = {"word_to_u32(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_source_at{v_6, 0n}}, False{}, v_1001768 => emitter_body_js_source_at(v_6, 0n), +v_1001767 => EmitterFinished{String.append(v_1001766, String.append(v_1001767, ")"))}}
    case "F":
      v_1001769 = {"f32_from_bits(word_to_u32(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_source_at{v_6, 0n}}, False{}, v_1001771 => emitter_body_js_source_at(v_6, 0n), +v_1001770 => EmitterFinished{String.append(v_1001769, String.append(v_1001770, "))"))}}
    case "AL":
      v_1001772 = {"[" : String}
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_source_at{v_6, 0n}}, False{}, v_1001774 => emitter_body_js_source_at(v_6, 0n), +v_1001773 => EmitterFinished{String.append(v_1001772, String.append(v_1001773, "]"))}}
    case "AN":
      v_1001775 = {"array_node(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_source_at{v_6, 0n}}, False{}, v_1001780 => emitter_body_js_source_at(v_6, 0n), +v_1001776 => emitter_continuation_348(v_6, v_1001775, v_1001776)}
    case _:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_3, v_8}}, False{}, v_1001783 => emitter_body_js_constructor_decl(v_3, v_8), +v_1001781 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_record{v_1001781, v_3, v_6}}, +v_1001782 => EmitterFinished{v_1001782}}}

def emitter_body_js_constructor_render(v_1: String, v_3: String, v_6: List<&2, String>, v_8: EmitEnv) -> EmitterProgress<String>:
  emitter_match_349(v_1, v_6, v_3, v_8)

def emitter_continuation_350(v_7: List<&2, String>, v_1001786: String, +v_1001787: String) -> EmitterProgress<String>:
  v_1001788 = {", [" : String}
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_sources{v_7}}, False{}, v_1001790 => emitter_body_js_sources(v_7), +v_1001789 => EmitterFinished{String.append(v_1001786, String.append(v_1001787, String.append(v_1001788, String.append(v_1001789, "], $scope, $aliases)"))))}}

def emitter_match_351(v_2: Maybe<&2, EmitConstructor>, v_7: List<&2, String>, v_4: String) -> EmitterProgress<String>:
  match v_2:
    case Some{EmitConstructor{v_14, _, _, v_17, _}}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_record_fields{v_17, v_7}}, +v_1001784 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_record_exact{v_1001784, v_14}}, +v_1001785 => EmitterFinished{v_1001785}}}
    case None{}:
      v_1001786 = {"$ctr(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_4}}, False{}, v_1001791 => emitter_body_js_quote(v_4), +v_1001787 => emitter_continuation_350(v_7, v_1001786, v_1001787)}

def emitter_body_js_constructor_record(v_2: Maybe<&2, EmitConstructor>, v_4: String, v_7: List<&2, String>) -> EmitterProgress<String>:
  emitter_match_351(v_2, v_7, v_4)

def emitter_body_js_constructor_record_exact(v_2: Maybe<&2, String>, v_4: String) -> EmitterProgress<String>:
  match v_2:
    case Some{v_7}:
      v_1001792 = {"({$:" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_4}}, False{}, v_1001794 => emitter_body_js_quote(v_4), +v_1001793 => EmitterFinished{String.append(v_1001792, String.append(v_1001793, String.append(v_7, "})")))}}
    case None{}:
      EmitterFinished{"(()=>{throw \"bend: constructor field count mismatch\"})()"}

def emitter_body_js_constructor_record_fields(v_1: List<&2, AST.TelescopeItem>, v_4: List<&2, String>) -> EmitterProgress<Maybe<&2, String>>:
  match v_1, v_4:
    case [], []:
      EmitterFinished{Some{""}}
    case AST.Binder{AST.QZero{}, _, _, _, _} <> v_18, _ <> v_20:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_record_fields{v_18, v_20}}, +v_1001795 => EmitterFinished{v_1001795}}
    case AST.Binder{_, v_31, _, _, _} <> v_35, +v_36 <> v_37:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_record_fields{v_35, v_37}}, +v_1001796 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_constructor_record_field{v_1001796, v_31, v_36}}, +v_1001797 => EmitterFinished{v_1001797}}}
    case _, _:
      EmitterFinished{None{}}

def emitter_body_js_constructor_record_field(v_2: Maybe<&2, String>, v_4: String, v_6: String) -> EmitterProgress<Maybe<&2, String>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_10}:
      v_1001798 = {", " : String}
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_object_key{v_4}}, +v_1001799 => EmitterFinished{Some{String.append(v_1001798, String.append(v_1001799, String.append(v_6, v_10)))}}}

def emitter_match_355(+v_1: String) -> EmitterProgress<String>:
  match v_1:
    case "__proto__":
      EmitterFinished{"[\"__proto__\"]:"}
    case _:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1001801 => emitter_body_js_quote(v_1), +v_1001800 => EmitterFinished{String.append(v_1001800, ":")}}

def emitter_body_js_object_key(v_1: String) -> EmitterProgress<String>:
  emitter_match_355(v_1)

def emitter_body_ctor_short(v_1: String) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_ctor_short_chars{List.reverse(&2, Char, String.to_list(v_1)), []}}, +v_1001802 => EmitterFinished{v_1001802}}

def emitter_match_356(+v_9: Char, v_5: List<&2, Char>, v_10: List<&2, Char>) -> EmitterProgress<String>:
  match v_9:
    case '.':
      EmitterFinished{String.from_list(v_5)}
    case '/':
      EmitterFinished{String.from_list(v_5)}
    case _:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_ctor_short_chars{v_10, v_9 <> v_5}}, +v_1001803 => EmitterFinished{v_1001803}}

def emitter_body_ctor_short_chars(v_2: List<&2, Char>, v_5: List<&2, Char>) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterFinished{String.from_list(v_5)}
    case +v_9 <> v_10:
      emitter_match_356(v_9, v_5, v_10)

def emitter_continuation_358(v_0: AST.SyntaxTerm, v_15: EmitEnv, v_6: Maybe<&2, EmitClosure>, v_1001808: String, +v_1001809: String) -> EmitterProgress<String>:
  v_1001810 = {"; return " : String}
  EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_0, v_15, v_6}}, False{}, v_1001812 => emitter_body_js_term_tail_expected(v_0, v_15, v_6), +v_1001811 => EmitterFinished{String.append(v_1001808, String.append(v_1001809, String.append(v_1001810, String.append(v_1001811, ";})()"))))}}

def emitter_continuation_359(+v_1001807: EmitEnv, v_10: String, v_1: AST.SyntaxTerm, v_3: EmitEnv, v_0: AST.SyntaxTerm, v_6: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_15 = v_1001807
  v_17 = String.append("(()=>{const ", String.append(v_10, "="))
  v_1001808 = {v_17 : String}
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term{v_1, v_3}}, False{}, v_1001813 => emitter_body_js_term(v_1, v_3), +v_1001809 => emitter_continuation_358(v_0, v_15, v_6, v_1001808, v_1001809)}

def emitter_body_js_match(v_0: AST.SyntaxTerm, +v_1: AST.SyntaxTerm, +v_3: EmitEnv, v_6: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  +v_10 = String.append("$v", Nat.show(emitter_pure_env_depth(v_3)))
  v_1001804 = {v_10 : String}
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_1, v_3}}, False{}, v_1001816 => emitter_body_js_type(v_1, v_3), +v_1001805 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_1, v_3}}, False{}, v_1001815 => emitter_body_js_close(v_1, v_3), +v_1001806 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1001804, v_1001805, Some{v_1001806}, v_3}}, False{}, v_1001814 => emitter_body_env_bind(v_1001804, v_1001805, Some{v_1001806}, v_3), +v_1001807 => emitter_continuation_359(v_1001807, v_10, v_1, v_3, v_0, v_6)}}}

def emitter_match_360(v_0: AST.SyntaxPattern, +v_4: EmitEnv, v_2: String) -> EmitterProgress<String>:
  match v_0:
    case AST.PatternVar{_, _, _, _}:
      EmitterFinished{"true"}
    case AST.PatternCtr{+v_17, v_18, _}:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_17, v_4}}, False{}, v_1001819 => emitter_body_js_constructor_decl(v_17, v_4), +v_1001817 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_constructor{v_1001817, v_17, v_18, v_2, v_4}}, +v_1001818 => EmitterFinished{v_1001818}}}

def emitter_body_pattern_test(v_0: AST.SyntaxPattern, v_2: String, v_4: EmitEnv) -> EmitterProgress<String>:
  emitter_match_360(v_0, v_4, v_2)

def emitter_continuation_361(+v_1001821: String, +v_6: List<&2, AST.SyntaxPattern>, +v_10: EmitEnv, v_18: String, v_21: List<&2, AST.TelescopeItem>, v_8: String) -> EmitterProgress<String>:
  +v_26 = v_1001821
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_native_word_pattern{v_26, v_6, v_10}}, +v_1001822 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_native_literal{v_1001822, v_26, v_18, v_6, v_21, v_8, v_10}}, +v_1001823 => EmitterFinished{v_1001823}}}

def emitter_body_pattern_test_constructor(v_2: Maybe<&2, EmitConstructor>, v_4: String, v_6: List<&2, AST.SyntaxPattern>, v_8: String, v_10: EmitEnv) -> EmitterProgress<String>:
  match v_2:
    case None{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_ctor{v_4, v_6, v_8, v_10}}, +v_1001820 => EmitterFinished{v_1001820}}
    case Some{EmitConstructor{+v_18, v_19, _, v_21, v_22}}:
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_constructor_native_origin{emitter_pure_js_base_origin(v_22), v_19, v_18}}, False{}, v_1001824 => emitter_body_js_constructor_native_origin(emitter_pure_js_base_origin(v_22), v_19, v_18), +v_1001821 => emitter_continuation_361(v_1001821, v_6, v_10, v_18, v_21, v_8)}

def emitter_continuation_363(v_7: List<&2, AST.SyntaxPattern>, v_9: List<&2, AST.TelescopeItem>, v_11: String, v_13: EmitEnv, v_1001826: String, v_1001827: String, v_1001828: String, v_1001829: String, v_1001830: String, +v_1001831: String) -> EmitterProgress<String>:
  v_1001832 = {" && " : String}
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_decl_fields_test{v_7, v_9, v_11, v_13}}, +v_1001833 => EmitterFinished{String.append(v_1001826, String.append(v_1001827, String.append(v_1001828, String.append(v_1001829, String.append(v_1001830, String.append(v_1001831, String.append(v_1001832, String.append(v_1001833, ")"))))))))}}

def emitter_match_364(v_1: Bool, v_3: String, v_7: List<&2, AST.SyntaxPattern>, +v_11: String, v_13: EmitEnv, v_5: String, v_9: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  match v_1:
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_ctor{v_3, v_7, v_11, v_13}}, +v_1001825 => EmitterFinished{v_1001825}}
    case True{}:
      v_1001826 = {"(" : String}
      v_1001827 = {v_11 : String}
      v_1001828 = {" && " : String}
      v_1001829 = {v_11 : String}
      v_1001830 = {".$ === " : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_5}}, False{}, v_1001834 => emitter_body_js_quote(v_5), +v_1001831 => emitter_continuation_363(v_7, v_9, v_11, v_13, v_1001826, v_1001827, v_1001828, v_1001829, v_1001830, v_1001831)}

def emitter_body_pattern_test_constructor_tagged(v_1: Bool, v_3: String, v_5: String, v_7: List<&2, AST.SyntaxPattern>, v_9: List<&2, AST.TelescopeItem>, v_11: String, v_13: EmitEnv) -> EmitterProgress<String>:
  emitter_match_364(v_1, v_3, v_7, v_11, v_13, v_5, v_9)

def emitter_match_365(v_2: Maybe<&2, Nat>, +v_4: String, v_6: String, v_8: List<&2, AST.SyntaxPattern>, v_10: List<&2, AST.TelescopeItem>, v_12: String, v_14: EmitEnv) -> EmitterProgress<String>:
  match v_2:
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_constructor_native{v_4}}, False{}, v_1001838 => emitter_body_js_constructor_native(v_4), +v_1001835 => EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_pattern_test_constructor_tagged{String.eq(v_1001835, ""), v_4, v_6, v_8, v_10, v_12, v_14}}, False{}, v_1001837 => emitter_body_pattern_test_constructor_tagged(String.eq(v_1001835, ""), v_4, v_6, v_8, v_10, v_12, v_14), +v_1001836 => EmitterFinished{v_1001836}}}
    case Some{v_19}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_native_bits{String.eq(v_4, "F32.F32"), v_19, v_12}}, +v_1001839 => EmitterFinished{v_1001839}}

def emitter_body_pattern_test_native_literal(v_2: Maybe<&2, Nat>, v_4: String, v_6: String, v_8: List<&2, AST.SyntaxPattern>, v_10: List<&2, AST.TelescopeItem>, v_12: String, v_14: EmitEnv) -> EmitterProgress<String>:
  emitter_match_365(v_2, v_4, v_6, v_8, v_10, v_12, v_14)

def emitter_match_366(v_1: Bool, v_5: String, v_3: Nat) -> EmitterProgress<String>:
  match v_1:
    case False{}:
      EmitterFinished{String.append("((", String.append(v_5, String.append(" >>> 0) === ", String.append(Nat.show(v_3), ")"))))}
    case True{}:
      EmitterFinished{String.append("(f32_bits(", String.append(v_5, String.append(") === ", String.append(Nat.show(v_3), ")"))))}

def emitter_body_pattern_test_native_bits(v_1: Bool, v_3: Nat, v_5: String) -> EmitterProgress<String>:
  emitter_match_366(v_1, v_5, v_3)

def emitter_body_js_native_word_pattern(v_1: String, v_3: List<&2, AST.SyntaxPattern>, v_5: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_1, v_3:
    case "U32.U32", [+v_9]:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_closed_word_pattern{32n, v_9, v_5}}, +v_1001840 => EmitterFinished{v_1001840}}
    case "F32.F32", [+v_12]:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_closed_word_pattern{32n, v_12, v_5}}, +v_1001841 => EmitterFinished{v_1001841}}
    case _, _:
      EmitterFinished{None{}}

def emitter_match_368(v_2: AST.SyntaxPattern, +v_1: Nat, +v_4: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_2:
    case AST.PatternCtr{v_10, v_11, _}:
      +v_1001842 = {v_1 : Nat}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_10, v_4}}, False{}, v_1001847 => emitter_body_js_constructor_decl(v_10, v_4), +v_1001843 => EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_word_identity{v_1001843}}, False{}, v_1001846 => emitter_body_js_word_identity(v_1001843), +v_1001844 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_closed_word_pattern_constructor{v_1001842, v_1001844, v_11, v_4}}, +v_1001845 => EmitterFinished{v_1001845}}}}
    case _:
      EmitterFinished{None{}}

def emitter_body_js_closed_word_pattern(+v_1: Nat, v_2: AST.SyntaxPattern, v_4: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  emitter_match_368(v_2, v_1, v_4)

def emitter_match_369(+v_1: Nat, v_3: String, v_5: List<&2, AST.SyntaxPattern>, +v_7: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_1, v_3, v_5:
    case 0n, "Word.Nil.WNil", []:
      EmitterFinished{Some{0n}}
    case 1n+v_13, "Word.Con.WCon", [+v_14, +v_15]:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_closed_bit_pattern{v_14, v_7}}, +v_1001848 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_js_closed_word_pattern_bit{v_1001848, v_13, v_15, v_7}}, +v_1001849 => EmitterFinished{v_1001849}}}
    case _, _, _:
      EmitterFinished{None{}}

def emitter_body_js_closed_word_pattern_constructor(+v_1: Nat, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  emitter_match_369(v_1, v_3, v_5, v_7)

def emitter_body_js_closed_bit_pattern(v_0: AST.SyntaxPattern, v_2: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_0:
    case AST.PatternCtr{v_7, [], _}:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_7, v_2}}, False{}, v_1001854 => emitter_body_js_constructor_decl(v_7, v_2), +v_1001850 => EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_word_identity{v_1001850}}, False{}, v_1001853 => emitter_body_js_word_identity(v_1001850), +v_1001851 => emitter_body_js_closed_bit_identity(v_1001851)}}
    case _:
      EmitterFinished{None{}}

def emitter_body_js_closed_word_pattern_bit(v_2: Maybe<&2, Nat>, v_4: Nat, v_5: AST.SyntaxPattern, v_7: EmitEnv) -> EmitterProgress<Maybe<&2, Nat>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_11}:
      v_1001855 = {v_11 : Nat}
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_closed_word_pattern{v_4, v_5, v_7}}, False{}, v_1001858 => emitter_body_js_closed_word_pattern(v_4, v_5, v_7), +v_1001856 => emitter_body_js_closed_word_combine(v_1001855, v_1001856)}

def emitter_body_js_field_projection(v_1: String, v_3: String) -> EmitterProgress<String>:
  v_1001859 = {"(" : String}
  v_1001860 = {v_1 : String}
  v_1001861 = {")[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_3}}, False{}, v_1001863 => emitter_body_js_quote(v_3), +v_1001862 => EmitterFinished{String.append(v_1001859, String.append(v_1001860, String.append(v_1001861, String.append(v_1001862, "]"))))}}

def emitter_continuation_372(v_33: List<&2, AST.SyntaxPattern>, v_39: List<&2, AST.TelescopeItem>, v_5: String, v_7: EmitEnv, v_1001866: String, +v_1001867: String) -> EmitterProgress<String>:
  v_1001868 = {" && " : String}
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_decl_fields_test{v_33, v_39, v_5, v_7}}, +v_1001869 => EmitterFinished{String.append(v_1001866, String.append(v_1001867, String.append(v_1001868, String.append(v_1001869, ")"))))}}

def emitter_continuation_373(+v_1001865: String, +v_32: AST.SyntaxPattern, +v_7: EmitEnv, v_33: List<&2, AST.SyntaxPattern>, v_39: List<&2, AST.TelescopeItem>, v_5: String) -> EmitterProgress<String>:
  v_42 = v_1001865
  v_1001866 = {"(" : String}
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_pattern_test{v_32, v_42, v_7}}, False{}, v_1001870 => emitter_body_pattern_test(v_32, v_42, v_7), +v_1001867 => emitter_continuation_372(v_33, v_39, v_5, v_7, v_1001866, v_1001867)}

def emitter_match_374(v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.TelescopeItem>, +v_5: String, v_7: EmitEnv) -> EmitterProgress<String>:
  match v_1, v_3:
    case [], []:
      EmitterFinished{"true"}
    case _ <> v_17, AST.Binder{AST.QZero{}, _, _, _, _} <> v_22:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_decl_fields_test{v_17, v_22, v_5, v_7}}, +v_1001864 => EmitterFinished{v_1001864}}
    case +v_32 <> v_33, AST.Binder{_, v_35, _, _, _} <> v_39:
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_field_projection{v_5, v_35}}, False{}, v_1001871 => emitter_body_js_field_projection(v_5, v_35), +v_1001865 => emitter_continuation_373(v_1001865, v_32, v_7, v_33, v_39, v_5)}
    case _, _:
      EmitterFinished{"false"}

def emitter_body_pattern_decl_fields_test(v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.TelescopeItem>, v_5: String, v_7: EmitEnv) -> EmitterProgress<String>:
  emitter_match_374(v_1, v_3, v_5, v_7)

def emitter_body_pattern_test_ctor(+v_1: String, v_3: List<&2, AST.SyntaxPattern>, v_5: String, v_7: EmitEnv) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_true{String.eq(v_1, "Bool.True"), v_1, v_3, v_5, v_7}}, +v_1001872 => EmitterFinished{v_1001872}}

def emitter_match_375(v_1: Bool, v_7: String, +v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{String.append("(", String.append(v_7, " === true)"))}
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_false{String.eq(v_3, "Bool.False"), v_3, v_5, v_7, v_9}}, +v_1001873 => EmitterFinished{v_1001873}}

def emitter_body_pattern_test_true(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_375(v_1, v_7, v_3, v_5, v_9)

def emitter_match_376(v_1: Bool, v_7: String, +v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{String.append("(", String.append(v_7, " === false)"))}
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_zero{String.eq(v_3, "Nat.Zero"), v_3, v_5, v_7, v_9}}, +v_1001874 => EmitterFinished{v_1001874}}

def emitter_body_pattern_test_false(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_376(v_1, v_7, v_3, v_5, v_9)

def emitter_match_377(v_1: Bool, v_7: String, +v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{String.append("(", String.append(v_7, " === 0)"))}
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_succ{String.eq(v_3, "Nat.Succ"), v_3, v_5, v_7, v_9}}, +v_1001875 => EmitterFinished{v_1001875}}

def emitter_body_pattern_test_zero(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_377(v_1, v_7, v_3, v_5, v_9)

def emitter_match_378(v_1: Bool, +v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv, +v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      v_12 = String.append("(", String.append(v_7, " - 1)"))
      v_1001876 = {"(" : String}
      v_1001877 = {v_7 : String}
      v_1001878 = {" > 0 && " : String}
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_patterns_test{v_5, [v_12], v_9}}, +v_1001879 => EmitterFinished{String.append(v_1001876, String.append(v_1001877, String.append(v_1001878, String.append(v_1001879, ")"))))}}
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_snil{String.eq(v_3, "String.SNil"), v_3, v_5, v_7, v_9}}, +v_1001880 => EmitterFinished{v_1001880}}

def emitter_body_pattern_test_succ(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_378(v_1, v_7, v_5, v_9, v_3)

def emitter_match_379(v_1: Bool, v_7: String, +v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{String.append("(", String.append(v_7, " === \"\")"))}
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_scon{String.eq(v_3, "String.SCon"), v_3, v_5, v_7, v_9}}, +v_1001881 => EmitterFinished{v_1001881}}

def emitter_body_pattern_test_snil(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_379(v_1, v_7, v_3, v_5, v_9)

def emitter_continuation_380(+v_1001882: String, +v_1001883: String, v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv) -> EmitterProgress<String>:
  v_16 = {[v_1001882, v_1001883] : List<&2, String>}
  v_1001884 = {"(" : String}
  v_1001885 = {v_7 : String}
  v_1001886 = {" !== \"\" && " : String}
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_patterns_test{v_5, v_16, v_9}}, +v_1001887 => EmitterFinished{String.append(v_1001884, String.append(v_1001885, String.append(v_1001886, String.append(v_1001887, ")"))))}}

def emitter_match_381(v_1: Bool, +v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv, +v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_string_field_value{v_7, 0n}}, +v_1001882 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_string_field_value{v_7, 1n}}, +v_1001883 => emitter_continuation_380(v_1001882, v_1001883, v_7, v_5, v_9)}}
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_u32{String.eq(v_3, "U32.U32"), v_3, v_5, v_7, v_9}}, +v_1001888 => EmitterFinished{v_1001888}}

def emitter_body_pattern_test_scon(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_381(v_1, v_7, v_5, v_9, v_3)

def emitter_match_382(v_1: Bool, v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv, +v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      v_12 = String.append("u32_to_word(", String.append(v_7, ")"))
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_patterns_test{v_5, [v_12], v_9}}, +v_1001889 => EmitterFinished{v_1001889}}
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_f32{String.eq(v_3, "F32.F32"), v_3, v_5, v_7, v_9}}, +v_1001890 => EmitterFinished{v_1001890}}

def emitter_body_pattern_test_u32(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_382(v_1, v_7, v_5, v_9, v_3)

def emitter_match_383(v_1: Bool, v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv, +v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      v_12 = String.append("u32_to_word(f32_bits(", String.append(v_7, "))"))
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_patterns_test{v_5, [v_12], v_9}}, +v_1001891 => EmitterFinished{v_1001891}}
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_aleaf{String.eq(v_3, "Array.ALeaf"), v_3, v_5, v_7, v_9}}, +v_1001892 => EmitterFinished{v_1001892}}

def emitter_body_pattern_test_f32(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_383(v_1, v_7, v_5, v_9, v_3)

def emitter_match_384(v_1: Bool, +v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv, +v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      v_1001893 = {"(" : String}
      v_1001894 = {v_7 : String}
      v_1001895 = {".length === 1 && " : String}
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_patterns_test{v_5, [String.append(v_7, "[0]")], v_9}}, +v_1001896 => EmitterFinished{String.append(v_1001893, String.append(v_1001894, String.append(v_1001895, String.append(v_1001896, ")"))))}}
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_anode{String.eq(v_3, "Array.ANode"), v_3, v_5, v_7, v_9}}, +v_1001897 => EmitterFinished{v_1001897}}

def emitter_body_pattern_test_aleaf(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_384(v_1, v_7, v_5, v_9, v_3)

def emitter_continuation_385(+v_1001898: String, +v_1001899: String, v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv) -> EmitterProgress<String>:
  v_16 = {[v_1001898, v_1001899] : List<&2, String>}
  v_1001900 = {"(" : String}
  v_1001901 = {v_7 : String}
  v_1001902 = {".length !== 1 && " : String}
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_patterns_test{v_5, v_16, v_9}}, +v_1001903 => EmitterFinished{String.append(v_1001900, String.append(v_1001901, String.append(v_1001902, String.append(v_1001903, ")"))))}}

def emitter_match_386(v_1: Bool, +v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv, +v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_array_field_value{v_7, 0n}}, +v_1001898 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_array_field_value{v_7, 1n}}, +v_1001899 => emitter_continuation_385(v_1001898, v_1001899, v_7, v_5, v_9)}}
    case False{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_test_char{String.eq(v_3, "Char.Chr"), v_3, v_5, v_7, v_9}}, +v_1001904 => EmitterFinished{v_1001904}}

def emitter_body_pattern_test_anode(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_386(v_1, v_7, v_5, v_9, v_3)

def emitter_continuation_387(v_5: List<&2, AST.SyntaxPattern>, v_3: String, v_7: String, v_9: EmitEnv, v_1001906: String, v_1001907: String, v_1001908: String, v_1001909: String, v_1001910: String, +v_1001911: String) -> EmitterProgress<String>:
  v_1001912 = {" && " : String}
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_fields_test{v_5, v_3, v_7, 0n, v_9}}, +v_1001913 => EmitterFinished{String.append(v_1001906, String.append(v_1001907, String.append(v_1001908, String.append(v_1001909, String.append(v_1001910, String.append(v_1001911, String.append(v_1001912, String.append(v_1001913, ")"))))))))}}

def emitter_match_388(v_1: Bool, v_5: List<&2, AST.SyntaxPattern>, +v_7: String, v_9: EmitEnv, +v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_patterns_test{v_5, [String.append(v_7, ".codePointAt(0)")], v_9}}, +v_1001905 => EmitterFinished{v_1001905}}
    case False{}:
      v_1001906 = {"(" : String}
      v_1001907 = {v_7 : String}
      v_1001908 = {" && " : String}
      v_1001909 = {v_7 : String}
      v_1001910 = {".$ === " : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_3}}, False{}, v_1001914 => emitter_body_js_quote(v_3), +v_1001911 => emitter_continuation_387(v_5, v_3, v_7, v_9, v_1001906, v_1001907, v_1001908, v_1001909, v_1001910, v_1001911)}

def emitter_body_pattern_test_char(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_388(v_1, v_5, v_7, v_9, v_3)

def emitter_continuation_389(v_23: List<&2, AST.SyntaxPattern>, v_3: String, v_5: String, v_7: Nat, v_9: EmitEnv, v_1001917: String, +v_1001918: String) -> EmitterProgress<String>:
  v_1001919 = {" && " : String}
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_fields_test{v_23, v_3, v_5, Nat.add(v_7, 1n), v_9}}, +v_1001920 => EmitterFinished{String.append(v_1001917, String.append(v_1001918, String.append(v_1001919, String.append(v_1001920, ")"))))}}

def emitter_continuation_390(+v_1001916: String, +v_22: AST.SyntaxPattern, +v_9: EmitEnv, v_23: List<&2, AST.SyntaxPattern>, v_3: String, v_5: String, v_7: Nat) -> EmitterProgress<String>:
  v_26 = v_1001916
  v_1001917 = {"(" : String}
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_pattern_test{v_22, v_26, v_9}}, False{}, v_1001921 => emitter_body_pattern_test(v_22, v_26, v_9), +v_1001918 => emitter_continuation_389(v_23, v_3, v_5, v_7, v_9, v_1001917, v_1001918)}

def emitter_match_391(v_1: List<&2, AST.SyntaxPattern>, +v_3: String, +v_5: String, +v_7: Nat, v_9: EmitEnv) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{"true"}
    case AST.PatternVar{_, _, AST.QZero{}, _} <> v_18:
      EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_fields_test{v_18, v_3, v_5, v_7, v_9}}, +v_1001915 => EmitterFinished{v_1001915}}
    case +v_22 <> v_23:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_positional_projection{v_5, v_3, v_7}}, +v_1001916 => emitter_continuation_390(v_1001916, v_22, v_9, v_23, v_3, v_5, v_7)}

def emitter_body_pattern_fields_test(v_1: List<&2, AST.SyntaxPattern>, v_3: String, v_5: String, v_7: Nat, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_391(v_1, v_3, v_5, v_7, v_9)

def emitter_continuation_392(v_13: List<&2, AST.SyntaxPattern>, v_15: List<&2, String>, v_6: EmitEnv, v_1001922: String, +v_1001923: String) -> EmitterProgress<String>:
  v_1001924 = {" && " : String}
  EmitterPending{EmitterRequestGroup_4{EmitterRequest_patterns_test{v_13, v_15, v_6}}, +v_1001925 => EmitterFinished{String.append(v_1001922, String.append(v_1001923, String.append(v_1001924, String.append(v_1001925, ")"))))}}

def emitter_match_393(v_1: List<&2, AST.SyntaxPattern>, v_4: List<&2, String>, +v_6: EmitEnv) -> EmitterProgress<String>:
  match v_1, v_4:
    case [], []:
      EmitterFinished{"true"}
    case +v_12 <> v_13, +v_14 <> v_15:
      v_1001922 = {"(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_pattern_test{v_12, v_14, v_6}}, False{}, v_1001926 => emitter_body_pattern_test(v_12, v_14, v_6), +v_1001923 => emitter_continuation_392(v_13, v_15, v_6, v_1001922, v_1001923)}
    case _, _:
      EmitterFinished{"false"}

def emitter_body_patterns_test(v_1: List<&2, AST.SyntaxPattern>, v_4: List<&2, String>, v_6: EmitEnv) -> EmitterProgress<String>:
  emitter_match_393(v_1, v_4, v_6)

def emitter_match_394(v_0: AST.SyntaxPattern, v_2: String, +v_4: EmitEnv) -> EmitterProgress<List<&2, String>>:
  match v_0:
    case AST.PatternVar{_, _, AST.QZero{}, _}:
      EmitterFinished{["null"]}
    case AST.PatternVar{_, _, _, _}:
      EmitterFinished{[v_2]}
    case AST.PatternCtr{+v_24, v_25, _}:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_24, v_4}}, False{}, v_1001929 => emitter_body_js_constructor_decl(v_24, v_4), +v_1001927 => EmitterPending{EmitterRequestGroup_4{EmitterRequest_pattern_vars_constructor{v_1001927, v_24, v_25, v_2, v_4}}, +v_1001928 => EmitterFinished{v_1001928}}}

def emitter_body_pattern_vars(v_0: AST.SyntaxPattern, v_2: String, v_4: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_394(v_0, v_2, v_4)

def emitter_continuation_395(+v_1001931: String, v_6: List<&2, AST.SyntaxPattern>, v_22: List<&2, AST.TelescopeItem>, v_8: String, v_10: EmitEnv) -> EmitterProgress<List<&2, String>>:
  +v_27 = v_1001931
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_constructor_native{v_27}}, False{}, v_1001934 => emitter_body_js_constructor_native(v_27), +v_1001932 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_vars_constructor_tagged{String.eq(v_1001932, ""), v_27, v_6, v_22, v_8, v_10}}, +v_1001933 => EmitterFinished{v_1001933}}}

def emitter_body_pattern_vars_constructor(v_2: Maybe<&2, EmitConstructor>, v_4: String, v_6: List<&2, AST.SyntaxPattern>, v_8: String, v_10: EmitEnv) -> EmitterProgress<List<&2, String>>:
  match v_2:
    case None{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_vars_ctr{v_4, v_6, v_8, v_10}}, +v_1001930 => EmitterFinished{v_1001930}}
    case Some{EmitConstructor{v_19, v_20, _, v_22, v_23}}:
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_constructor_native_origin{emitter_pure_js_base_origin(v_23), v_20, v_19}}, False{}, v_1001935 => emitter_body_js_constructor_native_origin(emitter_pure_js_base_origin(v_23), v_20, v_19), +v_1001931 => emitter_continuation_395(v_1001931, v_6, v_22, v_8, v_10)}

def emitter_match_397(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_9: String, v_11: EmitEnv, v_7: List<&2, AST.TelescopeItem>) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case False{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_vars_ctr{v_3, v_5, v_9, v_11}}, +v_1001936 => EmitterFinished{v_1001936}}
    case True{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_decl_fields_vars{v_5, v_7, v_9, v_11}}, +v_1001937 => EmitterFinished{v_1001937}}

def emitter_body_pattern_vars_constructor_tagged(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: List<&2, AST.TelescopeItem>, v_9: String, v_11: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_397(v_1, v_3, v_5, v_9, v_11, v_7)

def emitter_body_pattern_erased_vars(v_0: AST.SyntaxPattern) -> EmitterProgress<List<&2, String>>:
  match v_0:
    case AST.PatternVar{_, _, _, _}:
      EmitterFinished{["null"]}
    case AST.PatternCtr{_, v_15, _}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_patterns_erased_vars{v_15}}, +v_1001938 => EmitterFinished{v_1001938}}

def emitter_body_patterns_erased_vars(v_1: List<&2, AST.SyntaxPattern>) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case []:
      EmitterFinished{[]}
    case +v_6 <> v_7:
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_pattern_erased_vars{v_6}}, False{}, v_1001941 => emitter_body_pattern_erased_vars(v_6), +v_1001939 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_patterns_erased_vars{v_7}}, +v_1001940 => EmitterFinished{List.append(&2, String, v_1001939, v_1001940)}}}

def emitter_continuation_400(+v_1001945: String, +v_35: AST.SyntaxPattern, +v_7: EmitEnv, v_36: List<&2, AST.SyntaxPattern>, v_42: List<&2, AST.TelescopeItem>, v_5: String) -> EmitterProgress<List<&2, String>>:
  v_45 = v_1001945
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_pattern_vars{v_35, v_45, v_7}}, False{}, v_1001948 => emitter_body_pattern_vars(v_35, v_45, v_7), +v_1001946 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_decl_fields_vars{v_36, v_42, v_5, v_7}}, +v_1001947 => EmitterFinished{List.append(&2, String, v_1001946, v_1001947)}}}

def emitter_match_401(v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.TelescopeItem>, +v_5: String, v_7: EmitEnv) -> EmitterProgress<List<&2, String>>:
  match v_1, v_3:
    case [], []:
      EmitterFinished{[]}
    case +v_17 <> v_18, AST.Binder{AST.QZero{}, _, _, _, _} <> v_23:
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_pattern_erased_vars{v_17}}, False{}, v_1001944 => emitter_body_pattern_erased_vars(v_17), +v_1001942 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_decl_fields_vars{v_18, v_23, v_5, v_7}}, +v_1001943 => EmitterFinished{List.append(&2, String, v_1001942, v_1001943)}}}
    case +v_35 <> v_36, AST.Binder{_, v_38, _, _, _} <> v_42:
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_field_projection{v_5, v_38}}, False{}, v_1001949 => emitter_body_js_field_projection(v_5, v_38), +v_1001945 => emitter_continuation_400(v_1001945, v_35, v_7, v_36, v_42, v_5)}
    case _, _:
      EmitterFinished{[]}

def emitter_body_pattern_decl_fields_vars(v_1: List<&2, AST.SyntaxPattern>, v_3: List<&2, AST.TelescopeItem>, v_5: String, v_7: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_401(v_1, v_3, v_5, v_7)

def emitter_body_pattern_vars_ctr(+v_1: String, v_3: List<&2, AST.SyntaxPattern>, v_5: String, v_7: EmitEnv) -> EmitterProgress<List<&2, String>>:
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_vars_succ{String.eq(v_1, "Nat.Succ"), v_1, v_3, v_5, v_7}}, +v_1001950 => EmitterFinished{v_1001950}}

def emitter_match_402(v_1: Bool, v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv, +v_3: String) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case True{}:
      v_13 = String.append("(", String.append(v_7, " - 1)"))
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_patterns_vars{v_5, [v_13], v_9}}, +v_1001951 => EmitterFinished{v_1001951}}
    case False{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_vars_scon{String.eq(v_3, "String.SCon"), v_3, v_5, v_7, v_9}}, +v_1001952 => EmitterFinished{v_1001952}}

def emitter_body_pattern_vars_succ(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_402(v_1, v_7, v_5, v_9, v_3)

def emitter_match_403(v_1: Bool, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv, +v_3: String) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_string_fields{v_5, v_7, 0n, v_9}}, +v_1001953 => EmitterFinished{v_1001953}}
    case False{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_vars_char{String.eq(v_3, "Char.Chr"), v_3, v_5, v_7, v_9}}, +v_1001954 => EmitterFinished{v_1001954}}

def emitter_body_pattern_vars_scon(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_403(v_1, v_5, v_7, v_9, v_3)

def emitter_match_404(v_1: Bool, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv, +v_3: String) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_patterns_vars{v_5, [String.append(v_7, ".codePointAt(0)")], v_9}}, +v_1001955 => EmitterFinished{v_1001955}}
    case False{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_vars_u32{String.eq(v_3, "U32.U32"), v_3, v_5, v_7, v_9}}, +v_1001956 => EmitterFinished{v_1001956}}

def emitter_body_pattern_vars_char(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_404(v_1, v_5, v_7, v_9, v_3)

def emitter_match_405(v_1: Bool, v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv, +v_3: String) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case True{}:
      v_13 = String.append("u32_to_word(", String.append(v_7, ")"))
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_patterns_vars{v_5, [v_13], v_9}}, +v_1001957 => EmitterFinished{v_1001957}}
    case False{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_vars_f32{String.eq(v_3, "F32.F32"), v_3, v_5, v_7, v_9}}, +v_1001958 => EmitterFinished{v_1001958}}

def emitter_body_pattern_vars_u32(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_405(v_1, v_7, v_5, v_9, v_3)

def emitter_match_406(v_1: Bool, v_7: String, v_5: List<&2, AST.SyntaxPattern>, v_9: EmitEnv, +v_3: String) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case True{}:
      v_13 = String.append("u32_to_word(f32_bits(", String.append(v_7, "))"))
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_patterns_vars{v_5, [v_13], v_9}}, +v_1001959 => EmitterFinished{v_1001959}}
    case False{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_vars_aleaf{String.eq(v_3, "Array.ALeaf"), v_3, v_5, v_7, v_9}}, +v_1001960 => EmitterFinished{v_1001960}}

def emitter_body_pattern_vars_f32(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_406(v_1, v_7, v_5, v_9, v_3)

def emitter_match_407(v_1: Bool, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv, +v_3: String) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_patterns_vars{v_5, [String.append(v_7, "[0]")], v_9}}, +v_1001961 => EmitterFinished{v_1001961}}
    case False{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_vars_anode{String.eq(v_3, "Array.ANode"), v_3, v_5, v_7, v_9}}, +v_1001962 => EmitterFinished{v_1001962}}

def emitter_body_pattern_vars_aleaf(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_407(v_1, v_5, v_7, v_9, v_3)

def emitter_match_408(v_1: Bool, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv, v_3: String) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case True{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_array_fields{v_5, v_7, 0n, v_9}}, +v_1001963 => EmitterFinished{v_1001963}}
    case False{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_fields_vars{v_5, v_3, v_7, 0n, v_9}}, +v_1001964 => EmitterFinished{v_1001964}}

def emitter_body_pattern_vars_anode(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxPattern>, v_7: String, v_9: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_408(v_1, v_5, v_7, v_9, v_3)

def emitter_match_409(v_3: Nat, +v_1: String) -> EmitterProgress<String>:
  match v_3:
    case 0n:
      EmitterFinished{String.append(v_1, String.append(".slice(0, ", String.append(v_1, String.append(".length >> 1", ")"))))}
    case _:
      EmitterFinished{String.append(v_1, String.append(".slice(", String.append(v_1, String.append(".length >> 1", ")"))))}

def emitter_body_pattern_array_field_value(v_1: String, v_3: Nat) -> EmitterProgress<String>:
  emitter_match_409(v_3, v_1)

def emitter_continuation_410(+v_1001965: String, +v_12: AST.SyntaxPattern, +v_7: EmitEnv, v_13: List<&2, AST.SyntaxPattern>, v_3: String, v_5: Nat) -> EmitterProgress<List<&2, String>>:
  v_16 = v_1001965
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_pattern_vars{v_12, v_16, v_7}}, False{}, v_1001968 => emitter_body_pattern_vars(v_12, v_16, v_7), +v_1001966 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_array_fields{v_13, v_3, Nat.add(v_5, 1n), v_7}}, +v_1001967 => EmitterFinished{List.append(&2, String, v_1001966, v_1001967)}}}

def emitter_match_411(v_1: List<&2, AST.SyntaxPattern>, +v_3: String, +v_5: Nat, v_7: EmitEnv) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case []:
      EmitterFinished{[]}
    case +v_12 <> v_13:
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_pattern_array_field_value{v_3, v_5}}, False{}, v_1001969 => emitter_body_pattern_array_field_value(v_3, v_5), +v_1001965 => emitter_continuation_410(v_1001965, v_12, v_7, v_13, v_3, v_5)}

def emitter_body_pattern_array_fields(v_1: List<&2, AST.SyntaxPattern>, v_3: String, v_5: Nat, v_7: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_411(v_1, v_3, v_5, v_7)

def emitter_match_412(v_3: Nat, v_1: String) -> EmitterProgress<String>:
  match v_3:
    case 0n:
      EmitterFinished{String.append("String.fromCodePoint(", String.append(v_1, ".codePointAt(0))"))}
    case _:
      EmitterFinished{String.append("$string_tail(", String.append(v_1, ")"))}

def emitter_body_pattern_string_field_value(v_1: String, v_3: Nat) -> EmitterProgress<String>:
  emitter_match_412(v_3, v_1)

def emitter_continuation_413(+v_1001970: String, +v_12: AST.SyntaxPattern, +v_7: EmitEnv, v_13: List<&2, AST.SyntaxPattern>, v_3: String, v_5: Nat) -> EmitterProgress<List<&2, String>>:
  v_16 = v_1001970
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_pattern_vars{v_12, v_16, v_7}}, False{}, v_1001973 => emitter_body_pattern_vars(v_12, v_16, v_7), +v_1001971 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_string_fields{v_13, v_3, Nat.add(v_5, 1n), v_7}}, +v_1001972 => EmitterFinished{List.append(&2, String, v_1001971, v_1001972)}}}

def emitter_match_414(v_1: List<&2, AST.SyntaxPattern>, +v_3: String, +v_5: Nat, v_7: EmitEnv) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case []:
      EmitterFinished{[]}
    case +v_12 <> v_13:
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_pattern_string_field_value{v_3, v_5}}, False{}, v_1001974 => emitter_body_pattern_string_field_value(v_3, v_5), +v_1001970 => emitter_continuation_413(v_1001970, v_12, v_7, v_13, v_3, v_5)}

def emitter_body_pattern_string_fields(v_1: List<&2, AST.SyntaxPattern>, v_3: String, v_5: Nat, v_7: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_414(v_1, v_3, v_5, v_7)

def emitter_continuation_415(+v_1001977: String, +v_23: AST.SyntaxPattern, +v_9: EmitEnv, v_24: List<&2, AST.SyntaxPattern>, v_3: String, v_5: String, v_7: Nat) -> EmitterProgress<List<&2, String>>:
  v_27 = v_1001977
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_pattern_vars{v_23, v_27, v_9}}, False{}, v_1001980 => emitter_body_pattern_vars(v_23, v_27, v_9), +v_1001978 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_fields_vars{v_24, v_3, v_5, Nat.add(v_7, 1n), v_9}}, +v_1001979 => EmitterFinished{List.append(&2, String, v_1001978, v_1001979)}}}

def emitter_match_416(v_1: List<&2, AST.SyntaxPattern>, +v_3: String, +v_5: String, +v_7: Nat, v_9: EmitEnv) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case []:
      EmitterFinished{[]}
    case AST.PatternVar{_, _, AST.QZero{}, _} <> v_19:
      v_1001975 = {"null" : String}
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_pattern_fields_vars{v_19, v_3, v_5, v_7, v_9}}, +v_1001976 => EmitterFinished{v_1001975 <> v_1001976}}
    case +v_23 <> v_24:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_positional_projection{v_5, v_3, v_7}}, +v_1001977 => emitter_continuation_415(v_1001977, v_23, v_9, v_24, v_3, v_5, v_7)}

def emitter_body_pattern_fields_vars(v_1: List<&2, AST.SyntaxPattern>, v_3: String, v_5: String, v_7: Nat, v_9: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_416(v_1, v_3, v_5, v_7, v_9)

def emitter_body_js_positional_projection(v_1: String, v_3: String, v_5: Nat) -> EmitterProgress<String>:
  v_1001981 = {"$project(" : String}
  v_1001982 = {v_1 : String}
  v_1001983 = {"," : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_3}}, False{}, v_1001985 => emitter_body_js_quote(v_3), +v_1001984 => EmitterFinished{String.append(v_1001981, String.append(v_1001982, String.append(v_1001983, String.append(v_1001984, String.append(",", String.append(Nat.show(v_5), ",$scope,$aliases)"))))))}}

def emitter_match_417(v_1: List<&2, AST.SyntaxPattern>, v_4: List<&2, String>, +v_6: EmitEnv) -> EmitterProgress<List<&2, String>>:
  match v_1, v_4:
    case [], []:
      EmitterFinished{[]}
    case +v_13 <> v_14, +v_15 <> v_16:
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_pattern_vars{v_13, v_15, v_6}}, False{}, v_1001988 => emitter_body_pattern_vars(v_13, v_15, v_6), +v_1001986 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_patterns_vars{v_14, v_16, v_6}}, +v_1001987 => EmitterFinished{List.append(&2, String, v_1001986, v_1001987)}}}
    case _, _:
      EmitterFinished{[]}

def emitter_body_patterns_vars(v_1: List<&2, AST.SyntaxPattern>, v_4: List<&2, String>, v_6: EmitEnv) -> EmitterProgress<List<&2, String>>:
  emitter_match_417(v_1, v_4, v_6)

def emitter_continuation_418(+v_1001991: List<&2, Maybe<&2, EmitClosure>>, v_1: List<&2, AST.SyntaxPattern>, v_2: AST.SyntaxTerm, v_5: List<&2, String>, v_9: EmitEnv, v_12: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_17 = v_1001991
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_case_typed{v_1, v_2, v_5, v_17, v_9, v_12}}, +v_1001992 => EmitterFinished{v_1001992}}

def emitter_body_js_case(+v_1: List<&2, AST.SyntaxPattern>, v_2: AST.SyntaxTerm, v_5: List<&2, String>, v_7: List<&2, AST.SyntaxTerm>, +v_9: EmitEnv, v_12: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_1001989 = {v_1 : List<&2, AST.SyntaxPattern>}
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_scrutinee_types{v_7, v_9}}, False{}, v_1001994 => emitter_body_js_scrutinee_types(v_7, v_9), +v_1001990 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_pattern_types{v_1001989, v_1001990, v_9}}, False{}, v_1001993 => emitter_body_js_pattern_types(v_1001989, v_1001990, v_9), +v_1001991 => emitter_continuation_418(v_1001991, v_1, v_2, v_5, v_9, v_12)}}

def emitter_continuation_419(+v_1001995: String, v_1: List<&2, AST.SyntaxPattern>, v_2: AST.SyntaxTerm, v_5: List<&2, String>, v_9: List<&2, Maybe<&2, EmitClosure>>, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_18 = v_1001995
  v_1001996 = {"if (" : String}
  v_1001997 = {v_18 : String}
  v_1001998 = {") " : String}
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_case_block_typed{v_1, v_2, v_5, v_9, v_11, v_14}}, +v_1001999 => EmitterFinished{String.append(v_1001996, String.append(v_1001997, String.append(v_1001998, v_1001999)))}}

def emitter_body_js_case_typed(+v_1: List<&2, AST.SyntaxPattern>, v_2: AST.SyntaxTerm, +v_5: List<&2, String>, v_9: List<&2, Maybe<&2, EmitClosure>>, +v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_patterns_test{v_1, v_5, v_11}}, False{}, v_1002000 => emitter_body_patterns_test(v_1, v_5, v_11), +v_1001995 => emitter_continuation_419(v_1001995, v_1, v_2, v_5, v_9, v_11, v_14)}

def emitter_continuation_420(+v_1002004: String, v_2: AST.SyntaxTerm, v_25: EmitEnv, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_28 = v_1002004
  v_1002005 = {"{ " : String}
  v_1002006 = {v_28 : String}
  EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_statement_tail{v_2, v_25, v_14}}, False{}, v_1002008 => emitter_body_js_statement_tail(v_2, v_25, v_14), +v_1002007 => EmitterFinished{String.append(v_1002005, String.append(v_1002006, String.append(v_1002007, " }")))}}

def emitter_continuation_421(+v_1002003: EmitEnv, v_18: List<&2, String>, v_22: List<&2, String>, v_2: AST.SyntaxTerm, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_25 = v_1002003
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_case_bindings{v_18, v_22}}, +v_1002004 => emitter_continuation_420(v_1002004, v_2, v_25, v_14)}

def emitter_continuation_422(+v_1002002: List<&2, String>, v_9: List<&2, Maybe<&2, EmitClosure>>, v_11: EmitEnv, v_18: List<&2, String>, v_2: AST.SyntaxTerm, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  +v_22 = v_1002002
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_env_names_typed{v_22, v_9, v_11}}, False{}, v_1002009 => emitter_body_env_names_typed(v_22, v_9, v_11), +v_1002003 => emitter_continuation_421(v_1002003, v_18, v_22, v_2, v_14)}

def emitter_continuation_423(+v_1002001: List<&2, String>, +v_11: EmitEnv, v_9: List<&2, Maybe<&2, EmitClosure>>, v_2: AST.SyntaxTerm, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  +v_18 = v_1002001
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_case_binding_names{v_18, emitter_pure_env_depth(v_11)}}, +v_1002002 => emitter_continuation_422(v_1002002, v_9, v_11, v_18, v_2, v_14)}

def emitter_body_js_case_block_typed(v_1: List<&2, AST.SyntaxPattern>, v_2: AST.SyntaxTerm, v_5: List<&2, String>, v_9: List<&2, Maybe<&2, EmitClosure>>, +v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_patterns_vars{v_1, v_5, v_11}}, False{}, v_1002010 => emitter_body_patterns_vars(v_1, v_5, v_11), +v_1002001 => emitter_continuation_423(v_1002001, v_11, v_9, v_2, v_14)}

def emitter_match_424(v_2: List<&2, String>, +v_4: Nat) -> EmitterProgress<List<&2, String>>:
  match v_2:
    case []:
      EmitterFinished{[]}
    case +v_9 <> v_10:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_case_binding_name{String.eq(v_9, "null"), v_4}}, +v_1002011 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_case_binding_names{v_10, Nat.add(v_4, 1n)}}, +v_1002012 => EmitterFinished{v_1002011 <> v_1002012}}}

def emitter_body_js_case_binding_names(v_2: List<&2, String>, v_4: Nat) -> EmitterProgress<List<&2, String>>:
  emitter_match_424(v_2, v_4)

def emitter_body_js_case_binding_name(v_1: Bool, v_3: Nat) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{"null"}
    case False{}:
      EmitterFinished{String.append("$p", Nat.show(v_3))}

def emitter_body_js_case_bindings(v_2: List<&2, String>, v_5: List<&2, String>) -> EmitterProgress<String>:
  match v_2, v_5:
    case [], []:
      EmitterFinished{""}
    case +v_11 <> v_12, +v_13 <> v_14:
      v_1002013 = {String.eq(v_13, "null") : Bool}
      v_1002014 = {v_13 : String}
      v_1002015 = {v_11 : String}
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_case_bindings{v_12, v_14}}, +v_1002016 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_case_binding_source{v_1002013, v_1002014, v_1002015, v_1002016}}, +v_1002017 => EmitterFinished{v_1002017}}}
    case _, _:
      EmitterFinished{"throw \"bend: malformed pattern bindings\";"}

def emitter_match_427(v_1: Bool, v_7: String, v_3: String, v_5: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{v_7}
    case False{}:
      EmitterFinished{String.append("const ", String.append(v_3, String.append("=", String.append(v_5, String.append(";", v_7)))))}

def emitter_body_js_case_binding_source(v_1: Bool, v_3: String, v_5: String, v_7: String) -> EmitterProgress<String>:
  emitter_match_427(v_1, v_7, v_3, v_5)

def emitter_continuation_428(v_16: List<&2, AST.SyntaxTerm>, v_4: List<&2, String>, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>, +v_1002018: String) -> EmitterProgress<String>:
  v_1002019 = {"\n" : String}
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_cases{v_16, v_4, v_6, v_8, v_11}}, +v_1002020 => EmitterFinished{String.append(v_1002018, String.append(v_1002019, v_1002020))}}

def emitter_match_429(+v_15: AST.SyntaxTerm, +v_4: List<&2, String>, +v_6: List<&2, AST.SyntaxTerm>, +v_8: EmitEnv, +v_11: Maybe<&2, EmitClosure>, v_16: List<&2, AST.SyntaxTerm>) -> EmitterProgress<String>:
  match v_15:
    case AST.BodyCase{v_20, v_21, _}:
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_case{v_20, v_21, v_4, v_6, v_8, v_11}}, False{}, v_1002021 => emitter_body_js_case(v_20, v_21, v_4, v_6, v_8, v_11), +v_1002018 => emitter_continuation_428(v_16, v_4, v_6, v_8, v_11, v_1002018)}
    case _:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_cases{v_16, v_4, v_6, v_8, v_11}}, +v_1002022 => EmitterFinished{v_1002022}}

def emitter_body_js_cases(v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, String>, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{"throw \"bend: runtime fail-stop\";"}
    case +v_15 <> v_16:
      emitter_match_429(v_15, v_4, v_6, v_8, v_11, v_16)

def emitter_body_js_switch_tags(v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv, v_6: Map<&2, Bool>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  match v_1:
    case []:
      EmitterFinished{Some{[]}}
    case AST.BodyCase{[AST.PatternCtr{v_16, v_17, _}], _, _} <> v_21:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_fields{v_17}}, +v_1002023 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_tag_fields{v_1002023, v_16, v_21, v_3, v_6}}, +v_1002024 => EmitterFinished{v_1002024}}}
    case _ <> _:
      EmitterFinished{None{}}

def emitter_body_js_switch_fields(v_1: List<&2, AST.SyntaxPattern>) -> EmitterProgress<Bool>:
  match v_1:
    case []:
      EmitterFinished{True{}}
    case AST.PatternVar{_, _, _, _} <> v_12:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_fields{v_12}}, +v_1002025 => EmitterFinished{v_1002025}}
    case _ <> _:
      EmitterFinished{False{}}

def emitter_continuation_433(+v_1002026: String, v_18: String, v_4: List<&2, AST.SyntaxTerm>, v_6: EmitEnv, v_9: Map<&2, Bool>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  v_26 = v_1002026
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_constructor_native{v_26}}, False{}, v_1002029 => emitter_body_js_constructor_native(v_26), +v_1002027 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_tag_native{String.eq(v_1002027, ""), v_18, v_4, v_6, v_9}}, +v_1002028 => EmitterFinished{v_1002028}}}

def emitter_body_js_switch_tag_constructor(v_2: Maybe<&2, EmitConstructor>, v_4: List<&2, AST.SyntaxTerm>, v_6: EmitEnv, v_9: Map<&2, Bool>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  match v_2:
    case None{}:
      EmitterFinished{None{}}
    case Some{EmitConstructor{+v_18, v_19, _, _, v_22}}:
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_constructor_native_origin{emitter_pure_js_base_origin(v_22), v_19, v_18}}, False{}, v_1002030 => emitter_body_js_constructor_native_origin(emitter_pure_js_base_origin(v_22), v_19, v_18), +v_1002026 => emitter_continuation_433(v_1002026, v_18, v_4, v_6, v_9)}

def emitter_match_435(v_1: Bool, v_3: String, +v_7: EmitEnv, v_5: List<&2, AST.SyntaxTerm>, v_10: Map<&2, Bool>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  match v_1:
    case False{}:
      EmitterFinished{None{}}
    case True{}:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_constructor_decl{v_3, v_7}}, False{}, v_1002033 => emitter_body_js_constructor_decl(v_3, v_7), +v_1002031 => emitter_body_js_switch_tag_constructor(v_1002031, v_5, v_7, v_10)}

def emitter_body_js_switch_tag_fields(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv, v_10: Map<&2, Bool>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  emitter_match_435(v_1, v_3, v_7, v_5, v_10)

def emitter_match_436(v_2: Maybe<&2, Bool>, +v_4: String, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_11: Map<&2, Bool>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  match v_2:
    case Some{_}:
      EmitterFinished{None{}}
    case None{}:
      v_1002034 = {v_4 : String}
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_tags{v_6, v_8, Map.set(&2, Bool, v_11, v_4, True{})}}, False{}, v_1002037 => emitter_body_js_switch_tags(v_6, v_8, Map.set(&2, Bool, v_11, v_4, True{})), +v_1002035 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_tag_rest{v_1002034, v_1002035}}, +v_1002036 => EmitterFinished{v_1002036}}}

def emitter_body_js_switch_tag_seen(v_2: Maybe<&2, Bool>, v_4: String, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_11: Map<&2, Bool>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  emitter_match_436(v_2, v_4, v_6, v_8, v_11)

def emitter_match_437(v_1: Bool, +v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv, v_10: Map<&2, Bool>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  match v_1:
    case False{}:
      EmitterFinished{None{}}
    case True{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_bmp_tag{v_3}}, +v_1002038 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_tag_ordered{v_1002038, v_3, v_5, v_7, v_10}}, +v_1002039 => EmitterFinished{v_1002039}}}

def emitter_body_js_switch_tag_native(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv, v_10: Map<&2, Bool>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  emitter_match_437(v_1, v_3, v_5, v_7, v_10)

def emitter_match_438(v_1: Bool, +v_10: Map<&2, Bool>, +v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  match v_1:
    case False{}:
      EmitterFinished{None{}}
    case True{}:
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_tag_seen{IndexLookup.find(Bool, v_10, v_3), v_3, v_5, v_7, v_10}}, False{}, v_1002041 => emitter_body_js_switch_tag_seen(IndexLookup.find(Bool, v_10, v_3), v_3, v_5, v_7, v_10), +v_1002040 => EmitterFinished{v_1002040}}

def emitter_body_js_switch_tag_ordered(v_1: Bool, v_3: String, v_5: List<&2, AST.SyntaxTerm>, v_7: EmitEnv, v_10: Map<&2, Bool>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  emitter_match_438(v_1, v_10, v_3, v_5, v_7)

def emitter_body_js_switch_bmp_tag(v_1: String) -> EmitterProgress<Bool>:
  match v_1:
    case "":
      EmitterFinished{True{}}
    case SCon{v_5, v_6}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_bmp_tail{U32.is_le(Char.to_u32(v_5), 65535), v_6}}, +v_1002042 => EmitterFinished{v_1002042}}

def emitter_body_js_switch_bmp_tail(v_1: Bool, v_3: String) -> EmitterProgress<Bool>:
  match v_1:
    case False{}:
      EmitterFinished{False{}}
    case True{}:
      emitter_body_js_switch_bmp_tag(v_3)

def emitter_match_441(v_5: Maybe<&2, List<&2, String>>, v_1: String) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  match v_5:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_10}:
      EmitterFinished{Some{v_1 <> v_10}}

def emitter_body_js_switch_tag_rest(v_1: String, v_5: Maybe<&2, List<&2, String>>) -> EmitterProgress<Maybe<&2, List<&2, String>>>:
  emitter_match_441(v_5, v_1)

def emitter_continuation_442(v_1002047: String, +v_1002048: String, v_1002049: String, +v_1002050: String, v_25: List<&2, AST.SyntaxTerm>, v_27: List<&2, String>, v_7: List<&2, String>, v_9: List<&2, AST.SyntaxTerm>, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_35 = String.append(v_1002047, String.append(v_1002048, String.append(v_1002049, v_1002050)))
  v_1002051 = {v_35 : String}
  v_1002052 = {"\n" : String}
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_cases{v_25, v_27, v_7, v_9, v_11, v_14}}, +v_1002053 => EmitterFinished{String.append(v_1002051, String.append(v_1002052, v_1002053))}}

def emitter_continuation_443(v_22: List<&2, AST.SyntaxPattern>, v_23: AST.SyntaxTerm, +v_7: List<&2, String>, v_31: List<&2, Maybe<&2, EmitClosure>>, +v_11: EmitEnv, +v_14: Maybe<&2, EmitClosure>, v_1002047: String, +v_1002048: String, v_25: List<&2, AST.SyntaxTerm>, v_27: List<&2, String>, v_9: List<&2, AST.SyntaxTerm>) -> EmitterProgress<String>:
  v_1002049 = {": " : String}
  EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_case_block_typed{v_22, v_23, v_7, v_31, v_11, v_14}}, False{}, v_1002054 => emitter_body_js_case_block_typed(v_22, v_23, v_7, v_31, v_11, v_14), +v_1002050 => emitter_continuation_442(v_1002047, v_1002048, v_1002049, v_1002050, v_25, v_27, v_7, v_9, v_11, v_14)}

def emitter_continuation_444(+v_1002046: List<&2, Maybe<&2, EmitClosure>>, +v_26: String, v_22: List<&2, AST.SyntaxPattern>, v_23: AST.SyntaxTerm, v_7: List<&2, String>, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>, v_25: List<&2, AST.SyntaxTerm>, v_27: List<&2, String>, v_9: List<&2, AST.SyntaxTerm>) -> EmitterProgress<String>:
  v_31 = v_1002046
  v_1002047 = {"case " : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_26}}, False{}, v_1002055 => emitter_body_js_quote(v_26), +v_1002048 => emitter_continuation_443(v_22, v_23, v_7, v_31, v_11, v_14, v_1002047, v_1002048, v_25, v_27, v_9)}

def emitter_match_445(v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, String>, +v_9: List<&2, AST.SyntaxTerm>, +v_11: EmitEnv, v_7: List<&2, String>, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_1, v_4:
    case [], []:
      EmitterFinished{"default: { throw \"bend: runtime fail-stop\"; }\n"}
    case AST.BodyCase{+v_22, v_23, _} <> v_25, +v_26 <> v_27:
      v_1002044 = {v_22 : List<&2, AST.SyntaxPattern>}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_scrutinee_types{v_9, v_11}}, False{}, v_1002057 => emitter_body_js_scrutinee_types(v_9, v_11), +v_1002045 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_pattern_types{v_1002044, v_1002045, v_11}}, False{}, v_1002056 => emitter_body_js_pattern_types(v_1002044, v_1002045, v_11), +v_1002046 => emitter_continuation_444(v_1002046, v_26, v_22, v_23, v_7, v_11, v_14, v_25, v_27, v_9)}}
    case _, _:
      EmitterFinished{"default: { throw \"bend: malformed switch cases\"; }\n"}

def emitter_body_js_switch_cases(v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, String>, v_7: List<&2, String>, v_9: List<&2, AST.SyntaxTerm>, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_445(v_1, v_4, v_9, v_11, v_7, v_14)

def emitter_body_js_switch_pairs(v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, String>) -> EmitterProgress<List<&2, EmitSwitchRow>>:
  match v_1, v_4:
    case +v_11 <> v_12, +v_13 <> v_14:
      v_1002058 = {EmitSwitchRow{v_13, v_11} : EmitSwitchRow}
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_pairs{v_12, v_14}}, +v_1002059 => EmitterFinished{v_1002058 <> v_1002059}}
    case _, _:
      EmitterFinished{[]}

def emitter_body_js_switch_row_le(v_1: EmitSwitchRow, v_3: EmitSwitchRow) -> EmitterProgress<Bool>:
  match v_1, v_3:
    case EmitSwitchRow{v_9, _}, EmitSwitchRow{v_11, _}:
      EmitterFinished{String.is_le(v_9, v_11)}

def emitter_match_448(+v_1: Nat, +v_4: List<&2, EmitSwitchRow>) -> EmitterProgress<List<&2, EmitSwitchRow>>:
  match v_1:
    case 0n:
      EmitterFinished{[]}
    case 1n:
      EmitterFinished{v_4}
    case _:
      +v_10 = Nat.div(v_1, 2n)
      v_13 = List.take(&2, EmitSwitchRow, v_4, v_10)
      v_16 = List.drop(&2, EmitSwitchRow, v_4, v_10)
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_sort{v_10, v_13}}, +v_1002060 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_sort{Nat.sub(v_1, v_10), v_16}}, +v_1002061 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_merge{v_1002060, v_1002061}}, +v_1002062 => EmitterFinished{v_1002062}}}}

def emitter_body_js_switch_sort(v_1: Nat, +v_4: List<&2, EmitSwitchRow>) -> EmitterProgress<List<&2, EmitSwitchRow>>:
  emitter_match_448(v_1, v_4)

def emitter_body_js_switch_merge(v_2: List<&2, EmitSwitchRow>, v_5: List<&2, EmitSwitchRow>) -> EmitterProgress<List<&2, EmitSwitchRow>>:
  match v_2:
    case []:
      EmitterFinished{v_5}
    case +v_10 <> +v_11:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_merge_right{v_5, v_10, v_11}}, +v_1002063 => EmitterFinished{v_1002063}}

def emitter_body_js_switch_merge_right(v_2: List<&2, EmitSwitchRow>, +v_4: EmitSwitchRow, +v_7: List<&2, EmitSwitchRow>) -> EmitterProgress<List<&2, EmitSwitchRow>>:
  match v_2:
    case []:
      EmitterFinished{v_4 <> v_7}
    case +v_12 <> +v_13:
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_row_le{v_4, v_12}}, False{}, v_1002066 => emitter_body_js_switch_row_le(v_4, v_12), +v_1002064 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_merge_order{v_1002064, v_4, v_7, v_12, v_13}}, +v_1002065 => EmitterFinished{v_1002065}}}

def emitter_body_js_switch_merge_order(v_1: Bool, +v_3: EmitSwitchRow, +v_6: List<&2, EmitSwitchRow>, +v_8: EmitSwitchRow, +v_11: List<&2, EmitSwitchRow>) -> EmitterProgress<List<&2, EmitSwitchRow>>:
  match v_1:
    case True{}:
      v_1002067 = {v_3 : EmitSwitchRow}
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_merge{v_6, v_8 <> v_11}}, False{}, v_1002069 => emitter_body_js_switch_merge(v_6, v_8 <> v_11), +v_1002068 => EmitterFinished{v_1002067 <> v_1002068}}
    case False{}:
      v_1002070 = {v_8 : EmitSwitchRow}
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_merge{v_3 <> v_6, v_11}}, False{}, v_1002072 => emitter_body_js_switch_merge(v_3 <> v_6, v_11), +v_1002071 => EmitterFinished{v_1002070 <> v_1002071}}

def emitter_match_452(+v_1: Nat, +v_4: List<&2, EmitSwitchRow>, v_6: String, v_9: List<&2, String>, v_11: List<&2, AST.SyntaxTerm>, v_13: EmitEnv, v_16: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_1:
    case 0n:
      EmitterFinished{""}
    case 1n:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_tree_leaf{v_4, v_6, v_9, v_11, v_13, v_16}}, +v_1002073 => EmitterFinished{v_1002073}}
    case _:
      +v_22 = Nat.div(v_1, 2n)
      v_25 = List.take(&2, EmitSwitchRow, v_4, v_22)
      v_28 = List.drop(&2, EmitSwitchRow, v_4, v_22)
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_switch_tree_split{v_28, v_25, v_22, Nat.sub(v_1, v_22), v_6, v_9, v_11, v_13, v_16}}, +v_1002074 => EmitterFinished{v_1002074}}

def emitter_body_js_switch_tree(v_1: Nat, v_4: List<&2, EmitSwitchRow>, v_6: String, v_9: List<&2, String>, v_11: List<&2, AST.SyntaxTerm>, v_13: EmitEnv, v_16: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_452(v_1, v_4, v_6, v_9, v_11, v_13, v_16)

def emitter_continuation_453(+v_1002078: String, v_4: String, v_20: String) -> EmitterProgress<String>:
  v_30 = v_1002078
  v_1002079 = {"if (" : String}
  v_1002080 = {v_4 : String}
  v_1002081 = {" === " : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_20}}, False{}, v_1002083 => emitter_body_js_quote(v_20), +v_1002082 => EmitterFinished{String.append(v_1002079, String.append(v_1002080, String.append(v_1002081, String.append(v_1002082, String.append(") ", String.append(v_30, "\n"))))))}}

def emitter_continuation_454(+v_1002077: List<&2, Maybe<&2, EmitClosure>>, v_21: List<&2, AST.SyntaxPattern>, v_22: AST.SyntaxTerm, v_7: List<&2, String>, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>, v_4: String, v_20: String) -> EmitterProgress<String>:
  v_27 = v_1002077
  EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_case_block_typed{v_21, v_22, v_7, v_27, v_11, v_14}}, False{}, v_1002084 => emitter_body_js_case_block_typed(v_21, v_22, v_7, v_27, v_11, v_14), +v_1002078 => emitter_continuation_453(v_1002078, v_4, v_20)}

def emitter_match_455(v_2: List<&2, EmitSwitchRow>, v_9: List<&2, AST.SyntaxTerm>, +v_11: EmitEnv, v_7: List<&2, String>, v_14: Maybe<&2, EmitClosure>, v_4: String) -> EmitterProgress<String>:
  match v_2:
    case [EmitSwitchRow{v_20, AST.BodyCase{+v_21, v_22, _}}]:
      v_1002075 = {v_21 : List<&2, AST.SyntaxPattern>}
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_scrutinee_types{v_9, v_11}}, False{}, v_1002086 => emitter_body_js_scrutinee_types(v_9, v_11), +v_1002076 => EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_pattern_types{v_1002075, v_1002076, v_11}}, False{}, v_1002085 => emitter_body_js_pattern_types(v_1002075, v_1002076, v_11), +v_1002077 => emitter_continuation_454(v_1002077, v_21, v_22, v_7, v_11, v_14, v_4, v_20)}}
    case _:
      EmitterFinished{"throw \"bend: malformed switch cases\";"}

def emitter_body_js_switch_tree_leaf(v_2: List<&2, EmitSwitchRow>, v_4: String, v_7: List<&2, String>, v_9: List<&2, AST.SyntaxTerm>, v_11: EmitEnv, v_14: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_455(v_2, v_9, v_11, v_7, v_14, v_4)

def emitter_continuation_456(v_1002089: String, v_1002090: String, v_1002091: String, +v_1002092: String, v_31: String, v_34: String) -> EmitterProgress<String>:
  v_37 = String.append(v_1002089, String.append(v_1002090, String.append(v_1002091, String.append(v_1002092, ") {\n"))))
  EmitterFinished{String.append(v_37, String.append(v_31, String.append("} else {\n", String.append(v_34, "}\n"))))}

def emitter_continuation_457(+v_1002088: String, v_11: String, v_26: String, v_31: String) -> EmitterProgress<String>:
  v_34 = v_1002088
  v_1002089 = {"if (" : String}
  v_1002090 = {v_11 : String}
  v_1002091 = {" < " : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_26}}, False{}, v_1002093 => emitter_body_js_quote(v_26), +v_1002092 => emitter_continuation_456(v_1002089, v_1002090, v_1002091, v_1002092, v_31, v_34)}

def emitter_continuation_458(+v_1002087: String, v_9: Nat, v_2: List<&2, EmitSwitchRow>, +v_11: String, v_14: List<&2, String>, v_16: List<&2, AST.SyntaxTerm>, v_18: EmitEnv, v_21: Maybe<&2, EmitClosure>, v_26: String) -> EmitterProgress<String>:
  v_31 = v_1002087
  EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_tree{v_9, v_2, v_11, v_14, v_16, v_18, v_21}}, False{}, v_1002094 => emitter_body_js_switch_tree(v_9, v_2, v_11, v_14, v_16, v_18, v_21), +v_1002088 => emitter_continuation_457(v_1002088, v_11, v_26, v_31)}

def emitter_match_459(+v_2: List<&2, EmitSwitchRow>, v_7: Nat, v_5: List<&2, EmitSwitchRow>, +v_11: String, +v_14: List<&2, String>, +v_16: List<&2, AST.SyntaxTerm>, +v_18: EmitEnv, +v_21: Maybe<&2, EmitClosure>, v_9: Nat) -> EmitterProgress<String>:
  match v_2:
    case EmitSwitchRow{v_26, _} <> _:
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_tree{v_7, v_5, v_11, v_14, v_16, v_18, v_21}}, False{}, v_1002095 => emitter_body_js_switch_tree(v_7, v_5, v_11, v_14, v_16, v_18, v_21), +v_1002087 => emitter_continuation_458(v_1002087, v_9, v_2, v_11, v_14, v_16, v_18, v_21, v_26)}
    case []:
      EmitterFinished{"throw \"bend: malformed switch cases\";"}

def emitter_body_js_switch_tree_split(v_2: List<&2, EmitSwitchRow>, v_5: List<&2, EmitSwitchRow>, v_7: Nat, v_9: Nat, v_11: String, v_14: List<&2, String>, v_16: List<&2, AST.SyntaxTerm>, v_18: EmitEnv, v_21: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_459(v_2, v_7, v_5, v_11, v_14, v_16, v_18, v_21, v_9)

def emitter_continuation_460(+v_1002103: String, v_27: String, v_36: String) -> EmitterProgress<String>:
  v_39 = v_1002103
  v_41 = String.append("if (typeof ", String.append(v_27, String.append(" === \"string\") {\n", String.append(v_39, "}\n"))))
  EmitterFinished{String.append(v_36, String.append(v_41, "throw \"bend: runtime fail-stop\";"))}

def emitter_continuation_461(+v_1002102: List<&2, EmitSwitchRow>, +v_27: String, +v_8: String, v_3: Nat, v_13: List<&2, String>, v_15: List<&2, AST.SyntaxTerm>, v_30: EmitEnv, v_20: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_34 = v_1002102
  v_36 = String.append("const ", String.append(v_27, String.append(" = ", String.append(v_8, String.append(" && ", String.append(v_8, ".$;\n"))))))
  EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_tree{v_3, v_34, v_27, v_13, v_15, v_30, v_20}}, False{}, v_1002104 => emitter_body_js_switch_tree(v_3, v_34, v_27, v_13, v_15, v_30, v_20), +v_1002103 => emitter_continuation_460(v_1002103, v_27, v_36)}

def emitter_continuation_462(+v_1002099: EmitEnv, +v_3: Nat, v_10: List<&2, AST.SyntaxTerm>, v_6: List<&2, String>, v_27: String, v_8: String, v_13: List<&2, String>, v_15: List<&2, AST.SyntaxTerm>, v_20: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_30 = v_1002099
  v_1002100 = {v_3 : Nat}
  EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_pairs{v_10, v_6}}, False{}, v_1002106 => emitter_body_js_switch_pairs(v_10, v_6), +v_1002101 => EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_sort{v_1002100, v_1002101}}, False{}, v_1002105 => emitter_body_js_switch_sort(v_1002100, v_1002101), +v_1002102 => emitter_continuation_461(v_1002102, v_27, v_8, v_3, v_13, v_15, v_30, v_20)}}

def emitter_match_463(v_1: Bool, +v_8: String, v_10: List<&2, AST.SyntaxTerm>, v_6: List<&2, String>, v_13: List<&2, String>, v_15: List<&2, AST.SyntaxTerm>, +v_17: EmitEnv, v_20: Maybe<&2, EmitClosure>, v_3: Nat) -> EmitterProgress<String>:
  match v_1:
    case False{}:
      v_23 = String.append("switch (", String.append(v_8, String.append(" && ", String.append(v_8, ".$) {\n"))))
      v_1002096 = {v_23 : String}
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_cases{v_10, v_6, v_13, v_15, v_17, v_20}}, False{}, v_1002098 => emitter_body_js_switch_cases(v_10, v_6, v_13, v_15, v_17, v_20), +v_1002097 => EmitterFinished{String.append(v_1002096, String.append(v_1002097, "}"))}}
    case True{}:
      v_27 = String.append("$tag", Nat.show(emitter_pure_env_depth(v_17)))
      EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_env_reserve_names{1n, v_17}}, False{}, v_1002107 => emitter_body_env_reserve_names(1n, v_17), +v_1002099 => emitter_continuation_462(v_1002099, v_3, v_10, v_6, v_27, v_8, v_13, v_15, v_20)}

def emitter_body_js_cases_dispatch_size(v_1: Bool, v_3: Nat, v_6: List<&2, String>, v_8: String, v_10: List<&2, AST.SyntaxTerm>, v_13: List<&2, String>, v_15: List<&2, AST.SyntaxTerm>, v_17: EmitEnv, v_20: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_463(v_1, v_8, v_10, v_6, v_13, v_15, v_17, v_20, v_3)

def emitter_match_464(+v_2: List<&2, String>, +v_4: List<&2, AST.SyntaxTerm>, +v_6: List<&2, AST.SyntaxTerm>, +v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  match v_2, v_4, v_6:
    case [+v_17], [_], _ <> _:
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_switch_tags{v_6, v_8, MTip{}}}, False{}, v_1002110 => emitter_body_js_switch_tags(v_6, v_8, MTip{}), +v_1002108 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_cases_dispatch_switch{v_1002108, v_17, v_6, v_2, v_4, v_8, v_11}}, +v_1002109 => EmitterFinished{v_1002109}}}
    case _, _, _:
      emitter_body_js_cases(v_6, v_2, v_4, v_8, v_11)

def emitter_body_js_cases_dispatch_values(v_2: List<&2, String>, v_4: List<&2, AST.SyntaxTerm>, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_464(v_2, v_4, v_6, v_8, v_11)

def emitter_body_js_cases_dispatch(v_1: List<&2, AST.SyntaxTerm>, v_4: List<&2, String>, v_6: List<&2, AST.SyntaxTerm>, v_8: EmitEnv, v_11: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_body_js_cases_dispatch_values(v_4, v_6, v_1, v_8, v_11)

def emitter_match_465(v_3: Maybe<&2, List<&2, String>>, v_7: List<&2, AST.SyntaxTerm>, v_10: List<&2, String>, v_12: List<&2, AST.SyntaxTerm>, v_14: EmitEnv, v_17: Maybe<&2, EmitClosure>, v_5: String) -> EmitterProgress<String>:
  match v_3:
    case None{}:
      emitter_body_js_cases(v_7, v_10, v_12, v_14, v_17)
    case Some{+v_21}:
      +v_24 = List.length(&2, String, v_21)
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_cases_dispatch_size{Nat.is_ge(v_24, 32n), v_24, v_21, v_5, v_7, v_10, v_12, v_14, v_17}}, False{}, v_1002115 => emitter_body_js_cases_dispatch_size(Nat.is_ge(v_24, 32n), v_24, v_21, v_5, v_7, v_10, v_12, v_14, v_17), +v_1002114 => EmitterFinished{v_1002114}}

def emitter_body_js_cases_dispatch_switch(v_3: Maybe<&2, List<&2, String>>, v_5: String, v_7: List<&2, AST.SyntaxTerm>, v_10: List<&2, String>, v_12: List<&2, AST.SyntaxTerm>, v_14: EmitEnv, v_17: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  emitter_match_465(v_3, v_7, v_10, v_12, v_14, v_17, v_5)

def emitter_continuation_466(v_10: List<&2, AST.SyntaxTerm>, v_3: EmitEnv, v_5: Nat, v_1002116: String, v_1002117: String, v_1002118: String, +v_1002119: String) -> EmitterProgress<String>:
  v_1002120 = {";\n" : String}
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_scrutinees{v_10, v_3, Nat.add(v_5, 1n)}}, +v_1002121 => EmitterFinished{String.append(v_1002116, String.append(v_1002117, String.append(v_1002118, String.append(v_1002119, String.append(v_1002120, v_1002121)))))}}

def emitter_match_467(v_1: List<&2, AST.SyntaxTerm>, +v_3: EmitEnv, +v_5: Nat) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{""}
    case +v_9 <> v_10:
      v_15 = String.append("$s", Nat.show(Nat.add(emitter_pure_env_depth(v_3), v_5)))
      v_1002116 = {"const " : String}
      v_1002117 = {v_15 : String}
      v_1002118 = {" = " : String}
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_term{v_9, v_3}}, False{}, v_1002122 => emitter_body_js_term(v_9, v_3), +v_1002119 => emitter_continuation_466(v_10, v_3, v_5, v_1002116, v_1002117, v_1002118, v_1002119)}

def emitter_body_js_scrutinees(v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv, v_5: Nat) -> EmitterProgress<String>:
  emitter_match_467(v_1, v_3, v_5)

def emitter_body_scrutinee_names(v_1: Nat, v_3: EmitEnv) -> EmitterProgress<List<&2, String>>:
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_scrutinee_names_at{v_1, emitter_pure_env_depth(v_3)}}, +v_1002123 => EmitterFinished{v_1002123}}

def emitter_match_468(+v_1: Nat, +v_3: Nat) -> EmitterProgress<List<&2, String>>:
  match v_1:
    case 0n:
      EmitterFinished{[]}
    case _:
      v_1002124 = {String.append("$s", Nat.show(v_3)) : String}
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_scrutinee_names_at{Nat.sub(v_1, 1n), Nat.add(v_3, 1n)}}, +v_1002125 => EmitterFinished{v_1002124 <> v_1002125}}

def emitter_body_scrutinee_names_at(v_1: Nat, v_3: Nat) -> EmitterProgress<List<&2, String>>:
  emitter_match_468(v_1, v_3)

def emitter_body_js_body_match(v_1: List<&2, AST.SyntaxTerm>, v_3: List<&2, AST.SyntaxTerm>, v_5: EmitEnv, v_8: Maybe<&2, EmitClosure>) -> EmitterProgress<String>:
  v_1002126 = {"(()=>{" : String}
  EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_statement_match{v_1, v_3, v_5, v_8}}, False{}, v_1002128 => emitter_body_js_statement_match(v_1, v_3, v_5, v_8), +v_1002127 => EmitterFinished{String.append(v_1002126, String.append(v_1002127, "})()"))}}

def emitter_match_469(v_5: AST.OptionalTerm, v_4: AST.SyntaxTerm, +v_3: EmitEnv) -> EmitterProgress<String>:
  match v_5:
    case AST.SomeTerm{v_8}:
      v_1002129 = {v_4 : AST.SyntaxTerm}
      v_1002130 = {v_3 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_8, v_3}}, False{}, v_1002134 => emitter_body_js_close(v_8, v_3), +v_1002131 => EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_term_tail_expected{v_1002129, v_1002130, Some{v_1002131}}}, False{}, v_1002133 => emitter_body_js_term_tail_expected(v_1002129, v_1002130, Some{v_1002131}), +v_1002132 => EmitterFinished{v_1002132}}}
    case AST.NoTerm{}:
      emitter_body_js_term_tail_expected(v_4, v_3, None{})

def emitter_match_470(v_1: List<&2, AST.TelescopeItem>, v_5: AST.OptionalTerm, v_4: AST.SyntaxTerm, +v_3: EmitEnv) -> EmitterProgress<String>:
  match v_1:
    case []:
      emitter_match_469(v_5, v_4, v_3)
    case AST.Binder{AST.QZero{}, _, _, v_19, _} <> v_21:
      v_1002136 = {v_21 : List<&2, AST.TelescopeItem>}
      v_1002137 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_19, v_3}}, False{}, v_1002142 => emitter_body_js_close(v_19, v_3), +v_1002138 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1002137, Some{v_1002138}, None{}, v_3}}, False{}, v_1002141 => emitter_body_env_bind(v_1002137, Some{v_1002138}, None{}, v_3), +v_1002139 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_binders{v_1002136, v_1002139, v_4, v_5}}, +v_1002140 => EmitterFinished{v_1002140}}}}
    case AST.Binder{_, _, _, v_34, _} <> v_36:
      +v_39 = String.append("$a", Nat.show(emitter_pure_env_depth(v_3)))
      v_1002143 = {v_39 : String}
      v_1002144 = {v_36 : List<&2, AST.TelescopeItem>}
      v_1002145 = {v_39 : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_34, v_3}}, False{}, v_1002151 => emitter_body_js_close(v_34, v_3), +v_1002146 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1002145, Some{v_1002146}, None{}, v_3}}, False{}, v_1002150 => emitter_body_env_bind(v_1002145, Some{v_1002146}, None{}, v_3), +v_1002147 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_binders{v_1002144, v_1002147, v_4, v_5}}, +v_1002148 => emitter_body_js_closure(v_1002143, v_1002148)}}}
    case AST.TemplateBinder{_, _, _, _} <> v_53:
      v_1002152 = {v_53 : List<&2, AST.TelescopeItem>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_push{"null", v_3}}, False{}, v_1002155 => emitter_body_env_push("null", v_3), +v_1002153 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_binders{v_1002152, v_1002153, v_4, v_5}}, +v_1002154 => EmitterFinished{v_1002154}}}

def emitter_body_js_binders(v_1: List<&2, AST.TelescopeItem>, v_3: EmitEnv, v_4: AST.SyntaxTerm, v_5: AST.OptionalTerm) -> EmitterProgress<String>:
  emitter_match_470(v_1, v_5, v_4, v_3)

def emitter_continuation_471(+v_1002159: String, v_26: List<&2, String>, v_14: String, v_3: String, v_15: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  v_29 = v_1002159
  v_1002160 = {v_29 : String}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_foreign{v_26, v_14, v_3, v_15}}, +v_1002161 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decl_deferred_value{v_1002160, v_1002161}}, +v_1002162 => EmitterFinished{v_1002162}}}

def emitter_match_472(v_17: AST.DefBody, +v_15: List<&2, AST.TelescopeItem>, +v_16: AST.OptionalTerm, +v_6: EmitEnv, v_1: String, +v_14: String, v_3: String) -> EmitterProgress<String>:
  match v_17:
    case AST.DefTerm{+v_21}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_definition_is_type{v_15, v_16, v_21, v_6}}, +v_1002156 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_1, v_14}}, +v_1002157 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_decl_term{v_1002156, v_1002157, v_15, v_16, v_21, v_6}}, +v_1002158 => EmitterFinished{v_1002158}}}}
    case AST.DefImports{v_26}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_1, v_14}}, +v_1002159 => emitter_continuation_471(v_1002159, v_26, v_14, v_3, v_15)}

def emitter_match_473(v_4: AST.TopLevel, v_6: EmitEnv, v_1: String, v_3: String) -> EmitterProgress<String>:
  match v_4:
    case AST.DefTop{AST.Definition{v_14, v_15, v_16, v_17, _, _}}:
      emitter_match_472(v_17, v_15, v_16, v_6, v_1, v_14, v_3)
    case AST.TypeTop{_}:
      EmitterFinished{""}
    case AST.LawTop{AST.LawDecl{+v_38, v_39, _, _}}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_operation{v_38, v_6}}, False{}, v_1002168 => emitter_body_js_native_operation(v_38, v_6), +v_1002163 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_native_law_binders{v_39, 0n}}, False{}, v_1002167 => emitter_body_js_native_law_binders(v_39, 0n), +v_1002164 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify{v_1, v_38}}, +v_1002165 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decl_native_law{v_1002163, v_1002164, v_1002165}}, +v_1002166 => EmitterFinished{v_1002166}}}}}

def emitter_body_js_decl(v_1: String, v_3: String, v_4: AST.TopLevel, v_6: EmitEnv) -> EmitterProgress<String>:
  emitter_match_473(v_4, v_6, v_1, v_3)

def emitter_match_474(v_1: Bool, +v_3: String, +v_9: EmitEnv, v_5: List<&2, AST.TelescopeItem>, v_6: AST.OptionalTerm, v_7: AST.SyntaxTerm) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{""}
    case False{}:
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_operation{v_3, v_9}}, False{}, v_1002171 => emitter_body_js_native_operation(v_3, v_9), +v_1002169 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_decl_term_operation{v_1002169, v_3, v_5, v_6, v_7, v_9}}, +v_1002170 => EmitterFinished{v_1002170}}}

def emitter_body_js_decl_term(v_1: Bool, v_3: String, v_5: List<&2, AST.TelescopeItem>, v_6: AST.OptionalTerm, v_7: AST.SyntaxTerm, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_474(v_1, v_3, v_9, v_5, v_6, v_7)

def emitter_match_475(v_2: Maybe<&2, String>, +v_4: String, +v_6: List<&2, AST.TelescopeItem>, +v_7: AST.OptionalTerm, +v_8: AST.SyntaxTerm, +v_10: EmitEnv) -> EmitterProgress<String>:
  match v_2:
    case Some{v_13}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decl_native_value{v_4, v_13, v_6}}, +v_1002172 => EmitterFinished{v_1002172}}
    case None{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_named_eligible{v_4, v_6, v_7, v_8, v_10}}, +v_1002173 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_decl_named{v_1002173, v_4, v_6, v_7, v_8, v_10}}, +v_1002174 => EmitterFinished{v_1002174}}}

def emitter_body_js_decl_term_operation(v_2: Maybe<&2, String>, v_4: String, v_6: List<&2, AST.TelescopeItem>, v_7: AST.OptionalTerm, v_8: AST.SyntaxTerm, v_10: EmitEnv) -> EmitterProgress<String>:
  emitter_match_475(v_2, v_4, v_6, v_7, v_8, v_10)

def emitter_body_js_named_eligible(v_1: String, +v_3: List<&2, AST.TelescopeItem>, +v_4: AST.OptionalTerm, +v_5: AST.SyntaxTerm, +v_7: EmitEnv) -> EmitterProgress<Bool>:
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_operation{v_1, v_7}}, False{}, v_1002177 => emitter_body_js_native_operation(v_1, v_7), +v_1002175 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_named_eligible_operation{v_1002175, v_3, v_4, v_5, v_7}}, +v_1002176 => EmitterFinished{v_1002176}}}

def emitter_body_js_named_eligible_operation(v_2: Maybe<&2, String>, +v_4: List<&2, AST.TelescopeItem>, +v_5: AST.OptionalTerm, +v_6: AST.SyntaxTerm, +v_8: EmitEnv) -> EmitterProgress<Bool>:
  match v_2:
    case Some{_}:
      EmitterFinished{False{}}
    case None{}:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_named_fixed{v_4, v_5}}, +v_1002178 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_definition_has_live_binder{v_4}}, +v_1002179 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_definition_is_type{v_4, v_5, v_6, v_8}}, +v_1002180 => EmitterFinished{Bool.and(v_1002178, Bool.and(v_1002179, Bool.not(v_1002180)))}}}}

def emitter_match_477(v_2: AST.OptionalTerm) -> EmitterProgress<Bool>:
  match v_2:
    case AST.SomeTerm{_}:
      EmitterFinished{True{}}
    case AST.NoTerm{}:
      EmitterFinished{False{}}

def emitter_body_js_named_fixed(v_1: List<&2, AST.TelescopeItem>, v_2: AST.OptionalTerm) -> EmitterProgress<Bool>:
  match v_1:
    case AST.Binder{_, _, _, _, _} <> v_15:
      EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_named_fixed{v_15, v_2}}, +v_1002181 => EmitterFinished{v_1002181}}
    case AST.TemplateBinder{_, _, _, _} <> _:
      EmitterFinished{False{}}
    case []:
      emitter_match_477(v_2)

def emitter_continuation_479(v_3: String, v_5: List<&2, AST.TelescopeItem>, v_9: EmitEnv, v_7: AST.SyntaxTerm, v_6: AST.OptionalTerm, +v_1002182: Bool) -> EmitterProgress<String>:
  v_1002183 = {v_3 : String}
  EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_binders{v_5, v_9, v_7, v_6}}, False{}, v_1002186 => emitter_body_js_binders(v_5, v_9, v_7, v_6), +v_1002184 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decl_value{v_1002182, v_1002183, v_1002184}}, +v_1002185 => EmitterFinished{v_1002185}}}

def emitter_continuation_480(+v_1002189: String, v_16: String, +v_3: String, v_5: List<&2, AST.TelescopeItem>, v_9: EmitEnv) -> EmitterProgress<String>:
  v_19 = v_1002189
  v_1002190 = {v_16 : String}
  v_1002191 = {v_19 : String}
  v_1002192 = {";\n" : String}
  v_1002193 = {True{} : Bool}
  v_1002194 = {v_3 : String}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_named_facade{v_5, v_9, v_3, []}}, +v_1002195 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decl_value{v_1002193, v_1002194, v_1002195}}, +v_1002196 => EmitterFinished{String.append(v_1002190, String.append(v_1002191, String.append(v_1002192, v_1002196)))}}}

def emitter_continuation_481(v_1002187: String, +v_1002188: String, +v_5: List<&2, AST.TelescopeItem>, +v_9: EmitEnv, v_7: AST.SyntaxTerm, v_6: AST.OptionalTerm, v_3: String) -> EmitterProgress<String>:
  v_16 = String.append(v_1002187, String.append(v_1002188, " = ("))
  EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_named_body{v_5, v_9, v_7, v_6, True{}}}, +v_1002189 => emitter_continuation_480(v_1002189, v_16, v_3, v_5, v_9)}

def emitter_match_482(v_1: Bool, +v_5: List<&2, AST.TelescopeItem>, +v_3: String, v_9: EmitEnv, v_7: AST.SyntaxTerm, v_6: AST.OptionalTerm) -> EmitterProgress<String>:
  match v_1:
    case False{}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_definition_has_live_binder{v_5}}, +v_1002182 => emitter_continuation_479(v_3, v_5, v_9, v_7, v_6, v_1002182)}
    case True{}:
      v_1002187 = {"var " : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_named_identifier{v_3}}, False{}, v_1002197 => emitter_body_js_named_identifier(v_3), +v_1002188 => emitter_continuation_481(v_1002187, v_1002188, v_5, v_9, v_7, v_6, v_3)}

def emitter_body_js_decl_named(v_1: Bool, v_3: String, v_5: List<&2, AST.TelescopeItem>, v_6: AST.OptionalTerm, v_7: AST.SyntaxTerm, v_9: EmitEnv) -> EmitterProgress<String>:
  emitter_match_482(v_1, v_5, v_3, v_9, v_7, v_6)

def emitter_continuation_483(+v_37: String, v_34: List<&2, AST.TelescopeItem>, v_32: AST.SyntaxTerm, +v_3: EmitEnv, v_4: AST.SyntaxTerm, v_5: AST.OptionalTerm, +v_1002208: String) -> EmitterProgress<String>:
  v_1002209 = {v_37 : String}
  v_1002210 = {v_34 : List<&2, AST.TelescopeItem>}
  v_1002211 = {v_37 : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_32, v_3}}, False{}, v_1002216 => emitter_body_js_close(v_32, v_3), +v_1002212 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1002211, Some{v_1002212}, None{}, v_3}}, False{}, v_1002215 => emitter_body_env_bind(v_1002211, Some{v_1002212}, None{}, v_3), +v_1002213 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_named_body{v_1002210, v_1002213, v_4, v_5, False{}}}, +v_1002214 => EmitterFinished{String.append(v_1002208, String.append(v_1002209, v_1002214))}}}}

def emitter_match_484(v_1: List<&2, AST.TelescopeItem>, v_4: AST.SyntaxTerm, +v_3: EmitEnv, v_5: AST.OptionalTerm, v_7: Bool) -> EmitterProgress<String>:
  match v_1:
    case []:
      v_1002198 = {",$td=0) => {" : String}
      EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_statement_result{v_4, v_3, v_5}}, False{}, v_1002200 => emitter_body_js_statement_result(v_4, v_3, v_5), +v_1002199 => EmitterFinished{String.append(v_1002198, String.append(v_1002199, "}"))}}
    case AST.Binder{AST.QZero{}, _, _, v_17, _} <> v_19:
      v_1002201 = {v_19 : List<&2, AST.TelescopeItem>}
      v_1002202 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_17, v_3}}, False{}, v_1002207 => emitter_body_js_close(v_17, v_3), +v_1002203 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1002202, Some{v_1002203}, None{}, v_3}}, False{}, v_1002206 => emitter_body_env_bind(v_1002202, Some{v_1002203}, None{}, v_3), +v_1002204 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_named_body{v_1002201, v_1002204, v_4, v_5, v_7}}, +v_1002205 => EmitterFinished{v_1002205}}}}
    case AST.Binder{_, _, _, v_32, _} <> v_34:
      v_37 = String.append("$a", Nat.show(emitter_pure_env_depth(v_3)))
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_comma_prefix{v_7}}, False{}, v_1002217 => emitter_body_js_comma_prefix(v_7), +v_1002208 => emitter_continuation_483(v_37, v_34, v_32, v_3, v_4, v_5, v_1002208)}
    case AST.TemplateBinder{_, _, _, _} <> v_51:
      v_1002218 = {v_51 : List<&2, AST.TelescopeItem>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_push{"null", v_3}}, False{}, v_1002221 => emitter_body_env_push("null", v_3), +v_1002219 => EmitterPending{EmitterRequestGroup_5{EmitterRequest_js_named_body{v_1002218, v_1002219, v_4, v_5, v_7}}, +v_1002220 => EmitterFinished{v_1002220}}}

def emitter_body_js_named_body(v_1: List<&2, AST.TelescopeItem>, v_3: EmitEnv, v_4: AST.SyntaxTerm, v_5: AST.OptionalTerm, v_7: Bool) -> EmitterProgress<String>:
  emitter_match_484(v_1, v_4, v_3, v_5, v_7)

def emitter_match_485(v_1: List<&2, AST.TelescopeItem>, v_5: String, v_8: List<&2, String>, +v_3: EmitEnv) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_named_tail{v_5, List.reverse(&2, String, v_8)}}, False{}, v_1002223 => emitter_body_js_named_tail(v_5, List.reverse(&2, String, v_8)), +v_1002222 => EmitterFinished{v_1002222}}
    case AST.Binder{AST.QZero{}, _, _, v_19, _} <> v_21:
      v_1002224 = {v_21 : List<&2, AST.TelescopeItem>}
      v_1002225 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_19, v_3}}, False{}, v_1002230 => emitter_body_js_close(v_19, v_3), +v_1002226 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1002225, Some{v_1002226}, None{}, v_3}}, False{}, v_1002229 => emitter_body_env_bind(v_1002225, Some{v_1002226}, None{}, v_3), +v_1002227 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_named_facade{v_1002224, v_1002227, v_5, v_8}}, +v_1002228 => EmitterFinished{v_1002228}}}}
    case AST.Binder{_, _, _, v_34, _} <> v_36:
      +v_39 = String.append("$a", Nat.show(emitter_pure_env_depth(v_3)))
      v_1002231 = {v_39 : String}
      v_1002232 = {v_36 : List<&2, AST.TelescopeItem>}
      v_1002233 = {v_39 : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_34, v_3}}, False{}, v_1002239 => emitter_body_js_close(v_34, v_3), +v_1002234 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1002233, Some{v_1002234}, None{}, v_3}}, False{}, v_1002238 => emitter_body_env_bind(v_1002233, Some{v_1002234}, None{}, v_3), +v_1002235 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_named_facade{v_1002232, v_1002235, v_5, v_39 <> v_8}}, +v_1002236 => emitter_body_js_closure(v_1002231, v_1002236)}}}
    case AST.TemplateBinder{_, _, _, _} <> v_53:
      v_1002240 = {v_53 : List<&2, AST.TelescopeItem>}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_push{"null", v_3}}, False{}, v_1002243 => emitter_body_env_push("null", v_3), +v_1002241 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_named_facade{v_1002240, v_1002241, v_5, v_8}}, +v_1002242 => EmitterFinished{v_1002242}}}

def emitter_body_js_named_facade(v_1: List<&2, AST.TelescopeItem>, v_3: EmitEnv, v_5: String, v_8: List<&2, String>) -> EmitterProgress<String>:
  emitter_match_485(v_1, v_5, v_8, v_3)

def emitter_body_js_decl_native_law(v_2: Maybe<&2, String>, v_5: Maybe<&2, List<&2, AST.TelescopeItem>>, v_7: String) -> EmitterProgress<String>:
  match v_2, v_5:
    case Some{v_11}, Some{v_12}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decl_native_value{v_7, v_11, v_12}}, +v_1002244 => EmitterFinished{v_1002244}}
    case _, _:
      EmitterFinished{""}

def emitter_continuation_487(v_1002251: String, v_1002252: String, +v_1002253: String, v_10: String) -> EmitterProgress<String>:
  v_19 = String.append(v_1002251, String.append(v_1002252, String.append(v_1002253, "]};\n")))
  EmitterFinished{String.append(v_10, v_19)}

def emitter_continuation_488(v_1002249: String, +v_1002250: String, v_13: String, v_1: String, v_10: String) -> EmitterProgress<String>:
  v_16 = String.append(v_1002249, String.append(v_1002250, "],intrinsic:$D["))
  v_1002251 = {v_13 : String}
  v_1002252 = {v_16 : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1002254 => emitter_body_js_quote(v_1), +v_1002253 => emitter_continuation_487(v_1002251, v_1002252, v_1002253, v_10)}

def emitter_continuation_489(v_1002247: String, +v_1002248: String, +v_5: List<&2, AST.TelescopeItem>, v_1: String, v_10: String) -> EmitterProgress<String>:
  v_13 = String.append(v_1002247, String.append(v_1002248, String.append("]={n:", Nat.show(List.length(&2, AST.TelescopeItem, v_5)))))
  v_1002249 = {",q:[" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_field_quantities{v_5, True{}}}, +v_1002250 => emitter_continuation_488(v_1002249, v_1002250, v_13, v_1, v_10)}

def emitter_continuation_490(+v_1002246: String, +v_1: String, v_5: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  v_10 = v_1002246
  v_1002247 = {"$TYPEF[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1002255 => emitter_body_js_quote(v_1), +v_1002248 => emitter_continuation_489(v_1002247, v_1002248, v_5, v_1, v_10)}

def emitter_body_js_decl_native_value(+v_1: String, +v_3: String, +v_5: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_native_primitive_checked{Some{v_3}, v_5}}, False{}, v_1002256 => emitter_body_js_native_primitive_checked(Some{v_3}, v_5), +v_1002245 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decl_native_runtime{v_1002245, v_1, v_3}}, +v_1002246 => emitter_continuation_490(v_1002246, v_1, v_5)}}

def emitter_continuation_491(v_1002262: String, +v_1002263: String, +v_12: List<&2, String>, v_13: String, +v_4: String) -> EmitterProgress<String>:
  v_16 = String.append(v_1002262, String.append(v_1002263, String.append("=(", String.append(String.join(v_12, ","), String.append(")=>", String.append(v_13, ";\n"))))))
  v_1002264 = {v_16 : String}
  v_1002265 = {True{} : Bool}
  v_1002266 = {v_4 : String}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_native_facade{v_12, v_12, v_4}}, +v_1002267 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decl_value{v_1002265, v_1002266, v_1002267}}, +v_1002268 => EmitterFinished{String.append(v_1002264, v_1002268)}}}

def emitter_match_492(v_2: Maybe<&2, EmitPrimitive>, +v_4: String, v_6: String) -> EmitterProgress<String>:
  match v_2:
    case None{}:
      v_1002257 = {True{} : Bool}
      v_1002258 = {v_4 : String}
      EmitterDirect{Bool, EmitterRequestGroup_2{EmitterRequest_js_reference_old{v_6}}, False{}, v_1002261 => emitter_body_js_reference_old(v_6), +v_1002259 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decl_value{v_1002257, v_1002258, v_1002259}}, +v_1002260 => EmitterFinished{v_1002260}}}
    case Some{EmitPrimitive{v_12, v_13}}:
      v_1002262 = {"var " : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_named_identifier{v_4}}, False{}, v_1002269 => emitter_body_js_named_identifier(v_4), +v_1002263 => emitter_continuation_491(v_1002262, v_1002263, v_12, v_13, v_4)}

def emitter_body_js_decl_native_runtime(v_2: Maybe<&2, EmitPrimitive>, v_4: String, v_6: String) -> EmitterProgress<String>:
  emitter_match_492(v_2, v_4, v_6)

def emitter_match_493(v_2: List<&2, String>, v_7: String, v_5: List<&2, String>) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_named_identifier{v_7}}, False{}, v_1002271 => emitter_body_js_named_identifier(v_7), +v_1002270 => EmitterFinished{String.append(v_1002270, String.append("(", String.append(String.join(v_5, ","), ")")))}}
    case v_12 <> v_13:
      v_1002272 = {"(" : String}
      v_1002273 = {v_12 : String}
      v_1002274 = {")=>" : String}
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_native_facade{v_13, v_5, v_7}}, +v_1002275 => EmitterFinished{String.append(v_1002272, String.append(v_1002273, String.append(v_1002274, v_1002275)))}}

def emitter_body_js_native_facade(v_2: List<&2, String>, v_5: List<&2, String>, v_7: String) -> EmitterProgress<String>:
  emitter_match_493(v_2, v_7, v_5)

def emitter_body_js_definition_has_live_binder(v_1: List<&2, AST.TelescopeItem>) -> EmitterProgress<Bool>:
  match v_1:
    case []:
      EmitterFinished{False{}}
    case AST.Binder{AST.QZero{}, _, _, _, _} <> v_12:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_definition_has_live_binder{v_12}}, +v_1002276 => EmitterFinished{v_1002276}}
    case AST.Binder{_, _, _, _, _} <> _:
      EmitterFinished{True{}}
    case AST.TemplateBinder{_, _, _, _} <> v_35:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_definition_has_live_binder{v_35}}, +v_1002277 => EmitterFinished{v_1002277}}

def emitter_body_js_decl_value(v_1: Bool, v_3: String, v_5: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      v_1002278 = {"$D[" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_3}}, False{}, v_1002280 => emitter_body_js_quote(v_3), +v_1002279 => EmitterFinished{String.append(v_1002278, String.append(v_1002279, String.append("] = ", String.append(v_5, ";"))))}}
    case False{}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decl_deferred_value{v_3, v_5}}, +v_1002281 => EmitterFinished{v_1002281}}

def emitter_continuation_496(+v_1002282: String, v_3: String) -> EmitterProgress<String>:
  v_7 = v_1002282
  v_9 = String.append("Object.defineProperty($D,", String.append(v_7, ",{enumerable:true,configurable:true,get(){return run_loop("))
  EmitterFinished{String.append(v_9, String.append(v_3, ");}});"))}

def emitter_body_js_decl_deferred_value(v_1: String, v_3: String) -> EmitterProgress<String>:
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1002283 => emitter_body_js_quote(v_1), +v_1002282 => emitter_continuation_496(v_1002282, v_3)}

def emitter_match_497(v_2: AST.OptionalTerm, v_5: EmitEnv, v_3: AST.SyntaxTerm) -> EmitterProgress<Bool>:
  match v_2:
    case AST.SomeTerm{v_33}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_33, v_5}}, False{}, v_1002297 => emitter_body_js_close(v_33, v_5), +v_1002293 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1002293}}, False{}, v_1002296 => emitter_body_js_reduce(v_1002293), +v_1002294 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_type_is_sort{v_1002294}}, +v_1002295 => EmitterFinished{v_1002295}}}}
    case AST.NoTerm{}:
      EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_type{v_3, v_5}}, False{}, v_1002300 => emitter_body_js_type(v_3, v_5), +v_1002298 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_inferred_is_sort{v_1002298}}, +v_1002299 => EmitterFinished{v_1002299}}}

def emitter_match_498(v_1: List<&2, AST.TelescopeItem>, v_2: AST.OptionalTerm, v_3: AST.SyntaxTerm, +v_5: EmitEnv) -> EmitterProgress<Bool>:
  match v_1:
    case AST.Binder{_, _, _, v_16, _} <> v_18:
      v_1002284 = {v_18 : List<&2, AST.TelescopeItem>}
      v_1002285 = {v_2 : AST.OptionalTerm}
      v_1002286 = {v_3 : AST.SyntaxTerm}
      v_1002287 = {"null" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_16, v_5}}, False{}, v_1002292 => emitter_body_js_close(v_16, v_5), +v_1002288 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1002287, Some{v_1002288}, None{}, v_5}}, False{}, v_1002291 => emitter_body_env_bind(v_1002287, Some{v_1002288}, None{}, v_5), +v_1002289 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_definition_is_type{v_1002284, v_1002285, v_1002286, v_1002289}}, +v_1002290 => EmitterFinished{v_1002290}}}}
    case AST.TemplateBinder{_, _, _, _} <> _:
      EmitterFinished{False{}}
    case []:
      emitter_match_497(v_2, v_5, v_3)

def emitter_body_js_definition_is_type(v_1: List<&2, AST.TelescopeItem>, v_2: AST.OptionalTerm, v_3: AST.SyntaxTerm, v_5: EmitEnv) -> EmitterProgress<Bool>:
  emitter_match_498(v_1, v_2, v_3, v_5)

def emitter_body_js_inferred_is_sort(v_2: Maybe<&2, EmitClosure>) -> EmitterProgress<Bool>:
  match v_2:
    case Some{v_5}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_5}}, False{}, v_1002303 => emitter_body_js_reduce(v_5), +v_1002301 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_type_is_sort{v_1002301}}, +v_1002302 => EmitterFinished{v_1002302}}}
    case None{}:
      EmitterFinished{False{}}

def emitter_continuation_500(+v_1002304: EmitEnv, v_32: AST.SyntaxTerm, v_31: AST.SyntaxTerm) -> EmitterProgress<Bool>:
  +v_41 = v_1002304
  v_1002305 = {v_32 : AST.SyntaxTerm}
  v_1002306 = {"null" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_31, v_41}}, False{}, v_1002315 => emitter_body_js_close(v_31, v_41), +v_1002307 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_env_bind{v_1002306, Some{v_1002307}, None{}, v_41}}, False{}, v_1002314 => emitter_body_env_bind(v_1002306, Some{v_1002307}, None{}, v_41), +v_1002308 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_close{v_1002305, v_1002308}}, False{}, v_1002313 => emitter_body_js_close(v_1002305, v_1002308), +v_1002309 => EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_reduce{v_1002309}}, False{}, v_1002312 => emitter_body_js_reduce(v_1002309), +v_1002310 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_type_is_sort{v_1002310}}, +v_1002311 => EmitterFinished{v_1002311}}}}}}

def emitter_match_501(+v_1: EmitClosure) -> EmitterProgress<Bool>:
  match v_1:
    case EmitClosure{AST.TermType{_, _}, _, _, _, _, _}:
      EmitterFinished{True{}}
    case EmitClosure{AST.TermAll{_, _, _, v_31, v_32, _}, _, _, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_1}}, False{}, v_1002316 => emitter_body_js_closure_env(v_1), +v_1002304 => emitter_continuation_500(v_1002304, v_32, v_31)}
    case _:
      EmitterFinished{False{}}

def emitter_body_js_type_is_sort(v_1: EmitClosure) -> EmitterProgress<Bool>:
  emitter_match_501(v_1)

def emitter_match_502(+v_5: AST.TelescopeItem, v_6: List<&2, AST.TelescopeItem>) -> EmitterProgress<Nat>:
  match v_5:
    case AST.Binder{AST.QZero{}, _, _, _, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_live_binders{v_6}}, +v_1002317 => EmitterFinished{v_1002317}}
    case AST.Binder{_, _, _, _, _}:
      v_1002318 = {1n : Nat}
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_live_binders{v_6}}, +v_1002319 => EmitterFinished{Nat.add(v_1002318, v_1002319)}}
    case AST.TemplateBinder{_, _, _, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_live_binders{v_6}}, +v_1002320 => EmitterFinished{v_1002320}}

def emitter_body_js_live_binders(v_1: List<&2, AST.TelescopeItem>) -> EmitterProgress<Nat>:
  match v_1:
    case []:
      EmitterFinished{0n}
    case +v_5 <> v_6:
      emitter_match_502(v_5, v_6)

def emitter_body_js_foreign(v_2: List<&2, String>, v_4: String, v_6: String, v_8: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterFinished{"undefined"}
    case +v_12 <> v_13:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_foreign_path{String.ends_with(v_12, ".js"), v_13, v_12, v_4, v_6, v_8}}, +v_1002321 => EmitterFinished{v_1002321}}

def emitter_continuation_505(v_12: List<&2, AST.TelescopeItem>, v_1002322: String, +v_1002323: String, v_1002324: String, +v_1002325: String, v_1002326: String, +v_1002327: String, v_1002328: String, +v_1002329: String) -> EmitterProgress<String>:
  v_1002330 = {"], " : String}
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_live_binders{v_12}}, False{}, v_1002332 => emitter_body_js_live_binders(v_12), +v_1002331 => EmitterFinished{String.append(v_1002322, String.append(v_1002323, String.append(v_1002324, String.append(v_1002325, String.append(v_1002326, String.append(v_1002327, String.append(v_1002328, String.append(v_1002329, String.append(v_1002330, String.append(Nat.show(v_1002331), ")"))))))))))}}

def emitter_continuation_506(v_8: String, v_12: List<&2, AST.TelescopeItem>, v_1002322: String, +v_1002323: String, v_1002324: String, +v_1002325: String, v_1002326: String, +v_1002327: String) -> EmitterProgress<String>:
  v_1002328 = {")[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{String.append(v_8, "_need")}}, False{}, v_1002333 => emitter_body_js_quote(String.append(v_8, "_need")), +v_1002329 => emitter_continuation_505(v_12, v_1002322, v_1002323, v_1002324, v_1002325, v_1002326, v_1002327, v_1002328, v_1002329)}

def emitter_continuation_507(v_10: String, v_6: String, v_8: String, v_12: List<&2, AST.TelescopeItem>, v_1002322: String, +v_1002323: String, v_1002324: String, +v_1002325: String) -> EmitterProgress<String>:
  v_1002326 = {"], require(" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{Path.resolve(v_10, v_6)}}, False{}, v_1002334 => emitter_body_js_quote(Path.resolve(v_10, v_6)), +v_1002327 => emitter_continuation_506(v_8, v_12, v_1002322, v_1002323, v_1002324, v_1002325, v_1002326, v_1002327)}

def emitter_continuation_508(+v_8: String, v_10: String, v_6: String, v_12: List<&2, AST.TelescopeItem>, v_1002322: String, +v_1002323: String) -> EmitterProgress<String>:
  v_1002324 = {")[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_8}}, False{}, v_1002335 => emitter_body_js_quote(v_8), +v_1002325 => emitter_continuation_507(v_10, v_6, v_8, v_12, v_1002322, v_1002323, v_1002324, v_1002325)}

def emitter_match_509(v_1: Bool, +v_10: String, +v_6: String, v_8: String, v_12: List<&2, AST.TelescopeItem>, v_4: List<&2, String>) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      v_1002322 = {"$effect(require(" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{Path.resolve(v_10, v_6)}}, False{}, v_1002336 => emitter_body_js_quote(Path.resolve(v_10, v_6)), +v_1002323 => emitter_continuation_508(v_8, v_10, v_6, v_12, v_1002322, v_1002323)}
    case False{}:
      emitter_body_js_foreign(v_4, v_8, v_10, v_12)

def emitter_body_js_foreign_path(v_1: Bool, v_4: List<&2, String>, v_6: String, v_8: String, v_10: String, v_12: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  emitter_match_509(v_1, v_10, v_6, v_8, v_12, v_4)

def emitter_continuation_510(v_1: String, v_3: String, v_12: List<&2, AST.TopLevel>, v_7: EmitEnv, +v_1002338: String) -> EmitterProgress<String>:
  v_1002339 = {"\n" : String}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_decls{v_1, v_3, v_12, v_7}}, +v_1002340 => EmitterFinished{String.append(v_1002338, String.append(v_1002339, v_1002340))}}

def emitter_match_511(v_5: List<&2, AST.TopLevel>, +v_1: String, +v_3: String, +v_7: EmitEnv) -> EmitterProgress<String>:
  match v_5:
    case []:
      EmitterFinished{""}
    case +v_11 <> v_12:
      EmitterDirect{Bool, EmitterRequestGroup_5{EmitterRequest_js_decl{v_1, v_3, v_11, v_7}}, False{}, v_1002341 => emitter_body_js_decl(v_1, v_3, v_11, v_7), +v_1002338 => emitter_continuation_510(v_1, v_3, v_12, v_7, v_1002338)}

def emitter_body_js_decls(v_1: String, v_3: String, v_5: List<&2, AST.TopLevel>, v_7: EmitEnv) -> EmitterProgress<String>:
  emitter_match_511(v_5, v_1, v_3, v_7)

def emitter_body_alias_namespace(v_1: String, +v_3: String, v_6: Map<&2, String>) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_alias_namespace_base{String.eq(v_3, "Base"), v_1, v_3, v_6}}, +v_1002342 => EmitterFinished{v_1002342}}

def emitter_match_512(v_1: Bool, v_8: Map<&2, String>, v_3: String, v_5: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{""}
    case False{}:
      EmitterFinished{emitter_pure_alias_namespace_found(IndexLookup.find(String, v_8, Path.resolve(v_3, v_5)))}

def emitter_body_alias_namespace_base(v_1: Bool, v_3: String, v_5: String, v_8: Map<&2, String>) -> EmitterProgress<String>:
  emitter_match_512(v_1, v_8, v_3, v_5)

def emitter_body_alias_namespace_found(v_2: Maybe<&2, String>) -> EmitterProgress<String>:
  EmitterFinished{emitter_pure_alias_namespace_found(v_2)}

def emitter_match_513(v_1: List<&2, AST.ModuleImport>, +v_4: Map<&2, String>) -> EmitterProgress<List<&2, EmitAlias>>:
  match v_1:
    case []:
      EmitterFinished{[]}
    case AST.ModuleImport{v_13, +v_14, AST.SpanOf{v_15, _, _}} <> v_18:
      +v_20 = String.append(v_14, ".")
      v_1002343 = {v_14 : String}
      v_1002344 = {v_20 : String}
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_alias_namespace{v_15, v_13, v_4}}, False{}, v_1002347 => emitter_body_alias_namespace(v_15, v_13, v_4), +v_1002345 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_resolved_alias_entries{v_18, v_4}}, +v_1002346 => EmitterFinished{EmitAlias{v_1002343, v_1002344, v_1002345, String.length(v_20)} <> v_1002346}}}

def emitter_body_js_resolved_alias_entries(v_1: List<&2, AST.ModuleImport>, v_4: Map<&2, String>) -> EmitterProgress<List<&2, EmitAlias>>:
  emitter_match_513(v_1, v_4)

def emitter_body_js_resolved_aliases(+v_2: List<&2, EmitAlias>, v_4: Bool, v_7: Map<&2, String>) -> EmitterProgress<EmitAliases>:
  v_1002348 = {v_2 : List<&2, EmitAlias>}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_alias_source{v_2}}, +v_1002349 => EmitterFinished{EmitAliases{v_1002348, v_1002349, v_4, v_7}}}

def emitter_body_js_aliases(v_1: EmitAliases) -> EmitterProgress<String>:
  EmitterFinished{emitter_pure_js_aliases(v_1)}

def emitter_continuation_514(v_1002352: String, v_1002353: String, +v_1002354: String, v_13: List<&2, EmitAlias>) -> EmitterProgress<String>:
  v_19 = String.append(v_1002352, String.append(v_1002353, v_1002354))
  v_1002355 = {v_19 : String}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_alias_entries{v_13}}, +v_1002356 => EmitterFinished{String.append(v_1002355, String.append(v_1002356, "}"))}}

def emitter_continuation_515(v_1002350: String, +v_1002351: String, v_11: String, v_13: List<&2, EmitAlias>) -> EmitterProgress<String>:
  v_16 = String.append(v_1002350, v_1002351)
  v_1002352 = {v_16 : String}
  v_1002353 = {":" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_11}}, False{}, v_1002357 => emitter_body_js_quote(v_11), +v_1002354 => emitter_continuation_514(v_1002352, v_1002353, v_1002354, v_13)}

def emitter_body_js_alias_source(v_2: List<&2, EmitAlias>) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterFinished{"{}"}
    case EmitAlias{v_9, _, v_11, _} <> v_13:
      v_1002350 = {"{" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_9}}, False{}, v_1002358 => emitter_body_js_quote(v_9), +v_1002351 => emitter_continuation_515(v_1002350, v_1002351, v_11, v_13)}

def emitter_continuation_517(v_1002361: String, v_1002362: String, +v_1002363: String, v_13: List<&2, EmitAlias>) -> EmitterProgress<String>:
  v_19 = String.append(v_1002361, String.append(v_1002362, v_1002363))
  v_1002364 = {v_19 : String}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_alias_entries{v_13}}, +v_1002365 => EmitterFinished{String.append(v_1002364, v_1002365)}}

def emitter_continuation_518(v_1002359: String, +v_1002360: String, v_11: String, v_13: List<&2, EmitAlias>) -> EmitterProgress<String>:
  v_16 = String.append(v_1002359, v_1002360)
  v_1002361 = {v_16 : String}
  v_1002362 = {":" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_11}}, False{}, v_1002366 => emitter_body_js_quote(v_11), +v_1002363 => emitter_continuation_517(v_1002361, v_1002362, v_1002363, v_13)}

def emitter_body_js_alias_entries(v_2: List<&2, EmitAlias>) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterFinished{""}
    case EmitAlias{v_9, _, v_11, _} <> v_13:
      v_1002359 = {"," : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_9}}, False{}, v_1002367 => emitter_body_js_quote(v_9), +v_1002360 => emitter_continuation_518(v_1002359, v_1002360, v_11, v_13)}

def emitter_continuation_520(v_1002370: String, v_1002371: String, v_1002372: String, +v_1002373: String) -> EmitterProgress<String>:
  v_24 = String.append(v_1002370, String.append(v_1002371, String.append(v_1002372, v_1002373)))
  EmitterFinished{String.append(v_24, "}\n")}

def emitter_continuation_521(v_1002368: String, +v_1002369: String, +v_4: EmitAliases, +v_1: String, v_6: EmitCatalog, v_11: String, v_13: List<&2, AST.TopLevel>) -> EmitterProgress<String>:
  v_16 = String.append(v_1002368, v_1002369)
  v_19 = String.append(";const $aliases=", emitter_pure_js_aliases(v_4))
  v_21 = {EmitEnv{EmitScope{v_1, v_4, v_6}, [], [], [], 0n} : EmitEnv}
  v_1002370 = {v_16 : String}
  v_1002371 = {v_19 : String}
  v_1002372 = {";\n" : String}
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_decls{v_1, v_11, v_13, v_21}}, False{}, v_1002374 => emitter_body_js_decls(v_1, v_11, v_13, v_21), +v_1002373 => emitter_continuation_520(v_1002370, v_1002371, v_1002372, v_1002373)}

def emitter_match_522(v_2: AST.Module, +v_1: String, v_4: EmitAliases, v_6: EmitCatalog) -> EmitterProgress<String>:
  match v_2:
    case AST.Module{v_11, _, v_13}:
      v_1002368 = {"{const $scope=" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1002375 => emitter_body_js_quote(v_1), +v_1002369 => emitter_continuation_521(v_1002368, v_1002369, v_4, v_1, v_6, v_11, v_13)}

def emitter_body_js_module(v_1: String, v_2: AST.Module, v_4: EmitAliases, v_6: EmitCatalog) -> EmitterProgress<String>:
  emitter_match_522(v_2, v_1, v_4, v_6)

def emitter_body_js_modules(v_1: List<&2, Loader.LoadedModule>, +v_3: EmitCatalog) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_modules_at{v_1, v_3, emitter_pure_js_catalog_layouts(v_3)}}, +v_1002376 => EmitterFinished{v_1002376}}

def emitter_match_523(v_1: List<&2, Loader.LoadedModule>, v_6: List<&2, EmitModuleIndex>, +v_3: EmitCatalog) -> EmitterProgress<String>:
  match v_1, v_6:
    case Loader.LoadedModule{v_17, v_18} <> v_19, EmitModuleIndex{_, v_21, _, _, _} <> v_25:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_module{v_17, v_18, v_21, v_3}}, False{}, v_1002379 => emitter_body_js_module(v_17, v_18, v_21, v_3), +v_1002377 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_modules_at{v_19, v_3, v_25}}, +v_1002378 => EmitterFinished{String.append(v_1002377, v_1002378)}}}
    case _, _:
      EmitterFinished{""}

def emitter_body_js_modules_at(v_1: List<&2, Loader.LoadedModule>, v_3: EmitCatalog, v_6: List<&2, EmitModuleIndex>) -> EmitterProgress<String>:
  emitter_match_523(v_1, v_6, v_3)

def emitter_body_qualify(+v_1: String, v_3: String) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_qualify_result{String.eq(v_1, ""), v_1, v_3}}, +v_1002380 => EmitterFinished{v_1002380}}

def emitter_match_524(v_1: Bool, v_5: String, v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      EmitterFinished{v_5}
    case False{}:
      EmitterFinished{String.append(v_3, String.append(".", v_5))}

def emitter_body_qualify_result(v_1: Bool, v_3: String, v_5: String) -> EmitterProgress<String>:
  emitter_match_524(v_1, v_5, v_3)

def emitter_body_first_span(v_1: Maybe<&2, AST.SourceSpan>, v_3: Maybe<&2, AST.SourceSpan>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case Some{v_6}:
      EmitterFinished{Some{v_6}}
    case None{}:
      EmitterFinished{v_3}

def emitter_body_error_terms(v_1: List<&2, AST.SyntaxTerm>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_5}}, +v_1002381 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_terms{v_6}}, +v_1002382 => emitter_body_first_span(v_1002381, v_1002382)}}

def emitter_body_error_term(v_0: AST.SyntaxTerm) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_0:
    case AST.TermHole{_, v_5}:
      EmitterFinished{Some{v_5}}
    case AST.TermVar{_, _, _}:
      EmitterFinished{None{}}
    case AST.TermRef{_, _}:
      EmitterFinished{None{}}
    case AST.TermBang{v_18, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_18}}, +v_1002384 => EmitterFinished{v_1002384}}
    case AST.TermSub{_, v_26, v_27, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_26}}, +v_1002385 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_27}}, +v_1002386 => emitter_body_first_span(v_1002385, v_1002386)}}
    case AST.TermLet{_, _, _, v_41, v_42, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_terms{v_41}}, False{}, v_1002391 => emitter_body_error_terms(v_41), +v_1002388 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_42}}, +v_1002389 => emitter_body_first_span(v_1002388, v_1002389)}}
    case AST.TermType{v_49, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_49}}, +v_1002392 => EmitterFinished{v_1002392}}
    case AST.TermAnn{v_54, v_55, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_54}}, +v_1002393 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_55}}, +v_1002394 => emitter_body_first_span(v_1002393, v_1002394)}}
    case AST.TermTemplate{v_61, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_61}}, +v_1002396 => EmitterFinished{v_1002396}}
    case AST.TermQuant{}:
      EmitterFinished{None{}}
    case AST.TermQuantity{_, _}:
      EmitterFinished{None{}}
    case AST.TermMin{v_71, v_72, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_71}}, +v_1002397 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_72}}, +v_1002398 => emitter_body_first_span(v_1002397, v_1002398)}}
    case AST.TermAll{_, _, _, v_86, v_87, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_86}}, +v_1002400 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_87}}, +v_1002401 => emitter_body_first_span(v_1002400, v_1002401)}}
    case AST.TermLam{_, _, _, v_100, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_100}}, +v_1002403 => EmitterFinished{v_1002403}}
    case AST.TermApp{v_106, v_107, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_106}}, +v_1002404 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_107}}, +v_1002405 => emitter_body_first_span(v_1002404, v_1002405)}}
    case AST.TermAdt{_, v_117, _, _}:
      emitter_body_error_terms(v_117)
    case AST.TermCtr{_, v_125, _}:
      emitter_body_error_terms(v_125)
    case AST.TermString{_, _, _}:
      EmitterFinished{None{}}
    case AST.TermFill{v_137, v_138, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_137}}, +v_1002409 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_terms{v_138}}, False{}, v_1002412 => emitter_body_error_terms(v_138), +v_1002410 => emitter_body_first_span(v_1002409, v_1002410)}}
    case AST.TermPlus{v_146, v_147, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_146}}, +v_1002413 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_terms{v_147}}, False{}, v_1002416 => emitter_body_error_terms(v_147), +v_1002414 => emitter_body_first_span(v_1002413, v_1002414)}}
    case AST.TermMat{_, v_157, v_158, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_157}}, +v_1002417 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_158}}, +v_1002418 => emitter_body_first_span(v_1002417, v_1002418)}}
    case AST.TermAbsurd{_}:
      EmitterFinished{None{}}
    case AST.TermEqual{v_169, v_170, v_171, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_169}}, +v_1002420 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_170}}, +v_1002421 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_171}}, +v_1002422 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_first_span{v_1002421, v_1002422}}, False{}, v_1002425 => emitter_body_first_span(v_1002421, v_1002422), +v_1002423 => emitter_body_first_span(v_1002420, v_1002423)}}}}
    case AST.TermRefl{_}:
      EmitterFinished{None{}}
    case AST.TermRewrite{v_184, v_185, v_186, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_184}}, +v_1002426 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_185}}, +v_1002427 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_186}}, +v_1002428 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_first_span{v_1002427, v_1002428}}, False{}, v_1002431 => emitter_body_first_span(v_1002427, v_1002428), +v_1002429 => emitter_body_first_span(v_1002426, v_1002429)}}}}
    case AST.BodyMatch{v_196, v_197, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_terms{v_196}}, False{}, v_1002436 => emitter_body_error_terms(v_196), +v_1002432 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_terms{v_197}}, False{}, v_1002435 => emitter_body_error_terms(v_197), +v_1002433 => emitter_body_first_span(v_1002432, v_1002433)}}
    case AST.BodyCase{_, v_206, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_206}}, +v_1002437 => EmitterFinished{v_1002437}}
    case AST.BodyLocal{_, _, v_216, v_217, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_terms{v_216}}, False{}, v_1002441 => emitter_body_error_terms(v_216), +v_1002438 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_217}}, +v_1002439 => emitter_body_first_span(v_1002438, v_1002439)}}
    case AST.BodyReply{v_223, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_term{v_223}}, +v_1002442 => EmitterFinished{v_1002442}}

def emitter_body_error_optional_term(v_0: AST.OptionalTerm) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_0:
    case AST.NoTerm{}:
      EmitterFinished{None{}}
    case AST.SomeTerm{v_3}:
      emitter_body_error_term(v_3)

def emitter_body_error_def_body(v_0: AST.DefBody) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_0:
    case AST.DefTerm{v_3}:
      emitter_body_error_term(v_3)
    case AST.DefImports{_}:
      EmitterFinished{None{}}

def emitter_continuation_530(+v_1002447: Maybe<&2, AST.SourceSpan>, v_16: Maybe<&2, AST.SourceSpan>, v_19: Maybe<&2, AST.SourceSpan>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  v_22 = v_1002447
  v_1002448 = {v_16 : Maybe<&2, AST.SourceSpan>}
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_first_span{v_19, v_22}}, False{}, v_1002451 => emitter_body_first_span(v_19, v_22), +v_1002449 => emitter_body_first_span(v_1002448, v_1002449)}

def emitter_continuation_531(+v_1002446: Maybe<&2, AST.SourceSpan>, v_11: AST.DefBody, v_16: Maybe<&2, AST.SourceSpan>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  v_19 = v_1002446
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_def_body{v_11}}, False{}, v_1002452 => emitter_body_error_def_body(v_11), +v_1002447 => emitter_continuation_530(v_1002447, v_16, v_19)}

def emitter_continuation_532(+v_1002445: Maybe<&2, AST.SourceSpan>, v_9: List<&2, AST.TelescopeItem>, v_11: AST.DefBody) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  v_16 = v_1002445
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_binders{v_9}}, +v_1002446 => emitter_continuation_531(v_1002446, v_11, v_16)}

def emitter_body_error_decl(v_0: AST.TopLevel) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_0:
    case AST.DefTop{AST.Definition{_, v_9, v_10, v_11, _, v_13}}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_optional_term{v_10}}, False{}, v_1002453 => emitter_body_error_optional_term(v_10), +v_1002445 => emitter_continuation_532(v_1002445, v_9, v_11)}
    case AST.TypeTop{AST.TypeDecl{_, v_31, v_32, v_33, _}}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_term{v_32}}, False{}, v_1002460 => emitter_body_error_term(v_32), +v_1002454 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_binders{v_31}}, +v_1002455 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_constructors{v_33}}, +v_1002456 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_first_span{v_1002455, v_1002456}}, False{}, v_1002459 => emitter_body_first_span(v_1002455, v_1002456), +v_1002457 => emitter_body_first_span(v_1002454, v_1002457)}}}}
    case AST.LawTop{AST.LawDecl{_, v_45, v_46, _}}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_clauses{v_45}}, +v_1002461 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_term{v_46}}, False{}, v_1002464 => emitter_body_error_term(v_46), +v_1002462 => emitter_body_first_span(v_1002461, v_1002462)}}

def emitter_match_534(+v_5: AST.TelescopeItem, v_6: List<&2, AST.TelescopeItem>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_5:
    case AST.Binder{_, _, _, v_15, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_term{v_15}}, False{}, v_1002468 => emitter_body_error_term(v_15), +v_1002465 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_binders{v_6}}, +v_1002466 => emitter_body_first_span(v_1002465, v_1002466)}}
    case AST.TemplateBinder{_, _, v_26, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_term{v_26}}, False{}, v_1002472 => emitter_body_error_term(v_26), +v_1002469 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_binders{v_6}}, +v_1002470 => emitter_body_first_span(v_1002469, v_1002470)}}

def emitter_body_error_binders(v_1: List<&2, AST.TelescopeItem>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      emitter_match_534(v_5, v_6)

def emitter_match_536(+v_5: AST.ConstructorDecl, v_6: List<&2, AST.ConstructorDecl>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_5:
    case AST.Constructor{_, v_11, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_binders{v_11}}, False{}, v_1002476 => emitter_body_error_binders(v_11), +v_1002473 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_constructors{v_6}}, +v_1002474 => emitter_body_first_span(v_1002473, v_1002474)}}

def emitter_body_error_constructors(v_1: List<&2, AST.ConstructorDecl>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      emitter_match_536(v_5, v_6)

def emitter_body_error_condition(v_1: Maybe<&2, AST.SyntaxTerm>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_4}:
      emitter_body_error_term(v_4)

def emitter_continuation_539(v_21: Maybe<&2, AST.SourceSpan>, v_6: List<&2, AST.Clause>, +v_1002479: Maybe<&2, AST.SourceSpan>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  v_1002480 = {v_21 : Maybe<&2, AST.SourceSpan>}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_clauses{v_6}}, +v_1002481 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_first_span{v_1002480, v_1002481}}, False{}, v_1002484 => emitter_body_first_span(v_1002480, v_1002481), +v_1002482 => emitter_body_first_span(v_1002479, v_1002482)}}

def emitter_continuation_540(+v_1002478: Maybe<&2, AST.SourceSpan>, v_16: AST.SyntaxTerm, v_6: List<&2, AST.Clause>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  v_21 = v_1002478
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_term{v_16}}, False{}, v_1002485 => emitter_body_error_term(v_16), +v_1002479 => emitter_continuation_539(v_21, v_6, v_1002479)}

def emitter_match_541(+v_5: AST.Clause, v_6: List<&2, AST.Clause>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_5:
    case AST.ClauseFor{_, _, _, v_16, v_17, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_condition{v_17}}, False{}, v_1002486 => emitter_body_error_condition(v_17), +v_1002478 => emitter_continuation_540(v_1002478, v_16, v_6)}

def emitter_body_error_clauses(v_1: List<&2, AST.Clause>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      emitter_match_541(v_5, v_6)

def emitter_body_error_decls(v_1: List<&2, AST.TopLevel>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_decl{v_5}}, False{}, v_1002490 => emitter_body_error_decl(v_5), +v_1002487 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_decls{v_6}}, +v_1002488 => emitter_body_first_span(v_1002487, v_1002488)}}

def emitter_match_544(+v_5: Loader.LoadedModule, v_6: List<&2, Loader.LoadedModule>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_5:
    case Loader.LoadedModule{_, AST.Module{_, _, v_14}}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_decls{v_14}}, False{}, v_1002494 => emitter_body_error_decls(v_14), +v_1002491 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_error_modules{v_6}}, +v_1002492 => emitter_body_first_span(v_1002491, v_1002492)}}

def emitter_body_error_modules(v_1: List<&2, Loader.LoadedModule>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      emitter_match_544(v_5, v_6)

def emitter_body_template_terms(v_1: List<&2, AST.SyntaxTerm>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_5}}, +v_1002495 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_terms{v_6}}, +v_1002496 => emitter_body_first_span(v_1002495, v_1002496)}}

def emitter_body_template_term(v_0: AST.SyntaxTerm) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_0:
    case AST.TermTemplate{_, v_5}:
      EmitterFinished{Some{v_5}}
    case AST.TermVar{_, _, _}:
      EmitterFinished{None{}}
    case AST.TermRef{_, _}:
      EmitterFinished{None{}}
    case AST.TermBang{v_18, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_18}}, +v_1002498 => EmitterFinished{v_1002498}}
    case AST.TermSub{_, v_26, v_27, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_26}}, +v_1002499 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_27}}, +v_1002500 => emitter_body_first_span(v_1002499, v_1002500)}}
    case AST.TermLet{_, _, _, v_41, v_42, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_terms{v_41}}, False{}, v_1002505 => emitter_body_template_terms(v_41), +v_1002502 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_42}}, +v_1002503 => emitter_body_first_span(v_1002502, v_1002503)}}
    case AST.TermAnn{v_49, v_50, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_49}}, +v_1002506 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_50}}, +v_1002507 => emitter_body_first_span(v_1002506, v_1002507)}}
    case AST.TermType{v_57, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_57}}, +v_1002509 => EmitterFinished{v_1002509}}
    case AST.TermQuant{}:
      EmitterFinished{None{}}
    case AST.TermQuantity{_, _}:
      EmitterFinished{None{}}
    case AST.TermMin{v_67, v_68, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_67}}, +v_1002510 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_68}}, +v_1002511 => emitter_body_first_span(v_1002510, v_1002511)}}
    case AST.TermAll{_, _, _, v_82, v_83, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_82}}, +v_1002513 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_83}}, +v_1002514 => emitter_body_first_span(v_1002513, v_1002514)}}
    case AST.TermLam{_, _, _, v_96, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_96}}, +v_1002516 => EmitterFinished{v_1002516}}
    case AST.TermApp{v_102, v_103, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_102}}, +v_1002517 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_103}}, +v_1002518 => emitter_body_first_span(v_1002517, v_1002518)}}
    case AST.TermAdt{_, v_113, _, _}:
      emitter_body_template_terms(v_113)
    case AST.TermFill{v_120, v_121, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_120}}, +v_1002521 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_terms{v_121}}, False{}, v_1002524 => emitter_body_template_terms(v_121), +v_1002522 => emitter_body_first_span(v_1002521, v_1002522)}}
    case AST.TermPlus{v_129, v_130, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_129}}, +v_1002525 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_terms{v_130}}, False{}, v_1002528 => emitter_body_template_terms(v_130), +v_1002526 => emitter_body_first_span(v_1002525, v_1002526)}}
    case AST.TermCtr{_, v_139, _}:
      emitter_body_template_terms(v_139)
    case AST.TermString{_, _, _}:
      EmitterFinished{None{}}
    case AST.TermMat{_, v_153, v_154, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_153}}, +v_1002530 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_154}}, +v_1002531 => emitter_body_first_span(v_1002530, v_1002531)}}
    case AST.TermAbsurd{_}:
      EmitterFinished{None{}}
    case AST.TermEqual{v_165, v_166, v_167, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_165}}, +v_1002533 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_166}}, +v_1002534 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_167}}, +v_1002535 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_first_span{v_1002534, v_1002535}}, False{}, v_1002538 => emitter_body_first_span(v_1002534, v_1002535), +v_1002536 => emitter_body_first_span(v_1002533, v_1002536)}}}}
    case AST.TermRefl{_}:
      EmitterFinished{None{}}
    case AST.TermRewrite{v_180, v_181, v_182, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_180}}, +v_1002539 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_181}}, +v_1002540 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_182}}, +v_1002541 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_first_span{v_1002540, v_1002541}}, False{}, v_1002544 => emitter_body_first_span(v_1002540, v_1002541), +v_1002542 => emitter_body_first_span(v_1002539, v_1002542)}}}}
    case AST.TermHole{_, _}:
      EmitterFinished{None{}}
    case AST.BodyMatch{v_196, v_197, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_terms{v_196}}, False{}, v_1002549 => emitter_body_template_terms(v_196), +v_1002545 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_terms{v_197}}, False{}, v_1002548 => emitter_body_template_terms(v_197), +v_1002546 => emitter_body_first_span(v_1002545, v_1002546)}}
    case AST.BodyCase{_, v_206, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_206}}, +v_1002550 => EmitterFinished{v_1002550}}
    case AST.BodyLocal{_, _, v_216, v_217, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_terms{v_216}}, False{}, v_1002554 => emitter_body_template_terms(v_216), +v_1002551 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_217}}, +v_1002552 => emitter_body_first_span(v_1002551, v_1002552)}}
    case AST.BodyReply{v_223, _}:
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_term{v_223}}, +v_1002555 => EmitterFinished{v_1002555}}

def emitter_match_548(+v_5: AST.TelescopeItem, v_6: List<&2, AST.TelescopeItem>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_5:
    case AST.Binder{_, _, _, v_15, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_term{v_15}}, False{}, v_1002559 => emitter_body_template_term(v_15), +v_1002556 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_binders{v_6}}, +v_1002557 => emitter_body_first_span(v_1002556, v_1002557)}}
    case AST.TemplateBinder{_, _, _, v_27}:
      EmitterFinished{Some{v_27}}

def emitter_body_template_binders(v_1: List<&2, AST.TelescopeItem>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      emitter_match_548(v_5, v_6)

def emitter_match_550(+v_5: AST.ConstructorDecl, v_6: List<&2, AST.ConstructorDecl>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_5:
    case AST.Constructor{_, v_11, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_binders{v_11}}, False{}, v_1002563 => emitter_body_template_binders(v_11), +v_1002560 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_constructors{v_6}}, +v_1002561 => emitter_body_first_span(v_1002560, v_1002561)}}

def emitter_body_template_constructors(v_1: List<&2, AST.ConstructorDecl>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      emitter_match_550(v_5, v_6)

def emitter_body_template_condition(v_1: Maybe<&2, AST.SyntaxTerm>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case None{}:
      EmitterFinished{None{}}
    case Some{v_4}:
      emitter_body_template_term(v_4)

def emitter_continuation_553(v_21: Maybe<&2, AST.SourceSpan>, v_6: List<&2, AST.Clause>, +v_1002566: Maybe<&2, AST.SourceSpan>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  v_1002567 = {v_21 : Maybe<&2, AST.SourceSpan>}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_clauses{v_6}}, +v_1002568 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_first_span{v_1002567, v_1002568}}, False{}, v_1002571 => emitter_body_first_span(v_1002567, v_1002568), +v_1002569 => emitter_body_first_span(v_1002566, v_1002569)}}

def emitter_continuation_554(+v_1002565: Maybe<&2, AST.SourceSpan>, v_16: AST.SyntaxTerm, v_6: List<&2, AST.Clause>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  v_21 = v_1002565
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_term{v_16}}, False{}, v_1002572 => emitter_body_template_term(v_16), +v_1002566 => emitter_continuation_553(v_21, v_6, v_1002566)}

def emitter_match_555(+v_5: AST.Clause, v_6: List<&2, AST.Clause>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_5:
    case AST.ClauseFor{_, _, _, v_16, v_17, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_condition{v_17}}, False{}, v_1002573 => emitter_body_template_condition(v_17), +v_1002565 => emitter_continuation_554(v_1002565, v_16, v_6)}

def emitter_body_template_clauses(v_1: List<&2, AST.Clause>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      emitter_match_555(v_5, v_6)

def emitter_body_template_optional_term(v_0: AST.OptionalTerm) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_0:
    case AST.NoTerm{}:
      EmitterFinished{None{}}
    case AST.SomeTerm{v_3}:
      emitter_body_template_term(v_3)

def emitter_body_template_def_body(v_0: AST.DefBody) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_0:
    case AST.DefTerm{v_3}:
      emitter_body_template_term(v_3)
    case AST.DefImports{_}:
      EmitterFinished{None{}}

def emitter_continuation_559(+v_1002577: Maybe<&2, AST.SourceSpan>, v_16: Maybe<&2, AST.SourceSpan>, v_9: List<&2, AST.TelescopeItem>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  v_19 = v_1002577
  v_1002578 = {v_16 : Maybe<&2, AST.SourceSpan>}
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_binders{v_9}}, False{}, v_1002583 => emitter_body_template_binders(v_9), +v_1002579 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_first_span{v_1002579, v_19}}, False{}, v_1002582 => emitter_body_first_span(v_1002579, v_19), +v_1002580 => emitter_body_first_span(v_1002578, v_1002580)}}

def emitter_continuation_560(+v_1002576: Maybe<&2, AST.SourceSpan>, v_11: AST.DefBody, v_9: List<&2, AST.TelescopeItem>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  v_16 = v_1002576
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_def_body{v_11}}, False{}, v_1002584 => emitter_body_template_def_body(v_11), +v_1002577 => emitter_continuation_559(v_1002577, v_16, v_9)}

def emitter_body_template_decl(v_0: AST.TopLevel) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_0:
    case AST.DefTop{AST.Definition{_, v_9, v_10, v_11, _, _}}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_optional_term{v_10}}, False{}, v_1002585 => emitter_body_template_optional_term(v_10), +v_1002576 => emitter_continuation_560(v_1002576, v_11, v_9)}
    case AST.TypeTop{AST.TypeDecl{_, v_29, v_30, v_31, _}}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_term{v_30}}, False{}, v_1002594 => emitter_body_template_term(v_30), +v_1002586 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_binders{v_29}}, False{}, v_1002593 => emitter_body_template_binders(v_29), +v_1002587 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_constructors{v_31}}, False{}, v_1002592 => emitter_body_template_constructors(v_31), +v_1002588 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_first_span{v_1002587, v_1002588}}, False{}, v_1002591 => emitter_body_first_span(v_1002587, v_1002588), +v_1002589 => emitter_body_first_span(v_1002586, v_1002589)}}}}
    case AST.LawTop{AST.LawDecl{_, v_43, v_44, _}}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_clauses{v_43}}, False{}, v_1002599 => emitter_body_template_clauses(v_43), +v_1002595 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_term{v_44}}, False{}, v_1002598 => emitter_body_template_term(v_44), +v_1002596 => emitter_body_first_span(v_1002595, v_1002596)}}

def emitter_body_template_decls(v_1: List<&2, AST.TopLevel>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_decl{v_5}}, False{}, v_1002603 => emitter_body_template_decl(v_5), +v_1002600 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_decls{v_6}}, +v_1002601 => emitter_body_first_span(v_1002600, v_1002601)}}

def emitter_match_563(+v_5: Loader.LoadedModule, v_6: List<&2, Loader.LoadedModule>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_5:
    case Loader.LoadedModule{_, AST.Module{_, _, v_14}}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_decls{v_14}}, False{}, v_1002607 => emitter_body_template_decls(v_14), +v_1002604 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_template_modules{v_6}}, +v_1002605 => emitter_body_first_span(v_1002604, v_1002605)}}

def emitter_body_template_modules(v_1: List<&2, Loader.LoadedModule>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      emitter_match_563(v_5, v_6)

def emitter_body_has_js_import(v_2: List<&2, String>) -> EmitterProgress<Bool>:
  match v_2:
    case []:
      EmitterFinished{False{}}
    case +v_6 <> v_7:
      v_1002608 = {String.ends_with(v_6, ".js") : Bool}
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_has_js_import{v_7}}, +v_1002609 => EmitterFinished{Bool.or(v_1002608, v_1002609)}}

def emitter_match_566(v_11: AST.DefBody, v_13: AST.SourceSpan) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_11:
    case AST.DefImports{v_15}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_has_js_import{v_15}}, False{}, v_1002612 => emitter_body_has_js_import(v_15), +v_1002610 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_foreign_error_js{v_1002610, v_13}}, +v_1002611 => EmitterFinished{v_1002611}}}
    case AST.DefTerm{_}:
      EmitterFinished{None{}}

def emitter_body_foreign_error_decl(v_0: AST.TopLevel) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_0:
    case AST.DefTop{AST.Definition{_, _, _, v_11, _, v_13}}:
      emitter_match_566(v_11, v_13)
    case AST.TypeTop{_}:
      EmitterFinished{None{}}
    case AST.LawTop{_}:
      EmitterFinished{None{}}

def emitter_body_foreign_error_js(v_1: Bool, v_2: AST.SourceSpan) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case True{}:
      EmitterFinished{None{}}
    case False{}:
      EmitterFinished{Some{v_2}}

def emitter_body_foreign_error_decls(v_1: List<&2, AST.TopLevel>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_foreign_error_decl{v_5}}, False{}, v_1002616 => emitter_body_foreign_error_decl(v_5), +v_1002613 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_foreign_error_decls{v_6}}, +v_1002614 => emitter_body_first_span(v_1002613, v_1002614)}}

def emitter_match_570(+v_5: Loader.LoadedModule, v_6: List<&2, Loader.LoadedModule>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_5:
    case Loader.LoadedModule{_, AST.Module{_, _, v_14}}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_foreign_error_decls{v_14}}, False{}, v_1002620 => emitter_body_foreign_error_decls(v_14), +v_1002617 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_foreign_error_modules{v_6}}, +v_1002618 => emitter_body_first_span(v_1002617, v_1002618)}}

def emitter_body_foreign_error_modules(v_1: List<&2, Loader.LoadedModule>) -> EmitterProgress<Maybe<&2, AST.SourceSpan>>:
  match v_1:
    case []:
      EmitterFinished{None{}}
    case +v_5 <> v_6:
      emitter_match_570(v_5, v_6)

def emitter_body_js_runtime() -> EmitterProgress<String>:
  EmitterFinished{"const $D = Object.create(null);\nconst $BEND_TAIL = Symbol(\"bend.tail\");\nconst $td = 64;\nconst $TAIL_PENDING = Object.create(null), $tailArgs = Array(32);\nlet $tailFn, $tailCount=0, $tailUnary, $tailRest;\nfunction tail_many(f,a) { $tailFn=f; $tailCount=-2; $tailRest=a; return $TAIL_PENDING; }\nfunction tail_unary(f,x) { $tailFn=f; $tailCount=-1; $tailUnary=x; return $TAIL_PENDING; }\nfunction tail_named(f,n) { $tailFn=f; $tailCount=n; return $TAIL_PENDING; }\nfunction $run(f, xs) { let x=run_loop(f); for (const a of xs) x=run_loop(x(a)); return x; }\nfunction run_loop(x) { while (x===$TAIL_PENDING) { const f=$tailFn, count=$tailCount; $tailFn=undefined; $tailCount=0; if(count===-1) { const a=$tailUnary; $tailUnary=undefined; x=f(a,$BEND_TAIL); } else x=tail_dispatch(f,count); } return x; }\nfunction tail_dispatch(f,count) { switch(count) {\ncase -2: { const a=$tailRest; $tailRest=undefined; return f(...a); }\ncase 1: { const a0=$tailArgs[0]; $tailArgs[0]=undefined; return f(a0); }\ncase 2: { const a0=$tailArgs[0],a1=$tailArgs[1]; $tailArgs[0]=$tailArgs[1]=undefined; return f(a0,a1); }\ncase 3: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=undefined; return f(a0,a1,a2); }\ncase 4: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=undefined; return f(a0,a1,a2,a3); }\ncase 5: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=undefined; return f(a0,a1,a2,a3,a4); }\ncase 6: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=undefined; return f(a0,a1,a2,a3,a4,a5); }\ncase 7: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=undefined; return f(a0,a1,a2,a3,a4,a5,a6); }\ncase 8: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7); }\ncase 9: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8); }\ncase 10: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9); }\ncase 11: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10); }\ncase 12: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11); }\ncase 13: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12); }\ncase 14: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13); }\ncase 15: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14); }\ncase 16: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15); }\ncase 17: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16); }\ncase 18: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17); }\ncase 19: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18); }\ncase 20: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19); }\ncase 21: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20); }\ncase 22: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21); }\ncase 23: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22); }\ncase 24: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23); }\ncase 25: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24); }\ncase 26: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25); }\ncase 27: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26); }\ncase 28: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27); }\ncase 29: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28); }\ncase 30: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29); }\ncase 31: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30); }\ncase 32: { const a0=$tailArgs[0],a1=$tailArgs[1],a2=$tailArgs[2],a3=$tailArgs[3],a4=$tailArgs[4],a5=$tailArgs[5],a6=$tailArgs[6],a7=$tailArgs[7],a8=$tailArgs[8],a9=$tailArgs[9],a10=$tailArgs[10],a11=$tailArgs[11],a12=$tailArgs[12],a13=$tailArgs[13],a14=$tailArgs[14],a15=$tailArgs[15],a16=$tailArgs[16],a17=$tailArgs[17],a18=$tailArgs[18],a19=$tailArgs[19],a20=$tailArgs[20],a21=$tailArgs[21],a22=$tailArgs[22],a23=$tailArgs[23],a24=$tailArgs[24],a25=$tailArgs[25],a26=$tailArgs[26],a27=$tailArgs[27],a28=$tailArgs[28],a29=$tailArgs[29],a30=$tailArgs[30],a31=$tailArgs[31]; $tailArgs[0]=$tailArgs[1]=$tailArgs[2]=$tailArgs[3]=$tailArgs[4]=$tailArgs[5]=$tailArgs[6]=$tailArgs[7]=$tailArgs[8]=$tailArgs[9]=$tailArgs[10]=$tailArgs[11]=$tailArgs[12]=$tailArgs[13]=$tailArgs[14]=$tailArgs[15]=$tailArgs[16]=$tailArgs[17]=$tailArgs[18]=$tailArgs[19]=$tailArgs[20]=$tailArgs[21]=$tailArgs[22]=$tailArgs[23]=$tailArgs[24]=$tailArgs[25]=$tailArgs[26]=$tailArgs[27]=$tailArgs[28]=$tailArgs[29]=$tailArgs[30]=$tailArgs[31]=undefined; return f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31); }\ndefault: throw \"bend: invalid private tail frame\";\n} }\nfunction run_force(x,raw) { return raw===$BEND_TAIL?x:run_loop(x); }\nfunction run_many(f,a,d=$td) { return d<64?f(...a,d+1):tail_many(f,a); }\nfunction run_tail(f,x) { const j=f[$BEND_TAIL]; return j ? tail_unary(j,x) : f(x); }\nfunction run_clo(j) { j[$BEND_TAIL]=j; return j; }\nfunction nat_chk(x) { if(x>281474976710655) throw \"bend: a Nat past the largest immediate 2^48-1\"; return x; }\nfunction char_new(x) { if(x>0x10ffff || (x>=0xd800 && x<=0xdfff)) throw \"bend: \"+x+\" is not a Unicode scalar value\"; return String.fromCodePoint(x); }\nfunction cmp_new(a,b) { return {$:a<b?\"LT\":a===b?\"EQ\":\"GT\"}; }\nfunction word_to_u32(w) { let x=0; for(let i=0;w.$===\"WCon\";i++,w=w.tail) if(w.head)x|=1<<i; return x>>>0; }\nfunction u32_to_word(x) { let w={$:\"WNil\"}; for(let i=31;i>=0;i--) w={$:\"WCon\",head:!!((x>>>i)&1),tail:w}; return w; }\nfunction run_named1(f,a0,d) { return d<64?f(a0,d+1):($tailArgs[0]=a0,tail_named(f,1)); }\nfunction run_named2(f,a0,a1,d) { return d<64?f(a0,a1,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,tail_named(f,2)); }\nfunction run_named3(f,a0,a1,a2,d) { return d<64?f(a0,a1,a2,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,tail_named(f,3)); }\nfunction run_named4(f,a0,a1,a2,a3,d) { return d<64?f(a0,a1,a2,a3,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,tail_named(f,4)); }\nfunction run_named5(f,a0,a1,a2,a3,a4,d) { return d<64?f(a0,a1,a2,a3,a4,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,tail_named(f,5)); }\nfunction run_named6(f,a0,a1,a2,a3,a4,a5,d) { return d<64?f(a0,a1,a2,a3,a4,a5,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,tail_named(f,6)); }\nfunction run_named7(f,a0,a1,a2,a3,a4,a5,a6,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,tail_named(f,7)); }\nfunction run_named8(f,a0,a1,a2,a3,a4,a5,a6,a7,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,tail_named(f,8)); }\nfunction run_named9(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,tail_named(f,9)); }\nfunction run_named10(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,tail_named(f,10)); }\nfunction run_named11(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,tail_named(f,11)); }\nfunction run_named12(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,tail_named(f,12)); }\nfunction run_named13(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,tail_named(f,13)); }\nfunction run_named14(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,tail_named(f,14)); }\nfunction run_named15(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,tail_named(f,15)); }\nfunction run_named16(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,tail_named(f,16)); }\nfunction run_named17(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,tail_named(f,17)); }\nfunction run_named18(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,tail_named(f,18)); }\nfunction run_named19(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,tail_named(f,19)); }\nfunction run_named20(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,tail_named(f,20)); }\nfunction run_named21(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,tail_named(f,21)); }\nfunction run_named22(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,tail_named(f,22)); }\nfunction run_named23(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,tail_named(f,23)); }\nfunction run_named24(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,tail_named(f,24)); }\nfunction run_named25(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,tail_named(f,25)); }\nfunction run_named26(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,tail_named(f,26)); }\nfunction run_named27(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,tail_named(f,27)); }\nfunction run_named28(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,tail_named(f,28)); }\nfunction run_named29(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,tail_named(f,29)); }\nfunction run_named30(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,tail_named(f,30)); }\nfunction run_named31(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,tail_named(f,31)); }\nfunction run_named32(f,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d) { return d<64?f(a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,d+1):($tailArgs[0]=a0,$tailArgs[1]=a1,$tailArgs[2]=a2,$tailArgs[3]=a3,$tailArgs[4]=a4,$tailArgs[5]=a5,$tailArgs[6]=a6,$tailArgs[7]=a7,$tailArgs[8]=a8,$tailArgs[9]=a9,$tailArgs[10]=a10,$tailArgs[11]=a11,$tailArgs[12]=a12,$tailArgs[13]=a13,$tailArgs[14]=a14,$tailArgs[15]=a15,$tailArgs[16]=a16,$tailArgs[17]=a17,$tailArgs[18]=a18,$tailArgs[19]=a19,$tailArgs[20]=a20,$tailArgs[21]=a21,$tailArgs[22]=a22,$tailArgs[23]=a23,$tailArgs[24]=a24,$tailArgs[25]=a25,$tailArgs[26]=a26,$tailArgs[27]=a27,$tailArgs[28]=a28,$tailArgs[29]=a29,$tailArgs[30]=a30,$tailArgs[31]=a31,tail_named(f,32)); }\n"}

def emitter_body_js_runtime_extra() -> EmitterProgress<String>:
  EmitterFinished{"function f32_from_bits(x) { return new Float32Array(new Uint32Array([x]).buffer)[0]; }\nfunction f32_bits(x) { return new Uint32Array(new Float32Array([x]).buffer)[0]; }\nfunction tuple(a,b) { return {$:\"Tuple\",fst:a,snd:b}; }\nfunction f32_show(x) { if(x!==x) return \"nan\"; if(!Number.isFinite(x)||Object.is(x,-0)) return x<0?\"-inf\":x===0?\"-0\":\"inf\"; let s=\"x\"; for(let p=1;p<=9&&Math.fround(Number(s))!==x;p++) s=String(Number(x.toExponential(p-1))); return s; }\nfunction f32_read(s) { const re=/^\\s*[+-]?((\\d+\\.?\\d*|\\.\\d+)(e[+-]?\\d+)?|inf(inity)?|nan)$/i; const v=Number(s.replace(/inf\\w*/i,\"Infinity\")); return re.test(s)?{$:\"Some\",value:Math.fround(v)}:{$:\"None\"}; }\nfunction nat_divmod(a,b) { return b===0?tuple(0,a):tuple(Math.trunc(a/b),a%b); }\nfunction array_new(n,v) { if(n>31) throw \"bend: an array past the deepest block class 31\"; return Array(2 ** n).fill(v); }\nfunction array_node(a,b) { if(a.length!==b.length) throw \"bend: runtime fail-stop\"; return a.concat(b); }\n"}

def emitter_body_js_runtime_array() -> EmitterProgress<String>:
  EmitterFinished{"function array_swap(a,i,v) { const at=i%a.length, old=a[at]; a[at]=v; return tuple(a,old); }\nfunction $string_tail(s) { return s.slice(s.codePointAt(0)>0xFFFF?2:1); }\n"}

def emitter_body_js_runtime_foreign() -> EmitterProgress<String>:
  EmitterFinished{"function $curry(f,n,xs=[]) { return n===0 ? f(...xs) : x => $curry(f,n-1,[...xs,x]); }\nfunction io_emit(value) { return {$:\"Emit\",value}; }\nfunction $effect(f,need,n) { return $curry((...args)=>({$:\"$FFI\",run:f,need,args,kont:io_emit}),n); }\n"}

def emitter_body_js_runtime_namespace() -> EmitterProgress<String>:
  EmitterFinished{"function $key(k,s,a) { let p=null; for (const alias of Object.keys(a)) if(k.startsWith(alias+\".\") && (p===null || alias.length>p.length)) p=alias; const n=p===null?undefined:a[p]; return n===undefined?(s?s+\".\"+k:k):(n?n+\".\":\"\")+k.slice(p.length+1); }\nfunction $resolve(k,s,a) { const q=$key(k,s,a); return $D[Object.hasOwn($D,q)?q:k]; }\nconst $FIELDS=Object.create(null), $PRIMITIVES=Object.create(null), $TYPE=Object.create(null), $TYPEF=Object.create(null), $PARAMS=Object.create(null);\nfunction $ctr(k,x,s,a) { const q=$key(k,s,a), key=Object.hasOwn($FIELDS,q)?q:k, fs=$FIELDS[key]; if(!fs||fs.length!==x.length)throw \"bend: unresolved constructor layout\"; const v={$:key}; for(let i=0;i<fs.length;i++){const f=fs[i];if(f!==null){if(f===\"__proto__\")Object.defineProperty(v,f,{value:x[i],enumerable:true,writable:true,configurable:true});else v[f]=x[i];}} return v; }\nfunction $project(v,k,i,s,a) { const q=$key(k,s,a),fs=$FIELDS[q]||$FIELDS[k]; if(!fs)throw \"bend: unresolved constructor layout\"; for(const f of fs)if(f!==null&&i--===0)return v[f]; throw \"bend: constructor field count mismatch\"; }\n"}

def emitter_body_js_runtime_field_names(v_1: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_runtime_field_names_at{v_1, True{}}}, +v_1002621 => EmitterFinished{v_1002621}}

def emitter_continuation_572(+v_1002622: String, v_8: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  v_19 = v_1002622
  v_1002623 = {v_19 : String}
  v_1002624 = {"null" : String}
  EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_runtime_field_names_at{v_8, False{}}}, +v_1002625 => EmitterFinished{String.append(v_1002623, String.append(v_1002624, v_1002625))}}

def emitter_continuation_573(+v_1002627: String, v_27: String, v_8: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  v_33 = v_1002627
  v_1002628 = {v_33 : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_27}}, False{}, v_1002631 => emitter_body_js_quote(v_27), +v_1002629 => EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_runtime_field_names_at{v_8, False{}}}, +v_1002630 => EmitterFinished{String.append(v_1002628, String.append(v_1002629, v_1002630))}}}

def emitter_match_574(+v_7: AST.TelescopeItem, v_3: Bool, v_8: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  match v_7:
    case AST.Binder{AST.QZero{}, _, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_comma_prefix{v_3}}, False{}, v_1002626 => emitter_body_js_comma_prefix(v_3), +v_1002622 => emitter_continuation_572(v_1002622, v_8)}
    case AST.Binder{_, v_27, _, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_comma_prefix{v_3}}, False{}, v_1002632 => emitter_body_js_comma_prefix(v_3), +v_1002627 => emitter_continuation_573(v_1002627, v_27, v_8)}
    case AST.TemplateBinder{_, _, _, _}:
      v_1002633 = {"null" : String}
      EmitterPending{EmitterRequestGroup_6{EmitterRequest_js_runtime_field_names_at{v_8, False{}}}, +v_1002634 => EmitterFinished{String.append(v_1002633, v_1002634)}}

def emitter_body_js_runtime_field_names_at(v_1: List<&2, AST.TelescopeItem>, v_3: Bool) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{""}
    case +v_7 <> v_8:
      emitter_match_574(v_7, v_3, v_8)

def emitter_continuation_576(v_1002641: String, +v_1002642: String, v_1002643: String, +v_1002644: String, v_20: String) -> EmitterProgress<String>:
  v_27 = String.append(v_1002641, String.append(v_1002642, String.append(v_1002643, String.append(v_1002644, ";\n"))))
  EmitterFinished{String.append(v_20, v_27)}

def emitter_continuation_577(v_23: String, v_1002641: String, +v_1002642: String, v_20: String) -> EmitterProgress<String>:
  v_1002643 = {"] = " : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_23}}, False{}, v_1002645 => emitter_body_js_quote(v_23), +v_1002644 => emitter_continuation_576(v_1002641, v_1002642, v_1002643, v_1002644, v_20)}

def emitter_continuation_578(+v_1002640: String, v_16: String, v_20: String) -> EmitterProgress<String>:
  v_23 = v_1002640
  v_1002641 = {"$PRIMITIVES[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_16}}, False{}, v_1002646 => emitter_body_js_quote(v_16), +v_1002642 => emitter_continuation_577(v_23, v_1002641, v_1002642, v_20)}

def emitter_continuation_579(v_1002636: String, +v_1002637: String, v_1002638: String, +v_1002639: String, v_5: Bool, v_3: String, +v_16: String) -> EmitterProgress<String>:
  v_20 = String.append(v_1002636, String.append(v_1002637, String.append(v_1002638, String.append(v_1002639, "];\n"))))
  EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_constructor_native_origin{v_5, v_3, v_16}}, False{}, v_1002647 => emitter_body_js_constructor_native_origin(v_5, v_3, v_16), +v_1002640 => emitter_continuation_578(v_1002640, v_16, v_20)}

def emitter_continuation_580(v_12: List<&2, AST.TelescopeItem>, v_1002636: String, +v_1002637: String, v_5: Bool, v_3: String, v_16: String) -> EmitterProgress<String>:
  v_1002638 = {"] = [" : String}
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_runtime_field_names{v_12}}, False{}, v_1002648 => emitter_body_js_runtime_field_names(v_12), +v_1002639 => emitter_continuation_579(v_1002636, v_1002637, v_1002638, v_1002639, v_5, v_3, v_16)}

def emitter_continuation_581(+v_1002635: String, v_12: List<&2, AST.TelescopeItem>, v_5: Bool, v_3: String) -> EmitterProgress<String>:
  +v_16 = v_1002635
  v_1002636 = {"$FIELDS[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_16}}, False{}, v_1002649 => emitter_body_js_quote(v_16), +v_1002637 => emitter_continuation_580(v_12, v_1002636, v_1002637, v_5, v_3, v_16)}

def emitter_match_582(v_6: AST.ConstructorDecl, v_1: String, v_5: Bool, v_3: String) -> EmitterProgress<String>:
  match v_6:
    case AST.Constructor{v_11, v_12, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_qualify{v_1, v_11}}, False{}, v_1002650 => emitter_body_qualify(v_1, v_11), +v_1002635 => emitter_continuation_581(v_1002635, v_12, v_5, v_3)}

def emitter_body_js_constructor_fields_one(v_1: String, v_3: String, v_5: Bool, v_6: AST.ConstructorDecl) -> EmitterProgress<String>:
  emitter_match_582(v_6, v_1, v_5, v_3)

def emitter_match_583(v_7: List<&2, AST.ConstructorDecl>, +v_1: String, +v_3: String, +v_5: Bool) -> EmitterProgress<String>:
  match v_7:
    case []:
      EmitterFinished{""}
    case +v_11 <> v_12:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_constructor_fields_one{v_1, v_3, v_5, v_11}}, False{}, v_1002653 => emitter_body_js_constructor_fields_one(v_1, v_3, v_5, v_11), +v_1002651 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_constructor_fields_constructors{v_1, v_3, v_5, v_12}}, +v_1002652 => EmitterFinished{String.append(v_1002651, v_1002652)}}}

def emitter_body_js_constructor_fields_constructors(v_1: String, v_3: String, v_5: Bool, v_7: List<&2, AST.ConstructorDecl>) -> EmitterProgress<String>:
  emitter_match_583(v_7, v_1, v_3, v_5)

def emitter_match_584(v_4: AST.TopLevel, v_1: String, v_3: Bool) -> EmitterProgress<String>:
  match v_4:
    case AST.TypeTop{AST.TypeDecl{v_11, _, _, v_14, _}}:
      emitter_body_js_constructor_fields_constructors(v_1, v_11, v_3, v_14)
    case _:
      EmitterFinished{""}

def emitter_body_js_constructor_fields_decl(v_1: String, v_3: Bool, v_4: AST.TopLevel) -> EmitterProgress<String>:
  emitter_match_584(v_4, v_1, v_3)

def emitter_match_585(v_5: List<&2, AST.TopLevel>, +v_1: String, +v_3: Bool) -> EmitterProgress<String>:
  match v_5:
    case []:
      EmitterFinished{""}
    case +v_9 <> v_10:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_constructor_fields_decl{v_1, v_3, v_9}}, False{}, v_1002657 => emitter_body_js_constructor_fields_decl(v_1, v_3, v_9), +v_1002655 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_constructor_fields_decls{v_1, v_3, v_10}}, +v_1002656 => EmitterFinished{String.append(v_1002655, v_1002656)}}}

def emitter_body_js_constructor_fields_decls(v_1: String, v_3: Bool, v_5: List<&2, AST.TopLevel>) -> EmitterProgress<String>:
  emitter_match_585(v_5, v_1, v_3)

def emitter_body_js_constructor_fields_modules(+v_1: List<&2, Loader.LoadedModule>) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_constructor_fields_modules_at{v_1, v_1}}, +v_1002658 => EmitterFinished{v_1002658}}

def emitter_match_586(+v_7: Loader.LoadedModule, +v_3: List<&2, Loader.LoadedModule>, v_8: List<&2, Loader.LoadedModule>) -> EmitterProgress<String>:
  match v_7:
    case Loader.LoadedModule{v_13, AST.Module{v_14, _, v_16}}:
      v_1002659 = {v_13 : String}
      EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_base_source{v_14, v_3}}, False{}, v_1002664 => emitter_body_js_base_source(v_14, v_3), +v_1002660 => EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_constructor_fields_decls{v_1002659, v_1002660, v_16}}, False{}, v_1002663 => emitter_body_js_constructor_fields_decls(v_1002659, v_1002660, v_16), +v_1002661 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_constructor_fields_modules_at{v_8, v_3}}, +v_1002662 => EmitterFinished{String.append(v_1002661, v_1002662)}}}}

def emitter_body_js_constructor_fields_modules_at(v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{""}
    case +v_7 <> v_8:
      emitter_match_586(v_7, v_3, v_8)

def emitter_continuation_588(v_5: String, v_1002665: String, +v_1002666: String, v_1002667: String, +v_1002668: String, v_7: String) -> EmitterProgress<String>:
  v_1002669 = {"],s:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_5}}, False{}, v_1002671 => emitter_body_js_quote(v_5), +v_1002670 => EmitterFinished{String.append(v_1002665, String.append(v_1002666, String.append(v_1002667, String.append(v_1002668, String.append(v_1002669, String.append(v_1002670, String.append(",i:", String.append(v_7, "})"))))))))}}

def emitter_continuation_589(v_3: List<&2, AST.SyntaxTerm>, +v_5: String, +v_7: String, v_1002665: String, +v_1002666: String) -> EmitterProgress<String>:
  v_1002667 = {",a:[" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_args{v_3, v_5, v_7, True{}}}, +v_1002668 => emitter_continuation_588(v_5, v_1002665, v_1002666, v_1002667, v_1002668, v_7)}

def emitter_body_js_type_ref(v_1: String, v_3: List<&2, AST.SyntaxTerm>, v_5: String, v_7: String) -> EmitterProgress<String>:
  v_1002665 = {"({r:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1002672 => emitter_body_js_quote(v_1), +v_1002666 => emitter_continuation_589(v_3, v_5, v_7, v_1002665, v_1002666)}

def emitter_continuation_590(+v_1002673: String, +v_11: AST.SyntaxTerm, +v_3: String, +v_5: String, v_12: List<&2, AST.SyntaxTerm>) -> EmitterProgress<String>:
  v_15 = v_1002673
  v_1002674 = {v_15 : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_11, v_3, v_5}}, +v_1002675 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_args{v_12, v_3, v_5, False{}}}, +v_1002676 => EmitterFinished{String.append(v_1002674, String.append(v_1002675, v_1002676))}}}

def emitter_match_591(v_1: List<&2, AST.SyntaxTerm>, v_7: Bool, v_3: String, v_5: String) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{""}
    case +v_11 <> v_12:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_comma_prefix{v_7}}, False{}, v_1002677 => emitter_body_js_comma_prefix(v_7), +v_1002673 => emitter_continuation_590(v_1002673, v_11, v_3, v_5, v_12)}

def emitter_body_js_type_args(v_1: List<&2, AST.SyntaxTerm>, v_3: String, v_5: String, v_7: Bool) -> EmitterProgress<String>:
  emitter_match_591(v_1, v_7, v_3, v_5)

def emitter_continuation_592(+v_10: String, v_6: String, v_4: AST.SyntaxTerm, v_8: String, v_1002678: String, +v_1002679: String, v_1002680: String, +v_1002681: String, v_1002682: String, +v_1002683: String) -> EmitterProgress<String>:
  v_1002684 = {",i:" : String}
  v_1002685 = {v_10 : String}
  v_1002686 = {",f:" : String}
  v_1002687 = {v_6 : String}
  v_1002688 = {",h:" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_4, v_8, v_10}}, +v_1002689 => EmitterFinished{String.append(v_1002678, String.append(v_1002679, String.append(v_1002680, String.append(v_1002681, String.append(v_1002682, String.append(v_1002683, String.append(v_1002684, String.append(v_1002685, String.append(v_1002686, String.append(v_1002687, String.append(v_1002688, String.append(v_1002689, "})"))))))))))))}}

def emitter_continuation_593(+v_8: String, v_10: String, v_6: String, v_4: AST.SyntaxTerm, v_1002678: String, +v_1002679: String, v_1002680: String, +v_1002681: String) -> EmitterProgress<String>:
  v_1002682 = {"],s:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_8}}, False{}, v_1002690 => emitter_body_js_quote(v_8), +v_1002683 => emitter_continuation_592(v_10, v_6, v_4, v_8, v_1002678, v_1002679, v_1002680, v_1002681, v_1002682, v_1002683)}

def emitter_continuation_594(v_3: List<&2, AST.SyntaxTerm>, +v_8: String, +v_10: String, v_6: String, v_4: AST.SyntaxTerm, v_1002678: String, +v_1002679: String) -> EmitterProgress<String>:
  v_1002680 = {",a:[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_args{v_3, v_8, v_10, True{}}}, False{}, v_1002691 => emitter_body_js_type_args(v_3, v_8, v_10, True{}), +v_1002681 => emitter_continuation_593(v_8, v_10, v_6, v_4, v_1002678, v_1002679, v_1002680, v_1002681)}

def emitter_body_js_type_sugar_descriptor(v_1: String, v_3: List<&2, AST.SyntaxTerm>, v_4: AST.SyntaxTerm, v_6: String, v_8: String, v_10: String) -> EmitterProgress<String>:
  v_1002678 = {"({r:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1002692 => emitter_body_js_quote(v_1), +v_1002679 => emitter_continuation_594(v_3, v_8, v_10, v_6, v_4, v_1002678, v_1002679)}

def emitter_continuation_595(v_1002699: String, +v_1002700: String, v_2: List<&2, AST.SyntaxTerm>, v_6: String, v_8: String, v_4: String) -> EmitterProgress<String>:
  v_47 = String.append(v_1002699, String.append(v_1002700, ",a:["))
  v_1002701 = {v_47 : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_args{v_2, v_6, v_8, True{}}}, False{}, v_1002703 => emitter_body_js_type_args(v_2, v_6, v_8, True{}), +v_1002702 => EmitterFinished{String.append(v_1002701, String.append(v_1002702, String.append("],f:", String.append(v_4, "})"))))}}

def emitter_match_596(+v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>, v_4: String, +v_6: String, +v_8: String) -> EmitterProgress<String>:
  match v_0:
    case AST.TermAnn{v_13, _, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_sugar{v_13, v_2, v_4, v_6, v_8}}, +v_1002693 => EmitterFinished{v_1002693}}
    case AST.TermRef{v_19, _}:
      emitter_body_js_type_sugar_descriptor(v_19, v_2, v_0, v_4, v_6, v_8)
    case AST.TermAdt{v_26, v_27, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_sugar_descriptor{v_26, List.append(&2, AST.SyntaxTerm, v_27, v_2), v_0, v_4, v_6, v_8}}, False{}, v_1002696 => emitter_body_js_type_sugar_descriptor(v_26, List.append(&2, AST.SyntaxTerm, v_27, v_2), v_0, v_4, v_6, v_8), +v_1002695 => EmitterFinished{v_1002695}}
    case AST.TermApp{v_34, v_35, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_sugar{v_34, v_35 <> v_2, v_4, v_6, v_8}}, +v_1002697 => EmitterFinished{v_1002697}}
    case AST.TermBang{v_40, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_sugar{v_40, v_2, v_4, v_6, v_8}}, +v_1002698 => EmitterFinished{v_1002698}}
    case _:
      v_1002699 = {"({sugar:" : String}
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_0, v_6, v_8}}, +v_1002700 => emitter_continuation_595(v_1002699, v_1002700, v_2, v_6, v_8, v_4)}

def emitter_body_js_type_sugar(v_0: AST.SyntaxTerm, v_2: List<&2, AST.SyntaxTerm>, v_4: String, v_6: String, v_8: String) -> EmitterProgress<String>:
  emitter_match_596(v_0, v_2, v_4, v_6, v_8)

def emitter_continuation_597(v_1002718: String, +v_1002719: String, v_1002720: String, +v_1002721: String, v_91: AST.SyntaxTerm, v_2: String, v_4: String) -> EmitterProgress<String>:
  v_96 = String.append(v_1002718, String.append(v_1002719, String.append(v_1002720, v_1002721)))
  v_1002722 = {v_96 : String}
  v_1002723 = {",body:" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_91, v_2, v_4}}, +v_1002724 => EmitterFinished{String.append(v_1002722, String.append(v_1002723, String.append(v_1002724, "})")))}}

def emitter_continuation_598(v_87: AST.Quantity, v_1002718: String, +v_1002719: String, v_91: AST.SyntaxTerm, v_2: String, v_4: String) -> EmitterProgress<String>:
  v_1002720 = {",q:" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_quantity{v_87}}, +v_1002721 => emitter_continuation_597(v_1002718, v_1002719, v_1002720, v_1002721, v_91, v_2, v_4)}

def emitter_continuation_599(v_1002725: String, +v_1002726: String, v_103: Maybe<&2, AST.Quantity>) -> EmitterProgress<String>:
  v_110 = String.append(v_1002725, v_1002726)
  v_1002727 = {v_110 : String}
  v_1002728 = {",q:" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_optional_quantity{v_103}}, +v_1002729 => EmitterFinished{String.append(v_1002727, String.append(v_1002728, String.append(v_1002729, "})")))}}

def emitter_continuation_600(v_1002732: String, v_1002733: String, v_1002734: String, +v_1002735: String, v_132: AST.SyntaxTerm, v_2: String, v_4: String) -> EmitterProgress<String>:
  v_136 = String.append(v_1002732, String.append(v_1002733, String.append(v_1002734, v_1002735)))
  v_1002736 = {v_136 : String}
  v_1002737 = {",body:" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_132, v_2, v_4}}, +v_1002738 => EmitterFinished{String.append(v_1002736, String.append(v_1002737, String.append(v_1002738, "})")))}}

def emitter_continuation_601(+v_1002742: String, v_163: String, v_159: AST.SyntaxTerm, v_2: String, v_4: String) -> EmitterProgress<String>:
  v_166 = String.append(v_1002742, "],body:")
  v_1002743 = {v_163 : String}
  v_1002744 = {v_166 : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_159, v_2, v_4}}, +v_1002745 => EmitterFinished{String.append(v_1002743, String.append(v_1002744, String.append(v_1002745, "})")))}}

def emitter_continuation_602(v_1002740: String, +v_1002741: String, v_156: List<&2, AST.SyntaxPattern>, +v_2: String, +v_4: String, v_159: AST.SyntaxTerm) -> EmitterProgress<String>:
  v_163 = String.append(v_1002740, String.append(v_1002741, "],pat:["))
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_patterns_source{v_156, v_2, v_4, True{}}}, +v_1002742 => emitter_continuation_601(v_1002742, v_163, v_159, v_2, v_4)}

def emitter_continuation_603(v_1002747: String, +v_1002748: String, v_172: List<&2, AST.SyntaxTerm>, v_2: String, v_4: String) -> EmitterProgress<String>:
  v_176 = String.append(v_1002747, String.append(v_1002748, "],cases:["))
  v_1002749 = {v_176 : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_cases_source{v_172, v_2, v_4, True{}}}, +v_1002750 => EmitterFinished{String.append(v_1002749, String.append(v_1002750, "]})"))}}

def emitter_continuation_604(v_1002756: String, +v_1002757: String, v_1002758: String, +v_1002759: String, v_214: AST.SyntaxTerm, v_2: String, v_4: String) -> EmitterProgress<String>:
  v_219 = String.append(v_1002756, String.append(v_1002757, String.append(v_1002758, v_1002759)))
  v_1002760 = {v_219 : String}
  v_1002761 = {",ty:" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_214, v_2, v_4}}, +v_1002762 => EmitterFinished{String.append(v_1002760, String.append(v_1002761, String.append(v_1002762, "})")))}}

def emitter_continuation_605(v_213: AST.SyntaxTerm, +v_2: String, +v_4: String, v_1002756: String, +v_1002757: String, v_214: AST.SyntaxTerm) -> EmitterProgress<String>:
  v_1002758 = {",right:" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_213, v_2, v_4}}, +v_1002759 => emitter_continuation_604(v_1002756, v_1002757, v_1002758, v_1002759, v_214, v_2, v_4)}

def emitter_match_606(+v_0: AST.SyntaxTerm, +v_2: String, +v_4: String) -> EmitterProgress<String>:
  match v_0:
    case AST.TermFill{v_9, v_10, _}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_sugar{v_9, v_10, "1", v_2, v_4}}, False{}, v_1002705 => emitter_body_js_type_sugar(v_9, v_10, "1", v_2, v_4), +v_1002704 => EmitterFinished{v_1002704}}
    case AST.TermPlus{v_16, v_17, _}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_sugar{v_16, v_17, "2", v_2, v_4}}, False{}, v_1002707 => emitter_body_js_type_sugar(v_16, v_17, "2", v_2, v_4), +v_1002706 => EmitterFinished{v_1002706}}
    case AST.TermTemplate{_, _}:
      EmitterFinished{"(()=>{throw \"bend: unexpanded template\"})()"}
    case AST.TermBang{v_26, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_26, v_2, v_4}}, +v_1002708 => EmitterFinished{v_1002708}}
    case AST.TermAnn{v_31, _, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_31, v_2, v_4}}, +v_1002709 => EmitterFinished{v_1002709}}
    case AST.TermRef{v_37, _}:
      emitter_body_js_type_ref(v_37, [], v_2, v_4)
    case AST.TermAdt{v_44, v_45, _, _}:
      emitter_body_js_type_ref(v_44, v_45, v_2, v_4)
    case AST.TermApp{_, _, _}:
      EmitterDirect{Bool, EmitterRequestGroup_3{EmitterRequest_js_app_spine_at{v_0, []}}, False{}, v_1002714 => emitter_body_js_app_spine_at(v_0, []), v_1002712 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_application{v_1002712, v_2, v_4}}, +v_1002713 => EmitterFinished{v_1002713}}}
    case AST.TermVar{_, v_61, _}:
      EmitterFinished{String.append("({p:", String.append(Nat.show(v_61), "})"))}
    case AST.TermQuant{}:
      EmitterFinished{"({k:\"QK\"})"}
    case AST.TermQuantity{AST.QZero{}, _}:
      EmitterFinished{"({k:\"Q\",v:0})"}
    case AST.TermQuantity{AST.QOne{}, _}:
      EmitterFinished{"({k:\"Q\",v:1})"}
    case AST.TermQuantity{AST.QMany{}, _}:
      EmitterFinished{"({k:\"Q\",v:2})"}
    case AST.TermType{v_71, _}:
      v_1002715 = {"({kind:" : String}
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_71, v_2, v_4}}, +v_1002716 => EmitterFinished{String.append(v_1002715, String.append(v_1002716, "})"))}}
    case AST.TermMin{v_77, v_78, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_binary{"min", v_77, "right", v_78, v_2, v_4}}, +v_1002717 => EmitterFinished{v_1002717}}
    case AST.TermAll{v_87, _, _, v_90, v_91, _}:
      v_1002718 = {"({all:" : String}
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_90, v_2, v_4}}, +v_1002719 => emitter_continuation_598(v_87, v_1002718, v_1002719, v_91, v_2, v_4)}
    case AST.TermLam{v_103, _, _, v_106, _}:
      v_1002725 = {"({lam:" : String}
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_106, v_2, v_4}}, +v_1002726 => emitter_continuation_599(v_1002725, v_1002726, v_103)}
    case AST.TermCtr{v_115, v_116, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_constructor{v_115, v_116, v_2, v_4}}, +v_1002730 => EmitterFinished{v_1002730}}
    case AST.TermString{v_122, v_123, v_124}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{AST.string_desugar(v_122, v_123, v_124), v_2, v_4}}, +v_1002731 => EmitterFinished{v_1002731}}
    case AST.TermSub{v_130, v_131, v_132, _}:
      v_1002732 = {"({sub:" : String}
      v_1002733 = {Nat.show(v_130) : String}
      v_1002734 = {",value:" : String}
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_131, v_2, v_4}}, +v_1002735 => emitter_continuation_600(v_1002732, v_1002733, v_1002734, v_1002735, v_132, v_2, v_4)}
    case AST.TermLet{_, _, _, v_147, v_148, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_let{v_147, v_148, v_2, v_4}}, +v_1002739 => EmitterFinished{v_1002739}}
    case AST.BodyLocal{v_156, _, v_158, v_159, _}:
      v_1002740 = {"({local:[" : String}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_args{v_158, v_2, v_4, True{}}}, False{}, v_1002746 => emitter_body_js_type_args(v_158, v_2, v_4, True{}), +v_1002741 => emitter_continuation_602(v_1002740, v_1002741, v_156, v_2, v_4, v_159)}
    case AST.BodyMatch{v_171, v_172, _}:
      v_1002747 = {"({match:[" : String}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_args{v_171, v_2, v_4, True{}}}, False{}, v_1002751 => emitter_body_js_type_args(v_171, v_2, v_4, True{}), +v_1002748 => emitter_continuation_603(v_1002747, v_1002748, v_172, v_2, v_4)}
    case AST.BodyCase{_, v_182, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_182, v_2, v_4}}, +v_1002752 => EmitterFinished{v_1002752}}
    case AST.BodyReply{v_187, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_187, v_2, v_4}}, +v_1002753 => EmitterFinished{v_1002753}}
    case AST.TermMat{_, v_195, v_196, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_binary{"bind", v_196, "body", v_195, v_2, v_4}}, +v_1002754 => EmitterFinished{v_1002754}}
    case AST.TermRewrite{_, _, v_205, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_205, v_2, v_4}}, +v_1002755 => EmitterFinished{v_1002755}}
    case AST.TermEqual{v_212, v_213, v_214, _}:
      v_1002756 = {"({k:\"E\",left:" : String}
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_term{v_212, v_2, v_4}}, +v_1002757 => emitter_continuation_605(v_213, v_2, v_4, v_1002756, v_1002757, v_214)}
    case AST.TermRefl{_}:
      EmitterFinished{"({k:\"Refl\"})"}
    case AST.TermAbsurd{_}:
      EmitterFinished{"({fail:\"bend: runtime fail-stop\"})"}
    case AST.TermHole{v_227, _}:
      v_1002763 = {"({fail:" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{String.append("bend: unsolved hole ", v_227)}}, False{}, v_1002765 => emitter_body_js_quote(String.append("bend: unsolved hole ", v_227)), +v_1002764 => EmitterFinished{String.append(v_1002763, String.append(v_1002764, "})"))}}

def emitter_body_js_type_term(v_0: AST.SyntaxTerm, v_2: String, v_4: String) -> EmitterProgress<String>:
  emitter_match_606(v_0, v_2, v_4)

def emitter_body_js_type_quantity(v_0: AST.Quantity) -> EmitterProgress<String>:
  match v_0:
    case AST.QZero{}:
      EmitterFinished{"0"}
    case AST.QOne{}:
      EmitterFinished{"1"}
    case AST.QMany{}:
      EmitterFinished{"2"}

def emitter_body_js_type_optional_quantity(v_1: Maybe<&2, AST.Quantity>) -> EmitterProgress<String>:
  match v_1:
    case None{}:
      EmitterFinished{"null"}
    case Some{v_4}:
      emitter_body_js_type_quantity(v_4)

def emitter_continuation_609(v_1002767: String, v_1002768: String, v_1002769: String, +v_1002770: String, v_4: String, v_5: AST.SyntaxTerm, v_7: String, v_9: String) -> EmitterProgress<String>:
  v_13 = String.append(v_1002767, String.append(v_1002768, String.append(v_1002769, v_1002770)))
  v_1002771 = {v_13 : String}
  v_1002772 = {"," : String}
  v_1002773 = {v_4 : String}
  v_1002774 = {":" : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_term{v_5, v_7, v_9}}, False{}, v_1002776 => emitter_body_js_type_term(v_5, v_7, v_9), +v_1002775 => EmitterFinished{String.append(v_1002771, String.append(v_1002772, String.append(v_1002773, String.append(v_1002774, String.append(v_1002775, "})")))))}}

def emitter_body_js_type_binary(v_1: String, v_2: AST.SyntaxTerm, v_4: String, v_5: AST.SyntaxTerm, +v_7: String, +v_9: String) -> EmitterProgress<String>:
  v_1002767 = {"({" : String}
  v_1002768 = {v_1 : String}
  v_1002769 = {":" : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_term{v_2, v_7, v_9}}, False{}, v_1002777 => emitter_body_js_type_term(v_2, v_7, v_9), +v_1002770 => emitter_continuation_609(v_1002767, v_1002768, v_1002769, v_1002770, v_4, v_5, v_7, v_9)}

def emitter_continuation_610(v_5: String, v_1002778: String, +v_1002779: String, v_1002780: String, +v_1002781: String, v_7: String) -> EmitterProgress<String>:
  v_1002782 = {"],s:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_5}}, False{}, v_1002784 => emitter_body_js_quote(v_5), +v_1002783 => EmitterFinished{String.append(v_1002778, String.append(v_1002779, String.append(v_1002780, String.append(v_1002781, String.append(v_1002782, String.append(v_1002783, String.append(",i:", String.append(v_7, "})"))))))))}}

def emitter_continuation_611(v_3: List<&2, AST.SyntaxTerm>, +v_5: String, +v_7: String, v_1002778: String, +v_1002779: String) -> EmitterProgress<String>:
  v_1002780 = {",a:[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_args{v_3, v_5, v_7, True{}}}, False{}, v_1002785 => emitter_body_js_type_args(v_3, v_5, v_7, True{}), +v_1002781 => emitter_continuation_610(v_5, v_1002778, v_1002779, v_1002780, v_1002781, v_7)}

def emitter_body_js_type_constructor(v_1: String, v_3: List<&2, AST.SyntaxTerm>, v_5: String, v_7: String) -> EmitterProgress<String>:
  v_1002778 = {"({c:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_1}}, False{}, v_1002786 => emitter_body_js_quote(v_1), +v_1002779 => emitter_continuation_611(v_3, v_5, v_7, v_1002778, v_1002779)}

def emitter_match_612(v_1: Pair(AST.SyntaxTerm, List<&2, AST.SyntaxTerm>), +v_3: String, +v_5: String) -> EmitterProgress<String>:
  match v_1:
    case (AST.TermRef{v_10, _}, v_12):
      emitter_body_js_type_ref(v_10, v_12, v_3, v_5)
    case (AST.TermBang{AST.TermRef{v_18, _}, _}, v_21):
      emitter_body_js_type_ref(v_18, v_21, v_3, v_5)
    case (AST.TermAdt{v_28, v_29, _, _}, v_32):
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_ref{v_28, List.append(&2, AST.SyntaxTerm, v_29, v_32), v_3, v_5}}, False{}, v_1002790 => emitter_body_js_type_ref(v_28, List.append(&2, AST.SyntaxTerm, v_29, v_32), v_3, v_5), +v_1002789 => EmitterFinished{v_1002789}}
    case (v_36, v_37):
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_term{v_36, v_3, v_5}}, False{}, v_1002793 => emitter_body_js_type_term(v_36, v_3, v_5), +v_1002791 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_application_args{v_1002791, v_37, v_3, v_5}}, +v_1002792 => EmitterFinished{v_1002792}}}

def emitter_body_js_type_application(v_1: Pair(AST.SyntaxTerm, List<&2, AST.SyntaxTerm>), v_3: String, v_5: String) -> EmitterProgress<String>:
  emitter_match_612(v_1, v_3, v_5)

def emitter_continuation_613(v_1002794: String, v_1002795: String, v_1002796: String, +v_1002797: String, v_12: List<&2, AST.SyntaxTerm>, v_5: String, v_7: String) -> EmitterProgress<String>:
  v_15 = String.append(v_1002794, String.append(v_1002795, String.append(v_1002796, String.append(v_1002797, "})"))))
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_application_args{v_15, v_12, v_5, v_7}}, +v_1002798 => EmitterFinished{v_1002798}}

def emitter_match_614(v_3: List<&2, AST.SyntaxTerm>, v_1: String, +v_5: String, +v_7: String) -> EmitterProgress<String>:
  match v_3:
    case []:
      EmitterFinished{v_1}
    case +v_11 <> v_12:
      v_1002794 = {"({app:" : String}
      v_1002795 = {v_1 : String}
      v_1002796 = {",arg:" : String}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_term{v_11, v_5, v_7}}, False{}, v_1002799 => emitter_body_js_type_term(v_11, v_5, v_7), +v_1002797 => emitter_continuation_613(v_1002794, v_1002795, v_1002796, v_1002797, v_12, v_5, v_7)}

def emitter_body_js_type_application_args(v_1: String, v_3: List<&2, AST.SyntaxTerm>, v_5: String, v_7: String) -> EmitterProgress<String>:
  emitter_match_614(v_3, v_1, v_5, v_7)

def emitter_continuation_615(v_2: AST.SyntaxTerm, v_4: String, v_6: String, v_1002800: String, +v_1002801: String) -> EmitterProgress<String>:
  v_1002802 = {"],body:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_term{v_2, v_4, v_6}}, False{}, v_1002804 => emitter_body_js_type_term(v_2, v_4, v_6), +v_1002803 => EmitterFinished{String.append(v_1002800, String.append(v_1002801, String.append(v_1002802, String.append(v_1002803, "})"))))}}

def emitter_body_js_type_let(v_1: List<&2, AST.SyntaxTerm>, v_2: AST.SyntaxTerm, +v_4: String, +v_6: String) -> EmitterProgress<String>:
  v_1002800 = {"({let:[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_args{v_1, v_4, v_6, True{}}}, False{}, v_1002805 => emitter_body_js_type_args(v_1, v_4, v_6, True{}), +v_1002801 => emitter_continuation_615(v_2, v_4, v_6, v_1002800, v_1002801)}

def emitter_continuation_616(+v_1002806: String, +v_11: AST.SyntaxPattern, +v_3: String, +v_5: String, v_12: List<&2, AST.SyntaxPattern>) -> EmitterProgress<String>:
  v_15 = v_1002806
  v_1002807 = {v_15 : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_pattern_source{v_11, v_3, v_5}}, +v_1002808 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_patterns_source{v_12, v_3, v_5, False{}}}, +v_1002809 => EmitterFinished{String.append(v_1002807, String.append(v_1002808, v_1002809))}}}

def emitter_match_617(v_1: List<&2, AST.SyntaxPattern>, v_7: Bool, v_3: String, v_5: String) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{""}
    case +v_11 <> v_12:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_comma_prefix{v_7}}, False{}, v_1002810 => emitter_body_js_comma_prefix(v_7), +v_1002806 => emitter_continuation_616(v_1002806, v_11, v_3, v_5, v_12)}

def emitter_body_js_type_patterns_source(v_1: List<&2, AST.SyntaxPattern>, v_3: String, v_5: String, v_7: Bool) -> EmitterProgress<String>:
  emitter_match_617(v_1, v_7, v_3, v_5)

def emitter_continuation_618(v_1002814: String, +v_1002815: String, v_1002816: String, +v_1002817: String, +v_4: String, v_19: List<&2, AST.SyntaxPattern>, v_2: String) -> EmitterProgress<String>:
  v_24 = String.append(v_1002814, String.append(v_1002815, String.append(v_1002816, String.append(v_1002817, String.append(",i:", String.append(v_4, ",fields:["))))))
  v_1002818 = {v_24 : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_patterns_source{v_19, v_2, v_4, True{}}}, False{}, v_1002820 => emitter_body_js_type_patterns_source(v_19, v_2, v_4, True{}), +v_1002819 => EmitterFinished{String.append(v_1002818, String.append(v_1002819, "]})"))}}

def emitter_continuation_619(+v_2: String, v_1002814: String, +v_1002815: String, v_4: String, v_19: List<&2, AST.SyntaxPattern>) -> EmitterProgress<String>:
  v_1002816 = {",s:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_2}}, False{}, v_1002821 => emitter_body_js_quote(v_2), +v_1002817 => emitter_continuation_618(v_1002814, v_1002815, v_1002816, v_1002817, v_4, v_19, v_2)}

def emitter_body_js_type_pattern_source(v_0: AST.SyntaxPattern, v_2: String, v_4: String) -> EmitterProgress<String>:
  match v_0:
    case AST.PatternVar{_, _, v_12, _}:
      v_1002811 = {"({v:true,q:" : String}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_quantity{v_12}}, False{}, v_1002813 => emitter_body_js_type_quantity(v_12), +v_1002812 => EmitterFinished{String.append(v_1002811, String.append(v_1002812, "})"))}}
    case AST.PatternCtr{v_18, v_19, _}:
      v_1002814 = {"({c:" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_18}}, False{}, v_1002822 => emitter_body_js_quote(v_18), +v_1002815 => emitter_continuation_619(v_2, v_1002814, v_1002815, v_4, v_19)}

def emitter_continuation_621(v_1002826: String, +v_1002827: String, v_16: List<&2, AST.SyntaxTerm>, v_3: String, v_5: String) -> EmitterProgress<String>:
  v_23 = String.append(v_1002826, String.append(v_1002827, "})"))
  v_1002828 = {v_23 : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_cases_source{v_16, v_3, v_5, False{}}}, +v_1002829 => EmitterFinished{String.append(v_1002828, v_1002829)}}

def emitter_continuation_622(+v_1002823: String, v_1002824: String, +v_1002825: String, v_14: AST.SyntaxTerm, +v_3: String, +v_5: String, v_16: List<&2, AST.SyntaxTerm>) -> EmitterProgress<String>:
  v_20 = String.append(v_1002823, String.append(v_1002824, String.append(v_1002825, "],body:")))
  v_1002826 = {v_20 : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_term{v_14, v_3, v_5}}, False{}, v_1002830 => emitter_body_js_type_term(v_14, v_3, v_5), +v_1002827 => emitter_continuation_621(v_1002826, v_1002827, v_16, v_3, v_5)}

def emitter_continuation_623(v_13: List<&2, AST.SyntaxPattern>, +v_3: String, +v_5: String, +v_1002823: String, v_14: AST.SyntaxTerm, v_16: List<&2, AST.SyntaxTerm>) -> EmitterProgress<String>:
  v_1002824 = {"({pat:[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_patterns_source{v_13, v_3, v_5, True{}}}, False{}, v_1002831 => emitter_body_js_type_patterns_source(v_13, v_3, v_5, True{}), +v_1002825 => emitter_continuation_622(v_1002823, v_1002824, v_1002825, v_14, v_3, v_5, v_16)}

def emitter_match_624(v_1: List<&2, AST.SyntaxTerm>, v_7: Bool, v_3: String, v_5: String) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{""}
    case AST.BodyCase{v_13, v_14, _} <> v_16:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_comma_prefix{v_7}}, False{}, v_1002832 => emitter_body_js_comma_prefix(v_7), +v_1002823 => emitter_continuation_623(v_13, v_3, v_5, v_1002823, v_14, v_16)}
    case _ <> _:
      EmitterFinished{"(()=>{throw \"bend: malformed type match\"})()"}

def emitter_body_js_type_cases_source(v_1: List<&2, AST.SyntaxTerm>, v_3: String, v_5: String, v_7: Bool) -> EmitterProgress<String>:
  emitter_match_624(v_1, v_7, v_3, v_5)

def emitter_continuation_625(+v_1002833: String, v_21: AST.SyntaxTerm, +v_3: String, +v_5: String, v_12: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  v_25 = v_1002833
  v_1002834 = {v_25 : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_term{v_21, v_3, v_5}}, False{}, v_1002837 => emitter_body_js_type_term(v_21, v_3, v_5), +v_1002835 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_field_terms{v_12, v_3, v_5, False{}}}, +v_1002836 => EmitterFinished{String.append(v_1002834, String.append(v_1002835, v_1002836))}}}

def emitter_match_626(+v_11: AST.TelescopeItem, v_7: Bool, v_3: String, v_5: String, v_12: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  match v_11:
    case AST.Binder{_, _, _, v_21, _}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_comma_prefix{v_7}}, False{}, v_1002838 => emitter_body_js_comma_prefix(v_7), +v_1002833 => emitter_continuation_625(v_1002833, v_21, v_3, v_5, v_12)}
    case AST.TemplateBinder{_, _, _, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_field_terms{v_12, v_3, v_5, v_7}}, +v_1002839 => EmitterFinished{v_1002839}}

def emitter_match_627(v_1: List<&2, AST.TelescopeItem>, v_7: Bool, v_3: String, v_5: String) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{""}
    case +v_11 <> v_12:
      emitter_match_626(v_11, v_7, v_3, v_5, v_12)

def emitter_body_js_type_field_terms(v_1: List<&2, AST.TelescopeItem>, v_3: String, v_5: String, v_7: Bool) -> EmitterProgress<String>:
  emitter_match_627(v_1, v_7, v_3, v_5)

def emitter_continuation_628(v_1002844: String, +v_1002845: String, v_16: String, v_10: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  v_19 = String.append(v_1002844, String.append(v_1002845, "]}"))
  v_1002846 = {v_16 : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_field_quantities{v_10, True{}}}, +v_1002847 => EmitterFinished{String.append(v_1002846, String.append(v_1002847, v_19))}}

def emitter_continuation_629(+v_1002841: String, v_1002842: String, +v_1002843: String, +v_10: List<&2, AST.TelescopeItem>) -> EmitterProgress<String>:
  v_16 = String.append(v_1002841, String.append(v_1002842, String.append(v_1002843, "],q:[")))
  v_1002844 = {"],fields:[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_runtime_field_names{v_10}}, False{}, v_1002848 => emitter_body_js_runtime_field_names(v_10), +v_1002845 => emitter_continuation_628(v_1002844, v_1002845, v_16, v_10)}

def emitter_continuation_630(+v_10: List<&2, AST.TelescopeItem>, v_2: String, v_4: String, +v_1002841: String) -> EmitterProgress<String>:
  v_1002842 = {"{types:[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_field_terms{v_10, v_2, v_4, True{}}}, False{}, v_1002849 => emitter_body_js_type_field_terms(v_10, v_2, v_4, True{}), +v_1002843 => emitter_continuation_629(v_1002841, v_1002842, v_1002843, v_10)}

def emitter_match_631(v_0: AST.ConstructorDecl, +v_2: String, v_4: String) -> EmitterProgress<String>:
  match v_0:
    case AST.Constructor{v_9, v_10, _}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_qualify{v_2, v_9}}, False{}, v_1002851 => emitter_body_qualify(v_2, v_9), +v_1002840 => EmitterDirect{Bool, EmitterRequestGroup_4{EmitterRequest_js_object_key{v_1002840}}, False{}, v_1002850 => emitter_body_js_object_key(v_1002840), +v_1002841 => emitter_continuation_630(v_10, v_2, v_4, v_1002841)}}

def emitter_body_js_type_arm(v_0: AST.ConstructorDecl, v_2: String, v_4: String) -> EmitterProgress<String>:
  emitter_match_631(v_0, v_2, v_4)

def emitter_continuation_632(v_29: List<&2, AST.TelescopeItem>, +v_1002857: String) -> EmitterProgress<String>:
  v_1002858 = {"0" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_field_quantities{v_29, False{}}}, +v_1002859 => EmitterFinished{String.append(v_1002857, String.append(v_1002858, v_1002859))}}

def emitter_body_js_type_field_quantities(v_1: List<&2, AST.TelescopeItem>, v_3: Bool) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{""}
    case AST.Binder{v_11, _, _, _, _} <> v_16:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_comma_prefix{v_3}}, False{}, v_1002856 => emitter_body_js_comma_prefix(v_3), +v_1002852 => EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_quantity{v_11}}, False{}, v_1002855 => emitter_body_js_type_quantity(v_11), +v_1002853 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_field_quantities{v_16, False{}}}, +v_1002854 => EmitterFinished{String.append(v_1002852, String.append(v_1002853, v_1002854))}}}}
    case AST.TemplateBinder{_, _, _, _} <> v_29:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_comma_prefix{v_3}}, False{}, v_1002860 => emitter_body_js_comma_prefix(v_3), +v_1002857 => emitter_continuation_632(v_29, v_1002857)}

def emitter_continuation_634(+v_1002861: String, +v_11: AST.ConstructorDecl, +v_3: String, +v_5: String, v_12: List<&2, AST.ConstructorDecl>) -> EmitterProgress<String>:
  v_15 = v_1002861
  v_1002862 = {v_15 : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_arm{v_11, v_3, v_5}}, False{}, v_1002865 => emitter_body_js_type_arm(v_11, v_3, v_5), +v_1002863 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_arms{v_12, v_3, v_5, False{}}}, +v_1002864 => EmitterFinished{String.append(v_1002862, String.append(v_1002863, v_1002864))}}}

def emitter_match_635(v_1: List<&2, AST.ConstructorDecl>, v_7: Bool, v_3: String, v_5: String) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{""}
    case +v_11 <> v_12:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_comma_prefix{v_7}}, False{}, v_1002866 => emitter_body_js_comma_prefix(v_7), +v_1002861 => emitter_continuation_634(v_1002861, v_11, v_3, v_5, v_12)}

def emitter_body_js_type_arms(v_1: List<&2, AST.ConstructorDecl>, v_3: String, v_5: String, v_7: Bool) -> EmitterProgress<String>:
  emitter_match_635(v_1, v_7, v_3, v_5)

def emitter_continuation_636(v_1002877: String, +v_1002878: String, v_31: String, v_37: String) -> EmitterProgress<String>:
  v_40 = String.append(v_1002877, String.append(v_1002878, "}};\n"))
  EmitterFinished{String.append(v_31, String.append(v_37, v_40))}

def emitter_continuation_637(v_1002871: String, +v_1002872: String, v_1002873: String, +v_1002874: String, v_1002875: String, +v_1002876: String, v_16: List<&2, AST.ConstructorDecl>, v_1: String, v_20: String, v_31: String) -> EmitterProgress<String>:
  v_37 = String.append(v_1002871, String.append(v_1002872, String.append(v_1002873, String.append(v_1002874, String.append(v_1002875, v_1002876)))))
  v_1002877 = {",arms:{" : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_arms{v_16, v_1, v_20, True{}}}, False{}, v_1002879 => emitter_body_js_type_arms(v_16, v_1, v_20, True{}), +v_1002878 => emitter_continuation_636(v_1002877, v_1002878, v_31, v_37)}

def emitter_continuation_638(v_25: EmitEnv, v_13: String, v_1002871: String, +v_1002872: String, v_1002873: String, +v_1002874: String, v_16: List<&2, AST.ConstructorDecl>, v_1: String, v_20: String, v_31: String) -> EmitterProgress<String>:
  v_1002875 = {",native:" : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_native_marker{emitter_pure_js_base_origin(v_25), v_13}}, +v_1002876 => emitter_continuation_637(v_1002871, v_1002872, v_1002873, v_1002874, v_1002875, v_1002876, v_16, v_1, v_20, v_31)}

def emitter_continuation_639(+v_13: String, v_25: EmitEnv, v_1002871: String, +v_1002872: String, v_16: List<&2, AST.ConstructorDecl>, v_1: String, v_20: String, v_31: String) -> EmitterProgress<String>:
  v_1002873 = {"]={name:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_13}}, False{}, v_1002880 => emitter_body_js_quote(v_13), +v_1002874 => emitter_continuation_638(v_25, v_13, v_1002871, v_1002872, v_1002873, v_1002874, v_16, v_1, v_20, v_31)}

def emitter_continuation_640(v_1002869: String, +v_1002870: String, v_28: Nat, v_14: List<&2, AST.TelescopeItem>, v_23: String, v_13: String, v_25: EmitEnv, v_16: List<&2, AST.ConstructorDecl>, v_1: String, v_20: String) -> EmitterProgress<String>:
  v_31 = String.append(v_1002869, String.append(v_1002870, String.append("]={q:", String.append(Nat.show(v_28), String.append(",n:", String.append(Nat.show(List.length(&2, AST.TelescopeItem, v_14)), "};\n"))))))
  v_1002871 = {"$TYPE[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_23}}, False{}, v_1002881 => emitter_body_js_quote(v_23), +v_1002872 => emitter_continuation_639(v_13, v_25, v_1002871, v_1002872, v_16, v_1, v_20, v_31)}

def emitter_continuation_641(+v_1002868: Nat, +v_23: String, v_14: List<&2, AST.TelescopeItem>, v_13: String, v_25: EmitEnv, v_16: List<&2, AST.ConstructorDecl>, v_1: String, v_20: String) -> EmitterProgress<String>:
  v_28 = v_1002868
  v_1002869 = {"$PARAMS[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_23}}, False{}, v_1002882 => emitter_body_js_quote(v_23), +v_1002870 => emitter_continuation_640(v_1002869, v_1002870, v_28, v_14, v_23, v_13, v_25, v_16, v_1, v_20)}

def emitter_continuation_642(+v_1002867: String, +v_1: String, v_3: EmitAliases, v_6: EmitCatalog, +v_14: List<&2, AST.TelescopeItem>, v_13: String, v_16: List<&2, AST.ConstructorDecl>, v_20: String) -> EmitterProgress<String>:
  v_23 = v_1002867
  +v_25 = {EmitEnv{EmitScope{v_1, v_3, v_6}, [], [], [], 0n} : EmitEnv}
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_family_quant_prefix{v_14, v_25}}, False{}, v_1002883 => emitter_body_js_family_quant_prefix(v_14, v_25), +v_1002868 => emitter_continuation_641(v_1002868, v_23, v_14, v_13, v_25, v_16, v_1, v_20)}

def emitter_match_643(v_4: AST.TopLevel, +v_3: EmitAliases, +v_1: String, v_6: EmitCatalog) -> EmitterProgress<String>:
  match v_4:
    case AST.TypeTop{AST.TypeDecl{+v_13, v_14, _, v_16, _}}:
      v_20 = emitter_pure_js_aliases(v_3)
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_qualify{v_1, v_13}}, False{}, v_1002884 => emitter_body_qualify(v_1, v_13), +v_1002867 => emitter_continuation_642(v_1002867, v_1, v_3, v_6, v_14, v_13, v_16, v_20)}
    case _:
      EmitterFinished{""}

def emitter_body_js_type_decl(v_1: String, v_3: EmitAliases, v_4: AST.TopLevel, v_6: EmitCatalog) -> EmitterProgress<String>:
  emitter_match_643(v_4, v_3, v_1, v_6)

def emitter_body_js_type_native_marker(v_1: Bool, v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      emitter_body_js_quote(v_3)
    case False{}:
      EmitterFinished{"null"}

def emitter_match_645(v_5: List<&2, AST.TopLevel>, +v_1: String, +v_3: EmitAliases, +v_7: EmitCatalog) -> EmitterProgress<String>:
  match v_5:
    case []:
      EmitterFinished{""}
    case +v_11 <> v_12:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_decl{v_1, v_3, v_11, v_7}}, False{}, v_1002888 => emitter_body_js_type_decl(v_1, v_3, v_11, v_7), +v_1002886 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_decls{v_1, v_3, v_12, v_7}}, +v_1002887 => EmitterFinished{String.append(v_1002886, v_1002887)}}}

def emitter_body_js_type_decls(v_1: String, v_3: EmitAliases, v_5: List<&2, AST.TopLevel>, v_7: EmitCatalog) -> EmitterProgress<String>:
  emitter_match_645(v_5, v_1, v_3, v_7)

def emitter_body_js_type_modules(+v_1: List<&2, Loader.LoadedModule>, +v_3: EmitCatalog) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_modules{v_1, EmitTypeNeeded{[], MTip{}}, v_3}}, +v_1002889 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_modules_needed{v_1002889, v_1, v_3}}, +v_1002890 => EmitterFinished{v_1002890}}}

def emitter_match_646(v_1: EmitTypeNeeded, v_3: List<&2, Loader.LoadedModule>, +v_5: EmitCatalog) -> EmitterProgress<String>:
  match v_1:
    case EmitTypeNeeded{v_9, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_modules_at{v_3, v_5, emitter_pure_js_catalog_layouts(v_5)}}, +v_1002891 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_function_sources{v_9}}, +v_1002892 => EmitterFinished{String.append(v_1002891, v_1002892)}}}

def emitter_body_js_type_modules_needed(v_1: EmitTypeNeeded, v_3: List<&2, Loader.LoadedModule>, v_5: EmitCatalog) -> EmitterProgress<String>:
  emitter_match_646(v_1, v_3, v_5)

def emitter_match_647(v_1: List<&2, Loader.LoadedModule>, v_6: List<&2, EmitModuleIndex>, +v_3: EmitCatalog) -> EmitterProgress<String>:
  match v_1, v_6:
    case Loader.LoadedModule{v_19, AST.Module{_, _, v_22}} <> v_23, EmitModuleIndex{_, v_25, _, _, _} <> v_29:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_decls{v_19, v_25, v_22, v_3}}, False{}, v_1002895 => emitter_body_js_type_decls(v_19, v_25, v_22, v_3), +v_1002893 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_modules_at{v_23, v_3, v_29}}, +v_1002894 => EmitterFinished{String.append(v_1002893, v_1002894)}}}
    case _, _:
      EmitterFinished{""}

def emitter_body_js_type_modules_at(v_1: List<&2, Loader.LoadedModule>, v_3: EmitCatalog, v_6: List<&2, EmitModuleIndex>) -> EmitterProgress<String>:
  emitter_match_647(v_1, v_6, v_3)

def emitter_body_js_type_needed_ref(v_1: String, v_3: EmitEnv, v_5: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_global{v_1, v_3}}, False{}, v_1002898 => emitter_body_js_global(v_1, v_3), +v_1002896 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_found{v_1002896, v_5}}, +v_1002897 => EmitterFinished{v_1002897}}}

def emitter_match_648(+v_4: EmitTypeNeeded, +v_16: String, v_17: List<&2, AST.TelescopeItem>, v_18: AST.SyntaxTerm, v_7: EmitClosure) -> EmitterProgress<EmitTypeNeeded>:
  match v_4:
    case EmitTypeNeeded{_, v_27}:
      v_1002899 = {IndexLookup.find(Bool, v_27, v_16) : Maybe<&2, Bool>}
      v_1002900 = {v_16 : String}
      v_1002901 = {v_17 : List<&2, AST.TelescopeItem>}
      v_1002902 = {v_18 : AST.SyntaxTerm}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_closure_env{v_7}}, False{}, v_1002905 => emitter_body_js_closure_env(v_7), +v_1002903 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_definition{v_1002899, v_1002900, v_1002901, v_1002902, v_1002903, v_4}}, +v_1002904 => EmitterFinished{v_1002904}}}

def emitter_match_649(+v_7: EmitClosure, +v_4: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  match v_7:
    case EmitDefinition{v_16, v_17, v_18, _, _, _, _, _}:
      emitter_match_648(v_4, v_16, v_17, v_18, v_7)
    case _:
      EmitterFinished{v_4}

def emitter_body_js_type_needed_found(v_2: Maybe<&2, EmitClosure>, +v_4: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  match v_2:
    case Some{v_7}:
      emitter_match_649(v_7, v_4)
    case None{}:
      EmitterFinished{v_4}

def emitter_match_651(v_11: EmitTypeNeeded, +v_7: AST.SyntaxTerm, +v_9: EmitEnv, +v_4: String, v_6: List<&2, AST.TelescopeItem>) -> EmitterProgress<EmitTypeNeeded>:
  match v_11:
    case EmitTypeNeeded{v_17, v_18}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_7, v_9, EmitTypeNeeded{EmitTypeDefinition{v_4, v_6, v_7, v_9} <> v_17, Map.set(&2, Bool, v_18, v_4, True{})}}}, +v_1002906 => EmitterFinished{v_1002906}}

def emitter_match_652(v_2: Maybe<&2, Bool>, v_11: EmitTypeNeeded, v_7: AST.SyntaxTerm, v_9: EmitEnv, v_4: String, v_6: List<&2, AST.TelescopeItem>) -> EmitterProgress<EmitTypeNeeded>:
  match v_2:
    case Some{_}:
      EmitterFinished{v_11}
    case None{}:
      emitter_match_651(v_11, v_7, v_9, v_4, v_6)

def emitter_body_js_type_needed_definition(v_2: Maybe<&2, Bool>, v_4: String, v_6: List<&2, AST.TelescopeItem>, v_7: AST.SyntaxTerm, v_9: EmitEnv, v_11: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  emitter_match_652(v_2, v_11, v_7, v_9, v_4, v_6)

def emitter_match_653(v_1: List<&2, AST.SyntaxTerm>, v_5: EmitTypeNeeded, +v_3: EmitEnv) -> EmitterProgress<EmitTypeNeeded>:
  match v_1:
    case []:
      EmitterFinished{v_5}
    case +v_9 <> v_10:
      v_1002907 = {v_10 : List<&2, AST.SyntaxTerm>}
      v_1002908 = {v_3 : EmitEnv}
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_9, v_3, v_5}}, +v_1002909 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{v_1002907, v_1002908, v_1002909}}, +v_1002910 => EmitterFinished{v_1002910}}}

def emitter_body_js_type_needed_terms(v_1: List<&2, AST.SyntaxTerm>, v_3: EmitEnv, v_5: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  emitter_match_653(v_1, v_5, v_3)

def emitter_match_654(v_0: AST.SyntaxTerm, +v_2: EmitEnv, v_4: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  match v_0:
    case AST.TermRef{v_8, _}:
      emitter_body_js_type_needed_ref(v_8, v_2, v_4)
    case AST.TermBang{v_13, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_13, v_2, v_4}}, +v_1002912 => EmitterFinished{v_1002912}}
    case AST.TermSub{_, v_21, v_22, _}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{[v_21, v_22], v_2, v_4}}, False{}, v_1002914 => emitter_body_js_type_needed_terms([v_21, v_22], v_2, v_4), +v_1002913 => EmitterFinished{v_1002913}}
    case AST.TermLet{_, _, _, v_34, v_35, _}:
      v_1002915 = {v_35 : AST.SyntaxTerm}
      v_1002916 = {v_2 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{v_34, v_2, v_4}}, False{}, v_1002919 => emitter_body_js_type_needed_terms(v_34, v_2, v_4), +v_1002917 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_1002915, v_1002916, v_1002917}}, +v_1002918 => EmitterFinished{v_1002918}}}
    case AST.TermAnn{v_42, v_43, _}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{[v_42, v_43], v_2, v_4}}, False{}, v_1002921 => emitter_body_js_type_needed_terms([v_42, v_43], v_2, v_4), +v_1002920 => EmitterFinished{v_1002920}}
    case AST.TermType{v_48, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_48, v_2, v_4}}, +v_1002922 => EmitterFinished{v_1002922}}
    case AST.TermMin{v_54, v_55, _}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{[v_54, v_55], v_2, v_4}}, False{}, v_1002924 => emitter_body_js_type_needed_terms([v_54, v_55], v_2, v_4), +v_1002923 => EmitterFinished{v_1002923}}
    case AST.TermAll{_, _, _, v_67, v_68, _}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{[v_67, v_68], v_2, v_4}}, False{}, v_1002926 => emitter_body_js_type_needed_terms([v_67, v_68], v_2, v_4), +v_1002925 => EmitterFinished{v_1002925}}
    case AST.TermLam{_, _, _, v_79, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_79, v_2, v_4}}, +v_1002927 => EmitterFinished{v_1002927}}
    case AST.TermApp{v_85, v_86, _}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{[v_85, v_86], v_2, v_4}}, False{}, v_1002929 => emitter_body_js_type_needed_terms([v_85, v_86], v_2, v_4), +v_1002928 => EmitterFinished{v_1002928}}
    case AST.TermAdt{_, v_94, _, _}:
      emitter_body_js_type_needed_terms(v_94, v_2, v_4)
    case AST.TermFill{v_101, v_102, _}:
      v_1002931 = {v_101 : AST.SyntaxTerm}
      v_1002932 = {v_2 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{v_102, v_2, v_4}}, False{}, v_1002935 => emitter_body_js_type_needed_terms(v_102, v_2, v_4), +v_1002933 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_1002931, v_1002932, v_1002933}}, +v_1002934 => EmitterFinished{v_1002934}}}
    case AST.TermPlus{v_109, v_110, _}:
      v_1002936 = {v_109 : AST.SyntaxTerm}
      v_1002937 = {v_2 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{v_110, v_2, v_4}}, False{}, v_1002940 => emitter_body_js_type_needed_terms(v_110, v_2, v_4), +v_1002938 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_1002936, v_1002937, v_1002938}}, +v_1002939 => EmitterFinished{v_1002939}}}
    case AST.TermCtr{_, v_118, _}:
      emitter_body_js_type_needed_terms(v_118, v_2, v_4)
    case AST.TermString{_, _, _}:
      EmitterFinished{v_4}
    case AST.TermMat{_, v_132, v_133, _}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{[v_132, v_133], v_2, v_4}}, False{}, v_1002943 => emitter_body_js_type_needed_terms([v_132, v_133], v_2, v_4), +v_1002942 => EmitterFinished{v_1002942}}
    case AST.TermEqual{_, _, v_142, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_142, v_2, v_4}}, +v_1002944 => EmitterFinished{v_1002944}}
    case AST.TermRewrite{_, _, v_151, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_151, v_2, v_4}}, +v_1002945 => EmitterFinished{v_1002945}}
    case AST.BodyMatch{v_157, v_158, _}:
      v_1002946 = {v_158 : List<&2, AST.SyntaxTerm>}
      v_1002947 = {v_2 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{v_157, v_2, v_4}}, False{}, v_1002950 => emitter_body_js_type_needed_terms(v_157, v_2, v_4), +v_1002948 => emitter_body_js_type_needed_terms(v_1002946, v_1002947, v_1002948)}
    case AST.BodyCase{_, v_166, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_166, v_2, v_4}}, +v_1002951 => EmitterFinished{v_1002951}}
    case AST.BodyLocal{_, _, v_176, v_177, _}:
      v_1002952 = {v_177 : AST.SyntaxTerm}
      v_1002953 = {v_2 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_terms{v_176, v_2, v_4}}, False{}, v_1002956 => emitter_body_js_type_needed_terms(v_176, v_2, v_4), +v_1002954 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_1002952, v_1002953, v_1002954}}, +v_1002955 => EmitterFinished{v_1002955}}}
    case AST.BodyReply{v_183, _}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_183, v_2, v_4}}, +v_1002957 => EmitterFinished{v_1002957}}
    case _:
      EmitterFinished{v_4}

def emitter_body_js_type_needed_term(v_0: AST.SyntaxTerm, v_2: EmitEnv, v_4: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  emitter_match_654(v_0, v_2, v_4)

def emitter_match_655(v_1: List<&2, AST.TelescopeItem>, v_5: EmitTypeNeeded, +v_3: EmitEnv) -> EmitterProgress<EmitTypeNeeded>:
  match v_1:
    case []:
      EmitterFinished{v_5}
    case AST.Binder{_, _, _, v_16, _} <> v_18:
      v_1002958 = {v_18 : List<&2, AST.TelescopeItem>}
      v_1002959 = {v_3 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_16, v_3, v_5}}, False{}, v_1002962 => emitter_body_js_type_needed_term(v_16, v_3, v_5), +v_1002960 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_binders{v_1002958, v_1002959, v_1002960}}, +v_1002961 => EmitterFinished{v_1002961}}}
    case AST.TemplateBinder{_, _, v_28, _} <> v_30:
      v_1002963 = {v_30 : List<&2, AST.TelescopeItem>}
      v_1002964 = {v_3 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_28, v_3, v_5}}, False{}, v_1002967 => emitter_body_js_type_needed_term(v_28, v_3, v_5), +v_1002965 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_binders{v_1002963, v_1002964, v_1002965}}, +v_1002966 => EmitterFinished{v_1002966}}}

def emitter_body_js_type_needed_binders(v_1: List<&2, AST.TelescopeItem>, v_3: EmitEnv, v_5: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  emitter_match_655(v_1, v_5, v_3)

def emitter_match_656(v_0: AST.OptionalTerm, v_4: EmitTypeNeeded, v_2: EmitEnv) -> EmitterProgress<EmitTypeNeeded>:
  match v_0:
    case AST.NoTerm{}:
      EmitterFinished{v_4}
    case AST.SomeTerm{v_7}:
      emitter_body_js_type_needed_term(v_7, v_2, v_4)

def emitter_body_js_type_needed_result(v_0: AST.OptionalTerm, v_2: EmitEnv, v_4: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  emitter_match_656(v_0, v_4, v_2)

def emitter_match_657(v_1: List<&2, AST.ConstructorDecl>, v_5: EmitTypeNeeded, +v_3: EmitEnv) -> EmitterProgress<EmitTypeNeeded>:
  match v_1:
    case []:
      EmitterFinished{v_5}
    case AST.Constructor{_, v_12, _} <> v_14:
      v_1002969 = {v_14 : List<&2, AST.ConstructorDecl>}
      v_1002970 = {v_3 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_binders{v_12, v_3, v_5}}, False{}, v_1002973 => emitter_body_js_type_needed_binders(v_12, v_3, v_5), +v_1002971 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_constructors{v_1002969, v_1002970, v_1002971}}, +v_1002972 => EmitterFinished{v_1002972}}}

def emitter_body_js_type_needed_constructors(v_1: List<&2, AST.ConstructorDecl>, v_3: EmitEnv, v_5: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  emitter_match_657(v_1, v_5, v_3)

def emitter_continuation_658(+v_1002977: EmitTypeNeeded, v_20: List<&2, AST.TopLevel>, +v_3: EmitEnv, v_14: String, v_15: List<&2, AST.TelescopeItem>, v_16: AST.OptionalTerm, v_17: AST.DefBody) -> EmitterProgress<EmitTypeNeeded>:
  v_24 = v_1002977
  v_1002978 = {v_20 : List<&2, AST.TopLevel>}
  v_1002979 = {v_3 : EmitEnv}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_definition_root{v_14, v_15, v_16, v_17, v_3, v_24}}, +v_1002980 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_declarations{v_1002978, v_1002979, v_1002980}}, +v_1002981 => EmitterFinished{v_1002981}}}

def emitter_continuation_659(+v_1002990: EmitTypeNeeded, v_38: List<&2, AST.TopLevel>, v_3: EmitEnv) -> EmitterProgress<EmitTypeNeeded>:
  v_43 = v_1002990
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_declarations{v_38, v_3, v_43}}, +v_1002991 => EmitterFinished{v_1002991}}

def emitter_match_660(v_1: List<&2, AST.TopLevel>, v_5: EmitTypeNeeded, +v_3: EmitEnv) -> EmitterProgress<EmitTypeNeeded>:
  match v_1:
    case []:
      EmitterFinished{v_5}
    case AST.DefTop{AST.Definition{v_14, +v_15, +v_16, v_17, _, _}} <> v_20:
      v_1002974 = {v_16 : AST.OptionalTerm}
      v_1002975 = {v_3 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_binders{v_15, v_3, v_5}}, False{}, v_1002983 => emitter_body_js_type_needed_binders(v_15, v_3, v_5), +v_1002976 => EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_result{v_1002974, v_1002975, v_1002976}}, False{}, v_1002982 => emitter_body_js_type_needed_result(v_1002974, v_1002975, v_1002976), +v_1002977 => emitter_continuation_658(v_1002977, v_20, v_3, v_14, v_15, v_16, v_17)}}
    case AST.TypeTop{AST.TypeDecl{_, v_34, v_35, v_36, _}} <> v_38:
      v_1002984 = {v_36 : List<&2, AST.ConstructorDecl>}
      v_1002985 = {v_3 : EmitEnv}
      v_1002986 = {v_35 : AST.SyntaxTerm}
      v_1002987 = {v_3 : EmitEnv}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_binders{v_34, v_3, v_5}}, False{}, v_1002994 => emitter_body_js_type_needed_binders(v_34, v_3, v_5), +v_1002988 => EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_term{v_1002986, v_1002987, v_1002988}}, False{}, v_1002993 => emitter_body_js_type_needed_term(v_1002986, v_1002987, v_1002988), +v_1002989 => EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_constructors{v_1002984, v_1002985, v_1002989}}, False{}, v_1002992 => emitter_body_js_type_needed_constructors(v_1002984, v_1002985, v_1002989), +v_1002990 => emitter_continuation_659(v_1002990, v_38, v_3)}}}
    case AST.LawTop{_} <> v_48:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_declarations{v_48, v_3, v_5}}, +v_1002995 => EmitterFinished{v_1002995}}

def emitter_body_js_type_needed_declarations(v_1: List<&2, AST.TopLevel>, v_3: EmitEnv, v_5: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  emitter_match_660(v_1, v_5, v_3)

def emitter_match_661(v_5: AST.DefBody, v_9: EmitTypeNeeded, v_3: List<&2, AST.TelescopeItem>, v_4: AST.OptionalTerm, +v_7: EmitEnv, v_1: String) -> EmitterProgress<EmitTypeNeeded>:
  match v_5:
    case AST.DefImports{_}:
      EmitterFinished{v_9}
    case AST.DefTerm{v_14}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_definition_is_type{v_3, v_4, v_14, v_7}}, False{}, v_1002998 => emitter_body_js_definition_is_type(v_3, v_4, v_14, v_7), +v_1002996 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_definition_root_kind{v_1002996, v_1, v_7, v_9}}, +v_1002997 => EmitterFinished{v_1002997}}}

def emitter_body_js_type_needed_definition_root(v_1: String, v_3: List<&2, AST.TelescopeItem>, v_4: AST.OptionalTerm, v_5: AST.DefBody, v_7: EmitEnv, v_9: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  emitter_match_661(v_5, v_9, v_3, v_4, v_7, v_1)

def emitter_body_js_type_needed_definition_root_kind(v_1: Bool, v_3: String, v_5: EmitEnv, v_7: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  match v_1:
    case True{}:
      emitter_body_js_type_needed_ref(v_3, v_5, v_7)
    case False{}:
      EmitterFinished{v_7}

def emitter_body_js_type_needed_modules(v_1: List<&2, Loader.LoadedModule>, v_3: EmitTypeNeeded, +v_5: EmitCatalog) -> EmitterProgress<EmitTypeNeeded>:
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_modules_at{v_1, v_3, v_5, emitter_pure_js_catalog_layouts(v_5)}}, +v_1003000 => EmitterFinished{v_1003000}}

def emitter_match_663(v_1: List<&2, Loader.LoadedModule>, v_8: List<&2, EmitModuleIndex>, +v_5: EmitCatalog, v_3: EmitTypeNeeded) -> EmitterProgress<EmitTypeNeeded>:
  match v_1, v_8:
    case Loader.LoadedModule{v_21, AST.Module{_, _, v_24}} <> v_25, EmitModuleIndex{_, v_27, _, _, _} <> v_31:
      v_33 = {EmitEnv{EmitScope{v_21, v_27, v_5}, [], [], [], 0n} : EmitEnv}
      v_1003001 = {v_25 : List<&2, Loader.LoadedModule>}
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_needed_declarations{v_24, v_33, v_3}}, False{}, v_1003004 => emitter_body_js_type_needed_declarations(v_24, v_33, v_3), +v_1003002 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_needed_modules_at{v_1003001, v_1003002, v_5, v_31}}, +v_1003003 => EmitterFinished{v_1003003}}}
    case _, _:
      EmitterFinished{v_3}

def emitter_body_js_type_needed_modules_at(v_1: List<&2, Loader.LoadedModule>, v_3: EmitTypeNeeded, v_5: EmitCatalog, v_8: List<&2, EmitModuleIndex>) -> EmitterProgress<EmitTypeNeeded>:
  emitter_match_663(v_1, v_8, v_5, v_3)

def emitter_continuation_664(v_1003014: String, v_1003015: String, v_1003016: String, v_1003017: String, v_1003018: String, +v_1003019: String, v_13: List<&2, EmitTypeDefinition>) -> EmitterProgress<String>:
  v_46 = String.append(v_1003014, String.append(v_1003015, String.append(v_1003016, String.append(v_1003017, String.append(v_1003018, String.append(v_1003019, "};\n"))))))
  v_1003020 = {v_46 : String}
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_type_function_sources{v_13}}, +v_1003021 => EmitterFinished{String.append(v_1003020, v_1003021)}}

def emitter_continuation_665(+v_1003013: String, v_36: String, v_39: String, v_11: AST.SyntaxTerm, v_21: String, v_30: String, v_13: List<&2, EmitTypeDefinition>) -> EmitterProgress<String>:
  v_43 = v_1003013
  v_1003014 = {v_36 : String}
  v_1003015 = {v_39 : String}
  v_1003016 = {",native:" : String}
  v_1003017 = {v_43 : String}
  v_1003018 = {",body:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_term{v_11, v_21, v_30}}, False{}, v_1003022 => emitter_body_js_type_term(v_11, v_21, v_30), +v_1003019 => emitter_continuation_664(v_1003014, v_1003015, v_1003016, v_1003017, v_1003018, v_1003019, v_13)}

def emitter_continuation_666(v_1003011: String, +v_1003012: String, v_32: String, v_12: EmitEnv, v_9: String, v_36: String, v_11: AST.SyntaxTerm, v_21: String, v_30: String, v_13: List<&2, EmitTypeDefinition>) -> EmitterProgress<String>:
  v_39 = String.append(v_1003011, String.append(v_1003012, String.append("]={n:", v_32)))
  EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_native_marker{emitter_pure_js_base_origin(v_12), v_9}}, False{}, v_1003023 => emitter_body_js_type_native_marker(emitter_pure_js_base_origin(v_12), v_9), +v_1003013 => emitter_continuation_665(v_1003013, v_36, v_39, v_11, v_21, v_30, v_13)}

def emitter_continuation_667(v_1003005: String, +v_1003006: String, v_1003007: String, v_1003008: String, v_1003009: String, +v_1003010: Nat, +v_9: String, v_32: String, v_12: EmitEnv, v_11: AST.SyntaxTerm, v_21: String, v_30: String, v_13: List<&2, EmitTypeDefinition>) -> EmitterProgress<String>:
  v_36 = String.append(v_1003005, String.append(v_1003006, String.append(v_1003007, String.append(v_1003008, String.append(v_1003009, String.append(Nat.show(v_1003010), "};\n"))))))
  v_1003011 = {"$TYPEF[" : String}
  EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_9}}, False{}, v_1003024 => emitter_body_js_quote(v_9), +v_1003012 => emitter_continuation_666(v_1003011, v_1003012, v_32, v_12, v_9, v_36, v_11, v_21, v_30, v_13)}

def emitter_continuation_668(+v_32: String, v_10: List<&2, AST.TelescopeItem>, +v_12: EmitEnv, v_1003005: String, +v_1003006: String, v_9: String, v_11: AST.SyntaxTerm, v_21: String, v_30: String, v_13: List<&2, EmitTypeDefinition>) -> EmitterProgress<String>:
  v_1003007 = {"]={n:" : String}
  v_1003008 = {v_32 : String}
  v_1003009 = {",q:" : String}
  EmitterDirect{Bool, EmitterRequestGroup_1{EmitterRequest_js_family_quant_prefix{v_10, v_12}}, False{}, v_1003025 => emitter_body_js_family_quant_prefix(v_10, v_12), +v_1003010 => emitter_continuation_667(v_1003005, v_1003006, v_1003007, v_1003008, v_1003009, v_1003010, v_9, v_32, v_12, v_11, v_21, v_30, v_13)}

def emitter_match_669(+v_12: EmitEnv, +v_10: List<&2, AST.TelescopeItem>, +v_9: String, v_11: AST.SyntaxTerm, v_13: List<&2, EmitTypeDefinition>) -> EmitterProgress<String>:
  match v_12:
    case EmitEnv{EmitScope{v_21, v_22, _}, _, _, _, _}:
      v_30 = emitter_pure_js_aliases(v_22)
      v_32 = Nat.show(List.length(&2, AST.TelescopeItem, v_10))
      v_1003005 = {"$PARAMS[" : String}
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_9}}, False{}, v_1003026 => emitter_body_js_quote(v_9), +v_1003006 => emitter_continuation_668(v_32, v_10, v_12, v_1003005, v_1003006, v_9, v_11, v_21, v_30, v_13)}

def emitter_body_js_type_function_sources(v_2: List<&2, EmitTypeDefinition>) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterFinished{""}
    case EmitTypeDefinition{v_9, v_10, v_11, v_12} <> v_13:
      emitter_match_669(v_12, v_10, v_9, v_11, v_13)

def emitter_body_main_type_expr_declaration(v_0: AST.TopLevel, v_2: String, v_4: String) -> EmitterProgress<String>:
  match v_0:
    case AST.DefTop{AST.Definition{v_12, _, v_14, _, _, _}}:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_main_type_expr_is_main{String.eq(v_12, "main"), v_14, v_2, v_4}}, +v_1003027 => EmitterFinished{v_1003027}}
    case _:
      EmitterFinished{""}

def emitter_match_672(v_2: AST.OptionalTerm, v_4: String, v_6: String) -> EmitterProgress<String>:
  match v_2:
    case AST.SomeTerm{v_9}:
      emitter_body_js_type_term(v_9, v_4, v_6)
    case AST.NoTerm{}:
      EmitterFinished{""}

def emitter_body_main_type_expr_is_main(v_1: Bool, v_2: AST.OptionalTerm, v_4: String, v_6: String) -> EmitterProgress<String>:
  match v_1:
    case False{}:
      EmitterFinished{""}
    case True{}:
      emitter_match_672(v_2, v_4, v_6)

def emitter_match_674(v_1: List<&2, AST.TopLevel>, +v_3: String, +v_5: String) -> EmitterProgress<String>:
  match v_1:
    case []:
      EmitterFinished{""}
    case +v_9 <> v_10:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_main_type_expr_declaration{v_9, v_3, v_5}}, False{}, v_1003031 => emitter_body_main_type_expr_declaration(v_9, v_3, v_5), +v_1003029 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_main_type_expr_declaration_result{v_1003029, v_10, v_3, v_5}}, +v_1003030 => EmitterFinished{v_1003030}}}

def emitter_body_main_type_expr_declarations(v_1: List<&2, AST.TopLevel>, v_3: String, v_5: String) -> EmitterProgress<String>:
  emitter_match_674(v_1, v_3, v_5)

def emitter_body_main_type_expr_declaration_result(+v_1: String, v_3: List<&2, AST.TopLevel>, v_5: String, v_7: String) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_main_type_expr_declaration_empty{String.eq(v_1, ""), v_1, v_3, v_5, v_7}}, +v_1003032 => EmitterFinished{v_1003032}}

def emitter_match_675(v_1: Bool, v_5: List<&2, AST.TopLevel>, v_7: String, v_9: String, v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      emitter_body_main_type_expr_declarations(v_5, v_7, v_9)
    case False{}:
      EmitterFinished{v_3}

def emitter_body_main_type_expr_declaration_empty(v_1: Bool, v_3: String, v_5: List<&2, AST.TopLevel>, v_7: String, v_9: String) -> EmitterProgress<String>:
  emitter_match_675(v_1, v_5, v_7, v_9, v_3)

def emitter_body_main_type_expr_modules(v_1: List<&2, Loader.LoadedModule>, v_3: EmitCatalog) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_main_type_expr_modules_at{v_1, emitter_pure_js_catalog_layouts(v_3)}}, +v_1003034 => EmitterFinished{v_1003034}}

def emitter_body_main_type_expr_modules_at(v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, EmitModuleIndex>) -> EmitterProgress<String>:
  match v_1, v_4:
    case Loader.LoadedModule{+v_17, AST.Module{_, _, v_20}} <> v_21, EmitModuleIndex{_, v_23, _, _, _} <> v_27:
      EmitterPending{EmitterRequestGroup_7{EmitterRequest_main_type_expr_module_scope{String.eq(v_17, ""), v_17, v_23, v_20, v_21, v_27}}, +v_1003035 => EmitterFinished{v_1003035}}
    case _, _:
      EmitterFinished{"null"}

def emitter_match_677(v_1: Bool, v_9: List<&2, Loader.LoadedModule>, v_12: List<&2, EmitModuleIndex>, v_7: List<&2, AST.TopLevel>, v_3: String, v_5: EmitAliases) -> EmitterProgress<String>:
  match v_1:
    case False{}:
      emitter_body_main_type_expr_modules_at(v_9, v_12)
    case True{}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_main_type_expr_declarations{v_7, v_3, emitter_pure_js_aliases(v_5)}}, False{}, v_1003039 => emitter_body_main_type_expr_declarations(v_7, v_3, emitter_pure_js_aliases(v_5)), +v_1003037 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_main_type_expr_module_result{v_1003037, v_9, v_12}}, +v_1003038 => EmitterFinished{v_1003038}}}

def emitter_body_main_type_expr_module_scope(v_1: Bool, v_3: String, v_5: EmitAliases, v_7: List<&2, AST.TopLevel>, v_9: List<&2, Loader.LoadedModule>, v_12: List<&2, EmitModuleIndex>) -> EmitterProgress<String>:
  emitter_match_677(v_1, v_9, v_12, v_7, v_3, v_5)

def emitter_body_main_type_expr_module_result(+v_1: String, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, EmitModuleIndex>) -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_main_type_expr_module_empty{String.eq(v_1, ""), v_1, v_3, v_6}}, +v_1003040 => EmitterFinished{v_1003040}}

def emitter_match_678(v_1: Bool, v_5: List<&2, Loader.LoadedModule>, v_8: List<&2, EmitModuleIndex>, v_3: String) -> EmitterProgress<String>:
  match v_1:
    case True{}:
      emitter_body_main_type_expr_modules_at(v_5, v_8)
    case False{}:
      EmitterFinished{v_3}

def emitter_body_main_type_expr_module_empty(v_1: Bool, v_3: String, v_5: List<&2, Loader.LoadedModule>, v_8: List<&2, EmitModuleIndex>) -> EmitterProgress<String>:
  emitter_match_678(v_1, v_5, v_8, v_3)

def emitter_body_js_runtime_cli() -> EmitterProgress<String>:
  EmitterFinished{"const cli_args=[];\nfunction cli(argv) { for(let i=0;i<argv.length;i++){ if(argv[i]===\"--\"){cli_args.push(...argv.slice(i+1));break;} if(argv[i]===\"--help\"){process.stdout.write(\"usage: \"+process.argv[1]+\"\\n\");process.exit(0);} if(argv[i]===\"--threads\"||argv[i]===\"--gpu\"){i++;} else cli_args.push(argv[i]); } }\n"}

def emitter_body_js_runtime_io() -> EmitterProgress<String>:
  EmitterFinished{"function io_out(fd,data) { const fs=require(\"fs\"), b=Buffer.from(data); let at=0; while(at<b.length) at+=fs.writeSync(fd,b,at,b.length-at); }\nfunction io_errs(message) { io_out(2,io_bytes(message+\"\\n\")); }\nfunction io_bytes(text) { return new TextEncoder().encode(text); }\nfunction io_text(bytes,n) { return new TextDecoder(\"utf-8\",{ignoreBOM:true}).decode(bytes.subarray(0,n)); }\nfunction io_tuple_pair(snd,fst) { return tuple(fst,snd); }\nfunction io_tup(...xs) { if(xs.length!==2)return xs.reduceRight(io_tuple_pair); return tuple(xs[0],xs[1]); }\nfunction io_done(value) { return {$:\"Done\",value}; }\nfunction io_sys() { if(globalThis.BEND_SYS===undefined){const ffi=require(\"bun:ffi\"), mac=process.platform===\"darwin\", err=mac?\"__error\":\"__errno_location\", T={i:\"i32\",u:\"u32\",U:\"u64\",I:\"i64\",p:\"ptr\",c:\"cstring\"}, vari=mac&&process.arch===\"arm64\", lib=ffi.dlopen(mac?\"libSystem.dylib\":\"libc.so.6\",Object.fromEntries((\"socket:iii>i bind:ipu>i listen:ii>i connect:ipu>i accept:ipp>i send:ipUi>I recv:ipUi>I read:ipU>I pread:ipUI>I sendto:ipUipu>I recvfrom:ipUipp>I close:i>i poll:pui>i setsockopt:iiipu>i\"+(vari?\" fcntl:iiiiiiiii>i\":\" fcntl:iii>i\")+\" getsockopt:iiipp>i strerror:i>c \"+err+\":>p\").split(\" \").map(s=>{const [name,args,ret]=s.split(/[:>]/);return [name,{args:[...args].map(a=>T[a]),returns:T[ret]}]}))), fcntl=(fd,cmd,arg)=>vari?lib.symbols.fcntl(fd,cmd,0,0,0,0,0,0,arg):lib.symbols.fcntl(fd,cmd,arg); globalThis.BEND_SYS={...lib.symbols,fcntl,ptr:ffi.ptr,mac,errno:()=>ffi.read.i32(lib.symbols[err](),0)};} return globalThis.BEND_SYS; }\nfunction io_fail(code) { return {$:\"Fail\",error:io_tup(code>>>0,String(io_sys().strerror(code)))}; }\nfunction io_push(fun,arg,fresh) { const io=globalThis.BEND_IO; io.runs.push({fun,arg}); io.live+=fresh?1:0; }\nfunction io_park_on(fd,out,k,more) { globalThis.BEND_IO.waits.push({fd,out,k,more}); }\nfunction io_wait(io) { const soon=io.waits.reduce((m,w)=>Math.min(m,w.at??m),Infinity); let ms=-1; if(soon!==Infinity)ms=Math.min(Math.max(0,Math.ceil(soon-performance.now())),2147483647); const fds=io.waits.filter(w=>w.fd!==undefined), buf=Int32Array.from(fds.flatMap(w=>[w.fd,w.out?4:1])); io_sys().poll(fds.length?io_sys().ptr(buf):null,fds.length,ms); const now=performance.now(), fire=io.waits.filter((w)=>(buf[2*fds.indexOf(w)+1]>>>16)!==0||w.at<=now); io.waits=io.waits.filter(w=>!fire.includes(w)); for(const w of fire)io_push(io_wake,w,false); }\nfunction io_wake(w) { const x=w.more(); return x===undefined?undefined:w.k(x); }\nfunction io_run(m) { const io={runs:[],live:0,waits:[]}; globalThis.BEND_IO=io; try{io_push(run_loop(m()),io_emit,true); for(;;){if(io.runs.length===0){if(io.live===0)return 0;if(io.waits.length===0){io_errs(\"bend: deadlock: every computation waits on a channel\");return 1;}io_wait(io);continue;}const s=io.runs.shift();let op=s.fun(s.arg);for(;;){if(op===undefined)break;if(op.$===\"Emit\"){io.live-=1;break;}if(op.$===\"Halt\"){io_errs(op.message);return op.code;}const need=op.need?.()||{},fd=need.read?op.args[0]:null;if(need.time||fd!==null){const more=()=>op.run(...op.args,op.kont);io.waits.push(fd===null?{at:performance.now()+Number(op.args[0]),k:op.kont,more}:{fd,k:op.kont,more});break;}const x=op.run(...op.args,op.kont);if(x===undefined)break;op=op.kont(x);}}}catch(req){if(req instanceof RangeError)throw \"bend: memory fault (machine stack overflow?)\";if(req?.$!==\"$FFI\")throw req;io_errs(\"bend: an FFI operation failed\");return 1;} }\nfunction chan_wake(row,x) { const w=row.wait.shift(); io_push(w.cont,x,false); return w.item; }\nfunction chan_take(row) { const v=row.ring.shift(); if(row.wait.length>0)row.ring.push(chan_wake(row,true)); return v; }\nfunction chan_shut(row) { row.shut=true; while(row.wait.length>0)chan_wake(row,row.wait[0].item===null?{$:\"None\"}:false); }\nfunction io_exit(main,type) { if(type&&type.name===\"IO\")return io_run(main); try{io_out(1,io_bytes($show_value(type,run_loop(main()),0)+\"\\n\"));return 0;}catch(e){io_errs(String(e));return 1;} }\n"}

def emitter_body_js_runtime_show() -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_runtime_type{}}, +v_1003042 => EmitterFinished{String.append(v_1003042, "function $show_chr(x,q) { const c=[...x][0]||\"\\0\", n=c.codePointAt(0), k=({10:\"n\",9:\"t\",13:\"r\",0:\"0\",92:\"\\\\\"})[n]??(c===q?q:null); return k!==null?\"\\\\\"+k:n<32||n===127?\"\\\\u{\"+n.toString(16)+\"}\":c; }\nfunction $show_list(t,x) { const xs=[]; while(x&&x.$===\"Con\") { const fs=t.arms.Con; if(!fs||!Object.hasOwn(x,\"head\")||!Object.hasOwn(x,\"tail\")) throw \"bend: malformed List.Con\"; xs.push($show_value($type(fs.types[0],t.args),x.head,0)); const next=$type(fs.types[1],t.args.concat([x.head])); x=x.tail; t=next; } if(!x||x.$!==\"Nil\") throw \"bend: malformed List.Nil\"; return \"[\"+xs.join(\", \")+\"]\"; }\nfunction $show_fields(t,x,chain) { const fs=t.arms[x.$]; if(!fs) throw \"bend: constructor absent from result datatype\"; const out=[],env=t.args.slice(); let at=0; for(let j=0;j<fs.types.length;j++) { if(fs.q[j]===0) { env.push(null); continue; } const name=fs.fields[j]; if(!Object.hasOwn(x,name))throw \"bend: constructor field count mismatch\"; const v=x[name]; at++; out.push($show_value($type(fs.types[j],env),v,chain&&at===2?\"(\":0)); env.push(v); } return out.join(\", \"); }\nfunction $show_value(t,x,chain) { if(!t) return String(x); if(t.k===\"U\") return String(x); if(t.k===\"F\") { const s=f32_show(x); return s.replace(/^-?\\d+(?=e|$)/i,\"$&.0\"); } if(t.k===\"N\") return x+\"n\"; if(t.k===\"C\") return \"'\"+$show_chr(x,\"'\")+\"'\"; if(t.k===\"S\") return \"\\\"\"+[...x].map(c=>$show_chr(c,\"\\\"\")).join(\"\")+\"\\\"\"; if(t.k===\"E\") return \"{==}\"; if(t.k===\"A\") return \"[\"+x.map(v=>$show_value(t.e,v,0)).join(\", \")+\"]\"; if(typeof x===\"boolean\") return x?\"True{}\":\"False{}\"; if(!x||typeof x!==\"object\"||!x.$) return String(x); if(t.native===\"List\") return $show_list(t,x); if(t.native===\"Sigma\"&&x.$===\"Tuple\") { const c=chain===\"(\"; return (c?\"\":\"(\")+$show_fields(t,x,true)+(c?\"\":\")\"); } if(t.k!==\"D\") throw \"bend: expected a datatype result\"; return x.$+\"{\"+$show_fields(t,x,false)+\"}\"; }\n")}}

def emitter_body_js_runtime_type() -> EmitterProgress<String>:
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_runtime_native_type{}}, +v_1003043 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_runtime_type_names{}}, +v_1003044 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_runtime_type_patterns{}}, +v_1003045 => EmitterPending{EmitterRequestGroup_7{EmitterRequest_js_runtime_type_eval{}}, +v_1003046 => EmitterFinished{String.append(v_1003043, String.append(v_1003044, String.append(v_1003045, v_1003046)))}}}}}

def emitter_body_js_runtime_type_names() -> EmitterProgress<String>:
  EmitterFinished{"function $type_key(k,s,i) { const q=$key(k,s,i||{}); return $TYPE[q]!==undefined||$TYPEF[q]!==undefined?q:k; }\nfunction $type_ctor_key(k,s,i) { const q=$key(k,s,i||{}); return $FIELDS[q]!==undefined?q:k; }\nfunction $type_delay(t,a) { if(t.k)return t; if(t.p!==undefined&&a[a.length-1-t.p]!==undefined)return a[a.length-1-t.p]; return {k:\"Thunk\",term:t,env:a,depth:a.length,done:false}; }\nfunction $type_force(v) { if(v&&v.k===\"Thunk\") { if(!v.done) { v.value=$type(v.term,v.env.length===v.depth?v.env:v.env.slice(0,v.depth)); v.done=true; } return v.value; } return v; }\nfunction $type_apply(f,x) { f=$type_force(f); if(f.k===\"L\") return $type(f.body,f.env.concat([x])); if(f.k===\"TF\"||f.k===\"DF\") return $type_named(f.key,f.args.concat([x])); throw \"bend: type expression applied a non-function\"; }\nfunction $type_named(q,ps) { const f=$TYPEF[q]; if(f) { if(ps.length<f.n)return {k:\"TF\",key:q,args:ps}; let v=f.intrinsic?$type_native_invoke(f,ps):$type(f.body,ps.length===f.n?ps:ps.slice(0,f.n)); for(let i=f.n;i<ps.length;i++)v=$type_apply(v,ps[i]); if(f.native===\"IO\")v.name=\"IO\"; return v; } const d=$TYPE[q]; if(!d) throw \"bend: unresolved type expression \"+q; const p=$PARAMS[q]; if(ps.length<p.n)return {k:\"DF\",key:q,args:ps}; if(ps.length!==p.n)throw \"bend: datatype parameter count mismatch\"; if(d.native===\"Array\") return {k:\"A\",e:$type_force(ps[0])}; const k=({U32:\"U\",F32:\"F\",Nat:\"N\",Char:\"C\",String:\"S\",Eql:\"E\"})[d.native]; return k?{k}:{k:\"D\",key:q,name:d.name,native:d.native,arms:d.arms,args:ps}; }\n"}

def emitter_body_js_runtime_type_patterns() -> EmitterProgress<String>:
  EmitterFinished{"function $type_sugar(t,a) { const h=$type(t.sugar,a),more=t.a.map(x=>$type_delay(x,a)); if(h.k===\"TF\"||h.k===\"DF\"||h.k===\"D\") { const q=h.key,p=$PARAMS[q]; let xs=h.args.concat(more); if(p&&xs.length+p.q===p.n)xs=Array.from({length:p.q},()=>({k:\"Q\",v:t.f})).concat(xs); if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x); return $type_named(q,xs); } let v=h; for(const x of more)v=$type_apply(v,x); return v; }\nfunction $type_pattern(p,v,bindings) { if(p.v) { bindings.push(v); return true; } v=$type_force(v); const q=$type_ctor_key(p.c,p.s,p.i),c=$PRIMITIVES[q]||($FIELDS[q]===undefined?q:\"\"); let fields,complete=false; if(v&&v.k===\"V\") { if(v.c!==q)return false; fields=v.args; complete=true; } else if(v&&v.$===q) { const names=$FIELDS[q]; if(!names||names.length!==p.fields.length)return false; for(let j=0;j<names.length;j++){if(names[j]===null){bindings.push(null);continue;}if(!$type_pattern(p.fields[j],v[names[j]],bindings))return false;}return true; } else if(c===\"Bool.True\"&&v===true||c===\"Bool.False\"&&v===false||c===\"Nat.Zero\"&&v===0||c===\"String.SNil\"&&v===\"\") fields=[]; else if(c===\"Nat.Succ\"&&typeof v===\"number\"&&v>0)fields=[v-1]; else if(c===\"String.SCon\"&&typeof v===\"string\"&&v.length)fields=[String.fromCodePoint(v.codePointAt(0)),v.slice(v.codePointAt(0)>0xFFFF?2:1)]; else if(c===\"Char.Chr\"&&typeof v===\"string\")fields=[v.codePointAt(0)]; else if(c===\"U32.U32\"&&typeof v===\"number\")fields=[u32_to_word(v)]; else if(c===\"F32.F32\"&&typeof v===\"number\")fields=[u32_to_word(f32_bits(v))]; else if(c===\"Array.ALeaf\"&&Array.isArray(v)&&v.length===1)fields=[v[0]]; else if(c===\"Array.ANode\"&&Array.isArray(v)&&v.length!==1)fields=[v.slice(0,v.length>>1),v.slice(v.length>>1)]; else return false; let at=0; for(const field of p.fields) { if(!complete&&field.v&&field.q===0) { bindings.push(null); continue; } if(at>=fields.length||!$type_pattern(field,fields[at++],bindings))return false; } return at===fields.length; }\nfunction $type_bind(patterns,values) { if(patterns.length!==values.length)return null; const bindings=[]; for(let j=0;j<values.length;j++)if(!$type_pattern(patterns[j],values[j],bindings))return null; return bindings; }\n"}

def emitter_body_js_runtime_type_eval() -> EmitterProgress<String>:
  EmitterFinished{"function $type(t,a=[]) { if(t===null)return null; if(t===undefined)throw \"bend: missing type expression\"; if(t.p!==undefined) { const v=$type_force(a[a.length-1-t.p]); if(v===undefined||v===null)throw \"bend: unavailable type-expression binder\"; return v; } if(t.k)return $type_force(t); if(t.fail)throw t.fail; if(t.kind!==undefined)return {k:\"K\",q:$type(t.kind,a)}; if(t.min!==undefined)return {k:\"Q\",v:Math.min($type(t.min,a).v,$type(t.right,a).v)}; if(t.all!==undefined)return {k:\"Fn\",q:t.q,domain:$type(t.all,a),body:t.body,env:a}; if(t.lam!==undefined)return {k:\"L\",body:t.lam,env:a}; if(t.app!==undefined)return $type_apply($type(t.app,a),$type_delay(t.arg,a)); if(t.sub!==undefined) { const env=a.slice(); env.splice(env.length-t.sub,0,$type_delay(t.value,a)); return $type(t.body,env); } if(t.let!==undefined)return $type(t.body,a.concat(t.let.map(x=>$type_delay(x,a)))); if(t.local!==undefined) { const bs=$type_bind(t.pat,t.local.map(x=>$type_delay(x,a))); if(bs===null)throw \"bend: type expression local pattern failed\"; return $type(t.body,a.concat(bs)); } if(t.bind!==undefined)return $type(t.body,a.concat([$type_delay(t.bind,a)])); if(t.match!==undefined) { const vs=t.match.map(x=>$type_delay(x,a)); for(const c of t.cases) { const bs=$type_bind(c.pat,vs); if(bs!==null)return $type(c.body,a.concat(bs)); } throw \"bend: type expression match failed\"; } if(t.c!==undefined)return {k:\"V\",c:$type_ctor_key(t.c,t.s,t.i),args:t.a.map(x=>$type_delay(x,a))}; if(t.sugar!==undefined)return $type_sugar(t,a); if(t.f) { const q=$type_key(t.r,t.s,t.i),p=$PARAMS[q]; if(!p&&t.f===2)return $type(t.h,a); let xs=t.a||[]; if(p&&xs.length+p.q===p.n)xs=Array.from({length:p.q},()=>({k:\"Q\",v:1})).concat(xs); if(p&&t.f===2)xs=xs.map((x,i)=>i<p.q?({k:\"Q\",v:2}):x); return $type_named(q,xs.map(x=>$type_delay(x,a))); } if(t.r!==undefined)return $type_named($type_key(t.r,t.s,t.i),(t.a||[]).map(x=>$type_delay(x,a))); throw \"bend: unsupported type-expression descriptor\"; }\n"}

def emitter_body_js_runtime_native_type() -> EmitterProgress<String>:
  EmitterFinished{"function $type_native_invoke(f,ps) { let value=f.intrinsic; for(let i=0;i<f.n;i++)if(f.q[i]!==0)value=value($type_runtime_value(ps[i])); return value; }\nfunction $type_runtime_value(value) { const v=$type_force(value); if(!v||v.k!==\"V\")return v; const c=$PRIMITIVES[v.c]||($FIELDS[v.c]===undefined?v.c:\"\"),xs=v.args; switch(c) { case \"Nat.Zero\":return 0; case \"Nat.Succ\":return nat_chk($type_runtime_value(xs[0])+1); case \"Bool.False\":return false; case \"Bool.True\":return true; case \"String.SNil\":return \"\"; case \"String.SCon\":return $type_runtime_value(xs[0])+$type_runtime_value(xs[1]); case \"Char.Chr\":return char_new($type_runtime_value(xs[0])); case \"U32.U32\":return word_to_u32($type_runtime_value(xs[0])); case \"F32.F32\":return f32_from_bits(word_to_u32($type_runtime_value(xs[0]))); case \"Array.ALeaf\":return [$type_runtime_value(xs[0])]; case \"Array.ANode\":return $type_runtime_value(xs[0]).concat($type_runtime_value(xs[1])); } const fs=$FIELDS[v.c]; if(!fs||fs.length!==xs.length)throw \"bend: unresolved metadata constructor\"; const args=xs.map((x,i)=>fs[i]===null?null:$type_runtime_value(x)); return $ctr(v.c,args,\"\",{}); }\n"}

def emitter_body_js_main(v_1: String) -> EmitterProgress<String>:
  EmitterFinished{String.append("if (typeof process !== \"undefined\" && process.argv[1] && /\\.js$/.test(process.argv[1])) { cli(process.argv.slice(2)); if(Object.hasOwn($D,\"main\")) { process.exitCode=io_exit(()=>$D[\"main\"],$type(", String.append(v_1, ")); } }\n"))}

def emitter_body_emit(+v_1: List<&2, Loader.LoadedModule>) -> EmitterProgress<EmitResult>:
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_modules{v_1}}, False{}, v_1003049 => emitter_body_template_modules(v_1), +v_1003047 => EmitterPending{EmitterRequestGroup_8{EmitterRequest_js_emit_template{v_1003047, v_1, None{}}}, +v_1003048 => EmitterFinished{v_1003048}}}

def emitter_match_679(v_1: Maybe<&2, AST.SourceSpan>, +v_3: List<&2, Loader.LoadedModule>, v_7: Maybe<&2, List<&2, String>>) -> EmitterProgress<EmitResult>:
  match v_1:
    case Some{v_10}:
      EmitterFinished{EmitFailure{"unexpanded compile-time template", v_10}}
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_error_modules{v_3}}, False{}, v_1003052 => emitter_body_error_modules(v_3), +v_1003050 => EmitterPending{EmitterRequestGroup_8{EmitterRequest_js_emit_holes{v_1003050, v_3, v_7}}, +v_1003051 => EmitterFinished{v_1003051}}}

def emitter_body_js_emit_template(v_1: Maybe<&2, AST.SourceSpan>, v_3: List<&2, Loader.LoadedModule>, v_7: Maybe<&2, List<&2, String>>) -> EmitterProgress<EmitResult>:
  emitter_match_679(v_1, v_3, v_7)

def emitter_match_680(v_1: Maybe<&2, AST.SourceSpan>, +v_3: List<&2, Loader.LoadedModule>, v_7: Maybe<&2, List<&2, String>>) -> EmitterProgress<EmitResult>:
  match v_1:
    case Some{v_10}:
      EmitterFinished{EmitFailure{"cannot compile a hole", v_10}}
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_foreign_error_modules{v_3}}, False{}, v_1003055 => emitter_body_foreign_error_modules(v_3), +v_1003053 => EmitterPending{EmitterRequestGroup_8{EmitterRequest_js_emit_foreign{v_1003053, v_3, v_7}}, +v_1003054 => EmitterFinished{v_1003054}}}

def emitter_body_js_emit_holes(v_1: Maybe<&2, AST.SourceSpan>, v_3: List<&2, Loader.LoadedModule>, v_7: Maybe<&2, List<&2, String>>) -> EmitterProgress<EmitResult>:
  emitter_match_680(v_1, v_3, v_7)

def emitter_continuation_681(+v_1003057: String, +v_1003058: String, +v_1003059: String, +v_1003060: String, +v_1003061: String, +v_1003062: String, +v_1003063: String, +v_1003064: String, +v_1003065: String, +v_1003066: String, +v_1003067: String, +v_1003068: String) -> EmitterProgress<EmitResult>:
  v_27 = String.append(v_1003057, String.append(v_1003058, String.append(v_1003059, String.append(v_1003060, String.append(v_1003061, String.append(v_1003062, String.append(v_1003063, String.append(v_1003064, String.append(v_1003065, String.append(v_1003066, String.append(v_1003067, v_1003068)))))))))))
  EmitterFinished{EmitSuccess{v_27}}

def emitter_continuation_682(+v_1003056: EmitCatalog, +v_3: List<&2, Loader.LoadedModule>, v_7: Maybe<&2, List<&2, String>>) -> EmitterProgress<EmitResult>:
  +v_13 = v_1003056
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_runtime{}}, False{}, v_1003079 => emitter_body_js_runtime, +v_1003057 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_runtime_extra{}}, False{}, v_1003078 => emitter_body_js_runtime_extra, +v_1003058 => EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_runtime_show{}}, False{}, v_1003077 => emitter_body_js_runtime_show, +v_1003059 => EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_runtime_cli{}}, False{}, v_1003076 => emitter_body_js_runtime_cli, +v_1003060 => EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_runtime_io{}}, False{}, v_1003075 => emitter_body_js_runtime_io, +v_1003061 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_runtime_array{}}, False{}, v_1003074 => emitter_body_js_runtime_array, +v_1003062 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_runtime_foreign{}}, False{}, v_1003073 => emitter_body_js_runtime_foreign, +v_1003063 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_runtime_namespace{}}, False{}, v_1003072 => emitter_body_js_runtime_namespace, +v_1003064 => EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_constructor_fields_modules{v_3}}, False{}, v_1003071 => emitter_body_js_constructor_fields_modules(v_3), +v_1003065 => EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_js_type_modules{v_3, v_13}}, False{}, v_1003070 => emitter_body_js_type_modules(v_3, v_13), +v_1003066 => EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_js_modules{v_3, v_13}}, False{}, v_1003069 => emitter_body_js_modules(v_3, v_13), +v_1003067 => EmitterPending{EmitterRequestGroup_8{EmitterRequest_js_emit_ending{v_7, v_3, v_13}}, +v_1003068 => emitter_continuation_681(v_1003057, v_1003058, v_1003059, v_1003060, v_1003061, v_1003062, v_1003063, v_1003064, v_1003065, v_1003066, v_1003067, v_1003068)}}}}}}}}}}}}

def emitter_match_683(v_1: Maybe<&2, AST.SourceSpan>, +v_3: List<&2, Loader.LoadedModule>, v_7: Maybe<&2, List<&2, String>>) -> EmitterProgress<EmitResult>:
  match v_1:
    case Some{v_10}:
      EmitterFinished{EmitFailure{"a foreign def without a .js import", v_10}}
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_value_indices{v_3}}, False{}, v_1003080 => emitter_body_js_value_indices(v_3), +v_1003056 => emitter_continuation_682(v_1003056, v_3, v_7)}

def emitter_body_js_emit_foreign(v_1: Maybe<&2, AST.SourceSpan>, v_3: List<&2, Loader.LoadedModule>, v_7: Maybe<&2, List<&2, String>>) -> EmitterProgress<EmitResult>:
  emitter_match_683(v_1, v_3, v_7)

def emitter_body_js_library_exports(v_2: List<&2, String>) -> EmitterProgress<String>:
  v_1003081 = {"export default {" : String}
  EmitterPending{EmitterRequestGroup_8{EmitterRequest_js_library_export_fields{v_2}}, +v_1003082 => EmitterFinished{String.append(v_1003081, String.append(v_1003082, "};\n"))}}

def emitter_continuation_684(+v_1003083: String, v_7: List<&2, String>) -> EmitterProgress<String>:
  +v_10 = v_1003083
  v_1003084 = {v_10 : String}
  v_1003085 = {":(...args)=>$run($D[" : String}
  v_1003086 = {v_10 : String}
  v_1003087 = {"],args)," : String}
  EmitterPending{EmitterRequestGroup_8{EmitterRequest_js_library_export_fields{v_7}}, +v_1003088 => EmitterFinished{String.append(v_1003084, String.append(v_1003085, String.append(v_1003086, String.append(v_1003087, v_1003088))))}}

def emitter_body_js_library_export_fields(v_2: List<&2, String>) -> EmitterProgress<String>:
  match v_2:
    case []:
      EmitterFinished{""}
    case +v_6 <> v_7:
      EmitterDirect{Bool, EmitterRequestGroup_0{EmitterRequest_js_quote{v_6}}, False{}, v_1003089 => emitter_body_js_quote(v_6), +v_1003083 => emitter_continuation_684(v_1003083, v_7)}

def emitter_body_emit_library(+v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, String>) -> EmitterProgress<EmitResult>:
  EmitterDirect{Bool, EmitterRequestGroup_6{EmitterRequest_template_modules{v_1}}, False{}, v_1003093 => emitter_body_template_modules(v_1), +v_1003090 => EmitterDirect{Bool, EmitterRequestGroup_8{EmitterRequest_js_emit_template{v_1003090, v_1, Some{v_4}}}, False{}, v_1003092 => emitter_body_js_emit_template(v_1003090, v_1, Some{v_4}), +v_1003091 => EmitterFinished{v_1003091}}}

def emitter_body_js_emit_ending(v_3: Maybe<&2, List<&2, String>>, v_5: List<&2, Loader.LoadedModule>, v_7: EmitCatalog) -> EmitterProgress<String>:
  match v_3:
    case None{}:
      EmitterDirect{Bool, EmitterRequestGroup_7{EmitterRequest_main_type_expr_modules{v_5, v_7}}, False{}, v_1003096 => emitter_body_main_type_expr_modules(v_5, v_7), +v_1003094 => emitter_body_js_main(v_1003094)}
    case Some{v_12}:
      emitter_body_js_library_exports(v_12)

def emitter_step_group_0(request: EmitterRequestGroup0) -> EmitterProgress<emitter_result_group_0(request)>:
  match request:
    case EmitterRequest_js_value_indices{arg_0}: emitter_body_js_value_indices(arg_0)
    case EmitterRequest_js_catalog{arg_0}: emitter_body_js_catalog(arg_0)
    case EmitterRequest_js_catalog_at{arg_0, arg_1}: emitter_body_js_catalog_at(arg_0, arg_1)
    case EmitterRequest_js_catalog_module{arg_0, arg_1}: emitter_body_js_catalog_module(arg_0, arg_1)
    case EmitterRequest_js_catalog_values{arg_0, arg_1, arg_2}: emitter_body_js_catalog_values(arg_0, arg_1, arg_2)
    case EmitterRequest_js_catalog_constructors{arg_0, arg_1, arg_2}: emitter_body_js_catalog_constructors(arg_0, arg_1, arg_2)
    case EmitterRequest_js_catalog_types{arg_0, arg_1, arg_2}: emitter_body_js_catalog_types(arg_0, arg_1, arg_2)
    case EmitterRequest_js_catalog_type_insert{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_catalog_type_insert(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_catalog_layouts{arg_0}: emitter_body_js_catalog_layouts(arg_0)
    case EmitterRequest_js_namespace_indices{arg_0}: emitter_body_js_namespace_indices(arg_0)
    case EmitterRequest_js_value_indices_at{arg_0, arg_1, arg_2}: emitter_body_js_value_indices_at(arg_0, arg_1, arg_2)
    case EmitterRequest_js_value_declarations{arg_0, arg_1}: emitter_body_js_value_declarations(arg_0, arg_1)
    case EmitterRequest_js_value_declaration{arg_0, arg_1, arg_2}: emitter_body_js_value_declaration(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_indices{arg_0, arg_1}: emitter_body_js_constructor_indices(arg_0, arg_1)
    case EmitterRequest_js_constructor_index_family{arg_0, arg_1, arg_2}: emitter_body_js_constructor_index_family(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_index_items{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_constructor_index_items(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_indices{arg_0, arg_1}: emitter_body_js_type_indices(arg_0, arg_1)
    case EmitterRequest_js_type_index_declaration{arg_0, arg_1, arg_2}: emitter_body_js_type_index_declaration(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_index_insert{arg_0, arg_1, arg_2}: emitter_body_js_type_index_insert(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_index_found{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_index_found(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_escape_char{arg_0}: emitter_body_js_escape_char(arg_0)
    case EmitterRequest_js_comma_prefix{arg_0}: emitter_body_js_comma_prefix(arg_0)
    case EmitterRequest_js_quote_chars{arg_0, arg_1}: emitter_body_js_quote_chars(arg_0, arg_1)
    case EmitterRequest_js_quote{arg_0}: emitter_body_js_quote(arg_0)
    case EmitterRequest_js_named_identifier_char{arg_0, arg_1, arg_2}: emitter_body_js_named_identifier_char(arg_0, arg_1, arg_2)
    case EmitterRequest_js_named_identifier_chars{arg_0, arg_1}: emitter_body_js_named_identifier_chars(arg_0, arg_1)
    case EmitterRequest_js_named_identifier{arg_0}: emitter_body_js_named_identifier(arg_0)
    case EmitterRequest_env_binding{arg_0, arg_1}: emitter_body_env_binding(arg_0, arg_1)
    case EmitterRequest_env_binding_at{arg_0, arg_1, arg_2, arg_3}: emitter_body_env_binding_at(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_env_at_binding{arg_0}: emitter_body_env_at_binding(arg_0)
    case EmitterRequest_env_at{arg_0, arg_1}: emitter_body_env_at(arg_0, arg_1)
    case EmitterRequest_env_bind{arg_0, arg_1, arg_2, arg_3}: emitter_body_env_bind(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_env_push{arg_0, arg_1}: emitter_body_env_push(arg_0, arg_1)
    case EmitterRequest_js_close{arg_0, arg_1}: emitter_body_js_close(arg_0, arg_1)
    case EmitterRequest_js_close_inferred{arg_0, arg_1, arg_2}: emitter_body_js_close_inferred(arg_0, arg_1, arg_2)
    case EmitterRequest_js_close_declared{arg_0, arg_1, arg_2}: emitter_body_js_close_declared(arg_0, arg_1, arg_2)
    case EmitterRequest_js_close_definition{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_close_definition(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_closure_env{arg_0}: emitter_body_js_closure_env(arg_0)
    case EmitterRequest_js_scope_key{arg_0, arg_1}: emitter_body_js_scope_key(arg_0, arg_1)
    case EmitterRequest_js_scope_alias{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_scope_alias(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_scope_alias_match{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: emitter_body_js_scope_alias_match(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case EmitterRequest_js_global{arg_0, arg_1}: emitter_body_js_global(arg_0, arg_1)
    case EmitterRequest_js_global_fallback{arg_0, arg_1, arg_2}: emitter_body_js_global_fallback(arg_0, arg_1, arg_2)
    case EmitterRequest_js_global_lookup{arg_0, arg_1}: emitter_body_js_global_lookup(arg_0, arg_1)
    case EmitterRequest_js_global_owner{arg_0, arg_1, arg_2}: emitter_body_js_global_owner(arg_0, arg_1, arg_2)
    case EmitterRequest_js_owner_env{arg_0, arg_1}: emitter_body_js_owner_env(arg_0, arg_1)
    case EmitterRequest_js_global_definition{arg_0, arg_1, arg_2}: emitter_body_js_global_definition(arg_0, arg_1, arg_2)
    case EmitterRequest_js_global_type{arg_0, arg_1}: emitter_body_js_global_type(arg_0, arg_1)
    case EmitterRequest_js_global_type_fallback{arg_0, arg_1, arg_2}: emitter_body_js_global_type_fallback(arg_0, arg_1, arg_2)
    case EmitterRequest_js_global_type_lookup{arg_0, arg_1}: emitter_body_js_global_type_lookup(arg_0, arg_1)
    case EmitterRequest_js_global_type_owners{arg_0, arg_1, arg_2}: emitter_body_js_global_type_owners(arg_0, arg_1, arg_2)
    case EmitterRequest_js_global_type_modules{arg_0, arg_1, arg_2}: emitter_body_js_global_type_modules(arg_0, arg_1, arg_2)
    case EmitterRequest_js_global_type_next{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_global_type_next(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_global_type_index{arg_0, arg_1}: emitter_body_js_global_type_index(arg_0, arg_1)
    case EmitterRequest_js_global_type_decls{arg_0, arg_1}: emitter_body_js_global_type_decls(arg_0, arg_1)
    case EmitterRequest_js_global_type_definition{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_global_type_definition(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_global_native_law_operation{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_global_native_law_operation(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_native_law_type{arg_0, arg_1, arg_2}: emitter_body_js_native_law_type(arg_0, arg_1, arg_2)
    case EmitterRequest_js_native_law_binders{arg_0, arg_1}: emitter_body_js_native_law_binders(arg_0, arg_1)
    case EmitterRequest_js_native_law_binder{arg_0, arg_1}: emitter_body_js_native_law_binder(arg_0, arg_1)
    case EmitterRequest_js_type_definition{arg_0, arg_1, arg_2}: emitter_body_js_type_definition(arg_0, arg_1, arg_2)
    case EmitterRequest_js_reduce_env{arg_0, arg_1}: emitter_body_js_reduce_env(arg_0, arg_1)
    case EmitterRequest_js_reduce{arg_0}: emitter_body_js_reduce(arg_0)
    case EmitterRequest_js_reduce_inferred{arg_0, arg_1}: emitter_body_js_reduce_inferred(arg_0, arg_1)

def emitter_step_group_1(request: EmitterRequestGroup1) -> EmitterProgress<emitter_result_group_1(request)>:
  match request:
    case EmitterRequest_js_reduce_binding{arg_0, arg_1}: emitter_body_js_reduce_binding(arg_0, arg_1)
    case EmitterRequest_js_reduce_global{arg_0, arg_1}: emitter_body_js_reduce_global(arg_0, arg_1)
    case EmitterRequest_js_reduce_app_env{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_reduce_app_env(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_reduce_app{arg_0, arg_1, arg_2}: emitter_body_js_reduce_app(arg_0, arg_1, arg_2)
    case EmitterRequest_js_reduce_patterns{arg_0, arg_1, arg_2}: emitter_body_js_reduce_patterns(arg_0, arg_1, arg_2)
    case EmitterRequest_js_reduce_patterns_next{arg_0, arg_1, arg_2}: emitter_body_js_reduce_patterns_next(arg_0, arg_1, arg_2)
    case EmitterRequest_js_reduce_pattern{arg_0, arg_1, arg_2}: emitter_body_js_reduce_pattern(arg_0, arg_1, arg_2)
    case EmitterRequest_js_reduce_pattern_view_env{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_reduce_pattern_view_env(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_reduce_pattern_view{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_reduce_pattern_view(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_same_scoped_key{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_same_scoped_key(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_same_constructor_key{arg_0, arg_1}: emitter_body_js_same_constructor_key(arg_0, arg_1)
    case EmitterRequest_js_reduce_pattern_key{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_reduce_pattern_key(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_reduce_local{arg_0, arg_1, arg_2}: emitter_body_js_reduce_local(arg_0, arg_1, arg_2)
    case EmitterRequest_js_reduce_cases{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_reduce_cases(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_reduce_case_result{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_reduce_case_result(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_value_env{arg_0, arg_1}: emitter_body_js_value_env(arg_0, arg_1)
    case EmitterRequest_js_value_env_at{arg_0, arg_1, arg_2}: emitter_body_js_value_env_at(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type{arg_0, arg_1}: emitter_body_js_type(arg_0, arg_1)
    case EmitterRequest_js_binding_type{arg_0}: emitter_body_js_binding_type(arg_0)
    case EmitterRequest_js_type_value{arg_0}: emitter_body_js_type_value(arg_0)
    case EmitterRequest_js_type_local{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_local(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_local_refined{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_type_local_refined(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_apply_type_args{arg_0, arg_1}: emitter_body_js_apply_type_args(arg_0, arg_1)
    case EmitterRequest_js_apply_type{arg_0, arg_1}: emitter_body_js_apply_type(arg_0, arg_1)
    case EmitterRequest_js_apply_type_view_env{arg_0, arg_1, arg_2}: emitter_body_js_apply_type_view_env(arg_0, arg_1, arg_2)
    case EmitterRequest_js_apply_type_view{arg_0, arg_1}: emitter_body_js_apply_type_view(arg_0, arg_1)
    case EmitterRequest_js_type_cases{arg_0, arg_1, arg_2}: emitter_body_js_type_cases(arg_0, arg_1, arg_2)
    case EmitterRequest_env_insert_binding{arg_0, arg_1, arg_2}: emitter_body_env_insert_binding(arg_0, arg_1, arg_2)
    case EmitterRequest_env_insert_names{arg_0, arg_1, arg_2}: emitter_body_env_insert_names(arg_0, arg_1, arg_2)
    case EmitterRequest_env_insert_closures{arg_0, arg_1, arg_2}: emitter_body_env_insert_closures(arg_0, arg_1, arg_2)
    case EmitterRequest_env_names_typed{arg_0, arg_1, arg_2}: emitter_body_env_names_typed(arg_0, arg_1, arg_2)
    case EmitterRequest_js_scrutinee_types{arg_0, arg_1}: emitter_body_js_scrutinee_types(arg_0, arg_1)
    case EmitterRequest_js_pattern_types{arg_0, arg_1, arg_2}: emitter_body_js_pattern_types(arg_0, arg_1, arg_2)
    case EmitterRequest_js_pattern_type{arg_0, arg_1, arg_2}: emitter_body_js_pattern_type(arg_0, arg_1, arg_2)
    case EmitterRequest_js_field_types{arg_0}: emitter_body_js_field_types(arg_0)
    case EmitterRequest_js_field_types_view_env{arg_0, arg_1}: emitter_body_js_field_types_view_env(arg_0, arg_1)
    case EmitterRequest_js_field_types_view{arg_0}: emitter_body_js_field_types_view(arg_0)
    case EmitterRequest_js_constructor_decl{arg_0, arg_1}: emitter_body_js_constructor_decl(arg_0, arg_1)
    case EmitterRequest_js_constructor_decl_fallback{arg_0, arg_1, arg_2}: emitter_body_js_constructor_decl_fallback(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_lookup{arg_0, arg_1}: emitter_body_js_constructor_lookup(arg_0, arg_1)
    case EmitterRequest_js_constructor_index_owner{arg_0, arg_1, arg_2}: emitter_body_js_constructor_index_owner(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_owner{arg_0, arg_1, arg_2}: emitter_body_js_constructor_owner(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_signature{arg_0, arg_1, arg_2}: emitter_body_js_constructor_signature(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_signature_found{arg_0, arg_1}: emitter_body_js_constructor_signature_found(arg_0, arg_1)
    case EmitterRequest_js_family_parameter_arguments{arg_0, arg_1}: emitter_body_js_family_parameter_arguments(arg_0, arg_1)
    case EmitterRequest_js_family_parameter_view_env{arg_0, arg_1, arg_2}: emitter_body_js_family_parameter_view_env(arg_0, arg_1, arg_2)
    case EmitterRequest_js_family_parameter_view{arg_0, arg_1}: emitter_body_js_family_parameter_view(arg_0, arg_1)
    case EmitterRequest_js_family_arguments_view_env{arg_0, arg_1}: emitter_body_js_family_arguments_view_env(arg_0, arg_1)
    case EmitterRequest_js_family_arguments_view{arg_0}: emitter_body_js_family_arguments_view(arg_0)
    case EmitterRequest_js_family_fill_arguments{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_family_fill_arguments(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_family_quant_prefix{arg_0, arg_1}: emitter_body_js_family_quant_prefix(arg_0, arg_1)
    case EmitterRequest_js_family_quant_domain{arg_0, arg_1, arg_2}: emitter_body_js_family_quant_domain(arg_0, arg_1, arg_2)
    case EmitterRequest_js_family_fill_missing{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_family_fill_missing(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_quantity_closures{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_quantity_closures(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_family_promote_arguments{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_family_promote_arguments(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_closure_terms{arg_0, arg_1}: emitter_body_js_closure_terms(arg_0, arg_1)
    case EmitterRequest_js_constructor_parameter_types{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_constructor_parameter_types(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_choose{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_choose(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_key_matches{arg_0, arg_1}: emitter_body_js_key_matches(arg_0, arg_1)
    case EmitterRequest_js_choose_exact{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_choose_exact(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_choose_result{arg_0, arg_1, arg_2}: emitter_body_js_choose_result(arg_0, arg_1, arg_2)
    case EmitterRequest_js_reference{arg_0}: emitter_body_js_reference(arg_0)
    case EmitterRequest_js_native_operations{arg_0, arg_1, arg_2}: emitter_body_js_native_operations(arg_0, arg_1, arg_2)
    case EmitterRequest_js_native_operation_declarations{arg_0, arg_1}: emitter_body_js_native_operation_declarations(arg_0, arg_1)

def emitter_step_group_2(request: EmitterRequestGroup2) -> EmitterProgress<emitter_result_group_2(request)>:
  match request:
    case EmitterRequest_js_native_operation_insert_keys{arg_0, arg_1, arg_2}: emitter_body_js_native_operation_insert_keys(arg_0, arg_1, arg_2)
    case EmitterRequest_js_native_operation_insert{arg_0, arg_1}: emitter_body_js_native_operation_insert(arg_0, arg_1)
    case EmitterRequest_js_native_operation_insert_found{arg_0, arg_1, arg_2}: emitter_body_js_native_operation_insert_found(arg_0, arg_1, arg_2)
    case EmitterRequest_js_native_operation_origin{arg_0, arg_1}: emitter_body_js_native_operation_origin(arg_0, arg_1)
    case EmitterRequest_js_native_operation{arg_0, arg_1}: emitter_body_js_native_operation(arg_0, arg_1)
    case EmitterRequest_js_native_operation_known{arg_0, arg_1}: emitter_body_js_native_operation_known(arg_0, arg_1)
    case EmitterRequest_js_native_operation_name{arg_0}: emitter_body_js_native_operation_name(arg_0)
    case EmitterRequest_js_native_operation_chars{arg_0, arg_1}: emitter_body_js_native_operation_chars(arg_0, arg_1)
    case EmitterRequest_suffix_any{arg_0, arg_1, arg_2}: emitter_body_suffix_any(arg_0, arg_1, arg_2)
    case EmitterRequest_js_native_u32{arg_0}: emitter_body_js_native_u32(arg_0)
    case EmitterRequest_js_native_u32_1{arg_0}: emitter_body_js_native_u32_1(arg_0)
    case EmitterRequest_js_native_u32_2{arg_0}: emitter_body_js_native_u32_2(arg_0)
    case EmitterRequest_js_native_f32{arg_0}: emitter_body_js_native_f32(arg_0)
    case EmitterRequest_js_native_f32_1{arg_0}: emitter_body_js_native_f32_1(arg_0)
    case EmitterRequest_js_native_f32_2{arg_0}: emitter_body_js_native_f32_2(arg_0)
    case EmitterRequest_js_native_f32_extra{arg_0}: emitter_body_js_native_f32_extra(arg_0)
    case EmitterRequest_js_native_misc{arg_0}: emitter_body_js_native_misc(arg_0)
    case EmitterRequest_js_native_misc_1{arg_0}: emitter_body_js_native_misc_1(arg_0)
    case EmitterRequest_js_native_misc_2{arg_0}: emitter_body_js_native_misc_2(arg_0)
    case EmitterRequest_js_is_native{arg_0}: emitter_body_js_is_native(arg_0)
    case EmitterRequest_js_native_primitive{arg_0}: emitter_body_js_native_primitive(arg_0)
    case EmitterRequest_js_native_primitive_shape{arg_0}: emitter_body_js_native_primitive_shape(arg_0)
    case EmitterRequest_js_native_primitive_shape_match{arg_0, arg_1}: emitter_body_js_native_primitive_shape_match(arg_0, arg_1)
    case EmitterRequest_js_native_primitive_binary{arg_0}: emitter_body_js_native_primitive_binary(arg_0)
    case EmitterRequest_js_native_primitive_binary_match{arg_0, arg_1}: emitter_body_js_native_primitive_binary_match(arg_0, arg_1)
    case EmitterRequest_js_native_primitive_indexed{arg_0}: emitter_body_js_native_primitive_indexed(arg_0)
    case EmitterRequest_js_native_primitive_indexed_match{arg_0, arg_1}: emitter_body_js_native_primitive_indexed_match(arg_0, arg_1)
    case EmitterRequest_js_native_primitive_position{arg_0}: emitter_body_js_native_primitive_position(arg_0)
    case EmitterRequest_js_native_primitive_position_match{arg_0, arg_1}: emitter_body_js_native_primitive_position_match(arg_0, arg_1)
    case EmitterRequest_js_native_primitive_unary{arg_0}: emitter_body_js_native_primitive_unary(arg_0)
    case EmitterRequest_js_native_primitive_unary_match{arg_0, arg_1}: emitter_body_js_native_primitive_unary_match(arg_0, arg_1)
    case EmitterRequest_js_native_primitive_text{arg_0}: emitter_body_js_native_primitive_text(arg_0)
    case EmitterRequest_js_native_primitive_text_match{arg_0, arg_1}: emitter_body_js_native_primitive_text_match(arg_0, arg_1)
    case EmitterRequest_js_native_primitive_binders{arg_0}: emitter_body_js_native_primitive_binders(arg_0)
    case EmitterRequest_js_native_primitive_count{arg_0, arg_1}: emitter_body_js_native_primitive_count(arg_0, arg_1)
    case EmitterRequest_js_native_primitive_checked{arg_0, arg_1}: emitter_body_js_native_primitive_checked(arg_0, arg_1)
    case EmitterRequest_js_native_primitive_arity{arg_0, arg_1}: emitter_body_js_native_primitive_arity(arg_0, arg_1)
    case EmitterRequest_js_native_primitive_arity_match{arg_0, arg_1, arg_2}: emitter_body_js_native_primitive_arity_match(arg_0, arg_1, arg_2)
    case EmitterRequest_js_reference_old{arg_0}: emitter_body_js_reference_old(arg_0)
    case EmitterRequest_js_reference_2{arg_0}: emitter_body_js_reference_2(arg_0)
    case EmitterRequest_js_reference_3{arg_0}: emitter_body_js_reference_3(arg_0)
    case EmitterRequest_js_reference_4{arg_0}: emitter_body_js_reference_4(arg_0)
    case EmitterRequest_js_reference_5{arg_0}: emitter_body_js_reference_5(arg_0)
    case EmitterRequest_js_reference_6{arg_0}: emitter_body_js_reference_6(arg_0)
    case EmitterRequest_js_reference_7{arg_0}: emitter_body_js_reference_7(arg_0)
    case EmitterRequest_js_reference_8{arg_0}: emitter_body_js_reference_8(arg_0)
    case EmitterRequest_js_reference_nat_bounds{arg_0}: emitter_body_js_reference_nat_bounds(arg_0)
    case EmitterRequest_js_reference_9{arg_0}: emitter_body_js_reference_9(arg_0)
    case EmitterRequest_js_reference_10{arg_0}: emitter_body_js_reference_10(arg_0)
    case EmitterRequest_js_reference_11{arg_0}: emitter_body_js_reference_11(arg_0)
    case EmitterRequest_js_reference_12{arg_0}: emitter_body_js_reference_12(arg_0)
    case EmitterRequest_js_reference_more{arg_0}: emitter_body_js_reference_more(arg_0)
    case EmitterRequest_js_ref_f32_extra{arg_0}: emitter_body_js_ref_f32_extra(arg_0)
    case EmitterRequest_js_ref_u32{arg_0}: emitter_body_js_ref_u32(arg_0)
    case EmitterRequest_js_ref_u32_2{arg_0}: emitter_body_js_ref_u32_2(arg_0)
    case EmitterRequest_js_ref_u32_3{arg_0}: emitter_body_js_ref_u32_3(arg_0)
    case EmitterRequest_js_ref_f32{arg_0}: emitter_body_js_ref_f32(arg_0)
    case EmitterRequest_js_ref_f32_2{arg_0}: emitter_body_js_ref_f32_2(arg_0)
    case EmitterRequest_js_ref_f32_3{arg_0}: emitter_body_js_ref_f32_3(arg_0)
    case EmitterRequest_js_ref_nat{arg_0}: emitter_body_js_ref_nat(arg_0)
    case EmitterRequest_js_ref_strings{arg_0}: emitter_body_js_ref_strings(arg_0)
    case EmitterRequest_js_ref_array{arg_0}: emitter_body_js_ref_array(arg_0)
    case EmitterRequest_js_term{arg_0, arg_1}: emitter_body_js_term(arg_0, arg_1)
    case EmitterRequest_js_term_expected{arg_0, arg_1, arg_2}: emitter_body_js_term_expected(arg_0, arg_1, arg_2)

def emitter_step_group_3(request: EmitterRequestGroup3) -> EmitterProgress<emitter_result_group_3(request)>:
  match request:
    case EmitterRequest_js_term_tail_expected{arg_0, arg_1, arg_2}: emitter_body_js_term_tail_expected(arg_0, arg_1, arg_2)
    case EmitterRequest_js_statement_tail{arg_0, arg_1, arg_2}: emitter_body_js_statement_tail(arg_0, arg_1, arg_2)
    case EmitterRequest_js_statement_local{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_statement_local(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_statement_match{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_statement_match(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_statement_result{arg_0, arg_1, arg_2}: emitter_body_js_statement_result(arg_0, arg_1, arg_2)
    case EmitterRequest_js_app_spine{arg_0, arg_1, arg_2}: emitter_body_js_app_spine(arg_0, arg_1, arg_2)
    case EmitterRequest_js_app_spine_result{arg_0, arg_1, arg_2}: emitter_body_js_app_spine_result(arg_0, arg_1, arg_2)
    case EmitterRequest_js_app_dispatch{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_app_dispatch(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_named_owner{arg_0, arg_1}: emitter_body_js_named_owner(arg_0, arg_1)
    case EmitterRequest_js_named_fallback{arg_0, arg_1, arg_2}: emitter_body_js_named_fallback(arg_0, arg_1, arg_2)
    case EmitterRequest_js_named_lookup{arg_0, arg_1}: emitter_body_js_named_lookup(arg_0, arg_1)
    case EmitterRequest_js_named_layouts{arg_0, arg_1, arg_2}: emitter_body_js_named_layouts(arg_0, arg_1, arg_2)
    case EmitterRequest_js_named_next{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_named_next(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_named_declarations{arg_0, arg_1, arg_2}: emitter_body_js_named_declarations(arg_0, arg_1, arg_2)
    case EmitterRequest_js_named_native_law{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_named_native_law(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_named_app{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_named_app(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_named_app_found{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_named_app_found(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_named_native_law_app{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: emitter_body_js_named_native_law_app(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case EmitterRequest_js_named_app_native{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9}: emitter_body_js_named_app_native(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9)
    case EmitterRequest_js_native_app_args{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_native_app_args(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_named_app_eligible{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: emitter_body_js_named_app_eligible(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case EmitterRequest_js_named_tail_selected{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_named_tail_selected(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_named_tail{arg_0, arg_1}: emitter_body_js_named_tail(arg_0, arg_1)
    case EmitterRequest_js_named_app_args{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_named_app_args(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_named_args{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_named_args(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_named_arg{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_named_arg(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_app_spine_at{arg_0, arg_1}: emitter_body_js_app_spine_at(arg_0, arg_1)
    case EmitterRequest_js_app_chain_args{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_app_chain_args(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_app_chain{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_app_chain(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_app_arrow_env{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_app_arrow_env(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_app_arrow{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_app_arrow(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_app_quantity{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: emitter_body_js_app_quantity(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case EmitterRequest_js_lambda{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_lambda(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_lambda_view_env{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_lambda_view_env(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_lambda_view{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_lambda_view(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_binder_name{arg_0, arg_1}: emitter_body_js_binder_name(arg_0, arg_1)
    case EmitterRequest_js_lambda_untyped{arg_0, arg_1, arg_2}: emitter_body_js_lambda_untyped(arg_0, arg_1, arg_2)
    case EmitterRequest_js_lambda_quantity{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_lambda_quantity(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_closure{arg_0, arg_1}: emitter_body_js_closure(arg_0, arg_1)
    case EmitterRequest_env_depth{arg_0}: emitter_body_env_depth(arg_0)
    case EmitterRequest_env_reserve_names{arg_0, arg_1}: emitter_body_env_reserve_names(arg_0, arg_1)
    case EmitterRequest_js_term_sub{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_term_sub(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_term_let{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: emitter_body_js_term_let(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case EmitterRequest_js_body_local{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_body_local(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_body_local_constructor{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_body_local_constructor(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_constructor{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_constructor(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_constructor_literal{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_constructor_literal(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_native_word_literal{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_native_word_literal(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_native_word_declared{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_native_word_declared(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_word_literal_render{arg_0, arg_1}: emitter_body_js_word_literal_render(arg_0, arg_1)
    case EmitterRequest_js_word_identity{arg_0}: emitter_body_js_word_identity(arg_0)
    case EmitterRequest_js_closed_word{arg_0, arg_1, arg_2}: emitter_body_js_closed_word(arg_0, arg_1, arg_2)
    case EmitterRequest_js_closed_word_constructor{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_closed_word_constructor(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_closed_bit{arg_0, arg_1}: emitter_body_js_closed_bit(arg_0, arg_1)
    case EmitterRequest_js_closed_bit_identity{arg_0}: emitter_body_js_closed_bit_identity(arg_0)
    case EmitterRequest_js_closed_word_bit{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_closed_word_bit(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_closed_word_combine{arg_0, arg_1}: emitter_body_js_closed_word_combine(arg_0, arg_1)
    case EmitterRequest_js_string_literal{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_string_literal(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_string_literal_authorized{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_string_literal_authorized(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_string_literal_payload{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_string_literal_payload(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_string_scalar_chars{arg_0}: emitter_body_js_string_scalar_chars(arg_0)
    case EmitterRequest_js_string_scalar_char{arg_0, arg_1, arg_2}: emitter_body_js_string_scalar_char(arg_0, arg_1, arg_2)
    case EmitterRequest_js_string_scalar_cons{arg_0, arg_1}: emitter_body_js_string_scalar_cons(arg_0, arg_1)
    case EmitterRequest_js_string_names_native{arg_0, arg_1}: emitter_body_js_string_names_native(arg_0, arg_1)

def emitter_step_group_4(request: EmitterRequestGroup4) -> EmitterProgress<emitter_result_group_4(request)>:
  match request:
    case EmitterRequest_js_string_constructor_native{arg_0, arg_1, arg_2}: emitter_body_js_string_constructor_native(arg_0, arg_1, arg_2)
    case EmitterRequest_js_string_constructor_schema{arg_0, arg_1, arg_2}: emitter_body_js_string_constructor_schema(arg_0, arg_1, arg_2)
    case EmitterRequest_js_string_schema_owner{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_string_schema_owner(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_string_schema_global{arg_0, arg_1, arg_2}: emitter_body_js_string_schema_global(arg_0, arg_1, arg_2)
    case EmitterRequest_js_string_schema_decl{arg_0, arg_1, arg_2}: emitter_body_js_string_schema_decl(arg_0, arg_1, arg_2)
    case EmitterRequest_js_string_schema_fields{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_string_schema_fields(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_string_schema_nat{arg_0, arg_1, arg_2}: emitter_body_js_string_schema_nat(arg_0, arg_1, arg_2)
    case EmitterRequest_js_string_schema_ref{arg_0, arg_1, arg_2}: emitter_body_js_string_schema_ref(arg_0, arg_1, arg_2)
    case EmitterRequest_js_string_schema_key{arg_0, arg_1, arg_2}: emitter_body_js_string_schema_key(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_args{arg_0, arg_1, arg_2}: emitter_body_js_constructor_args(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_arg_view_env{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_constructor_arg_view_env(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_constructor_arg_view{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_constructor_arg_view(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_constructor_arg_quantity{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_constructor_arg_quantity(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_constructor_native{arg_0}: emitter_body_js_constructor_native(arg_0)
    case EmitterRequest_js_constructor_native_identity_found{arg_0, arg_1}: emitter_body_js_constructor_native_identity_found(arg_0, arg_1)
    case EmitterRequest_js_constructor_native_identity{arg_0, arg_1}: emitter_body_js_constructor_native_identity(arg_0, arg_1)
    case EmitterRequest_js_constructor_native_origin{arg_0, arg_1, arg_2}: emitter_body_js_constructor_native_origin(arg_0, arg_1, arg_2)
    case EmitterRequest_js_base_origin{arg_0}: emitter_body_js_base_origin(arg_0)
    case EmitterRequest_js_base_source_suffix{arg_0, arg_1}: emitter_body_js_base_source_suffix(arg_0, arg_1)
    case EmitterRequest_js_base_source_exact{arg_0, arg_1, arg_2}: emitter_body_js_base_source_exact(arg_0, arg_1, arg_2)
    case EmitterRequest_js_base_source{arg_0, arg_1}: emitter_body_js_base_source(arg_0, arg_1)
    case EmitterRequest_js_base_imported{arg_0}: emitter_body_js_base_imported(arg_0)
    case EmitterRequest_js_base_imported_next{arg_0, arg_1}: emitter_body_js_base_imported_next(arg_0, arg_1)
    case EmitterRequest_js_base_imports{arg_0}: emitter_body_js_base_imports(arg_0)
    case EmitterRequest_js_base_imports_next{arg_0, arg_1}: emitter_body_js_base_imports_next(arg_0, arg_1)
    case EmitterRequest_js_source_at{arg_0, arg_1}: emitter_body_js_source_at(arg_0, arg_1)
    case EmitterRequest_js_sources{arg_0}: emitter_body_js_sources(arg_0)
    case EmitterRequest_js_constructor_render{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_constructor_render(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_constructor_record{arg_0, arg_1, arg_2}: emitter_body_js_constructor_record(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_record_exact{arg_0, arg_1}: emitter_body_js_constructor_record_exact(arg_0, arg_1)
    case EmitterRequest_js_constructor_record_fields{arg_0, arg_1}: emitter_body_js_constructor_record_fields(arg_0, arg_1)
    case EmitterRequest_js_constructor_record_field{arg_0, arg_1, arg_2}: emitter_body_js_constructor_record_field(arg_0, arg_1, arg_2)
    case EmitterRequest_js_object_key{arg_0}: emitter_body_js_object_key(arg_0)
    case EmitterRequest_ctor_short{arg_0}: emitter_body_ctor_short(arg_0)
    case EmitterRequest_ctor_short_chars{arg_0, arg_1}: emitter_body_ctor_short_chars(arg_0, arg_1)
    case EmitterRequest_js_match{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_match(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_pattern_test{arg_0, arg_1, arg_2}: emitter_body_pattern_test(arg_0, arg_1, arg_2)
    case EmitterRequest_pattern_test_constructor{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_constructor(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_constructor_tagged{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: emitter_body_pattern_test_constructor_tagged(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case EmitterRequest_pattern_test_native_literal{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: emitter_body_pattern_test_native_literal(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case EmitterRequest_pattern_test_native_bits{arg_0, arg_1, arg_2}: emitter_body_pattern_test_native_bits(arg_0, arg_1, arg_2)
    case EmitterRequest_js_native_word_pattern{arg_0, arg_1, arg_2}: emitter_body_js_native_word_pattern(arg_0, arg_1, arg_2)
    case EmitterRequest_js_closed_word_pattern{arg_0, arg_1, arg_2}: emitter_body_js_closed_word_pattern(arg_0, arg_1, arg_2)
    case EmitterRequest_js_closed_word_pattern_constructor{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_closed_word_pattern_constructor(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_closed_bit_pattern{arg_0, arg_1}: emitter_body_js_closed_bit_pattern(arg_0, arg_1)
    case EmitterRequest_js_closed_word_pattern_bit{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_closed_word_pattern_bit(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_field_projection{arg_0, arg_1}: emitter_body_js_field_projection(arg_0, arg_1)
    case EmitterRequest_pattern_decl_fields_test{arg_0, arg_1, arg_2, arg_3}: emitter_body_pattern_decl_fields_test(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_pattern_test_ctor{arg_0, arg_1, arg_2, arg_3}: emitter_body_pattern_test_ctor(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_pattern_test_true{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_true(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_false{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_false(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_zero{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_zero(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_succ{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_succ(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_snil{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_snil(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_scon{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_scon(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_u32{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_u32(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_f32{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_f32(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_aleaf{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_aleaf(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_anode{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_anode(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_test_char{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_test_char(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_fields_test{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_fields_test(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_patterns_test{arg_0, arg_1, arg_2}: emitter_body_patterns_test(arg_0, arg_1, arg_2)
    case EmitterRequest_pattern_vars{arg_0, arg_1, arg_2}: emitter_body_pattern_vars(arg_0, arg_1, arg_2)
    case EmitterRequest_pattern_vars_constructor{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_vars_constructor(arg_0, arg_1, arg_2, arg_3, arg_4)

def emitter_step_group_5(request: EmitterRequestGroup5) -> EmitterProgress<emitter_result_group_5(request)>:
  match request:
    case EmitterRequest_pattern_vars_constructor_tagged{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_pattern_vars_constructor_tagged(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_pattern_erased_vars{arg_0}: emitter_body_pattern_erased_vars(arg_0)
    case EmitterRequest_patterns_erased_vars{arg_0}: emitter_body_patterns_erased_vars(arg_0)
    case EmitterRequest_pattern_decl_fields_vars{arg_0, arg_1, arg_2, arg_3}: emitter_body_pattern_decl_fields_vars(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_pattern_vars_ctr{arg_0, arg_1, arg_2, arg_3}: emitter_body_pattern_vars_ctr(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_pattern_vars_succ{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_vars_succ(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_vars_scon{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_vars_scon(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_vars_char{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_vars_char(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_vars_u32{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_vars_u32(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_vars_f32{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_vars_f32(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_vars_aleaf{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_vars_aleaf(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_vars_anode{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_vars_anode(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_pattern_array_field_value{arg_0, arg_1}: emitter_body_pattern_array_field_value(arg_0, arg_1)
    case EmitterRequest_pattern_array_fields{arg_0, arg_1, arg_2, arg_3}: emitter_body_pattern_array_fields(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_pattern_string_field_value{arg_0, arg_1}: emitter_body_pattern_string_field_value(arg_0, arg_1)
    case EmitterRequest_pattern_string_fields{arg_0, arg_1, arg_2, arg_3}: emitter_body_pattern_string_fields(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_pattern_fields_vars{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_pattern_fields_vars(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_positional_projection{arg_0, arg_1, arg_2}: emitter_body_js_positional_projection(arg_0, arg_1, arg_2)
    case EmitterRequest_patterns_vars{arg_0, arg_1, arg_2}: emitter_body_patterns_vars(arg_0, arg_1, arg_2)
    case EmitterRequest_js_case{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_case(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_case_typed{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_case_typed(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_case_block_typed{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_case_block_typed(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_case_binding_names{arg_0, arg_1}: emitter_body_js_case_binding_names(arg_0, arg_1)
    case EmitterRequest_js_case_binding_name{arg_0, arg_1}: emitter_body_js_case_binding_name(arg_0, arg_1)
    case EmitterRequest_js_case_bindings{arg_0, arg_1}: emitter_body_js_case_bindings(arg_0, arg_1)
    case EmitterRequest_js_case_binding_source{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_case_binding_source(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_cases{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_cases(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_switch_tags{arg_0, arg_1, arg_2}: emitter_body_js_switch_tags(arg_0, arg_1, arg_2)
    case EmitterRequest_js_switch_fields{arg_0}: emitter_body_js_switch_fields(arg_0)
    case EmitterRequest_js_switch_tag_constructor{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_switch_tag_constructor(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_switch_tag_fields{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_switch_tag_fields(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_switch_tag_seen{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_switch_tag_seen(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_switch_tag_native{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_switch_tag_native(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_switch_tag_ordered{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_switch_tag_ordered(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_switch_bmp_tag{arg_0}: emitter_body_js_switch_bmp_tag(arg_0)
    case EmitterRequest_js_switch_bmp_tail{arg_0, arg_1}: emitter_body_js_switch_bmp_tail(arg_0, arg_1)
    case EmitterRequest_js_switch_tag_rest{arg_0, arg_1}: emitter_body_js_switch_tag_rest(arg_0, arg_1)
    case EmitterRequest_js_switch_cases{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_switch_cases(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_switch_pairs{arg_0, arg_1}: emitter_body_js_switch_pairs(arg_0, arg_1)
    case EmitterRequest_js_switch_row_le{arg_0, arg_1}: emitter_body_js_switch_row_le(arg_0, arg_1)
    case EmitterRequest_js_switch_sort{arg_0, arg_1}: emitter_body_js_switch_sort(arg_0, arg_1)
    case EmitterRequest_js_switch_merge{arg_0, arg_1}: emitter_body_js_switch_merge(arg_0, arg_1)
    case EmitterRequest_js_switch_merge_right{arg_0, arg_1, arg_2}: emitter_body_js_switch_merge_right(arg_0, arg_1, arg_2)
    case EmitterRequest_js_switch_merge_order{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_switch_merge_order(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_switch_tree{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: emitter_body_js_switch_tree(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case EmitterRequest_js_switch_tree_leaf{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_switch_tree_leaf(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_switch_tree_split{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: emitter_body_js_switch_tree_split(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case EmitterRequest_js_cases_dispatch_size{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: emitter_body_js_cases_dispatch_size(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case EmitterRequest_js_cases_dispatch_values{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_cases_dispatch_values(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_cases_dispatch{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_cases_dispatch(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_cases_dispatch_switch{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: emitter_body_js_cases_dispatch_switch(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case EmitterRequest_js_scrutinees{arg_0, arg_1, arg_2}: emitter_body_js_scrutinees(arg_0, arg_1, arg_2)
    case EmitterRequest_scrutinee_names{arg_0, arg_1}: emitter_body_scrutinee_names(arg_0, arg_1)
    case EmitterRequest_scrutinee_names_at{arg_0, arg_1}: emitter_body_scrutinee_names_at(arg_0, arg_1)
    case EmitterRequest_js_body_match{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_body_match(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_binders{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_binders(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_decl{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_decl(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_decl_term{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_decl_term(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_decl_term_operation{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_decl_term_operation(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_named_eligible{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_named_eligible(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_named_eligible_operation{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_named_eligible_operation(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_named_fixed{arg_0, arg_1}: emitter_body_js_named_fixed(arg_0, arg_1)
    case EmitterRequest_js_decl_named{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_decl_named(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_named_body{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_named_body(arg_0, arg_1, arg_2, arg_3, arg_4)

def emitter_step_group_6(request: EmitterRequestGroup6) -> EmitterProgress<emitter_result_group_6(request)>:
  match request:
    case EmitterRequest_js_named_facade{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_named_facade(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_decl_native_law{arg_0, arg_1, arg_2}: emitter_body_js_decl_native_law(arg_0, arg_1, arg_2)
    case EmitterRequest_js_decl_native_value{arg_0, arg_1, arg_2}: emitter_body_js_decl_native_value(arg_0, arg_1, arg_2)
    case EmitterRequest_js_decl_native_runtime{arg_0, arg_1, arg_2}: emitter_body_js_decl_native_runtime(arg_0, arg_1, arg_2)
    case EmitterRequest_js_native_facade{arg_0, arg_1, arg_2}: emitter_body_js_native_facade(arg_0, arg_1, arg_2)
    case EmitterRequest_js_definition_has_live_binder{arg_0}: emitter_body_js_definition_has_live_binder(arg_0)
    case EmitterRequest_js_decl_value{arg_0, arg_1, arg_2}: emitter_body_js_decl_value(arg_0, arg_1, arg_2)
    case EmitterRequest_js_decl_deferred_value{arg_0, arg_1}: emitter_body_js_decl_deferred_value(arg_0, arg_1)
    case EmitterRequest_js_definition_is_type{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_definition_is_type(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_inferred_is_sort{arg_0}: emitter_body_js_inferred_is_sort(arg_0)
    case EmitterRequest_js_type_is_sort{arg_0}: emitter_body_js_type_is_sort(arg_0)
    case EmitterRequest_js_live_binders{arg_0}: emitter_body_js_live_binders(arg_0)
    case EmitterRequest_js_foreign{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_foreign(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_foreign_path{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_foreign_path(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_decls{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_decls(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_alias_namespace{arg_0, arg_1, arg_2}: emitter_body_alias_namespace(arg_0, arg_1, arg_2)
    case EmitterRequest_alias_namespace_base{arg_0, arg_1, arg_2, arg_3}: emitter_body_alias_namespace_base(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_alias_namespace_found{arg_0}: emitter_body_alias_namespace_found(arg_0)
    case EmitterRequest_js_resolved_alias_entries{arg_0, arg_1}: emitter_body_js_resolved_alias_entries(arg_0, arg_1)
    case EmitterRequest_js_resolved_aliases{arg_0, arg_1, arg_2}: emitter_body_js_resolved_aliases(arg_0, arg_1, arg_2)
    case EmitterRequest_js_aliases{arg_0}: emitter_body_js_aliases(arg_0)
    case EmitterRequest_js_alias_source{arg_0}: emitter_body_js_alias_source(arg_0)
    case EmitterRequest_js_alias_entries{arg_0}: emitter_body_js_alias_entries(arg_0)
    case EmitterRequest_js_module{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_module(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_modules{arg_0, arg_1}: emitter_body_js_modules(arg_0, arg_1)
    case EmitterRequest_js_modules_at{arg_0, arg_1, arg_2}: emitter_body_js_modules_at(arg_0, arg_1, arg_2)
    case EmitterRequest_qualify{arg_0, arg_1}: emitter_body_qualify(arg_0, arg_1)
    case EmitterRequest_qualify_result{arg_0, arg_1, arg_2}: emitter_body_qualify_result(arg_0, arg_1, arg_2)
    case EmitterRequest_first_span{arg_0, arg_1}: emitter_body_first_span(arg_0, arg_1)
    case EmitterRequest_error_terms{arg_0}: emitter_body_error_terms(arg_0)
    case EmitterRequest_error_term{arg_0}: emitter_body_error_term(arg_0)
    case EmitterRequest_error_optional_term{arg_0}: emitter_body_error_optional_term(arg_0)
    case EmitterRequest_error_def_body{arg_0}: emitter_body_error_def_body(arg_0)
    case EmitterRequest_error_decl{arg_0}: emitter_body_error_decl(arg_0)
    case EmitterRequest_error_binders{arg_0}: emitter_body_error_binders(arg_0)
    case EmitterRequest_error_constructors{arg_0}: emitter_body_error_constructors(arg_0)
    case EmitterRequest_error_condition{arg_0}: emitter_body_error_condition(arg_0)
    case EmitterRequest_error_clauses{arg_0}: emitter_body_error_clauses(arg_0)
    case EmitterRequest_error_decls{arg_0}: emitter_body_error_decls(arg_0)
    case EmitterRequest_error_modules{arg_0}: emitter_body_error_modules(arg_0)
    case EmitterRequest_template_terms{arg_0}: emitter_body_template_terms(arg_0)
    case EmitterRequest_template_term{arg_0}: emitter_body_template_term(arg_0)
    case EmitterRequest_template_binders{arg_0}: emitter_body_template_binders(arg_0)
    case EmitterRequest_template_constructors{arg_0}: emitter_body_template_constructors(arg_0)
    case EmitterRequest_template_condition{arg_0}: emitter_body_template_condition(arg_0)
    case EmitterRequest_template_clauses{arg_0}: emitter_body_template_clauses(arg_0)
    case EmitterRequest_template_optional_term{arg_0}: emitter_body_template_optional_term(arg_0)
    case EmitterRequest_template_def_body{arg_0}: emitter_body_template_def_body(arg_0)
    case EmitterRequest_template_decl{arg_0}: emitter_body_template_decl(arg_0)
    case EmitterRequest_template_decls{arg_0}: emitter_body_template_decls(arg_0)
    case EmitterRequest_template_modules{arg_0}: emitter_body_template_modules(arg_0)
    case EmitterRequest_has_js_import{arg_0}: emitter_body_has_js_import(arg_0)
    case EmitterRequest_foreign_error_decl{arg_0}: emitter_body_foreign_error_decl(arg_0)
    case EmitterRequest_foreign_error_js{arg_0, arg_1}: emitter_body_foreign_error_js(arg_0, arg_1)
    case EmitterRequest_foreign_error_decls{arg_0}: emitter_body_foreign_error_decls(arg_0)
    case EmitterRequest_foreign_error_modules{arg_0}: emitter_body_foreign_error_modules(arg_0)
    case EmitterRequest_js_runtime{}: emitter_body_js_runtime()
    case EmitterRequest_js_runtime_extra{}: emitter_body_js_runtime_extra()
    case EmitterRequest_js_runtime_array{}: emitter_body_js_runtime_array()
    case EmitterRequest_js_runtime_foreign{}: emitter_body_js_runtime_foreign()
    case EmitterRequest_js_runtime_namespace{}: emitter_body_js_runtime_namespace()
    case EmitterRequest_js_runtime_field_names{arg_0}: emitter_body_js_runtime_field_names(arg_0)
    case EmitterRequest_js_runtime_field_names_at{arg_0, arg_1}: emitter_body_js_runtime_field_names_at(arg_0, arg_1)
    case EmitterRequest_js_constructor_fields_one{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_constructor_fields_one(arg_0, arg_1, arg_2, arg_3)

def emitter_step_group_7(request: EmitterRequestGroup7) -> EmitterProgress<emitter_result_group_7(request)>:
  match request:
    case EmitterRequest_js_constructor_fields_constructors{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_constructor_fields_constructors(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_constructor_fields_decl{arg_0, arg_1, arg_2}: emitter_body_js_constructor_fields_decl(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_fields_decls{arg_0, arg_1, arg_2}: emitter_body_js_constructor_fields_decls(arg_0, arg_1, arg_2)
    case EmitterRequest_js_constructor_fields_modules{arg_0}: emitter_body_js_constructor_fields_modules(arg_0)
    case EmitterRequest_js_constructor_fields_modules_at{arg_0, arg_1}: emitter_body_js_constructor_fields_modules_at(arg_0, arg_1)
    case EmitterRequest_js_type_ref{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_ref(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_args{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_args(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_sugar_descriptor{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_type_sugar_descriptor(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_type_sugar{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_js_type_sugar(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_js_type_term{arg_0, arg_1, arg_2}: emitter_body_js_type_term(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_quantity{arg_0}: emitter_body_js_type_quantity(arg_0)
    case EmitterRequest_js_type_optional_quantity{arg_0}: emitter_body_js_type_optional_quantity(arg_0)
    case EmitterRequest_js_type_binary{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_type_binary(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_type_constructor{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_constructor(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_application{arg_0, arg_1, arg_2}: emitter_body_js_type_application(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_application_args{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_application_args(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_let{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_let(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_patterns_source{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_patterns_source(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_pattern_source{arg_0, arg_1, arg_2}: emitter_body_js_type_pattern_source(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_cases_source{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_cases_source(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_field_terms{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_field_terms(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_arm{arg_0, arg_1, arg_2}: emitter_body_js_type_arm(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_field_quantities{arg_0, arg_1}: emitter_body_js_type_field_quantities(arg_0, arg_1)
    case EmitterRequest_js_type_arms{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_arms(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_decl{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_decl(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_native_marker{arg_0, arg_1}: emitter_body_js_type_native_marker(arg_0, arg_1)
    case EmitterRequest_js_type_decls{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_decls(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_modules{arg_0, arg_1}: emitter_body_js_type_modules(arg_0, arg_1)
    case EmitterRequest_js_type_modules_needed{arg_0, arg_1, arg_2}: emitter_body_js_type_modules_needed(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_modules_at{arg_0, arg_1, arg_2}: emitter_body_js_type_modules_at(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_needed_ref{arg_0, arg_1, arg_2}: emitter_body_js_type_needed_ref(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_needed_found{arg_0, arg_1}: emitter_body_js_type_needed_found(arg_0, arg_1)
    case EmitterRequest_js_type_needed_definition{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_type_needed_definition(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_type_needed_terms{arg_0, arg_1, arg_2}: emitter_body_js_type_needed_terms(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_needed_term{arg_0, arg_1, arg_2}: emitter_body_js_type_needed_term(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_needed_binders{arg_0, arg_1, arg_2}: emitter_body_js_type_needed_binders(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_needed_result{arg_0, arg_1, arg_2}: emitter_body_js_type_needed_result(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_needed_constructors{arg_0, arg_1, arg_2}: emitter_body_js_type_needed_constructors(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_needed_declarations{arg_0, arg_1, arg_2}: emitter_body_js_type_needed_declarations(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_needed_definition_root{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_js_type_needed_definition_root(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_js_type_needed_definition_root_kind{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_needed_definition_root_kind(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_needed_modules{arg_0, arg_1, arg_2}: emitter_body_js_type_needed_modules(arg_0, arg_1, arg_2)
    case EmitterRequest_js_type_needed_modules_at{arg_0, arg_1, arg_2, arg_3}: emitter_body_js_type_needed_modules_at(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_type_function_sources{arg_0}: emitter_body_js_type_function_sources(arg_0)
    case EmitterRequest_main_type_expr_declaration{arg_0, arg_1, arg_2}: emitter_body_main_type_expr_declaration(arg_0, arg_1, arg_2)
    case EmitterRequest_main_type_expr_is_main{arg_0, arg_1, arg_2, arg_3}: emitter_body_main_type_expr_is_main(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_main_type_expr_declarations{arg_0, arg_1, arg_2}: emitter_body_main_type_expr_declarations(arg_0, arg_1, arg_2)
    case EmitterRequest_main_type_expr_declaration_result{arg_0, arg_1, arg_2, arg_3}: emitter_body_main_type_expr_declaration_result(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_main_type_expr_declaration_empty{arg_0, arg_1, arg_2, arg_3, arg_4}: emitter_body_main_type_expr_declaration_empty(arg_0, arg_1, arg_2, arg_3, arg_4)
    case EmitterRequest_main_type_expr_modules{arg_0, arg_1}: emitter_body_main_type_expr_modules(arg_0, arg_1)
    case EmitterRequest_main_type_expr_modules_at{arg_0, arg_1}: emitter_body_main_type_expr_modules_at(arg_0, arg_1)
    case EmitterRequest_main_type_expr_module_scope{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: emitter_body_main_type_expr_module_scope(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case EmitterRequest_main_type_expr_module_result{arg_0, arg_1, arg_2}: emitter_body_main_type_expr_module_result(arg_0, arg_1, arg_2)
    case EmitterRequest_main_type_expr_module_empty{arg_0, arg_1, arg_2, arg_3}: emitter_body_main_type_expr_module_empty(arg_0, arg_1, arg_2, arg_3)
    case EmitterRequest_js_runtime_cli{}: emitter_body_js_runtime_cli()
    case EmitterRequest_js_runtime_io{}: emitter_body_js_runtime_io()
    case EmitterRequest_js_runtime_show{}: emitter_body_js_runtime_show()
    case EmitterRequest_js_runtime_type{}: emitter_body_js_runtime_type()
    case EmitterRequest_js_runtime_type_names{}: emitter_body_js_runtime_type_names()
    case EmitterRequest_js_runtime_type_patterns{}: emitter_body_js_runtime_type_patterns()
    case EmitterRequest_js_runtime_type_eval{}: emitter_body_js_runtime_type_eval()
    case EmitterRequest_js_runtime_native_type{}: emitter_body_js_runtime_native_type()
    case EmitterRequest_js_main{arg_0}: emitter_body_js_main(arg_0)
    case EmitterRequest_emit{arg_0}: emitter_body_emit(arg_0)

def emitter_step_group_8(request: EmitterRequestGroup8) -> EmitterProgress<emitter_result_group_8(request)>:
  match request:
    case EmitterRequest_js_emit_template{arg_0, arg_1, arg_2}: emitter_body_js_emit_template(arg_0, arg_1, arg_2)
    case EmitterRequest_js_emit_holes{arg_0, arg_1, arg_2}: emitter_body_js_emit_holes(arg_0, arg_1, arg_2)
    case EmitterRequest_js_emit_foreign{arg_0, arg_1, arg_2}: emitter_body_js_emit_foreign(arg_0, arg_1, arg_2)
    case EmitterRequest_js_library_exports{arg_0}: emitter_body_js_library_exports(arg_0)
    case EmitterRequest_js_library_export_fields{arg_0}: emitter_body_js_library_export_fields(arg_0)
    case EmitterRequest_emit_library{arg_0, arg_1}: emitter_body_emit_library(arg_0, arg_1)
    case EmitterRequest_js_emit_ending{arg_0, arg_1, arg_2}: emitter_body_js_emit_ending(arg_0, arg_1, arg_2)

def emitter_step(request: EmitterRequest) -> EmitterProgress<emitter_result(request)>:
  match request:
    case EmitterRequestGroup_0{inner}: emitter_step_group_0(inner)
    case EmitterRequestGroup_1{inner}: emitter_step_group_1(inner)
    case EmitterRequestGroup_2{inner}: emitter_step_group_2(inner)
    case EmitterRequestGroup_3{inner}: emitter_step_group_3(inner)
    case EmitterRequestGroup_4{inner}: emitter_step_group_4(inner)
    case EmitterRequestGroup_5{inner}: emitter_step_group_5(inner)
    case EmitterRequestGroup_6{inner}: emitter_step_group_6(inner)
    case EmitterRequestGroup_7{inner}: emitter_step_group_7(inner)
    case EmitterRequestGroup_8{inner}: emitter_step_group_8(inner)

def emitter_start(modules: List<&2, Loader.LoadedModule>) -> EmitterProgress<EmitResult>:
  EmitterPending{EmitterRequestGroup_7{EmitterRequest_emit{modules}}, +result => EmitterFinished{result}}
