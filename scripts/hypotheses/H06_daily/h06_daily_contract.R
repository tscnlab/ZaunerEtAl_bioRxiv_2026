# H06-daily contracts: immutable inputs, daily metrics, predictors, and pilots.

h06d_abort <- function(..., call. = FALSE) {
  stop(sprintf(...), call. = call.)
}

h06d_metric_columns <- function() {
  c(
    daily_geometric_mean_medi = "daily_geometric_mean_medi_lx",
    m10_mean_medi = "m10_mean_medi_lx",
    l10_mean_medi = "l10_mean_medi_lx",
    duration_above_1000 = "duration_above_1000_h",
    duration_above_250_wake = "duration_above_250_wake_h",
    duration_below_10_pre_sleep = "duration_below_10_pre_sleep_h",
    duration_below_1_sleep_environment =
      "duration_below_1_sleep_environment_h",
    longest_bout_above_250 = "longest_bout_above_250_h",
    m10_midpoint = "m10_midpoint_clock_minute",
    l10_midpoint = "l10_midpoint_clock_minute",
    mean_timing_above_250 = "mean_timing_above_250_clock_minute",
    first_timing_above_250 = "first_timing_above_250_clock_minute",
    last_timing_above_250 = "last_timing_above_250_clock_minute",
    dose_time_sensitive_corrected_medi = "dose_corrected_medi_lx_h",
    mder_ratio_of_integrals = "mder"
  )
}

h06d_predictor_registry <- function() {
  tibble::tribble(
    ~predictor_id, ~column, ~reader_name, ~type, ~reference, ~increment,
    "work_free_day", "work_free_day", "Free day versus work day",
    "categorical", "Work day", NA_real_,
    "activity_status", "activity_status", "Active versus Sedentary",
    "categorical", "Sedentary", NA_real_,
    "previous_sleep_duration_centered_h",
    "previous_sleep_duration_centered_h",
    "Previous-night sleep duration", "continuous", "8 h", 1
  )
}

h06d_daily_pilot_registry <- function() {
  tibble::tribble(
    ~pilot_id, ~metric_id, ~predictor_id, ~response_family,
    ~response_transform, ~purpose,
    "gaussian_offset", "daily_geometric_mean_medi", "work_free_day",
    "gaussian", "log10_offset_0.1",
    "Representative shifted-log Gaussian family",
    "tweedie_duration", "duration_above_1000", "activity_status",
    "tweedie_log", "identity",
    "Representative zero-containing Tweedie duration family",
    "gaussian_identity", "duration_below_10_pre_sleep",
    "previous_sleep_duration_centered_h", "gaussian", "identity",
    "Representative identity-Gaussian duration family",
    "l10_one_part", "l10_mean_medi", "work_free_day", "gaussian",
    "log10_offset_0.1", "Mandatory L10 one-part zero-mass screen"
  )
}

h06d_transform_response <- function(value, transform_id) {
  switch(
    transform_id,
    identity = value,
    log10_offset_0.1 = log10(value + 0.1),
    clock_hours = value / 60,
    clock_hours_midnight_after_16 = {
      hours <- value / 60
      ifelse(hours > 16, hours - 24, hours)
    },
    h06d_abort("Unknown H06-daily response transform `%s`", transform_id)
  )
}

h06d_daily_formula_set <- function(predictor_column) {
  measure <- predictor_column
  list(
    registered_random_site = stats::as.formula(sprintf(
      paste0(
        "response_value ~ %s + (%s | site) + ",
        "(1 | site:participant_key)"
      ),
      measure,
      measure
    )),
    fixed_site_reduced = stats::as.formula(
      "response_value ~ site + (1 | participant_key)"
    ),
    fixed_site_additive = stats::as.formula(sprintf(
      "response_value ~ site + %s + (1 | participant_key)",
      measure
    )),
    fixed_site_heterogeneity = stats::as.formula(sprintf(
      "response_value ~ site * %s + (1 | participant_key)",
      measure
    ))
  )
}

h06d_temporal_specification <- function() {
  list(
    response = "zero_aware_geometric_mean_medi_lx",
    response_reader = "30-minute zero-aware geometric-mean melEDI",
    global_k = 12L,
    categorical_k = 12L,
    site_k = 12L,
    participant_k = 8L,
    method = "fREML",
    discrete = TRUE,
    nthreads = 1L,
    clock_knots = c(0, 24),
    rho_bounds = c(-0.95, 0.95),
    tweedie_power_bounds = c(1.01, 1.99),
    zero_calibration_ratio_range = c(0.80, 1.25),
    local_support_bins = 40L,
    local_support_participants = 5L,
    local_support_sites = 3L
  )
}

h06d_temporal_formula <- function(response) {
  stats::as.formula(paste0(
    response,
    " ~ s(time_hour, bs = 'cc', k = 12) + ",
    "s(time_hour, work_free_day, bs = 'sz', k = 12, ",
    "xt = list(bs = 'cc')) + ",
    "s(time_hour, activity_status, bs = 'sz', k = 12, ",
    "xt = list(bs = 'cc')) + ",
    "s(time_hour, by = previous_sleep_duration_centered_h, ",
    "bs = 'cc', k = 12) + ",
    "s(time_hour, site, bs = 'sz', k = 12, ",
    "xt = list(bs = 'cc')) + ",
    "s(time_hour, participant, bs = 'fs', xt = 'cc', k = 8) + ",
    "s(participant_day, bs = 're')"
  ))
}

h06d_temporal_formula_registry <- function() {
  tibble::tribble(
    ~candidate_id, ~component, ~response_family, ~formula,
    "one_part_tweedie", "conditional mean",
    "Tweedie log; p estimated without AR then fixed",
    paste(deparse(h06d_temporal_formula("geometric_mean_medi_lx")),
      collapse = " "
    ),
    "two_part_occurrence", "Pr(melEDI > 0)", "Binomial logit",
    paste(deparse(h06d_temporal_formula("positive_medi")), collapse = " "),
    "two_part_positive", "positive conditional mean", "Gamma log",
    paste(deparse(h06d_temporal_formula("geometric_mean_medi_lx")),
      collapse = " "
    )
  )
}

h06d_artifact_roots <- function(root) {
  list(
    model_data = file.path(root, "artifacts/06_model_data/H06_daily"),
    models = file.path(root, "artifacts/07_models/H06_daily"),
    diagnostics = file.path(root, "artifacts/08_diagnostics/H06_daily"),
    tables = file.path(root, "artifacts/09_tables/H06_daily"),
    figures = file.path(root, "artifacts/10_figures/H06_daily"),
    source_data = file.path(root, "artifacts/11_source_data/H06_daily"),
    manifests = file.path(root, "artifacts/12_manifests/H06_daily")
  )
}
