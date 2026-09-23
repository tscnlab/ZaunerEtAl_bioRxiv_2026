# The same optimizer sequence is used for independent and temporal models.
brown_optimize <- function(objective) {
  fit_started_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  fit_started <- proc.time()[["elapsed"]]
  optimization_passes <- list()
  optimization_results <- list()

  record_optimizer_result <- function(
    result,
    method,
    pass,
    iter_max,
    eval_max,
    pass_started
  ) {
    gradient <- tryCatch(
      objective$gr(result$par),
      error = function(error) rep(NA_real_, length(result$par))
    )
    maximum_gradient <- if (all(is.na(gradient))) {
      NA_real_
    } else {
      max(abs(gradient), na.rm = TRUE)
    }
    result$maximum_absolute_gradient <- maximum_gradient
    result$last_par_best <- objective$env$last.par.best
    optimization_results[[length(optimization_results) + 1L]] <<- result
    optimization_passes[[length(optimization_passes) + 1L]] <<-
      data.table::data.table(
        pass = pass,
        method = method,
        iterations_allowed = iter_max,
        evaluations_allowed = eval_max,
        convergence = result$convergence,
        objective = result$objective,
        maximum_absolute_gradient = maximum_gradient,
        message = paste(result$message, collapse = " | "),
        elapsed_seconds = proc.time()[["elapsed"]] - pass_started
      )
    result
  }

  fit_nlminb <- function(start, pass, iter_max, eval_max) {
    pass_started <- proc.time()[["elapsed"]]
    result <- stats::nlminb(
      start = start,
      objective = objective$fn,
      gradient = objective$gr,
      control = list(
        iter.max = iter_max,
        eval.max = eval_max,
        rel.tol = 1e-10,
        x.tol = 1e-8,
        trace = 0
      )
    )
    record_optimizer_result(
      result = result,
      method = "nlminb",
      pass = pass,
      iter_max = iter_max,
      eval_max = eval_max,
      pass_started = pass_started
    )
  }

  fit_bfgs <- function(start, random_start, pass, iter_max) {
    objective$env$last.par <- random_start
    objective$env$last.par.best <- random_start
    pass_started <- proc.time()[["elapsed"]]
    raw_result <- stats::optim(
      par = start,
      fn = objective$fn,
      gr = objective$gr,
      method = "BFGS",
      control = list(
        maxit = iter_max,
        reltol = 1e-10,
        trace = 0
      )
    )
    result <- list(
      par = raw_result$par,
      objective = raw_result$value,
      convergence = raw_result$convergence,
      iterations = unname(raw_result$counts[["gradient"]]),
      evaluations = raw_result$counts,
      message = if (is.null(raw_result$message)) {
        "BFGS relative convergence"
      } else {
        raw_result$message
      }
    )
    record_optimizer_result(
      result = result,
      method = "BFGS",
      pass = pass,
      iter_max = iter_max,
      eval_max = iter_max,
      pass_started = pass_started
    )
  }

  first_optimizer <- fit_nlminb(
    objective$par,
    pass = 1L,
    iter_max = 2000L,
    eval_max = 4000L
  )
  first_gradient <- optimization_passes[[1L]]$maximum_absolute_gradient
  if (
    first_optimizer$convergence != 0L ||
      !is.finite(first_gradient) ||
      first_gradient > 0.001
  ) {
    second_optimizer <- fit_nlminb(
      first_optimizer$par,
      pass = 2L,
      iter_max = 4000L,
      eval_max = 8000L
    )
  }

  optimization_log <- data.table::rbindlist(optimization_passes)
  eligible_converged <- which(
    optimization_log$convergence == 0L &
      is.finite(optimization_log$maximum_absolute_gradient) &
      optimization_log$maximum_absolute_gradient <= 0.01
  )
  provisional_index <- if (length(eligible_converged) > 0L) {
    eligible_converged[[which.min(optimization_log$objective[
      eligible_converged
    ])]]
  } else {
    finite_gradient <- which(
      is.finite(optimization_log$maximum_absolute_gradient) &
        is.finite(optimization_log$objective)
    )
    if (length(finite_gradient) > 0L) {
      finite_gradient[[which.min(
        optimization_log$maximum_absolute_gradient[finite_gradient]
      )]]
    } else {
      which.min(optimization_log$objective)
    }
  }
  provisional_optimizer <- optimization_results[[provisional_index]]

  if (
    provisional_optimizer$convergence != 0L &&
      is.finite(provisional_optimizer$maximum_absolute_gradient) &&
      provisional_optimizer$maximum_absolute_gradient <= 0.01
  ) {
    next_pass <- length(optimization_results) + 1L
    bfgs_optimizer <- fit_bfgs(
      start = provisional_optimizer$par,
      random_start = provisional_optimizer$last_par_best,
      pass = next_pass,
      iter_max = 500L
    )
  }

  optimization_seconds <- proc.time()[["elapsed"]] - fit_started
  optimization_log <- data.table::rbindlist(optimization_passes)

  eligible_converged <- which(
    optimization_log$convergence == 0L &
      is.finite(optimization_log$maximum_absolute_gradient) &
      optimization_log$maximum_absolute_gradient <= 0.01
  )
  selected_index <- if (length(eligible_converged) > 0L) {
    eligible_converged[[which.min(optimization_log$objective[
      eligible_converged
    ])]]
  } else {
    finite_gradient <- which(
      is.finite(optimization_log$maximum_absolute_gradient) &
        is.finite(optimization_log$objective)
    )
    if (length(finite_gradient) > 0L) {
      finite_gradient[[which.min(
        optimization_log$maximum_absolute_gradient[finite_gradient]
      )]]
    } else {
      which.min(optimization_log$objective)
    }
  }
  optimizer <- optimization_results[[selected_index]]
  optimization_log[, selected := seq_len(.N) == selected_index]
  list(optimizer = optimizer, log = optimization_log, seconds = optimization_seconds)
}


ba_lb_fit_candidate <- function(
  design_object,
  initial_parameters,
  model_id,
  sample_id
) {
  fixed_rung <- design_object$specification$fixed_rung
  random_rung <- design_object$specification$random_rung
  zero_rung <- design_object$specification$zero_rung
  one_rung <- design_object$specification$one_rung
  dispersion_rung <- design_object$specification$dispersion_rung
  use_zero_component <- design_object$specification$use_zero_component
  objective <- ba_boundary_make_object(
    design_object,
    initial_parameters,
    silent = TRUE
  )

  optimized <- brown_optimize(objective)
  optimizer <- optimized$optimizer
  optimization_log <- optimized$log
  optimization_seconds <- optimized$seconds

  objective$env$last.par <- optimizer$last_par_best
  objective$env$last.par.best <- optimizer$last_par_best
  invisible(objective$fn(optimizer$par))
  fixed_gradient <- tryCatch(
    objective$gr(optimizer$par),
    error = function(error) rep(NA_real_, length(optimizer$par))
  )
  report <- tryCatch(
    objective$report(),
    error = function(error) list(report_error = conditionMessage(error))
  )
  sd_report <- tryCatch(
    TMB::sdreport(objective, getJointPrecision = FALSE),
    error = function(error) error
  )
  sd_report_error <- inherits(sd_report, "error")

  if (sd_report_error) {
    fixed_summary <- data.table::data.table(
      parameter = character(),
      estimate = numeric(),
      standard_error = numeric()
    )
    covariance_fixed <- matrix(NA_real_, 1L, 1L)
    positive_definite_hessian <- FALSE
    sd_report_message <- conditionMessage(sd_report)
  } else {
    fixed_summary <- data.table::as.data.table(
      summary(sd_report, "fixed"),
      keep.rownames = "parameter"
    )
    data.table::setnames(
      fixed_summary,
      c("Estimate", "Std. Error"),
      c("estimate", "standard_error")
    )
    covariance_fixed <- as.matrix(sd_report$cov.fixed)
    positive_definite_hessian <- isTRUE(sd_report$pdHess)
    sd_report_message <- ""
  }

  parameter_list <- tryCatch(
    objective$env$parList(
      x = optimizer$par,
      par = objective$env$last.par.best
    ),
    error = function(error) NULL
  )
  if (is.null(parameter_list)) {
    parameter_list <- initial_parameters
  }

  random_sd <- data.table::rbindlist(
    list(
      data.table::data.table(
        component = "mean_participant",
        term = colnames(design_object$data$Z_mu_part),
        standard_deviation = exp(parameter_list$log_sd_mu_part),
        active = TRUE
      ),
      data.table::data.table(
        component = "mean_behavioral_day",
        term = "(Intercept)",
        standard_deviation = exp(parameter_list$log_sd_day),
        active = design_object$data$use_day_re == 1L
      ),
      data.table::data.table(
        component = "extra_all_no_participant",
        term = "(Intercept)",
        standard_deviation = exp(parameter_list$log_sd_zero),
        active = design_object$data$use_zero_re == 1L
      ),
      data.table::data.table(
        component = "extra_all_yes_participant",
        term = "(Intercept)",
        standard_deviation = exp(parameter_list$log_sd_one),
        active = design_object$data$use_one_re == 1L
      )
    ),
    use.names = TRUE,
    fill = TRUE
  )
  random_sd[, model_id := model_id]
  random_sd[, sample_id := sample_id]

  fixed_parameter_names <- names(optimizer$par)
  maximum_absolute_gradient <- if (all(is.na(fixed_gradient))) {
    NA_real_
  } else {
    max(abs(fixed_gradient), na.rm = TRUE)
  }
  covariance_finite <- all(is.finite(covariance_fixed))
  covariance_eigenvalues <- if (covariance_finite) {
    tryCatch(
      eigen(covariance_fixed, symmetric = TRUE, only.values = TRUE)$values,
      error = function(error) NA_real_
    )
  } else {
    NA_real_
  }
  minimum_covariance_eigenvalue <- if (all(is.na(covariance_eigenvalues))) {
    NA_real_
  } else {
    min(covariance_eigenvalues)
  }
  fixed_finite <- all(is.finite(optimizer$par)) &&
    nrow(fixed_summary) == length(optimizer$par) &&
    all(is.finite(fixed_summary$standard_error))
  endpoint_rows <- grepl("^beta_zero|^beta_one", fixed_summary$parameter)
  maximum_endpoint_coefficient <- if (any(endpoint_rows)) {
    max(abs(fixed_summary$estimate[endpoint_rows]))
  } else {
    NA_real_
  }
  maximum_endpoint_standard_error <- if (any(endpoint_rows)) {
    max(fixed_summary$standard_error[endpoint_rows])
  } else {
    NA_real_
  }

  mean_random_boundary <- any(
    random_sd$active &
      random_sd$component %in%
        c(
          "mean_participant",
          "mean_behavioral_day"
        ) &
      random_sd$standard_deviation < 1e-4
  )
  zero_random_boundary <- any(
    random_sd$active &
      random_sd$component == "extra_all_no_participant" &
      random_sd$standard_deviation < 1e-4
  )
  one_random_boundary <- any(
    random_sd$active &
      random_sd$component == "extra_all_yes_participant" &
      random_sd$standard_deviation < 1e-4
  )

  report_available <- all(
    c(
      "pi_zero",
      "pi_one",
      "pi_beta",
      "conditional_mean",
      "conditional_variance"
    ) %in%
      names(report)
  )
  if (report_available) {
    active_one <- design_object$data$one_active == 1L
    pure_beta <- !use_zero_component & !active_one
    endpoint_probability_interior <-
      (if (use_zero_component) {
        all(report$pi_zero > 1e-12 & report$pi_zero < 1 - 1e-12)
      } else {
        all(report$pi_zero == 0)
      }) &&
      all(report$pi_one[active_one] > 1e-12) &&
      all(report$pi_one[active_one] < 1 - 1e-12) &&
      all(report$pi_beta[!pure_beta] > 1e-12) &&
      all(report$pi_beta[!pure_beta] < 1 - 1e-12) &&
      all(report$pi_beta[pure_beta] == 1)
    report_finite <- all(is.finite(c(
      report$pi_zero,
      report$pi_one,
      report$pi_beta,
      report$conditional_mean,
      report$conditional_variance
    )))
  } else {
    endpoint_probability_interior <- FALSE
    report_finite <- FALSE
  }

  hard_failure <-
    optimizer$convergence != 0L ||
    !is.finite(optimizer$objective) ||
    !is.finite(maximum_absolute_gradient) ||
    maximum_absolute_gradient > 0.01 ||
    !positive_definite_hessian ||
    !fixed_finite ||
    !covariance_finite ||
    !is.finite(minimum_covariance_eigenvalue) ||
    minimum_covariance_eigenvalue <= 0 ||
    !report_finite ||
    !endpoint_probability_interior

  separation_failure <-
    is.finite(maximum_endpoint_coefficient) &&
    (maximum_endpoint_coefficient > 15 ||
      !is.finite(maximum_endpoint_standard_error) ||
      maximum_endpoint_standard_error > 10)

  structural_failure <- hard_failure ||
    separation_failure ||
    mean_random_boundary ||
    zero_random_boundary ||
    one_random_boundary

  fit_status <- if (structural_failure) {
    "structural_failure"
  } else if (
    maximum_absolute_gradient > 0.001 ||
      any(random_sd$active & random_sd$standard_deviation > 5) ||
      maximum_endpoint_coefficient > 10
  ) {
    "acceptable_with_cautions"
  } else {
    "acceptable"
  }

  failure_components <- c(
    if (hard_failure) "hard_fit_diagnostics" else character(),
    if (separation_failure) "endpoint_separation" else character(),
    if (mean_random_boundary) "mean_random_boundary" else character(),
    if (zero_random_boundary) "all_no_random_boundary" else character(),
    if (one_random_boundary) "all_yes_random_boundary" else character()
  )

  fit_diagnostics <- data.table::data.table(
    model_id = model_id,
    sample_id = sample_id,
    family = "endpoint_inflated_beta_binomial",
    fixed_rung = fixed_rung,
    random_rung = random_rung,
    zero_rung = zero_rung,
    one_rung = one_rung,
    dispersion_rung = dispersion_rung,
    use_zero_component = use_zero_component,
    rows = nrow(design_object$frame),
    participants = nlevels(design_object$frame$participant_id),
    behavioral_days = nlevels(design_object$frame$behavioral_day_id),
    convergence = optimizer$convergence,
    objective = optimizer$objective,
    maximum_absolute_gradient = maximum_absolute_gradient,
    positive_definite_hessian = positive_definite_hessian,
    fixed_parameters_finite = fixed_finite,
    covariance_finite = covariance_finite,
    minimum_covariance_eigenvalue = minimum_covariance_eigenvalue,
    maximum_endpoint_coefficient = maximum_endpoint_coefficient,
    maximum_endpoint_standard_error = maximum_endpoint_standard_error,
    endpoint_probability_interior = endpoint_probability_interior,
    mean_random_boundary = mean_random_boundary,
    all_no_random_boundary = zero_random_boundary,
    all_yes_random_boundary = one_random_boundary,
    fit_status = fit_status,
    structural_failure = structural_failure,
    failure_components = paste(failure_components, collapse = " | "),
    optimizer_message = paste(optimizer$message, collapse = " | "),
    sdreport_message = sd_report_message,
    optimization_seconds = optimization_seconds,
    optimization_passes = nrow(optimization_log)
  )

  fixed_summary[, `:=`(
    model_id = model_id,
    sample_id = sample_id
  )]
  optimization_log[, `:=`(
    model_id = model_id,
    sample_id = sample_id
  )]

  endpoint_summary <- if (report_available) {
    data.table::rbindlist(lapply(
      levels(design_object$frame$analysis_state),
      function(state) {
        selected <- design_object$frame$analysis_state == state
        data.table::data.table(
          model_id = model_id,
          sample_id = sample_id,
          analysis_state = state,
          rows = sum(selected),
          minimum_pi_zero = min(report$pi_zero[selected]),
          median_pi_zero = stats::median(report$pi_zero[selected]),
          maximum_pi_zero = max(report$pi_zero[selected]),
          minimum_pi_one = min(report$pi_one[selected]),
          median_pi_one = stats::median(report$pi_one[selected]),
          maximum_pi_one = max(report$pi_one[selected]),
          minimum_pi_beta = min(report$pi_beta[selected]),
          median_pi_beta = stats::median(report$pi_beta[selected]),
          maximum_pi_beta = max(report$pi_beta[selected]),
          minimum_mean = min(report$conditional_mean[selected]),
          median_mean = stats::median(report$conditional_mean[selected]),
          maximum_mean = max(report$conditional_mean[selected])
        )
      }
    ))
  } else {
    data.table::data.table()
  }

  bundle <- list(
    model_id = model_id,
    sample_id = sample_id,
    specification = design_object$specification,
    design_object = design_object,
    initial_parameters = initial_parameters,
    optimizer = optimizer,
    optimization_log = optimization_log,
    fit_diagnostics = fit_diagnostics,
    fixed_summary = fixed_summary,
    covariance_fixed = covariance_fixed,
    parameter_list = parameter_list,
    last_par_best = objective$env$last.par.best,
    report = report,
    random_sd = random_sd,
    endpoint_summary = endpoint_summary
  )
  bundle
}
