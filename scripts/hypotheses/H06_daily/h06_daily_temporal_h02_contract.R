# Versioned H02-aligned contract for the exploratory H06-daily temporal model.
# The superseded Tweedie/two-part pilot contract remains frozen separately.

h06d_h02_temporal_specification <- function() {
  list(
    implementation_id = "h06d_temporal_h02_v1",
    response_source = "arithmetic_mean_medi_lx",
    response_name = "30-minute arithmetic mean melEDI",
    response_transform = "log10(melEDI + 0.1 lx)",
    response_offset_lx = 0.1,
    response_family = "Gaussian",
    response_link = "identity",
    global_basis = "cyclic cubic regression spline",
    global_k = 12L,
    context_factor_basis = paste(
      "sum-to-zero factor smooth with default thin-plate time marginal"
    ),
    context_factor_k = 12L,
    sleep_basis = "numeric varying coefficient with default thin-plate basis",
    sleep_k = 12L,
    site_basis = paste(
      "sum-to-zero factor smooth with default thin-plate time marginal"
    ),
    site_k = 12L,
    participant_basis = paste(
      "factor smooth with default thin-plate time marginal and shared smoothing"
    ),
    participant_k = 10L,
    participant_day_basis = "random intercept",
    sleep_decomposition = paste(
      "participant mean across equally weighted fitted participant-days,",
      "centred on the equally participant-weighted grand mean, plus",
      "day-specific deviation from participant mean"
    ),
    method = "fREML",
    discrete = TRUE,
    nthreads = 1L,
    gc_level = 1L,
    clock_knots = c(0, 24),
    rho_bounds = c(-0.95, 0.95),
    rho_residual_type = "response",
    rho_algorithm = paste(
      "boundary-aware lag-1 response-residual correlation from the",
      "rho=0 full model; clamp to [-0.95, 0.95]; refit identical formula"
    ),
    pooled_residual_lag1_limit = 0.20,
    site_residual_lag1_limit = 0.30,
    basis_edf_fraction_limit = 0.90,
    basis_k_index_limit = 0.90,
    fixed_term_concurvity_limit = 0.80,
    residual_qq_correlation_limit = 0.95,
    residual_scale_pattern_limit = 0.30,
    global_closure_tolerance = 1e-8,
    primary_placement = "near_eye",
    scientific_role = paste(
      "exploratory observational association; separate from daily-metric",
      "and approved hourly H06 estimands"
    )
  )
}

h06d_h02_temporal_formula <- function(response = "response") {
  stats::as.formula(paste0(
    response,
    " ~ s(time_hour, bs = 'cc', k = 12) + ",
    "s(time_hour, work_free_day, bs = 'sz', k = 12) + ",
    "s(time_hour, activity_status, bs = 'sz', k = 12) + ",
    "s(time_hour, by = sleep_between_h, k = 12) + ",
    "s(time_hour, by = sleep_within_h, k = 12) + ",
    "s(time_hour, site, bs = 'sz', k = 12) + ",
    "s(time_hour, participant, bs = 'fs', k = 10) + ",
    "s(participant_day, bs = 're')"
  ))
}

h06d_h02_temporal_formula_registry <- function() {
  spec <- h06d_h02_temporal_specification()
  tibble::tibble(
    implementation_id = spec$implementation_id,
    component = "joint context-adjusted transformed profile",
    response_source = spec$response_source,
    response_transform = spec$response_transform,
    family = spec$response_family,
    link = spec$response_link,
    formula = paste(
      deparse(h06d_h02_temporal_formula("response")),
      collapse = " "
    ),
    estimand = paste(
      "E[log10(30-minute arithmetic-mean melEDI + 0.1 lx) | local time,",
      "work/free day, daily activity status, within- and between-person",
      "previous-night sleep duration, site, participant, participant-day]"
    ),
    inverse_transform = "max(0, 10^eta - 0.1 lx)",
    inverse_transform_qualification = paste(
      "back-transform of a mean log response; geometric-mean-like and",
      "conditional-median scale, not raw-scale E[Y]"
    )
  )
}
