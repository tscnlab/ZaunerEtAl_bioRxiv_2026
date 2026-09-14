#!/usr/bin/env Rscript

# REPORT-014/017 order 33 source-only verification.
# This script parses authoring code but never evaluates a QMD chunk.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    "Usage: run_h02_order33_source_audit.R <baseline-dir> <evidence-dir>",
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
  mustWork = TRUE
)
setwd(root)

source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

checks <- data.frame(
  check_id = character(),
  status = character(),
  expected = character(),
  observed = character(),
  detail = character(),
  stringsAsFactors = FALSE
)

record_check <- function(check_id, condition, expected, observed, detail = "") {
  checks <<- rbind(
    checks,
    data.frame(
      check_id = check_id,
      status = if (isTRUE(condition)) "PASS" else "FAIL",
      expected = as.character(expected),
      observed = as.character(observed),
      detail = as.character(detail),
      stringsAsFactors = FALSE
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
    body_lines <- if (end > start + 1L) {
      lines[(start + 1L):(end - 1L)]
    } else {
      character()
    }
    label_line <- grep("^#\\| label: ", body_lines, value = TRUE)
    label <- if (length(label_line) == 1L) {
      sub("^#\\| label: ", "", label_line)
    } else {
      NA_character_
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

explicit_chunk_labels <- function(chunks) {
  labels <- chunk_labels(chunks)
  labels[!is.na(labels)]
}

unlabeled_chunk_bodies <- function(chunks) {
  labels <- chunk_labels(chunks)
  vapply(chunks[is.na(labels)], `[[`, character(1), "body")
}

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
      label <- if (is.na(chunk$label)) "<unlabeled>" else chunk$label
      errors <- c(errors, paste0(document, ":", label, ": ", error))
    }
  }
  errors
}

extract_endpoints <- function(text) {
  table_labels <- regmatches(
    text,
    gregexpr("(?<=#\\| label: )tbl-h02-[a-z0-9-]+", text, perl = TRUE)
  )[[1L]]
  figure_labels <- regmatches(
    text,
    gregexpr("(?<=#\\| label: )fig-h02-[a-z0-9-]+", text, perl = TRUE)
  )[[1L]]
  list(
    tables = table_labels[table_labels != ""],
    figures = figure_labels[figure_labels != ""]
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

numeric_tokens <- function(text) {
  values <- regmatches(
    text,
    gregexpr(
      "(?<![[:alpha:]])-?[0-9]+(?:[.,][0-9]+)*(?![[:alpha:]])",
      text,
      perl = TRUE
    )
  )[[1L]]
  values[values != ""]
}

artifact_tokens <- function(text) {
  values <- regmatches(
    text,
    gregexpr(
      "[A-Za-z0-9_.*-]+[.](?:csv|rds|png|pdf|R|qmd|yml)|renv[.]lock",
      text,
      perl = TRUE
    )
  )[[1L]]
  values[values != ""]
}

multiset_equal <- function(left, right) identical(sort(left), sort(right))

chunk_body <- function(chunks, label) {
  index <- which(chunk_labels(chunks) == label)
  if (length(index) != 1L) return(NA_character_)
  chunks[[index]]$body
}

remove_fixed <- function(text, value) {
  gsub(value, "", text, fixed = TRUE)
}

canonical_companion_chunk <- function(body, label, phase) {
  if (label == "prepare-h02-response-distribution" && phase == "before") {
    body <- sub(
      "\\nresponse_source_dir <- file.path\\([\\s\\S]*$",
      "",
      body,
      perl = TRUE
    )
  }
  if (phase == "after") {
    display_blocks <- c(
      paste0(
        "  gt::cols_label(\n",
        "    Calculated_on_render = \"Calculated when rendered\"\n",
        "  ) |>\n"
      ),
      paste0(
        "  gt::cols_label(\n",
        "    Question_answered = \"Question answered\",\n",
        "    Interpretive_limit = \"Interpretive limit\"\n",
        "  ) |>\n"
      ),
      paste0(
        "  gt::cols_label(\n",
        "    Held_constant = \"Held constant\",\n",
        "    Entry_point = \"Entry point\"\n",
        "  ) |>\n"
      ),
      paste0(
        "  gt::cols_label(\n",
        "    Why_separate = \"Why separate\"\n",
        "  ) |>\n"
      ),
      paste0(
        "  gt::cols_label(\n",
        "    Entry_point = \"Entry point\",\n",
        "    Main_outputs = \"Main outputs\",\n",
        "    Run_when_page_renders = \"Run when page renders\"\n",
        "  ) |>\n"
      )
    )
    for (block in display_blocks) body <- remove_fixed(body, block)
    body <- gsub(
      paste0(
        "    Verified = if_else(\n",
        "      .data$hash_verified,\n",
        "      \"Verified\",\n",
        "      \"Review needed\"\n",
        "    )"
      ),
      "    Verified = if_else(.data$hash_verified, \"PASS\", \"FAIL\")",
      body,
      fixed = TRUE
    )
    body <- gsub(
      paste0(
        "  \"Multiplicity\", \"FDR adjustment\", ",
        "\"One confirmatory near-eye omnibus site-pattern test.\","
      ),
      paste0(
        "  \"Multiplicity\", \"H02-F1-site-pattern; ",
        "false-discovery-rate (FDR) adjustment\", ",
        "\"One confirmatory omnibus site-pattern family.\","
      ),
      body,
      fixed = TRUE
    )
    body <- gsub(
      paste0(
        "      \"Only the site-pattern comparison belongs to the single confirmatory\",\n",
        "      \"family. Bold denotes FDR-adjusted p < 0.05; the other rows are\","
      ),
      paste0(
        "      \"Only the site-pattern comparison belongs to the confirmatory H02-F1\",\n",
        "      \"family. Bold denotes FDR-adjusted p < 0.05; the other rows are\","
      ),
      body,
      fixed = TRUE
    )
  }
  body
}

document_paths <- c(
  result = "notebooks/hypotheses/H02.qmd",
  companion = "audit/hypotheses/H02/H02_analysis_preparation.qmd"
)
baseline_paths <- file.path(baseline_dir, document_paths)
current_paths <- file.path(root, document_paths)
baseline_text <- setNames(lapply(baseline_paths, read_text), names(document_paths))
current_text <- setNames(lapply(current_paths, read_text), names(document_paths))
baseline_chunks <- setNames(lapply(baseline_paths, extract_chunks), names(document_paths))
current_chunks <- setNames(lapply(current_paths, extract_chunks), names(document_paths))

baseline_companion_unlabeled <- unlabeled_chunk_bodies(baseline_chunks$companion)
current_companion_unlabeled <- unlabeled_chunk_bodies(current_chunks$companion)
companion_unlabeled_proof <- data.frame(
  document = "companion",
  before_count = length(baseline_companion_unlabeled),
  after_count = length(current_companion_unlabeled),
  before_body_bytes = if (length(baseline_companion_unlabeled) == 1L) {
    nchar(baseline_companion_unlabeled[[1L]], type = "bytes")
  } else {
    NA_integer_
  },
  after_body_bytes = if (length(current_companion_unlabeled) == 1L) {
    nchar(current_companion_unlabeled[[1L]], type = "bytes")
  } else {
    NA_integer_
  },
  body_byte_identical =
    length(baseline_companion_unlabeled) == 1L &&
    length(current_companion_unlabeled) == 1L &&
    identical(
      baseline_companion_unlabeled[[1L]],
      current_companion_unlabeled[[1L]]
    ),
  stringsAsFactors = FALSE
)

baseline_companion_numeric <- numeric_tokens(baseline_text$companion)
current_companion_numeric <- numeric_tokens(current_text$companion)
companion_numeric_levels <- sort(unique(c(
  baseline_companion_numeric,
  current_companion_numeric
)))
companion_numeric_before <- as.integer(table(factor(
  baseline_companion_numeric,
  levels = companion_numeric_levels
)))
companion_numeric_after <- as.integer(table(factor(
  current_companion_numeric,
  levels = companion_numeric_levels
)))
companion_numeric_delta <- data.frame(
  token = companion_numeric_levels,
  before_count = companion_numeric_before,
  after_count = companion_numeric_after,
  delta = companion_numeric_after - companion_numeric_before,
  stringsAsFactors = FALSE
)
companion_numeric_delta <- rbind(
  companion_numeric_delta,
  data.frame(
    token = "TOTAL",
    before_count = length(baseline_companion_numeric),
    after_count = length(current_companion_numeric),
    delta = length(current_companion_numeric) -
      length(baseline_companion_numeric),
    stringsAsFactors = FALSE
  )
)

for (document in names(document_paths)) {
  parse_errors <- parse_chunks(current_chunks[[document]], document)
  baseline_explicit_labels <- explicit_chunk_labels(baseline_chunks[[document]])
  current_explicit_labels <- explicit_chunk_labels(current_chunks[[document]])
  baseline_unlabeled <- unlabeled_chunk_bodies(baseline_chunks[[document]])
  current_unlabeled <- unlabeled_chunk_bodies(current_chunks[[document]])
  label_contract <- identical(
    sort(baseline_explicit_labels),
    sort(current_explicit_labels)
  ) && if (document == "companion") {
    length(baseline_unlabeled) == 1L &&
      length(current_unlabeled) == 1L &&
      identical(baseline_unlabeled[[1L]], current_unlabeled[[1L]])
  } else {
    length(baseline_unlabeled) == 0L && length(current_unlabeled) == 0L
  }
  record_check(
    paste0(document, "_r_chunks_parse"),
    length(parse_errors) == 0L,
    "no parse errors",
    paste(parse_errors, collapse = " | ")
  )
  record_check(
    paste0(document, "_chunk_labels_preserved"),
    label_contract,
    paste0(
      paste(sort(baseline_explicit_labels), collapse = "|"),
      "; unlabeled=",
      length(baseline_unlabeled)
    ),
    paste0(
      paste(sort(current_explicit_labels), collapse = "|"),
      "; unlabeled=",
      length(current_unlabeled),
      "; unlabeled_body_identical=",
      if (
        length(baseline_unlabeled) == 1L && length(current_unlabeled) == 1L
      ) {
        identical(baseline_unlabeled[[1L]], current_unlabeled[[1L]])
      } else {
        NA
      }
    )
  )
  record_check(
    paste0(document, "_inline_r_preserved"),
    multiset_equal(
      extract_inline_r(baseline_text[[document]]),
      extract_inline_r(current_text[[document]])
    ),
    as.character(length(extract_inline_r(baseline_text[[document]]))),
    as.character(length(extract_inline_r(current_text[[document]])))
  )
  baseline_numeric <- numeric_tokens(baseline_text[[document]])
  current_numeric <- numeric_tokens(current_text[[document]])
  if (document == "companion") {
    numeric_delta_without_allowed <- companion_numeric_delta[
      !companion_numeric_delta$token %in% c("2", "11", "TOTAL"),
      "delta"
    ]
    token_2_delta <- companion_numeric_delta[
      companion_numeric_delta$token == "2",
      "delta"
    ]
    token_11_delta <- companion_numeric_delta[
      companion_numeric_delta$token == "11",
      "delta"
    ]
    required_frozen_links <- c(
      paste0(
        "artifacts/11_source_data/H02/",
        "preparation_response_distribution_positive_observations.csv"
      ),
      paste0(
        "artifacts/11_source_data/H02/",
        "preparation_response_distribution_exact_zero_summary.csv"
      )
    )
    numeric_contract <-
      length(baseline_numeric) == 476L &&
      length(current_numeric) == 476L &&
      length(token_2_delta) == 1L && token_2_delta == -1L &&
      length(token_11_delta) == 1L && token_11_delta == 1L &&
      all(numeric_delta_without_allowed == 0L) &&
      all(vapply(
        required_frozen_links,
        grepl,
        logical(1),
        x = current_text$companion,
        fixed = TRUE
      )) &&
      !grepl(
        "H02-F1-site-pattern",
        current_text$companion,
        fixed = TRUE
      )
    numeric_observed <- paste0(
      "before=", length(baseline_numeric),
      "; after=", length(current_numeric),
      "; token_2_delta=", token_2_delta,
      "; token_11_delta=", token_11_delta,
      "; other_nonzero_deltas=",
      sum(numeric_delta_without_allowed != 0L)
    )
  } else {
    numeric_contract <- multiset_equal(baseline_numeric, current_numeric)
    numeric_observed <- as.character(length(current_numeric))
  }
  record_check(
    paste0(document, "_numeric_tokens_preserved"),
    numeric_contract,
    if (document == "companion") {
      "476/476; token 2 delta -1; token 11 delta +1; all others 0"
    } else {
      as.character(length(baseline_numeric))
    },
    numeric_observed
  )
  record_check(
    paste0(document, "_artifact_tokens_preserved"),
    multiset_equal(
      artifact_tokens(baseline_text[[document]]),
      artifact_tokens(current_text[[document]])
    ),
    paste(sort(unique(artifact_tokens(baseline_text[[document]]))), collapse = "|"),
    paste(sort(unique(artifact_tokens(current_text[[document]]))), collapse = "|")
  )
}

baseline_result_assignments <- top_assignments(baseline_chunks$result)
current_result_assignments <- top_assignments(current_chunks$result)
baseline_companion_assignments <- top_assignments(baseline_chunks$companion)
current_companion_assignments <- top_assignments(current_chunks$companion)
record_check(
  "result_top_assignments_preserved",
  multiset_equal(baseline_result_assignments, current_result_assignments),
  paste(sort(baseline_result_assignments), collapse = "|"),
  paste(sort(current_result_assignments), collapse = "|")
)
record_check(
  "companion_only_write_assignment_removed",
  multiset_equal(
    setdiff(baseline_companion_assignments, "response_source_dir"),
    current_companion_assignments
  ) &&
    sum(baseline_companion_assignments == "response_source_dir") == 1L &&
    !"response_source_dir" %in% current_companion_assignments,
  "baseline assignments except response_source_dir",
  paste(sort(current_companion_assignments), collapse = "|")
)

baseline_result_endpoints <- extract_endpoints(baseline_text$result)
current_result_endpoints <- extract_endpoints(current_text$result)
baseline_companion_endpoints <- extract_endpoints(baseline_text$companion)
current_companion_endpoints <- extract_endpoints(current_text$companion)
expected_result_tables <- c(
  "tbl-h02-near-variation", "tbl-h02-near-dominance",
  "tbl-h02-near-relevance", "tbl-h02-near-windows",
  "tbl-h02-chest-variation", "tbl-h02-chest-dominance",
  "tbl-h02-chest-relevance", "tbl-h02-chest-windows",
  "tbl-h02-near-diagnostics", "tbl-h02-chest-diagnostics",
  "tbl-h02-sensitivity", "tbl-h02-near-sample", "tbl-h02-chest-sample",
  "tbl-h02-model-deviations", "tbl-h02-data-deviations"
)
expected_result_figures <- c(
  "fig-h02-near-patterns", "fig-h02-chest-patterns",
  "fig-h02-paired-placement-curves", "fig-h02-near-diagnostics",
  "fig-h02-chest-diagnostics"
)
expected_companion_tables <- c(
  "tbl-h02-prep-boundary", "tbl-h02-prep-inputs", "tbl-h02-prep-support",
  "tbl-h02-prep-scenarios", "tbl-h02-prep-near-site-sample",
  "tbl-h02-prep-chest-site-sample", "tbl-h02-prep-parameters",
  "tbl-h02-prep-primary-fits", "tbl-h02-prep-structure-checks",
  "tbl-h02-prep-ar-boundaries", "tbl-h02-prep-diagnostic-map",
  "tbl-h02-prep-sensitivity-map", "tbl-h02-prep-module-map",
  "tbl-h02-prep-script-map", "tbl-h02-prep-manifests",
  "tbl-h02-prep-environment"
)
expected_companion_figures <- c(
  "fig-h02-prep-response-distribution", "fig-h02-prep-clock-support",
  "fig-h02-prep-day-support", "fig-h02-prep-ar-change"
)
record_check(
  "result_endpoint_sets_preserved",
  identical(
    sort(unlist(baseline_result_endpoints, use.names = FALSE)),
    sort(unlist(current_result_endpoints, use.names = FALSE))
  ) &&
    length(baseline_result_endpoints$tables) == 15L &&
    length(current_result_endpoints$tables) == 15L &&
    length(baseline_result_endpoints$figures) == 5L &&
    length(current_result_endpoints$figures) == 5L &&
    !anyDuplicated(unlist(baseline_result_endpoints, use.names = FALSE)) &&
    !anyDuplicated(unlist(current_result_endpoints, use.names = FALSE)),
  "15 tables and 5 figures, all once",
  paste(length(current_result_endpoints$tables), length(current_result_endpoints$figures))
)
record_check(
  "result_endpoint_order",
  identical(current_result_endpoints$tables, expected_result_tables) &&
    identical(current_result_endpoints$figures, expected_result_figures),
  paste(c(expected_result_figures, expected_result_tables), collapse = "|"),
  paste(
    c(current_result_endpoints$figures, current_result_endpoints$tables),
    collapse = "|"
  )
)
record_check(
  "companion_endpoint_contract",
  identical(current_companion_endpoints$tables, expected_companion_tables) &&
    identical(current_companion_endpoints$figures, expected_companion_figures) &&
    identical(
      sort(unlist(baseline_companion_endpoints)),
      sort(unlist(current_companion_endpoints))
    ),
  "16 tables and 4 figures, all once",
  paste(
    length(current_companion_endpoints$tables),
    length(current_companion_endpoints$figures)
  )
)

result_endpoint_labels <- unlist(baseline_result_endpoints, use.names = FALSE)
result_endpoint_equal <- vapply(
  result_endpoint_labels,
  function(label) {
    identical(
      chunk_body(baseline_chunks$result, label),
      chunk_body(current_chunks$result, label)
    )
  },
  logical(1)
)
record_check(
  "result_endpoint_code_byte_preserved",
  all(result_endpoint_equal),
  "every endpoint chunk body unchanged",
  paste(names(result_endpoint_equal)[!result_endpoint_equal], collapse = "|")
)

companion_endpoint_labels <- unlist(baseline_companion_endpoints, use.names = FALSE)
companion_endpoint_equal <- vapply(
  companion_endpoint_labels,
  function(label) {
    identical(
      canonical_companion_chunk(
        chunk_body(baseline_chunks$companion, label),
        label,
        "before"
      ),
      canonical_companion_chunk(
        chunk_body(current_chunks$companion, label),
        label,
        "after"
      )
    )
  },
  logical(1)
)
record_check(
  "companion_endpoint_science_preserved_after_display_canonicalization",
  all(companion_endpoint_equal),
  "every endpoint chunk differs only by approved display labels",
  paste(names(companion_endpoint_equal)[!companion_endpoint_equal], collapse = "|")
)
record_check(
  "companion_response_objects_preserved_without_writes",
  identical(
    canonical_companion_chunk(
      chunk_body(
        baseline_chunks$companion,
        "prepare-h02-response-distribution"
      ),
      "prepare-h02-response-distribution",
      "before"
    ),
    canonical_companion_chunk(
      chunk_body(
        current_chunks$companion,
        "prepare-h02-response-distribution"
      ),
      "prepare-h02-response-distribution",
      "after"
    )
  ),
  "in-memory objects unchanged; write-only tail removed",
  "compared canonical chunk bodies"
)

formula_terms <- c(
  's(time_hour, bs = "cc", k = 12)',
  's(time_hour, site, bs = "sz", k = 12)',
  's(time_hour, participant, bs = "fs", k = 10)',
  's(participant_day, bs = "re")'
)
for (document in names(document_paths)) {
  record_check(
    paste0(document, "_selected_wilkinson_formula"),
    all(vapply(
      formula_terms,
      function(term) {
        grepl(term, baseline_text[[document]], fixed = TRUE) &&
          grepl(term, current_text[[document]], fixed = TRUE)
      },
      logical(1)
    )),
    paste(formula_terms, collapse = " + "),
    "all four exact terms present"
  )
}

registration_links <- regmatches(
  current_text$result,
  gregexpr(
    "\\[[A-Z]{3}-[0-9]{3}\\]\\(\\.\\./preregistration_deviations\\.qmd#[a-z0-9-]+\\)",
    current_text$result,
    perl = TRUE
  )
)[[1L]]
registration_anchors <- sub(".*#([a-z0-9-]+)\\)$", "\\1", registration_links)
expected_registration_anchors <- c(
  "dev-001", "rep-001", "rep-002", "dev-012", "dev-012", "dev-011",
  "dev-010", "dev-011", "dev-021", "imp-005", "dev-012", "imp-015",
  "dev-019", "dev-057", "imp-017", "dev-021", "dev-005", "imp-012",
  "rep-003", "imp-002", "dev-049", "dev-050"
)
central_deviations <- read_text(
  file.path(root, "notebooks/preregistration_deviations.qmd")
)
record_check(
  "registration_link_mapping",
  identical(registration_anchors, expected_registration_anchors) &&
    length(registration_anchors) == 22L &&
    length(unique(registration_anchors)) == 18L,
  paste(expected_registration_anchors, collapse = "|"),
  paste(registration_anchors, collapse = "|")
)
record_check(
  "registration_anchor_targets_resolve",
  all(vapply(
    unique(registration_anchors),
    function(anchor) {
      grepl(paste0("{#", anchor, "}"), central_deviations, fixed = TRUE)
    },
    logical(1)
  )),
  "18 unique central anchors",
  as.character(length(unique(registration_anchors)))
)
record_check(
  "reciprocal_qmd_links",
  grepl(
    "../../audit/hypotheses/H02/H02_analysis_preparation.qmd",
    current_text$result,
    fixed = TRUE
  ) &&
    grepl(
      "../../../notebooks/hypotheses/H02.qmd",
      current_text$companion,
      fixed = TRUE
    ) &&
    grepl(
      "../../../notebooks/hypotheses/H02.qmd#h02-preregistration-deviations",
      current_text$companion,
      fixed = TRUE
    ),
  "dynamic relative QMD links in both directions",
  "result, companion, and anchored registration links found"
)

forbidden_page_links <- function(text) {
  grepl("\\]\\([^)]*[.]html(?:#|\\))", text, perl = TRUE) ||
    grepl("file://", text, fixed = TRUE) ||
    grepl("_build", text, fixed = TRUE) ||
    grepl("/Users/", text, fixed = TRUE) ||
    grepl("\\]\\(/", text, perl = TRUE)
}
record_check(
  "no_hard_coded_internal_page_links",
  !forbidden_page_links(current_text$result) &&
    !forbidden_page_links(current_text$companion),
  "no .html, file://, _build, absolute-local, or root-absolute page links",
  "scanned both QMD sources"
)
record_check(
  "reader_multiplicity_vocabulary",
  !grepl("\\bBH\\b", current_text$result, perl = TRUE) &&
    !grepl("\\bBH\\b", current_text$companion, perl = TRUE) &&
    !grepl("H02-F1-site-pattern", current_text$result, fixed = TRUE) &&
    !grepl("H02-F1-site-pattern", current_text$companion, fixed = TRUE) &&
    grepl("FDR adjustment", current_text$result, fixed = TRUE) &&
    grepl("FDR adjustment", current_text$companion, fixed = TRUE),
  "FDR reader vocabulary without internal family ID or BH abbreviation",
  "scanned both QMD sources"
)

result_without_missing_dash <- gsub(
  'missing_text = "—"',
  "",
  current_text$result,
  fixed = TRUE
)
record_check(
  "no_prose_em_dash",
  !grepl("—", result_without_missing_dash, fixed = TRUE) &&
    !grepl("—", current_text$companion, fixed = TRUE),
  "no prose em dash; missing-value symbol excepted",
  "scanned both QMD sources"
)

combined_chunk_text <- paste(
  c(
    vapply(current_chunks$result, `[[`, character(1), "body"),
    vapply(current_chunks$companion, `[[`, character(1), "body")
  ),
  collapse = "\n"
)
project_write_calls <- c(
  "write_csv", "write.csv", "writeLines", "saveRDS", "save(",
  "dir.create", "ggsave", "png(", "pdf("
)
write_hits <- project_write_calls[vapply(
  project_write_calls,
  function(value) grepl(value, combined_chunk_text, fixed = TRUE),
  logical(1)
)]
record_check(
  "no_project_side_writes_in_qmd_chunks",
  length(write_hits) == 0L,
  "no project-side write calls",
  paste(write_hits, collapse = "|")
)

historical_manifest_paths <- c(
  preparation = "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv",
  worker = "artifacts/12_manifests/H02/H02_worker_output_hashes.csv"
)
historical_manifest_hashes <- c(
  preparation = "c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7",
  worker = "0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331"
)
expected_mismatches <- list(
  preparation = sort(c(
    "_quarto-nathealth.yml",
    "audit/hypotheses/H02/H02_analysis_preparation.qmd",
    "notebooks/hypotheses/H02.qmd"
  )),
  worker = sort(c(
    "audit/handoffs/H02_shared_change_request.md",
    "audit/hypotheses/H02/H02_analysis_preparation.qmd",
    "notebooks/hypotheses/H02.qmd",
    "tests/hypotheses/H02/test_h02_paired_placement_display.R",
    "tests/hypotheses/H02/test_h02_preparation_report.R",
    "tests/hypotheses/H02/test_h02_reader_report.R"
  ))
)

manifest_mismatches <- function(relative) {
  manifest <- utils::read.csv(file.path(root, relative), check.names = FALSE)
  files <- file.path(root, manifest$path)
  exists <- file.exists(files)
  current_sha256 <- rep(NA_character_, length(files))
  current_bytes <- rep(NA_real_, length(files))
  current_sha256[exists] <- unname(vapply(
    files[exists],
    artifact_sha256,
    character(1)
  ))
  current_bytes[exists] <- as.numeric(file.info(files[exists])$size)
  sort(manifest$path[
    !exists |
      current_sha256 != manifest$sha256 |
      current_bytes != manifest$bytes
  ])
}

historical_mismatch_records <- vector("list", length(historical_manifest_paths))
for (index in seq_along(historical_manifest_paths)) {
  name <- names(historical_manifest_paths)[[index]]
  relative <- historical_manifest_paths[[index]]
  current_hash <- artifact_sha256(file.path(root, relative))
  mismatch <- manifest_mismatches(relative)
  record_check(
    paste0("historical_", name, "_manifest_identity"),
    identical(current_hash, historical_manifest_hashes[[name]]),
    historical_manifest_hashes[[name]],
    current_hash
  )
  record_check(
    paste0("historical_", name, "_mismatch_set"),
    identical(mismatch, expected_mismatches[[name]]),
    paste(expected_mismatches[[name]], collapse = "|"),
    paste(mismatch, collapse = "|")
  )
  historical_mismatch_records[[index]] <- data.frame(
    manifest = relative,
    mismatch_path = mismatch,
    stringsAsFactors = FALSE
  )
}
historical_mismatch_records <- do.call(rbind, historical_mismatch_records)

protected_expected <- c(
  "_build/nathealth/notebooks/hypotheses/H02.html" =
    "df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164",
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html" =
    "d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa",
  "artifacts/10_figures/H02/figure4_exact_layout_replication.png" =
    "2d31f38a169659b37a16c44b9845605186709e4dc7734a8f97342408711f9ac2",
  "artifacts/10_figures/H02/figure4_exact_layout_replication_chest.png" =
    "a82659874f9246b27e8cc25733b7a8236bbf8327d67f6378f868cc8f9c2f2cb1",
  "artifacts/10_figures/H02/model_diagnostics_near_eye.png" =
    "63feccccbde19e1804fe1405260e0a2015344837549046015e16374e8d5df05c",
  "artifacts/10_figures/H02/model_diagnostics_chest.png" =
    "10e8d1b1fce74474987b5f8b699260c85a4dba28126da2164fb9442e409424e8",
  "artifacts/11_source_data/H02/figure4_exact_layout_source.rds" =
    "63ea7588e5a19f5df64710e54d647b18cc74bc7c87dc7e8829bf65b7dfea825b",
  "artifacts/11_source_data/H02/figure4_exact_layout_source_chest.rds" =
    "f577321a48a04bf23d577abadcd4c57c264afe82ec889f6cebe5b6c5d20d5294",
  "artifacts/11_source_data/H02/paired_placement_site_curves.csv" =
    "3bc65cdd98bb8e71c5bc6f586e0aab966a929cc6b47df25b8e6eaf1376f5c5c8",
  "artifacts/11_source_data/H02/preparation_response_distribution_positive_observations.csv" =
    "22dff3af0f213b3ceaed0d5ca827da4184b662ff7d0366d592b6598b56e96842",
  "artifacts/11_source_data/H02/preparation_response_distribution_exact_zero_summary.csv" =
    "f2cc126a168bf8d6db3c5b13b3c6fea83030b23e7fdebff882bea1eb390f31db",
  "artifacts/09_tables/H02/variation_summary.csv" =
    "a07296c2e64e15a0217b9efc21b83acd578574f5b456a79eb2401382b0b4d3b0",
  "artifacts/09_tables/H02/dominance_summary.csv" =
    "c50589ee53541845cee1a104ae4aabb0bb45296a94e3ab7547fd1142ded4e84f",
  "artifacts/09_tables/H02/dominance_comparison_summary.csv" =
    "7240b7ab29818b085375a10c02bf53e49ad71203d6e2feb2385c590ca27e36fe",
  "artifacts/09_tables/H02/figure4_pointwise_conditional_windows.csv" =
    "ada1406a99af8edacbc9662c7a4616811bada78cb2a4cc5e61e6d9853e5cfa7b",
  "artifacts/06_model_data/H02/sample_counts.csv" =
    "61adf723232139383aa56075587b4476e0766641f4bc311542724b8482a5ab12",
  "artifacts/07_models/H02/selected_temporal_model_specification.csv" =
    "c3c95e97dbf7a260e4aa7513a15bb8c3c7e98bdb754d97c54700e4d82629310f",
  "artifacts/12_manifests/H02/H02_analysis_manifest.csv" =
    "cba73edc1d4974dd9a86a03513af7491aa62e8b09dbb3606895aa3af551b3804",
  "artifacts/12_manifests/H02/H02_dominance_manifest.csv" =
    "fe63aec3b643aa383e4ae68bc7ba71d6a7545f50278907b116c83816e26bf161",
  "artifacts/12_manifests/H02/H02_model_data_manifest.csv" =
    "63961c8f7fd1398ec31636a26a4008a0af630729800245404c4c38b9867ca005",
  "artifacts/12_manifests/H02/H02_paired_placement_display_manifest.csv" =
    "fffcffcecc79196a11515ff74c56b8293fbea9ee2368b4b71b6c39cddeb65753",
  "artifacts/12_manifests/H02/H02_reader_diagnostics_manifest.csv" =
    "493762b324d6f7e468ed78f91a30430cee58b9b3762cf7c870ccf7c8faccca0a",
  "artifacts/12_manifests/H02/figure4_replication_manifest.csv" =
    "bc393421b09347bd594928fb4893b538bcf55a11443cf8bdb02d218056a94d73",
  "artifacts/12_manifests/H02/H02_figure_readability_qa.csv" =
    "f0898eeab659591109954f453f78ef5f5b783415cce015c79c1ce17c72a43814",
  "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv" =
    "c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7",
  "artifacts/12_manifests/H02/H02_worker_output_hashes.csv" =
    "0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331",
  "notebooks/preregistration_deviations.qmd" =
    "b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d",
  "config/site_display_registry.csv" =
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "_quarto-nathealth.yml" =
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  "renv.lock" =
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
)
protected_paths <- names(protected_expected)
protected_files <- file.path(root, protected_paths)
protected_exists <- file.exists(protected_files)
protected_observed <- rep(NA_character_, length(protected_files))
protected_observed[protected_exists] <- unname(vapply(
  protected_files[protected_exists],
  artifact_sha256,
  character(1)
))
protected_inventory <- data.frame(
  path = protected_paths,
  expected_sha256 = unname(protected_expected),
  observed_sha256 = protected_observed,
  bytes = as.numeric(file.info(protected_files)$size),
  status = ifelse(
    protected_exists & protected_observed == unname(protected_expected),
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)
record_check(
  "protected_artifact_identities",
  all(protected_inventory$status == "PASS"),
  paste(nrow(protected_inventory), "protected identities"),
  paste(protected_inventory$path[protected_inventory$status != "PASS"], collapse = "|")
)

diff_relatives <- c(
  document_paths,
  "tests/hypotheses/H02/test_h02_reader_report.R",
  "tests/hypotheses/H02/test_h02_preparation_report.R",
  "tests/hypotheses/H02/test_h02_paired_placement_display.R",
  "audit/handoffs/H02_worker_handoff.md"
)
diff_lines <- character()
for (relative in diff_relatives) {
  output <- suppressWarnings(system2(
    "git",
    args = c(
      "diff", "--no-index", "--",
      file.path(baseline_dir, relative),
      file.path(root, relative)
    ),
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  record_check(
    paste0("source_diff_status_", gsub("[^A-Za-z0-9]+", "_", relative)),
    status %in% c(0L, 1L),
    "git diff --no-index status 0 or 1",
    as.character(status)
  )
  diff_lines <- c(diff_lines, output)
}
diff_path <- file.path(evidence_dir, "H02_order33_source_diff.patch")
writeLines(diff_lines, diff_path, useBytes = TRUE)

test_contract <- data.frame(
  test_id = c("reader_source_only", "preparation_source_only", "paired_placement"),
  path = c(
    "tests/hypotheses/H02/test_h02_reader_report.R",
    "tests/hypotheses/H02/test_h02_preparation_report.R",
    "tests/hypotheses/H02/test_h02_paired_placement_display.R"
  ),
  source_only = c(TRUE, TRUE, FALSE),
  stringsAsFactors = FALSE
)
rscript <- file.path(R.home("bin"), "Rscript")
test_results <- vector("list", nrow(test_contract))
for (index in seq_len(nrow(test_contract))) {
  entry <- test_contract[index, ]
  command_env <- c(paste0("NATHEALTH_PROJECT_ROOT=", root))
  if (entry$source_only) {
    command_env <- c(command_env, "H02_REPORT_SOURCE_ONLY=true")
  }
  command_args <- c("--vanilla", file.path(root, entry$path))
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
  test_results[[index]] <- data.frame(
    test_id = entry$test_id,
    command = paste(
      c(command_env, shQuote(rscript), "--vanilla", entry$path),
      collapse = " "
    ),
    exit_status = as.integer(status),
    elapsed_seconds = round(elapsed, 3),
    output = paste(output, collapse = " | "),
    stringsAsFactors = FALSE
  )
  record_check(
    paste0("focused_test_", entry$test_id),
    identical(as.integer(status), 0L),
    "exit status 0",
    as.character(status),
    paste(tail(output, 4L), collapse = " | ")
  )
}
test_results <- do.call(rbind, test_results)

scoped_paths <- c(
  diff_relatives,
  "audit/hypotheses/H02/report017_order33_source_rewrite"
)
diff_check_output <- system2(
  "git",
  args = c("diff", "--check", "--", diff_relatives),
  stdout = TRUE,
  stderr = TRUE
)
diff_check_status <- attr(diff_check_output, "status")
if (is.null(diff_check_status)) diff_check_status <- 0L
record_check(
  "scoped_git_diff_check",
  identical(as.integer(diff_check_status), 0L),
  "exit status 0",
  as.character(diff_check_status),
  paste(diff_check_output, collapse = " | ")
)

status_output <- system2(
  "git",
  args = c("status", "--short", "--", scoped_paths),
  stdout = TRUE,
  stderr = TRUE
)
status_path <- file.path(evidence_dir, "H02_order33_scoped_status.txt")
writeLines(status_output, status_path, useBytes = TRUE)

identity_paths <- unique(c(
  diff_relatives,
  "audit/hypotheses/H02/report017_order33_source_rewrite/run_h02_order33_source_audit.R",
  protected_paths
))
identity_files <- file.path(root, identity_paths)
current_identities <- data.frame(
  path = identity_paths,
  sha256 = unname(vapply(identity_files, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(identity_files)$size),
  stringsAsFactors = FALSE
)

package_names <- c("xml2", "readr", "dplyr", "gt", "knitr")
package_versions <- data.frame(
  component = c("R", package_names),
  version = c(
    as.character(getRversion()),
    vapply(
      package_names,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  stringsAsFactors = FALSE
)

reverse_checks <- checks[grepl(
  "preserved|canonicalization|write_assignment_removed|response_objects",
  checks$check_id
), , drop = FALSE]

utils::write.csv(
  checks,
  file.path(evidence_dir, "H02_order33_source_audit.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  test_results,
  file.path(evidence_dir, "H02_order33_test_results.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  current_identities,
  file.path(evidence_dir, "H02_order33_current_identities.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  package_versions,
  file.path(evidence_dir, "H02_order33_package_versions.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  reverse_checks,
  file.path(evidence_dir, "H02_order33_reverse_proof.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  protected_inventory,
  file.path(evidence_dir, "H02_order33_protected_inventory.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  historical_mismatch_records,
  file.path(evidence_dir, "H02_order33_historical_manifest_mismatches.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  companion_unlabeled_proof,
  file.path(evidence_dir, "H02_order33a_unlabeled_chunk_proof.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  companion_numeric_delta,
  file.path(evidence_dir, "H02_order33a_companion_numeric_token_delta.csv"),
  row.names = FALSE,
  na = ""
)

failures <- checks[checks$status != "PASS", , drop = FALSE]
execution_lines <- c(
  "# H02 order-33 source-only execution record",
  "",
  paste0("Date: ", format(Sys.Date(), "%Y-%m-%d")),
  "",
  paste0("R version: ", as.character(getRversion())),
  paste0("Checks passed: ", sum(checks$status == "PASS"), "/", nrow(checks)),
  paste0(
    "Focused tests passed: ",
    sum(test_results$exit_status == 0L),
    "/",
    nrow(test_results)
  ),
  "",
  "No Quarto render, QMD execution, model fit, prediction, bootstrap,",
  "simulation, Shapley allocation, p-value calculation, or figure regeneration",
  "was performed.",
  "",
  "## Focused commands",
  "",
  paste0("- `", test_results$command, "` (", test_results$elapsed_seconds, " s; exit ", test_results$exit_status, ")"),
  "",
  "## Historical render classification",
  "",
  "The Aug-1 preparation and worker manifests and both existing HTML pages",
  "remain byte-identical historical render evidence. They do not describe the",
  "revised source-only report state.",
  "",
  "## Known historical-to-live mismatch sets",
  "",
  paste0(
    "- `",
    historical_mismatch_records$manifest,
    "`: `",
    historical_mismatch_records$mismatch_path,
    "`"
  ),
  "",
  if (nrow(failures) == 0L) {
    "All prescribed source-only and preservation checks passed."
  } else {
    paste0("Stopped with ", nrow(failures), " failed checks; see H02_order33_source_audit.csv.")
  }
)
execution_path <- file.path(evidence_dir, "H02_order33_execution_record.md")
writeLines(execution_lines, execution_path, useBytes = TRUE)

evidence_relatives <- file.path(
  "audit/hypotheses/H02/report017_order33_source_rewrite",
  c(
    "run_h02_order33_source_audit.R",
    "H02_order33_source_audit.csv",
    "H02_order33_test_results.csv",
    "H02_order33_current_identities.csv",
    "H02_order33_package_versions.csv",
    "H02_order33_reverse_proof.csv",
    "H02_order33_protected_inventory.csv",
    "H02_order33_historical_manifest_mismatches.csv",
    "H02_order33a_unlabeled_chunk_proof.csv",
    "H02_order33a_companion_numeric_token_delta.csv",
    "H02_order33_source_diff.patch",
    "H02_order33_scoped_status.txt",
    "H02_order33_execution_record.md"
  )
)
manifest_paths <- unique(c(
  document_paths,
  "tests/hypotheses/H02/test_h02_reader_report.R",
  "tests/hypotheses/H02/test_h02_preparation_report.R",
  "tests/hypotheses/H02/test_h02_paired_placement_display.R",
  historical_manifest_paths,
  "audit/handoffs/H02_worker_handoff.md",
  protected_paths,
  "audit/report_harmonization/owner_orders/33_h02_consolidated_reader_rewrite.md",
  "audit/report_harmonization/report017_h02_consolidated_full_document_audit.md",
  "audit/report_harmonization/report017_h02_consolidated_change_matrix.csv",
  "audit/report_harmonization/report017_consolidated_document_pass_protocol.md",
  evidence_relatives
))
manifest_roles <- rep("protected source-only dependency", length(manifest_paths))
manifest_roles[manifest_paths %in% document_paths] <- "revised H02 authoring source"
manifest_roles[grepl("tests/hypotheses/H02/", manifest_paths, fixed = TRUE)] <-
  "H02 source and future-render test"
manifest_roles[manifest_paths %in% historical_manifest_paths] <-
  "unchanged historical render inventory"
manifest_roles[manifest_paths == "audit/handoffs/H02_worker_handoff.md"] <-
  "updated H02 owner handoff"
manifest_roles[grepl("_build/nathealth/", manifest_paths, fixed = TRUE)] <-
  "unchanged stale render context"
manifest_roles[grepl("report017_order33_source_rewrite/", manifest_paths, fixed = TRUE)] <-
  "order-33 source-only evidence"
manifest_roles[grepl("report_harmonization/", manifest_paths, fixed = TRUE)] <-
  "controlling order and audit context"

manifest_files <- file.path(root, manifest_paths)
source_manifest <- data.frame(
  path = manifest_paths,
  sha256 = unname(vapply(manifest_files, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(manifest_files)$size),
  role = manifest_roles,
  producer = "audit/hypotheses/H02/report017_order33_source_rewrite/run_h02_order33_source_audit.R",
  r_version = as.character(getRversion()),
  stringsAsFactors = FALSE
)
source_manifest <- source_manifest[order(source_manifest$path), , drop = FALSE]
source_manifest_path <- file.path(
  evidence_dir,
  "H02_order33_source_manifest.csv"
)
utils::write.csv(source_manifest, source_manifest_path, row.names = FALSE, na = "")
manifest_readback <- utils::read.csv(source_manifest_path, check.names = FALSE)
manifest_row_files <- file.path(root, manifest_readback$path)
manifest_rows_pass <-
  !source_manifest_path %in% manifest_row_files &&
  all(file.exists(manifest_row_files)) &&
  !anyDuplicated(manifest_readback$path) &&
  identical(
    unname(vapply(manifest_row_files, artifact_sha256, character(1))),
    unname(manifest_readback$sha256)
  ) &&
  identical(
    as.numeric(file.info(manifest_row_files)$size),
    as.numeric(manifest_readback$bytes)
  )

cat(
  paste0(
    "H02_ORDER33_CHECKS_PASSED=",
    sum(checks$status == "PASS"),
    "/",
    nrow(checks),
    "\n"
  )
)
cat(
  paste0(
    "H02_ORDER33_TESTS_PASSED=",
    sum(test_results$exit_status == 0L),
    "/",
    nrow(test_results),
    "\n"
  )
)
cat(paste0("H02_ORDER33_MANIFEST_ROWS=", nrow(source_manifest), "\n"))
cat(paste0("H02_ORDER33_MANIFEST_ROW_AUDIT=", manifest_rows_pass, "\n"))
cat(
  paste0(
    "H02_ORDER33_SOURCE_MANIFEST_SHA256=",
    artifact_sha256(source_manifest_path),
    "\n"
  )
)

if (nrow(failures) > 0L || !manifest_rows_pass) {
  quit(save = "no", status = 1L)
}
