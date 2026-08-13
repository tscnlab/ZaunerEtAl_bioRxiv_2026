#!/usr/bin/env Rscript

# Bounded family pilot for the current METRIC-010 primary near-eye frames.
# No likelihood-ratio test, multiplicity decision, or production claim is made.

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

required_packages <- c(
  "digest", "dplyr", "glmmTMB", "lme4", "performance", "readr", "tibble"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_modeling.R"
))

roots <- h06d_m10_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "run_h06_daily_mder_metric010_family_pilot.R"
)
frame_registry_path <- paste0(
  "artifacts/06_model_data/H06_daily/",
  "H06_daily_mder_metric010_frame_registry.csv"
)
static_manifest_path <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_mder_metric010_static_output_manifest.csv"
)
frame_registry <- readr::read_csv(
  file.path(root, frame_registry_path),
  show_col_types = FALSE
)
predictors <- h06d_m10_predictor_registry()

fit_bundle <- list()
diagnostics <- list()
effects <- list()
runtime <- list()

for (index in seq_len(nrow(predictors))) {
  predictor <- predictors[index, ]
  registry_row <- frame_registry |>
    dplyr::filter(
      .data$run_id == "primary__near_eye__all_available",
      .data$predictor_id == predictor$predictor_id[[1L]]
    )
  h06d_m10_assert(nrow(registry_row) == 1L, "Pilot frame registry mismatch")
  frame <- readRDS(file.path(root, registry_row$frame_path[[1L]]))
  h06d_m10_assert(
    digest::digest(frame, algo = "sha256", serialize = TRUE) ==
      registry_row$frame_object_sha256[[1L]],
    "Pilot frame object identity failed"
  )
  formula <- h06d_m10_formula_set(predictor$column[[1L]])$fixed_site_additive

  message("METRIC-010 family pilot: ", predictor$predictor_id[[1L]])
  gaussian_reml <- h06d_m10_fit_gaussian(frame, formula, REML = TRUE)
  gaussian_ml <- h06d_m10_fit_gaussian(frame, formula, REML = FALSE)
  t_reml <- h06d_m10_fit_t(frame, formula, REML = TRUE)
  t_ml <- h06d_m10_fit_t(frame, formula, REML = FALSE)
  h06d_m10_assert(
    !is.null(gaussian_reml$value) &&
      !is.null(gaussian_ml$value) &&
      !is.null(t_reml$value) &&
      !is.null(t_ml$value),
    "A METRIC-010 family-pilot fit failed"
  )

  key <- predictor$predictor_id[[1L]]
  fit_bundle[[key]] <- list(
    frame_path = registry_row$frame_path[[1L]],
    formula = formula,
    gaussian_reml = gaussian_reml,
    gaussian_ml = gaussian_ml,
    student_t_reml = t_reml,
    student_t_ml = t_ml
  )

  gaussian_status <- h06d_m10_model_status(gaussian_reml$value)
  t_status <- h06d_m10_model_status(t_reml$value)
  gaussian_diagnostic <- h06d_m10_gaussian_residual_diagnostics(
    gaussian_reml$value,
    frame
  )
  t_diagnostic <- h06d_m10_t_residual_diagnostics(t_reml$value, frame)
  gaussian_effect <- h06d_m10_effect_row(gaussian_reml$value, predictor)
  t_effect <- h06d_m10_effect_row(t_reml$value, predictor)
  effect_shift_se <- abs(t_effect$estimate - gaussian_effect$estimate) /
    gaussian_effect$standard_error

  diagnostics[[key]] <- dplyr::bind_cols(
    tibble::tibble(
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      participant_days = nrow(frame),
      participants = dplyr::n_distinct(frame$participant_key),
      sites = dplyr::n_distinct(frame$site),
      gaussian_warning_count = length(gaussian_reml$warnings),
      gaussian_warnings = paste(gaussian_reml$warnings, collapse = " | "),
      student_t_warning_count = length(t_reml$warnings),
      student_t_warnings = paste(t_reml$warnings, collapse = " | "),
      gaussian_ml_aic = stats::AIC(gaussian_ml$value),
      student_t_ml_aic = stats::AIC(t_ml$value),
      student_t_minus_gaussian_effect_shift_se = effect_shift_se
    ),
    gaussian_status |>
      dplyr::rename_with(~ paste0("gaussian_", .x)),
    gaussian_diagnostic |>
      dplyr::rename_with(~ paste0("gaussian_", .x)),
    t_status |>
      dplyr::rename_with(~ paste0("student_t_", .x)),
    t_diagnostic |>
      dplyr::rename_with(~ paste0("student_t_", .x))
  )

  effects[[key]] <- dplyr::bind_rows(
    gaussian_effect |>
      dplyr::mutate(family_candidate = "Gaussian identity"),
    t_effect |>
      dplyr::mutate(family_candidate = "Student-t identity")
  ) |>
    dplyr::mutate(
      run_id = "primary__near_eye__all_available",
      inferential_role = "bounded family pilot; not a production estimate"
    )
  runtime[[key]] <- tibble::tibble(
    predictor_id = predictor$predictor_id[[1L]],
    gaussian_reml_seconds = gaussian_reml$elapsed_seconds,
    gaussian_ml_seconds = gaussian_ml$elapsed_seconds,
    student_t_reml_seconds = t_reml$elapsed_seconds,
    student_t_ml_seconds = t_ml$elapsed_seconds,
    total_seconds = sum(c(
      gaussian_reml$elapsed_seconds,
      gaussian_ml$elapsed_seconds,
      t_reml$elapsed_seconds,
      t_ml$elapsed_seconds
    ))
  )
}

diagnostics <- dplyr::bind_rows(diagnostics) |>
  dplyr::arrange(.data$predictor_order)
effects <- dplyr::bind_rows(effects) |>
  dplyr::arrange(.data$predictor_order, .data$family_candidate)
runtime <- dplyr::bind_rows(runtime)

gaussian_core_pass <- with(
  diagnostics,
  gaussian_converged &
    !gaussian_singular &
    gaussian_absolute_residual_fitted_spearman < 0.20 &
    gaussian_standardized_residual_gt4_fraction < 0.01 &
    gaussian_conditional_below_minus_0_05_fraction <= 0.01 &
    gaussian_marginal_below_minus_0_05_fraction <= 0.01
)
gaussian_qq_review <- diagnostics$gaussian_residual_qq_correlation < 0.95
student_t_pass <- with(
  diagnostics,
  student_t_converged &
    student_t_positive_definite_hessian &
    student_t_t_degrees_of_freedom > 2 &
    student_t_quantile_residual_qq_correlation >= 0.95 &
    student_t_absolute_quantile_residual_fitted_spearman < 0.20 &
    student_t_prediction_below_minus_0_05_fraction <= 0.01 &
    student_t_minus_gaussian_effect_shift_se < 1
)

verdict <- dplyr::bind_cols(
  diagnostics |>
    dplyr::select(
      "predictor_order",
      "predictor_id",
      "participant_days",
      "participants",
      "sites"
    ),
  tibble::tibble(
    gaussian_core_pass = gaussian_core_pass,
    gaussian_qq_review = gaussian_qq_review,
    student_t_sensitivity_pass = student_t_pass,
    family_disposition = ifelse(
      gaussian_core_pass & student_t_pass,
      "RETAIN_GAUSSIAN_IDENTITY_WITH_HEAVY_TAIL_LIMITATION_AND_T_SENSITIVITY",
      "FAMILY_GATE_NOT_PASSED"
    ),
    interpretation = ifelse(
      gaussian_core_pass & student_t_pass,
      paste(
        "The approved identity-Gaussian candidate retains the direct MDER",
        "difference estimand and passes convergence, spread, tail-frequency,",
        "and bound rules. Its Q-Q shape is explicitly limited; the Student-t",
        "identity sensitivity must accompany production because it normalizes",
        "the quantile residuals and shifts the association by less than one",
        "Gaussian-model standard error."
      ),
      paste(
        "At least one prespecified core or Student-t stability check failed;",
        "do not run production inference."
      )
    )
  )
)
h06d_m10_assert(
  all(verdict$family_disposition != "FAMILY_GATE_NOT_PASSED"),
  "The METRIC-010 bounded family pilot did not pass"
)

model_relative <- paste0(
  "artifacts/07_models/H06_daily/",
  "H06_daily_mder_metric010_family_pilot.rds"
)
diagnostic_relative <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_mder_metric010_family_pilot_diagnostics.csv"
)
effect_relative <- paste0(
  "artifacts/09_tables/H06_daily/",
  "H06_daily_mder_metric010_family_pilot_effects.csv"
)
verdict_relative <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_mder_metric010_family_pilot_verdict.csv"
)
runtime_relative <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_mder_metric010_family_pilot_runtime.csv"
)
saveRDS(fit_bundle, file.path(root, model_relative), version = 3)
readr::write_csv(diagnostics, file.path(root, diagnostic_relative), na = "")
readr::write_csv(effects, file.path(root, effect_relative), na = "")
readr::write_csv(verdict, file.path(root, verdict_relative), na = "")
readr::write_csv(runtime, file.path(root, runtime_relative), na = "")

manifest <- function(relative_paths, roles) {
  absolute <- file.path(root, relative_paths)
  tibble::tibble(
    relative_path = relative_paths,
    sha256 = vapply(absolute, h06d_m10_sha256, character(1)),
    bytes = unname(file.info(absolute)$size),
    role = roles,
    producer = producer,
    r_version = as.character(getRversion())
  )
}
input_relative <- c(
  frame_registry_path,
  static_manifest_path,
  frame_registry |>
    dplyr::filter(.data$run_id == "primary__near_eye__all_available") |>
    dplyr::arrange(.data$predictor_order) |>
    dplyr::pull(.data$frame_path)
)
input_manifest <- manifest(
  input_relative,
  c(
    "frame registry",
    "static output manifest",
    rep("exact primary near-eye predictor frame", 3L)
  )
)
code_relative <- c(
  producer,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_modeling.R"
)
code_manifest <- manifest(code_relative, c(
  "family pilot runner",
  "METRIC-010 contract",
  "METRIC-010 data adapters",
  "METRIC-010 modeling helpers"
))
output_relative <- c(
  model_relative,
  diagnostic_relative,
  effect_relative,
  verdict_relative,
  runtime_relative
)
output_manifest <- manifest(output_relative, c(
  "family pilot fits",
  "family pilot diagnostics",
  "family pilot effect comparison",
  "family pilot verdict",
  "family pilot runtime"
))
software_manifest <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)
readr::write_csv(
  input_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_family_pilot_input_manifest.csv"),
  na = ""
)
readr::write_csv(
  code_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_family_pilot_code_manifest.csv"),
  na = ""
)
readr::write_csv(
  output_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_family_pilot_output_manifest.csv"),
  na = ""
)
readr::write_csv(
  software_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_family_pilot_software_manifest.csv"),
  na = ""
)

message(
  "H06_daily METRIC-010 family pilot passed; Gaussian identity retained with mandatory Student-t sensitivity."
)
