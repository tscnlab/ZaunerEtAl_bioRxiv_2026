# Exercise the shared H01 Gaussian and Tweedie model implementation.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))

registry <- h01_metric_registry()
main <- readRDS(file.path(root, "artifacts/06_model_data/H01.rds"))
manuscript_prepared <- readRDS(file.path(
  root,
  paste0(
    "artifacts/06_model_data/H01/scenarios/",
    "manuscript_prepared_data/H01.rds"
  )
))

message("Testing response transformations")
probability <- c(0.1, 0.5, 0.9)
stopifnot(all.equal(
  h01_inverse_response(
    h01_transform_response(probability, "logit"),
    "logit",
    "gaussian"
  ),
  probability
))
positive <- c(0, 0.5, 100)
stopifnot(all.equal(
  h01_inverse_response(
    h01_transform_response(positive, "log10_offset_0.1"),
    "log10_offset_0.1",
    "gaussian"
  ),
  positive,
  tolerance = 1e-10
))
clock <- c(60, 720, 960, 1020, 1380)
midnight_primary <- h01_transform_response(
  clock,
  "clock_hours_midnight_after_16"
)
midnight_noon <- h01_transform_response(
  clock,
  "clock_hours_midnight_after_12"
)
stopifnot(
  identical(midnight_primary, c(1, 12, 16, -7, -1)),
  identical(midnight_noon, c(1, 12, -8, -7, -1)),
  h01_inverse_response(
    midnight_primary,
    "clock_hours_midnight_after_16",
    "gaussian"
  ) == clock / 60
)
clock_frame <- data.frame(
  value = clock,
  response_value = clock / 60,
  metric_support_expected_minutes = NA_real_
)
clock_model <- stats::lm(response_value ~ 1, data = clock_frame)
clock_spec <- registry[
  registry$metric_id == "m10_midpoint",
  ,
  drop = FALSE
]
clock_bounds <- h01_prediction_bounds(
  clock_model,
  clock_frame,
  clock_spec
)
stopifnot(
  clock_bounds$observed_below_bound_n == 0L,
  clock_bounds$observed_above_bound_n == 0L
)

message("Testing the calendar-day pre-sleep audit threshold")
pre_sleep_spec <- registry[
  registry$metric_id == "duration_below_10_pre_sleep",
  ,
  drop = FALSE
]
pre_sleep_frame <- data.frame(
  value = c(0, 3.5, 5.9),
  response_value = log(c(0, 3.5, 5.9) + 0.1),
  metric_support_expected_minutes = c(180, 360, 360)
)
pre_sleep_model <- stats::lm(
  response_value ~ 1,
  data = pre_sleep_frame
)
pre_sleep_bounds <- h01_prediction_bounds(
  pre_sleep_model,
  pre_sleep_frame,
  pre_sleep_spec
)
stopifnot(
  pre_sleep_bounds$observed_above_bound_n == 0L,
  pre_sleep_bounds$audit_upper_threshold == 6,
  pre_sleep_bounds$observed_above_audit_threshold_n == 0L,
  pre_sleep_bounds$audit_threshold_status == "PASS"
)
pre_sleep_above_audit <- pre_sleep_frame
pre_sleep_above_audit$value[[3L]] <- 6.1
pre_sleep_above_audit$response_value[[3L]] <- log(6.1 + 0.1)
pre_sleep_above_model <- stats::lm(
  response_value ~ 1,
  data = pre_sleep_above_audit
)
pre_sleep_above_bounds <- h01_prediction_bounds(
  pre_sleep_above_model,
  pre_sleep_above_audit,
  pre_sleep_spec
)
stopifnot(
  pre_sleep_above_bounds$observed_above_bound_n == 0L,
  pre_sleep_above_bounds$observed_above_audit_threshold_n == 1L,
  pre_sleep_above_bounds$audit_threshold_status ==
    "WARN_OBSERVED_AUDIT_THRESHOLD"
)

message("Testing the Gaussian mixed-model path")
gaussian_spec <- registry[
  registry$metric_id == "daily_geometric_mean_medi",
  ,
  drop = FALSE
]
gaussian_frame <- h01_prepare_model_frame(
  main,
  gaussian_spec,
  placement = "glasses",
  sample_scenario = "all_available"
)
gaussian_bundle <- h01_fit_metric_models(gaussian_frame, gaussian_spec)
gaussian_tests <- h01_model_tests(gaussian_bundle)
stopifnot(
  nrow(gaussian_tests) == 4L,
  all(gaussian_tests$n_obs_full == nrow(gaussian_frame)),
  all(gaussian_tests$comparison_status == "PASS")
)
gaussian_site <- h01_site_summaries(
  h01_unwrap_model(gaussian_bundle, "final", "site_full"),
  gaussian_frame,
  gaussian_spec
)
stopifnot(
  nrow(gaussian_site$estimates) ==
    dplyr::n_distinct(gaussian_frame$site) + 2L,
  nrow(gaussian_site$deviations) ==
    dplyr::n_distinct(gaussian_frame$site)
)
gaussian_r2 <- h01_r2_point_summary(gaussian_bundle)
stopifnot(
  nrow(gaussian_r2) == 1L,
  all(is.finite(gaussian_r2$marginal_r2)),
  all(is.finite(gaussian_r2$conditional_r2))
)

message("Testing the Tweedie mixed-model path")
tweedie_spec <- registry[
  registry$metric_id == "duration_above_1000",
  ,
  drop = FALSE
]
tweedie_frame <- h01_prepare_model_frame(
  main,
  tweedie_spec,
  placement = "glasses",
  sample_scenario = "all_available"
)
tweedie_bundle <- h01_fit_metric_models(tweedie_frame, tweedie_spec)
tweedie_tests <- h01_model_tests(tweedie_bundle)
stopifnot(
  nrow(tweedie_tests) == 4L,
  all(tweedie_tests$n_obs_full == nrow(tweedie_frame)),
  all(tweedie_tests$comparison_status == "PASS")
)
tweedie_r2 <- h01_r2_point_summary(tweedie_bundle)
stopifnot(
  identical(tweedie_r2$approximation, c("lognormal", "delta")),
  all(is.finite(tweedie_r2$marginal_r2))
)

message("Testing shared implementation on the manuscript-prepared data")
manuscript_frame <- h01_prepare_model_frame(
  manuscript_prepared,
  gaussian_spec,
  placement = "glasses",
  sample_scenario = "all_available"
)
manuscript_bundle <- h01_fit_metric_models(
  manuscript_frame,
  gaussian_spec
)
stopifnot(
  identical(
    names(gaussian_bundle$formulas),
    names(manuscript_bundle$formulas)
  ),
  identical(
    vapply(
      gaussian_bundle$formulas,
      function(x) paste(deparse(x), collapse = " "),
      character(1)
    ),
    vapply(
      manuscript_bundle$formulas,
      function(x) paste(deparse(x), collapse = " "),
      character(1)
    )
  )
)

message("Testing unavailable manuscript-prepared censoring sensitivity")
bout_spec <- registry[
  registry$metric_id == "longest_bout_above_250",
  ,
  drop = FALSE
]
manuscript_exact_bout <- h01_prepare_model_frame(
  manuscript_prepared,
  bout_spec,
  placement = "chest",
  sample_scenario = "all_available",
  exactly_identified_only = TRUE
)
stopifnot(nrow(manuscript_exact_bout) == 0L)

message("Testing a small successful joint R2 bootstrap")
bootstrap <- h01_bootstrap_r2(
  gaussian_bundle,
  gaussian_frame,
  seed = 20260730L,
  successful_refits = 3L,
  cores = 1L,
  maximum_attempts = 10L
)
stopifnot(
  bootstrap$audit$used_refits == 3L,
  dplyr::n_distinct(bootstrap$draws$bootstrap_replicate) == 3L
)
bootstrap_summary <- h01_summarize_bootstrap(
  gaussian_r2,
  bootstrap$draws
)
stopifnot(
  nrow(bootstrap_summary) == 8L,
  all(bootstrap_summary$bootstrap_successful_used == 3L)
)

message("All H01 modeling tests passed")
