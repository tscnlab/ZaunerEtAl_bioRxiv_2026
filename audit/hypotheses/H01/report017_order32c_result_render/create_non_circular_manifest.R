#!/usr/bin/env Rscript

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
stopifnot(identical(as.character(getRversion()), "4.6.1"))
source(file.path(root, "scripts/pipeline/paths_io.R"))

evidence_relative <- "audit/hypotheses/H01/report017_order32c_result_render"
evidence_dir <- file.path(root, evidence_relative)
manifest_path <- file.path(evidence_dir, "owner_evidence_manifest.csv")

files <- sort(list.files(
  evidence_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
files <- files[file.exists(files) & !dir.exists(files)]
files <- setdiff(files, manifest_path)

relative <- substring(files, nchar(root) + 2L)
info <- file.info(files)
manifest <- data.frame(
  path = relative,
  sha256 = vapply(files, artifact_sha256, character(1)),
  bytes = as.numeric(info$size),
  role = ifelse(
    grepl("\\.(png|jpg|jpeg)$", files, ignore.case = TRUE),
    "visual_qa_screenshot",
    ifelse(
      grepl("\\.(R)$", files),
      "owner_evidence_code",
      "owner_evidence"
    )
  ),
  stringsAsFactors = FALSE
)

utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

cat(sprintf(
  "manifest_rows=%d manifest_excludes_self=%s\n",
  nrow(manifest),
  !any(manifest$path == substring(manifest_path, nchar(root) + 2L))
))

