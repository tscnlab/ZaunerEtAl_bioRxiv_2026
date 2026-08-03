# Clean-session verification for the Nature Health descriptive rebuild.

options(warn = 2)

test_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (all(file.exists(file.path(current, c("_quarto.yml", "renv.lock"))))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) stop("Could not locate project root")
    current <- parent
  }
}

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

assert_identical <- function(observed, expected, message) {
  if (!identical(observed, expected)) {
    stop(
      message,
      "\nObserved: ", paste(observed, collapse = ", "),
      "\nExpected: ", paste(expected, collapse = ", "),
      call. = FALSE
    )
  }
}

assert_close <- function(observed, expected, tolerance, message) {
  if (
    length(observed) != length(expected) ||
      any(!is.finite(observed) != !is.finite(expected)) ||
      any(abs(observed - expected) > tolerance, na.rm = TRUE)
  ) {
    stop(message, call. = FALSE)
  }
}

find_raw_sequence <- function(haystack, needle) {
  if (!length(needle) || length(needle) > length(haystack)) {
    return(integer())
  }
  candidates <- which(haystack == needle[[1L]])
  candidates <- candidates[
    candidates + length(needle) - 1L <= length(haystack)
  ]
  candidates[vapply(
    candidates,
    function(index) identical(
      haystack[index:(index + length(needle) - 1L)], needle
    ),
    logical(1)
  )]
}

read_pdf_raster_contract <- function(path) {
  bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  if (
    length(bytes) < 5L ||
      !identical(bytes[seq_len(5L)], charToRaw("%PDF-"))
  ) {
    stop("Not a PDF file: ", path, call. = FALSE)
  }

  media_index <- find_raw_sequence(bytes, charToRaw("/MediaBox ["))[[1L]]
  media_window <- bytes[
    media_index:min(length(bytes), media_index + 100L)
  ]
  media_end <- which(media_window %in% as.raw(c(10L, 13L)))[[1L]]
  media_text <- rawToChar(media_window[seq_len(media_end - 1L)])
  media_values <- as.numeric(regmatches(
    media_text, gregexpr("[0-9.]+", media_text)
  )[[1L]])

  image_index <- find_raw_sequence(bytes, charToRaw("/Subtype /Image"))[[1L]]
  image_window <- bytes[
    image_index:min(length(bytes), image_index + 500L)
  ]
  stream_index <- find_raw_sequence(image_window, charToRaw("stream"))[[1L]]
  image_text <- rawToChar(image_window[seq_len(stream_index - 1L)])
  extract_integer <- function(pattern) {
    match <- regexec(pattern, image_text, perl = TRUE)
    values <- regmatches(image_text, match)[[1L]]
    if (length(values) != 2L) {
      stop("Missing raster metadata in PDF: ", path, call. = FALSE)
    }
    as.integer(values[[2L]])
  }

  c(
    page_width_pt = media_values[[3L]],
    page_height_pt = media_values[[4L]],
    image_width_px = extract_integer("/Width[[:space:]]+([0-9]+)"),
    image_height_px = extract_integer("/Height[[:space:]]+([0-9]+)")
  )
}

read_jpeg_dimensions <- function(path) {
  bytes <- as.integer(readBin(path, what = "raw", n = file.info(path)$size))
  if (
    length(bytes) < 4L ||
      !identical(bytes[1:2], c(255L, 216L)) ||
      !identical(utils::tail(bytes, 2L), c(255L, 217L))
  ) {
    stop("Not a complete JPEG file: ", path, call. = FALSE)
  }
  start_of_frame <- c(192:195, 197:199, 201:203, 205:207)
  standalone <- c(1L, 208:217)
  position <- 3L
  while (position <= length(bytes)) {
    while (position <= length(bytes) && bytes[[position]] != 255L) {
      position <- position + 1L
    }
    while (position <= length(bytes) && bytes[[position]] == 255L) {
      position <- position + 1L
    }
    if (position > length(bytes)) break
    marker <- bytes[[position]]
    position <- position + 1L
    if (marker %in% standalone) next
    if (position + 1L > length(bytes)) break
    segment_length <- bytes[[position]] * 256L + bytes[[position + 1L]]
    if (marker %in% start_of_frame) {
      return(c(
        width_px = bytes[[position + 5L]] * 256L +
          bytes[[position + 6L]],
        height_px = bytes[[position + 3L]] * 256L +
          bytes[[position + 4L]]
      ))
    }
    position <- position + segment_length
  }
  stop("No JPEG start-of-frame marker found: ", path, call. = FALSE)
}

root <- test_root()
source(file.path(root, "scripts", "descriptives", "build_descriptives.R"))
source_descriptive_modules(root)
check_descriptive_packages()

paths <- descriptive_paths(root)
manifest_checks <- verify_descriptive_manifests(root)
input_checks <- verify_descriptive_inputs(root)
assert_true(all(manifest_checks$status == "PASS"), "A shared manifest failed")
assert_true(all(input_checks$status == "PASS"), "A prepared input failed")
assert_true(
  !any(startsWith(manifest_checks$path, "/")),
  "Stored shared-manifest verification contains an absolute local path"
)
assert_true(
  !any(startsWith(input_checks$path, "/")),
  "Stored descriptive input provenance contains an absolute local path"
)

# DISPLAY-001 is the single authority for reader-facing site labels, order,
# and colours.
registry_file <- utils::read.csv(
  file.path(root, "config", "site_display_registry.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8"
)
registry <- descriptive_site_display_registry()
assert_identical(registry, registry_file[order(registry_file$display_order), ],
                 "The descriptive display registry differs from DISPLAY-001")
assert_identical(descriptive_site_order(), registry$site,
                 "Site order does not come from DISPLAY-001")
assert_identical(
  descriptive_site_reader_labels(),
  stats::setNames(registry$display_name, registry$site),
  "Reader site labels do not come from DISPLAY-001"
)
assert_identical(
  descriptive_site_palette(),
  stats::setNames(registry$color_hex, registry$site),
  "Site colours do not come from DISPLAY-001"
)
contract_text <- readLines(
  file.path(root, "scripts", "descriptives", "descriptive_contract.R"),
  warn = FALSE
)
assert_true(
  !any(vapply(
    registry$color_hex,
    function(colour) any(grepl(colour, contract_text, fixed = TRUE)),
    logical(1)
  )),
  "A registered colour is duplicated in the descriptive contract"
)

inputs <- load_descriptive_inputs(root)
validate_descriptive_inputs(inputs)

# Fixed sample and unique-key contracts.
assert_true(dplyr::n_distinct(inputs$demographics$Id) == 191L,
            "Normalized participant roster is not 191")
key <- c("site", "Id", "local_date")
for (placement in c("near_eye", "chest")) {
  data <- inputs$participant_day[[placement]]
  assert_true(!anyDuplicated(data[key]), paste("Duplicate participant-day key:", placement))
}
assert_true(nrow(inputs$participant_day$near_eye) == 816L,
            "Near-eye main participant-days are not 816")
assert_true(dplyr::n_distinct(inputs$participant_day$near_eye$Id) == 141L,
            "Near-eye main participants are not 141")
assert_true(nrow(inputs$participant_day$chest) == 902L,
            "Chest main participant-days are not 902")
assert_true(dplyr::n_distinct(inputs$participant_day$chest$Id) == 154L,
            "Chest main participants are not 154")
assert_true(
  sum(inputs$daily_coverage$near_eye$day_eligible_without_all_zero_screen) == 818L &&
    sum(inputs$daily_coverage$near_eye$day_all_zero_medi_excluded) == 2L,
  "Near-eye all-zero sample flow is not 818 - 2 = 816"
)
assert_true(
  sum(inputs$daily_coverage$chest$day_eligible_without_all_zero_screen) == 905L &&
    sum(inputs$daily_coverage$chest$day_all_zero_medi_excluded) == 3L,
  "Chest all-zero sample flow is not 905 - 3 = 902"
)
assert_true(sum(inputs$coverage$near_eye$day_eligible) == 1175160L,
            "Near-eye eligible real-minute rows are not 1,175,160")
assert_true(sum(inputs$coverage$chest$day_eligible) == 1298880L,
            "Chest eligible real-minute rows are not 1,298,880")

collection_days <- build_collection_days(inputs)
assert_true(!anyDuplicated(collection_days[c("placement", key)]),
            "Collection-day output has duplicate placement-day keys")
paired_near <- dplyr::filter(
  collection_days, .data$placement == "near_eye", .data$paired_day
)
assert_true(nrow(paired_near) == 643L, "Paired participant-days are not 643")
assert_true(dplyr::n_distinct(paired_near$Id) == 112L,
            "Paired participants are not 112")

available_collection_days <- build_available_collection_days(inputs)
assert_true(
  nrow(available_collection_days) == 2380L &&
    !anyDuplicated(available_collection_days[c("placement", key)]),
  "Available collection days are not the 2,380 unique placement-day keys"
)
available_union <- available_collection_days |>
  dplyr::distinct(.data$site, .data$Id, .data$local_date)
assert_true(
  nrow(available_union) == 1478L &&
    dplyr::n_distinct(available_union$Id) == 184L,
  "The roster-wide available union is not 1,478 days from 184 participants"
)
available_paired <- available_collection_days |>
  dplyr::filter(.data$placement == "near_eye", .data$paired_available)
assert_true(
  nrow(available_paired) == 902L &&
    dplyr::n_distinct(available_paired$Id) == 116L,
  "Available paired coverage is not 902 days from 116 participants"
)
assert_true(
  !anyNA(available_collection_days$photoperiod_hours) &&
    all(available_collection_days$solar_depression_deg == 6),
  "An available non-all-zero day lacks canonical civil-twilight context"
)
collection_intervals <- build_collection_intervals(
  available_collection_days,
  pause_days = 6L
)
interval_gaps <- collection_intervals |>
  dplyr::group_by(.data$site) |>
  dplyr::arrange(.data$interval_start, .by_group = TRUE) |>
  dplyr::mutate(
    missing_dates_before = as.integer(
      .data$interval_start - dplyr::lag(.data$interval_end)
    ) - 1L
  ) |>
  dplyr::filter(!is.na(.data$missing_dates_before)) |>
  dplyr::ungroup()
assert_true(
  nrow(collection_intervals) == 37L &&
    all(interval_gaps$missing_dates_before >= 6L),
  "Collection rectangles are not split after pauses of at least six dates"
)

# Rebuilt table keys, sizes, order, and denominators.
site_sample <- build_site_sample_characteristics(
  inputs, collection_days, available_collection_days
)
participant_replica <- build_participant_site_replica(
  inputs, site_sample, available_collection_days
)
assert_true(nrow(participant_replica) == 220L,
            "Participant/site replica is not 22 by 10")
assert_true(!anyDuplicated(participant_replica[c("characteristic", "site")]),
            "Participant/site table key is duplicated")
assert_identical(
  as.character(participant_replica$site[participant_replica$characteristic == "Institution"]),
  replica_site_levels(),
  "Participant/site columns do not follow DISPLAY-001"
)
overall_participant_rows <- dplyr::filter(
  participant_replica,
  as.character(.data$site) == "Overall"
)
assert_identical(
  overall_participant_rows$display[
    overall_participant_rows$characteristic == "Participants"
  ],
  "191 roster (near-eye 143; chest 157; paired 116)",
  "Overall participant display is not roster-wide"
)
assert_identical(
  overall_participant_rows$display[
    overall_participant_rows$characteristic == "Participant-days"
  ],
  "1478 roster (near-eye 1134; chest 1246; paired 902)",
  "Overall participant-day display is not roster-wide"
)
assert_identical(
  overall_participant_rows$display[
    overall_participant_rows$characteristic == "Participant time"
  ],
  "116w 4d",
  "Participant time does not use the screened near-eye total and two units"
)
assert_true(
  "Screened days" %in% participant_replica$characteristic &&
    !"Main-day screen" %in% participant_replica$characteristic,
  "The final screened-day row has the wrong label"
)
assert_true(
  all(
    participant_replica$n_participants[
      participant_replica$characteristic == "Age"
    ] == site_sample$roster_participants
  ),
  "Participant information does not cover the whole roster"
)
manuscript_participant_replica <- participant_site_manuscript_data(
  participant_replica
)
assert_true(
  nrow(manuscript_participant_replica) == 150L &&
    !any(
      manuscript_participant_replica$characteristic %in%
        participant_site_manuscript_exclusions()
    ),
  "The manuscript Table 1 variant does not contain the exact reduced row set"
)
assert_identical(
  unique(manuscript_participant_replica$characteristic),
  setdiff(
    unique(participant_replica$characteristic),
    participant_site_manuscript_exclusions()
  ),
  "The manuscript Table 1 variant changed the retained row order"
)

metric_values <- build_metric_values(inputs)
metric_summary <- build_metric_summary(metric_values)
metric_replica <- build_metric_replica(metric_summary)
assert_true(nrow(metric_replica) == 170L, "Metric replica is not 17 by 10")
assert_true(!anyDuplicated(metric_replica[c("metric_id", "site")]),
            "Metric table key is duplicated")
assert_true(all(metric_replica$n_observations > 0),
            "A metric row has no observations")
assert_true(all(metric_replica$n_participants > 0),
            "A metric row has no participants")
assert_true(all(metric_replica$n_participant_days > 0),
            "A metric row has no participant-days")
assert_true(
  all(c("sd", "sd_formatted") %in% names(metric_replica)) &&
    all(is.finite(metric_replica$sd)) &&
    all(nzchar(metric_replica$sd_formatted)),
  "A metric cell lacks its arithmetic or circular standard deviation"
)
duration_rows <- grepl("duration|longest_bout", metric_replica$metric_id)
assert_identical(
  metric_replica$sd_formatted[duration_rows],
  vapply(
    metric_replica$sd[duration_rows],
    format_duration_hours,
    character(1)
  ),
  "A duration standard deviation is not formatted in the metric's hour unit"
)
timing_rows <- grepl("timing|midpoint", metric_replica$metric_id)
assert_true(all(is.finite(metric_replica$circular_resultant[timing_rows])),
            "A timing row lacks a circular resultant")
assert_true(all(is.na(metric_replica$circular_resultant[!timing_rows])),
            "A non-timing row unexpectedly has a circular resultant")

# Independent circular check for the overall mean-timing metric.
timing_values <- metric_values |>
  dplyr::filter(
    .data$placement == "near_eye",
    .data$metric_id == "mean_timing_above_250",
    .data$finite,
    is.finite(.data$value)
  ) |>
  dplyr::pull("value")
angles <- 2 * pi * timing_values / 1440
direct_center <- (atan2(mean(sin(angles)), mean(cos(angles))) %% (2 * pi)) *
  1440 / (2 * pi)
direct_difference <- (timing_values - direct_center + 720) %% 1440 - 720
direct_quantiles <- stats::quantile(
  direct_difference,
  probs = c(0.25, 0.5, 0.75),
  names = FALSE,
  type = 7L
)
direct_stats <- c(
  mean = direct_center,
  q1 = (direct_center + direct_quantiles[[1L]]) %% 1440,
  median = (direct_center + direct_quantiles[[2L]]) %% 1440,
  q3 = (direct_center + direct_quantiles[[3L]]) %% 1440,
  resultant = sqrt(mean(cos(angles))^2 + mean(sin(angles))^2)
)
observed_timing <- metric_replica |>
  dplyr::filter(
    as.character(.data$site) == "Overall",
    .data$metric_id == "mean_timing_above_250"
  )
assert_close(
  unlist(observed_timing[c("mean", "q1", "median", "q3", "circular_resultant")]),
  direct_stats,
  1e-10,
  "Circular metric statistics differ from the independent calculation"
)
assert_true(
  observed_timing$n_observations == 742L &&
    observed_timing$n_participants == 141L &&
    observed_timing$n_participant_days == 742L,
  "Overall mean-timing denominator is incorrect"
)

# The recreated daily profiles use pooled fixed 15-minute LightLogR summaries,
# the requested nested value intervals, and one average period row per
# displayed placement/site panel.
profiles <- build_profile_sources(inputs)
assert_true(
  nrow(profiles$profile) == 1824L &&
    nrow(profiles$state) == 5472L &&
    nrow(profiles$period) == 19L,
  "The 15-minute profile source dimensions are incorrect"
)
profile_bins <- sort(unique(profiles$profile$clock_minute))
assert_true(
  length(profile_bins) == 96L &&
    all(diff(profile_bins) == 15) &&
    identical(profile_bins[[1L]], 0),
  "Profile values are not aggregated to the fixed 15-minute grid"
)
assert_true(
  all(grepl("LightLogR::aggregate_Datetime", profiles$profile$aggregation_method,
            fixed = TRUE)) &&
    setequal(unique(profiles$state$context), c("wake", "pre_sleep", "sleep")) &&
    !"declared_nonwear" %in% unique(profiles$state$context),
  "The profile sources do not use the requested pooling or diary-state display"
)
assert_true(
  all(profiles$profile$interval_levels == "0.50;0.67;0.75;0.95") &&
    all(
      profiles$profile$value_lower_95_lx <=
        profiles$profile$value_lower_75_lx |
        is.na(profiles$profile$median_lx)
    ) &&
    all(
      profiles$profile$value_lower_75_lx <=
        profiles$profile$value_lower_67_lx |
        is.na(profiles$profile$median_lx)
    ) &&
    all(
      profiles$profile$value_lower_67_lx <=
        profiles$profile$value_lower_50_lx |
        is.na(profiles$profile$median_lx)
    ) &&
    all(
      profiles$profile$value_lower_50_lx <= profiles$profile$median_lx |
        is.na(profiles$profile$median_lx)
    ) &&
    all(
      profiles$profile$value_upper_50_lx >= profiles$profile$median_lx |
        is.na(profiles$profile$median_lx)
    ) &&
    all(
      profiles$profile$value_upper_67_lx >=
        profiles$profile$value_upper_50_lx |
        is.na(profiles$profile$median_lx)
    ) &&
    all(
      profiles$profile$value_upper_75_lx >=
        profiles$profile$value_upper_67_lx |
        is.na(profiles$profile$median_lx)
    ) &&
    all(
      profiles$profile$value_upper_95_lx >=
        profiles$profile$value_upper_75_lx |
        is.na(profiles$profile$median_lx)
    ),
  "A profile does not carry valid nested 50%, 67%, 75%, and 95% intervals"
)
period_values <- unlist(profiles$period[c(
  "mean_sleep_start_minute", "mean_sleep_end_minute",
  "mean_civil_dawn_minute", "mean_civil_dusk_minute"
)])
assert_true(
  all(is.finite(period_values)) && all(period_values %% 15 == 0),
  "Average sleep or civil-twilight periods are not on the 15-minute grid"
)

# Contextual table: each denominator is explicit and each fraction reproduces
# the detailed one-minute state summary.
recommendation <- build_recommendation_context(inputs)
recommendation_replica <- build_recommendation_replica(recommendation)
assert_true(nrow(recommendation_replica) == 10L,
            "Contextual replica does not contain Overall plus nine sites")
assert_identical(as.character(recommendation_replica$site), replica_site_levels(),
                 "Contextual table site order is incorrect")
overall_context <- dplyr::filter(
  recommendation_replica, as.character(.data$site) == "Overall"
)
assert_close(
  unlist(overall_context[c("wake_fraction", "pre_sleep_fraction", "sleep_fraction")]),
  c(137792 / 573712, 81894 / 129390, 336052 / 383366),
  1e-12,
  "Overall contextual fractions changed"
)
detail_overall <- dplyr::filter(
  recommendation, as.character(.data$site) == "Overall"
)
assert_close(
  overall_context$combined_fraction,
  sum(detail_overall$n_minutes_in_contextual_range) /
    sum(detail_overall$n_valid_one_minute_observations),
  1e-12,
  "Combined contextual denominator is incorrect"
)
assert_close(
  overall_context$unclassified_time_fraction,
  1 - sum(detail_overall$state_fraction_of_eligible_minutes),
  1e-12,
  "Unclassified eligible-time fraction is incorrect"
)
assert_true(
  overall_context$wake_context_numerator == 137792L &&
    overall_context$pre_sleep_context_numerator == 81894L &&
    overall_context$sleep_context_numerator == 336052L &&
    overall_context$wake_time_numerator +
      overall_context$pre_sleep_time_numerator +
      overall_context$sleep_time_numerator +
      overall_context$unclassified_time_numerator ==
      overall_context$eligible_real_minutes,
  "The recommendation-table numerator/denominator display inputs are incorrect"
)

# Same seven examples and study days, using the pinned gap-timing-unaware
# 30-minute samples and TAT250 calculated from the displayed daytime bins.
time_series <- build_time_series_replica_sources(root)
assert_true(nrow(time_series$selected) == 35L,
            "Time-series selection is not seven by five")
expected_time_series_order <- c(
  "MPI_S226", "BAUA_S003", "MPI_S227", "BAUA_S022",
  "MPI_S205", "TUM_S009", "BAUA_S009"
)
assert_identical(
  unique(time_series$selected$Id), expected_time_series_order,
  "Time-series IDs are not ordered from low to high median TAT250"
)
assert_true(!anyDuplicated(time_series$selected[c("Id", "protocol_day")]),
            "Time-series participant-protocol-day key is duplicated")
assert_true(
  all(vapply(
    split(time_series$selected$study_day, time_series$selected$Id),
    function(value) identical(sort(value), 2:6),
    logical(1)
  )) &&
    all(vapply(
      split(time_series$selected$protocol_day, time_series$selected$Id),
      function(value) identical(sort(value), 1:5),
      logical(1)
    )),
  "Time-series examples do not use the exact submitted study days 2–6"
)
assert_true(nrow(time_series$series) == 1680L,
            "Time-series bundle is not 35 days by 48 bins")
assert_true(nrow(time_series$states) == 1680L,
            "Time-series state bundle is not 35 days by 48 bins")
assert_true(nrow(time_series$metrics) == 35L,
            "Time-series daily metric bundle is not 35 rows")
assert_true(
  all(grepl(
    "Stored floor-aligned 30-minute arithmetic mean",
    time_series$series$aggregation_method,
    fixed = TRUE
  )) &&
    "civil_night" %in% names(time_series$states) &&
    !any(grepl("nonwear", names(time_series$states), fixed = TRUE)),
  "The time-series source is not the stored 30-minute dataset or retains non-wear"
)
recalculated_tat <- time_series$series |>
  dplyr::left_join(
    time_series$states |>
      dplyr::select(
        "participant", "protocol_day", "clock_bin", "civil_night"
      ),
    by = c("participant", "protocol_day", "clock_bin")
  ) |>
  dplyr::filter(!.data$civil_night) |>
  dplyr::group_by(.data$participant, .data$protocol_day) |>
  dplyr::summarise(
    expected = 0.5 * sum(is.finite(.data$melEDI_lx) & .data$melEDI_lx > 250),
    .groups = "drop"
  )
metric_parity <- time_series$metrics |>
  dplyr::left_join(
    recalculated_tat,
    by = c("participant", "protocol_day")
  )
assert_close(
  metric_parity$duration_above_250_daytime_h,
  metric_parity$expected,
  0,
  "TAT250 was not calculated from exactly the displayed daytime samples"
)
assert_identical(
  time_series$provenance$source_sha256,
  gap_timing_unaware_near_eye_contract(root)$expected_sha256,
  "The gap-timing-unaware time-series source hash is not pinned"
)

# Source-data map, durable-output manifest, raster dimensions, PDF page/raster
# contract, and SVG syntax.
source_map <- readr::read_csv(
  file.path(paths$manifest_dir, "figure_source_data_map.csv"),
  show_col_types = FALSE
)
source_hashes <- vapply(
  file.path(root, source_map$source_data_path),
  artifact_sha256,
  character(1)
)
assert_identical(unname(source_hashes), source_map$source_data_sha256,
                 "A figure source-data hash is stale")
bound_source <- readr::read_csv(
  file.path(paths$source_dir, "photoperiod_latitude_bounds.csv"),
  show_col_types = FALSE
)
bound_input_path <- file.path(
  root,
  "artifacts/11_source_data/H01/stage3/H01_stage3_photoperiod_latitude_bounds.csv"
)
assert_true(
  nrow(bound_source) == nrow(inputs$photoperiod_bounds) &&
    all(bound_source$source_sha256 == artifact_sha256(bound_input_path)) &&
    identical(
      bound_source$minimum_possible_photoperiod_hours,
      inputs$photoperiod_bounds$minimum_possible_photoperiod_hours
    ) &&
    identical(
      bound_source$maximum_possible_photoperiod_hours,
      inputs$photoperiod_bounds$maximum_possible_photoperiod_hours
    ),
  "Figure 5 does not consume the verified current H1 theoretical bounds"
)

artifact_manifest_path <- file.path(paths$manifest_dir, "descriptive_artifacts.csv")
manifest <- readr::read_csv(artifact_manifest_path, show_col_types = FALSE)
absolute_artifacts <- file.path(root, manifest$path)
assert_true(all(file.exists(absolute_artifacts)), "A manifested output is missing")
assert_identical(
  unname(vapply(absolute_artifacts, artifact_sha256, character(1))),
  manifest$sha256,
  "A manifested output hash is stale"
)

spec <- descriptive_figure_spec()
assert_true(all(spec$dpi == 300L), "A figure export is not specified at 300 dpi")
assert_true(
  identical(spec$base_width_in[[1L]], 10.5) &&
    identical(spec$base_height_in[[1L]], 10) &&
    identical(spec$export_scale_multiplier, c(1.5, rep(1, 5))) &&
    identical(spec$export_width_in[[1L]], 15.75) &&
    identical(spec$export_height_in[[1L]], 15) &&
    all(abs(
      spec$export_width_in -
        spec$base_width_in * spec$export_scale_multiplier
    ) < 1e-12) &&
    all(abs(
      spec$export_height_in -
        spec$base_height_in * spec$export_scale_multiplier
    ) < 1e-12) &&
    all(spec$html_out_width == "100%") &&
    all(spec$print_display_width_mm == 170) &&
    all(abs(
      spec$display_reduction_factor -
        (spec$print_display_width_mm / 25.4) / spec$export_width_in
    ) < 1e-12) &&
    all(abs(
      spec$effective_min_essential_text_pt -
        spec$nominal_min_essential_text_pt *
          spec$display_reduction_factor
    ) < 1e-12) &&
    all(spec$effective_min_essential_text_pt[-1L] >= 7),
  "A figure fails the corrected export-scale contract"
)
assert_identical(
  as.integer(
    c(spec$export_width_in[[1L]], spec$export_height_in[[1L]]) *
      spec$dpi[[1L]]
  ),
  c(4725L, 4500L),
  "The corrected Figure 1 raster contract is not 4725 by 4500 pixels"
)
overview_functions <- c(
  "replica_recommendation_bracket", "make_site_map_replica_plot",
  "make_collection_replica_plot", "make_photoperiod_replica_plot",
  "make_overall_profile_replica_plot", "make_overview_replica_figure"
)
assert_true(
  all(vapply(
    overview_functions,
    function(function_name) {
      function_text <- paste(
        deparse(get(function_name, mode = "function")), collapse = "\n"
      )
      !grepl(
        "visual_scale_multiplier|export_scale_multiplier",
        function_text
      )
    },
    logical(1)
  )),
  "A Figure 1 plot function still multiplies fonts or geoms for the pilot"
)
profile_scale <- replica_profile_y_scale(include_context_baseline = TRUE)
assert_identical(
  profile_scale$trans$name,
  "symlog-1-10-1",
  "Figures 1--3 do not use the LightLogR symlog scale with threshold 1"
)
readability_qa <- readr::read_csv(
  file.path(paths$audit_dir, "figure_readability_qa.csv"),
  show_col_types = FALSE
)
assert_identical(
  readability_qa$figure_id,
  spec$figure_id,
  "The physical-size QA does not cover all descriptive figures"
)
assert_true(
  identical(readability_qa$qa_status, spec$physical_size_qa) &&
    identical(readability_qa$export_scale_multiplier, spec$export_scale_multiplier) &&
    identical(
      readability_qa$effective_min_essential_text_pt,
      spec$effective_min_essential_text_pt
    ) &&
    all(!is.na(readability_qa$qa_notes)) &&
    all(nzchar(readability_qa$qa_notes)),
  "A descriptive figure lacks passing A4 100% physical-size QA"
)
metric_axis_labels <- vapply(
  seq_len(nrow(replica_metric_panel_contract())),
  function(index) {
    metric_panel_axis_label(
      replica_metric_panel_contract()[index, , drop = FALSE]
    )
  },
  character(1)
)
assert_true(
  all(nzchar(metric_axis_labels)) && !any(grepl("\n", metric_axis_labels)),
  "Figure 3 metric names are missing or contain line breaks"
)
for (format in c("png", "jpeg", "pdf", "svg")) {
  assert_true(
    sum(
      manifest$artifact_type == paste0("descriptive_figure_", format)
    ) == nrow(spec),
    paste("The output manifest does not contain six figure", format, "files")
  )
}
assert_true(
  sum(manifest$artifact_type == "descriptive_figure_a4_mockup") == nrow(spec),
  "The output manifest does not contain six A4 figure mock-ups"
)
for (i in seq_len(nrow(spec))) {
  figure_id <- spec$figure_id[[i]]
  png_path <- file.path(paths$figure_dir, paste0(figure_id, ".png"))
  jpeg_path <- file.path(paths$figure_dir, paste0(figure_id, ".jpeg"))
  pdf_path <- file.path(paths$figure_dir, paste0(figure_id, ".pdf"))
  svg_path <- file.path(paths$figure_dir, paste0(figure_id, ".svg"))
  expected_pixels <- as.integer(
    c(spec$export_width_in[[i]], spec$export_height_in[[i]]) * spec$dpi[[i]]
  )
  raster <- png::readPNG(png_path, native = FALSE, info = TRUE)
  assert_identical(
    dim(raster)[1:2],
    rev(expected_pixels),
    paste("Unexpected raster dimensions:", figure_id)
  )
  assert_close(
    attributes(raster)$info$dpi,
    rep(spec$dpi[[i]], 2L),
    0.1,
    paste("Unexpected raster DPI:", figure_id)
  )
  assert_identical(
    unname(read_jpeg_dimensions(jpeg_path)),
    expected_pixels,
    paste("Unexpected JPEG dimensions:", figure_id)
  )
  pdf_contract <- read_pdf_raster_contract(pdf_path)
  assert_close(
    unname(pdf_contract[c("page_width_pt", "page_height_pt")]),
    c(spec$export_width_in[[i]], spec$export_height_in[[i]]) * 72,
    # R's PDF devices serialize the MediaBox to whole PostScript points;
    # one point is the tightest meaningful physical-size tolerance here.
    1,
    paste("Unexpected PDF page dimensions:", figure_id)
  )
  assert_identical(
    as.integer(unname(pdf_contract[c("image_width_px", "image_height_px")])),
    expected_pixels,
    paste("Unexpected PDF raster dimensions:", figure_id)
  )
  svg <- xml2::read_xml(svg_path)
  assert_true(
    xml2::xml_name(xml2::xml_root(svg)) == "svg",
    paste("Invalid SVG:", figure_id)
  )
  mockup <- png::readPNG(
    file.path(root, spec$a4_mockup_path[[i]]),
    native = FALSE,
    info = TRUE
  )
  mockup_dpi <- attributes(mockup)$info$dpi
  mockup_size_mm <- c(dim(mockup)[2L], dim(mockup)[1L]) /
    mockup_dpi * 25.4
  assert_close(
    mockup_size_mm,
    c(210, 297),
    0.05,
    paste("The A4 mock-up has the wrong physical size:", figure_id)
  )
}

table_spec_path <- file.path(
  paths$manifest_dir, "table_export_specifications.csv"
)
table_spec <- readr::read_csv(table_spec_path, show_col_types = FALSE)
assert_identical(
  table_spec$table_id,
  c(
    "participant_site_characteristics", "participant_site_manuscript",
    "near_eye_metric_summary", "recommendation_context"
  ),
  "The publication table export set changed"
)
assert_identical(
  as.integer(table_spec$viewport_width_px),
  c(1200L, 1200L, 1800L, 992L),
  "A publication table no longer uses its submitted gtsave viewport"
)
table_png_paths <- file.path(paths$table_dir, table_spec$filename)
assert_true(all(file.exists(table_png_paths)), "A publication table PNG is missing")
table_manifest <- dplyr::filter(
  manifest, .data$artifact_type == "descriptive_table_png"
)
assert_true(
  nrow(table_manifest) == 4L &&
    setequal(table_manifest$table_id, table_spec$table_id),
  "The output manifest does not contain the four publication table PNGs"
)
for (i in seq_len(nrow(table_spec))) {
  rebuilt_dimensions <- read_png_dimensions(table_png_paths[[i]])
  original_dimensions <- read_png_dimensions(
    file.path(root, table_spec$original_path[[i]])
  )
  width_tolerance <- if (
    table_spec$table_id[[i]] == "near_eye_metric_summary"
  ) 0.06 else 0.03
  assert_true(
    all(rebuilt_dimensions > 0) &&
      abs(rebuilt_dimensions[["width_px"]] /
            original_dimensions[["width_px"]] - 1) < width_tolerance,
    paste(
      "Publication table width differs by more than 3% from the submitted render:",
      table_spec$table_id[[i]]
    )
  )
}

visual_comparison <- readr::read_csv(
  file.path(paths$audit_dir, "visual_export_comparison.csv"),
  show_col_types = FALSE
)
assert_identical(
  visual_comparison$output_id,
  c(table_spec$table_id, spec$figure_id),
  "The visual comparison does not cover all four tables and six figures"
)
assert_true(
  nrow(visual_comparison) == 10L &&
    all(file.exists(file.path(root, visual_comparison$original_path))) &&
    all(file.exists(file.path(root, visual_comparison$rebuilt_path))),
  "A side-by-side visual-comparison pair is incomplete"
)
assert_true(
  identical(
    visual_comparison$review_state[
      visual_comparison$output_type == "figure"
    ],
    spec$physical_size_qa
  ),
  "The figure comparison states differ from physical-size and pilot QA"
)
assert_identical(
  unname(vapply(
    file.path(root, visual_comparison$original_path),
    artifact_sha256,
    character(1)
  )),
  visual_comparison$original_sha256,
  "An original visual-comparison hash is stale"
)
assert_identical(
  unname(vapply(
    file.path(root, visual_comparison$rebuilt_path),
    artifact_sha256,
    character(1)
  )),
  visual_comparison$rebuilt_sha256,
  "A rebuilt visual-comparison hash is stale"
)

latitude_svg_text <- paste(
  readLines(
    file.path(paths$figure_dir, "latitude_photoperiod_diagnostic.svg"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
latitude_label_positions <- vapply(
  registry$display_name,
  function(label) regexpr(label, latitude_svg_text, fixed = TRUE)[[1L]],
  integer(1)
)
assert_true(
  all(latitude_label_positions > 0) && all(diff(latitude_label_positions) > 0),
  "The latitude diagnostic does not contain DISPLAY-001 labels in exact order"
)

alt_text <- readr::read_csv(
  file.path(paths$source_dir, "figure_alt_text.csv"),
  show_col_types = FALSE
)
assert_identical(alt_text$figure_id, spec$figure_id,
                 "Figure alt text does not cover the exact figure set")
assert_true(all(nzchar(alt_text$short_alt_text)) && all(nzchar(alt_text$long_description)),
            "A figure lacks alt text or a long description")

# Complete old-to-new comparison coverage.
comparison_expectations <- c(
  previous_table1_comparison.csv = 220L,
  previous_table2_comparison.csv = 170L,
  previous_recommendation_comparison.csv = 80L,
  output_difference_explanations.csv = 22L
)
for (filename in names(comparison_expectations)) {
  data <- readr::read_csv(
    file.path(paths$audit_dir, filename), show_col_types = FALSE
  )
  assert_true(
    nrow(data) == comparison_expectations[[filename]],
    paste("Comparison coverage changed:", filename)
  )
}

# The publication tables are native gt objects over unchanged prepared input.
participant_gt <- build_participant_site_publication_gt(participant_replica)
participant_manuscript_gt <-
  build_participant_site_manuscript_publication_gt(participant_replica)
metric_gt <- build_metric_publication_gt(
  metric_replica, build_metric_plot_values(metric_values)
)
recommendation_gt <- build_recommendation_publication_gt(recommendation_replica)
assert_true(all(vapply(
  list(
    participant_gt, participant_manuscript_gt, metric_gt, recommendation_gt
  ),
  inherits,
  logical(1),
  what = "gt_tbl"
)), "A publication table is not a gt_tbl")
participant_html <- gt::as_raw_html(participant_gt)
participant_manuscript_html <- gt::as_raw_html(participant_manuscript_gt)
metric_html <- gt::as_raw_html(metric_gt)
recommendation_html <- gt::as_raw_html(recommendation_gt)
metric_visible_text <- rvest::html_text2(rvest::read_html(metric_html))
recommendation_visible_text <- rvest::html_text2(
  rvest::read_html(recommendation_html)
)
for (html in list(participant_html, participant_manuscript_html, metric_html)) {
  positions <- vapply(
    registry$display_name,
    function(label) regexpr(label, html, fixed = TRUE)[[1L]],
    integer(1)
  )
  assert_true(all(positions > 0) && all(diff(positions) > 0),
              "A wide gt table violates DISPLAY-001 visible order")
}
recommendation_positions <- vapply(
  registry$display_name,
  function(label) regexpr(label, recommendation_html, fixed = TRUE)[[1L]],
  integer(1)
)
assert_true(
  all(recommendation_positions > 0) && all(diff(recommendation_positions) > 0),
  "The contextual gt table violates DISPLAY-001 visible order"
)
assert_true(
  grepl("white-space\\s*:\\s*nowrap", participant_html, perl = TRUE) &&
    grepl("<br", participant_html, fixed = TRUE) &&
    grepl("(n=", participant_html, fixed = TRUE),
  "Table 1 does not place each trailing sample size on a consistent new line"
)
social_jetlag_baua <- participant_replica |>
  dplyr::filter(.data$characteristic == "Social jetlag", .data$site == "BAUA")
assert_true(
  grepl(
    "white-space:nowrap", participant_display_markdown(
      social_jetlag_baua$display, social_jetlag_baua$characteristic
    ), fixed = TRUE
  ),
  "Table 1 does not keep the BAUA social-jetlag interval bracket together"
)
assert_true(
  !grepl("\\bn\\s*=", metric_visible_text, perl = TRUE) &&
    grepl("N=participants", metric_html, fixed = TRUE) &&
    grepl("d=participant-days", metric_html, fixed = TRUE) &&
    grepl("white-space:nowrap", metric_html, fixed = TRUE),
  "Table 2 does not use intact N/participant-day size lines"
)
assert_true(
  grepl("Minutes in the recommended range:", recommendation_html, fixed = TRUE) &&
    !grepl("display\\s*:\\s*inline-flex", recommendation_html, perl = TRUE) &&
    grepl("137,792 / 573,712", recommendation_visible_text, fixed = TRUE) &&
    !grepl("\\bn\\s*=", recommendation_visible_text, perl = TRUE),
  "The recommendation table does not show literal numerator/denominator fractions"
)
hidden_description_matches <- gregexpr(
  "clip-path:inset(50%)", metric_html, fixed = TRUE
)[[1L]]
aria_hidden_thumbnail_matches <- gregexpr(
  'aria-hidden="true"', metric_html, fixed = TRUE
)[[1L]]
presentation_thumbnail_matches <- gregexpr(
  'role="presentation"', metric_html, fixed = TRUE
)[[1L]]
assert_true(
  sum(hidden_description_matches > 0) == 17L &&
    sum(aria_hidden_thumbnail_matches > 0) == 17L &&
    sum(presentation_thumbnail_matches > 0) == 17L &&
    grepl(
      "Exact numerical summaries are in the adjacent cells.",
      metric_html,
      fixed = TRUE
    ),
  paste(
    "The metric gt table does not contain 17 hidden metric descriptions and",
    "17 decorative thumbnail markers"
  )
)

# Reader-facing terminology and analytical-boundary guardrails.
qmd_text <- paste(readLines(file.path(root, "notebooks", "descriptives.qmd"), warn = FALSE),
                  collapse = "\n")
for (opaque_term in c("legacy", "canonical", "support-aware", "source analysis")) {
  assert_true(!grepl(tolower(opaque_term), tolower(qmd_text), fixed = TRUE),
              paste("Opaque reader-facing term remains:", opaque_term))
}
assert_true(
  grepl("text-align: left !important", qmd_text, fixed = TRUE),
  "The report does not enforce left-aligned table and figure captions"
)
script_paths <- list.files(
  paths$script_dir,
  pattern = "[.]R$",
  full.names = TRUE
)
script_lines <- unlist(lapply(script_paths, readLines, warn = FALSE))
load_lines <- script_lines[
  grepl("\\b(?:base::)?load\\s*\\(", script_lines, perl = TRUE)
]
assert_true(
  length(load_lines) == 1L &&
    grepl(
      "loaded_objects <- base::load(contract$path[[1L]], envir = workspace)",
      trimws(load_lines),
      fixed = TRUE
    ),
  "A descriptive script loads an unpinned workspace or unexpected object"
)

# Optional end-to-end deterministic rebuild. The manifest itself records the
# hashes of every table, source CSV, audit CSV, PNG, JPEG, PDF, and SVG.
if ("--rebuild" %in% commandArgs(trailingOnly = TRUE)) {
  before <- stats::setNames(manifest$sha256, manifest$path)
  build_descriptives(root)
  after_manifest <- readr::read_csv(
    artifact_manifest_path, show_col_types = FALSE
  )
  after <- stats::setNames(after_manifest$sha256, after_manifest$path)
  assert_identical(names(after), names(before),
                   "Deterministic rebuild changed the artifact set")
  assert_identical(unname(after), unname(before),
                   "Deterministic rebuild changed an artifact hash")
}

cat("All descriptive tests passed.\n")
