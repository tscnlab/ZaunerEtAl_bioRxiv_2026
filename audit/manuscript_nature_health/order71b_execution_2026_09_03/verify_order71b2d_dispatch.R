#!/usr/bin/env Rscript

# Replay the sealed Order 71b2d dispatch manifest before any mutation.

if (getRversion() != "4.6.1") {
  stop("Order 71b2d requires R 4.6.1; observed ", getRversion())
}

root <- normalizePath(
  file.path(dirname(commandArgs(trailingOnly = FALSE)[grep("^--file=", commandArgs(trailingOnly = FALSE))] |> sub("^--file=", "", x = _)), "../../.."),
  mustWork = TRUE
)

manifest_path <- file.path(
  root,
  "audit/report_harmonization/report018_writer_order71b2d_dispatch_manifest.csv"
)
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)

stopifnot(
  identical(names(manifest), c("role", "path", "sha256", "bytes")),
  nrow(manifest) == 18L,
  !anyDuplicated(manifest$role),
  !anyDuplicated(manifest$path),
  all(nchar(manifest$sha256) == 64L)
)

sha256_file <- function(path) {
  digest::digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

paths <- file.path(root, manifest$path)
exists <- file.exists(paths)
observed_sha256 <- rep(NA_character_, length(paths))
observed_bytes <- rep(NA_real_, length(paths))
observed_sha256[exists] <- vapply(paths[exists], sha256_file, character(1))
observed_bytes[exists] <- file.info(paths[exists])$size

checks <- data.frame(
  role = manifest$role,
  path = manifest$path,
  expected_sha256 = manifest$sha256,
  observed_sha256 = observed_sha256,
  expected_bytes = manifest$bytes,
  observed_bytes = observed_bytes,
  exact = exists & observed_sha256 == manifest$sha256 & observed_bytes == manifest$bytes,
  stringsAsFactors = FALSE
)

output_path <- file.path(
  root,
  "audit/manuscript_nature_health/order71b_execution_2026_09_03/order71b2d_dispatch_replay.csv"
)
write.csv(checks, output_path, row.names = FALSE, na = "")

if (!all(checks$exact)) {
  print(checks[!checks$exact, ], row.names = FALSE)
  stop("Order 71b2d dispatch replay failed")
}

cat(
  "PASS: Order 71b2d dispatch manifest reproduced ",
  sum(checks$exact),
  "/",
  nrow(checks),
  " identities under R ",
  as.character(getRversion()),
  "\n",
  sep = ""
)
