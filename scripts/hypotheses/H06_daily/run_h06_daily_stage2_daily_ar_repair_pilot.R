# Run the bounded H06_daily non-MDER daily-family AR repair pilot.

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
  "dplyr", "tibble", "tidyr", "readr", "digest", "lme4", "glmmTMB",
  "performance", "melidosData"
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
  "scripts/hypotheses/H06_daily/h06_daily_daily_ar_repair.R"
))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06d_abort(
    "H06_daily AR repair pilot requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
if (!identical(as.character(utils::packageVersion("lme4")), "2.0.1")) {
  h06d_abort("H06_daily AR repair pilot requires lme4 2.0.1")
}
if (!identical(as.character(utils::packageVersion("glmmTMB")), "1.1.14")) {
  h06d_abort("H06_daily AR repair pilot requires glmmTMB 1.1.14")
}
if (!identical(as.character(utils::packageVersion("melidosData")), "1.0.6")) {
  h06d_abort("H06_daily AR repair pilot requires melidosData 1.0.6")
}

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "run_h06_daily_stage2_daily_ar_repair_pilot.R"
)
roots <- h06d_artifact_roots(root)
invisible(lapply(roots, dir.create, recursive = TRUE, showWarnings = FALSE))

write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}

write_rds <- function(object, path) {
  saveRDS(object, path, version = 3)
  invisible(path)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

input_contract <- tibble::tribble(
  ~input_id, ~relative_path, ~expected_sha256, ~role,
  "metric_manifest",
  "artifacts/12_manifests/metric_artifacts.csv",
  "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43",
  "current shared metric manifest after the MDER-only rebuild",
  "base_manifest",
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  "6cfbfb18a2f6b1e31613e3fba803c3fbf64eb63e37155ae4fffd437a213b3ad0",
  "current shared base-model-data manifest",
  "primary_near_eye_daily",
  "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
  "fb04a84f49a410f3474cc64ef97e91183db413197f5815f5dd83805a7d40b06e",
  "current near-eye participant-day source",
  "exercise_diary",
  "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
  "5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107",
  "immutable daily activity context",
  "sleep_diary",
  "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
  "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
  "immutable work/free and previous-night sleep context",
  "site_registry",
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "submitted site order",
  "frozen_daily_pilot_models",
  "artifacts/07_models/H06_daily/H06_daily_stage2_pilot_daily_models.rds",
  "338949fcaeff43156135b956c21ea53f726e011284e3ccb0a7ac2632c5c6e60d",
  "frozen pre-rebuild daily frames and independent models",
  "frozen_daily_pilot_diagnostics",
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_stage2_pilot_daily_diagnostics.csv"
  ),
  "788909932597058d71ac4c11e25542e1e9636254e9ac40958c0a966923284f93",
  "frozen independent-model diagnostic reference",
  "frozen_daily_pilot_effects",
  paste0(
    "artifacts/09_tables/H06_daily/",
    "H06_daily_stage2_pilot_effect_preview.csv"
  ),
  "0eed9fc3eab017922625062fa0764f74e7635ba7f69c72abcbd6091597699fef",
  "frozen engineering effect reference",
  "frozen_daily_pilot_input_manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_stage2_pilot_input_manifest.csv"
  ),
  "8751bbc8e3bb54756c80fb8297346fcc49f57d3b7a5c8aec70ddff44de656008",
  "historical pre-MDER-rebuild input pin",
  "approved_stage2_pilot_gate",
  "audit/hypotheses/H06_daily/02_stage2_pilot.qmd",
  "2610b5c8473c78ec0bc10d0a0b75373d1c2df0f17136bd9bd59df777611f95ca",
  "gate authorizing the two bounded daily AR repairs",
  "approved_mder_transition",
  "audit/hypotheses/H06_daily/H06_daily_mder_metric010_transition.md",
  "0f87412e2540ea0251301c5f90cfb871b0cf181454fbdd22c6b0e83b4ad9eb84",
  "gate closing the MDER hold before non-MDER work resumed"
) |>
  dplyr::mutate(
    observed_sha256 = vapply(
      file.path(.env$root, .data$relative_path),
      sha256,
      character(1)
    ),
    bytes = unname(file.info(
      file.path(.env$root, .data$relative_path)
    )$size),
    verified = .data$expected_sha256 == .data$observed_sha256
  )
if (!all(input_contract$verified)) {
  h06d_abort(
    "H06_daily AR repair input drift: %s",
    paste(input_contract$input_id[!input_contract$verified], collapse = ", ")
  )
}

registry <- tibble::tribble(
  ~repair_order, ~repair_id, ~metric_id, ~predictor_id,
  ~response_transform, ~checkpoint_key, ~effect_term,
  ~component, ~reader_metric, ~contrast, ~display_scale,
  ~lower_bound, ~upper_bound,
  1L, "pre_sleep_identity",
  "duration_below_10_pre_sleep",
  "previous_sleep_duration_centered_h",
  "identity",
  "gaussian_identity__fixed_site_additive",
  "previous_sleep_duration_centered_h",
  "one-part identity-Gaussian response",
  "Duration below 10 lx melEDI before sleep",
  "Per 1 h greater previous-night sleep duration",
  "absolute difference in hours",
  0, 6,
  2L, "l10_positive_magnitude",
  "l10_mean_medi",
  "work_free_day",
  "log10_positive",
  "l10_two_part__positive_magnitude",
  "work_free_dayFree day",
  "positive-magnitude component of the two-part response",
  "L10 mean melEDI",
  "Free day versus Work day among positive L10 days",
  "ratio of positive conditional geometric means",
  0, Inf
)

checkpoint <- readRDS(file.path(
  roots$models,
  "H06_daily_stage2_pilot_daily_models.rds"
))
diaries <- h06d_load_diaries(root)
l10_full_current <- h06d_daily_frame(
  root,
  placement = "near_eye",
  metric_id = "l10_mean_medi",
  predictor_id = "work_free_day",
  diaries = diaries
) |>
  h06d_prepare_daily_response("log10_offset_0.1")

current_frames <- list(
  pre_sleep_identity = h06d_daily_frame(
    root,
    placement = "near_eye",
    metric_id = "duration_below_10_pre_sleep",
    predictor_id = "previous_sleep_duration_centered_h",
    diaries = diaries
  ) |>
    h06d_prepare_daily_response("identity"),
  l10_positive_magnitude = l10_full_current |>
    dplyr::filter(.data$response_source > 0) |>
    dplyr::mutate(response_value = log10(.data$response_source)) |>
    droplevels()
)

frame_equivalence <- lapply(seq_len(nrow(registry)), function(index) {
  entry <- registry[index, ]
  old <- checkpoint[[entry$checkpoint_key[[1L]]]]$frame
  current <- current_frames[[entry$repair_id[[1L]]]]
  h06d_ar_frame_equivalence(old, current, entry$repair_id[[1L]])
}) |>
  dplyr::bind_rows() |>
  dplyr::left_join(
    dplyr::select(registry, "repair_order", "repair_id"),
    by = "repair_id",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(.data$repair_order)
if (!all(frame_equivalence$equivalence_pass)) {
  h06d_abort("A current non-MDER repair frame differs from its frozen pilot frame")
}

sequenced_frames <- lapply(current_frames, h06d_ar_add_day_sequences)
if (any(sequenced_frames$l10_positive_magnitude$response_source <= 0)) {
  h06d_abort("The positive L10 AR component contains a nonpositive outcome")
}
if (
  any(sequenced_frames$pre_sleep_identity$response_source < 0) ||
    any(sequenced_frames$pre_sleep_identity$response_source > 6)
) {
  h06d_abort("The pre-sleep AR response violates its 0-6 h source bound")
}

l10_zero_mass_audit <- tibble::tibble(
  participant_days = nrow(l10_full_current),
  exact_zeros = sum(l10_full_current$response_source == 0),
  exact_zero_fraction = mean(l10_full_current$response_source == 0),
  positive_values_at_or_below_1e_12 = sum(
    l10_full_current$response_source > 0 &
      l10_full_current$response_source <= 1e-12
  ),
  values_at_or_below_1e_12 = sum(
    l10_full_current$response_source <= 1e-12
  ),
  at_or_below_1e_12_fraction = mean(
    l10_full_current$response_source <= 1e-12
  ),
  positive_component_rows = sum(l10_full_current$response_source > 0),
  positive_component_minimum_lx = min(
    l10_full_current$response_source[l10_full_current$response_source > 0]
  ),
  positive_component_minimum_log10 = min(
    log10(l10_full_current$response_source[
      l10_full_current$response_source > 0
    ])
  ),
  audit_interpretation = paste0(
    "Exact-zero splitting retains three numerically near-zero positive values; ",
    "no local threshold or repair was applied."
  )
)
l10_numerically_near_zero <- l10_full_current |>
  dplyr::filter(
    .data$response_source > 0,
    .data$response_source <= 1e-12
  ) |>
  dplyr::transmute(
    site = as.character(.data$site),
    Id = .data$Id,
    local_date = .data$local_date,
    l10_mean_medi_lx = .data$response_source,
    log10_l10_mean_medi = log10(.data$response_source),
    work_free_day = as.character(.data$work_free_day),
    participant_day_key = .data$participant_day_key,
    disposition = paste0(
      "retained unchanged as positive under the exact-zero pilot contract; ",
      "upstream classification decision required"
    )
  ) |>
  dplyr::arrange(.data$site, .data$Id, .data$local_date)
if (nrow(l10_numerically_near_zero) != 3L) {
  h06d_abort("Unexpected L10 numerically near-zero row count")
}

support <- lapply(seq_len(nrow(registry)), function(index) {
  entry <- registry[index, ]
  frame <- sequenced_frames[[entry$repair_id[[1L]]]]
  h06d_ar_sequence_support(frame) |>
    dplyr::mutate(
      repair_order = entry$repair_order[[1L]],
      repair_id = entry$repair_id[[1L]],
      metric_id = entry$metric_id[[1L]],
      predictor_id = entry$predictor_id[[1L]],
      .before = 1L
    )
}) |>
  dplyr::bind_rows() |>
  dplyr::arrange(.data$repair_order)
if (!all(support$support_pass)) {
  h06d_abort("A daily AR repair frame lacks prespecified sequence support")
}

frame_paths <- c(
  pre_sleep_identity = file.path(
    roots$model_data,
    "H06_daily_stage2_daily_ar_repair__pre_sleep_identity__frame.rds"
  ),
  l10_positive_magnitude = file.path(
    roots$model_data,
    "H06_daily_stage2_daily_ar_repair__l10_positive_magnitude__frame.rds"
  )
)
for (repair_id in names(frame_paths)) {
  write_rds(sequenced_frames[[repair_id]], frame_paths[[repair_id]])
}
frame_registry <- registry |>
  dplyr::left_join(support, by = c(
    "repair_order", "repair_id", "metric_id", "predictor_id"
  )) |>
  dplyr::mutate(
    frame_relative_path = sub(
      paste0("^", .env$root, "/"),
      "",
      unname(frame_paths[.data$repair_id])
    ),
    frame_sha256 = vapply(unname(frame_paths[.data$repair_id]), sha256, character(1)),
    exact_zero_fraction = vapply(
      .data$repair_id,
      function(id) mean(sequenced_frames[[id]]$response_source == 0),
      numeric(1)
    )
  )

fits <- list()
effect_rows <- list()
diagnostic_rows <- list()
site_lag_rows <- list()
runtime_rows <- list()

baseline_status <- function(model, warnings = character()) {
  status <- h06d_model_status(model)
  table <- h06d_ar_fixed_table(model)
  status |>
    dplyr::mutate(
      finite_fixed_effects = all(is.finite(table$estimate)),
      finite_standard_errors = all(is.finite(table$standard_error)),
      warning_count = length(warnings),
      warnings = paste(warnings, collapse = " | ")
    )
}

for (index in seq_len(nrow(registry))) {
  entry <- registry[index, ]
  repair_id <- entry$repair_id[[1L]]
  frame <- sequenced_frames[[repair_id]]
  old_entry <- checkpoint[[entry$checkpoint_key[[1L]]]]
  old_frame <- old_entry$frame
  baseline <- old_entry$model
  independent_formula <- h06d_ar_formula(
    entry$predictor_id[[1L]],
    ar = FALSE
  )
  ar_formula <- h06d_ar_formula(
    entry$predictor_id[[1L]],
    ar = TRUE
  )

  message("Daily AR repair: ", repair_id, " / independent glmmTMB")
  independent_fit <- h06d_ar_fit_gaussian(
    frame,
    independent_formula,
    REML = TRUE
  )
  message("Daily AR repair: ", repair_id, " / gap-aware AR glmmTMB")
  ar_fit <- h06d_ar_fit_gaussian(frame, ar_formula, REML = TRUE)
  if (is.null(independent_fit$value) || is.null(ar_fit$value)) {
    h06d_abort(
      "A daily AR repair fit failed for `%s`: independent=%s; AR=%s",
      repair_id,
      independent_fit$error,
      ar_fit$error
    )
  }

  model_set <- list(
    frozen_lmer_independent = list(
      model = baseline,
      frame = old_frame,
      fit = NULL,
      formula = old_entry$formula
    ),
    glmmTMB_independent = list(
      model = independent_fit$value,
      frame = frame,
      fit = independent_fit,
      formula = independent_formula
    ),
    glmmTMB_gap_aware_ar1 = list(
      model = ar_fit$value,
      frame = frame,
      fit = ar_fit,
      formula = ar_formula
    )
  )

  baseline_effect <- h06d_ar_effect_row(
    baseline,
    entry$effect_term[[1L]],
    entry$response_transform[[1L]]
  )

  for (model_id in names(model_set)) {
    model_entry <- model_set[[model_id]]
    model <- model_entry$model
    model_frame <- model_entry$frame
    status <- if (model_id == "frozen_lmer_independent") {
      baseline_status(model, old_entry$warnings %||% character())
    } else {
      h06d_ar_model_status(model, model_entry$fit)
    }
    parameters <- if (model_id == "glmmTMB_gap_aware_ar1") {
      h06d_ar_parameters(model)
    } else {
      tibble::tibble(
        ar_standard_deviation = NA_real_,
        ar_rho = NA_real_,
        participant_standard_deviation = if (inherits(model, "merMod")) {
          unname(attr(lme4::VarCorr(model)$participant_key, "stddev")[[1L]])
        } else {
          unname(attr(
            glmmTMB::VarCorr(model)$cond$participant_key,
            "stddev"
          )[[1L]])
        },
        residual_standard_deviation = stats::sigma(model)
      )
    }
    residual_diagnostic <- h06d_ar_residual_diagnostics(
      model,
      model_frame,
      entry$response_transform[[1L]],
      entry$lower_bound[[1L]],
      entry$upper_bound[[1L]]
    )
    residual <- as.numeric(stats::residuals(model))
    lag <- h06d_ar_lag_screen(model_frame, residual)
    effect <- h06d_ar_effect_row(
      model,
      entry$effect_term[[1L]],
      entry$response_transform[[1L]]
    ) |>
      dplyr::mutate(
        repair_order = entry$repair_order[[1L]],
        repair_id = repair_id,
        metric_id = entry$metric_id[[1L]],
        predictor_id = entry$predictor_id[[1L]],
        component = entry$component[[1L]],
        reader_metric = entry$reader_metric[[1L]],
        contrast = entry$contrast[[1L]],
        display_scale = entry$display_scale[[1L]],
        model_id = model_id,
        effect_shift_in_frozen_lmer_se = abs(
          .data$estimate - baseline_effect$estimate[[1L]]
        ) / baseline_effect$standard_error[[1L]],
        direction_matches_frozen_lmer = sign(.data$estimate) ==
          sign(baseline_effect$estimate[[1L]]),
        pilot_role = "engineering family repair; no association claim",
        .before = 1L
      )
    effect_rows[[paste(repair_id, model_id, sep = "__")]] <- effect

    diagnostic_rows[[paste(repair_id, model_id, sep = "__")]] <-
      dplyr::bind_cols(
        tibble::tibble(
          repair_order = entry$repair_order[[1L]],
          repair_id = repair_id,
          metric_id = entry$metric_id[[1L]],
          predictor_id = entry$predictor_id[[1L]],
          model_id = model_id,
          observations = nrow(model_frame),
          participants = dplyr::n_distinct(model_frame$participant_key),
          sites = dplyr::n_distinct(model_frame$site),
          formula = paste(deparse(model_entry$formula), collapse = " ")
        ),
        status,
        parameters,
        residual_diagnostic,
        lag$overall |>
          dplyr::rename(
            true_adjacent_pairs = "adjacent_pairs",
            participants_with_true_adjacent_pair =
              "participants_with_adjacent_pair",
            true_date_residual_lag1 = "residual_lag1",
            maximum_absolute_site_residual_lag1 =
              "maximum_absolute_site_lag1",
            residual_temporal_threshold_pass = "temporal_threshold_pass"
          )
      )

    site_lag_rows[[paste(repair_id, model_id, sep = "__")]] <-
      lag$by_site |>
      dplyr::mutate(
        repair_order = entry$repair_order[[1L]],
        repair_id = repair_id,
        model_id = model_id,
        .before = 1L
      )
  }

  runtime_rows[[repair_id]] <- tibble::tibble(
    repair_order = entry$repair_order[[1L]],
    repair_id = repair_id,
    independent_fit_seconds = independent_fit$elapsed_seconds,
    ar_fit_seconds = ar_fit$elapsed_seconds,
    two_fit_seconds = independent_fit$elapsed_seconds + ar_fit$elapsed_seconds
  )
  fits[[repair_id]] <- list(
    registry = entry,
    frame = frame,
    frozen_lmer_independent = baseline,
    glmmTMB_independent = independent_fit$value,
    glmmTMB_gap_aware_ar1 = ar_fit$value,
    independent_formula = independent_formula,
    ar_formula = ar_formula,
    independent_warnings = independent_fit$warnings,
    ar_warnings = ar_fit$warnings
  )
}

effects <- dplyr::bind_rows(effect_rows) |>
  dplyr::arrange(.data$repair_order, match(
    .data$model_id,
    c(
      "frozen_lmer_independent",
      "glmmTMB_independent",
      "glmmTMB_gap_aware_ar1"
    )
  ))
diagnostics <- dplyr::bind_rows(diagnostic_rows) |>
  dplyr::arrange(.data$repair_order, match(
    .data$model_id,
    c(
      "frozen_lmer_independent",
      "glmmTMB_independent",
      "glmmTMB_gap_aware_ar1"
    )
  ))
site_lag <- dplyr::bind_rows(site_lag_rows) |>
  dplyr::arrange(.data$repair_order, .data$model_id, .data$site)
fit_runtime <- dplyr::bind_rows(runtime_rows) |>
  dplyr::arrange(.data$repair_order)

verdict_rows <- list()
for (index in seq_len(nrow(registry))) {
  entry <- registry[index, ]
  repair_id <- entry$repair_id[[1L]]
  equivalence <- dplyr::filter(
    frame_equivalence,
    .data$repair_id == .env$repair_id
  )
  support_row <- dplyr::filter(support, .data$repair_id == .env$repair_id)
  baseline_diag <- diagnostics |>
    dplyr::filter(
      .data$repair_id == .env$repair_id,
      .data$model_id == "frozen_lmer_independent"
    )
  ar_diag <- diagnostics |>
    dplyr::filter(
      .data$repair_id == .env$repair_id,
      .data$model_id == "glmmTMB_gap_aware_ar1"
    )
  ar_effect <- effects |>
    dplyr::filter(
      .data$repair_id == .env$repair_id,
      .data$model_id == "glmmTMB_gap_aware_ar1"
    )

  checks <- tibble::tribble(
    ~domain, ~passed, ~rule, ~observed,
    "Current-versus-frozen frame",
    equivalence$equivalence_pass[[1L]],
    "same participant-days, values, columns, and factor levels",
    sprintf(
      "%d current rows; differing value columns: %s",
      equivalence$current_rows[[1L]],
      ifelse(
        nzchar(equivalence$differing_value_columns[[1L]]),
        equivalence$differing_value_columns[[1L]],
        "none"
      )
    ),
    "Sequence support",
    support_row$support_pass[[1L]],
    ">=100 true adjacent pairs and >=20 participants with adjacency",
    sprintf(
      "%d pairs; %d participants",
      support_row$adjacent_pairs[[1L]],
      support_row$participants_with_adjacent_pair[[1L]]
    ),
    "Independent-model AR trigger",
    !baseline_diag$residual_temporal_threshold_pass[[1L]],
    "pooled |lag-1| >=0.20 or any site |lag-1| >=0.30",
    sprintf(
      "pooled %.3f; site maximum %.3f",
      baseline_diag$true_date_residual_lag1[[1L]],
      baseline_diag$maximum_absolute_site_residual_lag1[[1L]]
    ),
    "AR numerical fit",
    ar_diag$converged[[1L]] &&
      ar_diag$positive_definite_hessian[[1L]] &&
      ar_diag$finite_fixed_effects[[1L]] &&
      ar_diag$finite_standard_errors[[1L]],
    "convergence code 0, positive-definite Hessian, finite estimates and SEs",
    sprintf(
      "converged=%s; PD Hessian=%s; warnings=%d",
      ar_diag$converged[[1L]],
      ar_diag$positive_definite_hessian[[1L]],
      ar_diag$warning_count[[1L]]
    ),
    "AR structured-covariance singularity",
    isFALSE(ar_diag$singular[[1L]]),
    "required participant/AR covariance structure is not singular",
    sprintf(
      "singular flag=%s; participant SD=%.4f; AR SD=%.4f",
      ar_diag$singular[[1L]],
      ar_diag$participant_standard_deviation[[1L]],
      ar_diag$ar_standard_deviation[[1L]]
    ),
    "AR coefficient",
    is.finite(ar_diag$ar_rho[[1L]]) && abs(ar_diag$ar_rho[[1L]]) < 0.95,
    "finite |rho| <0.95",
    sprintf("rho=%.3f", ar_diag$ar_rho[[1L]]),
    "Effect stability",
    ar_effect$effect_shift_in_frozen_lmer_se[[1L]] < 1 &&
      ar_effect$direction_matches_frozen_lmer[[1L]],
    "same direction and <1 frozen-model SE shift",
    sprintf(
      "shift=%.3f SE; direction match=%s",
      ar_effect$effect_shift_in_frozen_lmer_se[[1L]],
      ar_effect$direction_matches_frozen_lmer[[1L]]
    ),
    "Residual temporal dependence after AR",
    ar_diag$residual_temporal_threshold_pass[[1L]],
    "pooled |lag-1| <0.20 and every site |lag-1| <0.30",
    sprintf(
      "pooled %.3f; site maximum %.3f",
      ar_diag$true_date_residual_lag1[[1L]],
      ar_diag$maximum_absolute_site_residual_lag1[[1L]]
    ),
    "Gaussian residual distribution",
    ar_diag$distribution_pass[[1L]],
    "Q-Q >=0.95, |spread Spearman| <0.20, and <1% residuals exceed |4|",
    sprintf(
      "Q-Q %.3f; spread %.3f; >|4| %.3f",
      ar_diag$residual_qq_correlation[[1L]],
      ar_diag$absolute_residual_fitted_spearman[[1L]],
      ar_diag$standardized_residual_gt4_fraction[[1L]]
    ),
    "Physical predictions",
    ar_diag$bounds_pass[[1L]],
    "no more than 1% of conditional or marginal predictions outside bounds by >0.05 units",
    sprintf(
      "conditional %.3f; marginal %.3f violation fraction",
      ar_diag$conditional_bound_violation_fraction[[1L]],
      ar_diag$marginal_bound_violation_fraction[[1L]]
    )
  ) |>
    dplyr::mutate(
      repair_order = entry$repair_order[[1L]],
      repair_id = repair_id,
      metric_id = entry$metric_id[[1L]],
      predictor_id = entry$predictor_id[[1L]],
      verdict = ifelse(.data$passed, "ACCEPTABLE", "NOT_ACCEPTABLE"),
      .before = 1L
    )

  overall_pass <- all(checks$passed)
  overall <- tibble::tibble(
    repair_order = entry$repair_order[[1L]],
    repair_id = repair_id,
    metric_id = entry$metric_id[[1L]],
    predictor_id = entry$predictor_id[[1L]],
    domain = "Overall repair gate",
    passed = overall_pass,
    rule = "every prespecified frame, support, numerical, covariance, temporal, distributional, stability, and bounds check passes",
    observed = if (overall_pass) {
      "all domains acceptable"
    } else {
      paste(checks$domain[!checks$passed], collapse = " | ")
    },
    verdict = ifelse(overall_pass, "ACCEPTABLE", "NOT_ACCEPTABLE")
  )
  verdict_rows[[repair_id]] <- dplyr::bind_rows(checks, overall)
}
verdict <- dplyr::bind_rows(verdict_rows) |>
  dplyr::arrange(.data$repair_order, .data$domain == "Overall repair gate")

old_runtime <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_stage2_pilot_runtime_projection.csv"
  ),
  show_col_types = FALSE
)
old_near_eye_seconds <- old_runtime |>
  dplyr::filter(.data$component == "Daily near-eye primary hierarchy") |>
  dplyr::pull("observed_or_projected_seconds")
median_ar_seconds <- stats::median(fit_runtime$ar_fit_seconds)
remaining_base_seconds <- old_near_eye_seconds * 14 / 15
remaining_ar_upper_seconds <- 14 * 3 * median_ar_seconds
runtime_projection <- dplyr::bind_rows(
  fit_runtime |>
    dplyr::transmute(
      component = paste0("Repair fit: ", .data$repair_id),
      scope = "one independent glmmTMB calibration plus one gap-aware AR fit",
      fit_units = 2L,
      observed_or_projected_seconds = .data$two_fit_seconds,
      basis = "measured elapsed model-fitting time",
      interpretation = "completed bounded repair"
    ),
  tibble::tribble(
    ~component, ~scope, ~fit_units, ~observed_or_projected_seconds,
    ~basis, ~interpretation,
    "Remaining non-MDER near-eye primary base hierarchy",
    "14 metrics x 3 predictors x four declared non-AR formula roles",
    168L,
    remaining_base_seconds,
    "14/15 of the frozen family-specific 180-fit projection",
    "model fitting only; excludes deletion diagnostics",
    "Conditional near-eye AR upper bound",
    "one additive AR counterpart for every remaining metric-predictor frame",
    42L,
    remaining_ar_upper_seconds,
    "42 times the median measured repair AR fit",
    "conservative trigger upper bound; AR fits only when required",
    "Six-scenario daily fit-only planning envelope",
    "near-eye/chest all available, paired/common near-eye/chest, and gap comparators",
    6L * (168L + 42L),
    1.5 * 6 * (remaining_base_seconds + remaining_ar_upper_seconds),
    "six times the near-eye fit projection with a 50% size/overhead allowance",
    "planning estimate only; exact scenario frames precede production",
    "Deletion diagnostics and resampling",
    "accepted production models only",
    NA_integer_,
    NA_real_,
    "not run in this pilot",
    "requires its own bounded 50/100-deletion or replicate pilot"
  )
)

model_checkpoint <- list(
  fits = fits,
  registry = registry,
  frame_equivalence = frame_equivalence,
  support = support,
  l10_zero_mass_audit = l10_zero_mass_audit,
  l10_numerically_near_zero = l10_numerically_near_zero,
  effects = effects,
  diagnostics = diagnostics,
  verdict = verdict,
  input_contract = input_contract,
  r_version = as.character(getRversion()),
  package_versions = vapply(
    required_packages,
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
)

model_path <- file.path(
  roots$models,
  "H06_daily_stage2_daily_ar_repair_pilot_models.rds"
)
frame_registry_path <- file.path(
  roots$model_data,
  "H06_daily_stage2_daily_ar_repair_pilot_frame_registry.csv"
)
equivalence_path <- file.path(
  roots$diagnostics,
  "H06_daily_stage2_daily_ar_repair_pilot_frame_equivalence.csv"
)
support_path <- file.path(
  roots$diagnostics,
  "H06_daily_stage2_daily_ar_repair_pilot_support.csv"
)
diagnostic_path <- file.path(
  roots$diagnostics,
  "H06_daily_stage2_daily_ar_repair_pilot_model_diagnostics.csv"
)
site_lag_path <- file.path(
  roots$diagnostics,
  "H06_daily_stage2_daily_ar_repair_pilot_site_residual_lag.csv"
)
verdict_path <- file.path(
  roots$diagnostics,
  "H06_daily_stage2_daily_ar_repair_pilot_verdict.csv"
)
runtime_path <- file.path(
  roots$diagnostics,
  "H06_daily_stage2_daily_ar_repair_pilot_runtime.csv"
)
l10_zero_mass_path <- file.path(
  roots$diagnostics,
  "H06_daily_stage2_daily_ar_repair_pilot_l10_zero_mass_audit.csv"
)
l10_near_zero_path <- file.path(
  roots$diagnostics,
  "H06_daily_stage2_daily_ar_repair_pilot_l10_near_zero_rows.csv"
)
effect_path <- file.path(
  roots$tables,
  "H06_daily_stage2_daily_ar_repair_pilot_effect_stability.csv"
)
input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_stage2_daily_ar_repair_pilot_input_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_stage2_daily_ar_repair_pilot_software_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_stage2_daily_ar_repair_pilot_code_manifest.csv"
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_stage2_daily_ar_repair_pilot_output_manifest.csv"
)

write_rds(model_checkpoint, model_path)
write_csv(frame_registry, frame_registry_path)
write_csv(frame_equivalence, equivalence_path)
write_csv(support, support_path)
write_csv(diagnostics, diagnostic_path)
write_csv(site_lag, site_lag_path)
write_csv(verdict, verdict_path)
write_csv(runtime_projection, runtime_path)
write_csv(l10_zero_mass_audit, l10_zero_mass_path)
write_csv(l10_numerically_near_zero, l10_near_zero_path)
write_csv(effects, effect_path)
write_csv(input_contract, input_manifest_path)

software_manifest <- tibble::tibble(
  item = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  role = c(
    "authoritative computation",
    rep("synchronized project library", length(required_packages))
  )
)
write_csv(software_manifest, software_manifest_path)

code_paths <- c(
  producer,
  "scripts/hypotheses/H06_daily/h06_daily_daily_ar_repair.R",
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_modeling.R"
)
code_manifest <- tibble::tibble(
  relative_path = code_paths,
  sha256 = vapply(file.path(root, code_paths), sha256, character(1)),
  bytes = unname(file.info(file.path(root, code_paths))$size),
  role = c(
    "executed repair pilot",
    "daily AR repair helpers",
    "daily metric and predictor contracts",
    "daily frame construction",
    "frozen independent-model helpers"
  )
)
write_csv(code_manifest, code_manifest_path)

output_paths <- c(
  model_path,
  unname(frame_paths),
  frame_registry_path,
  equivalence_path,
  support_path,
  diagnostic_path,
  site_lag_path,
  verdict_path,
  runtime_path,
  l10_zero_mass_path,
  l10_near_zero_path,
  effect_path,
  input_manifest_path,
  software_manifest_path,
  code_manifest_path
)
output_manifest <- tibble::tibble(
  relative_path = sub(paste0("^", root, "/"), "", output_paths),
  sha256 = vapply(output_paths, sha256, character(1)),
  bytes = unname(file.info(output_paths)$size),
  producer = producer,
  r_version = as.character(getRversion()),
  written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
write_csv(output_manifest, output_manifest_path)

overall <- verdict |>
  dplyr::filter(.data$domain == "Overall repair gate") |>
  dplyr::select("repair_id", "verdict")
message(
  "H06_daily bounded daily AR repair pilot complete: ",
  paste(paste(overall$repair_id, overall$verdict, sep = "="), collapse = "; "),
  "; no bootstrap, simulation, deletion batch, or production grid run"
)
