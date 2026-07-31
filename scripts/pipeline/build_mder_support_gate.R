# Build cutoff-neutral MDER support diagnostics without deriving MDER values.

normalise_mder_gate_run_label <- function(run_label = "full") {
  if (
    !is.character(run_label) ||
      length(run_label) != 1L ||
      is.na(run_label) ||
      !nzchar(trimws(run_label))
  ) {
    abort_pipeline("`run_label` must be one non-empty character value")
  }
  run_label <- trimws(run_label)
  if (!grepl("^[A-Za-z0-9._-]+$", run_label)) {
    abort_pipeline(
      paste0(
        "`run_label` may contain only letters, numbers, dots, ",
        "underscores, and hyphens"
      )
    )
  }
  run_label
}

normalise_mder_gate_root <- function(path, argument, must_work) {
  if (is.null(path)) {
    return(NULL)
  }
  if (
    !is.character(path) ||
      length(path) != 1L ||
      is.na(path) ||
      !nzchar(trimws(path))
  ) {
    abort_pipeline("`%s` must be NULL or one non-empty path", argument)
  }
  normalizePath(trimws(path), winslash = "/", mustWork = must_work)
}

mder_support_gate_layout <- function(
  paths,
  run_label = "full",
  coverage_run_root = NULL,
  profile_run_root = NULL,
  diagnostic_run_root = NULL
) {
  run_label <- normalise_mder_gate_run_label(run_label)
  coverage_run_root <- normalise_mder_gate_root(
    coverage_run_root,
    "coverage_run_root",
    must_work = TRUE
  )
  profile_run_root <- normalise_mder_gate_root(
    profile_run_root,
    "profile_run_root",
    must_work = TRUE
  )
  diagnostic_run_root <- normalise_mder_gate_root(
    diagnostic_run_root,
    "diagnostic_run_root",
    must_work = FALSE
  )
  if (is.null(coverage_run_root)) {
    coverage_run_root <- if (identical(run_label, "full")) {
      paths$coverage
    } else {
      file.path(paths$coverage, "runs", run_label)
    }
  }
  if (is.null(profile_run_root)) {
    profile_run_root <- if (identical(run_label, "full")) {
      paths$profiles
    } else {
      file.path(paths$profiles, "runs", run_label)
    }
  }
  if (is.null(diagnostic_run_root)) {
    diagnostic_run_root <- if (identical(run_label, "full")) {
      file.path(paths$diagnostics, "mder_support_gate")
    } else {
      file.path(
        paths$diagnostics,
        "runs",
        run_label,
        "mder_support_gate"
      )
    }
  }

  metrics_root <- normalizePath(paths$metrics, winslash = "/", mustWork = FALSE)
  diagnostic_normalized <- normalizePath(
    diagnostic_run_root,
    winslash = "/",
    mustWork = FALSE
  )
  if (
    identical(diagnostic_normalized, metrics_root) ||
      startsWith(diagnostic_normalized, paste0(metrics_root, "/"))
  ) {
    abort_pipeline(
      "The MDER author-gate diagnostics may not write below final metrics"
    )
  }
  list(
    run_label = run_label,
    coverage_run_root = coverage_run_root,
    profile_run_root = profile_run_root,
    diagnostic_run_root = diagnostic_run_root,
    manifest_suffix = if (identical(run_label, "full")) {
      ""
    } else {
      paste0("_", run_label)
    }
  )
}

discover_mder_gate_placements <- function(coverage_run_root) {
  candidates <- list.files(
    coverage_run_root,
    pattern = "^light_[A-Za-z0-9._-]+_coverage[.]rds$",
    full.names = FALSE
  )
  sort(unique(sub(
    "^light_(.+)_coverage[.]rds$",
    "\\1",
    candidates
  )))
}

resolve_mder_gate_placements <- function(placements, coverage_run_root) {
  available <- discover_mder_gate_placements(coverage_run_root)
  if (length(available) == 0L) {
    abort_pipeline(
      "No Preparation 02 coverage artifacts were found under %s",
      coverage_run_root
    )
  }
  if (is.null(placements) || length(placements) == 0L) {
    return(available)
  }
  placements <- sort(unique(trimws(as.character(placements))))
  if (
    length(placements) == 0L ||
      anyNA(placements) ||
      any(!nzchar(placements)) ||
      any(!grepl("^[A-Za-z0-9._-]+$", placements))
  ) {
    abort_pipeline("`placements` must contain valid placement labels")
  }
  missing <- setdiff(placements, available)
  if (length(missing) > 0L) {
    abort_pipeline(
      "Missing coverage artifact(s) for placement(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  placements
}

validate_mder_coverage_settings <- function(
  coverage_run_root,
  placements,
  run_label
) {
  run_label <- normalise_mder_gate_run_label(run_label)
  path <- file.path(coverage_run_root, "coverage_settings.csv")
  if (!file.exists(path)) {
    abort_pipeline("Preparation 02 coverage settings are missing: %s", path)
  }
  sha256 <- artifact_sha256(path)
  settings <- readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE
  )
  required <- c(
    "run_label",
    "placement",
    "coverage_rule_id",
    "coverage_signal",
    "daily_denominator_domain",
    "daily_eligibility_basis",
    "hourly_gate_scope",
    "minute_values_masked_by_hour_gate",
    "hour_screened_sensitivity_available",
    "all_zero_medi_exclusion_applied",
    "all_zero_medi_sensitivity_available",
    "diary_sleep_excluded_from_denominator",
    "expected_wall_minutes_per_hour",
    "expected_wall_minutes_per_day",
    "minimum_hour_coverage",
    "minimum_day_coverage"
  )
  assert_columns(settings, required, object = "Preparation 02 settings")
  assert_unique_key(
    settings,
    "placement",
    object = "Preparation 02 settings"
  )
  selected <- dplyr::filter(
    settings,
    .data$placement %in% .env$placements
  )
  if (!setequal(selected$placement, placements)) {
    abort_pipeline(
      "Preparation 02 settings do not identify every requested placement"
    )
  }
  selected_run_label <- as.character(selected$run_label)
  if (
    anyNA(selected_run_label) ||
      any(selected_run_label != run_label)
  ) {
    abort_pipeline(
      "Preparation 02 settings do not match requested run label `%s`",
      run_label
    )
  }
  tolerance <- sqrt(.Machine$double.eps)
  valid <- selected$coverage_rule_id == "A" &
    selected$coverage_signal == "MEDI" &
    selected$daily_denominator_domain == "all_pseudo_local_wall_minutes" &
    selected$daily_eligibility_basis ==
      "finite_medi_minutes_across_fixed_24_hour_cycle" &
    selected$hourly_gate_scope == "hourly_metrics_only" &
    !selected$minute_values_masked_by_hour_gate &
    selected$hour_screened_sensitivity_available &
    selected$all_zero_medi_exclusion_applied &
    selected$all_zero_medi_sensitivity_available &
    !selected$diary_sleep_excluded_from_denominator &
    selected$expected_wall_minutes_per_hour == 60 &
    selected$expected_wall_minutes_per_day == 1440 &
    abs(selected$minimum_hour_coverage - 0.50) <= tolerance &
    abs(selected$minimum_day_coverage - 0.80) <= tolerance
  if (anyNA(valid) || !all(valid)) {
    abort_pipeline(
      paste0(
        "The MDER support gate requires primary Rule A: 80% daily MEDI ",
        "coverage over the fixed 24-hour cycle, with the 50% hourly ",
        "requirement restricted to hourly summaries and otherwise eligible ",
        "all-zero melEDI days excluded"
      )
    )
  }
  list(
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    sha256 = sha256,
    data = dplyr::arrange(selected, .data$placement)
  )
}

validate_mder_profile_settings <- function(profile_run_root, run_label) {
  path <- file.path(profile_run_root, "reference_profile_settings.csv")
  if (!file.exists(path)) {
    abort_pipeline("Preparation 03 profile settings are missing: %s", path)
  }
  sha256 <- artifact_sha256(path)
  settings <- readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE
  )
  required <- c(
    "run_label",
    "input_coverage_rule_id",
    "input_daily_denominator_domain",
    "input_diary_sleep_excluded_from_denominator",
    "profile_learning",
    "participant_day_profiles_fitted",
    "bin_minutes",
    "l5_permitted"
  )
  assert_columns(settings, required, object = "Preparation 03 settings")
  if (
    nrow(settings) != 1L ||
      !identical(as.character(settings$run_label), run_label) ||
      !identical(as.character(settings$input_coverage_rule_id), "A") ||
      !identical(
        as.character(settings$input_daily_denominator_domain),
        "all_pseudo_local_wall_minutes"
      ) ||
      !identical(
        settings$input_diary_sleep_excluded_from_denominator,
        FALSE
      ) ||
      !identical(
        as.character(settings$profile_learning),
        "fixed_once_before_participant_day_metrics"
      ) ||
      !identical(settings$participant_day_profiles_fitted, FALSE) ||
      !identical(as.integer(settings$bin_minutes), 30L) ||
      !identical(settings$l5_permitted, FALSE)
  ) {
    abort_pipeline(
      paste0(
        "Preparation 03 settings must identify fixed, prelearned ",
        "30-minute Rule A profiles with L5 prohibited"
      )
    )
  }
  list(
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    sha256 = sha256,
    data = settings
  )
}

normalise_mder_sha256 <- function(value, argument = "sha256") {
  value <- unname(unclass(as.character(value)))
  if (
    length(value) != 1L ||
      is.na(value) ||
      !grepl("^[0-9a-f]{64}$", value)
  ) {
    abort_pipeline("`%s` must be one lowercase SHA-256 digest", argument)
  }
  value
}

mder_input_row <- function(
  input_type,
  path,
  sha256,
  placement = NA_character_
) {
  info <- file.info(path)
  tibble::tibble(
    input_type = input_type,
    placement = placement,
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    sha256 = normalise_mder_sha256(sha256),
    bytes = unname(info$size)
  )
}

assert_mder_gate_inputs_unchanged <- function(inputs) {
  current <- vapply(inputs$path, artifact_sha256, character(1))
  expected <- vapply(
    inputs$sha256,
    normalise_mder_sha256,
    character(1),
    argument = "inputs$sha256"
  )
  changed <- current != expected
  if (any(changed)) {
    details <- paste(
      sprintf(
        "%s (expected %s; observed %s)",
        inputs$path[changed],
        expected[changed],
        current[changed]
      ),
      collapse = "; "
    )
    abort_pipeline(
      "An MDER support-gate input changed during the run: %s",
      details
    )
  }
  invisible(TRUE)
}

build_mder_support_gate <- function(
  root = project_root(),
  run_label = "full",
  coverage_run_root = NULL,
  profile_run_root = NULL,
  diagnostic_run_root = NULL,
  placements = NULL,
  candidate_cutoffs = mder_support_candidate_cutoffs
) {
  producer <- "scripts/pipeline/build_mder_support_gate.R"
  candidate_cutoffs <- validate_mder_candidate_cutoffs(candidate_cutoffs)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  layout <- mder_support_gate_layout(
    paths = paths,
    run_label = run_label,
    coverage_run_root = coverage_run_root,
    profile_run_root = profile_run_root,
    diagnostic_run_root = diagnostic_run_root
  )
  dir.create(
    layout$diagnostic_run_root,
    recursive = TRUE,
    showWarnings = FALSE
  )
  placements <- resolve_mder_gate_placements(
    placements,
    layout$coverage_run_root
  )
  coverage_settings <- validate_mder_coverage_settings(
    layout$coverage_run_root,
    placements,
    run_label = layout$run_label
  )
  profile_settings <- validate_mder_profile_settings(
    layout$profile_run_root,
    layout$run_label
  )

  profile_path <- file.path(
    layout$profile_run_root,
    "reference_profiles.rds"
  )
  map_path <- file.path(
    layout$profile_run_root,
    "metric_relevance_maps.rds"
  )
  profile_sha256 <- artifact_sha256(profile_path)
  map_sha256 <- artifact_sha256(map_path)
  profiles <- dplyr::ungroup(read_rds_artifact(
    profile_path,
    expected_class = "data.frame"
  ))
  maps <- dplyr::ungroup(read_rds_artifact(
    map_path,
    expected_class = "data.frame"
  ))
  validate_mder_fixed_profiles(profiles, maps, placements)

  inputs <- dplyr::bind_rows(
    mder_input_row(
      "coverage_settings",
      coverage_settings$path,
      coverage_settings$sha256
    ),
    mder_input_row(
      "reference_profile_settings",
      profile_settings$path,
      profile_settings$sha256
    ),
    mder_input_row("fixed_reference_profiles", profile_path, profile_sha256),
    mder_input_row("paired_relevance_maps", map_path, map_sha256)
  )
  daily_rows <- list()
  for (placement in placements) {
    message("Evaluating cutoff-neutral MDER support for ", placement)
    coverage_path <- file.path(
      layout$coverage_run_root,
      paste0("light_", placement, "_coverage.rds")
    )
    coverage_sha256 <- artifact_sha256(coverage_path)
    coverage <- dplyr::ungroup(read_rds_artifact(
      coverage_path,
      expected_class = "data.frame"
    ))
    diagnostic <- derive_mder_support_gate_diagnostics(
      coverage,
      profiles = profiles,
      maps = maps,
      placement = placement,
      candidate_cutoffs = candidate_cutoffs
    )
    daily_rows[[placement]] <- diagnostic$daily
    inputs <- dplyr::bind_rows(
      inputs,
      mder_input_row(
        "preparation02_coverage",
        coverage_path,
        coverage_sha256,
        placement = placement
      )
    )
    rm(coverage, diagnostic)
    invisible(gc())
  }
  inputs <- inputs |>
    dplyr::arrange(.data$input_type, .data$placement, .data$path)
  assert_unique_key(inputs, "path", object = "MDER support-gate input ledger")
  assert_mder_gate_inputs_unchanged(inputs)

  daily <- dplyr::bind_rows(daily_rows) |>
    dplyr::mutate(
      run_label = layout$run_label,
      status = "AUTHOR_GATE_INPUT_NOT_A_SELECTED_RULE",
      .before = 1L
    ) |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$Id,
      .data$local_date
    )
  assert_unique_key(
    daily,
    mder_support_day_key,
    object = "combined daily MDER support diagnostics"
  )
  candidate_daily <- add_mder_candidate_retention(
    daily,
    candidate_cutoffs = candidate_cutoffs
  )
  candidates <- summarise_mder_candidate_retention(candidate_daily) |>
    dplyr::mutate(run_label = layout$run_label, .before = 1L)
  site_candidates <- summarise_mder_candidate_retention_by_site(
    candidate_daily
  ) |>
    dplyr::mutate(run_label = layout$run_label, .before = 1L)
  participant_candidates <- summarise_mder_candidate_retention_by_participant(
    candidate_daily
  ) |>
    dplyr::mutate(run_label = layout$run_label, .before = 1L)
  assert_unique_key(
    candidates,
    c("position", "candidate_support_cutoff"),
    object = "MDER support candidate summary"
  )
  assert_unique_key(
    site_candidates,
    c("position", "site", "candidate_support_cutoff"),
    object = "site-stratified MDER support candidate summary"
  )
  assert_unique_key(
    participant_candidates,
    c("position", "site", "Id", "candidate_support_cutoff"),
    object = "participant-stratified MDER support candidate summary"
  )
  inputs <- inputs |>
    dplyr::mutate(
      run_label = layout$run_label,
      candidate_cutoffs = paste(candidate_cutoffs, collapse = "|"),
      support_profile_variant = "pooled",
      ratio_value_calculated = FALSE,
      ratio_scaled_or_weighted = FALSE,
      status = "AUTHOR_GATE_INPUT_NOT_A_SELECTED_RULE",
      .before = 1L
    )
  input_hash_set <- paste(
    paste(
      inputs$input_type,
      dplyr::coalesce(inputs$placement, "all"),
      inputs$sha256,
      sep = "="
    ),
    collapse = "|"
  )

  daily_path <- file.path(
    layout$diagnostic_run_root,
    "mder_support_gate_daily.csv"
  )
  candidates_path <- file.path(
    layout$diagnostic_run_root,
    "mder_support_candidate_summary.csv"
  )
  site_candidates_path <- file.path(
    layout$diagnostic_run_root,
    "mder_support_candidate_by_site.csv"
  )
  participant_candidates_path <- file.path(
    layout$diagnostic_run_root,
    "mder_support_candidate_by_participant.csv"
  )
  inputs_path <- file.path(
    layout$diagnostic_run_root,
    "mder_support_gate_inputs.csv"
  )
  common_metadata <- list(
    run_label = layout$run_label,
    status = "diagnostic_only_not_final",
    input_hashes = input_hash_set,
    candidate_cutoffs = paste(candidate_cutoffs, collapse = "|"),
    ratio_value_calculated = FALSE,
    ratio_scaled_or_weighted = FALSE
  )
  records <- dplyr::bind_rows(
    manifest_row(write_csv_artifact(
      daily,
      daily_path,
      producer,
      metadata = c(
        list(artifact_type = "mder_support_gate_daily"),
        common_metadata
      )
    )),
    manifest_row(write_csv_artifact(
      candidates,
      candidates_path,
      producer,
      metadata = c(
        list(artifact_type = "mder_support_candidate_summary"),
        common_metadata
      )
    )),
    manifest_row(write_csv_artifact(
      site_candidates,
      site_candidates_path,
      producer,
      metadata = c(
        list(artifact_type = "mder_support_candidate_by_site"),
        common_metadata
      )
    )),
    manifest_row(write_csv_artifact(
      participant_candidates,
      participant_candidates_path,
      producer,
      metadata = c(
        list(artifact_type = "mder_support_candidate_by_participant"),
        common_metadata
      )
    )),
    manifest_row(write_csv_artifact(
      inputs,
      inputs_path,
      producer,
      metadata = c(
        list(artifact_type = "mder_support_gate_inputs"),
        common_metadata
      )
    ))
  ) |>
    dplyr::select(-dplyr::any_of("written_utc")) |>
    dplyr::arrange(.data$artifact_type, .data$path)
  assert_unique_key(
    records,
    "path",
    object = "MDER support-gate artifact manifest"
  )
  manifest_path <- file.path(
    paths$manifests,
    paste0(
      "mder_support_gate_artifacts",
      layout$manifest_suffix,
      ".csv"
    )
  )
  write_csv_artifact(
    records,
    manifest_path,
    producer,
    metadata = c(
      list(artifact_type = "mder_support_gate_artifact_manifest"),
      common_metadata
    )
  )
  assert_mder_gate_inputs_unchanged(inputs)

  list(
    run_label = layout$run_label,
    coverage_run_root = layout$coverage_run_root,
    profile_run_root = layout$profile_run_root,
    diagnostic_run_root = layout$diagnostic_run_root,
    placements = placements,
    daily = daily,
    candidates = candidates,
    site_candidates = site_candidates,
    participant_candidates = participant_candidates,
    inputs = inputs,
    daily_path = daily_path,
    candidates_path = candidates_path,
    site_candidates_path = site_candidates_path,
    participant_candidates_path = participant_candidates_path,
    inputs_path = inputs_path,
    artifact_manifest_path = manifest_path
  )
}

if (sys.nframe() == 0L) {
  root_override <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "")
  execution_root <- if (nzchar(root_override)) {
    normalizePath(root_override, winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  }
  dependencies <- c(
    "paths_io.R",
    "assertions.R",
    "time_axes.R",
    "mder_support_gate.R"
  )
  for (dependency in dependencies) {
    source(file.path(
      execution_root,
      "scripts",
      "pipeline",
      dependency
    ))
  }
  run_label <- Sys.getenv("NATHEALTH_MDER_GATE_RUN_LABEL", unset = "full")
  coverage_root <- Sys.getenv(
    "NATHEALTH_MDER_GATE_COVERAGE_ROOT",
    unset = ""
  )
  profile_root <- Sys.getenv(
    "NATHEALTH_MDER_GATE_PROFILE_ROOT",
    unset = ""
  )
  diagnostic_root <- Sys.getenv(
    "NATHEALTH_MDER_GATE_OUTPUT_ROOT",
    unset = ""
  )
  placement_argument <- Sys.getenv(
    "NATHEALTH_MDER_GATE_PLACEMENTS",
    unset = ""
  )
  result <- build_mder_support_gate(
    root = execution_root,
    run_label = run_label,
    coverage_run_root = if (nzchar(coverage_root)) coverage_root else NULL,
    profile_run_root = if (nzchar(profile_root)) profile_root else NULL,
    diagnostic_run_root = if (nzchar(diagnostic_root)) {
      diagnostic_root
    } else {
      NULL
    },
    placements = if (nzchar(placement_argument)) {
      strsplit(placement_argument, ",", fixed = TRUE)[[1L]]
    } else {
      NULL
    }
  )
  message(
    "MDER support gate complete: ",
    result$daily_path,
    " and ",
    result$candidates_path
  )
}
