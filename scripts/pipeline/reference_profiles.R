clock_bin <- function(clock_minute, bin_minutes = 30L) {
  if (
    !is.numeric(clock_minute) ||
      any(clock_minute < 0 | clock_minute >= 1440, na.rm = TRUE)
  ) {
    stop("clock_minute must be numeric and in [0, 1440)", call. = FALSE)
  }
  if (
    length(bin_minutes) != 1L ||
      is.na(bin_minutes) ||
      bin_minutes <= 0 ||
      bin_minutes != as.integer(bin_minutes) ||
      1440 %% bin_minutes != 0L
  ) {
    stop(
      "bin_minutes must be a positive integer that divides 1440 exactly",
      call. = FALSE
    )
  }
  floor(clock_minute / bin_minutes) * bin_minutes
}

add_profile_domains <- function(
  data,
  state_col = "State.Brown",
  output_col = "state_domain"
) {
  if (!state_col %in% names(data)) {
    stop("Missing state column: ", state_col, call. = FALSE)
  }
  full_day <- data
  full_day[[output_col]] <- "full_day"
  state_specific <- data
  state_specific[[output_col]] <- as.character(state_specific[[state_col]])
  state_specific <- state_specific[
    !is.na(state_specific[[output_col]]) &
      state_specific[[output_col]] %in% c("wake", "pre-sleep", "sleep"),
    ,
    drop = FALSE
  ]
  dplyr::bind_rows(full_day, state_specific)
}

check_profile_minimum <- function(value, name) {
  if (
    length(value) != 1L ||
      is.na(value) ||
      !is.numeric(value) ||
      value < 1 ||
      value != as.integer(value)
  ) {
    stop(name, " must be one positive integer", call. = FALSE)
  }
  as.integer(value)
}

reference_profile_minimum_participants <- function(
  profile_scope,
  state_domain,
  pooled_full_day_min = 20L,
  leave_one_site_out_full_day_min = 20L,
  state_specific_min = 5L,
  site_specific_min = 5L
) {
  pooled_full_day_min <- check_profile_minimum(
    pooled_full_day_min,
    "pooled_full_day_min"
  )
  leave_one_site_out_full_day_min <- check_profile_minimum(
    leave_one_site_out_full_day_min,
    "leave_one_site_out_full_day_min"
  )
  state_specific_min <- check_profile_minimum(
    state_specific_min,
    "state_specific_min"
  )
  site_specific_min <- check_profile_minimum(
    site_specific_min,
    "site_specific_min"
  )

  allowed <- c("pooled", "site_specific", "leave_one_site_out")
  if (
    length(profile_scope) != length(state_domain) &&
      length(profile_scope) != 1L &&
      length(state_domain) != 1L
  ) {
    stop(
      "profile_scope and state_domain must have conformable lengths",
      call. = FALSE
    )
  }
  profile_scope <- rep_len(
    as.character(profile_scope),
    length.out = max(
      length(profile_scope),
      length(state_domain)
    )
  )
  state_domain <- rep_len(
    as.character(state_domain),
    length.out = length(
      profile_scope
    )
  )
  invalid_scope <- is.na(profile_scope) | !profile_scope %in% allowed
  if (any(invalid_scope)) {
    stop(
      "Unknown profile scope(s): ",
      paste(sort(unique(profile_scope[invalid_scope])), collapse = ", "),
      call. = FALSE
    )
  }

  minimum <- rep.int(state_specific_min, length(profile_scope))
  site_specific <- profile_scope == "site_specific"
  pooled_full_day <- profile_scope == "pooled" &
    state_domain == "full_day"
  leave_one_out_full_day <- profile_scope == "leave_one_site_out" &
    state_domain == "full_day"
  minimum[site_specific] <- site_specific_min
  minimum[pooled_full_day] <- pooled_full_day_min
  minimum[leave_one_out_full_day] <- leave_one_site_out_full_day_min
  minimum
}

complete_profile_grid <- function(data, strata, clock_bin_col, bin_minutes) {
  combinations <- data |>
    dplyr::distinct(dplyr::across(dplyr::all_of(strata)))
  bins <- data.frame(
    value = seq.int(0L, 1440L - bin_minutes, by = bin_minutes)
  )
  names(bins) <- clock_bin_col
  tidyr::crossing(combinations, bins)
}

learn_reference_profile <- function(
  data,
  value_col,
  participant_col = "Id",
  participant_day_col = NULL,
  clock_bin_col = "clock_bin",
  strata = c("placement", "state_domain", "signal"),
  bin_minutes = 30L,
  profile_variant = "pooled",
  profile_scope = "custom",
  profile_site = NA_character_,
  held_out_site = NA_character_,
  minimum_participants = 1L,
  pooled_full_day_min = 20L,
  leave_one_site_out_full_day_min = 20L,
  state_specific_min = 5L,
  site_specific_min = 5L
) {
  required <- unique(c(value_col, participant_col, clock_bin_col, strata))
  if (!is.null(participant_day_col)) {
    required <- unique(c(required, participant_day_col))
  }
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(
      "Profile data are missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  if (nrow(data) == 0L) {
    stop("Cannot learn a reference profile from empty data", call. = FALSE)
  }
  if (!is.numeric(data[[value_col]])) {
    stop(value_col, " must be numeric", call. = FALSE)
  }
  if (any(data[[value_col]] < 0, na.rm = TRUE)) {
    stop(
      value_col,
      " contains negative values; light profiles require non-negative values",
      call. = FALSE
    )
  }
  if (
    anyNA(data[c(participant_col, clock_bin_col, strata)]) ||
      any(!is.finite(data[[clock_bin_col]])) ||
      any(
        data[[clock_bin_col]] !=
          clock_bin(
            data[[clock_bin_col]],
            bin_minutes = bin_minutes
          )
      )
  ) {
    stop(
      "Profile keys must be complete and clock bins must align to bin_minutes",
      call. = FALSE
    )
  }

  if (is.null(participant_day_col)) {
    data$.profile_participant_day <- data[[participant_col]]
    participant_day_col <- ".profile_participant_day"
    participant_day_count_basis <- "participant_proxy"
  } else {
    if (anyNA(data[[participant_day_col]])) {
      stop(participant_day_col, " contains missing values", call. = FALSE)
    }
    participant_day_count_basis <- participant_day_col
  }

  grouping_participant <- c(strata, participant_col, clock_bin_col)
  grouping_profile <- c(strata, clock_bin_col)
  finite_data <- data[is.finite(data[[value_col]]), , drop = FALSE]

  participant_bins <- finite_data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping_participant))) |>
    dplyr::summarise(
      participant_median = stats::median(.data[[value_col]]),
      .groups = "drop"
    )

  reference_values <- participant_bins |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping_profile))) |>
    dplyr::summarise(
      reference_value = stats::median(.data$participant_median),
      .groups = "drop"
    )

  support <- finite_data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping_profile))) |>
    dplyr::summarise(
      observations = dplyr::n(),
      participant_days = dplyr::n_distinct(
        .data[[participant_col]],
        .data[[participant_day_col]]
      ),
      participants = dplyr::n_distinct(.data[[participant_col]]),
      .groups = "drop"
    )

  profile <- complete_profile_grid(
    data = data,
    strata = strata,
    clock_bin_col = clock_bin_col,
    bin_minutes = bin_minutes
  ) |>
    dplyr::left_join(
      reference_values,
      by = grouping_profile,
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      support,
      by = grouping_profile,
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      observations = dplyr::coalesce(.data$observations, 0L),
      participant_days = dplyr::coalesce(.data$participant_days, 0L),
      participants = dplyr::coalesce(.data$participants, 0L),
      participant_observations = .data$observations,
      profile_variant = as.character(profile_variant),
      profile_scope = as.character(profile_scope),
      profile_site = as.character(profile_site),
      held_out_site = as.character(held_out_site),
      bin_minutes = as.integer(bin_minutes),
      participant_day_count_basis = participant_day_count_basis
    )

  if (is.null(minimum_participants)) {
    if (!"state_domain" %in% names(profile)) {
      stop(
        "Automatic support thresholds require a state_domain stratum",
        call. = FALSE
      )
    }
    minimum_participants <- reference_profile_minimum_participants(
      profile_scope = profile$profile_scope,
      state_domain = profile$state_domain,
      pooled_full_day_min = pooled_full_day_min,
      leave_one_site_out_full_day_min = leave_one_site_out_full_day_min,
      state_specific_min = state_specific_min,
      site_specific_min = site_specific_min
    )
  } else {
    minimum_participants <- check_profile_minimum(
      minimum_participants,
      "minimum_participants"
    )
  }

  profile |>
    dplyr::mutate(
      minimum_participants = minimum_participants,
      profile_supported = is.finite(.data$reference_value) &
        .data$participants >= .data$minimum_participants,
      support_reason = dplyr::case_when(
        .data$observations == 0L ~ "no_finite_observations",
        .data$participants < .data$minimum_participants ~
          "below_minimum_participants",
        TRUE ~ "supported"
      ),
      supported_reference_value = dplyr::if_else(
        .data$profile_supported,
        .data$reference_value,
        NA_real_
      )
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(strata))) |>
    dplyr::mutate(
      reference_total = sum(.data$supported_reference_value, na.rm = TRUE),
      reference_weight = dplyr::if_else(
        .data$profile_supported & .data$reference_total > 0,
        .data$reference_value / .data$reference_total,
        NA_real_
      ),
      supported_bins = sum(.data$profile_supported),
      profile_complete = all(.data$profile_supported),
      profile_estimable = .data$reference_total > 0
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(c(strata, clock_bin_col)))
    )
}

learn_reference_profile_set <- function(
  data,
  value_col,
  participant_col = "Id",
  participant_day_col = "local_date",
  site_col = "site",
  clock_minute_col = "clock_minute",
  clock_bin_col = "clock_bin",
  strata = c("placement", "state_domain", "signal"),
  bin_minutes = 30L,
  variants = c("pooled", "site_specific", "leave_one_site_out"),
  pooled_full_day_min = 20L,
  leave_one_site_out_full_day_min = 20L,
  state_specific_min = 5L,
  site_specific_min = 5L
) {
  variants <- unique(as.character(variants))
  allowed_variants <- c("pooled", "site_specific", "leave_one_site_out")
  invalid_variants <- setdiff(variants, allowed_variants)
  if (length(invalid_variants) > 0L) {
    stop(
      "Unknown profile variant(s): ",
      paste(invalid_variants, collapse = ", "),
      call. = FALSE
    )
  }
  required <- unique(c(
    value_col,
    participant_col,
    participant_day_col,
    site_col,
    strata
  ))
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(
      "Profile-set data are missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  if (!clock_bin_col %in% names(data)) {
    if (!clock_minute_col %in% names(data)) {
      stop(
        "Profile-set data require either ",
        clock_bin_col,
        " or ",
        clock_minute_col,
        call. = FALSE
      )
    }
    data[[clock_bin_col]] <- clock_bin(
      data[[clock_minute_col]],
      bin_minutes = bin_minutes
    )
  }
  if (anyNA(data[c(site_col, participant_col, participant_day_col, strata)])) {
    stop("Profile-set keys and strata must be complete", call. = FALSE)
  }

  data <- data |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(c(site_col, participant_col)))
    ) |>
    dplyr::mutate(
      .profile_participant = as.character(dplyr::cur_group_id())
    ) |>
    dplyr::ungroup() |>
    dplyr::group_by(
      dplyr::across(
        dplyr::all_of(c(site_col, participant_col, participant_day_col))
      )
    ) |>
    dplyr::mutate(
      .profile_participant_day = as.character(dplyr::cur_group_id())
    ) |>
    dplyr::ungroup()

  sites <- sort(unique(as.character(data[[site_col]])))
  learn_one <- function(
    training_data,
    profile_scope,
    profile_variant,
    profile_site = NA_character_,
    held_out_site = NA_character_
  ) {
    training_sites <- sort(unique(as.character(training_data[[site_col]])))
    training_site_count <- length(training_sites)
    learn_reference_profile(
      data = training_data,
      value_col = value_col,
      participant_col = ".profile_participant",
      participant_day_col = ".profile_participant_day",
      clock_bin_col = clock_bin_col,
      strata = strata,
      bin_minutes = bin_minutes,
      profile_variant = profile_variant,
      profile_scope = profile_scope,
      profile_site = profile_site,
      held_out_site = held_out_site,
      minimum_participants = NULL,
      pooled_full_day_min = pooled_full_day_min,
      leave_one_site_out_full_day_min = leave_one_site_out_full_day_min,
      state_specific_min = state_specific_min,
      site_specific_min = site_specific_min
    ) |>
      dplyr::mutate(
        training_sites = paste(.env$training_sites, collapse = "|"),
        training_site_count = .env$training_site_count
      )
  }

  profiles <- list()
  if ("pooled" %in% variants) {
    profiles[[length(profiles) + 1L]] <- learn_one(
      training_data = data,
      profile_scope = "pooled",
      profile_variant = "pooled"
    )
  }
  if ("site_specific" %in% variants) {
    profiles <- c(
      profiles,
      lapply(sites, function(site) {
        learn_one(
          training_data = data[data[[site_col]] == site, , drop = FALSE],
          profile_scope = "site_specific",
          profile_variant = paste0("site::", site),
          profile_site = site
        )
      })
    )
  }
  if ("leave_one_site_out" %in% variants && length(sites) > 1L) {
    profiles <- c(
      profiles,
      lapply(sites, function(site) {
        learn_one(
          training_data = data[data[[site_col]] != site, , drop = FALSE],
          profile_scope = "leave_one_site_out",
          profile_variant = paste0("leave_one_site_out::", site),
          held_out_site = site
        )
      })
    )
  }
  if (length(profiles) == 0L) {
    stop("No reference-profile variants were requested", call. = FALSE)
  }

  result <- dplyr::bind_rows(profiles) |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      dplyr::across(dplyr::all_of(strata)),
      .data[[clock_bin_col]]
    )
  attr(result, "profile_learning") <- "fixed_once_before_daily_metrics"
  attr(result, "profile_strata") <- strata
  result
}

validate_fixed_exceedance_specification <- function(
  threshold,
  bin_minutes
) {
  if (
    length(threshold) != 1L ||
      !is.numeric(threshold) ||
      !is.finite(threshold) ||
      threshold != 250
  ) {
    stop(
      "The timing distribution is fixed to the strict MEDI >250 lx threshold",
      call. = FALSE
    )
  }
  if (
    length(bin_minutes) != 1L ||
      !is.numeric(bin_minutes) ||
      is.na(bin_minutes) ||
      bin_minutes != 30L
  ) {
    stop(
      "The timing distribution is fixed to 30-minute clock bins",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

participant_probability_quantile <- function(x, probability) {
  stats::quantile(
    x,
    probs = probability,
    na.rm = TRUE,
    names = FALSE,
    type = 7
  )
}

# Learn a timing distribution from one-row-per-wall-minute data. The hierarchy
# is deliberate: valid minutes form a participant-day/bin probability, days
# are averaged equally within participant/bin, and participants are averaged
# equally within profile/bin. Consequently, neither long days nor participants
# with more retained days receive additional weight.
learn_exceedance_distribution_profile <- function(
  data,
  value_col,
  participant_col = "Id",
  participant_day_col = "local_date",
  clock_bin_col = "clock_bin",
  strata = c("placement", "state_domain", "signal"),
  bin_minutes = 30L,
  threshold = 250,
  profile_variant = "pooled",
  profile_scope = "custom",
  profile_site = NA_character_,
  held_out_site = NA_character_,
  minimum_participants = 1L,
  pooled_full_day_min = 20L,
  leave_one_site_out_full_day_min = 20L,
  state_specific_min = 5L,
  site_specific_min = 5L
) {
  validate_fixed_exceedance_specification(
    threshold = threshold,
    bin_minutes = bin_minutes
  )
  required <- unique(c(
    value_col,
    participant_col,
    participant_day_col,
    clock_bin_col,
    strata
  ))
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(
      "Distribution-profile data are missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  if (nrow(data) == 0L) {
    stop(
      "Cannot learn an exceedance distribution from empty data",
      call. = FALSE
    )
  }
  if (!is.numeric(data[[value_col]])) {
    stop(value_col, " must be numeric", call. = FALSE)
  }
  if (any(data[[value_col]] < 0, na.rm = TRUE)) {
    stop(
      value_col,
      " contains negative values; MEDI must be non-negative",
      call. = FALSE
    )
  }
  if (
    anyNA(data[c(
      participant_col,
      participant_day_col,
      clock_bin_col,
      strata
    )]) ||
      any(!is.finite(data[[clock_bin_col]])) ||
      any(
        data[[clock_bin_col]] !=
          clock_bin(
            data[[clock_bin_col]],
            bin_minutes = bin_minutes
          )
      )
  ) {
    stop(
      paste0(
        "Distribution-profile keys must be complete and clock bins must ",
        "align to 30 minutes"
      ),
      call. = FALSE
    )
  }
  if (
    !"state_domain" %in% strata ||
      any(as.character(data$state_domain) != "full_day")
  ) {
    stop(
      "The timing distribution must contain full_day observations only",
      call. = FALSE
    )
  }
  if (
    !"signal" %in% strata ||
      any(toupper(as.character(data$signal)) != "MEDI")
  ) {
    stop(
      "The timing distribution must contain MEDI observations only",
      call. = FALSE
    )
  }

  grouping_day <- c(
    strata,
    participant_col,
    participant_day_col,
    clock_bin_col
  )
  grouping_participant <- c(strata, participant_col, clock_bin_col)
  grouping_profile <- c(strata, clock_bin_col)

  participant_day_bins <- data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping_day))) |>
    dplyr::summarise(
      input_observations = dplyr::n(),
      valid_minutes = sum(is.finite(.data[[value_col]])),
      exceedance_minutes = sum(
        is.finite(.data[[value_col]]) &
          .data[[value_col]] > .env$threshold
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      participant_day_probability = dplyr::if_else(
        .data$valid_minutes > 0L,
        .data$exceedance_minutes / .data$valid_minutes,
        NA_real_
      )
    )

  participant_bins <- participant_day_bins |>
    dplyr::filter(is.finite(.data$participant_day_probability)) |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(grouping_participant))
    ) |>
    dplyr::summarise(
      participant_probability = mean(.data$participant_day_probability),
      participant_days = dplyr::n(),
      .groups = "drop"
    )

  probability <- participant_bins |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping_profile))) |>
    dplyr::summarise(
      exceedance_probability = mean(.data$participant_probability),
      participant_probability_q10 = participant_probability_quantile(
        .data$participant_probability,
        0.10
      ),
      participant_probability_q25 = participant_probability_quantile(
        .data$participant_probability,
        0.25
      ),
      participant_probability_median = participant_probability_quantile(
        .data$participant_probability,
        0.50
      ),
      participant_probability_q75 = participant_probability_quantile(
        .data$participant_probability,
        0.75
      ),
      participant_probability_q90 = participant_probability_quantile(
        .data$participant_probability,
        0.90
      ),
      participant_days = sum(.data$participant_days),
      participants = dplyr::n(),
      .groups = "drop"
    )

  raw_support <- data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping_profile))) |>
    dplyr::summarise(
      observations = dplyr::n(),
      valid_minutes = sum(is.finite(.data[[value_col]])),
      exceedance_minutes = sum(
        is.finite(.data[[value_col]]) &
          .data[[value_col]] > .env$threshold
      ),
      participant_days_with_input = dplyr::n_distinct(
        .data[[participant_col]],
        .data[[participant_day_col]]
      ),
      participants_with_input = dplyr::n_distinct(
        .data[[participant_col]]
      ),
      .groups = "drop"
    )

  distribution <- complete_profile_grid(
    data = data,
    strata = strata,
    clock_bin_col = clock_bin_col,
    bin_minutes = bin_minutes
  ) |>
    dplyr::left_join(
      probability,
      by = grouping_profile,
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      raw_support,
      by = grouping_profile,
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      observations = dplyr::coalesce(.data$observations, 0L),
      valid_minutes = dplyr::coalesce(.data$valid_minutes, 0L),
      exceedance_minutes = dplyr::coalesce(
        .data$exceedance_minutes,
        0L
      ),
      participant_days_with_input = dplyr::coalesce(
        .data$participant_days_with_input,
        0L
      ),
      participants_with_input = dplyr::coalesce(
        .data$participants_with_input,
        0L
      ),
      participant_days = dplyr::coalesce(.data$participant_days, 0L),
      participants = dplyr::coalesce(.data$participants, 0L),
      participant_observations = .data$participants,
      profile_variant = as.character(profile_variant),
      profile_scope = as.character(profile_scope),
      profile_site = as.character(profile_site),
      held_out_site = as.character(held_out_site),
      bin_minutes = as.integer(bin_minutes),
      exceedance_threshold_lx = as.numeric(threshold),
      exceedance_comparison = "strict_greater_than",
      probability_unit = "proportion_of_valid_wall_minutes",
      probability_aggregation = paste(
        "valid_minutes_within_participant_day_bin",
        "equal_days_within_participant_bin",
        "equal_participants_within_profile_bin",
        sep = ";"
      ),
      participant_day_count_basis = participant_day_col
    )

  if (is.null(minimum_participants)) {
    minimum_participants <- reference_profile_minimum_participants(
      profile_scope = distribution$profile_scope,
      state_domain = distribution$state_domain,
      pooled_full_day_min = pooled_full_day_min,
      leave_one_site_out_full_day_min = leave_one_site_out_full_day_min,
      state_specific_min = state_specific_min,
      site_specific_min = site_specific_min
    )
  } else {
    minimum_participants <- check_profile_minimum(
      minimum_participants,
      "minimum_participants"
    )
  }

  result <- distribution |>
    dplyr::mutate(
      minimum_participants = minimum_participants,
      profile_supported = is.finite(.data$exceedance_probability) &
        .data$participants >= .data$minimum_participants,
      support_reason = dplyr::case_when(
        .data$valid_minutes == 0L ~ "no_valid_minutes",
        .data$participants < .data$minimum_participants ~
          "below_minimum_participants",
        TRUE ~ "supported"
      ),
      supported_exceedance_probability = dplyr::if_else(
        .data$profile_supported,
        .data$exceedance_probability,
        NA_real_
      )
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(strata))) |>
    dplyr::mutate(
      probability_total = sum(
        .data$supported_exceedance_probability,
        na.rm = TRUE
      ),
      probability_weight = dplyr::if_else(
        .data$profile_supported & .data$probability_total > 0,
        .data$exceedance_probability / .data$probability_total,
        NA_real_
      ),
      supported_bins = sum(.data$profile_supported),
      profile_complete = all(.data$profile_supported),
      profile_estimable = .data$probability_total > 0
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(c(strata, clock_bin_col)))
    )
  attr(result, "distribution_profile_type") <-
    "participant_balanced_valid_minute_exceedance_probability"
  result
}

learn_exceedance_distribution_profile_set <- function(
  data,
  value_col,
  participant_col = "Id",
  participant_day_col = "local_date",
  site_col = "site",
  clock_minute_col = "clock_minute",
  clock_bin_col = "clock_bin",
  strata = c("placement", "state_domain", "signal"),
  bin_minutes = 30L,
  threshold = 250,
  variants = c("pooled", "site_specific", "leave_one_site_out"),
  pooled_full_day_min = 20L,
  leave_one_site_out_full_day_min = 20L,
  state_specific_min = 5L,
  site_specific_min = 5L
) {
  validate_fixed_exceedance_specification(
    threshold = threshold,
    bin_minutes = bin_minutes
  )
  variants <- unique(as.character(variants))
  allowed_variants <- c("pooled", "site_specific", "leave_one_site_out")
  invalid_variants <- setdiff(variants, allowed_variants)
  if (length(invalid_variants) > 0L) {
    stop(
      "Unknown distribution-profile variant(s): ",
      paste(invalid_variants, collapse = ", "),
      call. = FALSE
    )
  }
  required <- unique(c(
    value_col,
    participant_col,
    participant_day_col,
    site_col,
    strata
  ))
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(
      "Distribution-profile-set data are missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  if (!clock_bin_col %in% names(data)) {
    if (!clock_minute_col %in% names(data)) {
      stop(
        "Distribution-profile-set data require either ",
        clock_bin_col,
        " or ",
        clock_minute_col,
        call. = FALSE
      )
    }
    data[[clock_bin_col]] <- clock_bin(
      data[[clock_minute_col]],
      bin_minutes = bin_minutes
    )
  }
  if (anyNA(data[c(site_col, participant_col, participant_day_col, strata)])) {
    stop(
      "Distribution-profile-set keys and strata must be complete",
      call. = FALSE
    )
  }

  data <- data |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(c(site_col, participant_col)))
    ) |>
    dplyr::mutate(
      .profile_participant = as.character(dplyr::cur_group_id())
    ) |>
    dplyr::ungroup() |>
    dplyr::group_by(
      dplyr::across(
        dplyr::all_of(c(site_col, participant_col, participant_day_col))
      )
    ) |>
    dplyr::mutate(
      .profile_participant_day = as.character(dplyr::cur_group_id())
    ) |>
    dplyr::ungroup()

  sites <- sort(unique(as.character(data[[site_col]])))
  learn_one <- function(
    training_data,
    profile_scope,
    profile_variant,
    profile_site = NA_character_,
    held_out_site = NA_character_
  ) {
    training_sites <- sort(unique(as.character(training_data[[site_col]])))
    training_site_count <- length(training_sites)
    learn_exceedance_distribution_profile(
      data = training_data,
      value_col = value_col,
      participant_col = ".profile_participant",
      participant_day_col = ".profile_participant_day",
      clock_bin_col = clock_bin_col,
      strata = strata,
      bin_minutes = bin_minutes,
      threshold = threshold,
      profile_variant = profile_variant,
      profile_scope = profile_scope,
      profile_site = profile_site,
      held_out_site = held_out_site,
      minimum_participants = NULL,
      pooled_full_day_min = pooled_full_day_min,
      leave_one_site_out_full_day_min = leave_one_site_out_full_day_min,
      state_specific_min = state_specific_min,
      site_specific_min = site_specific_min
    ) |>
      dplyr::mutate(
        training_sites = paste(.env$training_sites, collapse = "|"),
        training_site_count = .env$training_site_count
      )
  }

  distributions <- list()
  if ("pooled" %in% variants) {
    distributions[[length(distributions) + 1L]] <- learn_one(
      training_data = data,
      profile_scope = "pooled",
      profile_variant = "pooled"
    )
  }
  if ("site_specific" %in% variants) {
    distributions <- c(
      distributions,
      lapply(sites, function(site) {
        learn_one(
          training_data = data[data[[site_col]] == site, , drop = FALSE],
          profile_scope = "site_specific",
          profile_variant = paste0("site::", site),
          profile_site = site
        )
      })
    )
  }
  if ("leave_one_site_out" %in% variants && length(sites) > 1L) {
    distributions <- c(
      distributions,
      lapply(sites, function(site) {
        learn_one(
          training_data = data[data[[site_col]] != site, , drop = FALSE],
          profile_scope = "leave_one_site_out",
          profile_variant = paste0("leave_one_site_out::", site),
          held_out_site = site
        )
      })
    )
  }
  if (length(distributions) == 0L) {
    stop("No distribution-profile variants were requested", call. = FALSE)
  }

  result <- dplyr::bind_rows(distributions) |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      dplyr::across(dplyr::all_of(strata)),
      .data[[clock_bin_col]]
    )
  attr(result, "profile_learning") <- "fixed_once_before_daily_metrics"
  attr(result, "profile_strata") <- strata
  attr(result, "distribution_profile_type") <-
    "participant_balanced_valid_minute_exceedance_probability"
  result
}

validate_exceedance_distribution_profiles <- function(
  distribution_profiles,
  signal_col = "signal",
  clock_bin_col = "clock_bin",
  strata = c("placement", "state_domain"),
  medi_label = "MEDI",
  tolerance = 1e-12
) {
  group_columns <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    strata,
    signal_col
  )
  required <- unique(c(
    group_columns,
    clock_bin_col,
    "exceedance_probability",
    "participant_probability_q10",
    "participant_probability_q25",
    "participant_probability_median",
    "participant_probability_q75",
    "participant_probability_q90",
    "observations",
    "participants",
    "participants_with_input",
    "participant_observations",
    "participant_days",
    "participant_days_with_input",
    "valid_minutes",
    "exceedance_minutes",
    "minimum_participants",
    "profile_supported",
    "supported_exceedance_probability",
    "probability_total",
    "probability_weight",
    "profile_complete",
    "profile_estimable",
    "supported_bins",
    "bin_minutes",
    "exceedance_threshold_lx",
    "exceedance_comparison",
    "probability_unit",
    "probability_aggregation",
    "participant_day_count_basis",
    "training_sites",
    "training_site_count"
  ))
  missing <- setdiff(required, names(distribution_profiles))
  if (length(missing) > 0L) {
    stop(
      "Distribution profiles are missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  if (nrow(distribution_profiles) == 0L) {
    stop("Distribution profiles must not be empty", call. = FALSE)
  }
  validate_fixed_exceedance_specification(
    threshold = unique(distribution_profiles$exceedance_threshold_lx),
    bin_minutes = unique(distribution_profiles$bin_minutes)
  )
  if (
    any(as.character(distribution_profiles$state_domain) != "full_day") ||
      any(
        toupper(as.character(distribution_profiles[[signal_col]])) !=
          toupper(medi_label)
      ) ||
      any(
        distribution_profiles$exceedance_comparison != "strict_greater_than"
      ) ||
      any(
        distribution_profiles$probability_unit !=
          "proportion_of_valid_wall_minutes"
      ) ||
      any(
        distribution_profiles$probability_aggregation !=
          paste(
            "valid_minutes_within_participant_day_bin",
            "equal_days_within_participant_bin",
            "equal_participants_within_profile_bin",
            sep = ";"
          )
      )
  ) {
    stop(
      paste0(
        "Distribution profiles must encode full-day MEDI, strict >250 lx, ",
        "valid-wall-minute probabilities"
      ),
      call. = FALSE
    )
  }
  if (
    length(tolerance) != 1L ||
      !is.finite(tolerance) ||
      tolerance <= 0
  ) {
    stop("tolerance must be one finite positive number", call. = FALSE)
  }

  key <- distribution_profiles[group_columns]
  key[[clock_bin_col]] <- distribution_profiles[[clock_bin_col]]
  if (anyDuplicated(key)) {
    stop("Distribution-profile clock-bin keys must be unique", call. = FALSE)
  }
  expected_bins <- seq.int(0L, 1410L, by = 30L)
  bin_audit <- distribution_profiles |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_columns))) |>
    dplyr::summarise(
      bins = list(sort(unique(.data[[clock_bin_col]]))),
      .groups = "drop"
    )
  if (
    any(vapply(
      bin_audit$bins,
      function(value) !identical(as.numeric(value), as.numeric(expected_bins)),
      logical(1)
    ))
  ) {
    stop(
      "Every distribution-profile stratum must contain all 48 clock bins",
      call. = FALSE
    )
  }

  probability_columns <- c(
    "exceedance_probability",
    "participant_probability_q10",
    "participant_probability_q25",
    "participant_probability_median",
    "participant_probability_q75",
    "participant_probability_q90",
    "supported_exceedance_probability",
    "probability_weight"
  )
  invalid_probability <- vapply(
    distribution_profiles[probability_columns],
    function(value) {
      any(
        !is.na(value) &
          (!is.finite(value) | value < -tolerance | value > 1 + tolerance)
      )
    },
    logical(1)
  )
  if (any(invalid_probability)) {
    stop(
      "Distribution-profile probabilities must lie in [0, 1]",
      call. = FALSE
    )
  }
  count_columns <- c(
    "observations",
    "valid_minutes",
    "exceedance_minutes",
    "participant_days_with_input",
    "participant_days",
    "participants_with_input",
    "participants",
    "participant_observations",
    "minimum_participants",
    "supported_bins",
    "training_site_count"
  )
  invalid_count <- vapply(
    distribution_profiles[count_columns],
    function(value) {
      any(
        !is.finite(value) |
          value < 0 |
          value != as.integer(value)
      )
    },
    logical(1)
  )
  if (any(invalid_count)) {
    stop(
      "Distribution-profile count fields must be non-negative integers",
      call. = FALSE
    )
  }
  quantiles <- as.matrix(distribution_profiles[c(
    "participant_probability_q10",
    "participant_probability_q25",
    "participant_probability_median",
    "participant_probability_q75",
    "participant_probability_q90"
  )])
  finite_quantile_rows <- rowSums(is.finite(quantiles)) == ncol(quantiles)
  if (
    any(
      apply(
        quantiles[finite_quantile_rows, , drop = FALSE],
        1L,
        function(value) any(diff(value) < -tolerance)
      )
    )
  ) {
    stop(
      "Participant-level probability quantiles must be monotone",
      call. = FALSE
    )
  }
  if (
    any(
      distribution_profiles$valid_minutes > distribution_profiles$observations
    ) ||
      any(
        distribution_profiles$exceedance_minutes >
          distribution_profiles$valid_minutes
      ) ||
      any(
        distribution_profiles$participant_days >
          distribution_profiles$participant_days_with_input
      ) ||
      any(
        distribution_profiles$participants >
          distribution_profiles$participants_with_input
      ) ||
      any(
        distribution_profiles$participant_observations !=
          distribution_profiles$participants
      ) ||
      any(
        distribution_profiles$profile_supported !=
          (is.finite(distribution_profiles$exceedance_probability) &
            distribution_profiles$participants >=
              distribution_profiles$minimum_participants)
      ) ||
      any(
        !distribution_profiles$profile_supported &
          !is.na(
            distribution_profiles$supported_exceedance_probability
          )
      ) ||
      any(
        distribution_profiles$profile_supported &
          (!is.finite(
            distribution_profiles$supported_exceedance_probability
          ) |
            abs(
              distribution_profiles$supported_exceedance_probability -
                distribution_profiles$exceedance_probability
            ) >
              tolerance)
      )
  ) {
    stop(
      "Distribution-profile support fields are internally inconsistent",
      call. = FALSE
    )
  }
  quantile_complete <- rowSums(is.finite(quantiles)) == ncol(quantiles)
  if (
    any(
      is.finite(distribution_profiles$exceedance_probability) !=
        quantile_complete
    ) ||
      any(
        distribution_profiles$training_site_count !=
          lengths(
            strsplit(
              distribution_profiles$training_sites,
              "|",
              fixed = TRUE
            )
          )
      )
  ) {
    stop(
      "Distribution-profile probability or provenance fields are incomplete",
      call. = FALSE
    )
  }

  normalization <- distribution_profiles |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_columns))) |>
    dplyr::summarise(
      profile_estimable = dplyr::first(.data$profile_estimable),
      estimable_consistent = dplyr::n_distinct(.data$profile_estimable) == 1L,
      probability_total = dplyr::first(.data$probability_total),
      total_consistent = dplyr::n_distinct(.data$probability_total) == 1L,
      expected_probability_total = sum(
        dplyr::if_else(
          .data$profile_supported,
          .data$exceedance_probability,
          NA_real_
        ),
        na.rm = TRUE
      ),
      supported_bins = dplyr::first(.data$supported_bins),
      supported_bins_consistent = dplyr::n_distinct(.data$supported_bins) == 1L,
      expected_supported_bins = sum(.data$profile_supported),
      profile_complete = dplyr::first(.data$profile_complete),
      complete_consistent = dplyr::n_distinct(.data$profile_complete) == 1L,
      expected_complete = all(.data$profile_supported),
      expected_estimable = .data$expected_probability_total > 0,
      weights_match_probability = all(
        dplyr::if_else(
          .data$expected_estimable & .data$profile_supported,
          is.finite(.data$probability_weight) &
            abs(
              .data$probability_weight -
                .data$exceedance_probability /
                  .data$expected_probability_total
            ) <=
              .env$tolerance,
          is.na(.data$probability_weight)
        )
      ),
      weight_sum = sum(.data$probability_weight, na.rm = TRUE),
      finite_weights = sum(is.finite(.data$probability_weight)),
      .groups = "drop"
    )
  invalid_estimable <- normalization$profile_estimable &
    (!normalization$estimable_consistent |
      !normalization$total_consistent |
      abs(
        normalization$probability_total -
          normalization$expected_probability_total
      ) >
        tolerance |
      !normalization$supported_bins_consistent |
      normalization$supported_bins != normalization$expected_supported_bins |
      !normalization$complete_consistent |
      normalization$profile_complete != normalization$expected_complete |
      normalization$profile_estimable != normalization$expected_estimable |
      !normalization$weights_match_probability |
      normalization$probability_total <= 0 |
      abs(normalization$weight_sum - 1) > tolerance |
      normalization$finite_weights == 0L)
  invalid_nonestimable <- !normalization$profile_estimable &
    (!normalization$estimable_consistent |
      !normalization$total_consistent |
      abs(
        normalization$probability_total -
          normalization$expected_probability_total
      ) >
        tolerance |
      !normalization$supported_bins_consistent |
      normalization$supported_bins != normalization$expected_supported_bins |
      !normalization$complete_consistent |
      normalization$profile_complete != normalization$expected_complete |
      normalization$profile_estimable != normalization$expected_estimable |
      !normalization$weights_match_probability |
      normalization$probability_total > tolerance |
      normalization$finite_weights > 0L)
  if (any(invalid_estimable | invalid_nonestimable)) {
    stop(
      "Distribution profiles failed normalization or estimability checks",
      call. = FALSE
    )
  }
  invisible(distribution_profiles)
}

profile_relevance_mass <- function(
  reference_value,
  supported,
  metric_map,
  zero_offset = 0.1
) {
  if (
    length(zero_offset) != 1L ||
      !is.finite(zero_offset) ||
      zero_offset <= 0
  ) {
    stop("zero_offset must be one finite positive value", call. = FALSE)
  }
  output <- rep(NA_real_, length(reference_value))
  valid <- supported & is.finite(reference_value)
  if (!any(valid)) {
    return(output)
  }
  value <- reference_value[valid]
  if (any(value < 0)) {
    stop(
      "Reference values must be non-negative for relevance maps",
      call. = FALSE
    )
  }

  mass <- switch(
    metric_map,
    dose = value,
    M10 = {
      log_value <- log10(value + zero_offset)
      log_value - min(log_value)
    },
    L10 = {
      log_value <- log10(value + zero_offset)
      max(log_value) - log_value
    },
    timing_above_250 = stop(
      paste0(
        "timing_above_250 requires an explicit participant-balanced ",
        "distribution profile"
      ),
      call. = FALSE
    ),
    paired_channel_coverage = value,
    stop("Unknown metric relevance map: ", metric_map, call. = FALSE)
  )
  output[valid] <- mass
  output
}

derive_metric_relevance_maps <- function(
  profiles,
  distribution_profiles,
  signal_col = "signal",
  clock_bin_col = "clock_bin",
  strata = c("placement", "state_domain"),
  medi_label = "MEDI",
  light_label = "LIGHT",
  zero_offset = 0.1
) {
  if (missing(distribution_profiles)) {
    stop(
      paste0(
        "distribution_profiles is required; timing_above_250 has no ",
        "median-profile fallback"
      ),
      call. = FALSE
    )
  }
  group_columns <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    strata,
    signal_col
  )
  required <- unique(c(
    group_columns,
    clock_bin_col,
    "reference_value",
    "profile_supported",
    "profile_complete",
    "supported_bins"
  ))
  missing <- setdiff(required, names(profiles))
  if (length(missing) > 0L) {
    stop(
      "Reference profiles are missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  if (!"state_domain" %in% strata) {
    stop(
      "Metric relevance maps require state_domain in strata",
      call. = FALSE
    )
  }
  validate_exceedance_distribution_profiles(
    distribution_profiles = distribution_profiles,
    signal_col = signal_col,
    clock_bin_col = clock_bin_col,
    strata = strata,
    medi_label = medi_label
  )

  signal_upper <- toupper(as.character(profiles[[signal_col]]))
  medi_profiles <- profiles[signal_upper == toupper(medi_label), , drop = FALSE]
  light_profiles <- profiles[
    signal_upper == toupper(light_label),
    ,
    drop = FALSE
  ]
  timing_median_profiles <- medi_profiles[
    as.character(medi_profiles$state_domain) == "full_day",
    ,
    drop = FALSE
  ]
  alignment_columns <- unique(c(group_columns, clock_bin_col))
  median_timing_keys <- timing_median_profiles |>
    dplyr::distinct(dplyr::across(dplyr::all_of(alignment_columns)))
  distribution_timing_keys <- distribution_profiles |>
    dplyr::distinct(dplyr::across(dplyr::all_of(alignment_columns)))
  missing_distribution_keys <- dplyr::anti_join(
    median_timing_keys,
    distribution_timing_keys,
    by = alignment_columns,
    na_matches = "na"
  )
  extra_distribution_keys <- dplyr::anti_join(
    distribution_timing_keys,
    median_timing_keys,
    by = alignment_columns,
    na_matches = "na"
  )
  if (
    nrow(missing_distribution_keys) > 0L ||
      nrow(extra_distribution_keys) > 0L
  ) {
    stop(
      paste0(
        "Distribution-profile keys must exactly match the full-day MEDI ",
        "median-profile keys"
      ),
      call. = FALSE
    )
  }

  map_specification <- list(
    list(
      data = medi_profiles,
      metric_map = "dose",
      application = "dose_correction",
      value_correction_allowed = TRUE,
      relevance_source = "median_reference_profile"
    ),
    list(
      data = medi_profiles,
      metric_map = "M10",
      application = "support_only",
      value_correction_allowed = FALSE,
      relevance_source = "median_reference_profile"
    ),
    list(
      data = medi_profiles,
      metric_map = "L10",
      application = "support_only",
      value_correction_allowed = FALSE,
      relevance_source = "median_reference_profile"
    ),
    list(
      data = distribution_profiles,
      metric_map = "timing_above_250",
      application = "support_only",
      value_correction_allowed = FALSE,
      relevance_source = "participant_balanced_exceedance_distribution"
    ),
    list(
      data = medi_profiles,
      metric_map = "paired_channel_coverage",
      application = "paired_coverage_only",
      value_correction_allowed = FALSE,
      relevance_source = "median_reference_profile"
    ),
    list(
      data = light_profiles,
      metric_map = "paired_channel_coverage",
      application = "paired_coverage_only",
      value_correction_allowed = FALSE,
      relevance_source = "median_reference_profile"
    )
  )

  maps <- lapply(map_specification, function(specification) {
    profile <- specification$data
    if (nrow(profile) == 0L) {
      return(NULL)
    }
    distribution_relevance <- identical(
      specification$relevance_source,
      "participant_balanced_exceedance_distribution"
    )
    if (distribution_relevance) {
      profile$reference_value <- NA_real_
    }
    profile |>
      dplyr::group_by(dplyr::across(dplyr::all_of(group_columns))) |>
      dplyr::mutate(
        metric_map = specification$metric_map,
        map_application = specification$application,
        relevance_source = specification$relevance_source,
        relevance_mass = if (.env$distribution_relevance) {
          dplyr::if_else(
            .data$profile_supported,
            .data$exceedance_probability,
            NA_real_
          )
        } else {
          profile_relevance_mass(
            .data$reference_value,
            .data$profile_supported,
            metric_map = specification$metric_map,
            zero_offset = zero_offset
          )
        },
        relevance_total = sum(.data$relevance_mass, na.rm = TRUE),
        map_estimable = is.finite(.data$relevance_total) &
          .data$relevance_total > 0,
        relevance_weight = dplyr::if_else(
          .data$map_estimable & is.finite(.data$relevance_mass),
          .data$relevance_mass / .data$relevance_total,
          NA_real_
        ),
        relevance_zero_offset = dplyr::if_else(
          specification$metric_map %in% c("M10", "L10"),
          zero_offset,
          NA_real_
        ),
        value_correction_allowed = specification$value_correction_allowed,
        ratio_correction_allowed = FALSE,
        paired_channel_required = specification$metric_map ==
          "paired_channel_coverage"
      ) |>
      dplyr::ungroup()
  })

  maps <- dplyr::bind_rows(maps) |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      dplyr::across(dplyr::all_of(strata)),
      .data[[signal_col]],
      .data$metric_map,
      .data[[clock_bin_col]]
    )
  attr(maps, "relevance_group_columns") <- c(
    group_columns,
    "metric_map"
  )
  validate_relevance_weight_normalization(
    maps,
    signal_col = signal_col,
    strata = strata
  )
  maps
}

validate_relevance_weight_normalization <- function(
  maps,
  signal_col = "signal",
  strata = c("placement", "state_domain"),
  tolerance = 1e-12
) {
  group_columns <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    strata,
    signal_col,
    "metric_map"
  )
  required <- c(
    group_columns,
    "relevance_mass",
    "relevance_weight",
    "map_estimable",
    "profile_supported"
  )
  missing <- setdiff(required, names(maps))
  if (length(missing) > 0L) {
    stop(
      "Relevance maps are missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  if (
    length(tolerance) != 1L ||
      !is.finite(tolerance) ||
      tolerance <= 0
  ) {
    stop("tolerance must be one finite positive number", call. = FALSE)
  }
  invalid_mass <- !is.na(maps$relevance_mass) &
    (!is.finite(maps$relevance_mass) | maps$relevance_mass < 0)
  if (any(invalid_mass)) {
    stop("Relevance mass must be finite and non-negative", call. = FALSE)
  }
  if (any(!maps$profile_supported & !is.na(maps$relevance_weight))) {
    stop("Unsupported profile bins must not receive weights", call. = FALSE)
  }

  audit <- maps |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_columns))) |>
    dplyr::summarise(
      map_estimable = dplyr::first(.data$map_estimable),
      estimable_consistent = dplyr::n_distinct(.data$map_estimable) == 1L,
      weight_sum = sum(.data$relevance_weight, na.rm = TRUE),
      finite_weights = sum(is.finite(.data$relevance_weight)),
      .groups = "drop"
    )
  invalid_estimable <- audit$map_estimable &
    (!audit$estimable_consistent |
      abs(audit$weight_sum - 1) > tolerance |
      audit$finite_weights == 0L)
  invalid_nonestimable <- !audit$map_estimable &
    (!audit$estimable_consistent | audit$finite_weights > 0L)
  if (any(invalid_estimable | invalid_nonestimable)) {
    stop(
      "Relevance weights failed normalization or estimability checks",
      call. = FALSE
    )
  }
  invisible(maps)
}

build_reference_profile_bundle <- function(
  data,
  value_col,
  distribution_profiles,
  ...
) {
  profiles <- learn_reference_profile_set(
    data = data,
    value_col = value_col,
    ...
  )
  maps <- derive_metric_relevance_maps(
    profiles = profiles,
    distribution_profiles = distribution_profiles
  )
  structure(
    list(
      profiles = profiles,
      distribution_profiles = distribution_profiles,
      relevance_maps = maps
    ),
    class = c("reference_profile_bundle", "list")
  )
}

learn_leave_one_site_out_profiles <- function(
  data,
  value_col,
  site_col = "site",
  participant_col = "Id",
  participant_day_col = NULL,
  clock_bin_col = "clock_bin",
  strata = c("placement", "state_domain", "signal"),
  minimum_participants = 1L
) {
  if (!site_col %in% names(data)) {
    stop("Missing site column: ", site_col, call. = FALSE)
  }
  sites <- sort(unique(as.character(data[[site_col]])))
  dplyr::bind_rows(lapply(sites, function(held_out_site) {
    learn_reference_profile(
      data = data[data[[site_col]] != held_out_site, , drop = FALSE],
      value_col = value_col,
      participant_col = participant_col,
      participant_day_col = participant_day_col,
      clock_bin_col = clock_bin_col,
      strata = strata,
      profile_variant = paste0("leave_out_", held_out_site),
      profile_scope = "custom",
      held_out_site = held_out_site,
      minimum_participants = minimum_participants
    )
  }))
}
