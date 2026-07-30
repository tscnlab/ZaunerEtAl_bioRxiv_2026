source("scripts/pipeline/paths_io.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

profile_root <- file.path(
  "artifacts",
  "04_reference_profiles",
  "runs",
  "subset_baua"
)
manifest_path <- file.path(
  "artifacts",
  "12_manifests",
  "reference_profile_artifacts_subset_baua.csv"
)

profiles <- readRDS(file.path(profile_root, "reference_profiles.rds"))
maps <- readRDS(file.path(profile_root, "metric_relevance_maps.rds"))
profile_support <- read_csv(
  file.path(profile_root, "reference_profile_support.csv"),
  show_col_types = FALSE
)
map_support <- read_csv(
  file.path(profile_root, "relevance_map_support.csv"),
  show_col_types = FALSE
)
provenance <- read_csv(
  file.path(profile_root, "reference_profile_input_provenance.csv"),
  show_col_types = FALSE
)
settings <- read_csv(
  file.path(profile_root, "reference_profile_settings.csv"),
  show_col_types = FALSE
)
manifest <- read_csv(manifest_path, show_col_types = FALSE)

profile_key <- c(
  "profile_scope",
  "profile_variant",
  "placement",
  "state_domain",
  "signal",
  "clock_bin"
)
map_key <- c(profile_key, "metric_map")

stopifnot(
  nrow(profiles) == nrow(distinct(profiles, across(all_of(profile_key)))),
  nrow(maps) == nrow(distinct(maps, across(all_of(map_key)))),
  setequal(unique(profiles$clock_bin), seq.int(0L, 1410L, by = 30L)),
  all(
    count(
      profiles,
      across(all_of(setdiff(profile_key, "clock_bin")))
    )$n ==
      48L
  ),
  all(
    count(
      maps,
      across(all_of(setdiff(map_key, "clock_bin")))
    )$n ==
      48L
  )
)

stopifnot(
  identical(
    attr(profiles, "profile_learning"),
    "fixed_once_before_participant_day_metrics"
  ),
  identical(settings$participant_day_profiles_fitted, FALSE),
  settings$bin_minutes == 30L,
  identical(
    settings$participant_balance,
    "within_participant_bin_median_then_across_participant_median"
  ),
  identical(
    settings$unsupported_bin_rule,
    "retain_as_unsupported_without_interpolation"
  ),
  identical(settings$l5_permitted, FALSE),
  !any(toupper(maps$metric_map) == "L5"),
  "L10" %in% maps$metric_map
)

expected_maps <- c(
  "dose",
  "L10",
  "M10",
  "paired_channel_coverage",
  "timing_above_250"
)
stopifnot(
  setequal(unique(maps$metric_map), expected_maps),
  all(maps$value_correction_allowed == (maps$metric_map == "dose")),
  !any(maps$ratio_correction_allowed),
  all(
    maps$paired_channel_required ==
      (maps$metric_map == "paired_channel_coverage")
  )
)

estimable_maps <- filter(map_support, .data$map_estimable)
nonestimable_maps <- filter(map_support, !.data$map_estimable)
stopifnot(
  nrow(estimable_maps) > 0L,
  all(abs(estimable_maps$relevance_weight_sum - 1) < 1e-12),
  all(nonestimable_maps$relevance_weight_sum == 0),
  all(
    is.na(
      maps$relevance_weight[
        !maps$map_estimable
      ]
    )
  )
)

pooled_chest_full <- profile_support |>
  filter(
    .data$profile_scope == "pooled",
    .data$placement == "chest",
    .data$state_domain == "full_day"
  )
pooled_glasses_full <- profile_support |>
  filter(
    .data$profile_scope == "pooled",
    .data$placement == "glasses",
    .data$state_domain == "full_day"
  )
site_glasses_full <- profile_support |>
  filter(
    .data$profile_scope == "site_specific",
    .data$placement == "glasses",
    .data$state_domain == "full_day"
  )
stopifnot(
  nrow(pooled_chest_full) == 2L,
  all(pooled_chest_full$minimum_bin_participants == 20L),
  all(pooled_chest_full$supported_bins == 48L),
  all(pooled_chest_full$profile_estimable),
  nrow(pooled_glasses_full) == 2L,
  all(pooled_glasses_full$maximum_bin_participants == 18L),
  all(pooled_glasses_full$supported_bins == 0L),
  !any(pooled_glasses_full$profile_estimable),
  nrow(site_glasses_full) == 2L,
  all(site_glasses_full$supported_bins == 48L),
  all(site_glasses_full$profile_estimable)
)

stopifnot(
  setequal(unique(provenance$placement), c("chest", "glasses")),
  setequal(unique(provenance$signal), c("LIGHT", "MEDI")),
  all(provenance$input_sites == 1L),
  all(provenance$repeated_wall_minutes_averaged == 0L),
  all(provenance$additional_true_rows_in_repeated_minutes == 0L),
  all(provenance$maximum_true_rows_per_wall_minute == 1L),
  all(
    vapply(
      seq_len(nrow(provenance)),
      function(index) {
        artifact_sha256(provenance$input_path[[index]]) ==
          provenance$input_sha256[[index]]
      },
      logical(1)
    )
  )
)

stopifnot(
  nrow(manifest) == 8L,
  all(file.exists(manifest$path)),
  all(
    vapply(
      seq_len(nrow(manifest)),
      function(index) {
        artifact_sha256(manifest$path[[index]]) == manifest$sha256[[index]]
      },
      logical(1)
    )
  )
)

timing_not_estimable <- nonestimable_maps |>
  filter(.data$metric_map == "timing_above_250") |>
  nrow()

cat("PASS: BAUA fixed-profile artifact and manifest checks\n")
cat(
  "Profiles:",
  nrow(profiles),
  "rows across",
  nrow(profile_support),
  "variants\n"
)
cat(
  "Relevance maps:",
  nrow(maps),
  "rows across",
  nrow(map_support),
  "variants\n"
)
cat("Estimable normalized maps:", nrow(estimable_maps), "\n")
cat(
  "Expected BAUA-only pooled full-day glasses profiles below n=20:",
  nrow(pooled_glasses_full),
  "\n"
)
cat(
  "Timing-above-250 maps not estimable on the BAUA median profile:",
  timing_not_estimable,
  "\n"
)
