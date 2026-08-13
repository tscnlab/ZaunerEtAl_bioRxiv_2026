#!/usr/bin/env Rscript

# Resolve the bounded basis-capacity warning from the H02-aligned pilot.
# One diagnostic work/free k=16 fit uses the selected fixed rho and exact rows.
# No association is inferred and the diagnostic model is not retained as a
# production model object.

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
  "dplyr", "tidyr", "tibble", "readr", "digest", "mgcv", "melidosData"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

library(mgcv)
library(dplyr)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_modeling.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_modeling.R"
))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06d_abort("H02-aligned basis repair requires R 4.6.1")
}
if (!identical(as.character(utils::packageVersion("mgcv")), "1.9.4")) {
  h06d_abort("H02-aligned basis repair requires mgcv 1.9-4")
}

roots <- h06d_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "run_h06_daily_temporal_h02_basis_repair.R"
)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}
write_rds <- function(object, path) {
  saveRDS(object, path, version = 3)
  invisible(path)
}
relative_to_root <- function(path) {
  substring(path, nchar(root) + 2L)
}
verify_manifest <- function(path) {
  manifest <- readr::read_csv(path, show_col_types = FALSE, na = "")
  observed <- vapply(
    file.path(root, manifest$relative_path),
    sha256,
    character(1)
  )
  if (!identical(unname(observed), manifest$sha256)) {
    h06d_abort("Manifest verification failed: %s", relative_to_root(path))
  }
  manifest
}

selected_input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_input_manifest.csv"
)
selected_code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_code_manifest.csv"
)
selected_output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_output_manifest.csv"
)
invisible(verify_manifest(selected_input_manifest_path))
invisible(verify_manifest(selected_code_manifest_path))
invisible(verify_manifest(selected_output_manifest_path))

frame_path <- file.path(
  roots$model_data,
  "H06_daily_temporal_h02_near_eye_frame.rds"
)
selected_model_path <- file.path(
  roots$models,
  "H06_daily_temporal_h02_near_eye_pilot.rds"
)
frame <- readRDS(frame_path)
selected_checkpoint <- readRDS(selected_model_path)
selected_fit <- selected_checkpoint$model
selected_formula <- h06d_h02_temporal_formula("response")
if (
  !identical(
    paste(deparse(stats::formula(selected_fit)), collapse = " "),
    paste(deparse(selected_formula), collapse = " ")
  ) ||
    !identical(nrow(frame), stats::nobs(selected_fit))
) {
  h06d_abort("Selected H02-aligned pilot identity failed")
}

alternative_formula <- stats::as.formula(paste0(
  "response ~ s(time_hour, bs = 'cc', k = 12) + ",
  "s(time_hour, work_free_day, bs = 'sz', k = 16) + ",
  "s(time_hour, activity_status, bs = 'sz', k = 12) + ",
  "s(time_hour, by = sleep_between_h, k = 12) + ",
  "s(time_hour, by = sleep_within_h, k = 12) + ",
  "s(time_hour, site, bs = 'sz', k = 12) + ",
  "s(time_hour, participant, bs = 'fs', k = 10) + ",
  "s(participant_day, bs = 're')"
))

message(sprintf(
  "Fitting diagnostic work/free k=16 model with fixed rho %.4f",
  selected_checkpoint$rho
))
repair_started <- proc.time()[["elapsed"]]
alternative <- h06d_fit_bam(
  formula = alternative_formula,
  data = frame,
  family = stats::gaussian(link = "identity"),
  rho = selected_checkpoint$rho
)
if (is.null(alternative$value)) {
  h06d_abort("Diagnostic work/free k=16 fit failed: %s", alternative$error)
}
alternative_fit <- alternative$value

k_check_with_permutations <- function(fit, model_id) {
  set.seed(61062026L)
  output <- mgcv::k.check(fit, subsample = 5000L, n.rep = 400L)
  tibble::as_tibble(output, rownames = "term") |>
    rlang::set_names(
      c("term", "k_prime", "effective_df", "k_index", "p_value")
    ) |>
    dplyr::mutate(
      model_id = model_id,
      edf_fraction = .data$effective_df / .data$k_prime,
      deterministic_seed = 61062026L,
      permutation_replicates = 400L,
      .before = 1L
    )
}

selected_k <- k_check_with_permutations(selected_fit, "selected_work_k12")
alternative_k <- k_check_with_permutations(
  alternative_fit,
  "diagnostic_work_k16"
)
k_comparison <- dplyr::bind_rows(selected_k, alternative_k)

prediction_grid <- tidyr::expand_grid(
  time_hour = seq(0.25, 23.75, by = 0.5),
  work_free_day = factor(
    c("Work day", "Free day"),
    levels = levels(frame$work_free_day)
  )
) |>
  dplyr::mutate(
    activity_status = factor(
      "Sedentary",
      levels = levels(frame$activity_status)
    ),
    sleep_between_h = 0,
    sleep_within_h = 0,
    site = factor(levels(frame$site)[[1L]], levels = levels(frame$site)),
    participant = factor(
      levels(frame$participant)[[1L]],
      levels = levels(frame$participant)
    ),
    participant_day = factor(
      levels(frame$participant_day)[[1L]],
      levels = levels(frame$participant_day)
    ),
    AR_start = TRUE
  )
excluded_terms <- c(
  "s(time_hour,site)",
  "s(time_hour,participant)",
  "s(participant_day)"
)
predict_population <- function(fit) {
  as.numeric(stats::predict(
    fit,
    newdata = prediction_grid,
    type = "link",
    exclude = excluded_terms,
    discrete = FALSE,
    newdata.guaranteed = TRUE
  ))
}
prediction_grid$selected_eta <- predict_population(selected_fit)
prediction_grid$alternative_eta <- predict_population(alternative_fit)
contrast_curves <- prediction_grid |>
  tidyr::pivot_longer(
    cols = c("selected_eta", "alternative_eta"),
    names_to = "model_id",
    values_to = "eta"
  ) |>
  dplyr::mutate(
    model_id = dplyr::recode(
      .data$model_id,
      selected_eta = "selected_work_k12",
      alternative_eta = "diagnostic_work_k16"
    )
  ) |>
  tidyr::pivot_wider(
    names_from = "work_free_day",
    values_from = "eta"
  ) |>
  dplyr::mutate(
    free_minus_work_link = .data$`Free day` - .data$`Work day`,
    diagnostic_only = TRUE
  ) |>
  dplyr::select(dplyr::all_of(c(
    "model_id",
    "time_hour",
    "free_minus_work_link",
    "diagnostic_only"
  )))

selected_curve <- contrast_curves |>
  dplyr::filter(.data$model_id == "selected_work_k12") |>
  dplyr::arrange(.data$time_hour)
alternative_curve <- contrast_curves |>
  dplyr::filter(.data$model_id == "diagnostic_work_k16") |>
  dplyr::arrange(.data$time_hour)
curve_difference <-
  alternative_curve$free_minus_work_link - selected_curve$free_minus_work_link

residual_summary <- function(fit, model_id) {
  residual <- h06d_h02_standardized_residual(fit)
  lag <- h06d_boundary_lag_correlation(residual, frame$AR_start, lag = 1L)
  fitted <- as.numeric(stats::fitted(fit))
  qq <- stats::cor(
    stats::qnorm(stats::ppoints(length(residual))),
    sort(residual)
  )
  tibble::tibble(
    model_id = model_id,
    convergence = h06d_bam_convergence(fit),
    warnings = if (model_id == "diagnostic_work_k16") {
      paste(alternative$warnings, collapse = " | ")
    } else {
      paste(selected_checkpoint$final_warnings, collapse = " | ")
    },
    conditional_aic = stats::AIC(fit),
    log_likelihood = as.numeric(stats::logLik(fit)),
    total_effective_df = sum(fit$edf),
    standardized_residual_rmse = sqrt(mean(residual^2)),
    standardized_residual_qq_correlation = qq,
    absolute_residual_fitted_spearman = suppressWarnings(stats::cor(
      abs(residual),
      fitted,
      method = "spearman",
      use = "complete.obs"
    )),
    boundary_aware_lag1 = lag[["correlation"]],
    boundary_aware_lag1_pairs = lag[["pairs"]]
  )
}
model_diagnostics <- dplyr::bind_rows(
  residual_summary(selected_fit, "selected_work_k12"),
  residual_summary(alternative_fit, "diagnostic_work_k16")
)

selected_work_k <- selected_k |>
  dplyr::filter(
    .data$term == "s(time_hour,work_free_day)"
  )
alternative_work_k <- alternative_k |>
  dplyr::filter(
    .data$term == "s(time_hour,work_free_day)"
  )
selected_global_k <- selected_k |>
  dplyr::filter(.data$term == "s(time_hour)")
if (
  nrow(selected_work_k) != 1L ||
    nrow(alternative_work_k) != 1L ||
    nrow(selected_global_k) != 1L
) {
  h06d_abort("Required basis-check term was not uniquely identified")
}

stability_thresholds <- list(
  maximum_absolute_link_difference = 0.05,
  curve_rmse_link = 0.02,
  global_k_index_minimum = 0.90,
  global_k_p_value_minimum = 0.05,
  pooled_lag1_limit = 0.20
)
curve_rmse <- sqrt(mean(curve_difference^2))
maximum_curve_difference <- max(abs(curve_difference))
curve_stable <-
  maximum_curve_difference <=
    stability_thresholds$maximum_absolute_link_difference &&
  curve_rmse <= stability_thresholds$curve_rmse_link
global_k_pass <-
  isTRUE(
    selected_global_k$k_index >=
      stability_thresholds$global_k_index_minimum
  ) &&
  isTRUE(
    selected_global_k$p_value >=
      stability_thresholds$global_k_p_value_minimum
  )
alternative_diagnostics_pass <-
  length(alternative$warnings) == 0L &&
  h06d_bam_convergence(alternative_fit) == "full convergence" &&
  abs(dplyr::last(model_diagnostics$boundary_aware_lag1)) <
    stability_thresholds$pooled_lag1_limit

selected_aic <- model_diagnostics$conditional_aic[
  model_diagnostics$model_id == "selected_work_k12"
]
diagnostic_aic <- model_diagnostics$conditional_aic[
  model_diagnostics$model_id == "diagnostic_work_k16"
]

repair_comparison <- tibble::tibble(
  selected_formula = paste(deparse(selected_formula), collapse = " "),
  diagnostic_formula = paste(deparse(alternative_formula), collapse = " "),
  common_fixed_rho = selected_checkpoint$rho,
  exact_same_rows = identical(stats::nobs(selected_fit), stats::nobs(alternative_fit)),
  selected_work_k_prime = selected_work_k$k_prime,
  selected_work_edf = selected_work_k$effective_df,
  selected_work_edf_fraction = selected_work_k$edf_fraction,
  diagnostic_work_k_prime = alternative_work_k$k_prime,
  diagnostic_work_edf = alternative_work_k$effective_df,
  diagnostic_work_edf_fraction = alternative_work_k$edf_fraction,
  selected_global_k_index = selected_global_k$k_index,
  selected_global_k_p_value = selected_global_k$p_value,
  maximum_absolute_work_contrast_difference_link = maximum_curve_difference,
  work_contrast_difference_rmse_link = curve_rmse,
  work_contrast_curve_correlation = stats::cor(
    selected_curve$free_minus_work_link,
    alternative_curve$free_minus_work_link
  ),
  selected_conditional_aic = selected_aic,
  diagnostic_conditional_aic = diagnostic_aic,
  diagnostic_minus_selected_aic = diagnostic_aic - selected_aic,
  curve_stability_pass = curve_stable,
  global_k_check_pass = global_k_pass,
  diagnostic_fit_pass = alternative_diagnostics_pass,
  basis_repair_status = ifelse(
    curve_stable && global_k_pass && alternative_diagnostics_pass,
    "K12_RETAINED_AFTER_K16_SENSITIVITY",
    "FURTHER_BASIS_REPAIR_REQUIRED"
  ),
  interpretation = paste(
    "diagnostic only; no work/free association or curve-wide inference"
  )
)

repair_elapsed_seconds <- proc.time()[["elapsed"]] - repair_started
runtime <- tibble::tibble(
  scope = "Fixed-rho work/free k=16 basis sensitivity",
  fits = 1L,
  observed_seconds = repair_elapsed_seconds,
  resampling = "k-check only: 400 fixed-seed residual permutations per model",
  status = repair_comparison$basis_repair_status
)

comparison_path <- file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_basis_repair_comparison.csv"
)
k_path <- file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_basis_repair_k_check.csv"
)
model_diagnostic_path <- file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_basis_repair_model_diagnostics.csv"
)
curve_path <- file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_basis_repair_work_contrast_curves.csv"
)
runtime_path <- file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_basis_repair_runtime.csv"
)
checkpoint_path <- file.path(
  roots$models,
  "H06_daily_temporal_h02_basis_repair_checkpoint.rds"
)
write_csv(repair_comparison, comparison_path)
write_csv(k_comparison, k_path)
write_csv(model_diagnostics, model_diagnostic_path)
write_csv(contrast_curves, curve_path)
write_csv(runtime, runtime_path)
write_rds(
  list(
    selected_formula = selected_formula,
    diagnostic_formula = alternative_formula,
    common_fixed_rho = selected_checkpoint$rho,
    alternative_warnings = alternative$warnings,
    alternative_elapsed_seconds = alternative$elapsed_seconds,
    k_check = k_comparison,
    model_diagnostics = model_diagnostics,
    contrast_curves = contrast_curves,
    comparison = repair_comparison,
    r_version = as.character(getRversion()),
    mgcv_version = as.character(utils::packageVersion("mgcv"))
  ),
  checkpoint_path
)

code_paths <- c(
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_modeling.R",
  producer
)
code_manifest <- tibble::tibble(
  relative_path = code_paths,
  sha256 = vapply(file.path(root, code_paths), sha256, character(1)),
  bytes = unname(file.info(file.path(root, code_paths))$size)
)
input_paths <- c(
  relative_to_root(frame_path),
  relative_to_root(selected_model_path),
  relative_to_root(selected_input_manifest_path),
  relative_to_root(selected_code_manifest_path),
  relative_to_root(selected_output_manifest_path)
)
input_manifest <- tibble::tibble(
  relative_path = input_paths,
  sha256 = vapply(file.path(root, input_paths), sha256, character(1)),
  bytes = unname(file.info(file.path(root, input_paths))$size)
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_basis_repair_code_manifest.csv"
)
input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_basis_repair_input_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_basis_repair_software_manifest.csv"
)
write_csv(code_manifest, code_manifest_path)
write_csv(input_manifest, input_manifest_path)
software_manifest <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) {
        as.character(utils::packageVersion(package))
      },
      character(1)
    )
  ),
  library_path = c(
    R.home(),
    vapply(
      required_packages,
      function(package) {
        dirname(system.file(package = package))
      },
      character(1)
    )
  )
)
write_csv(software_manifest, software_manifest_path)

output_paths <- c(
  comparison_path,
  k_path,
  model_diagnostic_path,
  curve_path,
  runtime_path,
  checkpoint_path,
  code_manifest_path,
  input_manifest_path,
  software_manifest_path
)
output_manifest <- tibble::tibble(
  relative_path = vapply(output_paths, relative_to_root, character(1)),
  sha256 = vapply(output_paths, sha256, character(1)),
  bytes = unname(file.info(output_paths)$size),
  producer = producer,
  r_version = as.character(getRversion())
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_basis_repair_output_manifest.csv"
)
write_csv(output_manifest, output_manifest_path)

message(sprintf(
  "Basis repair complete in %.1f seconds: %s",
  repair_elapsed_seconds,
  repair_comparison$basis_repair_status
))
