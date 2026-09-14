#!/usr/bin/env Rscript

# REPORT-014/017 order 32 source-only verification.
# This script parses authoring code but never evaluates a QMD chunk.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    "Usage: run_h01_order32_source_audit.R <baseline-dir> <evidence-dir>",
    call. = FALSE
  )
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
baseline_dir <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
evidence_dir <- normalizePath(
  file.path(root, args[[2L]]),
  winslash = "/",
  mustWork = FALSE
)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)
setwd(root)

source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(yaml)
})

checks <- tibble::tibble(
  check_id = character(),
  status = character(),
  expected = character(),
  observed = character(),
  detail = character()
)

record_check <- function(check_id, condition, expected, observed, detail = "") {
  checks <<- dplyr::bind_rows(
    checks,
    tibble::tibble(
      check_id = check_id,
      status = if (isTRUE(condition)) "PASS" else "FAIL",
      expected = as.character(expected),
      observed = as.character(observed),
      detail = as.character(detail)
    )
  )
  invisible(condition)
}

read_text <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

extract_chunks <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^```\\{r(?:[^}]*)\\}[[:space:]]*$", lines, perl = TRUE)
  chunks <- vector("list", length(starts))
  for (index in seq_along(starts)) {
    start <- starts[[index]]
    following <- which(
      seq_along(lines) > start & grepl("^```[[:space:]]*$", lines)
    )
    if (length(following) == 0L) {
      stop("Unclosed R chunk in ", path, " at line ", start, call. = FALSE)
    }
    end <- following[[1L]]
    body_lines <- if (end > start + 1L) lines[(start + 1L):(end - 1L)] else character()
    label_line <- grep("^#\\| label: ", body_lines, value = TRUE)
    label <- if (length(label_line) == 1L) {
      sub("^#\\| label: ", "", label_line)
    } else {
      paste0("unnamed-line-", start)
    }
    chunks[[index]] <- list(
      label = label,
      body = paste(body_lines, collapse = "\n"),
      start = start,
      end = end
    )
  }
  chunks
}

chunk_labels <- function(chunks) vapply(chunks, `[[`, character(1), "label")

parse_chunks <- function(chunks, document) {
  errors <- character()
  for (chunk in chunks) {
    error <- tryCatch(
      {
        parse(text = chunk$body, keep.source = TRUE)
        NULL
      },
      error = function(condition) conditionMessage(condition)
    )
    if (!is.null(error)) {
      errors <- c(errors, paste0(document, ":", chunk$label, ": ", error))
    }
  }
  errors
}

extract_endpoints <- function(text) {
  table_labels <- regmatches(
    text,
    gregexpr("(?<=#\\| label: )tbl-h01-[a-z0-9-]+", text, perl = TRUE)
  )[[1L]]
  chunk_figures <- regmatches(
    text,
    gregexpr("(?<=#\\| label: )fig-h01-[a-z0-9-]+", text, perl = TRUE)
  )[[1L]]
  image_figures <- regmatches(
    text,
    gregexpr("(?<=\\{#)fig-h01-[a-z0-9-]+", text, perl = TRUE)
  )[[1L]]
  list(
    tables = table_labels[table_labels != ""],
    figures = c(
      chunk_figures[chunk_figures != ""],
      image_figures[image_figures != ""]
    )
  )
}

extract_inline_r <- function(text) {
  values <- regmatches(
    text,
    gregexpr("(?<=`r )[^`]+(?=`)", text, perl = TRUE)
  )[[1L]]
  values[values != ""]
}

top_assignments <- function(chunks) {
  assignments <- character()
  for (chunk in chunks) {
    expressions <- parse(text = chunk$body)
    for (expression in expressions) {
      if (
        is.call(expression) &&
          identical(as.character(expression[[1L]]), "<-") &&
          is.symbol(expression[[2L]])
      ) {
        assignments <- c(assignments, as.character(expression[[2L]]))
      }
    }
  }
  assignments
}

multiset_difference <- function(after, before) {
  after_table <- table(after)
  before_table <- table(before)
  names_all <- union(names(after_table), names(before_table))
  difference <- integer(length(names_all))
  names(difference) <- names_all
  difference[names(after_table)] <- difference[names(after_table)] + as.integer(after_table)
  difference[names(before_table)] <- difference[names(before_table)] - as.integer(before_table)
  as.character(unlist(
    lapply(
      names(difference)[difference > 0L],
      function(value) rep(value, difference[[value]])
    ),
    use.names = FALSE
  ))
}

strip_fenced_blocks <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  in_fence <- FALSE
  retained <- character()
  for (line in lines) {
    if (grepl("^```", line)) {
      in_fence <- !in_fence
      next
    }
    if (!in_fence) retained <- c(retained, line)
  }
  paste(retained, collapse = "\n")
}

extract_numeric_tokens <- function(text) {
  text <- gsub("SHA-256", "SHA", text, fixed = TRUE)
  values <- regmatches(
    text,
    gregexpr(
      "(?<![A-Za-z0-9_])[0-9]+(?:[.][0-9]+)?%?(?![A-Za-z0-9_])",
      text,
      perl = TRUE
    )
  )[[1L]]
  values[values != ""]
}

extract_file_tokens <- function(text) {
  values <- regmatches(
    text,
    gregexpr(
      "(?:[.]{0,2}/)?(?:[A-Za-z0-9_.-]+/)+[A-Za-z0-9_.-]+[.](?:csv|rds|png|svg|qmd|R|yml|lock|md|html)",
      text,
      perl = TRUE
    )
  )[[1L]]
  values[values != ""]
}

extract_markdown_targets <- function(text) {
  values <- regmatches(
    text,
    gregexpr("(?<=\\]\\()[^)]+(?=\\))", text, perl = TRUE)
  )[[1L]]
  values[values != ""]
}

extract_registration_targets <- function(text) {
  targets <- extract_markdown_targets(text)
  targets[grepl("preregistration_deviations[.]qmd#", targets)]
}

extract_image_records <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  image_lines <- lines[grepl("^!\\[.*\\].*\\{#fig-h01-", lines)]
  ids <- regmatches(
    image_lines,
    regexpr("fig-h01-[a-z0-9-]+", image_lines, perl = TRUE)
  )
  stats::setNames(image_lines, ids)
}

extract_front_matter <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  boundaries <- which(lines == "---")
  stopifnot(length(boundaries) >= 2L, boundaries[[1L]] == 1L)
  yaml::yaml.load(paste(lines[2L:(boundaries[[2L]] - 1L)], collapse = "\n"))
}

collect_calls <- function(chunks) {
  calls <- character()
  walk <- function(object) {
    if (missing(object)) return(invisible(NULL))
    if (is.call(object)) {
      if (is.symbol(object[[1L]])) calls <<- c(calls, as.character(object[[1L]]))
      for (element in as.list(object)[-1L]) walk(element)
    } else if (is.expression(object) || is.pairlist(object)) {
      for (element in as.list(object)) walk(element)
    }
  }
  for (chunk in chunks) walk(parse(text = chunk$body))
  unique(calls)
}

result_relative <- "notebooks/hypotheses/H01.qmd"
companion_relative <- "audit/hypotheses/H01/H01_analysis_preparation.qmd"
documents <- c(result = result_relative, companion = companion_relative)

baseline_text <- lapply(
  documents,
  function(path) read_text(file.path(baseline_dir, path))
)
current_text <- lapply(documents, function(path) read_text(file.path(root, path)))
baseline_chunks <- lapply(
  documents,
  function(path) extract_chunks(file.path(baseline_dir, path))
)
current_chunks <- lapply(
  documents,
  function(path) extract_chunks(file.path(root, path))
)

for (document in names(documents)) {
  parse_errors <- parse_chunks(current_chunks[[document]], document)
  record_check(
    paste0(document, "_r_chunk_parse"),
    length(parse_errors) == 0L,
    "all R chunks parse without execution",
    if (length(parse_errors) == 0L) "all parsed" else paste(parse_errors, collapse = " | ")
  )
  record_check(
    paste0(document, "_chunk_labels"),
    identical(
      sort(chunk_labels(baseline_chunks[[document]])),
      sort(chunk_labels(current_chunks[[document]]))
    ),
    paste(length(baseline_chunks[[document]]), "unchanged chunk labels"),
    paste(length(current_chunks[[document]]), "current chunk labels")
  )
}

orientation_expression <- NULL
for (chunk in current_chunks$result) {
  expressions <- parse(text = chunk$body)
  for (expression in expressions) {
    if (
      is.call(expression) &&
        identical(as.character(expression[[1L]]), "<-") &&
        is.symbol(expression[[2L]]) &&
        identical(as.character(expression[[2L]]), "h01_support_orientation")
    ) {
      orientation_expression <- expression
    }
  }
}
orientation_calls <- if (is.null(orientation_expression)) {
  character()
} else {
  collect_calls(list(list(
    body = paste(deparse(orientation_expression), collapse = "\n")
  )))
}
orientation_allowed_calls <- c(
  "<-", "|>", "filter", "%in%", "c", "summarise", "min", "$", "[", "==", "max"
)
record_check(
  "result_support_orientation_boundary",
  !is.null(orientation_expression) &&
    identical(as.character(orientation_expression[[3L]][[2L]][[2L]]), "exact_samples") &&
    length(setdiff(orientation_calls, orientation_allowed_calls)) == 0L,
  "one non-mutating exact_samples filter and summary with no external read, join, or model call",
  paste(orientation_calls, collapse = " | ")
)

baseline_endpoints <- lapply(baseline_text, extract_endpoints)
current_endpoints <- lapply(current_text, extract_endpoints)
endpoint_contract <- list(
  result = c(tables = 36L, figures = 10L),
  companion = c(tables = 20L, figures = 2L)
)
for (document in names(documents)) {
  record_check(
    paste0(document, "_table_endpoints"),
    length(current_endpoints[[document]]$tables) == endpoint_contract[[document]][["tables"]] &&
      !anyDuplicated(current_endpoints[[document]]$tables) &&
      identical(
        sort(current_endpoints[[document]]$tables),
        sort(baseline_endpoints[[document]]$tables)
      ),
    paste(endpoint_contract[[document]][["tables"]], "unchanged unique table endpoints"),
    paste(length(current_endpoints[[document]]$tables), "table endpoints")
  )
  record_check(
    paste0(document, "_figure_endpoints"),
    length(current_endpoints[[document]]$figures) == endpoint_contract[[document]][["figures"]] &&
      !anyDuplicated(current_endpoints[[document]]$figures) &&
      identical(
        sort(current_endpoints[[document]]$figures),
        sort(baseline_endpoints[[document]]$figures)
      ),
    paste(endpoint_contract[[document]][["figures"]], "unchanged unique figure endpoints"),
    paste(length(current_endpoints[[document]]$figures), "figure endpoints")
  )
}

first_result_table <- regmatches(
  current_text$result,
  regexpr("tbl-h01-[a-z0-9-]+", current_text$result, perl = TRUE)
)
first_result_figure <- regmatches(
  current_text$result,
  regexpr("fig-h01-[a-z0-9-]+", current_text$result, perl = TRUE)
)
record_check(
  "result_first_table",
  identical(first_result_table, "tbl-h01-primary-publication-summary"),
  "tbl-h01-primary-publication-summary",
  first_result_table
)
record_check(
  "result_first_figure",
  identical(first_result_figure, "fig-h01-model-support"),
  "fig-h01-model-support",
  first_result_figure
)

formula_chunks <- list(
  result = c(
    "tbl-h01-participant-formulas",
    "tbl-h01-participant-day-formulas",
    "tbl-h01-preregistered-scope-formulas",
    "tbl-h01-formula-manifest"
  ),
  companion = "tbl-h01-prep-formulas"
)
for (document in names(formula_chunks)) {
  baseline_map <- stats::setNames(
    lapply(baseline_chunks[[document]], `[[`, "body"),
    chunk_labels(baseline_chunks[[document]])
  )
  current_map <- stats::setNames(
    lapply(current_chunks[[document]], `[[`, "body"),
    chunk_labels(current_chunks[[document]])
  )
  for (label in formula_chunks[[document]]) {
    record_check(
      paste0(document, "_formula_chunk_", label),
      identical(baseline_map[[label]], current_map[[label]]),
      "formula chunk byte-identical",
      if (identical(baseline_map[[label]], current_map[[label]])) "identical" else "changed"
    )
  }
}

expected_inline_additions <- paste0(
  "h01_support_orientation$",
  c(
    "primary_participant_min",
    "primary_participant_max",
    "primary_day_min",
    "primary_day_max",
    "primary_sites",
    "chest_participant_min",
    "chest_participant_max",
    "chest_day_min",
    "chest_day_max",
    "chest_sites"
  )
)
for (document in names(documents)) {
  before <- extract_inline_r(baseline_text[[document]])
  after <- extract_inline_r(current_text[[document]])
  added <- sort(multiset_difference(after, before))
  removed <- sort(multiset_difference(before, after))
  expected_added <- if (document == "result") sort(expected_inline_additions) else character()
  record_check(
    paste0(document, "_inline_r_allow_list"),
    identical(added, expected_added) && length(removed) == 0L,
    paste(c(expected_added, "no removals"), collapse = " | "),
    paste(c(paste0("added:", added), paste0("removed:", removed)), collapse = " | ")
  )
}

for (document in names(documents)) {
  before <- top_assignments(baseline_chunks[[document]])
  after <- top_assignments(current_chunks[[document]])
  added <- sort(multiset_difference(after, before))
  removed <- sort(multiset_difference(before, after))
  expected_added <- if (document == "result") "h01_support_orientation" else character()
  expected_removed <- if (document == "companion") "source_dir" else character()
  record_check(
    paste0(document, "_top_level_assignment_allow_list"),
    identical(added, expected_added) && identical(removed, expected_removed),
    paste0(
      "added=", paste(expected_added, collapse = "|"),
      "; removed=", paste(expected_removed, collapse = "|")
    ),
    paste0(
      "added=", paste(added, collapse = "|"),
      "; removed=", paste(removed, collapse = "|")
    )
  )
}

for (document in names(documents)) {
  baseline_prose <- strip_fenced_blocks(baseline_text[[document]])
  current_prose <- strip_fenced_blocks(current_text[[document]])
  before_numbers <- sort(extract_numeric_tokens(baseline_prose))
  after_numbers <- sort(extract_numeric_tokens(current_prose))
  record_check(
    paste0(document, "_scientific_numeric_tokens"),
    identical(before_numbers, after_numbers),
    paste(length(before_numbers), "unchanged prose numeric tokens"),
    paste(length(after_numbers), "current prose numeric tokens")
  )
  before_files <- sort(extract_file_tokens(baseline_text[[document]]))
  after_files <- sort(extract_file_tokens(current_text[[document]]))
  record_check(
    paste0(document, "_file_reference_tokens"),
    identical(before_files, after_files),
    paste(length(before_files), "unchanged file-reference tokens"),
    paste(length(after_files), "current file-reference tokens")
  )
  before_source_links <- sort(
    extract_markdown_targets(baseline_text[[document]])[
      grepl("artifacts/11_source_data", extract_markdown_targets(baseline_text[[document]]))
    ]
  )
  after_source_links <- sort(
    extract_markdown_targets(current_text[[document]])[
      grepl("artifacts/11_source_data", extract_markdown_targets(current_text[[document]]))
    ]
  )
  record_check(
    paste0(document, "_source_data_links"),
    identical(before_source_links, after_source_links),
    paste(length(before_source_links), "unchanged source-data links"),
    paste(length(after_source_links), "current source-data links")
  )
}

baseline_images <- extract_image_records(baseline_text$result)
current_images <- extract_image_records(current_text$result)
image_ids <- names(baseline_images)
image_match <- identical(sort(names(current_images)), sort(image_ids))
for (id in image_ids) {
  before <- baseline_images[[id]]
  after <- current_images[[id]]
  if (id %in% c("fig-h01-site-contrasts-near-eye", "fig-h01-site-contrasts-chest")) {
    after <- gsub("FDR-adjusted", "adjusted", after, fixed = TRUE)
  }
  image_match <- image_match && identical(before, after)
}
record_check(
  "result_figure_caption_alt_and_path_contract",
  image_match,
  "all figure Markdown unchanged except explicit FDR display wording",
  if (image_match) "matched" else "difference outside allow-list"
)

registration_targets <- extract_registration_targets(current_text$result)
registration_prefix <- "../preregistration_deviations.qmd#"
registration_anchors <- substring(
  registration_targets,
  nchar(registration_prefix) + 1L
)
central_text <- read_text(file.path(root, "notebooks/preregistration_deviations.qmd"))
central_anchor_tokens <- regmatches(
  central_text,
  gregexpr("\\{#[A-Za-z0-9-]+\\}", central_text, perl = TRUE)
)[[1L]]
central_anchors <- gsub("^\\{#|\\}$", "", central_anchor_tokens)
registration_ok <-
  length(registration_targets) == 40L &&
  length(unique(registration_anchors)) == 36L &&
  all(grepl(
    "^[.][.]/preregistration_deviations[.]qmd#[a-z0-9-]+$",
    registration_targets,
    perl = TRUE
  )) &&
  identical(registration_anchors, tolower(registration_anchors)) &&
  all(vapply(
    unique(registration_anchors),
    function(anchor) sum(central_anchors == anchor) == 1L,
    logical(1)
  ))
record_check(
  "registration_link_contract",
  registration_ok,
  "40 exact targets, 36 unique lower-case anchors, each central anchor once",
  paste(length(registration_targets), "targets and", length(unique(registration_anchors)), "anchors")
)

record_check(
  "reciprocal_dynamic_qmd_links",
  grepl(
    "../../audit/hypotheses/H01/H01_analysis_preparation.qmd",
    current_text$result,
    fixed = TRUE
  ) &&
    grepl(
      "../../../notebooks/hypotheses/H01.qmd",
      current_text$companion,
      fixed = TRUE
    ) &&
    grepl(
      "../../../notebooks/hypotheses/H01.qmd#h01-preregistration-deviations",
      current_text$companion,
      fixed = TRUE
    ),
  "reciprocal relative QMD links and registration anchor",
  "source links inspected"
)

all_page_targets <- unlist(lapply(current_text, extract_markdown_targets), use.names = FALSE)
forbidden_page_targets <- all_page_targets[
  grepl("[.]html(?:#|$)|_build|file://|^/|/Users/", all_page_targets, perl = TRUE)
]
record_check(
  "no_hard_coded_internal_page_links",
  length(forbidden_page_targets) == 0L,
  "no .html, _build, file://, root-absolute, or local absolute Markdown page targets",
  paste(forbidden_page_targets, collapse = " | ")
)

for (document in names(documents)) {
  front_matter <- extract_front_matter(file.path(root, documents[[document]]))
  record_check(
    paste0(document, "_lightbox"),
    isTRUE(front_matter$format$html$lightbox),
    "lightbox true",
    as.character(front_matter$format$html$lightbox)
  )
  prose <- strip_fenced_blocks(current_text[[document]])
  record_check(
    paste0(document, "_prose_em_dash"),
    !grepl("—", prose, fixed = TRUE),
    "no prose em dash",
    if (grepl("—", prose, fixed = TRUE)) "present" else "absent"
  )
  write_calls <- intersect(
    collect_calls(current_chunks[[document]]),
    c(
      "write.csv", "write.table", "writeLines", "saveRDS", "save",
      "ggsave", "dir.create", "file.copy", "file.rename", "unlink",
      "write_csv", "write_tsv", "atomic_write_csv", "atomic_save_rds"
    )
  )
  record_check(
    paste0(document, "_no_project_write_calls"),
    length(write_calls) == 0L,
    "no project-side write calls",
    paste(write_calls, collapse = " | ")
  )
}

record_check(
  "result_reader_fdr_language",
  !grepl("BH-adjusted", strip_fenced_blocks(current_text$result), fixed = TRUE) &&
    !grepl("Within-metric adjusted p", current_text$result, fixed = TRUE) &&
    grepl("Within-metric FDR-adjusted p", current_text$result, fixed = TRUE),
  "FDR reader language with no BH-adjusted display text",
  "result source inspected"
)
record_check(
  "companion_rh_sci_h01_003",
  grepl(
    paste0(
      "Marginal R², conditional R², participant-associated share, and ",
      "model-specific term part-R² values that may overlap and must not be summed"
    ),
    current_text$companion,
    fixed = TRUE
  ),
  "exact RH-SCI-H01-003 wording",
  "companion source inspected"
)
record_check(
  "result_reader_hierarchy",
  all(diff(match(
    c(
      "## Hypothesis and analytical question",
      "## What was analysed",
      "## Statistical models",
      "## Results overview",
      "## Primary near-eye results",
      "## Complementary chest results",
      "## Matched near-eye and chest evidence",
      "## Model checks",
      "## Sensitivity analyses",
      "## Interpretation",
      "## Limitations",
      "## Detailed analysis record",
      "## Analysis record and source data"
    ),
    strsplit(current_text$result, "\n", fixed = TRUE)[[1L]]
  )) > 0L),
  "approved result heading order",
  "heading positions inspected"
)
record_check(
  "result_disclosures",
  all(vapply(
    c(
      "Show representative model-check details",
      "Show linked registration entries by topic",
      "Show exact formulas and model engines"
    ),
    grepl,
    logical(1),
    x = current_text$result,
    fixed = TRUE
  )) &&
    str_count(current_text$result, fixed("<details>")) == 3L &&
    str_count(current_text$result, fixed("</details>")) == 3L,
  "three balanced approved disclosures",
  paste(str_count(current_text$result, fixed("<details>")), "opening disclosures")
)

site_contrasts <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H01/stage3/H01_stage3_site_contrasts.csv"),
  show_col_types = FALSE,
  progress = FALSE
)
site_names <- unique(site_contrasts$display_name)
record_check(
  "country_coded_site_display",
  length(site_names) == 9L && all(grepl(".+ \\([A-Z]{2}\\)$", site_names)),
  "nine country-coded registered site display names",
  paste(site_names, collapse = " | ")
)

preflight_protected <- c(
  "_build/nathealth/notebooks/hypotheses/H01.html" =
    "6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html" =
    "5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38",
  "_quarto-nathealth.yml" =
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R" =
    "121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb"
)
for (path in names(preflight_protected)) {
  observed <- artifact_sha256(file.path(root, path))
  record_check(
    paste0("protected_", gsub("[^A-Za-z0-9]+", "_", path)),
    identical(observed, unname(preflight_protected[[path]])),
    unname(preflight_protected[[path]]),
    observed
  )
}

read_manifest <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

audit_manifest <- function(relative_path) {
  manifest <- read_manifest(file.path(root, relative_path))
  files <- file.path(root, manifest$path)
  observed_sha256 <- vapply(files, artifact_sha256, character(1))
  observed_bytes <- as.numeric(file.info(files)$size)
  manifest |>
    mutate(
      observed_sha256 = unname(observed_sha256),
      observed_bytes = observed_bytes,
      exact = .data$sha256 == .data$observed_sha256 &
        .data$bytes == .data$observed_bytes
    )
}

manifest_paths <- c(
  reporting = "artifacts/12_manifests/H01_reporting_artifacts.csv",
  stage3 = "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv",
  preparation = "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
  worker = "artifacts/12_manifests/H01_worker_artifacts.csv"
)
manifest_audits <- lapply(manifest_paths, audit_manifest)
expected_mismatches <- list(
  reporting = character(),
  stage3 = character(),
  preparation = c(
    "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "_quarto-nathealth.yml"
  ),
  worker = c(
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "_quarto-nathealth.yml"
  )
)
for (manifest_name in names(manifest_audits)) {
  audit <- manifest_audits[[manifest_name]]
  mismatches <- sort(audit$path[!audit$exact])
  record_check(
    paste0("manifest_", manifest_name, "_classification"),
    !anyDuplicated(audit$path) &&
      identical(mismatches, sort(expected_mismatches[[manifest_name]])),
    paste0("unique paths; mismatches=", paste(sort(expected_mismatches[[manifest_name]]), collapse = "|")),
    paste0("rows=", nrow(audit), "; mismatches=", paste(mismatches, collapse = "|"))
  )
}

current_qmd_paths <- c(result_relative, companion_relative)
for (manifest_name in c("reporting", "stage3")) {
  audit <- manifest_audits[[manifest_name]]
  for (path in current_qmd_paths) {
    row <- audit[audit$path == path, , drop = FALSE]
    record_check(
      paste0("manifest_", manifest_name, "_", gsub("[^A-Za-z0-9]+", "_", path)),
      nrow(row) == 1L && row$exact,
      "one exact current source row",
      paste(nrow(row), "rows; exact=", if (nrow(row) == 1L) row$exact else FALSE)
    )
  }
}

baseline_worker <- read_manifest(
  file.path(baseline_dir, manifest_paths[["worker"]])
)
historical_pattern <- paste0(
  "^(audit/hypotheses/H01/report016/|",
  "audit/hypotheses/H01/report017_model_support_fdr_refresh/|",
  "audit/report_harmonization/owner_orders/31[fghi]|",
  "audit/report_harmonization/report017_h01_order31[fghi])"
)
historical_rows <- baseline_worker |>
  filter(grepl(historical_pattern, .data$path, perl = TRUE))
historical_current_sha256 <- vapply(
  file.path(root, historical_rows$path),
  artifact_sha256,
  character(1)
)
historical_current_bytes <- as.numeric(
  file.info(file.path(root, historical_rows$path))$size
)
historical_exact <-
  historical_rows$sha256 == unname(historical_current_sha256) &
  historical_rows$bytes == historical_current_bytes
record_check(
  "historical_report016_order31f_31i_preservation",
  nrow(historical_rows) > 0L && all(historical_exact),
  paste(nrow(historical_rows), "baseline worker identities exact"),
  paste(sum(historical_exact), "of", nrow(historical_rows), "exact")
)

historical_reconciliation_manifest <-
  "audit/hypotheses/H01/report016/H01_REPORT016_reconciliation_manifest.csv"
record_check(
  "historical_report016_reconciliation_manifest",
  identical(
    artifact_sha256(file.path(root, historical_reconciliation_manifest)),
    "15f88d244450f380112f1ab7adfadade56f518ea43daf8ef4fb0454278cdd5bf"
  ),
  "15f88d244450f380112f1ab7adfadade56f518ea43daf8ef4fb0454278cdd5bf",
  artifact_sha256(file.path(root, historical_reconciliation_manifest))
)

compare_manifest_rows <- function(name, expected_changed_paths) {
  relative <- manifest_paths[[name]]
  before_lines <- readLines(file.path(baseline_dir, relative), warn = FALSE)
  after_lines <- readLines(file.path(root, relative), warn = FALSE)
  before <- read_manifest(file.path(baseline_dir, relative))
  after <- read_manifest(file.path(root, relative))
  before_key <- before$path
  after_key <- after$path
  changed <- union(
    before_key[!before_key %in% after_key],
    after_key[!after_key %in% before_key]
  )
  common <- intersect(before_key, after_key)
  for (path in common) {
    before_row <- before[before$path == path, , drop = FALSE]
    after_row <- after[after$path == path, , drop = FALSE]
    if (!identical(before_row, after_row)) changed <- c(changed, path)
  }
  changed <- sort(unique(changed))
  record_check(
    paste0("manifest_", name, "_authorized_row_diff"),
    identical(changed, sort(expected_changed_paths)),
    paste(sort(expected_changed_paths), collapse = "|"),
    paste(changed, collapse = "|")
  )

  reconstructed <- after_lines
  for (path in expected_changed_paths) {
    before_line <- before_lines[startsWith(before_lines, paste0(path, ","))]
    after_index <- which(startsWith(reconstructed, paste0(path, ",")))
    if (length(before_line) == 1L && length(after_index) == 1L) {
      reconstructed[[after_index]] <- before_line
    }
  }
  temporary <- tempfile(fileext = ".csv")
  writeLines(reconstructed, temporary, useBytes = TRUE)
  reverse_sha256 <- artifact_sha256(temporary)
  baseline_sha256 <- artifact_sha256(file.path(baseline_dir, relative))
  unlink(temporary)
  record_check(
    paste0("manifest_", name, "_reverse_proof"),
    identical(reverse_sha256, baseline_sha256),
    baseline_sha256,
    reverse_sha256
  )

  before_selected <- before |> filter(.data$path %in% expected_changed_paths)
  after_selected <- after |> filter(.data$path %in% expected_changed_paths)
  dplyr::full_join(
    before_selected,
    after_selected,
    by = "path",
    suffix = c("_before", "_after")
  ) |>
    mutate(manifest = relative, .before = 1L)
}

manifest_row_diffs <- dplyr::bind_rows(
  compare_manifest_rows(
    "reporting",
    c(result_relative, companion_relative)
  ),
  compare_manifest_rows(
    "stage3",
    c(result_relative, companion_relative)
  ),
  compare_manifest_rows(
    "preparation",
    c(
      result_relative,
      companion_relative,
      manifest_paths[["reporting"]],
      manifest_paths[["stage3"]]
    )
  )
)

test_contract <- tibble::tribble(
  ~test_id, ~path, ~extra_env,
  "reporting", "tests/hypotheses/H01/test_h01_reporting_inputs.R", "",
  "preparation_source_only", "tests/hypotheses/H01/test_h01_preparation_report.R", "H01_PREPARATION_SOURCE_ONLY=true",
  "report016", "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R", "",
  "display_refresh_unchanged", "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R", ""
)
rscript <- file.path(R.home("bin"), "Rscript")
test_results <- vector("list", nrow(test_contract))
for (index in seq_len(nrow(test_contract))) {
  entry <- test_contract[index, ]
  command_args <- c("--vanilla", file.path(root, entry$path))
  command_env <- c(paste0("NATHEALTH_PROJECT_ROOT=", root))
  if (nzchar(entry$extra_env)) command_env <- c(command_env, entry$extra_env)
  started <- Sys.time()
  output <- system2(
    rscript,
    args = command_args,
    stdout = TRUE,
    stderr = TRUE,
    env = command_env
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  test_results[[index]] <- tibble::tibble(
    test_id = entry$test_id,
    command = paste(c(command_env, shQuote(rscript), "--vanilla", entry$path), collapse = " "),
    exit_status = as.integer(status),
    elapsed_seconds = round(elapsed, 3),
    output = paste(output, collapse = " | ")
  )
  record_check(
    paste0("focused_test_", entry$test_id),
    identical(as.integer(status), 0L),
    "exit status 0",
    as.character(status),
    paste(tail(output, 3L), collapse = " | ")
  )
}
test_results <- dplyr::bind_rows(test_results)

diff_paths <- c(
  result_relative,
  companion_relative,
  "tests/hypotheses/H01/test_h01_reporting_inputs.R",
  "tests/hypotheses/H01/test_h01_preparation_report.R",
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R",
  manifest_paths[["reporting"]],
  manifest_paths[["stage3"]],
  manifest_paths[["preparation"]],
  manifest_paths[["worker"]],
  "audit/handoffs/H01_worker_handoff.md"
)
diff_output <- system2(
  "git",
  args = c("diff", "--check", "--", diff_paths),
  stdout = TRUE,
  stderr = TRUE
)
diff_status <- attr(diff_output, "status")
if (is.null(diff_status)) diff_status <- 0L
record_check(
  "scoped_git_diff_check",
  identical(as.integer(diff_status), 0L),
  "exit status 0",
  as.character(diff_status),
  paste(diff_output, collapse = " | ")
)

status_output <- system2(
  "git",
  args = c("status", "--short", "--", diff_paths),
  stdout = TRUE,
  stderr = TRUE
)
writeLines(
  status_output,
  file.path(evidence_dir, "H01_order32_scoped_status.txt"),
  useBytes = TRUE
)

identities <- tibble::tibble(
  path = c(
    documents,
    "tests/hypotheses/H01/test_h01_reporting_inputs.R",
    "tests/hypotheses/H01/test_h01_preparation_report.R",
    "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R",
    manifest_paths,
    "audit/handoffs/H01_worker_handoff.md",
    names(preflight_protected)
  )
) |>
  distinct(.data$path) |>
  mutate(
    sha256 = vapply(file.path(root, .data$path), artifact_sha256, character(1)),
    bytes = as.numeric(file.info(file.path(root, .data$path))$size)
  )

package_versions <- tibble::tibble(
  component = c("R", "dplyr", "readr", "stringr", "tibble", "yaml", "openssl"),
  version = c(
    as.character(getRversion()),
    vapply(
      c("dplyr", "readr", "stringr", "tibble", "yaml", "openssl"),
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)

readr::write_csv(
  checks,
  file.path(evidence_dir, "H01_order32_source_audit.csv")
)
readr::write_csv(
  manifest_row_diffs,
  file.path(evidence_dir, "H01_order32_manifest_row_diff.csv")
)
readr::write_csv(
  checks |> filter(grepl("reverse_proof", .data$check_id)),
  file.path(evidence_dir, "H01_order32_reverse_proof.csv")
)
readr::write_csv(
  checks |> filter(grepl("protected|historical|numeric|formula|endpoint|reference|link", .data$check_id)),
  file.path(evidence_dir, "H01_order32_preservation_audit.csv")
)
readr::write_csv(
  test_results,
  file.path(evidence_dir, "H01_order32_test_results.csv")
)
readr::write_csv(
  identities,
  file.path(evidence_dir, "H01_order32_current_identities.csv")
)
readr::write_csv(
  package_versions,
  file.path(evidence_dir, "H01_order32_package_versions.csv")
)

failures <- checks |> filter(.data$status != "PASS")
summary_lines <- c(
  "# H01 order-32 source-only acceptance record",
  "",
  paste0("Date: ", format(Sys.Date(), "%Y-%m-%d")),
  "",
  paste0("R version: ", as.character(getRversion())),
  paste0("Checks passed: ", sum(checks$status == "PASS"), "/", nrow(checks)),
  paste0("Focused tests passed: ", sum(test_results$exit_status == 0L), "/", nrow(test_results)),
  "",
  "No Quarto render or QMD chunk execution was performed.",
  "No model, prediction, bootstrap, simulation, or reporting builder ran.",
  "",
  "## Disposition",
  "",
  if (nrow(failures) == 0L) {
    "PASS: the consolidated source-only rewrite satisfies the authorized order-32 contracts."
  } else {
    "STOPPED: one or more source-only contracts failed. No incremental repair was attempted."
  },
  if (nrow(failures) > 0L) c(
    "",
    "## Complete defect list",
    "",
    paste0("- ", failures$check_id, ": ", failures$detail)
  ) else character()
)
writeLines(
  summary_lines,
  file.path(evidence_dir, "H01_order32_source_acceptance.md"),
  useBytes = TRUE
)

if (nrow(failures) > 0L) {
  message("H01 order-32 source-only verification stopped with ", nrow(failures), " failures")
  quit(save = "no", status = 1L)
}

message(
  "H01 order-32 source-only verification passed: ",
  nrow(checks),
  " checks and ",
  nrow(test_results),
  " focused tests"
)
