#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(
  file.path(dirname(commandArgs(trailingOnly = FALSE)[1]), ".."),
  winslash = "/",
  mustWork = TRUE
)

# Rscript reports the script path as --file=... rather than as argv[1].
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(file_arg) == 1L) {
  script_path <- sub("^--file=", "", file_arg)
  root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
}

qmd_path <- file.path(
  root,
  "notebooks/preparation/06_model_ready_datasets.qmd"
)
stopifnot(file.exists(qmd_path))
lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")

fail <- function(message) {
  stop(message, call. = FALSE)
}

expect_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    fail(message)
  }
}

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
expect_true(length(r_chunks) >= 15L, "Expected at least 15 bounded R chunks.")

for (chunk in r_chunks) {
  code_lines <- chunk$code[!grepl("^[[:space:]]*#\\|", chunk$code)]
  code_text <- paste(code_lines, collapse = "\n")
  parse_result <- try(parse(text = code_text), silent = TRUE)
  expect_true(
    !inherits(parse_result, "try-error"),
    paste0("R syntax failed in chunk beginning at line ", chunk$start, ".")
  )
}

executable_code <- paste(
  unlist(lapply(r_chunks, function(chunk) chunk$code), use.names = FALSE),
  collapse = "\n"
)

forbidden_executable_patterns <- c(
  "\\bbuild_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bverify_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bsource[[:space:]]*\\(",
  "\\b(write_[A-Za-z0-9_.]+|write\\.(csv|table)|writeLines)[[:space:]]*\\(",
  "\\b(saveRDS|save|dir\\.create|file\\.create|file\\.copy|file\\.rename|unlink)[[:space:]]*\\(",
  "\\b(download\\.file|curl_fetch|GET|POST|system|system2)[[:space:]]*\\(",
  "\\b(lm|glm|gam|bam|lmer|glmer|glmmTMB)[[:space:]]*\\(",
  "\\b(predict|acf|simulate|boot|bootstrap|shapley)[A-Za-z0-9_.]*[[:space:]]*\\(",
  "\\bquarto_render[[:space:]]*\\("
)

for (pattern in forbidden_executable_patterns) {
  expect_true(
    !grepl(pattern, executable_code, perl = TRUE, ignore.case = TRUE),
    paste0("Forbidden executable pattern in Preparation 06: ", pattern)
  )
}

full_source <- paste(lines, collapse = "\n")
visible_prose <- strip_fenced_blocks(lines)
visible_without_inline_code <- gsub("`[^`]*`", "", visible_prose)

expect_true(
  grepl(
    "The predefined **gap-timing-unaware dataset** still passed the general",
    visible_prose,
    fixed = TRUE
  ),
  "Missing the approved first-use dataset explanation."
)
expect_true(
  grepl(
    "50%-per-hour and 80%-per-day coverage rules",
    visible_prose,
    fixed = TRUE
  ),
  "Missing the general coverage rules in the first explanation."
)
expect_true(
  grepl(
    "remaining missing observations was not used for an additional metric-specific",
    visible_prose,
    fixed = TRUE
  ),
  "Missing the meaning of gap-timing-unaware."
)
expect_true(
  count_fixed(full_source, "time-sensitive primary metric dataset") == 1L,
  "The one-time primary-dataset interpretation must occur exactly once."
)
expect_true(
  !grepl(
    "\\b(V0|legacy|previous|canonical)\\b",
    visible_without_inline_code,
    perl = TRUE,
    ignore.case = TRUE
  ),
  "A forbidden visible scenario/workflow label remains."
)
expect_true(
  !grepl("manuscript-prepared", visible_without_inline_code, ignore.case = TRUE),
  "The historical scenario label remains in visible prose."
)
expect_true(
  !grepl("\\bbout(s)?\\b", visible_without_inline_code, perl = TRUE, ignore.case = TRUE),
  "Reader-facing prose must use period rather than bout."
)
expect_true(grepl("melEDI", visible_prose, fixed = TRUE), "melEDI terminology is absent.")

expect_true(
  grepl(
    '::: {.callout-note appearance="simple" title="What is calculated during this render?"}',
    full_source,
    fixed = TRUE
  ),
  "Missing the informational render-boundary note."
)
expect_true(!grepl("knitr::kable", full_source, fixed = TRUE), "kable remains in the report.")
expect_true(grepl("library(gt)", executable_code, fixed = TRUE), "gt is not loaded.")
expect_true(
  grepl("`Step and producing code` ~ gt::pct(38)", full_source, fixed = TRUE) &&
    grepl(
      "`Reads, operation, separation, and output` ~ gt::pct(62)",
      full_source,
      fixed = TRUE
    ),
  "The script execution map must retain its approved two-column layout."
)

table_chunks <- Filter(
  function(chunk) any(grepl("^#\\| label: tbl-", chunk$code)),
  r_chunks
)
expect_true(length(table_chunks) >= 12L, "Expected at least 12 reader-facing tables.")
for (chunk in table_chunks) {
  expect_true(
    any(grepl("^#\\| tbl-cap: ", chunk$code)),
    paste0("Table chunk at line ", chunk$start, " lacks a Quarto caption.")
  )
  expect_true(
    any(grepl("prep_gt[[:space:]]*\\(", chunk$code)),
    paste0("Table chunk at line ", chunk$start, " is not a gt table.")
  )
}

required_paths <- c(
  "artifacts/12_manifests/model_input_normalization.csv",
  "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
  "artifacts/12_manifests/site_solar_context_artifacts.csv",
  "artifacts/06_model_data/temporal_provenance/artifact_manifest.csv",
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  "artifacts/12_manifests/H01_model_data_artifacts.csv",
  "artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv",
  "artifacts/12_manifests/preanalysis_comparison_artifacts.csv"
)
for (path in required_paths) {
  expect_true(grepl(path, full_source, fixed = TRUE), paste("Missing path:", path))
}

required_scripts <- c(
  "scripts/pipeline/build_model_input_normalization.R",
  "scripts/pipeline/build_manuscript_prepared_data.R",
  "scripts/pipeline/build_site_solar_context.R",
  "scripts/pipeline/build_temporal_sequence_provenance.R",
  "scripts/pipeline/build_base_model_data.R",
  "scripts/pipeline/build_h01_model_data.R",
  "scripts/pipeline/build_h01_manuscript_prepared_data.R",
  "scripts/pipeline/build_preanalysis_comparison.R"
)
for (path in required_scripts) {
  expect_true(grepl(path, full_source, fixed = TRUE), paste("Missing script:", path))
}

expect_true(grepl("#| label: fig-site-composition", full_source, fixed = TRUE), "Missing figure label.")
expect_true(grepl("#| fig-cap:", full_source, fixed = TRUE), "Missing figure caption.")
expect_true(grepl("#| fig-alt:", full_source, fixed = TRUE), "Missing figure alt text.")
expect_true(grepl("#| fig-width: 7.5", full_source, fixed = TRUE), "Unexpected figure width.")
expect_true(grepl("#| fig-height: 6.8", full_source, fixed = TRUE), "Unexpected figure height.")
expect_true(grepl("axis.text = element_text(size = 9", full_source, fixed = TRUE), "Axis text is below the planned size.")
expect_true(grepl("strip.text = element_text(size = 10", full_source, fixed = TRUE), "Facet text is below the planned size.")
expect_true(grepl("config/site_display_registry.csv", full_source, fixed = TRUE), "Site display registry is not used.")
expect_true(grepl("scale_fill_manual", executable_code, fixed = TRUE), "Registered site colours are not applied.")
expect_true(
  grepl(
    "[Download the source data for @fig-site-composition](../../artifacts/08_diagnostics/preanalysis_comparison/categorical_levels.csv)",
    full_source,
    fixed = TRUE
  ),
  "The figure lacks its paired source-data link."
)
expect_true(
  !grepl("categorical_distribution_overview.png", full_source, fixed = TRUE),
  "The old figure with historical visible labels remains embedded."
)
expect_true(grepl("REPORT-011", visible_prose, fixed = TRUE), "REPORT-011 QA is not declared.")

if (length(args) >= 1L) {
  html_path <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
  html <- paste(readLines(html_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  required_html_tokens <- c(
    "Preparation 06: Build model-ready datasets",
    "fig-site-composition",
    "tbl-manifest-identity",
    "tbl-script-execution-map",
    "categorical_levels.csv",
    "gap-timing-unaware dataset"
  )
  for (token in required_html_tokens) {
    expect_true(grepl(token, html, fixed = TRUE), paste("Rendered HTML lacks:", token))
  }
  expect_true(!grepl("# A tibble:", html, fixed = TRUE), "Raw tibble output is visible in HTML.")
  expect_true(!grepl("manuscript-prepared", html, ignore.case = TRUE), "Historical scenario label is visible in HTML.")
}

cat(
  "PASS: Preparation 06 source satisfies the bounded-render, terminology, gt-table, figure, and provenance contract.\n"
)
