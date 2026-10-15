# Exact CheckerCore dependency/order audit

Root: `check_modules`. Exact source closure contains416 of418 Checker defs; only `check` and `check_template_result` are excluded. Template import excluded; no reachable `Template.*` references. All type declarations retained. Bodies, signatures, quantities and original source-relative order preserved. Relative import paths adjusted only for slice location.

- 416 definitions; all reachable from `check_modules`.
- 161 forward edges: 55 acyclic inter-SCC; 106 within mutual SCCs.
- 75 defs with direct self calls; 29 live mutual SCCs.
- Full graph and per-definition earlier/later references, order indices, source locations, self-recursion and SCC membership: `checker-core-ordering-audit.json`.
- Reproduce: `bun checkpoints/checker-core-ordering-audit.ts`. Tarjan partition independently verified against all-pairs mutual reachability.

## Every mutual SCC

1. `lookup_binding`, `lookup_binding_head`
2. `lookup_global_match`, `lookup_global`
3. `family_lowered_whnf`, `whnf_ref_type`, `whnf_ref_global`, `whnf_ref_result`, `whnf_application`, `whnf`, `family_arity_view`, `family_arity`, `family_quant_prefix_domain`, `family_quant_prefix_view`, `family_quant_prefix`, `lower_family_sugar_family`, `lower_family_sugar_global`, `lower_family_sugar_global_result`, `lower_family_sugar_key_result`, `lower_family_sugar`
4. `equal_term`, `equal_raw`, `equal_lists`
5. `fits_kind_whnf`, `fits_kind`
6. `fits_term_whnf`, `fits_term`
7. `infer_adt_args_view`, `infer_adt_arg_check`, `infer_adt_args`, `validate_terms_result`, `validate_terms`, `check_local_quantities`, `check_local_pattern_uses`, `check_body_local_uses_result`, `check_body_local_terms_result`, `check_body_local_quantity_result`, `check_body_local_length_result`, `check_body_local`, `infer_family_sugar_result`, `infer_family_sugar`, `infer_application_result_view`, `infer_application_result`, `infer_global_adt`, `infer_term_annotation_result`, `infer_equal_type`, `infer_application_result_of_function`, `infer_application_unfolded`, `infer_application_bang`, `infer_application_valid`, `infer_all_domain`, `infer_let_values`, `infer_let_validated`, `infer_let_lengths`, `infer`, `check_match_head_result`, `check_match_applied`, `check_match_family_equal`, `check_match_family_result`, `check_match_global`, `check_match_constructor`, `check_match_unexcluded`, `check_match_input_view`, `check_match_goal_view`, `check_match`, `check_body_case_body_result`, `check_body_case_pattern_result`, `check_body_case_constructor_uses`, `check_body_case_constructor_seen`, `check_body_case_catchall_usage`, `check_body_case_catchall`, `check_body_case_pattern`, `check_body_case_term`, `check_body_cases`, `check_body_match_type_view`, `check_body_match_type`, `infer_scrutinee_types_result`, `infer_scrutinee_types`, `pattern_uses_valid`, `pattern_uses_valid_list`, `check_body_pattern_vector_typed`, `check_body_pattern_vector`, `check_body_pattern_rows_result`, `check_body_pattern_rows_catchall`, `check_body_pattern_rows_length`, `check_body_pattern_rows_case`, `check_body_pattern_rows`, `check_body_match_many_types_result`, `check_body_match_many`, `check_body_match_first_result`, `check_body_match_scrutinees`, `check_body_match_valid`, `check_body_match`, `rewrite_body_type_view`, `rewrite_left_applied_result`, `rewrite_fits_result`, `rewrite_equation_applied_result`, `rewrite_proof_result`, `rewrite_equation_view`, `rewrite_equation_result`, `check_rewrite`, `lambda_domain_valid`, `check_lambda_domain_result`, `check_lambda_promotes_result`, `check_lambda_quantity_result`, `check_lambda_body`, `check_lambda_body_result`, `check_term_lambda_view`, `check_term_constructor_apply`, `check_term_constructor_global`, `check_term_constructor_global_result`, `check_term_constructor_allowed`, `check_term_constructor_view`, `check_term`, `usage_let_env`, `usage_local_env`, `term_usage_map_constructor_view`, `constructor_argument_usage`, `term_usage_map_constructor_args`, `term_usage_map_lambda_quantity`, `term_usage_map_lambda_view`, `term_usage_map_lambda_expected`, `term_usage_map_application_quantity`, `term_usage_map_family_result`, `term_usage_map_constructor_result`, `term_usage_map_scrutinee_result`, `term_usage_map`, `term_usage_map_cases`, `term_usage_map_case`, `term_usage_map_list`, `term_usage_map_quantified_list`, `use_count_with_globals`, `use_count_with_context`, `use_count_with_expected`, `check_ctr_fields_arg`, `check_ctr_fields_view`, `check_ctr_fields`
8. `canonicalize_patterns`, `canonicalize_pattern`
9. `canonicalize_terms`, `canonicalize_term`
10. `match_scrutinee_binding`, `match_scrutinees_valid`
11. `replace_free_terms`, `replace_free_cases`, `replace_free_term`
12. `family_constructor_keys_for_type`, `family_constructor_keys_inner`
13. `index_terms_compatible_view`, `index_terms_compatible`, `index_term_lists_compatible`
14. `filter_reachable_result`, `filter_reachable_constructors`
15. `matrix_covers_recursive_result`, `matrix_covers_constructors`, `matrix_covers_types`, `matrix_covers`
16. `check_pattern_fields_typed_result`, `check_pattern_fields_view`, `check_pattern_typed_fields`, `check_pattern_applied_result`, `check_pattern_family_result`, `check_pattern_global`, `check_pattern_global_result`, `check_pattern_exclusion_result`, `check_pattern_typed_view`, `check_pattern_typed`
17. `usage_pattern_env_result`, `usage_pattern_env`
18. `check_live_fields_result`, `check_live_fields`
19. `check_constructors_fields_result`, `check_constructors_type_result`, `check_constructors_unique`, `check_constructors`
20. `application_argument_bangs_valid_terms`, `application_argument_bangs_valid`, `application_bangs_valid`
21. `term_descend`, `term_descend_raw`, `term_descend_live`, `term_descend_constructor_result`, `term_descend_list_result`, `term_descend_list`, `term_is_subterm_result`, `term_is_subterm`
22. `recursive_call_decrease_result`, `recursive_call_decreases`
23. `pattern_value`, `pattern_values`
24. `replace_order_var`, `replace_order_vars`
25. `initial_telescope_count_view`, `initial_telescope_count`
26. `drop_telescope_view`, `drop_telescope`
27. `recursion_terminates_mat_head`, `recursion_terminates_application_view`, `recursion_terminates_mat_arity`, `recursion_terminates`, `recursion_terminates_cases`, `recursion_terminates_list`, `recursion_terminates_call_args`
28. `check_declarations_step`, `check_declarations_type_result`, `check_declarations_law_result`, `check_declarations`
29. `check_modules_declarations`, `check_modules_module`, `check_modules`

No Checker body/SCC/order repair applied. Native validation must determine the first actual blocker; this audit predicts ordering constraints rather than replacing native validation.
