#!/usr/bin/env Rscript

# Build the final report-layer manifest for the bounded METRIC-010 amendment.

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
  "build_h06_daily_mder_metric010_report_manifest.R"
)
paths <- c(
  "audit/hypotheses/H06_daily/05_mder_metric010_amendment.qmd",
  "audit/hypotheses/H06_daily/05_mder_metric010_amendment.html",
  "tests/hypotheses/H06_daily/test_h06_daily_mder_metric010.R",
  "audit/hypotheses/H06_daily/H06_daily_mder_metric010_transition.md",
  "audit/hypotheses/H06_daily/H06_daily_mder_upstream_hold.md",
  "audit/handoffs/H06_daily_shared_change_request.md",
  "audit/handoffs/H06_daily_worker_handoff.md",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_mder_metric010_production_output_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_mder_metric010_pre_gap_refresh_output_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_mder_metric010_gap_refresh_output_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_mder_metric010_reader_output_manifest.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_mder_metric010_gap_refresh_provenance.csv"
  ),
  paste0(
    "scripts/hypotheses/H06_daily/",
    "finalize_h06_daily_mder_metric010_gap_refresh.R"
  ),
  producer
)
roles <- c(
  "executed MDER amendment source",
  "self-contained MDER amendment report",
  "focused no-refit MDER verification",
  "replacement METRIC-010 transition",
  "historical upstream hold and release record",
  "shared comparator provenance qualification",
  "current worker handoff",
  "current production output manifest",
  "byte-identical pre-refresh production output manifest",
  "bounded gap-refresh output manifest",
  "reader artifact output manifest",
  "bounded gap-refresh completion record",
  "gap-refresh provenance finalizer",
  "report manifest builder"
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
    "H06_daily_mder_metric010_report_manifest.csv"
  )
)
readr::write_csv(manifest, output, na = "")
message("Wrote ", substring(output, nchar(root) + 2L))
