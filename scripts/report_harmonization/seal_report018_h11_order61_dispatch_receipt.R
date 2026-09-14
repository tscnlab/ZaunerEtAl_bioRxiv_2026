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

receipt <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order61_dispatch_receipt.md"
)
manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order61_dispatch_receipt_manifest.csv"
)
members <- c(
  receipt,
  "audit/report_harmonization/owner_orders/61_h11_companion_test_link_and_target_render.md",
  "audit/report_harmonization/report018_h11_order61_dispatch_manifest.csv",
  "audit/report_harmonization/report018_h11_order60c_result_independent_acceptance.md",
  "audit/report_harmonization/report018_h11_order60c_result_independent_acceptance_manifest.csv",
  "scripts/report_harmonization/check_report018_h11_order60c_acceptance_and_companion_preflight.R",
  "audit/report_harmonization/coordination_matrix.csv"
)
roles <- c(
  "dispatch receipt",
  "controlling owner order",
  "dispatch seal",
  "result independent acceptance",
  "result acceptance seal",
  "complete companion preflight checker",
  "coordination invariant"
)
stopifnot(
  length(members) == length(roles),
  !anyDuplicated(members),
  !manifest_path %in% members,
  all(file.exists(members)),
  all(!dir.exists(members))
)
manifest <- data.frame(
  path = members,
  sha256 = vapply(members, sha256_file, character(1)),
  bytes = unname(as.numeric(file.info(members)$size)),
  role = roles,
  stringsAsFactors = FALSE
)
readr::write_csv(manifest, manifest_path)

replay <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopifnot(
  nrow(replay) == 7L,
  !anyDuplicated(replay$path),
  !manifest_path %in% replay$path,
  identical(
    unname(vapply(replay$path, sha256_file, character(1))),
    replay$sha256
  ),
  identical(
    unname(as.numeric(file.info(replay$path)$size)),
    as.numeric(replay$bytes)
  )
)

cat(sprintf(
  "REPORT018_H11_ORDER61_RECEIPT=PASS manifest=%d/%d matrix=%s R=%s\n",
  nrow(replay),
  nrow(replay),
  sha256_file("audit/report_harmonization/coordination_matrix.csv"),
  as.character(getRversion())
))
