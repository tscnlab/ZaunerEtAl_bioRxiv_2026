# Independently verify Preparation 06 site/solar artifacts.
#
# Source paths_io.R and assertions.R before this file. This verifier does not
# call the site/solar producer or its builder.

p06_site_solar_default_transition_keys <- function() {
  c(
    "FUSPCEU|2024-10-27",
    "MPI|2023-10-29",
    "RISE|2025-03-30",
    "THUAS|2025-03-30"
  )
}

p06_site_solar_default_site_codes <- function() {
  c(
    "BAUA",
    "FUSPCEU",
    "IZTECH",
    "KNUST",
    "MPI",
    "RISE",
    "THUAS",
    "TUM",
    "UCR"
  )
}

p06_site_solar_paths <- function(root) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  artifact_root <- file.path(root, "artifacts")
  context_root <- file.path(artifact_root, "06_model_data", "context")
  list(
    root = root,
    context_rds = file.path(context_root, "site_solar_context.rds"),
    context_csv = file.path(context_root, "site_solar_context.csv"),
    join_audit = file.path(
      context_root,
      "site_solar_context_join_audit.csv"
    ),
    manifest = file.path(
      artifact_root,
      "12_manifests",
      "site_solar_context_artifacts.csv"
    )
  )
}

p06_site_solar_relative_path <- function(path, anchor, object) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  anchor <- normalizePath(anchor, winslash = "/", mustWork = TRUE)
  prefix <- paste0(anchor, "/")
  p06_require(
    startsWith(path, prefix),
    "%s is outside its declared provenance root: %s",
    object,
    path
  )
  substring(path, nchar(prefix) + 1L)
}

p06_site_solar_manifest_columns <- function() {
  c(
    "path",
    "sha256",
    "bytes",
    "producer",
    "r_version",
    "artifact_type",
    "rows",
    "columns",
    "site_metadata_path",
    "site_metadata_sha256",
    "input_paths",
    "input_sha256",
    "date_domain_rule",
    "site_dates",
    "sites",
    "dst_transition_site_dates",
    "solar_depression_deg",
    "solar_altitude_boundary_deg",
    "solar_noon_role",
    "true_instant_plane",
    "wall_clock_plane",
    "lightlogr_version",
    "suntools_version",
    "status"
  )
}

p06_site_solar_metric_specification <- function(root) {
  metric_root <- file.path(root, "artifacts", "05_metrics")
  tibble::tribble(
    ~input_role,
    ~placement,
    ~resolution,
    ~path,
    "glasses_daily",
    "glasses",
    "daily",
    file.path(metric_root, "metrics_glasses_participant_day.rds"),
    "glasses_30_minute",
    "glasses",
    "30_minute",
    file.path(metric_root, "metrics_glasses_30_minute.rds"),
    "glasses_one_hour",
    "glasses",
    "one_hour",
    file.path(metric_root, "metrics_glasses_one_hour.rds"),
    "chest_daily",
    "chest",
    "daily",
    file.path(metric_root, "metrics_chest_participant_day.rds"),
    "chest_30_minute",
    "chest",
    "30_minute",
    file.path(metric_root, "metrics_chest_30_minute.rds"),
    "chest_one_hour",
    "chest",
    "one_hour",
    file.path(metric_root, "metrics_chest_one_hour.rds")
  )
}

p06_resolve_site_solar_metric_paths <- function(metric_paths, root) {
  specification <- p06_site_solar_metric_specification(root)
  expected <- specification$input_role
  if (is.null(metric_paths)) {
    metric_paths <- stats::setNames(
      specification$path,
      specification$input_role
    )
  }
  if (
    !is.character(metric_paths) ||
      is.null(names(metric_paths)) ||
      anyNA(metric_paths) ||
      any(!nzchar(metric_paths)) ||
      anyDuplicated(names(metric_paths)) ||
      !setequal(names(metric_paths), expected)
  ) {
    abort_pipeline(
      "Verifier metric paths must have exactly these roles: %s",
      paste(expected, collapse = ", ")
    )
  }
  metric_paths <- metric_paths[expected]
  missing <- !file.exists(metric_paths)
  if (any(missing)) {
    abort_pipeline(
      "Verifier input(s) do not exist: %s",
      paste(metric_paths[missing], collapse = ", ")
    )
  }
  vapply(
    metric_paths,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
}

p06_resolve_supplemental_date_paths <- function(
  supplemental_date_paths = NULL
) {
  if (is.null(supplemental_date_paths)) {
    return(stats::setNames(character(), character()))
  }
  p06_require(
    is.character(supplemental_date_paths) &&
      !is.null(names(supplemental_date_paths)) &&
      length(supplemental_date_paths) > 0L &&
      !anyNA(supplemental_date_paths) &&
      all(nzchar(supplemental_date_paths)) &&
      !anyNA(names(supplemental_date_paths)) &&
      all(nzchar(names(supplemental_date_paths))) &&
      !anyDuplicated(names(supplemental_date_paths)) &&
      !any(
        names(supplemental_date_paths) %in%
          p06_site_solar_metric_specification(".")$input_role
      ),
    paste0(
      "Verifier supplemental site-date paths must be NULL or a ",
      "uniquely named character vector"
    )
  )
  missing <- !file.exists(supplemental_date_paths)
  p06_require(
    !any(missing),
    "Verifier supplemental site-date input(s) are missing: %s",
    paste(supplemental_date_paths[missing], collapse = ", ")
  )
  vapply(
    supplemental_date_paths,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
}

p06_require <- function(condition, message, ...) {
  if (
    length(condition) != 1L ||
      is.na(condition) ||
      !isTRUE(condition)
  ) {
    abort_pipeline(message, ...)
  }
  invisible(TRUE)
}

p06_plain_participant_day_keys <- function(data) {
  required <- c("site", "Id", "position", "local_date")
  assert_columns(data, required, object = "verifier metric input")
  assert_no_missing_key(data, required, object = "verifier metric input")
  p06_require(
    is.character(data$site) &&
      is.character(data$Id) &&
      is.character(data$position) &&
      inherits(data$local_date, "Date"),
    "Verifier metric input has invalid participant-day key types"
  )
  tibble::tibble(
    site = as.character(data$site),
    Id = as.character(data$Id),
    position = as.character(data$position),
    local_date = as.Date(data$local_date)
  ) |>
    dplyr::distinct() |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date
    )
}

p06_read_and_validate_metric_inputs <- function(metric_paths, root) {
  specification <- p06_site_solar_metric_specification(root)
  inputs <- lapply(specification$input_role, function(input_role) {
    readRDS(metric_paths[[input_role]])
  })
  names(inputs) <- specification$input_role

  for (index in seq_len(nrow(specification))) {
    input_role <- specification$input_role[[index]]
    placement <- specification$placement[[index]]
    resolution <- specification$resolution[[index]]
    data <- inputs[[input_role]]
    p06_require(
      is.data.frame(data) && nrow(data) > 0L,
      "%s is empty",
      input_role
    )
    p06_require(
      identical(unique(data$position), placement),
      "%s has the wrong placement",
      input_role
    )
    participant_day_key <- c("site", "Id", "position", "local_date")
    resolution_key <- switch(
      resolution,
      daily = participant_day_key,
      `30_minute` = c(participant_day_key, "clock_bin"),
      one_hour = c(participant_day_key, "clock_minute")
    )
    assert_unique_key(data, resolution_key, object = input_role)
    if (!identical(resolution, "daily")) {
      clock_column <- if (identical(resolution, "30_minute")) {
        "clock_bin"
      } else {
        "clock_minute"
      }
      expected_grid <- if (identical(resolution, "30_minute")) {
        seq.int(0L, 1410L, by = 30L)
      } else {
        seq.int(0L, 1380L, by = 60L)
      }
      grid_checks <- split(
        as.integer(data[[clock_column]]),
        interaction(
          data$site,
          data$Id,
          data$position,
          data$local_date,
          drop = TRUE,
          lex.order = TRUE
        )
      )
      complete <- vapply(
        grid_checks,
        function(value) identical(sort(value), expected_grid),
        logical(1)
      )
      p06_require(
        all(complete),
        "%s does not have a complete clock grid",
        input_role
      )
    }
  }

  for (placement in unique(specification$placement)) {
    placement_specification <- specification[
      specification$placement == placement,
      ,
      drop = FALSE
    ]
    daily_role <- placement_specification$input_role[
      placement_specification$resolution == "daily"
    ]
    daily_keys <- p06_plain_participant_day_keys(inputs[[daily_role]])
    for (input_role in placement_specification$input_role) {
      p06_require(
        identical(
          p06_plain_participant_day_keys(inputs[[input_role]]),
          daily_keys
        ),
        "%s participant-day domain differs from %s daily metrics",
        input_role,
        placement
      )
    }
  }
  inputs
}

p06_read_supplemental_site_dates <- function(supplemental_date_paths) {
  inputs <- lapply(supplemental_date_paths, readRDS)
  names(inputs) <- names(supplemental_date_paths)
  for (input_role in names(inputs)) {
    data <- inputs[[input_role]]
    p06_require(
      is.data.frame(data) &&
        nrow(data) > 0L,
      "Verifier supplemental site-date input `%s` is empty",
      input_role
    )
    assert_columns(
      data,
      c("site", "local_date"),
      object = paste0("verifier supplemental input `", input_role, "`")
    )
    assert_no_missing_key(
      data,
      c("site", "local_date"),
      object = paste0("verifier supplemental input `", input_role, "`")
    )
    p06_require(
      is.character(data$site) &&
        inherits(data$local_date, "Date") &&
        all(data$site %in% p06_site_solar_default_site_codes()),
      "Verifier supplemental site-date input `%s` has invalid fields",
      input_role
    )
  }
  inputs
}

p06_site_date_domain <- function(
  inputs,
  supplemental_dates = list()
) {
  main_dates <- lapply(c("glasses_daily", "chest_daily"), function(role) {
    data <- inputs[[role]]
    tibble::tibble(
      site = as.character(data$site),
      local_date = as.Date(data$local_date)
    )
  })
  added_dates <- lapply(supplemental_dates, function(data) {
    tibble::tibble(
      site = as.character(data$site),
      local_date = as.Date(data$local_date)
    )
  })
  dplyr::bind_rows(c(main_dates, added_dates)) |>
    dplyr::distinct() |>
    dplyr::arrange(.data$site, .data$local_date)
}

p06_offset_minutes <- function(offset) {
  p06_require(
    is.character(offset) &&
      all(is.na(offset) | grepl("^[+-][0-9]{4}$", offset)),
    "Verifier encountered an invalid UTC offset"
  )
  sign <- ifelse(substr(offset, 1L, 1L) == "-", -1L, 1L)
  value <- sign *
    (as.integer(substr(offset, 2L, 3L)) *
      60L +
      as.integer(substr(offset, 4L, 5L)))
  value[is.na(offset)] <- NA_integer_
  as.integer(value)
}

p06_true_utc <- function(datetime) {
  as.POSIXct(as.numeric(datetime), origin = "1970-01-01", tz = "UTC")
}

p06_expected_event_fields <- function(datetime, timezone, prefix) {
  local <- as.POSIXlt(datetime, tz = timezone)
  output <- tibble::tibble(
    utc = p06_true_utc(datetime),
    local_label = as.character(format(
      datetime,
      "%Y-%m-%dT%H:%M:%OS6%z",
      tz = timezone
    )),
    wall_minute = as.numeric(
      local$hour * 60 + local$min + local$sec / 60
    ),
    utc_offset_minutes = p06_offset_minutes(
      format(datetime, "%z", tz = timezone)
    ),
    is_dst = as.logical(local$isdst == 1L)
  )
  names(output) <- paste0(prefix, names(output))
  output
}

p06_expected_day_fields <- function(dates, timezone) {
  local_start <- as.POSIXct(
    paste(format(dates, "%Y-%m-%d"), "00:00:00"),
    tz = timezone
  )
  next_local_start <- as.POSIXct(
    paste(format(dates + 1L, "%Y-%m-%d"), "00:00:00"),
    tz = timezone
  )
  local_end <- next_local_start - 1
  start_fields <- as.POSIXlt(local_start, tz = timezone)
  end_fields <- as.POSIXlt(local_end, tz = timezone)
  start_offset <- p06_offset_minutes(
    format(local_start, "%z", tz = timezone)
  )
  end_offset <- p06_offset_minutes(
    format(local_end, "%z", tz = timezone)
  )
  tibble::tibble(
    local_day_start_utc = p06_true_utc(local_start),
    next_local_day_start_utc = p06_true_utc(next_local_start),
    local_day_real_hours = as.numeric(
      difftime(next_local_start, local_start, units = "hours")
    ),
    local_day_start_utc_offset_minutes = start_offset,
    local_day_end_utc_offset_minutes = end_offset,
    local_day_start_is_dst = as.logical(start_fields$isdst == 1L),
    local_day_end_is_dst = as.logical(end_fields$isdst == 1L),
    local_day_crosses_dst = as.logical(start_offset != end_offset)
  )
}

p06_reconstruct_context <- function(domain, metadata) {
  sites <- unique(domain$site)
  rows <- lapply(sites, function(site) {
    dates <- domain$local_date[domain$site == site]
    metadata_row <- metadata[metadata$site == site, , drop = FALSE]
    p06_require(
      nrow(metadata_row) == 1L,
      "Verifier metadata does not have one row for site %s",
      site
    )
    timezone <- metadata_row$timezone[[1L]]
    coordinates <- c(
      metadata_row$latitude_deg[[1L]],
      metadata_row$longitude_deg[[1L]]
    )
    twilight <- LightLogR::photoperiod(
      coordinates = coordinates,
      dates = dates,
      tz = timezone,
      solarDep = 6
    )
    local_midnight <- as.POSIXct(
      paste(format(dates, "%Y-%m-%d"), "00:00:00"),
      tz = timezone
    )
    noon <- suntools::solarnoon(
      crds = matrix(c(coordinates[[2L]], coordinates[[1L]]), nrow = 1L),
      dateTime = local_midnight,
      POSIXct.out = TRUE
    )$time
    metadata_rows <- metadata_row[
      rep.int(1L, length(dates)),
      ,
      drop = FALSE
    ]
    tibble::as_tibble(metadata_rows) |>
      dplyr::mutate(
        local_date = dates,
        solar_context_definition = "civil_dawn_to_civil_dusk",
        solar_noon_role = "contextual_metadata_only",
        solar_depression_deg = 6,
        solar_altitude_boundary_deg = -6,
        photoperiod_hours = as.numeric(
          difftime(twilight$dusk, twilight$dawn, units = "hours")
        )
      ) |>
      dplyr::bind_cols(
        p06_expected_event_fields(
          twilight$dawn,
          timezone,
          "civil_dawn_"
        ),
        p06_expected_event_fields(
          twilight$dusk,
          timezone,
          "civil_dusk_"
        ),
        p06_expected_event_fields(noon, timezone, "solar_noon_"),
        p06_expected_day_fields(dates, timezone)
      )
  })
  dplyr::bind_rows(rows) |>
    dplyr::mutate(
      solar_context_algorithm = paste0(
        "LightLogR::photoperiod + suntools::solarnoon(local midnight)"
      ),
      lightlogr_version = as.character(
        utils::packageVersion("LightLogR")
      ),
      suntools_version = as.character(utils::packageVersion("suntools")),
      r_version = as.character(getRversion())
    ) |>
    dplyr::arrange(.data$site, .data$local_date)
}

p06_vector_equal <- function(observed, expected, tolerance = 1e-12) {
  if (
    length(observed) != length(expected) ||
      !identical(is.na(observed), is.na(expected))
  ) {
    return(FALSE)
  }
  keep <- !is.na(observed)
  if (!any(keep)) {
    return(TRUE)
  }
  if (
    (is.numeric(observed) || is.integer(observed)) &&
      (is.numeric(expected) || is.integer(expected))
  ) {
    return(all(
      abs(as.numeric(observed[keep]) - as.numeric(expected[keep])) <=
        tolerance *
          pmax(
            1,
            abs(as.numeric(observed[keep])),
            abs(as.numeric(expected[keep]))
          )
    ))
  }
  identical(
    as.character(observed[keep]),
    as.character(expected[keep])
  )
}

p06_tables_equal <- function(observed, expected, tolerance = 1e-12) {
  if (
    !identical(names(observed), names(expected)) ||
      nrow(observed) != nrow(expected)
  ) {
    return(FALSE)
  }
  all(vapply(
    names(expected),
    function(column) {
      p06_vector_equal(
        observed[[column]],
        expected[[column]],
        tolerance = tolerance
      )
    },
    logical(1)
  ))
}

p06_context_csv_col_types <- function() {
  numeric_columns <- c(
    "latitude_deg",
    "longitude_deg",
    "solar_depression_deg",
    "solar_altitude_boundary_deg",
    "photoperiod_hours",
    "civil_dawn_wall_minute",
    "civil_dawn_utc_offset_minutes",
    "civil_dusk_wall_minute",
    "civil_dusk_utc_offset_minutes",
    "solar_noon_wall_minute",
    "solar_noon_utc_offset_minutes",
    "local_day_real_hours",
    "local_day_start_utc_offset_minutes",
    "local_day_end_utc_offset_minutes"
  )
  logical_columns <- c(
    "civil_dawn_is_dst",
    "civil_dusk_is_dst",
    "solar_noon_is_dst",
    "local_day_start_is_dst",
    "local_day_end_is_dst",
    "local_day_crosses_dst"
  )
  specification <- c(
    stats::setNames(
      rep(list(readr::col_double()), length(numeric_columns)),
      numeric_columns
    ),
    stats::setNames(
      rep(list(readr::col_logical()), length(logical_columns)),
      logical_columns
    )
  )
  do.call(
    readr::cols,
    c(list(.default = readr::col_character()), specification)
  )
}

p06_expected_csv <- function(context) {
  output <- tibble::as_tibble(context)
  output$local_date <- format(output$local_date, "%Y-%m-%d")
  utc_columns <- c(
    "civil_dawn_utc",
    "civil_dusk_utc",
    "solar_noon_utc",
    "local_day_start_utc",
    "next_local_day_start_utc"
  )
  for (column in utc_columns) {
    output[[column]] <- format(
      output[[column]],
      "%Y-%m-%dT%H:%M:%OS6Z",
      tz = "UTC"
    )
  }
  output
}

p06_expected_join_audit <- function(inputs, root) {
  specification <- p06_site_solar_metric_specification(root)
  rows <- lapply(seq_len(nrow(specification)), function(index) {
    role <- specification$input_role[[index]]
    data <- inputs[[role]]
    site_dates <- tibble::tibble(
      site = as.character(data$site),
      local_date = as.Date(data$local_date)
    ) |>
      dplyr::distinct()
    tibble::tibble(
      input_role = role,
      placement = specification$placement[[index]],
      resolution = specification$resolution[[index]],
      join_key = "site|local_date",
      relationship = "many-to-one",
      input_rows = nrow(data),
      joined_rows = nrow(data),
      participant_days = nrow(p06_plain_participant_day_keys(data)),
      distinct_site_dates = nrow(site_dates),
      unmatched_rows = 0L,
      status = "PASS"
    )
  })
  dplyr::bind_rows(rows)
}

p06_verify_manifest <- function(
  manifest,
  paths,
  declared_input_paths,
  site_metadata_path,
  expected_context,
  output_root,
  input_root
) {
  required_types <- c(
    "site_solar_context_csv",
    "site_solar_context_join_audit",
    "site_solar_context_rds"
  )
  p06_require(
    identical(names(manifest), p06_site_solar_manifest_columns()) &&
      nrow(manifest) == 3L &&
      setequal(manifest$artifact_type, required_types),
    paste0(
      "Site/solar manifest must have the deterministic schema and exactly ",
      "the three main-analysis artifacts"
    )
  )
  expected_paths <- c(
    site_solar_context_csv = paths$context_csv,
    site_solar_context_join_audit = paths$join_audit,
    site_solar_context_rds = paths$context_rds
  )
  relative_input_paths <- vapply(
    declared_input_paths,
    p06_site_solar_relative_path,
    character(1),
    anchor = input_root,
    object = "Verifier metric input"
  )
  expected_path_string <- paste(
    paste(names(relative_input_paths), relative_input_paths, sep = "="),
    collapse = "|"
  )
  input_hashes <- vapply(
    declared_input_paths,
    artifact_sha256,
    character(1)
  )
  expected_hash_string <- paste(
    paste(names(input_hashes), input_hashes, sep = "="),
    collapse = "|"
  )
  expected_metadata_hash <- artifact_sha256(site_metadata_path)
  expected_metadata_path <- p06_site_solar_relative_path(
    site_metadata_path,
    input_root,
    "Verifier site metadata input"
  )
  p06_require(
    !"written_utc" %in% names(manifest) &&
      all(!grepl("^/", manifest$path)) &&
      all(!grepl("^/", manifest$site_metadata_path)) &&
      all(!grepl("=[/]", manifest$input_paths)),
    "Site/solar manifest contains runtime or absolute-path provenance"
  )
  for (artifact_type in required_types) {
    row <- manifest[
      manifest$artifact_type == artifact_type,
      ,
      drop = FALSE
    ]
    expected_absolute_path <- normalizePath(
      expected_paths[[artifact_type]],
      winslash = "/",
      mustWork = TRUE
    )
    expected_path <- p06_site_solar_relative_path(
      expected_absolute_path,
      output_root,
      "Verifier site/solar output"
    )
    p06_require(
      nrow(row) == 1L &&
        identical(row$path[[1L]], expected_path) &&
        identical(
          row$sha256[[1L]],
          artifact_sha256(expected_absolute_path)
        ) &&
        as.numeric(row$bytes[[1L]]) == file.info(expected_absolute_path)$size &&
        row$producer[[1L]] == "scripts/pipeline/build_site_solar_context.R" &&
        row$r_version[[1L]] == "4.6.1" &&
        row$site_metadata_path[[1L]] == expected_metadata_path &&
        row$site_metadata_sha256[[1L]] == expected_metadata_hash &&
        row$input_paths[[1L]] == expected_path_string &&
        row$input_sha256[[1L]] == expected_hash_string &&
        row$solar_noon_role[[1L]] == "contextual_metadata_only" &&
        row$true_instant_plane[[1L]] == "POSIXct_UTC" &&
        row$wall_clock_plane[[1L]] == "local_label_and_scalar_minute" &&
        row$status[[1L]] == "PASS",
      "Manifest row failed for artifact type %s",
      artifact_type
    )
  }
  rds_row <- manifest[
    manifest$artifact_type == "site_solar_context_rds",
    ,
    drop = FALSE
  ]
  p06_require(
    as.integer(rds_row$rows[[1L]]) == nrow(expected_context) &&
      as.integer(rds_row$columns[[1L]]) == ncol(expected_context),
    "Manifest RDS dimensions do not match the reconstructed context"
  )
  invisible(TRUE)
}

p06_verify_site_solar_context_impl <- function(
  root,
  site_metadata_path,
  metric_paths,
  supplemental_date_paths,
  input_root,
  expected_site_dates,
  expected_sites,
  expected_transition_keys
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  input_root <- normalizePath(
    input_root,
    winslash = "/",
    mustWork = TRUE
  )
  paths <- p06_site_solar_paths(root)
  required_outputs <- unlist(paths[names(paths) != "root"], use.names = FALSE)
  missing_outputs <- !file.exists(required_outputs)
  p06_require(
    !any(missing_outputs),
    "Site/solar output(s) are missing: %s",
    paste(required_outputs[missing_outputs], collapse = ", ")
  )
  metric_paths <- p06_resolve_site_solar_metric_paths(metric_paths, root)
  supplemental_date_paths <- p06_resolve_supplemental_date_paths(
    supplemental_date_paths
  )
  site_metadata_path <- normalizePath(
    site_metadata_path,
    winslash = "/",
    mustWork = TRUE
  )
  inputs <- p06_read_and_validate_metric_inputs(metric_paths, root)
  supplemental_dates <- p06_read_supplemental_site_dates(
    supplemental_date_paths
  )
  domain <- p06_site_date_domain(
    inputs,
    supplemental_dates = supplemental_dates
  )
  if (is.null(expected_site_dates)) {
    expected_site_dates <- nrow(domain)
  }
  if (
    !is.numeric(expected_site_dates) ||
      length(expected_site_dates) != 1L ||
      is.na(expected_site_dates) ||
      expected_site_dates < 1L ||
      expected_site_dates != as.integer(expected_site_dates)
  ) {
    p06_abort("`expected_site_dates` must be NULL or one positive integer")
  }
  expected_site_dates <- as.integer(expected_site_dates)

  metadata <- readr::read_csv(
    site_metadata_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  required_metadata <- c(
    "site",
    "city",
    "country",
    "location",
    "timezone",
    "latitude_deg",
    "longitude_deg",
    "coordinate_order",
    "coordinate_source",
    "coordinate_source_version",
    "site_manifest_source",
    "site_release_repository",
    "site_release_commit",
    "site_release_doi"
  )
  p06_require(
    identical(names(metadata), required_metadata) &&
      nrow(metadata) == 9L &&
      !anyDuplicated(metadata$site) &&
      all(metadata$timezone %in% OlsonNames()) &&
      all(metadata$coordinate_order == "latitude_longitude"),
    "Pinned site metadata failed independent structural validation"
  )
  coordinate_environment <- new.env(parent = emptyenv())
  utils::data(
    "melidos_coordinates",
    package = "melidosData",
    envir = coordinate_environment
  )
  coordinate_reference <- get(
    "melidos_coordinates",
    envir = coordinate_environment,
    inherits = FALSE
  )
  for (site in metadata$site) {
    row <- metadata[metadata$site == site, , drop = FALSE]
    p06_require(
      isTRUE(all.equal(
        c(row$latitude_deg, row$longitude_deg),
        unname(coordinate_reference[[site]]),
        tolerance = 0
      )),
      "Pinned coordinates differ from melidosData 1.0.6 for site %s",
      site
    )
  }

  observed <- readRDS(paths$context_rds)
  p06_require(
    is.data.frame(observed) &&
      inherits(observed$local_date, "Date") &&
      nrow(observed) == expected_site_dates &&
      dplyr::n_distinct(observed$site) == expected_sites,
    "Site/solar context dimensions differ from the metric date domain"
  )
  assert_unique_key(
    observed,
    c("site", "local_date"),
    object = "site solar context"
  )
  expected <- p06_reconstruct_context(domain, metadata)
  p06_require(
    p06_tables_equal(
      tibble::as_tibble(observed),
      expected,
      tolerance = 1e-12
    ),
    "Site/solar RDS differs from the independent solar reconstruction"
  )
  p06_require(
    identical(lubridate::tz(observed$civil_dawn_utc), "UTC") &&
      identical(lubridate::tz(observed$civil_dusk_utc), "UTC") &&
      identical(lubridate::tz(observed$solar_noon_utc), "UTC") &&
      all(observed$solar_noon_role == "contextual_metadata_only") &&
      all(
        observed$civil_dawn_wall_minute >= 0 &
          observed$civil_dawn_wall_minute < 1440
      ) &&
      all(
        observed$civil_dusk_wall_minute >= 0 &
          observed$civil_dusk_wall_minute < 1440
      ) &&
      all(
        observed$solar_noon_wall_minute >= 0 &
          observed$solar_noon_wall_minute < 1440
      ),
    "Site/solar context does not preserve the UTC/wall-clock contract"
  )
  transition_keys <- paste(
    observed$site[observed$local_day_crosses_dst],
    observed$local_date[observed$local_day_crosses_dst],
    sep = "|"
  )
  p06_require(
    setequal(transition_keys, expected_transition_keys),
    "Site/solar DST-transition site-date set differs from expectation"
  )

  expected_csv <- p06_expected_csv(expected)
  observed_csv <- readr::read_csv(
    paths$context_csv,
    col_types = p06_context_csv_col_types(),
    show_col_types = FALSE,
    progress = FALSE
  )
  p06_require(
    p06_tables_equal(observed_csv, expected_csv, tolerance = 1e-12),
    "Site/solar context CSV differs from the explicit formatted RDS values"
  )

  expected_join_audit <- p06_expected_join_audit(inputs, root)
  observed_join_audit <- readr::read_csv(
    paths$join_audit,
    show_col_types = FALSE,
    progress = FALSE
  )
  p06_require(
    p06_tables_equal(
      observed_join_audit,
      expected_join_audit,
      tolerance = 0
    ) &&
      nrow(observed_join_audit) == 6L &&
      all(observed_join_audit$unmatched_rows == 0L) &&
      all(observed_join_audit$relationship == "many-to-one"),
    "Site/solar join audit failed"
  )

  declared_input_paths <- c(metric_paths, supplemental_date_paths)
  input_hashes <- vapply(
    declared_input_paths,
    artifact_sha256,
    character(1)
  )
  settings <- attr(observed, "site_solar_settings", exact = TRUE)
  p06_require(
    is.data.frame(settings) &&
      nrow(settings) == 1L &&
      settings$site_dates[[1L]] == expected_site_dates &&
      settings$sites[[1L]] == expected_sites &&
      settings$dst_transition_site_dates[[1L]] ==
        length(expected_transition_keys) &&
      isTRUE(settings$resolution_domains_match_daily[[1L]]) &&
      isTRUE(settings$zero_unmatched_joins[[1L]]) &&
      identical(
        attr(observed, "site_metadata_sha256", exact = TRUE),
        artifact_sha256(site_metadata_path)
      ) &&
      identical(
        attr(observed, "input_sha256", exact = TRUE),
        input_hashes
      ),
    "Site/solar RDS provenance attributes failed"
  )

  manifest <- readr::read_csv(
    paths$manifest,
    show_col_types = FALSE,
    progress = FALSE
  )
  p06_verify_manifest(
    manifest,
    paths = paths,
    declared_input_paths = declared_input_paths,
    site_metadata_path = site_metadata_path,
    expected_context = expected,
    output_root = root,
    input_root = input_root
  )

  list(
    status = "PASS",
    site_dates = nrow(observed),
    sites = dplyr::n_distinct(observed$site),
    dst_transition_site_dates = length(transition_keys),
    join_audit_rows = nrow(observed_join_audit),
    unmatched_rows = sum(observed_join_audit$unmatched_rows),
    manifest_rows = nrow(manifest),
    paths = paths
  )
}

verify_site_solar_context_artifacts <- function(
  root = project_root(),
  site_metadata_path = file.path(root, "config", "site_metadata.csv"),
  metric_paths = NULL,
  supplemental_date_paths = NULL,
  input_root = root,
  expected_site_dates = NULL,
  expected_sites = 9L,
  expected_transition_keys = p06_site_solar_default_transition_keys(),
  stop_on_failure = TRUE
) {
  result <- tryCatch(
    p06_verify_site_solar_context_impl(
      root = root,
      site_metadata_path = site_metadata_path,
      metric_paths = metric_paths,
      supplemental_date_paths = supplemental_date_paths,
      input_root = input_root,
      expected_site_dates = expected_site_dates,
      expected_sites = expected_sites,
      expected_transition_keys = expected_transition_keys
    ),
    error = function(error) {
      list(
        status = "FAIL",
        error = conditionMessage(error)
      )
    }
  )
  if (!identical(result$status, "PASS") && isTRUE(stop_on_failure)) {
    abort_pipeline(
      "Site/solar artifact verification failed: %s",
      result$error
    )
  }
  result
}
