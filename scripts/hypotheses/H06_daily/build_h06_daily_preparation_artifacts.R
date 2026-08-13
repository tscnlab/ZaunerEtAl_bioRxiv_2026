#!/usr/bin/env Rscript

# Build bounded descriptive and provenance artifacts for the H06_daily
# preparation companion. This script does not fit, refit, predict from, or
# compare a statistical model, and it does not calculate p-values.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tibble)
  library(tidyr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "The H06_daily preparation artifacts require R 4.6.1; found %s",
      getRversion()
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "build_h06_daily_preparation_artifacts.R"
)
source_dir <- file.path(root, "artifacts/11_source_data/H06_daily")
figure_dir <- file.path(root, "artifacts/10_figures/H06_daily")
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

read_h06d_csv <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}

write_h06d_csv <- function(data, filename) {
  invisible(write_csv_artifact(
    data,
    file.path(source_dir, filename),
    producer = producer
  ))
}

####
# Step 1: Verify accepted inputs
####

input_pins <- tibble::tribble(
  ~input_role, ~relative_path, ~expected_sha256,
  "Stage 3 acceptance and preparation transition",
  "audit/hypotheses/H06_daily/H06_daily_stage3_acceptance_stage4_transition.md",
  "80d52eea0d175c55098f5aaa716f0d37f5ba4ff532aca5c35fd94a4912549c67",
  "Accepted Stage 2 to Stage 3 transition",
  "audit/decisions/h06_daily_stage2_acceptance_stage3_transition.md",
  "26e3cf5302db74156a2ad929a80a1352eac6967ccf0e0e1adb5cdcfa71b9954e",
  "Accepted Stage 3 revision record",
  "audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md",
  "733dd1dd4c57bfdb6df7bf10e69e635455c451373c8dd0f6e3060c12b6e3884e",
  "Accepted H06_daily results source",
  "notebooks/hypotheses/H06_daily.qmd",
  "0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc",
  "Accepted H06_daily results HTML",
  "notebooks/hypotheses/H06_daily.html",
  "5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3",
  "Accepted Stage 3 source-data manifest",
  "artifacts/12_manifests/H06_daily/H06_daily_stage3_source_data_manifest.csv",
  "77cd39b759a0bb46505c71db34f9b38818848531491f69afc7d67bf4dd8dc3ed",
  "Accepted Stage 3 output manifest",
  "artifacts/12_manifests/H06_daily/H06_daily_stage3_output_manifest.csv",
  "7c7658fca61687b0124f0f49a1b773fd1a101af7a5e6be641cd1adc2eb09c01e",
  "Accepted Stage 3 render QA",
  "artifacts/12_manifests/H06_daily/H06_daily_stage3_render_qa.csv",
  "d61a2550545370532ea1e000b23b198be24380d27980ae72b2a17686f4433f2f",
  "Accepted Stage 3 figure QA",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_stage3_revision_figure_readability_qa.csv"
  ),
  "75f3e82a7fcfa6b846fbb13b5441d892767b322073222bd7b6d433ecfa318064",
  "Accepted Stage 3 focused test",
  "tests/hypotheses/H06_daily/test_h06_daily_stage3_reader_report.R",
  "16e3d02bbfe443928708a8a6e2c793a04c47281afaa8993116e1c27d0bdaa8d2",
  "Non-L10 production output manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_non_l10_production_output_manifest.csv"
  ),
  "63c6e873c35bcef3b2a12600da27e10dc1097cf43e14be96dee838ce15d4e7e1",
  "Gap clock repair output manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_gap_clock_repair_output_manifest.csv"
  ),
  "54b63ff4dc3edf4cd112d4b7c71f02f193ee1be367fdd889d9a69923be6d1084",
  "L10 METRIC-011 output manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_l10_metric011_production_output_manifest.csv"
  ),
  "af89132e004e29d27351302b0f765ce9845da53fb6619d8d042aaa980165626c",
  "MDER METRIC-010 output manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_mder_metric010_production_output_manifest.csv"
  ),
  "19d91fdc62c81cf342490a2197ba335eb751b26500df102c0d0e8cbebf3a119c",
  "Temporal model output manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_temporal_h02_production_model_output_manifest.csv"
  ),
  "3386633a579406b262ab2f43aee86f908a140b08c674b1b01348be522db64684",
  "Temporal inference output manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_temporal_h02_production_inference_output_manifest.csv"
  ),
  "4b6a9b1d1cc3e4d07921385beb432b21b72d0afd0fee1c0e3434b9dab052ac4b",
  "Temporal frame output manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_temporal_h02_production_frame_output_manifest.csv"
  ),
  "8463445ac682272a59fda9617a2f77033d6c3ef54b3a5b29ea4f67eb1bdfa6d9",
  "Temporal diagnostic output manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_temporal_h02_production_diagnostic_output_manifest.csv"
  ),
  "1b1002578ba864064024617a1a91487145805570a96856bc6891da07034d80e3",
  "Joint-context exploratory output manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_joint_context_exploratory_output_manifest.csv"
  ),
  "90b458b251f023c4e9a4716164ceeb13942acf6bb976a61106b513d79164fb89"
)

input_paths <- file.path(root, input_pins$relative_path)
if (any(!file.exists(input_paths))) {
  stop("One or more accepted H06_daily preparation inputs are missing", call. = FALSE)
}

input_provenance <- input_pins |>
  mutate(
    observed_sha256 = vapply(input_paths, artifact_sha256, character(1L)),
    bytes = as.numeric(file.info(input_paths)$size),
    verification_status = if_else(
      .data$expected_sha256 == .data$observed_sha256,
      "PASS",
      "FAIL"
    ),
    r_version = as.character(getRversion())
  )

if (!all(input_provenance$verification_status == "PASS")) {
  failed <- input_provenance$relative_path[
    input_provenance$verification_status != "PASS"
  ]
  stop(
    paste("Accepted H06_daily input identity mismatch:", paste(failed, collapse = ", ")),
    call. = FALSE
  )
}
write_h06d_csv(input_provenance, "H06_daily_preparation_input_provenance.csv")

####
# Step 2: Read frozen scientific records
####

primary_results <- read_h06d_csv(
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_results.csv"
)
placement_results <- read_h06d_csv(
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_placement_results.csv"
)
family_summary <- read_h06d_csv(
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_family_summary.csv"
)
diagnostic_summary <- read_h06d_csv(
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_diagnostic_summary.csv"
)
non_l10_samples <- read_h06d_csv(
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_non_l10_production_exact_samples.csv"
  )
)
base_checkpoint <- read_h06d_csv(
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_non_l10_production_base_checkpoint.csv"
  )
)
final_classification <- read_h06d_csv(
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_gap_clock_repair_h01_classification.csv"
  )
)
l10_registry <- read_h06d_csv(
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_l10_metric011_frame_registry.csv"
  )
)
mder_registry <- read_h06d_csv(
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_mder_metric010_frame_registry.csv"
  )
)
joint_registry <- read_h06d_csv(
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_joint_context_exploratory_frame_registry.csv"
  )
)
temporal_runs <- read_h06d_csv(
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_temporal_h02_production_run_registry.csv"
  )
)
temporal_support <- read_h06d_csv(
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_temporal_h02_production_support_overall.csv"
  )
)
temporal_formula <- read_h06d_csv(
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_temporal_h02_formula_registry.csv"
  )
)
temporal_diagnostics <- read_h06d_csv(
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_temporal_h02_production_component_diagnostics.csv"
  )
)
site_registry <- read_h06d_csv("config/site_display_registry.csv")

stopifnot(
  nrow(primary_results) == 45L,
  nrow(placement_results) == 180L,
  nrow(family_summary) == 12L,
  nrow(diagnostic_summary) == 25L,
  nrow(non_l10_samples) == 468L,
  nrow(base_checkpoint) == 468L,
  nrow(final_classification) == 468L,
  nrow(l10_registry) == 36L,
  nrow(mder_registry) == 36L,
  nrow(joint_registry) == 14L,
  nrow(temporal_runs) == 6L,
  nrow(temporal_support) == 6L,
  nrow(temporal_formula) == 1L,
  nrow(temporal_diagnostics) == 6L,
  nrow(site_registry) == 9L,
  all(primary_results$metric_slot %in% 1:15),
  n_distinct(primary_results$metric_slot) == 15L,
  n_distinct(primary_results$predictor_id) == 3L,
  all(final_classification$h01_reader_label == "Acceptable with limitations"),
  all(!final_classification$hard_gate_failed)
)

####
# Step 3: Build metric, predictor, and model-route registries
####

route_lookup <- final_classification |>
  distinct(.data$metric_slot, .data$route)
stopifnot(nrow(route_lookup) == 13L)

primary_zero_ranges <- non_l10_samples |>
  filter(.data$run_id == "primary__near_eye__all_available") |>
  summarise(
    primary_exact_zeros_min = min(.data$exact_source_zeros),
    primary_exact_zeros_max = max(.data$exact_source_zeros),
    primary_observed_minimum = min(.data$source_minimum),
    primary_observed_maximum = max(.data$source_maximum),
    .by = c("metric_slot", "metric_id")
  )

l10_zero_range <- l10_registry |>
  filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$component == "zero_occurrence"
  ) |>
  summarise(
    metric_slot = 3L,
    metric_id = "l10_mean_medi",
    primary_exact_zeros_min = min(.data$parent_exact_zeros),
    primary_exact_zeros_max = max(.data$parent_exact_zeros),
    primary_observed_minimum = 0,
    primary_observed_maximum = max(.data$response_maximum)
  )

mder_zero_range <- mder_registry |>
  filter(.data$run_id == "primary__near_eye__all_available") |>
  summarise(
    metric_slot = 15L,
    metric_id = "mder_mean_of_viable_ratios",
    primary_exact_zeros_min = min(.data$exact_zeros),
    primary_exact_zeros_max = max(.data$exact_zeros),
    primary_observed_minimum = min(.data$minimum),
    primary_observed_maximum = max(.data$maximum)
  )

metric_registry <- primary_results |>
  distinct(
    .data$metric_slot,
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation,
    .data$manuscript_category,
    .data$analysis_unit,
    .data$display_unit,
    .data$response_family,
    .data$response_transform,
    .data$effect_scale,
    .data$result_status,
    .data$source_branch
  ) |>
  left_join(route_lookup, by = "metric_slot", relationship = "one-to-one") |>
  mutate(
    route = case_when(
      .data$metric_slot == 3L ~ "two_part_non_estimable_joint",
      .data$metric_slot == 15L ~ "mixed_model",
      TRUE ~ .data$route
    )
  ) |>
  left_join(
    bind_rows(primary_zero_ranges, l10_zero_range, mder_zero_range),
    by = c("metric_slot", "metric_id"),
    relationship = "one-to-one"
  ) |>
  mutate(
    zero_handling = case_when(
      .data$metric_slot == 3L ~ paste(
        "Exact zeros retained in the occurrence component and excluded only",
        "from the strictly positive magnitude component"
      ),
      .data$metric_slot == 15L ~ paste(
        "Only viable strictly positive finite minute ratios contribute;",
        "at least 720 viable minutes are required"
      ),
      .data$primary_exact_zeros_max > 0 ~
        "Exact zeros retained in the selected one-part response model",
      TRUE ~ "No exact zero occurred in the primary fitted samples"
    ),
    reader_route = recode(
      .data$route,
      mixed_model = "Fixed-site mixed model with participant random intercept",
      participant_cluster_HC3 = paste(
        "Fixed-site linear model with participant-cluster HC3 covariance"
      ),
      two_part_non_estimable_joint = paste(
        "Two-part occurrence and positive magnitude route; joint slot not estimable"
      )
    )
  ) |>
  arrange(.data$metric_slot)

stopifnot(
  nrow(metric_registry) == 15L,
  identical(as.integer(metric_registry$metric_slot), 1:15),
  metric_registry$route[metric_registry$metric_slot == 3L] ==
    "two_part_non_estimable_joint",
  metric_registry$route[metric_registry$metric_slot == 15L] == "mixed_model"
)
write_h06d_csv(metric_registry, "H06_daily_preparation_metric_registry.csv")

predictor_registry <- primary_results |>
  distinct(
    .data$predictor_order,
    .data$predictor_id,
    reader_name = .data$predictor
  ) |>
  mutate(
    reference = case_when(
      .data$predictor_id == "work_free_day" ~ "Work day",
      .data$predictor_id == "activity_status" ~ "Sedentary",
      TRUE ~ "Participant mean and day-specific deviation reported separately where applicable"
    ),
    interpretation = case_when(
      .data$predictor_id == "work_free_day" ~ "Free day compared with Work day",
      .data$predictor_id == "activity_status" ~ "Active compared with Sedentary",
      TRUE ~ "Per 1 h greater previous-night sleep duration"
    )
  ) |>
  arrange(.data$predictor_order)

stopifnot(nrow(predictor_registry) == 3L)
write_h06d_csv(
  predictor_registry,
  "H06_daily_preparation_predictor_registry.csv"
)

model_routes <- metric_registry |>
  transmute(
    .data$metric_slot,
    .data$manuscript_name,
    .data$response_family,
    .data$response_transform,
    .data$reader_route,
    reduced_formula = case_when(
      .data$route == "participant_cluster_HC3" ~ "response_value ~ site",
      TRUE ~ "response_value ~ site + (1 | participant_key)"
    ),
    additive_formula = case_when(
      .data$route == "participant_cluster_HC3" ~
        "response_value ~ site + predictor",
      TRUE ~ "response_value ~ site + predictor + (1 | participant_key)"
    ),
    heterogeneity_formula = case_when(
      .data$route == "participant_cluster_HC3" ~
        "response_value ~ site * predictor",
      TRUE ~ "response_value ~ site * predictor + (1 | participant_key)"
    ),
    uncertainty = case_when(
      .data$route == "participant_cluster_HC3" ~ paste(
        "Participant-cluster HC3 covariance; participant clusters minus one",
        "degrees of freedom; pointwise 95% CI"
      ),
      .data$metric_slot == 3L ~ paste(
        "Component-specific intervals only; joint association and",
        "heterogeneity tests are non-estimable"
      ),
      TRUE ~ "Model-based pointwise 95% CI"
    )
  )
write_h06d_csv(model_routes, "H06_daily_preparation_model_routes.csv")

####
# Step 4: Assemble the complete fitted-sample registry
####

non_l10_exact <- non_l10_samples |>
  transmute(
    .data$run_order,
    .data$run_id,
    .data$dataset_id,
    .data$placement_id,
    .data$sample_role,
    .data$analysis_role,
    .data$test_role,
    .data$metric_slot,
    .data$metric_id,
    .data$manuscript_name,
    .data$predictor_order,
    .data$predictor_id,
    reader_name = .data$reader_name,
    component = "one_part",
    .data$participant_days,
    .data$participants,
    .data$sites,
    .data$exact_source_zeros,
    .data$frame_object_sha256,
    frame_path = NA_character_,
    frame_file_sha256 = NA_character_,
    source_branch = "accepted_non_l10"
  )

l10_exact <- l10_registry |>
  filter(.data$component == "zero_occurrence") |>
  transmute(
    .data$run_order,
    .data$run_id,
    .data$dataset_id,
    .data$placement_id,
    .data$sample_role,
    .data$analysis_role,
    .data$test_role,
    metric_slot = 3L,
    metric_id = "l10_mean_medi",
    manuscript_name = "Darkest 10 h mean melEDI",
    .data$predictor_order,
    .data$predictor_id,
    reader_name = .data$reader_name,
    component = "full_parent_for_two_part_route",
    participant_days = .data$parent_participant_days,
    .data$participants,
    .data$sites,
    exact_source_zeros = .data$parent_exact_zeros,
    .data$frame_object_sha256,
    .data$frame_path,
    .data$frame_file_sha256,
    source_branch = "accepted_l10_metric011"
  )

mder_exact <- mder_registry |>
  transmute(
    .data$run_order,
    .data$run_id,
    .data$dataset_id,
    .data$placement_id,
    .data$sample_role,
    .data$analysis_role,
    .data$test_role,
    metric_slot = 15L,
    metric_id = "mder_mean_of_viable_ratios",
    manuscript_name = "Melanopic daylight efficacy ratio",
    .data$predictor_order,
    .data$predictor_id,
    reader_name = .data$reader_name,
    component = "one_part",
    .data$participant_days,
    .data$participants,
    .data$sites,
    exact_source_zeros = .data$exact_zeros,
    .data$frame_object_sha256,
    .data$frame_path,
    .data$frame_file_sha256,
    source_branch = "accepted_frozen_mder"
  )

exact_samples <- bind_rows(non_l10_exact, l10_exact, mder_exact) |>
  arrange(
    .data$run_order,
    .data$metric_slot,
    .data$predictor_order
  )

stopifnot(
  nrow(exact_samples) == 522L,
  !anyDuplicated(exact_samples[c("run_id", "metric_slot", "predictor_id")]),
  all(exact_samples$participant_days > 0L),
  all(exact_samples$participants > 0L),
  all(exact_samples$sites > 0L)
)
write_h06d_csv(exact_samples, "H06_daily_preparation_exact_samples.csv")

run_labels <- tibble::tribble(
  ~run_id, ~scenario_label,
  "primary__near_eye__all_available", "Primary near eye, all available",
  "primary__chest__all_available", "Complementary chest, all available",
  "primary__near_eye__paired_common", "Paired/common near eye",
  "primary__chest__paired_common", "Paired/common chest",
  "gap_timing_unaware__near_eye__all_available",
  "Gap-timing-unaware near eye, all available",
  "gap_timing_unaware__chest__all_available",
  "Gap-timing-unaware chest, all available",
  "gap_timing_unaware__near_eye__paired_common",
  "Gap-timing-unaware paired/common near eye",
  "gap_timing_unaware__chest__paired_common",
  "Gap-timing-unaware paired/common chest",
  "primary__near_eye__dataset_common", "Primary near eye, dataset-common",
  "gap_timing_unaware__near_eye__dataset_common",
  "Gap-timing-unaware near eye, dataset-common",
  "primary__chest__dataset_common", "Primary chest, dataset-common",
  "gap_timing_unaware__chest__dataset_common",
  "Gap-timing-unaware chest, dataset-common"
)

sample_role_summary <- exact_samples |>
  summarise(
    analyzed_metric_predictor_cells = n(),
    analyzed_metrics = n_distinct(.data$metric_slot),
    participant_days_min = min(.data$participant_days),
    participant_days_max = max(.data$participant_days),
    participants_min = min(.data$participants),
    participants_max = max(.data$participants),
    sites_min = min(.data$sites),
    sites_max = max(.data$sites),
    .by = c(
      "run_order", "run_id", "dataset_id", "placement_id", "sample_role",
      "analysis_role", "test_role"
    )
  ) |>
  left_join(run_labels, by = "run_id", relationship = "many-to-one") |>
  arrange(.data$run_order)

stopifnot(
  nrow(sample_role_summary) == 12L,
  !anyNA(sample_role_summary$scenario_label)
)
write_h06d_csv(
  sample_role_summary,
  "H06_daily_preparation_sample_role_summary.csv"
)

primary_sample_by_metric <- exact_samples |>
  filter(.data$run_id == "primary__near_eye__all_available") |>
  summarise(
    predictor_specific_samples = n(),
    participant_days_min = min(.data$participant_days),
    participant_days_max = max(.data$participant_days),
    participants_min = min(.data$participants),
    participants_max = max(.data$participants),
    sites_min = min(.data$sites),
    sites_max = max(.data$sites),
    exact_source_zeros_min = min(.data$exact_source_zeros),
    exact_source_zeros_max = max(.data$exact_source_zeros),
    .by = c("metric_slot", "metric_id", "manuscript_name")
  ) |>
  arrange(.data$metric_slot)

stopifnot(
  nrow(primary_sample_by_metric) == 15L,
  all(primary_sample_by_metric$predictor_specific_samples == 3L)
)
write_h06d_csv(
  primary_sample_by_metric,
  "H06_daily_preparation_primary_sample_by_metric.csv"
)

####
# Step 5: Describe primary predictor and site support from stored frames
####

primary_non_l10_index <- base_checkpoint |>
  filter(.data$run_id == "primary__near_eye__all_available") |>
  select(
    "metric_slot",
    "metric_id",
    "manuscript_name",
    "predictor_order",
    "predictor_id",
    "reader_name",
    "participant_days",
    "route",
    "checkpoint_relative_path"
  )

read_checkpoint_frame <- function(relative_path, route) {
  checkpoint <- readRDS(file.path(root, relative_path))
  if (identical(route, "mixed_model")) {
    fit <- checkpoint$result$models$additive_reml$value
    return(stats::model.frame(fit))
  }
  if (identical(route, "participant_cluster_HC3")) {
    return(checkpoint$result$models$models$additive$model)
  }
  stop("Unknown H06_daily stored-frame route", call. = FALSE)
}

primary_frame_rows <- vector("list", nrow(primary_non_l10_index))
for (index in seq_len(nrow(primary_non_l10_index))) {
  record <- primary_non_l10_index[index, ]
  frame <- read_checkpoint_frame(
    record$checkpoint_relative_path[[1L]],
    record$route[[1L]]
  )
  stopifnot(nrow(frame) == record$participant_days[[1L]])
  primary_frame_rows[[index]] <- list(record = record, frame = frame)
}

primary_l10_index <- l10_registry |>
  filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$component == "zero_occurrence"
  ) |>
  transmute(
    metric_slot = 3L,
    metric_id = "l10_mean_medi",
    manuscript_name = "Darkest 10 h mean melEDI",
    .data$predictor_order,
    .data$predictor_id,
    reader_name = .data$reader_name,
    participant_days = .data$parent_participant_days,
    route = "two_part_non_estimable_joint",
    checkpoint_relative_path = .data$frame_path
  )

for (index in seq_len(nrow(primary_l10_index))) {
  record <- primary_l10_index[index, ]
  frame <- readRDS(file.path(root, record$checkpoint_relative_path[[1L]]))
  stopifnot(nrow(frame) == record$participant_days[[1L]])
  primary_frame_rows[[length(primary_frame_rows) + 1L]] <- list(
    record = record,
    frame = frame
  )
}

primary_mder_index <- mder_registry |>
  filter(.data$run_id == "primary__near_eye__all_available") |>
  transmute(
    metric_slot = 15L,
    metric_id = "mder_mean_of_viable_ratios",
    manuscript_name = "Melanopic daylight efficacy ratio",
    .data$predictor_order,
    .data$predictor_id,
    reader_name = .data$reader_name,
    .data$participant_days,
    route = "mixed_model",
    checkpoint_relative_path = .data$frame_path
  )

for (index in seq_len(nrow(primary_mder_index))) {
  record <- primary_mder_index[index, ]
  frame <- readRDS(file.path(root, record$checkpoint_relative_path[[1L]]))
  stopifnot(nrow(frame) == record$participant_days[[1L]])
  primary_frame_rows[[length(primary_frame_rows) + 1L]] <- list(
    record = record,
    frame = frame
  )
}

stopifnot(length(primary_frame_rows) == 45L)

predictor_support <- bind_rows(lapply(primary_frame_rows, function(item) {
  record <- item$record
  frame <- item$frame
  predictor <- record$predictor_id[[1L]]
  if (!predictor %in% names(frame)) {
    stop("A stored primary frame lacks its predictor column", call. = FALSE)
  }
  values <- frame[[predictor]]
  if (predictor %in% c("work_free_day", "activity_status")) {
    return(tibble(
      metric_slot = record$metric_slot[[1L]],
      metric_id = record$metric_id[[1L]],
      manuscript_name = record$manuscript_name[[1L]],
      predictor_order = record$predictor_order[[1L]],
      predictor_id = predictor,
      reader_name = record$reader_name[[1L]],
      support_type = "category",
      category = as.character(values)
    ) |>
      count(
        .data$metric_slot,
        .data$metric_id,
        .data$manuscript_name,
        .data$predictor_order,
        .data$predictor_id,
        .data$reader_name,
        .data$support_type,
        .data$category,
        name = "participant_days"
      ) |>
      mutate(
        previous_sleep_minimum_h = NA_real_,
        previous_sleep_median_h = NA_real_,
        previous_sleep_maximum_h = NA_real_
      ))
  }
  tibble(
    metric_slot = record$metric_slot[[1L]],
    metric_id = record$metric_id[[1L]],
    manuscript_name = record$manuscript_name[[1L]],
    predictor_order = record$predictor_order[[1L]],
    predictor_id = predictor,
    reader_name = record$reader_name[[1L]],
    support_type = "continuous_range",
    category = "Observed previous-night sleep duration",
    participant_days = length(values),
    previous_sleep_minimum_h = min(as.numeric(values)) + 8,
    previous_sleep_median_h = stats::median(as.numeric(values)) + 8,
    previous_sleep_maximum_h = max(as.numeric(values)) + 8
  )
})) |>
  arrange(.data$metric_slot, .data$predictor_order, .data$category)

stopifnot(
  n_distinct(predictor_support$metric_slot) == 15L,
  n_distinct(predictor_support$predictor_id) == 3L,
  all(predictor_support$participant_days > 0L)
)
write_h06d_csv(
  predictor_support,
  "H06_daily_preparation_primary_predictor_support.csv"
)

site_support <- bind_rows(lapply(primary_frame_rows, function(item) {
  record <- item$record
  frame <- item$frame
  tibble(
    metric_slot = record$metric_slot[[1L]],
    metric_id = record$metric_id[[1L]],
    manuscript_name = record$manuscript_name[[1L]],
    predictor_order = record$predictor_order[[1L]],
    predictor_id = record$predictor_id[[1L]],
    site = as.character(frame$site)
  ) |>
    count(
      .data$metric_slot,
      .data$metric_id,
      .data$manuscript_name,
      .data$predictor_order,
      .data$predictor_id,
      .data$site,
      name = "participant_days"
    )
})) |>
  left_join(site_registry, by = "site", relationship = "many-to-one") |>
  arrange(.data$display_order, .data$metric_slot, .data$predictor_order)

stopifnot(
  nrow(site_support) == 405L,
  !anyNA(site_support$display_name),
  !anyNA(site_support$color_hex),
  all(site_support$participant_days > 0L)
)
write_h06d_csv(
  site_support,
  "H06_daily_preparation_primary_site_support.csv"
)

####
# Step 6: Record multiplicity, diagnostics, sensitivities, and code flow
####

write_h06d_csv(
  family_summary,
  "H06_daily_preparation_multiplicity_families.csv"
)
write_h06d_csv(
  diagnostic_summary,
  "H06_daily_preparation_diagnostic_summary.csv"
)

temporal_registry <- temporal_support |>
  select(
    "run_order",
    "run_id",
    "data_scenario_label",
    "placement_label",
    "sample_scenario",
    "analytical_role",
    "multiplicity_role",
    "observations_30_minute",
    "participant_days",
    "participants",
    "sites",
    "exact_zero_bins",
    "exact_zero_fraction",
    "ar_sequences",
    "sleep_grand_mean_h"
  ) |>
  left_join(
    temporal_runs |>
      select("run_id", registry_role = "analytical_role"),
    by = "run_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    temporal_diagnostics |>
      select(
        "run_id",
        "rho",
        "final_standardized_residual_lag1",
        "standardized_residual_qq_correlation",
        "absolute_residual_fitted_spearman",
        "convergence",
        "preliminary_warning_count",
        "final_warning_count"
      ),
    by = "run_id",
    relationship = "one-to-one"
  ) |>
  arrange(.data$run_order)
write_h06d_csv(
  temporal_registry,
  "H06_daily_preparation_temporal_support.csv"
)

sensitivity_registry <- tibble::tribble(
  ~branch, ~stored_scope, ~scientific_question, ~inferential_role,
  "Chest placement",
  "All-available chest participant-days",
  "Whether complementary non-ocular placement evidence is directionally compatible",
  "Estimation only",
  "Paired/common placement",
  "Near-eye and chest estimates on the same participant-days",
  "Whether placement comparisons are driven by unequal day samples",
  "Complementary estimation",
  "Gap-timing-unaware dataset",
  paste(
    "The 50%-per-hour and 80%-per-day coverage rules remain, but remaining",
    "gap timing does not trigger the additional metric-specific adjustment"
  ),
  "Whether the primary conclusion depends on using the timing of remaining gaps",
  "Separate near-eye 15-slot FDR families",
  "Dataset-common sample",
  "Primary and gap-timing-unaware estimates on identical day keys",
  "Whether different retained days explain a dataset comparison",
  "Estimation only",
  "Response-family checks",
  "Gaussian Student-t or Tweedie alternatives where prespecified and estimable",
  "Whether distributional assumptions materially move an association",
  "Mandatory limitation sidecar",
  "Actual-date AR(1)",
  "Consecutive observed dates within participant; gaps start new sequences",
  "Whether residual day-to-day dependence materially moves an association",
  "Mandatory nonblocking sidecar",
  "Exact-period check",
  "Exactly identified longest continuous-period records",
  "Whether interval uncertainty changes the longest-period association",
  "Mandatory nonblocking sidecar",
  "Participant and site deletion",
  "Checkpointed one-cluster-at-a-time refits",
  "Whether one participant or one site dominates an association",
  "Mandatory nonblocking sidecar",
  "Registered random-site benchmark",
  "Signed predictor random slope by site with participant nested in site",
  "Whether the exact registered structure is estimable without replacing it",
  "Benchmark only"
)
write_h06d_csv(
  sensitivity_registry,
  "H06_daily_preparation_sensitivity_registry.csv"
)

code_map <- tibble::tribble(
  ~sequence, ~module, ~responsibility,
  1L, "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "Daily metric, predictor, formula, reference-coding, and temporal contracts",
  2L, "scripts/hypotheses/H06_daily/h06_daily_data.R",
  "Participant-day frame assembly from prepared metrics and context records",
  3L, "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_contract.R",
  "Non-L10 run, sample, route, and multiplicity contracts",
  4L, "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_modeling.R",
  "Mixed-model and HC3 routes, contrasts, diagnostics, and sidecars",
  5L, "scripts/hypotheses/H06_daily/run_h06_daily_non_l10_production_base.R",
  "Checkpointed non-L10 model execution",
  6L, "scripts/hypotheses/H06_daily/run_h06_daily_non_l10_production_sensitivities.R",
  "Response-family and actual-date dependence sensitivities",
  7L, "scripts/hypotheses/H06_daily/run_h06_daily_non_l10_production_influence.R",
  "Participant and site deletion checks",
  8L, "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_contract.R",
  "Exact-zero occurrence and strictly positive L10 magnitude contract",
  9L, "scripts/hypotheses/H06_daily/run_h06_daily_l10_metric011_production.R",
  "Two-part L10 branch retained as non-estimable for joint inference",
  10L, "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R",
  "Mean-of-viable-one-minute-ratios MDER contract",
  11L, "scripts/hypotheses/H06_daily/run_h06_daily_mder_metric010_production.R",
  "MDER model and sensitivity execution",
  12L, "scripts/hypotheses/H06_daily/finalize_h06_daily_gap_clock_repair.R",
  "Task-local conversion of gap timing values to clock hours and resealing",
  13L, "scripts/hypotheses/H06_daily/run_h06_daily_joint_context_exploratory.R",
  "Exploratory jointly adjusted day type, activity, and sleep models",
  14L, "scripts/hypotheses/H06_daily/build_h06_daily_temporal_h02_production_frames.R",
  "Supported 30-minute frames and true-time AR sequence boundaries",
  15L, "scripts/hypotheses/H06_daily/run_h06_daily_temporal_h02_production_models.R",
  "H02-aligned exploratory BAM fits with frame-specific working AR(1)",
  16L, "scripts/hypotheses/H06_daily/extract_h06_daily_temporal_h02_production.R",
  "Pointwise clock-time functions and whole-function tests from stored fits",
  17L, "scripts/hypotheses/H06_daily/build_h06_daily_stage3_reader.R",
  "Reader-facing tables, figures, and paired source data",
  18L, "notebooks/hypotheses/H06_daily.qmd",
  "Complementary results report",
  19L, producer,
  "Bounded descriptive and provenance source data for this companion",
  20L, "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd",
  "Preparation and provenance display from stored scientific artifacts"
) |>
  mutate(
    exists = file.exists(file.path(root, .data$module)),
    sha256 = if_else(
      .data$exists,
      vapply(file.path(root, .data$module), artifact_sha256, character(1L)),
      NA_character_
    )
  )

stopifnot(all(code_map$exists))
write_h06d_csv(code_map, "H06_daily_preparation_code_map.csv")

output_trace_paths <- c(
  "artifacts/09_tables/H06_daily/H06_daily_gap_clock_repair_primary_gap_results.csv",
  "artifacts/09_tables/H06_daily/H06_daily_gap_clock_repair_bh_families.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_gap_clock_repair_h01_classification.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_gap_clock_repair_influence_summary.csv",
  "artifacts/07_models/H06_daily/H06_daily_l10_metric011_production_models.rds",
  "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_model_tests.csv",
  "artifacts/07_models/H06_daily/H06_daily_mder_metric010_production_models.rds",
  "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_model_tests.csv",
  "artifacts/07_models/H06_daily/H06_daily_joint_context_exploratory_cells",
  "artifacts/09_tables/H06_daily/H06_daily_joint_context_exploratory_tests.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_temporal_h02_production_support_overall.csv",
  "artifacts/09_tables/H06_daily/H06_daily_temporal_h02_production_whole_function_tests.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_results.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_placement_results.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_gap_results.csv",
  "notebooks/hypotheses/H06_daily.qmd",
  "notebooks/hypotheses/H06_daily.html"
)
output_trace_roles <- c(
  "Primary and gap daily-grid results",
  "Twelve complete 15-slot BH families",
  "Final H01-aligned cell classifications",
  "Participant and site deletion summary",
  "L10 two-part model bundle",
  "L10 component and joint-test record",
  "MDER model bundle",
  "MDER model-test record",
  "Exploratory joint-context per-cell model directory",
  "Exploratory jointly adjusted tests",
  "Temporal GAMM fitted support",
  "Temporal GAMM whole-function tests",
  "Primary reader source data",
  "Placement reader source data",
  "Gap-timing-unaware reader source data",
  "Results source",
  "Results HTML"
)

output_trace_absolute <- file.path(root, output_trace_paths)
stopifnot(all(file.exists(output_trace_absolute)))
output_trace <- tibble(
  relative_path = output_trace_paths,
  role = output_trace_roles,
  object_type = if_else(dir.exists(output_trace_absolute), "directory", "file"),
  sha256 = vapply(output_trace_absolute, function(path) {
    if (dir.exists(path)) {
      files <- sort(list.files(path, full.names = TRUE, recursive = TRUE))
      digest::digest(
        paste(vapply(files, artifact_sha256, character(1L)), collapse = ""),
        algo = "sha256",
        serialize = FALSE
      )
    } else {
      artifact_sha256(path)
    }
  }, character(1L)),
  bytes = vapply(output_trace_absolute, function(path) {
    if (dir.exists(path)) {
      sum(file.info(list.files(path, full.names = TRUE, recursive = TRUE))$size)
    } else {
      as.numeric(file.info(path)$size)
    }
  }, numeric(1L))
)
write_h06d_csv(output_trace, "H06_daily_preparation_output_trace.csv")

####
# Step 7: Create the primary fitted-sample figure and paired source data
####

sample_figure_source <- exact_samples |>
  filter(.data$run_id == "primary__near_eye__all_available") |>
  left_join(
    metric_registry |>
      select("metric_slot", "abbreviation"),
    by = "metric_slot",
    relationship = "many-to-one"
  ) |>
  transmute(
    .data$metric_slot,
    metric = .data$manuscript_name,
    .data$abbreviation,
    .data$predictor_order,
    predictor = recode(
      .data$predictor_id,
      work_free_day = "Work/free day",
      activity_status = "Daily activity",
      previous_sleep_duration_centered_h = "Previous-night sleep"
    ),
    .data$participant_days,
    .data$participants,
    .data$sites,
    .data$source_branch
  ) |>
  arrange(.data$metric_slot, .data$predictor_order)

stopifnot(
  nrow(sample_figure_source) == 45L,
  n_distinct(sample_figure_source$metric_slot) == 15L,
  all(sample_figure_source$sites == 9L)
)
write_h06d_csv(
  sample_figure_source,
  "H06_daily_preparation_primary_sample_figure.csv"
)

metric_levels <- rev(
  metric_registry$abbreviation[order(metric_registry$metric_slot)]
)
metric_display_labels <- c(
  "M10mean" = "M10 mean",
  "L10mean" = "L10 mean"
)
sample_plot <- ggplot(
  sample_figure_source |>
    mutate(abbreviation = factor(.data$abbreviation, levels = metric_levels)),
  aes(
    x = .data$participant_days,
    y = .data$abbreviation,
    colour = .data$predictor
  )
) +
  geom_point(
    position = position_dodge(width = 0.55),
    size = 2.4,
    alpha = 0.95
  ) +
  scale_colour_manual(values = c(
    "Work/free day" = "#0072B2",
    "Daily activity" = "#D55E00",
    "Previous-night sleep" = "#009E73"
  )) +
  scale_x_continuous(
    labels = scales::label_comma(),
    expand = expansion(mult = c(0.03, 0.08))
  ) +
  scale_y_discrete(labels = function(x) {
    ifelse(x %in% names(metric_display_labels), metric_display_labels[x], x)
  }) +
  labs(
    x = "Participant-days in the fitted primary near-eye sample",
    y = NULL,
    colour = "Predictor"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.major.y = element_line(colour = "#E5E5E5", linewidth = 0.35),
    panel.grid.minor = element_blank(),
    legend.position = "top",
    legend.justification = "left",
    plot.margin = margin(8, 18, 8, 8)
  )

sample_figure_stem <- file.path(
  figure_dir,
  "H06_daily_preparation_primary_sample_support"
)
ggsave(
  paste0(sample_figure_stem, ".png"),
  sample_plot,
  width = 170,
  height = 150,
  units = "mm",
  dpi = 300,
  scale = 1.5,
  bg = "white"
)
ggsave(
  paste0(sample_figure_stem, ".pdf"),
  sample_plot,
  width = 170,
  height = 150,
  units = "mm",
  scale = 1.5,
  bg = "white"
)
ggsave(
  paste0(sample_figure_stem, ".svg"),
  sample_plot,
  width = 170,
  height = 150,
  units = "mm",
  scale = 1.5,
  bg = "white"
)

figure_alt <- tibble(
  figure_id = "primary_sample_support",
  alt_text = paste(
    "Dot plot of the exact primary near-eye participant-day sample for each",
    "of 15 light-exposure metrics and the three predictors. Most outcomes",
    "use more than 700 days. The pre-sleep, first-light, last-light, and MDER",
    "samples are smaller, and every fitted sample contains nine sites."
  ),
  source_data_relative_path = paste0(
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_preparation_primary_sample_figure.csv"
  ),
  interval_scope = "No interval; exact fitted-sample counts"
)
write_h06d_csv(figure_alt, "H06_daily_preparation_figure_alt_text.csv")

message(
  "H06_daily preparation artifacts complete: ",
  nrow(exact_samples), " fitted sample records, ",
  nrow(metric_registry), " metrics, and ",
  nrow(input_provenance), " verified input pins"
)
