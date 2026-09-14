#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop(
    "Usage: check_h06_order47d_central_concurrence.R <project-root>",
    call. = FALSE
  )
}

root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H06 order 47d concurrence requires R 4.6.1.", call. = FALSE)
}

suppressPackageStartupMessages({
  library(data.table)
  library(digest)
})

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

order_relative <- paste0(
  "audit/report_harmonization/owner_orders/",
  "47d_h06_hourly_companion_render.md"
)
dispatch_relative <- paste0(
  "audit/report_harmonization/",
  "report018_h06_order47d_dispatch_manifest.csv"
)
order_path <- file.path(root, order_relative)
dispatch_path <- file.path(root, dispatch_relative)

stopifnot(
  identical(unname(file.info(order_path)$size), 9631),
  identical(
    sha256_file(order_path),
    "fe25c05e3fb20b9a76c41bd2fd67810e9b2cf7845fb52ffc1b92cd01d0663523"
  ),
  identical(unname(file.info(dispatch_path)$size), 5506),
  identical(
    sha256_file(dispatch_path),
    "9067ddc6607ea7e5f94fa7bb8d8259073137ac740a606ddcea9431e6dd052a47"
  )
)

dispatch <- fread(dispatch_path)
stopifnot(
  nrow(dispatch) == 37L,
  identical(names(dispatch), c("path", "sha256", "bytes", "role")),
  !anyDuplicated(dispatch$path),
  !dispatch_relative %in% dispatch$path
)
dispatch_paths <- file.path(root, dispatch$path)
stopifnot(
  all(file.exists(dispatch_paths)),
  identical(
    as.numeric(file.info(dispatch_paths)$size),
    as.numeric(dispatch$bytes)
  ),
  identical(
    unname(vapply(dispatch_paths, sha256_file, character(1))),
    dispatch$sha256
  )
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
  tryCatch(
    parse(text = chunks[[index]], keep.source = TRUE),
    error = function(error) {
      stop(
        sprintf("H06 companion R chunk %d did not parse: %s", index, error),
        call. = FALSE
      )
    }
  )
}

chunk_labels <- unlist(
  lapply(chunks, function(chunk) {
    label_lines <- grep("^#\\| label:[[:space:]]*", chunk, value = TRUE)
    sub("^#\\| label:[[:space:]]*", "", label_lines)
  }),
  use.names = FALSE
)
table_labels <- chunk_labels[startsWith(chunk_labels, "tbl-h06-prep-")]
figure_labels <- chunk_labels[startsWith(chunk_labels, "fig-h06-prep-")]
stopifnot(
  length(chunk_labels) == 34L,
  !anyDuplicated(chunk_labels),
  length(table_labels) == 30L,
  length(unique(table_labels)) == 30L,
  length(figure_labels) == 3L,
  length(unique(figure_labels)) == 3L,
  sum(grepl("flowchart TD", qmd_lines, fixed = TRUE)) == 1L
)

manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H06/H06_preparation_report_manifest.csv"
)
preparation_manifest <- fread(manifest_path)
stopifnot(
  nrow(preparation_manifest) == 315L,
  !anyDuplicated(preparation_manifest$path),
  all(nchar(preparation_manifest$sha256) == 64L),
  all(preparation_manifest$bytes > 0L)
)
preparation_paths <- file.path(root, preparation_manifest$path)
preparation_exists <- file.exists(preparation_paths)
live_sha256 <- rep(NA_character_, nrow(preparation_manifest))
live_bytes <- rep(NA_real_, nrow(preparation_manifest))
live_sha256[preparation_exists] <- vapply(
  preparation_paths[preparation_exists],
  sha256_file,
  character(1)
)
live_bytes[preparation_exists] <- file.info(
  preparation_paths[preparation_exists]
)$size
mismatch <- !preparation_exists |
  live_sha256 != preparation_manifest$sha256 |
  live_bytes != preparation_manifest$bytes

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
  sum(mismatch) == 20L,
  sum(!mismatch) == 295L,
  setequal(preparation_manifest$path[mismatch], expected_mismatch)
)

profile_path <- file.path(root, "_quarto-nathealth.yml")
profile_lines <- trimws(readLines(profile_path, warn = FALSE))
result_entry <- which(profile_lines == "- notebooks/hypotheses/H06.qmd")
companion_entry <- which(
  profile_lines == "- audit/hypotheses/H06/H06_analysis_preparation.qmd"
)
stopifnot(
  length(result_entry) == 1L,
  length(companion_entry) == 1L,
  companion_entry == result_entry + 1L,
  any(
    profile_lines ==
      "post-render: scripts/report_harmonization/post_render_gt_html_semantics.R"
  )
)

for (relative in c(
  "tests/hypotheses/H06/test_h06_preparation_report.R",
  "scripts/hypotheses/H06/build_h06_preparation_report_manifest.R",
  "scripts/hypotheses/H06/h06_contract.R"
)) {
  parse(file = file.path(root, relative), keep.source = TRUE)
}

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

order_text <- paste(readLines(order_path, warn = FALSE), collapse = "\n")
order_flat <- trimws(gsub("[[:space:]]+", " ", order_text))
required_order_tokens <- c(
  "GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render audit/hypotheses/H06/H06_analysis_preparation.qmd --profile nathealth",
  "build_h06_preparation_report_manifest.R` exactly",
  "exactly 30 native gt tables, three figure endpoints",
  "No source, scientific value, model, artifact, profile, package, lockfile",
  "H06 daily and every later REPORT-018 target remain held"
)
stopifnot(all(vapply(
  required_order_tokens,
  grepl,
  logical(1),
  x = order_flat,
  fixed = TRUE
)))

cat("H06 order 47d central concurrence PASS\n")
cat("R version:", R.version.string, "\n")
cat("Dispatch manifest: 37/37 exact, unique, non-circular\n")
cat("Companion source: 34/34 R chunks parse\n")
cat("Endpoints: 30 native tables, 3 figures, 1 TD Mermaid\n")
cat("Historical preparation manifest: 20 expected mismatches, 295 exact\n")
cat(
  "Profile adjacency, semantic hook, test/helper parse, and zero symlinks PASS\n"
)
cat("Disposition: concur for one companion-only render under order 47d\n")
