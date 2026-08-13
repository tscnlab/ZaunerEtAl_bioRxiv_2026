#!/usr/bin/env Rscript

# H06_daily exploratory mutually adjusted context analysis.
#
# This script fits primary-near-eye common-sample models only. It does not
# modify accepted primary estimates, p-values, multiplicity families, or model
# objects.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(ggplot2)
  library(glmmTMB)
  library(lme4)
  library(purrr)
  library(readr)
  library(sandwich)
  library(tibble)
  library(tidyr)
})

locate_project_root <- function(start = getwd()) {
  candidate <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(candidate, "renv.lock")) &&
        file.exists(file.path(candidate, "_quarto.yml"))
    ) return(candidate)
    parent <- dirname(candidate)
    if (identical(parent, candidate)) {
      stop("Could not locate the project root", call. = FALSE)
    }
    candidate <- parent
  }
}

root <- locate_project_root()
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_modeling.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_joint_context_exploratory_contract.R"
))

h06d_joint_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06_daily joint-context analysis requires R 4.6.1"
)

roots <- h06d_joint_artifact_roots(root)
for (path in roots) dir.create(path, recursive = TRUE, showWarnings = FALSE)
model_dir <- file.path(
  roots$models,
  "H06_daily_joint_context_exploratory_cells"
)
dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

started_at <- Sys.time()
started_elapsed <- proc.time()[["elapsed"]]

input_contract <- h06d_joint_input_contract() |>
  rowwise() |>
  mutate(
    actual_sha256 = h06d_joint_sha256(file.path(root, .data$relative_path)),
    verification_status = if_else(
      .data$actual_sha256 == .data$expected_sha256,
      "PASS",
      "FAIL"
    )
  ) |>
  ungroup() |>
  mutate(
    authorization = "direct author request, 2026-08-13",
    gate = "H06-D-G3-JOINT-CONTEXT",
    r_version = as.character(getRversion())
  )
h06d_joint_assert(
  all(input_contract$verification_status == "PASS"),
  "A joint-context input pin changed; fitting stopped"
)
write_csv(
  input_contract,
  file.path(
    roots$manifests,
    "H06_daily_joint_context_exploratory_input_manifest.csv"
  ),
  na = ""
)

metrics <- h06d_joint_metric_registry()
slots <- h06d_joint_slot_registry()
predictors <- h06d_joint_predictor_registry()
site_registry <- read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  arrange(.data$display_order)

diaries <- h06d_nl_load_diaries(root)
non_l10_source <- h06d_nl_primary_source(root, "near_eye", diaries)

wide <- readRDS(file.path(
  root,
  "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds"
))
h06d_joint_assert(
  all(c(
    "mder", "mder_viable_ratio_minutes", "mder_expected_minutes",
    "mder_minimum_viable_fraction", "mder_passes_viable_ratio_support",
    "mder_support_threshold_enforced", "mder_ratio_scaled_or_weighted",
    "mder_estimable"
  ) %in% names(wide)),
  "The current near-eye source lacks an audited MDER support field"
)
mder_source <- wide |>
  transmute(
    dataset_id = "primary",
    placement_id = "near_eye",
    placement = "Near-eye",
    site = as.character(.data$site),
    Id = as.character(.data$Id),
    local_date = as.Date(.data$local_date),
    metric_slot = 15L,
    metric_id = "mder_mean_of_viable_ratios",
    manuscript_name = "Melanopic daylight efficacy ratio",
    source_column = "mder",
    response_source = as.numeric(.data$mder),
    expected_minutes = as.numeric(.data$mder_expected_minutes),
    viable_ratio_minutes = as.integer(.data$mder_viable_ratio_minutes),
    minimum_viable_fraction = as.numeric(.data$mder_minimum_viable_fraction),
    passes_support = as.logical(.data$mder_passes_viable_ratio_support),
    support_threshold_enforced = as.logical(
      .data$mder_support_threshold_enforced
    ),
    ratio_scaled_or_weighted = as.logical(.data$mder_ratio_scaled_or_weighted),
    estimable = as.logical(.data$mder_estimable),
    longest_period_exact = NA,
    response_family = "gaussian",
    response_transform = "identity",
    effect_scale = "absolute MDER difference",
    display_unit = "dimensionless",
    lower_bound = 0,
    upper_bound = Inf,
    is_timing = FALSE
  ) |>
  h06d_nl_join_context(diaries) |>
  mutate(
    participant_key = paste(.data$site, .data$Id, sep = "::"),
    participant_day_key = paste(
      .data$site,
      .data$Id,
      .data$local_date,
      sep = "::"
    )
  )

finite_mder <- is.finite(mder_source$response_source)
h06d_joint_assert(
  nrow(mder_source) == 816L &&
    all(mder_source$expected_minutes == 1440) &&
    all(mder_source$minimum_viable_fraction == 0.5) &&
    all(mder_source$support_threshold_enforced) &&
    all(!mder_source$ratio_scaled_or_weighted) &&
    all(finite_mder == mder_source$estimable) &&
    all(finite_mder == mder_source$passes_support) &&
    all(mder_source$viable_ratio_minutes[finite_mder] >= 720L) &&
    all(mder_source$viable_ratio_minutes[!finite_mder] < 720L) &&
    all(mder_source$response_source[finite_mder] > 0),
  "The current MDER values do not satisfy the sealed METRIC-010 rule"
)

site_levels <- site_registry$site
source_data <- bind_rows(non_l10_source, mder_source) |>
  mutate(
    site = factor(as.character(.data$site), levels = .env$site_levels),
    work_free_day = factor(
      as.character(.data$work_free_day),
      levels = c("Work day", "Free day")
    ),
    activity_status = factor(
      as.character(.data$activity_status),
      levels = c("Sedentary", "Active")
    )
  )

h06d_joint_assert(
  !anyDuplicated(source_data[c(
    "site", "Id", "local_date", "metric_id"
  )]),
  "The joint-context source contains duplicate participant-day metrics"
)

h06d_joint_make_frame <- function(source, metric) {
  output <- source |>
    filter(
      .data$metric_id == metric$metric_id[[1L]],
      is.finite(.data$response_source),
      !is.na(.data$work_free_day),
      !is.na(.data$activity_status),
      is.finite(.data$previous_sleep_duration_centered_h)
    ) |>
    mutate(
      response_value = h06d_nl_transform_response(
        .data$response_source,
        metric$response_transform[[1L]]
      ),
      site = droplevels(.data$site),
      participant_key = factor(.data$participant_key),
      work_free_day = droplevels(.data$work_free_day),
      activity_status = droplevels(.data$activity_status)
    ) |>
    arrange(.data$site, .data$participant_key, .data$local_date)
  h06d_joint_assert(
    nrow(output) > 0L && n_distinct(output$site) == 9L,
    "The common frame for `%s` is empty or omits a submitted site",
    metric$metric_id[[1L]]
  )
  h06d_joint_assert(
    !anyDuplicated(output[c("site", "participant_key", "local_date")]),
    "The common frame for `%s` contains duplicate participant-days",
    metric$metric_id[[1L]]
  )
  contrasts(output$site) <- stats::contr.sum(nlevels(output$site))
  output
}

frames <- setNames(vector("list", nrow(metrics)), metrics$metric_id)
frame_rows <- vector("list", nrow(metrics))
for (index in seq_len(nrow(metrics))) {
  metric <- metrics[index, ]
  frame <- h06d_joint_make_frame(source_data, metric)
  frames[[metric$metric_id[[1L]]]] <- frame
  design_joint <- model.matrix(
    ~ site + work_free_day + activity_status +
      previous_sleep_duration_centered_h,
    data = frame
  )
  interaction_checks <- map_dfr(
    predictors$column,
    function(column) {
      design <- model.matrix(
        h06d_joint_formula(
          "interaction",
          column,
          random_intercept = FALSE
        ),
        data = frame
      )
      tibble(
        predictor_column = column,
        design_columns = ncol(design),
        design_rank = qr(design)$rank,
        full_rank = qr(design)$rank == ncol(design)
      )
    }
  )
  h06d_joint_assert(
    qr(design_joint)$rank == ncol(design_joint) &&
      all(interaction_checks$full_rank),
    "A joint or site-interaction design is rank deficient for `%s`",
    metric$metric_id[[1L]]
  )
  frame_rows[[index]] <- tibble(
    metric_slot = metric$metric_slot,
    metric_id = metric$metric_id,
    manuscript_name = metric$manuscript_name,
    response_family = metric$response_family,
    response_transform = metric$response_transform,
    route = if_else(
      metric$metric_id %in% c(
        "m10_midpoint", "l10_midpoint", "first_timing_above_250",
        "last_timing_above_250"
      ),
      "fixed_site_lm_participant_cluster_HC3",
      "mixed_model_participant_random_intercept"
    ),
    participant_days = nrow(frame),
    participants = n_distinct(frame$participant_key),
    sites = n_distinct(frame$site),
    exact_source_zeros = sum(frame$response_source == 0),
    source_minimum = min(frame$response_source),
    source_median = median(frame$response_source),
    source_maximum = max(frame$response_source),
    joint_design_columns = ncol(design_joint),
    joint_design_rank = qr(design_joint)$rank,
    frame_object_sha256 = digest(
      frame,
      algo = "sha256",
      serialize = TRUE
    )
  )
}
frame_registry <- bind_rows(frame_rows)
saveRDS(
  frames,
  file.path(
    roots$model_data,
    "H06_daily_joint_context_exploratory_frames.rds"
  ),
  version = 3
)
write_csv(
  frame_registry,
  file.path(
    roots$model_data,
    "H06_daily_joint_context_exploratory_frame_registry.csv"
  ),
  na = ""
)

h06d_joint_capture_status <- function(capture, structure, model_role) {
  if (is.null(capture$value)) {
    return(tibble(
      structure = structure,
      model_role = model_role,
      fitted = FALSE,
      acceptable = FALSE,
      elapsed_seconds = capture$elapsed_seconds,
      warning_count = length(capture$warnings),
      warnings = paste(capture$warnings, collapse = " | "),
      fit_error = capture$error,
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      maximum_absolute_gradient = NA_real_,
      convergence_message = capture$error
    ))
  }
  status <- h06d_nl_model_status(capture$value)
  bind_cols(
    tibble(
      structure = structure,
      model_role = model_role,
      fitted = TRUE,
      elapsed_seconds = capture$elapsed_seconds,
      warning_count = length(capture$warnings),
      warnings = paste(capture$warnings, collapse = " | "),
      fit_error = capture$error
    ),
    status
  ) |>
    mutate(
      acceptable = .data$converged &
        .data$positive_definite_hessian &
        !coalesce(.data$singular, FALSE),
      .after = "fitted"
    )
}

h06d_joint_mixed_ok <- function(capture) {
  if (is.null(capture$value)) return(FALSE)
  status <- h06d_nl_model_status(capture$value)
  isTRUE(status$converged) &&
    isTRUE(status$positive_definite_hessian) &&
    !isTRUE(status$singular)
}

h06d_joint_fit_mixed <- function(frame, metric, formula, REML) {
  h06d_nl_fit_model(
    frame,
    formula,
    metric$response_family[[1L]],
    REML = REML,
    ar = FALSE
  )
}

h06d_joint_fixed_components <- function(model, covariance = NULL) {
  if (inherits(model, "merMod")) {
    beta <- lme4::fixef(model)
    covariance <- as.matrix(stats::vcov(model))
  } else if (inherits(model, "glmmTMB")) {
    beta <- glmmTMB::fixef(model)$cond
    covariance <- as.matrix(stats::vcov(model)$cond)
  } else if (inherits(model, "lm")) {
    beta <- stats::coef(model)
    h06d_joint_assert(!is.null(covariance), "An LM requires HC3 covariance")
  } else {
    h06d_joint_abort("Unsupported fitted-model class")
  }
  list(beta = beta, covariance = covariance)
}

h06d_joint_effect <- function(
  model,
  covariance,
  metric,
  predictor,
  critical,
  model_id
) {
  fixed <- h06d_joint_fixed_components(model, covariance)
  term <- predictor$term[[1L]]
  predictor_name <- predictor$reader_name[[1L]]
  contrast_label <- predictor$contrast_label[[1L]]
  index <- match(term, names(fixed$beta))
  h06d_joint_assert(
    !is.na(index),
    "Term `%s` is absent from `%s`",
    term,
    model_id
  )
  estimate <- unname(fixed$beta[[index]])
  standard_error <- sqrt(fixed$covariance[index, index])
  lower <- estimate - critical * standard_error
  upper <- estimate + critical * standard_error
  display <- if (metric$response_transform[[1L]] == "log10_offset_0.1") {
    c(10^estimate, 10^lower, 10^upper)
  } else if (metric$response_family[[1L]] == "tweedie_log") {
    exp(c(estimate, lower, upper))
  } else {
    c(estimate, lower, upper)
  }
  tibble(
    metric_slot = metric$metric_slot,
    metric_id = metric$metric_id,
    manuscript_name = metric$manuscript_name,
    predictor_order = predictor$predictor_order,
    predictor_id = predictor$predictor_id,
    predictor = .env$predictor_name,
    contrast = .env$contrast_label,
    model_id = model_id,
    estimate = estimate,
    standard_error = standard_error,
    lower_95 = lower,
    upper_95 = upper,
    display_estimate = display[[1L]],
    display_lower_95 = display[[2L]],
    display_upper_95 = display[[3L]],
    effect_scale = metric$effect_scale,
    effect_status = "ESTIMABLE"
  )
}

h06d_joint_empty_effect <- function(metric, predictor, model_id, status) {
  predictor_name <- predictor$reader_name[[1L]]
  contrast_label <- predictor$contrast_label[[1L]]
  tibble(
    metric_slot = metric$metric_slot,
    metric_id = metric$metric_id,
    manuscript_name = metric$manuscript_name,
    predictor_order = predictor$predictor_order,
    predictor_id = predictor$predictor_id,
    predictor = .env$predictor_name,
    contrast = .env$contrast_label,
    model_id = model_id,
    estimate = NA_real_,
    standard_error = NA_real_,
    lower_95 = NA_real_,
    upper_95 = NA_real_,
    display_estimate = NA_real_,
    display_lower_95 = NA_real_,
    display_upper_95 = NA_real_,
    effect_scale = metric$effect_scale,
    effect_status = status
  )
}

h06d_joint_lrt <- function(reduced, full, test_type, predictor) {
  result <- h06d_nl_lrt_row(reduced, full, test_type)
  result |>
    transmute(
      predictor_order = predictor$predictor_order,
      predictor_id = predictor$predictor_id,
      predictor = predictor$reader_name,
      test_type = test_type,
      statistic = .data$likelihood_ratio,
      numerator_degrees_of_freedom = .data$degrees_of_freedom,
      denominator_degrees_of_freedom = NA_real_,
      raw_p_value = .data$raw_p_value,
      method = "maximum-likelihood likelihood-ratio test",
      test_status = if_else(
        .data$test_status == "PILOT_RAW_ONLY",
        "ESTIMABLE_EXPLORATORY",
        .data$test_status
      )
    )
}

h06d_joint_empty_test <- function(predictor, test_type, method, status) {
  tibble(
    predictor_order = predictor$predictor_order,
    predictor_id = predictor$predictor_id,
    predictor = predictor$reader_name,
    test_type = test_type,
    statistic = NA_real_,
    numerator_degrees_of_freedom = NA_real_,
    denominator_degrees_of_freedom = NA_real_,
    raw_p_value = NA_real_,
    method = method,
    test_status = status
  )
}

h06d_joint_lm_bundle <- function(frame, formula) {
  fit <- h06d_tr_fit_lm(frame, formula)
  covariance <- if (is.null(fit$value)) {
    list(
      value = NULL,
      error = "LM fit failed",
      warnings = character(),
      elapsed_seconds = 0
    )
  } else {
    h06d_tr_hc3(fit$value)
  }
  list(fit = fit, covariance = covariance)
}

h06d_joint_hc3_status <- function(bundle, frame, structure, model_role) {
  fit_status <- h06d_tr_lm_status(bundle$fit$value)
  covariance_status <- h06d_tr_matrix_status(bundle$covariance$value)
  leverage <- if (is.null(bundle$fit$value)) {
    tibble(
      maximum_observation_hat = NA_real_,
      maximum_cluster_hat_share = NA_real_,
      hc3_leverage_numerically_usable = FALSE
    )
  } else {
    h06d_tr_leverage(bundle$fit$value, frame) |>
      select(
        .data$maximum_observation_hat,
        .data$maximum_cluster_hat_share,
        .data$hc3_leverage_numerically_usable
      )
  }
  bind_cols(
    tibble(
      structure = structure,
      model_role = model_role,
      fitted = !is.null(bundle$fit$value),
      elapsed_seconds = bundle$fit$elapsed_seconds,
      warning_count = length(bundle$fit$warnings) +
        length(bundle$covariance$warnings),
      warnings = paste(
        unique(c(bundle$fit$warnings, bundle$covariance$warnings)),
        collapse = " | "
      ),
      fit_error = paste(
        na.omit(c(bundle$fit$error, bundle$covariance$error)),
        collapse = " | "
      )
    ),
    fit_status,
    covariance_status |>
      rename_with(~ paste0("covariance_", .x)),
    leverage
  ) |>
    mutate(
      acceptable = .data$fitted &
        .data$design_full_rank &
        .data$finite_coefficients &
        .data$covariance_finite &
        .data$covariance_symmetric &
        .data$covariance_positive_semidefinite &
        .data$hc3_leverage_numerically_usable &
        .data$warning_count == 0L,
      .after = "fitted"
    )
}

h06d_joint_hc3_ok <- function(bundle, frame) {
  isTRUE(h06d_joint_hc3_status(
    bundle,
    frame,
    "check",
    "check"
  )$acceptable[[1L]])
}

h06d_joint_fixed_matrix <- function(model, newdata) {
  if (inherits(model, "lm")) {
    return(model.matrix(
      stats::delete.response(stats::terms(model)),
      newdata,
      contrasts.arg = model$contrasts
    ))
  }
  formula <- reformulas::nobars(stats::formula(model))
  model.matrix(stats::delete.response(stats::terms(formula)), newdata)
}

h06d_joint_inverse <- function(value, metric) {
  if (metric$response_family[[1L]] == "tweedie_log") return(exp(value))
  switch(
    metric$response_transform[[1L]],
    identity = value,
    log10_offset_0.1 = 10^value - 0.1,
    clock_hours = value %% 24,
    clock_hours_midnight_after_16 = value %% 24,
    h06d_joint_abort("Unknown inverse transform")
  )
}

h06d_joint_site_estimates <- function(
  model,
  covariance,
  frame,
  metric,
  predictor,
  critical
) {
  fixed <- h06d_joint_fixed_components(model, covariance)
  site_values <- levels(frame$site)
  column <- predictor$column[[1L]]
  reference_value <- if (column == "work_free_day") {
    "Work day"
  } else if (column == "activity_status") {
    "Sedentary"
  } else {
    0
  }
  comparison_value <- if (column == "work_free_day") {
    "Free day"
  } else if (column == "activity_status") {
    "Active"
  } else {
    1
  }
  rows <- map_dfr(site_values, function(site_value) {
    newdata <- tibble(
      site = factor(site_value, levels = levels(frame$site)),
      work_free_day = factor("Work day", levels = levels(frame$work_free_day)),
      activity_status = factor(
        "Sedentary",
        levels = levels(frame$activity_status)
      ),
      previous_sleep_duration_centered_h = 0
    )
    newdata <- bind_rows(newdata, newdata)
    newdata[[column]] <- if (is.numeric(frame[[column]])) {
      c(reference_value, comparison_value)
    } else {
      factor(
        c(reference_value, comparison_value),
        levels = levels(frame[[column]])
      )
    }
    contrasts(newdata$site) <- contrasts(frame$site)
    design <- h06d_joint_fixed_matrix(model, newdata)
    design <- design[, names(fixed$beta), drop = FALSE]
    link <- as.numeric(design %*% fixed$beta)
    link_se <- sqrt(diag(design %*% fixed$covariance %*% t(design)))
    contrast_design <- design[2L, , drop = FALSE] -
      design[1L, , drop = FALSE]
    contrast <- as.numeric(contrast_design %*% fixed$beta)
    contrast_se <- sqrt(as.numeric(
      contrast_design %*% fixed$covariance %*% t(contrast_design)
    ))
    contrast_ci <- contrast + c(-1, 1) * critical * contrast_se
    contrast_display <- if (
      metric$response_transform[[1L]] == "log10_offset_0.1"
    ) {
      10^c(contrast, contrast_ci)
    } else if (metric$response_family[[1L]] == "tweedie_log") {
      exp(c(contrast, contrast_ci))
    } else {
      c(contrast, contrast_ci)
    }
    tibble(
      metric_slot = metric$metric_slot,
      metric_id = metric$metric_id,
      manuscript_name = metric$manuscript_name,
      predictor_order = predictor$predictor_order,
      predictor_id = predictor$predictor_id,
      predictor = predictor$reader_name,
      site = site_value,
      reference_level = if_else(
        column == "previous_sleep_duration_centered_h",
        "8 h",
        as.character(reference_value)
      ),
      comparison_level = if_else(
        column == "previous_sleep_duration_centered_h",
        "9 h",
        as.character(comparison_value)
      ),
      other_contexts = case_when(
        column == "work_free_day" ~ "Sedentary; 8 h sleep",
        column == "activity_status" ~ "Work day; 8 h sleep",
        TRUE ~ "Work day; Sedentary"
      ),
      reference_link = link[[1L]],
      reference_link_se = link_se[[1L]],
      comparison_link = link[[2L]],
      comparison_link_se = link_se[[2L]],
      reference_fitted = h06d_joint_inverse(link[[1L]], metric),
      comparison_fitted = h06d_joint_inverse(link[[2L]], metric),
      contrast_estimate = contrast,
      contrast_standard_error = contrast_se,
      contrast_lower_95 = contrast_ci[[1L]],
      contrast_upper_95 = contrast_ci[[2L]],
      display_estimate = contrast_display[[1L]],
      display_lower_95 = contrast_display[[2L]],
      display_upper_95 = contrast_display[[3L]],
      effect_scale = metric$effect_scale,
      pointwise_interval_excludes_null = if (
        grepl("ratio", metric$effect_scale[[1L]], fixed = TRUE)
      ) {
        contrast_display[[2L]] > 1 || contrast_display[[3L]] < 1
      } else {
        contrast_ci[[1L]] > 0 || contrast_ci[[2L]] < 0
      }
    )
  })
  rows
}

h06d_joint_residual_rows <- function(model, frame, metric, route) {
  residual_type <- if (metric$response_family[[1L]] == "tweedie_log") {
    "pearson"
  } else {
    "response"
  }
  residual <- if (inherits(model, "glmmTMB")) {
    as.numeric(stats::residuals(model, type = residual_type))
  } else {
    as.numeric(stats::residuals(model))
  }
  fitted <- if (inherits(model, "glmmTMB")) {
    as.numeric(stats::predict(model, type = "response"))
  } else {
    as.numeric(stats::fitted(model))
  }
  standardized <- residual / stats::sd(residual)
  order_index <- order(standardized)
  theoretical <- stats::qnorm(stats::ppoints(length(standardized)))
  qq <- rep(NA_real_, length(standardized))
  qq[order_index] <- theoretical
  tibble(
    metric_slot = metric$metric_slot,
    metric_id = metric$metric_id,
    manuscript_name = metric$manuscript_name,
    route = route,
    response_family = metric$response_family,
    row_index = seq_along(residual),
    participant_key = as.character(frame$participant_key),
    site = as.character(frame$site),
    local_date = frame$local_date,
    fitted_value = fitted,
    residual = residual,
    standardized_residual = standardized,
    qq_theoretical = if (
      metric$response_family[[1L]] == "tweedie_log"
    ) NA_real_ else qq
  )
}

effect_rows <- list()
test_rows <- list()
status_rows <- list()
site_rows <- list()
diagnostic_rows <- list()
residual_rows <- list()
model_files <- character()

timing_ids <- c(
  "m10_midpoint", "l10_midpoint", "first_timing_above_250",
  "last_timing_above_250"
)

for (metric_index in seq_len(nrow(metrics))) {
  metric <- metrics[metric_index, ]
  metric_id <- metric$metric_id[[1L]]
  frame <- frames[[metric_id]]
  message(sprintf(
    "Joint-context fit %02d/%02d: %s (%d days)",
    metric_index,
    nrow(metrics),
    metric_id,
    nrow(frame)
  ))
  is_timing <- metric_id %in% timing_ids
  bundle <- list(metric = metric, frame_sha256 = frame_registry |>
    filter(.data$metric_id == .env$metric_id) |>
    pull(.data$frame_object_sha256))

  if (!is_timing) {
    separate <- list()
    for (predictor_index in seq_len(nrow(predictors))) {
      predictor <- predictors[predictor_index, ]
      formula <- h06d_joint_formula(
        "separate",
        predictor$column[[1L]],
        TRUE
      )
      separate[[predictor$predictor_id[[1L]]]] <- h06d_joint_fit_mixed(
        frame,
        metric,
        formula,
        REML = metric$response_family[[1L]] == "gaussian"
      )
    }
    joint_ml <- h06d_joint_fit_mixed(
      frame,
      metric,
      h06d_joint_formula("joint", random_intercept = TRUE),
      REML = FALSE
    )
    joint_effect <- if (metric$response_family[[1L]] == "gaussian") {
      h06d_joint_fit_mixed(
        frame,
        metric,
        h06d_joint_formula("joint", random_intercept = TRUE),
        REML = TRUE
      )
    } else {
      joint_ml
    }
    reduced <- list()
    interactions_ml <- list()
    interactions_effect <- list()
    for (predictor_index in seq_len(nrow(predictors))) {
      predictor <- predictors[predictor_index, ]
      id <- predictor$predictor_id[[1L]]
      column <- predictor$column[[1L]]
      reduced[[id]] <- h06d_joint_fit_mixed(
        frame,
        metric,
        h06d_joint_formula("reduced", column, TRUE),
        REML = FALSE
      )
      interactions_ml[[id]] <- h06d_joint_fit_mixed(
        frame,
        metric,
        h06d_joint_formula("interaction", column, TRUE),
        REML = FALSE
      )
      interactions_effect[[id]] <- if (
        metric$response_family[[1L]] == "gaussian"
      ) {
        h06d_joint_fit_mixed(
          frame,
          metric,
          h06d_joint_formula("interaction", column, TRUE),
          REML = TRUE
        )
      } else {
        interactions_ml[[id]]
      }
    }
    bundle$models <- list(
      separate = separate,
      joint_ml = joint_ml,
      joint_effect = joint_effect,
      reduced = reduced,
      interactions_ml = interactions_ml,
      interactions_effect = interactions_effect
    )
    status_rows[[paste0(metric_id, "__joint_ml")]] <-
      h06d_joint_capture_status(joint_ml, "joint_ml", "joint association")
    status_rows[[paste0(metric_id, "__joint_effect")]] <-
      h06d_joint_capture_status(
        joint_effect,
        "joint_effect",
        "joint point estimate"
      )
    for (predictor_index in seq_len(nrow(predictors))) {
      predictor <- predictors[predictor_index, ]
      id <- predictor$predictor_id[[1L]]
      status_rows[[paste0(metric_id, "__separate__", id)]] <-
        h06d_joint_capture_status(
          separate[[id]],
          paste0("separate__", id),
          "common-sample predictor-specific comparator"
        )
      status_rows[[paste0(metric_id, "__reduced__", id)]] <-
        h06d_joint_capture_status(
          reduced[[id]],
          paste0("reduced__", id),
          "conditional association comparison"
        )
      status_rows[[paste0(metric_id, "__interaction_ml__", id)]] <-
        h06d_joint_capture_status(
          interactions_ml[[id]],
          paste0("interaction_ml__", id),
          "conditional site heterogeneity comparison"
        )
      status_rows[[paste0(metric_id, "__interaction_effect__", id)]] <-
        h06d_joint_capture_status(
          interactions_effect[[id]],
          paste0("interaction_effect__", id),
          "conditional site-specific estimates"
        )
      separate_ok <- h06d_joint_mixed_ok(separate[[id]])
      joint_effect_ok <- h06d_joint_mixed_ok(joint_effect)
      effect_rows[[paste0(metric_id, "__", id, "__separate")]] <- if (
        separate_ok
      ) {
        h06d_joint_effect(
          separate[[id]]$value,
          NULL,
          metric,
          predictor,
          stats::qnorm(0.975),
          "common_sample_predictor_specific"
        )
      } else {
        h06d_joint_empty_effect(
          metric,
          predictor,
          "common_sample_predictor_specific",
          "NON_ESTIMABLE_MODEL_FAILURE"
        )
      }
      effect_rows[[paste0(metric_id, "__", id, "__joint")]] <- if (
        joint_effect_ok
      ) {
        h06d_joint_effect(
          joint_effect$value,
          NULL,
          metric,
          predictor,
          stats::qnorm(0.975),
          "mutually_adjusted_joint"
        )
      } else {
        h06d_joint_empty_effect(
          metric,
          predictor,
          "mutually_adjusted_joint",
          "NON_ESTIMABLE_MODEL_FAILURE"
        )
      }
      association_ok <- h06d_joint_mixed_ok(joint_ml) &&
        h06d_joint_mixed_ok(reduced[[id]])
      test_rows[[paste0(metric_id, "__", id, "__association")]] <- if (
        association_ok
      ) {
        h06d_joint_lrt(
          reduced[[id]]$value,
          joint_ml$value,
          "conditional_association",
          predictor
        )
      } else {
        h06d_joint_empty_test(
          predictor,
          "conditional_association",
          "maximum-likelihood likelihood-ratio test",
          "NON_ESTIMABLE_MODEL_FAILURE"
        )
      }
      heterogeneity_ok <- h06d_joint_mixed_ok(joint_ml) &&
        h06d_joint_mixed_ok(interactions_ml[[id]])
      test_rows[[paste0(metric_id, "__", id, "__heterogeneity")]] <- if (
        heterogeneity_ok
      ) {
        h06d_joint_lrt(
          joint_ml$value,
          interactions_ml[[id]]$value,
          "conditional_site_heterogeneity",
          predictor
        )
      } else {
        h06d_joint_empty_test(
          predictor,
          "conditional_site_heterogeneity",
          "maximum-likelihood likelihood-ratio test",
          "NON_ESTIMABLE_MODEL_FAILURE"
        )
      }
      if (h06d_joint_mixed_ok(interactions_effect[[id]])) {
        site_rows[[paste0(metric_id, "__", id)]] <-
          h06d_joint_site_estimates(
            interactions_effect[[id]]$value,
            NULL,
            frame,
            metric,
            predictor,
            stats::qnorm(0.975)
          )
      }
    }
    if (h06d_joint_mixed_ok(joint_effect)) {
      residual_rows[[metric_id]] <- h06d_joint_residual_rows(
        joint_effect$value,
        frame,
        metric,
        "mixed_model_participant_random_intercept"
      )
      lag <- h06d_nl_lag_screen(
        frame,
        residual_rows[[metric_id]]$residual
      )$overall
      diagnostic_rows[[metric_id]] <- bind_cols(
        frame_registry |>
          filter(.data$metric_id == .env$metric_id),
        h06d_nl_model_status(joint_effect$value) |>
          rename_with(~ paste0("joint_", .x)),
        lag |>
          rename_with(~ paste0("joint_", .x))
      ) |>
        mutate(hard_gate_status = "PASS_PENDING_VISUAL_REVIEW")
    } else {
      diagnostic_rows[[metric_id]] <- frame_registry |>
        filter(.data$metric_id == .env$metric_id) |>
        mutate(hard_gate_status = "FAIL_MODEL_NOT_ACCEPTABLE")
    }
  } else {
    separate <- list()
    for (predictor_index in seq_len(nrow(predictors))) {
      predictor <- predictors[predictor_index, ]
      separate[[predictor$predictor_id[[1L]]]] <- h06d_joint_lm_bundle(
        frame,
        h06d_joint_formula(
          "separate",
          predictor$column[[1L]],
          random_intercept = FALSE
        )
      )
    }
    joint <- h06d_joint_lm_bundle(
      frame,
      h06d_joint_formula("joint", random_intercept = FALSE)
    )
    reduced <- list()
    interactions <- list()
    for (predictor_index in seq_len(nrow(predictors))) {
      predictor <- predictors[predictor_index, ]
      id <- predictor$predictor_id[[1L]]
      column <- predictor$column[[1L]]
      reduced[[id]] <- h06d_joint_lm_bundle(
        frame,
        h06d_joint_formula("reduced", column, random_intercept = FALSE)
      )
      interactions[[id]] <- h06d_joint_lm_bundle(
        frame,
        h06d_joint_formula("interaction", column, random_intercept = FALSE)
      )
    }
    bundle$models <- list(
      separate = separate,
      joint = joint,
      reduced = reduced,
      interactions = interactions
    )
    status_rows[[paste0(metric_id, "__joint")]] <-
      h06d_joint_hc3_status(joint, frame, "joint", "joint association")
    for (predictor_index in seq_len(nrow(predictors))) {
      predictor <- predictors[predictor_index, ]
      id <- predictor$predictor_id[[1L]]
      status_rows[[paste0(metric_id, "__separate__", id)]] <-
        h06d_joint_hc3_status(
          separate[[id]],
          frame,
          paste0("separate__", id),
          "common-sample predictor-specific comparator"
        )
      status_rows[[paste0(metric_id, "__reduced__", id)]] <-
        h06d_joint_hc3_status(
          reduced[[id]],
          frame,
          paste0("reduced__", id),
          "conditional association comparison"
        )
      status_rows[[paste0(metric_id, "__interaction__", id)]] <-
        h06d_joint_hc3_status(
          interactions[[id]],
          frame,
          paste0("interaction__", id),
          "conditional site heterogeneity and estimates"
        )
      clusters <- n_distinct(frame$participant_key)
      critical <- stats::qt(0.975, df = clusters - 1L)
      separate_ok <- h06d_joint_hc3_ok(separate[[id]], frame)
      joint_ok <- h06d_joint_hc3_ok(joint, frame)
      effect_rows[[paste0(metric_id, "__", id, "__separate")]] <- if (
        separate_ok
      ) {
        h06d_joint_effect(
          separate[[id]]$fit$value,
          separate[[id]]$covariance$value,
          metric,
          predictor,
          critical,
          "common_sample_predictor_specific"
        )
      } else {
        h06d_joint_empty_effect(
          metric,
          predictor,
          "common_sample_predictor_specific",
          "NON_ESTIMABLE_MODEL_OR_COVARIANCE"
        )
      }
      effect_rows[[paste0(metric_id, "__", id, "__joint")]] <- if (
        joint_ok
      ) {
        h06d_joint_effect(
          joint$fit$value,
          joint$covariance$value,
          metric,
          predictor,
          critical,
          "mutually_adjusted_joint"
        )
      } else {
        h06d_joint_empty_effect(
          metric,
          predictor,
          "mutually_adjusted_joint",
          "NON_ESTIMABLE_MODEL_OR_COVARIANCE"
        )
      }
      association <- if (joint_ok) {
        h06d_tr_wald_test(
          joint$fit$value,
          joint$covariance$value,
          predictor$term[[1L]],
          clusters,
          "conditional_association"
        )
      } else {
        NULL
      }
      test_rows[[paste0(metric_id, "__", id, "__association")]] <- if (
        !is.null(association)
      ) {
        association |>
          transmute(
            predictor_order = predictor$predictor_order,
            predictor_id = predictor$predictor_id,
            predictor = predictor$reader_name,
            test_type = "conditional_association",
            statistic = .data$f_statistic,
            numerator_degrees_of_freedom =
              .data$numerator_degrees_of_freedom,
            denominator_degrees_of_freedom =
              .data$denominator_degrees_of_freedom,
            raw_p_value = .data$raw_p_value,
            method = paste(
              "participant-cluster HC3 robust Wald F;",
              "cluster-minus-one reference"
            ),
            test_status = if_else(
              .data$test_status == "PILOT_RAW_ONLY_NO_BH_UPDATE",
              "ESTIMABLE_EXPLORATORY",
              .data$test_status
            )
          )
      } else {
        h06d_joint_empty_test(
          predictor,
          "conditional_association",
          "participant-cluster HC3 robust Wald F",
          "NON_ESTIMABLE_MODEL_OR_COVARIANCE"
        )
      }
      interaction_ok <- h06d_joint_hc3_ok(interactions[[id]], frame)
      interaction_terms <- if (interaction_ok) {
        h06d_tr_interaction_terms(
          interactions[[id]]$fit$value,
          predictor$column[[1L]]
        )
      } else {
        character()
      }
      heterogeneity <- if (interaction_ok && length(interaction_terms)) {
        h06d_tr_wald_test(
          interactions[[id]]$fit$value,
          interactions[[id]]$covariance$value,
          interaction_terms,
          clusters,
          "conditional_site_heterogeneity"
        )
      } else {
        NULL
      }
      test_rows[[paste0(metric_id, "__", id, "__heterogeneity")]] <- if (
        !is.null(heterogeneity)
      ) {
        heterogeneity |>
          transmute(
            predictor_order = predictor$predictor_order,
            predictor_id = predictor$predictor_id,
            predictor = predictor$reader_name,
            test_type = "conditional_site_heterogeneity",
            statistic = .data$f_statistic,
            numerator_degrees_of_freedom =
              .data$numerator_degrees_of_freedom,
            denominator_degrees_of_freedom =
              .data$denominator_degrees_of_freedom,
            raw_p_value = .data$raw_p_value,
            method = paste(
              "participant-cluster HC3 robust Wald F;",
              "cluster-minus-one reference"
            ),
            test_status = if_else(
              .data$test_status == "PILOT_RAW_ONLY_NO_BH_UPDATE",
              "ESTIMABLE_EXPLORATORY",
              .data$test_status
            )
          )
      } else {
        h06d_joint_empty_test(
          predictor,
          "conditional_site_heterogeneity",
          "participant-cluster HC3 robust Wald F",
          "NON_ESTIMABLE_MODEL_OR_COVARIANCE"
        )
      }
      if (interaction_ok) {
        site_rows[[paste0(metric_id, "__", id)]] <-
          h06d_joint_site_estimates(
            interactions[[id]]$fit$value,
            interactions[[id]]$covariance$value,
            frame,
            metric,
            predictor,
            critical
          )
      }
    }
    if (h06d_joint_hc3_ok(joint, frame)) {
      residual_rows[[metric_id]] <- h06d_joint_residual_rows(
        joint$fit$value,
        frame,
        metric,
        "fixed_site_lm_participant_cluster_HC3"
      )
      lag <- h06d_tr_lag_screen(
        frame,
        residual_rows[[metric_id]]$residual
      )$overall
      joint_status <- h06d_joint_hc3_status(
        joint,
        frame,
        "joint",
        "joint association"
      )
      diagnostic_rows[[metric_id]] <- bind_cols(
        frame_registry |>
          filter(.data$metric_id == .env$metric_id),
        joint_status |>
          select(
            joint_acceptable = .data$acceptable,
            joint_design_full_rank = .data$design_full_rank,
            joint_covariance_positive_semidefinite =
              .data$covariance_positive_semidefinite,
            joint_maximum_observation_hat = .data$maximum_observation_hat,
            joint_maximum_cluster_hat_share =
              .data$maximum_cluster_hat_share
          ),
        lag |>
          rename_with(~ paste0("joint_", .x))
      ) |>
        mutate(hard_gate_status = "PASS_PENDING_VISUAL_REVIEW")
    } else {
      diagnostic_rows[[metric_id]] <- frame_registry |>
        filter(.data$metric_id == .env$metric_id) |>
        mutate(hard_gate_status = "FAIL_MODEL_OR_HC3_NOT_ACCEPTABLE")
    }
  }

  model_file <- file.path(
    model_dir,
    sprintf("slot_%02d_%s.rds", metric$metric_slot[[1L]], metric_id)
  )
  saveRDS(bundle, model_file, version = 3)
  model_files <- c(model_files, model_file)
}

effects_long <- bind_rows(effect_rows)
# Attach each test to its metric using the exact metric identifier at the
# start of the list key.
test_key <- names(test_rows)
tests <- map2_dfr(test_rows, test_key, function(row, key) {
  metric_id <- metrics$metric_id[startsWith(key, metrics$metric_id)]
  h06d_joint_assert(
    length(metric_id) == 1L,
    "Could not resolve the metric from test key `%s`",
    key
  )
  metric <- metrics |>
    filter(.data$metric_id == .env$metric_id)
  bind_cols(
    metric |>
      select(
        .data$metric_slot,
        .data$metric_id,
        .data$manuscript_name,
        .data$effect_scale
      ),
    row
  )
})

# Retain the accepted L10 slot explicitly without fitting another estimand.
l10_effects <- tidyr::crossing(
  tibble(
    metric_slot = 3L,
    metric_id = "l10_mean_medi",
    manuscript_name = "Darkest 10 h mean",
    effect_scale = "accepted two-part overall estimand"
  ),
  predictors |>
    select(
      .data$predictor_order,
      .data$predictor_id,
      predictor = .data$reader_name,
      contrast = .data$contrast_label
    ),
  tibble(
    model_id = c(
      "common_sample_predictor_specific",
      "mutually_adjusted_joint"
    )
  )
) |>
  mutate(
    estimate = NA_real_,
    standard_error = NA_real_,
    lower_95 = NA_real_,
    upper_95 = NA_real_,
    display_estimate = NA_real_,
    display_lower_95 = NA_real_,
    display_upper_95 = NA_real_,
    effect_status = "NAMED_NA_ACCEPTED_L10_ESTIMAND_NOT_REPLACED"
  )
effects_long <- bind_rows(effects_long, l10_effects) |>
  arrange(.data$metric_slot, .data$predictor_order, .data$model_id)

l10_tests <- tidyr::crossing(
  tibble(
    metric_slot = 3L,
    metric_id = "l10_mean_medi",
    manuscript_name = "Darkest 10 h mean",
    effect_scale = "accepted two-part overall estimand"
  ),
  predictors |>
    select(
      .data$predictor_order,
      .data$predictor_id,
      predictor = .data$reader_name
    ),
  tibble(
    test_type = c(
      "conditional_association",
      "conditional_site_heterogeneity"
    )
  )
) |>
  mutate(
    statistic = NA_real_,
    numerator_degrees_of_freedom = NA_real_,
    denominator_degrees_of_freedom = NA_real_,
    raw_p_value = NA_real_,
    method = "not fitted; accepted L10 estimand retained",
    test_status = "NAMED_NA_ACCEPTED_L10_ESTIMAND_NOT_REPLACED"
  )
tests <- bind_rows(tests, l10_tests) |>
  arrange(.data$predictor_order, .data$test_type, .data$metric_slot) |>
  group_by(.data$predictor_order, .data$predictor_id, .data$test_type) |>
  group_modify(function(data, key) {
    adjusted <- rep(NA_real_, nrow(data))
    finite <- which(is.finite(data$raw_p_value))
    if (length(finite)) {
      adjusted[finite] <- stats::p.adjust(
        data$raw_p_value[finite],
        method = "BH",
        n = 15L
      )
    }
    mutate(
      data,
      bh_adjusted_p_value = adjusted,
      fdr_supported = is.finite(.data$bh_adjusted_p_value) &
        .data$bh_adjusted_p_value < 0.05,
      multiplicity_family_size = 15L,
      multiplicity_role = "separate exploratory 15-slot BH family"
    )
  }) |>
  ungroup()

family_summary <- tests |>
  summarise(
    named_slots = n(),
    estimable_slots = sum(is.finite(.data$raw_p_value)),
    named_na_slots = sum(!is.finite(.data$raw_p_value)),
    fdr_supported_slots = sum(.data$fdr_supported, na.rm = TRUE),
    family_valid = n() == 15L &&
      all(.data$metric_slot == seq_len(15L)) &&
      all(is.na(.data$raw_p_value[.data$metric_slot == 3L])) &&
      all(is.na(.data$bh_adjusted_p_value[.data$metric_slot == 3L])),
    .by = c("predictor_order", "predictor_id", "predictor", "test_type")
  )
h06d_joint_assert(
  nrow(tests) == 90L && nrow(family_summary) == 6L &&
    all(family_summary$family_valid),
  "The six exploratory 15-slot families are incomplete"
)

effects_wide <- effects_long |>
  select(
    .data$metric_slot,
    .data$metric_id,
    .data$manuscript_name,
    .data$predictor_order,
    .data$predictor_id,
    .data$predictor,
    .data$contrast,
    .data$effect_scale,
    .data$model_id,
    .data$estimate,
    .data$standard_error,
    .data$lower_95,
    .data$upper_95,
    .data$display_estimate,
    .data$display_lower_95,
    .data$display_upper_95,
    .data$effect_status
  ) |>
  pivot_wider(
    names_from = .data$model_id,
    values_from = c(
      .data$estimate,
      .data$standard_error,
      .data$lower_95,
      .data$upper_95,
      .data$display_estimate,
      .data$display_lower_95,
      .data$display_upper_95,
      .data$effect_status
    )
  )

accepted_non_l10 <- read_csv(
  file.path(
    root,
    "artifacts/09_tables/H06_daily/H06_daily_non_l10_production_effects.csv"
  ),
  show_col_types = FALSE
) |>
  filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$effect_status == "ESTIMABLE"
  ) |>
  select(
    .data$metric_slot,
    .data$metric_id,
    .data$predictor_id,
    original_participant_days = .data$participant_days,
    original_participants = .data$participants,
    original_estimate = .data$estimate,
    original_standard_error = .data$standard_error,
    original_display_estimate = .data$display_estimate,
    original_display_lower_95 = .data$display_lower_95,
    original_display_upper_95 = .data$display_upper_95
  )
accepted_mder <- read_csv(
  file.path(
    root,
    paste0(
      "artifacts/09_tables/H06_daily/",
      "H06_daily_mder_metric010_effect_estimates.csv"
    )
  ),
  show_col_types = FALSE
) |>
  filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$family == "Gaussian",
    .data$sensitivity_role == "selected candidate"
  ) |>
  transmute(
    metric_slot = 15L,
    metric_id = "mder_mean_of_viable_ratios",
    predictor_id = .data$predictor_id,
    original_participant_days = .data$participant_days,
    original_participants = .data$participants,
    original_estimate = .data$estimate,
    original_standard_error = .data$standard_error,
    original_display_estimate = .data$estimate,
    original_display_lower_95 = .data$lower_95,
    original_display_upper_95 = .data$upper_95
  )
accepted_effects <- bind_rows(accepted_non_l10, accepted_mder)

stability <- effects_wide |>
  left_join(
    accepted_effects,
    by = c("metric_slot", "metric_id", "predictor_id"),
    relationship = "one-to-one"
  ) |>
  left_join(
    frame_registry |>
      select(
        .data$metric_slot,
        .data$metric_id,
        common_participant_days = .data$participant_days,
        common_participants = .data$participants,
        common_sites = .data$sites,
        .data$exact_source_zeros
      ),
    by = c("metric_slot", "metric_id"),
    relationship = "many-to-one"
  ) |>
  mutate(
    sample_change_shift_in_original_se = abs(
      .data$estimate_common_sample_predictor_specific -
        .data$original_estimate
    ) / .data$original_standard_error,
    sample_change_direction_reversal = sign(
      .data$estimate_common_sample_predictor_specific
    ) != sign(.data$original_estimate),
    covariate_shift_in_common_se = abs(
      .data$estimate_mutually_adjusted_joint -
        .data$estimate_common_sample_predictor_specific
    ) / .data$standard_error_common_sample_predictor_specific,
    covariate_direction_reversal = sign(
      .data$estimate_mutually_adjusted_joint
    ) != sign(.data$estimate_common_sample_predictor_specific),
    covariate_stability = case_when(
      .data$metric_slot == 3L ~
        "NAMED_NA_ACCEPTED_L10_ESTIMAND_NOT_REPLACED",
      !is.finite(.data$covariate_shift_in_common_se) ~ "NON_ESTIMABLE",
      .data$covariate_direction_reversal |
        .data$covariate_shift_in_common_se >= 2 ~
          "UNSTABLE_GE_2_SE_OR_DIRECTION_REVERSAL",
      .data$covariate_shift_in_common_se >= 1 ~
        "SUBSTANTIAL_LIMITATION_1_TO_LT_2_SE",
      TRUE ~ "STABLE_LT_1_SE"
    ),
    sample_stability = case_when(
      .data$metric_slot == 3L ~
        "NAMED_NA_ACCEPTED_L10_ESTIMAND_NOT_REPLACED",
      !is.finite(.data$sample_change_shift_in_original_se) ~ "NON_ESTIMABLE",
      .data$sample_change_direction_reversal |
        .data$sample_change_shift_in_original_se >= 2 ~
          "UNSTABLE_GE_2_SE_OR_DIRECTION_REVERSAL",
      .data$sample_change_shift_in_original_se >= 1 ~
        "SUBSTANTIAL_LIMITATION_1_TO_LT_2_SE",
      TRUE ~ "STABLE_LT_1_SE"
    )
  ) |>
  left_join(
    tests |>
      filter(.data$test_type == "conditional_association") |>
      select(
        .data$metric_slot,
        .data$metric_id,
        .data$predictor_id,
        conditional_association_raw_p = .data$raw_p_value,
        conditional_association_bh_q = .data$bh_adjusted_p_value,
        conditional_association_fdr_supported = .data$fdr_supported,
        conditional_association_status = .data$test_status
      ),
    by = c("metric_slot", "metric_id", "predictor_id"),
    relationship = "one-to-one"
  ) |>
  left_join(
    tests |>
      filter(.data$test_type == "conditional_site_heterogeneity") |>
      select(
        .data$metric_slot,
        .data$metric_id,
        .data$predictor_id,
        conditional_heterogeneity_raw_p = .data$raw_p_value,
        conditional_heterogeneity_bh_q = .data$bh_adjusted_p_value,
        conditional_heterogeneity_fdr_supported = .data$fdr_supported,
        conditional_heterogeneity_status = .data$test_status
      ),
    by = c("metric_slot", "metric_id", "predictor_id"),
    relationship = "one-to-one"
  ) |>
  arrange(.data$metric_slot, .data$predictor_order)

site_estimates <- bind_rows(site_rows) |>
  left_join(
    site_registry |>
      select(
        .data$site,
        site_name = .data$display_name,
        .data$display_order,
        site_color = .data$color_hex
      ),
    by = "site",
    relationship = "many-to-one"
  ) |>
  left_join(
    tests |>
      filter(.data$test_type == "conditional_site_heterogeneity") |>
      select(
        .data$metric_slot,
        .data$metric_id,
        .data$predictor_id,
        global_interaction_raw_p = .data$raw_p_value,
        global_interaction_bh_q = .data$bh_adjusted_p_value,
        global_interaction_fdr_supported = .data$fdr_supported,
        global_interaction_status = .data$test_status
      ),
    by = c("metric_slot", "metric_id", "predictor_id"),
    relationship = "many-to-one"
  ) |>
  arrange(.data$metric_slot, .data$predictor_order, .data$display_order)

model_status <- bind_rows(status_rows, .id = "status_key") |>
  mutate(
    metric_id = metrics$metric_id[
      max.col(outer(
        .data$status_key,
        metrics$metric_id,
        Vectorize(startsWith)
      ), ties.method = "first")
    ]
  ) |>
  left_join(
    metrics |>
      select(.data$metric_slot, .data$metric_id, .data$manuscript_name),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  relocate(.data$metric_slot, .data$metric_id, .data$manuscript_name)

diagnostics <- bind_rows(diagnostic_rows) |>
  arrange(.data$metric_slot)
residual_source <- bind_rows(residual_rows) |>
  arrange(.data$metric_slot, .data$row_index)

write_csv(
  effects_long,
  file.path(
    roots$tables,
    "H06_daily_joint_context_exploratory_effects_long.csv"
  ),
  na = ""
)
write_csv(
  stability,
  file.path(
    roots$source_data,
    "H06_daily_joint_context_exploratory_stability.csv"
  ),
  na = ""
)
write_csv(
  tests,
  file.path(
    roots$tables,
    "H06_daily_joint_context_exploratory_tests.csv"
  ),
  na = ""
)
write_csv(
  family_summary,
  file.path(
    roots$tables,
    "H06_daily_joint_context_exploratory_family_summary.csv"
  ),
  na = ""
)
write_csv(
  site_estimates,
  file.path(
    roots$source_data,
    "H06_daily_joint_context_exploratory_site_estimates.csv"
  ),
  na = ""
)
write_csv(
  model_status,
  file.path(
    roots$diagnostics,
    "H06_daily_joint_context_exploratory_model_status.csv"
  ),
  na = ""
)
write_csv(
  diagnostics,
  file.path(
    roots$diagnostics,
    "H06_daily_joint_context_exploratory_diagnostics.csv"
  ),
  na = ""
)
write_csv(
  residual_source,
  file.path(
    roots$source_data,
    "H06_daily_joint_context_exploratory_residual_source.csv"
  ),
  na = ""
)

label_wrap <- function(value, width = 24L) {
  vapply(value, function(x) paste(strwrap(x, width), collapse = "\n"), character(1))
}

residual_plot <- residual_source |>
  mutate(
    metric_label = factor(
      label_wrap(.data$manuscript_name),
      levels = rev(unique(label_wrap(.data$manuscript_name)))
    )
  ) |>
  ggplot(aes(x = .data$fitted_value, y = .data$residual)) +
  geom_hline(yintercept = 0, colour = "#444444", linewidth = 0.35) +
  geom_point(alpha = 0.28, size = 0.55, colour = "#0072B2") +
  geom_smooth(
    method = "loess",
    formula = y ~ x,
    se = FALSE,
    colour = "#D55E00",
    linewidth = 0.6
  ) +
  facet_wrap(vars(.data$metric_label), scales = "free", ncol = 4) +
  labs(
    x = "Fitted value",
    y = "Residual",
    title = "Exploratory joint-context residuals versus fitted values",
    subtitle = paste(
      "Gaussian and HC3 routes use response residuals;",
      "Tweedie routes use Pearson residuals"
    )
  ) +
  theme_minimal(base_size = 10.5) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10.5),
    strip.text = element_text(face = "bold", size = 8.5),
    panel.grid.minor = element_blank()
  )
ggsave(
  file.path(
    roots$figures,
    "H06_daily_joint_context_exploratory_residual_fitted.png"
  ),
  residual_plot,
  width = 14,
  height = 11,
  units = "in",
  dpi = 300,
  bg = "white"
)

qq_source <- residual_source |>
  filter(is.finite(.data$qq_theoretical)) |>
  arrange(.data$metric_slot, .data$standardized_residual) |>
  mutate(
    metric_label = factor(
      label_wrap(.data$manuscript_name),
      levels = rev(unique(label_wrap(.data$manuscript_name)))
    )
  )
qq_plot <- ggplot(
  qq_source,
  aes(x = .data$qq_theoretical, y = .data$standardized_residual)
) +
  geom_abline(slope = 1, intercept = 0, colour = "#444444", linewidth = 0.4) +
  geom_point(alpha = 0.35, size = 0.55, colour = "#0072B2") +
  facet_wrap(vars(.data$metric_label), scales = "free", ncol = 4) +
  labs(
    x = "Theoretical normal quantile",
    y = "Standardized residual quantile",
    title = "Exploratory joint-context Gaussian Q-Q displays",
    subtitle = "Tweedie Pearson residuals are intentionally omitted"
  ) +
  theme_minimal(base_size = 10.5) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10.5),
    strip.text = element_text(face = "bold", size = 8.5),
    panel.grid.minor = element_blank()
  )
ggsave(
  file.path(
    roots$figures,
    "H06_daily_joint_context_exploratory_qq.png"
  ),
  qq_plot,
  width = 14,
  height = 9,
  units = "in",
  dpi = 300,
  bg = "white"
)

elapsed <- unname(proc.time()[["elapsed"]] - started_elapsed)
runtime <- tibble(
  started_at = format(started_at, "%Y-%m-%dT%H:%M:%S%z"),
  completed_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  elapsed_seconds = elapsed,
  metrics_fitted = nrow(metrics),
  common_sample_effect_rows = nrow(effects_long),
  exploratory_tests = nrow(tests),
  site_specific_rows = nrow(site_estimates),
  resampling = "none",
  deletion_refits = 0L,
  ar_refits = 0L,
  execution = "one serial R process"
)
write_csv(
  runtime,
  file.path(
    roots$diagnostics,
    "H06_daily_joint_context_exploratory_runtime.csv"
  ),
  na = ""
)

code_paths <- c(
  "scripts/hypotheses/H06_daily/h06_daily_joint_context_exploratory_contract.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_joint_context_exploratory.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R"
)
code_manifest <- tibble(relative_path = code_paths) |>
  mutate(
    sha256 = map_chr(
      .data$relative_path,
      ~ h06d_joint_sha256(file.path(root, .x))
    ),
    bytes = file.info(file.path(root, .data$relative_path))$size,
    role = case_when(
      grepl("joint_context", .data$relative_path) ~ "new exploratory code",
      TRUE ~ "accepted reusable H06_daily route helper"
    )
  )
write_csv(
  code_manifest,
  file.path(
    roots$manifests,
    "H06_daily_joint_context_exploratory_code_manifest.csv"
  ),
  na = ""
)

output_paths <- c(
  file.path(
    roots$model_data,
    "H06_daily_joint_context_exploratory_frames.rds"
  ),
  file.path(
    roots$model_data,
    "H06_daily_joint_context_exploratory_frame_registry.csv"
  ),
  model_files,
  file.path(
    roots$tables,
    "H06_daily_joint_context_exploratory_effects_long.csv"
  ),
  file.path(
    roots$tables,
    "H06_daily_joint_context_exploratory_tests.csv"
  ),
  file.path(
    roots$tables,
    "H06_daily_joint_context_exploratory_family_summary.csv"
  ),
  file.path(
    roots$source_data,
    "H06_daily_joint_context_exploratory_stability.csv"
  ),
  file.path(
    roots$source_data,
    "H06_daily_joint_context_exploratory_site_estimates.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_joint_context_exploratory_model_status.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_joint_context_exploratory_diagnostics.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_joint_context_exploratory_runtime.csv"
  ),
  file.path(
    roots$source_data,
    "H06_daily_joint_context_exploratory_residual_source.csv"
  ),
  file.path(
    roots$figures,
    "H06_daily_joint_context_exploratory_residual_fitted.png"
  ),
  file.path(
    roots$figures,
    "H06_daily_joint_context_exploratory_qq.png"
  )
)
output_manifest <- tibble(
  relative_path = sub(paste0("^", root, "/"), "", output_paths)
) |>
  mutate(
    sha256 = map_chr(
      output_paths,
      h06d_joint_sha256
    ),
    bytes = file.info(output_paths)$size
  )
write_csv(
  output_manifest,
  file.path(
    roots$manifests,
    "H06_daily_joint_context_exploratory_output_manifest.csv"
  ),
  na = ""
)

software <- tibble(
  package = c(
    "R", "dplyr", "tidyr", "readr", "tibble", "purrr", "digest",
    "lme4", "glmmTMB", "sandwich", "ggplot2"
  ),
  version = c(
    as.character(getRversion()),
    map_chr(
      c(
        "dplyr", "tidyr", "readr", "tibble", "purrr", "digest",
        "lme4", "glmmTMB", "sandwich", "ggplot2"
      ),
      ~ as.character(utils::packageVersion(.x))
    )
  ),
  role = c(
    "authoritative computation",
    rep("analysis dependency", 10L)
  )
)
write_csv(
  software,
  file.path(
    roots$manifests,
    "H06_daily_joint_context_exploratory_software_manifest.csv"
  ),
  na = ""
)

message(sprintf(
  paste0(
    "H06_daily joint-context exploratory analysis complete: ",
    "%d metrics, %d tests, %.1f seconds"
  ),
  nrow(metrics),
  nrow(tests),
  elapsed
))
