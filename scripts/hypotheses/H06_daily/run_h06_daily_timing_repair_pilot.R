#!/usr/bin/env Rscript

# Run the author-approved 12-cell H06_daily timing-repair pilot.

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
  "digest", "dplyr", "glmmTMB", "performance", "readr", "sandwich",
  "tibble"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing synchronized packages: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R"
))

h06d_tr_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Timing-repair pilot requires R 4.6.1; found %s",
  as.character(getRversion())
)
expected_versions <- c(
  sandwich = "3.1.1",
  glmmTMB = "1.1.14",
  performance = "0.17.1"
)
for (package in names(expected_versions)) {
  actual <- as.character(utils::packageVersion(package))
  h06d_tr_assert(
    identical(actual, expected_versions[[package]]),
    "Timing-repair pilot requires %s %s; found %s",
    package,
    expected_versions[[package]],
    actual
  )
}

roots <- h06d_tr_artifact_roots(root)
invisible(lapply(roots, dir.create, recursive = TRUE, showWarnings = FALSE))
set.seed(20260812L)

#####
# Step 1: Verify inputs and preservation boundary
#####

control_pins <- h06d_tr_control_pins()
control_verification <- h06d_tr_verify_manifest_rows(root, control_pins)
h06d_tr_assert(
  all(control_verification$verification_status == "PASS"),
  "One or more timing-repair control pins failed"
)

base_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_non_l10_pilot_input_manifest.csv"
)
base_manifest <- readr::read_csv(base_manifest_path, show_col_types = FALSE) |>
  dplyr::select(
    "input_id", "relative_path", "expected_sha256", "role"
  )
h06d_tr_assert(
  nrow(base_manifest) == 26L && !anyDuplicated(base_manifest$input_id),
  "The sealed non-L10 input manifest is not the expected 26-row contract"
)
base_verification <- h06d_tr_verify_manifest_rows(root, base_manifest)
h06d_tr_assert(
  all(base_verification$verification_status == "PASS"),
  "One or more entries in the complete 26-row input contract failed"
)

input_contract <- dplyr::bind_rows(
  base_verification,
  control_verification
) |>
  dplyr::arrange(.data$input_id)
h06d_tr_assert(
  !anyDuplicated(input_contract$input_id),
  "The expanded timing-repair input contract has duplicate IDs"
)
input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_timing_repair_input_manifest.csv"
)
h06d_tr_write_csv(input_contract, input_manifest_path)

prior_preservation <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_non_l10_pilot_preservation_final.csv"
  ),
  show_col_types = FALSE
)
h06d_tr_assert(
  nrow(prior_preservation) == 535L &&
    all(prior_preservation$identity_status == "BYTE_IDENTICAL"),
  "The sealed 535-entry prior preservation record is not intact"
)

preservation_baseline_path <- file.path(
  roots$diagnostics,
  "H06_daily_timing_repair_preservation_baseline.csv"
)
preservation_baseline <- readr::read_csv(
  preservation_baseline_path,
  show_col_types = FALSE
)
h06d_tr_assert(
  nrow(preservation_baseline) == 571L &&
    !anyDuplicated(preservation_baseline$relative_path),
  "The timing-repair preservation baseline is not the sealed 571-entry set"
)
preservation_preflight <- h06d_tr_verify_preservation(
  root,
  preservation_baseline
)
h06d_tr_assert(
  all(preservation_preflight$identity_status == "BYTE_IDENTICAL"),
  "An earlier H06_daily file changed before the timing-repair pilot"
)

#####
# Step 2: Verify the 12 exact frames
#####

frame_bundle <- readRDS(file.path(
  roots$model_data,
  "H06_daily_non_l10_pilot_timing_frames.rds"
))
frame_pins <- h06d_tr_frame_pins()
metrics <- h06d_tr_metric_registry()
predictors <- h06d_tr_predictor_registry()

frame_checks <- list()
support_rows <- list()
selected_frames <- list()

for (index in seq_len(nrow(frame_pins))) {
  pin <- frame_pins[index, , drop = FALSE]
  metric <- dplyr::filter(metrics, .data$metric_id == pin$metric_id)
  predictor <- dplyr::filter(
    predictors,
    .data$predictor_id == pin$predictor_id
  )
  frame <- frame_bundle[[pin$frame_key]]
  h06d_tr_assert(!is.null(frame), "Missing sealed frame `%s`", pin$frame_key)
  actual_hash <- h06d_tr_object_sha256(frame)
  clock <- h06d_tr_clock_support(frame, metric)
  site_contrast_exact <- identical(
    unname(contrasts(frame$site)),
    unname(stats::contr.sum(nlevels(frame$site)))
  )
  unique_days <- !anyDuplicated(frame[c(
    "site", "participant_key", "local_date"
  )])
  frame_pass <- identical(actual_hash, pin$frame_object_sha256) &&
    nrow(frame) == pin$participant_days &&
    dplyr::n_distinct(frame$participant_key) == pin$participants &&
    dplyr::n_distinct(frame$site) == pin$sites &&
    all(is.finite(frame$response_value)) &&
    site_contrast_exact && unique_days &&
    isTRUE(clock$source_clock_acceptable)
  frame_checks[[pin$cell_id]] <- dplyr::bind_cols(
    pin,
    tibble::tibble(
      actual_frame_object_sha256 = actual_hash,
      actual_participant_days = nrow(frame),
      actual_participants = dplyr::n_distinct(frame$participant_key),
      actual_sites = dplyr::n_distinct(frame$site),
      response_finite = all(is.finite(frame$response_value)),
      site_contrast_exact = site_contrast_exact,
      unique_participant_days = unique_days,
      frame_verification_status = if (frame_pass) "PASS" else "FAIL"
    ),
    clock
  )
  h06d_tr_assert(frame_pass, "Sealed frame contract failed for `%s`", pin$cell_id)
  selected_frames[[pin$cell_id]] <- frame

  column <- predictor$column[[1L]]
  if (predictor$type[[1L]] == "categorical") {
    support_rows[[pin$cell_id]] <- frame |>
      dplyr::count(.data$site, .data[[column]], name = "participant_days") |>
      dplyr::transmute(
        cell_id = pin$cell_id,
        metric_id = pin$metric_id,
        predictor_id = pin$predictor_id,
        site = as.character(.data$site),
        predictor_level = as.character(.data[[column]]),
        participant_days = .data$participant_days,
        predictor_mean = NA_real_,
        predictor_sd = NA_real_,
        predictor_minimum = NA_real_,
        predictor_maximum = NA_real_
      )
  } else {
    support_rows[[pin$cell_id]] <- frame |>
      dplyr::summarise(
        participant_days = dplyr::n(),
        predictor_mean = mean(.data[[column]]),
        predictor_sd = stats::sd(.data[[column]]),
        predictor_minimum = min(.data[[column]]),
        predictor_maximum = max(.data[[column]]),
        .by = "site"
      ) |>
      dplyr::transmute(
        cell_id = pin$cell_id,
        metric_id = pin$metric_id,
        predictor_id = pin$predictor_id,
        site = as.character(.data$site),
        predictor_level = NA_character_,
        .data$participant_days,
        .data$predictor_mean,
        .data$predictor_sd,
        .data$predictor_minimum,
        .data$predictor_maximum
      )
  }
}

frame_contract <- dplyr::bind_rows(frame_checks)
predictor_support <- dplyr::bind_rows(support_rows)
h06d_tr_assert(
  all(frame_contract$frame_verification_status == "PASS"),
  "Not all 12 timing frames passed"
)
h06d_tr_assert(
  all(
    predictor_support$participant_days > 0L &
      (
        is.na(predictor_support$predictor_sd) |
          predictor_support$predictor_sd > 0
      )
  ),
  "A timing-repair predictor/site support cell is empty or invariant"
)

frame_contract_path <- file.path(
  roots$model_data,
  "H06_daily_timing_repair_frame_contract.csv"
)
predictor_support_path <- file.path(
  roots$model_data,
  "H06_daily_timing_repair_predictor_support.csv"
)
h06d_tr_write_csv(frame_contract, frame_contract_path)
h06d_tr_write_csv(predictor_support, predictor_support_path)

prior_diagnostics <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_non_l10_pilot_timing_diagnostics.csv"
  ),
  show_col_types = FALSE
)

#####
# Step 3: Run the serial candidate and diagnostic fits
#####

message("H06-D-009: running 12 timing-repair cells serially")
wall_started <- proc.time()[["elapsed"]]

model_bundle <- list()
candidate_model_rows <- list()
candidate_cell_rows <- list()
candidate_effect_rows <- list()
candidate_marginal_rows <- list()
candidate_test_rows <- list()
candidate_lag_rows <- list()
student_model_rows <- list()
ar_model_rows <- list()
ar_lag_rows <- list()
sensitivity_rows <- list()

for (index in seq_len(nrow(frame_pins))) {
  pin <- frame_pins[index, , drop = FALSE]
  metric <- dplyr::filter(metrics, .data$metric_id == pin$metric_id)
  predictor <- dplyr::filter(
    predictors,
    .data$predictor_id == pin$predictor_id
  )
  frame <- selected_frames[[pin$cell_id]]
  formulas <- h06d_tr_formula_set(predictor$column[[1L]], ar = FALSE)
  ar_formulas <- h06d_tr_formula_set(predictor$column[[1L]], ar = TRUE)
  clusters <- dplyr::n_distinct(frame$participant_key)
  message("  timing-repair cell: ", pin$cell_id)

  candidate_fits <- lapply(formulas, function(formula) {
    h06d_tr_fit_lm(frame, formula)
  })
  h06d_tr_assert(
    all(vapply(candidate_fits, function(fit) !is.null(fit$value), logical(1L))),
    "A candidate LM failed for `%s`",
    pin$cell_id
  )
  candidate_models <- lapply(candidate_fits, `[[`, "value")
  hc3 <- lapply(candidate_models, h06d_tr_hc3)
  h06d_tr_assert(
    all(vapply(hc3, function(value) !is.null(value$value), logical(1L))),
    "An HC3 covariance failed for `%s`",
    pin$cell_id
  )
  hc3_matrices <- lapply(hc3, `[[`, "value")

  for (structure in names(formulas)) {
    model_status <- h06d_tr_lm_status(candidate_models[[structure]])
    covariance_status <- h06d_tr_matrix_status(hc3_matrices[[structure]])
    leverage <- h06d_tr_leverage(candidate_models[[structure]], frame)
    gate_pass <- isTRUE(model_status$design_full_rank) &&
      isTRUE(model_status$finite_coefficients) &&
      isTRUE(covariance_status$finite) &&
      isTRUE(covariance_status$symmetric) &&
      isTRUE(covariance_status$positive_semidefinite) &&
      isTRUE(leverage$hc3_leverage_numerically_usable) &&
      length(hc3[[structure]]$warnings) == 0L
    candidate_model_rows[[paste(pin$cell_id, structure)]] <-
      dplyr::bind_cols(
        pin |>
          dplyr::select(
            "cell_id", "metric_id", "predictor_id",
            "participants", "participant_days", "sites"
          ),
        tibble::tibble(
          structure = structure,
          formula = h06d_tr_normalize_formula(formulas[[structure]]),
          covariance = paste(
            "sandwich::vcovCL(cluster = ~ participant_key, type = HC3,",
            "cadjust = TRUE, fix = FALSE)"
          ),
          covariance_warning_count = length(hc3[[structure]]$warnings),
          covariance_warnings = paste(
            hc3[[structure]]$warnings,
            collapse = " | "
          ),
          covariance_error = hc3[[structure]]$error,
          elapsed_lm_seconds = candidate_fits[[structure]]$elapsed_seconds,
          elapsed_hc3_seconds = hc3[[structure]]$elapsed_seconds
        ),
        model_status,
        covariance_status,
        leverage,
        tibble::tibble(candidate_model_gate_pass = gate_pass)
      )
  }

  additive_terms <- predictor$term[[1L]]
  interaction_terms <- h06d_tr_interaction_terms(
    candidate_models$interaction,
    predictor$column[[1L]]
  )
  association <- h06d_tr_wald_test(
    candidate_models$additive,
    hc3_matrices$additive,
    additive_terms,
    clusters,
    "association_predictor_block"
  )
  heterogeneity <- h06d_tr_wald_test(
    candidate_models$interaction,
    hc3_matrices$interaction,
    interaction_terms,
    clusters,
    "heterogeneity_predictor_by_site_block"
  )
  tests <- dplyr::bind_rows(association, heterogeneity) |>
    dplyr::mutate(
      metric_id = pin$metric_id,
      predictor_id = pin$predictor_id,
      cell_id = pin$cell_id,
      .before = 1L
    )
  candidate_test_rows[[pin$cell_id]] <- tests

  effect <- h06d_tr_effect(
    candidate_models$additive,
    hc3_matrices$additive,
    predictor,
    clusters
  ) |>
    dplyr::mutate(
      metric_id = pin$metric_id,
      predictor_id = pin$predictor_id,
      manuscript_name = metric$manuscript_name[[1L]],
      contrast = predictor$contrast_label[[1L]],
      cell_id = pin$cell_id,
      .before = 1L
    )
  candidate_effect_rows[[pin$cell_id]] <- effect
  candidate_marginal_rows[[pin$cell_id]] <- h06d_tr_equal_site_marginals(
    candidate_models$additive,
    hc3_matrices$additive,
    frame,
    predictor,
    metric,
    clusters
  ) |>
    dplyr::mutate(cell_id = pin$cell_id, .before = 1L)

  residual <- h06d_tr_residual_diagnostics(
    candidate_models$additive,
    frame
  )
  candidate_lag_rows[[pin$cell_id]] <- residual$by_site |>
    dplyr::mutate(
      cell_id = pin$cell_id,
      metric_id = pin$metric_id,
      predictor_id = pin$predictor_id,
      model_id = "hc3_additive_mean_model_residual",
      .before = 1L
    )

  student_fits <- lapply(formulas, function(formula) {
    h06d_tr_fit_student_t(frame, formula)
  })
  student_models <- lapply(student_fits, `[[`, "value")
  student_statuses <- list()
  for (structure in names(formulas)) {
    status <- h06d_tr_glmmtmb_status(
      student_models[[structure]],
      student_fits[[structure]]
    )
    student_statuses[[structure]] <- status
    degrees <- if (!is.null(student_models[[structure]])) {
      unname(glmmTMB::family_params(student_models[[structure]])[[1L]])
    } else {
      NA_real_
    }
    student_model_rows[[paste(pin$cell_id, structure)]] <-
      dplyr::bind_cols(
        pin |>
          dplyr::select("cell_id", "metric_id", "predictor_id"),
        tibble::tibble(
          structure = structure,
          formula = h06d_tr_normalize_formula(formulas[[structure]]),
          family = "Student-t identity",
          REML = FALSE,
          degrees_of_freedom = degrees,
          elapsed_seconds = student_fits[[structure]]$elapsed_seconds
        ),
        status
      )
  }
  student_additive_shift <- h06d_tr_shift_summary(
    candidate_models$additive,
    hc3_matrices$additive,
    if (isTRUE(student_statuses$additive$converged)) {
      student_models$additive
    } else {
      NULL
    },
    additive_terms,
    "predictor_additive"
  )
  student_interaction_shift <- h06d_tr_shift_summary(
    candidate_models$interaction,
    hc3_matrices$interaction,
    if (isTRUE(student_statuses$interaction$converged)) {
      student_models$interaction
    } else {
      NULL
    },
    interaction_terms,
    "predictor_by_site_block"
  )
  sensitivity_rows[[paste(pin$cell_id, "student")]] <- dplyr::bind_rows(
    student_additive_shift,
    student_interaction_shift
  ) |>
    dplyr::mutate(
      cell_id = pin$cell_id,
      metric_id = pin$metric_id,
      predictor_id = pin$predictor_id,
      sensitivity_id = "student_t_identity",
      inferential_role = "diagnostic only; no p-value substitution",
      .before = 1L
    )

  ar_frame <- h06d_tr_add_day_sequences(frame)
  ar_fits <- lapply(ar_formulas, function(formula) {
    h06d_tr_fit_no_nugget_ar(ar_frame, formula)
  })
  ar_models <- lapply(ar_fits, `[[`, "value")
  ar_statuses <- list()
  for (structure in names(ar_formulas)) {
    status <- h06d_tr_glmmtmb_status(
      ar_models[[structure]],
      ar_fits[[structure]]
    )
    ar_statuses[[structure]] <- status
    covariance_rank <- h06d_tr_covariance_rank(ar_models[[structure]])
    parameters <- h06d_tr_ar_parameters(ar_models[[structure]])
    lag <- if (!is.null(ar_models[[structure]])) {
      h06d_tr_lag_screen(
        ar_frame,
        as.numeric(stats::residuals(ar_models[[structure]]))
      )
    } else {
      list(
        overall = tibble::tibble(
          adjacent_pairs = NA_integer_,
          participants_with_adjacent_pair = NA_integer_,
          residual_lag1 = NA_real_,
          maximum_absolute_site_lag1 = NA_real_,
          temporal_threshold_pass = FALSE
        ),
        by_site = tibble::tibble()
      )
    }
    ar_model_rows[[paste(pin$cell_id, structure)]] <- dplyr::bind_cols(
      pin |>
        dplyr::select("cell_id", "metric_id", "predictor_id"),
      tibble::tibble(
        structure = structure,
        formula = h06d_tr_normalize_formula(ar_formulas[[structure]]),
        family = "Gaussian identity, no residual nugget",
        REML = TRUE,
        dispformula = "~0",
        elapsed_seconds = ar_fits[[structure]]$elapsed_seconds
      ),
      status,
      covariance_rank,
      parameters,
      lag$overall
    )
    if (nrow(lag$by_site)) {
      ar_lag_rows[[paste(pin$cell_id, structure)]] <- lag$by_site |>
        dplyr::mutate(
          cell_id = pin$cell_id,
          metric_id = pin$metric_id,
          predictor_id = pin$predictor_id,
          structure = structure,
          model_id = "no_nugget_gap_aware_ar1",
          .before = 1L
        )
    }
  }
  ar_additive_shift <- h06d_tr_shift_summary(
    candidate_models$additive,
    hc3_matrices$additive,
    if (isTRUE(ar_statuses$additive$converged)) {
      ar_models$additive
    } else {
      NULL
    },
    additive_terms,
    "predictor_additive"
  )
  ar_interaction_shift <- h06d_tr_shift_summary(
    candidate_models$interaction,
    hc3_matrices$interaction,
    if (isTRUE(ar_statuses$interaction$converged)) {
      ar_models$interaction
    } else {
      NULL
    },
    interaction_terms,
    "predictor_by_site_block"
  )
  sensitivity_rows[[paste(pin$cell_id, "ar")]] <- dplyr::bind_rows(
    ar_additive_shift,
    ar_interaction_shift
  ) |>
    dplyr::mutate(
      cell_id = pin$cell_id,
      metric_id = pin$metric_id,
      predictor_id = pin$predictor_id,
      sensitivity_id = "no_nugget_gap_aware_ar1",
      inferential_role = "diagnostic only; no p-value substitution",
      .before = 1L
    )

  candidate_model_cell <- dplyr::bind_rows(
    candidate_model_rows[paste(pin$cell_id, names(formulas))]
  )
  prior <- prior_diagnostics |>
    dplyr::filter(
      .data$metric_id == pin$metric_id,
      .data$predictor_id == pin$predictor_id
    )
  h06d_tr_assert(nrow(prior) == 1L, "Prior failure is not unique for `%s`", pin$cell_id)
  candidate_gate_pass <-
    all(candidate_model_cell$candidate_model_gate_pass) &&
    all(tests$test_status == "PILOT_RAW_ONLY_NO_BH_UPDATE") &&
    all(is.finite(effect$estimate_hours)) &&
    isTRUE(frame_checks[[pin$cell_id]]$source_clock_acceptable)
  candidate_cell_rows[[pin$cell_id]] <- dplyr::bind_cols(
    pin |>
      dplyr::select(
        "cell_id", "metric_id", "predictor_id",
        "participants", "participant_days", "sites"
      ),
    tibble::tibble(
      prior_diagnostic_disposition = prior$diagnostic_disposition,
      candidate_route = paste(
        "fixed-site lm with participant-cluster HC3;",
        "cluster-minus-one t/F reference"
      ),
      predictor_clusters = clusters,
      additive_design_rank = candidate_models$additive$rank,
      additive_design_columns = ncol(candidate_models$additive$x),
      interaction_design_rank = candidate_models$interaction$rank,
      interaction_design_columns = ncol(candidate_models$interaction$x),
      interaction_terms = paste(interaction_terms, collapse = " | "),
      interaction_block_terms = length(interaction_terms),
      maximum_observation_hat = max(stats::hatvalues(
        candidate_models$additive
      )),
      candidate_residual_lag1 = residual$overall$residual_lag1,
      candidate_maximum_site_residual_lag1 =
        residual$overall$maximum_absolute_site_lag1,
      candidate_gate_pass = candidate_gate_pass,
      candidate_disposition = if (candidate_gate_pass) {
        "NUMERICALLY_ACCEPTABLE_CANDIDATE_ROUTE"
      } else {
        "NOT_ACCEPTABLE_CANDIDATE_ROUTE"
      }
    )
  )

  model_bundle[[pin$cell_id]] <- list(
    frame_object_sha256 = pin$frame_object_sha256,
    candidate = list(
      fits = candidate_fits,
      hc3 = hc3,
      formulas = formulas
    ),
    student_t = list(fits = student_fits, formulas = formulas),
    no_nugget_ar = list(
      fits = ar_fits,
      formulas = ar_formulas,
      frame_object_sha256 = h06d_tr_object_sha256(ar_frame)
    )
  )
}

wall_elapsed <- unname(proc.time()[["elapsed"]] - wall_started)

candidate_model_diagnostics <- dplyr::bind_rows(candidate_model_rows)
candidate_cell_diagnostics <- dplyr::bind_rows(candidate_cell_rows)
candidate_effects <- dplyr::bind_rows(candidate_effect_rows)
candidate_marginals <- dplyr::bind_rows(candidate_marginal_rows)
candidate_tests <- dplyr::bind_rows(candidate_test_rows)
candidate_lag_by_site <- dplyr::bind_rows(candidate_lag_rows)
student_diagnostics <- dplyr::bind_rows(student_model_rows)
ar_diagnostics <- dplyr::bind_rows(ar_model_rows)
ar_lag_by_site <- dplyr::bind_rows(ar_lag_rows)
sensitivity_stability <- dplyr::bind_rows(sensitivity_rows)

h06d_tr_assert(nrow(candidate_model_diagnostics) == 36L, "Expected 36 LM rows")
h06d_tr_assert(nrow(student_diagnostics) == 36L, "Expected 36 Student-t rows")
h06d_tr_assert(nrow(ar_diagnostics) == 36L, "Expected 36 no-nugget AR rows")
h06d_tr_assert(nrow(candidate_tests) == 24L, "Expected 24 robust Wald tests")
h06d_tr_assert(
  all(candidate_tests$multiplicity_status == "PILOT_RAW_ONLY_NO_BH_UPDATE") &&
    all(is.na(candidate_tests$adjusted_p_value)),
  "The timing-repair pilot unexpectedly created adjusted p-values"
)

classification_rank <- c(
  STABLE = 1L,
  SUBSTANTIAL_LIMITATION = 2L,
  UNSTABLE = 3L,
  UNRESOLVED_TERM_MISMATCH = 4L,
  UNRESOLVED_NUMERICAL_FAILURE = 4L
)
cell_sensitivity <- sensitivity_stability |>
  dplyr::mutate(
    classification_rank = unname(
      .env$classification_rank[.data$sensitivity_classification]
    )
  ) |>
  dplyr::summarise(
    worst_rank = max(.data$classification_rank, na.rm = TRUE),
    maximum_shift_in_hc3_se = max(
      .data$maximum_shift_in_hc3_se,
      na.rm = TRUE
    ),
    any_direction_reversal = any(
      .data$direction_reversal,
      na.rm = TRUE
    ),
    sensitivity_summary = paste(
      paste(
        .data$sensitivity_id,
        .data$component,
        .data$sensitivity_classification,
        sep = ":"
      ),
      collapse = " | "
    ),
    .by = c("cell_id", "metric_id", "predictor_id")
  ) |>
  dplyr::mutate(
    worst_sensitivity_classification = dplyr::case_when(
      .data$worst_rank >= 4L ~ "UNRESOLVED",
      .data$worst_rank == 3L ~ "UNSTABLE",
      .data$worst_rank == 2L ~ "SUBSTANTIAL_LIMITATION",
      TRUE ~ "STABLE"
    )
  )

candidate_cell_diagnostics <- candidate_cell_diagnostics |>
  dplyr::left_join(
    cell_sensitivity,
    by = c("cell_id", "metric_id", "predictor_id"),
    relationship = "one-to-one"
  )

outcome_verdict <- candidate_cell_diagnostics |>
  dplyr::summarise(
    predictor_cells = dplyr::n(),
    candidate_cells_acceptable = sum(.data$candidate_gate_pass),
    all_three_predictors_candidate_acceptable =
      dplyr::n() == 3L && all(.data$candidate_gate_pass),
    worst_sensitivity_rank = max(.data$worst_rank),
    maximum_shift_in_hc3_se = max(.data$maximum_shift_in_hc3_se),
    any_direction_reversal = any(.data$any_direction_reversal),
    .by = "metric_id"
  ) |>
  dplyr::left_join(
    metrics |>
      dplyr::select("metric_order", "metric_slot", "metric_id", "manuscript_name"),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    timing_repair_disposition = dplyr::case_when(
      !.data$all_three_predictors_candidate_acceptable ~
        "HOLD_CANDIDATE_NUMERICAL_OR_DESIGN_FAILURE",
      .data$worst_sensitivity_rank >= 4L ~
        "AUTHOR_REVIEW_CANDIDATE_ACCEPTABLE_SENSITIVITY_UNRESOLVED",
      .data$worst_sensitivity_rank == 3L ~
        "AUTHOR_REVIEW_CANDIDATE_ACCEPTABLE_SENSITIVITY_UNSTABLE",
      .data$worst_sensitivity_rank == 2L ~
        "AUTHOR_REVIEW_CANDIDATE_ACCEPTABLE_SUBSTANTIAL_LIMITATION",
      TRUE ~
        "RECOMMEND_LATER_PRODUCTION_EXPLICIT_APPROVAL_REQUIRED"
    ),
    gate_status = "H06-D-G2P-TIMING-REPAIR_AWAITING_AUTHOR_REVIEW"
  ) |>
  dplyr::arrange(.data$metric_order)

runtime <- tibble::tribble(
  ~component, ~model_fits, ~elapsed_seconds, ~role,
  "Candidate fixed-site LM", 36L,
  sum(candidate_model_diagnostics$elapsed_lm_seconds),
  "candidate mean structures",
  "Participant-cluster HC3 covariance", 36L,
  sum(candidate_model_diagnostics$elapsed_hc3_seconds),
  "candidate covariance calculations",
  "Student-t identity sensitivity", 36L,
  sum(student_diagnostics$elapsed_seconds),
  "diagnostic only",
  "No-nugget gap-aware AR sensitivity", 36L,
  sum(ar_diagnostics$elapsed_seconds),
  "diagnostic only",
  "Complete bounded serial pilot", 108L, wall_elapsed,
  "measured wall time"
) |>
  dplyr::mutate(
    projected_12_role_seconds = dplyr::if_else(
      .data$component == "Complete bounded serial pilot",
      .data$elapsed_seconds * 12,
      NA_real_
    ),
    projection_scope = dplyr::if_else(
      .data$component == "Complete bounded serial pilot",
      "mechanical 12-role timing-only projection; no production authorization",
      NA_character_
    )
  )

#####
# Step 4: Write bounded outputs and verify preservation
#####

model_path <- file.path(
  roots$models,
  "H06_daily_timing_repair_pilot_models.rds"
)
h06d_tr_write_rds(
  list(
    gate = "H06-D-G2P-TIMING-REPAIR",
    authorization = h06d_tr_authorization(),
    cells = model_bundle,
    r_version = R.version.string,
    package_versions = vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1L)
    )
  ),
  model_path
)

output_paths <- c(
  frame_contract_path,
  predictor_support_path,
  model_path,
  file.path(roots$diagnostics, "H06_daily_timing_repair_candidate_models.csv"),
  file.path(roots$diagnostics, "H06_daily_timing_repair_candidate_cells.csv"),
  file.path(roots$diagnostics, "H06_daily_timing_repair_candidate_lag_by_site.csv"),
  file.path(roots$diagnostics, "H06_daily_timing_repair_student_t.csv"),
  file.path(roots$diagnostics, "H06_daily_timing_repair_no_nugget_ar.csv"),
  file.path(roots$diagnostics, "H06_daily_timing_repair_no_nugget_ar_lag_by_site.csv"),
  file.path(roots$diagnostics, "H06_daily_timing_repair_sensitivity_stability.csv"),
  file.path(roots$tables, "H06_daily_timing_repair_effects.csv"),
  file.path(roots$tables, "H06_daily_timing_repair_equal_site_marginals.csv"),
  file.path(roots$tables, "H06_daily_timing_repair_raw_tests.csv"),
  file.path(roots$tables, "H06_daily_timing_repair_outcome_verdict.csv"),
  file.path(roots$tables, "H06_daily_timing_repair_runtime.csv")
)

h06d_tr_write_csv(candidate_model_diagnostics, output_paths[[4L]])
h06d_tr_write_csv(candidate_cell_diagnostics, output_paths[[5L]])
h06d_tr_write_csv(candidate_lag_by_site, output_paths[[6L]])
h06d_tr_write_csv(student_diagnostics, output_paths[[7L]])
h06d_tr_write_csv(ar_diagnostics, output_paths[[8L]])
h06d_tr_write_csv(ar_lag_by_site, output_paths[[9L]])
h06d_tr_write_csv(sensitivity_stability, output_paths[[10L]])
h06d_tr_write_csv(candidate_effects, output_paths[[11L]])
h06d_tr_write_csv(candidate_marginals, output_paths[[12L]])
h06d_tr_write_csv(candidate_tests, output_paths[[13L]])
h06d_tr_write_csv(outcome_verdict, output_paths[[14L]])
h06d_tr_write_csv(runtime, output_paths[[15L]])

preservation_final <- h06d_tr_verify_preservation(
  root,
  preservation_baseline
)
h06d_tr_assert(
  nrow(preservation_final) == 571L &&
    all(preservation_final$identity_status == "BYTE_IDENTICAL"),
  "An earlier H06_daily file changed during the timing-repair pilot"
)
preservation_final_path <- file.path(
  roots$diagnostics,
  "H06_daily_timing_repair_preservation_final.csv"
)
h06d_tr_write_csv(preservation_final, preservation_final_path)
output_paths <- c(output_paths, preservation_baseline_path, preservation_final_path)

code_paths <- c(
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_timing_repair_pilot.R"
)
code_manifest <- dplyr::bind_rows(lapply(
  code_paths,
  function(path) h06d_tr_file_record(root, path, "executed pilot code")
))
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_timing_repair_code_manifest.csv"
)
h06d_tr_write_csv(code_manifest, code_manifest_path)

software_manifest <- tibble::tibble(
  software = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1L)
    )
  ),
  role = c(
    "authoritative scientific runtime",
    rep("synchronized project library", length(required_packages))
  )
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_timing_repair_software_manifest.csv"
)
h06d_tr_write_csv(software_manifest, software_manifest_path)

output_manifest <- dplyr::bind_rows(lapply(
  c(output_paths, input_manifest_path, code_manifest_path, software_manifest_path),
  function(path) h06d_tr_file_record(
    root,
    path,
    "bounded timing-repair pilot output"
  )
)) |>
  dplyr::arrange(.data$relative_path)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_timing_repair_output_manifest.csv"
)
h06d_tr_write_csv(output_manifest, output_manifest_path)

pipeline_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_timing_repair_pipeline_manifest.csv"
)
pipeline_manifest <- dplyr::bind_rows(
  lapply(
    c(
      output_manifest_path,
      input_manifest_path,
      code_manifest_path,
      software_manifest_path
    ),
    function(path) h06d_tr_file_record(
      root,
      path,
      "timing-repair pipeline contract or manifest"
    )
  ),
  output_manifest
) |>
  dplyr::distinct(.data$relative_path, .keep_all = TRUE) |>
  dplyr::arrange(.data$relative_path)
h06d_tr_write_csv(pipeline_manifest, pipeline_manifest_path)

message(sprintf(
  paste0(
    "H06-D-G2P-TIMING-REPAIR complete: 12 cells, 108 fits, %.2f s; ",
    "%d candidate-pass cells; %d preserved files; no BH update."
  ),
  wall_elapsed,
  sum(candidate_cell_diagnostics$candidate_gate_pass),
  nrow(preservation_final)
))
