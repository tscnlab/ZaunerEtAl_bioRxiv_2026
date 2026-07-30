# Build diagnostic-only comparisons of three daily coverage rules.

normalise_daily_coverage_run_label <- function(run_label = "full") {
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

normalise_daily_coverage_root <- function(path, argument, must_work) {
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

daily_coverage_diagnostic_layout <- function(
  paths,
  run_label = "full",
  aligned_run_root = NULL,
  diagnostic_run_root = NULL
) {
  run_label <- normalise_daily_coverage_run_label(run_label)
  aligned_run_root <- normalise_daily_coverage_root(
    aligned_run_root,
    "aligned_run_root",
    must_work = TRUE
  )
  diagnostic_run_root <- normalise_daily_coverage_root(
    diagnostic_run_root,
    "diagnostic_run_root",
    must_work = FALSE
  )
  if (is.null(aligned_run_root)) {
    aligned_run_root <- if (identical(run_label, "full")) {
      paths$aligned
    } else {
      file.path(paths$aligned, "runs", run_label)
    }
  }
  if (is.null(diagnostic_run_root)) {
    diagnostic_run_root <- if (identical(run_label, "full")) {
      file.path(
        paths$diagnostics,
        "daily_coverage_rule_comparison"
      )
    } else {
      file.path(
        paths$diagnostics,
        "runs",
        run_label,
        "daily_coverage_rule_comparison"
      )
    }
  }
  diagnostics_root <- normalizePath(
    paths$diagnostics,
    winslash = "/",
    mustWork = FALSE
  )
  diagnostic_run_root <- normalizePath(
    diagnostic_run_root,
    winslash = "/",
    mustWork = FALSE
  )
  if (
    !identical(diagnostic_run_root, diagnostics_root) &&
      !startsWith(diagnostic_run_root, paste0(diagnostics_root, "/"))
  ) {
    abort_pipeline(
      "Coverage-rule diagnostics must be written below `artifacts/08_diagnostics`"
    )
  }
  list(
    run_label = run_label,
    aligned_run_root = aligned_run_root,
    diagnostic_run_root = diagnostic_run_root
  )
}

discover_daily_coverage_placements <- function(aligned_run_root) {
  candidates <- list.files(
    aligned_run_root,
    pattern = "^light_[A-Za-z0-9._-]+_aligned[.]rds$",
    full.names = FALSE
  )
  sort(unique(sub(
    "^light_(.+)_aligned[.]rds$",
    "\\1",
    candidates
  )))
}

resolve_daily_coverage_placements <- function(
  placements,
  aligned_run_root
) {
  available <- discover_daily_coverage_placements(aligned_run_root)
  if (length(available) == 0L) {
    abort_pipeline(
      "No aligned one-minute artifacts were found under %s",
      aligned_run_root
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
      "Missing aligned artifact(s) for placement(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  placements
}

normalise_daily_coverage_sha256 <- function(value, argument = "sha256") {
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

assert_daily_coverage_inputs_unchanged <- function(inputs) {
  current <- vapply(inputs$path, artifact_sha256, character(1))
  expected <- vapply(
    inputs$sha256,
    normalise_daily_coverage_sha256,
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
      "An aligned input changed during the coverage-rule diagnostic: %s",
      details
    )
  }
  invisible(TRUE)
}

build_daily_coverage_rule_diagnostic <- function(
  root = project_root(),
  run_label = "full",
  aligned_run_root = NULL,
  diagnostic_run_root = NULL,
  placements = NULL,
  coverage_signal = "MEDI",
  state_col = "State.Brown",
  sleep_value = "sleep",
  minimum_hour_coverage = 0.5,
  minimum_day_coverage = 0.8
) {
  producer <- "scripts/pipeline/build_daily_coverage_rule_diagnostic.R"
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  layout <- daily_coverage_diagnostic_layout(
    paths,
    run_label = run_label,
    aligned_run_root = aligned_run_root,
    diagnostic_run_root = diagnostic_run_root
  )
  dir.create(
    layout$diagnostic_run_root,
    recursive = TRUE,
    showWarnings = FALSE
  )
  placements <- resolve_daily_coverage_placements(
    placements,
    layout$aligned_run_root
  )
  validate_coverage_fraction(
    minimum_hour_coverage,
    argument = "minimum_hour_coverage"
  )
  validate_coverage_fraction(
    minimum_day_coverage,
    argument = "minimum_day_coverage"
  )

  daily_rows <- list()
  input_rows <- list()
  for (placement in placements) {
    message("Comparing daily coverage rules for ", placement)
    input_path <- file.path(
      layout$aligned_run_root,
      paste0("light_", placement, "_aligned.rds")
    )
    input_sha256 <- normalise_daily_coverage_sha256(
      artifact_sha256(input_path)
    )
    input_info <- file.info(input_path)
    aligned <- dplyr::ungroup(read_rds_artifact(
      input_path,
      expected_class = "data.frame"
    ))
    if (any(as.character(aligned$position) != placement)) {
      abort_pipeline(
        "%s aligned input contains a different placement",
        placement
      )
    }
    diagnostic <- compare_daily_coverage_rules(
      aligned,
      coverage_signal = coverage_signal,
      state_col = state_col,
      sleep_value = sleep_value,
      id_cols = c("site", "Id", "position"),
      minimum_hour_coverage = minimum_hour_coverage,
      minimum_day_coverage = minimum_day_coverage,
      object = paste0(placement, " aligned one-minute artifact")
    )
    daily_rows[[placement]] <- diagnostic$daily_detail |>
      dplyr::mutate(
        run_label = layout$run_label,
        input_sha256 = input_sha256,
        status = "DIAGNOSTIC_ONLY_NO_RULE_SELECTED",
        .before = 1L
      )
    input_rows[[placement]] <- tibble::tibble(
      run_label = layout$run_label,
      placement = placement,
      input_type = "aligned_one_minute",
      path = normalizePath(input_path, winslash = "/", mustWork = TRUE),
      sha256 = input_sha256,
      bytes = unname(input_info$size)
    )
    rm(aligned, diagnostic)
    invisible(gc())
  }

  inputs <- dplyr::bind_rows(input_rows) |>
    dplyr::arrange(.data$placement)
  assert_unique_key(
    inputs,
    "path",
    object = "daily coverage-rule input ledger"
  )
  assert_daily_coverage_inputs_unchanged(inputs)
  daily <- dplyr::bind_rows(daily_rows) |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$Id,
      .data$local_date,
      factor(
        .data$rule,
        levels = c("A_current", "B_prereg_minimal", "C_wake_aware")
      )
    )
  assert_unique_key(
    daily,
    c("site", "Id", "position", "local_date", "rule"),
    object = "combined participant-day coverage-rule detail"
  )
  counts <- summarise_daily_coverage_rule_counts(daily) |>
    dplyr::mutate(
      run_label = layout$run_label,
      status = "DIAGNOSTIC_ONLY_NO_RULE_SELECTED",
      .before = 1L
    )
  transitions <- summarise_daily_coverage_rule_transitions(daily) |>
    dplyr::mutate(
      run_label = layout$run_label,
      status = "DIAGNOSTIC_ONLY_NO_RULE_SELECTED",
      .before = 1L
    )
  settings <- daily_coverage_rule_definitions() |>
    dplyr::mutate(
      run_label = layout$run_label,
      coverage_signal = coverage_signal,
      state_column = state_col,
      sleep_definition = paste0(state_col, " == '", sleep_value, "'"),
      unknown_state_handling = paste0(
        "not_sleep_excluded; retained in expected support; ",
        "source-absent wall minutes are unknown"
      ),
      fall_back_handling = paste0(
        "wall signal uses any finite wall-mean for rule A/B hourly gates; ",
        "non-sleep expected and valid support use mean over true instances"
      ),
      minimum_hour_coverage = minimum_hour_coverage,
      minimum_day_coverage = minimum_day_coverage,
      r_version = as.character(getRversion()),
      rule_selected = FALSE,
      status = "DIAGNOSTIC_ONLY_NO_RULE_SELECTED",
      .before = 1L
    )
  input_hash_set <- paste(
    paste(inputs$placement, inputs$sha256, sep = "="),
    collapse = "|"
  )
  for (csv_output in list(counts, transitions, settings, inputs)) {
    if ("Id" %in% names(csv_output)) {
      abort_pipeline(
        "Participant identifiers may not appear in diagnostic CSV outputs"
      )
    }
  }

  detail_path <- file.path(
    layout$diagnostic_run_root,
    "daily_coverage_rule_detail.rds"
  )
  counts_path <- file.path(
    layout$diagnostic_run_root,
    "daily_coverage_rule_counts.csv"
  )
  transitions_path <- file.path(
    layout$diagnostic_run_root,
    "daily_coverage_rule_transitions.csv"
  )
  settings_path <- file.path(
    layout$diagnostic_run_root,
    "daily_coverage_rule_settings.csv"
  )
  inputs_path <- file.path(
    layout$diagnostic_run_root,
    "daily_coverage_rule_inputs.csv"
  )
  common_metadata <- list(
    run_label = layout$run_label,
    status = "diagnostic_only_no_rule_selected",
    input_hashes = input_hash_set,
    coverage_signal = coverage_signal,
    state_col = state_col,
    sleep_value = sleep_value,
    minimum_hour_coverage = minimum_hour_coverage,
    minimum_day_coverage = minimum_day_coverage,
    fall_back_support = "mean_over_true_instances"
  )
  records <- dplyr::bind_rows(
    manifest_row(write_rds_artifact(
      daily,
      detail_path,
      producer,
      metadata = c(
        list(artifact_type = "participant_day_rule_detail"),
        common_metadata
      )
    )),
    manifest_row(write_csv_artifact(
      counts,
      counts_path,
      producer,
      metadata = c(
        list(artifact_type = "eligible_day_counts"),
        common_metadata
      )
    )),
    manifest_row(write_csv_artifact(
      transitions,
      transitions_path,
      producer,
      metadata = c(
        list(artifact_type = "eligible_day_transitions"),
        common_metadata
      )
    )),
    manifest_row(write_csv_artifact(
      settings,
      settings_path,
      producer,
      metadata = c(
        list(artifact_type = "coverage_rule_settings"),
        common_metadata
      )
    )),
    manifest_row(write_csv_artifact(
      inputs,
      inputs_path,
      producer,
      metadata = c(
        list(artifact_type = "aligned_input_ledger"),
        common_metadata
      )
    ))
  ) |>
    dplyr::select(-dplyr::any_of("written_utc")) |>
    dplyr::arrange(.data$artifact_type, .data$path)
  assert_unique_key(
    records,
    "path",
    object = "daily coverage-rule artifact manifest"
  )
  manifest_path <- file.path(
    layout$diagnostic_run_root,
    "artifact_manifest.csv"
  )
  write_csv_artifact(
    records,
    manifest_path,
    producer,
    metadata = c(
      list(artifact_type = "daily_coverage_rule_artifact_manifest"),
      common_metadata
    )
  )
  assert_daily_coverage_inputs_unchanged(inputs)

  list(
    run_label = layout$run_label,
    aligned_run_root = layout$aligned_run_root,
    diagnostic_run_root = layout$diagnostic_run_root,
    placements = placements,
    daily = daily,
    counts = counts,
    transitions = transitions,
    settings = settings,
    inputs = inputs,
    detail_path = detail_path,
    counts_path = counts_path,
    transitions_path = transitions_path,
    settings_path = settings_path,
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
    "aggregation_coverage.R",
    "daily_coverage_rule_diagnostic.R"
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
    "NATHEALTH_DAILY_COVERAGE_RUN_LABEL",
    unset = "full"
  )
  aligned_root <- Sys.getenv(
    "NATHEALTH_DAILY_COVERAGE_ALIGNED_ROOT",
    unset = ""
  )
  diagnostic_root <- Sys.getenv(
    "NATHEALTH_DAILY_COVERAGE_OUTPUT_ROOT",
    unset = ""
  )
  placement_argument <- Sys.getenv(
    "NATHEALTH_DAILY_COVERAGE_PLACEMENTS",
    unset = ""
  )
  result <- build_daily_coverage_rule_diagnostic(
    root = execution_root,
    run_label = run_label,
    aligned_run_root = if (nzchar(aligned_root)) aligned_root else NULL,
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
    "Daily coverage-rule diagnostic complete: ",
    result$detail_path
  )
}
