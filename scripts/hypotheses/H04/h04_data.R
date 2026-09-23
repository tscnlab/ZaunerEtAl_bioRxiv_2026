h04_refactor_frame <- function(frame) {
  frame <- as.data.frame(frame)
  frame$site <- droplevels(factor(frame$site))
  frame$activity <- factor(
    as.character(frame$activity),
    levels = h04_activity_levels()
  )
  frame$participant <- droplevels(factor(frame$participant))
  frame$participant_day <- droplevels(factor(frame$participant_day))
  frame
}

h04_analysis_hour_id <- function(frame) {
  if ("gap_hour_id" %in% names(frame)) {
    as.character(frame$gap_hour_id)
  } else {
    as.character(frame$hour_id)
  }
}

h04_set_analysis_frame <- function(frame, analysis_weight = NULL) {
  frame <- h04_refactor_frame(frame)
  if (!"fall_back_hour" %in% names(frame)) {
    frame$fall_back_hour <- if ("local_occurrence" %in% names(frame)) {
      frame$local_occurrence > 1L
    } else {
      FALSE
    }
  }
  if (is.null(analysis_weight)) {
    analysis_weight <- frame$activity_weight
  }
  if (
    length(analysis_weight) != nrow(frame) ||
      any(!is.finite(analysis_weight)) ||
      any(analysis_weight <= 0)
  ) {
    h04_abort("Invalid H04 analysis weights")
  }
  frame$analysis_weight <- as.numeric(analysis_weight)
  frame$analysis_hour_id <- h04_analysis_hour_id(frame)
  frame
}

h04_prepare_paired_frames <- function(near_eye, chest) {
  key <- h04_key_columns()
  common <- near_eye |>
    dplyr::distinct(dplyr::across(dplyr::all_of(key))) |>
    dplyr::inner_join(
      chest |>
        dplyr::distinct(dplyr::across(dplyr::all_of(key))),
      by = key,
      relationship = "one-to-one"
    )
  list(
    near_eye = near_eye |>
      dplyr::semi_join(common, by = key) |>
      h04_set_analysis_frame(),
    chest = chest |>
      dplyr::semi_join(common, by = key) |>
      h04_set_analysis_frame(),
    keys = common
  )
}

h04_prepare_scenario_frames <- function(inputs, root) {
  diary_primary <- h04_prepare_diary(inputs$diary, root)
  diary_other_retained <- h04_prepare_diary(
    inputs$diary,
    root,
    retain_coselected_other = TRUE
  )

  near_bundle <- h04_prepare_primary_placement(
    inputs$near_eye,
    diary_primary,
    "Near-eye",
    root
  )
  chest_bundle <- h04_prepare_primary_placement(
    inputs$chest,
    diary_primary,
    "Chest",
    root
  )
  near_other_bundle <- h04_prepare_primary_placement(
    inputs$near_eye,
    diary_other_retained,
    "Near-eye",
    root
  )
  chest_other_bundle <- h04_prepare_primary_placement(
    inputs$chest,
    diary_other_retained,
    "Chest",
    root
  )
  gap_near_bundle <- h04_prepare_gap_placement(
    inputs$gap,
    diary_primary,
    "glasses",
    "Near-eye",
    root
  )
  gap_chest_bundle <- h04_prepare_gap_placement(
    inputs$gap,
    diary_primary,
    "chest",
    "Chest",
    root
  )

  main <- list(
    near_eye = h04_set_analysis_frame(near_bundle$long),
    chest = h04_set_analysis_frame(chest_bundle$long)
  )
  paired <- h04_prepare_paired_frames(main$near_eye, main$chest)

  exactly_one <- lapply(main, function(frame) {
    h04_set_analysis_frame(dplyr::filter(frame, .data$k == 1L))
  })
  retain_coselected_other <- list(
    near_eye = h04_set_analysis_frame(near_other_bundle$long),
    chest = h04_set_analysis_frame(chest_other_bundle$long)
  )
  exclude_other_only <- lapply(main, function(frame) {
    h04_set_analysis_frame(dplyr::filter(
      frame,
      .data$activity_code != "other"
    ))
  })
  unweighted_long <- lapply(main, function(frame) {
    h04_set_analysis_frame(frame, rep(1, nrow(frame)))
  })
  gap <- list(
    near_eye = h04_set_analysis_frame(gap_near_bundle$long),
    chest = h04_set_analysis_frame(gap_chest_bundle$long)
  )

  list(
    diary_primary = diary_primary,
    diary_other_retained = diary_other_retained,
    preparation_bundles = list(
      main_near_eye = near_bundle,
      main_chest = chest_bundle,
      other_near_eye = near_other_bundle,
      other_chest = chest_other_bundle,
      gap_near_eye = gap_near_bundle,
      gap_chest = gap_chest_bundle
    ),
    main = main,
    paired = paired,
    exactly_one = exactly_one,
    retain_coselected_other = retain_coselected_other,
    exclude_other_only = exclude_other_only,
    unweighted_long = unweighted_long,
    gap = gap
  )
}

h04_sample_summary <- function(frame, run_id, scenario_id, placement) {
  tibble::tibble(
    run_id = run_id,
    scenario_id = scenario_id,
    placement = placement,
    participants = dplyr::n_distinct(frame$participant),
    participant_days = dplyr::n_distinct(frame$participant_day),
    unique_participant_hours = dplyr::n_distinct(frame$analysis_hour_id),
    long_rows = nrow(frame),
    effective_weighted_hours = sum(frame$analysis_weight),
    sites = dplyr::n_distinct(frame$site),
    categories = dplyr::n_distinct(frame$activity),
    exact_zero_unique_hours = frame |>
      dplyr::distinct(.data$analysis_hour_id, .data$geo_medi_1h) |>
      dplyr::summarise(value = sum(.data$geo_medi_1h == 0)) |>
      dplyr::pull(.data$value)
  )
}

h04_mundlak_activity_map <- function() {
  reference <- h04_specification()$reference_label
  nonreference <- setdiff(h04_activity_levels(), reference)
  registry <- h04_activity_registry()
  tibble::tibble(
    between_variable = paste0("between_activity_", seq_along(nonreference)),
    activity = nonreference
  ) |>
    dplyr::left_join(
      registry |>
        dplyr::select(
          "activity_label",
          "activity_code",
          "display_order",
          "model_order"
        ),
      by = c("activity" = "activity_label"),
      relationship = "one-to-one"
    ) |>
    dplyr::arrange(.data$model_order)
}

h04_add_mundlak_proportions <- function(frame) {
  required <- c("participant", "activity", "analysis_weight")
  missing <- setdiff(required, names(frame))
  if (length(missing) > 0L) {
    h04_abort(
      "The H04 Mundlak frame is missing required column(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  if (
    any(!is.finite(frame$analysis_weight)) ||
      any(frame$analysis_weight <= 0)
  ) {
    h04_abort("The H04 Mundlak frame has invalid analysis weights")
  }

  mapping <- h04_mundlak_activity_map()
  proportions <- tibble::tibble(
    participant = levels(droplevels(factor(frame$participant)))
  )
  for (index in seq_len(nrow(mapping))) {
    activity <- mapping$activity[index]
    variable <- mapping$between_variable[index]
    values <- frame |>
      dplyr::group_by(.data$participant) |>
      dplyr::summarise(
        value = sum(
          .data$analysis_weight *
            (as.character(.data$activity) == .env$activity)
        ) / sum(.data$analysis_weight),
        .groups = "drop"
      )
    names(values)[names(values) == "value"] <- variable
    proportions <- dplyr::left_join(
      proportions,
      values,
      by = "participant",
      relationship = "one-to-one"
    )
  }

  between_variables <- mapping$between_variable
  if (
    any(!is.finite(as.matrix(proportions[between_variables]))) ||
      any(as.matrix(proportions[between_variables]) < 0) ||
      any(as.matrix(proportions[between_variables]) > 1) ||
      any(rowSums(proportions[between_variables]) > 1 + 1e-10)
  ) {
    h04_abort("The H04 Mundlak participant proportions are invalid")
  }

  output <- dplyr::left_join(
    frame,
    proportions,
    by = "participant",
    relationship = "many-to-one"
  )
  if (
    nrow(output) != nrow(frame) ||
      any(!stats::complete.cases(output[between_variables]))
  ) {
    h04_abort("The H04 Mundlak participant-proportion join failed")
  }
  output
}

h04_mundlak_support <- function(frame, placement) {
  mapping <- h04_mundlak_activity_map()
  between_variables <- mapping$between_variable
  missing <- setdiff(between_variables, names(frame))
  if (length(missing) > 0L) {
    h04_abort(
      "The H04 Mundlak support frame is missing term(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  frame |>
    dplyr::distinct(
      .data$participant,
      dplyr::across(dplyr::all_of(between_variables))
    ) |>
    dplyr::mutate(
      home_share = 1 - rowSums(
        as.data.frame(dplyr::pick(dplyr::all_of(between_variables)))
      )
    ) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(between_variables),
      names_to = "between_variable",
      values_to = "activity_share"
    ) |>
    dplyr::left_join(
      mapping,
      by = "between_variable",
      relationship = "many-to-one"
    ) |>
    dplyr::group_by(
      .data$activity_code,
      .data$activity,
      .data$display_order,
      .data$between_variable
    ) |>
    dplyr::summarise(
      participants = dplyr::n(),
      participants_with_category = sum(.data$activity_share > 0),
      participants_with_home = sum(.data$home_share > 0),
      participants_with_category_and_home = sum(
        .data$activity_share > 0 & .data$home_share > 0
      ),
      mean_activity_share = mean(.data$activity_share),
      median_activity_share = stats::median(.data$activity_share),
      activity_share_q25 = unname(stats::quantile(.data$activity_share, 0.25)),
      activity_share_q75 = unname(stats::quantile(.data$activity_share, 0.75)),
      maximum_activity_share = max(.data$activity_share),
      minimum_home_share = min(.data$home_share),
      .groups = "drop"
    ) |>
    dplyr::mutate(placement = placement, .before = 1) |>
    dplyr::arrange(.data$display_order)
}

h04_category_support <- function(frame) {
  registry <- h04_activity_registry()
  frame |>
    dplyr::group_by(
      .data$activity,
      .data$activity_code,
      .data$display_order
    ) |>
    dplyr::summarise(
      unique_participant_hours = dplyr::n_distinct(.data$analysis_hour_id),
      long_rows = dplyr::n(),
      effective_weighted_hours = sum(.data$analysis_weight),
      participants = dplyr::n_distinct(.data$participant),
      participant_days = dplyr::n_distinct(.data$participant_day),
      sites = dplyr::n_distinct(.data$site),
      .groups = "drop"
    ) |>
    dplyr::mutate(activity_label = as.character(.data$activity)) |>
    dplyr::right_join(
      registry |>
        dplyr::select(
          "activity_code",
          "activity_label",
          "display_order",
          "model_order"
        ),
      by = c("activity_code", "activity_label", "display_order")
    ) |>
    dplyr::arrange(.data$display_order)
}

h04_site_category_support <- function(frame, root) {
  bundle <- list(long = frame)
  h04_cell_support(bundle) |>
    dplyr::left_join(
      readr::read_csv(
        file.path(root, "config/site_display_registry.csv"),
        show_col_types = FALSE
      ) |>
        dplyr::select(
          "site",
          "display_name",
          "display_order",
          "color_hex"
        ),
      by = "site"
    ) |>
    dplyr::arrange(.data$display_order.y, .data$display_order.x)
}

h04_prepare_heterogeneity_frame <- function(frame, architecture) {
  if (architecture == "five_named") {
    levels <- h04_named_activity_levels()
    variable <- "activity_named"
  } else if (architecture == "core") {
    levels <- h04_core_heterogeneity_levels()
    variable <- "activity_core"
  } else {
    h04_abort("Unknown H04 heterogeneity architecture: %s", architecture)
  }
  selected <- frame |>
    dplyr::group_by(.data$analysis_hour_id) |>
    dplyr::filter(all(as.character(.data$activity) %in% levels)) |>
    dplyr::ungroup() |>
    dplyr::filter(as.character(.data$activity) %in% levels) |>
    h04_set_analysis_frame()
  selected[[variable]] <- factor(
    as.character(selected$activity),
    levels = levels
  )
  contrasts(selected[[variable]]) <- h04_treatment_contrasts(levels)
  selected
}

h04_add_unique_hour_sequences <- function(frame) {
  hour <- frame |>
    dplyr::group_by(.data$analysis_hour_id) |>
    dplyr::summarise(
      site = dplyr::first(.data$site),
      participant = dplyr::first(.data$participant),
      participant_day = dplyr::first(.data$participant_day),
      local_date = dplyr::first(.data$local_date),
      clock_minute = dplyr::first(.data$clock_minute),
      interval_start_utc = dplyr::first(.data$interval_start_utc),
      geo_medi_1h = dplyr::first(.data$geo_medi_1h),
      fall_back_hour = any(.data$fall_back_hour %in% TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data$site,
      .data$participant,
      .data$participant_day,
      .data$interval_start_utc,
      .data$clock_minute
    ) |>
    dplyr::group_by(.data$participant_day) |>
    dplyr::mutate(
      utc_step_hours = as.numeric(difftime(
        .data$interval_start_utc,
        dplyr::lag(.data$interval_start_utc),
        units = "hours"
      )),
      wall_step_minutes = .data$clock_minute - dplyr::lag(.data$clock_minute),
      AR_start = dplyr::row_number() == 1L |
        .data$fall_back_hour |
        dplyr::lag(.data$fall_back_hour, default = FALSE) |
        !dplyr::near(.data$utc_step_hours, 1) |
        .data$wall_step_minutes != 60L,
      sequence_id = cumsum(.data$AR_start)
    ) |>
    dplyr::ungroup()
  hour$AR_start[is.na(hour$AR_start)] <- TRUE
  hour
}

h04_add_activity_ar_sequences <- function(frame) {
  if (anyDuplicated(frame[c("analysis_hour_id", "activity_code")])) {
    h04_abort("H04 temporal frame duplicates an hour/activity membership")
  }
  data <- frame |>
    dplyr::arrange(
      .data$site,
      .data$participant,
      .data$participant_day,
      .data$activity,
      .data$interval_start_utc,
      .data$clock_minute
    ) |>
    dplyr::group_by(.data$participant_day, .data$activity) |>
    dplyr::mutate(
      utc_step_hours = as.numeric(difftime(
        .data$interval_start_utc,
        dplyr::lag(.data$interval_start_utc),
        units = "hours"
      )),
      wall_step_minutes = .data$clock_minute - dplyr::lag(.data$clock_minute),
      AR_start = dplyr::row_number() == 1L |
        .data$fall_back_hour |
        dplyr::lag(.data$fall_back_hour, default = FALSE) |
        !dplyr::near(.data$utc_step_hours, 1) |
        .data$wall_step_minutes != 60L,
      activity_run_id = interaction(
        .data$participant_day,
        .data$activity,
        cumsum(.data$AR_start),
        drop = TRUE,
        lex.order = TRUE
      )
    ) |>
    dplyr::ungroup()
  data$AR_start[is.na(data$AR_start)] <- TRUE
  if (anyDuplicated(data[c("activity_run_id", "interval_start_utc")])) {
    h04_abort("Concurrent activity rows became temporal lag neighbours")
  }
  data
}
