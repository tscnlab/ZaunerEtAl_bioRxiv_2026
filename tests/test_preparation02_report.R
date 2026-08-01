#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(file_arg) == 1L)
script_path <- sub("^--file=", "", file_arg)
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
qmd_path <- file.path(root, "notebooks/preparation/02_coverage_sample_flow.qmd")
lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")

fail <- function(message) stop(message, call. = FALSE)
expect_true <- function(condition, message) if (!isTRUE(condition)) fail(message)
count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1]]
  if (identical(matches, -1L)) 0L else length(matches)
}
extract_r_chunks <- function(source_lines) {
  chunks <- list()
  index <- 1L
  while (index <= length(source_lines)) {
    if (!grepl("^```\\{r(?:[,}])", source_lines[index], perl = TRUE)) {
      index <- index + 1L
      next
    }
    ends <- which(seq_along(source_lines) > index & grepl("^```[[:space:]]*$", source_lines))
    if (length(ends) == 0L) fail(paste("Unclosed R chunk at", index))
    end <- ends[1]
    chunks[[length(chunks) + 1L]] <- list(
      start = index,
      code = source_lines[seq.int(index + 1L, end - 1L)]
    )
    index <- end + 1L
  }
  chunks
}
strip_fenced_blocks <- function(source_lines) {
  keep <- character()
  inside <- FALSE
  for (line in source_lines) {
    if (grepl("^```", line)) inside <- !inside else if (!inside) keep <- c(keep, line)
  }
  paste(keep, collapse = "\n")
}

chunks <- extract_r_chunks(lines)
for (chunk in chunks) {
  code <- chunk$code[!grepl("^[[:space:]]*#\\|", chunk$code)]
  parsed <- try(parse(text = paste(code, collapse = "\n")), silent = TRUE)
  expect_true(!inherits(parsed, "try-error"), paste("R syntax failed at", chunk$start))
}
executable <- paste(unlist(lapply(chunks, `[[`, "code")), collapse = "\n")
forbidden <- c(
  "\\bbuild_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bverify_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bsource[[:space:]]*\\(",
  "\\b(write_[A-Za-z0-9_.]+|write\\.(csv|table)|writeLines)[[:space:]]*\\(",
  "\\b(saveRDS|save|dir\\.create|file\\.create|file\\.copy|unlink)[[:space:]]*\\(",
  "\\b(download\\.file|curl_fetch|GET|POST|system|system2)[[:space:]]*\\(",
  "\\b(lm|glm|gam|bam|lmer|glmer|glmmTMB|predict|acf|simulate|boot|bootstrap|shapley)[A-Za-z0-9_.]*[[:space:]]*\\("
)
for (pattern in forbidden) {
  expect_true(!grepl(pattern, executable, perl = TRUE, ignore.case = TRUE), paste("Forbidden executable pattern:", pattern))
}

full <- paste(lines, collapse = "\n")
visible <- strip_fenced_blocks(lines)
visible_no_code <- gsub("`[^`]*`", "", visible)
expect_true(grepl('title="What is calculated during this render?"', full, fixed = TRUE), "Missing render note.")
expect_true(!grepl("knitr::kable", full, fixed = TRUE), "kable remains.")
expect_true(grepl("library(gt)", executable, fixed = TRUE), "gt is not loaded.")
expect_true(grepl("melEDI", visible, fixed = TRUE), "melEDI is absent.")
expect_true(!grepl("\\bbout(s)?\\b", visible_no_code, perl = TRUE, ignore.case = TRUE), "Use period, not bout.")
expect_true(
  grepl("The separately predefined **gap-timing-unaware dataset** still passed the", visible, fixed = TRUE) &&
    grepl("general 50%-per-hour and 80%-per-day coverage rules", visible, fixed = TRUE) &&
    grepl("timing of remaining missing observations was not used for an additional", visible, fixed = TRUE),
  "Approved gap-timing-unaware explanation is incomplete."
)
expect_true(count_fixed(full, "time-sensitive primary metric dataset") == 1L, "Primary interpretation must appear once.")
expect_true(
  !grepl("\\b(V0|legacy|previous|canonical)\\b|manuscript-prepared", visible_no_code, perl = TRUE, ignore.case = TRUE),
  "Forbidden visible scenario label remains."
)

table_chunks <- Filter(function(x) any(grepl("^#\\| label: tbl-", x$code)), chunks)
expect_true(length(table_chunks) == 11L, "Expected exactly 11 gt tables.")
for (chunk in table_chunks) {
  expect_true(any(grepl("^#\\| tbl-cap: ", chunk$code)), paste("Missing caption at", chunk$start))
  expect_true(any(grepl("prep_gt[[:space:]]*\\(", chunk$code)), paste("Not a gt table at", chunk$start))
}

required_paths <- c(
  "artifacts/12_manifests/coverage_artifacts.csv",
  "artifacts/03_coverage/coverage_settings.csv",
  "artifacts/03_coverage/light_glasses_daily_coverage.csv",
  "artifacts/03_coverage/light_chest_daily_coverage.csv",
  "artifacts/03_coverage/light_glasses_hourly_coverage.csv",
  "artifacts/03_coverage/light_chest_hourly_coverage.csv",
  "artifacts/03_coverage/sample_flow.csv"
)
for (path in required_paths) expect_true(grepl(path, full, fixed = TRUE), paste("Missing path:", path))
required_scripts <- c(
  "scripts/pipeline/build_coverage_sample_flow.R",
  "scripts/pipeline/aggregation_coverage.R",
  "scripts/pipeline/verify_coverage_artifacts.R"
)
for (path in required_scripts) expect_true(grepl(path, full, fixed = TRUE), paste("Missing script:", path))
expect_true(
  grepl("`Step and producing code` ~ gt::pct(38)", full, fixed = TRUE) &&
    grepl("`Reads, operation, separation, and output` ~ gt::pct(62)", full, fixed = TRUE),
  "Script map width contract is missing."
)
expect_true(grepl("%%| label: fig-preparation02-chain", full, fixed = TRUE), "Missing chain figure.")
expect_true(grepl("%%| fig-cap:", full, fixed = TRUE), "Missing figure caption.")
expect_true(grepl("%%| fig-alt:", full, fixed = TRUE), "Missing figure alt text.")

if (length(args) >= 1L) {
  html <- paste(readLines(normalizePath(args[1], mustWork = TRUE), warn = FALSE), collapse = "\n")
  required_html <- c(
    "Preparation 02: Assess coverage and document sample flow",
    "tbl-preparation02-overall",
    "tbl-preparation02-script-map",
    "fig-preparation02-chain",
    "1,131,060",
    "1,253,505"
  )
  for (token in required_html) expect_true(grepl(token, html, fixed = TRUE), paste("HTML lacks:", token))
  expect_true(!grepl("# A tibble:", html, fixed = TRUE), "Raw tibble output is visible.")
}

cat("PASS: Preparation 02 source satisfies the bounded-render, terminology, gt-table, and provenance contract.\n")
