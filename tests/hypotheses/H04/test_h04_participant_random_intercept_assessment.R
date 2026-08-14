# Focused reproducibility checks for the H04 participant random-intercept
# variance assessment. This test reads accepted artifacts and does not refit.

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

suppressPackageStartupMessages({
  library(readr)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H04 participant random-intercept tests require R 4.6.1", call. = FALSE)
}
source(file.path(root, "scripts/pipeline/paths_io.R"))

artifact <- function(...) file.path(root, "artifacts", ...)
script_path <- file.path(
  root,
  "scripts/hypotheses/H04/",
  "run_h04_participant_random_intercept_assessment.R"
)
qmd_path <- file.path(root, "notebooks/hypotheses/H04.qmd")
preparation_path <- file.path(
  root,
  "audit/hypotheses/H04/H04_analysis_preparation.qmd"
)
model_path <- artifact(
  "07_models", "H04", "H04_participant_random_intercept_assessment.rds"
)
diagnostic_path <- artifact(
  "08_diagnostics", "H04",
  "H04_participant_random_intercept_diagnostics.csv"
)
nested_path <- artifact(
  "08_diagnostics", "H04",
  "H04_participant_random_intercept_shapley_models.csv"
)
summary_path <- artifact(
  "09_tables", "H04", "H04_participant_random_intercept_summary.csv"
)
shapley_path <- artifact(
  "09_tables", "H04",
  "H04_participant_random_intercept_marginal_r2_shapley.csv"
)
environment_path <- artifact(
  "12_manifests", "H04",
  "H04_participant_random_intercept_environment.csv"
)
manifest_path <- artifact(
  "12_manifests", "H04",
  "H04_participant_random_intercept_manifest.csv"
)

required_files <- c(
  script_path,
  qmd_path,
  preparation_path,
  model_path,
  diagnostic_path,
  nested_path,
  summary_path,
  shapley_path,
  environment_path,
  manifest_path
)
stopifnot(all(file.exists(required_files)))

summary_data <- readr::read_csv(summary_path, show_col_types = FALSE)
diagnostics <- readr::read_csv(diagnostic_path, show_col_types = FALSE)
nested <- readr::read_csv(nested_path, show_col_types = FALSE)
shapley <- readr::read_csv(shapley_path, show_col_types = FALSE)
environment <- readr::read_csv(environment_path, show_col_types = FALSE)
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
model <- readRDS(model_path)

stopifnot(
  nrow(summary_data) == 2L,
  identical(summary_data$placement, c("Near-eye", "Chest")),
  all(summary_data$formula ==
    "geo_medi_1h ~ site * activity_named + (1 | participant)"),
  all(summary_data$family == "glmmTMB Tweedie"),
  all(summary_data$link == "log"),
  identical(as.integer(summary_data$long_rows), c(16875L, 20440L)),
  identical(
    as.integer(summary_data$unique_participant_hours),
    c(16135L, 19497L)
  ),
  all(abs(
    summary_data$effective_weighted_hours -
      summary_data$unique_participant_hours
  ) < 1e-10),
  identical(as.integer(summary_data$participants), c(126L, 150L)),
  identical(as.integer(summary_data$activity_categories), c(5L, 5L)),
  all(abs(summary_data$working_power_fixed - 1.539919) < 1e-10),
  length(model$assessment) == 2L,
  identical(names(model$assessment), c("near_eye", "chest")),
  all(vapply(
    model$assessment,
    function(item) inherits(item$fit, "glmmTMB"),
    logical(1L)
  )),
  all(vapply(model$assessment, function(item) {
    length(item$nested_models) == 5L &&
      all(vapply(item$nested_models, inherits, logical(1L), "glmmTMB"))
  }, logical(1L))),
  model$input_sha256 ==
    "ccc6122cc0e7b41b9a8769bc3406629c398d71a3a30b3ff84587ee3323e5d05c"
)

expected_marginal <- c(0.766254443568648, 0.767808067278323)
expected_conditional <- c(0.858048950872999, 0.859338950897308)
expected_participant <- c(0.0917945073043515, 0.0915308836189843)
expected_residual <- c(0.141951049127001, 0.140661049102692)
stopifnot(
  all(abs(summary_data$marginal_r_squared - expected_marginal) < 1e-8),
  all(abs(summary_data$conditional_r_squared - expected_conditional) < 1e-8),
  all(abs(
    summary_data$participant_r_squared_increment - expected_participant
  ) < 1e-8),
  all(abs(summary_data$residual_variance_share - expected_residual) < 1e-8),
  all(abs(
    summary_data$marginal_r_squared +
      summary_data$participant_r_squared_increment +
      summary_data$residual_variance_share - 1
  ) < 1e-12),
  all(summary_data$marginal_r_squared > 0),
  all(summary_data$conditional_r_squared > summary_data$marginal_r_squared),
  all(summary_data$conditional_r_squared < 1),
  all(summary_data$participant_factor_per_sd > 2),
  all(abs(summary_data$marginal_r_squared_weighting_difference) < 0.003),
  all(summary_data$marginal_r_squared_weighting_difference < 0),
  grepl("weighted by exact 1/k", summary_data$r_squared_approximation[[1L]],
    fixed = TRUE
  )
)

total_variance <- with(
  summary_data,
  fixed_effect_variance_weighted + participant_intercept_variance +
    distribution_specific_variance
)
stopifnot(
  all(abs(
    summary_data$marginal_r_squared -
      summary_data$fixed_effect_variance_weighted / total_variance
  ) < 1e-12),
  all(abs(
    summary_data$conditional_r_squared -
      (
        summary_data$fixed_effect_variance_weighted +
          summary_data$participant_intercept_variance
      ) / total_variance
  ) < 1e-12),
  all(abs(
    summary_data$unadjusted_participant_icc -
      summary_data$participant_intercept_variance / total_variance
  ) < 1e-12),
  all(abs(
    summary_data$adjusted_participant_icc -
      summary_data$participant_intercept_variance /
        (
          summary_data$participant_intercept_variance +
            summary_data$distribution_specific_variance
        )
  ) < 1e-12),
  all(abs(
    summary_data$participant_factor_per_sd -
      exp(summary_data$participant_intercept_sd_log)
  ) < 1e-12)
)

stopifnot(
  nrow(shapley) == 6L,
  all(table(shapley$placement) == 3L),
  identical(
    shapley$component_id,
    rep(c("site", "activity", "site_by_activity"), 2L)
  ),
  all(abs(shapley$shapley_efficiency_error) < 1e-12),
  all(abs(
    tapply(
      shapley$marginal_r_squared_component,
      shapley$placement,
      sum
    )[summary_data$placement] - summary_data$marginal_r_squared
  ) < 1e-12),
  all(abs(
    tapply(
      shapley$share_of_full_marginal_r_squared_percent,
      shapley$placement,
      sum
    ) - 100
  ) < 1e-10),
  all(shapley$marginal_r_squared_component > 0),
  all(
    shapley$share_of_full_marginal_r_squared_percent[
      shapley$component_id == "activity"
    ] > 80
  ),
  grepl(
    "hierarchy-respecting Shapley/dominance allocation",
    shapley$allocation_definition[[1L]],
    fixed = TRUE
  ),
  grepl("invariant", shapley$reference_invariance[[1L]], fixed = TRUE)
)

stopifnot(
  nrow(nested) == 10L,
  identical(
    nested$model_id,
    rep(c("intercept", "site", "activity", "additive", "full"), 2L)
  ),
  all(abs(
    nested$marginal_r_squared[nested$model_id == "intercept"]
  ) < 1e-10),
  all(nested$converged),
  all(nested$warning_count == 0L),
  all(nested$positive_definite_hessian),
  !any(nested$singular),
  all(is.finite(nested$maximum_absolute_gradient))
)

stopifnot(
  nrow(diagnostics) == 2L,
  all(diagnostics$convergence_code == 0L),
  all(diagnostics$converged),
  all(diagnostics$warning_count == 0L),
  all(diagnostics$positive_definite_hessian),
  !any(diagnostics$singular),
  all(diagnostics$finite_fixed_coefficients),
  all(diagnostics$finite_participant_variance),
  all(is.finite(diagnostics$maximum_absolute_gradient)),
  all(abs(diagnostics$tweedie_power - 1.539919) < 1e-10),
  all(abs(diagnostics$minimum_hour_weight_sum - 1) < 1e-12),
  all(abs(diagnostics$maximum_hour_weight_sum - 1) < 1e-12),
  all(abs(
    diagnostics$lag1_pearson_residual_correlation_hour_aggregated
  ) < 1),
  all(diagnostics$lag1_pairs > 14000L),
  all(diagnostics$observed_zero_fraction >= 0),
  all(diagnostics$observed_zero_fraction <= 1),
  all(diagnostics$tweedie_implied_zero_fraction >= 0),
  all(diagnostics$tweedie_implied_zero_fraction <= 1)
)

stopifnot(
  identical(environment$component, c(
    "R", "dplyr", "tibble", "readr", "openssl", "glmmTMB", "lme4",
    "performance", "insight"
  )),
  environment$version[environment$component == "R"] == "4.6.1",
  nrow(manifest) == 6L,
  !anyDuplicated(manifest$path),
  all(file.exists(manifest$path)),
  identical(
    unname(vapply(manifest$path, artifact_sha256, character(1L))),
    manifest$sha256
  )
)

for (source_path in c(qmd_path, preparation_path)) {
  source_text <- paste(readLines(source_path, warn = FALSE), collapse = "\n")
  stopifnot(
    grepl(summary_data$formula[[1L]], source_text, fixed = TRUE),
    grepl(basename(summary_path), source_text, fixed = TRUE),
    grepl(basename(diagnostic_path), source_text, fixed = TRUE),
    grepl(basename(shapley_path), source_text, fixed = TRUE),
    grepl(basename(nested_path), source_text, fixed = TRUE)
  )
}

cat("H04 participant random-intercept assessment checks passed.\n")
