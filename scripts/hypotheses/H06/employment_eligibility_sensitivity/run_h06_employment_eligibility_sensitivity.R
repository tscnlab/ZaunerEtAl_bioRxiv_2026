# Fit the near-eye H06 employment-eligibility sensitivity and save its audit outputs.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_modeling.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_robust_modeling.R"))

options(lifecycle_verbosity = "quiet", warn = 1)

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06_abort(
    "The H06 employment-eligibility sensitivity requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "digest", "dplyr", "openssl", "readr", "sandwich", "tibble"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h06_abort(
    "The H06 employment-eligibility sensitivity is missing package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

scenario_id <- "H06-S-EMP-NE"
run_id <- "employment_eligible__glasses__all_available"
producer <- paste0(
  "scripts/hypotheses/H06/employment_eligibility_sensitivity/",
  "run_h06_employment_eligibility_sensitivity.R"
)

roots <- list(
  model_data = file.path(
    root,
    "artifacts/06_model_data/H06/employment_eligibility_sensitivity"
  ),
  models = file.path(
    root,
    "artifacts/07_models/H06/employment_eligibility_sensitivity"
  ),
  diagnostics = file.path(
    root,
    "artifacts/08_diagnostics/H06/employment_eligibility_sensitivity"
  ),
  tables = file.path(
    root,
    "artifacts/09_tables/H06/employment_eligibility_sensitivity"
  ),
  figures = file.path(
    root,
    "artifacts/10_figures/H06/employment_eligibility_sensitivity"
  ),
  source_data = file.path(
    root,
    "artifacts/11_source_data/H06/employment_eligibility_sensitivity"
  ),
  manifests = file.path(
    root,
    "artifacts/12_manifests/H06/employment_eligibility_sensitivity"
  )
)

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (!startsWith(normalized, paste0(root, "/"))) {
    h06_abort("A sensitivity path lies outside the project root: %s", path)
  }
  substring(normalized, nchar(root) + 2L)
}

input_contract <- tibble::tribble(
  ~input_role, ~relative_path, ~expected_sha256,
  "frozen_primary_near_eye_frame",
  "artifacts/06_model_data/H06/main__glasses__all_available__frame.rds",
  "38c47329b7dc5f7e64d8c42f55629c4a6afd413f5295e44942af8068aab08f3f",
  "normalized_demographics",
  "artifacts/06_model_data/normalized_inputs/demographics.rds",
  "a11d0ff6615b51dbaa0be8c0790c1ea550750d9f1d4d7e8893609803f269dadf",
  "accepted_primary_contrasts",
  "artifacts/09_tables/H06/H06_robust_F3_practical_contrasts.csv",
  "d097ba1e640842de19e5b3d7e4ea0042453604f5259da8cb998a5f4e3afd3687",
  "accepted_primary_tests",
  "artifacts/09_tables/H06/H06_robust_wald_tests.csv",
  "43c370cb42ca4b82fb55d72bdb5c288b3c3798fbce8277d1de71e6d5d4465e93",
  "accepted_primary_site_summaries",
  "artifacts/09_tables/H06/H06_robust_site_specific_effects.csv",
  "ec2b050fe9a3d9b423845cf1e8b84eafc8b9b85ca1d6829bf4e92cc03d970da8",
  "accepted_primary_models",
  "artifacts/07_models/H06/H06_robust_core_models.rds",
  "a0247d023c94e8e8cbaf1a85faa24f41d8b89c7f56a9a71e73bb9129c8eca271",
  "site_display_registry",
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "pipeline_io",
  "scripts/pipeline/paths_io.R",
  "ad7ec3eb6fe76b0b47498d3efa0ae247ac0da3b9cd43a7d3731ea102d3bedc6c",
  "accepted_h06_contract",
  "scripts/hypotheses/H06/h06_contract.R",
  "b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f",
  "accepted_h06_preparation",
  "scripts/hypotheses/H06/h06_modeling.R",
  "0e955ec55f11fe441509c4f6872135a80347f21baa162534d589eff2f1f13fe6",
  "accepted_h06_robust_modeling",
  "scripts/hypotheses/H06/h06_robust_modeling.R",
  "277b83c34596c6a35b246879cfc4cab955e3b03031168d3e7025ecca75c041fa",
  "registration_record",
  "notebooks/preregistration_deviations.qmd",
  "b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d",
  "deviation_register",
  "audit/ledgers/deviation_register.csv",
  "87dfe055c5961f30d5dc68903c2af8389e14eab75398d0ee5d362473ce1ca131",
  "protected_h06_reader_source",
  "notebooks/hypotheses/H06.qmd",
  "013496ae4ac5db1e069af98bea87af6c202714ed97d40cf1f7f64e6637239f5a",
  "protected_h06_preparation_source",
  "audit/hypotheses/H06/H06_analysis_preparation.qmd",
  "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
  "protected_h06_stage2_source",
  "audit/hypotheses/H06/02_implementation_and_v0_comparison.qmd",
  "736926de3576a7dceaed7b92fb65f65a05d8f6d32604d533fd9eb6e45e26a36d",
  "protected_h06_reader_html",
  "_build/nathealth/notebooks/hypotheses/H06.html",
  "bf3f70118afca9264aba77f9483a1cdd783e3c43996c9049fce67780ceca539b",
  "protected_h06_preparation_html",
  "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html",
  "ae3dd53c5c3947e163a6048807f1e639197548e8e824c9d52709da3a65f74683"
) |>
  dplyr::mutate(path = file.path(root, .data$relative_path))

input_audit <- input_contract |>
  dplyr::rowwise() |>
  dplyr::mutate(
    exists = file.exists(.data$path),
    observed_sha256 = if (.data$exists) artifact_sha256(.data$path) else NA_character_,
    hash_verified = .data$exists && identical(
      .data$observed_sha256,
      .data$expected_sha256
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::select(
    .data$input_role,
    .data$relative_path,
    .data$expected_sha256,
    .data$observed_sha256,
    .data$exists,
    .data$hash_verified
  )
if (any(!input_audit$hash_verified)) {
  h06_abort(
    "A frozen H06 employment-sensitivity input differs from its pin: %s",
    paste(input_audit$input_role[!input_audit$hash_verified], collapse = ", ")
  )
}

input_path <- function(role) {
  matches <- input_contract$path[input_contract$input_role == role]
  if (length(matches) != 1L) {
    h06_abort("The sensitivity input role `%s` is not unique", role)
  }
  matches
}

primary_frame <- readRDS(input_path("frozen_primary_near_eye_frame"))
demographics <- readRDS(input_path("normalized_demographics"))
primary_contrasts <- readr::read_csv(
  input_path("accepted_primary_contrasts"),
  show_col_types = FALSE,
  na = ""
)
primary_tests <- readr::read_csv(
  input_path("accepted_primary_tests"),
  show_col_types = FALSE,
  na = ""
)
primary_site_summaries <- readr::read_csv(
  input_path("accepted_primary_site_summaries"),
  show_col_types = FALSE,
  na = ""
)
site_registry <- readr::read_csv(
  input_path("site_display_registry"),
  show_col_types = FALSE,
  na = ""
) |>
  dplyr::arrange(.data$display_order)

required_demographic_columns <- c("site", "Id", "employment_status")
missing_demographic_columns <- setdiff(
  required_demographic_columns,
  names(demographics)
)
if (length(missing_demographic_columns) > 0L) {
  h06_abort(
    "Normalized demographics lack required field(s): %s",
    paste(missing_demographic_columns, collapse = ", ")
  )
}
if (anyDuplicated(demographics[c("site", "Id")])) {
  h06_abort("Normalized demographics contain duplicate site-participant keys")
}

participant_registry <- primary_frame |>
  dplyr::distinct(.data$site, .data$Id, .data$participant_key) |>
  dplyr::mutate(site = as.character(.data$site)) |>
  dplyr::left_join(
    demographics |>
      dplyr::transmute(
        site = as.character(.data$site),
        .data$Id,
        employment_status = as.character(.data$employment_status)
      ),
    by = c("site", "Id"),
    relationship = "many-to-one"
  )
if (anyNA(participant_registry$employment_status)) {
  h06_abort("At least one primary near-eye participant lacks employment status")
}

excluded_statuses <- c(
  "Not employed",
  "Marginally employed (Minijob)"
)
excluded_participants <- participant_registry |>
  dplyr::filter(.data$employment_status %in% .env$excluded_statuses)
if (nrow(excluded_participants) != 6L) {
  h06_abort(
    "The employment rule selected %d near-eye participants; expected 6",
    nrow(excluded_participants)
  )
}

participant_key_hash <- function(key) {
  vapply(
    as.character(key),
    digest::digest,
    character(1),
    algo = "sha256",
    serialize = FALSE
  )
}

excluded_key <- as.character(excluded_participants$participant_key)
remove_row <- as.character(primary_frame$participant_key) %in% excluded_key
excluded_hours <- sum(remove_row)
excluded_days <- dplyr::n_distinct(
  primary_frame$participant_day_key[remove_row]
)
if (excluded_hours != 725L || excluded_days != 31L) {
  h06_abort(
    paste0(
      "The employment exclusions remove %d hours and %d participant-days; ",
      "expected 725 and 31"
    ),
    excluded_hours,
    excluded_days
  )
}

sensitivity_frame <- primary_frame |>
  dplyr::filter(
    !as.character(.data$participant_key) %in% .env$excluded_key
  ) |>
  h06_refactor_frame()

expected_sample <- c(
  observations = 15871L,
  participant_days = 684L,
  participants = 131L,
  sites = 9L
)
observed_sample <- c(
  observations = nrow(sensitivity_frame),
  participant_days = dplyr::n_distinct(sensitivity_frame$participant_day_key),
  participants = dplyr::n_distinct(sensitivity_frame$participant_key),
  sites = dplyr::n_distinct(sensitivity_frame$site)
)
if (!identical(as.integer(observed_sample), as.integer(expected_sample))) {
  h06_abort(
    "The employment-eligible near-eye sample differs from the approved count contract"
  )
}
if (!identical(levels(sensitivity_frame$site), site_registry$site)) {
  h06_abort("The employment sensitivity lost or reordered a study site")
}
if (!identical(
  levels(sensitivity_frame$work_free_day),
  levels(primary_frame$work_free_day)
)) {
  h06_abort("The employment sensitivity changed the day-type factor levels")
}
if (!identical(
  levels(sensitivity_frame$activity_status),
  levels(primary_frame$activity_status)
)) {
  h06_abort("The employment sensitivity changed the activity factor levels")
}

category_cells <- h06_category_cells(sensitivity_frame, run_id)
minimum_daytype_hours <- min(
  category_cells$one_hour_observations[
    category_cells$cell_type == "work_free_day"
  ]
)
minimum_activity_hours <- min(
  category_cells$one_hour_observations[
    category_cells$cell_type == "activity_status"
  ]
)
if (minimum_daytype_hours != 187L || minimum_activity_hours != 180L) {
  h06_abort(
    paste0(
      "Minimum day-type/activity cell support is %d/%d hours; ",
      "expected 187/180"
    ),
    minimum_daytype_hours,
    minimum_activity_hours
  )
}

design_diagnostics <- h06_design_diagnostics(sensitivity_frame, run_id)
if (!isTRUE(design_diagnostics$full_rank) ||
    design_diagnostics$design_columns != 36L) {
  h06_abort("The employment-sensitivity full model matrix is not full rank")
}

formulas <- h06_formula_set()
formula_registry <- tibble::tibble(
  scenario_id = scenario_id,
  model_role = c("additive", "full"),
  wilkinson_formula = vapply(
    formulas[c("additive", "full")],
    h06_formula_text,
    character(1)
  ),
  family = "quasi-Poisson",
  link = "log",
  covariance = "participant-cluster HC3",
  denominator_df = "number of participant clusters minus 1",
  site_contrast = "contr.sum",
  binary_predictor_contrast = "treatment, first level as reference"
)

additive <- h06_fit_marginal(
  sensitivity_frame,
  formulas$additive,
  working_power = 1
)
full <- h06_fit_marginal(
  sensitivity_frame,
  formulas$full,
  working_power = 1
)

fit_diagnostics <- dplyr::bind_rows(
  h06_fit_diagnostics_robust(additive, run_id, "additive"),
  h06_fit_diagnostics_robust(full, run_id, "full")
)
if (nrow(fit_diagnostics) != 2L ||
    any(!fit_diagnostics$converged) ||
    any(!fit_diagnostics$full_rank) ||
    any(!fit_diagnostics$finite_coefficients) ||
    any(!fit_diagnostics$hc3_covariance_finite) ||
    any(!fit_diagnostics$hc3_covariance_positive_definite) ||
    any(!fit_diagnostics$numerical_gate_pass)) {
  h06_abort("An employment-sensitivity model failed its numerical gate")
}

covariance_diagnostics <- dplyr::bind_rows(
  h06_covariance_diagnostic_rows(additive, run_id, "additive"),
  h06_covariance_diagnostic_rows(full, run_id, "full")
)
if (nrow(covariance_diagnostics) != 8L ||
    any(!covariance_diagnostics$finite) ||
    any(!covariance_diagnostics$positive_definite)) {
  h06_abort("An employment-sensitivity covariance failed its numerical gate")
}

cluster_diagnostics <- dplyr::bind_rows(
  h06_cluster_diagnostics(additive, run_id, "additive"),
  h06_cluster_diagnostics(full, run_id, "full")
) |>
  dplyr::mutate(
    participant_key_sha256 = participant_key_hash(.data$participant_key)
  ) |>
  dplyr::select(-.data$participant_key)

residual_outputs <- lapply(
  c("additive", "full"),
  function(model_role) {
    bundle <- if (model_role == "additive") additive else full
    h06_residual_outputs(bundle, run_id, model_role)
  }
)
names(residual_outputs) <- c("additive", "full")
residual_calibration <- dplyr::bind_rows(lapply(
  residual_outputs,
  `[[`,
  "calibration"
))
residual_fitted_bins <- dplyr::bind_rows(lapply(
  residual_outputs,
  `[[`,
  "fitted_bins"
))
residual_clock <- dplyr::bind_rows(lapply(
  residual_outputs,
  `[[`,
  "clock"
))
residual_acf <- dplyr::bind_rows(lapply(
  residual_outputs,
  `[[`,
  "acf"
))

response_distribution <- sensitivity_frame |>
  dplyr::summarise(
    scenario_id = scenario_id,
    run_id = run_id,
    observations = dplyr::n(),
    exact_zero_hours = sum(.data$response_value == 0),
    exact_zero_fraction = mean(.data$response_value == 0),
    minimum = min(.data$response_value),
    q01 = unname(stats::quantile(.data$response_value, 0.01)),
    median = stats::median(.data$response_value),
    q99 = unname(stats::quantile(.data$response_value, 0.99)),
    maximum = max(.data$response_value)
  )

tests <- h06_primary_tests(
  additive,
  full,
  run_id,
  "H06-S-EMP-NE-main",
  "H06-S-EMP-NE-heterogeneity"
)
wald_tests <- dplyr::bind_rows(tests$main, tests$heterogeneity) |>
  dplyr::mutate(
    scenario_id = scenario_id,
    family_scope = dplyr::if_else(
      .data$test_role == "additive_main_association",
      "counterpart to the frozen three-test primary near-eye family",
      "counterpart to the frozen three-test near-eye site-heterogeneity family"
    ),
    .before = 1L
  )
if (nrow(wald_tests) != 6L ||
    any(table(wald_tests$family_id) != 3L) ||
    any(wald_tests$status != "ESTIMABLE") ||
    any(wald_tests$planned_size != 3L) ||
    any(wald_tests$available_rank != 3L)) {
  h06_abort("The employment sensitivity changed or failed a multiplicity family")
}

effects <- h06_core_estimands(
  additive,
  run_id,
  distribution = "equal_site"
) |>
  h06_f3_family() |>
  dplyr::mutate(
    scenario_id = scenario_id,
    family_id = "H06-S-EMP-NE-practical-contrasts",
    family_scope = "counterpart to the frozen three practical near-eye contrasts",
    .before = 1L
  )
if (nrow(effects) != 3L ||
    any(effects$status != "ESTIMABLE") ||
    any(effects$planned_size != 3L) ||
    any(effects$available_rank != 3L)) {
  h06_abort("The employment-sensitivity practical contrasts are incomplete")
}

reference_mean <- h06_reference_mean(
  additive,
  run_id,
  distribution = "equal_site"
) |>
  dplyr::mutate(scenario_id = scenario_id, .before = 1L)

site_summaries <- h06_core_estimands(
  full,
  run_id,
  model_role = "full",
  distribution = "equal_site",
  site_specific = TRUE
) |>
  dplyr::transmute(
    scenario_id = scenario_id,
    .data$run_id,
    .data$model_role,
    .data$predictor_id,
    .data$effect_id,
    .data$site,
    .data$log_estimate,
    .data$log_standard_error,
    .data$estimate_ratio,
    .data$conf_low_ratio,
    .data$conf_high_ratio,
    .data$denominator_df,
    .data$status,
    inferential_role = paste(
      "prespecified descriptive site-specific ratio and 95% CI;",
      "no new multiplicity family"
    )
  )
if (nrow(site_summaries) != 27L ||
    any(site_summaries$status != "ESTIMABLE")) {
  h06_abort("The employment-sensitivity site-specific summaries are incomplete")
}

primary_equal <- primary_contrasts |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$distribution == "equal_site"
  )
if (nrow(primary_equal) != 3L) {
  h06_abort("The frozen primary contrast comparator does not contain three rows")
}
effect_comparison <- h06_compare_effect_sets(
  primary_equal,
  effects,
  "frozen_primary_vs_employment_eligible_near_eye"
) |>
  dplyr::mutate(
    scenario_id = scenario_id,
    detailed_stability_classification = .data$stability_classification,
    stability_classification = dplyr::case_when(
      .data$detailed_stability_classification ==
        "stable within model uncertainty" ~ "stable",
      .data$detailed_stability_classification %in%
        c("precision-sensitive", "magnitude-sensitive") ~
        "quantitatively sensitive",
      .data$detailed_stability_classification %in%
        c("direction-sensitive", "multiplicity-conclusion-sensitive") ~
        "qualitatively sensitive",
      .data$detailed_stability_classification == "non-estimable" ~
        "non-estimable",
      TRUE ~ "inconclusive"
    ),
    .before = 1L
  )

primary_heterogeneity <- primary_tests |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$family_id == "H06-F2-heterogeneity"
  ) |>
  dplyr::select(
    .data$predictor_id,
    primary_f_statistic = .data$f_statistic,
    primary_df1 = .data$restrictions,
    primary_df2 = .data$denominator_df,
    primary_p_raw = .data$p_raw,
    primary_p_adjusted = .data$p_adjusted,
    primary_adjusted_supported = .data$adjusted_significant_0_05
  )
sensitivity_heterogeneity <- tests$heterogeneity |>
  dplyr::select(
    .data$predictor_id,
    sensitivity_f_statistic = .data$f_statistic,
    sensitivity_df1 = .data$restrictions,
    sensitivity_df2 = .data$denominator_df,
    sensitivity_p_raw = .data$p_raw,
    sensitivity_p_adjusted = .data$p_adjusted,
    sensitivity_adjusted_supported = .data$adjusted_significant_0_05,
    sensitivity_status = .data$status
  )
heterogeneity_comparison <- dplyr::left_join(
  primary_heterogeneity,
  sensitivity_heterogeneity,
  by = "predictor_id",
  relationship = "one-to-one"
) |>
  dplyr::mutate(
    scenario_id = scenario_id,
    adjusted_conclusion_changed =
      .data$primary_adjusted_supported !=
        .data$sensitivity_adjusted_supported,
    interpretation_rule = paste(
      "Assess together with site-specific magnitudes, intervals,",
      "sample composition, and diagnostics; a p-value crossing alone",
      "does not determine overall stability"
    ),
    .before = 1L
  )
if (nrow(heterogeneity_comparison) != 3L ||
    any(heterogeneity_comparison$sensitivity_status != "ESTIMABLE")) {
  h06_abort("The site-heterogeneity comparison is incomplete")
}

primary_sites <- primary_site_summaries |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$model_role == "full",
    .data$distribution == "equal_site",
    .data$site_specific
  ) |>
  dplyr::select(
    .data$predictor_id,
    .data$site,
    primary_log_estimate = .data$log_estimate,
    primary_log_standard_error = .data$log_standard_error,
    primary_ratio = .data$estimate_ratio,
    primary_conf_low = .data$conf_low_ratio,
    primary_conf_high = .data$conf_high_ratio
  )
site_comparison <- dplyr::left_join(
  primary_sites,
  site_summaries |>
    dplyr::select(
      .data$predictor_id,
      .data$site,
      sensitivity_log_estimate = .data$log_estimate,
      sensitivity_log_standard_error = .data$log_standard_error,
      sensitivity_ratio = .data$estimate_ratio,
      sensitivity_conf_low = .data$conf_low_ratio,
      sensitivity_conf_high = .data$conf_high_ratio
    ),
  by = c("predictor_id", "site"),
  relationship = "one-to-one"
) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    scenario_id = scenario_id,
    log_estimate_difference =
      .data$sensitivity_log_estimate - .data$primary_log_estimate,
    detailed_stability_classification = h06_stability_class(
      .data$primary_log_estimate,
      log(.data$primary_conf_low),
      log(.data$primary_conf_high),
      .data$sensitivity_log_estimate,
      log(.data$sensitivity_conf_low),
      log(.data$sensitivity_conf_high)
    ),
    .before = 1L
  ) |>
  dplyr::ungroup()
if (nrow(site_comparison) != 27L || anyNA(site_comparison$sensitivity_ratio)) {
  h06_abort("The site-specific primary-sensitivity comparison is incomplete")
}

primary_summary <- h06_sample_summary(
  primary_frame,
  "frozen_primary_near_eye"
)
sensitivity_summary <- h06_sample_summary(sensitivity_frame, run_id)
sample_flow <- dplyr::bind_rows(primary_summary, sensitivity_summary) |>
  dplyr::mutate(
    scenario_id = c("H06-primary-near-eye", scenario_id),
    scenario_label = c(
      "Frozen primary near-eye sample",
      "Employment-eligible near-eye sample"
    ),
    comparison_role = c("frozen comparator", "sensitivity"),
    retained_hour_fraction = .data$one_hour_observations /
      primary_summary$one_hour_observations,
    retained_day_fraction = .data$participant_days /
      primary_summary$participant_days,
    retained_participant_fraction = .data$participants /
      primary_summary$participants,
    .before = 1L
  )

exclusion_audit <- excluded_participants |>
  dplyr::transmute(
    scenario_id = scenario_id,
    participant_key_sha256 = participant_key_hash(.data$participant_key),
    site = .data$site,
    employment_status = .data$employment_status
  ) |>
  dplyr::left_join(
    primary_frame |>
      dplyr::filter(
        as.character(.data$participant_key) %in% .env$excluded_key
      ) |>
      dplyr::summarise(
        excluded_supported_hours = dplyr::n(),
        excluded_participant_days = dplyr::n_distinct(
          .data$participant_day_key
        ),
        .by = "participant_key"
      ) |>
      dplyr::mutate(
        participant_key_sha256 = participant_key_hash(.data$participant_key)
      ) |>
      dplyr::select(
        .data$participant_key_sha256,
        .data$excluded_supported_hours,
        .data$excluded_participant_days
      ),
    by = "participant_key_sha256",
    relationship = "one-to-one"
  ) |>
  dplyr::arrange(.data$site, .data$participant_key_sha256)
if (nrow(exclusion_audit) != 6L ||
    sum(exclusion_audit$excluded_supported_hours) != 725L ||
    sum(exclusion_audit$excluded_participant_days) != 31L ||
    any(grepl("::", exclusion_audit$participant_key_sha256, fixed = TRUE))) {
  h06_abort("The protected employment-exclusion audit is invalid")
}

scenario_contract <- tibble::tribble(
  ~scenario_id, ~scenario_label, ~scenario_family, ~primary_axis_changed,
  ~change_from_primary, ~invariants, ~estimand_id, ~sample_strategy,
  ~metric_set_id, ~model_spec_id, ~anticipated_failure_conditions,
  scenario_id,
  "Near-eye employment-eligibility sensitivity",
  "participant eligibility",
  "employment status",
  paste(
    "Remove all hours from near-eye participants recorded as Not employed",
    "or Marginally employed (Minijob); do not apply an age exclusion"
  ),
  paste(
    "Frozen supported-hour outcome and rows before participant exclusion;",
    "predictors; reference levels; sites; equal-site contrasts; exact",
    "additive/full formulas; quasi-Poisson log mean; participant-cluster",
    "HC3; finite-cluster df; three-member BH families"
  ),
  "expected supported-hour near-eye zero-aware geometric mean melEDI",
  "scenario-specific sample; no redundant common-sample refit",
  "supported-hour zero-aware geometric mean melEDI",
  "H06 accepted additive and predictor-by-site quasi-Poisson models",
  paste(
    "input drift; counts other than 6/725/31 or 15871/684/131/9;",
    "site or factor-level loss; rank, convergence, covariance,",
    "standardization, or multiplicity failure"
  )
)

package_versions <- tibble::tibble(
  package = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)

model_record <- function(bundle) {
  list(
    fit = bundle$fit,
    formula = bundle$formula,
    working_power = bundle$working_power,
    covariance = bundle$covariance,
    fit_warnings = bundle$fit_warnings,
    fit_error = bundle$fit_error,
    elapsed_seconds = bundle$elapsed_seconds,
    observations = nrow(bundle$data),
    participants = dplyr::n_distinct(bundle$data$participant_key),
    participant_days = dplyr::n_distinct(bundle$data$participant_day_key),
    sites = dplyr::n_distinct(bundle$data$site)
  )
}

model_object <- list(
  scenario_id = scenario_id,
  run_id = run_id,
  input_frame_sha256 = h06_model_frame_hash(primary_frame),
  sensitivity_frame_sha256 = h06_model_frame_hash(sensitivity_frame),
  excluded_participant_key_sha256 = exclusion_audit$participant_key_sha256,
  formulas = formulas[c("additive", "full")],
  additive = model_record(additive),
  full = model_record(full)
)

invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

write_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}
write_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

write_csv(
  input_audit,
  file.path(roots$model_data, "H06_employment_eligibility_input_audit.csv")
)
write_csv(
  scenario_contract,
  file.path(roots$model_data, "H06_employment_eligibility_scenario_contract.csv")
)
write_csv(
  sample_flow,
  file.path(roots$model_data, "H06_employment_eligibility_sample_flow.csv")
)
write_csv(
  exclusion_audit,
  file.path(roots$model_data, "H06_employment_eligibility_exclusion_audit.csv")
)
write_csv(
  category_cells,
  file.path(roots$model_data, "H06_employment_eligibility_category_cells.csv")
)
write_csv(
  design_diagnostics,
  file.path(roots$model_data, "H06_employment_eligibility_design_diagnostics.csv")
)
write_csv(
  formula_registry,
  file.path(roots$model_data, "H06_employment_eligibility_formula_registry.csv")
)
write_csv(
  package_versions,
  file.path(roots$model_data, "H06_employment_eligibility_package_versions.csv")
)
write_rds(
  model_object,
  file.path(roots$models, "H06_employment_eligibility_models.rds")
)
write_csv(
  fit_diagnostics,
  file.path(roots$diagnostics, "H06_employment_eligibility_fit_diagnostics.csv")
)
write_csv(
  covariance_diagnostics,
  file.path(roots$diagnostics, "H06_employment_eligibility_covariance_diagnostics.csv")
)
write_csv(
  cluster_diagnostics,
  file.path(roots$diagnostics, "H06_employment_eligibility_cluster_diagnostics.csv")
)
write_csv(
  response_distribution,
  file.path(roots$diagnostics, "H06_employment_eligibility_response_distribution.csv")
)
write_csv(
  residual_calibration,
  file.path(roots$diagnostics, "H06_employment_eligibility_residual_calibration.csv")
)
write_csv(
  residual_fitted_bins,
  file.path(roots$diagnostics, "H06_employment_eligibility_residual_fitted_bins.csv")
)
write_csv(
  residual_clock,
  file.path(roots$diagnostics, "H06_employment_eligibility_residual_clock.csv")
)
write_csv(
  residual_acf,
  file.path(roots$diagnostics, "H06_employment_eligibility_residual_acf.csv")
)
write_csv(
  effects,
  file.path(roots$tables, "H06_employment_eligibility_effects.csv")
)
write_csv(
  wald_tests,
  file.path(roots$tables, "H06_employment_eligibility_wald_tests.csv")
)
write_csv(
  reference_mean,
  file.path(roots$tables, "H06_employment_eligibility_reference_mean.csv")
)
write_csv(
  site_summaries,
  file.path(roots$tables, "H06_employment_eligibility_site_summaries.csv")
)
write_csv(
  effect_comparison,
  file.path(roots$tables, "H06_employment_eligibility_effect_comparison.csv")
)
write_csv(
  heterogeneity_comparison,
  file.path(roots$tables, "H06_employment_eligibility_heterogeneity_comparison.csv")
)
write_csv(
  site_comparison,
  file.path(roots$tables, "H06_employment_eligibility_site_comparison.csv")
)

manifest_path <- file.path(
  roots$manifests,
  "H06_employment_eligibility_analysis_manifest.csv"
)
manifest_files <- sort(unique(c(
  unlist(lapply(
    roots[names(roots) != "manifests"],
    list.files,
    recursive = TRUE,
    full.names = TRUE
  )),
  list.files(roots$manifests, full.names = TRUE),
  file.path(root, producer),
  file.path(
    root,
    "tests/hypotheses/H06/employment_eligibility_sensitivity/",
    "test_h06_employment_eligibility_sensitivity.R"
  )
)))
manifest_files <- manifest_files[
  file.exists(manifest_files) &
    !dir.exists(manifest_files) &
    normalizePath(
      manifest_files,
      winslash = "/",
      mustWork = TRUE
    ) != normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
]
analysis_manifest <- dplyr::bind_rows(lapply(manifest_files, function(path) {
  info <- file.info(path)
  tibble::tibble(
    scenario_id = scenario_id,
    path = relative_path(path),
    sha256 = artifact_sha256(path),
    bytes = as.numeric(info$size),
    artifact_type = tools::file_ext(path),
    producer = producer,
    r_version = as.character(getRversion()),
    written_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
  )
}))
manifest_relative_path <- substring(
  normalizePath(manifest_path, winslash = "/", mustWork = FALSE),
  nchar(root) + 2L
)
if (anyDuplicated(analysis_manifest$path) ||
    any(analysis_manifest$path == manifest_relative_path)) {
  h06_abort("The employment-sensitivity analysis manifest is circular or duplicated")
}
write_csv(analysis_manifest, manifest_path)

message(
  paste0(
    "H06-S-EMP-NE complete: ",
    nrow(sensitivity_frame),
    " hours, ",
    dplyr::n_distinct(sensitivity_frame$participant_day_key),
    " participant-days, ",
    dplyr::n_distinct(sensitivity_frame$participant_key),
    " participants"
  )
)
