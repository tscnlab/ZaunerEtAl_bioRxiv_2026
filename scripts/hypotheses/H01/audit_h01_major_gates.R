# Quantify the H01 response-support failures without changing shared inputs.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h01_abort(
    "The H01 gate audit requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

audit_root <- file.path(root, "audit/hypotheses/H01")
dir.create(audit_root, recursive = TRUE, showWarnings = FALSE)

input_contract <- h01_input_contract(root)
objects <- list(
  main = readRDS(input_contract$main$path),
  manuscript_prepared_data = readRDS(
    input_contract$manuscript_prepared_data$path
  )
)
registry <- h01_metric_registry()

summarize_gate_frame <- function(
  object,
  data_scenario_id,
  placement,
  metric_id
) {
  spec <- registry[
    registry$metric_id == metric_id,
    ,
    drop = FALSE
  ]
  frame <- h01_prepare_model_frame(
    object,
    spec,
    placement = placement,
    sample_scenario = "all_available"
  )
  list(spec = spec, frame = frame)
}

pre_sleep_rows <- dplyr::bind_rows(lapply(
  names(objects),
  function(data_scenario_id) {
    dplyr::bind_rows(lapply(c("glasses", "chest"), function(placement) {
      gate <- summarize_gate_frame(
        objects[[data_scenario_id]],
        data_scenario_id,
        placement,
        "duration_below_10_pre_sleep"
      )
      frame <- gate$frame
      audit_threshold_hours <- gate$spec$audit_upper_threshold
      over_single_interval <- frame$value > 3 + 1e-8
      over_audit_threshold <-
        frame$value > audit_threshold_hours + 1e-8
      expected_over_single_interval <-
        frame$metric_support_expected_minutes > 180 + 1e-8
      tibble::tibble(
        data_scenario_id = data_scenario_id,
        placement = placement,
        construct = "calendar_day_cumulative_pre_sleep_duration",
        audit_threshold_hours = audit_threshold_hours,
        values_truncated = FALSE,
        participants = dplyr::n_distinct(frame$participant_key),
        participant_days = nrow(frame),
        observations = nrow(frame),
        sites = dplyr::n_distinct(frame$site),
        days_above_single_interval_length = sum(
          over_single_interval,
          na.rm = TRUE
        ),
        fraction_above_single_interval_length = mean(
          over_single_interval,
          na.rm = TRUE
        ),
        days_above_audit_threshold = sum(
          over_audit_threshold,
          na.rm = TRUE
        ),
        fraction_above_audit_threshold = mean(
          over_audit_threshold,
          na.rm = TRUE
        ),
        maximum_duration_hours = max(frame$value, na.rm = TRUE),
        expected_support_above_single_interval_length = if (
          all(is.na(expected_over_single_interval))
        ) {
          NA_integer_
        } else {
          sum(expected_over_single_interval, na.rm = TRUE)
        },
        maximum_expected_support_hours = if (
          all(is.na(frame$metric_support_expected_minutes))
        ) {
          NA_real_
        } else {
          max(frame$metric_support_expected_minutes, na.rm = TRUE) / 60
        },
        audit_threshold_status = if (
          any(over_audit_threshold, na.rm = TRUE)
        ) {
          "WARN_ABOVE_SIX_HOUR_AUDIT_THRESHOLD"
        } else {
          "PASS"
        }
      )
    }))
  }
))

minimal_circular_arc <- function(hours) {
  hours <- sort(hours %% 24)
  if (length(hours) < 2L) {
    return(tibble::tibble(
      minimum_covering_arc_hours = 0,
      largest_empty_gap_hours = 24,
      largest_gap_start_hour = hours[[1L]],
      largest_gap_end_hour = hours[[1L]]
    ))
  }
  gaps <- c(diff(hours), hours[[1L]] + 24 - hours[[length(hours)]])
  gap_index <- which.max(gaps)
  gap_start <- hours[[gap_index]]
  gap_end <- if (gap_index == length(hours)) {
    hours[[1L]]
  } else {
    hours[[gap_index + 1L]]
  }
  tibble::tibble(
    minimum_covering_arc_hours = 24 - gaps[[gap_index]],
    largest_empty_gap_hours = gaps[[gap_index]],
    largest_gap_start_hour = gap_start,
    largest_gap_end_hour = gap_end
  )
}

l10_rows <- dplyr::bind_rows(lapply(
  names(objects),
  function(data_scenario_id) {
    dplyr::bind_rows(lapply(c("glasses", "chest"), function(placement) {
      gate <- summarize_gate_frame(
        objects[[data_scenario_id]],
        data_scenario_id,
        placement,
        "l10_midpoint"
      )
      frame <- gate$frame
      primary_transformed <- frame$response_value
      noon_transformed <- h01_transform_response(
        frame$value,
        "clock_hours_midnight_after_12"
      )
      arc <- minimal_circular_arc(frame$value / 60)
      dplyr::bind_cols(
        tibble::tibble(
          data_scenario_id = data_scenario_id,
          placement = placement,
          participants = dplyr::n_distinct(frame$participant_key),
          participant_days = nrow(frame),
          observations = nrow(frame),
          sites = dplyr::n_distinct(frame$site),
          primary_cut_hour = 16,
          sensitivity_cut_hour = 12,
          shift_rule = "subtract_24_only_when_clock_hour_is_strictly_later",
          observations_exactly_at_primary_cut = sum(
            abs((frame$value / 60) - 16) <= .Machine$double.eps^0.5
          ),
          primary_transformed_minimum_hour = min(primary_transformed),
          primary_transformed_maximum_hour = max(primary_transformed),
          primary_transformed_span_hours = diff(range(primary_transformed)),
          noon_transformed_minimum_hour = min(noon_transformed),
          noon_transformed_maximum_hour = max(noon_transformed),
          noon_transformed_span_hours = diff(range(noon_transformed)),
          changed_between_primary_and_noon = sum(
            abs(primary_transformed - noon_transformed) > 1e-12
          ),
          observations_within_one_hour_of_primary_cut = sum(
            abs((frame$value / 60) - 16) <= 1
          )
        ),
        arc,
        tibble::tibble(
          linearization_status = "PASS_APPROVED_STRICT_AFTER_16_PRIMARY",
          noon_sensitivity_status = "REGISTERED"
        )
      )
    }))
  }
))

interval_paths <- list.files(
  file.path(root, "artifacts/02_aligned/state_intervals"),
  pattern = "_sleep_intervals[.]rds$",
  full.names = TRUE
)
intervals <- dplyr::bind_rows(lapply(interval_paths, readRDS)) |>
  dplyr::filter(.data$State.Brown == "pre-sleep")

split_interval_by_local_date <- function(row) {
  timezone <- row$timezone[[1L]]
  start_local <- lubridate::with_tz(row$start[[1L]], timezone)
  end_local <- lubridate::with_tz(row$end[[1L]], timezone)
  local_dates <- seq(
    as.Date(start_local, tz = timezone),
    as.Date(end_local - 1, tz = timezone),
    by = "day"
  )
  dplyr::bind_rows(lapply(local_dates, function(local_date) {
    day_start_local <- as.POSIXct(
      paste(local_date, "00:00:00"),
      tz = timezone
    )
    day_end_local <- as.POSIXct(
      paste(local_date + 1, "00:00:00"),
      tz = timezone
    )
    overlap_start <- max(start_local, day_start_local)
    overlap_end <- min(end_local, day_end_local)
    tibble::tibble(
      site = row$site[[1L]],
      Id = row$Id[[1L]],
      participant_key = paste(row$site[[1L]], row$Id[[1L]], sep = "::"),
      local_date = as.character(local_date),
      sleep_source_row = row$sleep_source_row_start[[1L]],
      overlap_minutes = as.numeric(difftime(
        overlap_end,
        overlap_start,
        units = "mins"
      ))
    )
  }))
}

interval_day_rows <- dplyr::bind_rows(lapply(
  seq_len(nrow(intervals)),
  function(index) split_interval_by_local_date(intervals[index, ])
)) |>
  dplyr::filter(.data$overlap_minutes > 0) |>
  dplyr::group_by(
    .data$site,
    .data$participant_key,
    .data$local_date
  ) |>
  dplyr::summarise(
    pre_sleep_source_intervals = dplyr::n_distinct(.data$sleep_source_row),
    pre_sleep_interval_minutes_on_date = sum(.data$overlap_minutes),
    .groups = "drop"
  )

main_pre_sleep <- dplyr::bind_rows(lapply(
  c("glasses", "chest"),
  function(placement) {
    summarize_gate_frame(
      objects$main,
      "main",
      placement,
      "duration_below_10_pre_sleep"
    )$frame |>
      dplyr::transmute(
        placement = placement,
        site = as.character(.data$site),
        participant_key = as.character(.data$participant_key),
        local_date = as.character(.data$local_date),
        fitted_duration_hours = .data$value,
        metric_support_expected_minutes =
          .data$metric_support_expected_minutes
      )
  }
)) |>
  dplyr::left_join(
    interval_day_rows,
    by = c("site", "participant_key", "local_date"),
    relationship = "many-to-one"
  ) |>
  dplyr::filter(
    .data$fitted_duration_hours > 3 + 1e-8 |
      .data$metric_support_expected_minutes > 180 + 1e-8
  ) |>
  dplyr::arrange(
    .data$placement,
    dplyr::desc(.data$fitted_duration_hours),
    .data$site,
    .data$participant_key,
    .data$local_date
  )

readr::write_csv(
  pre_sleep_rows,
  file.path(audit_root, "H01_gate_a_pre_sleep_calendar_day.csv"),
  na = ""
)
readr::write_csv(
  l10_rows,
  file.path(audit_root, "H01_gate_b_l10_conversion.csv"),
  na = ""
)
readr::write_csv(
  main_pre_sleep,
  file.path(audit_root, "H01_shared_pre_sleep_interval_evidence.csv"),
  na = ""
)

session <- tibble::tibble(
  r_version = as.character(getRversion()),
  command = paste(
    "RENV_CONFIG_SANDBOX_ENABLED=FALSE",
    "NATHEALTH_PROJECT_ROOT=<project>",
    "Rscript scripts/hypotheses/H01/audit_h01_major_gates.R"
  ),
  main_manifest_sha256 = artifact_sha256(input_contract$main$manifest),
  manuscript_prepared_manifest_sha256 = artifact_sha256(
    input_contract$manuscript_prepared_data$manifest
  ),
  state_interval_manifest_sha256 = artifact_sha256(file.path(
    root,
    "artifacts/12_manifests/state_interval_artifacts.csv"
  )),
  fit_output_manifest_sha256 = artifact_sha256(file.path(
    root,
    "artifacts/12_manifests/H01_model_results_artifacts.csv"
  )),
  script_sha256 = artifact_sha256(file.path(
    root,
    "scripts/hypotheses/H01/audit_h01_major_gates.R"
  ))
)
readr::write_csv(
  session,
  file.path(audit_root, "H01_major_gate_provenance.csv"),
  na = ""
)

message("H01 major-gate audit completed")
