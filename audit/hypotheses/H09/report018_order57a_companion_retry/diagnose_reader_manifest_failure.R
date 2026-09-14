#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 57a reader-manifest diagnosis requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages(library(digest))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
working_dir <- normalizePath(
  Sys.getenv("ORDER57A_WORKING_DIR"),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
)
manifest <- read.csv(manifest_path, check.names = FALSE)
mutable_records <- c(
  "audit/handoffs/H09_worker_handoff.md",
  "audit/handoffs/H09_shared_change_request.md"
)
immutable <- manifest[!manifest$path %in% mutable_records, , drop = FALSE]
paths <- file.path(root, immutable$path)
exists <- file.exists(paths) & !dir.exists(paths)
current_sha <- rep(NA_character_, length(paths))
current_bytes <- rep(NA_real_, length(paths))
current_sha[exists] <- vapply(paths[exists], sha256_file, character(1))
current_bytes[exists] <- unname(file.info(paths[exists])$size)
audit <- transform(
  immutable,
  current_sha256 = current_sha,
  current_bytes = current_bytes,
  path_exists = exists,
  sha256_match = current_sha == immutable$sha256,
  bytes_match = current_bytes == as.numeric(immutable$bytes),
  status = ifelse(
    exists & current_sha == immutable$sha256 &
      current_bytes == as.numeric(immutable$bytes),
    "PASS",
    "FAIL"
  )
)
utils::write.csv(
  audit,
  file.path(working_dir, "reader_manifest_live_audit_postfailure.csv"),
  row.names = FALSE,
  na = ""
)
mismatches <- audit[audit$status == "FAIL", , drop = FALSE]
utils::write.csv(
  mismatches,
  file.path(working_dir, "reader_manifest_mismatches_postfailure.csv"),
  row.names = FALSE,
  na = ""
)

cat(sprintf(
  paste0(
    "H09_ORDER57A_READER_MANIFEST_DIAGNOSIS=%s manifest=%d immutable=%d ",
    "exact=%d mismatches=%d roles=%s R=%s\n"
  ),
  if (nrow(mismatches) > 0L) "EXPECTED_FAILURE_REPRODUCED" else "UNEXPECTED_PASS",
  nrow(manifest),
  nrow(immutable),
  sum(audit$status == "PASS"),
  nrow(mismatches),
  paste(mismatches$path, collapse = "|"),
  as.character(getRversion())
))
