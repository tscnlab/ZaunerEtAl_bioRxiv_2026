# H06-daily bounded Stage 2 model pilots and diagnostics.

h06d_capture <- function(expression) {
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  value <- tryCatch(
    withCallingHandlers(
      expression,
      warning = function(condition) {
        warnings <<- c(warnings, conditionMessage(condition))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(condition) condition
  )
  elapsed <- proc.time()[["elapsed"]] - started
  list(
    value = if (inherits(value, "error")) NULL else value,
    error = if (inherits(value, "error")) conditionMessage(value) else NA_character_,
    warnings = unique(warnings),
    elapsed_seconds = unname(elapsed)
  )
}

h06d_prepare_daily_response <- function(frame, response_transform) {
  output <- frame |>
    dplyr::mutate(
      response_value = h06d_transform_response(
        .data$response_source,
        response_transform
      ),
      site = droplevels(.data$site),
      participant_key = droplevels(.data$participant_key),
      work_free_day = droplevels(.data$work_free_day),
      activity_status = droplevels(.data$activity_status)
    )
  if (any(!is.finite(output$response_value))) {
    h06d_abort("A daily pilot response transformation produced nonfinite values")
  }
  if (nlevels(output$site) > 1L) {
    contrasts(output$site) <- stats::contr.sum(nlevels(output$site))
  }
  output
}

h06d_fit_daily_model <- function(frame, formula, response_family) {
  if (response_family == "gaussian") {
    return(h06d_capture(lme4::lmer(
      formula = formula,
      data = frame,
      REML = TRUE,
      control = lme4::lmerControl(
        optimizer = "nloptwrap",
        calc.derivs = TRUE
      )
    )))
  }
  if (response_family == "tweedie_log") {
    return(h06d_capture(glmmTMB::glmmTMB(
      formula = formula,
      data = frame,
      family = glmmTMB::tweedie(link = "log"),
      REML = FALSE,
      control = glmmTMB::glmmTMBControl(
        optCtrl = list(iter.max = 10000L, eval.max = 10000L)
      )
    )))
  }
  if (response_family == "binomial_logit") {
    return(h06d_capture(glmmTMB::glmmTMB(
      formula = formula,
      data = frame,
      family = stats::binomial(link = "logit"),
      REML = FALSE,
      control = glmmTMB::glmmTMBControl(
        optCtrl = list(iter.max = 10000L, eval.max = 10000L)
      )
    )))
  }
  h06d_abort("Unsupported H06-daily pilot family `%s`", response_family)
}

h06d_model_status <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      convergence_message = "fit failed"
    ))
  }
  if (inherits(model, "merMod")) {
    messages <- unlist(model@optinfo$conv$lme4$messages, use.names = FALSE)
    gradient <- model@optinfo$derivs$gradient
    converged <- length(messages) == 0L &&
      (is.null(gradient) || max(abs(gradient)) < 0.002)
    return(tibble::tibble(
      converged = converged,
      positive_definite_hessian = TRUE,
      singular = lme4::isSingular(model, tol = 1e-4),
      convergence_message = if (length(messages)) {
        paste(messages, collapse = " | ")
      } else {
        "full convergence"
      }
    ))
  }
  if (inherits(model, "glmmTMB")) {
    convergence_code <- model$fit$convergence
    pd_hessian <- isTRUE(model$sdr$pdHess)
    return(tibble::tibble(
      converged = identical(as.integer(convergence_code), 0L) && pd_hessian,
      positive_definite_hessian = pd_hessian,
      singular = tryCatch(
        performance::check_singularity(model),
        error = function(condition) NA
      ) |> as.logical(),
      convergence_message = paste(
        model$fit$message %||% "not reported",
        collapse = " | "
      )
    ))
  }
  h06d_abort("Unknown fitted model class")
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

h06d_fixed_table <- function(model) {
  if (inherits(model, "merMod")) {
    estimate <- lme4::fixef(model)
    covariance <- as.matrix(stats::vcov(model))
  } else if (inherits(model, "glmmTMB")) {
    estimate <- glmmTMB::fixef(model)$cond
    covariance <- as.matrix(stats::vcov(model)$cond)
  } else {
    h06d_abort("Cannot extract fixed effects from model class")
  }
  standard_error <- sqrt(diag(covariance))
  tibble::tibble(
    term = names(estimate),
    estimate = unname(estimate),
    standard_error = unname(standard_error),
    lower_95 = estimate - stats::qnorm(0.975) * standard_error,
    upper_95 = estimate + stats::qnorm(0.975) * standard_error
  )
}

h06d_model_predictions <- function(model) {
  if (inherits(model, "merMod")) {
    return(as.numeric(stats::fitted(model)))
  }
  if (inherits(model, "glmmTMB")) {
    return(as.numeric(stats::predict(model, type = "response")))
  }
  rep(NA_real_, stats::nobs(model))
}

h06d_model_residuals <- function(model) {
  if (inherits(model, "merMod")) {
    return(as.numeric(stats::residuals(model, type = "pearson")))
  }
  if (inherits(model, "glmmTMB")) {
    return(as.numeric(stats::residuals(model, type = "pearson")))
  }
  rep(NA_real_, stats::nobs(model))
}

h06d_daily_adjacent_lag <- function(frame, residual) {
  data <- frame |>
    dplyr::mutate(.residual = residual) |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      previous_residual = dplyr::lag(.data$.residual),
      date_gap = as.integer(.data$local_date - dplyr::lag(.data$local_date))
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(
      .data$date_gap == 1L,
      is.finite(.data$.residual),
      is.finite(.data$previous_residual)
    )
  tibble::tibble(
    adjacent_pairs = nrow(data),
    residual_lag1 = if (nrow(data) >= 3L) {
      stats::cor(data$.residual, data$previous_residual)
    } else {
      NA_real_
    }
  )
}

h06d_daily_diagnostic_row <- function(
  fit,
  frame,
  pilot_id,
  model_id,
  response_family,
  response_transform
) {
  status <- h06d_model_status(fit$value)
  if (is.null(fit$value)) {
    return(dplyr::bind_cols(
      tibble::tibble(
        pilot_id = pilot_id,
        model_id = model_id,
        response_family = response_family,
        response_transform = response_transform,
        observations = nrow(frame),
        participants = dplyr::n_distinct(frame$participant_key),
        sites = dplyr::n_distinct(frame$site),
        exact_zeros = sum(frame$response_source == 0),
        zero_fraction = mean(frame$response_source == 0),
        elapsed_seconds = fit$elapsed_seconds,
        fit_error = fit$error,
        warnings = paste(fit$warnings, collapse = " | "),
        warning_count = length(fit$warnings),
        residual_lag1 = NA_real_,
        adjacent_pairs = NA_integer_,
        absolute_residual_fitted_spearman = NA_real_,
        transformed_residual_skewness = NA_real_,
        lower_prediction_violations = NA_integer_,
        upper_prediction_violations = NA_integer_
      ),
      status
    ))
  }
  prediction <- h06d_model_predictions(fit$value)
  residual <- h06d_model_residuals(fit$value)
  lag <- h06d_daily_adjacent_lag(frame, residual)
  response_prediction <- if (response_transform == "log10_offset_0.1") {
    10^prediction - 0.1
  } else if (response_transform == "log10_positive") {
    10^prediction
  } else {
    prediction
  }
  upper_bound <- if (pilot_id %in% c("tweedie_duration")) {
    24
  } else if (pilot_id == "gaussian_identity") {
    6
  } else {
    Inf
  }
  centered <- residual - mean(residual, na.rm = TRUE)
  residual_sd <- stats::sd(centered, na.rm = TRUE)
  skewness <- if (is.finite(residual_sd) && residual_sd > 0) {
    mean((centered / residual_sd)^3, na.rm = TRUE)
  } else {
    NA_real_
  }
  dplyr::bind_cols(
    tibble::tibble(
      pilot_id = pilot_id,
      model_id = model_id,
      response_family = response_family,
      response_transform = response_transform,
      observations = nrow(frame),
      participants = dplyr::n_distinct(frame$participant_key),
      sites = dplyr::n_distinct(frame$site),
      exact_zeros = sum(frame$response_source == 0),
      zero_fraction = mean(frame$response_source == 0),
      elapsed_seconds = fit$elapsed_seconds,
      fit_error = fit$error,
      warnings = paste(fit$warnings, collapse = " | "),
      warning_count = length(fit$warnings),
      residual_lag1 = lag$residual_lag1,
      adjacent_pairs = lag$adjacent_pairs,
      absolute_residual_fitted_spearman = suppressWarnings(stats::cor(
        abs(residual),
        prediction,
        method = "spearman",
        use = "complete.obs"
      )),
      transformed_residual_skewness = skewness,
      lower_prediction_violations = sum(response_prediction < -1e-8),
      upper_prediction_violations = if (is.finite(upper_bound)) {
        sum(response_prediction > upper_bound + 1e-8)
      } else {
        0L
      }
    ),
    status
  )
}

h06d_daily_pilot <- function(root, placement = "near_eye") {
  registry <- h06d_daily_pilot_registry()
  diaries <- h06d_load_diaries(root)
  fits <- list()
  diagnostics <- list()
  effects <- list()

  for (index in seq_len(nrow(registry))) {
    entry <- registry[index, ]
    frame <- h06d_daily_frame(
      root = root,
      placement = placement,
      metric_id = entry$metric_id,
      predictor_id = entry$predictor_id,
      diaries = diaries
    ) |>
      h06d_prepare_daily_response(entry$response_transform)
    formulas <- h06d_daily_formula_set(entry$predictor_id)
    model_ids <- if (entry$pilot_id == "gaussian_offset") {
      c(
        "registered_random_site",
        "fixed_site_reduced",
        "fixed_site_additive",
        "fixed_site_heterogeneity"
      )
    } else {
      "fixed_site_additive"
    }
    for (model_id in model_ids) {
      message("Daily pilot: ", entry$pilot_id, " / ", model_id)
      fit <- h06d_fit_daily_model(
        frame,
        formulas[[model_id]],
        entry$response_family
      )
      key <- paste(entry$pilot_id, model_id, sep = "__")
      fits[[key]] <- list(
        frame = frame,
        formula = formulas[[model_id]],
        fit = fit,
        registry = entry
      )
      diagnostics[[key]] <- h06d_daily_diagnostic_row(
        fit,
        frame,
        entry$pilot_id,
        model_id,
        entry$response_family,
        entry$response_transform
      )
      if (!is.null(fit$value) && model_id == "fixed_site_additive") {
        effects[[key]] <- h06d_fixed_table(fit$value) |>
          dplyr::filter(grepl(entry$predictor_id, .data$term, fixed = TRUE)) |>
          dplyr::mutate(
            pilot_id = entry$pilot_id,
            model_id = model_id,
            response_family = entry$response_family,
            response_transform = entry$response_transform,
            display_estimate = dplyr::case_when(
              entry$response_transform == "log10_offset_0.1" ~ 10^.data$estimate,
              entry$response_family == "tweedie_log" ~ exp(.data$estimate),
              TRUE ~ .data$estimate
            ),
            display_lower_95 = dplyr::case_when(
              entry$response_transform == "log10_offset_0.1" ~ 10^.data$lower_95,
              entry$response_family == "tweedie_log" ~ exp(.data$lower_95),
              TRUE ~ .data$lower_95
            ),
            display_upper_95 = dplyr::case_when(
              entry$response_transform == "log10_offset_0.1" ~ 10^.data$upper_95,
              entry$response_family == "tweedie_log" ~ exp(.data$upper_95),
              TRUE ~ .data$upper_95
            ),
            inferential_role =
              "engineering pilot only; not a production estimate"
          )
      }
    }
  }

  l10_entry <- dplyr::filter(registry, .data$pilot_id == "l10_one_part")
  l10_frame <- fits[["l10_one_part__fixed_site_additive"]]$frame
  predictor <- l10_entry$predictor_id[[1L]]
  formulas <- h06d_daily_formula_set(predictor)

  occurrence_frame <- l10_frame |>
    dplyr::mutate(
      response_value = as.integer(.data$response_source == 0)
    )
  occurrence <- h06d_fit_daily_model(
    occurrence_frame,
    formulas$fixed_site_additive,
    "binomial_logit"
  )
  fits[["l10_two_part__zero_occurrence"]] <- list(
    frame = occurrence_frame,
    formula = formulas$fixed_site_additive,
    fit = occurrence
  )
  diagnostics[["l10_two_part__zero_occurrence"]] <-
    h06d_daily_diagnostic_row(
      occurrence,
      occurrence_frame,
      "l10_two_part",
      "zero_occurrence",
      "binomial_logit",
      "identity"
    )

  positive_frame <- l10_frame |>
    dplyr::filter(.data$response_source > 0) |>
    dplyr::mutate(response_value = log10(.data$response_source)) |>
    droplevels()
  positive <- h06d_fit_daily_model(
    positive_frame,
    formulas$fixed_site_additive,
    "gaussian"
  )
  fits[["l10_two_part__positive_magnitude"]] <- list(
    frame = positive_frame,
    formula = formulas$fixed_site_additive,
    fit = positive
  )
  diagnostics[["l10_two_part__positive_magnitude"]] <-
    h06d_daily_diagnostic_row(
      positive,
      positive_frame,
      "l10_two_part",
      "positive_magnitude",
      "gaussian_positive_log10",
      "log10_positive"
    )

  list(
    fits = fits,
    diagnostics = dplyr::bind_rows(diagnostics),
    effects = dplyr::bind_rows(effects),
    registry = registry
  )
}

h06d_boundary_lag_correlation <- function(residual, AR_start, lag = 1L) {
  sequence <- cumsum(AR_start)
  index <- seq_along(residual)
  earlier <- index - lag
  eligible <- earlier >= 1L
  eligible[eligible] <- sequence[index[eligible]] == sequence[earlier[eligible]]
  x <- residual[index[eligible]]
  y <- residual[earlier[eligible]]
  complete <- is.finite(x) & is.finite(y)
  if (sum(complete) < 3L) {
    return(c(correlation = NA_real_, pairs = sum(complete)))
  }
  c(
    correlation = stats::cor(x[complete], y[complete]),
    pairs = sum(complete)
  )
}

h06d_bam_convergence <- function(fit) {
  if (is.list(fit$outer.info) && !is.null(fit$outer.info$conv)) {
    return(as.character(fit$outer.info$conv))
  }
  if (is.logical(fit$converged) && length(fit$converged) == 1L) {
    return(ifelse(fit$converged, "full convergence", "not fully converged"))
  }
  "not reported"
}

h06d_fit_bam <- function(formula, data, family, rho = 0) {
  s <- mgcv::s
  environment(formula) <- environment()
  h06d_capture(mgcv::bam(
    formula = formula,
    data = data,
    family = family,
    method = "fREML",
    discrete = TRUE,
    rho = rho,
    AR.start = data$AR_start,
    knots = list(time_hour = c(0, 24)),
    nthreads = 1L,
    gc.level = 1L,
    drop.unused.levels = TRUE
  ))
}

h06d_estimate_rho <- function(fit, data, residual_type = "pearson") {
  residual <- stats::residuals(fit, type = residual_type)
  estimate <- unname(h06d_boundary_lag_correlation(
    residual,
    data$AR_start,
    lag = 1L
  )[["correlation"]])
  if (!is.finite(estimate)) {
    h06d_abort("Could not estimate boundary-aware temporal rho")
  }
  spec <- h06d_temporal_specification()
  pmax(spec$rho_bounds[[1L]], pmin(spec$rho_bounds[[2L]], estimate))
}

h06d_fit_temporal_pilot <- function(root, placement = "near_eye") {
  all_data <- h06d_temporal_frame(root, placement, positive_only = FALSE)
  positive_data <- h06d_temporal_frame(root, placement, positive_only = TRUE)

  one_formula <- h06d_temporal_formula("geometric_mean_medi_lx")
  message("Temporal pilot: preliminary one-part Tweedie power fit")
  one_preliminary <- h06d_fit_bam(
    one_formula,
    all_data,
    mgcv::tw(link = "log"),
    rho = 0
  )
  if (is.null(one_preliminary$value)) {
    h06d_abort("Preliminary one-part Tweedie fit failed: %s", one_preliminary$error)
  }
  tweedie_power <- unname(
    one_preliminary$value$family$getTheta(trans = TRUE)
  )
  one_rho <- h06d_estimate_rho(one_preliminary$value, all_data, "pearson")
  message(sprintf(
    "Temporal pilot: final one-part fixed-p Tweedie fit (p = %.4f, rho = %.4f)",
    tweedie_power,
    one_rho
  ))
  one_final <- h06d_fit_bam(
    one_formula,
    all_data,
    mgcv::Tweedie(p = tweedie_power, link = "log"),
    rho = one_rho
  )

  occurrence_formula <- h06d_temporal_formula("positive_medi")
  message("Temporal pilot: preliminary binomial occurrence fit")
  occurrence_preliminary <- h06d_fit_bam(
    occurrence_formula,
    all_data,
    stats::binomial(link = "logit"),
    rho = 0
  )
  if (is.null(occurrence_preliminary$value)) {
    h06d_abort(
      "Preliminary temporal occurrence fit failed: %s",
      occurrence_preliminary$error
    )
  }
  occurrence_rho <- h06d_estimate_rho(
    occurrence_preliminary$value,
    all_data,
    "pearson"
  )
  message(sprintf(
    "Temporal pilot: final binomial occurrence fit (rho = %.4f)",
    occurrence_rho
  ))
  occurrence_final <- h06d_fit_bam(
    occurrence_formula,
    all_data,
    stats::binomial(link = "logit"),
    rho = occurrence_rho
  )

  positive_formula <- h06d_temporal_formula("geometric_mean_medi_lx")
  message("Temporal pilot: preliminary positive Gamma fit")
  positive_preliminary <- h06d_fit_bam(
    positive_formula,
    positive_data,
    stats::Gamma(link = "log"),
    rho = 0
  )
  if (is.null(positive_preliminary$value)) {
    h06d_abort(
      "Preliminary temporal positive-magnitude fit failed: %s",
      positive_preliminary$error
    )
  }
  positive_rho <- h06d_estimate_rho(
    positive_preliminary$value,
    positive_data,
    "pearson"
  )
  message(sprintf(
    "Temporal pilot: final positive Gamma fit (rho = %.4f)",
    positive_rho
  ))
  positive_final <- h06d_fit_bam(
    positive_formula,
    positive_data,
    stats::Gamma(link = "log"),
    rho = positive_rho
  )

  if (any(vapply(
    list(one_final, occurrence_final, positive_final),
    function(x) is.null(x$value),
    logical(1)
  ))) {
    h06d_abort("At least one final H06-daily temporal pilot fit failed")
  }

  list(
    one_part = list(
      data = all_data,
      formula = one_formula,
      preliminary = one_preliminary,
      final = one_final,
      rho = one_rho,
      tweedie_power = tweedie_power
    ),
    occurrence = list(
      data = all_data,
      formula = occurrence_formula,
      preliminary = occurrence_preliminary,
      final = occurrence_final,
      rho = occurrence_rho
    ),
    positive = list(
      data = positive_data,
      formula = positive_formula,
      preliminary = positive_preliminary,
      final = positive_final,
      rho = positive_rho
    )
  )
}

h06d_smoothing_hessian <- function(fit) {
  hessian <- fit$outer.info$hess
  values <- if (is.matrix(hessian) && all(is.finite(hessian))) {
    eigen(
      (hessian + t(hessian)) / 2,
      symmetric = TRUE,
      only.values = TRUE
    )$values
  } else {
    NA_real_
  }
  c(
    minimum = if (all(is.na(values))) NA_real_ else min(values),
    maximum_absolute = if (all(is.na(values))) NA_real_ else max(abs(values)),
    minimum_relative = if (all(is.na(values)) || max(abs(values)) == 0) {
      NA_real_
    } else {
      min(values) / max(abs(values))
    },
    positive_definite = if (all(is.na(values))) NA else all(values > 0)
  )
}

h06d_temporal_closure <- function(fit, data, candidate_id, component) {
  smooth_labels <- vapply(
    fit$smooth,
    function(smooth) smooth$label,
    character(1)
  )
  excluded <- smooth_labels[
    grepl("participant)", smooth_labels, fixed = TRUE) |
      grepl("participant_day", smooth_labels, fixed = TRUE)
  ]
  grid <- tidyr::expand_grid(
    time_hour = c(0, 24),
    site = factor(levels(droplevels(data$site)), levels = levels(data$site)),
    work_free_day = factor(
      levels(data$work_free_day),
      levels = levels(data$work_free_day)
    ),
    activity_status = factor(
      levels(data$activity_status),
      levels = levels(data$activity_status)
    ),
    previous_sleep_duration_centered_h = c(-1, 0, 1),
    participant = factor(
      levels(data$participant)[[1L]],
      levels = levels(data$participant)
    ),
    participant_day = factor(
      levels(data$participant_day)[[1L]],
      levels = levels(data$participant_day)
    ),
    AR_start = TRUE
  )
  prediction <- stats::predict(
    fit,
    newdata = grid,
    type = "link",
    exclude = excluded,
    discrete = FALSE,
    newdata.guaranteed = TRUE
  )
  closure <- grid |>
    dplyr::mutate(link_prediction = as.numeric(prediction)) |>
    dplyr::summarise(
      link_at_0 = .data$link_prediction[.data$time_hour == 0],
      link_at_24 = .data$link_prediction[.data$time_hour == 24],
      absolute_endpoint_difference = abs(.data$link_at_24 - .data$link_at_0),
      .by = c(
        "site", "work_free_day", "activity_status",
        "previous_sleep_duration_centered_h"
      )
    )
  tibble::tibble(
    candidate_id = candidate_id,
    component = component,
    endpoint_pairs = nrow(closure),
    maximum_absolute_endpoint_difference_link = max(
      closure$absolute_endpoint_difference
    ),
    cyclic_closure_pass =
      max(closure$absolute_endpoint_difference) < 1e-8,
    excluded_random_smooths = paste(excluded, collapse = " | ")
  )
}

h06d_term_concurvity_fallback <- function(
  fit,
  candidate_id,
  component,
  maximum_rows = 5000L,
  seed = 61062026L
) {
  n <- stats::nobs(fit)
  if (n > maximum_rows) {
    set.seed(seed)
    rows <- sort(sample.int(n, maximum_rows, replace = FALSE))
  } else {
    rows <- seq_len(n)
  }
  terms <- stats::predict(fit, type = "terms", discrete = FALSE)[rows, , drop = FALSE]
  output <- lapply(seq_len(ncol(terms)), function(index) {
    response <- terms[, index]
    others <- terms[, -index, drop = FALSE]
    if (stats::sd(response) <= sqrt(.Machine$double.eps)) {
      multiple_r_squared <- NA_real_
    } else {
      design <- cbind(1, others)
      fitted <- stats::lm.fit(design, response)$fitted.values
      multiple_r_squared <- 1 - sum((response - fitted)^2) /
        sum((response - mean(response))^2)
    }
    tibble::tibble(
      candidate_id = candidate_id,
      component = component,
      term = colnames(terms)[[index]],
      sampled_rows = length(rows),
      fitted_term_multiple_r_squared = multiple_r_squared,
      diagnostic_role = paste(
        "fitted-term linear multiple-R2 fallback;",
        "not full mgcv concurvity"
      )
    )
  })
  dplyr::bind_rows(output)
}

h06d_site_residual_acf <- function(object, candidate_id, component) {
  fit <- object$final$value
  data <- object$data
  residual <- if (!is.null(fit$std.rsd) && length(fit$std.rsd) == nrow(data)) {
    fit$std.rsd
  } else {
    stats::residuals(fit, type = "pearson")
  }
  data |>
    dplyr::mutate(.residual = as.numeric(residual)) |>
    dplyr::group_split(.data$site, .keep = TRUE) |>
    lapply(function(site_data) {
      lag <- h06d_boundary_lag_correlation(
        site_data$.residual,
        site_data$AR_start,
        lag = 1L
      )
      tibble::tibble(
        candidate_id = candidate_id,
        component = component,
        site = as.character(site_data$site[[1L]]),
        residual_lag1 = lag[["correlation"]],
        adjacent_pairs = lag[["pairs"]]
      )
    }) |>
    dplyr::bind_rows()
}

h06d_deterministic_k_check <- function(fit, seed = 61062026L) {
  set.seed(seed)
  output <- tryCatch(
    mgcv::k.check(fit, subsample = 5000, n.rep = 0),
    error = function(condition) NULL
  )
  if (is.null(output)) {
    return(tibble::tibble(
      term = character(),
      k_prime = numeric(),
      effective_df = numeric(),
      k_index = numeric(),
      permutation_p_not_run = logical()
    ))
  }
  tibble::as_tibble(output, rownames = "term") |>
    rlang::set_names(
      c("term", "k_prime", "effective_df", "k_index", "p_value")
    ) |>
    dplyr::mutate(permutation_p_not_run = TRUE) |>
    dplyr::select(-"p_value")
}

h06d_calibration_bins <- function(observed, predicted, component) {
  tibble::tibble(observed = observed, predicted = predicted) |>
    dplyr::filter(is.finite(.data$observed), is.finite(.data$predicted)) |>
    dplyr::mutate(bin = dplyr::ntile(.data$predicted, 10L)) |>
    dplyr::summarise(
      component = component,
      observations = dplyr::n(),
      observed_mean = mean(.data$observed),
      predicted_mean = mean(.data$predicted),
      observed_to_predicted = .data$observed_mean / .data$predicted_mean,
      .by = "bin"
    )
}

h06d_temporal_component_diagnostics <- function(
  object,
  candidate_id,
  component,
  observed
) {
  fit <- object$final$value
  data <- object$data
  residual <- if (!is.null(fit$std.rsd) && length(fit$std.rsd) == nrow(data)) {
    fit$std.rsd
  } else {
    stats::residuals(fit, type = "pearson")
  }
  lag <- h06d_boundary_lag_correlation(residual, data$AR_start, lag = 1L)
  hessian <- h06d_smoothing_hessian(fit)
  summary_fit <- summary(fit)
  predicted <- as.numeric(stats::fitted(fit))
  tibble::tibble(
    candidate_id = candidate_id,
    component = component,
    formula = paste(deparse(object$formula), collapse = " "),
    family = fit$family$family,
    link = fit$family$link,
    method = "fREML",
    discrete = TRUE,
    nthreads = 1L,
    observations = nrow(data),
    participant_days = nlevels(data$participant_day),
    participants = nlevels(data$participant),
    sites = nlevels(droplevels(data$site)),
    exact_zeros = sum(data$geometric_mean_medi_lx == 0),
    zero_fraction = mean(data$geometric_mean_medi_lx == 0),
    rho = object$rho,
    preliminary_elapsed_seconds = object$preliminary$elapsed_seconds,
    final_elapsed_seconds = object$final$elapsed_seconds,
    total_elapsed_seconds = object$preliminary$elapsed_seconds +
      object$final$elapsed_seconds,
    convergence = h06d_bam_convergence(fit),
    rank = fit$rank,
    coefficients = length(stats::coef(fit)),
    total_edf = sum(fit$edf),
    adjusted_r_squared = summary_fit$r.sq,
    deviance_explained = summary_fit$dev.expl,
    dispersion = summary_fit$scale,
    smoothing_hessian_minimum_eigenvalue = hessian[["minimum"]],
    smoothing_hessian_maximum_absolute_eigenvalue =
      hessian[["maximum_absolute"]],
    smoothing_hessian_minimum_relative_eigenvalue =
      hessian[["minimum_relative"]],
    smoothing_hessian_positive_definite = as.logical(
      hessian[["positive_definite"]]
    ),
    preliminary_warning_count = length(object$preliminary$warnings),
    final_warning_count = length(object$final$warnings),
    final_warnings = paste(object$final$warnings, collapse = " | "),
    standardized_residual_lag1 = lag[["correlation"]],
    standardized_residual_lag1_pairs = lag[["pairs"]],
    absolute_residual_fitted_spearman = suppressWarnings(stats::cor(
      abs(residual),
      predicted,
      method = "spearman",
      use = "complete.obs"
    )),
    observed_mean = mean(observed),
    predicted_mean = mean(predicted)
  )
}

h06d_temporal_pilot_diagnostics <- function(pilot) {
  one <- pilot$one_part
  occurrence <- pilot$occurrence
  positive <- pilot$positive

  one_fit <- one$final$value
  one_mu <- as.numeric(stats::fitted(one_fit))
  one_phi <- summary(one_fit)$scale
  one_lambda <- one_mu^(2 - one$tweedie_power) /
    (one_phi * (2 - one$tweedie_power))
  one_working_zero <- exp(-one_lambda)

  occurrence_probability <- as.numeric(stats::fitted(occurrence$final$value))
  positive_mean <- as.numeric(stats::fitted(positive$final$value))

  component <- dplyr::bind_rows(
    h06d_temporal_component_diagnostics(
      one,
      "one_part_tweedie",
      "conditional_mean",
      one$data$geometric_mean_medi_lx
    ) |>
      dplyr::mutate(
        tweedie_power = one$tweedie_power,
        working_zero_fraction = mean(one_working_zero),
        observed_zero_fraction = mean(one$data$geometric_mean_medi_lx == 0)
      ),
    h06d_temporal_component_diagnostics(
      occurrence,
      "two_part",
      "occurrence",
      occurrence$data$positive_medi
    ) |>
      dplyr::mutate(
        tweedie_power = NA_real_,
        working_zero_fraction = mean(1 - occurrence_probability),
        observed_zero_fraction = mean(occurrence$data$positive_medi == 0)
      ),
    h06d_temporal_component_diagnostics(
      positive,
      "two_part",
      "positive_magnitude",
      positive$data$geometric_mean_medi_lx
    ) |>
      dplyr::mutate(
        tweedie_power = NA_real_,
        working_zero_fraction = NA_real_,
        observed_zero_fraction = NA_real_
      )
  )

  calibration <- dplyr::bind_rows(
    h06d_calibration_bins(
      as.integer(one$data$geometric_mean_medi_lx == 0),
      one_working_zero,
      "one_part_tweedie_zero_probability"
    ),
    h06d_calibration_bins(
      occurrence$data$positive_medi,
      occurrence_probability,
      "two_part_positive_occurrence_probability"
    ),
    h06d_calibration_bins(
      positive$data$geometric_mean_medi_lx,
      positive_mean,
      "two_part_positive_magnitude_mean"
    )
  )

  k_check <- dplyr::bind_rows(
    h06d_deterministic_k_check(one$final$value) |>
      dplyr::mutate(candidate_id = "one_part_tweedie", component = "mean"),
    h06d_deterministic_k_check(occurrence$final$value) |>
      dplyr::mutate(candidate_id = "two_part", component = "occurrence"),
    h06d_deterministic_k_check(positive$final$value) |>
      dplyr::mutate(candidate_id = "two_part", component = "positive_magnitude")
  )

  list(component = component, calibration = calibration, k_check = k_check)
}
