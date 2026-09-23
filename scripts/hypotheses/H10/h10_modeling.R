h10_transform_response <- function(value, spec, variant = "primary") {
  value <- as.numeric(value)
  if (spec$response_transform == "logit") {
    if (any(value <= 0 | value >= 1, na.rm = TRUE)) {
      h10_abort("`%s` contains a value outside (0, 1)", spec$metric_id)
    }
    return(stats::qlogis(value))
  }
  if (spec$response_transform == "log10_offset_0.1") {
    if (any(value < 0, na.rm = TRUE)) {
      h10_abort("`%s` contains a negative value", spec$metric_id)
    }
    return(log10(value + 0.1))
  }
  if (spec$response_transform == "clock_minutes_after_16") {
    cutoff <- if (variant == "l10_noon") 720 else 960
    return(ifelse(value > cutoff, value - 1440, value))
  }
  if (spec$response_transform %in% c("identity", "clock_minutes")) {
    return(value)
  }
  h10_abort(
    "Unknown H10 response transformation `%s` for `%s`",
    spec$response_transform,
    spec$metric_id
  )
}

h10_back_transform_response <- function(value, spec) {
  if (spec$response_family == "tweedie_log") {
    return(exp(value))
  }
  if (spec$response_transform == "log10_offset_0.1") {
    return(10^value - 0.1)
  }
  if (spec$response_transform == "logit") {
    return(stats::plogis(value))
  }
  value
}

h10_effect_transform <- function(estimate, conf_low, conf_high, spec) {
  if (spec$effect_scale == "ratio") {
    transform <- if (spec$response_transform == "log10_offset_0.1") {
      function(x) 10^x
    } else {
      exp
    }
    return(tibble::tibble(
      estimate_practical = transform(estimate),
      conf_low_practical = transform(conf_low),
      conf_high_practical = transform(conf_high),
      practical_effect_type = "ratio",
      practical_unit = "ratio"
    ))
  }
  if (spec$effect_scale == "odds_ratio") {
    return(tibble::tibble(
      estimate_practical = exp(estimate),
      conf_low_practical = exp(conf_low),
      conf_high_practical = exp(conf_high),
      practical_effect_type = "odds ratio",
      practical_unit = "odds ratio"
    ))
  }
  unit <- dplyr::case_when(
    spec$metric_id %in%
      c(
        "duration_below_10_pre_sleep",
        "intradaily_variability"
      ) ~
      ifelse(
        spec$metric_id == "duration_below_10_pre_sleep",
        "h",
        "dimensionless"
      ),
    spec$metric_id %in%
      c(
        "m10_midpoint",
        "l10_midpoint",
        "mean_timing_above_250",
        "first_timing_above_250",
        "last_timing_above_250"
      ) ~
      "min",
    spec$metric_id == "mder_mean_of_viable_ratios" ~ "dimensionless",
    TRUE ~ "model scale"
  )
  tibble::tibble(
    estimate_practical = estimate,
    conf_low_practical = conf_low,
    conf_high_practical = conf_high,
    practical_effect_type = "difference",
    practical_unit = unit
  )
}

h10_prepare_model_frame <- function(
  rows,
  spec,
  site_levels,
  sample_scenario = "all_available",
  transform_variant = "primary"
) {
  required <- c(
    "data_scenario",
    "placement",
    "site",
    "Id",
    "local_date",
    "metric_id",
    "value",
    "age",
    "biological_sex"
  )
  missing <- setdiff(required, names(rows))
  if (length(missing) > 0L) {
    h10_abort(
      "H10 model rows are missing column(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  frame <- rows[
    is.finite(rows$value) &
      is.finite(rows$age) &
      !is.na(rows$biological_sex) &
      !is.na(rows$site) &
      !is.na(rows$Id),
    ,
    drop = FALSE
  ]
  if (nrow(frame) == 0L) {
    return(tibble::tibble())
  }
  frame$site <- factor(as.character(frame$site), levels = site_levels)
  if (any(is.na(frame$site))) {
    h10_abort("H10 frame contains a site absent from the site registry")
  }
  frame$site <- droplevels(frame$site)
  if (nlevels(frame$site) < 2L) {
    h10_abort(
      "H10 frame for `%s` contains fewer than two sites",
      spec$metric_id
    )
  }
  stats::contrasts(frame$site) <- stats::contr.sum(nlevels(frame$site))
  frame$biological_sex <- factor(
    as.character(frame$biological_sex),
    levels = c("Male", "Female")
  )
  if (any(is.na(frame$biological_sex))) {
    h10_abort("H10 biological-sex values must be Male or Female")
  }
  stats::contrasts(frame$biological_sex) <- stats::contr.treatment(
    levels(frame$biological_sex),
    base = 1L
  )
  frame$Id <- factor(as.character(frame$Id))
  frame$participant_key <- factor(paste(frame$site, frame$Id, sep = ":"))
  frame$local_date <- as.Date(frame$local_date)
  frame$age_decade <- as.numeric(frame$age) / 10
  frame$response <- h10_transform_response(
    frame$value,
    spec,
    variant = transform_variant
  )
  frame$sample_scenario <- sample_scenario
  date_label <- ifelse(
    is.na(frame$local_date),
    "participant",
    format(frame$local_date)
  )
  frame$.model_row_id <- paste(
    frame$data_scenario,
    frame$placement,
    sample_scenario,
    frame$metric_id,
    as.character(frame$site),
    as.character(frame$Id),
    date_label,
    sep = "|"
  )
  frame <- frame[
    order(frame$site, frame$Id, frame$local_date, na.last = TRUE),
    ,
    drop = FALSE
  ]
  if (anyDuplicated(frame$.model_row_id)) {
    h10_abort(
      "H10 model-row identifiers are not unique for `%s`",
      spec$metric_id
    )
  }
  if (
    any(!is.finite(frame$response)) ||
      any(!is.finite(frame$age_decade))
  ) {
    h10_abort("H10 transformed frame contains a non-finite value")
  }
  tibble::as_tibble(frame)
}

h10_capture_fit <- function(expression) {
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

h10_fit_model <- function(frame, formula, spec, reml = FALSE) {
  if (nrow(frame) == 0L) {
    return(list(
      model = NULL,
      warnings = character(),
      error = "No estimable rows"
    ))
  }
  has_random <- length(reformulas::findbars(formula)) > 0L
  if (spec$response_family == "gaussian" && !has_random) {
    return(h10_capture_fit(stats::lm(formula = formula, data = frame)))
  }
  if (spec$response_family == "gaussian") {
    return(h10_capture_fit(
      lme4::lmer(
        formula = formula,
        data = frame,
        REML = reml,
        control = lme4::lmerControl(
          optimizer = "nloptwrap",
          calc.derivs = TRUE,
          optCtrl = list(maxeval = 200000L)
        )
      )
    ))
  }
  if (reml) {
    h10_abort("REML is not used for Tweedie H10 models")
  }
  h10_capture_fit(
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

h10_fit_bundle <- function(frame, spec) {
  formulas <- h10_formula_set(spec$analysis_unit)
  ml_fits <- lapply(formulas, function(formula) {
    h10_fit_model(frame, formula, spec, reml = FALSE)
  })
  final_names <- c("M_age", "M_age_site", "M_sex", "M_sex_site")
  final_fits <- lapply(final_names, function(model_name) {
    if (
      spec$response_family == "gaussian" &&
        spec$analysis_unit == "participant_day"
    ) {
      h10_fit_model(
        frame,
        formulas[[model_name]],
        spec,
        reml = TRUE
      )
    } else {
      ml_fits[[model_name]]
    }
  })
  names(final_fits) <- final_names
  list(
    spec = spec,
    formulas = formulas,
    ml_fits = ml_fits,
    final_fits = final_fits
  )
}

h10_fixed_components <- function(model) {
  if (is.null(model)) {
    return(list(beta = numeric(), vcov = matrix(numeric(), 0L, 0L)))
  }
  if (inherits(model, "glmmTMB")) {
    beta <- glmmTMB::fixef(model)$cond
    covariance <- as.matrix(stats::vcov(model)$cond)
  } else if (inherits(model, "merMod")) {
    beta <- lme4::fixef(model)
    covariance <- as.matrix(stats::vcov(model))
  } else {
    beta <- stats::coef(model)
    covariance <- as.matrix(stats::vcov(model))
  }
  list(beta = beta, vcov = covariance)
}

h10_model_fit_status <- function(model) {
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
      max_gradient = tryCatch(
        max(abs(model$fit$gradient), na.rm = TRUE),
        error = function(condition) NA_real_
      ),
      convergence_message = if (
        is.null(model$fit$message) ||
          identical(model$fit$message, "relative convergence (4)")
      ) {
        NA_character_
      } else {
        as.character(model$fit$message)
      }
    ))
  }
  h10_abort("Unsupported H10 model class: %s", class(model)[1L])
}

h10_model_condition <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      fixed_columns = NA_integer_,
      fixed_rank = NA_integer_,
      fixed_full_rank = FALSE,
      fixed_condition_number = NA_real_,
      aliased_coefficients = NA_character_
    ))
  }
  design <- tryCatch(
    stats::model.matrix(model),
    error = function(condition) {
      if (inherits(model, "glmmTMB")) {
        stats::model.matrix(model, component = "cond")
      } else {
        stop(condition)
      }
    }
  )
  rank <- qr(design)$rank
  components <- h10_fixed_components(model)
  aliased <- names(components$beta)[!is.finite(components$beta)]
  tibble::tibble(
    fixed_columns = ncol(design),
    fixed_rank = rank,
    fixed_full_rank = rank == ncol(design) && length(aliased) == 0L,
    fixed_condition_number = tryCatch(
      kappa(design, exact = FALSE),
      error = function(condition) NA_real_
    ),
    aliased_coefficients = if (length(aliased) == 0L) {
      NA_character_
    } else {
      paste(aliased, collapse = " | ")
    }
  )
}

h10_compare_models <- function(reduced_fit, full_fit) {
  if (is.null(reduced_fit$model) || is.null(full_fit$model)) {
    return(tibble::tibble(
      statistic = NA_real_,
      degrees_freedom = NA_real_,
      p_raw = NA_real_,
      comparison_method = NA_character_,
      comparison_status = "NON_ESTIMABLE"
    ))
  }
  comparison <- tryCatch(
    stats::anova(reduced_fit$model, full_fit$model),
    error = function(condition) condition
  )
  if (inherits(comparison, "error")) {
    return(tibble::tibble(
      statistic = NA_real_,
      degrees_freedom = NA_real_,
      p_raw = NA_real_,
      comparison_method = NA_character_,
      comparison_status = paste0(
        "NON_ESTIMABLE: ",
        conditionMessage(comparison)
      )
    ))
  }
  if (inherits(full_fit$model, "lm") && !inherits(full_fit$model, "merMod")) {
    return(tibble::tibble(
      statistic = as.numeric(comparison$F[[2L]]),
      degrees_freedom = as.numeric(comparison$Df[[2L]]),
      p_raw = as.numeric(comparison$`Pr(>F)`[[2L]]),
      comparison_method = "nested partial F test",
      comparison_status = "ESTIMABLE"
    ))
  }
  statistic_column <- if ("Chisq" %in% names(comparison)) {
    "Chisq"
  } else {
    NA_character_
  }
  df_column <- if ("Chi Df" %in% names(comparison)) {
    "Chi Df"
  } else if ("Df" %in% names(comparison)) {
    "Df"
  } else {
    NA_character_
  }
  p_column <- if ("Pr(>Chisq)" %in% names(comparison)) {
    "Pr(>Chisq)"
  } else {
    NA_character_
  }
  tibble::tibble(
    statistic = if (is.na(statistic_column)) {
      NA_real_
    } else {
      as.numeric(comparison[[statistic_column]][[2L]])
    },
    degrees_freedom = if (is.na(df_column)) {
      NA_real_
    } else {
      as.numeric(comparison[[df_column]][[2L]])
    },
    p_raw = if (is.na(p_column)) {
      NA_real_
    } else {
      as.numeric(comparison[[p_column]][[2L]])
    },
    comparison_method = "maximum-likelihood likelihood-ratio test",
    comparison_status = if (is.na(p_column)) {
      "NON_ESTIMABLE"
    } else {
      "ESTIMABLE"
    }
  )
}

h10_coefficient_summary <- function(model, predictor, spec) {
  term <- if (predictor == "age") {
    "age_decade"
  } else {
    "biological_sexFemale"
  }
  empty <- tibble::tibble(
    predictor = predictor,
    estimand = ifelse(
      predictor == "age",
      "per 10-year increase",
      "Female minus Male"
    ),
    term = term,
    estimate_model = NA_real_,
    standard_error = NA_real_,
    conf_low_model = NA_real_,
    conf_high_model = NA_real_,
    interval_distribution = NA_character_,
    estimate_status = "NON_ESTIMABLE"
  )
  if (is.null(model)) {
    return(dplyr::bind_cols(
      empty,
      h10_effect_transform(NA_real_, NA_real_, NA_real_, spec)
    ))
  }
  components <- h10_fixed_components(model)
  if (!term %in% names(components$beta)) {
    return(dplyr::bind_cols(
      empty,
      h10_effect_transform(NA_real_, NA_real_, NA_real_, spec)
    ))
  }
  estimate <- as.numeric(components$beta[[term]])
  standard_error <- sqrt(components$vcov[term, term])
  if (inherits(model, "lm") && !inherits(model, "merMod")) {
    critical <- stats::qt(0.975, stats::df.residual(model))
    distribution <- paste0("t(", stats::df.residual(model), ")")
  } else {
    critical <- stats::qnorm(0.975)
    distribution <- "normal"
  }
  conf_low <- estimate - critical * standard_error
  conf_high <- estimate + critical * standard_error
  dplyr::bind_cols(
    empty |>
      dplyr::mutate(
        estimate_model = estimate,
        standard_error = .env$standard_error,
        conf_low_model = conf_low,
        conf_high_model = conf_high,
        interval_distribution = distribution,
        estimate_status = "ESTIMABLE"
      ),
    h10_effect_transform(estimate, conf_low, conf_high, spec)
  ) |>
    dplyr::mutate(
      estimate_model_per_year = ifelse(
        .data$predictor == "age",
        .data$estimate_model / 10,
        NA_real_
      ),
      conf_low_model_per_year = ifelse(
        .data$predictor == "age",
        .data$conf_low_model / 10,
        NA_real_
      ),
      conf_high_model_per_year = ifelse(
        .data$predictor == "age",
        .data$conf_high_model / 10,
        NA_real_
      ),
      estimate_minutes = ifelse(
        .data$practical_unit == "h",
        .data$estimate_practical * 60,
        ifelse(
          .data$practical_unit == "min",
          .data$estimate_practical,
          NA_real_
        )
      ),
      conf_low_minutes = ifelse(
        .data$practical_unit == "h",
        .data$conf_low_practical * 60,
        ifelse(
          .data$practical_unit == "min",
          .data$conf_low_practical,
          NA_real_
        )
      ),
      conf_high_minutes = ifelse(
        .data$practical_unit == "h",
        .data$conf_high_practical * 60,
        ifelse(
          .data$practical_unit == "min",
          .data$conf_high_practical,
          NA_real_
        )
      )
    )
}

h10_fixed_design <- function(model, newdata) {
  formula <- if (inherits(model, "merMod") || inherits(model, "glmmTMB")) {
    reformulas::nobars(stats::formula(model))
  } else {
    stats::formula(model)
  }
  terms <- stats::delete.response(stats::terms(formula))
  design <- stats::model.matrix(terms, data = newdata)
  beta_names <- names(h10_fixed_components(model)$beta)
  missing <- setdiff(beta_names, colnames(design))
  if (length(missing) > 0L) {
    h10_abort(
      "H10 new-data design is missing coefficient(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  design[, beta_names, drop = FALSE]
}

h10_site_effects <- function(model, frame, predictor, spec) {
  if (is.null(model)) {
    return(tibble::tibble())
  }
  site_levels <- levels(frame$site)
  template <- tibble::tibble(
    site = factor(site_levels, levels = site_levels),
    age_decade = mean(frame$age_decade),
    biological_sex = factor("Male", levels = c("Male", "Female"))
  )
  stats::contrasts(template$site) <- stats::contrasts(frame$site)
  stats::contrasts(template$biological_sex) <- stats::contrasts(
    frame$biological_sex
  )
  lower <- template
  upper <- template
  if (predictor == "age") {
    lower$age_decade <- 0
    upper$age_decade <- 1
  } else {
    lower$biological_sex <- factor(
      "Male",
      levels = c("Male", "Female")
    )
    upper$biological_sex <- factor(
      "Female",
      levels = c("Male", "Female")
    )
    stats::contrasts(lower$biological_sex) <- stats::contrasts(
      frame$biological_sex
    )
    stats::contrasts(upper$biological_sex) <- stats::contrasts(
      frame$biological_sex
    )
  }
  contrast_matrix <- h10_fixed_design(model, upper) -
    h10_fixed_design(model, lower)
  components <- h10_fixed_components(model)
  estimate <- as.numeric(contrast_matrix %*% components$beta)
  covariance <- contrast_matrix %*% components$vcov %*% t(contrast_matrix)
  standard_error <- sqrt(diag(covariance))
  critical <- if (inherits(model, "lm") && !inherits(model, "merMod")) {
    stats::qt(0.975, stats::df.residual(model))
  } else {
    stats::qnorm(0.975)
  }
  participant_weights <- frame |>
    dplyr::distinct(.data$site, .data$participant_key) |>
    dplyr::count(.data$site, name = "participants") |>
    dplyr::mutate(
      observed_participant_weight = .data$participants / sum(.data$participants)
    )
  site_rows <- tibble::tibble(
    site = site_levels,
    estimate_model = estimate,
    standard_error = standard_error,
    conf_low_model = estimate - critical * standard_error,
    conf_high_model = estimate + critical * standard_error
  ) |>
    dplyr::left_join(
      participant_weights |>
        dplyr::mutate(site = as.character(.data$site)),
      by = "site"
    ) |>
    dplyr::mutate(equal_site_weight = 1 / dplyr::n())
  summaries <- lapply(
    c("equal_site", "observed_participant"),
    function(weighting) {
      weights <- if (weighting == "equal_site") {
        site_rows$equal_site_weight
      } else {
        site_rows$observed_participant_weight
      }
      estimate_weighted <- sum(weights * estimate)
      se_weighted <- sqrt(
        as.numeric(t(weights) %*% covariance %*% weights)
      )
      tibble::tibble(
        weighting = weighting,
        estimate_model = estimate_weighted,
        standard_error = se_weighted,
        conf_low_model = estimate_weighted - critical * se_weighted,
        conf_high_model = estimate_weighted + critical * se_weighted
      )
    }
  ) |>
    dplyr::bind_rows() |>
    dplyr::mutate(site = NA_character_)
  dplyr::bind_rows(
    site_rows |>
      dplyr::mutate(weighting = "site_specific"),
    summaries
  ) |>
    dplyr::mutate(
      predictor = predictor,
      estimate_practical = dplyr::case_when(
        spec$effect_scale == "ratio" &
          spec$response_transform == "log10_offset_0.1" ~
          10^.data$estimate_model,
        spec$effect_scale %in% c("ratio", "odds_ratio") ~
          exp(.data$estimate_model),
        TRUE ~ .data$estimate_model
      ),
      conf_low_practical = dplyr::case_when(
        spec$effect_scale == "ratio" &
          spec$response_transform == "log10_offset_0.1" ~
          10^.data$conf_low_model,
        spec$effect_scale %in% c("ratio", "odds_ratio") ~
          exp(.data$conf_low_model),
        TRUE ~ .data$conf_low_model
      ),
      conf_high_practical = dplyr::case_when(
        spec$effect_scale == "ratio" &
          spec$response_transform == "log10_offset_0.1" ~
          10^.data$conf_high_model,
        spec$effect_scale %in% c("ratio", "odds_ratio") ~
          exp(.data$conf_high_model),
        TRUE ~ .data$conf_high_model
      )
    )
}

h10_random_effect_sd <- function(model) {
  if (is.null(model) || inherits(model, "lm") && !inherits(model, "merMod")) {
    return(NA_real_)
  }
  if (inherits(model, "merMod")) {
    return(as.numeric(attr(lme4::VarCorr(model)[[1L]], "stddev")[[1L]]))
  }
  if (inherits(model, "glmmTMB")) {
    variance <- tryCatch(
      glmmTMB::VarCorr(model)$cond[[1L]],
      error = function(condition) NULL
    )
    if (is.null(variance)) {
      return(NA_real_)
    }
    return(as.numeric(attr(variance, "stddev")[[1L]]))
  }
  NA_real_
}

h10_serial_diagnostic <- function(residual, frame) {
  if (all(is.na(frame$local_date))) {
    return(tibble::tibble(
      consecutive_day_pairs = 0L,
      participants_with_consecutive_pairs = 0L,
      pooled_consecutive_day_residual_correlation = NA_real_,
      serial_status = "NOT_APPLICABLE_PARTICIPANT_LEVEL"
    ))
  }
  ordered <- tibble::tibble(
    participant_key = as.character(frame$participant_key),
    local_date = frame$local_date,
    residual = residual
  ) |>
    dplyr::filter(is.finite(.data$residual), !is.na(.data$local_date)) |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      previous_date = dplyr::lag(.data$local_date),
      previous_residual = dplyr::lag(.data$residual),
      consecutive = as.integer(.data$local_date - .data$previous_date) == 1L
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(.data$consecutive)
  correlation <- if (
    nrow(ordered) >= 3L &&
      stats::sd(ordered$residual) > 0 &&
      stats::sd(ordered$previous_residual) > 0
  ) {
    stats::cor(ordered$residual, ordered$previous_residual)
  } else {
    NA_real_
  }
  tibble::tibble(
    consecutive_day_pairs = nrow(ordered),
    participants_with_consecutive_pairs = dplyr::n_distinct(
      ordered$participant_key
    ),
    pooled_consecutive_day_residual_correlation = correlation,
    serial_status = dplyr::case_when(
      nrow(ordered) < 3L ~ "LIMITED_SUPPORT",
      is.finite(correlation) && abs(correlation) >= 0.3 ~
        "REVIEW_ABSOLUTE_CORRELATION_AT_LEAST_0.3",
      TRUE ~ "PASS_DESCRIPTIVE_CHECK"
    )
  )
}

h10_tweedie_zero_diagnostic <- function(model, observed) {
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
  if (is.null(model) || !inherits(model, "glmmTMB")) {
    return(empty)
  }
  power <- tryCatch(
    glmmTMB::family_params(model)[[1L]],
    error = function(condition) NA_real_
  )
  dispersion <- tryCatch(
    stats::sigma(model),
    error = function(condition) NA_real_
  )
  mu <- tryCatch(
    stats::fitted(model),
    error = function(condition) rep(NA_real_, length(observed))
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
  probability_zero <- exp(
    -(mu^(2 - power)) / (dispersion * (2 - power))
  )
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
      "Analytical compound-Poisson zero probability; no simulation or ",
      "resampling"
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

h10_prediction_bounds <- function(model, frame, spec) {
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
    h10_back_transform_response(fitted_model, spec)
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
    prediction_bound_status = dplyr::case_when(
      (!is.na(below) && below > 0L) || (!is.na(above) && above > 0L) ~
        "REVIEW_PREDICTION_OUTSIDE_DECLARED_BOUND",
      !is.na(audit_above) && audit_above > 0L ~
        "REVIEW_OBSERVED_ABOVE_AUDIT_THRESHOLD",
      TRUE ~ "PASS"
    )
  )
}

h10_model_diagnostics <- function(fit, frame, spec) {
  model <- fit$model
  status <- h10_model_fit_status(model)
  condition <- h10_model_condition(model)
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
  serial <- if (any(finite)) {
    h10_serial_diagnostic(residual, frame)
  } else {
    tibble::tibble(
      consecutive_day_pairs = 0L,
      participants_with_consecutive_pairs = 0L,
      pooled_consecutive_day_residual_correlation = NA_real_,
      serial_status = "NON_ESTIMABLE"
    )
  }
  zeros <- h10_tweedie_zero_diagnostic(model, frame$value)
  bounds <- h10_prediction_bounds(model, frame, spec)
  warnings <- paste(fit$warnings, collapse = " | ")
  major_failure <-
    is.null(model) ||
    !isTRUE(status$converged) ||
    !isTRUE(status$positive_definite_hessian) ||
    !isTRUE(condition$fixed_full_rank) ||
    any(!is.finite(h10_fixed_components(model)$beta))
  review <-
    isTRUE(status$singular) ||
    (is.finite(qq_correlation) && qq_correlation < 0.95) ||
    (is.finite(residual_fitted_correlation) &&
      abs(residual_fitted_correlation) >= 0.3) ||
    startsWith(serial$serial_status, "REVIEW") ||
    startsWith(zeros$zero_mass_status, "REVIEW") ||
    startsWith(bounds$prediction_bound_status, "REVIEW") ||
    nzchar(warnings)
  issue_codes <- c(
    if (major_failure) "NUMERICAL_OR_RANK_CHECK",
    if (isTRUE(status$singular)) "RANDOM_INTERCEPT_BOUNDARY",
    if (is.finite(qq_correlation) && qq_correlation < 0.95) {
      "RESIDUAL_QQ_REVIEW"
    },
    if (
      is.finite(residual_fitted_correlation) &&
        abs(residual_fitted_correlation) >= 0.3
    ) {
      "RESIDUAL_SPREAD_REVIEW"
    },
    if (startsWith(serial$serial_status, "REVIEW")) {
      "SERIAL_DEPENDENCE_REVIEW"
    },
    if (startsWith(zeros$zero_mass_status, "REVIEW")) {
      "ZERO_MASS_REVIEW"
    },
    if (startsWith(bounds$prediction_bound_status, "REVIEW")) {
      "BOUND_REVIEW"
    },
    if (nzchar(warnings)) "FIT_WARNING"
  )
  dplyr::bind_cols(
    status,
    condition,
    tibble::tibble(
      residual_n = sum(finite),
      residual_mean = if (any(finite)) mean(residual[finite]) else NA_real_,
      residual_sd = if (sum(finite) >= 2L) {
        stats::sd(residual[finite])
      } else {
        NA_real_
      },
      residual_skewness = residual_skewness,
      residual_qq_correlation = qq_correlation,
      residual_absolute_fitted_spearman = residual_fitted_correlation,
      residual_absolute_above_3_fraction = if (any(finite)) {
        mean(abs(residual[finite]) > 3)
      } else {
        NA_real_
      }
    ),
    serial,
    zeros,
    bounds,
    tibble::tibble(
      participant_random_intercept_sd = h10_random_effect_sd(model),
      fit_warnings = warnings,
      fit_error = fit$error,
      diagnostic_assessment = dplyr::case_when(
        major_failure ~ "not acceptable for inference",
        review ~ "acceptable with specified limitations",
        TRUE ~ "acceptable"
      ),
      diagnostic_issues = if (length(issue_codes) == 0L) {
        NA_character_
      } else {
        paste(unique(issue_codes), collapse = " | ")
      }
    )
  )
}

h10_diagnostic_plot_data <- function(model, frame) {
  if (is.null(model)) {
    return(tibble::tibble())
  }
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
    age = frame$age,
    biological_sex = as.character(frame$biological_sex),
    fitted_model_scale = fitted,
    residual_pearson = residual,
    qq_theoretical = theoretical,
    qq_observed = residual
  )
}

h10_top_participant <- function(model, frame) {
  if (is.null(model)) {
    return(NA_character_)
  }
  residual <- tryCatch(
    as.numeric(stats::residuals(model, type = "pearson")),
    error = function(condition) as.numeric(stats::residuals(model))
  )
  tibble::tibble(
    participant_key = as.character(frame$participant_key),
    residual = residual
  ) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::summarise(
      rms_residual = sqrt(mean(.data$residual^2, na.rm = TRUE)),
      maximum_absolute_residual = max(abs(.data$residual), na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      dplyr::desc(.data$rms_residual),
      dplyr::desc(.data$maximum_absolute_residual)
    ) |>
    dplyr::slice_head(n = 1L) |>
    dplyr::pull(.data$participant_key)
}

h10_delete_participant_influence <- function(
  model,
  frame,
  spec,
  predictor,
  full_effect
) {
  participant <- h10_top_participant(model, frame)
  if (length(participant) == 0L || is.na(participant)) {
    return(tibble::tibble(
      deleted_participant = NA_character_,
      deletion_status = "NON_ESTIMABLE"
    ))
  }
  subset <- frame[
    as.character(frame$participant_key) != participant,
    ,
    drop = FALSE
  ]
  subset$site <- droplevels(subset$site)
  stats::contrasts(subset$site) <- stats::contr.sum(nlevels(subset$site))
  subset$Id <- droplevels(subset$Id)
  subset$participant_key <- droplevels(subset$participant_key)
  formula_name <- if (predictor == "age") "M_age" else "M_sex"
  fit <- h10_fit_model(
    subset,
    h10_formula_set(spec$analysis_unit)[[formula_name]],
    spec,
    reml = spec$response_family == "gaussian" &&
      spec$analysis_unit == "participant_day"
  )
  effect <- h10_coefficient_summary(fit$model, predictor, spec)
  status <- h10_model_fit_status(fit$model)
  tibble::tibble(
    deleted_participant = participant,
    observations_after_deletion = nrow(subset),
    participants_after_deletion = dplyr::n_distinct(subset$participant_key),
    estimate_model_after_deletion = effect$estimate_model,
    conf_low_model_after_deletion = effect$conf_low_model,
    conf_high_model_after_deletion = effect$conf_high_model,
    estimate_change_from_full = effect$estimate_model -
      full_effect$estimate_model,
    change_in_full_standard_errors = ifelse(
      is.finite(full_effect$standard_error) && full_effect$standard_error > 0,
      abs(effect$estimate_model - full_effect$estimate_model) /
        full_effect$standard_error,
      NA_real_
    ),
    sign_reversal = ifelse(
      is.finite(effect$estimate_model) &&
        is.finite(full_effect$estimate_model) &&
        full_effect$estimate_model != 0,
      sign(effect$estimate_model) != sign(full_effect$estimate_model),
      NA
    ),
    converged = status$converged,
    positive_definite_hessian = status$positive_definite_hessian,
    singular = status$singular,
    warnings = paste(fit$warnings, collapse = " | "),
    error = fit$error,
    deletion_status = if (
      is.null(fit$model) ||
        !isTRUE(status$converged) ||
        !isTRUE(status$positive_definite_hessian)
    ) {
      "UNSTABLE_OR_NON_ESTIMABLE"
    } else if (
      isTRUE(
        abs(effect$estimate_model - full_effect$estimate_model) /
          full_effect$standard_error >=
          1
      )
    ) {
      "REVIEW_CHANGE_AT_LEAST_ONE_FULL_STANDARD_ERROR"
    } else {
      "PASS_DESCRIPTIVE_CHECK"
    }
  )
}

h10_fit_index_rows <- function(bundle) {
  ml <- dplyr::bind_rows(lapply(names(bundle$ml_fits), function(model_name) {
    fit <- bundle$ml_fits[[model_name]]
    model <- fit$model
    dplyr::bind_cols(
      tibble::tibble(
        fit_role = "maximum_likelihood_comparison",
        model_name = model_name,
        formula = paste(
          deparse(bundle$formulas[[model_name]]),
          collapse = " "
        ),
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
      h10_model_fit_status(model),
      h10_model_condition(model)
    )
  }))
  final <- dplyr::bind_rows(lapply(
    names(bundle$final_fits),
    function(model_name) {
      fit <- bundle$final_fits[[model_name]]
      model <- fit$model
      dplyr::bind_cols(
        tibble::tibble(
          fit_role = if (
            bundle$spec$response_family == "gaussian" &&
              bundle$spec$analysis_unit == "participant_day"
          ) {
            "REML_final_estimation"
          } else {
            "final_estimation_same_as_ML"
          },
          model_name = model_name,
          formula = paste(
            deparse(bundle$formulas[[model_name]]),
            collapse = " "
          ),
          engine = if (is.null(model)) NA_character_ else class(model)[1L],
          observations = if (is.null(model)) NA_integer_ else
            stats::nobs(model),
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
        h10_model_fit_status(model),
        h10_model_condition(model)
      )
    }
  ))
  dplyr::bind_rows(ml, final)
}

h10_loso_refit <- function(frame, spec, predictor, omitted_site) {
  subset <- frame[as.character(frame$site) != omitted_site, , drop = FALSE]
  subset$site <- droplevels(subset$site)
  stats::contrasts(subset$site) <- stats::contr.sum(nlevels(subset$site))
  subset$Id <- droplevels(subset$Id)
  subset$participant_key <- droplevels(subset$participant_key)
  formulas <- h10_formula_set(spec$analysis_unit)
  full_name <- if (predictor == "age") "M_age" else "M_sex"
  reduced <- h10_fit_model(subset, formulas$M0, spec, reml = FALSE)
  full_ml <- h10_fit_model(subset, formulas[[full_name]], spec, reml = FALSE)
  comparison <- h10_compare_models(reduced, full_ml)
  final <- if (
    spec$response_family == "gaussian" &&
      spec$analysis_unit == "participant_day"
  ) {
    h10_fit_model(subset, formulas[[full_name]], spec, reml = TRUE)
  } else {
    full_ml
  }
  effect <- h10_coefficient_summary(final$model, predictor, spec)
  status <- h10_model_fit_status(final$model)
  dplyr::bind_cols(
    tibble::tibble(
      omitted_site = omitted_site,
      observations = nrow(subset),
      participants = dplyr::n_distinct(subset$participant_key),
      sites = nlevels(subset$site)
    ),
    comparison,
    effect,
    status |>
      dplyr::rename_with(~ paste0("final_", .x)),
    tibble::tibble(
      fit_warnings = paste(
        c(reduced$warnings, full_ml$warnings, final$warnings),
        collapse = " | "
      ),
      fit_errors = paste(
        stats::na.omit(c(reduced$error, full_ml$error, final$error)),
        collapse = " | "
      )
    )
  )
}
