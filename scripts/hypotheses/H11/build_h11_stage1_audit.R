#!/usr/bin/env Rscript

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_argument) != 1L) {
  stop("Could not determine the H11 Stage 1 script location", call. = FALSE)
}
script_path <- normalizePath(
  sub("^--file=", "", script_argument),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(dirname(script_path), "h11_stage1.R"))

project_root <- h11_find_project_root(dirname(script_path))
manifest <- h11_write_stage1_artifacts(project_root)

manifest_dir <- file.path(project_root, "artifacts/12_manifests/H11")
dir.create(manifest_dir, recursive = TRUE, showWarnings = FALSE)
manifest_path <- file.path(manifest_dir, "H11_stage1_artifacts.csv")
utils::write.csv(manifest, manifest_path, row.names = FALSE, na = "")

cat("H11 Stage 1 audit artifacts written:\n")
print(manifest, n = Inf)
