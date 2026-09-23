make_chest_design <- function(raw_frame) {
  frame <- ba_boundary_prepare_frame(raw_frame)
  if (!identical(
    levels(frame$analysis_state),
    c("Wake outside the three hours before sleep", "Pre-sleep")
  )) {
    stop("Chest frame does not contain exactly Wake and Pre-sleep.", call. = FALSE)
  }
  one_active <- as.character(frame$analysis_state) == "Pre-sleep"
  supported <- droplevels(frame[one_active, , drop = FALSE])
  contrasts(supported$day_type) <- stats::contr.sum(nlevels(supported$day_type))
  supported_matrix <- ba_boundary_model_matrix(~day_type, supported)
  x_one <- matrix(
    0,
    nrow = nrow(frame),
    ncol = ncol(supported_matrix),
    dimnames = list(NULL, colnames(supported_matrix))
  )
  x_one[one_active, ] <- supported_matrix
  participant <- as.integer(frame$participant_id) - 1L
  day <- as.integer(frame$behavioral_day_id) - 1L
  design <- list(
    y = as.integer(frame$brown_yes),
    n = as.integer(frame$brown_yes + frame$brown_no),
    X_mu = ba_boundary_model_matrix(ba_boundary_fixed_formulas$F3, frame),
    X_zero = ba_boundary_model_matrix(ba_boundary_zero_formulas$Q2, frame),
    X_one = x_one,
    X_disp = ba_boundary_model_matrix(ba_boundary_dispersion_formulas$D0, frame),
    Z_mu_part = ba_boundary_model_matrix(~1, frame),
    part_index = participant,
    day_index = day,
    one_active = as.integer(one_active),
    use_zero_component = 1L,
    use_mu_part_re = 1L,
    use_day_re = 0L,
    use_zero_re = 0L,
    use_one_re = 0L
  )
  list(
    frame = frame,
    data = design,
    specification = list(
      fixed_rung = "F3",
      random_rung = "R3",
      zero_rung = "Q2",
      one_rung = "Q1_pre_sleep_day_type",
      dispersion_rung = "D0",
      use_zero_component = TRUE
    ),
    levels = list(
      analysis_state = levels(frame$analysis_state),
      site = levels(frame$site),
      day_type = levels(frame$day_type),
      participant_id = levels(frame$participant_id),
      behavioral_day_id = levels(frame$behavioral_day_id)
    )
  )
}

make_chest_grid <- function() {
  frame <- chest_design$frame
  grid <- expand.grid(
    analysis_state = levels(frame$analysis_state),
    site = levels(frame$site),
    day_type = levels(frame$day_type),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  for (variable in c("analysis_state", "site", "day_type")) {
    grid[[variable]] <- factor(grid[[variable]], levels = levels(frame[[variable]]))
    contrasts(grid[[variable]]) <- stats::contr.sum(nlevels(grid[[variable]]))
  }
  grid$one_active <- as.integer(as.character(grid$analysis_state) == "Pre-sleep")
  supported <- droplevels(grid[grid$one_active == 1L, , drop = FALSE])
  contrasts(supported$day_type) <- stats::contr.sum(nlevels(supported$day_type))
  x_one_supported <- ba_boundary_model_matrix(~day_type, supported)
  x_one <- matrix(
    0,
    nrow = nrow(grid),
    ncol = ncol(x_one_supported),
    dimnames = list(NULL, colnames(x_one_supported))
  )
  x_one[grid$one_active == 1L, ] <- x_one_supported
  list(grid = grid, x_one = x_one)
}

make_estimand_object <- function(nodes) {
  grid_object <- make_chest_grid()
  quadrature <- statmod::gauss.quad.prob(nodes, dist = "normal")
  data <- list(
    X_mu_cell = ba_boundary_model_matrix(ba_boundary_fixed_formulas$F3, grid_object$grid),
    X_zero_cell = ba_boundary_model_matrix(ba_boundary_zero_formulas$Q2, grid_object$grid),
    X_one_cell = grid_object$x_one,
    X_disp_cell = ba_boundary_model_matrix(ba_boundary_dispersion_formulas$D0, grid_object$grid),
    one_active_cell = as.integer(grid_object$grid$one_active),
    use_zero_component = 1L,
    gh_nodes = quadrature$nodes,
    gh_weights = quadrature$weights
  )
  parameters <- list(
    beta_mu = parameter_list$beta_mu,
    beta_zero = parameter_list$beta_zero,
    beta_one = parameter_list$beta_one,
    beta_disp = parameter_list$beta_disp,
    log_sd_mu_part = parameter_list$log_sd_mu_part
  )
  estimator <- TMB::MakeADFun(
    data = data,
    parameters = parameters,
    DLL = "endpoint_inflated_sensitivity_estimands",
    silent = TRUE
  )
  list(objective = estimator, grid = grid_object$grid)
}
