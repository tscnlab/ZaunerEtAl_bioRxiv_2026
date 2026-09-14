#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
out_dir <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)
stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(data.table)
  library(digest)
})

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

live_table <- function(relative) {
  absolute <- file.path(root, relative)
  exists <- file.exists(absolute)
  sha256 <- rep(NA_character_, length(relative))
  bytes <- rep(NA_real_, length(relative))
  sha256[exists] <- unname(vapply(
    absolute[exists],
    sha256_file,
    character(1)
  ))
  bytes[exists] <- as.numeric(file.info(absolute[exists])$size)
  data.table(
    path = relative,
    exists = exists,
    sha256 = sha256,
    bytes = bytes
  )
}

order_relative <- paste0(
  "audit/report_harmonization/owner_orders/",
  "47d_h06_hourly_companion_render.md"
)
dispatch_relative <- paste0(
  "audit/report_harmonization/",
  "report018_h06_order47d_dispatch_manifest.csv"
)
concurrence_relative <- paste0(
  "audit/report_harmonization/",
  "report018_h06_order47d_central_concurrence.md"
)
concurrence_manifest_relative <- paste0(
  "audit/report_harmonization/",
  "report018_h06_order47d_central_concurrence_manifest.csv"
)

hard_files <- data.table(
  path = c(
    order_relative,
    dispatch_relative,
    concurrence_relative,
    concurrence_manifest_relative
  ),
  sha256 = c(
    "fe25c05e3fb20b9a76c41bd2fd67810e9b2cf7845fb52ffc1b92cd01d0663523",
    "9067ddc6607ea7e5f94fa7bb8d8259073137ac740a606ddcea9431e6dd052a47",
    "cd9941b10481c04b7172ecad123273236e7e54d3c71ce9abccf835a037f8f390",
    "823f73451f3284ae696c1e6d5665394a9c4038cedaf108fd91f8a444c537d9dd"
  )
)
hard_live <- live_table(hard_files$path)
stopifnot(
  all(hard_live$exists),
  identical(hard_live$sha256, hard_files$sha256)
)

dispatch <- fread(file.path(root, dispatch_relative))
stopifnot(
  nrow(dispatch) == 37L,
  identical(names(dispatch), c("path", "sha256", "bytes", "role")),
  !anyDuplicated(dispatch$path),
  !dispatch_relative %in% dispatch$path
)
dispatch_live <- live_table(dispatch$path)
dispatch_check <- cbind(dispatch, dispatch_live[, .(
  live_exists = exists,
  live_sha256 = sha256,
  live_bytes = bytes
)])
dispatch_check[, exact := live_exists &
  sha256 == live_sha256 &
  as.numeric(bytes) == as.numeric(live_bytes)]
matrix_relative <- "audit/report_harmonization/coordination_matrix.csv"
stopifnot(
  all(dispatch_check$exact[dispatch_check$path != matrix_relative]),
  identical(
    dispatch_check$live_sha256[dispatch_check$path == matrix_relative],
    "e50de62b5882855f681d13d0561355155a1211797f5b8d3cde05fa701337541c"
  ),
  identical(
    as.numeric(dispatch_check$live_bytes[dispatch_check$path == matrix_relative]),
    28537
  )
)
fwrite(
  dispatch_check,
  file.path(out_dir, "dispatch_preflight.csv")
)

concurrence_manifest <- fread(file.path(root, concurrence_manifest_relative))
stopifnot(
  nrow(concurrence_manifest) == 20L,
  !anyDuplicated(concurrence_manifest$path)
)
concurrence_live <- live_table(concurrence_manifest$path)
concurrence_check <- cbind(concurrence_manifest, concurrence_live[, .(
  live_exists = exists,
  live_sha256 = sha256,
  live_bytes = bytes
)])
concurrence_check[, exact := live_exists &
  sha256 == live_sha256 &
  as.numeric(bytes) == as.numeric(live_bytes)]
stopifnot(
  all(concurrence_check$exact[concurrence_check$path != matrix_relative]),
  identical(
    concurrence_check$live_sha256[concurrence_check$path == matrix_relative],
    "e50de62b5882855f681d13d0561355155a1211797f5b8d3cde05fa701337541c"
  )
)
fwrite(
  concurrence_check,
  file.path(out_dir, "concurrence_manifest_preflight.csv")
)

qmd_relative <- "audit/hypotheses/H06/H06_analysis_preparation.qmd"
qmd_path <- file.path(root, qmd_relative)
qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
chunks <- list()
inside <- FALSE
current <- character()
for (line in qmd_lines) {
  if (!inside && grepl("^```\\{r(?:[ ,}])", line, perl = TRUE)) {
    inside <- TRUE
    current <- character()
  } else if (inside && grepl("^```[[:space:]]*$", line)) {
    chunks[[length(chunks) + 1L]] <- current
    inside <- FALSE
  } else if (inside) {
    current <- c(current, line)
  }
}
stopifnot(!inside, length(chunks) == 34L)
for (index in seq_along(chunks)) {
  parse(text = chunks[[index]], keep.source = TRUE)
}
chunk_labels <- unlist(lapply(chunks, function(chunk) {
  label_lines <- grep("^#\\| label:[[:space:]]*", chunk, value = TRUE)
  sub("^#\\| label:[[:space:]]*", "", label_lines)
}), use.names = FALSE)
table_labels <- chunk_labels[startsWith(chunk_labels, "tbl-h06-prep-")]
figure_labels <- chunk_labels[startsWith(chunk_labels, "fig-h06-prep-")]
stopifnot(
  length(chunk_labels) == 34L,
  !anyDuplicated(chunk_labels),
  length(table_labels) == 30L,
  !anyDuplicated(table_labels),
  length(figure_labels) == 3L,
  !anyDuplicated(figure_labels),
  sum(grepl("flowchart TD", qmd_lines, fixed = TRUE)) == 1L
)

manifest_relative <- paste0(
  "artifacts/12_manifests/H06/",
  "H06_preparation_report_manifest.csv"
)
preparation_manifest <- fread(file.path(root, manifest_relative))
stopifnot(
  nrow(preparation_manifest) == 315L,
  !anyDuplicated(preparation_manifest$path)
)
preparation_live <- live_table(preparation_manifest$path)
preparation_check <- cbind(preparation_manifest, preparation_live[, .(
  live_exists = exists,
  live_sha256 = sha256,
  live_bytes = bytes
)])
preparation_check[, exact := live_exists &
  sha256 == live_sha256 &
  as.numeric(bytes) == as.numeric(live_bytes)]
expected_mismatch <- c(
  "_build/nathealth/notebooks/hypotheses/H06.html",
  "_quarto-nathealth.yml",
  "artifacts/10_figures/H06/H06_reader_primary_effects.pdf",
  "artifacts/10_figures/H06/H06_reader_primary_effects.png",
  "artifacts/10_figures/H06/H06_reader_primary_effects.svg",
  "artifacts/10_figures/H06/H06_reader_temporal_activity.pdf",
  "artifacts/10_figures/H06/H06_reader_temporal_activity.png",
  "artifacts/10_figures/H06/H06_reader_temporal_activity.svg",
  "artifacts/10_figures/H06/H06_reader_temporal_day_type.pdf",
  "artifacts/10_figures/H06/H06_reader_temporal_day_type.png",
  "artifacts/10_figures/H06/H06_reader_temporal_day_type.svg",
  paste0(
    "artifacts/10_figures/H06/",
    "H06_stage3_site_specific_significance_screen.pdf"
  ),
  paste0(
    "artifacts/10_figures/H06/",
    "H06_stage3_site_specific_significance_screen.png"
  ),
  "artifacts/12_manifests/H06/H06_stage3_artifacts.csv",
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  "audit/hypotheses/H06/H06_analysis_preparation.qmd",
  "notebooks/hypotheses/H06.qmd",
  "scripts/hypotheses/H06/build_h06_stage3_reader_displays.R",
  paste0(
    "scripts/hypotheses/H06/",
    "build_h06_stage3_site_specific_screening.R"
  ),
  "scripts/hypotheses/H06/h06_contract.R"
)
stopifnot(
  sum(!preparation_check$exact) == 20L,
  sum(preparation_check$exact) == 295L,
  setequal(preparation_check$path[!preparation_check$exact], expected_mismatch)
)
fwrite(
  preparation_check,
  file.path(out_dir, "preparation_manifest_live_pre.csv")
)

for (relative in c(
  "tests/hypotheses/H06/test_h06_preparation_report.R",
  "scripts/hypotheses/H06/build_h06_preparation_report_manifest.R",
  "scripts/hypotheses/H06/h06_contract.R"
)) {
  parse(file = file.path(root, relative), keep.source = TRUE)
}

profile_lines <- trimws(readLines(file.path(root, "_quarto-nathealth.yml")))
result_entry <- which(profile_lines == "- notebooks/hypotheses/H06.qmd")
companion_entry <- which(
  profile_lines == "- audit/hypotheses/H06/H06_analysis_preparation.qmd"
)
stopifnot(
  length(result_entry) == 1L,
  length(companion_entry) == 1L,
  companion_entry == result_entry + 1L,
  any(profile_lines == paste0(
    "post-render: scripts/report_harmonization/",
    "post_render_gt_html_semantics.R"
  ))
)

build_root <- file.path(root, "_build/nathealth")
build_entries <- list.files(
  build_root,
  all.files = TRUE,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
)
stopifnot(!any(nzchar(Sys.readlink(build_entries))))
build_files <- sort(build_entries[file.exists(build_entries) &
  !dir.exists(build_entries)])
build_relative <- substring(build_files, nchar(root) + 2L)
build_inventory <- data.table(
  path = build_relative,
  sha256 = unname(vapply(build_files, sha256_file, character(1))),
  bytes = as.numeric(file.info(build_files)$size),
  mtime = as.numeric(file.info(build_files)$mtime)
)
fwrite(build_inventory, file.path(out_dir, "build_pre.csv"))

protected_paths <- unique(c(
  dispatch$path[dispatch$path != matrix_relative],
  concurrence_manifest$path[concurrence_manifest$path != matrix_relative],
  preparation_manifest$path,
  manifest_relative,
  "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.qmd"
))
protected_pre <- live_table(protected_paths)
stopifnot(all(protected_pre$exists), !anyDuplicated(protected_pre$path))
fwrite(protected_pre, file.path(out_dir, "protected_live_pre.csv"))

cat("H06 order 47d owner preflight PASS\n")
cat("R version:", R.version.string, "\n")
cat("Dispatch hard rows: 36/36 exact; matrix classified as dispatch evidence\n")
cat("Concurrence manifest hard rows: 19/19 exact; matrix classified\n")
cat("Companion source: 34/34 R chunks parse\n")
cat("Endpoints: 30 tables, 3 figures, 1 TD Mermaid\n")
cat("Preparation manifest: 20 expected mismatches, 295 exact\n")
cat("Build files:", nrow(build_inventory), "; symlinks: 0\n")
cat("Protected live inventory:", nrow(protected_pre), "rows\n")
