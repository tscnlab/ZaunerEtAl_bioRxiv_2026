#!/usr/bin/env Rscript

# Build the standalone H11 reader layer from frozen Stage 2 outputs. This
# script verifies every Stage 2 identity, selects or relabels accepted stored
# results for the separate reader-display builder. It never fits or refits a
# model, bootstraps, simulates, or changes a scientific estimate.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    paste0(
      "H11 Stage 3 reader artifacts require R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H11/build_h11_stage3_reader_artifacts.R"
stage2_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_stage2_output_hashes.csv"
)
expected_stage2_manifest_sha256 <-
  "a3cb30de615c615cfbfd6bfb1b7994634b1721915ed446eee5e00157638d44a2"

if (!identical(
  artifact_sha256(stage2_manifest_path),
  expected_stage2_manifest_sha256
)) {
  stop("The authoritative H11 Stage 2 manifest identity changed", call. = FALSE)
}

stage2_manifest <- readr::read_csv(
  stage2_manifest_path,
  show_col_types = FALSE
)
stage2_paths <- file.path(root, stage2_manifest$path)
if (any(!file.exists(stage2_paths))) {
  missing <- stage2_manifest$path[!file.exists(stage2_paths)]
  stop(
    paste("Frozen H11 Stage 2 artifact is missing:", paste(missing, collapse = ", ")),
    call. = FALSE
  )
}
observed_stage2_sha256 <- unname(vapply(
  stage2_paths,
  artifact_sha256,
  character(1)
))
changed <- stage2_manifest$path[
  observed_stage2_sha256 != stage2_manifest$sha256
]
authorized_non_scientific_post_stage2_updates <- c(
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/model_reporting.md",
  "audit/hypotheses/implementation_result_comparison_contract.qmd",
  "audit/handoffs/H11_shared_change_request.md",
  "audit/handoffs/H11_worker_handoff.md"
)
unauthorized_changes <- setdiff(
  changed,
  authorized_non_scientific_post_stage2_updates
)
if (length(unauthorized_changes) > 0L) {
  stop(
    paste(
      "Frozen H11 Stage 2 artifact identity changed:",
      paste(unauthorized_changes, collapse = ", ")
    ),
    call. = FALSE
  )
}
stage2_reconciliation <- stage2_manifest |>
  dplyr::transmute(
    .data$path,
    stage2_manifest_sha256 = .data$sha256,
    current_sha256 = observed_stage2_sha256,
    identity_status = dplyr::case_when(
      .data$path %in% authorized_non_scientific_post_stage2_updates &
        .data$sha256 != observed_stage2_sha256 ~
        "authorized_non_scientific_post_stage2_update",
      .data$sha256 == observed_stage2_sha256 ~ "unchanged",
      TRUE ~ "unauthorized_change"
    )
  )
stopifnot(
  !any(stage2_reconciliation$identity_status == "unauthorized_change"),
  setequal(
    stage2_reconciliation$path[
      stage2_reconciliation$identity_status ==
        "authorized_non_scientific_post_stage2_update"
    ],
    changed
  )
)

activity_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_activity_context_output_hashes.csv"
)
expected_activity_manifest_sha256 <-
  "6960448adc102d29ff48c06d07eb53cdb97a1bba89ea7dce73f779d5c5a4eecc"
if (!identical(
  artifact_sha256(activity_manifest_path),
  expected_activity_manifest_sha256
)) {
  stop("The authoritative H11 activity-context manifest identity changed",
    call. = FALSE
  )
}
activity_manifest <- readr::read_csv(
  activity_manifest_path,
  show_col_types = FALSE
)
activity_paths <- file.path(root, activity_manifest$relative_path)
if (
  any(!file.exists(activity_paths)) ||
    any(activity_manifest$sha256 != unname(vapply(
      activity_paths,
      artifact_sha256,
      character(1)
    )))
) {
  stop("An H11 activity-context artifact identity changed", call. = FALSE)
}
activity_reconciliation <- activity_manifest |>
  dplyr::transmute(
    path = .data$relative_path,
    manifest_sha256 = .data$sha256,
    current_sha256 = unname(vapply(
      file.path(root, .data$relative_path),
      artifact_sha256,
      character(1)
    )),
    identity_status = "unchanged"
  )

verified_path <- function(relative_path) {
  row <- stage2_manifest |>
    dplyr::filter(.data$path == .env$relative_path)
  if (nrow(row) != 1L) {
    stop(
      paste("Stage 2 manifest does not uniquely identify", relative_path),
      call. = FALSE
    )
  }
  path <- file.path(root, relative_path)
  if (!identical(artifact_sha256(path), row$sha256[[1L]])) {
    stop(paste("Stage 2 identity changed for", relative_path), call. = FALSE)
  }
  path
}

verified_read <- function(relative_path) {
  readr::read_csv(
    verified_path(relative_path),
    show_col_types = FALSE
  )
}

activity_verified_path <- function(relative_path) {
  row <- activity_manifest |>
    dplyr::filter(.data$relative_path == .env$relative_path)
  if (nrow(row) != 1L) {
    stop(
      paste("Activity manifest does not uniquely identify", relative_path),
      call. = FALSE
    )
  }
  path <- file.path(root, relative_path)
  if (!identical(artifact_sha256(path), row$sha256[[1L]])) {
    stop(paste("Activity artifact identity changed for", relative_path),
      call. = FALSE
    )
  }
  path
}

activity_verified_read <- function(relative_path) {
  readr::read_csv(
    activity_verified_path(relative_path),
    show_col_types = FALSE
  )
}

model_data_dir <- file.path(root, "artifacts/06_model_data/H11/stage3")
diagnostic_dir <- file.path(root, "artifacts/08_diagnostics/H11/stage3")
table_dir <- file.path(root, "artifacts/09_tables/H11/stage3")
figure_dir <- file.path(root, "artifacts/10_figures/H11/stage3")
source_dir <- file.path(root, "artifacts/11_source_data/H11/stage3")
invisible(vapply(
  c(model_data_dir, diagnostic_dir, table_dir, figure_dir, source_dir),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

samples <- verified_read(
  "artifacts/09_tables/H11/stage2/sample_counts.csv"
)
comparisons <- verified_read(
  "artifacts/09_tables/H11/stage2/model_comparisons.csv"
)
parametric <- verified_read(
  "artifacts/09_tables/H11/stage2/parametric_sex_component.csv"
)
segments <- verified_read(
  "artifacts/09_tables/H11/stage2/pointwise_descriptive_segments.csv"
)
curve_variation <- verified_read(
  "artifacts/09_tables/H11/stage2/effect_size_curve_variation.csv"
)
diagnostic_assessment <- verified_read(
  "artifacts/08_diagnostics/H11/stage2/diagnostic_assessment.csv"
)
robust_diagnostics <- verified_read(
  "artifacts/08_diagnostics/H11/stage2/robust_inference_diagnostics.csv"
)
residual_acf <- verified_read(
  "artifacts/08_diagnostics/H11/stage2/boundary_aware_residual_acf.csv"
)
residual_summary <- verified_read(
  "artifacts/08_diagnostics/H11/stage2/residual_summary.csv"
)
curves <- verified_read(
  "artifacts/11_source_data/H11/stage2/sex_specific_curves_pointwise.csv"
)
contrasts <- verified_read(
  "artifacts/11_source_data/H11/stage2/female_minus_male_pointwise_contrasts.csv"
)
solar_context <- verified_read(
  "artifacts/11_source_data/H11/stage2/equal_site_solar_context.csv"
)
formula_manifest <- verified_read(
  "artifacts/06_model_data/H11/stage2/formula_and_fit_manifest.csv"
)
paired_assessment <- verified_read(
  "artifacts/06_model_data/H11/stage2/paired_placement_display_assessment.csv"
)
activity_samples <- activity_verified_read(
  "artifacts/09_tables/H11/activity_context/activity_common_sample_counts.csv"
)
activity_tests <- activity_verified_read(
  "artifacts/09_tables/H11/activity_context/global_sex_curve_tests.csv"
)
activity_attenuation <- activity_verified_read(
  "artifacts/09_tables/H11/activity_context/same_sample_activity_attenuation.csv"
)
activity_support <- activity_verified_read(
  "artifacts/09_tables/H11/activity_context/activity_category_support_by_sex.csv"
)
activity_diagnostics <- activity_verified_read(
  "artifacts/08_diagnostics/H11/activity_context/diagnostic_assessment.csv"
)
activity_robust_diagnostics <- activity_verified_read(
  "artifacts/08_diagnostics/H11/activity_context/robust_inference_diagnostics.csv"
)
activity_contrasts <- activity_verified_read(
  paste0(
    "artifacts/11_source_data/H11/activity_context/",
    "female_minus_male_pointwise_contrasts.csv"
  )
)
activity_formula_manifest <- activity_verified_read(
  "artifacts/06_model_data/H11/activity_context/formula_and_fit_manifest.csv"
)
activity_effect_gate <- activity_verified_read(
  paste0(
    "artifacts/09_tables/H11/activity_context/",
    "activity_adjusted_effect_size_gate.csv"
  )
)

run_labels <- tibble::tribble(
  ~run_id, ~dataset_label, ~placement_label, ~reader_role,
  "main__glasses__all_available", "Primary dataset", "Near eye", "Primary",
  "main__chest__all_available", "Primary dataset", "Chest", "Complementary",
  "manuscript_prepared_data__glasses__all_available",
  "Gap-timing-unaware dataset", "Near eye", "Sensitivity",
  "manuscript_prepared_data__chest__all_available",
  "Gap-timing-unaware dataset", "Chest", "Sensitivity"
)

with_reader_labels <- function(data) {
  data |>
    dplyr::left_join(run_labels, by = "run_id", relationship = "many-to-one") |>
    dplyr::relocate(
      dataset_label,
      placement_label,
      reader_role,
      .after = run_id
    )
}

format_clock <- function(minutes) {
  ifelse(
    minutes == 1440,
    "24:00",
    sprintf("%02d:%02d", (minutes %/% 60) %% 24, minutes %% 60)
  )
}

reader_samples <- samples |>
  with_reader_labels() |>
  dplyr::select(
    run_id,
    dataset_label,
    placement_label,
    reader_role,
    participants,
    female_participants,
    male_participants,
    participant_days,
    female_participant_days,
    male_participant_days,
    observations_30_minute,
    nominal_observation_hours,
    female_observations_30_minute,
    male_observations_30_minute,
    sites,
    AR_sequences,
    frame_sha256
  )

reader_global <- comparisons |>
  dplyr::filter(.data$comparison_id == "complete_sex_curve") |>
  with_reader_labels() |>
  dplyr::select(
    run_id,
    dataset_label,
    placement_label,
    reader_role,
    estimand,
    test_method,
    covariance_method,
    F_statistic = test_statistic,
    fractional_numerator_df = test_df,
    denominator_df,
    p_raw,
    p_adjusted = p_adjusted_BH,
    observed_family_n,
    support_status
  )

reader_decomposition <- comparisons |>
  dplyr::filter(
    .data$comparison_role == "decomposition"
  ) |>
  with_reader_labels() |>
  dplyr::select(
    run_id,
    dataset_label,
    placement_label,
    reader_role,
    comparison_id,
    estimand,
    F_statistic = test_statistic,
    fractional_numerator_df = test_df,
    denominator_df,
    p_raw,
    p_adjusted = p_adjusted_BH,
    observed_family_n,
    support_status
  )

reader_parametric <- parametric |>
  dplyr::filter(startsWith(.data$run_id, "main__")) |>
  with_reader_labels() |>
  dplyr::select(
    run_id,
    dataset_label,
    placement_label,
    reader_role,
    estimand,
    estimate_eta,
    standard_error_participant_cluster_robust,
    lower_eta_95,
    upper_eta_95,
    female_to_male_shifted_ratio = shifted_ratio,
    ratio_lower_95 = shifted_ratio_lower_95,
    ratio_upper_95 = shifted_ratio_upper_95,
    interval_method
  )

reader_curve_variation <- curve_variation |>
  with_reader_labels() |>
  dplyr::select(
    run_id,
    dataset_label,
    placement_label,
    reader_role,
    participants,
    participant_days,
    observations_30_minute,
    sites,
    effect_size_id,
    definition,
    estimate,
    lower_95,
    upper_95,
    standard_error_participant_cluster_robust,
    unit,
    confidence_interval_method,
    inferential_role
  )

reader_pointwise_context <- contrasts |>
  with_reader_labels() |>
  dplyr::group_by(
    .data$run_id,
    .data$dataset_label,
    .data$placement_label,
    .data$reader_role
  ) |>
  dplyr::summarise(
    displayed_bins = dplyr::n(),
    pointwise_bins_excluding_one = sum(
      .data$pointwise_direction != "not_distinguishable_pointwise"
    ),
    minimum_ratio = min(.data$female_to_male_shifted_ratio),
    minimum_clock = format_clock(
      round(
        60 * .data$time_hour[
          which.min(.data$female_to_male_shifted_ratio)
        ]
      )
    ),
    minimum_ratio_lower_95 = .data$ratio_lower_pointwise_95[
      which.min(.data$female_to_male_shifted_ratio)
    ],
    minimum_ratio_upper_95 = .data$ratio_upper_pointwise_95[
      which.min(.data$female_to_male_shifted_ratio)
    ],
    maximum_ratio = max(.data$female_to_male_shifted_ratio),
    maximum_clock = format_clock(
      round(
        60 * .data$time_hour[
          which.max(.data$female_to_male_shifted_ratio)
        ]
      )
    ),
    maximum_ratio_lower_95 = .data$ratio_lower_pointwise_95[
      which.max(.data$female_to_male_shifted_ratio)
    ],
    maximum_ratio_upper_95 = .data$ratio_upper_pointwise_95[
      which.max(.data$female_to_male_shifted_ratio)
    ],
    interval_scope = dplyr::first(.data$interval_scope),
    .groups = "drop"
  )

reader_segments <- segments |>
  with_reader_labels() |>
  dplyr::mutate(
    start_local_clock = format_clock(.data$start_clock_bin),
    end_local_clock = format_clock(.data$end_clock_bin_exclusive)
  ) |>
  dplyr::select(
    run_id,
    dataset_label,
    placement_label,
    reader_role,
    pointwise_direction,
    start_local_clock,
    end_local_clock,
    bins_30_minute,
    minimum_ratio,
    maximum_ratio,
    minimum_pointwise_lower,
    maximum_pointwise_upper,
    interval_scope
  )

reader_diagnostic_assessment <- diagnostic_assessment |>
  with_reader_labels()
reader_robust_diagnostics <- robust_diagnostics |>
  with_reader_labels()
reader_residual_acf <- residual_acf |>
  with_reader_labels()
reader_primary_residual_summary <- residual_summary |>
  with_reader_labels() |>
  dplyr::filter(.data$dataset_label == "Primary dataset")
reader_curves <- curves |>
  with_reader_labels()
reader_contrasts <- contrasts |>
  with_reader_labels()
reader_solar_context <- solar_context |>
  with_reader_labels()

reader_formula <- formula_manifest |>
  dplyr::filter(
    .data$data_scenario_id == "main",
    .data$placement == "glasses",
    .data$model_id == "mpattern_final_fREML"
  ) |>
  dplyr::distinct(
    formula_id,
    formula,
    family,
    link,
    method,
    discrete,
    rho_rule,
    knots,
    biological_sex_encoding
  )

reader_paired_assessment <- paired_assessment |>
  dplyr::transmute(
    policy = .data$decision_id,
    stored_common_sample_participants = .data$stored_paired_frame_participants,
    stored_common_sample_participant_days =
      .data$stored_paired_frame_participant_days,
    stored_common_sample_observations =
      .data$stored_paired_frame_observations,
    stored_common_sample_sites = .data$stored_paired_frame_sites,
    common_sample_H11_fitted_outputs_available =
      .data$h11_paired_fitted_outputs_available,
    predeclared_scalar_temporal_estimand_available =
      .data$predeclared_scalar_temporal_estimand_available,
    scalar_identity_plot_applicable = .data$scalar_identity_plot_applicable,
    applicability_reason = .data$applicability_reason,
    closest_valid_display = .data$closest_valid_display,
    paired_source_data_created = !is.na(.data$paired_source_data_csv),
    source_data_status = .data$source_data_status
  )

activity_placement_labels <- c(
  glasses = "Near eye",
  chest = "Chest"
)
activity_model_labels <- c(
  restricted_unadjusted = "Activity-complete sample, unadjusted",
  activity_adjusted = "Same sample, activity-adjusted"
)

reader_activity_samples <- activity_samples |>
  dplyr::mutate(
    placement_label = unname(activity_placement_labels[.data$placement]),
    reader_role = dplyr::if_else(
      .data$placement == "glasses",
      "Primary near-eye sensitivity",
      "Complementary chest sensitivity"
    ),
    dataset_label = "Activity-complete sample",
    .after = "run_id"
  ) |>
  dplyr::select(
    run_id,
    dataset_label,
    placement_label,
    reader_role,
    participants,
    female_participants,
    male_participants,
    participant_days,
    female_participant_days,
    male_participant_days,
    observations_30_minute,
    nominal_observation_hours,
    female_observations_30_minute,
    male_observations_30_minute,
    sites,
    AR_sequences,
    frame_sha256
  )

reader_activity_tests <- activity_tests |>
  dplyr::left_join(
    reader_activity_samples |>
      dplyr::select(
        run_id,
        participants,
        participant_days,
        observations_30_minute,
        sites
      ),
    by = "run_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    placement_label = unname(activity_placement_labels[.data$placement]),
    analysis_step = unname(activity_model_labels[.data$model_variant]),
    step_order = dplyr::if_else(
      .data$model_variant == "restricted_unadjusted",
      2L,
      3L
    )
  ) |>
  dplyr::transmute(
    run_id,
    placement_label,
    analysis_step,
    step_order,
    participants,
    participant_days,
    observations_30_minute,
    sites,
    F_statistic = .data$test_statistic,
    fractional_numerator_df = .data$test_df,
    denominator_df,
    p_raw,
    p_adjusted = .data$p_adjusted_BH,
    support_status,
    inferential_role
  )

reader_activity_original <- reader_global |>
  dplyr::filter(
    .data$dataset_label == "Primary dataset",
    .data$run_id %in% c(
      "main__glasses__all_available",
      "main__chest__all_available"
    )
  ) |>
  dplyr::left_join(
    reader_samples |>
      dplyr::select(
        run_id,
        participants,
        participant_days,
        observations_30_minute,
        sites
      ),
    by = "run_id",
    relationship = "one-to-one"
  ) |>
  dplyr::transmute(
    run_id,
    placement_label,
    analysis_step = "Accepted all-available model",
    step_order = 1L,
    participants,
    participant_days,
    observations_30_minute,
    sites,
    F_statistic,
    fractional_numerator_df,
    denominator_df,
    p_raw,
    p_adjusted,
    support_status,
    inferential_role = dplyr::if_else(
      .data$placement_label == "Near eye",
      "Accepted primary result",
      "Accepted complementary result"
    )
  )

reader_activity_comparison <- dplyr::bind_rows(
  reader_activity_original,
  reader_activity_tests
) |>
  dplyr::arrange(
    factor(.data$placement_label, levels = c("Near eye", "Chest")),
    .data$step_order
  )

reader_activity_attenuation <- activity_attenuation |>
  dplyr::mutate(
    placement_label = unname(activity_placement_labels[.data$placement]),
    .after = "run_id"
  )

reader_activity_support <- activity_support |>
  dplyr::mutate(
    placement_label = unname(activity_placement_labels[.data$placement]),
    .after = "run_id"
  )

reader_activity_diagnostics <- activity_diagnostics |>
  dplyr::left_join(
    activity_robust_diagnostics |>
      dplyr::select(
        run_id,
        model_variant,
        maximum_participant_unscaled_meat_share,
        effective_participants_unscaled_meat_trace,
        delete_one_participant_p_minimum,
        delete_one_participant_p_maximum
      ),
    by = c("run_id", "model_variant"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    placement_label = unname(activity_placement_labels[.data$placement]),
    analysis_step = unname(activity_model_labels[.data$model_variant]),
    .after = "run_id"
  )

reader_activity_contrasts <- activity_contrasts |>
  dplyr::mutate(
    placement_label = unname(activity_placement_labels[.data$placement]),
    analysis_step = unname(activity_model_labels[.data$model_variant]),
    .after = "run_id"
  )

reader_activity_pointwise_context <- reader_activity_contrasts |>
  dplyr::group_by(
    .data$run_id,
    .data$placement_label,
    .data$model_variant,
    .data$analysis_step
  ) |>
  dplyr::summarise(
    displayed_bins = dplyr::n(),
    pointwise_bins_excluding_one = sum(
      .data$pointwise_direction != "not_distinguishable_pointwise"
    ),
    minimum_ratio = min(.data$female_to_male_shifted_ratio),
    minimum_clock = format_clock(round(
      60 * .data$time_hour[which.min(.data$female_to_male_shifted_ratio)]
    )),
    minimum_ratio_lower_95 = .data$ratio_lower_pointwise_95[
      which.min(.data$female_to_male_shifted_ratio)
    ],
    minimum_ratio_upper_95 = .data$ratio_upper_pointwise_95[
      which.min(.data$female_to_male_shifted_ratio)
    ],
    maximum_ratio = max(.data$female_to_male_shifted_ratio),
    maximum_clock = format_clock(round(
      60 * .data$time_hour[which.max(.data$female_to_male_shifted_ratio)]
    )),
    maximum_ratio_lower_95 = .data$ratio_lower_pointwise_95[
      which.max(.data$female_to_male_shifted_ratio)
    ],
    maximum_ratio_upper_95 = .data$ratio_upper_pointwise_95[
      which.max(.data$female_to_male_shifted_ratio)
    ],
    interval_scope = dplyr::first(.data$interval_scope),
    .groups = "drop"
  )

reader_activity_formula <- activity_formula_manifest |>
  dplyr::filter(
    .data$formula_id %in% c("restricted_unadjusted", "activity_adjusted")
  ) |>
  dplyr::mutate(
    analysis_step = unname(activity_model_labels[.data$formula_id]),
    .before = 1L
  )

stopifnot(
  nrow(reader_samples) == 4L,
  nrow(reader_global) == 4L,
  nrow(reader_decomposition) == 8L,
  nrow(reader_parametric) == 2L,
  nrow(reader_curve_variation) == 2L,
  nrow(reader_pointwise_context) == 4L,
  nrow(reader_segments) == 6L,
  nrow(reader_diagnostic_assessment) == 4L,
  nrow(reader_robust_diagnostics) == 4L,
  nrow(reader_residual_acf) == 96L,
  nrow(reader_primary_residual_summary) == 6L,
  setequal(
    reader_primary_residual_summary$biological_sex,
    c("Overall", "Female", "Male")
  ),
  all(abs(reader_primary_residual_summary$median) < 0.04),
  all(
    reader_primary_residual_summary$correlation_absolute_residual_fitted >
      0
  ),
  nrow(reader_curves) == 384L,
  nrow(reader_contrasts) == 192L,
  nrow(reader_solar_context) == 4L,
  nrow(reader_formula) == 1L,
  nrow(reader_paired_assessment) == 1L,
  nrow(reader_activity_samples) == 2L,
  nrow(reader_activity_comparison) == 6L,
  nrow(reader_activity_attenuation) == 2L,
  nrow(reader_activity_support) == 20L,
  nrow(reader_activity_diagnostics) == 4L,
  nrow(reader_activity_contrasts) == 192L,
  nrow(reader_activity_pointwise_context) == 4L,
  nrow(reader_activity_formula) == 2L,
  all(reader_global$support_status == "supported"),
  !any(reader_decomposition$p_adjusted <= 0.05),
  all(reader_diagnostic_assessment$classification ==
    "acceptable with specified limitations"),
  identical(reader_samples$participants, c(141, 154, 141, 154)),
  identical(reader_samples$participant_days, c(816, 902, 809, 894)),
  identical(
    reader_samples$observations_30_minute,
    c(37756, 41842, 37603, 41664)
  ),
  identical(reader_pointwise_context$displayed_bins, rep(48L, 4L)),
  identical(
    reader_pointwise_context$minimum_clock[
      reader_pointwise_context$run_id == "main__glasses__all_available"
    ],
    "08:45"
  ),
  identical(
    reader_pointwise_context$maximum_clock[
      reader_pointwise_context$run_id == "main__glasses__all_available"
    ],
    "22:15"
  ),
  !reader_paired_assessment$scalar_identity_plot_applicable,
  !reader_paired_assessment$common_sample_H11_fitted_outputs_available,
  identical(reader_activity_samples$participants, c(126, 150)),
  identical(reader_activity_samples$participant_days, c(724, 875)),
  identical(
    reader_activity_samples$observations_30_minute,
    c(30499, 36711)
  ),
  identical(
    reader_activity_comparison$p_adjusted,
    c(
      reader_global$p_adjusted[reader_global$run_id ==
        "main__glasses__all_available"],
      activity_tests$p_adjusted_BH[activity_tests$placement == "glasses"],
      reader_global$p_adjusted[reader_global$run_id ==
        "main__chest__all_available"],
      activity_tests$p_adjusted_BH[activity_tests$placement == "chest"]
    )
  ),
  all(reader_activity_diagnostics$classification ==
    "acceptable with specified limitations"),
  !any(activity_effect_gate$effect_size_gate_open),
  all(grepl("pointwise", reader_activity_contrasts$interval_scope,
    fixed = TRUE
  )),
  all(activity_reconciliation$identity_status == "unchanged")
)

write_reader <- function(data, directory, filename) {
  invisible(write_csv_artifact(
    data,
    file.path(directory, filename),
    producer = producer
  ))
}

write_reader(reader_samples, table_dir, "H11_reader_samples.csv")
write_reader(reader_global, table_dir, "H11_reader_global_tests.csv")
write_reader(
  reader_decomposition,
  table_dir,
  "H11_reader_level_shape_decomposition.csv"
)
write_reader(
  reader_parametric,
  table_dir,
  "H11_reader_parametric_level_estimates.csv"
)
write_reader(
  reader_curve_variation,
  table_dir,
  "H11_reader_curve_variation_effect_size.csv"
)
write_reader(
  reader_pointwise_context,
  table_dir,
  "H11_reader_pointwise_context.csv"
)
write_reader(
  reader_segments,
  table_dir,
  "H11_reader_pointwise_segments.csv"
)
write_reader(
  reader_diagnostic_assessment,
  diagnostic_dir,
  "H11_reader_diagnostic_assessment.csv"
)
write_reader(
  reader_robust_diagnostics,
  diagnostic_dir,
  "H11_reader_robust_diagnostics.csv"
)
write_reader(
  reader_residual_acf,
  diagnostic_dir,
  "H11_reader_residual_acf.csv"
)
write_reader(
  reader_primary_residual_summary,
  diagnostic_dir,
  "H11_reader_primary_residual_summary.csv"
)
write_reader(
  reader_formula,
  model_data_dir,
  "H11_reader_formula_registry.csv"
)
write_reader(
  reader_paired_assessment,
  model_data_dir,
  "H11_reader_placement_comparison_assessment.csv"
)
write_reader(
  stage2_reconciliation,
  model_data_dir,
  "H11_stage2_identity_reconciliation.csv"
)
write_reader(
  activity_reconciliation,
  model_data_dir,
  "H11_activity_identity_reconciliation.csv"
)
write_reader(
  reader_activity_formula,
  model_data_dir,
  "H11_reader_activity_formula_registry.csv"
)
write_reader(
  reader_curves,
  source_dir,
  "H11_reader_sex_specific_curves.csv"
)
write_reader(
  reader_contrasts,
  source_dir,
  "H11_reader_female_minus_male_contrasts.csv"
)
write_reader(
  reader_solar_context,
  source_dir,
  "H11_reader_solar_context.csv"
)
write_reader(
  reader_activity_samples,
  table_dir,
  "H11_reader_activity_samples.csv"
)
write_reader(
  reader_activity_comparison,
  table_dir,
  "H11_reader_activity_global_comparison.csv"
)
write_reader(
  reader_activity_attenuation,
  table_dir,
  "H11_reader_activity_attenuation.csv"
)
write_reader(
  reader_activity_support,
  table_dir,
  "H11_reader_activity_support.csv"
)
write_reader(
  reader_activity_pointwise_context,
  table_dir,
  "H11_reader_activity_pointwise_context.csv"
)
write_reader(
  reader_activity_diagnostics,
  diagnostic_dir,
  "H11_reader_activity_diagnostic_assessment.csv"
)
write_reader(
  reader_activity_contrasts,
  source_dir,
  "H11_reader_activity_female_minus_male_contrasts.csv"
)

output_files <- c(
  list.files(model_data_dir, full.names = TRUE),
  list.files(diagnostic_dir, full.names = TRUE),
  list.files(table_dir, full.names = TRUE),
  list.files(source_dir, full.names = TRUE)
)
if (
  any(grepl("pilot|bootstrap", basename(output_files), ignore.case = TRUE)) ||
    length(output_files) != 26L
) {
  stop("Unexpected H11 reader artifact inventory", call. = FALSE)
}

message(
  "H11 Stage 3 reader layer completed from verified Stage 2 outputs: ",
  length(output_files),
  " files; no fitting or resampling"
)
