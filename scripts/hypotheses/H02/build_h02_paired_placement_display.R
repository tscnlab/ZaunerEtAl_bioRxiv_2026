#!/usr/bin/env Rscript

# Build the matched near-eye/chest temporal display data from stored H02 fits.
# This script validates matched observations and does not fit or refit a model.

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
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))

if (getRversion() != "4.6.1") {
  h02_abort("H02 requires R 4.6.1; running %s", getRversion())
}

invisible(h02_validate_inputs(root))

paths <- pipeline_paths(root)
producer <- paste0(
  "scripts/hypotheses/H02/",
  "build_h02_paired_placement_display.R"
)
near_id <- "main__glasses__paired_common_sample"
chest_id <- "main__chest__paired_common_sample"

near_frame_path <- file.path(paths$model_data, "H02", paste0(near_id, ".rds"))
chest_frame_path <- file.path(
  paths$model_data,
  "H02",
  paste0(chest_id, ".rds")
)
prediction_path <- file.path(
  paths$source_data,
  "H02",
  "site_curve_predictions.csv"
)
sample_path <- file.path(paths$model_data, "H02", "sample_counts.csv")
registry_path <- file.path(root, "config", "site_display_registry.csv")
output_path <- file.path(
  paths$source_data,
  "H02",
  "paired_placement_site_curves.csv"
)
manifest_path <- file.path(
  paths$manifests,
  "H02",
  "H02_paired_placement_display_manifest.csv"
)

required_inputs <- c(
  near_frame_path,
  chest_frame_path,
  prediction_path,
  sample_path,
  registry_path
)
if (any(!file.exists(required_inputs))) {
  h02_abort(
    "Missing H02 paired-placement input(s): %s",
    paste(required_inputs[!file.exists(required_inputs)], collapse = ", ")
  )
}

near_frame <- readRDS(near_frame_path)
chest_frame <- readRDS(chest_frame_path)
observation_key <- c(
  "participant_key",
  "participant_day_key",
  "site",
  "clock_bin",
  "time_hour"
)
if (
  nrow(near_frame) != nrow(chest_frame) ||
    !identical(near_frame[observation_key], chest_frame[observation_key])
) {
  h02_abort("Near-eye and chest common-sample observation keys do not match")
}

sample_counts <- readr::read_csv(sample_path, show_col_types = FALSE)
paired_counts <- sample_counts |>
  dplyr::filter(
    .data$run_id %in% c(.env$near_id, .env$chest_id),
    .data$site == "ALL_SITES"
  ) |>
  dplyr::arrange(match(.data$run_id, c(.env$near_id, .env$chest_id)))
count_columns <- c(
  "participants",
  "participant_days",
  "observations_30_minute",
  "sites"
)
if (
  nrow(paired_counts) != 2L ||
    any(vapply(
      count_columns,
      function(column) {
        length(unique(paired_counts[[column]])) != 1L
      },
      logical(1)
    )) ||
    paired_counts$observations_30_minute[[1L]] != nrow(near_frame)
) {
  h02_abort("Recorded H02 paired-placement sample counts do not match")
}
if (!identical(
  unname(as.integer(paired_counts[1L, count_columns])),
  c(112L, 643L, 29786L, 8L)
)) {
  h02_abort("Unexpected H02 paired-placement sample identity")
}

site_registry <- readr::read_csv(registry_path, show_col_types = FALSE) |>
  dplyr::arrange(.data$display_order)
predictions <- readr::read_csv(prediction_path, show_col_types = FALSE) |>
  dplyr::filter(.data$run_id %in% c(.env$near_id, .env$chest_id))
curve_key <- c("site", "clock_bin", "time_hour")
near_keys <- predictions |>
  dplyr::filter(.data$run_id == .env$near_id) |>
  dplyr::select(dplyr::all_of(curve_key))
chest_keys <- predictions |>
  dplyr::filter(.data$run_id == .env$chest_id) |>
  dplyr::select(dplyr::all_of(curve_key))
if (
  nrow(near_keys) != 384L ||
    !identical(near_keys, chest_keys) ||
    anyDuplicated(near_keys)
) {
  h02_abort("Stored paired-placement site-curve grids do not match")
}

critical <- stats::qnorm(0.975)
paired_sample <- paired_counts[1L, count_columns]
display_data <- predictions |>
  dplyr::mutate(
    placement = dplyr::recode(
      .data$run_id,
      !!near_id := "Near eye",
      !!chest_id := "Chest"
    ),
    pointwise_lower_eta = .data$eta - critical * .data$standard_error,
    pointwise_upper_eta = .data$eta + critical * .data$standard_error,
    pointwise_lower_melEDI_lx = h02_inverse_transform(
      .data$pointwise_lower_eta
    ),
    pointwise_upper_melEDI_lx = h02_inverse_transform(
      .data$pointwise_upper_eta
    )
  ) |>
  dplyr::left_join(
    site_registry,
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    paired_participants = paired_sample$participants,
    paired_participant_days = paired_sample$participant_days,
    paired_observations_30_minute = paired_sample$observations_30_minute,
    paired_sites = paired_sample$sites,
    placement_order = match(.data$placement, c("Near eye", "Chest"))
  ) |>
  dplyr::arrange(
    .data$display_order,
    .data$clock_bin,
    .data$placement_order
  ) |>
  dplyr::select(
    "run_id",
    "placement",
    "site",
    "display_name",
    "display_order",
    "color_hex",
    "clock_bin",
    "time_hour",
    "eta",
    "standard_error",
    "pointwise_lower_eta",
    "pointwise_upper_eta",
    "estimate_melEDI_lx",
    "pointwise_lower_melEDI_lx",
    "pointwise_upper_melEDI_lx",
    "paired_participants",
    "paired_participant_days",
    "paired_observations_30_minute",
    "paired_sites"
  )

if (
  nrow(display_data) != 768L ||
    anyNA(display_data[c("display_name", "display_order", "color_hex")]) ||
    any(display_data$pointwise_lower_eta > display_data$eta) ||
    any(display_data$pointwise_upper_eta < display_data$eta)
) {
  h02_abort("Invalid H02 paired-placement display data")
}

invisible(write_csv_artifact(display_data, output_path, producer))

manifest_files <- c(required_inputs, output_path)
roles <- c(
  "input_near_eye_common_sample",
  "input_chest_common_sample",
  "input_stored_site_curves",
  "input_sample_counts",
  "input_display_registry",
  "output_paired_curve_source_data"
)
relative <- sub(
  paste0(
    "^",
    gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", root),
    "/"
  ),
  "",
  normalizePath(manifest_files, winslash = "/", mustWork = TRUE)
)
manifest <- tibble::tibble(
  role = roles,
  path = relative,
  sha256 = vapply(manifest_files, artifact_sha256, character(1)),
  bytes = unname(file.info(manifest_files)$size),
  paired_participants = paired_sample$participants,
  paired_participant_days = paired_sample$participant_days,
  paired_observations_30_minute = paired_sample$observations_30_minute,
  paired_sites = paired_sample$sites,
  producer = producer,
  r_version = as.character(getRversion()),
  status = "PASS"
)
invisible(write_csv_artifact(manifest, manifest_path, producer))

message(
  "Recorded ",
  nrow(display_data),
  " matched H02 placement-curve rows for ",
  paired_sample$observations_30_minute,
  " paired observations"
)
