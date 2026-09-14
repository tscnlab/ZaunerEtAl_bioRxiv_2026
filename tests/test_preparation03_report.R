#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(file_arg) == 1L)
script_path <- sub("^--file=", "", file_arg)
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
qmd_path <- file.path(
  root,
  "notebooks/preparation/03_reference_profiles.qmd"
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
expect_true(length(chunks) >= 12L, "Expected at least 12 bounded R chunks.")
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
  "\\b(lm|glm|gam|bam|lmer|glmer|glmmTMB|predict|acf|simulate|boot|bootstrap|shapley)[A-Za-z0-9_.]*[[:space:]]*\\("
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

current_hash <-
  "5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062"
preceding_hash <-
  "c8e02302521360d3a5cb18f49e0a97aed4a1f0ea64343ead68bde274cddce10d"
mder_decision_hash <-
  "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de"
expect_true(grepl(current_hash, full, fixed = TRUE), "Current manifest is absent.")
expect_true(
  grepl(preceding_hash, full, fixed = TRUE),
  "Preceding verified manifest is absent."
)
expect_true(
  grepl("applied to the **preceding** manifest", visible, fixed = TRUE),
  "The 394-of-394 result is not version-specific."
)
expect_true(
  grepl("It must not", visible, fixed = TRUE) &&
    grepl("current manifest", visible, fixed = TRUE),
  "The preceding verification could be transferred to the current manifest."
)
expect_true(grepl("PREP-002", visible, fixed = TRUE), "PREP-002 is absent.")
expect_true(grepl("FIND-043", visible, fixed = TRUE), "FIND-043 is absent.")
expect_true(
  grepl(
    "This incomplete provenance check is not evidence",
    visible,
    fixed = TRUE
  ) &&
    grepl(
      "a current[[:space:]]+profile, metric, or downstream result is incorrect",
      visible,
      perl = TRUE
    ),
  "The open audit item lacks its non-discrepancy qualification."
)
expect_true(
  grepl(
    "No[[:space:]]+reference profile weights, scales, or gates",
    visible,
    perl = TRUE
  ) &&
    grepl(
      "not active Preparation 04[[:space:]]+inputs for MDER",
      visible,
      perl = TRUE
    ),
  "Preparation 03 does not clearly retire profile-based MDER support."
)
expect_true(
  !grepl(
    "The MDER maps require paired melEDI and illuminance observations",
    visible,
    fixed = TRUE
  ),
  "The superseded MDER-map claim remains visible."
)
decision_path <- file.path(root, "audit/decisions/mder_mean_of_viable_ratios.md")
expect_true(file.exists(decision_path), "The controlling MDER decision is missing.")
expect_true(
  identical(
    digest::digest(file = decision_path, algo = "sha256"),
    mder_decision_hash
  ),
  "The controlling MDER decision identity changed."
)

table_chunks <- Filter(
  function(chunk) any(grepl("^#\\| label: tbl-", chunk$code)),
  chunks
)
expect_true(length(table_chunks) == 11L, "Expected exactly 11 gt tables.")
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
  "artifacts/12_manifests/reference_profile_artifacts.csv",
  "artifacts/04_reference_profiles/reference_profile_settings.csv",
  "artifacts/04_reference_profiles/reference_profile_input_provenance.csv",
  "artifacts/04_reference_profiles/reference_profile_support.csv",
  "artifacts/04_reference_profiles/timing_exceedance_distribution_support.csv",
  "artifacts/04_reference_profiles/relevance_map_support.csv",
  "artifacts/04_reference_profiles/reference_profiles.csv",
  "artifacts/04_reference_profiles/timing_exceedance_distributions.csv",
  "artifacts/04_reference_profiles/metric_relevance_maps.csv"
)
for (path in required_paths) {
  expect_true(grepl(path, full, fixed = TRUE), paste("Missing path:", path))
}
required_scripts <- c(
  "scripts/pipeline/build_reference_profiles.R",
  "scripts/pipeline/reference_profiles.R",
  "scripts/pipeline/verify_reference_profile_artifacts.R"
)
for (path in required_scripts) {
  expect_true(grepl(path, full, fixed = TRUE), paste("Missing script:", path))
}

expect_true(
  grepl("#| label: fig-pooled-reference-profiles", full, fixed = TRUE),
  "Missing empirical figure."
)
expect_true(grepl("#| fig-cap:", full, fixed = TRUE), "Missing figure caption.")
expect_true(grepl("#| fig-alt:", full, fixed = TRUE), "Missing figure alt text.")
expect_true(grepl("#| fig-width: 7.6", full, fixed = TRUE), "Wrong figure width.")
expect_true(grepl("#| fig-height: 5.4", full, fixed = TRUE), "Wrong figure height.")
expect_true(
  grepl("axis.text = element_text(size = 9", full, fixed = TRUE),
  "Axis text is below the REPORT-011 plan."
)
expect_true(
  grepl("legend.text = element_text(size = 9", full, fixed = TRUE),
  "Legend text is below the REPORT-011 plan."
)
expect_true(
  grepl("strip.text = element_text(size = 10", full, fixed = TRUE),
  "Facet text is below the REPORT-011 plan."
)
expect_true(
  grepl(
    "[Download the source data for @fig-pooled-reference-profiles](../../artifacts/04_reference_profiles/reference_profiles.csv)",
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
    "Preparation 03: Learn fixed time-of-day reference profiles",
    "fig-pooled-reference-profiles",
    "tbl-current-validation",
    "tbl-script-execution-map",
    "FIND-043",
    "394 of 394",
    "reference_profiles.csv"
  )
  for (token in required_html) {
    expect_true(grepl(token, html, fixed = TRUE), paste("HTML lacks:", token))
  }
  expect_true(!grepl("# A tibble:", html, fixed = TRUE), "Raw tibble output is visible.")
}

cat(
  paste0(
    "PASS: Preparation 03 satisfies the bounded-render, version-specific ",
    "verification, gt-table, figure, and provenance contract.\n"
  )
)
