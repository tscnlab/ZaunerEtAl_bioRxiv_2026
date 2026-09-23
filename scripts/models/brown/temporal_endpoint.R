make_temporal_design <- function(raw_frame) {
  ordered <- data.table::as.data.table(raw_frame)
  ordered[, behavior_date_numeric := as.numeric(as.Date(behavior_date))]
  data.table::setorder(ordered, participant_state_id, behavior_date_numeric)
  ordered[, ou_new_series := as.integer(seq_len(.N) == 1L), by = participant_state_id]
  ordered[, ou_gap_days := behavior_date_numeric - data.table::shift(behavior_date_numeric),
    by = participant_state_id]
  ordered[ou_new_series == 1L, ou_gap_days := 0]
  if (any(ordered$ou_new_series == 0L & ordered$ou_gap_days <= 0)) {
    stop("OU series contain a duplicate or reversed actual date.", call. = FALSE)
  }
  design <- ba_boundary_build_design(
    ordered,
    fixed_rung = "F3",
    random_rung = "R3",
    zero_rung = "Q2",
    one_rung = "Q1",
    dispersion_rung = "D0",
    use_zero_component = TRUE
  )
  design$data <- list(
    y = design$data$y,
    n = design$data$n,
    X_mu = design$data$X_mu,
    X_zero = design$data$X_zero,
    X_one = design$data$X_one,
    X_disp = design$data$X_disp,
    Z_mu_part = design$data$Z_mu_part,
    part_index = design$data$part_index,
    one_active = design$data$one_active,
    ou_new_series = as.integer(ordered$ou_new_series),
    ou_gap_days = as.numeric(ordered$ou_gap_days)
  )
  design
}

make_parameters <- function(design, base_bundle) {
  list(
    beta_mu = unname(base_bundle$parameter_list$beta_mu),
    beta_zero = unname(base_bundle$parameter_list$beta_zero),
    beta_one = unname(base_bundle$parameter_list$beta_one),
    beta_disp = unname(base_bundle$parameter_list$beta_disp),
    b_mu_part = base_bundle$parameter_list$b_mu_part,
    log_sd_mu_part = unname(base_bundle$parameter_list$log_sd_mu_part),
    u_ou = rep(0, nrow(design$frame)),
    log_sd_ou = log(0.25),
    log_rate_ou = log(log(2))
  )
}

make_object <- function(design, parameters, random = TRUE) {
  TMB::MakeADFun(
    data = design$data,
    parameters = parameters,
    random = if (random) c("b_mu_part", "u_ou") else NULL,
    DLL = "endpoint_inflated_betabinomial_ou",
    silent = TRUE
  )
}

validate_exact_objective <- function() {
  synthetic_frame <- data.frame(
    brown_yes = c(0L, 2L, 4L, 1L, 3L, 4L),
    brown_no = c(4L, 2L, 0L, 3L, 1L, 0L),
    analysis_state = factor(
      c(
        "Wake outside the three hours before sleep",
        "Wake outside the three hours before sleep",
        "Pre-sleep",
        "Pre-sleep",
        "Sleep environment",
        "Sleep environment"
      )
    ),
    site = factor(rep(c("A", "B"), 3L)),
    day_type = factor(rep(c("Work day", "Free day"), 3L)),
    participant_id = factor(rep("P1", 6L)),
    behavioral_day_id = factor(paste0("D", seq_len(6L))),
    participant_state_id = factor(
      rep(c("P1::W", "P1::P", "P1::S"), each = 2L)
    ),
    behavior_date = as.Date("2026-01-01") + c(0, 2, 0, 3, 1, 5)
  )
  design <- make_temporal_design(synthetic_frame)
  parameters <- list(
    beta_mu = rep(0.1, ncol(design$data$X_mu)),
    beta_zero = rep(-1.0, ncol(design$data$X_zero)),
    beta_one = rep(-1.3, ncol(design$data$X_one)),
    beta_disp = rep(log(8), ncol(design$data$X_disp)),
    b_mu_part = matrix(0.15, 1L, 1L),
    log_sd_mu_part = log(0.4),
    u_ou = c(0.2, -0.1, 0.05, 0.12, -0.08, 0.03),
    log_sd_ou = log(0.3),
    log_rate_ou = log(0.5)
  )
  objective <- make_object(design, parameters, random = FALSE)
  tmb_value <- objective$fn(objective$par)
  report <- objective$report(objective$par)
  participant_prior <- -sum(stats::dnorm(
    parameters$b_mu_part,
    0,
    exp(parameters$log_sd_mu_part),
    log = TRUE
  ))
  ou_prior <- 0
  for (row in seq_along(parameters$u_ou)) {
    if (design$data$ou_new_series[[row]] == 1L) {
      ou_prior <- ou_prior - stats::dnorm(
        parameters$u_ou[[row]],
        0,
        exp(parameters$log_sd_ou),
        log = TRUE
      )
    } else {
      correlation <- exp(
        -exp(parameters$log_rate_ou) * design$data$ou_gap_days[[row]]
      )
      ou_prior <- ou_prior - stats::dnorm(
        parameters$u_ou[[row]],
        correlation * parameters$u_ou[[row - 1L]],
        exp(parameters$log_sd_ou) * sqrt(1 - correlation^2),
        log = TRUE
      )
    }
  }
  manual <- participant_prior + ou_prior - sum(report$log_likelihood)
  gradient <- objective$gr(objective$par)
  data.table::rbindlist(list(
    data.table::data.table(
      check = "synthetic_objective_matches_R",
      value = abs(tmb_value - manual),
      tolerance = 1e-10,
      passed = is.finite(tmb_value) && abs(tmb_value - manual) <= 1e-10
    ),
    data.table::data.table(
      check = "synthetic_gradient_finite",
      value = max(abs(gradient)),
      tolerance = Inf,
      passed = all(is.finite(gradient))
    ),
    data.table::data.table(
      check = "synthetic_ou_gaps_positive",
      value = min(design$data$ou_gap_days[design$data$ou_new_series == 0L]),
      tolerance = 0,
      passed = all(design$data$ou_gap_days[design$data$ou_new_series == 0L] > 0)
    )
  ))
}

make_grid <- function(bundle) {
  frame <- bundle$design_object$frame
  grid <- expand.grid(
    analysis_state = levels(frame$analysis_state),
    site = levels(frame$site),
    day_type = levels(frame$day_type),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  grid$analysis_state <- factor(grid$analysis_state, levels = levels(frame$analysis_state))
  grid$site <- factor(grid$site, levels = levels(frame$site))
  grid$day_type <- factor(grid$day_type, levels = levels(frame$day_type))
  for (variable in c("analysis_state", "site", "day_type")) {
    contrasts(grid[[variable]]) <- stats::contr.sum(nlevels(grid[[variable]]))
  }
  grid$boundary_one_state <- factor(
    as.character(grid$analysis_state),
    levels = c("Pre-sleep", "Sleep environment")
  )
  grid
}

make_estimand_object <- function(bundle, nodes) {
  grid <- make_grid(bundle)
  quadrature <- statmod::gauss.quad.prob(nodes, dist = "normal")
  data <- list(
    X_mu_cell = ba_boundary_model_matrix(ba_boundary_fixed_formulas$F3, grid),
    X_zero_cell = ba_boundary_model_matrix(ba_boundary_zero_formulas$Q2, grid),
    X_one_cell = ba_boundary_one_matrix(ba_boundary_one_formulas$Q1, grid),
    X_disp_cell = ba_boundary_model_matrix(ba_boundary_dispersion_formulas$D0, grid),
    one_active_cell = as.integer(!is.na(grid$boundary_one_state)),
    gh_nodes = quadrature$nodes,
    gh_weights = quadrature$weights
  )
  parameters <- list(
    beta_mu = bundle$parameter_list$beta_mu,
    beta_zero = bundle$parameter_list$beta_zero,
    beta_one = bundle$parameter_list$beta_one,
    beta_disp = bundle$parameter_list$beta_disp,
    log_sd_mu_part = bundle$parameter_list$log_sd_mu_part,
    log_sd_ou = bundle$parameter_list$log_sd_ou,
    log_rate_ou = bundle$parameter_list$log_rate_ou
  )
  objective <- TMB::MakeADFun(
    data = data,
    parameters = parameters,
    DLL = "endpoint_inflated_ou_estimands",
    silent = TRUE
  )
  list(objective = objective, grid = grid)
}
