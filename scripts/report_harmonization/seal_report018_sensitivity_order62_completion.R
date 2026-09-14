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

manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_order62_link_target_import_recovery_manifest.csv"
)
paths <- c(
  "audit/report_harmonization/report018_sensitivity_order62_link_target_import_recovery.md",
  "scripts/report_harmonization/check_report018_sensitivity_order62_completion.R",
  "scripts/report_harmonization/seal_report018_sensitivity_order62_completion.R",
  "scripts/report_harmonization/check_report018_sensitivity_order62_no_rerender_final.R",
  "audit/report_harmonization/report018_sensitivity_order62_no_rerender_wrapper_recovery_manifest.csv",
  "audit/report_harmonization/report018_sensitivity_battery_order62_render/postrender_checks_postrender.csv",
  "audit/report_harmonization/report018_sensitivity_battery_order62_render/build_inventory_prerender.csv",
  "audit/report_harmonization/report018_sensitivity_battery_order62_render/build_inventory_postrender.csv",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "notebooks/sensitivity_battery.qmd"
)
stopifnot(
  length(paths) == 10L,
  !anyDuplicated(paths),
  !manifest_path %in% paths,
  all(file.exists(paths)),
  !any(dir.exists(paths)),
  sha256_file(
    "scripts/report_harmonization/check_report018_sensitivity_order62_no_rerender_final.R"
  ) ==
    "9657996be5fcc3a6d7588339fd3094c26d63371b6f4c3af844ab367661e72961",
  sha256_file("_build/nathealth/notebooks/sensitivity_battery.html") ==
    "875f53995f5f47ec30b630a5cf47edfef1d0fe925034d3fab4944be8c6c6b4be"
)

manifest <- data.frame(
  path = paths,
  sha256 = vapply(paths, sha256_file, character(1)),
  bytes = unname(as.numeric(file.info(paths)$size)),
  stringsAsFactors = FALSE
)
readr::write_csv(manifest, manifest_path)
check <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopifnot(
  nrow(check) == 10L,
  !anyDuplicated(check$path),
  !manifest_path %in% check$path,
  all(vapply(check$path, sha256_file, character(1)) == check$sha256),
  all(unname(as.numeric(file.info(check$path)$size)) == as.numeric(check$bytes))
)

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_IMPORT_RECOVERY=PASS manifest=%d/%d ",
    "sha=%s R=%s\n"
  ),
  nrow(check),
  nrow(check),
  sha256_file(manifest_path),
  as.character(getRversion())
))
