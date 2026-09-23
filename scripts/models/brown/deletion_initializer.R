
prepare_start <- function(raw_frame, design_object) {
  projection_frame <- as.data.frame(raw_frame)
  for (variable in names(primary_levels)) {
    projection_frame[[variable]] <- factor(
      as.character(projection_frame[[variable]]),
      levels = primary_levels[[variable]]
    )
    contrasts(projection_frame[[variable]]) <- stats::contr.sum(
      length(primary_levels[[variable]])
    )
  }
  full_matrix <- ba_boundary_model_matrix(
    ba_boundary_fixed_formulas$F3,
    projection_frame
  )
  target_eta <- as.numeric(full_matrix %*% primary_parameters$beta_mu)
  reduced_beta <- qr.solve(design_object$data$X_mu, target_eta, tol = 1e-10)

  parameters <- ba_boundary_initial_parameters(design_object)
  parameters$beta_mu <- unname(reduced_beta)
  parameters$beta_zero <- unname(primary_parameters$beta_zero)
  parameters$beta_one <- unname(primary_parameters$beta_one)
  parameters$beta_disp <- unname(primary_parameters$beta_disp)
  parameters$log_sd_mu_part <- unname(primary_parameters$log_sd_mu_part)
  parameters
}
