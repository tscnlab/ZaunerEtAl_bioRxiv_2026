source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/reference_profiles.R")
source("scripts/pipeline/build_reference_profiles.R")
source("scripts/pipeline/verify_reference_profile_artifacts.R")

new_verifier_profile_day <- function(
  site,
  id,
  date,
  participant_level,
  placement = "glasses"
) {
  clock_minute <- 0:1439
  datetime_wall <- as.POSIXct(date, tz = "UTC") + clock_minute * 60
  state <- dplyr::case_when(
    clock_minute < 360L ~ "sleep",
    clock_minute < 1200L ~ "wake",
    TRUE ~ "pre-sleep"
  )
  bin_effect <- floor(clock_minute / 30L)
  tibble::tibble(
    site = site,
    Id = id,
    position = placement,
    datetime_utc = datetime_wall,
    datetime_wall = datetime_wall,
    local_date = as.Date(date),
    clock_minute = clock_minute,
    utc_offset_minutes = 0L,
    State.Brown = state,
    MEDI_eligible = participant_level + bin_effect,
    LIGHT_eligible = 2 * (participant_level + bin_effect) + 1
  )
}

refresh_verifier_manifest <- function(root, run_label) {
  paths <- pipeline_paths(root)
  manifest_path <- file.path(
    paths$manifests,
    paste0("reference_profile_artifacts_", run_label, ".csv")
  )
  manifest <- readr::read_csv(
    manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  manifest$sha256 <- vapply(manifest$path, artifact_sha256, character(1))
  manifest$bytes <- unname(file.info(manifest$path)$size)
  readr::write_csv(manifest, manifest_path, na = "")
  invisible(manifest_path)
}

rewrite_profile_count_artifacts <- function(
  profile_root,
  count_function
) {
  profiles_path <- file.path(profile_root, "reference_profiles.rds")
  profiles_csv_path <- file.path(profile_root, "reference_profiles.csv")
  maps_path <- file.path(profile_root, "metric_relevance_maps.rds")
  maps_csv_path <- file.path(profile_root, "metric_relevance_maps.csv")
  distributions_path <- file.path(
    profile_root,
    "timing_exceedance_distributions.rds"
  )
  distributions_csv_path <- file.path(
    profile_root,
    "timing_exceedance_distributions.csv"
  )
  support_path <- file.path(profile_root, "reference_profile_support.csv")
  distribution_support_path <- file.path(
    profile_root,
    "timing_exceedance_distribution_support.csv"
  )
  map_support_path <- file.path(profile_root, "relevance_map_support.csv")

  profiles <- readRDS(profiles_path)
  maps <- readRDS(maps_path)
  distributions <- readRDS(distributions_path)
  support <- readr::read_csv(
    support_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  distribution_support <- readr::read_csv(
    distribution_support_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  map_support <- readr::read_csv(
    map_support_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  if ("training_sites" %in% names(profiles)) {
    profiles$training_site_count <- count_function(profiles$training_sites)
  }
  if ("training_sites" %in% names(maps)) {
    maps$training_site_count <- count_function(maps$training_sites)
  }
  if ("training_sites" %in% names(distributions)) {
    distributions$training_site_count <- count_function(
      distributions$training_sites
    )
  }
  if ("training_sites" %in% names(support)) {
    support$training_site_count <- count_function(support$training_sites)
  }
  if ("training_sites" %in% names(map_support)) {
    map_support$training_site_count <- count_function(
      map_support$training_sites
    )
  }
  if ("training_sites" %in% names(distribution_support)) {
    distribution_support$training_site_count <- count_function(
      distribution_support$training_sites
    )
  }

  saveRDS(profiles, profiles_path, version = 3, compress = "xz")
  saveRDS(maps, maps_path, version = 3, compress = "xz")
  saveRDS(
    distributions,
    distributions_path,
    version = 3,
    compress = "xz"
  )
  readr::write_csv(profiles, profiles_csv_path, na = "")
  readr::write_csv(maps, maps_csv_path, na = "")
  readr::write_csv(distributions, distributions_csv_path, na = "")
  readr::write_csv(support, support_path, na = "")
  readr::write_csv(
    distribution_support,
    distribution_support_path,
    na = ""
  )
  readr::write_csv(map_support, map_support_path, na = "")
  invisible(list(
    profiles = profiles,
    distributions = distributions,
    maps = maps
  ))
}

true_training_site_count <- function(training_sites) {
  vapply(
    strsplit(as.character(training_sites), "|", fixed = TRUE),
    length,
    integer(1)
  )
}

message("Building isolated two-site Preparation 02 inputs")
test_root <- tempfile("nathealth-profile-verifier-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
paths <- pipeline_paths(test_root)
ensure_pipeline_directories(paths)
coverage_root <- file.path(paths$coverage, "runs", "smoke")
dir.create(coverage_root, recursive = TRUE)

coverage <- dplyr::bind_rows(lapply(c("A", "B"), function(site) {
  dplyr::bind_rows(lapply(seq_len(20L), function(index) {
    new_verifier_profile_day(
      site,
      sprintf("%s%02d", site, index),
      "2026-01-01",
      participant_level = index
    )
  }))
}))
coverage <- dplyr::bind_rows(
  coverage,
  new_verifier_profile_day("A", "A01", "2026-01-03", 100)
)
timing_targets <- tibble::tibble(
  site = rep(c("A", "B"), each = 20L),
  Id = c(sprintf("A%02d", 1:20), sprintf("B%02d", 1:20)),
  target_probability = rep(c(0.5, 0, 1 / 3, 2 / 3, 1), 8L)
)
coverage <- coverage |>
  dplyr::left_join(
    timing_targets,
    by = c("site", "Id"),
    relationship = "many-to-one"
  ) |>
  dplyr::group_by(.data$site, .data$Id, .data$local_date) |>
  dplyr::mutate(
    timing_bin_row = dplyr::if_else(
      .data$clock_minute < 30L,
      cumsum(.data$clock_minute < 30L),
      NA_integer_
    ),
    MEDI_eligible = dplyr::case_when(
      .data$clock_minute >= 30L ~ .data$MEDI_eligible,
      .data$site == "A" &
        .data$Id == "A01" &
        .data$local_date == as.Date("2026-01-01") &
        .data$timing_bin_row == 1L ~
        251,
      .data$site == "A" &
        .data$Id == "A01" &
        .data$local_date == as.Date("2026-01-01") ~
        NA_real_,
      .data$site == "A" &
        .data$Id == "A01" &
        .data$local_date == as.Date("2026-01-03") ~
        250,
      .data$timing_bin_row <= round(.data$target_probability * 30) ~ 251,
      TRUE ~ 250
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::select(-dplyr::all_of(c("target_probability", "timing_bin_row")))
fold_duplicate <- coverage |>
  dplyr::filter(
    .data$site == "A",
    .data$Id == "A01",
    .data$local_date == as.Date("2026-01-01"),
    .data$clock_minute == 120L
  )
fold_duplicate$datetime_utc <- as.POSIXct(
  "2026-01-02 00:00:00",
  tz = "UTC"
)
fold_duplicate$utc_offset_minutes <- -60L
fold_duplicate$State.Brown <- "wake"
fold_duplicate$MEDI_eligible <- 80
fold_duplicate$LIGHT_eligible <- 161
coverage <- dplyr::bind_rows(coverage, fold_duplicate) |>
  dplyr::arrange(.data$site, .data$Id, .data$datetime_utc)

coverage_path <- file.path(
  coverage_root,
  "light_glasses_coverage.rds"
)
saveRDS(coverage, coverage_path, version = 3, compress = "xz")
coverage_settings_path <- file.path(coverage_root, "coverage_settings.csv")
readr::write_csv(
  tibble::tibble(
    run_label = "smoke",
    placement = "glasses",
    coverage_rule_id = "A",
    coverage_signal = "MEDI",
    daily_denominator_domain = "all_pseudo_local_wall_minutes",
    diary_sleep_excluded_from_denominator = FALSE,
    expected_wall_minutes_per_hour = 60L,
    expected_wall_minutes_per_day = 1440L,
    minimum_hour_coverage = 0.5,
    minimum_day_coverage = 0.8
  ),
  coverage_settings_path
)
input_sha256 <- artifact_sha256(coverage_path)
coverage_settings_sha256 <- artifact_sha256(coverage_settings_path)

message("Building isolated Preparation 03 artifacts")
build <- build_reference_profiles(
  root = test_root,
  run_label = "smoke",
  placements = "glasses"
)
profile_root <- build$profile_run_root

manifest_path <- refresh_verifier_manifest(test_root, "smoke")

message("Checking a complete independent verification pass")
verified <- verify_reference_profile_artifacts(
  root = test_root,
  run_label = "smoke",
  reconstruction = "complete",
  stop_on_failure = FALSE
)
if (!identical(verified$status, "PASS")) {
  print(verified$failures, n = Inf, width = Inf)
}
stopifnot(
  verified$status == "PASS",
  nrow(verified$failures) == 0L,
  verified$reconstructed_profile_groups == 40L,
  verified$reconstructed_distribution_groups == 5L,
  artifact_sha256(coverage_path) == input_sha256,
  artifact_sha256(coverage_settings_path) == coverage_settings_sha256,
  all(
    verified$checks$status[
      verified$checks$check_id %in%
        c(
          "immutability::coverage_rds",
          "immutability::coverage_settings"
        )
    ] ==
      "PASS"
  )
)

message("Checking day- and participant-balanced strict exceedance profiles")
distributions <- readRDS(file.path(
  profile_root,
  "timing_exceedance_distributions.rds"
))
pooled_timing_bin <- distributions |>
  dplyr::filter(
    .data$profile_scope == "pooled",
    .data$clock_bin == 0L
  )
pooled_fold_bin <- distributions |>
  dplyr::filter(
    .data$profile_scope == "pooled",
    .data$clock_bin == 120L
  )
stopifnot(
  nrow(pooled_timing_bin) == 1L,
  pooled_timing_bin$observations == 41L * 30L,
  pooled_timing_bin$valid_minutes == 1201L,
  pooled_timing_bin$exceedance_minutes == 586L,
  pooled_timing_bin$participant_days == 41L,
  pooled_timing_bin$participants == 40L,
  pooled_timing_bin$participant_days_with_input == 41L,
  pooled_timing_bin$participants_with_input == 40L,
  abs(pooled_timing_bin$exceedance_probability - 0.5) < 1e-12,
  pooled_timing_bin$exceedance_probability !=
    pooled_timing_bin$exceedance_minutes /
      pooled_timing_bin$valid_minutes,
  pooled_timing_bin$participant_probability_q10 == 0,
  abs(pooled_timing_bin$participant_probability_q25 - 1 / 3) < 1e-12,
  pooled_timing_bin$participant_probability_median == 0.5,
  abs(pooled_timing_bin$participant_probability_q75 - 2 / 3) < 1e-12,
  pooled_timing_bin$participant_probability_q90 == 1,
  pooled_timing_bin$profile_supported,
  pooled_timing_bin$profile_estimable,
  pooled_timing_bin$probability_total == 0.5,
  pooled_timing_bin$probability_weight == 1,
  nrow(pooled_fold_bin) == 1L,
  pooled_fold_bin$observations == 41L * 30L,
  pooled_fold_bin$valid_minutes == 41L * 30L
)
timing_map <- readRDS(file.path(
  profile_root,
  "metric_relevance_maps.rds"
)) |>
  dplyr::filter(
    .data$profile_scope == "pooled",
    .data$metric_map == "timing_above_250",
    .data$clock_bin == 0L
  )
stopifnot(
  nrow(timing_map) == 1L,
  is.na(timing_map$reference_value),
  timing_map$relevance_source == "participant_balanced_exceedance_distribution",
  timing_map$relevance_mass == pooled_timing_bin$exceedance_probability,
  timing_map$relevance_weight == pooled_timing_bin$probability_weight,
  timing_map$map_estimable == pooled_timing_bin$profile_estimable
)

message("Checking participant-balanced reconstruction")
profiles <- readRDS(file.path(profile_root, "reference_profiles.rds"))
pooled_wake_bin <- profiles |>
  dplyr::filter(
    .data$profile_scope == "pooled",
    .data$state_domain == "wake",
    .data$signal == "MEDI",
    .data$clock_bin == 360L
  )
participant_bin_values <- coverage |>
  dplyr::filter(
    .data$State.Brown == "wake",
    floor(.data$clock_minute / 30L) * 30L == 360L,
    is.finite(.data$MEDI_eligible)
  ) |>
  dplyr::group_by(.data$site, .data$Id) |>
  dplyr::summarise(
    participant_median = stats::median(.data$MEDI_eligible),
    .groups = "drop"
  )
expected_reference <- stats::median(
  participant_bin_values$participant_median
)
stopifnot(
  nrow(pooled_wake_bin) == 1L,
  pooled_wake_bin$reference_value == expected_reference
)

message("Checking timing-distribution value corruption detection")
distribution_rds_path <- file.path(
  profile_root,
  "timing_exceedance_distributions.rds"
)
distribution_csv_path <- file.path(
  profile_root,
  "timing_exceedance_distributions.csv"
)
valid_distributions <- readRDS(distribution_rds_path)
corrupt_distributions <- valid_distributions
corrupt_distribution_index <- which(
  corrupt_distributions$profile_scope == "pooled" &
    corrupt_distributions$clock_bin == 0L
)[[1L]]
corrupt_distributions$exceedance_probability[[
  corrupt_distribution_index
]] <- corrupt_distributions$exceedance_probability[[
  corrupt_distribution_index
]] +
  0.05
saveRDS(
  corrupt_distributions,
  distribution_rds_path,
  version = 3,
  compress = "xz"
)
readr::write_csv(
  corrupt_distributions,
  distribution_csv_path,
  na = ""
)
refresh_verifier_manifest(test_root, "smoke")
distribution_failure <- verify_reference_profile_artifacts(
  root = test_root,
  run_label = "smoke",
  reconstruction = "sampled",
  stop_on_failure = FALSE
)
stopifnot(
  distribution_failure$status == "FAIL",
  "distribution_reconstruction::exceedance_probability" %in%
    distribution_failure$failures$check_id
)
saveRDS(
  valid_distributions,
  distribution_rds_path,
  version = 3,
  compress = "xz"
)
readr::write_csv(
  valid_distributions,
  distribution_csv_path,
  na = ""
)
refresh_verifier_manifest(test_root, "smoke")

message("Checking timing-map linkage corruption detection")
map_rds_path <- file.path(profile_root, "metric_relevance_maps.rds")
map_csv_path <- file.path(profile_root, "metric_relevance_maps.csv")
valid_timing_maps <- readRDS(map_rds_path)
corrupt_timing_maps <- valid_timing_maps
corrupt_timing_index <- which(
  corrupt_timing_maps$profile_scope == "pooled" &
    corrupt_timing_maps$metric_map == "timing_above_250" &
    corrupt_timing_maps$clock_bin == 0L
)[[1L]]
corrupt_timing_maps$relevance_mass[[corrupt_timing_index]] <-
  corrupt_timing_maps$relevance_mass[[corrupt_timing_index]] + 0.05
saveRDS(
  corrupt_timing_maps,
  map_rds_path,
  version = 3,
  compress = "xz"
)
readr::write_csv(corrupt_timing_maps, map_csv_path, na = "")
refresh_verifier_manifest(test_root, "smoke")
timing_map_failure <- verify_reference_profile_artifacts(
  root = test_root,
  run_label = "smoke",
  reconstruction = "sampled",
  stop_on_failure = FALSE
)
stopifnot(
  timing_map_failure$status == "FAIL",
  "timing_map_linkage::relevance_mass" %in%
    timing_map_failure$failures$check_id
)
saveRDS(
  valid_timing_maps,
  map_rds_path,
  version = 3,
  compress = "xz"
)
readr::write_csv(valid_timing_maps, map_csv_path, na = "")
refresh_verifier_manifest(test_root, "smoke")

message("Checking timing-distribution support corruption detection")
distribution_support_path <- file.path(
  profile_root,
  "timing_exceedance_distribution_support.csv"
)
valid_distribution_support <- readr::read_csv(
  distribution_support_path,
  show_col_types = FALSE,
  progress = FALSE
)
corrupt_distribution_support <- valid_distribution_support
corrupt_distribution_support$nonzero_probability_bins[[1L]] <-
  corrupt_distribution_support$nonzero_probability_bins[[1L]] + 1L
readr::write_csv(
  corrupt_distribution_support,
  distribution_support_path,
  na = ""
)
refresh_verifier_manifest(test_root, "smoke")
distribution_support_failure <- verify_reference_profile_artifacts(
  root = test_root,
  run_label = "smoke",
  reconstruction = "sampled",
  stop_on_failure = FALSE
)
stopifnot(
  distribution_support_failure$status == "FAIL",
  "distribution_support::nonzero_probability_bins" %in%
    distribution_support_failure$failures$check_id
)
readr::write_csv(
  valid_distribution_support,
  distribution_support_path,
  na = ""
)
refresh_verifier_manifest(test_root, "smoke")

message("Checking timing-distribution settings corruption detection")
profile_settings_path <- file.path(
  profile_root,
  "reference_profile_settings.csv"
)
valid_profile_settings <- readr::read_csv(
  profile_settings_path,
  show_col_types = FALSE,
  progress = FALSE
)
corrupt_profile_settings <- valid_profile_settings
corrupt_profile_settings$timing_distribution_threshold_lx[[1L]] <- 251
readr::write_csv(
  corrupt_profile_settings,
  profile_settings_path,
  na = ""
)
refresh_verifier_manifest(test_root, "smoke")
distribution_settings_failure <- verify_reference_profile_artifacts(
  root = test_root,
  run_label = "smoke",
  reconstruction = "sampled",
  stop_on_failure = FALSE
)
stopifnot(
  distribution_settings_failure$status == "FAIL",
  "settings::timing_distribution_threshold_lx" %in%
    distribution_settings_failure$failures$check_id,
  "distributions::settings_attribute" %in%
    distribution_settings_failure$failures$check_id
)
readr::write_csv(
  valid_profile_settings,
  profile_settings_path,
  na = ""
)
refresh_verifier_manifest(test_root, "smoke")

message("Checking manifest corruption detection")
valid_manifest <- readr::read_csv(
  manifest_path,
  show_col_types = FALSE,
  progress = FALSE
)
corrupt_manifest <- valid_manifest
corrupt_manifest$sha256[[1L]] <- paste(rep("0", 64L), collapse = "")
readr::write_csv(corrupt_manifest, manifest_path, na = "")
manifest_failure <- verify_reference_profile_artifacts(
  root = test_root,
  run_label = "smoke",
  reconstruction = "sampled",
  stop_on_failure = FALSE
)
stopifnot(
  manifest_failure$status == "FAIL",
  "manifest::bytewise_sha256" %in% manifest_failure$failures$check_id
)
readr::write_csv(valid_manifest, manifest_path, na = "")

message("Checking training-site separation detection")
rewrite_profile_count_artifacts(
  profile_root,
  function(training_sites) rep.int(48L, length(training_sites))
)
refresh_verifier_manifest(test_root, "smoke")
training_failure <- verify_reference_profile_artifacts(
  root = test_root,
  run_label = "smoke",
  reconstruction = "sampled",
  stop_on_failure = FALSE
)
stopifnot(
  training_failure$status == "FAIL",
  "training_sites::training_count_correct" %in%
    training_failure$failures$check_id,
  "reconstruction::training_site_count" %in%
    training_failure$failures$check_id
)
rewrite_profile_count_artifacts(
  profile_root,
  true_training_site_count
)
refresh_verifier_manifest(test_root, "smoke")

message("Checking map-application corruption detection")
valid_maps <- readRDS(file.path(profile_root, "metric_relevance_maps.rds"))
corrupt_maps <- valid_maps
corrupt_index <- which(corrupt_maps$metric_map == "L10")[[1L]]
corrupt_maps$value_correction_allowed[[corrupt_index]] <- TRUE
saveRDS(
  corrupt_maps,
  file.path(profile_root, "metric_relevance_maps.rds"),
  version = 3,
  compress = "xz"
)
readr::write_csv(
  corrupt_maps,
  file.path(profile_root, "metric_relevance_maps.csv"),
  na = ""
)
refresh_verifier_manifest(test_root, "smoke")
map_failure <- verify_reference_profile_artifacts(
  root = test_root,
  run_label = "smoke",
  reconstruction = "sampled",
  stop_on_failure = FALSE
)
stopifnot(
  map_failure$status == "FAIL",
  "maps::dose_only_value_correction" %in% map_failure$failures$check_id,
  "maps_formula::value_correction_allowed" %in%
    map_failure$failures$check_id
)
saveRDS(
  valid_maps,
  file.path(profile_root, "metric_relevance_maps.rds"),
  version = 3,
  compress = "xz"
)
readr::write_csv(
  valid_maps,
  file.path(profile_root, "metric_relevance_maps.csv"),
  na = ""
)
refresh_verifier_manifest(test_root, "smoke")

message("Checking no-interpolation corruption detection")
valid_profiles <- readRDS(file.path(profile_root, "reference_profiles.rds"))
corrupt_profiles <- valid_profiles
unsupported_index <- which(!corrupt_profiles$profile_supported)[[1L]]
corrupt_profiles$supported_reference_value[[unsupported_index]] <- 999
saveRDS(
  corrupt_profiles,
  file.path(profile_root, "reference_profiles.rds"),
  version = 3,
  compress = "xz"
)
readr::write_csv(
  corrupt_profiles,
  file.path(profile_root, "reference_profiles.csv"),
  na = ""
)
refresh_verifier_manifest(test_root, "smoke")
interpolation_failure <- verify_reference_profile_artifacts(
  root = test_root,
  run_label = "smoke",
  reconstruction = "sampled",
  stop_on_failure = FALSE
)
stopifnot(
  interpolation_failure$status == "FAIL",
  "profiles::no_interpolation" %in%
    interpolation_failure$failures$check_id
)
saveRDS(
  valid_profiles,
  file.path(profile_root, "reference_profiles.rds"),
  version = 3,
  compress = "xz"
)
readr::write_csv(
  valid_profiles,
  file.path(profile_root, "reference_profiles.csv"),
  na = ""
)
refresh_verifier_manifest(test_root, "smoke")

message("All independent Preparation 03 artifact-verifier tests passed")
