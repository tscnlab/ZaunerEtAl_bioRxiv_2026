#!/usr/bin/env Rscript

suppressPackageStartupMessages({
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

if (getRversion() != "4.6.1") {
  h11_stage2_abort(
    "H11 Stage 2 requires R 4.6.1; running %s",
    getRversion()
  )
}
if (
  as.character(utils::packageVersion("mgcv")) != "1.9.4" ||
    as.character(utils::packageVersion("gratia")) != "0.11.2"
) {
  h11_stage2_abort("H11 Stage 2 package versions differ from the approved environment")
}

paths <- h11_stage2_paths(root)
h11_stage2_create_directories(paths)
producer <- "scripts/hypotheses/H11/run_h11_stage2_analysis.R"

write_stage2_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}

message("Reconciling frozen Stage 1 evidence with current upstream files")
reconciliation <- h11_stage2_gate_reconciliation(root)
write_stage2_csv(
  reconciliation,
  file.path(paths$model_data, "upstream_reconciliation.csv")
)

author_decision_path <- file.path(
  root,
  "audit/hypotheses/H11/01_author_decision.md"
)
author_decision_text <- paste(
  readLines(author_decision_path, warn = FALSE),
  collapse = "\n"
)
required_decision_tokens <- c(
  "approved with two author amendments",
  "pointwise 95% confidence intervals",
  "50-replicate pilot"
)
if (!all(vapply(
  required_decision_tokens,
  grepl,
  logical(1),
  x = author_decision_text,
  fixed = TRUE
))) {
  h11_stage2_abort("The H11 author-decision record is incomplete")
}
method_decision_path <- file.path(
  root,
  "audit/hypotheses/H11/02_inferential_method_decision.md"
)
method_decision_text <- paste(
  readLines(method_decision_path, warn = FALSE),
  collapse = "\n"
)
required_method_tokens <- c(
  "Status: **approved**",
  "approved `H11-METHOD-001` through",
  "participant-cluster-robust",
  "pointwise 95% confidence intervals",
  "below 0.050",
  "50-replicate non-inferential pilot"
)
if (!all(vapply(
  required_method_tokens,
  grepl,
  logical(1),
  x = method_decision_text,
  fixed = TRUE
))) {
  h11_stage2_abort("The H11 robust-method decision record is incomplete")
}
decision_record <- tibble::tibble(
  decision_id = c(
    "H11-stage1-approval",
    "H11-pointwise-interval-amendment",
    "H11-conditional-effect-size-amendment",
    paste0("H11-METHOD-00", 1:7)
  ),
  decision_date = "2026-08-01",
  status = "approved",
  decision = c(
    "Proceed to Stage 2 with all non-amended Stage 1 recommendations.",
    paste(
      "Use H02-consistent pointwise conditional 95% intervals at the 48",
      "30-minute clock-bin midpoints; do not claim a familywise-significant period."
    ),
    paste(
      "Compute H02-like sex effect sizes only within a main placement whose",
      "approved global robust test has raw p < 0.050; use only a",
      "50-replicate pilot for hierarchical resampling."
    ),
    "Remove the unfinished ML/discrete=FALSE fits and delta-AIC rule.",
    "Test the complete 48-bin Female-minus-Male curve from final M_pattern.",
    paste(
      "Use AR-whitened participant-cluster CR1 covariance plus Vp - Ve",
      "and the finite-cluster fractional-rank F reference."
    ),
    "Retain one-test global and BH-adjusted two-test decomposition families.",
    paste(
      "Use participant-cluster-robust pointwise 95% intervals; no",
      "simultaneous period claim."
    ),
    paste(
      "Open the placement-specific effect-size branch only for global",
      "robust raw p < 0.050."
    ),
    "Retain fixed-site scope, associational wording, and leave-one-site-out sensitivity."
  ),
  source_path = c(
    rep("audit/hypotheses/H11/01_author_decision.md", 3L),
    rep("audit/hypotheses/H11/02_inferential_method_decision.md", 7L)
  ),
  source_sha256 = c(
    rep(h11_stage2_sha256(author_decision_path), 3L),
    rep(h11_stage2_sha256(method_decision_path), 7L)
  )
)
write_stage2_csv(
  decision_record,
  file.path(paths$model_data, "author_decision_record.csv")
)

reporting_sources <- tibble::tribble(
  ~decision_id, ~source_path, ~required_token,
  "REPORT-008", "audit/decisions/p_value_display_conventions.md",
  "Status: approved",
  "REPORT-009", "audit/decisions/paired_placement_comparison_display.md",
  "Status: approved",
  "REPORT-008-helper", "scripts/pipeline/p_value_display.R",
  "nh_p_value_display",
  "REPORT-010", "audit/decisions/gap_timing_unaware_dataset_terminology.md",
  "Status: approved",
  "REPORT-011", "audit/decisions/figure_readability_and_layout.md",
  "Status: approved",
  "REPORT-012", "audit/decisions/answer_in_brief_callout.md",
  "Status: approved",
  "H11-REPORT-010-APPLICATION",
  "audit/hypotheses/H11/02_reader_facing_terminology_decision.md",
  "Decision ID: `REPORT-010`"
)
reporting_record <- reporting_sources |>
  dplyr::rowwise() |>
  dplyr::mutate(
    source_text = paste(
      readLines(file.path(root, .data$source_path), warn = FALSE),
      collapse = "\n"
    ),
    verified = grepl(
      .data$required_token,
      .data$source_text,
      fixed = TRUE
    ),
    source_sha256 = h11_stage2_sha256(file.path(root, .data$source_path))
  ) |>
  dplyr::ungroup() |>
  dplyr::select(-"source_text", -"required_token")
if (!all(reporting_record$verified)) {
  h11_stage2_abort("An H11 reporting-policy source failed validation")
}
write_stage2_csv(
  reporting_record,
  file.path(paths$model_data, "reporting_decision_record.csv")
)

registry <- h11_stage2_registry(root)
requested_runs <- Sys.getenv("H11_STAGE2_RUN_IDS", unset = "")
if (nzchar(requested_runs)) {
  requested_ids <- trimws(strsplit(requested_runs, ",", fixed = TRUE)[[1L]])
  if (!all(requested_ids %in% registry$run_id)) {
    h11_stage2_abort(
      "Unknown H11_STAGE2_RUN_IDS: %s",
      paste(setdiff(requested_ids, registry$run_id), collapse = "; ")
    )
  }
  active_registry <- registry |>
    dplyr::filter(.data$run_id %in% requested_ids)
} else {
  active_registry <- registry
}

formulas <- h11_formula_set(root)
formula_plan <- tidyr::crossing(
  registry |>
    dplyr::select(
      "run_id", "data_scenario_id", "placement", "analytical_role"
    ),
  tibble::tribble(
    ~model_id, ~formula_id, ~method, ~discrete, ~rho_rule, ~fit_role,
    "mpattern_preliminary_rho0_fREML", "proposed_mpattern", "fREML", TRUE,
    "rho = 0", "preliminary boundary-aware rho estimation",
    "mpattern_final_fREML", "proposed_mpattern", "fREML", TRUE,
    "one run-specific rho from preliminary full model", "final estimation",
    "robust_complete_curve_test", "proposed_mpattern", "post-fit robust Wald", NA,
    "accepted final-model rho and AR.start whitening", "global inference",
    "robust_level_shape_tests", "proposed_mpattern", "post-fit robust Wald", NA,
    "accepted final-model rho and AR.start whitening", "BH-adjusted decomposition inference",
    "m0_effect_size_fREML", "proposed_m0", "fREML", TRUE,
    "one run-specific rho from preliminary full model",
    "conditional effect-size baseline; fitted only when placement gate opens"
  )
) |>
  dplyr::mutate(
    formula = vapply(
      .data$formula_id,
      function(id) h11_formula_text(formulas[[id]]),
      character(1)
    ),
    family = "Gaussian",
    link = "identity",
    knots = "time_hour = c(0, 24)",
    biological_sex_encoding = paste(
      "sex treatment contrast with Male reference; sex_smooth ordered",
      "Male then Female for cyclic Female-minus-Male deviation"
    )
  )
write_stage2_csv(
  formula_plan,
  file.path(paths$model_data, "formula_and_fit_manifest.csv")
)

demographics <- readRDS(file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/demographics.rds"
))

message("Beginning checkpointed H11 Stage 2 fits")
for (index in seq_len(nrow(active_registry))) {
  run <- active_registry[index, , drop = FALSE]
  message("H11 run: ", run$run_id)
  frame <- readRDS(run$frame_path)
  h11_stage2_fit_run(frame, demographics, run, formulas, paths)
  rm(frame)
  invisible(gc())
}

bundle_paths <- file.path(
  paths$models,
  registry$run_id,
  "stage2_run_bundle.rds"
)
if (!all(file.exists(bundle_paths))) {
  missing <- registry$run_id[!file.exists(bundle_paths)]
  message(
    "Partial H11 Stage 2 run complete; remaining checkpoint bundles: ",
    paste(missing, collapse = "; ")
  )
  quit(save = "no", status = 0L)
}

bundles <- lapply(bundle_paths, readRDS)
names(bundles) <- registry$run_id
sample_counts <- dplyr::bind_rows(lapply(bundles, `[[`, "sample"))
model_fit_summary <- dplyr::bind_rows(lapply(bundles, `[[`, "model_rows"))
rho_summary <- dplyr::bind_rows(lapply(bundles, `[[`, "rho_row"))

expected_sample <- tibble::tribble(
  ~run_id, ~participants, ~participant_days, ~observations_30_minute, ~sites,
  "main__glasses__all_available", 141L, 816L, 37756L, 9L,
  "main__chest__all_available", 154L, 902L, 41842L, 8L,
  "manuscript_prepared_data__glasses__all_available", 141L, 809L, 37603L, 9L,
  "manuscript_prepared_data__chest__all_available", 154L, 894L, 41664L, 8L
)
observed_sample <- sample_counts |>
  dplyr::select(
    "run_id", "participants", "participant_days",
    "observations_30_minute", "sites"
  ) |>
  dplyr::arrange(match(.data$run_id, expected_sample$run_id))
if (!identical(observed_sample, expected_sample)) {
  h11_stage2_abort("The exact H11 Stage 2 model samples do not match the approved counts")
}
if (
  any(sample_counts$female_participants + sample_counts$male_participants !=
    sample_counts$participants) ||
    any(sample_counts$female_observations_30_minute +
      sample_counts$male_observations_30_minute !=
      sample_counts$observations_30_minute)
) {
  h11_stage2_abort("Biological-sex sample counts do not reconcile")
}

write_stage2_csv(sample_counts, file.path(paths$tables, "sample_counts.csv"))
write_stage2_csv(
  model_fit_summary,
  file.path(paths$tables, "model_fit_summary.csv")
)
write_stage2_csv(rho_summary, file.path(paths$tables, "rho_summary.csv"))

h02_sample_counts <- utils::read.csv(
  file.path(root, "artifacts/06_model_data/H02/sample_counts.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
paired_run_ids <- c(
  "main__glasses__paired_common_sample",
  "main__chest__paired_common_sample"
)
paired_counts <- h02_sample_counts |>
  dplyr::filter(
    .data$run_id %in% paired_run_ids,
    .data$site == "ALL_SITES"
  ) |>
  dplyr::arrange(match(.data$run_id, paired_run_ids))
paired_count_columns <- c(
  "participants", "participant_days", "observations_30_minute", "sites"
)
if (
  nrow(paired_counts) != 2L ||
    !all(vapply(
      paired_count_columns,
      function(column) length(unique(paired_counts[[column]])) == 1L,
      logical(1)
    ))
) {
  h11_stage2_abort("The stored H02 paired/common placement counts do not reconcile")
}
paired_frame_paths <- file.path(
  root,
  "artifacts/06_model_data/H02",
  paste0(paired_run_ids, ".rds")
)
paired_display_assessment <- tibble::tibble(
  decision_id = "REPORT-009",
  assessment_stage = "H11 Stage 2 author-facing report",
  all_available_near_eye_participants = sample_counts$participants[
    sample_counts$run_id == "main__glasses__all_available"
  ],
  all_available_chest_participants = sample_counts$participants[
    sample_counts$run_id == "main__chest__all_available"
  ],
  all_available_near_eye_participant_days = sample_counts$participant_days[
    sample_counts$run_id == "main__glasses__all_available"
  ],
  all_available_chest_participant_days = sample_counts$participant_days[
    sample_counts$run_id == "main__chest__all_available"
  ],
  all_available_near_eye_observations = sample_counts$observations_30_minute[
    sample_counts$run_id == "main__glasses__all_available"
  ],
  all_available_chest_observations = sample_counts$observations_30_minute[
    sample_counts$run_id == "main__chest__all_available"
  ],
  all_available_near_eye_sites = sample_counts$sites[
    sample_counts$run_id == "main__glasses__all_available"
  ],
  all_available_chest_sites = sample_counts$sites[
    sample_counts$run_id == "main__chest__all_available"
  ],
  stored_paired_frame_participants = paired_counts$participants[[1L]],
  stored_paired_frame_participant_days = paired_counts$participant_days[[1L]],
  stored_paired_frame_observations = paired_counts$observations_30_minute[[1L]],
  stored_paired_frame_sites = paired_counts$sites[[1L]],
  stored_h02_paired_frames_available = all(file.exists(paired_frame_paths)),
  h11_paired_fitted_outputs_available = any(grepl(
    "paired_common_sample",
    model_fit_summary$run_id,
    fixed = TRUE
  )),
  predeclared_scalar_temporal_estimand_available = FALSE,
  scalar_identity_plot_applicable = FALSE,
  applicability_reason = paste(
    "The fitted H11 Stage 2 outputs use unmatched all-available samples,",
    "and the registered paired/common H11 sensitivity has not been fitted.",
    "The H11 result is a temporal curve without a predeclared scalar",
    "reduction, so an H05-style scalar identity scatter would be misleading."
  ),
  closest_valid_display = paste(
    "Retain separate primary near-eye and complementary chest curves in",
    "Stage 2 without direct paired interpretation. If the paired/common",
    "sensitivity is authorized and fitted, prefer matched placement curves",
    "or Female-minus-Male contrast curves; reconsider a clock-bin identity",
    "display only after exact estimand comparability is verified."
  ),
  paired_source_data_csv = NA_character_,
  source_data_status = paste(
    "Not created because no valid H11 paired fitted estimands exist at",
    "this stage; do not pair unmatched all-available outputs."
  )
)
write_stage2_csv(
  paired_display_assessment,
  file.path(paths$model_data, "paired_placement_display_assessment.csv")
)

curve_tables <- list()
contrast_tables <- list()
contrast_contracts <- list()
closure_tables <- list()
parametric_tables <- list()
acf_tables <- list()
residual_tables <- list()
smooth_tables <- list()
concurvity_tables <- list()
k_check_tables <- list()
site_constraint_tables <- list()
assessment_tables <- list()
comparison_tables <- list()
robust_diagnostic_tables <- list()

message("Calculating final-model contrasts and diagnostics")
for (index in seq_len(nrow(registry))) {
  run <- registry[index, , drop = FALSE]
  bundle <- bundles[[run$run_id]]
  data <- readRDS(bundle$frame_path)
  preliminary <- readRDS(bundle$model_paths$preliminary)
  final <- readRDS(bundle$model_paths$final)

  message("  curves and diagnostics: ", run$run_id)
  robust_context <- h11_stage2_robust_context(
    final,
    data,
    run$run_id
  )
  robust_test <- h11_stage2_robust_tests(
    final,
    data,
    run,
    robust_context
  )
  comparison_tables[[run$run_id]] <- robust_test$comparisons
  robust_diagnostic_tables[[run$run_id]] <- robust_test$diagnostics
  curve_contract <- h11_stage2_pointwise_curves(
    final,
    data,
    run$run_id,
    robust_context
  )
  curve_tables[[run$run_id]] <- curve_contract$curves
  contrast_tables[[run$run_id]] <- curve_contract$contrast
  contrast_contracts[[run$run_id]] <- curve_contract
  closure_tables[[run$run_id]] <- h11_stage2_curve_closure(
    final, data, run$run_id
  )
  parametric_tables[[run$run_id]] <- h11_stage2_parametric_sex(
    final, run$run_id, robust_context
  )
  acf_tables[[run$run_id]] <- dplyr::bind_rows(
    h11_stage2_residual_acf(
      preliminary, data, run$run_id, "preliminary_rho0_response"
    ),
    h11_stage2_residual_acf(
      final, data, run$run_id, "final_AR1_standardized"
    )
  )
  residual_tables[[run$run_id]] <- h11_stage2_residual_summary(
    final, data, run$run_id
  )
  smooth_tables[[run$run_id]] <- h11_stage2_smooth_summary(
    final, run$run_id
  )
  concurvity_tables[[run$run_id]] <- h11_stage2_concurvity(
    final, run$run_id
  )
  k_check_tables[[run$run_id]] <- h11_stage2_k_check(
    final,
    run$run_id,
    seed = h02_seed(run$run_id, 90L)
  )
  site_constraint_tables[[run$run_id]] <- h11_stage2_site_constraint(
    final, data, run$run_id
  )
  assessment_tables[[run$run_id]] <- h11_stage2_diagnostic_assessment(
    bundle$model_rows,
    acf_tables[[run$run_id]],
    closure_tables[[run$run_id]],
    site_constraint_tables[[run$run_id]],
    k_check_tables[[run$run_id]],
    run$run_id
  )

  rm(data, preliminary, final, robust_context, robust_test)
  invisible(gc())
}

sex_curves <- dplyr::bind_rows(curve_tables)
sex_contrasts <- dplyr::bind_rows(contrast_tables)
pointwise_segments <- h11_stage2_pointwise_segments(sex_contrasts)
curve_closure <- dplyr::bind_rows(closure_tables)
parametric_sex <- dplyr::bind_rows(parametric_tables)
residual_acf <- dplyr::bind_rows(acf_tables)
residual_summary <- dplyr::bind_rows(residual_tables)
smooth_summary <- dplyr::bind_rows(smooth_tables)
formal_concurvity <- dplyr::bind_rows(concurvity_tables)
k_check <- dplyr::bind_rows(k_check_tables)
site_constraint <- dplyr::bind_rows(site_constraint_tables)
diagnostic_assessment <- dplyr::bind_rows(assessment_tables)
model_comparisons <- h11_stage2_adjust_multiplicity(
  dplyr::bind_rows(comparison_tables)
)
robust_inference_diagnostics <- dplyr::bind_rows(robust_diagnostic_tables)

write_stage2_csv(
  model_comparisons,
  file.path(paths$tables, "model_comparisons.csv")
)
write_stage2_csv(
  robust_inference_diagnostics,
  file.path(paths$diagnostics, "robust_inference_diagnostics.csv")
)

write_stage2_csv(
  sex_curves,
  file.path(paths$source_data, "sex_specific_curves_pointwise.csv")
)
write_stage2_csv(
  sex_contrasts,
  file.path(paths$source_data, "female_minus_male_pointwise_contrasts.csv")
)
write_stage2_csv(
  pointwise_segments,
  file.path(paths$tables, "pointwise_descriptive_segments.csv")
)
write_stage2_csv(
  curve_closure,
  file.path(paths$diagnostics, "cyclic_curve_closure.csv")
)
write_stage2_csv(
  parametric_sex,
  file.path(paths$tables, "parametric_sex_component.csv")
)
write_stage2_csv(
  residual_acf,
  file.path(paths$diagnostics, "boundary_aware_residual_acf.csv")
)
write_stage2_csv(
  residual_summary,
  file.path(paths$diagnostics, "residual_summary.csv")
)
write_stage2_csv(
  smooth_summary,
  file.path(paths$diagnostics, "smooth_summary.csv")
)
write_stage2_csv(
  formal_concurvity,
  file.path(paths$diagnostics, "formal_concurvity.csv")
)
write_stage2_csv(
  k_check,
  file.path(paths$diagnostics, "basis_dimension_check.csv")
)
write_stage2_csv(
  site_constraint,
  file.path(paths$diagnostics, "site_sum_to_zero_constraint.csv")
)
write_stage2_csv(
  diagnostic_assessment,
  file.path(paths$diagnostics, "diagnostic_assessment.csv")
)

message("Applying the predeclared conditional effect-size gate")
main_global <- model_comparisons |>
  dplyr::filter(
    .data$data_scenario_id == "main",
    .data$comparison_role == "global"
  )
effect_gate <- main_global |>
  dplyr::transmute(
    run_id = .data$run_id,
    placement = .data$placement,
    family_id = .data$family_id,
    p_raw = .data$p_raw,
    p_adjusted_BH = .data$p_adjusted_BH,
    support_status = .data$support_status,
    effect_size_gate_open = .data$p_raw < 0.05,
    gate_rule = paste(
      "Open within this main placement only when the accepted one-test",
      "global participant-cluster-robust raw p < 0.050; chest cannot alter",
      "the primary near-eye gate."
    )
  )
write_stage2_csv(
  effect_gate,
  file.path(paths$tables, "effect_size_gate.csv")
)

effect_model_rows <- list()
effect_pilot_tables <- list()
effect_variation_tables <- list()
effect_prediction_metadata <- list()
for (index in which(effect_gate$effect_size_gate_open)) {
  gate <- effect_gate[index, , drop = FALSE]
  run <- registry[match(gate$run_id, registry$run_id), , drop = FALSE]
  bundle <- bundles[[run$run_id]]
  data <- readRDS(bundle$frame_path)
  final <- readRDS(bundle$model_paths$final)
  effect_robust_context <- h11_stage2_robust_context(
    final,
    data,
    run$run_id
  )
  baseline <- h11_stage2_checkpoint_fit(
    formulas$proposed_m0,
    data,
    "fREML",
    bundle$rho,
    TRUE,
    "m0_effect_size_fREML",
    run$run_id,
    paths$models
  )
  effect_model_rows[[run$run_id]] <- h11_stage2_model_row(
    baseline,
    run,
    "proposed_m0"
  ) |>
    dplyr::mutate(
      fit_role = "conditional H02-like effect-size baseline",
      inferential_role = "descriptive fitted-model relevance only"
    )
  baseline_prediction <- as.numeric(stats::fitted(baseline$fit))
  full_prediction <- as.numeric(stats::fitted(final))
  predictions <- tibble::tibble(
    run_id = run$run_id,
    row_index = seq_len(nrow(data)),
    response = data$response,
    baseline_prediction = baseline_prediction,
    full_prediction = full_prediction
  )
  prediction_path <- file.path(
    paths$source_data,
    paste0(run$run_id, "__effect_size_fixed_predictions.rds")
  )
  saveRDS(predictions, prediction_path, compress = "xz")
  pilot <- h11_stage2_bootstrap_r2(
    response = data$response,
    baseline_prediction = baseline_prediction,
    full_prediction = full_prediction,
    data = data,
    replicates = 50L,
    seed = h02_seed(run$run_id, 110L)
  )
  pilot_path <- file.path(
    paths$diagnostics,
    paste0(run$run_id, "__effect_size_pilot_50rep.rds")
  )
  saveRDS(pilot, pilot_path, compress = "xz")
  effect_pilot_tables[[run$run_id]] <- h11_stage2_effect_pilot_summary(
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
  effect_variation_tables[[run$run_id]] <- h11_stage2_curve_variation(
    final,
    contrast_contracts[[run$run_id]],
    run$run_id,
    effect_robust_context
  ) |>
    dplyr::mutate(
      placement = run$placement,
      participants = dplyr::n_distinct(data$participant),
      participant_days = dplyr::n_distinct(data$participant_day),
      observations_30_minute = nrow(data),
      sites = dplyr::n_distinct(data$site),
      .after = "run_id"
    )
  effect_prediction_metadata[[run$run_id]] <- tibble::tibble(
    run_id = run$run_id,
    placement = run$placement,
    prediction_path = sub(paste0("^", root, "/"), "", prediction_path),
    prediction_sha256 = h11_stage2_sha256(prediction_path),
    pilot_path = sub(paste0("^", root, "/"), "", pilot_path),
    pilot_sha256 = h11_stage2_sha256(pilot_path),
    baseline_formula = h11_formula_text(formulas$proposed_m0),
    full_formula = h11_formula_text(formulas$proposed_mpattern),
    rho = bundle$rho,
    effect_size_scope = paste(
      "Exact one-block conditional Shapley/general-dominance allocation",
      "beyond the inherited H02 temporal baseline; row-weighted in-sample",
      "R-squared on log10(melEDI + 0.1 lx); fixed predictions."
    )
  )
  rm(
    data,
    final,
    baseline,
    pilot,
    predictions,
    effect_robust_context
  )
  invisible(gc())
}

effect_model_summary <- dplyr::bind_rows(effect_model_rows)
effect_size_pilot <- dplyr::bind_rows(effect_pilot_tables)
effect_curve_variation <- dplyr::bind_rows(effect_variation_tables)
effect_prediction_manifest <- dplyr::bind_rows(effect_prediction_metadata)
write_stage2_csv(
  effect_model_summary,
  file.path(paths$tables, "effect_size_model_fit_summary.csv")
)
write_stage2_csv(
  effect_size_pilot,
  file.path(paths$tables, "effect_size_pilot_50rep.csv")
)
write_stage2_csv(
  effect_curve_variation,
  file.path(paths$tables, "effect_size_curve_variation.csv")
)
write_stage2_csv(
  effect_prediction_manifest,
  file.path(paths$model_data, "effect_size_prediction_manifest.csv")
)

message("Building the V0/model-change/data-preparation comparison")
v0 <- utils::read.csv(
  file.path(root, "artifacts/06_model_data/H11/stage1_v0_result_summary.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
) |>
  dplyr::filter(.data$comparison == "temporal null versus sex smooth")
new_global <- model_comparisons |>
  dplyr::filter(.data$comparison_role == "global") |>
  dplyr::select(
    "run_id", "data_scenario_id", "placement", "analytical_role",
    "test_statistic", "test_df", "denominator_df",
    "reduced_AIC", "full_AIC", "delta_AIC_reduced_minus_full",
    "p_raw", "p_adjusted_BH", "support_status"
  ) |>
  dplyr::left_join(
    sample_counts |>
      dplyr::select(
        "run_id", "participants", "participant_days",
        "observations_30_minute", "sites"
      ),
    by = "run_id",
    relationship = "one-to-one"
  )
v0_layer <- v0 |>
  dplyr::transmute(
    placement = .data$placement,
    comparison_layer = "V0 recovered result",
    data_scenario_id = "manuscript_prepared_data",
    implementation = paste(
      "V0 fREML structures with separately estimated rho; omitted",
      "parametric sex level; comparison not decision-valid"
    ),
    participants = .data$participants,
    participant_days = .data$participant_days,
    observations_30_minute = .data$observations_30_minute,
    sites = .data$sites,
    reduced_AIC = .data$reduced_AIC,
    full_AIC = .data$full_AIC,
    delta_AIC_reduced_minus_full = .data$delta_AIC_reduced_minus_full,
    test_statistic = NA_real_,
    test_df = NA_real_,
    denominator_df = NA_real_,
    p_raw = .data$smooth_sex_p,
    p_adjusted_BH = NA_real_,
    support_status = "reopened_not_decision_valid",
    change_attributed_to = "reference V0 result"
  )
new_layer <- new_global |>
  dplyr::transmute(
    placement = .data$placement,
    comparison_layer = dplyr::if_else(
      .data$data_scenario_id == "main",
      "New implementation on main repaired data",
      "New implementation on gap-timing-unaware data"
    ),
    data_scenario_id = .data$data_scenario_id,
    implementation = paste(
      "Approved post-fit participant-cluster-robust joint curve test from",
      "the final fREML model with parametric level and cyclic deviation"
    ),
    participants = .data$participants,
    participant_days = .data$participant_days,
    observations_30_minute = .data$observations_30_minute,
    sites = .data$sites,
    reduced_AIC = .data$reduced_AIC,
    full_AIC = .data$full_AIC,
    delta_AIC_reduced_minus_full = .data$delta_AIC_reduced_minus_full,
    test_statistic = .data$test_statistic,
    test_df = .data$test_df,
    denominator_df = .data$denominator_df,
    p_raw = .data$p_raw,
    p_adjusted_BH = .data$p_adjusted_BH,
    support_status = .data$support_status,
    change_attributed_to = dplyr::if_else(
      .data$data_scenario_id == "main",
      "data preparation after holding the new implementation fixed",
      paste(
        "model/inference implementation relative to V0 on the corresponding",
        "gap-timing-unaware frame"
      )
    )
  )
v0_comparison <- dplyr::bind_rows(v0_layer, new_layer) |>
  dplyr::arrange(
    factor(.data$placement, levels = c("glasses", "chest")),
    factor(
      .data$comparison_layer,
      levels = c(
        "V0 recovered result",
        "New implementation on gap-timing-unaware data",
        "New implementation on main repaired data"
      )
    )
  )
write_stage2_csv(
  v0_comparison,
  file.path(paths$tables, "v0_new_implementation_comparison.csv")
)

data_preparation_comparison <- new_global |>
  dplyr::select(
    "placement", "data_scenario_id", "test_statistic", "test_df",
    "denominator_df",
    "p_raw", "p_adjusted_BH", "support_status",
    "participants", "participant_days", "observations_30_minute", "sites"
  ) |>
  tidyr::pivot_wider(
    names_from = "data_scenario_id",
    values_from = c(
      "test_statistic", "test_df", "denominator_df", "p_raw", "p_adjusted_BH",
      "support_status", "participants", "participant_days",
      "observations_30_minute", "sites"
    ),
    names_sep = "__"
  ) |>
  dplyr::mutate(
    added_participant_days_main_minus_manuscript =
      .data$participant_days__main -
      .data$participant_days__manuscript_prepared_data,
    added_observations_main_minus_manuscript =
      .data$observations_30_minute__main -
      .data$observations_30_minute__manuscript_prepared_data,
    robust_statistic_change_main_minus_gap_timing_unaware =
      .data$test_statistic__main -
      .data$test_statistic__manuscript_prepared_data,
    raw_p_change_main_minus_gap_timing_unaware =
      .data$p_raw__main -
      .data$p_raw__manuscript_prepared_data,
    interpretation_scope = paste(
      "This contrast holds the approved H11 implementation fixed and varies",
      "the shared preparation scenario; it does not isolate one individual",
      "upstream correction."
    )
  )
write_stage2_csv(
  data_preparation_comparison,
  file.path(paths$tables, "data_preparation_comparison.csv")
)

deferred <- tibble::tribble(
  ~scenario_id, ~placement_scope, ~stage2_status, ~why_deferred, ~could_change_interpretation,
  "registered_hourly_geometric_mean", "near-eye and chest", "deferred",
  "Registered outcome sensitivity belongs to the full sensitivity battery after the Stage 2 gate.",
  "Yes; it changes epoch, aggregation, support, and the dependence structure.",
  "paired_common_sample", "near-eye and chest", "deferred",
  "The placement-matched sensitivity requires four additional preliminary/final BAM fits and remains behind the Stage 2 result gate.",
  "Yes; it can distinguish placement differences from all-available sample composition.",
  "leave_one_site_out", "near-eye primary, chest if warranted", "deferred",
  "Repeated refits are computationally expensive and explicitly permitted to remain outside Stage 2.",
  "Yes; sparse sex cells at UCR and TUM could influence the primary curve.",
  "all_zero_inclusive", "near-eye and chest", "blocked_shared_input",
  "The coordinator has not supplied the approved H02-compatible all-zero-inclusive frame.",
  "Yes; retaining otherwise eligible exact-all-zero participant-days can change time patterns.",
  "H02_model_form", "near-eye first", "deferred_separate_gate",
  "Alternative temporal bases and response families would reopen inherited H02 decisions.",
  "Yes; high exact-zero mass, tails, and concurvity motivate a later robustness check.",
  "activity_context", "near-eye and chest", "deferred_separate_gate",
  "The H04 activity dictionary and exact activity-complete common sample are not yet approved for H11.",
  "Yes; it may contextualize attenuation but cannot establish behaviour or mediation."
)
write_stage2_csv(
  deferred,
  file.path(paths$model_data, "deferred_analysis_registry.csv")
)

environment <- tibble::tibble(
  component = c(
    "R", "mgcv", "gratia", "dplyr", "tidyr", "readr", "digest"
  ),
  version = c(
    as.character(getRversion()),
    vapply(
      c("mgcv", "gratia", "dplyr", "tidyr", "readr", "digest"),
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  computation_role = c(
    "authoritative scientific language",
    "BAM fitting and coefficient covariance",
    "formal concurvity wrapper",
    "data transformation and summaries",
    "model grid and comparison reshaping",
    "artifact serialization",
    "SHA-256 and frame identity"
  )
)
write_stage2_csv(
  environment,
  file.path(paths$model_data, "environment.csv")
)

completion <- list(
  completed_at = format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE),
  producer = producer,
  run_ids = registry$run_id,
  sample_counts = sample_counts,
  model_comparisons = model_comparisons,
  diagnostic_assessment = diagnostic_assessment,
  effect_gate = effect_gate,
  effect_size_pilot = effect_size_pilot,
  R_version = as.character(getRversion()),
  mgcv_version = as.character(utils::packageVersion("mgcv"))
)
saveRDS(
  completion,
  file.path(paths$model_data, "stage2_analysis_completion.rds"),
  compress = "xz"
)

message("H11 Stage 2 analysis and 50-replicate conditional pilots complete")
