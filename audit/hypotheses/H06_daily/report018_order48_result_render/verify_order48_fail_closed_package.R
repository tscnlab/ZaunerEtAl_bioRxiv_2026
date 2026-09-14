#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <-
  "audit/hypotheses/H06_daily/report018_order48_result_render"
evidence_dir <- file.path(root, evidence_relative)
manifest_path <- file.path(evidence_dir, "order48_fail_closed_manifest.csv")
manifest <- read_csv(manifest_path, show_col_types = FALSE)

stopifnot(
  nrow(manifest) > 0L,
  !anyDuplicated(manifest$path),
  !any(
    manifest$path ==
      paste0(
        evidence_relative,
        "/order48_fail_closed_manifest.csv"
      )
  )
)

manifest_files <- file.path(root, manifest$path)
observed_hashes <- vapply(
  manifest_files,
  digest,
  character(1),
  algo = "sha256",
  file = TRUE,
  serialize = FALSE
)
observed_bytes <- as.numeric(file.info(manifest_files)$size)
stopifnot(
  all(file.exists(manifest_files)),
  identical(unname(observed_hashes), manifest$sha256),
  identical(unname(observed_bytes), manifest$bytes)
)

read_evidence <- function(name) {
  read_csv(file.path(evidence_dir, name), show_col_types = FALSE)
}

final_gate <- read_evidence("order48_final_gate_summary.csv")
defects <- read_evidence("visual_fail_closed_defect_summary.csv")
tabs <- read_evidence("placement_tab_content_audit.csv")
figures <- read_evidence("figure_final_size_typography_audit.csv")
build <- read_evidence("build_reconciliation_postqa.csv")
protected <- read_evidence("protected_reconciliation_postqa.csv")
links <- read_evidence("dynamic_link_audit.csv")
tables <- read_evidence("table_endpoint_audit.csv")
figure_endpoints <- read_evidence("figure_endpoint_audit.csv")
render <- read_evidence("render_execution.csv")
lifecycle <- read_evidence("loopback_lifecycle.csv")
browser_console <- fromJSON(
  file.path(evidence_dir, "browser_console_warn_error.json")
)

stopifnot(
  nrow(defects) == 2L,
  identical(defects$defect_id, c("ORDER48-DEFECT-001", "ORDER48-DEFECT-002")),
  nrow(tabs) == 3L,
  all(tabs$status == "FAIL_REPEATED_THREE_PREDICTOR_CONTENT"),
  sum(figures$overall_status == "FAIL_FINAL_SIZE_TYPOGRAPHY") == 4L,
  sum(figures$overall_status == "PASS") == 1L,
  nrow(build) == 846L,
  all(build$status == "PASS"),
  nrow(protected) == 3260L,
  all(protected$status == "PASS"),
  nrow(links) == 7L,
  all(links$status == "PASS"),
  nrow(tables) == 14L,
  nrow(figure_endpoints) == 5L,
  nrow(render) == 1L,
  render$execution_count[[1L]] == 1L,
  render$exit_code[[1L]] == 0L,
  all(lifecycle$status == "PASS"),
  length(browser_console) == 0L,
  final_gate$status[final_gate$domain == "order disposition"] == "FAIL_CLOSED"
)

source_hash <- digest(
  file.path(root, "notebooks/hypotheses/H06_daily.qmd"),
  algo = "sha256",
  file = TRUE,
  serialize = FALSE
)
html_hash <- digest(
  file.path(root, "_build/nathealth/notebooks/hypotheses/H06_daily.html"),
  algo = "sha256",
  file = TRUE,
  serialize = FALSE
)
stopifnot(
  identical(
    source_hash,
    "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08"
  ),
  identical(
    html_hash,
    "15c537269ac0be96ce06c6b574946dc0b98d46afe36c3c696f804a216a7d0c76"
  )
)

cat(sprintf(
  paste0(
    "ORDER48_PACKAGE=PASS manifest_entries=%d defects=2 tables=14 ",
    "figures=5 links=7 build_preserved=846 protected_preserved=3260\n"
  ),
  nrow(manifest)
))
