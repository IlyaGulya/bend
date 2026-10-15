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
  TemplateRequest_fresh_generated_key{v_1: String, v_4: List<&2, String>, v_6: Nat}
  TemplateRequest_fresh_generated_key_match{v_1: String, v_4: List<&2, String>, v_6: Nat, v_8: String, v_10: Bool}
  TemplateRequest_generated_candidate{v_1: String, v_3: Nat}
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
  TemplateRequest_template_arity{v_1: TemplateDef}
  TemplateRequest_expand_application_arguments{v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>, v_6: Ast.SyntaxTerm, v_8: List<&2, Ast.SyntaxTerm>, v_10: TemplateDef, v_12: Nat, v_15: Maybe<&2, List<&2, Ast.SyntaxTerm>>}

type TemplateRequestGroup1 is Type:
  TemplateRequest_specialize_head{v_0: Ast.SyntaxTerm, v_2: String}
  TemplateRequest_drop_args{v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat}
  TemplateRequest_specialize_definition{v_1: TemplateDef, v_3: List<&2, Ast.SyntaxTerm>}
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
  TemplateRequest_template_aliases{v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: String, v_8: List<&2, TemplateDef>}
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
  TemplateRequest_find_generated_identity_match{v_1: String, v_3: GeneratedIdentity, v_6: List<&2, GeneratedIdentity>, v_8: String, v_10: Bool}
  TemplateRequest_template_span{v_1: TemplateDef}

type TemplateRequestGroup2 is Type:
  TemplateRequest_generated_actuals{v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>}
  TemplateRequest_template_name{v_1: TemplateDef}
  TemplateRequest_generated_actual_case{v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>, v_14: String, v_16: String, v_18: String, v_20: String, v_22: List<&2, Ast.SyntaxTerm>, v_25: Maybe<&2, GeneratedIdentity>}
  TemplateRequest_generated_identity_collision{v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>, v_14: String, v_16: String, v_18: Bool}
  TemplateRequest_generated_actual_new{v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>, v_14: String, v_16: String, v_18: String, v_20: String, v_22: List<&2, Ast.SyntaxTerm>, v_24: Bool}
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
  TemplateRequest_template_expand_templates{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_6: Maybe<&2, Ast.SourceSpan>}
  TemplateRequest_template_expand_modules{v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_6: Maybe<&2, Ast.SourceSpan>}

type TemplateRequestGroup3 is Type:
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
    case TemplateRequest_fresh_generated_key{_, _, _}: String
    case TemplateRequest_fresh_generated_key_match{_, _, _, _, _}: String
    case TemplateRequest_generated_candidate{_, _}: String
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
    case TemplateRequest_template_arity{_}: Nat
    case TemplateRequest_expand_application_arguments{_, _, _, _, _, _, _, _, _}: Ast.SyntaxTerm

def template_result_group_1(request: TemplateRequestGroup1) -> Type:
  match request:
    case TemplateRequest_specialize_head{_, _}: Ast.SyntaxTerm
    case TemplateRequest_drop_args{_, _}: List<&2, Ast.SyntaxTerm>
    case TemplateRequest_specialize_definition{_, _}: Ast.Definition
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
    case TemplateRequest_template_aliases{_, _, _, _}: List<&2, String>
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
    case TemplateRequest_find_generated_identity_match{_, _, _, _, _}: Maybe<&2, GeneratedIdentity>
    case TemplateRequest_template_span{_}: Ast.SourceSpan

def template_result_group_2(request: TemplateRequestGroup2) -> Type:
  match request:
    case TemplateRequest_generated_actuals{_, _, _, _, _}: GeneratedBuild
    case TemplateRequest_template_name{_}: String
    case TemplateRequest_generated_actual_case{_, _, _, _, _, _, _, _, _, _, _}: GeneratedBuild
    case TemplateRequest_generated_identity_collision{_, _, _, _, _, _, _, _}: GeneratedBuild
    case TemplateRequest_generated_actual_new{_, _, _, _, _, _, _, _, _, _, _}: GeneratedBuild
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
    case TemplateRequest_template_expand_templates{_, _, _}: ExpandResult
    case TemplateRequest_template_expand_modules{_, _, _}: ExpandResult

def template_result_group_3(request: TemplateRequestGroup3) -> Type:
  match request:
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

def template_resume_type_group_0(-B: Type, request: TemplateRequestGroup0) -> Type:
  match request:
    case TemplateRequest_span_of{_}: (@+value: Ast.SourceSpan -> B)
    case TemplateRequest_collect_templates{_}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_top_keys{_}: (@+value: List<&2, String> -> B)
    case TemplateRequest_collect_template_decls{_, _, _, _}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_collect_template_decl{_, _, _, _, _, _, _, _, _, _, _}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_has_template_binder{_}: (@+value: Bool -> B)
    case TemplateRequest_qualify{_, _}: (@+value: String -> B)
    case TemplateRequest_qualify_match{_, _, _}: (@+value: String -> B)
    case TemplateRequest_find_template{_, _}: (@+value: Maybe<&2, TemplateDef> -> B)
    case TemplateRequest_find_template_match{_, _, _, _}: (@+value: Maybe<&2, TemplateDef> -> B)
    case TemplateRequest_flatten_application{_}: (@+value: ApplicationSpine -> B)
    case TemplateRequest_flatten_append{_, _, _}: (@+value: ApplicationSpine -> B)
    case TemplateRequest_leading_template_count{_}: (@+value: Nat -> B)
    case TemplateRequest_template_for_head{_, _}: (@+value: Maybe<&2, TemplateDef> -> B)
    case TemplateRequest_take_template_args{_, _}: (@+value: Maybe<&2, List<&2, Ast.SyntaxTerm>> -> B)
    case TemplateRequest_take_template_arg{_, _}: (@+value: Maybe<&2, List<&2, Ast.SyntaxTerm>> -> B)
    case TemplateRequest_reapply_args{_, _, _}: (@+value: Ast.SyntaxTerm -> B)
    case TemplateRequest_generated_local_key{_, _}: (@+value: String -> B)
    case TemplateRequest_fresh_generated_key{_, _, _}: (@+value: String -> B)
    case TemplateRequest_fresh_generated_key_match{_, _, _, _, _}: (@+value: String -> B)
    case TemplateRequest_generated_candidate{_, _}: (@+value: String -> B)
    case TemplateRequest_generated_key{_, _}: (@+value: String -> B)
    case TemplateRequest_encode_string{_}: (@+value: String -> B)
    case TemplateRequest_encode_quantity{_}: (@+value: String -> B)
    case TemplateRequest_serialize_strings{_}: (@+value: String -> B)
    case TemplateRequest_serialize_nats{_}: (@+value: String -> B)
    case TemplateRequest_serialize_quantities{_}: (@+value: String -> B)
    case TemplateRequest_serialize_patterns{_}: (@+value: String -> B)
    case TemplateRequest_serialize_pattern{_}: (@+value: String -> B)
    case TemplateRequest_serialize_terms{_}: (@+value: String -> B)
    case TemplateRequest_serialize_term{_}: (@+value: String -> B)
    case TemplateRequest_serialize_optional_quantity{_}: (@+value: String -> B)
    case TemplateRequest_strip_namespace{_, _}: (@+value: String -> B)
    case TemplateRequest_strip_namespace_match{_, _, _}: (@+value: String -> B)
    case TemplateRequest_strip_namespace_prefix{_, _}: (@+value: String -> B)
    case TemplateRequest_strip_namespace_prefix_match{_, _, _}: (@+value: String -> B)
    case TemplateRequest_template_capture_names{_}: (@+value: List<&2, CaptureName> -> B)
    case TemplateRequest_scoped_templates{_, _, _, _}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_templates_with_captures{_, _}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_scope_capture_names{_, _, _}: (@+value: List<&2, CaptureName> -> B)
    case TemplateRequest_capture_import_names{_, _, _}: (@+value: List<&2, CaptureName> -> B)
    case TemplateRequest_capture_module_names{_, _, _}: (@+value: List<&2, CaptureName> -> B)
    case TemplateRequest_capture_declaration_names{_, _, _}: (@+value: List<&2, CaptureName> -> B)
    case TemplateRequest_capture_constructor_names{_, _, _}: (@+value: List<&2, CaptureName> -> B)
    case TemplateRequest_capture_declared_name{_, _, _, _, _, _}: (@+value: List<&2, CaptureName> -> B)
    case TemplateRequest_capture_name{_, _, _, _}: (@+value: Maybe<&2, String> -> B)
    case TemplateRequest_capture_key{_, _, _}: (@+value: String -> B)
    case TemplateRequest_capture_strings{_, _}: (@+value: List<&2, String> -> B)
    case TemplateRequest_capture_patterns{_, _}: (@+value: List<&2, Ast.SyntaxPattern> -> B)
    case TemplateRequest_capture_pattern{_, _}: (@+value: Ast.SyntaxPattern -> B)
    case TemplateRequest_capture_terms{_, _}: (@+value: List<&2, Ast.SyntaxTerm> -> B)
    case TemplateRequest_reference_key{_}: (@+value: String -> B)
    case TemplateRequest_capture_string_names{_, _}: (@+value: Ast.StringLiteralNames -> B)
    case TemplateRequest_capture_term{_, _}: (@+value: Ast.SyntaxTerm -> B)
    case TemplateRequest_expand_term{_, _}: (@+value: Ast.SyntaxTerm -> B)
    case TemplateRequest_expand_stable_term{_}: (@+value: Bool -> B)
    case TemplateRequest_expand_stable_terms{_}: (@+value: Bool -> B)
    case TemplateRequest_expand_stable_tail{_, _}: (@+value: Bool -> B)
    case TemplateRequest_expand_constructor_stable{_, _, _, _, _, _}: (@+value: Ast.SyntaxTerm -> B)
    case TemplateRequest_expand_application{_, _, _, _}: (@+value: Ast.SyntaxTerm -> B)
    case TemplateRequest_expand_application_spine{_, _, _, _, _}: (@+value: Ast.SyntaxTerm -> B)
    case TemplateRequest_expand_application_template{_, _, _, _, _, _, _}: (@+value: Ast.SyntaxTerm -> B)
    case TemplateRequest_template_arity{_}: (@+value: Nat -> B)
    case TemplateRequest_expand_application_arguments{_, _, _, _, _, _, _, _, _}: (@+value: Ast.SyntaxTerm -> B)

def template_resume_type_group_1(-B: Type, request: TemplateRequestGroup1) -> Type:
  match request:
    case TemplateRequest_specialize_head{_, _}: (@+value: Ast.SyntaxTerm -> B)
    case TemplateRequest_drop_args{_, _}: (@+value: List<&2, Ast.SyntaxTerm> -> B)
    case TemplateRequest_specialize_definition{_, _}: (@+value: Ast.Definition -> B)
    case TemplateRequest_specialize_definition_result{_, _, _, _}: (@+value: Ast.Definition -> B)
    case TemplateRequest_specialize_prefix{_, _, _, _}: (@value: List<&2, Ast.TelescopeItem> & Ast.OptionalTerm & Ast.DefBody -> B)
    case TemplateRequest_binder_count{_}: (@+value: Nat -> B)
    case TemplateRequest_substitute_binders{_, _, _}: (@+value: List<&2, Ast.TelescopeItem> -> B)
    case TemplateRequest_substitute_optional{_, _, _}: (@+value: Ast.OptionalTerm -> B)
    case TemplateRequest_substitute_body{_, _, _}: (@+value: Ast.DefBody -> B)
    case TemplateRequest_expand_terms{_, _}: (@+value: List<&2, Ast.SyntaxTerm> -> B)
    case TemplateRequest_strip_template_decls{_, _, _, _}: (@+value: List<&2, Ast.TopLevel> -> B)
    case TemplateRequest_strip_template_definition{_, _, _, _, _, _, _, _, _, _, _}: (@+value: List<&2, Ast.TopLevel> -> B)
    case TemplateRequest_strip_canonical_template{_, _, _, _, _}: (@+value: List<&2, Ast.TopLevel> -> B)
    case TemplateRequest_strip_instance_or_definition{_, _, _, _, _, _, _}: (@+value: List<&2, Ast.TopLevel> -> B)
    case TemplateRequest_canonical_template_key{_, _}: (@+value: Maybe<&2, String> -> B)
    case TemplateRequest_canonical_template_match{_, _, _, _}: (@+value: Maybe<&2, String> -> B)
    case TemplateRequest_generated_local_keys{_, _}: (@+value: List<&2, String> -> B)
    case TemplateRequest_generated_local_key_match{_, _, _, _}: (@+value: List<&2, String> -> B)
    case TemplateRequest_has_generated_local_key{_, _}: (@+value: Bool -> B)
    case TemplateRequest_is_template_instance{_, _, _}: (@+value: Bool -> B)
    case TemplateRequest_generated_identity_found{_}: (@+value: Bool -> B)
    case TemplateRequest_template_instances{_, _, _, _}: (@+value: List<&2, Ast.TopLevel> -> B)
    case TemplateRequest_template_instances_for_keys{_, _, _}: (@+value: List<&2, Ast.TopLevel> -> B)
    case TemplateRequest_template_instance_definition{_, _, _, _, _, _, _, _, _, _}: (@+value: List<&2, Ast.TopLevel> -> B)
    case TemplateRequest_expand_constructors{_, _}: (@+value: List<&2, Ast.ConstructorDecl> -> B)
    case TemplateRequest_expand_clauses{_, _}: (@+value: List<&2, Ast.Clause> -> B)
    case TemplateRequest_expand_maybe{_, _}: (@+value: Maybe<&2, Ast.SyntaxTerm> -> B)
    case TemplateRequest_expand_definition{_, _}: (@+value: Ast.Definition -> B)
    case TemplateRequest_expand_body{_, _}: (@+value: Ast.DefBody -> B)
    case TemplateRequest_expand_optional{_, _}: (@+value: Ast.OptionalTerm -> B)
    case TemplateRequest_expand_binders{_, _}: (@+value: List<&2, Ast.TelescopeItem> -> B)
    case TemplateRequest_collect_actual_term{_, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_collect_actual_application{_, _, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_collect_actual_prefix{_, _, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_head_key{_}: (@+value: Maybe<&2, String> -> B)
    case TemplateRequest_wrapped_prefix{_}: (@+value: Maybe<&2, List<&2, Ast.SyntaxTerm>> -> B)
    case TemplateRequest_wrapped_prefix_cons{_, _}: (@+value: Maybe<&2, List<&2, Ast.SyntaxTerm>> -> B)
    case TemplateRequest_collect_actual_terms{_, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_first_actual{_, _}: (@+value: List<&2, List<&2, Ast.SyntaxTerm>> -> B)
    case TemplateRequest_collect_actual_declarations{_, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_collect_actual_definition{_, _, _, _, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_collect_actual_body{_, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_collect_actual_modules{_, _}: (@+value: List<&2, ActualModule> -> B)
    case TemplateRequest_collect_actual_module{_, _, _, _, _}: (@+value: List<&2, ActualModule> -> B)
    case TemplateRequest_actual_in_catalog{_, _, _}: (@+value: List<&2, List<&2, Ast.SyntaxTerm>> -> B)
    case TemplateRequest_template_aliases{_, _, _, _}: (@+value: List<&2, String> -> B)
    case TemplateRequest_template_aliases_found{_, _, _, _}: (@+value: List<&2, String> -> B)
    case TemplateRequest_template_local_alias{_, _, _, _}: (@+value: List<&2, String> -> B)
    case TemplateRequest_imported_alias_names{_, _, _, _}: (@+value: List<&2, String> -> B)
    case TemplateRequest_imported_alias_match{_, _, _, _, _, _}: (@+value: List<&2, String> -> B)
    case TemplateRequest_actual_in_aliases{_, _}: (@+value: List<&2, List<&2, Ast.SyntaxTerm>> -> B)
    case TemplateRequest_actual_sites_for_key{_, _}: (@+value: List<&2, List<&2, Ast.SyntaxTerm>> -> B)
    case TemplateRequest_expand_actual_values{_, _, _}: (@+value: List<&2, List<&2, Ast.SyntaxTerm>> -> B)
    case TemplateRequest_collect_actual_binders{_, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_collect_actual_optional{_, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_collect_actual_constructors{_, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_collect_actual_clauses{_, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_collect_actual_maybe{_, _}: (@+value: List<&2, ActualSite> -> B)
    case TemplateRequest_has_string{_, _}: (@+value: Bool -> B)
    case TemplateRequest_has_string_match{_, _, _, _}: (@+value: Bool -> B)
    case TemplateRequest_has_top_key{_, _}: (@+value: Bool -> B)
    case TemplateRequest_find_generated_identity{_, _}: (@+value: Maybe<&2, GeneratedIdentity> -> B)
    case TemplateRequest_find_generated_identity_match{_, _, _, _, _}: (@+value: Maybe<&2, GeneratedIdentity> -> B)
    case TemplateRequest_template_span{_}: (@+value: Ast.SourceSpan -> B)

def template_resume_type_group_2(-B: Type, request: TemplateRequestGroup2) -> Type:
  match request:
    case TemplateRequest_generated_actuals{_, _, _, _, _}: (@+value: GeneratedBuild -> B)
    case TemplateRequest_template_name{_}: (@+value: String -> B)
    case TemplateRequest_generated_actual_case{_, _, _, _, _, _, _, _, _, _, _}: (@+value: GeneratedBuild -> B)
    case TemplateRequest_generated_identity_collision{_, _, _, _, _, _, _, _}: (@+value: GeneratedBuild -> B)
    case TemplateRequest_generated_actual_new{_, _, _, _, _, _, _, _, _, _, _}: (@+value: GeneratedBuild -> B)
    case TemplateRequest_generated_actual_complete{_, _}: (@+value: GeneratedBuild -> B)
    case TemplateRequest_template_source_span_equal{_, _}: (@+value: Bool -> B)
    case TemplateRequest_has_template_source_definition{_, _, _}: (@+value: Bool -> B)
    case TemplateRequest_template_owned_by_module{_, _, _, _}: (@+value: Bool -> B)
    case TemplateRequest_generated_for_module{_, _, _, _, _, _}: (@+value: GeneratedBuild -> B)
    case TemplateRequest_generated_for_module_match{_, _, _, _, _, _, _, _, _, _}: (@+value: GeneratedBuild -> B)
    case TemplateRequest_generated_for_module_here{_, _, _, _, _, _, _, _}: (@+value: GeneratedBuild -> B)
    case TemplateRequest_generated_for_module_merge{_, _}: (@+value: GeneratedBuild -> B)
    case TemplateRequest_generate_round{_, _, _}: (@+value: GeneratedRound -> B)
    case TemplateRequest_generate_scoped_round{_, _, _, _}: (@+value: GeneratedRound -> B)
    case TemplateRequest_generate_round_loaded{_, _, _, _, _, _, _, _}: (@+value: GeneratedRound -> B)
    case TemplateRequest_generate_round_merge{_, _, _, _, _, _, _}: (@+value: GeneratedRound -> B)
    case TemplateRequest_generate_until_stable{_, _, _}: (@+value: GeneratedRound -> B)
    case TemplateRequest_generate_until_result{_, _}: (@+value: GeneratedRound -> B)
    case TemplateRequest_visible_templates{_, _, _}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_local_templates{_, _}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_local_template_match{_, _, _, _, _, _, _, _}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_imported_templates{_, _, _}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_imported_from{_, _, _}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_imported_from_match{_, _, _, _, _, _, _, _, _}: (@+value: List<&2, TemplateDef> -> B)
    case TemplateRequest_expand_modules{_, _, _}: (@+value: List<&2, Loader.LoadedModule> -> B)
    case TemplateRequest_expand_scoped_modules{_, _, _, _}: (@+value: List<&2, Loader.LoadedModule> -> B)
    case TemplateRequest_has_late_template_binder{_, _}: (@+value: Bool -> B)
    case TemplateRequest_invalid_template_definitions{_}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_template_decls{_}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_template_decl{_, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_application{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_reference{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_application_spine{_, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_application_head{_, _, _, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_application_arity{_, _, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_application_arguments{_, _, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_application_parts{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_template_args{_, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_template_argument{_, _, _, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_capture_context{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_capture_key{_, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_capture_strings{_, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_capture_patterns{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_capture_terms{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_capture_string_bit{_, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_capture_string_word{_, _, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_capture_string{_, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_capture{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_has_open_vars{_, _}: (@+value: Bool -> B)
    case TemplateRequest_has_open_vars_terms{_, _}: (@+value: Bool -> B)
    case TemplateRequest_invalid_terms{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_first_invalid{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_definitions{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_definition{_, _, _, _, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_def_body{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_optional{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_binders{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_constructors{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_clauses{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_maybe{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_expand{_}: (@+value: ExpandResult -> B)
    case TemplateRequest_template_expand_templates{_, _, _}: (@+value: ExpandResult -> B)
    case TemplateRequest_template_expand_modules{_, _, _}: (@+value: ExpandResult -> B)

def template_resume_type_group_3(-B: Type, request: TemplateRequestGroup3) -> Type:
  match request:
    case TemplateRequest_template_expand_round{_, _}: (@+value: ExpandResult -> B)
    case TemplateRequest_template_expand_generated{_, _, _, _}: (@+value: ExpandResult -> B)
    case TemplateRequest_invalid_modules{_, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)
    case TemplateRequest_invalid_scoped_modules{_, _, _}: (@+value: Maybe<&2, Ast.SourceSpan> -> B)

def template_resume_type(-B: Type, request: TemplateRequest) -> Type:
  match request:
    case TemplateRequestGroup_0{inner}: template_resume_type_group_0(B, inner)
    case TemplateRequestGroup_1{inner}: template_resume_type_group_1(B, inner)
    case TemplateRequestGroup_2{inner}: template_resume_type_group_2(B, inner)
    case TemplateRequestGroup_3{inner}: template_resume_type_group_3(B, inner)

type TemplateProgress<-A: Type> is Type:
  TemplateFinished{value: A}
  TemplatePending{request: TemplateRequest, resume: template_resume_type(TemplateProgress<A>, request)}
  TemplateDirect{-R: Type, -request: TemplateRequest, arguments: R, invoke: (@arguments: R -> TemplateProgress<template_result(request)>), resume: template_resume_type(TemplateProgress<A>, request)}

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
      TemplateFinished{v_6}
    case Ast.TermRef{_, v_10}:
      TemplateFinished{v_10}
    case Ast.TermBang{_, v_14}:
      TemplateFinished{v_14}
    case Ast.TermSub{_, _, _, v_22}:
      TemplateFinished{v_22}
    case Ast.TermLet{_, _, _, _, _, v_34}:
      TemplateFinished{v_34}
    case Ast.TermAnn{_, _, v_40}:
      TemplateFinished{v_40}
    case Ast.TermTemplate{_, v_44}:
      TemplateFinished{v_44}
    case Ast.TermType{_, v_48}:
      TemplateFinished{v_48}
    case Ast.TermQuantity{_, v_52}:
      TemplateFinished{v_52}
    case Ast.TermMin{_, _, v_58}:
      TemplateFinished{v_58}
    case Ast.TermAll{_, _, _, _, _, v_70}:
      TemplateFinished{v_70}
    case Ast.TermLam{_, _, _, _, v_80}:
      TemplateFinished{v_80}
    case Ast.TermApp{_, _, v_86}:
      TemplateFinished{v_86}
    case Ast.TermAdt{_, _, _, v_94}:
      TemplateFinished{v_94}
    case Ast.TermFill{_, _, v_100}:
      TemplateFinished{v_100}
    case Ast.TermPlus{_, _, v_106}:
      TemplateFinished{v_106}
    case Ast.TermCtr{_, _, v_112}:
      TemplateFinished{v_112}
    case Ast.TermString{_, _, v_118}:
      TemplateFinished{v_118}
    case Ast.TermMat{_, _, _, v_126}:
      TemplateFinished{v_126}
    case Ast.TermAbsurd{v_128}:
      TemplateFinished{v_128}
    case Ast.TermEqual{_, _, _, v_136}:
      TemplateFinished{v_136}
    case Ast.TermRefl{v_138}:
      TemplateFinished{v_138}
    case Ast.TermRewrite{_, _, _, v_146}:
      TemplateFinished{v_146}
    case Ast.TermHole{_, v_150}:
      TemplateFinished{v_150}
    case Ast.BodyMatch{_, _, v_156}:
      TemplateFinished{v_156}
    case Ast.BodyCase{_, _, v_162}:
      TemplateFinished{v_162}
    case Ast.BodyLocal{_, _, _, _, v_172}:
      TemplateFinished{v_172}
    case Ast.BodyReply{_, v_176}:
      TemplateFinished{v_176}
    case Ast.TermQuant{}:
      TemplateFinished{Ast.SpanOf{"", 0n, 0n}}

def template_match_5(+v_6: Loader.LoadedModule, v_7: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_6:
    case Loader.LoadedModule{v_12, Ast.Module{_, v_14, +v_15}}:
      v_1000000 = {v_12 : String}
      v_1000001 = {v_14 : List<&2, Ast.ModuleImport>}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_top_keys{v_15}}, +v_1000002 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_collect_template_decls{v_1000000, v_1000001, v_1000002, v_15}}, +v_1000003 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_collect_templates{v_7}}, +v_1000004 => TemplateFinished{List.append(&2, TemplateDef, v_1000003, v_1000004)}}}}

def template_body_collect_templates(v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_6 <> v_7:
      template_match_5(v_6, v_7)

def template_match_7(+v_6: Ast.TopLevel, v_7: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, String>>:
  match v_6:
    case Ast.DefTop{Ast.Definition{v_14, _, _, _, _, _}}:
      v_1000005 = {v_14 : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_top_keys{v_7}}, +v_1000006 => TemplateFinished{v_1000005 <> v_1000006}}
    case Ast.TypeTop{Ast.TypeDecl{v_26, _, _, _, _}}:
      v_1000007 = {v_26 : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_top_keys{v_7}}, +v_1000008 => TemplateFinished{v_1000007 <> v_1000008}}
    case Ast.LawTop{Ast.LawDecl{v_36, _, _, _}}:
      v_1000009 = {v_36 : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_top_keys{v_7}}, +v_1000010 => TemplateFinished{v_1000009 <> v_1000010}}

def template_body_top_keys(v_1: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, String>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_6 <> v_7:
      template_match_7(v_6, v_7)

def template_match_9(+v_13: Ast.TopLevel, v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, String>, v_14: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_13:
    case Ast.DefTop{Ast.Definition{v_21, +v_22, v_23, v_24, v_25, v_26}}:
      v_1000011 = {v_1 : String}
      v_1000012 = {v_3 : List<&2, Ast.ModuleImport>}
      v_1000013 = {v_6 : List<&2, String>}
      v_1000014 = {v_21 : String}
      v_1000015 = {v_22 : List<&2, Ast.TelescopeItem>}
      v_1000016 = {v_23 : Ast.OptionalTerm}
      v_1000017 = {v_24 : Ast.DefBody}
      v_1000018 = {v_25 : Bool}
      v_1000019 = {v_26 : Ast.SourceSpan}
      v_1000020 = {v_14 : List<&2, Ast.TopLevel>}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_has_template_binder{v_22}}, +v_1000021 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_collect_template_decl{v_1000011, v_1000012, v_1000013, v_1000014, v_1000015, v_1000016, v_1000017, v_1000018, v_1000019, v_1000020, v_1000021}}, +v_1000022 => TemplateFinished{v_1000022}}}
    case _:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_collect_template_decls{v_1, v_3, v_6, v_14}}, +v_1000023 => TemplateFinished{v_1000023}}

def template_match_10(v_8: List<&2, Ast.TopLevel>, v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, String>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_8:
    case []:
      TemplateFinished{[]}
    case +v_13 <> v_14:
      template_match_9(v_13, v_1, v_3, v_6, v_14)

def template_body_collect_template_decls(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, String>, v_8: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, TemplateDef>>:
  template_match_10(v_8, v_1, v_3, v_6)

def template_continuation_11(+v_1000024: String, v_8: String, v_10: List<&2, Ast.TelescopeItem>, v_11: Ast.OptionalTerm, v_12: Ast.DefBody, v_14: Bool, v_15: Ast.SourceSpan, +v_1: String, +v_3: List<&2, Ast.ModuleImport>, +v_6: List<&2, String>, v_17: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, TemplateDef>>:
  v_24 = v_1000024
  v_26 = {Ast.Definition{v_8, v_10, v_11, v_12, v_14, v_15} : Ast.Definition}
  v_1000025 = {TemplateDef{v_24, v_1, v_3, v_6, "", v_26, []} : TemplateDef}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_collect_template_decls{v_1, v_3, v_6, v_17}}, False{}, v_1000027 => template_body_collect_template_decls(v_1, v_3, v_6, v_17), +v_1000026 => TemplateFinished{v_1000025 <> v_1000026}}

def template_match_12(v_19: Bool, +v_1: String, +v_8: String, v_10: List<&2, Ast.TelescopeItem>, v_11: Ast.OptionalTerm, v_12: Ast.DefBody, v_14: Bool, v_15: Ast.SourceSpan, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, String>, v_17: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_19:
    case True{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_qualify{v_1, v_8}}, +v_1000024 => template_continuation_11(v_1000024, v_8, v_10, v_11, v_12, v_14, v_15, v_1, v_3, v_6, v_17)}
    case False{}:
      template_body_collect_template_decls(v_1, v_3, v_6, v_17)

def template_body_collect_template_decl(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, String>, v_8: String, v_10: List<&2, Ast.TelescopeItem>, v_11: Ast.OptionalTerm, v_12: Ast.DefBody, v_14: Bool, v_15: Ast.SourceSpan, v_17: List<&2, Ast.TopLevel>, v_19: Bool) -> TemplateProgress<List<&2, TemplateDef>>:
  template_match_12(v_19, v_1, v_8, v_10, v_11, v_12, v_14, v_15, v_3, v_6, v_17)

def template_match_13(+v_5: Ast.TelescopeItem, v_6: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Bool>:
  match v_5:
    case Ast.TemplateBinder{_, _, _, _}:
      TemplateFinished{True{}}
    case Ast.Binder{_, _, _, _, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_has_template_binder{v_6}}, +v_1000029 => TemplateFinished{v_1000029}}

def template_body_has_template_binder(v_1: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Bool>:
  match v_1:
    case []:
      TemplateFinished{False{}}
    case +v_5 <> v_6:
      template_match_13(v_5, v_6)

def template_body_qualify(+v_1: String, v_3: String) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_qualify_match{v_1, v_3, String.eq(v_1, "")}}, +v_1000030 => TemplateFinished{v_1000030}}

def template_match_15(v_5: Bool, v_3: String, v_1: String) -> TemplateProgress<String>:
  match v_5:
    case True{}:
      TemplateFinished{v_3}
    case False{}:
      TemplateFinished{String.append(v_1, String.append(".", v_3))}

def template_body_qualify_match(v_1: String, v_3: String, v_5: Bool) -> TemplateProgress<String>:
  template_match_15(v_5, v_3, v_1)

def template_match_16(+v_9: TemplateDef, +v_1: String, v_10: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, TemplateDef>>:
  match v_9:
    case TemplateDef{v_18, _, _, _, v_22, _, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_find_template_match{v_1, v_9, v_10, Bool.or(String.eq(v_18, v_1), String.eq(v_22, v_1))}}, +v_1000031 => TemplateFinished{v_1000031}}

def template_match_17(v_4: List<&2, TemplateDef>, v_1: String) -> TemplateProgress<Maybe<&2, TemplateDef>>:
  match v_4:
    case []:
      TemplateFinished{None{}}
    case +v_9 <> v_10:
      template_match_16(v_9, v_1, v_10)

def template_body_find_template(v_1: String, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, TemplateDef>>:
  template_match_17(v_4, v_1)

def template_match_18(v_8: Bool, v_3: TemplateDef, v_1: String, v_6: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, TemplateDef>>:
  match v_8:
    case True{}:
      TemplateFinished{Some{v_3}}
    case False{}:
      template_body_find_template(v_1, v_6)

def template_body_find_template_match(v_1: String, v_3: TemplateDef, v_6: List<&2, TemplateDef>, v_8: Bool) -> TemplateProgress<Maybe<&2, TemplateDef>>:
  template_match_18(v_8, v_3, v_1, v_6)

def template_match_19(+v_0: Ast.SyntaxTerm) -> TemplateProgress<ApplicationSpine>:
  match v_0:
    case Ast.TermApp{v_5, v_6, v_7}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_flatten_application{v_5}}, +v_1000033 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_flatten_append{v_1000033, v_6, v_7}}, +v_1000034 => TemplateFinished{v_1000034}}}
    case _:
      v_1000035 = {v_0 : Ast.SyntaxTerm}
      v_1000036 = {[] : List<&2, Ast.SyntaxTerm>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_span_of{v_0}}, False{}, v_1000038 => template_body_span_of(v_0), +v_1000037 => TemplateFinished{ApplicationSpine{v_1000035, v_1000036, v_1000037}}}

def template_body_flatten_application(v_0: Ast.SyntaxTerm) -> TemplateProgress<ApplicationSpine>:
  template_match_19(v_0)

def template_body_flatten_append(v_1: ApplicationSpine, v_2: Ast.SyntaxTerm, v_3: Ast.SourceSpan) -> TemplateProgress<ApplicationSpine>:
  match v_1:
    case ApplicationSpine{v_8, v_9, _}:
      TemplateFinished{ApplicationSpine{v_8, List.append(&2, Ast.SyntaxTerm, v_9, [v_2]), v_3}}

def template_body_leading_template_count(v_1: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Nat>:
  match v_1:
    case Ast.TemplateBinder{_, _, _, _} <> v_12:
      v_1000039 = {1n : Nat}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_leading_template_count{v_12}}, +v_1000040 => TemplateFinished{Nat.add(v_1000039, v_1000040)}}
    case _:
      TemplateFinished{0n}

def template_body_template_for_head(v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, TemplateDef>>:
  match v_0:
    case Ast.TermRef{v_8, _}:
      template_body_find_template(v_8, v_3)
    case Ast.TermBang{v_13, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_template_for_head{v_13, v_3}}, +v_1000042 => TemplateFinished{v_1000042}}
    case _:
      TemplateFinished{None{}}

def template_body_take_template_args(v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat) -> TemplateProgress<Maybe<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_1, v_3:
    case _, 0n:
      TemplateFinished{Some{[]}}
    case Ast.TermTemplate{v_12, _} <> v_14, 1n+v_15:
      v_1000043 = {v_12 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_take_template_args{v_14, v_15}}, +v_1000044 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_take_template_arg{v_1000043, v_1000044}}, +v_1000045 => TemplateFinished{v_1000045}}}
    case _, _:
      TemplateFinished{None{}}

def template_match_24(v_3: Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_0: Ast.SyntaxTerm) -> TemplateProgress<Maybe<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_3:
    case Some{v_7}:
      TemplateFinished{Some{v_0 <> v_7}}
    case None{}:
      TemplateFinished{None{}}

def template_body_take_template_arg(v_0: Ast.SyntaxTerm, v_3: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> TemplateProgress<Maybe<&2, List<&2, Ast.SyntaxTerm>>>:
  template_match_24(v_3, v_0)

def template_match_25(v_2: List<&2, Ast.SyntaxTerm>, v_0: Ast.SyntaxTerm, +v_3: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_2:
    case []:
      TemplateFinished{v_0}
    case +v_6 <> v_7:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_reapply_args{Ast.TermApp{v_0, v_6, v_3}, v_7, v_3}}, +v_1000046 => TemplateFinished{v_1000046}}

def template_body_reapply_args(v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>, v_3: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  template_match_25(v_2, v_0, v_3)

def template_continuation_26(+v_1000047: String, +v_1000048: String, v_15: List<&2, String>) -> TemplateProgress<String>:
  v_22 = String.append(v_1000047, v_1000048)
  v_24 = String.append("T~", SHA256.hash(v_22))
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_fresh_generated_key{v_24, v_15, 0n}}, +v_1000049 => TemplateFinished{v_1000049}}

def template_body_generated_local_key(v_1: TemplateDef, v_3: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<String>:
  match v_1:
    case TemplateDef{v_12, _, _, v_15, _, _, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_encode_string{v_12}}, +v_1000047 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_3}}, +v_1000048 => template_continuation_26(v_1000047, v_1000048, v_15)}}

def template_continuation_28(+v_1000050: String, v_1: String, +v_4: List<&2, String>, v_6: Nat) -> TemplateProgress<String>:
  +v_10 = v_1000050
  v_1000051 = {v_1 : String}
  v_1000052 = {v_4 : List<&2, String>}
  v_1000053 = {v_6 : Nat}
  v_1000054 = {v_10 : String}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_string{v_10, v_4}}, +v_1000055 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_fresh_generated_key_match{v_1000051, v_1000052, v_1000053, v_1000054, v_1000055}}, +v_1000056 => TemplateFinished{v_1000056}}}

def template_body_fresh_generated_key(+v_1: String, v_4: List<&2, String>, +v_6: Nat) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_generated_candidate{v_1, v_6}}, +v_1000050 => template_continuation_28(v_1000050, v_1, v_4, v_6)}

def template_match_29(v_10: Bool, v_1: String, v_4: List<&2, String>, v_6: Nat, v_8: String) -> TemplateProgress<String>:
  match v_10:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_fresh_generated_key{v_1, v_4, Nat.add(v_6, 1n)}}, False{}, v_1000058 => template_body_fresh_generated_key(v_1, v_4, Nat.add(v_6, 1n)), +v_1000057 => TemplateFinished{v_1000057}}
    case False{}:
      TemplateFinished{v_8}

def template_body_fresh_generated_key_match(v_1: String, v_4: List<&2, String>, v_6: Nat, v_8: String, v_10: Bool) -> TemplateProgress<String>:
  template_match_29(v_10, v_1, v_4, v_6, v_8)

def template_match_30(+v_3: Nat, v_1: String) -> TemplateProgress<String>:
  match v_3:
    case 0n:
      TemplateFinished{v_1}
    case _:
      TemplateFinished{String.append(v_1, String.append("~", Nat.show(v_3)))}

def template_body_generated_candidate(v_1: String, v_3: Nat) -> TemplateProgress<String>:
  template_match_30(v_3, v_1)

def template_match_31(+v_1: TemplateDef, v_3: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<String>:
  match v_1:
    case TemplateDef{_, v_13, _, _, _, _, _}:
      v_1000059 = {v_13 : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_generated_local_key{v_1, v_3}}, False{}, v_1000062 => template_body_generated_local_key(v_1, v_3), +v_1000060 => template_body_qualify(v_1000059, v_1000060)}

def template_body_generated_key(v_1: TemplateDef, v_3: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<String>:
  template_match_31(v_1, v_3)

def template_body_encode_string(+v_1: String) -> TemplateProgress<String>:
  TemplateFinished{String.append(Nat.show(String.length(v_1)), String.append(":", v_1))}

def template_body_encode_quantity(v_0: Ast.Quantity) -> TemplateProgress<String>:
  match v_0:
    case Ast.QZero{}:
      TemplateFinished{"0"}
    case Ast.QOne{}:
      TemplateFinished{"1"}
    case Ast.QMany{}:
      TemplateFinished{"m"}

def template_continuation_33(v_7: List<&2, String>, +v_1000063: String) -> TemplateProgress<String>:
  v_1000064 = {";" : String}
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_strings{v_7}}, +v_1000065 => TemplateFinished{String.append(v_1000063, String.append(v_1000064, v_1000065))}}

def template_body_serialize_strings(v_2: List<&2, String>) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{"]"}
    case +v_6 <> v_7:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_6}}, False{}, v_1000066 => template_body_encode_string(v_6), +v_1000063 => template_continuation_33(v_7, v_1000063)}

def template_body_serialize_nats(v_2: List<&2, Nat>) -> TemplateProgress<String>:
  match v_2:
    case []:
      TemplateFinished{"]"}
    case +v_6 <> v_7:
      v_1000067 = {Nat.show(v_6) : String}
      v_1000068 = {";" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_nats{v_7}}, +v_1000069 => TemplateFinished{String.append(v_1000067, String.append(v_1000068, v_1000069))}}

def template_continuation_36(v_6: List<&2, Ast.Quantity>, +v_1000070: String) -> TemplateProgress<String>:
  v_1000071 = {";" : String}
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_quantities{v_6}}, +v_1000072 => TemplateFinished{String.append(v_1000070, String.append(v_1000071, v_1000072))}}

def template_body_serialize_quantities(v_1: List<&2, Ast.Quantity>) -> TemplateProgress<String>:
  match v_1:
    case []:
      TemplateFinished{"]"}
    case +v_5 <> v_6:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_5}}, False{}, v_1000073 => template_body_encode_quantity(v_5), +v_1000070 => template_continuation_36(v_6, v_1000070)}

def template_continuation_38(v_6: List<&2, Ast.SyntaxPattern>, +v_1000074: String) -> TemplateProgress<String>:
  v_1000075 = {";" : String}
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_patterns{v_6}}, +v_1000076 => TemplateFinished{String.append(v_1000074, String.append(v_1000075, v_1000076))}}

def template_body_serialize_patterns(v_1: List<&2, Ast.SyntaxPattern>) -> TemplateProgress<String>:
  match v_1:
    case []:
      TemplateFinished{"]"}
    case +v_5 <> v_6:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_pattern{v_5}}, +v_1000074 => template_continuation_38(v_6, v_1000074)}

def template_body_serialize_pattern(v_0: Ast.SyntaxPattern) -> TemplateProgress<String>:
  match v_0:
    case Ast.PatternVar{_, v_7, v_8, _}:
      v_1000077 = {"v" : String}
      v_1000078 = {Nat.show(v_7) : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_8}}, False{}, v_1000080 => template_body_encode_quantity(v_8), +v_1000079 => TemplateFinished{String.append(v_1000077, String.append(v_1000078, String.append(v_1000079, ";")))}}
    case Ast.PatternCtr{v_14, v_15, _}:
      v_1000081 = {"c" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_14}}, False{}, v_1000085 => template_body_encode_string(v_14), +v_1000082 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_patterns{v_15}}, False{}, v_1000084 => template_body_serialize_patterns(v_15), +v_1000083 => TemplateFinished{String.append(v_1000081, String.append(v_1000082, v_1000083))}}}

def template_continuation_41(v_6: List<&2, Ast.SyntaxTerm>, +v_1000086: String) -> TemplateProgress<String>:
  v_1000087 = {";" : String}
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_6}}, +v_1000088 => TemplateFinished{String.append(v_1000086, String.append(v_1000087, v_1000088))}}

def template_body_serialize_terms(v_1: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<String>:
  match v_1:
    case []:
      TemplateFinished{"]"}
    case +v_5 <> v_6:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_5}}, +v_1000086 => template_continuation_41(v_6, v_1000086)}

def template_body_serialize_term(v_0: Ast.SyntaxTerm) -> TemplateProgress<String>:
  match v_0:
    case Ast.TermVar{_, v_6, _}:
      TemplateFinished{String.append("v", String.append(Nat.show(v_6), ";"))}
    case Ast.TermRef{v_10, _}:
      v_1000089 = {"r" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_10}}, False{}, v_1000091 => template_body_encode_string(v_10), +v_1000090 => TemplateFinished{String.append(v_1000089, v_1000090)}}
    case Ast.TermBang{v_15, _}:
      v_1000092 = {"!" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_15}}, +v_1000093 => TemplateFinished{String.append(v_1000092, v_1000093)}}
    case Ast.TermSub{v_22, v_23, v_24, _}:
      v_1000094 = {"s" : String}
      v_1000095 = {Nat.show(v_22) : String}
      v_1000096 = {";" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_23}}, +v_1000097 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_24}}, +v_1000098 => TemplateFinished{String.append(v_1000094, String.append(v_1000095, String.append(v_1000096, String.append(v_1000097, v_1000098))))}}}
    case Ast.TermLet{v_34, v_35, v_36, v_37, v_38, _}:
      v_1000099 = {"l" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_strings{v_34}}, False{}, v_1000108 => template_body_serialize_strings(v_34), +v_1000100 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_nats{v_35}}, False{}, v_1000107 => template_body_serialize_nats(v_35), +v_1000101 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_quantities{v_36}}, False{}, v_1000106 => template_body_serialize_quantities(v_36), +v_1000102 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_37}}, False{}, v_1000105 => template_body_serialize_terms(v_37), +v_1000103 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_38}}, +v_1000104 => TemplateFinished{String.append(v_1000099, String.append(v_1000100, String.append(v_1000101, String.append(v_1000102, String.append(v_1000103, v_1000104)))))}}}}}}
    case Ast.TermAnn{v_48, v_49, _}:
      v_1000109 = {"a" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_48}}, +v_1000110 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_49}}, +v_1000111 => TemplateFinished{String.append(v_1000109, String.append(v_1000110, v_1000111))}}}
    case Ast.TermTemplate{v_55, _}:
      v_1000112 = {"t" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_55}}, +v_1000113 => TemplateFinished{String.append(v_1000112, v_1000113)}}
    case Ast.TermType{v_60, _}:
      v_1000114 = {"T" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_60}}, +v_1000115 => TemplateFinished{String.append(v_1000114, v_1000115)}}
    case Ast.TermQuant{}:
      TemplateFinished{"q;"}
    case Ast.TermQuantity{v_65, _}:
      v_1000116 = {"Q" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_65}}, False{}, v_1000118 => template_body_encode_quantity(v_65), +v_1000117 => TemplateFinished{String.append(v_1000116, String.append(v_1000117, ";"))}}
    case Ast.TermMin{v_71, v_72, _}:
      v_1000119 = {"m" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_71}}, +v_1000120 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_72}}, +v_1000121 => TemplateFinished{String.append(v_1000119, String.append(v_1000120, v_1000121))}}}
    case Ast.TermAll{v_82, _, _, v_85, v_86, _}:
      v_1000122 = {"A" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_82}}, False{}, v_1000126 => template_body_encode_quantity(v_82), +v_1000123 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_85}}, +v_1000124 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_86}}, +v_1000125 => TemplateFinished{String.append(v_1000122, String.append(v_1000123, String.append(v_1000124, v_1000125)))}}}}
    case Ast.TermLam{v_96, _, _, v_99, _}:
      v_1000127 = {"L" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_optional_quantity{v_96}}, +v_1000128 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_99}}, +v_1000129 => TemplateFinished{String.append(v_1000127, String.append(v_1000128, v_1000129))}}}
    case Ast.TermApp{v_106, v_107, _}:
      v_1000130 = {"p" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_106}}, +v_1000131 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_107}}, +v_1000132 => TemplateFinished{String.append(v_1000130, String.append(v_1000131, v_1000132))}}}
    case Ast.TermAdt{v_115, v_116, v_117, _}:
      v_1000133 = {"d" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_115}}, False{}, v_1000139 => template_body_encode_string(v_115), +v_1000134 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_116}}, False{}, v_1000138 => template_body_serialize_terms(v_116), +v_1000135 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_strings{v_117}}, False{}, v_1000137 => template_body_serialize_strings(v_117), +v_1000136 => TemplateFinished{String.append(v_1000133, String.append(v_1000134, String.append(v_1000135, v_1000136)))}}}}
    case Ast.TermFill{v_125, v_126, _}:
      v_1000140 = {"f" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_125}}, +v_1000141 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_126}}, False{}, v_1000143 => template_body_serialize_terms(v_126), +v_1000142 => TemplateFinished{String.append(v_1000140, String.append(v_1000141, v_1000142))}}}
    case Ast.TermPlus{v_133, v_134, _}:
      v_1000144 = {"+" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_133}}, +v_1000145 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_134}}, False{}, v_1000147 => template_body_serialize_terms(v_134), +v_1000146 => TemplateFinished{String.append(v_1000144, String.append(v_1000145, v_1000146))}}}
    case Ast.TermCtr{v_141, v_142, _}:
      v_1000148 = {"c" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_141}}, False{}, v_1000152 => template_body_encode_string(v_141), +v_1000149 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_142}}, False{}, v_1000151 => template_body_serialize_terms(v_142), +v_1000150 => TemplateFinished{String.append(v_1000148, String.append(v_1000149, v_1000150))}}}
    case Ast.TermString{v_149, v_150, v_151}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{Ast.string_desugar(v_149, v_150, v_151)}}, +v_1000153 => TemplateFinished{v_1000153}}
    case Ast.TermMat{v_157, v_158, v_159, _}:
      v_1000154 = {"M" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_157}}, False{}, v_1000158 => template_body_encode_string(v_157), +v_1000155 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_158}}, +v_1000156 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_159}}, +v_1000157 => TemplateFinished{String.append(v_1000154, String.append(v_1000155, String.append(v_1000156, v_1000157)))}}}}
    case Ast.TermAbsurd{_}:
      TemplateFinished{"!"}
    case Ast.TermEqual{v_170, v_171, v_172, _}:
      v_1000159 = {"=" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_170}}, +v_1000160 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_171}}, +v_1000161 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_172}}, +v_1000162 => TemplateFinished{String.append(v_1000159, String.append(v_1000160, String.append(v_1000161, v_1000162)))}}}}
    case Ast.TermRefl{_}:
      TemplateFinished{"R"}
    case Ast.TermRewrite{v_183, v_184, v_185, _}:
      v_1000163 = {"w" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_183}}, +v_1000164 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_184}}, +v_1000165 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_185}}, +v_1000166 => TemplateFinished{String.append(v_1000163, String.append(v_1000164, String.append(v_1000165, v_1000166)))}}}}
    case Ast.TermHole{v_192, _}:
      v_1000167 = {"h" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_192}}, False{}, v_1000169 => template_body_encode_string(v_192), +v_1000168 => TemplateFinished{String.append(v_1000167, v_1000168)}}
    case Ast.BodyMatch{v_198, v_199, _}:
      v_1000170 = {"B" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_198}}, False{}, v_1000174 => template_body_serialize_terms(v_198), +v_1000171 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_199}}, False{}, v_1000173 => template_body_serialize_terms(v_199), +v_1000172 => TemplateFinished{String.append(v_1000170, String.append(v_1000171, v_1000172))}}}
    case Ast.BodyCase{v_206, v_207, _}:
      v_1000175 = {"C" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_patterns{v_206}}, False{}, v_1000178 => template_body_serialize_patterns(v_206), +v_1000176 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_207}}, +v_1000177 => TemplateFinished{String.append(v_1000175, String.append(v_1000176, v_1000177))}}}
    case Ast.BodyLocal{v_216, v_217, v_218, v_219, _}:
      v_1000179 = {"D" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_patterns{v_216}}, False{}, v_1000186 => template_body_serialize_patterns(v_216), +v_1000180 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_217}}, False{}, v_1000185 => template_body_encode_quantity(v_217), +v_1000181 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_218}}, False{}, v_1000184 => template_body_serialize_terms(v_218), +v_1000182 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_219}}, +v_1000183 => TemplateFinished{String.append(v_1000179, String.append(v_1000180, String.append(v_1000181, String.append(v_1000182, v_1000183))))}}}}}
    case Ast.BodyReply{v_227, _}:
      v_1000187 = {"Y" : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_serialize_term{v_227}}, +v_1000188 => TemplateFinished{String.append(v_1000187, v_1000188)}}

def template_body_serialize_optional_quantity(v_1: Maybe<&2, Ast.Quantity>) -> TemplateProgress<String>:
  match v_1:
    case None{}:
      TemplateFinished{"n"}
    case Some{v_3}:
      v_1000189 = {"s" : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_quantity{v_3}}, False{}, v_1000191 => template_body_encode_quantity(v_3), +v_1000190 => TemplateFinished{String.append(v_1000189, v_1000190)}}

def template_body_strip_namespace(v_1: String, +v_3: String) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_strip_namespace_match{v_1, v_3, String.eq(v_3, "")}}, +v_1000192 => TemplateFinished{v_1000192}}

def template_match_45(v_5: Bool, v_1: String, v_3: String) -> TemplateProgress<String>:
  match v_5:
    case True{}:
      TemplateFinished{v_1}
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_strip_namespace_prefix{v_1, String.append(v_3, ".")}}, +v_1000193 => TemplateFinished{v_1000193}}

def template_body_strip_namespace_match(v_1: String, v_3: String, v_5: Bool) -> TemplateProgress<String>:
  template_match_45(v_5, v_1, v_3)

def template_body_strip_namespace_prefix(+v_1: String, +v_3: String) -> TemplateProgress<String>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_strip_namespace_prefix_match{v_1, v_3, String.starts_with(v_1, v_3)}}, +v_1000194 => TemplateFinished{v_1000194}}

def template_match_46(v_5: Bool, v_1: String, v_3: String) -> TemplateProgress<String>:
  match v_5:
    case True{}:
      TemplateFinished{String.drop(v_1, String.length(v_3))}
    case False{}:
      TemplateFinished{v_1}

def template_body_strip_namespace_prefix_match(v_1: String, v_3: String, v_5: Bool) -> TemplateProgress<String>:
  template_match_46(v_5, v_1, v_3)

def template_body_template_capture_names(v_1: TemplateDef) -> TemplateProgress<List<&2, CaptureName>>:
  TemplateFinished{template_pure_template_capture_names(v_1)}

def template_match_47(+v_6: List<&2, TemplateDef>, +v_1: String, +v_3: List<&2, Ast.ModuleImport>, v_8: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_6:
    case []:
      TemplateFinished{[]}
    case +_ <> _:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_visible_templates{v_1, v_3, v_6}}, +v_1000195 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_scope_capture_names{v_1, v_3, v_8}}, +v_1000196 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_templates_with_captures{v_1000195, v_1000196}}, +v_1000197 => TemplateFinished{v_1000197}}}}

def template_body_scoped_templates(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, TemplateDef>, v_8: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, TemplateDef>>:
  template_match_47(v_6, v_1, v_3, v_8)

def template_match_48(v_2: List<&2, TemplateDef>, +v_5: List<&2, CaptureName>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_2:
    case []:
      TemplateFinished{[]}
    case TemplateDef{v_16, v_17, v_18, v_19, v_20, v_21, _} <> v_23:
      v_1000198 = {TemplateDef{v_16, v_17, v_18, v_19, v_20, v_21, v_5} : TemplateDef}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_templates_with_captures{v_23, v_5}}, +v_1000199 => TemplateFinished{v_1000198 <> v_1000199}}

def template_body_templates_with_captures(v_2: List<&2, TemplateDef>, v_5: List<&2, CaptureName>) -> TemplateProgress<List<&2, TemplateDef>>:
  template_match_48(v_2, v_5)

def template_continuation_49(+v_1000202: List<&2, CaptureName>, v_10: List<&2, CaptureName>, v_13: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  v_16 = v_1000202
  TemplateFinished{List.append(&2, CaptureName, v_10, List.append(&2, CaptureName, v_13, v_16))}

def template_continuation_50(+v_1000201: List<&2, CaptureName>, v_5: List<&2, Loader.LoadedModule>, v_10: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  v_13 = v_1000201
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_module_names{"", "Base", v_5}}, +v_1000202 => template_continuation_49(v_1000202, v_10, v_13)}

def template_continuation_51(+v_1000200: List<&2, CaptureName>, v_1: String, v_3: List<&2, Ast.ModuleImport>, +v_5: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, CaptureName>>:
  v_10 = v_1000200
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_import_names{v_1, v_3, v_5}}, +v_1000201 => template_continuation_50(v_1000201, v_5, v_10)}

def template_body_scope_capture_names(+v_1: String, v_3: List<&2, Ast.ModuleImport>, +v_5: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, CaptureName>>:
  TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_module_names{v_1, "", v_5}}, +v_1000200 => template_continuation_51(v_1000200, v_1, v_3, v_5)}

def template_match_52(v_3: List<&2, Ast.ModuleImport>, +v_1: String, +v_5: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_3:
    case []:
      TemplateFinished{[]}
    case Ast.ModuleImport{v_12, v_13, _} <> v_15:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_module_names{Path.namespace(v_1, v_12), v_13, v_5}}, +v_1000203 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_import_names{v_1, v_15, v_5}}, +v_1000204 => TemplateFinished{List.append(&2, CaptureName, v_1000203, v_1000204)}}}

def template_body_capture_import_names(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, CaptureName>>:
  template_match_52(v_3, v_1, v_5)

def template_match_53(v_1000205: Bool, +v_1: String, +v_3: String, v_17: List<&2, Loader.LoadedModule>, v_16: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_1000205:
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_module_names{v_1, v_3, v_17}}, +v_1000206 => TemplateFinished{v_1000206}}
    case True{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declaration_names{v_1, v_3, v_16}}, +v_1000207 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_module_names{v_1, v_3, v_17}}, +v_1000208 => TemplateFinished{List.append(&2, CaptureName, v_1000207, v_1000208)}}}

def template_match_54(v_5: List<&2, Loader.LoadedModule>, +v_1: String, v_3: String) -> TemplateProgress<List<&2, CaptureName>>:
  match v_5:
    case []:
      TemplateFinished{[]}
    case Loader.LoadedModule{v_13, Ast.Module{_, _, v_16}} <> v_17:
      v_1000205 = {String.eq(v_1, v_13) : Bool}
      template_match_53(v_1000205, v_1, v_3, v_17, v_16)

def template_body_capture_module_names(v_1: String, v_3: String, v_5: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, CaptureName>>:
  template_match_54(v_5, v_1, v_3)

def template_match_55(+v_10: Ast.TopLevel, +v_1: String, +v_3: String, v_14: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_10:
    case Ast.DefTop{Ast.Definition{v_21, _, _, _, _, _}}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declared_name{v_1, v_3, v_21, False{}, False{}, v_14}}, +v_1000210 => TemplateFinished{v_1000210}}
    case Ast.TypeTop{Ast.TypeDecl{v_33, _, _, v_36, _}}:
      v_1000211 = {v_1 : String}
      v_1000212 = {v_3 : String}
      v_1000213 = {v_33 : String}
      v_1000214 = {True{} : Bool}
      v_1000215 = {False{} : Bool}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_constructor_names{v_1, v_3, v_36}}, +v_1000216 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declared_name{v_1000211, v_1000212, v_1000213, v_1000214, v_1000215, List.append(&2, CaptureName, v_1000216, v_14)}}, +v_1000217 => TemplateFinished{v_1000217}}}
    case Ast.LawTop{Ast.LawDecl{v_45, _, _, _}}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declared_name{v_1, v_3, v_45, False{}, False{}, v_14}}, +v_1000218 => TemplateFinished{v_1000218}}

def template_continuation_56(+v_1000209: List<&2, CaptureName>, +v_10: Ast.TopLevel, v_1: String, v_3: String) -> TemplateProgress<List<&2, CaptureName>>:
  v_14 = v_1000209
  template_match_55(v_10, v_1, v_3, v_14)

def template_match_57(v_5: List<&2, Ast.TopLevel>, +v_1: String, +v_3: String) -> TemplateProgress<List<&2, CaptureName>>:
  match v_5:
    case []:
      TemplateFinished{[]}
    case +v_10 <> v_11:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declaration_names{v_1, v_3, v_11}}, +v_1000209 => template_continuation_56(v_1000209, v_10, v_1, v_3)}

def template_body_capture_declaration_names(v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<List<&2, CaptureName>>:
  template_match_57(v_5, v_1, v_3)

def template_match_58(v_5: List<&2, Ast.ConstructorDecl>, +v_1: String, +v_3: String) -> TemplateProgress<List<&2, CaptureName>>:
  match v_5:
    case []:
      TemplateFinished{[]}
    case Ast.Constructor{v_12, _, _} <> v_15:
      v_1000219 = {v_1 : String}
      v_1000220 = {v_3 : String}
      v_1000221 = {v_12 : String}
      v_1000222 = {False{} : Bool}
      v_1000223 = {True{} : Bool}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_constructor_names{v_1, v_3, v_15}}, +v_1000224 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_declared_name{v_1000219, v_1000220, v_1000221, v_1000222, v_1000223, v_1000224}}, +v_1000225 => TemplateFinished{v_1000225}}}

def template_body_capture_constructor_names(v_1: String, v_3: String, v_5: List<&2, Ast.ConstructorDecl>) -> TemplateProgress<List<&2, CaptureName>>:
  template_match_58(v_5, v_1, v_3)

def template_match_59(v_1000228: Bool, v_5: String, v_17: String, v_7: Bool, v_9: Bool, v_20: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  match v_1000228:
    case True{}:
      TemplateFinished{CaptureName{v_5, v_17, v_7, v_9} <> v_20}
    case False{}:
      TemplateFinished{v_20}

def template_continuation_60(+v_1000227: String, +v_17: String, +v_7: Bool, +v_9: Bool, v_12: List<&2, CaptureName>, v_3: String, v_5: String) -> TemplateProgress<List<&2, CaptureName>>:
  v_20 = {CaptureName{v_1000227, v_17, v_7, v_9} <> v_12 : List<&2, CaptureName>}
  v_1000228 = {String.eq(v_3, "Base") : Bool}
  template_match_59(v_1000228, v_5, v_17, v_7, v_9, v_20)

def template_continuation_61(+v_1000226: String, +v_3: String, +v_5: String, v_7: Bool, v_9: Bool, v_12: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  v_17 = v_1000226
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_qualify{v_3, v_5}}, False{}, v_1000229 => template_body_qualify(v_3, v_5), +v_1000227 => template_continuation_60(v_1000227, v_17, v_7, v_9, v_12, v_3, v_5)}

def template_body_capture_declared_name(v_1: String, v_3: String, +v_5: String, v_7: Bool, v_9: Bool, v_12: List<&2, CaptureName>) -> TemplateProgress<List<&2, CaptureName>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_qualify{v_1, v_5}}, False{}, v_1000230 => template_body_qualify(v_1, v_5), +v_1000226 => template_continuation_61(v_1000226, v_3, v_5, v_7, v_9, v_12)}

def template_match_62(v_20: Bool, v_18: String, v_1: String, v_3: Bool, v_21: List<&2, CaptureName>, v_9: Maybe<&2, String>) -> TemplateProgress<Maybe<&2, String>>:
  match v_20:
    case True{}:
      TemplateFinished{Some{v_18}}
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_21, v_9}}, +v_1000233 => TemplateFinished{v_1000233}}

def template_match_63(+v_9: Maybe<&2, String>, v_1: String, v_3: Bool, v_21: List<&2, CaptureName>, v_18: String) -> TemplateProgress<Maybe<&2, String>>:
  match v_9:
    case Some{_}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_21, v_9}}, +v_1000234 => TemplateFinished{v_1000234}}
    case None{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_21, Some{v_18}}}, +v_1000235 => TemplateFinished{v_1000235}}

def template_match_64(v_19: Bool, v_18: String, v_9: Maybe<&2, String>, v_1: String, v_3: Bool, v_21: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, String>>:
  match v_19:
    case True{}:
      TemplateFinished{Some{v_18}}
    case False{}:
      template_match_63(v_9, v_1, v_3, v_21, v_18)

def template_match_65(+v_3: Bool, v_20: Bool, v_18: String, v_1: String, v_21: List<&2, CaptureName>, v_9: Maybe<&2, String>, v_19: Bool) -> TemplateProgress<Maybe<&2, String>>:
  match v_3:
    case True{}:
      template_match_62(v_20, v_18, v_1, v_3, v_21, v_9)
    case False{}:
      template_match_64(v_19, v_18, v_9, v_1, v_3, v_21)

def template_match_66(v_1000231: Bool, v_1: String, v_3: Bool, v_21: List<&2, CaptureName>, v_9: Maybe<&2, String>, v_20: Bool, v_18: String, v_19: Bool) -> TemplateProgress<Maybe<&2, String>>:
  match v_1000231:
    case False{}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_21, v_9}}, +v_1000232 => TemplateFinished{v_1000232}}
    case True{}:
      template_match_65(v_3, v_20, v_18, v_1, v_21, v_9, v_19)

def template_match_67(v_6: List<&2, CaptureName>, v_9: Maybe<&2, String>, +v_1: String, v_3: Bool) -> TemplateProgress<Maybe<&2, String>>:
  match v_6:
    case []:
      TemplateFinished{v_9}
    case CaptureName{v_17, +v_18, v_19, v_20} <> v_21:
      v_1000231 = {Bool.or(String.eq(v_1, v_17), String.eq(v_1, v_18)) : Bool}
      template_match_66(v_1000231, v_1, v_3, v_21, v_9, v_20, v_18, v_19)

def template_body_capture_name(v_1: String, v_3: Bool, v_6: List<&2, CaptureName>, v_9: Maybe<&2, String>) -> TemplateProgress<Maybe<&2, String>>:
  template_match_67(v_6, v_9, v_1, v_3)

def template_match_68(+v_1000236: Maybe<&2, String>, v_1: String) -> TemplateProgress<String>:
  match v_1000236:
    case None{}:
      TemplateFinished{v_1}
    case Some{v_10}:
      TemplateFinished{v_10}

def template_body_capture_key(+v_1: String, v_3: Bool, v_6: List<&2, CaptureName>) -> TemplateProgress<String>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_6, None{}}}, False{}, v_1000237 => template_body_capture_name(v_1, v_3, v_6, None{}), +v_1000236 => template_match_68(v_1000236, v_1)}

def template_match_69(v_2: List<&2, String>, +v_5: List<&2, CaptureName>) -> TemplateProgress<List<&2, String>>:
  match v_2:
    case []:
      TemplateFinished{[]}
    case +v_10 <> v_11:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_10, True{}, v_5}}, False{}, v_1000240 => template_body_capture_key(v_10, True{}, v_5), +v_1000238 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_strings{v_11, v_5}}, +v_1000239 => TemplateFinished{v_1000238 <> v_1000239}}}

def template_body_capture_strings(v_2: List<&2, String>, v_5: List<&2, CaptureName>) -> TemplateProgress<List<&2, String>>:
  template_match_69(v_2, v_5)

def template_match_70(v_1: List<&2, Ast.SyntaxPattern>, +v_4: List<&2, CaptureName>) -> TemplateProgress<List<&2, Ast.SyntaxPattern>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_8 <> v_9:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_pattern{v_8, v_4}}, +v_1000241 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_patterns{v_9, v_4}}, +v_1000242 => TemplateFinished{v_1000241 <> v_1000242}}}

def template_body_capture_patterns(v_1: List<&2, Ast.SyntaxPattern>, v_4: List<&2, CaptureName>) -> TemplateProgress<List<&2, Ast.SyntaxPattern>>:
  template_match_70(v_1, v_4)

def template_match_71(+v_0: Ast.SyntaxPattern, +v_3: List<&2, CaptureName>) -> TemplateProgress<Ast.SyntaxPattern>:
  match v_0:
    case Ast.PatternVar{_, _, _, _}:
      TemplateFinished{v_0}
    case Ast.PatternCtr{v_15, v_16, v_17}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_15, True{}, v_3}}, False{}, v_1000246 => template_body_capture_key(v_15, True{}, v_3), +v_1000243 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_patterns{v_16, v_3}}, False{}, v_1000245 => template_body_capture_patterns(v_16, v_3), +v_1000244 => TemplateFinished{Ast.PatternCtr{v_1000243, v_1000244, v_17}}}}

def template_body_capture_pattern(v_0: Ast.SyntaxPattern, v_3: List<&2, CaptureName>) -> TemplateProgress<Ast.SyntaxPattern>:
  template_match_71(v_0, v_3)

def template_match_72(v_1: List<&2, Ast.SyntaxTerm>, +v_4: List<&2, CaptureName>) -> TemplateProgress<List<&2, Ast.SyntaxTerm>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_8 <> v_9:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_8, v_4}}, +v_1000247 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_terms{v_9, v_4}}, +v_1000248 => TemplateFinished{v_1000247 <> v_1000248}}}

def template_body_capture_terms(v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, CaptureName>) -> TemplateProgress<List<&2, Ast.SyntaxTerm>>:
  template_match_72(v_1, v_4)

def template_match_73(v_1000250: Bool, v_1: String) -> TemplateProgress<String>:
  match v_1000250:
    case True{}:
      TemplateFinished{v_1}
    case False{}:
      TemplateFinished{String.append("Nat", v_1)}

def template_match_74(v_1000249: Bool, +v_1: String) -> TemplateProgress<String>:
  match v_1000249:
    case False{}:
      TemplateFinished{v_1}
    case True{}:
      v_1000250 = {String.starts_with(v_1, "..") : Bool}
      template_match_73(v_1000250, v_1)

def template_body_reference_key(+v_1: String) -> TemplateProgress<String>:
  v_1000249 = {String.starts_with(v_1, ".") : Bool}
  template_match_74(v_1000249, v_1)

def template_body_capture_string_names(v_0: Ast.StringLiteralNames, +v_3: List<&2, CaptureName>) -> TemplateProgress<Ast.StringLiteralNames>:
  match v_0:
    case Ast.StringLiteralNames{v_12, v_13, v_14, v_15, v_16, v_17, v_18, v_19}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_12, True{}, v_3}}, False{}, v_1000266 => template_body_capture_key(v_12, True{}, v_3), +v_1000251 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_13, True{}, v_3}}, False{}, v_1000265 => template_body_capture_key(v_13, True{}, v_3), +v_1000252 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_14, True{}, v_3}}, False{}, v_1000264 => template_body_capture_key(v_14, True{}, v_3), +v_1000253 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_15, True{}, v_3}}, False{}, v_1000263 => template_body_capture_key(v_15, True{}, v_3), +v_1000254 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_16, True{}, v_3}}, False{}, v_1000262 => template_body_capture_key(v_16, True{}, v_3), +v_1000255 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_17, True{}, v_3}}, False{}, v_1000261 => template_body_capture_key(v_17, True{}, v_3), +v_1000256 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_18, True{}, v_3}}, False{}, v_1000260 => template_body_capture_key(v_18, True{}, v_3), +v_1000257 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_19, True{}, v_3}}, False{}, v_1000259 => template_body_capture_key(v_19, True{}, v_3), +v_1000258 => TemplateFinished{Ast.StringLiteralNames{v_1000251, v_1000252, v_1000253, v_1000254, v_1000255, v_1000256, v_1000257, v_1000258}}}}}}}}}}

def template_continuation_76(v_213: Ast.Quantity, v_214: List<&2, Ast.SyntaxTerm>, +v_3: List<&2, CaptureName>, v_215: Ast.SyntaxTerm, +v_1000334: List<&2, Ast.SyntaxPattern>, v_216: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  v_1000335 = {v_213 : Ast.Quantity}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_214, v_3}}, False{}, v_1000338 => template_body_capture_terms(v_214, v_3), +v_1000336 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_215, v_3}}, +v_1000337 => TemplateFinished{Ast.BodyLocal{v_1000334, v_1000335, v_1000336, v_1000337, v_216}}}}

def template_match_77(+v_0: Ast.SyntaxTerm, +v_3: List<&2, CaptureName>) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_0:
    case Ast.TermVar{_, _, _}:
      TemplateFinished{v_0}
    case Ast.TermRef{v_12, v_13}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_reference_key{v_12}}, False{}, v_1000270 => template_body_reference_key(v_12), +v_1000267 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_1000267, False{}, v_3}}, False{}, v_1000269 => template_body_capture_key(v_1000267, False{}, v_3), +v_1000268 => TemplateFinished{Ast.TermRef{v_1000268, v_13}}}}
    case Ast.TermBang{v_18, v_19}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_18, v_3}}, +v_1000271 => TemplateFinished{Ast.TermBang{v_1000271, v_19}}}
    case Ast.TermSub{v_25, v_26, v_27, v_28}:
      v_1000272 = {v_25 : Nat}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_26, v_3}}, +v_1000273 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_27, v_3}}, +v_1000274 => TemplateFinished{Ast.TermSub{v_1000272, v_1000273, v_1000274, v_28}}}}
    case Ast.TermLet{v_37, v_38, v_39, v_40, v_41, v_42}:
      v_1000275 = {v_37 : List<&2, String>}
      v_1000276 = {v_38 : List<&2, Nat>}
      v_1000277 = {v_39 : List<&2, Ast.Quantity>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_40, v_3}}, False{}, v_1000280 => template_body_capture_terms(v_40, v_3), +v_1000278 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_41, v_3}}, +v_1000279 => TemplateFinished{Ast.TermLet{v_1000275, v_1000276, v_1000277, v_1000278, v_1000279, v_42}}}}
    case Ast.TermAnn{v_48, v_49, v_50}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_48, v_3}}, +v_1000281 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_49, v_3}}, +v_1000282 => TemplateFinished{Ast.TermAnn{v_1000281, v_1000282, v_50}}}}
    case Ast.TermTemplate{v_55, v_56}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_55, v_3}}, +v_1000283 => TemplateFinished{Ast.TermTemplate{v_1000283, v_56}}}
    case Ast.TermType{v_60, v_61}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_60, v_3}}, +v_1000284 => TemplateFinished{Ast.TermType{v_1000284, v_61}}}
    case Ast.TermQuant{}:
      TemplateFinished{v_0}
    case Ast.TermQuantity{_, _}:
      TemplateFinished{v_0}
    case Ast.TermMin{v_70, v_71, v_72}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_70, v_3}}, +v_1000285 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_71, v_3}}, +v_1000286 => TemplateFinished{Ast.TermMin{v_1000285, v_1000286, v_72}}}}
    case Ast.TermAll{v_81, v_82, v_83, v_84, v_85, v_86}:
      v_1000287 = {v_81 : Ast.Quantity}
      v_1000288 = {v_82 : String}
      v_1000289 = {v_83 : Nat}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_84, v_3}}, +v_1000290 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_85, v_3}}, +v_1000291 => TemplateFinished{Ast.TermAll{v_1000287, v_1000288, v_1000289, v_1000290, v_1000291, v_86}}}}
    case Ast.TermLam{v_94, v_95, v_96, v_97, v_98}:
      v_1000292 = {v_94 : Maybe<&2, Ast.Quantity>}
      v_1000293 = {v_95 : String}
      v_1000294 = {v_96 : Nat}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_97, v_3}}, +v_1000295 => TemplateFinished{Ast.TermLam{v_1000292, v_1000293, v_1000294, v_1000295, v_98}}}
    case Ast.TermApp{v_103, v_104, v_105}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_103, v_3}}, +v_1000296 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_104, v_3}}, +v_1000297 => TemplateFinished{Ast.TermApp{v_1000296, v_1000297, v_105}}}}
    case Ast.TermAdt{v_112, v_113, v_114, v_115}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_112, False{}, v_3}}, False{}, v_1000303 => template_body_capture_key(v_112, False{}, v_3), +v_1000298 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_113, v_3}}, False{}, v_1000302 => template_body_capture_terms(v_113, v_3), +v_1000299 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_strings{v_114, v_3}}, False{}, v_1000301 => template_body_capture_strings(v_114, v_3), +v_1000300 => TemplateFinished{Ast.TermAdt{v_1000298, v_1000299, v_1000300, v_115}}}}}
    case Ast.TermFill{v_122, v_123, v_124}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_122, v_3}}, +v_1000304 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_123, v_3}}, False{}, v_1000306 => template_body_capture_terms(v_123, v_3), +v_1000305 => TemplateFinished{Ast.TermFill{v_1000304, v_1000305, v_124}}}}
    case Ast.TermPlus{v_130, v_131, v_132}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_130, v_3}}, +v_1000307 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_131, v_3}}, False{}, v_1000309 => template_body_capture_terms(v_131, v_3), +v_1000308 => TemplateFinished{Ast.TermPlus{v_1000307, v_1000308, v_132}}}}
    case Ast.TermCtr{v_138, v_139, v_140}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_138, True{}, v_3}}, False{}, v_1000313 => template_body_capture_key(v_138, True{}, v_3), +v_1000310 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_139, v_3}}, False{}, v_1000312 => template_body_capture_terms(v_139, v_3), +v_1000311 => TemplateFinished{Ast.TermCtr{v_1000310, v_1000311, v_140}}}}
    case Ast.TermString{v_146, v_147, v_148}:
      v_1000314 = {v_146 : List<&2, U32>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_string_names{v_147, v_3}}, False{}, v_1000316 => template_body_capture_string_names(v_147, v_3), +v_1000315 => TemplateFinished{Ast.TermString{v_1000314, v_1000315, v_148}}}
    case Ast.TermMat{v_154, v_155, v_156, v_157}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_key{v_154, True{}, v_3}}, False{}, v_1000320 => template_body_capture_key(v_154, True{}, v_3), +v_1000317 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_155, v_3}}, +v_1000318 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_156, v_3}}, +v_1000319 => TemplateFinished{Ast.TermMat{v_1000317, v_1000318, v_1000319, v_157}}}}}
    case Ast.TermAbsurd{_}:
      TemplateFinished{v_0}
    case Ast.TermEqual{v_167, v_168, v_169, v_170}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_167, v_3}}, +v_1000321 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_168, v_3}}, +v_1000322 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_169, v_3}}, +v_1000323 => TemplateFinished{Ast.TermEqual{v_1000321, v_1000322, v_1000323, v_170}}}}}
    case Ast.TermRefl{_}:
      TemplateFinished{v_0}
    case Ast.TermRewrite{v_180, v_181, v_182, v_183}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_180, v_3}}, +v_1000324 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_181, v_3}}, +v_1000325 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_182, v_3}}, +v_1000326 => TemplateFinished{Ast.TermRewrite{v_1000324, v_1000325, v_1000326, v_183}}}}}
    case Ast.TermHole{_, _}:
      TemplateFinished{v_0}
    case Ast.BodyMatch{v_194, v_195, v_196}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_194, v_3}}, False{}, v_1000330 => template_body_capture_terms(v_194, v_3), +v_1000327 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_195, v_3}}, False{}, v_1000329 => template_body_capture_terms(v_195, v_3), +v_1000328 => TemplateFinished{Ast.BodyMatch{v_1000327, v_1000328, v_196}}}}
    case Ast.BodyCase{v_202, v_203, v_204}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_patterns{v_202, v_3}}, False{}, v_1000333 => template_body_capture_patterns(v_202, v_3), +v_1000331 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_203, v_3}}, +v_1000332 => TemplateFinished{Ast.BodyCase{v_1000331, v_1000332, v_204}}}}
    case Ast.BodyLocal{v_212, v_213, v_214, v_215, v_216}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_patterns{v_212, v_3}}, False{}, v_1000339 => template_body_capture_patterns(v_212, v_3), +v_1000334 => template_continuation_76(v_213, v_214, v_3, v_215, v_1000334, v_216)}
    case Ast.BodyReply{v_222, v_223}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_capture_term{v_222, v_3}}, +v_1000340 => TemplateFinished{Ast.BodyReply{v_1000340, v_223}}}

def template_body_capture_term(v_0: Ast.SyntaxTerm, v_3: List<&2, CaptureName>) -> TemplateProgress<Ast.SyntaxTerm>:
  template_match_77(v_0, v_3)

def template_match_78(+v_0: Ast.SyntaxTerm, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_0:
    case Ast.TermVar{v_7, v_8, v_9}:
      TemplateFinished{Ast.TermVar{v_7, v_8, v_9}}
    case Ast.TermRef{v_12, v_13}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_reference_key{v_12}}, False{}, v_1000342 => template_body_reference_key(v_12), +v_1000341 => TemplateFinished{Ast.TermRef{v_1000341, v_13}}}
    case Ast.TermBang{v_17, v_18}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_17, v_3}}, +v_1000343 => TemplateFinished{Ast.TermBang{v_1000343, v_18}}}
    case Ast.TermSub{v_24, v_25, v_26, v_27}:
      v_1000344 = {v_24 : Nat}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_25, v_3}}, +v_1000345 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_26, v_3}}, +v_1000346 => TemplateFinished{Ast.TermSub{v_1000344, v_1000345, v_1000346, v_27}}}}
    case Ast.TermLet{v_36, v_37, v_38, v_39, v_40, v_41}:
      v_1000347 = {v_36 : List<&2, String>}
      v_1000348 = {v_37 : List<&2, Nat>}
      v_1000349 = {v_38 : List<&2, Ast.Quantity>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_39, v_3}}, +v_1000350 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_40, v_3}}, +v_1000351 => TemplateFinished{Ast.TermLet{v_1000347, v_1000348, v_1000349, v_1000350, v_1000351, v_41}}}}
    case Ast.TermAnn{v_47, v_48, v_49}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_47, v_3}}, +v_1000352 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_48, v_3}}, +v_1000353 => TemplateFinished{Ast.TermAnn{v_1000352, v_1000353, v_49}}}}
    case Ast.TermTemplate{v_54, v_55}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_54, v_3}}, +v_1000354 => TemplateFinished{Ast.TermTemplate{v_1000354, v_55}}}
    case Ast.TermType{v_59, v_60}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_59, v_3}}, +v_1000355 => TemplateFinished{Ast.TermType{v_1000355, v_60}}}
    case Ast.TermQuant{}:
      TemplateFinished{v_0}
    case Ast.TermQuantity{v_64, v_65}:
      TemplateFinished{Ast.TermQuantity{v_64, v_65}}
    case Ast.TermMin{v_69, v_70, v_71}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_69, v_3}}, +v_1000356 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_70, v_3}}, +v_1000357 => TemplateFinished{Ast.TermMin{v_1000356, v_1000357, v_71}}}}
    case Ast.TermAll{v_80, v_81, v_82, v_83, v_84, v_85}:
      v_1000358 = {v_80 : Ast.Quantity}
      v_1000359 = {v_81 : String}
      v_1000360 = {v_82 : Nat}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_83, v_3}}, +v_1000361 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_84, v_3}}, +v_1000362 => TemplateFinished{Ast.TermAll{v_1000358, v_1000359, v_1000360, v_1000361, v_1000362, v_85}}}}
    case Ast.TermLam{v_93, v_94, v_95, v_96, v_97}:
      v_1000363 = {v_93 : Maybe<&2, Ast.Quantity>}
      v_1000364 = {v_94 : String}
      v_1000365 = {v_95 : Nat}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_96, v_3}}, +v_1000366 => TemplateFinished{Ast.TermLam{v_1000363, v_1000364, v_1000365, v_1000366, v_97}}}
    case Ast.TermApp{v_102, v_103, v_104}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_application{v_102, v_103, v_104, v_3}}, +v_1000367 => TemplateFinished{v_1000367}}
    case Ast.TermAdt{v_110, v_111, v_112, v_113}:
      v_1000368 = {v_110 : String}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_111, v_3}}, +v_1000369 => TemplateFinished{Ast.TermAdt{v_1000368, v_1000369, v_112, v_113}}}
    case Ast.TermFill{v_118, v_119, v_120}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_118, v_3}}, +v_1000370 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_119, v_3}}, +v_1000371 => TemplateFinished{Ast.TermFill{v_1000370, v_1000371, v_120}}}}
    case Ast.TermPlus{v_126, v_127, v_128}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_126, v_3}}, +v_1000372 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_127, v_3}}, +v_1000373 => TemplateFinished{Ast.TermPlus{v_1000372, v_1000373, v_128}}}}
    case Ast.TermCtr{v_134, +v_135, v_136}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_stable_terms{v_135}}, +v_1000374 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_constructor_stable{v_1000374, v_0, v_134, v_135, v_136, v_3}}, +v_1000375 => TemplateFinished{v_1000375}}}
    case Ast.TermString{_, _, _}:
      TemplateFinished{v_0}
    case Ast.TermMat{v_149, v_150, v_151, v_152}:
      v_1000376 = {v_149 : String}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_150, v_3}}, +v_1000377 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_151, v_3}}, +v_1000378 => TemplateFinished{Ast.TermMat{v_1000376, v_1000377, v_1000378, v_152}}}}
    case Ast.TermAbsurd{v_156}:
      TemplateFinished{v_0}
    case Ast.TermEqual{v_161, v_162, v_163, v_164}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_161, v_3}}, +v_1000379 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_162, v_3}}, +v_1000380 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_163, v_3}}, +v_1000381 => TemplateFinished{Ast.TermEqual{v_1000379, v_1000380, v_1000381, v_164}}}}}
    case Ast.TermRefl{v_169}:
      TemplateFinished{v_0}
    case Ast.TermRewrite{v_174, v_175, v_176, v_177}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_174, v_3}}, +v_1000382 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_175, v_3}}, +v_1000383 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_176, v_3}}, +v_1000384 => TemplateFinished{Ast.TermRewrite{v_1000382, v_1000383, v_1000384, v_177}}}}}
    case Ast.TermHole{v_183, v_184}:
      TemplateFinished{v_0}
    case Ast.BodyMatch{v_188, v_189, v_190}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_188, v_3}}, +v_1000385 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_189, v_3}}, +v_1000386 => TemplateFinished{Ast.BodyMatch{v_1000385, v_1000386, v_190}}}}
    case Ast.BodyCase{v_196, v_197, v_198}:
      v_1000387 = {v_196 : List<&2, Ast.SyntaxPattern>}
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_197, v_3}}, +v_1000388 => TemplateFinished{Ast.BodyCase{v_1000387, v_1000388, v_198}}}
    case Ast.BodyLocal{v_205, v_206, v_207, v_208, v_209}:
      v_1000389 = {v_205 : List<&2, Ast.SyntaxPattern>}
      v_1000390 = {v_206 : Ast.Quantity}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_207, v_3}}, +v_1000391 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_208, v_3}}, +v_1000392 => TemplateFinished{Ast.BodyLocal{v_1000389, v_1000390, v_1000391, v_1000392, v_209}}}}
    case Ast.BodyReply{v_214, v_215}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_term{v_214, v_3}}, +v_1000393 => TemplateFinished{Ast.BodyReply{v_1000393, v_215}}}

def template_body_expand_term(v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.SyntaxTerm>:
  template_match_78(v_0, v_3)

def template_body_expand_stable_term(v_0: Ast.SyntaxTerm) -> TemplateProgress<Bool>:
  match v_0:
    case Ast.TermVar{_, _, _}:
      TemplateFinished{True{}}
    case Ast.TermCtr{_, v_12, _}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_stable_terms{v_12}}, +v_1000394 => TemplateFinished{v_1000394}}
    case Ast.TermString{_, _, _}:
      TemplateFinished{True{}}
    case Ast.TermQuant{}:
      TemplateFinished{True{}}
    case Ast.TermQuantity{_, _}:
      TemplateFinished{True{}}
    case Ast.TermAbsurd{_}:
      TemplateFinished{True{}}
    case Ast.TermRefl{_}:
      TemplateFinished{True{}}
    case Ast.TermHole{_, _}:
      TemplateFinished{True{}}
    case _:
      TemplateFinished{False{}}

def template_body_expand_stable_terms(v_1: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Bool>:
  match v_1:
    case []:
      TemplateFinished{True{}}
    case v_5 <> v_6:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_stable_term{v_5}}, False{}, v_1000397 => template_body_expand_stable_term(v_5), +v_1000395 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_stable_tail{v_1000395, v_6}}, +v_1000396 => TemplateFinished{v_1000396}}}

def template_body_expand_stable_tail(v_1: Bool, v_3: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Bool>:
  match v_1:
    case True{}:
      template_body_expand_stable_terms(v_3)
    case False{}:
      TemplateFinished{False{}}

def template_match_82(v_1: Bool, v_2: Ast.SyntaxTerm, v_4: String, v_6: List<&2, Ast.SyntaxTerm>, v_10: List<&2, TemplateDef>, v_7: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_1:
    case True{}:
      TemplateFinished{v_2}
    case False{}:
      v_1000399 = {v_4 : String}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_6, v_10}}, +v_1000400 => TemplateFinished{Ast.TermCtr{v_1000399, v_1000400, v_7}}}

def template_body_expand_constructor_stable(v_1: Bool, v_2: Ast.SyntaxTerm, v_4: String, v_6: List<&2, Ast.SyntaxTerm>, v_7: Ast.SourceSpan, v_10: List<&2, TemplateDef>) -> TemplateProgress<Ast.SyntaxTerm>:
  template_match_82(v_1, v_2, v_4, v_6, v_10, v_7)

def template_body_expand_application(+v_0: Ast.SyntaxTerm, +v_1: Ast.SyntaxTerm, +v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>) -> TemplateProgress<Ast.SyntaxTerm>:
  v_7 = {Ast.TermApp{v_0, v_1, v_2} : Ast.SyntaxTerm}
  v_1000401 = {v_0 : Ast.SyntaxTerm}
  v_1000402 = {v_1 : Ast.SyntaxTerm}
  v_1000403 = {v_2 : Ast.SourceSpan}
  v_1000404 = {v_5 : List<&2, TemplateDef>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_flatten_application{v_7}}, False{}, v_1000407 => template_body_flatten_application(v_7), +v_1000405 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_application_spine{v_1000401, v_1000402, v_1000403, v_1000404, v_1000405}}, +v_1000406 => TemplateFinished{v_1000406}}}

def template_match_83(v_7: ApplicationSpine, v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, +v_5: List<&2, TemplateDef>) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_7:
    case ApplicationSpine{+v_11, v_12, _}:
      v_1000408 = {v_0 : Ast.SyntaxTerm}
      v_1000409 = {v_1 : Ast.SyntaxTerm}
      v_1000410 = {v_2 : Ast.SourceSpan}
      v_1000411 = {v_5 : List<&2, TemplateDef>}
      v_1000412 = {v_11 : Ast.SyntaxTerm}
      v_1000413 = {v_12 : List<&2, Ast.SyntaxTerm>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_template_for_head{v_11, v_5}}, False{}, v_1000416 => template_body_template_for_head(v_11, v_5), +v_1000414 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_application_template{v_1000408, v_1000409, v_1000410, v_1000411, v_1000412, v_1000413, v_1000414}}, +v_1000415 => TemplateFinished{v_1000415}}}

def template_body_expand_application_spine(v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>, v_7: ApplicationSpine) -> TemplateProgress<Ast.SyntaxTerm>:
  template_match_83(v_7, v_0, v_1, v_2, v_5)

def template_continuation_84(+v_1000421: Nat, v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>, v_6: Ast.SyntaxTerm, +v_8: List<&2, Ast.SyntaxTerm>, v_15: TemplateDef) -> TemplateProgress<Ast.SyntaxTerm>:
  +v_18 = v_1000421
  v_1000422 = {v_0 : Ast.SyntaxTerm}
  v_1000423 = {v_1 : Ast.SyntaxTerm}
  v_1000424 = {v_2 : Ast.SourceSpan}
  v_1000425 = {v_5 : List<&2, TemplateDef>}
  v_1000426 = {v_6 : Ast.SyntaxTerm}
  v_1000427 = {v_8 : List<&2, Ast.SyntaxTerm>}
  v_1000428 = {v_15 : TemplateDef}
  v_1000429 = {v_18 : Nat}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_take_template_args{v_8, v_18}}, False{}, v_1000432 => template_body_take_template_args(v_8, v_18), +v_1000430 => TemplatePending{TemplateRequestGroup_0{TemplateRequest_expand_application_arguments{v_1000422, v_1000423, v_1000424, v_1000425, v_1000426, v_1000427, v_1000428, v_1000429, v_1000430}}, +v_1000431 => TemplateFinished{v_1000431}}}

def template_match_85(v_11: Maybe<&2, TemplateDef>, v_0: Ast.SyntaxTerm, +v_5: List<&2, TemplateDef>, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_6: Ast.SyntaxTerm, v_8: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_11:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_0, v_5}}, False{}, v_1000420 => template_body_expand_term(v_0, v_5), +v_1000417 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_1, v_5}}, False{}, v_1000419 => template_body_expand_term(v_1, v_5), +v_1000418 => TemplateFinished{Ast.TermApp{v_1000417, v_1000418, v_2}}}}
    case Some{+v_15}:
      TemplatePending{TemplateRequestGroup_0{TemplateRequest_template_arity{v_15}}, +v_1000421 => template_continuation_84(v_1000421, v_0, v_1, v_2, v_5, v_6, v_8, v_15)}

def template_body_expand_application_template(v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>, v_6: Ast.SyntaxTerm, v_8: List<&2, Ast.SyntaxTerm>, v_11: Maybe<&2, TemplateDef>) -> TemplateProgress<Ast.SyntaxTerm>:
  template_match_85(v_11, v_0, v_5, v_1, v_2, v_6, v_8)

def template_body_template_arity(v_1: TemplateDef) -> TemplateProgress<Nat>:
  match v_1:
    case TemplateDef{_, _, _, _, _, Ast.Definition{_, v_21, _, _, _, _}, _}:
      template_body_leading_template_count(v_21)

def template_continuation_87(+v_1000443: Ast.SyntaxTerm, v_22: List<&2, Ast.SyntaxTerm>, v_5: List<&2, TemplateDef>, v_2: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  v_31 = v_1000443
  v_1000444 = {v_31 : Ast.SyntaxTerm}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_22, v_5}}, +v_1000445 => template_body_reapply_args(v_1000444, v_1000445, v_2)}

def template_continuation_88(+v_1000440: List<&2, Ast.SyntaxTerm>, v_6: Ast.SyntaxTerm, v_10: TemplateDef, v_22: List<&2, Ast.SyntaxTerm>, v_5: List<&2, TemplateDef>, v_2: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  v_27 = v_1000440
  v_1000441 = {v_6 : Ast.SyntaxTerm}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_generated_key{v_10, v_27}}, False{}, v_1000447 => template_body_generated_key(v_10, v_27), +v_1000442 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_specialize_head{v_1000441, v_1000442}}, +v_1000443 => template_continuation_87(v_1000443, v_22, v_5, v_2)}}

def template_continuation_89(+v_1000438: List<&2, Ast.SyntaxTerm>, v_19: List<&2, Ast.SyntaxTerm>, +v_5: List<&2, TemplateDef>, +v_10: TemplateDef, v_6: Ast.SyntaxTerm, v_2: Ast.SourceSpan) -> TemplateProgress<Ast.SyntaxTerm>:
  v_22 = v_1000438
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_19, v_5}}, +v_1000439 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1000439, template_pure_template_capture_names(v_10)}}, False{}, v_1000448 => template_body_capture_terms(v_1000439, template_pure_template_capture_names(v_10)), +v_1000440 => template_continuation_88(v_1000440, v_6, v_10, v_22, v_5, v_2)}}

def template_match_90(v_15: Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_0: Ast.SyntaxTerm, +v_5: List<&2, TemplateDef>, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_8: List<&2, Ast.SyntaxTerm>, v_12: Nat, v_10: TemplateDef, v_6: Ast.SyntaxTerm) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_15:
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_0, v_5}}, False{}, v_1000437 => template_body_expand_term(v_0, v_5), +v_1000434 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_1, v_5}}, False{}, v_1000436 => template_body_expand_term(v_1, v_5), +v_1000435 => TemplateFinished{Ast.TermApp{v_1000434, v_1000435, v_2}}}}
    case Some{v_19}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_drop_args{v_8, v_12}}, +v_1000438 => template_continuation_89(v_1000438, v_19, v_5, v_10, v_6, v_2)}

def template_body_expand_application_arguments(v_0: Ast.SyntaxTerm, v_1: Ast.SyntaxTerm, v_2: Ast.SourceSpan, v_5: List<&2, TemplateDef>, v_6: Ast.SyntaxTerm, v_8: List<&2, Ast.SyntaxTerm>, v_10: TemplateDef, v_12: Nat, v_15: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> TemplateProgress<Ast.SyntaxTerm>:
  template_match_90(v_15, v_0, v_5, v_1, v_2, v_8, v_12, v_10, v_6)

def template_match_91(+v_0: Ast.SyntaxTerm, v_2: String) -> TemplateProgress<Ast.SyntaxTerm>:
  match v_0:
    case Ast.TermRef{_, v_6}:
      TemplateFinished{Ast.TermRef{v_2, v_6}}
    case Ast.TermBang{_, +v_10}:
      TemplateFinished{Ast.TermBang{Ast.TermRef{v_2, v_10}, v_10}}
    case _:
      TemplateFinished{v_0}

def template_body_specialize_head(v_0: Ast.SyntaxTerm, v_2: String) -> TemplateProgress<Ast.SyntaxTerm>:
  template_match_91(v_0, v_2)

def template_match_92(+v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat) -> TemplateProgress<List<&2, Ast.SyntaxTerm>>:
  match v_1, v_3:
    case _, 0n:
      TemplateFinished{v_1}
    case +_ <> v_11, 1n+v_12:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_drop_args{v_11, v_12}}, +v_1000449 => TemplateFinished{v_1000449}}
    case [], _:
      TemplateFinished{[]}

def template_body_drop_args(v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat) -> TemplateProgress<List<&2, Ast.SyntaxTerm>>:
  template_match_92(v_1, v_3)

def template_continuation_93(v_1000450: Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody)), v_1: TemplateDef, v_3: List<&2, Ast.SyntaxTerm>, v_25: Bool, v_26: Ast.SourceSpan) -> TemplateProgress<Ast.Definition>:
  v_30 = v_1000450
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_generated_local_key{v_1, v_3}}, False{}, v_1000453 => template_body_generated_local_key(v_1, v_3), +v_1000451 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_specialize_definition_result{v_1000451, v_25, v_26, v_30}}, +v_1000452 => TemplateFinished{v_1000452}}}

def template_match_94(+v_1: TemplateDef, +v_3: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Ast.Definition>:
  match v_1:
    case TemplateDef{_, _, _, _, _, Ast.Definition{v_21, v_22, v_23, v_24, v_25, v_26}, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_specialize_prefix{v_22, v_3, v_23, v_24}}, v_1000450 => template_continuation_93(v_1000450, v_1, v_3, v_25, v_26)}

def template_body_specialize_definition(v_1: TemplateDef, v_3: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Ast.Definition>:
  template_match_94(v_1, v_3)

def template_match_95(v_6: Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody)), v_1: String, v_3: Bool, v_4: Ast.SourceSpan) -> TemplateProgress<Ast.Definition>:
  match v_6:
    case (v_10, v_11, v_12):
      TemplateFinished{Ast.Definition{v_1, v_10, v_11, v_12, v_3, v_4}}

def template_body_specialize_definition_result(v_1: String, v_3: Bool, v_4: Ast.SourceSpan, v_6: Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))) -> TemplateProgress<Ast.Definition>:
  template_match_95(v_6, v_1, v_3, v_4)

def template_continuation_96(+v_1000460: Ast.DefBody, v_29: List<&2, Ast.TelescopeItem>, v_20: List<&2, Ast.SyntaxTerm>, v_32: Ast.OptionalTerm) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  v_35 = v_1000460
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_specialize_prefix{v_29, v_20, v_32, v_35}}, v_1000461 => TemplateFinished{v_1000461}}

def template_continuation_97(+v_1000459: Ast.OptionalTerm, v_5: Ast.DefBody, v_23: Nat, v_26: Ast.SyntaxTerm, v_29: List<&2, Ast.TelescopeItem>, v_20: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  v_32 = v_1000459
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_substitute_body{v_5, v_23, v_26}}, +v_1000460 => template_continuation_96(v_1000460, v_29, v_20, v_32)}

def template_continuation_98(+v_1000458: List<&2, Ast.TelescopeItem>, v_4: Ast.OptionalTerm, +v_23: Nat, +v_26: Ast.SyntaxTerm, v_5: Ast.DefBody, v_20: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  v_29 = v_1000458
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_substitute_optional{v_4, v_23, v_26}}, +v_1000459 => template_continuation_97(v_1000459, v_5, v_23, v_26, v_29, v_20)}

def template_continuation_99(v_1000455: Ast.SyntaxTerm, v_1000456: Ast.SyntaxTerm, +v_1000457: Ast.SourceSpan, v_18: List<&2, Ast.TelescopeItem>, v_4: Ast.OptionalTerm, v_23: Nat, v_5: Ast.DefBody, v_20: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  +v_26 = {Ast.TermAnn{v_1000455, v_1000456, v_1000457} : Ast.SyntaxTerm}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_substitute_binders{v_18, 0n, v_26}}, +v_1000458 => template_continuation_98(v_1000458, v_4, v_23, v_26, v_5, v_20)}

def template_continuation_100(+v_1000454: Nat, +v_19: Ast.SyntaxTerm, v_16: Ast.SyntaxTerm, v_18: List<&2, Ast.TelescopeItem>, v_4: Ast.OptionalTerm, v_5: Ast.DefBody, v_20: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  v_23 = v_1000454
  v_1000455 = {v_19 : Ast.SyntaxTerm}
  v_1000456 = {v_16 : Ast.SyntaxTerm}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_span_of{v_19}}, False{}, v_1000462 => template_body_span_of(v_19), +v_1000457 => template_continuation_99(v_1000455, v_1000456, v_1000457, v_18, v_4, v_23, v_5, v_20)}

def template_match_101(+v_1: List<&2, Ast.TelescopeItem>, v_3: List<&2, Ast.SyntaxTerm>, v_4: Ast.OptionalTerm, v_5: Ast.DefBody) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  match v_1, v_3:
    case Ast.TemplateBinder{_, _, v_16, _} <> +v_18, +v_19 <> v_20:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_binder_count{v_18}}, +v_1000454 => template_continuation_100(v_1000454, v_19, v_16, v_18, v_4, v_5, v_20)}
    case _, _:
      TemplateFinished{(v_1, v_4, v_5)}

def template_body_specialize_prefix(v_1: List<&2, Ast.TelescopeItem>, v_3: List<&2, Ast.SyntaxTerm>, v_4: Ast.OptionalTerm, v_5: Ast.DefBody) -> TemplateProgress<Pair(List<&2, Ast.TelescopeItem>, Pair(Ast.OptionalTerm, Ast.DefBody))>:
  template_match_101(v_1, v_3, v_4, v_5)

def template_body_binder_count(v_1: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Nat>:
  match v_1:
    case []:
      TemplateFinished{0n}
    case +_ <> v_6:
      v_1000463 = {1n : Nat}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_binder_count{v_6}}, +v_1000464 => TemplateFinished{Nat.add(v_1000463, v_1000464)}}

def template_match_103(+v_8: Ast.TelescopeItem, +v_3: Nat, +v_4: Ast.SyntaxTerm, v_9: List<&2, Ast.TelescopeItem>) -> TemplateProgress<List<&2, Ast.TelescopeItem>>:
  match v_8:
    case Ast.Binder{v_15, v_16, v_17, v_18, v_19}:
      v_1000465 = {Ast.Binder{v_15, v_16, v_17, Core.subst(v_3, v_4, v_18), v_19} : Ast.TelescopeItem}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_substitute_binders{v_9, Nat.add(v_3, 1n), v_4}}, +v_1000466 => TemplateFinished{v_1000465 <> v_1000466}}
    case Ast.TemplateBinder{v_27, v_28, v_29, v_30}:
      v_1000467 = {Ast.TemplateBinder{v_27, v_28, Core.subst(v_3, v_4, v_29), v_30} : Ast.TelescopeItem}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_substitute_binders{v_9, Nat.add(v_3, 1n), v_4}}, +v_1000468 => TemplateFinished{v_1000467 <> v_1000468}}

def template_body_substitute_binders(v_1: List<&2, Ast.TelescopeItem>, v_3: Nat, v_4: Ast.SyntaxTerm) -> TemplateProgress<List<&2, Ast.TelescopeItem>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_8 <> v_9:
      template_match_103(v_8, v_3, v_4, v_9)

def template_match_105(+v_0: Ast.OptionalTerm, v_2: Nat, v_3: Ast.SyntaxTerm) -> TemplateProgress<Ast.OptionalTerm>:
  match v_0:
    case Ast.NoTerm{}:
      TemplateFinished{v_0}
    case Ast.SomeTerm{v_5}:
      TemplateFinished{Ast.SomeTerm{Core.subst(v_2, v_3, v_5)}}

def template_body_substitute_optional(v_0: Ast.OptionalTerm, v_2: Nat, v_3: Ast.SyntaxTerm) -> TemplateProgress<Ast.OptionalTerm>:
  template_match_105(v_0, v_2, v_3)

def template_match_106(+v_0: Ast.DefBody, v_2: Nat, v_3: Ast.SyntaxTerm) -> TemplateProgress<Ast.DefBody>:
  match v_0:
    case Ast.DefTerm{v_5}:
      TemplateFinished{Ast.DefTerm{Core.subst(v_2, v_3, v_5)}}
    case Ast.DefImports{v_7}:
      TemplateFinished{v_0}

def template_body_substitute_body(v_0: Ast.DefBody, v_2: Nat, v_3: Ast.SyntaxTerm) -> TemplateProgress<Ast.DefBody>:
  template_match_106(v_0, v_2, v_3)

def template_match_107(v_1: List<&2, Ast.SyntaxTerm>, +v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.SyntaxTerm>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_8 <> v_9:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_8, v_4}}, False{}, v_1000471 => template_body_expand_term(v_8, v_4), +v_1000469 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_terms{v_9, v_4}}, +v_1000470 => TemplateFinished{v_1000469 <> v_1000470}}}

def template_body_expand_terms(v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.SyntaxTerm>>:
  template_match_107(v_1, v_4)

def template_match_108(+v_13: Ast.TopLevel, v_1: String, v_14: List<&2, Ast.TopLevel>, +v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_13:
    case Ast.DefTop{Ast.Definition{v_21, +v_22, v_23, v_24, v_25, v_26}}:
      v_1000472 = {v_1 : String}
      v_1000473 = {v_21 : String}
      v_1000474 = {v_22 : List<&2, Ast.TelescopeItem>}
      v_1000475 = {v_23 : Ast.OptionalTerm}
      v_1000476 = {v_24 : Ast.DefBody}
      v_1000477 = {v_25 : Bool}
      v_1000478 = {v_26 : Ast.SourceSpan}
      v_1000479 = {v_14 : List<&2, Ast.TopLevel>}
      v_1000480 = {v_6 : List<&2, TemplateDef>}
      v_1000481 = {v_9 : List<&2, GeneratedIdentity>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_has_template_binder{v_22}}, False{}, v_1000484 => template_body_has_template_binder(v_22), +v_1000482 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_strip_template_definition{v_1000472, v_1000473, v_1000474, v_1000475, v_1000476, v_1000477, v_1000478, v_1000479, v_1000480, v_1000481, v_1000482}}, +v_1000483 => TemplateFinished{v_1000483}}}
    case Ast.TypeTop{Ast.TypeDecl{v_34, v_35, v_36, v_37, v_38}}:
      v_1000485 = {v_34 : String}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_binders{v_35, v_6}}, +v_1000486 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_36, v_6}}, False{}, v_1000490 => template_body_expand_term(v_36, v_6), +v_1000487 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_constructors{v_37, v_6}}, +v_1000488 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_strip_template_decls{v_1, v_14, v_6, v_9}}, +v_1000489 => TemplateFinished{Ast.TypeTop{Ast.TypeDecl{v_1000485, v_1000486, v_1000487, v_1000488, v_38}} <> v_1000489}}}}}
    case Ast.LawTop{Ast.LawDecl{v_47, v_48, v_49, v_50}}:
      v_1000491 = {v_47 : String}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_clauses{v_48, v_6}}, +v_1000492 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_49, v_6}}, False{}, v_1000495 => template_body_expand_term(v_49, v_6), +v_1000493 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_strip_template_decls{v_1, v_14, v_6, v_9}}, +v_1000494 => TemplateFinished{Ast.LawTop{Ast.LawDecl{v_1000491, v_1000492, v_1000493, v_50}} <> v_1000494}}}}

def template_match_109(v_3: List<&2, Ast.TopLevel>, v_1: String, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_3:
    case []:
      TemplateFinished{[]}
    case +v_13 <> v_14:
      template_match_108(v_13, v_1, v_14, v_6, v_9)

def template_body_strip_template_decls(v_1: String, v_3: List<&2, Ast.TopLevel>, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  template_match_109(v_3, v_1, v_6, v_9)

def template_match_110(v_20: Bool, +v_1: String, v_12: List<&2, Ast.TopLevel>, +v_15: List<&2, TemplateDef>, +v_18: List<&2, GeneratedIdentity>, +v_3: String, v_5: List<&2, Ast.TelescopeItem>, v_6: Ast.OptionalTerm, v_7: Ast.DefBody, v_9: Bool, v_10: Ast.SourceSpan) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_20:
    case True{}:
      v_1000496 = {v_1 : String}
      v_1000497 = {v_12 : List<&2, Ast.TopLevel>}
      v_1000498 = {v_15 : List<&2, TemplateDef>}
      v_1000499 = {v_18 : List<&2, GeneratedIdentity>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_canonical_template_key{v_3, v_15}}, +v_1000500 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_strip_canonical_template{v_1000496, v_1000497, v_1000498, v_1000499, v_1000500}}, +v_1000501 => TemplateFinished{v_1000501}}}
    case False{}:
      v_1000502 = {v_1 : String}
      v_1000503 = {v_3 : String}
      v_1000504 = {Ast.Definition{v_3, v_5, v_6, v_7, v_9, v_10} : Ast.Definition}
      v_1000505 = {v_12 : List<&2, Ast.TopLevel>}
      v_1000506 = {v_15 : List<&2, TemplateDef>}
      v_1000507 = {v_18 : List<&2, GeneratedIdentity>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_is_template_instance{v_1, v_3, v_18}}, +v_1000508 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_strip_instance_or_definition{v_1000502, v_1000503, v_1000504, v_1000505, v_1000506, v_1000507, v_1000508}}, +v_1000509 => TemplateFinished{v_1000509}}}

def template_body_strip_template_definition(v_1: String, v_3: String, v_5: List<&2, Ast.TelescopeItem>, v_6: Ast.OptionalTerm, v_7: Ast.DefBody, v_9: Bool, v_10: Ast.SourceSpan, v_12: List<&2, Ast.TopLevel>, v_15: List<&2, TemplateDef>, v_18: List<&2, GeneratedIdentity>, v_20: Bool) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  template_match_110(v_20, v_1, v_12, v_15, v_18, v_3, v_5, v_6, v_7, v_9, v_10)

def template_match_111(v_12: Maybe<&2, String>, +v_3: List<&2, Ast.TopLevel>, +v_6: List<&2, TemplateDef>, +v_9: List<&2, GeneratedIdentity>, v_1: String) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_12:
    case Some{v_15}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_instances{v_3, v_15, v_6, v_9}}, +v_1000510 => TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_strip_template_decls{v_1, v_3, v_6, v_9}}, False{}, v_1000512 => template_body_strip_template_decls(v_1, v_3, v_6, v_9), +v_1000511 => TemplateFinished{List.append(&2, Ast.TopLevel, v_1000510, v_1000511)}}}
    case None{}:
      template_body_strip_template_decls(v_1, v_3, v_6, v_9)

def template_body_strip_canonical_template(v_1: String, v_3: List<&2, Ast.TopLevel>, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>, v_12: Maybe<&2, String>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  template_match_111(v_12, v_3, v_6, v_9, v_1)

def template_match_112(v_14: Bool, v_1: String, v_6: List<&2, Ast.TopLevel>, +v_9: List<&2, TemplateDef>, v_12: List<&2, GeneratedIdentity>, v_4: Ast.Definition) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_14:
    case True{}:
      template_body_strip_template_decls(v_1, v_6, v_9, v_12)
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_definition{v_4, v_9}}, +v_1000515 => TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_strip_template_decls{v_1, v_6, v_9, v_12}}, False{}, v_1000517 => template_body_strip_template_decls(v_1, v_6, v_9, v_12), +v_1000516 => TemplateFinished{Ast.DefTop{v_1000515} <> v_1000516}}}

def template_body_strip_instance_or_definition(v_1: String, v_3: String, v_4: Ast.Definition, v_6: List<&2, Ast.TopLevel>, v_9: List<&2, TemplateDef>, v_12: List<&2, GeneratedIdentity>, v_14: Bool) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  template_match_112(v_14, v_1, v_6, v_9, v_12, v_4)

def template_match_113(+v_9: TemplateDef, +v_1: String, v_10: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, String>>:
  match v_9:
    case TemplateDef{+v_18, v_19, _, _, _, _, _}:
      v_1000518 = {v_1 : String}
      v_1000519 = {v_18 : String}
      v_1000520 = {v_10 : List<&2, TemplateDef>}
      v_1000521 = {v_1 : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_strip_namespace{v_18, v_19}}, False{}, v_1000524 => template_body_strip_namespace(v_18, v_19), +v_1000522 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_canonical_template_match{v_1000518, v_1000519, v_1000520, String.eq(v_1000521, v_1000522)}}, +v_1000523 => TemplateFinished{v_1000523}}}

def template_match_114(v_4: List<&2, TemplateDef>, v_1: String) -> TemplateProgress<Maybe<&2, String>>:
  match v_4:
    case []:
      TemplateFinished{None{}}
    case +v_9 <> v_10:
      template_match_113(v_9, v_1, v_10)

def template_body_canonical_template_key(v_1: String, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, String>>:
  template_match_114(v_4, v_1)

def template_match_115(v_8: Bool, v_3: String, v_1: String, v_6: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, String>>:
  match v_8:
    case True{}:
      TemplateFinished{Some{v_3}}
    case False{}:
      template_body_canonical_template_key(v_1, v_6)

def template_body_canonical_template_match(v_1: String, v_3: String, v_6: List<&2, TemplateDef>, v_8: Bool) -> TemplateProgress<Maybe<&2, String>>:
  template_match_115(v_8, v_3, v_1, v_6)

def template_match_116(+v_9: GeneratedIdentity, +v_1: String, v_10: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, String>>:
  match v_9:
    case GeneratedIdentity{_, v_16, v_17, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_generated_local_key_match{v_1, v_17, v_10, String.eq(v_1, v_16)}}, +v_1000526 => TemplateFinished{v_1000526}}

def template_match_117(v_4: List<&2, GeneratedIdentity>, v_1: String) -> TemplateProgress<List<&2, String>>:
  match v_4:
    case []:
      TemplateFinished{[]}
    case +v_9 <> v_10:
      template_match_116(v_9, v_1, v_10)

def template_body_generated_local_keys(v_1: String, v_4: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, String>>:
  template_match_117(v_4, v_1)

def template_match_118(v_8: Bool, v_3: String, v_1: String, v_6: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, String>>:
  match v_8:
    case True{}:
      v_1000527 = {v_3 : String}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_generated_local_keys{v_1, v_6}}, False{}, v_1000529 => template_body_generated_local_keys(v_1, v_6), +v_1000528 => TemplateFinished{v_1000527 <> v_1000528}}
    case False{}:
      template_body_generated_local_keys(v_1, v_6)

def template_body_generated_local_key_match(v_1: String, v_3: String, v_6: List<&2, GeneratedIdentity>, v_8: Bool) -> TemplateProgress<List<&2, String>>:
  template_match_118(v_8, v_3, v_1, v_6)

def template_body_has_generated_local_key(v_1: String, v_4: List<&2, String>) -> TemplateProgress<Bool>:
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_string{v_1, v_4}}, +v_1000531 => TemplateFinished{v_1000531}}

def template_continuation_119(+v_1000532: String, v_6: List<&2, GeneratedIdentity>) -> TemplateProgress<Bool>:
  v_10 = v_1000532
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_find_generated_identity{v_10, v_6}}, +v_1000533 => TemplateFinished{template_pure_generated_identity_found(v_1000533)}}

def template_body_is_template_instance(v_1: String, v_3: String, v_6: List<&2, GeneratedIdentity>) -> TemplateProgress<Bool>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_qualify{v_1, v_3}}, False{}, v_1000534 => template_body_qualify(v_1, v_3), +v_1000532 => template_continuation_119(v_1000532, v_6)}

def template_body_generated_identity_found(v_2: Maybe<&2, GeneratedIdentity>) -> TemplateProgress<Bool>:
  TemplateFinished{template_pure_generated_identity_found(v_2)}

def template_continuation_120(+v_1000535: List<&2, String>, v_1: List<&2, Ast.TopLevel>, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  v_13 = v_1000535
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_instances_for_keys{v_1, v_13, v_6}}, +v_1000536 => TemplateFinished{v_1000536}}

def template_body_template_instances(v_1: List<&2, Ast.TopLevel>, v_3: String, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_generated_local_keys{v_3, v_9}}, False{}, v_1000537 => template_body_generated_local_keys(v_3, v_9), +v_1000535 => template_continuation_120(v_1000535, v_1, v_6)}

def template_match_121(+v_11: Ast.TopLevel, v_12: List<&2, Ast.TopLevel>, v_7: List<&2, TemplateDef>, +v_4: List<&2, String>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_11:
    case Ast.DefTop{Ast.Definition{+v_19, v_20, v_21, v_22, v_23, v_24}}:
      v_1000538 = {v_19 : String}
      v_1000539 = {v_20 : List<&2, Ast.TelescopeItem>}
      v_1000540 = {v_21 : Ast.OptionalTerm}
      v_1000541 = {v_22 : Ast.DefBody}
      v_1000542 = {v_23 : Bool}
      v_1000543 = {v_24 : Ast.SourceSpan}
      v_1000544 = {v_12 : List<&2, Ast.TopLevel>}
      v_1000545 = {v_7 : List<&2, TemplateDef>}
      v_1000546 = {v_4 : List<&2, String>}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_has_generated_local_key{v_19, v_4}}, False{}, v_1000549 => template_body_has_generated_local_key(v_19, v_4), +v_1000547 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_instance_definition{v_1000538, v_1000539, v_1000540, v_1000541, v_1000542, v_1000543, v_1000544, v_1000545, v_1000546, v_1000547}}, +v_1000548 => TemplateFinished{v_1000548}}}
    case _:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_instances_for_keys{v_12, v_4, v_7}}, +v_1000550 => TemplateFinished{v_1000550}}

def template_match_122(v_1: List<&2, Ast.TopLevel>, v_7: List<&2, TemplateDef>, v_4: List<&2, String>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_11 <> v_12:
      template_match_121(v_11, v_12, v_7, v_4)

def template_body_template_instances_for_keys(v_1: List<&2, Ast.TopLevel>, v_4: List<&2, String>, v_7: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  template_match_122(v_1, v_7, v_4)

def template_match_123(v_18: Bool, v_1: String, v_3: List<&2, Ast.TelescopeItem>, v_4: Ast.OptionalTerm, v_5: Ast.DefBody, v_7: Bool, v_8: Ast.SourceSpan, +v_13: List<&2, TemplateDef>, v_10: List<&2, Ast.TopLevel>, v_16: List<&2, String>) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  match v_18:
    case True{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_definition{Ast.Definition{v_1, v_3, v_4, v_5, v_7, v_8}, v_13}}, +v_1000551 => TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_template_instances_for_keys{v_10, v_16, v_13}}, False{}, v_1000553 => template_body_template_instances_for_keys(v_10, v_16, v_13), +v_1000552 => TemplateFinished{Ast.DefTop{v_1000551} <> v_1000552}}}
    case False{}:
      template_body_template_instances_for_keys(v_10, v_16, v_13)

def template_body_template_instance_definition(v_1: String, v_3: List<&2, Ast.TelescopeItem>, v_4: Ast.OptionalTerm, v_5: Ast.DefBody, v_7: Bool, v_8: Ast.SourceSpan, v_10: List<&2, Ast.TopLevel>, v_13: List<&2, TemplateDef>, v_16: List<&2, String>, v_18: Bool) -> TemplateProgress<List<&2, Ast.TopLevel>>:
  template_match_123(v_18, v_1, v_3, v_4, v_5, v_7, v_8, v_13, v_10, v_16)

def template_match_124(+v_8: Ast.ConstructorDecl, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.ConstructorDecl>) -> TemplateProgress<List<&2, Ast.ConstructorDecl>>:
  match v_8:
    case Ast.Constructor{v_13, v_14, v_15}:
      v_1000555 = {v_13 : String}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_binders{v_14, v_4}}, +v_1000556 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_constructors{v_9, v_4}}, +v_1000557 => TemplateFinished{Ast.Constructor{v_1000555, v_1000556, v_15} <> v_1000557}}}

def template_body_expand_constructors(v_1: List<&2, Ast.ConstructorDecl>, v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.ConstructorDecl>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_8 <> v_9:
      template_match_124(v_8, v_4, v_9)

def template_match_126(+v_8: Ast.Clause, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.Clause>) -> TemplateProgress<List<&2, Ast.Clause>>:
  match v_8:
    case Ast.ClauseFor{v_16, v_17, v_18, v_19, v_20, v_21}:
      v_1000558 = {v_16 : Bool}
      v_1000559 = {v_17 : Ast.Quantity}
      v_1000560 = {v_18 : String}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_19, v_4}}, False{}, v_1000564 => template_body_expand_term(v_19, v_4), +v_1000561 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_maybe{v_20, v_4}}, +v_1000562 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_clauses{v_9, v_4}}, +v_1000563 => TemplateFinished{Ast.ClauseFor{v_1000558, v_1000559, v_1000560, v_1000561, v_1000562, v_21} <> v_1000563}}}}

def template_body_expand_clauses(v_1: List<&2, Ast.Clause>, v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.Clause>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_8 <> v_9:
      template_match_126(v_8, v_4, v_9)

def template_body_expand_maybe(v_1: Maybe<&2, Ast.SyntaxTerm>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SyntaxTerm>>:
  match v_1:
    case None{}:
      TemplateFinished{None{}}
    case Some{v_6}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_6, v_4}}, False{}, v_1000566 => template_body_expand_term(v_6, v_4), +v_1000565 => TemplateFinished{Some{v_1000565}}}

def template_match_129(v_0: Ast.Definition, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.Definition>:
  match v_0:
    case Ast.Definition{v_10, v_11, v_12, v_13, v_14, v_15}:
      v_1000567 = {v_10 : String}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_binders{v_11, v_3}}, +v_1000568 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_optional{v_12, v_3}}, +v_1000569 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_body{v_13, v_3}}, +v_1000570 => TemplateFinished{Ast.Definition{v_1000567, v_1000568, v_1000569, v_1000570, v_14, v_15}}}}}

def template_body_expand_definition(v_0: Ast.Definition, v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.Definition>:
  template_match_129(v_0, v_3)

def template_match_130(+v_0: Ast.DefBody, v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.DefBody>:
  match v_0:
    case Ast.DefTerm{v_5}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_5, v_3}}, False{}, v_1000572 => template_body_expand_term(v_5, v_3), +v_1000571 => TemplateFinished{Ast.DefTerm{v_1000571}}}
    case Ast.DefImports{v_8}:
      TemplateFinished{v_0}

def template_body_expand_body(v_0: Ast.DefBody, v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.DefBody>:
  template_match_130(v_0, v_3)

def template_match_131(+v_0: Ast.OptionalTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.OptionalTerm>:
  match v_0:
    case Ast.NoTerm{}:
      TemplateFinished{v_0}
    case Ast.SomeTerm{v_5}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_5, v_3}}, False{}, v_1000574 => template_body_expand_term(v_5, v_3), +v_1000573 => TemplateFinished{Ast.SomeTerm{v_1000573}}}

def template_body_expand_optional(v_0: Ast.OptionalTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Ast.OptionalTerm>:
  template_match_131(v_0, v_3)

def template_match_132(+v_8: Ast.TelescopeItem, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.TelescopeItem>) -> TemplateProgress<List<&2, Ast.TelescopeItem>>:
  match v_8:
    case Ast.Binder{v_15, v_16, v_17, v_18, v_19}:
      v_1000575 = {v_15 : Ast.Quantity}
      v_1000576 = {v_16 : String}
      v_1000577 = {v_17 : Nat}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_18, v_4}}, False{}, v_1000580 => template_body_expand_term(v_18, v_4), +v_1000578 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_binders{v_9, v_4}}, +v_1000579 => TemplateFinished{Ast.Binder{v_1000575, v_1000576, v_1000577, v_1000578, v_19} <> v_1000579}}}
    case Ast.TemplateBinder{v_26, v_27, v_28, v_29}:
      v_1000581 = {v_26 : String}
      v_1000582 = {v_27 : Nat}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_expand_term{v_28, v_4}}, False{}, v_1000585 => template_body_expand_term(v_28, v_4), +v_1000583 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_binders{v_9, v_4}}, +v_1000584 => TemplateFinished{Ast.TemplateBinder{v_1000581, v_1000582, v_1000583, v_29} <> v_1000584}}}

def template_body_expand_binders(v_1: List<&2, Ast.TelescopeItem>, v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Ast.TelescopeItem>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_8 <> v_9:
      template_match_132(v_8, v_4, v_9)

def template_match_134(+v_0: Ast.SyntaxTerm, v_3: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_0:
    case Ast.TermApp{_, _, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_application{v_0, [], v_3}}, +v_1000586 => TemplateFinished{v_1000586}}
    case Ast.TermBang{v_14, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_14, v_3}}, +v_1000587 => TemplateFinished{v_1000587}}
    case Ast.TermSub{_, v_22, v_23, _}:
      v_1000588 = {v_22 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_23, v_3}}, +v_1000589 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000588, v_1000589}}, +v_1000590 => TemplateFinished{v_1000590}}}
    case Ast.TermLet{_, _, _, v_36, v_37, _}:
      v_1000591 = {v_36 : List<&2, Ast.SyntaxTerm>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_37, v_3}}, +v_1000592 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_1000591, v_1000592}}, +v_1000593 => TemplateFinished{v_1000593}}}
    case Ast.TermAnn{v_44, v_45, _}:
      v_1000594 = {v_44 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_45, v_3}}, +v_1000595 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000594, v_1000595}}, +v_1000596 => TemplateFinished{v_1000596}}}
    case Ast.TermTemplate{v_51, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_51, v_3}}, +v_1000597 => TemplateFinished{v_1000597}}
    case Ast.TermType{v_56, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_56, v_3}}, +v_1000598 => TemplateFinished{v_1000598}}
    case Ast.TermMin{v_62, v_63, _}:
      v_1000599 = {v_62 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_63, v_3}}, +v_1000600 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000599, v_1000600}}, +v_1000601 => TemplateFinished{v_1000601}}}
    case Ast.TermAll{_, _, _, v_76, v_77, _}:
      v_1000602 = {v_76 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_77, v_3}}, +v_1000603 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000602, v_1000603}}, +v_1000604 => TemplateFinished{v_1000604}}}
    case Ast.TermLam{_, _, _, v_89, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_89, v_3}}, +v_1000605 => TemplateFinished{v_1000605}}
    case Ast.TermAdt{_, v_97, _, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_97, v_3}}, +v_1000606 => TemplateFinished{v_1000606}}
    case Ast.TermFill{v_104, v_105, _}:
      v_1000607 = {v_104 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_105, v_3}}, +v_1000608 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000607, v_1000608}}, +v_1000609 => TemplateFinished{v_1000609}}}
    case Ast.TermPlus{v_112, v_113, _}:
      v_1000610 = {v_112 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_113, v_3}}, +v_1000611 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000610, v_1000611}}, +v_1000612 => TemplateFinished{v_1000612}}}
    case Ast.TermCtr{_, v_121, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_121, v_3}}, +v_1000613 => TemplateFinished{v_1000613}}
    case Ast.TermString{_, _, _}:
      TemplateFinished{v_3}
    case Ast.TermMat{_, v_135, v_136, _}:
      v_1000614 = {v_135 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_136, v_3}}, +v_1000615 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000614, v_1000615}}, +v_1000616 => TemplateFinished{v_1000616}}}
    case Ast.TermEqual{v_144, v_145, v_146, _}:
      v_1000617 = {v_144 : Ast.SyntaxTerm}
      v_1000618 = {v_145 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_146, v_3}}, +v_1000619 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000618, v_1000619}}, +v_1000620 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000617, v_1000620}}, +v_1000621 => TemplateFinished{v_1000621}}}}
    case Ast.TermRewrite{v_155, v_156, v_157, _}:
      v_1000622 = {v_155 : Ast.SyntaxTerm}
      v_1000623 = {v_156 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_157, v_3}}, +v_1000624 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000623, v_1000624}}, +v_1000625 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000622, v_1000625}}, +v_1000626 => TemplateFinished{v_1000626}}}}
    case Ast.BodyMatch{v_165, v_166, _}:
      v_1000627 = {v_165 : List<&2, Ast.SyntaxTerm>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_166, v_3}}, +v_1000628 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_1000627, v_1000628}}, +v_1000629 => TemplateFinished{v_1000629}}}
    case Ast.BodyCase{_, v_174, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_174, v_3}}, +v_1000630 => TemplateFinished{v_1000630}}
    case Ast.BodyLocal{_, _, v_184, v_185, _}:
      v_1000631 = {v_184 : List<&2, Ast.SyntaxTerm>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_185, v_3}}, +v_1000632 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_1000631, v_1000632}}, +v_1000633 => TemplateFinished{v_1000633}}}
    case Ast.BodyReply{v_191, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_191, v_3}}, +v_1000634 => TemplateFinished{v_1000634}}
    case _:
      TemplateFinished{v_3}

def template_body_collect_actual_term(v_0: Ast.SyntaxTerm, v_3: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  template_match_134(v_0, v_3)

def template_match_135(+v_1000639: Maybe<&2, String>, v_20: List<&2, ActualSite>, v_2: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1000639:
    case None{}:
      TemplateFinished{v_20}
    case Some{v_23}:
      v_1000640 = {v_23 : String}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_wrapped_prefix{v_2}}, +v_1000641 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_prefix{v_1000640, v_1000641, v_20}}, +v_1000642 => TemplateFinished{v_1000642}}}

def template_continuation_136(+v_1000638: List<&2, ActualSite>, v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<List<&2, ActualSite>>:
  v_20 = v_1000638
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_head_key{v_0}}, +v_1000639 => template_match_135(v_1000639, v_20, v_2)}

def template_match_137(+v_0: Ast.SyntaxTerm, +v_2: List<&2, Ast.SyntaxTerm>, v_5: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_0:
    case Ast.TermApp{v_11, v_12, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_application{v_11, v_12 <> v_2, v_5}}, +v_1000635 => TemplateFinished{v_1000635}}
    case _:
      v_1000636 = {v_0 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_2, v_5}}, +v_1000637 => TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000636, v_1000637}}, False{}, v_1000643 => template_body_collect_actual_term(v_1000636, v_1000637), +v_1000638 => template_continuation_136(v_1000638, v_0, v_2)}}

def template_body_collect_actual_application(v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>, v_5: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  template_match_137(v_0, v_2, v_5)

def template_match_138(v_4: Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, ActualSite>, v_1: String) -> TemplateProgress<List<&2, ActualSite>>:
  match v_4:
    case Some{[]}:
      TemplateFinished{v_7}
    case Some{v_11}:
      TemplateFinished{ActualSite{v_1, v_11} <> v_7}
    case None{}:
      TemplateFinished{v_7}

def template_body_collect_actual_prefix(v_1: String, v_4: Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  template_match_138(v_4, v_7, v_1)

def template_body_head_key(v_0: Ast.SyntaxTerm) -> TemplateProgress<Maybe<&2, String>>:
  match v_0:
    case Ast.TermRef{v_5, _}:
      TemplateFinished{Some{v_5}}
    case Ast.TermBang{v_9, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_head_key{v_9}}, +v_1000644 => TemplateFinished{v_1000644}}
    case _:
      TemplateFinished{None{}}

def template_body_wrapped_prefix(v_1: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<Maybe<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_1:
    case Ast.TermTemplate{v_7, _} <> v_9:
      v_1000645 = {v_7 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_wrapped_prefix{v_9}}, +v_1000646 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_wrapped_prefix_cons{v_1000645, v_1000646}}, +v_1000647 => TemplateFinished{v_1000647}}}
    case _:
      TemplateFinished{Some{[]}}

def template_match_141(v_3: Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_0: Ast.SyntaxTerm) -> TemplateProgress<Maybe<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_3:
    case Some{v_7}:
      TemplateFinished{Some{v_0 <> v_7}}
    case None{}:
      TemplateFinished{None{}}

def template_body_wrapped_prefix_cons(v_0: Ast.SyntaxTerm, v_3: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> TemplateProgress<Maybe<&2, List<&2, Ast.SyntaxTerm>>>:
  template_match_141(v_3, v_0)

def template_body_collect_actual_terms(v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case []:
      TemplateFinished{v_4}
    case +v_9 <> v_10:
      v_1000648 = {v_9 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_terms{v_10, v_4}}, +v_1000649 => template_body_collect_actual_term(v_1000648, v_1000649)}

def template_body_first_actual(v_2: List<&2, List<&2, Ast.SyntaxTerm>>, v_5: List<&2, List<&2, Ast.SyntaxTerm>>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  TemplateFinished{List.append(&2, List<&2, Ast.SyntaxTerm>, v_2, v_5)}

def template_match_143(+v_9: Ast.TopLevel, v_13: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_9:
    case Ast.DefTop{Ast.Definition{_, +v_21, v_22, v_23, _, _}}:
      v_1000652 = {v_21 : List<&2, Ast.TelescopeItem>}
      v_1000653 = {v_22 : Ast.OptionalTerm}
      v_1000654 = {v_23 : Ast.DefBody}
      v_1000655 = {v_13 : List<&2, ActualSite>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_has_template_binder{v_21}}, False{}, v_1000658 => template_body_has_template_binder(v_21), +v_1000656 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_definition{v_1000652, v_1000653, v_1000654, v_1000655, v_1000656}}, +v_1000657 => TemplateFinished{v_1000657}}}
    case Ast.TypeTop{Ast.TypeDecl{_, v_34, v_35, v_36, _}}:
      v_1000659 = {v_34 : List<&2, Ast.TelescopeItem>}
      v_1000660 = {v_35 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_constructors{v_36, v_13}}, +v_1000661 => TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_1000660, v_1000661}}, False{}, v_1000664 => template_body_collect_actual_term(v_1000660, v_1000661), +v_1000662 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_binders{v_1000659, v_1000662}}, +v_1000663 => TemplateFinished{v_1000663}}}}
    case Ast.LawTop{Ast.LawDecl{_, v_46, v_47, _}}:
      v_1000665 = {v_46 : List<&2, Ast.Clause>}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_collect_actual_term{v_47, v_13}}, False{}, v_1000668 => template_body_collect_actual_term(v_47, v_13), +v_1000666 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_clauses{v_1000665, v_1000666}}, +v_1000667 => TemplateFinished{v_1000667}}}

def template_continuation_144(+v_1000651: List<&2, ActualSite>, +v_9: Ast.TopLevel) -> TemplateProgress<List<&2, ActualSite>>:
  v_13 = v_1000651
  template_match_143(v_9, v_13)

def template_body_collect_actual_declarations(v_1: List<&2, Ast.TopLevel>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case []:
      TemplateFinished{v_4}
    case +v_9 <> v_10:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_declarations{v_10, v_4}}, +v_1000651 => template_continuation_144(v_1000651, v_9)}

def template_match_146(v_8: Bool, v_6: List<&2, ActualSite>, v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.OptionalTerm, v_3: Ast.DefBody) -> TemplateProgress<List<&2, ActualSite>>:
  match v_8:
    case True{}:
      TemplateFinished{v_6}
    case False{}:
      v_1000669 = {v_1 : List<&2, Ast.TelescopeItem>}
      v_1000670 = {v_2 : Ast.OptionalTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_body{v_3, v_6}}, +v_1000671 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_optional{v_1000670, v_1000671}}, +v_1000672 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_binders{v_1000669, v_1000672}}, +v_1000673 => TemplateFinished{v_1000673}}}}

def template_body_collect_actual_definition(v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.OptionalTerm, v_3: Ast.DefBody, v_6: List<&2, ActualSite>, v_8: Bool) -> TemplateProgress<List<&2, ActualSite>>:
  template_match_146(v_8, v_6, v_1, v_2, v_3)

def template_body_collect_actual_body(v_0: Ast.DefBody, v_3: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_0:
    case Ast.DefTerm{v_7}:
      template_body_collect_actual_term(v_7, v_3)
    case Ast.DefImports{_}:
      TemplateFinished{v_3}

def template_continuation_148(+v_3: List<&2, Loader.LoadedModule>, v_15: List<&2, Loader.LoadedModule>, v_1000675: String, v_1000676: List<&2, Ast.ModuleImport>, +v_1000677: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualModule>>:
  v_1000678 = {v_3 : List<&2, Loader.LoadedModule>}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_modules{v_15, v_3}}, +v_1000679 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_module{v_1000675, v_1000676, v_1000677, v_1000678, v_1000679}}, +v_1000680 => TemplateFinished{v_1000680}}}

def template_body_collect_actual_modules(v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, ActualModule>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case Loader.LoadedModule{v_11, Ast.Module{_, v_13, v_14}} <> v_15:
      v_1000675 = {v_11 : String}
      v_1000676 = {v_13 : List<&2, Ast.ModuleImport>}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_collect_actual_declarations{v_14, []}}, False{}, v_1000681 => template_body_collect_actual_declarations(v_14, []), +v_1000677 => template_continuation_148(v_3, v_15, v_1000675, v_1000676, v_1000677)}

def template_match_150(+v_6: List<&2, ActualSite>, v_11: List<&2, ActualModule>, +v_1: String, +v_3: List<&2, Ast.ModuleImport>, v_8: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, ActualModule>>:
  match v_6:
    case []:
      TemplateFinished{v_11}
    case +_ <> _:
      v_1000682 = {v_1 : String}
      v_1000683 = {v_3 : List<&2, Ast.ModuleImport>}
      v_1000684 = {v_6 : List<&2, ActualSite>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_scope_capture_names{v_1, v_3, v_8}}, False{}, v_1000686 => template_body_scope_capture_names(v_1, v_3, v_8), +v_1000685 => TemplateFinished{ActualModule{v_1000682, v_1000683, v_1000684, v_1000685} <> v_11}}

def template_body_collect_actual_module(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, ActualSite>, v_8: List<&2, Loader.LoadedModule>, v_11: List<&2, ActualModule>) -> TemplateProgress<List<&2, ActualModule>>:
  template_match_150(v_6, v_11, v_1, v_3, v_8)

def template_continuation_151(+v_1000692: List<&2, TemplateDef>, v_23: List<&2, List<&2, Ast.SyntaxTerm>>, v_18: List<&2, CaptureName>, v_19: List<&2, ActualModule>, v_4: String, v_7: List<&2, TemplateDef>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  v_32 = v_1000692
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_actual_values{v_23, v_32, v_18}}, +v_1000693 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_in_catalog{v_19, v_4, v_7}}, +v_1000694 => template_body_first_actual(v_1000693, v_1000694)}}

def template_match_152(+v_23: List<&2, List<&2, Ast.SyntaxTerm>>, v_19: List<&2, ActualModule>, v_4: String, +v_7: List<&2, TemplateDef>, v_15: String, v_16: List<&2, Ast.ModuleImport>, +v_18: List<&2, CaptureName>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_23:
    case []:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_in_catalog{v_19, v_4, v_7}}, +v_1000690 => TemplateFinished{v_1000690}}
    case +_ <> _:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_visible_templates{v_15, v_16, v_7}}, +v_1000691 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_templates_with_captures{v_1000691, v_18}}, False{}, v_1000696 => template_body_templates_with_captures(v_1000691, v_18), +v_1000692 => template_continuation_151(v_1000692, v_23, v_18, v_19, v_4, v_7)}}

def template_continuation_153(+v_1000689: List<&2, List<&2, Ast.SyntaxTerm>>, v_19: List<&2, ActualModule>, v_4: String, v_7: List<&2, TemplateDef>, v_15: String, v_16: List<&2, Ast.ModuleImport>, v_18: List<&2, CaptureName>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  v_23 = v_1000689
  template_match_152(v_23, v_19, v_4, v_7, v_15, v_16, v_18)

def template_match_154(v_2: List<&2, ActualModule>, +v_4: String, +v_7: List<&2, TemplateDef>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_2:
    case []:
      TemplateFinished{[]}
    case ActualModule{+v_15, +v_16, v_17, v_18} <> v_19:
      v_1000687 = {v_17 : List<&2, ActualSite>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_aliases{v_15, v_16, v_4, v_7}}, +v_1000688 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_in_aliases{v_1000687, v_1000688}}, +v_1000689 => template_continuation_153(v_1000689, v_19, v_4, v_7, v_15, v_16, v_18)}}

def template_body_actual_in_catalog(v_2: List<&2, ActualModule>, v_4: String, v_7: List<&2, TemplateDef>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  template_match_154(v_2, v_4, v_7)

def template_body_template_aliases(v_1: String, v_3: List<&2, Ast.ModuleImport>, +v_5: String, v_8: List<&2, TemplateDef>) -> TemplateProgress<List<&2, String>>:
  v_1000697 = {v_1 : String}
  v_1000698 = {v_3 : List<&2, Ast.ModuleImport>}
  v_1000699 = {v_5 : String}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_find_template{v_5, v_8}}, False{}, v_1000702 => template_body_find_template(v_5, v_8), +v_1000700 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_aliases_found{v_1000697, v_1000698, v_1000699, v_1000700}}, +v_1000701 => TemplateFinished{v_1000701}}}

def template_continuation_155(+v_1000704: List<&2, String>, v_5: String, v_1: String, v_3: List<&2, Ast.ModuleImport>, v_19: String, v_27: String) -> TemplateProgress<List<&2, String>>:
  v_30 = v_1000704
  v_1000705 = {[v_5] : List<&2, String>}
  v_1000706 = {v_30 : List<&2, String>}
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_imported_alias_names{v_1, v_3, v_19, v_27}}, +v_1000707 => TemplateFinished{List.append(&2, String, v_1000705, List.append(&2, String, v_1000706, v_1000707))}}

def template_continuation_156(+v_1000703: String, +v_1: String, +v_19: String, v_5: String, v_3: List<&2, Ast.ModuleImport>) -> TemplateProgress<List<&2, String>>:
  +v_27 = v_1000703
  TemplatePending{TemplateRequestGroup_1{TemplateRequest_template_local_alias{v_1, v_19, v_27, String.eq(v_1, v_19)}}, +v_1000704 => template_continuation_155(v_1000704, v_5, v_1, v_3, v_19, v_27)}

def template_match_157(v_8: Maybe<&2, TemplateDef>, +v_5: String, v_1: String, v_3: List<&2, Ast.ModuleImport>) -> TemplateProgress<List<&2, String>>:
  match v_8:
    case None{}:
      TemplateFinished{[v_5]}
    case Some{TemplateDef{_, +v_19, _, _, _, _, _}}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_strip_namespace{v_5, v_19}}, False{}, v_1000708 => template_body_strip_namespace(v_5, v_19), +v_1000703 => template_continuation_156(v_1000703, v_1, v_19, v_5, v_3)}

def template_body_template_aliases_found(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: String, v_8: Maybe<&2, TemplateDef>) -> TemplateProgress<List<&2, String>>:
  template_match_157(v_8, v_5, v_1, v_3)

def template_match_158(v_7: Bool, v_5: String) -> TemplateProgress<List<&2, String>>:
  match v_7:
    case True{}:
      TemplateFinished{[v_5]}
    case False{}:
      TemplateFinished{[]}

def template_body_template_local_alias(v_1: String, v_3: String, v_5: String, v_7: Bool) -> TemplateProgress<List<&2, String>>:
  template_match_158(v_7, v_5)

def template_match_159(+v_12: Ast.ModuleImport, +v_1: String, v_13: List<&2, Ast.ModuleImport>, +v_5: String, v_7: String) -> TemplateProgress<List<&2, String>>:
  match v_12:
    case Ast.ModuleImport{v_17, v_18, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_imported_alias_match{v_1, v_13, v_5, v_7, v_18, String.eq(Path.namespace(v_1, v_17), v_5)}}, +v_1000709 => TemplateFinished{v_1000709}}

def template_match_160(v_3: List<&2, Ast.ModuleImport>, v_1: String, v_5: String, v_7: String) -> TemplateProgress<List<&2, String>>:
  match v_3:
    case []:
      TemplateFinished{[]}
    case +v_12 <> v_13:
      template_match_159(v_12, v_1, v_13, v_5, v_7)

def template_body_imported_alias_names(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: String, v_7: String) -> TemplateProgress<List<&2, String>>:
  template_match_160(v_3, v_1, v_5, v_7)

def template_match_161(v_11: Bool, v_9: String, +v_7: String, v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: String) -> TemplateProgress<List<&2, String>>:
  match v_11:
    case True{}:
      v_1000710 = {String.append(v_9, String.append(".", v_7)) : String}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_imported_alias_names{v_1, v_3, v_5, v_7}}, False{}, v_1000712 => template_body_imported_alias_names(v_1, v_3, v_5, v_7), +v_1000711 => TemplateFinished{v_1000710 <> v_1000711}}
    case False{}:
      template_body_imported_alias_names(v_1, v_3, v_5, v_7)

def template_body_imported_alias_match(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_5: String, v_7: String, v_9: String, v_11: Bool) -> TemplateProgress<List<&2, String>>:
  template_match_161(v_11, v_9, v_7, v_1, v_3, v_5)

def template_match_162(v_5: List<&2, String>, +v_2: List<&2, ActualSite>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_5:
    case []:
      TemplateFinished{[]}
    case +v_10 <> v_11:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_sites_for_key{v_2, v_10}}, +v_1000714 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_in_aliases{v_2, v_11}}, +v_1000715 => template_body_first_actual(v_1000714, v_1000715)}}

def template_body_actual_in_aliases(v_2: List<&2, ActualSite>, v_5: List<&2, String>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  template_match_162(v_5, v_2)

def template_match_163(v_1000717: Bool, v_11: List<&2, Ast.SyntaxTerm>, v_12: List<&2, ActualSite>, v_4: String) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_1000717:
    case True{}:
      v_1000718 = {v_11 : List<&2, Ast.SyntaxTerm>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_sites_for_key{v_12, v_4}}, +v_1000719 => TemplateFinished{v_1000718 <> v_1000719}}
    case False{}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_actual_sites_for_key{v_12, v_4}}, +v_1000720 => TemplateFinished{v_1000720}}

def template_match_164(v_2: List<&2, ActualSite>, +v_4: String) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_2:
    case []:
      TemplateFinished{[]}
    case ActualSite{v_10, v_11} <> v_12:
      v_1000717 = {String.eq(v_4, v_10) : Bool}
      template_match_163(v_1000717, v_11, v_12, v_4)

def template_body_actual_sites_for_key(v_2: List<&2, ActualSite>, v_4: String) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  template_match_164(v_2, v_4)

def template_match_165(v_2: List<&2, List<&2, Ast.SyntaxTerm>>, +v_5: List<&2, TemplateDef>, +v_8: List<&2, CaptureName>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  match v_2:
    case []:
      TemplateFinished{[]}
    case +v_13 <> v_14:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_expand_terms{v_13, v_5}}, False{}, v_1000725 => template_body_expand_terms(v_13, v_5), +v_1000721 => TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_terms{v_1000721, v_8}}, False{}, v_1000724 => template_body_capture_terms(v_1000721, v_8), +v_1000722 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_expand_actual_values{v_14, v_5, v_8}}, +v_1000723 => TemplateFinished{v_1000722 <> v_1000723}}}}

def template_body_expand_actual_values(v_2: List<&2, List<&2, Ast.SyntaxTerm>>, v_5: List<&2, TemplateDef>, v_8: List<&2, CaptureName>) -> TemplateProgress<List<&2, List<&2, Ast.SyntaxTerm>>>:
  template_match_165(v_2, v_5, v_8)

def template_match_166(+v_9: Ast.TelescopeItem, v_10: List<&2, Ast.TelescopeItem>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_9:
    case Ast.Binder{_, _, _, v_19, _}:
      v_1000726 = {v_19 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_binders{v_10, v_4}}, +v_1000727 => template_body_collect_actual_term(v_1000726, v_1000727)}
    case Ast.TemplateBinder{_, _, v_29, _}:
      v_1000729 = {v_29 : Ast.SyntaxTerm}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_binders{v_10, v_4}}, +v_1000730 => template_body_collect_actual_term(v_1000729, v_1000730)}

def template_body_collect_actual_binders(v_1: List<&2, Ast.TelescopeItem>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case []:
      TemplateFinished{v_4}
    case +v_9 <> v_10:
      template_match_166(v_9, v_10, v_4)

def template_body_collect_actual_optional(v_0: Ast.OptionalTerm, v_3: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_0:
    case Ast.NoTerm{}:
      TemplateFinished{v_3}
    case Ast.SomeTerm{v_7}:
      template_body_collect_actual_term(v_7, v_3)

def template_body_collect_actual_constructors(v_1: List<&2, Ast.ConstructorDecl>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case []:
      TemplateFinished{v_4}
    case Ast.Constructor{_, v_12, _} <> v_14:
      v_1000733 = {v_12 : List<&2, Ast.TelescopeItem>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_constructors{v_14, v_4}}, +v_1000734 => template_body_collect_actual_binders(v_1000733, v_1000734)}

def template_body_collect_actual_clauses(v_1: List<&2, Ast.Clause>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case []:
      TemplateFinished{v_4}
    case Ast.ClauseFor{_, _, _, v_17, v_18, _} <> v_20:
      v_1000736 = {v_17 : Ast.SyntaxTerm}
      v_1000737 = {v_18 : Maybe<&2, Ast.SyntaxTerm>}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_clauses{v_20, v_4}}, +v_1000738 => TemplatePending{TemplateRequestGroup_1{TemplateRequest_collect_actual_maybe{v_1000737, v_1000738}}, +v_1000739 => template_body_collect_actual_term(v_1000736, v_1000739)}}

def template_body_collect_actual_maybe(v_1: Maybe<&2, Ast.SyntaxTerm>, v_4: List<&2, ActualSite>) -> TemplateProgress<List<&2, ActualSite>>:
  match v_1:
    case None{}:
      TemplateFinished{v_4}
    case Some{v_7}:
      template_body_collect_actual_term(v_7, v_4)

def template_match_172(v_4: List<&2, String>, +v_1: String) -> TemplateProgress<Bool>:
  match v_4:
    case []:
      TemplateFinished{False{}}
    case +v_8 <> v_9:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_string_match{v_1, v_8, v_9, String.eq(v_1, v_8)}}, +v_1000742 => TemplateFinished{v_1000742}}

def template_body_has_string(v_1: String, v_4: List<&2, String>) -> TemplateProgress<Bool>:
  template_match_172(v_4, v_1)

def template_match_173(v_8: Bool, v_1: String, v_6: List<&2, String>) -> TemplateProgress<Bool>:
  match v_8:
    case True{}:
      TemplateFinished{True{}}
    case False{}:
      template_body_has_string(v_1, v_6)

def template_body_has_string_match(v_1: String, v_3: String, v_6: List<&2, String>, v_8: Bool) -> TemplateProgress<Bool>:
  template_match_173(v_8, v_1, v_6)

def template_match_174(+v_7: Ast.TopLevel, +v_1: String, v_8: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_7:
    case Ast.DefTop{Ast.Definition{v_15, _, _, _, _, _}}:
      v_1000744 = {String.eq(v_1, v_15) : Bool}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_top_key{v_1, v_8}}, +v_1000745 => TemplateFinished{Bool.or(v_1000744, v_1000745)}}
    case Ast.TypeTop{Ast.TypeDecl{v_27, _, _, _, _}}:
      v_1000746 = {String.eq(v_1, v_27) : Bool}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_top_key{v_1, v_8}}, +v_1000747 => TemplateFinished{Bool.or(v_1000746, v_1000747)}}
    case Ast.LawTop{Ast.LawDecl{v_37, _, _, _}}:
      v_1000748 = {String.eq(v_1, v_37) : Bool}
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_has_top_key{v_1, v_8}}, +v_1000749 => TemplateFinished{Bool.or(v_1000748, v_1000749)}}

def template_match_175(v_3: List<&2, Ast.TopLevel>, v_1: String) -> TemplateProgress<Bool>:
  match v_3:
    case []:
      TemplateFinished{False{}}
    case +v_7 <> v_8:
      template_match_174(v_7, v_1, v_8)

def template_body_has_top_key(v_1: String, v_3: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  template_match_175(v_3, v_1)

def template_match_176(+v_9: GeneratedIdentity, +v_1: String, v_10: List<&2, GeneratedIdentity>) -> TemplateProgress<Maybe<&2, GeneratedIdentity>>:
  match v_9:
    case GeneratedIdentity{+v_15, _, _, _}:
      TemplatePending{TemplateRequestGroup_1{TemplateRequest_find_generated_identity_match{v_1, v_9, v_10, v_15, String.eq(v_1, v_15)}}, +v_1000750 => TemplateFinished{v_1000750}}

def template_match_177(v_4: List<&2, GeneratedIdentity>, v_1: String) -> TemplateProgress<Maybe<&2, GeneratedIdentity>>:
  match v_4:
    case []:
      TemplateFinished{None{}}
    case +v_9 <> v_10:
      template_match_176(v_9, v_1, v_10)

def template_body_find_generated_identity(v_1: String, v_4: List<&2, GeneratedIdentity>) -> TemplateProgress<Maybe<&2, GeneratedIdentity>>:
  template_match_177(v_4, v_1)

def template_match_178(v_10: Bool, v_3: GeneratedIdentity, v_1: String, v_6: List<&2, GeneratedIdentity>) -> TemplateProgress<Maybe<&2, GeneratedIdentity>>:
  match v_10:
    case True{}:
      TemplateFinished{Some{v_3}}
    case False{}:
      template_body_find_generated_identity(v_1, v_6)

def template_body_find_generated_identity_match(v_1: String, v_3: GeneratedIdentity, v_6: List<&2, GeneratedIdentity>, v_8: String, v_10: Bool) -> TemplateProgress<Maybe<&2, GeneratedIdentity>>:
  template_match_178(v_10, v_3, v_1, v_6)

def template_body_template_span(v_1: TemplateDef) -> TemplateProgress<Ast.SourceSpan>:
  TemplateFinished{template_pure_template_span(v_1)}

def template_continuation_179(+v_1000756: String, v_1: TemplateDef, v_17: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, +v_12: List<&2, GeneratedIdentity>, v_26: String, v_29: String, v_32: String, v_20: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<GeneratedBuild>:
  +v_35 = v_1000756
  v_1000757 = {v_1 : TemplateDef}
  v_1000758 = {v_17 : List<&2, List<&2, Ast.SyntaxTerm>>}
  v_1000759 = {v_7 : List<&2, TemplateDef>}
  v_1000760 = {v_9 : List<&2, Ast.TopLevel>}
  v_1000761 = {v_12 : List<&2, GeneratedIdentity>}
  v_1000762 = {v_26 : String}
  v_1000763 = {v_29 : String}
  v_1000764 = {v_32 : String}
  v_1000765 = {v_35 : String}
  v_1000766 = {v_20 : List<&2, Ast.SyntaxTerm>}
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_find_generated_identity{v_35, v_12}}, False{}, v_1000769 => template_body_find_generated_identity(v_35, v_12), +v_1000767 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_actual_case{v_1000757, v_1000758, v_1000759, v_1000760, v_1000761, v_1000762, v_1000763, v_1000764, v_1000765, v_1000766, v_1000767}}, +v_1000768 => TemplateFinished{v_1000768}}}

def template_continuation_180(+v_1000755: String, +v_1: TemplateDef, +v_20: List<&2, Ast.SyntaxTerm>, v_17: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>, v_26: String, v_29: String) -> TemplateProgress<GeneratedBuild>:
  v_32 = v_1000755
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_generated_key{v_1, v_20}}, False{}, v_1000770 => template_body_generated_key(v_1, v_20), +v_1000756 => template_continuation_179(v_1000756, v_1, v_17, v_7, v_9, v_12, v_26, v_29, v_32, v_20)}

def template_continuation_181(+v_1000754: String, v_23: String, +v_1: TemplateDef, +v_20: List<&2, Ast.SyntaxTerm>, v_17: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>, v_26: String) -> TemplateProgress<GeneratedBuild>:
  v_29 = String.append(v_1000754, v_23)
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_generated_local_key{v_1, v_20}}, False{}, v_1000771 => template_body_generated_local_key(v_1, v_20), +v_1000755 => template_continuation_180(v_1000755, v_1, v_20, v_17, v_7, v_9, v_12, v_26, v_29)}

def template_continuation_182(+v_1000753: String, +v_1: TemplateDef, v_20: List<&2, Ast.SyntaxTerm>, v_17: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedBuild>:
  v_23 = v_1000753
  +v_26 = template_pure_template_name(v_1)
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_encode_string{v_26}}, False{}, v_1000772 => template_body_encode_string(v_26), +v_1000754 => template_continuation_181(v_1000754, v_23, v_1, v_20, v_17, v_7, v_9, v_12, v_26)}

def template_continuation_183(+v_1000752: List<&2, Ast.SyntaxTerm>, v_1: TemplateDef, v_17: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedBuild>:
  +v_20 = v_1000752
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_serialize_terms{v_20}}, False{}, v_1000773 => template_body_serialize_terms(v_20), +v_1000753 => template_continuation_182(v_1000753, v_1, v_20, v_17, v_7, v_9, v_12)}

def template_match_184(v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_12: List<&2, GeneratedIdentity>, +v_7: List<&2, TemplateDef>, v_1: TemplateDef, v_9: List<&2, Ast.TopLevel>) -> TemplateProgress<GeneratedBuild>:
  match v_4:
    case []:
      TemplateFinished{GeneratedBuild{[], v_12, None{}}}
    case +v_16 <> v_17:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_expand_terms{v_16, v_7}}, False{}, v_1000774 => template_body_expand_terms(v_16, v_7), +v_1000752 => template_continuation_183(v_1000752, v_1, v_17, v_7, v_9, v_12)}

def template_body_generated_actuals(v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedBuild>:
  template_match_184(v_4, v_12, v_7, v_1, v_9)

def template_body_template_name(v_1: TemplateDef) -> TemplateProgress<String>:
  TemplateFinished{template_pure_template_name(v_1)}

def template_match_185(v_25: Maybe<&2, GeneratedIdentity>, v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, +v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>, +v_16: String, v_14: String, +v_18: String, v_20: String, v_22: List<&2, Ast.SyntaxTerm>) -> TemplateProgress<GeneratedBuild>:
  match v_25:
    case Some{GeneratedIdentity{_, _, _, +v_34}}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_identity_collision{v_1, v_4, v_7, v_9, v_12, v_16, v_34, String.eq(v_16, v_34)}}, +v_1000775 => TemplateFinished{v_1000775}}
    case None{}:
      v_1000776 = {v_1 : TemplateDef}
      v_1000777 = {v_4 : List<&2, List<&2, Ast.SyntaxTerm>>}
      v_1000778 = {v_7 : List<&2, TemplateDef>}
      v_1000779 = {v_9 : List<&2, Ast.TopLevel>}
      v_1000780 = {v_12 : List<&2, GeneratedIdentity>}
      v_1000781 = {v_14 : String}
      v_1000782 = {v_16 : String}
      v_1000783 = {v_18 : String}
      v_1000784 = {v_20 : String}
      v_1000785 = {v_22 : List<&2, Ast.SyntaxTerm>}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_has_top_key{v_18, v_9}}, False{}, v_1000788 => template_body_has_top_key(v_18, v_9), +v_1000786 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_actual_new{v_1000776, v_1000777, v_1000778, v_1000779, v_1000780, v_1000781, v_1000782, v_1000783, v_1000784, v_1000785, v_1000786}}, +v_1000787 => TemplateFinished{v_1000787}}}

def template_body_generated_actual_case(v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>, v_14: String, v_16: String, v_18: String, v_20: String, v_22: List<&2, Ast.SyntaxTerm>, v_25: Maybe<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedBuild>:
  template_match_185(v_25, v_1, v_4, v_7, v_9, v_12, v_16, v_14, v_18, v_20, v_22)

def template_match_186(v_18: Bool, v_12: List<&2, GeneratedIdentity>, v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>) -> TemplateProgress<GeneratedBuild>:
  match v_18:
    case False{}:
      TemplateFinished{GeneratedBuild{[], v_12, Some{template_pure_template_span(v_1)}}}
    case True{}:
      template_body_generated_actuals(v_1, v_4, v_7, v_9, v_12)

def template_body_generated_identity_collision(v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>, v_14: String, v_16: String, v_18: Bool) -> TemplateProgress<GeneratedBuild>:
  template_match_186(v_18, v_12, v_1, v_4, v_7, v_9)

def template_continuation_187(+v_1000790: Ast.Definition, v_20: String, v_14: String, v_18: String, v_16: String, v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedBuild>:
  v_29 = v_1000790
  v_31 = {GeneratedIdentity{v_20, v_14, v_18, v_16} : GeneratedIdentity}
  v_1000791 = {v_29 : Ast.Definition}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generated_actuals{v_1, v_4, v_7, v_9, v_31 <> v_12}}, False{}, v_1000794 => template_body_generated_actuals(v_1, v_4, v_7, v_9, v_31 <> v_12), +v_1000792 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_actual_complete{v_1000791, v_1000792}}, +v_1000793 => TemplateFinished{v_1000793}}}

def template_match_188(v_24: Bool, v_12: List<&2, GeneratedIdentity>, +v_1: TemplateDef, v_22: List<&2, Ast.SyntaxTerm>, v_20: String, v_14: String, v_18: String, v_16: String, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>) -> TemplateProgress<GeneratedBuild>:
  match v_24:
    case True{}:
      TemplateFinished{GeneratedBuild{[], v_12, Some{template_pure_template_span(v_1)}}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_specialize_definition{v_1, v_22}}, False{}, v_1000795 => template_body_specialize_definition(v_1, v_22), +v_1000790 => template_continuation_187(v_1000790, v_20, v_14, v_18, v_16, v_1, v_4, v_7, v_9, v_12)}

def template_body_generated_actual_new(v_1: TemplateDef, v_4: List<&2, List<&2, Ast.SyntaxTerm>>, v_7: List<&2, TemplateDef>, v_9: List<&2, Ast.TopLevel>, v_12: List<&2, GeneratedIdentity>, v_14: String, v_16: String, v_18: String, v_20: String, v_22: List<&2, Ast.SyntaxTerm>, v_24: Bool) -> TemplateProgress<GeneratedBuild>:
  template_match_188(v_24, v_12, v_1, v_22, v_20, v_14, v_18, v_16, v_4, v_7, v_9)

def template_match_189(v_2: GeneratedBuild, v_0: Ast.Definition) -> TemplateProgress<GeneratedBuild>:
  match v_2:
    case GeneratedBuild{v_7, v_8, v_9}:
      TemplateFinished{GeneratedBuild{Ast.DefTop{v_0} <> v_7, v_8, v_9}}

def template_body_generated_actual_complete(v_0: Ast.Definition, v_2: GeneratedBuild) -> TemplateProgress<GeneratedBuild>:
  template_match_189(v_2, v_0)

def template_body_template_source_span_equal(v_0: Ast.SourceSpan, v_1: Ast.SourceSpan) -> TemplateProgress<Bool>:
  match v_0, v_1:
    case Ast.SpanOf{v_9, v_10, v_11}, Ast.SpanOf{v_12, v_13, v_14}:
      TemplateFinished{Bool.and(String.eq(v_9, v_12), Bool.and(Nat.is_eq(v_10, v_13), Nat.is_eq(v_11, v_14)))}

def template_match_191(+v_1000797: Bool, v_1: String, v_2: Ast.SourceSpan, v_19: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_1000797:
    case True{}:
      TemplateFinished{True{}}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_template_source_definition{v_1, v_2, v_19}}, +v_1000798 => TemplateFinished{v_1000798}}

def template_match_192(v_1000796: Bool, +v_2: Ast.SourceSpan, v_18: Ast.SourceSpan, v_1: String, v_19: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_1000796:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_template_source_span_equal{v_2, v_18}}, False{}, v_1000799 => template_body_template_source_span_equal(v_2, v_18), +v_1000797 => template_match_191(v_1000797, v_1, v_2, v_19)}
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_template_source_definition{v_1, v_2, v_19}}, +v_1000800 => TemplateFinished{v_1000800}}

def template_match_193(v_4: List<&2, Ast.TopLevel>, +v_1: String, v_2: Ast.SourceSpan) -> TemplateProgress<Bool>:
  match v_4:
    case []:
      TemplateFinished{False{}}
    case Ast.DefTop{Ast.Definition{v_13, _, _, _, _, v_18}} <> v_19:
      v_1000796 = {String.eq(v_1, v_13) : Bool}
      template_match_192(v_1000796, v_2, v_18, v_1, v_19)
    case +_ <> v_26:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_template_source_definition{v_1, v_2, v_26}}, +v_1000801 => TemplateFinished{v_1000801}}

def template_body_has_template_source_definition(v_1: String, v_2: Ast.SourceSpan, v_4: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  template_match_193(v_4, v_1, v_2)

def template_match_194(v_1000803: Bool, v_26: String, v_31: Ast.SourceSpan, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_1000803:
    case False{}:
      TemplateFinished{False{}}
    case True{}:
      template_body_has_template_source_definition(v_26, v_31, v_5)

def template_match_195(+v_31: Ast.SourceSpan, v_3: String, v_26: String, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_31:
    case Ast.SpanOf{v_36, _, _}:
      v_1000803 = {String.eq(v_3, v_36) : Bool}
      template_match_194(v_1000803, v_26, v_31, v_5)

def template_match_196(v_1000802: Bool, v_31: Ast.SourceSpan, v_3: String, v_26: String, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_1000802:
    case False{}:
      TemplateFinished{False{}}
    case True{}:
      template_match_195(v_31, v_3, v_26, v_5)

def template_match_197(v_7: TemplateDef, v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<Bool>:
  match v_7:
    case TemplateDef{_, v_22, _, _, _, Ast.Definition{v_26, _, _, _, _, v_31}, _}:
      v_1000802 = {String.eq(v_1, v_22) : Bool}
      template_match_196(v_1000802, v_31, v_3, v_26, v_5)

def template_body_template_owned_by_module(v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_7: TemplateDef) -> TemplateProgress<Bool>:
  template_match_197(v_7, v_1, v_3, v_5)

def template_match_198(+v_18: TemplateDef, +v_1: String, +v_3: String, +v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, v_11: List<&2, ActualModule>, v_14: List<&2, GeneratedIdentity>, v_19: List<&2, TemplateDef>) -> TemplateProgress<GeneratedBuild>:
  match v_18:
    case TemplateDef{v_27, _, _, _, _, _, _}:
      v_1000805 = {v_1 : String}
      v_1000806 = {v_3 : String}
      v_1000807 = {v_5 : List<&2, Ast.TopLevel>}
      v_1000808 = {v_8 : List<&2, TemplateDef>}
      v_1000809 = {v_11 : List<&2, ActualModule>}
      v_1000810 = {v_14 : List<&2, GeneratedIdentity>}
      v_1000811 = {v_18 : TemplateDef}
      v_1000812 = {v_27 : String}
      v_1000813 = {v_19 : List<&2, TemplateDef>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_template_owned_by_module{v_1, v_3, v_5, v_18}}, False{}, v_1000816 => template_body_template_owned_by_module(v_1, v_3, v_5, v_18), +v_1000814 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_for_module_match{v_1000805, v_1000806, v_1000807, v_1000808, v_1000809, v_1000810, v_1000811, v_1000812, v_1000813, v_1000814}}, +v_1000815 => TemplateFinished{v_1000815}}}

def template_match_199(+v_8: List<&2, TemplateDef>, v_14: List<&2, GeneratedIdentity>, v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_11: List<&2, ActualModule>) -> TemplateProgress<GeneratedBuild>:
  match v_8:
    case []:
      TemplateFinished{GeneratedBuild{[], v_14, None{}}}
    case +v_18 <> v_19:
      template_match_198(v_18, v_1, v_3, v_5, v_8, v_11, v_14, v_19)

def template_body_generated_for_module(v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, v_11: List<&2, ActualModule>, v_14: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedBuild>:
  template_match_199(v_8, v_14, v_1, v_3, v_5, v_11)

def template_match_200(v_23: Bool, v_1: String, v_3: String, +v_5: List<&2, Ast.TopLevel>, v_21: List<&2, TemplateDef>, +v_11: List<&2, ActualModule>, +v_14: List<&2, GeneratedIdentity>, +v_8: List<&2, TemplateDef>, v_16: TemplateDef, v_18: String) -> TemplateProgress<GeneratedBuild>:
  match v_23:
    case False{}:
      template_body_generated_for_module(v_1, v_3, v_5, v_21, v_11, v_14)
    case True{}:
      v_1000818 = {v_1 : String}
      v_1000819 = {v_3 : String}
      v_1000820 = {v_5 : List<&2, Ast.TopLevel>}
      v_1000821 = {v_8 : List<&2, TemplateDef>}
      v_1000822 = {v_11 : List<&2, ActualModule>}
      v_1000823 = {v_14 : List<&2, GeneratedIdentity>}
      v_1000824 = {v_21 : List<&2, TemplateDef>}
      v_1000825 = {v_16 : TemplateDef}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_actual_in_catalog{v_11, v_18, v_8}}, False{}, v_1000830 => template_body_actual_in_catalog(v_11, v_18, v_8), +v_1000826 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generated_actuals{v_1000825, v_1000826, v_8, v_5, v_14}}, False{}, v_1000829 => template_body_generated_actuals(v_1000825, v_1000826, v_8, v_5, v_14), +v_1000827 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_for_module_here{v_1000818, v_1000819, v_1000820, v_1000821, v_1000822, v_1000823, v_1000824, v_1000827}}, +v_1000828 => TemplateFinished{v_1000828}}}}

def template_body_generated_for_module_match(v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, v_11: List<&2, ActualModule>, v_14: List<&2, GeneratedIdentity>, v_16: TemplateDef, v_18: String, v_21: List<&2, TemplateDef>, v_23: Bool) -> TemplateProgress<GeneratedBuild>:
  template_match_200(v_23, v_1, v_3, v_5, v_21, v_11, v_14, v_8, v_16, v_18)

def template_match_201(v_19: GeneratedBuild, v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_17: List<&2, TemplateDef>, v_11: List<&2, ActualModule>) -> TemplateProgress<GeneratedBuild>:
  match v_19:
    case GeneratedBuild{v_24, v_25, Some{v_26}}:
      TemplateFinished{GeneratedBuild{v_24, v_25, Some{v_26}}}
    case GeneratedBuild{v_29, v_30, None{}}:
      v_1000831 = {v_29 : List<&2, Ast.TopLevel>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generated_for_module{v_1, v_3, v_5, v_17, v_11, v_30}}, False{}, v_1000834 => template_body_generated_for_module(v_1, v_3, v_5, v_17, v_11, v_30), +v_1000832 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_generated_for_module_merge{v_1000831, v_1000832}}, +v_1000833 => TemplateFinished{v_1000833}}}

def template_body_generated_for_module_here(v_1: String, v_3: String, v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, v_11: List<&2, ActualModule>, v_14: List<&2, GeneratedIdentity>, v_17: List<&2, TemplateDef>, v_19: GeneratedBuild) -> TemplateProgress<GeneratedBuild>:
  template_match_201(v_19, v_1, v_3, v_5, v_17, v_11)

def template_match_202(v_3: GeneratedBuild, v_1: List<&2, Ast.TopLevel>) -> TemplateProgress<GeneratedBuild>:
  match v_3:
    case GeneratedBuild{v_8, v_9, v_10}:
      TemplateFinished{GeneratedBuild{List.append(&2, Ast.TopLevel, v_1, v_8), v_9, v_10}}

def template_body_generated_for_module_merge(v_1: List<&2, Ast.TopLevel>, v_3: GeneratedBuild) -> TemplateProgress<GeneratedBuild>:
  template_match_202(v_3, v_1)

def template_match_203(+v_4: List<&2, TemplateDef>, +v_1: List<&2, Loader.LoadedModule>, v_7: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedRound>:
  match v_4:
    case []:
      TemplateFinished{GeneratedRound{v_1, False{}, v_7, None{}}}
    case +_ <> _:
      v_1000835 = {v_1 : List<&2, Loader.LoadedModule>}
      TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_collect_actual_modules{v_1, v_1}}, False{}, v_1000838 => template_body_collect_actual_modules(v_1, v_1), +v_1000836 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_generate_scoped_round{v_1000835, v_1000836, v_4, v_7}}, +v_1000837 => TemplateFinished{v_1000837}}}

def template_body_generate_round(v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_7: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedRound>:
  template_match_203(v_4, v_1, v_7)

def template_match_204(+v_14: Loader.LoadedModule, v_15: List<&2, Loader.LoadedModule>, +v_4: List<&2, ActualModule>, +v_7: List<&2, TemplateDef>, v_10: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedRound>:
  match v_14:
    case Loader.LoadedModule{+v_20, Ast.Module{+v_21, v_22, +v_23}}:
      v_1000839 = {v_20 : String}
      v_1000840 = {v_21 : String}
      v_1000841 = {v_22 : List<&2, Ast.ModuleImport>}
      v_1000842 = {v_23 : List<&2, Ast.TopLevel>}
      v_1000843 = {v_15 : List<&2, Loader.LoadedModule>}
      v_1000844 = {v_4 : List<&2, ActualModule>}
      v_1000845 = {v_7 : List<&2, TemplateDef>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generated_for_module{v_20, v_21, v_23, v_7, v_4, v_10}}, False{}, v_1000848 => template_body_generated_for_module(v_20, v_21, v_23, v_7, v_4, v_10), +v_1000846 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_generate_round_loaded{v_1000839, v_1000840, v_1000841, v_1000842, v_1000843, v_1000844, v_1000845, v_1000846}}, +v_1000847 => TemplateFinished{v_1000847}}}

def template_match_205(v_1: List<&2, Loader.LoadedModule>, v_10: List<&2, GeneratedIdentity>, v_4: List<&2, ActualModule>, v_7: List<&2, TemplateDef>) -> TemplateProgress<GeneratedRound>:
  match v_1:
    case []:
      TemplateFinished{GeneratedRound{[], False{}, v_10, None{}}}
    case +v_14 <> v_15:
      template_match_204(v_14, v_15, v_4, v_7, v_10)

def template_body_generate_scoped_round(v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, ActualModule>, v_7: List<&2, TemplateDef>, v_10: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedRound>:
  template_match_205(v_1, v_10, v_4, v_7)

def template_match_206(v_17: GeneratedBuild, v_1: String, v_3: String, v_5: List<&2, Ast.ModuleImport>, v_7: List<&2, Ast.TopLevel>, v_9: List<&2, Loader.LoadedModule>, v_12: List<&2, ActualModule>, v_15: List<&2, TemplateDef>) -> TemplateProgress<GeneratedRound>:
  match v_17:
    case GeneratedBuild{v_22, v_23, v_24}:
      v_1000849 = {v_1 : String}
      v_1000850 = {v_3 : String}
      v_1000851 = {v_5 : List<&2, Ast.ModuleImport>}
      v_1000852 = {v_7 : List<&2, Ast.TopLevel>}
      v_1000853 = {v_22 : List<&2, Ast.TopLevel>}
      v_1000854 = {v_24 : Maybe<&2, Ast.SourceSpan>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generate_scoped_round{v_9, v_12, v_15, v_23}}, False{}, v_1000857 => template_body_generate_scoped_round(v_9, v_12, v_15, v_23), +v_1000855 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_generate_round_merge{v_1000849, v_1000850, v_1000851, v_1000852, v_1000853, v_1000854, v_1000855}}, +v_1000856 => TemplateFinished{v_1000856}}}

def template_body_generate_round_loaded(v_1: String, v_3: String, v_5: List<&2, Ast.ModuleImport>, v_7: List<&2, Ast.TopLevel>, v_9: List<&2, Loader.LoadedModule>, v_12: List<&2, ActualModule>, v_15: List<&2, TemplateDef>, v_17: GeneratedBuild) -> TemplateProgress<GeneratedRound>:
  template_match_206(v_17, v_1, v_3, v_5, v_7, v_9, v_12, v_15)

def template_match_207(v_13: GeneratedRound, v_1: String, v_3: String, v_5: List<&2, Ast.ModuleImport>, v_7: List<&2, Ast.TopLevel>, +v_9: List<&2, Ast.TopLevel>, v_11: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<GeneratedRound>:
  match v_13:
    case GeneratedRound{v_19, v_20, v_21, v_22}:
      v_1000858 = {Loader.LoadedModule{v_1, Ast.Module{v_3, v_5, List.append(&2, Ast.TopLevel, v_7, v_9)}} <> v_19 : List<&2, Loader.LoadedModule>}
      v_1000859 = {Bool.or(v_20, Bool.not(List.is_empty(&2, Ast.TopLevel, v_9))) : Bool}
      v_1000860 = {v_21 : List<&2, GeneratedIdentity>}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_11, v_22}}, +v_1000861 => TemplateFinished{GeneratedRound{v_1000858, v_1000859, v_1000860, v_1000861}}}

def template_body_generate_round_merge(v_1: String, v_3: String, v_5: List<&2, Ast.ModuleImport>, v_7: List<&2, Ast.TopLevel>, v_9: List<&2, Ast.TopLevel>, v_11: Maybe<&2, Ast.SourceSpan>, v_13: GeneratedRound) -> TemplateProgress<GeneratedRound>:
  template_match_207(v_13, v_1, v_3, v_5, v_7, v_9, v_11)

def template_body_generate_until_stable(v_1: List<&2, Loader.LoadedModule>, +v_4: List<&2, TemplateDef>, v_7: List<&2, GeneratedIdentity>) -> TemplateProgress<GeneratedRound>:
  v_1000862 = {v_4 : List<&2, TemplateDef>}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generate_round{v_1, v_4, v_7}}, False{}, v_1000865 => template_body_generate_round(v_1, v_4, v_7), +v_1000863 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_generate_until_result{v_1000862, v_1000863}}, +v_1000864 => TemplateFinished{v_1000864}}}

def template_match_208(v_4: GeneratedRound, v_2: List<&2, TemplateDef>) -> TemplateProgress<GeneratedRound>:
  match v_4:
    case GeneratedRound{v_10, _, v_12, Some{v_13}}:
      TemplateFinished{GeneratedRound{v_10, False{}, v_12, Some{v_13}}}
    case GeneratedRound{v_16, True{}, v_17, None{}}:
      template_body_generate_until_stable(v_16, v_2, v_17)
    case GeneratedRound{v_21, False{}, v_22, None{}}:
      TemplateFinished{GeneratedRound{v_21, False{}, v_22, None{}}}

def template_body_generate_until_result(v_2: List<&2, TemplateDef>, v_4: GeneratedRound) -> TemplateProgress<GeneratedRound>:
  template_match_208(v_4, v_2)

def template_body_visible_templates(+v_1: String, v_3: List<&2, Ast.ModuleImport>, +v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_local_templates{v_1, v_6}}, +v_1000867 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_imported_templates{v_1, v_3, v_6}}, +v_1000868 => TemplateFinished{List.append(&2, TemplateDef, v_1000867, List.append(&2, TemplateDef, v_1000868, v_6))}}}

def template_match_209(+v_9: TemplateDef, +v_1: String, v_10: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_9:
    case TemplateDef{v_18, +v_19, v_20, v_21, _, v_23, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_local_template_match{v_1, v_10, v_18, v_19, v_20, v_21, v_23, String.eq(v_1, v_19)}}, +v_1000869 => TemplateFinished{v_1000869}}

def template_match_210(v_4: List<&2, TemplateDef>, v_1: String) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_4:
    case []:
      TemplateFinished{[]}
    case +v_9 <> v_10:
      template_match_209(v_9, v_1, v_10)

def template_body_local_templates(v_1: String, v_4: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  template_match_210(v_4, v_1)

def template_match_211(v_16: Bool, +v_6: String, +v_8: String, v_10: List<&2, Ast.ModuleImport>, v_13: List<&2, String>, v_1: String, v_4: List<&2, TemplateDef>, v_14: Ast.Definition) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_16:
    case True{}:
      v_1000870 = {v_6 : String}
      v_1000871 = {v_8 : String}
      v_1000872 = {v_10 : List<&2, Ast.ModuleImport>}
      v_1000873 = {v_13 : List<&2, String>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_strip_namespace{v_6, v_8}}, False{}, v_1000877 => template_body_strip_namespace(v_6, v_8), +v_1000874 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_local_templates{v_1, v_4}}, False{}, v_1000876 => template_body_local_templates(v_1, v_4), +v_1000875 => TemplateFinished{TemplateDef{v_1000870, v_1000871, v_1000872, v_1000873, v_1000874, v_14, []} <> v_1000875}}}
    case False{}:
      template_body_local_templates(v_1, v_4)

def template_body_local_template_match(v_1: String, v_4: List<&2, TemplateDef>, v_6: String, v_8: String, v_10: List<&2, Ast.ModuleImport>, v_13: List<&2, String>, v_14: Ast.Definition, v_16: Bool) -> TemplateProgress<List<&2, TemplateDef>>:
  template_match_211(v_16, v_6, v_8, v_10, v_13, v_1, v_4, v_14)

def template_match_212(+v_11: Ast.ModuleImport, +v_1: String, +v_6: List<&2, TemplateDef>, v_12: List<&2, Ast.ModuleImport>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_11:
    case Ast.ModuleImport{v_16, v_17, _}:
      v_20 = Path.namespace(v_1, v_16)
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_imported_from{v_20, v_17, v_6}}, +v_1000879 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_imported_templates{v_1, v_12, v_6}}, +v_1000880 => TemplateFinished{List.append(&2, TemplateDef, v_1000879, v_1000880)}}}

def template_match_213(v_3: List<&2, Ast.ModuleImport>, v_1: String, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_3:
    case []:
      TemplateFinished{[]}
    case +v_11 <> v_12:
      template_match_212(v_11, v_1, v_6, v_12)

def template_body_imported_templates(v_1: String, v_3: List<&2, Ast.ModuleImport>, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  template_match_213(v_3, v_1, v_6)

def template_match_214(+v_11: TemplateDef, +v_1: String, v_3: String, v_12: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_11:
    case TemplateDef{v_20, +v_21, v_22, v_23, _, v_25, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_imported_from_match{v_1, v_3, v_12, v_20, v_21, v_22, v_23, v_25, String.eq(v_1, v_21)}}, +v_1000881 => TemplateFinished{v_1000881}}

def template_match_215(v_6: List<&2, TemplateDef>, v_1: String, v_3: String) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_6:
    case []:
      TemplateFinished{[]}
    case +v_11 <> v_12:
      template_match_214(v_11, v_1, v_3, v_12)

def template_body_imported_from(v_1: String, v_3: String, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  template_match_215(v_6, v_1, v_3)

def template_continuation_216(+v_1000882: String, v_8: String, v_10: String, v_12: List<&2, Ast.ModuleImport>, v_15: List<&2, String>, +v_3: String, v_16: Ast.Definition, v_1: String, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  v_23 = v_1000882
  v_1000883 = {TemplateDef{v_8, v_10, v_12, v_15, String.append(v_3, String.append(".", v_23)), v_16, []} : TemplateDef}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_imported_from{v_1, v_3, v_6}}, False{}, v_1000885 => template_body_imported_from(v_1, v_3, v_6), +v_1000884 => TemplateFinished{v_1000883 <> v_1000884}}

def template_match_217(v_18: Bool, +v_8: String, +v_10: String, v_12: List<&2, Ast.ModuleImport>, v_15: List<&2, String>, v_3: String, v_16: Ast.Definition, v_1: String, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, TemplateDef>>:
  match v_18:
    case True{}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_strip_namespace{v_8, v_10}}, False{}, v_1000886 => template_body_strip_namespace(v_8, v_10), +v_1000882 => template_continuation_216(v_1000882, v_8, v_10, v_12, v_15, v_3, v_16, v_1, v_6)}
    case False{}:
      template_body_imported_from(v_1, v_3, v_6)

def template_body_imported_from_match(v_1: String, v_3: String, v_6: List<&2, TemplateDef>, v_8: String, v_10: String, v_12: List<&2, Ast.ModuleImport>, v_15: List<&2, String>, v_16: Ast.Definition, v_18: Bool) -> TemplateProgress<List<&2, TemplateDef>>:
  template_match_217(v_18, v_8, v_10, v_12, v_15, v_3, v_16, v_1, v_6)

def template_body_expand_modules(+v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_7: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_expand_scoped_modules{v_1, v_1, v_4, v_7}}, +v_1000888 => TemplateFinished{v_1000888}}

def template_continuation_218(+v_1000890: List<&2, Ast.TopLevel>, v_19: String, v_20: String, v_21: List<&2, Ast.ModuleImport>, v_14: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  v_28 = v_1000890
  v_1000891 = {Loader.LoadedModule{v_19, Ast.Module{v_20, v_21, v_28}} : Loader.LoadedModule}
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_expand_scoped_modules{v_14, v_3, v_6, v_9}}, +v_1000892 => TemplateFinished{v_1000891 <> v_1000892}}

def template_continuation_219(+v_1000889: List<&2, TemplateDef>, +v_19: String, v_22: List<&2, Ast.TopLevel>, +v_9: List<&2, GeneratedIdentity>, v_20: String, v_21: List<&2, Ast.ModuleImport>, v_14: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  v_25 = v_1000889
  TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_strip_template_decls{v_19, v_22, v_25, v_9}}, False{}, v_1000893 => template_body_strip_template_decls(v_19, v_22, v_25, v_9), +v_1000890 => template_continuation_218(v_1000890, v_19, v_20, v_21, v_14, v_3, v_6, v_9)}

def template_match_220(+v_13: Loader.LoadedModule, +v_6: List<&2, TemplateDef>, +v_3: List<&2, Loader.LoadedModule>, v_9: List<&2, GeneratedIdentity>, v_14: List<&2, Loader.LoadedModule>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  match v_13:
    case Loader.LoadedModule{+v_19, Ast.Module{v_20, +v_21, v_22}}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_scoped_templates{v_19, v_21, v_6, v_3}}, False{}, v_1000894 => template_body_scoped_templates(v_19, v_21, v_6, v_3), +v_1000889 => template_continuation_219(v_1000889, v_19, v_22, v_9, v_20, v_21, v_14, v_3, v_6)}

def template_match_221(v_1: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>, v_3: List<&2, Loader.LoadedModule>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  match v_1:
    case []:
      TemplateFinished{[]}
    case +v_13 <> v_14:
      template_match_220(v_13, v_6, v_3, v_9, v_14)

def template_body_expand_scoped_modules(v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>, v_9: List<&2, GeneratedIdentity>) -> TemplateProgress<List<&2, Loader.LoadedModule>>:
  template_match_221(v_1, v_6, v_3, v_9)

def template_match_222(+v_7: Ast.TelescopeItem, +v_3: Bool, v_8: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Bool>:
  match v_7:
    case Ast.TemplateBinder{_, _, _, _}:
      v_1000895 = {v_3 : Bool}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_late_template_binder{v_8, v_3}}, +v_1000896 => TemplateFinished{Bool.or(v_1000895, v_1000896)}}
    case Ast.Binder{_, _, _, _, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_late_template_binder{v_8, True{}}}, +v_1000897 => TemplateFinished{v_1000897}}

def template_body_has_late_template_binder(v_1: List<&2, Ast.TelescopeItem>, v_3: Bool) -> TemplateProgress<Bool>:
  match v_1:
    case []:
      TemplateFinished{False{}}
    case +v_7 <> v_8:
      template_match_222(v_7, v_3, v_8)

def template_match_224(+v_5: Loader.LoadedModule, v_6: List<&2, Loader.LoadedModule>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_5:
    case Loader.LoadedModule{_, Ast.Module{_, _, v_14}}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_decls{v_14}}, +v_1000898 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_definitions{v_6}}, +v_1000899 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000898, v_1000899}}, +v_1000900 => TemplateFinished{v_1000900}}}}

def template_body_invalid_template_definitions(v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{None{}}
    case +v_5 <> v_6:
      template_match_224(v_5, v_6)

def template_match_226(+v_5: Ast.TopLevel, v_6: List<&2, Ast.TopLevel>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_5:
    case Ast.DefTop{Ast.Definition{_, +v_14, _, _, _, v_18}}:
      v_1000901 = {v_14 : List<&2, Ast.TelescopeItem>}
      v_1000902 = {v_18 : Ast.SourceSpan}
      v_1000903 = {v_6 : List<&2, Ast.TopLevel>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_has_late_template_binder{v_14, False{}}}, False{}, v_1000906 => template_body_has_late_template_binder(v_14, False{}), +v_1000904 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_decl{v_1000901, v_1000902, v_1000903, v_1000904}}, +v_1000905 => TemplateFinished{v_1000905}}}
    case _:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_decls{v_6}}, +v_1000907 => TemplateFinished{v_1000907}}

def template_body_invalid_template_decls(v_1: List<&2, Ast.TopLevel>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{None{}}
    case +v_5 <> v_6:
      template_match_226(v_5, v_6)

def template_match_228(v_6: Bool, v_2: Ast.SourceSpan, v_4: List<&2, Ast.TopLevel>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_6:
    case True{}:
      TemplateFinished{Some{v_2}}
    case False{}:
      template_body_invalid_template_decls(v_4)

def template_body_invalid_template_decl(v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.SourceSpan, v_4: List<&2, Ast.TopLevel>, v_6: Bool) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_228(v_6, v_2, v_4)

def template_match_229(+v_0: Ast.SyntaxTerm, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_0:
    case Ast.TermRef{v_7, v_8}:
      v_1000909 = {v_8 : Ast.SourceSpan}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_find_template{v_7, v_3}}, False{}, v_1000912 => template_body_find_template(v_7, v_3), +v_1000910 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_reference{v_1000909, v_1000910}}, +v_1000911 => TemplateFinished{v_1000911}}}
    case Ast.TermApp{_, _, _}:
      v_1000913 = {v_0 : Ast.SyntaxTerm}
      v_1000914 = {v_3 : List<&2, TemplateDef>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_flatten_application{v_0}}, False{}, v_1000917 => template_body_flatten_application(v_0), +v_1000915 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application_spine{v_1000913, v_1000914, v_1000915}}, +v_1000916 => TemplateFinished{v_1000916}}}
    case Ast.TermTemplate{v_21, v_22}:
      v_1000918 = {Some{v_22} : Maybe<&2, Ast.SourceSpan>}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_21, v_3}}, +v_1000919 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000918, v_1000919}}, +v_1000920 => TemplateFinished{v_1000920}}}
    case Ast.TermBang{v_27, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_27, v_3}}, +v_1000921 => TemplateFinished{v_1000921}}
    case Ast.TermSub{_, v_35, v_36, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_35, v_3}}, +v_1000922 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_36, v_3}}, +v_1000923 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000922, v_1000923}}, +v_1000924 => TemplateFinished{v_1000924}}}}
    case Ast.TermLet{_, _, _, v_50, v_51, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_50, v_3}}, +v_1000925 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_51, v_3}}, +v_1000926 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000925, v_1000926}}, +v_1000927 => TemplateFinished{v_1000927}}}}
    case Ast.TermAnn{v_59, v_60, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_59, v_3}}, +v_1000928 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_60, v_3}}, +v_1000929 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000928, v_1000929}}, +v_1000930 => TemplateFinished{v_1000930}}}}
    case Ast.TermType{v_67, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_67, v_3}}, +v_1000931 => TemplateFinished{v_1000931}}
    case Ast.TermMin{v_73, v_74, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_73, v_3}}, +v_1000932 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_74, v_3}}, +v_1000933 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000932, v_1000933}}, +v_1000934 => TemplateFinished{v_1000934}}}}
    case Ast.TermAll{_, _, _, v_88, v_89, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_88, v_3}}, +v_1000935 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_89, v_3}}, +v_1000936 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000935, v_1000936}}, +v_1000937 => TemplateFinished{v_1000937}}}}
    case Ast.TermLam{_, _, _, v_102, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_102, v_3}}, +v_1000938 => TemplateFinished{v_1000938}}
    case Ast.TermAdt{_, v_110, _, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_110, v_3}}, +v_1000939 => TemplateFinished{v_1000939}}
    case Ast.TermFill{v_117, v_118, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_117, v_3}}, +v_1000940 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_118, v_3}}, +v_1000941 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000940, v_1000941}}, +v_1000942 => TemplateFinished{v_1000942}}}}
    case Ast.TermPlus{v_126, v_127, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_126, v_3}}, +v_1000943 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_127, v_3}}, +v_1000944 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000943, v_1000944}}, +v_1000945 => TemplateFinished{v_1000945}}}}
    case Ast.TermCtr{_, v_136, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_136, v_3}}, +v_1000946 => TemplateFinished{v_1000946}}
    case Ast.TermString{_, _, _}:
      TemplateFinished{None{}}
    case Ast.TermMat{_, v_150, v_151, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_150, v_3}}, +v_1000947 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_151, v_3}}, +v_1000948 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000947, v_1000948}}, +v_1000949 => TemplateFinished{v_1000949}}}}
    case Ast.TermEqual{v_160, v_161, v_162, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_160, v_3}}, +v_1000950 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_161, v_3}}, +v_1000951 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_162, v_3}}, +v_1000952 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000951, v_1000952}}, +v_1000953 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000950, v_1000953}}, +v_1000954 => TemplateFinished{v_1000954}}}}}}
    case Ast.TermRewrite{v_173, v_174, v_175, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_173, v_3}}, +v_1000955 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_174, v_3}}, +v_1000956 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_175, v_3}}, +v_1000957 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000956, v_1000957}}, +v_1000958 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000955, v_1000958}}, +v_1000959 => TemplateFinished{v_1000959}}}}}}
    case Ast.BodyMatch{v_185, v_186, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_185, v_3}}, +v_1000960 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_186, v_3}}, +v_1000961 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000960, v_1000961}}, +v_1000962 => TemplateFinished{v_1000962}}}}
    case Ast.BodyCase{_, v_195, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_195, v_3}}, +v_1000963 => TemplateFinished{v_1000963}}
    case Ast.BodyLocal{_, _, v_205, v_206, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_205, v_3}}, +v_1000964 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_206, v_3}}, +v_1000965 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000964, v_1000965}}, +v_1000966 => TemplateFinished{v_1000966}}}}
    case Ast.BodyReply{v_213, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application{v_213, v_3}}, +v_1000967 => TemplateFinished{v_1000967}}
    case _:
      TemplateFinished{None{}}

def template_body_invalid_application(v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_229(v_0, v_3)

def template_match_230(v_3: Maybe<&2, TemplateDef>, v_0: Ast.SourceSpan) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_3:
    case Some{_}:
      TemplateFinished{Some{v_0}}
    case None{}:
      TemplateFinished{None{}}

def template_body_invalid_reference(v_0: Ast.SourceSpan, v_3: Maybe<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_230(v_3, v_0)

def template_match_231(v_5: ApplicationSpine, v_0: Ast.SyntaxTerm, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_5:
    case ApplicationSpine{+v_10, v_11, v_12}:
      v_1000968 = {v_0 : Ast.SyntaxTerm}
      v_1000969 = {v_3 : List<&2, TemplateDef>}
      v_1000970 = {v_10 : Ast.SyntaxTerm}
      v_1000971 = {v_11 : List<&2, Ast.SyntaxTerm>}
      v_1000972 = {v_12 : Ast.SourceSpan}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_template_for_head{v_10, v_3}}, False{}, v_1000975 => template_body_template_for_head(v_10, v_3), +v_1000973 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application_head{v_1000968, v_1000969, v_1000970, v_1000971, v_1000972, v_1000973}}, +v_1000974 => TemplateFinished{v_1000974}}}

def template_body_invalid_application_spine(v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>, v_5: ApplicationSpine) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_231(v_5, v_0, v_3)

def template_continuation_232(+v_1000976: Nat, +v_6: List<&2, Ast.SyntaxTerm>, v_7: Ast.SourceSpan, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  +v_16 = v_1000976
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application_arity{v_6, v_16, v_7, v_3, Nat.is_ge(List.length(&2, Ast.SyntaxTerm, v_6), v_16)}}, +v_1000977 => TemplateFinished{v_1000977}}

def template_match_233(v_10: Maybe<&2, TemplateDef>, v_6: List<&2, Ast.SyntaxTerm>, v_7: Ast.SourceSpan, v_3: List<&2, TemplateDef>, v_0: Ast.SyntaxTerm) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_10:
    case Some{v_13}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_template_arity{v_13}}, False{}, v_1000978 => template_body_template_arity(v_13), +v_1000976 => template_continuation_232(v_1000976, v_6, v_7, v_3)}
    case None{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application_parts{v_0, v_3}}, +v_1000979 => TemplateFinished{v_1000979}}

def template_body_invalid_application_head(v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>, v_4: Ast.SyntaxTerm, v_6: List<&2, Ast.SyntaxTerm>, v_7: Ast.SourceSpan, v_10: Maybe<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_233(v_10, v_6, v_7, v_3, v_0)

def template_match_234(v_9: Bool, v_4: Ast.SourceSpan, +v_1: List<&2, Ast.SyntaxTerm>, +v_3: Nat, v_7: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_9:
    case False{}:
      TemplateFinished{Some{v_4}}
    case True{}:
      v_1000980 = {v_1 : List<&2, Ast.SyntaxTerm>}
      v_1000981 = {v_3 : Nat}
      v_1000982 = {v_4 : Ast.SourceSpan}
      v_1000983 = {v_7 : List<&2, TemplateDef>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_take_template_args{v_1, v_3}}, False{}, v_1000986 => template_body_take_template_args(v_1, v_3), +v_1000984 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_application_arguments{v_1000980, v_1000981, v_1000982, v_1000983, v_1000984}}, +v_1000985 => TemplateFinished{v_1000985}}}

def template_body_invalid_application_arity(v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat, v_4: Ast.SourceSpan, v_7: List<&2, TemplateDef>, v_9: Bool) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_234(v_9, v_4, v_1, v_3, v_7)

def template_match_235(v_10: Maybe<&2, List<&2, Ast.SyntaxTerm>>, v_4: Ast.SourceSpan, +v_1: List<&2, Ast.SyntaxTerm>, +v_3: Nat, +v_7: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_10:
    case None{}:
      TemplateFinished{Some{v_4}}
    case Some{_}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_args{v_1, v_3, v_4, v_7}}, +v_1000987 => TemplateDirect{Bool, TemplateRequestGroup_1{TemplateRequest_drop_args{v_1, v_3}}, False{}, v_1000991 => template_body_drop_args(v_1, v_3), +v_1000988 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_1000988, v_7}}, +v_1000989 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000987, v_1000989}}, +v_1000990 => TemplateFinished{v_1000990}}}}}

def template_body_invalid_application_arguments(v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat, v_4: Ast.SourceSpan, v_7: List<&2, TemplateDef>, v_10: Maybe<&2, List<&2, Ast.SyntaxTerm>>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_235(v_10, v_4, v_1, v_3, v_7)

def template_match_236(v_0: Ast.SyntaxTerm, +v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_0:
    case Ast.TermApp{v_8, v_9, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_8, v_3}}, False{}, v_1000996 => template_body_invalid_application(v_8, v_3), +v_1000992 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_9, v_3}}, False{}, v_1000995 => template_body_invalid_application(v_9, v_3), +v_1000993 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1000992, v_1000993}}, +v_1000994 => TemplateFinished{v_1000994}}}}
    case _:
      TemplateFinished{None{}}

def template_body_invalid_application_parts(v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_236(v_0, v_3)

def template_body_invalid_template_args(v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat, v_4: Ast.SourceSpan, v_7: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1, v_3:
    case _, 0n:
      TemplateFinished{None{}}
    case Ast.TermTemplate{+v_15, _} <> v_17, 1n+v_18:
      v_1000997 = {v_15 : Ast.SyntaxTerm}
      v_1000998 = {v_17 : List<&2, Ast.SyntaxTerm>}
      v_1000999 = {Nat.add(1n, v_18) : Nat}
      v_1001000 = {v_4 : Ast.SourceSpan}
      v_1001001 = {v_7 : List<&2, TemplateDef>}
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_15, 0n}}, +v_1001002 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_template_argument{v_1000997, v_1000998, v_1000999, v_1001000, v_1001001, v_1001002}}, +v_1001003 => TemplateFinished{v_1001003}}}
    case _, _:
      TemplateFinished{Some{v_4}}

def template_match_238(v_10: Bool, v_5: Ast.SourceSpan, +v_0: Ast.SyntaxTerm, +v_8: List<&2, TemplateDef>, v_2: List<&2, Ast.SyntaxTerm>, v_4: Nat) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_10:
    case True{}:
      TemplateFinished{Some{v_5}}
    case False{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_0, v_8}}, False{}, v_1001010 => template_body_invalid_application(v_0, v_8), +v_1001004 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_context{v_0, v_8}}, +v_1001005 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001004, v_1001005}}, +v_1001006 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_template_args{v_2, Nat.sub(v_4, 1n), v_5, v_8}}, False{}, v_1001009 => template_body_invalid_template_args(v_2, Nat.sub(v_4, 1n), v_5, v_8), +v_1001007 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001006, v_1001007}}, +v_1001008 => TemplateFinished{v_1001008}}}}}}

def template_body_invalid_template_argument(v_0: Ast.SyntaxTerm, v_2: List<&2, Ast.SyntaxTerm>, v_4: Nat, v_5: Ast.SourceSpan, v_8: List<&2, TemplateDef>, v_10: Bool) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_238(v_10, v_5, v_0, v_8, v_2, v_4)

def template_match_239(v_3: List<&2, TemplateDef>, v_0: Ast.SyntaxTerm) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_3:
    case []:
      TemplateFinished{None{}}
    case +v_7 <> _:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_0, template_pure_template_capture_names(v_7)}}, +v_1001011 => TemplateFinished{v_1001011}}

def template_body_invalid_capture_context(v_0: Ast.SyntaxTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_239(v_3, v_0)

def template_match_240(+v_1001012: Maybe<&2, String>, v_4: Ast.SourceSpan) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1001012:
    case Some{_}:
      TemplateFinished{None{}}
    case None{}:
      TemplateFinished{Some{v_4}}

def template_body_invalid_capture_key(v_1: String, v_3: Bool, v_4: Ast.SourceSpan, v_7: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_capture_name{v_1, v_3, v_7, None{}}}, False{}, v_1001013 => template_body_capture_name(v_1, v_3, v_7, None{}), +v_1001012 => template_match_240(v_1001012, v_4)}

def template_match_241(v_2: List<&2, String>, +v_3: Ast.SourceSpan, +v_6: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_2:
    case []:
      TemplateFinished{None{}}
    case +v_10 <> v_11:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_10, True{}, v_3, v_6}}, False{}, v_1001017 => template_body_invalid_capture_key(v_10, True{}, v_3, v_6), +v_1001014 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_strings{v_11, v_3, v_6}}, +v_1001015 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001014, v_1001015}}, +v_1001016 => TemplateFinished{v_1001016}}}}

def template_body_invalid_capture_strings(v_2: List<&2, String>, v_3: Ast.SourceSpan, v_6: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_241(v_2, v_3, v_6)

def template_match_242(v_1: List<&2, Ast.SyntaxPattern>, +v_4: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{None{}}
    case Ast.PatternVar{_, _, _, _} <> v_15:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_patterns{v_15, v_4}}, +v_1001018 => TemplateFinished{v_1001018}}
    case Ast.PatternCtr{v_21, v_22, v_23} <> v_24:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_21, True{}, v_23, v_4}}, False{}, v_1001024 => template_body_invalid_capture_key(v_21, True{}, v_23, v_4), +v_1001019 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_patterns{v_22, v_4}}, +v_1001020 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_patterns{v_24, v_4}}, +v_1001021 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001020, v_1001021}}, +v_1001022 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001019, v_1001022}}, +v_1001023 => TemplateFinished{v_1001023}}}}}}

def template_body_invalid_capture_patterns(v_1: List<&2, Ast.SyntaxPattern>, v_4: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_242(v_1, v_4)

def template_match_243(v_1: List<&2, Ast.SyntaxTerm>, +v_4: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{None{}}
    case +v_8 <> v_9:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_8, v_4}}, +v_1001025 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_9, v_4}}, +v_1001026 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001025, v_1001026}}, +v_1001027 => TemplateFinished{v_1001027}}}}

def template_body_invalid_capture_terms(v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_243(v_1, v_4)

def template_body_invalid_capture_string_bit(v_1: Bool, v_2: Ast.StringLiteralNames, v_3: Ast.SourceSpan, v_6: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1, v_2:
    case True{}, Ast.StringLiteralNames{_, _, _, _, _, _, v_22, _}:
      template_body_invalid_capture_key(v_22, True{}, v_3, v_6)
    case False{}, Ast.StringLiteralNames{_, _, _, _, _, _, _, v_40}:
      template_body_invalid_capture_key(v_40, True{}, v_3, v_6)

def template_match_245(v_1: Nat, +v_4: Ast.StringLiteralNames, +v_5: Ast.SourceSpan, +v_8: List<&2, CaptureName>, +v_3: U32) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1, v_4:
    case 0n, Ast.StringLiteralNames{_, _, _, _, v_22, _, _, _}:
      template_body_invalid_capture_key(v_22, True{}, v_5, v_8)
    case 1n+v_36, Ast.StringLiteralNames{_, _, _, _, _, v_42, _, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_42, True{}, v_5, v_8}}, False{}, v_1001037 => template_body_invalid_capture_key(v_42, True{}, v_5, v_8), +v_1001031 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_string_bit{U32.is_zero(U32.and(v_3, 1)), v_4, v_5, v_8}}, False{}, v_1001036 => template_body_invalid_capture_string_bit(U32.is_zero(U32.and(v_3, 1)), v_4, v_5, v_8), +v_1001032 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_string_word{v_36, U32.shr(v_3), v_4, v_5, v_8}}, +v_1001033 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001032, v_1001033}}, +v_1001034 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001031, v_1001034}}, +v_1001035 => TemplateFinished{v_1001035}}}}}}

def template_body_invalid_capture_string_word(v_1: Nat, +v_3: U32, +v_4: Ast.StringLiteralNames, +v_5: Ast.SourceSpan, +v_8: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_245(v_1, v_4, v_5, v_8, v_3)

def template_body_invalid_capture_string(v_2: List<&2, U32>, +v_3: Ast.StringLiteralNames, +v_4: Ast.SourceSpan, +v_7: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_2, v_3:
    case [], Ast.StringLiteralNames{v_17, _, _, _, _, _, _, _}:
      template_body_invalid_capture_key(v_17, True{}, v_4, v_7)
    case v_36 <> v_37, Ast.StringLiteralNames{_, v_39, v_40, v_41, _, _, _, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_39, True{}, v_4, v_7}}, False{}, v_1001051 => template_body_invalid_capture_key(v_39, True{}, v_4, v_7), +v_1001039 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_40, True{}, v_4, v_7}}, False{}, v_1001050 => template_body_invalid_capture_key(v_40, True{}, v_4, v_7), +v_1001040 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_41, True{}, v_4, v_7}}, False{}, v_1001049 => template_body_invalid_capture_key(v_41, True{}, v_4, v_7), +v_1001041 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_string_word{32n, v_36, v_3, v_4, v_7}}, False{}, v_1001048 => template_body_invalid_capture_string_word(32n, v_36, v_3, v_4, v_7), +v_1001042 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture_string{v_37, v_3, v_4, v_7}}, +v_1001043 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001042, v_1001043}}, +v_1001044 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001041, v_1001044}}, +v_1001045 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001040, v_1001045}}, +v_1001046 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001039, v_1001046}}, +v_1001047 => TemplateFinished{v_1001047}}}}}}}}}}

def template_match_247(v_0: Ast.SyntaxTerm, +v_3: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_0:
    case Ast.TermRef{v_7, v_8}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_reference_key{v_7}}, False{}, v_1001054 => template_body_reference_key(v_7), +v_1001052 => template_body_invalid_capture_key(v_1001052, False{}, v_8, v_3)}
    case Ast.TermBang{v_13, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_13, v_3}}, +v_1001055 => TemplateFinished{v_1001055}}
    case Ast.TermSub{_, v_21, v_22, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_21, v_3}}, +v_1001056 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_22, v_3}}, +v_1001057 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001056, v_1001057}}, +v_1001058 => TemplateFinished{v_1001058}}}}
    case Ast.TermLet{_, _, _, v_36, v_37, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_36, v_3}}, False{}, v_1001062 => template_body_invalid_capture_terms(v_36, v_3), +v_1001059 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_37, v_3}}, +v_1001060 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001059, v_1001060}}, +v_1001061 => TemplateFinished{v_1001061}}}}
    case Ast.TermAnn{v_45, v_46, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_45, v_3}}, +v_1001063 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_46, v_3}}, +v_1001064 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001063, v_1001064}}, +v_1001065 => TemplateFinished{v_1001065}}}}
    case Ast.TermTemplate{v_53, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_53, v_3}}, +v_1001066 => TemplateFinished{v_1001066}}
    case Ast.TermType{v_58, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_58, v_3}}, +v_1001067 => TemplateFinished{v_1001067}}
    case Ast.TermMin{v_64, v_65, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_64, v_3}}, +v_1001068 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_65, v_3}}, +v_1001069 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001068, v_1001069}}, +v_1001070 => TemplateFinished{v_1001070}}}}
    case Ast.TermAll{_, _, _, v_79, v_80, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_79, v_3}}, +v_1001071 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_80, v_3}}, +v_1001072 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001071, v_1001072}}, +v_1001073 => TemplateFinished{v_1001073}}}}
    case Ast.TermLam{_, _, _, v_93, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_93, v_3}}, +v_1001074 => TemplateFinished{v_1001074}}
    case Ast.TermApp{v_99, v_100, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_99, v_3}}, +v_1001075 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_100, v_3}}, +v_1001076 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001075, v_1001076}}, +v_1001077 => TemplateFinished{v_1001077}}}}
    case Ast.TermAdt{v_109, v_110, v_111, +v_112}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_109, False{}, v_112, v_3}}, False{}, v_1001085 => template_body_invalid_capture_key(v_109, False{}, v_112, v_3), +v_1001078 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_110, v_3}}, False{}, v_1001084 => template_body_invalid_capture_terms(v_110, v_3), +v_1001079 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_strings{v_111, v_112, v_3}}, False{}, v_1001083 => template_body_invalid_capture_strings(v_111, v_112, v_3), +v_1001080 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001079, v_1001080}}, +v_1001081 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001078, v_1001081}}, +v_1001082 => TemplateFinished{v_1001082}}}}}}
    case Ast.TermFill{v_121, v_122, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_121, v_3}}, +v_1001086 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_122, v_3}}, False{}, v_1001089 => template_body_invalid_capture_terms(v_122, v_3), +v_1001087 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001086, v_1001087}}, +v_1001088 => TemplateFinished{v_1001088}}}}
    case Ast.TermPlus{v_130, v_131, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_130, v_3}}, +v_1001090 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_131, v_3}}, False{}, v_1001093 => template_body_invalid_capture_terms(v_131, v_3), +v_1001091 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001090, v_1001091}}, +v_1001092 => TemplateFinished{v_1001092}}}}
    case Ast.TermCtr{v_139, v_140, v_141}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_139, True{}, v_141, v_3}}, False{}, v_1001098 => template_body_invalid_capture_key(v_139, True{}, v_141, v_3), +v_1001094 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_140, v_3}}, False{}, v_1001097 => template_body_invalid_capture_terms(v_140, v_3), +v_1001095 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001094, v_1001095}}, +v_1001096 => TemplateFinished{v_1001096}}}}
    case Ast.TermString{v_148, v_149, v_150}:
      template_body_invalid_capture_string(v_148, v_149, v_150, v_3)
    case Ast.TermMat{v_156, v_157, v_158, v_159}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_key{v_156, True{}, v_159, v_3}}, False{}, v_1001105 => template_body_invalid_capture_key(v_156, True{}, v_159, v_3), +v_1001100 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_157, v_3}}, +v_1001101 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_158, v_3}}, +v_1001102 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001101, v_1001102}}, +v_1001103 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001100, v_1001103}}, +v_1001104 => TemplateFinished{v_1001104}}}}}}
    case Ast.TermEqual{v_169, v_170, v_171, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_169, v_3}}, +v_1001106 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_170, v_3}}, +v_1001107 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_171, v_3}}, +v_1001108 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001107, v_1001108}}, +v_1001109 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001106, v_1001109}}, +v_1001110 => TemplateFinished{v_1001110}}}}}}
    case Ast.TermRewrite{v_182, v_183, v_184, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_182, v_3}}, +v_1001111 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_183, v_3}}, +v_1001112 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_184, v_3}}, +v_1001113 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001112, v_1001113}}, +v_1001114 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001111, v_1001114}}, +v_1001115 => TemplateFinished{v_1001115}}}}}}
    case Ast.BodyMatch{v_194, v_195, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_194, v_3}}, False{}, v_1001120 => template_body_invalid_capture_terms(v_194, v_3), +v_1001116 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_195, v_3}}, False{}, v_1001119 => template_body_invalid_capture_terms(v_195, v_3), +v_1001117 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001116, v_1001117}}, +v_1001118 => TemplateFinished{v_1001118}}}}
    case Ast.BodyCase{v_203, v_204, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_patterns{v_203, v_3}}, False{}, v_1001124 => template_body_invalid_capture_patterns(v_203, v_3), +v_1001121 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_204, v_3}}, +v_1001122 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001121, v_1001122}}, +v_1001123 => TemplateFinished{v_1001123}}}}
    case Ast.BodyLocal{v_214, _, v_216, v_217, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_patterns{v_214, v_3}}, False{}, v_1001131 => template_body_invalid_capture_patterns(v_214, v_3), +v_1001125 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_capture_terms{v_216, v_3}}, False{}, v_1001130 => template_body_invalid_capture_terms(v_216, v_3), +v_1001126 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_217, v_3}}, +v_1001127 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001126, v_1001127}}, +v_1001128 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001125, v_1001128}}, +v_1001129 => TemplateFinished{v_1001129}}}}}}
    case Ast.BodyReply{v_226, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_capture{v_226, v_3}}, +v_1001132 => TemplateFinished{v_1001132}}
    case _:
      TemplateFinished{None{}}

def template_body_invalid_capture(v_0: Ast.SyntaxTerm, v_3: List<&2, CaptureName>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_247(v_0, v_3)

def template_match_248(v_0: Ast.SyntaxTerm, +v_2: Nat) -> TemplateProgress<Bool>:
  match v_0:
    case Ast.TermVar{_, v_8, _}:
      TemplateFinished{Nat.is_ge(v_8, v_2)}
    case Ast.TermSub{_, v_15, v_16, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_15, v_2}}, +v_1001133 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_16, Nat.add(v_2, 1n)}}, +v_1001134 => TemplateFinished{Bool.or(v_1001133, v_1001134)}}}
    case Ast.TermLet{v_28, _, _, v_31, v_32, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_31, v_2}}, +v_1001135 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_32, Nat.add(v_2, List.length(&2, String, v_28))}}, +v_1001136 => TemplateFinished{Bool.or(v_1001135, v_1001136)}}}
    case Ast.TermAnn{v_42, v_43, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_42, v_2}}, +v_1001137 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_43, v_2}}, +v_1001138 => TemplateFinished{Bool.or(v_1001137, v_1001138)}}}
    case Ast.TermTemplate{v_49, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_49, v_2}}, +v_1001139 => TemplateFinished{v_1001139}}
    case Ast.TermBang{v_54, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_54, v_2}}, +v_1001140 => TemplateFinished{v_1001140}}
    case Ast.TermType{v_59, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_59, v_2}}, +v_1001141 => TemplateFinished{v_1001141}}
    case Ast.TermMin{v_65, v_66, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_65, v_2}}, +v_1001142 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_66, v_2}}, +v_1001143 => TemplateFinished{Bool.or(v_1001142, v_1001143)}}}
    case Ast.TermAll{_, _, _, v_79, v_80, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_79, v_2}}, +v_1001144 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_80, Nat.add(v_2, 1n)}}, +v_1001145 => TemplateFinished{Bool.or(v_1001144, v_1001145)}}}
    case Ast.TermLam{_, _, _, v_94, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_94, Nat.add(v_2, 1n)}}, +v_1001146 => TemplateFinished{v_1001146}}
    case Ast.TermApp{v_102, v_103, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_102, v_2}}, +v_1001147 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_103, v_2}}, +v_1001148 => TemplateFinished{Bool.or(v_1001147, v_1001148)}}}
    case Ast.TermAdt{_, v_112, _, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_112, v_2}}, +v_1001149 => TemplateFinished{v_1001149}}
    case Ast.TermFill{v_119, v_120, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_119, v_2}}, +v_1001150 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_120, v_2}}, +v_1001151 => TemplateFinished{Bool.or(v_1001150, v_1001151)}}}
    case Ast.TermPlus{v_127, v_128, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_127, v_2}}, +v_1001152 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_128, v_2}}, +v_1001153 => TemplateFinished{Bool.or(v_1001152, v_1001153)}}}
    case Ast.TermCtr{_, v_136, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_136, v_2}}, +v_1001154 => TemplateFinished{v_1001154}}
    case Ast.TermString{_, _, _}:
      TemplateFinished{False{}}
    case Ast.TermMat{_, v_150, v_151, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_150, v_2}}, +v_1001155 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_151, v_2}}, +v_1001156 => TemplateFinished{Bool.or(v_1001155, v_1001156)}}}
    case Ast.TermEqual{v_159, v_160, v_161, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_159, v_2}}, +v_1001157 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_160, v_2}}, +v_1001158 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_161, v_2}}, +v_1001159 => TemplateFinished{Bool.or(v_1001157, Bool.or(v_1001158, v_1001159))}}}}
    case Ast.TermRewrite{v_170, v_171, v_172, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_170, v_2}}, +v_1001160 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_171, v_2}}, +v_1001161 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_172, v_2}}, +v_1001162 => TemplateFinished{Bool.or(v_1001160, Bool.or(v_1001161, v_1001162))}}}}
    case Ast.BodyMatch{v_180, v_181, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_180, v_2}}, +v_1001163 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_181, v_2}}, +v_1001164 => TemplateFinished{Bool.or(v_1001163, v_1001164)}}}
    case Ast.BodyCase{v_188, v_189, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_189, Nat.add(v_2, Core.pattern_list_depth(v_188))}}, +v_1001165 => TemplateFinished{v_1001165}}
    case Ast.BodyLocal{v_199, _, v_201, v_202, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_201, v_2}}, +v_1001166 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_202, Nat.add(v_2, Core.pattern_list_depth(v_199))}}, +v_1001167 => TemplateFinished{Bool.or(v_1001166, v_1001167)}}}
    case Ast.BodyReply{v_210, _}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_210, v_2}}, +v_1001168 => TemplateFinished{v_1001168}}
    case _:
      TemplateFinished{False{}}

def template_body_has_open_vars(v_0: Ast.SyntaxTerm, v_2: Nat) -> TemplateProgress<Bool>:
  template_match_248(v_0, v_2)

def template_match_249(v_1: List<&2, Ast.SyntaxTerm>, +v_3: Nat) -> TemplateProgress<Bool>:
  match v_1:
    case []:
      TemplateFinished{False{}}
    case +v_7 <> v_8:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_has_open_vars{v_7, v_3}}, False{}, v_1001171 => template_body_has_open_vars(v_7, v_3), +v_1001169 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_has_open_vars_terms{v_8, v_3}}, +v_1001170 => TemplateFinished{Bool.or(v_1001169, v_1001170)}}}

def template_body_has_open_vars_terms(v_1: List<&2, Ast.SyntaxTerm>, v_3: Nat) -> TemplateProgress<Bool>:
  template_match_249(v_1, v_3)

def template_match_250(v_1: List<&2, Ast.SyntaxTerm>, +v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{None{}}
    case +v_8 <> v_9:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_8, v_4}}, False{}, v_1001175 => template_body_invalid_application(v_8, v_4), +v_1001172 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_terms{v_9, v_4}}, +v_1001173 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001172, v_1001173}}, +v_1001174 => TemplateFinished{v_1001174}}}}

def template_body_invalid_terms(v_1: List<&2, Ast.SyntaxTerm>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_250(v_1, v_4)

def template_body_first_invalid(v_1: Maybe<&2, Ast.SourceSpan>, v_3: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case Some{v_6}:
      TemplateFinished{Some{v_6}}
    case None{}:
      TemplateFinished{v_3}

def template_match_252(+v_8: Ast.TopLevel, v_9: List<&2, Ast.TopLevel>, +v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_8:
    case Ast.DefTop{Ast.Definition{_, +v_17, v_18, v_19, _, _}}:
      v_1001176 = {v_17 : List<&2, Ast.TelescopeItem>}
      v_1001177 = {v_18 : Ast.OptionalTerm}
      v_1001178 = {v_19 : Ast.DefBody}
      v_1001179 = {v_9 : List<&2, Ast.TopLevel>}
      v_1001180 = {v_4 : List<&2, TemplateDef>}
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_has_template_binder{v_17}}, False{}, v_1001183 => template_body_has_template_binder(v_17), +v_1001181 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_definition{v_1001176, v_1001177, v_1001178, v_1001179, v_1001180, v_1001181}}, +v_1001182 => TemplateFinished{v_1001182}}}
    case Ast.TypeTop{Ast.TypeDecl{_, v_30, v_31, v_32, _}}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_binders{v_30, v_4}}, +v_1001184 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_31, v_4}}, False{}, v_1001193 => template_body_invalid_application(v_31, v_4), +v_1001185 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001184, v_1001185}}, False{}, v_1001192 => template_body_first_invalid(v_1001184, v_1001185), +v_1001186 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_constructors{v_32, v_4}}, +v_1001187 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_definitions{v_9, v_4}}, +v_1001188 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001187, v_1001188}}, False{}, v_1001191 => template_body_first_invalid(v_1001187, v_1001188), +v_1001189 => template_body_first_invalid(v_1001186, v_1001189)}}}}}}
    case Ast.LawTop{Ast.LawDecl{_, v_46, v_47, _}}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_clauses{v_46, v_4}}, +v_1001194 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_47, v_4}}, False{}, v_1001200 => template_body_invalid_application(v_47, v_4), +v_1001195 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001194, v_1001195}}, False{}, v_1001199 => template_body_first_invalid(v_1001194, v_1001195), +v_1001196 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_definitions{v_9, v_4}}, +v_1001197 => template_body_first_invalid(v_1001196, v_1001197)}}}}

def template_body_invalid_definitions(v_1: List<&2, Ast.TopLevel>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{None{}}
    case +v_8 <> v_9:
      template_match_252(v_8, v_9, v_4)

def template_continuation_254(v_15: Maybe<&2, Ast.SourceSpan>, v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, +v_1001205: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  v_1001206 = {v_15 : Maybe<&2, Ast.SourceSpan>}
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_definitions{v_5, v_8}}, False{}, v_1001211 => template_body_invalid_definitions(v_5, v_8), +v_1001207 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001206, v_1001207}}, False{}, v_1001210 => template_body_first_invalid(v_1001206, v_1001207), +v_1001208 => template_body_first_invalid(v_1001205, v_1001208)}}

def template_continuation_255(+v_1001202: Maybe<&2, Ast.SourceSpan>, v_1: List<&2, Ast.TelescopeItem>, +v_8: List<&2, TemplateDef>, v_2: Ast.OptionalTerm, v_5: List<&2, Ast.TopLevel>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  v_15 = v_1001202
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_binders{v_1, v_8}}, +v_1001203 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_optional{v_2, v_8}}, +v_1001204 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001203, v_1001204}}, False{}, v_1001212 => template_body_first_invalid(v_1001203, v_1001204), +v_1001205 => template_continuation_254(v_15, v_5, v_8, v_1001205)}}}

def template_match_256(v_10: Bool, v_5: List<&2, Ast.TopLevel>, +v_8: List<&2, TemplateDef>, v_3: Ast.DefBody, v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.OptionalTerm) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_10:
    case True{}:
      template_body_invalid_definitions(v_5, v_8)
    case False{}:
      TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_def_body{v_3, v_8}}, +v_1001202 => template_continuation_255(v_1001202, v_1, v_8, v_2, v_5)}

def template_body_invalid_definition(v_1: List<&2, Ast.TelescopeItem>, v_2: Ast.OptionalTerm, v_3: Ast.DefBody, v_5: List<&2, Ast.TopLevel>, v_8: List<&2, TemplateDef>, v_10: Bool) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_256(v_10, v_5, v_8, v_3, v_1, v_2)

def template_body_invalid_def_body(v_0: Ast.DefBody, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_0:
    case Ast.DefTerm{v_6}:
      template_body_invalid_application(v_6, v_3)
    case Ast.DefImports{_}:
      TemplateFinished{None{}}

def template_body_invalid_optional(v_0: Ast.OptionalTerm, v_3: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_0:
    case Ast.NoTerm{}:
      TemplateFinished{None{}}
    case Ast.SomeTerm{v_6}:
      template_body_invalid_application(v_6, v_3)

def template_match_259(+v_8: Ast.TelescopeItem, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.TelescopeItem>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_8:
    case Ast.Binder{_, _, _, v_18, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_18, v_4}}, False{}, v_1001218 => template_body_invalid_application(v_18, v_4), +v_1001215 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_binders{v_9, v_4}}, +v_1001216 => template_body_first_invalid(v_1001215, v_1001216)}}
    case Ast.TemplateBinder{_, _, v_29, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_29, v_4}}, False{}, v_1001222 => template_body_invalid_application(v_29, v_4), +v_1001219 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_binders{v_9, v_4}}, +v_1001220 => template_body_first_invalid(v_1001219, v_1001220)}}

def template_body_invalid_binders(v_1: List<&2, Ast.TelescopeItem>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{None{}}
    case +v_8 <> v_9:
      template_match_259(v_8, v_4, v_9)

def template_match_261(+v_8: Ast.ConstructorDecl, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.ConstructorDecl>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_8:
    case Ast.Constructor{_, v_14, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_binders{v_14, v_4}}, False{}, v_1001226 => template_body_invalid_binders(v_14, v_4), +v_1001223 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_constructors{v_9, v_4}}, +v_1001224 => template_body_first_invalid(v_1001223, v_1001224)}}

def template_body_invalid_constructors(v_1: List<&2, Ast.ConstructorDecl>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{None{}}
    case +v_8 <> v_9:
      template_match_261(v_8, v_4, v_9)

def template_match_263(+v_8: Ast.Clause, +v_4: List<&2, TemplateDef>, v_9: List<&2, Ast.Clause>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_8:
    case Ast.ClauseFor{_, _, _, v_19, v_20, _}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_application{v_19, v_4}}, False{}, v_1001233 => template_body_invalid_application(v_19, v_4), +v_1001227 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_maybe{v_20, v_4}}, +v_1001228 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_invalid_clauses{v_9, v_4}}, +v_1001229 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_first_invalid{v_1001228, v_1001229}}, False{}, v_1001232 => template_body_first_invalid(v_1001228, v_1001229), +v_1001230 => template_body_first_invalid(v_1001227, v_1001230)}}}}

def template_body_invalid_clauses(v_1: List<&2, Ast.Clause>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{None{}}
    case +v_8 <> v_9:
      template_match_263(v_8, v_4, v_9)

def template_body_invalid_maybe(v_1: Maybe<&2, Ast.SyntaxTerm>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case None{}:
      TemplateFinished{None{}}
    case Some{v_6}:
      template_body_invalid_application(v_6, v_4)

def template_body_expand(+v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<ExpandResult>:
  v_1001235 = {v_1 : List<&2, Loader.LoadedModule>}
  TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_collect_templates{v_1}}, False{}, v_1001240 => template_body_collect_templates(v_1), +v_1001236 => TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_template_definitions{v_1}}, False{}, v_1001239 => template_body_invalid_template_definitions(v_1), +v_1001237 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_template_expand_templates{v_1001235, v_1001236, v_1001237}}, +v_1001238 => TemplateFinished{v_1001238}}}}

def template_match_266(v_6: Maybe<&2, Ast.SourceSpan>, +v_1: List<&2, Loader.LoadedModule>, +v_4: List<&2, TemplateDef>) -> TemplateProgress<ExpandResult>:
  match v_6:
    case Some{v_9}:
      TemplateFinished{ExpandFailure{"template binders must precede runtime binders", v_9}}
    case None{}:
      v_1001241 = {v_1 : List<&2, Loader.LoadedModule>}
      v_1001242 = {v_4 : List<&2, TemplateDef>}
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_invalid_modules{v_1, v_4}}, +v_1001243 => TemplatePending{TemplateRequestGroup_2{TemplateRequest_template_expand_modules{v_1001241, v_1001242, v_1001243}}, +v_1001244 => TemplateFinished{v_1001244}}}

def template_body_template_expand_templates(v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_6: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<ExpandResult>:
  template_match_266(v_6, v_1, v_4)

def template_match_267(v_6: Maybe<&2, Ast.SourceSpan>, +v_4: List<&2, TemplateDef>, v_1: List<&2, Loader.LoadedModule>) -> TemplateProgress<ExpandResult>:
  match v_6:
    case Some{v_9}:
      TemplateFinished{ExpandFailure{"template application requires a compile-time template argument", v_9}}
    case None{}:
      v_1001245 = {v_4 : List<&2, TemplateDef>}
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_generate_until_stable{v_1, v_4, []}}, False{}, v_1001248 => template_body_generate_until_stable(v_1, v_4, []), +v_1001246 => TemplatePending{TemplateRequestGroup_3{TemplateRequest_template_expand_round{v_1001245, v_1001246}}, +v_1001247 => TemplateFinished{v_1001247}}}

def template_body_template_expand_modules(v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>, v_6: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<ExpandResult>:
  template_match_267(v_6, v_4, v_1)

def template_match_268(v_4: GeneratedRound, +v_2: List<&2, TemplateDef>) -> TemplateProgress<ExpandResult>:
  match v_4:
    case GeneratedRound{v_10, _, _, Some{v_13}}:
      TemplateFinished{ExpandFailure{"template specialization hash collision", v_13}}
    case GeneratedRound{+v_17, _, v_19, None{}}:
      v_1001249 = {v_17 : List<&2, Loader.LoadedModule>}
      v_1001250 = {v_19 : List<&2, GeneratedIdentity>}
      v_1001251 = {v_2 : List<&2, TemplateDef>}
      TemplatePending{TemplateRequestGroup_3{TemplateRequest_invalid_modules{v_17, v_2}}, +v_1001252 => TemplatePending{TemplateRequestGroup_3{TemplateRequest_template_expand_generated{v_1001249, v_1001250, v_1001251, v_1001252}}, +v_1001253 => TemplateFinished{v_1001253}}}

def template_body_template_expand_round(v_2: List<&2, TemplateDef>, v_4: GeneratedRound) -> TemplateProgress<ExpandResult>:
  template_match_268(v_4, v_2)

def template_match_269(v_9: Maybe<&2, Ast.SourceSpan>, v_1: List<&2, Loader.LoadedModule>, v_7: List<&2, TemplateDef>, v_4: List<&2, GeneratedIdentity>) -> TemplateProgress<ExpandResult>:
  match v_9:
    case Some{v_12}:
      TemplateFinished{ExpandFailure{"template application requires a closed compile-time argument", v_12}}
    case None{}:
      TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_expand_modules{v_1, v_7, v_4}}, False{}, v_1001255 => template_body_expand_modules(v_1, v_7, v_4), +v_1001254 => TemplateFinished{ExpandSuccess{v_1001254}}}

def template_body_template_expand_generated(v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, GeneratedIdentity>, v_7: List<&2, TemplateDef>, v_9: Maybe<&2, Ast.SourceSpan>) -> TemplateProgress<ExpandResult>:
  template_match_269(v_9, v_1, v_7, v_4)

def template_body_invalid_modules(+v_1: List<&2, Loader.LoadedModule>, v_4: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  TemplatePending{TemplateRequestGroup_3{TemplateRequest_invalid_scoped_modules{v_1, v_1, v_4}}, +v_1001256 => TemplateFinished{v_1001256}}

def template_continuation_270(+v_1001257: List<&2, TemplateDef>, v_19: List<&2, Ast.TopLevel>, v_11: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  v_22 = v_1001257
  TemplateDirect{Bool, TemplateRequestGroup_2{TemplateRequest_invalid_definitions{v_19, v_22}}, False{}, v_1001261 => template_body_invalid_definitions(v_19, v_22), +v_1001258 => TemplatePending{TemplateRequestGroup_3{TemplateRequest_invalid_scoped_modules{v_11, v_3, v_6}}, +v_1001259 => template_body_first_invalid(v_1001258, v_1001259)}}

def template_match_271(+v_10: Loader.LoadedModule, +v_6: List<&2, TemplateDef>, +v_3: List<&2, Loader.LoadedModule>, v_11: List<&2, Loader.LoadedModule>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_10:
    case Loader.LoadedModule{v_16, Ast.Module{_, v_18, v_19}}:
      TemplateDirect{Bool, TemplateRequestGroup_0{TemplateRequest_scoped_templates{v_16, v_18, v_6, v_3}}, False{}, v_1001262 => template_body_scoped_templates(v_16, v_18, v_6, v_3), +v_1001257 => template_continuation_270(v_1001257, v_19, v_11, v_3, v_6)}

def template_match_272(v_1: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>, v_3: List<&2, Loader.LoadedModule>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  match v_1:
    case []:
      TemplateFinished{None{}}
    case +v_10 <> v_11:
      template_match_271(v_10, v_6, v_3, v_11)

def template_body_invalid_scoped_modules(v_1: List<&2, Loader.LoadedModule>, v_3: List<&2, Loader.LoadedModule>, v_6: List<&2, TemplateDef>) -> TemplateProgress<Maybe<&2, Ast.SourceSpan>>:
  template_match_272(v_1, v_6, v_3)

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
    case TemplateRequest_fresh_generated_key{arg_0, arg_1, arg_2}: template_body_fresh_generated_key(arg_0, arg_1, arg_2)
    case TemplateRequest_fresh_generated_key_match{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_fresh_generated_key_match(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_generated_candidate{arg_0, arg_1}: template_body_generated_candidate(arg_0, arg_1)
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
    case TemplateRequest_template_arity{arg_0}: template_body_template_arity(arg_0)
    case TemplateRequest_expand_application_arguments{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8}: template_body_expand_application_arguments(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8)

def template_step_group_1(request: TemplateRequestGroup1) -> TemplateProgress<template_result_group_1(request)>:
  match request:
    case TemplateRequest_specialize_head{arg_0, arg_1}: template_body_specialize_head(arg_0, arg_1)
    case TemplateRequest_drop_args{arg_0, arg_1}: template_body_drop_args(arg_0, arg_1)
    case TemplateRequest_specialize_definition{arg_0, arg_1}: template_body_specialize_definition(arg_0, arg_1)
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
    case TemplateRequest_template_aliases{arg_0, arg_1, arg_2, arg_3}: template_body_template_aliases(arg_0, arg_1, arg_2, arg_3)
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
    case TemplateRequest_find_generated_identity_match{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_find_generated_identity_match(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_template_span{arg_0}: template_body_template_span(arg_0)

def template_step_group_2(request: TemplateRequestGroup2) -> TemplateProgress<template_result_group_2(request)>:
  match request:
    case TemplateRequest_generated_actuals{arg_0, arg_1, arg_2, arg_3, arg_4}: template_body_generated_actuals(arg_0, arg_1, arg_2, arg_3, arg_4)
    case TemplateRequest_template_name{arg_0}: template_body_template_name(arg_0)
    case TemplateRequest_generated_actual_case{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10}: template_body_generated_actual_case(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10)
    case TemplateRequest_generated_identity_collision{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7}: template_body_generated_identity_collision(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7)
    case TemplateRequest_generated_actual_new{arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10}: template_body_generated_actual_new(arg_0, arg_1, arg_2, arg_3, arg_4, arg_5, arg_6, arg_7, arg_8, arg_9, arg_10)
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
    case TemplateRequest_template_expand_templates{arg_0, arg_1, arg_2}: template_body_template_expand_templates(arg_0, arg_1, arg_2)
    case TemplateRequest_template_expand_modules{arg_0, arg_1, arg_2}: template_body_template_expand_modules(arg_0, arg_1, arg_2)

def template_step_group_3(request: TemplateRequestGroup3) -> TemplateProgress<template_result_group_3(request)>:
  match request:
    case TemplateRequest_template_expand_round{arg_0, arg_1}: template_body_template_expand_round(arg_0, arg_1)
    case TemplateRequest_template_expand_generated{arg_0, arg_1, arg_2, arg_3}: template_body_template_expand_generated(arg_0, arg_1, arg_2, arg_3)
    case TemplateRequest_invalid_modules{arg_0, arg_1}: template_body_invalid_modules(arg_0, arg_1)
    case TemplateRequest_invalid_scoped_modules{arg_0, arg_1, arg_2}: template_body_invalid_scoped_modules(arg_0, arg_1, arg_2)

def template_step(request: TemplateRequest) -> TemplateProgress<template_result(request)>:
  match request:
    case TemplateRequestGroup_0{inner}: template_step_group_0(inner)
    case TemplateRequestGroup_1{inner}: template_step_group_1(inner)
    case TemplateRequestGroup_2{inner}: template_step_group_2(inner)
    case TemplateRequestGroup_3{inner}: template_step_group_3(inner)

def template_start(modules: List<&2, Loader.LoadedModule>) -> TemplateProgress<ExpandResult>:
  TemplatePending{TemplateRequestGroup_2{TemplateRequest_expand{modules}}, +result => TemplateFinished{result}}
