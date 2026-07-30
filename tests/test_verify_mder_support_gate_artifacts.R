source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/time_axes.R")
source("scripts/pipeline/mder_support_gate.R")
source("scripts/pipeline/build_mder_support_gate.R")
source("scripts/pipeline/verify_mder_support_gate_artifacts.R")

options(warn = 2)

test_mder_verifier_profiles <- function(placement = "glasses") {
  clock_bin <- seq.int(0L, 1410L, by = 30L)
  daytime <- clock_bin >= 360L & clock_bin < 1080L
  signal_values <- list(
    MEDI = ifelse(daytime, 100, 1),
    LIGHT = ifelse(daytime, 1, 100)
  )
  profiles <- dplyr::bind_rows(lapply(
    names(signal_values),
    function(signal) {
      reference <- signal_values[[signal]]
      tibble::tibble(
        profile_scope = "pooled",
        profile_variant = "pooled",
        placement = placement,
        state_domain = "full_day",
        signal = signal,
        clock_bin = clock_bin,
        bin_minutes = 30L,
        profile_supported = TRUE,
        reference_weight = reference / sum(reference)
      )
    }
  ))
  maps <- profiles |>
    dplyr::mutate(
      metric_map = "paired_channel_coverage",
      map_application = "paired_coverage_only",
      map_estimable = TRUE,
      relevance_weight = .data$reference_weight,
      ratio_correction_allowed = FALSE,
      paired_channel_required = TRUE
    )
  list(profiles = profiles, maps = maps)
}

test_mder_verifier_day <- function(
  date,
  id,
  site,
  scenario,
  timezone = "UTC",
  placement = "glasses"
) {
  day_index <- tibble::tibble(
    site = site,
    Id = id,
    position = placement,
    local_date = as.Date(date),
    timezone = timezone
  )
  grid <- build_true_minute_day_grid(day_index)
  medi <- rep(100, nrow(grid))
  light <- rep(200, nrow(grid))
  if (identical(scenario, "exact_80")) {
    retained <- grid$clock_minute %% 5L != 0L
    medi[!retained] <- NA_real_
    light[!retained] <- NA_real_
  } else if (identical(scenario, "no_pairing")) {
    light[] <- NA_real_
  } else if (identical(scenario, "zero_denominator")) {
    light[] <- 0
  } else if (!identical(scenario, "all_observed")) {
    stop("Unknown verifier test scenario", call. = FALSE)
  }
  grid$day_eligible <- TRUE
  grid$MEDI_eligible <- medi
  grid$LIGHT_eligible <- light
  grid$source_subepochs <- 1L
  grid |>
    dplyr::select(dplyr::all_of(c(
      "site",
      "Id",
      "position",
      "local_date",
      "timezone",
      "datetime_utc",
      "clock_minute",
      "day_eligible",
      "MEDI_eligible",
      "LIGHT_eligible",
      "source_subepochs"
    )))
}

test_mder_verifier_provenance <- function(
  coverage,
  coverage_path,
  placement
) {
  coverage_hash <- artifact_sha256(coverage_path)
  coverage_bytes <- unname(file.info(coverage_path)$size)
  participants <- nrow(dplyr::distinct(
    coverage,
    .data$site,
    .data$Id
  ))
  participant_days <- nrow(dplyr::distinct(
    coverage,
    .data$site,
    .data$Id,
    .data$position,
    .data$local_date
  ))
  dplyr::bind_rows(lapply(c("LIGHT", "MEDI"), function(signal) {
    tibble::tibble(
      placement = placement,
      signal = signal,
      input_path = normalizePath(
        coverage_path,
        winslash = "/",
        mustWork = TRUE
      ),
      input_sha256 = coverage_hash,
      input_bytes = coverage_bytes,
      input_sites = dplyr::n_distinct(coverage$site),
      input_participants = participants,
      input_participant_days = participant_days,
      input_true_utc_minutes = nrow(coverage),
      input_true_utc_start = format(
        min(coverage$datetime_utc),
        tz = "UTC",
        usetz = TRUE
      ),
      input_true_utc_end = format(
        max(coverage$datetime_utc),
        tz = "UTC",
        usetz = TRUE
      ),
      eligible_true_utc_minutes = sum(
        is.finite(coverage[[paste0(signal, "_eligible")]])
      ),
      clock_coordinate = "pseudo_local_wall_clock",
      absolute_coordinate = "datetime_utc_preserved_in_input"
    )
  }))
}

test_mder_verifier_fixture <- function() {
  root <- tempfile("nathealth-mder-verifier-")
  dir.create(root, recursive = TRUE)
  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  run_label <- "smoke"
  coverage_root <- file.path(paths$coverage, "runs", run_label)
  profile_root <- file.path(paths$profiles, "runs", run_label)
  diagnostic_root <- file.path(
    paths$diagnostics,
    "runs",
    run_label,
    "mder_support_gate"
  )
  dir.create(coverage_root, recursive = TRUE)
  dir.create(profile_root, recursive = TRUE)

  coverage <- dplyr::bind_rows(
    test_mder_verifier_day(
      "2026-01-01",
      "P01",
      "TEST",
      "all_observed"
    ),
    test_mder_verifier_day(
      "2026-01-02",
      "P01",
      "TEST",
      "exact_80"
    ),
    test_mder_verifier_day(
      "2026-01-03",
      "P01",
      "TEST",
      "no_pairing"
    ),
    test_mder_verifier_day(
      "2026-01-04",
      "P01",
      "TEST",
      "zero_denominator"
    ),
    test_mder_verifier_day(
      "2026-03-29",
      "P02",
      "BERLIN",
      "all_observed",
      timezone = "Europe/Berlin"
    ),
    test_mder_verifier_day(
      "2026-10-25",
      "P02",
      "BERLIN",
      "all_observed",
      timezone = "Europe/Berlin"
    )
  )
  coverage_path <- file.path(
    coverage_root,
    "light_glasses_coverage.rds"
  )
  saveRDS(coverage, coverage_path, version = 3, compress = "xz")
  coverage_settings_path <- file.path(
    coverage_root,
    "coverage_settings.csv"
  )
  readr::write_csv(
    tibble::tibble(
      run_label = run_label,
      placement = "glasses",
      coverage_rule_id = "A",
      coverage_signal = "MEDI",
      daily_denominator_domain = "all_pseudo_local_wall_minutes",
      diary_sleep_excluded_from_denominator = FALSE,
      expected_wall_minutes_per_hour = 60L,
      expected_wall_minutes_per_day = 1440L,
      minimum_hour_coverage = 0.50,
      minimum_day_coverage = 0.80
    ),
    coverage_settings_path
  )

  fixed <- test_mder_verifier_profiles()
  profile_path <- file.path(profile_root, "reference_profiles.rds")
  map_path <- file.path(profile_root, "metric_relevance_maps.rds")
  saveRDS(fixed$profiles, profile_path, version = 3, compress = "xz")
  saveRDS(fixed$maps, map_path, version = 3, compress = "xz")
  coverage_hash <- artifact_sha256(coverage_path)
  profile_settings_path <- file.path(
    profile_root,
    "reference_profile_settings.csv"
  )
  readr::write_csv(
    tibble::tibble(
      run_label = run_label,
      input_coverage_rule_id = "A",
      input_coverage_settings_path = normalizePath(
        coverage_settings_path,
        winslash = "/",
        mustWork = TRUE
      ),
      input_coverage_settings_sha256 = artifact_sha256(
        coverage_settings_path
      ),
      input_daily_denominator_domain = "all_pseudo_local_wall_minutes",
      input_diary_sleep_excluded_from_denominator = FALSE,
      profile_learning = "fixed_once_before_participant_day_metrics",
      participant_day_profiles_fitted = FALSE,
      bin_minutes = 30L,
      l5_permitted = FALSE,
      input_hashes = paste0("glasses=", coverage_hash)
    ),
    profile_settings_path
  )
  profile_provenance_path <- file.path(
    profile_root,
    "reference_profile_input_provenance.csv"
  )
  readr::write_csv(
    test_mder_verifier_provenance(
      coverage,
      coverage_path,
      "glasses"
    ),
    profile_provenance_path
  )
  result <- build_mder_support_gate(
    root = root,
    run_label = run_label,
    coverage_run_root = coverage_root,
    profile_run_root = profile_root,
    diagnostic_run_root = diagnostic_root,
    placements = "glasses"
  )
  list(
    root = root,
    run_label = run_label,
    paths = paths,
    coverage_root = coverage_root,
    profile_root = profile_root,
    diagnostic_root = diagnostic_root,
    coverage = coverage,
    coverage_path = coverage_path,
    profile_path = profile_path,
    map_path = map_path,
    profile_provenance_path = profile_provenance_path,
    result = result
  )
}

test_mder_verifier_expect_error <- function(expression, pattern) {
  observed <- tryCatch(
    {
      force(expression)
      ""
    },
    error = function(error) conditionMessage(error)
  )
  stopifnot(
    nzchar(observed),
    grepl(pattern, observed, fixed = TRUE)
  )
  invisible(observed)
}

test_mder_verifier_refresh_manifest <- function(
  manifest_path,
  artifact_path
) {
  manifest <- readr::read_csv(
    manifest_path,
    show_col_types = FALSE,
    progress = FALSE,
    col_types = readr::cols(
      input_hashes = readr::col_character(),
      candidate_cutoffs = readr::col_character()
    )
  )
  normalized <- normalizePath(
    artifact_path,
    winslash = "/",
    mustWork = TRUE
  )
  rows <- normalizePath(
    manifest$path,
    winslash = "/",
    mustWork = TRUE
  ) ==
    normalized
  stopifnot(sum(rows) == 1L)
  artifact <- readr::read_csv(
    artifact_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  manifest$sha256[rows] <- artifact_sha256(artifact_path)
  manifest$bytes[rows] <- unname(file.info(artifact_path)$size)
  manifest$rows[rows] <- nrow(artifact)
  manifest$columns[rows] <- ncol(artifact)
  readr::write_csv(manifest, manifest_path, na = "")
  invisible(manifest_path)
}

message("Building isolated MDER verifier fixture")
fixture <- test_mder_verifier_fixture()
on.exit(unlink(fixture$root, recursive = TRUE), add = TRUE)

message(
  "Checking independent daily, aggregate, provenance, and hash verification"
)
verified <- verify_mder_support_gate_artifacts(
  root = fixture$root,
  run_label = fixture$run_label,
  coverage_run_root = fixture$coverage_root,
  profile_run_root = fixture$profile_root,
  diagnostic_run_root = fixture$diagnostic_root,
  manifest_path = fixture$result$artifact_manifest_path
)
exact_80 <- readr::read_csv(
  fixture$result$daily_path,
  show_col_types = FALSE,
  progress = FALSE,
  col_types = readr::cols(local_date = readr::col_date())
) |>
  dplyr::filter(.data$local_date == as.Date("2026-01-02"))
stopifnot(
  identical(verified$status, "PASS"),
  identical(verified$daily_rows, 6L),
  identical(verified$summary_rows, 3L),
  identical(verified$site_summary_rows, 6L),
  identical(verified$participant_summary_rows, 6L),
  identical(verified$cutoffs, c(0.70, 0.80, 0.90)),
  !verified$l5_present,
  !verified$ratio_value_calculated,
  verified$immutable_inputs,
  abs(exact_80$ordinary_paired_coverage - 0.80) < 1e-12,
  abs(exact_80$medi_paired_profile_coverage - 0.80) < 1e-12,
  abs(exact_80$light_paired_profile_coverage - 0.80) < 1e-12,
  !exact_80$retained_at_0_90
)
inclusive <- exact_80
inclusive$ordinary_paired_coverage <- 0.80
inclusive$medi_paired_profile_coverage <- 0.80
inclusive$light_paired_profile_coverage <- 0.80
inclusive$positive_light_integral <- TRUE
inclusive_classification <- mder_gate_verifier_classify(inclusive)
stopifnot(
  inclusive_classification$retained_at_candidate[
    inclusive_classification$candidate_support_cutoff == 0.80
  ],
  !inclusive_classification$retained_at_candidate[
    inclusive_classification$candidate_support_cutoff == 0.90
  ]
)

message("Checking strict MEDI boundary and canonical true-minute rejection")
boundary_coverage <- fixture$coverage
boundary_coverage$MEDI_eligible[1L] <- 100000
test_mder_verifier_expect_error(
  mder_gate_verifier_validate_coverage(
    boundary_coverage,
    "glasses"
  ),
  "strict MEDI <100000 lx"
)
missing_minute <- fixture$coverage[-1L, , drop = FALSE]
test_mder_verifier_expect_error(
  mder_gate_verifier_validate_coverage(
    missing_minute,
    "glasses"
  ),
  "complete canonical true-minute day grid"
)

message("Checking malformed signal-specific maps and L5 rejection")
bad_maps <- test_mder_verifier_profiles()$maps
bad_maps$relevance_weight[1L] <-
  bad_maps$relevance_weight[1L] + 0.01
test_mder_verifier_expect_error(
  mder_gate_verifier_validate_profiles(
    test_mder_verifier_profiles()$profiles,
    bad_maps,
    placements = "glasses"
  ),
  "relevance map is invalid"
)
l5_table <- tibble::tibble(metric = "L5")
test_mder_verifier_expect_error(
  mder_gate_verifier_assert_no_l5(l5 = l5_table),
  "Excluded L5 content"
)

message("Checking manifest catches byte corruption")
manifest_backup <- tempfile("mder-manifest-backup-")
stopifnot(file.copy(
  fixture$result$artifact_manifest_path,
  manifest_backup,
  overwrite = TRUE
))
manifest <- readr::read_csv(
  fixture$result$artifact_manifest_path,
  show_col_types = FALSE,
  progress = FALSE,
  col_types = readr::cols(
    input_hashes = readr::col_character(),
    candidate_cutoffs = readr::col_character()
  )
)
manifest$bytes[[1L]] <- manifest$bytes[[1L]] + 1
readr::write_csv(
  manifest,
  fixture$result$artifact_manifest_path,
  na = ""
)
test_mder_verifier_expect_error(
  verify_mder_support_gate_artifacts(
    root = fixture$root,
    run_label = fixture$run_label,
    coverage_run_root = fixture$coverage_root,
    profile_run_root = fixture$profile_root,
    diagnostic_run_root = fixture$diagnostic_root,
    manifest_path = fixture$result$artifact_manifest_path
  ),
  "manifest path/hash/bytes/rows/columns disagree"
)
stopifnot(file.copy(
  manifest_backup,
  fixture$result$artifact_manifest_path,
  overwrite = TRUE
))

message("Checking semantic corruption survives refreshed manifest metadata")
daily_backup <- tempfile("mder-daily-backup-")
stopifnot(file.copy(
  fixture$result$daily_path,
  daily_backup,
  overwrite = TRUE
))
daily <- readr::read_csv(
  fixture$result$daily_path,
  show_col_types = FALSE,
  progress = FALSE,
  col_types = readr::cols(
    local_date = readr::col_date(),
    failure_reason = readr::col_character()
  )
)
daily$medi_paired_profile_coverage[[1L]] <-
  daily$medi_paired_profile_coverage[[1L]] - 0.01
readr::write_csv(daily, fixture$result$daily_path, na = "")
test_mder_verifier_refresh_manifest(
  fixture$result$artifact_manifest_path,
  fixture$result$daily_path
)
test_mder_verifier_expect_error(
  verify_mder_support_gate_artifacts(
    root = fixture$root,
    run_label = fixture$run_label,
    coverage_run_root = fixture$coverage_root,
    profile_run_root = fixture$profile_root,
    diagnostic_run_root = fixture$diagnostic_root,
    manifest_path = fixture$result$artifact_manifest_path
  ),
  "independent reconstruction in `medi_paired_profile_coverage`"
)
stopifnot(file.copy(
  daily_backup,
  fixture$result$daily_path,
  overwrite = TRUE
))
test_mder_verifier_refresh_manifest(
  fixture$result$artifact_manifest_path,
  fixture$result$daily_path
)

message("Checking site and participant summary corruption")
site_backup <- tempfile("mder-site-backup-")
stopifnot(file.copy(
  fixture$result$site_candidates_path,
  site_backup,
  overwrite = TRUE
))
site_summary <- readr::read_csv(
  fixture$result$site_candidates_path,
  show_col_types = FALSE,
  progress = FALSE
)
site_summary$retained_participant_days[[1L]] <-
  site_summary$retained_participant_days[[1L]] + 1L
readr::write_csv(
  site_summary,
  fixture$result$site_candidates_path,
  na = ""
)
test_mder_verifier_refresh_manifest(
  fixture$result$artifact_manifest_path,
  fixture$result$site_candidates_path
)
test_mder_verifier_expect_error(
  verify_mder_support_gate_artifacts(
    root = fixture$root,
    run_label = fixture$run_label,
    coverage_run_root = fixture$coverage_root,
    profile_run_root = fixture$profile_root,
    diagnostic_run_root = fixture$diagnostic_root,
    manifest_path = fixture$result$artifact_manifest_path
  ),
  "site MDER candidate summary disagrees"
)
stopifnot(file.copy(
  site_backup,
  fixture$result$site_candidates_path,
  overwrite = TRUE
))
test_mder_verifier_refresh_manifest(
  fixture$result$artifact_manifest_path,
  fixture$result$site_candidates_path
)

participant_backup <- tempfile("mder-participant-backup-")
stopifnot(file.copy(
  fixture$result$participant_candidates_path,
  participant_backup,
  overwrite = TRUE
))
participant_summary <- readr::read_csv(
  fixture$result$participant_candidates_path,
  show_col_types = FALSE,
  progress = FALSE
)
participant_summary$classification_total[[1L]] <-
  participant_summary$classification_total[[1L]] + 1L
readr::write_csv(
  participant_summary,
  fixture$result$participant_candidates_path,
  na = ""
)
test_mder_verifier_refresh_manifest(
  fixture$result$artifact_manifest_path,
  fixture$result$participant_candidates_path
)
test_mder_verifier_expect_error(
  verify_mder_support_gate_artifacts(
    root = fixture$root,
    run_label = fixture$run_label,
    coverage_run_root = fixture$coverage_root,
    profile_run_root = fixture$profile_root,
    diagnostic_run_root = fixture$diagnostic_root,
    manifest_path = fixture$result$artifact_manifest_path
  ),
  "participant MDER candidate summary disagrees"
)
stopifnot(file.copy(
  participant_backup,
  fixture$result$participant_candidates_path,
  overwrite = TRUE
))
test_mder_verifier_refresh_manifest(
  fixture$result$artifact_manifest_path,
  fixture$result$participant_candidates_path
)

message("Checking non-registered cutoff and refreshed hash rejection")
summary_backup <- tempfile("mder-summary-backup-")
stopifnot(file.copy(
  fixture$result$candidates_path,
  summary_backup,
  overwrite = TRUE
))
summary <- readr::read_csv(
  fixture$result$candidates_path,
  show_col_types = FALSE,
  progress = FALSE
)
summary$candidate_support_cutoff[[1L]] <- 0.75
readr::write_csv(summary, fixture$result$candidates_path, na = "")
test_mder_verifier_refresh_manifest(
  fixture$result$artifact_manifest_path,
  fixture$result$candidates_path
)
test_mder_verifier_expect_error(
  verify_mder_support_gate_artifacts(
    root = fixture$root,
    run_label = fixture$run_label,
    coverage_run_root = fixture$coverage_root,
    profile_run_root = fixture$profile_root,
    diagnostic_run_root = fixture$diagnostic_root,
    manifest_path = fixture$result$artifact_manifest_path
  ),
  "must contain exactly 0.70, 0.80, and 0.90"
)
stopifnot(file.copy(
  summary_backup,
  fixture$result$candidates_path,
  overwrite = TRUE
))
test_mder_verifier_refresh_manifest(
  fixture$result$artifact_manifest_path,
  fixture$result$candidates_path
)

message("Checking final restored fixture")
restored <- verify_mder_support_gate_artifacts(
  root = fixture$root,
  run_label = fixture$run_label,
  coverage_run_root = fixture$coverage_root,
  profile_run_root = fixture$profile_root,
  diagnostic_run_root = fixture$diagnostic_root,
  manifest_path = fixture$result$artifact_manifest_path
)
stopifnot(identical(restored$status, "PASS"))

message("Independent MDER support-gate verifier tests passed")
