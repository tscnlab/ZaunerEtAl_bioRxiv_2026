#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(file_arg) == 1L)
script_path <- sub("^--file=", "", file_arg)
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
qmd_path <- file.path(
  root,
  "notebooks/preparation/05_model_input_acquisition.qmd"
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
expect_true(length(chunks) == 10L, "Expected exactly 10 bounded R chunks.")
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
  grepl(
    'title="What is calculated during this render?"',
    full,
    fixed = TRUE
  ),
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
    "\\b(V0|legacy|previous|canonical)\\b|manuscript-prepared",
    visible_no_code,
    perl = TRUE,
    ignore.case = TRUE
  ),
  "Forbidden reader-facing workflow label remains."
)

expect_true(
  grepl(
    "ac79a83c2d60dde1ac563f6e2cb09c58d4d7d3b06549d9b9262e4acd5a50a58b",
    full,
    fixed = TRUE
  ),
  "Current acquisition manifest is absent."
)
expect_true(
  grepl(
    "618fda8521f3cf581661ceb2c026e3de7cd9ba82",
    full,
    fixed = TRUE
  ) &&
    grepl(
      "0db56324e9826d427c42984fdfc43eb1e7487211365f222a1c0b2ecff618f1ef",
      full,
      fixed = TRUE
    ),
  "The exact TUM exercise source pin is absent."
)
for (token in c("63", "963", "53", "nine sleep diaries", "downloaded one")) {
  expect_true(grepl(token, visible, fixed = TRUE), paste("Missing total:", token))
}
expect_true(
  grepl("connect to the network", visible, fixed = TRUE) &&
    grepl("not rerun", visible, fixed = TRUE),
  "The no-network/no-verifier boundary is incomplete."
)

table_chunks <- Filter(
  function(chunk) any(grepl("^#\\| label: tbl-", chunk$code)),
  chunks
)
expect_true(length(table_chunks) == 9L, "Expected exactly nine gt tables.")
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
  "config/site_sources.csv",
  "config/model_input_availability.csv",
  "config/model_input_source_pins.csv",
  "artifacts/12_manifests/pinned_downloads.csv",
  "artifacts/12_manifests/model_input_acquisition.csv",
  "artifacts/01_imported/model_inputs/object_audit.csv",
  "artifacts/01_imported/model_inputs/column_audit.csv",
  "audit/findings/preparation05_input_provenance_gaps.md",
  "audit/reconciliation/preparation06/normalization_gate.md"
)
for (path in required_paths) {
  expect_true(grepl(path, full, fixed = TRUE), paste("Missing path:", path))
}
required_scripts <- c(
  "scripts/pipeline/model_input_acquisition.R",
  "scripts/pipeline/import_sources.R",
  "scripts/pipeline/build_model_input_acquisition.R",
  "scripts/pipeline/verify_model_input_acquisition.R"
)
for (path in required_scripts) {
  expect_true(grepl(path, full, fixed = TRUE), paste("Missing script:", path))
}

expect_true(
  grepl("config/site_display_registry.csv", full, fixed = TRUE) &&
    grepl("arrange(.data$display_order)", full, fixed = TRUE) &&
    grepl(".data$color_hex", full, fixed = TRUE),
  "The site table does not use the submitted display registry."
)

if (length(args) >= 1L) {
  html_path <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
  html <- paste(
    readLines(html_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  required_html <- c(
    "Preparation 05: Acquire fixed questionnaire and diary inputs",
    "tbl-site-releases",
    "tbl-acquired-modalities",
    "tbl-current-acquisition-validation",
    "tbl-stored-acquisition-verification",
    "63 / 63",
    "963",
    "TUM exercise diary"
  )
  for (token in required_html) {
    expect_true(grepl(token, html, fixed = TRUE), paste("HTML lacks:", token))
  }
  site_names <- c(
    "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
    "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
    "Kumasi (GH)"
  )
  site_colours <- c(
    "#88CCEE", "#117733", "#DDCC77", "#CC6677", "#332288",
    "#44AA99", "#AA4499"
  )
  for (token in c(site_names, site_colours)) {
    expect_true(grepl(token, html, fixed = TRUE), paste("HTML lacks:", token))
  }
  expect_true(!grepl("# A tibble:", html, fixed = TRUE), "Raw tibble output is visible.")
}

cat(
  paste0(
    "PASS: Preparation 05 satisfies the bounded-render, fixed-source, ",
    "gt-table, site-display, and provenance contract.\n"
  )
)
