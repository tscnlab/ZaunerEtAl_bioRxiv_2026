source("scripts/pipeline/reference_profiles.R")

message("Testing 30-minute clock-bin validation")
stopifnot(
  identical(clock_bin(c(0, 29.9, 30, 1439.9)), c(0, 0, 30, 1410))
)
invalid_clock <- tryCatch(
  {
    clock_bin(c(0, 1440))
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(invalid_clock)

message("Testing participant-balanced low-level profile learning")
balanced_input <- data.frame(
  Id = c("A", "A", "A", "B", "B"),
  day = as.Date(c(
    "2026-01-01",
    "2026-01-01",
    "2026-01-02",
    "2026-01-01",
    "2026-01-02"
  )),
  placement = "glasses",
  state_domain = "full_day",
  signal = "MEDI",
  clock_bin = c(0, 0, 0, 0, 0),
  value = c(1, 3, 5, 10, 10)
)
balanced <- learn_reference_profile(
  balanced_input,
  value_col = "value",
  participant_day_col = "day"
)
bin_zero <- balanced[balanced$clock_bin == 0, , drop = FALSE]
stopifnot(
  nrow(balanced) == 48L,
  bin_zero$reference_value == 6.5,
  bin_zero$observations == 5L,
  bin_zero$participant_days == 4L,
  bin_zero$participants == 2L,
  bin_zero$profile_supported,
  sum(balanced$profile_supported) == 1L,
  all(is.na(
    balanced$reference_value[balanced$clock_bin != 0]
  ))
)

message("Testing participant/day-balanced strict exceedance learning")
distribution_balanced_input <- data.frame(
  Id = c(
    rep("A", 6L),
    rep("B", 4L)
  ),
  day = as.Date(c(
    rep("2026-01-01", 5L),
    "2026-01-02",
    rep("2026-01-01", 4L)
  )),
  placement = "glasses",
  state_domain = "full_day",
  signal = "MEDI",
  clock_bin = 0,
  value = c(
    300,
    100,
    250,
    250.0001,
    NA,
    300,
    300,
    100,
    100,
    100
  )
)
distribution_balanced <- learn_exceedance_distribution_profile(
  data = distribution_balanced_input,
  value_col = "value",
  participant_day_col = "day"
)
distribution_bin_zero <- distribution_balanced[
  distribution_balanced$clock_bin == 0,
  ,
  drop = FALSE
]
stopifnot(
  nrow(distribution_balanced) == 48L,
  distribution_bin_zero$observations == 10L,
  distribution_bin_zero$valid_minutes == 9L,
  distribution_bin_zero$exceedance_minutes == 4L,
  distribution_bin_zero$participant_days == 3L,
  distribution_bin_zero$participants == 2L,
  distribution_bin_zero$exceedance_probability == 0.5,
  distribution_bin_zero$exceedance_probability != 4 / 9,
  isTRUE(all.equal(
    distribution_bin_zero$participant_probability_q10,
    0.30
  )),
  distribution_bin_zero$participant_probability_q25 == 0.375,
  distribution_bin_zero$participant_probability_median == 0.5,
  distribution_bin_zero$participant_probability_q75 == 0.625,
  isTRUE(all.equal(
    distribution_bin_zero$participant_probability_q90,
    0.70
  )),
  distribution_bin_zero$profile_supported,
  distribution_bin_zero$probability_weight == 1,
  all(
    distribution_balanced$exceedance_probability[
      distribution_balanced$clock_bin != 0
    ] |>
      is.na()
  )
)
invalid_distribution_threshold <- tryCatch(
  {
    learn_exceedance_distribution_profile(
      data = distribution_balanced_input,
      value_col = "value",
      participant_day_col = "day",
      threshold = 249
    )
    FALSE
  },
  error = function(error) TRUE
)
invalid_distribution_bin <- tryCatch(
  {
    learn_exceedance_distribution_profile(
      data = distribution_balanced_input,
      value_col = "value",
      participant_day_col = "day",
      bin_minutes = 60L
    )
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(
  invalid_distribution_threshold,
  invalid_distribution_bin
)

message("Building fixed pooled, site, and leave-one-site-out profiles")
sites <- c("A", "B", "C")
participants <- unlist(lapply(sites, function(site) {
  paste0(site, sprintf("%02d", seq_len(11L)))
}))
profile_input <- expand.grid(
  site = sites,
  Id = participants,
  local_date = as.Date(c("2026-01-01", "2026-01-02")),
  clock_bin = seq.int(0L, 1410L, by = 30L),
  state_domain = c("full_day", "wake"),
  signal = c("MEDI", "LIGHT"),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
profile_input <- profile_input[
  substr(profile_input$Id, 1L, 1L) == profile_input$site,
  ,
  drop = FALSE
]
profile_input$placement <- "glasses"
participant_number <- as.integer(substr(profile_input$Id, 2L, 3L))
bin_number <- profile_input$clock_bin / 30
profile_input$value <- ifelse(
  profile_input$signal == "MEDI",
  10 + 12 * bin_number + participant_number,
  100 + 20 * bin_number + participant_number
)

# Leave only four site-A participants in one full-day MEDI bin. This bin is
# supported in the pooled profile, but not in site A or in LOSO profiles whose
# training data contain fewer than 20 participants at that bin.
drop_row <- profile_input$site == "A" &
  profile_input$state_domain == "full_day" &
  profile_input$signal == "MEDI" &
  profile_input$clock_bin == 0 &
  participant_number > 4L
profile_input <- profile_input[!drop_row, , drop = FALSE]

profiles <- learn_reference_profile_set(
  data = profile_input,
  value_col = "value"
)
stopifnot(
  identical(
    attr(profiles, "profile_learning"),
    "fixed_once_before_daily_metrics"
  ),
  nrow(profiles) == (1L + 3L + 3L) * 2L * 2L * 48L
)

stratum_bin_counts <- profiles |>
  dplyr::count(
    .data$profile_scope,
    .data$profile_variant,
    .data$placement,
    .data$state_domain,
    .data$signal
  )
stopifnot(
  all(stratum_bin_counts$n == 48L),
  setequal(unique(profiles$clock_bin), seq.int(0L, 1410L, by = 30L))
)

pooled_full_day <- profiles |>
  dplyr::filter(
    .data$profile_scope == "pooled",
    .data$state_domain == "full_day"
  )
pooled_wake <- profiles |>
  dplyr::filter(
    .data$profile_scope == "pooled",
    .data$state_domain == "wake"
  )
site_profiles <- profiles |>
  dplyr::filter(.data$profile_scope == "site_specific")
loso_full_day <- profiles |>
  dplyr::filter(
    .data$profile_scope == "leave_one_site_out",
    .data$state_domain == "full_day"
  )
stopifnot(
  all(pooled_full_day$minimum_participants == 20L),
  all(pooled_wake$minimum_participants == 5L),
  all(site_profiles$minimum_participants == 5L),
  all(loso_full_day$minimum_participants == 20L),
  all(pooled_full_day$training_site_count == 3L),
  all(site_profiles$training_site_count == 1L),
  all(loso_full_day$training_site_count == 2L),
  all(
    profiles$training_site_count ==
      lengths(strsplit(profiles$training_sites, "|", fixed = TRUE))
  )
)

pooled_sparse_bin <- profiles |>
  dplyr::filter(
    .data$profile_scope == "pooled",
    .data$state_domain == "full_day",
    .data$signal == "MEDI",
    .data$clock_bin == 0
  )
site_a_sparse_bin <- profiles |>
  dplyr::filter(
    .data$profile_variant == "site::A",
    .data$state_domain == "full_day",
    .data$signal == "MEDI",
    .data$clock_bin == 0
  )
loso_b_sparse_bin <- profiles |>
  dplyr::filter(
    .data$profile_variant == "leave_one_site_out::B",
    .data$state_domain == "full_day",
    .data$signal == "MEDI",
    .data$clock_bin == 0
  )
stopifnot(
  pooled_sparse_bin$participants == 26L,
  pooled_sparse_bin$participant_days == 52L,
  pooled_sparse_bin$observations == 52L,
  pooled_sparse_bin$profile_supported,
  site_a_sparse_bin$participants == 4L,
  !site_a_sparse_bin$profile_supported,
  is.na(site_a_sparse_bin$supported_reference_value),
  loso_b_sparse_bin$participants == 15L,
  !loso_b_sparse_bin$profile_supported
)

message("Building fixed participant-balanced exceedance distributions")
distribution_input <- expand.grid(
  site = sites,
  Id = participants,
  local_date = as.Date(c("2026-01-01", "2026-01-02")),
  clock_bin = seq.int(0L, 1410L, by = 30L),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
distribution_input <- distribution_input[
  substr(distribution_input$Id, 1L, 1L) == distribution_input$site,
  ,
  drop = FALSE
]
distribution_input$placement <- "glasses"
distribution_input$state_domain <- "full_day"
distribution_input$signal <- "MEDI"
distribution_input$value <- 100
distribution_input$value[
  distribution_input$clock_bin == 0 &
    distribution_input$site == "A"
] <- 251
distribution_input$value[
  distribution_input$clock_bin == 0 &
    distribution_input$site == "B"
] <- 250
distribution_input$value[
  distribution_input$clock_bin == 0 &
    distribution_input$site == "C" &
    distribution_input$local_date == as.Date("2026-01-01")
] <- 251
distribution_input$value[
  distribution_input$clock_bin == 0 &
    distribution_input$site == "C" &
    distribution_input$local_date == as.Date("2026-01-02")
] <- 249

distribution_profiles <- learn_exceedance_distribution_profile_set(
  data = distribution_input,
  value_col = "value"
)
validate_exceedance_distribution_profiles(distribution_profiles)
stopifnot(
  identical(
    attr(distribution_profiles, "profile_learning"),
    "fixed_once_before_daily_metrics"
  ),
  identical(
    attr(distribution_profiles, "distribution_profile_type"),
    "participant_balanced_valid_minute_exceedance_probability"
  ),
  nrow(distribution_profiles) == (1L + 3L + 3L) * 48L,
  !any(grepl("L5", names(distribution_profiles), fixed = TRUE))
)

distribution_bin_counts <- distribution_profiles |>
  dplyr::count(
    .data$profile_scope,
    .data$profile_variant,
    .data$placement,
    .data$state_domain,
    .data$signal
  )
stopifnot(
  all(distribution_bin_counts$n == 48L),
  setequal(
    unique(distribution_profiles$clock_bin),
    seq.int(0L, 1410L, by = 30L)
  ),
  all(
    distribution_profiles$minimum_participants[
      distribution_profiles$profile_scope == "pooled"
    ] ==
      20L
  ),
  all(
    distribution_profiles$minimum_participants[
      distribution_profiles$profile_scope == "site_specific"
    ] ==
      5L
  ),
  all(
    distribution_profiles$minimum_participants[
      distribution_profiles$profile_scope == "leave_one_site_out"
    ] ==
      20L
  )
)

distribution_at_zero <- distribution_profiles |>
  dplyr::filter(.data$clock_bin == 0) |>
  dplyr::select(dplyr::all_of(c(
    "profile_variant",
    "exceedance_probability",
    "participant_probability_q10",
    "participant_probability_median",
    "participant_probability_q90",
    "participants",
    "participant_days",
    "valid_minutes"
  )))
profile_probability <- function(variant) {
  distribution_at_zero$exceedance_probability[
    distribution_at_zero$profile_variant == variant
  ]
}
stopifnot(
  profile_probability("pooled") == 0.5,
  profile_probability("site::A") == 1,
  profile_probability("site::B") == 0,
  profile_probability("site::C") == 0.5,
  profile_probability("leave_one_site_out::A") == 0.25,
  profile_probability("leave_one_site_out::B") == 0.75,
  profile_probability("leave_one_site_out::C") == 0.5
)
pooled_distribution_zero <- distribution_at_zero |>
  dplyr::filter(.data$profile_variant == "pooled")
stopifnot(
  pooled_distribution_zero$participant_probability_q10 == 0,
  pooled_distribution_zero$participant_probability_median == 0.5,
  pooled_distribution_zero$participant_probability_q90 == 1,
  pooled_distribution_zero$participants == 33L,
  pooled_distribution_zero$participant_days == 66L,
  pooled_distribution_zero$valid_minutes == 66L
)

message("Testing deterministic metric-specific relevance maps")
maps <- derive_metric_relevance_maps(
  profiles = profiles,
  distribution_profiles = distribution_profiles
)
validate_relevance_weight_normalization(maps)
non_timing_numeric_audit <- maps |>
  dplyr::filter(.data$metric_map != "timing_above_250") |>
  dplyr::group_by(
    .data$profile_scope,
    .data$profile_variant,
    .data$profile_site,
    .data$held_out_site,
    .data$placement,
    .data$state_domain,
    .data$signal,
    .data$metric_map
  ) |>
  dplyr::mutate(
    expected_mass = profile_relevance_mass(
      .data$reference_value,
      .data$profile_supported,
      metric_map = dplyr::first(.data$metric_map),
      zero_offset = 0.1
    ),
    expected_total = sum(.data$expected_mass, na.rm = TRUE),
    expected_estimable = is.finite(.data$expected_total) &
      .data$expected_total > 0,
    expected_weight = dplyr::if_else(
      .data$expected_estimable & is.finite(.data$expected_mass),
      .data$expected_mass / .data$expected_total,
      NA_real_
    )
  ) |>
  dplyr::ungroup()
stopifnot(
  identical(
    non_timing_numeric_audit$relevance_mass,
    non_timing_numeric_audit$expected_mass
  ),
  identical(
    non_timing_numeric_audit$relevance_total,
    non_timing_numeric_audit$expected_total
  ),
  identical(
    non_timing_numeric_audit$map_estimable,
    non_timing_numeric_audit$expected_estimable
  ),
  identical(
    non_timing_numeric_audit$relevance_weight,
    non_timing_numeric_audit$expected_weight
  )
)
map_groups <- maps |>
  dplyr::distinct(
    .data$profile_scope,
    .data$profile_variant,
    .data$placement,
    .data$state_domain,
    .data$signal,
    .data$metric_map
  )
stopifnot(
  setequal(
    unique(maps$metric_map),
    c(
      "dose",
      "M10",
      "L10",
      "timing_above_250",
      "paired_channel_coverage"
    )
  ),
  all(maps$ratio_correction_allowed == FALSE),
  all(
    maps$value_correction_allowed == (maps$metric_map == "dose")
  ),
  all(
    maps$paired_channel_required ==
      (maps$metric_map == "paired_channel_coverage")
  ),
  all(
    map_groups$signal[map_groups$metric_map != "paired_channel_coverage"] ==
      "MEDI"
  ),
  setequal(
    map_groups$signal[
      map_groups$metric_map == "paired_channel_coverage"
    ],
    c("MEDI", "LIGHT")
  ),
  all(
    map_groups$state_domain[
      map_groups$metric_map == "timing_above_250"
    ] ==
      "full_day"
  ),
  !any(grepl("L5", maps$metric_map, fixed = TRUE))
)

pooled_medi_maps <- maps |>
  dplyr::filter(
    .data$profile_scope == "pooled",
    .data$state_domain == "full_day",
    .data$signal == "MEDI"
  )
dose_map <- pooled_medi_maps |>
  dplyr::filter(.data$metric_map == "dose")
m10_map <- pooled_medi_maps |>
  dplyr::filter(.data$metric_map == "M10")
l10_map <- pooled_medi_maps |>
  dplyr::filter(.data$metric_map == "L10")
timing_map <- pooled_medi_maps |>
  dplyr::filter(.data$metric_map == "timing_above_250")
stopifnot(
  isTRUE(all.equal(
    dose_map$relevance_mass,
    dose_map$reference_value
  )),
  m10_map$relevance_mass[
    which.min(m10_map$reference_value)
  ] ==
    0,
  l10_map$relevance_mass[
    which.max(l10_map$reference_value)
  ] ==
    0,
  timing_map$relevance_mass[timing_map$clock_bin == 0] == 0.5,
  all(timing_map$relevance_mass[timing_map$clock_bin != 0] == 0),
  timing_map$relevance_weight[timing_map$clock_bin == 0] == 1,
  all(
    timing_map$relevance_source ==
      "participant_balanced_exceedance_distribution"
  ),
  isTRUE(all.equal(
    sum(dose_map$relevance_weight),
    1,
    tolerance = 1e-12
  ))
)

# Site B's median reference exceeds 250 lx during part of the day, but its
# learned strict-exceedance probability is zero at every bin. This deliberately
# proves there is no fallback to median excess.
site_b_median <- profiles |>
  dplyr::filter(
    .data$profile_variant == "site::B",
    .data$state_domain == "full_day",
    .data$signal == "MEDI"
  )
site_b_timing <- maps |>
  dplyr::filter(
    .data$profile_variant == "site::B",
    .data$metric_map == "timing_above_250"
  )
stopifnot(
  max(site_b_median$reference_value) > 250,
  all(site_b_timing$relevance_mass == 0),
  all(!site_b_timing$map_estimable),
  all(is.na(site_b_timing$relevance_weight))
)
timing_fallback_error <- tryCatch(
  {
    profile_relevance_mass(
      reference_value = c(100, 300),
      supported = c(TRUE, TRUE),
      metric_map = "timing_above_250"
    )
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(timing_fallback_error)

unsupported_map_bin <- maps |>
  dplyr::filter(
    .data$profile_variant == "site::A",
    .data$state_domain == "full_day",
    .data$signal == "MEDI",
    .data$metric_map == "dose",
    .data$clock_bin == 0
  )
stopifnot(
  !unsupported_map_bin$profile_supported,
  is.na(unsupported_map_bin$relevance_mass),
  is.na(unsupported_map_bin$relevance_weight)
)

profiles_again <- learn_reference_profile_set(
  data = profile_input,
  value_col = "value"
)
distribution_profiles_again <- learn_exceedance_distribution_profile_set(
  data = distribution_input,
  value_col = "value"
)
maps_again <- derive_metric_relevance_maps(
  profiles = profiles_again,
  distribution_profiles = distribution_profiles_again
)
stopifnot(
  identical(profiles, profiles_again),
  identical(distribution_profiles, distribution_profiles_again),
  identical(maps, maps_again)
)

# Changing only the supplied exceedance distribution must change timing maps
# without changing any dose, M10, L10, or paired-channel map value.
distribution_input_changed <- distribution_input
distribution_input_changed$value[
  distribution_input_changed$site == "B" &
    distribution_input_changed$clock_bin == 30
] <- 251
distribution_profiles_changed <-
  learn_exceedance_distribution_profile_set(
    data = distribution_input_changed,
    value_col = "value"
  )
maps_changed <- derive_metric_relevance_maps(
  profiles = profiles,
  distribution_profiles = distribution_profiles_changed
)
non_timing_maps <- maps[
  maps$metric_map != "timing_above_250",
  ,
  drop = FALSE
]
non_timing_maps_changed <- maps_changed[
  maps_changed$metric_map != "timing_above_250",
  ,
  drop = FALSE
]
stopifnot(
  identical(non_timing_maps, non_timing_maps_changed),
  !identical(
    maps$relevance_weight[maps$metric_map == "timing_above_250"],
    maps_changed$relevance_weight[
      maps_changed$metric_map == "timing_above_250"
    ]
  )
)

incomplete_distribution <- distribution_profiles[-1L, , drop = FALSE]
distribution_validation_error <- tryCatch(
  {
    derive_metric_relevance_maps(
      profiles = profiles,
      distribution_profiles = incomplete_distribution
    )
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(distribution_validation_error)

broken_maps <- maps
first_estimable <- which(
  broken_maps$map_estimable & is.finite(broken_maps$relevance_weight)
)[1L]
broken_maps$relevance_weight[first_estimable] <-
  broken_maps$relevance_weight[first_estimable] + 0.01
normalization_error <- tryCatch(
  {
    validate_relevance_weight_normalization(broken_maps)
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(normalization_error)

message("All fixed reference-profile tests passed")
