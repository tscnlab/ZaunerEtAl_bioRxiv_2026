source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/verify_metric_derivation_mder.R")

options(warn = 2)

test_metric_mder_fixture_rows <- function() {
  supports <- tibble::tribble(
    ~scenario,
    ~ordinary,
    ~medi,
    ~light,
    ~has_pair,
    ~positive_light,
    "retained",
    0.90,
    0.90,
    0.90,
    TRUE,
    TRUE,
    "inclusive_80",
    0.80,
    0.80,
    0.80,
    TRUE,
    TRUE,
    "below_ordinary",
    0.75,
    0.90,
    0.90,
    TRUE,
    TRUE,
    "below_medi",
    0.85,
    0.75,
    0.90,
    TRUE,
    TRUE,
    "below_light",
    0.85,
    0.85,
    0.75,
    TRUE,
    TRUE,
    "no_pair",
    0.00,
    0.00,
    0.00,
    FALSE,
    FALSE,
    "nonpositive_light",
    0.90,
    0.90,
    0.90,
    TRUE,
    FALSE
  ) |>
    dplyr::mutate(
      site = "TEST",
      Id = paste0("P", sprintf("%02d", dplyr::row_number())),
      position = "glasses",
      local_date = as.Date("2026-01-01") + dplyr::row_number() - 1L,
      expected_true_minutes = 1440L,
      paired_finite_medi_light_minutes = as.integer(
        round(.data$ordinary * .data$expected_true_minutes)
      ),
      retained_at_0_70 = .data$has_pair &
        .data$positive_light &
        .data$ordinary >= 0.70 &
        .data$medi >= 0.70 &
        .data$light >= 0.70,
      retained_at_0_80 = .data$has_pair &
        .data$positive_light &
        .data$ordinary >= 0.80 &
        .data$medi >= 0.80 &
        .data$light >= 0.80,
      retained_at_0_90 = .data$has_pair &
        .data$positive_light &
        .data$ordinary >= 0.90 &
        .data$medi >= 0.90 &
        .data$light >= 0.90,
      gate_failure = dplyr::case_when(
        !.data$has_pair ~ "no_paired_observation",
        !.data$positive_light ~ "nonpositive_paired_light_integral",
        TRUE ~ NA_character_
      ),
      metric_failure = dplyr::case_when(
        !.data$has_pair ~ "no_paired_observation",
        !.data$positive_light ~ "nonpositive_paired_light_integral",
        .data$ordinary < 0.80 ~ "below_ordinary_paired_support",
        .data$medi < 0.80 ~ "below_medi_profile_support",
        .data$light < 0.80 ~ "below_light_profile_support",
        TRUE ~ NA_character_
      ),
      mder = dplyr::if_else(.data$retained_at_0_80, 0.50, NA_real_)
    )
  supports
}

test_metric_mder_gate <- function(rows, run_label) {
  rows |>
    dplyr::transmute(
      run_label = run_label,
      status = "AUTHOR_GATE_INPUT_NOT_A_SELECTED_RULE",
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      timezone = "UTC",
      profile_variant = "pooled",
      .data$expected_true_minutes,
      finite_medi_minutes = .data$paired_finite_medi_light_minutes,
      finite_light_minutes = .data$paired_finite_medi_light_minutes,
      .data$paired_finite_medi_light_minutes,
      ordinary_paired_coverage = .data$ordinary,
      medi_paired_profile_coverage = .data$medi,
      light_paired_profile_coverage = .data$light,
      paired_light_integral_lx_h = dplyr::if_else(
        .data$positive_light,
        100,
        dplyr::if_else(.data$has_pair, 0, NA_real_)
      ),
      positive_light_integral = .data$positive_light,
      has_paired_observation = .data$has_pair,
      .data$retained_at_0_70,
      .data$retained_at_0_80,
      .data$retained_at_0_90,
      failure_reason = .data$gate_failure,
      support_role = "author_gate_input_only",
      ratio_value_calculated = FALSE,
      ratio_scaled_or_weighted = FALSE
    )
}

test_metric_mder_daily <- function(rows) {
  rows |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      profile_variant = "pooled",
      expected_real_minutes = .data$expected_true_minutes,
      mder = .data$mder,
      mder_ordinary_paired_coverage = .data$ordinary,
      mder_medi_profile_coverage = .data$medi,
      mder_light_profile_coverage = .data$light,
      mder_minimum_support = 0.80,
      mder_passes_ordinary_paired_support = .data$ordinary >= 0.80,
      mder_passes_medi_profile_support = .data$medi >= 0.80,
      mder_passes_light_profile_support = .data$light >= 0.80,
      mder_support_threshold_enforced = TRUE,
      mder_ratio_scaled_or_weighted = FALSE,
      mder_estimable = .data$retained_at_0_80,
      mder_failure_reason = .data$metric_failure
    )
}

test_metric_mder_long <- function(rows) {
  rows |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      profile_variant = "pooled",
      analysis_unit = "participant_day",
      metric = "mder_ratio_of_integrals",
      value = .data$mder,
      units = "dimensionless",
      state_domain = "full_day_paired_channels",
      estimable = .data$retained_at_0_80,
      failure_reason = .data$metric_failure,
      ordinary_support = .data$ordinary,
      relevance_support = pmin(.data$medi, .data$light),
      valid_minutes = .data$paired_finite_medi_light_minutes,
      expected_minutes = .data$expected_true_minutes,
      descriptive_nonconfirmatory = FALSE,
      left_censored = FALSE,
      right_censored = FALSE,
      any_censored = FALSE,
      state_domain_complete = NA,
      medi_profile_support = .data$medi,
      light_profile_support = .data$light,
      minimum_support = 0.80,
      passes_ordinary_support = .data$ordinary >= 0.80,
      passes_medi_profile_support = .data$medi >= 0.80,
      passes_light_profile_support = .data$light >= 0.80,
      support_threshold_enforced = TRUE,
      ratio_scaled_or_weighted = FALSE
    )
}

test_metric_mder_support <- function(long) {
  long |>
    dplyr::select(
      dplyr::all_of(
        metric_mder_verifier_required_support_columns()
      )
    )
}

test_metric_mder_metadata <- function(run_label, placement) {
  list(
    run_label = run_label,
    placement = placement,
    profile_variant = "pooled",
    mder_support_cutoff = 0.80,
    mder_support_decision_id = "METRIC-003",
    mder_support_status = "author_approved",
    mder_support_candidates = "0.7|0.8|0.9",
    mder_support_sensitivity_cutoffs = "0.7|0.9",
    mder_support_rule = "ordinary_and_both_fixed_signal_profile_supports_gte_cutoff",
    mder_failure_scope = "metric_specific_only_day_retained",
    mder_ratio_definition = "ratio_of_observed_paired_integrals",
    mder_ratio_scaled_or_weighted = FALSE
  )
}

test_metric_mder_fixture <- function() {
  root <- tempfile("nathealth-metric-mder-verifier-")
  dir.create(root, recursive = TRUE)
  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  run_label <- "smoke"
  placement <- "glasses"
  metric_root <- file.path(paths$metrics, "runs", run_label)
  gate_root <- file.path(
    paths$diagnostics,
    "runs",
    run_label,
    "mder_support_gate"
  )
  dir.create(metric_root, recursive = TRUE)
  dir.create(gate_root, recursive = TRUE)

  rows <- test_metric_mder_fixture_rows()
  gate <- test_metric_mder_gate(rows, run_label)
  daily <- test_metric_mder_daily(rows)
  long <- test_metric_mder_long(rows)
  support <- test_metric_mder_support(long)
  settings <- tibble::as_tibble(test_metric_mder_metadata(
    run_label,
    placement
  )) |>
    dplyr::mutate(
      eligible_participant_days = nrow(daily)
    )

  gate_path <- file.path(gate_root, "mder_support_gate_daily.csv")
  gate_record <- manifest_row(write_csv_artifact(
    gate,
    gate_path,
    producer = "scripts/pipeline/build_mder_support_gate.R",
    metadata = list(
      artifact_type = "mder_support_gate_daily",
      run_label = run_label,
      status = "diagnostic_only_not_final",
      input_hashes = paste0("fixture=", strrep("a", 64L)),
      candidate_cutoffs = "0.7|0.8|0.9",
      ratio_value_calculated = FALSE,
      ratio_scaled_or_weighted = FALSE
    )
  ))
  gate_manifest_path <- file.path(
    paths$manifests,
    paste0("mder_support_gate_artifacts_", run_label, ".csv")
  )
  readr::write_csv(gate_record, gate_manifest_path, na = "")

  output_paths <- metric_mder_verifier_output_paths(
    metric_root,
    placement
  )
  metadata <- test_metric_mder_metadata(run_label, placement)
  records <- list(
    manifest_row(write_rds_artifact(
      daily,
      output_paths[["participant_day_metrics_rds"]],
      producer = "scripts/pipeline/build_metric_derivation.R",
      metadata = c(
        list(artifact_type = "participant_day_metrics_rds"),
        metadata
      )
    )),
    manifest_row(write_csv_artifact(
      daily,
      output_paths[["participant_day_metrics_csv"]],
      producer = "scripts/pipeline/build_metric_derivation.R",
      metadata = c(
        list(artifact_type = "participant_day_metrics_csv"),
        metadata
      )
    )),
    manifest_row(write_csv_artifact(
      long,
      output_paths[["long_metric_values"]],
      producer = "scripts/pipeline/build_metric_derivation.R",
      metadata = c(
        list(artifact_type = "long_metric_values"),
        metadata
      )
    )),
    manifest_row(write_csv_artifact(
      support,
      output_paths[["metric_support_diagnostics"]],
      producer = "scripts/pipeline/build_metric_derivation.R",
      metadata = c(
        list(artifact_type = "metric_support_diagnostics"),
        metadata
      )
    ))
  )
  settings_path <- file.path(metric_root, "metric_derivation_settings.csv")
  records[[length(records) + 1L]] <- manifest_row(write_csv_artifact(
    settings,
    settings_path,
    producer = "scripts/pipeline/build_metric_derivation.R",
    metadata = list(
      artifact_type = "metric_derivation_settings",
      run_label = run_label
    )
  ))
  metric_manifest <- dplyr::bind_rows(records)
  metric_manifest_path <- file.path(
    paths$manifests,
    paste0("metric_artifacts_", run_label, ".csv")
  )
  readr::write_csv(metric_manifest, metric_manifest_path, na = "")

  list(
    root = root,
    run_label = run_label,
    placement = placement,
    metric_root = metric_root,
    gate_root = gate_root,
    gate_path = gate_path,
    gate_manifest_path = gate_manifest_path,
    output_paths = output_paths,
    settings_path = settings_path,
    metric_manifest_path = metric_manifest_path
  )
}

test_metric_mder_expect_error <- function(expression, pattern) {
  observed <- tryCatch(
    {
      force(expression)
      ""
    },
    error = function(error) conditionMessage(error)
  )
  stopifnot(
    nzchar(observed),
    grepl(pattern, observed, fixed = TRUE)
  )
  invisible(observed)
}

test_metric_mder_refresh_manifest <- function(
  manifest_path,
  artifact_path
) {
  manifest <- metric_mder_verifier_read_csv(manifest_path)
  normalized_path <- normalizePath(
    artifact_path,
    winslash = "/",
    mustWork = TRUE
  )
  rows <- normalizePath(
    manifest$path,
    winslash = "/",
    mustWork = TRUE
  ) ==
    normalized_path
  stopifnot(sum(rows) == 1L)
  manifest$sha256[rows] <- artifact_sha256(artifact_path)
  manifest$bytes[rows] <- unname(file.info(artifact_path)$size)
  if (grepl("[.]csv$", artifact_path)) {
    artifact <- metric_mder_verifier_read_csv(artifact_path)
    manifest$rows[rows] <- nrow(artifact)
    manifest$columns[rows] <- ncol(artifact)
  }
  readr::write_csv(manifest, manifest_path, na = "")
  invisible(manifest_path)
}

test_metric_mder_verify <- function(fixture) {
  verify_metric_derivation_mder(
    root = fixture$root,
    run_label = fixture$run_label,
    metric_run_root = fixture$metric_root,
    metric_manifest_path = fixture$metric_manifest_path,
    gate_run_root = fixture$gate_root,
    gate_manifest_path = fixture$gate_manifest_path
  )
}

message("Building isolated Preparation 04 MDER verifier fixture")
fixture <- test_metric_mder_fixture()
on.exit(unlink(fixture$root, recursive = TRUE), add = TRUE)

message("Checking independent gate-to-wide-to-long verification")
verified <- test_metric_mder_verify(fixture)
stopifnot(
  identical(verified$status, "PASS"),
  identical(verified$cutoff, 0.80),
  identical(verified$placements, "glasses"),
  identical(verified$eligible_participant_days, 7L),
  identical(verified$retained_at_0_80, 2L),
  identical(verified$excluded_at_0_80, 5L),
  identical(verified$relevant_manifest_rows, 5L),
  verified$immutable_inputs,
  !verified$ratio_recalculated
)

message("Checking manifest byte corruption")
corrupt_manifest_fixture <- test_metric_mder_fixture()
corrupt_manifest <- metric_mder_verifier_read_csv(
  corrupt_manifest_fixture$metric_manifest_path
)
corrupt_manifest$bytes[[1L]] <- corrupt_manifest$bytes[[1L]] + 1
readr::write_csv(
  corrupt_manifest,
  corrupt_manifest_fixture$metric_manifest_path,
  na = ""
)
test_metric_mder_expect_error(
  test_metric_mder_verify(corrupt_manifest_fixture),
  "manifest hash/bytes disagree"
)
unlink(corrupt_manifest_fixture$root, recursive = TRUE)

message("Checking semantic support corruption after refreshed metadata")
support_fixture <- test_metric_mder_fixture()
support <- metric_mder_verifier_read_csv(
  support_fixture$output_paths[["metric_support_diagnostics"]]
)
support$ordinary_support[[1L]] <- support$ordinary_support[[1L]] - 0.01
readr::write_csv(
  support,
  support_fixture$output_paths[["metric_support_diagnostics"]],
  na = ""
)
test_metric_mder_refresh_manifest(
  support_fixture$metric_manifest_path,
  support_fixture$output_paths[["metric_support_diagnostics"]]
)
test_metric_mder_expect_error(
  test_metric_mder_verify(support_fixture),
  "MDER support output"
)
unlink(support_fixture$root, recursive = TRUE)

message("Checking wide/long value corruption after refreshed metadata")
long_fixture <- test_metric_mder_fixture()
long <- metric_mder_verifier_read_csv(
  long_fixture$output_paths[["long_metric_values"]]
)
long$value[[1L]] <- long$value[[1L]] + 0.10
readr::write_csv(
  long,
  long_fixture$output_paths[["long_metric_values"]],
  na = ""
)
test_metric_mder_refresh_manifest(
  long_fixture$metric_manifest_path,
  long_fixture$output_paths[["long_metric_values"]]
)
test_metric_mder_expect_error(
  test_metric_mder_verify(long_fixture),
  "wide/long MDER output"
)
unlink(long_fixture$root, recursive = TRUE)

message("Checking duplicate long MDER rows")
duplicate_fixture <- test_metric_mder_fixture()
long <- metric_mder_verifier_read_csv(
  duplicate_fixture$output_paths[["long_metric_values"]]
)
long <- dplyr::bind_rows(long, long[1L, , drop = FALSE])
readr::write_csv(
  long,
  duplicate_fixture$output_paths[["long_metric_values"]],
  na = ""
)
test_metric_mder_refresh_manifest(
  duplicate_fixture$metric_manifest_path,
  duplicate_fixture$output_paths[["long_metric_values"]]
)
test_metric_mder_expect_error(
  test_metric_mder_verify(duplicate_fixture),
  "duplicated row"
)
unlink(duplicate_fixture$root, recursive = TRUE)

message("Checking exact failure-priority corruption")
failure_fixture <- test_metric_mder_fixture()
daily_csv <- metric_mder_verifier_read_csv(
  failure_fixture$output_paths[["participant_day_metrics_csv"]]
)
daily_rds <- readRDS(
  failure_fixture$output_paths[["participant_day_metrics_rds"]]
)
target <- which(
  daily_csv$mder_failure_reason == "below_ordinary_paired_support"
)
stopifnot(length(target) == 1L)
daily_csv$mder_failure_reason[target] <- "below_medi_profile_support"
daily_rds$mder_failure_reason[target] <- "below_medi_profile_support"
readr::write_csv(
  daily_csv,
  failure_fixture$output_paths[["participant_day_metrics_csv"]],
  na = ""
)
saveRDS(
  daily_rds,
  failure_fixture$output_paths[["participant_day_metrics_rds"]],
  version = 3,
  compress = "xz"
)
test_metric_mder_refresh_manifest(
  failure_fixture$metric_manifest_path,
  failure_fixture$output_paths[["participant_day_metrics_csv"]]
)
test_metric_mder_refresh_manifest(
  failure_fixture$metric_manifest_path,
  failure_fixture$output_paths[["participant_day_metrics_rds"]]
)
test_metric_mder_expect_error(
  test_metric_mder_verify(failure_fixture),
  "participant-day MDER output"
)
unlink(failure_fixture$root, recursive = TRUE)

message("Checking day-retention mismatch")
retention_fixture <- test_metric_mder_fixture()
gate <- metric_mder_verifier_read_csv(retention_fixture$gate_path)
gate <- gate[-1L, , drop = FALSE]
readr::write_csv(gate, retention_fixture$gate_path, na = "")
test_metric_mder_refresh_manifest(
  retention_fixture$gate_manifest_path,
  retention_fixture$gate_path
)
settings <- metric_mder_verifier_read_csv(
  retention_fixture$settings_path
)
settings$eligible_participant_days <- nrow(gate)
readr::write_csv(
  settings,
  retention_fixture$settings_path,
  na = ""
)
test_metric_mder_refresh_manifest(
  retention_fixture$metric_manifest_path,
  retention_fixture$settings_path
)
test_metric_mder_expect_error(
  test_metric_mder_verify(retention_fixture),
  "does not retain exactly one row for every eligible support-gate day"
)
unlink(retention_fixture$root, recursive = TRUE)

message("Independent Preparation 04 MDER verifier tests passed")
