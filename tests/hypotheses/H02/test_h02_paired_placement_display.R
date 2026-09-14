# Validate the stored-output H02 near-eye/chest temporal comparison display.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

source_path <- file.path(
  root,
  "artifacts/11_source_data/H02/paired_placement_site_curves.csv"
)
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_paired_placement_display_manifest.csv"
)
result_qmd_path <- file.path(root, "notebooks/hypotheses/H02.qmd")
preparation_qmd_path <- file.path(
  root,
  "audit/hypotheses/H02/H02_analysis_preparation.qmd"
)
stopifnot(all(file.exists(c(
  source_path,
  manifest_path,
  result_qmd_path,
  preparation_qmd_path
))))

display <- readr::read_csv(source_path, show_col_types = FALSE)
stopifnot(
  nrow(display) == 768L,
  identical(unique(display$placement), c("Near eye", "Chest")),
  identical(sort(unique(display$paired_participants)), 112),
  identical(sort(unique(display$paired_participant_days)), 643),
  identical(sort(unique(display$paired_observations_30_minute)), 29786),
  identical(sort(unique(display$paired_sites)), 8),
  length(unique(display$site)) == 8L,
  all(table(display$placement) == 384L),
  all(display$pointwise_lower_eta <= display$eta),
  all(display$pointwise_upper_eta >= display$eta),
  all(display$pointwise_lower_melEDI_lx >= 0),
  all(display$pointwise_upper_melEDI_lx >= display$estimate_melEDI_lx)
)

curve_key <- c("site", "clock_bin", "time_hour")
near_key <- display |>
  dplyr::filter(.data$placement == "Near eye") |>
  dplyr::select(dplyr::all_of(curve_key))
chest_key <- display |>
  dplyr::filter(.data$placement == "Chest") |>
  dplyr::select(dplyr::all_of(curve_key))
stopifnot(identical(near_key, chest_key), !anyDuplicated(near_key))

expected_sites <- c(
  "Borås (SE)",
  "Delft (NL)",
  "Dortmund (DE)",
  "Munich (DE)",
  "Madrid (ES)",
  "Izmir (TR)",
  "San José (CR)",
  "Kumasi (GH)"
)
observed_sites <- display |>
  dplyr::filter(.data$placement == "Near eye") |>
  dplyr::distinct(.data$display_order, .data$display_name) |>
  dplyr::arrange(.data$display_order) |>
  dplyr::pull(.data$display_name)
stopifnot(identical(observed_sites, expected_sites))

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopifnot(
  nrow(manifest) == 6L,
  !anyDuplicated(manifest$path),
  all(manifest$status == "PASS"),
  all(manifest$paired_participants == 112L),
  all(manifest$paired_participant_days == 643L),
  all(manifest$paired_observations_30_minute == 29786L),
  all(manifest$paired_sites == 8L)
)
manifest_files <- file.path(root, manifest$path)
stopifnot(all(file.exists(manifest_files)))
actual_hashes <- unname(vapply(
  manifest_files,
  artifact_sha256,
  character(1)
))
stopifnot(identical(actual_hashes, unname(manifest$sha256)))

result_qmd <- paste(readLines(result_qmd_path, warn = FALSE), collapse = "\n")
preparation_qmd <- paste(
  readLines(preparation_qmd_path, warn = FALSE),
  collapse = "\n"
)
stopifnot(
  grepl("fig-h02-paired-placement-curves", result_qmd, fixed = TRUE),
  grepl("paired_placement_site_curves.csv", result_qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", result_qmd, fixed = TRUE),
  grepl("p_value_display.R", result_qmd, fixed = TRUE),
  grepl(
    "false-discovery-rate (FDR)-adjusted",
    result_qmd,
    fixed = TRUE
  ),
  grepl("FDR adjustment", result_qmd, fixed = TRUE),
  !grepl("\\bBH\\b", result_qmd, perl = TRUE),
  !grepl("H02-F1-site-pattern", result_qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", preparation_qmd, fixed = TRUE),
  grepl("p_value_display.R", preparation_qmd, fixed = TRUE)
)

message("All H02 paired-placement display tests passed")
