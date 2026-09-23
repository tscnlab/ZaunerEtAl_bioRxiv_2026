# Post-fit helpers for the defined cross-state association estimands.

cs_parameter_layout <- function(bundle) {
  lengths <- c(
    beta_mu = length(bundle$parameter_list$beta_mu),
    beta_zero = length(bundle$parameter_list$beta_zero),
    beta_one = length(bundle$parameter_list$beta_one),
    beta_disp = length(bundle$parameter_list$beta_disp),
    log_sd_mu_part = length(bundle$parameter_list$log_sd_mu_part)
  )
  ends <- cumsum(lengths)
  starts <- c(1L, head(ends, -1L) + 1L)
  list(
    lengths = lengths,
    ranges = stats::setNames(Map(seq.int, starts, ends), names(lengths)),
    total = sum(lengths)
  )
}

cs_unpack_theta <- function(theta, bundle) {
  layout <- cs_parameter_layout(bundle)
  if (length(theta) != layout$total) {
    stop("Fixed-parameter vector does not match an R3 model.", call. = FALSE)
  }
  list(
    beta_mu = theta[layout$ranges$beta_mu],
    beta_zero = theta[layout$ranges$beta_zero],
    beta_one = theta[layout$ranges$beta_one],
    beta_disp = theta[layout$ranges$beta_disp],
    log_sd_mu_part = theta[layout$ranges$log_sd_mu_part]
  )
}

cs_reference_grid <- function(bundle, target, predictor, low = -0.5, high = 0.5) {
  frame <- bundle$design_object$frame
  grid <- expand.grid(
    target_state = levels(frame$target_state),
    site = levels(frame$site),
    day_type = levels(frame$day_type),
    scenario = c("low", "high"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  grid$target_state <- factor(
    grid$target_state,
    levels = levels(frame$target_state)
  )
  grid$site <- factor(grid$site, levels = levels(frame$site))
  grid$day_type <- factor(grid$day_type, levels = levels(frame$day_type))
  for (variable in c("target_state", "site", "day_type")) {
    contrasts(grid[[variable]]) <- stats::contr.sum(nlevels(grid[[variable]]))
  }
  grid$wake_within_10pp <- 0
  grid$wake_between_centered_10pp <- 0
  grid$wake_free_fraction_centered_10pp <- 0
  grid[[predictor]] <- ifelse(grid$scenario == "low", low, high)
  grid$target_selected <- as.character(grid$target_state) == target
  grid
}

cs_marginal_cell_mean <- function(theta, bundle, grid, nodes = 30L) {
  parameters <- cs_unpack_theta(theta, bundle)
  quadrature <- statmod::gauss.quad.prob(nodes, dist = "normal")
  x_mu <- cs_model_matrix(
    cs_fixed_formulas[[bundle$specification$fixed_rung]], grid
  )
  x_zero <- cs_model_matrix(cs_zero_formulas$Q2, grid)
  x_one <- cs_model_matrix(cs_one_formulas$Q1, grid)
  eta_mu <- as.numeric(x_mu %*% parameters$beta_mu)
  eta_zero <- as.numeric(x_zero %*% parameters$beta_zero)
  eta_one <- as.numeric(x_one %*% parameters$beta_one)
  weights <- cs_component_weights(eta_zero, eta_one)
  participant_sd <- exp(parameters$log_sd_mu_part[[1L]])
  integrated_mu <- vapply(eta_mu, function(value) {
    sum(
      quadrature$weights *
        stats::plogis(value + participant_sd * quadrature$nodes)
    )
  }, numeric(1))
  weights$pi_one + weights$pi_beta * integrated_mu
}

cs_response_effect <- function(theta, bundle, target, predictor, nodes = 30L) {
  grid <- cs_reference_grid(bundle, target, predictor)
  values <- cs_marginal_cell_mean(theta, bundle, grid, nodes)
  high <- mean(values[grid$target_selected & grid$scenario == "high"])
  low <- mean(values[grid$target_selected & grid$scenario == "low"])
  high - low
}

cs_central_gradient <- function(fn, theta) {
  step <- 1e-5 * pmax(1, abs(theta))
  vapply(seq_along(theta), function(index) {
    upper <- theta
    lower <- theta
    upper[[index]] <- upper[[index]] + step[[index]]
    lower[[index]] <- lower[[index]] - step[[index]]
    (fn(upper) - fn(lower)) / (2 * step[[index]])
  }, numeric(1))
}

cs_conditional_contrast <- function(bundle, target, predictor) {
  grid <- cs_reference_grid(bundle, target, predictor)
  x_mu <- cs_model_matrix(
    cs_fixed_formulas[[bundle$specification$fixed_rung]], grid
  )
  high <- colMeans(
    x_mu[grid$target_selected & grid$scenario == "high", , drop = FALSE]
  )
  low <- colMeans(
    x_mu[grid$target_selected & grid$scenario == "low", , drop = FALSE]
  )
  high - low
}

cs_summarize_four_effects <- function(bundle, model_id, include_uncertainty = TRUE) {
  if (
    isTRUE(bundle$fit_check$structural_failure) ||
      bundle$specification$random_rung != "R3" ||
      !bundle$specification$fixed_rung %in% c("F3", "F2", "F1", "F0")
  ) {
    stop("Post-fit effect derivation requires an retained specified R3 fit.", call. = FALSE)
  }
  theta <- bundle$optimizer$par
  covariance <- bundle$covariance_fixed
  layout <- cs_parameter_layout(bundle)
  targets <- levels(bundle$design_object$frame$target_state)
  output <- data.table::rbindlist(lapply(c("within", "between"), function(level) {
    predictor <- if (level == "within") {
      "wake_within_10pp"
    } else {
      "wake_between_centered_10pp"
    }
    data.table::rbindlist(lapply(targets, function(target) {
      contrast <- cs_conditional_contrast(bundle, target, predictor)
      indices <- layout$ranges$beta_mu
      estimate <- sum(contrast * theta[indices])
      variance <- as.numeric(
        contrast %*% covariance[indices, indices, drop = FALSE] %*% contrast
      )
      standard_error <- sqrt(max(variance, 0))
      response_fn <- function(value) {
        cs_response_effect(value, bundle, target, predictor, 30L)
      }
      response <- response_fn(theta)
      if (include_uncertainty) {
        gradient <- cs_central_gradient(response_fn, theta)
        response_variance <- as.numeric(gradient %*% covariance %*% gradient)
        response_standard_error <- sqrt(max(response_variance, 0))
      } else {
        response_standard_error <- NA_real_
      }
      data.table::data.table(
        model_id = model_id,
        target_state = target,
        association_level = level,
        conditional_logit_estimate = estimate,
        conditional_logit_standard_error = standard_error,
        conditional_logit_conf_low = estimate - stats::qnorm(0.975) * standard_error,
        conditional_logit_conf_high = estimate + stats::qnorm(0.975) * standard_error,
        response_effect_percentage_points = 100 * response,
        response_standard_error_percentage_points = 100 * response_standard_error,
        response_conf_low_percentage_points = 100 * (
          response - stats::qnorm(0.975) * response_standard_error
        ),
        response_conf_high_percentage_points = 100 * (
          response + stats::qnorm(0.975) * response_standard_error
        )
      )
    }))
  }))
  output[, `:=`(
    direction = data.table::fcase(
      conditional_logit_estimate > 0, "positive",
      conditional_logit_estimate < 0, "negative",
      default = "zero"
    ),
    interval_excludes_zero =
      conditional_logit_conf_low > 0 | conditional_logit_conf_high < 0
  )]
  output
}
