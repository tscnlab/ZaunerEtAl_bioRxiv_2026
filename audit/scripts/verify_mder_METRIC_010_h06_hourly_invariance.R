# Verify that the METRIC-010 Preparation 06 repin did not change H06's
# prepared hourly analysis frames. No model is fit or refit.

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H06 hourly invariance check requires R 4.6.1", call. = FALSE)
}

source("scripts/pipeline/paths_io.R")
source("scripts/hypotheses/H06/h06_contract.R")
source("scripts/hypotheses/H06/h06_modeling.R")

site_levels <- readr::read_csv(
  file.path(root, "config", "site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order) |>
  dplyr::pull(.data$site)

near_main <- readRDS(file.path(
  root,
  "artifacts/06_model_data/base/metrics_glasses_one_hour_context.rds"
))
chest_main <- readRDS(file.path(
  root,
  "artifacts/06_model_data/base/metrics_chest_one_hour_context.rds"
))
gap_hour <- readRDS(file.path(
  root,
  paste0(
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
    "one_hour_data.rds"
  )
))
exercise_raw <- readRDS(file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/exercisediary.rds"
))
sleep_raw <- readRDS(file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds"
))
temporal_raw <- readr::read_csv(
  file.path(
    root,
    "artifacts/06_model_data/temporal_provenance/wall_outcome_links.csv"
  ),
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE
)

rebuilt <- h06_build_run_frames(
  near_main = near_main,
  chest_main = chest_main,
  gap_hour = gap_hour,
  exercise_raw = exercise_raw,
  sleep_raw = sleep_raw,
  temporal_raw = temporal_raw,
  site_levels = site_levels
)$runs

comparison <- dplyr::bind_rows(lapply(names(rebuilt), function(run_id) {
  stored_path <- file.path(
    root,
    "artifacts/06_model_data/H06",
    paste0(run_id, "__frame.rds")
  )
  if (!file.exists(stored_path)) {
    stop("Missing frozen H06 frame: ", stored_path, call. = FALSE)
  }
  stored <- readRDS(stored_path)
  same <- isTRUE(all.equal(
    rebuilt[[run_id]],
    stored,
    tolerance = 0,
    check.attributes = TRUE
  ))
  tibble::tibble(
    run_id = run_id,
    rows_rebuilt = nrow(rebuilt[[run_id]]),
    rows_frozen = nrow(stored),
    columns_rebuilt = ncol(rebuilt[[run_id]]),
    columns_frozen = ncol(stored),
    exact_frame_match = same,
    frozen_frame_sha256 = artifact_sha256(stored_path)
  )
}))

if (!all(comparison$exact_frame_match)) {
  stop(
    "At least one H06 analysis frame changed after the METRIC-010 repin",
    call. = FALSE
  )
}

output_root <- file.path(
  root,
  "artifacts/08_diagnostics/mder_METRIC-010/downstream_rebuild"
)
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
output_path <- file.path(output_root, "h06_hourly_frame_invariance.csv")
readr::write_csv(comparison, output_path, na = "")

message(
  "H06 hourly frame invariance PASS; SHA-256: ",
  artifact_sha256(output_path)
)
