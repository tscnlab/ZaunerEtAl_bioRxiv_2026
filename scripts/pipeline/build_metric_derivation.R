# Canonical Preparation 04 executor.

normalise_metric_run_label <- function(run_label = "full") {
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

normalise_metric_profile_variant <- function(profile_variant = "pooled") {
  if (
    !is.character(profile_variant) ||
      length(profile_variant) != 1L ||
      is.na(profile_variant) ||
      !nzchar(trimws(profile_variant))
  ) {
    abort_pipeline(
      "`profile_variant` must be one non-empty character value"
    )
  }
  profile_variant <- trimws(profile_variant)
  allowed <- c("pooled", "site_specific", "leave_one_site_out")
  if (!profile_variant %in% allowed) {
    abort_pipeline(
      "`profile_variant` must be one of: %s",
      paste(allowed, collapse = ", ")
    )
  }
  profile_variant
}

normalise_metric_optional_root <- function(path, argument, must_work) {
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
  normalizePath(
    trimws(path),
    winslash = "/",
    mustWork = must_work
  )
}

metric_derivation_run_layout <- function(
  paths,
  run_label = "full",
  coverage_run_root = NULL,
  state_interval_run_root = NULL,
  state_interval_manifest_path = NULL,
  profile_run_root = NULL,
  metric_run_root = NULL,
  profile_variant = "pooled"
) {
  run_label <- normalise_metric_run_label(run_label)
  profile_variant <- normalise_metric_profile_variant(profile_variant)
  coverage_run_root <- normalise_metric_optional_root(
    coverage_run_root,
    "coverage_run_root",
    must_work = TRUE
  )
  state_interval_run_root <- normalise_metric_optional_root(
    state_interval_run_root,
    "state_interval_run_root",
    must_work = FALSE
  )
  state_interval_manifest_path <- normalise_metric_optional_root(
    state_interval_manifest_path,
    "state_interval_manifest_path",
    must_work = FALSE
  )
  profile_run_root <- normalise_metric_optional_root(
    profile_run_root,
    "profile_run_root",
    must_work = TRUE
  )
  metric_run_root <- normalise_metric_optional_root(
    metric_run_root,
    "metric_run_root",
    must_work = FALSE
  )
  if (is.null(coverage_run_root)) {
    coverage_run_root <- if (identical(run_label, "full")) {
      paths$coverage
    } else {
      file.path(paths$coverage, "runs", run_label)
    }
  }
  if (is.null(state_interval_run_root)) {
    state_interval_run_root <- if (identical(run_label, "full")) {
      file.path(paths$aligned, "state_intervals")
    } else {
      file.path(paths$aligned, "runs", run_label, "state_intervals")
    }
  }
  if (is.null(state_interval_manifest_path)) {
    state_interval_manifest_path <- file.path(
      paths$manifests,
      paste0(
        "state_interval_artifacts",
        if (identical(run_label, "full")) "" else paste0("_", run_label),
        ".csv"
      )
    )
  }
  if (is.null(profile_run_root)) {
    profile_run_root <- if (identical(run_label, "full")) {
      paths$profiles
    } else {
      file.path(paths$profiles, "runs", run_label)
    }
  }
  if (is.null(metric_run_root)) {
    metric_run_root <- if (identical(run_label, "full")) {
      paths$metrics
    } else {
      file.path(paths$metrics, "runs", run_label)
    }
  }
  if (!identical(profile_variant, "pooled")) {
    metric_run_root <- file.path(
      metric_run_root,
      "profile_variants",
      profile_variant
    )
  }
  manifest_suffix <- if (identical(run_label, "full")) {
    ""
  } else {
    paste0("_", run_label)
  }
  if (!identical(profile_variant, "pooled")) {
    manifest_suffix <- paste0(manifest_suffix, "_", profile_variant)
  }
  list(
    run_label = run_label,
    profile_variant = profile_variant,
    coverage_run_root = coverage_run_root,
    state_interval_run_root = state_interval_run_root,
    state_interval_manifest_path = state_interval_manifest_path,
    profile_run_root = profile_run_root,
    metric_run_root = metric_run_root,
    manifest_suffix = manifest_suffix
  )
}

assert_canonical_metric_output_scope <- function(
  layout,
  paths,
  check_profile_input = TRUE
) {
  normalise <- function(path) {
    normalizePath(path, winslash = "/", mustWork = FALSE)
  }
  canonical_output <- identical(
    normalise(layout$metric_run_root),
    normalise(paths$metrics)
  )
  if (!canonical_output) {
    return(invisible(layout))
  }
  canonical_coverage <- identical(
    normalise(layout$coverage_run_root),
    normalise(paths$coverage)
  )
  canonical_state_intervals <- identical(
    normalise(layout$state_interval_run_root),
    normalise(file.path(paths$aligned, "state_intervals"))
  )
  canonical_state_manifest <- identical(
    normalise(layout$state_interval_manifest_path),
    normalise(file.path(paths$manifests, "state_interval_artifacts.csv"))
  )
  canonical_profile <- !check_profile_input ||
    identical(
      normalise(layout$profile_run_root),
      normalise(paths$profiles)
    )
  if (
    !identical(layout$run_label, "full") ||
      !identical(layout$profile_variant, "pooled") ||
      !canonical_coverage ||
      !canonical_state_intervals ||
      !canonical_state_manifest ||
      !canonical_profile
  ) {
    abort_pipeline(
      paste0(
        "Canonical Preparation 04 output is reserved for the pooled full ",
        "run with canonical Preparation 02 and 03 inputs; use a non-full ",
        "run label or a namespaced profile variant"
      )
    )
  }
  invisible(layout)
}

assert_primary_state_support_cutoff <- function(
  minimum_state_support,
  layout,
  paths
) {
  canonical_output <- identical(
    normalizePath(
      layout$metric_run_root,
      winslash = "/",
      mustWork = FALSE
    ),
    normalizePath(paths$metrics, winslash = "/", mustWork = FALSE)
  )
  if (
    canonical_output &&
      !isTRUE(all.equal(
        as.numeric(minimum_state_support),
        0.80,
        tolerance = 1e-12
      ))
  ) {
    abort_pipeline(
      paste0(
        "Canonical Preparation 04 requires the author-approved 0.80 ",
        "state-support cutoff; use a namespaced sensitivity run for ",
        "0.70 or 0.90"
      )
    )
  }
  invisible(minimum_state_support)
}

assert_primary_mder_support_cutoff <- function(
  minimum_mder_support,
  layout,
  paths
) {
  minimum_mder_support <- validate_mder_metric_support_cutoff(
    minimum_mder_support
  )
  canonical_output <- identical(
    normalizePath(
      layout$metric_run_root,
      winslash = "/",
      mustWork = FALSE
    ),
    normalizePath(paths$metrics, winslash = "/", mustWork = FALSE)
  )
  if (
    canonical_output &&
      !isTRUE(all.equal(
        minimum_mder_support,
        0.80,
        tolerance = 1e-12
      ))
  ) {
    abort_pipeline(
      paste0(
        "Canonical Preparation 04 requires the author-approved 0.80 ",
        "MDER-support cutoff; registered 0.70 and 0.90 sensitivities ",
        "must use a namespaced run"
      )
    )
  }
  invisible(minimum_mder_support)
}

discover_metric_placements <- function(coverage_run_root) {
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

resolve_metric_placements <- function(placements, coverage_run_root) {
  available <- discover_metric_placements(coverage_run_root)
  if (length(available) == 0L) {
    abort_pipeline(
      "No coverage artifacts were found under %s",
      coverage_run_root
    )
  }
  if (is.null(placements) || length(placements) == 0L) {
    return(available)
  }
  placements <- unique(trimws(as.character(placements)))
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

validate_preparation02_settings <- function(
  coverage_run_root,
  placements,
  expected_run_label = NULL,
  expected_hour_coverage = 0.50,
  expected_day_coverage = 0.80
) {
  settings_path <- file.path(coverage_run_root, "coverage_settings.csv")
  if (!file.exists(settings_path)) {
    abort_pipeline(
      "Preparation 02 settings are missing: %s",
      settings_path
    )
  }
  settings_sha256 <- artifact_sha256(settings_path)
  settings <- readr::read_csv(
    settings_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  required <- c(
    "run_label",
    "placement",
    "coverage_rule_id",
    "coverage_signal",
    "daily_denominator_domain",
    "diary_sleep_excluded_from_denominator",
    "expected_wall_minutes_per_hour",
    "expected_wall_minutes_per_day",
    "minimum_hour_coverage",
    "minimum_day_coverage"
  )
  assert_columns(
    settings,
    required,
    object = "Preparation 02 coverage settings"
  )
  assert_unique_key(
    settings,
    "placement",
    object = "Preparation 02 coverage settings"
  )
  selected <- dplyr::filter(
    settings,
    .data$placement %in% .env$placements
  )
  if (!setequal(selected$placement, placements)) {
    abort_pipeline(
      paste0(
        "Preparation 02 settings do not identify every requested ",
        "placement exactly once"
      )
    )
  }
  if (
    !is.null(expected_run_label) &&
      (length(expected_run_label) != 1L ||
        is.na(expected_run_label) ||
        any(selected$run_label != expected_run_label))
  ) {
    abort_pipeline(
      "Preparation 02 settings do not match run label '%s'",
      expected_run_label
    )
  }
  tolerance <- sqrt(.Machine$double.eps)
  valid <- selected$coverage_rule_id == "A" &
    selected$coverage_signal == "MEDI" &
    selected$daily_denominator_domain == "all_pseudo_local_wall_minutes" &
    !selected$diary_sleep_excluded_from_denominator &
    selected$expected_wall_minutes_per_hour == 60 &
    selected$expected_wall_minutes_per_day == 1440 &
    abs(selected$minimum_hour_coverage - expected_hour_coverage) <= tolerance &
    abs(selected$minimum_day_coverage - expected_day_coverage) <= tolerance
  if (anyNA(valid) || !all(valid)) {
    abort_pipeline(
      paste0(
        "Preparation 04 requires primary coverage rule A: MEDI coverage ",
        "over all 60/1440 pseudo-local wall minutes with diary sleep ",
        "included, at exactly 0.50 per hour and 0.80 per day"
      )
    )
  }
  if (artifact_sha256(settings_path) != settings_sha256) {
    abort_pipeline(
      "Preparation 02 settings changed while they were being verified"
    )
  }
  list(
    data = dplyr::arrange(selected, .data$placement),
    path = normalizePath(settings_path, winslash = "/", mustWork = TRUE),
    sha256 = settings_sha256
  )
}

assert_metric_long_unique <- function(data, object) {
  assert_columns(
    data,
    c(
      metric_participant_key,
      "local_date",
      "profile_variant",
      "analysis_unit",
      "metric"
    ),
    object = object
  )
  allowed_units <- c("participant_day", "participant")
  invalid_units <- unique(data$analysis_unit[
    is.na(data$analysis_unit) | !data$analysis_unit %in% allowed_units
  ])
  if (length(invalid_units) > 0L) {
    abort_pipeline("%s contains an unknown analysis unit", object)
  }
  participant_day <- dplyr::filter(
    data,
    .data$analysis_unit == "participant_day"
  )
  participant <- dplyr::filter(
    data,
    .data$analysis_unit == "participant"
  )
  if (nrow(participant_day) > 0L) {
    assert_unique_key(
      participant_day,
      c(metric_day_key, "profile_variant", "analysis_unit", "metric"),
      object = paste0(object, " participant-day rows")
    )
  }
  if (nrow(participant) > 0L) {
    assert_unique_key(
      participant,
      c(
        metric_participant_key,
        "profile_variant",
        "analysis_unit",
        "metric"
      ),
      object = paste0(object, " participant rows")
    )
  }
  invisible(data)
}

metric_output_paths <- function(metric_run_root, placement) {
  prefix <- paste0("metrics_", placement, "_")
  list(
    daily_rds = file.path(
      metric_run_root,
      paste0(prefix, "participant_day.rds")
    ),
    daily_csv = file.path(
      metric_run_root,
      paste0(prefix, "participant_day.csv")
    ),
    participant_rds = file.path(
      metric_run_root,
      paste0(prefix, "participant.rds")
    ),
    participant_csv = file.path(
      metric_run_root,
      paste0(prefix, "participant.csv")
    ),
    thirty_minute_rds = file.path(
      metric_run_root,
      paste0(prefix, "30_minute.rds")
    ),
    thirty_minute_csv = file.path(
      metric_run_root,
      paste0(prefix, "30_minute.csv")
    ),
    hourly_rds = file.path(
      metric_run_root,
      paste0(prefix, "one_hour.rds")
    ),
    hourly_csv = file.path(
      metric_run_root,
      paste0(prefix, "one_hour.csv")
    ),
    values = file.path(
      metric_run_root,
      paste0(prefix, "values_long.csv")
    ),
    admissibility = file.path(
      metric_run_root,
      paste0(prefix, "admissibility.csv")
    ),
    support = file.path(
      metric_run_root,
      paste0(prefix, "support_diagnostics.csv")
    ),
    censoring = file.path(
      metric_run_root,
      paste0(prefix, "censoring_diagnostics.csv")
    ),
    gaps = file.path(
      metric_run_root,
      paste0(prefix, "gap_diagnostics.csv")
    )
  )
}

validate_metric_builder_outputs <- function(result, placement) {
  expected_days <- nrow(result$daily_metrics)
  if (
    expected_days < 1L ||
      nrow(result$thirty_minute) != expected_days * 48L ||
      nrow(result$hourly) != expected_days * 24L
  ) {
    abort_pipeline(
      "%s metric grids are not rectangular over retained days",
      placement
    )
  }
  assert_unique_key(
    result$daily_metrics,
    metric_day_key,
    object = paste0(placement, " participant-day metrics")
  )
  assert_unique_key(
    result$participant_metrics,
    metric_participant_key,
    object = paste0(placement, " participant metrics")
  )
  assert_unique_key(
    result$thirty_minute,
    c(metric_day_key, "clock_bin"),
    object = paste0(placement, " 30-minute outcome grid")
  )
  assert_unique_key(
    result$hourly,
    c(metric_day_key, "clock_hour"),
    object = paste0(placement, " one-hour outcome grid")
  )
  assert_metric_long_unique(
    result$metric_values,
    object = paste0(placement, " long metric values")
  )
  assert_unique_key(
    result$support,
    c(metric_day_key, "profile_variant", "metric"),
    object = paste0(placement, " metric support diagnostics")
  )
  assert_metric_long_unique(
    result$admissibility,
    object = paste0(placement, " metric admissibility")
  )
  assert_unique_key(
    result$censoring,
    c(metric_day_key, "profile_variant"),
    object = paste0(placement, " censoring diagnostics")
  )
  assert_unique_key(
    result$gap,
    metric_day_key,
    object = paste0(placement, " gap diagnostics")
  )
  assert_unique_key(
    result$state_support_candidates,
    c(
      "position",
      "metric",
      "state_domain",
      "candidate_state_support_cutoff"
    ),
    object = paste0(placement, " state-support candidates")
  )
  prohibited <- c(
    names(result$daily_metrics),
    names(result$participant_metrics),
    names(result$thirty_minute),
    names(result$hourly),
    unique(result$metric_values$metric)
  )
  if (any(grepl("L5", prohibited, fixed = TRUE))) {
    abort_pipeline("Excluded darkest-five-hour output was produced")
  }
  invisible(TRUE)
}

build_state_support_gate <- function(
  root = project_root(),
  run_label = "full",
  coverage_run_root = NULL,
  state_interval_run_root = NULL,
  state_interval_manifest_path = NULL,
  metric_run_root = NULL,
  placements = NULL,
  profile_variant = "pooled",
  candidate_cutoffs = state_support_candidate_cutoffs
) {
  producer <- "scripts/pipeline/build_metric_derivation.R"
  candidate_cutoffs <- validate_state_support_candidate_cutoffs(
    candidate_cutoffs
  )
  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  layout <- metric_derivation_run_layout(
    paths = paths,
    run_label = run_label,
    coverage_run_root = coverage_run_root,
    state_interval_run_root = state_interval_run_root,
    state_interval_manifest_path = state_interval_manifest_path,
    profile_run_root = paths$profiles,
    metric_run_root = metric_run_root,
    profile_variant = profile_variant
  )
  assert_canonical_metric_output_scope(
    layout,
    paths,
    check_profile_input = FALSE
  )
  dir.create(
    layout$metric_run_root,
    recursive = TRUE,
    showWarnings = FALSE
  )
  placements <- resolve_metric_placements(
    placements,
    layout$coverage_run_root
  )
  preparation02_settings <- validate_preparation02_settings(
    layout$coverage_run_root,
    placements,
    expected_run_label = layout$run_label
  )
  daily_rows <- list()
  candidate_rows <- list()
  input_rows <- list()
  for (placement in placements) {
    coverage_path <- file.path(
      layout$coverage_run_root,
      paste0("light_", placement, "_coverage.rds")
    )
    coverage_sha256 <- artifact_sha256(coverage_path)
    coverage <- dplyr::ungroup(read_rds_artifact(
      coverage_path,
      expected_class = "data.frame"
    ))
    state_inputs <- read_metric_state_interval_inputs(
      state_interval_root = layout$state_interval_run_root,
      state_interval_manifest_path = layout$state_interval_manifest_path,
      sites = sort(unique(as.character(coverage$site))),
      run_label = layout$run_label
    )
    diagnostic <- derive_state_support_gate_diagnostics(
      coverage,
      state_intervals = state_inputs,
      placement = placement,
      candidate_cutoffs = candidate_cutoffs
    )
    if (
      artifact_sha256(coverage_path) != coverage_sha256 ||
        artifact_sha256(preparation02_settings$path) !=
          preparation02_settings$sha256
    ) {
      abort_pipeline(
        paste0(
          "%s coverage input or Preparation 02 settings changed ",
          "during state-support diagnostics"
        ),
        placement
      )
    }
    assert_metric_state_interval_inputs_unchanged(state_inputs)
    daily_rows[[placement]] <- diagnostic$daily_support
    candidate_rows[[placement]] <- diagnostic$candidates
    input_rows[[placement]] <- state_inputs$inputs |>
      dplyr::transmute(
        run_label = layout$run_label,
        profile_variant = layout$profile_variant,
        placement = placement,
        .data$site,
        .data$interval_kind,
        state_interval_path = .data$path,
        state_interval_sha256 = .data$actual_sha256,
        state_interval_manifest_path = .data$manifest_path,
        .data$state_interval_manifest_sha256,
        coverage_path = normalizePath(
          coverage_path,
          winslash = "/",
          mustWork = TRUE
        ),
        coverage_sha256 = coverage_sha256,
        coverage_settings_path = preparation02_settings$path,
        coverage_settings_sha256 = preparation02_settings$sha256,
        verified_minimum_hour_coverage = 0.50,
        verified_minimum_day_coverage = 0.80,
        candidate_cutoffs = paste(candidate_cutoffs, collapse = "|"),
        status = "AUTHOR_GATE_INPUT_NOT_A_SELECTED_RULE"
      )
  }
  daily <- dplyr::bind_rows(daily_rows) |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$Id,
      .data$local_date,
      .data$metric
    )
  candidates <- dplyr::bind_rows(candidate_rows) |>
    dplyr::arrange(
      .data$position,
      .data$metric,
      .data$candidate_state_support_cutoff
    )
  site_candidates <- state_support_cutoff_site_diagnostics(
    daily,
    candidate_cutoffs = candidate_cutoffs
  )
  inputs <- dplyr::bind_rows(input_rows) |>
    dplyr::arrange(.data$placement, .data$site, .data$interval_kind)
  assert_unique_key(
    daily,
    c(metric_day_key, "metric"),
    object = "state-support gate daily diagnostics"
  )
  assert_unique_key(
    candidates,
    c(
      "position",
      "metric",
      "state_domain",
      "candidate_state_support_cutoff"
    ),
    object = "state-support candidate diagnostics"
  )
  assert_unique_key(
    inputs,
    c("placement", "site", "interval_kind"),
    object = "state-support gate inputs"
  )
  daily_path <- file.path(
    layout$metric_run_root,
    "state_support_gate_daily.csv"
  )
  candidates_path <- file.path(
    layout$metric_run_root,
    "state_support_candidate_diagnostics.csv"
  )
  site_candidates_path <- file.path(
    layout$metric_run_root,
    "state_support_candidate_by_site.csv"
  )
  inputs_path <- file.path(
    layout$metric_run_root,
    "state_support_gate_inputs.csv"
  )
  records <- dplyr::bind_rows(
    manifest_row(write_csv_artifact(
      daily,
      daily_path,
      producer,
      metadata = list(
        artifact_type = "state_support_gate_daily",
        run_label = layout$run_label,
        profile_variant = layout$profile_variant,
        status = "author_gate_input"
      )
    )),
    manifest_row(write_csv_artifact(
      candidates,
      candidates_path,
      producer,
      metadata = list(
        artifact_type = "state_support_candidate_diagnostics",
        run_label = layout$run_label,
        profile_variant = layout$profile_variant,
        status = "diagnostic_only_not_final"
      )
    )),
    manifest_row(write_csv_artifact(
      site_candidates,
      site_candidates_path,
      producer,
      metadata = list(
        artifact_type = "state_support_candidate_by_site",
        run_label = layout$run_label,
        profile_variant = layout$profile_variant,
        status = "diagnostic_only_not_final"
      )
    )),
    manifest_row(write_csv_artifact(
      inputs,
      inputs_path,
      producer,
      metadata = list(
        artifact_type = "state_support_gate_inputs",
        run_label = layout$run_label,
        profile_variant = layout$profile_variant,
        status = "author_gate_input"
      )
    ))
  ) |>
    dplyr::arrange(.data$artifact_type, .data$path)
  assert_unique_key(
    records,
    "path",
    object = "state-support gate artifact manifest"
  )
  manifest_path <- file.path(
    paths$manifests,
    paste0("state_support_gate_artifacts", layout$manifest_suffix, ".csv")
  )
  write_csv_artifact(
    records,
    manifest_path,
    producer,
    metadata = list(
      artifact_type = "state_support_gate_artifact_manifest",
      run_label = layout$run_label,
      profile_variant = layout$profile_variant
    )
  )
  list(
    run_label = layout$run_label,
    profile_variant = layout$profile_variant,
    coverage_run_root = layout$coverage_run_root,
    state_interval_run_root = layout$state_interval_run_root,
    state_interval_manifest_path = layout$state_interval_manifest_path,
    metric_run_root = layout$metric_run_root,
    placements = placements,
    daily = daily,
    candidates = candidates,
    site_candidates = site_candidates,
    inputs = inputs,
    daily_path = daily_path,
    candidates_path = candidates_path,
    site_candidates_path = site_candidates_path,
    inputs_path = inputs_path,
    artifact_manifest_path = manifest_path
  )
}

build_metric_derivation <- function(
  root = project_root(),
  run_label = "full",
  coverage_run_root = NULL,
  state_interval_run_root = NULL,
  state_interval_manifest_path = NULL,
  profile_run_root = NULL,
  metric_run_root = NULL,
  placements = NULL,
  profile_variant = "pooled",
  zero_offset = 0.1,
  minimum_window_support = 0.80,
  minimum_relevance_support = 0.80,
  minimum_state_support = NULL,
  minimum_mder_support = 0.80,
  provisional_state_support = FALSE,
  synthetic_test = FALSE,
  minimum_circular_resultant = 0.10
) {
  producer <- "scripts/pipeline/build_metric_derivation.R"
  profile_variant <- normalise_metric_profile_variant(profile_variant)
  if (is.null(minimum_state_support)) {
    abort_pipeline(
      paste0(
        "`minimum_state_support` is required. The canonical primary cutoff ",
        "is the author-approved 0.80; isolated synthetic tests must mark ",
        "their provisional 0.80 setting explicitly."
      )
    )
  }
  validate_fraction(minimum_state_support, "minimum_state_support")
  minimum_mder_support <- validate_mder_metric_support_cutoff(
    minimum_mder_support
  )
  if (
    !is.logical(provisional_state_support) ||
      length(provisional_state_support) != 1L ||
      is.na(provisional_state_support)
  ) {
    abort_pipeline("`provisional_state_support` must be one logical value")
  }
  if (
    !is.logical(synthetic_test) ||
      length(synthetic_test) != 1L ||
      is.na(synthetic_test)
  ) {
    abort_pipeline("`synthetic_test` must be one logical value")
  }

  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  layout <- metric_derivation_run_layout(
    paths = paths,
    run_label = run_label,
    coverage_run_root = coverage_run_root,
    state_interval_run_root = state_interval_run_root,
    state_interval_manifest_path = state_interval_manifest_path,
    profile_run_root = profile_run_root,
    metric_run_root = metric_run_root,
    profile_variant = profile_variant
  )
  assert_canonical_metric_output_scope(layout, paths)
  assert_primary_state_support_cutoff(
    minimum_state_support,
    layout,
    paths
  )
  assert_primary_mder_support_cutoff(
    minimum_mder_support,
    layout,
    paths
  )
  if (
    provisional_state_support &&
      identical(layout$run_label, "full")
  ) {
    abort_pipeline(
      "A provisional state-support cutoff cannot be used for the full run"
    )
  }
  if (provisional_state_support && !synthetic_test) {
    abort_pipeline(
      "A provisional state-support cutoff is permitted only in a synthetic test"
    )
  }
  if (synthetic_test && !provisional_state_support) {
    abort_pipeline(
      "A synthetic test must label its state-support cutoff as provisional"
    )
  }
  if (provisional_state_support && minimum_state_support != 0.80) {
    abort_pipeline(
      "The isolated provisional smoke setting is fixed at 0.80"
    )
  }
  dir.create(
    layout$metric_run_root,
    recursive = TRUE,
    showWarnings = FALSE
  )
  placements <- resolve_metric_placements(
    placements,
    layout$coverage_run_root
  )
  preparation02_settings <- validate_preparation02_settings(
    layout$coverage_run_root,
    placements,
    expected_run_label = layout$run_label
  )

  profile_path <- file.path(
    layout$profile_run_root,
    "reference_profiles.rds"
  )
  timing_distribution_path <- file.path(
    layout$profile_run_root,
    "timing_exceedance_distributions.rds"
  )
  map_path <- file.path(
    layout$profile_run_root,
    "metric_relevance_maps.rds"
  )
  profiles_sha256 <- artifact_sha256(profile_path)
  timing_distribution_sha256 <- artifact_sha256(
    timing_distribution_path
  )
  maps_sha256 <- artifact_sha256(map_path)
  profiles <- dplyr::ungroup(read_rds_artifact(
    profile_path,
    expected_class = "data.frame"
  ))
  timing_distributions <- dplyr::ungroup(read_rds_artifact(
    timing_distribution_path,
    expected_class = "data.frame"
  ))
  maps <- dplyr::ungroup(read_rds_artifact(
    map_path,
    expected_class = "data.frame"
  ))
  validate_fixed_metric_profiles(
    profiles,
    maps,
    distribution_profiles = timing_distributions
  )

  artifact_records <- list()
  record_artifact <- function(metadata, label) {
    artifact_records[[label]] <<- manifest_row(metadata)
    invisible(metadata)
  }
  outputs <- list()
  results <- list()
  settings_rows <- list()
  state_cutoff_rows <- list()
  state_input_rows <- list()

  for (placement in placements) {
    message("Deriving support-aware metrics for ", placement)
    coverage_path <- file.path(
      layout$coverage_run_root,
      paste0("light_", placement, "_coverage.rds")
    )
    coverage_sha256 <- artifact_sha256(coverage_path)
    coverage <- dplyr::ungroup(read_rds_artifact(
      coverage_path,
      expected_class = "data.frame"
    ))
    state_inputs <- read_metric_state_interval_inputs(
      state_interval_root = layout$state_interval_run_root,
      state_interval_manifest_path = layout$state_interval_manifest_path,
      sites = sort(unique(as.character(coverage$site))),
      run_label = layout$run_label
    )
    result <- derive_metric_set(
      coverage = coverage,
      state_intervals = state_inputs,
      profiles = profiles,
      maps = maps,
      placement = placement,
      profile_variant = profile_variant,
      zero_offset = zero_offset,
      minimum_window_support = minimum_window_support,
      minimum_relevance_support = minimum_relevance_support,
      minimum_state_support = minimum_state_support,
      minimum_mder_support = minimum_mder_support,
      minimum_circular_resultant = minimum_circular_resultant
    )
    validate_metric_builder_outputs(result, placement)
    if (
      artifact_sha256(coverage_path) != coverage_sha256 ||
        artifact_sha256(preparation02_settings$path) !=
          preparation02_settings$sha256 ||
        artifact_sha256(profile_path) != profiles_sha256 ||
        artifact_sha256(timing_distribution_path) !=
          timing_distribution_sha256 ||
        artifact_sha256(map_path) != maps_sha256
    ) {
      abort_pipeline(
        "A Preparation 02 or 03 input changed during metric derivation"
      )
    }
    assert_metric_state_interval_inputs_unchanged(state_inputs)

    settings <- tibble::tibble(
      run_label = layout$run_label,
      placement = placement,
      profile_variant = profile_variant,
      coverage_path = normalizePath(
        coverage_path,
        winslash = "/",
        mustWork = TRUE
      ),
      coverage_sha256 = coverage_sha256,
      coverage_settings_path = preparation02_settings$path,
      coverage_settings_sha256 = preparation02_settings$sha256,
      verified_minimum_hour_coverage = 0.50,
      verified_minimum_day_coverage = 0.80,
      state_interval_root = normalizePath(
        layout$state_interval_run_root,
        winslash = "/",
        mustWork = TRUE
      ),
      state_interval_manifest_path = state_inputs$manifest_path,
      state_interval_manifest_sha256 = state_inputs$manifest_sha256,
      state_interval_artifacts = nrow(state_inputs$inputs),
      state_interval_bounds = "[)",
      state_projection_rule = "true_utc_half_open_no_locf",
      state_projection_verification = "all_source_present_rows_exact",
      reference_profiles_path = normalizePath(
        profile_path,
        winslash = "/",
        mustWork = TRUE
      ),
      reference_profiles_sha256 = profiles_sha256,
      timing_exceedance_distributions_path = normalizePath(
        timing_distribution_path,
        winslash = "/",
        mustWork = TRUE
      ),
      timing_exceedance_distributions_sha256 =
        timing_distribution_sha256,
      timing_exceedance_threshold_lx = 250,
      timing_exceedance_comparison = "strict_greater_than",
      timing_exceedance_aggregation =
        "equal_days_within_participant_then_equal_participants",
      timing_exceedance_application = "support_only_no_value_scaling",
      relevance_maps_path = normalizePath(
        map_path,
        winslash = "/",
        mustWork = TRUE
      ),
      relevance_maps_sha256 = maps_sha256,
      minute_epoch_seconds = 60L,
      zero_aware_offset_lx = zero_offset,
      operating_boundary_rule = "finite_MEDI_strictly_below_100000_lx",
      threshold_endpoint_rule = "strict",
      threshold_values_lx = "above_1000|above_250|below_10|below_1",
      thirty_minute_minimum = 15L,
      hourly_minimum = 30L,
      window_minutes = 600L,
      rolling_window_candidate_step_minutes = 1L,
      minimum_window_support = minimum_window_support,
      dose_minimum_relevance_support = minimum_relevance_support,
      maximum_dose_correction_factor = 1 / minimum_relevance_support,
      minimum_circular_resultant = minimum_circular_resultant,
      state_support_cutoff = minimum_state_support,
      state_support_decision_id = "STATE-005",
      state_support_status = if (provisional_state_support) {
        "PROVISIONAL_SYNTHETIC_ONLY_NOT_FINAL"
      } else {
        "author_approved"
      },
      synthetic_test = synthetic_test,
      state_support_candidates = "0.70|0.80|0.90",
      state_support_sensitivity_cutoffs = "0.70|0.90",
      state_failure_scope = "metric_specific_only_day_retained",
      mder_support_cutoff = minimum_mder_support,
      mder_support_decision_id = "METRIC-003",
      mder_support_status = "author_approved",
      mder_support_candidates = "0.7|0.8|0.9",
      mder_support_sensitivity_cutoffs = "0.7|0.9",
      mder_support_rule = "ordinary_and_both_fixed_signal_profile_supports_gte_cutoff",
      mder_failure_scope = "metric_specific_only_day_retained",
      mder_ratio_definition = "ratio_of_observed_paired_integrals",
      mder_ratio_scaled_or_weighted = FALSE,
      m10_wraps_midnight = FALSE,
      l10_wraps_midnight = TRUE,
      rolling_window_profile_bin_minutes = 30L,
      excluded_darkest_window = "five_hour_window_not_produced",
      longest_bout_primary =
        "longest_observed_uninterrupted_above_250_lower_bound",
      longest_bout_missing_rule =
        "missing_or_invalid_minutes_break_observed_runs",
      longest_bout_possible_bound =
        "upper_bound_if_all_missing_or_invalid_minutes_qualified",
      longest_bout_exact_only_sensitivity = TRUE,
      longest_bout_failure_scope =
        "metric_specific_only_day_retained",
      longest_bout_winner_selection_rule =
        "earliest_onset_then_earliest_offset",
      longest_bout_day_boundary_contact_scope =
        "selected_winner_with_any_winning_run_diagnostic",
      clock_time_rule = "average_repeated_fall_back_wall_minutes_for_clock_metrics",
      elapsed_time_rule = "preserve_true_utc_minutes_for_integrals_durations_bouts_and_iv",
      measurement_construct = measurement_construct_for_placement(
        placement
      ),
      eligible_participant_days = nrow(result$daily_metrics),
      participants = nrow(result$participant_metrics),
      thirty_minute_rows = nrow(result$thirty_minute),
      hourly_rows = nrow(result$hourly)
    )
    attr(result$daily_metrics, "metric_settings") <- settings
    attr(result$daily_metrics, "input_sha256") <- c(
      coverage = coverage_sha256,
      state_interval_manifest = state_inputs$manifest_sha256,
      profiles = profiles_sha256,
      timing_distribution = timing_distribution_sha256,
      maps = maps_sha256
    )
    attr(result$participant_metrics, "metric_settings") <- settings
    attr(result$thirty_minute, "metric_settings") <- settings
    attr(result$hourly, "metric_settings") <- settings

    output_paths <- metric_output_paths(
      layout$metric_run_root,
      placement
    )
    common_metadata <- list(
      run_label = layout$run_label,
      placement = placement,
      coverage_sha256 = coverage_sha256,
      coverage_settings_sha256 = preparation02_settings$sha256,
      state_interval_manifest_sha256 = state_inputs$manifest_sha256,
      reference_profiles_sha256 = profiles_sha256,
      timing_exceedance_distributions_sha256 =
        timing_distribution_sha256,
      relevance_maps_sha256 = maps_sha256,
      profile_variant = profile_variant,
      state_support_status = settings$state_support_status,
      mder_support_cutoff = minimum_mder_support,
      mder_support_decision_id = "METRIC-003",
      mder_support_status = "author_approved",
      mder_support_candidates = "0.7|0.8|0.9",
      mder_support_sensitivity_cutoffs = "0.7|0.9",
      mder_support_rule = "ordinary_and_both_fixed_signal_profile_supports_gte_cutoff",
      mder_failure_scope = "metric_specific_only_day_retained",
      mder_ratio_definition = "ratio_of_observed_paired_integrals",
      mder_ratio_scaled_or_weighted = FALSE,
      rolling_window_minutes = 600L,
      rolling_window_candidate_step_minutes = 1L,
      rolling_window_profile_bin_minutes = 30L,
      m10_wraps_midnight = FALSE,
      l10_wraps_midnight = TRUE,
      excluded_darkest_window = "five_hour_window_not_produced",
      longest_bout_primary =
        "longest_observed_uninterrupted_above_250_lower_bound",
      longest_bout_missing_rule =
        "missing_or_invalid_minutes_break_observed_runs",
      longest_bout_possible_bound =
        "upper_bound_if_all_missing_or_invalid_minutes_qualified",
      longest_bout_exact_only_sensitivity = TRUE,
      longest_bout_failure_scope =
        "metric_specific_only_day_retained",
      longest_bout_winner_selection_rule =
        "earliest_onset_then_earliest_offset",
      longest_bout_day_boundary_contact_scope =
        "selected_winner_with_any_winning_run_diagnostic"
    )
    artifact_specification <- list(
      list(
        label = "daily/rds",
        type = "participant_day_metrics_rds",
        data = result$daily_metrics,
        path = output_paths$daily_rds,
        writer = "rds"
      ),
      list(
        label = "daily/csv",
        type = "participant_day_metrics_csv",
        data = result$daily_metrics,
        path = output_paths$daily_csv,
        writer = "csv"
      ),
      list(
        label = "participant/rds",
        type = "participant_is_iv_rds",
        data = result$participant_metrics,
        path = output_paths$participant_rds,
        writer = "rds"
      ),
      list(
        label = "participant/csv",
        type = "participant_is_iv_csv",
        data = result$participant_metrics,
        path = output_paths$participant_csv,
        writer = "csv"
      ),
      list(
        label = "30min/rds",
        type = "complete_30_minute_arithmetic_medi_grid_rds",
        data = result$thirty_minute,
        path = output_paths$thirty_minute_rds,
        writer = "rds"
      ),
      list(
        label = "30min/csv",
        type = "complete_30_minute_arithmetic_medi_grid_csv",
        data = result$thirty_minute,
        path = output_paths$thirty_minute_csv,
        writer = "csv"
      ),
      list(
        label = "hourly/rds",
        type = "complete_one_hour_geometric_medi_grid_rds",
        data = result$hourly,
        path = output_paths$hourly_rds,
        writer = "rds"
      ),
      list(
        label = "hourly/csv",
        type = "complete_one_hour_geometric_medi_grid_csv",
        data = result$hourly,
        path = output_paths$hourly_csv,
        writer = "csv"
      ),
      list(
        label = "values",
        type = "long_metric_values",
        data = result$metric_values,
        path = output_paths$values,
        writer = "csv"
      ),
      list(
        label = "admissibility",
        type = "metric_admissibility",
        data = result$admissibility,
        path = output_paths$admissibility,
        writer = "csv"
      ),
      list(
        label = "support",
        type = "metric_support_diagnostics",
        data = result$support,
        path = output_paths$support,
        writer = "csv"
      ),
      list(
        label = "censoring",
        type = "metric_censoring_diagnostics",
        data = result$censoring,
        path = output_paths$censoring,
        writer = "csv"
      ),
      list(
        label = "gaps",
        type = "metric_gap_diagnostics",
        data = result$gap,
        path = output_paths$gaps,
        writer = "csv"
      )
    )
    for (specification in artifact_specification) {
      metadata <- if (identical(specification$writer, "rds")) {
        write_rds_artifact(
          specification$data,
          specification$path,
          producer,
          metadata = c(
            list(artifact_type = specification$type),
            common_metadata
          )
        )
      } else {
        write_csv_artifact(
          specification$data,
          specification$path,
          producer,
          metadata = c(
            list(artifact_type = specification$type),
            common_metadata
          )
        )
      }
      record_artifact(
        metadata,
        paste(placement, specification$label, sep = "/")
      )
    }

    outputs[[placement]] <- output_paths
    results[[placement]] <- result
    settings_rows[[placement]] <- settings
    state_cutoff_rows[[placement]] <- result$state_support_candidates
    state_input_rows[[placement]] <- state_inputs$inputs |>
      dplyr::transmute(
        run_label = layout$run_label,
        profile_variant = layout$profile_variant,
        placement = placement,
        .data$site,
        .data$interval_kind,
        state_interval_path = .data$path,
        state_interval_sha256 = .data$actual_sha256,
        state_interval_manifest_path = .data$manifest_path,
        .data$state_interval_manifest_sha256
      )
    rm(coverage)
    invisible(gc())
  }

  settings <- dplyr::bind_rows(settings_rows) |>
    dplyr::arrange(.data$placement)
  state_support_candidates <- dplyr::bind_rows(state_cutoff_rows) |>
    dplyr::arrange(
      .data$position,
      .data$metric,
      .data$candidate_state_support_cutoff
    )
  state_interval_inputs <- dplyr::bind_rows(state_input_rows) |>
    dplyr::arrange(.data$placement, .data$site, .data$interval_kind)
  assert_unique_key(
    settings,
    "placement",
    object = "combined metric derivation settings"
  )
  assert_unique_key(
    state_support_candidates,
    c(
      "position",
      "metric",
      "state_domain",
      "candidate_state_support_cutoff"
    ),
    object = "combined state-support candidate diagnostics"
  )
  assert_unique_key(
    state_interval_inputs,
    c("placement", "site", "interval_kind"),
    object = "combined metric state-interval inputs"
  )
  settings_path <- file.path(
    layout$metric_run_root,
    "metric_derivation_settings.csv"
  )
  state_candidates_path <- file.path(
    layout$metric_run_root,
    "state_support_candidate_diagnostics.csv"
  )
  state_inputs_path <- file.path(
    layout$metric_run_root,
    "metric_state_interval_inputs.csv"
  )
  record_artifact(
    write_csv_artifact(
      settings,
      settings_path,
      producer,
      metadata = list(
        artifact_type = "metric_derivation_settings",
        run_label = layout$run_label
      )
    ),
    "combined/settings"
  )
  record_artifact(
    write_csv_artifact(
      state_support_candidates,
      state_candidates_path,
      producer,
      metadata = list(
        artifact_type = "state_support_candidate_diagnostics",
        run_label = layout$run_label,
        status = "diagnostic_only_not_final"
      )
    ),
    "combined/state_support_candidates"
  )
  record_artifact(
    write_csv_artifact(
      state_interval_inputs,
      state_inputs_path,
      producer,
      metadata = list(
        artifact_type = "metric_state_interval_inputs",
        run_label = layout$run_label
      )
    ),
    "combined/state_interval_inputs"
  )

  manifest <- dplyr::bind_rows(artifact_records) |>
    dplyr::arrange(.data$artifact_type, .data$path)
  assert_unique_key(
    manifest,
    "path",
    object = "metric artifact manifest"
  )
  manifest_path <- file.path(
    paths$manifests,
    paste0("metric_artifacts", layout$manifest_suffix, ".csv")
  )
  write_csv_artifact(
    manifest,
    manifest_path,
    producer,
    metadata = list(
      artifact_type = "metric_artifact_manifest",
      run_label = layout$run_label
    )
  )

  list(
    run_label = layout$run_label,
    profile_variant = layout$profile_variant,
    coverage_run_root = layout$coverage_run_root,
    state_interval_run_root = layout$state_interval_run_root,
    state_interval_manifest_path = layout$state_interval_manifest_path,
    profile_run_root = layout$profile_run_root,
    metric_run_root = layout$metric_run_root,
    placements = placements,
    output_paths = outputs,
    settings_path = settings_path,
    state_candidates_path = state_candidates_path,
    state_inputs_path = state_inputs_path,
    artifact_manifest_path = manifest_path,
    results = results,
    settings = settings,
    state_interval_inputs = state_interval_inputs,
    state_support_candidates = state_support_candidates
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
    "state_alignment.R",
    "time_axes.R",
    "time_support.R",
    "reference_profiles.R",
    "state_interval_projection.R",
    "metric_derivation.R"
  )
  for (dependency in dependencies) {
    source(file.path(
      execution_root,
      "scripts",
      "pipeline",
      dependency
    ))
  }
  run_label <- Sys.getenv(
    "NATHEALTH_METRIC_RUN_LABEL",
    unset = "full"
  )
  coverage_root <- Sys.getenv(
    "NATHEALTH_COVERAGE_RUN_ROOT",
    unset = ""
  )
  state_interval_root <- Sys.getenv(
    "NATHEALTH_STATE_INTERVAL_RUN_ROOT",
    unset = ""
  )
  state_interval_manifest <- Sys.getenv(
    "NATHEALTH_STATE_INTERVAL_MANIFEST",
    unset = ""
  )
  profile_root <- Sys.getenv(
    "NATHEALTH_PROFILE_RUN_ROOT",
    unset = ""
  )
  metric_root <- Sys.getenv(
    "NATHEALTH_METRIC_RUN_ROOT",
    unset = ""
  )
  placement_argument <- Sys.getenv(
    "NATHEALTH_METRIC_PLACEMENTS",
    unset = ""
  )
  profile_variant <- Sys.getenv(
    "NATHEALTH_METRIC_PROFILE_VARIANT",
    unset = "pooled"
  )
  state_support_argument <- Sys.getenv(
    "NATHEALTH_STATE_SUPPORT_CUTOFF",
    unset = ""
  )
  if (!nzchar(state_support_argument)) {
    state_support_argument <- if (identical(run_label, "full")) {
      "0.80"
    } else {
      abort_pipeline(
        paste0(
          "Set NATHEALTH_STATE_SUPPORT_CUTOFF explicitly for a namespaced ",
          "non-full sensitivity run"
        )
      )
    }
  }
  state_support_cutoff <- suppressWarnings(as.numeric(state_support_argument))
  if (
    length(state_support_cutoff) != 1L ||
      !is.finite(state_support_cutoff)
  ) {
    abort_pipeline("NATHEALTH_STATE_SUPPORT_CUTOFF must be numeric")
  }
  mder_support_argument <- Sys.getenv(
    "NATHEALTH_MDER_SUPPORT_CUTOFF",
    unset = ""
  )
  if (!nzchar(mder_support_argument)) {
    mder_support_argument <- if (identical(run_label, "full")) {
      "0.80"
    } else {
      abort_pipeline(
        paste0(
          "Set NATHEALTH_MDER_SUPPORT_CUTOFF explicitly for a namespaced ",
          "non-full sensitivity run"
        )
      )
    }
  }
  mder_support_cutoff <- suppressWarnings(as.numeric(mder_support_argument))
  if (
    length(mder_support_cutoff) != 1L ||
      !is.finite(mder_support_cutoff)
  ) {
    abort_pipeline("NATHEALTH_MDER_SUPPORT_CUTOFF must be numeric")
  }
  result <- build_metric_derivation(
    root = execution_root,
    run_label = run_label,
    coverage_run_root = if (nzchar(coverage_root)) coverage_root else NULL,
    state_interval_run_root = if (nzchar(state_interval_root)) {
      state_interval_root
    } else {
      NULL
    },
    state_interval_manifest_path = if (nzchar(state_interval_manifest)) {
      state_interval_manifest
    } else {
      NULL
    },
    profile_run_root = if (nzchar(profile_root)) profile_root else NULL,
    metric_run_root = if (nzchar(metric_root)) metric_root else NULL,
    placements = if (nzchar(placement_argument)) {
      strsplit(placement_argument, ",", fixed = TRUE)[[1L]]
    } else {
      NULL
    },
    profile_variant = profile_variant,
    minimum_state_support = state_support_cutoff,
    minimum_mder_support = mder_support_cutoff,
    provisional_state_support = FALSE
  )
  print(result$settings)
}
