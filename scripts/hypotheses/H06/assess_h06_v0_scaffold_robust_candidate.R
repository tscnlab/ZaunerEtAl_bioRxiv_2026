# Targeted calibration and influence checks for the H06 robust pilot candidate.

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
    "H06 robust-candidate checks require R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c("dplyr", "tidyr", "tibble", "readr", "sandwich")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h06_abort(
    "H06 robust-candidate checks are missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <-
  "scripts/hypotheses/H06/assess_h06_v0_scaffold_robust_candidate.R"
paths <- pipeline_paths(root)
diagnostic_root <- file.path(paths$diagnostics, "H06")
table_root <- file.path(paths$tables, "H06")
dir.create(diagnostic_root, recursive = TRUE, showWarnings = FALSE)
dir.create(table_root, recursive = TRUE, showWarnings = FALSE)

write_h06_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

model_path <- file.path(
  paths$models,
  "H06",
  "H06_v0_scaffold_pilot_models.rds"
)
if (!file.exists(model_path)) {
  h06_abort("Missing H06 V0-scaffold pilot models: %s", model_path)
}
pilot_objects <- readRDS(model_path)
if (!identical(sort(names(pilot_objects)), c("chest", "glasses"))) {
  h06_abort("Unexpected placement set in H06 V0-scaffold pilot models")
}

fixed_formula <- stats::as.formula(paste(
  "response_value ~",
  "site * work_free_day + site * activity_status +",
  "site * previous_sleep_duration_centered_h"
))
effect_terms <- c(
  free_day_vs_work_day = "work_free_dayFree day",
  active_vs_sedentary = paste0(
    "activity_status",
    "Active (light, moderate, or vigorous exercise)"
  ),
  per_hour_previous_sleep = "previous_sleep_duration_centered_h"
)

extract_target_coefficients <- function(model) {
  coefficients <- stats::coef(model)
  if (!all(effect_terms %in% names(coefficients))) {
    return(stats::setNames(rep(NA_real_, length(effect_terms)), names(effect_terms)))
  }
  stats::setNames(unname(coefficients[effect_terms]), names(effect_terms))
}

fit_reduced_quasi <- function(data) {
  data <- droplevels(data)
  tryCatch(
    stats::glm(
      formula = fixed_formula,
      data = data,
      family = stats::quasipoisson(link = "log"),
      contrasts = list(site = "contr.sum"),
      control = stats::glm.control(maxit = 100L)
    ),
    error = function(error) error
  )
}

calibration_rows <- list()
covariance_sensitivity_rows <- list()
influence_rank_rows <- list()
influence_refit_rows <- list()
leave_site_rows <- list()
summary_rows <- list()

for (placement in names(pilot_objects)) {
  candidate <- pilot_objects[[placement]]$candidates[[
    "glm_participant_cluster_robust"
  ]]
  model <- candidate$model
  data <- candidate$data
  covariance <- candidate$covariance
  if (is.null(model) || is.null(covariance)) {
    h06_abort("Missing fitted robust candidate for placement `%s`", placement)
  }
  if (!identical(nrow(data), length(stats::fitted(model)))) {
    h06_abort("Model/data row mismatch for placement `%s`", placement)
  }
  if (anyDuplicated(data$.model_row_id)) {
    h06_abort("Duplicate model row IDs for placement `%s`", placement)
  }

  full_target <- extract_target_coefficients(model)
  robust_se <- sqrt(diag(covariance))[effect_terms]
  if (any(!is.finite(full_target)) || any(!is.finite(robust_se))) {
    h06_abort("Non-finite target estimate or robust SE for `%s`", placement)
  }

  covariance_rows <- lapply(c("HC0", "HC1", "HC2", "HC3"), function(type) {
    covariance_type <- sandwich::vcovCL(
      model,
      cluster = data$participant_key,
      type = type,
      cadjust = TRUE,
      fix = TRUE
    )
    standard_error <- sqrt(diag(covariance_type))[effect_terms]
    critical <- stats::qt(0.975, df = candidate$clusters - 1L)
    tibble::tibble(
      placement = placement,
      covariance_type = type,
      participant_cluster_adjustment = TRUE,
      degrees_freedom = candidate$clusters - 1L,
      effect_id = names(effect_terms),
      estimate_link = unname(full_target),
      standard_error = unname(standard_error),
      conf_low_link = unname(full_target - critical * standard_error),
      conf_high_link = unname(full_target + critical * standard_error),
      estimate_response_ratio = exp(unname(full_target)),
      conf_low_response_ratio = exp(unname(full_target - critical * standard_error)),
      conf_high_response_ratio = exp(unname(full_target + critical * standard_error)),
      inferential_status = "covariance_feasibility_pilot_not_accepted_inference"
    )
  })
  covariance_sensitivity_rows[[placement]] <- dplyr::bind_rows(covariance_rows)

  fitted_value <- as.numeric(stats::fitted(model))
  observed_value <- data$response_value
  decile_rows <- tibble::tibble(
    group_value = dplyr::ntile(fitted_value, 10L),
    observed_value = observed_value,
    fitted_value = fitted_value
  ) |>
    dplyr::summarise(
      observations = dplyr::n(),
      observed_mean = mean(observed_value),
      fitted_mean = mean(fitted_value),
      observed_to_fitted_ratio = observed_mean / fitted_mean,
      .by = group_value
    ) |>
    dplyr::mutate(
      placement = placement,
      diagnostic = "fitted_mean_decile",
      group_label = paste0("Decile ", group_value),
      .before = 1L
    ) |>
    dplyr::select(-group_value)
  clock_rows <- tibble::tibble(
    group_value = data$clock_hour,
    observed_value = observed_value,
    fitted_value = fitted_value
  ) |>
    dplyr::summarise(
      observations = dplyr::n(),
      observed_mean = mean(observed_value),
      fitted_mean = mean(fitted_value),
      observed_to_fitted_ratio = observed_mean / fitted_mean,
      .by = group_value
    ) |>
    dplyr::mutate(
      placement = placement,
      diagnostic = "local_clock_profile_diagnostic_only",
      group_label = sprintf("%04.1f h", group_value),
      .before = 1L
    ) |>
    dplyr::select(-group_value)
  calibration_rows[[placement]] <- dplyr::bind_rows(decile_rows, clock_rows) |>
    dplyr::mutate(
      inferential_status = "pilot_diagnostic_not_a_confirmatory_clock_effect"
    )

  design <- stats::model.matrix(model)
  if (!identical(nrow(design), nrow(data))) {
    h06_abort("Design/data row mismatch for placement `%s`", placement)
  }
  working_score <- design * as.numeric(observed_value - fitted_value)
  cluster <- as.character(data$participant_key)
  cluster_score <- rowsum(working_score, cluster, reorder = FALSE)
  working_information <- crossprod(design, design * fitted_value)
  information_inverse <- tryCatch(
    solve(working_information),
    error = function(error) NULL
  )
  if (is.null(information_inverse)) {
    h06_abort("Working information is singular for placement `%s`", placement)
  }
  approximate_shift <- -t(information_inverse %*% t(cluster_score))
  colnames(approximate_shift) <- colnames(design)
  standardized_target_shift <- sweep(
    approximate_shift[, effect_terms, drop = FALSE],
    2L,
    robust_se,
    "/"
  )
  rank_table <- tibble::tibble(
    participant_key = rownames(cluster_score),
    observations = as.integer(table(cluster)[rownames(cluster_score)]),
    approximate_max_abs_target_shift_robust_se = apply(
      abs(standardized_target_shift),
      1L,
      max
    )
  ) |>
    dplyr::arrange(
      dplyr::desc(approximate_max_abs_target_shift_robust_se),
      participant_key
    ) |>
    dplyr::mutate(
      placement = placement,
      influence_rank = dplyr::row_number(),
      .before = 1L
    )
  influence_rank_rows[[placement]] <- rank_table

  top_participants <- utils::head(rank_table$participant_key, 5L)
  refit_rows <- lapply(top_participants, function(excluded_participant) {
    reduced <- data[data$participant_key != excluded_participant, , drop = FALSE]
    refit <- fit_reduced_quasi(reduced)
    if (inherits(refit, "error")) {
      return(tibble::tibble(
        placement = placement,
        excluded_participant = excluded_participant,
        effect_id = names(effect_terms),
        full_estimate_link = unname(full_target),
        reduced_estimate_link = NA_real_,
        shift_link = NA_real_,
        shift_in_full_robust_se = NA_real_,
        refit_converged = FALSE,
        refit_rank = NA_integer_,
        refit_error = conditionMessage(refit)
      ))
    }
    reduced_target <- extract_target_coefficients(refit)
    shift <- reduced_target - full_target
    tibble::tibble(
      placement = placement,
      excluded_participant = excluded_participant,
      effect_id = names(effect_terms),
      full_estimate_link = unname(full_target),
      reduced_estimate_link = unname(reduced_target),
      shift_link = unname(shift),
      shift_in_full_robust_se = unname(shift / robust_se),
      refit_converged = isTRUE(refit$converged),
      refit_rank = refit$rank,
      refit_error = NA_character_
    )
  })
  influence_refit_rows[[placement]] <- dplyr::bind_rows(refit_rows) |>
    dplyr::mutate(
      inferential_status = "targeted_pilot_influence_screen"
    )

  site_rows <- lapply(levels(data$site), function(excluded_site) {
    reduced <- data[data$site != excluded_site, , drop = FALSE]
    refit <- fit_reduced_quasi(reduced)
    if (inherits(refit, "error")) {
      return(tibble::tibble(
        placement = placement,
        excluded_site = excluded_site,
        effect_id = names(effect_terms),
        full_estimate_link = unname(full_target),
        reduced_equal_remaining_site_estimate_link = NA_real_,
        shift_link = NA_real_,
        refit_converged = FALSE,
        refit_rank = NA_integer_,
        refit_error = conditionMessage(refit)
      ))
    }
    reduced_target <- extract_target_coefficients(refit)
    tibble::tibble(
      placement = placement,
      excluded_site = excluded_site,
      effect_id = names(effect_terms),
      full_estimate_link = unname(full_target),
      reduced_equal_remaining_site_estimate_link = unname(reduced_target),
      shift_link = unname(reduced_target - full_target),
      refit_converged = isTRUE(refit$converged),
      refit_rank = refit$rank,
      refit_error = NA_character_
    )
  })
  leave_site_rows[[placement]] <- dplyr::bind_rows(site_rows) |>
    dplyr::mutate(
      estimand_note = paste(
        "Screen only: deleting a site changes the equal-site average to",
        "the remaining sites; it is not a common-estimand sensitivity."
      ),
      inferential_status = "targeted_pilot_site_influence_screen"
    )

  calibration_placement <- calibration_rows[[placement]]
  decile_ratio <- calibration_placement |>
    dplyr::filter(diagnostic == "fitted_mean_decile") |>
    dplyr::pull(observed_to_fitted_ratio)
  clock_ratio <- calibration_placement |>
    dplyr::filter(diagnostic == "local_clock_profile_diagnostic_only") |>
    dplyr::pull(observed_to_fitted_ratio)
  participant_refits <- influence_refit_rows[[placement]]
  site_refits <- leave_site_rows[[placement]]
  covariance_placement <- covariance_sensitivity_rows[[placement]]
  hc1_se <- covariance_placement |>
    dplyr::filter(covariance_type == "HC1") |>
    dplyr::arrange(effect_id) |>
    dplyr::pull(standard_error)
  hc3_se <- covariance_placement |>
    dplyr::filter(covariance_type == "HC3") |>
    dplyr::arrange(effect_id) |>
    dplyr::pull(standard_error)
  cluster_sizes <- as.integer(table(cluster))
  summary_rows[[placement]] <- tibble::tibble(
    placement = placement,
    observations = nrow(data),
    participant_clusters = dplyr::n_distinct(cluster),
    fixed_coefficients = model$rank,
    minimum_participant_observations = min(cluster_sizes),
    median_participant_observations = stats::median(cluster_sizes),
    maximum_participant_observations = max(cluster_sizes),
    deviance_per_residual_df = stats::deviance(model) / stats::df.residual(model),
    fitted_decile_min_observed_to_fitted = min(decile_ratio),
    fitted_decile_max_observed_to_fitted = max(decile_ratio),
    clock_min_observed_to_fitted = min(clock_ratio),
    clock_max_observed_to_fitted = max(clock_ratio),
    targeted_participant_refits = length(top_participants),
    maximum_abs_target_shift_robust_se = max(
      abs(participant_refits$shift_in_full_robust_se),
      na.rm = TRUE
    ),
    maximum_hc3_to_hc1_se_ratio = max(hc3_se / hc1_se),
    leave_one_site_refits = dplyr::n_distinct(site_refits$excluded_site),
    maximum_abs_leave_site_shift_link = max(
      abs(site_refits$shift_link),
      na.rm = TRUE
    ),
    confirmatory_clock_term = FALSE,
    overall_assessment = paste(
      "Structurally estimable marginal pilot; retain only as a candidate",
      "pending an approved production contract and full sensitivity battery."
    ),
    inferential_status = "feasibility_pilot_not_accepted_inference"
  )
}

calibration <- dplyr::bind_rows(calibration_rows)
covariance_sensitivity <- dplyr::bind_rows(covariance_sensitivity_rows)
influence_rank <- dplyr::bind_rows(influence_rank_rows)
influence_refits <- dplyr::bind_rows(influence_refit_rows)
leave_site <- dplyr::bind_rows(leave_site_rows)
robust_summary <- dplyr::bind_rows(summary_rows)

stopifnot(
  nrow(robust_summary) == 2L,
  nrow(influence_refits) == 2L * 5L * length(effect_terms),
  all(influence_refits$refit_converged),
  all(is.finite(influence_refits$shift_link)),
  all(leave_site$refit_converged),
  all(is.finite(leave_site$shift_link)),
  !any(robust_summary$confirmatory_clock_term)
)

write_h06_csv(
  calibration,
  file.path(
    diagnostic_root,
    "H06_v0_scaffold_pilot_robust_calibration.csv"
  )
)
write_h06_csv(
  covariance_sensitivity,
  file.path(
    diagnostic_root,
    "H06_v0_scaffold_pilot_robust_covariance_sensitivity.csv"
  )
)
write_h06_csv(
  influence_rank,
  file.path(
    diagnostic_root,
    "H06_v0_scaffold_pilot_robust_influence_ranking.csv"
  )
)
write_h06_csv(
  influence_refits,
  file.path(
    diagnostic_root,
    "H06_v0_scaffold_pilot_robust_targeted_deletions.csv"
  )
)
write_h06_csv(
  leave_site,
  file.path(
    diagnostic_root,
    "H06_v0_scaffold_pilot_robust_leave_site.csv"
  )
)
write_h06_csv(
  robust_summary,
  file.path(
    table_root,
    "H06_v0_scaffold_pilot_robust_assessment.csv"
  )
)

message("H06 robust-candidate pilot checks complete")
