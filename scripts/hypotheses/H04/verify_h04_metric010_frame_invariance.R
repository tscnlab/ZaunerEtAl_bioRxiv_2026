# Verify that the shared METRIC-010 provenance repin did not change any H04
# analysis frame. This script rebuilds data frames only; it never fits or
# refits a statistical model.

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H04 frame-invariance verification requires R 4.6.1", call. = FALSE)
}

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_data.R"))

contract <- h04_input_contract(root)
read_contract_rds <- function(input_id) {
  readRDS(contract$path[contract$input_id == input_id])
}

inputs <- list(
  diary = read_contract_rds("normalized_diary"),
  near_eye = read_contract_rds("main_near_eye"),
  chest = read_contract_rds("main_chest"),
  gap = read_contract_rds("gap_timing_unaware"),
  sites = readr::read_csv(
    contract$path[contract$input_id == "site_registry"],
    show_col_types = FALSE
  ) |>
    dplyr::arrange(.data$display_order)
)

rebuilt_full <- h04_prepare_scenario_frames(inputs, root)
rebuilt <- list(
  main = rebuilt_full$main,
  paired = rebuilt_full$paired,
  exactly_one = rebuilt_full$exactly_one,
  retain_coselected_other = rebuilt_full$retain_coselected_other,
  exclude_other_only = rebuilt_full$exclude_other_only,
  unweighted_long = rebuilt_full$unweighted_long,
  gap_timing_unaware = rebuilt_full$gap
)
frozen <- readRDS(file.path(
  root,
  "artifacts/06_model_data/H04/H04_model_frames.rds"
))

comparison <- dplyr::bind_rows(lapply(names(frozen), function(scenario) {
  dplyr::bind_rows(lapply(names(frozen[[scenario]]), function(placement) {
    rebuilt_frame <- rebuilt[[scenario]][[placement]]
    frozen_frame <- frozen[[scenario]][[placement]]
    value_match <- isTRUE(all.equal(
      rebuilt_frame,
      frozen_frame,
      tolerance = 0,
      check.attributes = FALSE
    ))
    exact_match <- isTRUE(all.equal(
      rebuilt_frame,
      frozen_frame,
      tolerance = 0,
      check.attributes = TRUE
    ))
    tibble::tibble(
      scenario = scenario,
      placement = placement,
      rows_rebuilt = nrow(rebuilt_frame),
      rows_frozen = nrow(frozen_frame),
      columns_rebuilt = ncol(rebuilt_frame),
      columns_frozen = ncol(frozen_frame),
      values_match_tolerance_zero = value_match,
      attributes_match = exact_match,
      rebuilt_object_sha256 = digest::digest(
        rebuilt_frame,
        algo = "sha256",
        serialize = TRUE
      ),
      frozen_object_sha256 = digest::digest(
        frozen_frame,
        algo = "sha256",
        serialize = TRUE
      )
    )
  }))
}))

if (!all(comparison$values_match_tolerance_zero)) {
  stop(
    "At least one H04 analysis-frame value changed after the METRIC-010 repin",
    call. = FALSE
  )
}

diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H04")
dir.create(diagnostic_root, recursive = TRUE, showWarnings = FALSE)
output_path <- file.path(
  diagnostic_root,
  "H04_metric010_frame_invariance.csv"
)
readr::write_csv(comparison, output_path, na = "")

frozen_input_audit <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H04/H04_input_audit.csv"),
  show_col_types = FALSE
)
repinned_ids <- c("main_near_eye", "main_chest")
reconciliation <- contract |>
  dplyr::filter(.data$input_id %in% repinned_ids) |>
  dplyr::left_join(
    frozen_input_audit |>
      dplyr::select(
        "input_id",
        accepted_stage2_sha256 = "sha256"
      ),
    by = "input_id",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    current_sha256 = vapply(.data$path, artifact_sha256, character(1)),
    current_contract_verified = .data$current_sha256 == .data$sha256,
    all_downstream_frame_values_identical = vapply(
      .data$input_id,
      function(input_id) {
        placement <- if (identical(input_id, "main_near_eye")) {
          "near_eye"
        } else {
          "chest"
        }
        all(comparison$values_match_tolerance_zero[
          comparison$placement == placement
        ])
      },
      logical(1)
    ),
    disposition = paste(
      "provenance-only METRIC-010 repin; accepted frozen model objects and",
      "reported results remain controlling; no model refit"
    )
  ) |>
  dplyr::select(
    "input_id",
    "path",
    "accepted_stage2_sha256",
    current_contract_sha256 = "sha256",
    "current_sha256",
    "current_contract_verified",
    "all_downstream_frame_values_identical",
    "disposition"
  )

if (!all(
  reconciliation$current_contract_verified &
    reconciliation$all_downstream_frame_values_identical
)) {
  stop("H04 METRIC-010 input reconciliation failed", call. = FALSE)
}

reconciliation_path <- file.path(
  diagnostic_root,
  "H04_metric010_input_reconciliation.csv"
)
readr::write_csv(reconciliation, reconciliation_path, na = "")

message(
  "H04 frame-value invariance PASS; ",
  sum(comparison$attributes_match),
  "/",
  nrow(comparison),
  " frames also match attributes; frame evidence SHA-256: ",
  artifact_sha256(output_path),
  "; reconciliation SHA-256: ",
  artifact_sha256(reconciliation_path)
)
