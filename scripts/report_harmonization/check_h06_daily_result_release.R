#!/usr/bin/env Rscript

# Read-only central preflight for the single H06_daily result render.

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

verify_rows <- function(rows, label) {
  paths <- file.path(root, rows$relative_path)
  assert(all(file.exists(paths)), paste(label, "contains a missing path"))
  observed_sha <- unname(vapply(paths, sha256, character(1L)))
  observed_bytes <- as.numeric(file.info(paths)$size)
  assert(
    identical(observed_sha, rows$sha256) &&
      identical(observed_bytes, as.numeric(rows$bytes)),
    paste(label, "contains identity drift")
  )
  invisible(TRUE)
}

assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06_daily release preflight requires R 4.6.1"
)

hard_pins <- readr::read_csv(
  file.path(
    root,
    "audit/report_harmonization/report018_h06_daily_result_release_pins.csv"
  ),
  show_col_types = FALSE
)
assert(
  nrow(hard_pins) == 25L &&
    !anyDuplicated(hard_pins$relative_path) &&
    !any(grepl("report018_h06_daily_result_release_manifest", hard_pins$relative_path)),
  "The H06_daily release pin set is malformed or circular"
)
verify_rows(hard_pins, "The H06_daily release pin set")

hourly_acceptance <- readr::read_csv(
  file.path(
    root,
    "audit/report_harmonization/",
    "report018_h06_companion_independent_acceptance_manifest.csv"
  ),
  show_col_types = FALSE
)
names(hourly_acceptance)[names(hourly_acceptance) == "path"] <- "relative_path"
assert(
  nrow(hourly_acceptance) == 37L &&
    !anyDuplicated(hourly_acceptance$relative_path) &&
    !"audit/report_harmonization/report018_h06_companion_independent_acceptance_manifest.csv" %in%
      hourly_acceptance$relative_path,
  "The hourly H06 acceptance manifest is malformed or circular"
)
verify_rows(hourly_acceptance, "The hourly H06 acceptance manifest")

input_manifest <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H06_daily/H06_daily_stage3_input_manifest.csv"
  ),
  show_col_types = FALSE,
  na = c("", "NA")
)
assert(
  nrow(input_manifest) == 23L &&
    !anyDuplicated(input_manifest$relative_path) &&
    all(input_manifest$verification_status == "PASS") &&
    identical(input_manifest$expected_sha256, input_manifest$actual_sha256),
  "The accepted H06_daily Stage 3 input contract is incomplete"
)
input_paths <- file.path(root, input_manifest$relative_path)
assert(
  all(file.exists(input_paths)) &&
    identical(
      unname(vapply(input_paths, sha256, character(1L))),
      input_manifest$expected_sha256
    ),
  "A current H06_daily Stage 3 input differs from its accepted identity"
)

source_manifest <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_stage3_source_data_manifest.csv"
  ),
  show_col_types = FALSE
)
assert(
  nrow(source_manifest) == 23L &&
    !anyDuplicated(source_manifest$relative_path),
  "The H06_daily source-data manifest is malformed"
)
verify_rows(source_manifest, "The H06_daily source-data manifest")

output_manifest <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H06_daily/H06_daily_stage3_output_manifest.csv"
  ),
  show_col_types = FALSE
)
output_paths <- file.path(root, output_manifest$relative_path)
output_actual_sha <- ifelse(
  file.exists(output_paths),
  vapply(output_paths, sha256, character(1L)),
  NA_character_
)
output_actual_bytes <- as.numeric(file.info(output_paths)$size)
output_bad <- is.na(output_actual_sha) |
  output_actual_sha != output_manifest$sha256 |
  output_actual_bytes != as.numeric(output_manifest$bytes)
expected_output_transitions <- c(
  "notebooks/hypotheses/H06_daily.qmd",
  paste0(
    "artifacts/10_figures/H06_daily/",
    "H06_daily_stage3_primary_site_deviations.png"
  )
)
assert(
  nrow(output_manifest) == 54L &&
    !anyDuplicated(output_manifest$relative_path) &&
    identical(output_manifest$relative_path[output_bad], expected_output_transitions) &&
    identical(
      output_manifest$sha256[output_bad],
      c(
        "0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc",
        "69fd3786901993e9e9c0cfb3432abde07fbed14ccac03bea08ed9ea55751400c"
      )
    ) &&
    identical(
      output_actual_sha[output_bad],
      c(
        "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08",
        "a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1"
      )
    ),
  "The historical output manifest has an unclassified live transition"
)

figure_qa <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_stage3_revision_figure_readability_qa.csv"
  ),
  show_col_types = FALSE
)
figure_paths <- file.path(root, figure_qa$relative_path)
figure_actual_sha <- vapply(figure_paths, sha256, character(1L))
figure_bad <- figure_actual_sha != figure_qa$figure_sha256
assert(
  nrow(figure_qa) == 5L &&
    identical(
      figure_qa$relative_path[figure_bad],
      expected_output_transitions[[2L]]
    ) &&
    identical(
      figure_qa$figure_sha256[figure_bad],
      "69fd3786901993e9e9c0cfb3432abde07fbed14ccac03bea08ed9ea55751400c"
    ) &&
    identical(
      unname(figure_actual_sha[figure_bad]),
      "a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1"
    ) &&
    all(figure_qa$paired_source_present) &&
    all(figure_qa$alt_text_present) &&
    all(figure_qa$visual_review_status == "PASS"),
  "The figure-readability manifest has an unclassified live transition"
)

gt_audit <- readr::read_csv(
  file.path(
    root,
    "audit/report_harmonization/phase4_h06_daily_gt_source_audit.csv"
  ),
  show_col_types = FALSE,
  na = c("", "NA")
)
assert(
  nrow(gt_audit) == 14L &&
    !anyDuplicated(gt_audit$label) &&
    all(gt_audit$source_native_gt_static) &&
    all(gt_audit$source_contract_complete) &&
    all(
      gt_audit$source_sha256 ==
        "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08"
    ),
  "The H06_daily native gt source contract is incomplete"
)

qmd_path <- file.path(root, "notebooks/hypotheses/H06_daily.qmd")
qmd_lines <- readLines(qmd_path, warn = FALSE)
qmd <- paste(qmd_lines, collapse = "\n")
table_labels <- sub(
  "^#\\| label:[[:space:]]*",
  "",
  qmd_lines[grepl("^#\\| label:[[:space:]]*tbl-", qmd_lines)]
)
figure_labels <- sub(
  ".*\\{#(fig-[^[:space:]}]+).*",
  "\\1",
  qmd_lines[grepl("^!\\[.*\\{#fig-", qmd_lines)]
)
assert(
  length(table_labels) == 14L &&
    length(unique(table_labels)) == 14L &&
    length(figure_labels) == 5L &&
    length(unique(figure_labels)) == 5L,
  "The H06_daily result endpoint inventory changed"
)
assert(
  grepl("[hourly H06 analysis](H06.qmd)", qmd, fixed = TRUE) &&
    !grepl("[main H06 analysis](H06.qmd)", qmd, fixed = TRUE),
  "The accepted H06_daily hourly-main link wording changed"
)

# Replay the complete historical focused test in memory after reconciling only
# the three accepted REPORT-014 classifications. No project file is changed.
test_path <- file.path(
  root,
  "tests/hypotheses/H06_daily/test_h06_daily_stage3_reader_report.R"
)
test_lines <- readLines(test_path, warn = FALSE)
legacy_phrase <- "[main H06 analysis](H06.qmd)"
accepted_phrase <- "[hourly H06 analysis](H06.qmd)"
phrase_rows <- which(grepl(legacy_phrase, test_lines, fixed = TRUE))
assert(length(phrase_rows) == 1L, "The legacy reader-test phrase changed")
test_lines[[phrase_rows]] <- sub(
  legacy_phrase,
  accepted_phrase,
  test_lines[[phrase_rows]],
  fixed = TRUE
)

insert_after <- function(lines, pattern, addition) {
  at <- which(lines == pattern)
  assert(length(at) == 1L, paste("Missing focused-test insertion point:", pattern))
  append(lines, addition, after = at)
}

test_lines <- insert_after(
  test_lines,
  paste0(
    "output_manifest <- read_project_csv(file.path(manifest_dir, ",
    "\"H06_daily_stage3_output_manifest.csv\"))"
  ),
  c(
    "current_output_paths <- c(",
    "  \"notebooks/hypotheses/H06_daily.qmd\",",
    "  paste0(\"artifacts/10_figures/H06_daily/\",",
    "    \"H06_daily_stage3_primary_site_deviations.png\")",
    ")",
    "current_output_rows <- match(current_output_paths, output_manifest$relative_path)",
    "stopifnot(!anyNA(current_output_rows))",
    "current_output_files <- file.path(root, current_output_paths)",
    "output_manifest$sha256[current_output_rows] <- vapply(",
    "  current_output_files, sha256, character(1L)",
    ")",
    "output_manifest$bytes[current_output_rows] <- as.numeric(",
    "  file.info(current_output_files)$size",
    ")"
  )
)

test_lines <- insert_after(
  test_lines,
  paste0(
    "figure_qa <- read_project_csv(file.path(manifest_dir, ",
    "\"H06_daily_stage3_revision_figure_readability_qa.csv\"))"
  ),
  c(
    "current_figure_path <- paste0(",
    "  \"artifacts/10_figures/H06_daily/\",",
    "  \"H06_daily_stage3_primary_site_deviations.png\"",
    ")",
    "current_figure_row <- match(current_figure_path, figure_qa$relative_path)",
    "stopifnot(length(current_figure_row) == 1L, !is.na(current_figure_row))",
    "figure_qa$figure_sha256[[current_figure_row]] <- sha256(",
    "  file.path(root, current_figure_path)",
    ")"
  )
)

test_environment <- new.env(parent = globalenv())
eval(parse(text = test_lines), envir = test_environment)

cat(
  paste0(
    "PASS: H06_daily result release preflight under R ",
    as.character(getRversion()),
    "; 25/25 hard pins, 37/37 hourly acceptance rows, 23/23 inputs, ",
    "23/23 source-data rows, exactly three accepted legacy classifications, ",
    "14 native gt tables, five figures, and the complete reconciled focused ",
    "test pass.\n"
  )
)
