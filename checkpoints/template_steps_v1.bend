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


# Bounded typed request groups; every source declaration retains its checked signature.
type TemplateRequestGroup0 is Type:
  TemplateRequest_span_of{v_0: Ast.SyntaxTerm}
  TemplateRequest_collect_templates{v_1: List<&2, Loader.LoadedModule>}
  TemplateRequest_top_keys{v_1: List<&2, Ast.TopLevel>}
  TemplateRequest_collect_template_decls{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, String>, v_8: List<&2, Ast.TopLevel>}
  TemplateRequest_collect_template_decl{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, String>, v_8: String, v_10: List<&2, Ast.TelescopeItem>, v_11: Ast.OptionalTerm, v_12: Ast.DefBody, v_14: Bool, v_15: Ast.SourceSpan, v_17: List<&2, Ast.TopLevel>, v_19: Bool}
  TemplateRequest_has_template_binder{v_1: List<&2, Ast.TelescopeItem>}
  TemplateRequest_qualify{v_1: String, v_3: String}
  TemplateRequest_qualify_match{v_1: String, v_3: String, v_5: Bool}
  TemplateRequest_find_template{v_1: String, v_4: List<&2, TemplateDef>}
  TemplateRequest_find_template_match{v_1: String, v_3: TemplateDef, v_6: List<&2, TemplateDef>, v_8: Bool}
  TemplateRequest_flatten_application{v_0: Ast.SyntaxTerm}
  TemplateRequest_flatten_append{v_1: ApplicationSpine, v_2: Ast.SyntaxTerm, v_3: Ast.SourceSpan}
  TemplateRequest_leading_template_count{v_1: List<&2, Ast.TelescopeItem>}
  TemplateRequest_template_for_head{v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>}
  TemplateRequest_take_template_args{v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat}
  TemplateRequest_take_template_arg{v_0: Ast.SyntaxTerm, v_3: Maybe<&2, List<&2, Ast.SyntaxTerm>>}
  TemplateRequest_reapply_args{v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>, v_3: Ast.SourceSpan}
  TemplateRequest_generated_local_key{v_1: TemplateDef, v_3: List<&2, Ast.SyntaxTerm>}
  TemplateRequest_generated_local_key_for_identity{v_1: TemplateDef, v_3: String}
  TemplateRequest_fresh_generated_key{v_1: String, v_4: List<&2, String>, v_6: Nat}
  TemplateRequest_fresh_generated_key_match{v_1: String, v_4: List<&2, String>, v_6: Nat, v_8: String, v_10: Bool}
  TemplateRequest_generated_candidate{v_1: String, v_3: Nat}
  TemplateRequest_generated_canonical_key{v_1: TemplateDef, v_3: String}
  TemplateRequest_generated_key{v_1: TemplateDef, v_3: List<&2, Ast.SyntaxTerm>}
  TemplateRequest_encode_string{v_1: String}
  TemplateRequest_encode_quantity{v_0: Ast.Quantity}
  TemplateRequest_serialize_strings{v_2: List<&2, String>}
  TemplateRequest_serialize_nats{v_2: List<&2, Nat>}
  TemplateRequest_serialize_quantities{v_1: List<&2, Ast.Quantity>}
  TemplateRequest_serialize_patterns{v_1: List<&2, Ast.SyntaxPattern>}
  TemplateRequest_serialize_pattern{v_0: Ast.SyntaxPattern}
  TemplateRequest_serialize_terms{v_1: List<&2, Ast.SyntaxTerm>}
  TemplateRequest_serialize_term{v_0: Ast.SyntaxTerm}
  TemplateRequest_serialize_optional_quantity{v_1: Maybe<&2, Ast.Quantity>}
  TemplateRequest_strip_namespace{v_1: String, v_3: String}
  TemplateRequest_strip_namespace_match{v_1: String, v_3: String, v_5: Bool}
  TemplateRequest_strip_namespace_prefix{v_1: String, v_3: String}
  TemplateRequest_strip_namespace_prefix_match{v_1: String, v_3: String, v_5: Bool}
  TemplateRequest_template_capture_names{v_1: TemplateDef}
  TemplateRequest_scoped_templates{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, TemplateDef>, v_8: List<&2, Loader.LoadedModule>}
  TemplateRequest_templates_with_captures{v_2: List<&2, TemplateDef>, v_5: List<&2, CaptureName>}
  TemplateRequest_scope_capture_names{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: List<&2, Loader.LoadedModule>}
  TemplateRequest_capture_import_names{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: List<&2, Loader.LoadedModule>}
  TemplateRequest_capture_module_names{v_1: String, v_3: String, v_5: List<&2, Loader.LoadedModule>}
  TemplateRequest_capture_declaration_names{v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>}
  TemplateRequest_capture_constructor_names{v_1: String, v_3: String, v_5: List<&2, Ast.ConstructorDecl>}
  TemplateRequest_capture_declared_name{v_1: String, v_3: String, v_5: String, v_7: Bool, v_9: Bool, v_12: List<&2, CaptureName>}
  TemplateRequest_capture_name{v_1: String, v_3: Bool, v_6: List<&2, CaptureName>, v_9: Maybe<&2, String>}
  TemplateRequest_capture_key{v_1: String, v_3: Bool, v_6: List<&2, CaptureName>}
  TemplateRequest_capture_strings{v_2: List<&2, String>, v_5: List<&2, CaptureName>}
  TemplateRequest_capture_patterns{v_1: List<&2, Ast.SyntaxPattern>, v_4: List<&2, CaptureName>}
  TemplateRequest_capture_pattern{v_0: Ast.SyntaxPattern, v_3: List<&2, CaptureName>}
  TemplateRequest_capture_terms{v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, CaptureName>}
  TemplateRequest_reference_key{v_1: String}
  TemplateRequest_capture_string_names{v_0: Ast.StringLiteralNames, +v_3: List<&2, CaptureName>}
  TemplateRequest_capture_term{v_0: Ast.SyntaxTerm, v_3: List<&2, CaptureName>}
  TemplateRequest_expand_term{v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>}
  TemplateRequest_expand_stable_term{v_0: Ast.SyntaxTerm}
  TemplateRequest_expand_stable_terms{v_1: List<&2, Ast.SyntaxTerm>}
  TemplateRequest_expand_stable_tail{v_1: Bool, v_3: List<&2, Ast.SyntaxTerm>}
  TemplateRequest_expand_constructor_stable{v_1: Bool, v_2: Ast.SyntaxTerm, v_4: String, v_6: List<&2, Ast.SyntaxTerm>, v_7: Ast.SourceSpan, v_10: List<&2, TemplateDef>}
  TemplateRequest_expand_application{v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>}
  TemplateRequest_expand_application_spine{v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>, v_7: ApplicationSpine}
  TemplateRequest_expand_application_template{v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>, v_6: Ast.SyntaxTerm, v_8: List<&2, Ast.SyntaxTerm>, v_11: Maybe<&2, TemplateDef>}

type TemplateRequestGroup1 is Type:
  TemplateRequest_template_arity{v_1: TemplateDef}
  TemplateRequest_expand_application_arguments{v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>, v_6: Ast.SyntaxTerm, v_8: List<&2, Ast.SyntaxTerm>, v_10: TemplateDef, v_12: Nat, v_15: Maybe<&2, List<&2, Ast.SyntaxTerm>>}
  TemplateRequest_specialize_head{v_0: Ast.SyntaxTerm, v_2: String}
  TemplateRequest_drop_args{v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat}
  TemplateRequest_specialize_definition{v_1: TemplateDef, v_3: String, v_5: List<&2, Ast.SyntaxTerm>}
  TemplateRequest_specialize_definition_result{v_1: String, v_3: Bool, v_4: Ast.SourceSpan, v_6: Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))}
  TemplateRequest_specialize_prefix{v_1: List<&2, Ast.TelescopeItem>, v_3: List<&2, Ast.SyntaxTerm>, v_4: Ast.OptionalTerm, v_5: Ast.DefBody}
  TemplateRequest_binder_count{v_1: List<&2, Ast.TelescopeItem>}
  TemplateRequest_substitute_binders{v_1: List<&2, Ast.TelescopeItem>, v_3: Nat, v_4: Ast.SyntaxTerm}
  TemplateRequest_substitute_optional{v_0: Ast.OptionalTerm, v_2: Nat, v_3: Ast.SyntaxTerm}
  TemplateRequest_substitute_body{v_0: Ast.DefBody, v_2: Nat, v_3: Ast.SyntaxTerm}
  TemplateRequest_expand_terms{v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, TemplateDef>}
  TemplateRequest_strip_template_decls{v_1: String, v_3: List<&2, Ast.TopLevel>, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>}
  TemplateRequest_strip_template_definition{v_1: String, v_3: String, v_5: List<&2, Ast.TelescopeItem>, v_6: Ast.OptionalTerm, v_7: Ast.DefBody, v_9: Bool, v_10: Ast.SourceSpan, v_12: List<&2, Ast.TopLevel>, v_15: List<&2, TemplateDef>, v_18: List<&2, GeneratedIdentity>, v_20: Bool}
  TemplateRequest_strip_canonical_template{v_1: String, v_3: List<&2, Ast.TopLevel>, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>, v_12: Maybe<&2, String>}
  TemplateRequest_strip_instance_or_definition{v_1: String, v_3: String, v_4: Ast.Definition, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, TemplateDef>, v_12: List<&2, GeneratedIdentity>, v_14: Bool}
  TemplateRequest_canonical_template_key{v_1: String, v_4: List<&2, TemplateDef>}
  TemplateRequest_canonical_template_match{v_1: String, v_3: String, v_6: List<&2, TemplateDef>, v_8: Bool}
  TemplateRequest_generated_local_keys{v_1: String, v_4: List<&2, GeneratedIdentity>}
  TemplateRequest_generated_local_key_match{v_1: String, v_3: String, v_6: List<&2, GeneratedIdentity>, v_8: Bool}
  TemplateRequest_has_generated_local_key{v_1: String, v_4: List<&2, String>}
  TemplateRequest_is_template_instance{v_1: String, v_3: String, v_6: List<&2, GeneratedIdentity>}
  TemplateRequest_generated_identity_found{v_2: Maybe<&2, GeneratedIdentity>}
  TemplateRequest_template_instances{v_1: List<&2, Ast.TopLevel>, v_3: String, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>}
  TemplateRequest_template_instances_for_keys{v_1: List<&2, Ast.TopLevel>, v_4: List<&2, String>, v_7: List<&2, TemplateDef>}
  TemplateRequest_template_instance_definition{v_1: String, v_3: List<&2, Ast.TelescopeItem>, v_4: Ast.OptionalTerm, v_5: Ast.DefBody, v_7: Bool, v_8: Ast.SourceSpan, v_10: List<&2, Ast.TopLevel>, v_13: List<&2, TemplateDef>, v_16: List<&2, String>, v_18: Bool}
  TemplateRequest_expand_constructors{v_1: List<&2, Ast.ConstructorDecl>, v_4: List<&2, TemplateDef>}
  TemplateRequest_expand_clauses{v_1: List<&2, Ast.Clause>, v_4: List<&2, TemplateDef>}
  TemplateRequest_expand_maybe{v_1: Maybe<&2, Ast.SyntaxTerm>, v_4: List<&2, TemplateDef>}
  TemplateRequest_expand_definition{v_0: Ast.Definition, v_3: List<&2, TemplateDef>}
  TemplateRequest_expand_body{v_0: Ast.DefBody, v_3: List<&2, TemplateDef>}
  TemplateRequest_expand_optional{v_0: Ast.OptionalTerm, v_3: List<&2, TemplateDef>}
  TemplateRequest_expand_binders{v_1: List<&2, Ast.TelescopeItem>, v_4: List<&2, TemplateDef>}
  TemplateRequest_collect_actual_term{v_0: Ast.SyntaxTerm, v_3: List<&2, ActualSite>}
  TemplateRequest_collect_actual_application{v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>, v_5: List<&2, ActualSite>}
  TemplateRequest_collect_actual_prefix{v_1: String, v_4: Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, ActualSite>}
  TemplateRequest_head_key{v_0: Ast.SyntaxTerm}
  TemplateRequest_wrapped_prefix{v_1: List<&2, Ast.SyntaxTerm>}
  TemplateRequest_wrapped_prefix_cons{v_0: Ast.SyntaxTerm, v_3: Maybe<&2, List<&2, Ast.SyntaxTerm>>}
  TemplateRequest_collect_actual_terms{v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, ActualSite>}
  TemplateRequest_first_actual{v_2: List<&2, List<&2, Ast.SyntaxTerm>>, v_5: List<&2, List<&2, Ast.SyntaxTerm>>}
  TemplateRequest_collect_actual_declarations{v_1: List<&2, Ast.TopLevel>, v_4: List<&2, ActualSite>}
  TemplateRequest_collect_actual_definition{v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.OptionalTerm, v_3: Ast.DefBody, v_6: List<&2, ActualSite>, v_8: Bool}
  TemplateRequest_collect_actual_body{v_0: Ast.DefBody, v_3: List<&2, ActualSite>}
  TemplateRequest_collect_actual_modules{v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>}
  TemplateRequest_collect_actual_module{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, ActualSite>, v_8: List<&2, Loader.LoadedModule>, v_11: List<&2, ActualModule>}
  TemplateRequest_actual_in_catalog{v_2: List<&2, ActualModule>, v_4: String, v_7: List<&2, TemplateDef>}
  TemplateRequest_actual_in_catalog_found{v_2: List<&2, ActualModule>, v_4: String, v_7: List<&2, TemplateDef>, v_10: Maybe<&2, TemplateDef>}
  TemplateRequest_template_aliases_found{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: String, v_8: Maybe<&2, TemplateDef>}
  TemplateRequest_template_local_alias{v_1: String, v_3: String, v_5: String, v_7: Bool}
  TemplateRequest_imported_alias_names{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: String, v_7: String}
  TemplateRequest_imported_alias_match{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: String, v_7: String, v_9: String, v_11: Bool}
  TemplateRequest_actual_in_aliases{v_2: List<&2, ActualSite>, v_5: List<&2, String>}
  TemplateRequest_actual_sites_for_key{v_2: List<&2, ActualSite>, v_4: String}
  TemplateRequest_expand_actual_values{v_2: List<&2, List<&2, Ast.SyntaxTerm>>, v_5: List<&2, TemplateDef>, v_8: List<&2, CaptureName>}
  TemplateRequest_collect_actual_binders{v_1: List<&2, Ast.TelescopeItem>, v_4: List<&2, ActualSite>}
  TemplateRequest_collect_actual_optional{v_0: Ast.OptionalTerm, v_3: List<&2, ActualSite>}
  TemplateRequest_collect_actual_constructors{v_1: List<&2, Ast.ConstructorDecl>, v_4: List<&2, ActualSite>}
  TemplateRequest_collect_actual_clauses{v_1: List<&2, Ast.Clause>, v_4: List<&2, ActualSite>}
  TemplateRequest_collect_actual_maybe{v_1: Maybe<&2, Ast.SyntaxTerm>, v_4: List<&2, ActualSite>}
  TemplateRequest_has_string{v_1: String, v_4: List<&2, String>}
  TemplateRequest_has_string_match{v_1: String, v_3: String, v_6: List<&2, String>, v_8: Bool}
  TemplateRequest_has_top_key{v_1: String, v_3: List<&2, Ast.TopLevel>}
  TemplateRequest_find_generated_identity{v_1: String, v_4: List<&2, GeneratedIdentity>}

type TemplateRequestGroup2 is Type:
  TemplateRequest_find_generated_identity_match{v_1: String, v_3: GeneratedIdentity, v_6: List<&2, GeneratedIdentity>, v_8: String, v_10: Bool}
  TemplateRequest_template_span{v_1: TemplateDef}
  TemplateRequest_generated_actuals{v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>}
  TemplateRequest_template_name{v_1: TemplateDef}
  TemplateRequest_generated_actual_case{v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>, v_11: String, v_13: String, v_15: String, v_17: String, v_19: List<&2, Ast.SyntaxTerm>, v_22: Maybe<&2, GeneratedIdentity>}
  TemplateRequest_generated_identity_collision{v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>, v_11: String, v_13: String, v_15: Bool}
  TemplateRequest_generated_actual_new{v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>, v_11: String, v_13: String, v_15: String, v_17: String, v_19: List<&2, Ast.SyntaxTerm>, v_21: Bool}
  TemplateRequest_generated_actual_complete{v_0: Ast.Definition, v_2: GeneratedBuild}
  TemplateRequest_template_source_span_equal{v_0: Ast.SourceSpan, v_1: Ast.SourceSpan}
  TemplateRequest_has_template_source_definition{v_1: String, v_2: Ast.SourceSpan, v_4: List<&2, Ast.TopLevel>}
  TemplateRequest_template_owned_by_module{v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_7: TemplateDef}
  TemplateRequest_generated_for_module{v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, v_11: List<&2, ActualModule>, v_14: List<&2, GeneratedIdentity>}
  TemplateRequest_generated_for_module_match{v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, v_11: List<&2, ActualModule>, v_14: List<&2, GeneratedIdentity>, v_16: TemplateDef, v_18: String, v_21: List<&2, TemplateDef>, v_23: Bool}
  TemplateRequest_generated_for_module_here{v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, v_11: List<&2, ActualModule>, v_14: List<&2, GeneratedIdentity>, v_17: List<&2, TemplateDef>, v_19: GeneratedBuild}
  TemplateRequest_generated_for_module_merge{v_1: List<&2, Ast.TopLevel>, v_3: GeneratedBuild}
  TemplateRequest_generate_round{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_7: List<&2, GeneratedIdentity>}
  TemplateRequest_generate_scoped_round{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, ActualModule>, v_7: List<&2, TemplateDef>, v_10: List<&2, GeneratedIdentity>}
  TemplateRequest_generate_round_loaded{v_1: String, v_3: String, v_5: List<&2, Ast.ModuleImport>, v_7: List<&2, Ast.TopLevel>, v_9: List<&2, Loader.LoadedModule>, v_12: List<&2, ActualModule>, v_15: List<&2, TemplateDef>, v_17: GeneratedBuild}
  TemplateRequest_generate_round_merge{v_1: String, v_3: String, v_5: List<&2, Ast.ModuleImport>, v_7: List<&2, Ast.TopLevel>, v_9: List<&2, Ast.TopLevel>, v_11: Maybe<&2, Ast.SourceSpan>, v_13: GeneratedRound}
  TemplateRequest_generate_until_stable{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_7: List<&2, GeneratedIdentity>}
  TemplateRequest_generate_until_result{v_2: List<&2, TemplateDef>, v_4: GeneratedRound}
  TemplateRequest_visible_templates{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, TemplateDef>}
  TemplateRequest_local_templates{v_1: String, v_4: List<&2, TemplateDef>}
  TemplateRequest_local_template_match{v_1: String, v_4: List<&2, TemplateDef>, v_6: String, v_8: String, v_10: List<&2, Ast.ModuleImport>, v_13: List<&2, String>, v_14: Ast.Definition, v_16: Bool}
  TemplateRequest_imported_templates{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, TemplateDef>}
  TemplateRequest_imported_from{v_1: String, v_3: String, v_6: List<&2, TemplateDef>}
  TemplateRequest_imported_from_match{v_1: String, v_3: String, v_6: List<&2, TemplateDef>, v_8: String, v_10: String, v_12: List<&2, Ast.ModuleImport>, v_15: List<&2, String>, v_16: Ast.Definition, v_18: Bool}
  TemplateRequest_expand_modules{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_7: List<&2, GeneratedIdentity>}
  TemplateRequest_expand_scoped_modules{v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>}
  TemplateRequest_has_late_template_binder{v_1: List<&2, Ast.TelescopeItem>, v_3: Bool}
  TemplateRequest_invalid_template_definitions{v_1: List<&2, Loader.LoadedModule>}
  TemplateRequest_invalid_template_decls{v_1: List<&2, Ast.TopLevel>}
  TemplateRequest_invalid_template_decl{v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.SourceSpan, v_4: List<&2, Ast.TopLevel>, v_6: Bool}
  TemplateRequest_invalid_application{v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>}
  TemplateRequest_invalid_reference{v_0: Ast.SourceSpan, v_3: Maybe<&2, TemplateDef>}
  TemplateRequest_invalid_application_spine{v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>, v_5: ApplicationSpine}
  TemplateRequest_invalid_application_head{v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>, v_4: Ast.SyntaxTerm, v_6: List<&2, Ast.SyntaxTerm>, v_7: Ast.SourceSpan, v_10: Maybe<&2, TemplateDef>}
  TemplateRequest_invalid_application_arity{v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat, v_4: Ast.SourceSpan, v_7: List<&2, TemplateDef>, v_9: Bool}
  TemplateRequest_invalid_application_arguments{v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat, v_4: Ast.SourceSpan, v_7: List<&2, TemplateDef>, v_10: Maybe<&2, List<&2, Ast.SyntaxTerm>>}
  TemplateRequest_invalid_application_parts{v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>}
  TemplateRequest_invalid_template_args{v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat, v_4: Ast.SourceSpan, v_7: List<&2, TemplateDef>}
  TemplateRequest_invalid_template_argument{v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>, v_4: Nat, v_5: Ast.SourceSpan, v_8: List<&2, TemplateDef>, v_10: Bool}
  TemplateRequest_invalid_capture_context{v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>}
  TemplateRequest_invalid_capture_key{v_1: String, v_3: Bool, v_4: Ast.SourceSpan, v_7: List<&2, CaptureName>}
  TemplateRequest_invalid_capture_strings{v_2: List<&2, String>, v_3: Ast.SourceSpan, v_6: List<&2, CaptureName>}
  TemplateRequest_invalid_capture_patterns{v_1: List<&2, Ast.SyntaxPattern>, v_4: List<&2, CaptureName>}
  TemplateRequest_invalid_capture_terms{v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, CaptureName>}
  TemplateRequest_invalid_capture_string_bit{v_1: Bool, v_2: Ast.StringLiteralNames, v_3: Ast.SourceSpan, v_6: List<&2, CaptureName>}
  TemplateRequest_invalid_capture_string_word{v_1: Nat, +v_3: U32, +v_4: Ast.StringLiteralNames, +v_5: Ast.SourceSpan, +v_8: List<&2, CaptureName>}
  TemplateRequest_invalid_capture_string{v_2: List<&2, U32>, +v_3: Ast.StringLiteralNames, +v_4: Ast.SourceSpan, +v_7: List<&2, CaptureName>}
  TemplateRequest_invalid_capture{v_0: Ast.SyntaxTerm, v_3: List<&2, CaptureName>}
  TemplateRequest_has_open_vars{v_0: Ast.SyntaxTerm, v_2: Nat}
  TemplateRequest_has_open_vars_terms{v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat}
  TemplateRequest_invalid_terms{v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, TemplateDef>}
  TemplateRequest_first_invalid{v_1: Maybe<&2, Ast.SourceSpan>, v_3: Maybe<&2, Ast.SourceSpan>}
  TemplateRequest_invalid_definitions{v_1: List<&2, Ast.TopLevel>, v_4: List<&2, TemplateDef>}
  TemplateRequest_invalid_definition{v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.OptionalTerm, v_3: Ast.DefBody, v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, v_10: Bool}
  TemplateRequest_invalid_def_body{v_0: Ast.DefBody, v_3: List<&2, TemplateDef>}
  TemplateRequest_invalid_optional{v_0: Ast.OptionalTerm, v_3: List<&2, TemplateDef>}
  TemplateRequest_invalid_binders{v_1: List<&2, Ast.TelescopeItem>, v_4: List<&2, TemplateDef>}
  TemplateRequest_invalid_constructors{v_1: List<&2, Ast.ConstructorDecl>, v_4: List<&2, TemplateDef>}
  TemplateRequest_invalid_clauses{v_1: List<&2, Ast.Clause>, v_4: List<&2, TemplateDef>}
  TemplateRequest_invalid_maybe{v_1: Maybe<&2, Ast.SyntaxTerm>, v_4: List<&2, TemplateDef>}
  TemplateRequest_expand{v_1: List<&2, Loader.LoadedModule>}

type TemplateRequestGroup3 is Type:
  TemplateRequest_template_expand_templates{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_6: Maybe<&2, Ast.SourceSpan>}
  TemplateRequest_template_expand_modules{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_6: Maybe<&2, Ast.SourceSpan>}
  TemplateRequest_generated_declarations{v_1: List<&2, Ast.TopLevel>}
  TemplateRequest_generated_modules{v_1: List<&2, Loader.LoadedModule>}
  TemplateRequest_template_expand_round{v_2: List<&2, TemplateDef>, v_4: GeneratedRound}
  TemplateRequest_template_expand_generated{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, GeneratedIdentity>, v_7: List<&2, TemplateDef>, v_9: Maybe<&2, Ast.SourceSpan>}
  TemplateRequest_invalid_modules{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>}
  TemplateRequest_invalid_scoped_modules{v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>}

type TemplateRequest is Type:
  TemplateRequestGroup_0{request: TemplateRequestGroup0}
  TemplateRequestGroup_1{request: TemplateRequestGroup1}
  TemplateRequestGroup_2{request: TemplateRequestGroup2}
  TemplateRequestGroup_3{request: TemplateRequestGroup3}

def template_result_group_0(request: TemplateRequestGroup0) -> Type:
  match request:
    case TemplateRequest_span_of{_}: Ast.SourceSpan
    case TemplateRequest_collect_templates{_}: List<&2, TemplateDef>
    case TemplateRequest_top_keys{_}: List<&2, String>
    case TemplateRequest_collect_template_decls{_, _, _, _}: List<&2, TemplateDef>
    case TemplateRequest_collect_template_decl{_, _, _, _, _, _, _, _, _, _, _}: List<&2, TemplateDef>
    case TemplateRequest_has_template_binder{_}: Bool
    case TemplateRequest_qualify{_, _}: String
    case TemplateRequest_qualify_match{_, _, _}: String
    case TemplateRequest_find_template{_, _}: Maybe<&2, TemplateDef>
    case TemplateRequest_find_template_match{_, _, _, _}: Maybe<&2, TemplateDef>
    case TemplateRequest_flatten_application{_}: ApplicationSpine
    case TemplateRequest_flatten_append{_, _, _}: ApplicationSpine
    case TemplateRequest_leading_template_count{_}: Nat
    case TemplateRequest_template_for_head{_, _}: Maybe<&2, TemplateDef>
    case TemplateRequest_take_template_args{_, _}: Maybe<&2, List<&2, Ast.SyntaxTerm>>
    case TemplateRequest_take_template_arg{_, _}: Maybe<&2, List<&2, Ast.SyntaxTerm>>
    case TemplateRequest_reapply_args{_, _, _}: Ast.SyntaxTerm
    case TemplateRequest_generated_local_key{_, _}: String
    case TemplateRequest_generated_local_key_for_identity{_, _}: String
    case TemplateRequest_fresh_generated_key{_, _, _}: String
    case TemplateRequest_fresh_generated_key_match{_, _, _, _, _}: String
    case TemplateRequest_generated_candidate{_, _}: String
    case TemplateRequest_generated_canonical_key{_, _}: String
    case TemplateRequest_generated_key{_, _}: String
    case TemplateRequest_encode_string{_}: String
    case TemplateRequest_encode_quantity{_}: String
    case TemplateRequest_serialize_strings{_}: String
    case TemplateRequest_serialize_nats{_}: String
    case TemplateRequest_serialize_quantities{_}: String
    case TemplateRequest_serialize_patterns{_}: String
    case TemplateRequest_serialize_pattern{_}: String
    case TemplateRequest_serialize_terms{_}: String
    case TemplateRequest_serialize_term{_}: String
    case TemplateRequest_serialize_optional_quantity{_}: String
    case TemplateRequest_strip_namespace{_, _}: String
    case TemplateRequest_strip_namespace_match{_, _, _}: String
    case TemplateRequest_strip_namespace_prefix{_, _}: String
    case TemplateRequest_strip_namespace_prefix_match{_, _, _}: String
    case TemplateRequest_template_capture_names{_}: List<&2, CaptureName>
    case TemplateRequest_scoped_templates{_, _, _, _}: List<&2, TemplateDef>
    case TemplateRequest_templates_with_captures{_, _}: List<&2, TemplateDef>
    case TemplateRequest_scope_capture_names{_, _, _}: List<&2, CaptureName>
    case TemplateRequest_capture_import_names{_, _, _}: List<&2, CaptureName>
    case TemplateRequest_capture_module_names{_, _, _}: List<&2, CaptureName>
    case TemplateRequest_capture_declaration_names{_, _, _}: List<&2, CaptureName>
    case TemplateRequest_capture_constructor_names{_, _, _}: List<&2, CaptureName>
    case TemplateRequest_capture_declared_name{_, _, _, _, _, _}: List<&2, CaptureName>
    case TemplateRequest_capture_name{_, _, _, _}: Maybe<&2, String>
    case TemplateRequest_capture_key{_, _, _}: String
    case TemplateRequest_capture_strings{_, _}: List<&2, String>
    case TemplateRequest_capture_patterns{_, _}: List<&2, Ast.SyntaxPattern>
    case TemplateRequest_capture_pattern{_, _}: Ast.SyntaxPattern
    case TemplateRequest_capture_terms{_, _}: List<&2, Ast.SyntaxTerm>
    case TemplateRequest_reference_key{_}: String
    case TemplateRequest_capture_string_names{_, _}: Ast.StringLiteralNames
    case TemplateRequest_capture_term{_, _}: Ast.SyntaxTerm
    case TemplateRequest_expand_term{_, _}: Ast.SyntaxTerm
    case TemplateRequest_expand_stable_term{_}: Bool
    case TemplateRequest_expand_stable_terms{_}: Bool
    case TemplateRequest_expand_stable_tail{_, _}: Bool
    case TemplateRequest_expand_constructor_stable{_, _, _, _, _, _}: Ast.SyntaxTerm
    case TemplateRequest_expand_application{_, _, _, _}: Ast.SyntaxTerm
    case TemplateRequest_expand_application_spine{_, _, _, _, _}: Ast.SyntaxTerm
    case TemplateRequest_expand_application_template{_, _, _, _, _, _, _}: Ast.SyntaxTerm

def template_result_group_1(request: TemplateRequestGroup1) -> Type:
  match request:
    case TemplateRequest_template_arity{_}: Nat
    case TemplateRequest_expand_application_arguments{_, _, _, _, _, _, _, _, _}: Ast.SyntaxTerm
    case TemplateRequest_specialize_head{_, _}: Ast.SyntaxTerm
    case TemplateRequest_drop_args{_, _}: List<&2, Ast.SyntaxTerm>
    case TemplateRequest_specialize_definition{_, _, _}: Ast.Definition
    case TemplateRequest_specialize_definition_result{_, _, _, _}: Ast.Definition
    case TemplateRequest_specialize_prefix{_, _, _, _}: List<&2, Ast.TelescopeItem> & Ast.OptionalTerm & Ast.DefBody
    case TemplateRequest_binder_count{_}: Nat
    case TemplateRequest_substitute_binders{_, _, _}: List<&2, Ast.TelescopeItem>
    case TemplateRequest_substitute_optional{_, _, _}: Ast.OptionalTerm
    case TemplateRequest_substitute_body{_, _, _}: Ast.DefBody
    case TemplateRequest_expand_terms{_, _}: List<&2, Ast.SyntaxTerm>
    case TemplateRequest_strip_template_decls{_, _, _, _}: List<&2, Ast.TopLevel>
    case TemplateRequest_strip_template_definition{_, _, _, _, _, _, _, _, _, _, _}: List<&2, Ast.TopLevel>
    case TemplateRequest_strip_canonical_template{_, _, _, _, _}: List<&2, Ast.TopLevel>
    case TemplateRequest_strip_instance_or_definition{_, _, _, _, _, _, _}: List<&2, Ast.TopLevel>
    case TemplateRequest_canonical_template_key{_, _}: Maybe<&2, String>
    case TemplateRequest_canonical_template_match{_, _, _, _}: Maybe<&2, String>
    case TemplateRequest_generated_local_keys{_, _}: List<&2, String>
    case TemplateRequest_generated_local_key_match{_, _, _, _}: List<&2, String>
    case TemplateRequest_has_generated_local_key{_, _}: Bool
    case TemplateRequest_is_template_instance{_, _, _}: Bool
    case TemplateRequest_generated_identity_found{_}: Bool
    case TemplateRequest_template_instances{_, _, _, _}: List<&2, Ast.TopLevel>
    case TemplateRequest_template_instances_for_keys{_, _, _}: List<&2, Ast.TopLevel>
    case TemplateRequest_template_instance_definition{_, _, _, _, _, _, _, _, _, _}: List<&2, Ast.TopLevel>
    case TemplateRequest_expand_constructors{_, _}: List<&2, Ast.ConstructorDecl>
    case TemplateRequest_expand_clauses{_, _}: List<&2, Ast.Clause>
    case TemplateRequest_expand_maybe{_, _}: Maybe<&2, Ast.SyntaxTerm>
    case TemplateRequest_expand_definition{_, _}: Ast.Definition
    case TemplateRequest_expand_body{_, _}: Ast.DefBody
    case TemplateRequest_expand_optional{_, _}: Ast.OptionalTerm
    case TemplateRequest_expand_binders{_, _}: List<&2, Ast.TelescopeItem>
    case TemplateRequest_collect_actual_term{_, _}: List<&2, ActualSite>
    case TemplateRequest_collect_actual_application{_, _, _}: List<&2, ActualSite>
    case TemplateRequest_collect_actual_prefix{_, _, _}: List<&2, ActualSite>
    case TemplateRequest_head_key{_}: Maybe<&2, String>
    case TemplateRequest_wrapped_prefix{_}: Maybe<&2, List<&2, Ast.SyntaxTerm>>
    case TemplateRequest_wrapped_prefix_cons{_, _}: Maybe<&2, List<&2, Ast.SyntaxTerm>>
    case TemplateRequest_collect_actual_terms{_, _}: List<&2, ActualSite>
    case TemplateRequest_first_actual{_, _}: List<&2, List<&2, Ast.SyntaxTerm>>
    case TemplateRequest_collect_actual_declarations{_, _}: List<&2, ActualSite>
    case TemplateRequest_collect_actual_definition{_, _, _, _, _}: List<&2, ActualSite>
    case TemplateRequest_collect_actual_body{_, _}: List<&2, ActualSite>
    case TemplateRequest_collect_actual_modules{_, _}: List<&2, ActualModule>
    case TemplateRequest_collect_actual_module{_, _, _, _, _}: List<&2, ActualModule>
    case TemplateRequest_actual_in_catalog{_, _, _}: List<&2, List<&2, Ast.SyntaxTerm>>
    case TemplateRequest_actual_in_catalog_found{_, _, _, _}: List<&2, List<&2, Ast.SyntaxTerm>>
    case TemplateRequest_template_aliases_found{_, _, _, _}: List<&2, String>
    case TemplateRequest_template_local_alias{_, _, _, _}: List<&2, String>
    case TemplateRequest_imported_alias_names{_, _, _, _}: List<&2, String>
    case TemplateRequest_imported_alias_match{_, _, _, _, _, _}: List<&2, String>
    case TemplateRequest_actual_in_aliases{_, _}: List<&2, List<&2, Ast.SyntaxTerm>>
    case TemplateRequest_actual_sites_for_key{_, _}: List<&2, List<&2, Ast.SyntaxTerm>>
    case TemplateRequest_expand_actual_values{_, _, _}: List<&2, List<&2, Ast.SyntaxTerm>>
    case TemplateRequest_collect_actual_binders{_, _}: List<&2, ActualSite>
    case TemplateRequest_collect_actual_optional{_, _}: List<&2, ActualSite>
    case TemplateRequest_collect_actual_constructors{_, _}: List<&2, ActualSite>
    case TemplateRequest_collect_actual_clauses{_, _}: List<&2, ActualSite>
    case TemplateRequest_collect_actual_maybe{_, _}: List<&2, ActualSite>
    case TemplateRequest_has_string{_, _}: Bool
    case TemplateRequest_has_string_match{_, _, _, _}: Bool
    case TemplateRequest_has_top_key{_, _}: Bool
    case TemplateRequest_find_generated_identity{_, _}: Maybe<&2, GeneratedIdentity>

def template_result_group_2(request: TemplateRequestGroup2) -> Type:
  match request:
    case TemplateRequest_find_generated_identity_match{_, _, _, _, _}: Maybe<&2, GeneratedIdentity>
    case TemplateRequest_template_span{_}: Ast.SourceSpan
    case TemplateRequest_generated_actuals{_, _, _, _}: GeneratedBuild
    case TemplateRequest_template_name{_}: String
    case TemplateRequest_generated_actual_case{_, _, _, _, _, _, _, _, _, _}: GeneratedBuild
    case TemplateRequest_generated_identity_collision{_, _, _, _, _, _, _}: GeneratedBuild
    case TemplateRequest_generated_actual_new{_, _, _, _, _, _, _, _, _, _}: GeneratedBuild
    case TemplateRequest_generated_actual_complete{_, _}: GeneratedBuild
    case TemplateRequest_template_source_span_equal{_, _}: Bool
    case TemplateRequest_has_template_source_definition{_, _, _}: Bool
    case TemplateRequest_template_owned_by_module{_, _, _, _}: Bool
    case TemplateRequest_generated_for_module{_, _, _, _, _, _}: GeneratedBuild
    case TemplateRequest_generated_for_module_match{_, _, _, _, _, _, _, _, _, _}: GeneratedBuild
    case TemplateRequest_generated_for_module_here{_, _, _, _, _, _, _, _}: GeneratedBuild
    case TemplateRequest_generated_for_module_merge{_, _}: GeneratedBuild
    case TemplateRequest_generate_round{_, _, _}: GeneratedRound
    case TemplateRequest_generate_scoped_round{_, _, _, _}: GeneratedRound
    case TemplateRequest_generate_round_loaded{_, _, _, _, _, _, _, _}: GeneratedRound
    case TemplateRequest_generate_round_merge{_, _, _, _, _, _, _}: GeneratedRound
    case TemplateRequest_generate_until_stable{_, _, _}: GeneratedRound
    case TemplateRequest_generate_until_result{_, _}: GeneratedRound
    case TemplateRequest_visible_templates{_, _, _}: List<&2, TemplateDef>
    case TemplateRequest_local_templates{_, _}: List<&2, TemplateDef>
    case TemplateRequest_local_template_match{_, _, _, _, _, _, _, _}: List<&2, TemplateDef>
    case TemplateRequest_imported_templates{_, _, _}: List<&2, TemplateDef>
    case TemplateRequest_imported_from{_, _, _}: List<&2, TemplateDef>
    case TemplateRequest_imported_from_match{_, _, _, _, _, _, _, _, _}: List<&2, TemplateDef>
    case TemplateRequest_expand_modules{_, _, _}: List<&2, Loader.LoadedModule>
    case TemplateRequest_expand_scoped_modules{_, _, _, _}: List<&2, Loader.LoadedModule>
    case TemplateRequest_has_late_template_binder{_, _}: Bool
    case TemplateRequest_invalid_template_definitions{_}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_template_decls{_}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_template_decl{_, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_application{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_reference{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_application_spine{_, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_application_head{_, _, _, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_application_arity{_, _, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_application_arguments{_, _, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_application_parts{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_template_args{_, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_template_argument{_, _, _, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_capture_context{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_capture_key{_, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_capture_strings{_, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_capture_patterns{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_capture_terms{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_capture_string_bit{_, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_capture_string_word{_, _, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_capture_string{_, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_capture{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_has_open_vars{_, _}: Bool
    case TemplateRequest_has_open_vars_terms{_, _}: Bool
    case TemplateRequest_invalid_terms{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_first_invalid{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_definitions{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_definition{_, _, _, _, _, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_def_body{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_optional{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_binders{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_constructors{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_clauses{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_maybe{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_expand{_}: ExpandResult

def template_result_group_3(request: TemplateRequestGroup3) -> Type:
  match request:
    case TemplateRequest_template_expand_templates{_, _, _}: ExpandResult
    case TemplateRequest_template_expand_modules{_, _, _}: ExpandResult
    case TemplateRequest_generated_declarations{_}: List<&2, Ast.TopLevel>
    case TemplateRequest_generated_modules{_}: List<&2, Loader.LoadedModule>
    case TemplateRequest_template_expand_round{_, _}: ExpandResult
    case TemplateRequest_template_expand_generated{_, _, _, _}: ExpandResult
    case TemplateRequest_invalid_modules{_, _}: Maybe<&2, Ast.SourceSpan>
    case TemplateRequest_invalid_scoped_modules{_, _, _}: Maybe<&2, Ast.SourceSpan>

def template_result(request: TemplateRequest) -> Type:
  match request:
    case TemplateRequestGroup_0{inner}: template_result_group_0(inner)
    case TemplateRequestGroup_1{inner}: template_result_group_1(inner)
    case TemplateRequestGroup_2{inner}: template_result_group_2(inner)
    case TemplateRequestGroup_3{inner}: template_result_group_3(inner)

type TemplateValue<-A: Type> is Type:
  TemplateValue{value: A}

type TemplateProgress<-A: Type> is Type:
  TemplateFinished{box: TemplateValue<A>}
  TemplatePending{request: TemplateRequest, resume: (@box: TemplateValue<template_result(request)> -> TemplateProgress<A>)}
  TemplateDirect{-R: Type, -request: TemplateRequest, arguments: R, invoke: (@arguments: R -> TemplateProgress<template_result(request)>), resume: (@box: TemplateValue<template_result(request)> -> TemplateProgress<A>)}
  TemplateBound{-B: Type, inner: TemplateProgress<B>, resume: (@box: TemplateValue<B> -> TemplateProgress<A>)}


type TemplateStack<-A: Type, -R: Type> is Type:
  TemplateStackDone{equation: {A == R : Type}}
  TemplateStackMore{-B: Type, resume: (@box: TemplateValue<A> -> TemplateProgress<B>), rest: TemplateStack<B, R>}

type TemplateRun<-R: Type> is Type:
  TemplateRunFinished{box: TemplateValue<R>}
  TemplateRunState{-A: Type, progress: TemplateProgress<A>, stack: TemplateStack<A, R>}

def template_cast_box(-A: Type, -R: Type, equation: {A == R : Type}, box: TemplateValue<A>) -> TemplateValue<R>:
  %equation : TemplateValue<_>
  box

def template_unbox(-A: Type, box: TemplateValue<A>) -> A:
  match box:
    case TemplateValue{value}: value

def template_pure_template_capture_names(v_1: TemplateDef) -> List<&2, CaptureName>:
  match v_1:
    case TemplateDef{_, _, _, _, _, _, v_17}:
      v_17

def template_pure_generated_identity_found(v_2: Maybe<&2, GeneratedIdentity>) -> Bool:
  match v_2:
    case Some{_}:
      True{}
    case None{}:
      False{}

def template_pure_template_span(v_1: TemplateDef) -> Ast.SourceSpan:
  match v_1:
    case TemplateDef{_, _, _, _, _, Ast.Definition{_, _, _, _, _, v_24}, _}:
      v_24

def template_pure_template_name(v_1: TemplateDef) -> String:
  match v_1:
    case TemplateDef{v_10, _, _, _, _, _, _}:
      v_10

def template_body_span_of(v_0: Ast.SyntaxTerm) -> TemplateProgress<Ast.SourceSpan>:
  match v_0:
    case Ast.TermVar{_, _, v_6}:
      TemplateFinished{TemplateValue{v_6}}
    case Ast.TermRef{_, v_10}:
      TemplateFinished{TemplateValue{v_10}}
    case Ast.TermBang{_, v_14}:
      TemplateFinished{TemplateValue{v_14}}
    case Ast.TermSub{_, _, _, v_22}:
      TemplateFinished{TemplateValue{v_22}}
    case Ast.TermLet{_, _, _, _, _, v_34}:
      TemplateFinished{TemplateValue{v_34}}
    case Ast.TermAnn{_, _, v_40}:
      TemplateFinished{TemplateValue{v_40}}
    case Ast.TermTemplate{_, v_44}:
      TemplateFinished{TemplateValue{v_44}}
    case Ast.TermType{_, v_48}:
      TemplateFinished{TemplateValue{v_48}}
    case Ast.TermQuantity{_, v_52}:
      TemplateFinished{TemplateValue{v_52}}
    case Ast.TermMin{_, _, v_58}:
      TemplateFinished{TemplateValue{v_58}}
    case Ast.TermAll{_, _, _, _, _, v_70}:
      TemplateFinished{TemplateValue{v_70}}
    case Ast.TermLam{_, _, _, _, v_80}:
      TemplateFinished{TemplateValue{v_80}}
    case Ast.TermApp{_, _, v_86}:
      TemplateFinished{TemplateValue{v_86}}
    case Ast.TermAdt{_, _, _, v_94}:
      TemplateFinished{TemplateValue{v_94}}
    case Ast.TermFill{_, _, v_100}:
      TemplateFinished{TemplateValue{v_100}}
    case Ast.TermPlus{_, _, v_106}:
      TemplateFinished{TemplateValue{v_106}}
    case Ast.TermCtr{_, _, v_112}:
      TemplateFinished{TemplateValue{v_112}}
    case Ast.TermString{_, _, v_118}:
      TemplateFinished{TemplateValue{v_118}}
    case Ast.TermMat{_, _, _, v_126}:
      TemplateFinished{TemplateValue{v_126}}
    case Ast.TermAbsurd{v_128}:
      TemplateFinished{TemplateValue{v_128}}
    case Ast.TermEqual{_, _, _, v_136}:
      TemplateFinished{TemplateValue{v_136}}
    case Ast.TermRefl{v_138}:
      TemplateFinished{TemplateValue{v_138}}
    case Ast.TermRewrite{_, _, _, v_146}:
      TemplateFinished{TemplateValue{v_146}}
    case Ast.TermHole{_, v_150}:
      TemplateFinished{TemplateValue{v_150}}
    case Ast.BodyMatch{_, _, v_156}:
      TemplateFinished{TemplateValue{v_156}}
    case Ast.BodyCase{_, _, v_162}:
      TemplateFinished{TemplateValue{v_162}}
    case Ast.BodyLocal{_, _, _, _, v_172}:
      TemplateFinished{TemplateValue{v_172}}
    case Ast.BodyReply{_, v_176}:
      TemplateFinished{TemplateValue{v_176}}
    case Ast.TermQuant{}:
      TemplateFinished{TemplateValue{Ast.SpanOf{"", 0n, 0n}}}

def template_match_5(+v_6: Loader.LoadedModule, v_7: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_6:
    case Loader.LoadedModule{v_12, Ast.Module{_, v_14, +v_15}}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_top_keys{v_15}}, v_1000007 => +v_1000002 = template_unbox(List<&2, String>, v_1000007); TemplatePending{TemplateRequestGroup_0{TemplateRequest_collect_template_decls{{v_12 : String}, {v_14 : List<&2, Ast.ModuleImport>}, v_1000002, v_15}}, v_1000006 => +v_1000003 = template_unbox(List<&2, TemplateDef>, v_1000006); TemplatePending{TemplateRequestGroup_0{TemplateRequest_collect_templates{v_7}}, v_1000005 => +v_1000004 = template_unbox(List<&2, TemplateDef>, v_1000005); TemplateFinished{TemplateValue{List.append(&2, TemplateDef, v_1000003, v_1000004)}}}}}

def template_body_collect_templates(v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_6 <> v_7:
      template_match_5(v_6, v_7)

def template_match_7(+v_6: Ast.TopLevel, v_7: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, String>>:
  match v_6:
    case Ast.DefTop{Ast.Definition{v_14, _, _, _, _, _}}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_top_keys{v_7}}, v_1000010 => +v_1000009 = template_unbox(List<&2, String>, v_1000010); TemplateFinished{TemplateValue{{v_14 : String} <> v_1000009}}}
    case Ast.TypeTop{Ast.TypeDecl{v_26, _, _, _, _}}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_top_keys{v_7}}, v_1000013 => +v_1000012 = template_unbox(List<&2, String>, v_1000013); TemplateFinished{TemplateValue{{v_26 : String} <> v_1000012}}}
    case Ast.LawTop{Ast.LawDecl{v_36, _, _, _}}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_top_keys{v_7}}, v_1000016 => +v_1000015 = template_unbox(List<&2, String>, v_1000016); TemplateFinished{TemplateValue{{v_36 : String} <> v_1000015}}}

def template_body_top_keys(v_1: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, String>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_6 <> v_7:
      template_match_7(v_6, v_7)

def template_match_9(+v_13: Ast.TopLevel, v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, String>, v_14: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_13:
    case Ast.DefTop{Ast.Definition{v_21, +v_22, v_23, v_24, v_25, v_26}}:
      v_1000017 = {v_1 : String}
      v_1000018 = {v_3 : List<&2, Ast.ModuleImport>}
      v_1000019 = {v_6 : List<&2, String>}
      v_1000026 = {v_14 : List<&2, Ast.TopLevel>}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_has_template_binder{v_22}}, v_1000030 => +v_1000027 = template_unbox(Bool, v_1000030); TemplatePending{TemplateRequestGroup_0{TemplateRequest_collect_template_decl{v_1000017, v_1000018, v_1000019, {v_21 : String}, {v_22 : List<&2, Ast.TelescopeItem>}, {v_23 : Ast.OptionalTerm}, {v_24 : Ast.DefBody}, {v_25 : Bool}, {v_26 : Ast.SourceSpan}, v_1000026, v_1000027}}, v_1000029 => +v_1000028 = template_unbox(List<&2, TemplateDef>, v_1000029); TemplateFinished{TemplateValue{v_1000028}}}}
    case _:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_collect_template_decls{v_1, v_3, v_6, v_14}}, v_1000032 => +v_1000031 = template_unbox(List<&2, TemplateDef>, v_1000032); TemplateFinished{TemplateValue{v_1000031}}}

def template_body_collect_template_decls(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, String>, v_8: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_8:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1001977 <> v_1001978:
      template_match_9(v_1001977, v_1, v_3, v_6, v_1001978)

def template_continuation_11(+v_1000033: String, v_8: String, v_10: List<&2, Ast.TelescopeItem>, v_11: Ast.OptionalTerm, v_12: Ast.DefBody, v_14: Bool, v_15: Ast.SourceSpan, +v_1: String, +v_3: List<&2, Ast.ModuleImport>, +v_6: List<&2, String>, v_17: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, TemplateDef>>:
  v_26 = {Ast.Definition{v_8, v_10, v_11, v_12, v_14, v_15} : Ast.Definition}
  v_1000034 = {TemplateDef{v_1000033, v_1, v_3, v_6, "", v_26, []} : TemplateDef}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_collect_template_decls{v_1, v_3, v_6, v_17}}, False{}, v_1000037 => template_body_collect_template_decls(v_1, v_3, v_6, v_17), v_1000036 => +v_1000035 = template_unbox(List<&2, TemplateDef>, v_1000036); TemplateFinished{TemplateValue{v_1000034 <> v_1000035}}}

def template_body_collect_template_decl(+v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, String>, +v_8: String, v_10: List<&2, Ast.TelescopeItem>, v_11: Ast.OptionalTerm, v_12: Ast.DefBody, v_14: Bool, v_15: Ast.SourceSpan, v_17: List<&2, Ast.TopLevel>, v_19: Bool) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_19:
    case True{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_qualify{v_1, v_8}}, v_1001979 => +v_1001980 = template_unbox(String, v_1001979); template_continuation_11(v_1001980, v_8, v_10, v_11, v_12, v_14, v_15, v_1, v_3, v_6, v_17)}
    case False{}:
      template_body_collect_template_decls(v_1, v_3, v_6, v_17)

def template_match_13(+v_5: Ast.TelescopeItem, v_6: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Bool>:
  match v_5:
    case Ast.TemplateBinder{_, _, _, _}:
      TemplateFinished{TemplateValue{True{}}}
    case Ast.Binder{_, _, _, _, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_has_template_binder{v_6}}, v_1000041 => +v_1000040 = template_unbox(Bool, v_1000041); TemplateFinished{TemplateValue{v_1000040}}}

def template_body_has_template_binder(v_1: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Bool>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_5 <> v_6:
      template_match_13(v_5, v_6)

def template_body_qualify(+v_1: String, v_3: String) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_qualify_match{v_1, v_3, String.eq(v_1, "")}}, v_1000043 => +v_1000042 = template_unbox(String, v_1000043); TemplateFinished{TemplateValue{v_1000042}}}

def template_body_qualify_match(v_1: String, v_3: String, v_5: Bool) -> TemplateProgress<String>:
  match v_5:
    case True{}:
      TemplateFinished{TemplateValue{v_3}}
    case False{}:
      TemplateFinished{TemplateValue{String.append(v_1, String.append(".", v_3))}}

def template_match_16(+v_9: TemplateDef, +v_1: String, v_10: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, TemplateDef>>:
  match v_9:
    case TemplateDef{v_18, _, _, _, v_22, _, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_find_template_match{v_1, v_9, v_10, Bool.or(String.eq(v_18, v_1), String.eq(v_22, v_1))}}, v_1000045 => +v_1000044 = template_unbox(Maybe<&2, TemplateDef>, v_1000045); TemplateFinished{TemplateValue{v_1000044}}}

def template_body_find_template(v_1: String, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, TemplateDef>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1001981 <> v_1001982:
      template_match_16(v_1001981, v_1, v_1001982)

def template_body_find_template_match(v_1: String, v_3: TemplateDef, v_6: List<&2, TemplateDef>, v_8: Bool) -> TemplateProgress<Maybe<&2, TemplateDef>>:
  match v_8:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_3}}}
    case False{}:
      template_body_find_template(v_1, v_6)

def template_body_flatten_application(+v_0: Ast.SyntaxTerm) -> TemplateProgress<ApplicationSpine>:
  match v_0:
    case Ast.TermApp{v_1001983, v_1001984, v_1001985}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_flatten_application{v_1001983}}, v_1001986 => +v_1001987 = template_unbox(ApplicationSpine, v_1001986); TemplatePending{TemplateRequestGroup_0{TemplateRequest_flatten_append{v_1001987, v_1001984, v_1001985}}, v_1001988 => +v_1001989 = template_unbox(ApplicationSpine, v_1001988); TemplateFinished{TemplateValue{v_1001989}}}}
    case v_1001990:
      v_1001992 = {[] : List<&2, Ast.SyntaxTerm>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_span_of{v_0}}, False{}, v_1001993 => template_body_span_of(v_0), v_1001994 => +v_1001995 = template_unbox(Ast.SourceSpan, v_1001994); TemplateFinished{TemplateValue{ApplicationSpine{{v_0 : Ast.SyntaxTerm}, v_1001992, v_1001995}}}}

def template_body_flatten_append(v_1: ApplicationSpine, v_2: Ast.SyntaxTerm, v_3: Ast.SourceSpan) -> TemplateProgress<ApplicationSpine>:
  match v_1:
    case ApplicationSpine{v_8, v_9, _}:
      TemplateFinished{TemplateValue{ApplicationSpine{v_8, List.append(&2, Ast.SyntaxTerm, v_9, [v_2]), v_3}}}

def template_body_leading_template_count(v_1: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Nat>:
  match v_1:
    case Ast.TemplateBinder{_, _, _, _} <> v_12:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_leading_template_count{v_12}}, v_1000058 => +v_1000057 = template_unbox(Nat, v_1000058); TemplateFinished{TemplateValue{Nat.add({1n : Nat}, v_1000057)}}}
    case _:
      TemplateFinished{TemplateValue{0n}}

def template_body_template_for_head(v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, TemplateDef>>:
  match v_0:
    case Ast.TermRef{v_8, _}:
      template_body_find_template(v_8, v_3)
    case Ast.TermBang{v_13, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_template_for_head{v_13, v_3}}, v_1000061 => +v_1000060 = template_unbox(Maybe<&2, TemplateDef>, v_1000061); TemplateFinished{TemplateValue{v_1000060}}}
    case _:
      TemplateFinished{TemplateValue{None{}}}

def template_body_take_template_args(v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat) -> TemplateProgress<Maybe<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_1, v_3:
    case _, 0n:
      TemplateFinished{TemplateValue{Some{[]}}}
    case Ast.TermTemplate{v_12, _} <> v_14, 1n+v_15:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_take_template_args{v_14, v_15}}, v_1000066 => +v_1000063 = template_unbox(Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_1000066); TemplatePending{TemplateRequestGroup_0{TemplateRequest_take_template_arg{{v_12 : Ast.SyntaxTerm}, v_1000063}}, v_1000065 => +v_1000064 = template_unbox(Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_1000065); TemplateFinished{TemplateValue{v_1000064}}}}
    case _, _:
      TemplateFinished{TemplateValue{None{}}}

def template_body_take_template_arg(v_0: Ast.SyntaxTerm, v_3: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> TemplateProgress<Maybe<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_3:
    case Some{v_1001996}:
      TemplateFinished{TemplateValue{Some{v_0 <> v_1001996}}}
    case None{}:
      TemplateFinished{TemplateValue{None{}}}

def template_body_reapply_args(v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>, +v_3: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{v_0}}
    case +v_1001997 <> v_1001998:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_reapply_args{Ast.TermApp{v_0, v_1001997, v_3}, v_1001998, v_3}}, v_1001999 => +v_1002000 = template_unbox(Ast.SyntaxTerm, v_1001999); TemplateFinished{TemplateValue{v_1002000}}}

def template_body_generated_local_key(+v_1: TemplateDef, v_3: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<String>:
  match v_1:
    case TemplateDef{v_1002001, v_1002002, v_1002003, v_1002004, v_1002005, v_1002006, v_1002007}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_encode_string{v_1002001}}, v_1002009 => +v_1002010 = template_unbox(String, v_1002009); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_3}}, v_1002011 => +v_1002012 = template_unbox(String, v_1002011); TemplatePending{TemplateRequestGroup_0{TemplateRequest_generated_local_key_for_identity{{v_1 : TemplateDef}, String.append(v_1002010, v_1002012)}}, v_1002013 => +v_1002014 = template_unbox(String, v_1002013); TemplateFinished{TemplateValue{v_1002014}}}}}

def template_body_generated_local_key_for_identity(v_1: TemplateDef, v_3: String) -> TemplateProgress<String>:
  match v_1:
    case TemplateDef{_, _, _, v_15, _, _, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_fresh_generated_key{String.append("T~", SHA256.hash(v_3)), v_15, 0n}}, v_1000077 => +v_1000076 = template_unbox(String, v_1000077); TemplateFinished{TemplateValue{v_1000076}}}

def template_continuation_28(+v_1000078: String, v_1: String, +v_4: List<&2, String>, v_6: Nat) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_string{v_1000078, v_4}}, v_1000086 => +v_1000083 = template_unbox(Bool, v_1000086); TemplatePending{TemplateRequestGroup_0{TemplateRequest_fresh_generated_key_match{{v_1 : String}, {v_4 : List<&2, String>}, {v_6 : Nat}, {v_1000078 : String}, v_1000083}}, v_1000085 => +v_1000084 = template_unbox(String, v_1000085); TemplateFinished{TemplateValue{v_1000084}}}}

def template_body_fresh_generated_key(+v_1: String, v_4: List<&2, String>, +v_6: Nat) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_generated_candidate{v_1, v_6}}, v_1000087 => +v_1000078 = template_unbox(String, v_1000087); template_continuation_28(v_1000078, v_1, v_4, v_6)}

def template_body_fresh_generated_key_match(+v_1: String, +v_4: List<&2, String>, +v_6: Nat, v_8: String, v_10: Bool) -> TemplateProgress<String>:
  match v_10:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fresh_generated_key{v_1, v_4, Nat.add(v_6, 1n)}}, False{}, v_1002015 => template_body_fresh_generated_key(v_1, v_4, Nat.add(v_6, 1n)), v_1002016 => +v_1002017 = template_unbox(String, v_1002016); TemplateFinished{TemplateValue{v_1002017}}}
    case False{}:
      TemplateFinished{TemplateValue{v_8}}

def template_body_generated_candidate(v_1: String, +v_3: Nat) -> TemplateProgress<String>:
  match v_3:
    case 0n:
      TemplateFinished{TemplateValue{v_1}}
    case v_1002018:
      TemplateFinished{TemplateValue{String.append(v_1, String.append("~", Nat.show(v_3)))}}

def template_body_generated_canonical_key(v_1: TemplateDef, v_3: String) -> TemplateProgress<String>:
  match v_1:
    case TemplateDef{_, v_13, _, _, _, _, _}:
      template_body_qualify(v_13, v_3)

def template_body_generated_key(+v_1: TemplateDef, v_3: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_generated_local_key{v_1, v_3}}, False{}, v_1000096 => template_body_generated_local_key(v_1, v_3), v_1000095 => +v_1000093 = template_unbox(String, v_1000095); template_body_generated_canonical_key({v_1 : TemplateDef}, v_1000093)}

def template_body_encode_string(+v_1: String) -> TemplateProgress<String>:
  TemplateFinished{TemplateValue{String.append(Nat.show(String.length(v_1)), String.append(":", v_1))}}

def template_body_encode_quantity(v_0: Ast.Quantity) -> TemplateProgress<String>:
  match v_0:
    case Ast.QZero{}:
      TemplateFinished{TemplateValue{"0"}}
    case Ast.QOne{}:
      TemplateFinished{TemplateValue{"1"}}
    case Ast.QMany{}:
      TemplateFinished{TemplateValue{"m"}}

def template_continuation_33(v_7: List<&2, String>, +v_1000097: String) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_strings{v_7}}, v_1000100 => +v_1000099 = template_unbox(String, v_1000100); TemplateFinished{TemplateValue{String.append(v_1000097, String.append({";" : String}, v_1000099))}}}

def template_body_serialize_strings(v_2: List<&2, String>) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{"]"}}
    case +v_6 <> v_7:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_6}}, False{}, v_1000102 => template_body_encode_string(v_6), v_1000101 => +v_1000097 = template_unbox(String, v_1000101); template_continuation_33(v_7, v_1000097)}

def template_body_serialize_nats(v_2: List<&2, Nat>) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{"]"}}
    case +v_6 <> v_7:
      v_1000103 = {Nat.show(v_6) : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_nats{v_7}}, v_1000106 => +v_1000105 = template_unbox(String, v_1000106); TemplateFinished{TemplateValue{String.append(v_1000103, String.append({";" : String}, v_1000105))}}}

def template_continuation_36(v_6: List<&2, Ast.Quantity>, +v_1000107: String) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_quantities{v_6}}, v_1000110 => +v_1000109 = template_unbox(String, v_1000110); TemplateFinished{TemplateValue{String.append(v_1000107, String.append({";" : String}, v_1000109))}}}

def template_body_serialize_quantities(v_1: List<&2, Ast.Quantity>) -> TemplateProgress<String>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{"]"}}
    case +v_5 <> v_6:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_5}}, False{}, v_1000112 => template_body_encode_quantity(v_5), v_1000111 => +v_1000107 = template_unbox(String, v_1000111); template_continuation_36(v_6, v_1000107)}

def template_continuation_38(v_6: List<&2, Ast.SyntaxPattern>, +v_1000113: String) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_patterns{v_6}}, v_1000116 => +v_1000115 = template_unbox(String, v_1000116); TemplateFinished{TemplateValue{String.append(v_1000113, String.append({";" : String}, v_1000115))}}}

def template_body_serialize_patterns(v_1: List<&2, Ast.SyntaxPattern>) -> TemplateProgress<String>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{"]"}}
    case +v_5 <> v_6:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_pattern{v_5}}, v_1000117 => +v_1000113 = template_unbox(String, v_1000117); template_continuation_38(v_6, v_1000113)}

def template_body_serialize_pattern(v_0: Ast.SyntaxPattern) -> TemplateProgress<String>:
  match v_0:
    case Ast.PatternVar{_, v_7, v_8, _}:
      v_1000119 = {Nat.show(v_7) : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_8}}, False{}, v_1000122 => template_body_encode_quantity(v_8), v_1000121 => +v_1000120 = template_unbox(String, v_1000121); TemplateFinished{TemplateValue{String.append({"v" : String}, String.append(v_1000119, String.append(v_1000120, ";")))}}}
    case Ast.PatternCtr{v_14, v_15, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_14}}, False{}, v_1000129 => template_body_encode_string(v_14), v_1000128 => +v_1000124 = template_unbox(String, v_1000128); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_patterns{v_15}}, False{}, v_1000127 => template_body_serialize_patterns(v_15), v_1000126 => +v_1000125 = template_unbox(String, v_1000126); TemplateFinished{TemplateValue{String.append({"c" : String}, String.append(v_1000124, v_1000125))}}}}

def template_continuation_41(v_6: List<&2, Ast.SyntaxTerm>, +v_1000130: String) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_6}}, v_1000133 => +v_1000132 = template_unbox(String, v_1000133); TemplateFinished{TemplateValue{String.append(v_1000130, String.append({";" : String}, v_1000132))}}}

def template_body_serialize_terms(v_1: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<String>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{"]"}}
    case +v_5 <> v_6:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_5}}, v_1000134 => +v_1000130 = template_unbox(String, v_1000134); template_continuation_41(v_6, v_1000130)}

def template_body_serialize_term(v_0: Ast.SyntaxTerm) -> TemplateProgress<String>:
  match v_0:
    case Ast.TermVar{_, v_6, _}:
      TemplateFinished{TemplateValue{String.append("v", String.append(Nat.show(v_6), ";"))}}
    case Ast.TermRef{v_10, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_10}}, False{}, v_1000138 => template_body_encode_string(v_10), v_1000137 => +v_1000136 = template_unbox(String, v_1000137); TemplateFinished{TemplateValue{String.append({"r" : String}, v_1000136)}}}
    case Ast.TermBang{v_15, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_15}}, v_1000141 => +v_1000140 = template_unbox(String, v_1000141); TemplateFinished{TemplateValue{String.append({"!" : String}, v_1000140)}}}
    case Ast.TermSub{v_22, v_23, v_24, _}:
      v_1000143 = {Nat.show(v_22) : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_23}}, v_1000148 => +v_1000145 = template_unbox(String, v_1000148); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_24}}, v_1000147 => +v_1000146 = template_unbox(String, v_1000147); TemplateFinished{TemplateValue{String.append({"s" : String}, String.append(v_1000143, String.append({";" : String}, String.append(v_1000145, v_1000146))))}}}}
    case Ast.TermLet{v_34, v_35, v_36, v_37, v_38, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_strings{v_34}}, False{}, v_1000163 => template_body_serialize_strings(v_34), v_1000162 => +v_1000150 = template_unbox(String, v_1000162); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_nats{v_35}}, False{}, v_1000161 => template_body_serialize_nats(v_35), v_1000160 => +v_1000151 = template_unbox(String, v_1000160); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_quantities{v_36}}, False{}, v_1000159 => template_body_serialize_quantities(v_36), v_1000158 => +v_1000152 = template_unbox(String, v_1000158); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_37}}, False{}, v_1000157 => template_body_serialize_terms(v_37), v_1000156 => +v_1000153 = template_unbox(String, v_1000156); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_38}}, v_1000155 => +v_1000154 = template_unbox(String, v_1000155); TemplateFinished{TemplateValue{String.append({"l" : String}, String.append(v_1000150, String.append(v_1000151, String.append(v_1000152, String.append(v_1000153, v_1000154)))))}}}}}}}
    case Ast.TermAnn{v_48, v_49, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_48}}, v_1000168 => +v_1000165 = template_unbox(String, v_1000168); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_49}}, v_1000167 => +v_1000166 = template_unbox(String, v_1000167); TemplateFinished{TemplateValue{String.append({"a" : String}, String.append(v_1000165, v_1000166))}}}}
    case Ast.TermTemplate{v_55, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_55}}, v_1000171 => +v_1000170 = template_unbox(String, v_1000171); TemplateFinished{TemplateValue{String.append({"t" : String}, v_1000170)}}}
    case Ast.TermType{v_60, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_60}}, v_1000174 => +v_1000173 = template_unbox(String, v_1000174); TemplateFinished{TemplateValue{String.append({"T" : String}, v_1000173)}}}
    case Ast.TermQuant{}:
      TemplateFinished{TemplateValue{"q;"}}
    case Ast.TermQuantity{v_65, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_65}}, False{}, v_1000178 => template_body_encode_quantity(v_65), v_1000177 => +v_1000176 = template_unbox(String, v_1000177); TemplateFinished{TemplateValue{String.append({"Q" : String}, String.append(v_1000176, ";"))}}}
    case Ast.TermMin{v_71, v_72, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_71}}, v_1000183 => +v_1000180 = template_unbox(String, v_1000183); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_72}}, v_1000182 => +v_1000181 = template_unbox(String, v_1000182); TemplateFinished{TemplateValue{String.append({"m" : String}, String.append(v_1000180, v_1000181))}}}}
    case Ast.TermAll{v_82, _, _, v_85, v_86, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_82}}, False{}, v_1000191 => template_body_encode_quantity(v_82), v_1000190 => +v_1000185 = template_unbox(String, v_1000190); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_85}}, v_1000189 => +v_1000186 = template_unbox(String, v_1000189); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_86}}, v_1000188 => +v_1000187 = template_unbox(String, v_1000188); TemplateFinished{TemplateValue{String.append({"A" : String}, String.append(v_1000185, String.append(v_1000186, v_1000187)))}}}}}
    case Ast.TermLam{v_96, _, _, v_99, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_optional_quantity{v_96}}, v_1000196 => +v_1000193 = template_unbox(String, v_1000196); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_99}}, v_1000195 => +v_1000194 = template_unbox(String, v_1000195); TemplateFinished{TemplateValue{String.append({"L" : String}, String.append(v_1000193, v_1000194))}}}}
    case Ast.TermApp{v_106, v_107, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_106}}, v_1000201 => +v_1000198 = template_unbox(String, v_1000201); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_107}}, v_1000200 => +v_1000199 = template_unbox(String, v_1000200); TemplateFinished{TemplateValue{String.append({"p" : String}, String.append(v_1000198, v_1000199))}}}}
    case Ast.TermAdt{v_115, v_116, v_117, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_115}}, False{}, v_1000211 => template_body_encode_string(v_115), v_1000210 => +v_1000203 = template_unbox(String, v_1000210); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_116}}, False{}, v_1000209 => template_body_serialize_terms(v_116), v_1000208 => +v_1000204 = template_unbox(String, v_1000208); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_strings{v_117}}, False{}, v_1000207 => template_body_serialize_strings(v_117), v_1000206 => +v_1000205 = template_unbox(String, v_1000206); TemplateFinished{TemplateValue{String.append({"d" : String}, String.append(v_1000203, String.append(v_1000204, v_1000205)))}}}}}
    case Ast.TermFill{v_125, v_126, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_125}}, v_1000217 => +v_1000213 = template_unbox(String, v_1000217); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_126}}, False{}, v_1000216 => template_body_serialize_terms(v_126), v_1000215 => +v_1000214 = template_unbox(String, v_1000215); TemplateFinished{TemplateValue{String.append({"f" : String}, String.append(v_1000213, v_1000214))}}}}
    case Ast.TermPlus{v_133, v_134, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_133}}, v_1000223 => +v_1000219 = template_unbox(String, v_1000223); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_134}}, False{}, v_1000222 => template_body_serialize_terms(v_134), v_1000221 => +v_1000220 = template_unbox(String, v_1000221); TemplateFinished{TemplateValue{String.append({"+" : String}, String.append(v_1000219, v_1000220))}}}}
    case Ast.TermCtr{v_141, v_142, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_141}}, False{}, v_1000230 => template_body_encode_string(v_141), v_1000229 => +v_1000225 = template_unbox(String, v_1000229); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_142}}, False{}, v_1000228 => template_body_serialize_terms(v_142), v_1000227 => +v_1000226 = template_unbox(String, v_1000227); TemplateFinished{TemplateValue{String.append({"c" : String}, String.append(v_1000225, v_1000226))}}}}
    case Ast.TermString{v_149, v_150, v_151}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{Ast.string_desugar(v_149, v_150, v_151)}}, v_1000232 => +v_1000231 = template_unbox(String, v_1000232); TemplateFinished{TemplateValue{v_1000231}}}
    case Ast.TermMat{v_157, v_158, v_159, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_157}}, False{}, v_1000240 => template_body_encode_string(v_157), v_1000239 => +v_1000234 = template_unbox(String, v_1000239); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_158}}, v_1000238 => +v_1000235 = template_unbox(String, v_1000238); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_159}}, v_1000237 => +v_1000236 = template_unbox(String, v_1000237); TemplateFinished{TemplateValue{String.append({"M" : String}, String.append(v_1000234, String.append(v_1000235, v_1000236)))}}}}}
    case Ast.TermAbsurd{_}:
      TemplateFinished{TemplateValue{"!"}}
    case Ast.TermEqual{v_170, v_171, v_172, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_170}}, v_1000247 => +v_1000242 = template_unbox(String, v_1000247); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_171}}, v_1000246 => +v_1000243 = template_unbox(String, v_1000246); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_172}}, v_1000245 => +v_1000244 = template_unbox(String, v_1000245); TemplateFinished{TemplateValue{String.append({"=" : String}, String.append(v_1000242, String.append(v_1000243, v_1000244)))}}}}}
    case Ast.TermRefl{_}:
      TemplateFinished{TemplateValue{"R"}}
    case Ast.TermRewrite{v_183, v_184, v_185, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_183}}, v_1000254 => +v_1000249 = template_unbox(String, v_1000254); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_184}}, v_1000253 => +v_1000250 = template_unbox(String, v_1000253); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_185}}, v_1000252 => +v_1000251 = template_unbox(String, v_1000252); TemplateFinished{TemplateValue{String.append({"w" : String}, String.append(v_1000249, String.append(v_1000250, v_1000251)))}}}}}
    case Ast.TermHole{v_192, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_192}}, False{}, v_1000258 => template_body_encode_string(v_192), v_1000257 => +v_1000256 = template_unbox(String, v_1000257); TemplateFinished{TemplateValue{String.append({"h" : String}, v_1000256)}}}
    case Ast.BodyMatch{v_198, v_199, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_198}}, False{}, v_1000265 => template_body_serialize_terms(v_198), v_1000264 => +v_1000260 = template_unbox(String, v_1000264); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_199}}, False{}, v_1000263 => template_body_serialize_terms(v_199), v_1000262 => +v_1000261 = template_unbox(String, v_1000262); TemplateFinished{TemplateValue{String.append({"B" : String}, String.append(v_1000260, v_1000261))}}}}
    case Ast.BodyCase{v_206, v_207, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_patterns{v_206}}, False{}, v_1000271 => template_body_serialize_patterns(v_206), v_1000270 => +v_1000267 = template_unbox(String, v_1000270); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_207}}, v_1000269 => +v_1000268 = template_unbox(String, v_1000269); TemplateFinished{TemplateValue{String.append({"C" : String}, String.append(v_1000267, v_1000268))}}}}
    case Ast.BodyLocal{v_216, v_217, v_218, v_219, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_patterns{v_216}}, False{}, v_1000283 => template_body_serialize_patterns(v_216), v_1000282 => +v_1000273 = template_unbox(String, v_1000282); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_217}}, False{}, v_1000281 => template_body_encode_quantity(v_217), v_1000280 => +v_1000274 = template_unbox(String, v_1000280); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_218}}, False{}, v_1000279 => template_body_serialize_terms(v_218), v_1000278 => +v_1000275 = template_unbox(String, v_1000278); TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_219}}, v_1000277 => +v_1000276 = template_unbox(String, v_1000277); TemplateFinished{TemplateValue{String.append({"D" : String}, String.append(v_1000273, String.append(v_1000274, String.append(v_1000275, v_1000276))))}}}}}}
    case Ast.BodyReply{v_227, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_227}}, v_1000286 => +v_1000285 = template_unbox(String, v_1000286); TemplateFinished{TemplateValue{String.append({"Y" : String}, v_1000285)}}}

def template_body_serialize_optional_quantity(v_1: Maybe<&2, Ast.Quantity>) -> TemplateProgress<String>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{"n"}}
    case Some{v_3}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_3}}, False{}, v_1000290 => template_body_encode_quantity(v_3), v_1000289 => +v_1000288 = template_unbox(String, v_1000289); TemplateFinished{TemplateValue{String.append({"s" : String}, v_1000288)}}}

def template_body_strip_namespace(v_1: String, +v_3: String) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_strip_namespace_match{v_1, v_3, String.eq(v_3, "")}}, v_1000292 => +v_1000291 = template_unbox(String, v_1000292); TemplateFinished{TemplateValue{v_1000291}}}

def template_body_strip_namespace_match(v_1: String, v_3: String, v_5: Bool) -> TemplateProgress<String>:
  match v_5:
    case True{}:
      TemplateFinished{TemplateValue{v_1}}
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_strip_namespace_prefix{v_1, String.append(v_3, ".")}}, v_1002019 => +v_1002020 = template_unbox(String, v_1002019); TemplateFinished{TemplateValue{v_1002020}}}

def template_body_strip_namespace_prefix(+v_1: String, +v_3: String) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_strip_namespace_prefix_match{v_1, v_3, String.starts_with(v_1, v_3)}}, v_1000296 => +v_1000295 = template_unbox(String, v_1000296); TemplateFinished{TemplateValue{v_1000295}}}

def template_body_strip_namespace_prefix_match(v_1: String, v_3: String, v_5: Bool) -> TemplateProgress<String>:
  match v_5:
    case True{}:
      TemplateFinished{TemplateValue{String.drop(v_1, String.length(v_3))}}
    case False{}:
      TemplateFinished{TemplateValue{v_1}}

def template_body_template_capture_names(v_1: TemplateDef) -> TemplateProgress<List<&2, CaptureName>>:
  TemplateFinished{TemplateValue{template_pure_template_capture_names(v_1)}}

def template_body_scoped_templates(+v_1: String, +v_3: List<&2, Ast.ModuleImport>, +v_6: List<&2, TemplateDef>, v_8: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002021 <> v_1002022:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_visible_templates{v_1, v_3, v_6}}, v_1002023 => +v_1002024 = template_unbox(List<&2, TemplateDef>, v_1002023); TemplatePending{TemplateRequestGroup_0{TemplateRequest_scope_capture_names{v_1, v_3, v_8}}, v_1002025 => +v_1002026 = template_unbox(List<&2, CaptureName>, v_1002025); TemplatePending{TemplateRequestGroup_0{TemplateRequest_templates_with_captures{v_1002024, v_1002026}}, v_1002027 => +v_1002028 = template_unbox(List<&2, TemplateDef>, v_1002027); TemplateFinished{TemplateValue{v_1002028}}}}}

def template_body_templates_with_captures(v_2: List<&2, TemplateDef>, +v_5: List<&2, CaptureName>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case TemplateDef{v_1002029, v_1002030, v_1002031, v_1002032, v_1002033, v_1002034, v_1002035} <> v_1002036:
      v_1002037 = {TemplateDef{v_1002029, v_1002030, v_1002031, v_1002032, v_1002033, v_1002034, v_5} : TemplateDef}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_templates_with_captures{v_1002036, v_5}}, v_1002038 => +v_1002039 = template_unbox(List<&2, TemplateDef>, v_1002038); TemplateFinished{TemplateValue{v_1002037 <> v_1002039}}}

def template_continuation_49(+v_1000308: List<&2, CaptureName>, v_10: List<&2, CaptureName>, v_13: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  TemplateFinished{TemplateValue{List.append(&2, CaptureName, v_10, List.append(&2, CaptureName, v_13, v_1000308))}}

def template_continuation_50(+v_1000307: List<&2, CaptureName>, v_5: List<&2, Loader.LoadedModule>, v_10: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_module_names{"", "Base", v_5}}, v_1000309 => +v_1000308 = template_unbox(List<&2, CaptureName>, v_1000309); template_continuation_49(v_1000308, v_10, v_1000307)}

def template_continuation_51(+v_1000306: List<&2, CaptureName>, v_1: String, v_3: List<&2, Ast.ModuleImport>, +v_5: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, CaptureName>>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_import_names{v_1, v_3, v_5}}, v_1000310 => +v_1000307 = template_unbox(List<&2, CaptureName>, v_1000310); template_continuation_50(v_1000307, v_5, v_1000306)}

def template_body_scope_capture_names(+v_1: String, v_3: List<&2, Ast.ModuleImport>, +v_5: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, CaptureName>>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_module_names{v_1, "", v_5}}, v_1000311 => +v_1000306 = template_unbox(List<&2, CaptureName>, v_1000311); template_continuation_51(v_1000306, v_1, v_3, v_5)}

def template_body_capture_import_names(+v_1: String, v_3: List<&2, Ast.ModuleImport>, +v_5: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case Ast.ModuleImport{v_1002040, v_1002041, v_1002042} <> v_1002043:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_module_names{Path.namespace(v_1, v_1002040), v_1002041, v_5}}, v_1002044 => +v_1002045 = template_unbox(List<&2, CaptureName>, v_1002044); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_import_names{v_1, v_1002043, v_5}}, v_1002046 => +v_1002047 = template_unbox(List<&2, CaptureName>, v_1002046); TemplateFinished{TemplateValue{List.append(&2, CaptureName, v_1002045, v_1002047)}}}}

def template_match_53(v_1000316: Bool, +v_1: String, +v_3: String, v_17: List<&2, Loader.LoadedModule>, v_16: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_1000316:
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_module_names{v_1, v_3, v_17}}, v_1000318 => +v_1000317 = template_unbox(List<&2, CaptureName>, v_1000318); TemplateFinished{TemplateValue{v_1000317}}}
    case True{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declaration_names{v_1, v_3, v_16}}, v_1000322 => +v_1000319 = template_unbox(List<&2, CaptureName>, v_1000322); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_module_names{v_1, v_3, v_17}}, v_1000321 => +v_1000320 = template_unbox(List<&2, CaptureName>, v_1000321); TemplateFinished{TemplateValue{List.append(&2, CaptureName, v_1000319, v_1000320)}}}}

def template_body_capture_module_names(+v_1: String, v_3: String, v_5: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_5:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case Loader.LoadedModule{v_1002048, Ast.Module{v_1002049, v_1002050, v_1002051}} <> v_1002052:
      v_1002053 = {String.eq(v_1, v_1002048) : Bool}
      template_match_53(v_1002053, v_1, v_3, v_1002052, v_1002051)

def template_match_55(+v_10: Ast.TopLevel, +v_1: String, +v_3: String, v_14: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_10:
    case Ast.DefTop{Ast.Definition{v_21, _, _, _, _, _}}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declared_name{v_1, v_3, v_21, False{}, False{}, v_14}}, v_1000325 => +v_1000324 = template_unbox(List<&2, CaptureName>, v_1000325); TemplateFinished{TemplateValue{v_1000324}}}
    case Ast.TypeTop{Ast.TypeDecl{v_33, _, _, v_36, _}}:
      v_1000329 = {True{} : Bool}
      v_1000330 = {False{} : Bool}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_constructor_names{v_1, v_3, v_36}}, v_1000334 => +v_1000331 = template_unbox(List<&2, CaptureName>, v_1000334); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declared_name{{v_1 : String}, {v_3 : String}, {v_33 : String}, v_1000329, v_1000330, List.append(&2, CaptureName, v_1000331, v_14)}}, v_1000333 => +v_1000332 = template_unbox(List<&2, CaptureName>, v_1000333); TemplateFinished{TemplateValue{v_1000332}}}}
    case Ast.LawTop{Ast.LawDecl{v_45, _, _, _}}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declared_name{v_1, v_3, v_45, False{}, False{}, v_14}}, v_1000336 => +v_1000335 = template_unbox(List<&2, CaptureName>, v_1000336); TemplateFinished{TemplateValue{v_1000335}}}

def template_continuation_56(+v_1000323: List<&2, CaptureName>, +v_10: Ast.TopLevel, v_1: String, v_3: String) -> TemplateProgress<List<&2, CaptureName>>:
  template_match_55(v_10, v_1, v_3, v_1000323)

def template_body_capture_declaration_names(+v_1: String, +v_3: String, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_5:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002054 <> v_1002055:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declaration_names{v_1, v_3, v_1002055}}, v_1002056 => +v_1002057 = template_unbox(List<&2, CaptureName>, v_1002056); template_continuation_56(v_1002057, v_1002054, v_1, v_3)}

def template_body_capture_constructor_names(+v_1: String, +v_3: String, v_5: List<&2, Ast.ConstructorDecl>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_5:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case Ast.Constructor{v_1002058, v_1002059, v_1002060} <> v_1002061:
      v_1002065 = {False{} : Bool}
      v_1002066 = {True{} : Bool}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_constructor_names{v_1, v_3, v_1002061}}, v_1002067 => +v_1002068 = template_unbox(List<&2, CaptureName>, v_1002067); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declared_name{{v_1 : String}, {v_3 : String}, {v_1002058 : String}, v_1002065, v_1002066, v_1002068}}, v_1002069 => +v_1002070 = template_unbox(List<&2, CaptureName>, v_1002069); TemplateFinished{TemplateValue{v_1002070}}}}

def template_match_59(v_1000349: Bool, v_5: String, v_17: String, v_7: Bool, v_9: Bool, v_20: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_1000349:
    case True{}:
      TemplateFinished{TemplateValue{CaptureName{v_5, v_17, v_7, v_9} <> v_20}}
    case False{}:
      TemplateFinished{TemplateValue{v_20}}

def template_continuation_60(+v_1000348: String, +v_17: String, +v_7: Bool, +v_9: Bool, v_12: List<&2, CaptureName>, v_3: String, v_5: String) -> TemplateProgress<List<&2, CaptureName>>:
  v_20 = {CaptureName{v_1000348, v_17, v_7, v_9} <> v_12 : List<&2, CaptureName>}
  v_1000349 = {String.eq(v_3, "Base") : Bool}
  template_match_59(v_1000349, v_5, v_17, v_7, v_9, v_20)

def template_continuation_61(+v_1000347: String, +v_3: String, +v_5: String, v_7: Bool, v_9: Bool, v_12: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_qualify{v_3, v_5}}, False{}, v_1000351 => template_body_qualify(v_3, v_5), v_1000350 => +v_1000348 = template_unbox(String, v_1000350); template_continuation_60(v_1000348, v_1000347, v_7, v_9, v_12, v_3, v_5)}

def template_body_capture_declared_name(v_1: String, v_3: String, +v_5: String, v_7: Bool, v_9: Bool, v_12: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_qualify{v_1, v_5}}, False{}, v_1000353 => template_body_qualify(v_1, v_5), v_1000352 => +v_1000347 = template_unbox(String, v_1000352); template_continuation_61(v_1000347, v_3, v_5, v_7, v_9, v_12)}

def template_match_62(v_20: Bool, v_18: String, v_1: String, v_3: Bool, v_21: List<&2, CaptureName>, v_9: Maybe<&2, String>) -> TemplateProgress<Maybe<&2, String>>:
  match v_20:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_18}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_21, v_9}}, v_1000358 => +v_1000357 = template_unbox(Maybe<&2, String>, v_1000358); TemplateFinished{TemplateValue{v_1000357}}}

def template_match_63(+v_9: Maybe<&2, String>, v_1: String, v_3: Bool, v_21: List<&2, CaptureName>, v_18: String) -> TemplateProgress<Maybe<&2, String>>:
  match v_9:
    case Some{_}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_21, v_9}}, v_1000360 => +v_1000359 = template_unbox(Maybe<&2, String>, v_1000360); TemplateFinished{TemplateValue{v_1000359}}}
    case None{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_21, Some{v_18}}}, v_1000362 => +v_1000361 = template_unbox(Maybe<&2, String>, v_1000362); TemplateFinished{TemplateValue{v_1000361}}}

def template_match_64(v_19: Bool, v_18: String, v_9: Maybe<&2, String>, v_1: String, v_3: Bool, v_21: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, String>>:
  match v_19:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_18}}}
    case False{}:
      template_match_63(v_9, v_1, v_3, v_21, v_18)

def template_match_65(+v_3: Bool, v_20: Bool, v_18: String, v_1: String, v_21: List<&2, CaptureName>, v_9: Maybe<&2, String>, v_19: Bool) -> TemplateProgress<Maybe<&2, String>>:
  match v_3:
    case True{}:
      template_match_62(v_20, v_18, v_1, v_3, v_21, v_9)
    case False{}:
      template_match_64(v_19, v_18, v_9, v_1, v_3, v_21)

def template_match_66(v_1000354: Bool, v_1: String, v_3: Bool, v_21: List<&2, CaptureName>, v_9: Maybe<&2, String>, v_20: Bool, v_18: String, v_19: Bool) -> TemplateProgress<Maybe<&2, String>>:
  match v_1000354:
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_21, v_9}}, v_1000356 => +v_1000355 = template_unbox(Maybe<&2, String>, v_1000356); TemplateFinished{TemplateValue{v_1000355}}}
    case True{}:
      template_match_65(v_3, v_20, v_18, v_1, v_21, v_9, v_19)

def template_body_capture_name(+v_1: String, v_3: Bool, v_6: List<&2, CaptureName>, v_9: Maybe<&2, String>) -> TemplateProgress<Maybe<&2, String>>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{v_9}}
    case CaptureName{v_1002071, +v_1002072, v_1002073, v_1002074} <> v_1002075:
      v_1002076 = {Bool.or(String.eq(v_1, v_1002071), String.eq(v_1, v_1002072)) : Bool}
      template_match_66(v_1002076, v_1, v_3, v_1002075, v_9, v_1002074, v_1002072, v_1002073)

def template_match_68(+v_1000363: Maybe<&2, String>, v_1: String) -> TemplateProgress<String>:
  match v_1000363:
    case None{}:
      TemplateFinished{TemplateValue{v_1}}
    case Some{v_10}:
      TemplateFinished{TemplateValue{v_10}}

def template_body_capture_key(+v_1: String, v_3: Bool, v_6: List<&2, CaptureName>) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_6, None{}}}, False{}, v_1000365 => template_body_capture_name(v_1, v_3, v_6, None{}), v_1000364 => +v_1000363 = template_unbox(Maybe<&2, String>, v_1000364); template_match_68(v_1000363, v_1)}

def template_body_capture_strings(v_2: List<&2, String>, +v_5: List<&2, CaptureName>) -> TemplateProgress<List<&2, String>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002077 <> v_1002078:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_1002077, True{}, v_5}}, False{}, v_1002079 => template_body_capture_key(v_1002077, True{}, v_5), v_1002080 => +v_1002081 = template_unbox(String, v_1002080); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_strings{v_1002078, v_5}}, v_1002082 => +v_1002083 = template_unbox(List<&2, String>, v_1002082); TemplateFinished{TemplateValue{v_1002081 <> v_1002083}}}}

def template_body_capture_patterns(v_1: List<&2, Ast.SyntaxPattern>, +v_4: List<&2, CaptureName>) -> TemplateProgress<List<&2, Ast.SyntaxPattern>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002084 <> v_1002085:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_pattern{v_1002084, v_4}}, v_1002086 => +v_1002087 = template_unbox(Ast.SyntaxPattern, v_1002086); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_patterns{v_1002085, v_4}}, v_1002088 => +v_1002089 = template_unbox(List<&2, Ast.SyntaxPattern>, v_1002088); TemplateFinished{TemplateValue{v_1002087 <> v_1002089}}}}

def template_body_capture_pattern(+v_0: Ast.SyntaxPattern, +v_3: List<&2, CaptureName>) -> TemplateProgress<Ast.SyntaxPattern>:
  match v_0:
    case Ast.PatternVar{v_1002090, v_1002091, v_1002092, v_1002093}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.PatternCtr{v_1002094, v_1002095, v_1002096}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_1002094, True{}, v_3}}, False{}, v_1002097 => template_body_capture_key(v_1002094, True{}, v_3), v_1002098 => +v_1002099 = template_unbox(String, v_1002098); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_patterns{v_1002095, v_3}}, False{}, v_1002100 => template_body_capture_patterns(v_1002095, v_3), v_1002101 => +v_1002102 = template_unbox(List<&2, Ast.SyntaxPattern>, v_1002101); TemplateFinished{TemplateValue{Ast.PatternCtr{v_1002099, v_1002102, v_1002096}}}}}

def template_body_capture_terms(v_1: List<&2, Ast.SyntaxTerm>, +v_4: List<&2, CaptureName>) -> TemplateProgress<List<&2, Ast.SyntaxTerm>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002103 <> v_1002104:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002103, v_4}}, v_1002105 => +v_1002106 = template_unbox(Ast.SyntaxTerm, v_1002105); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1002104, v_4}}, v_1002107 => +v_1002108 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002107); TemplateFinished{TemplateValue{v_1002106 <> v_1002108}}}}

def template_match_73(v_1000386: Bool, v_1: String) -> TemplateProgress<String>:
  match v_1000386:
    case True{}:
      TemplateFinished{TemplateValue{v_1}}
    case False{}:
      TemplateFinished{TemplateValue{String.append("Nat", v_1)}}

def template_match_74(v_1000385: Bool, +v_1: String) -> TemplateProgress<String>:
  match v_1000385:
    case False{}:
      TemplateFinished{TemplateValue{v_1}}
    case True{}:
      v_1000386 = {String.starts_with(v_1, "..") : Bool}
      template_match_73(v_1000386, v_1)

def template_body_reference_key(+v_1: String) -> TemplateProgress<String>:
  v_1000385 = {String.starts_with(v_1, ".") : Bool}
  template_match_74(v_1000385, v_1)

def template_body_capture_string_names(v_0: Ast.StringLiteralNames, +v_3: List<&2, CaptureName>) -> TemplateProgress<Ast.StringLiteralNames>:
  match v_0:
    case Ast.StringLiteralNames{v_12, v_13, v_14, v_15, v_16, v_17, v_18, v_19}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_12, True{}, v_3}}, False{}, v_1000410 => template_body_capture_key(v_12, True{}, v_3), v_1000409 => +v_1000387 = template_unbox(String, v_1000409); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_13, True{}, v_3}}, False{}, v_1000408 => template_body_capture_key(v_13, True{}, v_3), v_1000407 => +v_1000388 = template_unbox(String, v_1000407); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_14, True{}, v_3}}, False{}, v_1000406 => template_body_capture_key(v_14, True{}, v_3), v_1000405 => +v_1000389 = template_unbox(String, v_1000405); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_15, True{}, v_3}}, False{}, v_1000404 => template_body_capture_key(v_15, True{}, v_3), v_1000403 => +v_1000390 = template_unbox(String, v_1000403); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_16, True{}, v_3}}, False{}, v_1000402 => template_body_capture_key(v_16, True{}, v_3), v_1000401 => +v_1000391 = template_unbox(String, v_1000401); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_17, True{}, v_3}}, False{}, v_1000400 => template_body_capture_key(v_17, True{}, v_3), v_1000399 => +v_1000392 = template_unbox(String, v_1000399); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_18, True{}, v_3}}, False{}, v_1000398 => template_body_capture_key(v_18, True{}, v_3), v_1000397 => +v_1000393 = template_unbox(String, v_1000397); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_19, True{}, v_3}}, False{}, v_1000396 => template_body_capture_key(v_19, True{}, v_3), v_1000395 => +v_1000394 = template_unbox(String, v_1000395); TemplateFinished{TemplateValue{Ast.StringLiteralNames{v_1000387, v_1000388, v_1000389, v_1000390, v_1000391, v_1000392, v_1000393, v_1000394}}}}}}}}}}}

def template_continuation_76(v_213: Ast.Quantity, v_214: List<&2, Ast.SyntaxTerm>, +v_3: List<&2, CaptureName>, v_215: Ast.SyntaxTerm, +v_1000519: List<&2, Ast.SyntaxPattern>, v_216: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_214, v_3}}, False{}, v_1000525 => template_body_capture_terms(v_214, v_3), v_1000524 => +v_1000521 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1000524); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_215, v_3}}, v_1000523 => +v_1000522 = template_unbox(Ast.SyntaxTerm, v_1000523); TemplateFinished{TemplateValue{Ast.BodyLocal{v_1000519, {v_213 : Ast.Quantity}, v_1000521, v_1000522, v_216}}}}}

def template_body_capture_term(+v_0: Ast.SyntaxTerm, +v_3: List<&2, CaptureName>) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_0:
    case Ast.TermVar{v_1002109, v_1002110, v_1002111}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.TermRef{v_1002112, v_1002113}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_reference_key{v_1002112}}, False{}, v_1002114 => template_body_reference_key(v_1002112), v_1002115 => +v_1002116 = template_unbox(String, v_1002115); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_1002116, False{}, v_3}}, False{}, v_1002117 => template_body_capture_key(v_1002116, False{}, v_3), v_1002118 => +v_1002119 = template_unbox(String, v_1002118); TemplateFinished{TemplateValue{Ast.TermRef{v_1002119, v_1002113}}}}}
    case Ast.TermBang{v_1002120, v_1002121}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002120, v_3}}, v_1002122 => +v_1002123 = template_unbox(Ast.SyntaxTerm, v_1002122); TemplateFinished{TemplateValue{Ast.TermBang{v_1002123, v_1002121}}}}
    case Ast.TermSub{v_1002124, v_1002125, v_1002126, v_1002127}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002125, v_3}}, v_1002129 => +v_1002130 = template_unbox(Ast.SyntaxTerm, v_1002129); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002126, v_3}}, v_1002131 => +v_1002132 = template_unbox(Ast.SyntaxTerm, v_1002131); TemplateFinished{TemplateValue{Ast.TermSub{{v_1002124 : Nat}, v_1002130, v_1002132, v_1002127}}}}}
    case Ast.TermLet{v_1002133, v_1002134, v_1002135, v_1002136, v_1002137, v_1002138}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1002136, v_3}}, False{}, v_1002142 => template_body_capture_terms(v_1002136, v_3), v_1002143 => +v_1002144 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002143); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002137, v_3}}, v_1002145 => +v_1002146 = template_unbox(Ast.SyntaxTerm, v_1002145); TemplateFinished{TemplateValue{Ast.TermLet{{v_1002133 : List<&2, String>}, {v_1002134 : List<&2, Nat>}, {v_1002135 : List<&2, Ast.Quantity>}, v_1002144, v_1002146, v_1002138}}}}}
    case Ast.TermAnn{v_1002147, v_1002148, v_1002149}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002147, v_3}}, v_1002150 => +v_1002151 = template_unbox(Ast.SyntaxTerm, v_1002150); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002148, v_3}}, v_1002152 => +v_1002153 = template_unbox(Ast.SyntaxTerm, v_1002152); TemplateFinished{TemplateValue{Ast.TermAnn{v_1002151, v_1002153, v_1002149}}}}}
    case Ast.TermTemplate{v_1002154, v_1002155}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002154, v_3}}, v_1002156 => +v_1002157 = template_unbox(Ast.SyntaxTerm, v_1002156); TemplateFinished{TemplateValue{Ast.TermTemplate{v_1002157, v_1002155}}}}
    case Ast.TermType{v_1002158, v_1002159}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002158, v_3}}, v_1002160 => +v_1002161 = template_unbox(Ast.SyntaxTerm, v_1002160); TemplateFinished{TemplateValue{Ast.TermType{v_1002161, v_1002159}}}}
    case Ast.TermQuant{}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.TermQuantity{v_1002162, v_1002163}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.TermMin{v_1002164, v_1002165, v_1002166}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002164, v_3}}, v_1002167 => +v_1002168 = template_unbox(Ast.SyntaxTerm, v_1002167); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002165, v_3}}, v_1002169 => +v_1002170 = template_unbox(Ast.SyntaxTerm, v_1002169); TemplateFinished{TemplateValue{Ast.TermMin{v_1002168, v_1002170, v_1002166}}}}}
    case Ast.TermAll{v_1002171, v_1002172, v_1002173, v_1002174, v_1002175, v_1002176}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002174, v_3}}, v_1002180 => +v_1002181 = template_unbox(Ast.SyntaxTerm, v_1002180); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002175, v_3}}, v_1002182 => +v_1002183 = template_unbox(Ast.SyntaxTerm, v_1002182); TemplateFinished{TemplateValue{Ast.TermAll{{v_1002171 : Ast.Quantity}, {v_1002172 : String}, {v_1002173 : Nat}, v_1002181, v_1002183, v_1002176}}}}}
    case Ast.TermLam{v_1002184, v_1002185, v_1002186, v_1002187, v_1002188}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002187, v_3}}, v_1002192 => +v_1002193 = template_unbox(Ast.SyntaxTerm, v_1002192); TemplateFinished{TemplateValue{Ast.TermLam{{v_1002184 : Maybe<&2, Ast.Quantity>}, {v_1002185 : String}, {v_1002186 : Nat}, v_1002193, v_1002188}}}}
    case Ast.TermApp{v_1002194, v_1002195, v_1002196}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002194, v_3}}, v_1002197 => +v_1002198 = template_unbox(Ast.SyntaxTerm, v_1002197); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002195, v_3}}, v_1002199 => +v_1002200 = template_unbox(Ast.SyntaxTerm, v_1002199); TemplateFinished{TemplateValue{Ast.TermApp{v_1002198, v_1002200, v_1002196}}}}}
    case Ast.TermAdt{v_1002201, v_1002202, v_1002203, v_1002204}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_1002201, False{}, v_3}}, False{}, v_1002205 => template_body_capture_key(v_1002201, False{}, v_3), v_1002206 => +v_1002207 = template_unbox(String, v_1002206); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1002202, v_3}}, False{}, v_1002208 => template_body_capture_terms(v_1002202, v_3), v_1002209 => +v_1002210 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002209); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_strings{v_1002203, v_3}}, False{}, v_1002211 => template_body_capture_strings(v_1002203, v_3), v_1002212 => +v_1002213 = template_unbox(List<&2, String>, v_1002212); TemplateFinished{TemplateValue{Ast.TermAdt{v_1002207, v_1002210, v_1002213, v_1002204}}}}}}
    case Ast.TermFill{v_1002214, v_1002215, v_1002216}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002214, v_3}}, v_1002217 => +v_1002218 = template_unbox(Ast.SyntaxTerm, v_1002217); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1002215, v_3}}, False{}, v_1002219 => template_body_capture_terms(v_1002215, v_3), v_1002220 => +v_1002221 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002220); TemplateFinished{TemplateValue{Ast.TermFill{v_1002218, v_1002221, v_1002216}}}}}
    case Ast.TermPlus{v_1002222, v_1002223, v_1002224}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002222, v_3}}, v_1002225 => +v_1002226 = template_unbox(Ast.SyntaxTerm, v_1002225); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1002223, v_3}}, False{}, v_1002227 => template_body_capture_terms(v_1002223, v_3), v_1002228 => +v_1002229 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002228); TemplateFinished{TemplateValue{Ast.TermPlus{v_1002226, v_1002229, v_1002224}}}}}
    case Ast.TermCtr{v_1002230, v_1002231, v_1002232}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_1002230, True{}, v_3}}, False{}, v_1002233 => template_body_capture_key(v_1002230, True{}, v_3), v_1002234 => +v_1002235 = template_unbox(String, v_1002234); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1002231, v_3}}, False{}, v_1002236 => template_body_capture_terms(v_1002231, v_3), v_1002237 => +v_1002238 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002237); TemplateFinished{TemplateValue{Ast.TermCtr{v_1002235, v_1002238, v_1002232}}}}}
    case Ast.TermString{v_1002239, v_1002240, v_1002241}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_string_names{v_1002240, v_3}}, False{}, v_1002243 => template_body_capture_string_names(v_1002240, v_3), v_1002244 => +v_1002245 = template_unbox(Ast.StringLiteralNames, v_1002244); TemplateFinished{TemplateValue{Ast.TermString{{v_1002239 : List<&2, U32>}, v_1002245, v_1002241}}}}
    case Ast.TermMat{v_1002246, v_1002247, v_1002248, v_1002249}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_1002246, True{}, v_3}}, False{}, v_1002250 => template_body_capture_key(v_1002246, True{}, v_3), v_1002251 => +v_1002252 = template_unbox(String, v_1002251); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002247, v_3}}, v_1002253 => +v_1002254 = template_unbox(Ast.SyntaxTerm, v_1002253); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002248, v_3}}, v_1002255 => +v_1002256 = template_unbox(Ast.SyntaxTerm, v_1002255); TemplateFinished{TemplateValue{Ast.TermMat{v_1002252, v_1002254, v_1002256, v_1002249}}}}}}
    case Ast.TermAbsurd{v_1002257}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.TermEqual{v_1002258, v_1002259, v_1002260, v_1002261}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002258, v_3}}, v_1002262 => +v_1002263 = template_unbox(Ast.SyntaxTerm, v_1002262); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002259, v_3}}, v_1002264 => +v_1002265 = template_unbox(Ast.SyntaxTerm, v_1002264); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002260, v_3}}, v_1002266 => +v_1002267 = template_unbox(Ast.SyntaxTerm, v_1002266); TemplateFinished{TemplateValue{Ast.TermEqual{v_1002263, v_1002265, v_1002267, v_1002261}}}}}}
    case Ast.TermRefl{v_1002268}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.TermRewrite{v_1002269, v_1002270, v_1002271, v_1002272}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002269, v_3}}, v_1002273 => +v_1002274 = template_unbox(Ast.SyntaxTerm, v_1002273); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002270, v_3}}, v_1002275 => +v_1002276 = template_unbox(Ast.SyntaxTerm, v_1002275); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002271, v_3}}, v_1002277 => +v_1002278 = template_unbox(Ast.SyntaxTerm, v_1002277); TemplateFinished{TemplateValue{Ast.TermRewrite{v_1002274, v_1002276, v_1002278, v_1002272}}}}}}
    case Ast.TermHole{v_1002279, v_1002280}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.BodyMatch{v_1002281, v_1002282, v_1002283}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1002281, v_3}}, False{}, v_1002284 => template_body_capture_terms(v_1002281, v_3), v_1002285 => +v_1002286 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002285); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1002282, v_3}}, False{}, v_1002287 => template_body_capture_terms(v_1002282, v_3), v_1002288 => +v_1002289 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002288); TemplateFinished{TemplateValue{Ast.BodyMatch{v_1002286, v_1002289, v_1002283}}}}}
    case Ast.BodyCase{v_1002290, v_1002291, v_1002292}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_patterns{v_1002290, v_3}}, False{}, v_1002293 => template_body_capture_patterns(v_1002290, v_3), v_1002294 => +v_1002295 = template_unbox(List<&2, Ast.SyntaxPattern>, v_1002294); TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002291, v_3}}, v_1002296 => +v_1002297 = template_unbox(Ast.SyntaxTerm, v_1002296); TemplateFinished{TemplateValue{Ast.BodyCase{v_1002295, v_1002297, v_1002292}}}}}
    case Ast.BodyLocal{v_1002298, v_1002299, v_1002300, v_1002301, v_1002302}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_patterns{v_1002298, v_3}}, False{}, v_1002303 => template_body_capture_patterns(v_1002298, v_3), v_1002304 => +v_1002305 = template_unbox(List<&2, Ast.SyntaxPattern>, v_1002304); template_continuation_76(v_1002299, v_1002300, v_3, v_1002301, v_1002305, v_1002302)}
    case Ast.BodyReply{v_1002306, v_1002307}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_1002306, v_3}}, v_1002308 => +v_1002309 = template_unbox(Ast.SyntaxTerm, v_1002308); TemplateFinished{TemplateValue{Ast.BodyReply{v_1002309, v_1002307}}}}

def template_body_expand_term(+v_0: Ast.SyntaxTerm, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_0:
    case Ast.TermVar{v_1002310, v_1002311, v_1002312}:
      TemplateFinished{TemplateValue{Ast.TermVar{v_1002310, v_1002311, v_1002312}}}
    case Ast.TermRef{v_1002313, v_1002314}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_reference_key{v_1002313}}, False{}, v_1002315 => template_body_reference_key(v_1002313), v_1002316 => +v_1002317 = template_unbox(String, v_1002316); TemplateFinished{TemplateValue{Ast.TermRef{v_1002317, v_1002314}}}}
    case Ast.TermBang{v_1002318, v_1002319}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002318, v_3}}, v_1002320 => +v_1002321 = template_unbox(Ast.SyntaxTerm, v_1002320); TemplateFinished{TemplateValue{Ast.TermBang{v_1002321, v_1002319}}}}
    case Ast.TermSub{v_1002322, v_1002323, v_1002324, v_1002325}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002323, v_3}}, v_1002327 => +v_1002328 = template_unbox(Ast.SyntaxTerm, v_1002327); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002324, v_3}}, v_1002329 => +v_1002330 = template_unbox(Ast.SyntaxTerm, v_1002329); TemplateFinished{TemplateValue{Ast.TermSub{{v_1002322 : Nat}, v_1002328, v_1002330, v_1002325}}}}}
    case Ast.TermLet{v_1002331, v_1002332, v_1002333, v_1002334, v_1002335, v_1002336}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_1002334, v_3}}, v_1002340 => +v_1002341 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002340); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002335, v_3}}, v_1002342 => +v_1002343 = template_unbox(Ast.SyntaxTerm, v_1002342); TemplateFinished{TemplateValue{Ast.TermLet{{v_1002331 : List<&2, String>}, {v_1002332 : List<&2, Nat>}, {v_1002333 : List<&2, Ast.Quantity>}, v_1002341, v_1002343, v_1002336}}}}}
    case Ast.TermAnn{v_1002344, v_1002345, v_1002346}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002344, v_3}}, v_1002347 => +v_1002348 = template_unbox(Ast.SyntaxTerm, v_1002347); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002345, v_3}}, v_1002349 => +v_1002350 = template_unbox(Ast.SyntaxTerm, v_1002349); TemplateFinished{TemplateValue{Ast.TermAnn{v_1002348, v_1002350, v_1002346}}}}}
    case Ast.TermTemplate{v_1002351, v_1002352}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002351, v_3}}, v_1002353 => +v_1002354 = template_unbox(Ast.SyntaxTerm, v_1002353); TemplateFinished{TemplateValue{Ast.TermTemplate{v_1002354, v_1002352}}}}
    case Ast.TermType{v_1002355, v_1002356}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002355, v_3}}, v_1002357 => +v_1002358 = template_unbox(Ast.SyntaxTerm, v_1002357); TemplateFinished{TemplateValue{Ast.TermType{v_1002358, v_1002356}}}}
    case Ast.TermQuant{}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.TermQuantity{v_1002359, v_1002360}:
      TemplateFinished{TemplateValue{Ast.TermQuantity{v_1002359, v_1002360}}}
    case Ast.TermMin{v_1002361, v_1002362, v_1002363}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002361, v_3}}, v_1002364 => +v_1002365 = template_unbox(Ast.SyntaxTerm, v_1002364); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002362, v_3}}, v_1002366 => +v_1002367 = template_unbox(Ast.SyntaxTerm, v_1002366); TemplateFinished{TemplateValue{Ast.TermMin{v_1002365, v_1002367, v_1002363}}}}}
    case Ast.TermAll{v_1002368, v_1002369, v_1002370, v_1002371, v_1002372, v_1002373}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002371, v_3}}, v_1002377 => +v_1002378 = template_unbox(Ast.SyntaxTerm, v_1002377); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002372, v_3}}, v_1002379 => +v_1002380 = template_unbox(Ast.SyntaxTerm, v_1002379); TemplateFinished{TemplateValue{Ast.TermAll{{v_1002368 : Ast.Quantity}, {v_1002369 : String}, {v_1002370 : Nat}, v_1002378, v_1002380, v_1002373}}}}}
    case Ast.TermLam{v_1002381, v_1002382, v_1002383, v_1002384, v_1002385}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002384, v_3}}, v_1002389 => +v_1002390 = template_unbox(Ast.SyntaxTerm, v_1002389); TemplateFinished{TemplateValue{Ast.TermLam{{v_1002381 : Maybe<&2, Ast.Quantity>}, {v_1002382 : String}, {v_1002383 : Nat}, v_1002390, v_1002385}}}}
    case Ast.TermApp{v_1002391, v_1002392, v_1002393}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_application{v_1002391, v_1002392, v_1002393, v_3}}, v_1002394 => +v_1002395 = template_unbox(Ast.SyntaxTerm, v_1002394); TemplateFinished{TemplateValue{v_1002395}}}
    case Ast.TermAdt{v_1002396, v_1002397, v_1002398, v_1002399}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_1002397, v_3}}, v_1002401 => +v_1002402 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002401); TemplateFinished{TemplateValue{Ast.TermAdt{{v_1002396 : String}, v_1002402, v_1002398, v_1002399}}}}
    case Ast.TermFill{v_1002403, v_1002404, v_1002405}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002403, v_3}}, v_1002406 => +v_1002407 = template_unbox(Ast.SyntaxTerm, v_1002406); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_1002404, v_3}}, v_1002408 => +v_1002409 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002408); TemplateFinished{TemplateValue{Ast.TermFill{v_1002407, v_1002409, v_1002405}}}}}
    case Ast.TermPlus{v_1002410, v_1002411, v_1002412}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002410, v_3}}, v_1002413 => +v_1002414 = template_unbox(Ast.SyntaxTerm, v_1002413); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_1002411, v_3}}, v_1002415 => +v_1002416 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002415); TemplateFinished{TemplateValue{Ast.TermPlus{v_1002414, v_1002416, v_1002412}}}}}
    case Ast.TermCtr{v_1002417, +v_1002418, v_1002419}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_stable_terms{v_1002418}}, v_1002420 => +v_1002421 = template_unbox(Bool, v_1002420); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_constructor_stable{v_1002421, v_0, v_1002417, v_1002418, v_1002419, v_3}}, v_1002422 => +v_1002423 = template_unbox(Ast.SyntaxTerm, v_1002422); TemplateFinished{TemplateValue{v_1002423}}}}
    case Ast.TermString{v_1002424, v_1002425, v_1002426}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.TermMat{v_1002427, v_1002428, v_1002429, v_1002430}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002428, v_3}}, v_1002432 => +v_1002433 = template_unbox(Ast.SyntaxTerm, v_1002432); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002429, v_3}}, v_1002434 => +v_1002435 = template_unbox(Ast.SyntaxTerm, v_1002434); TemplateFinished{TemplateValue{Ast.TermMat{{v_1002427 : String}, v_1002433, v_1002435, v_1002430}}}}}
    case Ast.TermAbsurd{v_1002436}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.TermEqual{v_1002437, v_1002438, v_1002439, v_1002440}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002437, v_3}}, v_1002441 => +v_1002442 = template_unbox(Ast.SyntaxTerm, v_1002441); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002438, v_3}}, v_1002443 => +v_1002444 = template_unbox(Ast.SyntaxTerm, v_1002443); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002439, v_3}}, v_1002445 => +v_1002446 = template_unbox(Ast.SyntaxTerm, v_1002445); TemplateFinished{TemplateValue{Ast.TermEqual{v_1002442, v_1002444, v_1002446, v_1002440}}}}}}
    case Ast.TermRefl{v_1002447}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.TermRewrite{v_1002448, v_1002449, v_1002450, v_1002451}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002448, v_3}}, v_1002452 => +v_1002453 = template_unbox(Ast.SyntaxTerm, v_1002452); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002449, v_3}}, v_1002454 => +v_1002455 = template_unbox(Ast.SyntaxTerm, v_1002454); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002450, v_3}}, v_1002456 => +v_1002457 = template_unbox(Ast.SyntaxTerm, v_1002456); TemplateFinished{TemplateValue{Ast.TermRewrite{v_1002453, v_1002455, v_1002457, v_1002451}}}}}}
    case Ast.TermHole{v_1002458, v_1002459}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.BodyMatch{v_1002460, v_1002461, v_1002462}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_1002460, v_3}}, v_1002463 => +v_1002464 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002463); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_1002461, v_3}}, v_1002465 => +v_1002466 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002465); TemplateFinished{TemplateValue{Ast.BodyMatch{v_1002464, v_1002466, v_1002462}}}}}
    case Ast.BodyCase{v_1002467, v_1002468, v_1002469}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002468, v_3}}, v_1002471 => +v_1002472 = template_unbox(Ast.SyntaxTerm, v_1002471); TemplateFinished{TemplateValue{Ast.BodyCase{{v_1002467 : List<&2, Ast.SyntaxPattern>}, v_1002472, v_1002469}}}}
    case Ast.BodyLocal{v_1002473, v_1002474, v_1002475, v_1002476, v_1002477}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_1002475, v_3}}, v_1002480 => +v_1002481 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002480); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002476, v_3}}, v_1002482 => +v_1002483 = template_unbox(Ast.SyntaxTerm, v_1002482); TemplateFinished{TemplateValue{Ast.BodyLocal{{v_1002473 : List<&2, Ast.SyntaxPattern>}, {v_1002474 : Ast.Quantity}, v_1002481, v_1002483, v_1002477}}}}}
    case Ast.BodyReply{v_1002484, v_1002485}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002484, v_3}}, v_1002486 => +v_1002487 = template_unbox(Ast.SyntaxTerm, v_1002486); TemplateFinished{TemplateValue{Ast.BodyReply{v_1002487, v_1002485}}}}

def template_body_expand_stable_term(v_0: Ast.SyntaxTerm) -> TemplateProgress<Bool>:
  match v_0:
    case Ast.TermVar{_, _, _}:
      TemplateFinished{TemplateValue{True{}}}
    case Ast.TermCtr{_, v_12, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_stable_terms{v_12}}, v_1000621 => +v_1000620 = template_unbox(Bool, v_1000621); TemplateFinished{TemplateValue{v_1000620}}}
    case Ast.TermString{_, _, _}:
      TemplateFinished{TemplateValue{True{}}}
    case Ast.TermQuant{}:
      TemplateFinished{TemplateValue{True{}}}
    case Ast.TermQuantity{_, _}:
      TemplateFinished{TemplateValue{True{}}}
    case Ast.TermAbsurd{_}:
      TemplateFinished{TemplateValue{True{}}}
    case Ast.TermRefl{_}:
      TemplateFinished{TemplateValue{True{}}}
    case Ast.TermHole{_, _}:
      TemplateFinished{TemplateValue{True{}}}
    case _:
      TemplateFinished{TemplateValue{False{}}}

def template_body_expand_stable_terms(v_1: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Bool>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{True{}}}
    case v_5 <> v_6:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_stable_term{v_5}}, False{}, v_1000626 => template_body_expand_stable_term(v_5), v_1000625 => +v_1000622 = template_unbox(Bool, v_1000625); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_stable_tail{v_1000622, v_6}}, v_1000624 => +v_1000623 = template_unbox(Bool, v_1000624); TemplateFinished{TemplateValue{v_1000623}}}}

def template_body_expand_stable_tail(v_1: Bool, v_3: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Bool>:
  match v_1:
    case True{}:
      template_body_expand_stable_terms(v_3)
    case False{}:
      TemplateFinished{TemplateValue{False{}}}

def template_body_expand_constructor_stable(v_1: Bool, v_2: Ast.SyntaxTerm, v_4: String, v_6: List<&2, Ast.SyntaxTerm>, v_7: Ast.SourceSpan, v_10: List<&2, TemplateDef>) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_1:
    case True{}:
      TemplateFinished{TemplateValue{v_2}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_6, v_10}}, v_1002489 => +v_1002490 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002489); TemplateFinished{TemplateValue{Ast.TermCtr{{v_4 : String}, v_1002490, v_7}}}}

def template_body_expand_application(+v_0: Ast.SyntaxTerm, +v_1: Ast.SyntaxTerm, +v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>) -> TemplateProgress<Ast.SyntaxTerm>:
  v_7 = {Ast.TermApp{v_0, v_1, v_2} : Ast.SyntaxTerm}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_flatten_application{v_7}}, False{}, v_1000639 => template_body_flatten_application(v_7), v_1000638 => +v_1000635 = template_unbox(ApplicationSpine, v_1000638); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_application_spine{{v_0 : Ast.SyntaxTerm}, {v_1 : Ast.SyntaxTerm}, {v_2 : Ast.SourceSpan}, {v_5 : List<&2, TemplateDef>}, v_1000635}}, v_1000637 => +v_1000636 = template_unbox(Ast.SyntaxTerm, v_1000637); TemplateFinished{TemplateValue{v_1000636}}}}

def template_body_expand_application_spine(v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, +v_5: List<&2, TemplateDef>, v_7: ApplicationSpine) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_7:
    case ApplicationSpine{+v_1002491, v_1002492, v_1002493}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_template_for_head{v_1002491, v_5}}, False{}, v_1002500 => template_body_template_for_head(v_1002491, v_5), v_1002501 => +v_1002502 = template_unbox(Maybe<&2, TemplateDef>, v_1002501); TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_application_template{{v_0 : Ast.SyntaxTerm}, {v_1 : Ast.SyntaxTerm}, {v_2 : Ast.SourceSpan}, {v_5 : List<&2, TemplateDef>}, {v_1002491 : Ast.SyntaxTerm}, {v_1002492 : List<&2, Ast.SyntaxTerm>}, v_1002502}}, v_1002503 => +v_1002504 = template_unbox(Ast.SyntaxTerm, v_1002503); TemplateFinished{TemplateValue{v_1002504}}}}

def template_continuation_84(+v_1000657: Nat, v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>, v_6: Ast.SyntaxTerm, +v_8: List<&2, Ast.SyntaxTerm>, v_15: TemplateDef) -> TemplateProgress<Ast.SyntaxTerm>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_take_template_args{v_8, v_1000657}}, False{}, v_1000670 => template_body_take_template_args(v_8, v_1000657), v_1000669 => +v_1000666 = template_unbox(Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_1000669); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_application_arguments{{v_0 : Ast.SyntaxTerm}, {v_1 : Ast.SyntaxTerm}, {v_2 : Ast.SourceSpan}, {v_5 : List<&2, TemplateDef>}, {v_6 : Ast.SyntaxTerm}, {v_8 : List<&2, Ast.SyntaxTerm>}, {v_15 : TemplateDef}, {v_1000657 : Nat}, v_1000666}}, v_1000668 => +v_1000667 = template_unbox(Ast.SyntaxTerm, v_1000668); TemplateFinished{TemplateValue{v_1000667}}}}

def template_body_expand_application_template(+v_0: Ast.SyntaxTerm, +v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, +v_5: List<&2, TemplateDef>, v_6: Ast.SyntaxTerm, v_8: List<&2, Ast.SyntaxTerm>, v_11: Maybe<&2, TemplateDef>) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_11:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_0, v_5}}, False{}, v_1002505 => template_body_expand_term(v_0, v_5), v_1002506 => +v_1002507 = template_unbox(Ast.SyntaxTerm, v_1002506); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_1, v_5}}, False{}, v_1002508 => template_body_expand_term(v_1, v_5), v_1002509 => +v_1002510 = template_unbox(Ast.SyntaxTerm, v_1002509); TemplateFinished{TemplateValue{Ast.TermApp{v_1002507, v_1002510, v_2}}}}}
    case Some{+v_1002511}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_arity{v_1002511}}, v_1002512 => +v_1002513 = template_unbox(Nat, v_1002512); template_continuation_84(v_1002513, v_0, v_1, v_2, v_5, v_6, v_8, v_1002511)}

def template_body_template_arity(v_1: TemplateDef) -> TemplateProgress<Nat>:
  match v_1:
    case TemplateDef{_, _, _, _, _, Ast.Definition{_, v_21, _, _, _, _}, _}:
      template_body_leading_template_count(v_21)

def template_continuation_87(+v_1000684: Ast.SyntaxTerm, v_22: List<&2, Ast.SyntaxTerm>, v_5: List<&2, TemplateDef>, v_2: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_22, v_5}}, v_1000688 => +v_1000686 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1000688); template_body_reapply_args({v_1000684 : Ast.SyntaxTerm}, v_1000686, v_2)}

def template_continuation_88(+v_1000681: List<&2, Ast.SyntaxTerm>, v_6: Ast.SyntaxTerm, v_10: TemplateDef, v_22: List<&2, Ast.SyntaxTerm>, v_5: List<&2, TemplateDef>, v_2: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  v_27 = v_1000681
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_generated_key{v_10, v_27}}, False{}, v_1000691 => template_body_generated_key(v_10, v_27), v_1000690 => +v_1000683 = template_unbox(String, v_1000690); TemplatePending{TemplateRequestGroup_1{TemplateRequest_specialize_head{{v_6 : Ast.SyntaxTerm}, v_1000683}}, v_1000689 => +v_1000684 = template_unbox(Ast.SyntaxTerm, v_1000689); template_continuation_87(v_1000684, v_22, v_5, v_2)}}

def template_continuation_89(+v_1000679: List<&2, Ast.SyntaxTerm>, v_19: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, TemplateDef>, +v_10: TemplateDef, v_6: Ast.SyntaxTerm, v_2: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_19, v_5}}, v_1000694 => +v_1000680 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1000694); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1000680, template_pure_template_capture_names(v_10)}}, False{}, v_1000693 => template_body_capture_terms(v_1000680, template_pure_template_capture_names(v_10)), v_1000692 => +v_1000681 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1000692); template_continuation_88(v_1000681, v_6, v_10, v_1000679, v_5, v_2)}}

def template_body_expand_application_arguments(+v_0: Ast.SyntaxTerm, +v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, +v_5: List<&2, TemplateDef>, v_6: Ast.SyntaxTerm, v_8: List<&2, Ast.SyntaxTerm>, v_10: TemplateDef, v_12: Nat, v_15: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_15:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_0, v_5}}, False{}, v_1002514 => template_body_expand_term(v_0, v_5), v_1002515 => +v_1002516 = template_unbox(Ast.SyntaxTerm, v_1002515); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_1, v_5}}, False{}, v_1002517 => template_body_expand_term(v_1, v_5), v_1002518 => +v_1002519 = template_unbox(Ast.SyntaxTerm, v_1002518); TemplateFinished{TemplateValue{Ast.TermApp{v_1002516, v_1002519, v_2}}}}}
    case Some{v_1002520}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_drop_args{v_8, v_12}}, v_1002521 => +v_1002522 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002521); template_continuation_89(v_1002522, v_1002520, v_5, v_10, v_6, v_2)}

def template_body_specialize_head(+v_0: Ast.SyntaxTerm, v_2: String) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_0:
    case Ast.TermRef{v_1002523, v_1002524}:
      TemplateFinished{TemplateValue{Ast.TermRef{v_2, v_1002524}}}
    case Ast.TermBang{v_1002525, +v_1002526}:
      TemplateFinished{TemplateValue{Ast.TermBang{Ast.TermRef{v_2, v_1002526}, v_1002526}}}
    case v_1002527:
      TemplateFinished{TemplateValue{v_0}}

def template_body_drop_args(+v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat) -> TemplateProgress<List<&2, Ast.SyntaxTerm>>:
  match v_1, v_3:
    case v_1002528, 0n:
      TemplateFinished{TemplateValue{v_1}}
    case +v_1002529 <> v_1002530, 1n+v_1002531:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_drop_args{v_1002530, v_1002531}}, v_1002532 => +v_1002533 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002532); TemplateFinished{TemplateValue{v_1002533}}}
    case [], v_1002534:
      TemplateFinished{TemplateValue{[]}}

def template_continuation_93(v_1000698: Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody)), v_3: String, v_27: Bool, v_28: Ast.SourceSpan) -> TemplateProgress<Ast.Definition>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_specialize_definition_result{v_3, v_27, v_28, v_1000698}}, v_1000700 => +v_1000699 = template_unbox(Ast.Definition, v_1000700); TemplateFinished{TemplateValue{v_1000699}}}

def template_body_specialize_definition(v_1: TemplateDef, v_3: String, v_5: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Ast.Definition>:
  match v_1:
    case TemplateDef{v_1002535, v_1002536, v_1002537, v_1002538, v_1002539, Ast.Definition{v_1002540, v_1002541, v_1002542, v_1002543, v_1002544, v_1002545}, v_1002546}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_specialize_prefix{v_1002541, v_5, v_1002542, v_1002543}}, v_1002547 => v_1002548 = template_unbox(Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody)), v_1002547); template_continuation_93(v_1002548, v_3, v_1002544, v_1002545)}

def template_body_specialize_definition_result(v_1: String, v_3: Bool, v_4: Ast.SourceSpan, v_6: Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))) -> TemplateProgress<Ast.Definition>:
  match v_6:
    case (v_1002549, v_1002550, v_1002551):
      TemplateFinished{TemplateValue{Ast.Definition{v_1, v_1002549, v_1002550, v_1002551, v_3, v_4}}}

def template_continuation_96(+v_1000708: Ast.DefBody, v_29: List<&2, Ast.TelescopeItem>, v_20: List<&2, Ast.SyntaxTerm>, v_32: Ast.OptionalTerm) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_specialize_prefix{v_29, v_20, v_32, v_1000708}}, v_1000710 => v_1000709 = template_unbox(Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody)), v_1000710); TemplateFinished{TemplateValue{v_1000709}}}

def template_continuation_97(+v_1000707: Ast.OptionalTerm, v_5: Ast.DefBody, v_23: Nat, v_26: Ast.SyntaxTerm, v_29: List<&2, Ast.TelescopeItem>, v_20: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_substitute_body{v_5, v_23, v_26}}, v_1000711 => +v_1000708 = template_unbox(Ast.DefBody, v_1000711); template_continuation_96(v_1000708, v_29, v_20, v_1000707)}

def template_continuation_98(+v_1000706: List<&2, Ast.TelescopeItem>, v_4: Ast.OptionalTerm, +v_23: Nat, +v_26: Ast.SyntaxTerm, v_5: Ast.DefBody, v_20: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_substitute_optional{v_4, v_23, v_26}}, v_1000712 => +v_1000707 = template_unbox(Ast.OptionalTerm, v_1000712); template_continuation_97(v_1000707, v_5, v_23, v_26, v_1000706, v_20)}

def template_continuation_99(v_1000703: Ast.SyntaxTerm, v_1000704: Ast.SyntaxTerm, +v_1000705: Ast.SourceSpan, v_18: List<&2, Ast.TelescopeItem>, v_4: Ast.OptionalTerm, v_23: Nat, v_5: Ast.DefBody, v_20: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  +v_26 = {Ast.TermAnn{v_1000703, v_1000704, v_1000705} : Ast.SyntaxTerm}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_substitute_binders{v_18, 0n, v_26}}, v_1000713 => +v_1000706 = template_unbox(List<&2, Ast.TelescopeItem>, v_1000713); template_continuation_98(v_1000706, v_4, v_23, v_26, v_5, v_20)}

def template_continuation_100(+v_1000702: Nat, +v_19: Ast.SyntaxTerm, v_16: Ast.SyntaxTerm, v_18: List<&2, Ast.TelescopeItem>, v_4: Ast.OptionalTerm, v_5: Ast.DefBody, v_20: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_span_of{v_19}}, False{}, v_1000715 => template_body_span_of(v_19), v_1000714 => +v_1000705 = template_unbox(Ast.SourceSpan, v_1000714); template_continuation_99({v_19 : Ast.SyntaxTerm}, {v_16 : Ast.SyntaxTerm}, v_1000705, v_18, v_4, v_1000702, v_5, v_20)}

def template_body_specialize_prefix(+v_1: List<&2, Ast.TelescopeItem>, v_3: List<&2, Ast.SyntaxTerm>, v_4: Ast.OptionalTerm, v_5: Ast.DefBody) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  match v_1, v_3:
    case Ast.TemplateBinder{v_1002552, v_1002553, v_1002554, v_1002555} <> +v_1002556, +v_1002557 <> v_1002558:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_binder_count{v_1002556}}, v_1002559 => +v_1002560 = template_unbox(Nat, v_1002559); template_continuation_100(v_1002560, v_1002557, v_1002554, v_1002556, v_4, v_5, v_1002558)}
    case v_1002561, v_1002562:
      TemplateFinished{TemplateValue{(v_1, v_4, v_5)}}

def template_body_binder_count(v_1: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Nat>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{0n}}
    case +_ <> v_6:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_binder_count{v_6}}, v_1000719 => +v_1000718 = template_unbox(Nat, v_1000719); TemplateFinished{TemplateValue{Nat.add({1n : Nat}, v_1000718)}}}

def template_match_103(+v_8: Ast.TelescopeItem, +v_3: Nat, +v_4: Ast.SyntaxTerm, v_9: List<&2, Ast.TelescopeItem>) -> TemplateProgress<List<&2, Ast.TelescopeItem>>:
  match v_8:
    case Ast.Binder{v_15, v_16, v_17, v_18, v_19}:
      v_1000720 = {Ast.Binder{v_15, v_16, v_17, Core.subst(v_3, v_4, v_18), v_19} : Ast.TelescopeItem}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_substitute_binders{v_9, Nat.add(v_3, 1n), v_4}}, v_1000722 => +v_1000721 = template_unbox(List<&2, Ast.TelescopeItem>, v_1000722); TemplateFinished{TemplateValue{v_1000720 <> v_1000721}}}
    case Ast.TemplateBinder{v_27, v_28, v_29, v_30}:
      v_1000723 = {Ast.TemplateBinder{v_27, v_28, Core.subst(v_3, v_4, v_29), v_30} : Ast.TelescopeItem}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_substitute_binders{v_9, Nat.add(v_3, 1n), v_4}}, v_1000725 => +v_1000724 = template_unbox(List<&2, Ast.TelescopeItem>, v_1000725); TemplateFinished{TemplateValue{v_1000723 <> v_1000724}}}

def template_body_substitute_binders(v_1: List<&2, Ast.TelescopeItem>, v_3: Nat, v_4: Ast.SyntaxTerm) -> TemplateProgress<List<&2, Ast.TelescopeItem>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_8 <> v_9:
      template_match_103(v_8, v_3, v_4, v_9)

def template_body_substitute_optional(+v_0: Ast.OptionalTerm, v_2: Nat, v_3: Ast.SyntaxTerm) -> TemplateProgress<Ast.OptionalTerm>:
  match v_0:
    case Ast.NoTerm{}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.SomeTerm{v_1002563}:
      TemplateFinished{TemplateValue{Ast.SomeTerm{Core.subst(v_2, v_3, v_1002563)}}}

def template_body_substitute_body(+v_0: Ast.DefBody, v_2: Nat, v_3: Ast.SyntaxTerm) -> TemplateProgress<Ast.DefBody>:
  match v_0:
    case Ast.DefTerm{v_1002564}:
      TemplateFinished{TemplateValue{Ast.DefTerm{Core.subst(v_2, v_3, v_1002564)}}}
    case Ast.DefImports{v_1002565}:
      TemplateFinished{TemplateValue{v_0}}

def template_body_expand_terms(v_1: List<&2, Ast.SyntaxTerm>, +v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.SyntaxTerm>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002566 <> v_1002567:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002566, v_4}}, False{}, v_1002568 => template_body_expand_term(v_1002566, v_4), v_1002569 => +v_1002570 = template_unbox(Ast.SyntaxTerm, v_1002569); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_1002567, v_4}}, v_1002571 => +v_1002572 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002571); TemplateFinished{TemplateValue{v_1002570 <> v_1002572}}}}

def template_match_108(+v_13: Ast.TopLevel, v_1: String, v_14: List<&2, Ast.TopLevel>, +v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_13:
    case Ast.DefTop{Ast.Definition{v_21, +v_22, v_23, v_24, v_25, v_26}}:
      v_1000731 = {v_1 : String}
      v_1000738 = {v_14 : List<&2, Ast.TopLevel>}
      v_1000740 = {v_9 : List<&2, GeneratedIdentity>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_has_template_binder{v_22}}, False{}, v_1000745 => template_body_has_template_binder(v_22), v_1000744 => +v_1000741 = template_unbox(Bool, v_1000744); TemplatePending{TemplateRequestGroup_1{TemplateRequest_strip_template_definition{v_1000731, {v_21 : String}, {v_22 : List<&2, Ast.TelescopeItem>}, {v_23 : Ast.OptionalTerm}, {v_24 : Ast.DefBody}, {v_25 : Bool}, {v_26 : Ast.SourceSpan}, v_1000738, {v_6 : List<&2, TemplateDef>}, v_1000740, v_1000741}}, v_1000743 => +v_1000742 = template_unbox(List<&2, Ast.TopLevel>, v_1000743); TemplateFinished{TemplateValue{v_1000742}}}}
    case Ast.TypeTop{Ast.TypeDecl{v_34, v_35, v_36, v_37, v_38}}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_binders{v_35, v_6}}, v_1000755 => +v_1000747 = template_unbox(List<&2, Ast.TelescopeItem>, v_1000755); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_36, v_6}}, False{}, v_1000754 => template_body_expand_term(v_36, v_6), v_1000753 => +v_1000748 = template_unbox(Ast.SyntaxTerm, v_1000753); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_constructors{v_37, v_6}}, v_1000752 => +v_1000749 = template_unbox(List<&2, Ast.ConstructorDecl>, v_1000752); TemplatePending{TemplateRequestGroup_1{TemplateRequest_strip_template_decls{v_1, v_14, v_6, v_9}}, v_1000751 => +v_1000750 = template_unbox(List<&2, Ast.TopLevel>, v_1000751); TemplateFinished{TemplateValue{Ast.TypeTop{Ast.TypeDecl{{v_34 : String}, v_1000747, v_1000748, v_1000749, v_38}} <> v_1000750}}}}}}
    case Ast.LawTop{Ast.LawDecl{v_47, v_48, v_49, v_50}}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_clauses{v_48, v_6}}, v_1000763 => +v_1000757 = template_unbox(List<&2, Ast.Clause>, v_1000763); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_49, v_6}}, False{}, v_1000762 => template_body_expand_term(v_49, v_6), v_1000761 => +v_1000758 = template_unbox(Ast.SyntaxTerm, v_1000761); TemplatePending{TemplateRequestGroup_1{TemplateRequest_strip_template_decls{v_1, v_14, v_6, v_9}}, v_1000760 => +v_1000759 = template_unbox(List<&2, Ast.TopLevel>, v_1000760); TemplateFinished{TemplateValue{Ast.LawTop{Ast.LawDecl{{v_47 : String}, v_1000757, v_1000758, v_50}} <> v_1000759}}}}}

def template_body_strip_template_decls(v_1: String, v_3: List<&2, Ast.TopLevel>, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002573 <> v_1002574:
      template_match_108(v_1002573, v_1, v_1002574, v_6, v_9)

def template_body_strip_template_definition(+v_1: String, +v_3: String, v_5: List<&2, Ast.TelescopeItem>, v_6: Ast.OptionalTerm, v_7: Ast.DefBody, v_9: Bool, v_10: Ast.SourceSpan, v_12: List<&2, Ast.TopLevel>, +v_15: List<&2, TemplateDef>, +v_18: List<&2, GeneratedIdentity>, v_20: Bool) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_20:
    case True{}:
      v_1002576 = {v_12 : List<&2, Ast.TopLevel>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_canonical_template_key{v_3, v_15}}, v_1002579 => +v_1002580 = template_unbox(Maybe<&2, String>, v_1002579); TemplatePending{TemplateRequestGroup_1{TemplateRequest_strip_canonical_template{{v_1 : String}, v_1002576, {v_15 : List<&2, TemplateDef>}, {v_18 : List<&2, GeneratedIdentity>}, v_1002580}}, v_1002581 => +v_1002582 = template_unbox(List<&2, Ast.TopLevel>, v_1002581); TemplateFinished{TemplateValue{v_1002582}}}}
    case False{}:
      v_1002585 = {Ast.Definition{v_3, v_5, v_6, v_7, v_9, v_10} : Ast.Definition}
      v_1002586 = {v_12 : List<&2, Ast.TopLevel>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_is_template_instance{v_1, v_3, v_18}}, v_1002589 => +v_1002590 = template_unbox(Bool, v_1002589); TemplatePending{TemplateRequestGroup_1{TemplateRequest_strip_instance_or_definition{{v_1 : String}, {v_3 : String}, v_1002585, v_1002586, {v_15 : List<&2, TemplateDef>}, {v_18 : List<&2, GeneratedIdentity>}, v_1002590}}, v_1002591 => +v_1002592 = template_unbox(List<&2, Ast.TopLevel>, v_1002591); TemplateFinished{TemplateValue{v_1002592}}}}

def template_body_strip_canonical_template(+v_1: String, +v_3: List<&2, Ast.TopLevel>, +v_6: List<&2, TemplateDef>, +v_9: List<&2, GeneratedIdentity>, v_12: Maybe<&2, String>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_12:
    case Some{v_1002593}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_instances{v_3, v_1002593, v_6, v_9}}, v_1002594 => +v_1002595 = template_unbox(List<&2, Ast.TopLevel>, v_1002594); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_strip_template_decls{v_1, v_3, v_6, v_9}}, False{}, v_1002596 => template_body_strip_template_decls(v_1, v_3, v_6, v_9), v_1002597 => +v_1002598 = template_unbox(List<&2, Ast.TopLevel>, v_1002597); TemplateFinished{TemplateValue{List.append(&2, Ast.TopLevel, v_1002595, v_1002598)}}}}
    case None{}:
      template_body_strip_template_decls(v_1, v_3, v_6, v_9)

def template_body_strip_instance_or_definition(+v_1: String, v_3: String, v_4: Ast.Definition, +v_6: List<&2, Ast.TopLevel>, +v_9: List<&2, TemplateDef>, +v_12: List<&2, GeneratedIdentity>, v_14: Bool) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_14:
    case True{}:
      template_body_strip_template_decls(v_1, v_6, v_9, v_12)
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_definition{v_4, v_9}}, v_1002599 => +v_1002600 = template_unbox(Ast.Definition, v_1002599); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_strip_template_decls{v_1, v_6, v_9, v_12}}, False{}, v_1002601 => template_body_strip_template_decls(v_1, v_6, v_9, v_12), v_1002602 => +v_1002603 = template_unbox(List<&2, Ast.TopLevel>, v_1002602); TemplateFinished{TemplateValue{Ast.DefTop{v_1002600} <> v_1002603}}}}

def template_match_113(+v_9: TemplateDef, +v_1: String, v_10: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, String>>:
  match v_9:
    case TemplateDef{+v_18, v_19, _, _, _, _, _}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_strip_namespace{v_18, v_19}}, False{}, v_1000802 => template_body_strip_namespace(v_18, v_19), v_1000801 => +v_1000798 = template_unbox(String, v_1000801); TemplatePending{TemplateRequestGroup_1{TemplateRequest_canonical_template_match{{v_1 : String}, {v_18 : String}, {v_10 : List<&2, TemplateDef>}, String.eq({v_1 : String}, v_1000798)}}, v_1000800 => +v_1000799 = template_unbox(Maybe<&2, String>, v_1000800); TemplateFinished{TemplateValue{v_1000799}}}}

def template_body_canonical_template_key(v_1: String, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, String>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1002604 <> v_1002605:
      template_match_113(v_1002604, v_1, v_1002605)

def template_body_canonical_template_match(v_1: String, v_3: String, v_6: List<&2, TemplateDef>, v_8: Bool) -> TemplateProgress<Maybe<&2, String>>:
  match v_8:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_3}}}
    case False{}:
      template_body_canonical_template_key(v_1, v_6)

def template_match_116(+v_9: GeneratedIdentity, +v_1: String, v_10: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, String>>:
  match v_9:
    case GeneratedIdentity{_, v_16, v_17, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_generated_local_key_match{v_1, v_17, v_10, String.eq(v_1, v_16)}}, v_1000805 => +v_1000804 = template_unbox(List<&2, String>, v_1000805); TemplateFinished{TemplateValue{v_1000804}}}

def template_body_generated_local_keys(v_1: String, v_4: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, String>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002606 <> v_1002607:
      template_match_116(v_1002606, v_1, v_1002607)

def template_body_generated_local_key_match(+v_1: String, v_3: String, +v_6: List<&2, GeneratedIdentity>, v_8: Bool) -> TemplateProgress<List<&2, String>>:
  match v_8:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_generated_local_keys{v_1, v_6}}, False{}, v_1002609 => template_body_generated_local_keys(v_1, v_6), v_1002610 => +v_1002611 = template_unbox(List<&2, String>, v_1002610); TemplateFinished{TemplateValue{{v_3 : String} <> v_1002611}}}
    case False{}:
      template_body_generated_local_keys(v_1, v_6)

def template_body_has_generated_local_key(v_1: String, v_4: List<&2, String>) -> TemplateProgress<Bool>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_string{v_1, v_4}}, v_1000812 => +v_1000811 = template_unbox(Bool, v_1000812); TemplateFinished{TemplateValue{v_1000811}}}

def template_continuation_119(+v_1000813: String, v_6: List<&2, GeneratedIdentity>) -> TemplateProgress<Bool>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_find_generated_identity{v_1000813, v_6}}, v_1000815 => +v_1000814 = template_unbox(Maybe<&2, GeneratedIdentity>, v_1000815); TemplateFinished{TemplateValue{template_pure_generated_identity_found(v_1000814)}}}

def template_body_is_template_instance(v_1: String, v_3: String, v_6: List<&2, GeneratedIdentity>) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_qualify{v_1, v_3}}, False{}, v_1000817 => template_body_qualify(v_1, v_3), v_1000816 => +v_1000813 = template_unbox(String, v_1000816); template_continuation_119(v_1000813, v_6)}

def template_body_generated_identity_found(v_2: Maybe<&2, GeneratedIdentity>) -> TemplateProgress<Bool>:
  TemplateFinished{TemplateValue{template_pure_generated_identity_found(v_2)}}

def template_continuation_120(+v_1000818: List<&2, String>, v_1: List<&2, Ast.TopLevel>, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_instances_for_keys{v_1, v_1000818, v_6}}, v_1000820 => +v_1000819 = template_unbox(List<&2, Ast.TopLevel>, v_1000820); TemplateFinished{TemplateValue{v_1000819}}}

def template_body_template_instances(v_1: List<&2, Ast.TopLevel>, v_3: String, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_generated_local_keys{v_3, v_9}}, False{}, v_1000822 => template_body_generated_local_keys(v_3, v_9), v_1000821 => +v_1000818 = template_unbox(List<&2, String>, v_1000821); template_continuation_120(v_1000818, v_1, v_6)}

def template_match_121(+v_11: Ast.TopLevel, v_12: List<&2, Ast.TopLevel>, v_7: List<&2, TemplateDef>, +v_4: List<&2, String>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_11:
    case Ast.DefTop{Ast.Definition{+v_19, v_20, v_21, v_22, v_23, v_24}}:
      v_1000829 = {v_12 : List<&2, Ast.TopLevel>}
      v_1000830 = {v_7 : List<&2, TemplateDef>}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_has_generated_local_key{v_19, v_4}}, False{}, v_1000836 => template_body_has_generated_local_key(v_19, v_4), v_1000835 => +v_1000832 = template_unbox(Bool, v_1000835); TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_instance_definition{{v_19 : String}, {v_20 : List<&2, Ast.TelescopeItem>}, {v_21 : Ast.OptionalTerm}, {v_22 : Ast.DefBody}, {v_23 : Bool}, {v_24 : Ast.SourceSpan}, v_1000829, v_1000830, {v_4 : List<&2, String>}, v_1000832}}, v_1000834 => +v_1000833 = template_unbox(List<&2, Ast.TopLevel>, v_1000834); TemplateFinished{TemplateValue{v_1000833}}}}
    case _:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_instances_for_keys{v_12, v_4, v_7}}, v_1000838 => +v_1000837 = template_unbox(List<&2, Ast.TopLevel>, v_1000838); TemplateFinished{TemplateValue{v_1000837}}}

def template_body_template_instances_for_keys(v_1: List<&2, Ast.TopLevel>, v_4: List<&2, String>, v_7: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002612 <> v_1002613:
      template_match_121(v_1002612, v_1002613, v_7, v_4)

def template_body_template_instance_definition(v_1: String, v_3: List<&2, Ast.TelescopeItem>, v_4: Ast.OptionalTerm, v_5: Ast.DefBody, v_7: Bool, v_8: Ast.SourceSpan, +v_10: List<&2, Ast.TopLevel>, +v_13: List<&2, TemplateDef>, +v_16: List<&2, String>, v_18: Bool) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_18:
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_definition{Ast.Definition{v_1, v_3, v_4, v_5, v_7, v_8}, v_13}}, v_1002614 => +v_1002615 = template_unbox(Ast.Definition, v_1002614); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_template_instances_for_keys{v_10, v_16, v_13}}, False{}, v_1002616 => template_body_template_instances_for_keys(v_10, v_16, v_13), v_1002617 => +v_1002618 = template_unbox(List<&2, Ast.TopLevel>, v_1002617); TemplateFinished{TemplateValue{Ast.DefTop{v_1002615} <> v_1002618}}}}
    case False{}:
      template_body_template_instances_for_keys(v_10, v_16, v_13)

def template_match_124(+v_8: Ast.ConstructorDecl, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.ConstructorDecl>) -> TemplateProgress<List<&2, Ast.ConstructorDecl>>:
  match v_8:
    case Ast.Constructor{v_13, v_14, v_15}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_binders{v_14, v_4}}, v_1000849 => +v_1000846 = template_unbox(List<&2, Ast.TelescopeItem>, v_1000849); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_constructors{v_9, v_4}}, v_1000848 => +v_1000847 = template_unbox(List<&2, Ast.ConstructorDecl>, v_1000848); TemplateFinished{TemplateValue{Ast.Constructor{{v_13 : String}, v_1000846, v_15} <> v_1000847}}}}

def template_body_expand_constructors(v_1: List<&2, Ast.ConstructorDecl>, v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.ConstructorDecl>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_8 <> v_9:
      template_match_124(v_8, v_4, v_9)

def template_match_126(+v_8: Ast.Clause, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.Clause>) -> TemplateProgress<List<&2, Ast.Clause>>:
  match v_8:
    case Ast.ClauseFor{v_16, v_17, v_18, v_19, v_20, v_21}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_19, v_4}}, False{}, v_1000859 => template_body_expand_term(v_19, v_4), v_1000858 => +v_1000853 = template_unbox(Ast.SyntaxTerm, v_1000858); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_maybe{v_20, v_4}}, v_1000857 => +v_1000854 = template_unbox(Maybe<&2, Ast.SyntaxTerm>, v_1000857); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_clauses{v_9, v_4}}, v_1000856 => +v_1000855 = template_unbox(List<&2, Ast.Clause>, v_1000856); TemplateFinished{TemplateValue{Ast.ClauseFor{{v_16 : Bool}, {v_17 : Ast.Quantity}, {v_18 : String}, v_1000853, v_1000854, v_21} <> v_1000855}}}}}

def template_body_expand_clauses(v_1: List<&2, Ast.Clause>, v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.Clause>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_8 <> v_9:
      template_match_126(v_8, v_4, v_9)

def template_body_expand_maybe(v_1: Maybe<&2, Ast.SyntaxTerm>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SyntaxTerm>>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{None{}}}
    case Some{v_6}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_6, v_4}}, False{}, v_1000862 => template_body_expand_term(v_6, v_4), v_1000861 => +v_1000860 = template_unbox(Ast.SyntaxTerm, v_1000861); TemplateFinished{TemplateValue{Some{v_1000860}}}}

def template_body_expand_definition(v_0: Ast.Definition, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.Definition>:
  match v_0:
    case Ast.Definition{v_1002619, v_1002620, v_1002621, v_1002622, v_1002623, v_1002624}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_binders{v_1002620, v_3}}, v_1002626 => +v_1002627 = template_unbox(List<&2, Ast.TelescopeItem>, v_1002626); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_optional{v_1002621, v_3}}, v_1002628 => +v_1002629 = template_unbox(Ast.OptionalTerm, v_1002628); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_body{v_1002622, v_3}}, v_1002630 => +v_1002631 = template_unbox(Ast.DefBody, v_1002630); TemplateFinished{TemplateValue{Ast.Definition{{v_1002619 : String}, v_1002627, v_1002629, v_1002631, v_1002623, v_1002624}}}}}}

def template_body_expand_body(+v_0: Ast.DefBody, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.DefBody>:
  match v_0:
    case Ast.DefTerm{v_1002632}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002632, v_3}}, False{}, v_1002633 => template_body_expand_term(v_1002632, v_3), v_1002634 => +v_1002635 = template_unbox(Ast.SyntaxTerm, v_1002634); TemplateFinished{TemplateValue{Ast.DefTerm{v_1002635}}}}
    case Ast.DefImports{v_1002636}:
      TemplateFinished{TemplateValue{v_0}}

def template_body_expand_optional(+v_0: Ast.OptionalTerm, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.OptionalTerm>:
  match v_0:
    case Ast.NoTerm{}:
      TemplateFinished{TemplateValue{v_0}}
    case Ast.SomeTerm{v_1002637}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_1002637, v_3}}, False{}, v_1002638 => template_body_expand_term(v_1002637, v_3), v_1002639 => +v_1002640 = template_unbox(Ast.SyntaxTerm, v_1002639); TemplateFinished{TemplateValue{Ast.SomeTerm{v_1002640}}}}

def template_match_132(+v_8: Ast.TelescopeItem, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.TelescopeItem>) -> TemplateProgress<List<&2, Ast.TelescopeItem>>:
  match v_8:
    case Ast.Binder{v_15, v_16, v_17, v_18, v_19}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_18, v_4}}, False{}, v_1000883 => template_body_expand_term(v_18, v_4), v_1000882 => +v_1000879 = template_unbox(Ast.SyntaxTerm, v_1000882); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_binders{v_9, v_4}}, v_1000881 => +v_1000880 = template_unbox(List<&2, Ast.TelescopeItem>, v_1000881); TemplateFinished{TemplateValue{Ast.Binder{{v_15 : Ast.Quantity}, {v_16 : String}, {v_17 : Nat}, v_1000879, v_19} <> v_1000880}}}}
    case Ast.TemplateBinder{v_26, v_27, v_28, v_29}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_28, v_4}}, False{}, v_1000890 => template_body_expand_term(v_28, v_4), v_1000889 => +v_1000886 = template_unbox(Ast.SyntaxTerm, v_1000889); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_binders{v_9, v_4}}, v_1000888 => +v_1000887 = template_unbox(List<&2, Ast.TelescopeItem>, v_1000888); TemplateFinished{TemplateValue{Ast.TemplateBinder{{v_26 : String}, {v_27 : Nat}, v_1000886, v_29} <> v_1000887}}}}

def template_body_expand_binders(v_1: List<&2, Ast.TelescopeItem>, v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.TelescopeItem>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_8 <> v_9:
      template_match_132(v_8, v_4, v_9)

def template_body_collect_actual_term(+v_0: Ast.SyntaxTerm, v_3: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_0:
    case Ast.TermApp{v_1002641, v_1002642, v_1002643}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_application{v_0, [], v_3}}, v_1002644 => +v_1002645 = template_unbox(List<&2, ActualSite>, v_1002644); TemplateFinished{TemplateValue{v_1002645}}}
    case Ast.TermBang{v_1002646, v_1002647}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002646, v_3}}, v_1002648 => +v_1002649 = template_unbox(List<&2, ActualSite>, v_1002648); TemplateFinished{TemplateValue{v_1002649}}}
    case Ast.TermSub{v_1002650, v_1002651, v_1002652, v_1002653}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002652, v_3}}, v_1002655 => +v_1002656 = template_unbox(List<&2, ActualSite>, v_1002655); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002651 : Ast.SyntaxTerm}, v_1002656}}, v_1002657 => +v_1002658 = template_unbox(List<&2, ActualSite>, v_1002657); TemplateFinished{TemplateValue{v_1002658}}}}
    case Ast.TermLet{v_1002659, v_1002660, v_1002661, v_1002662, v_1002663, v_1002664}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002663, v_3}}, v_1002666 => +v_1002667 = template_unbox(List<&2, ActualSite>, v_1002666); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{{v_1002662 : List<&2, Ast.SyntaxTerm>}, v_1002667}}, v_1002668 => +v_1002669 = template_unbox(List<&2, ActualSite>, v_1002668); TemplateFinished{TemplateValue{v_1002669}}}}
    case Ast.TermAnn{v_1002670, v_1002671, v_1002672}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002671, v_3}}, v_1002674 => +v_1002675 = template_unbox(List<&2, ActualSite>, v_1002674); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002670 : Ast.SyntaxTerm}, v_1002675}}, v_1002676 => +v_1002677 = template_unbox(List<&2, ActualSite>, v_1002676); TemplateFinished{TemplateValue{v_1002677}}}}
    case Ast.TermTemplate{v_1002678, v_1002679}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002678, v_3}}, v_1002680 => +v_1002681 = template_unbox(List<&2, ActualSite>, v_1002680); TemplateFinished{TemplateValue{v_1002681}}}
    case Ast.TermType{v_1002682, v_1002683}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002682, v_3}}, v_1002684 => +v_1002685 = template_unbox(List<&2, ActualSite>, v_1002684); TemplateFinished{TemplateValue{v_1002685}}}
    case Ast.TermMin{v_1002686, v_1002687, v_1002688}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002687, v_3}}, v_1002690 => +v_1002691 = template_unbox(List<&2, ActualSite>, v_1002690); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002686 : Ast.SyntaxTerm}, v_1002691}}, v_1002692 => +v_1002693 = template_unbox(List<&2, ActualSite>, v_1002692); TemplateFinished{TemplateValue{v_1002693}}}}
    case Ast.TermAll{v_1002694, v_1002695, v_1002696, v_1002697, v_1002698, v_1002699}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002698, v_3}}, v_1002701 => +v_1002702 = template_unbox(List<&2, ActualSite>, v_1002701); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002697 : Ast.SyntaxTerm}, v_1002702}}, v_1002703 => +v_1002704 = template_unbox(List<&2, ActualSite>, v_1002703); TemplateFinished{TemplateValue{v_1002704}}}}
    case Ast.TermLam{v_1002705, v_1002706, v_1002707, v_1002708, v_1002709}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002708, v_3}}, v_1002710 => +v_1002711 = template_unbox(List<&2, ActualSite>, v_1002710); TemplateFinished{TemplateValue{v_1002711}}}
    case Ast.TermAdt{v_1002712, v_1002713, v_1002714, v_1002715}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_1002713, v_3}}, v_1002716 => +v_1002717 = template_unbox(List<&2, ActualSite>, v_1002716); TemplateFinished{TemplateValue{v_1002717}}}
    case Ast.TermFill{v_1002718, v_1002719, v_1002720}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_1002719, v_3}}, v_1002722 => +v_1002723 = template_unbox(List<&2, ActualSite>, v_1002722); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002718 : Ast.SyntaxTerm}, v_1002723}}, v_1002724 => +v_1002725 = template_unbox(List<&2, ActualSite>, v_1002724); TemplateFinished{TemplateValue{v_1002725}}}}
    case Ast.TermPlus{v_1002726, v_1002727, v_1002728}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_1002727, v_3}}, v_1002730 => +v_1002731 = template_unbox(List<&2, ActualSite>, v_1002730); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002726 : Ast.SyntaxTerm}, v_1002731}}, v_1002732 => +v_1002733 = template_unbox(List<&2, ActualSite>, v_1002732); TemplateFinished{TemplateValue{v_1002733}}}}
    case Ast.TermCtr{v_1002734, v_1002735, v_1002736}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_1002735, v_3}}, v_1002737 => +v_1002738 = template_unbox(List<&2, ActualSite>, v_1002737); TemplateFinished{TemplateValue{v_1002738}}}
    case Ast.TermString{v_1002739, v_1002740, v_1002741}:
      TemplateFinished{TemplateValue{v_3}}
    case Ast.TermMat{v_1002742, v_1002743, v_1002744, v_1002745}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002744, v_3}}, v_1002747 => +v_1002748 = template_unbox(List<&2, ActualSite>, v_1002747); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002743 : Ast.SyntaxTerm}, v_1002748}}, v_1002749 => +v_1002750 = template_unbox(List<&2, ActualSite>, v_1002749); TemplateFinished{TemplateValue{v_1002750}}}}
    case Ast.TermEqual{v_1002751, v_1002752, v_1002753, v_1002754}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002753, v_3}}, v_1002757 => +v_1002758 = template_unbox(List<&2, ActualSite>, v_1002757); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002752 : Ast.SyntaxTerm}, v_1002758}}, v_1002759 => +v_1002760 = template_unbox(List<&2, ActualSite>, v_1002759); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002751 : Ast.SyntaxTerm}, v_1002760}}, v_1002761 => +v_1002762 = template_unbox(List<&2, ActualSite>, v_1002761); TemplateFinished{TemplateValue{v_1002762}}}}}
    case Ast.TermRewrite{v_1002763, v_1002764, v_1002765, v_1002766}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002765, v_3}}, v_1002769 => +v_1002770 = template_unbox(List<&2, ActualSite>, v_1002769); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002764 : Ast.SyntaxTerm}, v_1002770}}, v_1002771 => +v_1002772 = template_unbox(List<&2, ActualSite>, v_1002771); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{{v_1002763 : Ast.SyntaxTerm}, v_1002772}}, v_1002773 => +v_1002774 = template_unbox(List<&2, ActualSite>, v_1002773); TemplateFinished{TemplateValue{v_1002774}}}}}
    case Ast.BodyMatch{v_1002775, v_1002776, v_1002777}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_1002776, v_3}}, v_1002779 => +v_1002780 = template_unbox(List<&2, ActualSite>, v_1002779); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{{v_1002775 : List<&2, Ast.SyntaxTerm>}, v_1002780}}, v_1002781 => +v_1002782 = template_unbox(List<&2, ActualSite>, v_1002781); TemplateFinished{TemplateValue{v_1002782}}}}
    case Ast.BodyCase{v_1002783, v_1002784, v_1002785}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002784, v_3}}, v_1002786 => +v_1002787 = template_unbox(List<&2, ActualSite>, v_1002786); TemplateFinished{TemplateValue{v_1002787}}}
    case Ast.BodyLocal{v_1002788, v_1002789, v_1002790, v_1002791, v_1002792}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002791, v_3}}, v_1002794 => +v_1002795 = template_unbox(List<&2, ActualSite>, v_1002794); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{{v_1002790 : List<&2, Ast.SyntaxTerm>}, v_1002795}}, v_1002796 => +v_1002797 = template_unbox(List<&2, ActualSite>, v_1002796); TemplateFinished{TemplateValue{v_1002797}}}}
    case Ast.BodyReply{v_1002798, v_1002799}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002798, v_3}}, v_1002800 => +v_1002801 = template_unbox(List<&2, ActualSite>, v_1002800); TemplateFinished{TemplateValue{v_1002801}}}
    case v_1002802:
      TemplateFinished{TemplateValue{v_3}}

def template_match_135(+v_1000980: Maybe<&2, String>, v_20: List<&2, ActualSite>, v_2: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1000980:
    case None{}:
      TemplateFinished{TemplateValue{v_20}}
    case Some{v_23}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_wrapped_prefix{v_2}}, v_1000985 => +v_1000982 = template_unbox(Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_1000985); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_prefix{{v_23 : String}, v_1000982, v_20}}, v_1000984 => +v_1000983 = template_unbox(List<&2, ActualSite>, v_1000984); TemplateFinished{TemplateValue{v_1000983}}}}

def template_continuation_136(+v_1000979: List<&2, ActualSite>, v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<List<&2, ActualSite>>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_head_key{v_0}}, v_1000986 => +v_1000980 = template_unbox(Maybe<&2, String>, v_1000986); template_match_135(v_1000980, v_1000979, v_2)}

def template_body_collect_actual_application(+v_0: Ast.SyntaxTerm, +v_2: List<&2, Ast.SyntaxTerm>, v_5: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_0:
    case Ast.TermApp{v_1002803, v_1002804, v_1002805}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_application{v_1002803, v_1002804 <> v_2, v_5}}, v_1002806 => +v_1002807 = template_unbox(List<&2, ActualSite>, v_1002806); TemplateFinished{TemplateValue{v_1002807}}}
    case v_1002808:
      v_1002809 = {v_0 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_2, v_5}}, v_1002810 => +v_1002811 = template_unbox(List<&2, ActualSite>, v_1002810); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1002809, v_1002811}}, False{}, v_1002812 => template_body_collect_actual_term(v_1002809, v_1002811), v_1002813 => +v_1002814 = template_unbox(List<&2, ActualSite>, v_1002813); template_continuation_136(v_1002814, v_0, v_2)}}

def template_body_collect_actual_prefix(v_1: String, v_4: Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_4:
    case Some{[]}:
      TemplateFinished{TemplateValue{v_7}}
    case Some{v_1002815}:
      TemplateFinished{TemplateValue{ActualSite{v_1, v_1002815} <> v_7}}
    case None{}:
      TemplateFinished{TemplateValue{v_7}}

def template_body_head_key(v_0: Ast.SyntaxTerm) -> TemplateProgress<Maybe<&2, String>>:
  match v_0:
    case Ast.TermRef{v_5, _}:
      TemplateFinished{TemplateValue{Some{v_5}}}
    case Ast.TermBang{v_9, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_head_key{v_9}}, v_1000991 => +v_1000990 = template_unbox(Maybe<&2, String>, v_1000991); TemplateFinished{TemplateValue{v_1000990}}}
    case _:
      TemplateFinished{TemplateValue{None{}}}

def template_body_wrapped_prefix(v_1: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Maybe<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_1:
    case Ast.TermTemplate{v_7, _} <> v_9:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_wrapped_prefix{v_9}}, v_1000996 => +v_1000993 = template_unbox(Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_1000996); TemplatePending{TemplateRequestGroup_1{TemplateRequest_wrapped_prefix_cons{{v_7 : Ast.SyntaxTerm}, v_1000993}}, v_1000995 => +v_1000994 = template_unbox(Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_1000995); TemplateFinished{TemplateValue{v_1000994}}}}
    case _:
      TemplateFinished{TemplateValue{Some{[]}}}

def template_body_wrapped_prefix_cons(v_0: Ast.SyntaxTerm, v_3: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> TemplateProgress<Maybe<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_3:
    case Some{v_1002816}:
      TemplateFinished{TemplateValue{Some{v_0 <> v_1002816}}}
    case None{}:
      TemplateFinished{TemplateValue{None{}}}

def template_body_collect_actual_terms(v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case +v_9 <> v_10:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_10, v_4}}, v_1001000 => +v_1000998 = template_unbox(List<&2, ActualSite>, v_1001000); template_body_collect_actual_term({v_9 : Ast.SyntaxTerm}, v_1000998)}

def template_body_first_actual(v_2: List<&2, List<&2, Ast.SyntaxTerm>>, v_5: List<&2, List<&2, Ast.SyntaxTerm>>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  TemplateFinished{TemplateValue{List.append(&2, List<&2, Ast.SyntaxTerm>, v_2, v_5)}}

def template_match_143(+v_9: Ast.TopLevel, v_13: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_9:
    case Ast.DefTop{Ast.Definition{_, +v_21, v_22, v_23, _, _}}:
      v_1001005 = {v_13 : List<&2, ActualSite>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_has_template_binder{v_21}}, False{}, v_1001010 => template_body_has_template_binder(v_21), v_1001009 => +v_1001006 = template_unbox(Bool, v_1001009); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_definition{{v_21 : List<&2, Ast.TelescopeItem>}, {v_22 : Ast.OptionalTerm}, {v_23 : Ast.DefBody}, v_1001005, v_1001006}}, v_1001008 => +v_1001007 = template_unbox(List<&2, ActualSite>, v_1001008); TemplateFinished{TemplateValue{v_1001007}}}}
    case Ast.TypeTop{Ast.TypeDecl{_, v_34, v_35, v_36, _}}:
      v_1001012 = {v_35 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_constructors{v_36, v_13}}, v_1001019 => +v_1001013 = template_unbox(List<&2, ActualSite>, v_1001019); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1001012, v_1001013}}, False{}, v_1001018 => template_body_collect_actual_term(v_1001012, v_1001013), v_1001017 => +v_1001014 = template_unbox(List<&2, ActualSite>, v_1001017); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_binders{{v_34 : List<&2, Ast.TelescopeItem>}, v_1001014}}, v_1001016 => +v_1001015 = template_unbox(List<&2, ActualSite>, v_1001016); TemplateFinished{TemplateValue{v_1001015}}}}}
    case Ast.LawTop{Ast.LawDecl{_, v_46, v_47, _}}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_47, v_13}}, False{}, v_1001025 => template_body_collect_actual_term(v_47, v_13), v_1001024 => +v_1001021 = template_unbox(List<&2, ActualSite>, v_1001024); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_clauses{{v_46 : List<&2, Ast.Clause>}, v_1001021}}, v_1001023 => +v_1001022 = template_unbox(List<&2, ActualSite>, v_1001023); TemplateFinished{TemplateValue{v_1001022}}}}

def template_continuation_144(+v_1001001: List<&2, ActualSite>, +v_9: Ast.TopLevel) -> TemplateProgress<List<&2, ActualSite>>:
  template_match_143(v_9, v_1001001)

def template_body_collect_actual_declarations(v_1: List<&2, Ast.TopLevel>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case +v_9 <> v_10:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_declarations{v_10, v_4}}, v_1001026 => +v_1001001 = template_unbox(List<&2, ActualSite>, v_1001026); template_continuation_144(v_1001001, v_9)}

def template_body_collect_actual_definition(v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.OptionalTerm, v_3: Ast.DefBody, v_6: List<&2, ActualSite>, v_8: Bool) -> TemplateProgress<List<&2, ActualSite>>:
  match v_8:
    case True{}:
      TemplateFinished{TemplateValue{v_6}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_body{v_3, v_6}}, v_1002819 => +v_1002820 = template_unbox(List<&2, ActualSite>, v_1002819); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_optional{{v_2 : Ast.OptionalTerm}, v_1002820}}, v_1002821 => +v_1002822 = template_unbox(List<&2, ActualSite>, v_1002821); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_binders{{v_1 : List<&2, Ast.TelescopeItem>}, v_1002822}}, v_1002823 => +v_1002824 = template_unbox(List<&2, ActualSite>, v_1002823); TemplateFinished{TemplateValue{v_1002824}}}}}

def template_body_collect_actual_body(v_0: Ast.DefBody, v_3: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_0:
    case Ast.DefTerm{v_7}:
      template_body_collect_actual_term(v_7, v_3)
    case Ast.DefImports{_}:
      TemplateFinished{TemplateValue{v_3}}

def template_continuation_148(+v_3: List<&2, Loader.LoadedModule>, v_15: List<&2, Loader.LoadedModule>, v_1001036: String, v_1001037: List<&2, Ast.ModuleImport>, +v_1001038: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualModule>>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_modules{v_15, v_3}}, v_1001043 => +v_1001040 = template_unbox(List<&2, ActualModule>, v_1001043); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_module{v_1001036, v_1001037, v_1001038, {v_3 : List<&2, Loader.LoadedModule>}, v_1001040}}, v_1001042 => +v_1001041 = template_unbox(List<&2, ActualModule>, v_1001042); TemplateFinished{TemplateValue{v_1001041}}}}

def template_body_collect_actual_modules(v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, ActualModule>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case Loader.LoadedModule{v_11, Ast.Module{_, v_13, v_14}} <> v_15:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_collect_actual_declarations{v_14, []}}, False{}, v_1001045 => template_body_collect_actual_declarations(v_14, []), v_1001044 => +v_1001038 = template_unbox(List<&2, ActualSite>, v_1001044); template_continuation_148(v_3, v_15, {v_11 : String}, {v_13 : List<&2, Ast.ModuleImport>}, v_1001038)}

def template_body_collect_actual_module(+v_1: String, +v_3: List<&2, Ast.ModuleImport>, +v_6: List<&2, ActualSite>, +v_8: List<&2, Loader.LoadedModule>, v_11: List<&2, ActualModule>) -> TemplateProgress<List<&2, ActualModule>>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{v_11}}
    case +v_1002825 <> v_1002826:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_scope_capture_names{v_1, v_3, v_8}}, False{}, v_1002830 => template_body_scope_capture_names(v_1, v_3, v_8), v_1002831 => +v_1002832 = template_unbox(List<&2, CaptureName>, v_1002831); TemplateFinished{TemplateValue{ActualModule{{v_1 : String}, {v_3 : List<&2, Ast.ModuleImport>}, {v_6 : List<&2, ActualSite>}, v_1002832} <> v_11}}}

def template_body_actual_in_catalog(v_2: List<&2, ActualModule>, +v_4: String, +v_7: List<&2, TemplateDef>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_find_template{v_4, v_7}}, False{}, v_1001059 => template_body_find_template(v_4, v_7), v_1001058 => +v_1001055 = template_unbox(Maybe<&2, TemplateDef>, v_1001058); TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_in_catalog_found{{v_2 : List<&2, ActualModule>}, {v_4 : String}, {v_7 : List<&2, TemplateDef>}, v_1001055}}, v_1001057 => +v_1001056 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1001057); TemplateFinished{TemplateValue{v_1001056}}}}

def template_continuation_151(+v_1001066: List<&2, TemplateDef>, v_26: List<&2, List<&2, Ast.SyntaxTerm>>, v_21: List<&2, CaptureName>, v_22: List<&2, ActualModule>, v_4: String, v_7: List<&2, TemplateDef>, v_10: Maybe<&2, TemplateDef>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_actual_values{v_26, v_1001066, v_21}}, v_1001071 => +v_1001067 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1001071); TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_in_catalog_found{v_22, v_4, v_7, v_10}}, v_1001070 => +v_1001068 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1001070); template_body_first_actual(v_1001067, v_1001068)}}

def template_match_152(+v_26: List<&2, List<&2, Ast.SyntaxTerm>>, v_22: List<&2, ActualModule>, v_4: String, +v_7: List<&2, TemplateDef>, v_10: Maybe<&2, TemplateDef>, v_18: String, v_19: List<&2, Ast.ModuleImport>, +v_21: List<&2, CaptureName>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_26:
    case []:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_in_catalog_found{v_22, v_4, v_7, v_10}}, v_1001064 => +v_1001063 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1001064); TemplateFinished{TemplateValue{v_1001063}}}
    case +_ <> _:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_visible_templates{v_18, v_19, v_7}}, v_1001074 => +v_1001065 = template_unbox(List<&2, TemplateDef>, v_1001074); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_templates_with_captures{v_1001065, v_21}}, False{}, v_1001073 => template_body_templates_with_captures(v_1001065, v_21), v_1001072 => +v_1001066 = template_unbox(List<&2, TemplateDef>, v_1001072); template_continuation_151(v_1001066, v_26, v_21, v_22, v_4, v_7, v_10)}}

def template_continuation_153(+v_1001062: List<&2, List<&2, Ast.SyntaxTerm>>, v_22: List<&2, ActualModule>, v_4: String, v_7: List<&2, TemplateDef>, v_10: Maybe<&2, TemplateDef>, v_18: String, v_19: List<&2, Ast.ModuleImport>, v_21: List<&2, CaptureName>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  template_match_152(v_1001062, v_22, v_4, v_7, v_10, v_18, v_19, v_21)

def template_body_actual_in_catalog_found(v_2: List<&2, ActualModule>, +v_4: String, v_7: List<&2, TemplateDef>, +v_10: Maybe<&2, TemplateDef>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case ActualModule{+v_1002833, +v_1002834, v_1002835, v_1002836} <> v_1002837:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_aliases_found{v_1002833, v_1002834, v_4, v_10}}, v_1002839 => +v_1002840 = template_unbox(List<&2, String>, v_1002839); TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_in_aliases{{v_1002835 : List<&2, ActualSite>}, v_1002840}}, v_1002841 => +v_1002842 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1002841); template_continuation_153(v_1002842, v_1002837, v_4, v_7, v_10, v_1002833, v_1002834, v_1002836)}}

def template_continuation_155(+v_1001078: List<&2, String>, v_5: String, v_1: String, v_3: List<&2, Ast.ModuleImport>, v_19: String, v_27: String) -> TemplateProgress<List<&2, String>>:
  v_1001079 = {[v_5] : List<&2, String>}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_imported_alias_names{v_1, v_3, v_19, v_27}}, v_1001082 => +v_1001081 = template_unbox(List<&2, String>, v_1001082); TemplateFinished{TemplateValue{List.append(&2, String, v_1001079, List.append(&2, String, {v_1001078 : List<&2, String>}, v_1001081))}}}

def template_continuation_156(+v_1001077: String, +v_1: String, +v_19: String, v_5: String, v_3: List<&2, Ast.ModuleImport>) -> TemplateProgress<List<&2, String>>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_local_alias{v_1, v_19, v_1001077, String.eq(v_1, v_19)}}, v_1001083 => +v_1001078 = template_unbox(List<&2, String>, v_1001083); template_continuation_155(v_1001078, v_5, v_1, v_3, v_19, v_1001077)}

def template_body_template_aliases_found(v_1: String, v_3: List<&2, Ast.ModuleImport>, +v_5: String, v_8: Maybe<&2, TemplateDef>) -> TemplateProgress<List<&2, String>>:
  match v_8:
    case None{}:
      TemplateFinished{TemplateValue{[v_5]}}
    case Some{TemplateDef{v_1002843, +v_1002844, v_1002845, v_1002846, v_1002847, v_1002848, v_1002849}}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_strip_namespace{v_5, v_1002844}}, False{}, v_1002850 => template_body_strip_namespace(v_5, v_1002844), v_1002851 => +v_1002852 = template_unbox(String, v_1002851); template_continuation_156(v_1002852, v_1, v_1002844, v_5, v_3)}

def template_body_template_local_alias(v_1: String, v_3: String, v_5: String, v_7: Bool) -> TemplateProgress<List<&2, String>>:
  match v_7:
    case True{}:
      TemplateFinished{TemplateValue{[v_5]}}
    case False{}:
      TemplateFinished{TemplateValue{[]}}

def template_match_159(+v_12: Ast.ModuleImport, +v_1: String, v_13: List<&2, Ast.ModuleImport>, +v_5: String, v_7: String) -> TemplateProgress<List<&2, String>>:
  match v_12:
    case Ast.ModuleImport{v_17, v_18, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_imported_alias_match{v_1, v_13, v_5, v_7, v_18, String.eq(Path.namespace(v_1, v_17), v_5)}}, v_1001087 => +v_1001086 = template_unbox(List<&2, String>, v_1001087); TemplateFinished{TemplateValue{v_1001086}}}

def template_body_imported_alias_names(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: String, v_7: String) -> TemplateProgress<List<&2, String>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002853 <> v_1002854:
      template_match_159(v_1002853, v_1, v_1002854, v_5, v_7)

def template_body_imported_alias_match(+v_1: String, +v_3: List<&2, Ast.ModuleImport>, +v_5: String, +v_7: String, v_9: String, v_11: Bool) -> TemplateProgress<List<&2, String>>:
  match v_11:
    case True{}:
      v_1002855 = {String.append(v_9, String.append(".", v_7)) : String}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_imported_alias_names{v_1, v_3, v_5, v_7}}, False{}, v_1002856 => template_body_imported_alias_names(v_1, v_3, v_5, v_7), v_1002857 => +v_1002858 = template_unbox(List<&2, String>, v_1002857); TemplateFinished{TemplateValue{v_1002855 <> v_1002858}}}
    case False{}:
      template_body_imported_alias_names(v_1, v_3, v_5, v_7)

def template_body_actual_in_aliases(+v_2: List<&2, ActualSite>, v_5: List<&2, String>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_5:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002859 <> v_1002860:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_sites_for_key{v_2, v_1002859}}, v_1002861 => +v_1002862 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1002861); TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_in_aliases{v_2, v_1002860}}, v_1002863 => +v_1002864 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1002863); template_body_first_actual(v_1002862, v_1002864)}}

def template_match_163(v_1001098: Bool, v_11: List<&2, Ast.SyntaxTerm>, v_12: List<&2, ActualSite>, v_4: String) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_1001098:
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_sites_for_key{v_12, v_4}}, v_1001101 => +v_1001100 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1001101); TemplateFinished{TemplateValue{{v_11 : List<&2, Ast.SyntaxTerm>} <> v_1001100}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_sites_for_key{v_12, v_4}}, v_1001103 => +v_1001102 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1001103); TemplateFinished{TemplateValue{v_1001102}}}

def template_body_actual_sites_for_key(v_2: List<&2, ActualSite>, +v_4: String) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case ActualSite{v_1002865, v_1002866} <> v_1002867:
      v_1002868 = {String.eq(v_4, v_1002865) : Bool}
      template_match_163(v_1002868, v_1002866, v_1002867, v_4)

def template_body_expand_actual_values(v_2: List<&2, List<&2, Ast.SyntaxTerm>>, +v_5: List<&2, TemplateDef>, +v_8: List<&2, CaptureName>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1002869 <> v_1002870:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_expand_terms{v_1002869, v_5}}, False{}, v_1002871 => template_body_expand_terms(v_1002869, v_5), v_1002872 => +v_1002873 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002872); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1002873, v_8}}, False{}, v_1002874 => template_body_capture_terms(v_1002873, v_8), v_1002875 => +v_1002876 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1002875); TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_actual_values{v_1002870, v_5, v_8}}, v_1002877 => +v_1002878 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1002877); TemplateFinished{TemplateValue{v_1002876 <> v_1002878}}}}}

def template_match_166(+v_9: Ast.TelescopeItem, v_10: List<&2, Ast.TelescopeItem>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_9:
    case Ast.Binder{_, _, _, v_19, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_binders{v_10, v_4}}, v_1001115 => +v_1001113 = template_unbox(List<&2, ActualSite>, v_1001115); template_body_collect_actual_term({v_19 : Ast.SyntaxTerm}, v_1001113)}
    case Ast.TemplateBinder{_, _, v_29, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_binders{v_10, v_4}}, v_1001119 => +v_1001117 = template_unbox(List<&2, ActualSite>, v_1001119); template_body_collect_actual_term({v_29 : Ast.SyntaxTerm}, v_1001117)}

def template_body_collect_actual_binders(v_1: List<&2, Ast.TelescopeItem>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case +v_9 <> v_10:
      template_match_166(v_9, v_10, v_4)

def template_body_collect_actual_optional(v_0: Ast.OptionalTerm, v_3: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_0:
    case Ast.NoTerm{}:
      TemplateFinished{TemplateValue{v_3}}
    case Ast.SomeTerm{v_7}:
      template_body_collect_actual_term(v_7, v_3)

def template_body_collect_actual_constructors(v_1: List<&2, Ast.ConstructorDecl>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case Ast.Constructor{_, v_12, _} <> v_14:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_constructors{v_14, v_4}}, v_1001124 => +v_1001122 = template_unbox(List<&2, ActualSite>, v_1001124); template_body_collect_actual_binders({v_12 : List<&2, Ast.TelescopeItem>}, v_1001122)}

def template_body_collect_actual_clauses(v_1: List<&2, Ast.Clause>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{v_4}}
    case Ast.ClauseFor{_, _, _, v_17, v_18, _} <> v_20:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_clauses{v_20, v_4}}, v_1001131 => +v_1001127 = template_unbox(List<&2, ActualSite>, v_1001131); TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_maybe{{v_18 : Maybe<&2, Ast.SyntaxTerm>}, v_1001127}}, v_1001130 => +v_1001128 = template_unbox(List<&2, ActualSite>, v_1001130); template_body_collect_actual_term({v_17 : Ast.SyntaxTerm}, v_1001128)}}

def template_body_collect_actual_maybe(v_1: Maybe<&2, Ast.SyntaxTerm>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{v_4}}
    case Some{v_7}:
      template_body_collect_actual_term(v_7, v_4)

def template_body_has_string(+v_1: String, v_4: List<&2, String>) -> TemplateProgress<Bool>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_1002879 <> v_1002880:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_string_match{v_1, v_1002879, v_1002880, String.eq(v_1, v_1002879)}}, v_1002881 => +v_1002882 = template_unbox(Bool, v_1002881); TemplateFinished{TemplateValue{v_1002882}}}

def template_body_has_string_match(v_1: String, v_3: String, v_6: List<&2, String>, v_8: Bool) -> TemplateProgress<Bool>:
  match v_8:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      template_body_has_string(v_1, v_6)

def template_match_174(+v_7: Ast.TopLevel, +v_1: String, v_8: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_7:
    case Ast.DefTop{Ast.Definition{v_15, _, _, _, _, _}}:
      v_1001136 = {String.eq(v_1, v_15) : Bool}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_top_key{v_1, v_8}}, v_1001138 => +v_1001137 = template_unbox(Bool, v_1001138); TemplateFinished{TemplateValue{Bool.or(v_1001136, v_1001137)}}}
    case Ast.TypeTop{Ast.TypeDecl{v_27, _, _, _, _}}:
      v_1001139 = {String.eq(v_1, v_27) : Bool}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_top_key{v_1, v_8}}, v_1001141 => +v_1001140 = template_unbox(Bool, v_1001141); TemplateFinished{TemplateValue{Bool.or(v_1001139, v_1001140)}}}
    case Ast.LawTop{Ast.LawDecl{v_37, _, _, _}}:
      v_1001142 = {String.eq(v_1, v_37) : Bool}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_top_key{v_1, v_8}}, v_1001144 => +v_1001143 = template_unbox(Bool, v_1001144); TemplateFinished{TemplateValue{Bool.or(v_1001142, v_1001143)}}}

def template_body_has_top_key(v_1: String, v_3: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_1002883 <> v_1002884:
      template_match_174(v_1002883, v_1, v_1002884)

def template_match_176(+v_9: GeneratedIdentity, +v_1: String, v_10: List<&2, GeneratedIdentity>) -> TemplateProgress<Maybe<&2, GeneratedIdentity>>:
  match v_9:
    case GeneratedIdentity{+v_15, _, _, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_find_generated_identity_match{v_1, v_9, v_10, v_15, String.eq(v_1, v_15)}}, v_1001146 => +v_1001145 = template_unbox(Maybe<&2, GeneratedIdentity>, v_1001146); TemplateFinished{TemplateValue{v_1001145}}}

def template_body_find_generated_identity(v_1: String, v_4: List<&2, GeneratedIdentity>) -> TemplateProgress<Maybe<&2, GeneratedIdentity>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1002885 <> v_1002886:
      template_match_176(v_1002885, v_1, v_1002886)

def template_body_find_generated_identity_match(v_1: String, v_3: GeneratedIdentity, v_6: List<&2, GeneratedIdentity>, v_8: String, v_10: Bool) -> TemplateProgress<Maybe<&2, GeneratedIdentity>>:
  match v_10:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_3}}}
    case False{}:
      template_body_find_generated_identity(v_1, v_6)

def template_body_template_span(v_1: TemplateDef) -> TemplateProgress<Ast.SourceSpan>:
  TemplateFinished{TemplateValue{template_pure_template_span(v_1)}}

def template_continuation_179(+v_1001151: String, v_1: TemplateDef, v_14: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, +v_9: List<&2, GeneratedIdentity>, v_17: String, v_21: String, v_24: String, +v_13: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<GeneratedBuild>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_find_generated_identity{v_1001151, v_9}}, False{}, v_1001165 => template_body_find_generated_identity(v_1001151, v_9), v_1001164 => +v_1001161 = template_unbox(Maybe<&2, GeneratedIdentity>, v_1001164); TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_actual_case{{v_1 : TemplateDef}, {v_14 : List<&2, List<&2, Ast.SyntaxTerm>>}, {v_6 : List<&2, Ast.TopLevel>}, {v_9 : List<&2, GeneratedIdentity>}, {v_17 : String}, {v_21 : String}, {v_24 : String}, {v_1001151 : String}, {v_13 : List<&2, Ast.SyntaxTerm>}, v_1001161}}, v_1001163 => +v_1001162 = template_unbox(GeneratedBuild, v_1001163); TemplateFinished{TemplateValue{v_1001162}}}}

def template_continuation_180(+v_1001150: String, +v_1: TemplateDef, v_14: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>, v_17: String, v_21: String, +v_13: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<GeneratedBuild>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_generated_canonical_key{v_1, v_1001150}}, False{}, v_1001167 => template_body_generated_canonical_key(v_1, v_1001150), v_1001166 => +v_1001151 = template_unbox(String, v_1001166); template_continuation_179(v_1001151, v_1, v_14, v_6, v_9, v_17, v_21, v_1001150, v_13)}

def template_continuation_181(+v_1001148: String, +v_1001149: String, +v_1: TemplateDef, v_14: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>, v_17: String, +v_13: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<GeneratedBuild>:
  +v_21 = String.append(v_1001148, v_1001149)
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_generated_local_key_for_identity{v_1, v_21}}, False{}, v_1001169 => template_body_generated_local_key_for_identity(v_1, v_21), v_1001168 => +v_1001150 = template_unbox(String, v_1001168); template_continuation_180(v_1001150, v_1, v_14, v_6, v_9, v_17, v_21, v_13)}

def template_body_generated_actuals(+v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedBuild>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{GeneratedBuild{[], v_9, None{}}}}
    case +v_1002887 <> v_1002888:
      +v_1002889 = template_pure_template_name(v_1)
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_1002889}}, False{}, v_1002890 => template_body_encode_string(v_1002889), v_1002891 => +v_1002892 = template_unbox(String, v_1002891); TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_1002887}}, False{}, v_1002893 => template_body_serialize_terms(v_1002887), v_1002894 => +v_1002895 = template_unbox(String, v_1002894); template_continuation_181(v_1002892, v_1002895, v_1, v_1002888, v_6, v_9, v_1002889, v_1002887)}}

def template_body_template_name(v_1: TemplateDef) -> TemplateProgress<String>:
  TemplateFinished{TemplateValue{template_pure_template_name(v_1)}}

def template_body_generated_actual_case(v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, +v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>, v_11: String, +v_13: String, +v_15: String, v_17: String, v_19: List<&2, Ast.SyntaxTerm>, v_22: Maybe<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedBuild>:
  match v_22:
    case Some{GeneratedIdentity{v_1002896, v_1002897, v_1002898, +v_1002899}}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_identity_collision{v_1, v_4, v_6, v_9, v_13, v_1002899, String.eq(v_13, v_1002899)}}, v_1002900 => +v_1002901 = template_unbox(GeneratedBuild, v_1002900); TemplateFinished{TemplateValue{v_1002901}}}
    case None{}:
      v_1002902 = {v_1 : TemplateDef}
      v_1002903 = {v_4 : List<&2, List<&2, Ast.SyntaxTerm>>}
      v_1002905 = {v_9 : List<&2, GeneratedIdentity>}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_has_top_key{v_15, v_6}}, False{}, v_1002911 => template_body_has_top_key(v_15, v_6), v_1002912 => +v_1002913 = template_unbox(Bool, v_1002912); TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_actual_new{v_1002902, v_1002903, {v_6 : List<&2, Ast.TopLevel>}, v_1002905, {v_11 : String}, {v_13 : String}, {v_15 : String}, {v_17 : String}, {v_19 : List<&2, Ast.SyntaxTerm>}, v_1002913}}, v_1002914 => +v_1002915 = template_unbox(GeneratedBuild, v_1002914); TemplateFinished{TemplateValue{v_1002915}}}}

def template_body_generated_identity_collision(v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>, v_11: String, v_13: String, v_15: Bool) -> TemplateProgress<GeneratedBuild>:
  match v_15:
    case False{}:
      TemplateFinished{TemplateValue{GeneratedBuild{[], v_9, Some{template_pure_template_span(v_1)}}}}
    case True{}:
      template_body_generated_actuals(v_1, v_4, v_6, v_9)

def template_continuation_185(+v_1001191: Ast.Definition, v_17: String, v_11: String, v_15: String, v_13: String, v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedBuild>:
  v_28 = {GeneratedIdentity{v_17, v_11, v_15, v_13} : GeneratedIdentity}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generated_actuals{v_1, v_4, v_6, v_28 <> v_9}}, False{}, v_1001197 => template_body_generated_actuals(v_1, v_4, v_6, v_28 <> v_9), v_1001196 => +v_1001193 = template_unbox(GeneratedBuild, v_1001196); TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_actual_complete{{v_1001191 : Ast.Definition}, v_1001193}}, v_1001195 => +v_1001194 = template_unbox(GeneratedBuild, v_1001195); TemplateFinished{TemplateValue{v_1001194}}}}

def template_body_generated_actual_new(+v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, GeneratedIdentity>, v_11: String, v_13: String, +v_15: String, v_17: String, +v_19: List<&2, Ast.SyntaxTerm>, v_21: Bool) -> TemplateProgress<GeneratedBuild>:
  match v_21:
    case True{}:
      TemplateFinished{TemplateValue{GeneratedBuild{[], v_9, Some{template_pure_template_span(v_1)}}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_specialize_definition{v_1, v_15, v_19}}, False{}, v_1002916 => template_body_specialize_definition(v_1, v_15, v_19), v_1002917 => +v_1002918 = template_unbox(Ast.Definition, v_1002917); template_continuation_185(v_1002918, v_17, v_11, v_15, v_13, v_1, v_4, v_6, v_9)}

def template_body_generated_actual_complete(v_0: Ast.Definition, v_2: GeneratedBuild) -> TemplateProgress<GeneratedBuild>:
  match v_2:
    case GeneratedBuild{v_1002919, v_1002920, v_1002921}:
      TemplateFinished{TemplateValue{GeneratedBuild{Ast.DefTop{v_0} <> v_1002919, v_1002920, v_1002921}}}

def template_body_template_source_span_equal(v_0: Ast.SourceSpan, v_1: Ast.SourceSpan) -> TemplateProgress<Bool>:
  match v_0, v_1:
    case Ast.SpanOf{v_9, v_10, v_11}, Ast.SpanOf{v_12, v_13, v_14}:
      TemplateFinished{TemplateValue{Bool.and(String.eq(v_9, v_12), Bool.and(Nat.is_eq(v_10, v_13), Nat.is_eq(v_11, v_14)))}}

def template_match_189(+v_1001201: Bool, v_1: String, v_2: Ast.SourceSpan, v_19: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_1001201:
    case True{}:
      TemplateFinished{TemplateValue{True{}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_template_source_definition{v_1, v_2, v_19}}, v_1001203 => +v_1001202 = template_unbox(Bool, v_1001203); TemplateFinished{TemplateValue{v_1001202}}}

def template_match_190(v_1001200: Bool, +v_2: Ast.SourceSpan, v_18: Ast.SourceSpan, v_1: String, v_19: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_1001200:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_template_source_span_equal{v_2, v_18}}, False{}, v_1001205 => template_body_template_source_span_equal(v_2, v_18), v_1001204 => +v_1001201 = template_unbox(Bool, v_1001204); template_match_189(v_1001201, v_1, v_2, v_19)}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_template_source_definition{v_1, v_2, v_19}}, v_1001207 => +v_1001206 = template_unbox(Bool, v_1001207); TemplateFinished{TemplateValue{v_1001206}}}

def template_body_has_template_source_definition(+v_1: String, v_2: Ast.SourceSpan, v_4: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case Ast.DefTop{Ast.Definition{v_1002922, v_1002923, v_1002924, v_1002925, v_1002926, v_1002927}} <> v_1002928:
      v_1002929 = {String.eq(v_1, v_1002922) : Bool}
      template_match_190(v_1002929, v_2, v_1002927, v_1, v_1002928)
    case +v_1002930 <> v_1002931:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_template_source_definition{v_1, v_2, v_1002931}}, v_1002932 => +v_1002933 = template_unbox(Bool, v_1002932); TemplateFinished{TemplateValue{v_1002933}}}

def template_match_192(v_1001211: Bool, v_26: String, v_31: Ast.SourceSpan, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_1001211:
    case False{}:
      TemplateFinished{TemplateValue{False{}}}
    case True{}:
      template_body_has_template_source_definition(v_26, v_31, v_5)

def template_match_193(+v_31: Ast.SourceSpan, v_3: String, v_26: String, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_31:
    case Ast.SpanOf{v_36, _, _}:
      v_1001211 = {String.eq(v_3, v_36) : Bool}
      template_match_192(v_1001211, v_26, v_31, v_5)

def template_match_194(v_1001210: Bool, v_31: Ast.SourceSpan, v_3: String, v_26: String, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_1001210:
    case False{}:
      TemplateFinished{TemplateValue{False{}}}
    case True{}:
      template_match_193(v_31, v_3, v_26, v_5)

def template_body_template_owned_by_module(v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_7: TemplateDef) -> TemplateProgress<Bool>:
  match v_7:
    case TemplateDef{v_1002934, v_1002935, v_1002936, v_1002937, v_1002938, Ast.Definition{v_1002939, v_1002940, v_1002941, v_1002942, v_1002943, v_1002944}, v_1002945}:
      v_1002946 = {String.eq(v_1, v_1002935) : Bool}
      template_match_194(v_1002946, v_1002944, v_3, v_1002939, v_5)

def template_match_196(+v_18: TemplateDef, +v_1: String, +v_3: String, +v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, v_11: List<&2, ActualModule>, v_14: List<&2, GeneratedIdentity>, v_19: List<&2, TemplateDef>) -> TemplateProgress<GeneratedBuild>:
  match v_18:
    case TemplateDef{v_27, _, _, _, _, _, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_template_owned_by_module{v_1, v_3, v_5, v_18}}, False{}, v_1001226 => template_body_template_owned_by_module(v_1, v_3, v_5, v_18), v_1001225 => +v_1001222 = template_unbox(Bool, v_1001225); TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_for_module_match{{v_1 : String}, {v_3 : String}, {v_5 : List<&2, Ast.TopLevel>}, {v_8 : List<&2, TemplateDef>}, {v_11 : List<&2, ActualModule>}, {v_14 : List<&2, GeneratedIdentity>}, {v_18 : TemplateDef}, {v_27 : String}, {v_19 : List<&2, TemplateDef>}, v_1001222}}, v_1001224 => +v_1001223 = template_unbox(GeneratedBuild, v_1001224); TemplateFinished{TemplateValue{v_1001223}}}}

def template_body_generated_for_module(v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, +v_8: List<&2, TemplateDef>, v_11: List<&2, ActualModule>, v_14: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedBuild>:
  match v_8:
    case []:
      TemplateFinished{TemplateValue{GeneratedBuild{[], v_14, None{}}}}
    case +v_1002947 <> v_1002948:
      template_match_196(v_1002947, v_1, v_3, v_5, v_8, v_11, v_14, v_1002948)

def template_body_generated_for_module_match(v_1: String, v_3: String, +v_5: List<&2, Ast.TopLevel>, +v_8: List<&2, TemplateDef>, +v_11: List<&2, ActualModule>, +v_14: List<&2, GeneratedIdentity>, v_16: TemplateDef, +v_18: String, v_21: List<&2, TemplateDef>, v_23: Bool) -> TemplateProgress<GeneratedBuild>:
  match v_23:
    case False{}:
      template_body_generated_for_module(v_1, v_3, v_5, v_21, v_11, v_14)
    case True{}:
      v_1002949 = {v_1 : String}
      v_1002950 = {v_3 : String}
      v_1002955 = {v_21 : List<&2, TemplateDef>}
      v_1002956 = {v_16 : TemplateDef}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_actual_in_catalog{v_11, v_18, v_8}}, False{}, v_1002957 => template_body_actual_in_catalog(v_11, v_18, v_8), v_1002958 => +v_1002959 = template_unbox(List<&2, List<&2, Ast.SyntaxTerm>>, v_1002958); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generated_actuals{v_1002956, v_1002959, v_5, v_14}}, False{}, v_1002960 => template_body_generated_actuals(v_1002956, v_1002959, v_5, v_14), v_1002961 => +v_1002962 = template_unbox(GeneratedBuild, v_1002961); TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_for_module_here{v_1002949, v_1002950, {v_5 : List<&2, Ast.TopLevel>}, {v_8 : List<&2, TemplateDef>}, {v_11 : List<&2, ActualModule>}, {v_14 : List<&2, GeneratedIdentity>}, v_1002955, v_1002962}}, v_1002963 => +v_1002964 = template_unbox(GeneratedBuild, v_1002963); TemplateFinished{TemplateValue{v_1002964}}}}}

def template_body_generated_for_module_here(+v_1: String, +v_3: String, +v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, +v_11: List<&2, ActualModule>, v_14: List<&2, GeneratedIdentity>, +v_17: List<&2, TemplateDef>, v_19: GeneratedBuild) -> TemplateProgress<GeneratedBuild>:
  match v_19:
    case GeneratedBuild{v_1002965, v_1002966, Some{v_1002967}}:
      TemplateFinished{TemplateValue{GeneratedBuild{v_1002965, v_1002966, Some{v_1002967}}}}
    case GeneratedBuild{v_1002968, v_1002969, None{}}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generated_for_module{v_1, v_3, v_5, v_17, v_11, v_1002969}}, False{}, v_1002971 => template_body_generated_for_module(v_1, v_3, v_5, v_17, v_11, v_1002969), v_1002972 => +v_1002973 = template_unbox(GeneratedBuild, v_1002972); TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_for_module_merge{{v_1002968 : List<&2, Ast.TopLevel>}, v_1002973}}, v_1002974 => +v_1002975 = template_unbox(GeneratedBuild, v_1002974); TemplateFinished{TemplateValue{v_1002975}}}}

def template_body_generated_for_module_merge(v_1: List<&2, Ast.TopLevel>, v_3: GeneratedBuild) -> TemplateProgress<GeneratedBuild>:
  match v_3:
    case GeneratedBuild{v_1002976, v_1002977, v_1002978}:
      TemplateFinished{TemplateValue{GeneratedBuild{List.append(&2, Ast.TopLevel, v_1, v_1002976), v_1002977, v_1002978}}}

def template_body_generate_round(+v_1: List<&2, Loader.LoadedModule>, +v_4: List<&2, TemplateDef>, v_7: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedRound>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{GeneratedRound{v_1, False{}, v_7, None{}}}}
    case +v_1002979 <> v_1002980:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_collect_actual_modules{v_1, v_1}}, False{}, v_1002982 => template_body_collect_actual_modules(v_1, v_1), v_1002983 => +v_1002984 = template_unbox(List<&2, ActualModule>, v_1002983); TemplatePending{TemplateRequestGroup_2{TemplateRequest_generate_scoped_round{{v_1 : List<&2, Loader.LoadedModule>}, v_1002984, v_4, v_7}}, v_1002985 => +v_1002986 = template_unbox(GeneratedRound, v_1002985); TemplateFinished{TemplateValue{v_1002986}}}}

def template_match_202(+v_14: Loader.LoadedModule, v_15: List<&2, Loader.LoadedModule>, +v_4: List<&2, ActualModule>, +v_7: List<&2, TemplateDef>, v_10: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedRound>:
  match v_14:
    case Loader.LoadedModule{+v_20, Ast.Module{+v_21, v_22, +v_23}}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generated_for_module{v_20, v_21, v_23, v_7, v_4, v_10}}, False{}, v_1001267 => template_body_generated_for_module(v_20, v_21, v_23, v_7, v_4, v_10), v_1001266 => +v_1001263 = template_unbox(GeneratedBuild, v_1001266); TemplatePending{TemplateRequestGroup_2{TemplateRequest_generate_round_loaded{{v_20 : String}, {v_21 : String}, {v_22 : List<&2, Ast.ModuleImport>}, {v_23 : List<&2, Ast.TopLevel>}, {v_15 : List<&2, Loader.LoadedModule>}, {v_4 : List<&2, ActualModule>}, {v_7 : List<&2, TemplateDef>}, v_1001263}}, v_1001265 => +v_1001264 = template_unbox(GeneratedRound, v_1001265); TemplateFinished{TemplateValue{v_1001264}}}}

def template_body_generate_scoped_round(v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, ActualModule>, v_7: List<&2, TemplateDef>, v_10: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedRound>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{GeneratedRound{[], False{}, v_10, None{}}}}
    case +v_1002987 <> v_1002988:
      template_match_202(v_1002987, v_1002988, v_4, v_7, v_10)

def template_body_generate_round_loaded(v_1: String, v_3: String, v_5: List<&2, Ast.ModuleImport>, v_7: List<&2, Ast.TopLevel>, +v_9: List<&2, Loader.LoadedModule>, +v_12: List<&2, ActualModule>, +v_15: List<&2, TemplateDef>, v_17: GeneratedBuild) -> TemplateProgress<GeneratedRound>:
  match v_17:
    case GeneratedBuild{v_1002989, v_1002990, v_1002991}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generate_scoped_round{v_9, v_12, v_15, v_1002990}}, False{}, v_1002998 => template_body_generate_scoped_round(v_9, v_12, v_15, v_1002990), v_1002999 => +v_1003000 = template_unbox(GeneratedRound, v_1002999); TemplatePending{TemplateRequestGroup_2{TemplateRequest_generate_round_merge{{v_1 : String}, {v_3 : String}, {v_5 : List<&2, Ast.ModuleImport>}, {v_7 : List<&2, Ast.TopLevel>}, {v_1002989 : List<&2, Ast.TopLevel>}, {v_1002991 : Maybe<&2, Ast.SourceSpan>}, v_1003000}}, v_1003001 => +v_1003002 = template_unbox(GeneratedRound, v_1003001); TemplateFinished{TemplateValue{v_1003002}}}}

def template_body_generate_round_merge(v_1: String, v_3: String, v_5: List<&2, Ast.ModuleImport>, v_7: List<&2, Ast.TopLevel>, +v_9: List<&2, Ast.TopLevel>, v_11: Maybe<&2, Ast.SourceSpan>, v_13: GeneratedRound) -> TemplateProgress<GeneratedRound>:
  match v_13:
    case GeneratedRound{v_1003003, v_1003004, v_1003005, v_1003006}:
      v_1003007 = {Loader.LoadedModule{v_1, Ast.Module{v_3, v_5, List.append(&2, Ast.TopLevel, v_7, v_9)}} <> v_1003003 : List<&2, Loader.LoadedModule>}
      v_1003008 = {Bool.or(v_1003004, Bool.not(List.is_empty(&2, Ast.TopLevel, v_9))) : Bool}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_11, v_1003006}}, v_1003010 => +v_1003011 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003010); TemplateFinished{TemplateValue{GeneratedRound{v_1003007, v_1003008, {v_1003005 : List<&2, GeneratedIdentity>}, v_1003011}}}}

def template_body_generate_until_stable(v_1: List<&2, Loader.LoadedModule>, +v_4: List<&2, TemplateDef>, v_7: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedRound>:
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generate_round{v_1, v_4, v_7}}, False{}, v_1001289 => template_body_generate_round(v_1, v_4, v_7), v_1001288 => +v_1001285 = template_unbox(GeneratedRound, v_1001288); TemplatePending{TemplateRequestGroup_2{TemplateRequest_generate_until_result{{v_4 : List<&2, TemplateDef>}, v_1001285}}, v_1001287 => +v_1001286 = template_unbox(GeneratedRound, v_1001287); TemplateFinished{TemplateValue{v_1001286}}}}

def template_body_generate_until_result(v_2: List<&2, TemplateDef>, v_4: GeneratedRound) -> TemplateProgress<GeneratedRound>:
  match v_4:
    case GeneratedRound{v_1003012, v_1003013, v_1003014, Some{v_1003015}}:
      TemplateFinished{TemplateValue{GeneratedRound{v_1003012, False{}, v_1003014, Some{v_1003015}}}}
    case GeneratedRound{v_1003016, True{}, v_1003017, None{}}:
      template_body_generate_until_stable(v_1003016, v_2, v_1003017)
    case GeneratedRound{v_1003018, False{}, v_1003019, None{}}:
      TemplateFinished{TemplateValue{GeneratedRound{v_1003018, False{}, v_1003019, None{}}}}

def template_body_visible_templates(+v_1: String, v_3: List<&2, Ast.ModuleImport>, +v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_local_templates{v_1, v_6}}, v_1001294 => +v_1001291 = template_unbox(List<&2, TemplateDef>, v_1001294); TemplatePending{TemplateRequestGroup_2{TemplateRequest_imported_templates{v_1, v_3, v_6}}, v_1001293 => +v_1001292 = template_unbox(List<&2, TemplateDef>, v_1001293); TemplateFinished{TemplateValue{List.append(&2, TemplateDef, v_1001291, List.append(&2, TemplateDef, v_1001292, v_6))}}}}

def template_match_207(+v_9: TemplateDef, +v_1: String, v_10: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_9:
    case TemplateDef{v_18, +v_19, v_20, v_21, _, v_23, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_local_template_match{v_1, v_10, v_18, v_19, v_20, v_21, v_23, String.eq(v_1, v_19)}}, v_1001296 => +v_1001295 = template_unbox(List<&2, TemplateDef>, v_1001296); TemplateFinished{TemplateValue{v_1001295}}}

def template_body_local_templates(v_1: String, v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_4:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1003020 <> v_1003021:
      template_match_207(v_1003020, v_1, v_1003021)

def template_body_local_template_match(+v_1: String, +v_4: List<&2, TemplateDef>, +v_6: String, +v_8: String, v_10: List<&2, Ast.ModuleImport>, v_13: List<&2, String>, v_14: Ast.Definition, v_16: Bool) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_16:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_strip_namespace{v_6, v_8}}, False{}, v_1003026 => template_body_strip_namespace(v_6, v_8), v_1003027 => +v_1003028 = template_unbox(String, v_1003027); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_local_templates{v_1, v_4}}, False{}, v_1003029 => template_body_local_templates(v_1, v_4), v_1003030 => +v_1003031 = template_unbox(List<&2, TemplateDef>, v_1003030); TemplateFinished{TemplateValue{TemplateDef{{v_6 : String}, {v_8 : String}, {v_10 : List<&2, Ast.ModuleImport>}, {v_13 : List<&2, String>}, v_1003028, v_14, []} <> v_1003031}}}}
    case False{}:
      template_body_local_templates(v_1, v_4)

def template_match_210(+v_11: Ast.ModuleImport, +v_1: String, +v_6: List<&2, TemplateDef>, v_12: List<&2, Ast.ModuleImport>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_11:
    case Ast.ModuleImport{v_16, v_17, _}:
      v_20 = Path.namespace(v_1, v_16)
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_imported_from{v_20, v_17, v_6}}, v_1001311 => +v_1001308 = template_unbox(List<&2, TemplateDef>, v_1001311); TemplatePending{TemplateRequestGroup_2{TemplateRequest_imported_templates{v_1, v_12, v_6}}, v_1001310 => +v_1001309 = template_unbox(List<&2, TemplateDef>, v_1001310); TemplateFinished{TemplateValue{List.append(&2, TemplateDef, v_1001308, v_1001309)}}}}

def template_body_imported_templates(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1003032 <> v_1003033:
      template_match_210(v_1003032, v_1, v_6, v_1003033)

def template_match_212(+v_11: TemplateDef, +v_1: String, v_3: String, v_12: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_11:
    case TemplateDef{v_20, +v_21, v_22, v_23, _, v_25, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_imported_from_match{v_1, v_3, v_12, v_20, v_21, v_22, v_23, v_25, String.eq(v_1, v_21)}}, v_1001313 => +v_1001312 = template_unbox(List<&2, TemplateDef>, v_1001313); TemplateFinished{TemplateValue{v_1001312}}}

def template_body_imported_from(v_1: String, v_3: String, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_6:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1003034 <> v_1003035:
      template_match_212(v_1003034, v_1, v_3, v_1003035)

def template_continuation_214(+v_1001314: String, v_8: String, v_10: String, v_12: List<&2, Ast.ModuleImport>, v_15: List<&2, String>, +v_3: String, v_16: Ast.Definition, v_1: String, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  v_1001315 = {TemplateDef{v_8, v_10, v_12, v_15, String.append(v_3, String.append(".", v_1001314)), v_16, []} : TemplateDef}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_imported_from{v_1, v_3, v_6}}, False{}, v_1001318 => template_body_imported_from(v_1, v_3, v_6), v_1001317 => +v_1001316 = template_unbox(List<&2, TemplateDef>, v_1001317); TemplateFinished{TemplateValue{v_1001315 <> v_1001316}}}

def template_body_imported_from_match(v_1: String, v_3: String, v_6: List<&2, TemplateDef>, +v_8: String, +v_10: String, v_12: List<&2, Ast.ModuleImport>, v_15: List<&2, String>, v_16: Ast.Definition, v_18: Bool) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_18:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_strip_namespace{v_8, v_10}}, False{}, v_1003036 => template_body_strip_namespace(v_8, v_10), v_1003037 => +v_1003038 = template_unbox(String, v_1003037); template_continuation_214(v_1003038, v_8, v_10, v_12, v_15, v_3, v_16, v_1, v_6)}
    case False{}:
      template_body_imported_from(v_1, v_3, v_6)

def template_body_expand_modules(+v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_7: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_expand_scoped_modules{v_1, v_1, v_4, v_7}}, v_1001323 => +v_1001322 = template_unbox(List<&2, Loader.LoadedModule>, v_1001323); TemplateFinished{TemplateValue{v_1001322}}}

def template_continuation_216(+v_1001325: List<&2, Ast.TopLevel>, v_19: String, v_20: String, v_21: List<&2, Ast.ModuleImport>, v_14: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  v_1001326 = {Loader.LoadedModule{v_19, Ast.Module{v_20, v_21, v_1001325}} : Loader.LoadedModule}
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_expand_scoped_modules{v_14, v_3, v_6, v_9}}, v_1001328 => +v_1001327 = template_unbox(List<&2, Loader.LoadedModule>, v_1001328); TemplateFinished{TemplateValue{v_1001326 <> v_1001327}}}

def template_continuation_217(+v_1001324: List<&2, TemplateDef>, +v_19: String, v_22: List<&2, Ast.TopLevel>, +v_9: List<&2, GeneratedIdentity>, v_20: String, v_21: List<&2, Ast.ModuleImport>, v_14: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  v_25 = v_1001324
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_strip_template_decls{v_19, v_22, v_25, v_9}}, False{}, v_1001330 => template_body_strip_template_decls(v_19, v_22, v_25, v_9), v_1001329 => +v_1001325 = template_unbox(List<&2, Ast.TopLevel>, v_1001329); template_continuation_216(v_1001325, v_19, v_20, v_21, v_14, v_3, v_6, v_9)}

def template_match_218(+v_13: Loader.LoadedModule, +v_6: List<&2, TemplateDef>, +v_3: List<&2, Loader.LoadedModule>, v_9: List<&2, GeneratedIdentity>, v_14: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  match v_13:
    case Loader.LoadedModule{+v_19, Ast.Module{v_20, +v_21, v_22}}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_scoped_templates{v_19, v_21, v_6, v_3}}, False{}, v_1001332 => template_body_scoped_templates(v_19, v_21, v_6, v_3), v_1001331 => +v_1001324 = template_unbox(List<&2, TemplateDef>, v_1001331); template_continuation_217(v_1001324, v_19, v_22, v_9, v_20, v_21, v_14, v_3, v_6)}

def template_body_expand_scoped_modules(v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_1003039 <> v_1003040:
      template_match_218(v_1003039, v_6, v_3, v_9, v_1003040)

def template_match_220(+v_7: Ast.TelescopeItem, +v_3: Bool, v_8: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Bool>:
  match v_7:
    case Ast.TemplateBinder{_, _, _, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_late_template_binder{v_8, v_3}}, v_1001335 => +v_1001334 = template_unbox(Bool, v_1001335); TemplateFinished{TemplateValue{Bool.or({v_3 : Bool}, v_1001334)}}}
    case Ast.Binder{_, _, _, _, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_late_template_binder{v_8, True{}}}, v_1001337 => +v_1001336 = template_unbox(Bool, v_1001337); TemplateFinished{TemplateValue{v_1001336}}}

def template_body_has_late_template_binder(v_1: List<&2, Ast.TelescopeItem>, v_3: Bool) -> TemplateProgress<Bool>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_7 <> v_8:
      template_match_220(v_7, v_3, v_8)

def template_match_222(+v_5: Loader.LoadedModule, v_6: List<&2, Loader.LoadedModule>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_5:
    case Loader.LoadedModule{_, Ast.Module{_, _, v_14}}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_decls{v_14}}, v_1001343 => +v_1001338 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001343); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_definitions{v_6}}, v_1001342 => +v_1001339 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001342); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001338, v_1001339}}, v_1001341 => +v_1001340 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001341); TemplateFinished{TemplateValue{v_1001340}}}}}

def template_body_invalid_template_definitions(v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_5 <> v_6:
      template_match_222(v_5, v_6)

def template_match_224(+v_5: Ast.TopLevel, v_6: List<&2, Ast.TopLevel>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_5:
    case Ast.DefTop{Ast.Definition{_, +v_14, _, _, _, v_18}}:
      v_1001346 = {v_6 : List<&2, Ast.TopLevel>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_has_late_template_binder{v_14, False{}}}, False{}, v_1001351 => template_body_has_late_template_binder(v_14, False{}), v_1001350 => +v_1001347 = template_unbox(Bool, v_1001350); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_decl{{v_14 : List<&2, Ast.TelescopeItem>}, {v_18 : Ast.SourceSpan}, v_1001346, v_1001347}}, v_1001349 => +v_1001348 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001349); TemplateFinished{TemplateValue{v_1001348}}}}
    case _:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_decls{v_6}}, v_1001353 => +v_1001352 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001353); TemplateFinished{TemplateValue{v_1001352}}}

def template_body_invalid_template_decls(v_1: List<&2, Ast.TopLevel>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_5 <> v_6:
      template_match_224(v_5, v_6)

def template_body_invalid_template_decl(v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.SourceSpan, v_4: List<&2, Ast.TopLevel>, v_6: Bool) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_6:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_2}}}
    case False{}:
      template_body_invalid_template_decls(v_4)

def template_body_invalid_application(+v_0: Ast.SyntaxTerm, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_0:
    case Ast.TermRef{v_1003041, v_1003042}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_find_template{v_1003041, v_3}}, False{}, v_1003044 => template_body_find_template(v_1003041, v_3), v_1003045 => +v_1003046 = template_unbox(Maybe<&2, TemplateDef>, v_1003045); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_reference{{v_1003042 : Ast.SourceSpan}, v_1003046}}, v_1003047 => +v_1003048 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003047); TemplateFinished{TemplateValue{v_1003048}}}}
    case Ast.TermApp{v_1003049, v_1003050, v_1003051}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_flatten_application{v_0}}, False{}, v_1003054 => template_body_flatten_application(v_0), v_1003055 => +v_1003056 = template_unbox(ApplicationSpine, v_1003055); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application_spine{{v_0 : Ast.SyntaxTerm}, {v_3 : List<&2, TemplateDef>}, v_1003056}}, v_1003057 => +v_1003058 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003057); TemplateFinished{TemplateValue{v_1003058}}}}
    case Ast.TermTemplate{v_1003059, v_1003060}:
      v_1003061 = {Some{v_1003060} : Maybe<&2, Ast.SourceSpan>}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003059, v_3}}, v_1003062 => +v_1003063 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003062); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003061, v_1003063}}, v_1003064 => +v_1003065 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003064); TemplateFinished{TemplateValue{v_1003065}}}}
    case Ast.TermBang{v_1003066, v_1003067}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003066, v_3}}, v_1003068 => +v_1003069 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003068); TemplateFinished{TemplateValue{v_1003069}}}
    case Ast.TermSub{v_1003070, v_1003071, v_1003072, v_1003073}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003071, v_3}}, v_1003074 => +v_1003075 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003074); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003072, v_3}}, v_1003076 => +v_1003077 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003076); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003075, v_1003077}}, v_1003078 => +v_1003079 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003078); TemplateFinished{TemplateValue{v_1003079}}}}}
    case Ast.TermLet{v_1003080, v_1003081, v_1003082, v_1003083, v_1003084, v_1003085}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1003083, v_3}}, v_1003086 => +v_1003087 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003086); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003084, v_3}}, v_1003088 => +v_1003089 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003088); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003087, v_1003089}}, v_1003090 => +v_1003091 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003090); TemplateFinished{TemplateValue{v_1003091}}}}}
    case Ast.TermAnn{v_1003092, v_1003093, v_1003094}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003092, v_3}}, v_1003095 => +v_1003096 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003095); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003093, v_3}}, v_1003097 => +v_1003098 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003097); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003096, v_1003098}}, v_1003099 => +v_1003100 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003099); TemplateFinished{TemplateValue{v_1003100}}}}}
    case Ast.TermType{v_1003101, v_1003102}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003101, v_3}}, v_1003103 => +v_1003104 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003103); TemplateFinished{TemplateValue{v_1003104}}}
    case Ast.TermMin{v_1003105, v_1003106, v_1003107}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003105, v_3}}, v_1003108 => +v_1003109 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003108); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003106, v_3}}, v_1003110 => +v_1003111 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003110); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003109, v_1003111}}, v_1003112 => +v_1003113 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003112); TemplateFinished{TemplateValue{v_1003113}}}}}
    case Ast.TermAll{v_1003114, v_1003115, v_1003116, v_1003117, v_1003118, v_1003119}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003117, v_3}}, v_1003120 => +v_1003121 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003120); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003118, v_3}}, v_1003122 => +v_1003123 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003122); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003121, v_1003123}}, v_1003124 => +v_1003125 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003124); TemplateFinished{TemplateValue{v_1003125}}}}}
    case Ast.TermLam{v_1003126, v_1003127, v_1003128, v_1003129, v_1003130}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003129, v_3}}, v_1003131 => +v_1003132 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003131); TemplateFinished{TemplateValue{v_1003132}}}
    case Ast.TermAdt{v_1003133, v_1003134, v_1003135, v_1003136}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1003134, v_3}}, v_1003137 => +v_1003138 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003137); TemplateFinished{TemplateValue{v_1003138}}}
    case Ast.TermFill{v_1003139, v_1003140, v_1003141}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003139, v_3}}, v_1003142 => +v_1003143 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003142); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1003140, v_3}}, v_1003144 => +v_1003145 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003144); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003143, v_1003145}}, v_1003146 => +v_1003147 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003146); TemplateFinished{TemplateValue{v_1003147}}}}}
    case Ast.TermPlus{v_1003148, v_1003149, v_1003150}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003148, v_3}}, v_1003151 => +v_1003152 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003151); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1003149, v_3}}, v_1003153 => +v_1003154 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003153); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003152, v_1003154}}, v_1003155 => +v_1003156 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003155); TemplateFinished{TemplateValue{v_1003156}}}}}
    case Ast.TermCtr{v_1003157, v_1003158, v_1003159}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1003158, v_3}}, v_1003160 => +v_1003161 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003160); TemplateFinished{TemplateValue{v_1003161}}}
    case Ast.TermString{v_1003162, v_1003163, v_1003164}:
      TemplateFinished{TemplateValue{None{}}}
    case Ast.TermMat{v_1003165, v_1003166, v_1003167, v_1003168}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003166, v_3}}, v_1003169 => +v_1003170 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003169); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003167, v_3}}, v_1003171 => +v_1003172 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003171); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003170, v_1003172}}, v_1003173 => +v_1003174 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003173); TemplateFinished{TemplateValue{v_1003174}}}}}
    case Ast.TermEqual{v_1003175, v_1003176, v_1003177, v_1003178}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003175, v_3}}, v_1003179 => +v_1003180 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003179); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003176, v_3}}, v_1003181 => +v_1003182 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003181); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003177, v_3}}, v_1003183 => +v_1003184 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003183); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003182, v_1003184}}, v_1003185 => +v_1003186 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003185); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003180, v_1003186}}, v_1003187 => +v_1003188 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003187); TemplateFinished{TemplateValue{v_1003188}}}}}}}
    case Ast.TermRewrite{v_1003189, v_1003190, v_1003191, v_1003192}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003189, v_3}}, v_1003193 => +v_1003194 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003193); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003190, v_3}}, v_1003195 => +v_1003196 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003195); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003191, v_3}}, v_1003197 => +v_1003198 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003197); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003196, v_1003198}}, v_1003199 => +v_1003200 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003199); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003194, v_1003200}}, v_1003201 => +v_1003202 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003201); TemplateFinished{TemplateValue{v_1003202}}}}}}}
    case Ast.BodyMatch{v_1003203, v_1003204, v_1003205}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1003203, v_3}}, v_1003206 => +v_1003207 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003206); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1003204, v_3}}, v_1003208 => +v_1003209 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003208); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003207, v_1003209}}, v_1003210 => +v_1003211 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003210); TemplateFinished{TemplateValue{v_1003211}}}}}
    case Ast.BodyCase{v_1003212, v_1003213, v_1003214}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003213, v_3}}, v_1003215 => +v_1003216 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003215); TemplateFinished{TemplateValue{v_1003216}}}
    case Ast.BodyLocal{v_1003217, v_1003218, v_1003219, v_1003220, v_1003221}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1003219, v_3}}, v_1003222 => +v_1003223 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003222); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003220, v_3}}, v_1003224 => +v_1003225 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003224); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003223, v_1003225}}, v_1003226 => +v_1003227 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003226); TemplateFinished{TemplateValue{v_1003227}}}}}
    case Ast.BodyReply{v_1003228, v_1003229}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003228, v_3}}, v_1003230 => +v_1003231 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003230); TemplateFinished{TemplateValue{v_1003231}}}
    case v_1003232:
      TemplateFinished{TemplateValue{None{}}}

def template_body_invalid_reference(v_0: Ast.SourceSpan, v_3: Maybe<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_3:
    case Some{v_1003233}:
      TemplateFinished{TemplateValue{Some{v_0}}}
    case None{}:
      TemplateFinished{TemplateValue{None{}}}

def template_body_invalid_application_spine(v_0: Ast.SyntaxTerm, +v_3: List<&2, TemplateDef>, v_5: ApplicationSpine) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_5:
    case ApplicationSpine{+v_1003234, v_1003235, v_1003236}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_template_for_head{v_1003234, v_3}}, False{}, v_1003242 => template_body_template_for_head(v_1003234, v_3), v_1003243 => +v_1003244 = template_unbox(Maybe<&2, TemplateDef>, v_1003243); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application_head{{v_0 : Ast.SyntaxTerm}, {v_3 : List<&2, TemplateDef>}, {v_1003234 : Ast.SyntaxTerm}, {v_1003235 : List<&2, Ast.SyntaxTerm>}, {v_1003236 : Ast.SourceSpan}, v_1003244}}, v_1003245 => +v_1003246 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003245); TemplateFinished{TemplateValue{v_1003246}}}}

def template_continuation_230(+v_1001477: Nat, +v_6: List<&2, Ast.SyntaxTerm>, v_7: Ast.SourceSpan, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application_arity{v_6, v_1001477, v_7, v_3, Nat.is_ge(List.length(&2, Ast.SyntaxTerm, v_6), v_1001477)}}, v_1001479 => +v_1001478 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001479); TemplateFinished{TemplateValue{v_1001478}}}

def template_body_invalid_application_head(v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>, v_4: Ast.SyntaxTerm, v_6: List<&2, Ast.SyntaxTerm>, v_7: Ast.SourceSpan, v_10: Maybe<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_10:
    case Some{v_1003247}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_template_arity{v_1003247}}, False{}, v_1003248 => template_body_template_arity(v_1003247), v_1003249 => +v_1003250 = template_unbox(Nat, v_1003249); template_continuation_230(v_1003250, v_6, v_7, v_3)}
    case None{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application_parts{v_0, v_3}}, v_1003251 => +v_1003252 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003251); TemplateFinished{TemplateValue{v_1003252}}}

def template_body_invalid_application_arity(+v_1: List<&2, Ast.SyntaxTerm>, +v_3: Nat, v_4: Ast.SourceSpan, v_7: List<&2, TemplateDef>, v_9: Bool) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_9:
    case False{}:
      TemplateFinished{TemplateValue{Some{v_4}}}
    case True{}:
      v_1003255 = {v_4 : Ast.SourceSpan}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_take_template_args{v_1, v_3}}, False{}, v_1003257 => template_body_take_template_args(v_1, v_3), v_1003258 => +v_1003259 = template_unbox(Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_1003258); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application_arguments{{v_1 : List<&2, Ast.SyntaxTerm>}, {v_3 : Nat}, v_1003255, {v_7 : List<&2, TemplateDef>}, v_1003259}}, v_1003260 => +v_1003261 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003260); TemplateFinished{TemplateValue{v_1003261}}}}

def template_body_invalid_application_arguments(+v_1: List<&2, Ast.SyntaxTerm>, +v_3: Nat, v_4: Ast.SourceSpan, +v_7: List<&2, TemplateDef>, v_10: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_10:
    case None{}:
      TemplateFinished{TemplateValue{Some{v_4}}}
    case Some{v_1003262}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_args{v_1, v_3, v_4, v_7}}, v_1003263 => +v_1003264 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003263); TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_drop_args{v_1, v_3}}, False{}, v_1003265 => template_body_drop_args(v_1, v_3), v_1003266 => +v_1003267 = template_unbox(List<&2, Ast.SyntaxTerm>, v_1003266); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1003267, v_7}}, v_1003268 => +v_1003269 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003268); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003264, v_1003269}}, v_1003270 => +v_1003271 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003270); TemplateFinished{TemplateValue{v_1003271}}}}}}

def template_body_invalid_application_parts(v_0: Ast.SyntaxTerm, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_0:
    case Ast.TermApp{v_1003272, v_1003273, v_1003274}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003272, v_3}}, False{}, v_1003275 => template_body_invalid_application(v_1003272, v_3), v_1003276 => +v_1003277 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003276); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003273, v_3}}, False{}, v_1003278 => template_body_invalid_application(v_1003273, v_3), v_1003279 => +v_1003280 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003279); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003277, v_1003280}}, v_1003281 => +v_1003282 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003281); TemplateFinished{TemplateValue{v_1003282}}}}}
    case v_1003283:
      TemplateFinished{TemplateValue{None{}}}

def template_body_invalid_template_args(v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat, v_4: Ast.SourceSpan, v_7: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1, v_3:
    case _, 0n:
      TemplateFinished{TemplateValue{None{}}}
    case Ast.TermTemplate{+v_15, _} <> v_17, 1n+v_18:
      v_1001512 = {Nat.add(1n, v_18) : Nat}
      v_1001513 = {v_4 : Ast.SourceSpan}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_15, 0n}}, v_1001518 => +v_1001515 = template_unbox(Bool, v_1001518); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_argument{{v_15 : Ast.SyntaxTerm}, {v_17 : List<&2, Ast.SyntaxTerm>}, v_1001512, v_1001513, {v_7 : List<&2, TemplateDef>}, v_1001515}}, v_1001517 => +v_1001516 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001517); TemplateFinished{TemplateValue{v_1001516}}}}
    case _, _:
      TemplateFinished{TemplateValue{Some{v_4}}}

def template_body_invalid_template_argument(+v_0: Ast.SyntaxTerm, +v_2: List<&2, Ast.SyntaxTerm>, +v_4: Nat, +v_5: Ast.SourceSpan, +v_8: List<&2, TemplateDef>, v_10: Bool) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_10:
    case True{}:
      TemplateFinished{TemplateValue{Some{v_5}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_0, v_8}}, False{}, v_1003284 => template_body_invalid_application(v_0, v_8), v_1003285 => +v_1003286 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003285); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_context{v_0, v_8}}, v_1003287 => +v_1003288 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003287); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003286, v_1003288}}, v_1003289 => +v_1003290 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003289); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_template_args{v_2, Nat.sub(v_4, 1n), v_5, v_8}}, False{}, v_1003291 => template_body_invalid_template_args(v_2, Nat.sub(v_4, 1n), v_5, v_8), v_1003292 => +v_1003293 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003292); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003290, v_1003293}}, v_1003294 => +v_1003295 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003294); TemplateFinished{TemplateValue{v_1003295}}}}}}}

def template_body_invalid_capture_context(v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_3:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1003296 <> v_1003297:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_0, template_pure_template_capture_names(v_1003296)}}, v_1003298 => +v_1003299 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003298); TemplateFinished{TemplateValue{v_1003299}}}

def template_match_238(+v_1001533: Maybe<&2, String>, v_4: Ast.SourceSpan) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1001533:
    case Some{_}:
      TemplateFinished{TemplateValue{None{}}}
    case None{}:
      TemplateFinished{TemplateValue{Some{v_4}}}

def template_body_invalid_capture_key(v_1: String, v_3: Bool, v_4: Ast.SourceSpan, v_7: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_7, None{}}}, False{}, v_1001535 => template_body_capture_name(v_1, v_3, v_7, None{}), v_1001534 => +v_1001533 = template_unbox(Maybe<&2, String>, v_1001534); template_match_238(v_1001533, v_4)}

def template_body_invalid_capture_strings(v_2: List<&2, String>, +v_3: Ast.SourceSpan, +v_6: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_2:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1003300 <> v_1003301:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_1003300, True{}, v_3, v_6}}, False{}, v_1003302 => template_body_invalid_capture_key(v_1003300, True{}, v_3, v_6), v_1003303 => +v_1003304 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003303); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_strings{v_1003301, v_3, v_6}}, v_1003305 => +v_1003306 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003305); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003304, v_1003306}}, v_1003307 => +v_1003308 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003307); TemplateFinished{TemplateValue{v_1003308}}}}}

def template_body_invalid_capture_patterns(v_1: List<&2, Ast.SyntaxPattern>, +v_4: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case Ast.PatternVar{v_1003309, v_1003310, v_1003311, v_1003312} <> v_1003313:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_patterns{v_1003313, v_4}}, v_1003314 => +v_1003315 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003314); TemplateFinished{TemplateValue{v_1003315}}}
    case Ast.PatternCtr{v_1003316, v_1003317, v_1003318} <> v_1003319:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_1003316, True{}, v_1003318, v_4}}, False{}, v_1003320 => template_body_invalid_capture_key(v_1003316, True{}, v_1003318, v_4), v_1003321 => +v_1003322 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003321); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_patterns{v_1003317, v_4}}, v_1003323 => +v_1003324 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003323); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_patterns{v_1003319, v_4}}, v_1003325 => +v_1003326 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003325); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003324, v_1003326}}, v_1003327 => +v_1003328 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003327); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003322, v_1003328}}, v_1003329 => +v_1003330 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003329); TemplateFinished{TemplateValue{v_1003330}}}}}}}

def template_body_invalid_capture_terms(v_1: List<&2, Ast.SyntaxTerm>, +v_4: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1003331 <> v_1003332:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003331, v_4}}, v_1003333 => +v_1003334 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003333); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_1003332, v_4}}, v_1003335 => +v_1003336 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003335); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003334, v_1003336}}, v_1003337 => +v_1003338 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003337); TemplateFinished{TemplateValue{v_1003338}}}}}

def template_body_invalid_capture_string_bit(v_1: Bool, v_2: Ast.StringLiteralNames, v_3: Ast.SourceSpan, v_6: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1, v_2:
    case True{}, Ast.StringLiteralNames{_, _, _, _, _, _, v_22, _}:
      template_body_invalid_capture_key(v_22, True{}, v_3, v_6)
    case False{}, Ast.StringLiteralNames{_, _, _, _, _, _, _, v_40}:
      template_body_invalid_capture_key(v_40, True{}, v_3, v_6)

def template_body_invalid_capture_string_word(v_1: Nat, +v_3: U32, +v_4: Ast.StringLiteralNames, +v_5: Ast.SourceSpan, +v_8: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1, v_4:
    case 0n, Ast.StringLiteralNames{v_1003339, v_1003340, v_1003341, v_1003342, v_1003343, v_1003344, v_1003345, v_1003346}:
      template_body_invalid_capture_key(v_1003343, True{}, v_5, v_8)
    case 1n+v_1003347, Ast.StringLiteralNames{v_1003348, v_1003349, v_1003350, v_1003351, v_1003352, v_1003353, v_1003354, v_1003355}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_1003353, True{}, v_5, v_8}}, False{}, v_1003356 => template_body_invalid_capture_key(v_1003353, True{}, v_5, v_8), v_1003357 => +v_1003358 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003357); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_string_bit{U32.is_zero(U32.and(v_3, 1)), v_4, v_5, v_8}}, False{}, v_1003359 => template_body_invalid_capture_string_bit(U32.is_zero(U32.and(v_3, 1)), v_4, v_5, v_8), v_1003360 => +v_1003361 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003360); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_string_word{v_1003347, U32.shr(v_3), v_4, v_5, v_8}}, v_1003362 => +v_1003363 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003362); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003361, v_1003363}}, v_1003364 => +v_1003365 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003364); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003358, v_1003365}}, v_1003366 => +v_1003367 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003366); TemplateFinished{TemplateValue{v_1003367}}}}}}}

def template_body_invalid_capture_string(v_2: List<&2, U32>, +v_3: Ast.StringLiteralNames, +v_4: Ast.SourceSpan, +v_7: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_2, v_3:
    case [], Ast.StringLiteralNames{v_17, _, _, _, _, _, _, _}:
      template_body_invalid_capture_key(v_17, True{}, v_4, v_7)
    case v_36 <> v_37, Ast.StringLiteralNames{_, v_39, v_40, v_41, _, _, _, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_39, True{}, v_4, v_7}}, False{}, v_1001599 => template_body_invalid_capture_key(v_39, True{}, v_4, v_7), v_1001598 => +v_1001578 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001598); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_40, True{}, v_4, v_7}}, False{}, v_1001597 => template_body_invalid_capture_key(v_40, True{}, v_4, v_7), v_1001596 => +v_1001579 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001596); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_41, True{}, v_4, v_7}}, False{}, v_1001595 => template_body_invalid_capture_key(v_41, True{}, v_4, v_7), v_1001594 => +v_1001580 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001594); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_string_word{32n, v_36, v_3, v_4, v_7}}, False{}, v_1001593 => template_body_invalid_capture_string_word(32n, v_36, v_3, v_4, v_7), v_1001592 => +v_1001581 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001592); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_string{v_37, v_3, v_4, v_7}}, v_1001591 => +v_1001582 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001591); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001581, v_1001582}}, v_1001590 => +v_1001583 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001590); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001580, v_1001583}}, v_1001589 => +v_1001584 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001589); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001579, v_1001584}}, v_1001588 => +v_1001585 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001588); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001578, v_1001585}}, v_1001587 => +v_1001586 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001587); TemplateFinished{TemplateValue{v_1001586}}}}}}}}}}}

def template_body_invalid_capture(v_0: Ast.SyntaxTerm, +v_3: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_0:
    case Ast.TermRef{v_1003368, v_1003369}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_reference_key{v_1003368}}, False{}, v_1003370 => template_body_reference_key(v_1003368), v_1003371 => +v_1003372 = template_unbox(String, v_1003371); template_body_invalid_capture_key(v_1003372, False{}, v_1003369, v_3)}
    case Ast.TermBang{v_1003373, v_1003374}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003373, v_3}}, v_1003375 => +v_1003376 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003375); TemplateFinished{TemplateValue{v_1003376}}}
    case Ast.TermSub{v_1003377, v_1003378, v_1003379, v_1003380}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003378, v_3}}, v_1003381 => +v_1003382 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003381); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003379, v_3}}, v_1003383 => +v_1003384 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003383); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003382, v_1003384}}, v_1003385 => +v_1003386 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003385); TemplateFinished{TemplateValue{v_1003386}}}}}
    case Ast.TermLet{v_1003387, v_1003388, v_1003389, v_1003390, v_1003391, v_1003392}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_1003390, v_3}}, False{}, v_1003393 => template_body_invalid_capture_terms(v_1003390, v_3), v_1003394 => +v_1003395 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003394); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003391, v_3}}, v_1003396 => +v_1003397 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003396); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003395, v_1003397}}, v_1003398 => +v_1003399 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003398); TemplateFinished{TemplateValue{v_1003399}}}}}
    case Ast.TermAnn{v_1003400, v_1003401, v_1003402}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003400, v_3}}, v_1003403 => +v_1003404 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003403); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003401, v_3}}, v_1003405 => +v_1003406 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003405); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003404, v_1003406}}, v_1003407 => +v_1003408 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003407); TemplateFinished{TemplateValue{v_1003408}}}}}
    case Ast.TermTemplate{v_1003409, v_1003410}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003409, v_3}}, v_1003411 => +v_1003412 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003411); TemplateFinished{TemplateValue{v_1003412}}}
    case Ast.TermType{v_1003413, v_1003414}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003413, v_3}}, v_1003415 => +v_1003416 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003415); TemplateFinished{TemplateValue{v_1003416}}}
    case Ast.TermMin{v_1003417, v_1003418, v_1003419}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003417, v_3}}, v_1003420 => +v_1003421 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003420); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003418, v_3}}, v_1003422 => +v_1003423 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003422); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003421, v_1003423}}, v_1003424 => +v_1003425 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003424); TemplateFinished{TemplateValue{v_1003425}}}}}
    case Ast.TermAll{v_1003426, v_1003427, v_1003428, v_1003429, v_1003430, v_1003431}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003429, v_3}}, v_1003432 => +v_1003433 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003432); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003430, v_3}}, v_1003434 => +v_1003435 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003434); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003433, v_1003435}}, v_1003436 => +v_1003437 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003436); TemplateFinished{TemplateValue{v_1003437}}}}}
    case Ast.TermLam{v_1003438, v_1003439, v_1003440, v_1003441, v_1003442}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003441, v_3}}, v_1003443 => +v_1003444 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003443); TemplateFinished{TemplateValue{v_1003444}}}
    case Ast.TermApp{v_1003445, v_1003446, v_1003447}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003445, v_3}}, v_1003448 => +v_1003449 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003448); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003446, v_3}}, v_1003450 => +v_1003451 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003450); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003449, v_1003451}}, v_1003452 => +v_1003453 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003452); TemplateFinished{TemplateValue{v_1003453}}}}}
    case Ast.TermAdt{v_1003454, v_1003455, v_1003456, +v_1003457}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_1003454, False{}, v_1003457, v_3}}, False{}, v_1003458 => template_body_invalid_capture_key(v_1003454, False{}, v_1003457, v_3), v_1003459 => +v_1003460 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003459); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_1003455, v_3}}, False{}, v_1003461 => template_body_invalid_capture_terms(v_1003455, v_3), v_1003462 => +v_1003463 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003462); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_strings{v_1003456, v_1003457, v_3}}, False{}, v_1003464 => template_body_invalid_capture_strings(v_1003456, v_1003457, v_3), v_1003465 => +v_1003466 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003465); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003463, v_1003466}}, v_1003467 => +v_1003468 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003467); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003460, v_1003468}}, v_1003469 => +v_1003470 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003469); TemplateFinished{TemplateValue{v_1003470}}}}}}}
    case Ast.TermFill{v_1003471, v_1003472, v_1003473}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003471, v_3}}, v_1003474 => +v_1003475 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003474); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_1003472, v_3}}, False{}, v_1003476 => template_body_invalid_capture_terms(v_1003472, v_3), v_1003477 => +v_1003478 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003477); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003475, v_1003478}}, v_1003479 => +v_1003480 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003479); TemplateFinished{TemplateValue{v_1003480}}}}}
    case Ast.TermPlus{v_1003481, v_1003482, v_1003483}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003481, v_3}}, v_1003484 => +v_1003485 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003484); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_1003482, v_3}}, False{}, v_1003486 => template_body_invalid_capture_terms(v_1003482, v_3), v_1003487 => +v_1003488 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003487); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003485, v_1003488}}, v_1003489 => +v_1003490 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003489); TemplateFinished{TemplateValue{v_1003490}}}}}
    case Ast.TermCtr{v_1003491, v_1003492, v_1003493}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_1003491, True{}, v_1003493, v_3}}, False{}, v_1003494 => template_body_invalid_capture_key(v_1003491, True{}, v_1003493, v_3), v_1003495 => +v_1003496 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003495); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_1003492, v_3}}, False{}, v_1003497 => template_body_invalid_capture_terms(v_1003492, v_3), v_1003498 => +v_1003499 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003498); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003496, v_1003499}}, v_1003500 => +v_1003501 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003500); TemplateFinished{TemplateValue{v_1003501}}}}}
    case Ast.TermString{v_1003502, v_1003503, v_1003504}:
      template_body_invalid_capture_string(v_1003502, v_1003503, v_1003504, v_3)
    case Ast.TermMat{v_1003505, v_1003506, v_1003507, v_1003508}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_1003505, True{}, v_1003508, v_3}}, False{}, v_1003509 => template_body_invalid_capture_key(v_1003505, True{}, v_1003508, v_3), v_1003510 => +v_1003511 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003510); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003506, v_3}}, v_1003512 => +v_1003513 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003512); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003507, v_3}}, v_1003514 => +v_1003515 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003514); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003513, v_1003515}}, v_1003516 => +v_1003517 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003516); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003511, v_1003517}}, v_1003518 => +v_1003519 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003518); TemplateFinished{TemplateValue{v_1003519}}}}}}}
    case Ast.TermEqual{v_1003520, v_1003521, v_1003522, v_1003523}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003520, v_3}}, v_1003524 => +v_1003525 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003524); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003521, v_3}}, v_1003526 => +v_1003527 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003526); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003522, v_3}}, v_1003528 => +v_1003529 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003528); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003527, v_1003529}}, v_1003530 => +v_1003531 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003530); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003525, v_1003531}}, v_1003532 => +v_1003533 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003532); TemplateFinished{TemplateValue{v_1003533}}}}}}}
    case Ast.TermRewrite{v_1003534, v_1003535, v_1003536, v_1003537}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003534, v_3}}, v_1003538 => +v_1003539 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003538); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003535, v_3}}, v_1003540 => +v_1003541 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003540); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003536, v_3}}, v_1003542 => +v_1003543 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003542); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003541, v_1003543}}, v_1003544 => +v_1003545 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003544); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003539, v_1003545}}, v_1003546 => +v_1003547 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003546); TemplateFinished{TemplateValue{v_1003547}}}}}}}
    case Ast.BodyMatch{v_1003548, v_1003549, v_1003550}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_1003548, v_3}}, False{}, v_1003551 => template_body_invalid_capture_terms(v_1003548, v_3), v_1003552 => +v_1003553 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003552); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_1003549, v_3}}, False{}, v_1003554 => template_body_invalid_capture_terms(v_1003549, v_3), v_1003555 => +v_1003556 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003555); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003553, v_1003556}}, v_1003557 => +v_1003558 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003557); TemplateFinished{TemplateValue{v_1003558}}}}}
    case Ast.BodyCase{v_1003559, v_1003560, v_1003561}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_patterns{v_1003559, v_3}}, False{}, v_1003562 => template_body_invalid_capture_patterns(v_1003559, v_3), v_1003563 => +v_1003564 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003563); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003560, v_3}}, v_1003565 => +v_1003566 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003565); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003564, v_1003566}}, v_1003567 => +v_1003568 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003567); TemplateFinished{TemplateValue{v_1003568}}}}}
    case Ast.BodyLocal{v_1003569, v_1003570, v_1003571, v_1003572, v_1003573}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_patterns{v_1003569, v_3}}, False{}, v_1003574 => template_body_invalid_capture_patterns(v_1003569, v_3), v_1003575 => +v_1003576 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003575); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_1003571, v_3}}, False{}, v_1003577 => template_body_invalid_capture_terms(v_1003571, v_3), v_1003578 => +v_1003579 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003578); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003572, v_3}}, v_1003580 => +v_1003581 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003580); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003579, v_1003581}}, v_1003582 => +v_1003583 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003582); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003576, v_1003583}}, v_1003584 => +v_1003585 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003584); TemplateFinished{TemplateValue{v_1003585}}}}}}}
    case Ast.BodyReply{v_1003586, v_1003587}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_1003586, v_3}}, v_1003588 => +v_1003589 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003588); TemplateFinished{TemplateValue{v_1003589}}}
    case v_1003590:
      TemplateFinished{TemplateValue{None{}}}

def template_body_has_open_vars(v_0: Ast.SyntaxTerm, +v_2: Nat) -> TemplateProgress<Bool>:
  match v_0:
    case Ast.TermVar{v_1003591, v_1003592, v_1003593}:
      TemplateFinished{TemplateValue{Nat.is_ge(v_1003592, v_2)}}
    case Ast.TermSub{v_1003594, v_1003595, v_1003596, v_1003597}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003595, v_2}}, v_1003598 => +v_1003599 = template_unbox(Bool, v_1003598); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003596, Nat.add(v_2, 1n)}}, v_1003600 => +v_1003601 = template_unbox(Bool, v_1003600); TemplateFinished{TemplateValue{Bool.or(v_1003599, v_1003601)}}}}
    case Ast.TermLet{v_1003602, v_1003603, v_1003604, v_1003605, v_1003606, v_1003607}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_1003605, v_2}}, v_1003608 => +v_1003609 = template_unbox(Bool, v_1003608); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003606, Nat.add(v_2, List.length(&2, String, v_1003602))}}, v_1003610 => +v_1003611 = template_unbox(Bool, v_1003610); TemplateFinished{TemplateValue{Bool.or(v_1003609, v_1003611)}}}}
    case Ast.TermAnn{v_1003612, v_1003613, v_1003614}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003612, v_2}}, v_1003615 => +v_1003616 = template_unbox(Bool, v_1003615); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003613, v_2}}, v_1003617 => +v_1003618 = template_unbox(Bool, v_1003617); TemplateFinished{TemplateValue{Bool.or(v_1003616, v_1003618)}}}}
    case Ast.TermTemplate{v_1003619, v_1003620}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003619, v_2}}, v_1003621 => +v_1003622 = template_unbox(Bool, v_1003621); TemplateFinished{TemplateValue{v_1003622}}}
    case Ast.TermBang{v_1003623, v_1003624}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003623, v_2}}, v_1003625 => +v_1003626 = template_unbox(Bool, v_1003625); TemplateFinished{TemplateValue{v_1003626}}}
    case Ast.TermType{v_1003627, v_1003628}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003627, v_2}}, v_1003629 => +v_1003630 = template_unbox(Bool, v_1003629); TemplateFinished{TemplateValue{v_1003630}}}
    case Ast.TermMin{v_1003631, v_1003632, v_1003633}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003631, v_2}}, v_1003634 => +v_1003635 = template_unbox(Bool, v_1003634); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003632, v_2}}, v_1003636 => +v_1003637 = template_unbox(Bool, v_1003636); TemplateFinished{TemplateValue{Bool.or(v_1003635, v_1003637)}}}}
    case Ast.TermAll{v_1003638, v_1003639, v_1003640, v_1003641, v_1003642, v_1003643}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003641, v_2}}, v_1003644 => +v_1003645 = template_unbox(Bool, v_1003644); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003642, Nat.add(v_2, 1n)}}, v_1003646 => +v_1003647 = template_unbox(Bool, v_1003646); TemplateFinished{TemplateValue{Bool.or(v_1003645, v_1003647)}}}}
    case Ast.TermLam{v_1003648, v_1003649, v_1003650, v_1003651, v_1003652}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003651, Nat.add(v_2, 1n)}}, v_1003653 => +v_1003654 = template_unbox(Bool, v_1003653); TemplateFinished{TemplateValue{v_1003654}}}
    case Ast.TermApp{v_1003655, v_1003656, v_1003657}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003655, v_2}}, v_1003658 => +v_1003659 = template_unbox(Bool, v_1003658); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003656, v_2}}, v_1003660 => +v_1003661 = template_unbox(Bool, v_1003660); TemplateFinished{TemplateValue{Bool.or(v_1003659, v_1003661)}}}}
    case Ast.TermAdt{v_1003662, v_1003663, v_1003664, v_1003665}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_1003663, v_2}}, v_1003666 => +v_1003667 = template_unbox(Bool, v_1003666); TemplateFinished{TemplateValue{v_1003667}}}
    case Ast.TermFill{v_1003668, v_1003669, v_1003670}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003668, v_2}}, v_1003671 => +v_1003672 = template_unbox(Bool, v_1003671); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_1003669, v_2}}, v_1003673 => +v_1003674 = template_unbox(Bool, v_1003673); TemplateFinished{TemplateValue{Bool.or(v_1003672, v_1003674)}}}}
    case Ast.TermPlus{v_1003675, v_1003676, v_1003677}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003675, v_2}}, v_1003678 => +v_1003679 = template_unbox(Bool, v_1003678); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_1003676, v_2}}, v_1003680 => +v_1003681 = template_unbox(Bool, v_1003680); TemplateFinished{TemplateValue{Bool.or(v_1003679, v_1003681)}}}}
    case Ast.TermCtr{v_1003682, v_1003683, v_1003684}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_1003683, v_2}}, v_1003685 => +v_1003686 = template_unbox(Bool, v_1003685); TemplateFinished{TemplateValue{v_1003686}}}
    case Ast.TermString{v_1003687, v_1003688, v_1003689}:
      TemplateFinished{TemplateValue{False{}}}
    case Ast.TermMat{v_1003690, v_1003691, v_1003692, v_1003693}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003691, v_2}}, v_1003694 => +v_1003695 = template_unbox(Bool, v_1003694); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003692, v_2}}, v_1003696 => +v_1003697 = template_unbox(Bool, v_1003696); TemplateFinished{TemplateValue{Bool.or(v_1003695, v_1003697)}}}}
    case Ast.TermEqual{v_1003698, v_1003699, v_1003700, v_1003701}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003698, v_2}}, v_1003702 => +v_1003703 = template_unbox(Bool, v_1003702); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003699, v_2}}, v_1003704 => +v_1003705 = template_unbox(Bool, v_1003704); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003700, v_2}}, v_1003706 => +v_1003707 = template_unbox(Bool, v_1003706); TemplateFinished{TemplateValue{Bool.or(v_1003703, Bool.or(v_1003705, v_1003707))}}}}}
    case Ast.TermRewrite{v_1003708, v_1003709, v_1003710, v_1003711}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003708, v_2}}, v_1003712 => +v_1003713 = template_unbox(Bool, v_1003712); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003709, v_2}}, v_1003714 => +v_1003715 = template_unbox(Bool, v_1003714); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003710, v_2}}, v_1003716 => +v_1003717 = template_unbox(Bool, v_1003716); TemplateFinished{TemplateValue{Bool.or(v_1003713, Bool.or(v_1003715, v_1003717))}}}}}
    case Ast.BodyMatch{v_1003718, v_1003719, v_1003720}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_1003718, v_2}}, v_1003721 => +v_1003722 = template_unbox(Bool, v_1003721); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_1003719, v_2}}, v_1003723 => +v_1003724 = template_unbox(Bool, v_1003723); TemplateFinished{TemplateValue{Bool.or(v_1003722, v_1003724)}}}}
    case Ast.BodyCase{v_1003725, v_1003726, v_1003727}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003726, Nat.add(v_2, Core.pattern_list_depth(v_1003725))}}, v_1003728 => +v_1003729 = template_unbox(Bool, v_1003728); TemplateFinished{TemplateValue{v_1003729}}}
    case Ast.BodyLocal{v_1003730, v_1003731, v_1003732, v_1003733, v_1003734}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_1003732, v_2}}, v_1003735 => +v_1003736 = template_unbox(Bool, v_1003735); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003733, Nat.add(v_2, Core.pattern_list_depth(v_1003730))}}, v_1003737 => +v_1003738 = template_unbox(Bool, v_1003737); TemplateFinished{TemplateValue{Bool.or(v_1003736, v_1003738)}}}}
    case Ast.BodyReply{v_1003739, v_1003740}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003739, v_2}}, v_1003741 => +v_1003742 = template_unbox(Bool, v_1003741); TemplateFinished{TemplateValue{v_1003742}}}
    case v_1003743:
      TemplateFinished{TemplateValue{False{}}}

def template_body_has_open_vars_terms(v_1: List<&2, Ast.SyntaxTerm>, +v_3: Nat) -> TemplateProgress<Bool>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{False{}}}
    case +v_1003744 <> v_1003745:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_1003744, v_3}}, False{}, v_1003746 => template_body_has_open_vars(v_1003744, v_3), v_1003747 => +v_1003748 = template_unbox(Bool, v_1003747); TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_1003745, v_3}}, v_1003749 => +v_1003750 = template_unbox(Bool, v_1003749); TemplateFinished{TemplateValue{Bool.or(v_1003748, v_1003750)}}}}

def template_body_invalid_terms(v_1: List<&2, Ast.SyntaxTerm>, +v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1003751 <> v_1003752:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_1003751, v_4}}, False{}, v_1003753 => template_body_invalid_application(v_1003751, v_4), v_1003754 => +v_1003755 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003754); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1003752, v_4}}, v_1003756 => +v_1003757 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003756); TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1003755, v_1003757}}, v_1003758 => +v_1003759 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003758); TemplateFinished{TemplateValue{v_1003759}}}}}

def template_body_first_invalid(v_1: Maybe<&2, Ast.SourceSpan>, v_3: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case Some{v_6}:
      TemplateFinished{TemplateValue{Some{v_6}}}
    case None{}:
      TemplateFinished{TemplateValue{v_3}}

def template_match_250(+v_8: Ast.TopLevel, v_9: List<&2, Ast.TopLevel>, +v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_8:
    case Ast.DefTop{Ast.Definition{_, +v_17, v_18, v_19, _, _}}:
      v_1001832 = {v_9 : List<&2, Ast.TopLevel>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_has_template_binder{v_17}}, False{}, v_1001838 => template_body_has_template_binder(v_17), v_1001837 => +v_1001834 = template_unbox(Bool, v_1001837); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_definition{{v_17 : List<&2, Ast.TelescopeItem>}, {v_18 : Ast.OptionalTerm}, {v_19 : Ast.DefBody}, v_1001832, {v_4 : List<&2, TemplateDef>}, v_1001834}}, v_1001836 => +v_1001835 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001836); TemplateFinished{TemplateValue{v_1001835}}}}
    case Ast.TypeTop{Ast.TypeDecl{_, v_30, v_31, v_32, _}}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_binders{v_30, v_4}}, v_1001854 => +v_1001839 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001854); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_31, v_4}}, False{}, v_1001853 => template_body_invalid_application(v_31, v_4), v_1001852 => +v_1001840 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001852); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001839, v_1001840}}, False{}, v_1001851 => template_body_first_invalid(v_1001839, v_1001840), v_1001850 => +v_1001841 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001850); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_constructors{v_32, v_4}}, v_1001849 => +v_1001842 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001849); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_definitions{v_9, v_4}}, v_1001848 => +v_1001843 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001848); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001842, v_1001843}}, False{}, v_1001847 => template_body_first_invalid(v_1001842, v_1001843), v_1001846 => +v_1001844 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001846); template_body_first_invalid(v_1001841, v_1001844)}}}}}}
    case Ast.LawTop{Ast.LawDecl{_, v_46, v_47, _}}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_clauses{v_46, v_4}}, v_1001865 => +v_1001855 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001865); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_47, v_4}}, False{}, v_1001864 => template_body_invalid_application(v_47, v_4), v_1001863 => +v_1001856 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001863); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001855, v_1001856}}, False{}, v_1001862 => template_body_first_invalid(v_1001855, v_1001856), v_1001861 => +v_1001857 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001861); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_definitions{v_9, v_4}}, v_1001860 => +v_1001858 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001860); template_body_first_invalid(v_1001857, v_1001858)}}}}

def template_body_invalid_definitions(v_1: List<&2, Ast.TopLevel>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_8 <> v_9:
      template_match_250(v_8, v_9, v_4)

def template_continuation_252(v_15: Maybe<&2, Ast.SourceSpan>, v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, +v_1001870: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  v_1001871 = {v_15 : Maybe<&2, Ast.SourceSpan>}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_definitions{v_5, v_8}}, False{}, v_1001878 => template_body_invalid_definitions(v_5, v_8), v_1001877 => +v_1001872 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001877); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001871, v_1001872}}, False{}, v_1001876 => template_body_first_invalid(v_1001871, v_1001872), v_1001875 => +v_1001873 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001875); template_body_first_invalid(v_1001870, v_1001873)}}

def template_continuation_253(+v_1001867: Maybe<&2, Ast.SourceSpan>, v_1: List<&2, Ast.TelescopeItem>, +v_8: List<&2, TemplateDef>, v_2: Ast.OptionalTerm, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_binders{v_1, v_8}}, v_1001882 => +v_1001868 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001882); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_optional{v_2, v_8}}, v_1001881 => +v_1001869 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001881); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001868, v_1001869}}, False{}, v_1001880 => template_body_first_invalid(v_1001868, v_1001869), v_1001879 => +v_1001870 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001879); template_continuation_252(v_1001867, v_5, v_8, v_1001870)}}}

def template_body_invalid_definition(v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.OptionalTerm, v_3: Ast.DefBody, v_5: List<&2, Ast.TopLevel>, +v_8: List<&2, TemplateDef>, v_10: Bool) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_10:
    case True{}:
      template_body_invalid_definitions(v_5, v_8)
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_def_body{v_3, v_8}}, v_1003760 => +v_1003761 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003760); template_continuation_253(v_1003761, v_1, v_8, v_2, v_5)}

def template_body_invalid_def_body(v_0: Ast.DefBody, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_0:
    case Ast.DefTerm{v_6}:
      template_body_invalid_application(v_6, v_3)
    case Ast.DefImports{_}:
      TemplateFinished{TemplateValue{None{}}}

def template_body_invalid_optional(v_0: Ast.OptionalTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_0:
    case Ast.NoTerm{}:
      TemplateFinished{TemplateValue{None{}}}
    case Ast.SomeTerm{v_6}:
      template_body_invalid_application(v_6, v_3)

def template_match_257(+v_8: Ast.TelescopeItem, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_8:
    case Ast.Binder{_, _, _, v_18, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_18, v_4}}, False{}, v_1001891 => template_body_invalid_application(v_18, v_4), v_1001890 => +v_1001886 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001890); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_binders{v_9, v_4}}, v_1001889 => +v_1001887 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001889); template_body_first_invalid(v_1001886, v_1001887)}}
    case Ast.TemplateBinder{_, _, v_29, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_29, v_4}}, False{}, v_1001897 => template_body_invalid_application(v_29, v_4), v_1001896 => +v_1001892 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001896); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_binders{v_9, v_4}}, v_1001895 => +v_1001893 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001895); template_body_first_invalid(v_1001892, v_1001893)}}

def template_body_invalid_binders(v_1: List<&2, Ast.TelescopeItem>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_8 <> v_9:
      template_match_257(v_8, v_4, v_9)

def template_match_259(+v_8: Ast.ConstructorDecl, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.ConstructorDecl>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_8:
    case Ast.Constructor{_, v_14, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_binders{v_14, v_4}}, False{}, v_1001903 => template_body_invalid_binders(v_14, v_4), v_1001902 => +v_1001898 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001902); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_constructors{v_9, v_4}}, v_1001901 => +v_1001899 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001901); template_body_first_invalid(v_1001898, v_1001899)}}

def template_body_invalid_constructors(v_1: List<&2, Ast.ConstructorDecl>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_8 <> v_9:
      template_match_259(v_8, v_4, v_9)

def template_match_261(+v_8: Ast.Clause, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.Clause>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_8:
    case Ast.ClauseFor{_, _, _, v_19, v_20, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_19, v_4}}, False{}, v_1001914 => template_body_invalid_application(v_19, v_4), v_1001913 => +v_1001904 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001913); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_maybe{v_20, v_4}}, v_1001912 => +v_1001905 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001912); TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_clauses{v_9, v_4}}, v_1001911 => +v_1001906 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001911); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001905, v_1001906}}, False{}, v_1001910 => template_body_first_invalid(v_1001905, v_1001906), v_1001909 => +v_1001907 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001909); template_body_first_invalid(v_1001904, v_1001907)}}}}

def template_body_invalid_clauses(v_1: List<&2, Ast.Clause>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_8 <> v_9:
      template_match_261(v_8, v_4, v_9)

def template_body_invalid_maybe(v_1: Maybe<&2, Ast.SyntaxTerm>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case None{}:
      TemplateFinished{TemplateValue{None{}}}
    case Some{v_6}:
      template_body_invalid_application(v_6, v_4)

def template_body_expand(+v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<ExpandResult>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_collect_templates{v_1}}, False{}, v_1001924 => template_body_collect_templates(v_1), v_1001923 => +v_1001917 = template_unbox(List<&2, TemplateDef>, v_1001923); TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_template_definitions{v_1}}, False{}, v_1001922 => template_body_invalid_template_definitions(v_1), v_1001921 => +v_1001918 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001921); TemplatePending{TemplateRequestGroup_3{TemplateRequest_template_expand_templates{{v_1 : List<&2, Loader.LoadedModule>}, v_1001917, v_1001918}}, v_1001920 => +v_1001919 = template_unbox(ExpandResult, v_1001920); TemplateFinished{TemplateValue{v_1001919}}}}}

def template_body_template_expand_templates(+v_1: List<&2, Loader.LoadedModule>, +v_4: List<&2, TemplateDef>, v_6: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<ExpandResult>:
  match v_6:
    case Some{v_1003762}:
      TemplateFinished{TemplateValue{ExpandFailure{"template binders must precede runtime binders", v_1003762}}}
    case None{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_invalid_modules{v_1, v_4}}, v_1003765 => +v_1003766 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003765); TemplatePending{TemplateRequestGroup_3{TemplateRequest_template_expand_modules{{v_1 : List<&2, Loader.LoadedModule>}, {v_4 : List<&2, TemplateDef>}, v_1003766}}, v_1003767 => +v_1003768 = template_unbox(ExpandResult, v_1003767); TemplateFinished{TemplateValue{v_1003768}}}}

def template_body_template_expand_modules(+v_1: List<&2, Loader.LoadedModule>, +v_4: List<&2, TemplateDef>, v_6: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<ExpandResult>:
  match v_6:
    case Some{v_1003769}:
      TemplateFinished{TemplateValue{ExpandFailure{"template application requires a compile-time template argument", v_1003769}}}
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generate_until_stable{v_1, v_4, []}}, False{}, v_1003771 => template_body_generate_until_stable(v_1, v_4, []), v_1003772 => +v_1003773 = template_unbox(GeneratedRound, v_1003772); TemplatePending{TemplateRequestGroup_3{TemplateRequest_template_expand_round{{v_4 : List<&2, TemplateDef>}, v_1003773}}, v_1003774 => +v_1003775 = template_unbox(ExpandResult, v_1003774); TemplateFinished{TemplateValue{v_1003775}}}}

def template_match_266(v_1001937: Bool, +v_5: Ast.TopLevel, v_6: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_1001937:
    case True{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_generated_declarations{v_6}}, v_1001940 => +v_1001939 = template_unbox(List<&2, Ast.TopLevel>, v_1001940); TemplateFinished{TemplateValue{{v_5 : Ast.TopLevel} <> v_1001939}}}
    case False{}:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_generated_declarations{v_6}}, v_1001942 => +v_1001941 = template_unbox(List<&2, Ast.TopLevel>, v_1001942); TemplateFinished{TemplateValue{v_1001941}}}

def template_match_267(+v_5: Ast.TopLevel, v_6: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_5:
    case Ast.DefTop{Ast.Definition{v_13, _, _, _, _, _}}:
      v_1001937 = {String.starts_with(v_13, "T~") : Bool}
      template_match_266(v_1001937, v_5, v_6)
    case _:
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_generated_declarations{v_6}}, v_1001944 => +v_1001943 = template_unbox(List<&2, Ast.TopLevel>, v_1001944); TemplateFinished{TemplateValue{v_1001943}}}

def template_body_generated_declarations(v_1: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case +v_5 <> v_6:
      template_match_267(v_5, v_6)

def template_body_generated_modules(v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{[]}}
    case Loader.LoadedModule{v_8, Ast.Module{v_9, v_10, v_11}} <> v_12:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_generated_declarations{v_11}}, False{}, v_1001952 => template_body_generated_declarations(v_11), v_1001951 => +v_1001948 = template_unbox(List<&2, Ast.TopLevel>, v_1001951); TemplatePending{TemplateRequestGroup_3{TemplateRequest_generated_modules{v_12}}, v_1001950 => +v_1001949 = template_unbox(List<&2, Loader.LoadedModule>, v_1001950); TemplateFinished{TemplateValue{Loader.LoadedModule{{v_8 : String}, Ast.Module{{v_9 : String}, {v_10 : List<&2, Ast.ModuleImport>}, v_1001948}} <> v_1001949}}}}

def template_body_template_expand_round(+v_2: List<&2, TemplateDef>, v_4: GeneratedRound) -> TemplateProgress<ExpandResult>:
  match v_4:
    case GeneratedRound{v_1003776, v_1003777, v_1003778, Some{v_1003779}}:
      TemplateFinished{TemplateValue{ExpandFailure{"template specialization hash collision", v_1003779}}}
    case GeneratedRound{+v_1003780, v_1003781, v_1003782, None{}}:
      TemplateDirect{Bool, TemplateRequestGroup_3{TemplateRequest_generated_modules{v_1003780}}, False{}, v_1003786 => template_body_generated_modules(v_1003780), v_1003787 => +v_1003788 = template_unbox(List<&2, Loader.LoadedModule>, v_1003787); TemplatePending{TemplateRequestGroup_3{TemplateRequest_invalid_scoped_modules{v_1003788, v_1003780, v_2}}, v_1003789 => +v_1003790 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1003789); TemplatePending{TemplateRequestGroup_3{TemplateRequest_template_expand_generated{{v_1003780 : List<&2, Loader.LoadedModule>}, {v_1003782 : List<&2, GeneratedIdentity>}, {v_2 : List<&2, TemplateDef>}, v_1003790}}, v_1003791 => +v_1003792 = template_unbox(ExpandResult, v_1003791); TemplateFinished{TemplateValue{v_1003792}}}}}

def template_body_template_expand_generated(+v_1: List<&2, Loader.LoadedModule>, +v_4: List<&2, GeneratedIdentity>, +v_7: List<&2, TemplateDef>, v_9: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<ExpandResult>:
  match v_9:
    case Some{v_1003793}:
      TemplateFinished{TemplateValue{ExpandFailure{"template application requires a closed compile-time argument", v_1003793}}}
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_expand_modules{v_1, v_7, v_4}}, False{}, v_1003794 => template_body_expand_modules(v_1, v_7, v_4), v_1003795 => +v_1003796 = template_unbox(List<&2, Loader.LoadedModule>, v_1003795); TemplateFinished{TemplateValue{ExpandSuccess{v_1003796}}}}

def template_body_invalid_modules(+v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_invalid_scoped_modules{v_1, v_1, v_4}}, v_1001967 => +v_1001966 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001967); TemplateFinished{TemplateValue{v_1001966}}}

def template_continuation_272(+v_1001968: List<&2, TemplateDef>, v_19: List<&2, Ast.TopLevel>, v_11: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  v_22 = v_1001968
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_definitions{v_19, v_22}}, False{}, v_1001974 => template_body_invalid_definitions(v_19, v_22), v_1001973 => +v_1001969 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001973); TemplatePending{TemplateRequestGroup_3{TemplateRequest_invalid_scoped_modules{v_11, v_3, v_6}}, v_1001972 => +v_1001970 = template_unbox(Maybe<&2, Ast.SourceSpan>, v_1001972); template_body_first_invalid(v_1001969, v_1001970)}}

def template_match_273(+v_10: Loader.LoadedModule, +v_6: List<&2, TemplateDef>, +v_3: List<&2, Loader.LoadedModule>, v_11: List<&2, Loader.LoadedModule>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_10:
    case Loader.LoadedModule{v_16, Ast.Module{_, v_18, v_19}}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_scoped_templates{v_16, v_18, v_6, v_3}}, False{}, v_1001976 => template_body_scoped_templates(v_16, v_18, v_6, v_3), v_1001975 => +v_1001968 = template_unbox(List<&2, TemplateDef>, v_1001975); template_continuation_272(v_1001968, v_19, v_11, v_3, v_6)}

def template_body_invalid_scoped_modules(v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{TemplateValue{None{}}}
    case +v_1003797 <> v_1003798:
      template_match_273(v_1003797, v_6, v_3, v_1003798)

def template_step_group_0(request: TemplateRequestGroup0) -> TemplateProgress<template_result_group_0(request)>:
  match request:
    case TemplateRequest_span_of{arg_0}: template_body_span_of(arg_0)
    case TemplateRequest_collect_templates{arg_0}: template_body_collect_templates(arg_0)
    case TemplateRequest_top_keys{arg_0}: template_body_top_keys(arg_0)
    case TemplateRequest_collect_template_decls{arg_0, arg_1, arg_2, arg_3}: template_body_collect_template_decls(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_collect_template_decl{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10}: template_body_collect_template_decl(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10)
    case TemplateRequest_has_template_binder{arg_0}: template_body_has_template_binder(arg_0)
    case TemplateRequest_qualify{arg_0, arg_1}: template_body_qualify(arg_0, arg_1)
    case TemplateRequest_qualify_match{arg_0, arg_1, arg_2}: template_body_qualify_match(arg_0, arg_1, arg_2)
    case TemplateRequest_find_template{arg_0, arg_1}: template_body_find_template(arg_0, arg_1)
    case TemplateRequest_find_template_match{arg_0, arg_1, arg_2, arg_3}: template_body_find_template_match(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_flatten_application{arg_0}: template_body_flatten_application(arg_0)
    case TemplateRequest_flatten_append{arg_0, arg_1, arg_2}: template_body_flatten_append(arg_0, arg_1, arg_2)
    case TemplateRequest_leading_template_count{arg_0}: template_body_leading_template_count(arg_0)
    case TemplateRequest_template_for_head{arg_0, arg_1}: template_body_template_for_head(arg_0, arg_1)
    case TemplateRequest_take_template_args{arg_0, arg_1}: template_body_take_template_args(arg_0, arg_1)
    case TemplateRequest_take_template_arg{arg_0, arg_1}: template_body_take_template_arg(arg_0, arg_1)
    case TemplateRequest_reapply_args{arg_0, arg_1, arg_2}: template_body_reapply_args(arg_0, arg_1, arg_2)
    case TemplateRequest_generated_local_key{arg_0, arg_1}: template_body_generated_local_key(arg_0, arg_1)
    case TemplateRequest_generated_local_key_for_identity{arg_0, arg_1}: template_body_generated_local_key_for_identity(arg_0, arg_1)
    case TemplateRequest_fresh_generated_key{arg_0, arg_1, arg_2}: template_body_fresh_generated_key(arg_0, arg_1, arg_2)
    case TemplateRequest_fresh_generated_key_match{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_fresh_generated_key_match(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_generated_candidate{arg_0, arg_1}: template_body_generated_candidate(arg_0, arg_1)
    case TemplateRequest_generated_canonical_key{arg_0, arg_1}: template_body_generated_canonical_key(arg_0, arg_1)
    case TemplateRequest_generated_key{arg_0, arg_1}: template_body_generated_key(arg_0, arg_1)
    case TemplateRequest_encode_string{arg_0}: template_body_encode_string(arg_0)
    case TemplateRequest_encode_quantity{arg_0}: template_body_encode_quantity(arg_0)
    case TemplateRequest_serialize_strings{arg_0}: template_body_serialize_strings(arg_0)
    case TemplateRequest_serialize_nats{arg_0}: template_body_serialize_nats(arg_0)
    case TemplateRequest_serialize_quantities{arg_0}: template_body_serialize_quantities(arg_0)
    case TemplateRequest_serialize_patterns{arg_0}: template_body_serialize_patterns(arg_0)
    case TemplateRequest_serialize_pattern{arg_0}: template_body_serialize_pattern(arg_0)
    case TemplateRequest_serialize_terms{arg_0}: template_body_serialize_terms(arg_0)
    case TemplateRequest_serialize_term{arg_0}: template_body_serialize_term(arg_0)
    case TemplateRequest_serialize_optional_quantity{arg_0}: template_body_serialize_optional_quantity(arg_0)
    case TemplateRequest_strip_namespace{arg_0, arg_1}: template_body_strip_namespace(arg_0, arg_1)
    case TemplateRequest_strip_namespace_match{arg_0, arg_1, arg_2}: template_body_strip_namespace_match(arg_0, arg_1, arg_2)
    case TemplateRequest_strip_namespace_prefix{arg_0, arg_1}: template_body_strip_namespace_prefix(arg_0, arg_1)
    case TemplateRequest_strip_namespace_prefix_match{arg_0, arg_1, arg_2}: template_body_strip_namespace_prefix_match(arg_0, arg_1, arg_2)
    case TemplateRequest_template_capture_names{arg_0}: template_body_template_capture_names(arg_0)
    case TemplateRequest_scoped_templates{arg_0, arg_1, arg_2, arg_3}: template_body_scoped_templates(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_templates_with_captures{arg_0, arg_1}: template_body_templates_with_captures(arg_0, arg_1)
    case TemplateRequest_scope_capture_names{arg_0, arg_1, arg_2}: template_body_scope_capture_names(arg_0, arg_1, arg_2)
    case TemplateRequest_capture_import_names{arg_0, arg_1, arg_2}: template_body_capture_import_names(arg_0, arg_1, arg_2)
    case TemplateRequest_capture_module_names{arg_0, arg_1, arg_2}: template_body_capture_module_names(arg_0, arg_1, arg_2)
    case TemplateRequest_capture_declaration_names{arg_0, arg_1, arg_2}: template_body_capture_declaration_names(arg_0, arg_1, arg_2)
    case TemplateRequest_capture_constructor_names{arg_0, arg_1, arg_2}: template_body_capture_constructor_names(arg_0, arg_1, arg_2)
    case TemplateRequest_capture_declared_name{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_capture_declared_name(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_capture_name{arg_0, arg_1, arg_2, arg_3}: template_body_capture_name(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_capture_key{arg_0, arg_1, arg_2}: template_body_capture_key(arg_0, arg_1, arg_2)
    case TemplateRequest_capture_strings{arg_0, arg_1}: template_body_capture_strings(arg_0, arg_1)
    case TemplateRequest_capture_patterns{arg_0, arg_1}: template_body_capture_patterns(arg_0, arg_1)
    case TemplateRequest_capture_pattern{arg_0, arg_1}: template_body_capture_pattern(arg_0, arg_1)
    case TemplateRequest_capture_terms{arg_0, arg_1}: template_body_capture_terms(arg_0, arg_1)
    case TemplateRequest_reference_key{arg_0}: template_body_reference_key(arg_0)
    case TemplateRequest_capture_string_names{arg_0, arg_1}: template_body_capture_string_names(arg_0, arg_1)
    case TemplateRequest_capture_term{arg_0, arg_1}: template_body_capture_term(arg_0, arg_1)
    case TemplateRequest_expand_term{arg_0, arg_1}: template_body_expand_term(arg_0, arg_1)
    case TemplateRequest_expand_stable_term{arg_0}: template_body_expand_stable_term(arg_0)
    case TemplateRequest_expand_stable_terms{arg_0}: template_body_expand_stable_terms(arg_0)
    case TemplateRequest_expand_stable_tail{arg_0, arg_1}: template_body_expand_stable_tail(arg_0, arg_1)
    case TemplateRequest_expand_constructor_stable{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_expand_constructor_stable(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_expand_application{arg_0, arg_1, arg_2, arg_3}: template_body_expand_application(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_expand_application_spine{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_expand_application_spine(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_expand_application_template{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_expand_application_template(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)

def template_step_group_1(request: TemplateRequestGroup1) -> TemplateProgress<template_result_group_1(request)>:
  match request:
    case TemplateRequest_template_arity{arg_0}: template_body_template_arity(arg_0)
    case TemplateRequest_expand_application_arguments{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_expand_application_arguments(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_specialize_head{arg_0, arg_1}: template_body_specialize_head(arg_0, arg_1)
    case TemplateRequest_drop_args{arg_0, arg_1}: template_body_drop_args(arg_0, arg_1)
    case TemplateRequest_specialize_definition{arg_0, arg_1, arg_2}: template_body_specialize_definition(arg_0, arg_1, arg_2)
    case TemplateRequest_specialize_definition_result{arg_0, arg_1, arg_2, arg_3}: template_body_specialize_definition_result(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_specialize_prefix{arg_0, arg_1, arg_2, arg_3}: template_body_specialize_prefix(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_binder_count{arg_0}: template_body_binder_count(arg_0)
    case TemplateRequest_substitute_binders{arg_0, arg_1, arg_2}: template_body_substitute_binders(arg_0, arg_1, arg_2)
    case TemplateRequest_substitute_optional{arg_0, arg_1, arg_2}: template_body_substitute_optional(arg_0, arg_1, arg_2)
    case TemplateRequest_substitute_body{arg_0, arg_1, arg_2}: template_body_substitute_body(arg_0, arg_1, arg_2)
    case TemplateRequest_expand_terms{arg_0, arg_1}: template_body_expand_terms(arg_0, arg_1)
    case TemplateRequest_strip_template_decls{arg_0, arg_1, arg_2, arg_3}: template_body_strip_template_decls(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_strip_template_definition{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10}: template_body_strip_template_definition(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10)
    case TemplateRequest_strip_canonical_template{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_strip_canonical_template(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_strip_instance_or_definition{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_strip_instance_or_definition(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_canonical_template_key{arg_0, arg_1}: template_body_canonical_template_key(arg_0, arg_1)
    case TemplateRequest_canonical_template_match{arg_0, arg_1, arg_2, arg_3}: template_body_canonical_template_match(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_generated_local_keys{arg_0, arg_1}: template_body_generated_local_keys(arg_0, arg_1)
    case TemplateRequest_generated_local_key_match{arg_0, arg_1, arg_2, arg_3}: template_body_generated_local_key_match(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_has_generated_local_key{arg_0, arg_1}: template_body_has_generated_local_key(arg_0, arg_1)
    case TemplateRequest_is_template_instance{arg_0, arg_1, arg_2}: template_body_is_template_instance(arg_0, arg_1, arg_2)
    case TemplateRequest_generated_identity_found{arg_0}: template_body_generated_identity_found(arg_0)
    case TemplateRequest_template_instances{arg_0, arg_1, arg_2, arg_3}: template_body_template_instances(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_template_instances_for_keys{arg_0, arg_1, arg_2}: template_body_template_instances_for_keys(arg_0, arg_1, arg_2)
    case TemplateRequest_template_instance_definition{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9}: template_body_template_instance_definition(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9)
    case TemplateRequest_expand_constructors{arg_0, arg_1}: template_body_expand_constructors(arg_0, arg_1)
    case TemplateRequest_expand_clauses{arg_0, arg_1}: template_body_expand_clauses(arg_0, arg_1)
    case TemplateRequest_expand_maybe{arg_0, arg_1}: template_body_expand_maybe(arg_0, arg_1)
    case TemplateRequest_expand_definition{arg_0, arg_1}: template_body_expand_definition(arg_0, arg_1)
    case TemplateRequest_expand_body{arg_0, arg_1}: template_body_expand_body(arg_0, arg_1)
    case TemplateRequest_expand_optional{arg_0, arg_1}: template_body_expand_optional(arg_0, arg_1)
    case TemplateRequest_expand_binders{arg_0, arg_1}: template_body_expand_binders(arg_0, arg_1)
    case TemplateRequest_collect_actual_term{arg_0, arg_1}: template_body_collect_actual_term(arg_0, arg_1)
    case TemplateRequest_collect_actual_application{arg_0, arg_1, arg_2}: template_body_collect_actual_application(arg_0, arg_1, arg_2)
    case TemplateRequest_collect_actual_prefix{arg_0, arg_1, arg_2}: template_body_collect_actual_prefix(arg_0, arg_1, arg_2)
    case TemplateRequest_head_key{arg_0}: template_body_head_key(arg_0)
    case TemplateRequest_wrapped_prefix{arg_0}: template_body_wrapped_prefix(arg_0)
    case TemplateRequest_wrapped_prefix_cons{arg_0, arg_1}: template_body_wrapped_prefix_cons(arg_0, arg_1)
    case TemplateRequest_collect_actual_terms{arg_0, arg_1}: template_body_collect_actual_terms(arg_0, arg_1)
    case TemplateRequest_first_actual{arg_0, arg_1}: template_body_first_actual(arg_0, arg_1)
    case TemplateRequest_collect_actual_declarations{arg_0, arg_1}: template_body_collect_actual_declarations(arg_0, arg_1)
    case TemplateRequest_collect_actual_definition{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_collect_actual_definition(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_collect_actual_body{arg_0, arg_1}: template_body_collect_actual_body(arg_0, arg_1)
    case TemplateRequest_collect_actual_modules{arg_0, arg_1}: template_body_collect_actual_modules(arg_0, arg_1)
    case TemplateRequest_collect_actual_module{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_collect_actual_module(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_actual_in_catalog{arg_0, arg_1, arg_2}: template_body_actual_in_catalog(arg_0, arg_1, arg_2)
    case TemplateRequest_actual_in_catalog_found{arg_0, arg_1, arg_2, arg_3}: template_body_actual_in_catalog_found(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_template_aliases_found{arg_0, arg_1, arg_2, arg_3}: template_body_template_aliases_found(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_template_local_alias{arg_0, arg_1, arg_2, arg_3}: template_body_template_local_alias(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_imported_alias_names{arg_0, arg_1, arg_2, arg_3}: template_body_imported_alias_names(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_imported_alias_match{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_imported_alias_match(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_actual_in_aliases{arg_0, arg_1}: template_body_actual_in_aliases(arg_0, arg_1)
    case TemplateRequest_actual_sites_for_key{arg_0, arg_1}: template_body_actual_sites_for_key(arg_0, arg_1)
    case TemplateRequest_expand_actual_values{arg_0, arg_1, arg_2}: template_body_expand_actual_values(arg_0, arg_1, arg_2)
    case TemplateRequest_collect_actual_binders{arg_0, arg_1}: template_body_collect_actual_binders(arg_0, arg_1)
    case TemplateRequest_collect_actual_optional{arg_0, arg_1}: template_body_collect_actual_optional(arg_0, arg_1)
    case TemplateRequest_collect_actual_constructors{arg_0, arg_1}: template_body_collect_actual_constructors(arg_0, arg_1)
    case TemplateRequest_collect_actual_clauses{arg_0, arg_1}: template_body_collect_actual_clauses(arg_0, arg_1)
    case TemplateRequest_collect_actual_maybe{arg_0, arg_1}: template_body_collect_actual_maybe(arg_0, arg_1)
    case TemplateRequest_has_string{arg_0, arg_1}: template_body_has_string(arg_0, arg_1)
    case TemplateRequest_has_string_match{arg_0, arg_1, arg_2, arg_3}: template_body_has_string_match(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_has_top_key{arg_0, arg_1}: template_body_has_top_key(arg_0, arg_1)
    case TemplateRequest_find_generated_identity{arg_0, arg_1}: template_body_find_generated_identity(arg_0, arg_1)

def template_step_group_2(request: TemplateRequestGroup2) -> TemplateProgress<template_result_group_2(request)>:
  match request:
    case TemplateRequest_find_generated_identity_match{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_find_generated_identity_match(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_template_span{arg_0}: template_body_template_span(arg_0)
    case TemplateRequest_generated_actuals{arg_0, arg_1, arg_2, arg_3}: template_body_generated_actuals(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_template_name{arg_0}: template_body_template_name(arg_0)
    case TemplateRequest_generated_actual_case{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9}: template_body_generated_actual_case(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9)
    case TemplateRequest_generated_identity_collision{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_generated_identity_collision(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_generated_actual_new{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9}: template_body_generated_actual_new(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9)
    case TemplateRequest_generated_actual_complete{arg_0, arg_1}: template_body_generated_actual_complete(arg_0, arg_1)
    case TemplateRequest_template_source_span_equal{arg_0, arg_1}: template_body_template_source_span_equal(arg_0, arg_1)
    case TemplateRequest_has_template_source_definition{arg_0, arg_1, arg_2}: template_body_has_template_source_definition(arg_0, arg_1, arg_2)
    case TemplateRequest_template_owned_by_module{arg_0, arg_1, arg_2, arg_3}: template_body_template_owned_by_module(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_generated_for_module{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_generated_for_module(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_generated_for_module_match{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9}: template_body_generated_for_module_match(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9)
    case TemplateRequest_generated_for_module_here{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_generated_for_module_here(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_generated_for_module_merge{arg_0, arg_1}: template_body_generated_for_module_merge(arg_0, arg_1)
    case TemplateRequest_generate_round{arg_0, arg_1, arg_2}: template_body_generate_round(arg_0, arg_1, arg_2)
    case TemplateRequest_generate_scoped_round{arg_0, arg_1, arg_2, arg_3}: template_body_generate_scoped_round(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_generate_round_loaded{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_generate_round_loaded(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_generate_round_merge{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6}: template_body_generate_round_merge(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6)
    case TemplateRequest_generate_until_stable{arg_0, arg_1, arg_2}: template_body_generate_until_stable(arg_0, arg_1, arg_2)
    case TemplateRequest_generate_until_result{arg_0, arg_1}: template_body_generate_until_result(arg_0, arg_1)
    case TemplateRequest_visible_templates{arg_0, arg_1, arg_2}: template_body_visible_templates(arg_0, arg_1, arg_2)
    case TemplateRequest_local_templates{arg_0, arg_1}: template_body_local_templates(arg_0, arg_1)
    case TemplateRequest_local_template_match{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_local_template_match(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_imported_templates{arg_0, arg_1, arg_2}: template_body_imported_templates(arg_0, arg_1, arg_2)
    case TemplateRequest_imported_from{arg_0, arg_1, arg_2}: template_body_imported_from(arg_0, arg_1, arg_2)
    case TemplateRequest_imported_from_match{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_imported_from_match(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)
    case TemplateRequest_expand_modules{arg_0, arg_1, arg_2}: template_body_expand_modules(arg_0, arg_1, arg_2)
    case TemplateRequest_expand_scoped_modules{arg_0, arg_1, arg_2, arg_3}: template_body_expand_scoped_modules(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_has_late_template_binder{arg_0, arg_1}: template_body_has_late_template_binder(arg_0, arg_1)
    case TemplateRequest_invalid_template_definitions{arg_0}: template_body_invalid_template_definitions(arg_0)
    case TemplateRequest_invalid_template_decls{arg_0}: template_body_invalid_template_decls(arg_0)
    case TemplateRequest_invalid_template_decl{arg_0, arg_1, arg_2, arg_3}: template_body_invalid_template_decl(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_invalid_application{arg_0, arg_1}: template_body_invalid_application(arg_0, arg_1)
    case TemplateRequest_invalid_reference{arg_0, arg_1}: template_body_invalid_reference(arg_0, arg_1)
    case TemplateRequest_invalid_application_spine{arg_0, arg_1, arg_2}: template_body_invalid_application_spine(arg_0, arg_1, arg_2)
    case TemplateRequest_invalid_application_head{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_invalid_application_head(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_invalid_application_arity{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_invalid_application_arity(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_invalid_application_arguments{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_invalid_application_arguments(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_invalid_application_parts{arg_0, arg_1}: template_body_invalid_application_parts(arg_0, arg_1)
    case TemplateRequest_invalid_template_args{arg_0, arg_1, arg_2, arg_3}: template_body_invalid_template_args(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_invalid_template_argument{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_invalid_template_argument(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_invalid_capture_context{arg_0, arg_1}: template_body_invalid_capture_context(arg_0, arg_1)
    case TemplateRequest_invalid_capture_key{arg_0, arg_1, arg_2, arg_3}: template_body_invalid_capture_key(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_invalid_capture_strings{arg_0, arg_1, arg_2}: template_body_invalid_capture_strings(arg_0, arg_1, arg_2)
    case TemplateRequest_invalid_capture_patterns{arg_0, arg_1}: template_body_invalid_capture_patterns(arg_0, arg_1)
    case TemplateRequest_invalid_capture_terms{arg_0, arg_1}: template_body_invalid_capture_terms(arg_0, arg_1)
    case TemplateRequest_invalid_capture_string_bit{arg_0, arg_1, arg_2, arg_3}: template_body_invalid_capture_string_bit(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_invalid_capture_string_word{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_invalid_capture_string_word(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_invalid_capture_string{arg_0, arg_1, arg_2, arg_3}: template_body_invalid_capture_string(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_invalid_capture{arg_0, arg_1}: template_body_invalid_capture(arg_0, arg_1)
    case TemplateRequest_has_open_vars{arg_0, arg_1}: template_body_has_open_vars(arg_0, arg_1)
    case TemplateRequest_has_open_vars_terms{arg_0, arg_1}: template_body_has_open_vars_terms(arg_0, arg_1)
    case TemplateRequest_invalid_terms{arg_0, arg_1}: template_body_invalid_terms(arg_0, arg_1)
    case TemplateRequest_first_invalid{arg_0, arg_1}: template_body_first_invalid(arg_0, arg_1)
    case TemplateRequest_invalid_definitions{arg_0, arg_1}: template_body_invalid_definitions(arg_0, arg_1)
    case TemplateRequest_invalid_definition{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5}: template_body_invalid_definition(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5)
    case TemplateRequest_invalid_def_body{arg_0, arg_1}: template_body_invalid_def_body(arg_0, arg_1)
    case TemplateRequest_invalid_optional{arg_0, arg_1}: template_body_invalid_optional(arg_0, arg_1)
    case TemplateRequest_invalid_binders{arg_0, arg_1}: template_body_invalid_binders(arg_0, arg_1)
    case TemplateRequest_invalid_constructors{arg_0, arg_1}: template_body_invalid_constructors(arg_0, arg_1)
    case TemplateRequest_invalid_clauses{arg_0, arg_1}: template_body_invalid_clauses(arg_0, arg_1)
    case TemplateRequest_invalid_maybe{arg_0, arg_1}: template_body_invalid_maybe(arg_0, arg_1)
    case TemplateRequest_expand{arg_0}: template_body_expand(arg_0)

def template_step_group_3(request: TemplateRequestGroup3) -> TemplateProgress<template_result_group_3(request)>:
  match request:
    case TemplateRequest_template_expand_templates{arg_0, arg_1, arg_2}: template_body_template_expand_templates(arg_0, arg_1, arg_2)
    case TemplateRequest_template_expand_modules{arg_0, arg_1, arg_2}: template_body_template_expand_modules(arg_0, arg_1, arg_2)
    case TemplateRequest_generated_declarations{arg_0}: template_body_generated_declarations(arg_0)
    case TemplateRequest_generated_modules{arg_0}: template_body_generated_modules(arg_0)
    case TemplateRequest_template_expand_round{arg_0, arg_1}: template_body_template_expand_round(arg_0, arg_1)
    case TemplateRequest_template_expand_generated{arg_0, arg_1, arg_2, arg_3}: template_body_template_expand_generated(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_invalid_modules{arg_0, arg_1}: template_body_invalid_modules(arg_0, arg_1)
    case TemplateRequest_invalid_scoped_modules{arg_0, arg_1, arg_2}: template_body_invalid_scoped_modules(arg_0, arg_1, arg_2)

def template_step_one(request: TemplateRequest) -> TemplateProgress<template_result(request)>:
  match request:
    case TemplateRequestGroup_0{inner}: template_step_group_0(inner)
    case TemplateRequestGroup_1{inner}: template_step_group_1(inner)
    case TemplateRequestGroup_2{inner}: template_step_group_2(inner)
    case TemplateRequestGroup_3{inner}: template_step_group_3(inner)

def template_chunk_state(-A: Type, -R: Type, fuel: Nat, progress: TemplateProgress<A>, stack: TemplateStack<A, R>) -> TemplateRun<R>:
  match fuel:
    case 0n: TemplateRunState{A, progress, stack}
    case 1n+rest:
      match progress:
        case TemplateFinished{box}:
          match stack:
            case TemplateStackDone{equation}: TemplateRunFinished{template_cast_box(A, R, equation, box)}
            case TemplateStackMore{B, resume, remainder}: template_chunk_state(B, R, rest, resume(box), remainder)
        case TemplatePending{request, resume}:
          template_chunk_state(template_result(request), R, rest, template_step_one(request), TemplateStackMore{A, resume, stack})
        case TemplateDirect{T, request, arguments, invoke, resume}:
          template_chunk_state(template_result(request), R, rest, invoke(arguments), TemplateStackMore{A, resume, stack})
        case TemplateBound{B, inner, resume}:
          template_chunk_state(B, R, rest, inner, TemplateStackMore{A, resume, stack})

def template_chunk(-R: Type, fuel: Nat, run: TemplateRun<R>) -> TemplateRun<R>:
  match run:
    case TemplateRunFinished{box}: TemplateRunFinished{box}
    case TemplateRunState{A, progress, stack}: template_chunk_state(A, R, fuel, progress, stack)

def template_step(-R: Type, run: TemplateRun<R>) -> TemplateRun<R>:
  template_chunk(R, 64n, run)

def template_start(modules: List<&2, Loader.LoadedModule>) -> TemplateRun<ExpandResult>:
  template_chunk(ExpandResult, 64n, TemplateRunState{ExpandResult, TemplatePending{TemplateRequestGroup_2{TemplateRequest_expand{modules}}, box => TemplateFinished{box}}, TemplateStackDone{{==}}})
