#!/usr/bin/env Rscript

# Build lightweight descriptive source data for the H08 analysis-preparation
# companion from frozen H08 audit outputs. This script does not fit, diagnose,
# compare, predict from, resample, or simulate a model.

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
      "The H08 preparation artifacts require R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H08/",
  "build_h08_preparation_artifacts.R"
)
output_dir <- file.path(root, "artifacts/11_source_data/H08")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

read_h08_csv <- function(relative_path) {
  readr::read_csv(file.path(root, relative_path), show_col_types = FALSE)
}

write_h08_csv <- function(data, filename) {
  write_csv_artifact(
    data,
    file.path(output_dir, filename),
    producer = producer
  )
}

metric_registry <- read_h08_csv(
  "artifacts/06_model_data/H08/H08_metric_registry.csv"
)
run_registry <- read_h08_csv(
  "artifacts/06_model_data/H08/H08_run_registry.csv"
)
frame_index <- read_h08_csv(
  "artifacts/06_model_data/H08/H08_model_frame_index.csv"
)
frame_by_site <- read_h08_csv(
  "artifacts/06_model_data/H08/H08_model_frame_by_site.csv"
)
metric_missingness <- read_h08_csv(
  "artifacts/06_model_data/H08/H08_metric_missingness.csv"
)
score_rows <- read_h08_csv(
  "artifacts/08_diagnostics/H08/H08_vlsq_score_rows.csv"
)
site_registry <- read_h08_csv("config/site_display_registry.csv") |>
  arrange(.data$display_order)

near_id <- "main__glasses__all_available"
chest_id <- "main__chest__all_available"

sample_support <- frame_index |>
  filter(.data$run_id %in% c(near_id, chest_id)) |>
  transmute(
    metric_order = .data$metric_order,
    metric_id = .data$metric_id,
    manuscript_name = .data$manuscript_name,
    placement = .data$placement,
    placement_label = .data$placement_label,
    participants = .data$participants,
    participant_days = .data$participant_days,
    sites = .data$sites,
    metric_support_valid_hours = .data$metric_support_valid_hours,
    metric_support_expected_hours = .data$metric_support_expected_hours,
    metric_support_missing_rows = .data$metric_support_missing_rows,
    row_key_hash = .data$row_key_hash,
    model_frame_hash = .data$model_frame_hash
  ) |>
  arrange(.data$metric_order, .data$placement)

stopifnot(
  nrow(sample_support) == 18L,
  n_distinct(sample_support$metric_id) == 9L,
  range(
    sample_support$participants[sample_support$placement == "glasses"]
  ) ==
    c(139L, 141L),
  range(
    sample_support$participant_days[
      sample_support$placement == "glasses"
    ]
  ) ==
    c(655L, 816L),
  range(
    sample_support$participants[sample_support$placement == "chest"]
  ) ==
    c(153L, 154L),
  range(
    sample_support$participant_days[
      sample_support$placement == "chest"
    ]
  ) ==
    c(743L, 902L)
)
write_h08_csv(sample_support, "H08_preparation_sample_support.csv")

score_distribution <- score_rows |>
  count(.data$stored_VLSQ8, name = "participants") |>
  mutate(
    percentage = 100 * .data$participants / sum(.data$participants)
  ) |>
  arrange(.data$stored_VLSQ8)

stopifnot(
  sum(score_distribution$participants) == 184L,
  nrow(score_distribution) == 24L,
  min(score_distribution$stored_VLSQ8) == 13,
  max(score_distribution$stored_VLSQ8) == 39
)
write_h08_csv(
  score_distribution,
  "H08_preparation_vlsq_score_distribution.csv"
)

score_site_support <- score_rows |>
  group_by(.data$site) |>
  summarise(
    participants = n(),
    score_min = min(.data$stored_VLSQ8),
    score_max = max(.data$stored_VLSQ8),
    score_mean = mean(.data$stored_VLSQ8),
    score_sd = sd(.data$stored_VLSQ8),
    .groups = "drop"
  ) |>
  left_join(
    site_registry |>
      select(
        "site",
        "display_order",
        "display_name",
        "color_hex"
      ),
    by = "site",
    relationship = "many-to-one"
  ) |>
  arrange(.data$display_order) |>
  select(
    "display_order",
    "site",
    site_name = "display_name",
    site_color = "color_hex",
    "participants",
    "score_min",
    "score_max",
    "score_mean",
    "score_sd"
  )

stopifnot(
  nrow(score_site_support) == 9L,
  sum(score_site_support$participants) == 184L,
  !anyNA(score_site_support$site_name)
)
write_h08_csv(
  score_site_support,
  "H08_preparation_vlsq_site_support.csv"
)

site_support <- frame_by_site |>
  filter(.data$run_id %in% c(near_id, chest_id)) |>
  left_join(
    run_registry |>
      select(
        "run_id",
        "run_order",
        "placement",
        "placement_label"
      ),
    by = "run_id",
    relationship = "many-to-one"
  ) |>
  left_join(
    metric_registry |>
      select(
        "metric_order",
        "metric_id",
        "manuscript_name"
      ),
    by = c("metric_order", "metric_id"),
    relationship = "many-to-one",
    suffix = c("", ".registry")
  ) |>
  transmute(
    run_order = .data$run_order,
    run_id = .data$run_id,
    placement = .data$placement,
    placement_label = .data$placement_label,
    metric_order = .data$metric_order,
    metric_id = .data$metric_id,
    manuscript_name = .data$manuscript_name,
    display_order = .data$display_order,
    site = .data$site,
    site_name = .data$display_name,
    participants = .data$participants,
    participant_days = .data$participant_days,
    metric_support_valid_hours = .data$metric_support_valid_hours,
    metric_support_expected_hours = .data$metric_support_expected_hours
  ) |>
  arrange(.data$run_order, .data$metric_order, .data$display_order)

stopifnot(
  nrow(site_support) == 153L,
  !anyNA(site_support$site_name),
  all(site_support$participants > 0L),
  all(site_support$participant_days > 0L)
)
write_h08_csv(site_support, "H08_preparation_site_support.csv")

site_support_summary <- site_support |>
  group_by(
    .data$run_order,
    .data$placement,
    .data$placement_label,
    .data$display_order,
    .data$site,
    .data$site_name
  ) |>
  summarise(
    metric_frames = n_distinct(.data$metric_id),
    participants_min = min(.data$participants),
    participants_max = max(.data$participants),
    participant_days_min = min(.data$participant_days),
    participant_days_max = max(.data$participant_days),
    .groups = "drop"
  ) |>
  left_join(
    site_registry |>
      select("site", site_color = "color_hex"),
    by = "site",
    relationship = "many-to-one"
  ) |>
  arrange(.data$run_order, .data$display_order)

stopifnot(
  nrow(site_support_summary) == 17L,
  all(site_support_summary$metric_frames == 9L),
  all(site_support_summary$participants_min > 0L),
  all(site_support_summary$participant_days_min > 0L)
)
write_h08_csv(
  site_support_summary,
  "H08_preparation_site_support_summary.csv"
)

metric_availability <- metric_missingness |>
  left_join(
    metric_registry |>
      select(
        "metric_order",
        "metric_id",
        "manuscript_name"
      ),
    by = c("metric_order", "metric_id"),
    relationship = "many-to-one"
  ) |>
  mutate(
    preparation = recode(
      .data$data_scenario_id,
      main = "Primary dataset",
      gap_timing_unaware = "Gap-timing-unaware dataset"
    ),
    placement_label = recode(
      .data$placement,
      glasses = "Near eye",
      chest = "Chest"
    )
  ) |>
  select(
    "data_scenario_id",
    "preparation",
    "placement",
    "placement_label",
    "metric_order",
    "metric_id",
    "manuscript_name",
    "availability_reason",
    "participant_days"
  ) |>
  arrange(
    .data$data_scenario_id,
    .data$placement,
    .data$metric_order,
    .data$availability_reason
  )

stopifnot(
  nrow(metric_availability) == 56L,
  n_distinct(metric_availability$metric_id) == 9L,
  !anyNA(metric_availability$manuscript_name),
  all(metric_availability$participant_days >= 0L)
)
write_h08_csv(
  metric_availability,
  "H08_preparation_metric_availability.csv"
)

message(
  "Recorded H08 preparation source data: ",
  nrow(sample_support),
  " placement-metric rows, ",
  nrow(score_distribution),
  " VLSQ-8 score rows, ",
  nrow(site_support),
  " site-by-model rows, and ",
  nrow(metric_availability),
  " availability rows"
)
