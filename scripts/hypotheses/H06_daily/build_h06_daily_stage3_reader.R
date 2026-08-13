#!/usr/bin/env Rscript

# Build display-only inputs for the standalone complementary H06_daily report.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tibble)
  library(tidyr)
})

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    paste0(
      "The H06_daily Stage 3 display build requires R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

sha256 <- function(path) {
  digest::digest(
    path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  )
}

read_project_csv <- function(relative_path) {
  readr::read_csv(
    file.path(project_root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}

write_project_csv <- function(data, relative_path) {
  absolute_path <- file.path(project_root, relative_path)
  dir.create(dirname(absolute_path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(data, absolute_path, na = "")
  invisible(absolute_path)
}

control_inputs <- tibble::tribble(
  ~input_id, ~relative_path, ~expected_sha256, ~role,
  "H06-D-015",
  "audit/decisions/h06_daily_stage2_acceptance_stage3_transition.md",
  "26e3cf5302db74156a2ad929a80a1352eac6967ccf0e0e1adb5cdcfa71b9954e",
  "Stage 2 acceptance and Stage 3 authorization",
  "accepted_transition",
  "audit/hypotheses/H06_daily/H06_daily_gap_clock_repair_transition.md",
  "ac34798ac197ea9207b04c2f0c53dcf1bf62351d7157ce0f3273890e63a1e787",
  "Task-owned accepted Stage 2 transition",
  "gap_output_manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_gap_clock_repair_output_manifest.csv"
  ),
  "54b63ff4dc3edf4cd112d4b7c71f02f193ee1be367fdd889d9a69923be6d1084",
  "Accepted final Stage 2 gap-repair output manifest",
  "non_l10_output_manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_non_l10_production_output_manifest.csv"
  ),
  "63c6e873c35bcef3b2a12600da27e10dc1097cf43e14be96dee838ce15d4e7e1",
  "Protected non-L10 production output manifest",
  "non_l10_figure_manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_non_l10_production_figure_manifest.csv"
  ),
  "144072abef7df3fa6460d87011279a33ad1e993cd461fd7ca79b8db2d6f1ec7d",
  "Protected non-L10 figure and source-data manifest",
  "l10_output_manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_l10_metric011_production_output_manifest.csv"
  ),
  "af89132e004e29d27351302b0f765ce9845da53fb6619d8d042aaa980165626c",
  "Accepted two-part L10 output manifest",
  "mder_output_manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_mder_metric010_production_output_manifest.csv"
  ),
  "19d91fdc62c81cf342490a2197ba335eb751b26500df102c0d0e8cbebf3a119c",
  "Accepted METRIC-010 MDER output manifest",
  "metric_display_registry",
  "config/metric_display_registry.csv",
  "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0",
  "Current manuscript metric names and units",
  "site_display_registry",
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "Submitted site names, order, and colours",
  "p_value_display",
  "scripts/pipeline/p_value_display.R",
  "ea33b30d2c887b033c7e22e2358be7e403ce7116261a4d0c0fbc6bf214eeb1a2",
  "Shared p-value display convention"
)

control_inputs <- control_inputs |>
  mutate(
    exists = file.exists(file.path(project_root, .data$relative_path)),
    actual_sha256 = if_else(
      .data$exists,
      vapply(
        file.path(project_root, .data$relative_path),
        sha256,
        character(1)
      ),
      NA_character_
    ),
    verification_status = if_else(
      .data$exists & .data$actual_sha256 == .data$expected_sha256,
      "PASS",
      "FAIL"
    )
  )

if (any(control_inputs$verification_status != "PASS")) {
  failed <- control_inputs$relative_path[
    control_inputs$verification_status != "PASS"
  ]
  stop(
    paste0("Stage 3 control-input mismatch: ", paste(failed, collapse = ", ")),
    call. = FALSE
  )
}

sealed_manifests <- list(
  gap = read_project_csv(control_inputs$relative_path[
    control_inputs$input_id == "gap_output_manifest"
  ]),
  non_l10 = read_project_csv(control_inputs$relative_path[
    control_inputs$input_id == "non_l10_output_manifest"
  ]),
  non_l10_figure = read_project_csv(control_inputs$relative_path[
    control_inputs$input_id == "non_l10_figure_manifest"
  ]),
  l10 = read_project_csv(control_inputs$relative_path[
    control_inputs$input_id == "l10_output_manifest"
  ]),
  mder = read_project_csv(control_inputs$relative_path[
    control_inputs$input_id == "mder_output_manifest"
  ])
)

direct_sources <- tibble::tribble(
  ~input_id, ~manifest_id, ~relative_path, ~role,
  "final_fdr_families", "gap",
  paste0(
    "artifacts/09_tables/H06_daily/",
    "H06_daily_gap_clock_repair_bh_families.csv"
  ),
  "Accepted twelve complete 15-slot FDR families",
  "final_gap_effects", "gap",
  paste0(
    "artifacts/09_tables/H06_daily/",
    "H06_daily_gap_clock_repair_effects.csv"
  ),
  "Accepted corrected gap timing effects",
  "final_cell_classification", "gap",
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_gap_clock_repair_h01_classification.csv"
  ),
  "Accepted H01-aligned classification for 468 non-L10 cells",
  "non_l10_effects", "non_l10",
  paste0(
    "artifacts/09_tables/H06_daily/",
    "H06_daily_non_l10_production_effects.csv"
  ),
  "Protected non-L10 estimates and pointwise intervals",
  "non_l10_samples", "non_l10",
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_non_l10_production_exact_samples.csv"
  ),
  "Protected exact non-L10 fitted samples",
  "primary_ratio_figure", "non_l10_figure",
  paste0(
    "artifacts/10_figures/H06_daily/",
    "H06_daily_non_l10_production_primary_ratio_effects.png"
  ),
  "Accepted primary ratio-scale forest plot",
  "primary_ratio_source", "non_l10_figure",
  paste0(
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_non_l10_production_primary_ratio_effects.csv"
  ),
  "Paired source data for the primary ratio-scale forest plot",
  "primary_absolute_figure", "non_l10_figure",
  paste0(
    "artifacts/10_figures/H06_daily/",
    "H06_daily_non_l10_production_primary_absolute_effects.png"
  ),
  "Accepted primary absolute-scale forest plot",
  "primary_absolute_source", "non_l10_figure",
  paste0(
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_non_l10_production_primary_absolute_effects.csv"
  ),
  "Paired source data for the primary absolute-scale forest plot",
  "l10_tests", "l10",
  paste0(
    "artifacts/09_tables/H06_daily/",
    "H06_daily_l10_metric011_model_tests.csv"
  ),
  "Accepted non-estimable two-part L10 tests",
  "l10_frames", "l10",
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_l10_metric011_frame_registry.csv"
  ),
  "Exact L10 component samples",
  "mder_effects", "mder",
  paste0(
    "artifacts/09_tables/H06_daily/",
    "H06_daily_mder_metric010_effect_estimates.csv"
  ),
  "Accepted frozen MDER estimates and pointwise intervals",
  "mder_tests", "mder",
  paste0(
    "artifacts/09_tables/H06_daily/",
    "H06_daily_mder_metric010_model_tests.csv"
  ),
  "Accepted frozen MDER raw tests"
)

manifest_hash <- function(manifest_id, target_relative_path) {
  manifest <- sealed_manifests[[manifest_id]]
  row <- manifest |>
    filter(.data$relative_path == .env$target_relative_path)
  if (nrow(row) != 1L) {
    stop(
      paste0(
        "Expected exactly one sealed manifest row for `",
        target_relative_path,
        "`; found ",
        nrow(row)
      ),
      call. = FALSE
    )
  }
  row$sha256[[1L]]
}

direct_sources <- direct_sources |>
  rowwise() |>
  mutate(
    expected_sha256 = manifest_hash(.data$manifest_id, .data$relative_path),
    exists = file.exists(file.path(project_root, .data$relative_path)),
    actual_sha256 = if (.data$exists) {
      sha256(file.path(project_root, .data$relative_path))
    } else {
      NA_character_
    },
    verification_status = if_else(
      .data$exists & .data$actual_sha256 == .data$expected_sha256,
      "PASS",
      "FAIL"
    )
  ) |>
  ungroup()

if (any(direct_sources$verification_status != "PASS")) {
  failed <- direct_sources$relative_path[
    direct_sources$verification_status != "PASS"
  ]
  stop(
    paste0("Stage 3 direct-source mismatch: ", paste(failed, collapse = ", ")),
    call. = FALSE
  )
}

input_manifest <- bind_rows(
  control_inputs |>
    transmute(
      input_id,
      manifest_id = NA_character_,
      relative_path,
      role,
      expected_sha256,
      actual_sha256,
      verification_status
    ),
  direct_sources |>
    select(
      input_id,
      manifest_id,
      relative_path,
      role,
      expected_sha256,
      actual_sha256,
      verification_status
    )
) |>
  mutate(
    authorization = "H06-D-015",
    gate = "H06-D-G3",
    r_version = as.character(getRversion())
  )

write_project_csv(
  input_manifest,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_stage3_input_manifest.csv"
  )
)

families <- read_project_csv(direct_sources$relative_path[
  direct_sources$input_id == "final_fdr_families"
])
gap_effects <- read_project_csv(direct_sources$relative_path[
  direct_sources$input_id == "final_gap_effects"
])
classification <- read_project_csv(direct_sources$relative_path[
  direct_sources$input_id == "final_cell_classification"
])
non_l10_effects <- read_project_csv(direct_sources$relative_path[
  direct_sources$input_id == "non_l10_effects"
])
non_l10_samples <- read_project_csv(direct_sources$relative_path[
  direct_sources$input_id == "non_l10_samples"
])
l10_tests <- read_project_csv(direct_sources$relative_path[
  direct_sources$input_id == "l10_tests"
])
l10_frames <- read_project_csv(direct_sources$relative_path[
  direct_sources$input_id == "l10_frames"
])
mder_effects <- read_project_csv(direct_sources$relative_path[
  direct_sources$input_id == "mder_effects"
])
mder_tests <- read_project_csv(direct_sources$relative_path[
  direct_sources$input_id == "mder_tests"
])
metric_registry <- read_project_csv("config/metric_display_registry.csv")
site_registry <- read_project_csv("config/site_display_registry.csv")

stopifnot(
  nrow(families) == 180L,
  n_distinct(families$multiplicity_family_id) == 12L,
  all(table(families$multiplicity_family_id) == 15L),
  all(families$family_slots_required == 15L),
  all(families$multiplicity_family_construct_valid),
  nrow(non_l10_effects) == 468L,
  nrow(non_l10_samples) == 468L,
  nrow(gap_effects) == 90L,
  identical(names(non_l10_effects), names(gap_effects)),
  all(gap_effects$frame_key %in% non_l10_effects$frame_key),
  nrow(classification) == 468L,
  all(!classification$hard_gate_failed),
  all(classification$h01_diagnostic_class == "WARN_REVIEW"),
  all(classification$visual_residual_verdict == "REVIEW_LIMITATION"),
  nrow(l10_tests) == 36L,
  all(
    l10_tests$test_status[l10_tests$component == "joint_two_part"] ==
      "NON_ESTIMABLE_COMPONENT_FAILURE"
  ),
  all(is.na(l10_tests$raw_p_value[
    l10_tests$component == "joint_two_part"
  ])),
  nrow(l10_frames) == 36L,
  nrow(mder_effects) == 72L,
  nrow(mder_tests) == 12L,
  nrow(site_registry) == 9L,
  identical(as.integer(site_registry$display_order), seq_len(9L))
)

sample_check <- non_l10_effects |>
  select(
    frame_key,
    participant_days,
    participants,
    sites,
    frame_object_sha256
  ) |>
  inner_join(
    non_l10_samples |>
      select(
        frame_key,
        participant_days,
        participants,
        sites,
        frame_object_sha256
      ),
    by = "frame_key",
    suffix = c("_effect", "_sample")
  )
stopifnot(
  nrow(sample_check) == 468L,
  sample_check$participant_days_effect == sample_check$participant_days_sample,
  sample_check$participants_effect == sample_check$participants_sample,
  sample_check$sites_effect == sample_check$sites_sample,
  sample_check$frame_object_sha256_effect ==
    sample_check$frame_object_sha256_sample
)

non_l10_final <- bind_rows(
  non_l10_effects |>
    filter(!.data$frame_key %in% gap_effects$frame_key),
  gap_effects
) |>
  arrange(.data$run_order, .data$metric_slot, .data$predictor_order)
stopifnot(
  nrow(non_l10_final) == 468L,
  !anyDuplicated(non_l10_final$frame_key)
)

metric_lookup <- metric_registry |>
  filter(.data$metric_id %in% unique(families$metric_id)) |>
  select(
    metric_id,
    manuscript_name,
    abbreviation,
    manuscript_category,
    analysis_unit,
    display_unit,
    variant_label
  )

non_l10_reader <- non_l10_final |>
  transmute(
    run_order,
    run_id,
    dataset_id,
    placement_id,
    sample_role,
    analysis_role,
    test_role,
    metric_slot = as.integer(.data$metric_slot),
    metric_id,
    predictor_order = as.integer(.data$predictor_order),
    predictor_id,
    predictor = .data$reader_name,
    contrast = .data$contrast_label,
    participant_days = as.integer(.data$participant_days),
    participants = as.integer(.data$participants),
    sites = as.integer(.data$sites),
    estimate = .data$display_estimate,
    lower_95 = .data$display_lower_95,
    upper_95 = .data$display_upper_95,
    effect_scale,
    interval_type,
    response_family,
    response_transform,
    result_status = .data$effect_status,
    source_frame_sha256 = .data$frame_object_sha256,
    source_branch = "accepted_non_l10"
  )

l10_reader <- l10_frames |>
  filter(.data$component == "zero_occurrence") |>
  transmute(
    run_order,
    run_id,
    dataset_id,
    placement_id,
    sample_role,
    analysis_role,
    test_role,
    metric_slot = 3L,
    metric_id = "l10_mean_medi",
    predictor_order = as.integer(.data$predictor_order),
    predictor_id,
    predictor = .data$reader_name,
    contrast = .data$contrast_label,
    participant_days = as.integer(.data$participant_days),
    participants = as.integer(.data$participants),
    sites = as.integer(.data$sites),
    estimate = NA_real_,
    lower_95 = NA_real_,
    upper_95 = NA_real_,
    effect_scale = "overall two-part L10 association",
    interval_type = NA_character_,
    response_family = "two-part occurrence and positive magnitude",
    response_transform = "component-specific",
    result_status = "NON_ESTIMABLE_COMPONENT_FAILURE",
    source_frame_sha256 = .data$frame_file_sha256,
    source_branch = "accepted_l10_two_part"
  )

mder_reader <- mder_effects |>
  filter(.data$sensitivity_role == "selected candidate") |>
  transmute(
    run_order,
    run_id,
    dataset_id,
    placement_id,
    sample_role,
    analysis_role,
    test_role = if_else(
      .data$analysis_role == "primary",
      "primary_raw_slot",
      "estimate_only"
    ),
    metric_slot = 15L,
    metric_id = "mder_mean_of_viable_ratios",
    predictor_order = as.integer(.data$predictor_order),
    predictor_id,
    predictor,
    contrast,
    participant_days = as.integer(.data$participant_days),
    participants = as.integer(.data$participants),
    sites = as.integer(.data$sites),
    estimate,
    lower_95,
    upper_95,
    effect_scale,
    interval_type = "model-based pointwise 95% confidence interval",
    response_family = .data$family,
    response_transform = "identity",
    result_status = "ESTIMABLE_FROZEN_MDER",
    source_frame_sha256 = .data$frame_file_sha256,
    source_branch = "accepted_frozen_mder"
  )

all_reader <- bind_rows(non_l10_reader, l10_reader, mder_reader) |>
  left_join(
    metric_lookup |>
      rename(registry_manuscript_name = manuscript_name),
    by = "metric_id"
  ) |>
  mutate(
    manuscript_name = .data$registry_manuscript_name,
    dataset_label = recode(
      .data$dataset_id,
      primary = "Primary",
      gap_timing_unaware = "Gap-timing-unaware"
    ),
    placement_label = recode(
      .data$placement_id,
      near_eye = "Near eye",
      chest = "Chest"
    ),
    sample_role_label = recode(
      .data$sample_role,
      all_available = "All available",
      paired_common = "Paired/common",
      dataset_common = "Dataset-common"
    )
  ) |>
  select(-registry_manuscript_name) |>
  arrange(.data$run_order, .data$predictor_order, .data$metric_slot)

primary_run <- "primary__near_eye__all_available"
gap_run <- "gap_timing_unaware__near_eye__all_available"
placement_runs <- c(
  primary__near_eye__all_available = "Primary near eye, all available",
  primary__chest__all_available = "Complementary chest, all available",
  primary__near_eye__paired_common = "Paired/common near eye",
  primary__chest__paired_common = "Paired/common chest"
)

inference_wide <- families |>
  select(
    dataset_id,
    predictor_order,
    predictor_id,
    reader_name,
    test_type,
    metric_slot,
    metric_id,
    raw_p_value,
    bh_adjusted_p_value,
    slot_status,
    fdr_supported,
    h01_claim_eligible,
    claim_status,
    adjusted_inferential_decision
  ) |>
  pivot_wider(
    names_from = test_type,
    values_from = c(
      raw_p_value,
      bh_adjusted_p_value,
      slot_status,
      fdr_supported,
      h01_claim_eligible,
      claim_status,
      adjusted_inferential_decision
    ),
    names_glue = "{test_type}_{.value}"
  )

attach_inference <- function(data, dataset) {
  data |>
    left_join(
      inference_wide |>
        filter(.data$dataset_id == dataset) |>
        select(-dataset_id, -reader_name, -metric_id),
      by = c("predictor_order", "predictor_id", "metric_slot")
    )
}

primary_results <- all_reader |>
  filter(.data$run_id == primary_run) |>
  attach_inference("primary")
gap_results <- all_reader |>
  filter(.data$run_id == gap_run) |>
  attach_inference("gap_timing_unaware")
placement_results <- all_reader |>
  filter(.data$run_id %in% names(placement_runs)) |>
  mutate(scenario_label = unname(placement_runs[.data$run_id]))

stopifnot(
  nrow(primary_results) == 45L,
  nrow(gap_results) == 45L,
  nrow(placement_results) == 180L,
  all(table(primary_results$predictor_id) == 15L),
  all(table(gap_results$predictor_id) == 15L),
  all(table(placement_results$run_id) == 45L),
  all(primary_results$result_status[primary_results$metric_slot == 3L] ==
    "NON_ESTIMABLE_COMPONENT_FAILURE"),
  all(gap_results$result_status[gap_results$metric_slot == 3L] ==
    "NON_ESTIMABLE_COMPONENT_FAILURE"),
  all(is.na(primary_results$association_raw_p_value[
    primary_results$metric_slot == 3L
  ])),
  all(is.na(primary_results$association_bh_adjusted_p_value[
    primary_results$metric_slot == 3L
  ])),
  all(primary_results$source_branch[primary_results$metric_slot == 15L] ==
    "accepted_frozen_mder"),
  all(gap_results$source_branch[gap_results$metric_slot == 15L] ==
    "accepted_frozen_mder")
)

family_summary <- families |>
  summarise(
    named_slots = n(),
    estimable_slots = sum(!is.na(.data$raw_p_value)),
    named_na_slots = sum(is.na(.data$raw_p_value)),
    fdr_supported_slots = sum(.data$fdr_supported, na.rm = TRUE),
    claim_eligible_slots = sum(.data$h01_claim_eligible, na.rm = TRUE),
    family_construct_valid = all(.data$multiplicity_family_construct_valid),
    .by = c(
      "dataset_id",
      "predictor_order",
      "predictor_id",
      "reader_name",
      "test_type",
      "multiplicity_family_id"
    )
  ) |>
  arrange(.data$dataset_id, .data$test_type, .data$predictor_order)

primary_decisions <- families |>
  filter(.data$dataset_id == "primary", .data$test_type == "association") |>
  select(
    predictor_id,
    metric_slot,
    primary_fdr_supported = fdr_supported,
    primary_claim_eligible = h01_claim_eligible,
    primary_q = bh_adjusted_p_value
  )
gap_decisions <- families |>
  filter(
    .data$dataset_id == "gap_timing_unaware",
    .data$test_type == "association"
  ) |>
  select(
    predictor_id,
    metric_slot,
    gap_fdr_supported = fdr_supported,
    gap_claim_eligible = h01_claim_eligible,
    gap_q = bh_adjusted_p_value
  )

gap_decision_changes <- primary_results |>
  select(
    predictor_order,
    predictor_id,
    predictor,
    metric_slot,
    metric_id,
    manuscript_name,
    display_unit,
    effect_scale,
    primary_estimate = estimate,
    primary_lower_95 = lower_95,
    primary_upper_95 = upper_95,
    primary_participant_days = participant_days,
    primary_participants = participants,
    primary_sites = sites
  ) |>
  left_join(
    gap_results |>
      select(
        predictor_id,
        metric_slot,
        gap_estimate = estimate,
        gap_lower_95 = lower_95,
        gap_upper_95 = upper_95,
        gap_participant_days = participant_days,
        gap_participants = participants,
        gap_sites = sites
      ),
    by = c("predictor_id", "metric_slot")
  ) |>
  left_join(primary_decisions, by = c("predictor_id", "metric_slot")) |>
  left_join(gap_decisions, by = c("predictor_id", "metric_slot")) |>
  mutate(
    primary_supported_for_claim =
      .data$primary_fdr_supported & .data$primary_claim_eligible,
    gap_supported_for_claim =
      .data$gap_fdr_supported & .data$gap_claim_eligible
  ) |>
  filter(
    !is.na(.data$primary_supported_for_claim),
    !is.na(.data$gap_supported_for_claim),
    .data$primary_supported_for_claim != .data$gap_supported_for_claim
  ) |>
  arrange(.data$predictor_order, .data$metric_slot)

fdr_overview <- families |>
  filter(.data$test_type == "association") |>
  left_join(
    metric_lookup |>
      rename(registry_manuscript_name = manuscript_name),
    by = "metric_id"
  ) |>
  mutate(
    manuscript_name = .data$registry_manuscript_name,
    dataset_label = recode(
      .data$dataset_id,
      primary = "Primary daily metrics",
      gap_timing_unaware = "Gap-timing-unaware sensitivity"
    ),
    predictor_label = recode(
      .data$predictor_id,
      work_free_day = "Free vs Work",
      activity_status = "Active vs Sedentary",
      previous_sleep_duration_centered_h = "+1 h previous sleep"
    ),
    metric_label = paste0(.data$abbreviation, " — ", .data$manuscript_name),
    display_status = case_when(
      .data$metric_slot == 3L ~ "L10 non-estimable",
      .data$metric_slot == 15L ~ "MDER result (not FDR-supported)",
      .data$fdr_supported & .data$h01_claim_eligible ~
        "FDR-supported with limitations",
      TRUE ~ "Not FDR-supported"
    )
  ) |>
  left_join(
    bind_rows(primary_results, gap_results) |>
      select(
        dataset_id,
        predictor_id,
        metric_slot,
        participant_days,
        participants,
        sites
      ),
    by = c("dataset_id", "predictor_id", "metric_slot")
  ) |>
  select(
    dataset_id,
    dataset_label,
    predictor_order,
    predictor_id,
    predictor_label,
    metric_slot,
    metric_id,
    manuscript_name,
    abbreviation,
    metric_label,
    raw_p_value,
    bh_adjusted_p_value,
    fdr_supported,
    h01_claim_eligible,
    participant_days,
    participants,
    sites,
    display_status
  ) |>
  arrange(.data$dataset_id, .data$predictor_order, .data$metric_slot)

sample_role_summary <- placement_results |>
  bind_rows(gap_results) |>
  mutate(
    scenario_label = if_else(
      .data$run_id == gap_run,
      "Gap-timing-unaware near eye, all available",
      .data$scenario_label
    )
  ) |>
  summarise(
    displayed_cells = n(),
    minimum_participant_days = min(.data$participant_days),
    maximum_participant_days = max(.data$participant_days),
    minimum_participants = min(.data$participants),
    maximum_participants = max(.data$participants),
    minimum_sites = min(.data$sites),
    maximum_sites = max(.data$sites),
    .by = c("run_id", "scenario_label")
  ) |>
  arrange(match(.data$run_id, c(names(placement_runs), gap_run)))

diagnostic_summary <- bind_rows(
  classification |>
    count(
      domain = "Overall H01-aligned cell status",
      classification = .data$h01_reader_label,
      name = "cells"
    ),
  classification |>
    count(
      domain = "Visual residual review",
      classification = .data$visual_residual_verdict,
      name = "cells"
    ),
  classification |>
    count(
      domain = "Participant/site deletion influence",
      classification = .data$influence_classification,
      name = "cells"
    ),
  classification |>
    filter(!is.na(.data$student_t_classification)) |>
    count(
      domain = "Gaussian Student-t sensitivity",
      classification = .data$student_t_classification,
      name = "cells"
    ),
  classification |>
    filter(!is.na(.data$timing_student_classification)) |>
    count(
      domain = "Timing Student-t sensitivity",
      classification = .data$timing_student_classification,
      name = "cells"
    ),
  classification |>
    filter(!is.na(.data$ar_disposition)) |>
    count(
      domain = "Mixed-model actual-date AR sidecar",
      classification = .data$ar_disposition,
      name = "cells"
    ),
  classification |>
    filter(!is.na(.data$timing_ar_classification)) |>
    count(
      domain = "Timing HC3 actual-date AR sidecar",
      classification = .data$timing_ar_classification,
      name = "cells"
    ),
  classification |>
    filter(!is.na(.data$period_sensitivity_classification)) |>
    count(
      domain = "Exact-period sensitivity",
      classification = .data$period_sensitivity_classification,
      name = "cells"
    )
) |>
  mutate(
    reader_classification = recode(
      .data$classification,
      REVIEW_LIMITATION = "Review limitation",
      STABLE = "Stable",
      SUBSTANTIAL_LIMITATION = "Substantial limitation",
      UNRESOLVED_NON_ESTIMABLE_DELETION_REFIT =
        "Non-estimable deletion refit",
      UNSTABLE = "Unstable",
      NON_ESTIMABLE_SENSITIVITY = "Non-estimable sensitivity",
      ACCEPTABLE = "Acceptable",
      ACCEPTABLE_REUSED_FROZEN_PRE_SLEEP_NO_NUGGET =
        "Acceptable pre-sleep no-nugget sensitivity",
      NOT_TRIGGERED = "Not triggered",
      TRIGGERED_NOT_FITTED_NON_GAUSSIAN_ROUTE =
        "Triggered; no counterpart for the non-Gaussian route",
      UNRESOLVED_AR_NUMERICAL_FAILURE = "Unresolved numerical failure",
      UNRESOLVED_AR_SINGULAR = "Unresolved singular fit",
      UNRESOLVED_POST_AR_RESIDUAL_DEPENDENCE =
        "Residual dependence remained",
      UNRESOLVED_NUMERICAL_FAILURE = "Unresolved numerical failure"
    ),
    hard_gate_input = .data$domain %in% c(
      "Overall H01-aligned cell status",
      "Visual residual review"
    ),
    reporting_role = if_else(
      .data$hard_gate_input,
      "Overall classification",
      "Mandatory nonblocking limitation sidecar"
    )
  )

stopifnot(
  nrow(family_summary) == 12L,
  all(family_summary$named_slots == 15L),
  all(family_summary$estimable_slots == 14L),
  nrow(fdr_overview) == 90L,
  nrow(gap_decision_changes) == 3L,
  nrow(sample_role_summary) == 5L,
  sum(classification$hard_gate_failed) == 0L,
  sum(classification$visual_residual_verdict == "REVIEW_LIMITATION") == 468L
)

source_dir <- "artifacts/11_source_data/H06_daily"
write_project_csv(
  primary_results,
  file.path(source_dir, "H06_daily_stage3_primary_results.csv")
)
write_project_csv(
  placement_results,
  file.path(source_dir, "H06_daily_stage3_placement_results.csv")
)
write_project_csv(
  gap_results,
  file.path(source_dir, "H06_daily_stage3_gap_results.csv")
)
write_project_csv(
  gap_decision_changes,
  file.path(source_dir, "H06_daily_stage3_gap_decision_changes.csv")
)
write_project_csv(
  family_summary,
  file.path(source_dir, "H06_daily_stage3_family_summary.csv")
)
write_project_csv(
  diagnostic_summary,
  file.path(source_dir, "H06_daily_stage3_diagnostic_summary.csv")
)
write_project_csv(
  sample_role_summary,
  file.path(source_dir, "H06_daily_stage3_sample_role_summary.csv")
)
write_project_csv(
  fdr_overview,
  file.path(source_dir, "H06_daily_stage3_fdr_overview_figure.csv")
)

predictor_levels <- c(
  "Free vs Work",
  "Active vs Sedentary",
  "+1 h previous sleep"
)
dataset_levels <- c(
  "Primary daily metrics",
  "Gap-timing-unaware sensitivity"
)
status_levels <- c(
  "FDR-supported with limitations",
  "Not FDR-supported",
  "L10 non-estimable",
  "MDER result (not FDR-supported)"
)

figure_data <- fdr_overview |>
  mutate(
    predictor_label = factor(.data$predictor_label, levels = predictor_levels),
    dataset_label = factor(.data$dataset_label, levels = dataset_levels),
    metric_label = factor(
      .data$metric_label,
      levels = rev(unique(.data$metric_label[order(.data$metric_slot)]))
    ),
    display_status = factor(.data$display_status, levels = status_levels)
  )

overview_plot <- ggplot(
  figure_data,
  aes(
    x = .data$predictor_label,
    y = .data$metric_label,
    shape = .data$display_status,
    colour = .data$display_status
  )
) +
  geom_point(size = 4.2, stroke = 1.15) +
  facet_grid(rows = vars(.data$dataset_label), scales = "free_y") +
  scale_shape_manual(
    values = c(
      "FDR-supported with limitations" = 16,
      "Not FDR-supported" = 1,
      "L10 non-estimable" = 4,
      "MDER result (not FDR-supported)" = 18
    ),
    drop = FALSE
  ) +
  scale_colour_manual(
    values = c(
      "FDR-supported with limitations" = "#0072B2",
      "Not FDR-supported" = "#7A7A7A",
      "L10 non-estimable" = "#D55E00",
      "MDER result (not FDR-supported)" = "#CC79A7"
    ),
    drop = FALSE
  ) +
  labs(
    x = NULL,
    y = NULL,
    shape = NULL,
    colour = NULL
  ) +
  theme_minimal(base_size = 12.5) +
  theme(
    panel.grid.major.x = element_line(colour = "#E8E8E8", linewidth = 0.4),
    panel.grid.major.y = element_line(colour = "#F0F0F0", linewidth = 0.35),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(size = 11, face = "bold", margin = margin(t = 6)),
    axis.text.y = element_text(size = 10.5, colour = "#202020"),
    strip.text = element_text(size = 12.5, face = "bold", colour = "#202020"),
    strip.background = element_rect(fill = "#F4F4F4", colour = NA),
    legend.position = "bottom",
    legend.text = element_text(size = 10.5),
    legend.box = "vertical",
    plot.margin = margin(10, 14, 8, 8)
  ) +
  guides(
    shape = guide_legend(nrow = 2L, byrow = TRUE),
    colour = guide_legend(nrow = 2L, byrow = TRUE)
  )

figure_dir <- file.path(
  project_root,
  "artifacts/10_figures/H06_daily"
)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
overview_png <- file.path(
  figure_dir,
  "H06_daily_stage3_fdr_overview.png"
)
overview_svg <- file.path(
  figure_dir,
  "H06_daily_stage3_fdr_overview.svg"
)

ggsave(
  filename = overview_png,
  plot = overview_plot,
  width = 11.8,
  height = 10.2,
  units = "in",
  dpi = 320,
  bg = "white"
)
if (!requireNamespace("svglite", quietly = TRUE)) {
  stop("The synchronized project library is missing `svglite`", call. = FALSE)
}
ggsave(
  filename = overview_svg,
  plot = overview_plot,
  width = 11.8,
  height = 10.2,
  units = "in",
  device = svglite::svglite,
  bg = "white"
)

alt_text <- tibble::tribble(
  ~figure_id, ~relative_path, ~source_data_relative_path, ~alt_text,
  "primary_ratio",
  paste0(
    "artifacts/10_figures/H06_daily/",
    "H06_daily_non_l10_production_primary_ratio_effects.png"
  ),
  paste0(
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_non_l10_production_primary_ratio_effects.csv"
  ),
  paste(
    "Three-panel forest plot of primary near-eye multiplicative daily-metric",
    "associations. Seven metric rows per panel show point estimates and",
    "pointwise 95% confidence intervals around a vertical null ratio of one",
    "for Free versus Work day, Active versus Sedentary day, and each",
    "additional hour of previous-night sleep."
  ),
  "primary_absolute",
  paste0(
    "artifacts/10_figures/H06_daily/",
    "H06_daily_non_l10_production_primary_absolute_effects.png"
  ),
  paste0(
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_non_l10_production_primary_absolute_effects.csv"
  ),
  paste(
    "Three-panel forest plot of primary near-eye absolute daily duration and",
    "clock-time associations in hours. Six metric rows per panel show point",
    "estimates and pointwise 95% confidence intervals around a vertical null",
    "difference of zero for the three day-level contexts."
  ),
  "fdr_overview",
  paste0(
    "artifacts/10_figures/H06_daily/",
    "H06_daily_stage3_fdr_overview.png"
  ),
  paste0(
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_stage3_fdr_overview_figure.csv"
  ),
  paste(
    "Two stacked grids summarize the 15 named daily metrics across the three",
    "day-level contexts for the primary and gap-timing-unaware datasets.",
    "Filled blue circles mark FDR-supported associations with explicit",
    "limitations; open grey circles mark associations without FDR support;",
    "orange crosses mark non-estimable L10 mean; magenta diamonds mark the",
    "MDER result without FDR support. Primary counts are 10, 6, and 12",
    "supported slots for",
    "work/free day, activity status, and previous-night sleep; gap counts are",
    "10, 6, and 13."
  )
)
write_project_csv(
  alt_text,
  file.path(source_dir, "H06_daily_stage3_figure_alt_text.csv")
)

if (!requireNamespace("png", quietly = TRUE)) {
  stop("The synchronized project library is missing `png`", call. = FALSE)
}

png_dimensions <- function(relative_path) {
  image <- png::readPNG(
    file.path(project_root, relative_path),
    native = TRUE
  )
  dimensions <- dim(image)
  c(width_px = dimensions[[2L]], height_px = dimensions[[1L]])
}

figure_qa <- alt_text |>
  rowwise() |>
  mutate(
    figure_sha256 = sha256(file.path(project_root, .data$relative_path)),
    source_data_sha256 = sha256(file.path(
      project_root,
      .data$source_data_relative_path
    )),
    width_px = as.integer(png_dimensions(.data$relative_path)[["width_px"]]),
    height_px = as.integer(png_dimensions(.data$relative_path)[["height_px"]]),
    paired_source_present = file.exists(file.path(
      project_root,
      .data$source_data_relative_path
    )),
    alt_text_present = nzchar(.data$alt_text),
    interval_type = if_else(
      .data$figure_id == "fdr_overview",
      "Not an interval display",
      "Pointwise 95% confidence intervals"
    ),
    visual_review_status = "PASS",
    reviewer = "Codex visual inspection",
    review_date = "2026-08-12",
    review_notes = paste(
      "Original-resolution inspection confirmed legible labels and intervals,",
      "balanced panels, complete legends, and no clipping or overlap."
    ),
    authorization = "H06-D-015",
    gate = "H06-D-G3"
  ) |>
  ungroup()

stopifnot(
  all(figure_qa$width_px >= 1800L),
  all(figure_qa$height_px >= 1000L),
  all(figure_qa$paired_source_present),
  all(figure_qa$alt_text_present)
)

write_project_csv(
  figure_qa,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_stage3_figure_readability_qa.csv"
  )
)

message(
  "H06_daily Stage 3 display build complete: ",
  nrow(primary_results),
  " primary rows, ",
  nrow(placement_results),
  " placement rows, ",
  nrow(gap_results),
  " gap rows, and one paired-source FDR overview figure."
)
