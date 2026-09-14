#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <-
  "audit/hypotheses/H06_daily/report018_order48_result_render"
evidence_dir <- file.path(root, evidence_relative)
manifest_name <- "order48_fail_closed_manifest.csv"
excluded_names <- c(
  manifest_name,
  "order48_fail_closed_manifest_verification.csv"
)

paths <- list.files(
  evidence_dir,
  all.files = TRUE,
  full.names = TRUE,
  recursive = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
)
paths <- paths[!basename(paths) %in% excluded_names]
paths <- sort(paths)
stopifnot(length(paths) > 0L, all(file.exists(paths)))

role_for <- function(path) {
  extension <- tolower(tools::file_ext(path))
  name <- basename(path)
  if (extension %in% c("jpg", "jpeg", "png")) return("visual_qa_capture")
  if (extension == "json") return("browser_measurement_or_log")
  if (extension == "r") return("read_only_audit_code")
  if (extension == "md") return("fail_closed_report")
  if (grepl("inventory|reconciliation", name)) return("identity_evidence")
  if (extension == "csv") return("audit_evidence")
  "audit_evidence"
}

info <- file.info(paths)
manifest <- data.frame(
  path = paste0(
    evidence_relative,
    "/",
    substring(paths, nchar(evidence_dir) + 2L)
  ),
  role = vapply(paths, role_for, character(1)),
  sha256 = vapply(
    paths,
    digest,
    character(1),
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  bytes = as.numeric(info$size),
  stringsAsFactors = FALSE
)

stopifnot(
  !anyDuplicated(manifest$path),
  !any(manifest$path == file.path(evidence_relative, manifest_name))
)
write_csv(manifest, file.path(evidence_dir, manifest_name), na = "")
cat(sprintf(
  "ORDER48_MANIFEST=PASS entries=%d non_circular=1\n",
  nrow(manifest)
))
