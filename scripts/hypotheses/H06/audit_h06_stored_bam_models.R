# Strengthen the GAMM audit of stored H06 V0-scaffold BAM pilot models.

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
    "The H06 stored-BAM audit requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c("dplyr", "tidyr", "tibble", "readr", "mgcv")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h06_abort(
    "The H06 stored-BAM audit is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H06/audit_h06_stored_bam_models.R"
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
  "H06_v0_scaffold_pilot_models.rds"
)
dharma_path <- file.path(
  diagnostic_root,
  "H06_v0_scaffold_pilot_DHARMa_100.csv"
)
if (!file.exists(model_path) || !file.exists(dharma_path)) {
  h06_abort("The stored H06 BAM model or bounded diagnostic artifact is missing")
}

pilot <- readRDS(model_path)
dharma <- readr::read_csv(dharma_path, show_col_types = FALSE) |>
  dplyr::filter(candidate_id == "bam_participant_day_working_ar")
if (
  !identical(sort(names(pilot)), c("chest", "glasses")) ||
    nrow(dharma) != 2L ||
    any(dharma$simulations != 100L)
) {
  h06_abort("The stored H06 BAM audit inputs failed validation")
}

series_lag <- function(data, residual, residual_type, placement) {
  tibble::tibble(
    sequence = data$hour_sequence_id,
    position = data$hour_sequence_position,
    residual = as.numeric(residual)
  ) |>
    dplyr::arrange(sequence, position) |>
    dplyr::summarise(
      observations = dplyr::n(),
      lag1 = if (dplyr::n() >= 3L) {
        suppressWarnings(stats::cor(
          residual[-1L], residual[-dplyr::n()]
        ))
      } else {
        NA_real_
      },
      .by = sequence
    ) |>
    dplyr::filter(is.finite(lag1)) |>
    dplyr::mutate(
      placement = placement,
      residual_type = residual_type,
      .before = 1L
    )
}

audit_rows <- list()
lag_rows <- list()
smooth_rows <- list()
tweedie_formals <- formals(mgcv::tw)

for (placement in names(pilot)) {
  candidate <- pilot[[placement]]$candidates[[
    "bam_participant_day_working_ar"
  ]]
  model <- candidate$model
  data <- candidate$data
  if (
    is.null(model) ||
      !inherits(model, "bam") ||
      nrow(data) != stats::nobs(model) ||
      length(model$std.rsd) != nrow(data)
  ) {
    h06_abort("The stored %s BAM object/data pairing is invalid", placement)
  }
  raw <- as.numeric(stats::residuals(model, type = "pearson"))
  standardized <- as.numeric(model$std.rsd)
  placement_lags <- dplyr::bind_rows(
    series_lag(data, raw, "pearson", placement),
    series_lag(data, standardized, "AR_standardized", placement)
  )
  lag_rows[[placement]] <- placement_lags

  smooth_table <- tibble::as_tibble(
    as.data.frame(summary(model)$s.table),
    rownames = "smooth"
  ) |>
    dplyr::mutate(placement = placement, .before = 1L)
  smooth_rows[[placement]] <- smooth_table

  random_edf <- smooth_table |>
    dplyr::filter(smooth %in% c(
      "s(participant_key)",
      "s(participant_day_key)"
    ))
  participant_edf <- random_edf$edf[
    random_edf$smooth == "s(participant_key)"
  ]
  participant_day_edf <- random_edf$edf[
    random_edf$smooth == "s(participant_day_key)"
  ]
  standardized_lag <- placement_lags |>
    dplyr::filter(residual_type == "AR_standardized") |>
    dplyr::pull(lag1)
  raw_lag <- placement_lags |>
    dplyr::filter(residual_type == "pearson") |>
    dplyr::pull(lag1)
  diagnostic <- dharma |>
    dplyr::filter(.data$placement == .env$placement)
  model_summary <- summary(model)
  audit_rows[[placement]] <- tibble::tibble(
    placement = placement,
    model_id = "bam_participant_day_working_ar",
    engine = "mgcv::bam",
    method = "fREML",
    discrete = TRUE,
    response_family = "Tweedie with estimated power and log link",
    tweedie_power = model$family$getTheta(TRUE),
    tweedie_default_lower_bound = as.numeric(tweedie_formals$a),
    tweedie_default_upper_bound = as.numeric(tweedie_formals$b),
    scale_parameter_phi = model_summary$scale,
    scale_parameter_sqrt = sqrt(model_summary$scale),
    working_ar_rho = model$AR1.rho,
    observations = stats::nobs(model),
    adjusted_r_squared = model_summary$r.sq,
    deviance_explained = model_summary$dev.expl,
    participant_random_effect_edf = participant_edf,
    participant_day_random_effect_edf = participant_day_edf,
    random_effect_penalties_effectively_absent =
      participant_edf < 0.001 && participant_day_edf < 0.001,
    raw_sequence_lag1_median = stats::median(raw_lag),
    raw_sequence_lag1_first_quartile = stats::quantile(raw_lag, 0.25),
    raw_sequence_lag1_third_quartile = stats::quantile(raw_lag, 0.75),
    standardized_sequence_lag1_median = stats::median(standardized_lag),
    standardized_sequence_lag1_first_quartile = stats::quantile(
      standardized_lag,
      0.25
    ),
    standardized_sequence_lag1_third_quartile = stats::quantile(
      standardized_lag,
      0.75
    ),
    observed_zero_fraction = diagnostic$observed_zero_fraction,
    simulated_zero_fraction_100 = diagnostic$simulated_zero_fraction,
    uniformity_p_100 = diagnostic$uniformity_p,
    dispersion_p_100 = diagnostic$dispersion_p,
    zero_mass_p_100 = diagnostic$zero_inflation_p,
    outlier_p_100 = diagnostic$outlier_p,
    positive_tail_calibration = "NOT TESTED in the stored pilot",
    ar_interpretation = paste(
      "For a non-Gaussian BAM, rho is a working-residual GEE",
      "approximation rather than a full joint/generative AR likelihood"
    ),
    simulation_interpretation = paste(
      "The stored 100 marginal-response simulations test the conditional",
      "Tweedie response distribution, not a full generative AR process"
    ),
    inferential_status = "failed_feasibility_pilot_not_accepted_inference"
  )
}

audit <- dplyr::bind_rows(audit_rows) |>
  dplyr::arrange(match(placement, c("glasses", "chest")))
per_sequence <- dplyr::bind_rows(lag_rows) |>
  dplyr::arrange(match(placement, c("glasses", "chest")), residual_type, sequence)
smooths <- dplyr::bind_rows(smooth_rows) |>
  dplyr::arrange(match(placement, c("glasses", "chest")), smooth)

write_h06_csv(
  audit,
  file.path(diagnostic_root, "H06_v0_scaffold_pilot_bam_gamm_audit.csv")
)
write_h06_csv(
  per_sequence,
  file.path(
    diagnostic_root,
    "H06_v0_scaffold_pilot_bam_per_sequence_residual_lag.csv"
  )
)
write_h06_csv(
  smooths,
  file.path(diagnostic_root, "H06_v0_scaffold_pilot_bam_smooths.csv")
)

message("H06 stored-BAM GAMM audit complete")
