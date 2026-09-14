source("scripts/hypotheses/H07/h07_stage2_core.R")

overwrite <- identical(Sys.getenv("H07_STAGE2_OVERWRITE", unset = "0"), "1")
long_data <- h07_stage2_load_long()

key_columns <- c("site", "Id", "local_date")

paired_keys <- long_data |>
  filter(
    .data$data_scenario == "primary",
    .data$placement %in% c("near_eye", "chest"),
    !is.na(.data$original_value)
  ) |>
  group_by(
    .data$metric_id,
    .data$site,
    .data$Id,
    .data$local_date
  ) |>
  summarise(
    placements = n_distinct(.data$placement),
    .groups = "drop"
  ) |>
  filter(.data$placements == 2L) |>
  select(-"placements")

preparation_common_keys <- long_data |>
  filter(
    .data$data_scenario %in% c("primary", "gap_timing_unaware"),
    !is.na(.data$original_value)
  ) |>
  group_by(
    .data$placement,
    .data$metric_id,
    .data$site,
    .data$Id,
    .data$local_date
  ) |>
  summarise(
    scenarios = n_distinct(.data$data_scenario),
    .groups = "drop"
  ) |>
  filter(.data$scenarios == 2L) |>
  select(-"scenarios")

h07_stage2_read_variant_map <- function(path, placement) {
  readRDS(path) |>
    transmute(
      placement = .env$placement,
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      exact_period_value = .data$longest_bout_above_250_exact_only_sensitivity_h,
      exact_period_identifiable =
        as.logical(.data$longest_bout_above_250_exact_identifiable),
      corrected_dose_value = .data$dose_corrected_medi_lx_h,
      observed_dose_value = .data$dose_observed_medi_lx_h
    )
}

variant_map <- bind_rows(
  h07_stage2_read_variant_map(
    h07_stage2_input_paths[["primary_near_eye"]],
    "near_eye"
  ),
  h07_stage2_read_variant_map(
    h07_stage2_input_paths[["primary_chest"]],
    "chest"
  )
)
if (anyDuplicated(variant_map[c("placement", key_columns)])) {
  h07_stage2_abort("H07 metric-variant source has duplicate participant-day keys")
}

exact_period_keys <- variant_map |>
  filter(
    .data$exact_period_identifiable %in% TRUE,
    is.finite(.data$exact_period_value)
  ) |>
  select("placement", all_of(key_columns))

dose_common_keys <- variant_map |>
  filter(
    is.finite(.data$corrected_dose_value),
    is.finite(.data$observed_dose_value)
  ) |>
  select("placement", all_of(key_columns))

h07_stage2_override_from_variant <- function(placement, value_column) {
  map <- variant_map |>
    filter(.data$placement == .env$placement) |>
    select(all_of(key_columns), variant_value = all_of(value_column))
  function(frame) {
    frame |>
      left_join(map, by = key_columns, relationship = "one-to-one") |>
      mutate(original_value = .data$variant_value) |>
      select(-"variant_value")
  }
}

full_run_registry <- tibble::tribble(
  ~run_id, ~data_scenario, ~placement, ~sensitivity, ~key_rule,
  "paired__near_eye", "primary", "near_eye", "paired_common_placement", "paired",
  "paired__chest", "primary", "chest", "paired_common_placement", "paired",
  "gap_timing_unaware__near_eye", "gap_timing_unaware", "near_eye", "gap_timing_unaware", "all_available",
  "gap_timing_unaware__chest", "gap_timing_unaware", "chest", "gap_timing_unaware", "all_available",
  "prep_common_primary__near_eye", "primary", "near_eye", "preparation_exact_common", "preparation_common",
  "prep_common_primary__chest", "primary", "chest", "preparation_exact_common", "preparation_common",
  "prep_common_gap__near_eye", "gap_timing_unaware", "near_eye", "preparation_exact_common", "preparation_common",
  "prep_common_gap__chest", "gap_timing_unaware", "chest", "preparation_exact_common", "preparation_common"
)

special_run_registry <- tibble::tribble(
  ~run_id, ~data_scenario, ~placement, ~sensitivity, ~key_rule, ~metric_id, ~value_column,
  "exact_period__near_eye", "primary", "near_eye", "longest_period_exact_only", "exact_period", "longest_bout_above_250", "exact_period_value",
  "exact_period__chest", "primary", "chest", "longest_period_exact_only", "exact_period", "longest_bout_above_250", "exact_period_value",
  "dose_common_corrected__near_eye", "primary", "near_eye", "observed_dose_common_sample", "dose_common", "dose_time_sensitive_corrected_medi", NA_character_,
  "dose_common_corrected__chest", "primary", "chest", "observed_dose_common_sample", "dose_common", "dose_time_sensitive_corrected_medi", NA_character_,
  "dose_common_observed__near_eye", "primary", "near_eye", "observed_dose_common_sample", "dose_common", "dose_time_sensitive_corrected_medi", "observed_dose_value",
  "dose_common_observed__chest", "primary", "chest", "observed_dose_common_sample", "dose_common", "dose_time_sensitive_corrected_medi", "observed_dose_value"
)

run_registry <- bind_rows(
  full_run_registry |>
    mutate(
      metric_id = NA_character_,
      value_column = NA_character_,
      expected_family_n = 9L
    ),
  special_run_registry |>
    mutate(expected_family_n = NA_integer_)
)
readr::write_csv(
  run_registry,
  file.path(h07_stage2_paths$tables, "H07_sensitivity_run_registry.csv"),
  na = ""
)

key_audit <- bind_rows(
  paired_keys |>
    mutate(key_set = "paired_common_placement", placement = "both"),
  preparation_common_keys |>
    mutate(key_set = "preparation_exact_common"),
  exact_period_keys |>
    mutate(metric_id = "longest_bout_above_250", key_set = "longest_period_exact_only"),
  dose_common_keys |>
    mutate(metric_id = "dose_time_sensitive_corrected_medi", key_set = "observed_dose_common_sample")
) |>
  group_by(.data$key_set, .data$placement, .data$metric_id) |>
  summarise(
    participants = n_distinct(.data$site, .data$Id),
    participant_days = n(),
    sites = n_distinct(.data$site),
    .groups = "drop"
  ) |>
  left_join(
    h07_stage2_metric_contract |>
      select("metric_id", "metric_order", "manuscript_name"),
    by = "metric_id"
  ) |>
  arrange(.data$key_set, .data$placement, .data$metric_order)
readr::write_csv(
  key_audit,
  file.path(h07_stage2_paths$tables, "H07_sensitivity_key_audit.csv"),
  na = ""
)

h07_stage2_keys_for_run <- function(run, metric_id) {
  switch(
    run$key_rule[[1L]],
    paired = paired_keys |>
      filter(.data$metric_id == .env$metric_id) |>
      select(all_of(key_columns)),
    preparation_common = preparation_common_keys |>
      filter(
        .data$placement == run$placement[[1L]],
        .data$metric_id == .env$metric_id
      ) |>
      select(all_of(key_columns)),
    exact_period = exact_period_keys |>
      filter(.data$placement == run$placement[[1L]]) |>
      select(all_of(key_columns)),
    dose_common = dose_common_keys |>
      filter(.data$placement == run$placement[[1L]]) |>
      select(all_of(key_columns)),
    all_available = NULL,
    h07_stage2_abort("Unknown H07 sensitivity key rule: %s", run$key_rule[[1L]])
  )
}

h07_stage2_override_for_run <- function(run) {
  value_column <- run$value_column[[1L]]
  if (is.na(value_column) || !nzchar(value_column)) return(NULL)
  h07_stage2_override_from_variant(run$placement[[1L]], value_column)
}

h07_sensitivity_seed_unaffected <- function(filename) {
  path <- file.path(h07_stage2_paths$tables, filename)
  if (!h07_stage2_partial_execution || !file.exists(path)) {
    return(tibble::tibble())
  }
  readr::read_csv(path, show_col_types = FALSE) |>
    filter(!.data$metric_id %in% h07_stage2_execution_metric_ids)
}

samples <- h07_sensitivity_seed_unaffected("H07_sensitivity_samples.csv")
diagnostics <- h07_sensitivity_seed_unaffected(
  "H07_sensitivity_diagnostics.csv"
)
tests <- h07_sensitivity_seed_unaffected(
  "H07_sensitivity_tests_unadjusted.csv"
)

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  metrics <- if (is.na(run$metric_id[[1L]])) {
    h07_stage2_execution_metric_ids
  } else {
    intersect(run$metric_id[[1L]], h07_stage2_execution_metric_ids)
  }
  if (length(metrics) == 0L) next
  for (metric_id in metrics) {
    message(sprintf(
      "H07 SENS START %s / %s at %s",
      run$run_id,
      metric_id,
      format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    ))
    keys <- h07_stage2_keys_for_run(run, metric_id)
    if (!is.null(keys) && nrow(keys) == 0L) {
      h07_stage2_abort(
        "The approved sensitivity has no exact keys: %s / %s",
        run$run_id,
        metric_id
      )
    }
    result <- h07_stage2_run_metric(
      long_data = long_data,
      run_id = run$run_id,
      data_scenario = run$data_scenario,
      placement = run$placement,
      metric_id = metric_id,
      model_ids = h07_stage2_adapted_core_model_ids,
      keys = keys,
      value_override = h07_stage2_override_for_run(run),
      overwrite = overwrite
    )
    samples <- bind_rows(samples, result$sample) |>
      distinct(.data$run_id, .data$metric_id, .keep_all = TRUE)
    diagnostics <- bind_rows(diagnostics, result$diagnostics) |>
      distinct(.data$run_id, .data$metric_id, .data$model_id, .keep_all = TRUE)
    tests <- bind_rows(tests, result$tests) |>
      filter(.data$analysis_scope == "adapted_photoperiod") |>
      distinct(
        .data$run_id,
        .data$metric_id,
        .data$analysis_scope,
        .data$test_id,
        .keep_all = TRUE
      )
    readr::write_csv(
      samples,
      file.path(h07_stage2_paths$tables, "H07_sensitivity_samples.csv"),
      na = ""
    )
    readr::write_csv(
      diagnostics,
      file.path(h07_stage2_paths$tables, "H07_sensitivity_diagnostics.csv"),
      na = ""
    )
    readr::write_csv(
      tests,
      file.path(h07_stage2_paths$tables, "H07_sensitivity_tests_unadjusted.csv"),
      na = ""
    )
    message(sprintf(
      "H07 SENS DONE %s / %s: %s",
      run$run_id,
      metric_id,
      paste(unique(result$diagnostics$fit_status), collapse = ", ")
    ))
    rm(result)
    invisible(gc())
  }
}

samples <- samples |>
  arrange(
    factor(.data$run_id, levels = run_registry$run_id),
    factor(.data$metric_id, levels = h07_stage2_metric_ids)
  )
diagnostics <- diagnostics |>
  arrange(
    factor(.data$run_id, levels = run_registry$run_id),
    factor(.data$metric_id, levels = h07_stage2_metric_ids),
    factor(.data$model_id, levels = h07_stage2_adapted_core_model_ids)
  )
tests <- tests |>
  arrange(
    factor(.data$run_id, levels = run_registry$run_id),
    factor(.data$metric_id, levels = h07_stage2_metric_ids),
    .data$analysis_scope,
    .data$test_id
  )
readr::write_csv(
  samples,
  file.path(h07_stage2_paths$tables, "H07_sensitivity_samples.csv"),
  na = ""
)
readr::write_csv(
  diagnostics,
  file.path(h07_stage2_paths$tables, "H07_sensitivity_diagnostics.csv"),
  na = ""
)
readr::write_csv(
  tests,
  file.path(
    h07_stage2_paths$tables,
    "H07_sensitivity_tests_unadjusted.csv"
  ),
  na = ""
)

tests_adjusted <- tests |>
  left_join(
    h07_stage2_metric_contract |>
      select(
        "metric_id",
        "metric_order",
        "manuscript_name",
        "response_family",
        "response_transform",
        "effect_scale",
        "display_unit"
      ),
    by = "metric_id"
  ) |>
  left_join(
    run_registry |>
      select("run_id", "sensitivity", "placement", "expected_family_n"),
    by = "run_id"
  ) |>
  group_by(.data$run_id, .data$analysis_scope, .data$test_id) |>
  arrange(.data$metric_order, .by_group = TRUE) |>
  mutate(
    p_adjusted_BH_model = if (is.na(first(.data$expected_family_n))) {
      rep(NA_real_, n())
    } else {
      stats::p.adjust(
        .data$p_raw_model,
        method = "BH",
        n = first(.data$expected_family_n)
      )
    },
    p_raw_release = if_else(
      .data$p_release_status == "RELEASE_CONDITIONAL_APPROXIMATE",
      .data$p_raw_model,
      NA_real_
    ),
    p_adjusted_BH_release = if (is.na(first(.data$expected_family_n))) {
      rep(NA_real_, n())
    } else {
      stats::p.adjust(
        .data$p_raw_release,
        method = "BH",
        n = first(.data$expected_family_n)
      )
    },
    conditional_aic_support = case_when(
      is.na(.data$delta_aic_full_minus_reduced) ~ "UNAVAILABLE",
      .data$delta_aic_full_minus_reduced < -2 ~ "FULL_LOWER_BY_MORE_THAN_2",
      .data$delta_aic_full_minus_reduced <= 0 ~ "FULL_LOWER_BY_0_TO_2",
      TRUE ~ "REDUCED_LOWER"
    )
  ) |>
  ungroup() |>
  arrange(
    factor(.data$run_id, levels = run_registry$run_id),
    .data$test_id,
    .data$metric_order
  )

family_audit <- tests_adjusted |>
  filter(!is.na(.data$expected_family_n)) |>
  count(
    .data$run_id,
    .data$analysis_scope,
    .data$test_id,
    .data$expected_family_n,
    name = "observed_family_n"
  ) |>
  mutate(
    status = if_else(
      .data$observed_family_n == .data$expected_family_n,
      "PASS",
      "FAIL"
    )
  )
if (any(family_audit$status != "PASS")) {
  h07_stage2_abort("An H07 sensitivity multiplicity family is incomplete")
}

readr::write_csv(
  tests_adjusted,
  file.path(h07_stage2_paths$tables, "H07_sensitivity_tests.csv"),
  na = ""
)
readr::write_csv(
  family_audit,
  file.path(h07_stage2_paths$tables, "H07_sensitivity_family_audit.csv"),
  na = ""
)

message("H07 Stage 2 sensitivity checkpoint run complete")
