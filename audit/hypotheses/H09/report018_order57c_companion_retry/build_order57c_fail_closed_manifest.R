#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 57c evidence sealing requires R 4.6.1", call. = FALSE)
}
suppressPackageStartupMessages(library(digest))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
working_dir <- normalizePath(
  Sys.getenv("ORDER57C_WORKING_DIR"),
  winslash = "/",
  mustWork = TRUE
)
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
durable_dir <- file.path(
  root,
  "audit/hypotheses/H09/report018_order57c_companion_retry"
)
manifest_name <- "order57c_fail_closed_evidence_manifest.csv"
manifest_path <- file.path(durable_dir, manifest_name)

list_files <- function(path) {
  list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE,
    all.files = TRUE,
    no.. = TRUE
  )
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

relative_to <- function(paths, base) {
  normalized <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  substring(normalized, nchar(base) + 2L)
}

durable_files <- setdiff(list_files(durable_dir), manifest_path)
working_files <- list_files(working_dir)
semantic_files <- list_files(semantic_dir)
project_rel <- c(
  "audit/report_harmonization/owner_orders/57c_h09_environment_process_probe_and_companion_retry.md",
  "audit/report_harmonization/report018_h09_order57b_environment_stop_independent_acceptance.md",
  "audit/report_harmonization/report018_h09_order57b_environment_stop_independent_acceptance_manifest.csv",
  "audit/report_harmonization/report018_h09_order57c_dispatch_manifest.csv",
  "scripts/report_harmonization/check_report018_h09_order57b_environment_stop.R",
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv",
  "notebooks/hypotheses/H09.qmd",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "artifacts/12_manifests/H09/H09_stage3_artifacts.csv",
  "scripts/hypotheses/H09/h09_contract.R",
  "artifacts/06_model_data/H09/H09_input_audit.csv",
  "scripts/hypotheses/H09/build_h09_preparation_report_manifest.R",
  "tests/hypotheses/H09/test_h09_preparation_report.R",
  "_quarto-nathealth.yml",
  "renv.lock",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation_files/figure-html/fig-h09-prep-sample-support-1.png"
)
project_files <- file.path(root, project_rel)
all_files <- c(durable_files, working_files, semantic_files, project_files)
stopifnot(all(file.exists(all_files)), all(!dir.exists(all_files)))

record_path <- c(
  paste0("durable:", relative_to(durable_files, durable_dir)),
  paste0("working:", relative_to(working_files, working_dir)),
  paste0("semantic:", relative_to(semantic_files, semantic_dir)),
  paste0("project:", project_rel)
)
role <- c(
  rep("durable order57c fail-closed evidence", length(durable_files)),
  rep("external order57c execution evidence", length(working_files)),
  rep("external semantic evidence", length(semantic_files)),
  rep("project identity at order57c stop", length(project_files))
)
manifest <- data.frame(
  path = record_path,
  observed_path = all_files,
  role = role,
  sha256 = vapply(all_files, sha256_file, character(1)),
  bytes = unname(file.info(all_files)$size),
  r_version = as.character(getRversion()),
  stringsAsFactors = FALSE
)
manifest <- manifest[order(manifest$path), , drop = FALSE]
stopifnot(
  !anyDuplicated(manifest$path),
  !any(grepl(manifest_name, manifest$path, fixed = TRUE))
)
utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

sealed <- utils::read.csv(manifest_path, check.names = FALSE)
sealed_files <- sealed$observed_path
live_exact <- file.exists(sealed_files) & !dir.exists(sealed_files) &
  vapply(sealed_files, sha256_file, character(1)) == sealed$sha256 &
  unname(file.info(sealed_files)$size) == as.numeric(sealed$bytes)
stopifnot(
  nrow(sealed) == nrow(manifest),
  !anyDuplicated(sealed$path),
  !any(grepl(manifest_name, sealed$path, fixed = TRUE)),
  all(live_exact)
)
cat(sprintf(
  paste0(
    "REPORT018_H09_ORDER57C_FAIL_CLOSED_MANIFEST=PASS rows=%d/%d ",
    "unique=TRUE non_circular=TRUE R=%s\n"
  ),
  sum(live_exact),
  nrow(sealed),
  as.character(getRversion())
))
