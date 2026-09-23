h04_key_columns <- function() {
  c("site", "Id", "local_date", "clock_minute")
}

h04_activity_registry <- function() {
  tibble::tribble(
    ~display_order,
    ~model_order,
    ~activity_code,
    ~activity_label,
    1L,
    2L,
    "sleeping",
    "Sleeping",
    2L,
    1L,
    "home",
    "At home",
    3L,
    3L,
    "road_vehicle",
    "On the road with public transport/car",
    4L,
    4L,
    "working_indoor",
    "Working in the office/from home",
    5L,
    5L,
    "outdoors",
    "Outdoors",
    6L,
    6L,
    "other",
    "Other/unspecified activity"
  )
}

h04_activity_levels <- function() {
  registry <- h04_activity_registry()
  registry$activity_label[order(registry$model_order)]
}

h04_named_activity_levels <- function() {
  setdiff(h04_activity_levels(), "Other/unspecified activity")
}

h04_core_heterogeneity_levels <- function() {
  c(
    "At home",
    "Sleeping",
    "On the road with public transport/car",
    "Working in the office/from home"
  )
}

h04_treatment_contrasts <- function(levels) {
  contrast <- stats::contr.treatment(length(levels), base = 1L)
  colnames(contrast) <- make.names(levels[-1L], unique = TRUE)
  contrast
}

h04_site_levels <- function(root) {
  registry <- utils::read.csv(
    file.path(root, "config/site_display_registry.csv"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  registry$site[order(registry$display_order)]
}

h04_prepare_diary <- function(
  raw,
  root,
  retain_coselected_other = FALSE
) {
  key <- h04_key_columns()
  site_levels <- h04_site_levels(root)
  flag_names <- c(
    "act_sleep",
    "act_home",
    "act_road_vehicle",
    "act_road_open",
    "act_working_indoor",
    "act_working_outdoor",
    "act_free_outdoor",
    "act_other"
  )

  missing_columns <- setdiff(flag_names, names(raw))
  if (length(missing_columns) > 0L) {
    stop(
      "Missing H04 activity flag(s): ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  eligible <- raw |>
    dplyr::mutate(
      site = factor(.data$site, levels = site_levels),
      local_date = as.Date(.data$Date),
      clock_minute = as.integer(format(
        .data$interval_start_wall,
        "%H",
        tz = "UTC"
      )) *
        60L +
        as.integer(format(
          .data$interval_start_wall,
          "%M",
          tz = "UTC"
        )),
      participant = interaction(
        .data$site,
        .data$Id,
        drop = TRUE,
        lex.order = TRUE
      ),
      participant_day = interaction(
        .data$site,
        .data$Id,
        .data$local_date,
        drop = TRUE,
        lex.order = TRUE
      )
    ) |>
    dplyr::filter(
      .data$interval_analysis_eligible %in% TRUE,
      !(.data$interval_quarantined %in% TRUE)
    )

  key_counts <- eligible |>
    dplyr::count(dplyr::across(dplyr::all_of(key)), name = "rows_per_key")
  if (any(key_counts$rows_per_key != 1L)) {
    stop("Eligible H04 diary keys are not unique", call. = FALSE)
  }
  if (any(eligible$clock_minute %% 60L != 0L)) {
    stop("Eligible H04 diary intervals are not hour aligned", call. = FALSE)
  }

  hour <- eligible |>
    dplyr::mutate(
      original_true_flag_n = rowSums(
        dplyr::across(
          dplyr::all_of(flag_names),
          ~ as.integer(.x %in% TRUE)
        )
      ),
      missing_flag_n = rowSums(
        dplyr::across(dplyr::all_of(flag_names), is.na)
      ),
      sleeping = .data$act_sleep %in% TRUE,
      home = .data$act_home %in% TRUE,
      road_vehicle = .data$act_road_vehicle %in% TRUE,
      working_indoor = .data$act_working_indoor %in% TRUE,
      outdoors = .data$act_road_open %in%
        TRUE |
        .data$act_working_outdoor %in% TRUE |
        .data$act_free_outdoor %in% TRUE,
      original_outdoor_true_n = rowSums(dplyr::across(
        c(
          "act_road_open",
          "act_working_outdoor",
          "act_free_outdoor"
        ),
        ~ as.integer(.x %in% TRUE)
      )),
      other_selected = .data$act_other %in% TRUE,
      named_k = as.integer(.data$sleeping) +
        as.integer(.data$home) +
        as.integer(.data$road_vehicle) +
        as.integer(.data$working_indoor) +
        as.integer(.data$outdoors),
      other_coselected = .data$other_selected & .data$named_k > 0L,
      other_retained = .data$other_selected &
        (.data$named_k == 0L | retain_coselected_other),
      k = .data$named_k + as.integer(.data$other_retained),
      activity_observation_status = dplyr::case_when(
        .data$missing_flag_n == length(flag_names) ~ "all flags missing",
        .data$k == 0L ~ "no selected category",
        .data$other_selected & .data$named_k == 0L ~ "other only",
        .data$other_coselected ~ "named plus other (other suppressed)",
        .data$k == 1L ~ "one collapsed named category",
        TRUE ~ "multiple collapsed named categories"
      ),
      hour_id = interaction(
        .data$site,
        .data$Id,
        .data$local_date,
        .data$clock_minute,
        drop = TRUE,
        lex.order = TRUE
      )
    )

  if (retain_coselected_other) {
    hour$activity_observation_status[hour$other_coselected] <-
      "named plus other (other retained)"
  }

  activity_columns <- c(
    "sleeping",
    "home",
    "road_vehicle",
    "working_indoor",
    "outdoors",
    "other_retained"
  )
  activity_codes <- c(
    sleeping = "sleeping",
    home = "home",
    road_vehicle = "road_vehicle",
    working_indoor = "working_indoor",
    outdoors = "outdoors",
    other_retained = "other"
  )
  registry <- h04_activity_registry()

  long <- hour |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(activity_columns),
      names_to = "activity_source",
      values_to = "selected"
    ) |>
    dplyr::filter(.data$selected) |>
    dplyr::mutate(
      activity_code = unname(activity_codes[.data$activity_source])
    ) |>
    dplyr::distinct(
      dplyr::across(dplyr::all_of(key)),
      .data$activity_code,
      .keep_all = TRUE
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(key))) |>
    dplyr::mutate(
      k_from_long = dplyr::n_distinct(.data$activity_code),
      activity_weight = 1 / .data$k_from_long
    ) |>
    dplyr::ungroup() |>
    dplyr::left_join(
      registry |>
        dplyr::select(
          "activity_code",
          "activity_label",
          "display_order",
          "model_order"
        ),
      by = "activity_code",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      activity = factor(
        .data$activity_label,
        levels = h04_activity_levels()
      )
    )

  long_check <- long |>
    dplyr::group_by(dplyr::across(dplyr::all_of(key))) |>
    dplyr::summarise(
      rows = dplyr::n(),
      distinct_labels = dplyr::n_distinct(.data$activity_code),
      recorded_k = dplyr::first(.data$k),
      weight_sum = sum(.data$activity_weight),
      .groups = "drop"
    )
  if (
    any(long_check$rows != long_check$distinct_labels) ||
      any(long_check$rows != long_check$recorded_k) ||
      any(abs(long_check$weight_sum - 1) > 1e-12)
  ) {
    stop("The H04 fractional-weight transformation failed", call. = FALSE)
  }

  list(
    eligible = hour,
    long = long,
    retain_coselected_other = retain_coselected_other,
    flag_names = flag_names,
    key = key
  )
}

h04_prepare_primary_placement <- function(
  raw,
  diary,
  placement,
  root
) {
  key <- h04_key_columns()
  site_levels <- h04_site_levels(root)
  duplicate_outcome <- raw |>
    dplyr::count(dplyr::across(dplyr::all_of(key)), name = "rows_per_key") |>
    dplyr::filter(.data$rows_per_key != 1L)
  if (nrow(duplicate_outcome) > 0L) {
    stop(placement, " outcome keys are not unique", call. = FALSE)
  }

  hour_fields <- diary$eligible |>
    dplyr::select(
      dplyr::all_of(key),
      "interval_start_utc",
      "participant",
      "participant_day",
      "original_true_flag_n",
      "missing_flag_n",
      "original_outdoor_true_n",
      "other_selected",
      "other_coselected",
      "named_k",
      "k",
      "activity_observation_status"
    )

  joined <- raw |>
    dplyr::mutate(
      site = factor(.data$site, levels = site_levels),
      local_date = as.Date(.data$local_date),
      participant = interaction(
        .data$site,
        .data$Id,
        drop = TRUE,
        lex.order = TRUE
      ),
      participant_day = interaction(
        .data$site,
        .data$Id,
        .data$local_date,
        drop = TRUE,
        lex.order = TRUE
      )
    ) |>
    dplyr::left_join(
      hour_fields |>
        dplyr::rename(
          diary_participant = "participant",
          diary_participant_day = "participant_day"
        ) |>
        dplyr::mutate(diary_key_matched = TRUE),
      by = key,
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      placement = placement,
      outcome_available = .data$bin_admissible %in%
        TRUE &
        is.finite(.data$metric_value_lx),
      diary_key_matched = .data$diary_key_matched %in% TRUE,
      retained_activity_available = !is.na(.data$k) & .data$k > 0L,
      model_hour_candidate = .data$outcome_available &
        .data$diary_key_matched &
        .data$retained_activity_available,
      geo_medi_1h = .data$metric_value_lx,
      time_hour = .data$clock_minute / 60 + 0.5,
      fall_back_hour = .data$dst_fold_wall_minutes > 0,
      hour_id = interaction(
        .data$site,
        .data$Id,
        .data$local_date,
        .data$clock_minute,
        drop = TRUE,
        lex.order = TRUE
      )
    )

  long <- joined |>
    dplyr::filter(.data$model_hour_candidate) |>
    dplyr::select(
      -"diary_participant",
      -"diary_participant_day"
    ) |>
    dplyr::inner_join(
      diary$long |>
        dplyr::select(
          dplyr::all_of(key),
          "activity_code",
          "activity_label",
          "activity",
          "display_order",
          "model_order",
          "activity_weight",
          "k_from_long"
        ),
      by = key,
      relationship = "one-to-many"
    ) |>
    dplyr::mutate(
      site = droplevels(factor(.data$site, levels = site_levels)),
      activity = factor(
        as.character(.data$activity),
        levels = h04_activity_levels()
      ),
      participant = droplevels(factor(.data$participant)),
      participant_day = droplevels(factor(.data$participant_day)),
      other_indicator = as.integer(.data$activity_code == "other"),
      site_activity_cell = interaction(
        .data$site,
        .data$activity,
        drop = TRUE,
        lex.order = TRUE
      )
    )

  long_check <- long |>
    dplyr::group_by(dplyr::across(dplyr::all_of(key))) |>
    dplyr::summarise(
      rows = dplyr::n(),
      k = dplyr::first(.data$k),
      outcomes = dplyr::n_distinct(.data$geo_medi_1h),
      weight_sum = sum(.data$activity_weight),
      .groups = "drop"
    )
  if (
    any(long_check$rows != long_check$k) ||
      any(long_check$outcomes != 1L) ||
      any(abs(long_check$weight_sum - 1) > 1e-12)
  ) {
    stop(
      placement,
      " long frame does not preserve one weighted contribution per hour",
      call. = FALSE
    )
  }

  list(joined = joined, long = long, hour_check = long_check)
}

h04_prepare_gap_placement <- function(
  raw,
  diary,
  position,
  placement,
  root
) {
  key <- h04_key_columns()
  site_levels <- h04_site_levels(root)
  hour_fields <- diary$eligible |>
    dplyr::select(
      dplyr::all_of(key),
      "interval_start_utc",
      "k",
      "activity_observation_status"
    )

  joined <- raw |>
    dplyr::filter(.data$position == .env$position) |>
    dplyr::mutate(
      site = factor(.data$site, levels = site_levels),
      local_date = as.Date(.data$local_date),
      clock_minute = as.integer(format(
        .data$local_clock_datetime_utc_proxy,
        "%H",
        tz = "UTC"
      )) *
        60L +
        as.integer(format(
          .data$local_clock_datetime_utc_proxy,
          "%M",
          tz = "UTC"
        )),
      participant = interaction(
        .data$site,
        .data$Id,
        drop = TRUE,
        lex.order = TRUE
      ),
      participant_day = interaction(
        .data$site,
        .data$Id,
        .data$local_date,
        drop = TRUE,
        lex.order = TRUE
      )
    ) |>
    dplyr::left_join(
      hour_fields |>
        dplyr::mutate(diary_key_matched = TRUE),
      by = key,
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      placement = .env$placement,
      outcome_available = is.finite(.data$medi_geometric_mean_lx),
      diary_key_matched = .data$diary_key_matched %in% TRUE,
      retained_activity_available = !is.na(.data$k) & .data$k > 0L,
      model_hour_candidate = .data$outcome_available &
        .data$diary_key_matched &
        .data$retained_activity_available,
      geo_medi_1h = .data$medi_geometric_mean_lx,
      gap_hour_id = interaction(
        .data$site,
        .data$Id,
        .data$local_date,
        .data$clock_minute,
        .data$local_occurrence,
        drop = TRUE,
        lex.order = TRUE
      )
    )

  long <- joined |>
    dplyr::filter(.data$model_hour_candidate) |>
    dplyr::inner_join(
      diary$long |>
        dplyr::select(
          dplyr::all_of(key),
          "activity_code",
          "activity_label",
          "activity",
          "display_order",
          "model_order",
          "activity_weight",
          "k_from_long"
        ),
      by = key,
      relationship = "many-to-many"
    ) |>
    dplyr::mutate(
      site = droplevels(factor(.data$site, levels = site_levels)),
      activity = factor(
        as.character(.data$activity),
        levels = h04_activity_levels()
      ),
      participant = droplevels(factor(.data$participant)),
      participant_day = droplevels(factor(.data$participant_day)),
      other_indicator = as.integer(.data$activity_code == "other"),
      site_activity_cell = interaction(
        .data$site,
        .data$activity,
        drop = TRUE,
        lex.order = TRUE
      )
    )

  check <- long |>
    dplyr::group_by(.data$gap_hour_id) |>
    dplyr::summarise(
      rows = dplyr::n(),
      k = dplyr::first(.data$k),
      weight_sum = sum(.data$activity_weight),
      .groups = "drop"
    )
  if (any(check$rows != check$k) || any(abs(check$weight_sum - 1) > 1e-12)) {
    failed <- check |>
      dplyr::filter(
        .data$rows != .data$k |
          abs(.data$weight_sum - 1) > 1e-12
      )
    stop(
      placement,
      " gap sensitivity weighting failed for ",
      nrow(failed),
      " hour(s); first failure: ",
      paste(
        utils::capture.output(print(utils::head(failed, 1L))),
        collapse = " "
      ),
      call. = FALSE
    )
  }
  list(joined = joined, long = long, hour_check = check)
}

h04_sample_flow <- function(bundle) {
  joined <- bundle$joined
  long <- bundle$long
  candidate <- joined$model_hour_candidate
  tibble::tibble(
    placement = dplyr::first(joined$placement),
    outcome_grid_hours = nrow(joined),
    outcome_available_hours = sum(joined$outcome_available),
    outcome_unavailable_hours = sum(!joined$outcome_available),
    outcome_hours_without_eligible_diary_key = sum(
      joined$outcome_available & !joined$diary_key_matched
    ),
    outcome_hours_with_no_retained_activity = sum(
      joined$outcome_available &
        joined$diary_key_matched &
        !joined$retained_activity_available
    ),
    model_candidate_unique_hours = sum(candidate),
    participants = dplyr::n_distinct(joined$participant[candidate]),
    participant_days = dplyr::n_distinct(joined$participant_day[candidate]),
    sites = dplyr::n_distinct(joined$site[candidate]),
    generated_long_rows = nrow(long),
    effective_weighted_hours = sum(long$activity_weight),
    exact_zero_unique_hours = sum(
      joined$geo_medi_1h[candidate] == 0,
      na.rm = TRUE
    )
  )
}

h04_gap_sample_flow <- function(bundle) {
  joined <- bundle$joined
  long <- bundle$long
  candidate <- joined$model_hour_candidate
  tibble::tibble(
    placement = dplyr::first(joined$placement),
    outcome_rows = nrow(joined),
    outcome_available_hours = sum(joined$outcome_available),
    outcome_hours_without_eligible_diary_key = sum(
      joined$outcome_available & !joined$diary_key_matched
    ),
    outcome_hours_with_no_retained_activity = sum(
      joined$outcome_available &
        joined$diary_key_matched &
        !joined$retained_activity_available
    ),
    model_candidate_unique_hours = dplyr::n_distinct(
      joined$gap_hour_id[candidate]
    ),
    participants = dplyr::n_distinct(joined$participant[candidate]),
    participant_days = dplyr::n_distinct(joined$participant_day[candidate]),
    sites = dplyr::n_distinct(joined$site[candidate]),
    generated_long_rows = nrow(long),
    effective_weighted_hours = sum(long$activity_weight)
  )
}

h04_cell_support <- function(bundle) {
  registry <- h04_activity_registry()
  long <- bundle$long
  observed_sites <- levels(droplevels(long$site))
  categories <- h04_activity_levels()

  member_ids <- long |>
    dplyr::distinct(.data$site, .data$activity, .data$participant) |>
    dplyr::group_by(.data$site, .data$activity) |>
    dplyr::summarise(
      member_ids = list(as.character(.data$participant)),
      .groups = "drop"
    )
  home_ids <- member_ids |>
    dplyr::filter(as.character(.data$activity) == "At home") |>
    dplyr::transmute(
      .data$site,
      home_ids = .data$member_ids
    )

  cell <- long |>
    dplyr::group_by(.data$placement, .data$site, .data$activity) |>
    dplyr::summarise(
      unique_hours = dplyr::n_distinct(.data$hour_id),
      long_rows = dplyr::n(),
      effective_weighted_hours = sum(.data$activity_weight),
      participants = dplyr::n_distinct(.data$participant),
      participant_days = dplyr::n_distinct(.data$participant_day),
      .groups = "drop"
    ) |>
    tidyr::complete(
      placement = unique(long$placement),
      site = factor(observed_sites, levels = levels(long$site)),
      activity = factor(categories, levels = categories),
      fill = list(
        unique_hours = 0L,
        long_rows = 0L,
        effective_weighted_hours = 0,
        participants = 0L,
        participant_days = 0L
      )
    ) |>
    dplyr::left_join(member_ids, by = c("site", "activity")) |>
    dplyr::left_join(home_ids, by = "site")
  cell$member_ids <- lapply(
    cell$member_ids,
    function(value) if (is.null(value)) character() else value
  )
  cell$home_ids <- lapply(
    cell$home_ids,
    function(value) if (is.null(value)) character() else value
  )
  cell |>
    dplyr::mutate(
      shared_with_home_participants = purrr::map2_int(
        .data$member_ids,
        .data$home_ids,
        ~ length(intersect(.x, .y))
      ),
      support_rule = .data$unique_hours >= 20L &
        .data$participants >= 5L &
        .data$shared_with_home_participants >= 5L,
      activity_label = as.character(.data$activity)
    ) |>
    dplyr::left_join(
      registry |>
        dplyr::select(
          "activity_label",
          "activity_code",
          "display_order"
        ),
      by = "activity_label",
      relationship = "many-to-one"
    ) |>
    dplyr::select(-"member_ids", -"home_ids") |>
    dplyr::arrange(.data$site, .data$display_order)
}
