source("scripts/pipeline/assertions.R")
source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/metric_display_registry.R")
source("scripts/pipeline/h01_model_data.R")
source("scripts/pipeline/verify_h01_model_data_artifacts.R")

expect_error <- function(code) {
  errored <- tryCatch(
    {
      force(code)
      FALSE
    },
    error = function(error) TRUE
  )
  stopifnot(errored)
}

make_h01_input <- function(placement, contract) {
  day <- tibble::tibble(
    site = rep(c("SITE_A", "SITE_B"), each = 2L),
    Id = rep(c("P01", "P02"), each = 2L),
    position = placement,
    local_date = rep(
      as.Date(c("2026-01-01", "2026-01-02")),
      times = 2L
    ),
    profile_variant = "pooled",
    measurement_construct = "hybrid_24_hour_record",
    prepared_record_support_available = TRUE,
    prepared_record_support_unavailability_reason = NA_character_,
    expected_real_minutes = 1440,
    valid_medi_real_minutes = 1200,
    valid_light_real_minutes = 1180,
    photoperiod_hours = rep(c(10, 12), each = 2L),
    latitude_deg = rep(c(48, -10), each = 2L)
  )
  day_contract <- contract |>
    dplyr::filter(.data$analysis_unit == "participant_day")
  for (index in seq_len(nrow(day_contract))) {
    day[[day_contract$source_field[[index]]]] <-
      seq_len(nrow(day)) + day_contract$metric_order[[index]]
  }
  participant <- tibble::tibble(
    site = c("SITE_A", "SITE_B"),
    Id = c("P01", "P02"),
    position = placement,
    profile_variant = "pooled",
    measurement_construct = "hybrid_24_hour_record",
    prepared_record_support_available = TRUE,
    prepared_record_support_unavailability_reason = NA_character_,
    days = 2L,
    valid_minutes = 2400,
    expected_minutes = 2880
  )
  participant_contract <- contract |>
    dplyr::filter(.data$analysis_unit == "participant")
  for (index in seq_len(nrow(participant_contract))) {
    participant[[participant_contract$source_field[[index]]]] <-
      c(0.5, 0.7) + index / 10
  }

  support_rows <- lapply(seq_len(nrow(contract)), function(index) {
    specification <- contract[index, , drop = FALSE]
    source_field <- specification$source_field[[1L]]
    rolling_window_metric <- specification$metric_id[[1L]] %in%
      c(
        "m10_mean_medi",
        "l10_mean_medi",
        "m10_midpoint",
        "l10_midpoint"
      )
    if (specification$analysis_unit[[1L]] == "participant_day") {
      day |>
        dplyr::transmute(
          .data$site,
          .data$Id,
          .data$position,
          .data$local_date,
          .data$profile_variant,
          analysis_unit = "participant_day",
          metric = specification$metric_id[[1L]],
          value = .data[[source_field]],
          units = specification$source_unit[[1L]],
          estimable = TRUE,
          failure_reason = NA_character_,
          metric_support_available = !rolling_window_metric,
          metric_support_unavailability_reason = if (rolling_window_metric) {
            "test_support_not_exported"
          } else {
            NA_character_
          },
          valid_minutes = if (rolling_window_metric) NA_real_ else 1200,
          expected_minutes = if (rolling_window_metric) NA_real_ else 1440
        )
    } else {
      participant |>
        dplyr::transmute(
          .data$site,
          .data$Id,
          .data$position,
          local_date = as.Date(NA),
          .data$profile_variant,
          analysis_unit = "participant",
          metric = specification$metric_id[[1L]],
          value = .data[[source_field]],
          units = specification$source_unit[[1L]],
          estimable = TRUE,
          failure_reason = NA_character_,
          metric_support_available = TRUE,
          metric_support_unavailability_reason = NA_character_,
          valid_minutes = 2400,
          expected_minutes = 2880
        )
    }
  }) |>
    dplyr::bind_rows()
  admissibility <- support_rows |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$profile_variant,
      .data$analysis_unit,
      .data$metric,
      .data$estimable,
      .data$failure_reason,
      left_censored = FALSE,
      right_censored = FALSE,
      any_censored = FALSE
    )
  list(
    participant_day = day,
    participant = participant,
    admissibility = admissibility,
    metric_support = support_rows
  )
}

message("Testing the exact H01 metric contract")
contract <- h01_metric_contract(".")
stopifnot(
  nrow(contract) == 17L,
  sum(contract$analysis_unit == "participant") == 2L,
  sum(contract$analysis_unit == "participant_day") == 15L,
  !any(grepl("(m10|l10)_(onset|offset)", contract$metric_id))
)

message("Testing type-tolerant but value-strict CSV parity")
parity_expected <- tibble::tibble(
  count = c(1L, NA_integer_),
  unavailable_count = c(NA_integer_, NA_integer_),
  label = c("a", NA_character_),
  date = as.Date(c("2026-01-01", NA))
)
parity_observed <- tibble::tibble(
  count = c(1, NA_real_),
  unavailable_count = c(NA, NA),
  label = c("a", NA_character_),
  date = as.Date(c("2026-01-01", NA))
)
stopifnot(
  h01_csv_content_equal(parity_expected, parity_observed),
  !h01_csv_content_equal(
    parity_expected,
    dplyr::mutate(parity_observed, count = c(2, NA_real_))
  )
)

message("Testing swappable prepared-data inputs with unchanged model rules")
inputs <- list(
  glasses = make_h01_input("glasses", contract),
  chest = make_h01_input("chest", contract)
)
missing_index <- with(
  inputs$chest$metric_support,
  metric == "duration_above_250_wake" &
    site == "SITE_B" &
    local_date == as.Date("2026-01-02")
)
inputs$chest$metric_support$value[missing_index] <- NA_real_
inputs$chest$metric_support$estimable[missing_index] <- FALSE
inputs$chest$metric_support$failure_reason[missing_index] <-
  "test_low_support"
inputs$chest$admissibility$estimable[missing_index] <- FALSE
inputs$chest$admissibility$failure_reason[missing_index] <-
  "test_low_support"
inputs$chest$participant_day$duration_above_250_wake_h[4L] <- NA_real_

main <- h01_build_model_rows_from_inputs(
  inputs,
  contract,
  data_scenario_id = "main",
  model_implementation_id = "new_h01_h11"
)
prepared_sensitivity <- h01_build_model_rows_from_inputs(
  inputs,
  contract,
  data_scenario_id = "manuscript_prepared_data",
  model_implementation_id = "new_h01_h11"
)
stopifnot(
  nrow(main$rows) == 248L,
  identical(unique(main$rows$data_scenario_id), "main"),
  identical(
    unique(prepared_sensitivity$rows$data_scenario_id),
    "manuscript_prepared_data"
  ),
  identical(
    unique(main$rows$model_implementation_id),
    unique(prepared_sensitivity$rows$model_implementation_id)
  )
)

message("Testing paired joint estimability and exact reasons")
paired_missing <- main$rows |>
  dplyr::filter(
    .data$scenario == "paired_common_sample",
    .data$metric_id == "duration_above_250_wake",
    .data$site == "SITE_B",
    .data$local_date == as.Date("2026-01-02")
  ) |>
  dplyr::arrange(.data$placement)
stopifnot(
  nrow(paired_missing) == 2L,
  !any(paired_missing$scenario_estimable),
  !any(paired_missing$site_photoperiod_included),
  paired_missing$scenario_failure_reason[
    paired_missing$placement == "chest"
  ] ==
    "test_low_support",
  paired_missing$scenario_failure_reason[
    paired_missing$placement == "glasses"
  ] ==
    "paired_other_placement:test_low_support"
)

message("Testing exact participant, day, hour-support, and row counts")
scenario_status <- h01_scenario_status(
  contract,
  data_scenario_id = "main",
  model_implementation_id = "new_h01_h11"
)
flow <- h01_build_sample_flow(main$rows, scenario_status)
daily_flow <- flow |>
  dplyr::filter(
    .data$data_scenario_id == "main",
    .data$placement == "glasses",
    .data$scenario == "all_available",
    .data$metric_id == "daily_geometric_mean_medi",
    .data$stage == "site_photoperiod_model",
    .data$scope == "overall"
  )
participant_flow <- flow |>
  dplyr::filter(
    .data$data_scenario_id == "main",
    .data$placement == "glasses",
    .data$scenario == "all_available",
    .data$metric_id == "interdaily_stability",
    .data$stage == "site_photoperiod_model",
    .data$scope == "overall"
  )
m10_flow <- flow |>
  dplyr::filter(
    .data$data_scenario_id == "main",
    .data$placement == "glasses",
    .data$scenario == "all_available",
    .data$metric_id == "m10_mean_medi",
    .data$stage == "site_photoperiod_model",
    .data$scope == "overall"
  )
stopifnot(
  nrow(daily_flow) == 1L,
  daily_flow$model_observations == 4L,
  daily_flow$participants == 2L,
  daily_flow$participant_days == 4L,
  is.na(daily_flow$participant_hours),
  daily_flow$contributing_participant_days == 4L,
  daily_flow$metric_support_missing_observations == 0L,
  daily_flow$metric_support_valid_hours == 80,
  daily_flow$metric_support_expected_hours == 96,
  nrow(participant_flow) == 1L,
  participant_flow$model_observations == 2L,
  participant_flow$participants == 2L,
  is.na(participant_flow$participant_days),
  participant_flow$contributing_participant_days == 4L,
  participant_flow$metric_support_valid_hours == 80,
  participant_flow$metric_support_expected_hours == 96,
  m10_flow$metric_support_missing_observations == 4L,
  is.na(m10_flow$metric_support_valid_hours),
  is.na(m10_flow$metric_support_expected_hours)
)

message("Testing explicit unavailability of paired IS and IV")
unavailable <- scenario_status |>
  dplyr::filter(!.data$available)
stopifnot(
  nrow(scenario_status) == 68L,
  nrow(unavailable) == 4L,
  all(unavailable$analysis_unit == "participant"),
  all(
    unavailable$availability_reason ==
      h01_output_contract()$unavailable_scenario_reason
  )
)

message("Testing fail-closed H01 input contracts")
bad_reason <- inputs
bad_reason$chest$admissibility$failure_reason[missing_index] <-
  NA_character_
expect_error(h01_build_model_rows_from_inputs(bad_reason, contract))

bad_days <- inputs
bad_days$glasses$participant$days[1L] <- 3L
expect_error(h01_build_model_rows_from_inputs(bad_days, contract))

bad_support <- inputs
bad_support$glasses$metric_support$valid_minutes[1L] <- 3000
expect_error(h01_build_model_rows_from_inputs(bad_support, contract))

bad_variant <- inputs
bad_variant$glasses$admissibility$profile_variant[1L] <- "other"
expect_error(h01_build_model_rows_from_inputs(bad_variant, contract))

negative_l10 <- inputs
negative_l10$glasses$participant_day$l10_mean_medi_lx[1L] <- -5e-17
negative_l10$glasses$metric_support$value[
  negative_l10$glasses$metric_support$metric == "l10_mean_medi" &
    negative_l10$glasses$metric_support$site == "SITE_A" &
    negative_l10$glasses$metric_support$local_date == as.Date("2026-01-01")
] <- -5e-17
expect_error(h01_build_model_rows_from_inputs(negative_l10, contract))

message("All H01 model-data tests passed")
