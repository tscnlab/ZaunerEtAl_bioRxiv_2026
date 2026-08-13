# Helpers for the bounded H06_daily non-MDER daily AR repair pilot.

h06d_ar_capture <- function(expression) {
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
  list(
    value = if (inherits(value, "error")) NULL else value,
    error = if (inherits(value, "error")) {
      conditionMessage(value)
    } else {
      NA_character_
    },
    warnings = unique(warnings),
    elapsed_seconds = unname(proc.time()[["elapsed"]] - started)
  )
}

h06d_ar_add_day_sequences <- function(frame) {
  output <- frame |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      date_gap = as.integer(.data$local_date - dplyr::lag(.data$local_date)),
      sequence_start = dplyr::row_number() == 1L |
        is.na(.data$date_gap) |
        .data$date_gap != 1L,
      sequence_number = cumsum(.data$sequence_start)
    ) |>
    dplyr::ungroup() |>
    dplyr::group_by(.data$participant_key, .data$sequence_number) |>
    dplyr::mutate(day_index = dplyr::row_number()) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      day_sequence_id = interaction(
        .data$participant_key,
        .data$sequence_number,
        drop = TRUE,
        lex.order = TRUE
      ),
      day_index_factor = factor(
        .data$day_index,
        levels = seq_len(max(.data$day_index))
      )
    )

  if (anyDuplicated(output[c("participant_key", "local_date")])) {
    h06d_abort("A daily AR frame contains duplicate participant-dates")
  }
  if (any(output$date_gap[!output$sequence_start] != 1L)) {
    h06d_abort("A daily AR sequence crosses a missing calendar date")
  }
  output
}

h06d_ar_formula <- function(predictor_column, ar = FALSE) {
  ar_term <- if (isTRUE(ar)) {
    " + ar1(day_index_factor + 0 | day_sequence_id)"
  } else {
    ""
  }
  stats::as.formula(sprintf(
    "response_value ~ site + %s + (1 | participant_key)%s",
    predictor_column,
    ar_term
  ))
}

h06d_ar_fit_gaussian <- function(frame, formula, REML = TRUE) {
  h06d_ar_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    family = stats::gaussian(link = "identity"),
    REML = REML,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_ar_model_status <- function(model, fit = NULL) {
  if (is.null(model)) {
    return(tibble::tibble(
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      finite_fixed_effects = FALSE,
      finite_standard_errors = FALSE,
      convergence_message = fit$error %||% "fit failed",
      warning_count = length(fit$warnings %||% character()),
      warnings = paste(fit$warnings %||% character(), collapse = " | ")
    ))
  }
  fixed <- glmmTMB::fixef(model)$cond
  covariance <- as.matrix(stats::vcov(model)$cond)
  standard_error <- sqrt(diag(covariance))
  tibble::tibble(
    converged = identical(as.integer(model$fit$convergence), 0L) &&
      isTRUE(model$sdr$pdHess),
    positive_definite_hessian = isTRUE(model$sdr$pdHess),
    singular = tryCatch(
      as.logical(performance::check_singularity(model)),
      error = function(condition) NA
    ),
    finite_fixed_effects = all(is.finite(fixed)),
    finite_standard_errors = all(is.finite(standard_error)),
    convergence_message = paste(model$fit$message, collapse = " | "),
    warning_count = length(fit$warnings %||% character()),
    warnings = paste(fit$warnings %||% character(), collapse = " | ")
  )
}

h06d_ar_fixed_table <- function(model) {
  if (inherits(model, "merMod")) {
    estimate <- lme4::fixef(model)
    covariance <- as.matrix(stats::vcov(model))
  } else if (inherits(model, "glmmTMB")) {
    estimate <- glmmTMB::fixef(model)$cond
    covariance <- as.matrix(stats::vcov(model)$cond)
  } else {
    h06d_abort("Unsupported daily AR model class")
  }
  standard_error <- sqrt(diag(covariance))
  critical <- stats::qnorm(0.975)
  tibble::tibble(
    term = names(estimate),
    estimate = unname(estimate),
    standard_error = unname(standard_error),
    lower_95 = unname(estimate - critical * standard_error),
    upper_95 = unname(estimate + critical * standard_error)
  )
}

h06d_ar_effect_row <- function(model, effect_term, response_transform) {
  selected <- h06d_ar_fixed_table(model) |>
    dplyr::filter(.data$term == .env$effect_term)
  if (nrow(selected) != 1L) {
    h06d_abort("Daily AR effect term `%s` was not uniquely estimated", effect_term)
  }
  selected |>
    dplyr::mutate(
      display_estimate = dplyr::case_when(
        .env$response_transform == "log10_positive" ~ 10^.data$estimate,
        TRUE ~ .data$estimate
      ),
      display_lower_95 = dplyr::case_when(
        .env$response_transform == "log10_positive" ~ 10^.data$lower_95,
        TRUE ~ .data$lower_95
      ),
      display_upper_95 = dplyr::case_when(
        .env$response_transform == "log10_positive" ~ 10^.data$upper_95,
        TRUE ~ .data$upper_95
      )
    )
}

h06d_ar_lag_screen <- function(frame, residual) {
  pairs <- frame |>
    dplyr::mutate(.residual = residual) |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      previous_residual = dplyr::lag(.data$.residual),
      date_gap = as.integer(
        .data$local_date - dplyr::lag(.data$local_date)
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(
      .data$date_gap == 1L,
      is.finite(.data$.residual),
      is.finite(.data$previous_residual)
    )

  by_site <- pairs |>
    dplyr::summarise(
      adjacent_pairs = dplyr::n(),
      participants = dplyr::n_distinct(.data$participant_key),
      residual_lag1 = if (dplyr::n() >= 3L) {
        stats::cor(.data$.residual, .data$previous_residual)
      } else {
        NA_real_
      },
      .by = "site"
    )
  site_lag <- by_site$residual_lag1[is.finite(by_site$residual_lag1)]
  pooled <- if (nrow(pairs) >= 3L) {
    stats::cor(pairs$.residual, pairs$previous_residual)
  } else {
    NA_real_
  }
  overall <- tibble::tibble(
    adjacent_pairs = nrow(pairs),
    participants_with_adjacent_pair =
      dplyr::n_distinct(pairs$participant_key),
    residual_lag1 = pooled,
    maximum_absolute_site_lag1 = if (length(site_lag)) {
      max(abs(site_lag))
    } else {
      NA_real_
    },
    temporal_threshold_pass = is.finite(pooled) &&
      abs(pooled) < 0.20 &&
      length(site_lag) > 0L &&
      all(abs(site_lag) < 0.30)
  )
  list(overall = overall, by_site = by_site, pairs = pairs)
}

h06d_ar_sequence_support <- function(frame) {
  sequence_table <- frame |>
    dplyr::count(
      .data$participant_key,
      .data$sequence_number,
      name = "sequence_days"
    )
  tibble::tibble(
    observations = nrow(frame),
    participants = dplyr::n_distinct(frame$participant_key),
    sites = dplyr::n_distinct(frame$site),
    sequences = nrow(sequence_table),
    adjacent_pairs = sum(pmax(sequence_table$sequence_days - 1L, 0L)),
    participants_with_adjacent_pair = dplyr::n_distinct(
      sequence_table$participant_key[sequence_table$sequence_days >= 2L]
    ),
    sequences_at_least_3_days = sum(sequence_table$sequence_days >= 3L),
    maximum_sequence_days = max(sequence_table$sequence_days),
    support_pass = sum(pmax(sequence_table$sequence_days - 1L, 0L)) >= 100L &&
      dplyr::n_distinct(
        sequence_table$participant_key[sequence_table$sequence_days >= 2L]
      ) >= 20L
  )
}

h06d_ar_parameters <- function(model) {
  covariance <- glmmTMB::VarCorr(model)$cond
  ar <- covariance$day_sequence_id
  participant <- covariance$participant_key
  correlation <- attr(ar, "correlation")
  tibble::tibble(
    ar_standard_deviation = unname(attr(ar, "stddev")[[1L]]),
    ar_rho = if (nrow(correlation) >= 2L) {
      unname(correlation[[1L, 2L]])
    } else {
      NA_real_
    },
    participant_standard_deviation =
      unname(attr(participant, "stddev")[[1L]]),
    residual_standard_deviation = stats::sigma(model)
  )
}

h06d_ar_model_predictions <- function(model, marginal = FALSE) {
  if (inherits(model, "merMod")) {
    return(as.numeric(stats::predict(
      model,
      re.form = if (isTRUE(marginal)) NA else NULL
    )))
  }
  as.numeric(stats::predict(
    model,
    type = "response",
    re.form = if (isTRUE(marginal)) NA else NULL
  ))
}

h06d_ar_residual_diagnostics <- function(
  model,
  frame,
  response_transform,
  lower_bound,
  upper_bound
) {
  residual <- as.numeric(stats::residuals(model))
  sigma <- stats::sigma(model)
  standardized <- residual / sigma
  conditional <- h06d_ar_model_predictions(model, marginal = FALSE)
  marginal <- h06d_ar_model_predictions(model, marginal = TRUE)
  to_source_scale <- function(value) {
    if (response_transform == "log10_positive") 10^value else value
  }
  conditional_source <- to_source_scale(conditional)
  marginal_source <- to_source_scale(marginal)
  theoretical <- stats::qnorm(stats::ppoints(length(standardized)))
  violation_fraction <- function(value) {
    mean(
      value < lower_bound - 0.05 |
        (is.finite(upper_bound) & value > upper_bound + 0.05)
    )
  }
  centered <- residual - mean(residual)
  residual_sd <- stats::sd(centered)
  tibble::tibble(
    residual_qq_correlation = stats::cor(
      sort(standardized),
      theoretical
    ),
    absolute_residual_fitted_spearman = suppressWarnings(stats::cor(
      abs(residual),
      conditional,
      method = "spearman",
      use = "complete.obs"
    )),
    standardized_residual_gt4_fraction = mean(abs(standardized) > 4),
    maximum_absolute_standardized_residual = max(abs(standardized)),
    residual_skewness = if (is.finite(residual_sd) && residual_sd > 0) {
      mean((centered / residual_sd)^3)
    } else {
      NA_real_
    },
    conditional_prediction_minimum = min(conditional_source),
    conditional_prediction_maximum = max(conditional_source),
    marginal_prediction_minimum = min(marginal_source),
    marginal_prediction_maximum = max(marginal_source),
    conditional_bound_violation_fraction =
      violation_fraction(conditional_source),
    marginal_bound_violation_fraction = violation_fraction(marginal_source),
    distribution_pass =
      stats::cor(sort(standardized), theoretical) >= 0.95 &&
      abs(suppressWarnings(stats::cor(
        abs(residual),
        conditional,
        method = "spearman",
        use = "complete.obs"
      ))) < 0.20 &&
      mean(abs(standardized) > 4) < 0.01,
    bounds_pass = violation_fraction(conditional_source) <= 0.01 &&
      violation_fraction(marginal_source) <= 0.01
  )
}

h06d_ar_frame_equivalence <- function(old, current, repair_id) {
  old <- old |>
    dplyr::arrange(.data$participant_day_key)
  current <- current |>
    dplyr::arrange(.data$participant_day_key)
  canonicalize <- function(data) {
    output <- lapply(data, function(column) {
      if (is.factor(column)) {
        return(list(values = as.character(column), levels = levels(column)))
      }
      if (inherits(column, "Date")) {
        return(as.numeric(column))
      }
      unname(column)
    })
    names(output) <- names(data)
    output
  }
  common <- intersect(names(old), names(current))
  value_equal <- vapply(
    common,
    function(column) isTRUE(all.equal(
      old[[column]],
      current[[column]],
      check.attributes = FALSE
    )),
    logical(1)
  )
  factor_columns <- common[
    vapply(old[common], is.factor, logical(1)) |
      vapply(current[common], is.factor, logical(1))
  ]
  levels_equal <- vapply(
    factor_columns,
    function(column) identical(levels(old[[column]]), levels(current[[column]])),
    logical(1)
  )
  tibble::tibble(
    repair_id = repair_id,
    old_rows = nrow(old),
    current_rows = nrow(current),
    identical_column_names = identical(names(old), names(current)),
    identical_ordered_keys = identical(
      as.character(old$participant_day_key),
      as.character(current$participant_day_key)
    ),
    all_shared_column_values_equal = all(value_equal),
    all_factor_levels_equal = all(levels_equal),
    differing_value_columns = paste(common[!value_equal], collapse = " | "),
    differing_factor_levels = paste(factor_columns[!levels_equal], collapse = " | "),
    old_normalized_sha256 = digest::digest(
      canonicalize(old),
      algo = "sha256"
    ),
    current_normalized_sha256 = digest::digest(
      canonicalize(current),
      algo = "sha256"
    ),
    equivalence_pass = nrow(old) == nrow(current) &&
      identical(names(old), names(current)) &&
      identical(
        as.character(old$participant_day_key),
        as.character(current$participant_day_key)
      ) &&
      all(value_equal) && all(levels_equal)
  )
}
