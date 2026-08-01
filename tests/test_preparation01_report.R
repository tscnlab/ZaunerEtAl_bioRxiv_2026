#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(file_arg) == 1L)
script_path <- sub("^--file=", "", file_arg)
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
qmd_path <- file.path(
  root,
  "notebooks/preparation/01_import_state_alignment.qmd"
)
stopifnot(file.exists(qmd_path))
lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")

fail <- function(message) stop(message, call. = FALSE)
expect_true <- function(condition, message) {
  if (!isTRUE(condition)) fail(message)
}

extract_r_chunks <- function(source_lines) {
  chunks <- list()
  index <- 1L
  while (index <= length(source_lines)) {
    if (!grepl("^```\\{r(?:[,}])", source_lines[index], perl = TRUE)) {
      index <- index + 1L
      next
    }
    end_candidates <- which(
      seq_along(source_lines) > index &
        grepl("^```[[:space:]]*$", source_lines)
    )
    if (length(end_candidates) == 0L) {
      fail(paste0("Unclosed R chunk beginning at line ", index, "."))
    }
    end <- end_candidates[1]
    chunks[[length(chunks) + 1L]] <- list(
      start = index,
      end = end,
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
    if (grepl("^```", line)) {
      inside <- !inside
    } else if (!inside) {
      keep <- c(keep, line)
    }
  }
  paste(keep, collapse = "\n")
}

r_chunks <- extract_r_chunks(lines)
expect_true(length(r_chunks) >= 15L, "Expected the setup and 14 table chunks.")

for (chunk in r_chunks) {
  code_lines <- chunk$code[!grepl("^[[:space:]]*#\\|", chunk$code)]
  parse_result <- try(parse(text = paste(code_lines, collapse = "\n")), silent = TRUE)
  expect_true(
    !inherits(parse_result, "try-error"),
    paste0("R syntax failed in chunk beginning at line ", chunk$start, ".")
  )
}

executable_code <- paste(
  unlist(lapply(r_chunks, function(chunk) chunk$code), use.names = FALSE),
  collapse = "\n"
)
forbidden_patterns <- c(
  "\\bbuild_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bverify_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bsource[[:space:]]*\\(",
  "\\b(write_[A-Za-z0-9_.]+|write\\.(csv|table)|writeLines)[[:space:]]*\\(",
  "\\b(saveRDS|save|dir\\.create|file\\.create|file\\.copy|file\\.rename|unlink)[[:space:]]*\\(",
  "\\b(download\\.file|curl_fetch|GET|POST|system|system2)[[:space:]]*\\(",
  "\\b(lm|glm|gam|bam|lmer|glmer|glmmTMB)[[:space:]]*\\(",
  "\\b(predict|acf|simulate|boot|bootstrap|shapley)[A-Za-z0-9_.]*[[:space:]]*\\("
)
for (pattern in forbidden_patterns) {
  expect_true(
    !grepl(pattern, executable_code, perl = TRUE, ignore.case = TRUE),
    paste0("Forbidden executable pattern in Preparation 01: ", pattern)
  )
}

full_source <- paste(lines, collapse = "\n")
visible_prose <- strip_fenced_blocks(lines)
visible_without_inline_code <- gsub("`[^`]*`", "", visible_prose)

expect_true(
  grepl(
    '::: {.callout-note appearance="simple" title="What is calculated during this render?"}',
    full_source,
    fixed = TRUE
  ),
  "Missing the informational render-boundary note."
)
expect_true(!grepl("knitr::kable", full_source, fixed = TRUE), "kable remains.")
expect_true(grepl("library(gt)", executable_code, fixed = TRUE), "gt is not loaded.")
expect_true(grepl("melEDI", visible_prose, fixed = TRUE), "melEDI terminology is absent.")
expect_true(
  !grepl("\\bbout(s)?\\b", visible_without_inline_code, perl = TRUE, ignore.case = TRUE),
  "Reader-facing prose must use period rather than bout."
)
expect_true(
  !grepl("\\bcanonical\\b", visible_without_inline_code, perl = TRUE, ignore.case = TRUE),
  "Opaque canonical terminology remains in visible prose."
)

table_chunks <- Filter(
  function(chunk) any(grepl("^#\\| label: tbl-", chunk$code)),
  r_chunks
)
expect_true(length(table_chunks) == 14L, "Expected exactly 14 reader-facing tables.")
for (chunk in table_chunks) {
  expect_true(
    any(grepl("^#\\| tbl-cap: ", chunk$code)),
    paste0("Table chunk at line ", chunk$start, " lacks a caption.")
  )
  expect_true(
    any(grepl("prep_gt[[:space:]]*\\(", chunk$code)),
    paste0("Table chunk at line ", chunk$start, " is not a gt table.")
  )
}

required_paths <- c(
  "artifacts/12_manifests/import_alignment_artifacts.csv",
  "artifacts/12_manifests/state_interval_artifacts.csv",
  "artifacts/12_manifests/pinned_downloads.csv",
  "artifacts/02_aligned/source_audit.csv",
  "artifacts/02_aligned/stream_epoch_audit.csv",
  "artifacts/02_aligned/state_interval_audit.csv",
  "artifacts/02_aligned/sample_audit.csv"
)
for (path in required_paths) {
  expect_true(grepl(path, full_source, fixed = TRUE), paste("Missing path:", path))
}

required_scripts <- c(
  "scripts/pipeline/build_import_alignment.R",
  "scripts/pipeline/import_sources.R",
  "scripts/pipeline/time_axes.R",
  "scripts/pipeline/aggregation_coverage.R",
  "scripts/pipeline/state_alignment.R",
  "scripts/pipeline/state_interval_projection.R",
  "scripts/pipeline/verify_import_alignment_artifacts.R"
)
for (path in required_scripts) {
  expect_true(grepl(path, full_source, fixed = TRUE), paste("Missing script:", path))
}

expect_true(
  grepl("`Step and producing code` ~ gt::pct(38)", full_source, fixed = TRUE) &&
    grepl(
      "`Reads, operation, separation, and output` ~ gt::pct(62)",
      full_source,
      fixed = TRUE
    ),
  "The script map must use the approved readable two-column layout."
)
expect_true(grepl("%%| label: fig-preparation01-chain", full_source, fixed = TRUE), "Missing chain figure label.")
expect_true(grepl("%%| fig-cap:", full_source, fixed = TRUE), "Missing chain figure caption.")
expect_true(grepl("%%| fig-alt:", full_source, fixed = TRUE), "Missing chain figure alt text.")

if (length(args) >= 1L) {
  html_path <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
  html <- paste(readLines(html_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  required_html <- c(
    "Preparation 01: Import and align light, sleep, and wear data",
    "tbl-preparation01-source-identity",
    "tbl-preparation01-script-map",
    "fig-preparation01-chain",
    "1,635,960",
    "1,798,560"
  )
  for (token in required_html) {
    expect_true(grepl(token, html, fixed = TRUE), paste("Rendered HTML lacks:", token))
  }
  expect_true(!grepl("# A tibble:", html, fixed = TRUE), "Raw tibble output is visible.")
}

cat(
  "PASS: Preparation 01 source satisfies the bounded-render, gt-table, terminology, and provenance contract.\n"
)
