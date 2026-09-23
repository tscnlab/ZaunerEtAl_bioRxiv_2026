brown_deletion_estimands <- function(bundle, sample_id) {
estimator_15 <- make_object(bundle, 15L)
estimator_30 <- make_object(bundle, 30L)
point_15 <- estimator_15$objective$report(estimator_15$objective$par)
point_30 <- estimator_30$objective$report(estimator_30$objective$par)
uncertain <- TMB::sdreport(
  estimator_30$objective,
  par.fixed = estimator_30$objective$par,
  hessian.fixed = solve(bundle$covariance_fixed),
  getReportCovariance = TRUE
)
grid <- estimator_30$grid
cell_count <- nrow(grid)
site_count <- nlevels(grid$site)
stopifnot(
  cell_count == 6L * site_count,
  site_count == if (grepl("^LOSO-", sample_id)) 8L else 9L,
  identical(
    names(uncertain$value),
    rep(
      c("cell_mean", "cell_pi_zero", "cell_pi_one", "cell_pi_beta", "cell_phi"),
      each = cell_count
    )
  )
)
mean_estimate <- uncertain$value[seq_len(cell_count)]
mean_covariance <- uncertain$cov[
  seq_len(cell_count),
  seq_len(cell_count),
  drop = FALSE
]
cell_predictions <- cbind(
  grid,
  adherence = as.numeric(mean_estimate),
  standard_error = as.numeric(uncertain$sd[seq_len(cell_count)])
)
cell_predictions$conf_low <- cell_predictions$adherence -
  stats::qnorm(0.975) * cell_predictions$standard_error
cell_predictions$conf_high <- cell_predictions$adherence +
  stats::qnorm(0.975) * cell_predictions$standard_error
states <- levels(grid$analysis_state)
contrasts <- lapply(states, function(state) {
  free <- as.numeric(
    as.character(grid$analysis_state) == state &
      as.character(grid$day_type) == "Free day"
  ) /
    site_count
  work <- as.numeric(
    as.character(grid$analysis_state) == state &
      as.character(grid$day_type) == "Work day"
  ) /
    site_count
  stopifnot(abs(sum(free) - 1) < 1e-12, abs(sum(work) - 1) < 1e-12)
  free - work
})
contrast_matrix <- do.call(rbind, contrasts)
colnames(contrast_matrix) <- paste0("cell_", seq_len(cell_count))
rownames(contrast_matrix) <- states
m1 <- do.call(
  rbind,
  lapply(seq_along(states), function(i) {
    result <- as.data.frame(linear_result(
      contrasts[[i]],
      mean_estimate,
      mean_covariance
    ))
    cbind(
      data.frame(
        job_id = sample_id,
        analysis_state = states[i],
        included_sites = site_count,
        reference_sites = 9L,
        weighting = if (site_count == 8L) "equal remaining eight sites" else
          "equal nine sites"
      ),
      result
    )
  })
)

list(cell_predictions = cell_predictions, m1 = m1,
     quadrature = data.frame(maximum_difference_percentage_points = 100 * max(abs(point_15$cell_mean - point_30$cell_mean))))
}
