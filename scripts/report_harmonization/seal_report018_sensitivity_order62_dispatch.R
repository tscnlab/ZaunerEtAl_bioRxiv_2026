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

order_path <- paste0(
  "audit/report_harmonization/owner_orders/",
  "62_sensitivity_battery_target_render.md"
)
preflight_dir <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_battery_preflight"
)
dispatch_path <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_order62_dispatch_manifest.csv"
)
dispatch_record_path <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_order62_dispatch.md"
)
receipt_path <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_order62_dispatch_receipt.md"
)
receipt_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_order62_dispatch_receipt_manifest.csv"
)
matrix_path <- "audit/report_harmonization/coordination_matrix.csv"

h11_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order61a_result_companion_independent_acceptance_manifest.csv"
)
h11_manifest <- readr::read_csv(h11_manifest_path, show_col_types = FALSE)
h11_live_sha <- vapply(h11_manifest$path, sha256_file, character(1))
h11_live_bytes <- unname(as.numeric(file.info(h11_manifest$path)$size))
stopifnot(
  nrow(h11_manifest) == 37L,
  !anyDuplicated(h11_manifest$path),
  !h11_manifest_path %in% h11_manifest$path,
  all(h11_live_sha == h11_manifest$sha256),
  all(h11_live_bytes == as.numeric(h11_manifest$bytes))
)

dispatch_paths <- unique(c(
  order_path,
  "scripts/report_harmonization/check_report018_sensitivity_battery_preflight.R",
  "scripts/report_harmonization/seal_report018_sensitivity_order62_dispatch.R",
  sort(list.files(preflight_dir, full.names = TRUE)),
  paste0(
    "audit/report_harmonization/",
    "report018_h11_order61a_result_companion_independent_acceptance.md"
  ),
  h11_manifest_path,
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "_quarto-nathealth.yml",
  "renv.lock",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "audit/decisions/report_harmonization_render_completion_priority.md",
  "audit/handoffs/report_harmonization_shared_change_request.md",
  "audit/report_harmonization/phase4_corpus_manifest.csv"
))
stopifnot(
  !dispatch_path %in% dispatch_paths,
  !anyDuplicated(dispatch_paths),
  all(file.exists(dispatch_paths)),
  !any(dir.exists(dispatch_paths))
)

dispatch <- data.frame(
  path = dispatch_paths,
  sha256 = vapply(dispatch_paths, sha256_file, character(1)),
  bytes = unname(as.numeric(file.info(dispatch_paths)$size)),
  stringsAsFactors = FALSE
)
readr::write_csv(dispatch, dispatch_path)

writeLines(
  c(
    "# REPORT-018 sensitivity-battery Order 62 dispatch",
    "",
    "Status: `RELEASED_EXACTLY_ONCE_TO_SHARED_PAGE_COORDINATOR`",
    "",
    paste0("Order SHA-256: `", sha256_file(order_path), "`."),
    paste0("Dispatch rows: ", nrow(dispatch), "."),
    "",
    paste0(
      "The H11 result and companion acceptance is sealed. The read-only ",
      "sensitivity preflight passes 10 of 10 domains. Exactly one shared-page ",
      "target render is released under Order 62. No source or scientific ",
      "change and no final corpus rebuild is released."
    )
  ),
  dispatch_record_path,
  useBytes = TRUE
)

matrix_before_sha <- sha256_file(matrix_path)
stopifnot(identical(
  matrix_before_sha,
  "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
))
matrix <- readr::read_csv(matrix_path, show_col_types = FALSE)
stopifnot(nrow(matrix) == 15L, ncol(matrix) == 16L)

h11_row <- matrix$logical_order == "13"
shared_row <- matrix$logical_order == "00"
stopifnot(sum(h11_row) == 1L, sum(shared_row) == 1L)

matrix$current_task_status_2026_08_12[h11_row] <-
  "idle_result_and_companion_accepted"
matrix$first_adjustment_render_received[h11_row] <- "yes"
matrix$harmonization_review_status[h11_row] <-
  "report018_result_and_companion_independently_accepted"
matrix$notes[h11_row] <- paste0(
  matrix$notes[h11_row],
  " Order 61a completed the local preparation-test correction and direct ",
  "283-row manifest reseal without rerendering. The sole test passed once. ",
  "Independent acceptance 54e83ea5 reproduces the 47-row owner seal, all ",
  "980 semantic substitutions, 26 tables, three figures, one Mermaid, ",
  "1,193 resolving header tokens, 1,180 build members, 336 protected paths, ",
  "193 scientific paths, bounded visual QA, and teardown. The screenshot ",
  "suffix mismatch is evidence-only: all 13 retained files decode as valid ",
  "JPEG/JFIF and remain byte-identical. H11 result and companion are closed."
)

matrix$current_task_status_2026_08_12[shared_row] <-
  "active_order62_sensitivity_battery_target_render"
matrix$harmonization_review_status[shared_row] <-
  "report018_order62_sensitivity_battery_target_render_released"
matrix$notes[shared_row] <- paste0(
  matrix$notes[shared_row],
  " H11 is independently closed. The sensitivity-battery preflight passes ",
  "10/10 under R 4.6.1: source d2d17770, one eval-false R chunk, no inline R, ",
  "no table or figure endpoint, one resolving decision link, registered ",
  "target 35/37, semantic disposition NO_GT, 1,180 build members, zero ",
  "symlinks, four structural tests PASS, and no competing project process. ",
  "Order 62 releases exactly one target render. Final corpus rebuild and ",
  "integrated closure remain held."
)
readr::write_csv(matrix, matrix_path)
matrix_after_sha <- sha256_file(matrix_path)

writeLines(
  c(
    "# REPORT-018 sensitivity-battery Order 62 dispatch receipt",
    "",
    "The shared-page coordinator released Order 62 exactly once.",
    "",
    paste0("Order SHA-256: `", sha256_file(order_path), "`."),
    paste0("Dispatch manifest SHA-256: `", sha256_file(dispatch_path), "`."),
    paste0(
      "Dispatch record SHA-256: `",
      sha256_file(dispatch_record_path),
      "`."
    ),
    paste0("Coordination preimage SHA-256: `", matrix_before_sha, "`."),
    paste0("Coordination postimage SHA-256: `", matrix_after_sha, "`."),
    "",
    "No Quarto command was invoked during dispatch."
  ),
  receipt_path,
  useBytes = TRUE
)

receipt_paths <- c(
  order_path,
  dispatch_path,
  dispatch_record_path,
  matrix_path,
  receipt_path,
  "scripts/report_harmonization/seal_report018_sensitivity_order62_dispatch.R"
)
receipt <- data.frame(
  path = receipt_paths,
  sha256 = vapply(receipt_paths, sha256_file, character(1)),
  bytes = unname(as.numeric(file.info(receipt_paths)$size)),
  stringsAsFactors = FALSE
)
stopifnot(
  !receipt_manifest_path %in% receipt$path,
  !anyDuplicated(receipt$path)
)
readr::write_csv(receipt, receipt_manifest_path)

dispatch_check <- readr::read_csv(dispatch_path, show_col_types = FALSE)
receipt_check <- readr::read_csv(
  receipt_manifest_path,
  show_col_types = FALSE
)
stopifnot(
  all(
    vapply(dispatch_check$path, sha256_file, character(1)) ==
      dispatch_check$sha256
  ),
  all(
    unname(as.numeric(file.info(dispatch_check$path)$size)) ==
      as.numeric(dispatch_check$bytes)
  ),
  all(
    vapply(receipt_check$path, sha256_file, character(1)) ==
      receipt_check$sha256
  ),
  all(
    unname(as.numeric(file.info(receipt_check$path)$size)) ==
      as.numeric(receipt_check$bytes)
  )
)

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_DISPATCH=PASS dispatch=%d/%d ",
    "receipt=%d/%d matrix=%s R=%s\n"
  ),
  nrow(dispatch_check),
  nrow(dispatch_check),
  nrow(receipt_check),
  nrow(receipt_check),
  matrix_after_sha,
  as.character(getRversion())
))
