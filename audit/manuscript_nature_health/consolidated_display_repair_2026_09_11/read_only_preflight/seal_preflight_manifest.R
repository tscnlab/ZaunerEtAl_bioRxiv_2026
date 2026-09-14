#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

if (getRversion() != "4.6.1") {
  stop("Order72i manifest sealing requires R 4.6.1", call. = FALSE)
}
if (!requireNamespace("openssl", quietly = TRUE)) {
  stop("The established openssl package is required for SHA-256", call. = FALSE)
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(
  root,
  "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/read_only_preflight"
)
manifest_path <- file.path(out_dir, "audit_manifest.csv")

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  as.character(openssl::sha256(con))
}

paths <- list.files(out_dir, full.names = TRUE, recursive = TRUE, all.files = TRUE)
paths <- paths[file.info(paths)$isdir %in% FALSE]
paths <- paths[normalizePath(paths, winslash = "/", mustWork = TRUE) != normalizePath(manifest_path, winslash = "/", mustWork = FALSE)]
paths <- sort(paths)

manifest <- data.frame(
  relative_path = substring(paths, nchar(root) + 2L),
  sha256 = vapply(paths, sha256_file, character(1)),
  bytes = unname(file.info(paths)$size),
  stringsAsFactors = FALSE
)

write.csv(manifest, manifest_path, row.names = FALSE)
message(sprintf("ORDER72I_NON_CIRCULAR_MANIFEST=SEALED members=%d", nrow(manifest)))
