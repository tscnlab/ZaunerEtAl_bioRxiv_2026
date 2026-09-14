#!/usr/bin/env Rscript

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

evidence_rel <- "audit/hypotheses/H02/report017_order33g_result_completion"
evidence_dir <- file.path(root, evidence_rel)
manifest_rel <- file.path(evidence_rel, "owner_evidence_manifest.csv")
manifest_path <- file.path(root, manifest_rel)

evidence_files <- list.files(
  evidence_dir,
  full.names = FALSE,
  recursive = TRUE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
)
evidence_files <- file.path(evidence_rel, evidence_files)
evidence_files <- setdiff(evidence_files, manifest_rel)

fixed <- c(
  "audit/report_harmonization/owner_orders/33g_h02_result_no_rerender_completion.md",
  "audit/report_harmonization/report017_h02_order33g_dispatch_manifest.csv",
  "notebooks/hypotheses/H02.qmd",
  "audit/hypotheses/H02/H02_analysis_preparation.qmd",
  "tests/hypotheses/H02/test_h02_reader_report.R",
  "tests/hypotheses/H02/test_h02_paired_placement_display.R",
  "tests/hypotheses/H02/test_h02_preparation_report.R",
  "_quarto-nathealth.yml",
  "_build/nathealth/notebooks/hypotheses/H02.html",
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html",
  "audit/hypotheses/H02/report017_order33f_result_render/protected_reconciliation_summary.csv",
  "/private/tmp/H02-order33f-semantics.Cux4Wg/gt_html_semantic_post_render_summary.csv",
  "/private/tmp/H02-order33f-semantics.Cux4Wg/001__build__nathealth__notebooks__hypotheses__H02.html_gt_semantic_ledger.csv"
)

paths <- sort(unique(c(evidence_files, fixed)))
stopifnot(!manifest_rel %in% paths, !anyDuplicated(paths))
absolute <- ifelse(startsWith(paths, "/"), paths, file.path(root, paths))
stopifnot(all(file.exists(absolute)), !any(dir.exists(absolute)))

role <- rep("owner_evidence", length(paths))
role[paths == fixed[[1L]]] <- "controlling_order"
role[paths == fixed[[2L]]] <- "dispatch_manifest"
role[paths == fixed[[3L]]] <- "accepted_result_source"
role[paths == fixed[[4L]]] <- "held_companion_source"
role[paths == fixed[[5L]]] <- "authorized_reader_test"
role[paths == fixed[[6L]]] <- "unchanged_paired_test"
role[paths == fixed[[7L]]] <- "held_unexecuted_preparation_test"
role[paths == fixed[[8L]]] <- "held_profile"
role[paths == fixed[[9L]]] <- "fresh_result_html"
role[paths == fixed[[10L]]] <- "held_companion_html"
role[paths == fixed[[11L]]] <- "retained_protected_reconciliation"
role[paths %in% fixed[12:13]] <- "retained_external_semantic_evidence"

manifest <- data.frame(
  role = role,
  path = paths,
  sha256 = unname(vapply(absolute, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(absolute)$size),
  stringsAsFactors = FALSE
)

utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

audit <- utils::read.csv(
  manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
audit_absolute <- ifelse(
  startsWith(audit$path, "/"),
  audit$path,
  file.path(root, audit$path)
)
stopifnot(
  nrow(audit) == nrow(manifest),
  !anyDuplicated(audit$path),
  !manifest_rel %in% audit$path,
  all(file.exists(audit_absolute)),
  identical(
    unname(vapply(audit_absolute, artifact_sha256, character(1))),
    audit$sha256
  ),
  all(as.numeric(file.info(audit_absolute)$size) == as.numeric(audit$bytes))
)

cat(sprintf(
  "H02_ORDER33G_SEAL=PASS rows=%d manifest_sha256=%s\n",
  nrow(audit),
  artifact_sha256(manifest_path)
))
