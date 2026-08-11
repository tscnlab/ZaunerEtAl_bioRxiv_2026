# Verify the H04 Stage 2 fitted artifacts, reports, and computation gates.

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

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H04 Stage 2 tests require R 4.6.1", call. = FALSE)
}

library(dplyr)
library(tidyr)
library(readr)
library(tibble)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_data.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_temporal.R"))

artifact <- function(...) file.path(root, "artifacts", ...)
read_h04 <- function(...) {
  readr::read_csv(artifact(...), show_col_types = FALSE, na = "")
}

approvals <- read_h04("06_model_data", "H04", "H04_author_approvals.csv")
inputs <- read_h04("06_model_data", "H04", "H04_input_audit.csv")
formulas <- read_h04("06_model_data", "H04", "H04_formula_registry.csv")
samples <- read_h04("06_model_data", "H04", "H04_model_frame_index.csv")
k_distribution <- read_h04("06_model_data", "H04", "H04_k_distribution.csv")
support <- read_h04(
  "06_model_data",
  "H04",
  "H04_weighted_support_totals.csv"
)
primary <- read_h04("09_tables", "H04", "H04_primary_category_estimands.csv")
tests <- read_h04(
  "09_tables",
  "H04",
  "H04_primary_and_heterogeneity_tests.csv"
)
diagnostics <- read_h04("08_diagnostics", "H04", "H04_model_diagnostics.csv")
assessments <- read_h04(
  "08_diagnostics",
  "H04",
  "H04_diagnostic_assessments.csv"
)
heterogeneity_gate <- read_h04(
  "08_diagnostics",
  "H04",
  "H04_heterogeneity_architecture_gate.csv"
)
site_activity <- read_h04(
  "09_tables",
  "H04",
  "H04_site_activity_estimands.csv"
)
sensitivity <- read_h04(
  "09_tables",
  "H04",
  "H04_sensitivity_comparison.csv"
)
sensitivity_tests <- read_h04(
  "09_tables",
  "H04",
  "H04_sensitivity_omnibus_tests.csv"
)
influence <- read_h04(
  "09_tables",
  "H04",
  "H04_influence_category_refits.csv"
)
v0_comparison <- read_h04(
  "09_tables",
  "H04",
  "H04_v0_denominator_and_test_comparison.csv"
)
v0_models <- read_h04("09_tables", "H04", "H04_v0_bridge_models.csv")
temporal_basis <- read_h04(
  "08_diagnostics",
  "H04",
  "H04_temporal_basis_contract.csv"
)
temporal_summary <- read_h04(
  "08_diagnostics",
  "H04",
  "H04_temporal_model_summary.csv"
)
temporal_retention <- read_h04(
  "08_diagnostics",
  "H04",
  "H04_temporal_retention_decision.csv"
)
temporal_run <- read_h04(
  "08_diagnostics",
  "H04",
  "H04_temporal_run_diagnostics.csv"
)
temporal_k <- read_h04(
  "08_diagnostics",
  "H04",
  "H04_temporal_k_check.csv"
)
temporal_uncertainty <- read_h04(
  "08_diagnostics",
  "H04",
  "H04_temporal_uncertainty_contract.csv"
)
bootstrap_supersession <- read_h04(
  "08_diagnostics",
  "H04",
  "H04_temporal_bootstrap_supersession.csv"
)
temporal_near_curves <- read_h04(
  "11_source_data",
  "H04",
  "H04_temporal_near_eye_curves.csv"
)
temporal_chest_curves <- read_h04(
  "11_source_data",
  "H04",
  "H04_temporal_chest_curves.csv"
)

# Frozen inputs, approvals, and formulas.
stopifnot(
  nrow(approvals) == 8L,
  all(approvals$status == "APPROVED"),
  all(inputs$hash_verified),
  identical(inputs$sha256, inputs$observed_sha256)
)
expected_formula_registry <- enframe(
  h04_formula_set(),
  name = "formula_id",
  value = "formula"
) |>
  mutate(formula = vapply(.data$formula, h04_formula_text, character(1)))
stopifnot(
  identical(formulas$formula_id, expected_formula_registry$formula_id),
  identical(formulas$formula, expected_formula_registry$formula)
)

# Exact fitted-frame cardinalities and within-hour weight conservation.
main_samples <- samples |>
  filter(.data$scenario_id == "primary_dataset") |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
stopifnot(
  isTRUE(all.equal(main_samples$participants, c(126, 150))),
  isTRUE(all.equal(main_samples$participant_days, c(724, 875))),
  isTRUE(all.equal(
    main_samples$unique_participant_hours,
    c(16526, 20128)
  )),
  isTRUE(all.equal(main_samples$long_rows, c(17266, 21071))),
  isTRUE(all.equal(main_samples$effective_weighted_hours, c(16526, 20128)))
)
frames <- readRDS(artifact("06_model_data", "H04", "H04_model_frames.rds"))
for (frame in frames$main) {
  weight_check <- frame |>
    group_by(.data$analysis_hour_id) |>
    summarise(
      rows = dplyr::n(),
      k = dplyr::first(.data$k),
      weight_sum = sum(.data$analysis_weight),
      outcomes = dplyr::n_distinct(.data$geo_medi_1h),
      .groups = "drop"
    )
  stopifnot(
    all(weight_check$rows == weight_check$k),
    all(weight_check$outcomes == 1L),
    max(abs(weight_check$weight_sum - 1)) < 1e-10
  )
}
stopifnot(
  isTRUE(all.equal(k_distribution$k, c(1, 2, 3, 1, 2, 3))),
  isTRUE(all.equal(
    k_distribution$unique_participant_hours,
    c(19210, 893, 25, 15810, 692, 24)
  )),
  all(
    abs(
      support$unique_participant_hours[support$summary_level == "placement"] -
        support$effective_weighted_hours[support$summary_level == "placement"]
    ) <
      1e-10
  )
)

# Fitted main objects retain the exact formula, weights, and rank.
additive <- readRDS(artifact(
  "07_models",
  "H04",
  "H04_additive_model_objects.rds"
))
for (id in c("near_eye", "chest")) {
  object <- additive$main[[id]]
  stopifnot(
    inherits(object$fit, "glm"),
    identical(
      h04_formula_text(stats::formula(object$fit)),
      h04_formula_text(h04_formula_set()$primary_full)
    ),
    object$fit$rank == ncol(stats::model.matrix(object$fit)),
    all(is.finite(stats::coef(object$fit))),
    max(abs(object$data$analysis_weight - object$fit$prior.weights)) < 1e-12,
    identical(
      as.character(object$data$participant),
      as.character(frames$main[[id]]$participant)
    )
  )
}
rm(additive)
invisible(gc())

# Primary estimands, restrictions, multiplicity, and p-value display.
expected_means <- tibble::tribble(
  ~placement,
  ~activity_code,
  ~mean,
  "Near-eye",
  "sleeping",
  6.953,
  "Near-eye",
  "home",
  74.693,
  "Near-eye",
  "road_vehicle",
  332.091,
  "Near-eye",
  "working_indoor",
  202.063,
  "Near-eye",
  "outdoors",
  864.807,
  "Near-eye",
  "other",
  221.752,
  "Chest",
  "sleeping",
  7.681,
  "Chest",
  "home",
  87.594,
  "Chest",
  "road_vehicle",
  576.052,
  "Chest",
  "working_indoor",
  210.122,
  "Chest",
  "outdoors",
  1203.102,
  "Chest",
  "other",
  315.713
)
observed_means <- primary |>
  select("placement", "activity_code", observed = "standardized_mean_lx") |>
  inner_join(expected_means, by = c("placement", "activity_code"))
stopifnot(
  nrow(observed_means) == 12L,
  max(abs(observed_means$observed - observed_means$mean)) < 0.6
)
named <- primary |>
  filter(
    .data$activity_code %in%
      c(
        "sleeping",
        "road_vehicle",
        "working_indoor",
        "outdoors"
      )
  )
other <- primary |>
  filter(.data$activity_code == "other")
stopifnot(
  nrow(named) == 8L,
  all(named$family_id == "H04-F2"),
  all(named$family_n == 4L),
  all(named$p_adjusted < 0.05),
  all(is.na(other$p_adjusted)),
  all(grepl("display", other$inferential_role, ignore.case = TRUE))
)
primary_tests <- tests |>
  filter(.data$test_id %in% c("H04-F1", "H04-F1b"))
stopifnot(
  isTRUE(all.equal(sort(unique(primary_tests$restrictions)), c(4, 5))),
  all(primary_tests$status == "ESTIMABLE"),
  all(primary_tests$p_raw < 0.001),
  nh_format_p_value(0.001) == "0.001",
  nh_format_p_value(0.000999) == "<0.001"
)

# Separate heterogeneity, diagnostics, influence, and sensitivity battery.
heterogeneity_tests <- tests |>
  filter(.data$test_id == "H04-F3")
stopifnot(
  nrow(heterogeneity_tests) == 2L,
  all(heterogeneity_tests$selected_architecture == "five_named"),
  all(heterogeneity_tests$p_raw < 0.001),
  all(heterogeneity_gate$gate_pass),
  all(heterogeneity_gate$full_rank),
  !any(grepl("Other", heterogeneity_gate$formula, fixed = TRUE)),
  identical(
    site_activity |>
      filter(!is.na(.data$site_deviation_p_adjusted)) |>
      count(.data$placement, name = "family_n") |>
      arrange(match(.data$placement, c("Near-eye", "Chest"))) |>
      pull("family_n"),
    c(44L, 40L)
  ),
  identical(
    site_activity |>
      filter(.data$site_deviation_p_adjusted < 0.05) |>
      count(.data$placement, name = "significant_n") |>
      arrange(match(.data$placement, c("Near-eye", "Chest"))) |>
      pull("significant_n"),
    c(17L, 9L)
  ),
  sum(site_activity$reporting_status == "SUPPORT_NON_ESTIMABLE") == 1L,
  all(is.na(site_activity$site_deviation_p_adjusted[
    site_activity$reporting_status != "ESTIMABLE"
  ]))
)
overall <- assessments |>
  filter(.data$diagnostic == "Overall primary mean-model assessment")
stopifnot(
  nrow(overall) == 2L,
  all(overall$assessment == "ACCEPTABLE WITH LIMITATION"),
  all(diagnostics$converged[diagnostics$scenario_id == "primary_dataset"]),
  all(diagnostics$full_rank[diagnostics$scenario_id == "primary_dataset"]),
  all(diagnostics$covariance_positive_definite[
    diagnostics$scenario_id == "primary_dataset"
  ]),
  !any(influence$primary_decision_changed),
  max(
    abs(influence$ratio_relative_change_percent[
      influence$inferential_role == "NAMED_VERSUS_HOME"
    ]),
    na.rm = TRUE
  ) <
    35
)
named_sensitivity <- sensitivity |>
  filter(
    .data$activity_code %in%
      c(
        "sleeping",
        "road_vehicle",
        "working_indoor",
        "outdoors"
      )
  )
stopifnot(
  n_distinct(named_sensitivity$scenario_id) == 8L,
  n_distinct(named_sensitivity$placement) == 2L,
  all(named_sensitivity$stability == "stable"),
  all(named_sensitivity$direction_concordant),
  all(sensitivity_tests$status == "ESTIMABLE"),
  all(sensitivity_tests$p_raw < 0.001)
)
paired_samples <- samples |>
  filter(.data$scenario_id == "paired_common_sample")
stopifnot(
  nrow(paired_samples) == 2L,
  all(paired_samples$participants == 110L),
  all(paired_samples$participant_days == 625L),
  all(paired_samples$unique_participant_hours == 14308L),
  all(paired_samples$long_rows == 15001L),
  all(abs(paired_samples$effective_weighted_hours - 14308) < 1e-10)
)

# V0 is distinct from both its current-input bridge and the repaired analysis.
stopifnot(
  isTRUE(all.equal(
    v0_comparison$long_rows[v0_comparison$implementation == "Frozen V0 model"],
    c(16801, 20327)
  )),
  isTRUE(all.equal(
    v0_comparison$long_rows[
      v0_comparison$implementation == "V0 bridge on current normalized inputs"
    ],
    c(16925, 20489)
  )),
  all(v0_models$convergence_code == 0L),
  all(v0_models$positive_definite_hessian),
  all(grepl(
    "site \\* activity_v0",
    v0_models$formula[v0_models$model_id == "v0_full_joint"]
  ))
)

# Temporal construction, thin-plate basis, runs, diagnostics, and retention.
activity_temporal_summary <- temporal_summary |>
  filter(.data$formula_id == "temporal_activity_long")
comparator_temporal_summary <- temporal_summary |>
  filter(.data$formula_id == "temporal_no_activity")
stopifnot(
  identical(
    temporal_basis$component,
    c("global time", "activity deviation", "site deviation")
  ),
  identical(temporal_basis$cyclic, c(TRUE, FALSE, FALSE)),
  all(grepl(
    "tp.smooth.spec / tprs.smooth",
    temporal_basis$marginal_basis[temporal_basis$component != "global time"],
    fixed = TRUE
  )),
  all(temporal_summary$converged),
  all(activity_temporal_summary$preliminary_warning_count == 0L),
  all(activity_temporal_summary$final_warning_count == 0L),
  all(comparator_temporal_summary$final_warning_count == 0L),
  sum(comparator_temporal_summary$preliminary_warning_count) == 1L,
  all(grepl(
    "algorithm did not converge",
    comparator_temporal_summary$preliminary_warnings[
      comparator_temporal_summary$preliminary_warning_count > 0L
    ],
    fixed = TRUE
  )),
  all(temporal_run$runs_with_duplicate_timestamps == 0L),
  all(temporal_run$mixed_activity_runs == 0L),
  all(temporal_run$mixed_participant_day_runs == 0L),
  all(temporal_run$hours_with_row_k_mismatch == 0L),
  all(temporal_run$maximum_hour_weight_error < 1e-10),
  all(temporal_run$concurrent_rows_never_lag_neighbours),
  all(temporal_retention$retained_for_context),
  all(temporal_retention$assessment == "ACCEPTABLE WITH LIMITATION"),
  all(temporal_retention$minimum_finite_k_index >= 0.70),
  all(temporal_retention$activity_model_delta_aic < -2),
  all(
    temporal_retention$activity_model_deviance_explained >
      temporal_retention$no_activity_model_deviance_explained
  ),
  all(temporal_k$resampling_replicates == 0L)
)

# Temporal uncertainty matches H03: fitted-coefficient covariance, pointwise
# intervals, zero resampling replicates, and no curve-wide inference.
temporal_curves <- bind_rows(temporal_near_curves, temporal_chest_curves)
stopifnot(
  nrow(temporal_uncertainty) == 2L,
  all(temporal_uncertainty$implementation ==
    "H03-aligned fitted-coefficient covariance"),
  all(temporal_uncertainty$interval_type ==
    "pointwise_95_percent_conditional"),
  all(grepl(
    "unconditional = TRUE",
    temporal_uncertainty$covariance_source,
    fixed = TRUE
  )),
  all(temporal_uncertainty$interval_critical_value == 1.96),
  all(temporal_uncertainty$resampling_replicates == 0L),
  all(!temporal_uncertainty$simultaneous_band),
  all(!temporal_uncertainty$curve_wide_inference),
  nrow(temporal_curves) == 2L * 6L * 49L,
  all(is.finite(temporal_curves$estimated_mel_edi_lx)),
  all(is.finite(temporal_curves$pointwise_conf_low_lx)),
  all(is.finite(temporal_curves$pointwise_conf_high_lx)),
  all(is.finite(temporal_curves$pointwise_log_se)),
  all(temporal_curves$pointwise_conf_low_lx <=
    temporal_curves$estimated_mel_edi_lx),
  all(temporal_curves$pointwise_conf_high_lx >=
    temporal_curves$estimated_mel_edi_lx),
  all(temporal_curves$pointwise_log_se >= 0),
  all(temporal_curves$interval_type ==
    "pointwise_95_percent_conditional"),
  all(temporal_curves$resampling_replicates == 0L),
  all(!temporal_curves$simultaneous_band),
  all(!temporal_curves$curve_wide_inference)
)

temporal_objects <- readRDS(artifact(
  "07_models",
  "H04",
  "H04_temporal_model_objects.rds"
))
near_probe <- h04_temporal_curves(
  temporal_objects$near_eye$activity,
  times = 0.5
) |>
  arrange(.data$display_order)
near_artifact_probe <- temporal_near_curves |>
  filter(.data$time_hour == 0.5) |>
  arrange(.data$display_order)
stopifnot(
  isTRUE(all.equal(
    near_probe$estimated_mel_edi_lx,
    near_artifact_probe$estimated_mel_edi_lx,
    tolerance = 1e-10
  )),
  isTRUE(all.equal(
    near_probe$pointwise_conf_low_lx,
    near_artifact_probe$pointwise_conf_low_lx,
    tolerance = 1e-10
  )),
  isTRUE(all.equal(
    near_probe$pointwise_conf_high_lx,
    near_artifact_probe$pointwise_conf_high_lx,
    tolerance = 1e-10
  ))
)

# Incomplete bootstrap checkpoints remain provenance only and are excluded
# from every current temporal curve and uncertainty contract.
checkpoint_directory <- artifact(
  "07_models",
  "H04",
  "temporal_bootstrap_pilot_checkpoints"
)
checkpoint_paths <- list.files(
  checkpoint_directory,
  pattern = "[.]rds$",
  full.names = TRUE
)
stopifnot(
  nrow(bootstrap_supersession) == 2L,
  sum(bootstrap_supersession$completed_checkpoint_files) ==
    length(checkpoint_paths),
  all(bootstrap_supersession$successful_checkpoint_files < 50L),
  all(grepl(
    "excluded from estimates",
    bootstrap_supersession$supersession_status,
    fixed = TRUE
  )),
  !file.exists(artifact(
    "09_tables",
    "H04",
    "H04_temporal_bootstrap_production_summary.csv"
  ))
)

# Durable source/figure pairs and report stop language.
figure_bases <- c(
  "H04_primary_category_estimates",
  "H04_site_activity_estimates",
  "H04_paired_placement_comparison",
  "H04_primary_diagnostics",
  "H04_temporal_near_eye",
  "H04_temporal_chest"
)
for (base in figure_bases) {
  stopifnot(all(file.exists(artifact(
    "10_figures",
    "H04",
    paste0(base, c(".png", ".pdf", ".svg"))
  ))))
}
qmd_path <- file.path(
  root,
  "audit/hypotheses/H04/02_implementation_and_v0_comparison.qmd"
)
html_path <- file.path(
  root,
  "audit/hypotheses/H04/02_implementation_and_v0_comparison.html"
)
stopifnot(file.exists(qmd_path), file.exists(html_path))
qmd <- readLines(qmd_path, warn = FALSE)
html <- readLines(html_path, warn = FALSE, encoding = "UTF-8")
stopifnot(
  any(grepl("primary_full = geo_medi_1h ~ site + activity", qmd, fixed = TRUE)),
  any(grepl("s(time_hour, activity, bs = 'sz', k = 12", qmd, fixed = TRUE)),
  any(grepl("s(time_hour, site, bs = 'sz', k = 12", qmd, fixed = TRUE)),
  any(grepl("weights = analysis_weight", qmd, fixed = TRUE)),
  any(grepl(
    "H03-aligned pointwise uncertainty",
    qmd,
    fixed = TRUE
  )),
  any(grepl("not simultaneous bands", qmd, fixed = TRUE)),
  any(grepl("no curve-wide inference", qmd, ignore.case = TRUE)),
  any(grepl("bootstrap is required or authorized", qmd, fixed = TRUE)),
  any(grepl("STOP.** Await explicit author approval", qmd, fixed = TRUE)),
  any(grepl("fig-alt:", qmd, fixed = TRUE)),
  !any(grepl("temperature", qmd, ignore.case = TRUE)),
  !any(grepl("production-computation gate", qmd, fixed = TRUE)),
  !any(grepl("[ F =", qmd, fixed = TRUE)),
  !any(grepl("If (hat)", qmd, fixed = TRUE)),
  any(grepl("math", html, fixed = TRUE)),
  any(grepl("Stage 2 stop", html, fixed = TRUE))
)

# The superseded bootstrap runner aborts before loading data or fitting a model.
production_guard <- readLines(
  file.path(root, "scripts/hypotheses/H04/run_h04_temporal_bootstrap.R"),
  warn = FALSE
)
stopifnot(
  any(grepl(
    "superseded by the owner's",
    production_guard,
    fixed = TRUE
  )),
  any(grepl(
    "permits no curve-wide inference",
    production_guard,
    fixed = TRUE
  ))
)

message(
  "H04 Stage 2 fitted-artifact, report, and pointwise-uncertainty contracts passed"
)
