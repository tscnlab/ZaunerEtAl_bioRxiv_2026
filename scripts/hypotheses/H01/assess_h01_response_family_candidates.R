# Assess common response-family candidates for the three gated H01 metrics.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h01_abort(
    "The H01 candidate-family assessment requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

producer <-
  "scripts/hypotheses/H01/assess_h01_response_family_candidates.R"
protocol <-
  "audit/hypotheses/H01/H01_response_family_candidate_protocol.md"

candidate_registry <- tibble::tribble(
  ~metric_id, ~candidate_order, ~candidate_id, ~candidate_label,
  ~response_family, ~response_transform, ~effect_scale, ~candidate_role,
  "duration_below_1_sleep_environment", 1L,
  "tweedie_log_identity", "Tweedie, log link",
  "tweedie_log", "identity", "ratio", "current",
  "duration_below_1_sleep_environment", 2L,
  "gaussian_identity", "Gaussian, identity scale",
  "gaussian", "identity", "difference", "predefined_alternative",
  "duration_below_1_sleep_environment", 3L,
  "gaussian_log10_offset_0.1", "Gaussian, shifted-log scale",
  "gaussian", "log10_offset_0.1", "ratio",
  "positive_scale_alternative",
  "duration_below_10_pre_sleep", 1L,
  "tweedie_log_identity", "Tweedie, log link",
  "tweedie_log", "identity", "ratio", "current",
  "duration_below_10_pre_sleep", 2L,
  "gaussian_identity", "Gaussian, identity scale",
  "gaussian", "identity", "difference", "alternative",
  "duration_below_10_pre_sleep", 3L,
  "gaussian_log10_offset_0.1", "Gaussian, shifted-log scale",
  "gaussian", "log10_offset_0.1", "ratio",
  "positive_scale_alternative",
  "l10_mean_medi", 1L,
  "gaussian_log10_offset_0.1", "Gaussian, shifted-log scale",
  "gaussian", "log10_offset_0.1", "ratio", "current",
  "l10_mean_medi", 2L,
  "tweedie_log_identity", "Tweedie, log link",
  "tweedie_log", "identity", "ratio", "named_alternative",
  "l10_mean_medi", 3L,
  "gaussian_identity", "Gaussian, identity scale",
  "gaussian", "identity", "difference", "completeness_candidate"
)

input_contract <- h01_input_contract(root)
if (
  !identical(
    artifact_sha256(input_contract$main$manifest),
    input_contract$main$manifest_sha256
  ) ||
    !identical(
      artifact_sha256(input_contract$manuscript_prepared_data$manifest),
      input_contract$manuscript_prepared_data$manifest_sha256
    )
) {
  h01_abort("Pinned H01 manifests changed before candidate assessment")
}

objects <- list(
  main = readRDS(input_contract$main$path),
  manuscript_prepared_data = readRDS(
    input_contract$manuscript_prepared_data$path
  )
)
for (name in names(objects)) {
  metadata <- objects[[name]]$metadata
  if (
    !identical(metadata$data_scenario_id, name) ||
      !identical(
        metadata$model_implementation_id,
        input_contract$model_implementation_id
      ) ||
      !identical(
        metadata$implementation_contract_sha256,
        input_contract$implementation_contract_sha256
      ) ||
      !identical(
        metadata$shared_implementation_sha256,
        input_contract$shared_implementation_sha256
      )
  ) {
    h01_abort("H01 `%s` input identity differs from the approved gate", name)
  }
}

metric_registry <- h01_metric_registry()
h01_validate_registry(metric_registry)
display_registry <- objects$main$metric_contract |>
  dplyr::select(
    metric_order,
    metric_id,
    manuscript_name,
    abbreviation,
    manuscript_category,
    display_unit,
    variant_label,
    value_definition
  )
metric_registry <- dplyr::left_join(
  metric_registry,
  display_registry,
  by = c("metric_order", "metric_id"),
  relationship = "one-to-one"
)
run_registry <- h01_run_registry()

candidate_model_root <- file.path(
  root,
  "artifacts/07_models/H01/response_family_candidates"
)
candidate_diagnostic_root <- file.path(
  root,
  "artifacts/08_diagnostics/H01/response_family_candidates"
)
candidate_table_root <- file.path(
  root,
  "artifacts/09_tables/H01/response_family_candidates"
)
candidate_figure_root <- file.path(
  root,
  "artifacts/10_figures/H01/response_family_candidates"
)
candidate_source_root <- file.path(
  root,
  "artifacts/11_source_data/H01/response_family_candidates"
)
candidate_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_response_family_candidate_artifacts.csv"
)
invisible(vapply(
  c(
    candidate_model_root,
    candidate_diagnostic_root,
    candidate_table_root,
    candidate_figure_root,
    candidate_source_root,
    dirname(candidate_manifest_path)
  ),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

fit_contract_sha256 <- digest::digest(
  list(
    candidate_registry = candidate_registry,
    main_manifest = input_contract$main$manifest_sha256,
    manuscript_manifest =
      input_contract$manuscript_prepared_data$manifest_sha256,
    model_implementation_id = input_contract$model_implementation_id,
    h01_contract_sha256 = artifact_sha256(file.path(
      root,
      "scripts/hypotheses/H01/h01_contract.R"
    )),
    h01_modeling_sha256 = artifact_sha256(file.path(
      root,
      "scripts/hypotheses/H01/h01_modeling.R"
    ))
  ),
  algo = "sha256",
  serialize = TRUE
)
assessment_contract_sha256 <- digest::digest(
  list(
    fit_contract_sha256 = fit_contract_sha256,
    assessment_script_sha256 = artifact_sha256(file.path(root, producer)),
    protocol_sha256 = artifact_sha256(file.path(root, protocol))
  ),
  algo = "sha256",
  serialize = TRUE
)
legacy_fit_compatible_contracts <-
  "e0f5c456d1e7f39a77fb533491fe2669d7d9c87da922a5b95977d2c153038df8"

h01_candidate_spec <- function(candidate) {
  spec <- metric_registry[
    metric_registry$metric_id == candidate$metric_id,
    ,
    drop = FALSE
  ]
  if (nrow(spec) != 1L) {
    h01_abort("Unknown H01 candidate metric: %s", candidate$metric_id)
  }
  spec$response_family <- candidate$response_family
  spec$response_transform <- candidate$response_transform
  spec$effect_scale <- candidate$effect_scale
  spec$diagnostic_note <- paste(
    spec$diagnostic_note,
    "Candidate-family assessment",
    sep = "; "
  )
  spec
}

h01_candidate_identity <- function(run, candidate, spec) {
  tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    analytical_role = run$analytical_role,
    metric_order = spec$metric_order,
    metric_id = spec$metric_id,
    manuscript_name = spec$manuscript_name,
    candidate_order = candidate$candidate_order,
    candidate_id = candidate$candidate_id,
    candidate_label = candidate$candidate_label,
    candidate_role = candidate$candidate_role,
    response_family = spec$response_family,
    response_transform = spec$response_transform,
    effect_scale = spec$effect_scale
  )
}

h01_add_candidate_identity <- function(data, run, candidate, spec) {
  if (nrow(data) == 0L) {
    return(data)
  }
  identity <- h01_candidate_identity(run, candidate, spec)
  dplyr::bind_cols(identity[rep(1L, nrow(data)), , drop = FALSE], data)
}

h01_frame_row_sha256 <- function(frame) {
  digest::digest(
    as.character(frame$.model_row_id),
    algo = "sha256",
    serialize = TRUE
  )
}

h01_checkpoint_read <- function(path, expected_row_sha256) {
  if (!file.exists(path)) {
    return(NULL)
  }
  checkpoint <- readRDS(path)
  compatible_contract <- identical(
    checkpoint$fit_contract_sha256,
    fit_contract_sha256
  ) || checkpoint$contract_sha256 %in% legacy_fit_compatible_contracts
  if (
    !is.list(checkpoint) ||
      !isTRUE(compatible_contract) ||
      !identical(checkpoint$frame_row_sha256, expected_row_sha256)
  ) {
    h01_abort(
      "Stale H01 candidate checkpoint requires review: %s",
      substring(path, nchar(root) + 2L)
    )
  }
  checkpoint
}

h01_complete_bundle <- function(frame, spec, site_final_fit) {
  formulas <- h01_formula_set(spec$analysis_unit)
  comparison_names <- c(
    "site_full",
    "no_site",
    "no_photoperiod",
    "latitude_full",
    "random_site"
  )
  comparison <- stats::setNames(
    lapply(comparison_names, function(name) {
      if (
        name == "site_full" &&
          identical(spec$response_family, "tweedie_log")
      ) {
        return(site_final_fit)
      }
      h01_fit_model(
        frame,
        formulas[[name]],
        spec,
        estimation = "comparison"
      )
    }),
    comparison_names
  )
  final_names <- c(
    "site_full",
    "no_site",
    "no_photoperiod",
    "latitude_full"
  )
  if (identical(spec$response_family, "tweedie_log")) {
    final <- comparison[final_names]
  } else {
    final <- stats::setNames(
      lapply(final_names, function(name) {
        if (name == "site_full") {
          return(site_final_fit)
        }
        h01_fit_model(
          frame,
          formulas[[name]],
          spec,
          estimation = "final"
        )
      }),
      final_names
    )
  }
  list(
    spec = spec,
    formulas = formulas,
    comparison = comparison,
    final = final,
    frame_keys = frame$.model_row_id
  )
}

h01_bundle_fit_status <- function(bundle, run, candidate, spec) {
  rows <- list()
  index <- 1L
  for (stage_name in c("comparison", "final")) {
    for (model_name in names(bundle[[stage_name]])) {
      fit <- bundle[[stage_name]][[model_name]]
      status <- h01_model_fit_status(fit$model)
      rows[[index]] <- h01_add_candidate_identity(
        dplyr::bind_cols(
          tibble::tibble(
            estimation_stage = stage_name,
            model_name = model_name,
            formula = paste(
              deparse(bundle$formulas[[model_name]]),
              collapse = " "
            ),
            fitted = !is.null(fit$model),
            fit_error = fit$error,
            fit_warnings = paste(fit$warnings, collapse = " | ")
          ),
          status
        ),
        run,
        candidate,
        spec
      )
      index <- index + 1L
    }
  }
  dplyr::bind_rows(rows)
}

screen_rows <- list()
sample_rows <- list()
plot_rows <- list()
full_status_rows <- list()
screen_fits <- list()
screen_index <- 1L
sample_index <- 1L
plot_index <- 1L
full_status_index <- 1L

for (candidate_index in seq_len(nrow(candidate_registry))) {
  candidate <- candidate_registry[candidate_index, , drop = FALSE]
  spec <- h01_candidate_spec(candidate)
  message(
    "Screening H01 candidate: ",
    spec$metric_id,
    " / ",
    candidate$candidate_id
  )
  for (run_index in seq_len(nrow(run_registry))) {
    run <- run_registry[run_index, , drop = FALSE]
    object <- objects[[run$data_scenario_id]]
    frame <- h01_prepare_model_frame(
      object,
      spec,
      placement = run$placement,
      sample_scenario = run$sample_scenario
    )
    if (nrow(frame) == 0L) {
      h01_abort(
        "Candidate assessment unexpectedly found no rows for `%s` in `%s`",
        spec$metric_id,
        run$run_id
      )
    }
    canonical_frame_path <- file.path(
      root,
      "artifacts/07_models/H01",
      run$data_scenario_id,
      run$placement,
      run$sample_scenario,
      paste0(spec$metric_id, "_model_frame.rds")
    )
    canonical_bundle_path <- file.path(
      root,
      "artifacts/07_models/H01",
      run$data_scenario_id,
      run$placement,
      run$sample_scenario,
      paste0(spec$metric_id, "_models.rds")
    )
    canonical_frame <- readRDS(canonical_frame_path)
    if (!identical(frame$.model_row_id, canonical_frame$.model_row_id)) {
      h01_abort(
        "Candidate `%s` changed model rows for `%s` in `%s`",
        candidate$candidate_id,
        spec$metric_id,
        run$run_id
      )
    }
    frame_row_sha256 <- h01_frame_row_sha256(frame)
    key <- paste(spec$metric_id, candidate$candidate_id, run$run_id, sep = "::")
    is_current <- identical(candidate$candidate_role, "current")
    candidate_directory <- file.path(
      candidate_model_root,
      spec$metric_id,
      candidate$candidate_id,
      run$data_scenario_id,
      run$placement,
      run$sample_scenario
    )
    dir.create(candidate_directory, recursive = TRUE, showWarnings = FALSE)
    frame_path <- file.path(candidate_directory, "model_frame.rds")
    frame_csv_path <- file.path(candidate_directory, "model_frame.csv")
    screen_path <- file.path(candidate_directory, "screen_site_model.rds")
    full_path <- file.path(candidate_directory, "models.rds")

    if (is_current) {
      bundle <- readRDS(canonical_bundle_path)
      if (
        !identical(bundle$spec$response_family, spec$response_family) ||
          !identical(bundle$spec$response_transform, spec$response_transform)
      ) {
        h01_abort("Canonical current H01 specification changed unexpectedly")
      }
      site_fit <- bundle$final$site_full
      full_checkpoint <- list(
        fit_contract_sha256 = fit_contract_sha256,
        assessment_contract_sha256 = assessment_contract_sha256,
        frame_row_sha256 = frame_row_sha256,
        source = "canonical_completed_fit",
        canonical_bundle_path = substring(
          canonical_bundle_path,
          nchar(root) + 2L
        ),
        bundle = bundle
      )
    } else {
      write_rds_artifact(frame, frame_path, producer = producer)
      write_csv_artifact(
        frame |>
          dplyr::select(
            .model_row_id,
            site,
            participant_key,
            local_date,
            value,
            response_value,
            photoperiod_hours,
            photoperiod_centered_hours,
            latitude_deg,
            absolute_latitude_10deg_centered,
            metric_support_available,
            metric_support_valid_minutes,
            metric_support_expected_minutes
          ),
        frame_csv_path,
        producer = producer
      )
      checkpoint <- h01_checkpoint_read(screen_path, frame_row_sha256)
      if (is.null(checkpoint)) {
        formulas <- h01_formula_set(spec$analysis_unit)
        site_fit <- h01_fit_model(
          frame,
          formulas$site_full,
          spec,
          estimation = "final"
        )
        checkpoint <- list(
          fit_contract_sha256 = fit_contract_sha256,
          assessment_contract_sha256 = assessment_contract_sha256,
          frame_row_sha256 = frame_row_sha256,
          site_fit = site_fit
        )
        write_rds_artifact(checkpoint, screen_path, producer = producer)
      } else {
        site_fit <- checkpoint$site_fit
      }
      full_checkpoint <- h01_checkpoint_read(full_path, frame_row_sha256)
    }

    screen_bundle <- list(
      spec = spec,
      formulas = h01_formula_set(spec$analysis_unit),
      comparison = list(),
      final = list(site_full = site_fit),
      frame_keys = frame$.model_row_id
    )
    seed <- h01_primary_seed(
      spec$metric_order,
      run$data_scenario_id,
      run$placement,
      run$sample_scenario
    )
    diagnostic <- h01_model_diagnostics(screen_bundle, frame, seed)
    site_status <- h01_model_fit_status(site_fit$model)
    screen_rows[[screen_index]] <- h01_add_candidate_identity(
      dplyr::bind_cols(
        tibble::tibble(
          frame_row_sha256 = frame_row_sha256,
          site_model_fitted = !is.null(site_fit$model),
          site_fit_error = site_fit$error,
          site_fit_warnings = paste(site_fit$warnings, collapse = " | ")
        ),
        site_status,
        diagnostic |>
          dplyr::select(-converged, -positive_definite_hessian, -singular,
                        -max_gradient)
      ),
      run,
      candidate,
      spec
    )
    screen_index <- screen_index + 1L

    sample <- h01_sample_summary(frame, spec)$overall
    sample_rows[[sample_index]] <- h01_add_candidate_identity(
      dplyr::mutate(
        sample,
        frame_row_sha256 = frame_row_sha256,
        sample_status = "FITTED"
      ),
      run,
      candidate,
      spec
    )
    sample_index <- sample_index + 1L

    if (
      run$placement == "glasses" &&
        run$sample_scenario == "all_available" &&
        !is.null(site_fit$model)
    ) {
      plot_rows[[plot_index]] <- h01_add_candidate_identity(
        h01_diagnostic_plot_data(site_fit$model, frame),
        run,
        candidate,
        spec
      )
      plot_index <- plot_index + 1L
    }
    screen_fits[[key]] <- list(
      frame = frame,
      spec = spec,
      candidate = candidate,
      run = run,
      site_fit = site_fit,
      frame_row_sha256 = frame_row_sha256,
      full_checkpoint = full_checkpoint,
      full_path = full_path,
      is_current = is_current
    )
  }
}

screen <- dplyr::bind_rows(screen_rows) |>
  dplyr::mutate(
    primary_near_eye = placement == "glasses" &
      sample_scenario == "all_available",
    strong_residual_warning = startsWith(
      residual_status,
      "WARN_STRONG"
    ),
    ordinary_residual_warning = startsWith(
      residual_status,
      "WARN"
    ) & !strong_residual_warning,
    prediction_support_warning = startsWith(
      prediction_bound_status,
      "WARN"
    ),
    observed_support_failure = prediction_bound_status ==
      "FAIL_OBSERVED_SUPPORT",
    hard_screen_failure = !site_model_fitted |
      !is.na(site_fit_error) |
      !converged |
      !positive_definite_hessian |
      is.na(singular) |
      singular |
      diagnostic_status == "FAIL_MAJOR_GATE" |
      observed_support_failure
  )

screen_score <- screen |>
  dplyr::group_by(
    metric_order,
    metric_id,
    manuscript_name,
    candidate_order,
    candidate_id,
    candidate_label,
    candidate_role,
    response_family,
    response_transform,
    effect_scale
  ) |>
  dplyr::summarise(
    runs = dplyr::n(),
    hard_screen_failures = sum(hard_screen_failure),
    strong_residual_warning_runs = sum(strong_residual_warning),
    ordinary_residual_warning_runs = sum(ordinary_residual_warning),
    prediction_support_warning_runs = sum(prediction_support_warning),
    primary_prediction_support_warning_runs = sum(
      prediction_support_warning & primary_near_eye
    ),
    site_fit_warning_runs = sum(nzchar(site_fit_warnings)),
    diagnostic_pass_runs = sum(diagnostic_status == "PASS"),
    diagnostic_warn_runs = sum(diagnostic_status == "WARN_REVIEW"),
    good_common_screen = hard_screen_failures == 0L &
      strong_residual_warning_runs == 0L &
      primary_prediction_support_warning_runs == 0L,
    .groups = "drop"
  )

confirm_keys <- screen_score |>
  dplyr::filter(good_common_screen | candidate_role == "current") |>
  dplyr::transmute(key = paste(metric_id, candidate_id, sep = "::")) |>
  dplyr::pull(key)

for (key in names(screen_fits)) {
  entry <- screen_fits[[key]]
  candidate_key <- paste(
    entry$spec$metric_id,
    entry$candidate$candidate_id,
    sep = "::"
  )
  if (!candidate_key %in% confirm_keys) {
    next
  }
  full_checkpoint <- entry$full_checkpoint
  if (is.null(full_checkpoint)) {
    message("Confirming full H01 candidate: ", key)
    bundle <- h01_complete_bundle(
      entry$frame,
      entry$spec,
      entry$site_fit
    )
    full_checkpoint <- list(
      fit_contract_sha256 = fit_contract_sha256,
      assessment_contract_sha256 = assessment_contract_sha256,
      frame_row_sha256 = entry$frame_row_sha256,
      source = "candidate_assessment_fit",
      bundle = bundle
    )
    write_rds_artifact(
      full_checkpoint,
      entry$full_path,
      producer = producer
    )
  } else {
    bundle <- full_checkpoint$bundle
  }
  full_status_rows[[full_status_index]] <- h01_bundle_fit_status(
    bundle,
    entry$run,
    entry$candidate,
    entry$spec
  )
  full_status_index <- full_status_index + 1L
}

full_status <- dplyr::bind_rows(full_status_rows)
required_full_status <- full_status |>
  dplyr::filter(model_name != "random_site")
descriptive_full_score <- full_status |>
  dplyr::filter(model_name == "random_site") |>
  dplyr::group_by(metric_id, candidate_id) |>
  dplyr::summarise(
    random_site_model_rows = dplyr::n(),
    random_site_nonconverged_rows = sum(!converged),
    random_site_singular_or_unknown_rows = sum(is.na(singular) | singular),
    random_site_fit_warning_rows = sum(nzchar(fit_warnings)),
    .groups = "drop"
  )
full_score <- required_full_status |>
  dplyr::group_by(metric_id, candidate_id) |>
  dplyr::summarise(
    required_model_rows = dplyr::n(),
    fitted_model_rows = sum(fitted),
    fit_error_model_rows = sum(!is.na(fit_error)),
    nonconverged_model_rows = sum(!converged),
    nonpositive_hessian_model_rows = sum(!positive_definite_hessian),
    singular_or_unknown_model_rows = sum(is.na(singular) | singular),
    fit_warning_model_rows = sum(nzchar(fit_warnings)),
    full_fit_eligible = required_model_rows == 64L &
      fitted_model_rows == 64L &
      fit_error_model_rows == 0L &
      nonconverged_model_rows == 0L &
      nonpositive_hessian_model_rows == 0L &
      singular_or_unknown_model_rows == 0L,
    .groups = "drop"
  ) |>
  dplyr::left_join(
    descriptive_full_score,
    by = c("metric_id", "candidate_id")
  )

scorecard <- screen_score |>
  dplyr::left_join(
    full_score,
    by = c("metric_id", "candidate_id")
  ) |>
  dplyr::mutate(
    full_fit_confirmed = !is.na(required_model_rows),
    full_fit_eligible = dplyr::coalesce(full_fit_eligible, FALSE),
    fit_warning_model_rows = dplyr::coalesce(
      fit_warning_model_rows,
      NA_integer_
    ),
    eligible = good_common_screen & full_fit_eligible,
    common_diagnostic_status = dplyr::case_when(
      eligible ~ "GOOD_COMMON_DIAGNOSTICS",
      hard_screen_failures > 0L ~ "INELIGIBLE_HARD_FAILURE",
      strong_residual_warning_runs > 0L ~
        "INELIGIBLE_STRONG_RESIDUAL_WARNING",
      primary_prediction_support_warning_runs > 0L ~
        "INELIGIBLE_PRIMARY_PREDICTION_SUPPORT_WARNING",
      !full_fit_confirmed ~ "NOT_FULLY_CONFIRMED_AFTER_SCREEN",
      !full_fit_eligible ~ "INELIGIBLE_FULL_FIT_FAILURE",
      TRUE ~ "INELIGIBLE"
    )
  ) |>
  dplyr::arrange(metric_order, candidate_order)

h01_lexicographically_better <- function(candidate, reference) {
  candidate_values <- c(
    candidate$prediction_support_warning_runs,
    candidate$ordinary_residual_warning_runs,
    candidate$fit_warning_model_rows
  )
  reference_values <- c(
    reference$prediction_support_warning_runs,
    reference$ordinary_residual_warning_runs,
    reference$fit_warning_model_rows
  )
  for (index in seq_along(candidate_values)) {
    if (candidate_values[[index]] < reference_values[[index]]) {
      return(TRUE)
    }
    if (candidate_values[[index]] > reference_values[[index]]) {
      return(FALSE)
    }
  }
  FALSE
}

h01_select_candidate <- function(rows) {
  current <- rows[rows$candidate_role == "current", , drop = FALSE]
  if (nrow(current) != 1L) {
    h01_abort("H01 candidate scorecard must have one current row per metric")
  }
  eligible <- rows[rows$eligible, , drop = FALSE]
  if (nrow(eligible) == 0L) {
    selected <- current
    reason <- paste0(
      "Retained current: no candidate met the fixed good-common-diagnostics ",
      "and full-fit eligibility rule"
    )
  } else {
    eligible <- eligible[order(
      eligible$prediction_support_warning_runs,
      eligible$ordinary_residual_warning_runs,
      eligible$fit_warning_model_rows,
      eligible$candidate_order
    ), , drop = FALSE]
    best <- eligible[1L, , drop = FALSE]
    if (isTRUE(current$eligible)) {
      if (
        best$candidate_id != current$candidate_id &&
          h01_lexicographically_better(best, current)
      ) {
        selected <- best
        reason <- paste0(
          "Selected eligible alternative with a strictly better fixed ",
          "diagnostic profile than the current candidate"
        )
      } else {
        selected <- current
        reason <- paste0(
          "Retained current: no eligible alternative was strictly better ",
          "under the fixed diagnostic ordering"
        )
      }
    } else {
      selected <- best
      reason <- paste0(
        "Selected the highest-ranked eligible alternative because the ",
        "current candidate did not meet good common diagnostics"
      )
    }
  }
  tibble::tibble(
    metric_order = selected$metric_order,
    metric_id = selected$metric_id,
    manuscript_name = selected$manuscript_name,
    selected_candidate_id = selected$candidate_id,
    selected_candidate_label = selected$candidate_label,
    selected_response_family = selected$response_family,
    selected_response_transform = selected$response_transform,
    selected_effect_scale = selected$effect_scale,
    current_candidate_retained = selected$candidate_role == "current",
    selected_common_diagnostic_status =
      selected$common_diagnostic_status,
    selection_reason = reason,
    canonical_update_required = selected$candidate_role != "current"
  )
}

selection <- scorecard |>
  dplyr::group_split(metric_id) |>
  lapply(h01_select_candidate) |>
  dplyr::bind_rows() |>
  dplyr::arrange(metric_order)

sample_check <- dplyr::bind_rows(sample_rows) |>
  dplyr::group_by(metric_id, run_id) |>
  dplyr::summarise(
    candidates = dplyr::n(),
    distinct_row_hashes = dplyr::n_distinct(frame_row_sha256),
    distinct_participant_counts = dplyr::n_distinct(participants),
    distinct_participant_day_counts = dplyr::n_distinct(participant_days),
    distinct_observation_counts = dplyr::n_distinct(observations),
    sample_invariant = distinct_row_hashes == 1L &
      distinct_participant_counts == 1L &
      distinct_participant_day_counts == 1L &
      distinct_observation_counts == 1L,
    .groups = "drop"
  )
if (
  nrow(screen) != 72L ||
    nrow(scorecard) != 9L ||
    nrow(selection) != 3L ||
    !all(sample_check$sample_invariant)
) {
  h01_abort("H01 candidate assessment completeness checks failed")
}

status_source <- screen |>
  dplyr::mutate(
    run_label = paste(
      dplyr::recode(
        data_scenario_id,
        main = "Main",
        manuscript_prepared_data = "Manuscript-prepared"
      ),
      dplyr::recode(placement, glasses = "near eye", chest = "chest"),
      dplyr::recode(
        sample_scenario,
        all_available = "all available",
        paired_common_sample = "paired/common sample"
      ),
      sep = " — "
    ),
    status_label = dplyr::case_when(
      hard_screen_failure ~ "Major failure",
      strong_residual_warning ~ "Strong residual warning",
      prediction_support_warning ~ "Prediction support warning",
      ordinary_residual_warning ~ "Residual warning",
      nzchar(site_fit_warnings) ~ "Fit warning",
      TRUE ~ "Pass"
    ),
    status_symbol = dplyr::recode(
      status_label,
      "Pass" = "P",
      "Fit warning" = "F",
      "Residual warning" = "R",
      "Prediction support warning" = "B",
      "Strong residual warning" = "S",
      "Major failure" = "X"
    ),
    candidate_axis = paste(candidate_order, candidate_label, sep = "__")
  ) |>
  dplyr::select(
    metric_order,
    metric_id,
    manuscript_name,
    candidate_order,
    candidate_id,
    candidate_label,
    candidate_axis,
    run_id,
    run_label,
    status_label,
    status_symbol
  )

status_source$run_label <- factor(
  status_source$run_label,
  levels = rev(unique(status_source$run_label))
)
status_source$manuscript_name <- factor(
  status_source$manuscript_name,
  levels = unique(
    status_source$manuscript_name[order(status_source$metric_order)]
  )
)
status_source$candidate_axis <- factor(
  status_source$candidate_axis,
  levels = unique(status_source$candidate_axis[order(
    status_source$metric_order,
    status_source$candidate_order
  )])
)
status_source$status_label <- factor(
  status_source$status_label,
  levels = c(
    "Pass",
    "Fit warning",
    "Residual warning",
    "Prediction support warning",
    "Strong residual warning",
    "Major failure"
  )
)

status_plot <- ggplot2::ggplot(
  status_source,
  ggplot2::aes(
    x = candidate_axis,
    y = run_label,
    fill = status_label
  )
) +
  ggplot2::geom_tile(color = "white", linewidth = 0.5) +
  ggplot2::geom_text(
    ggplot2::aes(label = status_symbol),
    size = 3.2,
    fontface = "bold"
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(manuscript_name),
    scales = "free_x",
    ncol = 1
  ) +
  ggplot2::scale_fill_manual(
    values = c(
      "Pass" = "#E8F1EC",
      "Fit warning" = "#CCEBC5",
      "Residual warning" = "#FED9A6",
      "Prediction support warning" = "#FFFFCC",
      "Strong residual warning" = "#FBB4AE",
      "Major failure" = "#B2182B"
    ),
    drop = FALSE
  ) +
  ggplot2::scale_x_discrete(
    labels = function(value) sub("^[0-9]+__", "", value)
  ) +
  ggplot2::labs(
    x = NULL,
    y = NULL,
    fill = "Diagnostic classification"
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_text(angle = 20, hjust = 1),
    strip.text = ggplot2::element_text(face = "bold"),
    legend.position = "bottom"
  )

diagnostic_path <- file.path(
  candidate_diagnostic_root,
  "H01_response_family_candidate_diagnostics.csv"
)
scorecard_path <- file.path(
  candidate_table_root,
  "H01_response_family_candidate_scorecard.csv"
)
selection_path <- file.path(
  candidate_table_root,
  "H01_response_family_candidate_selection.csv"
)
sample_path <- file.path(
  candidate_table_root,
  "H01_response_family_candidate_samples.csv"
)
sample_check_path <- file.path(
  candidate_diagnostic_root,
  "H01_response_family_candidate_sample_invariance.csv"
)
full_status_path <- file.path(
  candidate_diagnostic_root,
  "H01_response_family_candidate_full_fit_status.csv"
)
plot_data_path <- file.path(
  candidate_source_root,
  "H01_response_family_primary_diagnostic_plot_data.csv"
)
status_source_path <- file.path(
  candidate_source_root,
  "H01_response_family_diagnostic_status_source.csv"
)
figure_path <- file.path(
  candidate_figure_root,
  "H01_response_family_diagnostic_status.png"
)
provenance_path <- file.path(
  candidate_diagnostic_root,
  "H01_response_family_candidate_provenance.csv"
)

write_csv_artifact(screen, diagnostic_path, producer = producer)
write_csv_artifact(scorecard, scorecard_path, producer = producer)
write_csv_artifact(selection, selection_path, producer = producer)
write_csv_artifact(
  dplyr::bind_rows(sample_rows),
  sample_path,
  producer = producer
)
write_csv_artifact(sample_check, sample_check_path, producer = producer)
write_csv_artifact(full_status, full_status_path, producer = producer)
write_csv_artifact(
  dplyr::bind_rows(plot_rows),
  plot_data_path,
  producer = producer
)
write_csv_artifact(
  tibble::as_tibble(status_source) |>
    dplyr::mutate(
      run_label = as.character(run_label),
      candidate_label = as.character(candidate_label),
      status_label = as.character(status_label)
    ),
  status_source_path,
  producer = producer
)
ggplot2::ggsave(
  filename = figure_path,
  plot = status_plot,
  width = 10,
  height = 11,
  units = "in",
  dpi = 180,
  bg = "white"
)

provenance <- tibble::tibble(
  fit_contract_sha256 = fit_contract_sha256,
  assessment_contract_sha256 = assessment_contract_sha256,
  r_version = as.character(getRversion()),
  lme4_version = as.character(utils::packageVersion("lme4")),
  glmmTMB_version = as.character(utils::packageVersion("glmmTMB")),
  DHARMa_version = as.character(utils::packageVersion("DHARMa")),
  performance_version = as.character(utils::packageVersion("performance")),
  digest_version = as.character(utils::packageVersion("digest")),
  main_input_manifest_sha256 = input_contract$main$manifest_sha256,
  manuscript_prepared_input_manifest_sha256 =
    input_contract$manuscript_prepared_data$manifest_sha256,
  renv_lock_sha256 = artifact_sha256(file.path(root, "renv.lock")),
  protocol_path = protocol,
  protocol_sha256 = artifact_sha256(file.path(root, protocol)),
  producer_path = producer,
  producer_sha256 = artifact_sha256(file.path(root, producer)),
  completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
write_csv_artifact(provenance, provenance_path, producer = producer)

manifest_roots <- c(
  candidate_model_root,
  candidate_diagnostic_root,
  candidate_table_root,
  candidate_figure_root,
  candidate_source_root
)
manifest_files <- sort(unique(c(
  unlist(lapply(
    manifest_roots,
    list.files,
    recursive = TRUE,
    full.names = TRUE
  )),
  file.path(root, producer),
  file.path(root, protocol),
  file.path(root, "scripts/hypotheses/H01/h01_contract.R"),
  file.path(root, "scripts/hypotheses/H01/h01_modeling.R"),
  input_contract$main$manifest,
  input_contract$manuscript_prepared_data$manifest,
  file.path(root, "renv.lock")
)))
manifest_files <- manifest_files[
  file.exists(manifest_files) & !dir.exists(manifest_files)
]
manifest <- dplyr::bind_rows(lapply(manifest_files, function(path) {
  info <- file.info(path)
  tibble::tibble(
    path = if (startsWith(path, paste0(root, "/"))) {
      substring(path, nchar(root) + 2L)
    } else {
      path
    },
    sha256 = artifact_sha256(path),
    bytes = as.numeric(info$size),
    producer = producer,
    r_version = as.character(getRversion()),
    candidate_fit_contract_sha256 = fit_contract_sha256,
    candidate_assessment_contract_sha256 = assessment_contract_sha256
  )
}))
write_csv_artifact(manifest, candidate_manifest_path, producer = producer)

message(
  "H01 response-family candidate assessment completed: ",
  paste(
    paste0(selection$metric_id, "=", selection$selected_candidate_id),
    collapse = "; "
  )
)
