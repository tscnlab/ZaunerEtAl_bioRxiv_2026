record_result <- function(objective, result, method, pass, elapsed_seconds) {
  gradient <- tryCatch(
    objective$gr(result$par),
    error = function(error) rep(NA_real_, length(result$par))
  )
  result$maximum_absolute_gradient <- if (all(is.na(gradient))) {
    NA_real_
  } else {
    max(abs(gradient), na.rm = TRUE)
  }
  result$last_par_best <- objective$env$last.par.best
  list(
    result = result,
    log = data.table::data.table(
      pass = pass,
      method = method,
      convergence = result$convergence,
      objective = result$objective,
      maximum_absolute_gradient = result$maximum_absolute_gradient,
      message = paste(result$message, collapse = " | "),
      elapsed_seconds = elapsed_seconds
    )
  )
}

cs_fit_deletion <- function(frame, refit_id, primary_bundle) {
  fit_started <- proc.time()[["elapsed"]]
  design <- cs_build_design(frame, "F3", "R3")
  parameters <- cs_initial_parameters(design, warm_bundle = primary_bundle)
  if (length(primary_bundle$parameter_list$beta_mu) != length(parameters$beta_mu)) {
    old_frame <- design$frame
    for (variable in c("target_state", "site", "day_type")) {
      old_frame[[variable]] <- factor(
        as.character(old_frame[[variable]]),
        levels = primary_bundle$design_object$levels[[variable]]
      )
      contrasts(old_frame[[variable]]) <- stats::contr.sum(
        nlevels(old_frame[[variable]])
      )
    }
    old_matrix <- cs_model_matrix(cs_fixed_formulas$F3, old_frame)
    target_eta <- as.numeric(
      old_matrix %*% primary_bundle$parameter_list$beta_mu
    )
    parameters$beta_mu <- unname(qr.solve(design$data$X_mu, target_eta))
  }
  objective <- cs_make_object(design, parameters, silent = TRUE)
  results <- list()
  logs <- list()

  run_nlminb <- function(start, pass, iter_max, eval_max) {
    started <- proc.time()[["elapsed"]]
    raw <- stats::nlminb(
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
    recorded <- record_result(
      objective,
      raw,
      "nlminb",
      pass,
      proc.time()[["elapsed"]] - started
    )
    results[[length(results) + 1L]] <<- recorded$result
    logs[[length(logs) + 1L]] <<- recorded$log
    recorded$result
  }
  run_bfgs <- function(start, random_start, pass) {
    objective$env$last.par <- random_start
    objective$env$last.par.best <- random_start
    started <- proc.time()[["elapsed"]]
    raw <- stats::optim(
      par = start,
      fn = objective$fn,
      gr = objective$gr,
      method = "BFGS",
      control = list(maxit = 1000L, reltol = 1e-10, trace = 0)
    )
    candidate <- list(
      par = raw$par,
      objective = raw$value,
      convergence = raw$convergence,
      message = if (is.null(raw$message)) {
        "BFGS relative convergence"
      } else {
        raw$message
      }
    )
    recorded <- record_result(
      objective,
      candidate,
      "BFGS",
      pass,
      proc.time()[["elapsed"]] - started
    )
    results[[length(results) + 1L]] <<- recorded$result
    logs[[length(logs) + 1L]] <<- recorded$log
    recorded$result
  }

  first <- run_nlminb(objective$par, 1L, 2500L, 5000L)
  if (
    first$convergence != 0L ||
      !is.finite(first$maximum_absolute_gradient) ||
      first$maximum_absolute_gradient > 0.001
  ) {
    invisible(run_nlminb(first$par, 2L, 5000L, 10000L))
  }
  current_log <- data.table::rbindlist(logs)
  finite <- which(
    is.finite(current_log$objective) &
      is.finite(current_log$maximum_absolute_gradient)
  )
  provisional_index <- finite[[which.min(
    current_log$maximum_absolute_gradient[finite]
  )]]
  provisional <- results[[provisional_index]]
  if (
    provisional$convergence != 0L ||
      provisional$maximum_absolute_gradient > 0.001
  ) {
    invisible(run_bfgs(
      provisional$par,
      provisional$last_par_best,
      length(results) + 1L
    ))
  }
  optimization_log <- data.table::rbindlist(logs)
  eligible <- which(
    optimization_log$convergence == 0L &
      is.finite(optimization_log$maximum_absolute_gradient) &
      optimization_log$maximum_absolute_gradient <= 0.01
  )
  selected_index <- if (length(eligible) > 0L) {
    eligible[[which.min(optimization_log$objective[eligible])]]
  } else {
    finite <- which(
      is.finite(optimization_log$objective) &
        is.finite(optimization_log$maximum_absolute_gradient)
    )
    finite[[which.min(optimization_log$maximum_absolute_gradient[finite])]]
  }
  optimizer <- results[[selected_index]]
  optimization_log[, selected := seq_len(.N) == selected_index]

  objective$env$last.par <- optimizer$last_par_best
  objective$env$last.par.best <- optimizer$last_par_best
  invisible(objective$fn(optimizer$par))
  fixed_gradient <- tryCatch(
    objective$gr(optimizer$par),
    error = function(error) rep(NA_real_, length(optimizer$par))
  )
  sd_report <- tryCatch(
    TMB::sdreport(objective, getJointPrecision = FALSE),
    error = function(error) error
  )
  sd_error <- inherits(sd_report, "error")
  if (sd_error) {
    fixed_summary <- data.table::data.table(
      parameter = character(), estimate = numeric(), standard_error = numeric()
    )
    covariance <- matrix(NA_real_, 1L, 1L)
    pd_hessian <- FALSE
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
    covariance <- as.matrix(sd_report$cov.fixed)
    pd_hessian <- isTRUE(sd_report$pdHess)
  }
  parameter_list <- tryCatch(
    objective$env$parList(x = optimizer$par, par = objective$env$last.par.best),
    error = function(error) parameters
  )
  maximum_gradient <- if (all(is.na(fixed_gradient))) {
    NA_real_
  } else {
    max(abs(fixed_gradient), na.rm = TRUE)
  }
  covariance_finite <- all(is.finite(covariance))
  minimum_covariance_eigenvalue <- if (covariance_finite) {
    min(eigen(covariance, symmetric = TRUE, only.values = TRUE)$values)
  } else {
    NA_real_
  }
  lengths <- c(
    ncol(design$data$X_mu), ncol(design$data$X_zero),
    ncol(design$data$X_one), ncol(design$data$X_disp), 1L
  )
  fixed_finite <- nrow(fixed_summary) == sum(lengths) &&
    all(is.finite(fixed_summary$estimate)) &&
    all(is.finite(fixed_summary$standard_error))
  endpoint_indices <- seq.int(
    lengths[[1L]] + 1L,
    sum(lengths[1:3])
  )
  maximum_endpoint_coefficient <- if (fixed_finite) {
    max(abs(fixed_summary$estimate[endpoint_indices]))
  } else {
    Inf
  }
  maximum_endpoint_standard_error <- if (fixed_finite) {
    max(fixed_summary$standard_error[endpoint_indices])
  } else {
    Inf
  }
  participant_sd <- exp(parameter_list$log_sd_mu_part[[1L]])
  participant_log_sd_se <- if (fixed_finite) {
    fixed_summary$standard_error[[sum(lengths)]]
  } else {
    Inf
  }
  structural_failure <-
    optimizer$convergence != 0L ||
    !is.finite(maximum_gradient) || maximum_gradient > 0.01 ||
    !pd_hessian || !fixed_finite || !covariance_finite ||
    !is.finite(minimum_covariance_eigenvalue) ||
    minimum_covariance_eigenvalue <= 0 ||
    maximum_endpoint_coefficient > 15 ||
    maximum_endpoint_standard_error > 10 ||
    !is.finite(participant_sd) || participant_sd < 1e-4 ||
    !is.finite(participant_log_sd_se) || participant_log_sd_se > 10
  fit_status <- if (structural_failure) {
    "structural_failure"
  } else if (maximum_gradient > 0.001) {
    "acceptable_with_cautions"
  } else {
    "acceptable"
  }
  check <- data.table::data.table(
    refit_id = refit_id,
    rows = nrow(design$frame),
    participants = nlevels(design$frame$participant_cluster),
    sites = nlevels(design$frame$site),
    convergence = optimizer$convergence,
    maximum_absolute_gradient = maximum_gradient,
    positive_definite_hessian = pd_hessian,
    minimum_covariance_eigenvalue = minimum_covariance_eigenvalue,
    maximum_endpoint_coefficient = maximum_endpoint_coefficient,
    maximum_endpoint_standard_error = maximum_endpoint_standard_error,
    participant_standard_deviation = participant_sd,
    participant_log_sd_standard_error = participant_log_sd_se,
    fit_status = fit_status,
    structural_failure = structural_failure,
    initialization = "selected_primary_fixed_effect_warm_start",
    optimization_seconds = proc.time()[["elapsed"]] - fit_started,
    optimization_passes = nrow(optimization_log)
  )
  bundle <- list(
    model_id = refit_id,
    sample_id = "primary_any_valid",
    frame_variant = "bounded_refit",
    specification = design$specification,
    design_object = design,
    optimizer = optimizer,
    optimization_log = optimization_log,
    fit_check = check,
    fixed_summary = fixed_summary,
    covariance_fixed = covariance,
    parameter_list = parameter_list,
    last_par_best = objective$env$last.par.best
  )
  effects <- if (structural_failure) {
    data.table::data.table()
  } else {
    cs_summarize_four_effects(bundle, refit_id, include_uncertainty = TRUE)
  }
  list(bundle = bundle, check = check, effects = effects)
}
