# Focused reproducibility checks for the H03 participant random-intercept
# variance assessment. This test reads accepted artifacts and does not refit.

suppressPackageStartupMessages({
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "H03 participant random-intercept tests require R 4.6.1",
    call. = FALSE
  )
}
source(file.path(root, "scripts/pipeline/paths_io.R"))

artifact <- function(...) file.path(root, "artifacts", ...)
script_path <- file.path(
  root,
  "scripts/hypotheses/H03/",
  "run_h03_participant_random_intercept_assessment.R"
)
qmd_path <- file.path(root, "notebooks/hypotheses/H03.qmd")
model_path <- artifact(
  "07_models", "H03",
  "H03_near_eye_participant_random_intercept_assessment.rds"
)
diagnostic_path <- artifact(
  "08_diagnostics", "H03",
  "H03_near_eye_participant_random_intercept_diagnostics.csv"
)
summary_path <- artifact(
  "09_tables", "H03",
  "H03_near_eye_participant_random_intercept_summary.csv"
)
shapley_path <- artifact(
  "09_tables", "H03",
  "H03_near_eye_participant_random_intercept_marginal_r2_shapley.csv"
)
shapley_models_path <- artifact(
  "08_diagnostics", "H03",
  "H03_near_eye_participant_random_intercept_shapley_models.csv"
)
environment_path <- artifact(
  "12_manifests", "H03",
  "H03_near_eye_participant_random_intercept_environment.csv"
)
manifest_path <- artifact(
  "12_manifests", "H03",
  "H03_near_eye_participant_random_intercept_manifest.csv"
)

required_files <- c(
  script_path,
  qmd_path,
  model_path,
  diagnostic_path,
  summary_path,
  shapley_path,
  shapley_models_path,
  environment_path,
  manifest_path
)
stopifnot(all(file.exists(required_files)))

summary_data <- readr::read_csv(summary_path, show_col_types = FALSE)
diagnostics <- readr::read_csv(diagnostic_path, show_col_types = FALSE)
shapley <- readr::read_csv(shapley_path, show_col_types = FALSE)
shapley_models <- readr::read_csv(
  shapley_models_path,
  show_col_types = FALSE
)
environment <- readr::read_csv(environment_path, show_col_types = FALSE)
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
model <- readRDS(model_path)

stopifnot(
  nrow(summary_data) == 1L,
  nrow(diagnostics) == 1L,
  summary_data$placement[[1L]] == "Near-eye",
  summary_data$formula[[1L]] ==
    "geo_medi_1h ~ site * light_source + (1 | participant)",
  summary_data$family[[1L]] == "glmmTMB Tweedie",
  summary_data$link[[1L]] == "log",
  summary_data$observations[[1L]] == 17935L,
  summary_data$participants[[1L]] == 140L,
  summary_data$participant_days[[1L]] == 801L,
  summary_data$sites[[1L]] == 9L,
  summary_data$light_source_categories[[1L]] == 7L,
  abs(summary_data$working_power_fixed[[1L]] - 1.539919) < 1e-10,
  inherits(model$fit, "glmmTMB"),
  length(model$nested_models) == 5L,
  all(vapply(model$nested_models, inherits, logical(1L), "glmmTMB")),
  paste(deparse(model$formula), collapse = " ") == summary_data$formula[[1L]],
  model$working_power == summary_data$working_power_fixed[[1L]]
)

stopifnot(
  nrow(shapley) == 3L,
  identical(
    shapley$component_id,
    c("site", "light_source", "site_by_light_source")
  ),
  abs(
    shapley$marginal_r_squared_component[shapley$component_id == "site"] -
      0.05630003
  ) < 1e-6,
  abs(
    shapley$marginal_r_squared_component[
      shapley$component_id == "light_source"
    ] - 0.71044566
  ) < 1e-6,
  abs(
    shapley$marginal_r_squared_component[
      shapley$component_id == "site_by_light_source"
    ] - 0.02910495
  ) < 1e-6,
  abs(
    sum(shapley$marginal_r_squared_component) -
      summary_data$marginal_r_squared[[1L]]
  ) < 1e-12,
  abs(sum(shapley$share_of_full_marginal_r_squared_percent) - 100) < 1e-10,
  all(abs(shapley$shapley_efficiency_error) < 1e-12),
  grepl(
    "hierarchy-respecting Shapley/dominance allocation",
    shapley$allocation_definition[[1L]],
    fixed = TRUE
  ),
  grepl("invariant", shapley$reference_invariance[[1L]], fixed = TRUE)
)

stopifnot(
  nrow(shapley_models) == 5L,
  identical(
    shapley_models$model_id,
    c("intercept", "site", "light_source", "additive", "full")
  ),
  abs(shapley_models$marginal_r_squared[1L]) < 1e-12,
  abs(
    shapley_models$marginal_r_squared[shapley_models$model_id == "full"] -
      summary_data$marginal_r_squared[[1L]]
  ) < 1e-12,
  all(shapley_models$converged),
  all(shapley_models$warning_count == 0L),
  all(shapley_models$positive_definite_hessian),
  !any(shapley_models$singular),
  all(is.finite(shapley_models$maximum_absolute_gradient))
)

total_variance <- with(
  summary_data,
  fixed_effect_variance + participant_intercept_variance +
    distribution_specific_variance
)
stopifnot(
  abs(
    summary_data$marginal_r_squared -
      summary_data$fixed_effect_variance / total_variance
  ) < 1e-12,
  abs(
    summary_data$conditional_r_squared -
      (
        summary_data$fixed_effect_variance +
          summary_data$participant_intercept_variance
      ) / total_variance
  ) < 1e-12,
  abs(
    summary_data$participant_r_squared_increment -
      (
        summary_data$conditional_r_squared -
          summary_data$marginal_r_squared
      )
  ) < 1e-12,
  abs(
    summary_data$adjusted_participant_icc -
      summary_data$participant_intercept_variance /
        (
          summary_data$participant_intercept_variance +
            summary_data$distribution_specific_variance
        )
  ) < 1e-12,
  abs(
    summary_data$unadjusted_participant_icc -
      summary_data$participant_intercept_variance / total_variance
  ) < 1e-12,
  abs(
    summary_data$participant_factor_per_sd -
      exp(summary_data$participant_intercept_sd_log)
  ) < 1e-12,
  summary_data$conditional_r_squared >= summary_data$marginal_r_squared,
  summary_data$marginal_r_squared > 0,
  summary_data$conditional_r_squared < 1
)

stopifnot(
  diagnostics$convergence_code[[1L]] == 0L,
  diagnostics$converged[[1L]],
  diagnostics$warning_count[[1L]] == 0L,
  diagnostics$positive_definite_hessian[[1L]],
  !diagnostics$singular[[1L]],
  diagnostics$finite_fixed_coefficients[[1L]],
  diagnostics$finite_participant_variance[[1L]],
  is.finite(diagnostics$maximum_absolute_gradient[[1L]]),
  abs(diagnostics$tweedie_power[[1L]] - 1.539919) < 1e-10,
  abs(diagnostics$lag1_pearson_residual_correlation[[1L]]) < 1,
  diagnostics$lag1_pairs[[1L]] > 16000L,
  diagnostics$observed_zero_fraction[[1L]] >= 0,
  diagnostics$observed_zero_fraction[[1L]] <= 1,
  diagnostics$tweedie_implied_zero_fraction[[1L]] >= 0,
  diagnostics$tweedie_implied_zero_fraction[[1L]] <= 1
)

stopifnot(
  identical(environment$component, c(
    "R", "dplyr", "tibble", "readr", "glmmTMB", "performance", "insight"
  )),
  environment$version[environment$component == "R"] == "4.6.1",
  nrow(manifest) == 6L,
  !anyDuplicated(manifest$path),
  all(c(shapley_path, shapley_models_path) %in% manifest$path),
  all(file.exists(manifest$path)),
  identical(
    unname(vapply(manifest$path, artifact_sha256, character(1L))),
    manifest$sha256
  )
)

qmd_text <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl(summary_data$formula[[1L]], qmd_text, fixed = TRUE),
  grepl(basename(summary_path), qmd_text, fixed = TRUE),
  grepl(basename(diagnostic_path), qmd_text, fixed = TRUE),
  grepl(basename(shapley_path), qmd_text, fixed = TRUE),
  grepl(basename(shapley_models_path), qmd_text, fixed = TRUE)
)

cat("H03 participant random-intercept assessment checks passed.\n")
