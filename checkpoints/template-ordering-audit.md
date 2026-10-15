# Template dependency/order audit

Outcome **C**: collector-local refactor plus declaration reordering is insufficient for the whole module. No implementation source changed, no driver rebuild attempted.

## Exact source and method

- Source: `bend2/selfhost/template.bend`; preserved byte-for-byte in `template-ordering-before.bend`.
- SHA256: `3e29a7b890d029f4995e6ac0390759a1e1baf95ed1a7fb7ab394b3043bfc6b0a`.
- Source indices are **1-based**; lines refer to the preserved source.
- String/comment masking; unique def names; bare local identifiers only; qualified imported names excluded; rejects parameter shadowing, non-call local identifiers and unsupported signatures; Tarjan verified against independent all-pairs mutual reachability.
- Reproducible command: `bun checkpoints/template-ordering-audit.ts`. No imported Ast/Core/List/String/Nat/Bool/SHA256/Path/Loader names are local edges.
- Complete extraction independently cross-checked for all 159 definitions. SCC partition independently checked against all-pairs mutual reachability.
- This is a static source graph, not native type/ownership/termination validation. Self-call classification does not assert structural validity.

## Classification

- **159 definitions**, **144 forward edges**.
- **A:** 93 inter-SCC forward edges: acyclic condensation constraints; declaration ordering can address these once each recursive component has an allowed representation. Every edge and location appears below and in JSON.
- **B:** 52 definitions contain direct self calls; all listed below. Leave these source bodies unchanged; no new recursion/termination policy assumed.
- **C:** 25 non-singleton SCCs, containing 71 definitions and 51 within-SCC forward edges. No linear declaration order eliminates these cycles.
- No forward-declaration construct was introduced or assumed supported.

## Every mutual-recursive SCC (before any implementation edit)

| SCC | Members (source order) |
|---|---|
| 1 | `collect_template_decls`, `collect_template_decl` |
| 2 | `find_template`, `find_template_match` |
| 3 | `fresh_generated_key`, `fresh_generated_key_match` |
| 4 | `serialize_patterns`, `serialize_pattern` |
| 5 | `serialize_terms`, `serialize_term` |
| 6 | `expand_term`, `expand_application`, `expand_application_spine`, `expand_application_template`, `expand_application_arguments`, `expand_terms` |
| 7 | `strip_template_decls`, `strip_template_definition`, `strip_canonical_template`, `strip_instance_or_definition` |
| 8 | `canonical_template_key`, `canonical_template_match` |
| 9 | `generated_local_keys`, `generated_local_key_match` |
| 10 | `template_instances_for_keys`, `template_instance_definition` |
| 11 | `find_actual`, `find_actual_spine`, `find_actual_head`, `find_actual_key`, `find_actual_prefix`, `find_actual_application_parts`, `find_actual_terms` |
| 12 | `actual_in_declarations`, `actual_definition` |
| 13 | `imported_alias_names`, `imported_alias_match` |
| 14 | `has_string`, `has_string_match` |
| 15 | `find_generated_identity`, `find_generated_identity_match` |
| 16 | `generated_actuals`, `generated_actual_case`, `generated_identity_collision`, `generated_actual_new` |
| 17 | `generated_for_module`, `generated_for_module_match`, `generated_for_module_here` |
| 18 | `generate_round`, `generate_round_loaded` |
| 19 | `generate_until_stable`, `generate_until_result` |
| 20 | `local_templates`, `local_template_match` |
| 21 | `imported_from`, `imported_from_match` |
| 22 | `invalid_template_decls`, `invalid_template_decl` |
| 23 | `invalid_application`, `invalid_application_spine`, `invalid_application_head`, `invalid_application_arity`, `invalid_application_arguments`, `invalid_application_parts`, `invalid_template_args`, `invalid_template_argument`, `invalid_terms` |
| 24 | `has_open_vars`, `has_open_vars_terms` |
| 25 | `invalid_definitions`, `invalid_definition` |

## Why the collector-only refactor is insufficient

The expected SCC is confirmed: `collect_template_decls` → `collect_template_decl` → `collect_template_decls` (lines 82 and 90/91). The helper has exactly one distinct caller, `collect_template_decls`; its only local dependencies are `qualify` and `collect_template_decls`. The proposed local fusion would remove SCC1 without changing collection order/fields. It does not remove any of the other 24 SCCs.

The actual collector prerequisite closure (excluding that SCC) is `top_keys`, `has_template_binder`, `qualify_match`, `qualify`. Dependency constraints: `qualify_match` before `qualify`; `has_template_binder` and `qualify` before the fused collector; `top_keys` and the fused collector before `collect_templates`. There is no dependency between `top_keys` and the qualification/predicate helpers.

Some other cycles are predicate/dispatch helper pairs (e.g. find_template, has_string, local_templates); they need separate local fusion, not reordering. The module also contains genuine heterogeneous recursive traversals:

- SCC5: term-list serialization ↔ term serialization. Nested term constructors contain both single terms and lists.
- SCC4: pattern-list serialization ↔ pattern serialization (constructor pattern fields).
- SCC6: term expansion ↔ list expansion plus the application specialization path.
- SCC11: actual-argument discovery ↔ list discovery plus application-prefix traversal.
- SCC24: open-variable analysis ↔ list analysis.
- SCC23: invalid-application traversal ↔ list/argument traversal and application validation dispatch.

These cannot become an acyclic module by moving definitions. Converting all of them would require additional distinct source refactors beyond the tiny collector dispatch fusion; no generic CPS/state machine, kernel change, unsafe exclusion, Template bypass, or host semantic replacement was applied. Even optimistically removing the collector SCC leaves **24 mutual components** and a lower bound of **24 unavoidable non-self forward edges** in any ordering of the remaining unchanged SCCs.

All **159 definitions**, hence all25 SCCs, are reachable from the actual `expand` entrypoint. There is no unreachable SCC whose deletion alone would avoid a recursive-representation decision.

Focused collector regressions and a full driver rebuild were deliberately not run: no collector change was made, and the prerequisite of a clean entire-module dependency audit is not satisfied. The accepted prior driver-load/native-first-blocker evidence remains unchanged. Tiny frontend runtime and bootstrap remain NOT REACHED.

## Every definition

Direct references are unique names; JSON additionally records every call-site line. Earlier/later exclude self; SCC `—` means singleton (which may still have a self call).

| Index | Line | Definition | Direct local references | Earlier | Later | Self | Non-singleton SCC |
|---|---|---|---|---|---|---|---|
| 1 | 27 | `span_of` | — | — | — | no | — |
| 2 | 59 | `collect_templates` | `collect_template_decls`, `top_keys`, `collect_templates` | — | `collect_template_decls`, `top_keys` | yes | — |
| 3 | 67 | `top_keys` | `top_keys` | — | — | yes | — |
| 4 | 76 | `collect_template_decls` | `collect_template_decl`, `has_template_binder`, `collect_template_decls` | — | `collect_template_decl`, `has_template_binder` | yes | 1 |
| 5 | 85 | `collect_template_decl` | `qualify`, `collect_template_decls` | `collect_template_decls` | `qualify` | no | 1 |
| 6 | 93 | `has_template_binder` | `has_template_binder` | — | — | yes | — |
| 7 | 101 | `qualify` | `qualify_match` | — | `qualify_match` | no | — |
| 8 | 104 | `qualify_match` | — | — | — | no | — |
| 9 | 109 | `find_template` | `find_template_match` | — | `find_template_match` | no | 2 |
| 10 | 117 | `find_template_match` | `find_template` | `find_template` | — | no | 2 |
| 11 | 121 | `flatten_application` | `flatten_append`, `flatten_application`, `span_of` | `span_of` | `flatten_append` | yes | — |
| 12 | 128 | `flatten_append` | — | — | — | no | — |
| 13 | 132 | `leading_template_count` | `leading_template_count` | — | — | yes | — |
| 14 | 137 | `template_for_head` | `find_template`, `template_for_head` | `find_template` | — | yes | — |
| 15 | 143 | `take_template_args` | `take_template_arg`, `take_template_args` | — | `take_template_arg` | yes | — |
| 16 | 150 | `take_template_arg` | — | — | — | no | — |
| 17 | 155 | `reapply_args` | `reapply_args` | — | — | yes | — |
| 18 | 162 | `generated_local_key` | `encode_string`, `serialize_terms`, `fresh_generated_key` | — | `encode_string`, `serialize_terms`, `fresh_generated_key` | no | — |
| 19 | 169 | `fresh_generated_key` | `generated_candidate`, `fresh_generated_key_match`, `has_string` | — | `generated_candidate`, `fresh_generated_key_match`, `has_string` | no | 3 |
| 20 | 173 | `fresh_generated_key_match` | `fresh_generated_key` | `fresh_generated_key` | — | no | 3 |
| 21 | 178 | `generated_candidate` | — | — | — | no | — |
| 22 | 183 | `generated_key` | `qualify`, `generated_local_key` | `qualify`, `generated_local_key` | — | no | — |
| 23 | 188 | `encode_string` | — | — | — | no | — |
| 24 | 191 | `encode_quantity` | — | — | — | no | — |
| 25 | 197 | `serialize_strings` | `encode_string`, `serialize_strings` | `encode_string` | — | yes | — |
| 26 | 202 | `serialize_nats` | `serialize_nats` | — | — | yes | — |
| 27 | 207 | `serialize_quantities` | `encode_quantity`, `serialize_quantities` | `encode_quantity` | — | yes | — |
| 28 | 212 | `serialize_patterns` | `serialize_pattern`, `serialize_patterns` | — | `serialize_pattern` | yes | 4 |
| 29 | 217 | `serialize_pattern` | `encode_quantity`, `encode_string`, `serialize_patterns` | `encode_quantity`, `encode_string`, `serialize_patterns` | — | no | 4 |
| 30 | 222 | `serialize_terms` | `serialize_term`, `serialize_terms` | — | `serialize_term` | yes | 5 |
| 31 | 227 | `serialize_term` | `encode_string`, `serialize_term`, `serialize_strings`, `serialize_nats`, `serialize_quantities`, `serialize_terms`, `encode_quantity`, `serialize_optional_quantity`, `serialize_patterns` | `encode_string`, `serialize_strings`, `serialize_nats`, `serialize_quantities`, `serialize_terms`, `encode_quantity`, `serialize_patterns` | `serialize_optional_quantity` | yes | 5 |
| 32 | 258 | `serialize_optional_quantity` | `encode_quantity` | `encode_quantity` | — | no | — |
| 33 | 263 | `strip_namespace` | `strip_namespace_match` | — | `strip_namespace_match` | no | — |
| 34 | 266 | `strip_namespace_match` | `strip_namespace_prefix` | — | `strip_namespace_prefix` | no | — |
| 35 | 271 | `strip_namespace_prefix` | `strip_namespace_prefix_match` | — | `strip_namespace_prefix_match` | no | — |
| 36 | 274 | `strip_namespace_prefix_match` | — | — | — | no | — |
| 37 | 279 | `expand_term` | `expand_term`, `expand_terms`, `expand_application` | — | `expand_terms`, `expand_application` | yes | 6 |
| 38 | 310 | `expand_application` | `expand_application_spine`, `flatten_application` | `flatten_application` | `expand_application_spine` | no | 6 |
| 39 | 314 | `expand_application_spine` | `expand_application_template`, `template_for_head` | `template_for_head` | `expand_application_template` | no | 6 |
| 40 | 319 | `expand_application_template` | `expand_term`, `template_arity`, `expand_application_arguments`, `take_template_args` | `expand_term`, `take_template_args` | `template_arity`, `expand_application_arguments` | no | 6 |
| 41 | 326 | `template_arity` | `leading_template_count` | `leading_template_count` | — | no | — |
| 42 | 330 | `expand_application_arguments` | `expand_term`, `drop_args`, `expand_terms`, `specialize_head`, `generated_key`, `reapply_args` | `expand_term`, `generated_key`, `reapply_args` | `drop_args`, `expand_terms`, `specialize_head` | no | 6 |
| 43 | 339 | `specialize_head` | — | — | — | no | — |
| 44 | 345 | `drop_args` | `drop_args` | — | — | yes | — |
| 45 | 352 | `specialize_definition` | `specialize_prefix`, `specialize_definition_result`, `generated_local_key` | `generated_local_key` | `specialize_prefix`, `specialize_definition_result` | no | — |
| 46 | 358 | `specialize_definition_result` | — | — | — | no | — |
| 47 | 362 | `specialize_prefix` | `binder_count`, `substitute_binders`, `substitute_optional`, `substitute_body`, `specialize_prefix` | — | `binder_count`, `substitute_binders`, `substitute_optional`, `substitute_body` | yes | — |
| 48 | 373 | `binder_count` | `binder_count` | — | — | yes | — |
| 49 | 378 | `substitute_binders` | `substitute_binders` | — | — | yes | — |
| 50 | 388 | `substitute_optional` | — | — | — | no | — |
| 51 | 393 | `substitute_body` | — | — | — | no | — |
| 52 | 397 | `expand_terms` | `expand_term`, `expand_terms` | `expand_term` | — | yes | 6 |
| 53 | 402 | `strip_template_decls` | `strip_template_definition`, `has_template_binder`, `expand_binders`, `expand_term`, `expand_constructors`, `strip_template_decls`, `expand_clauses` | `has_template_binder`, `expand_term` | `strip_template_definition`, `expand_binders`, `expand_constructors`, `expand_clauses` | yes | 7 |
| 54 | 414 | `strip_template_definition` | `strip_canonical_template`, `canonical_template_key`, `strip_instance_or_definition`, `is_template_instance` | — | `strip_canonical_template`, `canonical_template_key`, `strip_instance_or_definition`, `is_template_instance` | no | 7 |
| 55 | 421 | `strip_canonical_template` | `template_instances`, `strip_template_decls` | `strip_template_decls` | `template_instances` | no | 7 |
| 56 | 426 | `strip_instance_or_definition` | `strip_template_decls`, `expand_definition` | `strip_template_decls` | `expand_definition` | no | 7 |
| 57 | 431 | `canonical_template_key` | `canonical_template_match`, `strip_namespace` | `strip_namespace` | `canonical_template_match` | no | 8 |
| 58 | 439 | `canonical_template_match` | `canonical_template_key` | `canonical_template_key` | — | no | 8 |
| 59 | 444 | `generated_local_keys` | `generated_local_key_match` | — | `generated_local_key_match` | no | 9 |
| 60 | 452 | `generated_local_key_match` | `generated_local_keys` | `generated_local_keys` | — | no | 9 |
| 61 | 457 | `has_generated_local_key` | `has_string` | — | `has_string` | no | — |
| 62 | 460 | `is_template_instance` | `qualify`, `generated_identity_found`, `find_generated_identity` | `qualify` | `generated_identity_found`, `find_generated_identity` | no | — |
| 63 | 464 | `generated_identity_found` | — | — | — | no | — |
| 64 | 469 | `template_instances` | `generated_local_keys`, `template_instances_for_keys` | `generated_local_keys` | `template_instances_for_keys` | no | — |
| 65 | 473 | `template_instances_for_keys` | `template_instance_definition`, `has_generated_local_key`, `template_instances_for_keys` | `has_generated_local_key` | `template_instance_definition` | yes | 10 |
| 66 | 482 | `template_instance_definition` | `expand_definition`, `template_instances_for_keys` | `template_instances_for_keys` | `expand_definition` | no | 10 |
| 67 | 487 | `expand_constructors` | `expand_binders`, `expand_constructors` | — | `expand_binders` | yes | — |
| 68 | 495 | `expand_clauses` | `expand_term`, `expand_maybe`, `expand_clauses` | `expand_term` | `expand_maybe` | yes | — |
| 69 | 503 | `expand_maybe` | `expand_term` | `expand_term` | — | no | — |
| 70 | 507 | `expand_definition` | `expand_binders`, `expand_optional`, `expand_body` | — | `expand_binders`, `expand_optional`, `expand_body` | no | — |
| 71 | 512 | `expand_body` | `expand_term` | `expand_term` | — | no | — |
| 72 | 517 | `expand_optional` | `expand_term` | `expand_term` | — | no | — |
| 73 | 522 | `expand_binders` | `expand_term`, `expand_binders` | `expand_term` | — | yes | — |
| 74 | 530 | `find_actual` | `find_actual_spine`, `flatten_application`, `find_actual`, `first_actual`, `find_actual_terms` | `flatten_application` | `find_actual_spine`, `first_actual`, `find_actual_terms` | yes | 11 |
| 75 | 556 | `find_actual_spine` | `find_actual_head`, `head_key` | — | `find_actual_head`, `head_key` | no | 11 |
| 76 | 560 | `find_actual_head` | `find_actual_key`, `find_actual_application_parts` | — | `find_actual_key`, `find_actual_application_parts` | no | 11 |
| 77 | 565 | `find_actual_key` | `find_actual_prefix`, `wrapped_prefix`, `find_actual_application_parts` | — | `find_actual_prefix`, `wrapped_prefix`, `find_actual_application_parts` | no | 11 |
| 78 | 570 | `find_actual_prefix` | `find_actual_application_parts`, `drop_args`, `first_actual`, `find_actual_terms` | `drop_args` | `find_actual_application_parts`, `first_actual`, `find_actual_terms` | no | 11 |
| 79 | 578 | `find_actual_application_parts` | `first_actual`, `find_actual` | `find_actual` | `first_actual` | no | 11 |
| 80 | 583 | `head_key` | `head_key` | — | — | yes | — |
| 81 | 589 | `wrapped_prefix` | `wrapped_prefix_cons`, `wrapped_prefix` | — | `wrapped_prefix_cons` | yes | — |
| 82 | 595 | `wrapped_prefix_cons` | — | — | — | no | — |
| 83 | 600 | `find_actual_terms` | `first_actual`, `find_actual`, `find_actual_terms` | `find_actual` | `first_actual` | yes | 11 |
| 84 | 605 | `first_actual` | — | — | — | no | — |
| 85 | 608 | `actual_in_declarations` | `actual_definition`, `has_template_binder`, `first_actual`, `find_actual_binders`, `find_actual`, `find_actual_constructors`, `actual_in_declarations`, `find_actual_clauses` | `has_template_binder`, `first_actual`, `find_actual` | `actual_definition`, `find_actual_binders`, `find_actual_constructors`, `find_actual_clauses` | yes | 12 |
| 86 | 620 | `actual_definition` | `actual_in_declarations`, `find_actual_body`, `first_actual`, `find_actual_binders`, `find_actual_optional` | `actual_in_declarations`, `first_actual` | `find_actual_body`, `find_actual_binders`, `find_actual_optional` | no | 12 |
| 87 | 627 | `find_actual_body` | `find_actual` | `find_actual` | — | no | — |
| 88 | 632 | `actual_in_modules` | `visible_templates`, `template_aliases`, `actual_in_aliases`, `first_actual`, `expand_actual_values`, `actual_in_modules` | `first_actual` | `visible_templates`, `template_aliases`, `actual_in_aliases`, `expand_actual_values` | yes | — |
| 89 | 643 | `template_aliases` | `template_aliases_found`, `find_template` | `find_template` | `template_aliases_found` | no | — |
| 90 | 646 | `template_aliases_found` | `strip_namespace`, `template_local_alias`, `imported_alias_names` | `strip_namespace` | `template_local_alias`, `imported_alias_names` | no | — |
| 91 | 654 | `template_local_alias` | — | — | — | no | — |
| 92 | 659 | `imported_alias_names` | `imported_alias_match` | — | `imported_alias_match` | no | 13 |
| 93 | 667 | `imported_alias_match` | `imported_alias_names` | `imported_alias_names` | — | no | 13 |
| 94 | 672 | `actual_in_aliases` | `first_actual`, `actual_in_declarations`, `actual_in_aliases` | `first_actual`, `actual_in_declarations` | — | yes | — |
| 95 | 676 | `expand_actual_values` | `expand_terms`, `expand_actual_values` | `expand_terms` | — | yes | — |
| 96 | 681 | `find_actual_binders` | `first_actual`, `find_actual`, `find_actual_binders` | `first_actual`, `find_actual` | — | yes | — |
| 97 | 689 | `find_actual_optional` | `find_actual` | `find_actual` | — | no | — |
| 98 | 694 | `find_actual_constructors` | `first_actual`, `find_actual_binders`, `find_actual_constructors` | `first_actual`, `find_actual_binders` | — | yes | — |
| 99 | 701 | `find_actual_clauses` | `first_actual`, `find_actual`, `find_actual_maybe`, `find_actual_clauses` | `first_actual`, `find_actual` | `find_actual_maybe` | yes | — |
| 100 | 708 | `find_actual_maybe` | `find_actual` | `find_actual` | — | no | — |
| 101 | 712 | `has_string` | `has_string_match` | — | `has_string_match` | no | 14 |
| 102 | 718 | `has_string_match` | `has_string` | `has_string` | — | no | 14 |
| 103 | 723 | `has_top_key` | `has_top_key` | — | — | yes | — |
| 104 | 735 | `find_generated_identity` | `find_generated_identity_match` | — | `find_generated_identity_match` | no | 15 |
| 105 | 743 | `find_generated_identity_match` | `find_generated_identity` | `find_generated_identity` | — | no | 15 |
| 106 | 748 | `template_span` | — | — | — | no | — |
| 107 | 752 | `generated_actuals` | `expand_terms`, `serialize_terms`, `template_name`, `encode_string`, `generated_local_key`, `generated_key`, `generated_actual_case`, `find_generated_identity` | `expand_terms`, `serialize_terms`, `encode_string`, `generated_local_key`, `generated_key`, `find_generated_identity` | `template_name`, `generated_actual_case` | no | 16 |
| 108 | 764 | `template_name` | — | — | — | no | — |
| 109 | 768 | `generated_actual_case` | `generated_identity_collision`, `generated_actual_new`, `has_top_key` | `has_top_key` | `generated_identity_collision`, `generated_actual_new` | no | 16 |
| 110 | 774 | `generated_identity_collision` | `template_span`, `generated_actuals` | `template_span`, `generated_actuals` | — | no | 16 |
| 111 | 779 | `generated_actual_new` | `template_span`, `specialize_definition`, `generated_actual_complete`, `generated_actuals` | `template_span`, `specialize_definition`, `generated_actuals` | `generated_actual_complete` | no | 16 |
| 112 | 787 | `generated_actual_complete` | — | — | — | no | — |
| 113 | 791 | `generated_for_module` | `generated_for_module_match` | — | `generated_for_module_match` | no | 17 |
| 114 | 799 | `generated_for_module_match` | `generated_for_module`, `generated_for_module_here`, `generated_actuals`, `actual_in_modules` | `generated_for_module`, `generated_actuals`, `actual_in_modules` | `generated_for_module_here` | no | 17 |
| 115 | 805 | `generated_for_module_here` | `generated_for_module_merge`, `generated_for_module` | `generated_for_module` | `generated_for_module_merge` | no | 17 |
| 116 | 811 | `generated_for_module_merge` | — | — | — | no | — |
| 117 | 815 | `generate_round` | `generate_round_loaded`, `generated_for_module` | `generated_for_module` | `generate_round_loaded` | no | 18 |
| 118 | 823 | `generate_round_loaded` | `generate_round_merge`, `generate_round` | `generate_round` | `generate_round_merge` | no | 18 |
| 119 | 828 | `generate_round_merge` | `first_invalid` | — | `first_invalid` | no | — |
| 120 | 838 | `generate_until_stable` | `generate_until_result`, `generate_round` | `generate_round` | `generate_until_result` | no | 19 |
| 121 | 841 | `generate_until_result` | `generate_until_stable` | `generate_until_stable` | — | no | 19 |
| 122 | 850 | `visible_templates` | `local_templates`, `imported_templates` | — | `local_templates`, `imported_templates` | no | — |
| 123 | 853 | `local_templates` | `local_template_match` | — | `local_template_match` | no | 20 |
| 124 | 861 | `local_template_match` | `strip_namespace`, `local_templates` | `strip_namespace`, `local_templates` | — | no | 20 |
| 125 | 866 | `imported_templates` | `imported_from`, `imported_templates` | — | `imported_from` | yes | — |
| 126 | 875 | `imported_from` | `imported_from_match` | — | `imported_from_match` | no | 21 |
| 127 | 883 | `imported_from_match` | `strip_namespace`, `imported_from` | `strip_namespace`, `imported_from` | — | no | 21 |
| 128 | 890 | `expand_modules` | `visible_templates`, `strip_template_decls`, `expand_modules` | `visible_templates`, `strip_template_decls` | — | yes | — |
| 129 | 901 | `has_late_template_binder` | `has_late_template_binder` | — | — | yes | — |
| 130 | 911 | `invalid_template_definitions` | `first_invalid`, `invalid_template_decls`, `invalid_template_definitions` | — | `first_invalid`, `invalid_template_decls` | yes | — |
| 131 | 919 | `invalid_template_decls` | `invalid_template_decl`, `has_late_template_binder`, `invalid_template_decls` | `has_late_template_binder` | `invalid_template_decl` | yes | 22 |
| 132 | 928 | `invalid_template_decl` | `invalid_template_decls` | `invalid_template_decls` | — | no | 22 |
| 133 | 933 | `invalid_application` | `invalid_reference`, `find_template`, `invalid_application_spine`, `flatten_application`, `first_invalid`, `invalid_application`, `invalid_terms` | `find_template`, `flatten_application` | `invalid_reference`, `invalid_application_spine`, `first_invalid`, `invalid_terms` | yes | 23 |
| 134 | 962 | `invalid_reference` | — | — | — | no | — |
| 135 | 967 | `invalid_application_spine` | `invalid_application_head`, `template_for_head` | `template_for_head` | `invalid_application_head` | no | 23 |
| 136 | 972 | `invalid_application_head` | `template_arity`, `invalid_application_arity`, `invalid_application_parts` | `template_arity` | `invalid_application_arity`, `invalid_application_parts` | no | 23 |
| 137 | 979 | `invalid_application_arity` | `invalid_application_arguments`, `take_template_args` | `take_template_args` | `invalid_application_arguments` | no | 23 |
| 138 | 984 | `invalid_application_arguments` | `first_invalid`, `invalid_template_args`, `invalid_terms`, `drop_args` | `drop_args` | `first_invalid`, `invalid_template_args`, `invalid_terms` | no | 23 |
| 139 | 989 | `invalid_application_parts` | `first_invalid`, `invalid_application` | `invalid_application` | `first_invalid` | no | 23 |
| 140 | 994 | `invalid_template_args` | `invalid_template_argument`, `has_open_vars` | — | `invalid_template_argument`, `has_open_vars` | no | 23 |
| 141 | 1001 | `invalid_template_argument` | `first_invalid`, `invalid_application`, `invalid_template_args` | `invalid_application`, `invalid_template_args` | `first_invalid` | no | 23 |
| 142 | 1007 | `has_open_vars` | `has_open_vars`, `has_open_vars_terms` | — | `has_open_vars_terms` | yes | 24 |
| 143 | 1033 | `has_open_vars_terms` | `has_open_vars`, `has_open_vars_terms` | `has_open_vars` | — | yes | 24 |
| 144 | 1037 | `invalid_terms` | `first_invalid`, `invalid_application`, `invalid_terms` | `invalid_application` | `first_invalid` | yes | 23 |
| 145 | 1042 | `first_invalid` | — | — | — | no | — |
| 146 | 1047 | `invalid_definitions` | `invalid_definition`, `has_template_binder`, `first_invalid`, `invalid_binders`, `invalid_application`, `invalid_constructors`, `invalid_definitions`, `invalid_clauses` | `has_template_binder`, `first_invalid`, `invalid_application` | `invalid_definition`, `invalid_binders`, `invalid_constructors`, `invalid_clauses` | yes | 25 |
| 147 | 1059 | `invalid_definition` | `invalid_definitions`, `invalid_def_body`, `first_invalid`, `invalid_binders`, `invalid_optional` | `invalid_definitions`, `first_invalid` | `invalid_def_body`, `invalid_binders`, `invalid_optional` | no | 25 |
| 148 | 1066 | `invalid_def_body` | `invalid_application` | `invalid_application` | — | no | — |
| 149 | 1071 | `invalid_optional` | `invalid_application` | `invalid_application` | — | no | — |
| 150 | 1076 | `invalid_binders` | `first_invalid`, `invalid_application`, `invalid_binders` | `first_invalid`, `invalid_application` | — | yes | — |
| 151 | 1084 | `invalid_constructors` | `first_invalid`, `invalid_binders`, `invalid_constructors` | `first_invalid`, `invalid_binders` | — | yes | — |
| 152 | 1091 | `invalid_clauses` | `first_invalid`, `invalid_application`, `invalid_maybe`, `invalid_clauses` | `first_invalid`, `invalid_application` | `invalid_maybe` | yes | — |
| 153 | 1098 | `invalid_maybe` | `invalid_application` | `invalid_application` | — | no | — |
| 154 | 1103 | `expand` | `template_expand_templates`, `collect_templates`, `invalid_template_definitions` | `collect_templates`, `invalid_template_definitions` | `template_expand_templates` | no | — |
| 155 | 1106 | `template_expand_templates` | `template_expand_modules`, `invalid_modules` | — | `template_expand_modules`, `invalid_modules` | no | — |
| 156 | 1112 | `template_expand_modules` | `template_expand_round`, `generate_until_stable` | `generate_until_stable` | `template_expand_round` | no | — |
| 157 | 1118 | `template_expand_round` | `template_expand_generated`, `invalid_modules` | — | `template_expand_generated`, `invalid_modules` | no | — |
| 158 | 1124 | `template_expand_generated` | `expand_modules` | `expand_modules` | — | no | — |
| 159 | 1129 | `invalid_modules` | `visible_templates`, `first_invalid`, `invalid_definitions`, `invalid_modules` | `visible_templates`, `first_invalid`, `invalid_definitions` | — | yes | — |

## Every forward constraint

| User index/name | Required index/name | Call lines | Class |
|---|---|---|---|
| 2 `collect_templates` | 4 `collect_template_decls` | 65 | A: acyclic inter-SCC |
| 2 `collect_templates` | 3 `top_keys` | 65 | A: acyclic inter-SCC |
| 4 `collect_template_decls` | 5 `collect_template_decl` | 82 | C: mutual SCC |
| 4 `collect_template_decls` | 6 `has_template_binder` | 82 | A: acyclic inter-SCC |
| 5 `collect_template_decl` | 7 `qualify` | 88 | A: acyclic inter-SCC |
| 7 `qualify` | 8 `qualify_match` | 102 | A: acyclic inter-SCC |
| 9 `find_template` | 10 `find_template_match` | 115 | C: mutual SCC |
| 11 `flatten_application` | 12 `flatten_append` | 124 | A: acyclic inter-SCC |
| 15 `take_template_args` | 16 `take_template_arg` | 147 | A: acyclic inter-SCC |
| 18 `generated_local_key` | 23 `encode_string` | 165 | A: acyclic inter-SCC |
| 18 `generated_local_key` | 30 `serialize_terms` | 165 | A: acyclic inter-SCC |
| 18 `generated_local_key` | 19 `fresh_generated_key` | 167 | A: acyclic inter-SCC |
| 19 `fresh_generated_key` | 21 `generated_candidate` | 170 | A: acyclic inter-SCC |
| 19 `fresh_generated_key` | 20 `fresh_generated_key_match` | 171 | C: mutual SCC |
| 19 `fresh_generated_key` | 101 `has_string` | 171 | A: acyclic inter-SCC |
| 28 `serialize_patterns` | 29 `serialize_pattern` | 215 | C: mutual SCC |
| 30 `serialize_terms` | 31 `serialize_term` | 225 | C: mutual SCC |
| 31 `serialize_term` | 32 `serialize_optional_quantity` | 241 | A: acyclic inter-SCC |
| 33 `strip_namespace` | 34 `strip_namespace_match` | 264 | A: acyclic inter-SCC |
| 34 `strip_namespace_match` | 35 `strip_namespace_prefix` | 269 | A: acyclic inter-SCC |
| 35 `strip_namespace_prefix` | 36 `strip_namespace_prefix_match` | 272 | A: acyclic inter-SCC |
| 37 `expand_term` | 52 `expand_terms` | 285, 295, 296, 297, 298, 305, 305, 307 | C: mutual SCC |
| 37 `expand_term` | 38 `expand_application` | 294 | C: mutual SCC |
| 38 `expand_application` | 39 `expand_application_spine` | 312 | C: mutual SCC |
| 39 `expand_application_spine` | 40 `expand_application_template` | 317 | C: mutual SCC |
| 40 `expand_application_template` | 41 `template_arity` | 323 | A: acyclic inter-SCC |
| 40 `expand_application_template` | 42 `expand_application_arguments` | 324 | C: mutual SCC |
| 42 `expand_application_arguments` | 44 `drop_args` | 334 | A: acyclic inter-SCC |
| 42 `expand_application_arguments` | 52 `expand_terms` | 335, 337 | C: mutual SCC |
| 42 `expand_application_arguments` | 43 `specialize_head` | 336 | A: acyclic inter-SCC |
| 45 `specialize_definition` | 47 `specialize_prefix` | 355 | A: acyclic inter-SCC |
| 45 `specialize_definition` | 46 `specialize_definition_result` | 356 | A: acyclic inter-SCC |
| 47 `specialize_prefix` | 48 `binder_count` | 365 | A: acyclic inter-SCC |
| 47 `specialize_prefix` | 49 `substitute_binders` | 366 | A: acyclic inter-SCC |
| 47 `specialize_prefix` | 50 `substitute_optional` | 367 | A: acyclic inter-SCC |
| 47 `specialize_prefix` | 51 `substitute_body` | 368 | A: acyclic inter-SCC |
| 53 `strip_template_decls` | 54 `strip_template_definition` | 408 | C: mutual SCC |
| 53 `strip_template_decls` | 73 `expand_binders` | 410 | A: acyclic inter-SCC |
| 53 `strip_template_decls` | 67 `expand_constructors` | 410 | A: acyclic inter-SCC |
| 53 `strip_template_decls` | 68 `expand_clauses` | 412 | A: acyclic inter-SCC |
| 54 `strip_template_definition` | 55 `strip_canonical_template` | 417 | C: mutual SCC |
| 54 `strip_template_definition` | 57 `canonical_template_key` | 417 | A: acyclic inter-SCC |
| 54 `strip_template_definition` | 56 `strip_instance_or_definition` | 419 | C: mutual SCC |
| 54 `strip_template_definition` | 62 `is_template_instance` | 419 | A: acyclic inter-SCC |
| 55 `strip_canonical_template` | 64 `template_instances` | 423 | A: acyclic inter-SCC |
| 56 `strip_instance_or_definition` | 70 `expand_definition` | 429 | A: acyclic inter-SCC |
| 57 `canonical_template_key` | 58 `canonical_template_match` | 437 | C: mutual SCC |
| 59 `generated_local_keys` | 60 `generated_local_key_match` | 450 | C: mutual SCC |
| 61 `has_generated_local_key` | 101 `has_string` | 458 | A: acyclic inter-SCC |
| 62 `is_template_instance` | 63 `generated_identity_found` | 462 | A: acyclic inter-SCC |
| 62 `is_template_instance` | 104 `find_generated_identity` | 462 | A: acyclic inter-SCC |
| 64 `template_instances` | 65 `template_instances_for_keys` | 471 | A: acyclic inter-SCC |
| 65 `template_instances_for_keys` | 66 `template_instance_definition` | 479 | C: mutual SCC |
| 66 `template_instance_definition` | 70 `expand_definition` | 484 | A: acyclic inter-SCC |
| 67 `expand_constructors` | 73 `expand_binders` | 493 | A: acyclic inter-SCC |
| 68 `expand_clauses` | 69 `expand_maybe` | 501 | A: acyclic inter-SCC |
| 70 `expand_definition` | 73 `expand_binders` | 510 | A: acyclic inter-SCC |
| 70 `expand_definition` | 72 `expand_optional` | 510 | A: acyclic inter-SCC |
| 70 `expand_definition` | 71 `expand_body` | 510 | A: acyclic inter-SCC |
| 74 `find_actual` | 75 `find_actual_spine` | 533 | C: mutual SCC |
| 74 `find_actual` | 84 `first_actual` | 535, 536, 537, 540, 541, 544, 545, 547, 548, 548, 549, 549, 550, 552 | A: acyclic inter-SCC |
| 74 `find_actual` | 83 `find_actual_terms` | 536, 543, 544, 545, 546, 550, 550, 552 | C: mutual SCC |
| 75 `find_actual_spine` | 76 `find_actual_head` | 558 | C: mutual SCC |
| 75 `find_actual_spine` | 80 `head_key` | 558 | A: acyclic inter-SCC |
| 76 `find_actual_head` | 77 `find_actual_key` | 562 | C: mutual SCC |
| 76 `find_actual_head` | 79 `find_actual_application_parts` | 563 | C: mutual SCC |
| 77 `find_actual_key` | 78 `find_actual_prefix` | 567 | C: mutual SCC |
| 77 `find_actual_key` | 81 `wrapped_prefix` | 567 | A: acyclic inter-SCC |
| 77 `find_actual_key` | 79 `find_actual_application_parts` | 568 | C: mutual SCC |
| 78 `find_actual_prefix` | 79 `find_actual_application_parts` | 572 | C: mutual SCC |
| 78 `find_actual_prefix` | 84 `first_actual` | 575 | A: acyclic inter-SCC |
| 78 `find_actual_prefix` | 83 `find_actual_terms` | 575, 575 | C: mutual SCC |
| 79 `find_actual_application_parts` | 84 `first_actual` | 580 | A: acyclic inter-SCC |
| 81 `wrapped_prefix` | 82 `wrapped_prefix_cons` | 592 | A: acyclic inter-SCC |
| 83 `find_actual_terms` | 84 `first_actual` | 603 | A: acyclic inter-SCC |
| 85 `actual_in_declarations` | 86 `actual_definition` | 614 | C: mutual SCC |
| 85 `actual_in_declarations` | 96 `find_actual_binders` | 616 | A: acyclic inter-SCC |
| 85 `actual_in_declarations` | 98 `find_actual_constructors` | 616 | A: acyclic inter-SCC |
| 85 `actual_in_declarations` | 99 `find_actual_clauses` | 618 | A: acyclic inter-SCC |
| 86 `actual_definition` | 87 `find_actual_body` | 624 | A: acyclic inter-SCC |
| 86 `actual_definition` | 96 `find_actual_binders` | 625 | A: acyclic inter-SCC |
| 86 `actual_definition` | 97 `find_actual_optional` | 625 | A: acyclic inter-SCC |
| 88 `actual_in_modules` | 122 `visible_templates` | 638 | A: acyclic inter-SCC |
| 88 `actual_in_modules` | 89 `template_aliases` | 639 | A: acyclic inter-SCC |
| 88 `actual_in_modules` | 94 `actual_in_aliases` | 640 | A: acyclic inter-SCC |
| 88 `actual_in_modules` | 95 `expand_actual_values` | 641 | A: acyclic inter-SCC |
| 89 `template_aliases` | 90 `template_aliases_found` | 644 | A: acyclic inter-SCC |
| 90 `template_aliases_found` | 91 `template_local_alias` | 651 | A: acyclic inter-SCC |
| 90 `template_aliases_found` | 92 `imported_alias_names` | 652 | A: acyclic inter-SCC |
| 92 `imported_alias_names` | 93 `imported_alias_match` | 665 | C: mutual SCC |
| 99 `find_actual_clauses` | 100 `find_actual_maybe` | 706 | A: acyclic inter-SCC |
| 101 `has_string` | 102 `has_string_match` | 716 | C: mutual SCC |
| 104 `find_generated_identity` | 105 `find_generated_identity_match` | 741 | C: mutual SCC |
| 107 `generated_actuals` | 108 `template_name` | 758 | A: acyclic inter-SCC |
| 107 `generated_actuals` | 109 `generated_actual_case` | 762 | C: mutual SCC |
| 109 `generated_actual_case` | 110 `generated_identity_collision` | 771 | C: mutual SCC |
| 109 `generated_actual_case` | 111 `generated_actual_new` | 772 | C: mutual SCC |
| 111 `generated_actual_new` | 112 `generated_actual_complete` | 785 | A: acyclic inter-SCC |
| 113 `generated_for_module` | 114 `generated_for_module_match` | 797 | C: mutual SCC |
| 114 `generated_for_module_match` | 115 `generated_for_module_here` | 803 | C: mutual SCC |
| 115 `generated_for_module_here` | 116 `generated_for_module_merge` | 809 | A: acyclic inter-SCC |
| 117 `generate_round` | 118 `generate_round_loaded` | 821 | C: mutual SCC |
| 118 `generate_round_loaded` | 119 `generate_round_merge` | 826 | A: acyclic inter-SCC |
| 119 `generate_round_merge` | 145 `first_invalid` | 835 | A: acyclic inter-SCC |
| 120 `generate_until_stable` | 121 `generate_until_result` | 839 | C: mutual SCC |
| 122 `visible_templates` | 123 `local_templates` | 851 | A: acyclic inter-SCC |
| 122 `visible_templates` | 125 `imported_templates` | 851 | A: acyclic inter-SCC |
| 123 `local_templates` | 124 `local_template_match` | 859 | C: mutual SCC |
| 125 `imported_templates` | 126 `imported_from` | 873 | A: acyclic inter-SCC |
| 126 `imported_from` | 127 `imported_from_match` | 881 | C: mutual SCC |
| 130 `invalid_template_definitions` | 145 `first_invalid` | 917 | A: acyclic inter-SCC |
| 130 `invalid_template_definitions` | 131 `invalid_template_decls` | 917 | A: acyclic inter-SCC |
| 131 `invalid_template_decls` | 132 `invalid_template_decl` | 925 | C: mutual SCC |
| 133 `invalid_application` | 134 `invalid_reference` | 937 | A: acyclic inter-SCC |
| 133 `invalid_application` | 135 `invalid_application_spine` | 939 | C: mutual SCC |
| 133 `invalid_application` | 145 `first_invalid` | 940, 942, 943, 944, 946, 947, 950, 951, 953, 954, 954, 955, 955, 956, 958 | A: acyclic inter-SCC |
| 133 `invalid_application` | 144 `invalid_terms` | 943, 949, 950, 951, 952, 956, 956, 958 | C: mutual SCC |
| 135 `invalid_application_spine` | 136 `invalid_application_head` | 970 | C: mutual SCC |
| 136 `invalid_application_head` | 137 `invalid_application_arity` | 976 | C: mutual SCC |
| 136 `invalid_application_head` | 139 `invalid_application_parts` | 977 | C: mutual SCC |
| 137 `invalid_application_arity` | 138 `invalid_application_arguments` | 982 | C: mutual SCC |
| 138 `invalid_application_arguments` | 145 `first_invalid` | 987 | A: acyclic inter-SCC |
| 138 `invalid_application_arguments` | 140 `invalid_template_args` | 987 | C: mutual SCC |
| 138 `invalid_application_arguments` | 144 `invalid_terms` | 987 | C: mutual SCC |
| 139 `invalid_application_parts` | 145 `first_invalid` | 991 | A: acyclic inter-SCC |
| 140 `invalid_template_args` | 141 `invalid_template_argument` | 998 | C: mutual SCC |
| 140 `invalid_template_args` | 142 `has_open_vars` | 998 | A: acyclic inter-SCC |
| 141 `invalid_template_argument` | 145 `first_invalid` | 1005 | A: acyclic inter-SCC |
| 142 `has_open_vars` | 143 `has_open_vars_terms` | 1011, 1020, 1021, 1022, 1023, 1027, 1027, 1029 | C: mutual SCC |
| 144 `invalid_terms` | 145 `first_invalid` | 1040 | A: acyclic inter-SCC |
| 146 `invalid_definitions` | 147 `invalid_definition` | 1053 | C: mutual SCC |
| 146 `invalid_definitions` | 150 `invalid_binders` | 1055 | A: acyclic inter-SCC |
| 146 `invalid_definitions` | 151 `invalid_constructors` | 1055 | A: acyclic inter-SCC |
| 146 `invalid_definitions` | 152 `invalid_clauses` | 1057 | A: acyclic inter-SCC |
| 147 `invalid_definition` | 148 `invalid_def_body` | 1063 | A: acyclic inter-SCC |
| 147 `invalid_definition` | 150 `invalid_binders` | 1064 | A: acyclic inter-SCC |
| 147 `invalid_definition` | 149 `invalid_optional` | 1064 | A: acyclic inter-SCC |
| 152 `invalid_clauses` | 153 `invalid_maybe` | 1096 | A: acyclic inter-SCC |
| 154 `expand` | 155 `template_expand_templates` | 1104 | A: acyclic inter-SCC |
| 155 `template_expand_templates` | 156 `template_expand_modules` | 1110 | A: acyclic inter-SCC |
| 155 `template_expand_templates` | 159 `invalid_modules` | 1110 | A: acyclic inter-SCC |
| 156 `template_expand_modules` | 157 `template_expand_round` | 1116 | A: acyclic inter-SCC |
| 157 `template_expand_round` | 158 `template_expand_generated` | 1122 | A: acyclic inter-SCC |
| 157 `template_expand_round` | 159 `invalid_modules` | 1122 | A: acyclic inter-SCC |

## Derived prerequisite-first condensation order

This is a **component** order, NOT a valid Bend definition order. Bracketed non-singletons cannot be linearized without refactoring. Earliest-original available component is selected at each step to avoid gratuitous unrelated movement.

1. `span_of`
2. `top_keys`
3. `has_template_binder`
4. `qualify_match`
5. `qualify`
6. [`collect_template_decls`, `collect_template_decl`]
7. `collect_templates`
8. [`find_template`, `find_template_match`]
9. `flatten_append`
10. `flatten_application`
11. `leading_template_count`
12. `template_for_head`
13. `take_template_arg`
14. `take_template_args`
15. `reapply_args`
16. `generated_candidate`
17. `encode_string`
18. `encode_quantity`
19. `serialize_strings`
20. `serialize_nats`
21. `serialize_quantities`
22. [`serialize_patterns`, `serialize_pattern`]
23. `serialize_optional_quantity`
24. [`serialize_terms`, `serialize_term`]
25. `strip_namespace_prefix_match`
26. `strip_namespace_prefix`
27. `strip_namespace_match`
28. `strip_namespace`
29. `template_arity`
30. `specialize_head`
31. `drop_args`
32. `specialize_definition_result`
33. `binder_count`
34. `substitute_binders`
35. `substitute_optional`
36. `substitute_body`
37. `specialize_prefix`
38. [`canonical_template_key`, `canonical_template_match`]
39. [`generated_local_keys`, `generated_local_key_match`]
40. `generated_identity_found`
41. `head_key`
42. `wrapped_prefix_cons`
43. `wrapped_prefix`
44. `first_actual`
45. [`find_actual`, `find_actual_spine`, `find_actual_head`, `find_actual_key`, `find_actual_prefix`, `find_actual_application_parts`, `find_actual_terms`]
46. `find_actual_body`
47. `template_local_alias`
48. [`imported_alias_names`, `imported_alias_match`]
49. `template_aliases_found`
50. `template_aliases`
51. `find_actual_binders`
52. `find_actual_optional`
53. `find_actual_constructors`
54. `find_actual_maybe`
55. `find_actual_clauses`
56. [`actual_in_declarations`, `actual_definition`]
57. `actual_in_aliases`
58. [`has_string`, `has_string_match`]
59. [`fresh_generated_key`, `fresh_generated_key_match`]
60. `generated_local_key`
61. `generated_key`
62. [`expand_term`, `expand_application`, `expand_application_spine`, `expand_application_template`, `expand_application_arguments`, `expand_terms`]
63. `specialize_definition`
64. `has_generated_local_key`
65. `expand_maybe`
66. `expand_clauses`
67. `expand_body`
68. `expand_optional`
69. `expand_binders`
70. `expand_constructors`
71. `expand_definition`
72. [`template_instances_for_keys`, `template_instance_definition`]
73. `template_instances`
74. `expand_actual_values`
75. `has_top_key`
76. [`find_generated_identity`, `find_generated_identity_match`]
77. `is_template_instance`
78. [`strip_template_decls`, `strip_template_definition`, `strip_canonical_template`, `strip_instance_or_definition`]
79. `template_span`
80. `template_name`
81. `generated_actual_complete`
82. [`generated_actuals`, `generated_actual_case`, `generated_identity_collision`, `generated_actual_new`]
83. `generated_for_module_merge`
84. [`local_templates`, `local_template_match`]
85. [`imported_from`, `imported_from_match`]
86. `imported_templates`
87. `visible_templates`
88. `actual_in_modules`
89. [`generated_for_module`, `generated_for_module_match`, `generated_for_module_here`]
90. `expand_modules`
91. `has_late_template_binder`
92. [`invalid_template_decls`, `invalid_template_decl`]
93. `invalid_reference`
94. [`has_open_vars`, `has_open_vars_terms`]
95. `first_invalid`
96. `generate_round_merge`
97. [`generate_round`, `generate_round_loaded`]
98. [`generate_until_stable`, `generate_until_result`]
99. `invalid_template_definitions`
100. [`invalid_application`, `invalid_application_spine`, `invalid_application_head`, `invalid_application_arity`, `invalid_application_arguments`, `invalid_application_parts`, `invalid_template_args`, `invalid_template_argument`, `invalid_terms`]
101. `invalid_def_body`
102. `invalid_optional`
103. `invalid_binders`
104. `invalid_constructors`
105. `invalid_maybe`
106. `invalid_clauses`
107. [`invalid_definitions`, `invalid_definition`]
108. `template_expand_generated`
109. `invalid_modules`
110. `template_expand_round`
111. `template_expand_modules`
112. `template_expand_templates`
113. `expand`
