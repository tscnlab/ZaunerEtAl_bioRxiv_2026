#!/usr/bin/env Rscript

# Build the report-layer manifest for the bounded daily AR-repair pilot.

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
  "build_h06_daily_daily_ar_repair_pilot_report_manifest.R"
)
paths <- c(
  "audit/hypotheses/H06_daily/06_daily_ar_repair_pilot.qmd",
  "audit/hypotheses/H06_daily/06_daily_ar_repair_pilot.html",
  "tests/hypotheses/H06_daily/test_h06_daily_daily_ar_repair_pilot.R",
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_daily_ar_repair_pilot_transition.md"
  ),
  "audit/handoffs/H06_daily_shared_change_request.md",
  "audit/handoffs/H06_daily_worker_handoff.md",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_stage2_daily_ar_repair_pilot_output_manifest.csv"
  ),
  producer
)
roles <- c(
  "executed daily AR-repair pilot source",
  "self-contained daily AR-repair pilot report",
  "focused no-refit repair-pilot verification",
  "H06-D-G2P-AR stop-gate record",
  "L10 upstream numerical-zero classification request",
  "current worker handoff",
  "scientific output manifest",
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
    "H06_daily_daily_ar_repair_pilot_report_manifest.csv"
  )
)
readr::write_csv(manifest, output, na = "")
message("Wrote ", substring(output, nchar(root) + 2L))
