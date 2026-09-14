#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
strict <- "--strict" %in% args
stopifnot(identical(as.character(getRversion()), "4.6.1"))

path <- file.path(
  "audit", "report_harmonization", "phase4_gt_render_audit.csv"
)
if (!file.exists(path)) {
  stop(
    "Run scripts/report_harmonization/audit_gt_render_contract.R first",
    call. = FALSE
  )
}
audit <- read.csv(path, check.names = FALSE)

stopifnot(
  nrow(audit) == 195L,
  !anyDuplicated(audit$label),
  all(audit$html_exists),
  all(audit$rendered_gt_table_count <= 1L),
  all(audit$caption_count <= 1L),
  all(audit$rendered_table_count <= 1L)
)

descriptives <- audit[audit$document == "Descriptives", , drop = FALSE]
stopifnot(
  nrow(descriptives) == 8L,
  all(descriptives$render_contract_complete),
  all(descriptives$targeted_render_accepted),
  all(descriptives$integration_complete)
)

if (strict) {
  failures <- audit$label[!audit$integration_complete]
  if (length(failures)) {
    stop(
      "Pending native-gt render/visual integrations: ",
      paste(failures, collapse = ", "),
      call. = FALSE
    )
  }
  cat("PASS: all 195 native-gt tables have accepted rendered integration.\n")
} else {
  pending_documents <- unique(audit$document[!audit$integration_complete])
  cat(
    "PASS: current render audit is structurally valid; accepted integrations ",
    sum(audit$integration_complete), "/195; pending documents: ",
    paste(pending_documents, collapse = ", "), "\n",
    sep = ""
  )
}
