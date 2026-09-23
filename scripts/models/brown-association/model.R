# Construct and evaluate the specified cross-state association model.

cs_formula_text <- function(formula) {
  paste(deparse(formula, width.cutoff = 500L), collapse = " ")
}

cs_fixed_formulas <- list(
  F3 = ~ target_state * site * day_type +
    target_state * wake_within_10pp +
    target_state * wake_between_centered_10pp +
    target_state * wake_free_fraction_centered_10pp,
  F2 = ~ target_state * site +
    target_state * day_type +
    site * day_type +
    target_state * wake_within_10pp +
    target_state * wake_between_centered_10pp +
    target_state * wake_free_fraction_centered_10pp,
  F1 = ~ target_state * site +
    target_state * day_type +
    target_state * wake_within_10pp +
    target_state * wake_between_centered_10pp +
    target_state * wake_free_fraction_centered_10pp,
  F0 = ~ target_state + site + day_type +
    target_state * wake_within_10pp +
    target_state * wake_between_centered_10pp +
    target_state * wake_free_fraction_centered_10pp
)

cs_zero_formulas <- list(Q2 = ~ target_state + day_type)
cs_one_formulas <- list(Q1 = ~ target_state * day_type)
cs_dispersion_formulas <- list(D0 = ~ target_state)
cs_random_registry <- list(
  R0 = "(1 | participant_cluster) + (1 | association_cycle_cluster)",
  R3 = "(1 | participant_cluster)"
)

cs_formula_registry <- data.table::rbindlist(list(
  data.table::data.table(
    component = "mean_fixed",
    rung = names(cs_fixed_formulas),
    formula = vapply(cs_fixed_formulas, cs_formula_text, character(1))
  ),
  data.table::data.table(
    component = "mean_random",
    rung = names(cs_random_registry),
    formula = unlist(cs_random_registry, use.names = FALSE)
  ),
  data.table::data.table(
    component = "extra_all_zero",
    rung = names(cs_zero_formulas),
    formula = vapply(cs_zero_formulas, cs_formula_text, character(1))
  ),
  data.table::data.table(
    component = "extra_all_one",
    rung = names(cs_one_formulas),
    formula = vapply(cs_one_formulas, cs_formula_text, character(1))
  ),
  data.table::data.table(
    component = "dispersion",
    rung = names(cs_dispersion_formulas),
    formula = vapply(cs_dispersion_formulas, cs_formula_text, character(1))
  )
), use.names = TRUE)

cs_prepare_frame <- function(data) {
  output <- droplevels(as.data.frame(data))
  required <- c(
    "target_brown_yes",
    "target_brown_no",
    "target_state",
    "site",
    "day_type",
    "participant_cluster",
    "association_cycle_cluster",
    "wake_within_10pp",
    "wake_between_centered_10pp",
    "wake_free_fraction_centered_10pp"
  )
  missing <- setdiff(required, names(output))
  if (length(missing) > 0L) {
    stop(
      sprintf("Cross-state frame lacks: %s", paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }
  for (variable in c("target_state", "site", "day_type")) {
    output[[variable]] <- droplevels(factor(output[[variable]]))
    contrasts(output[[variable]]) <- stats::contr.sum(
      nlevels(output[[variable]])
    )
  }
  output$participant_cluster <- droplevels(factor(output$participant_cluster))
  output$association_cycle_cluster <- droplevels(factor(
    output$association_cycle_cluster
  ))
  output
}

cs_model_matrix <- function(formula, data) {
  value <- stats::model.matrix(formula, data = data)
  storage.mode(value) <- "double"
  value
}

cs_build_design <- function(
  data,
  fixed_rung = "F3",
  random_rung = "R0"
) {
  stopifnot(
    fixed_rung %in% names(cs_fixed_formulas),
    random_rung %in% names(cs_random_registry)
  )
  frame <- cs_prepare_frame(data)
  participant <- as.integer(frame$participant_cluster) - 1L
  cycle <- as.integer(frame$association_cycle_cluster) - 1L
  design <- list(
    y = as.integer(frame$target_brown_yes),
    n = as.integer(frame$target_brown_yes + frame$target_brown_no),
    X_mu = cs_model_matrix(cs_fixed_formulas[[fixed_rung]], frame),
    X_zero = cs_model_matrix(cs_zero_formulas$Q2, frame),
    X_one = cs_model_matrix(cs_one_formulas$Q1, frame),
    X_disp = cs_model_matrix(cs_dispersion_formulas$D0, frame),
    Z_mu_part = matrix(
      1,
      nrow = nrow(frame),
      ncol = 1L,
      dimnames = list(NULL, "(Intercept)")
    ),
    part_index = participant,
    day_index = cycle,
    one_active = rep(1L, nrow(frame)),
    use_zero_component = 1L,
    use_mu_part_re = 1L,
    use_day_re = as.integer(random_rung == "R0"),
    use_zero_re = 0L,
    use_one_re = 0L
  )
  ranks <- vapply(
    design[c("X_mu", "X_zero", "X_one", "X_disp")],
    function(value) qr(value)$rank,
    integer(1)
  )
  columns <- vapply(
    design[c("X_mu", "X_zero", "X_one", "X_disp")],
    ncol,
    integer(1)
  )
  if (!identical(unname(ranks), unname(columns))) {
    stop("A requested fixed-component design is not full rank.", call. = FALSE)
  }
  list(
    frame = frame,
    data = design,
    specification = list(
      fixed_rung = fixed_rung,
      random_rung = random_rung,
      zero_rung = "Q2",
      one_rung = "Q1",
      dispersion_rung = "D0"
    ),
    levels = list(
      target_state = levels(frame$target_state),
      site = levels(frame$site),
      day_type = levels(frame$day_type),
      participant_cluster = levels(frame$participant_cluster),
      association_cycle_cluster = levels(frame$association_cycle_cluster)
    )
  )
}

cs_log_beta_binomial <- function(y, n, mu, phi) {
  lchoose(n, y) +
    lbeta(y + mu * phi, n - y + (1 - mu) * phi) -
    lbeta(mu * phi, (1 - mu) * phi)
}

cs_component_weights <- function(eta_zero, eta_one) {
  denominator <- 1 + exp(eta_zero) + exp(eta_one)
  data.frame(
    pi_zero = exp(eta_zero) / denominator,
    pi_one = exp(eta_one) / denominator,
    pi_beta = 1 / denominator
  )
}

cs_mixture_support <- function(n, mu, phi, pi_zero, pi_one, pi_beta) {
  y <- 0:n
  probability <- exp(cs_log_beta_binomial(y, n, mu, phi)) * pi_beta
  probability[[1L]] <- probability[[1L]] + pi_zero
  probability[[length(probability)]] <-
    probability[[length(probability)]] + pi_one
  data.frame(y = y, probability = probability, cdf = cumsum(probability))
}

cs_endpoint_initial <- function(design, frame) {
  boundary_class <- ifelse(
    frame$target_brown_yes == 0,
    "zero",
    ifelse(frame$target_brown_no == 0, "one", "beta")
  )
  cell <- aggregate(
    list(
      zero = as.numeric(boundary_class == "zero"),
      one = as.numeric(boundary_class == "one"),
      beta = as.numeric(boundary_class == "beta")
    ),
    by = list(target_state = frame$target_state, day_type = frame$day_type),
    FUN = sum
  )
  cell_key <- paste(cell$target_state, cell$day_type)
  row_key <- paste(frame$target_state, frame$day_type)
  row_index <- match(row_key, cell_key)
  zero_target <- log((cell$zero + 0.5) / (cell$beta + 0.5))[row_index]
  one_target <- log((cell$one + 0.5) / (cell$beta + 0.5))[row_index]
  list(
    beta_zero = unname(qr.solve(design$X_zero, zero_target)),
    beta_one = unname(qr.solve(design$X_one, one_target))
  )
}

cs_initial_parameters <- function(design_object, warm_bundle = NULL) {
  design <- design_object$data
  frame <- design_object$frame
  endpoint <- cs_endpoint_initial(design, frame)
  participant_count <- nlevels(frame$participant_cluster)
  cycle_count <- nlevels(frame$association_cycle_cluster)
  state_pool <- aggregate(
    cbind(target_brown_yes, target_brown_no) ~ target_state,
    data = frame,
    FUN = sum
  )
  state_eta <- stats::qlogis(
    (state_pool$target_brown_yes + 0.5) /
      (state_pool$target_brown_yes + state_pool$target_brown_no + 1)
  )
  target_eta <- state_eta[match(frame$target_state, state_pool$target_state)]
  beta_mu <- unname(qr.solve(design$X_mu, target_eta))
  parameters <- list(
    beta_mu = beta_mu,
    beta_zero = endpoint$beta_zero,
    beta_one = endpoint$beta_one,
    beta_disp = c(log(10), rep(0, ncol(design$X_disp) - 1L)),
    b_mu_part = matrix(0, participant_count, 1L),
    b_day = rep(0, cycle_count),
    b_zero_part = rep(0, participant_count),
    b_one_part = rep(0, participant_count),
    log_sd_mu_part = log(0.30),
    log_sd_day = log(0.20),
    log_sd_zero = log(0.50),
    log_sd_one = log(0.50)
  )
  if (!is.null(warm_bundle)) {
    old <- warm_bundle$parameter_list
    if (length(old$beta_mu) == length(parameters$beta_mu)) {
      parameters$beta_mu <- old$beta_mu
    }
    if (length(old$beta_zero) == length(parameters$beta_zero)) {
      parameters$beta_zero <- old$beta_zero
    }
    if (length(old$beta_one) == length(parameters$beta_one)) {
      parameters$beta_one <- old$beta_one
    }
    if (length(old$beta_disp) == length(parameters$beta_disp)) {
      parameters$beta_disp <- old$beta_disp
    }
    parameters$log_sd_mu_part <- old$log_sd_mu_part
    parameters$log_sd_day <- old$log_sd_day
  }
  parameters
}

cs_make_object <- function(
  design_object,
  parameters,
  dll = "cross_state_endpoint_model",
  silent = TRUE
) {
  design <- design_object$data
  map <- list(
    b_zero_part = factor(rep(NA, length(parameters$b_zero_part))),
    b_one_part = factor(rep(NA, length(parameters$b_one_part))),
    log_sd_zero = factor(NA),
    log_sd_one = factor(NA)
  )
  random <- character()
  if (design$use_mu_part_re == 1L) {
    random <- c(random, "b_mu_part")
  } else {
    map$b_mu_part <- factor(matrix(
      NA,
      nrow(parameters$b_mu_part),
      ncol(parameters$b_mu_part)
    ))
    map$log_sd_mu_part <- factor(rep(
      NA,
      length(parameters$log_sd_mu_part)
    ))
  }
  if (design$use_day_re == 1L) {
    random <- c(random, "b_day")
  } else {
    map$b_day <- factor(rep(NA, length(parameters$b_day)))
    map$log_sd_day <- factor(NA)
  }
  TMB::MakeADFun(
    data = design,
    parameters = parameters,
    random = random,
    map = map,
    DLL = dll,
    silent = silent
  )
}

cs_conditional_predictions <- function(bundle) {
  design <- bundle$design_object$data
  parameters <- bundle$parameter_list
  participant_row <- design$part_index + 1L
  participant_effect <- parameters$b_mu_part[participant_row, 1L]
  cycle_effect <- if (design$use_day_re == 1L) {
    parameters$b_day[design$day_index + 1L]
  } else {
    rep(0, length(design$y))
  }
  eta_mu <- as.numeric(design$X_mu %*% parameters$beta_mu) +
    participant_effect + cycle_effect
  eta_zero <- as.numeric(design$X_zero %*% parameters$beta_zero)
  eta_one <- as.numeric(design$X_one %*% parameters$beta_one)
  eta_disp <- as.numeric(design$X_disp %*% parameters$beta_disp)
  mu <- stats::plogis(eta_mu)
  phi <- exp(eta_disp)
  weights <- cs_component_weights(eta_zero, eta_one)
  n <- design$n
  alpha <- mu * phi
  beta <- (1 - mu) * phi
  beta_zero <- exp(lbeta(alpha, beta + n) - lbeta(alpha, beta))
  beta_one <- exp(lbeta(alpha + n, beta) - lbeta(alpha, beta))
  exact_zero_probability <- weights$pi_zero + weights$pi_beta * beta_zero
  exact_one_probability <- weights$pi_one + weights$pi_beta * beta_one
  conditional_mean <- weights$pi_one + weights$pi_beta * mu
  beta_variance <- mu * (1 - mu) * (phi + n) / (n * (phi + 1))
  conditional_variance <- weights$pi_one +
    weights$pi_beta * (mu^2 + beta_variance) - conditional_mean^2
  list(
    y = design$y,
    n = n,
    mu = mu,
    phi = phi,
    pi_zero = weights$pi_zero,
    pi_one = weights$pi_one,
    pi_beta = weights$pi_beta,
    exact_zero_probability = exact_zero_probability,
    exact_one_probability = exact_one_probability,
    mixed_probability = 1 - exact_zero_probability - exact_one_probability,
    conditional_mean = conditional_mean,
    conditional_variance = conditional_variance
  )
}

cs_fixed_formulas$F3_DATE <- ~ target_state * site * day_type + target_state * wake_within_10pp + target_state * wake_between_centered_10pp + target_state * wake_free_fraction_centered_10pp + target_state * participant_centered_date
