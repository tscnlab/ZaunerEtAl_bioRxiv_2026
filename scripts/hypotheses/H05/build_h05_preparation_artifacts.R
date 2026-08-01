#!/usr/bin/env Rscript

# Build lightweight descriptive source data for the H05 analysis-preparation
# companion from frozen H05 inputs and model frames. This script does not fit,
# diagnose, compare, predict from, or simulate a model.

suppressPackageStartupMessages({
  library(dplyr)
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
    paste0(
      "The H05 preparation artifacts require R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H05/",
  "build_h05_preparation_artifacts.R"
)
output_dir <- file.path(root, "artifacts/11_source_data/H05")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

read_h05_csv <- function(relative_path) {
  readr::read_csv(file.path(root, relative_path), show_col_types = FALSE)
}

write_h05_csv <- function(data, filename) {
  write_csv_artifact(
    data,
    file.path(output_dir, filename),
    producer = producer
  )
}

metric_registry <- read_h05_csv(
  "artifacts/06_model_data/H05/H05_metric_registry.csv"
)
factor_registry <- read_h05_csv(
  "artifacts/06_model_data/H05/H05_factor_registry.csv"
)
run_registry <- read_h05_csv(
  "artifacts/06_model_data/H05/H05_run_registry.csv"
)
site_registry <- read_h05_csv("config/site_display_registry.csv")

near_samples <- read_h05_csv(
  "artifacts/11_source_data/H05/H05_reader_near_eye_samples.csv"
) |>
  mutate(
    placement = "glasses",
    placement_label = "Near eye"
  )
chest_samples <- read_h05_csv(
  "artifacts/11_source_data/H05/H05_reader_chest_samples.csv"
) |>
  mutate(
    placement = "chest",
    placement_label = "Chest"
  )

sample_support <- bind_rows(near_samples, chest_samples) |>
  select(
    "metric_order", "metric_id", "manuscript_name", "analysis_unit",
    "placement", "placement_label", "observations", "participants",
    "participant_days", "represented_days", "sites"
  ) |>
  arrange(.data$metric_order, .data$placement)

stopifnot(
  nrow(sample_support) == 34L,
  n_distinct(sample_support$metric_id) == 17L,
  all(sample_support$observations > 0L),
  all(sample_support$participants > 0L),
  all(sample_support$represented_days > 0L)
)
write_h05_csv(sample_support, "H05_preparation_sample_support.csv")

leba <- readRDS(
  file.path(root, "artifacts/06_model_data/normalized_inputs/leba.rds")
)
factor_ids <- factor_registry$factor_id
stopifnot(
  nrow(leba) == 184L,
  all(factor_ids %in% names(leba)),
  !anyDuplicated(leba[c("site", "Id")]),
  all(stats::complete.cases(leba[factor_ids]))
)

leba_distribution <- leba |>
  select("site", "Id", all_of(factor_ids)) |>
  pivot_longer(
    cols = all_of(factor_ids),
    names_to = "factor_id",
    values_to = "score"
  ) |>
  left_join(
    factor_registry |>
      select(
        "factor_order", "factor_id", "factor_label",
        "possible_min", "possible_max"
      ),
    by = "factor_id",
    relationship = "many-to-one"
  ) |>
  count(
    .data$factor_order,
    .data$factor_id,
    .data$factor_label,
    .data$possible_min,
    .data$possible_max,
    .data$score,
    name = "participants"
  ) |>
  arrange(.data$factor_order, .data$score)

stopifnot(
  all(
    leba_distribution |>
      group_by(.data$factor_id) |>
      summarise(n = sum(.data$participants), .groups = "drop") |>
      pull(.data$n) == 184L
  )
)
write_h05_csv(
  leba_distribution,
  "H05_preparation_leba_score_distribution.csv"
)

run_labels <- tibble::tribble(
  ~run_id, ~run_label, ~run_order,
  "main__glasses__all_available",
  "Primary near-eye dataset", 1L,
  "main__chest__all_available",
  "Complementary chest dataset", 2L,
  "main__glasses__paired_common_sample",
  "Paired/common near-eye sensitivity", 3L,
  "main__chest__paired_common_sample",
  "Paired/common chest sensitivity", 4L,
  "manuscript_prepared_data__glasses__all_available",
  "Gap-timing-unaware near-eye sensitivity", 5L,
  "manuscript_prepared_data__chest__all_available",
  "Gap-timing-unaware chest supporting analysis", 6L,
  "manuscript_prepared_data__glasses__paired_common_sample",
  "Gap-timing-unaware paired/common near-eye supporting analysis", 7L,
  "manuscript_prepared_data__chest__paired_common_sample",
  "Gap-timing-unaware paired/common chest supporting analysis", 8L
)
stopifnot(setequal(run_registry$run_id, run_labels$run_id))

model_frame_archive <- readRDS(
  file.path(root, "artifacts/06_model_data/H05/H05_model_frames.rds")
)
model_frames <- model_frame_archive$model_frames
stopifnot(
  identical(model_frame_archive$hypothesis_id, "H05"),
  length(model_frames) == 136L
)

site_rows <- lapply(names(model_frames), function(frame_key) {
  key_parts <- strsplit(frame_key, "::", fixed = TRUE)[[1L]]
  stopifnot(length(key_parts) == 2L)
  run_id <- key_parts[[1L]]
  metric_id <- key_parts[[2L]]
  frame <- model_frames[[frame_key]]
  metric <- metric_registry |>
    filter(.data$metric_id == .env$metric_id)
  stopifnot(nrow(metric) == 1L)

  frame |>
    mutate(site = as.character(.data$site)) |>
    group_by(.data$site) |>
    summarise(
      observations = n(),
      participants = n_distinct(.data$participant_key),
      participant_days = if (metric$analysis_unit[[1L]] == "participant_day") {
        n()
      } else {
        NA_integer_
      },
      represented_days = if (
        metric$analysis_unit[[1L]] == "participant_day"
      ) {
        n()
      } else {
        sum(.data$participant_days_contributing, na.rm = TRUE)
      },
      .groups = "drop"
    ) |>
    mutate(
      run_id = run_id,
      metric_id = metric_id,
      .before = 1L
    )
})

site_support <- bind_rows(site_rows) |>
  left_join(
    run_labels,
    by = "run_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    metric_registry |>
      select(
        "metric_order", "metric_id", "manuscript_name", "analysis_unit"
      ),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    site_registry |>
      select("site", "display_order", "display_name", "color_hex"),
    by = "site",
    relationship = "many-to-one"
  ) |>
  arrange(.data$run_order, .data$metric_order, .data$display_order) |>
  select(
    "run_order", "run_id", "run_label", "metric_order", "metric_id",
    "manuscript_name", "analysis_unit", "display_order", "site",
    site_name = "display_name", site_color = "color_hex", "observations",
    "participants", "participant_days", "represented_days"
  )

stopifnot(
  !anyNA(site_support$run_label),
  !anyNA(site_support$site_name),
  all(site_support$observations > 0L),
  all(site_support$participants > 0L),
  all(site_support$represented_days > 0L)
)
write_h05_csv(site_support, "H05_preparation_site_support.csv")

site_support_summary <- site_support |>
  filter(
    .data$run_id %in% c(
      "main__glasses__all_available",
      "main__chest__all_available"
    )
  ) |>
  group_by(
    .data$run_order,
    .data$run_label,
    .data$display_order,
    .data$site,
    .data$site_name,
    .data$site_color
  ) |>
  summarise(
    metric_frames = n_distinct(.data$metric_id),
    participants_min = min(.data$participants),
    participants_max = max(.data$participants),
    represented_days_min = min(.data$represented_days),
    represented_days_max = max(.data$represented_days),
    .groups = "drop"
  ) |>
  arrange(.data$run_order, .data$display_order)

stopifnot(
  nrow(site_support_summary) == 17L,
  all(site_support_summary$metric_frames == 17L),
  all(site_support_summary$participants_min > 0L),
  all(site_support_summary$represented_days_min > 0L)
)
write_h05_csv(
  site_support_summary,
  "H05_preparation_site_support_summary.csv"
)

message(
  "Recorded H05 preparation source data: ",
  nrow(sample_support), " placement-metric rows, ",
  nrow(leba_distribution), " questionnaire-score rows, and ",
  nrow(site_support), " site-by-model rows"
)
