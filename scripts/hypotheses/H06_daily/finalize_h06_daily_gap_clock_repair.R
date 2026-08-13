#!/usr/bin/env Rscript

# Finalize the targeted H06_daily gap clock-hour repair from sealed model and
# diagnostic checkpoints. No model is fitted here. The script replaces only
# the 90 repaired classification cells, completes only the six gap BH families,
# and leaves all historical artifacts untouched.

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
  "scripts/hypotheses/H06_daily/h06_daily_gap_clock_repair_contract.R"
))

h06d_gap_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Gap clock repair finalization requires R 4.6.1"
)
paths <- h06d_gap_paths(root)
authorization <- h06d_gap_authorization()
authorization_id <- authorization$authorization
gate_id <- authorization$gate
invisible(h06d_gap_verify_direct_pins(root))
protected_final <- h06d_gap_verify_protected_1011(root, "pre_finalization")
g2a_manifest_path <- file.path(
  paths$manifests,
  "H06_daily_h01_diagnostic_alignment_output_manifest.csv"
)
g2a_outputs_final <- h06d_gap_verify_manifest(
  root,
  g2a_manifest_path,
  "pre_finalization_g2a_outputs"
)

read_diagnostic <- function(name) {
  readr::read_csv(file.path(paths$diagnostic, name), show_col_types = FALSE)
}
read_table <- function(name) {
  readr::read_csv(file.path(paths$tables, name), show_col_types = FALSE)
}

historical_classification <- read_diagnostic(
  "H06_daily_h01_aligned_cell_classification.csv"
)
diagnostics <- read_diagnostic("H06_daily_gap_clock_repair_diagnostics.csv")
influence <- read_diagnostic("H06_daily_gap_clock_repair_influence_summary.csv")
student <- read_diagnostic("H06_daily_gap_clock_repair_student_t_stability.csv")
ar_stability <- read_diagnostic("H06_daily_gap_clock_repair_ar_stability.csv")
ar_models <- read_diagnostic("H06_daily_gap_clock_repair_ar_model_diagnostics.csv")
visual <- read_diagnostic("H06_daily_gap_clock_repair_visual_review.csv")
base_index <- read_diagnostic("H06_daily_gap_clock_repair_base_checkpoint.csv")
provisional_bh <- read_table(
  "H06_daily_gap_clock_repair_bh_families_provisional.csv"
)
historical_bh <- read_table("H06_daily_non_l10_production_bh_families.csv")
historical_bh_tokens <- readr::read_csv(
  file.path(paths$tables, "H06_daily_non_l10_production_bh_families.csv"),
  col_types = readr::cols(.default = readr::col_character()),
  na = c("", "NA")
)
effects <- read_table("H06_daily_gap_clock_repair_effects.csv")
scale_equivariance <- read_table(
  "H06_daily_gap_clock_repair_scale_equivariance.csv"
)
frame_invariance <- read_diagnostic(
  "H06_daily_gap_clock_repair_378_frame_invariance.csv"
)
change_audit <- read_diagnostic(
  "H06_daily_gap_clock_repair_90_cell_change_audit.csv"
)

h06d_gap_assert(
  nrow(historical_classification) == 468L &&
    nrow(diagnostics) == 90L && nrow(influence) == 90L &&
    nrow(student) == 144L && nrow(ar_stability) == 144L &&
    nrow(ar_models) == 216L && nrow(visual) == 90L &&
    nrow(base_index) == 90L && nrow(provisional_bh) == 180L &&
    nrow(historical_bh) == 180L && nrow(effects) == 90L &&
    nrow(scale_equivariance) == 30L && nrow(frame_invariance) == 378L &&
    nrow(change_audit) == 90L,
  "A required repair-finalization input is incomplete"
)
h06d_gap_assert(
  all(visual$visual_residual_verdict == "REVIEW_LIMITATION") &&
    !any(visual$numeric_threshold_set_verdict),
  "The required manual visual review is incomplete or threshold-derived"
)

# Read the plotted source data to recover the actually fitted clock-hour range.
# This avoids relying on minute-scale registry metadata in generic diagnostics.
observed_support <- lapply(seq_len(nrow(visual)), function(index) {
  source <- readr::read_csv(
    file.path(root, visual$source_data_relative_path[[index]]),
    show_col_types = FALSE
  )
  observed <- source$fitted_clock_hour + source$residual_clock_hour
  tibble::tibble(
    frame_key = visual$frame_key[[index]],
    observed_minimum = min(observed),
    observed_maximum = max(observed),
    observed_finite = all(is.finite(observed))
  )
}) |>
  dplyr::bind_rows()
h06d_gap_assert(
  nrow(observed_support) == 90L && all(observed_support$observed_finite),
  "The repaired observed-response support could not be reconstructed"
)

# One row per frame for the two HC3 sensitivity components used in the prior
# diagnostic assessment. Predictor-by-site rows remain available in their
# dedicated sidecar and do not determine the overall H01-aligned class.
student_additive <- student |>
  dplyr::filter(.data$component == "predictor_additive") |>
  dplyr::transmute(
    frame_key,
    timing_student_shift_in_hc3_se = .data$maximum_shift_in_hc3_se,
    timing_student_direction_reversal = .data$direction_reversal,
    timing_student_classification = .data$sensitivity_classification
  )
ar_additive <- ar_stability |>
  dplyr::filter(.data$component == "predictor_additive") |>
  dplyr::transmute(
    frame_key,
    timing_ar_shift_in_hc3_se = .data$maximum_shift_in_hc3_se,
    timing_ar_direction_reversal = .data$direction_reversal,
    timing_ar_classification = .data$sensitivity_classification
  )
ar_additive_models <- ar_models |>
  dplyr::filter(.data$structure == "additive") |>
  dplyr::transmute(
    frame_key,
    timing_ar_converged = .data$converged,
    timing_ar_positive_definite_hessian = .data$positive_definite_hessian,
    timing_ar_finite_fixed_effects = .data$finite_fixed_effects,
    timing_ar_finite_standard_errors = .data$finite_standard_errors,
    timing_ar_singular = .data$singular,
    timing_ar_rho = .data$ar_rho,
    timing_ar_residual_lag1 = .data$residual_lag1,
    timing_ar_maximum_absolute_site_lag1 =
      .data$maximum_absolute_site_lag1,
    timing_ar_temporal_threshold_pass = .data$temporal_threshold_pass
  )
h06d_gap_assert(
  nrow(student_additive) == 72L && nrow(ar_additive) == 72L &&
    nrow(ar_additive_models) == 72L,
  "A repaired HC3 sensitivity sidecar is incomplete"
)

# Begin with the frozen G2A rows and overlay only fields supplied by the new
# 90-cell evidence. Assignments are coerced to the existing column type so the
# 378 unaffected rows remain exactly identical, including column classes.
affected_keys <- visual$frame_key
affected_index <- match(affected_keys, historical_classification$frame_key)
h06d_gap_assert(
  !anyNA(affected_index) && !anyDuplicated(affected_index),
  "The 90 repaired frame keys do not map one-to-one to the frozen grid"
)
repair_rows <- historical_classification[affected_index, , drop = FALSE]

coerce_like <- function(value, template) {
  if (is.logical(template)) return(as.logical(value))
  if (is.integer(template)) return(as.integer(value))
  if (is.numeric(template)) return(as.numeric(value))
  as.character(value)
}
overlay <- function(target, source, key = "frame_key") {
  source_index <- match(target[[key]], source[[key]])
  h06d_gap_assert(!anyNA(source_index), "A repair overlay key is missing")
  common <- setdiff(intersect(names(target), names(source)), key)
  for (column in common) {
    target[[column]] <- coerce_like(
      source[[column]][source_index],
      target[[column]]
    )
  }
  target
}

repair_rows <- overlay(repair_rows, diagnostics)
repair_rows <- overlay(repair_rows, influence)
repair_rows <- overlay(repair_rows, visual)
repair_rows <- overlay(repair_rows, observed_support)
repair_rows$observed_finite <- observed_support$observed_finite[
  match(repair_rows$frame_key, observed_support$frame_key)
]

hc3_rows <- repair_rows$route == "participant_cluster_HC3"
mixed_rows <- repair_rows$route == "mixed_model"
repair_rows[hc3_rows, ] <- overlay(
  repair_rows[hc3_rows, , drop = FALSE],
  student_additive
)
repair_rows[hc3_rows, ] <- overlay(
  repair_rows[hc3_rows, , drop = FALSE],
  ar_additive
)
repair_rows[hc3_rows, ] <- overlay(
  repair_rows[hc3_rows, , drop = FALSE],
  ar_additive_models
)

base_match <- match(repair_rows$frame_key, base_index$frame_key)
model_paths <- file.path(root, base_index$checkpoint_relative_path[base_match])
model_file_sha <- vapply(model_paths, h06d_gap_sha256, character(1L))
model_object_sha <- vapply(
  model_paths,
  function(path) h06d_gap_object_sha256(readRDS(path)),
  character(1L)
)
h06d_gap_assert(
  identical(unname(model_file_sha), base_index$checkpoint_sha256[base_match]),
  "A repaired model checkpoint changed before classification"
)
repair_rows$model_relative_path <-
  base_index$checkpoint_relative_path[base_match]
repair_rows$model_file_sha256 <- model_file_sha
repair_rows$model_object_sha256 <- model_object_sha
repair_rows$fit_error <- base_index$outer_error[base_match]
repair_rows$fit_warning_count <- base_index$outer_warning_count[base_match]
repair_rows$fit_warnings <- base_index$outer_warnings[base_match]

# H01-aligned hard gates. AR, influence, period, and response-family checks are
# retained as mandatory sidecars but are deliberately absent from this hard
# gate, in accordance with H06-D-014 and the owner's clarification.
repair_rows$timing_construct_unit_valid <- TRUE
repair_rows$base_fit_available <-
  is.na(repair_rows$fit_error) | !nzchar(repair_rows$fit_error)
repair_rows$base_numerical_estimability <- ifelse(
  hc3_rows,
  repair_rows$all_three_candidate_models_pass &
    repair_rows$association_estimable & repair_rows$heterogeneity_estimable,
  repair_rows$additive_estimable & repair_rows$heterogeneity_estimable &
    repair_rows$additive_converged &
    repair_rows$additive_positive_definite_hessian &
    !repair_rows$additive_singular
)
repair_rows$required_clock_support <- ifelse(
  hc3_rows,
  repair_rows$source_clock_acceptable,
  repair_rows$observed_finite & repair_rows$observed_minimum >= 0 &
    repair_rows$observed_maximum < 24
)
repair_rows$observed_response_support <- ifelse(
  repair_rows$response_transform == "clock_hours_midnight_after_16",
  repair_rows$observed_finite & repair_rows$source_clock_acceptable,
  repair_rows$observed_finite & repair_rows$observed_minimum >= 0 &
    repair_rows$observed_maximum < 24
)
repair_rows$predicted_value_bound_warning <- ifelse(
  is.na(repair_rows$prediction_bound_acceptable),
  FALSE,
  !repair_rows$prediction_bound_acceptable
)
repair_rows$audit_threshold_warning <- FALSE
repair_rows$base_fit_warning <- repair_rows$fit_warning_count > 0L
repair_rows$hard_gate_failed <-
  !repair_rows$base_fit_available |
  !repair_rows$base_numerical_estimability |
  !repair_rows$timing_construct_unit_valid |
  !repair_rows$required_clock_support |
  !repair_rows$observed_response_support |
  repair_rows$visual_residual_verdict == "FAIL_GROSS"
repair_rows$hard_gate_reason_codes <- ifelse(
  repair_rows$hard_gate_failed,
  "UNEXPECTED_REPAIRED_HARD_GATE_FAILURE",
  "NONE"
)
repair_rows$warning_gate_present <-
  repair_rows$visual_residual_verdict == "REVIEW_LIMITATION" |
  repair_rows$predicted_value_bound_warning |
  repair_rows$audit_threshold_warning |
  repair_rows$base_fit_warning
repair_rows$warning_reason_codes <- ifelse(
  repair_rows$visual_residual_verdict == "REVIEW_LIMITATION",
  repair_rows$visual_reason_codes,
  ifelse(
    repair_rows$predicted_value_bound_warning,
    "PREDICTED_VALUE_BOUND_WARNING",
    ifelse(repair_rows$base_fit_warning, "BASE_FIT_WARNING", "NONE")
  )
)
repair_rows$h01_diagnostic_class <- ifelse(
  repair_rows$hard_gate_failed,
  "FAIL_MAJOR_GATE",
  ifelse(repair_rows$warning_gate_present, "WARN_REVIEW", "PASS")
)
repair_rows$h01_reader_label <- ifelse(
  repair_rows$h01_diagnostic_class == "FAIL_MAJOR_GATE",
  "Not acceptable",
  ifelse(
    repair_rows$h01_diagnostic_class == "WARN_REVIEW",
    "Acceptable with limitations",
    "Acceptable"
  )
)
repair_rows$h01_association_claim_status <- ifelse(
  repair_rows$h01_diagnostic_class == "FAIL_MAJOR_GATE",
  "ASSOCIATION_CLAIM_BLOCKED_BY_HARD_GATE",
  ifelse(
    repair_rows$h01_diagnostic_class == "WARN_REVIEW",
    "ASSOCIATION_CLAIM_ELIGIBLE_WITH_EXPLICIT_LIMITATIONS",
    "ASSOCIATION_CLAIM_ELIGIBLE"
  )
)
repair_rows$h01_heterogeneity_claim_status <- ifelse(
  repair_rows$h01_diagnostic_class == "FAIL_MAJOR_GATE",
  "SITE_INTERACTION_CLAIM_BLOCKED_BY_HARD_GATE",
  ifelse(
    hc3_rows,
    "SITE_INTERACTION_CLAIM_SENSITIVITY_DEPENDENT_WITH_LIMITATIONS",
    ifelse(
      repair_rows$h01_diagnostic_class == "WARN_REVIEW",
      "SITE_INTERACTION_CLAIM_ELIGIBLE_WITH_EXPLICIT_LIMITATIONS",
      "SITE_INTERACTION_CLAIM_ELIGIBLE"
    )
  )
)

# Descriptive legacy-style gates are updated for the repaired evidence, but
# remain nonblocking under the H01 architecture.
repair_rows$model_gate <- "ACCEPTABLE"
repair_rows$distribution_gate <- "ACCEPTABLE"
repair_rows$distribution_gate[hc3_rows &
  repair_rows$timing_student_classification == "SUBSTANTIAL_LIMITATION"] <-
  "ACCEPTABLE_WITH_MAJOR_STUDENT_T_LIMITATION"
repair_rows$distribution_gate[hc3_rows &
  repair_rows$timing_student_classification == "UNSTABLE"] <-
  "REVIEW_NONBLOCKING_STUDENT_T_INSTABILITY"
repair_rows$temporal_gate <- ifelse(
  hc3_rows,
  ifelse(
    repair_rows$timing_ar_classification == "UNRESOLVED_NUMERICAL_FAILURE",
    "REVIEW_NONBLOCKING_UNRESOLVED_AR_NUMERICS",
    ifelse(
      !repair_rows$timing_ar_temporal_threshold_pass,
      "REVIEW_NONBLOCKING_POST_AR_RESIDUAL_DEPENDENCE",
      ifelse(
        repair_rows$timing_ar_classification == "UNSTABLE",
        "REVIEW_NONBLOCKING_AR_EFFECT_INSTABILITY",
        ifelse(
          repair_rows$timing_ar_classification == "SUBSTANTIAL_LIMITATION",
          "REVIEW_NONBLOCKING_MAJOR_AR_EFFECT_SHIFT",
          "ACCEPTABLE_NONBLOCKING_AR_SIDECAR"
        )
      )
    )
  ),
  ifelse(
    repair_rows$ar_disposition == "NOT_TRIGGERED",
    "ACCEPTABLE_NONBLOCKING_AR_NOT_TRIGGERED",
    paste0("REVIEW_NONBLOCKING_", repair_rows$ar_disposition)
  )
)
repair_rows$period_gate <- "NOT_APPLICABLE"
repair_rows$influence_gate <- ifelse(
  repair_rows$influence_classification == "STABLE",
  "ACCEPTABLE_NONBLOCKING_INFLUENCE_SIDECAR",
  ifelse(
    repair_rows$influence_classification == "SUBSTANTIAL_LIMITATION",
    "REVIEW_NONBLOCKING_MAJOR_INFLUENCE_LIMITATION",
    "REVIEW_NONBLOCKING_INFLUENCE_INSTABILITY"
  )
)
repair_rows$diagnostic_status <- "ACCEPTABLE_WITH_LIMITATIONS"
repair_rows$association_claim_status <-
  "ASSOCIATION_CLAIM_REQUIRES_EXPLICIT_LIMITATION"
repair_rows$heterogeneity_claim_status <- ifelse(
  hc3_rows,
  "SITE_INTERACTION_CLAIM_SENSITIVITY_DEPENDENT_WITH_LIMITATIONS",
  "SITE_INTERACTION_CLAIM_REQUIRES_EXPLICIT_LIMITATION"
)
repair_rows$ar_sidecar_nonblocking <- TRUE
repair_rows$influence_sidecar_nonblocking <- TRUE
repair_rows$period_sidecar_nonblocking <- TRUE
repair_rows$family_sensitivity_sidecar_nonblocking <- TRUE
repair_rows$numeric_residual_threshold_set_verdict <- FALSE
repair_rows$authorization <- authorization_id
repair_rows$gate <- gate_id
repair_rows$r_version <- as.character(getRversion())

h06d_gap_assert(
  all(repair_rows$base_fit_available) &&
    all(repair_rows$base_numerical_estimability) &&
    all(repair_rows$timing_construct_unit_valid) &&
    all(repair_rows$required_clock_support) &&
    all(repair_rows$observed_response_support) &&
    !any(repair_rows$hard_gate_failed) &&
    all(repair_rows$h01_diagnostic_class == "WARN_REVIEW") &&
    !any(repair_rows$numeric_residual_threshold_set_verdict),
  "A repaired cell did not satisfy the authorized H01-aligned hard gates"
)

final_classification <- historical_classification
for (column in names(final_classification)) {
  final_classification[[column]][affected_index] <- coerce_like(
    repair_rows[[column]],
    final_classification[[column]]
  )
}
unaffected_index <- setdiff(seq_len(nrow(final_classification)), affected_index)
h06d_gap_assert(
  identical(
    final_classification[unaffected_index, , drop = FALSE],
    historical_classification[unaffected_index, , drop = FALSE]
  ),
  "At least one of the 378 unaffected classification rows changed"
)
h06d_gap_assert(
  nrow(final_classification) == 468L &&
    all(final_classification$h01_diagnostic_class == "WARN_REVIEW") &&
    !any(final_classification$hard_gate_failed),
  "The repaired 468-cell classification does not have the expected state"
)

classification_summary <- final_classification |>
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
    gross_visual_failures = 0L,
    hard_gate_failures = 0L,
    authorization = .env$authorization_id,
    gate = .env$gate_id
  ) |>
  dplyr::arrange(factor(
    .data$h01_diagnostic_class,
    levels = c("PASS", "WARN_REVIEW", "FAIL_MAJOR_GATE")
  ))

# Complete only the six gap families, using the provisional repaired raw tests
# and their n=15 BH values. Add the current H01-aligned diagnostic and claim
# fields without altering the frozen historical BH table.
bh_key <- c("dataset_id", "predictor_id", "test_type", "metric_slot")
provisional_key <- do.call(paste, c(provisional_bh[bh_key], sep = "::"))
historical_key <- do.call(paste, c(historical_bh[bh_key], sep = "::"))
historical_match <- match(provisional_key, historical_key)
h06d_gap_assert(
  !anyNA(historical_match) && !anyDuplicated(historical_match),
  "The repaired and historical BH keys do not match one-to-one"
)
bh_source <- provisional_bh
raw_repair_rows <- bh_source$dataset_id == "gap_timing_unaware" &
  bh_source$metric_slot %in% 9:13
raw_fields <- c("raw_p_value", "method", "test_status", "frame_key")
for (column in raw_fields) {
  bh_source[[column]][!raw_repair_rows] <-
    historical_bh[[column]][historical_match[!raw_repair_rows]]
}

# Recompute the six gap families after restoring the exact frozen raw values
# in the other ten named slots. Primary q/rank/decision fields are then copied
# directly from the historical table.
bh_source <- bh_source |>
  dplyr::group_by(.data$dataset_id, .data$predictor_id, .data$test_type) |>
  dplyr::mutate(
    bh_adjusted_p_value = dplyr::if_else(
      .data$dataset_id == "gap_timing_unaware",
      {
        output <- rep(NA_real_, dplyr::n())
        available <- is.finite(.data$raw_p_value)
        output[available] <- stats::p.adjust(
          .data$raw_p_value[available],
          method = "BH",
          n = 15L
        )
        output
      },
      .data$bh_adjusted_p_value
    ),
    raw_rank_within_available = dplyr::if_else(
      .data$dataset_id == "gap_timing_unaware",
      {
        output <- rep(NA_real_, dplyr::n())
        available <- is.finite(.data$raw_p_value)
        output[available] <- rank(.data$raw_p_value[available], ties.method = "min")
        output
      },
      .data$raw_rank_within_available
    ),
    raw_decision = dplyr::if_else(
      .data$dataset_id == "gap_timing_unaware",
      dplyr::case_when(
        !is.finite(.data$raw_p_value) ~ "NOT_ESTIMABLE",
        .data$raw_p_value < 0.05 ~ "RAW_P_LT_0.05",
        TRUE ~ "RAW_P_GE_0.05"
      ),
      .data$raw_decision
    ),
    adjusted_decision = dplyr::if_else(
      .data$dataset_id == "gap_timing_unaware",
      dplyr::case_when(
        !is.finite(.data$bh_adjusted_p_value) ~ "NOT_ESTIMABLE",
        .data$bh_adjusted_p_value < 0.05 ~ "BH_Q_LT_0.05",
        TRUE ~ "BH_Q_GE_0.05"
      ),
      .data$adjusted_decision
    )
  ) |>
  dplyr::ungroup()
primary_source_rows <- bh_source$dataset_id == "primary"
primary_fields <- c(
  "raw_p_value", "bh_adjusted_p_value", "raw_rank_within_available",
  "raw_decision", "adjusted_decision", "method", "test_status", "frame_key"
)
for (column in primary_fields) {
  bh_source[[column]][primary_source_rows] <-
    historical_bh[[column]][historical_match[primary_source_rows]]
}

claim_fields <- final_classification |>
  dplyr::select(
    "frame_key", "route", "is_timing", "h01_diagnostic_class",
    "h01_reader_label", "h01_association_claim_status",
    "h01_heterogeneity_claim_status", "visual_residual_verdict",
    "visual_reason_codes", "ar_disposition", "temporal_gate",
    "influence_classification", "influence_gate",
    "period_sensitivity_classification", "period_gate",
    "student_t_classification", "timing_student_classification",
    "tweedie_simulation_diagnostic_status"
  )
final_bh <- bh_source |>
  dplyr::rename(
    pre_h01_diagnostic_status = "diagnostic_status",
    pre_h01_association_claim_status = "association_claim_status",
    pre_h01_heterogeneity_claim_status = "heterogeneity_claim_status",
    pre_h01_claim_status = "claim_status",
    pre_h01_adjusted_inferential_decision =
      "adjusted_inferential_decision"
  ) |>
  dplyr::left_join(claim_fields, by = "frame_key", relationship = "many-to-one") |>
  dplyr::mutate(
    multiplicity_family_construct_valid = TRUE,
    fdr_supported = is.finite(.data$bh_adjusted_p_value) &
      .data$bh_adjusted_p_value < 0.05,
    diagnostic_status = dplyr::case_when(
      .data$metric_slot == 3L ~ "FROZEN_L10_NON_ESTIMABLE_NAMED_NA_SLOT",
      .data$metric_slot == 15L ~ "FROZEN_MDER_SCIENTIFIC_RESULT",
      .data$h01_diagnostic_class == "WARN_REVIEW" ~
        "ACCEPTABLE_WITH_LIMITATIONS",
      .data$h01_diagnostic_class == "PASS" ~ "ACCEPTABLE",
      TRUE ~ "NOT_ACCEPTABLE"
    ),
    association_claim_status = dplyr::case_when(
      .data$metric_slot == 3L ~ "NO_L10_CLAIM_NON_ESTIMABLE_NAMED_NA_SLOT",
      .data$metric_slot == 15L ~ "FROZEN_MDER_CLAIM_UNCHANGED",
      TRUE ~ .data$h01_association_claim_status
    ),
    heterogeneity_claim_status = dplyr::case_when(
      .data$metric_slot == 3L ~
        "NO_L10_SITE_INTERACTION_CLAIM_NON_ESTIMABLE_NAMED_NA_SLOT",
      .data$metric_slot == 15L ~
        "FROZEN_MDER_SITE_INTERACTION_CLAIM_UNCHANGED",
      TRUE ~ .data$h01_heterogeneity_claim_status
    ),
    claim_status = dplyr::if_else(
      .data$test_type == "association",
      .data$association_claim_status,
      .data$heterogeneity_claim_status
    ),
    h01_claim_eligible =
      !.data$metric_slot %in% c(3L, 15L) &
      .data$fdr_supported &
      !is.na(.data$h01_diagnostic_class) &
      .data$h01_diagnostic_class != "FAIL_MAJOR_GATE",
    h01_claim_disposition = dplyr::case_when(
      .data$metric_slot == 3L ~
        "NO_CLAIM_FROZEN_L10_NON_ESTIMABLE_NAMED_NA_SLOT",
      .data$metric_slot == 15L ~
        "FROZEN_MDER_MODEL_RAW_AND_SCIENTIFIC_RESULT_UNCHANGED",
      !.data$fdr_supported ~ "NO_FDR_SUPPORT",
      .data$h01_diagnostic_class == "FAIL_MAJOR_GATE" ~
        "FDR_SUPPORT_BUT_HARD_DIAGNOSTIC_FAILURE",
      .data$test_type == "site_heterogeneity" &
        .data$route == "participant_cluster_HC3" ~
        "FDR_SUPPORTED_SITE_INTERACTION_SENSITIVITY_DEPENDENT_WITH_LIMITATIONS",
      .data$h01_diagnostic_class == "WARN_REVIEW" ~
        "FDR_SUPPORTED_CLAIM_ELIGIBLE_WITH_EXPLICIT_LIMITATIONS",
      TRUE ~ "FDR_SUPPORTED_CLAIM_ELIGIBLE"
    ),
    adjusted_inferential_decision = dplyr::case_when(
      !is.finite(.data$bh_adjusted_p_value) ~ "NOT_ESTIMABLE",
      .data$metric_slot == 15L ~ dplyr::if_else(
        .data$bh_adjusted_p_value < 0.05,
        "FROZEN_MDER_BH_Q_LT_0.05_NO_NEW_SCIENTIFIC_CLAIM",
        "FROZEN_MDER_BH_Q_GE_0.05_NO_NEW_SCIENTIFIC_CLAIM"
      ),
      .data$bh_adjusted_p_value >= 0.05 ~ "BH_Q_GE_0.05",
      .data$test_type == "site_heterogeneity" &
        .data$route == "participant_cluster_HC3" ~
        "BH_Q_LT_0.05_SITE_INTERACTION_SENSITIVITY_DEPENDENT_WITH_LIMITATIONS",
      .data$h01_diagnostic_class == "WARN_REVIEW" ~
        "BH_Q_LT_0.05_WITH_EXPLICIT_DIAGNOSTIC_LIMITATIONS",
      TRUE ~ "BH_Q_LT_0.05"
    ),
    raw_slot_repaired = .data$dataset_id == "gap_timing_unaware" &
      .data$metric_slot %in% 9:13,
    bh_family_recomputed = .data$dataset_id == "gap_timing_unaware",
    authorization = .env$authorization_id,
    gate = .env$gate_id
  )

historical_compare <- historical_bh |>
  dplyr::select(
    dplyr::all_of(bh_key),
    historical_raw_p_value = "raw_p_value",
    historical_bh_adjusted_p_value = "bh_adjusted_p_value",
    historical_raw_rank = "raw_rank_within_available"
  )
final_bh <- final_bh |>
  dplyr::left_join(
    historical_compare,
    by = bh_key,
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    raw_p_value_changed_numerically = dplyr::coalesce(
      .data$raw_p_value != .data$historical_raw_p_value,
      FALSE
    ),
    bh_adjusted_value_changed_numerically = dplyr::coalesce(
      .data$bh_adjusted_p_value != .data$historical_bh_adjusted_p_value,
      FALSE
    ),
    raw_rank_changed = dplyr::coalesce(
      .data$raw_rank_within_available != .data$historical_raw_rank,
      FALSE
    )
  )

# Preserve the exact serialized raw-p tokens for every frozen slot and the
# exact primary-family q tokens. Gap q-values are newly derived and receive a
# 17-significant-digit round-trip representation. This prevents CSV
# reserialization from introducing one-ULP changes in frozen scientific
# fields.
format_roundtrip <- function(value) {
  output <- rep(NA_character_, length(value))
  finite <- is.finite(value)
  output[finite] <- sprintf("%.17g", value[finite])
  output
}
token_match <- match(
  do.call(paste, c(final_bh[bh_key], sep = "::")),
  do.call(paste, c(historical_bh[bh_key], sep = "::"))
)
h06d_gap_assert(!anyNA(token_match), "A BH serialization key is missing")
final_bh_serialized <- final_bh
final_bh_serialized$raw_p_value <- format_roundtrip(final_bh$raw_p_value)
final_bh_serialized$raw_p_value[!final_bh$raw_slot_repaired] <-
  historical_bh_tokens$raw_p_value[token_match[!final_bh$raw_slot_repaired]]
final_bh_serialized$bh_adjusted_p_value <- format_roundtrip(
  final_bh$bh_adjusted_p_value
)
final_bh_serialized$bh_adjusted_p_value[final_bh$dataset_id == "primary"] <-
  historical_bh_tokens$bh_adjusted_p_value[
    token_match[final_bh$dataset_id == "primary"]
  ]

primary_rows <- final_bh$dataset_id == "primary"
gap_unaffected_rows <- final_bh$dataset_id == "gap_timing_unaware" &
  !final_bh$metric_slot %in% 9:13
mder_rows <- final_bh$metric_slot == 15L
l10_rows <- final_bh$metric_slot == 3L
bh_contract_checks <- c(
  rows_180 = nrow(final_bh) == 180L,
  families_12 = dplyr::n_distinct(final_bh$multiplicity_family_id) == 12L,
  required_slots_15 = all(final_bh$family_slots_required == 15L),
  available_slots_14 = all(final_bh$family_slots_available == 14L),
  family_construct_valid = all(final_bh$multiplicity_family_construct_valid),
  primary_raw_unchanged =
    !any(final_bh$raw_p_value_changed_numerically[primary_rows]),
  primary_bh_unchanged =
    !any(final_bh$bh_adjusted_value_changed_numerically[primary_rows]),
  unaffected_gap_raw_unchanged =
    !any(final_bh$raw_p_value_changed_numerically[gap_unaffected_rows]),
  mder_raw_unchanged =
    !any(final_bh$raw_p_value_changed_numerically[mder_rows]),
  l10_raw_named_na = all(is.na(final_bh$raw_p_value[l10_rows])),
  l10_bh_named_na = all(is.na(final_bh$bh_adjusted_p_value[l10_rows])),
  repaired_raw_slots_30 = sum(final_bh$raw_slot_repaired) == 30L,
  recomputed_gap_rows_90 = sum(final_bh$bh_family_recomputed) == 90L
)
h06d_gap_assert(
  all(bh_contract_checks),
  "The repaired 12-family multiplicity table failed: %s",
  paste(names(bh_contract_checks)[!bh_contract_checks], collapse = ", ")
)

family_summary <- final_bh |>
  dplyr::group_by(
    .data$dataset_id,
    .data$predictor_id,
    .data$reader_name,
    .data$test_type,
    .data$multiplicity_family_id
  ) |>
  dplyr::summarise(
    named_slots = dplyr::n(),
    available_raw_slots = sum(is.finite(.data$raw_p_value)),
    named_na_slots = sum(!is.finite(.data$raw_p_value)),
    fdr_supported_slots = sum(.data$fdr_supported),
    claim_eligible_slots = sum(.data$h01_claim_eligible),
    family_construct_valid = all(.data$multiplicity_family_construct_valid),
    bh_family_recomputed = any(.data$bh_family_recomputed),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    authorization = .env$authorization_id,
    gate = .env$gate_id
  )

gap_primary_results <- effects |>
  dplyr::filter(
    .data$placement_id == "near_eye",
    .data$sample_role == "all_available"
  ) |>
  dplyr::left_join(
    final_bh |>
      dplyr::filter(
        .data$dataset_id == "gap_timing_unaware",
        .data$test_type == "association",
        .data$metric_slot %in% 9:13
      ) |>
      dplyr::select(
        "metric_slot", "predictor_id",
        association_raw_p_value = "raw_p_value",
        association_bh_adjusted_p_value = "bh_adjusted_p_value",
        association_claim_disposition = "h01_claim_disposition"
      ),
    by = c("metric_slot", "predictor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    final_bh |>
      dplyr::filter(
        .data$dataset_id == "gap_timing_unaware",
        .data$test_type == "site_heterogeneity",
        .data$metric_slot %in% 9:13
      ) |>
      dplyr::select(
        "metric_slot", "predictor_id",
        heterogeneity_raw_p_value = "raw_p_value",
        heterogeneity_bh_adjusted_p_value = "bh_adjusted_p_value",
        heterogeneity_claim_disposition = "h01_claim_disposition"
      ),
    by = c("metric_slot", "predictor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    repair_rows |>
      dplyr::filter(
        .data$placement_id == "near_eye",
        .data$sample_role == "all_available"
      ) |>
      dplyr::select(
        "metric_slot", "predictor_id", "h01_reader_label",
        "visual_reason_codes", "temporal_gate", "influence_gate",
        "distribution_gate"
      ),
    by = c("metric_slot", "predictor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order)
h06d_gap_assert(
  nrow(gap_primary_results) == 15L &&
    !anyNA(gap_primary_results$association_bh_adjusted_p_value),
  "The repaired primary near-eye gap result table is incomplete"
)

sample_summary <- effects |>
  dplyr::select(
    "frame_key", "dataset_id", "placement_id", "sample_role",
    "metric_slot", "metric_id", "manuscript_name", "predictor_id",
    "participant_days", "participants", "sites", "frame_object_sha256"
  ) |>
  dplyr::left_join(observed_support, by = "frame_key", relationship = "one-to-one")

sidecar_summary <- dplyr::bind_rows(
  repair_rows |>
    dplyr::filter(.data$route == "participant_cluster_HC3") |>
    dplyr::count(
      sidecar = "HC3 Student-t additive effect stability",
      classification = .data$timing_student_classification,
      name = "cells"
    ),
  repair_rows |>
    dplyr::filter(.data$route == "participant_cluster_HC3") |>
    dplyr::count(
      sidecar = "HC3 gap-aware no-nugget AR additive stability",
      classification = .data$timing_ar_classification,
      name = "cells"
    ),
  repair_rows |>
    dplyr::filter(.data$route == "mixed_model") |>
    dplyr::count(
      sidecar = "Mixed-model gap-aware AR disposition",
      classification = .data$ar_disposition,
      name = "cells"
    ),
  repair_rows |>
    dplyr::count(
      sidecar = "Participant/site deletion influence",
      classification = .data$influence_classification,
      name = "cells"
    ),
  repair_rows |>
    dplyr::count(
      sidecar = "Manual residual review",
      classification = .data$visual_residual_verdict,
      name = "cells"
    )
) |>
  dplyr::mutate(
    overall_hard_gate_input = .data$sidecar == "Manual residual review",
    note = dplyr::if_else(
      .data$sidecar == "Manual residual review",
      "Only a visually confirmed FAIL_GROSS would set a residual hard failure",
      "Mandatory row-linked sensitivity; nonblocking under H06-D-014"
    ),
    authorization = .env$authorization_id,
    gate = .env$gate_id
  )

repair_scope <- tibble::tibble(
  check = c(
    "corrected gap clock cells",
    "unaffected non-L10 cells preserved",
    "replaced primary-gap raw tests",
    "recomputed gap 15-slot families",
    "primary families unchanged",
    "L10 raw/BH slots remain named NA",
    "MDER raw values unchanged",
    "protected historical identities verified",
    "frozen G2A output identities verified"
  ),
  expected = c(90L, 378L, 30L, 6L, 6L, 12L, 12L, 1011L, 997L),
  observed = c(
    nrow(repair_rows),
    nrow(frame_invariance),
    sum(final_bh$raw_slot_repaired),
    dplyr::n_distinct(final_bh$multiplicity_family_id[
      final_bh$dataset_id == "gap_timing_unaware"
    ]),
    dplyr::n_distinct(final_bh$multiplicity_family_id[
      final_bh$dataset_id == "primary"
    ]),
    sum(l10_rows),
    sum(mder_rows & !final_bh$raw_p_value_changed_numerically),
    nrow(protected_final),
    nrow(g2a_outputs_final)
  ),
  verified = expected == observed,
  authorization = authorization_id,
  gate = gate_id
)
h06d_gap_assert(all(repair_scope$verified), "The repair scope audit failed")

output_paths <- list(
  classification = file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_h01_classification.csv"
  ),
  repair_classification = file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_90_cell_classification.csv"
  ),
  classification_summary = file.path(
    paths$tables,
    "H06_daily_gap_clock_repair_classification_summary.csv"
  ),
  final_bh = file.path(
    paths$tables,
    "H06_daily_gap_clock_repair_bh_families.csv"
  ),
  family_summary = file.path(
    paths$tables,
    "H06_daily_gap_clock_repair_bh_family_summary.csv"
  ),
  primary_results = file.path(
    paths$tables,
    "H06_daily_gap_clock_repair_primary_gap_results.csv"
  ),
  samples = file.path(
    paths$tables,
    "H06_daily_gap_clock_repair_sample_summary.csv"
  ),
  sidecars = file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_sidecar_summary.csv"
  ),
  scope = file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_scope_audit.csv"
  ),
  protected = file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_protected_final.csv"
  ),
  g2a = file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_g2a_outputs_final.csv"
  )
)
h06d_gap_write_csv(final_classification, output_paths$classification)
h06d_gap_write_csv(repair_rows, output_paths$repair_classification)
h06d_gap_write_csv(classification_summary, output_paths$classification_summary)
h06d_gap_write_csv(final_bh_serialized, output_paths$final_bh)
h06d_gap_write_csv(family_summary, output_paths$family_summary)
h06d_gap_write_csv(gap_primary_results, output_paths$primary_results)
h06d_gap_write_csv(sample_summary, output_paths$samples)
h06d_gap_write_csv(sidecar_summary, output_paths$sidecars)
h06d_gap_write_csv(repair_scope, output_paths$scope)
h06d_gap_write_csv(protected_final, output_paths$protected)
h06d_gap_write_csv(g2a_outputs_final, output_paths$g2a)

state <- readRDS(paths$state)
h06d_gap_assert(
  state$phase %in% c("POSTPROCESS_COMPLETE", "FINALIZED_PRE_REPORT"),
  "The repair state is not ready for finalization"
)
state$phase <- "FINALIZED_PRE_REPORT"
state$visual_review_cells <- 90L
state$visual_fail_gross <- 0L
state$repaired_hard_gate_failures <- 0L
state$final_bh_rows <- 180L
state$updated <- format(Sys.time(), tz = "UTC", usetz = TRUE)
h06d_gap_write_rds(state, paths$state)

invisible(h06d_gap_verify_protected_1011(root, "post_finalization"))
message(paste(
  "Gap clock repair finalized: 90 repaired cells acceptable with limitations;",
  "six gap BH families complete; 1,011 protected identities unchanged"
))
