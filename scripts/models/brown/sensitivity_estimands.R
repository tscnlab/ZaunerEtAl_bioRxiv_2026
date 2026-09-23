
state_label <- c(
  `Wake outside the three hours before sleep` = "Wake",
  `Pre-sleep` = "Pre-sleep",
  `Sleep environment` = "Sleep"
)

make_grid <- function(bundle) {
  frame <- bundle$design_object$frame
  grid <- expand.grid(
    analysis_state = levels(frame$analysis_state),
    site = levels(frame$site),
    day_type = levels(frame$day_type),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  grid$analysis_state <- factor(
    grid$analysis_state,
    levels = levels(frame$analysis_state)
  )
  grid$site <- factor(grid$site, levels = levels(frame$site))
  grid$day_type <- factor(grid$day_type, levels = levels(frame$day_type))
  for (variable in c("analysis_state", "site", "day_type")) {
    contrasts(grid[[variable]]) <- stats::contr.sum(nlevels(grid[[variable]]))
  }
  grid$boundary_one_state <- factor(
    as.character(grid$analysis_state),
    levels = c("Pre-sleep", "Sleep environment")
  )
  grid$cell_id <- seq_len(nrow(grid))
  grid
}

make_object <- function(bundle, nodes) {
  specification <- bundle$specification
  grid <- make_grid(bundle)
  quadrature <- statmod::gauss.quad.prob(nodes, dist = "normal")
  data <- list(
    X_mu_cell = ba_boundary_model_matrix(
      ba_boundary_fixed_formulas[[specification$fixed_rung]],
      grid
    ),
    X_zero_cell = ba_boundary_model_matrix(
      ba_boundary_zero_formulas[[specification$zero_rung]],
      grid
    ),
    X_one_cell = ba_boundary_one_matrix(
      ba_boundary_one_formulas[[specification$one_rung]],
      grid
    ),
    X_disp_cell = ba_boundary_model_matrix(
      ba_boundary_dispersion_formulas[[specification$dispersion_rung]],
      grid
    ),
    one_active_cell = as.integer(!is.na(grid$boundary_one_state)),
    use_zero_component = as.integer(specification$use_zero_component),
    gh_nodes = quadrature$nodes,
    gh_weights = quadrature$weights
  )
  full_parameters <- bundle$parameter_list
  parameters <- list(
    beta_mu = full_parameters$beta_mu,
    beta_zero = full_parameters$beta_zero,
    beta_one = full_parameters$beta_one,
    beta_disp = full_parameters$beta_disp,
    log_sd_mu_part = full_parameters$log_sd_mu_part
  )
  map <- if (!specification$use_zero_component) {
    list(beta_zero = factor(rep(NA, length(parameters$beta_zero))))
  } else {
    NULL
  }
  objective <- TMB::MakeADFun(
    data = data,
    parameters = parameters,
    map = map,
    DLL = "endpoint_inflated_sensitivity_estimands",
    silent = TRUE
  )
  if (!identical(names(objective$par), names(bundle$optimizer$par))) {
    stop("Sensitivity estimator parameter order mismatch.", call. = FALSE)
  }
  if (max(abs(objective$par - bundle$optimizer$par)) > 1e-10) {
    stop("Sensitivity estimator parameter values mismatch.", call. = FALSE)
  }
  list(objective = objective, grid = grid)
}

extract_uncertain <- function(bundle, estimator) {
  hessian <- solve(bundle$covariance_fixed)
  report <- TMB::sdreport(
    estimator$objective,
    par.fixed = estimator$objective$par,
    hessian.fixed = hessian,
    getReportCovariance = TRUE
  )
  expected_names <- rep(
    c("cell_mean", "cell_pi_zero", "cell_pi_one", "cell_pi_beta", "cell_phi"),
    each = 54L
  )
  if (!identical(names(report$value), expected_names)) {
    stop("Sensitivity ADREPORT order mismatch.", call. = FALSE)
  }
  list(
    value = report$value,
    standard_error = report$sd,
    covariance = report$cov,
    report = report
  )
}

linear_result <- function(contrast, estimate, covariance) {
  point <- sum(contrast * estimate)
  variance <- as.numeric(contrast %*% covariance %*% contrast)
  standard_error <- sqrt(max(variance, 0))
  data.table::data.table(
    estimate = point,
    standard_error = standard_error,
    conf_low = point - stats::qnorm(0.975) * standard_error,
    conf_high = point + stats::qnorm(0.975) * standard_error
  )
}

cell_contrast <- function(grid, state, site, day_type) {
  contrast <- numeric(nrow(grid))
  selected <- as.character(grid$analysis_state) == state &
    as.character(grid$site) == site &
    as.character(grid$day_type) == day_type
  if (sum(selected) != 1L) {
    stop("Sensitivity reference cell is not unique.", call. = FALSE)
  }
  contrast[selected] <- 1
  contrast
}

derive_one <- function(scenario_id, model_path) {
  bundle <- readRDS(model_path)
  estimator_15 <- make_object(bundle, 15L)
  estimator_30 <- make_object(bundle, 30L)
  point_15 <- estimator_15$objective$report(estimator_15$objective$par)
  point_30 <- estimator_30$objective$report(estimator_30$objective$par)
  uncertain <- extract_uncertain(bundle, estimator_30)
  grid <- estimator_30$grid
  states <- levels(grid$analysis_state)
  sites <- levels(grid$site)
  day_types <- levels(grid$day_type)
  mean_estimate <- uncertain$value[seq_len(54L)]
  mean_covariance <- uncertain$covariance[
    seq_len(54L),
    seq_len(54L),
    drop = FALSE
  ]
  cell_predictions <- data.table::as.data.table(grid)
  cell_predictions[, `:=`(
    scenario_id = scenario_id,
    analysis_state = as.character(analysis_state),
    site = as.character(site),
    day_type = as.character(day_type),
    adherence = mean_estimate,
    adherence_standard_error = uncertain$standard_error[seq_len(54L)],
    extra_all_zero_probability = uncertain$value[54L + seq_len(54L)],
    extra_all_one_probability = uncertain$value[
      108L +
        seq_len(54L)
    ],
    beta_binomial_component_probability = uncertain$value[162L + seq_len(54L)],
    beta_binomial_precision = uncertain$value[
      216L +
        seq_len(54L)
    ]
  )]
  cell_predictions[, `:=`(
    adherence_conf_low = adherence -
      stats::qnorm(0.975) * adherence_standard_error,
    adherence_conf_high = adherence +
      stats::qnorm(0.975) * adherence_standard_error
  )]
  equal_site_means <- data.table::rbindlist(lapply(states, function(state) {
    data.table::rbindlist(lapply(day_types, function(day_type) {
      contrast <- Reduce(
        `+`,
        lapply(sites, function(site) {
          cell_contrast(grid, state, site, day_type)
        })
      ) /
        length(sites)
      cbind(
        data.table::data.table(
          scenario_id = scenario_id,
          analysis_state = state,
          state_display = unname(state_label[state]),
          day_type = day_type,
          weighting = "equal_site"
        ),
        linear_result(contrast, mean_estimate, mean_covariance)
      )
    }))
  }))
  m1 <- data.table::rbindlist(lapply(states, function(state) {
    free <- Reduce(
      `+`,
      lapply(sites, function(site) {
        cell_contrast(grid, state, site, "Free day")
      })
    ) /
      length(sites)
    work <- Reduce(
      `+`,
      lapply(sites, function(site) {
        cell_contrast(grid, state, site, "Work day")
      })
    ) /
      length(sites)
    cbind(
      data.table::data.table(
        scenario_id = scenario_id,
        analysis_state = state,
        state_display = unname(state_label[state]),
        contrast = "Free day minus Work day",
        weighting = "equal_site"
      ),
      linear_result(free - work, mean_estimate, mean_covariance)
    )
  }))
  quadrature <- data.table::rbindlist(lapply(
    names(point_30),
    function(measure) {
      difference <- max(abs(point_30[[measure]] - point_15[[measure]]))
      data.table::data.table(
        scenario_id = scenario_id,
        measure = measure,
        maximum_absolute_difference_percentage_points = 100 *
          difference,
        passed = is.finite(difference) && 100 * difference <= 0.05
      )
    }
  ))
  list(
    bundle = bundle,
    grid = grid,
    mean_estimate = mean_estimate,
    mean_covariance = mean_covariance,
    cell_predictions = cell_predictions,
    equal_site_means = equal_site_means,
    m1 = m1,
    quadrature = quadrature
  )
}
