#!/usr/bin/env Rscript

# REPORT-017 order 37a source-only verification for the main hourly H06 pair.
# This test parses source text and audits identities. It does not execute a QMD
# or calculate a scientific result.

options(warn = 1)

started_at <- Sys.time()
started_elapsed <- proc.time()[["elapsed"]]
startup_elapsed_seconds <- started_elapsed
checks_run <- 0L
failures <- data.frame(
  id = character(),
  detail = character(),
  stringsAsFactors = FALSE
)

record_check <- function(ok, id, detail) {
  checks_run <<- checks_run + 1L
  if (!isTRUE(ok)) {
    failures <<- rbind(
      failures,
      data.frame(
        id = as.character(id),
        detail = as.character(detail),
        stringsAsFactors = FALSE
      )
    )
  }
  invisible(ok)
}

locate_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(current, "renv.lock")) &&
      file.exists(file.path(
        current,
        "notebooks/hypotheses/H06.qmd"
      ))
    ) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate the project root", call. = FALSE)
    }
    current <- parent
  }
}

root <- locate_root()

record_check(
  identical(as.character(getRversion()), "4.6.1"),
  "R_VERSION",
  paste("Expected R 4.6.1, observed", as.character(getRversion()))
)

if (!requireNamespace("openssl", quietly = TRUE)) {
  stop("The source-only seal requires the pinned openssl package", call. = FALSE)
}

sha256_file <- function(path) {
  if (!file.exists(path)) {
    return(NA_character_)
  }
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  unname(unclass(as.character(openssl::sha256(connection))))
}

sha256_text <- function(text) {
  unname(unclass(as.character(openssl::sha256(charToRaw(enc2utf8(text))))))
}

file_bytes <- function(path) {
  if (!file.exists(path)) {
    return(NA_real_)
  }
  unname(file.info(path)$size)
}

read_text <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

result_rel <- "notebooks/hypotheses/H06.qmd"
companion_rel <- "audit/hypotheses/H06/H06_analysis_preparation.qmd"
handoff_rel <- "audit/handoffs/H06_worker_handoff.md"
test_rel <- "tests/hypotheses/H06/test_h06_report017_source_harmonization_37a.R"
evidence_rel <- "audit/hypotheses/H06/report017_order37a"
historical_evidence_rel <- "audit/hypotheses/H06/report017_order37"

result_path <- file.path(root, result_rel)
companion_path <- file.path(root, companion_rel)
handoff_path <- file.path(root, handoff_rel)
test_path <- file.path(root, test_rel)
evidence_dir <- file.path(root, evidence_rel)
diff_path <- file.path(evidence_dir, "exact_source_diff.patch")
historical_diff_path <- file.path(
  root,
  historical_evidence_rel,
  "exact_source_diff.patch"
)
protected_path <- file.path(evidence_dir, "protected_inventory.csv")
figure_inventory_path <- file.path(
  root,
  historical_evidence_rel,
  "stored_figure_inventory.csv"
)
package_versions_path <- file.path(evidence_dir, "package_versions.csv")
allow_list_path <- file.path(
  root,
  historical_evidence_rel,
  "editorial_allow_list.csv"
)

expected_final <- data.frame(
  path = c(result_rel, companion_rel, handoff_rel),
  sha256 = c(
    "468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2",
    "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
    "21b37d161f07ec27a2802239a3999621f484b9d697c7cddaf3a73f6c09fe4e90"
  ),
  bytes = c(60677, 59613, 11453),
  stringsAsFactors = FALSE
)

for (index in seq_len(nrow(expected_final))) {
  path <- file.path(root, expected_final$path[[index]])
  record_check(
    identical(sha256_file(path), expected_final$sha256[[index]]) &&
      identical(file_bytes(path), expected_final$bytes[[index]]),
    paste0("FINAL_IDENTITY_", index),
    paste("Final identity differs for", expected_final$path[[index]])
  )
}

record_check(
  identical(
    sha256_file(diff_path),
    "3fdf8165340f0a4c9bfdb155adf32ee51839e26dbb52842dd445ae655691b45a"
  ),
  "EXACT_DIFF_IDENTITY",
  "The exact source diff identity differs"
)

extract_r_chunks <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^```\\{r(?:[^}]*)\\}\\s*$", lines, perl = TRUE)
  chunks <- vector("list", length(starts))
  labels <- character(length(starts))
  for (index in seq_along(starts)) {
    start <- starts[[index]]
    candidate_ends <- which(seq_along(lines) > start & lines == "```")
    if (!length(candidate_ends)) {
      stop("Unclosed R chunk in ", path, " at line ", start, call. = FALSE)
    }
    end <- candidate_ends[[1L]]
    body <- if (end > start + 1L) lines[(start + 1L):(end - 1L)] else character()
    label_line <- grep("^#\\|\\s*label:\\s*", body, value = TRUE)
    label <- if (length(label_line)) {
      trimws(sub("^#\\|\\s*label:\\s*", "", label_line[[1L]]))
    } else {
      paste0("<unlabelled-", index, ">")
    }
    chunks[[index]] <- list(
      label = label,
      body = body,
      start = start,
      end = end
    )
    labels[[index]] <- label
  }
  names(chunks) <- labels
  chunks
}

extract_mermaid <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  start <- grep("^```\\{mermaid\\}\\s*$", lines)
  if (length(start) != 1L) {
    return(character())
  }
  candidate_ends <- which(seq_along(lines) > start[[1L]] & lines == "```")
  if (!length(candidate_ends)) {
    return(character())
  }
  lines[start[[1L]]:candidate_ends[[1L]]]
}

chunk_labels <- function(chunks) vapply(chunks, `[[`, character(1), "label")
chunk_body_text <- function(chunk) paste(chunk$body, collapse = "\n")
chunk_hash <- function(chunk) sha256_text(chunk_body_text(chunk))

parse_chunks <- function(chunks, document) {
  errors <- character()
  for (chunk in chunks) {
    error <- tryCatch(
      {
        parse(text = chunk_body_text(chunk), keep.source = TRUE)
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

current_result_chunks <- extract_r_chunks(result_path)
current_companion_chunks <- extract_r_chunks(companion_path)

record_check(
  length(current_result_chunks) == 20L &&
    !anyDuplicated(chunk_labels(current_result_chunks)),
  "RESULT_CHUNK_COUNT",
  paste("Expected 20 unique result chunks, observed", length(current_result_chunks))
)
record_check(
  length(current_companion_chunks) == 34L &&
    !anyDuplicated(chunk_labels(current_companion_chunks)),
  "COMPANION_CHUNK_COUNT",
  paste("Expected 34 unique companion chunks, observed", length(current_companion_chunks))
)

parse_errors <- c(
  parse_chunks(current_result_chunks, "result"),
  parse_chunks(current_companion_chunks, "companion")
)
record_check(
  !length(parse_errors),
  "R_CHUNK_PARSE",
  if (length(parse_errors)) paste(parse_errors, collapse = " | ") else "All chunks parse"
)

expected_result_chunks <- c(
  "setup",
  "fig-h06-core-effects",
  "tbl-h06-primary-effects",
  "tbl-h06-primary-site-interactions",
  "fig-h06-primary-site-associations",
  "tbl-h06-site-specific-associations",
  "tbl-h06-gap-sensitivity-comparisons",
  "fig-h06-paired-placement",
  "tbl-h06-key-sensitivities",
  "tbl-h06-influence-checks",
  "tbl-h06-model-checks",
  "fig-h06-residual-clock",
  "tbl-h06-exploratory-diary-associations",
  "exploratory-two-part-formulas",
  "fig-h06-exploratory-day-type-time",
  "fig-h06-exploratory-activity-time",
  "tbl-h06-exact-samples",
  "exact-confirmatory-formulas",
  "tbl-h06-fdr-adjustment",
  "tbl-h06-figure-readability-checks"
)
record_check(
  identical(unname(chunk_labels(current_result_chunks)), expected_result_chunks),
  "RESULT_CHUNK_ORDER",
  "The result chunk set or order differs from the sealed 20-chunk contract"
)

expected_companion_chunks <- c(
  "setup-h06-preparation",
  "tbl-h06-prep-render-boundary",
  "tbl-h06-prep-shared-provenance",
  "tbl-h06-prep-input-provenance",
  "tbl-h06-prep-diary-pin",
  "tbl-h06-prep-candidate-flow",
  "tbl-h06-prep-missingness",
  "tbl-h06-prep-previous-night",
  "tbl-h06-prep-exact-samples",
  "tbl-h06-prep-frame-integrity",
  "fig-h06-prep-response-distribution",
  "tbl-h06-prep-response-distribution",
  "fig-h06-prep-site-day-activity-support",
  "tbl-h06-prep-site-cell-summary",
  "tbl-h06-prep-category-cell-minima",
  "fig-h06-prep-clock-support",
  "tbl-h06-prep-participant-day-support",
  "tbl-h06-prep-true-time-sequences",
  "tbl-h06-prep-primary-formulas",
  "tbl-h06-prep-model-settings",
  "tbl-h06-prep-multiplicity",
  "tbl-h06-prep-fit-diagnostics",
  "tbl-h06-prep-residual-correlation",
  "tbl-h06-prep-influence",
  "tbl-h06-prep-sensitivity-map",
  "tbl-h06-prep-sensitivity-stability",
  "tbl-h06-prep-temporal-formulas",
  "tbl-h06-prep-temporal-diagnostics",
  "tbl-h06-prep-temporal-basis",
  "tbl-h06-prep-exploratory-samples",
  "tbl-h06-prep-code-map",
  "tbl-h06-prep-output-inventory",
  "tbl-h06-prep-environment",
  "tbl-h06-prep-source-data"
)
record_check(
  identical(unname(chunk_labels(current_companion_chunks)), expected_companion_chunks),
  "COMPANION_CHUNK_ORDER",
  "The companion chunk set or order differs from the sealed 34-chunk contract"
)

result_table_expected <- c(
  "tbl-h06-primary-effects",
  "tbl-h06-primary-site-interactions",
  "tbl-h06-site-specific-associations",
  "tbl-h06-gap-sensitivity-comparisons",
  "tbl-h06-key-sensitivities",
  "tbl-h06-influence-checks",
  "tbl-h06-model-checks",
  "tbl-h06-exploratory-diary-associations",
  "tbl-h06-exact-samples",
  "tbl-h06-fdr-adjustment",
  "tbl-h06-figure-readability-checks"
)
result_figure_expected <- c(
  "fig-h06-core-effects",
  "fig-h06-primary-site-associations",
  "fig-h06-paired-placement",
  "fig-h06-residual-clock",
  "fig-h06-exploratory-day-type-time",
  "fig-h06-exploratory-activity-time"
)
result_native_tables <- c(
  "exact-confirmatory-formulas",
  "exploratory-two-part-formulas"
)
result_labels <- chunk_labels(current_result_chunks)
record_check(
  identical(
    unname(result_labels[startsWith(result_labels, "tbl-")]),
    result_table_expected
  ),
  "RESULT_TABLE_ENDPOINTS",
  "The 11 result table endpoints or their order differ"
)
record_check(
  identical(
    unname(result_labels[startsWith(result_labels, "fig-")]),
    result_figure_expected
  ),
  "RESULT_FIGURE_ENDPOINTS",
  "The six result figure endpoints or their order differ"
)
record_check(
  setequal(result_native_tables, intersect(result_labels, result_native_tables)) &&
    all(table(factor(
      intersect(result_labels, result_native_tables),
      levels = result_native_tables
    )) == 1L),
  "RESULT_NATIVE_TABLES",
  "The two native formula-table displays are not present exactly once"
)
record_check(
  identical(result_labels[startsWith(result_labels, "fig-")][[1L]], "fig-h06-core-effects") &&
    identical(result_labels[startsWith(result_labels, "tbl-")][[1L]], "tbl-h06-primary-effects"),
  "PRINCIPAL_ENDPOINT_ORDER",
  "The provisional main figure or table is not the first endpoint of its type"
)

companion_labels <- chunk_labels(current_companion_chunks)
companion_tables <- companion_labels[startsWith(companion_labels, "tbl-")]
companion_figures <- companion_labels[startsWith(companion_labels, "fig-")]
record_check(
  length(companion_tables) == 30L && !anyDuplicated(companion_tables),
  "COMPANION_TABLE_ENDPOINTS",
  paste("Expected 30 companion tables, observed", length(companion_tables))
)
record_check(
  identical(
    unname(companion_figures),
    c(
      "fig-h06-prep-response-distribution",
      "fig-h06-prep-site-day-activity-support",
      "fig-h06-prep-clock-support"
    )
  ),
  "COMPANION_FIGURE_ENDPOINTS",
  "The three companion figure endpoints or their order differ"
)

record_check(
  !any(startsWith(result_labels, "<unlabelled-")) &&
    !any(startsWith(companion_labels, "<unlabelled-")),
  "UNLABELLED_CHUNKS",
  "An unexpected unlabelled R chunk is present"
)

# Reverse the order-37a patch and then the historical order-37 patch in a
# temporary directory. No project file is modified.
reverse_root <- tempfile("h06-order37a-reverse-")
dir.create(reverse_root, recursive = TRUE, showWarnings = FALSE)
on.exit(unlink(reverse_root, recursive = TRUE, force = TRUE), add = TRUE)

reverse_paths <- c(result_rel, companion_rel, handoff_rel)
for (relative in reverse_paths) {
  destination <- file.path(reverse_root, relative)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  file.copy(file.path(root, relative), destination, overwrite = TRUE)
}

patch_binary <- Sys.which("patch")
record_check(nzchar(patch_binary), "PATCH_BINARY", "The patch utility is unavailable")

reverse_patch <- function(path, check_id, description) {
  output <- character()
  status <- 1L
  if (nzchar(patch_binary)) {
    output <- suppressWarnings(system2(
      patch_binary,
      args = c(
        "-R", "-p1", "-s",
        "-d", shQuote(reverse_root),
        "-i", shQuote(path)
      ),
      stdout = TRUE,
      stderr = TRUE
    ))
    status <- attr(output, "status")
    if (is.null(status)) status <- 0L
  }
  record_check(
    identical(status, 0L),
    check_id,
    paste(c(description, output), collapse = " | ")
  )
  status
}

order37a_patch_status <- reverse_patch(
  diff_path,
  "REVERSE_ORDER37A_PATCH",
  "Order-37a reverse patch failed"
)

expected_stopped <- data.frame(
  path = reverse_paths,
  sha256 = c(
    "938f1a253bffefa99947783dc1ae4c739f92ad82fb224a4d8626d91bcebea061",
    "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
    "5bf8dc5a5ee0a27f15edeceef1aaac7d10fd3d0bbf1895517fea8451cdea99a3"
  ),
  bytes = c(60541, 59613, 10408),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(expected_stopped))) {
  path <- file.path(reverse_root, expected_stopped$path[[index]])
  record_check(
    identical(sha256_file(path), expected_stopped$sha256[[index]]) &&
      identical(file_bytes(path), expected_stopped$bytes[[index]]),
    paste0("STOPPED_ORDER37_IDENTITY_", index),
    paste(
      "Order-37a reverse substitution did not reproduce",
      expected_stopped$path[[index]]
    )
  )
}

historical_patch_status <- if (identical(order37a_patch_status, 0L)) {
  reverse_patch(
    historical_diff_path,
    "REVERSE_HISTORICAL_ORDER37_PATCH",
    "Historical order-37 reverse patch failed"
  )
} else {
  1L
}

expected_pre <- data.frame(
  path = reverse_paths,
  sha256 = c(
    "692c28ce165eda27e0b85dbb73f2e834a31a188ae8eefe9f1391980bd5641459",
    "205eac1ee6d878353a2b23c3741e18ef7480765882d6e0baad0808963b3aa731",
    "5080334fa1f1ac82c60359111b5aa44065cdf2075e3a7a672fd9c225e3ba3829"
  ),
  bytes = c(56355, 55895, 24781),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(expected_pre))) {
  path <- file.path(reverse_root, expected_pre$path[[index]])
  record_check(
    identical(sha256_file(path), expected_pre$sha256[[index]]) &&
      identical(file_bytes(path), expected_pre$bytes[[index]]),
    paste0("ACCEPTED_PRE_ORDER37_IDENTITY_", index),
    paste("Two-step reverse substitution did not reproduce", expected_pre$path[[index]])
  )
}

if (
  identical(order37a_patch_status, 0L) &&
    identical(historical_patch_status, 0L)
) {
  original_result_path <- file.path(reverse_root, result_rel)
  original_companion_path <- file.path(reverse_root, companion_rel)
  original_result_chunks <- extract_r_chunks(original_result_path)
  original_companion_chunks <- extract_r_chunks(original_companion_path)

  record_check(
    setequal(chunk_labels(original_result_chunks), result_labels),
    "RESULT_PRE_POST_CHUNK_SET",
    "The result labelled-chunk set changed"
  )
  record_check(
    setequal(chunk_labels(original_companion_chunks), companion_labels),
    "COMPANION_PRE_POST_CHUNK_SET",
    "The companion labelled-chunk set changed"
  )

  changed_chunk_labels <- function(before, after) {
    common <- intersect(names(before), names(after))
    sort(common[vapply(
      common,
      function(label) !identical(chunk_hash(before[[label]]), chunk_hash(after[[label]])),
      logical(1)
    )])
  }

  expected_changed_result <- sort(c(
    "tbl-h06-key-sensitivities",
    "tbl-h06-model-checks",
    "tbl-h06-figure-readability-checks"
  ))
  expected_changed_companion <- sort(c(
    "setup-h06-preparation",
    "tbl-h06-prep-render-boundary",
    "tbl-h06-prep-shared-provenance",
    "tbl-h06-prep-input-provenance",
    "tbl-h06-prep-diary-pin",
    "tbl-h06-prep-frame-integrity",
    "tbl-h06-prep-fit-diagnostics",
    "tbl-h06-prep-influence",
    "tbl-h06-prep-sensitivity-stability",
    "tbl-h06-prep-temporal-formulas",
    "tbl-h06-prep-temporal-diagnostics",
    "tbl-h06-prep-output-inventory",
    "tbl-h06-prep-environment",
    "tbl-h06-prep-source-data"
  ))
  changed_result <- changed_chunk_labels(original_result_chunks, current_result_chunks)
  changed_companion <- changed_chunk_labels(
    original_companion_chunks,
    current_companion_chunks
  )
  record_check(
    identical(changed_result, expected_changed_result),
    "RESULT_EDITORIAL_ALLOW_LIST",
    paste("Unexpected changed result chunks:", paste(changed_result, collapse = ", "))
  )
  record_check(
    identical(changed_companion, expected_changed_companion),
    "COMPANION_EDITORIAL_ALLOW_LIST",
    paste(
      "Unexpected changed companion chunks:",
      paste(changed_companion, collapse = ", ")
    )
  )

  original_result_text <- read_text(original_result_path)
  original_companion_text <- read_text(original_companion_path)
  current_result_text <- read_text(result_path)
  current_companion_text <- read_text(companion_path)

  regex_values <- function(text, pattern) {
    matches <- gregexpr(pattern, text, perl = TRUE)
    values <- regmatches(text, matches)[[1L]]
    if (identical(values, character(0)) || identical(values, "")) character() else sort(unique(values))
  }

  numeric_tokens <- function(text) {
    regex_values(
      text,
      "(?<![[:alnum:]_])(?:[0-9]+(?:[.,][0-9]+)*)(?![[:alnum:]_])"
    )
  }
  inline_r <- function(text) regex_values(text, "`r[[:space:]]+[^`]+`")
  prepared_refs <- function(text) {
    regex_values(text, "\\.data\\$(?:`[^`]+`|[A-Za-z0-9._]+)")
  }
  file_refs <- function(text) {
    regex_values(
      text,
      "H06_[A-Za-z0-9_.-]+\\.(?:csv|rds|png|pdf|svg)"
    )
  }
  formula_lines <- function(text) {
    lines <- trimws(strsplit(text, "\n", fixed = TRUE)[[1L]])
    sort(unique(lines[grepl("response_value[[:space:]]*~|~[[:space:]]*site", lines)]))
  }
  pipeline_lines <- function(text) {
    lines <- trimws(strsplit(text, "\n", fixed = TRUE)[[1L]])
    sort(unique(lines[grepl(
      "(?:dplyr::)?filter\\(|(?:left|right|inner|full)_join\\(|arrange\\(",
      lines,
      perl = TRUE
    )]))
  }
  assignment_names <- function(text) {
    lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
    matches <- regexec(
      "^([A-Za-z.][A-Za-z0-9._]*)[[:space:]]*<-",
      lines,
      perl = TRUE
    )
    extracted <- regmatches(lines, matches)
    sort(unique(vapply(
      extracted[lengths(extracted) > 1L],
      `[[`,
      character(1),
      2L
    )))
  }

  preservation_pairs <- list(
    result_numeric = list(numeric_tokens(original_result_text), numeric_tokens(current_result_text)),
    companion_numeric = list(numeric_tokens(original_companion_text), numeric_tokens(current_companion_text)),
    result_inline_r = list(inline_r(original_result_text), inline_r(current_result_text)),
    companion_inline_r = list(inline_r(original_companion_text), inline_r(current_companion_text)),
    result_prepared_refs = list(prepared_refs(original_result_text), prepared_refs(current_result_text)),
    result_file_refs = list(file_refs(original_result_text), file_refs(current_result_text)),
    companion_file_refs = list(file_refs(original_companion_text), file_refs(current_companion_text)),
    result_formulas = list(formula_lines(original_result_text), formula_lines(current_result_text)),
    companion_formulas = list(formula_lines(original_companion_text), formula_lines(current_companion_text)),
    result_pipelines = list(pipeline_lines(original_result_text), pipeline_lines(current_result_text)),
    companion_pipelines = list(pipeline_lines(original_companion_text), pipeline_lines(current_companion_text)),
    result_assignments = list(assignment_names(original_result_text), assignment_names(current_result_text)),
    companion_assignments = list(assignment_names(original_companion_text), assignment_names(current_companion_text))
  )
  for (name in names(preservation_pairs)) {
    pair <- preservation_pairs[[name]]
    record_check(
      identical(pair[[1L]], pair[[2L]]),
      paste0("PRESERVE_", toupper(name)),
      paste("Pre/post structural inventory differs for", name)
    )
  }

  original_companion_prepared_refs <- prepared_refs(original_companion_text)
  current_companion_prepared_refs <- prepared_refs(current_companion_text)
  expected_companion_prepared_additions <- sort(c(
    ".data$`All additive fits converged`",
    ".data$`All interaction fits converged`"
  ))
  removed_companion_prepared_refs <- setdiff(
    original_companion_prepared_refs,
    current_companion_prepared_refs
  )
  added_companion_prepared_refs <- sort(setdiff(
    current_companion_prepared_refs,
    original_companion_prepared_refs
  ))
  record_check(
    !length(removed_companion_prepared_refs) &&
      identical(
        added_companion_prepared_refs,
        expected_companion_prepared_additions
      ),
    "COMPANION_PREPARED_REFERENCE_ALLOWANCE",
    paste(
      "Removed:", paste(removed_companion_prepared_refs, collapse = ";"),
      "added:", paste(added_companion_prepared_refs, collapse = ";")
    )
  )

  record_check(
    identical(
      chunk_hash(original_result_chunks[["exact-confirmatory-formulas"]]),
      chunk_hash(current_result_chunks[["exact-confirmatory-formulas"]])
    ) && identical(
      chunk_hash(original_result_chunks[["exploratory-two-part-formulas"]]),
      chunk_hash(current_result_chunks[["exploratory-two-part-formulas"]])
    ),
    "EXACT_RESULT_FORMULA_CHUNKS",
    "A native result formula display changed"
  )
  record_check(
    identical(
      chunk_hash(original_companion_chunks[["tbl-h06-prep-primary-formulas"]]),
      chunk_hash(current_companion_chunks[["tbl-h06-prep-primary-formulas"]])
    ),
    "EXACT_COMPANION_PRIMARY_FORMULAS",
    "The companion primary formula pipeline changed"
  )
  record_check(
    identical(extract_mermaid(original_companion_path), extract_mermaid(companion_path)),
    "MERMAID_PRESERVATION",
    "The companion flowchart node or edge text changed"
  )
}

result_text <- read_text(result_path)
companion_text <- read_text(companion_path)

count_fixed <- function(text, token) {
  matches <- gregexpr(token, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
}

required_result_disclosures <- c(
  "Show site-specific estimates and interaction details",
  "Show complementary placement and sensitivity results",
  "Show detailed model checks and influence analyses",
  "Show exploratory clock-time and diary analyses",
  "Show technical source and figure checks"
)
for (title in required_result_disclosures) {
  record_check(
    count_fixed(result_text, paste0("<summary>", title, "</summary>")) == 1L,
    paste0("DISCLOSURE_", gsub("[^A-Za-z0-9]", "_", title)),
    paste("Missing or duplicated disclosure:", title)
  )
}
record_check(
  count_fixed(result_text, "lightbox: true") == 1L &&
    count_fixed(companion_text, "lightbox: true") == 1L,
  "LIGHTBOX",
  "Each H06 source must contain lightbox: true exactly once"
)
record_check(
  count_fixed(result_text, 'title="Answer in brief"') == 1L &&
    count_fixed(companion_text, 'title="About this analysis record"') == 1L,
  "CALLOUT_TITLES",
  "A required callout title is missing or duplicated"
)

record_check(
  count_fixed(result_text, "H06_daily.qmd") == 1L &&
    count_fixed(companion_text, "H06_daily.qmd") == 1L,
  "DAILY_LINK_COUNTS",
  "Each hourly page must contain exactly one complementary daily QMD link"
)
record_check(
  count_fixed(
    result_text,
    "../../audit/hypotheses/H06/H06_analysis_preparation.qmd"
  ) >= 1L && count_fixed(
    companion_text,
    "../../../notebooks/hypotheses/H06.qmd"
  ) >= 1L,
  "RECIPROCAL_HOURLY_LINKS",
  "A reciprocal hourly QMD link is missing"
)
record_check(
  count_fixed(result_text, "../preparation/06_model_ready_datasets.qmd") == 2L &&
    count_fixed(
      companion_text,
      "../../../notebooks/preparation/06_model_ready_datasets.qmd"
    ) == 1L,
  "PREPARATION_06_LINKS",
  "The Preparation 06 dynamic link counts differ"
)
for (deviation in c("015", "030", "031", "032")) {
  result_target <- paste0("../preregistration_deviations.qmd#dev-", deviation)
  companion_target <- paste0(
    "../../../notebooks/preregistration_deviations.qmd#dev-",
    deviation
  )
  record_check(
    count_fixed(result_text, result_target) == 1L &&
      count_fixed(companion_text, companion_target) == 1L,
    paste0("DEVIATION_LINK_", deviation),
    paste("The DEV-", deviation, "link count differs", sep = "")
  )
}
record_check(
  count_fixed(result_text, "{#h06-preregistration-deviations}") == 1L &&
    count_fixed(
      companion_text,
      "#h06-preregistration-deviations"
    ) == 1L,
  "RESULT_ANCHOR",
  "The result registration anchor or its companion link differs"
)

extract_markdown_targets <- function(text) {
  matches <- gregexpr("\\[[^]]+\\]\\(([^)]+)\\)", text, perl = TRUE)
  links <- regmatches(text, matches)[[1L]]
  if (!length(links)) return(character())
  captures <- regmatches(
    links,
    regexec("\\]\\(([^)]+)\\)$", links, perl = TRUE)
  )
  vapply(captures, `[[`, character(1), 2L)
}

check_targets <- function(source_path, text, document) {
  targets <- extract_markdown_targets(text)
  missing <- character()
  prohibited <- character()
  for (target in targets) {
    if (grepl("^(https?:|mailto:)", target)) next
    if (
      grepl("\\.html(?:#|$)|_build|^file:|^/", target, perl = TRUE) ||
      grepl("^~", target)
    ) {
      prohibited <- c(prohibited, target)
    }
    path_part <- sub("#.*$", "", target)
    if (!nzchar(path_part)) next
    resolved <- normalizePath(
      file.path(dirname(source_path), path_part),
      winslash = "/",
      mustWork = FALSE
    )
    if (!file.exists(resolved)) missing <- c(missing, target)
  }
  record_check(
    !length(unique(missing)),
    paste0(document, "_LINK_TARGETS"),
    paste("Missing targets:", paste(unique(missing), collapse = ", "))
  )
  record_check(
    !length(unique(prohibited)),
    paste0(document, "_PROHIBITED_LINKS"),
    paste("Prohibited internal targets:", paste(unique(prohibited), collapse = ", "))
  )
}
check_targets(result_path, result_text, "RESULT")
check_targets(companion_path, companion_text, "COMPANION")

reader_surface <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  in_fence <- FALSE
  output <- character()
  for (line in lines) {
    if (grepl("^```", line)) {
      in_fence <- !in_fence
      next
    }
    if (!in_fence || grepl(
      "^#\\|\\s*(?:fig-alt|fig-cap|tbl-cap|code-summary):",
      line,
      perl = TRUE
    )) {
      output <- c(output, line)
    }
  }
  paste(output, collapse = "\n")
}

result_reader <- reader_surface(result_path)
companion_reader <- reader_surface(companion_path)
reader_pair <- paste(result_reader, companion_reader, sep = "\n")

record_check(
  count_fixed(result_reader, "discrete = TRUE") == 1L &&
    count_fixed(result_reader, "discrete = FALSE") == 0L &&
    count_fixed(companion_reader, "discrete = TRUE") == 1L &&
    count_fixed(companion_reader, "discrete = FALSE") == 1L,
  "TECHNICAL_BOOLEAN_METHOD_STRINGS",
  "The exact visible discrete-method TRUE/FALSE occurrences differ"
)
result_reader_scan <- gsub(
  "discrete = TRUE",
  "",
  result_reader,
  fixed = TRUE
)
companion_reader_scan <- gsub(
  "discrete = TRUE",
  "",
  companion_reader,
  fixed = TRUE
)
companion_reader_scan <- gsub(
  "discrete = FALSE",
  "",
  companion_reader_scan,
  fixed = TRUE
)
reader_pair_scan <- paste(result_reader_scan, companion_reader_scan, sep = "\n")

forbidden_reader_patterns <- c(
  "\\bBH\\b",
  "Benjamini-Hochberg",
  "equal-site",
  "\\bheterogeneity\\b",
  "REPORT_011",
  "\\baccepted\\b",
  "\\bfrozen\\b",
  "\\bproduction\\b",
  "expected-hour",
  "supported-hour",
  "\\bPASS\\b",
  "\\bFAIL\\b",
  "\\bTRUE\\b",
  "\\bFALSE\\b",
  "\\bExecuted\\b",
  "Not executed",
  "—"
)
for (pattern in forbidden_reader_patterns) {
  record_check(
    !grepl(pattern, reader_pair_scan, ignore.case = FALSE, perl = TRUE),
    paste0("READER_TERM_", gsub("[^A-Za-z0-9]", "_", pattern)),
    paste("Reader-facing source contains prohibited pattern", pattern)
  )
}

collapse_source_whitespace <- function(text) {
  trimws(gsub("[[:space:]]+", " ", text, perl = TRUE))
}
result_reader_language <- collapse_source_whitespace(result_reader)
companion_reader_language <- collapse_source_whitespace(companion_reader)
restored_day_type_sentence <- paste(
  "The interaction model's site-average day-type association did not meet the",
  "adjusted threshold (three-predictor FDR-adjusted p = 0.298)."
)
record_check(
  count_fixed(result_reader_language, restored_day_type_sentence) == 1L,
  "RESTORED_DAY_TYPE_SENTENCE",
  "The accepted visible p = 0.298 sentence is missing or duplicated"
)

record_check(
  count_fixed(result_text, "Benjamini-Hochberg") == 2L &&
    count_fixed(result_text, 'BH = "FDR"') == 1L,
  "TECHNICAL_FDR_METHOD_STRINGS",
  "Technical method-string occurrences differ from the sealed allowance"
)

required_result_language <- c(
  "main H06 analysis",
  "complementary participant-day analysis",
  "estimated mean hourly melEDI among observed hours that met the support criteria",
  "participant-hour",
  "participant-day",
  "Near-eye measurements are primary",
  "complementary, non-ocular evidence",
  "direct retinal measure",
  "participant-cluster-robust 95% confidence interval",
  "HC3 small-sample correction",
  "False-discovery-rate adjustment",
  "predictor-by-site interaction model",
  "association to differ by study site",
  "site-average estimate",
  "gives each site equal weight",
  "A sensitivity analysis asks whether",
  "gap-timing-unaware dataset",
  "not an observation-level identity comparison",
  "nonlinear generalized additive model (GAM)",
  "pointwise 95% CI",
  "not a simultaneous band",
  "symlog",
  "linear from 0 to 1 lx",
  "Tick labels remain"
)
for (token in required_result_language) {
  record_check(
    grepl(token, result_reader_language, fixed = TRUE),
    paste0("RESULT_LANGUAGE_", gsub("[^A-Za-z0-9]", "_", token)),
    paste("Missing result explanation:", token)
  )
}

required_companion_language <- c(
  "hourly analysis remains the main H06 analysis",
  "complementary participant-day report",
  "participant-hour",
  "participant-day",
  "near-eye sensor position is primary",
  "complementary",
  "non-ocular exposure",
  "quasi-Poisson model estimates a log mean",
  "fixed effect",
  "participant-cluster-robust 95% CI",
  "HC3 small-sample correction",
  "predictor-by-site interaction model",
  "site-average estimate",
  "back-transforms once",
  "False-discovery-rate (FDR) adjustment",
  "gap-timing-unaware dataset",
  "nonlinear generalized additive model (GAM)",
  "pointwise 95% CI",
  "AR(1) working structure",
  "symlog axis is linear from 0 to 1 lux"
)
for (token in required_companion_language) {
  record_check(
    grepl(token, companion_reader_language, fixed = TRUE),
    paste0("COMPANION_LANGUAGE_", gsub("[^A-Za-z0-9]", "_", token)),
    paste("Missing companion explanation:", token)
  )
}

site_names <- c(
  "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
  "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
  "Kumasi (GH)"
)
for (site in site_names) {
  record_check(
    grepl(site, result_reader, fixed = TRUE) &&
      grepl(site, companion_reader, fixed = TRUE),
    paste0("COUNTRY_SITE_", gsub("[^A-Za-z0-9]", "_", site)),
    paste("Country-coded site is missing:", site)
  )
}

record_check(
  all(vapply(
    c(
      '"Meets numerical checks"', '"Review needed"', '"Verified"',
      '"Read from stored records"', '"Not repeated here"', '"Yes"', '"No"'
    ),
    function(token) grepl(token, paste(result_text, companion_text), fixed = TRUE),
    logical(1)
  )),
  "DISPLAY_STATUS_MAPPINGS",
  "One or more required reader status mappings is absent"
)
record_check(
  !grepl('"Executed"|"Not executed"|ifelse\\(x, "PASS", "FAIL"\\)',
    paste(result_text, companion_text),
    perl = TRUE
  ),
  "RAW_STATUS_EXPOSURE",
  "A removed workflow or raw model-check display string remains"
)

all_current_code <- paste(
  c(
    vapply(current_result_chunks, chunk_body_text, character(1)),
    vapply(current_companion_chunks, chunk_body_text, character(1))
  ),
  collapse = "\n"
)
prohibited_scientific_calls <- c(
  "glm", "gam", "bam", "gamm", "gamm4", "glmmTMB", "lmer", "glmer",
  "predict", "simulate", "boot", "readRDS", "saveRDS", "write_csv",
  "write.csv", "ggsave"
)
for (call in prohibited_scientific_calls) {
  pattern <- paste0("(?<![A-Za-z0-9_.:])", gsub("\\.", "\\\\.", call), "\\s*\\(")
  record_check(
    !grepl(pattern, all_current_code, perl = TRUE),
    paste0("PROHIBITED_CALL_", gsub("[^A-Za-z0-9]", "_", call)),
    paste("Prohibited project-side analytical call found:", call)
  )
}

protected <- utils::read.csv(
  protected_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
record_check(
  nrow(protected) == 94L && !anyDuplicated(protected$path),
  "PROTECTED_INVENTORY_SHAPE",
  paste("Expected 94 unique protected rows, observed", nrow(protected))
)
protected_missing <- protected$path[!file.exists(file.path(root, protected$path))]
record_check(
  !length(protected_missing),
  "PROTECTED_FILES_EXIST",
  paste("Missing protected files:", paste(protected_missing, collapse = ", "))
)
protected_hash_mismatch <- character()
protected_byte_mismatch <- character()
for (index in seq_len(nrow(protected))) {
  path <- file.path(root, protected$path[[index]])
  if (!file.exists(path)) next
  if (!identical(sha256_file(path), protected$sha256[[index]])) {
    protected_hash_mismatch <- c(protected_hash_mismatch, protected$path[[index]])
  }
  if (!identical(file_bytes(path), as.numeric(protected$bytes[[index]]))) {
    protected_byte_mismatch <- c(protected_byte_mismatch, protected$path[[index]])
  }
}
record_check(
  !length(protected_hash_mismatch),
  "PROTECTED_HASHES",
  paste("Protected hash mismatches:", paste(protected_hash_mismatch, collapse = ", "))
)
record_check(
  !length(protected_byte_mismatch),
  "PROTECTED_BYTES",
  paste("Protected byte mismatches:", paste(protected_byte_mismatch, collapse = ", "))
)

figures <- utils::read.csv(
  figure_inventory_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
record_check(
  nrow(figures) == 6L && !anyDuplicated(figures$path),
  "FIGURE_INVENTORY_SHAPE",
  "The stored-figure inventory must contain six unique result figures"
)
figure_bad <- character()
for (index in seq_len(nrow(figures))) {
  path <- file.path(root, figures$path[[index]])
  if (
    !file.exists(path) ||
    !identical(sha256_file(path), figures$sha256[[index]]) ||
    !identical(file_bytes(path), as.numeric(figures$bytes[[index]]))
  ) {
    figure_bad <- c(figure_bad, figures$path[[index]])
  }
}
record_check(
  !length(figure_bad),
  "STORED_FIGURE_IDENTITIES",
  paste("Stored figure identities differ:", paste(figure_bad, collapse = ", "))
)
record_check(
  all(figures$width_px == 2141L) &&
    identical(figures$height_px[c(1, 2, 5, 6)], c(1486L, 1700L, 2582L, 2582L)) &&
    all(figures$dpi == 320L),
  "DEFERRED_FIGURE_METADATA",
  "A deferred figure dimension or DPI differs from the sealed order"
)

expected_existing <- data.frame(
  path = c(
    "tests/hypotheses/H06/test_h06_stage2.R",
    "tests/hypotheses/H06/test_h06_stage3.R",
    "tests/hypotheses/H06/test_h06_preparation_report.R",
    "artifacts/12_manifests/H06/H06_stage2_artifacts.csv",
    "artifacts/12_manifests/H06/H06_stage3_artifacts.csv",
    "artifacts/12_manifests/H06/H06_preparation_report_manifest.csv"
  ),
  sha256 = c(
    "489115354c11de17b627e4e2cb28cef9f54654a50756a7d4897dda3080b29b89",
    "a6e3e307b023588b475587876be86eeb9c0f7b9d9d1597df946dd112458940aa",
    "2b9f02f7caa448a3c7fdb88b0febc5ce306239002ebe220b6f5f7a7c4285a4fc",
    "2407f2045d960be1025dbd5e338d0df9a733bd4caf2afc29f16a9680fb355752",
    "d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21",
    "db976477b9cdbce2a6d4575e382b2f04062e8834c086f1d82cb25d7e8a2176e4"
  ),
  bytes = c(15916, 35771, 12918, 47385, 73277, 78784),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(expected_existing))) {
  path <- file.path(root, expected_existing$path[[index]])
  record_check(
    identical(sha256_file(path), expected_existing$sha256[[index]]) &&
      identical(file_bytes(path), expected_existing$bytes[[index]]),
    paste0("EXISTING_H06_IDENTITY_", index),
    paste("Existing H06 test or manifest differs:", expected_existing$path[[index]])
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

stage2_mismatch <- manifest_mismatch_paths(
  "artifacts/12_manifests/H06/H06_stage2_artifacts.csv"
)
stage3_mismatch <- manifest_mismatch_paths(
  "artifacts/12_manifests/H06/H06_stage3_artifacts.csv"
)
preparation_mismatch <- manifest_mismatch_paths(
  "artifacts/12_manifests/H06/H06_preparation_report_manifest.csv"
)

expected_stage2_mismatch <- sort(c(
  "audit/handoffs/H06_shared_change_request.md",
  "audit/handoffs/H06_worker_handoff.md",
  "scripts/hypotheses/H06/h06_contract.R",
  "tests/hypotheses/H06/test_h06_stage2.R"
))
expected_stage3_mismatch <- sort(c(
  "_build/nathealth/notebooks/hypotheses/H06.html",
  "audit/handoffs/H06_shared_change_request.md",
  "audit/handoffs/H06_worker_handoff.md",
  "notebooks/hypotheses/H06.qmd",
  "scripts/hypotheses/H06/h06_contract.R"
))
expected_preparation_mismatch <- sort(c(
  "_quarto-nathealth.yml",
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  "audit/hypotheses/H06/H06_analysis_preparation.qmd",
  "notebooks/hypotheses/H06.qmd"
))

record_check(
  identical(stage2_mismatch, expected_stage2_mismatch),
  "STAGE2_MANIFEST_MISMATCH_SET",
  paste("Observed Stage 2 mismatches:", paste(stage2_mismatch, collapse = ", "))
)
record_check(
  identical(stage3_mismatch, expected_stage3_mismatch),
  "STAGE3_MANIFEST_MISMATCH_SET",
  paste("Observed Stage 3 mismatches:", paste(stage3_mismatch, collapse = ", "))
)
record_check(
  identical(preparation_mismatch, expected_preparation_mismatch),
  "PREPARATION_MANIFEST_MISMATCH_SET",
  paste(
    "Observed preparation mismatches:",
    paste(preparation_mismatch, collapse = ", ")
  )
)

versions <- utils::read.csv(
  package_versions_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
version_bad <- character()
for (index in seq_len(nrow(versions))) {
  package <- versions$package[[index]]
  expected <- versions$version[[index]]
  observed <- if (identical(package, "R")) {
    as.character(getRversion())
  } else if (requireNamespace(package, quietly = TRUE)) {
    as.character(utils::packageVersion(package))
  } else {
    NA_character_
  }
  if (!identical(observed, expected)) {
    version_bad <- c(
      version_bad,
      paste0(package, " expected ", expected, " observed ", observed)
    )
  }
}
record_check(
  !length(version_bad),
  "PACKAGE_VERSIONS",
  paste("Package version differences:", paste(version_bad, collapse = " | "))
)

allow_list <- utils::read.csv(
  allow_list_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
record_check(
  nrow(allow_list) == 17L && !anyDuplicated(paste(
    allow_list$document,
    allow_list$chunk_label
  )),
  "EDITORIAL_ALLOW_LIST_SHAPE",
  "The explicit editorial allow-list must contain 17 unique chunk rows"
)
record_check(
  sum(
    allow_list$document == "companion" &
      allow_list$chunk_label == "tbl-h06-prep-influence" &
      allow_list$allowed_change == "Map stored convergence booleans to Yes or No"
  ) == 1L,
  "COMPANION_INFLUENCE_ALLOW_LIST_ROW",
  "The sealed order-37 influence Yes/No mapping row is absent or changed"
)

static_evidence <- c(
  "bounded_audit.md",
  "exact_source_diff.patch",
  "reverse_proof.md",
  "protected_inventory.csv",
  "package_versions.csv"
)
whitespace_paths <- c(
  result_path,
  companion_path,
  handoff_path,
  test_path,
  file.path(evidence_dir, static_evidence)
)
whitespace_bad <- character()
for (path in whitespace_paths) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  is_unified_diff <- identical(path, diff_path)
  if (
    (!is_unified_diff && any(grepl("[[:blank:]]+$", lines))) ||
    any(grepl("^(<<<<<<<|=======|>>>>>>>)", lines))
  ) {
    whitespace_bad <- c(whitespace_bad, sub(paste0("^", root, "/"), "", path))
  }
}
record_check(
  !length(whitespace_bad),
  "SOURCE_WHITESPACE",
  paste("Whitespace or conflict-marker failures:", paste(whitespace_bad, collapse = ", "))
)

git_output <- suppressWarnings(system2(
  "git",
  args = c(
    "diff", "--check", "--",
    shQuote(result_rel),
    shQuote(companion_rel),
    shQuote(handoff_rel),
    shQuote(test_rel),
    shQuote(evidence_rel)
  ),
  stdout = TRUE,
  stderr = TRUE
))
git_status <- attr(git_output, "status")
if (is.null(git_status)) git_status <- 0L
record_check(
  identical(git_status, 0L),
  "SCOPED_GIT_DIFF_CHECK",
  paste(c("git diff --check failed", git_output), collapse = " | ")
)

# Prepare deterministic source-only seal files. These are audit outputs, not
# scientific artifacts. The manifest excludes itself.
verifier_elapsed_before_seal <- proc.time()[["elapsed"]] - started_elapsed
total_elapsed_before_seal <- proc.time()[["elapsed"]]
status_before_manifest <- if (nrow(failures)) "FAIL" else "PASS"
exit_status_before_manifest <- if (nrow(failures)) 1L else 0L

defect_rel <- file.path(evidence_rel, "defect_list.csv")
execution_rel <- file.path(evidence_rel, "execution_record.md")
pre_post_rel <- file.path(evidence_rel, "pre_post_identities.csv")
source_manifest_rel <- file.path(evidence_rel, "order37a_source_manifest.csv")

csv_escape <- function(value) {
  value <- as.character(value)
  needs_quotes <- grepl('[",\n\r]', value)
  value <- gsub('"', '""', value, fixed = TRUE)
  ifelse(needs_quotes, paste0('"', value, '"'), value)
}

render_csv <- function(data) {
  lines <- c(
    paste(vapply(names(data), csv_escape, character(1)), collapse = ","),
    vapply(
      seq_len(nrow(data)),
      function(index) {
        values <- vapply(
          data,
          function(column) as.character(column[[index]]),
          character(1)
        )
        paste(
          vapply(values, csv_escape, character(1)),
          collapse = ","
        )
      },
      character(1)
    )
  )
  paste(lines, collapse = "\n")
}

mutable_pre <- data.frame(
  path = c(result_rel, companion_rel, handoff_rel, test_rel),
  scope = "mutable or controlling source",
  pre_sha256 = c(
    "938f1a253bffefa99947783dc1ae4c739f92ad82fb224a4d8626d91bcebea061",
    "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
    "5bf8dc5a5ee0a27f15edeceef1aaac7d10fd3d0bbf1895517fea8451cdea99a3",
    "not present at dispatch"
  ),
  pre_bytes = c("60541", "59613", "10408", "not present at dispatch"),
  stringsAsFactors = FALSE
)
mutable_pre$post_sha256 <- vapply(
  file.path(root, mutable_pre$path),
  sha256_file,
  character(1)
)
mutable_pre$post_bytes <- vapply(
  file.path(root, mutable_pre$path),
  function(path) format(file_bytes(path), scientific = FALSE, trim = TRUE),
  character(1)
)
mutable_pre$status <- ifelse(
  mutable_pre$path == companion_rel,
  ifelse(mutable_pre$pre_sha256 == mutable_pre$post_sha256, "unchanged", "changed"),
  ifelse(mutable_pre$path == test_rel, "new", "authorized change")
)

protected_pre_post <- data.frame(
  path = protected$path,
  scope = "protected read-only input",
  pre_sha256 = protected$sha256,
  pre_bytes = format(protected$bytes, scientific = FALSE, trim = TRUE),
  post_sha256 = vapply(file.path(root, protected$path), sha256_file, character(1)),
  post_bytes = vapply(
    file.path(root, protected$path),
    function(path) format(file_bytes(path), scientific = FALSE, trim = TRUE),
    character(1)
  ),
  stringsAsFactors = FALSE
)
protected_pre_post$status <- ifelse(
  protected_pre_post$pre_sha256 == protected_pre_post$post_sha256 &
    protected_pre_post$pre_bytes == protected_pre_post$post_bytes,
  "unchanged",
  "changed"
)

new_static_paths <- file.path(evidence_rel, static_evidence)
new_static_pre_post <- data.frame(
  path = new_static_paths,
  scope = "new order-37a static evidence",
  pre_sha256 = "not present at dispatch",
  pre_bytes = "not present at dispatch",
  post_sha256 = vapply(file.path(root, new_static_paths), sha256_file, character(1)),
  post_bytes = vapply(
    file.path(root, new_static_paths),
    function(path) format(file_bytes(path), scientific = FALSE, trim = TRUE),
    character(1)
  ),
  status = "new",
  stringsAsFactors = FALSE
)
pre_post_rows <- rbind(mutable_pre, protected_pre_post, new_static_pre_post)
pre_post_text <- render_csv(pre_post_rows)
pre_post_file_text <- paste0(pre_post_text, "\n")

defect_lines <- c(
  "id,detail",
  if (nrow(failures)) {
    apply(
      failures,
      1L,
      function(row) paste(csv_escape(row[[1L]]), csv_escape(row[[2L]]), sep = ",")
    )
  } else {
    character()
  }
)
defect_text <- paste(defect_lines, collapse = "\n")
defect_file_text <- paste0(defect_text, "\n")

execution_lines <- c(
  "# H06 order-37a one-shot execution record",
  "",
  paste("Status:", status_before_manifest),
  paste("Verifier body started UTC:", format(started_at, tz = "UTC", usetz = TRUE)),
  paste("Sealed UTC:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  sprintf(
    "Environment startup elapsed seconds before verifier body: %.3f",
    startup_elapsed_seconds
  ),
  sprintf("Verifier pre-seal elapsed seconds: %.3f", verifier_elapsed_before_seal),
  sprintf("Total process elapsed seconds before seal: %.3f", total_elapsed_before_seal),
  paste("Expected verifier exit status:", exit_status_before_manifest),
  paste("Checks evaluated:", checks_run),
  paste("Defects before manifest seal:", nrow(failures)),
  paste("R version:", as.character(getRversion())),
  paste("openssl version:", as.character(utils::packageVersion("openssl"))),
  "renv cache boundary: existing user-owned ~/Library/Caches/org.R-project.R/R/renv.",
  "The normal project profile had approved narrow read/write cache access only.",
  "",
  "Command:",
  "",
  "```sh",
  "Rscript tests/hypotheses/H06/test_h06_report017_source_harmonization_37a.R",
  "```",
  "",
  paste(
    "Historical order 37: R 4.6.1 evaluated 171 checks and stopped with",
    "17 sealed defects after its authorized environment-startup retry."
  ),
  paste(
    "Before that run, one sandboxed startup process spent about 75 minutes in",
    "the documented renv transient-cache loop and never entered the verifier body."
  ),
  "No preliminary R or project test was run. No Quarto command was run.",
  "The QMDs were parsed as text only and were not executed.",
  "The three historical H06 tests were not run.",
  "The manifest mismatch sets were audited as historical identity context.",
  paste(
    "The order-37a source patch and historical order-37 patch were reversed",
    "only inside an R temporary directory."
  ),
  paste("Pre/post identity rows:", nrow(pre_post_rows)),
  "",
  if (nrow(failures)) {
    paste("Combined defect list: defect_list.csv with", nrow(failures), "row(s).")
  } else {
    "Combined defect list: defect_list.csv contains its header only."
  }
)
execution_text <- paste(execution_lines, collapse = "\n")
execution_file_text <- paste0(execution_text, "\n")

source_roles <- c(
  setNames(
    c(
      "final hourly result source",
      "final hourly companion source",
      "final H06 worker handoff",
      "order-37a source-only test"
    ),
    c(result_rel, companion_rel, handoff_rel, test_rel)
  ),
  setNames(protected$role, protected$path),
  setNames(
    c(
      "bounded source audit",
      "exact reversible source diff",
      "reverse-substitution proof",
      "protected read-only inventory",
      "source-only package versions"
    ),
    file.path(evidence_rel, static_evidence)
  ),
  setNames(
    c(
      "one-shot combined defect list",
      "one-shot execution record",
      "pre/post source and protected identities"
    ),
    c(defect_rel, execution_rel, pre_post_rel)
  )
)
manifest_paths <- sort(unique(names(source_roles)))
record_check(
  !source_manifest_rel %in% manifest_paths,
  "MANIFEST_NONCIRCULAR_PATH_SET",
  "The new source manifest included itself"
)

manifest_rows <- data.frame(
  path = manifest_paths,
  sha256 = NA_character_,
  bytes = NA_real_,
  role = unname(source_roles[manifest_paths]),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(manifest_rows))) {
  relative <- manifest_rows$path[[index]]
  if (identical(relative, defect_rel)) {
    manifest_rows$sha256[[index]] <- sha256_text(defect_file_text)
    manifest_rows$bytes[[index]] <- nchar(enc2utf8(defect_file_text), type = "bytes")
  } else if (identical(relative, execution_rel)) {
    manifest_rows$sha256[[index]] <- sha256_text(execution_file_text)
    manifest_rows$bytes[[index]] <- nchar(enc2utf8(execution_file_text), type = "bytes")
  } else if (identical(relative, pre_post_rel)) {
    manifest_rows$sha256[[index]] <- sha256_text(pre_post_file_text)
    manifest_rows$bytes[[index]] <- nchar(enc2utf8(pre_post_file_text), type = "bytes")
  } else {
    absolute <- file.path(root, relative)
    manifest_rows$sha256[[index]] <- sha256_file(absolute)
    manifest_rows$bytes[[index]] <- file_bytes(absolute)
  }
}

writeLines(defect_text, file.path(root, defect_rel), useBytes = TRUE)
writeLines(execution_text, file.path(root, execution_rel), useBytes = TRUE)
writeLines(pre_post_text, file.path(root, pre_post_rel), useBytes = TRUE)

manifest_lines <- c(
  "path,sha256,bytes,role",
  vapply(
    seq_len(nrow(manifest_rows)),
    function(index) {
      values <- c(
        manifest_rows$path[[index]],
        manifest_rows$sha256[[index]],
        format(manifest_rows$bytes[[index]], scientific = FALSE, trim = TRUE),
        manifest_rows$role[[index]]
      )
      paste(vapply(values, csv_escape, character(1)), collapse = ",")
    },
    character(1)
  )
)
writeLines(
  paste(manifest_lines, collapse = "\n"),
  file.path(root, source_manifest_rel),
  useBytes = TRUE
)

sealed_manifest <- utils::read.csv(
  file.path(root, source_manifest_rel),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
manifest_missing <- sealed_manifest$path[
  !file.exists(file.path(root, sealed_manifest$path))
]
manifest_hash_bad <- character()
manifest_bytes_bad <- character()
for (index in seq_len(nrow(sealed_manifest))) {
  path <- file.path(root, sealed_manifest$path[[index]])
  if (!file.exists(path)) next
  if (!identical(sha256_file(path), sealed_manifest$sha256[[index]])) {
    manifest_hash_bad <- c(manifest_hash_bad, sealed_manifest$path[[index]])
  }
  if (!identical(file_bytes(path), as.numeric(sealed_manifest$bytes[[index]]))) {
    manifest_bytes_bad <- c(manifest_bytes_bad, sealed_manifest$path[[index]])
  }
}
manifest_audit_ok <-
  !anyDuplicated(sealed_manifest$path) &&
  !source_manifest_rel %in% sealed_manifest$path &&
  !length(manifest_missing) &&
  !length(manifest_hash_bad) &&
  !length(manifest_bytes_bad)
if (!manifest_audit_ok) {
  failures <- rbind(
    failures,
    data.frame(
      id = "SOURCE_MANIFEST_AUDIT",
      detail = paste(
        "missing", paste(manifest_missing, collapse = ";"),
        "hash", paste(manifest_hash_bad, collapse = ";"),
        "bytes", paste(manifest_bytes_bad, collapse = ";")
      ),
      stringsAsFactors = FALSE
    )
  )
}

if (nrow(failures)) {
  message("H06 REPORT-017 order-37a source-only verification: FAIL")
  for (index in seq_len(nrow(failures))) {
    message("[", failures$id[[index]], "] ", failures$detail[[index]])
  }
  quit(save = "no", status = 1L, runLast = FALSE)
}

message(
  "H06 REPORT-017 order-37a source-only verification: PASS (",
  checks_run,
  " checks before non-circular manifest seal; ",
  nrow(sealed_manifest),
  " manifest rows audited)"
)
