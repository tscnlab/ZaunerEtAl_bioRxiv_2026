make_synthetic <- function(y, n, eta_mu, eta_zero, eta_one, eta_disp) {
  observations <- length(y)
  design <- list(
    data = list(
      y = as.integer(y),
      n = as.integer(n),
      X_mu = matrix(1, observations, 1L),
      X_zero = matrix(1, observations, 1L),
      X_one = matrix(1, observations, 1L),
      X_disp = matrix(1, observations, 1L),
      Z_mu_part = matrix(1, observations, 1L),
      part_index = rep(0L, observations),
      day_index = rep(0L, observations),
      one_active = rep(1L, observations),
      use_zero_component = 1L,
      use_mu_part_re = 0L,
      use_day_re = 0L,
      use_zero_re = 0L,
      use_one_re = 0L
    )
  )
  parameters <- list(
    beta_mu = eta_mu,
    beta_zero = eta_zero,
    beta_one = eta_one,
    beta_disp = eta_disp,
    b_mu_part = matrix(0, 1L, 1L),
    b_day = 0,
    b_zero_part = 0,
    b_one_part = 0,
    log_sd_mu_part = 0,
    log_sd_day = 0,
    log_sd_zero = 0,
    log_sd_one = 0
  )
  list(design = design, parameters = parameters)
}
