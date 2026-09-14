# Verify the isolated H01 METRIC-010 MDER production bootstrap.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
base::source(file.path(root, "scripts/pipeline/paths_io.R"))
base::source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

metric_id <- "mder_mean_of_viable_ratios"
production_label <- "PRODUCTION - 1,000 successful joint bootstrap refits"
metric_root <- file.path(
  root,
  "audit/hypotheses/H01/mder_METRIC-010"
)
production_root <- file.path(metric_root, "bootstrap_production")
runner_path <- file.path(
  root,
  "scripts/hypotheses/H01/run_h01_mder_METRIC010_bootstrap_production.R"
)
test_path <- file.path(
  root,
  "tests/hypotheses/H01/test_h01_mder_METRIC010_production.R"
)
authorization_path <- file.path(
  metric_root,
  "H01_METRIC-010_production_authorization.md"
)

message("Checking author authorization and the production runner")
stopifnot(
  file.exists(runner_path),
  file.exists(test_path),
  file.exists(authorization_path),
  identical(
    artifact_sha256(authorization_path),
    "f9279a46c73b5feede48adaeee98306a4841183468688446ce91cf09045e33af"
  )
)
invisible(parse(file = runner_path))
authorization_text <- paste(
  readLines(authorization_path, warn = FALSE),
  collapse = "\n"
)
stopifnot(
  grepl(
    "approve the 1,000-refit MDER production bootstrap",
    authorization_text,
    fixed = TRUE
  ),
  grepl("exactly 1,000 successful", authorization_text, fixed = TRUE),
  grepl(
    "eight already accepted MDER targets",
    authorization_text,
    fixed = TRUE
  ),
  grepl("does not permit any non-MDER refit", authorization_text, fixed = TRUE)
)

read_production <- function(relative_path) {
  path <- file.path(production_root, relative_path)
  stopifnot(file.exists(path))
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

message("Checking the exact current-input bridge")
bridge <- read_production(
  "diagnostics/H01_METRIC-010_bootstrap_production_input_bridge.csv"
)
expected_samples <- tibble::tribble(
  ~run_id,
  ~participant_days,
  ~participants,
  ~sites,
  "main__chest__all_available",
  732L,
  152L,
  8L,
  "main__chest__paired_common_sample",
  489L,
  107L,
  8L,
  "main__glasses__all_available",
  702L,
  137L,
  9L,
  "main__glasses__paired_common_sample",
  489L,
  107L,
  8L,
  "manuscript_prepared_data__chest__all_available",
  723L,
  152L,
  8L,
  "manuscript_prepared_data__chest__paired_common_sample",
  478L,
  107L,
  8L,
  "manuscript_prepared_data__glasses__all_available",
  687L,
  137L,
  9L,
  "manuscript_prepared_data__glasses__paired_common_sample",
  478L,
  107L,
  8L
) |>
  dplyr::arrange(run_id)
observed_samples <- bridge |>
  dplyr::select(run_id, participant_days, participants, sites) |>
  dplyr::arrange(run_id)
stopifnot(
  nrow(bridge) == 8L,
  isTRUE(all.equal(observed_samples, expected_samples, tolerance = 0)),
  all(bridge$participant_days == bridge$observations),
  all(bridge$scientific_frame_identical),
  all(bridge$model_specification_identical),
  all(bridge$row_keys_identical),
  all(bridge$response_values_identical),
  all(
    bridge$container_difference_classification %in%
      c("NONE", "NON_ANALYTICAL_METRIC_SETTINGS_ATTRIBUTE_ONLY")
  )
)

message("Checking eight 1,000-refit production targets")
audits <- read_production(
  "diagnostics/H01_METRIC-010_bootstrap_production_audit.csv"
)
failures <- read_production(
  "diagnostics/H01_METRIC-010_bootstrap_production_failures.csv"
)
runtimes <- read_production(
  "diagnostics/H01_METRIC-010_bootstrap_production_runtime.csv"
)
provenance <- read_production(
  "diagnostics/H01_METRIC-010_bootstrap_production_provenance.csv"
)
registry <- h01_run_registry() |>
  dplyr::arrange(run_id)
expected_seeds <- vapply(
  seq_len(nrow(registry)),
  function(index) {
    run <- registry[index, , drop = FALSE]
    h01_primary_seed(
      17L,
      run$data_scenario_id,
      run$placement,
      run$sample_scenario
    )
  },
  integer(1)
)
observed_audits <- audits |>
  dplyr::arrange(run_id)
stopifnot(
  nrow(audits) == 8L,
  setequal(audits$run_id, registry$run_id),
  all(audits$metric_id == metric_id),
  all(audits$inference_status == production_label),
  all(audits$attempted_refits == 1500L),
  all(audits$successful_refits >= 1000L),
  all(audits$used_refits == 1000L),
  all(
    audits$failed_refits == audits$attempted_refits - audits$successful_refits
  ),
  all(audits$status == "PASS"),
  all(audits$interval_method == "parametric_percentile"),
  isTRUE(all.equal(observed_audits$seed, expected_seeds, tolerance = 0)),
  nrow(failures) == sum(audits$failed_refits),
  nrow(runtimes) == 8L,
  all(runtimes$successful_draws == 1000L),
  all(runtimes$requested_parallel_workers == 4L),
  all(runtimes$omp_threads == "1"),
  all(runtimes$openblas_threads == "1"),
  all(runtimes$mkl_threads == "1"),
  all(runtimes$veclib_maximum_threads == "1"),
  all(runtimes$wall_seconds > 0),
  all(
    runtimes$checkpoint_status %in%
      c(
        "WROTE_COMPLETED_TARGET_CHECKPOINT",
        "REUSED_COMPLETED_TARGET_CHECKPOINT"
      )
  ),
  dplyr::n_distinct(audits$production_contract_sha256) == 1L,
  identical(
    unique(audits$production_contract_sha256),
    unique(runtimes$production_contract_sha256)
  )
)

draw_paths <- file.path(root, runtimes$draws_path)
checkpoint_paths <- sub(
  "/draws/",
  "/checkpoints/",
  draw_paths,
  fixed = TRUE
)
checkpoint_paths <- sub(
  "_draws\\.rds$",
  "_checkpoint.rds",
  checkpoint_paths
)
measure_columns <- c(
  "marginal_r2",
  "conditional_r2",
  "participant_associated_share",
  "site_part_r2",
  "photoperiod_part_r2",
  "latitude_model_marginal_r2",
  "latitude_part_r2",
  "unrepresented_share"
)
stopifnot(
  length(draw_paths) == 8L,
  length(unique(draw_paths)) == 8L,
  all(file.exists(draw_paths)),
  all(file.exists(checkpoint_paths)),
  identical(
    unname(vapply(draw_paths, artifact_sha256, character(1))),
    unname(runtimes$draws_sha256)
  ),
  identical(
    as.numeric(file.info(draw_paths)$size),
    runtimes$draws_bytes
  )
)
for (index in seq_along(draw_paths)) {
  draws <- readRDS(draw_paths[[index]])
  checkpoint <- readRDS(checkpoint_paths[[index]])
  stopifnot(
    nrow(draws) == 1000L,
    all(measure_columns %in% names(draws)),
    all(draws$status == "PASS"),
    identical(sort(unique(draws$bootstrap_replicate)), seq_len(1000L)),
    !anyDuplicated(draws[c("approximation", "bootstrap_replicate")]),
    all(draws$attempt >= 1L & draws$attempt <= 1500L),
    all(vapply(
      draws[measure_columns],
      function(value) all(is.finite(value) | is.na(value)),
      logical(1)
    )),
    identical(
      checkpoint$target_contract_sha256,
      runtimes$target_contract_sha256[[index]]
    ),
    identical(checkpoint$draws_sha256, runtimes$draws_sha256[[index]]),
    checkpoint$production$audit$used_refits == 1000L,
    checkpoint$production$audit$status == "PASS"
  )
}

message("Checking all production 95% interval rows")
summaries <- read_production(
  "tables/H01_METRIC-010_bootstrap_production_r2_summaries.csv"
)
point_results <- readr::read_csv(
  file.path(
    metric_root,
    paste0(
      "point_refit_repaired_gap/artifacts/09_tables/H01/",
      "H01_r2_point_summaries.csv"
    )
  ),
  show_col_types = FALSE,
  progress = FALSE
)
expected_point <- point_results |>
  dplyr::select(run_id, dplyr::all_of(measure_columns)) |>
  tidyr::pivot_longer(
    cols = dplyr::all_of(measure_columns),
    names_to = "measure",
    values_to = "expected_estimate"
  )
summary_point_check <- summaries |>
  dplyr::select(run_id, measure, estimate) |>
  dplyr::left_join(expected_point, by = c("run_id", "measure"))
stopifnot(
  nrow(summaries) == 64L,
  setequal(summaries$measure, measure_columns),
  all(summaries$metric_id == metric_id),
  all(summaries$inference_status == production_label),
  all(summaries$bootstrap_successful_used == 1000L),
  all(summaries$interval_method == "joint_parametric_percentile"),
  all(summaries$status == "PASS"),
  all(is.finite(summaries$estimate)),
  all(is.finite(summaries$conf_low)),
  all(is.finite(summaries$conf_high)),
  all(summaries$conf_low <= summaries$conf_high),
  isTRUE(all.equal(
    summary_point_check$estimate,
    summary_point_check$expected_estimate,
    tolerance = 0
  ))
)

message("Checking production provenance and preservation")
stopifnot(
  nrow(provenance) == 1L,
  provenance$inference_status == production_label,
  provenance$author_approval_token == "approved_2026-08-31",
  grepl("Explicit author reply", provenance$author_approval, fixed = TRUE),
  provenance$production_authorization_sha256 ==
    artifact_sha256(authorization_path),
  provenance$successful_refits_per_target == 1000L,
  provenance$planned_targets == 8L,
  provenance$completed_targets == 8L,
  provenance$total_attempted_refits == sum(audits$attempted_refits),
  provenance$total_successful_refits == sum(audits$successful_refits),
  provenance$total_used_refits == 8000L,
  provenance$total_failed_refits == sum(audits$failed_refits),
  provenance$total_warning_refits == sum(audits$warning_refits),
  provenance$total_target_wall_seconds == sum(runtimes$wall_seconds),
  provenance$production_draw_bytes == sum(runtimes$draws_bytes),
  provenance$canonical_h01_artifacts_unchanged,
  provenance$production_status == "PASS_PENDING_INTEGRATION_VERIFICATION",
  provenance$production_contract_sha256 ==
    unique(audits$production_contract_sha256)
)

protected_before <- read_production(
  "diagnostics/H01_METRIC-010_canonical_H01_before.csv"
)
protected_after <- read_production(
  "diagnostics/H01_METRIC-010_canonical_H01_after.csv"
)
protected_paths <- file.path(root, protected_after$path)
stopifnot(
  nrow(protected_before) > 0L,
  isTRUE(all.equal(protected_before, protected_after, tolerance = 0)),
  nrow(protected_before) == provenance$canonical_h01_artifacts_checked
)

# The production run itself left the canonical tree unchanged. After its
# separate verified installation, superseded ratio-of-integrals files live in
# the integration archive while every non-MDER file remains byte-identical.
integration_root <- file.path(metric_root, "production_integration")
integration_summary <- readr::read_csv(
  file.path(
    integration_root,
    "H01_METRIC-010_production_integration_summary.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
non_mder_baseline <- readr::read_csv(
  file.path(
    integration_root,
    "H01_METRIC-010_non_mder_preintegration_baseline.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
superseded_archive <- readr::read_csv(
  file.path(
    integration_root,
    "H01_METRIC-010_superseded_ratio_of_integrals_archive.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
integration_manifest <- readr::read_csv(
  file.path(
    integration_root,
    "H01_METRIC-010_production_integration_manifest.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
reporting_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H01_reporting_artifacts.csv"),
  show_col_types = FALSE,
  progress = FALSE
)
stage3_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"),
  show_col_types = FALSE,
  progress = FALSE
)
existing_protected <- file.exists(protected_paths)
non_mder_paths <- file.path(root, non_mder_baseline$path)
non_mder_hashes <- vapply(
  non_mder_paths,
  artifact_sha256,
  character(1)
)
non_mder_drift <- non_mder_hashes != non_mder_baseline$sha256
allowed_reporting_drift <- c(
  reporting_manifest$path[
    reporting_manifest$role == "H01 reporting output"
  ],
  stage3_manifest$path[
    stage3_manifest$role == "H01 Stage 3 reporting output"
  ]
)
stopifnot(
  nrow(integration_summary) == 1L,
  integration_summary$integration_status == "PASS_NO_NEW_AUTHOR_GATE",
  integration_summary$successful_refits_per_target == 1000L,
  integration_summary$support_disposition_changes == FALSE,
  setequal(
    protected_after$path[!existing_protected],
    superseded_archive$original_path
  ),
  all(file.exists(file.path(root, superseded_archive$archive_path))),
  all(file.exists(non_mder_paths)),
  all(non_mder_baseline$path[non_mder_drift] %in% allowed_reporting_drift),
  identical(
    unname(non_mder_hashes[!non_mder_drift]),
    unname(non_mder_baseline$sha256[!non_mder_drift])
  ),
  identical(
    unname(vapply(
      file.path(root, superseded_archive$archive_path),
      artifact_sha256,
      character(1)
    )),
    unname(superseded_archive$sha256)
  ),
  all(file.exists(file.path(root, integration_manifest$path))),
  identical(
    unname(vapply(
      file.path(root, integration_manifest$path),
      artifact_sha256,
      character(1)
    )),
    unname(integration_manifest$sha256)
  )
)

message("Checking review language and the non-circular production seal")
review_path <- file.path(
  production_root,
  "H01_METRIC-010_bootstrap_production_review.md"
)
review_text <- paste(readLines(review_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl(production_label, review_text, fixed = TRUE),
  grepl("1,000 successful joint refits", review_text, fixed = TRUE),
  grepl("Production uncertainty summary", review_text, fixed = TRUE),
  grepl("Primary dataset", review_text, fixed = TRUE),
  grepl("Gap-timing-unaware dataset", review_text, fixed = TRUE),
  grepl("Near eye", review_text, fixed = TRUE),
  grepl("Paired/common", review_text, fixed = TRUE),
  !grepl("manuscript_prepared_data", review_text, fixed = TRUE),
  !grepl("all_available", review_text, fixed = TRUE),
  !grepl("paired_common_sample", review_text, fixed = TRUE),
  !grepl(root, review_text, fixed = TRUE),
  !grepl("_build", review_text, fixed = TRUE)
)

input_pins <- read_production(
  "H01_METRIC-010_bootstrap_production_input_pins.csv"
)
stopifnot(
  nrow(input_pins) == 16L,
  length(unique(input_pins$name)) == 16L,
  all(file.exists(file.path(root, input_pins$path))),
  identical(
    unname(vapply(
      file.path(root, input_pins$path),
      artifact_sha256,
      character(1)
    )),
    unname(input_pins$sha256)
  )
)

manifest_path <- file.path(
  production_root,
  "H01_METRIC-010_bootstrap_production_manifest.csv"
)
manifest <- readr::read_csv(
  manifest_path,
  show_col_types = FALSE,
  progress = FALSE
)
manifest_paths <- file.path(root, manifest$path)
stopifnot(
  nrow(manifest) > 0L,
  length(unique(manifest$path)) == nrow(manifest),
  !any(
    manifest$path ==
      paste0(
        "audit/hypotheses/H01/mder_METRIC-010/bootstrap_production/",
        "H01_METRIC-010_bootstrap_production_manifest.csv"
      )
  ),
  all(file.exists(manifest_paths)),
  all(manifest$inference_status == production_label),
  all(manifest$r_version == "4.6.1"),
  dplyr::n_distinct(manifest$production_contract_sha256) == 1L,
  identical(
    unname(vapply(manifest_paths, artifact_sha256, character(1))),
    unname(manifest$sha256)
  ),
  identical(
    as.numeric(file.info(manifest_paths)$size),
    manifest$bytes
  ),
  all(
    c(
      "scripts/hypotheses/H01/run_h01_mder_METRIC010_bootstrap_production.R",
      "tests/hypotheses/H01/test_h01_mder_METRIC010_production.R",
      paste0(
        "audit/hypotheses/H01/mder_METRIC-010/",
        "H01_METRIC-010_production_authorization.md"
      ),
      paste0(
        "audit/hypotheses/H01/mder_METRIC-010/bootstrap_pilot/",
        "H01_METRIC-010_bootstrap_pilot_manifest.csv"
      )
    ) %in%
      manifest$path
  )
)

stopifnot(
  identical(
    artifact_sha256(file.path(
      metric_root,
      "bootstrap_pilot/H01_METRIC-010_bootstrap_pilot_manifest.csv"
    )),
    "deeb5dab9a5b63163f932dfdf4e23cc74ebc6848bd6d4ef8335d921ddd0c8764"
  )
)

message("H01 METRIC-010 isolated production verification passed")
