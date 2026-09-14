#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

audit_path <- file.path(
  "audit",
  "report_harmonization",
  "phase4_h06_daily_gt_source_audit.csv"
)
if (!file.exists(audit_path)) {
  stop(
    paste0(
      "Run scripts/report_harmonization/",
      "audit_h06_daily_gt_source_contract.R first"
    ),
    call. = FALSE
  )
}

audit <- read.csv(audit_path, check.names = FALSE)
audit$prohibited_output_calls[is.na(audit$prohibited_output_calls)] <- ""

expected_labels <- c(
  "tbl-h06-daily-analysis-roles",
  "tbl-h06-daily-fdr-families",
  "tbl-h06-daily-primary-matrix",
  "tbl-h06-daily-primary-site-interactions",
  "tbl-h06-daily-placement-work-free",
  "tbl-h06-daily-placement-activity",
  "tbl-h06-daily-placement-sleep",
  "tbl-h06-daily-gap-decision-changes",
  "tbl-h06-daily-joint-family-summary",
  "tbl-h06-daily-joint-stability-limitations",
  "tbl-h06-daily-joint-site-interactions",
  "tbl-h06-daily-temporal-gamm",
  "tbl-h06-daily-main-comparison",
  "tbl-h06-daily-diagnostic-summary"
)

stopifnot(
  nrow(audit) == 14L,
  setequal(audit$label, expected_labels),
  !anyDuplicated(audit$label),
  all(
    audit$source_sha256 ==
      "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08"
  ),
  all(audit$manuscript_role == "supplementary table"),
  all(audit$label_option_count == 1L),
  all(audit$caption_option_count == 1L),
  all(audit$label_conforms),
  all(audit$caption_nonempty),
  all(audit$source_native_gt_static),
  all(audit$prohibited_output_calls == ""),
  !any(audit$duplicate_caption_call),
  all(audit$source_contract_complete)
)

cat(
  paste0(
    "PASS: all 14 H06_daily complementary table sources use native gt; ",
    "combined current corpus total is 209 endpoints.\n"
  )
)
