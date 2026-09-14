#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

owner_dir <- paste0(
  "audit/hypotheses/H11/",
  "report018_order61a_no_rerender_completion"
)
replay_dir <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order61a_result_companion_acceptance"
)
manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order61a_result_companion_independent_acceptance_manifest.csv"
)

paths <- c(
  paste0(
    "audit/report_harmonization/",
    "report018_h11_order61a_result_companion_independent_acceptance.md"
  ),
  "scripts/report_harmonization/check_report018_h11_order61a_result_companion_acceptance.R",
  "scripts/report_harmonization/seal_report018_h11_order61a_acceptance.R",
  sort(list.files(replay_dir, full.names = TRUE)),
  file.path(owner_dir, "order61a_fail_closed_stop.md"),
  file.path(owner_dir, "order61a_fail_closed_non_circular_manifest.csv"),
  file.path(owner_dir, "preparation_test_execution.txt"),
  file.path(owner_dir, "static_acceptance_checks.csv"),
  file.path(owner_dir, "loopback_visual_qa.md"),
  file.path(owner_dir, "loopback_server_lifecycle.md"),
  file.path(owner_dir, "screenshot_representation_audit.csv"),
  "tests/hypotheses/H11/test_h11_preparation_report.R",
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  "notebooks/hypotheses/H11.qmd",
  "_build/nathealth/notebooks/hypotheses/H11.html",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html",
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "_quarto-nathealth.yml",
  "renv.lock",
  "audit/report_harmonization/coordination_matrix.csv"
)
paths <- unique(paths)
stopifnot(
  !manifest_path %in% paths,
  !anyDuplicated(paths),
  all(file.exists(paths)),
  !any(dir.exists(paths))
)

manifest <- data.frame(
  path = paths,
  sha256 = vapply(paths, sha256_file, character(1)),
  bytes = unname(as.numeric(file.info(paths)$size)),
  stringsAsFactors = FALSE
)
readr::write_csv(manifest, manifest_path)

sealed <- readr::read_csv(manifest_path, show_col_types = FALSE)
live_sha256 <- vapply(sealed$path, sha256_file, character(1))
live_bytes <- unname(as.numeric(file.info(sealed$path)$size))
stopifnot(
  !manifest_path %in% sealed$path,
  !anyDuplicated(sealed$path),
  all(live_sha256 == sealed$sha256),
  all(live_bytes == as.numeric(sealed$bytes))
)

cat(sprintf(
  "REPORT018_H11_ORDER61A_SEAL=PASS manifest=%d/%d R=%s\n",
  nrow(sealed),
  nrow(sealed),
  as.character(getRversion())
))
