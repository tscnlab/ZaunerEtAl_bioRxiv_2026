# H06_daily H06-D-007 current-source adapters and exact pilot frames.

h06d_nl_assert_unique <- function(data, key, label) {
  duplicate <- data |>
    dplyr::count(dplyr::across(dplyr::all_of(key)), name = "rows") |>
    dplyr::filter(.data$rows != 1L)
  h06d_nl_assert(
    nrow(duplicate) == 0L,
    "%s contains %d duplicated keys",
    label,
    nrow(duplicate)
  )
  invisible(data)
}

h06d_nl_site_levels <- function(root) {
  readr::read_csv(
    file.path(root, "config/site_display_registry.csv"),
    show_col_types = FALSE
  ) |>
    dplyr::arrange(.data$display_order) |>
    dplyr::pull("site") |>
    as.character()
}

h06d_nl_load_diaries <- function(root) {
  exercise_raw <- readRDS(file.path(
    root,
    "artifacts/06_model_data/normalized_inputs/exercisediary.rds"
  ))
  sleep_raw <- readRDS(file.path(
    root,
    "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds"
  ))

  exercise_day <- exercise_raw |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$Date),
      activity_status = dplyr::case_when(
        is.na(.data$intensity) ~ NA_character_,
        as.character(.data$intensity) ==
          "None of the above, I did not perform any type of physical activity" ~
          "Sedentary",
        TRUE ~ "Active"
      ) |>
        factor(levels = c("Sedentary", "Active")),
      exercise_source_row = .data$source_row
    )

  sleep_day <- sleep_raw |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$wake_wall),
      work_free_day = factor(
        as.character(.data$daytype2),
        levels = c("a work day", "a free day"),
        labels = c("Work day", "Free day")
      ),
      previous_sleep_duration_h = as.numeric(
        .data$sleep_duration,
        units = "hours"
      ),
      previous_sleep_duration_centered_h =
        .data$previous_sleep_duration_h - 8,
      sleep_source_row = .data$source_row
    )

  h06d_nl_assert_unique(
    exercise_day,
    c("site", "Id", "local_date"),
    "H06-D-007 exercise diary"
  )
  h06d_nl_assert_unique(
    dplyr::filter(sleep_day, !is.na(.data$local_date)),
    c("site", "Id", "local_date"),
    "H06-D-007 sleep diary"
  )
  h06d_nl_assert(
    sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S001") == 7L &&
      sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S101") == 0L,
    "Immutable melidosData 1.0.6 TUM exercise identity failed"
  )
  h06d_nl_assert(
    sum(is.na(sleep_day$local_date)) == 1L,
    "Unexpected number of quarantined sleep rows"
  )

  list(
    exercise_raw = exercise_raw,
    sleep_raw = sleep_raw,
    exercise_day = exercise_day,
    sleep_day = sleep_day
  )
}

h06d_nl_join_context <- function(data, diaries) {
  data |>
    dplyr::left_join(
      diaries$sleep_day,
      by = c("site", "Id", "local_date"),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      diaries$exercise_day,
      by = c("site", "Id", "local_date"),
      relationship = "many-to-one"
    )
}

h06d_nl_primary_source <- function(
  root,
  placement_id = c("near_eye", "chest"),
  diaries = h06d_nl_load_diaries(root)
) {
  placement_id <- match.arg(placement_id)
  stem <- if (placement_id == "near_eye") "glasses" else "chest"
  registry <- h06d_nl_metric_registry()
  wide <- readRDS(file.path(
    root,
    "artifacts/06_model_data/base",
    sprintf("metrics_%s_participant_day_enriched.rds", stem)
  ))
  required <- c(
    "site", "Id", "local_date", "expected_real_minutes",
    "longest_bout_above_250_exact_identifiable",
    registry$source_column
  )
  h06d_nl_assert(
    all(required %in% names(wide)),
    "The current %s source lacks a required non-L10 column",
    placement_id
  )

  source <- wide |>
    dplyr::select(dplyr::all_of(required)) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(registry$source_column),
      names_to = "source_column",
      values_to = "response_source"
    ) |>
    dplyr::left_join(
      registry,
      by = "source_column",
      relationship = "many-to-one"
    ) |>
    dplyr::transmute(
      dataset_id = "primary",
      placement_id = .env$placement_id,
      placement = ifelse(.env$placement_id == "near_eye", "Near-eye", "Chest"),
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      metric_slot = .data$metric_slot,
      metric_id = .data$metric_id,
      manuscript_name = .data$manuscript_name,
      source_column = .data$source_column,
      response_source = as.numeric(.data$response_source),
      expected_minutes = as.numeric(.data$expected_real_minutes),
      longest_period_exact = as.logical(
        .data$longest_bout_above_250_exact_identifiable
      ),
      response_family = .data$response_family,
      response_transform = .data$response_transform,
      effect_scale = .data$effect_scale,
      display_unit = .data$display_unit,
      lower_bound = .data$lower_bound,
      upper_bound = .data$upper_bound,
      is_timing = .data$is_timing
    ) |>
    h06d_nl_join_context(diaries) |>
    dplyr::mutate(
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      )
    )

  expected_days <- if (placement_id == "near_eye") 816L else 902L
  h06d_nl_assert(
    nrow(source) == expected_days * nrow(registry),
    "Unexpected %s non-L10 primary source size",
    placement_id
  )
  h06d_nl_assert_unique(
    source,
    c("site", "Id", "local_date", "metric_id"),
    sprintf("H06-D-007 %s primary metric source", placement_id)
  )
  source
}

h06d_nl_gap_source <- function(
  root,
  placement_id = c("near_eye", "chest"),
  diaries = h06d_nl_load_diaries(root)
) {
  placement_id <- match.arg(placement_id)
  role <- if (placement_id == "near_eye") {
    "near_eye_primary"
  } else {
    "complementary_chest"
  }
  registry <- h06d_nl_metric_registry()
  source <- readRDS(file.path(
    root,
    paste0(
      "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
      "participant_day_metrics.rds"
    )
  )) |>
    dplyr::filter(
      .data$position_role == .env$role,
      .data$metric_id %in% registry$metric_id
    ) |>
    dplyr::transmute(
      dataset_id = "gap_timing_unaware",
      placement_id = .env$placement_id,
      placement = ifelse(.env$placement_id == "near_eye", "Near-eye", "Chest"),
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      metric_id = as.character(.data$metric_id),
      response_source = as.numeric(.data$manuscript_prepared_value)
    ) |>
    dplyr::left_join(
      registry,
      by = "metric_id",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      expected_minutes = NA_real_,
      longest_period_exact = NA,
      source_column = NA_character_
    ) |>
    h06d_nl_join_context(diaries) |>
    dplyr::mutate(
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      )
    )

  expected_days <- if (placement_id == "near_eye") 811L else 897L
  h06d_nl_assert(
    nrow(source) == expected_days * nrow(registry),
    "Unexpected %s gap non-L10 source size",
    placement_id
  )
  h06d_nl_assert_unique(
    source,
    c("site", "Id", "local_date", "metric_id"),
    sprintf("H06-D-007 %s gap metric source", placement_id)
  )
  source
}

h06d_nl_load_sources <- function(root) {
  diaries <- h06d_nl_load_diaries(root)
  site_levels <- h06d_nl_site_levels(root)
  dplyr::bind_rows(
    h06d_nl_primary_source(root, "near_eye", diaries),
    h06d_nl_primary_source(root, "chest", diaries),
    h06d_nl_gap_source(root, "near_eye", diaries),
    h06d_nl_gap_source(root, "chest", diaries)
  ) |>
    dplyr::mutate(
      site = factor(.data$site, levels = .env$site_levels),
      placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
    ) |>
    dplyr::arrange(
      .data$dataset_id,
      .data$placement_id,
      .data$metric_slot,
      .data$site,
      .data$Id,
      .data$local_date
    )
}

h06d_nl_transform_response <- function(value, transform_id) {
  output <- switch(
    transform_id,
    identity = value,
    log10_offset_0.1 = log10(value + 0.1),
    clock_hours = value / 60,
    clock_hours_midnight_after_16 = {
      hours <- value / 60
      ifelse(hours > 16, hours - 24, hours)
    },
    h06d_nl_abort("Unknown response transform `%s`", transform_id)
  )
  h06d_nl_assert(
    all(is.finite(output)),
    "A non-L10 response transformation produced nonfinite values"
  )
  output
}

h06d_nl_predictor_available <- function(data, column) {
  value <- data[[column]]
  if (is.numeric(value)) is.finite(value) else !is.na(value)
}

h06d_nl_prepare_frame <- function(data, metric, predictor) {
  column <- predictor$column[[1L]]
  output <- data |>
    dplyr::filter(
      .data$metric_id == metric$metric_id[[1L]],
      is.finite(.data$response_source),
      h06d_nl_predictor_available(dplyr::pick(dplyr::everything()), column)
    ) |>
    dplyr::mutate(
      predictor_id = predictor$predictor_id[[1L]],
      response_value = h06d_nl_transform_response(
        .data$response_source,
        metric$response_transform[[1L]]
      ),
      site = droplevels(.data$site),
      participant_key = factor(.data$participant_key),
      work_free_day = droplevels(.data$work_free_day),
      activity_status = droplevels(.data$activity_status)
    ) |>
    dplyr::arrange(.data$site, .data$participant_key, .data$local_date)

  h06d_nl_assert_unique(
    output,
    c("site", "participant_key", "local_date"),
    paste(metric$metric_id[[1L]], predictor$predictor_id[[1L]], "frame")
  )
  h06d_nl_assert(
    nrow(output) > 0L && nlevels(output$site) >= 2L,
    "A non-L10 frame is empty or single-site"
  )
  contrasts(output$site) <- stats::contr.sum(nlevels(output$site))
  output
}

h06d_nl_build_frames <- function(source_data, retain_frames = TRUE) {
  metrics <- h06d_nl_metric_registry()
  predictors <- h06d_nl_predictor_registry()
  runs <- h06d_nl_run_registry()
  frames <- list()
  inventory <- list()

  for (metric_index in seq_len(nrow(metrics))) {
    metric <- metrics[metric_index, ]
    for (predictor_index in seq_len(nrow(predictors))) {
      predictor <- predictors[predictor_index, ]
      column <- predictor$column[[1L]]
      available <- source_data |>
        dplyr::filter(.data$metric_id == metric$metric_id[[1L]]) |>
        dplyr::mutate(
          response_available = is.finite(.data$response_source),
          predictor_available = h06d_nl_predictor_available(
            dplyr::pick(dplyr::everything()),
            column
          ),
          complete = .data$response_available & .data$predictor_available
        )

      placement_common <- available |>
        dplyr::filter(.data$complete) |>
        dplyr::distinct(
          .data$dataset_id,
          .data$participant_day_key,
          .data$placement_id
        ) |>
        dplyr::count(
          .data$dataset_id,
          .data$participant_day_key,
          name = "placements"
        ) |>
        dplyr::filter(.data$placements == 2L) |>
        dplyr::select("dataset_id", "participant_day_key")

      dataset_common <- available |>
        dplyr::filter(.data$complete) |>
        dplyr::distinct(
          .data$placement_id,
          .data$participant_day_key,
          .data$dataset_id
        ) |>
        dplyr::count(
          .data$placement_id,
          .data$participant_day_key,
          name = "datasets"
        ) |>
        dplyr::filter(.data$datasets == 2L) |>
        dplyr::select("placement_id", "participant_day_key")

      for (run_index in seq_len(nrow(runs))) {
        run <- runs[run_index, ]
        selected <- available |>
          dplyr::filter(
            .data$dataset_id == run$dataset_id[[1L]],
            .data$placement_id == run$placement_id[[1L]],
            .data$complete
          )
        if (run$sample_role[[1L]] == "paired_common") {
          selected <- selected |>
            dplyr::inner_join(
              placement_common,
              by = c("dataset_id", "participant_day_key"),
              relationship = "many-to-one"
            )
        }
        if (run$sample_role[[1L]] == "dataset_common") {
          selected <- selected |>
            dplyr::inner_join(
              dataset_common,
              by = c("placement_id", "participant_day_key"),
              relationship = "many-to-one"
            )
        }
        frame <- h06d_nl_prepare_frame(selected, metric, predictor)
        key <- paste(
          run$run_id[[1L]],
          metric$metric_id[[1L]],
          predictor$predictor_id[[1L]],
          sep = "__"
        )
        if (isTRUE(retain_frames)) frames[[key]] <- frame
        inventory[[key]] <- dplyr::bind_cols(
          run,
          metric |>
            dplyr::select(
              "metric_slot", "metric_id", "manuscript_name", "display_unit",
              "response_family", "response_transform", "effect_scale",
              "is_timing"
            ),
          predictor |>
            dplyr::select(
              "predictor_order", "predictor_id", "reader_name",
              "contrast_label", "association_family_id",
              "heterogeneity_family_id"
            ),
          tibble::tibble(
            frame_key = key,
            participant_days = nrow(frame),
            participants = dplyr::n_distinct(frame$participant_key),
            sites = dplyr::n_distinct(frame$site),
            exact_source_zeros = sum(frame$response_source == 0),
            source_minimum = min(frame$response_source),
            source_median = stats::median(frame$response_source),
            source_maximum = max(frame$response_source),
            frame_object_sha256 = digest::digest(
              frame,
              algo = "sha256",
              serialize = TRUE
            )
          )
        )
      }
    }
  }

  list(
    frames = frames,
    inventory = dplyr::bind_rows(inventory) |>
      dplyr::arrange(
        .data$metric_slot,
        .data$predictor_order,
        .data$run_order
      )
  )
}

h06d_nl_add_day_sequences <- function(frame) {
  output <- frame |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      date_gap = as.integer(.data$local_date - dplyr::lag(.data$local_date)),
      sequence_start = dplyr::row_number() == 1L |
        is.na(.data$date_gap) |
        .data$date_gap != 1L,
      sequence_number = cumsum(.data$sequence_start)
    ) |>
    dplyr::ungroup() |>
    dplyr::group_by(.data$participant_key, .data$sequence_number) |>
    dplyr::mutate(day_index = dplyr::row_number()) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      day_sequence_id = interaction(
        .data$participant_key,
        .data$sequence_number,
        drop = TRUE,
        lex.order = TRUE
      ),
      day_index_factor = factor(
        .data$day_index,
        levels = seq_len(max(.data$day_index))
      )
    )
  h06d_nl_assert(
    all(output$date_gap[!output$sequence_start] == 1L),
    "A daily AR sequence crosses a missing calendar date"
  )
  output
}

h06d_nl_smallest_circular_arc <- function(hours, fraction = 0.95) {
  hours <- sort(hours %% 24)
  n <- length(hours)
  keep <- max(2L, ceiling(fraction * n))
  extended <- c(hours, hours + 24)
  starts <- seq_len(n)
  spans <- extended[starts + keep - 1L] - extended[starts]
  min(spans)
}

h06d_nl_clock_source_diagnostics <- function(frame, metric) {
  hours <- frame$response_source / 60
  transformed <- frame$response_value
  central <- unname(stats::quantile(
    transformed,
    probs = c(0.025, 0.975),
    names = FALSE,
    type = 8
  ))
  circular_arc <- h06d_nl_smallest_circular_arc(hours, 0.95)
  transformed_span <- diff(central)
  ordinary_boundary_split <-
    metric$response_transform[[1L]] == "clock_hours" &&
    mean(hours < 3) > 0.01 && mean(hours > 21) > 0.01
  cutpoint <- if (
    metric$response_transform[[1L]] == "clock_hours_midnight_after_16"
  ) {
    16
  } else {
    0
  }
  tibble::tibble(
    source_minimum_hour = min(hours),
    source_maximum_hour = max(hours),
    source_exact_midnights = sum(hours == 0),
    circular_95_arc_hours = circular_arc,
    transformed_95_span_hours = transformed_span,
    unwrap_cutpoint_hour = cutpoint,
    ordinary_boundary_split = ordinary_boundary_split,
    source_clock_acceptable = circular_arc <= 18 &&
      transformed_span <= 18 && !ordinary_boundary_split
  )
}

h06d_nl_current_long_reconciliation <- function(
  root,
  numeric_relative_tolerance = 1e-12
) {
  registry <- h06d_nl_metric_registry()
  rows <- list()
  for (placement_id in c("near_eye", "chest")) {
    stem <- if (placement_id == "near_eye") "glasses" else "chest"
    wide <- readRDS(file.path(
      root,
      "artifacts/06_model_data/base",
      sprintf("metrics_%s_participant_day_enriched.rds", stem)
    )) |>
      dplyr::select(
        "site", "Id", "local_date",
        dplyr::all_of(registry$source_column)
      ) |>
      tidyr::pivot_longer(
        cols = dplyr::all_of(registry$source_column),
        names_to = "source_column",
        values_to = "wide_value"
      ) |>
      dplyr::left_join(
        registry |>
          dplyr::select("metric_id", "source_column"),
        by = "source_column",
        relationship = "many-to-one"
      ) |>
      dplyr::mutate(local_date = as.Date(.data$local_date))
    long <- readr::read_csv(
      file.path(
        root,
        "artifacts/05_metrics",
        sprintf("metrics_%s_values_long.csv", stem)
      ),
      show_col_types = FALSE
    ) |>
      dplyr::filter(
        .data$analysis_unit == "participant_day",
        .data$profile_variant == "pooled",
        .data$metric %in% registry$metric_id
      ) |>
      dplyr::transmute(
        site = as.character(.data$site),
        Id = as.character(.data$Id),
        local_date = as.Date(.data$local_date),
        metric_id = as.character(.data$metric),
        long_value = as.numeric(.data$value),
        long_estimable = as.logical(.data$estimable),
        units = as.character(.data$units)
      )
    h06d_nl_assert_unique(
      wide,
      c("site", "Id", "local_date", "metric_id"),
      paste(placement_id, "wide non-L10 source")
    )
    h06d_nl_assert_unique(
      long,
      c("site", "Id", "local_date", "metric_id"),
      paste(placement_id, "long non-L10 source")
    )
    joined <- wide |>
      dplyr::left_join(
        long,
        by = c("site", "Id", "local_date", "metric_id"),
        relationship = "one-to-one"
      )
    same_missingness <- is.na(joined$wide_value) == is.na(joined$long_value)
    finite <- is.finite(joined$wide_value) & is.finite(joined$long_value)
    absolute_difference <- abs(joined$wide_value - joined$long_value)
    relative_difference <- absolute_difference / pmax(
      1,
      abs(joined$wide_value),
      abs(joined$long_value)
    )
    bit_identical <- same_missingness
    bit_identical[finite] <-
      joined$wide_value[finite] == joined$long_value[finite]
    value_reconciled <- same_missingness
    value_reconciled[finite] <-
      relative_difference[finite] <= numeric_relative_tolerance
    rows[[placement_id]] <- joined |>
      dplyr::mutate(
        bit_identical = .env$bit_identical,
        value_reconciled = .env$value_reconciled,
        absolute_difference = .env$absolute_difference,
        relative_difference = .env$relative_difference
      ) |>
      dplyr::summarise(
        placement_id = .env$placement_id,
        rows = dplyr::n(),
        finite_values = sum(is.finite(.data$wide_value)),
        missing_values = sum(is.na(.data$wide_value)),
        representation_differences = sum(!.data$bit_identical),
        maximum_absolute_difference = max(
          .data$absolute_difference,
          na.rm = TRUE
        ),
        maximum_relative_difference = max(
          .data$relative_difference,
          na.rm = TRUE
        ),
        numeric_relative_tolerance = .env$numeric_relative_tolerance,
        estimability_mismatches = sum(
          is.finite(.data$wide_value) != .data$long_estimable,
          na.rm = TRUE
        ),
        exact_reconciliation = all(.data$value_reconciled) &&
          all(is.finite(.data$wide_value) == .data$long_estimable),
        .by = "metric_id"
      )
  }
  dplyr::bind_rows(rows) |>
    dplyr::left_join(
      registry |>
        dplyr::select("metric_slot", "metric_id", "manuscript_name"),
      by = "metric_id",
      relationship = "many-to-one"
    ) |>
    dplyr::arrange(.data$metric_slot, .data$placement_id)
}
