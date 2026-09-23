cs_fit <- function(frames, sample_id, model_id, fixed_rung = "F3", random_rung = "R3", frame_variant = "primary", warm_bundle = NULL) {
raw_frame <- frames[[sample_id]]
if (frame_variant == "complete_pair") {
  raw_frame <- droplevels(raw_frame[raw_frame$complete_target_pair, , drop = FALSE])
}
if (frame_variant == "equal_daytype") {
  raw_frame <- raw_frame[raw_frame$eligible_equal_daytype, , drop = FALSE]
  raw_frame$wake_within_10pp <- raw_frame$wake_equal_daytype_within_10pp
  raw_frame$wake_between_centered_10pp <-
    raw_frame$wake_equal_daytype_between_centered_10pp
  raw_frame <- droplevels(raw_frame)
}
if (frame_variant == "date_trend") {
  raw_frame <- data.table::as.data.table(raw_frame)
  cycle_date <- unique(raw_frame[, .(
    participant_cluster,
    association_cycle_cluster,
    anchor_date = as.Date(anchor_date)
  )])
  cycle_date[, participant_mean_date := mean(as.numeric(anchor_date)),
    by = participant_cluster]
  cycle_date[, participant_centered_date :=
    as.numeric(anchor_date) - participant_mean_date]
  raw_frame <- merge(
    raw_frame,
    cycle_date[, .(
      participant_cluster,
      association_cycle_cluster,
      participant_centered_date
    )],
    by = c("participant_cluster", "association_cycle_cluster"),
    all.x = TRUE,
    sort = FALSE
  )
  if (anyNA(raw_frame$participant_centered_date)) {
    stop("Participant-centered actual date could not be constructed.", call. = FALSE)
  }
  raw_frame <- droplevels(as.data.frame(raw_frame))
  cs_fixed_formulas$F3_DATE <- ~
    target_state * site * day_type +
    target_state * wake_within_10pp +
    target_state * wake_between_centered_10pp +
    target_state * wake_free_fraction_centered_10pp +
    target_state * participant_centered_date
}
if (frame_variant == "thinned") {
  raw_frame <- data.table::as.data.table(raw_frame)
  raw_frame[, source_order__ := .I]
  data.table::setorder(
    raw_frame,
    participant_cluster,
    target_state,
    anchor_date,
    association_cycle_cluster
  )
  raw_frame[, retain_temporally_thinned__ := {
    dates <- as.Date(anchor_date)
    keep <- logical(.N)
    if (.N > 0L) {
      keep[[1L]] <- TRUE
      last_date <- dates[[1L]]
      if (.N > 1L) {
        for (index in 2:.N) {
          if (as.integer(dates[[index]] - last_date) >= 2L) {
            keep[[index]] <- TRUE
            last_date <- dates[[index]]
          }
        }
      }
    }
    keep
  }, by = .(participant_cluster, target_state)]
  raw_frame <- raw_frame[retain_temporally_thinned__ == TRUE]
  data.table::setorder(raw_frame, source_order__)
  raw_frame[, c("source_order__", "retain_temporally_thinned__") := NULL]
  raw_frame <- droplevels(as.data.frame(raw_frame))
}
if (!fixed_rung %in% names(cs_fixed_formulas)) {
  stop("Unknown fixed rung.", call. = FALSE)
}

design_object <- cs_build_design(raw_frame, fixed_rung, random_rung)
initial_parameters <- cs_initial_parameters(design_object, warm_bundle)
if (!is.null(warm_bundle) &&
    length(warm_bundle$parameter_list$beta_mu) != length(initial_parameters$beta_mu)) {
  old_frame <- design_object$frame
  old_levels <- warm_bundle$design_object$levels
  for (variable in c("target_state", "site", "day_type")) {
    old_frame[[variable]] <- factor(
      as.character(old_frame[[variable]]),
      levels = old_levels[[variable]]
    )
    contrasts(old_frame[[variable]]) <- stats::contr.sum(nlevels(old_frame[[variable]]))
  }
  old_matrix <- cs_model_matrix(
    cs_fixed_formulas[[warm_bundle$specification$fixed_rung]],
    old_frame
  )
  target_eta <- as.numeric(old_matrix %*% warm_bundle$parameter_list$beta_mu)
  initial_parameters$beta_mu <- unname(qr.solve(
    design_object$data$X_mu,
    target_eta
  ))
}

objective <- cs_make_object(design_object, initial_parameters, silent = TRUE)
fit_started_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
fit_started <- proc.time()[["elapsed"]]
results <- list()
logs <- list()

record_result <- function(result, method, pass, elapsed_seconds) {
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
  results[[length(results) + 1L]] <<- result
  logs[[length(logs) + 1L]] <<- data.table::data.table(
    pass = pass,
    method = method,
    convergence = result$convergence,
    objective = result$objective,
    maximum_absolute_gradient = result$maximum_absolute_gradient,
    message = paste(result$message, collapse = " | "),
    elapsed_seconds = elapsed_seconds
  )
  result
}

run_nlminb <- function(start, pass, iter_max, eval_max) {
  started <- proc.time()[["elapsed"]]
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
  record_result(
    result,
    "nlminb",
    pass,
    proc.time()[["elapsed"]] - started
  )
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
  result <- list(
    par = raw$par,
    objective = raw$value,
    convergence = raw$convergence,
    message = if (is.null(raw$message)) "BFGS relative convergence" else raw$message
  )
  record_result(
    result,
    "BFGS",
    pass,
    proc.time()[["elapsed"]] - started
  )
}

first <- run_nlminb(objective$par, 1L, 2500L, 5000L)
if (
  first$convergence != 0L ||
    !is.finite(first$maximum_absolute_gradient) ||
    first$maximum_absolute_gradient > 0.001
) {
  second <- run_nlminb(first$par, 2L, 5000L, 10000L)
}
current_log <- data.table::rbindlist(logs)
finite <- which(
  is.finite(current_log$objective) &
    is.finite(current_log$maximum_absolute_gradient)
)
if (length(finite) == 0L) {
  stop("No optimizer pass returned a finite objective and gradient.", call. = FALSE)
}
provisional_index <- finite[[which.min(
  current_log$maximum_absolute_gradient[finite]
)]]
provisional <- results[[provisional_index]]
if (
  provisional$convergence != 0L &&
    (
      provisional$maximum_absolute_gradient <= 0.01 ||
        frame_variant == "date_trend"
    )
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
optimization_seconds <- proc.time()[["elapsed"]] - fit_started

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
sd_error <- inherits(sd_report, "error")
if (sd_error) {
  fixed_summary <- data.table::data.table(
    parameter = character(),
    estimate = numeric(),
    standard_error = numeric()
  )
  covariance_fixed <- matrix(NA_real_, 1L, 1L)
  positive_definite_hessian <- FALSE
  sd_message <- conditionMessage(sd_report)
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
  sd_message <- ""
}

parameter_list <- tryCatch(
  objective$env$parList(x = optimizer$par, par = objective$env$last.par.best),
  error = function(error) initial_parameters
)
maximum_gradient <- if (all(is.na(fixed_gradient))) {
  NA_real_
} else {
  max(abs(fixed_gradient), na.rm = TRUE)
}
covariance_finite <- all(is.finite(covariance_fixed))
minimum_covariance_eigenvalue <- if (covariance_finite) {
  tryCatch(
    min(eigen(covariance_fixed, symmetric = TRUE, only.values = TRUE)$values),
    error = function(error) NA_real_
  )
} else {
  NA_real_
}
fixed_finite <- all(is.finite(optimizer$par)) &&
  nrow(fixed_summary) == length(optimizer$par) &&
  all(is.finite(fixed_summary$standard_error))
endpoint_rows <- fixed_summary$parameter %in% c("beta_zero", "beta_one")
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

participant_sd <- exp(parameter_list$log_sd_mu_part[[1L]])
cycle_sd <- if (random_rung == "R0") exp(parameter_list$log_sd_day) else NA_real_
participant_log_sd_row <- fixed_summary$parameter == "log_sd_mu_part"
cycle_log_sd_row <- fixed_summary$parameter == "log_sd_day"
participant_log_sd_se <- if (sum(participant_log_sd_row) == 1L) {
  fixed_summary$standard_error[participant_log_sd_row]
} else {
  NA_real_
}
cycle_log_sd_se <- if (sum(cycle_log_sd_row) == 1L) {
  fixed_summary$standard_error[cycle_log_sd_row]
} else {
  NA_real_
}
participant_nonidentifiable <- !is.finite(participant_log_sd_se) ||
  participant_log_sd_se > 10
cycle_nonidentifiable <- random_rung == "R0" &&
  (!is.finite(cycle_log_sd_se) || cycle_log_sd_se > 10)
participant_boundary <- !is.finite(participant_sd) || participant_sd < 1e-4
cycle_boundary <- random_rung == "R0" &&
  (!is.finite(cycle_sd) || cycle_sd < 1e-4)

report_available <- all(c(
  "pi_zero",
  "pi_one",
  "pi_beta",
  "conditional_mean",
  "conditional_variance"
) %in% names(report))
endpoint_interior <- report_available &&
  all(report$pi_zero > 1e-12 & report$pi_zero < 1 - 1e-12) &&
  all(report$pi_one > 1e-12 & report$pi_one < 1 - 1e-12) &&
  all(report$pi_beta > 1e-12 & report$pi_beta < 1 - 1e-12)
report_finite <- report_available && all(is.finite(c(
  report$pi_zero,
  report$pi_one,
  report$pi_beta,
  report$conditional_mean,
  report$conditional_variance
)))

association_terms <- c("wake_within_10pp", "wake_between_centered_10pp")
association_indices <- unlist(lapply(association_terms, function(term) {
  grep(term, colnames(design_object$data$X_mu), fixed = TRUE)
}))
association_estimable <- length(association_indices) == 4L &&
  fixed_finite && all(is.finite(fixed_summary$standard_error[association_indices]))

hard_fit_failure <-
  optimizer$convergence != 0L ||
  !is.finite(optimizer$objective) ||
  !is.finite(maximum_gradient) ||
  maximum_gradient > 0.01 ||
  !positive_definite_hessian ||
  !fixed_finite ||
  !covariance_finite ||
  !is.finite(minimum_covariance_eigenvalue) ||
  minimum_covariance_eigenvalue <= 0 ||
  !report_finite ||
  !endpoint_interior
endpoint_separation <-
  !is.finite(maximum_endpoint_coefficient) ||
  maximum_endpoint_coefficient > 15 ||
  !is.finite(maximum_endpoint_standard_error) ||
  maximum_endpoint_standard_error > 10
structural_failure <-
  hard_fit_failure ||
  endpoint_separation ||
  participant_boundary ||
  cycle_boundary ||
  participant_nonidentifiable ||
  cycle_nonidentifiable ||
  !association_estimable
fit_status <- if (structural_failure) {
  "structural_failure"
} else if (
  maximum_gradient > 0.001 || participant_sd > 5 ||
    (is.finite(cycle_sd) && cycle_sd > 5) ||
    maximum_endpoint_coefficient > 10
) {
  "acceptable_with_cautions"
} else {
  "acceptable"
}
failure_components <- c(
  if (hard_fit_failure) "hard_fit_check" else character(),
  if (endpoint_separation) "endpoint_separation" else character(),
  if (participant_boundary) "participant_random_boundary" else character(),
  if (cycle_boundary) "association_cycle_random_boundary" else character(),
  if (participant_nonidentifiable) "participant_random_nonidentifiable" else character(),
  if (cycle_nonidentifiable) "association_cycle_random_nonidentifiable" else character(),
  if (!association_estimable) "wake_association_nonestimable" else character()
)

fit_check <- data.table::data.table(
  model_id = model_id,
  sample_id = sample_id,
  frame_variant = frame_variant,
  family = "endpoint_inflated_beta_binomial",
  fixed_rung = fixed_rung,
  random_rung = random_rung,
  zero_rung = "Q2",
  one_rung = "Q1",
  dispersion_rung = "D0",
  rows = nrow(design_object$frame),
  participants = nlevels(design_object$frame$participant_cluster),
  cycles = nlevels(design_object$frame$association_cycle_cluster),
  convergence = optimizer$convergence,
  objective = optimizer$objective,
  maximum_absolute_gradient = maximum_gradient,
  positive_definite_hessian = positive_definite_hessian,
  fixed_parameters_finite = fixed_finite,
  covariance_finite = covariance_finite,
  minimum_covariance_eigenvalue = minimum_covariance_eigenvalue,
  maximum_endpoint_coefficient = maximum_endpoint_coefficient,
  maximum_endpoint_standard_error = maximum_endpoint_standard_error,
  endpoint_probability_interior = endpoint_interior,
  participant_standard_deviation = participant_sd,
  association_cycle_standard_deviation = cycle_sd,
  participant_log_sd_standard_error = participant_log_sd_se,
  association_cycle_log_sd_standard_error = cycle_log_sd_se,
  participant_random_boundary = participant_boundary,
  association_cycle_random_boundary = cycle_boundary,
  participant_random_nonidentifiable = participant_nonidentifiable,
  association_cycle_random_nonidentifiable = cycle_nonidentifiable,
  wake_association_estimable = association_estimable,
  fit_status = fit_status,
  structural_failure = structural_failure,
  failure_components = paste(failure_components, collapse = " | "),
  optimizer_message = paste(optimizer$message, collapse = " | "),
  sdreport_message = sd_message,
  optimization_seconds = optimization_seconds,
  optimization_passes = nrow(optimization_log)
)

mean_terms <- colnames(design_object$data$X_mu)
zero_terms <- colnames(design_object$data$X_zero)
one_terms <- colnames(design_object$data$X_one)
dispersion_terms <- colnames(design_object$data$X_disp)
fixed_summary[, `:=`(model_id = model_id, sample_id = sample_id)]
fixed_summary[, component := data.table::fcase(
  seq_len(.N) <= length(mean_terms), "mean",
  seq_len(.N) <= length(mean_terms) + length(zero_terms), "extra_all_zero",
  seq_len(.N) <= length(mean_terms) + length(zero_terms) + length(one_terms),
    "extra_all_one",
  seq_len(.N) <= length(mean_terms) + length(zero_terms) +
    length(one_terms) + length(dispersion_terms), "dispersion",
  default = "random_standard_deviation"
)]
term_labels <- c(
  mean_terms,
  zero_terms,
  one_terms,
  dispersion_terms,
  "log_sd_participant",
  if (random_rung == "R0") "log_sd_association_cycle" else character()
)
if (length(term_labels) == nrow(fixed_summary)) {
  fixed_summary[, term := term_labels]
} else {
  fixed_summary[, term := parameter]
}
optimization_log[, `:=`(model_id = model_id, sample_id = sample_id)]

endpoint_range <- if (report_available) {
  data.table::data.table(
    target_state = as.character(design_object$frame$target_state),
    pi_zero = report$pi_zero,
    pi_one = report$pi_one,
    pi_beta = report$pi_beta,
    conditional_mean = report$conditional_mean
  )[, .(
    rows = .N,
    minimum_pi_zero = min(pi_zero),
    median_pi_zero = stats::median(pi_zero),
    maximum_pi_zero = max(pi_zero),
    minimum_pi_one = min(pi_one),
    median_pi_one = stats::median(pi_one),
    maximum_pi_one = max(pi_one),
    minimum_pi_beta = min(pi_beta),
    median_pi_beta = stats::median(pi_beta),
    maximum_pi_beta = max(pi_beta),
    minimum_conditional_mean = min(conditional_mean),
    median_conditional_mean = stats::median(conditional_mean),
    maximum_conditional_mean = max(conditional_mean)
  ), by = target_state]
} else {
  data.table::data.table()
}
endpoint_range[, `:=`(model_id = model_id, sample_id = sample_id)]

bundle <- list(
  model_id = model_id,
  sample_id = sample_id,
  frame_variant = frame_variant,
  specification = design_object$specification,
  design_object = design_object,
  initial_parameters = initial_parameters,
  optimizer = optimizer,
  optimization_log = optimization_log,
  fit_check = fit_check,
  fixed_summary = fixed_summary,
  covariance_fixed = covariance_fixed,
  parameter_list = parameter_list,
  last_par_best = objective$env$last.par.best,
  report = report,
  endpoint_range = endpoint_range
)

bundle
}
