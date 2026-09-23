
make_cell_grid <- function(bundle) {
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
    contrasts(grid[[variable]]) <- stats::contr.sum(
      nlevels(grid[[variable]])
    )
  }
  grid$boundary_one_state <- factor(
    as.character(grid$analysis_state),
    levels = c("Pre-sleep", "Sleep environment")
  )
  grid$cell_id <- seq_len(nrow(grid))
  grid
}

make_estimator_data <- function(bundle, nodes) {
  specification <- bundle$specification
  if (
    !identical(
      unname(unlist(specification[c(
        "fixed_rung",
        "random_rung",
        "zero_rung",
        "one_rung",
        "dispersion_rung"
      )])),
      c("F3", "R3", "Q2", "Q1", "D0")
    )
  ) {
    stop("Selected bundle does not use specified F3/R3/Q2/Q1/D0.", call. = FALSE)
  }
  cell_grid <- make_cell_grid(bundle)
  frame <- bundle$design_object$frame
  cell_key <- paste(
    cell_grid$analysis_state,
    cell_grid$site,
    cell_grid$day_type,
    sep = "||"
  )
  frame_key <- paste(
    frame$analysis_state,
    frame$site,
    frame$day_type,
    sep = "||"
  )
  frame_cell <- match(frame_key, cell_key)
  if (anyNA(frame_cell)) {
    stop(
      "Observed rows did not map to the 54-cell reference grid.",
      call. = FALSE
    )
  }
  denominator_support <- data.table::data.table(
    cell_id = frame_cell,
    denominator = as.integer(frame$brown_yes + frame$brown_no)
  )[, .(frequency = .N), by = .(cell_id, denominator)]
  denominator_support[,
    support_weight := frequency / sum(frequency),
    by = cell_id
  ]
  if (
    nrow(cell_grid) != 54L ||
      any(
        abs(
          denominator_support[,
            .(weight = sum(support_weight)),
            by = cell_id
          ]$weight -
            1
        ) >
          1e-12
      )
  ) {
    stop("Reference grid or denominator weights are incomplete.", call. = FALSE)
  }
  quadrature <- statmod::gauss.quad.prob(nodes, dist = "normal")
  data <- list(
    X_mu_cell = ba_boundary_model_matrix(
      ba_boundary_fixed_formulas[[specification$fixed_rung]],
      cell_grid
    ),
    X_zero_cell = ba_boundary_model_matrix(
      ba_boundary_zero_formulas[[specification$zero_rung]],
      cell_grid
    ),
    X_one_cell = ba_boundary_one_matrix(
      ba_boundary_one_formulas[[specification$one_rung]],
      cell_grid
    ),
    X_disp_cell = ba_boundary_model_matrix(
      ba_boundary_dispersion_formulas[[specification$dispersion_rung]],
      cell_grid
    ),
    one_active_cell = as.integer(!is.na(cell_grid$boundary_one_state)),
    support_cell_index = as.integer(denominator_support$cell_id - 1L),
    support_denominator = as.integer(denominator_support$denominator),
    support_weight = denominator_support$support_weight,
    gh_nodes = quadrature$nodes,
    gh_weights = quadrature$weights
  )
  list(
    data = data,
    cell_grid = cell_grid,
    denominator_support = denominator_support
  )
}

make_estimator_parameters <- function(bundle) {
  parameters <- bundle$parameter_list
  list(
    beta_mu = parameters$beta_mu,
    beta_zero = parameters$beta_zero,
    beta_one = parameters$beta_one,
    beta_disp = parameters$beta_disp,
    log_sd_mu_part = parameters$log_sd_mu_part
  )
}

make_estimator_object <- function(bundle, nodes) {
  estimator_data <- make_estimator_data(bundle, nodes)
  parameters <- make_estimator_parameters(bundle)
  objective <- TMB::MakeADFun(
    data = estimator_data$data,
    parameters = parameters,
    DLL = "endpoint_inflated_estimands",
    silent = TRUE
  )
  if (!identical(names(objective$par), names(bundle$optimizer$par))) {
    stop(
      "Estimator parameter order does not match fitted covariance.",
      call. = FALSE
    )
  }
  if (max(abs(objective$par - bundle$optimizer$par)) > 1e-10) {
    stop("Estimator parameters do not match selected estimates.", call. = FALSE)
  }
  list(
    objective = objective,
    cell_grid = estimator_data$cell_grid,
    denominator_support = estimator_data$denominator_support
  )
}

extract_point_report <- function(estimator) {
  report <- estimator$objective$report(estimator$objective$par)
  measures <- c(
    "cell_mean",
    "cell_all_zero",
    "cell_all_one",
    "cell_mixed",
    "cell_pi_zero",
    "cell_pi_one",
    "cell_pi_beta",
    "cell_phi"
  )
  if (!all(measures %in% names(report))) {
    stop("Estimator REPORT vectors are incomplete.", call. = FALSE)
  }
  report[measures]
}

extract_uncertain_report <- function(bundle, estimator) {
  covariance_fixed <- bundle$covariance_fixed
  if (
    nrow(covariance_fixed) != length(estimator$objective$par) ||
      !all(is.finite(covariance_fixed))
  ) {
    stop("Selected fixed covariance is unavailable.", call. = FALSE)
  }
  hessian_fixed <- solve(covariance_fixed)
  sd_report <- TMB::sdreport(
    estimator$objective,
    par.fixed = estimator$objective$par,
    hessian.fixed = hessian_fixed,
    getJointPrecision = FALSE,
    getReportCovariance = TRUE
  )
  if (!isTRUE(sd_report$pdHess)) {
    stop("Post-fit estimand Hessian is not positive definite.", call. = FALSE)
  }
  report_names <- names(sd_report$value)
  expected_names <- rep(
    c(
      "cell_mean",
      "cell_all_zero",
      "cell_all_one",
      "cell_mixed",
      "cell_pi_zero",
      "cell_pi_one",
      "cell_pi_beta",
      "cell_phi"
    ),
    each = 54L
  )
  if (!identical(report_names, expected_names)) {
    stop("Unexpected ADREPORT order or dimensions.", call. = FALSE)
  }
  list(
    value = sd_report$value,
    standard_error = sd_report$sd,
    covariance = sd_report$cov,
    covariance_fixed = sd_report$cov.fixed,
    report = sd_report
  )
}

linear_result <- function(contrast, estimate, covariance) {
  contrast <- as.numeric(contrast)
  point <- sum(contrast * estimate)
  variance <- as.numeric(contrast %*% covariance %*% contrast)
  if (!is.finite(variance) || variance < -1e-10) {
    stop("A requested contrast has invalid variance.", call. = FALSE)
  }
  standard_error <- sqrt(max(variance, 0))
  statistic <- point / standard_error
  data.table::data.table(
    estimate = point,
    standard_error = standard_error,
    conf_low = point - stats::qnorm(0.975) * standard_error,
    conf_high = point + stats::qnorm(0.975) * standard_error,
    statistic = statistic,
    p_value = 2 * stats::pnorm(-abs(statistic))
  )
}

wald_result <- function(contrast, estimate, covariance) {
  theta <- as.numeric(contrast %*% estimate)
  contrast_covariance <- contrast %*% covariance %*% t(contrast)
  rank <- qr(contrast_covariance, tol = 1e-8)$rank
  if (rank != nrow(contrast)) {
    return(data.table::data.table(
      statistic = NA_real_,
      degrees_freedom = rank,
      p_value = NA_real_,
      estimable = FALSE
    ))
  }
  statistic <- as.numeric(
    crossprod(theta, solve(contrast_covariance, theta))
  )
  data.table::data.table(
    statistic = statistic,
    degrees_freedom = rank,
    p_value = stats::pchisq(statistic, df = rank, lower.tail = FALSE),
    estimable = TRUE
  )
}

cell_contrast <- function(grid, state, site, day_type) {
  output <- numeric(nrow(grid))
  selected <-
    as.character(grid$analysis_state) == state &
    as.character(grid$site) == site &
    as.character(grid$day_type) == day_type
  if (sum(selected) != 1L) {
    stop("A reference cell could not be selected uniquely.", call. = FALSE)
  }
  output[selected] <- 1
  output
}

derive_sample <- function(sample_id, model_path) {
  bundle <- readRDS(model_path)
  if (isTRUE(bundle$fit_diagnostics$structural_failure)) {
    stop(
      sprintf("Selected model failed its numerical checks: %s", sample_id),
      call. = FALSE
    )
  }
  estimator_15 <- make_estimator_object(bundle, 15L)
  estimator_30 <- make_estimator_object(bundle, 30L)
  report_15 <- extract_point_report(estimator_15)
  report_30 <- extract_point_report(estimator_30)
  uncertain <- extract_uncertain_report(bundle, estimator_30)
  grid <- estimator_30$cell_grid
  states <- levels(grid$analysis_state)
  sites <- levels(grid$site)
  day_types <- levels(grid$day_type)

  quadrature <- data.table::rbindlist(lapply(
    names(report_30),
    function(measure) {
      difference <- max(abs(report_30[[measure]] - report_15[[measure]]))
      data.table::data.table(
        sample_id = sample_id,
        measure = measure,
        maximum_absolute_difference = difference,
        maximum_absolute_difference_percentage_points = 100 * difference,
        tolerance_percentage_points = 0.05,
        passed = is.finite(difference) && 100 * difference <= 0.05
      )
    }
  ))

  value_matrix <- matrix(uncertain$value, nrow = 54L, ncol = 8L)
  standard_error_matrix <- matrix(
    uncertain$standard_error,
    nrow = 54L,
    ncol = 8L
  )
  colnames(value_matrix) <- colnames(standard_error_matrix) <- c(
    "adherence",
    "all_zero_probability",
    "all_one_probability",
    "mixed_probability",
    "extra_all_zero_probability",
    "extra_all_one_probability",
    "beta_binomial_component_probability",
    "beta_binomial_precision"
  )
  cell_predictions <- data.table::as.data.table(grid)
  for (measure in colnames(value_matrix)) {
    cell_predictions[[measure]] <- value_matrix[, measure]
    cell_predictions[[paste0(measure, "_standard_error")]] <-
      standard_error_matrix[, measure]
    cell_predictions[[paste0(measure, "_conf_low")]] <-
      value_matrix[, measure] -
      stats::qnorm(0.975) * standard_error_matrix[, measure]
    cell_predictions[[paste0(measure, "_conf_high")]] <-
      value_matrix[, measure] +
      stats::qnorm(0.975) * standard_error_matrix[, measure]
  }
  cell_predictions[, `:=`(
    sample_id = sample_id,
    analysis_state = as.character(analysis_state),
    site = as.character(site),
    day_type = as.character(day_type),
    state_display = unname(state_label[as.character(analysis_state)]),
    site_display = unname(site_label[as.character(site)]),
    day_type_display = unname(day_label[as.character(day_type)])
  )]

  mean_estimate <- uncertain$value[seq_len(54L)]
  mean_covariance <- uncertain$covariance[
    seq_len(54L),
    seq_len(54L),
    drop = FALSE
  ]

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
          sample_id = sample_id,
          analysis_state = state,
          state_display = unname(state_label[state]),
          day_type = day_type,
          day_type_display = unname(day_label[day_type]),
          weighting = "equal_site"
        ),
        linear_result(contrast, mean_estimate, mean_covariance)[, .(
          estimate,
          standard_error,
          conf_low,
          conf_high
        )]
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
        sample_id = sample_id,
        family = "BA-M1",
        analysis_state = state,
        state_display = unname(state_label[state]),
        contrast = "Free day minus Work day",
        weighting = "equal_site"
      ),
      linear_result(free - work, mean_estimate, mean_covariance)
    )
  }))
  m1[, p_adjusted := stats::p.adjust(p_value, method = "BH")]

  m4 <- data.table::rbindlist(lapply(states, function(state) {
    data.table::rbindlist(lapply(sites, function(site) {
      contrast <-
        cell_contrast(grid, state, site, "Free day") -
        cell_contrast(grid, state, site, "Work day")
      cbind(
        data.table::data.table(
          sample_id = sample_id,
          family = "BA-M4",
          analysis_state = state,
          state_display = unname(state_label[state]),
          site = site,
          site_display = unname(site_label[site]),
          contrast = "Free day minus Work day"
        ),
        linear_result(contrast, mean_estimate, mean_covariance)
      )
    }))
  }))
  m4[, p_adjusted := stats::p.adjust(p_value, method = "BH")]

  m5 <- data.table::rbindlist(lapply(states, function(state) {
    data.table::rbindlist(lapply(day_types, function(day_type) {
      equal_site <- Reduce(
        `+`,
        lapply(sites, function(site) {
          cell_contrast(grid, state, site, day_type)
        })
      ) /
        length(sites)
      data.table::rbindlist(lapply(sites, function(site) {
        contrast <-
          cell_contrast(grid, state, site, day_type) - equal_site
        cbind(
          data.table::data.table(
            sample_id = sample_id,
            family = "BA-M5",
            analysis_state = state,
            state_display = unname(state_label[state]),
            site = site,
            site_display = unname(site_label[site]),
            day_type = day_type,
            day_type_display = unname(day_label[day_type]),
            contrast = "Site minus equal-site mean"
          ),
          linear_result(contrast, mean_estimate, mean_covariance)
        )
      }))
    }))
  }))
  m5[, p_adjusted := stats::p.adjust(p_value, method = "BH")]

  site_day_contrasts <- lapply(states, function(state) {
    do.call(
      rbind,
      lapply(sites, function(site) {
        cell_contrast(grid, state, site, "Free day") -
          cell_contrast(grid, state, site, "Work day")
      })
    )
  })
  names(site_day_contrasts) <- states
  site_reference_contrast <- cbind(diag(length(sites) - 1L), -1)
  m2 <- data.table::rbindlist(lapply(states, function(state) {
    contrast <- site_reference_contrast %*% site_day_contrasts[[state]]
    cbind(
      data.table::data.table(
        sample_id = sample_id,
        family = "BA-M2",
        analysis_state = state,
        state_display = unname(state_label[state]),
        contrast = "Site heterogeneity in Free day minus Work day"
      ),
      wald_result(contrast, mean_estimate, mean_covariance)
    )
  }))
  m2[, p_adjusted := stats::p.adjust(p_value, method = "BH")]

  three_way_contrast <- rbind(
    site_reference_contrast %*%
      (site_day_contrasts[[states[[1L]]]] - site_day_contrasts[[states[[3L]]]]),
    site_reference_contrast %*%
      (site_day_contrasts[[states[[2L]]]] - site_day_contrasts[[states[[3L]]]])
  )
  m3 <- cbind(
    data.table::data.table(
      sample_id = sample_id,
      family = "BA-M3",
      contrast = "Global State by Site by Day-type interaction"
    ),
    wald_result(three_way_contrast, mean_estimate, mean_covariance)
  )
  m3[, p_adjusted := p_value]

  compact_source <- data.table::rbindlist(
    list(
      merge(
        equal_site_means,
        m1[, .(
          sample_id,
          analysis_state,
          contrast_estimate = estimate,
          contrast_standard_error = standard_error,
          contrast_conf_low = conf_low,
          contrast_conf_high = conf_high,
          contrast_p_value = p_value,
          contrast_p_adjusted = p_adjusted
        )],
        by = c("sample_id", "analysis_state"),
        all.x = TRUE
      )[, `:=`(
        row_kind = "average",
        location = "Equal-site average",
        site = NA_character_,
        site_display = NA_character_,
        contrast_type = data.table::fifelse(
          day_type == "Free day",
          "Free day minus Work day",
          NA_character_
        )
      )],
      merge(
        cell_predictions[, .(
          sample_id,
          analysis_state,
          state_display,
          site,
          site_display,
          day_type,
          day_type_display,
          estimate = adherence,
          standard_error = adherence_standard_error,
          conf_low = adherence_conf_low,
          conf_high = adherence_conf_high
        )],
        m5[, .(
          sample_id,
          analysis_state,
          site,
          day_type,
          contrast_estimate = estimate,
          contrast_standard_error = standard_error,
          contrast_conf_low = conf_low,
          contrast_conf_high = conf_high,
          contrast_p_value = p_value,
          contrast_p_adjusted = p_adjusted
        )],
        by = c("sample_id", "analysis_state", "site", "day_type")
      )[, `:=`(
        row_kind = "site",
        location = site_display,
        contrast_type = "Site minus equal-site mean"
      )]
    ),
    use.names = TRUE,
    fill = TRUE
  )
  compact_source[,
    contrast_significant := is.finite(contrast_p_adjusted) &
      contrast_p_adjusted < 0.05
  ]

  list(
    quadrature = quadrature,
    cell_predictions = cell_predictions,
    equal_site_means = equal_site_means,
    m1 = m1,
    m2 = m2,
    m3 = m3,
    m4 = m4,
    m5 = m5,
    compact_source = compact_source,
    denominator_support = estimator_30$denominator_support,
    sd_report = uncertain$report
  )
}
