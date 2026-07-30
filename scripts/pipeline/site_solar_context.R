# Derive deterministic civil-twilight context on true and wall-clock planes.
#
# Source scripts/pipeline/assertions.R before this file.

expected_site_codes <- function() {
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

site_metadata_required_columns <- function() {
  c(
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
}

validate_site_metadata <- function(
  site_metadata,
  object = deparse(substitute(site_metadata))
) {
  if (!is.data.frame(site_metadata)) {
    abort_pipeline("%s must be a data frame", object)
  }
  required <- site_metadata_required_columns()
  assert_columns(site_metadata, required, object = object)
  assert_no_missing_key(site_metadata, required, object = object)
  assert_unique_key(site_metadata, "site", object = object)

  expected_sites <- sort(expected_site_codes())
  observed_sites <- sort(as.character(site_metadata$site))
  if (!identical(observed_sites, expected_sites)) {
    missing_sites <- setdiff(expected_sites, observed_sites)
    unexpected_sites <- setdiff(observed_sites, expected_sites)
    abort_pipeline(
      paste0(
        "%s must contain exactly the nine study sites. ",
        "Missing: %s. Unexpected: %s"
      ),
      object,
      if (length(missing_sites) == 0L) {
        "none"
      } else {
        paste(missing_sites, collapse = ", ")
      },
      if (length(unexpected_sites) == 0L) {
        "none"
      } else {
        paste(unexpected_sites, collapse = ", ")
      }
    )
  }

  character_columns <- setdiff(
    required,
    c("latitude_deg", "longitude_deg")
  )
  invalid_character <- vapply(
    site_metadata[character_columns],
    function(value) {
      !is.character(value) ||
        any(!nzchar(trimws(value)))
    },
    logical(1)
  )
  if (any(invalid_character)) {
    abort_pipeline(
      "%s has invalid character field(s): %s",
      object,
      paste(names(invalid_character)[invalid_character], collapse = ", ")
    )
  }

  if (
    !is.numeric(site_metadata$latitude_deg) ||
      any(!is.finite(site_metadata$latitude_deg)) ||
      any(site_metadata$latitude_deg < -90 | site_metadata$latitude_deg > 90)
  ) {
    abort_pipeline(
      "%s column `latitude_deg` must contain finite values in [-90, 90]",
      object
    )
  }
  if (
    !is.numeric(site_metadata$longitude_deg) ||
      any(!is.finite(site_metadata$longitude_deg)) ||
      any(
        site_metadata$longitude_deg < -180 |
          site_metadata$longitude_deg > 180
      )
  ) {
    abort_pipeline(
      "%s column `longitude_deg` must contain finite values in [-180, 180]",
      object
    )
  }
  if (any(site_metadata$coordinate_order != "latitude_longitude")) {
    abort_pipeline(
      "%s must declare `coordinate_order` as `latitude_longitude`",
      object
    )
  }

  invalid_timezones <- !site_metadata$timezone %in% OlsonNames()
  if (any(invalid_timezones)) {
    abort_pipeline(
      "%s has invalid Olson time zone(s): %s",
      object,
      paste(
        sort(unique(site_metadata$timezone[invalid_timezones])),
        collapse = ", "
      )
    )
  }
  invalid_commits <- !grepl(
    "^[0-9a-f]{40}$",
    site_metadata$site_release_commit
  )
  if (any(invalid_commits)) {
    abort_pipeline(
      "%s has invalid 40-character release commit(s) for site(s): %s",
      object,
      paste(site_metadata$site[invalid_commits], collapse = ", ")
    )
  }
  invalid_dois <- !grepl("^10[.][0-9]+/", site_metadata$site_release_doi)
  if (any(invalid_dois)) {
    abort_pipeline(
      "%s has invalid release DOI(s) for site(s): %s",
      object,
      paste(site_metadata$site[invalid_dois], collapse = ", ")
    )
  }

  invisible(site_metadata)
}

read_site_metadata <- function(path) {
  if (
    !is.character(path) ||
      length(path) != 1L ||
      is.na(path) ||
      !nzchar(path)
  ) {
    abort_pipeline("`path` must be one non-empty file path")
  }
  if (!file.exists(path)) {
    abort_pipeline("Site metadata file does not exist: %s", path)
  }
  metadata <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fileEncoding = "UTF-8"
  )
  validate_site_metadata(metadata, object = "site metadata")
  tibble::as_tibble(metadata)
}

validate_site_date_domain <- function(
  site_dates,
  site_metadata,
  object = deparse(substitute(site_dates))
) {
  if (!is.data.frame(site_dates)) {
    abort_pipeline("%s must be a data frame", object)
  }
  if (nrow(site_dates) == 0L) {
    abort_pipeline("%s must contain at least one site-date row", object)
  }
  assert_columns(site_dates, c("site", "local_date"), object = object)
  assert_no_missing_key(
    site_dates,
    c("site", "local_date"),
    object = object
  )
  assert_unique_key(
    site_dates,
    c("site", "local_date"),
    object = object
  )
  if (!is.character(site_dates$site)) {
    abort_pipeline("%s column `site` must be character", object)
  }
  if (!inherits(site_dates$local_date, "Date")) {
    abort_pipeline("%s column `local_date` must be Date", object)
  }

  validate_site_metadata(site_metadata, object = "site metadata")
  unknown_sites <- setdiff(unique(site_dates$site), site_metadata$site)
  if (length(unknown_sites) > 0L) {
    abort_pipeline(
      "%s contains site(s) absent from site metadata: %s",
      object,
      paste(sort(unknown_sites), collapse = ", ")
    )
  }
  invisible(site_dates)
}

validate_solar_context_runtime <- function() {
  required_packages <- c("LightLogR", "suntools")
  available <- vapply(
    required_packages,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )
  if (any(!available)) {
    abort_pipeline(
      "Solar context requires installed package(s): %s",
      paste(required_packages[!available], collapse = ", ")
    )
  }
  if (utils::packageVersion("LightLogR") < "0.10.3") {
    abort_pipeline("Solar context requires LightLogR >= 0.10.3")
  }
  if (utils::packageVersion("suntools") < "1.1.0") {
    abort_pipeline("Solar context requires suntools >= 1.1.0")
  }
  invisible(TRUE)
}

parse_solar_utc_offset_minutes <- function(offset) {
  if (!is.character(offset)) {
    abort_pipeline("Solar-event UTC offsets must be character")
  }
  valid <- is.na(offset) | grepl("^[+-][0-9]{4}$", offset)
  if (!all(valid)) {
    abort_pipeline(
      "Solar-event UTC offsets contain invalid value(s): %s",
      paste(unique(offset[!valid]), collapse = ", ")
    )
  }
  sign <- ifelse(substr(offset, 1L, 1L) == "-", -1L, 1L)
  hours <- suppressWarnings(as.integer(substr(offset, 2L, 3L)))
  minutes <- suppressWarnings(as.integer(substr(offset, 4L, 5L)))
  result <- sign * (hours * 60L + minutes)
  result[is.na(offset)] <- NA_integer_
  as.integer(result)
}

as_true_utc <- function(datetime) {
  if (!inherits(datetime, "POSIXct")) {
    abort_pipeline("Solar event must be POSIXct")
  }
  as.POSIXct(
    as.numeric(datetime),
    origin = "1970-01-01",
    tz = "UTC"
  )
}

solar_event_fields <- function(datetime, timezone, prefix) {
  if (!inherits(datetime, "POSIXct")) {
    abort_pipeline("Solar event `%s` must be POSIXct", prefix)
  }
  if (
    !is.character(timezone) ||
      length(timezone) != 1L ||
      is.na(timezone) ||
      !timezone %in% OlsonNames()
  ) {
    abort_pipeline(
      "Solar event `%s` requires one valid Olson time zone",
      prefix
    )
  }
  if (
    !is.character(prefix) ||
      length(prefix) != 1L ||
      is.na(prefix) ||
      !nzchar(prefix)
  ) {
    abort_pipeline("Solar-event `prefix` must be one non-empty string")
  }

  local_fields <- as.POSIXlt(datetime, tz = timezone)
  local_label <- format(
    datetime,
    format = "%Y-%m-%dT%H:%M:%OS6%z",
    tz = timezone
  )
  wall_minute <- (local_fields$hour *
    60 +
    local_fields$min +
    local_fields$sec / 60)
  offset <- format(datetime, format = "%z", tz = timezone)

  output <- tibble::tibble(
    utc = as_true_utc(datetime),
    local_label = as.character(local_label),
    wall_minute = as.numeric(wall_minute),
    utc_offset_minutes = parse_solar_utc_offset_minutes(offset),
    is_dst = as.logical(local_fields$isdst == 1L)
  )
  names(output) <- paste0(prefix, names(output))
  output
}

local_day_fields <- function(local_date, timezone) {
  start_local <- as.POSIXct(
    paste(format(local_date, "%Y-%m-%d"), "00:00:00"),
    tz = timezone
  )
  next_start_local <- as.POSIXct(
    paste(format(local_date + 1L, "%Y-%m-%d"), "00:00:00"),
    tz = timezone
  )
  day_end_local <- next_start_local - 1
  start_fields <- as.POSIXlt(start_local, tz = timezone)
  end_fields <- as.POSIXlt(day_end_local, tz = timezone)
  start_offset <- parse_solar_utc_offset_minutes(
    format(start_local, format = "%z", tz = timezone)
  )
  end_offset <- parse_solar_utc_offset_minutes(
    format(day_end_local, format = "%z", tz = timezone)
  )

  tibble::tibble(
    local_day_start_utc = as_true_utc(start_local),
    next_local_day_start_utc = as_true_utc(next_start_local),
    local_day_real_hours = as.numeric(
      difftime(next_start_local, start_local, units = "hours")
    ),
    local_day_start_utc_offset_minutes = start_offset,
    local_day_end_utc_offset_minutes = end_offset,
    local_day_start_is_dst = as.logical(start_fields$isdst == 1L),
    local_day_end_is_dst = as.logical(end_fields$isdst == 1L),
    local_day_crosses_dst = as.logical(start_offset != end_offset)
  )
}

calculate_suntools_solar_noon <- function(
  coordinates_lat_lon,
  dates,
  timezone
) {
  local_midnight <- as.POSIXct(
    paste(format(dates, "%Y-%m-%d"), "00:00:00"),
    tz = timezone
  )
  # LightLogR 0.10.3 passes Date directly to as.POSIXct(), which can shift the
  # requested date in zones west of UTC. Explicit local midnight preserves the
  # requested site-local date while using the same suntools algorithm.
  result <- suntools::solarnoon(
    crds = matrix(
      c(coordinates_lat_lon[[2L]], coordinates_lat_lon[[1L]]),
      nrow = 1L
    ),
    dateTime = local_midnight,
    POSIXct.out = TRUE
  )
  if (
    nrow(result) != length(dates) ||
      !"time" %in% names(result) ||
      !inherits(result$time, "POSIXct")
  ) {
    abort_pipeline(
      "suntools solar-noon output did not preserve the requested date domain"
    )
  }
  result$time
}

calculate_site_solar_context <- function(
  site_dates,
  site_metadata_row,
  solar_depression_deg
) {
  if (nrow(site_metadata_row) != 1L) {
    abort_pipeline("One metadata row is required per solar-context site")
  }
  site <- site_metadata_row$site[[1L]]
  timezone <- site_metadata_row$timezone[[1L]]
  latitude <- site_metadata_row$latitude_deg[[1L]]
  longitude <- site_metadata_row$longitude_deg[[1L]]
  dates <- site_dates$local_date
  coordinates_lat_lon <- c(latitude, longitude)

  photoperiod <- LightLogR::photoperiod(
    coordinates = coordinates_lat_lon,
    dates = dates,
    tz = timezone,
    solarDep = solar_depression_deg
  )
  solar_noon <- calculate_suntools_solar_noon(
    coordinates_lat_lon = coordinates_lat_lon,
    dates = dates,
    timezone = timezone
  )
  if (
    nrow(photoperiod) != length(dates) ||
      !identical(photoperiod$date, dates) ||
      length(solar_noon) != length(dates)
  ) {
    abort_pipeline(
      "Solar package output did not preserve the requested dates for site %s",
      site
    )
  }
  if (
    any(photoperiod$lat != latitude) ||
      any(photoperiod$lon != longitude)
  ) {
    abort_pipeline(
      "Solar package output changed latitude/longitude order for site %s",
      site
    )
  }
  if (
    any(photoperiod$tz != timezone) ||
      any(photoperiod$solar.angle != -solar_depression_deg)
  ) {
    abort_pipeline(
      "Solar package output changed the time zone or solar boundary for site %s",
      site
    )
  }

  complete_twilight <- is.finite(as.numeric(photoperiod$dawn)) &
    is.finite(as.numeric(photoperiod$dusk))
  incomplete_twilight <- xor(
    is.finite(as.numeric(photoperiod$dawn)),
    is.finite(as.numeric(photoperiod$dusk))
  )
  if (any(incomplete_twilight)) {
    abort_pipeline(
      "Solar package returned only one civil-twilight boundary for site %s",
      site
    )
  }
  if (
    any(
      photoperiod$dusk[complete_twilight] <= photoperiod$dawn[complete_twilight]
    )
  ) {
    abort_pipeline(
      "Civil dusk must follow civil dawn for site %s",
      site
    )
  }
  observed_hours <- as.numeric(photoperiod$photoperiod, units = "hours")
  independent_hours <- as.numeric(
    difftime(photoperiod$dusk, photoperiod$dawn, units = "hours")
  )
  if (
    any(
      abs(
        observed_hours[complete_twilight] -
          independent_hours[complete_twilight]
      ) >
        1e-10
    ) ||
      any(!is.na(observed_hours[!complete_twilight]))
  ) {
    abort_pipeline(
      "Photoperiod duration is inconsistent with civil dawn/dusk for site %s",
      site
    )
  }

  finite_noon <- is.finite(as.numeric(solar_noon))
  if (
    any(
      complete_twilight &
        finite_noon &
        (solar_noon <= photoperiod$dawn |
          solar_noon >= photoperiod$dusk)
    )
  ) {
    abort_pipeline(
      "Solar noon falls outside civil dawn/dusk for site %s",
      site
    )
  }

  event_dates <- list(
    civil_dawn = as.Date(photoperiod$dawn, tz = timezone),
    civil_dusk = as.Date(photoperiod$dusk, tz = timezone),
    solar_noon = as.Date(solar_noon, tz = timezone)
  )
  invalid_event_date <- vapply(
    event_dates,
    function(event_date) {
      any(!is.na(event_date) & event_date != dates)
    },
    logical(1)
  )
  if (any(invalid_event_date)) {
    abort_pipeline(
      "Solar event date differs from requested local date for site %s: %s",
      site,
      paste(names(invalid_event_date)[invalid_event_date], collapse = ", ")
    )
  }

  metadata <- site_metadata_row[
    rep.int(1L, length(dates)),
    ,
    drop = FALSE
  ]
  tibble::as_tibble(metadata) |>
    dplyr::mutate(
      local_date = dates,
      solar_context_definition = "civil_dawn_to_civil_dusk",
      solar_noon_role = "contextual_metadata_only",
      solar_depression_deg = as.numeric(solar_depression_deg),
      solar_altitude_boundary_deg = -as.numeric(solar_depression_deg),
      photoperiod_hours = observed_hours
    ) |>
    dplyr::bind_cols(
      solar_event_fields(
        photoperiod$dawn,
        timezone = timezone,
        prefix = "civil_dawn_"
      ),
      solar_event_fields(
        photoperiod$dusk,
        timezone = timezone,
        prefix = "civil_dusk_"
      ),
      solar_event_fields(
        solar_noon,
        timezone = timezone,
        prefix = "solar_noon_"
      ),
      local_day_fields(dates, timezone = timezone)
    )
}

build_site_solar_context <- function(
  site_dates,
  site_metadata,
  solar_depression_deg = 6
) {
  validate_site_date_domain(site_dates, site_metadata)
  if (
    !is.numeric(solar_depression_deg) ||
      length(solar_depression_deg) != 1L ||
      is.na(solar_depression_deg) ||
      !is.finite(solar_depression_deg) ||
      solar_depression_deg != 6
  ) {
    abort_pipeline(
      paste0(
        "`solar_depression_deg` must equal 6 for the canonical ",
        "civil-dawn/civil-dusk context"
      )
    )
  }
  validate_solar_context_runtime()

  # Reconstruct the domain explicitly so provenance attributes inherited from
  # upstream metric artifacts cannot make value-identical keys compare unequal.
  domain <- tibble::tibble(
    site = as.character(site_dates$site),
    local_date = as.Date(site_dates$local_date)
  ) |>
    dplyr::arrange(.data$site, .data$local_date)
  sites <- unique(domain$site)
  rows <- lapply(sites, function(site) {
    site_domain <- domain[domain$site == site, , drop = FALSE]
    metadata_row <- site_metadata[
      site_metadata$site == site,
      ,
      drop = FALSE
    ]
    calculate_site_solar_context(
      site_dates = site_domain,
      site_metadata_row = metadata_row,
      solar_depression_deg = solar_depression_deg
    )
  })
  output <- dplyr::bind_rows(rows) |>
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

  assert_unique_key(
    output,
    c("site", "local_date"),
    object = "site solar context"
  )
  expected_keys <- domain |>
    dplyr::arrange(.data$site, .data$local_date)
  observed_keys <- output |>
    dplyr::select(dplyr::all_of(c("site", "local_date"))) |>
    dplyr::arrange(.data$site, .data$local_date)
  if (!identical(as.data.frame(observed_keys), as.data.frame(expected_keys))) {
    abort_pipeline(
      "Site solar context does not exactly cover the requested site-date domain"
    )
  }
  if (
    !identical(lubridate::tz(output$civil_dawn_utc), "UTC") ||
      !identical(lubridate::tz(output$civil_dusk_utc), "UTC") ||
      !identical(lubridate::tz(output$solar_noon_utc), "UTC") ||
      !identical(lubridate::tz(output$local_day_start_utc), "UTC") ||
      !identical(lubridate::tz(output$next_local_day_start_utc), "UTC")
  ) {
    abort_pipeline("All true-instant solar columns must use UTC")
  }
  output
}
