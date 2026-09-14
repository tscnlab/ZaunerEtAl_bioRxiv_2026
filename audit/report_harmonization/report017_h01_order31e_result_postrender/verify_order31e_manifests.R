#!/usr/bin/env Rscript

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "pipeline", "paths_io.R"))

manifest_paths <- c(
  reporting = "artifacts/12_manifests/H01_reporting_artifacts.csv",
  stage3 = "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
)

absolute_path <- function(path) {
  if (grepl("^/", path)) path else file.path(root, path)
}

audit_one <- function(label, manifest_path) {
  manifest <- utils::read.csv(
    file.path(root, manifest_path),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  required <- c("path", "sha256", "bytes")
  stopifnot(all(required %in% names(manifest)))

  paths <- vapply(manifest$path, absolute_path, character(1))
  exists <- file.exists(paths)
  observed_sha256 <- rep(NA_character_, length(paths))
  observed_bytes <- rep(NA_real_, length(paths))
  observed_sha256[exists] <- vapply(
    paths[exists],
    artifact_sha256,
    character(1)
  )
  observed_bytes[exists] <- unname(file.info(paths[exists])$size)

  data.frame(
    manifest = label,
    manifest_path = manifest_path,
    row = seq_len(nrow(manifest)),
    path = manifest$path,
    recorded_sha256 = manifest$sha256,
    observed_sha256 = observed_sha256,
    recorded_bytes = as.numeric(manifest$bytes),
    observed_bytes = observed_bytes,
    exists = exists,
    sha256_exact = exists & manifest$sha256 == observed_sha256,
    bytes_exact = exists & as.numeric(manifest$bytes) == observed_bytes,
    row_exact = exists &
      manifest$sha256 == observed_sha256 &
      as.numeric(manifest$bytes) == observed_bytes,
    stringsAsFactors = FALSE
  )
}

audit <- do.call(
  rbind,
  Map(audit_one, names(manifest_paths), unname(manifest_paths))
)
row.names(audit) <- NULL

output <- file.path(
  root,
  "audit",
  "report_harmonization",
  "report017_h01_order31e_result_postrender",
  "manifest_row_identity_audit.csv"
)
utils::write.csv(audit, output, row.names = FALSE, na = "")

counts <- aggregate(
  row_exact ~ manifest,
  data = audit,
  FUN = function(x) c(exact = sum(x), total = length(x))
)
for (i in seq_len(nrow(counts))) {
  value <- counts$row_exact[i, ]
  cat(sprintf(
    "%s manifest rows exact: %d/%d\n",
    counts$manifest[i],
    value[["exact"]],
    value[["total"]]
  ))
}

if (!all(audit$row_exact)) {
  stop("At least one reporting-manifest row is not exact", call. = FALSE)
}

