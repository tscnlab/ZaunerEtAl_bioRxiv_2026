#!/usr/bin/env Rscript

# Build the report-layer manifest after the corrected temporal reconciliation
# QMD, HTML, and no-refit verification source are final.

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
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("readr", quietly = TRUE),
  requireNamespace("tibble", quietly = TRUE)
)

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "build_h06_daily_temporal_h02_report_manifest.R"
)
paths <- c(
  "audit/hypotheses/H06_daily/03_temporal_h02_reconciliation.qmd",
  "audit/hypotheses/H06_daily/03_temporal_h02_reconciliation.html",
  paste0(
    "tests/hypotheses/H06_daily/",
    "test_h06_daily_temporal_h02_reconciliation.R"
  ),
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_temporal_h02_estimand_transition.md"
  ),
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_temporal_h02_production_transition.md"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_temporal_h02_production_gate_contract.csv"
  ),
  producer
)
roles <- c(
  "executed_source",
  "rendered_report",
  "no_refit_verification",
  "author_confirmed_estimand_transition",
  "author_approved_production_transition",
  "current_production_gate",
  "manifest_builder"
)
absolute_paths <- file.path(root, paths)
stopifnot(all(file.exists(absolute_paths)))
manifest <- tibble::tibble(
  relative_path = paths,
  size_bytes = unname(file.info(absolute_paths)$size),
  sha256 = vapply(
    absolute_paths,
    digest::digest,
    character(1),
    algo = "sha256",
    file = TRUE
  ),
  role = roles,
  producer = producer,
  r_version = as.character(getRversion())
)
output <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_temporal_h02_reconciliation_report_manifest.csv"
  )
)
readr::write_csv(manifest, output, na = "")
message("Wrote ", substring(output, nchar(root) + 2L))
