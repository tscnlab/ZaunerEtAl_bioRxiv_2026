#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(cowplot)
  library(ggplot2)
  library(LightLogR)
  library(openssl)
  library(png)
  library(readr)
  library(scales)
})

args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args) >= 1L) args[[1L]] else getwd()
project_root <- normalizePath(project_root, mustWork = TRUE)
setwd(project_root)

fail <- function(message) {
  stop(message, call. = FALSE)
}

expect_true <- function(value, message) {
  if (!isTRUE(value)) {
    fail(message)
  }
}

sha256_file <- function(path) {
  connection <- file(path, "rb")
  on.exit(close(connection), add = TRUE)
  unclass(as.character(openssl::sha256(connection)))
}

qmd_path <- "audit/hypotheses/H06/H06_analysis_preparation.qmd"
source_path <- "artifacts/11_source_data/H06/H06_preparation_response_distribution.csv"
build_png <- paste0(
  "_build/nathealth/audit/hypotheses/H06/",
  "H06_analysis_preparation_files/figure-html/",
  "fig-h06-prep-response-distribution-1.png"
)
freeze_png <- paste0(
  ".quarto/_freeze/audit/hypotheses/H06/",
  "H06_analysis_preparation/figure-html/",
  "fig-h06-prep-response-distribution-1.png"
)
identity_path <- paste0(
  "audit/hypotheses/H06/report018_order47d_companion_render/",
  "figure_png_identity.csv"
)

expected_sha <- c(
  qmd = "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
  source = "d8ef3376d9bf72cbdd3a1d6519c4f567e23911c803dd738b528376413005afd4",
  build = "ab51417026d3b3edd9c0af7a455961b9e018cd0d4396bc6ba2f615ac98e7f7a1",
  freeze = "ab51417026d3b3edd9c0af7a455961b9e018cd0d4396bc6ba2f615ac98e7f7a1"
)
expected_paths <- c(qmd_path, source_path, build_png, freeze_png)
expect_true(
  all(file.exists(expected_paths)),
  "A required source or PNG path is missing."
)
actual_sha <- vapply(expected_paths, sha256_file, character(1))
expect_true(
  identical(unname(actual_sha), unname(expected_sha)),
  "A required source or PNG identity has drifted."
)

qmd_lines <- readLines(qmd_path, warn = FALSE)
label_index <- grep(
  "^#\\| label: fig-h06-prep-response-distribution$",
  qmd_lines
)
expect_true(
  length(label_index) == 1L,
  "The response-distribution chunk label is not unique."
)
opening_candidates <- which(
  seq_along(qmd_lines) < label_index & qmd_lines == "```{r}"
)
closing_candidates <- which(
  seq_along(qmd_lines) > label_index & qmd_lines == "```"
)
expect_true(
  length(opening_candidates) > 0L && length(closing_candidates) > 0L,
  "The figure chunk is not fenced."
)
opening_index <- max(opening_candidates)
closing_index <- min(closing_candidates)
chunk_lines <- qmd_lines[(opening_index + 1L):(closing_index - 1L)]
chunk_text <- paste(chunk_lines, collapse = "\n")
chunk_expression <- parse(text = chunk_text, keep.source = TRUE)

forbidden_calls <- c(
  "sample",
  "runif",
  "rnorm",
  "fit",
  "predict",
  "readRDS",
  "saveRDS",
  "write.csv",
  "write_csv",
  "ggsave",
  "source",
  "system",
  "system2"
)
chunk_names <- all.names(chunk_expression, functions = TRUE, unique = TRUE)
expect_true(
  !any(forbidden_calls %in% chunk_names),
  "The accepted figure chunk contains a random, inferential, write, or system call."
)
required_mappings <- c(
  "positive_p10_lx",
  "positive_p90_lx",
  "positive_p25_lx",
  "positive_p75_lx",
  "positive_median_lx",
  "positive_p99_lx",
  "exact_zero_fraction",
  "placement"
)
expect_true(
  all(required_mappings %in% chunk_names),
  "The accepted figure chunk does not retain every frozen display mapping."
)

response_distribution <- readr::read_csv(source_path, show_col_types = FALSE)
expect_true(
  nrow(response_distribution) == 2L,
  "The frozen source does not have two rows."
)
expect_true(
  identical(response_distribution$placement, c("Near-eye", "Chest")),
  "The frozen placement order has changed."
)
expect_true(
  identical(response_distribution$exact_zero_hours, c(4697, 5337)),
  "The frozen exact-zero counts have changed."
)
expect_true(
  isTRUE(all.equal(
    response_distribution$exact_zero_fraction,
    c(0.28302000482043865, 0.2908129904097646),
    tolerance = 0
  )),
  "The frozen exact-zero fractions have changed."
)

evaluation_environment <- new.env(parent = globalenv())
evaluation_environment$response_distribution <- response_distribution
evaluation_environment$placement_colors <- c(
  "Near-eye" = "#0072B2",
  "Chest" = "#D55E00"
)
display <- eval(chunk_expression, envir = evaluation_environment)

candidate_path <- tempfile(
  "h06_order47d_response_reproduction_",
  fileext = ".png"
)
on.exit(unlink(candidate_path), add = TRUE)
grDevices::png(
  filename = candidate_path,
  width = 10,
  height = 5.8,
  units = "in",
  res = 192
)
print(display)
grDevices::dev.off()

expect_true(
  identical(sha256_file(candidate_path), expected_sha[["build"]]),
  "The independent R reproduction is not byte-identical to the current build PNG."
)
expect_true(
  identical(as.numeric(file.info(candidate_path)$size), 105561),
  "The independent reproduction byte count is not 105,561."
)

for (path in c(candidate_path, build_png, freeze_png)) {
  image <- png::readPNG(path, info = TRUE)
  expect_true(
    identical(c(dim(image)[[2L]], dim(image)[[1L]]), c(1920L, 1113L)),
    paste("Unexpected PNG dimensions:", path)
  )
}

identity <- read.csv(
  identity_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
expect_true(
  nrow(identity) == 3L,
  "The owner figure identity table does not have three rows."
)
response_row <- identity[
  identity$figure_id == "fig-h06-prep-response-distribution",
  ,
  drop = FALSE
]
expect_true(
  nrow(response_row) == 1L,
  "The response-distribution identity row is not unique."
)
expect_true(
  identical(
    response_row$expected_sha256[[1L]],
    "5cf25ad6cef9840e78a217ab083ca816105eacb37568ac788d3cd82c4bc31f46"
  ) &&
    identical(response_row$live_sha256[[1L]], expected_sha[["build"]]) &&
    identical(response_row$expected_bytes[[1L]], 105897L) &&
    identical(response_row$live_bytes[[1L]], 105561L) &&
    identical(response_row$expected_width[[1L]], 1920L) &&
    identical(response_row$live_width[[1L]], 1920L) &&
    identical(response_row$expected_height[[1L]], 1113L) &&
    identical(response_row$live_height[[1L]], 1113L),
  "The sealed pre/post response-distribution identity row is not exact."
)

unchanged_rows <- identity[
  identity$figure_id != "fig-h06-prep-response-distribution",
  ,
  drop = FALSE
]
expect_true(
  nrow(unchanged_rows) == 2L,
  "The two neighboring figure rows are absent."
)
expect_true(
  all(unchanged_rows$expected_sha256 == unchanged_rows$live_sha256) &&
    all(unchanged_rows$expected_bytes == unchanged_rows$live_bytes),
  "A neighboring target-generated figure changed."
)

cat("H06 order 47d response-PNG delta classification PASS\n")
cat("R version:", R.version.string, "\n")
cat("Frozen source:", expected_sha[["source"]], "with 2/2 placement rows\n")
cat("Current build and freeze PNG:", expected_sha[["build"]], "\n")
cat(
  "Independent exact-chunk reproduction: byte-identical, 105561 bytes, 1920 x 1113\n"
)
cat("Neighboring companion PNGs: 2/2 unchanged\n")
cat("Disposition: expected target-owned deterministic regeneration\n")
