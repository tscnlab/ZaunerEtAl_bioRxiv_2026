#!/usr/bin/env Rscript

# Seal non-circular H06-D-013 code, scientific-output, software, and final
# preservation manifests before the H06-D-G2 report is rendered.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(tibble)
})
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_contract.R"
))

h06d_prod_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06-D-013 artifact sealing requires R 4.6.1"
)
paths <- h06d_prod_checkpoint_paths(root)
state <- readRDS(paths$state)
h06d_prod_assert(
  identical(state$authorization, "H06-D-013") &&
    state$phase %in% c("POSTPROCESS_COMPLETE", "REPORT_READY") &&
    state$completed_cells == 468L && state$completed_refits == 66664L,
  "Postprocessed H06-D-013 production is required before sealing"
)
invisible(h06d_prod_verify_contract(root, h06d_prod_input_contract()))
invisible(h06d_prod_verify_contract(
  root,
  h06d_prod_main_h06_contract() |>
    dplyr::mutate(input_id = paste0("main_h06_", dplyr::row_number()), .before = 1L)
))

manifest_dir <- file.path(root, "artifacts/12_manifests/H06_daily")
diagnostic_dir <- file.path(root, "artifacts/08_diagnostics/H06_daily")
dir.create(manifest_dir, recursive = TRUE, showWarnings = FALSE)

figure_manifest_path <- file.path(
  manifest_dir,
  "H06_daily_non_l10_production_figure_manifest.csv"
)
h06d_prod_assert(
  file.exists(figure_manifest_path),
  "The paired reader-figure manifest is missing"
)
figure_manifest <- readr::read_csv(figure_manifest_path, show_col_types = FALSE)
figure_paths <- file.path(root, figure_manifest$relative_path)
h06d_prod_assert(
  nrow(figure_manifest) == 4L && all(file.exists(figure_paths)) &&
    identical(
      unname(vapply(figure_paths, h06d_prod_sha256, character(1))),
      figure_manifest$sha256
    ),
  "The reader-figure manifest failed verification"
)

code_paths <- c(
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_modeling.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_non_l10_production_base.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_non_l10_production_influence.R",
  "scripts/hypotheses/H06_daily/continue_h06_daily_non_l10_production_influence.R",
  "scripts/hypotheses/H06_daily/repair_h06_daily_non_l10_influence_index_hashes.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_non_l10_production_sensitivities.R",
  "scripts/hypotheses/H06_daily/postprocess_h06_daily_non_l10_production.R",
  "scripts/hypotheses/H06_daily/make_h06_daily_non_l10_production_figures.R",
  "scripts/hypotheses/H06_daily/seal_h06_daily_non_l10_production_artifacts.R",
  "scripts/hypotheses/H06_daily/finalize_h06_daily_non_l10_production_report.R",
  "tests/hypotheses/H06_daily/test_h06_daily_non_l10_production.R",
  "audit/hypotheses/H06_daily/H06_daily_non_l10_production_runtime_continuation.md",
  "audit/hypotheses/H06_daily/12_stage2_production.qmd"
)
code_roles <- c(
  "approved non-L10 registry and shared pilot contract",
  "current-source frame construction",
  "shared mixed-model pilot helpers",
  "accepted timing-route contract",
  "participant-cluster HC3 and timing sensitivity helpers",
  "H06-D-013 production and preservation contract",
  "H06-D-013 per-cell model and deletion helpers",
  "468-cell base runner",
  "66,664-refit checkpointed influence runner",
  "runtime-only checkpoint continuation and health-check controller",
  "no-refit influence-index hash-field provenance repair",
  "bounded family and support sensitivity runner",
  "no-refit production aggregation and multiplicity",
  "reader-facing pointwise-interval figure generator",
  "non-circular production artifact sealer",
  "post-render report and protected-identity finalizer",
  "focused H06-D-G2 no-refit verifier",
  "author runtime-continuation scope record",
  "Stage 2 author-gate source"
)
h06d_prod_assert(
  length(code_paths) == length(code_roles) && !anyDuplicated(code_paths) &&
    all(file.exists(file.path(root, code_paths))),
  "The production code inventory is incomplete"
)
code_manifest <- dplyr::bind_rows(lapply(seq_along(code_paths), function(index) {
  h06d_prod_file_record(root, code_paths[[index]], code_roles[[index]])
})) |>
  dplyr::mutate(
    authorization = "H06-D-013",
    gate = "H06-D-G2",
    r_version = as.character(getRversion())
  )
h06d_prod_write_csv(
  code_manifest,
  file.path(
    manifest_dir,
    "H06_daily_non_l10_production_code_manifest.csv"
  )
)

software_packages <- c(
  "R", "digest", "dplyr", "tidyr", "tibble", "readr", "lme4",
  "glmmTMB", "performance", "emmeans", "sandwich", "ggplot2",
  "melidosData", "LightLogR", "gt", "knitr"
)
versions <- c(
  as.character(getRversion()),
  vapply(
    software_packages[-1L],
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
)
quarto_version <- tryCatch(
  trimws(system2("quarto", "--version", stdout = TRUE, stderr = TRUE)[[1L]]),
  error = function(condition) NA_character_
)
software_manifest <- tibble::tibble(
  item = c(software_packages, "Quarto CLI"),
  version = c(versions, quarto_version),
  role = c(
    "authoritative scientific computation",
    rep("synchronized project library", length(software_packages) - 1L),
    "narrow HTML report render"
  ),
  authorization = "H06-D-013",
  gate = "H06-D-G2"
)
h06d_prod_write_csv(
  software_manifest,
  file.path(
    manifest_dir,
    "H06_daily_non_l10_production_software_manifest.csv"
  )
)

# REPORT_READY is the terminal analytical state. Later rendering and report
# sealing must not rewrite this state object.
state <- utils::modifyList(
  state,
  list(
    phase = "REPORT_READY",
    code_manifest_entries = nrow(code_manifest),
    software_manifest_entries = nrow(software_manifest),
    updated = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )
)
h06d_prod_write_rds(state, paths$state)

preservation_baseline <- readr::read_csv(
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_baseline.csv"
  ),
  show_col_types = FALSE
)
preservation_final <- h06d_prod_recheck_preservation(
  root,
  preservation_baseline,
  "final_pre_report"
)
h06d_prod_write_csv(
  preservation_final,
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_final.csv"
  )
)

artifact_roots <- file.path(
  root,
  "artifacts",
  c(
    "06_model_data/H06_daily", "07_models/H06_daily",
    "08_diagnostics/H06_daily", "09_tables/H06_daily",
    "10_figures/H06_daily", "11_source_data/H06_daily"
  )
)
scientific_paths <- unlist(lapply(artifact_roots, function(directory) {
  if (!dir.exists(directory)) return(character())
  list.files(directory, recursive = TRUE, full.names = TRUE, all.files = TRUE)
}), use.names = FALSE)
scientific_paths <- scientific_paths[
  file.exists(scientific_paths) & !dir.exists(scientific_paths) &
    grepl(
      "h06_daily_non_l10_production",
      tolower(scientific_paths),
      fixed = TRUE
    )
]
scientific_paths <- sort(unique(normalizePath(
  scientific_paths,
  winslash = "/",
  mustWork = TRUE
)))
h06d_prod_assert(
  length(scientific_paths) >= 950L,
  "The scientific-output inventory is unexpectedly small (%d files)",
  length(scientific_paths)
)
output_manifest <- dplyr::bind_rows(lapply(scientific_paths, function(path) {
  role <- dplyr::case_when(
    grepl("production_cells/", path, fixed = TRUE) ~ "sealed base-cell model object",
    grepl("production_influence_cells/", path, fixed = TRUE) ~
      "sealed influence-cell checkpoint",
    grepl("10_figures", path, fixed = TRUE) ~ "reader-facing figure",
    grepl("11_source_data", path, fixed = TRUE) ~ "figure source data",
    grepl("09_tables", path, fixed = TRUE) ~ "production result table",
    grepl("08_diagnostics", path, fixed = TRUE) ~ "production diagnostic evidence",
    grepl("06_model_data", path, fixed = TRUE) ~ "sealed frame or task contract",
    TRUE ~ "production scientific artifact"
  )
  h06d_prod_file_record(root, path, role)
})) |>
  dplyr::mutate(
    authorization = "H06-D-013",
    gate = "H06-D-G2",
    r_version = as.character(getRversion())
  )
h06d_prod_assert(
  !anyDuplicated(output_manifest$relative_path) &&
    !any(grepl("production_output_manifest", output_manifest$relative_path)),
  "The production output manifest is circular or duplicated"
)
h06d_prod_write_csv(
  output_manifest,
  file.path(
    manifest_dir,
    "H06_daily_non_l10_production_output_manifest.csv"
  )
)

message(sprintf(
  paste0(
    "H06-D-013 artifacts sealed: %d code, %d scientific-output, %d software, ",
    "%d figure, and %d protected-history identities."
  ),
  nrow(code_manifest),
  nrow(output_manifest),
  nrow(software_manifest),
  nrow(figure_manifest),
  nrow(preservation_final)
))
