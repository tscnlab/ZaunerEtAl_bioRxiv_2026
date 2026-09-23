# Integrate every retained temporal random component and preserve uncertainty.

lb_temporal_random_variance <- function(components, grid) {
  stopifnot(
    setequal(names(components), c("participant_id", "participant_state_id")) ||
      setequal(
        names(components),
        c("participant_id", "behavioral_day_id", "participant_state_id")
      )
  )
  participant <- as.matrix(components$participant_id)
  Z <- stats::model.matrix(~ analysis_state + day_type, grid)
  stopifnot(
    all(colnames(participant) %in% colnames(Z)),
    identical(rownames(participant), colnames(participant)),
    all(is.finite(participant))
  )
  Z <- Z[, colnames(participant), drop = FALSE]
  participant_variance <- rowSums((Z %*% participant) * Z)
  cycle_variance <- 0
  if ("behavioral_day_id" %in% names(components)) {
    cycle <- as.matrix(components$behavioral_day_id)
    stopifnot(
      identical(dim(cycle), c(1L, 1L)),
      is.finite(cycle[1L, 1L]),
      cycle[1L, 1L] >= 0
    )
    cycle_variance <- cycle[1L, 1L]
  }
  ou <- as.matrix(components$participant_state_id)
  stopifnot(nrow(ou) == ncol(ou), nrow(ou) >= 2L, all(is.finite(ou)))
  diagonal <- diag(ou)
  stopifnot(
    all(diagonal >= 0),
    max(abs(diagonal - diagonal[1L])) <= 1e-10 * max(1, diagonal[1L])
  )
  total <- participant_variance + cycle_variance + diagonal[1L]
  stopifnot(all(is.finite(total)), all(total >= 0))
  list(
    total = total,
    participant = participant_variance,
    cycle = rep(cycle_variance, nrow(grid)),
    OU = rep(diagonal[1L], nrow(grid))
  )
}

lb_temporal_bb_cells <- function(model, data, nodes) {
  grid <- lb_bb_ou$make_grid(data)
  X <- stats::model.matrix(~ analysis_state * site * day_type, grid)
  beta <- glmmTMB::fixef(model)$cond
  V <- as.matrix(stats::vcov(model)$cond)
  stopifnot(
    identical(colnames(X), names(beta)),
    identical(colnames(X), colnames(V)),
    identical(rownames(V), colnames(V)),
    all(is.finite(V))
  )
  components <- lb_temporal_random_variance(glmmTMB::VarCorr(model)$cond, grid)
  quadrature <- statmod::gauss.quad.prob(nodes, dist = "normal")
  probabilities <- stats::plogis(
    outer(sqrt(components$total), quadrature$nodes) + as.numeric(X %*% beta)
  )
  probability <- as.numeric(probabilities %*% quadrature$weights)
  gradient <- X *
    as.numeric((probabilities * (1 - probabilities)) %*% quadrature$weights)
  list(
    grid = grid,
    probability = probability,
    covariance = gradient %*% V %*% t(gradient),
    gradient = gradient,
    fixed_covariance = V,
    variance_components = components
  )
}

lb_temporal_endpoint_cells <- function(bundle) {
  estimator15 <- lb_endpoint_ou$make_estimand_object(bundle, 15L)
  estimator30 <- lb_endpoint_ou$make_estimand_object(bundle, 30L)
  stopifnot(
    identical(
      names(estimator30$objective$par),
      names(bundle$fixed_parameter_vector)
    ),
    isTRUE(all.equal(
      unname(estimator30$objective$par),
      unname(bundle$fixed_parameter_vector),
      tolerance = 1e-12
    )),
    identical(
      dim(bundle$covariance_fixed),
      c(length(estimator30$objective$par), length(estimator30$objective$par))
    ),
    all(is.finite(bundle$covariance_fixed))
  )
  point15 <- estimator15$objective$report(estimator15$objective$par)
  point30 <- estimator30$objective$report(estimator30$objective$par)
  report <- TMB::sdreport(
    estimator30$objective,
    par.fixed = estimator30$objective$par,
    hessian.fixed = solve(bundle$covariance_fixed),
    getReportCovariance = TRUE
  )
  n <- nrow(estimator30$grid)
  stopifnot(n == 54L, all(names(report$value)[seq_len(n)] == "cell_mean"))
  cells <- list(
    grid = estimator30$grid,
    probability = as.numeric(report$value[seq_len(n)]),
    covariance = report$cov[seq_len(n), seq_len(n), drop = FALSE],
    full_sd_report = report
  )
  delta <- 100 * max(abs(point15$cell_mean - point30$cell_mean))
  stopifnot(
    is.finite(delta),
    delta <= 0.05,
    all(is.finite(cells$covariance)),
    isTRUE(all.equal(
      cells$probability,
      as.numeric(point30$cell_mean),
      tolerance = 1e-12
    ))
  )
  list(cells = cells, quadrature_difference_percentage_points = delta)
}

lb_temporal_contrasts <- function(cells) {
  grid <- cells$grid
  stopifnot(
    nrow(grid) == 54L,
    nlevels(grid$analysis_state) == 3L,
    nlevels(grid$site) == 9L,
    identical(levels(grid$day_type), c("Work day", "Free day")),
    !anyDuplicated(grid[, c("analysis_state", "site", "day_type")]),
    all(is.finite(cells$probability)),
    all(cells$probability >= 0 & cells$probability <= 1),
    all(is.finite(cells$covariance)),
    identical(dim(cells$covariance), c(54L, 54L))
  )
  W <- do.call(
    rbind,
    lapply(levels(grid$analysis_state), function(state) {
      as.numeric(grid$analysis_state == state & grid$day_type == "Free day") /
        9 -
        as.numeric(grid$analysis_state == state & grid$day_type == "Work day") /
          9
    })
  )
  stopifnot(
    all(rowSums(W > 0) == 9L),
    all(rowSums(W < 0) == 9L),
    max(abs(rowSums(W))) < 1e-12
  )
  estimate <- as.numeric(W %*% cells$probability)
  variance <- diag(W %*% cells$covariance %*% t(W))
  stopifnot(all(is.finite(variance)), all(variance >= 0))
  se <- sqrt(variance)
  list(
    contrasts = data.frame(
      analysis_state = levels(grid$analysis_state),
      estimate = estimate,
      standard_error = se,
      conf_low = estimate - stats::qnorm(0.975) * se,
      conf_high = estimate + stats::qnorm(0.975) * se
    ),
    weights = W
  )
}

lb_temporal_report_bundle <- function(bundle) {
  status <- data.frame(
    model_id = bundle$model_id,
    sample_id = bundle$sample_id,
    route = bundle$route,
    fit_status = bundle$fit_diagnostics$fit_status,
    structural_failure = bundle$fit_diagnostics$structural_failure,
    estimates_eligible = !bundle$fit_diagnostics$structural_failure
  )
  if (status$structural_failure) return(list(status = status))
  if (bundle$route == "ENDPOINT-R3") {
    result <- lb_temporal_endpoint_cells(bundle)
    cells <- result$cells
    difference <- result$quadrature_difference_percentage_points
    uncertainty <- "Full fixed-parameter covariance delta method including retained variance parameters"
  } else {
    cells15 <- lb_temporal_bb_cells(bundle$model, bundle$data, 15L)
    cells <- lb_temporal_bb_cells(bundle$model, bundle$data, 30L)
    stopifnot(identical(cells15$grid, cells$grid))
    difference <- 100 * max(abs(cells$probability - cells15$probability))
    uncertainty <- "Full conditional fixed-effect covariance delta method; fitted variance parameters held fixed"
  }
  stopifnot(is.finite(difference), difference <= 0.05)
  result <- lb_temporal_contrasts(cells)
  list(
    status = status,
    contrasts = result$contrasts,
    cells = cells,
    contrast_matrix = result$weights,
    quadrature = data.frame(
      maximum_difference_percentage_points = difference,
      pass = difference <= 0.05
    ),
    uncertainty = uncertainty
  )
}

lb_temporal_prediction_fields <- function(
  frame,
  mu,
  phi,
  pi_zero,
  pi_one,
  pi_beta,
  X,
  V
) {
  n <- as.integer(frame$valid_minutes)
  stopifnot(
    length(mu) == nrow(frame),
    length(phi) == nrow(frame),
    all(is.finite(mu) & mu > 0 & mu < 1),
    all(is.finite(phi) & phi > 0),
    all(is.finite(c(pi_zero, pi_one, pi_beta))),
    all(pi_zero >= 0 & pi_one >= 0 & pi_beta >= 0),
    max(abs(pi_zero + pi_one + pi_beta - 1)) < 1e-12,
    nrow(X) == nrow(frame),
    all(is.finite(V)),
    ncol(X) == ncol(V)
  )
  alpha <- mu * phi
  beta <- (1 - mu) * phi
  p0 <- pi_zero + pi_beta * exp(lbeta(alpha, beta + n) - lbeta(alpha, beta))
  p1 <- pi_one + pi_beta * exp(lbeta(alpha + n, beta) - lbeta(alpha, beta))
  mean <- pi_one + pi_beta * mu
  bb_variance <- mu * (1 - mu) * (phi + n) / (n * (phi + 1))
  variance <- pi_one + pi_beta * (mu^2 + bb_variance) - mean^2
  stopifnot(
    all(is.finite(variance) & variance > 0),
    all(p0 >= 0 & p0 <= 1),
    all(p1 >= 0 & p1 <= 1)
  )
  list(
    frame = frame,
    n = n,
    y = as.integer(frame$brown_yes),
    mu = mu,
    phi = phi,
    pi_zero = pi_zero,
    pi_one = pi_one,
    pi_beta = pi_beta,
    exact_zero_probability = p0,
    exact_one_probability = p1,
    mixed_probability = 1 - p0 - p1,
    conditional_mean = mean,
    conditional_variance = variance,
    fixed_linear_predictor_variance = rowSums((X %*% V) * X)
  )
}

lb_temporal_predictions <- function(bundle) {
  stopifnot(!bundle$fit_diagnostics$structural_failure)
  if (bundle$route == "ENDPOINT-R3") {
    frame <- bundle$design_object$frame
    report <- bundle$report
    X <- bundle$design_object$data$X_mu
    V <- bundle$covariance_fixed[
      seq_len(ncol(X)),
      seq_len(ncol(X)),
      drop = FALSE
    ]
    predictions <- lb_temporal_prediction_fields(
      frame,
      report$mu,
      report$phi,
      report$pi_zero,
      report$pi_one,
      report$pi_beta,
      X,
      V
    )
    stopifnot(
      max(abs(predictions$conditional_mean - report$conditional_mean)) < 1e-10,
      max(abs(predictions$conditional_variance - report$conditional_variance)) <
        1e-10
    )
    return(predictions)
  }
  frame <- bundle$data
  mu <- as.numeric(stats::predict(bundle$model, type = "response"))
  phi <- as.numeric(stats::predict(bundle$model, type = "disp"))
  X <- stats::model.matrix(bundle$model, component = "cond")
  V <- as.matrix(stats::vcov(bundle$model)$cond)
  stopifnot(identical(colnames(X), colnames(V)))
  lb_temporal_prediction_fields(
    frame,
    mu,
    phi,
    rep(0, nrow(frame)),
    rep(0, nrow(frame)),
    rep(1, nrow(frame)),
    X,
    V
  )
}
