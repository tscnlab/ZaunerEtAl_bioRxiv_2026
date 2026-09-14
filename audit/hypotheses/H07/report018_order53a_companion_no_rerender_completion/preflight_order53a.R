#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_rel <-
  "audit/hypotheses/H07/report018_order53a_companion_no_rerender_completion"
evidence_dir <- file.path(root, evidence_rel)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

dispatch_rel <-
  "audit/report_harmonization/report018_h07_order53a_dispatch_manifest.csv"
dispatch <- read.csv(file.path(root, dispatch_rel), check.names = FALSE)
matrix_rel <- "audit/report_harmonization/coordination_matrix.csv"
hard <- dispatch[dispatch$path != matrix_rel, , drop = FALSE]

stopifnot(
  nrow(dispatch) == 27L,
  nrow(hard) == 26L,
  !anyDuplicated(dispatch$path),
  identical(
    sha256_file(file.path(root, dispatch_rel)),
    "d8e1b84945d0b1479ffa63c674b23014d2bc11e8c66bd41423ef74579573a5d7"
  )
)

hard_paths <- file.path(root, hard$path)
hard_exists <- file.exists(hard_paths) & !dir.exists(hard_paths)
observed_sha <- rep(NA_character_, nrow(hard))
observed_bytes <- rep(NA_real_, nrow(hard))
observed_sha[hard_exists] <- vapply(
  hard_paths[hard_exists],
  sha256_file,
  character(1)
)
observed_bytes[hard_exists] <- unname(file.info(hard_paths[hard_exists])$size)

dispatch_audit <- data.frame(
  path = hard$path,
  role = hard$role,
  expected_sha256 = hard$sha256,
  observed_sha256 = observed_sha,
  expected_bytes = as.numeric(hard$bytes),
  observed_bytes = observed_bytes,
  exists = hard_exists,
  stringsAsFactors = FALSE
)
dispatch_audit$status <- ifelse(
  dispatch_audit$exists &
    dispatch_audit$expected_sha256 == dispatch_audit$observed_sha256 &
    dispatch_audit$expected_bytes == dispatch_audit$observed_bytes,
  "PASS",
  "FAIL"
)
write.csv(
  dispatch_audit,
  file.path(evidence_dir, "dispatch_reconciliation_preqa.csv"),
  row.names = FALSE,
  na = ""
)
stopifnot(all(dispatch_audit$status == "PASS"))

delta_path <- file.path(
  root,
  "audit/hypotheses/H07/report018_order53_companion_render/protected_delta_posthelper.csv"
)
delta <- read.csv(delta_path, check.names = FALSE)
removed <- delta[delta$delta == "REMOVED", , drop = FALSE]
removed_exists <- file.exists(file.path(root, removed$relative_path))
cleanup_audit <- data.frame(
  relative_path = removed$relative_path,
  historical_sha256 = removed$sha256_pre,
  historical_bytes = removed$bytes_pre,
  exists_now = removed_exists,
  status = ifelse(!removed_exists, "PASS_ABSENT", "FAIL_PRESENT"),
  stringsAsFactors = FALSE
)
write.csv(
  cleanup_audit,
  file.path(evidence_dir, "canonical_cleanup_preqa.csv"),
  row.names = FALSE,
  na = ""
)
stopifnot(
  nrow(cleanup_audit) == 16L,
  sum(startsWith(
    cleanup_audit$relative_path,
    "audit/hypotheses/H07/H07_analysis_preparation_files/"
  )) == 15L,
  all(cleanup_audit$status == "PASS_ABSENT")
)

build_root <- file.path(root, "_build/nathealth")
build_files <- list.files(
  build_root,
  all.files = TRUE,
  full.names = TRUE,
  recursive = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
)
build_info <- file.info(build_files)
build_files <- build_files[!is.na(build_info$isdir) & !build_info$isdir]
build_links <- Sys.readlink(build_files)
symlink_audit <- data.frame(
  path = substring(
    normalizePath(build_files[nzchar(build_links)], winslash = "/", mustWork = FALSE),
    nchar(root) + 2L
  ),
  target = build_links[nzchar(build_links)],
  stringsAsFactors = FALSE
)
write.csv(
  symlink_audit,
  file.path(evidence_dir, "build_symlink_preqa.csv"),
  row.names = FALSE,
  na = ""
)
stopifnot(nrow(symlink_audit) == 0L)

status <- data.frame(
  check = c(
    "R version",
    "dispatch rows",
    "non-matrix dispatch rows exact",
    "canonical cleanup paths absent",
    "build symlinks"
  ),
  observed = c(
    as.character(getRversion()),
    as.character(nrow(dispatch)),
    as.character(sum(dispatch_audit$status == "PASS")),
    as.character(sum(cleanup_audit$status == "PASS_ABSENT")),
    as.character(nrow(symlink_audit))
  ),
  expected = c("4.6.1", "27", "26", "16", "0"),
  status = "PASS",
  stringsAsFactors = FALSE
)
write.csv(
  status,
  file.path(evidence_dir, "preflight_status.csv"),
  row.names = FALSE,
  na = ""
)

cat(
  sprintf(
    "ORDER53A_PREFLIGHT=PASS dispatch=%d/%d cleanup_absent=%d symlinks=%d R=%s\n",
    sum(dispatch_audit$status == "PASS"),
    nrow(dispatch_audit),
    sum(cleanup_audit$status == "PASS_ABSENT"),
    nrow(symlink_audit),
    as.character(getRversion())
  )
)

