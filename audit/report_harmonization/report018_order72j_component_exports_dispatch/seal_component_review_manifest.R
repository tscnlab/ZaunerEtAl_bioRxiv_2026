#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

if (getRversion() != "4.6.1") {
  stop("Order72j component seal requires R 4.6.1", call. = FALSE)
}
if (!requireNamespace("openssl", quietly = TRUE)) {
  stop("Missing established package: openssl", call. = FALSE)
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
review_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72j_component_exports_dispatch"
)
manifest_path <- file.path(review_root, "component_review_manifest.csv")

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  unname(unclass(as.character(openssl::sha256(con))))
}

files <- list.files(
  review_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
files <- files[file.info(files)$isdir %in% FALSE]
files <- sort(setdiff(
  normalizePath(files, winslash = "/", mustWork = TRUE),
  normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
))

manifest <- data.frame(
  path = substring(files, nchar(root) + 2L),
  sha256 = vapply(files, sha256_file, character(1)),
  bytes = as.numeric(file.info(files)$size),
  stringsAsFactors = FALSE
)

stopifnot(
  nrow(manifest) > 20L,
  !anyDuplicated(manifest$path),
  !any(basename(manifest$path) == basename(manifest_path))
)

write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

replay <- read.csv(manifest_path, check.names = FALSE)
replay_paths <- file.path(root, replay$path)
stopifnot(
  identical(replay$path, manifest$path),
  all(file.exists(replay_paths)),
  identical(
    unname(replay$sha256),
    unname(vapply(replay_paths, sha256_file, character(1)))
  ),
  all(as.numeric(replay$bytes) == as.numeric(file.info(replay_paths)$size))
)

message(sprintf(
  "ORDER72J_COMPONENT_REVIEW_SEAL=PASS members=%d manifest_sha256=%s",
  nrow(replay),
  sha256_file(manifest_path)
))
