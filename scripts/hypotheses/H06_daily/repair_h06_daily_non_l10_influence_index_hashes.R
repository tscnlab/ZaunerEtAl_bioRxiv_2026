#!/usr/bin/env Rscript

# H06-D-013 no-refit provenance repair. The influence runner correctly wrote
# all 468 checkpoint objects but its dplyr data mask retained the identically
# named base-model `checkpoint_sha256` column in the influence index. This
# script proves that narrow failure, verifies every influence object against
# its internal contract, updates only the stale index hash field, and records
# before/after evidence. No model, estimate, diagnostic, or fitted frame is
# changed.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(tibble)
})
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_contract.R"
))

h06d_prod_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "The influence-index repair requires R 4.6.1"
)
paths <- h06d_prod_checkpoint_paths(root)
state <- readRDS(paths$state)
h06d_prod_assert(
  identical(state$authorization, "H06-D-013") &&
    state$phase %in% c("INFLUENCE_COMPLETE", "SENSITIVITY_COMPLETE"),
  "The complete influence phase is required before the no-refit index repair"
)
invisible(h06d_prod_verify_contract(root, h06d_prod_input_contract()))
invisible(h06d_prod_verify_contract(
  root,
  h06d_prod_main_h06_contract() |>
    dplyr::mutate(input_id = paste0("main_h06_", dplyr::row_number()), .before = 1L)
))

diagnostic_dir <- file.path(root, "artifacts/08_diagnostics/H06_daily")
preservation_baseline <- readr::read_csv(
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_baseline.csv"
  ),
  show_col_types = FALSE
)
invisible(h06d_prod_recheck_preservation(
  root,
  preservation_baseline,
  "pre_influence_index_hash_repair"
))

base_index <- readr::read_csv(paths$base_index, show_col_types = FALSE) |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
influence_index <- readr::read_csv(paths$influence, show_col_types = FALSE) |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
h06d_prod_assert(
  nrow(base_index) == 468L && nrow(influence_index) == 468L &&
    identical(base_index$frame_key, influence_index$frame_key) &&
    sum(influence_index$completed_refits) == 66664L,
  "The base and influence indexes are not the complete aligned grid"
)

absolute_paths <- file.path(root, influence_index$checkpoint_relative_path)
actual_hashes_before <- vapply(
  absolute_paths,
  h06d_prod_sha256,
  character(1)
)
actual_bytes_before <- as.numeric(file.info(absolute_paths)$size)

# The stale values must be exactly the corresponding base-model object hashes,
# which is the expected signature of the runner's data-mask name collision.
h06d_prod_assert(
  all(influence_index$checkpoint_sha256 == base_index$checkpoint_sha256) &&
    all(influence_index$checkpoint_sha256 != actual_hashes_before) &&
    all(influence_index$checkpoint_bytes == actual_bytes_before) &&
    all(influence_index$checkpoint_relative_path !=
      base_index$checkpoint_relative_path),
  paste0(
    "The influence-index mismatch is not the sealed one-column data-mask ",
    "failure; no repair was made"
  )
)

object_checks <- lapply(seq_len(nrow(influence_index)), function(index) {
  meta <- influence_index[index, , drop = FALSE]
  object <- readRDS(absolute_paths[[index]])
  tibble::tibble(
    row = index,
    frame_key = meta$frame_key[[1L]],
    influence_relative_path = meta$checkpoint_relative_path[[1L]],
    stale_index_sha256 = meta$checkpoint_sha256[[1L]],
    corresponding_base_sha256 = base_index$checkpoint_sha256[[index]],
    actual_influence_sha256 = actual_hashes_before[[index]],
    actual_influence_bytes = actual_bytes_before[[index]],
    authorization_ok = identical(object$authorization, "H06-D-013"),
    frame_key_ok = identical(object$frame_key, meta$frame_key[[1L]]),
    frame_object_sha256_ok = identical(
      object$frame_object_sha256,
      meta$frame_object_sha256[[1L]]
    ),
    influence_code_sha256_ok = identical(
      object$influence_code_sha256,
      meta$influence_code_sha256[[1L]]
    ),
    task_inventory_sha256_ok = identical(
      object$task_inventory_sha256,
      meta$task_inventory_sha256[[1L]]
    ),
    completed_refits = nrow(object$results),
    expected_refits = meta$completed_refits[[1L]],
    task_sequence_ok = identical(
      object$results$task_within_cell,
      seq_len(meta$completed_refits[[1L]])
    ),
    repair_classification = "STALE_INDEX_HASH_FIELD_ONLY_NO_REFIT"
  )
}) |>
  dplyr::bind_rows()
h06d_prod_assert(
  nrow(object_checks) == 468L &&
    all(object_checks$authorization_ok) &&
    all(object_checks$frame_key_ok) &&
    all(object_checks$frame_object_sha256_ok) &&
    all(object_checks$influence_code_sha256_ok) &&
    all(object_checks$task_inventory_sha256_ok) &&
    all(object_checks$completed_refits == object_checks$expected_refits) &&
    all(object_checks$task_sequence_ok),
  "An influence object failed its scientific checkpoint contract"
)

evidence_path <- file.path(
  diagnostic_dir,
  "H06_daily_non_l10_production_influence_index_hash_repair.csv"
)
h06d_prod_write_csv(object_checks, evidence_path)

influence_index$checkpoint_sha256 <- actual_hashes_before
h06d_prod_write_csv(influence_index, paths$influence)

actual_hashes_after <- vapply(
  absolute_paths,
  h06d_prod_sha256,
  character(1)
)
h06d_prod_assert(
  identical(actual_hashes_after, actual_hashes_before) &&
    all(readr::read_csv(
      paths$influence,
      show_col_types = FALSE
    )$checkpoint_sha256 == actual_hashes_after),
  "The no-refit index repair did not preserve and correctly pin all objects"
)
invisible(h06d_prod_recheck_preservation(
  root,
  preservation_baseline,
  "post_influence_index_hash_repair"
))

state <- utils::modifyList(
  state,
  list(
    influence_index_repair = "STALE_INDEX_HASH_FIELD_ONLY_NO_REFIT",
    influence_index_repair_entries = nrow(object_checks),
    influence_index_repair_evidence_sha256 = h06d_prod_sha256(evidence_path),
    updated = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )
)
h06d_prod_write_rds(state, paths$state)
message(
  paste0(
    "H06-D-013 no-refit influence-index repair PASS: 468 object identities ",
    "preserved and correctly repinned"
  )
)
