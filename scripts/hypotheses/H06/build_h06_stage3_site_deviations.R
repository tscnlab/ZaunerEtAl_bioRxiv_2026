#!/usr/bin/env Rscript

# Derive pointwise site-to-equal-site-average work/free deviations from the
# frozen accepted H06-002 heterogeneity fit. This script never refits a model.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_robust_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06_abort(
    "H06 Stage 3 site deviations require R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c("dplyr", "readr", "tibble")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  h06_abort(
    "H06 Stage 3 site deviations are missing package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H06/build_h06_stage3_site_deviations.R"
model_path <- file.path(
  root,
  "artifacts/07_models/H06/H06_robust_core_models.rds"
)
stored_site_effects_path <- file.path(
  root,
  "artifacts/09_tables/H06/H06_robust_site_specific_effects.csv"
)
output_path <- file.path(
  root,
  "artifacts/11_source_data/H06/H06_primary_work_free_site_deviations.csv"
)

input_contract <- h06_input_contract(root)
input_hashes_match <- vapply(
  seq_len(nrow(input_contract)),
  function(index) {
    identical(
      artifact_sha256(input_contract$path[[index]]),
      input_contract$expected_sha256[[index]]
    )
  },
  logical(1)
)
if (any(!input_hashes_match)) {
  h06_abort(
    "Frozen H06 Stage 3 input(s) changed: %s",
    paste(input_contract$input_role[!input_hashes_match], collapse = ", ")
  )
}

stage2_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H06/H06_stage2_artifacts.csv"),
  show_col_types = FALSE
)
required_paths <- c(
  "artifacts/07_models/H06/H06_robust_core_models.rds",
  "artifacts/09_tables/H06/H06_robust_site_specific_effects.csv"
)
manifest_rows <- stage2_manifest[
  match(required_paths, stage2_manifest$path),
  ,
  drop = FALSE
]
absolute_paths <- file.path(root, manifest_rows$path)
if (
  anyNA(manifest_rows$path) ||
    any(!file.exists(absolute_paths)) ||
    !identical(
      unname(vapply(absolute_paths, artifact_sha256, character(1))),
      manifest_rows$sha256
    )
) {
  h06_abort("A frozen H06 Stage 2 site-effect artifact changed")
}

model_archive <- readRDS(model_path)
run_id <- "main__glasses__all_available"
if (
  !identical(model_archive$contract_version, "h06_002_robust_core_v1") ||
    !run_id %in% names(model_archive$runs) ||
    !identical(
      model_archive$frame_hashes[[run_id]],
      "ec9049b3a0c0f3b237c66a471ffdbaa1a86afe8e8e4983f6fd5deea97472950e"
    )
) {
  h06_abort("The accepted H06 robust model archive failed validation")
}

bundle <- model_archive$runs[[run_id]]$full
formula_text <- gsub(
  "[[:space:]]+",
  " ",
  paste(deparse(bundle$formula), collapse = " ")
)
expected_formula <- gsub(
  "[[:space:]]+",
  " ",
  paste(deparse(h06_formula_set()$full), collapse = " ")
)
covariance <- bundle$covariance$HC3$value
if (
  !identical(formula_text, expected_formula) ||
    !isTRUE(bundle$fit$converged) ||
    bundle$fit$rank != length(stats::coef(bundle$fit)) ||
    !is.matrix(covariance) ||
    any(!is.finite(covariance))
) {
  h06_abort("The accepted H06 work/free heterogeneity fit failed validation")
}

sites <- levels(bundle$data$site)
low_data <- h06_prediction_defaults(bundle, sites)
high_data <- low_data
low_data$work_free_day <- factor(
  "Work day",
  levels = levels(bundle$data$work_free_day)
)
high_data$work_free_day <- factor(
  "Free day",
  levels = levels(bundle$data$work_free_day)
)
site_gradients <- h06_model_matrix_newdata(bundle, high_data) -
  h06_model_matrix_newdata(bundle, low_data)
average_gradient <- colMeans(site_gradients)
coefficients <- stats::coef(bundle$fit)
degrees_freedom <- nlevels(bundle$data$participant_key) - 1L

average_effect <- h06_log_delta(
  log_estimate = drop(crossprod(average_gradient, coefficients)),
  gradient = average_gradient,
  covariance = covariance,
  df = degrees_freedom,
  null_log = NA_real_
)

site_results <- dplyr::bind_rows(lapply(seq_along(sites), function(index) {
  site_gradient <- site_gradients[index, ]
  deviation_gradient <- site_gradient - average_gradient
  site_effect <- h06_log_delta(
    log_estimate = drop(crossprod(site_gradient, coefficients)),
    gradient = site_gradient,
    covariance = covariance,
    df = degrees_freedom,
    null_log = NA_real_
  )
  deviation <- h06_log_delta(
    log_estimate = drop(crossprod(deviation_gradient, coefficients)),
    gradient = deviation_gradient,
    covariance = covariance,
    df = degrees_freedom
  )
  tibble::tibble(
    site = sites[[index]],
    site_free_vs_work_ratio = site_effect$estimate_ratio,
    site_conf_low_ratio = site_effect$conf_low_ratio,
    site_conf_high_ratio = site_effect$conf_high_ratio,
    equal_site_heterogeneity_model_ratio = average_effect$estimate_ratio,
    equal_site_heterogeneity_model_conf_low_ratio =
      average_effect$conf_low_ratio,
    equal_site_heterogeneity_model_conf_high_ratio =
      average_effect$conf_high_ratio,
    site_to_average_ratio = deviation$estimate_ratio,
    site_to_average_conf_low_ratio = deviation$conf_low_ratio,
    site_to_average_conf_high_ratio = deviation$conf_high_ratio,
    pointwise_deviation = dplyr::case_when(
      deviation$conf_low_ratio > 1 ~ "above_average",
      deviation$conf_high_ratio < 1 ~ "below_average",
      TRUE ~ "not_distinguishable_from_average"
    )
  )
}))

stored_site_effects <- readr::read_csv(
  stored_site_effects_path,
  show_col_types = FALSE
) |>
  dplyr::filter(
    .data$run_id == .env$run_id,
    .data$predictor_id == "work_free_day"
  ) |>
  dplyr::arrange(match(.data$site, sites))
if (
  nrow(stored_site_effects) != length(sites) ||
    !isTRUE(all.equal(
      site_results$site_free_vs_work_ratio,
      stored_site_effects$estimate_ratio,
      tolerance = 1e-12
    )) ||
    !isTRUE(all.equal(
      site_results$site_conf_low_ratio,
      stored_site_effects$conf_low_ratio,
      tolerance = 1e-12
    )) ||
    !isTRUE(all.equal(
      site_results$site_conf_high_ratio,
      stored_site_effects$conf_high_ratio,
      tolerance = 1e-12
    ))
) {
  h06_abort("Derived H06 site effects do not reproduce accepted Stage 2 output")
}

site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
)
output <- site_results |>
  dplyr::left_join(
    site_registry,
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(.data$display_order) |>
  dplyr::transmute(
    .data$site,
    .data$display_name,
    .data$display_order,
    .data$site_free_vs_work_ratio,
    .data$site_conf_low_ratio,
    .data$site_conf_high_ratio,
    .data$equal_site_heterogeneity_model_ratio,
    .data$equal_site_heterogeneity_model_conf_low_ratio,
    .data$equal_site_heterogeneity_model_conf_high_ratio,
    .data$site_to_average_ratio,
    .data$site_to_average_conf_low_ratio,
    .data$site_to_average_conf_high_ratio,
    .data$pointwise_deviation,
    covariance_type = "participant-cluster HC3; fix = FALSE",
    denominator_df = degrees_freedom,
    interval_scope = paste(
      "Pointwise 95% t interval for the site work/free log-ratio minus the",
      "equal-site mean log-ratio; not multiplicity adjusted across nine sites"
    ),
    inferential_role = paste(
      "Descriptive localization after a multiplicity-retained omnibus",
      "work/free site-heterogeneity test; no separate site discovery family"
    ),
    model_archive = "artifacts/07_models/H06/H06_robust_core_models.rds",
    model_archive_sha256 = artifact_sha256(model_path)
  )

if (
  nrow(output) != 9L ||
    !identical(
      output$display_name[output$pointwise_deviation == "above_average"],
      c("Borås (SE)", "Dortmund (DE)")
    ) ||
    any(output$pointwise_deviation == "below_average") ||
    any(!is.finite(
      output$equal_site_heterogeneity_model_conf_low_ratio
    )) ||
    any(!is.finite(
      output$equal_site_heterogeneity_model_conf_high_ratio
    )) ||
    any(output$equal_site_heterogeneity_model_conf_low_ratio <= 0) ||
    any(!is.finite(output$site_to_average_ratio)) ||
    any(output$site_to_average_conf_low_ratio <= 0) ||
    any(output$site_to_average_conf_high_ratio <= 0)
) {
  h06_abort("The H06 site-deviation output failed its scientific contract")
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(output, output_path, producer = producer))
message(
  paste0(
    "H06 Stage 3 work/free site deviations built without refitting: ",
    "Borås and Dortmund pointwise above the equal-site average; ",
    "no site pointwise below"
  )
)
