#!/usr/bin/env Rscript

# Derive H01-aligned H06_daily diagnostic and claim classifications without
# fitting, refitting, predicting, simulating, or changing any p/FDR value.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "readr", "tibble", "tidyr")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing synchronized packages: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_h01_diagnostic_alignment_contract.R"
))

h06d_h01_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06-D-014 finalization requires R 4.6.1; found %s",
  as.character(getRversion())
)

roots <- h06d_h01_artifact_roots(root)
direct_inputs <- h06d_h01_verify_direct_inputs(root)
h06d_h01_write_csv(
  direct_inputs,
  file.path(
    roots$manifests,
    "H06_daily_h01_diagnostic_alignment_input_manifest.csv"
  )
)
production_manifest <- readr::read_csv(
  file.path(
    roots$manifests,
    "H06_daily_non_l10_production_output_manifest.csv"
  ),
  show_col_types = FALSE
)
production_before <- vapply(
  file.path(root, production_manifest$relative_path),
  h06d_h01_sha256,
  character(1L)
)
h06d_h01_assert(
  identical(unname(production_before), production_manifest$sha256),
  "A protected H06-D-G2 output changed before H06-D-014 finalization"
)

diagnostics <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_non_l10_production_diagnostic_assessment.csv"
  ),
  show_col_types = FALSE
)
bh <- readr::read_csv(
  file.path(
    roots$tables,
    "H06_daily_non_l10_production_bh_families.csv"
  ),
  show_col_types = FALSE
)
bh_tokens <- readr::read_csv(
  file.path(
    roots$tables,
    "H06_daily_non_l10_production_bh_families.csv"
  ),
  col_types = readr::cols(.default = readr::col_character()),
  na = c("", "NA")
)
plot_index <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_h01_visual_residual_plot_index.csv"
  ),
  show_col_types = FALSE
)
visual_review <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_h01_visual_residual_review.csv"
  ),
  show_col_types = FALSE
)
timing_unit_audit <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_h01_timing_unit_contract_audit.csv"
  ),
  show_col_types = FALSE
)
timing_family_impact <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_h01_timing_unit_family_impact.csv"
  ),
  show_col_types = FALSE
)

h06d_h01_assert(
  nrow(diagnostics) == 468L && !anyDuplicated(diagnostics$frame_key) &&
    nrow(bh) == 180L &&
    nrow(plot_index) == 471L &&
    nrow(visual_review) == 471L &&
    nrow(timing_unit_audit) == 10L &&
    nrow(timing_family_impact) == 6L,
  "The H06-D-014 input inventories are incomplete"
)
h06d_h01_assert(
  all(visual_review$visual_residual_verdict %in%
        c("PASS", "REVIEW_LIMITATION", "FAIL_GROSS")) &&
    !any(visual_review$numeric_threshold_set_verdict),
  "A visual verdict is missing or was set by a numeric threshold"
)

# Reproduce the provisional, pre-visual mapping exactly. This replay is an
# implementation cross-check only; it is not the final residual assessment.
previsual <- diagnostics |>
  dplyr::mutate(
    provisional_h01_class = dplyr::case_when(
      grepl("^NOT_ACCEPTABLE", .data$distribution_gate) ~ "FAIL_MAJOR_GATE",
      grepl("LIMITATION|NO_SIMULATION", .data$distribution_gate) ~ "WARN_REVIEW",
      TRUE ~ "PASS"
    ),
    provisional_scope = dplyr::if_else(
      .data$dataset_id == "primary" &
        .data$placement_id == "near_eye" &
        .data$sample_role == "all_available",
      "primary_near_eye_all_available_39_cells",
      "outside_primary_near_eye_scope"
    )
  )

previsual_summary <- dplyr::bind_rows(
  previsual |>
    dplyr::count(.data$provisional_h01_class, name = "cells") |>
    dplyr::mutate(scope = "all_468_cells", .before = 1L),
  previsual |>
    dplyr::filter(
      .data$provisional_scope == "primary_near_eye_all_available_39_cells"
    ) |>
    dplyr::count(.data$provisional_h01_class, name = "cells") |>
    dplyr::mutate(
      scope = "primary_near_eye_all_available_39_cells",
      .before = 1L
    )
) |>
  tidyr::complete(
    .data$scope,
    provisional_h01_class = c("PASS", "WARN_REVIEW", "FAIL_MAJOR_GATE"),
    fill = list(cells = 0L)
  ) |>
  dplyr::arrange(
    factor(
      .data$scope,
      levels = c(
        "all_468_cells",
        "primary_near_eye_all_available_39_cells"
      )
    ),
    factor(
      .data$provisional_h01_class,
      levels = c("PASS", "WARN_REVIEW", "FAIL_MAJOR_GATE")
    )
  ) |>
  dplyr::mutate(
    mapping_basis = paste(
      "Frozen pre-visual distribution-gate replay; numeric residual",
      "summaries do not set the final visual verdict"
    ),
    authorization = "H06-D-014",
    gate = "H06-D-G2A"
  )

expected_previsual <- tibble::tribble(
  ~scope, ~provisional_h01_class, ~cells,
  "all_468_cells", "PASS", 311L,
  "all_468_cells", "WARN_REVIEW", 157L,
  "all_468_cells", "FAIL_MAJOR_GATE", 0L,
  "primary_near_eye_all_available_39_cells", "PASS", 26L,
  "primary_near_eye_all_available_39_cells", "WARN_REVIEW", 13L,
  "primary_near_eye_all_available_39_cells", "FAIL_MAJOR_GATE", 0L
)
h06d_h01_assert(
  identical(
    previsual_summary |>
      dplyr::select("scope", "provisional_h01_class", "cells"),
    expected_previsual
  ),
  "The required 311/157/0 and 26/13/0 pre-visual replay was not reproduced"
)

visual_non_l10 <- visual_review |>
  dplyr::filter(.data$scope == "non_l10_stage2_production") |>
  dplyr::select(
    "frame_key", "audit_cell_id", "visual_residual_verdict",
    "visual_reason_codes", "visual_explanation", "reviewer", "review_date",
    "review_method", "numeric_threshold_set_verdict",
    "diagnostic_plot_relative_path", "diagnostic_plot_sha256",
    "source_data_relative_path", "source_data_sha256",
    "atlas_group_key", "atlas_relative_path", "atlas_sha256"
  )
plot_fit_status <- plot_index |>
  dplyr::filter(.data$scope == "non_l10_stage2_production") |>
  dplyr::select(
    "frame_key", "model_relative_path", "model_file_sha256",
    "model_object_sha256", "fit_error", "fit_warning_count", "fit_warnings",
    "observed_minimum", "observed_maximum"
  )

duration_metric_ids <- c(
  "duration_above_1000",
  "duration_above_250_wake",
  "duration_below_10_pre_sleep",
  "duration_below_1_sleep_environment",
  "longest_bout_above_250"
)

classification <- diagnostics |>
  dplyr::left_join(visual_non_l10, by = "frame_key", relationship = "one-to-one") |>
  dplyr::left_join(plot_fit_status, by = "frame_key", relationship = "one-to-one") |>
  dplyr::mutate(
    timing_construct_unit_valid = !(
      .data$dataset_id == "gap_timing_unaware" &
        .data$metric_slot %in% c(9L, 10L, 11L, 12L, 13L)
    ),
    base_fit_available = is.na(.data$fit_error) | !nzchar(.data$fit_error),
    base_numerical_estimability = dplyr::case_when(
      .data$route == "mixed_model" ~
        .data$model_gate == "ACCEPTABLE" &
        .data$additive_estimable & .data$heterogeneity_estimable &
        .data$additive_converged &
        .data$additive_positive_definite_hessian &
        !dplyr::coalesce(.data$additive_singular, TRUE),
      .data$route == "participant_cluster_HC3" ~
        dplyr::coalesce(.data$all_three_candidate_models_pass, FALSE) &
        dplyr::coalesce(.data$association_estimable, FALSE),
      TRUE ~ FALSE
    ),
    required_clock_support = dplyr::case_when(
      !.data$is_timing ~ TRUE,
      !.data$timing_construct_unit_valid ~ FALSE,
      .data$response_transform == "clock_hours" ~
        .data$observed_minimum >= 0 & .data$observed_maximum < 24,
      .data$response_transform == "clock_hours_midnight_after_16" ~
        .data$observed_minimum > -8 & .data$observed_maximum <= 16,
      TRUE ~ FALSE
    ),
    observed_response_support = dplyr::case_when(
      .data$is_timing & .data$response_transform == "clock_hours" ~
        .data$observed_minimum >= 0 & .data$observed_maximum < 24,
      .data$is_timing &
        .data$response_transform == "clock_hours_midnight_after_16" ~
        .data$observed_minimum > -8 & .data$observed_maximum <= 16,
      .data$is_timing ~ FALSE,
      .data$metric_id %in% duration_metric_ids ~
        .data$source_minimum >= -1e-8 & .data$source_maximum <= 24 + 1e-8,
      TRUE ~ .data$source_minimum >= -1e-8
    ),
    predicted_value_bound_warning = dplyr::case_when(
      is.na(.data$prediction_bound_acceptable) ~ FALSE,
      TRUE ~ !.data$prediction_bound_acceptable
    ),
    audit_threshold_warning = FALSE,
    base_fit_warning = dplyr::coalesce(.data$fit_warning_count, 0L) > 0L,
    hard_gate_failed =
      !.data$base_fit_available |
      !.data$base_numerical_estimability |
      !.data$timing_construct_unit_valid |
      !.data$required_clock_support |
      !.data$observed_response_support |
      .data$visual_residual_verdict == "FAIL_GROSS",
    hard_gate_reason_codes = dplyr::case_when(
      !.data$base_fit_available ~ "BASE_FIT_UNAVAILABLE",
      !.data$base_numerical_estimability ~ "BASE_NUMERICAL_NON_ESTIMABILITY",
      !.data$timing_construct_unit_valid ~
        "TIMING_CONSTRUCT_UNIT_DOUBLE_CONVERSION",
      !.data$required_clock_support ~ "REQUIRED_CLOCK_SUPPORT_FAILURE",
      !.data$observed_response_support ~ "OBSERVED_RESPONSE_SUPPORT_FAILURE",
      .data$visual_residual_verdict == "FAIL_GROSS" ~ "VISUAL_FAIL_GROSS",
      TRUE ~ "NONE"
    ),
    warning_gate_present =
      .data$visual_residual_verdict == "REVIEW_LIMITATION" |
      .data$predicted_value_bound_warning |
      .data$audit_threshold_warning |
      .data$base_fit_warning,
    warning_reason_codes = dplyr::case_when(
      .data$visual_residual_verdict == "REVIEW_LIMITATION" ~
        .data$visual_reason_codes,
      .data$predicted_value_bound_warning ~ "PREDICTED_VALUE_BOUND_WARNING",
      .data$audit_threshold_warning ~ "AUDIT_THRESHOLD_WARNING",
      .data$base_fit_warning ~ "BASE_FIT_WARNING",
      TRUE ~ "NONE"
    ),
    h01_diagnostic_class = dplyr::case_when(
      .data$hard_gate_failed ~ "FAIL_MAJOR_GATE",
      .data$warning_gate_present ~ "WARN_REVIEW",
      TRUE ~ "PASS"
    ),
    h01_reader_label = dplyr::recode(
      .data$h01_diagnostic_class,
      FAIL_MAJOR_GATE = "Not acceptable",
      WARN_REVIEW = "Acceptable with limitations",
      PASS = "Acceptable"
    ),
    h01_association_claim_status = dplyr::case_when(
      .data$h01_diagnostic_class == "FAIL_MAJOR_GATE" ~
        "ASSOCIATION_CLAIM_BLOCKED_BY_HARD_GATE",
      .data$h01_diagnostic_class == "WARN_REVIEW" ~
        "ASSOCIATION_CLAIM_ELIGIBLE_WITH_EXPLICIT_LIMITATIONS",
      TRUE ~ "ASSOCIATION_CLAIM_ELIGIBLE"
    ),
    h01_heterogeneity_claim_status = dplyr::case_when(
      .data$h01_diagnostic_class == "FAIL_MAJOR_GATE" ~
        "SITE_INTERACTION_CLAIM_BLOCKED_BY_HARD_GATE",
      .data$route == "participant_cluster_HC3" ~
        "SITE_INTERACTION_CLAIM_SENSITIVITY_DEPENDENT_WITH_LIMITATIONS",
      .data$h01_diagnostic_class == "WARN_REVIEW" ~
        "SITE_INTERACTION_CLAIM_ELIGIBLE_WITH_EXPLICIT_LIMITATIONS",
      TRUE ~ "SITE_INTERACTION_CLAIM_ELIGIBLE"
    ),
    ar_sidecar_nonblocking = TRUE,
    influence_sidecar_nonblocking = TRUE,
    period_sidecar_nonblocking = TRUE,
    family_sensitivity_sidecar_nonblocking = TRUE,
    numeric_residual_threshold_set_verdict = FALSE,
    authorization = "H06-D-014",
    gate = "H06-D-G2A",
    r_version = as.character(getRversion())
  )

classification_contract_checks <- c(
  rows_468 = nrow(classification) == 468L,
  unique_frame_keys = !anyDuplicated(classification$frame_key),
  visual_verdict_complete = !any(is.na(classification$visual_residual_verdict)),
  no_numeric_visual_verdict = !any(classification$numeric_threshold_set_verdict),
  no_numeric_final_verdict =
    !any(classification$numeric_residual_threshold_set_verdict),
  base_fit_available = all(classification$base_fit_available),
  base_numerically_estimable = all(classification$base_numerical_estimability),
  timing_construct_failures_exactly_90 =
    sum(!classification$timing_construct_unit_valid) == 90L,
  clock_support_failures_match_timing_construct = identical(
    !classification$required_clock_support,
    !classification$timing_construct_unit_valid
  ),
  observed_support_complete = all(classification$observed_response_support),
  construct_audit_matches_cells =
    sum(timing_unit_audit$affected_stored_cells) ==
    sum(!classification$timing_construct_unit_valid)
)
h06d_h01_assert(
  all(classification_contract_checks),
  "The final H01-aligned classification failed checks: %s",
  paste(names(classification_contract_checks)[!classification_contract_checks],
        collapse = ", ")
)

final_summary <- classification |>
  dplyr::count(
    .data$h01_diagnostic_class,
    .data$h01_reader_label,
    name = "cells"
  ) |>
  tidyr::complete(
    h01_diagnostic_class = c("PASS", "WARN_REVIEW", "FAIL_MAJOR_GATE"),
    fill = list(cells = 0L)
  ) |>
  dplyr::mutate(
    h01_reader_label = dplyr::case_when(
      .data$h01_diagnostic_class == "PASS" ~ "Acceptable",
      .data$h01_diagnostic_class == "WARN_REVIEW" ~
        "Acceptable with limitations",
      TRUE ~ "Not acceptable"
    ),
    visual_review_completed_cells = 468L,
    numeric_threshold_verdicts = 0L,
    sidecars_nonblocking = TRUE,
    authorization = "H06-D-014",
    gate = "H06-D-G2A"
  ) |>
  dplyr::arrange(factor(
    .data$h01_diagnostic_class,
    levels = c("PASS", "WARN_REVIEW", "FAIL_MAJOR_GATE")
  ))

h06d_h01_assert(
  sum(final_summary$cells) == 468L &&
    final_summary$cells[final_summary$h01_diagnostic_class == "WARN_REVIEW"] ==
      378L &&
    final_summary$cells[final_summary$h01_diagnostic_class == "FAIL_MAJOR_GATE"] ==
      90L,
  "The final visual classification counts are not the sealed review result"
)

# Preserve every original sidecar field and verify exact in-memory identity.
sidecar_groups <- list(
  ar = grep(
    "(^ar_|post_ar|residual_lag1|site_lag1|timing_ar|tweedie_ar)",
    names(diagnostics),
    value = TRUE
  ),
  influence = grep("^influence_", names(diagnostics), value = TRUE),
  period = grep("^period_", names(diagnostics), value = TRUE),
  response_family = grep(
    "student_t|timing_student|tweedie|simulation_diagnostic|prediction_bound",
    names(diagnostics),
    value = TRUE
  )
)
sidecar_retention <- dplyr::bind_rows(lapply(
  names(sidecar_groups),
  function(group) {
    fields <- unique(c("frame_key", sidecar_groups[[group]]))
    source_object <- diagnostics[, fields, drop = FALSE]
    derived_object <- classification[, fields, drop = FALSE]
    tibble::tibble(
      sidecar_group = group,
      fields = length(fields) - 1L,
      rows = nrow(source_object),
      source_object_sha256 = h06d_h01_object_sha256(source_object),
      derived_object_sha256 = h06d_h01_object_sha256(derived_object),
      exact_in_memory_identity = identical(source_object, derived_object),
      overall_class_input = FALSE,
      authorization = "H06-D-014",
      gate = "H06-D-G2A"
    )
  }
))
h06d_h01_assert(
  all(sidecar_retention$exact_in_memory_identity) &&
    !any(sidecar_retention$overall_class_input),
  "At least one required sidecar was lost or used as an overall gate"
)

# Derived claim eligibility copies every p/FDR field unchanged.
claim_table <- bh |>
  dplyr::left_join(
    classification |>
      dplyr::select(
        "frame_key", "route", "is_timing", "h01_diagnostic_class",
        "h01_reader_label", "h01_association_claim_status",
        "h01_heterogeneity_claim_status", "visual_residual_verdict",
        "visual_reason_codes", "ar_disposition", "temporal_gate",
        "influence_classification", "influence_gate",
        "period_sensitivity_classification", "period_gate",
        "student_t_classification", "timing_student_classification",
        "tweedie_simulation_diagnostic_status"
      ),
    by = "frame_key",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    fdr_supported = !is.na(.data$bh_adjusted_p_value) &
      .data$bh_adjusted_p_value < 0.05,
    multiplicity_family_construct_valid =
      !.data$multiplicity_family_id %in%
      timing_family_impact$multiplicity_family_id,
    h01_claim_eligible = dplyr::case_when(
      .data$metric_slot %in% c(3L, 15L) ~ FALSE,
      !.data$multiplicity_family_construct_valid ~ FALSE,
      !.data$fdr_supported ~ FALSE,
      is.na(.data$h01_diagnostic_class) ~ FALSE,
      .data$h01_diagnostic_class == "FAIL_MAJOR_GATE" ~ FALSE,
      TRUE ~ TRUE
    ),
    became_claim_eligible_under_h01 =
      .data$h01_claim_eligible &
      grepl("DIAGNOSTICALLY_NOT_ACCEPTABLE", .data$adjusted_inferential_decision),
    h01_claim_disposition = dplyr::case_when(
      .data$metric_slot == 3L ~
        "NO_CLAIM_FROZEN_L10_NON_ESTIMABLE_NAMED_NA_SLOT",
      !.data$multiplicity_family_construct_valid & .data$metric_slot == 15L ~
        "FROZEN_MDER_MODEL_RAW_UNCHANGED_GAP_BH_FAMILY_BLOCKED",
      .data$metric_slot == 15L ~ "FROZEN_MDER_CLAIM_UNCHANGED",
      !.data$multiplicity_family_construct_valid ~
        "NO_CLAIM_GAP_BH_FAMILY_INVALID_TIMING_UNIT_SLOTS",
      !.data$fdr_supported ~ "NO_FDR_SUPPORT",
      .data$h01_diagnostic_class == "FAIL_MAJOR_GATE" ~
        "FDR_SUPPORT_BUT_HARD_DIAGNOSTIC_FAILURE",
      .data$test_type == "heterogeneity" &
        .data$route == "participant_cluster_HC3" ~
        "FDR_SUPPORTED_SITE_INTERACTION_SENSITIVITY_DEPENDENT_WITH_LIMITATIONS",
      .data$h01_diagnostic_class == "WARN_REVIEW" ~
        "FDR_SUPPORTED_CLAIM_ELIGIBLE_WITH_EXPLICIT_LIMITATIONS",
      TRUE ~ "FDR_SUPPORTED_CLAIM_ELIGIBLE"
    ),
    p_fdr_values_changed = FALSE,
    authorization = "H06-D-014",
    gate = "H06-D-G2A"
  )

h06d_h01_assert(
  nrow(claim_table) == nrow(bh) &&
    identical(claim_table$raw_p_value, bh$raw_p_value) &&
    identical(claim_table$bh_adjusted_p_value, bh$bh_adjusted_p_value) &&
    identical(claim_table$raw_rank_within_available, bh$raw_rank_within_available) &&
    identical(claim_table$raw_decision, bh$raw_decision) &&
    identical(claim_table$adjusted_decision, bh$adjusted_decision) &&
    sum(!claim_table$multiplicity_family_construct_valid) == 90L &&
    dplyr::n_distinct(
      claim_table$multiplicity_family_id[
        !claim_table$multiplicity_family_construct_valid
      ]
    ) == 6L &&
    !any(claim_table$p_fdr_values_changed),
  "A frozen raw p-value, FDR field, rank, or decision changed"
)

claim_transition_summary <- claim_table |>
  dplyr::filter(!.data$metric_slot %in% c(3L, 15L)) |>
  dplyr::group_by(.data$dataset_id, .data$test_type) |>
  dplyr::summarise(
    named_non_l10_slots = dplyr::n(),
    fdr_supported = sum(.data$fdr_supported),
    multiplicity_family_construct_valid =
      all(.data$multiplicity_family_construct_valid),
    h01_claim_eligible = sum(.data$h01_claim_eligible),
    became_claim_eligible_under_h01 =
      sum(.data$became_claim_eligible_under_h01),
    hard_gate_blocked = sum(
      .data$fdr_supported &
        .data$h01_diagnostic_class == "FAIL_MAJOR_GATE",
      na.rm = TRUE
    ),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    p_fdr_values_changed = FALSE,
    authorization = "H06-D-014",
    gate = "H06-D-G2A"
  )

# Preserve the exact serialized source tokens for the two floating-point
# inferential fields. This avoids any last-bit shortening when the new derived
# table is written and makes the no-p/FDR-change contract textually auditable.
claim_table_serialized <- claim_table
claim_table_serialized$raw_p_value <- bh_tokens$raw_p_value
claim_table_serialized$bh_adjusted_p_value <- bh_tokens$bh_adjusted_p_value

# Reclassify only the already fitted shifted-log L10 pilot. No pilot p-value is
# accepted and no L10 production/FDR slot is authorized by this amendment.
l10_verdict <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_pilot_verdict.csv"
  ),
  show_col_types = FALSE
)
l10_diagnostics <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_pilot_diagnostics.csv"
  ),
  show_col_types = FALSE
)
l10_visual <- visual_review |>
  dplyr::filter(.data$scope == "shifted_log_l10_pilot") |>
  dplyr::select(
    "predictor_id", "audit_cell_id", "visual_residual_verdict",
    "visual_reason_codes", "visual_explanation", "reviewer", "review_date",
    "diagnostic_plot_relative_path", "diagnostic_plot_sha256",
    "source_data_relative_path", "source_data_sha256"
  )
l10_reclassification <- l10_verdict |>
  dplyr::left_join(
    l10_diagnostics,
    by = c("run_id", "predictor_order", "predictor_id"),
    relationship = "one-to-one",
    suffix = c("_verdict", "_diagnostic")
  ) |>
  dplyr::left_join(l10_visual, by = "predictor_id", relationship = "one-to-one") |>
  dplyr::mutate(
    hard_base_gate_failed =
      .data$numerical_disposition_verdict != "ACCEPTABLE" |
      !.data$additive_design_estimable |
      !.data$heterogeneity_design_estimable |
      !.data$converged |
      !.data$positive_definite_hessian |
      dplyr::coalesce(.data$singular, TRUE) |
      .data$visual_residual_verdict == "FAIL_GROSS",
    h01_diagnostic_class = dplyr::case_when(
      .data$hard_base_gate_failed ~ "FAIL_MAJOR_GATE",
      .data$visual_residual_verdict == "REVIEW_LIMITATION" |
        .data$bound_disposition_verdict != "ACCEPTABLE" |
        .data$zero_mass_disposition_verdict != "ACCEPTABLE" |
        .data$family_sensitivity_disposition != "ACCEPTABLE" ~ "WARN_REVIEW",
      TRUE ~ "PASS"
    ),
    h01_reader_label = dplyr::recode(
      .data$h01_diagnostic_class,
      FAIL_MAJOR_GATE = "Not acceptable",
      WARN_REVIEW = "Acceptable with limitations",
      PASS = "Acceptable"
    ),
    temporal_disposition_is_nonblocking_sidecar = TRUE,
    pilot_raw_p_values_accepted = FALSE,
    l10_bh_slot_populated = FALSE,
    full_l10_production_authorized = FALSE,
    historical_two_part_status =
      "NOT_ACCEPTABLE_NON_ESTIMABLE_COMPONENT_SEPARATION_P_VALUES_NA",
    authorization = "H06-D-014",
    gate = "H06-D-G2A",
    r_version = as.character(getRversion())
  )
h06d_h01_assert(
  nrow(l10_reclassification) == 3L &&
    all(l10_reclassification$h01_diagnostic_class == "WARN_REVIEW") &&
    all(l10_reclassification$temporal_disposition_is_nonblocking_sidecar) &&
    !any(l10_reclassification$pilot_raw_p_values_accepted) &&
    !any(l10_reclassification$l10_bh_slot_populated) &&
    !any(l10_reclassification$full_l10_production_authorized),
  "The shifted-log L10 pilot was not reclassified within H06-D-014 scope"
)

output_paths <- c(
  previsual = file.path(
    roots$diagnostics,
    "H06_daily_h01_previsual_replay.csv"
  ),
  classification = file.path(
    roots$diagnostics,
    "H06_daily_h01_aligned_cell_classification.csv"
  ),
  final_summary = file.path(
    roots$tables,
    "H06_daily_h01_aligned_classification_summary.csv"
  ),
  sidecars = file.path(
    roots$diagnostics,
    "H06_daily_h01_sidecar_retention_audit.csv"
  ),
  claims = file.path(
    roots$tables,
    "H06_daily_h01_aligned_claim_eligibility.csv"
  ),
  claim_summary = file.path(
    roots$tables,
    "H06_daily_h01_claim_transition_summary.csv"
  ),
  l10 = file.path(
    roots$diagnostics,
    "H06_daily_h01_l10_shiftlog_reclassification.csv"
  )
)
h06d_h01_write_csv(previsual_summary, output_paths[["previsual"]])
h06d_h01_write_csv(classification, output_paths[["classification"]])
h06d_h01_write_csv(final_summary, output_paths[["final_summary"]])
h06d_h01_write_csv(sidecar_retention, output_paths[["sidecars"]])
h06d_h01_write_csv(claim_table_serialized, output_paths[["claims"]])
h06d_h01_write_csv(claim_transition_summary, output_paths[["claim_summary"]])
h06d_h01_write_csv(l10_reclassification, output_paths[["l10"]])

# Recheck all protected scientific identities after writing only new derived
# amendment artifacts.
production_after <- vapply(
  file.path(root, production_manifest$relative_path),
  h06d_h01_sha256,
  character(1L)
)
direct_after <- vapply(
  file.path(root, direct_inputs$relative_path),
  h06d_h01_sha256,
  character(1L)
)
h06d_h01_assert(
  identical(unname(production_after), production_manifest$sha256) &&
    identical(unname(direct_after), direct_inputs$expected_sha256),
  "A protected scientific or direct input identity changed during finalization"
)

protected_identity <- dplyr::bind_rows(
  production_manifest |>
    dplyr::transmute(
      record_set = "H06_D_G2_987_ENTRY_OUTPUT_MANIFEST",
      relative_path = .data$relative_path,
      role = .data$role,
      expected_sha256 = .data$sha256,
      observed_before_sha256 = unname(production_before),
      observed_after_sha256 = unname(production_after),
      bytes_before = as.numeric(file.info(file.path(root, .data$relative_path))$size),
      bytes_after = .data$bytes
    ),
  direct_inputs |>
    dplyr::transmute(
      record_set = "H06_D_014_DIRECT_INPUTS",
      relative_path = .data$relative_path,
      role = .data$role,
      expected_sha256 = .data$expected_sha256,
      observed_before_sha256 = .data$observed_sha256,
      observed_after_sha256 = unname(direct_after),
      bytes_before = .data$bytes,
      bytes_after = as.numeric(file.info(file.path(root, .data$relative_path))$size)
    )
  ) |>
  dplyr::mutate(
    identity_verified =
      .data$expected_sha256 == .data$observed_before_sha256 &
      .data$expected_sha256 == .data$observed_after_sha256 &
      .data$bytes_before == .data$bytes_after,
    authorization = "H06-D-014",
    gate = "H06-D-G2A",
    r_version = as.character(getRversion())
  )
h06d_h01_assert(
  all(protected_identity$identity_verified),
  "Protected-identity verification failed"
)
h06d_h01_write_csv(
  protected_identity,
  file.path(
    roots$diagnostics,
    "H06_daily_h01_protected_identity_verification.csv"
  )
)

cat(sprintf(
  paste0(
    "H06-D-014 finalization complete: %d PASS, %d WARN_REVIEW, ",
    "%d FAIL_MAJOR_GATE; %d FDR-supported claims newly eligible; ",
    "%d protected identities unchanged.\n"
  ),
  sum(classification$h01_diagnostic_class == "PASS"),
  sum(classification$h01_diagnostic_class == "WARN_REVIEW"),
  sum(classification$h01_diagnostic_class == "FAIL_MAJOR_GATE"),
  sum(claim_table$became_claim_eligible_under_h01),
  nrow(protected_identity)
))
