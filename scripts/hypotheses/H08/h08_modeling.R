# Prepare, fit, diagnose, and summarize the approved H08 models.

h08_transform_response <- function(value, spec) {
  value <- as.numeric(value)
  if (spec$response_transform == "log10_offset_0.1") {
    if (any(value < 0, na.rm = TRUE)) {
      h08_abort(
        "`%s` contains a negative value before log10 transformation",
        spec$metric_id
      )
    }
    return(log10(value + 0.1))
  }
  if (spec$response_transform == "identity") {
    return(value)
  }
  h08_abort(
    "Unknown H08 response transformation `%s` for `%s`",
    spec$response_transform,
    spec$metric_id
  )
}

h08_back_transform_response <- function(value, spec) {
  if (spec$response_family == "tweedie_log") {
    return(exp(value))
  }
  if (spec$response_transform == "log10_offset_0.1") {
    return(10^value - 0.1)
  }
  value
}

h08_transform_effect <- function(estimate, conf_low, conf_high, spec) {
  if (spec$effect_scale == "difference") {
    return(tibble::tibble(
      estimate_practical = estimate,
      conf_low_practical = conf_low,
      conf_high_practical = conf_high,
      effect_type = "difference"
    ))
  }
  transform <- if (spec$response_transform == "log10_offset_0.1") {
    function(x) 10^x
  } else {
    exp
  }
  tibble::tibble(
    estimate_practical = transform(estimate),
    conf_low_practical = transform(conf_low),
    conf_high_practical = transform(conf_high),
    effect_type = "ratio"
  )
}

h08_complete_sum <- function(value) {
  if (length(value) == 0L || all(is.na(value))) NA_real_ else
    sum(value, na.rm = TRUE)
}

h08_prepare_model_frame <- function(rows, spec, site_levels, score_contract) {
  required <- c(
    "data_scenario_id",
    "placement",
    "site",
    "Id",
    "local_date",
    "metric_id",
    "value",
    "VLSQ8",
    "photoperiod_hours",
    "metric_support_valid_minutes",
    "metric_support_expected_minutes"
  )
  missing <- setdiff(required, names(rows))
  if (length(missing) > 0L) {
    h08_abort(
      "H08 model rows are missing column(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  frame <- rows[
    is.finite(rows$value) & is.finite(rows$VLSQ8),
    ,
    drop = FALSE
  ]
  if (nrow(frame) == 0L) {
    return(tibble::tibble())
  }
  frame$site <- factor(as.character(frame$site), levels = site_levels)
  if (any(is.na(frame$site))) {
    h08_abort("H08 frame contains a site absent from the display registry")
  }
  frame$site <- droplevels(frame$site)
  if (nlevels(frame$site) < 2L) {
    h08_abort(
      "H08 frame for `%s` contains fewer than two sites",
      spec$metric_id
    )
  }
  stats::contrasts(frame$site) <- stats::contr.sum(nlevels(frame$site))
  frame$Id <- factor(as.character(frame$Id))
  frame$participant_key <- factor(paste(frame$site, frame$Id, sep = ":"))
  frame$local_date <- as.Date(frame$local_date)
  frame$VLSQ8_c <- frame$VLSQ8 - score_contract$center
  frame$photoperiod_c <- frame$photoperiod_hours - 12
  frame$response_value <- h08_transform_response(frame$value, spec)
  frame$.model_row_id <- paste(
    frame$data_scenario_id,
    frame$placement,
    as.character(frame$site),
    as.character(frame$Id),
    format(frame$local_date),
    frame$metric_id,
    sep = "|"
  )
  frame <- frame[
    order(frame$site, frame$Id, frame$local_date),
    ,
    drop = FALSE
  ]
  if (anyDuplicated(frame$.model_row_id)) {
    h08_abort(
      "H08 model-row identifiers are not unique for `%s`",
      spec$metric_id
    )
  }
  if (
    any(!is.finite(frame$response_value)) ||
      any(!is.finite(frame$VLSQ8_c))
  ) {
    h08_abort("H08 transformed frame contains a non-finite value")
  }
  tibble::as_tibble(frame)
}

h08_prepare_participant_summary <- function(frame, spec, site_levels) {
  if (nrow(frame) == 0L) {
    return(tibble::tibble())
  }
  summary <- frame |>
    dplyr::group_by(.data$site, .data$Id, .data$participant_key) |>
    dplyr::summarise(
      VLSQ8 = dplyr::first(.data$VLSQ8),
      VLSQ8_c = dplyr::first(.data$VLSQ8_c),
      participant_value = mean(.data$value),
      participant_days = dplyr::n(),
      metric_support_valid_minutes = h08_complete_sum(
        .data$metric_support_valid_minutes
      ),
      metric_support_expected_minutes = h08_complete_sum(
        .data$metric_support_expected_minutes
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      participant_response = h08_transform_response(
        .data$participant_value,
        spec
      ),
      site = factor(as.character(.data$site), levels = site_levels)
    )
  summary$site <- droplevels(summary$site)
  stats::contrasts(summary$site) <- stats::contr.sum(nlevels(summary$site))
  summary$Id <- factor(as.character(summary$Id))
  summary$participant_key <- factor(as.character(summary$participant_key))
  summary
}

h08_frame_hash <- function(frame, include_values = TRUE) {
  if (nrow(frame) == 0L) {
    return(NA_character_)
  }
  columns <- c("site", "Id")
  if ("local_date" %in% names(frame)) columns <- c(columns, "local_date")
  if (include_values) {
    value_columns <- intersect(
      c("value", "response_value", "participant_value", "participant_response"),
      names(frame)
    )
    columns <- c(columns, value_columns)
  }
  digest::digest(
    as.data.frame(frame[columns]),
    algo = "sha256",
    serialize = TRUE
  )
}

h08_key_hash <- function(frame) {
  h08_frame_hash(frame, include_values = FALSE)
}

h08_capture_fit <- function(expression) {
  warnings <- character()
  model <- tryCatch(
    withCallingHandlers(
      expression,
      warning = function(condition) {
        warnings <<- c(warnings, conditionMessage(condition))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(condition) condition
  )
  if (inherits(model, "error")) {
    return(list(
      model = NULL,
      warnings = unique(warnings),
      error = conditionMessage(model)
    ))
  }
  list(model = model, warnings = unique(warnings), error = NA_character_)
}

h08_fit_model <- function(frame, formula, spec) {
  if (nrow(frame) == 0L) {
    return(list(
      model = NULL,
      warnings = character(),
      error = "No estimable rows"
    ))
  }
  has_random <- length(reformulas::findbars(formula)) > 0L
  if (spec$response_family == "gaussian" && !has_random) {
    return(h08_capture_fit(stats::lm(formula = formula, data = frame)))
  }
  if (spec$response_family == "gaussian") {
    return(h08_capture_fit(
      lme4::lmer(
        formula = formula,
        data = frame,
        REML = FALSE,
        control = lme4::lmerControl(
          optimizer = "nloptwrap",
          calc.derivs = TRUE,
          optCtrl = list(maxeval = 200000L)
        )
      )
    ))
  }
  h08_capture_fit(
    glmmTMB::glmmTMB(
      formula = formula,
      data = frame,
      family = glmmTMB::tweedie(link = "log"),
      REML = FALSE,
      control = glmmTMB::glmmTMBControl(
        optCtrl = list(iter.max = 10000L, eval.max = 10000L)
      )
    )
  )
}

h08_fit_bundle <- function(
  frame,
  spec,
  formula_kind = c("participant_day", "photoperiod", "participant")
) {
  formula_kind <- match.arg(formula_kind)
  formulas <- h08_formula_set(formula_kind)
  fits <- lapply(formulas, function(formula) {
    h08_fit_model(frame, formula, spec)
  })
  list(
    spec = spec,
    formula_kind = formula_kind,
    formulas = formulas,
    fits = fits,
    frame_key_hash = h08_key_hash(frame),
    frame_hash = h08_frame_hash(frame)
  )
}

h08_model_fit_status <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      max_gradient = NA_real_,
      convergence_message = "Model not fitted"
    ))
  }
  if (inherits(model, "lm") && !inherits(model, "merMod")) {
    return(tibble::tibble(
      converged = TRUE,
      positive_definite_hessian = TRUE,
      singular = FALSE,
      max_gradient = NA_real_,
      convergence_message = NA_character_
    ))
  }
  if (inherits(model, "merMod")) {
    messages <- model@optinfo$conv$lme4$messages
    gradient <- model@optinfo$derivs$gradient
    max_gradient <- if (is.null(gradient)) {
      NA_real_
    } else {
      max(abs(gradient), na.rm = TRUE)
    }
    return(tibble::tibble(
      converged = is.null(messages),
      positive_definite_hessian = is.null(messages) ||
        !any(grepl("Hessian", messages, fixed = TRUE)),
      singular = lme4::isSingular(model, tol = 1e-5),
      max_gradient = max_gradient,
      convergence_message = if (is.null(messages)) {
        NA_character_
      } else {
        paste(messages, collapse = " | ")
      }
    ))
  }
  if (inherits(model, "glmmTMB")) {
    return(tibble::tibble(
      converged = identical(model$fit$convergence, 0L),
      positive_definite_hessian = isTRUE(model$sdr$pdHess),
      singular = tryCatch(
        performance::check_singularity(model, tolerance = 1e-5),
        error = function(condition) NA
      ),
      max_gradient = NA_real_,
      convergence_message = if (
        identical(model$fit$convergence, 0L) && isTRUE(model$sdr$pdHess)
      ) {
        NA_character_
      } else {
        paste(
          model$fit$message,
          if (!isTRUE(model$sdr$pdHess)) "non-positive-definite Hessian",
          collapse = " | "
        )
      }
    ))
  }
  h08_abort("Unsupported H08 model class: %s", class(model)[1L])
}

h08_fixed_effects <- function(model) {
  if (inherits(model, "glmmTMB")) {
    return(glmmTMB::fixef(model)$cond)
  }
  if (inherits(model, "merMod")) {
    return(lme4::fixef(model))
  }
  stats::coef(model)
}

h08_fixed_vcov <- function(model) {
  if (inherits(model, "glmmTMB")) {
    return(as.matrix(stats::vcov(model)$cond))
  }
  as.matrix(stats::vcov(model))
}

h08_fixed_model_matrix <- function(model) {
  if (inherits(model, "glmmTMB")) {
    return(stats::model.matrix(model, component = "cond"))
  }
  stats::model.matrix(model)
}

h08_model_condition <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      fixed_columns = NA_integer_,
      fixed_rank = NA_integer_,
      fixed_full_rank = NA,
      fixed_condition_number = NA_real_
    ))
  }
  matrix <- h08_fixed_model_matrix(model)
  rank <- qr(matrix)$rank
  tibble::tibble(
    fixed_columns = ncol(matrix),
    fixed_rank = rank,
    fixed_full_rank = rank == ncol(matrix),
    fixed_condition_number = tryCatch(
      kappa(matrix, exact = TRUE),
      error = function(condition) NA_real_
    )
  )
}

h08_nested_test <- function(reduced_fit, full_fit, comparison_id) {
  reduced <- reduced_fit$model
  full <- full_fit$model
  empty <- tibble::tibble(
    comparison_id = comparison_id,
    statistic = NA_real_,
    df = NA_real_,
    p_raw = NA_real_,
    log_lik_reduced = NA_real_,
    log_lik_full = NA_real_,
    n_obs_reduced = if (is.null(reduced)) NA_integer_ else stats::nobs(reduced),
    n_obs_full = if (is.null(full)) NA_integer_ else stats::nobs(full),
    comparison_status = "NON_ESTIMABLE"
  )
  if (is.null(reduced) || is.null(full)) return(empty)
  if (stats::nobs(reduced) != stats::nobs(full)) {
    empty$comparison_status <- "FAIL_SAMPLE_MISMATCH"
    return(empty)
  }
  reduced_log_lik <- tryCatch(stats::logLik(reduced), error = function(e) NULL)
  full_log_lik <- tryCatch(stats::logLik(full), error = function(e) NULL)
  if (is.null(reduced_log_lik) || is.null(full_log_lik)) return(empty)
  df <- attr(full_log_lik, "df") - attr(reduced_log_lik, "df")
  statistic <- 2 * (as.numeric(full_log_lik) - as.numeric(reduced_log_lik))
  if (!is.finite(statistic) || !is.finite(df) || df <= 0) return(empty)
  statistic <- max(statistic, 0)
  tibble::tibble(
    comparison_id = comparison_id,
    statistic = statistic,
    df = df,
    p_raw = stats::pchisq(statistic, df = df, lower.tail = FALSE),
    log_lik_reduced = as.numeric(reduced_log_lik),
    log_lik_full = as.numeric(full_log_lik),
    n_obs_reduced = stats::nobs(reduced),
    n_obs_full = stats::nobs(full),
    comparison_status = "PASS"
  )
}

h08_bundle_tests <- function(bundle, inferential) {
  if (!isTRUE(inferential)) {
    return(tibble::tibble(
      comparison_id = c("average_vlsq", "site_heterogeneity"),
      statistic = NA_real_,
      df = NA_real_,
      p_raw = NA_real_,
      log_lik_reduced = NA_real_,
      log_lik_full = NA_real_,
      n_obs_reduced = NA_integer_,
      n_obs_full = NA_integer_,
      comparison_status = "NOT_INFERENTIAL"
    ))
  }
  dplyr::bind_rows(
    h08_nested_test(
      bundle$fits$site_only,
      bundle$fits$additive,
      "average_vlsq"
    ),
    h08_nested_test(
      bundle$fits$additive,
      bundle$fits$interaction,
      "site_heterogeneity"
    )
  )
}

h08_empty_effect <- function(status = "NON_ESTIMABLE") {
  tibble::tibble(
    estimate_model_per_point = NA_real_,
    std_error_model_per_point = NA_real_,
    conf_low_model_per_point = NA_real_,
    conf_high_model_per_point = NA_real_,
    estimate_practical_per_point = NA_real_,
    conf_low_practical_per_point = NA_real_,
    conf_high_practical_per_point = NA_real_,
    estimate_model_per_sd = NA_real_,
    std_error_model_per_sd = NA_real_,
    conf_low_model_per_sd = NA_real_,
    conf_high_model_per_sd = NA_real_,
    estimate_practical_per_sd = NA_real_,
    conf_low_practical_per_sd = NA_real_,
    conf_high_practical_per_sd = NA_real_,
    effect_type = NA_character_,
    interval_method = "wald_normal",
    effect_status = status
  )
}

h08_effect_summary <- function(model, spec, score_sd) {
  if (is.null(model)) return(h08_empty_effect())
  coefficients <- h08_fixed_effects(model)
  covariance <- h08_fixed_vcov(model)
  term <- "VLSQ8_c"
  if (!term %in% names(coefficients) || !term %in% rownames(covariance)) {
    return(h08_empty_effect("TERM_NOT_ESTIMABLE"))
  }
  estimate <- unname(coefficients[[term]])
  standard_error <- sqrt(covariance[term, term])
  if (!is.finite(estimate) || !is.finite(standard_error)) {
    return(h08_empty_effect("NON_FINITE"))
  }
  critical <- stats::qnorm(0.975)
  low <- estimate - critical * standard_error
  high <- estimate + critical * standard_error
  practical <- h08_transform_effect(estimate, low, high, spec)
  estimate_sd <- estimate * score_sd
  standard_error_sd <- standard_error * score_sd
  low_sd <- estimate_sd - critical * standard_error_sd
  high_sd <- estimate_sd + critical * standard_error_sd
  practical_sd <- h08_transform_effect(estimate_sd, low_sd, high_sd, spec)
  tibble::tibble(
    estimate_model_per_point = estimate,
    std_error_model_per_point = standard_error,
    conf_low_model_per_point = low,
    conf_high_model_per_point = high,
    estimate_practical_per_point = practical$estimate_practical,
    conf_low_practical_per_point = practical$conf_low_practical,
    conf_high_practical_per_point = practical$conf_high_practical,
    estimate_model_per_sd = estimate_sd,
    std_error_model_per_sd = standard_error_sd,
    conf_low_model_per_sd = low_sd,
    conf_high_model_per_sd = high_sd,
    estimate_practical_per_sd = practical_sd$estimate_practical,
    conf_low_practical_per_sd = practical_sd$conf_low_practical,
    conf_high_practical_per_sd = practical_sd$conf_high_practical,
    effect_type = practical$effect_type,
    interval_method = "wald_normal",
    effect_status = "PASS"
  )
}

h08_newdata_model_matrix <- function(model, newdata) {
  formula <- reformulas::nobars(stats::formula(model))
  terms <- stats::delete.response(stats::terms(formula))
  matrix <- stats::model.matrix(
    terms,
    data = newdata,
    contrasts.arg = list(
      site = stats::contr.sum(nlevels(newdata$site))
    )
  )
  coefficients <- h08_fixed_effects(model)
  missing <- setdiff(names(coefficients), colnames(matrix))
  extra <- setdiff(colnames(matrix), names(coefficients))
  if (length(missing) > 0L || length(extra) > 0L) {
    h08_abort(
      "H08 new-data model matrix does not match fitted coefficients; missing=%s; extra=%s",
      paste(missing, collapse = ","),
      paste(extra, collapse = ",")
    )
  }
  matrix[, names(coefficients), drop = FALSE]
}

h08_site_slopes <- function(model, frame, spec, score_sd) {
  sites <- levels(frame$site)
  if (is.null(model)) {
    return(tibble::tibble(
      site = sites,
      estimate_model_per_point = NA_real_,
      std_error_model_per_point = NA_real_,
      conf_low_model_per_point = NA_real_,
      conf_high_model_per_point = NA_real_,
      estimate_practical_per_point = NA_real_,
      conf_low_practical_per_point = NA_real_,
      conf_high_practical_per_point = NA_real_,
      estimate_practical_per_sd = NA_real_,
      conf_low_practical_per_sd = NA_real_,
      conf_high_practical_per_sd = NA_real_,
      effect_type = NA_character_,
      interval_method = "wald_normal",
      slope_status = "NON_ESTIMABLE"
    ))
  }
  base <- data.frame(
    site = factor(sites, levels = sites),
    VLSQ8_c = 0,
    photoperiod_c = 0,
    Id = factor(as.character(frame$Id[1L]), levels = levels(frame$Id))
  )
  one <- base
  one$VLSQ8_c <- 1
  contrast_matrix <- h08_newdata_model_matrix(model, one) -
    h08_newdata_model_matrix(model, base)
  coefficients <- h08_fixed_effects(model)
  covariance <- h08_fixed_vcov(model)
  estimate <- as.numeric(contrast_matrix %*% coefficients)
  standard_error <- sqrt(rowSums(
    (contrast_matrix %*% covariance) * contrast_matrix
  ))
  critical <- stats::qnorm(0.975)
  low <- estimate - critical * standard_error
  high <- estimate + critical * standard_error
  practical <- h08_transform_effect(estimate, low, high, spec)
  practical_sd <- h08_transform_effect(
    estimate * score_sd,
    low * score_sd,
    high * score_sd,
    spec
  )
  tibble::tibble(
    site = sites,
    estimate_model_per_point = estimate,
    std_error_model_per_point = standard_error,
    conf_low_model_per_point = low,
    conf_high_model_per_point = high,
    estimate_practical_per_point = practical$estimate_practical,
    conf_low_practical_per_point = practical$conf_low_practical,
    conf_high_practical_per_point = practical$conf_high_practical,
    estimate_practical_per_sd = practical_sd$estimate_practical,
    conf_low_practical_per_sd = practical_sd$conf_low_practical,
    conf_high_practical_per_sd = practical_sd$conf_high_practical,
    effect_type = practical$effect_type,
    interval_method = "wald_normal",
    slope_status = ifelse(
      is.finite(estimate) & is.finite(standard_error),
      "PASS",
      "NON_ESTIMABLE"
    )
  )
}

h08_natural_mean_and_gradient <- function(matrix, coefficients, spec) {
  eta <- as.numeric(matrix %*% coefficients)
  if (spec$response_family == "tweedie_log") {
    value <- exp(eta)
    derivative <- value
  } else if (spec$response_transform == "log10_offset_0.1") {
    value <- 10^eta - 0.1
    derivative <- log(10) * 10^eta
  } else {
    value <- eta
    derivative <- rep(1, length(eta))
  }
  list(
    estimate = mean(value),
    gradient = colMeans(matrix * derivative)
  )
}

h08_centered_predictions <- function(model, frame, spec, score_sd) {
  if (is.null(model)) return(tibble::tibble())
  sites <- levels(frame$site)
  points <- c(-0.5 * score_sd, 0.5 * score_sd)
  labels <- c("centre_minus_half_sd", "centre_plus_half_sd")
  coefficients <- h08_fixed_effects(model)
  covariance <- h08_fixed_vcov(model)
  rows <- lapply(seq_along(points), function(index) {
    newdata <- data.frame(
      site = factor(sites, levels = sites),
      VLSQ8_c = points[[index]],
      photoperiod_c = 0,
      Id = factor(as.character(frame$Id[1L]), levels = levels(frame$Id))
    )
    matrix <- h08_newdata_model_matrix(model, newdata)
    estimate <- h08_natural_mean_and_gradient(matrix, coefficients, spec)
    standard_error <- sqrt(
      drop(estimate$gradient %*% covariance %*% estimate$gradient)
    )
    low <- estimate$estimate - stats::qnorm(0.975) * standard_error
    high <- estimate$estimate + stats::qnorm(0.975) * standard_error
    if (is.finite(spec$lower_bound)) low <- max(low, spec$lower_bound)
    tibble::tibble(
      prediction_id = labels[[index]],
      VLSQ8_c = points[[index]],
      VLSQ8 = points[[index]] + 21.5978260869565,
      estimate = estimate$estimate,
      std_error = standard_error,
      conf_low = low,
      conf_high = high,
      interval_method = "delta_normal; physical lower bound applied"
    )
  })
  dplyr::bind_rows(rows)
}

h08_random_effect_sd <- function(model) {
  if (is.null(model)) return(NA_real_)
  tryCatch(
    {
      if (inherits(model, "glmmTMB")) {
        variance <- as.data.frame(glmmTMB::VarCorr(model)$cond)
      } else if (inherits(model, "merMod")) {
        variance <- as.data.frame(lme4::VarCorr(model))
      } else {
        return(NA_real_)
      }
      value <- variance$sdcor[variance$var1 == "(Intercept)"][1L]
      if (length(value) == 0L) NA_real_ else as.numeric(value)
    },
    error = function(condition) NA_real_
  )
}

h08_serial_diagnostic <- function(residual, frame) {
  data <- tibble::tibble(
    participant_key = as.character(frame$participant_key),
    local_date = as.Date(frame$local_date),
    residual = as.numeric(residual)
  ) |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      previous_residual = dplyr::lag(.data$residual),
      previous_date = dplyr::lag(.data$local_date),
      date_lag_days = as.numeric(.data$local_date - .data$previous_date)
    ) |>
    dplyr::ungroup()
  consecutive <- data |>
    dplyr::filter(
      .data$date_lag_days == 1,
      is.finite(.data$residual),
      is.finite(.data$previous_residual)
    )
  pooled <- if (nrow(consecutive) >= 3L) {
    suppressWarnings(stats::cor(
      consecutive$residual,
      consecutive$previous_residual
    ))
  } else {
    NA_real_
  }
  tibble::tibble(
    consecutive_day_pairs = nrow(consecutive),
    participants_with_consecutive_pairs = dplyr::n_distinct(
      consecutive$participant_key
    ),
    pooled_consecutive_day_residual_correlation = pooled,
    serial_status = if (is.finite(pooled) && abs(pooled) >= 0.3) {
      "REVIEW_ABSOLUTE_CORRELATION_AT_LEAST_0.30"
    } else if (nrow(consecutive) < 3L) {
      "LIMITED_SUPPORT"
    } else {
      "PASS_DESCRIPTIVE_CHECK"
    }
  )
}

h08_tweedie_zero_diagnostic <- function(model, observed) {
  empty <- tibble::tibble(
    tweedie_power = NA_real_,
    dispersion = NA_real_,
    observed_zero_n = sum(observed == 0, na.rm = TRUE),
    observed_zero_fraction = mean(observed == 0, na.rm = TRUE),
    expected_zero_n = NA_real_,
    expected_zero_fraction = NA_real_,
    zero_mass_standardized_difference = NA_real_,
    zero_mass_method = "not applicable",
    zero_mass_status = "NOT_APPLICABLE"
  )
  if (is.null(model) || !inherits(model, "glmmTMB")) return(empty)
  power <- tryCatch(
    glmmTMB::family_params(model)[[1L]],
    error = function(e) NA_real_
  )
  dispersion <- tryCatch(stats::sigma(model), error = function(e) NA_real_)
  mu <- tryCatch(
    stats::fitted(model),
    error = function(e) rep(NA_real_, length(observed))
  )
  if (
    !is.finite(power) ||
      power <= 1 ||
      power >= 2 ||
      !is.finite(dispersion) ||
      dispersion <= 0 ||
      any(!is.finite(mu)) ||
      any(mu <= 0)
  ) {
    empty$zero_mass_status <- "NON_ESTIMABLE"
    return(empty)
  }
  probability_zero <- exp(-(mu^(2 - power)) / (dispersion * (2 - power)))
  expected <- sum(probability_zero)
  variance <- sum(probability_zero * (1 - probability_zero))
  standardized <- if (variance > 0) {
    (sum(observed == 0) - expected) / sqrt(variance)
  } else {
    NA_real_
  }
  tibble::tibble(
    tweedie_power = power,
    dispersion = dispersion,
    observed_zero_n = sum(observed == 0),
    observed_zero_fraction = mean(observed == 0),
    expected_zero_n = expected,
    expected_zero_fraction = mean(probability_zero),
    zero_mass_standardized_difference = standardized,
    zero_mass_method = paste0(
      "Analytical compound-Poisson zero probability; no simulation or resampling"
    ),
    zero_mass_status = if (
      is.finite(standardized) && abs(standardized) >= 3.29
    ) {
      "REVIEW_ABSOLUTE_STANDARDIZED_DIFFERENCE_AT_LEAST_3.29"
    } else {
      "PASS_DESCRIPTIVE_CHECK"
    }
  )
}

h08_prediction_bounds <- function(model, frame, spec) {
  if (is.null(model)) {
    return(tibble::tibble(
      fitted_natural_min = NA_real_,
      fitted_natural_max = NA_real_,
      fitted_below_lower_n = NA_integer_,
      fitted_above_upper_n = NA_integer_,
      observed_above_audit_threshold_n = NA_integer_,
      prediction_bound_status = "NON_ESTIMABLE"
    ))
  }
  fitted_model <- as.numeric(stats::fitted(model))
  fitted_natural <- if (inherits(model, "glmmTMB")) {
    fitted_model
  } else {
    h08_back_transform_response(fitted_model, spec)
  }
  below <- if (is.finite(spec$lower_bound)) {
    sum(fitted_natural < spec$lower_bound - 1e-8, na.rm = TRUE)
  } else {
    NA_integer_
  }
  above <- if (is.finite(spec$upper_bound)) {
    sum(fitted_natural > spec$upper_bound + 1e-8, na.rm = TRUE)
  } else {
    NA_integer_
  }
  audit_above <- if (is.finite(spec$audit_upper_threshold)) {
    sum(frame$value > spec$audit_upper_threshold, na.rm = TRUE)
  } else {
    NA_integer_
  }
  tibble::tibble(
    fitted_natural_min = min(fitted_natural, na.rm = TRUE),
    fitted_natural_max = max(fitted_natural, na.rm = TRUE),
    fitted_below_lower_n = below,
    fitted_above_upper_n = above,
    observed_above_audit_threshold_n = audit_above,
    prediction_bound_status = if (
      (!is.na(below) && below > 0L) || (!is.na(above) && above > 0L)
    ) {
      "REVIEW_PREDICTION_OUTSIDE_PHYSICAL_BOUND"
    } else if (!is.na(audit_above) && audit_above > 0L) {
      "REVIEW_OBSERVED_ABOVE_AUDIT_THRESHOLD"
    } else {
      "PASS"
    }
  )
}

h08_model_diagnostics <- function(bundle, frame) {
  additive_fit <- bundle$fits$additive
  interaction_fit <- bundle$fits$interaction
  model <- additive_fit$model
  additive_status <- h08_model_fit_status(model)
  interaction_status <- h08_model_fit_status(interaction_fit$model)
  additive_condition <- h08_model_condition(model)
  interaction_condition <- h08_model_condition(interaction_fit$model)
  if (is.null(model)) {
    residual <- rep(NA_real_, nrow(frame))
    fitted <- rep(NA_real_, nrow(frame))
  } else {
    residual <- tryCatch(
      as.numeric(stats::residuals(model, type = "pearson")),
      error = function(condition) as.numeric(stats::residuals(model))
    )
    fitted <- as.numeric(stats::fitted(model))
  }
  finite <- is.finite(residual) & is.finite(fitted)
  qq_correlation <- if (sum(finite) >= 3L) {
    observed <- sort(residual[finite])
    theoretical <- stats::qnorm(stats::ppoints(length(observed)))
    suppressWarnings(stats::cor(observed, theoretical))
  } else {
    NA_real_
  }
  residual_fitted_correlation <- if (sum(finite) >= 3L) {
    suppressWarnings(stats::cor(
      abs(residual[finite]),
      fitted[finite],
      method = "spearman"
    ))
  } else {
    NA_real_
  }
  residual_skewness <- if (
    sum(finite) >= 3L && stats::sd(residual[finite]) > 0
  ) {
    mean((residual[finite] - mean(residual[finite]))^3) /
      stats::sd(residual[finite])^3
  } else {
    NA_real_
  }
  residual_summary <- tibble::tibble(
    residual_n = sum(finite),
    residual_mean = if (any(finite)) mean(residual[finite]) else NA_real_,
    residual_sd = if (sum(finite) >= 2L) stats::sd(residual[finite]) else
      NA_real_,
    residual_skewness = residual_skewness,
    residual_qq_correlation = qq_correlation,
    residual_absolute_fitted_spearman = residual_fitted_correlation,
    residual_absolute_above_3_fraction = if (any(finite)) {
      mean(abs(residual[finite]) > 3)
    } else {
      NA_real_
    }
  )
  serial <- if (any(finite)) {
    h08_serial_diagnostic(residual, frame)
  } else {
    tibble::tibble(
      consecutive_day_pairs = 0L,
      participants_with_consecutive_pairs = 0L,
      pooled_consecutive_day_residual_correlation = NA_real_,
      serial_status = "NON_ESTIMABLE"
    )
  }
  zeros <- h08_tweedie_zero_diagnostic(model, frame$value)
  bounds <- h08_prediction_bounds(model, frame, bundle$spec)
  fit_warnings <- paste(additive_fit$warnings, collapse = " | ")
  interaction_warnings <- paste(interaction_fit$warnings, collapse = " | ")
  major_failure <-
    is.null(model) ||
    !isTRUE(additive_status$converged) ||
    !isTRUE(additive_status$positive_definite_hessian) ||
    !isTRUE(additive_condition$fixed_full_rank)
  interaction_failure <-
    is.null(interaction_fit$model) ||
    !isTRUE(interaction_status$converged) ||
    !isTRUE(interaction_status$positive_definite_hessian) ||
    !isTRUE(interaction_condition$fixed_full_rank) ||
    (is.finite(interaction_condition$fixed_condition_number) &&
      interaction_condition$fixed_condition_number >= 1e8)
  review <-
    isTRUE(additive_status$singular) ||
    (is.finite(qq_correlation) && qq_correlation < 0.95) ||
    (is.finite(residual_fitted_correlation) &&
      abs(residual_fitted_correlation) >= 0.3) ||
    startsWith(serial$serial_status, "REVIEW") ||
    startsWith(zeros$zero_mass_status, "REVIEW") ||
    startsWith(bounds$prediction_bound_status, "REVIEW") ||
    nzchar(fit_warnings)
  issue_codes <- c(
    if (major_failure) "ADDITIVE_NUMERICAL_GATE",
    if (interaction_failure) "INTERACTION_NON_ESTIMABLE_OR_UNSTABLE",
    if (isTRUE(additive_status$singular)) "RANDOM_INTERCEPT_BOUNDARY",
    if (is.finite(qq_correlation) && qq_correlation < 0.95)
      "RESIDUAL_QQ_REVIEW",
    if (
      is.finite(residual_fitted_correlation) &&
        abs(residual_fitted_correlation) >= 0.3
    )
      "RESIDUAL_SPREAD_REVIEW",
    if (startsWith(serial$serial_status, "REVIEW")) "SERIAL_DEPENDENCE_REVIEW",
    if (startsWith(zeros$zero_mass_status, "REVIEW")) "ZERO_MASS_REVIEW",
    if (startsWith(bounds$prediction_bound_status, "REVIEW")) "BOUND_REVIEW",
    if (nzchar(fit_warnings)) "ADDITIVE_FIT_WARNING",
    if (nzchar(interaction_warnings)) "INTERACTION_FIT_WARNING"
  )
  dplyr::bind_cols(
    additive_status |>
      dplyr::rename_with(~ paste0("additive_", .x)),
    additive_condition |>
      dplyr::rename_with(~ paste0("additive_", .x)),
    interaction_status |>
      dplyr::rename_with(~ paste0("interaction_", .x)),
    interaction_condition |>
      dplyr::rename_with(~ paste0("interaction_", .x)),
    residual_summary,
    serial,
    zeros,
    bounds,
    tibble::tibble(
      participant_random_intercept_sd = h08_random_effect_sd(model),
      additive_fit_warnings = fit_warnings,
      additive_fit_error = additive_fit$error,
      interaction_fit_warnings = interaction_warnings,
      interaction_fit_error = interaction_fit$error,
      average_effect_status = if (major_failure) "NON_ESTIMABLE" else
        "ESTIMABLE",
      interaction_effect_status = if (interaction_failure) {
        "NON_ESTIMABLE_OR_UNSTABLE"
      } else {
        "ESTIMABLE"
      },
      diagnostic_status = if (major_failure) {
        "FAIL_MAJOR_GATE"
      } else if (review || interaction_failure) {
        "REVIEW_WITH_LIMITATIONS"
      } else {
        "PASS"
      },
      diagnostic_issues = if (length(issue_codes) == 0L) {
        NA_character_
      } else {
        paste(unique(issue_codes), collapse = " | ")
      }
    )
  )
}

h08_diagnostic_plot_data <- function(model, frame) {
  if (is.null(model)) return(tibble::tibble())
  residual <- tryCatch(
    as.numeric(stats::residuals(model, type = "pearson")),
    error = function(condition) as.numeric(stats::residuals(model))
  )
  fitted <- as.numeric(stats::fitted(model))
  rank <- rank(residual, ties.method = "average", na.last = "keep")
  theoretical <- stats::qnorm((rank - 0.5) / sum(is.finite(residual)))
  tibble::tibble(
    model_row_id = frame$.model_row_id,
    site = as.character(frame$site),
    participant_key = as.character(frame$participant_key),
    local_date = frame$local_date,
    fitted_model_scale = fitted,
    residual_pearson = residual,
    qq_theoretical = theoretical,
    qq_observed = residual
  )
}

h08_model_manifest_rows <- function(bundle) {
  dplyr::bind_rows(lapply(names(bundle$fits), function(model_name) {
    fit <- bundle$fits[[model_name]]
    model <- fit$model
    status <- h08_model_fit_status(model)
    condition <- h08_model_condition(model)
    dplyr::bind_cols(
      tibble::tibble(
        model_name = model_name,
        formula = paste(deparse(bundle$formulas[[model_name]]), collapse = " "),
        engine = if (is.null(model)) NA_character_ else class(model)[1L],
        observations = if (is.null(model)) NA_integer_ else stats::nobs(model),
        log_likelihood = if (is.null(model)) {
          NA_real_
        } else {
          as.numeric(stats::logLik(model))
        },
        aic = if (is.null(model)) NA_real_ else stats::AIC(model),
        warnings = paste(fit$warnings, collapse = " | "),
        error = fit$error,
        fit_status = if (is.null(model)) "NOT_FITTED" else "FITTED"
      ),
      status,
      condition
    )
  }))
}

h08_participant_influence_screen <- function(model, frame, n = 5L) {
  if (is.null(model) || nrow(frame) == 0L) return(tibble::tibble())
  residual <- tryCatch(
    as.numeric(stats::residuals(model, type = "pearson")),
    error = function(condition) as.numeric(stats::residuals(model))
  )
  tibble::tibble(
    participant_key = as.character(frame$participant_key),
    site = as.character(frame$site),
    VLSQ8 = frame$VLSQ8,
    residual = residual
  ) |>
    dplyr::group_by(.data$participant_key, .data$site) |>
    dplyr::summarise(
      VLSQ8 = dplyr::first(.data$VLSQ8),
      participant_days = dplyr::n(),
      mean_pearson_residual = mean(.data$residual, na.rm = TRUE),
      maximum_absolute_pearson_residual = max(
        abs(.data$residual),
        na.rm = TRUE
      ),
      rms_pearson_residual = sqrt(mean(.data$residual^2, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(.data$maximum_absolute_pearson_residual)) |>
    dplyr::slice_head(n = n) |>
    dplyr::mutate(
      screen_rank = dplyr::row_number(),
      influence_screen = "maximum absolute Pearson residual; descriptive screen"
    )
}

h08_leave_one_site_out <- function(frame, spec, score_sd, full_estimate) {
  sites <- levels(frame$site)
  dplyr::bind_rows(lapply(sites, function(omitted_site) {
    subset <- frame[as.character(frame$site) != omitted_site, , drop = FALSE]
    subset$site <- droplevels(subset$site)
    subset$Id <- droplevels(subset$Id)
    subset$participant_key <- droplevels(subset$participant_key)
    stats::contrasts(subset$site) <- stats::contr.sum(nlevels(subset$site))
    formula <- h08_formula_set("participant_day")$additive
    fit <- h08_fit_model(subset, formula, spec)
    status <- h08_model_fit_status(fit$model)
    effect <- h08_effect_summary(fit$model, spec, score_sd)
    estimate <- effect$estimate_model_per_point
    tibble::tibble(
      omitted_site = omitted_site,
      observations = nrow(subset),
      participants = dplyr::n_distinct(subset$participant_key),
      sites = nlevels(subset$site),
      estimate_model_per_point = estimate,
      conf_low_model_per_point = effect$conf_low_model_per_point,
      conf_high_model_per_point = effect$conf_high_model_per_point,
      estimate_practical_per_sd = effect$estimate_practical_per_sd,
      conf_low_practical_per_sd = effect$conf_low_practical_per_sd,
      conf_high_practical_per_sd = effect$conf_high_practical_per_sd,
      estimate_change_from_full = estimate - full_estimate,
      relative_absolute_change = if (
        is.finite(full_estimate) && abs(full_estimate) > 1e-12
      ) {
        abs((estimate - full_estimate) / full_estimate)
      } else {
        NA_real_
      },
      sign_reversal = if (
        is.finite(estimate) && is.finite(full_estimate) && full_estimate != 0
      ) {
        sign(estimate) != sign(full_estimate)
      } else {
        NA
      },
      converged = status$converged,
      positive_definite_hessian = status$positive_definite_hessian,
      singular = status$singular,
      warnings = paste(fit$warnings, collapse = " | "),
      error = fit$error,
      refit_status = if (
        is.null(fit$model) ||
          !isTRUE(status$converged) ||
          !isTRUE(status$positive_definite_hessian)
      ) {
        "UNSTABLE_OR_NON_ESTIMABLE"
      } else {
        "PASS"
      }
    )
  }))
}

h08_load_v0_metrics <- function(path) {
  environment <- new.env(parent = emptyenv())
  object_names <- load(path, envir = environment)
  if (length(object_names) != 1L) {
    h08_abort("Unexpected number of V0 objects in `%s`", path)
  }
  object <- environment[[object_names[[1L]]]]
  if (
    !is.data.frame(object) ||
      !all(c("name", "data", "metric_type") %in% names(object))
  ) {
    h08_abort("Unexpected V0 metric object in `%s`", path)
  }
  object
}

h08_v0_fit_model <- function(frame, formula, engine) {
  if (engine == "lmer") {
    return(h08_capture_fit(lme4::lmer(formula = formula, data = frame)))
  }
  h08_capture_fit(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    family = glmmTMB::tweedie(link = "log")
  ))
}

h08_v0_comparison <- function(reduced_fit, full_fit) {
  if (is.null(reduced_fit$model) || is.null(full_fit$model)) {
    return(tibble::tibble(
      statistic = NA_real_,
      df = NA_real_,
      p_raw = NA_real_,
      status = "NON_ESTIMABLE"
    ))
  }
  comparison <- tryCatch(
    stats::anova(reduced_fit$model, full_fit$model),
    error = function(condition) condition
  )
  if (inherits(comparison, "error")) {
    return(tibble::tibble(
      statistic = NA_real_,
      df = NA_real_,
      p_raw = NA_real_,
      status = "NON_ESTIMABLE"
    ))
  }
  p_column <- "Pr(>Chisq)"
  statistic_column <- if ("Chisq" %in% names(comparison)) "Chisq" else
    NA_character_
  tibble::tibble(
    statistic = if (is.na(statistic_column)) NA_real_ else {
      as.numeric(comparison[[statistic_column]][2L])
    },
    df = if ("Chi Df" %in% names(comparison)) {
      as.numeric(comparison[["Chi Df"]][2L])
    } else {
      NA_real_
    },
    p_raw = if (p_column %in% names(comparison)) {
      as.numeric(comparison[[p_column]][2L])
    } else {
      NA_real_
    },
    status = if (p_column %in% names(comparison)) "PASS" else "NON_ESTIMABLE"
  )
}

h08_reproduce_v0_placement <- function(path, placement, vlsq, metric_registry) {
  v0 <- h08_load_v0_metrics(path) |>
    dplyr::inner_join(
      metric_registry |>
        dplyr::select(
          .data$metric_order,
          .data$metric_id,
          .data$manuscript_name,
          .data$v0_name
        ),
      by = c("name" = "v0_name"),
      relationship = "one-to-one"
    ) |>
    dplyr::arrange(.data$metric_order)
  if (nrow(v0) != 9L) {
    h08_abort(
      "V0 `%s` reconstruction does not contain nine H08 metrics",
      placement
    )
  }
  formulas <- h08_v0_formula_set()
  log_metrics <- c(
    "daily_geometric_mean_medi",
    "m10_mean_medi",
    "l10_mean_medi",
    "longest_bout_above_250",
    "dose_time_sensitive_corrected_medi"
  )
  result_rows <- vector("list", nrow(v0))
  model_rows <- vector("list", nrow(v0))
  model_objects <- vector("list", nrow(v0))
  for (index in seq_len(nrow(v0))) {
    row <- v0[index, , drop = FALSE]
    frame <- row$data[[1L]] |>
      dplyr::left_join(
        vlsq |>
          dplyr::select(.data$site, .data$Id, .data$VLSQ8),
        by = c("site", "Id"),
        relationship = "many-to-one"
      ) |>
      dplyr::filter(is.finite(.data$metric), is.finite(.data$VLSQ8)) |>
      dplyr::mutate(
        response_value = if (row$metric_id %in% log_metrics) {
          log10(.data$metric + 0.1)
        } else {
          .data$metric
        }
      )
    engine <- if (
      row$metric_id %in%
        c(
          "duration_above_1000",
          "duration_above_250_wake",
          "duration_below_10_pre_sleep",
          "duration_below_1_sleep_environment"
        )
    ) {
      "glmmTMB"
    } else {
      "lmer"
    }
    fits <- lapply(formulas, function(formula) {
      h08_v0_fit_model(frame, formula, engine)
    })
    association <- h08_v0_comparison(fits$site_only, fits$full)
    interaction <- h08_v0_comparison(fits$additive, fits$full)
    site <- h08_v0_comparison(fits$vlsq_only, fits$additive)
    scalar_adjusted <- if (is.finite(association$p_raw)) {
      stats::p.adjust(association$p_raw, method = "fdr", n = 9L)
    } else {
      NA_real_
    }
    result_rows[[index]] <- dplyr::bind_cols(
      tibble::tibble(
        placement = placement,
        metric_order = row$metric_order,
        metric_id = row$metric_id,
        manuscript_name = row$manuscript_name,
        v0_name = row$name,
        engine = engine,
        participants = dplyr::n_distinct(frame$site, frame$Id),
        participant_days = nrow(frame),
        sites = dplyr::n_distinct(frame$site),
        association_scalar_adjusted_p = scalar_adjusted
      ),
      association |>
        dplyr::rename_with(~ paste0("association_", .x)),
      interaction |>
        dplyr::rename_with(~ paste0("interaction_", .x)),
      site |>
        dplyr::rename_with(~ paste0("site_", .x))
    )
    model_rows[[index]] <- frame |>
      dplyr::transmute(
        placement = placement,
        metric_id = row$metric_id,
        site = .data$site,
        Id = .data$Id,
        Date = if ("Date" %in% names(frame)) .data$Date else as.Date(NA),
        metric = .data$metric,
        VLSQ8 = .data$VLSQ8,
        response_value = .data$response_value
      )
    model_objects[[index]] <- fits
    names(model_objects)[[index]] <- paste(placement, row$metric_id, sep = "__")
  }
  results <- dplyr::bind_rows(result_rows) |>
    dplyr::group_by(.data$placement) |>
    dplyr::mutate(
      consistent_vector_bh_p = stats::p.adjust(
        .data$association_p_raw,
        method = "BH",
        n = 9L
      )
    ) |>
    dplyr::ungroup()
  list(
    results = results,
    model_rows = dplyr::bind_rows(model_rows),
    models = model_objects
  )
}
