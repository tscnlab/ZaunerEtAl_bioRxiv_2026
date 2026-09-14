source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/verify_metric_derivation_mder.R")

options(warn = 2)

test_mder_expected_rows <- function() {
  duplicate_ratio <- (4 / 3 + 1439 * 0.5) / 1440
  tibble::tibble(
    site = "TEST",
    Id = sprintf("P%02d", 1:5),
    position = "glasses",
    local_date = as.Date("2026-01-01") + 0:4,
    profile_variant = "pooled",
    expected_real_minutes = c(1440L, 1440L, 1440L, 1440L, 1441L),
    mder = c(0.5, 0.5, NA_real_, NA_real_, duplicate_ratio),
    mder_viable_ratio_minutes = c(1440L, 720L, 719L, 0L, 1440L),
    mder_expected_minutes = 1440L,
    mder_viable_ratio_fraction = c(1, 0.5, 719 / 1440, 0, 1),
    mder_excluded_nonfinite_source_minutes = c(0L, 720L, 721L, 0L, 0L),
    mder_excluded_zero_either_minutes = c(0L, 0L, 0L, 1440L, 0L),
    mder_excluded_zero_medi_minutes = c(0L, 0L, 0L, 1440L, 0L),
    mder_excluded_zero_light_minutes = 0L,
    mder_excluded_both_zero_minutes = 0L,
    mder_excluded_nonfinite_ratio_minutes = 0L,
    mder_minimum_viable_fraction = 0.50,
    mder_passes_viable_ratio_support = c(TRUE, TRUE, FALSE, FALSE, TRUE),
    mder_support_threshold_enforced = TRUE,
    mder_ratio_scaled_or_weighted = FALSE,
    mder_estimable = c(TRUE, TRUE, FALSE, FALSE, TRUE),
    mder_failure_reason = c(
      NA_character_,
      NA_character_,
      "below_viable_ratio_fraction",
      "no_viable_momentary_ratio",
      NA_character_
    )
  )
}

test_mder_coverage <- function(expected) {
  purrr::map_dfr(seq_len(nrow(expected)), function(index) {
    n <- if (index == 5L) 1441L else 1440L
    clock <- if (index == 5L) c(0L, 0:1439) else 0:1439
    medi <- rep(2, n)
    light <- rep(4, n)
    if (index == 2L) light[721:1440] <- NA_real_
    if (index == 3L) light[720:1440] <- NA_real_
    if (index == 4L) medi[] <- 0
    if (index == 5L) {
      medi[1:2] <- c(2, 6)
      light[1:2] <- c(4, 2)
    }
    tibble::tibble(
      site = expected$site[index],
      Id = expected$Id[index],
      position = expected$position[index],
      local_date = expected$local_date[index],
      clock_minute = clock,
      day_eligible = TRUE,
      MEDI_eligible = medi,
      LIGHT_eligible = light
    )
  })
}

test_mder_long <- function(expected) {
  expected |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$profile_variant,
      analysis_unit = "participant_day",
      metric = metric_mder_verifier_metric,
      value = .data$mder,
      units = "dimensionless",
      state_domain = "full_day_positive_paired_minutes",
      estimable = .data$mder_estimable,
      failure_reason = .data$mder_failure_reason,
      ordinary_support = .data$mder_viable_ratio_fraction,
      relevance_support = NA_real_,
      valid_minutes = .data$mder_viable_ratio_minutes,
      expected_minutes = .data$mder_expected_minutes,
      descriptive_nonconfirmatory = FALSE,
      left_censored = FALSE,
      right_censored = FALSE,
      any_censored = FALSE,
      state_domain_complete = NA,
      medi_profile_support = NA_real_,
      light_profile_support = NA_real_,
      minimum_support = .data$mder_minimum_viable_fraction,
      passes_ordinary_support = .data$mder_passes_viable_ratio_support,
      passes_medi_profile_support = NA,
      passes_light_profile_support = NA,
      support_threshold_enforced = TRUE,
      ratio_scaled_or_weighted = FALSE
    )
}

test_mder_metadata <- function(run_label, placement) {
  list(
    run_label = run_label,
    placement = placement,
    mder_support_cutoff = 0.50,
    mder_support_decision_id = "METRIC-010",
    mder_support_status = "author_approved",
    mder_support_candidates = "0.5",
    mder_support_sensitivity_cutoffs = NA_character_,
    mder_support_rule = "positive_finite_one_minute_ratio_fraction_gte_0.50",
    mder_failure_scope = "metric_specific_only_day_retained",
    mder_ratio_definition =
      "arithmetic_mean_of_positive_finite_one_minute_ratios",
    mder_pair_resolution_minutes = 1L,
    mder_zero_pair_rule = "exclude_if_either_channel_zero",
    mder_nonfinite_pair_rule = "exclude_if_source_or_ratio_nonfinite",
    mder_ratio_scaled_or_weighted = FALSE
  )
}

test_mder_fixture <- function() {
  root <- tempfile("nathealth-mder-verifier-")
  dir.create(root, recursive = TRUE)
  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  run_label <- "smoke"
  placement <- "glasses"
  metric_root <- file.path(paths$metrics, "runs", run_label)
  coverage_root <- file.path(paths$coverage, "runs", run_label)
  dir.create(metric_root, recursive = TRUE)
  dir.create(coverage_root, recursive = TRUE)
  expected <- test_mder_expected_rows()
  coverage <- test_mder_coverage(expected)
  coverage_path <- file.path(coverage_root, "light_glasses_coverage.rds")
  saveRDS(coverage, coverage_path, version = 3, compress = "xz")

  long <- test_mder_long(expected)
  support <- long
  output_paths <- metric_mder_verifier_output_paths(metric_root, placement)
  producer <- "scripts/pipeline/build_metric_derivation.R"
  metadata <- test_mder_metadata(run_label, placement)
  records <- list(
    manifest_row(write_rds_artifact(
      expected,
      output_paths[["participant_day_metrics_rds"]],
      producer,
      metadata = c(list(artifact_type = "participant_day_metrics_rds"), metadata)
    )),
    manifest_row(write_csv_artifact(
      expected,
      output_paths[["participant_day_metrics_csv"]],
      producer,
      metadata = c(list(artifact_type = "participant_day_metrics_csv"), metadata)
    )),
    manifest_row(write_csv_artifact(
      long,
      output_paths[["long_metric_values"]],
      producer,
      metadata = c(list(artifact_type = "long_metric_values"), metadata)
    )),
    manifest_row(write_csv_artifact(
      support,
      output_paths[["metric_support_diagnostics"]],
      producer,
      metadata = c(list(artifact_type = "metric_support_diagnostics"), metadata)
    ))
  )
  settings <- tibble::as_tibble(metadata) |>
    dplyr::mutate(eligible_participant_days = nrow(expected))
  settings_path <- file.path(metric_root, "metric_derivation_settings.csv")
  records[[5L]] <- manifest_row(write_csv_artifact(
    settings,
    settings_path,
    producer,
    metadata = list(
      artifact_type = "metric_derivation_settings",
      run_label = run_label
    )
  ))
  manifest_path <- file.path(
    paths$manifests,
    paste0("metric_artifacts_", run_label, ".csv")
  )
  readr::write_csv(dplyr::bind_rows(records), manifest_path, na = "")
  list(
    root = root,
    run_label = run_label,
    metric_root = metric_root,
    coverage_root = coverage_root,
    manifest_path = manifest_path,
    output_paths = output_paths
  )
}

test_mder_refresh_manifest <- function(manifest_path, artifact_path) {
  manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
  normal <- normalizePath(manifest$path, winslash = "/", mustWork = TRUE)
  target <- which(normal == normalizePath(
    artifact_path,
    winslash = "/",
    mustWork = TRUE
  ))
  stopifnot(length(target) == 1L)
  manifest$sha256[target] <- artifact_sha256(artifact_path)
  manifest$bytes[target] <- unname(file.info(artifact_path)$size)
  if (grepl("[.]csv$", artifact_path)) {
    data <- readr::read_csv(artifact_path, show_col_types = FALSE)
    manifest$rows[target] <- nrow(data)
    manifest$columns[target] <- ncol(data)
  }
  readr::write_csv(manifest, manifest_path, na = "")
}

test_mder_verify <- function(fixture) {
  verify_metric_derivation_mder(
    root = fixture$root,
    run_label = fixture$run_label,
    metric_run_root = fixture$metric_root,
    metric_manifest_path = fixture$manifest_path,
    coverage_run_root = fixture$coverage_root
  )
}

test_mder_expect_error <- function(expression, pattern) {
  matched <- tryCatch(
    {
      force(expression)
      FALSE
    },
    error = function(error) {
      grepl(pattern, conditionMessage(error), fixed = TRUE)
    }
  )
  stopifnot(matched)
}

message("Building isolated mean-of-viable-ratios verifier fixture")
fixture <- test_mder_fixture()
on.exit(unlink(fixture$root, recursive = TRUE), add = TRUE)

message("Checking independent minute-level reconstruction")
verified <- test_mder_verify(fixture)
stopifnot(
  identical(verified$status, "PASS"),
  identical(verified$viable_ratio_fraction, 0.50),
  identical(verified$metric, "mder_mean_of_viable_ratios"),
  identical(verified$placements, "glasses"),
  identical(verified$eligible_participant_days, 5L),
  identical(verified$estimable_mder_days, 3L),
  identical(verified$excluded_mder_days, 2L),
  identical(verified$relevant_manifest_rows, 5L),
  verified$immutable_inputs,
  verified$ratio_recalculated
)

message("Checking semantic value corruption after manifest refresh")
corrupt <- test_mder_fixture()
daily <- readRDS(corrupt$output_paths[["participant_day_metrics_rds"]])
daily$mder[1L] <- daily$mder[1L] + 0.1
saveRDS(
  daily,
  corrupt$output_paths[["participant_day_metrics_rds"]],
  version = 3,
  compress = "xz"
)
test_mder_refresh_manifest(
  corrupt$manifest_path,
  corrupt$output_paths[["participant_day_metrics_rds"]]
)
test_mder_expect_error(
  test_mder_verify(corrupt),
  "participant-day MDER output"
)
unlink(corrupt$root, recursive = TRUE)

message("Checking viable-support corruption after manifest refresh")
corrupt <- test_mder_fixture()
support <- readr::read_csv(
  corrupt$output_paths[["metric_support_diagnostics"]],
  show_col_types = FALSE
)
support$ordinary_support[1L] <- 0.99
readr::write_csv(
  support,
  corrupt$output_paths[["metric_support_diagnostics"]],
  na = ""
)
test_mder_refresh_manifest(
  corrupt$manifest_path,
  corrupt$output_paths[["metric_support_diagnostics"]]
)
test_mder_expect_error(
  test_mder_verify(corrupt),
  "MDER support output"
)
unlink(corrupt$root, recursive = TRUE)

message("Independent Preparation 04 MDER verifier tests passed")
