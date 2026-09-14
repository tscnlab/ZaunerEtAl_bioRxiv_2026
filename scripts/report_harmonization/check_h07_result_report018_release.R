#!/usr/bin/env Rscript

options(warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) {
    stop(message, call. = FALSE)
  }
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  mustWork = TRUE
)
assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)
assert_true(requireNamespace("digest", quietly = TRUE), "digest is required")

pins_path <- file.path(
  root,
  "audit/report_harmonization/report018_h07_result_release_pins.csv"
)
pins <- read.csv(pins_path, stringsAsFactors = FALSE)
assert_true(nrow(pins) == 25L, "H07 release must contain 25 pins")
assert_true(
  identical(names(pins), c("role", "relative_path", "sha256", "bytes")),
  "H07 release-pin columns changed"
)
assert_true(!anyDuplicated(pins$role), "H07 release-pin roles are not unique")
assert_true(
  !anyDuplicated(pins$relative_path),
  "H07 release-pin paths are not unique"
)
pin_files <- file.path(root, pins$relative_path)
assert_true(all(file.exists(pin_files)), "An H07 release-pin path is missing")
assert_true(
  all(as.numeric(file.info(pin_files)$size) == pins$bytes),
  "An H07 release-pin byte count changed"
)
assert_true(
  identical(
    unname(vapply(pin_files, sha256_file, character(1))),
    pins$sha256
  ),
  "An H07 release-pin SHA-256 changed"
)

qmd_path <- file.path(root, "notebooks/hypotheses/H07.qmd")
companion_path <- file.path(
  root,
  "audit/hypotheses/H07/H07_analysis_preparation.qmd"
)
qmd_lines <- readLines(qmd_path, warn = FALSE)
qmd_text <- paste(qmd_lines, collapse = "\n")
qmd_text_normalized <- gsub("[[:space:]]+", " ", qmd_text)
companion_text <- paste(
  readLines(companion_path, warn = FALSE),
  collapse = "\n"
)

r_chunks <- sum(startsWith(qmd_lines, "```{r"))
table_endpoints <- sub(
  "#| label: ",
  "",
  qmd_lines[startsWith(qmd_lines, "#| label: tbl-h07-")],
  fixed = TRUE
)
figure_endpoints <- sub(
  "#| label: ",
  "",
  qmd_lines[startsWith(qmd_lines, "#| label: fig-h07-")],
  fixed = TRUE
)
assert_true(r_chunks == 16L, "H07 result must contain 16 R chunks")
assert_true(
  identical(
    table_endpoints,
    c(
      "tbl-h07-response-specifications",
      "tbl-h07-near-samples",
      "tbl-h07-near-results",
      "tbl-h07-chest-samples",
      "tbl-h07-chest-results",
      "tbl-h07-diagnostic-summary",
      "tbl-h07-sensitivity-samples",
      "tbl-h07-sensitivity-classifications",
      "tbl-h07-model-form-sensitivities",
      "tbl-h07-near-loso",
      "tbl-h07-chest-loso"
    )
  ),
  "H07 result table endpoints or order changed"
)
assert_true(
  identical(
    figure_endpoints,
    c(
      "fig-h07-near-smooth-derivative-pairs",
      "fig-h07-chest-smooth-derivative-pairs"
    )
  ),
  "H07 result figure endpoints or order changed"
)

source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))
calls <- executable_r_call_names(qmd_lines)
forbidden_calls <- c(
  "mgcv::gam",
  "mgcv::bam",
  "gam",
  "bam",
  "stats::predict",
  "predict",
  "stats::simulate",
  "simulate",
  "boot::boot",
  "boot",
  "gratia::derivatives",
  "derivatives",
  "h07_stage2_fit_checkpoint",
  "h07_revised_derivatives",
  "h07_derivative_draws",
  "h07_stage2_tweedie_pilot"
)
assert_true(
  length(intersect(calls, forbidden_calls)) == 0L,
  "H07 result source contains a prohibited analytical call"
)

markdown_matches <- regmatches(
  qmd_text,
  gregexpr("\\[[^]]*\\]\\(([^)]+)\\)", qmd_text, perl = TRUE)
)[[1L]]
targets <- sub(
  "^.*\\]\\(([^)]+)\\)$",
  "\\1",
  markdown_matches,
  perl = TRUE
)
expected_targets <- c(
  "../preparation/04_metric_derivation.qmd",
  "../../audit/hypotheses/H07/H07_analysis_preparation.qmd",
  "../../artifacts/09_tables/H07/H07_main_curve_points.csv",
  "../../artifacts/09_tables/H07/H07_revised_derivative_points.csv",
  "../../artifacts/09_tables/H07/H07_main_samples.csv",
  "../../artifacts/09_tables/H07/H07_revised_paired_figure_settings.csv",
  "../preregistration_deviations.qmd#dev-016",
  "../preregistration_deviations.qmd#dev-033",
  "../preregistration_deviations.qmd#dev-034"
)
assert_true(
  identical(sort(unique(targets)), sort(expected_targets)),
  "H07 result reader-link set changed"
)
assert_true(
  !any(grepl("^(file:|/|[A-Za-z]+://)", targets)) &&
    !any(grepl("[.]html($|#)", targets)) &&
    !any(grepl("_build", targets, fixed = TRUE)),
  "H07 result contains a forbidden reader-page target"
)

for (target in unique(targets)) {
  file_target <- sub("#.*$", "", target)
  anchor <- if (grepl("#", target, fixed = TRUE)) {
    sub("^[^#]*#", "", target)
  } else {
    ""
  }
  resolved <- file.path(dirname(qmd_path), file_target)
  assert_true(
    file.exists(resolved),
    sprintf("H07 link target is missing: %s", target)
  )
  if (nzchar(anchor)) {
    target_text <- paste(readLines(resolved, warn = FALSE), collapse = "\n")
    assert_true(
      grepl(sprintf("{#%s}", anchor), target_text, fixed = TRUE),
      sprintf("H07 link anchor is missing: %s", target)
    )
  }
}
assert_true(
  sum(grepl("DEV-016", qmd_lines, fixed = TRUE)) == 1L &&
    sum(grepl("DEV-033", qmd_lines, fixed = TRUE)) == 1L &&
    sum(grepl("DEV-034", qmd_lines, fixed = TRUE)) == 1L &&
    !grepl("IMP-008", qmd_text, fixed = TRUE),
  "H07 deviation-link contract changed"
)

required_source_phrases <- c(
  "Answer in brief",
  "six of nine primary near-eye metrics",
  "seven of nine",
  "gap-timing-unaware dataset",
  "derivative-defined plateau pattern",
  "not establish a ceiling",
  "do not establish a ceiling"
)
assert_true(
  all(vapply(
    required_source_phrases,
    grepl,
    logical(1),
    x = qmd_text_normalized,
    fixed = TRUE
  )),
  "An accepted H07 source phrase is missing"
)

profile_lines <- readLines(
  file.path(root, "_quarto-nathealth.yml"),
  warn = FALSE
)
result_profile_line <- which(grepl(
  "notebooks/hypotheses/H07.qmd",
  profile_lines,
  fixed = TRUE
))
companion_profile_line <- which(grepl(
  "audit/hypotheses/H07/H07_analysis_preparation.qmd",
  profile_lines,
  fixed = TRUE
))
assert_true(
  length(result_profile_line) == 2L &&
    length(companion_profile_line) == 2L &&
    result_profile_line[[1L]] + 1L == companion_profile_line[[1L]] &&
    result_profile_line[[2L]] < companion_profile_line[[2L]],
  "H07 profile placement changed"
)

matrix <- read.csv(
  file.path(root, "audit/report_harmonization/coordination_matrix.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
h07_row <- matrix[matrix$logical_order == 9L, , drop = FALSE]
assert_true(nrow(h07_row) == 1L, "Coordination matrix has no unique H07 row")
assert_true(
  identical(
    h07_row$harmonization_review_status[[1L]],
    "source_only_adjustment_and_exact_deviation_links_accepted"
  ),
  "H07 source-acceptance status changed"
)

reader_test <- file.path(
  root,
  "tests/hypotheses/H07/test_h07_stage3_reader_report.R"
)
test_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", reader_test),
  stdout = TRUE,
  stderr = TRUE,
  env = sprintf("NATHEALTH_PROJECT_ROOT=%s", root)
)
assert_true(
  identical(attr(test_output, "status"), NULL) &&
    any(grepl(
      "H07 Stage 3 reader-report checks passed",
      test_output,
      fixed = TRUE
    )),
  paste("Current H07 reader test failed:", paste(test_output, collapse = "\n"))
)

preparation_test_text <- paste(
  readLines(
    file.path(root, "tests/hypotheses/H07/test_h07_preparation_report.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
assert_true(
  grepl(
    "../../../notebooks/hypotheses/H07.html",
    preparation_test_text,
    fixed = TRUE
  ) &&
    grepl(
      "../../../notebooks/hypotheses/H07.qmd",
      companion_text,
      fixed = TRUE
    ) &&
    !grepl(
      "../../../notebooks/hypotheses/H07.html",
      companion_text,
      fixed = TRUE
    ),
  "Known held-companion hard-coded-HTML classification changed"
)

build_root <- file.path(root, "_build/nathealth")
build_entries <- list.files(
  build_root,
  recursive = TRUE,
  all.files = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
)
assert_true(
  !any(nzchar(Sys.readlink(build_entries))),
  "The Nature Health build contains a symlink"
)

quarto_version <- system2("quarto", "--version", stdout = TRUE, stderr = TRUE)
assert_true(
  length(quarto_version) >= 1L &&
    identical(trimws(quarto_version[[1L]]), "1.9.37"),
  "Quarto 1.9.37 required"
)

cat(sprintf(
  paste0(
    "H07_RESULT_REPORT018_RELEASE=PASS pins=25/25 chunks=16 ",
    "tables=11 figures=2 links=9 deviations=3 reader_test=PASS ",
    "forbidden_calls=0 build_symlinks=0 R=%s quarto=%s\n"
  ),
  as.character(getRversion()),
  trimws(quarto_version[[1L]])
))
