#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
stopifnot(identical(as.character(getRversion()), "4.6.1"))
suppressPackageStartupMessages(library(digest))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H11/report018_order61_companion_render"
)
output_path <- file.path(
  evidence_dir,
  "order61_fail_closed_non_circular_manifest.csv"
)

files <- list.files(
  evidence_dir,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = FALSE,
  all.files = TRUE,
  no.. = TRUE
)
files <- sort(setdiff(files, output_path))
stopifnot(
  length(files) > 0L,
  all(file.exists(files)),
  all(!dir.exists(files)),
  !any(nzchar(Sys.readlink(files)))
)

relative <- substring(
  normalizePath(files, winslash = "/", mustWork = TRUE),
  nchar(root) + 2L
)
role <- ifelse(
  grepl("inventory|delta|audit|checks|manifest", basename(files)),
  "bounded audit evidence",
  ifelse(
    grepl("[.]R$", files),
    "task-owned verifier",
    ifelse(
      grepl("[.]md$", files),
      "fail-closed disposition",
      "execution evidence"
    )
  )
)

manifest <- data.frame(
  path = relative,
  sha256 = vapply(
    files,
    digest::digest,
    character(1),
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  bytes = unname(as.numeric(file.info(files)$size)),
  role = role,
  stringsAsFactors = FALSE
)

stopifnot(
  !anyDuplicated(manifest$path),
  !substring(output_path, nchar(root) + 2L) %in% manifest$path,
  all(nchar(manifest$sha256) == 64L)
)
utils::write.csv(
  manifest,
  output_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

message(sprintf(
  "REPORT018_H11_ORDER61_FAIL_CLOSED_SEAL=PASS rows=%d noncircular=TRUE R=4.6.1",
  nrow(manifest)
))
