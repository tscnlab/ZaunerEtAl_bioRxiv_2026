#!/usr/bin/env Rscript

# Build the final report-layer manifest for the H02-aligned temporal production
# report after the QMD, HTML, focused test, and handoff are final.

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
  "build_h06_daily_temporal_h02_production_report_manifest.R"
)
paths <- c(
  "audit/hypotheses/H06_daily/04_temporal_h02_production.qmd",
  "audit/hypotheses/H06_daily/04_temporal_h02_production.html",
  "tests/hypotheses/H06_daily/test_h06_daily_temporal_h02_production.R",
  "audit/hypotheses/H06_daily/H06_daily_temporal_h02_production_transition.md",
  "audit/handoffs/H06_daily_worker_handoff.md",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_temporal_h02_figure_output_manifest.csv"
  ),
  producer
)
roles <- c(
  "executed production report source",
  "self-contained production report",
  "focused no-refit production verification",
  "author-approved pointwise production transition",
  "current worker handoff",
  "reader figure output manifest",
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
    "H06_daily_temporal_h02_production_report_manifest.csv"
  )
)
readr::write_csv(manifest, output, na = "")
message("Wrote ", substring(output, nchar(root) + 2L))
