# Data builders for tables and exact figure source data. All scientific
# calculations in this file use R and verified prepared artifacts.

load_descriptive_inputs <- function(root) {
  read_csv <- function(path) {
    readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  }
  list(
    coverage = list(
      near_eye = readRDS(file.path(
        root, "artifacts/03_coverage/light_glasses_coverage.rds"
      )),
      chest = readRDS(file.path(
        root, "artifacts/03_coverage/light_chest_coverage.rds"
      ))
    ),
    daily_coverage = list(
      near_eye = read_csv(file.path(
        root, "artifacts/03_coverage/light_glasses_daily_coverage.csv"
      )),
      chest = read_csv(file.path(
        root, "artifacts/03_coverage/light_chest_daily_coverage.csv"
      ))
    ),
    metrics_30 = list(
      near_eye = read_csv(file.path(
        root, "artifacts/05_metrics/metrics_glasses_30_minute.csv"
      )),
      chest = read_csv(file.path(
        root, "artifacts/05_metrics/metrics_chest_30_minute.csv"
      ))
    ),
    metrics_hour = list(
      near_eye = read_csv(file.path(
        root, "artifacts/05_metrics/metrics_glasses_one_hour.csv"
      )),
      chest = read_csv(file.path(
        root, "artifacts/05_metrics/metrics_chest_one_hour.csv"
      ))
    ),
    metrics_long = list(
      near_eye = read_csv(file.path(
        root, "artifacts/05_metrics/metrics_glasses_values_long.csv"
      )),
      chest = read_csv(file.path(
        root, "artifacts/05_metrics/metrics_chest_values_long.csv"
      ))
    ),
    participant_day = list(
      near_eye = read_csv(file.path(
        root, "artifacts/05_metrics/metrics_glasses_participant_day.csv"
      )),
      chest = read_csv(file.path(
        root, "artifacts/05_metrics/metrics_chest_participant_day.csv"
      ))
    ),
    participant = list(
      near_eye = read_csv(file.path(
        root, "artifacts/05_metrics/metrics_glasses_participant.csv"
      )),
      chest = read_csv(file.path(
        root, "artifacts/05_metrics/metrics_chest_participant.csv"
      ))
    ),
    demographics = readRDS(file.path(
      root, "artifacts/06_model_data/normalized_inputs/demographics.rds"
    )),
    chronotype = readRDS(file.path(
      root, "artifacts/06_model_data/normalized_inputs/chronotype.rds"
    )),
    sleepdiaries = readRDS(file.path(
      root, "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds"
    )),
    solar = readRDS(file.path(
      root, "artifacts/06_model_data/context/site_solar_context.rds"
    )),
    showcase = read_csv(file.path(
      root, "artifacts/11_source_data/prepared_day_showcase.csv"
    )),
    selected_showcase = read_csv(file.path(
      root,
      "artifacts/08_diagnostics/prepared_day_showcase/selected_days.csv"
    )),
    photoperiod_bounds = read_csv(file.path(
      root,
      paste0(
        "artifacts/11_source_data/H01/stage3/",
        "H01_stage3_photoperiod_latitude_bounds.csv"
      )
    )),
    registry = read_csv(file.path(root, "config/metric_display_registry.csv"))
  )
}

validate_descriptive_inputs <- function(inputs) {
  day_key <- c("site", "Id", "local_date")
  assert_unique_descriptive_key(
    inputs$participant_day$near_eye,
    day_key,
    "Near-eye participant-day metrics"
  )
  assert_unique_descriptive_key(
    inputs$participant_day$chest,
    day_key,
    "Chest participant-day metrics"
  )
  if (nrow(inputs$participant_day$near_eye) != 816L) {
    stop("Expected 816 near-eye participant-days", call. = FALSE)
  }
  if (nrow(inputs$participant_day$chest) != 902L) {
    stop("Expected 902 chest participant-days", call. = FALSE)
  }
  if (dplyr::n_distinct(inputs$participant_day$near_eye$Id) != 141L) {
    stop("Expected 141 near-eye participants", call. = FALSE)
  }
  if (dplyr::n_distinct(inputs$participant_day$chest$Id) != 154L) {
    stop("Expected 154 chest participants", call. = FALSE)
  }
  paired <- dplyr::inner_join(
    dplyr::select(inputs$participant_day$near_eye, dplyr::all_of(day_key)),
    dplyr::select(inputs$participant_day$chest, dplyr::all_of(day_key)),
    by = day_key
  )
  if (nrow(paired) != 643L || dplyr::n_distinct(paired$Id) != 112L) {
    stop("Expected 643 paired days from 112 participants", call. = FALSE)
  }
  expected_rows <- c(near_eye = 816L, chest = 902L)
  for (placement in names(expected_rows)) {
    if (nrow(inputs$metrics_30[[placement]]) != expected_rows[[placement]] * 48L) {
      stop("The 30-minute metric grid is incomplete for ", placement, call. = FALSE)
    }
    if (nrow(inputs$metrics_hour[[placement]]) != expected_rows[[placement]] * 24L) {
      stop("The hourly metric grid is incomplete for ", placement, call. = FALSE)
    }
    coverage_keys <- inputs$coverage[[placement]] |>
      dplyr::filter(.data$day_eligible) |>
      dplyr::distinct(site, Id, local_date)
    metric_keys <- inputs$participant_day[[placement]] |>
      dplyr::distinct(site, Id, local_date)
    coverage_key_text <- do.call(
      paste,
      c(coverage_keys, list(sep = "\r"))
    )
    metric_key_text <- do.call(
      paste,
      c(metric_keys, list(sep = "\r"))
    )
    if (!setequal(coverage_key_text, metric_key_text)) {
      stop("Coverage and metric day keys differ for ", placement, call. = FALSE)
    }
    values <- inputs$coverage[[placement]]$MEDI_eligible
    if (any(values > 100000, na.rm = TRUE)) {
      stop("An eligible melEDI value exceeds 100,000 lx", call. = FALSE)
    }
  }
  all_zero_counts <- vapply(
    inputs$daily_coverage,
    function(data) sum(data$day_all_zero_medi_excluded, na.rm = TRUE),
    integer(1)
  )
  if (!identical(unname(all_zero_counts), c(2L, 3L))) {
    stop("Expected two near-eye and three chest all-zero exclusions", call. = FALSE)
  }
  assert_unique_descriptive_key(
    inputs$solar,
    c("site", "local_date"),
    "Site solar context"
  )
  required_bound_columns <- c(
    "absolute_latitude_deg", "minimum_possible_photoperiod_hours",
    "maximum_possible_photoperiod_hours", "calendar_year",
    "solar_depression_deg"
  )
  if (!all(required_bound_columns %in% names(inputs$photoperiod_bounds))) {
    stop("The verified H1 photoperiod-bound source is incomplete", call. = FALSE)
  }
  if (any(
    inputs$photoperiod_bounds$minimum_possible_photoperiod_hours >
      inputs$photoperiod_bounds$maximum_possible_photoperiod_hours,
    na.rm = TRUE
  )) {
    stop("The verified H1 photoperiod bounds are internally inconsistent", call. = FALSE)
  }
  invisible(inputs)
}

placement_reader_label <- function(placement) {
  dplyr::recode(
    placement,
    near_eye = "Near-eye (primary)",
    chest = "Chest (complementary)",
    .default = placement
  )
}

build_collection_days <- function(inputs) {
  day_key <- c("site", "Id", "local_date")
  paired <- dplyr::inner_join(
    dplyr::select(inputs$participant_day$near_eye, dplyr::all_of(day_key)),
    dplyr::select(inputs$participant_day$chest, dplyr::all_of(day_key)),
    by = day_key
  ) |>
    dplyr::mutate(paired_day = TRUE)
  solar <- inputs$solar |>
    dplyr::select(
      site, local_date, city, country, location, timezone, latitude_deg,
      longitude_deg, photoperiod_hours, civil_dawn_wall_minute,
      civil_dusk_wall_minute
    )
  make_days <- function(data, placement) {
    data |>
      dplyr::select(
        site, Id, local_date, valid_medi_real_minutes, expected_real_minutes,
        daily_ordinary_support, measurement_construct
      ) |>
      dplyr::mutate(
        local_date = as.Date(.data$local_date),
        placement = placement,
        placement_label = placement_reader_label(placement),
        weekend = as.POSIXlt(.data$local_date)$wday %in% c(0L, 6L)
      ) |>
      dplyr::left_join(paired, by = day_key) |>
      dplyr::mutate(paired_day = dplyr::coalesce(.data$paired_day, FALSE)) |>
      dplyr::left_join(solar, by = c("site", "local_date"))
  }
  days <- dplyr::bind_rows(
    make_days(inputs$participant_day$near_eye, "near_eye"),
    make_days(inputs$participant_day$chest, "chest")
  ) |>
    dplyr::arrange(
      factor(.data$placement, levels = c("near_eye", "chest")),
      factor(.data$site, levels = descriptive_site_order()),
      .data$Id,
      .data$local_date
    )
  if (anyNA(days$photoperiod_hours)) {
    stop("A main participant-day has no verified solar context", call. = FALSE)
  }
  assert_unique_descriptive_key(
    days,
    c("placement", "site", "Id", "local_date"),
    "Collection-day source data"
  )
  days
}

build_available_collection_days <- function(inputs) {
  day_key <- c("site", "Id", "local_date")
  available_date_domain <- dplyr::bind_rows(
    inputs$daily_coverage$near_eye |>
      dplyr::filter(!.data$day_all_zero_medi_excluded),
    inputs$daily_coverage$chest |>
      dplyr::filter(!.data$day_all_zero_medi_excluded)
  ) |>
    dplyr::transmute(
      site = as.character(.data$site),
      local_date = as.Date(.data$local_date)
    ) |>
    dplyr::distinct() |>
    dplyr::arrange(.data$site, .data$local_date)
  verified_solar_keys <- inputs$solar |>
    dplyr::transmute(
      site = as.character(.data$site),
      local_date = as.Date(.data$local_date)
    )
  missing_date_domain <- available_date_domain |>
    dplyr::anti_join(verified_solar_keys, by = c("site", "local_date"))
  site_metadata <- inputs$solar |>
    dplyr::select(dplyr::all_of(site_metadata_required_columns())) |>
    dplyr::distinct()
  extended_solar <- if (nrow(missing_date_domain)) {
    validate_site_date_domain(missing_date_domain, site_metadata)
    validate_solar_context_runtime()
    extension_rows <- lapply(
      unique(missing_date_domain$site),
      function(site_code) {
        calculate_site_solar_context(
          site_dates = dplyr::filter(
            missing_date_domain, .data$site == .env$site_code
          ),
          site_metadata_row = dplyr::filter(
            site_metadata, .data$site == .env$site_code
          ),
          solar_depression_deg = 6
        )
      }
    )
    extension <- dplyr::bind_rows(extension_rows) |>
      dplyr::mutate(
        solar_context_algorithm = paste0(
          "LightLogR::photoperiod + suntools::solarnoon(local midnight)"
        ),
        lightlogr_version = as.character(utils::packageVersion("LightLogR")),
        suntools_version = as.character(utils::packageVersion("suntools")),
        r_version = as.character(getRversion())
      ) |>
      dplyr::arrange(.data$site, .data$local_date)
    assert_unique_descriptive_key(
      extension,
      c("site", "local_date"),
      "Extended available-day solar context"
    )
    expected_keys <- paste(
      missing_date_domain$site,
      as.Date(missing_date_domain$local_date),
      sep = "\r"
    )
    observed_keys <- paste(
      extension$site, as.Date(extension$local_date), sep = "\r"
    )
    if (!setequal(expected_keys, observed_keys)) {
      stop(
        "The available-day solar extension does not cover its date domain",
        call. = FALSE
      )
    }
    extension |>
      dplyr::mutate(
        solar_context_origin =
          "canonical extension for available non-all-zero day"
      )
  } else {
    inputs$solar[0, ] |>
      dplyr::mutate(solar_context_origin = character())
  }
  solar <- dplyr::bind_rows(
    inputs$solar |>
      dplyr::mutate(
        solar_context_origin = "verified shared solar-context artifact"
      ),
    extended_solar
  ) |>
    dplyr::semi_join(
      available_date_domain, by = c("site", "local_date")
    ) |>
    dplyr::select(
      site, local_date, city, country, location, timezone, latitude_deg,
      longitude_deg, photoperiod_hours, civil_dawn_wall_minute,
      civil_dusk_wall_minute, solar_context_origin,
      solar_context_algorithm, solar_depression_deg,
      coordinate_source, coordinate_source_version
    )
  make_days <- function(data, placement) {
    data |>
      dplyr::filter(!.data$day_all_zero_medi_excluded) |>
      dplyr::transmute(
        site = .data$site,
        Id = .data$Id,
        local_date = as.Date(.data$local_date),
        placement = placement,
        placement_label = placement_reader_label(placement),
        source_real_minutes = .data$day_source_real_minutes,
        valid_minutes_raw = .data$day_valid_minutes_raw,
        screened_day = .data$day_eligible,
        weekend = as.POSIXlt(as.Date(.data$local_date))$wday %in% c(0L, 6L)
      ) |>
      dplyr::left_join(solar, by = c("site", "local_date"))
  }
  days <- dplyr::bind_rows(
    make_days(inputs$daily_coverage$near_eye, "near_eye"),
    make_days(inputs$daily_coverage$chest, "chest")
  )
  paired <- days |>
    dplyr::count(.data$site, .data$Id, .data$local_date, name = "placements") |>
    dplyr::mutate(paired_available = .data$placements == 2L) |>
      dplyr::select(dplyr::all_of(day_key), "paired_available")
  days <- days |>
    dplyr::left_join(paired, by = day_key) |>
    dplyr::arrange(
      factor(.data$placement, levels = c("near_eye", "chest")),
      factor(.data$site, levels = descriptive_site_order()),
      .data$Id, .data$local_date
    )
  if (anyNA(days$photoperiod_hours)) {
    stop("An available participant-day has no verified solar context", call. = FALSE)
  }
  assert_unique_descriptive_key(
    days,
    c("placement", "site", "Id", "local_date"),
    "Available collection-day source data"
  )
  days
}

add_overall_rows <- function(data, summarise_function) {
  dplyr::bind_rows(
    summarise_function(data, "site"),
    summarise_function(dplyr::mutate(data, site = "Overall"), "site")
  )
}

build_site_sample_characteristics <- function(
  inputs, collection_days, available_collection_days
) {
  sites <- inputs$solar |>
    dplyr::distinct(
      .data$site, .data$city, .data$country, .data$location,
      .data$latitude_deg, .data$longitude_deg
    )
  roster <- inputs$demographics |>
    dplyr::count(.data$site, name = "roster_participants")
  roster <- dplyr::bind_rows(
    roster,
    dplyr::summarise(
      inputs$demographics,
      site = "Overall",
      roster_participants = dplyr::n_distinct(.data$Id)
    )
  )
  day_summary <- function(data, grouping) {
    data |>
      dplyr::group_by(.data[[grouping]], .data$placement) |>
      dplyr::summarise(
        participants = dplyr::n_distinct(.data$Id),
        participant_days = dplyr::n(),
        weekdays = sum(!.data$weekend),
        weekends = sum(.data$weekend),
        first_date = min(.data$local_date),
        last_date = max(.data$local_date),
        photoperiod_median_h = stats::median(.data$photoperiod_hours),
        photoperiod_q1_h = finite_quantile(.data$photoperiod_hours, 0.25),
        photoperiod_q3_h = finite_quantile(.data$photoperiod_hours, 0.75),
        .groups = "drop"
      )
  }
  by_site <- day_summary(collection_days, "site")
  overall <- day_summary(
    dplyr::mutate(collection_days, site = "Overall"),
    "site"
  )
  days_wide <- dplyr::bind_rows(by_site, overall) |>
    tidyr::pivot_wider(
      names_from = "placement",
      values_from = c(
        "participants", "participant_days", "weekdays", "weekends",
        "first_date", "last_date", "photoperiod_median_h",
        "photoperiod_q1_h", "photoperiod_q3_h"
      ),
      names_glue = "{placement}_{.value}"
    )

  available_by_placement <- dplyr::bind_rows(
    day_summary(available_collection_days, "site"),
    day_summary(
      dplyr::mutate(available_collection_days, site = "Overall"),
      "site"
    )
  ) |>
    tidyr::pivot_wider(
      names_from = "placement",
      values_from = c(
        "participants", "participant_days", "weekdays", "weekends",
        "first_date", "last_date", "photoperiod_median_h",
        "photoperiod_q1_h", "photoperiod_q3_h"
      ),
      names_glue = "{placement}_available_{.value}"
    )

  available_union <- available_collection_days |>
    dplyr::distinct(
      .data$site, .data$Id, .data$local_date, .data$weekend,
      .data$photoperiod_hours
    )
  union_summary <- function(data) {
    data |>
      dplyr::group_by(.data$site) |>
      dplyr::summarise(
        available_union_participants = dplyr::n_distinct(.data$Id),
        available_union_participant_days = dplyr::n(),
        available_union_weekdays = sum(!.data$weekend),
        available_union_weekends = sum(.data$weekend),
        available_union_first_date = min(.data$local_date),
        available_union_last_date = max(.data$local_date),
        available_union_photoperiod_median_h = stats::median(
          .data$photoperiod_hours
        ),
        available_union_photoperiod_p05_h = finite_quantile(
          .data$photoperiod_hours, 0.05
        ),
        available_union_photoperiod_p95_h = finite_quantile(
          .data$photoperiod_hours, 0.95
        ),
        .groups = "drop"
      )
  }
  union_wide <- dplyr::bind_rows(
    union_summary(available_union),
    union_summary(dplyr::mutate(available_union, site = "Overall"))
  )

  coverage_summary <- function(data, placement) {
    screened <- data |>
      dplyr::filter(.data$day_eligible)
    by_site <- screened |>
      dplyr::group_by(.data$site) |>
      dplyr::summarise(
        real_minutes = dplyr::n(),
        declared_nonwear_minutes = sum(.data$invalid_nonwear, na.rm = TRUE),
        .groups = "drop"
      )
    dplyr::bind_rows(
      by_site,
      dplyr::summarise(
        screened,
        site = "Overall",
        real_minutes = dplyr::n(),
        declared_nonwear_minutes = sum(.data$invalid_nonwear, na.rm = TRUE)
      )
    ) |>
      dplyr::mutate(
        declared_nonwear_percent = 100 * .data$declared_nonwear_minutes /
          .data$real_minutes,
        placement = placement
      )
  }
  coverage_wide <- dplyr::bind_rows(
    coverage_summary(inputs$coverage$near_eye, "near_eye"),
    coverage_summary(inputs$coverage$chest, "chest")
  ) |>
    tidyr::pivot_wider(
      names_from = "placement",
      values_from = c(
        "real_minutes", "declared_nonwear_minutes",
        "declared_nonwear_percent"
      ),
      names_glue = "{placement}_{.value}"
    )
  all_zero_summary <- function(data, placement) {
    by_site <- data |>
      dplyr::group_by(.data$site) |>
      dplyr::summarise(
        complete_before_all_zero_screen = sum(
          .data$day_eligible_without_all_zero_screen
        ),
        all_zero_days_excluded = sum(.data$day_all_zero_medi_excluded),
        .groups = "drop"
      )
    dplyr::bind_rows(
      by_site,
      dplyr::summarise(
        data,
        site = "Overall",
        complete_before_all_zero_screen = sum(
          .data$day_eligible_without_all_zero_screen
        ),
        all_zero_days_excluded = sum(.data$day_all_zero_medi_excluded)
      )
    ) |>
      dplyr::mutate(placement = placement)
  }
  all_zero_wide <- dplyr::bind_rows(
    all_zero_summary(inputs$daily_coverage$near_eye, "near_eye"),
    all_zero_summary(inputs$daily_coverage$chest, "chest")
  ) |>
    tidyr::pivot_wider(
      names_from = "placement",
      values_from = c(
        "complete_before_all_zero_screen", "all_zero_days_excluded"
      ),
      names_glue = "{placement}_{.value}"
    )
  paired <- collection_days |>
    dplyr::filter(.data$placement == "near_eye", .data$paired_day) |>
    dplyr::group_by(.data$site) |>
    dplyr::summarise(
      paired_participants = dplyr::n_distinct(.data$Id),
      paired_participant_days = dplyr::n(),
      .groups = "drop"
    )
  paired <- dplyr::bind_rows(
    paired,
    collection_days |>
      dplyr::filter(.data$placement == "near_eye", .data$paired_day) |>
      dplyr::summarise(
        site = "Overall",
        paired_participants = dplyr::n_distinct(.data$Id),
        paired_participant_days = dplyr::n()
      )
  )
  available_paired <- available_collection_days |>
    dplyr::filter(.data$placement == "near_eye", .data$paired_available) |>
    dplyr::group_by(.data$site) |>
    dplyr::summarise(
      available_paired_participants = dplyr::n_distinct(.data$Id),
      available_paired_participant_days = dplyr::n(),
      .groups = "drop"
    )
  available_paired <- dplyr::bind_rows(
    available_paired,
    available_collection_days |>
      dplyr::filter(.data$placement == "near_eye", .data$paired_available) |>
      dplyr::summarise(
        site = "Overall",
        available_paired_participants = dplyr::n_distinct(.data$Id),
        available_paired_participant_days = dplyr::n()
      )
  )
  result <- dplyr::bind_rows(
    sites,
    data.frame(
      site = "Overall", city = "", country = "",
      location = "All nine sites", latitude_deg = NA_real_,
      longitude_deg = NA_real_, stringsAsFactors = FALSE
    )
  ) |>
    dplyr::left_join(roster, by = "site") |>
    dplyr::left_join(days_wide, by = "site") |>
    dplyr::left_join(available_by_placement, by = "site") |>
    dplyr::left_join(union_wide, by = "site") |>
    dplyr::left_join(coverage_wide, by = "site") |>
    dplyr::left_join(all_zero_wide, by = "site") |>
    dplyr::left_join(paired, by = "site") |>
    dplyr::left_join(available_paired, by = "site") |>
    dplyr::mutate(
      dplyr::across(
        dplyr::matches(
          "participants|days|weekdays|weekends|minutes|complete_before"
        ),
        ~ tidyr::replace_na(.x, 0)
      )
    ) |>
    dplyr::arrange(
      factor(.data$site, levels = c("Overall", descriptive_site_order()))
    )
  result
}

continuous_characteristic_row <- function(
  data,
  variable,
  characteristic,
  section,
  unit,
  transform = identity,
  circular = FALSE,
  analysis_unit = "participant"
) {
  values <- transform(data[[variable]])
  values <- values[is.finite(values)]
  denominator <- nrow(data)
  if (circular) {
    summary <- circular_descriptive_summary(values)
    display <- paste0(
      format_clock_minute(summary[["median"]]), " [",
      format_clock_minute(summary[["q1"]]), ", ",
      format_clock_minute(summary[["q3"]]), "]"
    )
    minimum <- maximum <- NA_real_
  } else {
    summary <- c(
      mean = finite_mean(values),
      q1 = finite_quantile(values, 0.25),
      median = finite_median(values),
      q3 = finite_quantile(values, 0.75),
      resultant = NA_real_
    )
    minimum <- if (length(values)) min(values) else NA_real_
    maximum <- if (length(values)) max(values) else NA_real_
    display <- paste0(
      format_number_compact(summary[["median"]], 3L), " [",
      format_number_compact(summary[["q1"]], 3L), ", ",
      format_number_compact(summary[["q3"]], 3L), "]"
    )
  }
  data.frame(
    section = section,
    characteristic = characteristic,
    level = "",
    analysis_unit = analysis_unit,
    unit = unit,
    n_available = length(values),
    n_denominator = denominator,
    count = NA_integer_,
    percent = NA_real_,
    mean = summary[["mean"]],
    q1 = summary[["q1"]],
    median = summary[["median"]],
    q3 = summary[["q3"]],
    minimum = minimum,
    maximum = maximum,
    circular_resultant = summary[["resultant"]],
    display = display,
    stringsAsFactors = FALSE
  )
}

categorical_characteristic_rows <- function(
  data,
  variable,
  characteristic,
  section,
  analysis_unit = "participant"
) {
  values <- as.character(data[[variable]])
  available <- !is.na(values) & nzchar(values)
  counts <- as.data.frame(table(values[available]), stringsAsFactors = FALSE)
  names(counts) <- c("level", "count")
  denominator <- sum(available)
  if (nrow(counts) == 0L) {
    counts <- data.frame(level = "No available values", count = 0L)
  }
  counts$percent <- if (denominator > 0) {
    100 * counts$count / denominator
  } else {
    NA_real_
  }
  counts$display <- if (denominator > 0) {
    sprintf("%d (%.1f%%)", counts$count, counts$percent)
  } else {
    "Not available"
  }
  counts |>
    dplyr::mutate(
      section = section,
      characteristic = characteristic,
      analysis_unit = analysis_unit,
      unit = "n (%)",
      n_available = denominator,
      n_denominator = denominator,
      mean = NA_real_, q1 = NA_real_, median = NA_real_, q3 = NA_real_,
      minimum = NA_real_, maximum = NA_real_, circular_resultant = NA_real_,
      display = .data$display
    ) |>
    dplyr::select(
      section, characteristic, level, analysis_unit, unit, n_available,
      n_denominator, count, percent, mean, q1, median, q3, minimum, maximum,
      circular_resultant, display
    )
}

build_participant_characteristics <- function(inputs) {
  cohort <- inputs$participant_day$near_eye |>
    dplyr::distinct(site, Id) |>
    dplyr::left_join(
      inputs$demographics |>
        dplyr::select(
          site, Id, age, sex, gender, employment_status
        ),
      by = c("site", "Id")
    ) |>
    dplyr::left_join(
      inputs$chronotype |>
        dplyr::select(
          Id, meq_type, meq, msf_sc, sjl
        ),
      by = "Id"
    ) |>
    dplyr::mutate(
      meq_group = dplyr::case_when(
        grepl("morning", .data$meq_type, ignore.case = TRUE) ~ "Morning type",
        grepl("evening", .data$meq_type, ignore.case = TRUE) ~ "Evening type",
        .data$meq_type == "Intermediate" ~ "Intermediate",
        TRUE ~ NA_character_
      )
    )
  sleep <- inputs$sleepdiaries |>
    dplyr::filter(
      .data$Id %in% cohort$Id,
      .data$sleep_interval_analysis_eligible
    )
  summarise_site <- function(site_name) {
    participant_data <- if (site_name == "Overall") {
      cohort
    } else {
      dplyr::filter(cohort, .data$site == site_name)
    }
    sleep_data <- if (site_name == "Overall") {
      sleep
    } else {
      dplyr::filter(sleep, .data$site == site_name)
    }
    participant_count <- nrow(participant_data)
    rows <- list(
      data.frame(
        section = "Sample", characteristic = "Participants",
        level = "Main near-eye dataset", analysis_unit = "participant",
        unit = "n", n_available = participant_count,
        n_denominator = participant_count, count = participant_count,
        percent = 100, mean = NA_real_, q1 = NA_real_, median = NA_real_,
        q3 = NA_real_, minimum = NA_real_, maximum = NA_real_,
        circular_resultant = NA_real_, display = as.character(participant_count),
        stringsAsFactors = FALSE
      ),
      continuous_characteristic_row(
        participant_data, "age", "Age", "Demographics", "years"
      ),
      categorical_characteristic_rows(
        participant_data, "sex", "Sex", "Demographics"
      ),
      categorical_characteristic_rows(
        participant_data, "gender", "Gender", "Demographics"
      ),
      categorical_characteristic_rows(
        participant_data, "employment_status", "Employment status",
        "Demographics"
      ),
      continuous_characteristic_row(
        participant_data, "meq", "Morningness–Eveningness Questionnaire score",
        "Chronotype", "score"
      ),
      categorical_characteristic_rows(
        participant_data, "meq_group", "Chronotype group", "Chronotype"
      ),
      continuous_characteristic_row(
        participant_data, "msf_sc", "Sleep-corrected midsleep on free days",
        "Chronotype", "clock time",
        transform = function(x) as.numeric(x) / 60,
        circular = TRUE
      ),
      continuous_characteristic_row(
        participant_data, "sjl", "Social jetlag", "Chronotype", "hours",
        transform = function(x) as.numeric(x, units = "hours")
      ),
      data.frame(
        section = "Sleep diary", characteristic = "Participants with eligible sleep diary",
        level = "", analysis_unit = "participant", unit = "n",
        n_available = dplyr::n_distinct(sleep_data$Id),
        n_denominator = participant_count,
        count = dplyr::n_distinct(sleep_data$Id),
        percent = 100 * dplyr::n_distinct(sleep_data$Id) / participant_count,
        mean = NA_real_, q1 = NA_real_, median = NA_real_, q3 = NA_real_,
        minimum = NA_real_, maximum = NA_real_, circular_resultant = NA_real_,
        display = sprintf(
          "%d (%.1f%%)",
          dplyr::n_distinct(sleep_data$Id),
          100 * dplyr::n_distinct(sleep_data$Id) / participant_count
        ),
        stringsAsFactors = FALSE
      ),
      data.frame(
        section = "Sleep diary", characteristic = "Eligible sleep diary records",
        level = "", analysis_unit = "diary record", unit = "n",
        n_available = nrow(sleep_data), n_denominator = nrow(sleep_data),
        count = nrow(sleep_data), percent = 100,
        mean = NA_real_, q1 = NA_real_, median = NA_real_, q3 = NA_real_,
        minimum = NA_real_, maximum = NA_real_, circular_resultant = NA_real_,
        display = as.character(nrow(sleep_data)), stringsAsFactors = FALSE
      ),
      continuous_characteristic_row(
        sleep_data, "sleep_duration", "Sleep duration", "Sleep diary", "hours",
        transform = function(x) as.numeric(x, units = "hours"),
        analysis_unit = "diary record"
      )
    )
    dplyr::bind_rows(rows) |>
      dplyr::mutate(site = site_name, .before = 1L)
  }
  sites <- c("Overall", descriptive_site_order())
  dplyr::bind_rows(lapply(sites, summarise_site))
}

build_metric_values <- function(inputs) {
  registry <- inputs$registry |>
    dplyr::filter(
      .data$analytical_role %in% c("primary_outcome", "descriptive_only")
    ) |>
    dplyr::mutate(
      manuscript_name = dplyr::if_else(
        .data$metric_id == "longest_bout_above_250",
        "Longest period above 250 lx melEDI",
        .data$manuscript_name
      ),
      metric_label = dplyr::if_else(
        .data$manuscript_name == "Mean melEDI",
        paste0(.data$manuscript_name, " — ", .data$variant_label),
        .data$manuscript_name
      ),
      registry_analysis_unit = .data$analysis_unit
    )
  make_long <- function(data, participant, placement) {
    data |>
      dplyr::filter(.data$metric %in% registry$metric_id) |>
      dplyr::rename(metric_id = metric) |>
      dplyr::left_join(
        dplyr::select(participant, Id, underlying_days = days),
        by = "Id"
      ) |>
      dplyr::mutate(
        placement = placement,
        local_date = as.Date(.data$local_date),
        possible = TRUE,
        finite = .data$estimable & is.finite(.data$value)
      ) |>
      dplyr::select(
        placement, site, Id, local_date, analysis_unit, metric_id, value,
        possible, finite, underlying_days
      )
  }
  make_grid <- function(data, placement, metric_id, analysis_unit) {
    data |>
      dplyr::transmute(
        placement = placement,
        site = .data$site,
        Id = .data$Id,
        local_date = as.Date(.data$local_date),
        analysis_unit = analysis_unit,
        metric_id = metric_id,
        value = .data$metric_value_lx,
        possible = TRUE,
        finite = .data$bin_admissible & is.finite(.data$metric_value_lx),
        underlying_days = NA_real_
      )
  }
  values <- dplyr::bind_rows(
    make_long(
      inputs$metrics_long$near_eye,
      inputs$participant$near_eye,
      "near_eye"
    ),
    make_long(
      inputs$metrics_long$chest,
      inputs$participant$chest,
      "chest"
    ),
    make_grid(
      inputs$metrics_30$near_eye,
      "near_eye",
      "thirty_minute_arithmetic_medi",
      "participant-30-minute"
    ),
    make_grid(
      inputs$metrics_30$chest,
      "chest",
      "thirty_minute_arithmetic_medi",
      "participant-30-minute"
    ),
    make_grid(
      inputs$metrics_hour$near_eye,
      "near_eye",
      "one_hour_geometric_mean_medi",
      "participant-hour"
    ),
    make_grid(
      inputs$metrics_hour$chest,
      "chest",
      "one_hour_geometric_mean_medi",
      "participant-hour"
    )
  ) |>
    dplyr::left_join(
      dplyr::select(registry, -dplyr::all_of("analysis_unit")),
      by = "metric_id"
    ) |>
    dplyr::mutate(
      artifact_analysis_unit = .data$analysis_unit,
      analysis_unit = .data$registry_analysis_unit,
      placement_label = placement_reader_label(.data$placement),
      site = factor(.data$site, levels = descriptive_site_order()),
      metric_id = factor(.data$metric_id, levels = registry$metric_id)
    ) |>
    dplyr::arrange(
      factor(.data$placement, levels = c("near_eye", "chest")),
      .data$metric_id, .data$site, .data$Id, .data$local_date
    ) |>
    dplyr::mutate(
      site = as.character(.data$site),
      metric_id = as.character(.data$metric_id)
    )
  values
}

summarise_one_metric_group <- function(data, group_key) {
  finite <- data$finite & is.finite(data$value)
  values <- data$value[finite]
  circular <- identical(group_key$display_unit[[1L]], "clock time")
  if (circular) {
    stats <- circular_descriptive_summary(values)
    stats <- c(
      stats,
      sd = circular_standard_deviation(stats[["resultant"]])
    )
    display_mean <- format_clock_minute(stats[["mean"]])
    display_middle <- paste0(
      format_clock_minute(stats[["median"]]), " [",
      format_clock_minute(stats[["q1"]]), ", ",
      format_clock_minute(stats[["q3"]]), "]"
    )
  } else {
    stats <- c(
      mean = finite_mean(values),
      sd = finite_sd(values),
      q1 = finite_quantile(values, 0.25),
      median = finite_median(values),
      q3 = finite_quantile(values, 0.75),
      resultant = NA_real_
    )
    display_mean <- format_number_compact(stats[["mean"]], 4L)
    display_middle <- paste0(
      format_number_compact(stats[["median"]], 4L), " [",
      format_number_compact(stats[["q1"]], 4L), ", ",
      format_number_compact(stats[["q3"]], 4L), "]"
    )
  }
  analysis_unit <- group_key$analysis_unit[[1L]]
  participant_days <- if (identical(analysis_unit, "participant")) {
    sum(data$underlying_days[finite], na.rm = TRUE)
  } else {
    dplyr::n_distinct(
      paste(
        group_key$site[[1L]], data$Id[finite], data$local_date[finite],
        sep = "|"
      )
    )
  }
  data.frame(
    n_possible_observations = nrow(data),
    n_observations = sum(finite),
    n_participants = dplyr::n_distinct(data$Id[finite]),
    n_participant_days = participant_days,
    mean = stats[["mean"]],
    sd = stats[["sd"]],
    q1 = stats[["q1"]],
    median = stats[["median"]],
    q3 = stats[["q3"]],
    circular_resultant = stats[["resultant"]],
    mean_display = display_mean,
    median_middle_50_display = display_middle,
    stringsAsFactors = FALSE
  )
}

build_metric_summary <- function(metric_values) {
  grouping <- c(
    "placement", "placement_label", "site", "metric_id", "manuscript_name",
    "metric_label", "abbreviation", "manuscript_category", "analysis_unit",
    "display_unit", "analytical_role", "variant_label"
  )
  by_site <- metric_values |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping))) |>
    dplyr::group_modify(~ summarise_one_metric_group(.x, .y)) |>
    dplyr::ungroup()
  overall_values <- metric_values |>
    dplyr::mutate(site = "Overall")
  overall <- overall_values |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping))) |>
    dplyr::group_modify(~ summarise_one_metric_group(.x, .y)) |>
    dplyr::ungroup()
  dplyr::bind_rows(by_site, overall) |>
    dplyr::arrange(
      factor(.data$placement, levels = c("near_eye", "chest")),
      factor(.data$metric_id, levels = unique(metric_values$metric_id)),
      factor(.data$site, levels = c("Overall", descriptive_site_order()))
    )
}

build_metric_plot_values <- function(metric_values) {
  metric_values |>
    dplyr::filter(.data$finite, is.finite(.data$value)) |>
    dplyr::group_by(.data$placement, .data$metric_id, .data$site) |>
    dplyr::arrange(.data$value, .data$Id, .data$local_date, .by_group = TRUE) |>
    dplyr::mutate(
      site_index = match(.data$site, descriptive_site_order()),
      stable_plot_index = vapply(
        paste(.data$Id, .data$local_date, sep = "|"),
        function(key) sum(utf8ToInt(key)),
        integer(1)
      ),
      within_site_offset = ((.data$stable_plot_index %% 11L) - 5L) * 0.035,
      timing_plot_y = .data$site_index + .data$within_site_offset
    ) |>
    dplyr::ungroup()
}

profile_fixed_datetime <- function(clock_minute) {
  as.POSIXct("2025-04-03 00:00:00", tz = "UTC") + 60 * clock_minute
}

profile_aggregation_input <- function(coverage) {
  coverage |>
    dplyr::filter(.data$day_eligible) |>
    dplyr::transmute(
      site = .data$site,
      participant_id = .data$Id,
      participant_day = paste(.data$Id, .data$local_date, sep = "|"),
      Datetime = profile_fixed_datetime(.data$clock_minute),
      MEDI = .data$MEDI_eligible,
      diary_state = .data$State.Brown
    )
}

aggregate_profile_values <- function(data, by_site) {
  grouped <- data |>
    dplyr::select(-"diary_state") |>
    dplyr::group_by(.data$site, .data$participant_id) |>
    dplyr::ungroup("participant_id")
  if (!by_site) {
    grouped <- grouped |>
      dplyr::ungroup("site") |>
      dplyr::select(-"site")
  }
  aggregated <- LightLogR::aggregate_Datetime(
    grouped,
    unit = "15 mins",
    type = "floor",
    numeric.handler = function(value) stats::median(value, na.rm = TRUE),
    value_lower_50_lx = finite_quantile(MEDI, 0.25),
    value_upper_50_lx = finite_quantile(MEDI, 0.75),
    value_lower_67_lx = finite_quantile(MEDI, 0.165),
    value_upper_67_lx = finite_quantile(MEDI, 0.835),
    value_lower_75_lx = finite_quantile(MEDI, 0.125),
    value_upper_75_lx = finite_quantile(MEDI, 0.875),
    value_lower_95_lx = finite_quantile(MEDI, 0.025),
    value_upper_95_lx = finite_quantile(MEDI, 0.975),
    n_participants = dplyr::n_distinct(
      participant_id[is.finite(MEDI)]
    ),
    participant_days_contributing = dplyr::n_distinct(
      participant_day[is.finite(MEDI)]
    ),
    one_minute_observations_contributing = sum(is.finite(MEDI))
  ) |>
    dplyr::ungroup()
  if (!by_site) aggregated$site <- "Overall"
  aggregated |>
    dplyr::transmute(
      site = as.character(.data$site),
      clock_minute = lubridate::hour(.data$Datetime) * 60 +
        lubridate::minute(.data$Datetime),
      median_lx = .data$MEDI,
      value_lower_50_lx = .data$value_lower_50_lx,
      value_upper_50_lx = .data$value_upper_50_lx,
      value_lower_67_lx = .data$value_lower_67_lx,
      value_upper_67_lx = .data$value_upper_67_lx,
      value_lower_75_lx = .data$value_lower_75_lx,
      value_upper_75_lx = .data$value_upper_75_lx,
      value_lower_95_lx = .data$value_lower_95_lx,
      value_upper_95_lx = .data$value_upper_95_lx,
      n_participants = as.integer(.data$n_participants),
      participant_days_contributing = as.integer(
        .data$participant_days_contributing
      ),
      one_minute_observations_contributing = as.integer(
        .data$one_minute_observations_contributing
      )
    )
}

aggregate_profile_states <- function(data, by_site) {
  grouped <- data |>
    dplyr::select(-"MEDI") |>
    dplyr::group_by(.data$site, .data$participant_id) |>
    dplyr::ungroup("participant_id")
  if (!by_site) {
    grouped <- grouped |>
      dplyr::ungroup("site") |>
      dplyr::select(-"site")
  }
  aggregated <- LightLogR::aggregate_Datetime(
    grouped,
    unit = "15 mins",
    type = "floor",
    wake = finite_mean(as.numeric(diary_state == "wake")),
    pre_sleep = finite_mean(as.numeric(diary_state == "pre-sleep")),
    sleep = finite_mean(as.numeric(diary_state == "sleep")),
    n_participants = dplyr::n_distinct(
      participant_id[!is.na(diary_state)]
    ),
    participant_days = dplyr::n_distinct(
      participant_day[!is.na(diary_state)]
    )
  ) |>
    dplyr::ungroup()
  if (!by_site) aggregated$site <- "Overall"
  aggregated |>
    dplyr::transmute(
      site = as.character(.data$site),
      clock_minute = lubridate::hour(.data$Datetime) * 60 +
        lubridate::minute(.data$Datetime),
      wake = .data$wake,
      pre_sleep = .data$pre_sleep,
      sleep = .data$sleep,
      n_participants = as.integer(.data$n_participants),
      participant_days = as.integer(.data$participant_days)
    )
}

build_aggregated_profile_sources <- function(coverage, placement) {
  input <- profile_aggregation_input(coverage)
  profile <- dplyr::bind_rows(
    aggregate_profile_values(input, by_site = TRUE),
    aggregate_profile_values(input, by_site = FALSE)
  ) |>
    dplyr::mutate(
      placement = placement,
      placement_label = placement_reader_label(placement),
      interval_levels = "0.50;0.67;0.75;0.95",
      aggregation_minutes = 15L,
      aggregation_method = paste(
        "LightLogR::aggregate_Datetime with type = floor after removing",
        "participant grouping; numeric handler = median with na.rm = TRUE."
      ),
      uncertainty_definition = paste(
        "Pointwise central 50%, 67%, 75%, and 95% value intervals across",
        "eligible one-minute melEDI values in each 15-minute bin."
      ),
      .before = 1L
    )

  state_columns <- c(
    wake = "Daytime (wake)",
    pre_sleep = "Pre-sleep",
    sleep = "Sleep"
  )
  state_colours <- c(
    wake = "#0072B2", pre_sleep = "#E69F00", sleep = "#D73027"
  )
  band_geometry <- data.frame(
    context = names(state_columns),
    context_label = unname(state_columns),
    band_index = c(3, 2, 1),
    stringsAsFactors = FALSE
  ) |>
    dplyr::mutate(
      ymin = .data$band_index - 0.42,
      ymax = .data$band_index + 0.42
    )
  state <- dplyr::bind_rows(
    aggregate_profile_states(input, by_site = TRUE),
    aggregate_profile_states(input, by_site = FALSE)
  ) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(names(state_columns)),
      names_to = "context",
      values_to = "fraction"
    ) |>
    dplyr::left_join(band_geometry, by = "context") |>
    dplyr::mutate(
      placement = placement,
      placement_label = placement_reader_label(placement),
      base_colour = unname(state_colours[.data$context]),
      fill_colour = blend_with_white(.data$base_colour, .data$fraction),
      xmin = .data$clock_minute - 7.5,
      xmax = .data$clock_minute + 7.5,
      alpha = 1,
      aggregation_minutes = 15L,
      .before = 1L
    )
  list(profile = profile, state = state)
}

mean_profile_periods <- function(daily_clock, placement, bin_minutes = 1L) {
  daily_periods <- daily_clock |>
    dplyr::group_by(.data$site, .data$Id, .data$local_date) |>
    dplyr::summarise(
      sleep_start_minute = {
        candidates <- .data$clock_minute[
          .data$sleep > 0 & .data$clock_minute >= 720
        ]
        if (length(candidates)) min(candidates) else NA_real_
      },
      sleep_end_minute = {
        candidates <- .data$clock_minute[
          .data$sleep > 0 & .data$clock_minute < 720
        ]
        if (length(candidates)) max(candidates) + bin_minutes else NA_real_
      },
      civil_dawn_wall_minute = dplyr::first(.data$civil_dawn_wall_minute),
      civil_dusk_wall_minute = dplyr::first(.data$civil_dusk_wall_minute),
      .groups = "drop"
    )
  participant_periods <- daily_periods |>
    dplyr::group_by(.data$site, .data$Id) |>
    dplyr::summarise(
      sleep_start_minute = finite_mean(.data$sleep_start_minute),
      sleep_end_minute = finite_mean(.data$sleep_end_minute),
      civil_dawn_wall_minute = finite_mean(.data$civil_dawn_wall_minute),
      civil_dusk_wall_minute = finite_mean(.data$civil_dusk_wall_minute),
      n_days = dplyr::n(),
      .groups = "drop"
    )
  expanded <- dplyr::bind_rows(
    participant_periods |>
      dplyr::rename(profile_site = site),
    participant_periods |>
      dplyr::mutate(profile_site = "Overall")
  )
  expanded |>
    dplyr::group_by(.data$profile_site) |>
    dplyr::summarise(
      mean_sleep_start_minute = round(
        finite_mean(.data$sleep_start_minute) / 15
      ) * 15,
      mean_sleep_end_minute = round(
        finite_mean(.data$sleep_end_minute) / 15
      ) * 15,
      mean_civil_dawn_minute = round(
        finite_mean(.data$civil_dawn_wall_minute) / 15
      ) * 15,
      mean_civil_dusk_minute = round(
        finite_mean(.data$civil_dusk_wall_minute) / 15
      ) * 15,
      n_participants = dplyr::n_distinct(.data$Id),
      participant_days = sum(.data$n_days),
      .groups = "drop"
    ) |>
    dplyr::rename(site = profile_site) |>
    dplyr::mutate(
      placement = placement,
      placement_label = placement_reader_label(placement),
      aggregation_minutes = 15L,
      period_definition = paste(
        "Participant-balanced means of daily diary sleep onset/wake and",
        "verified civil dawn/dusk, rounded to the nearest 15 minutes."
      ),
      .before = 1L
    )
}

build_profile_sources_one_placement <- function(coverage, solar, placement) {
  solar_small <- solar |>
    dplyr::select(
      site, local_date, civil_dawn_wall_minute, civil_dusk_wall_minute
    )
  daily_clock <- coverage |>
    dplyr::filter(.data$day_eligible) |>
    dplyr::select(
      site, Id, local_date, clock_minute, State.Brown
    ) |>
    dplyr::left_join(solar_small, by = c("site", "local_date")) |>
    dplyr::mutate(sleep = .data$State.Brown == "sleep")
  if (anyNA(daily_clock$civil_dawn_wall_minute)) {
    stop("A profile day lacks verified dawn/dusk context", call. = FALSE)
  }
  profile_sources <- build_aggregated_profile_sources(coverage, placement)
  profile_sources$period <- mean_profile_periods(
    daily_clock, placement, bin_minutes = 1L
  )
  profile_sources
}

build_profile_sources <- function(inputs) {
  near_eye <- build_profile_sources_one_placement(
    inputs$coverage$near_eye, inputs$solar, "near_eye"
  )
  chest <- build_profile_sources_one_placement(
    inputs$coverage$chest, inputs$solar, "chest"
  )
  list(
    profile = dplyr::bind_rows(near_eye$profile, chest$profile) |>
      dplyr::arrange(
        factor(.data$placement, levels = c("near_eye", "chest")),
        factor(.data$site, levels = c("Overall", descriptive_site_order())),
        .data$clock_minute
      ),
    state = dplyr::bind_rows(near_eye$state, chest$state) |>
      dplyr::arrange(
        factor(.data$placement, levels = c("near_eye", "chest")),
        factor(.data$site, levels = c("Overall", descriptive_site_order())),
        .data$band_index,
        .data$clock_minute
      ),
    period = dplyr::bind_rows(near_eye$period, chest$period) |>
      dplyr::arrange(
        factor(.data$placement, levels = c("near_eye", "chest")),
        factor(.data$site, levels = c("Overall", descriptive_site_order()))
      )
  )
}

recommendation_period_contract <- function() {
  data.frame(
    brown_state = c("wake", "pre-sleep", "sleep"),
    period = c(
      "Wake (excluding the three hours before sleep)",
      "Three hours before sleep",
      "Diary sleep window"
    ),
    comparator = c(">=", "<=", "<="),
    threshold_lx = c(250, 10, 1),
    measurement_interpretation = c(
      "Near-eye waking measurement",
      "Near-eye pre-sleep measurement",
      "Bedside sleep-environment measurement; not ocular exposure"
    ),
    stringsAsFactors = FALSE
  )
}

build_recommendation_context <- function(inputs) {
  contract <- recommendation_period_contract()
  minute_data <- inputs$coverage$near_eye |>
    dplyr::filter(.data$day_eligible) |>
    dplyr::transmute(
      site = .data$site,
      Id = .data$Id,
      local_date = as.Date(.data$local_date),
      brown_state = .data$State.Brown,
      value = .data$MEDI_eligible,
      valid = is.finite(.data$MEDI_eligible)
    ) |>
    dplyr::left_join(contract, by = "brown_state") |>
    dplyr::mutate(
      in_contextual_range = dplyr::case_when(
        .data$brown_state == "wake" & .data$valid ~ .data$value >= 250,
        .data$brown_state == "pre-sleep" & .data$valid ~ .data$value <= 10,
        .data$brown_state == "sleep" & .data$valid ~ .data$value <= 1,
        TRUE ~ NA
      )
    )
  all_day_minutes <- inputs$coverage$near_eye |>
    dplyr::filter(.data$day_eligible) |>
    dplyr::count(.data$site, .data$Id, .data$local_date, name = "all_real_minutes")
  observed_day_state <- minute_data |>
    dplyr::filter(.data$brown_state %in% contract$brown_state) |>
    dplyr::group_by(
      .data$site, .data$Id, .data$local_date, .data$brown_state,
      .data$period, .data$comparator, .data$threshold_lx,
      .data$measurement_interpretation
    ) |>
    dplyr::summarise(
      state_real_minutes = dplyr::n(),
      valid_one_minute_observations = sum(.data$valid),
      minutes_in_contextual_range = sum(
        .data$in_contextual_range, na.rm = TRUE
      ),
      .groups = "drop"
    )
  day_state <- merge(
    all_day_minutes,
    contract,
    by = NULL,
    sort = FALSE
  ) |>
    dplyr::left_join(
      observed_day_state,
      by = c(
        "site", "Id", "local_date", "brown_state", "period",
        "comparator", "threshold_lx", "measurement_interpretation"
      )
    ) |>
    dplyr::mutate(
      dplyr::across(
        c(
          state_real_minutes,
          valid_one_minute_observations,
          minutes_in_contextual_range
        ),
        ~ tidyr::replace_na(.x, 0)
      ),
      participant_day_fraction = dplyr::if_else(
        .data$valid_one_minute_observations > 0,
        .data$minutes_in_contextual_range /
          .data$valid_one_minute_observations,
        NA_real_
      )
    )
  grouping <- c(
    "site", "brown_state", "period", "comparator", "threshold_lx",
    "measurement_interpretation"
  )
  summarise_context <- function(data) {
    data |>
      dplyr::group_by(dplyr::across(dplyr::all_of(grouping))) |>
      dplyr::summarise(
        n_participants = dplyr::n_distinct(.data$Id),
        n_participant_days = dplyr::n(),
        n_participant_days_with_valid_minutes = sum(
          .data$valid_one_minute_observations > 0
        ),
        n_state_real_minutes = sum(.data$state_real_minutes),
        n_valid_one_minute_observations = sum(
          .data$valid_one_minute_observations
        ),
        n_minutes_in_contextual_range = sum(
          .data$minutes_in_contextual_range
        ),
        n_all_eligible_real_minutes = sum(.data$all_real_minutes),
        pooled_fraction_in_contextual_range =
          .data$n_minutes_in_contextual_range /
          .data$n_valid_one_minute_observations,
        state_fraction_of_eligible_minutes =
          .data$n_state_real_minutes / .data$n_all_eligible_real_minutes,
        participant_day_q1 = finite_quantile(
          .data$participant_day_fraction, 0.25
        ),
        participant_day_median = finite_median(
          .data$participant_day_fraction
        ),
        participant_day_q3 = finite_quantile(
          .data$participant_day_fraction, 0.75
        ),
        .groups = "drop"
      )
  }
  by_site <- summarise_context(day_state)
  overall <- summarise_context(dplyr::mutate(day_state, site = "Overall"))
  dplyr::bind_rows(by_site, overall) |>
    dplyr::mutate(
      placement = "near_eye",
      placement_label = "Near-eye (primary)",
      comparison_type = paste(
        "Contextual comparison with Brown et al. (2022); these fractions",
        "are not adherence or compliance estimates. Inclusive operational",
        "boundaries follow the approved analysis brief."
      ),
      .before = 1L
    ) |>
    dplyr::arrange(
      factor(.data$site, levels = c("Overall", descriptive_site_order())),
      match(.data$brown_state, contract$brown_state)
    )
}

build_time_series_sources <- function(inputs) {
  selected <- inputs$selected_showcase |>
    dplyr::left_join(
      inputs$participant_day$near_eye |>
        dplyr::select(
          site, participant = Id, local_date, duration_above_250_wake_h
        ),
      by = c("site", "participant", "local_date")
    ) |>
    dplyr::filter(is.finite(.data$duration_above_250_wake_h)) |>
    dplyr::arrange(
      dplyr::desc(.data$duration_above_250_wake_h),
      match(.data$site, descriptive_site_order())
    ) |>
    dplyr::slice(1L)
  series <- inputs$showcase |>
    dplyr::filter(
      .data$site == selected$site[[1L]],
      .data$participant == selected$participant[[1L]],
      as.Date(.data$local_date) == as.Date(selected$local_date[[1L]])
    ) |>
    dplyr::mutate(
      local_date = as.Date(.data$local_date),
      source_resolution = "one-minute",
      selection_rule = paste(
        "Among the nine fixed prepared-day showcase selections, choose the",
        "day with the largest finite verified time above 250 lx melEDI during",
        "wake; ties follow the fixed site order. Showcase seed: 20260730."
      )
    )
  if (nrow(series) != 1440L) {
    stop("The selected showcase day must contain 1,440 wall-clock minutes", call. = FALSE)
  }
  metrics <- inputs$participant_day$near_eye |>
    dplyr::filter(
      .data$site == selected$site[[1L]],
      .data$Id == selected$participant[[1L]],
      as.Date(.data$local_date) == as.Date(selected$local_date[[1L]])
    )
  if (nrow(metrics) != 1L) {
    stop("The showcase day did not match one verified metric row", call. = FALSE)
  }
  annotation_spec <- data.frame(
    metric_id = c(
      "daily_geometric_mean_medi", "m10_mean_medi", "m10_midpoint",
      "l10_mean_medi", "l10_midpoint", "duration_above_250_wake",
      "longest_bout_above_250", "first_timing_above_250",
      "last_timing_above_250", "dose_time_sensitive_corrected_medi",
      "mder_ratio_of_integrals"
    ),
    source_column = c(
      "daily_geometric_mean_medi_lx", "m10_mean_medi_lx",
      "m10_midpoint_clock_minute", "l10_mean_medi_lx",
      "l10_midpoint_clock_minute", "duration_above_250_wake_h",
      "longest_bout_above_250_h", "first_timing_above_250_clock_minute",
      "last_timing_above_250_clock_minute", "dose_corrected_medi_lx_h",
      "mder"
    ),
    stringsAsFactors = FALSE
  )
  annotations <- annotation_spec |>
    dplyr::mutate(
      value = vapply(
        .data$source_column,
        function(column) as.numeric(metrics[[column]][[1L]]),
        numeric(1)
      )
    ) |>
    dplyr::left_join(inputs$registry, by = "metric_id") |>
    dplyr::mutate(
      manuscript_name = dplyr::if_else(
        .data$metric_id == "longest_bout_above_250",
        "Longest period above 250 lx melEDI",
        .data$manuscript_name
      ),
      site = selected$site[[1L]],
      participant = selected$participant[[1L]],
      local_date = as.Date(selected$local_date[[1L]]),
      provenance = "Verified participant-day metric artifact",
      .before = 1L
    )
  list(series = series, annotations = annotations)
}

build_latitude_photoperiod_source <- function(collection_days) {
  collection_days |>
    dplyr::filter(.data$placement == "near_eye") |>
    dplyr::arrange(
      factor(.data$site, levels = descriptive_site_order()),
      .data$local_date, .data$Id
    ) |>
    dplyr::group_by(.data$site) |>
    dplyr::mutate(
      absolute_latitude_deg = abs(.data$latitude_deg),
      deterministic_plot_offset_deg =
        ((dplyr::row_number() - 1L) %% 17L - 8L) * 0.025,
      plot_latitude_deg = .data$absolute_latitude_deg +
        .data$deterministic_plot_offset_deg
    ) |>
    dplyr::ungroup() |>
    dplyr::select(
      site, location, Id, local_date, photoperiod_hours,
      absolute_latitude_deg, deterministic_plot_offset_deg, plot_latitude_deg
    )
}

build_collection_date_counts <- function(collection_days) {
  collection_days |>
    dplyr::distinct(
      .data$site, .data$Id, .data$local_date, .keep_all = TRUE
    ) |>
    dplyr::group_by(.data$site, .data$local_date) |>
    dplyr::summarise(
      participant_days = dplyr::n(),
      participants = dplyr::n_distinct(.data$Id),
      photoperiod_hours = finite_median(.data$photoperiod_hours),
      .groups = "drop"
    )
}

build_collection_intervals <- function(collection_days, pause_days = 6L) {
  if (!is.numeric(pause_days) || length(pause_days) != 1L || pause_days < 1) {
    stop("pause_days must be one positive number", call. = FALSE)
  }
  collection_days |>
    dplyr::distinct(.data$site, .data$local_date) |>
    dplyr::mutate(local_date = as.Date(.data$local_date)) |>
    dplyr::arrange(
      factor(.data$site, levels = descriptive_site_order()),
      .data$local_date
    ) |>
    dplyr::group_by(.data$site) |>
    dplyr::mutate(
      previous_collection_date = dplyr::lag(.data$local_date),
      missing_days_before = pmax(
        0L,
        as.integer(.data$local_date - .data$previous_collection_date) - 1L
      ),
      starts_new_interval = dplyr::row_number() == 1L |
        .data$missing_days_before >= pause_days,
      interval_id = cumsum(.data$starts_new_interval)
    ) |>
    dplyr::group_by(.data$site, .data$interval_id) |>
    dplyr::summarise(
      interval_start = min(.data$local_date),
      interval_end = max(.data$local_date),
      collection_dates = dplyr::n(),
      interruption_rule = paste0(
        "New interval after at least ", pause_days,
        " consecutive dates without any available site data"
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      factor(.data$site, levels = descriptive_site_order()),
      .data$interval_start
    )
}

build_protocol_flow <- function(inputs, collection_days) {
  eligibility <- data.frame(
    placement = c("near_eye", "chest"),
    before_screen = c(
      sum(inputs$daily_coverage$near_eye$day_eligible_without_all_zero_screen),
      sum(inputs$daily_coverage$chest$day_eligible_without_all_zero_screen)
    ),
    excluded_all_zero = c(
      sum(inputs$daily_coverage$near_eye$day_all_zero_medi_excluded),
      sum(inputs$daily_coverage$chest$day_all_zero_medi_excluded)
    ),
    stringsAsFactors = FALSE
  )
  nodes <- data.frame(
    node_id = c(
      "roster", "near_complete", "chest_complete", "near_main",
      "chest_main", "paired"
    ),
    x = c(1, 2, 2, 3, 3, 4),
    y = c(1.5, 2.25, 0.75, 2.25, 0.75, 1.5),
    label = c(
      sprintf(
        "Available participant metadata\n%d participants",
        dplyr::n_distinct(inputs$demographics$Id)
      ),
      sprintf(
        "At least 80%% of 24 h\n%d near-eye days",
        eligibility$before_screen[eligibility$placement == "near_eye"]
      ),
      sprintf(
        "At least 80%% of 24 h\n%d chest days",
        eligibility$before_screen[eligibility$placement == "chest"]
      ),
      sprintf(
        "Main near-eye dataset\n141 participants • 816 days\n%d all-zero days excluded",
        eligibility$excluded_all_zero[eligibility$placement == "near_eye"]
      ),
      sprintf(
        "Complementary chest dataset\n154 participants • 902 days\n%d all-zero days excluded",
        eligibility$excluded_all_zero[eligibility$placement == "chest"]
      ),
      "Paired subset\n112 participants • 643 paired days"
    ),
    placement = c(
      "not_applicable", "near_eye", "chest", "near_eye", "chest", "paired"
    ),
    row_type = "node",
    xend = NA_real_,
    yend = NA_real_,
    stringsAsFactors = FALSE
  )
  edges <- data.frame(
    node_id = c("edge_1", "edge_2", "edge_3", "edge_4", "edge_5", "edge_6"),
    x = c(1.25, 1.25, 2.25, 2.25, 3.25, 3.25),
    y = c(1.5, 1.5, 2.25, 0.75, 2.25, 0.75),
    label = "",
    placement = c("near_eye", "chest", "near_eye", "chest", "paired", "paired"),
    row_type = "edge",
    xend = c(1.75, 1.75, 2.75, 2.75, 3.75, 3.75),
    yend = c(2.25, 0.75, 2.25, 0.75, 1.5, 1.5),
    stringsAsFactors = FALSE
  )
  dplyr::bind_rows(nodes, edges)
}

build_site_location_source <- function(inputs) {
  offsets <- data.frame(
    site = c("RISE", "THUAS", "BAUA", "MPI", "TUM", "FUSPCEU", "IZTECH", "UCR", "KNUST"),
    label_longitude = c(42, -75, -55, 42, 80, -55, 55, -125, 20),
    label_latitude = c(68, 50, 63, 56, 44, 35, 31, 18, -5),
    stringsAsFactors = FALSE
  )
  inputs$solar |>
    dplyr::distinct(
      .data$site, .data$city, .data$country, .data$location,
      .data$latitude_deg, .data$longitude_deg,
      .data$coordinate_source, .data$coordinate_source_version
    ) |>
    dplyr::left_join(offsets, by = "site") |>
    dplyr::arrange(match(.data$site, descriptive_site_order()))
}

build_world_map_source <- function() {
  world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")
  data.frame(
    region = world$admin,
    iso_a3 = world$iso_a3,
    wkt = sf::st_as_text(sf::st_geometry(world)),
    stringsAsFactors = FALSE
  )
}

build_figure_alt_text <- function(
  site_sample,
  metric_summary,
  time_series,
  latitude_source
) {
  overall <- dplyr::filter(site_sample, .data$site == "Overall")
  selected <- time_series$series[1L, ]
  data.frame(
    figure_id = c(
      "descriptive_overview", "near_eye_site_profiles",
      "chest_site_profiles", "near_eye_metric_distributions_level",
      "near_eye_metric_distributions_duration",
      "near_eye_metric_distributions_timing",
      "near_eye_metric_distributions_exposure_history",
      "near_eye_metric_distributions_other", "time_series_to_metrics",
      "latitude_photoperiod_diagnostic"
    ),
    short_alt = c(
      paste0(
        "Study overview showing the participant-day flow, nine study sites, ",
        "collection dates and photoperiod, and the pooled ",
        "near-eye 24-hour melEDI profile."
      ),
      paste0(
        "Nine site-specific pooled 15-minute near-eye 24-hour ",
        "melEDI profiles with nested central 50%, 75%, and 95% value bands."
      ),
      paste0(
        "Eight site-specific pooled complementary 15-minute ",
        "chest 24-hour melEDI profiles with nested central 50%, 75%, and 95% value bands."
      ),
      "Near-eye distributions by site for five level-based melEDI metrics.",
      "Near-eye distributions by site for six duration-based melEDI metrics.",
      paste0(
        "Near-eye clock-time observations by site for five timing-based ",
        "melEDI metrics; the axis wraps at midnight."
      ),
      paste(
        "Near-eye melEDI dose distributions by site on a symlog axis",
        "(base 10; threshold 1)."
      ),
      paste0(
        "Near-eye distributions by site for MDER, interdaily stability, and ",
        "intradaily variability."
      ),
      paste0(
        "One deterministic near-eye day for ", selected$participant,
        " at ", selected$site, " with diary periods, civil daylight, ",
        "threshold guides, and verified daily metric annotations."
      ),
      paste0(
        "Supplemental scatterplot of photoperiod against absolute latitude ",
        "for 816 main near-eye participant-days across nine sites."
      )
    ),
    long_description = c(
      paste0(
        "The flow panel separates near-eye and chest measurements. The main ",
        "near-eye dataset contains ", overall$near_eye_participants,
        " participants and ", overall$near_eye_participant_days,
        " participant-days; the complementary chest dataset contains ",
        overall$chest_participants, " participants and ",
        overall$chest_participant_days, " participant-days; ",
        overall$paired_participant_days, " days are paired. The map locates ",
        "nine sites. Collection-date bubbles encode participant-day counts ",
        "and verified civil photoperiod. The profile line is the pooled median ",
        "after 15-minute LightLogR aggregation, with a pointwise central 67% ",
        "value interval. Separate strips show average diary sleep and average ",
        "civil night; declared non-wear is omitted."
      ),
      paste0(
        "Each panel is one site. Eligible one-minute values are pooled after ",
        "removing participant grouping and aggregated to 15-minute bins. ",
        "The dark line is the median and the nested bands are pointwise ",
        "central 50%, 75%, and 95% value intervals. The y-axis is capped ",
        paste0(
          "at the verified 100,000 lx melEDI boundary and shown on a symlog ",
          "scale (base 10; threshold 1)."
        )
      ),
      paste0(
        "Each panel is one chest site; MPI has no chest measurement and is not ",
        "shown. The line and value band use the same pooled LightLogR ",
        "procedure as the near-eye profile. Chest measurements are presented as ",
        "complementary and are not pooled with near-eye measurements."
      ),
      paste(
        "Violin shapes show the full finite analysis-unit distributions by",
        "labelled site; inset white boxes show the median and middle 50%.",
        "A symlog axis (base 10; threshold 1) retains zero while",
        "accommodating skewed levels."
      ),
      "Violin shapes show participant-day duration distributions by labelled site; inset white boxes show the median and middle 50%. Values come from verified metric artifacts and no metric is recalculated.",
      "Each small point is a finite participant-day clock-time observation placed on a 00:00–24:00 axis. Points have deterministic vertical offsets only to reduce overplotting. Midnight is both the left and right boundary, so no linear boxplot is used.",
      paste(
        "Site-labelled violins and boxes summarize the verified corrected",
        "participant-day melEDI dose. A symlog axis (base 10; threshold 1)",
        "retains zero while showing the strongly right-skewed distribution",
        "without hiding high observations."
      ),
      "Site-labelled violins and boxes summarize verified participant-day MDER and participant-level interdaily stability and intradaily variability. Each panel has its own numeric scale and states its analysis unit.",
      paste0(
        "The upper panel shows all 1,440 prepared wall-clock minutes on ",
        selected$local_date, ". Opaque strips identify wake, the three hours ",
        "before sleep, sleep, unavailable minutes, and declared non-wear; a ",
        "translucent rectangle marks civil daylight. The lower panel lists ",
        "metric values joined from the verified participant-day artifact."
      ),
      paste0(
        "Each point is one of ", nrow(latitude_source),
        " near-eye participant-days. Small deterministic vertical offsets ",
        "prevent exact overlap at a site's fixed latitude. Site medians and ",
        "middle 50% photoperiod ranges are overlaid; no theoretical photoperiod ",
        "surface is recalculated."
      )
    ),
    stringsAsFactors = FALSE
  )
}
