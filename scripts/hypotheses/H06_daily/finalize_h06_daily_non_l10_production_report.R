#!/usr/bin/env Rscript

# Final no-refit H06-D-G2 report sealing and protected-identity audit.

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
  "H06-D-G2 report sealing requires R 4.6.1"
)
state <- readRDS(file.path(
  root,
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_production_state.rds"
))
h06d_prod_assert(
  identical(state$authorization, "H06-D-013") &&
    identical(state$phase, "REPORT_READY") &&
    state$completed_refits == 66664L,
  "The sealed production state is not report-ready"
)

baseline <- readr::read_csv(file.path(
  root,
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_production_preservation_baseline.csv"
), show_col_types = FALSE)
at_gate <- h06d_prod_recheck_preservation(root, baseline, "H06-D-G2")
at_gate_path <- file.path(
  root,
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_production_preservation_at_gate.csv"
)
h06d_prod_write_csv(at_gate, at_gate_path)

manifest_relative <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_stage2_production_report_manifest.csv"
)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "finalize_h06_daily_non_l10_production_report.R"
)
report_paths <- c(
  "audit/decisions/h06_daily_non_l10_production_authorization.md",
  "audit/decisions/h06_daily_timing_repair_acceptance.md",
  "audit/decisions/h06_daily_non_l10_grid_reopening.md",
  "audit/decisions/h06_primary_selection_and_daily_complement.md",
  "audit/hypotheses/H06_daily/12_stage2_production.qmd",
  "audit/hypotheses/H06_daily/12_stage2_production.html",
  "audit/hypotheses/H06_daily/H06_daily_stage2_production_transition.md",
  "artifacts/12_manifests/H06_daily/H06_daily_non_l10_production_input_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_non_l10_production_main_h06_pins.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_non_l10_production_code_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_non_l10_production_output_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_non_l10_production_figure_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_non_l10_production_software_manifest.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_state.rds",
  "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_preservation_final.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_preservation_at_gate.csv",
  "artifacts/09_tables/H06_daily/H06_daily_non_l10_production_primary_results.csv",
  "artifacts/09_tables/H06_daily/H06_daily_non_l10_production_bh_families.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_diagnostic_assessment.csv",
  "tests/hypotheses/H06_daily/test_h06_daily_non_l10_production.R",
  producer
)
roles <- c(
  "controlling Stage 2 production authorization",
  "accepted timing-route qualifications",
  "complementary daily-grid reopening",
  "hourly-primary and daily-complement role selection",
  "Stage 2 author-gate source",
  "self-contained rendered Stage 2 author gate",
  "task transition and mandatory stop record",
  "sealed current-source and decision inputs",
  "frozen main-H06 identity pins",
  "sealed production code identities",
  "sealed scientific-output identities",
  "paired figure and source-data identities",
  "authoritative software identities",
  "terminal report-ready analytical state",
  "pre-render protected-history verification",
  "post-render H06-D-G2 protected-history verification",
  "primary near-eye estimates and pointwise intervals",
  "twelve complete named 15-slot BH families",
  "complete cell-level diagnostic verdicts",
  "focused H06-D-G2 verifier",
  "non-circular report finalizer"
)
h06d_prod_assert(
  length(report_paths) == length(roles) &&
    !manifest_relative %in% report_paths && !anyDuplicated(report_paths) &&
    all(file.exists(file.path(root, report_paths))),
  "The H06-D-G2 report inventory is incomplete or circular"
)
manifest <- dplyr::bind_rows(lapply(seq_along(report_paths), function(index) {
  h06d_prod_file_record(root, report_paths[[index]], roles[[index]])
})) |>
  dplyr::mutate(
    producer = .env$producer,
    authorization = "H06-D-013",
    gate = "H06-D-G2",
    r_version = as.character(getRversion())
  )
h06d_prod_write_csv(manifest, file.path(root, manifest_relative))

message(sprintf(
  paste0(
    "H06-D-G2 report sealed: %d non-circular identities and %d protected ",
    "historical identities byte-identical after render."
  ),
  nrow(manifest),
  nrow(at_gate)
))
