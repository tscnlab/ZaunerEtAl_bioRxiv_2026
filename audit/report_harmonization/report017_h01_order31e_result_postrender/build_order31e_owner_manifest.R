#!/usr/bin/env Rscript

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "pipeline", "paths_io.R"))

evidence_dir <- file.path(
  root,
  "audit",
  "report_harmonization",
  "report017_h01_order31e_result_postrender"
)
manifest_path <- file.path(evidence_dir, "manifest.csv")

files <- list.files(
  evidence_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
files <- files[file.info(files)$isdir %in% FALSE]
files <- files[normalizePath(files, winslash = "/", mustWork = TRUE) !=
  normalizePath(manifest_path, winslash = "/", mustWork = FALSE)]
files <- sort(files)

relative <- substring(files, nchar(evidence_dir) + 2L)
extension <- tolower(tools::file_ext(relative))
role <- ifelse(
  extension == "png",
  "visual QA screenshot",
  ifelse(
    extension == "r",
    "structural verification code",
    ifelse(
      extension %in% c("csv", "json"),
      "structured verification evidence",
      "owner verification record"
    )
  )
)

manifest <- data.frame(
  path = relative,
  sha256 = vapply(files, artifact_sha256, character(1)),
  bytes = unname(file.info(files)$size),
  role = role,
  stringsAsFactors = FALSE
)

stopifnot(!anyDuplicated(manifest$path))
stopifnot(!any(manifest$path == "manifest.csv"))
utils::write.csv(manifest, manifest_path, row.names = FALSE, na = "")
cat(sprintf("Non-circular owner manifest written: %d evidence files\n", nrow(manifest)))

