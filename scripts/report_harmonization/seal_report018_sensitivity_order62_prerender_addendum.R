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
  "report018_sensitivity_order62_prerender_matrix_addendum_manifest.csv"
)
paths <- c(
  paste0(
    "audit/report_harmonization/",
    "report018_sensitivity_order62_prerender_matrix_addendum.md"
  ),
  "scripts/report_harmonization/check_report018_sensitivity_order62_prerender.R",
  "scripts/report_harmonization/capture_report018_sensitivity_order62_inventory.R",
  "scripts/report_harmonization/check_report018_sensitivity_order62_postrender.R",
  "scripts/report_harmonization/seal_report018_sensitivity_order62_prerender_addendum.R",
  "scripts/report_harmonization/check_report018_sensitivity_battery_preflight.R",
  "audit/report_harmonization/owner_orders/62_sensitivity_battery_target_render.md",
  "audit/report_harmonization/report018_sensitivity_order62_dispatch_manifest.csv",
  "audit/report_harmonization/report018_sensitivity_order62_dispatch_receipt_manifest.csv",
  "audit/report_harmonization/report018_sensitivity_order62_dispatch.md",
  "audit/report_harmonization/report018_sensitivity_order62_dispatch_receipt.md",
  "audit/report_harmonization/coordination_matrix.csv",
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "_quarto-nathealth.yml",
  "renv.lock"
)
stopifnot(
  length(paths) == 16L,
  !anyDuplicated(paths),
  !manifest_path %in% paths,
  all(file.exists(paths)),
  !any(dir.exists(paths)),
  sha256_file(
    "scripts/report_harmonization/check_report018_sensitivity_battery_preflight.R"
  ) ==
    "27ca85880beda38f82f27720735ca9c567acdac34b5b3d48d1b15d7fad4a515e",
  sha256_file("audit/report_harmonization/coordination_matrix.csv") ==
    "7a6ce0ee4b2c97dea27d18ad3fed9759f580484ea046a2cf645ab5993f714842"
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
  nrow(check) == 16L,
  !anyDuplicated(check$path),
  !manifest_path %in% check$path,
  all(vapply(check$path, sha256_file, character(1)) == check$sha256),
  all(unname(as.numeric(file.info(check$path)$size)) == as.numeric(check$bytes))
)

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_ADDENDUM=PASS manifest=%d/%d ",
    "sha=%s R=%s\n"
  ),
  nrow(check),
  nrow(check),
  sha256_file(manifest_path),
  as.character(getRversion())
))
