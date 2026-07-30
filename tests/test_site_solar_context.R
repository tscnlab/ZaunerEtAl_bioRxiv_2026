options(warn = 2)

source("scripts/pipeline/assertions.R")
source("scripts/pipeline/site_solar_context.R")

message("Testing pinned site-metadata provenance")
site_metadata <- read_site_metadata("config/site_metadata.csv")
site_sources <- utils::read.csv(
  "config/site_sources.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8"
)
stopifnot(
  nrow(site_metadata) == 9L,
  identical(sort(site_metadata$site), sort(expected_site_codes())),
  !anyDuplicated(site_metadata$site),
  all(site_metadata$coordinate_order == "latitude_longitude"),
  all(site_metadata$coordinate_source == "melidosData::melidos_coordinates"),
  all(site_metadata$coordinate_source_version == "1.0.6"),
  all(site_metadata$site_manifest_source == "config/site_sources.csv")
)

source_rows <- match(site_metadata$site, site_sources$site)
stopifnot(
  !anyNA(source_rows),
  identical(site_metadata$location, site_sources$location[source_rows]),
  identical(site_metadata$timezone, site_sources$timezone[source_rows]),
  identical(
    site_metadata$site_release_repository,
    site_sources$repository[source_rows]
  ),
  identical(
    site_metadata$site_release_commit,
    site_sources$commit[source_rows]
  ),
  identical(site_metadata$site_release_doi, site_sources$doi[source_rows])
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
for (site in site_metadata$site) {
  metadata_row <- site_metadata[site_metadata$site == site, , drop = FALSE]
  stopifnot(
    isTRUE(all.equal(
      c(metadata_row$latitude_deg, metadata_row$longitude_deg),
      unname(coordinate_reference[[site]]),
      tolerance = 0
    ))
  )
}

message("Testing ordinary and DST-boundary site-date calculations")
ordinary_domain <- tibble::tibble(
  site = site_metadata$site,
  local_date = as.Date("2024-06-15")
)
dst_domain <- tibble::tibble(
  site = "TUM",
  local_date = as.Date(c("2024-03-31", "2024-10-27"))
)
site_dates <- dplyr::bind_rows(ordinary_domain, dst_domain)
solar_context <- build_site_solar_context(
  site_dates = site_dates,
  site_metadata = site_metadata
)
solar_context_repeat <- build_site_solar_context(
  site_dates = site_dates,
  site_metadata = site_metadata
)
attributed_site_dates <- site_dates
attr(attributed_site_dates, "metric_settings") <- tibble::tibble(
  profile_variant = "pooled"
)
attr(attributed_site_dates, "input_sha256") <- c(
  metrics = paste(rep("a", 64L), collapse = "")
)
solar_context_from_attributed_domain <- build_site_solar_context(
  site_dates = attributed_site_dates,
  site_metadata = site_metadata
)
stopifnot(
  identical(solar_context, solar_context_repeat),
  identical(solar_context, solar_context_from_attributed_domain),
  nrow(solar_context) == nrow(site_dates),
  !anyDuplicated(solar_context[c("site", "local_date")]),
  inherits(solar_context$local_date, "Date"),
  identical(lubridate::tz(solar_context$civil_dawn_utc), "UTC"),
  identical(lubridate::tz(solar_context$civil_dusk_utc), "UTC"),
  identical(lubridate::tz(solar_context$solar_noon_utc), "UTC"),
  identical(lubridate::tz(solar_context$local_day_start_utc), "UTC"),
  identical(lubridate::tz(solar_context$next_local_day_start_utc), "UTC"),
  all(solar_context$solar_depression_deg == 6),
  all(solar_context$solar_altitude_boundary_deg == -6),
  all(solar_context$solar_noon_role == "contextual_metadata_only"),
  all(solar_context$photoperiod_hours > 0),
  all(solar_context$photoperiod_hours < 24),
  all(solar_context$civil_dawn_wall_minute >= 0),
  all(solar_context$civil_dawn_wall_minute < 1440),
  all(solar_context$civil_dusk_wall_minute >= 0),
  all(solar_context$civil_dusk_wall_minute < 1440),
  all(solar_context$solar_noon_wall_minute >= 0),
  all(solar_context$solar_noon_wall_minute < 1440),
  all(solar_context$lightlogr_version == "0.10.3"),
  all(solar_context$suntools_version == "1.1.0"),
  all(solar_context$r_version == "4.6.1")
)

message("Testing equality to LightLogR and suntools calculations")
for (index in seq_len(nrow(solar_context))) {
  observed <- solar_context[index, , drop = FALSE]
  coordinates <- c(observed$latitude_deg, observed$longitude_deg)
  expected_photoperiod <- LightLogR::photoperiod(
    coordinates = coordinates,
    dates = observed$local_date,
    tz = observed$timezone,
    solarDep = 6
  )
  expected_noon <- suntools::solarnoon(
    crds = matrix(
      c(observed$longitude_deg, observed$latitude_deg),
      nrow = 1L
    ),
    dateTime = as.POSIXct(
      paste(format(observed$local_date, "%Y-%m-%d"), "00:00:00"),
      tz = observed$timezone
    ),
    POSIXct.out = TRUE
  )
  expected_dawn_utc <- as_true_utc(expected_photoperiod$dawn)
  expected_dusk_utc <- as_true_utc(expected_photoperiod$dusk)
  expected_noon_utc <- as_true_utc(expected_noon$time)
  expected_dawn_fields <- as.POSIXlt(
    expected_photoperiod$dawn,
    tz = observed$timezone
  )
  expected_dusk_fields <- as.POSIXlt(
    expected_photoperiod$dusk,
    tz = observed$timezone
  )
  expected_noon_fields <- as.POSIXlt(
    expected_noon$time,
    tz = observed$timezone
  )
  stopifnot(
    identical(observed$civil_dawn_utc, expected_dawn_utc),
    identical(observed$civil_dusk_utc, expected_dusk_utc),
    identical(observed$solar_noon_utc, expected_noon_utc),
    identical(
      observed$civil_dawn_local_label,
      format(
        expected_photoperiod$dawn,
        "%Y-%m-%dT%H:%M:%OS6%z",
        tz = observed$timezone
      )
    ),
    isTRUE(all.equal(
      observed$photoperiod_hours,
      as.numeric(expected_photoperiod$photoperiod, units = "hours"),
      tolerance = 1e-12
    )),
    isTRUE(all.equal(
      observed$civil_dawn_wall_minute,
      expected_dawn_fields$hour *
        60 +
        expected_dawn_fields$min +
        expected_dawn_fields$sec / 60,
      tolerance = 1e-12
    )),
    isTRUE(all.equal(
      observed$civil_dusk_wall_minute,
      expected_dusk_fields$hour *
        60 +
        expected_dusk_fields$min +
        expected_dusk_fields$sec / 60,
      tolerance = 1e-12
    )),
    isTRUE(all.equal(
      observed$solar_noon_wall_minute,
      expected_noon_fields$hour *
        60 +
        expected_noon_fields$min +
        expected_noon_fields$sec / 60,
      tolerance = 1e-12
    ))
  )
}

ucr <- solar_context[
  solar_context$site == "UCR" &
    solar_context$local_date == as.Date("2024-06-15"),
  ,
  drop = FALSE
]
stopifnot(
  as.Date(ucr$solar_noon_utc, tz = ucr$timezone) == ucr$local_date
)

tum_metadata <- site_metadata[
  site_metadata$site == "TUM",
  ,
  drop = FALSE
]
direct_test_dates <- as.Date(c("2024-03-31", "2024-10-27"))
for (date_index in seq_along(direct_test_dates)) {
  date <- direct_test_dates[[date_index]]
  date_time <- as.POSIXct(
    paste(format(date, "%Y-%m-%d"), "00:00:00"),
    tz = tum_metadata$timezone
  )
  coordinate_matrix_lon_lat <- matrix(
    c(tum_metadata$longitude_deg, tum_metadata$latitude_deg),
    nrow = 1L
  )
  direct_dawn <- suntools::crepuscule(
    crds = coordinate_matrix_lon_lat,
    dateTime = date_time,
    solarDep = 6,
    direction = "dawn",
    POSIXct.out = TRUE
  )$time
  direct_dusk <- suntools::crepuscule(
    crds = coordinate_matrix_lon_lat,
    dateTime = date_time,
    solarDep = 6,
    direction = "dusk",
    POSIXct.out = TRUE
  )$time
  direct_noon <- suntools::solarnoon(
    crds = coordinate_matrix_lon_lat,
    dateTime = date_time,
    POSIXct.out = TRUE
  )$time
  observed <- solar_context[
    solar_context$site == "TUM" &
      solar_context$local_date == date,
    ,
    drop = FALSE
  ]
  stopifnot(
    identical(observed$civil_dawn_utc, as_true_utc(direct_dawn)),
    identical(observed$civil_dusk_utc, as_true_utc(direct_dusk)),
    identical(observed$solar_noon_utc, as_true_utc(direct_noon))
  )
}

spring <- solar_context[
  solar_context$site == "TUM" &
    solar_context$local_date == as.Date("2024-03-31"),
  ,
  drop = FALSE
]
fall <- solar_context[
  solar_context$site == "TUM" &
    solar_context$local_date == as.Date("2024-10-27"),
  ,
  drop = FALSE
]
stopifnot(
  spring$local_day_real_hours == 23,
  fall$local_day_real_hours == 25,
  spring$local_day_crosses_dst,
  fall$local_day_crosses_dst,
  spring$local_day_start_utc_offset_minutes == 60L,
  spring$local_day_end_utc_offset_minutes == 120L,
  fall$local_day_start_utc_offset_minutes == 120L,
  fall$local_day_end_utc_offset_minutes == 60L,
  spring$civil_dawn_utc_offset_minutes == 120L,
  spring$civil_dawn_is_dst,
  fall$civil_dawn_utc_offset_minutes == 60L,
  !fall$civil_dawn_is_dst
)

message("Testing site/date boundary failures")
duplicate_domain <- dplyr::bind_rows(site_dates[1L, ], site_dates[1L, ])
duplicate_error <- tryCatch(
  {
    build_site_solar_context(duplicate_domain, site_metadata)
    FALSE
  },
  error = function(error) TRUE
)
unknown_site_error <- tryCatch(
  {
    build_site_solar_context(
      tibble::tibble(
        site = "UNKNOWN",
        local_date = as.Date("2024-06-15")
      ),
      site_metadata
    )
    FALSE
  },
  error = function(error) TRUE
)
character_date_error <- tryCatch(
  {
    build_site_solar_context(
      tibble::tibble(
        site = "TUM",
        local_date = "2024-06-15"
      ),
      site_metadata
    )
    FALSE
  },
  error = function(error) TRUE
)
wrong_boundary_error <- tryCatch(
  {
    build_site_solar_context(
      tibble::tibble(
        site = "TUM",
        local_date = as.Date("2024-06-15")
      ),
      site_metadata,
      solar_depression_deg = 0
    )
    FALSE
  },
  error = function(error) TRUE
)
wrong_coordinate_order <- site_metadata
wrong_coordinate_order$coordinate_order[
  wrong_coordinate_order$site == "TUM"
] <- "longitude_latitude"
coordinate_order_error <- tryCatch(
  {
    build_site_solar_context(
      tibble::tibble(
        site = "TUM",
        local_date = as.Date("2024-06-15")
      ),
      wrong_coordinate_order
    )
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(
  duplicate_error,
  unknown_site_error,
  character_date_error,
  wrong_boundary_error,
  coordinate_order_error
)

message("Site solar-context tests passed")
