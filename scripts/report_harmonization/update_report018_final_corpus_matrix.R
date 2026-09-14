#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages(library(openssl))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

matrix_path <- "audit/report_harmonization/coordination_matrix.csv"
pre_sha256 <- sha256_file(matrix_path)
stopifnot(
  pre_sha256 ==
    "01b3438ff097c7ea31486f20932ec3fed72e2eac0361732ada3bedc69408d960"
)

lines <- readLines(matrix_path, warn = FALSE)
old_status <- paste0(
  "idle_sensitivity_battery_order62_independently_accepted_",
  "awaiting_final_corpus"
)
new_status <- paste0(
  "complete_report018_final_37_page_corpus_accepted_with_",
  "documented_legacy_accessibility_limitations"
)
old_review <- paste0(
  "report018_sensitivity_battery_independently_accepted_",
  "awaiting_final_corpus_rebuild"
)
new_review <- paste0(
  "report018_final_37_page_corpus_accepted_with_documented_",
  "legacy_accessibility_limitations"
)
old_note <- paste0(
  "Final 37-page corpus rebuild and integrated closure are the sole ",
  "remaining REPORT-018 step."
)
new_note <- paste0(
  old_note,
  " The final corpus manifest was rebuilt exactly once and now registers ",
  "37 live-exact sources and 37 live-exact HTML targets. The integrated ",
  "R 4.6.1 audit passes six of six domains: 572 native gt tables, 160 ",
  "figures, 10,192 resolving local links, 1,180 unchanged build members, ",
  "and zero symlinks or rendered error nodes. Six current structural tests ",
  "pass and three retained historical gates are classified exactly. No ",
  "reader source, HTML, scientific artifact, profile, package, or lockfile ",
  "changed during final integration. Eight legacy Preparation/Descriptives ",
  "pages retain exact historical table-ID/header semantics, and 24 ",
  "captioned landing-page images remain without alt text. These are ",
  "documented residual accessibility limitations, not claimed repairs."
)

count_fixed <- function(text, pattern) {
  sum(vapply(
    text,
    function(value) grepl(pattern, value, fixed = TRUE),
    logical(1)
  ))
}
stopifnot(
  count_fixed(lines, old_status) == 1L,
  count_fixed(lines, old_review) == 1L,
  count_fixed(lines, old_note) == 1L,
  count_fixed(lines, new_status) == 0L,
  count_fixed(lines, new_review) == 0L
)

lines <- sub(old_status, new_status, lines, fixed = TRUE)
lines <- sub(old_review, new_review, lines, fixed = TRUE)
lines <- sub(old_note, new_note, lines, fixed = TRUE)

temporary <- tempfile(
  "report018-final-corpus-matrix-",
  tmpdir = dirname(matrix_path)
)
writeLines(lines, temporary, useBytes = TRUE)
stopifnot(length(readLines(temporary, warn = FALSE)) == 16L)
file.rename(temporary, matrix_path)

post_sha256 <- sha256_file(matrix_path)
stopifnot(post_sha256 != pre_sha256)

transition <- data.frame(
  path = matrix_path,
  pre_sha256 = pre_sha256,
  post_sha256 = post_sha256,
  old_status = old_status,
  new_status = new_status,
  old_review = old_review,
  new_review = new_review,
  stringsAsFactors = FALSE
)
readr::write_csv(
  transition,
  "audit/report_harmonization/report018_final_corpus_matrix_transition.csv"
)

cat(sprintf(
  "REPORT018_FINAL_CORPUS_MATRIX=PASS pre=%s post=%s R=%s\n",
  pre_sha256,
  post_sha256,
  as.character(getRversion())
))
