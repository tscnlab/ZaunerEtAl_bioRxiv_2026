#!/usr/bin/env Rscript

# Audit H03 and H04 diary-category support without reading exposure outcomes.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(tibble)
  library(tidyr)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "The H03/H04 category-support audit requires R 4.6.1; found %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

arguments <- commandArgs(trailingOnly = TRUE)
root <- if (length(arguments) >= 1L) {
  arguments[[1L]]
} else {
  getwd()
}
root <- normalizePath(root, winslash = "/", mustWork = TRUE)

#####
# Step 1: Declare inputs and dictionaries
#####

input_paths <- c(
  normalized_diary = file.path(
    root,
    "artifacts",
    "06_model_data",
    "normalized_inputs",
    "lightexposurediary.rds"
  ),
  free_text_audit = file.path(
    root,
    "artifacts",
    "06_model_data",
    "normalized_inputs",
    "audits",
    "free_text_audit.csv"
  ),
  normalization_manifest = file.path(
    root,
    "artifacts",
    "12_manifests",
    "model_input_normalization.csv"
  ),
  preregistration_contract = file.path(
    root,
    "audit",
    "evidence",
    "preregistration_contract.md"
  ),
  migration_map = file.path(
    root,
    "audit",
    "hypotheses",
    "H01-H04_migration_map.md"
  )
)
if (any(!file.exists(input_paths))) {
  stop(
    sprintf(
      "Missing category-support input(s): %s",
      paste(names(input_paths)[!file.exists(input_paths)], collapse = ", ")
    ),
    call. = FALSE
  )
}

light_dictionary <- tribble(
  ~category_order,
  ~category_code,
  ~category_label,
  ~source_flag,
  ~category_role,
  ~measurement_interpretation,
  1L,
  "electric_indoor",
  "Electric light source indoors",
  "light_electric_indoor",
  "reference",
  "hourly reported light-source context",
  2L,
  "electric_outdoor",
  "Electric light source outdoors",
  "light_electric_outdoor",
  "contrast",
  "hourly reported light-source context",
  3L,
  "daylight_indoor",
  "Daylight indoors",
  "light_daylight_indoor",
  "contrast",
  "hourly reported light-source context",
  4L,
  "daylight_outdoor",
  "Daylight outdoors (including shade)",
  "light_daylight_outdoor",
  "contrast",
  "hourly reported light-source context",
  5L,
  "display",
  "Emissive display light",
  "light_display",
  "contrast",
  "hourly reported light-source context",
  6L,
  "sleep_darkness",
  "Darkness during sleep",
  "light_sleep_darkness",
  "contrast",
  "bedside sleep-environment context",
  7L,
  "sleep_external_light",
  "Light entering from outside during sleep",
  "light_sleep_imission",
  "contrast",
  "bedside sleep-environment context"
)

activity_dictionary <- tribble(
  ~activity_order,
  ~activity_flag,
  ~activity_code,
  ~activity_label,
  ~adapted_five_level,
  1L,
  "act_sleep",
  "sleep",
  "Sleeping in bed",
  "sleep",
  2L,
  "act_home",
  "home",
  "Awake at home",
  "home",
  3L,
  "act_road_vehicle",
  "road_vehicle",
  "On the road with public transport/car",
  "road_vehicle",
  4L,
  "act_road_open",
  "road_open",
  "On the road with bike/on foot",
  "outdoor",
  5L,
  "act_working_indoor",
  "working_indoor",
  "Working in the office/from home",
  "working_indoor",
  6L,
  "act_working_outdoor",
  "working_outdoor",
  "Working outdoors (including lunch break outdoors)",
  "outdoor",
  7L,
  "act_free_outdoor",
  "free_outdoor",
  "Free time outdoors",
  "outdoor",
  8L,
  "act_other",
  "other",
  "Other",
  NA_character_
)

#####
# Step 2: Read only the outcome-blinded diary fields
#####

source_diary <- readRDS(input_paths[["normalized_diary"]])
required_columns <- c(
  "site",
  "Id",
  "Date",
  "source_row",
  "lightsource_primary",
  "lightsource_secondary",
  light_dictionary$source_flag,
  activity_dictionary$activity_flag,
  "interval_start_utc",
  "interval_start_local_label",
  "interval_start_wall",
  "interval_start_utc_offset_minutes",
  "interval_start_is_dst",
  "interval_end_utc",
  "interval_end_local_label",
  "interval_end_wall",
  "interval_end_utc_offset_minutes",
  "interval_end_is_dst",
  "interval_analysis_eligible",
  "interval_quarantined",
  "interval_issue_code"
)
missing_columns <- setdiff(required_columns, names(source_diary))
if (length(missing_columns) > 0L) {
  stop(
    sprintf(
      "Normalized diary lacks required column(s): %s",
      paste(missing_columns, collapse = ", ")
    ),
    call. = FALSE
  )
}
if (
  any(grepl(
    "MEDI|melanopic|illuminance|\\bLIGHT\\b|exposure_outcome",
    required_columns,
    ignore.case = TRUE
  ))
) {
  stop(
    "The approved audit field list contains an exposure outcome",
    call. = FALSE
  )
}

diary <- source_diary |>
  select(all_of(required_columns))
rm(source_diary)

if (
  nrow(diary) != 30199L ||
    anyDuplicated(diary[c("site", "source_row")]) ||
    !all(vapply(
      diary[activity_dictionary$activity_flag],
      is.logical,
      logical(1)
    ))
) {
  stop(
    "Normalized diary violates its row or activity-flag contract",
    call. = FALSE
  )
}
if (
  !is.factor(diary$lightsource_primary) ||
    !identical(
      levels(diary$lightsource_primary),
      light_dictionary$category_label
    )
) {
  stop(
    "Primary-light-source factor levels differ from the declared dictionary",
    call. = FALSE
  )
}

diary <- diary |>
  mutate(
    participant_key = paste(.data$site, .data$Id, sep = "::"),
    participant_day_key = paste(
      .data$site,
      .data$Id,
      format(.data$Date, "%Y-%m-%d"),
      sep = "::"
    ),
    true_hour_key = paste(
      .data$site,
      .data$Id,
      format(
        .data$interval_start_utc,
        "%Y-%m-%dT%H:%M:%S",
        tz = "UTC"
      ),
      sep = "::"
    ),
    wall_hour_key = paste(
      .data$site,
      .data$Id,
      format(
        .data$interval_start_wall,
        "%Y-%m-%dT%H:%M:%S",
        tz = "UTC"
      ),
      sep = "::"
    ),
    local_clock_hour = as.integer(format(
      .data$interval_start_wall,
      "%H",
      tz = "UTC"
    )),
    light_category_label = if_else(
      is.na(.data$lightsource_primary),
      "<missing primary light source>",
      as.character(.data$lightsource_primary)
    )
  ) |>
  left_join(
    light_dictionary |>
      select(category_code, category_label),
    by = c("light_category_label" = "category_label"),
    relationship = "many-to-one"
  ) |>
  mutate(
    category_code = coalesce(
      .data$category_code,
      "missing_primary_light_source"
    )
  )

activity_matrix <- as.matrix(diary[activity_dictionary$activity_flag])
diary$n_activity_true <- rowSums(activity_matrix == TRUE, na.rm = TRUE)
diary$n_activity_missing <- rowSums(is.na(activity_matrix))
diary$activity_cardinality <- case_when(
  diary$n_activity_missing == ncol(activity_matrix) ~ "all_flags_missing",
  diary$n_activity_missing > 0L ~ "partially_missing_flags",
  diary$n_activity_true == 0L ~ "observed_zero_selected",
  diary$n_activity_true == 1L ~ "exactly_one_selected",
  diary$n_activity_true > 1L ~ "multiple_selected"
)
diary$activity_pattern <- apply(
  activity_matrix,
  1L,
  function(values) {
    selected <- activity_dictionary$activity_code[
      which(!is.na(values) & values)
    ]
    if (length(selected) > 0L) {
      paste(selected, collapse = "+")
    } else if (all(is.na(values))) {
      "<all flags missing>"
    } else {
      "<zero selected>"
    }
  }
)
rm(activity_matrix)

eligible <- diary |>
  filter(.data$interval_analysis_eligible)
sites <- sort(unique(diary$site))
site_scopes <- c("ALL", sites)

#####
# Step 3: Audit H03 categories
#####

h03_dictionary_audit <- light_dictionary |>
  rowwise() |>
  mutate(
    n_primary_rows = sum(
      as.character(diary$lightsource_primary) == .data$category_label,
      na.rm = TRUE
    ),
    n_expected_flag_true = sum(
      as.character(diary$lightsource_primary) == .data$category_label &
        diary[[.data$source_flag]] %in% TRUE,
      na.rm = TRUE
    ),
    n_expected_flag_false = sum(
      as.character(diary$lightsource_primary) == .data$category_label &
        diary[[.data$source_flag]] %in% FALSE,
      na.rm = TRUE
    ),
    n_expected_flag_missing = sum(
      as.character(diary$lightsource_primary) == .data$category_label &
        is.na(diary[[.data$source_flag]]),
      na.rm = TRUE
    ),
    factor_level_matches_declared_order = identical(
      levels(diary$lightsource_primary)[[.data$category_order]],
      .data$category_label
    )
  ) |>
  ungroup()

light_codes <- c(
  light_dictionary$category_code,
  "missing_primary_light_source"
)
h03_support_overall <- diary |>
  group_by(.data$category_code) |>
  summarise(
    n_source_intervals = n(),
    n_analysis_eligible_intervals = sum(.data$interval_analysis_eligible),
    n_quarantined_intervals = sum(.data$interval_quarantined),
    n_participants_eligible = n_distinct(
      .data$participant_key[.data$interval_analysis_eligible]
    ),
    n_participant_days_eligible = n_distinct(
      .data$participant_day_key[.data$interval_analysis_eligible]
    ),
    n_sites_eligible = n_distinct(
      .data$site[.data$interval_analysis_eligible]
    ),
    n_local_clock_hours_eligible = n_distinct(
      .data$local_clock_hour[.data$interval_analysis_eligible]
    ),
    .groups = "drop"
  ) |>
  right_join(
    tibble(category_code = light_codes),
    by = "category_code",
    relationship = "one-to-one"
  ) |>
  mutate(
    across(
      starts_with("n_"),
      ~ coalesce(as.integer(.x), 0L)
    )
  ) |>
  left_join(
    light_dictionary |>
      select(
        category_order,
        category_code,
        category_label,
        category_role,
        measurement_interpretation
      ),
    by = "category_code",
    relationship = "many-to-one"
  ) |>
  mutate(
    category_order = coalesce(.data$category_order, 8L),
    category_label = coalesce(
      .data$category_label,
      "<missing primary light source>"
    ),
    category_role = coalesce(.data$category_role, "missing"),
    measurement_interpretation = coalesce(
      .data$measurement_interpretation,
      "no primary light-source category available"
    ),
    pooled_support_200h_20participants_3sites = .data$category_role !=
      "missing" &
      .data$n_analysis_eligible_intervals >= 200L &
      .data$n_participants_eligible >= 20L &
      .data$n_sites_eligible >= 3L
  ) |>
  arrange(.data$category_order)

h03_participant_support <- eligible |>
  count(
    .data$site,
    .data$category_code,
    .data$participant_key,
    name = "participant_hours"
  ) |>
  group_by(.data$site, .data$category_code) |>
  summarise(
    n_participants = n(),
    participant_hours_min = min(.data$participant_hours),
    participant_hours_q25 = as.numeric(
      quantile(.data$participant_hours, 0.25, names = FALSE)
    ),
    participant_hours_median = median(.data$participant_hours),
    participant_hours_q75 = as.numeric(
      quantile(.data$participant_hours, 0.75, names = FALSE)
    ),
    participant_hours_max = max(.data$participant_hours),
    .groups = "drop"
  )

h03_reference_participants <- eligible |>
  filter(.data$category_code == "electric_indoor") |>
  distinct(.data$site, .data$participant_key) |>
  mutate(has_reference_support = TRUE)
h03_shared_reference <- eligible |>
  distinct(.data$site, .data$category_code, .data$participant_key) |>
  left_join(
    h03_reference_participants,
    by = c("site", "participant_key"),
    relationship = "many-to-one"
  ) |>
  group_by(.data$site, .data$category_code) |>
  summarise(
    n_participants_with_category_and_reference = sum(
      .data$has_reference_support %in% TRUE
    ),
    .groups = "drop"
  )

h03_site_grid <- expand_grid(
  site = sites,
  category_code = light_codes
)
h03_support_by_site <- eligible |>
  group_by(.data$site, .data$category_code) |>
  summarise(
    n_intervals = n(),
    n_participant_days = n_distinct(.data$participant_day_key),
    n_local_clock_hours = n_distinct(.data$local_clock_hour),
    .groups = "drop"
  ) |>
  right_join(
    h03_site_grid,
    by = c("site", "category_code"),
    relationship = "one-to-one"
  ) |>
  left_join(
    h03_participant_support,
    by = c("site", "category_code"),
    relationship = "one-to-one"
  ) |>
  left_join(
    h03_shared_reference,
    by = c("site", "category_code"),
    relationship = "one-to-one"
  ) |>
  mutate(
    across(
      c(
        "n_intervals",
        "n_participant_days",
        "n_local_clock_hours",
        "n_participants",
        "participant_hours_min",
        "participant_hours_q25",
        "participant_hours_median",
        "participant_hours_q75",
        "participant_hours_max",
        "n_participants_with_category_and_reference"
      ),
      ~ coalesce(as.numeric(.x), 0)
    ),
    site_specific_support_rule = .data$category_code !=
      "missing_primary_light_source" &
      .data$n_intervals >= 20L &
      .data$n_participants >= 5L &
      .data$n_participants_with_category_and_reference >= 5L
  ) |>
  left_join(
    h03_support_overall |>
      select(category_code, category_order, category_label),
    by = "category_code",
    relationship = "many-to-one"
  ) |>
  arrange(.data$category_order, .data$site)

h03_hour_grid <- expand_grid(
  site = sites,
  category_code = light_codes,
  local_clock_hour = 0:23
)
h03_support_by_local_hour <- eligible |>
  group_by(
    .data$site,
    .data$category_code,
    .data$local_clock_hour
  ) |>
  summarise(
    n_intervals = n(),
    n_participants = n_distinct(.data$participant_key),
    n_participant_days = n_distinct(.data$participant_day_key),
    .groups = "drop"
  ) |>
  right_join(
    h03_hour_grid,
    by = c("site", "category_code", "local_clock_hour"),
    relationship = "one-to-one"
  ) |>
  mutate(
    across(
      c("n_intervals", "n_participants", "n_participant_days"),
      ~ coalesce(as.integer(.x), 0L)
    )
  ) |>
  left_join(
    h03_support_overall |>
      select(category_code, category_order, category_label),
    by = "category_code",
    relationship = "many-to-one"
  ) |>
  arrange(
    .data$category_order,
    .data$site,
    .data$local_clock_hour
  )

#####
# Step 4: Audit H04 flags, overlap, and hourly cardinality
#####

activity_long <- eligible |>
  select(
    "site",
    "participant_key",
    "participant_day_key",
    "local_clock_hour",
    "activity_cardinality",
    all_of(activity_dictionary$activity_flag)
  ) |>
  pivot_longer(
    cols = all_of(activity_dictionary$activity_flag),
    names_to = "activity_flag",
    values_to = "selected"
  ) |>
  left_join(
    activity_dictionary,
    by = "activity_flag",
    relationship = "many-to-one"
  )

activity_scoped <- bind_rows(
  activity_long |>
    mutate(scope_site = .data$site),
  activity_long |>
    mutate(scope_site = "ALL")
)
h04_activity_flag_support <- activity_scoped |>
  group_by(
    .data$scope_site,
    .data$activity_order,
    .data$activity_flag,
    .data$activity_code,
    .data$activity_label,
    .data$adapted_five_level
  ) |>
  summarise(
    n_true = sum(.data$selected %in% TRUE),
    n_false = sum(.data$selected %in% FALSE),
    n_missing = sum(is.na(.data$selected)),
    n_true_in_exact_one_hours = sum(
      .data$selected %in%
        TRUE &
        .data$activity_cardinality == "exactly_one_selected"
    ),
    n_true_in_multilabel_hours = sum(
      .data$selected %in%
        TRUE &
        .data$activity_cardinality == "multiple_selected"
    ),
    n_participants_true = n_distinct(
      .data$participant_key[.data$selected %in% TRUE]
    ),
    n_participant_days_true = n_distinct(
      .data$participant_day_key[.data$selected %in% TRUE]
    ),
    n_local_clock_hours_true = n_distinct(
      .data$local_clock_hour[.data$selected %in% TRUE]
    ),
    .groups = "drop"
  ) |>
  rename(site = "scope_site") |>
  arrange(factor(.data$site, levels = site_scopes), .data$activity_order)

cardinality_scoped <- bind_rows(
  eligible |>
    mutate(scope_site = .data$site),
  eligible |>
    mutate(scope_site = "ALL")
)
cardinality_participant_support <- cardinality_scoped |>
  count(
    .data$scope_site,
    .data$activity_cardinality,
    .data$participant_key,
    name = "participant_hours"
  ) |>
  group_by(.data$scope_site, .data$activity_cardinality) |>
  summarise(
    n_participants = n(),
    participant_hours_min = min(.data$participant_hours),
    participant_hours_q25 = as.numeric(
      quantile(.data$participant_hours, 0.25, names = FALSE)
    ),
    participant_hours_median = median(.data$participant_hours),
    participant_hours_q75 = as.numeric(
      quantile(.data$participant_hours, 0.75, names = FALSE)
    ),
    participant_hours_max = max(.data$participant_hours),
    .groups = "drop"
  )

cardinality_levels <- c(
  "all_flags_missing",
  "partially_missing_flags",
  "observed_zero_selected",
  "exactly_one_selected",
  "multiple_selected"
)
h04_cardinality_by_site <- cardinality_scoped |>
  group_by(.data$scope_site, .data$activity_cardinality) |>
  summarise(
    n_intervals = n(),
    n_participant_days = n_distinct(.data$participant_day_key),
    .groups = "drop"
  ) |>
  right_join(
    expand_grid(
      scope_site = site_scopes,
      activity_cardinality = cardinality_levels
    ),
    by = c("scope_site", "activity_cardinality"),
    relationship = "one-to-one"
  ) |>
  left_join(
    cardinality_participant_support,
    by = c("scope_site", "activity_cardinality"),
    relationship = "one-to-one"
  ) |>
  group_by(.data$scope_site) |>
  mutate(
    n_intervals = coalesce(as.integer(.data$n_intervals), 0L),
    n_participant_days = coalesce(
      as.integer(.data$n_participant_days),
      0L
    ),
    n_participants = coalesce(as.integer(.data$n_participants), 0L),
    across(
      starts_with("participant_hours_"),
      ~ coalesce(as.numeric(.x), 0)
    ),
    percent_of_eligible_intervals = 100 *
      .data$n_intervals /
      sum(.data$n_intervals)
  ) |>
  ungroup() |>
  rename(site = "scope_site") |>
  arrange(
    factor(.data$site, levels = site_scopes),
    factor(.data$activity_cardinality, levels = cardinality_levels)
  )

h04_flag_count_distribution <- cardinality_scoped |>
  count(
    .data$scope_site,
    .data$n_activity_true,
    .data$n_activity_missing,
    name = "n_intervals"
  ) |>
  group_by(.data$scope_site) |>
  mutate(
    percent_of_eligible_intervals = 100 *
      .data$n_intervals /
      sum(.data$n_intervals)
  ) |>
  ungroup() |>
  rename(site = "scope_site") |>
  arrange(
    factor(.data$site, levels = site_scopes),
    .data$n_activity_missing,
    .data$n_activity_true
  )

h04_cardinality_by_local_hour <- cardinality_scoped |>
  group_by(
    .data$scope_site,
    .data$local_clock_hour,
    .data$activity_cardinality
  ) |>
  summarise(
    n_intervals = n(),
    n_participants = n_distinct(.data$participant_key),
    n_participant_days = n_distinct(.data$participant_day_key),
    .groups = "drop"
  ) |>
  right_join(
    expand_grid(
      scope_site = site_scopes,
      local_clock_hour = 0:23,
      activity_cardinality = cardinality_levels
    ),
    by = c("scope_site", "local_clock_hour", "activity_cardinality"),
    relationship = "one-to-one"
  ) |>
  mutate(
    across(
      c("n_intervals", "n_participants", "n_participant_days"),
      ~ coalesce(as.integer(.x), 0L)
    )
  ) |>
  rename(site = "scope_site") |>
  arrange(
    factor(.data$site, levels = site_scopes),
    .data$local_clock_hour,
    factor(.data$activity_cardinality, levels = cardinality_levels)
  )

h04_pattern_support <- cardinality_scoped |>
  group_by(
    .data$scope_site,
    .data$activity_pattern,
    .data$activity_cardinality,
    .data$n_activity_true,
    .data$n_activity_missing
  ) |>
  summarise(
    n_intervals = n(),
    n_participants = n_distinct(.data$participant_key),
    n_participant_days = n_distinct(.data$participant_day_key),
    n_local_clock_hours = n_distinct(.data$local_clock_hour),
    .groups = "drop"
  ) |>
  rename(site = "scope_site") |>
  arrange(
    factor(.data$site, levels = site_scopes),
    factor(.data$activity_cardinality, levels = cardinality_levels),
    desc(.data$n_intervals),
    .data$activity_pattern
  )

#####
# Step 5: Audit interval alignment and participant-hour cardinality
#####

summarise_key_cardinality <- function(data, key_name) {
  key_counts <- data |>
    count(.data$site, .data[[key_name]], name = "source_rows")
  key_conflicts <- data |>
    group_by(.data$site, .data[[key_name]]) |>
    summarise(
      n_activity_patterns = n_distinct(.data$activity_pattern),
      n_primary_light_categories = n_distinct(
        .data$category_code
      ),
      .groups = "drop"
    )
  key_counts |>
    left_join(
      key_conflicts,
      by = c("site", key_name),
      relationship = "one-to-one"
    ) |>
    group_by(.data$site) |>
    summarise(
      n_unique_keys = n(),
      n_duplicate_keys = sum(.data$source_rows > 1L),
      n_rows_in_duplicate_keys = sum(
        .data$source_rows[.data$source_rows > 1L]
      ),
      n_duplicate_keys_with_activity_conflict = sum(
        .data$source_rows > 1L &
          .data$n_activity_patterns > 1L
      ),
      n_duplicate_keys_with_primary_light_conflict = sum(
        .data$source_rows > 1L &
          .data$n_primary_light_categories > 1L
      ),
      .groups = "drop"
    )
}

true_key_audit <- summarise_key_cardinality(eligible, "true_hour_key") |>
  rename_with(~ paste0("true_", .x), -site)
wall_key_audit <- summarise_key_cardinality(eligible, "wall_hour_key") |>
  rename_with(~ paste0("wall_", .x), -site)

interval_site <- eligible |>
  mutate(
    true_duration_minutes = as.numeric(difftime(
      .data$interval_end_utc,
      .data$interval_start_utc,
      units = "mins"
    )),
    wall_duration_minutes = as.numeric(difftime(
      .data$interval_end_wall,
      .data$interval_start_wall,
      units = "mins"
    )),
    start_aligned_to_hour = format(
      .data$interval_start_wall,
      "%M:%S",
      tz = "UTC"
    ) ==
      "00:00",
    end_aligned_to_hour = format(
      .data$interval_end_wall,
      "%M:%S",
      tz = "UTC"
    ) ==
      "00:00",
    start_label_matches_wall = .data$interval_start_local_label ==
      format(
        .data$interval_start_wall,
        "%Y-%m-%d %H:%M:%S",
        tz = "UTC"
      ),
    end_label_matches_wall = .data$interval_end_local_label ==
      format(
        .data$interval_end_wall,
        "%Y-%m-%d %H:%M:%S",
        tz = "UTC"
      ),
    start_offset_matches = as.numeric(.data$interval_start_wall) -
      as.numeric(.data$interval_start_utc) ==
      60 * .data$interval_start_utc_offset_minutes,
    end_offset_matches = as.numeric(.data$interval_end_wall) -
      as.numeric(.data$interval_end_utc) ==
      60 * .data$interval_end_utc_offset_minutes
  ) |>
  group_by(.data$site) |>
  summarise(
    n_eligible_intervals = n(),
    n_true_duration_60_minutes = sum(.data$true_duration_minutes == 60),
    n_true_duration_other = sum(.data$true_duration_minutes != 60),
    n_wall_duration_60_minutes = sum(.data$wall_duration_minutes == 60),
    n_wall_duration_120_minutes = sum(.data$wall_duration_minutes == 120),
    n_wall_duration_other = sum(!.data$wall_duration_minutes %in% c(60, 120)),
    n_start_aligned_to_hour = sum(.data$start_aligned_to_hour),
    n_end_aligned_to_hour = sum(.data$end_aligned_to_hour),
    n_start_label_matches_wall = sum(.data$start_label_matches_wall),
    n_end_label_matches_wall = sum(.data$end_label_matches_wall),
    n_start_offset_matches = sum(.data$start_offset_matches),
    n_end_offset_matches = sum(.data$end_offset_matches),
    .groups = "drop"
  ) |>
  left_join(true_key_audit, by = "site", relationship = "one-to-one") |>
  left_join(wall_key_audit, by = "site", relationship = "one-to-one")

quarantine_site <- diary |>
  group_by(.data$site) |>
  summarise(
    n_quarantined_intervals = sum(.data$interval_quarantined),
    .groups = "drop"
  )
interval_alignment_audit <- interval_site |>
  left_join(quarantine_site, by = "site", relationship = "one-to-one")
interval_alignment_audit <- bind_rows(
  interval_alignment_audit |>
    summarise(
      site = "ALL",
      across(where(is.numeric), ~ sum(.x, na.rm = TRUE))
    ),
  interval_alignment_audit
) |>
  arrange(factor(.data$site, levels = site_scopes))

h04_hour_key_audit <- eligible |>
  group_by(.data$site) |>
  summarise(
    n_eligible_source_intervals = n(),
    n_unique_hours_with_any_activity = sum(
      .data$n_activity_true >= 1L &
        .data$n_activity_missing == 0L
    ),
    n_long_rows_if_true_flags_are_pivoted = sum(.data$n_activity_true),
    n_extra_long_rows_from_multilabel_hours = sum(pmax(
      .data$n_activity_true - 1L,
      0L
    )),
    n_multilabel_hours = sum(.data$activity_cardinality == "multiple_selected"),
    n_observed_zero_hours = sum(
      .data$activity_cardinality == "observed_zero_selected"
    ),
    n_all_missing_hours = sum(
      .data$activity_cardinality == "all_flags_missing"
    ),
    .groups = "drop"
  ) |>
  left_join(true_key_audit, by = "site", relationship = "one-to-one") |>
  left_join(wall_key_audit, by = "site", relationship = "one-to-one")
h04_hour_key_audit <- bind_rows(
  h04_hour_key_audit |>
    summarise(
      site = "ALL",
      across(where(is.numeric), ~ sum(.x, na.rm = TRUE))
    ),
  h04_hour_key_audit
) |>
  arrange(factor(.data$site, levels = site_scopes))

#####
# Step 6: Compare pre-outcome H04 representations
#####

exact_one <- eligible$activity_cardinality == "exactly_one_selected"
any_selected <- eligible$activity_cardinality %in%
  c(
    "exactly_one_selected",
    "multiple_selected"
  )
exact_activity_flag <- rep(NA_character_, nrow(eligible))
for (activity_flag in activity_dictionary$activity_flag) {
  exact_activity_flag[
    exact_one & eligible[[activity_flag]] %in% TRUE
  ] <- activity_flag
}
eligible$exact_activity_flag <- exact_activity_flag
eligible <- eligible |>
  left_join(
    activity_dictionary |>
      select(
        activity_flag,
        activity_code,
        adapted_five_level
      ),
    by = c("exact_activity_flag" = "activity_flag"),
    relationship = "many-to-one"
  )

option_masks <- list(
  indicator_global_block = any_selected,
  exact_one_original_eight = exact_one,
  exact_one_adapted_five = exact_one & !is.na(eligible$adapted_five_level),
  exact_one_plus_explicit_multilabel_profile = any_selected
)
option_estimands <- c(
  indicator_global_block = paste(
    "Joint activity-indicator block; standardized exact-one profiles",
    "can be contrasted while multi-label hours inform the block"
  ),
  exact_one_original_eight = paste(
    "Mutually exclusive association among the eight declared source",
    "activities for exactly-one hours"
  ),
  exact_one_adapted_five = paste(
    "Mutually exclusive association among the current adapted five",
    "levels; other is excluded and three outdoor flags are combined"
  ),
  exact_one_plus_explicit_multilabel_profile = paste(
    "Mutually exclusive exact-one activity profiles plus a heterogeneous",
    "explicit multi-label profile"
  )
)
option_multiplicity <- c(
  indicator_global_block = paste(
    "One global 8-df block; predeclared standardized contrasts in one",
    "family, with interaction terms requiring a separate gate"
  ),
  exact_one_original_eight = "One global factor test; seven activity-versus-home contrasts",
  exact_one_adapted_five = "One global factor test; four adapted activity-versus-home contrasts",
  exact_one_plus_explicit_multilabel_profile = paste(
    "One global profile test; eight profile-versus-home contrasts if",
    "multi-label is reported as a ninth level"
  )
)

h04_option_sample_accounting <- bind_rows(lapply(
  names(option_masks),
  function(option_id) {
    mask <- option_masks[[option_id]]
    tibble(
      option_id = option_id,
      estimand = option_estimands[[option_id]],
      n_intervals_retained = sum(mask),
      n_intervals_excluded_from_all_eligible = nrow(eligible) - sum(mask),
      percent_of_all_eligible_retained = 100 * sum(mask) / nrow(eligible),
      n_intervals_excluded_from_any_selected = sum(any_selected) - sum(mask),
      percent_of_any_selected_retained = 100 * sum(mask) / sum(any_selected),
      n_participants_retained = n_distinct(eligible$participant_key[mask]),
      n_participant_days_retained = n_distinct(eligible$participant_day_key[
        mask
      ]),
      n_sites_retained = n_distinct(eligible$site[mask]),
      multiplicity_implication = option_multiplicity[[option_id]]
    )
  }
))

rank_row <- function(data, analysis_id, formula) {
  design <- model.matrix(formula, data = data)
  design_qr <- qr(design)
  design_rank <- design_qr$rank
  aliased_columns <- if (design_rank < ncol(design)) {
    paste(
      colnames(design)[
        design_qr$pivot[seq.int(design_rank + 1L, ncol(design))]
      ],
      collapse = ";"
    )
  } else {
    ""
  }
  tibble(
    analysis_id = analysis_id,
    formula = paste(deparse(formula), collapse = ""),
    n_rows = nrow(design),
    n_columns = ncol(design),
    rank = design_rank,
    rank_deficient = design_rank < ncol(design),
    aliased_columns = aliased_columns,
    residual_df = nrow(design) - design_rank
  )
}

h03_design <- eligible |>
  filter(.data$category_code != "missing_primary_light_source") |>
  mutate(
    light_category = factor(
      .data$category_code,
      levels = light_dictionary$category_code
    )
  )
h04_indicator_design <- eligible[any_selected, , drop = FALSE]
h04_exact_design <- eligible[exact_one, , drop = FALSE] |>
  mutate(
    activity = factor(
      .data$activity_code,
      levels = activity_dictionary$activity_code
    )
  )
h04_adapted_design <- eligible[
  exact_one & !is.na(eligible$adapted_five_level),
  ,
  drop = FALSE
] |>
  mutate(
    activity_adapted = factor(
      .data$adapted_five_level,
      levels = c(
        "home",
        "sleep",
        "road_vehicle",
        "working_indoor",
        "outdoor"
      )
    )
  )
h04_profile_design <- eligible[any_selected, , drop = FALSE] |>
  mutate(
    activity_profile = factor(
      if_else(
        .data$activity_cardinality == "multiple_selected",
        "multiple_selected",
        .data$activity_code
      )
    )
  )

indicator_additive_formula <- reformulate(
  c("site", activity_dictionary$activity_flag)
)
indicator_interaction_formula <- as.formula(paste0(
  "~ site * (",
  paste(activity_dictionary$activity_flag, collapse = " + "),
  ")"
))
design_rank_audit <- bind_rows(
  rank_row(
    h03_design,
    "H03_additive_all_declared_categories",
    ~ site + light_category
  ),
  rank_row(
    h03_design,
    "H03_site_by_all_declared_categories",
    ~ site * light_category
  ),
  rank_row(
    h04_indicator_design,
    "H04_indicator_global_additive",
    indicator_additive_formula
  ),
  rank_row(
    h04_indicator_design,
    "H04_indicator_site_interactions",
    indicator_interaction_formula
  ),
  rank_row(
    h04_exact_design,
    "H04_exact_one_original_additive",
    ~ site + activity
  ),
  rank_row(
    h04_exact_design,
    "H04_exact_one_original_site_interaction",
    ~ site * activity
  ),
  rank_row(
    h04_adapted_design,
    "H04_exact_one_adapted_additive",
    ~ site + activity_adapted
  ),
  rank_row(
    h04_adapted_design,
    "H04_exact_one_adapted_site_interaction",
    ~ site * activity_adapted
  ),
  rank_row(
    h04_profile_design,
    "H04_exact_one_plus_multilabel_additive",
    ~ site + activity_profile
  ),
  rank_row(
    h04_profile_design,
    "H04_exact_one_plus_multilabel_site_interaction",
    ~ site * activity_profile
  )
)

free_text_audit <- read_csv(
  input_paths[["free_text_audit"]],
  show_col_types = FALSE
) |>
  filter(.data$modality == "lightexposurediary") |>
  group_by(.data$source_column) |>
  summarise(
    source_rows = sum(.data$rows),
    missing_rows = sum(.data$missing_rows),
    nonblank_rows = sum(.data$nonblank_rows),
    blank_rows = sum(.data$blank_rows),
    excluded_from_analytic_rds = all(.data$excluded_from_analytic_rds),
    content_exported = any(.data$content_exported),
    .groups = "drop"
  )

#####
# Step 7: Write aggregate artifacts and verify
#####

output_root <- file.path(
  root,
  "audit",
  "reconciliation",
  "preparation06",
  "category_support"
)
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
output_paths <- c(
  h03_dictionary_audit = file.path(
    output_root,
    "h03_category_dictionary.csv"
  ),
  h03_support_overall = file.path(
    output_root,
    "h03_category_support_overall.csv"
  ),
  h03_support_by_site = file.path(
    output_root,
    "h03_category_support_by_site.csv"
  ),
  h03_support_by_local_hour = file.path(
    output_root,
    "h03_category_support_by_local_hour.csv"
  ),
  h04_activity_flag_support = file.path(
    output_root,
    "h04_activity_flag_support.csv"
  ),
  h04_cardinality_by_site = file.path(
    output_root,
    "h04_activity_cardinality_by_site.csv"
  ),
  h04_flag_count_distribution = file.path(
    output_root,
    "h04_activity_flag_count_distribution.csv"
  ),
  h04_cardinality_by_local_hour = file.path(
    output_root,
    "h04_activity_cardinality_by_local_hour.csv"
  ),
  h04_pattern_support = file.path(
    output_root,
    "h04_activity_pattern_support.csv"
  ),
  interval_alignment_audit = file.path(
    output_root,
    "interval_alignment_audit.csv"
  ),
  h04_hour_key_audit = file.path(
    output_root,
    "h04_participant_hour_cardinality.csv"
  ),
  h04_option_sample_accounting = file.path(
    output_root,
    "h04_option_sample_accounting.csv"
  ),
  design_rank_audit = file.path(
    output_root,
    "design_rank_audit.csv"
  ),
  free_text_presence_audit = file.path(
    output_root,
    "free_text_presence_audit.csv"
  )
)
output_objects <- list(
  h03_dictionary_audit = h03_dictionary_audit,
  h03_support_overall = h03_support_overall,
  h03_support_by_site = h03_support_by_site,
  h03_support_by_local_hour = h03_support_by_local_hour,
  h04_activity_flag_support = h04_activity_flag_support,
  h04_cardinality_by_site = h04_cardinality_by_site,
  h04_flag_count_distribution = h04_flag_count_distribution,
  h04_cardinality_by_local_hour = h04_cardinality_by_local_hour,
  h04_pattern_support = h04_pattern_support,
  interval_alignment_audit = interval_alignment_audit,
  h04_hour_key_audit = h04_hour_key_audit,
  h04_option_sample_accounting = h04_option_sample_accounting,
  design_rank_audit = design_rank_audit,
  free_text_presence_audit = free_text_audit
)

for (artifact_name in names(output_paths)) {
  output <- output_objects[[artifact_name]]
  forbidden_output_columns <- intersect(
    names(output),
    c(
      "Id",
      "participant_key",
      "participant_day_key",
      "true_hour_key",
      "wall_hour_key",
      "source_row",
      "interval_start_utc",
      "interval_start_wall"
    )
  )
  if (length(forbidden_output_columns) > 0L) {
    stop(
      sprintf(
        "%s would export identifying or row-level key column(s): %s",
        artifact_name,
        paste(forbidden_output_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  write_csv(output, output_paths[[artifact_name]], na = "")
}

manifest <- tibble(
  artifact = names(output_paths),
  path = vapply(
    output_paths,
    function(path) {
      sub(
        paste0("^", root, "/"),
        "",
        normalizePath(path, winslash = "/", mustWork = TRUE)
      )
    },
    character(1)
  ),
  sha256 = vapply(
    output_paths,
    digest,
    character(1),
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  rows = vapply(output_objects, nrow, integer(1)),
  r_version = as.character(getRversion()),
  normalized_diary_sha256 = digest(
    input_paths[["normalized_diary"]],
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  normalization_manifest_sha256 = digest(
    input_paths[["normalization_manifest"]],
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  preregistration_contract_sha256 = digest(
    input_paths[["preregistration_contract"]],
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  migration_map_sha256 = digest(
    input_paths[["migration_map"]],
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  exposure_outcome_columns_accessed = FALSE,
  participant_identifiers_exported = FALSE,
  free_text_content_exported = FALSE
)
manifest_path <- file.path(output_root, "artifact_manifest.csv")
write_csv(manifest, manifest_path, na = "")

stopifnot(
  nrow(eligible) == 30172L,
  sum(!eligible$interval_analysis_eligible) == 0L,
  sum(h03_support_overall$n_analysis_eligible_intervals) == nrow(eligible),
  nrow(h03_support_by_site) == length(sites) * length(light_codes),
  nrow(h03_support_by_local_hour) == length(sites) * length(light_codes) * 24L,
  sum(
    h04_cardinality_by_site$n_intervals[
      h04_cardinality_by_site$site == "ALL"
    ]
  ) ==
    nrow(eligible),
  all(h03_dictionary_audit$n_expected_flag_false == 0L),
  all(h03_dictionary_audit$n_expected_flag_missing == 0L),
  all(
    interval_alignment_audit$n_true_duration_other == 0L
  ),
  all(
    interval_alignment_audit$true_n_duplicate_keys == 0L
  ),
  all(
    interval_alignment_audit$wall_n_duplicate_keys == 0L
  ),
  all(free_text_audit$excluded_from_analytic_rds),
  !any(free_text_audit$content_exported),
  all(!manifest$exposure_outcome_columns_accessed),
  all(!manifest$participant_identifiers_exported),
  all(!manifest$free_text_content_exported)
)

cat("H03/H04 category-support audit PASS\n")
cat(
  "Eligible intervals:",
  nrow(eligible),
  "\n"
)
cat(
  "H04 exact-one / multi-label / observed-zero / all-missing:",
  sum(eligible$activity_cardinality == "exactly_one_selected"),
  "/",
  sum(eligible$activity_cardinality == "multiple_selected"),
  "/",
  sum(eligible$activity_cardinality == "observed_zero_selected"),
  "/",
  sum(eligible$activity_cardinality == "all_flags_missing"),
  "\n"
)
cat(
  "Manifest SHA-256:",
  digest(
    manifest_path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  "\n"
)
