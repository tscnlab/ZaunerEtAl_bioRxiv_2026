# Descriptive tables and the fixed-example time-series source data.
# Calculations use prepared inputs loaded by analyses/descriptives.qmd.

display_site_levels <- function() {
  c("Overall", descriptive_site_order())
}

display_site_label <- function(site) {
  ifelse(
    site == "Overall",
    "Overall",
    unname(descriptive_site_reader_labels()[site])
  )
}

format_duration_minutes <- function(minutes) {
  rounded <- round_display_minutes(minutes)
  ifelse(
    is.finite(minutes),
    sprintf("%02d:%02d", rounded %/% 60L, rounded %% 60L),
    "Not available"
  )
}

format_duration_hours <- function(hours) {
  format_duration_minutes(60 * hours)
}

format_elapsed_minutes <- function(minutes, max_units = Inf) {
  if (!is.finite(minutes)) return("Not available")
  total <- round(minutes)
  weeks <- total %/% (7L * 1440L)
  total <- total %% (7L * 1440L)
  days <- total %/% 1440L
  total <- total %% 1440L
  hours <- total %/% 60L
  mins <- total %% 60L
  parts <- c(
    if (weeks > 0L) paste0(weeks, "w") else character(),
    if (days > 0L) paste0(days, "d") else character(),
    if (hours > 0L) paste0(hours, "h") else character(),
    if (mins > 0L || !length(c(weeks, days, hours)[c(weeks, days, hours) > 0L])) {
      paste0(mins, " min")
    } else character()
  )
  paste(utils::head(parts, max_units), collapse = " ")
}

format_date_short <- function(x) {
  date <- if (is.numeric(x)) as.Date(x, origin = "1970-01-01") else as.Date(x)
  ifelse(is.na(date), "Not available", format(date, "%y/%m/%d"))
}

finite_summary <- function(x, probs = c(0.05, 0.5, 0.95)) {
  x <- x[is.finite(x)]
  if (!length(x)) return(c(lower = NA_real_, median = NA_real_, upper = NA_real_, n = 0))
  values <- stats::quantile(x, probs = probs, names = FALSE, type = 7L)
  c(lower = values[[1L]], median = values[[2L]], upper = values[[3L]], n = length(x))
}

circular_interval <- function(minutes, probs = c(0.05, 0.5, 0.95)) {
  minutes <- minutes[is.finite(minutes)] %% 1440
  if (!length(minutes)) {
    return(c(lower = NA_real_, median = NA_real_, upper = NA_real_, n = 0))
  }
  angle <- 2 * pi * minutes / 1440
  center <- (atan2(mean(sin(angle)), mean(cos(angle))) %% (2 * pi)) * 1440 / (2 * pi)
  displacement <- (minutes - center + 720) %% 1440 - 720
  values <- stats::quantile(displacement, probs = probs, names = FALSE, type = 7L)
  c(
    lower = (center + values[[1L]]) %% 1440,
    median = (center + values[[2L]]) %% 1440,
    upper = (center + values[[3L]]) %% 1440,
    n = length(minutes)
  )
}

display_table_row <- function(
  section, characteristic, site, display, denominator_definition,
  placement = "mixed_or_not_applicable", n_participants = NA_integer_,
  n_participant_days = NA_integer_, n_observations = NA_integer_
) {
  data.frame(
    section = section,
    characteristic = characteristic,
    site = site,
    reader_site = display_site_label(site),
    display = display,
    denominator_definition = denominator_definition,
    placement = placement,
    n_participants = n_participants,
    n_participant_days = n_participant_days,
    n_observations = n_observations,
    stringsAsFactors = FALSE
  )
}

build_participant_site_display <- function(
  inputs, site_sample, available_collection_days
) {
  participant <- inputs$demographics[, c(
    "site", "Id", "age", "sex", "gender", "employment_status"
  )] |>
    dplyr::left_join(
      inputs$chronotype[, c("Id", "meq_type", "meq", "msf_sc", "sjl")],
      by = "Id"
    ) |>
    dplyr::mutate(
      chronotype_group = dplyr::case_when(
        grepl("morning", .data$meq_type, ignore.case = TRUE) ~ "Morning",
        grepl("evening", .data$meq_type, ignore.case = TRUE) ~ "Evening",
        .data$meq_type == "Intermediate" ~ "Intermediate",
        TRUE ~ NA_character_
      ),
      employment_group = dplyr::case_when(
        .data$employment_status %in% c(
          "Full time employed", "Studying and employed",
          "Not employed but studying or in training"
        ) ~ "Full/studying",
        .data$employment_status %in% c(
          "Part time employed", "Marginally employed (Minijob)"
        ) ~ "Part/marginal",
        .data$employment_status == "Not employed" ~ "Not employed",
        TRUE ~ NA_character_
      )
    )
  sleep <- inputs$sleepdiaries |>
    dplyr::filter(
      .data$Id %in% participant$Id,
      .data$sleep_interval_analysis_eligible
    )

  site_rows <- lapply(display_site_levels(), function(site_name) {
    sample <- dplyr::filter(site_sample, as.character(.data$site) == site_name)
    if (nrow(sample) != 1L) stop("Missing site sample row: ", site_name, call. = FALSE)
    pdata <- if (site_name == "Overall") participant else {
      dplyr::filter(participant, .data$site == site_name)
    }
    sdata <- if (site_name == "Overall") sleep else {
      dplyr::filter(sleep, .data$site == site_name)
    }
    cdays <- if (site_name == "Overall") available_collection_days else {
      dplyr::filter(available_collection_days, .data$site == site_name)
    }
    union_days <- cdays |>
      dplyr::distinct(
        .data$site, .data$Id, .data$local_date, .data$photoperiod_hours
      )
    n_roster <- nrow(pdata)

    count_string <- function(x, levels) {
      values <- as.character(x)
      counts <- table(factor(values, levels = levels))
      paste0(levels, " ", as.integer(counts), collapse = " / ")
    }
    summarize_collection <- function() {
      if (!nrow(union_days)) return("Not available")
      dates <- as.Date(union_days$local_date)
      paste0(
        format_date_short(min(dates)), "–", format_date_short(max(dates)),
        "; n=", nrow(union_days), " participant-days"
      )
    }
    summarize_photoperiod <- function() {
      summary <- finite_summary(union_days$photoperiod_hours)
      if (!summary[["n"]]) return("Not available")
      sprintf(
        "%.2f h (%.2f–%.2f); n=%d participant-days",
        summary[["median"]], summary[["lower"]], summary[["upper"]],
        as.integer(summary[["n"]])
      )
    }
    continuous_display <- function(x, unit = "", digits = 1L) {
      summary <- finite_summary(x)
      if (!summary[["n"]]) return("Not available")
      paste0(
        format_number_compact(summary[["median"]], digits), unit, " (",
        format_number_compact(summary[["lower"]], digits), unit, "–",
        format_number_compact(summary[["upper"]], digits), unit, "); n=",
        as.integer(summary[["n"]]), " participants"
      )
    }
    circular_display <- function(x) {
      summary <- circular_interval(as.numeric(x) / 60)
      if (!summary[["n"]]) return("Not available")
      paste0(
        format_clock_minute(summary[["median"]]), " (",
        format_clock_minute(summary[["lower"]]), "–",
        format_clock_minute(summary[["upper"]]), "); n=",
        as.integer(summary[["n"]]), " participants"
      )
    }
    sleep_summary <- finite_summary(as.numeric(sdata$sleep_duration, units = "hours"))
    sleep_display <- if (sleep_summary[["n"]]) {
      sprintf(
        "%.2f h (%.2f–%.2f); n=%d diary records from %d participants",
        sleep_summary[["median"]], sleep_summary[["lower"]],
        sleep_summary[["upper"]], as.integer(sleep_summary[["n"]]),
        dplyr::n_distinct(sdata$Id)
      )
    } else "Not available"
    work_free <- table(factor(
      as.character(sdata$daytype2), levels = c("a work day", "a free day")
    ))
    work_free_display <- paste0(
      as.integer(work_free[[1L]]), " work / ", as.integer(work_free[[2L]]),
      " free; n=", sum(work_free), " eligible diary records"
    )

    rows <- list(
      display_table_row(
        "Site specifics", "Institution", site_name,
        if (site_name == "Overall") "Overall" else site_name,
        "Study site", n_participants = n_roster
      ),
      display_table_row(
        "Site specifics", "Country", site_name,
        if (site_name == "Overall") "Not applicable" else sample$country,
        "Study site"
      ),
      display_table_row(
        "Site specifics", "City", site_name,
        if (site_name == "Overall") "Not applicable" else sample$city,
        "Study site"
      ),
      display_table_row(
        "Site specifics", "Coordinates", site_name,
        if (site_name == "Overall") "Not applicable" else sprintf(
          "%.1f°%s, %.1f°%s",
          abs(sample$latitude_deg), ifelse(sample$latitude_deg >= 0, "N", "S"),
          abs(sample$longitude_deg), ifelse(sample$longitude_deg >= 0, "E", "W")
        ),
        "Verified site coordinates"
      ),
      display_table_row(
        "Data collection", "Participants", site_name,
        paste0(
          sample$roster_participants, " roster (near-eye ",
          sample$near_eye_available_participants, "; chest ",
          sample$chest_available_participants, "; paired ",
          sample$available_paired_participants, ")"
        ),
        paste(
          "Whole participant roster; placement counts include any recorded",
          "non-all-zero participant-day"
        ),
        n_participants = sample$roster_participants
      ),
      display_table_row(
        "Data collection", "Participant-days", site_name,
        paste0(
          sample$available_union_participant_days, " roster (near-eye ",
          sample$near_eye_available_participant_days, "; chest ",
          sample$chest_available_participant_days, "; paired ",
          sample$available_paired_participant_days, ")"
        ),
        paste(
          "All participant-days with recorded data except exact all-zero",
          "melEDI days; roster is the union across placements"
        ),
        n_participants = sample$available_union_participants,
        n_participant_days = sample$available_union_participant_days
      ),
      display_table_row(
        "Data collection", "Weekday / weekend", site_name,
        paste0(
          "Near-eye ", sample$near_eye_available_weekdays, " / ",
          sample$near_eye_available_weekends, "; chest ",
          sample$chest_available_weekdays, " / ",
          sample$chest_available_weekends
        ),
        "Available non-all-zero participant-days; placements remain separate",
        n_participant_days = sample$available_union_participant_days
      ),
      display_table_row(
        "Data collection", "Workday / free-day diaries", site_name,
        work_free_display,
        "Eligible normalized sleep-diary records from the whole roster",
        n_participants = dplyr::n_distinct(sdata$Id),
        n_observations = nrow(sdata)
      ),
      display_table_row(
        "Data collection", "Participant time", site_name,
        format_elapsed_minutes(
          sample$near_eye_real_minutes, max_units = 2L
        ),
        "Near-eye eligible real minutes on screened participant-days",
        placement = "near_eye",
        n_participant_days = sample$near_eye_participant_days
      ),
      display_table_row(
        "Data collection", "Declared non-wear", site_name,
        paste0(
          "Near-eye ", format_elapsed_minutes(
            sample$near_eye_declared_nonwear_minutes,
            max_units = 2L
          ),
          sprintf(
            " (%.2f%%)",
            sample$near_eye_declared_nonwear_percent
          )
        ),
        paste(
          "Near-eye wear-log off outside diary sleep divided by eligible",
          "real minutes on screened days"
        ),
        placement = "near_eye",
        n_participant_days = sample$near_eye_participant_days
      ),
      display_table_row(
        "Data collection", "Screened days", site_name,
        paste0(
          "Near-eye ", sample$near_eye_participant_days,
          "; chest ", sample$chest_participant_days
        ),
        "Final participant-days after completeness and exact-all-zero screens",
        n_participant_days = sample$near_eye_participant_days
      ),
      display_table_row(
        "Data collection", "Collection dates", site_name,
        summarize_collection(),
        "Total local-date span across the whole available roster"
      ),
      display_table_row(
        "Data collection", "Civil photoperiod", site_name,
        summarize_photoperiod(),
        paste(
          "Median (5th–95th percentile) verified civil photoperiod across",
          "the whole available roster"
        )
      ),
      display_table_row(
        "Participant information", "Age", site_name,
        continuous_display(pdata$age, " y", 3L),
        "Whole participant roster; median (5th–95th percentile)",
        n_participants = n_roster
      ),
      display_table_row(
        "Participant information", "Sex", site_name,
        paste0(count_string(pdata$sex, c("Female", "Male")), "; n=", sum(!is.na(pdata$sex))),
        "Whole roster participants with normalized sex",
        n_participants = sum(!is.na(pdata$sex))
      ),
      display_table_row(
        "Participant information", "Gender", site_name,
        paste0(
          count_string(pdata$gender, c("Woman", "Man", "Non-binary")),
          "; n=", sum(!is.na(pdata$gender))
        ),
        "Whole roster participants with normalized gender",
        n_participants = sum(!is.na(pdata$gender))
      ),
      display_table_row(
        "Participant information", "Employment status", site_name,
        paste0(
          count_string(
            pdata$employment_group,
            c("Full/studying", "Part/marginal", "Not employed")
          ),
          "; n=", sum(!is.na(pdata$employment_group))
        ),
        "Whole roster; categories reproduce the earlier grouped presentation",
        n_participants = sum(!is.na(pdata$employment_group))
      ),
      display_table_row(
        "Participant information", "Chronotype group", site_name,
        paste0(
          count_string(
            pdata$chronotype_group, c("Morning", "Intermediate", "Evening")
          ),
          "; n=", sum(!is.na(pdata$chronotype_group))
        ),
        "Whole roster with Morningness–Eveningness Questionnaire category",
        n_participants = sum(!is.na(pdata$chronotype_group))
      ),
      display_table_row(
        "Participant information", "Sleep-corrected midsleep on free days", site_name,
        circular_display(pdata$msf_sc),
        "Whole roster; circular median and circular 5th–95th interval",
        n_participants = sum(!is.na(pdata$msf_sc))
      ),
      display_table_row(
        "Participant information", "Morningness–Eveningness Questionnaire score", site_name,
        continuous_display(pdata$meq, "", 3L),
        "Whole roster; median (5th–95th percentile)",
        n_participants = sum(is.finite(pdata$meq))
      ),
      display_table_row(
        "Participant information", "Social jetlag", site_name,
        continuous_display(as.numeric(pdata$sjl, units = "hours"), " h", 3L),
        "Whole roster; median (5th–95th percentile)",
        n_participants = sum(!is.na(pdata$sjl))
      ),
      display_table_row(
        "Participant information", "Sleep duration", site_name,
        sleep_display,
        "Eligible normalized sleep-diary records from the whole roster; median (5th–95th percentile)",
        n_participants = dplyr::n_distinct(sdata$Id),
        n_observations = nrow(sdata)
      )
    )
    dplyr::bind_rows(rows)
  })
  dplyr::bind_rows(site_rows) |>
    dplyr::mutate(
      site = factor(.data$site, levels = display_site_levels()),
      reader_site = factor(
        .data$reader_site,
        levels = display_site_label(display_site_levels())
      )
    ) |>
    dplyr::arrange(
      match(.data$section, c("Site specifics", "Data collection", "Participant information")),
      match(.data$characteristic, unique(.data$characteristic)),
      .data$site
    )
}

display_metric_contract <- function() {
  data.frame(
    category = c(
      rep("Duration", 5), rep("Dynamics", 2), "Exposure history",
      rep("Level", 3), "Spectrum", rep("Timing", 5)
    ),
    metric_order = seq_len(17),
    metric_id = c(
      "duration_above_1000", "duration_above_250_wake",
      "duration_below_10_pre_sleep", "duration_below_1_sleep_environment",
      "longest_bout_above_250", "interdaily_stability",
      "intradaily_variability", "dose_time_sensitive_corrected_medi",
      "daily_geometric_mean_medi", "m10_mean_medi", "l10_mean_medi",
      "mder_mean_of_viable_ratios", "m10_midpoint", "l10_midpoint",
      "first_timing_above_250", "last_timing_above_250",
      "mean_timing_above_250"
    ),
    table_name = c(
      "Time above 1,000 lx melEDI", "Time above 250 lx melEDI during wake",
      "Time below 10 lx melEDI before sleep",
      "Time below 1 lx melEDI during sleep",
      "Longest period above 250 lx melEDI", "Interdaily stability",
      "Intradaily variability", "melEDI dose", "Mean melEDI",
      "Brightest 10 h mean", "Darkest 10 h mean",
      "Melanopic daylight efficacy ratio", "Midpoint of the brightest 10 hours",
      "Midpoint of the darkest 10 hours",
      "First light timing above 250 lx melEDI",
      "Last light timing above 250 lx melEDI",
      "Mean timing of exposure above 250 lx melEDI"
    ),
    unit = c(
      rep("HH:MM", 5), rep("dimensionless", 2), "klx·h",
      rep("lx", 3), "dimensionless", rep("HH:MM clock time", 5)
    ),
    scaling = c(rep("Symlog", 5), rep("Linear", 2), "Symlog",
                rep("Symlog", 3), "Linear", rep("Circular clock", 5)),
    meaning_and_relevance = c(
      "Bright-light exposure duration; relevant to daytime alerting and circadian entrainment.",
      "Waking time in recommended daytime light; relevant to alertness, entrainment, and subsequent sleep.",
      "Low-light time before bed; limits evening melatonin suppression and circadian delay.",
      "Darkness during sleep; supports nocturnal melatonin and an undisturbed sleep environment.",
      "Longest sustained bright-light bout; captures continuity of daytime circadian stimulation.",
      "Day-to-day regularity of the light–dark pattern; higher regularity supports circadian stability.",
      "Within-day fragmentation of light exposure; higher values indicate less consolidated light–dark input.",
      "Intensity–duration-weighted melanopic exposure; summarizes cumulative non-visual retinal light input.",
      "Geometric average of daily melEDI values, including zeros; summarizes overall exposure while reducing peak influence.",
      "Mean of the brightest 10 hours; reflects the strength of the main daytime light episode.",
      "Mean of the darkest 10 hours; lower values during the biological night favour melatonin preservation and sleep.",
      paste(
        "Mean of viable one-minute melEDI/illuminance ratios; indicates",
        "melanopic efficacy relative to visual light."
      ),
      "Centre time of the brightest 10 hours; indexes the main daily circadian light cue.",
      "Centre time of the darkest 10 hours; indexes the main daily darkness cue.",
      "First waking bright-light exposure; morning timing can advance circadian phase and promote alertness.",
      "Last bright-light exposure; later timing may delay circadian phase and sleep onset.",
      "Average bright-light timing; summarizes the phase of daily circadian stimulation."
    ),
    stringsAsFactors = FALSE
  )
}

format_display_metric_decimal <- function(value, decimal_places = 3L) {
  if (!is.finite(value)) return("Not estimable")
  if (abs(value) < 0.5 * 10^(-decimal_places)) value <- 0
  formatted <- formatC(
    value,
    format = "f", digits = decimal_places,
    big.mark = ",", decimal.mark = "."
  )
  sub("\\.?0+$", "", formatted)
}

format_display_metric_value <- function(value, metric_id) {
  if (!is.finite(value)) return("Not estimable")
  if (grepl("duration|longest_bout", metric_id)) return(format_duration_hours(value))
  if (grepl("timing|midpoint", metric_id)) return(format_clock_minute(value))
  if (metric_id == "dose_time_sensitive_corrected_medi") {
    return(format_display_metric_decimal(value / 1000, 3L))
  }
  format_display_metric_decimal(value, 3L)
}

format_display_metric_spread <- function(value, metric_id) {
  if (!is.finite(value)) return("Not estimable")
  if (grepl("duration|longest_bout", metric_id)) {
    return(format_duration_hours(value))
  }
  if (grepl("timing|midpoint", metric_id)) {
    return(format_duration_minutes(value))
  }
  if (metric_id == "dose_time_sensitive_corrected_medi") {
    return(format_display_metric_decimal(value / 1000, 3L))
  }
  format_display_metric_decimal(value, 3L)
}

build_metric_display <- function(metric_summary) {
  contract <- display_metric_contract()
  metric_summary |>
    dplyr::filter(
      .data$placement == "near_eye",
      .data$metric_id %in% contract$metric_id
    ) |>
    dplyr::inner_join(contract, by = "metric_id") |>
    dplyr::mutate(
      site = factor(as.character(.data$site), levels = display_site_levels()),
      reader_site = display_site_label(as.character(.data$site)),
      median_formatted = mapply(
        format_display_metric_value, .data$median, .data$metric_id,
        USE.NAMES = FALSE
      ),
      q1_formatted = mapply(
        format_display_metric_value, .data$q1, .data$metric_id,
        USE.NAMES = FALSE
      ),
      q3_formatted = mapply(
        format_display_metric_value, .data$q3, .data$metric_id,
        USE.NAMES = FALSE
      ),
      mean_formatted = mapply(
        format_display_metric_value, .data$mean, .data$metric_id,
        USE.NAMES = FALSE
      ),
      sd_formatted = mapply(
        format_display_metric_spread, .data$sd, .data$metric_id,
        USE.NAMES = FALSE
      ),
      display = paste0(
        .data$median_formatted, " (", .data$q1_formatted, "–",
        .data$q3_formatted, "); mean ", .data$mean_formatted, " ± ",
        .data$sd_formatted,
        "; n=", .data$n_observations, " obs / ", .data$n_participants,
        " participants / ", .data$n_participant_days, " participant-days"
      )
    ) |>
    dplyr::arrange(.data$metric_order, .data$site)
}

build_recommendation_display <- function(recommendation) {
  main <- recommendation |>
    dplyr::mutate(site = as.character(.data$site)) |>
    dplyr::arrange(
      factor(.data$site, levels = display_site_levels()),
      match(.data$brown_state, c("wake", "pre-sleep", "sleep"))
    )
  wide <- main |>
    dplyr::group_by(.data$site) |>
    dplyr::summarise(
      participants = dplyr::first(.data$n_participants),
      participant_days = dplyr::first(.data$n_participant_days),
      eligible_real_minutes = dplyr::first(.data$n_all_eligible_real_minutes),
      wake_fraction = .data$pooled_fraction_in_contextual_range[.data$brown_state == "wake"],
      pre_sleep_fraction = .data$pooled_fraction_in_contextual_range[.data$brown_state == "pre-sleep"],
      sleep_fraction = .data$pooled_fraction_in_contextual_range[.data$brown_state == "sleep"],
      wake_context_numerator = .data$n_minutes_in_contextual_range[.data$brown_state == "wake"],
      pre_sleep_context_numerator = .data$n_minutes_in_contextual_range[.data$brown_state == "pre-sleep"],
      sleep_context_numerator = .data$n_minutes_in_contextual_range[.data$brown_state == "sleep"],
      combined_fraction = sum(.data$n_minutes_in_contextual_range) /
        sum(.data$n_valid_one_minute_observations),
      combined_context_numerator = sum(.data$n_minutes_in_contextual_range),
      wake_time_fraction = .data$state_fraction_of_eligible_minutes[.data$brown_state == "wake"],
      pre_sleep_time_fraction = .data$state_fraction_of_eligible_minutes[.data$brown_state == "pre-sleep"],
      sleep_time_fraction = .data$state_fraction_of_eligible_minutes[.data$brown_state == "sleep"],
      wake_time_numerator = .data$n_state_real_minutes[.data$brown_state == "wake"],
      pre_sleep_time_numerator = .data$n_state_real_minutes[.data$brown_state == "pre-sleep"],
      sleep_time_numerator = .data$n_state_real_minutes[.data$brown_state == "sleep"],
      unclassified_time_fraction = pmax(
        0,
        1 - sum(.data$state_fraction_of_eligible_minutes)
      ),
      unclassified_time_numerator = pmax(
        0,
        dplyr::first(.data$n_all_eligible_real_minutes) -
          sum(.data$n_state_real_minutes)
      ),
      wake_valid_minutes = .data$n_valid_one_minute_observations[.data$brown_state == "wake"],
      pre_sleep_valid_minutes = .data$n_valid_one_minute_observations[.data$brown_state == "pre-sleep"],
      sleep_valid_minutes = .data$n_valid_one_minute_observations[.data$brown_state == "sleep"],
      classified_valid_minutes = sum(.data$n_valid_one_minute_observations),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      reader_site = display_site_label(.data$site),
      sample_display = paste0(
        .data$participants, " participants; ", .data$participant_days,
        " participant-days; ", format(.data$eligible_real_minutes, big.mark = ","),
        " eligible real minutes"
      ),
      site = factor(.data$site, levels = display_site_levels())
    ) |>
    dplyr::arrange(.data$site)
  wide
}

display_time_series_ids <- function() {
  c(
    "BAUA_S003", "BAUA_S009", "BAUA_S022", "MPI_S205",
    "MPI_S226", "MPI_S227", "TUM_S009"
  )
}

read_gap_timing_unaware_near_eye <- function(root) {
  contract <- gap_timing_unaware_near_eye_contract(root)
  if (!file.exists(contract$path[[1L]])) {
    stop("Gap-timing-unaware near-eye source is missing", call. = FALSE)
  }
  workspace <- new.env(parent = baseenv())
  loaded_objects <- base::load(contract$path[[1L]], envir = workspace)
  if (!contract$object[[1L]] %in% loaded_objects) {
    stop("Expected gap-timing-unaware object is absent", call. = FALSE)
  }
  data <- workspace[[contract$object[[1L]]]] |>
    dplyr::ungroup() |>
    dplyr::as_tibble()
  required <- c(
    "site", "Id", "Date", "Datetime", "MEDI", "photoperiod.state"
  )
  if (!all(required %in% names(data))) {
    stop("Gap-timing-unaware near-eye object is incomplete", call. = FALSE)
  }
  list(
    data = data,
    provenance = contract |>
      dplyr::transmute(
        dataset_id = .data$dataset_id,
        reader_label = .data$reader_label,
        source_path = substring(
          normalizePath(.data$path, winslash = "/", mustWork = TRUE),
          nchar(normalizePath(root, winslash = "/", mustWork = TRUE)) + 2L
        ),
        source_object = .data$object,
        aggregation = .data$aggregation
      )
  )
}

build_time_series_display_sources <- function(root) {
  ids <- display_time_series_ids()
  weekday_levels <- c("Wed", "Thu", "Fri", "Sat", "Sun")
  source <- read_gap_timing_unaware_near_eye(root)
  selected_dates <- source$data |>
    dplyr::filter(.data$Id %in% ids) |>
    dplyr::distinct(.data$site, .data$Id, .data$Date) |>
    dplyr::group_by(.data$site, .data$Id) |>
    dplyr::arrange(.data$Date, .by_group = TRUE) |>
    dplyr::mutate(study_day = dplyr::row_number()) |>
    dplyr::filter(.data$study_day %in% 2:6) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      protocol_day = .data$study_day - 1L,
      weekday = weekday_levels[.data$protocol_day],
      selection_rule = paste0(
        "Seven fixed example participants and study days 2–6; displayed ",
        "30-minute values come directly from the gap-timing-unaware dataset"
      )
    )
  expected_rows <- length(ids) * length(weekday_levels)
  if (nrow(selected_dates) != expected_rows) {
    stop("Time-series display selection does not contain 7 × 5 days", call. = FALSE)
  }

  selected_samples <- source$data |>
    dplyr::inner_join(
      selected_dates,
      by = c("site", "Id", "Date")
    ) |>
    dplyr::mutate(Date = as.Date(.data$Date))
  if (anyDuplicated(selected_samples[c("site", "Id", "Datetime")])) {
    stop("Gap-timing-unaware display samples contain duplicate epochs", call. = FALSE)
  }

  metrics <- selected_samples |>
    dplyr::filter(.data$photoperiod.state == "day") |>
    dplyr::group_by(
      .data$site, .data$Id, .data$Date, .data$study_day,
      .data$protocol_day, .data$weekday, .data$selection_rule
    ) |>
    dplyr::group_modify(function(.x, .y) {
      duration <- LightLogR::duration_above_threshold(
        .x$MEDI,
        .x$Datetime,
        threshold = 250,
        na.rm = TRUE
      )
      data.frame(
        duration_above_250_daytime_h = as.numeric(duration, units = "hours"),
        finite_daytime_samples = sum(is.finite(.x$MEDI)),
        samples_above_250 = sum(is.finite(.x$MEDI) & .x$MEDI > 250),
        stringsAsFactors = FALSE
      )
    }) |>
    dplyr::ungroup()
  if (nrow(metrics) != expected_rows) {
    stop("TAT250 could not be calculated for every displayed day", call. = FALSE)
  }

  participant_order <- metrics |>
    dplyr::group_by(.data$Id) |>
    dplyr::summarise(
      participant_tat250_median_h = finite_median(
        .data$duration_above_250_daytime_h
      ),
      .groups = "drop"
    ) |>
    dplyr::distinct(.data$Id, .data$participant_tat250_median_h) |>
    dplyr::arrange(.data$participant_tat250_median_h, .data$Id) |>
    dplyr::mutate(participant_order = dplyr::row_number()) |>
    dplyr::select("Id", "participant_order")
  metrics <- metrics |>
    dplyr::left_join(participant_order, by = "Id") |>
    dplyr::arrange(.data$participant_order, .data$protocol_day)
  selected <- selected_dates |>
    dplyr::left_join(
      dplyr::select(
        metrics,
        "site", "Id", "Date", "duration_above_250_daytime_h",
        "finite_daytime_samples", "samples_above_250"
      ),
      by = c("site", "Id", "Date")
    ) |>
    dplyr::left_join(participant_order, by = "Id") |>
    dplyr::arrange(.data$participant_order, .data$protocol_day)

  selected_keys <- selected |>
    dplyr::select(
      site, Id, Date, weekday, participant_order, protocol_day
    )
  series <- selected_samples |>
    dplyr::left_join(
      dplyr::select(
        selected_keys,
        "site", "Id", "Date", "participant_order", "protocol_day", "weekday"
      ),
      by = c("site", "Id", "Date", "protocol_day", "weekday")
    ) |>
    dplyr::mutate(
      clock_bin = lubridate::hour(.data$Datetime) * 60 +
        lubridate::minute(.data$Datetime),
      aligned_minute = (.data$protocol_day - 1L) * 1440 + .data$clock_bin
    ) |>
    dplyr::transmute(
      site = .data$site,
      participant = .data$Id,
      participant_order = .data$participant_order,
      local_date = as.Date(.data$Date),
      weekday = .data$weekday,
      protocol_day = .data$protocol_day,
      clock_bin = .data$clock_bin,
      aligned_minute = .data$aligned_minute,
      melEDI_lx = .data$MEDI,
      sample_available = is.finite(.data$MEDI),
      photoperiod_state = .data$photoperiod.state,
      daytime = .data$photoperiod.state == "day",
      aggregation_method =
        "Stored floor-aligned 30-minute arithmetic mean",
      dataset = "Gap-timing-unaware near-eye dataset",
      analysis_unit = "participant-30-minute"
    ) |>
    dplyr::arrange(.data$participant_order, .data$aligned_minute)

  # Calculate solar context from daily mean dawn and dusk, independently of
  # missing light samples. Solar context remains defined during these gaps.
  daily_solar_context <- selected_samples |>
    dplyr::left_join(
      dplyr::select(
        selected_keys,
        "site", "Id", "Date", "participant_order", "protocol_day", "weekday"
      ),
      by = c("site", "Id", "Date", "protocol_day", "weekday")
    ) |>
    dplyr::group_by(
      .data$site, .data$Id, .data$Date, .data$participant_order,
      .data$protocol_day, .data$weekday
    ) |>
    dplyr::summarise(
      dawn = mean(.data$dawn, na.rm = TRUE),
      dusk = mean(.data$dusk, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      day_start = (.data$protocol_day - 1L) * 1440,
      dawn_minute = lubridate::hour(.data$dawn) * 60 +
        lubridate::minute(.data$dawn) + lubridate::second(.data$dawn) / 60,
      dusk_minute = lubridate::hour(.data$dusk) * 60 +
        lubridate::minute(.data$dusk) + lubridate::second(.data$dusk) / 60
    )
  if (any(!is.finite(daily_solar_context$dawn_minute)) ||
      any(!is.finite(daily_solar_context$dusk_minute))) {
    stop("A Figure 4 day lacks finite dawn or dusk context", call. = FALSE)
  }
  states <- dplyr::bind_rows(
    daily_solar_context |>
      dplyr::mutate(
        interval = "midnight_to_dawn",
        xmin = .data$day_start,
        xmax = .data$day_start + .data$dawn_minute
      ),
    daily_solar_context |>
      dplyr::mutate(
        interval = "dusk_to_midnight",
        xmin = .data$day_start + .data$dusk_minute,
        xmax = .data$day_start + 1440
      )
  ) |>
    dplyr::transmute(
      site = .data$site,
      participant = .data$Id,
      participant_order = .data$participant_order,
      local_date = as.Date(.data$Date),
      weekday = .data$weekday,
      protocol_day = .data$protocol_day,
      interval = .data$interval,
      dawn_minute = .data$dawn_minute,
      dusk_minute = .data$dusk_minute,
      civil_night = TRUE,
      xmin = .data$xmin,
      xmax = .data$xmax,
      state_source = "Daily mean dawn and dusk"
    ) |>
    dplyr::arrange(.data$participant_order, .data$xmin)

  metrics <- metrics |>
    dplyr::transmute(
      site = .data$site,
      participant = .data$Id,
      participant_order = .data$participant_order,
      local_date = as.Date(.data$Date),
      weekday = .data$weekday,
      protocol_day = .data$protocol_day,
      duration_above_250_daytime_h = .data$duration_above_250_daytime_h,
      finite_daytime_samples = .data$finite_daytime_samples,
      samples_above_250 = .data$samples_above_250,
      metric_id = "duration_above_250_daytime",
      metric_source = paste(
        "Calculated from the displayed gap-timing-unaware 30-minute",
        "daytime samples with LightLogR::duration_above_threshold"
      ),
      selection_rule = .data$selection_rule
    ) |>
    dplyr::arrange(.data$participant_order, .data$protocol_day)
  list(
    selected = selected,
    series = series,
    states = states,
    metrics = metrics,
    provenance = source$provenance
  )
}

build_time_series_display_alt_text <- function(time_series) {
  list(
    short = paste0(
      "Four-panel explanation connecting five protocol weekdays of stored ",
      "30-minute near-eye light samples for seven fixed participants to ",
      "TAT250 calculated from the same displayed daytime samples."
    ),
    long = paste0(
      "Panel A shows stored 30-minute mean melEDI across Wednesday to Sunday ",
      "for ", length(unique(time_series$metrics$participant)),
      " fixed manuscript exemplars, with continuous daily dawn-to-dusk ",
      "civil-night context and a 250-lux guide. Panels B and C summarize ",
      "TAT250 calculated from the same displayed daytime samples by ",
      "participant and weekday. Panel D encodes the same calculated values ",
      "by point size. Actual dates remain in the source data."
    )
  )
}

build_display_figure_alt_text <- function(
  site_sample, metric_summary, time_series, latitude_source
) {
  overall <- dplyr::filter(site_sample, as.character(.data$site) == "Overall")
  main_metrics <- metric_summary |>
    dplyr::filter(.data$placement == "near_eye", .data$site == "Overall")
  time_series_alt <- build_time_series_display_alt_text(time_series)
  data.frame(
    figure_id = c(
      "descriptive_overview", "near_eye_site_profiles", "chest_site_profiles",
      "near_eye_metric_distributions", "time_series_to_metrics",
      "latitude_photoperiod_diagnostic"
    ),
    short_alt_text = c(
      paste0(
        "Five-panel study overview with the protocol, a country-and-coordinate-labelled world map, collection dates, ",
        "site photoperiod distributions, and a repeated 48-hour near-eye melEDI profile with central 50% and 90% bands."
      ),
      "Nine site panels repeat pooled 15-minute near-eye 24-hour melEDI profiles across 48 hours with nested central 50%, 75%, and 95% value bands.",
      "Eight site panels repeat complementary 15-minute chest-level 24-hour melEDI profiles across 48 hours with nested central 50%, 75%, and 95% value bands.",
      "Sixteen-panel grid of corrected near-eye light-metric distributions by labelled study site.",
      time_series_alt$short,
      "Observed civil photoperiod distributions and verified theoretical bounds plotted against absolute study-site latitude for main near-eye participant-days."
    ),
    long_description = c(
      paste0(
        "Panel A retains the study protocol schematic. Panel B locates nine sites. ",
        "Panel C shows roster-wide collection intervals split by pauses of at least six dates. Panel D shows roster-wide ",
        "photoperiod ridges. Panel E repeats the main near-eye daily profile once; a black ",
        "pooled 15-minute median and nested grey central 50% and 90% pointwise value bands are ",
        "shown with site lines and average sleep and civil-night periods. ",
        "The main sample is ", overall$near_eye_participants, " participants and ",
        overall$near_eye_participant_days, " participant-days; chest is complementary ",
        "with ", overall$chest_participants, " participants and ",
        overall$chest_participant_days, " participant-days."
      ),
      paste0(
        "The nine labelled site facets follow the earlier three-by-three double-plot ",
        "layout. Each site profile is a pooled median of verified values ",
        "aggregated to 15-minute bins with nested central 50%, 75%, and 95% value intervals. The repeated ",
        "second day is a display device, not additional data; baseline strips identify ",
        "average civil night and average diary sleep context; declared non-wear is omitted."
      ),
      paste0(
        "The complementary chest figure uses the same corrected double-plot structure as ",
        "the primary near-eye figure in a complete four-by-two layout. MPI has no chest main days, so eight labelled facets ",
        "are shown. Chest values describe sensor-level environmental light and are not ",
        "interpreted as ocular exposure."
      ),
      paste0(
        "Rows within each panel are the nine named sites. Ridges and white boxes show ",
        "finite distributions and middle 50% intervals for duration, regularity, dose, ",
        "level, spectrum, and circular timing metrics. Sample sizes vary by verified metric ",
        "support; the overall table contains ", nrow(main_metrics), " registered near-eye ",
        "metrics with explicit participants, participant-days, and observations. ",
        "For MDER, each daily value is the arithmetic mean of viable one-minute ",
        "melEDI/photopic-illuminance ratios. Both channels must be finite and ",
        "strictly positive, and at least 720 of the complete 1,440 local ",
        "wall-clock minutes are required (inclusive 50% rule)."
      ),
      time_series_alt$long,
      paste0(
        "Points and density ridges summarize ", nrow(latitude_source),
        " main near-eye participant-days across nine sites identified by a ",
        "registered-colour legend. Higher-latitude sites ",
        "span wider observed photoperiod ranges because their collection dates cover ",
        "different seasons. Black curtains restore the verified theoretical impossible ",
        "regions consumed from the current H1 reporting source and are drawn over the distributions."
      )
    ),
    stringsAsFactors = FALSE
  )
}
