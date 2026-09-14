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

evidence_dir <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_battery_order62_render"
)
acceptance_dir <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_battery_order62_acceptance"
)
manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_battery_order62_independent_acceptance_manifest.csv"
)

checks <- readr::read_csv(
  file.path(acceptance_dir, "acceptance_checks.csv"),
  show_col_types = FALSE
)
transition <- readr::read_csv(
  "audit/report_harmonization/report018_sensitivity_battery_order62_matrix_transition.csv",
  show_col_types = FALSE,
  col_types = cols(.default = col_character())
)
stopifnot(
  nrow(checks) == 16L,
  all(checks$pass),
  nrow(transition) == 7L,
  all(transition$pass == "TRUE"),
  sha256_file("audit/report_harmonization/coordination_matrix.csv") ==
    "01b3438ff097c7ea31486f20932ec3fed72e2eac0361732ada3bedc69408d960",
  sha256_file("_build/nathealth/notebooks/sensitivity_battery.html") ==
    "875f53995f5f47ec30b630a5cf47edfef1d0fe925034d3fab4944be8c6c6b4be"
)

paths <- c(
  "audit/report_harmonization/report018_sensitivity_battery_order62_independent_acceptance.md",
  "audit/report_harmonization/report018_sensitivity_battery_order62_matrix_transition.csv",
  "scripts/report_harmonization/check_report018_sensitivity_order62_acceptance.R",
  "scripts/report_harmonization/seal_report018_sensitivity_order62_acceptance.R",
  sort(list.files(evidence_dir, recursive = TRUE, full.names = TRUE)),
  sort(list.files(acceptance_dir, recursive = TRUE, full.names = TRUE)),
  "audit/report_harmonization/owner_orders/62_sensitivity_battery_target_render.md",
  "audit/report_harmonization/report018_sensitivity_order62_dispatch.md",
  "audit/report_harmonization/report018_sensitivity_order62_dispatch_manifest.csv",
  "audit/report_harmonization/report018_sensitivity_order62_dispatch_receipt.md",
  "audit/report_harmonization/report018_sensitivity_order62_dispatch_receipt_manifest.csv",
  "audit/report_harmonization/report018_sensitivity_order62_prerender_matrix_addendum.md",
  "audit/report_harmonization/report018_sensitivity_order62_prerender_matrix_addendum_manifest.csv",
  "audit/report_harmonization/report018_sensitivity_order62_no_rerender_classification.md",
  "audit/report_harmonization/report018_sensitivity_order62_no_rerender_classification_manifest.csv",
  "audit/report_harmonization/report018_sensitivity_order62_no_rerender_wrapper_recovery.md",
  "audit/report_harmonization/report018_sensitivity_order62_no_rerender_wrapper_recovery_manifest.csv",
  "audit/report_harmonization/report018_sensitivity_order62_link_target_import_recovery.md",
  "audit/report_harmonization/report018_sensitivity_order62_link_target_import_recovery_manifest.csv",
  "scripts/report_harmonization/check_report018_sensitivity_battery_preflight.R",
  "scripts/report_harmonization/check_report018_sensitivity_order62_prerender.R",
  "scripts/report_harmonization/capture_report018_sensitivity_order62_inventory.R",
  "scripts/report_harmonization/check_report018_sensitivity_order62_postrender.R",
  "scripts/report_harmonization/check_report018_sensitivity_order62_no_rerender.R",
  "scripts/report_harmonization/check_report018_sensitivity_order62_no_rerender_final.R",
  "scripts/report_harmonization/check_report018_sensitivity_order62_completion.R",
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "audit/decisions/manuscript_prepared_data_sensitivity.md",
  "_build/nathealth/audit/decisions/manuscript_prepared_data_sensitivity.md",
  "_quarto-nathealth.yml",
  "renv.lock",
  "audit/report_harmonization/phase4_corpus_manifest.csv",
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
exists <- file.exists(sealed$path) & !dir.exists(sealed$path)
live_sha256 <- rep(NA_character_, nrow(sealed))
live_bytes <- rep(NA_real_, nrow(sealed))
live_sha256[exists] <- vapply(sealed$path[exists], sha256_file, character(1))
live_bytes[exists] <- unname(as.numeric(file.info(sealed$path[exists])$size))
stopifnot(
  !manifest_path %in% sealed$path,
  !anyDuplicated(sealed$path),
  all(exists),
  all(live_sha256 == sealed$sha256),
  all(live_bytes == as.numeric(sealed$bytes))
)

cat(sprintf(
  "REPORT018_SENSITIVITY_ORDER62_SEAL=PASS manifest=%d/%d R=%s\n",
  nrow(sealed),
  nrow(sealed),
  as.character(getRversion())
))
