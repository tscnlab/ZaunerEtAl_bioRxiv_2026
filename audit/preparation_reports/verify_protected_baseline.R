#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = FALSE)
file_argument <- grep("^--file=", arguments, value = TRUE)
stopifnot(length(file_argument) == 1L)
script_path <- sub("^--file=", "", file_argument)
root <- normalizePath(
  file.path(dirname(script_path), "../.."),
  winslash = "/",
  mustWork = TRUE
)

project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))
stopifnot(requireNamespace("digest", quietly = TRUE))

trailing_arguments <- commandArgs(trailingOnly = TRUE)
baseline_argument <- grep("^--baseline=", trailing_arguments, value = TRUE)
output_argument <- grep("^--output=", trailing_arguments, value = TRUE)
positional_arguments <- trailing_arguments[!grepl("^--", trailing_arguments)]

if (length(baseline_argument) == 1L) {
  baseline_path <- sub("^--baseline=", "", baseline_argument)
  if (!grepl("^/", baseline_path)) {
    baseline_path <- file.path(root, baseline_path)
  }
} else {
  baseline_path <- file.path(
    root,
    "audit/preparation_reports/preparation_report_protected_baseline.csv"
  )
}
baseline_path <- normalizePath(baseline_path, winslash = "/", mustWork = TRUE)
baseline <- utils::read.csv(
  baseline_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  identical(names(baseline), c("path", "role", "bytes", "sha256")),
  nrow(baseline) == 2094L
)

full_paths <- file.path(root, baseline$path)
exists <- file.exists(full_paths)
current_bytes <- rep(NA_real_, nrow(baseline))
current_sha256 <- rep(NA_character_, nrow(baseline))
current_bytes[exists] <- file.info(full_paths[exists])$size
current_sha256[exists] <- vapply(
  full_paths[exists],
  digest::digest,
  character(1),
  algo = "sha256",
  file = TRUE
)

verification <- data.frame(
  path = baseline$path,
  role = baseline$role,
  baseline_bytes = baseline$bytes,
  current_bytes = current_bytes,
  baseline_sha256 = baseline$sha256,
  current_sha256 = current_sha256,
  exists = exists,
  bytes_match = exists & current_bytes == baseline$bytes,
  sha256_match = exists & current_sha256 == baseline$sha256,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
verification$status <- ifelse(
  verification$exists & verification$bytes_match & verification$sha256_match,
  "UNCHANGED",
  "MISMATCH"
)

if (length(output_argument) == 1L) {
  requested_output <- sub("^--output=", "", output_argument)
} else if (length(positional_arguments) > 0L) {
  requested_output <- positional_arguments[1]
} else {
  requested_output <- NULL
}

if (!is.null(requested_output)) {
  output_path <- normalizePath(
    dirname(requested_output),
    winslash = "/",
    mustWork = TRUE
  )
  output_path <- file.path(output_path, basename(requested_output))
  utils::write.csv(verification, output_path, row.names = FALSE, na = "")
}

baseline_inventory_sha256 <- digest::digest(
  file = baseline_path,
  algo = "sha256"
)
unchanged <- sum(verification$status == "UNCHANGED")
mismatches <- sum(verification$status == "MISMATCH")

cat(
  paste0(
    "Baseline inventory SHA-256: ", baseline_inventory_sha256, "\n",
    "Protected paths checked: ", nrow(verification), "\n",
    "Unchanged: ", unchanged, "\n",
    "Mismatches: ", mismatches, "\n"
  )
)

if (mismatches > 0L) {
  print(verification[verification$status == "MISMATCH", ], row.names = FALSE)
  stop("Protected-file checksum verification failed.", call. = FALSE)
}
