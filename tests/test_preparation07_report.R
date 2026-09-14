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
visible_flat <- gsub("[[:space:]]+", " ", visible)
approved_equivalence_explanation <- paste(
  "The stored example-day display was created from an earlier version of the",
  "site/daylight-context file. The accepted current file contains the same",
  "site/daylight values used here; only file-level provenance metadata changed."
)

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
for (token in c(
  "870cbb5d5f9414f61ee7db05b61a12eb51d56c9273e9ae7dfd05094984c47164",
  "0757fc175c44fd33e9d8b06e4f9352699c18bfe50bbcf1c65d141f3f36a1cb97",
  "01a07b87799faeb8291bb6187ced96ab7abdcf2399ee77c5dcfd19d608b1194c",
  "b0e8de539572ee595cc91027e7a2d919ba01237f780e50a76e5e4468d497c4bf",
  "39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0",
  "7dc64cc5026947ef96d6e4ab112bb767414420be97817f022082248db68d7028"
)) {
  expect_true(grepl(token, full, fixed = TRUE), paste("Missing identity:", token))
}
for (path in c(
  "artifacts/03_coverage/light_glasses_coverage.rds",
  "artifacts/06_model_data/context/site_solar_context.rds",
  "artifacts/06_model_data/context/site_solar_context.csv",
  "config/site_metadata.csv",
  "config/site_display_registry.csv",
  "artifacts/12_manifests/prepared_day_showcase_artifacts.csv",
  "artifacts/08_diagnostics/prepared_day_showcase/selected_days.csv",
  "artifacts/08_diagnostics/prepared_day_showcase/eligible_day_counts.csv",
  "artifacts/08_diagnostics/prepared_day_showcase/selection_settings.csv",
  "artifacts/11_source_data/prepared_day_showcase.csv",
  "artifacts/10_figures/prepared_day_showcase.png",
  "artifacts/10_figures/prepared_day_showcase.svg",
  "audit/reconciliation/preparation07/site_solar_context_equivalence_audit.md",
  "audit/reconciliation/preparation07/site_solar_context_equivalence_evidence.csv",
  "audit/reconciliation/preparation07/site_solar_context_equivalence_manifest.csv"
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

expect_true(
  grepl(approved_equivalence_explanation, visible_flat, fixed = TRUE),
  "The approved site/daylight-context explanation is absent."
)
expect_true(
  grepl("Equivalent values, different file version", full, fixed = TRUE),
  "The plain site/daylight-context equivalence label is absent."
)
for (token in c(
  "nrow(equivalence_evidence) == 17L",
  "sum(equivalence_evidence$status == \"PASS\") == 16L",
  "EXPECTED_PROVENANCE_FAIL_ONLY",
  "17 PASS and manifest::input_hashes FAIL",
  "618 rows; 47 columns; zero changed cells",
  "9 keys and 4 fields exactly equal as stored strings",
  "nrow(equivalence_seal) == 2L",
  "all(equivalence_seal$r_version == \"4.6.1\")",
  "all(equivalence_seal$status == \"PASS\")"
)) {
  expect_true(
    grepl(token, full, fixed = TRUE),
    paste("Missing stored-evidence contract:", token)
  )
}

for (token in c(
  "display-only inspection",
  "no hypothesis-analysis handoff",
  "12,960",
  "1,440",
  "50% valid observations",
  "80% valid observations"
)) {
  expect_true(grepl(token, visible, fixed = TRUE), paste("Missing statement:", token))
}
for (token in c(
  "none enters an H01–H11 model",
  "selection was not repeated",
  "does not repeat the selection"
)) {
  expect_true(
    grepl(token, visible_flat, fixed = TRUE),
    paste("Missing visible semantic statement:", token)
  )
}
expect_true(
  grepl("unique(manifest$seed) == 20260730L", full, fixed = TRUE),
  "The fixed-seed source assertion is absent."
)
expect_true(
  grepl(
    "The full production verifier is deliberately not rerun here because",
    full,
    fixed = TRUE
  ),
  "The full-source verifier-not-rerun assertion is absent."
)

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
  grepl("legend.title = ggplot2::element_text(size = 10)", full, fixed = TRUE) &&
    grepl("legend.text = ggplot2::element_text(size = 10)", full, fixed = TRUE) &&
    grepl(
      "strip\\.text\\s*=\\s*ggplot2::element_text\\(\\s*size\\s*=\\s*10\\s*,",
      full,
      perl = TRUE
    ) &&
    grepl("axis.text = ggplot2::element_text(size = 10)", full, fixed = TRUE) &&
    grepl("axis.title = ggplot2::element_text(size = 10)", full, fixed = TRUE),
  "REPORT-011 figure typography contract is absent."
)
expect_true(
  grepl("figure source-data CSV", visible_flat, fixed = TRUE) &&
    grepl("split into three three-panel figures", visible_flat, fixed = TRUE),
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
  html_unwrapped <- gsub("\u200b", "", html, fixed = TRUE)
  html_flat <- gsub("[[:space:]]+", " ", html_unwrapped)
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
    grepl(approved_equivalence_explanation, html_flat, fixed = TRUE),
    "HTML lacks the approved site/daylight-context explanation."
  )
  for (token in c(
    "Equivalent values, different file version",
    "audit/reconciliation/preparation07/site_solar_context_equivalence_audit.md",
    "audit/reconciliation/preparation07/site_solar_context_equivalence_evidence.csv",
    "audit/reconciliation/preparation07/site_solar_context_equivalence_manifest.csv",
    "870cbb5d5f9414f61ee7db05b61a12eb51d56c9273e9ae7dfd05094984c47164",
    "0757fc175c44fd33e9d8b06e4f9352699c18bfe50bbcf1c65d141f3f36a1cb97",
    "01a07b87799faeb8291bb6187ced96ab7abdcf2399ee77c5dcfd19d608b1194c",
    "b0e8de539572ee595cc91027e7a2d919ba01237f780e50a76e5e4468d497c4bf",
    "39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0"
  )) {
    expect_true(
      grepl(token, html_unwrapped, fixed = TRUE),
      paste("HTML lacks provenance reconciliation token:", token)
    )
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
