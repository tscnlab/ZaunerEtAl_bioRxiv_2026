# Complete deterministic post-fit H03 diagnostics without refitting models.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_contract.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 post-fit diagnostics require R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c("dplyr", "tibble", "readr", "openssl")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h03_abort(
    "Missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H03/run_h03_postfit_diagnostics.R"
model_path <- file.path(
  root,
  "artifacts/07_models/H03/H03_additive_model_objects.rds"
)
if (!file.exists(model_path)) {
  h03_abort("Run H03 Stage 2 primary models before post-fit diagnostics")
}
objects <- readRDS(model_path)
models <- list(
  near_eye = objects$main_near_eye,
  chest = objects$main_chest
)
placements <- c(near_eye = "Near-eye", chest = "Chest")

h03_residual_rows <- function(object, placement) {
  tibble::tibble(
    placement = placement,
    observation_index = seq_len(nrow(object$data)),
    fitted_mean = as.numeric(stats::fitted(object$fit)),
    pearson_residual = as.numeric(stats::residuals(
      object$fit,
      type = "pearson"
    )),
    deviance_residual = as.numeric(stats::residuals(
      object$fit,
      type = "deviance"
    )),
    observed_mel_edi_lx = object$data$geo_medi_1h,
    observed_zero = object$data$geo_medi_1h == 0,
    source_model = "geo_medi_1h ~ site + light_source"
  )
}

h03_residual_acf_rows <- function(object, placement, maximum_lag = 6L) {
  residual <- stats::residuals(object$fit, type = "pearson")
  dplyr::bind_rows(lapply(seq_len(maximum_lag), function(lag) {
    estimate <- h03_boundary_lag_correlation(
      residual,
      object$data$AR_start,
      lag = lag
    )
    tibble::tibble(
      placement = placement,
      lag = lag,
      correlation = unname(estimate[["correlation"]]),
      eligible_pairs = as.integer(unname(estimate[["pairs"]])),
      boundary_definition = paste(
        "pairs remain within the same participant-day contiguous",
        "hourly sequence"
      ),
      source_model = "geo_medi_1h ~ site + light_source"
    )
  }))
}

residual_points <- dplyr::bind_rows(lapply(names(models), function(id) {
  h03_residual_rows(models[[id]], placements[[id]])
}))
residual_acf <- dplyr::bind_rows(lapply(names(models), function(id) {
  h03_residual_acf_rows(models[[id]], placements[[id]])
}))

h03_zero_rows <- function(object, placement) {
  mu <- stats::fitted(object$fit)
  power <- object$working_power
  dispersion <- summary(object$fit)$dispersion
  if (!is.finite(dispersion) || dispersion <= 0 || power <= 1 || power >= 2) {
    h03_abort("Invalid working Tweedie parameters for %s", placement)
  }
  # For a compound Poisson Tweedie with 1 < p < 2, P(Y = 0) is exp(-lambda),
  # lambda = mu^(2-p) / (phi * (2-p)). The H03 fit is quasi-likelihood, so
  # these are explicitly working-distribution diagnostics, not fitted
  # likelihood probabilities.
  lambda <- mu^(2 - power) / (dispersion * (2 - power))
  zero_probability <- exp(-lambda)
  observed_zero <- object$data$geo_medi_1h == 0
  tibble::tibble(
    placement = placement,
    light_source = as.character(object$data$light_source),
    fitted_mean_lx = mu,
    observed_zero = observed_zero,
    working_zero_probability = zero_probability,
    working_power = power,
    dispersion = dispersion
  )
}

row_data <- dplyr::bind_rows(lapply(names(models), function(id) {
  h03_zero_rows(models[[id]], placements[[id]])
}))

summarise_zero <- function(data, scope) {
  data |>
    dplyr::summarise(
      observations = dplyr::n(),
      observed_zeros = sum(.data$observed_zero),
      observed_zero_fraction = mean(.data$observed_zero),
      working_expected_zeros = sum(.data$working_zero_probability),
      working_expected_zero_fraction = mean(.data$working_zero_probability),
      observed_minus_working_fraction =
        .data$observed_zero_fraction - .data$working_expected_zero_fraction,
      observed_to_working_ratio = dplyr::if_else(
        .data$working_expected_zero_fraction > 0,
        .data$observed_zero_fraction / .data$working_expected_zero_fraction,
        NA_real_
      ),
      zero_brier_score = mean(
        (as.numeric(.data$observed_zero) - .data$working_zero_probability)^2
      ),
      working_power = dplyr::first(.data$working_power),
      dispersion = dplyr::first(.data$dispersion),
      scope = scope,
      diagnostic_role = paste(
        "working compound-Poisson Tweedie zero-mass check;",
        "quasi-likelihood fit does not estimate a zero-mass likelihood"
      ),
      .groups = "drop"
    )
}

overall <- row_data |>
  dplyr::group_by(.data$placement) |>
  summarise_zero("overall") |>
  dplyr::mutate(light_source = NA_character_, .after = "placement")
by_category <- row_data |>
  dplyr::group_by(.data$placement, .data$light_source) |>
  summarise_zero("light_source")
zero_summary <- dplyr::bind_rows(overall, by_category) |>
  dplyr::arrange(.data$placement, dplyr::desc(.data$scope), .data$light_source)

zero_bins <- row_data |>
  dplyr::group_by(.data$placement) |>
  dplyr::mutate(fitted_mean_decile = dplyr::ntile(.data$fitted_mean_lx, 10L)) |>
  dplyr::group_by(.data$placement, .data$fitted_mean_decile) |>
  dplyr::summarise(
    observations = dplyr::n(),
    fitted_mean_minimum_lx = min(.data$fitted_mean_lx),
    fitted_mean_median_lx = stats::median(.data$fitted_mean_lx),
    fitted_mean_maximum_lx = max(.data$fitted_mean_lx),
    observed_zero_fraction = mean(.data$observed_zero),
    working_expected_zero_fraction = mean(.data$working_zero_probability),
    observed_minus_working_fraction =
      .data$observed_zero_fraction - .data$working_expected_zero_fraction,
    .groups = "drop"
  )

h03_standardization_rows <- function(object, placement) {
  site_levels <- levels(object$data$site)
  category_levels <- levels(object$data$light_source)
  grid <- expand.grid(
    site = site_levels,
    light_source = category_levels,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  grid$site <- factor(grid$site, levels = site_levels)
  grid$light_source <- factor(
    grid$light_source,
    levels = category_levels
  )
  grid$linear_predictor <- as.numeric(stats::predict(
    object$fit,
    newdata = grid,
    type = "link"
  ))
  grid$expected_mel_edi_lx <- exp(grid$linear_predictor)
  grid |>
    dplyr::mutate(placement = placement, .before = 1) |>
    dplyr::group_by(.data$placement, .data$light_source) |>
    dplyr::summarise(
      sites_standardized = dplyr::n(),
      minimum_site_mean_lx = min(.data$expected_mel_edi_lx),
      maximum_site_mean_lx = max(.data$expected_mel_edi_lx),
      link_scale_equal_site_backtransform_lx = exp(
        mean(.data$linear_predictor)
      ),
      response_scale_equal_site_mean_lx = mean(.data$expected_mel_edi_lx),
      .groups = "drop"
    )
}

standardization_reconciliation <- dplyr::bind_rows(lapply(
  names(models),
  function(id) h03_standardization_rows(models[[id]], placements[[id]])
))
primary_path <- file.path(
  root,
  "artifacts/09_tables/H03/H03_primary_category_estimands.csv"
)
if (!file.exists(primary_path)) {
  h03_abort("Run H03 Stage 2 primary reporting before reconciliation")
}
primary_estimands <- readr::read_csv(primary_path, show_col_types = FALSE) |>
  dplyr::filter(.data$distribution == "site_standardized") |>
  dplyr::select(
    "placement", "category_order", "category_code", "light_source",
    stage2_expected_mel_edi_lx = "expected_mel_edi_lx"
  )
standardization_reconciliation <- standardization_reconciliation |>
  dplyr::left_join(
    primary_estimands,
    by = c("placement", "light_source"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    response_minus_link_scale_lx =
      .data$response_scale_equal_site_mean_lx -
      .data$link_scale_equal_site_backtransform_lx,
    response_relative_to_link_scale_percent = 100 * (
      .data$response_scale_equal_site_mean_lx /
        .data$link_scale_equal_site_backtransform_lx - 1
    ),
    stage2_minus_approved_link_scale_lx =
      .data$stage2_expected_mel_edi_lx -
      .data$link_scale_equal_site_backtransform_lx,
    preliminary_estimand = "exp(equal-site mean linear predictor)",
    approved_estimand = "exp(equal-site mean linear predictor)",
    superseded_estimand = paste(
      "equal-site arithmetic mean of response-scale expected melEDI;",
      "used in the pre-amendment Stage 2 render"
    )
  ) |>
  dplyr::arrange(.data$placement, .data$category_order)
if (
  any(!is.finite(
    standardization_reconciliation$stage2_minus_approved_link_scale_lx
  )) ||
    max(abs(
      standardization_reconciliation$stage2_minus_approved_link_scale_lx
    )) > 1e-8
) {
  h03_abort("Stage 2 site-standardized means failed deterministic reconciliation")
}

diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H03")
table_root <- file.path(root, "artifacts/09_tables/H03")
source_root <- file.path(root, "artifacts/11_source_data/H03")
manifest_root <- file.path(root, "artifacts/12_manifests/H03")
dir.create(diagnostic_root, recursive = TRUE, showWarnings = FALSE)
dir.create(table_root, recursive = TRUE, showWarnings = FALSE)
dir.create(source_root, recursive = TRUE, showWarnings = FALSE)
dir.create(manifest_root, recursive = TRUE, showWarnings = FALSE)
metadata <- list(
  zero_summary = write_csv_artifact(
    zero_summary,
    file.path(diagnostic_root, "H03_zero_mass_diagnostics.csv"),
    producer
  ),
  zero_bins = write_csv_artifact(
    zero_bins,
    file.path(diagnostic_root, "H03_zero_mass_calibration_bins.csv"),
    producer
  ),
  residual_acf = write_csv_artifact(
    residual_acf,
    file.path(diagnostic_root, "H03_primary_residual_acf.csv"),
    producer
  ),
  residual_points = write_csv_artifact(
    residual_points,
    file.path(source_root, "H03_primary_residual_points.csv"),
    producer
  ),
  standardization_reconciliation = write_csv_artifact(
    standardization_reconciliation,
    file.path(table_root, "H03_standardization_reconciliation.csv"),
    producer
  )
)
manifest <- dplyr::bind_rows(lapply(metadata, manifest_row))
write_csv_artifact(
  manifest,
  file.path(manifest_root, "H03_postfit_diagnostic_manifest.csv"),
  producer
)

message("H03 deterministic post-fit diagnostics complete; no model was refit")
print(as.data.frame(dplyr::filter(zero_summary, .data$scope == "overall")), row.names = FALSE)
