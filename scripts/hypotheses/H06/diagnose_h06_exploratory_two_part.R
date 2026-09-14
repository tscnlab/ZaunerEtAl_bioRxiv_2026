# Derive deterministic calibration and residual audits from the stored H06 fit.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))

options(lifecycle_verbosity = "quiet", warn = 1)

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06_abort(
    "The H06 two-part diagnostic audit requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c("dplyr", "tidyr", "tibble", "readr")
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages) > 0L) {
  h06_abort(
    "The H06 two-part diagnostic audit is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H06/diagnose_h06_exploratory_two_part.R"
paths <- pipeline_paths(root)
diagnostic_root <- file.path(paths$diagnostics, "H06")
dir.create(diagnostic_root, recursive = TRUE, showWarnings = FALSE)

write_h06_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

model_path <- file.path(
  paths$models,
  "H06",
  "H06_exploratory_time_of_day_two_part.rds"
)
if (!file.exists(model_path)) {
  h06_abort("Missing H06 exploratory two-part model bundle: %s", model_path)
}
bundle <- readRDS(model_path)
if (
  !identical(
    bundle$contract_version,
    paste0(
      "v3_two_part_cyclic_factor_by_group_equal_site_",
      "k16_selected_discrete_working_ar"
    )
  ) ||
    !identical(
      sort(names(bundle$base_fits)),
      c(
        "occurrence",
        "positive_magnitude"
      )
    )
) {
  h06_abort("The H06 exploratory two-part model contract is unexpected")
}

calibration_rows <- list()
distribution_rows <- list()
response_rows <- list()

for (component in names(bundle$base_fits)) {
  model <- bundle$base_fits[[component]]$model
  response <- as.numeric(model$y)
  fitted <- as.numeric(stats::fitted(model))
  deviance <- as.numeric(stats::residuals(model, type = "deviance"))
  pearson <- as.numeric(stats::residuals(model, type = "pearson"))
  standardized <- as.numeric(model$std.rsd)
  if (
    length(response) != stats::nobs(model) ||
      length(fitted) != length(response) ||
      length(standardized) != length(response) ||
      any(!is.finite(response)) ||
      any(!is.finite(fitted))
  ) {
    h06_abort("The stored %s model diagnostic vectors are invalid", component)
  }

  calibration_rows[[component]] <- tibble::tibble(
    response = response,
    fitted = fitted,
    deviance_residual = deviance,
    fitted_decile = dplyr::ntile(fitted, 10L)
  ) |>
    dplyr::summarise(
      observations = dplyr::n(),
      observed_mean = mean(response),
      fitted_mean = mean(fitted),
      observed_to_fitted_ratio = observed_mean / fitted_mean,
      observed_minus_fitted = observed_mean - fitted_mean,
      mean_deviance_residual = mean(deviance_residual),
      .by = fitted_decile
    ) |>
    dplyr::mutate(
      component = component,
      calibration_scope = paste(
        "In-sample fitted-value deciles; descriptive model check, not",
        "predictive validation"
      ),
      .before = 1L
    )

  residuals <- list(
    deviance = deviance,
    pearson = pearson,
    AR_standardized = standardized
  )
  distribution_rows[[component]] <- dplyr::bind_rows(lapply(
    names(residuals),
    function(residual_type) {
      value <- residuals[[residual_type]]
      value <- value[is.finite(value)]
      centered <- value - mean(value)
      standard_deviation <- stats::sd(value)
      tibble::tibble(
        component = component,
        residual_type = residual_type,
        observations = length(value),
        mean = mean(value),
        standard_deviation = standard_deviation,
        skewness = mean(centered^3) / standard_deviation^3,
        kurtosis = mean(centered^4) / standard_deviation^4,
        minimum = min(value),
        first_percentile = stats::quantile(value, 0.01),
        fifth_percentile = stats::quantile(value, 0.05),
        first_quartile = stats::quantile(value, 0.25),
        median = stats::median(value),
        third_quartile = stats::quantile(value, 0.75),
        ninety_fifth_percentile = stats::quantile(value, 0.95),
        ninety_ninth_percentile = stats::quantile(value, 0.99),
        maximum = max(value),
        absolute_over_3_fraction = mean(abs(value) > 3),
        absolute_over_4_fraction = mean(abs(value) > 4)
      )
    }
  ))

  response_rows[[component]] <- tibble::tibble(
    component = component,
    observations = length(response),
    minimum = min(response),
    first_percentile = stats::quantile(response, 0.01),
    first_quartile = stats::quantile(response, 0.25),
    median = stats::median(response),
    mean = mean(response),
    third_quartile = stats::quantile(response, 0.75),
    ninety_ninth_percentile = stats::quantile(response, 0.99),
    maximum = max(response),
    exact_zero_fraction = mean(response == 0)
  )
}

calibration <- dplyr::bind_rows(calibration_rows)
residual_distribution <- dplyr::bind_rows(distribution_rows)
response_distribution <- dplyr::bind_rows(response_rows)
calibration_summary <- calibration |>
  dplyr::summarise(
    minimum_observed_to_fitted_ratio = min(observed_to_fitted_ratio),
    maximum_observed_to_fitted_ratio = max(observed_to_fitted_ratio),
    maximum_absolute_observed_minus_fitted = max(
      abs(observed_minus_fitted)
    ),
    .by = component
  ) |>
  dplyr::mutate(
    assessment = dplyr::case_when(
      component == "occurrence" ~
        paste(
          "Occurrence calibration is weakest in the lowest-probability",
          "decile; interpret rare-positive nighttime cells cautiously"
        ),
      component == "positive_magnitude" ~
        paste(
          "Positive-mean decile calibration is approximate and the residual",
          "upper tail remains heavy; retain exploratory status"
        )
    )
  )

write_h06_csv(
  calibration,
  file.path(
    diagnostic_root,
    "H06_exploratory_two_part_fitted_decile_calibration.csv"
  )
)
write_h06_csv(
  calibration_summary,
  file.path(
    diagnostic_root,
    "H06_exploratory_two_part_calibration_summary.csv"
  )
)
write_h06_csv(
  residual_distribution,
  file.path(
    diagnostic_root,
    "H06_exploratory_two_part_residual_distribution.csv"
  )
)
write_h06_csv(
  response_distribution,
  file.path(
    diagnostic_root,
    "H06_exploratory_two_part_response_distribution.csv"
  )
)

message("H06 exploratory two-part deterministic diagnostic audit complete")
