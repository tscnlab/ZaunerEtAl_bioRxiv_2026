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
stopifnot(length(baseline_argument) == 1L)

resolve_project_path <- function(path, must_work = TRUE) {
  candidate <- if (grepl("^/", path)) path else file.path(root, path)
  if (must_work) {
    normalizePath(candidate, winslash = "/", mustWork = TRUE)
  } else {
    file.path(
      normalizePath(dirname(candidate), winslash = "/", mustWork = TRUE),
      basename(candidate)
    )
  }
}

baseline_path <- resolve_project_path(
  sub("^--baseline=", "", baseline_argument)
)
baseline <- utils::read.csv(
  baseline_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  identical(
    names(baseline),
    c("page", "path", "role", "source_spec", "bytes", "sha256")
  ),
  nrow(baseline) > 0L
)

full_paths <- file.path(root, baseline$path)
exists <- file.exists(full_paths)
current_bytes <- rep(NA_real_, nrow(baseline))
current_sha256 <- rep(NA_character_, nrow(baseline))

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
  stop("Scoped read-set path changed repeatedly while hashing: ", path)
}

if (any(exists)) {
  identities <- lapply(full_paths[exists], hash_stable_file)
  current_bytes[exists] <- vapply(identities, `[[`, numeric(1), "bytes")
  current_sha256[exists] <- vapply(
    identities,
    `[[`,
    character(1),
    "sha256"
  )
}

verification <- data.frame(
  page = baseline$page,
  path = baseline$path,
  role = baseline$role,
  source_spec = baseline$source_spec,
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
  output_path <- resolve_project_path(
    sub("^--output=", "", output_argument),
    must_work = FALSE
  )
  utils::write.csv(verification, output_path, row.names = FALSE, na = "")
}

unchanged <- sum(verification$status == "UNCHANGED")
mismatches <- sum(verification$status == "MISMATCH")
cat(
  paste0(
    "Scoped baseline SHA-256: ",
    digest::digest(file = baseline_path, algo = "sha256"), "\n",
    "Scoped paths checked: ", nrow(verification), "\n",
    "Unchanged: ", unchanged, "\n",
    "Mismatches: ", mismatches, "\n"
  )
)

if (mismatches > 0L) {
  print(verification[verification$status == "MISMATCH", ], row.names = FALSE)
  stop("Scoped read-set verification failed.", call. = FALSE)
}
