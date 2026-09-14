#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

audit_path <- file.path(
  "audit", "report_harmonization", "phase4_gt_source_audit.csv"
)
summary_path <- file.path(
  "audit", "report_harmonization", "phase4_gt_source_document_summary.csv"
)
if (!file.exists(audit_path) || !file.exists(summary_path)) {
  stop(
    "Run scripts/report_harmonization/audit_gt_source_contract.R first",
    call. = FALSE
  )
}

audit <- read.csv(audit_path, check.names = FALSE)
summary <- read.csv(summary_path, check.names = FALSE)
audit$prohibited_output_calls[is.na(audit$prohibited_output_calls)] <- ""

expected_counts <- c(
  Descriptives = 8L, H01 = 36L, H02 = 15L, H03 = 13L,
  H04 = 15L, H05 = 30L, H06 = 11L, H07 = 11L, H08 = 15L,
  H09 = 11L, H10 = 15L, H11 = 15L
)

fail <- function(label, values) {
  stop(
    label, ": ", paste(values, collapse = ", "),
    call. = FALSE
  )
}

stopifnot(
  nrow(audit) == 195L,
  nrow(summary) == 12L,
  !anyDuplicated(audit$label),
  identical(
    as.integer(table(factor(audit$document, levels = names(expected_counts)))),
    as.integer(expected_counts)
  ),
  sum(audit$manuscript_role == "main table") == 13L,
  sum(audit$manuscript_role == "supplementary table") == 182L,
  all(audit$label_option_count == 1L),
  all(audit$caption_option_count == 1L),
  all(audit$caption_nonempty)
)

if (any(!audit$label_conforms)) {
  fail("Nonconforming table labels", audit$label[!audit$label_conforms])
}
if (any(!audit$source_native_gt_static)) {
  fail(
    "Native gt source remains unproven",
    audit$label[!audit$source_native_gt_static]
  )
}
if (any(audit$prohibited_output_calls != "")) {
  fail(
    "Prohibited table output path",
    paste0(
      audit$label[audit$prohibited_output_calls != ""], " [",
      audit$prohibited_output_calls[audit$prohibited_output_calls != ""],
      "]"
    )
  )
}
if (any(audit$duplicate_caption_call)) {
  fail(
    "Competing gt-owned captions",
    audit$label[audit$duplicate_caption_call]
  )
}
if (any(!audit$source_contract_complete)) {
  fail(
    "Incomplete source table contract",
    audit$label[!audit$source_contract_complete]
  )
}

required_main <- c(
  "tbl-participant-site", "tbl-h01-primary-publication-summary",
  "tbl-h02-near-variation", "tbl-h03-primary-results",
  "tbl-h04-primary-results", "tbl-h05-near-results-a",
  "tbl-h05-near-results-b", "tbl-h06-primary-effects",
  "tbl-h07-near-results", "tbl-h08-near-eye-results",
  "tbl-h09-near-eye-results", "tbl-h10-main-results",
  "tbl-h11-global-tests"
)
stopifnot(setequal(
  audit$label[audit$manuscript_role == "main table"],
  required_main
))

cat("PASS: all 195 current manuscript main/supplementary table sources use native gt.\n")
