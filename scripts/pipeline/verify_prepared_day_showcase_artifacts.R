# Independently verify the one-participant-day-per-site display.
#
# Source paths_io.R before this file. This verifier deliberately does not
# source or call the display producer.

prepared_day_showcase_verifier_paths <- function(root) {
  paths <- pipeline_paths(root)
  diagnostic_root <- file.path(
    paths$diagnostics,
    "prepared_day_showcase"
  )
  list(
    coverage = file.path(paths$coverage, "light_glasses_coverage.rds"),
    solar_context = file.path(
      paths$model_data,
      "context",
      "site_solar_context.rds"
    ),
    site_metadata = file.path(root, "config", "site_metadata.csv"),
    selected_days = file.path(diagnostic_root, "selected_days.csv"),
    eligible_day_counts = file.path(
      diagnostic_root,
      "eligible_day_counts.csv"
    ),
    settings = file.path(diagnostic_root, "selection_settings.csv"),
    source_data = file.path(
      paths$source_data,
      "prepared_day_showcase.csv"
    ),
    figure_png = file.path(
      paths$figures,
      "prepared_day_showcase.png"
    ),
    figure_svg = file.path(
      paths$figures,
      "prepared_day_showcase.svg"
    ),
    manifest = file.path(
      paths$manifests,
      "prepared_day_showcase_artifacts.csv"
    )
  )
}

prepared_day_showcase_expected_artifacts <- function() {
  c(
    selected_days_csv = "selected_days",
    eligible_day_counts_csv = "eligible_day_counts",
    selection_settings_csv = "settings",
    plot_source_data_csv = "source_data",
    figure_png = "figure_png",
    figure_svg = "figure_svg"
  )
}

prepared_day_showcase_verifier_result <- function(checks) {
  failures <- checks[checks$status != "PASS", , drop = FALSE]
  list(
    status = if (nrow(failures) == 0L) "PASS" else "FAIL",
    checks = checks,
    failures = failures
  )
}

prepared_day_showcase_numeric_equal <- function(
  observed,
  expected,
  tolerance = 1e-10
) {
  if (length(observed) != length(expected)) {
    return(FALSE)
  }
  same_missing <- is.na(observed) == is.na(expected)
  finite <- is.finite(observed) & is.finite(expected)
  all(same_missing) &&
    all(abs(observed[finite] - expected[finite]) <= tolerance) &&
    all(
      observed[!finite & !is.na(observed)] ==
        expected[!finite & !is.na(expected)]
    )
}

prepared_day_showcase_verifier_candidates <- function(coverage) {
  coverage |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$local_date,
      .data$clock_minute
    ) |>
    dplyr::group_by(.data$site, .data$Id, .data$local_date) |>
    dplyr::summarise(
      minute_rows = dplyr::n(),
      distinct_clock_minutes = dplyr::n_distinct(.data$clock_minute),
      day_eligible = all(.data$day_eligible %in% TRUE),
      sleep_preparation_transitions = sum(
        dplyr::lag(.data$State.Brown) == "pre-sleep" &
          .data$State.Brown == "sleep",
        na.rm = TRUE
      ),
      wake_transitions = sum(
        dplyr::lag(.data$State.Brown) == "sleep" &
          .data$State.Brown == "wake",
        na.rm = TRUE
      ),
      complete_sleep_interval = any(
        .data$State.Brown == "sleep" &
          !is.na(.data$sleep_source_row_start) &
          !is.na(.data$sleep_source_row_end)
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(
      .data$minute_rows == 1440L,
      .data$distinct_clock_minutes == 1440L,
      .data$day_eligible,
      .data$sleep_preparation_transitions == 1L,
      .data$wake_transitions == 1L,
      .data$complete_sleep_interval
    ) |>
    dplyr::arrange(.data$site, .data$Id, .data$local_date)
}

prepared_day_showcase_verifier_selection <- function(
  candidates,
  seed
) {
  pools <- split(candidates, candidates$site, drop = TRUE)
  pools <- pools[sort(names(pools))]
  previous_rng <- RNGkind()
  on.exit(do.call(RNGkind, as.list(previous_rng)), add = TRUE)
  set.seed(
    as.integer(seed),
    kind = "Mersenne-Twister",
    normal.kind = "Inversion",
    sample.kind = "Rejection"
  )
  dplyr::bind_rows(lapply(
    pools,
    function(pool) pool[sample.int(nrow(pool), 1L), , drop = FALSE]
  )) |>
    dplyr::arrange(.data$site)
}

verify_prepared_day_showcase_artifacts <- function(
  root = project_root(),
  expected_seed = 20260730L
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  paths <- prepared_day_showcase_verifier_paths(root)
  checks <- data.frame(
    check_id = character(),
    status = character(),
    details = character(),
    stringsAsFactors = FALSE
  )
  add_check <- function(check_id, passed, details) {
    checks <<- rbind(
      checks,
      data.frame(
        check_id = check_id,
        status = if (isTRUE(passed)) "PASS" else "FAIL",
        details = as.character(details),
        stringsAsFactors = FALSE
      )
    )
  }

  required_paths <- unlist(paths, use.names = FALSE)
  present <- file.exists(required_paths)
  add_check(
    "files::all_required",
    all(present),
    if (all(present)) {
      sprintf("All %d required files are present.", length(required_paths))
    } else {
      paste("Missing:", paste(required_paths[!present], collapse = ", "))
    }
  )
  if (!all(present)) {
    return(prepared_day_showcase_verifier_result(checks))
  }

  manifest <- utils::read.csv(
    paths$manifest,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  expected_artifacts <- prepared_day_showcase_expected_artifacts()
  manifest_types_ok <-
    nrow(manifest) == length(expected_artifacts) &&
    !anyDuplicated(manifest$artifact_type) &&
    setequal(manifest$artifact_type, names(expected_artifacts))
  add_check(
    "manifest::artifact_set",
    manifest_types_ok,
    "The manifest must list each table, source-data file, and figure once."
  )
  if (!manifest_types_ok) {
    return(prepared_day_showcase_verifier_result(checks))
  }

  manifest <- manifest[
    match(names(expected_artifacts), manifest$artifact_type),
    ,
    drop = FALSE
  ]
  expected_relative_paths <- vapply(
    expected_artifacts,
    function(path_name) {
      full_path <- normalizePath(
        paths[[path_name]],
        winslash = "/",
        mustWork = TRUE
      )
      substring(full_path, nchar(root) + 2L)
    },
    character(1)
  )
  add_check(
    "manifest::paths",
    identical(unname(manifest$path), unname(expected_relative_paths)),
    "Manifest paths match the six expected project-relative files."
  )

  actual_paths <- file.path(root, manifest$path)
  actual_hashes <- vapply(
    actual_paths,
    artifact_sha256,
    character(1)
  )
  actual_bytes <- unname(file.info(actual_paths)$size)
  add_check(
    "manifest::file_hashes",
    identical(unname(manifest$sha256), unname(actual_hashes)),
    "Every listed SHA-256 checksum matches the file on disk."
  )
  add_check(
    "manifest::file_sizes",
    identical(as.numeric(manifest$bytes), as.numeric(actual_bytes)),
    "Every listed byte count matches the file on disk."
  )
  add_check(
    "manifest::seed",
    all(as.integer(manifest$seed) == as.integer(expected_seed)),
    sprintf("Every artifact records selection seed %d.", expected_seed)
  )

  input_hashes <- c(
    coverage_input_sha256 = artifact_sha256(paths$coverage),
    solar_context_input_sha256 = artifact_sha256(paths$solar_context),
    site_metadata_input_sha256 = artifact_sha256(paths$site_metadata)
  )
  input_hashes_ok <- all(vapply(
    names(input_hashes),
    function(column) {
      all(manifest[[column]] == input_hashes[[column]])
    },
    logical(1)
  ))
  add_check(
    "manifest::input_hashes",
    input_hashes_ok,
    "The manifest identifies the exact prepared, solar, and site files used."
  )

  selected <- readr::read_csv(
    paths$selected_days,
    show_col_types = FALSE,
    progress = FALSE
  )
  eligible <- readr::read_csv(
    paths$eligible_day_counts,
    show_col_types = FALSE,
    progress = FALSE
  )
  settings <- readr::read_csv(
    paths$settings,
    show_col_types = FALSE,
    progress = FALSE
  )
  source_data <- readr::read_csv(
    paths$source_data,
    col_types = readr::cols(
      datetime_utc = readr::col_character(),
      datetime_wall = readr::col_character(),
      local_date = readr::col_date()
    ),
    show_col_types = FALSE,
    progress = FALSE
  )
  selected$local_date <- as.Date(selected$local_date)
  source_data$local_date <- as.Date(source_data$local_date)
  coverage <- readRDS(paths$coverage)
  solar_context <- readRDS(paths$solar_context)
  site_metadata <- utils::read.csv(
    paths$site_metadata,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fileEncoding = "UTF-8"
  )
  expected_sites <- sort(unique(site_metadata$site))

  selected_keys <- selected |>
    dplyr::transmute(
      .data$site,
      Id = .data$participant,
      .data$local_date
    ) |>
    dplyr::arrange(.data$site)
  add_check(
    "selection::one_day_per_site",
    nrow(selected) == length(expected_sites) &&
      !anyDuplicated(selected$site) &&
      identical(sort(selected$site), expected_sites),
    sprintf(
      "One qualifying participant-day is shown for each of %d sites.",
      length(expected_sites)
    )
  )

  candidates <- prepared_day_showcase_verifier_candidates(coverage)
  expected_selection <- prepared_day_showcase_verifier_selection(
    candidates,
    expected_seed
  ) |>
    dplyr::select(site, Id, local_date)
  add_check(
    "selection::fixed_seed_reproduction",
    identical(
      as.data.frame(selected_keys),
      as.data.frame(expected_selection)
    ),
    "Independent fixed-seed selection reproduces all displayed days."
  )

  expected_eligible <- candidates |>
    dplyr::count(.data$site, name = "eligible_participant_days") |>
    dplyr::arrange(.data$site)
  observed_eligible <- eligible |>
    dplyr::arrange(.data$site) |>
    dplyr::mutate(
      eligible_participant_days = as.integer(
        .data$eligible_participant_days
      )
    )
  add_check(
    "selection::eligible_counts",
    identical(
      as.data.frame(observed_eligible),
      as.data.frame(expected_eligible)
    ),
    "Eligible participant-day counts agree with the prepared minute data."
  )

  expected_rows <- length(expected_sites) * 1440L
  key_columns <- c("site", "participant", "local_date", "clock_minute")
  source_keys_unique <- !anyDuplicated(source_data[key_columns])
  minute_grid <- source_data |>
    dplyr::group_by(.data$site, .data$participant, .data$local_date) |>
    dplyr::summarise(
      rows = dplyr::n(),
      minutes = dplyr::n_distinct(.data$clock_minute),
      minimum = min(.data$clock_minute),
      maximum = max(.data$clock_minute),
      .groups = "drop"
    )
  add_check(
    "source_data::complete_minute_grid",
    nrow(source_data) == expected_rows &&
      source_keys_unique &&
      all(minute_grid$rows == 1440L) &&
      all(minute_grid$minutes == 1440L) &&
      all(minute_grid$minimum == 0L) &&
      all(minute_grid$maximum == 1439L),
    sprintf(
      "%s rows form nine unique 1,440-minute local-clock days.",
      format(expected_rows, big.mark = ",")
    )
  )

  observed_day_keys <- source_data |>
    dplyr::distinct(
      .data$site,
      Id = .data$participant,
      .data$local_date
    ) |>
    dplyr::arrange(.data$site)
  add_check(
    "source_data::selected_day_keys",
    identical(
      as.data.frame(observed_day_keys),
      as.data.frame(selected_keys)
    ),
    "Source-data rows correspond exactly to the nine selected days."
  )

  prepared_rows <- coverage |>
    dplyr::inner_join(
      selected_keys,
      by = c("site", "Id", "local_date"),
      relationship = "many-to-one"
    ) |>
    dplyr::transmute(
      .data$site,
      participant = .data$Id,
      .data$local_date,
      .data$clock_minute,
      expected_datetime_utc = format(
        .data$datetime_utc,
        tz = "UTC",
        format = "%Y-%m-%dT%H:%M:%SZ"
      ),
      expected_datetime_wall = format(
        .data$datetime_wall,
        tz = "UTC",
        format = "%Y-%m-%dT%H:%M:%S"
      ),
      expected_melEDI_lx = .data$MEDI_eligible,
      expected_nonwear = .data$invalid_nonwear,
      expected_wear = as.character(.data$wear),
      expected_sleep = as.character(.data$sleep),
      expected_brown_period = dplyr::recode(
        as.character(.data$State.Brown),
        wake = "Waking daytime",
        `pre-sleep` = "Three hours before sleep",
        sleep = "Sleep"
      ),
      expected_brown_reference_lx = dplyr::recode(
        as.character(.data$State.Brown),
        wake = 250,
        `pre-sleep` = 10,
        sleep = 1
      ),
      expected_measurement_context = as.character(
        .data$measurement_context
      ),
      expected_reason = as.character(.data$MEDI_eligibility_reason)
    ) |>
    dplyr::arrange(
      .data$site,
      .data$participant,
      .data$local_date,
      .data$clock_minute
    )
  source_ordered <- source_data |>
    dplyr::arrange(
      .data$site,
      .data$participant,
      .data$local_date,
      .data$clock_minute
    )
  parity_parts <- c(
    keys =
      identical(source_ordered$site, prepared_rows$site) &&
      identical(source_ordered$participant, prepared_rows$participant) &&
      identical(source_ordered$local_date, prepared_rows$local_date) &&
      all(source_ordered$clock_minute == prepared_rows$clock_minute),
    datetime_utc = identical(
      source_ordered$datetime_utc,
      prepared_rows$expected_datetime_utc
    ),
    datetime_wall = identical(
      source_ordered$datetime_wall,
      prepared_rows$expected_datetime_wall
    ),
    melEDI = prepared_day_showcase_numeric_equal(
      source_ordered$melEDI_lx,
      prepared_rows$expected_melEDI_lx
    ),
    nonwear = identical(
      source_ordered$declared_nonwear,
      prepared_rows$expected_nonwear
    ),
    wear_state = identical(
      as.character(source_ordered$wear_log_state),
      prepared_rows$expected_wear
    ),
    sleep_state = identical(
      as.character(source_ordered$diary_sleep_state),
      prepared_rows$expected_sleep
    ),
    brown_period = identical(
      source_ordered$brown_period,
      prepared_rows$expected_brown_period
    ),
    brown_reference = prepared_day_showcase_numeric_equal(
      source_ordered$brown_reference_lx,
      prepared_rows$expected_brown_reference_lx
    ),
    measurement_context = identical(
      as.character(source_ordered$measurement_context),
      prepared_rows$expected_measurement_context
    ),
    eligibility_reason = identical(
      as.character(source_ordered$MEDI_eligibility_reason),
      prepared_rows$expected_reason
    )
  )
  minute_parity <- all(parity_parts)
  add_check(
    "source_data::prepared_minute_parity",
    minute_parity,
    if (minute_parity) {
      paste(
        "Displayed melEDI, clock values, diary periods, measurement",
        "context, and non-wear reproduce the prepared one-minute input."
      )
    } else {
      paste(
        "Minute-level mismatch in:",
        paste(names(parity_parts)[!parity_parts], collapse = ", ")
      )
    }
  )

  add_check(
    "source_data::nonwear_mask",
    all(
      is.na(source_ordered$melEDI_lx[
        source_ordered$declared_nonwear
      ])
    ),
    "Every declared non-wear minute has missing prepared melEDI."
  )

  solar_selected <- solar_context |>
    dplyr::inner_join(
      selected_keys |>
        dplyr::select(site, local_date),
      by = c("site", "local_date"),
      relationship = "one-to-one"
    ) |>
    dplyr::select(
      site,
      local_date,
      civil_dawn_wall_minute,
      civil_dusk_wall_minute,
      photoperiod_hours,
      solar_depression_deg
    )
  solar_observed <- source_data |>
    dplyr::distinct(
      .data$site,
      .data$local_date,
      .data$civil_dawn_wall_minute,
      .data$civil_dusk_wall_minute,
      .data$photoperiod_hours,
      .data$solar_depression_deg
    )
  solar_comparison <- solar_observed |>
    dplyr::inner_join(
      solar_selected,
      by = c("site", "local_date"),
      suffix = c("_observed", "_expected"),
      relationship = "one-to-one"
    )
  solar_parity <- nrow(solar_comparison) == length(expected_sites) &&
    all(vapply(
      c(
        "civil_dawn_wall_minute",
        "civil_dusk_wall_minute",
        "photoperiod_hours",
        "solar_depression_deg"
      ),
      function(variable) {
        prepared_day_showcase_numeric_equal(
          solar_comparison[[paste0(variable, "_observed")]],
          solar_comparison[[paste0(variable, "_expected")]]
        )
      },
      logical(1)
    ))
  add_check(
    "source_data::solar_context_parity",
    solar_parity,
    "Civil dawn, civil dusk, and photoperiod match the site/date context."
  )

  settings_ok <- c(
    !anyDuplicated(settings$setting) &&
      length(settings$value[settings$setting == "selection_seed"]) == 1L,
    length(settings$value[settings$setting == "selection_seed"]) == 1L &&
      settings$value[settings$setting == "selection_seed"] ==
        as.character(expected_seed),
    length(settings$value[settings$setting == "placement"]) == 1L &&
      settings$value[settings$setting == "placement"] == "near-eye",
    length(settings$value[settings$setting == "plot_time_basis"]) == 1L &&
      settings$value[settings$setting == "plot_time_basis"] ==
        "local wall-clock minute; true UTC retained in source data"
  )
  add_check(
    "settings::declared_design",
    length(settings_ok) == 4L && all(settings_ok),
    paste(
      "The settings identify the fixed seed, near-eye placement,",
      "and local-clock display basis."
    )
  )

  figure_bytes <- file.info(c(paths$figure_png, paths$figure_svg))$size
  svg_opening <- readLines(
    paths$figure_svg,
    n = 10L,
    warn = FALSE,
    encoding = "UTF-8"
  )
  add_check(
    "figures::nonempty_png_and_svg",
    all(figure_bytes > 1000) &&
      any(grepl("<svg", svg_opening, fixed = TRUE)),
    "Both the 300-dpi PNG and vector SVG are non-empty."
  )

  add_check(
    "manifest::table_dimensions",
    all(
      manifest$rows[manifest$artifact_type == "selected_days_csv"] ==
        nrow(selected),
      manifest$rows[
        manifest$artifact_type == "eligible_day_counts_csv"
      ] == nrow(eligible),
      manifest$rows[
        manifest$artifact_type == "selection_settings_csv"
      ] == nrow(settings),
      manifest$rows[
        manifest$artifact_type == "plot_source_data_csv"
      ] == nrow(source_data)
    ),
    "Manifest row counts agree with every CSV artifact."
  )

  result <- prepared_day_showcase_verifier_result(checks)
  result$summary <- list(
    sites = length(expected_sites),
    participant_days = nrow(selected),
    source_rows = nrow(source_data),
    seed = as.integer(expected_seed),
    selected = selected
  )
  result
}
