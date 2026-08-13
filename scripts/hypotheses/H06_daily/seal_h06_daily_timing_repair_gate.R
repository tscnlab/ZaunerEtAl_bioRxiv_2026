#!/usr/bin/env Rscript

# Seal the non-circular H06-D-G2P-TIMING-REPAIR author-gate manifest.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "readr", "tibble")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf(
      "Missing synchronized packages: %s",
      paste(missing_packages, collapse = ", ")
    ),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R"
))
h06d_tr_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Gate sealing requires R 4.6.1; found %s",
  as.character(getRversion())
)

pipeline_path <- file.path(
  root,
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_timing_repair_pipeline_manifest.csv"
)
figure_path <- file.path(
  root,
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_timing_repair_figure_manifest.csv"
)
pipeline <- readr::read_csv(pipeline_path, show_col_types = FALSE)
figures <- readr::read_csv(figure_path, show_col_types = FALSE)
h06d_tr_assert(
  all(h06d_tr_verify_manifest_rows(
    root,
    pipeline |>
      dplyr::transmute(
        input_id = paste0("pipeline_", dplyr::row_number()),
        relative_path = .data$relative_path,
        expected_sha256 = .data$sha256,
        role = .data$role
      )
  )$verification_status == "PASS"),
  "The timing-repair pipeline manifest does not verify"
)
h06d_tr_assert(
  all(h06d_tr_verify_manifest_rows(
    root,
    figures |>
      dplyr::transmute(
        input_id = paste0("figure_", dplyr::row_number()),
        relative_path = .data$relative_path,
        expected_sha256 = .data$sha256,
        role = .data$role
      )
  )$verification_status == "PASS"),
  "The timing-repair figure manifest does not verify"
)

direct_paths <- c(
  "audit/decisions/h06_daily_timing_repair_pilot_authorization.md",
  "audit/decisions/h06_daily_non_l10_pilot_gate.md",
  "audit/hypotheses/H06_daily/11_timing_repair_pilot.qmd",
  "audit/hypotheses/H06_daily/11_timing_repair_pilot.html",
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_timing_repair_pilot_transition.md"
  ),
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_timing_repair_pilot.R",
  paste0(
    "scripts/hypotheses/H06_daily/",
    "make_h06_daily_timing_repair_residual_plots.R"
  ),
  paste0(
    "scripts/hypotheses/H06_daily/",
    "seal_h06_daily_timing_repair_gate.R"
  ),
  paste0(
    "tests/hypotheses/H06_daily/",
    "test_h06_daily_timing_repair_pilot.R"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_timing_repair_pipeline_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_timing_repair_figure_manifest.csv"
  )
)
all_paths <- sort(unique(c(
  direct_paths,
  pipeline$relative_path,
  figures$relative_path
)))
manifest_relative_path <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_timing_repair_report_manifest.csv"
)
h06d_tr_assert(
  !(manifest_relative_path %in% all_paths),
  "The report manifest would be circular"
)

role_for_path <- function(path) {
  dplyr::case_when(
    grepl("audit/decisions", path, fixed = TRUE) ~
      "controlling or predecessor author decision",
    grepl("11_timing_repair_pilot", path, fixed = TRUE) ~
      "author-gate report source or rendered HTML",
    grepl("transition", path, fixed = TRUE) ~
      "author-gate transition",
    grepl("tests/", path, fixed = TRUE) ~
      "focused gate identity test",
    grepl("scripts/", path, fixed = TRUE) ~
      "executed scientific, display, or sealing code",
    grepl("manifest", path, fixed = TRUE) ~
      "non-circular provenance manifest",
    grepl("preservation", path, fixed = TRUE) ~
      "protected-file identity evidence",
    endsWith(path, ".png") ~ "residual diagnostic figure",
    grepl("source_data", path, fixed = TRUE) ~
      "paired residual-figure source data",
    grepl("models", path, fixed = TRUE) ~ "sealed model bundle",
    TRUE ~ "bounded timing-repair pilot artifact"
  )
}

manifest <- dplyr::bind_rows(lapply(all_paths, function(path) {
  h06d_tr_file_record(root, path, role_for_path(path))
})) |>
  dplyr::arrange(.data$relative_path)
h06d_tr_assert(
  !anyDuplicated(manifest$relative_path),
  "The timing-repair report manifest contains duplicate paths"
)
h06d_tr_assert(
  !(manifest_relative_path %in% manifest$relative_path),
  "The timing-repair report manifest contains itself"
)

h06d_tr_write_csv(
  manifest,
  file.path(root, manifest_relative_path)
)
message(sprintf(
  "Sealed %d non-circular H06-D-G2P-TIMING-REPAIR identities.",
  nrow(manifest)
))
