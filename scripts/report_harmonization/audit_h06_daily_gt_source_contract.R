#!/usr/bin/env Rscript

# Static native-gt addendum for the late-added H06_daily complementary report.
# This parses source only. It does not execute QMD chunks or read scientific
# data, and it preserves the sealed 195-endpoint Descriptives/H01-H11 audit.

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "audit", "report_harmonization")
base_script <- file.path(
  root,
  "scripts",
  "report_harmonization",
  "audit_gt_source_contract.R"
)

base_lines <- readLines(base_script, warn = FALSE)
audit_marker <- grep("^audit <- do.call", base_lines)
stopifnot(length(audit_marker) == 1L, audit_marker > 1L)

audit_environment <- new.env(parent = globalenv())
eval(
  parse(text = paste(base_lines[seq_len(audit_marker - 1L)], collapse = "\n")),
  envir = audit_environment
)

source_qmd <- "notebooks/hypotheses/H06_daily.qmd"
audit <- audit_environment$analyse_document("H06_daily", source_qmd)
row.names(audit) <- NULL
audit$manuscript_role <- "supplementary table"
audit$source_contract_complete <- with(
  audit,
  label_conforms &
    caption_nonempty &
    source_native_gt_static &
    prohibited_output_calls == "" &
    !duplicate_caption_call
)

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
  all(audit$label_option_count == 1L),
  all(audit$caption_option_count == 1L),
  all(audit$label_conforms),
  all(audit$caption_nonempty),
  all(audit$source_native_gt_static),
  all(audit$prohibited_output_calls == ""),
  !any(audit$duplicate_caption_call),
  all(audit$source_contract_complete),
  all(audit$manuscript_role == "supplementary table")
)

write.csv(
  audit,
  file.path(out_dir, "phase4_h06_daily_gt_source_audit.csv"),
  row.names = FALSE,
  na = ""
)

runtime <- c(
  paste0(
    "Run timestamp: ",
    format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE)
  ),
  paste0("Working directory: ", root),
  paste0(
    "Command: Rscript --vanilla ",
    "scripts/report_harmonization/audit_h06_daily_gt_source_contract.R"
  ),
  "Scope: current H06_daily QMD source structure only",
  paste0("R: ", R.version.string),
  paste0("gt: ", as.character(utils::packageVersion("gt"))),
  paste0("knitr: ", as.character(utils::packageVersion("knitr"))),
  paste0("Quarto: ", system2("quarto", "--version", stdout = TRUE)),
  "No QMD chunk was executed; no scientific data or stored output was read",
  "No package was installed or updated",
  "The sealed 195-endpoint Descriptives/H01-H11 audit was not rewritten"
)
writeLines(
  runtime,
  file.path(out_dir, "phase4_h06_daily_gt_source_audit_runtime.txt")
)

cat(
  "H06_daily source table endpoints: ",
  nrow(audit),
  "\n",
  "Native gt statically proven: ",
  sum(audit$source_native_gt_static),
  "\n",
  "Complete source contracts: ",
  sum(audit$source_contract_complete),
  "\n",
  sep = ""
)
