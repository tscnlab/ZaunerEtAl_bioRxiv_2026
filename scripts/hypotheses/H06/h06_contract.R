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
 tibble::tibble(input_role=c("primary_near_eye_hourly","complementary_chest_hourly","gap_timing_unaware_hourly","normalized_exercise_diary","normalized_sleep_diary","temporal_provenance","site_display_registry"),
 relative_path=c("results/intermediate/model_data/base/metrics_glasses_one_hour_context.rds","results/intermediate/model_data/base/metrics_chest_one_hour_context.rds","results/intermediate/model_data/scenarios/alternative_preprocessing/one_hour_data.rds","results/intermediate/model_data/normalized_inputs/exercisediary.rds","results/intermediate/model_data/normalized_inputs/sleepdiaries.rds","results/intermediate/model_data/temporal_provenance/wall_outcome_links.csv","config/site_display_registry.csv")) |>
 dplyr::mutate(path=file.path(root,.data$relative_path))
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
    h06_abort("The H06 contract is internally inconsistent")
  }
  invisible(TRUE)
}
