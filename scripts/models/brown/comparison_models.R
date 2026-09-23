
ba_formula_f3_r0 <- cbind(brown_yes, brown_no) ~
  analysis_state *
    site *
    day_type +
    diag(1 + analysis_state + day_type | participant_id) +
    (1 | behavioral_day_id)

ba_formula_f3_r1 <- cbind(brown_yes, brown_no) ~
  analysis_state *
    site *
    day_type +
    diag(1 + analysis_state | participant_id) +
    (1 | behavioral_day_id)

ba_formula_f3_r1b <- cbind(brown_yes, brown_no) ~
  analysis_state *
    site *
    day_type +
    diag(1 + day_type | participant_id) +
    (1 | behavioral_day_id)

ba_formula_f3_r2 <- cbind(brown_yes, brown_no) ~
  analysis_state *
    site *
    day_type +
    (1 | participant_id) +
    (1 | behavioral_day_id)

ba_formula_f3_r3 <- cbind(brown_yes, brown_no) ~
  analysis_state * site * day_type + (1 | participant_id)

ba_formula_f2_r0 <- cbind(brown_yes, brown_no) ~
  analysis_state *
    site +
    analysis_state * day_type +
    site * day_type +
    diag(1 + analysis_state + day_type | participant_id) +
    (1 | behavioral_day_id)

ba_formula_f1_r0 <- cbind(brown_yes, brown_no) ~
  analysis_state *
    site +
    analysis_state * day_type +
    diag(1 + analysis_state + day_type | participant_id) +
    (1 | behavioral_day_id)

ba_formula_f0_r0 <- cbind(brown_yes, brown_no) ~
  analysis_state +
    site +
    day_type +
    diag(1 + analysis_state + day_type | participant_id) +
    (1 | behavioral_day_id)

ba_formula_calendar <- cbind(brown_yes, brown_no) ~
  analysis_state *
    site *
    day_type +
    diag(1 + analysis_state + day_type | participant_id) +
    (1 | behavioral_day_id) +
    (1 | participant_calendar_day_id)

ba_formula_chest <- cbind(brown_yes, brown_no) ~
  analysis_state *
    site *
    day_type +
    diag(1 + analysis_state + day_type | participant_id) +
    (1 | behavioral_day_id)

ba_formula_fractional <- brown_fraction ~ analysis_state * site * day_type

ba_dispersion_state <- ~analysis_state
ba_dispersion_common <- ~1

ba_formula_text <- function(formula) {
  paste(deparse(formula, width.cutoff = 500L), collapse = " ")
}

ba_prepare_factor_frame <- function(data) {
  output <- droplevels(as.data.frame(data))
  factors <- c("analysis_state", "site", "day_type")
  for (factor_name in factors) {
    if (!factor_name %in% names(output)) {
      stop(
        sprintf("Model frame lacks `%s`.", factor_name),
        call. = FALSE
      )
    }
    if (nlevels(output[[factor_name]]) < 2L) {
      stop(
        sprintf("Model factor `%s` has fewer than two levels.", factor_name),
        call. = FALSE
      )
    }
    contrasts(output[[factor_name]]) <- stats::contr.sum(
      nlevels(output[[factor_name]])
    )
  }
  output$participant_id <- droplevels(factor(output$participant_id))
  output$behavioral_day_id <- droplevels(factor(output$behavioral_day_id))
  if ("participant_calendar_day_id" %in% names(output)) {
    output$participant_calendar_day_id <- droplevels(
      factor(output$participant_calendar_day_id)
    )
  }
  output
}

ba_fit_beta_binomial <- function(
  data,
  formula,
  dispersion_formula = ba_dispersion_state
) {
  glmmTMB::glmmTMB(
    formula = formula,
    data = data,
    family = glmmTMB::betabinomial(link = "logit"),
    ziformula = ~0,
    dispformula = dispersion_formula,
    REML = FALSE,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 2000L, eval.max = 3000L),
      rank_check = "warning",
      conv_check = "warning"
    )
  )
}

ba_fit_binomial <- function(data, formula) {
  glmmTMB::glmmTMB(
    formula = formula,
    data = data,
    family = stats::binomial(link = "logit"),
    ziformula = ~0,
    REML = FALSE,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 2000L, eval.max = 3000L),
      rank_check = "warning",
      conv_check = "warning"
    )
  )
}

ba_random_sd <- function(model) {
  variance_components <- glmmTMB::VarCorr(model)$cond
  output <- lapply(names(variance_components), function(group_name) {
    standard_deviation <- attr(
      variance_components[[group_name]],
      "stddev",
      exact = TRUE
    )
    data.frame(
      group = group_name,
      term = names(standard_deviation),
      standard_deviation = as.numeric(standard_deviation),
      stringsAsFactors = FALSE
    )
  })
  data.table::rbindlist(output, use.names = TRUE, fill = TRUE)
}

ba_assess_fit <- function(
  model,
  data,
  model_id,
  sample_id,
  formula_id,
  dispersion_id,
  elapsed_seconds,
  family_name = "beta-binomial"
) {
  conditional_coefficients <- glmmTMB::fixef(model)$cond
  dispersion_coefficients <- glmmTMB::fixef(model)$disp
  conditional_vcov <- tryCatch(
    as.matrix(stats::vcov(model)$cond),
    error = function(error) matrix(NA_real_, 1L, 1L)
  )
  full_vcov <- tryCatch(
    as.matrix(model$sdr$cov.fixed),
    error = function(error) matrix(NA_real_, 1L, 1L)
  )
  full_eigenvalues <- tryCatch(
    eigen(full_vcov, symmetric = TRUE, only.values = TRUE)$values,
    error = function(error) NA_real_
  )
  fixed_design <- stats::model.matrix(model, component = "cond")
  random_sd <- ba_random_sd(model)
  gradient <- tryCatch(
    as.numeric(model$sdr$gradient.fixed),
    error = function(error) NA_real_
  )

  convergence_code <- model$fit$convergence
  positive_definite_hessian <- isTRUE(model$sdr$pdHess)
  maximum_absolute_gradient <- if (all(is.na(gradient))) {
    NA_real_
  } else {
    max(abs(gradient), na.rm = TRUE)
  }
  minimum_full_vcov_eigenvalue <- if (all(is.na(full_eigenvalues))) {
    NA_real_
  } else {
    min(full_eigenvalues, na.rm = TRUE)
  }
  minimum_random_sd <- if (nrow(random_sd) == 0L) {
    NA_real_
  } else {
    min(random_sd$standard_deviation, na.rm = TRUE)
  }
  boundary_index <- if (nrow(random_sd) == 0L) {
    logical()
  } else {
    random_sd$standard_deviation < 1e-4
  }
  boundary_random_terms <- if (nrow(random_sd) == 0L || !any(boundary_index)) {
    character()
  } else {
    paste0(
      random_sd$group[boundary_index],
      "::",
      random_sd$term[boundary_index]
    )
  }
  finite_coefficients <- all(is.finite(c(
    conditional_coefficients,
    dispersion_coefficients
  )))
  finite_conditional_vcov <- all(is.finite(conditional_vcov))
  fixed_rank <- qr(fixed_design)$rank
  fixed_columns <- ncol(fixed_design)
  fixed_condition_number <- tryCatch(
    kappa(fixed_design, exact = FALSE),
    error = function(error) Inf
  )
  maximum_absolute_coefficient <- max(abs(c(
    conditional_coefficients,
    dispersion_coefficients
  )))
  optimizer_message <- if (is.null(model$fit$message)) {
    ""
  } else {
    paste(model$fit$message, collapse = " | ")
  }

  hard_failure <-
    convergence_code != 0L ||
    !positive_definite_hessian ||
    !finite_coefficients ||
    !finite_conditional_vcov ||
    fixed_rank != fixed_columns ||
    !is.finite(minimum_full_vcov_eigenvalue) ||
    minimum_full_vcov_eigenvalue <= 0 ||
    (!is.na(maximum_absolute_gradient) && maximum_absolute_gradient > 0.01)
  random_boundary <- length(boundary_random_terms) > 0L
  large_coefficient_caution <- maximum_absolute_coefficient > 10
  fit_status <- if (hard_failure) {
    "not_acceptable"
  } else if (random_boundary || large_coefficient_caution) {
    "acceptable_with_limitations"
  } else {
    "acceptable"
  }

  fit_diagnostics <- data.table::data.table(
    model_id = model_id,
    sample_id = sample_id,
    formula_id = formula_id,
    dispersion_id = dispersion_id,
    family = family_name,
    link = "logit",
    estimation = "maximum likelihood with Laplace approximation",
    state_rows = nrow(data),
    participants = data.table::uniqueN(data$participant_id),
    behavioral_days = data.table::uniqueN(data$behavioral_day_id),
    valid_brown_checks = sum(data$valid_minutes),
    in_range_checks = sum(data$brown_yes),
    elapsed_seconds = elapsed_seconds,
    log_likelihood = as.numeric(stats::logLik(model)),
    aic = stats::AIC(model),
    convergence_code = convergence_code,
    optimizer_message = optimizer_message,
    positive_definite_hessian = positive_definite_hessian,
    maximum_absolute_gradient = maximum_absolute_gradient,
    fixed_rank = fixed_rank,
    fixed_columns = fixed_columns,
    fixed_condition_number = fixed_condition_number,
    finite_coefficients = finite_coefficients,
    finite_conditional_vcov = finite_conditional_vcov,
    minimum_full_vcov_eigenvalue = minimum_full_vcov_eigenvalue,
    maximum_absolute_coefficient = maximum_absolute_coefficient,
    minimum_random_sd = minimum_random_sd,
    boundary_random_terms = paste(boundary_random_terms, collapse = " | "),
    random_boundary = random_boundary,
    large_coefficient_caution = large_coefficient_caution,
    hard_failure = hard_failure,
    fit_status = fit_status
  )

  list(fit_diagnostics = fit_diagnostics, random_sd = random_sd)
}


fit_fractional <- function(data, weighted, model_id) {
  model_data <- ba_prepare_factor_frame(data)
  model_data$analysis_weight <- if (weighted) {
    model_data$valid_minutes
  } else {
    rep(1, nrow(model_data))
  }
  cat(sprintf("Fitting %s ...\n", model_id))
  started <- proc.time()[["elapsed"]]
  warnings <- character()
  model <- withCallingHandlers(
    stats::glm(
      formula = ba_formula_fractional,
      data = model_data,
      family = stats::quasibinomial(link = "logit"),
      weights = analysis_weight
    ),
    warning = function(warning) {
      warnings <<- c(warnings, conditionMessage(warning))
      invokeRestart("muffleWarning")
    }
  )
  robust_vcov <- sandwich::vcovCL(
    model,
    cluster = model_data$participant_id,
    type = "HC3"
  )
  elapsed_seconds <- proc.time()[["elapsed"]] - started
  design <- stats::model.matrix(model)
  robust_eigen <- eigen(
    robust_vcov,
    symmetric = TRUE,
    only.values = TRUE
  )$values
  fit_diagnostics <- data.table::data.table(
    model_id = model_id,
    sample_id = "primary_any_valid",
    formula_id = "BA-FRACTIONAL",
    dispersion_id = "quasi-dispersion",
    family = "fractional quasibinomial",
    link = "logit",
    estimation = "quasi-likelihood with participant-cluster HC3 covariance",
    state_rows = nrow(model_data),
    participants = data.table::uniqueN(model_data$participant_id),
    behavioral_days = data.table::uniqueN(model_data$behavioral_day_id),
    valid_brown_checks = sum(model_data$valid_minutes),
    in_range_checks = sum(model_data$brown_yes),
    elapsed_seconds = elapsed_seconds,
    convergence_code = as.integer(!isTRUE(model$converged)),
    optimizer_message = paste(unique(warnings), collapse = " | "),
    positive_definite_hessian = NA,
    maximum_absolute_gradient = NA_real_,
    fixed_rank = model$rank,
    fixed_columns = ncol(design),
    fixed_condition_number = kappa(design, exact = FALSE),
    finite_coefficients = all(is.finite(stats::coef(model))),
    finite_conditional_vcov = all(is.finite(robust_vcov)),
    minimum_full_vcov_eigenvalue = min(robust_eigen),
    maximum_absolute_coefficient = max(abs(stats::coef(model))),
    minimum_random_sd = NA_real_,
    boundary_random_terms = "",
    random_boundary = FALSE,
    large_coefficient_caution = max(abs(stats::coef(model))) > 10,
    hard_failure = !isTRUE(model$converged) ||
      model$rank != ncol(design) ||
      any(!is.finite(stats::coef(model))) ||
      any(!is.finite(robust_vcov)) ||
      min(robust_eigen) <= 0,
    fit_status = NA_character_
  )
  fit_diagnostics[,
    fit_status := data.table::fcase(
      hard_failure,
      "not_acceptable",
      large_coefficient_caution,
      "acceptable_with_limitations",
      default = "acceptable"
    )
  ]
  cat(sprintf(
    "Finished %s in %.1f seconds with status `%s`.\n",
    model_id,
    elapsed_seconds,
    fit_diagnostics$fit_status[[1L]]
  ))
  list(
    model = model,
    data = model_data,
    robust_vcov = robust_vcov,
    weighted = weighted,
    fit_diagnostics = fit_diagnostics
  )
}
