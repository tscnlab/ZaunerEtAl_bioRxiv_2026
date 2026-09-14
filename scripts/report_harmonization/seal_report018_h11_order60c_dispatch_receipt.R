#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages(library(openssl))

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

receipt_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60c_dispatch_receipt.md"
)
manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60c_dispatch_receipt_manifest.csv"
)
sealer_path <- paste0(
  "scripts/report_harmonization/",
  "seal_report018_h11_order60c_dispatch_receipt.R"
)
paths <- c(
  receipt_path,
  "audit/report_harmonization/owner_orders/60c_h11_no_rerender_test_contract_and_result_completion.md",
  "audit/report_harmonization/report018_h11_order60c_dispatch_manifest.csv",
  "audit/report_harmonization/report018_h11_order60b_rendered_stop_independent_acceptance.md",
  "audit/report_harmonization/report018_h11_order60b_rendered_stop_independent_acceptance_manifest.csv",
  "audit/report_harmonization/coordination_matrix.csv",
  sealer_path
)
roles <- c(
  "dispatch receipt",
  "controlling order",
  "dispatch seal",
  "independent acceptance",
  "independent acceptance seal",
  "unchanged coordination matrix",
  "receipt sealer"
)
stopifnot(
  length(paths) == 7L,
  length(paths) == length(roles),
  all(file.exists(paths)),
  !anyDuplicated(paths),
  !manifest_path %in% paths,
  sha256_file(paths[[2L]]) ==
    "22cb4390c7715ace8035a44436da3e51b67d0b7c758a17baeb8ac9697444feb9",
  sha256_file(paths[[3L]]) ==
    "3a7fab321ac2deeef1f3fcdd7bfc5ff208c407d2277d861ee036e3e0d19ff870",
  sha256_file(paths[[4L]]) ==
    "6200fff04c64558abfaac8e2df1d97c0dccc62855208da938e003d3825df604d",
  sha256_file(paths[[5L]]) ==
    "2d503e0c88233ce24a641302ff173868479588f7a16c30fee867ef45c3667410",
  sha256_file(paths[[6L]]) ==
    "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
)
manifest <- data.frame(
  path = paths,
  sha256 = vapply(paths, sha256_file, character(1)),
  bytes = unname(as.numeric(file.info(paths)$size)),
  role = roles,
  stringsAsFactors = FALSE
)
utils::write.csv(manifest, manifest_path, row.names = FALSE, na = "")

cat(sprintf(
  "REPORT018_H11_ORDER60C_RECEIPT=PASS rows=%d/%d matrix=unchanged R=%s\n",
  nrow(manifest),
  nrow(manifest),
  as.character(getRversion())
))
