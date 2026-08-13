# H06_daily METRIC-011 source adapters and exact two-part model frames.

h06d_l10_assert_unique <- function(data, key, label) {
  duplicate <- data |>
    dplyr::count(dplyr::across(dplyr::all_of(key)), name = "rows") |>
    dplyr::filter(.data$rows != 1L)
  h06d_l10_assert(
    nrow(duplicate) == 0L,
    "%s contains %d duplicated keys",
    label,
    nrow(duplicate)
  )
  invisible(data)
}

h06d_l10_site_levels <- function(root) {
  readr::read_csv(
    file.path(root, "config/site_display_registry.csv"),
    show_col_types = FALSE
  ) |>
    dplyr::arrange(.data$display_order) |>
    dplyr::pull(.data$site) |>
    as.character()
}

h06d_l10_load_diaries <- function(root) {
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

  h06d_l10_assert_unique(
    exercise_day,
    c("site", "Id", "local_date"),
    "METRIC-011 exercise diary"
  )
  h06d_l10_assert_unique(
    dplyr::filter(sleep_day, !is.na(.data$local_date)),
    c("site", "Id", "local_date"),
    "METRIC-011 sleep diary"
  )
  h06d_l10_assert(
    sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S001") == 7L,
    "Immutable TUM S001 exercise-row identity failed"
  )
  h06d_l10_assert(
    sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S101") == 0L,
    "Immutable TUM S101 exercise-row identity failed"
  )
  h06d_l10_assert(
    sum(is.na(sleep_day$local_date)) == 1L,
    "Unexpected number of sleep rows without a wake date"
  )

  list(
    exercise_raw = exercise_raw,
    sleep_raw = sleep_raw,
    exercise_day = exercise_day,
    sleep_day = sleep_day
  )
}

h06d_l10_join_context <- function(data, diaries) {
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

h06d_l10_changed_cells <- function(root) {
  readr::read_csv(
    file.path(
      root,
      "audit/reconciliation/l10_METRIC-011/primary_scientific_cell_changes.csv"
    ),
    show_col_types = FALSE
  ) |>
    dplyr::transmute(
      placement_id = dplyr::recode(
        as.character(.data$position),
        glasses = "near_eye",
        chest = "chest"
      ),
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      old_value_lx = as.numeric(.data$old_value_lx),
      new_value_lx = as.numeric(.data$new_value_lx)
    )
}

h06d_l10_primary_source <- function(
  root,
  placement_id = c("near_eye", "chest"),
  diaries = h06d_l10_load_diaries(root),
  changed_cells = h06d_l10_changed_cells(root)
) {
  placement_id <- match.arg(placement_id)
  stem <- if (placement_id == "near_eye") "glasses" else "chest"
  path <- file.path(
    root,
    "artifacts/06_model_data/base",
    sprintf("metrics_%s_participant_day_context.rds", stem)
  )
  data <- readRDS(path) |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      response_source = as.numeric(.data$l10_mean_medi_lx)
    )
  h06d_l10_assert_unique(
    data,
    c("site", "Id", "local_date"),
    sprintf("METRIC-011 %s primary source", placement_id)
  )
  h06d_l10_assert(
    nrow(data) == ifelse(placement_id == "near_eye", 816L, 902L),
    "Unexpected METRIC-011 %s primary source row count",
    placement_id
  )
  changed <- changed_cells |>
    dplyr::filter(.data$placement_id == .env$placement_id)
  reconciled <- data |>
    dplyr::left_join(
      changed |>
        dplyr::select(-"placement_id"),
      by = c("site", "Id", "local_date"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      metric011_changed_source_cell = !is.na(.data$new_value_lx)
    )
  h06d_l10_assert(
    sum(reconciled$metric011_changed_source_cell) ==
      ifelse(placement_id == "near_eye", 3L, 5L),
    "METRIC-011 %s changed-cell count failed",
    placement_id
  )
  audited <- reconciled$metric011_changed_source_cell
  h06d_l10_assert(
    all(reconciled$response_source[audited] == 0) &&
      all(reconciled$new_value_lx[audited] == 0) &&
      all(reconciled$old_value_lx[audited] > 0) &&
      all(reconciled$response_source[is.finite(reconciled$response_source)] >= 0),
    "METRIC-011 %s exact-zero or lower-bound reconciliation failed",
    placement_id
  )

  reconciled |>
    h06d_l10_join_context(diaries) |>
    dplyr::mutate(
      dataset_id = "primary",
      dataset_label = "Primary gap-aware dataset",
      placement_id = .env$placement_id,
      placement = ifelse(.env$placement_id == "near_eye", "Near-eye", "Chest"),
      metric_id = "l10_mean_medi",
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      )
    )
}

h06d_l10_gap_source <- function(
  root,
  placement_id = c("near_eye", "chest"),
  diaries = h06d_l10_load_diaries(root)
) {
  placement_id <- match.arg(placement_id)
  position_role <- if (placement_id == "near_eye") {
    "near_eye_primary"
  } else {
    "complementary_chest"
  }
  data <- readRDS(file.path(
    root,
    paste0(
      "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
      "participant_day_metrics.rds"
    )
  )) |>
    dplyr::filter(
      .data$metric_id == "l10_mean_medi",
      .data$position_role == .env$position_role
    ) |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      response_source = as.numeric(.data$manuscript_prepared_value),
      old_value_lx = NA_real_,
      new_value_lx = NA_real_,
      metric011_changed_source_cell = FALSE
    )
  h06d_l10_assert_unique(
    data,
    c("site", "Id", "local_date"),
    sprintf("METRIC-011 %s gap source", placement_id)
  )
  h06d_l10_assert(
    nrow(data) == ifelse(placement_id == "near_eye", 811L, 897L) &&
      all(data$response_source[is.finite(data$response_source)] >= 0),
    "Unexpected METRIC-011 %s gap rows or lower bound",
    placement_id
  )

  data |>
    h06d_l10_join_context(diaries) |>
    dplyr::mutate(
      dataset_id = "gap_timing_unaware",
      dataset_label = "Gap-timing-unaware dataset",
      placement_id = .env$placement_id,
      placement = ifelse(.env$placement_id == "near_eye", "Near-eye", "Chest"),
      metric_id = "l10_mean_medi",
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      )
    )
}

h06d_l10_load_sources <- function(root) {
  diaries <- h06d_l10_load_diaries(root)
  changed <- h06d_l10_changed_cells(root)
  h06d_l10_assert(nrow(changed) == 8L, "METRIC-011 changed-cell registry is not eight rows")
  dplyr::bind_rows(
    h06d_l10_primary_source(root, "near_eye", diaries, changed),
    h06d_l10_primary_source(root, "chest", diaries, changed),
    h06d_l10_gap_source(root, "near_eye", diaries),
    h06d_l10_gap_source(root, "chest", diaries)
  ) |>
    dplyr::mutate(
      site = factor(.data$site, levels = h06d_l10_site_levels(root)),
      placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
    )
}

h06d_l10_predictor_available <- function(data, column) {
  value <- data[[column]]
  if (is.numeric(value)) {
    is.finite(value)
  } else {
    !is.na(value)
  }
}

h06d_l10_set_factor_contrasts <- function(frame) {
  if (nlevels(frame$site) > 1L) {
    contrasts(frame$site) <- stats::contr.sum(nlevels(frame$site))
  }
  if (nlevels(frame$work_free_day) > 1L) {
    contrast <- stats::contr.treatment(nlevels(frame$work_free_day), base = 1L)
    colnames(contrast) <- levels(frame$work_free_day)[-1L]
    contrasts(frame$work_free_day) <- contrast
  }
  if (nlevels(frame$activity_status) > 1L) {
    contrast <- stats::contr.treatment(nlevels(frame$activity_status), base = 1L)
    colnames(contrast) <- levels(frame$activity_status)[-1L]
    contrasts(frame$activity_status) <- contrast
  }
  frame
}

h06d_l10_prepare_parent_frame <- function(data, predictor) {
  column <- predictor$column[[1L]]
  output <- data |>
    dplyr::filter(
      is.finite(.data$response_source),
      h06d_l10_predictor_available(dplyr::pick(dplyr::everything()), column)
    ) |>
    dplyr::mutate(
      predictor_id = predictor$predictor_id[[1L]],
      participant_key = factor(.data$participant_key),
      site = droplevels(.data$site),
      work_free_day = droplevels(.data$work_free_day),
      activity_status = droplevels(.data$activity_status)
    ) |>
    dplyr::arrange(.data$site, .data$participant_key, .data$local_date) |>
    h06d_l10_set_factor_contrasts()
  h06d_l10_assert_unique(
    output,
    c("site", "participant_key", "local_date"),
    paste("METRIC-011 parent frame", predictor$predictor_id[[1L]])
  )
  h06d_l10_assert(
    nrow(output) > 0L &&
      dplyr::n_distinct(output$site) >= 2L &&
      all(output$response_source >= 0),
    "METRIC-011 parent frame is empty, single-site, or below zero"
  )
  output
}

h06d_l10_component_frame <- function(parent, component) {
  h06d_l10_assert(
    component %in% c("zero_occurrence", "positive_magnitude"),
    "Unknown METRIC-011 component `%s`",
    component
  )
  if (component == "zero_occurrence") {
    output <- parent |>
      dplyr::mutate(
        component = .env$component,
        response_value = as.integer(.data$response_source == 0)
      )
  } else {
    output <- parent |>
      dplyr::filter(.data$response_source > 0) |>
      dplyr::mutate(
        component = .env$component,
        response_value = log10(.data$response_source),
        participant_key = droplevels(.data$participant_key),
        site = droplevels(.data$site),
        work_free_day = droplevels(.data$work_free_day),
        activity_status = droplevels(.data$activity_status)
      ) |>
      h06d_l10_set_factor_contrasts()
  }
  h06d_l10_assert(
    all(is.finite(output$response_value)) &&
      (component != "positive_magnitude" || all(output$response_source > 0)),
    "METRIC-011 component response contract failed"
  )
  output
}

h06d_l10_build_frames <- function(source_data) {
  predictors <- h06d_l10_predictor_registry()
  runs <- h06d_l10_scenario_registry()
  components <- c("zero_occurrence", "positive_magnitude")
  frames <- list()
  registry_rows <- list()

  for (predictor_index in seq_len(nrow(predictors))) {
    predictor <- predictors[predictor_index, ]
    column <- predictor$column[[1L]]
    available <- source_data |>
      dplyr::mutate(
        response_available = is.finite(.data$response_source),
        predictor_available = h06d_l10_predictor_available(
          dplyr::pick(dplyr::everything()),
          column
        ),
        complete = .data$response_available & .data$predictor_available
      )
    paired_keys <- available |>
      dplyr::filter(.data$dataset_id == "primary", .data$complete) |>
      dplyr::distinct(.data$participant_day_key, .data$placement_id) |>
      dplyr::count(.data$participant_day_key, name = "placements") |>
      dplyr::filter(.data$placements == 2L) |>
      dplyr::select("participant_day_key")

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
            paired_keys,
            by = "participant_day_key",
            relationship = "many-to-one"
          )
      }
      parent <- h06d_l10_prepare_parent_frame(selected, predictor)
      parent_changed <- sum(parent$metric011_changed_source_cell)
      for (component in components) {
        frame <- h06d_l10_component_frame(parent, component)
        key <- paste(
          run$run_id[[1L]],
          predictor$predictor_id[[1L]],
          component,
          sep = "__"
        )
        frames[[key]] <- frame
        registry_rows[[key]] <- dplyr::bind_cols(
          run,
          predictor |>
            dplyr::select(
              "predictor_order",
              "predictor_id",
              "reader_name",
              "contrast_label",
              "association_family_id",
              "heterogeneity_family_id"
            ),
          tibble::tibble(
            component = component,
            frame_key = key,
            participant_days = nrow(frame),
            parent_participant_days = nrow(parent),
            participants = dplyr::n_distinct(frame$participant_key),
            sites = dplyr::n_distinct(frame$site),
            parent_exact_zeros = sum(parent$response_source == 0),
            parent_positive_values = sum(parent$response_source > 0),
            metric011_changed_parent_rows = parent_changed,
            response_minimum = min(frame$response_value),
            response_median = stats::median(frame$response_value),
            response_maximum = max(frame$response_value),
            frame_object_sha256 = h06d_l10_object_sha256(frame)
          )
        )
      }
    }
  }
  list(
    frames = frames,
    registry = dplyr::bind_rows(registry_rows) |>
      dplyr::arrange(.data$predictor_order, .data$run_order, .data$component)
  )
}

h06d_l10_counterfactual_pre_metric011 <- function(source_data) {
  source_data |>
    dplyr::mutate(
      response_source = dplyr::if_else(
        .data$metric011_changed_source_cell,
        .data$old_value_lx,
        .data$response_source,
        missing = .data$response_source
      )
    )
}

h06d_l10_add_day_sequences <- function(frame) {
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
  h06d_l10_assert(
    all(output$date_gap[!output$sequence_start] == 1L),
    "METRIC-011 AR sequence crosses a missing calendar date"
  )
  output
}
