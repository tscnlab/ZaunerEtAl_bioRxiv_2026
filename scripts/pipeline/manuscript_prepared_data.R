# Define the frozen-input contract for the manuscript-prepared-data sensitivity.
#
# Source paths_io.R, assertions.R, metric_display_registry.R, and
# time_support.R first.

manuscript_prepared_scenario_id <- function() {
  "manuscript_prepared_data"
}

manuscript_prepared_model_implementation_id <- function() {
  "new_h01_h11"
}

manuscript_prepared_positions <- function() {
  c("glasses", "chest")
}

manuscript_prepared_source_contract <- function() {
  data.frame(
    source_id = c(
      "metrics_separate_glasses",
      "metrics_separate_chest",
      "metrics_glasses",
      "metrics_chest",
      "preprocessed_glasses_2",
      "preprocessed_chest_2"
    ),
    position = rep(manuscript_prepared_positions(), 3L),
    source_role = c(
      rep("participant_participant_day_and_30_minute", 2L),
      rep("manuscript_model_input_metrics", 2L),
      rep("one_minute_input_for_mder_and_one_hour_aggregation", 2L)
    ),
    path = file.path(
      "data",
      c(
        "metrics_separate_glasses.RData",
        "metrics_separate_chest.RData",
        "metrics_glasses.RData",
        "metrics_chest.RData",
        "preprocessed_glasses_2.RData",
        "preprocessed_chest_2.RData"
      )
    ),
    expected_sha256 = c(
      "f4b8ddfdbd4ee2e577957ed6a89f65a7b44581bba916e786147dcd40c94a234b",
      "f1ab7345966bdaa8705a03745798d99c3d945fe0119f2476a5dd6e9a53f5de2f",
      "9595cb7c574672cf2c8ff89ac3d227f3f7ff11eca57776609e19599561b2d441",
      "4498d677a8fc7d47168ab2f03731f2dc67b419102b7c818305925273d57c818c",
      "0d00bac25d955d45447f74cc9c3ad6a5f5dfa1de1282d8d619c9468f72e0c430",
      "b289c17c64d1bd24166fa3873da9aa8f22a5f57c793a7282ecb201dc77dcd274"
    ),
    expected_bytes = c(
      782870,
      855909,
      245562,
      257469,
      10949538,
      11996039
    ),
    expected_objects = c(
      paste(
        "metric_glasses_participant",
        "metric_glasses_participantday",
        "metric_glasses_participanthour",
        sep = "|"
      ),
      paste(
        "metric_chest_participant",
        "metric_chest_participantday",
        "metric_chest_participanthour",
        sep = "|"
      ),
      "metrics_glasses",
      "metrics_chest",
      "light_glasses_processed2",
      "light_chest_processed2"
    ),
    stringsAsFactors = FALSE
  )
}

manuscript_prepared_load_rdata <- function(path, expected_objects) {
  if (!file.exists(path)) {
    abort_pipeline("Frozen manuscript-prepared input is missing: %s", path)
  }
  environment <- new.env(parent = emptyenv())
  loaded <- sort(load(path, envir = environment))
  expected <- sort(strsplit(expected_objects, "|", fixed = TRUE)[[1L]])
  if (!identical(loaded, expected)) {
    abort_pipeline(
      paste0(
        "Frozen input `%s` contains object(s) `%s`; expected exactly `%s`"
      ),
      path,
      paste(loaded, collapse = ", "),
      paste(expected, collapse = ", ")
    )
  }
  stats::setNames(
    lapply(loaded, function(name) environment[[name]]),
    loaded
  )
}

manuscript_prepared_load_sources <- function(root = project_root()) {
  contract <- manuscript_prepared_source_contract()
  objects <- vector("list", nrow(contract))
  names(objects) <- contract$source_id
  manifest <- vector("list", nrow(contract))

  for (index in seq_len(nrow(contract))) {
    specification <- contract[index, , drop = FALSE]
    path <- file.path(root, specification$path)
    actual_sha256 <- artifact_sha256(path)
    actual_bytes <- unname(file.info(path)$size)
    if (
      !identical(actual_sha256, specification$expected_sha256) ||
        !identical(as.numeric(actual_bytes), specification$expected_bytes)
    ) {
      abort_pipeline(
        paste0(
          "Frozen input `%s` does not match its fixed fingerprint. ",
          "Expected %s bytes and SHA-256 %s; found %s bytes and %s"
        ),
        specification$path,
        specification$expected_bytes,
        specification$expected_sha256,
        actual_bytes,
        actual_sha256
      )
    }
    objects[[specification$source_id]] <- manuscript_prepared_load_rdata(
      path,
      specification$expected_objects
    )
    manifest[[index]] <- data.frame(
      scenario_id = manuscript_prepared_scenario_id(),
      model_implementation_id = manuscript_prepared_model_implementation_id(),
      source_kind = "frozen_rdata",
      source_id = specification$source_id,
      position = specification$position,
      source_role = specification$source_role,
      path = specification$path,
      expected_sha256 = specification$expected_sha256,
      actual_sha256 = actual_sha256,
      bytes = as.numeric(actual_bytes),
      expected_objects = specification$expected_objects,
      loaded_objects = paste(
        sort(names(objects[[specification$source_id]])),
        collapse = "|"
      ),
      verification_status = "PASS",
      stringsAsFactors = FALSE
    )
  }

  list(
    objects = objects,
    manifest = dplyr::bind_rows(manifest)
  )
}

manuscript_prepared_metric_mapping <- function(root = project_root()) {
  mapping <- data.frame(
    metric_order = seq_len(20L),
    frozen_name = c(
      "interdaily_stability",
      "intradaily_variability",
      "Mean",
      "brightest_10h_mean",
      "darkest_10h_mean",
      "duration_above_1000",
      "duration_above_250",
      "duration_above_250_wake",
      "duration_below_10_pre-sleep",
      "duration_below_1_sleep",
      "period_above_250",
      "brightest_10h_midpoint",
      "darkest_10h_midpoint",
      "mean_timing_above_250",
      "first_timing_above_250",
      "last_timing_above_250",
      "dose",
      "MDER",
      "MEDI",
      "geo.MEDI"
    ),
    metric_id = c(
      "interdaily_stability",
      "intradaily_variability",
      "daily_geometric_mean_medi",
      "m10_mean_medi",
      "l10_mean_medi",
      "duration_above_1000",
      "duration_above_250_full_day",
      "duration_above_250_wake",
      "duration_below_10_pre_sleep",
      "duration_below_1_sleep_environment",
      "longest_bout_above_250",
      "m10_midpoint",
      "l10_midpoint",
      "mean_timing_above_250",
      "first_timing_above_250",
      "last_timing_above_250",
      "dose_time_sensitive_corrected_medi",
      "mder_mean_of_viable_ratios",
      "thirty_minute_arithmetic_medi",
      "one_hour_geometric_mean_medi"
    ),
    source_unit = c(
      rep("dimensionless", 2L),
      rep("lx", 3L),
      rep("h", 6L),
      rep("decimal_clock_hour", 5L),
      "lx_h",
      "dimensionless",
      "lx",
      "lx"
    ),
    analysis_unit = c(
      rep("participant", 2L),
      rep("participant_day", 16L),
      "30_minute",
      "one_hour"
    ),
    selected_for_h01 = c(
      rep(TRUE, 6L),
      FALSE,
      rep(TRUE, 11L),
      FALSE,
      FALSE
    ),
    value_definition = c(
      "Manuscript-prepared interdaily stability",
      "Manuscript-prepared intradaily variability",
      "Manuscript-prepared daily zero-aware geometric mean melEDI",
      "Manuscript-prepared brightest 10-hour mean melEDI",
      "Manuscript-prepared darkest 10-hour mean melEDI",
      "Manuscript-prepared time above 1,000 lx melEDI",
      "Manuscript-prepared full-day time above 250 lx melEDI",
      "Manuscript-prepared waking time above 250 lx melEDI",
      "Manuscript-prepared pre-sleep time below 10 lx melEDI",
      "Manuscript-prepared sleep time below 1 lx melEDI",
      "Manuscript-prepared longest observed period above 250 lx melEDI",
      "Manuscript-prepared midpoint of the brightest 10 hours",
      "Manuscript-prepared midpoint of the darkest 10 hours",
      "Manuscript-prepared mean timing above 250 lx melEDI",
      "Manuscript-prepared first timing above 250 lx melEDI",
      "Manuscript-prepared last timing above 250 lx melEDI",
      paste(
        "Manuscript-prepared melEDI dose without the new time-sensitive",
        "coverage correction"
      ),
      paste(
        "Gap-timing-unaware arithmetic mean of viable positive finite",
        "one-minute melEDI/illuminance ratios"
      ),
      "Manuscript-prepared 30-minute arithmetic mean melEDI",
      "Manuscript-prepared one-hour zero-aware geometric mean melEDI"
    ),
    stringsAsFactors = FALSE
  )
  display <- read_metric_display_registry(root) |>
    dplyr::rename(display_analysis_unit = "analysis_unit")
  mapping <- dplyr::left_join(
    mapping,
    display,
    by = "metric_id",
    relationship = "many-to-one"
  )
  expected_display_unit <- c(
    participant = "participant",
    participant_day = "participant_day",
    `30_minute` = "participant_30_minute",
    one_hour = "participant_hour"
  )[mapping$analysis_unit]
  if (
    nrow(mapping) != 20L ||
      anyDuplicated(mapping$metric_order) ||
      anyDuplicated(mapping$metric_id) ||
      anyNA(mapping$manuscript_name) ||
      any(
        gsub("-", "_", mapping$display_analysis_unit, fixed = TRUE) !=
          unname(expected_display_unit)
      ) ||
      sum(mapping$selected_for_h01) != 17L ||
      any(
        grepl(
          "(^|_)(m10|l10)_(onset|offset)($|_)",
          mapping$metric_id,
          perl = TRUE
        )
      )
  ) {
    abort_pipeline("Manuscript-prepared metric mapping is invalid")
  }
  mapping
}

manuscript_prepared_position_role <- function(position) {
  ifelse(
    position == "glasses",
    "near_eye_primary",
    "complementary_chest"
  )
}

manuscript_prepared_add_ids <- function(data, position) {
  data |>
    dplyr::mutate(
      scenario_id = manuscript_prepared_scenario_id(),
      model_implementation_id = manuscript_prepared_model_implementation_id(),
      position = position,
      position_role = manuscript_prepared_position_role(position),
      .before = 1L
    )
}

manuscript_prepared_extract_metric_rows <- function(
  nested_metrics,
  mapping,
  position,
  analysis_unit
) {
  expected_type <- gsub("_", "-", analysis_unit, fixed = TRUE)
  selected_mapping <- mapping[
    mapping$analysis_unit == analysis_unit,
    ,
    drop = FALSE
  ]
  available <- nested_metrics[
    nested_metrics$type == expected_type &
      nested_metrics$name %in% selected_mapping$frozen_name,
    ,
    drop = FALSE
  ]
  if (
    nrow(available) != nrow(selected_mapping) ||
      !setequal(available$name, selected_mapping$frozen_name)
  ) {
    abort_pipeline(
      "Nested %s metrics do not match the declared mapping for %s",
      analysis_unit,
      position
    )
  }

  rows <- lapply(seq_len(nrow(selected_mapping)), function(index) {
    specification <- selected_mapping[index, , drop = FALSE]
    nested_index <- match(specification$frozen_name, nested_metrics$name)
    data <- nested_metrics$data[[nested_index]]
    required <- c("site", "Id", "metric")
    if (analysis_unit == "participant_day") {
      required <- c(required, "Date")
    }
    assert_columns(
      data,
      required,
      object = paste(position, specification$frozen_name)
    )
    result <- data.frame(
      site = as.character(data$site),
      Id = as.character(data$Id),
      metric_id = specification$metric_id,
      manuscript_prepared_value = as.numeric(data$metric),
      stringsAsFactors = FALSE
    )
    if (analysis_unit == "participant_day") {
      result$local_date <- as.Date(as.character(data$Date))
      result <- result[
        c(
          "site",
          "Id",
          "local_date",
          "metric_id",
          "manuscript_prepared_value"
        )
      ]
    }
    result
  })
  result <- dplyr::bind_rows(rows)
  result <- manuscript_prepared_add_ids(result, position)
  key <- c("scenario_id", "position", "site", "Id", "metric_id")
  if (analysis_unit == "participant_day") {
    key <- append(key, "local_date", after = 4L)
  }
  assert_unique_key(result, key, paste(position, analysis_unit, "metrics"))
  result
}

manuscript_prepared_mder_metric_id <- function() {
  "mder_mean_of_viable_ratios"
}

manuscript_prepared_mder_minimum_fraction <- function() {
  0.50
}

manuscript_prepared_mder_expected_minutes <- function() {
  1440L
}

manuscript_prepared_mean_finite <- function(value) {
  finite <- is.finite(value)
  if (!any(finite)) {
    return(NA_real_)
  }
  mean(value[finite])
}

manuscript_prepared_build_mder_support <- function(data, position) {
  assert_columns(
    data,
    c("site", "Id", "Datetime", "Date", "MEDI", "LIGHT"),
    object = paste(position, "frozen one-minute MDER input")
  )
  if (!position %in% manuscript_prepared_positions()) {
    abort_pipeline("Unknown manuscript-prepared position: %s", position)
  }

  minute_input <- data |>
    dplyr::ungroup() |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$Date),
      datetime_date = as.Date(format(.data$Datetime, tz = "UTC")),
      local_clock_minute =
        as.integer(format(.data$Datetime, "%H", tz = "UTC")) * 60L +
          as.integer(format(.data$Datetime, "%M", tz = "UTC")),
      medi = as.numeric(.data$MEDI),
      light = as.numeric(.data$LIGHT)
    )
  if (
    anyNA(minute_input$site) ||
      anyNA(minute_input$Id) ||
      anyNA(minute_input$local_date) ||
      anyNA(minute_input$local_clock_minute) ||
      any(minute_input$local_date != minute_input$datetime_date) ||
      any(
        minute_input$local_clock_minute < 0L |
          minute_input$local_clock_minute >=
            manuscript_prepared_mder_expected_minutes()
      )
  ) {
    abort_pipeline(
      "Frozen %s one-minute data have invalid local-day or minute keys",
      position
    )
  }

  collapsed <- minute_input |>
    dplyr::group_by(
      .data$site,
      .data$Id,
      .data$local_date,
      .data$local_clock_minute
    ) |>
    dplyr::summarise(
      medi = manuscript_prepared_mean_finite(.data$medi),
      light = manuscript_prepared_mean_finite(.data$light),
      source_rows = dplyr::n(),
      .groups = "drop"
    )
  day_counts <- collapsed |>
    dplyr::count(.data$site, .data$Id, .data$local_date, name = "local_minutes")
  if (any(day_counts$local_minutes > manuscript_prepared_mder_expected_minutes())) {
    abort_pipeline("Frozen %s input contains more than 1,440 local minutes", position)
  }
  support <- collapsed |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$local_date,
      .data$local_clock_minute
    ) |>
    dplyr::group_by(.data$site, .data$Id, .data$local_date) |>
    dplyr::group_modify(function(.data, .key) {
      missing_minutes <-
        manuscript_prepared_mder_expected_minutes() - nrow(.data)
      medi <- c(.data$medi, rep(NA_real_, missing_minutes))
      light <- c(.data$light, rep(NA_real_, missing_minutes))
      result <- mder_mean_of_viable_ratios(
        medi = medi,
        light = light,
        minimum_viable_fraction =
          manuscript_prepared_mder_minimum_fraction()
      )
      raw_source_rows <- as.integer(sum(.data$source_rows, na.rm = TRUE))
      observed_local_minutes <- as.integer(nrow(.data))
      duplicated_local_minutes <- as.integer(
        sum(.data$source_rows > 1L, na.rm = TRUE)
      )
      duplicate_source_rows <- as.integer(
        sum(pmax(.data$source_rows - 1L, 0L), na.rm = TRUE)
      )
      dplyr::mutate(
        result,
        raw_source_rows = raw_source_rows,
        observed_local_minutes = observed_local_minutes,
        duplicated_local_minutes = duplicated_local_minutes,
        duplicate_source_rows = duplicate_source_rows
      )
    }) |>
    dplyr::ungroup() |>
    dplyr::rename(manuscript_prepared_value = "MDER") |>
    dplyr::mutate(
      metric_id = manuscript_prepared_mder_metric_id(),
      metric_decision_id = "METRIC-010",
      duplicate_minute_rule = "channel_mean_before_ratio",
      expected_day_rule = "complete_1440_local_wall_clock_minutes"
    ) |>
    manuscript_prepared_add_ids(position) |>
    dplyr::select(
      "scenario_id",
      "model_implementation_id",
      "position",
      "position_role",
      "site",
      "Id",
      "local_date",
      "metric_id",
      "metric_decision_id",
      "manuscript_prepared_value",
      "viable_ratio_minutes",
      "expected_minutes",
      "viable_ratio_fraction",
      "raw_source_rows",
      "observed_local_minutes",
      "duplicated_local_minutes",
      "duplicate_source_rows",
      "excluded_nonfinite_source_minutes",
      "excluded_zero_either_minutes",
      "excluded_zero_medi_minutes",
      "excluded_zero_light_minutes",
      "excluded_both_zero_minutes",
      "excluded_nonfinite_ratio_minutes",
      "minimum_viable_fraction",
      "passes_viable_ratio_support",
      "support_threshold_enforced",
      "ratio_scaled_or_weighted",
      "estimable",
      "failure_reason",
      "duplicate_minute_rule",
      "expected_day_rule"
    )

  assert_unique_key(
    support,
    c("scenario_id", "position", "site", "Id", "local_date", "metric_id"),
    paste(position, "manuscript-prepared MDER support")
  )
  if (
    any(support$expected_minutes !=
      manuscript_prepared_mder_expected_minutes()) ||
      any(support$minimum_viable_fraction !=
        manuscript_prepared_mder_minimum_fraction()) ||
      any(
        is.finite(support$manuscript_prepared_value) &
          support$manuscript_prepared_value <= 0
      ) ||
      any(
        support$estimable !=
          (support$passes_viable_ratio_support &
            is.na(support$failure_reason) &
            is.finite(support$manuscript_prepared_value))
      )
  ) {
    abort_pipeline("Rebuilt %s MDER support is internally inconsistent", position)
  }
  support
}

manuscript_prepared_replace_mder <- function(participant_day, support) {
  key <- c(
    "scenario_id",
    "model_implementation_id",
    "position",
    "position_role",
    "site",
    "Id",
    "local_date",
    "metric_id"
  )
  mder_rows <- participant_day |>
    dplyr::filter(.data$metric_id == manuscript_prepared_mder_metric_id())
  if (
    nrow(mder_rows) != nrow(support) ||
      nrow(dplyr::anti_join(mder_rows, support, by = key)) != 0L ||
      nrow(dplyr::anti_join(support, mder_rows, by = key)) != 0L
  ) {
    abort_pipeline(
      "Rebuilt MDER support does not match the participant-day key set"
    )
  }
  replacement <- dplyr::select(
    support,
    dplyr::all_of(key),
    replacement_value = "manuscript_prepared_value"
  ) |>
    dplyr::mutate(replacement_present = TRUE)
  result <- participant_day |>
    dplyr::mutate(.row_order = dplyr::row_number()) |>
    dplyr::left_join(replacement, by = key, relationship = "many-to-one") |>
    dplyr::mutate(
      manuscript_prepared_value = dplyr::if_else(
        .data$metric_id == manuscript_prepared_mder_metric_id(),
        .data$replacement_value,
        .data$manuscript_prepared_value
      )
    ) |>
    dplyr::arrange(.data$.row_order)
  if (
    any(
      result$metric_id == manuscript_prepared_mder_metric_id() &
        is.na(result$replacement_present)
    ) ||
      any(
        result$metric_id != manuscript_prepared_mder_metric_id() &
          !is.na(result$replacement_present)
      )
  ) {
    abort_pipeline("MDER replacement did not preserve the declared scope")
  }
  dplyr::select(
    result,
    -".row_order",
    -"replacement_value",
    -"replacement_present"
  )
}

manuscript_prepared_add_occurrence <- function(data) {
  assert_columns(
    data,
    c("site", "Id", "Datetime"),
    object = "local-clock data"
  )
  data |>
    dplyr::ungroup() |>
    dplyr::group_by(.data$site, .data$Id, .data$Datetime) |>
    dplyr::mutate(local_occurrence = dplyr::row_number()) |>
    dplyr::ungroup()
}

manuscript_prepared_normalize_clock_data <- function(
  data,
  position,
  analysis_unit
) {
  assert_columns(
    data,
    c(
      "site",
      "Id",
      "Datetime",
      "Date",
      "MEDI",
      "geo.MEDI",
      "LIGHT",
      "sleep",
      "State.Brown",
      "wear",
      "photoperiod.state",
      "is.implicit",
      "dawn",
      "dusk",
      "local_occurrence"
    ),
    object = paste(position, analysis_unit, "clock data")
  )
  result <- data.frame(
    site = as.character(data$site),
    Id = as.character(data$Id),
    local_date = as.Date(as.character(data$Date)),
    local_clock_datetime_utc_proxy = as.POSIXct(data$Datetime, tz = "UTC"),
    local_clock_label = format(
      data$Datetime,
      format = "%Y-%m-%d %H:%M:%S",
      tz = "UTC"
    ),
    local_occurrence = as.integer(data$local_occurrence),
    medi_arithmetic_mean_lx = as.numeric(data$MEDI),
    medi_geometric_mean_lx = as.numeric(data$geo.MEDI),
    photopic_illuminance_mean_lx = as.numeric(data$LIGHT),
    sleep_diary_state = as.character(data$sleep),
    analysis_state = as.character(data$State.Brown),
    wear_state = as.character(data$wear),
    photoperiod_state = as.character(data$photoperiod.state),
    state_was_implicit = as.logical(data$is.implicit),
    dawn_local_clock_utc_proxy = as.POSIXct(data$dawn, tz = "UTC"),
    dusk_local_clock_utc_proxy = as.POSIXct(data$dusk, tz = "UTC"),
    stringsAsFactors = FALSE
  )
  result <- manuscript_prepared_add_ids(result, position)
  result$analysis_unit <- analysis_unit
  result <- result[
    c(
      "scenario_id",
      "model_implementation_id",
      "position",
      "position_role",
      "analysis_unit",
      setdiff(
        names(result),
        c(
          "scenario_id",
          "model_implementation_id",
          "position",
          "position_role",
          "analysis_unit"
        )
      )
    )
  ]
  assert_unique_key(
    result,
    c(
      "scenario_id",
      "position",
      "site",
      "Id",
      "local_clock_label",
      "local_occurrence"
    ),
    paste(position, analysis_unit, "normalized clock data")
  )
  result
}

manuscript_prepared_build_one_hour <- function(data) {
  required <- c(
    "site",
    "Id",
    "Datetime",
    "Date",
    "MEDI",
    "LIGHT"
  )
  assert_columns(data, required, object = "frozen one-minute data")
  hourly <- LightLogR::aggregate_Datetime(
    dplyr::group_by(data, .data$site, .data$Id),
    "1 hour",
    type = "floor",
    numeric.handler = function(value) mean(value, na.rm = TRUE),
    geo.MEDI = LightLogR::exp_zero_inflated(
      mean(LightLogR::log_zero_inflated(MEDI), na.rm = TRUE)
    )
  ) |>
    LightLogR::add_Date_col(group.by = TRUE) |>
    dplyr::ungroup() |>
    dplyr::group_by(.data$site, .data$Id, .data$Date) |>
    dplyr::mutate(
      manuscript_static_day = all(.data$MEDI == .data$MEDI[[1L]])
    ) |>
    dplyr::filter(!.data$manuscript_static_day) |>
    dplyr::select(-"manuscript_static_day") |>
    dplyr::ungroup() |>
    dplyr::mutate(local_occurrence = 1L)
  hourly
}

manuscript_prepared_normalized_input_references <- function(
  root = project_root()
) {
  manifest_path <- file.path(
    root,
    "artifacts",
    "12_manifests",
    "model_input_normalization.csv"
  )
  if (!file.exists(manifest_path)) {
    abort_pipeline("Normalized-input manifest is missing: %s", manifest_path)
  }
  manifest <- utils::read.csv(
    manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  modalities <- c(
    "demographics",
    "chronotype",
    "leba",
    "vlsq8",
    "exercisediary",
    "lightexposurediary",
    "sleepdiaries"
  )
  selected <- manifest[
    manifest$artifact_type == "rds" &
      manifest$modality %in% modalities,
    ,
    drop = FALSE
  ]
  if (
    nrow(selected) != length(modalities) ||
      !setequal(selected$modality, modalities) ||
      anyDuplicated(selected$modality)
  ) {
    abort_pipeline(
      "Normalized-input manifest does not contain exactly the seven inputs"
    )
  }
  actual <- vapply(
    file.path(root, selected$path),
    artifact_sha256,
    character(1)
  )
  if (!identical(unname(actual), selected$sha256)) {
    abort_pipeline("A shared normalized input does not match its manifest")
  }
  data.frame(
    scenario_id = manuscript_prepared_scenario_id(),
    model_implementation_id = manuscript_prepared_model_implementation_id(),
    source_kind = "shared_verified_normalized_input",
    source_id = paste0("normalized_", selected$modality),
    position = NA_character_,
    source_role = selected$modality,
    path = selected$path,
    expected_sha256 = selected$sha256,
    actual_sha256 = unname(actual),
    bytes = selected$bytes,
    expected_objects = "one_rds_object",
    loaded_objects = "one_rds_object",
    verification_status = "PASS",
    stringsAsFactors = FALSE
  )
}

manuscript_prepared_correction_manifest <- function(root = project_root()) {
  exercise <- readRDS(
    file.path(
      root,
      "artifacts",
      "06_model_data",
      "normalized_inputs",
      "exercisediary.rds"
    )
  )
  dates <- seq(as.Date("2024-05-13"), as.Date("2024-05-19"), by = "day")
  corrected <- exercise[
    exercise$site == "TUM" &
      exercise$Id == "TUM_S001" &
      exercise$Date %in% dates,
    ,
    drop = FALSE
  ]
  erroneous <- exercise[
    exercise$site == "TUM" &
      exercise$Id == "TUM_S101",
    ,
    drop = FALSE
  ]
  if (
    nrow(corrected) != 7L ||
      nrow(erroneous) != 0L ||
      !setequal(corrected$Date, dates) ||
      !all(
        corrected$source_commit == "618fda8521f3cf581661ceb2c026e3de7cd9ba82"
      )
  ) {
    abort_pipeline(
      "The shared exercise input does not contain the verified DEV-056 repair"
    )
  }
  data.frame(
    scenario_id = manuscript_prepared_scenario_id(),
    correction_id = "DEV-056",
    correction_scope = "shared_normalized_exercise_diary",
    affected_rows = 7L,
    affected_site = "TUM",
    affected_dates = "2024-05-13/2024-05-19",
    erroneous_value = "TUM_S101",
    corrected_value = "TUM_S001",
    scientific_light_values_changed = FALSE,
    evidence = paste(
      "audit/findings/preparation05_input_provenance_gaps.md;",
      "audit/reconciliation/preparation06/normalization_gate.md"
    ),
    stringsAsFactors = FALSE
  )
}

manuscript_prepared_variable_dictionary <- function() {
  dictionary <- data.frame(
    variable = c(
      "scenario_id",
      "model_implementation_id",
      "position",
      "position_role",
      "site",
      "Id",
      "local_date",
      "local_clock_datetime_utc_proxy",
      "local_clock_label",
      "local_occurrence",
      "metric_id",
      "manuscript_prepared_value",
      "medi_arithmetic_mean_lx",
      "medi_geometric_mean_lx",
      "photopic_illuminance_mean_lx",
      "sleep_diary_state",
      "analysis_state",
      "wear_state",
      "photoperiod_state",
      "state_was_implicit",
      "dawn_local_clock_utc_proxy",
      "dusk_local_clock_utc_proxy"
    ),
    definition = c(
      "Prepared-data scenario identifier",
      "H01-H11 model implementation applied to the scenario",
      "Logger placement",
      "Near-eye primary or complementary chest role",
      "Study site",
      "Participant identifier",
      "Participant-day local date",
      paste(
        "Shared UTC-class column used as a local-clock proxy;",
        "it is not physical UTC"
      ),
      "Printed local-clock proxy used in portable keys",
      paste(
        "Occurrence of the same participant local-clock timestamp;",
        "retains repeated fall-back times"
      ),
      "Metric identifier aligned with the display registry",
      "Scientific value stored in the manuscript-prepared model input",
      "Arithmetic mean melEDI in the time bin",
      "Zero-aware geometric mean melEDI in the time bin",
      "Arithmetic mean photopic illuminance in the time bin",
      "Sleep-diary state carried by the prepared data",
      "Prepared wake/pre-sleep/sleep analysis state",
      "Prepared wear state",
      "Day/night state",
      "Whether the prepared state was implicit",
      "Prepared dawn time on the shared local-clock proxy",
      "Prepared dusk time on the shared local-clock proxy"
    ),
    unit_or_values = c(
      "manuscript_prepared_data",
      "new_h01_h11",
      "glasses/chest",
      "near_eye_primary/complementary_chest",
      "identifier",
      "identifier",
      "date",
      "POSIXct with UTC class",
      "YYYY-MM-DD HH:MM:SS",
      "positive integer",
      "registry identifier",
      "metric-specific",
      "lx",
      "lx",
      "lx",
      "category",
      "category",
      "category",
      "day/night",
      "TRUE/FALSE",
      "POSIXct with UTC class",
      "POSIXct with UTC class"
    ),
    stringsAsFactors = FALSE
  )
  mder_support <- data.frame(
    variable = c(
      "metric_decision_id",
      "viable_ratio_minutes",
      "expected_minutes",
      "viable_ratio_fraction",
      "raw_source_rows",
      "observed_local_minutes",
      "duplicated_local_minutes",
      "duplicate_source_rows",
      "excluded_nonfinite_source_minutes",
      "excluded_zero_either_minutes",
      "excluded_zero_medi_minutes",
      "excluded_zero_light_minutes",
      "excluded_both_zero_minutes",
      "excluded_nonfinite_ratio_minutes",
      "minimum_viable_fraction",
      "passes_viable_ratio_support",
      "support_threshold_enforced",
      "ratio_scaled_or_weighted",
      "estimable",
      "failure_reason",
      "duplicate_minute_rule",
      "expected_day_rule"
    ),
    definition = c(
      "Decision governing the MDER calculation",
      "Local minutes with finite strictly positive melEDI and illuminance",
      "Local wall-clock minutes in the MDER day denominator",
      "Viable one-minute MDER ratios divided by expected minutes",
      "One-minute source rows before repeated-clock-minute averaging",
      "Distinct local clock minutes represented by at least one source row",
      "Local clock minutes represented more than once at the DST fall-back",
      "Source rows beyond the first within repeated local clock minutes",
      "Minutes excluded because either source channel was non-finite",
      "Minutes excluded because either finite source channel was zero",
      "Minutes with finite zero melEDI",
      "Minutes with finite zero photopic illuminance",
      "Minutes with both finite source channels equal to zero",
      "Positive-source minutes excluded because their ratio was non-finite",
      "Minimum viable-ratio fraction required for daily MDER",
      "Whether viable one-minute ratios meet the MDER support threshold",
      "Whether the metric-specific support threshold is enforced",
      "Whether one-minute ratios are time-weighted or rescaled",
      "Whether the participant-day MDER is finite and retained",
      "Reason a participant-day MDER is unavailable",
      "Rule for repeated fall-back local clock minutes",
      "Declared local wall-clock day used for the MDER denominator"
    ),
    unit_or_values = c(
      "METRIC-010",
      "minutes",
      "minutes",
      "proportion",
      "rows",
      "minutes",
      "minutes",
      "rows",
      "minutes",
      "minutes",
      "minutes",
      "minutes",
      "minutes",
      "minutes",
      "proportion",
      "TRUE/FALSE",
      "TRUE",
      "FALSE",
      "TRUE/FALSE",
      "no_viable_momentary_ratio/below_viable_ratio_fraction/NA",
      "channel_mean_before_ratio",
      "complete_1440_local_wall_clock_minutes"
    ),
    stringsAsFactors = FALSE
  )
  dplyr::bind_rows(dictionary, mder_support)
}
