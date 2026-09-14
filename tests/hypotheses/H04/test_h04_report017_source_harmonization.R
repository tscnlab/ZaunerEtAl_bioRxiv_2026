#!/usr/bin/env Rscript

# REPORT-014/017 order 35 source-only contract.
# This test reads and parses the two H04 QMD sources. It never evaluates a
# QMD chunk and never performs scientific computation.

options(stringsAsFactors = FALSE, width = 180)

locate_project_root <- function(start = getwd()) {
  candidate <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(candidate, "renv.lock")) &&
        file.exists(file.path(candidate, "_quarto.yml"))
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

stopifnot(identical(as.character(getRversion()), "4.6.1"))
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("The synchronized project library must provide digest", call. = FALSE)
}

result_path <- "notebooks/hypotheses/H04.qmd"
companion_path <- "audit/hypotheses/H04/H04_analysis_preparation.qmd"

baseline_blobs <- c(
  result = "40a2651b0a3d461af057afffea5e0afd29c8659c",
  companion = "7d88f0943aff5038909e7c2747c255309c8d2ed5"
)

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

read_git_blob <- function(blob) {
  value <- system2(
    "git",
    c("cat-file", "blob", blob),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(value, "status")
  if (!is.null(status) && status != 0L) {
    stop("Could not read protected baseline blob ", blob, call. = FALSE)
  }
  paste(value, collapse = "\n")
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

sha256_text <- function(text) {
  digest::digest(text, algo = "sha256", serialize = FALSE)
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
  starts <- which(startsWith(lines, "```{r"))
  chunks <- vector("list", length(starts))
  for (index in seq_along(starts)) {
    start <- starts[[index]]
    ends <- which(seq_along(lines) > start & trimws(lines) == "```")
    if (length(ends) == 0L) {
      stop("Unclosed R chunk at line ", start, call. = FALSE)
    }
    end <- ends[[1L]]
    body_lines <- if (end > start + 1L) {
      lines[(start + 1L):(end - 1L)]
    } else {
      character()
    }
    label_line <- grep("#| label: ", body_lines, value = TRUE, fixed = TRUE)
    label <- if (length(label_line) == 1L) {
      sub("#| label: ", "", label_line, fixed = TRUE)
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
      errors <- c(
        errors,
        paste0(document, ":", chunk$label, ": ", error)
      )
    }
  }
  errors
}

extract_inline_r <- function(text) {
  regex_values(text, "(?<=`r )[^`]+(?=`)")
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
  regex_values(
    text,
    "(?<![[:alpha:]])-?[0-9]+(?:[.,][0-9]+)*(?![[:alpha:]])"
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
  trimws(lines[
    grepl("geo_medi_1h ~", lines, fixed = TRUE) |
      grepl("s(time_hour", lines, fixed = TRUE)
  ])
}

extract_markdown_targets <- function(text) {
  full <- regex_values(text, "\\]\\([^)]+\\)")
  sub("^\\]\\(", "", sub("\\)$", "", full))
}

extract_h04_filenames <- function(text) {
  regex_values(
    text,
    "H04_[A-Za-z0-9_.*-]+[.](?:csv|rds|png|pdf|svg)"
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
  calls <- character()
  for (chunk in chunks) {
    calls <- c(
      calls,
      all.names(parse(text = chunk$body), functions = TRUE)
    )
  }
  calls
}

current <- c(
  result = read_text(result_path),
  companion = read_text(companion_path)
)
baseline <- c(
  result = read_git_blob(baseline_blobs[["result"]]),
  companion = read_git_blob(baseline_blobs[["companion"]])
)
current_chunks <- lapply(current, extract_chunks)
baseline_chunks <- lapply(baseline, extract_chunks)

expected_result_tables <- c(
  "tbl-h04-primary-results",
  "tbl-h04-named-contrasts",
  "tbl-h04-omnibus",
  "tbl-h04-overall-samples",
  "tbl-h04-sample-flow",
  "tbl-h04-category-support",
  "tbl-h04-heterogeneity",
  "tbl-h04-near-site-factorization",
  "tbl-h04-fixed-r2",
  "tbl-h04-participant-random-intercept",
  "tbl-h04-primary-diagnostics",
  "tbl-h04-sensitivities",
  "tbl-h04-mundlak",
  "tbl-h04-temporal-fit",
  "tbl-h04-temporal-allocation",
  "tbl-h04-temporal-diagnostics",
  "tbl-h04-formulas"
)
expected_result_figures <- c(
  "fig-h04-primary-estimates",
  "fig-h04-site-context",
  "fig-h04-primary-diagnostics",
  "fig-h04-paired-placement",
  "fig-h04-temporal-near-eye",
  "fig-h04-temporal-chest",
  "fig-h04-temporal-diagnostics"
)
expected_companion_tables <- c(
  "tbl-h04-prep-input-identities",
  "tbl-h04-prep-transformation",
  "tbl-h04-prep-sample-flow",
  "tbl-h04-prep-zero-support",
  "tbl-h04-prep-integrity",
  "tbl-h04-prep-k-distribution",
  "tbl-h04-prep-participant-day-support",
  "tbl-h04-prep-category-support",
  "tbl-h04-prep-site-cell-support",
  "tbl-h04-prep-primary-specification",
  "tbl-h04-prep-formulas",
  "tbl-h04-prep-primary-tests",
  "tbl-h04-prep-estimand-contract",
  "tbl-h04-prep-heterogeneity-checks",
  "tbl-h04-prep-heterogeneity-tests",
  "tbl-h04-prep-participant-r2",
  "tbl-h04-prep-participant-r2-shapley",
  "tbl-h04-prep-participant-r2-checks",
  "tbl-h04-prep-multiplicity",
  "tbl-h04-prep-primary-diagnostics",
  "tbl-h04-prep-zero-diagnostics",
  "tbl-h04-prep-residual-acf",
  "tbl-h04-prep-diagnostic-interpretation",
  "tbl-h04-prep-influence",
  "tbl-h04-prep-sensitivity-samples",
  "tbl-h04-prep-sensitivity-tests",
  "tbl-h04-prep-mundlak-support",
  "tbl-h04-prep-temporal-basis",
  "tbl-h04-prep-temporal-models",
  "tbl-h04-prep-temporal-comparison",
  "tbl-h04-prep-temporal-retention",
  "tbl-h04-prep-temporal-uncertainty",
  "tbl-h04-prep-temporal-performance",
  "tbl-h04-prep-boundary",
  "tbl-h04-prep-script-map",
  "tbl-h04-prep-output-map",
  "tbl-h04-prep-environment"
)
expected_companion_figures <- c(
  "fig-h04-prep-positive-distribution",
  "fig-h04-prep-category-support",
  "fig-h04-prep-site-category-support",
  "fig-h04-prep-clock-category-support"
)

result_labels <- chunk_labels(current_chunks$result)
companion_labels <- chunk_labels(current_chunks$companion)
result_tables <- result_labels[startsWith(result_labels, "tbl-h04-")]
result_figures <- result_labels[startsWith(result_labels, "fig-h04-")]
companion_tables <- companion_labels[
  startsWith(companion_labels, "tbl-h04-prep-")
]
companion_figures <- companion_labels[
  startsWith(companion_labels, "fig-h04-prep-")
]

record_check(
  "result_table_endpoints",
  identical(result_tables, expected_result_tables) &&
    !anyDuplicated(result_tables),
  "17 exact table labels in approved order",
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
  identical(result_tables[[1L]], "tbl-h04-primary-results") &&
    identical(result_figures[[1L]], "fig-h04-primary-estimates"),
  "primary result table and figure first",
  paste(result_tables[[1L]], result_figures[[1L]], sep = "; ")
)
record_check(
  "companion_table_endpoints",
  identical(companion_tables, expected_companion_tables) &&
    !anyDuplicated(companion_tables),
  "37 exact table labels",
  paste(companion_tables, collapse = "; ")
)
record_check(
  "companion_figure_endpoints",
  identical(companion_figures, expected_companion_figures) &&
    !anyDuplicated(companion_figures),
  "4 exact figure labels",
  paste(companion_figures, collapse = "; ")
)

result_parse_errors <- parse_chunk_errors(
  current_chunks$result,
  result_path
)
companion_parse_errors <- parse_chunk_errors(
  current_chunks$companion,
  companion_path
)
record_check(
  "result_chunks_parse",
  length(result_parse_errors) == 0L,
  "all result chunks parse without execution",
  paste(result_parse_errors, collapse = "; ")
)
record_check(
  "companion_chunks_parse",
  length(companion_parse_errors) == 0L,
  "all companion chunks parse without execution",
  paste(companion_parse_errors, collapse = "; ")
)

record_check(
  "chunk_label_sets_preserved",
  identical(
    sort(chunk_labels(current_chunks$result)),
    sort(chunk_labels(baseline_chunks$result))
  ) && identical(
    sort(chunk_labels(current_chunks$companion)),
    sort(chunk_labels(baseline_chunks$companion))
  ),
  "pre-order chunk-label sets",
  "result and companion compared with protected Git blobs"
)

result_current_bodies <- chunk_bodies(current_chunks$result)
result_baseline_bodies <- chunk_bodies(baseline_chunks$result)
record_check(
  "result_chunk_bodies_preserved",
  identical(
    result_current_bodies[sort(names(result_current_bodies))],
    result_baseline_bodies[sort(names(result_baseline_bodies))]
  ),
  "every result R chunk byte-identical by label",
  "source-only reordering outside chunks"
)

companion_current_bodies <- chunk_bodies(current_chunks$companion)
companion_baseline_bodies <- chunk_bodies(baseline_chunks$companion)
changed_companion_chunks <- c(
  "tbl-h04-prep-input-identities" =
    "861177f1bd8b4f465dbd744246c2d8d79191ec663d748ce647573ebed2f8737a",
  "tbl-h04-prep-transformation" =
    "a56916c9317328b19dc30937eb6b49cdd077fbc15bded2d77a2f0561f4993934",
  "tbl-h04-prep-primary-tests" =
    "4748bb6b014539467da54ddac5d3d95252505244a2f46b8f623ebb2cfabf698b",
  "tbl-h04-prep-estimand-contract" =
    "90e9dbbbd4ca91004f1d1be1fc38758ee74d363c45d5f9e7fd6f530348821042",
  "tbl-h04-prep-heterogeneity-tests" =
    "774a9fed457eb3abe2903b5ea9f190b266b278dba1a8774ddfbcad48634bd54b",
  "tbl-h04-prep-multiplicity" =
    "1a0a8717c696587e4ddefaffd85baa301a5fdf38e227f534698e7fee5a4ab337",
  "tbl-h04-prep-sensitivity-tests" =
    "aa1f11b1b2dbdfdd195159c33420b9e98c9f93e7ce88551feff4c6791ee1ba48",
  "tbl-h04-prep-boundary" =
    "5dde8ebf90491167beabfd05b126413ea0f191de7bd54ec4ba29d93ecf75f2de",
  "tbl-h04-prep-script-map" =
    "201ebcef1d6056f9c848c67bf0d5552eb47995b529b281133f30527122e09538",
  "tbl-h04-prep-output-map" =
    "04088ce197cc7462de74c50b72cb6c5b291c3b8ba4cb0f0b5e5f34a4705c7181"
)
unchanged_companion_labels <- setdiff(
  names(companion_baseline_bodies),
  names(changed_companion_chunks)
)
unchanged_companion_ok <- identical(
  companion_current_bodies[sort(unchanged_companion_labels)],
  companion_baseline_bodies[sort(unchanged_companion_labels)]
)
changed_chunk_hashes <- vapply(
  companion_current_bodies[names(changed_companion_chunks)],
  sha256_text,
  character(1)
)
record_check(
  "companion_chunk_allowlist",
  unchanged_companion_ok &&
    identical(
      unname(changed_chunk_hashes),
      unname(changed_companion_chunks)
    ),
  "only 10 exact display-only companion chunks changed",
  paste(names(changed_companion_chunks), collapse = "; ")
)

record_check(
  "inline_r_preserved",
  identical(
    sort(extract_inline_r(current[["result"]])),
    sort(extract_inline_r(baseline[["result"]]))
  ) && identical(
    sort(extract_inline_r(current[["companion"]])),
    sort(extract_inline_r(baseline[["companion"]]))
  ),
  "exact pre-order inline-R multisets",
  paste(length(extract_inline_r(current[["result"]])), "result expressions")
)
record_check(
  "top_level_assignments_preserved",
  identical(
    sort(top_assignments(current_chunks$result)),
    sort(top_assignments(baseline_chunks$result))
  ) && identical(
    sort(top_assignments(current_chunks$companion)),
    sort(top_assignments(baseline_chunks$companion))
  ),
  "exact pre-order top-level assignment multisets",
  "result and companion"
)
record_check(
  "formula_lines_preserved",
  identical(
    sort(extract_formula_lines(current[["result"]])),
    sort(extract_formula_lines(baseline[["result"]]))
  ) && identical(
    sort(extract_formula_lines(current[["companion"]])),
    sort(extract_formula_lines(baseline[["companion"]]))
  ),
  "exact pre-order formula-line multisets",
  "population-mean, Mundlak, interaction, mixed, and temporal formulas"
)

result_numeric_delta <- token_delta(
  numeric_tokens(baseline[["result"]]),
  numeric_tokens(current[["result"]])
)
companion_numeric_delta <- token_delta(
  numeric_tokens(baseline[["companion"]]),
  numeric_tokens(current[["companion"]])
)
expected_result_numeric_delta <- c("1" = 1L, "95" = 1L)
record_check(
  "scientific_numeric_tokens_preserved",
  identical(result_numeric_delta, expected_result_numeric_delta) &&
    length(companion_numeric_delta) == 0L,
  "only glossary AR(1) and 95% CI tokens added",
  paste(
    paste(names(result_numeric_delta), result_numeric_delta, sep = ":"),
    collapse = "; "
  )
)

record_check(
  "artifact_references_preserved",
  identical(
    sort(extract_h04_filenames(current[["result"]])),
    sort(extract_h04_filenames(baseline[["result"]]))
  ) && identical(
    sort(extract_h04_filenames(current[["companion"]])),
    sort(extract_h04_filenames(baseline[["companion"]]))
  ),
  "exact H04 artifact filename multisets",
  "result and companion"
)
record_check(
  "markdown_targets_preserved",
  identical(
    sort(extract_markdown_targets(current[["result"]])),
    sort(extract_markdown_targets(baseline[["result"]]))
  ) && identical(
    sort(extract_markdown_targets(current[["companion"]])),
    sort(extract_markdown_targets(baseline[["companion"]]))
  ),
  "exact pre-order Markdown target multisets",
  "includes source-data and reciprocal QMD links"
)

expected_headings <- c(
  "## Question",
  "## What was analysed",
  "## Terms used below",
  "## Principal activity-category estimates",
  "## Supporting contrasts and omnibus tests",
  "## Sample and activity support",
  "## Model and estimand",
  "## Site-specific context",
  "## Exploratory participant random-intercept decomposition",
  "## Model checks",
  "## Sensitivity analyses",
  "## Same-participant, same-hour sensor-position comparison",
  "## Exploratory time-of-day context",
  "## Interpretation",
  "## Detailed analysis record"
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
  "Show supporting contrasts and interaction tests",
  "Show site-specific context and R² summaries",
  "Show detailed primary model checks",
  "Show detailed sensitivity results",
  "Show exploratory nonlinear time-of-day details"
)
record_check(
  "result_disclosures",
  all(vapply(
    disclosure_labels,
    function(value) fixed_count(current[["result"]], value) == 1L,
    logical(1)
  )) && fixed_count(current[["result"]], "<details>") == 5L &&
    fixed_count(current[["result"]], "</details>") == 5L,
  "five exact balanced disclosures",
  paste(disclosure_labels, collapse = "; ")
)

record_check(
  "lightbox_enabled",
  fixed_count(current[["result"]], "lightbox: true") == 1L &&
    fixed_count(current[["companion"]], "lightbox: true") == 1L,
  "lightbox enabled once in each YAML header",
  "result and companion"
)

result_random_link <- paste0(
  "../../audit/hypotheses/H04/H04_analysis_preparation.qmd",
  "#sec-h04-prep-participant-random-intercept"
)
record_check(
  "random_intercept_anchor_and_link",
  fixed_count(current[["result"]], result_random_link) == 1L &&
    fixed_count(
      current[["companion"]],
      "{#sec-h04-prep-participant-random-intercept}"
    ) == 1L,
  "one exact result link and one exact companion anchor",
  result_random_link
)

deviation_ids <- c("013", "014", "025", "026", "027")
deviation_links_ok <- all(vapply(
  deviation_ids,
  function(id) {
    link <- paste0(
      "../preregistration_deviations.qmd#dev-",
      id
    )
    fixed_count(current[["result"]], link) == 1L
  },
  logical(1)
))
deviation_text <- read_text("notebooks/preregistration_deviations.qmd")
deviation_anchors_ok <- all(vapply(
  deviation_ids,
  function(id) {
    fixed_count(deviation_text, paste0("{#dev-", id, "}")) == 1L
  },
  logical(1)
))
record_check(
  "preregistration_links_and_anchors",
  deviation_links_ok && deviation_anchors_ok &&
    fixed_count(
      current[["result"]],
      "{#h04-preregistration-deviations}"
    ) == 1L,
  "five exact deviation links and unique central anchors",
  paste(deviation_ids, collapse = ", ")
)

record_check(
  "reciprocal_qmd_links",
  fixed_count(
    current[["result"]],
    "../../audit/hypotheses/H04/H04_analysis_preparation.qmd"
  ) >= 1L &&
    fixed_count(
      current[["companion"]],
      "../../../notebooks/hypotheses/H04.qmd"
    ) >= 2L,
  "result-to-companion and companion-to-result relative QMD links",
  "reciprocal links present"
)

all_targets_resolve <- function(text, document) {
  targets <- extract_markdown_targets(text)
  targets <- targets[
    !grepl("^(?:https?:|mailto:|#)", targets, perl = TRUE)
  ]
  files <- sub("#.*$", "", targets)
  files <- files[nzchar(files)]
  resolved <- file.path(dirname(document), files)
  data.frame(
    target = targets[nzchar(sub("#.*$", "", targets))],
    resolved = resolved,
    exists = file.exists(resolved),
    stringsAsFactors = FALSE
  )
}
result_targets <- all_targets_resolve(current[["result"]], result_path)
companion_targets <- all_targets_resolve(
  current[["companion"]],
  companion_path
)
record_check(
  "all_relative_targets_resolve",
  all(result_targets$exists) && all(companion_targets$exists),
  "all relative QMD, preparation, artifact, and source-data targets exist",
  paste(
    c(
      result_targets$target[!result_targets$exists],
      companion_targets$target[!companion_targets$exists]
    ),
    collapse = "; "
  )
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
result_visible_compact <- gsub("[[:space:]]+", " ", result_visible)
companion_visible_compact <- gsub("[[:space:]]+", " ", companion_visible)
record_check(
  "approved_reader_vocabulary",
  !grepl("submitted", visible_combined, ignore.case = TRUE) &&
    !grepl("heterogeneous", visible_combined, ignore.case = TRUE) &&
    !grepl("\\bBH\\b", visible_combined, perl = TRUE) &&
    !grepl("H04-F[0-9]", visible_combined, perl = TRUE) &&
    !grepl("—", visible_combined, fixed = TRUE) &&
    grepl("varied display-only category", visible_combined, fixed = TRUE) &&
    grepl("not a coherent scientific category", visible_combined, fixed = TRUE),
  "approved site, activity, FDR, identifier, and punctuation vocabulary",
  "reader-visible prose scanned with code fences removed"
)

country_sites <- c(
  "Borås (SE)",
  "Delft (NL)",
  "Dortmund (DE)",
  "Tübingen (DE)",
  "Munich (DE)",
  "Madrid (ES)",
  "Izmir (TR)",
  "San José (CR)",
  "Kumasi (GH)"
)
record_check(
  "country_coded_sites",
  all(vapply(
    country_sites,
    function(value) {
      grepl(value, result_visible_compact, fixed = TRUE) &&
        grepl(value, companion_visible_compact, fixed = TRUE)
    },
    logical(1)
  )),
  "all nine country-coded study-site names in both reader sources",
  paste(country_sites, collapse = "; ")
)

glossary_terms <- c(
  "**Site-average estimate:**",
  "**Activity-by-site interaction:**",
  "**95% CI:**",
  "**FDR:**",
  "**Random intercept:**",
  "**Nonlinear GAM analysis:**",
  "**AR(1):**",
  "**Shapley allocation:**",
  "**Common sample:**"
)
record_check(
  "compact_glossary",
  all(vapply(
    glossary_terms,
    function(value) fixed_count(result_visible, value) == 1L,
    logical(1)
  )),
  "nine approved first-use glossary entries",
  paste(glossary_terms, collapse = "; ")
)

companion_display_contract <- c(
  "## About this analysis record",
  "PASS = \"Verified\"",
  "`VERIFIED CURRENT IDENTITY` = \"Verified current identity\"",
  "BH = \"FDR\"",
  "Scientific_reason = \"Scientific reason\"",
  "Near_eye = \"Near eye\"",
  "Source_model = \"Source model\"",
  "Reference_distribution = \"Reference distribution\"",
  "Inferential_role = \"Inferential role\"",
  "Principal_outputs = \"Principal outputs\"",
  "Run_on_this_page = \"Run on this page\"",
  "Output_group = \"Output group\"",
  "Reader_use = \"Reader use\"",
  "Calculated_on_render = \"Calculated on render\"",
  "predefined $10^{10}$ threshold"
)
record_check(
  "companion_display_mappings",
  all(vapply(
    companion_display_contract,
    function(value) grepl(value, current[["companion"]], fixed = TRUE),
    logical(1)
  )) &&
    fixed_count(current[["companion"]], "BH = \"FDR\"") == 1L,
  "verification, multiplicity, threshold, and spaced-label mappings",
  paste(companion_display_contract, collapse = "; ")
)

formula_registry <- read.csv(
  "artifacts/06_model_data/H04/H04_formula_registry.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
expected_formula_registry <- c(
  primary_full = "geo_medi_1h ~ site + activity",
  secondary_mundlak_audit = paste(
    "geo_medi_1h ~ site + activity + between_activity_1 +",
    "between_activity_2 + between_activity_3 + between_activity_4 +",
    "between_activity_5"
  ),
  heterogeneity_five_named_full =
    "geo_medi_1h ~ site * activity_named",
  temporal_activity_long = paste(
    "geo_medi_1h ~ s(time_hour, bs = \"cc\", k = 12) +",
    "s(time_hour, activity, bs = \"sz\", k = 12) +",
    "s(time_hour, site, bs = \"sz\", k = 12) +",
    "s(time_hour, participant, bs = \"fs\", k = 10) +",
    "s(participant_day, bs = \"re\")"
  )
)
observed_formulas <- setNames(
  formula_registry$formula,
  formula_registry$formula_id
)[names(expected_formula_registry)]
record_check(
  "exact_primary_mundlak_temporal_formulas",
  identical(unname(observed_formulas), unname(expected_formula_registry)) &&
    fixed_count(
      current[["result"]],
      "geo_medi_1h ~ site * activity_named + (1 | participant)"
    ) == 1L &&
    fixed_count(
      current[["companion"]],
      "geo_medi_1h ~ site * activity_named + (1 | participant)"
    ) == 2L,
  "exact accepted formulas",
  paste(names(expected_formula_registry), collapse = "; ")
)

role_phrases <- c(
  "additive population-mean model",
  "population-mean Mundlak-style sensitivity",
  "participant-level variation",
  "no participant-specific activity slope",
  "no participant-day random effect",
  "Neither assessment changes the primary analysis",
  "not a causal"
)
all_source_compact <- gsub(
  "[[:space:]]+",
  " ",
  paste(current, collapse = "\n")
)
record_check(
  "scientific_role_separation",
  all(vapply(
    role_phrases,
    function(value) grepl(
      value,
      all_source_compact,
      fixed = TRUE
    ),
    logical(1)
  )),
  "primary, Mundlak, and random-intercept roles remain distinct",
  paste(role_phrases, collapse = "; ")
)

script_names <- c(
  "h04_contract.R",
  "h04_stage1_support.R",
  "h04_data.R",
  "h04_modeling.R",
  "run_h04_stage2.R",
  "run_h04_mundlak_sensitivity.R",
  "run_h04_participant_random_intercept_assessment.R",
  "h04_temporal.R",
  "run_h04_temporal.R",
  "build_h04_stage3_reader_assets.R",
  "build_h04_stage3_reader_figures.R",
  "h04_reporting.R",
  "build_h04_preparation_artifacts.R"
)
output_groups <- c(
  "Recorded model frames",
  "Model objects",
  "Model checks",
  "Result tables",
  "Figures",
  "Figure and table source data",
  "Manifests",
  "Results report",
  "Preparation companion"
)
record_check(
  "script_and_output_maps_preserved",
  all(vapply(
    c(script_names, output_groups),
    function(value) grepl(value, current[["companion"]], fixed = TRUE),
    logical(1)
  )),
  "13 scripts and 9 output groups",
  "exact names retained"
)

banned_calls <- c(
  "write.csv", "write.table", "writeLines", "save", "saveRDS",
  "file.copy", "file.rename", "unlink", "dir.create",
  "readr::write_csv", "readr::write_tsv", "data.table::fwrite",
  "glm", "stats::glm", "glmmTMB", "glmmTMB::glmmTMB",
  "gam", "mgcv::gam", "bam", "mgcv::bam", "gamm", "mgcv::gamm",
  "lmer", "lme4::lmer", "glmer", "lme4::glmer",
  "predict", "stats::predict", "simulate", "stats::simulate",
  "boot", "boot::boot", "bootstrap", "resample", "ggsave",
  "ggplot2::ggsave"
)
observed_calls <- unique(c(
  all_chunk_calls(current_chunks$result),
  all_chunk_calls(current_chunks$companion)
))
present_banned_calls <- intersect(banned_calls, observed_calls)
record_check(
  "no_scientific_or_write_calls",
  length(present_banned_calls) == 0L &&
    !grepl(
      "source\\([^)]*scripts/hypotheses/H04",
      paste(current, collapse = "\n"),
      perl = TRUE
    ),
  "no project write, fit, predict, simulation, bootstrap, resampling, or builder call",
  paste(present_banned_calls, collapse = "; ")
)

package_manifest <- read.csv(
  "audit/report_harmonization/report017_h04_consolidated_audit_manifest.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
record_check(
  "controlling_package_manifest_identity",
  identical(
    sha256_file(
      "audit/report_harmonization/report017_h04_consolidated_audit_manifest.csv"
    ),
    "ab0cfd8b663c70d78e4d6b2b9adaf507bf547c7ae21190e4ff2aec81ff3bca89"
  ),
  "34-row controlling package manifest",
  nrow(package_manifest)
)
mutable_package_roles <- c(
  "preorder_result_source",
  "preorder_companion_source",
  "current_owner_handoff",
  "dispatch_coordination_context"
)
protected_package <- package_manifest[
  !package_manifest$role %in% mutable_package_roles,
]
protected_exists <- file.exists(protected_package$path)
protected_hashes <- rep(NA_character_, nrow(protected_package))
protected_bytes <- rep(NA_real_, nrow(protected_package))
protected_hashes[protected_exists] <- vapply(
  protected_package$path[protected_exists],
  sha256_file,
  character(1)
)
protected_bytes[protected_exists] <- file.info(
  protected_package$path[protected_exists]
)$size
protected_package_ok <- protected_exists &
  protected_hashes == protected_package$sha256 &
  protected_bytes == as.numeric(protected_package$bytes)
record_check(
  "owner_package_protected_identities",
  all(protected_package_ok),
  paste(nrow(protected_package), "protected package identities"),
  paste(protected_package$path[!protected_package_ok], collapse = "; ")
)

auxiliary_pins <- c(
  "artifacts/07_models/H04/H04_participant_random_intercept_assessment.rds" =
    "6b44b614b0898ba1c812fb44a532e2add6fe96e9eb41534bde574975bdfec351",
  "artifacts/09_tables/H04/H04_participant_random_intercept_summary.csv" =
    "44ce688f51b023f827ccf6fbb12d8dcc506e1c824c98d0e7d4e9bf046ec38c65",
  "artifacts/09_tables/H04/H04_participant_random_intercept_marginal_r2_shapley.csv" =
    "87d56a1b482e471e162171af4a6b2c3182eba08e915b7e1bca7025385e229fda",
  "artifacts/08_diagnostics/H04/H04_participant_random_intercept_diagnostics.csv" =
    "b1dae2a0ba345c1ffc7eea5a3bf2c0df9753f6bbdbb79c175761ef5377ffe541",
  "artifacts/08_diagnostics/H04/H04_participant_random_intercept_shapley_models.csv" =
    "f68f4a0ef2ceed8455fc75854858094bf9a28b0981a53c1561bf73aae01dfe31",
  "artifacts/12_manifests/H04/H04_participant_random_intercept_environment.csv" =
    "5d76a1f50993cce6b7b209a238b5551c0e0b3890bfad479b2732d5301c4b9534",
  "artifacts/12_manifests/H04/H04_participant_random_intercept_manifest.csv" =
    "ec267c547cd7ca3f44a3bf0b09a016dda226d85535f908f3b8632718f23712b4"
)
observed_auxiliary_hashes <- vapply(
  names(auxiliary_pins),
  sha256_file,
  character(1)
)
record_check(
  "random_intercept_artifacts_preserved",
  identical(unname(observed_auxiliary_hashes), unname(auxiliary_pins)),
  "7 accepted random-intercept identities",
  paste(names(auxiliary_pins), collapse = "; ")
)

untracked_audit_html_pins <- c(
  "audit/hypotheses/H04/01_audit_and_plan.html" =
    "59afbcd101e77ceadd7a720ef5e7bceebc22650d3e5d4b623a463d25f8bb2a4b",
  "audit/hypotheses/H04/02_implementation_and_v0_comparison.html" =
    "2e8bcaa35974c7aef36b1cfa9b942a4d7e1baca9cfacc2edb57365bf43aab636"
)
observed_untracked_html_hashes <- vapply(
  names(untracked_audit_html_pins),
  sha256_file,
  character(1)
)
record_check(
  "untracked_audit_html_preserved",
  identical(
    unname(observed_untracked_html_hashes),
    unname(untracked_audit_html_pins)
  ),
  "two out-of-order audit HTML pages untouched",
  paste(names(untracked_audit_html_pins), collapse = "; ")
)

main_svg <- read_text(
  "artifacts/10_figures/H04/H04_reader_heterogeneity_category_estimates.svg"
)
site_svg <- read_text(
  "artifacts/10_figures/H04/H04_site_activity_estimates.svg"
)
record_check(
  "stored_figure_baked_labels_held",
  fixed_count(main_svg, "Heterogeneity-model") == 2L &&
    fixed_count(main_svg, "site-heterogeneity model") == 1L &&
    fixed_count(site_svg, "equal-site") == 1L &&
    fixed_count(site_svg, "BH-adjusted") == 1L &&
    fixed_count(site_svg, "Support-gated") == 1L &&
    fixed_count(site_svg, "site-heterogeneity model") == 1L,
  "known baked labels remain pending later bounded refresh",
  "two SVG families inventoried without regeneration"
)

audit_out <- Sys.getenv("H04_ORDER35_AUDIT_CSV", unset = "")
if (nzchar(audit_out)) {
  write.csv(checks, audit_out, row.names = FALSE, na = "")
}

print(checks, row.names = FALSE)
cat(
  "R ", as.character(getRversion()),
  "; digest ", as.character(utils::packageVersion("digest")),
  "\n",
  sep = ""
)

failures <- checks$check_id[checks$status != "PASS"]
if (length(failures) > 0L) {
  stop(
    "H04 REPORT-017 source-only checks failed: ",
    paste(failures, collapse = ", "),
    call. = FALSE
  )
}

cat(
  "H04 REPORT-017 order 35 source-only checks passed: ",
  nrow(checks),
  " checks.\n",
  sep = ""
)
