source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/reference_profiles.R")
source("scripts/pipeline/build_reference_profiles.R")

new_profile_coverage_input <- function(placement) {
  sites <- c("A", "B", "C")
  participants <- unlist(lapply(sites, function(site) {
    paste0(site, sprintf("%02d", seq_len(10L)))
  }))
  data <- expand.grid(
    site = sites,
    Id = participants,
    clock_minute = seq.int(0L, 1439L),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  data <- data[
    substr(data$Id, 1L, 1L) == data$site,
    ,
    drop = FALSE
  ]
  data$position <- placement
  data$local_date <- as.Date("2026-01-01")
  data$datetime_wall <- as.POSIXct(
    data$local_date,
    tz = "UTC"
  ) +
    data$clock_minute * 60
  # Shift later true instants for the three fold fixtures so each added
  # repeated wall minute has a unique true-UTC key.
  after_fold <- data$site == "A" &
    data$Id %in% c("A01", "A02", "A03") &
    data$clock_minute >= 120L
  data$datetime_utc <- data$datetime_wall + ifelse(after_fold, 3600, 0)
  data$utc_offset_minutes <- 0L
  data$is_dst <- FALSE
  data$State.Brown <- dplyr::case_when(
    data$clock_minute < 480L ~ "sleep",
    data$clock_minute < 1200L ~ "wake",
    TRUE ~ "pre-sleep"
  )
  participant_number <- as.integer(substr(data$Id, 2L, 3L))
  site_number <- match(data$site, sites)
  placement_offset <- if (placement == "glasses") 0 else 50
  data$MEDI_eligible <- 10 +
    site_number * 20 +
    participant_number +
    data$clock_minute / 30 +
    placement_offset +
    ifelse(
      data$clock_minute >= 600L & data$clock_minute < 900L,
      300,
      0
    )
  data$LIGHT_eligible <- 100 +
    site_number * 40 +
    participant_number +
    data$clock_minute / 15 +
    placement_offset

  if (placement == "glasses") {
    sparse <- data$site == "A" &
      data$clock_minute < 30L &
      participant_number > 4L
    data$MEDI_eligible[sparse] <- NA_real_
  }

  repeated <- lapply(c("A01", "A02", "A03"), function(participant) {
    row <- data[
      data$site == "A" &
        data$Id == participant &
        data$clock_minute == 60L,
      ,
      drop = FALSE
    ]
    row$datetime_utc <- row$datetime_utc + 3600
    row$utc_offset_minutes <- -60L
    row$is_dst <- TRUE
    row
  })
  # A01 crosses the diary-state boundary and has two finite values.
  repeated[[1L]]$State.Brown <- "wake"
  repeated[[1L]]$MEDI_eligible <- repeated[[1L]]$MEDI_eligible + 20
  repeated[[1L]]$LIGHT_eligible <- repeated[[1L]]$LIGHT_eligible + 40
  # A02 remains in one state and has two finite values.
  repeated[[2L]]$MEDI_eligible <- repeated[[2L]]$MEDI_eligible + 30
  repeated[[2L]]$LIGHT_eligible <- repeated[[2L]]$LIGHT_eligible + 60
  # A03 remains in one state but the second true minute is missing.
  repeated[[3L]]$MEDI_eligible <- NA_real_
  repeated[[3L]]$LIGHT_eligible <- NA_real_
  dplyr::bind_rows(data, dplyr::bind_rows(repeated)) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$datetime_utc
    )
}

message("Building isolated synthetic Preparation 03 inputs")
test_root <- tempfile("nathealth-profile-test-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
paths <- pipeline_paths(test_root)
ensure_pipeline_directories(paths)
coverage_run_root <- file.path(paths$coverage, "runs", "smoke")
dir.create(coverage_run_root, recursive = TRUE)

glasses_input <- new_profile_coverage_input("glasses")
chest_input <- new_profile_coverage_input("chest")
glasses_input_path <- file.path(
  coverage_run_root,
  "light_glasses_coverage.rds"
)
chest_input_path <- file.path(
  coverage_run_root,
  "light_chest_coverage.rds"
)
saveRDS(glasses_input, glasses_input_path)
saveRDS(chest_input, chest_input_path)
glasses_input_sha256 <- artifact_sha256(glasses_input_path)
chest_input_sha256 <- artifact_sha256(chest_input_path)
coverage_settings_path <- file.path(
  coverage_run_root,
  "coverage_settings.csv"
)
readr::write_csv(
  tibble::tibble(
    run_label = "smoke",
    placement = c("chest", "glasses"),
    coverage_rule_id = "A",
    coverage_signal = "MEDI",
    daily_denominator_domain = "all_pseudo_local_wall_minutes",
    daily_eligibility_basis =
      "finite_medi_minutes_across_fixed_24_hour_cycle",
    hourly_gate_scope = "hourly_metrics_only",
    minute_values_masked_by_hour_gate = FALSE,
    hour_screened_sensitivity_available = TRUE,
    all_zero_medi_exclusion_applied = TRUE,
    all_zero_medi_sensitivity_available = TRUE,
    diary_sleep_excluded_from_denominator = FALSE,
    expected_wall_minutes_per_hour = 60L,
    expected_wall_minutes_per_day = 1440L,
    minimum_hour_coverage = 0.5,
    minimum_day_coverage = 0.8
  ),
  coverage_settings_path
)
coverage_settings_sha256 <- artifact_sha256(coverage_settings_path)

message("Checking fall-back wall-minute averaging before learning")
glasses_wall <- collapse_reference_profile_wall_minutes(
  glasses_input,
  object = "synthetic glasses coverage"
)
fold_input <- glasses_input |>
  dplyr::filter(
    .data$site == "A",
    .data$Id == "A01",
    .data$clock_minute == 60L
  )
fold_wall <- glasses_wall |>
  dplyr::filter(
    .data$site == "A",
    .data$Id == "A01",
    .data$clock_minute == 60L
  )
stopifnot(
  nrow(fold_input) == 2L,
  nrow(fold_wall) == 1L,
  fold_wall$source_real_minutes == 2L,
  fold_wall$distinct_true_utc_minutes == 2L,
  fold_wall$wall_dst_fold,
  fold_wall$State.Brown == "mixed",
  fold_wall$MEDI_eligible == mean(fold_input$MEDI_eligible),
  fold_wall$LIGHT_eligible == mean(fold_input$LIGHT_eligible)
)
sleep_wall <- collapse_reference_profile_wall_minutes(
  glasses_input,
  state_domain = "sleep",
  object = "synthetic glasses sleep coverage"
) |>
  dplyr::filter(
    .data$site == "A",
    .data$Id == "A01",
    .data$clock_minute == 60L
  )
wake_wall <- collapse_reference_profile_wall_minutes(
  glasses_input,
  state_domain = "wake",
  object = "synthetic glasses wake coverage"
) |>
  dplyr::filter(
    .data$site == "A",
    .data$Id == "A01",
    .data$clock_minute == 60L
  )
stopifnot(
  nrow(sleep_wall) == 1L,
  nrow(wake_wall) == 1L,
  sleep_wall$source_real_minutes == 1L,
  wake_wall$source_real_minutes == 1L,
  sleep_wall$State.Brown == "sleep",
  wake_wall$State.Brown == "wake",
  sleep_wall$MEDI_eligible == min(fold_input$MEDI_eligible),
  wake_wall$MEDI_eligible == max(fold_input$MEDI_eligible)
)

message("Checking finite-plus-finite and finite-plus-missing folds")
same_state_finite_input <- glasses_input |>
  dplyr::filter(
    .data$site == "A",
    .data$Id == "A02",
    .data$clock_minute == 60L
  )
same_state_finite_wall <- glasses_wall |>
  dplyr::filter(
    .data$site == "A",
    .data$Id == "A02",
    .data$clock_minute == 60L
  )
same_state_missing_input <- glasses_input |>
  dplyr::filter(
    .data$site == "A",
    .data$Id == "A03",
    .data$clock_minute == 60L
  )
same_state_missing_wall <- glasses_wall |>
  dplyr::filter(
    .data$site == "A",
    .data$Id == "A03",
    .data$clock_minute == 60L
  )
stopifnot(
  nrow(same_state_finite_input) == 2L,
  nrow(same_state_finite_wall) == 1L,
  same_state_finite_wall$State.Brown == "sleep",
  same_state_finite_wall$MEDI_finite_true_minutes == 2L,
  same_state_finite_wall$LIGHT_finite_true_minutes == 2L,
  same_state_finite_wall$MEDI_eligible ==
    mean(same_state_finite_input$MEDI_eligible),
  same_state_finite_wall$LIGHT_eligible ==
    mean(same_state_finite_input$LIGHT_eligible),
  nrow(same_state_missing_input) == 2L,
  nrow(same_state_missing_wall) == 1L,
  same_state_missing_wall$State.Brown == "sleep",
  same_state_missing_wall$MEDI_finite_true_minutes == 1L,
  same_state_missing_wall$LIGHT_finite_true_minutes == 1L,
  same_state_missing_wall$MEDI_eligible ==
    same_state_missing_input$MEDI_eligible[
      is.finite(same_state_missing_input$MEDI_eligible)
    ],
  same_state_missing_wall$LIGHT_eligible ==
    same_state_missing_input$LIGHT_eligible[
      is.finite(same_state_missing_input$LIGHT_eligible)
    ]
)

message("Checking per-domain true-UTC row and key reconciliation")
wall_key <- c("site", "Id", "position", "local_date", "clock_minute")
for (state_domain in c("full_day", "wake", "pre-sleep", "sleep")) {
  domain_input <- if (state_domain == "full_day") {
    glasses_input
  } else {
    glasses_input[
      !is.na(glasses_input$State.Brown) &
        glasses_input$State.Brown == state_domain,
      ,
      drop = FALSE
    ]
  }
  domain_wall <- collapse_reference_profile_wall_minutes(
    glasses_input,
    state_domain = state_domain,
    object = paste0("synthetic ", state_domain, " coverage")
  )
  stopifnot(
    nrow(domain_wall) == nrow(unique(domain_input[wall_key])),
    sum(domain_wall$source_real_minutes) == nrow(domain_input),
    sum(domain_wall$distinct_true_utc_minutes) == nrow(domain_input),
    !anyDuplicated(domain_wall[wall_key]),
    sum(domain_wall$MEDI_finite_true_minutes) ==
      sum(is.finite(domain_input$MEDI_eligible)),
    sum(domain_wall$LIGHT_finite_true_minutes) ==
      sum(is.finite(domain_input$LIGHT_eligible))
  )
}

message("Checking rejection of duplicated true-UTC source keys")
duplicated_true_utc <- dplyr::bind_rows(
  glasses_input,
  glasses_input[1L, , drop = FALSE]
)
duplicated_true_utc_error <- tryCatch(
  {
    collapse_reference_profile_wall_minutes(
      duplicated_true_utc,
      object = "duplicated true-UTC fixture"
    )
    NULL
  },
  error = identity
)
stopifnot(
  inherits(duplicated_true_utc_error, "error"),
  grepl(
    "duplicated row",
    conditionMessage(duplicated_true_utc_error),
    fixed = TRUE
  )
)

message("Running Preparation 03 only on the isolated smoke root")
result <- build_reference_profiles(
  root = test_root,
  run_label = "smoke",
  placements = c("glasses", "chest")
)
expected_output_root <- file.path(paths$profiles, "runs", "smoke")
stopifnot(
  identical(
    normalizePath(result$profile_run_root, winslash = "/", mustWork = TRUE),
    normalizePath(expected_output_root, winslash = "/", mustWork = TRUE)
  ),
  !file.exists(file.path(paths$profiles, "reference_profiles.rds")),
  artifact_sha256(glasses_input_path) == glasses_input_sha256,
  artifact_sha256(chest_input_path) == chest_input_sha256,
  artifact_sha256(coverage_settings_path) == coverage_settings_sha256
)

message("Checking fixed profile strata, support, and sparse bins")
profiles <- readRDS(result$output_paths$profiles_rds)
profiles_csv <- readr::read_csv(
  result$output_paths$profiles_csv,
  show_col_types = FALSE
)
stopifnot(
  identical(
    attr(profiles, "profile_learning"),
    "fixed_once_before_participant_day_metrics"
  ),
  identical(attr(profiles, "bin_minutes"), 30L),
  setequal(unique(profiles$placement), c("glasses", "chest")),
  setequal(
    unique(profiles$state_domain),
    c("full_day", "wake", "pre-sleep", "sleep")
  ),
  setequal(unique(profiles$signal), c("MEDI", "LIGHT")),
  setequal(unique(profiles$clock_bin), seq.int(0L, 1410L, by = 30L)),
  nrow(profiles) == 2L * (1L + 3L + 3L) * 4L * 2L * 48L,
  nrow(profiles_csv) == nrow(profiles)
)
stopifnot(
  all(
    profiles$minimum_participants[
      profiles$profile_scope == "pooled" &
        profiles$state_domain == "full_day"
    ] ==
      20L
  ),
  all(
    profiles$minimum_participants[
      profiles$profile_scope == "leave_one_site_out" &
        profiles$state_domain == "full_day"
    ] ==
      20L
  ),
  all(
    profiles$minimum_participants[
      profiles$profile_scope == "site_specific" |
        profiles$state_domain != "full_day"
    ] ==
      5L
  )
)

pooled_sparse <- profiles |>
  dplyr::filter(
    .data$profile_variant == "pooled",
    .data$placement == "glasses",
    .data$state_domain == "full_day",
    .data$signal == "MEDI",
    .data$clock_bin == 0L
  )
site_a_sparse <- profiles |>
  dplyr::filter(
    .data$profile_variant == "site::A",
    .data$placement == "glasses",
    .data$state_domain == "full_day",
    .data$signal == "MEDI",
    .data$clock_bin == 0L
  )
loso_b_sparse <- profiles |>
  dplyr::filter(
    .data$profile_variant == "leave_one_site_out::B",
    .data$placement == "glasses",
    .data$state_domain == "full_day",
    .data$signal == "MEDI",
    .data$clock_bin == 0L
  )
stopifnot(
  pooled_sparse$participants == 24L,
  pooled_sparse$profile_supported,
  site_a_sparse$participants == 4L,
  !site_a_sparse$profile_supported,
  is.na(site_a_sparse$supported_reference_value),
  loso_b_sparse$participants == 14L,
  !loso_b_sparse$profile_supported
)

message("Checking fixed participant/day-balanced timing distributions")
timing_distributions <- readRDS(
  result$output_paths$timing_distributions_rds
)
timing_distributions_csv <- readr::read_csv(
  result$output_paths$timing_distributions_csv,
  show_col_types = FALSE
)
validate_exceedance_distribution_profiles(timing_distributions)
stopifnot(
  identical(
    attr(timing_distributions, "profile_learning"),
    "fixed_once_before_participant_day_metrics"
  ),
  identical(
    attr(timing_distributions, "distribution_profile_type"),
    "participant_balanced_valid_minute_exceedance_probability"
  ),
  identical(attr(timing_distributions, "bin_minutes"), 30L),
  identical(attr(timing_distributions, "threshold_lx"), 250),
  identical(
    attr(timing_distributions, "comparison"),
    "strict_greater_than"
  ),
  setequal(
    unique(timing_distributions$placement),
    c("glasses", "chest")
  ),
  identical(
    unique(as.character(timing_distributions$state_domain)),
    "full_day"
  ),
  identical(
    unique(as.character(timing_distributions$signal)),
    "MEDI"
  ),
  setequal(
    unique(timing_distributions$clock_bin),
    seq.int(0L, 1410L, by = 30L)
  ),
  nrow(timing_distributions) ==
    2L * (1L + 3L + 3L) * 48L,
  nrow(timing_distributions_csv) == nrow(timing_distributions)
)
pooled_timing <- timing_distributions |>
  dplyr::filter(
    .data$profile_variant == "pooled",
    .data$placement == "glasses"
  )
stopifnot(
  all(
    pooled_timing$exceedance_probability[
      pooled_timing$clock_bin >= 600L &
        pooled_timing$clock_bin < 900L
    ] == 1
  ),
  all(
    pooled_timing$exceedance_probability[
      pooled_timing$clock_bin < 600L |
        pooled_timing$clock_bin >= 900L
    ] == 0
  ),
  all(pooled_timing$profile_supported),
  pooled_timing$profile_estimable[[1L]]
)

message("Checking metric-specific maps and non-interpolation")
maps <- readRDS(result$output_paths$relevance_maps_rds)
maps_csv <- readr::read_csv(
  result$output_paths$relevance_maps_csv,
  show_col_types = FALSE
)
validate_relevance_weight_normalization(maps)
stopifnot(
  !"L5" %in% maps$metric_map,
  "L10" %in% maps$metric_map,
  all(maps$ratio_correction_allowed == FALSE),
  all(
    maps$value_correction_allowed == (maps$metric_map == "dose")
  ),
  all(
    is.na(
      profiles$supported_reference_value[!profiles$profile_supported]
    )
  ),
  nrow(maps_csv) == nrow(maps)
)
timing_maps <- maps |>
  dplyr::filter(.data$metric_map == "timing_above_250")
timing_key_columns <- c(
  "profile_scope",
  "profile_variant",
  "profile_site",
  "held_out_site",
  "placement",
  "state_domain",
  "signal",
  "clock_bin"
)
timing_alignment <- timing_maps |>
  dplyr::select(dplyr::all_of(c(
    timing_key_columns,
    "relevance_mass",
    "relevance_weight",
    "relevance_source"
  ))) |>
  dplyr::left_join(
    timing_distributions |>
      dplyr::select(dplyr::all_of(c(
        timing_key_columns,
        "exceedance_probability",
        "supported_exceedance_probability",
        "probability_weight"
      ))),
    by = timing_key_columns,
    na_matches = "na",
    relationship = "one-to-one"
  )
stopifnot(
  nrow(timing_alignment) == nrow(timing_distributions),
  all(
    timing_alignment$relevance_source ==
      "participant_balanced_exceedance_distribution"
  ),
  isTRUE(all.equal(
    timing_alignment$relevance_mass,
    timing_alignment$supported_exceedance_probability,
    check.attributes = FALSE
  )),
  isTRUE(all.equal(
    timing_alignment$relevance_weight,
    timing_alignment$probability_weight,
    check.attributes = FALSE
  ))
)

message("Checking provenance, settings, and complete manifests")
provenance <- readr::read_csv(
  result$output_paths$provenance,
  show_col_types = FALSE
)
settings <- readr::read_csv(
  result$output_paths$settings,
  show_col_types = FALSE
)
manifest <- readr::read_csv(
  result$artifact_manifest_path,
  show_col_types = FALSE
)
timing_distribution_support <- readr::read_csv(
  result$output_paths$timing_distribution_support,
  show_col_types = FALSE
)
stopifnot(
  nrow(provenance) == 4L,
  all(provenance$absolute_coordinate == "datetime_utc_preserved_in_input"),
  all(provenance$repeated_wall_keys == 3L),
  all(provenance$mixed_state_wall_keys == 1L),
  all(provenance$repeated_mixed_state_wall_keys == 1L),
  all(provenance$repeated_wall_minutes_averaged == 3L),
  all(provenance$repeated_wall_minutes_with_mixed_state == 1L),
  all(provenance$additional_true_rows_in_repeated_minutes == 3L),
  nrow(settings) == 1L,
  !settings$participant_day_profiles_fitted,
  !settings$l5_permitted,
  settings$bin_minutes == 30L,
  settings$input_coverage_rule_id == "A",
  settings$input_coverage_settings_sha256 == coverage_settings_sha256,
  settings$input_daily_denominator_domain == "all_pseudo_local_wall_minutes",
  !settings$input_diary_sleep_excluded_from_denominator,
  settings$unsupported_bin_rule ==
    "retain_as_unsupported_without_interpolation",
  settings$timing_distribution_threshold_lx == 250,
  settings$timing_distribution_comparison == "strict_greater_than",
  settings$timing_distribution_fitted_once,
  settings$timing_distribution_applies_to ==
    "timing_above_250_support_only",
  !settings$timing_distribution_scales_metric_values,
  settings$timing_distribution_rows == nrow(timing_distributions),
  nrow(timing_distribution_support) ==
    2L * (1L + 3L + 3L),
  nrow(manifest) == 11L,
  all(file.exists(manifest$path)),
  all(vapply(
    seq_len(nrow(manifest)),
    function(index) {
      artifact_sha256(manifest$path[index]) == manifest$sha256[index]
    },
    logical(1)
  ))
)

message("Checking deterministic reruns and immutable inputs")
profiles_sha256 <- artifact_sha256(result$output_paths$profiles_rds)
timing_distributions_sha256 <- artifact_sha256(
  result$output_paths$timing_distributions_rds
)
maps_sha256 <- artifact_sha256(result$output_paths$relevance_maps_rds)
rerun <- build_reference_profiles(
  root = test_root,
  run_label = "smoke",
  placements = c("chest", "glasses")
)
stopifnot(
  artifact_sha256(rerun$output_paths$profiles_rds) == profiles_sha256,
  artifact_sha256(rerun$output_paths$timing_distributions_rds) ==
    timing_distributions_sha256,
  artifact_sha256(rerun$output_paths$relevance_maps_rds) == maps_sha256,
  artifact_sha256(glasses_input_path) == glasses_input_sha256,
  artifact_sha256(chest_input_path) == chest_input_sha256
)

message("All Preparation 03 builder tests passed")
