#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(file_arg) == 1L)
script_path <- sub("^--file=", "", file_arg)
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
qmd_path <- file.path(
  root,
  "notebooks/preparation/04_metric_derivation.qmd"
)
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
expect_true(length(chunks) == 15L, "Expected exactly 15 bounded R chunks.")
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
  "\\b(saveRDS|save|dir\\.create|file\\.create|file\\.copy|unlink)[[:space:]]*\\(",
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
  grepl(
    'title="What is calculated during this render?"',
    full,
    fixed = TRUE
  ),
  "Missing render-boundary note."
)
expect_true(!grepl("knitr::kable", full, fixed = TRUE), "kable remains.")
expect_true(grepl("library(gt)", executable, fixed = TRUE), "gt is not loaded.")
expect_true(grepl("melEDI", visible, fixed = TRUE), "melEDI is absent.")
expect_true(
  !grepl("\\bbout(s)?\\b", visible_no_code, perl = TRUE, ignore.case = TRUE),
  "Use period, not bout."
)
expect_true(
  !grepl(
    "\\b(V0|legacy|previous|canonical)\\b|manuscript-prepared",
    visible_no_code,
    perl = TRUE,
    ignore.case = TRUE
  ),
  "Forbidden reader-facing workflow label remains."
)

expect_true(
  grepl("gap-timing-unaware dataset", visible, fixed = TRUE),
  "Approved prepared-data sensitivity term is absent."
)
expect_true(
  grepl("50%-per-hour", visible, fixed = TRUE) &&
    grepl("80%-per-day", visible, fixed = TRUE) &&
    grepl(
      "timing of remaining[[:space:]]+missing observations was not used",
      visible,
      perl = TRUE
    ),
  "The first-use explanation of the gap-timing-unaware dataset is incomplete."
)
expect_true(
  grepl("time-sensitive primary metric dataset", visible, fixed = TRUE),
  "The permitted first-use contrast is absent."
)

current_hashes <- c(
  "6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8",
  "9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b",
  "755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619"
)
earlier_hashes <- c(
  "ac0325716421f2d90bb83b445ffb6ad965b131e382373e45f4ad6157eac5937d",
  "c4ecfab41892e44b38dd78097277ccef5f94a379b44c7b309de281e9215a7b3c",
  "944f395e00735e6f8200798d4cde387454441d39b9defda68f583bd8778cd34b"
)
for (hash in c(current_hashes, earlier_hashes)) {
  expect_true(grepl(hash, full, fixed = TRUE), paste("Missing hash:", hash))
}
expect_true(grepl("PREP-003", visible, fixed = TRUE), "PREP-003 is absent.")
expect_true(grepl("FIND-044", visible, fixed = TRUE), "FIND-044 is absent.")
expect_true(
  grepl(
    "must not be transferred to the three current manifests",
    visible,
    fixed = TRUE
  ),
  "Version-specific verification boundary is absent."
)
expect_true(
  grepl("not evidence", visible, fixed = TRUE) &&
    grepl("downstream", visible, fixed = TRUE),
  "The open audit item lacks its non-discrepancy qualification."
)

table_chunks <- Filter(
  function(chunk) any(grepl("^#\\| label: tbl-", chunk$code)),
  chunks
)
expect_true(length(table_chunks) == 13L, "Expected exactly 13 gt tables.")
for (chunk in table_chunks) {
  expect_true(
    any(grepl("^#\\| tbl-cap: ", chunk$code)),
    paste("Missing table caption at line", chunk$start)
  )
  expect_true(
    any(grepl("prep_gt[[:space:]]*\\(", chunk$code)),
    paste("Table is not built with gt at line", chunk$start)
  )
}
expect_true(
  grepl("`Step and producing code` ~ gt::pct(38)", full, fixed = TRUE) &&
    grepl(
      "`Reads, operation, separation, and output` ~ gt::pct(62)",
      full,
      fixed = TRUE
    ),
  "The script map is not the approved two-column layout."
)

required_paths <- c(
  "artifacts/12_manifests/metric_artifacts.csv",
  "artifacts/12_manifests/mder_support_gate_artifacts.csv",
  "artifacts/12_manifests/state_support_gate_artifacts.csv",
  "artifacts/05_metrics/metric_derivation_settings.csv",
  "artifacts/05_metrics/state_support_candidate_diagnostics.csv",
  "artifacts/08_diagnostics/mder_support_gate/mder_support_candidate_summary.csv",
  "artifacts/05_metrics/metrics_glasses_admissibility.csv",
  "artifacts/05_metrics/metrics_chest_admissibility.csv",
  "artifacts/05_metrics/metrics_glasses_gap_diagnostics.csv",
  "artifacts/05_metrics/metrics_chest_gap_diagnostics.csv"
)
for (path in required_paths) {
  expect_true(grepl(path, full, fixed = TRUE), paste("Missing path:", path))
}
required_scripts <- c(
  "scripts/pipeline/build_mder_support_gate.R",
  "scripts/pipeline/mder_support_gate.R",
  "scripts/pipeline/build_metric_derivation.R",
  "scripts/pipeline/metric_derivation.R",
  "scripts/pipeline/state_interval_projection.R",
  "scripts/pipeline/time_support.R"
)
for (path in required_scripts) {
  expect_true(grepl(path, full, fixed = TRUE), paste("Missing script:", path))
}

expect_true(
  grepl("#| label: fig-mder-support-retention", full, fixed = TRUE),
  "Missing empirical figure."
)
expect_true(grepl("#| fig-cap:", full, fixed = TRUE), "Missing figure caption.")
expect_true(grepl("#| fig-alt:", full, fixed = TRUE), "Missing figure alt text.")
expect_true(grepl("#| fig-width: 7.2", full, fixed = TRUE), "Wrong figure width.")
expect_true(grepl("#| fig-height: 4.2", full, fixed = TRUE), "Wrong figure height.")
expect_true(
  grepl("axis.text = element_text(size = 9", full, fixed = TRUE),
  "Axis text is below the REPORT-011 plan."
)
expect_true(
  grepl("legend.text = element_text(size = 9", full, fixed = TRUE),
  "Legend text is below the REPORT-011 plan."
)
expect_true(
  grepl(
    "[Download the source data for @fig-mder-support-retention](../../artifacts/08_diagnostics/mder_support_gate/mder_support_candidate_summary.csv)",
    full,
    fixed = TRUE
  ),
  "The empirical figure lacks its paired source-data link."
)

if (length(args) >= 1L) {
  html_path <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
  html <- paste(
    readLines(html_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  required_html <- c(
    "Preparation 04: Derive light-exposure metrics",
    "fig-mder-support-retention",
    "tbl-current-manifest-validation",
    "tbl-version-specific-verification",
    "FIND-044",
    "gap-timing-unaware dataset",
    "mder_support_candidate_summary.csv"
  )
  for (token in required_html) {
    expect_true(grepl(token, html, fixed = TRUE), paste("HTML lacks:", token))
  }
  expect_true(!grepl("# A tibble:", html, fixed = TRUE), "Raw tibble output is visible.")
}

cat(
  paste0(
    "PASS: Preparation 04 satisfies the bounded-render, version-specific ",
    "verification, gt-table, figure, terminology, and provenance contract.\n"
  )
)
