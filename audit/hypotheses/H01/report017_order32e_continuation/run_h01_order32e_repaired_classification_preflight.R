#!/usr/bin/env Rscript

# One non-mutating repaired-classification preflight for REPORT-017 order 32e.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(tibble)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 32e requires R 4.6.1", call. = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
old_candidate_dir <- "/private/tmp/H01-order32d-candidates.nW90PN"
quarantine_dir <- "/private/tmp/H01-order32d-quarantine.Xc28uF"
order32d_evidence <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32d_display_repair"
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

source_specs <- tribble(
  ~name, ~path, ~sha256, ~rows,
  "support",
  "artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv",
  "cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0",
  136L,
  "paired",
  "artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_paired_placement_figure_source.csv",
  "8e1672e499e6bee05cde70647165e780dfa5cb9195ed0c3f1bd203da5d838853",
  30L,
  "diagnostic",
  "artifacts/11_source_data/H01/stage3/H01_stage3_diagnostic_figure_source.csv",
  "d9b424ae246fc688670a77a561717701fec3ddffaf000af72ea6b68f214b9397",
  204L
)

read_frozen <- function(spec) {
  path <- file.path(root, spec$path[[1]])
  if (!file.exists(path) || sha256_file(path) != spec$sha256[[1]]) {
    stop("Frozen source identity mismatch: ", spec$path[[1]], call. = FALSE)
  }
  value <- read_csv(path, show_col_types = FALSE, progress = FALSE)
  if (nrow(value) != spec$rows[[1]]) {
    stop("Frozen source row-count mismatch: ", spec$path[[1]], call. = FALSE)
  }
  value
}

support <- read_frozen(source_specs[1, ])
paired <- read_frozen(source_specs[2, ])
diagnostic <- read_frozen(source_specs[3, ])

if (
  nrow(distinct(support, .data$placement_label, .data$metric_order, .data$question_order)) !=
    136L ||
    nrow(distinct(paired, .data$effect_scale, .data$point_label)) != 30L ||
    nrow(distinct(
      diagnostic,
      .data$placement_label,
      .data$metric_order,
      .data$check_order
    )) != 204L
) {
  stop("A frozen display key is not unique", call. = FALSE)
}

if (
  !identical(
    sort(unique(support$support_status)),
    c("Not supported", "Supported")
  ) ||
    !identical(
      sort(unique(diagnostic$check_status)),
      c("Not applicable", "Pass", "Review")
    ) ||
    !identical(sort(unique(paired$effect_scale)), c("Difference", "Ratio")) ||
    !all(paired$sample_exactly_matched)
) {
  stop("The repaired observed-category guard did not pass", call. = FALSE)
}

quarantine <- read_csv(
  file.path(order32d_evidence, "quarantine_recovery_evidence.csv"),
  show_col_types = FALSE
)
if (nrow(quarantine) != 3L) {
  stop("The quarantine evidence must contain exactly three rows", call. = FALSE)
}

quarantine_exact <- vapply(seq_len(nrow(quarantine)), function(index) {
  row <- quarantine[index, ]
  recovery_path <- row$recovery_path[[1]]
  original_path <- file.path(root, row$original_path[[1]])
  file.exists(recovery_path) &&
    !file.info(recovery_path)$isdir &&
    !nzchar(Sys.readlink(recovery_path)) &&
    sha256_file(recovery_path) == row$expected_sha256[[1]] &&
    as.numeric(file.info(recovery_path)$size) == row$expected_bytes[[1]] &&
    !file.exists(original_path)
}, logical(1))
if (!all(quarantine_exact)) {
  stop("The three recovery files are not exact", call. = FALSE)
}

build_pre <- read_csv(
  file.path(order32d_evidence, "build_inventory_prechange.csv"),
  show_col_types = FALSE
)
build_stop <- read_csv(
  file.path(order32d_evidence, "build_inventory_postqa.csv"),
  show_col_types = FALSE
)
build_transitions <- full_join(
  select(build_pre, "path", pre_present = "present"),
  select(build_stop, "path", stop_present = "present"),
  by = "path",
  relationship = "one-to-one"
) |>
  filter(.data$pre_present %in% TRUE, is.na(.data$stop_present)) |>
  pull(.data$path) |>
  sort()
if (!identical(build_transitions, sort(quarantine$recovery_relative_path))) {
  stop("Build-relative quarantine classification is not exact", call. = FALSE)
}

protected_pre <- read_csv(
  file.path(order32d_evidence, "protected_inventory_prechange.csv"),
  show_col_types = FALSE
)
protected_stop <- read_csv(
  file.path(order32d_evidence, "protected_inventory_postqa.csv"),
  show_col_types = FALSE
)
protected_transitions <- full_join(
  select(protected_pre, "path", pre_present = "present"),
  select(protected_stop, "path", stop_present = "present"),
  by = "path",
  relationship = "one-to-one"
) |>
  filter(.data$pre_present %in% TRUE, .data$stop_present %in% FALSE) |>
  pull(.data$path) |>
  sort()
if (!identical(protected_transitions, sort(quarantine$original_path))) {
  stop("Project-relative protected quarantine classification is not exact", call. = FALSE)
}

if (
  !dir.exists(old_candidate_dir) ||
    length(list.files(old_candidate_dir, all.files = TRUE, no.. = TRUE)) != 0L
) {
  stop("The failed candidate directory is not present and empty", call. = FALSE)
}

cat(
  "ORDER32E_REPAIRED_CLASSIFICATION_PREFLIGHT=PASS\n",
  "R_VERSION=", as.character(getRversion()), "\n",
  "SOURCE_ROWS=136,30,204\n",
  "OBSERVED_SUPPORT=Not supported|Supported\n",
  "OBSERVED_DIAGNOSTIC=Not applicable|Pass|Review\n",
  "PAIRED_MATCHED_FLAGS=30/30\n",
  "BUILD_QUARANTINE_TRANSITIONS=3/3\n",
  "PROTECTED_QUARANTINE_TRANSITIONS=3/3\n",
  "OLD_FAILED_CANDIDATE_ENTRIES=0\n",
  "QUARANTINE_FILES_EXACT=3/3\n",
  sep = ""
)
