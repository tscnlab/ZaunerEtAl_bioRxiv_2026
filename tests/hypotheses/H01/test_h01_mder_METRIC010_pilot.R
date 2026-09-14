# Verify the bounded H01 METRIC-010 MDER bootstrap pilot.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
base::source(file.path(root, "scripts/pipeline/paths_io.R"))
base::source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

pilot_label <- "PILOT - NOT FOR INFERENCE OR MANUSCRIPT REPORTING"
metric_id <- "mder_mean_of_viable_ratios"
metric_root <- file.path(
  root,
  "audit/hypotheses/H01/mder_METRIC-010"
)
pilot_root <- file.path(metric_root, "bootstrap_pilot")
runner_path <- file.path(
  root,
  "scripts/hypotheses/H01/run_h01_mder_METRIC010_bootstrap_pilot.R"
)
test_path <- file.path(
  root,
  "tests/hypotheses/H01/test_h01_mder_METRIC010_pilot.R"
)
authority_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/",
    "report018_h01_metric010_point_baseline_acceptance_and_pilot_",
    "authority.md"
  )
)
authority_manifest_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/",
    "report018_h01_metric010_point_baseline_acceptance_and_pilot_",
    "authority_manifest.csv"
  )
)
acceptance_path <- file.path(
  metric_root,
  "H01_METRIC-010_point_baseline_acceptance.md"
)

message("Checking the controlling pilot authority and executable source")
stopifnot(
  file.exists(runner_path),
  file.exists(test_path),
  file.exists(authority_path),
  file.exists(authority_manifest_path),
  file.exists(acceptance_path),
  identical(
    artifact_sha256(authority_path),
    "fb9a333926928aa1d48732133ceaf5a5f0f55a5794842ed23d3ee9732fcdc536"
  ),
  identical(
    artifact_sha256(authority_manifest_path),
    "0daae7170ca077e241e687ca39901d481f74f6af234ec3fab05da2febe0ae102"
  ),
  identical(
    artifact_sha256(acceptance_path),
    "e0681c3488e75059fd5721d3c743843a31f258f55fe680a8d2831d3423c4b7b6"
  )
)
invisible(parse(file = runner_path))
authority_text <- paste(
  readLines(authority_path, warn = FALSE),
  collapse = "\n"
)
acceptance_text <- paste(
  readLines(acceptance_path, warn = FALSE),
  collapse = "\n"
)
stopifnot(
  grepl(pilot_label, authority_text, fixed = TRUE),
  grepl(pilot_label, acceptance_text, fixed = TRUE),
  grepl("50-successful-refit", authority_text, fixed = TRUE),
  grepl("does not authorize", acceptance_text, fixed = TRUE),
  !grepl("PILOT \u2014 NOT", acceptance_text, fixed = TRUE)
)

message("Checking the current-input bridge")
bridge_path <- file.path(
  pilot_root,
  "diagnostics/H01_METRIC-010_current_input_bridge.csv"
)
bridge <- readr::read_csv(
  bridge_path,
  show_col_types = FALSE,
  progress = FALSE
)
expected_samples <- tibble::tribble(
  ~run_id,
  ~current_rows,
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
)
observed_samples <- bridge |>
  dplyr::select(run_id, current_rows, participants, sites) |>
  dplyr::arrange(run_id)
expected_samples <- expected_samples |>
  dplyr::arrange(run_id)
stopifnot(
  nrow(bridge) == 8L,
  isTRUE(all.equal(observed_samples, expected_samples, tolerance = 0)),
  all(bridge$current_rows == bridge$sealed_rows),
  all(bridge$participant_days == bridge$current_rows),
  all(bridge$observations == bridge$current_rows),
  all(bridge$scientific_columns_identical),
  all(bridge$model_specification_identical),
  all(bridge$row_keys_identical),
  all(bridge$response_values_identical),
  all(nchar(bridge$current_scientific_frame_sha256) == 64L),
  all(nchar(bridge$sealed_frame_file_sha256) == 64L),
  all(nchar(bridge$sealed_bundle_file_sha256) == 64L),
  all(
    bridge$container_difference_classification[
      bridge$data_scenario_id == "main"
    ] ==
      "NON_ANALYTICAL_METRIC_SETTINGS_ATTRIBUTE_ONLY"
  ),
  all(
    bridge$container_difference_classification[
      bridge$data_scenario_id == "manuscript_prepared_data"
    ] ==
      "NONE"
  )
)

message("Checking pilot counts, seeds, failures, warnings, and checkpoints")
audit_path <- file.path(
  pilot_root,
  "diagnostics/H01_METRIC-010_bootstrap_pilot_audit.csv"
)
failure_path <- file.path(
  pilot_root,
  "diagnostics/H01_METRIC-010_bootstrap_pilot_failures.csv"
)
runtime_path <- file.path(
  pilot_root,
  "diagnostics/H01_METRIC-010_bootstrap_pilot_runtime.csv"
)
provenance_path <- file.path(
  pilot_root,
  "diagnostics/H01_METRIC-010_bootstrap_pilot_provenance.csv"
)
audits <- readr::read_csv(
  audit_path,
  show_col_types = FALSE,
  progress = FALSE
)
failures <- readr::read_csv(
  failure_path,
  show_col_types = FALSE,
  progress = FALSE
)
runtimes <- readr::read_csv(
  runtime_path,
  show_col_types = FALSE,
  progress = FALSE
)
provenance <- readr::read_csv(
  provenance_path,
  show_col_types = FALSE,
  progress = FALSE
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
    ) +
      10000000L
  },
  integer(1)
)
observed_audits <- audits |>
  dplyr::arrange(run_id)
stopifnot(
  nrow(audits) == 8L,
  setequal(audits$run_id, registry$run_id),
  all(audits$metric_id == metric_id),
  all(audits$inference_status == pilot_label),
  all(audits$attempted_refits == 75L),
  all(audits$successful_refits >= 50L),
  all(audits$used_refits == 50L),
  all(audits$status == "PASS"),
  all(audits$interval_method == "parametric_percentile"),
  isTRUE(all.equal(observed_audits$seed, expected_seeds, tolerance = 0)),
  nrow(failures) == sum(audits$failed_refits),
  all(runtimes$successful_draws == 50L),
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
    nrow(draws) == 50L,
    dplyr::n_distinct(draws$bootstrap_replicate) == 50L,
    all(draws$status == "PASS"),
    identical(
      checkpoint$target_contract_sha256,
      runtimes$target_contract_sha256[[index]]
    ),
    identical(checkpoint$draws_sha256, runtimes$draws_sha256[[index]]),
    checkpoint$pilot$audit$used_refits == 50L,
    checkpoint$pilot$audit$status == "PASS"
  )
}

stopifnot(
  nrow(provenance) == 1L,
  provenance$inference_status == pilot_label,
  provenance$r_version == "4.6.1",
  provenance$successful_refits_per_target == 50L,
  provenance$planned_targets == 8L,
  provenance$completed_targets == 8L,
  provenance$total_attempted_refits == sum(audits$attempted_refits),
  provenance$total_successful_refits == sum(audits$successful_refits),
  provenance$total_used_refits == 400L,
  provenance$total_failed_refits == sum(audits$failed_refits),
  provenance$total_warning_refits == sum(audits$warning_refits),
  provenance$total_wall_seconds == sum(runtimes$wall_seconds),
  provenance$projected_production_wall_seconds > 0,
  provenance$projected_production_low_seconds <
    provenance$projected_production_wall_seconds,
  provenance$projected_production_high_seconds >
    provenance$projected_production_wall_seconds,
  provenance$pilot_draw_bytes == sum(runtimes$draws_bytes),
  provenance$projected_production_draw_bytes ==
    provenance$pilot_draw_bytes * 20,
  provenance$canonical_h01_artifacts_unchanged,
  provenance$pilot_status == "PASS_AWAITING_AUTHOR_PRODUCTION_APPROVAL"
)

message("Checking pilot uncertainty and multiplicity previews")
summary_path <- file.path(
  pilot_root,
  "tables/H01_METRIC-010_bootstrap_pilot_r2_summaries.csv"
)
preview_source_path <- file.path(
  pilot_root,
  "source_data/H01_METRIC-010_bootstrap_pilot_preview_source.csv"
)
preview_table_path <- file.path(
  pilot_root,
  "tables/H01_METRIC-010_bootstrap_pilot_preview_table.csv"
)
multiplicity_path <- file.path(
  pilot_root,
  "tables/H01_METRIC-010_bootstrap_pilot_multiplicity_preview.csv"
)
summaries <- readr::read_csv(
  summary_path,
  show_col_types = FALSE,
  progress = FALSE
)
preview_source <- readr::read_csv(
  preview_source_path,
  show_col_types = FALSE,
  progress = FALSE
)
preview_table <- readr::read_csv(
  preview_table_path,
  show_col_types = FALSE,
  progress = FALSE
)
multiplicity <- readr::read_csv(
  multiplicity_path,
  show_col_types = FALSE,
  progress = FALSE
)
measures <- c(
  "marginal_r2",
  "conditional_r2",
  "participant_associated_share",
  "site_part_r2",
  "photoperiod_part_r2",
  "latitude_model_marginal_r2",
  "latitude_part_r2",
  "unrepresented_share"
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
  dplyr::select(run_id, dplyr::all_of(measures)) |>
  tidyr::pivot_longer(
    cols = dplyr::all_of(measures),
    names_to = "measure",
    values_to = "expected_estimate"
  )
summary_point_check <- summaries |>
  dplyr::select(run_id, measure, estimate) |>
  dplyr::left_join(expected_point, by = c("run_id", "measure"))
stopifnot(
  nrow(summaries) == 64L,
  setequal(summaries$measure, measures),
  all(summaries$metric_id == metric_id),
  all(summaries$inference_status == pilot_label),
  all(summaries$bootstrap_successful_used == 50L),
  all(summaries$interval_method == "joint_parametric_percentile"),
  all(summaries$status == "PASS"),
  all(is.finite(summaries$conf_low)),
  all(is.finite(summaries$conf_high)),
  isTRUE(all.equal(
    summary_point_check$estimate,
    summary_point_check$expected_estimate,
    tolerance = 0
  )),
  nrow(preview_source) == 48L,
  dplyr::n_distinct(preview_source$run_id) == 8L,
  dplyr::n_distinct(preview_source$component) == 6L,
  nrow(preview_table) == 8L,
  all(preview_table$Status == pilot_label),
  setequal(
    preview_table$Dataset,
    c("Primary dataset", "Gap-timing-unaware dataset")
  ),
  setequal(preview_table$Placement, c("Near eye", "Chest")),
  setequal(preview_table$Sample, c("All available", "Paired/common")),
  nrow(multiplicity) == 5L,
  sum(multiplicity$new_metric_id == metric_id) == 4L,
  sum(
    multiplicity$support_changed & multiplicity$new_metric_id != metric_id
  ) ==
    1L,
  all(multiplicity$inference_status == pilot_label)
)

figure_path <- file.path(
  pilot_root,
  "figures/H01_METRIC-010_bootstrap_pilot_preview.png"
)
review_path <- file.path(
  pilot_root,
  "H01_METRIC-010_bootstrap_pilot_review.md"
)
review_text <- paste(readLines(review_path, warn = FALSE), collapse = "\n")
stopifnot(
  file.exists(figure_path),
  file.info(figure_path)$size > 0,
  grepl(pilot_label, review_text, fixed = TRUE),
  grepl(
    "](figures/H01_METRIC-010_bootstrap_pilot_preview.png)",
    review_text,
    fixed = TRUE
  ),
  grepl("Raw p (rule: p < 0.050)", review_text, fixed = TRUE),
  grepl(
    "FDR-adjusted p (rule: q < 0.050)",
    review_text,
    fixed = TRUE
  ),
  grepl("&lt;0.001", review_text, fixed = TRUE),
  !grepl("0.0000000", review_text, fixed = TRUE),
  grepl(
    "awaiting explicit author production approval",
    review_text,
    fixed = TRUE
  ),
  !grepl(root, review_text, fixed = TRUE),
  !grepl("_build", review_text, fixed = TRUE),
  !grepl("manuscript_prepared_data", review_text, fixed = TRUE),
  !grepl("all_available", review_text, fixed = TRUE),
  !grepl("paired_common_sample", review_text, fixed = TRUE),
  !grepl("PILOT \u2014 NOT", review_text, fixed = TRUE)
)

message("Checking canonical H01 preservation and the non-circular pilot seal")
protected_before <- readr::read_csv(
  file.path(
    pilot_root,
    "diagnostics/H01_METRIC-010_canonical_H01_before.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
protected_after <- readr::read_csv(
  file.path(
    pilot_root,
    "diagnostics/H01_METRIC-010_canonical_H01_after.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
stopifnot(
  nrow(protected_before) > 0L,
  isTRUE(all.equal(protected_before, protected_after, tolerance = 0)),
  nrow(protected_before) == provenance$canonical_h01_artifacts_checked,
  all(file.exists(file.path(root, protected_after$path))),
  identical(
    unname(vapply(
      file.path(root, protected_after$path),
      artifact_sha256,
      character(1)
    )),
    unname(protected_after$sha256)
  )
)

input_pins <- readr::read_csv(
  file.path(pilot_root, "H01_METRIC-010_bootstrap_pilot_input_pins.csv"),
  show_col_types = FALSE,
  progress = FALSE
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
  pilot_root,
  "H01_METRIC-010_bootstrap_pilot_manifest.csv"
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
        "audit/hypotheses/H01/mder_METRIC-010/bootstrap_pilot/",
        "H01_METRIC-010_bootstrap_pilot_manifest.csv"
      )
  ),
  all(file.exists(manifest_paths)),
  all(manifest$inference_status == pilot_label),
  all(manifest$r_version == "4.6.1"),
  dplyr::n_distinct(manifest$pilot_contract_sha256) == 1L,
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
      "scripts/hypotheses/H01/run_h01_mder_METRIC010_bootstrap_pilot.R",
      "tests/hypotheses/H01/test_h01_mder_METRIC010_pilot.R",
      "scripts/pipeline/p_value_display.R",
      paste0(
        "audit/hypotheses/H01/mder_METRIC-010/",
        "H01_METRIC-010_point_baseline_acceptance.md"
      )
    ) %in%
      manifest$path
  )
)

stopifnot(!dir.exists(file.path(metric_root, "bootstrap_production")))

message("H01 METRIC-010 bootstrap pilot verification passed")
