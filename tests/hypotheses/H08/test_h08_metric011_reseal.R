#!/usr/bin/env Rscript

# Verify the bounded H08 reseal after shared METRIC-011. This test reads the
# sealed evidence and accepted H08 outputs; it does not fit or refit a model.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (dir.exists(project_library)) {
  .libPaths(c(project_library, .libPaths()))
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H08/h08_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H08 METRIC-011 tests require R 4.6.1", call. = FALSE)
}

reseal_script <- file.path(
  root,
  "scripts/hypotheses/H08/reseal_h08_l10_metric011.R"
)
invisible(parse(reseal_script))

read_csv_path <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    progress = FALSE,
    na = ""
  )
}

contract <- h08_input_contract(root)
stopifnot(
  nrow(contract) == 20L,
  !anyDuplicated(contract$input_role),
  all(file.exists(contract$absolute_path)),
  identical(
    unname(vapply(contract$absolute_path, artifact_sha256, character(1))),
    contract$expected_sha256
  )
)

input_audit <- read_csv_path(
  "artifacts/06_model_data/H08/H08_input_audit.csv"
)
stopifnot(
  nrow(input_audit) == 20L,
  all(input_audit$hash_verified),
  identical(input_audit$expected_sha256, input_audit$observed_sha256)
)

evidence_manifest <- read_csv_path(
  "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv"
)
change_record <- evidence_manifest |>
  filter(.data$artifact == "primary_scientific_cell_changes")
stopifnot(
  nrow(change_record) == 1L,
  change_record$status == "PASS",
  change_record$r_version == "4.6.1",
  artifact_sha256(file.path(root, change_record$path)) ==
    change_record$sha256,
  as.numeric(file.info(file.path(root, change_record$path))$size) ==
    change_record$bytes
)

cell_changes <- read_csv_path(change_record$path)
stopifnot(
  nrow(cell_changes) == 8L,
  sum(cell_changes$position == "glasses") == 3L,
  sum(cell_changes$position == "chest") == 5L,
  all(cell_changes$metric == "l10_mean_medi"),
  all(cell_changes$old_value_lx == 4.163336342344337e-17),
  all(cell_changes$new_value_lx == 0)
)

frames_archive <- readRDS(file.path(
  root,
  "artifacts/06_model_data/H08/H08_model_frames.rds"
))
verified_change_rows <- 0L
for (placement in c("glasses", "chest")) {
  frame_name <- paste(
    "main",
    placement,
    "all_available",
    "l10_mean_medi",
    sep = "__"
  )
  frame <- frames_archive$model_frames[[frame_name]]
  expected <- cell_changes |>
    filter(.data$position == .env$placement)
  for (index in seq_len(nrow(expected))) {
    row <-
      as.character(frame$site) == expected$site[[index]] &
      as.character(frame$Id) == expected$Id[[index]] &
      as.Date(frame$local_date) == expected$local_date[[index]]
    stopifnot(sum(row) == 1L, frame$value[row] == 0)
    verified_change_rows <- verified_change_rows + 1L
  }
}
stopifnot(verified_change_rows == 8L)

result_comparison <- read_csv_path(
  "artifacts/09_tables/H08/H08_metric011_result_comparison.csv"
)
display_invariance <- read_csv_path(
  "artifacts/09_tables/H08/H08_metric011_display_invariance.csv"
)
bh_recalculation <- read_csv_path(
  "artifacts/09_tables/H08/H08_metric011_bh_recalculation.csv"
)
reconciliation <- read_csv_path(
  "artifacts/12_manifests/H08/H08_metric011_reconciliation.csv"
)

stopifnot(
  nrow(result_comparison) == 2L,
  !any(result_comparison$reader_display_changed),
  !any(result_comparison$retained_conclusion_changed),
  !any(result_comparison$diagnostic_disposition_changed),
  !any(result_comparison$author_review_required),
  nrow(display_invariance) == 6L,
  all(display_invariance$display_identical),
  nrow(bh_recalculation) == 36L,
  n_distinct(bh_recalculation$family_id) == 4L,
  all(count(bh_recalculation, .data$family_id)$n == 9L),
  sum(!bh_recalculation$raw_p_identical) == 4L,
  all(
    bh_recalculation$metric_id[!bh_recalculation$raw_p_identical] ==
      "l10_mean_medi"
  ),
  sum(!bh_recalculation$adjusted_p_identical) == 3L,
  sum(
    !bh_recalculation$adjusted_p_identical &
      bh_recalculation$metric_id == "m10_mean_medi"
  ) == 1L,
  all(bh_recalculation$adjusted_display_identical),
  all(bh_recalculation$adjusted_conclusion_identical),
  nrow(reconciliation) == 33L,
  all(reconciliation$invariant_verified)
)

reconciled_paths <- file.path(root, reconciliation$path)
stopifnot(
  all(file.exists(reconciled_paths)),
  identical(
    unname(vapply(reconciled_paths, artifact_sha256, character(1))),
    reconciliation$file_sha256_after
  )
)

fully_protected <- c(
  "v0_results",
  "v0_rows",
  "v0_models",
  "exact_longest",
  "observed_dose"
)
protected_records <- reconciliation |>
  filter(.data$artifact_id %in% fully_protected)
stopifnot(
  nrow(protected_records) == length(fully_protected),
  setequal(protected_records$artifact_id, fully_protected),
  identical(
    protected_records$file_sha256_before,
    protected_records$file_sha256_after
  )
)

tests <- read_csv_path("artifacts/09_tables/H08/H08_model_tests.csv")
affected_families <- unique(bh_recalculation$family_id)
for (family_id in affected_families) {
  family <- tests |>
    filter(.data$family_id == .env$family_id) |>
    arrange(.data$metric_order)
  stopifnot(
    nrow(family) == 9L,
    isTRUE(all.equal(
      family$p_adjusted,
      stats::p.adjust(family$p_raw, method = "BH", n = 9L)
    )),
    !any(family$adjusted_significant)
  )
}

cat(
  "H08 METRIC-011 reseal tests passed: eight exact-zero cells, six ",
  "unchanged reader displays, four exact BH families, and 33 passing ",
  "invariance records\n",
  sep = ""
)
