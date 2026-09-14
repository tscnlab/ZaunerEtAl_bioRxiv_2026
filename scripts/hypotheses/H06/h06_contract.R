# Define the accepted H06-002 model and H06-003 Stage 3 provenance contract.

h06_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h06_activity_levels <- function() {
  c(
    "Sedentary (no reported exercise)",
    "Active (light, moderate, or vigorous exercise)"
  )
}

h06_exercise_intensity_levels <- function() {
  c("No exercise", "Light", "Moderate", "Vigorous")
}

h06_predictor_registry <- function() {
  tibble::tribble(
    ~predictor_order,
    ~predictor_id,
    ~reader_name,
    ~role,
    1L,
    "work_free_day",
    "Work day versus free day",
    "primary",
    2L,
    "activity_status",
    "Sedentary versus active",
    "primary",
    3L,
    "previous_sleep_duration_centered_h",
    "Previous sleep duration",
    "primary",
    4L,
    "weekday_weekend",
    "Weekday versus weekend",
    "sensitivity",
    5L,
    "exercise_location",
    "Exercise location",
    "exploratory",
    6L,
    "active_commute_h",
    "Walking/cycling travel time",
    "exploratory",
    7L,
    "sedentary_h",
    "Sitting/reclining time",
    "exploratory",
    8L,
    "previous_sleep_onset_centered_h",
    "Previous sleep onset",
    "exploratory",
    9L,
    "wake_centered_h",
    "Final wake time",
    "exploratory"
  )
}

h06_formula_set <- function() {
  list(
    base = stats::as.formula("response_value ~ site"),
    additive = stats::as.formula(paste(
      "response_value ~ site + work_free_day + activity_status +",
      "previous_sleep_duration_centered_h"
    )),
    additive_no_daytype = stats::as.formula(paste(
      "response_value ~ site + activity_status +",
      "previous_sleep_duration_centered_h"
    )),
    additive_no_activity = stats::as.formula(paste(
      "response_value ~ site + work_free_day +",
      "previous_sleep_duration_centered_h"
    )),
    additive_no_sleep = stats::as.formula(paste(
      "response_value ~ site + work_free_day + activity_status"
    )),
    full = stats::as.formula(paste(
      "response_value ~ site * work_free_day + site * activity_status +",
      "site * previous_sleep_duration_centered_h"
    )),
    full_no_daytype_interaction = stats::as.formula(paste(
      "response_value ~ site + work_free_day + activity_status +",
      "previous_sleep_duration_centered_h +",
      "site:(activity_status + previous_sleep_duration_centered_h)"
    )),
    full_no_activity_interaction = stats::as.formula(paste(
      "response_value ~ site + work_free_day + activity_status +",
      "previous_sleep_duration_centered_h +",
      "site:(work_free_day + previous_sleep_duration_centered_h)"
    )),
    full_no_sleep_interaction = stats::as.formula(paste(
      "response_value ~ site + work_free_day + activity_status +",
      "previous_sleep_duration_centered_h +",
      "site:(work_free_day + activity_status)"
    )),
    weekend_additive = stats::as.formula(paste(
      "response_value ~ site + weekday_weekend + activity_status +",
      "previous_sleep_duration_centered_h"
    ))
  )
}

h06_exploratory_formula_set <- function() {
  list(
    exercise_location_active_days = stats::as.formula(paste(
      "response_value ~ site + work_free_day + exercise_location +",
      "previous_sleep_duration_centered_h"
    )),
    active_travel = stats::as.formula(paste(
      "response_value ~ site + work_free_day + activity_status +",
      "previous_sleep_duration_centered_h + active_commute_h"
    )),
    sedentary_time = stats::as.formula(paste(
      "response_value ~ site + work_free_day + activity_status +",
      "previous_sleep_duration_centered_h + sedentary_h"
    )),
    previous_sleep_onset = stats::as.formula(paste(
      "response_value ~ site + work_free_day + activity_status +",
      "previous_sleep_duration_centered_h +",
      "previous_sleep_onset_centered_h"
    )),
    final_wake = stats::as.formula(paste(
      "response_value ~ site + work_free_day + activity_status +",
      "previous_sleep_duration_centered_h + wake_centered_h"
    ))
  )
}

h06_gamm_formula <- function() {
  stats::as.formula(paste(
    "log10_melEDI_offset ~ site + work_free_day * activity_status +",
    "previous_sleep_duration_centered_h +",
    "s(clock_hour, by = day_activity_group, bs = 'cc', k = 16, id = 1) +",
    "s(participant_key, bs = 're') +",
    "s(participant_day_key, bs = 're')"
  ))
}

h06_day_activity_levels <- function() {
  c(
    "Work day · Sedentary",
    "Work day · Active",
    "Free day · Sedentary",
    "Free day · Active"
  )
}

h06_day_activity_group <- function(work_free_day, activity_status) {
  work_free_day <- as.character(work_free_day)
  activity_status <- as.character(activity_status)
  activity_short <- ifelse(
    grepl("^Sedentary", activity_status),
    "Sedentary",
    ifelse(grepl("^Active", activity_status), "Active", NA_character_)
  )
  group <- paste(work_free_day, activity_short, sep = " · ")
  invalid <- is.na(work_free_day) |
    is.na(activity_short) |
    !group %in% h06_day_activity_levels()
  if (any(invalid)) {
    h06_abort(
      paste(
        "The exploratory time-of-day model received an unsupported",
        "work/free-day or activity-status value"
      )
    )
  }
  factor(group, levels = h06_day_activity_levels())
}

h06_exploratory_two_part_gamm_terms <- function(
  k = 12L,
  random_effects = TRUE
) {
  if (length(k) != 1L || !is.finite(k) || k < 5L || k != as.integer(k)) {
    h06_abort(
      "The exploratory two-part GAM basis dimension must be one integer >= 5"
    )
  }
  terms <- c(
    "site",
    "work_free_day * activity_status",
    sprintf(
      paste0(
        "s(clock_hour, by = day_activity_group, bs = 'cc', ",
        "k = %d, id = 1)"
      ),
      as.integer(k)
    )
  )
  if (isTRUE(random_effects)) {
    terms <- c(
      terms,
      "s(participant_key, bs = 're')",
      "s(participant_day_key, bs = 're')"
    )
  }
  paste(terms, collapse = " + ")
}

h06_exploratory_two_part_gamm_formulas <- function(k = 12L) {
  smooth_terms <- h06_exploratory_two_part_gamm_terms(
    k = k,
    random_effects = TRUE
  )
  make_formula <- function(response) {
    stats::as.formula(paste(
      response,
      "~ previous_sleep_duration_centered_h +",
      smooth_terms
    ))
  }
  list(
    occurrence = make_formula("melEDI_positive"),
    positive_magnitude = make_formula("response_value")
  )
}

h06_exploratory_two_part_fixed_smooth_formulas <- function(k = 12L) {
  smooth_terms <- h06_exploratory_two_part_gamm_terms(
    k = k,
    random_effects = FALSE
  )
  make_formula <- function(response) {
    stats::as.formula(paste(
      response,
      "~ previous_sleep_duration_centered_h +",
      smooth_terms
    ))
  }
  list(
    occurrence = make_formula("melEDI_positive"),
    positive_magnitude = make_formula("response_value")
  )
}

h06_run_registry <- function() {
  tibble::tribble(
    ~run_order,
    ~run_id,
    ~data_scenario_id,
    ~placement,
    ~sample_scenario,
    ~analytical_role,
    ~fit_comparisons,
    1L,
    "main__glasses__all_available",
    "main",
    "glasses",
    "all_available",
    "primary_near_eye",
    TRUE,
    2L,
    "main__chest__all_available",
    "main",
    "chest",
    "all_available",
    "contextual_chest_all_available",
    FALSE,
    3L,
    "main__glasses__paired_common",
    "main",
    "glasses",
    "paired_common",
    "paired_near_eye",
    FALSE,
    4L,
    "main__chest__paired_common",
    "main",
    "chest",
    "paired_common",
    "paired_chest",
    FALSE,
    5L,
    "gap_timing_unaware__glasses__all_available",
    "gap_timing_unaware",
    "glasses",
    "all_available",
    "required_gap_near_eye",
    TRUE,
    6L,
    "gap_timing_unaware__chest__all_available",
    "gap_timing_unaware",
    "chest",
    "all_available",
    "contextual_gap_chest",
    FALSE
  )
}

h06_multiplicity_registry <- function() {
  tibble::tribble(
    ~family_order,
    ~family_id,
    ~content,
    ~planned_size,
    ~method,
    1L,
    "H06-F1-main",
    "Primary near-eye main-association tests",
    3L,
    "BH",
    2L,
    "H06-F2-heterogeneity",
    "Primary near-eye site-heterogeneity tests",
    3L,
    "BH",
    3L,
    "H06-F3-practical-contrasts",
    "Primary equal-site practical contrasts",
    3L,
    "BH",
    4L,
    "H06-F1-gap",
    "Gap-timing-unaware near-eye main tests",
    3L,
    "BH",
    5L,
    "H06-F2-gap",
    "Gap-timing-unaware near-eye heterogeneity tests",
    3L,
    "BH"
  )
}

h06_input_contract <- function(root) {
  tibble::tribble(
    ~input_role,
    ~relative_path,
    ~expected_sha256,
    "primary_near_eye_hourly",
    "artifacts/06_model_data/base/metrics_glasses_one_hour_context.rds",
    "7591bcfaae4b49fdde2053160848e170895092b223f96108e538066ce210a951",
    "complementary_chest_hourly",
    "artifacts/06_model_data/base/metrics_chest_one_hour_context.rds",
    "18134eec529c36e5fd47c7b3bb1e3b909628b97986cd91eff8e59ee9b5343cbb",
    "gap_timing_unaware_hourly",
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/one_hour_data.rds",
    "3c9a44d67d3267a3daa2a1392b096bdd89d80d62155edc44bdfe6c048ac4c105",
    "normalized_exercise_diary",
    "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
    "5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107",
    "normalized_sleep_diary",
    "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
    "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
    "temporal_provenance",
    "artifacts/06_model_data/temporal_provenance/wall_outcome_links.csv",
    "0e8baf5e7548efff60c2cc2c4eda3418dfcddb02b5523acb30506f8a77890850",
    "site_display_registry",
    "config/site_display_registry.csv",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "model_input_source_pins",
    "config/model_input_source_pins.csv",
    "3fbf9f40125c60e1d0779d2b2d524e79534597586c60ec236a1ce16299e18831",
    "current_base_model_manifest",
    "artifacts/12_manifests/base_model_data_artifacts.csv",
    "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
    "approved_stage1_source",
    "audit/hypotheses/H06/01_audit_and_plan.qmd",
    "393fd87c908302c1681925dcc451b27be31e652758592da8a81c775ff09aaf26",
    "approved_stage1_render",
    "audit/hypotheses/H06/01_audit_and_plan.html",
    "186ab355deb0ba41f276c55c0490e9e0edbe7be1060c40fe2f4c366ed8eee8ae",
    "stage2_gate_decision",
    "audit/decisions/h06_stage1a_gate_and_stage2_transition.md",
    "882057ec11ce5e6a56d5b7268b3b501d372c2ec5a34de21a1ef0fa4ebcf07a52",
    "approved_stage2_source",
    "audit/hypotheses/H06/02_implementation_and_v0_comparison.qmd",
    "736926de3576a7dceaed7b92fb65f65a05d8f6d32604d533fd9eb6e45e26a36d",
    "approved_stage2_render",
    "audit/hypotheses/H06/02_implementation_and_v0_comparison.html",
    "eea3da853bb23db96a59759d11a8f7eeb838e2e42960bf71ab96830030289b75",
    "approved_stage2_manifest",
    "artifacts/12_manifests/H06/H06_stage2_artifacts.csv",
    "2407f2045d960be1025dbd5e338d0df9a733bd4caf2afc29f16a9680fb355752",
    "stage3_gate_decision",
    "audit/decisions/h06_stage2_gate_and_stage3_transition.md",
    "88fb0bae10e24d3fb300de64d8c6959865a5cfa7ed9ced98e66ae2dffbe0617d",
    "stage4_gate_decision",
    "audit/decisions/h06_stage3_gate_and_stage4_transition.md",
    "a97f3b9dc7f2b3b42d27ae970773ea50cd479046891594de5b0955a52e5dfaa4",
    "v0_near_eye_table",
    "tables/H6.docx",
    "20a259c13c5d0637c11f3522ed6fdca12d18d8f7df27b6ab8b1bf5787c330b80",
    "v0_chest_table",
    "tables/chest/H6.docx",
    "4db844c889df3ee0d628f2d017a82dacd81c87c2e3e1ac02b6694bb1c8f40893",
    "v0_near_eye_light",
    "data/preprocessed_glasses_2.RData",
    "0d00bac25d955d45447f74cc9c3ad6a5f5dfa1de1282d8d619c9468f72e0c430",
    "v0_chest_light",
    "data/preprocessed_chest_2.RData",
    "b289c17c64d1bd24166fa3873da9aa8f22a5f57c793a7282ecb201dc77dcd274"
  ) |>
    dplyr::mutate(path = file.path(root, .data$relative_path))
}

h06_base_input_bundle_sha256 <- function() {
  "168f25e18b6e494aa7a0272923041ad8249e25adb9ff3742d22e2f4cacf1bdf8"
}

h06_v0_output_summary <- function() {
  tibble::tribble(
    ~placement,
    ~participant_hours,
    ~reference_melEDI_lx,
    ~free_vs_work_ratio,
    ~light_vs_none_ratio,
    ~moderate_vs_none_ratio,
    ~vigorous_vs_none_ratio,
    ~sleep_ratio_per_hour,
    ~conditional_r2,
    ~marginal_r2,
    ~participant_random_multiplier,
    "glasses",
    16406L,
    75.79,
    0.92,
    1.85,
    1.74,
    1.50,
    0.92,
    0.42,
    0.15,
    2.36,
    "chest",
    18124L,
    96.18,
    0.92,
    1.49,
    1.61,
    1.21,
    0.92,
    0.37,
    0.13,
    2.26
  )
}

h06_validate_contract <- function() {
  formulas <- h06_formula_set()
  exploratory <- h06_exploratory_formula_set()
  runs <- h06_run_registry()
  families <- h06_multiplicity_registry()
  formula_text <- vapply(
    formulas,
    function(x) paste(deparse(x), collapse = " "),
    character(1)
  )
  if (
    length(formulas) != 10L ||
      length(exploratory) != 5L ||
      nrow(runs) != 6L ||
      nrow(families) != 5L ||
      any(families$planned_size != 3L) ||
      any(grepl("\\|", formula_text)) ||
      any(grepl("ar1", formula_text, fixed = TRUE)) ||
      any(grepl("clock_hour", formula_text, fixed = TRUE)) ||
      any(grepl("exercise_intensity", formula_text, fixed = TRUE))
  ) {
    h06_abort("The H06 Stage 2 contract is internally inconsistent")
  }
  invisible(TRUE)
}
