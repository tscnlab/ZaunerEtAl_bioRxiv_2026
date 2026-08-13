#!/usr/bin/env Rscript

# H06-D-013 phase 3: bounded diagnostic sensitivities not contained in the
# frozen primary-fit objects. No primary p-value is replaced here.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c(
  "digest", "dplyr", "tidyr", "tibble", "readr", "lme4", "glmmTMB",
  "performance", "emmeans", "sandwich", "melidosData", "LightLogR"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(lme4)
  library(glmmTMB)
  library(performance)
  library(emmeans)
  library(sandwich)
})

for (script in c(
  "h06_daily_non_l10_pilot_contract.R",
  "h06_daily_non_l10_pilot_data.R",
  "h06_daily_non_l10_pilot_modeling.R",
  "h06_daily_timing_repair_contract.R",
  "h06_daily_timing_repair_modeling.R",
  "h06_daily_non_l10_production_contract.R",
  "h06_daily_non_l10_production_modeling.R"
)) {
  source(file.path(root, "scripts/hypotheses/H06_daily", script))
}

h06d_prod_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06-D-013 diagnostic sensitivities require R 4.6.1"
)
h06d_prod_assert(
  identical(as.character(utils::packageVersion("melidosData")), "1.0.6"),
  "H06-D-013 requires immutable melidosData 1.0.6"
)

paths <- h06d_prod_checkpoint_paths(root)
diagnostic_dir <- file.path(root, "artifacts/08_diagnostics/H06_daily")
model_dir <- file.path(root, "artifacts/07_models/H06_daily")
preservation_baseline <- readr::read_csv(
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_baseline.csv"
  ),
  show_col_types = FALSE
)
invisible(h06d_prod_verify_contract(root, h06d_prod_input_contract()))
invisible(h06d_prod_verify_contract(
  root,
  h06d_prod_main_h06_contract() |>
    dplyr::mutate(input_id = paste0("main_h06_", dplyr::row_number()), .before = 1L)
))
h06d_prod_recheck_preservation(
  root,
  preservation_baseline,
  "pre_sensitivity"
) |>
  h06d_prod_write_csv(file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_pre_sensitivity.csv"
  ))

state <- readRDS(paths$state)
h06d_prod_assert(
  identical(state$authorization, "H06-D-013") &&
    identical(state$phase, "INFLUENCE_COMPLETE") &&
    state$completed_refits == 66664L,
  "The complete influence phase must precede bounded sensitivities"
)
base_index <- readr::read_csv(paths$base_index, show_col_types = FALSE) |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
h06d_prod_assert(
  nrow(base_index) == 468L && all(base_index$outer_success),
  "The complete base index is unavailable"
)

frame_build <- h06d_nl_build_frames(
  h06d_nl_load_sources(root),
  retain_frames = TRUE
)
frames <- frame_build$frames
metrics <- h06d_nl_metric_registry()
predictors <- h06d_nl_predictor_registry()
h06d_prod_assert(
  nrow(frame_build$inventory) == 468L && all(vapply(
    base_index$frame_key,
    function(frame_key) {
      digest::digest(
        frames[[frame_key]],
        algo = "sha256",
        serialize = TRUE
      ) == base_index$frame_object_sha256[
        base_index$frame_key == frame_key
      ][[1L]]
    },
    logical(1)
  )),
  "A rebuilt frame differs from its base-fit identity"
)

metadata <- function(meta) {
  meta |>
    dplyr::select(
      "run_order", "run_id", "dataset_id", "placement_id", "sample_role",
      "analysis_role", "test_role", "metric_slot", "metric_id",
      "manuscript_name", "display_unit", "response_family",
      "response_transform", "effect_scale", "predictor_order",
      "predictor_id", "reader_name", "contrast_label", "frame_key",
      "participant_days", "participants", "sites", "exact_source_zeros",
      "frame_object_sha256", "route"
    )
}

shift_class <- function(shift, reversal, estimable) {
  dplyr::case_when(
    !isTRUE(estimable) || !is.finite(shift) ~ "NON_ESTIMABLE_SENSITIVITY",
    isTRUE(reversal) || shift >= 2 ~ "UNSTABLE",
    shift >= 1 ~ "SUBSTANTIAL_LIMITATION",
    TRUE ~ "STABLE"
  )
}

fit_tweedie_ar <- function(frame, metric, predictor, full_effect, full_se) {
  ar_frame <- h06d_nl_add_day_sequences(frame)
  formula <- h06d_nl_formula_set(
    predictor$column[[1L]],
    ar = TRUE
  )$fixed_site_additive
  capture <- h06d_prod_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = ar_frame,
    family = glmmTMB::tweedie(link = "log"),
    REML = FALSE,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
  status <- h06d_nl_model_status(capture$value)
  parameters <- if (is.null(capture$value)) {
    tibble::tibble(ar_standard_deviation = NA_real_, ar_rho = NA_real_)
  } else {
    h06d_nl_ar_parameters(capture$value)
  }
  effect <- if (!is.null(capture$value)) {
    tryCatch(
      h06d_nl_effect_row(capture$value, predictor, metric),
      error = function(condition) NULL
    )
  } else {
    NULL
  }
  shift <- if (!is.null(effect)) {
    abs(effect$estimate[[1L]] - full_effect) / full_se
  } else {
    NA_real_
  }
  reversal <- if (!is.null(effect)) {
    sign(effect$estimate[[1L]]) != sign(full_effect)
  } else {
    NA
  }
  lag <- if (!is.null(capture$value)) {
    h06d_nl_lag_screen(
      ar_frame,
      as.numeric(stats::residuals(capture$value, type = "pearson"))
    )
  } else {
    list(
      overall = tibble::tibble(
        adjacent_pairs = NA_integer_,
        participants = NA_integer_,
        residual_lag1 = NA_real_,
        maximum_absolute_site_lag1 = NA_real_,
        ar_trigger = NA
      ),
      by_site = tibble::tibble()
    )
  }
  estimable <- !is.null(capture$value) && isTRUE(status$converged) &&
    isTRUE(status$positive_definite_hessian) && !isTRUE(status$singular) &&
    is.finite(parameters$ar_rho) && abs(parameters$ar_rho) < 0.95
  acceptable <- estimable && is.finite(shift) && shift < 1 &&
    !isTRUE(reversal) &&
    is.finite(lag$overall$residual_lag1) &&
    abs(lag$overall$residual_lag1) < 0.20 &&
    is.finite(lag$overall$maximum_absolute_site_lag1) &&
    lag$overall$maximum_absolute_site_lag1 < 0.30
  disposition <- dplyr::case_when(
    is.null(capture$value) ~ "UNRESOLVED_AR_FIT_FAILURE",
    !isTRUE(status$converged) || !isTRUE(status$positive_definite_hessian) ~
      "UNRESOLVED_AR_NUMERICAL_FAILURE",
    isTRUE(status$singular) ~ "UNRESOLVED_AR_SINGULAR",
    !is.finite(parameters$ar_rho) || abs(parameters$ar_rho) >= 0.95 ~
      "UNRESOLVED_AR_BOUNDARY",
    !is.finite(shift) || shift >= 2 || isTRUE(reversal) ~
      "UNSTABLE_AR_EFFECT",
    shift >= 1 ~ "SUBSTANTIAL_AR_EFFECT_LIMITATION",
    !is.finite(lag$overall$residual_lag1) ||
      abs(lag$overall$residual_lag1) >= 0.20 ||
      !is.finite(lag$overall$maximum_absolute_site_lag1) ||
      lag$overall$maximum_absolute_site_lag1 >= 0.30 ~
      "UNRESOLVED_POST_AR_RESIDUAL_DEPENDENCE",
    TRUE ~ "ACCEPTABLE"
  )
  list(
    capture = capture,
    row = dplyr::bind_cols(
      status,
      parameters,
      tibble::tibble(
        effect_estimate = if (is.null(effect)) NA_real_ else effect$estimate[[1L]],
        effect_standard_error = if (is.null(effect)) {
          NA_real_
        } else {
          effect$standard_error[[1L]]
        },
        effect_lower_95 = if (is.null(effect)) NA_real_ else effect$lower_95[[1L]],
        effect_upper_95 = if (is.null(effect)) NA_real_ else effect$upper_95[[1L]],
        effect_shift_in_primary_se = shift,
        direction_reversal = reversal,
        post_ar_residual_lag1 = lag$overall$residual_lag1,
        post_ar_maximum_absolute_site_lag1 =
          lag$overall$maximum_absolute_site_lag1,
        adjacent_pairs = lag$overall$adjacent_pairs,
        participants_with_adjacency = lag$overall$participants,
        warning_count = length(capture$warnings),
        warnings = paste(capture$warnings, collapse = " | "),
        fit_error = capture$error,
        elapsed_seconds = capture$elapsed_seconds,
        ar_acceptable = acceptable,
        ar_disposition = disposition,
        inferential_role = "diagnostic sensitivity; no p-value substitution"
      )
    ),
    lag_by_site = lag$by_site
  )
}

message("H06-D-013 phase 3: running bounded family and support sensitivities")
phase_started <- proc.time()[["elapsed"]]
model_bundle <- list()
tweedie_rows <- list()
tweedie_ar_rows <- list()
tweedie_ar_site_rows <- list()
student_rows <- list()
period_rows <- list()
clock_rows <- list()

for (index in seq_len(nrow(base_index))) {
  meta <- base_index[index, , drop = FALSE]
  frame <- frames[[meta$frame_key[[1L]]]]
  metric <- dplyr::filter(metrics, .data$metric_id == meta$metric_id[[1L]])
  predictor <- dplyr::filter(
    predictors,
    .data$predictor_id == meta$predictor_id[[1L]]
  )
  object <- readRDS(file.path(root, meta$checkpoint_relative_path[[1L]]))
  result <- object$result
  full_effect <- result$influence_reference$estimate
  full_se <- result$influence_reference$standard_error
  key <- meta$frame_key[[1L]]

  if (identical(meta$response_family[[1L]], "tweedie_log")) {
    model <- result$influence_reference$model
    residual <- as.numeric(stats::residuals(model, type = "pearson"))
    fitted <- as.numeric(stats::predict(model, type = "response"))
    centered <- residual - mean(residual, na.rm = TRUE)
    residual_sd <- stats::sd(centered, na.rm = TRUE)
    power <- tryCatch(
      unname(glmmTMB::family_params(model)[[1L]]),
      error = function(condition) NA_real_
    )
    lag <- h06d_nl_lag_screen(frame, residual)
    bounds <- h06d_nl_prediction_bounds(model, frame, metric)
    tweedie_rows[[key]] <- dplyr::bind_cols(
      metadata(meta),
      tibble::tibble(
        tweedie_power = power,
        tweedie_power_interior = is.finite(power) && power > 1 && power < 2,
        dispersion = unname(stats::sigma(model)),
        exact_zero_fraction = mean(frame$response_source == 0),
        pearson_residual_fitted_spearman = abs(suppressWarnings(stats::cor(
          abs(residual),
          fitted,
          method = "spearman",
          use = "complete.obs"
        ))),
        pearson_residual_skewness = if (
          is.finite(residual_sd) && residual_sd > 0
        ) {
          mean((centered / residual_sd)^3, na.rm = TRUE)
        } else {
          NA_real_
        },
        standardized_residual_gt4_fraction = if (
          is.finite(residual_sd) && residual_sd > 0
        ) {
          mean(abs(centered / residual_sd) > 4, na.rm = TRUE)
        } else {
          NA_real_
        },
        independent_residual_lag1 = lag$overall$residual_lag1,
        independent_maximum_absolute_site_lag1 =
          lag$overall$maximum_absolute_site_lag1,
        adjacent_pairs = lag$overall$adjacent_pairs,
        participants_with_adjacency = lag$overall$participants,
        ar_trigger = lag$overall$ar_trigger,
        simulation_diagnostic_status =
          "NOT_RUN_BY_H06-D-013_NO_SIMULATION_AUTHORIZATION"
      ),
      bounds
    )
    if (isTRUE(lag$overall$ar_trigger)) {
      message("  Tweedie AR diagnostic: ", key)
      ar <- fit_tweedie_ar(
        frame,
        metric,
        predictor,
        full_effect,
        full_se
      )
      model_bundle[[paste0(key, "__tweedie_ar")]] <- ar$capture$value
      tweedie_ar_rows[[key]] <- dplyr::bind_cols(metadata(meta), ar$row)
      if (nrow(ar$lag_by_site)) {
        tweedie_ar_site_rows[[key]] <- ar$lag_by_site |>
          dplyr::mutate(frame_key = key, .before = 1L)
      }
    }
  }

  if (
    identical(meta$route[[1L]], "mixed_model") &&
      identical(meta$response_family[[1L]], "gaussian")
  ) {
    diagnostic <- result$diagnostics
    trigger_student <-
      is.finite(diagnostic$residual_qq_correlation[[1L]]) &&
        diagnostic$residual_qq_correlation[[1L]] < 0.95 ||
      is.finite(diagnostic$absolute_residual_fitted_spearman[[1L]]) &&
        abs(diagnostic$absolute_residual_fitted_spearman[[1L]]) >= 0.20 ||
      is.finite(diagnostic$standardized_residual_gt4_fraction[[1L]]) &&
        diagnostic$standardized_residual_gt4_fraction[[1L]] >= 0.01
    if (isTRUE(trigger_student)) {
      message("  Student-t diagnostic: ", key)
      formula <- h06d_nl_formula_set(
        predictor$column[[1L]]
      )$fixed_site_additive
      capture <- h06d_tr_fit_student_t(frame, formula)
      status <- h06d_tr_glmmtmb_status(capture$value, capture)
      singular <- if (is.null(capture$value)) {
        NA
      } else {
        suppressWarnings(tryCatch(
          as.logical(performance::check_singularity(capture$value)),
          error = function(condition) NA
        ))
      }
      effect <- if (!is.null(capture$value)) {
        tryCatch(
          h06d_nl_effect_row(capture$value, predictor, metric),
          error = function(condition) NULL
        )
      } else {
        NULL
      }
      shift <- if (!is.null(effect)) {
        abs(effect$estimate[[1L]] - full_effect) / full_se
      } else {
        NA_real_
      }
      reversal <- if (!is.null(effect)) {
        sign(effect$estimate[[1L]]) != sign(full_effect)
      } else {
        NA
      }
      estimable <- !is.null(capture$value) && isTRUE(status$converged) &&
        isTRUE(status$positive_definite_hessian) &&
        isTRUE(status$finite_fixed_effects) &&
        isTRUE(status$finite_standard_errors) && !isTRUE(singular)
      model_bundle[[paste0(key, "__student_t")]] <- capture$value
      student_rows[[key]] <- dplyr::bind_cols(
        metadata(meta),
        status,
        tibble::tibble(
          singular = singular,
          student_t_degrees_of_freedom = if (is.null(capture$value)) {
            NA_real_
          } else {
            tryCatch(
              unname(glmmTMB::family_params(capture$value)[[1L]]),
              error = function(condition) NA_real_
            )
          },
          effect_estimate = if (is.null(effect)) {
            NA_real_
          } else {
            effect$estimate[[1L]]
          },
          effect_standard_error = if (is.null(effect)) {
            NA_real_
          } else {
            effect$standard_error[[1L]]
          },
          effect_lower_95 = if (is.null(effect)) {
            NA_real_
          } else {
            effect$lower_95[[1L]]
          },
          effect_upper_95 = if (is.null(effect)) {
            NA_real_
          } else {
            effect$upper_95[[1L]]
          },
          effect_shift_in_primary_se = shift,
          direction_reversal = reversal,
          sensitivity_classification = shift_class(
            shift,
            reversal,
            estimable
          ),
          inferential_role = "diagnostic sensitivity; no p-value substitution"
        )
      )
    }
  }

  if (identical(meta$metric_id[[1L]], "longest_bout_above_250") &&
      identical(meta$dataset_id[[1L]], "primary") &&
      any(frame$longest_period_exact %in% TRUE)) {
    exact_frame <- droplevels(frame[frame$longest_period_exact %in% TRUE, ])
    if (nlevels(exact_frame$site) > 1L) {
      contrasts(exact_frame$site) <- stats::contr.sum(nlevels(exact_frame$site))
    }
    design <- h06d_nl_design_check(exact_frame, predictor, FALSE)
    capture <- if (isTRUE(design$estimable)) {
      h06d_prod_mixed_fit(
        exact_frame,
        metric,
        predictor,
        h06d_nl_formula_set(
          predictor$column[[1L]]
        )$fixed_site_additive,
        REML = TRUE
      )
    } else {
      list(
        value = NULL,
        error = "exact-subset additive design not estimable",
        warnings = character(),
        elapsed_seconds = 0
      )
    }
    acceptable <- h06d_prod_mixed_model_acceptable(capture)
    effect <- if (acceptable) {
      h06d_prod_mixed_effect(capture$value, metric, predictor)
    } else {
      NULL
    }
    shift <- if (!is.null(effect)) {
      abs(effect$estimate[[1L]] - full_effect) / full_se
    } else {
      NA_real_
    }
    reversal <- if (!is.null(effect)) {
      sign(effect$estimate[[1L]]) != sign(full_effect)
    } else {
      NA
    }
    model_bundle[[paste0(key, "__period_exact")]] <- capture$value
    period_rows[[key]] <- dplyr::bind_cols(
      metadata(meta),
      design |>
        dplyr::rename_with(~ paste0("exact_", .x)),
      tibble::tibble(
        exact_participant_days = nrow(exact_frame),
        exact_participants = dplyr::n_distinct(exact_frame$participant_key),
        exact_sites = dplyr::n_distinct(exact_frame$site),
        exact_fraction_of_primary_frame = nrow(exact_frame) / nrow(frame),
        exact_effect_estimate = if (is.null(effect)) {
          NA_real_
        } else {
          effect$estimate[[1L]]
        },
        exact_effect_standard_error = if (is.null(effect)) {
          NA_real_
        } else {
          effect$standard_error[[1L]]
        },
        exact_effect_lower_95 = if (is.null(effect)) {
          NA_real_
        } else {
          effect$lower_95[[1L]]
        },
        exact_effect_upper_95 = if (is.null(effect)) {
          NA_real_
        } else {
          effect$upper_95[[1L]]
        },
        effect_shift_in_primary_se = shift,
        direction_reversal = reversal,
        sensitivity_classification = shift_class(
          shift,
          reversal,
          acceptable
        ),
        warning_count = length(capture$warnings),
        warnings = paste(capture$warnings, collapse = " | "),
        fit_error = capture$error,
        elapsed_seconds = capture$elapsed_seconds,
        inferential_role =
          "exact-identifiable period sensitivity; no multiplicity slot"
      )
    )
  }

  if (identical(meta$metric_id[[1L]], "mean_timing_above_250")) {
    clock_rows[[key]] <- dplyr::bind_cols(
      metadata(meta),
      h06d_nl_clock_source_diagnostics(frame, metric)
    )
  }
}

tweedie <- dplyr::bind_rows(tweedie_rows)
tweedie_ar <- dplyr::bind_rows(tweedie_ar_rows)
tweedie_ar_site <- dplyr::bind_rows(tweedie_ar_site_rows)
student <- dplyr::bind_rows(student_rows)
period <- dplyr::bind_rows(period_rows)
clock <- dplyr::bind_rows(clock_rows)
h06d_prod_assert(
  nrow(tweedie) == 108L && nrow(tweedie_ar) == sum(tweedie$ar_trigger) &&
    nrow(period) == 18L && nrow(clock) == 36L,
  "The bounded diagnostic-sensitivity inventory is incomplete"
)

h06d_prod_write_csv(
  tweedie,
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_tweedie_diagnostics.csv"
  )
)
h06d_prod_write_csv(
  tweedie_ar,
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_tweedie_ar_sensitivity.csv"
  )
)
h06d_prod_write_csv(
  tweedie_ar_site,
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_tweedie_ar_lag_by_site.csv"
  )
)
h06d_prod_write_csv(
  student,
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_gaussian_student_t_sensitivity.csv"
  )
)
h06d_prod_write_csv(
  period,
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_period_exact_sensitivity.csv"
  )
)
h06d_prod_write_csv(
  clock,
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_mean_timing_clock_support.csv"
  )
)
h06d_prod_write_rds(
  list(
    gate = "H06-D-G2",
    authorization = "H06-D-013",
    models = model_bundle,
    r_version = as.character(getRversion()),
    package_versions = vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  file.path(
    model_dir,
    "H06_daily_non_l10_production_diagnostic_sensitivity_models.rds"
  )
)

sensitivity_elapsed <- unname(proc.time()[["elapsed"]] - phase_started)
h06d_prod_recheck_preservation(
  root,
  preservation_baseline,
  "post_sensitivity"
) |>
  h06d_prod_write_csv(file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_post_sensitivity.csv"
  ))
h06d_prod_write_rds(
  utils::modifyList(
    state,
    list(
      phase = "SENSITIVITY_COMPLETE",
      sensitivity_models = length(model_bundle),
      tweedie_ar_models = nrow(tweedie_ar),
      gaussian_student_t_models = nrow(student),
      period_exact_models = nrow(period),
      sensitivity_elapsed_seconds = sensitivity_elapsed,
      updated = format(Sys.time(), tz = "UTC", usetz = TRUE)
    )
  ),
  paths$state
)
message(sprintf(
  paste0(
    "H06-D-013 bounded sensitivities complete in %.1f seconds: ",
    "%d Tweedie AR, %d Student-t, %d exact-period fits"
  ),
  sensitivity_elapsed,
  nrow(tweedie_ar),
  nrow(student),
  nrow(period)
))
