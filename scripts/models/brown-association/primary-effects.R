parameter_layout <- function(bundle) {
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

unpack_theta <- function(theta, bundle) {
  layout <- parameter_layout(bundle)
  if (length(theta) != layout$total) {
    stop("Fixed-parameter vector does not match the selected R3 model.", call. = FALSE)
  }
  list(
    beta_mu = theta[layout$ranges$beta_mu],
    beta_zero = theta[layout$ranges$beta_zero],
    beta_one = theta[layout$ranges$beta_one],
    beta_disp = theta[layout$ranges$beta_disp],
    log_sd_mu_part = theta[layout$ranges$log_sd_mu_part]
  )
}

make_reference_grid <- function(bundle, target, predictor, low, high) {
  frame <- bundle$design_object$frame
  base <- expand.grid(
    target_state = levels(frame$target_state),
    site = levels(frame$site),
    day_type = levels(frame$day_type),
    scenario = c("low", "high"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  base$target_state <- factor(
    base$target_state,
    levels = levels(frame$target_state)
  )
  base$site <- factor(base$site, levels = levels(frame$site))
  base$day_type <- factor(base$day_type, levels = levels(frame$day_type))
  for (variable in c("target_state", "site", "day_type")) {
    contrasts(base[[variable]]) <- stats::contr.sum(nlevels(base[[variable]]))
  }
  base$wake_within_10pp <- 0
  base$wake_between_centered_10pp <- 0
  base$wake_free_fraction_centered_10pp <- 0
  base[[predictor]] <- ifelse(base$scenario == "low", low, high)
  base$target_selected <- as.character(base$target_state) == target
  base
}

marginal_cell_mean <- function(theta, bundle, grid, nodes) {
  pars <- unpack_theta(theta, bundle)
  quadrature <- statmod::gauss.quad.prob(nodes, dist = "normal")
  x_mu <- cs_model_matrix(
    cs_fixed_formulas[[bundle$specification$fixed_rung]], grid
  )
  x_zero <- cs_model_matrix(cs_zero_formulas$Q2, grid)
  x_one <- cs_model_matrix(cs_one_formulas$Q1, grid)
  eta_mu <- as.numeric(x_mu %*% pars$beta_mu)
  eta_zero <- as.numeric(x_zero %*% pars$beta_zero)
  eta_one <- as.numeric(x_one %*% pars$beta_one)
  weights <- cs_component_weights(eta_zero, eta_one)
  participant_sd <- exp(pars$log_sd_mu_part[[1L]])
  integrated_mu <- vapply(
    eta_mu,
    function(value) {
      sum(
        quadrature$weights *
          stats::plogis(value + participant_sd * quadrature$nodes)
      )
    },
    numeric(1)
  )
  weights$pi_one + weights$pi_beta * integrated_mu
}

response_effect <- function(theta, bundle, target, predictor, nodes) {
  grid <- make_reference_grid(bundle, target, predictor, -0.5, 0.5)
  mean_value <- marginal_cell_mean(theta, bundle, grid, nodes)
  high <- mean(mean_value[grid$target_selected & grid$scenario == "high"])
  low <- mean(mean_value[grid$target_selected & grid$scenario == "low"])
  high - low
}

central_gradient <- function(fn, theta) {
  step <- 1e-5 * pmax(1, abs(theta))
  vapply(seq_along(theta), function(index) {
    upper <- theta
    lower <- theta
    upper[[index]] <- upper[[index]] + step[[index]]
    lower[[index]] <- lower[[index]] - step[[index]]
    (fn(upper) - fn(lower)) / (2 * step[[index]])
  }, numeric(1))
}

conditional_contrast <- function(bundle, target, predictor) {
  grid <- make_reference_grid(bundle, target, predictor, -0.5, 0.5)
  x_mu <- cs_model_matrix(
    cs_fixed_formulas[[bundle$specification$fixed_rung]], grid
  )
  high <- colMeans(x_mu[grid$target_selected & grid$scenario == "high", , drop = FALSE])
  low <- colMeans(x_mu[grid$target_selected & grid$scenario == "low", , drop = FALSE])
  high - low
}

cs_derive_primary_effects <- function(sample_id, bundle) {
  expected_specification <- c(
    fixed_rung = "F3", random_rung = "R3", zero_rung = "Q2",
    one_rung = "Q1", dispersion_rung = "D0"
  )
  observed_specification <- unlist(bundle$specification[names(expected_specification)])
  if (
    isTRUE(bundle$fit_check$structural_failure) ||
      !identical(observed_specification, expected_specification)
  ) {
    stop(sprintf("Selected model failed or changed specification: %s", sample_id), call. = FALSE)
  }
  theta <- bundle$optimizer$par
  covariance <- bundle$covariance_fixed
  layout <- parameter_layout(bundle)
  if (
    length(theta) != layout$total ||
      !identical(dim(covariance), c(layout$total, layout$total)) ||
      !all(is.finite(covariance))
  ) {
    stop("The selected joint fixed covariance is incomplete.", call. = FALSE)
  }

  targets <- levels(bundle$design_object$frame$target_state)
  effects <- data.table::rbindlist(lapply(
    c("within", "between"),
    function(effect_type) {
      predictor <- if (effect_type == "within") {
        "wake_within_10pp"
      } else {
        "wake_between_centered_10pp"
      }
      data.table::rbindlist(lapply(targets, function(target) {
        contrast <- conditional_contrast(bundle, target, predictor)
        mean_indices <- layout$ranges$beta_mu
        logit_estimate <- sum(contrast * theta[mean_indices])
        logit_variance <- as.numeric(
          contrast %*% covariance[mean_indices, mean_indices, drop = FALSE] %*%
            contrast
        )
        if (!is.finite(logit_variance) || logit_variance <= 0) {
          stop("A conditional association variance is not positive.", call. = FALSE)
        }
        logit_se <- sqrt(logit_variance)
        response_fn_30 <- function(value) {
          response_effect(value, bundle, target, predictor, 30L)
        }
        response_15 <- response_effect(theta, bundle, target, predictor, 15L)
        response_30 <- response_fn_30(theta)
        response_gradient <- central_gradient(response_fn_30, theta)
        response_variance <- as.numeric(
          response_gradient %*% covariance %*% response_gradient
        )
        if (!is.finite(response_variance) || response_variance < -1e-12) {
          stop("A marginal response-scale variance is invalid.", call. = FALSE)
        }
        response_se <- sqrt(max(response_variance, 0))
        data.table::data.table(
          sample_id = sample_id,
          target_state = target,
          association_level = effect_type,
          wake_predictor = predictor,
          wake_contrast_percentage_points = 10,
          conditional_logit_estimate = logit_estimate,
          conditional_logit_standard_error = logit_se,
          conditional_logit_conf_low = logit_estimate - stats::qnorm(0.975) * logit_se,
          conditional_logit_conf_high = logit_estimate + stats::qnorm(0.975) * logit_se,
          conditional_logit_statistic = logit_estimate / logit_se,
          raw_p_value = 2 * stats::pnorm(-abs(logit_estimate / logit_se)),
          response_effect_15 = response_15,
          response_effect_30 = response_30,
          response_effect_percentage_points = 100 * response_30,
          response_standard_error_percentage_points = 100 * response_se,
          response_conf_low_percentage_points = 100 * (
            response_30 - stats::qnorm(0.975) * response_se
          ),
          response_conf_high_percentage_points = 100 * (
            response_30 + stats::qnorm(0.975) * response_se
          ),
          quadrature_absolute_difference_percentage_points =
            100 * abs(response_30 - response_15),
          reference_weighting = "equal 9 sites; 50:50 Work/Free",
          contrast_definition = if (effect_type == "within") {
            "Wake within-person deviation: -5 to +5 percentage points"
          } else {
            paste(
              "Wake between-person centered mean: -5 to +5 percentage points;",
              "within deviation and Free-Wake fraction centered"
            )
          }
        )
      }))
    }
  ))
  effects[, interval_excludes_zero :=
    conditional_logit_conf_low > 0 | conditional_logit_conf_high < 0]
  effects[, direction := data.table::fcase(
    conditional_logit_estimate > 0, "positive",
    conditional_logit_estimate < 0, "negative",
    default = "zero"
  )]
  effects
}
