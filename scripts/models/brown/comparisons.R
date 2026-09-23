brown_compare <- function(contrasts, primary, scenario) {
  x <- as.data.frame(contrasts)
  i <- match(x$analysis_state, primary$analysis_state)
  stopifnot(!anyNA(i))
  x$scenario <- scenario
  x$state_display <- primary$state_display[i]
  x$primary_estimate <- primary$estimate[i]
  x$primary_conf_low <- primary$conf_low[i]
  x$primary_conf_high <- primary$conf_high[i]
  x$shift_percentage_points <- 100 * (x$estimate - x$primary_estimate)
  x$direction_retained <- sign(x$estimate) == sign(x$primary_estimate)
  x$interval_exclusion_retained <- (x$conf_low > 0 | x$conf_high < 0) ==
    (x$primary_conf_low > 0 | x$primary_conf_high < 0)
  x
}
mean_result <- function(weights, value, covariance) {
  variance <- as.numeric(weights %*% covariance %*% weights)
  stopifnot(is.finite(variance), variance >= 0)
  estimate <- sum(weights * value)
  se <- sqrt(variance)
  data.frame(estimate = estimate, standard_error = se,
             conf_low = estimate - qnorm(0.975) * se,
             conf_high = estimate + qnorm(0.975) * se)
}
brown_export_estimands <- function(result, relative, primary, scenario) {
  lb_save_rds(result, file.path(relative, "estimands.rds"))
  for (name in c("cell_predictions", "equal_site_means", "m1", "quadrature")) {
    if(is.data.frame(result[[name]])) lb_write_csv(result[[name]], file.path(relative, paste0(name, ".csv")))
  }
  comparison <- brown_compare(result$m1, primary, scenario)
  lb_write_csv(comparison, file.path(relative, "primary_comparison.csv"))
  comparison
}
