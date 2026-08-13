# Fit the approved H02-aligned H06-daily temporal production model on one
# frozen frame. Association extraction and pointwise intervals are performed
# later from the saved selected fit.

h06d_h02_fit_production_model <- function(frame, run_id) {
  formula <- h06d_h02_temporal_formula("response")
  family <- stats::gaussian(link = "identity")

  message(run_id, ": preliminary full model with rho = 0")
  preliminary <- h06d_fit_bam(
    formula = formula,
    data = frame,
    family = family,
    rho = 0
  )
  if (is.null(preliminary$value)) {
    h06d_abort(
      "Preliminary production BAM failed for %s: %s",
      run_id,
      preliminary$error
    )
  }
  preliminary_residual <- as.numeric(stats::residuals(
    preliminary$value,
    type = "response"
  ))
  lag <- h06d_boundary_lag_correlation(
    preliminary_residual,
    frame$AR_start,
    lag = 1L
  )
  rho_unclamped <- unname(lag[["correlation"]])
  if (!is.finite(rho_unclamped)) {
    h06d_abort("No finite preliminary rho for %s", run_id)
  }
  bounds <- h06d_h02_temporal_specification()$rho_bounds
  rho <- max(bounds[[1L]], min(bounds[[2L]], rho_unclamped))

  message(sprintf("%s: identical final model with rho = %.4f", run_id, rho))
  final <- h06d_fit_bam(
    formula = formula,
    data = frame,
    family = family,
    rho = rho
  )
  if (is.null(final$value)) {
    h06d_abort(
      "Final production BAM failed for %s: %s",
      run_id,
      final$error
    )
  }

  list(
    implementation_id = "h06d_temporal_h02_production_v1",
    run_id = run_id,
    formula = formula,
    specification = h06d_h02_temporal_specification(),
    model = final$value,
    rho_unclamped = rho_unclamped,
    rho = rho,
    preliminary_response_residuals = preliminary_residual,
    preliminary_lag_pairs = unname(lag[["pairs"]]),
    preliminary_elapsed_seconds = preliminary$elapsed_seconds,
    final_elapsed_seconds = final$elapsed_seconds,
    preliminary_warnings = preliminary$warnings,
    final_warnings = final$warnings,
    reused_selected_pilot = FALSE,
    r_version = as.character(getRversion()),
    package_versions = c(
      mgcv = as.character(utils::packageVersion("mgcv"))
    )
  )
}

h06d_h02_reuse_selected_pilot <- function(frame, run_id, checkpoint) {
  if (!identical(run_id, "primary__near_eye__all_available")) {
    h06d_abort("Selected pilot reuse is permitted only for primary near eye")
  }
  expected_formula <- h06d_h02_temporal_formula("response")
  lag <- h06d_boundary_lag_correlation(
    checkpoint$preliminary_response_residuals,
    frame$AR_start,
    lag = 1L
  )
  rho_raw <- unname(lag[["correlation"]])
  if (
    !inherits(checkpoint$model, "bam") ||
      stats::nobs(checkpoint$model) != nrow(frame) ||
      !identical(
        paste(deparse(stats::formula(checkpoint$model)), collapse = " "),
        paste(deparse(expected_formula), collapse = " ")
      ) ||
      !identical(checkpoint$model$family$family, "gaussian") ||
      !identical(checkpoint$model$family$link, "identity") ||
      any(vapply(
        checkpoint$model$smooth,
        function(smooth) !is.null(smooth$xt),
        logical(1)
      )) ||
      abs(rho_raw - checkpoint$rho_unclamped) > 1e-10
  ) {
    h06d_abort("Selected near-eye pilot cannot be reused for production")
  }

  list(
    implementation_id = "h06d_temporal_h02_production_v1",
    run_id = run_id,
    formula = expected_formula,
    specification = h06d_h02_temporal_specification(),
    model = checkpoint$model,
    rho_unclamped = checkpoint$rho_unclamped,
    rho = checkpoint$rho,
    preliminary_response_residuals =
      checkpoint$preliminary_response_residuals,
    preliminary_lag_pairs = unname(lag[["pairs"]]),
    preliminary_elapsed_seconds = checkpoint$preliminary_elapsed_seconds,
    final_elapsed_seconds = checkpoint$final_elapsed_seconds,
    preliminary_warnings = checkpoint$preliminary_warnings,
    final_warnings = checkpoint$final_warnings,
    reused_selected_pilot = TRUE,
    selected_pilot_frame_relative_path = checkpoint$frame_relative_path,
    r_version = as.character(getRversion()),
    package_versions = c(
      mgcv = as.character(utils::packageVersion("mgcv"))
    )
  )
}
