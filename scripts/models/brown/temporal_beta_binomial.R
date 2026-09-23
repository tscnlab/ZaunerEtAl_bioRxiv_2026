formula_r0_ou <- cbind(brown_yes, brown_no) ~
  analysis_state * site * day_type +
  diag(1 + analysis_state + day_type | participant_id) +
  (1 | behavioral_day_id) +
  ou(behavior_date_factor + 0 | participant_state_id)

formula_r3_ou <- cbind(brown_yes, brown_no) ~
  analysis_state * site * day_type +
  (1 | participant_id) +
  ou(behavior_date_factor + 0 | participant_state_id)

prepare_ou_frame <- function(raw_frame) {
  data <- ba_prepare_factor_frame(raw_frame)
  data$participant_state_id <- droplevels(factor(data$participant_state_id))
  actual_date <- as.Date(data$behavior_date)
  if (anyNA(actual_date)) {
    stop("OU frame has missing actual dates.", call. = FALSE)
  }
  date_index <- as.numeric(actual_date - min(actual_date))
  data$behavior_date_factor <- glmmTMB::numFactor(date_index)
  duplicate_check <- data.table::as.data.table(data)[, .N,
    by = .(participant_state_id, behavior_date_factor)][N > 1L]
  if (nrow(duplicate_check) > 0L) {
    stop("OU frame has duplicate actual dates within a participant-state series.", call. = FALSE)
  }
  data
}

fit_model <- function(data, formula) {
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  model <- withCallingHandlers(
    ba_fit_beta_binomial(data, formula, ba_dispersion_state),
    warning = function(warning) {
      warnings <<- c(warnings, conditionMessage(warning))
      invokeRestart("muffleWarning")
    }
  )
  list(
    model = model,
    elapsed_seconds = proc.time()[["elapsed"]] - started,
    warnings = paste(unique(warnings), collapse = " | ")
  )
}

extract_ou_parameters <- function(model) {
  covariance <- glmmTMB::VarCorr(model)$cond$participant_state_id
  coordinates <- as.numeric(glmmTMB::parseNumLevels(rownames(covariance))[, 1L])
  correlation <- attr(covariance, "correlation", exact = TRUE)
  one_day_pairs <- which(
    abs(outer(coordinates, coordinates, `-`)) == 1,
    arr.ind = TRUE
  )
  rho_one_day <- mean(correlation[one_day_pairs])
  decay_rate <- -log(rho_one_day)
  data.table::data.table(
    ou_standard_deviation = unname(attr(covariance, "stddev", exact = TRUE)[[1L]]),
    one_day_correlation = rho_one_day,
    ou_decay_rate_per_day = decay_rate,
    ou_half_life_days = log(2) / decay_rate,
    coordinate_levels = length(coordinates),
    minimum_coordinate = min(coordinates),
    maximum_coordinate = max(coordinates)
  )
}

assess_fit <- function(result, data, model_id, sample_id, random_rung) {
  model <- result$model
  conditional_vcov <- tryCatch(
    as.matrix(stats::vcov(model)$cond),
    error = function(error) matrix(NA_real_, 1L, 1L)
  )
  full_vcov <- tryCatch(
    as.matrix(model$sdr$cov.fixed),
    error = function(error) matrix(NA_real_, 1L, 1L)
  )
  eigenvalues <- tryCatch(
    eigen(full_vcov, symmetric = TRUE, only.values = TRUE)$values,
    error = function(error) NA_real_
  )
  gradient <- tryCatch(as.numeric(model$sdr$gradient.fixed), error = function(error) NA_real_)
  random_sd <- ba_random_sd(model)
  fixed_design <- stats::model.matrix(model, component = "cond")
  ou <- extract_ou_parameters(model)
  participant_sd <- random_sd[
    group == "participant_id" & term == "(Intercept)",
    standard_deviation
  ]
  if (length(participant_sd) == 0L) participant_sd <- NA_real_
  behavioral_day_sd <- random_sd[
    group == "behavioral_day_id" & term == "(Intercept)",
    standard_deviation
  ]
  if (length(behavioral_day_sd) == 0L) behavioral_day_sd <- NA_real_
  maximum_gradient <- if (all(is.na(gradient))) NA_real_ else max(abs(gradient), na.rm = TRUE)
  minimum_eigenvalue <- if (all(is.na(eigenvalues))) NA_real_ else min(eigenvalues)
  hard_failure <-
    model$fit$convergence != 0L ||
    !isTRUE(model$sdr$pdHess) ||
    !all(is.finite(c(glmmTMB::fixef(model)$cond, glmmTMB::fixef(model)$disp))) ||
    !all(is.finite(conditional_vcov)) ||
    qr(fixed_design)$rank != ncol(fixed_design) ||
    !is.finite(minimum_eigenvalue) ||
    minimum_eigenvalue <= 0 ||
    !is.finite(maximum_gradient) ||
    maximum_gradient > 0.01
  random_boundary <- any(random_sd$standard_deviation < 1e-4)
  near_random_boundary <- any(random_sd$standard_deviation < 1e-3)
  status <- if (hard_failure || random_boundary) {
    "structural_failure"
  } else if (near_random_boundary || nzchar(result$warnings)) {
    "acceptable_with_limitations"
  } else {
    "acceptable"
  }
  cbind(
    data.table::data.table(
      model_id = model_id,
      sample_id = sample_id,
      family = "beta-binomial",
      link = "logit",
      fixed_rung = "F3",
      random_rung = random_rung,
      dispersion_rung = "D0",
      state_rows = nrow(data),
      participants = data.table::uniqueN(data$participant_id),
      behavioral_days = data.table::uniqueN(data$behavioral_day_id),
      temporal_series = data.table::uniqueN(data$participant_state_id),
      convergence = model$fit$convergence,
      optimizer_message = paste(model$fit$message, collapse = " | "),
      maximum_absolute_gradient = maximum_gradient,
      positive_definite_hessian = isTRUE(model$sdr$pdHess),
      fixed_rank = qr(fixed_design)$rank,
      fixed_columns = ncol(fixed_design),
      covariance_finite = all(is.finite(full_vcov)),
      minimum_covariance_eigenvalue = minimum_eigenvalue,
      minimum_random_standard_deviation = min(random_sd$standard_deviation),
      participant_standard_deviation = participant_sd,
      behavioral_day_standard_deviation = behavioral_day_sd,
      random_boundary = random_boundary,
      near_random_boundary = near_random_boundary,
      fit_status = status,
      structural_failure = status == "structural_failure",
      elapsed_seconds = result$elapsed_seconds,
      warnings = result$warnings
    ),
    ou
  )
}

make_grid <- function(data) {
  grid <- expand.grid(
    analysis_state = levels(data$analysis_state),
    site = levels(data$site),
    day_type = levels(data$day_type),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  for (variable in c("analysis_state", "site", "day_type")) {
    grid[[variable]] <- factor(grid[[variable]], levels = levels(data[[variable]]))
    contrasts(grid[[variable]]) <- stats::contr.sum(nlevels(grid[[variable]]))
  }
  grid
}
