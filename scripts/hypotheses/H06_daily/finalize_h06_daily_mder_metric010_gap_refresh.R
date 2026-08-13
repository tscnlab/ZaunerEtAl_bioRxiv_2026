#!/usr/bin/env Rscript

# Finalize provenance for the bounded METRIC-010 gap-branch refresh.
# This script does not fit, refit, predict, resample, or alter shared inputs.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

required_packages <- c("digest", "dplyr", "readr", "tibble")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R"
))

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "finalize_h06_daily_mder_metric010_gap_refresh.R"
)
manifest_root <- file.path(root, "artifacts/12_manifests/H06_daily")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H06_daily")
dir.create(manifest_root, recursive = TRUE, showWarnings = FALSE)

production_input_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_mder_metric010_production_input_manifest.csv"
)
production_output_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_mder_metric010_production_output_manifest.csv"
)
production_input <- readr::read_csv(
  file.path(root, production_input_relative),
  show_col_types = FALSE
)
production_output <- readr::read_csv(
  file.path(root, production_output_relative),
  show_col_types = FALSE
)

frozen_prefix <- "pre-refresh frozen production input: "
frozen_rows <- production_input |>
  dplyr::filter(startsWith(.data$role, .env$frozen_prefix))
captured_manifest <- production_input |>
  dplyr::filter(.data$role == "pre-refresh production output manifest")
h06d_m10_assert(
  nrow(frozen_rows) == 14L && nrow(captured_manifest) == 1L,
  "The pre-refresh METRIC-010 production manifest cannot be reconstructed"
)

pre_refresh_snapshot <- frozen_rows |>
  dplyr::transmute(
    relative_path = .data$relative_path,
    sha256 = .data$sha256,
    bytes = .data$bytes,
    role = substring(.data$role, nchar(.env$frozen_prefix) + 1L),
    producer = .data$producer,
    r_version = .data$r_version
  )
snapshot_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_mder_metric010_pre_gap_refresh_output_manifest.csv"
)
readr::write_csv(
  pre_refresh_snapshot,
  file.path(root, snapshot_relative),
  na = ""
)
h06d_m10_assert(
  h06d_m10_sha256(file.path(root, snapshot_relative)) ==
    captured_manifest$sha256[[1L]],
  "The reconstructed pre-refresh output manifest is not byte-identical"
)

frame_comparison <- readr::read_csv(
  file.path(
    diagnostic_root,
    "H06_daily_mder_metric010_gap_refresh_frame_comparison.csv"
  ),
  show_col_types = FALSE
)
preservation <- readr::read_csv(
  file.path(
    diagnostic_root,
    "H06_daily_mder_metric010_gap_refresh_preservation.csv"
  ),
  show_col_types = FALSE
)
support <- readr::read_csv(
  file.path(
    diagnostic_root,
    "H06_daily_mder_metric010_support_summary.csv"
  ),
  show_col_types = FALSE
)
runtime <- readr::read_csv(
  file.path(
    diagnostic_root,
    "H06_daily_mder_metric010_production_runtime.csv"
  ),
  show_col_types = FALSE
)
bh <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/09_tables/H06_daily/",
      "H06_daily_mder_metric010_bh_slot_families.csv"
    )
  ),
  show_col_types = FALSE
)

h06d_m10_assert(
  nrow(frame_comparison) == 36L &&
    sum(!frame_comparison$object_identical) == 24L &&
    all(preservation$preserved) &&
    all(is.na(bh$bh_adjusted_p_value)) &&
    all(bh$family_status == "INCOMPLETE_1_OF_15_NO_BH_DECISION"),
  "The METRIC-010 gap-refresh completion contract failed"
)

availability <- function(dataset_id, placement_id, column) {
  support[[column]][
    support$dataset_id == dataset_id &
      support$placement_id == placement_id
  ][[1L]]
}
refresh_record <- tibble::tribble(
  ~domain, ~observed, ~verdict,
  "Execution scope",
  sprintf(
    "%d affected frames: %d gap frames and %d primary-gap common-sample frames",
    sum(!frame_comparison$object_identical),
    sum(
      frame_comparison$dataset_id == "gap_timing_unaware" &
        !frame_comparison$object_identical
    ),
    sum(
      frame_comparison$dataset_id == "primary" &
        frame_comparison$sample_role == "dataset_common" &
        !frame_comparison$object_identical
    )
  ),
  "PASS",
  "Frozen primary routes",
  sprintf(
    "%d all-available or placement-paired primary frames unchanged",
    sum(
      frame_comparison$dataset_id == "primary" &
        frame_comparison$sample_role != "dataset_common" &
        frame_comparison$object_identical
    )
  ),
  "PASS",
  "Frozen production results",
  sprintf("%d preservation domains passed", nrow(preservation)),
  "PASS",
  "Gap availability",
  sprintf(
    "Near eye %d/%d; chest %d/%d; zero finite nonpositive values",
    availability("gap_timing_unaware", "near_eye", "available_days"),
    availability("gap_timing_unaware", "near_eye", "base_days"),
    availability("gap_timing_unaware", "chest", "available_days"),
    availability("gap_timing_unaware", "chest", "base_days")
  ),
  "PASS",
  "Multiplicity",
  "MDER slot refreshed in each affected 15-slot family; 1/15 available",
  "INCOMPLETE_NO_BH_DECISION",
  "Refresh runtime",
  sprintf(
    "%.1f seconds; no bootstrap or resampling",
    runtime$gaussian_reml_seconds[
      runtime$run_id == "metric010_gap_refresh_wall_time"
    ][[1L]]
  ),
  "PASS",
  "Pre-refresh provenance",
  paste0(
    "Reconstructed output manifest SHA-256 ",
    h06d_m10_sha256(file.path(root, snapshot_relative))
  ),
  "PASS"
)
record_relative <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_mder_metric010_gap_refresh_provenance.csv"
)
readr::write_csv(refresh_record, file.path(root, record_relative), na = "")

manifest <- function(relative_paths, roles) {
  absolute <- file.path(root, relative_paths)
  tibble::tibble(
    relative_path = relative_paths,
    sha256 = vapply(absolute, h06d_m10_sha256, character(1)),
    bytes = unname(file.info(absolute)$size),
    role = roles,
    producer = producer,
    r_version = as.character(getRversion())
  )
}

input_relative <- c(
  production_input_relative,
  production_output_relative,
  "artifacts/12_manifests/H06_daily/H06_daily_mder_metric010_static_input_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_mder_metric010_static_output_manifest.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_gap_refresh_frame_comparison.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_gap_refresh_preservation.csv",
  "audit/reconciliation/mder_METRIC-010_gap_repair/gap_repair_evidence_manifest.csv"
)
input_manifest <- manifest(input_relative, c(
  "targeted production input manifest",
  "refreshed production output manifest",
  "current static input manifest",
  "current static output manifest",
  "frame-level refresh scope evidence",
  "frozen production preservation evidence",
  "independent upstream repair evidence"
))
code_relative <- c(
  producer,
  "scripts/hypotheses/H06_daily/run_h06_daily_mder_metric010_production.R",
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_modeling.R"
)
code_manifest <- manifest(code_relative, c(
  "gap-refresh provenance finalizer",
  "bounded production refresh runner",
  "METRIC-010 contract",
  "METRIC-010 data adapters",
  "METRIC-010 modeling helpers"
))
output_manifest <- manifest(
  c(snapshot_relative, record_relative),
  c(
    "byte-identical pre-refresh production output manifest",
    "gap-refresh completion record"
  )
)
software_manifest <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)

readr::write_csv(
  input_manifest,
  file.path(
    manifest_root,
    "H06_daily_mder_metric010_gap_refresh_input_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  code_manifest,
  file.path(
    manifest_root,
    "H06_daily_mder_metric010_gap_refresh_code_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  output_manifest,
  file.path(
    manifest_root,
    "H06_daily_mder_metric010_gap_refresh_output_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  software_manifest,
  file.path(
    manifest_root,
    "H06_daily_mder_metric010_gap_refresh_software_manifest.csv"
  ),
  na = ""
)

message(
  "Finalized H06_daily METRIC-010 gap-refresh provenance without refitting"
)
