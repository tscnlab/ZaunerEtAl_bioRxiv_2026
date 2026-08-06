#!/usr/bin/env Rscript

# Fit the author-approved H11 activity-context sensitivity. The accepted
# all-available H11 models are read-only inputs and remain the primary result.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(gratia)
  library(mgcv)
  library(readr)
  library(tibble)
  library(tidyr)
})

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_modeling.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_dominance.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_stage1.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_stage2.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_activity_context.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h11_activity_abort(
    "H11 activity sensitivity requires R 4.6.1; running %s",
    getRversion()
  )
}
if (
  as.character(utils::packageVersion("mgcv")) != "1.9.4" ||
    as.character(utils::packageVersion("gratia")) != "0.11.2"
) {
  h11_activity_abort("H11 activity-sensitivity package versions changed")
}

paths <- h11_activity_paths(root)
h11_activity_create_directories(paths)
producer <- "scripts/hypotheses/H11/run_h11_activity_context.R"

write_activity_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}

relative_path <- function(path) {
  sub(paste0("^", root, "/"), "", normalizePath(
    path,
    winslash = "/",
    mustWork = TRUE
  ))
}

message("Validating author decision and immutable inputs")
decision_path <- file.path(
  root,
  "audit/hypotheses/H11/04_activity_context_amendment.md"
)
decision_text <- paste(readLines(decision_path, warn = FALSE), collapse = "\n")
required_decision_tokens <- c(
  "Status: **author approved for implementation**",
  "exact activity-complete",
  "activity-adjusted model",
  "LightLogR::symlog_trans",
  "not a causal mediation"
)
if (!all(vapply(
  required_decision_tokens,
  grepl,
  logical(1),
  x = decision_text,
  fixed = TRUE
))) {
  h11_activity_abort("The activity-context author decision is incomplete")
}

registry <- tibble::tribble(
  ~run_id, ~placement, ~analytical_role, ~accepted_frame_relative_path,
  "activity_context__glasses", "glasses", "primary near-eye sensitivity",
  "artifacts/06_model_data/H11/stage2/main__glasses__all_available__frame.rds",
  "activity_context__chest", "chest", "complementary chest sensitivity",
  "artifacts/06_model_data/H11/stage2/main__chest__all_available__frame.rds"
) |>
  dplyr::mutate(
    accepted_frame_path = file.path(root, .data$accepted_frame_relative_path)
  )

required_inputs <- c(
  file.path(root, registry$accepted_frame_relative_path),
  file.path(
    root,
    "artifacts/06_model_data/normalized_inputs/lightexposurediary.rds"
  ),
  decision_path,
  file.path(root, "scripts/hypotheses/H11/h11_stage2.R"),
  file.path(root, "scripts/hypotheses/H02/h02_modeling.R")
)
if (!all(file.exists(required_inputs))) {
  h11_activity_abort("An H11 activity-sensitivity input is missing")
}
input_provenance <- tibble::tibble(
  relative_path = vapply(required_inputs, relative_path, character(1)),
  sha256 = vapply(
    required_inputs,
    digest::digest,
    character(1),
    algo = "sha256",
    file = TRUE
  ),
  role = c(
    "accepted near-eye H11 frame",
    "accepted chest H11 frame",
    "normalized hourly activity diary",
    "author-approved activity amendment",
    "accepted H11 robust-inference implementation",
    "accepted H02 fitting and AR implementation"
  )
)
write_activity_csv(
  input_provenance,
  file.path(paths$model_data, "input_provenance.csv")
)

environment_record <- tibble::tibble(
  completed_at = format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE),
  R_version = as.character(getRversion()),
  platform = R.version$platform,
  mgcv_version = as.character(utils::packageVersion("mgcv")),
  gratia_version = as.character(utils::packageVersion("gratia")),
  dplyr_version = as.character(utils::packageVersion("dplyr")),
  readr_version = as.character(utils::packageVersion("readr")),
  producer = producer
)
write_activity_csv(
  environment_record,
  file.path(paths$model_data, "environment.csv")
)

message("Preparing exact activity-complete common samples")
diary_path <- file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/lightexposurediary.rds"
)
diary <- h11_activity_prepare_diary(readRDS(diary_path))
write_activity_csv(
  diary$audit,
  file.path(paths$model_data, "normalized_diary_activity_audit.csv")
)

prepared <- list()
sample_rows <- list()
support_rows <- list()
join_rows <- list()
boundary_rows <- list()
for (index in seq_len(nrow(registry))) {
  run <- registry[index, , drop = FALSE]
  accepted_frame <- readRDS(run$accepted_frame_path)
  attached <- h11_activity_attach(
    accepted_frame,
    diary$data,
    run$run_id
  )
  data <- attached$data
  frame_path <- file.path(paths$model_data, paste0(run$run_id, "__frame.rds"))
  saveRDS(data, frame_path, compress = "xz")
  prepared[[run$run_id]] <- list(data = data, frame_path = frame_path)
  sample_rows[[run$run_id]] <- h11_activity_sample_row(
    data,
    run$run_id,
    run$placement
  )
  support_rows[[run$run_id]] <- h11_activity_support(
    data,
    run$run_id,
    run$placement
  )
  join_rows[[run$run_id]] <- attached$join_audit |>
    dplyr::mutate(placement = run$placement, .after = "run_id")
  boundary_rows[[run$run_id]] <- data |>
    dplyr::count(.data$activity_AR_start_reason, name = "observations_30_minute") |>
    dplyr::mutate(
      run_id = run$run_id,
      placement = run$placement,
      AR_start = .data$activity_AR_start_reason != "continuous",
      .before = 1L
    )
  rm(accepted_frame, attached)
}

sample_counts <- dplyr::bind_rows(sample_rows)
activity_support <- dplyr::bind_rows(support_rows)
join_audit <- dplyr::bind_rows(join_rows)
boundary_audit <- dplyr::bind_rows(boundary_rows)

if (
  nrow(sample_counts) != 2L ||
    any(sample_counts$participants < 2L) ||
    any(sample_counts$sites < 2L) ||
    any(sample_counts$female_participants + sample_counts$male_participants !=
      sample_counts$participants) ||
    any(sample_counts$female_observations_30_minute +
      sample_counts$male_observations_30_minute !=
      sample_counts$observations_30_minute) ||
    any(sample_counts$AR_sequences != vapply(
      prepared,
      function(item) sum(item$data$AR_start),
      numeric(1)
    ))
) {
  h11_activity_abort("Activity-complete sample counts do not reconcile")
}
if (
  nrow(activity_support) != 20L ||
    !all(h11_activity_levels() %in% activity_support$activity_code) ||
    any(activity_support$participants < 1L)
) {
  h11_activity_abort("Activity support is incomplete by placement and sex")
}

write_activity_csv(
  sample_counts,
  file.path(paths$tables, "activity_common_sample_counts.csv")
)
write_activity_csv(
  activity_support,
  file.path(paths$tables, "activity_category_support_by_sex.csv")
)
write_activity_csv(
  join_audit,
  file.path(paths$model_data, "activity_join_attrition.csv")
)
write_activity_csv(
  boundary_audit,
  file.path(paths$model_data, "activity_AR_boundary_audit.csv")
)

formulas <- h11_activity_formulas(root)
formula_manifest <- tibble::tribble(
  ~formula_id, ~fit_role, ~rho_rule, ~fit_gate,
  "restricted_unadjusted", "same-sample unadjusted H11 sensitivity",
  "rho from preliminary activity-adjusted model", "always",
  "activity_adjusted", "same-sample activity-adjusted H11 sensitivity",
  "rho from preliminary activity-adjusted model", "always",
  "activity_adjusted_no_sex", "conditional effect-size baseline",
  "same final rho", "only if adjusted global raw p < 0.050"
) |>
  dplyr::mutate(
    formula = vapply(
      .data$formula_id,
      function(id) h11_formula_text(formulas[[id]]),
      character(1)
    ),
    family = "Gaussian",
    link = "identity",
    method = "fREML",
    discrete = TRUE,
    knots = "time_hour = c(0, 24)",
    activity_encoding = paste(
      "Treatment-coded activity level with home reference; ordered-factor",
      "cyclic deviations with common smoothing parameter id = 2"
    ),
    interval_method = "participant-cluster-robust pointwise 95% intervals"
  )
write_activity_csv(
  formula_manifest,
  file.path(paths$model_data, "formula_and_fit_manifest.csv")
)

requested_runs <- Sys.getenv("H11_ACTIVITY_RUN_IDS", unset = "")
active_registry <- registry
if (nzchar(requested_runs)) {
  requested_ids <- trimws(strsplit(requested_runs, ",", fixed = TRUE)[[1L]])
  if (!all(requested_ids %in% registry$run_id)) {
    h11_activity_abort(
      "Unknown H11_ACTIVITY_RUN_IDS: %s",
      paste(setdiff(requested_ids, registry$run_id), collapse = "; ")
    )
  }
  active_registry <- registry |>
    dplyr::filter(.data$run_id %in% requested_ids)
}

message("Beginning checkpointed discrete=TRUE activity-context fits")
for (index in seq_len(nrow(active_registry))) {
  run <- active_registry[index, , drop = FALSE]
  data <- prepared[[run$run_id]]$data
  preliminary <- h11_activity_checkpoint_fit(
    formula = formulas$activity_adjusted,
    data = data,
    method = "fREML",
    rho = 0,
    model_id = "activity_adjusted_preliminary_rho0_fREML",
    run_id = run$run_id,
    model_directory = paths$models
  )
  rho <- h02_estimate_rho(preliminary$fit, data)
  if (!is.finite(rho) || abs(rho) > 0.95) {
    h11_activity_abort("Invalid boundary-aware rho for %s", run$run_id)
  }
  unadjusted <- h11_activity_checkpoint_fit(
    formula = formulas$restricted_unadjusted,
    data = data,
    method = "fREML",
    rho = rho,
    model_id = "restricted_unadjusted_final_fREML",
    run_id = run$run_id,
    model_directory = paths$models
  )
  adjusted <- h11_activity_checkpoint_fit(
    formula = formulas$activity_adjusted,
    data = data,
    method = "fREML",
    rho = rho,
    model_id = "activity_adjusted_final_fREML",
    run_id = run$run_id,
    model_directory = paths$models
  )
  bundle <- list(
    run_id = run$run_id,
    placement = run$placement,
    analytical_role = run$analytical_role,
    frame_path = prepared[[run$run_id]]$frame_path,
    frame_sha256 = h11_activity_frame_hash(data),
    rho = rho,
    preliminary_path = preliminary$model_path,
    unadjusted_path = unadjusted$model_path,
    adjusted_path = adjusted$model_path,
    preliminary_metadata_path = preliminary$metadata_path,
    unadjusted_metadata_path = unadjusted$metadata_path,
    adjusted_metadata_path = adjusted$metadata_path,
    completed_at = format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE)
  )
  saveRDS(
    bundle,
    file.path(paths$models, run$run_id, "activity_context_run_bundle.rds"),
    compress = "xz"
  )
  rm(data, preliminary, unadjusted, adjusted, bundle)
  invisible(gc())
}

bundle_paths <- file.path(
  paths$models,
  registry$run_id,
  "activity_context_run_bundle.rds"
)
if (!all(file.exists(bundle_paths))) {
  missing <- registry$run_id[!file.exists(bundle_paths)]
  message(
    "Partial activity-context run complete; remaining bundles: ",
    paste(missing, collapse = "; ")
  )
  quit(save = "no", status = 0L)
}

bundles <- lapply(bundle_paths, readRDS)
names(bundles) <- registry$run_id

model_rows <- list()
rho_rows <- list()
comparison_rows <- list()
robust_rows <- list()
curve_rows <- list()
contrast_rows <- list()
acf_rows <- list()
residual_rows <- list()
smooth_rows <- list()
concurvity_rows <- list()
k_rows <- list()
closure_rows <- list()
site_rows <- list()
assessment_rows <- list()
effect_variation_rows <- list()

message("Computing robust tests, pointwise intervals, and diagnostics")
for (index in seq_len(nrow(registry))) {
  run <- registry[index, , drop = FALSE]
  bundle <- bundles[[run$run_id]]
  data <- readRDS(bundle$frame_path)
  fit_results <- list(
    restricted_unadjusted = list(
      fit = readRDS(bundle$unadjusted_path),
      metadata = readRDS(bundle$unadjusted_metadata_path)
    ),
    activity_adjusted = list(
      fit = readRDS(bundle$adjusted_path),
      metadata = readRDS(bundle$adjusted_metadata_path)
    )
  )
  preliminary <- readRDS(bundle$preliminary_path)
  rho_rows[[run$run_id]] <- tibble::tibble(
    run_id = run$run_id,
    placement = run$placement,
    rho = bundle$rho,
    rho_source_model = "activity_adjusted_preliminary_rho0_fREML",
    rho_estimator = paste(
      "Boundary-aware lag-1 correlation of preliminary response residuals;",
      "held fixed across both exact-common-sample final fits"
    ),
    preliminary_lag1_response_correlation = unname(
      h02_boundary_lag_correlation(
        stats::residuals(preliminary, type = "response"),
        data$AR_start,
        lag = 1L
      )["correlation"]
    ),
    AR_sequences = sum(data$AR_start),
    frame_sha256 = h11_activity_frame_hash(data)
  )

  for (model_variant in names(fit_results)) {
    result <- fit_results[[model_variant]]
    fit <- result$fit
    diagnostic_run_id <- paste(run$run_id, model_variant, sep = "__")
    row <- h11_activity_model_row(
      result,
      run$run_id,
      run$placement,
      model_variant
    )
    model_rows[[diagnostic_run_id]] <- row
    context <- h11_stage2_robust_context(fit, data, diagnostic_run_id)
    robust <- h11_activity_robust_test(
      fit,
      data,
      run$run_id,
      run$placement,
      model_variant,
      context
    )
    comparison_rows[[diagnostic_run_id]] <- robust$comparison
    robust_rows[[diagnostic_run_id]] <- robust$diagnostics
    pointwise <- h11_activity_pointwise_curves(
      fit,
      data,
      run$run_id,
      run$placement,
      model_variant,
      context
    )
    curve_rows[[diagnostic_run_id]] <- pointwise$curves
    contrast_rows[[diagnostic_run_id]] <- pointwise$contrast
    closure <- h11_activity_curve_closure(
      fit,
      data,
      run$run_id,
      run$placement,
      model_variant
    )
    closure_rows[[diagnostic_run_id]] <- closure
    acf <- h11_stage2_residual_acf(
      fit,
      data,
      diagnostic_run_id,
      "final_AR1_standardized"
    ) |>
      dplyr::mutate(
        base_run_id = run$run_id,
        placement = run$placement,
        model_variant = model_variant,
        .after = "run_id"
      )
    acf_rows[[diagnostic_run_id]] <- acf
    residual_rows[[diagnostic_run_id]] <- h11_stage2_residual_summary(
      fit,
      data,
      diagnostic_run_id
    ) |>
      dplyr::mutate(
        base_run_id = run$run_id,
        placement = run$placement,
        model_variant = model_variant,
        .after = "run_id"
      )
    smooth_rows[[diagnostic_run_id]] <- h11_stage2_smooth_summary(
      fit,
      diagnostic_run_id
    ) |>
      dplyr::mutate(
        base_run_id = run$run_id,
        placement = run$placement,
        model_variant = model_variant,
        .after = "run_id"
      )
    concurvity_rows[[diagnostic_run_id]] <- h11_stage2_concurvity(
      fit,
      diagnostic_run_id
    ) |>
      dplyr::mutate(
        base_run_id = run$run_id,
        placement = run$placement,
        model_variant = model_variant,
        .after = "run_id"
      )
    k_check <- h11_stage2_k_check(
      fit,
      diagnostic_run_id,
      seed = h02_seed(diagnostic_run_id, 130L)
    ) |>
      dplyr::mutate(
        base_run_id = run$run_id,
        placement = run$placement,
        model_variant = model_variant,
        .after = "run_id"
      )
    k_rows[[diagnostic_run_id]] <- k_check
    site_constraint <- h11_activity_site_constraint(
      fit,
      data,
      run$run_id,
      run$placement,
      model_variant
    )
    site_rows[[diagnostic_run_id]] <- site_constraint
    assessment_rows[[diagnostic_run_id]] <-
      h11_activity_diagnostic_assessment(
        row,
        acf,
        closure,
        site_constraint,
        k_check,
        run$run_id,
        run$placement,
        model_variant
      )
    if (
      model_variant == "activity_adjusted" &&
        robust$comparison$p_raw < 0.05
    ) {
      effect_variation_rows[[run$run_id]] <-
        h11_stage2_curve_variation(
          fit,
          pointwise,
          diagnostic_run_id,
          context
        ) |>
        dplyr::mutate(
          base_run_id = run$run_id,
          placement = run$placement,
          model_variant = model_variant,
          participants = dplyr::n_distinct(data$participant),
          participant_days = dplyr::n_distinct(data$participant_day),
          observations_30_minute = nrow(data),
          sites = dplyr::n_distinct(data$site),
          .after = "run_id"
        )
    }
    rm(
      fit,
      context,
      robust,
      pointwise,
      closure,
      acf,
      k_check,
      site_constraint
    )
    invisible(gc())
  }
  rm(data, fit_results, preliminary)
  invisible(gc())
}

model_fit_summary <- dplyr::bind_rows(model_rows)
rho_summary <- dplyr::bind_rows(rho_rows)
comparisons <- dplyr::bind_rows(comparison_rows)
robust_diagnostics <- dplyr::bind_rows(robust_rows)
curves <- dplyr::bind_rows(curve_rows)
contrasts <- dplyr::bind_rows(contrast_rows)
residual_acf <- dplyr::bind_rows(acf_rows)
residual_summary <- dplyr::bind_rows(residual_rows)
smooth_summary <- dplyr::bind_rows(smooth_rows)
formal_concurvity <- dplyr::bind_rows(concurvity_rows)
k_check <- dplyr::bind_rows(k_rows)
curve_closure <- dplyr::bind_rows(closure_rows)
site_constraint <- dplyr::bind_rows(site_rows)
diagnostic_assessment <- dplyr::bind_rows(assessment_rows)
effect_curve_variation <- dplyr::bind_rows(effect_variation_rows)
attenuation <- h11_activity_attenuation(comparisons, contrasts)

if (
  nrow(model_fit_summary) != 4L ||
    nrow(comparisons) != 4L ||
    nrow(curves) != 384L ||
    nrow(contrasts) != 192L ||
    any(model_fit_summary$n != rep(
      sample_counts$observations_30_minute,
      each = 2L
    )) ||
    any(comparisons$planned_n != comparisons$observed_family_n) ||
    any(abs(comparisons$p_raw - comparisons$p_adjusted_BH) > 0)
) {
  h11_activity_abort("Final activity-sensitivity artifacts do not reconcile")
}

write_activity_csv(
  model_fit_summary,
  file.path(paths$tables, "model_fit_summary.csv")
)
write_activity_csv(rho_summary, file.path(paths$tables, "rho_summary.csv"))
write_activity_csv(
  comparisons,
  file.path(paths$tables, "global_sex_curve_tests.csv")
)
write_activity_csv(
  attenuation,
  file.path(paths$tables, "same_sample_activity_attenuation.csv")
)
write_activity_csv(
  curves,
  file.path(paths$source_data, "sex_specific_curves_pointwise.csv")
)
write_activity_csv(
  contrasts,
  file.path(paths$source_data, "female_minus_male_pointwise_contrasts.csv")
)
write_activity_csv(
  robust_diagnostics,
  file.path(paths$diagnostics, "robust_inference_diagnostics.csv")
)
write_activity_csv(
  residual_acf,
  file.path(paths$diagnostics, "boundary_aware_residual_acf.csv")
)
write_activity_csv(
  residual_summary,
  file.path(paths$diagnostics, "residual_summary.csv")
)
write_activity_csv(
  smooth_summary,
  file.path(paths$diagnostics, "smooth_summary.csv")
)
write_activity_csv(
  formal_concurvity,
  file.path(paths$diagnostics, "formal_concurvity.csv")
)
write_activity_csv(
  k_check,
  file.path(paths$diagnostics, "basis_dimension_check.csv")
)
write_activity_csv(
  curve_closure,
  file.path(paths$diagnostics, "cyclic_curve_closure.csv")
)
write_activity_csv(
  site_constraint,
  file.path(paths$diagnostics, "site_sum_to_zero_constraint.csv")
)
write_activity_csv(
  diagnostic_assessment,
  file.path(paths$diagnostics, "diagnostic_assessment.csv")
)

message("Applying the author-approved conditional sex effect-size gate")
effect_gate <- comparisons |>
  dplyr::filter(.data$model_variant == "activity_adjusted") |>
  dplyr::transmute(
    run_id = .data$run_id,
    placement = .data$placement,
    p_raw = .data$p_raw,
    p_adjusted_BH = .data$p_adjusted_BH,
    effect_size_gate_open = .data$p_raw < 0.05,
    gate_rule = paste(
      "Open only when the activity-adjusted exploratory global robust raw",
      "p-value is below 0.050 within that placement"
    )
  )
write_activity_csv(
  effect_gate,
  file.path(paths$tables, "activity_adjusted_effect_size_gate.csv")
)

effect_model_rows <- list()
effect_pilot_rows <- list()
effect_prediction_rows <- list()
for (index in which(effect_gate$effect_size_gate_open)) {
  gate <- effect_gate[index, , drop = FALSE]
  run <- registry[match(gate$run_id, registry$run_id), , drop = FALSE]
  bundle <- bundles[[run$run_id]]
  data <- readRDS(bundle$frame_path)
  adjusted <- readRDS(bundle$adjusted_path)
  baseline <- h11_activity_checkpoint_fit(
    formula = formulas$activity_adjusted_no_sex,
    data = data,
    method = "fREML",
    rho = bundle$rho,
    model_id = "activity_adjusted_no_sex_effect_size_fREML",
    run_id = run$run_id,
    model_directory = paths$models
  )
  effect_model_rows[[run$run_id]] <- h11_activity_model_row(
    baseline,
    run$run_id,
    run$placement,
    "activity_adjusted_no_sex_effect_size_baseline"
  ) |>
    dplyr::mutate(
      inferential_role = "conditional descriptive effect-size baseline"
    )
  predictions <- tibble::tibble(
    run_id = run$run_id,
    row_index = seq_len(nrow(data)),
    response = data$response,
    baseline_prediction = as.numeric(stats::fitted(baseline$fit)),
    full_prediction = as.numeric(stats::fitted(adjusted))
  )
  prediction_path <- file.path(
    paths$source_data,
    paste0(run$run_id, "__activity_adjusted_effect_size_predictions.rds")
  )
  saveRDS(predictions, prediction_path, compress = "xz")
  pilot <- h11_stage2_bootstrap_r2(
    response = predictions$response,
    baseline_prediction = predictions$baseline_prediction,
    full_prediction = predictions$full_prediction,
    data = data,
    replicates = 50L,
    seed = h02_seed(paste0(run$run_id, "__activity_adjusted"), 140L)
  )
  pilot_path <- file.path(
    paths$diagnostics,
    paste0(run$run_id, "__activity_adjusted_effect_size_pilot_50rep.rds")
  )
  saveRDS(pilot, pilot_path, compress = "xz")
  effect_pilot_rows[[run$run_id]] <- h11_stage2_effect_pilot_summary(
    pilot,
    run$run_id
  ) |>
    dplyr::mutate(
      placement = run$placement,
      participants = dplyr::n_distinct(data$participant),
      participant_days = dplyr::n_distinct(data$participant_day),
      observations_30_minute = nrow(data),
      sites = dplyr::n_distinct(data$site),
      .after = "run_id"
    )
  effect_prediction_rows[[run$run_id]] <- tibble::tibble(
    run_id = run$run_id,
    placement = run$placement,
    prediction_relative_path = relative_path(prediction_path),
    prediction_sha256 = digest::digest(
      prediction_path,
      algo = "sha256",
      file = TRUE
    ),
    pilot_relative_path = relative_path(pilot_path),
    pilot_sha256 = digest::digest(pilot_path, algo = "sha256", file = TRUE),
    baseline_formula = h11_formula_text(formulas$activity_adjusted_no_sex),
    full_formula = h11_formula_text(formulas$activity_adjusted),
    rho = bundle$rho,
    effect_size_scope = paste(
      "Sex-block increment beyond the activity-adjusted inherited temporal",
      "baseline on the exact common sample; fixed in-sample predictions"
    )
  )
  rm(data, adjusted, baseline, predictions, pilot)
  invisible(gc())
}

effect_model_summary <- dplyr::bind_rows(effect_model_rows)
effect_size_pilot <- dplyr::bind_rows(effect_pilot_rows)
effect_prediction_manifest <- dplyr::bind_rows(effect_prediction_rows)
write_activity_csv(
  effect_model_summary,
  file.path(paths$tables, "activity_adjusted_effect_size_model_fit_summary.csv")
)
write_activity_csv(
  effect_size_pilot,
  file.path(paths$tables, "activity_adjusted_effect_size_pilot_50rep.csv")
)
write_activity_csv(
  effect_curve_variation,
  file.path(paths$tables, "activity_adjusted_effect_size_curve_variation.csv")
)
write_activity_csv(
  effect_prediction_manifest,
  file.path(paths$model_data, "activity_adjusted_effect_size_prediction_manifest.csv")
)

completion <- list(
  status = "complete",
  scientific_role = "exploratory contextual sensitivity",
  completed_at = format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE),
  R_version = as.character(getRversion()),
  sample_counts = sample_counts,
  comparisons = comparisons,
  attenuation = attenuation,
  diagnostic_assessment = diagnostic_assessment,
  effect_gate = effect_gate,
  full_bootstrap_run = FALSE,
  producer = producer
)
completion_path <- file.path(paths$model_data, "activity_context_completion.rds")
saveRDS(completion, completion_path, compress = "xz")

manifest_inputs <- unique(c(
  list.files(paths$model_data, full.names = TRUE, recursive = TRUE),
  list.files(paths$models, full.names = TRUE, recursive = TRUE),
  list.files(paths$diagnostics, full.names = TRUE, recursive = TRUE),
  list.files(paths$tables, full.names = TRUE, recursive = TRUE),
  list.files(paths$source_data, full.names = TRUE, recursive = TRUE),
  decision_path,
  file.path(root, producer),
  file.path(root, "scripts/hypotheses/H11/h11_activity_context.R")
))
manifest_inputs <- manifest_inputs[file.exists(manifest_inputs)]
manifest <- tibble::tibble(
  relative_path = vapply(manifest_inputs, relative_path, character(1)),
  bytes = as.numeric(file.info(manifest_inputs)$size),
  sha256 = vapply(
    manifest_inputs,
    digest::digest,
    character(1),
    algo = "sha256",
    file = TRUE
  ),
  producer = producer,
  scientific_status = "full precision stored; reader display formatting deferred"
) |>
  dplyr::arrange(.data$relative_path)
manifest_path <- file.path(
  paths$manifests,
  "H11_activity_context_output_hashes.csv"
)
write_activity_csv(manifest, manifest_path)

message(
  "Completed H11 activity-context sensitivity: ",
  paste(
    sprintf(
      "%s N=%d, days=%d, observations=%d",
      sample_counts$placement,
      sample_counts$participants,
      sample_counts$participant_days,
      sample_counts$observations_30_minute
    ),
    collapse = "; "
  )
)
