#!/usr/bin/env Rscript

# REPORT-014/017 order 36 source-only verification for the H05 reader pair.
# This test reads and parses QMD source. It never executes a QMD chunk and
# never calculates or changes a scientific result.

options(stringsAsFactors = FALSE, warn = 1, width = 180)

started_at <- Sys.time()
started_elapsed <- proc.time()[["elapsed"]]

locate_project_root <- function(start = getwd()) {
  candidate <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(candidate, "renv.lock")) &&
        file.exists(file.path(candidate, "notebooks/hypotheses/H05.qmd"))
    ) {
      return(candidate)
    }
    parent <- dirname(candidate)
    if (identical(parent, candidate)) {
      stop("Could not locate the project root", call. = FALSE)
    }
    candidate <- parent
  }
}

root <- locate_project_root()
setwd(root)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H05 order-36 source verification requires R 4.6.1", call. = FALSE)
}
for (package in c("digest", "png")) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop("The synchronized project library must provide ", package, call. = FALSE)
  }
}

result_rel <- "notebooks/hypotheses/H05.qmd"
companion_rel <- "audit/hypotheses/H05/H05_analysis_preparation.qmd"
handoff_rel <- "audit/handoffs/H05_stage4_handoff.md"
test_rel <- "tests/hypotheses/H05/test_h05_report017_source_harmonization.R"
evidence_rel <- "audit/hypotheses/H05/report017_order36"
evidence_dir <- file.path(root, evidence_rel)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

result_path <- file.path(root, result_rel)
companion_path <- file.path(root, companion_rel)
handoff_path <- file.path(root, handoff_rel)
test_path <- file.path(root, test_rel)

checks <- data.frame(
  check_id = character(),
  status = character(),
  expected = character(),
  observed = character(),
  detail = character(),
  stringsAsFactors = FALSE
)

record_check <- function(
  check_id,
  condition,
  expected,
  observed,
  detail = ""
) {
  checks <<- rbind(
    checks,
    data.frame(
      check_id = as.character(check_id),
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

sha256_file <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

sha256_text <- function(text) {
  digest::digest(enc2utf8(text), algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) {
  if (!file.exists(path)) return(NA_real_)
  as.numeric(file.info(path)$size)
}

fixed_count <- function(text, value) {
  positions <- gregexpr(value, text, fixed = TRUE)[[1L]]
  if (identical(positions[[1L]], -1L)) 0L else length(positions)
}

regex_values <- function(text, pattern) {
  values <- regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1L]]
  values[values != ""]
}

extract_chunks <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  starts <- grep("^```\\{r(?:[^}]*)\\}\\s*$", lines, perl = TRUE)
  chunks <- vector("list", length(starts))
  labels <- character(length(starts))
  for (index in seq_along(starts)) {
    start <- starts[[index]]
    candidates <- which(seq_along(lines) > start & trimws(lines) == "```")
    if (!length(candidates)) {
      stop("Unclosed R chunk at line ", start, call. = FALSE)
    }
    end <- candidates[[1L]]
    body_lines <- if (end > start + 1L) {
      lines[(start + 1L):(end - 1L)]
    } else {
      character()
    }
    label_line <- grep(
      "^#\\|\\s*label:\\s*",
      body_lines,
      value = TRUE,
      perl = TRUE
    )
    label <- if (length(label_line) == 1L) {
      trimws(sub("^#\\|\\s*label:\\s*", "", label_line[[1L]], perl = TRUE))
    } else {
      paste0("unnamed-line-", start)
    }
    chunks[[index]] <- list(
      label = label,
      body = paste(body_lines, collapse = "\n"),
      start = start,
      end = end
    )
    labels[[index]] <- label
  }
  names(chunks) <- labels
  chunks
}

chunk_labels <- function(chunks) {
  vapply(chunks, `[[`, character(1), "label")
}

chunk_bodies <- function(chunks) {
  values <- vapply(chunks, `[[`, character(1), "body")
  names(values) <- chunk_labels(chunks)
  values
}

parse_chunk_errors <- function(chunks, document) {
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

extract_inline_r <- function(text) {
  regex_values(text, "(?<=`r )[^`]+(?=`)")
}

numeric_tokens <- function(text) {
  regex_values(
    text,
    "(?<![[:alnum:]])-?[0-9]+(?:[.,][0-9]+)*(?![[:alnum:]])"
  )
}

token_delta <- function(before, after) {
  before_table <- table(before)
  after_table <- table(after)
  keys <- sort(unique(c(names(before_table), names(after_table))))
  before_n <- as.integer(before_table[keys])
  after_n <- as.integer(after_table[keys])
  before_n[is.na(before_n)] <- 0L
  after_n[is.na(after_n)] <- 0L
  delta <- after_n - before_n
  value <- delta[delta != 0L]
  names(value) <- keys[delta != 0L]
  value
}

extract_formula_lines <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  trimws(lines[grepl("response_value ~", lines, fixed = TRUE)])
}

extract_markdown_targets <- function(text) {
  values <- regex_values(text, "\\]\\([^)]+\\)")
  sub("^\\]\\(", "", sub("\\)$", "", values))
}

extract_path_references <- function(text, prefix) {
  regex_values(
    text,
    paste0(prefix, "/[A-Za-z0-9_./*-]+")
  )
}

visible_prose <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  keep <- logical(length(lines))
  in_fence <- FALSE
  for (index in seq_along(lines)) {
    if (startsWith(trimws(lines[[index]]), "```")) {
      in_fence <- !in_fence
      next
    }
    keep[[index]] <- !in_fence
  }
  paste(lines[keep], collapse = "\n")
}

all_chunk_calls <- function(chunks) {
  unique(unlist(lapply(
    chunks,
    function(chunk) all.names(
      parse(text = chunk$body),
      functions = TRUE,
      unique = FALSE
    )
  )))
}

assignment_records <- function(chunks) {
  output <- data.frame(
    key = character(),
    chunk = character(),
    name = character(),
    rhs = character(),
    stringsAsFactors = FALSE
  )
  seen <- list()
  for (chunk in chunks) {
    expressions <- parse(text = chunk$body)
    for (expression in expressions) {
      operator <- if (
        is.call(expression) && is.symbol(expression[[1L]])
      ) {
        as.character(expression[[1L]])
      } else {
        NA_character_
      }
      if (
        is.call(expression) &&
          length(expression) >= 3L &&
          !is.na(operator) &&
          operator %in% c("<-", "=") &&
          is.symbol(expression[[2L]])
      ) {
        name <- as.character(expression[[2L]])
        stem <- paste(chunk$label, name, sep = "::")
        occurrence <- if (is.null(seen[[stem]])) 1L else seen[[stem]] + 1L
        seen[[stem]] <- occurrence
        output <- rbind(
          output,
          data.frame(
            key = paste(stem, occurrence, sep = "::"),
            chunk = chunk$label,
            name = name,
            rhs = paste(
              deparse(expression[[3L]], width.cutoff = 500L),
              collapse = "\n"
            ),
            stringsAsFactors = FALSE
          )
        )
      }
    }
  }
  output
}

all_targets_resolve <- function(text, document) {
  targets <- extract_markdown_targets(text)
  targets <- targets[!grepl("^(?:https?:|mailto:|#)", targets, perl = TRUE)]
  files <- sub("#.*$", "", targets)
  keep <- nzchar(files)
  data.frame(
    target = targets[keep],
    resolved = file.path(dirname(document), files[keep]),
    exists = file.exists(file.path(dirname(document), files[keep])),
    stringsAsFactors = FALSE
  )
}

manifest_mismatch_paths <- function(relative_path) {
  manifest <- utils::read.csv(
    file.path(root, relative_path),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  observed <- vapply(
    file.path(root, manifest$path),
    sha256_file,
    character(1)
  )
  sort(manifest$path[is.na(observed) | observed != manifest$sha256])
}

write_csv <- function(data, path) {
  utils::write.csv(data, path, row.names = FALSE, na = "")
}

current <- c(
  result = read_text(result_path),
  companion = read_text(companion_path),
  handoff = read_text(handoff_path)
)

pre_dir <- Sys.getenv("H05_ORDER36_PRE_DIR", unset = "")
pre_paths <- c(
  result = file.path(pre_dir, "H05.qmd.pre"),
  companion = file.path(pre_dir, "H05_analysis_preparation.qmd.pre"),
  handoff = file.path(pre_dir, "H05_stage4_handoff.md.pre")
)
pre_available <- nzchar(pre_dir) && all(file.exists(pre_paths))
record_check(
  "sealed_pre_edit_snapshots",
  pre_available,
  "three exact order-36 pre-edit snapshots",
  if (pre_available) pre_dir else "missing H05_ORDER36_PRE_DIR snapshots"
)
if (!pre_available) {
  stop("The one-shot order-36 test requires the sealed pre-edit snapshots", call. = FALSE)
}
pre <- vapply(pre_paths, read_text, character(1))

expected_pre <- data.frame(
  path = c(result_rel, companion_rel, handoff_rel),
  sha256 = c(
    "b4167419ce0f22b635d41c98d3d7edda2717fc73e6c963371f79035a334d793c",
    "f7d7d3ef4bdf9b29403e85592b7dd2737f7e3c9dcfdc0ff7275eeefa7735c28f",
    "896205d9b7f0403e7cb70023ebb392526e58a30825c4d2b151488098602018b4"
  ),
  bytes = c(70979, 74171, 14619),
  stringsAsFactors = FALSE
)
observed_pre_hashes <- vapply(pre_paths, sha256_file, character(1))
observed_pre_bytes <- vapply(pre_paths, file_bytes, numeric(1))
record_check(
  "sealed_pre_edit_identities",
  identical(unname(observed_pre_hashes), expected_pre$sha256) &&
    identical(unname(observed_pre_bytes), expected_pre$bytes),
  "exact three pre-edit hashes and byte counts",
  paste(observed_pre_hashes, collapse = "; ")
)

expected_final <- data.frame(
  path = c(result_rel, companion_rel, handoff_rel),
  sha256 = c(
    "7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0",
    "0a5296442b46c8b9e43773d97eb979ffbbf3512faabe6f4399da2214d38cb81c",
    "71a8d4664504da7b6e621d5b24aa699df793ee120373ae28aeb75d1c980246da"
  ),
  bytes = c(74309, 75630, 19132),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(expected_final))) {
  path <- file.path(root, expected_final$path[[index]])
  record_check(
    paste0("final_source_identity_", index),
    identical(sha256_file(path), expected_final$sha256[[index]]) &&
      identical(file_bytes(path), expected_final$bytes[[index]]),
    paste(expected_final$sha256[[index]], expected_final$bytes[[index]]),
    paste(sha256_file(path), file_bytes(path)),
    expected_final$path[[index]]
  )
}

current_chunks <- list(
  result = extract_chunks(current[["result"]]),
  companion = extract_chunks(current[["companion"]])
)
pre_chunks <- list(
  result = extract_chunks(pre[["result"]]),
  companion = extract_chunks(pre[["companion"]])
)

expected_result_tables <- c(
  "tbl-h05-near-results-a",
  "tbl-h05-near-results-b",
  "tbl-h05-chest-results-a",
  "tbl-h05-chest-results-b",
  "tbl-h05-chest-adequacy-counts",
  "tbl-h05-chest-limitations",
  "tbl-h05-chest-sleep-diagnostics",
  "tbl-h05-near-adequacy-counts",
  "tbl-h05-near-limitations",
  "tbl-h05-near-sleep-diagnostics",
  "tbl-h05-mder-primary-scenarios",
  "tbl-h05-mder-gap-scenarios",
  "tbl-h05-mder-upper-tail",
  "tbl-h05-mder-influence",
  "tbl-h05-paired-f2",
  "tbl-h05-paired-f3",
  "tbl-h05-paired-f4",
  "tbl-h05-paired-f5",
  "tbl-h05-leading-sensitivities",
  "tbl-h05-descriptive-spearman",
  "tbl-h05-random-site-summary",
  "tbl-h05-leave-site-summary",
  "tbl-h05-exact-period",
  "tbl-h05-factors",
  "tbl-h05-near-samples",
  "tbl-h05-chest-samples",
  "tbl-h05-formulas",
  "tbl-h05-response-specifications",
  "tbl-h05-model-deviations",
  "tbl-h05-data-deviations"
)
expected_result_figures <- c(
  "fig-h05-near-effects",
  "fig-h05-chest-effects",
  "fig-h05-chest-adequacy",
  "fig-h05-near-adequacy",
  "fig-h05-near-residual-fitted",
  "fig-h05-near-residual-qq",
  "fig-h05-paired-placement"
)
expected_companion_tables <- c(
  "tbl-h05-prep-input-identities",
  "tbl-h05-prep-integrity-checks",
  "tbl-h05-prep-factor-contract",
  "tbl-h05-prep-leba-audit",
  "tbl-h05-prep-metric-contract",
  "tbl-h05-prep-primary-samples",
  "tbl-h05-prep-site-support",
  "tbl-h05-prep-family-audit",
  "tbl-h05-prep-site-structure",
  "tbl-h05-prep-exact-formulas",
  "tbl-h05-prep-model-settings",
  "tbl-h05-prep-diagnostic-overview",
  "tbl-h05-prep-sleep-disposition",
  "tbl-h05-prep-sensitivity-map",
  "tbl-h05-prep-mder-diagnostics",
  "tbl-h05-prep-gap-mder-diagnostics",
  "tbl-h05-prep-boundary",
  "tbl-h05-prep-l10-reseal",
  "tbl-h05-prep-module-map",
  "tbl-h05-prep-script-map",
  "tbl-h05-prep-output-identities",
  "tbl-h05-prep-environment"
)
expected_companion_figures <- c(
  "fig-h05-prep-leba-distribution",
  "fig-h05-prep-sample-support",
  "fig-h05-prep-site-range"
)

result_labels <- unname(chunk_labels(current_chunks$result))
companion_labels <- unname(chunk_labels(current_chunks$companion))
result_tables <- result_labels[startsWith(result_labels, "tbl-h05-")]
result_figures <- result_labels[startsWith(result_labels, "fig-h05-")]
companion_tables <- companion_labels[
  startsWith(companion_labels, "tbl-h05-prep-")
]
companion_figures <- companion_labels[
  startsWith(companion_labels, "fig-h05-prep-")
]

record_check(
  "result_table_endpoints",
  identical(result_tables, expected_result_tables) &&
    !anyDuplicated(result_tables),
  "30 exact table labels in approved order",
  paste(result_tables, collapse = "; ")
)
record_check(
  "result_figure_endpoints",
  identical(result_figures, expected_result_figures) &&
    !anyDuplicated(result_figures),
  "7 exact figure labels in approved order",
  paste(result_figures, collapse = "; ")
)
record_check(
  "result_first_endpoints",
  identical(result_figures[[1L]], "fig-h05-near-effects") &&
    identical(result_tables[1:2], c(
      "tbl-h05-near-results-a",
      "tbl-h05-near-results-b"
    )),
  "near-eye figure first and continued near-eye table parts first",
  paste(result_figures[[1L]], paste(result_tables[1:2], collapse = ", "))
)
record_check(
  "companion_table_endpoints",
  identical(companion_tables, expected_companion_tables) &&
    !anyDuplicated(companion_tables),
  "22 exact table labels in approved order",
  paste(companion_tables, collapse = "; ")
)
record_check(
  "companion_figure_endpoints",
  identical(companion_figures, expected_companion_figures) &&
    !anyDuplicated(companion_figures),
  "3 exact figure labels in approved order",
  paste(companion_figures, collapse = "; ")
)

parse_errors <- c(
  parse_chunk_errors(current_chunks$result, result_rel),
  parse_chunk_errors(current_chunks$companion, companion_rel)
)
record_check(
  "all_r_chunks_parse_without_execution",
  length(parse_errors) == 0L,
  "every R chunk parses without execution",
  paste(parse_errors, collapse = "; ")
)

record_check(
  "chunk_label_sets_preserved",
  identical(
    sort(chunk_labels(current_chunks$result)),
    sort(chunk_labels(pre_chunks$result))
  ) && identical(
    sort(chunk_labels(current_chunks$companion)),
    sort(chunk_labels(pre_chunks$companion))
  ),
  "exact pre-edit chunk-label sets",
  "result and companion"
)

current_bodies <- list(
  result = chunk_bodies(current_chunks$result),
  companion = chunk_bodies(current_chunks$companion)
)
pre_bodies <- list(
  result = chunk_bodies(pre_chunks$result),
  companion = chunk_bodies(pre_chunks$companion)
)
changed_labels <- function(before, after) {
  labels <- sort(intersect(names(before), names(after)))
  labels[!vapply(labels, function(label) {
    identical(before[[label]], after[[label]])
  }, logical(1))]
}
expected_changed_result_chunks <- sort(c(
  "setup-h05-reader",
  "tbl-h05-model-deviations"
))
expected_changed_companion_chunks <- sort(c(
  "tbl-h05-prep-input-identities",
  "tbl-h05-prep-integrity-checks",
  "tbl-h05-prep-leba-audit",
  "tbl-h05-prep-site-support",
  "fig-h05-prep-site-range",
  "tbl-h05-prep-family-audit",
  "tbl-h05-prep-model-settings",
  "tbl-h05-prep-boundary",
  "tbl-h05-prep-module-map",
  "tbl-h05-prep-script-map",
  "tbl-h05-prep-output-identities"
))
observed_changed_result_chunks <- changed_labels(
  pre_bodies$result,
  current_bodies$result
)
observed_changed_companion_chunks <- changed_labels(
  pre_bodies$companion,
  current_bodies$companion
)
record_check(
  "explicit_display_chunk_allowlist",
  identical(
    observed_changed_result_chunks,
    expected_changed_result_chunks
  ) && identical(
    observed_changed_companion_chunks,
    expected_changed_companion_chunks
  ),
  "2 result and 11 companion display-only changed chunks",
  paste(
    paste(observed_changed_result_chunks, collapse = ", "),
    paste(observed_changed_companion_chunks, collapse = ", "),
    sep = " | "
  )
)

record_check(
  "inline_r_preserved",
  identical(
    sort(extract_inline_r(current[["result"]])),
    sort(extract_inline_r(pre[["result"]]))
  ) && identical(
    sort(extract_inline_r(current[["companion"]])),
    sort(extract_inline_r(pre[["companion"]]))
  ),
  "exact pre-edit inline-R expression multisets",
  paste(
    length(extract_inline_r(current[["result"]])),
    length(extract_inline_r(current[["companion"]]))
  )
)

record_check(
  "formula_text_preserved",
  identical(
    sort(extract_formula_lines(current[["result"]])),
    sort(extract_formula_lines(pre[["result"]]))
  ) && identical(
    sort(extract_formula_lines(current[["companion"]])),
    sort(extract_formula_lines(pre[["companion"]]))
  ),
  "exact response_value Wilkinson formula-line multisets",
  paste(
    length(extract_formula_lines(current[["result"]])),
    length(extract_formula_lines(current[["companion"]]))
  )
)

result_numeric_delta <- token_delta(
  numeric_tokens(pre[["result"]]),
  numeric_tokens(current[["result"]])
)
companion_numeric_delta <- token_delta(
  numeric_tokens(pre[["companion"]]),
  numeric_tokens(current[["companion"]])
)
record_check(
  "scientific_numeric_tokens_preserved",
  length(result_numeric_delta) == 0L &&
    identical(companion_numeric_delta, c("12" = -1L, "17" = 1L)),
  "no result delta; companion only removes one 12 and adds one 17",
  paste(
    paste(names(result_numeric_delta), result_numeric_delta, sep = ":"),
    paste(names(companion_numeric_delta), companion_numeric_delta, sep = ":"),
    collapse = "; "
  )
)

for (prefix in c("artifacts", "scripts")) {
  record_check(
    paste0(prefix, "_references_preserved"),
    identical(
      sort(extract_path_references(current[["result"]], prefix)),
      sort(extract_path_references(pre[["result"]], prefix))
    ) && identical(
      sort(extract_path_references(current[["companion"]], prefix)),
      sort(extract_path_references(pre[["companion"]], prefix))
    ),
    paste("exact pre-edit", prefix, "reference multisets"),
    "result and companion"
  )
}

current_assignments <- rbind(
  transform(assignment_records(current_chunks$result), document = "result"),
  transform(
    assignment_records(current_chunks$companion),
    document = "companion"
  )
)
pre_assignments <- rbind(
  transform(assignment_records(pre_chunks$result), document = "result"),
  transform(assignment_records(pre_chunks$companion), document = "companion"
  )
)
current_assignments$full_key <- paste(
  current_assignments$document,
  current_assignments$key,
  sep = "::"
)
pre_assignments$full_key <- paste(
  pre_assignments$document,
  pre_assignments$key,
  sep = "::"
)
record_check(
  "top_level_assignment_sets_preserved",
  identical(
    sort(current_assignments$full_key),
    sort(pre_assignments$full_key)
  ),
  "exact top-level assignment key set",
  paste(nrow(current_assignments), nrow(pre_assignments))
)
assignment_keys <- sort(intersect(
  current_assignments$full_key,
  pre_assignments$full_key
))
current_rhs <- setNames(current_assignments$rhs, current_assignments$full_key)
pre_rhs <- setNames(pre_assignments$rhs, pre_assignments$full_key)
changed_rhs <- assignment_keys[!vapply(assignment_keys, function(key) {
  identical(current_rhs[[key]], pre_rhs[[key]])
}, logical(1))]
expected_changed_rhs <- sort(c(
  "result::setup-h05-reader::mder_influence_summary::1",
  paste0(
    "companion::tbl-h05-prep-input-identities::verified_inputs::1"
  ),
  paste0(
    "companion::tbl-h05-prep-integrity-checks::integrity_checks::1"
  ),
  paste0(
    "companion::tbl-h05-prep-output-identities::output_registry::1"
  )
))
record_check(
  "top_level_assignment_rhs_allowlist",
  identical(changed_rhs, expected_changed_rhs),
  "only four non-mutating display assignment RHS changes",
  paste(changed_rhs, collapse = "; ")
)

expected_headings <- c(
  "## Question",
  "## Orientation",
  "## Primary near-eye result",
  "## Complementary chest evidence",
  "## Model checks and the unfit sleep-environment boundary",
  "## MDER results and upper-tail checks",
  "## Sensitivity analyses",
  "## Interpretation and limitations",
  "## Detailed analysis record",
  "## Preregistration and operational context",
  "## Source data and technical provenance"
)
heading_positions <- vapply(
  expected_headings,
  function(value) regexpr(value, current[["result"]], fixed = TRUE)[[1L]],
  integer(1)
)
record_check(
  "result_heading_order",
  all(heading_positions > 0L) && all(diff(heading_positions) > 0L),
  "approved main-first result hierarchy",
  paste(expected_headings, collapse = "; ")
)

disclosure_labels <- c(
  "Show complementary chest results and model checks",
  "Show detailed near-eye model checks",
  "Show MDER details and upper-tail checks",
  "Show detailed sensitivity results"
)
record_check(
  "exact_progressive_disclosures",
  all(vapply(
    disclosure_labels,
    function(value) fixed_count(current[["result"]], value) == 1L,
    logical(1)
  )) && fixed_count(
    current[["result"]],
    "Implementation history for the current MDER and numerical-zero rules"
  ) == 1L && fixed_count(current[["result"]], "<details>") == 5L &&
    fixed_count(current[["result"]], "</details>") == 5L,
  "four exact analytical disclosures plus one subordinate history disclosure",
  paste(disclosure_labels, collapse = "; ")
)

record_check(
  "lightbox_enabled",
  fixed_count(current[["result"]], "lightbox: true") == 1L &&
    fixed_count(current[["companion"]], "lightbox: true") == 1L,
  "lightbox enabled once in each YAML header",
  "result and companion"
)

record_check(
  "reciprocal_dynamic_qmd_links",
  fixed_count(
    current[["result"]],
    "../../audit/hypotheses/H05/H05_analysis_preparation.qmd"
  ) == 1L && fixed_count(
    current[["companion"]],
    "../../../notebooks/hypotheses/H05.qmd"
  ) >= 2L && fixed_count(
    current[["companion"]],
    paste0(
      "../../../notebooks/hypotheses/H05.qmd",
      "#h05-preregistration-deviations"
    )
  ) == 1L,
  "exact reciprocal QMD links and companion result-anchor link",
  "dynamic source links"
)

registration_ids <- c(
  "dev-001", "rep-001", "rep-002", "dev-028", "dev-029",
  "dev-054", "dev-058", "imp-001", "imp-006"
)
deviation_text <- read_text(file.path(root, "notebooks/preregistration_deviations.qmd"))
registration_links_ok <- all(vapply(
  registration_ids,
  function(id) fixed_count(
    current[["result"]],
    paste0("../preregistration_deviations.qmd#", id)
  ) == 1L,
  logical(1)
))
registration_anchors_ok <- all(vapply(
  registration_ids,
  function(id) fixed_count(deviation_text, paste0("{#", id, "}")) == 1L,
  logical(1)
))
record_check(
  "registration_links_and_anchors",
  registration_links_ok && registration_anchors_ok &&
    fixed_count(
      current[["result"]],
      "{#h05-preregistration-deviations}"
    ) == 1L,
  "nine exact registration links, central anchors, and result anchor",
  paste(registration_ids, collapse = ", ")
)

preparation_links <- c(
  "../preparation/04_metric_derivation.qmd",
  "../preparation/06_model_ready_datasets.qmd"
)
companion_preparation_links <- c(
  "../../../notebooks/preparation/04_metric_derivation.qmd",
  "../../../notebooks/preparation/06_model_ready_datasets.qmd"
)
record_check(
  "preparation_04_and_06_links",
  all(vapply(
    preparation_links,
    function(value) fixed_count(current[["result"]], value) == 1L,
    logical(1)
  )) && all(vapply(
    companion_preparation_links,
    function(value) fixed_count(current[["companion"]], value) == 1L,
    logical(1)
  )),
  "Preparation 04 and 06 links in both reader sources",
  "four dynamic QMD links"
)

result_targets <- all_targets_resolve(current[["result"]], result_rel)
companion_targets <- all_targets_resolve(current[["companion"]], companion_rel)
record_check(
  "all_relative_targets_resolve",
  all(result_targets$exists) && all(companion_targets$exists),
  "all QMD, registration, artifact, and source-data targets exist",
  paste(c(
    result_targets$target[!result_targets$exists],
    companion_targets$target[!companion_targets$exists]
  ), collapse = "; ")
)

all_page_targets <- c(
  extract_markdown_targets(current[["result"]]),
  extract_markdown_targets(current[["companion"]])
)
bad_page_targets <- all_page_targets[
  grepl("[.]html(?:$|#)|_build|file://|/Users/", all_page_targets) |
    (startsWith(all_page_targets, "/") &
      !grepl("^https?://", all_page_targets))
]
record_check(
  "no_hard_coded_page_links",
  length(bad_page_targets) == 0L,
  "no internal HTML, build, file, absolute-local, or root-absolute page link",
  paste(bad_page_targets, collapse = "; ")
)

result_visible <- visible_prose(current[["result"]])
companion_visible <- visible_prose(current[["companion"]])
visible_combined <- paste(result_visible, companion_visible, sep = "\n")
visible_compact <- gsub("[[:space:]]+", " ", visible_combined)
record_check(
  "approved_reader_vocabulary",
  !grepl("submitted[- ](?:manuscript|site)", visible_combined, ignore.case = TRUE) &&
    !grepl("\\bBH\\b", visible_combined, perl = TRUE) &&
    !grepl("H05-F[123]", visible_combined, perl = TRUE) &&
    !grepl("—", visible_combined, fixed = TRUE) &&
    !grepl("\\bV0\\b", visible_combined, perl = TRUE) &&
    !grepl("direct retinal measurement", visible_combined, ignore.case = TRUE),
  "approved study-site, FDR, family, historical, and punctuation vocabulary",
  "reader-visible prose scanned with code fences removed"
)

site_names <- c(
  "Borås", "Delft", "Dortmund", "Tübingen", "Munich", "Madrid",
  "Izmir", "San José", "Kumasi"
)
source_combined <- paste(current[c("result", "companion")], collapse = "\n")
uncoded_sites <- site_names[vapply(
  site_names,
  function(site) grepl(
    paste0(site, "(?! \\([A-Z]{2}\\))"),
    source_combined,
    perl = TRUE
  ),
  logical(1)
)]
record_check(
  "literal_sites_country_coded",
  length(uncoded_sites) == 0L &&
    grepl("Tübingen (DE)", source_combined, fixed = TRUE) &&
    grepl("Madrid (ES)", source_combined, fixed = TRUE) &&
    grepl("San José (CR)", source_combined, fixed = TRUE),
  "every literal site name has a country code",
  paste(uncoded_sites, collapse = "; ")
)

reader_terms <- c(
  "measures light close to the eyes",
  "participant-day",
  "participant-level standard deviation",
  "95% confidence interval",
  "False-discovery-rate (FDR)",
  "the same participants and participant-days at both sensor positions",
  "fixed effect",
  "random effect",
  "sensitivity analysis",
  "A Tweedie model is",
  "Back-transformation converts",
  "A likelihood-ratio comparison asks"
)
record_check(
  "reader_terms_explained",
  all(vapply(
    reader_terms,
    function(value) grepl(value, visible_compact, fixed = TRUE),
    logical(1)
  )),
  "all required reader terms explained",
  paste(reader_terms, collapse = "; ")
)

science_phrases <- c(
  "Near-eye measurements are primary",
  "complementary, non-ocular evidence",
  "four factors × 17 metrics = 68 tests",
  "zero of 68",
  "four sleep-environment cells",
  "unfit for H05 inference",
  "This is neither an equivalence test nor a direct test of a placement effect",
  "fixed site for primary inference and random site only as a stability assessment",
  "arithmetic mean of viable one-minute melEDI/illuminance ratios",
  "same general 50%-per-hour and 80%-per-day coverage rules",
  "15 were unstable",
  "leave-one-site-out",
  "exactly identified longest-period analysis"
)
record_check(
  "scientific_boundaries_preserved",
  all(vapply(
    science_phrases,
    function(value) grepl(value, visible_compact, fixed = TRUE),
    logical(1)
  )),
  "primary, complementary, family, unfit, model, MDER, and sensitivity roles",
  paste(science_phrases, collapse = "; ")
)

record_check(
  "unfit_scope_and_suppression",
  grepl(
    paste0(
      "This judgment applies only to the H05 response and model structure. ",
      "It does not rule out analysing the underlying metric in another ",
      "hypothesis with a different response variable, estimand, or model structure."
    ),
    gsub("[[:space:]]+", " ", result_visible),
    fixed = TRUE
  ) && grepl(
    "Their estimates, confidence intervals, and p-values are suppressed",
    gsub("[[:space:]]+", " ", result_visible),
    fixed = TRUE
  ),
  "four unfit cells suppressed only for the H05 response and model structure",
  "reader-facing inference boundary"
)

record_check(
  "mder_and_gap_definitions_before_details",
  regexpr(
    "A predefined sensitivity uses the **gap-timing-unaware dataset**",
    current[["result"]],
    fixed = TRUE
  )[[1L]] < regexpr(
    "Show MDER details and upper-tail checks",
    current[["result"]],
    fixed = TRUE
  )[[1L]] && regexpr(
    "MDER is the arithmetic mean of viable one-minute",
    current[["result"]],
    fixed = TRUE
  )[[1L]] < regexpr(
    "Show MDER details and upper-tail checks",
    current[["result"]],
    fixed = TRUE
  )[[1L]],
  "gap-timing-unaware and MDER definitions precede detailed display",
  "definitions positioned before short-form use in result detail"
)

companion_display_contract <- c(
  "## About this analysis record",
  "Verification_code = if_else",
  "PASS = \"Verified\"",
  "FAIL = \"Review needed\"",
  "\"17 matches\"",
  "Model_component = \"Model component\"",
  "Calculated_on_render = \"Calculated when rendered\"",
  "Reads_or_defines = \"Reads or defines\"",
  "Why_separate = \"Why separate\"",
  "Entry_point = \"Entry point\"",
  "Runs_when_page_renders = \"Runs when page renders\"",
  paste0(
    "\"Reader report source\", \"notebooks/hypotheses/H05.qmd\", ",
    "\"Quarto source authoring\""
  )
)
record_check(
  "companion_display_mappings",
  all(vapply(
    companion_display_contract,
    function(value) grepl(value, current[["companion"]], fixed = TRUE),
    logical(1)
  )) && !grepl("_build/", current[["companion"]], fixed = TRUE),
  "verification, integrity, labels, and source-output mappings",
  paste(companion_display_contract, collapse = "; ")
)

record_check(
  "companion_fail_closed_identity_logic",
  grepl(
    "nrow(verified_inputs) == 17L",
    current[["companion"]],
    fixed = TRUE
  ) && grepl(
    "all(verified_inputs$Verification_code == \"PASS\")",
    current[["companion"]],
    fixed = TRUE
  ) && grepl(
    "sum(verified_inputs$Verification_code == \"PASS\")",
    current[["companion"]],
    fixed = TRUE
  ),
  "17 comparisons with internal PASS/FAIL fail-closed checks",
  "display mapping does not alter verification logic"
)

prohibited_calls <- c(
  "write.csv", "write.table", "writeLines", "save", "saveRDS",
  "file.copy", "file.rename", "unlink", "dir.create",
  "readr::write_csv", "readr::write_tsv", "data.table::fwrite",
  "lm", "stats::lm", "glm", "stats::glm", "glmmTMB",
  "glmmTMB::glmmTMB", "lmer", "lme4::lmer", "glmer",
  "lme4::glmer", "gam", "mgcv::gam", "bam", "mgcv::bam",
  "gamm", "mgcv::gamm", "predict", "stats::predict", "simulate",
  "stats::simulate", "boot", "boot::boot", "bootstrap", "resample",
  "p.adjust", "stats::p.adjust", "ggsave", "ggplot2::ggsave"
)
observed_calls <- unique(c(
  all_chunk_calls(current_chunks$result),
  all_chunk_calls(current_chunks$companion)
))
present_prohibited_calls <- intersect(prohibited_calls, observed_calls)
model_builder_source <- grepl(
  "source\\([^)]*scripts/hypotheses/H05",
  paste(current[c("result", "companion")], collapse = "\n"),
  perl = TRUE
)
record_check(
  "no_scientific_or_project_write_calls",
  length(present_prohibited_calls) == 0L && !model_builder_source,
  "no write, fit, predict, simulation, resampling, FDR, or builder-source call",
  paste(present_prohibited_calls, collapse = "; ")
)

existing_identities <- data.frame(
  path = c(
    "tests/hypotheses/H05/test_h05_stage2.R",
    "tests/hypotheses/H05/test_h05_stage3_reader_report.R",
    "tests/hypotheses/H05/test_h05_preparation_report.R",
    "artifacts/12_manifests/H05/H05_stage2_artifacts.csv",
    "artifacts/12_manifests/H05/H05_stage3_artifacts.csv",
    "artifacts/12_manifests/H05/H05_preparation_report_manifest.csv"
  ),
  sha256 = c(
    "76008cadabc573005f4833c21494a61f034ff376ea6ef92612691e2694bbb1b7",
    "982162ccbd55def924beff3fbb0e98d31a94884aeb8cc683f817189e1171d4f4",
    "ec738f56fb8b3cf94755fd5055d128d1a22bcc31a435554568aaa15acf78890e",
    "09363abf0557646870d0752f08b00f42013deec471a1ea97067c2333a1a811cc",
    "9dabc70a0ab6554a0b4d9dbc175cd4009b1f57a57c975cb4677b45ead2620100",
    "bd4ae8ac8516e961d1c4a37b1c18d3262376cd27ba0ed9611b7b60d167059c36"
  ),
  bytes = c(17076, 30898, 15264, 15631, 42166, 34048),
  stringsAsFactors = FALSE
)
bad_existing <- character()
for (index in seq_len(nrow(existing_identities))) {
  path <- file.path(root, existing_identities$path[[index]])
  if (
    !identical(sha256_file(path), existing_identities$sha256[[index]]) ||
      !identical(file_bytes(path), existing_identities$bytes[[index]])
  ) {
    bad_existing <- c(bad_existing, existing_identities$path[[index]])
  }
}
record_check(
  "existing_tests_and_manifests_preserved",
  length(bad_existing) == 0L,
  "three exact tests and three exact manifests",
  paste(bad_existing, collapse = "; ")
)

stage2_mismatch <- manifest_mismatch_paths(
  "artifacts/12_manifests/H05/H05_stage2_artifacts.csv"
)
stage3_mismatch <- manifest_mismatch_paths(
  "artifacts/12_manifests/H05/H05_stage3_artifacts.csv"
)
preparation_mismatch <- manifest_mismatch_paths(
  "artifacts/12_manifests/H05/H05_preparation_report_manifest.csv"
)
expected_stage3_mismatch <- sort(c(
  "audit/ledgers/change_log.csv",
  "audit/ledgers/hypothesis_stage_gates.csv",
  "notebooks/hypotheses/H05.qmd",
  "_quarto-nathealth.yml"
))
expected_preparation_mismatch <- sort(c(
  "notebooks/hypotheses/H05.qmd",
  "audit/hypotheses/H05/H05_analysis_preparation.qmd",
  "_quarto-nathealth.yml",
  "scripts/hypotheses/H01/h01_contract.R"
))
record_check(
  "stage2_manifest_mismatch_set",
  length(stage2_mismatch) == 0L,
  "zero Stage 2 manifest mismatches",
  paste(stage2_mismatch, collapse = "; ")
)
record_check(
  "stage3_manifest_mismatch_set",
  identical(stage3_mismatch, expected_stage3_mismatch),
  "exact four-path historical Stage 3 mismatch set",
  paste(stage3_mismatch, collapse = "; ")
)
record_check(
  "preparation_manifest_mismatch_set",
  identical(preparation_mismatch, expected_preparation_mismatch),
  "exact four-path historical preparation mismatch set",
  paste(preparation_mismatch, collapse = "; ")
)

stable_context <- data.frame(
  path = c(
    "_build/nathealth/notebooks/hypotheses/H05.html",
    paste0(
      "_build/nathealth/audit/hypotheses/H05/",
      "H05_analysis_preparation.html"
    ),
    "_quarto-nathealth.yml",
    "notebooks/preregistration_deviations.qmd",
    "config/site_display_registry.csv",
    "audit/report_harmonization/phase2_main_supplement_output_catalog.csv"
  ),
  sha256 = c(
    "58be9b4da8bb67a4322af7096472de1bf97c47d17c79f39078692577a2788b96",
    "c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894"
  ),
  bytes = c(573311, 839152, 7480, 94061, 295, 165132),
  stringsAsFactors = FALSE
)
bad_context <- character()
for (index in seq_len(nrow(stable_context))) {
  path <- file.path(root, stable_context$path[[index]])
  if (
    !identical(sha256_file(path), stable_context$sha256[[index]]) ||
      !identical(file_bytes(path), stable_context$bytes[[index]])
  ) {
    bad_context <- c(bad_context, stable_context$path[[index]])
  }
}
record_check(
  "stale_html_and_shared_context_preserved",
  length(bad_context) == 0L,
  "two stale HTML files and four shared contexts exact",
  paste(bad_context, collapse = "; ")
)

order_package <- data.frame(
  path = c(
    "audit/report_harmonization/owner_orders/36_h05_consolidated_reader_and_companion_rewrite.md",
    "audit/report_harmonization/report017_h05_consolidated_full_document_audit.md",
    "audit/report_harmonization/report017_h05_consolidated_change_matrix.csv",
    "audit/report_harmonization/report017_h05_consolidated_audit_manifest.csv",
    "audit/report_harmonization/report017_consolidated_document_pass_protocol.md"
  ),
  sha256 = c(
    "8b6f6cd056106ac0836edab81e5f1db49674642c22608e5ef7d965c764bcc560",
    "c27b15a29fc56142419dda2f2d5ecb860ad18775a67096fdffe857eb00e7932d",
    "5edf51a846e2d187bb76a534e4fe533b7e551c929f9fbf659fb8362b88f625b7",
    "b3e29a03f349e6ffa4cf1ab0adf5f39e8d6262fe4f2f38efdd51ccc63a59f452",
    "13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923"
  ),
  bytes = c(19645, 15772, 11780, 4271, 3839),
  stringsAsFactors = FALSE
)
bad_package <- character()
for (index in seq_len(nrow(order_package))) {
  path <- file.path(root, order_package$path[[index]])
  if (
    !identical(sha256_file(path), order_package$sha256[[index]]) ||
      !identical(file_bytes(path), order_package$bytes[[index]])
  ) {
    bad_package <- c(bad_package, order_package$path[[index]])
  }
}
record_check(
  "controlling_order_package_preserved",
  length(bad_package) == 0L,
  "five exact controlling order-package identities",
  paste(bad_package, collapse = "; ")
)

package_manifest <- utils::read.csv(
  file.path(
    root,
    "audit/report_harmonization/report017_h05_consolidated_audit_manifest.csv"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
mutable_package_paths <- c(result_rel, companion_rel, handoff_rel)
protected_package <- package_manifest[
  !package_manifest$path %in% mutable_package_paths,
  ,
  drop = FALSE
]
bad_protected_package <- character()
for (index in seq_len(nrow(protected_package))) {
  path <- file.path(root, protected_package$path[[index]])
  if (
    !identical(sha256_file(path), protected_package$sha256[[index]]) ||
      !identical(file_bytes(path), as.numeric(protected_package$bytes[[index]]))
  ) {
    bad_protected_package <- c(
      bad_protected_package,
      protected_package$path[[index]]
    )
  }
}
record_check(
  "controlling_manifest_protected_rows",
  nrow(package_manifest) == 27L && length(bad_protected_package) == 0L,
  "24 protected rows from the 27-row controlling manifest",
  paste(bad_protected_package, collapse = "; ")
)

figure_contract <- data.frame(
  path = c(
    "artifacts/10_figures/H05/H05_reader_near_eye_effects.png",
    "artifacts/10_figures/H05/H05_reader_near_eye_adequacy.png",
    "artifacts/10_figures/H05/H05_reader_paired_placement_effects.png"
  ),
  role = c(
    "provisional main figure",
    "supplemental model-check figure",
    "supplemental paired-placement figure"
  ),
  sha256 = c(
    "70c1013d51f7619fafe0d38664db7dcf55692990993098948ed443e83c35e1a5",
    "a457fda5dfb9025f21b72daab52c3e5338ba1657f7183ad4726ddd9b57561edf",
    "b30291d1c1f483202b6b3303045a760e03ef43b1fdf18a36a525543b1a387774"
  ),
  bytes = c(487117, 306686, 240045),
  width_px = c(2700L, 2700L, 2700L),
  height_px = c(2700L, 2550L, 2400L),
  dpi = c(300L, 300L, 300L),
  stringsAsFactors = FALSE
)
figure_observed <- figure_contract
figure_observed$current_sha256 <- NA_character_
figure_observed$current_bytes <- NA_real_
figure_observed$current_width_px <- NA_integer_
figure_observed$current_height_px <- NA_integer_
figure_observed$current_dpi <- NA_integer_
figure_observed$status <- "FAIL"
for (index in seq_len(nrow(figure_observed))) {
  path <- file.path(root, figure_observed$path[[index]])
  figure_observed$current_sha256[[index]] <- sha256_file(path)
  figure_observed$current_bytes[[index]] <- file_bytes(path)
  image <- png::readPNG(path, native = TRUE, info = TRUE)
  info <- attr(image, "info")
  figure_observed$current_width_px[[index]] <- as.integer(info$dim[[1L]])
  figure_observed$current_height_px[[index]] <- as.integer(info$dim[[2L]])
  dpi <- if (is.null(info$dpi)) NA_real_ else info$dpi[[1L]]
  figure_observed$current_dpi[[index]] <- as.integer(round(dpi))
  figure_observed$status[[index]] <- if (
    identical(figure_observed$current_sha256[[index]], figure_observed$sha256[[index]]) &&
      identical(figure_observed$current_bytes[[index]], figure_observed$bytes[[index]]) &&
      identical(figure_observed$current_width_px[[index]], figure_observed$width_px[[index]]) &&
      identical(figure_observed$current_height_px[[index]], figure_observed$height_px[[index]]) &&
      identical(figure_observed$current_dpi[[index]], figure_observed$dpi[[index]])
  ) "PASS" else "FAIL"
}
record_check(
  "stored_figure_identities_and_geometry",
  all(figure_observed$status == "PASS"),
  "three exact stored figures with 2700-pixel width and 300 dpi",
  paste(figure_observed$path[figure_observed$status != "PASS"], collapse = "; ")
)

source_and_builder <- data.frame(
  path = c(
    "artifacts/11_source_data/H05/H05_reader_near_eye_effect_figure_data.csv",
    "artifacts/11_source_data/H05/H05_reader_near_eye_results.csv",
    "artifacts/11_source_data/H05/H05_reader_near_eye_samples.csv",
    "artifacts/11_source_data/H05/H05_paired_effect_comparison_data.csv",
    "scripts/hypotheses/H05/build_h05_reader_artifacts.R"
  ),
  sha256 = c(
    "e563514cfac059a284d0c38ad733bef708f92ba13fec6686e0aa07804e835ec1",
    "501e3d15df42902063a411f2bf7f823c96ff46ca130d09768024ba5cd60210da",
    "5cd4b570980d6a48deb18ae777abadf7aa092c739db84532e2840aa8f583837d",
    "fd1a9c8ed252a795d88a68990bd023137b48a1d0956768a850fde65f572afa01",
    "7cecc2ec14b23085c50da300f04a1506f161df755e21ff636ed92ac1a84a6177"
  ),
  stringsAsFactors = FALSE
)
bad_source_builder <- source_and_builder$path[vapply(
  seq_len(nrow(source_and_builder)),
  function(index) !identical(
    sha256_file(file.path(root, source_and_builder$path[[index]])),
    source_and_builder$sha256[[index]]
  ),
  logical(1)
)]
record_check(
  "principal_source_data_and_builder_preserved",
  length(bad_source_builder) == 0L,
  "four exact source-data files and exact reader builder",
  paste(bad_source_builder, collapse = "; ")
)

# Assemble the protected scientific inventory from the three accepted H05
# manifests. Only H05 artifacts and H05 scripts are admitted. New evidence and
# the three mutable reader sources are excluded.
manifest_sources <- c(
  "artifacts/12_manifests/H05/H05_stage2_artifacts.csv",
  "artifacts/12_manifests/H05/H05_stage3_artifacts.csv",
  "artifacts/12_manifests/H05/H05_preparation_report_manifest.csv"
)
manifest_rows <- do.call(rbind, lapply(manifest_sources, function(path) {
  data <- utils::read.csv(
    file.path(root, path),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  data.frame(
    path = data$path,
    sha256 = data$sha256,
    bytes = as.numeric(data$bytes),
    source_manifest = path,
    stringsAsFactors = FALSE
  )
}))
scientific_mask <- grepl(
  paste0(
    "^(?:artifacts/(?:06_model_data|07_models|08_diagnostics|09_tables|",
    "10_figures|11_source_data|12_manifests)/H05/|",
    "scripts/hypotheses/H05/)"
  ),
  manifest_rows$path,
  perl = TRUE
)
scientific_rows <- manifest_rows[scientific_mask, , drop = FALSE]
identity_keys <- paste(scientific_rows$sha256, scientific_rows$bytes, sep = "::")
identity_count <- tapply(identity_keys, scientific_rows$path, function(value) {
  length(unique(value))
})
conflicting_manifest_paths <- names(identity_count)[identity_count != 1L]
record_check(
  "protected_manifest_identity_consistency",
  length(conflicting_manifest_paths) == 0L,
  "one accepted identity per protected H05 artifact or script",
  paste(conflicting_manifest_paths, collapse = "; ")
)
scientific_rows <- scientific_rows[!duplicated(scientific_rows$path), ]

protected_expected <- rbind(
  data.frame(
    path = scientific_rows$path,
    role = "protected H05 scientific or display artifact",
    expected_sha256 = scientific_rows$sha256,
    expected_bytes = scientific_rows$bytes,
    source = scientific_rows$source_manifest,
    stringsAsFactors = FALSE
  ),
  data.frame(
    path = protected_package$path,
    role = protected_package$role,
    expected_sha256 = protected_package$sha256,
    expected_bytes = as.numeric(protected_package$bytes),
    source = "order-36 controlling package",
    stringsAsFactors = FALSE
  ),
  data.frame(
    path = order_package$path,
    role = "controlling order-package identity",
    expected_sha256 = order_package$sha256,
    expected_bytes = order_package$bytes,
    source = "sealed owner order",
    stringsAsFactors = FALSE
  )
)
protected_expected <- protected_expected[!duplicated(protected_expected$path), ]
protected_expected <- protected_expected[order(protected_expected$path), ]
protected_inventory <- protected_expected
protected_inventory$current_sha256 <- vapply(
  file.path(root, protected_inventory$path),
  sha256_file,
  character(1)
)
protected_inventory$current_bytes <- vapply(
  file.path(root, protected_inventory$path),
  file_bytes,
  numeric(1)
)
protected_inventory$status <- ifelse(
  !is.na(protected_inventory$current_sha256) &
    protected_inventory$current_sha256 == protected_inventory$expected_sha256 &
    protected_inventory$current_bytes == protected_inventory$expected_bytes,
  "PASS",
  "FAIL"
)
record_check(
  "protected_scientific_inventory",
  all(protected_inventory$status == "PASS"),
  paste(nrow(protected_inventory), "protected identities"),
  paste(
    protected_inventory$path[protected_inventory$status != "PASS"],
    collapse = "; "
  )
)

# Generate stable exact diffs from the sealed pre-edit copies. Header paths are
# normalized so the patches are portable and can be reverse-applied with -p1.
diff_contract <- data.frame(
  key = c("result", "companion", "handoff"),
  relative_path = c(result_rel, companion_rel, handoff_rel),
  pre_path = unname(pre_paths[c("result", "companion", "handoff")]),
  current_path = c(result_path, companion_path, handoff_path),
  diff_name = c(
    "result_source_exact.diff",
    "companion_source_exact.diff",
    "handoff_exact.diff"
  ),
  pre_sha256 = expected_pre$sha256,
  stringsAsFactors = FALSE
)
diff_statuses <- integer(nrow(diff_contract))
for (index in seq_len(nrow(diff_contract))) {
  output <- suppressWarnings(system2(
    "diff",
    c(
      "-u",
      diff_contract$pre_path[[index]],
      diff_contract$current_path[[index]]
    ),
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  diff_statuses[[index]] <- status
  if (length(output) >= 2L) {
    output[[1L]] <- paste0("--- a/", diff_contract$relative_path[[index]])
    output[[2L]] <- paste0("+++ b/", diff_contract$relative_path[[index]])
  }
  writeLines(
    output,
    file.path(evidence_dir, diff_contract$diff_name[[index]]),
    useBytes = TRUE
  )
}
record_check(
  "exact_diff_generation",
  all(diff_statuses == 1L) && all(vapply(
    file.path(evidence_dir, diff_contract$diff_name),
    file_bytes,
    numeric(1)
  ) > 0),
  "three non-empty exact source diffs with diff status 1",
  paste(diff_statuses, collapse = "; ")
)

reverse_proof <- data.frame(
  path = diff_contract$relative_path,
  pre_sha256 = diff_contract$pre_sha256,
  reconstructed_sha256 = NA_character_,
  patch_status = NA_integer_,
  status = "FAIL",
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(reverse_proof))) {
  reverse_root <- tempfile(pattern = "h05-order36-reverse-")
  dir.create(
    file.path(reverse_root, dirname(reverse_proof$path[[index]])),
    recursive = TRUE,
    showWarnings = FALSE
  )
  target <- file.path(reverse_root, reverse_proof$path[[index]])
  file.copy(diff_contract$current_path[[index]], target, overwrite = TRUE)
  patch_output <- suppressWarnings(system2(
    "patch",
    c(
      "-f", "-p1", "-R", "-d", reverse_root,
      "-i", file.path(evidence_dir, diff_contract$diff_name[[index]])
    ),
    stdout = TRUE,
    stderr = TRUE
  ))
  patch_status <- attr(patch_output, "status")
  if (is.null(patch_status)) patch_status <- 0L
  reverse_proof$patch_status[[index]] <- patch_status
  reverse_proof$reconstructed_sha256[[index]] <- sha256_file(target)
  reverse_proof$status[[index]] <- if (
    patch_status == 0L && identical(
      reverse_proof$reconstructed_sha256[[index]],
      reverse_proof$pre_sha256[[index]]
    )
  ) "PASS" else "FAIL"
}
record_check(
  "reverse_substitution_proof",
  all(reverse_proof$status == "PASS"),
  "three reverse patches reproduce the sealed pre-edit hashes",
  paste(
    reverse_proof$path[reverse_proof$status != "PASS"],
    collapse = "; "
  )
)

package_versions <- data.frame(
  package = c("R", "digest", "png"),
  version = c(
    as.character(getRversion()),
    as.character(utils::packageVersion("digest")),
    as.character(utils::packageVersion("png"))
  ),
  role = c(
    "source-only verification runtime",
    "SHA-256 identities",
    "stored PNG metadata inspection"
  ),
  stringsAsFactors = FALSE
)

write_csv(
  protected_inventory,
  file.path(evidence_dir, "protected_inventory.csv")
)
write_csv(
  figure_observed,
  file.path(evidence_dir, "stored_figure_inventory.csv")
)
write_csv(
  reverse_proof,
  file.path(evidence_dir, "reverse_proof.csv")
)
write_csv(
  package_versions,
  file.path(evidence_dir, "package_versions.csv")
)

git_output <- suppressWarnings(system2(
  "git",
  c(
    "diff", "--check", "--",
    result_rel,
    companion_rel,
    handoff_rel,
    test_rel,
    evidence_rel
  ),
  stdout = TRUE,
  stderr = TRUE
))
git_status <- attr(git_output, "status")
if (is.null(git_status)) git_status <- 0L
record_check(
  "scoped_git_diff_check",
  identical(git_status, 0L),
  "git diff --check passes for the five authorized paths",
  paste(git_output, collapse = " | ")
)

static_evidence <- c(
  "result_source_exact.diff",
  "companion_source_exact.diff",
  "handoff_exact.diff",
  "reverse_proof.csv",
  "protected_inventory.csv",
  "stored_figure_inventory.csv",
  "package_versions.csv"
)
whitespace_bad <- character()
for (path in c(result_path, companion_path, handoff_path, test_path,
               file.path(evidence_dir, static_evidence))) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  is_diff <- endsWith(path, ".diff")
  if (
    (!is_diff && any(grepl("[[:blank:]]+$", lines))) ||
      any(grepl("^(<<<<<<<|=======|>>>>>>>)", lines))
  ) {
    whitespace_bad <- c(
      whitespace_bad,
      sub(paste0("^", root, "/"), "", path)
    )
  }
}
record_check(
  "source_and_evidence_whitespace",
  length(whitespace_bad) == 0L,
  "no trailing whitespace outside diffs and no conflict markers",
  paste(whitespace_bad, collapse = "; ")
)

handoff_contract <- c(
  "Source-only verification result: **PASS**",
  expected_final$sha256[[1L]],
  expected_final$sha256[[2L]],
  paste0(
    "H05_ORDER36_PRE_DIR=", pre_dir,
    " Rscript --vanilla ", test_rel
  ),
  "The provisional main outputs remain `fig-h05-near-effects`",
  "remain supplemental",
  "no stored-figure label that requires refresh",
  "render hold remains in force"
)
record_check(
  "handoff_order36_contract",
  all(vapply(
    handoff_contract,
    function(value) grepl(value, current[["handoff"]], fixed = TRUE),
    logical(1)
  )),
  "final identities, PASS, command, roles, static figure QA, and render hold",
  paste(handoff_contract, collapse = "; ")
)

# Define the non-circular manifest path set before sealing the execution result.
evidence_files <- c(
  "bounded_audit.md",
  static_evidence,
  "execution_record.md",
  "defect_list.csv"
)
source_roles <- c(
  setNames(
    c(
      "final H05 result QMD",
      "final H05 analysis-preparation QMD",
      "final H05 Stage 4 handoff",
      "order-36 source-only test"
    ),
    c(result_rel, companion_rel, handoff_rel, test_rel)
  ),
  setNames(protected_inventory$role, protected_inventory$path),
  setNames(
    c(
      "bounded source audit",
      "exact result-source diff",
      "exact companion-source diff",
      "exact handoff diff",
      "reverse-substitution proof",
      "protected identity inventory",
      "stored-figure identity and geometry inventory",
      "source-only package versions",
      "one-shot execution record",
      "combined defect list"
    ),
    file.path(evidence_rel, evidence_files)
  )
)
manifest_paths <- sort(unique(names(source_roles)))
source_manifest_rel <- file.path(
  evidence_rel,
  "H05_report017_order36_source_manifest.csv"
)
record_check(
  "source_manifest_noncircular_path_set",
  !source_manifest_rel %in% manifest_paths,
  "new source manifest excludes itself",
  paste(length(manifest_paths), "included paths")
)

status_before_seal <- if (all(checks$status == "PASS")) "PASS" else "FAIL"
elapsed_before_seal <- proc.time()[["elapsed"]] - started_elapsed
failures <- checks[checks$status == "FAIL", , drop = FALSE]

defect_path <- file.path(evidence_dir, "defect_list.csv")
write_csv(
  failures[, c("check_id", "expected", "observed", "detail"), drop = FALSE],
  defect_path
)

bounded_audit_lines <- c(
  "# H05 REPORT-014/017 order-36 bounded source audit",
  "",
  paste("Status:", status_before_seal),
  paste("Checks evaluated before seal:", nrow(checks)),
  paste("Defects:", nrow(failures)),
  "",
  "## Scope",
  "",
  "The audit covers only the H05 result QMD, H05 analysis-preparation QMD,",
  "the H05 Stage 4 handoff, the new source-only test, and this evidence",
  "directory. The two QMDs were parsed as text and were not executed.",
  "",
  "## Result hierarchy",
  "",
  "The provisional main figure is `fig-h05-near-effects`. The continued main",
  "table is `tbl-h05-near-results-a` plus `tbl-h05-near-results-b`. The",
  "near-eye model-check and paired-placement figures remain supplemental.",
  "Static inspection required no stored-figure label regeneration.",
  "",
  "## Scientific preservation",
  "",
  "The primary near-eye role, complementary non-ocular chest role, complete",
  "68-test FDR families, zero retained associations, four unfit sleep cells,",
  "fixed-site primary model, random-site sensitivity, common-sample",
  "concordance interpretation, accepted MDER estimand, and all sensitivity",
  "roles are unchanged. No scientific artifact was regenerated.",
  "",
  "## Render state",
  "",
  "The current result and companion HTML files are retained only as exact",
  "stale-render context. Neither HTML is claimed to correspond to the revised",
  "source. The REPORT-017 render hold remains in force.",
  "",
  "## Check summary",
  "",
  "| Check | Status |",
  "|---|---|",
  paste0("| `", checks$check_id, "` | ", checks$status, " |")
)
writeLines(
  bounded_audit_lines,
  file.path(evidence_dir, "bounded_audit.md"),
  useBytes = TRUE
)

execution_lines <- c(
  "# H05 order-36 one-shot execution record",
  "",
  paste("Status:", status_before_seal),
  paste("Started UTC:", format(started_at, tz = "UTC", usetz = TRUE)),
  paste("Sealed UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  sprintf("Pre-seal elapsed seconds: %.3f", elapsed_before_seal),
  paste("Checks evaluated before manifest seal:", nrow(checks)),
  paste("Defects before manifest seal:", nrow(failures)),
  paste("R version:", as.character(getRversion())),
  paste("digest version:", as.character(utils::packageVersion("digest"))),
  paste("png version:", as.character(utils::packageVersion("png"))),
  "",
  "Command:",
  "",
  "```sh",
  paste0(
    "H05_ORDER36_PRE_DIR=", pre_dir,
    " Rscript --vanilla ", test_rel
  ),
  "```",
  "",
  "No preliminary R or project test was run. No Quarto command was run.",
  "The QMDs were parsed as source text only and were not executed.",
  "The three historical H05 tests were not run.",
  "No fit, refit, prediction, simulation, bootstrap, resampling, FDR",
  "recalculation, diagnostic rerun, leave-one-site-out rerun, asset rebuild,",
  "configuration edit, ledger edit, commit, or push occurred.",
  "The reverse patches were applied only inside R temporary directories.",
  "No stopped attempt preceded this one-shot suite.",
  "",
  if (nrow(failures)) {
    paste("Combined defect list contains", nrow(failures), "row(s).")
  } else {
    "Combined defect list contains its header only."
  }
)
writeLines(
  execution_lines,
  file.path(evidence_dir, "execution_record.md"),
  useBytes = TRUE
)

# Build the non-circular source manifest after every included file exists.
# The manifest deliberately excludes itself.
source_manifest <- data.frame(
  path = manifest_paths,
  sha256 = vapply(
    file.path(root, manifest_paths),
    sha256_file,
    character(1)
  ),
  bytes = vapply(
    file.path(root, manifest_paths),
    file_bytes,
    numeric(1)
  ),
  role = unname(source_roles[manifest_paths]),
  r_version = as.character(getRversion()),
  stringsAsFactors = FALSE
)
write_csv(
  source_manifest,
  file.path(root, source_manifest_rel)
)

sealed_manifest <- utils::read.csv(
  file.path(root, source_manifest_rel),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
manifest_missing <- sealed_manifest$path[
  !file.exists(file.path(root, sealed_manifest$path))
]
manifest_hash_bad <- sealed_manifest$path[vapply(
  seq_len(nrow(sealed_manifest)),
  function(index) !identical(
    sha256_file(file.path(root, sealed_manifest$path[[index]])),
    sealed_manifest$sha256[[index]]
  ),
  logical(1)
)]
manifest_bytes_bad <- sealed_manifest$path[vapply(
  seq_len(nrow(sealed_manifest)),
  function(index) !identical(
    file_bytes(file.path(root, sealed_manifest$path[[index]])),
    as.numeric(sealed_manifest$bytes[[index]])
  ),
  logical(1)
)]
manifest_ok <-
  !anyDuplicated(sealed_manifest$path) &&
  !source_manifest_rel %in% sealed_manifest$path &&
  !length(manifest_missing) &&
  !length(manifest_hash_bad) &&
  !length(manifest_bytes_bad) &&
  all(sealed_manifest$r_version == "4.6.1")

print(checks, row.names = FALSE)
cat(
  "R ", as.character(getRversion()),
  "; digest ", as.character(utils::packageVersion("digest")),
  "; png ", as.character(utils::packageVersion("png")),
  "\n",
  sep = ""
)

if (!manifest_ok) {
  message("[source_manifest_audit] missing: ", paste(manifest_missing, collapse = "; "))
  message("[source_manifest_audit] hash: ", paste(manifest_hash_bad, collapse = "; "))
  message("[source_manifest_audit] bytes: ", paste(manifest_bytes_bad, collapse = "; "))
  quit(save = "no", status = 1L, runLast = FALSE)
}

failures <- checks$check_id[checks$status != "PASS"]
if (length(failures) > 0L) {
  stop(
    "H05 REPORT-017 source-only checks failed: ",
    paste(failures, collapse = ", "),
    call. = FALSE
  )
}

cat(
  "H05 REPORT-014/017 order 36 source-only checks passed: ",
  nrow(checks),
  " checks and ",
  nrow(sealed_manifest),
  " non-circular manifest rows audited.\n",
  sep = ""
)
