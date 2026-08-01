#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(file_arg) == 1L)
script_path <- sub("^--file=", "", file_arg)
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
qmd_path <- file.path(root, "notebooks/preparation/07_example_days.qmd")
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
      fail(paste("Unclosed R chunk beginning at line", index))
    }
    end <- end_candidates[1]
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
    if (grepl("^```", line)) {
      inside <- !inside
    } else if (!inside) {
      keep <- c(keep, line)
    }
  }
  paste(keep, collapse = "\n")
}

chunks <- extract_r_chunks(lines)
expect_true(length(chunks) == 11L, "Expected exactly 11 bounded R chunks.")
for (chunk in chunks) {
  code <- chunk$code[!grepl("^[[:space:]]*#\\|", chunk$code)]
  parsed <- try(parse(text = paste(code, collapse = "\n")), silent = TRUE)
  expect_true(
    !inherits(parsed, "try-error"),
    paste("R syntax failed in chunk beginning at line", chunk$start)
  )
}

executable <- paste(
  unlist(lapply(chunks, `[[`, "code"), use.names = FALSE),
  collapse = "\n"
)
forbidden <- c(
  "\\bbuild_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bverify_[A-Za-z0-9_.]+[[:space:]]*\\(",
  "\\bsource[[:space:]]*\\(",
  "\\b(write_[A-Za-z0-9_.]+|write\\.(csv|table)|writeLines)[[:space:]]*\\(",
  "\\b(saveRDS|save|load|readRDS|dir\\.create|file\\.create|file\\.copy|unlink)[[:space:]]*\\(",
  "\\b(download\\.file|curl_fetch|GET|POST|system|system2)[[:space:]]*\\(",
  paste0(
    "\\b(lm|glm|gam|bam|lmer|glmer|glmmTMB|predict|acf|simulate|boot|",
    "bootstrap|shapley)[A-Za-z0-9_.]*[[:space:]]*\\("
  )
)
for (pattern in forbidden) {
  expect_true(
    !grepl(pattern, executable, perl = TRUE, ignore.case = TRUE),
    paste("Forbidden executable pattern:", pattern)
  )
}

full <- paste(lines, collapse = "\n")
visible <- strip_fenced_blocks(lines)
visible_no_code <- gsub("`[^`]*`", "", visible)

expect_true(
  grepl('title="What is calculated during this render?"', full, fixed = TRUE),
  "Missing render-boundary note."
)
expect_true(!grepl("knitr::kable", full, fixed = TRUE), "kable remains.")
expect_true(grepl("library(gt)", executable, fixed = TRUE), "gt is not loaded.")
expect_true(
  !grepl("\\bbout(s)?\\b", visible_no_code, perl = TRUE, ignore.case = TRUE),
  "Use period, not bout."
)
expect_true(
  !grepl(
    "\\b(V0|legacy|previous|canonical)\\b|manuscript-prepared|alternative preparation",
    visible_no_code,
    perl = TRUE,
    ignore.case = TRUE
  ),
  "Forbidden reader-facing workflow label remains."
)

expect_true(
  grepl(
    "c5ca66b2a6ec4fabbe57d08135db7f365bcd123365caab6c987bcb2b62f7a322",
    full,
    fixed = TRUE
  ),
  "Current showcase manifest identity is absent."
)
for (path in c(
  "artifacts/03_coverage/light_glasses_coverage.rds",
  "artifacts/06_model_data/context/site_solar_context.rds",
  "config/site_metadata.csv",
  "config/site_display_registry.csv",
  "artifacts/12_manifests/prepared_day_showcase_artifacts.csv",
  "artifacts/08_diagnostics/prepared_day_showcase/selected_days.csv",
  "artifacts/08_diagnostics/prepared_day_showcase/eligible_day_counts.csv",
  "artifacts/08_diagnostics/prepared_day_showcase/selection_settings.csv",
  "artifacts/11_source_data/prepared_day_showcase.csv",
  "artifacts/10_figures/prepared_day_showcase.png",
  "artifacts/10_figures/prepared_day_showcase.svg"
)) {
  expect_true(grepl(path, full, fixed = TRUE), paste("Missing path:", path))
}
for (path in c(
  "scripts/pipeline/build_prepared_day_showcase.R",
  "scripts/pipeline/prepared_day_showcase.R",
  "scripts/pipeline/verify_prepared_day_showcase_artifacts.R"
)) {
  expect_true(grepl(path, full, fixed = TRUE), paste("Missing script:", path))
}

for (token in c(
  "display-only inspection",
  "None of the Preparation 07",
  "no hypothesis-analysis handoff",
  "does not rerun the fixed-seed selection",
  "does not rerun",
  "12,960",
  "1,440",
  "20260730",
  "50% valid observations",
  "80% valid observations"
)) {
  expect_true(grepl(token, visible, fixed = TRUE), paste("Missing statement:", token))
}

table_chunks <- Filter(
  function(chunk) any(grepl("^#\\| label: tbl-", chunk$code)),
  chunks
)
expect_true(length(table_chunks) == 7L, "Expected exactly seven gt tables.")
for (chunk in table_chunks) {
  expect_true(
    any(grepl("^#\\| tbl-cap: ", chunk$code)),
    paste("Table lacks a Quarto caption near line", chunk$start)
  )
  expect_true(
    grepl("prep_gt\\(", paste(chunk$code, collapse = "\n"), perl = TRUE),
    paste("Table does not use prep_gt near line", chunk$start)
  )
}

figure_chunks <- Filter(
  function(chunk) any(grepl("^#\\| label: fig-example-days-", chunk$code)),
  chunks
)
expect_true(length(figure_chunks) == 3L, "Expected exactly three profile figures.")
for (chunk in figure_chunks) {
  expect_true(
    any(grepl("^#\\| fig-cap: ", chunk$code)),
    paste("Figure lacks a caption near line", chunk$start)
  )
  expect_true(
    any(grepl("^#\\| fig-alt: ", chunk$code)),
    paste("Figure lacks alt text near line", chunk$start)
  )
  expect_true(
    any(grepl('^#\\| out-width: "100%"', chunk$code)),
    paste("Figure lacks final-width sizing near line", chunk$start)
  )
}
expect_true(
  grepl("axis.text = ggplot2::element_text(size = 9)", full, fixed = TRUE) &&
    grepl("strip.text = ggplot2::element_text(", full, fixed = TRUE) &&
    grepl("size = 9.5", full, fixed = TRUE) &&
    grepl("legend.text = ggplot2::element_text(size = 9)", full, fixed = TRUE),
  "REPORT-011 figure typography contract is absent."
)
expect_true(
  grepl("figure source-data CSV", visible, fixed = TRUE) &&
    grepl("split into three three-panel figures", visible, fixed = TRUE),
  "The readable figure split or paired source-data statement is absent."
)
expect_true(
  grepl("arrange(.data$display_order)", executable, fixed = TRUE) &&
    grepl(".data$color_hex", executable, fixed = TRUE),
  "Submitted site order and colours are not used."
)

if (length(args) >= 1L) {
  html_path <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
  html <- paste(
    readLines(html_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  for (token in c(
    "Preparation 07: Inspect example days from each study site",
    "tbl-example-day-inputs",
    "tbl-example-day-scripts",
    "tbl-example-day-current-checks",
    "fig-example-days-1",
    "fig-example-days-2",
    "fig-example-days-3",
    "12,960",
    "20260730",
    "no hypothesis-analysis handoff",
    "Borås (SE)",
    "Delft (NL)",
    "Dortmund (DE)",
    "Tübingen (DE)",
    "Munich (DE)",
    "Madrid (ES)",
    "Izmir (TR)",
    "San José (CR)",
    "Kumasi (GH)"
  )) {
    expect_true(grepl(token, html, fixed = TRUE), paste("HTML lacks:", token))
  }
  expect_true(
    lengths(regmatches(html, gregexpr('<table class="gt_table ', html, fixed = TRUE))) == 7L,
    "Rendered HTML does not contain exactly seven gt tables."
  )
  expect_true(!grepl("# A tibble:", html, fixed = TRUE), "Raw tibble output is visible.")
  expect_true(
    !grepl("WARNING \\(\\?@", html, perl = TRUE) &&
      !grepl("WARNING: Unable to resolve crossref", html, fixed = TRUE),
    "Rendered HTML contains an unresolved cross-reference warning."
  )
}

cat(
  paste0(
    "PASS: Preparation 07 satisfies the bounded-render, fixed-input, ",
    "gt-table, accessible-figure, site-display, and provenance contract.\n"
  )
)
