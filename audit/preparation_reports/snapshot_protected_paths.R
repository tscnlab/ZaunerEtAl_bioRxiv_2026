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
stopifnot(length(trailing_arguments) == 1L)
output_path <- trailing_arguments[1]
if (!grepl("^/", output_path)) {
  output_path <- file.path(root, output_path)
}
output_path <- file.path(
  normalizePath(dirname(output_path), winslash = "/", mustWork = TRUE),
  basename(output_path)
)

original_baseline_path <- file.path(
  root,
  "audit/preparation_reports/preparation_report_protected_baseline.csv"
)
original_baseline <- utils::read.csv(
  original_baseline_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  identical(
    names(original_baseline),
    c("path", "role", "bytes", "sha256")
  ),
  nrow(original_baseline) == 2094L
)

full_paths <- file.path(root, original_baseline$path)
stopifnot(all(file.exists(full_paths)))

hash_stable_file <- function(path, attempts = 5L) {
  for (attempt in seq_len(attempts)) {
    before <- file.info(path)[1, c("size", "mtime")]
    sha256 <- digest::digest(file = path, algo = "sha256")
    after <- file.info(path)[1, c("size", "mtime")]
    if (
      identical(before$size, after$size) &&
        identical(as.numeric(before$mtime), as.numeric(after$mtime))
    ) {
      return(list(bytes = after$size, sha256 = sha256))
    }
  }
  stop("Protected path changed repeatedly while hashing: ", path)
}

stable_identity <- lapply(full_paths, hash_stable_file)
snapshot <- data.frame(
  path = original_baseline$path,
  role = original_baseline$role,
  bytes = vapply(stable_identity, `[[`, numeric(1), "bytes"),
  sha256 = vapply(stable_identity, `[[`, character(1), "sha256"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
utils::write.csv(snapshot, output_path, row.names = FALSE, na = "")

cat(
  paste0(
    "Protected paths snapshotted: ", nrow(snapshot), "\n",
    "Snapshot SHA-256: ",
    digest::digest(file = output_path, algo = "sha256"),
    "\n"
  )
)
