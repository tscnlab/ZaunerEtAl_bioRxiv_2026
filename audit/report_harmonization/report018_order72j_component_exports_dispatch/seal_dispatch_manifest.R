#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

if (getRversion() != "4.6.1") {
  stop("Order72j dispatch sealing requires R 4.6.1", call. = FALSE)
}
if (!requireNamespace("openssl", quietly = TRUE)) {
  stop("The established openssl package is required for SHA-256", call. = FALSE)
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(
  root,
  "audit/report_harmonization/report018_order72j_component_exports_dispatch"
)
manifest_path <- file.path(out_dir, "dispatch_manifest.csv")

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
message(sprintf("ORDER72J_DISPATCH_MANIFEST=SEALED members=%d", nrow(manifest)))
