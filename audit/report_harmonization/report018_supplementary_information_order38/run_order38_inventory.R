#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, nzchar(args[[1L]]))
phase <- args[[1L]]

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_dir <- file.path(
  root,
  "audit/report_harmonization/report018_supplementary_information_order38"
)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  output <- system2(
    "/usr/bin/shasum",
    c("-a", "256", shQuote(path)),
    stdout = TRUE
  )
  sub("[[:space:]]+.*$", "", output[[1L]])
}

format_mtime <- function(value) {
  format(value, "%Y-%m-%d %H:%M:%S %Z", tz = "UTC")
}

build_root <- normalizePath(
  file.path(root, "_build/nathealth"),
  winslash = "/",
  mustWork = TRUE
)
entries <- c(
  build_root,
  list.files(
    build_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )
)
entries <- unique(entries)
link_target <- Sys.readlink(entries)
is_link <- nzchar(link_target)
is_directory <- dir.exists(entries) & !is_link
is_file <- file.exists(entries) & !dir.exists(entries) & !is_link

link_resolved <- rep("", length(entries))
link_safe <- rep(NA, length(entries))
if (any(is_link)) {
  for (index in which(is_link)) {
    candidate <- if (startsWith(link_target[[index]], "/")) {
      link_target[[index]]
    } else {
      file.path(dirname(entries[[index]]), link_target[[index]])
    }
    resolved <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
    link_resolved[[index]] <- resolved
    link_safe[[index]] <- identical(resolved, build_root) ||
      startsWith(resolved, paste0(build_root, "/"))
  }
  stopifnot(all(link_safe[is_link]))
}

entry_info <- file.info(entries)
relative_path <- ifelse(
  entries == build_root,
  "",
  substring(entries, nchar(build_root) + 2L)
)
sha256 <- rep(NA_character_, length(entries))
sha256[is_file] <- vapply(entries[is_file], sha256_file, character(1))
bytes <- rep(NA_real_, length(entries))
bytes[is_file] <- as.numeric(entry_info$size[is_file])

build <- data.frame(
  path = relative_path,
  type = ifelse(is_link, "symlink", ifelse(is_directory, "directory", "file")),
  sha256 = sha256,
  bytes = bytes,
  mtime_utc = format_mtime(entry_info$mtime),
  mode = sprintf("%04o", as.integer(entry_info$mode)),
  link_target = link_target,
  link_resolved = link_resolved,
  link_safe = link_safe,
  stringsAsFactors = FALSE
)
build <- build[order(build$path), , drop = FALSE]
write.csv(
  build,
  file.path(evidence_dir, paste0("build_inventory_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)

pin_paths <- c(
  "supplementary_information.qmd",
  "_quarto-nathealth.yml",
  "_quarto.yml",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "bibliography.bib",
  "nature.csl",
  "styles.css",
  "scripts/report_harmonization/build_phase4_corpus_manifest.R",
  "tests/report_harmonization/test_navigation_contract.R",
  "tests/report_harmonization/test_reader_links.R",
  "_build/nathealth/index.html",
  "_build/nathealth/notebooks/preregistration_deviations.html",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html",
  "_build/nathealth/notebooks/hypotheses/H02.html",
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html"
)
pin_files <- file.path(root, pin_paths)
stopifnot(all(file.exists(pin_files)))
pin_info <- file.info(pin_files)
pins <- data.frame(
  path = pin_paths,
  sha256 = vapply(pin_files, sha256_file, character(1)),
  bytes = as.numeric(pin_info$size),
  mtime_utc = format_mtime(pin_info$mtime),
  stringsAsFactors = FALSE
)
write.csv(
  pins,
  file.path(evidence_dir, paste0("protected_pins_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)

cat(sprintf(
  paste0(
    "phase=%s build_entries=%d files=%d directories=%d symlinks=%d ",
    "unsafe_symlinks=%d pins=%d\n"
  ),
  phase,
  nrow(build),
  sum(build$type == "file"),
  sum(build$type == "directory"),
  sum(build$type == "symlink"),
  sum(build$type == "symlink" & !build$link_safe, na.rm = TRUE),
  nrow(pins)
))
