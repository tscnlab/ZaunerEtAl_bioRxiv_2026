# Independently verify the cutoff-neutral MDER support-gate artifacts.
#
# Source paths_io.R and assertions.R before calling
# verify_mder_support_gate_artifacts(). This verifier does not source the MDER
# builder or its support-gate functions, and it never derives the MDER ratio.

mder_gate_verifier_cutoffs <- c(0.70, 0.80, 0.90)
mder_gate_verifier_day_key <- c("site", "Id", "position", "local_date")

mder_gate_verifier_run_label <- function(run_label = "full") {
  if (
    !is.character(run_label) ||
      length(run_label) != 1L ||
      is.na(run_label) ||
      !nzchar(trimws(run_label)) ||
      !grepl("^[A-Za-z0-9._-]+$", trimws(run_label))
  ) {
    abort_pipeline("`run_label` must be one safe non-empty label")
  }
  trimws(run_label)
}

mder_gate_verifier_path <- function(path, default, must_work = TRUE) {
  selected <- if (is.null(path)) default else path
  if (
    !is.character(selected) ||
      length(selected) != 1L ||
      is.na(selected) ||
      !nzchar(trimws(selected))
  ) {
    abort_pipeline("Verifier paths must be one non-empty character value")
  }
  normalizePath(
    trimws(selected),
    winslash = "/",
    mustWork = must_work
  )
}

mder_gate_verifier_layout <- function(
  root,
  run_label = "full",
  coverage_run_root = NULL,
  profile_run_root = NULL,
  diagnostic_run_root = NULL,
  manifest_path = NULL
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  run_label <- mder_gate_verifier_run_label(run_label)
  paths <- pipeline_paths(root)
  suffix <- if (identical(run_label, "full")) {
    ""
  } else {
    paste0("_", run_label)
  }
  coverage_default <- if (identical(run_label, "full")) {
    paths$coverage
  } else {
    file.path(paths$coverage, "runs", run_label)
  }
  profile_default <- if (identical(run_label, "full")) {
    paths$profiles
  } else {
    file.path(paths$profiles, "runs", run_label)
  }
  diagnostic_default <- if (identical(run_label, "full")) {
    file.path(paths$diagnostics, "mder_support_gate")
  } else {
    file.path(paths$diagnostics, "runs", run_label, "mder_support_gate")
  }
  manifest_default <- file.path(
    paths$manifests,
    paste0("mder_support_gate_artifacts", suffix, ".csv")
  )
  list(
    root = root,
    run_label = run_label,
    paths = paths,
    coverage_run_root = mder_gate_verifier_path(
      coverage_run_root,
      coverage_default
    ),
    profile_run_root = mder_gate_verifier_path(
      profile_run_root,
      profile_default
    ),
    diagnostic_run_root = mder_gate_verifier_path(
      diagnostic_run_root,
      diagnostic_default
    ),
    manifest_path = mder_gate_verifier_path(
      manifest_path,
      manifest_default
    )
  )
}

mder_gate_verifier_output_paths <- function(diagnostic_run_root) {
  c(
    mder_support_gate_daily = file.path(
      diagnostic_run_root,
      "mder_support_gate_daily.csv"
    ),
    mder_support_candidate_summary = file.path(
      diagnostic_run_root,
      "mder_support_candidate_summary.csv"
    ),
    mder_support_candidate_by_site = file.path(
      diagnostic_run_root,
      "mder_support_candidate_by_site.csv"
    ),
    mder_support_candidate_by_participant = file.path(
      diagnostic_run_root,
      "mder_support_candidate_by_participant.csv"
    ),
    mder_support_gate_inputs = file.path(
      diagnostic_run_root,
      "mder_support_gate_inputs.csv"
    )
  )
}

mder_gate_verifier_values_equal <- function(
  observed,
  expected,
  tolerance = 1e-12
) {
  if (
    length(observed) != length(expected) ||
      !identical(is.na(observed), is.na(expected))
  ) {
    return(FALSE)
  }
  available <- !is.na(observed)
  if (!any(available)) {
    return(TRUE)
  }
  if (
    inherits(observed, "POSIXt") ||
      inherits(expected, "POSIXt") ||
      inherits(observed, "Date") ||
      inherits(expected, "Date")
  ) {
    return(isTRUE(all.equal(
      as.numeric(observed[available]),
      as.numeric(expected[available]),
      tolerance = tolerance,
      check.attributes = FALSE
    )))
  }
  if (is.numeric(observed) && is.numeric(expected)) {
    return(isTRUE(all.equal(
      as.numeric(observed[available]),
      as.numeric(expected[available]),
      tolerance = tolerance,
      check.attributes = FALSE
    )))
  }
  identical(
    as.character(observed[available]),
    as.character(expected[available])
  )
}

mder_gate_verifier_assert_table <- function(
  observed,
  expected,
  key,
  object,
  tolerance = 1e-12
) {
  if (!identical(names(observed), names(expected))) {
    abort_pipeline(
      "%s schema differs from the independent reconstruction; observed: %s; expected: %s",
      object,
      paste(names(observed), collapse = "|"),
      paste(names(expected), collapse = "|")
    )
  }
  assert_unique_key(observed, key, object = object)
  assert_unique_key(
    expected,
    key,
    object = paste0("independently reconstructed ", object)
  )
  observed <- dplyr::arrange(
    observed,
    dplyr::across(dplyr::all_of(key))
  )
  expected <- dplyr::arrange(
    expected,
    dplyr::across(dplyr::all_of(key))
  )
  if (nrow(observed) != nrow(expected)) {
    abort_pipeline(
      "%s has %d rows; independently expected %d",
      object,
      nrow(observed),
      nrow(expected)
    )
  }
  for (column in names(expected)) {
    if (
      !mder_gate_verifier_values_equal(
        observed[[column]],
        expected[[column]],
        tolerance = tolerance
      )
    ) {
      abort_pipeline(
        "%s disagrees with the independent reconstruction in `%s`",
        object,
        column
      )
    }
  }
  invisible(TRUE)
}

mder_gate_verifier_contains_l5 <- function(data) {
  if (!is.data.frame(data)) {
    return(FALSE)
  }
  if (any(grepl("L5", names(data), fixed = TRUE))) {
    return(TRUE)
  }
  character_columns <- vapply(
    data,
    function(column) is.character(column) || is.factor(column),
    logical(1)
  )
  if (!any(character_columns)) {
    return(FALSE)
  }
  any(vapply(
    data[character_columns],
    function(column) {
      any(grepl("L5", as.character(column), fixed = TRUE), na.rm = TRUE)
    },
    logical(1)
  ))
}

mder_gate_verifier_assert_no_l5 <- function(...) {
  objects <- list(...)
  labels <- names(objects)
  if (is.null(labels)) {
    labels <- rep("", length(objects))
  }
  present <- vapply(objects, mder_gate_verifier_contains_l5, logical(1))
  if (any(present)) {
    affected <- labels[present]
    affected[!nzchar(affected)] <- "unnamed object"
    abort_pipeline(
      "Excluded L5 content appears in: %s",
      paste(affected, collapse = ", ")
    )
  }
  invisible(TRUE)
}

mder_gate_verifier_parse_cutoffs <- function(value, object) {
  if (
    length(value) != 1L ||
      is.na(value) ||
      !nzchar(as.character(value))
  ) {
    abort_pipeline("%s does not record the support cutoffs", object)
  }
  parsed <- suppressWarnings(as.numeric(strsplit(
    as.character(value),
    "|",
    fixed = TRUE
  )[[1L]]))
  if (
    anyNA(parsed) ||
      length(parsed) != length(mder_gate_verifier_cutoffs) ||
      !identical(parsed, mder_gate_verifier_cutoffs)
  ) {
    abort_pipeline(
      "%s must record exactly the ordered cutoffs 0.70, 0.80, and 0.90",
      object
    )
  }
  parsed
}

mder_gate_verifier_assert_cutoffs <- function(cutoffs, object) {
  observed <- sort(unique(as.numeric(cutoffs)))
  if (
    anyNA(observed) ||
      length(observed) != length(mder_gate_verifier_cutoffs) ||
      !identical(observed, mder_gate_verifier_cutoffs)
  ) {
    abort_pipeline(
      "%s must contain exactly 0.70, 0.80, and 0.90",
      object
    )
  }
  invisible(observed)
}

mder_gate_verifier_assert_manifest <- function(
  manifest,
  layout,
  output_paths
) {
  expected_columns <- c(
    "path",
    "sha256",
    "bytes",
    "rows",
    "columns",
    "producer",
    "r_version",
    "artifact_type",
    "run_label",
    "status",
    "input_hashes",
    "candidate_cutoffs",
    "ratio_value_calculated",
    "ratio_scaled_or_weighted"
  )
  if (!identical(names(manifest), expected_columns)) {
    abort_pipeline(
      "MDER support-gate manifest has an unexpected schema: %s",
      paste(names(manifest), collapse = "|")
    )
  }
  if (
    nrow(manifest) != length(output_paths) ||
      anyNA(manifest[expected_columns]) ||
      any(manifest$producer != "scripts/pipeline/build_mder_support_gate.R") ||
      any(manifest$run_label != layout$run_label) ||
      any(manifest$status != "diagnostic_only_not_final") ||
      any(manifest$ratio_value_calculated) ||
      any(manifest$ratio_scaled_or_weighted) ||
      any(!grepl("^[0-9a-f]{64}$", manifest$sha256))
  ) {
    abort_pipeline(
      "MDER support-gate manifest metadata is incomplete or inconsistent"
    )
  }
  cutoff_strings <- unique(as.character(manifest$candidate_cutoffs))
  if (length(cutoff_strings) != 1L) {
    abort_pipeline(
      "MDER support-gate manifest records inconsistent cutoff registries"
    )
  }
  mder_gate_verifier_parse_cutoffs(
    cutoff_strings,
    "MDER support-gate manifest"
  )
  input_hash_sets <- unique(as.character(manifest$input_hashes))
  if (length(input_hash_sets) != 1L || !nzchar(input_hash_sets)) {
    abort_pipeline(
      "MDER support-gate manifest records inconsistent input hashes"
    )
  }
  assert_unique_key(
    manifest,
    "artifact_type",
    object = "MDER support-gate manifest"
  )
  if (!setequal(manifest$artifact_type, names(output_paths))) {
    abort_pipeline(
      "MDER support-gate manifest does not identify the exact output set"
    )
  }
  normalized_paths <- normalizePath(
    manifest$path,
    winslash = "/",
    mustWork = TRUE
  )
  expected_paths <- normalizePath(
    unname(output_paths),
    winslash = "/",
    mustWork = TRUE
  )
  if (!setequal(normalized_paths, expected_paths)) {
    abort_pipeline(
      "MDER support-gate manifest paths do not match the canonical outputs"
    )
  }
  actual_sha256 <- vapply(
    normalized_paths,
    artifact_sha256,
    character(1)
  )
  actual_bytes <- unname(file.info(normalized_paths)$size)
  actual_rows <- integer(length(normalized_paths))
  actual_columns <- integer(length(normalized_paths))
  for (index in seq_along(normalized_paths)) {
    artifact <- readr::read_csv(
      normalized_paths[[index]],
      show_col_types = FALSE,
      progress = FALSE
    )
    actual_rows[[index]] <- nrow(artifact)
    actual_columns[[index]] <- ncol(artifact)
  }
  exact <- actual_sha256 == manifest$sha256 &
    actual_bytes == manifest$bytes &
    actual_rows == manifest$rows &
    actual_columns == manifest$columns
  if (anyNA(exact) || !all(exact)) {
    abort_pipeline(
      "MDER support-gate manifest path/hash/bytes/rows/columns disagree for: %s",
      paste(manifest$artifact_type[!exact], collapse = ", ")
    )
  }
  tibble::tibble(
    artifact_type = manifest$artifact_type,
    path = normalized_paths,
    sha256 = actual_sha256,
    bytes = actual_bytes,
    rows = actual_rows,
    columns = actual_columns,
    input_hashes = manifest$input_hashes
  )
}

mder_gate_verifier_assert_rule_a <- function(
  settings,
  run_label,
  placements
) {
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
    c("run_label", "placement"),
    object = "Preparation 02 coverage settings"
  )
  if (
    nrow(settings) != length(placements) ||
      !setequal(as.character(settings$placement), placements) ||
      anyNA(settings[required]) ||
      any(settings$run_label != run_label) ||
      any(settings$coverage_rule_id != "A") ||
      any(settings$coverage_signal != "MEDI") ||
      any(
        settings$daily_denominator_domain != "all_pseudo_local_wall_minutes"
      ) ||
      any(settings$diary_sleep_excluded_from_denominator) ||
      any(settings$expected_wall_minutes_per_hour != 60) ||
      any(settings$expected_wall_minutes_per_day != 1440) ||
      any(settings$minimum_hour_coverage != 0.50) ||
      any(settings$minimum_day_coverage != 0.80)
  ) {
    abort_pipeline(
      "Preparation 02 settings do not record the exact approved Rule A full-day hybrid denominator"
    )
  }
  invisible(settings)
}

mder_gate_verifier_parse_hash_set <- function(value, object) {
  if (
    length(value) != 1L ||
      is.na(value) ||
      !nzchar(as.character(value))
  ) {
    abort_pipeline("%s does not record input hashes", object)
  }
  entries <- strsplit(as.character(value), "|", fixed = TRUE)[[1L]]
  separator <- regexpr("=", entries, fixed = TRUE)
  if (any(separator < 2L)) {
    abort_pipeline("%s has malformed input hashes", object)
  }
  labels <- substring(entries, 1L, separator - 1L)
  hashes <- substring(entries, separator + 1L)
  if (
    anyNA(labels) ||
      any(!nzchar(labels)) ||
      anyDuplicated(labels) ||
      any(!grepl("^[0-9a-f]{64}$", hashes))
  ) {
    abort_pipeline("%s has malformed input hashes", object)
  }
  stats::setNames(hashes, labels)
}

mder_gate_verifier_assert_profile_settings <- function(
  settings,
  run_label,
  coverage_settings_path,
  coverage_settings_sha256,
  coverage_hashes
) {
  required <- c(
    "run_label",
    "input_coverage_rule_id",
    "input_coverage_settings_path",
    "input_coverage_settings_sha256",
    "input_daily_denominator_domain",
    "input_diary_sleep_excluded_from_denominator",
    "profile_learning",
    "participant_day_profiles_fitted",
    "bin_minutes",
    "l5_permitted",
    "input_hashes"
  )
  assert_columns(
    settings,
    required,
    object = "Preparation 03 profile settings"
  )
  normalized_coverage_path <- normalizePath(
    settings$input_coverage_settings_path,
    winslash = "/",
    mustWork = TRUE
  )
  if (
    nrow(settings) != 1L ||
      anyNA(settings[required]) ||
      !identical(as.character(settings$run_label), run_label) ||
      !identical(as.character(settings$input_coverage_rule_id), "A") ||
      !identical(normalized_coverage_path, coverage_settings_path) ||
      !identical(
        as.character(settings$input_coverage_settings_sha256),
        coverage_settings_sha256
      ) ||
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
      "Preparation 03 settings do not record fixed 30-minute Rule A profiles with L5 prohibited"
    )
  }
  recorded <- mder_gate_verifier_parse_hash_set(
    settings$input_hashes,
    "Preparation 03 profile settings"
  )
  if (
    !setequal(names(recorded), names(coverage_hashes)) ||
      !identical(
        unname(recorded[names(coverage_hashes)]),
        unname(coverage_hashes)
      )
  ) {
    abort_pipeline(
      "Preparation 03 settings do not match the coverage artifact hashes"
    )
  }
  invisible(settings)
}

mder_gate_verifier_validate_inputs <- function(
  inputs,
  layout,
  placements,
  output_manifest,
  coverage_settings_path,
  profile_settings_path,
  profile_path,
  map_path
) {
  expected_columns <- c(
    "run_label",
    "candidate_cutoffs",
    "support_profile_variant",
    "ratio_value_calculated",
    "ratio_scaled_or_weighted",
    "status",
    "input_type",
    "placement",
    "path",
    "sha256",
    "bytes"
  )
  if (!identical(names(inputs), expected_columns)) {
    abort_pipeline(
      "MDER support-gate input ledger has an unexpected schema: %s",
      paste(names(inputs), collapse = "|")
    )
  }
  if (
    anyNA(inputs[setdiff(expected_columns, "placement")]) ||
      any(inputs$run_label != layout$run_label) ||
      any(inputs$support_profile_variant != "pooled") ||
      any(inputs$ratio_value_calculated) ||
      any(inputs$ratio_scaled_or_weighted) ||
      any(inputs$status != "AUTHOR_GATE_INPUT_NOT_A_SELECTED_RULE") ||
      any(!grepl("^[0-9a-f]{64}$", inputs$sha256))
  ) {
    abort_pipeline(
      "MDER support-gate input ledger metadata is incomplete or inconsistent"
    )
  }
  cutoff_strings <- unique(as.character(inputs$candidate_cutoffs))
  if (length(cutoff_strings) != 1L) {
    abort_pipeline(
      "MDER support-gate input ledger records inconsistent cutoffs"
    )
  }
  mder_gate_verifier_parse_cutoffs(
    cutoff_strings,
    "MDER support-gate input ledger"
  )
  normalized_paths <- normalizePath(
    inputs$path,
    winslash = "/",
    mustWork = TRUE
  )
  inputs$path <- normalized_paths
  assert_unique_key(
    inputs,
    "path",
    object = "MDER support-gate input ledger"
  )

  global_expected <- c(
    coverage_settings = coverage_settings_path,
    reference_profile_settings = profile_settings_path,
    fixed_reference_profiles = profile_path,
    paired_relevance_maps = map_path
  )
  coverage_expected <- stats::setNames(
    file.path(
      layout$coverage_run_root,
      paste0("light_", placements, "_coverage.rds")
    ),
    placements
  )
  coverage_expected <- normalizePath(
    coverage_expected,
    winslash = "/",
    mustWork = TRUE
  )
  expected_rows <- tibble::tibble(
    input_type = c(
      names(global_expected),
      rep("preparation02_coverage", length(placements))
    ),
    placement = c(
      rep(NA_character_, length(global_expected)),
      placements
    ),
    path = c(unname(global_expected), unname(coverage_expected))
  )
  expected_rows$path <- normalizePath(
    expected_rows$path,
    winslash = "/",
    mustWork = TRUE
  )
  observed_key <- inputs |>
    dplyr::select(dplyr::all_of(c("input_type", "placement", "path"))) |>
    dplyr::arrange(.data$input_type, .data$placement, .data$path)
  expected_key <- expected_rows |>
    dplyr::arrange(.data$input_type, .data$placement, .data$path)
  if (
    nrow(observed_key) != nrow(expected_key) ||
      !identical(observed_key, expected_key)
  ) {
    abort_pipeline(
      "MDER support-gate input ledger does not identify the exact canonical input set"
    )
  }
  actual_hashes <- unname(vapply(
    inputs$path,
    artifact_sha256,
    character(1)
  ))
  actual_bytes <- unname(file.info(inputs$path)$size)
  if (
    !identical(actual_hashes, unname(as.character(inputs$sha256))) ||
      !identical(actual_bytes, unname(as.numeric(inputs$bytes)))
  ) {
    abort_pipeline(
      "MDER support-gate input ledger path/hash/bytes verification failed"
    )
  }
  expected_hash_set <- paste(
    paste(
      inputs$input_type,
      dplyr::coalesce(inputs$placement, "all"),
      inputs$sha256,
      sep = "="
    ),
    collapse = "|"
  )
  recorded_hash_set <- unique(as.character(output_manifest$input_hashes))
  if (
    length(recorded_hash_set) != 1L ||
      !identical(recorded_hash_set, expected_hash_set)
  ) {
    abort_pipeline(
      "MDER output manifest does not reproduce the ordered input ledger hashes"
    )
  }
  list(
    inputs = inputs,
    coverage_paths = stats::setNames(
      inputs$path[
        inputs$input_type == "preparation02_coverage"
      ],
      inputs$placement[
        inputs$input_type == "preparation02_coverage"
      ]
    ),
    coverage_hashes = stats::setNames(
      inputs$sha256[
        inputs$input_type == "preparation02_coverage"
      ],
      inputs$placement[
        inputs$input_type == "preparation02_coverage"
      ]
    ),
    all_hashes = stats::setNames(inputs$sha256, inputs$path)
  )
}

mder_gate_verifier_validate_profiles <- function(
  profiles,
  maps,
  placements,
  tolerance = 1e-12
) {
  profile_required <- c(
    "profile_scope",
    "profile_variant",
    "placement",
    "state_domain",
    "signal",
    "clock_bin",
    "bin_minutes",
    "profile_supported",
    "reference_weight"
  )
  map_required <- c(
    profile_required,
    "metric_map",
    "map_application",
    "map_estimable",
    "relevance_weight",
    "ratio_correction_allowed",
    "paired_channel_required"
  )
  assert_columns(profiles, profile_required, object = "fixed profiles")
  assert_columns(maps, map_required, object = "fixed relevance maps")
  selected_profiles <- profiles |>
    dplyr::filter(
      .data$profile_scope == "pooled",
      .data$profile_variant == "pooled",
      .data$placement %in% .env$placements,
      .data$state_domain == "full_day",
      .data$signal %in% c("MEDI", "LIGHT")
    ) |>
    dplyr::arrange(.data$placement, .data$signal, .data$clock_bin)
  selected_maps <- maps |>
    dplyr::filter(
      .data$profile_scope == "pooled",
      .data$profile_variant == "pooled",
      .data$placement %in% .env$placements,
      .data$state_domain == "full_day",
      .data$signal %in% c("MEDI", "LIGHT"),
      .data$metric_map == "paired_channel_coverage"
    ) |>
    dplyr::arrange(.data$placement, .data$signal, .data$clock_bin)
  expected_bins <- seq.int(0L, 1410L, by = 30L)
  expected_rows <- length(placements) * 2L * length(expected_bins)
  if (
    nrow(selected_profiles) != expected_rows ||
      nrow(selected_maps) != expected_rows
  ) {
    abort_pipeline(
      "The verifier requires one complete pooled full-day MEDI and LIGHT relevance map per placement"
    )
  }
  profile_key <- c("placement", "state_domain", "signal", "clock_bin")
  map_key <- c(profile_key, "metric_map")
  assert_unique_key(
    selected_profiles,
    profile_key,
    object = "pooled full-day fixed profiles"
  )
  assert_unique_key(
    selected_maps,
    map_key,
    object = "pooled full-day paired-channel maps"
  )
  groups <- split(
    seq_len(nrow(selected_maps)),
    interaction(
      selected_maps$placement,
      selected_maps$signal,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  for (indices in groups) {
    map_group <- selected_maps[indices, , drop = FALSE]
    if (
      !identical(as.integer(map_group$clock_bin), expected_bins) ||
        anyNA(map_group[c(
          "bin_minutes",
          "map_estimable",
          "relevance_weight",
          "ratio_correction_allowed",
          "paired_channel_required"
        )]) ||
        any(map_group$bin_minutes != 30L) ||
        any(!map_group$map_estimable) ||
        any(
          !is.finite(map_group$relevance_weight) |
            map_group$relevance_weight < 0
        ) ||
        abs(sum(map_group$relevance_weight) - 1) > tolerance ||
        any(map_group$map_application != "paired_coverage_only") ||
        any(map_group$ratio_correction_allowed) ||
        any(!map_group$paired_channel_required)
    ) {
      abort_pipeline(
        "A pooled full-day paired-channel relevance map is invalid"
      )
    }
  }
  profile_groups <- split(
    seq_len(nrow(selected_profiles)),
    interaction(
      selected_profiles$placement,
      selected_profiles$signal,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  for (indices in profile_groups) {
    profile_group <- selected_profiles[indices, , drop = FALSE]
    if (
      !identical(as.integer(profile_group$clock_bin), expected_bins) ||
        anyNA(profile_group[c(
          "bin_minutes",
          "profile_supported",
          "reference_weight"
        )]) ||
        any(profile_group$bin_minutes != 30L) ||
        any(!profile_group$profile_supported) ||
        any(
          !is.finite(profile_group$reference_weight) |
            profile_group$reference_weight < 0
        ) ||
        abs(sum(profile_group$reference_weight) - 1) > tolerance
    ) {
      abort_pipeline("A pooled full-day fixed profile is invalid")
    }
  }
  compared <- dplyr::left_join(
    dplyr::select(
      selected_profiles,
      dplyr::all_of(profile_key),
      profile_weight = "reference_weight"
    ),
    dplyr::select(
      selected_maps,
      dplyr::all_of(profile_key),
      map_weight = "relevance_weight"
    ),
    by = profile_key,
    relationship = "one-to-one"
  )
  if (
    anyNA(compared$map_weight) ||
      !mder_gate_verifier_values_equal(
        compared$profile_weight,
        compared$map_weight,
        tolerance = tolerance
      )
  ) {
    abort_pipeline(
      "Signal-specific relevance maps do not reproduce the fixed profiles"
    )
  }
  selected_maps
}

mder_gate_verifier_midnight_utc <- function(date, timezone) {
  as.numeric(as.POSIXct(
    paste(format(as.Date(date), "%Y-%m-%d"), "00:00:00"),
    tz = timezone
  ))
}

mder_gate_verifier_validate_coverage <- function(
  coverage,
  placement,
  object = paste(placement, "coverage")
) {
  required <- c(
    mder_gate_verifier_day_key,
    "timezone",
    "datetime_utc",
    "clock_minute",
    "day_eligible",
    "MEDI_eligible",
    "LIGHT_eligible",
    "source_subepochs"
  )
  if (!is.data.frame(coverage)) {
    abort_pipeline("%s is not a data frame", object)
  }
  assert_columns(coverage, required, object = object)
  assert_no_missing_key(
    coverage,
    c(
      mder_gate_verifier_day_key,
      "timezone",
      "datetime_utc",
      "clock_minute"
    ),
    object = object
  )
  assert_unique_key(
    coverage,
    c("site", "Id", "position", "datetime_utc"),
    object = object
  )
  if (
    !inherits(coverage$local_date, "Date") ||
      !inherits(coverage$datetime_utc, "POSIXct") ||
      !identical(lubridate::tz(coverage$datetime_utc), "UTC") ||
      any(as.character(coverage$position) != placement) ||
      !is.logical(coverage$day_eligible) ||
      anyNA(coverage$day_eligible)
  ) {
    abort_pipeline(
      "%s has invalid placement, dates, UTC timestamps, or day eligibility",
      object
    )
  }
  datetime_numeric <- as.numeric(coverage$datetime_utc)
  if (
    any(!is.finite(datetime_numeric)) ||
      any(abs(datetime_numeric / 60 - round(datetime_numeric / 60)) > 1e-8)
  ) {
    abort_pipeline("%s has timestamps outside exact UTC minutes", object)
  }
  if (
    !is.numeric(coverage$clock_minute) ||
      anyNA(coverage$clock_minute) ||
      any(
        coverage$clock_minute < 0 |
          coverage$clock_minute >= 1440 |
          coverage$clock_minute != as.integer(coverage$clock_minute)
      )
  ) {
    abort_pipeline("%s has invalid pseudo-local clock minutes", object)
  }
  if (any(!as.character(coverage$timezone) %in% OlsonNames())) {
    abort_pipeline("%s contains invalid Olson time zones", object)
  }
  for (signal in c("MEDI_eligible", "LIGHT_eligible")) {
    value <- coverage[[signal]]
    if (
      !is.numeric(value) ||
        any(!is.na(value) & (!is.finite(value) | value < 0))
    ) {
      abort_pipeline(
        "%s `%s` must contain finite non-negative values or NA",
        object,
        signal
      )
    }
  }
  if (
    any(
      is.finite(coverage$MEDI_eligible) &
        coverage$MEDI_eligible >= 100000
    )
  ) {
    abort_pipeline(
      "%s violates the strict MEDI <100000 lx operating boundary",
      object
    )
  }
  if (
    !is.numeric(coverage$source_subepochs) ||
      anyNA(coverage$source_subepochs) ||
      any(
        !is.finite(coverage$source_subepochs) |
          coverage$source_subepochs < 0 |
          coverage$source_subepochs != as.integer(coverage$source_subepochs)
      )
  ) {
    abort_pipeline("%s has invalid source-subepoch counts", object)
  }
  finite_signal <- is.finite(coverage$MEDI_eligible) |
    is.finite(coverage$LIGHT_eligible)
  if (any(finite_signal & coverage$source_subepochs == 0L)) {
    abort_pipeline(
      "%s has eligible signal values without a source observation",
      object
    )
  }

  site_timezones <- coverage |>
    dplyr::distinct(.data$site, .data$timezone) |>
    dplyr::count(.data$site, name = "timezone_count")
  if (any(site_timezones$timezone_count != 1L)) {
    abort_pipeline("%s assigns multiple time zones to one site", object)
  }
  timezone_values <- as.character(coverage$timezone)
  derived_date <- as.Date(rep(NA_character_, nrow(coverage)))
  derived_clock <- rep(NA_integer_, nrow(coverage))
  for (timezone in sort(unique(timezone_values))) {
    rows <- which(timezone_values == timezone)
    local <- lubridate::with_tz(
      coverage$datetime_utc[rows],
      tzone = timezone
    )
    local_parts <- as.POSIXlt(local, tz = timezone)
    derived_date[rows] <- as.Date(local, tz = timezone)
    derived_clock[rows] <- as.integer(
      local_parts$hour * 60L + local_parts$min
    )
  }
  if (
    any(derived_date != coverage$local_date) ||
      any(derived_clock != as.integer(coverage$clock_minute))
  ) {
    abort_pipeline(
      "%s pseudo-local coordinates disagree with true UTC timestamps",
      object
    )
  }

  day_index <- coverage |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(mder_gate_verifier_day_key))
    ) |>
    dplyr::summarise(
      timezone_count = dplyr::n_distinct(.data$timezone),
      timezone = dplyr::first(.data$timezone),
      eligibility_count = dplyr::n_distinct(.data$day_eligible),
      day_eligible = dplyr::first(.data$day_eligible),
      observed_true_minutes = dplyr::n(),
      minimum_utc = min(as.numeric(.data$datetime_utc)),
      maximum_utc = max(as.numeric(.data$datetime_utc)),
      .groups = "drop"
    )
  if (
    any(day_index$timezone_count != 1L) ||
      any(day_index$eligibility_count != 1L)
  ) {
    abort_pipeline(
      "%s has participant-days with inconsistent timezone or eligibility",
      object
    )
  }
  day_index$expected_start_utc <- mapply(
    mder_gate_verifier_midnight_utc,
    day_index$local_date,
    day_index$timezone
  )
  day_index$expected_end_utc <- mapply(
    mder_gate_verifier_midnight_utc,
    day_index$local_date + 1L,
    day_index$timezone
  )
  day_index$expected_true_minutes <- as.integer(
    (day_index$expected_end_utc - day_index$expected_start_utc) / 60
  )
  if (
    any(
      !day_index$expected_true_minutes %in% c(1380L, 1440L, 1500L)
    ) ||
      any(
        day_index$observed_true_minutes != day_index$expected_true_minutes
      ) ||
      any(day_index$minimum_utc != day_index$expected_start_utc) ||
      any(
        day_index$maximum_utc != day_index$expected_end_utc - 60
      )
  ) {
    abort_pipeline(
      "%s does not contain the complete canonical true-minute day grid",
      object
    )
  }
  coordinate_check <- dplyr::left_join(
    dplyr::select(
      coverage,
      dplyr::all_of(c(mder_gate_verifier_day_key, "datetime_utc"))
    ),
    dplyr::select(
      day_index,
      dplyr::all_of(c(
        mder_gate_verifier_day_key,
        "expected_start_utc",
        "expected_end_utc"
      ))
    ),
    by = mder_gate_verifier_day_key,
    relationship = "many-to-one"
  )
  coordinate_numeric <- as.numeric(coordinate_check$datetime_utc)
  if (
    any(coordinate_numeric < coordinate_check$expected_start_utc) ||
      any(coordinate_numeric >= coordinate_check$expected_end_utc)
  ) {
    abort_pipeline(
      "%s has UTC minutes outside its local-day bounds",
      object
    )
  }
  list(
    coverage = coverage,
    day_index = dplyr::select(
      day_index,
      dplyr::all_of(c(
        mder_gate_verifier_day_key,
        "timezone",
        "day_eligible",
        "expected_true_minutes"
      ))
    )
  )
}

mder_gate_verifier_weights <- function(clock_minute, map, signal, placement) {
  clock_bin <- floor(as.integer(clock_minute) / 30L) * 30L
  weights <- map$relevance_weight[match(clock_bin, map$clock_bin)]
  if (
    anyNA(weights) ||
      any(!is.finite(weights) | weights < 0)
  ) {
    abort_pipeline(
      "The fixed %s relevance map does not cover all `%s` clock minutes",
      signal,
      placement
    )
  }
  weights
}

mder_gate_verifier_reconstruct_daily <- function(
  validated_coverage,
  maps,
  placement,
  run_label,
  tolerance = 1e-12
) {
  coverage <- validated_coverage$coverage
  day_index <- validated_coverage$day_index |>
    dplyr::filter(.data$day_eligible) |>
    dplyr::select(-dplyr::all_of("day_eligible"))
  if (nrow(day_index) == 0L) {
    abort_pipeline("%s has no Rule A eligible participant-days", placement)
  }
  eligible <- dplyr::semi_join(
    coverage,
    day_index,
    by = mder_gate_verifier_day_key
  )
  medi_map <- maps |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$signal == "MEDI"
    ) |>
    dplyr::arrange(.data$clock_bin)
  light_map <- maps |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$signal == "LIGHT"
    ) |>
    dplyr::arrange(.data$clock_bin)
  eligible$medi_profile_weight <- mder_gate_verifier_weights(
    eligible$clock_minute,
    medi_map,
    signal = "MEDI",
    placement = placement
  )
  eligible$light_profile_weight <- mder_gate_verifier_weights(
    eligible$clock_minute,
    light_map,
    signal = "LIGHT",
    placement = placement
  )
  eligible$paired_finite <- is.finite(eligible$MEDI_eligible) &
    is.finite(eligible$LIGHT_eligible)

  reconstructed <- eligible |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(mder_gate_verifier_day_key))
    ) |>
    dplyr::summarise(
      timezone = dplyr::first(.data$timezone),
      expected_true_minutes = dplyr::n(),
      expected_medi_profile_mass = sum(.data$medi_profile_weight),
      expected_light_profile_mass = sum(.data$light_profile_weight),
      finite_medi_minutes = sum(is.finite(.data$MEDI_eligible)),
      finite_light_minutes = sum(is.finite(.data$LIGHT_eligible)),
      paired_finite_medi_light_minutes = sum(.data$paired_finite),
      paired_medi_profile_mass = sum(
        .data$medi_profile_weight[.data$paired_finite]
      ),
      paired_light_profile_mass = sum(
        .data$light_profile_weight[.data$paired_finite]
      ),
      paired_light_integral_lx_h = if (any(.data$paired_finite)) {
        sum(.data$LIGHT_eligible[.data$paired_finite]) / 60
      } else {
        NA_real_
      },
      .groups = "drop"
    )
  if (
    any(
      !is.finite(reconstructed$expected_medi_profile_mass) |
        reconstructed$expected_medi_profile_mass <= 0
    ) ||
      any(
        !is.finite(reconstructed$expected_light_profile_mass) |
          reconstructed$expected_light_profile_mass <= 0
      )
  ) {
    abort_pipeline(
      "%s has a non-positive expected fixed-profile mass",
      placement
    )
  }
  reconstructed <- reconstructed |>
    dplyr::mutate(
      ordinary_paired_coverage = .data$paired_finite_medi_light_minutes /
        .data$expected_true_minutes,
      medi_paired_profile_coverage = .data$paired_medi_profile_mass /
        .data$expected_medi_profile_mass,
      light_paired_profile_coverage = .data$paired_light_profile_mass /
        .data$expected_light_profile_mass,
      positive_light_integral = is.finite(.data$paired_light_integral_lx_h) &
        .data$paired_light_integral_lx_h > 0,
      has_paired_observation = .data$paired_finite_medi_light_minutes > 0L,
      profile_variant = "pooled",
      failure_reason = dplyr::case_when(
        !.data$has_paired_observation ~ "no_paired_observation",
        !.data$positive_light_integral ~ "nonpositive_paired_light_integral",
        TRUE ~ NA_character_
      ),
      support_role = "author_gate_input_only",
      ratio_value_calculated = FALSE,
      ratio_scaled_or_weighted = FALSE
    )
  for (cutoff in mder_gate_verifier_cutoffs) {
    column <- paste0(
      "retained_at_",
      gsub(".", "_", sprintf("%.2f", cutoff), fixed = TRUE)
    )
    reconstructed[[column]] <-
      is.finite(reconstructed$ordinary_paired_coverage) &
      reconstructed$ordinary_paired_coverage >= cutoff &
      is.finite(reconstructed$medi_paired_profile_coverage) &
      reconstructed$medi_paired_profile_coverage >= cutoff &
      is.finite(reconstructed$light_paired_profile_coverage) &
      reconstructed$light_paired_profile_coverage >= cutoff &
      reconstructed$positive_light_integral
  }
  probability_columns <- c(
    "ordinary_paired_coverage",
    "medi_paired_profile_coverage",
    "light_paired_profile_coverage"
  )
  if (
    any(
      !is.finite(as.matrix(reconstructed[probability_columns]))
    ) ||
      any(as.matrix(reconstructed[probability_columns]) < -tolerance) ||
      any(as.matrix(reconstructed[probability_columns]) > 1 + tolerance)
  ) {
    abort_pipeline("Reconstructed MDER support lies outside [0, 1]")
  }
  reconstructed |>
    dplyr::mutate(
      run_label = run_label,
      status = "AUTHOR_GATE_INPUT_NOT_A_SELECTED_RULE",
      .before = 1L
    ) |>
    dplyr::select(dplyr::all_of(c(
      "run_label",
      "status",
      mder_gate_verifier_day_key,
      "timezone",
      "profile_variant",
      "expected_true_minutes",
      "finite_medi_minutes",
      "finite_light_minutes",
      "paired_finite_medi_light_minutes",
      "ordinary_paired_coverage",
      "medi_paired_profile_coverage",
      "light_paired_profile_coverage",
      "paired_light_integral_lx_h",
      "positive_light_integral",
      "has_paired_observation",
      "retained_at_0_70",
      "retained_at_0_80",
      "retained_at_0_90",
      "failure_reason",
      "support_role",
      "ratio_value_calculated",
      "ratio_scaled_or_weighted"
    ))) |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$Id,
      .data$local_date
    )
}

mder_gate_verifier_classify <- function(daily) {
  tidyr::crossing(
    daily,
    candidate_support_cutoff = mder_gate_verifier_cutoffs
  ) |>
    dplyr::mutate(
      passes_ordinary_paired_support = is.finite(
        .data$ordinary_paired_coverage
      ) &
        .data$ordinary_paired_coverage >= .data$candidate_support_cutoff,
      passes_medi_profile_support = is.finite(
        .data$medi_paired_profile_coverage
      ) &
        .data$medi_paired_profile_coverage >= .data$candidate_support_cutoff,
      passes_light_profile_support = is.finite(
        .data$light_paired_profile_coverage
      ) &
        .data$light_paired_profile_coverage >= .data$candidate_support_cutoff,
      retained_at_candidate = .data$passes_ordinary_paired_support &
        .data$passes_medi_profile_support &
        .data$passes_light_profile_support &
        .data$positive_light_integral,
      below_any_support = .data$has_paired_observation &
        .data$positive_light_integral &
        !.data$retained_at_candidate,
      candidate_failure_reason = dplyr::case_when(
        !.data$has_paired_observation ~ "no_paired_observation",
        !.data$positive_light_integral ~ "nonpositive_paired_light_integral",
        !.data$passes_ordinary_paired_support ~ "below_ordinary_paired_support",
        !.data$passes_medi_profile_support ~ "below_medi_profile_support",
        !.data$passes_light_profile_support ~ "below_light_profile_support",
        TRUE ~ NA_character_
      )
    )
}

mder_gate_verifier_finite_quantile <- function(value, probability) {
  finite <- is.finite(value)
  if (!any(finite)) {
    return(NA_real_)
  }
  as.numeric(stats::quantile(
    value[finite],
    probs = probability,
    names = FALSE,
    type = 7
  ))
}

mder_gate_verifier_summarise <- function(classified, run_label) {
  summary <- classified |>
    dplyr::group_by(
      .data$position,
      .data$candidate_support_cutoff
    ) |>
    dplyr::summarise(
      eligible_participant_days = dplyr::n(),
      eligible_participants = dplyr::n_distinct(.data$site, .data$Id),
      eligible_sites = dplyr::n_distinct(.data$site),
      participant_days_with_paired_minutes = sum(
        .data$paired_finite_medi_light_minutes > 0L
      ),
      participants_with_paired_minutes = dplyr::n_distinct(
        .data$site[.data$has_paired_observation],
        .data$Id[.data$has_paired_observation]
      ),
      participant_days_with_positive_light_integral = sum(
        .data$positive_light_integral
      ),
      retained_participant_days = sum(.data$retained_at_candidate),
      retained_participants = dplyr::n_distinct(
        .data$site[.data$retained_at_candidate],
        .data$Id[.data$retained_at_candidate]
      ),
      sites_with_retained_days = dplyr::n_distinct(
        .data$site[.data$retained_at_candidate]
      ),
      excluded_participant_days = sum(!.data$retained_at_candidate),
      no_paired_observation_days = sum(
        .data$paired_finite_medi_light_minutes == 0L
      ),
      nonpositive_paired_light_integral_days = sum(
        .data$paired_finite_medi_light_minutes > 0L &
          !.data$positive_light_integral
      ),
      below_ordinary_paired_support_days = sum(
        !.data$passes_ordinary_paired_support
      ),
      below_medi_profile_support_days = sum(
        !.data$passes_medi_profile_support
      ),
      below_light_profile_support_days = sum(
        !.data$passes_light_profile_support
      ),
      below_any_support_days = sum(.data$below_any_support),
      ordinary_paired_coverage_q10 = mder_gate_verifier_finite_quantile(
        .data$ordinary_paired_coverage,
        0.10
      ),
      ordinary_paired_coverage_median = mder_gate_verifier_finite_quantile(
        .data$ordinary_paired_coverage,
        0.50
      ),
      medi_profile_coverage_q10 = mder_gate_verifier_finite_quantile(
        .data$medi_paired_profile_coverage,
        0.10
      ),
      medi_profile_coverage_median = mder_gate_verifier_finite_quantile(
        .data$medi_paired_profile_coverage,
        0.50
      ),
      light_profile_coverage_q10 = mder_gate_verifier_finite_quantile(
        .data$light_paired_profile_coverage,
        0.10
      ),
      light_profile_coverage_median = mder_gate_verifier_finite_quantile(
        .data$light_paired_profile_coverage,
        0.50
      ),
      .groups = "drop"
    ) |>
    dplyr::group_by(.data$position) |>
    dplyr::arrange(.data$candidate_support_cutoff, .by_group = TRUE) |>
    dplyr::mutate(
      retained_fraction = .data$retained_participant_days /
        .data$eligible_participant_days,
      marginal_participant_day_loss_from_lower = dplyr::lag(
        .data$retained_participant_days
      ) -
        .data$retained_participant_days,
      marginal_participant_loss_from_lower = dplyr::lag(
        .data$retained_participants
      ) -
        .data$retained_participants,
      classification_total = .data$retained_participant_days +
        .data$no_paired_observation_days +
        .data$nonpositive_paired_light_integral_days +
        .data$below_any_support_days,
      status = "diagnostic_only_not_final",
      selection_rule = "candidate_cutoffs_fixed_without_result_preference"
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$position,
      .data$candidate_support_cutoff
    ) |>
    dplyr::mutate(run_label = run_label, .before = 1L)
  if (
    any(
      summary$classification_total != summary$eligible_participant_days
    )
  ) {
    abort_pipeline(
      "Reconstructed overall MDER classifications do not reconcile"
    )
  }
  summary
}

mder_gate_verifier_summarise_site <- function(classified, run_label) {
  summary <- classified |>
    dplyr::group_by(
      .data$position,
      .data$site,
      .data$candidate_support_cutoff
    ) |>
    dplyr::summarise(
      eligible_participant_days = dplyr::n(),
      eligible_participants = dplyr::n_distinct(.data$Id),
      participant_days_with_paired_minutes = sum(
        .data$has_paired_observation
      ),
      retained_participant_days = sum(.data$retained_at_candidate),
      retained_participants = dplyr::n_distinct(
        .data$Id[.data$retained_at_candidate]
      ),
      no_paired_observation_days = sum(
        !.data$has_paired_observation
      ),
      nonpositive_paired_light_integral_days = sum(
        .data$has_paired_observation &
          !.data$positive_light_integral
      ),
      below_any_support_days = sum(.data$below_any_support),
      ordinary_paired_coverage_median = mder_gate_verifier_finite_quantile(
        .data$ordinary_paired_coverage,
        0.50
      ),
      medi_profile_coverage_median = mder_gate_verifier_finite_quantile(
        .data$medi_paired_profile_coverage,
        0.50
      ),
      light_profile_coverage_median = mder_gate_verifier_finite_quantile(
        .data$light_paired_profile_coverage,
        0.50
      ),
      .groups = "drop"
    ) |>
    dplyr::group_by(.data$position, .data$site) |>
    dplyr::arrange(.data$candidate_support_cutoff, .by_group = TRUE) |>
    dplyr::mutate(
      retained_fraction = .data$retained_participant_days /
        .data$eligible_participant_days,
      marginal_participant_day_loss_from_lower = dplyr::lag(
        .data$retained_participant_days
      ) -
        .data$retained_participant_days,
      classification_total = .data$retained_participant_days +
        .data$no_paired_observation_days +
        .data$nonpositive_paired_light_integral_days +
        .data$below_any_support_days,
      status = "diagnostic_only_not_final",
      selection_rule = "candidate_cutoffs_fixed_without_result_preference"
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$candidate_support_cutoff
    ) |>
    dplyr::mutate(run_label = run_label, .before = 1L)
  if (
    any(
      summary$classification_total != summary$eligible_participant_days
    )
  ) {
    abort_pipeline(
      "Reconstructed site MDER classifications do not reconcile"
    )
  }
  summary
}

mder_gate_verifier_summarise_participant <- function(
  classified,
  run_label
) {
  summary <- classified |>
    dplyr::group_by(
      .data$position,
      .data$site,
      .data$Id,
      .data$candidate_support_cutoff
    ) |>
    dplyr::summarise(
      eligible_participant_days = dplyr::n(),
      participant_days_with_paired_minutes = sum(
        .data$has_paired_observation
      ),
      retained_participant_days = sum(.data$retained_at_candidate),
      no_paired_observation_days = sum(
        !.data$has_paired_observation
      ),
      nonpositive_paired_light_integral_days = sum(
        .data$has_paired_observation &
          !.data$positive_light_integral
      ),
      below_any_support_days = sum(.data$below_any_support),
      ordinary_paired_coverage_median = mder_gate_verifier_finite_quantile(
        .data$ordinary_paired_coverage,
        0.50
      ),
      medi_profile_coverage_median = mder_gate_verifier_finite_quantile(
        .data$medi_paired_profile_coverage,
        0.50
      ),
      light_profile_coverage_median = mder_gate_verifier_finite_quantile(
        .data$light_paired_profile_coverage,
        0.50
      ),
      .groups = "drop"
    ) |>
    dplyr::group_by(.data$position, .data$site, .data$Id) |>
    dplyr::arrange(.data$candidate_support_cutoff, .by_group = TRUE) |>
    dplyr::mutate(
      retained_fraction = .data$retained_participant_days /
        .data$eligible_participant_days,
      marginal_participant_day_loss_from_lower = dplyr::lag(
        .data$retained_participant_days
      ) -
        .data$retained_participant_days,
      classification_total = .data$retained_participant_days +
        .data$no_paired_observation_days +
        .data$nonpositive_paired_light_integral_days +
        .data$below_any_support_days,
      status = "diagnostic_only_not_final",
      selection_rule = "candidate_cutoffs_fixed_without_result_preference"
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$Id,
      .data$candidate_support_cutoff
    ) |>
    dplyr::mutate(run_label = run_label, .before = 1L)
  if (
    any(
      summary$classification_total != summary$eligible_participant_days
    )
  ) {
    abort_pipeline(
      "Reconstructed participant MDER classifications do not reconcile"
    )
  }
  summary
}

mder_gate_verifier_assert_profile_provenance <- function(
  provenance,
  coverage,
  coverage_paths,
  coverage_hashes
) {
  required <- c(
    "placement",
    "signal",
    "input_path",
    "input_sha256",
    "input_bytes",
    "input_sites",
    "input_participants",
    "input_participant_days",
    "input_true_utc_minutes",
    "input_true_utc_start",
    "input_true_utc_end",
    "eligible_true_utc_minutes",
    "clock_coordinate",
    "absolute_coordinate"
  )
  assert_columns(
    provenance,
    required,
    object = "Preparation 03 input provenance"
  )
  placements <- sort(names(coverage))
  expected_keys <- tidyr::crossing(
    placement = placements,
    signal = c("LIGHT", "MEDI")
  )
  observed_keys <- provenance |>
    dplyr::select(dplyr::all_of(c("placement", "signal"))) |>
    dplyr::arrange(.data$placement, .data$signal)
  if (
    nrow(provenance) != nrow(expected_keys) ||
      !identical(observed_keys, expected_keys)
  ) {
    abort_pipeline(
      "Preparation 03 provenance does not contain one row per placement and signal"
    )
  }
  assert_unique_key(
    provenance,
    c("placement", "signal"),
    object = "Preparation 03 input provenance"
  )
  for (placement in placements) {
    data <- coverage[[placement]]
    rows <- provenance$placement == placement
    signal_rows <- provenance[rows, , drop = FALSE]
    normalized_paths <- normalizePath(
      signal_rows$input_path,
      winslash = "/",
      mustWork = TRUE
    )
    expected_participants <- nrow(dplyr::distinct(
      data,
      .data$site,
      .data$Id
    ))
    expected_days <- nrow(dplyr::distinct(
      data,
      dplyr::across(dplyr::all_of(mder_gate_verifier_day_key))
    ))
    expected_start <- format(
      min(data$datetime_utc),
      tz = "UTC",
      usetz = TRUE
    )
    expected_end <- format(
      max(data$datetime_utc),
      tz = "UTC",
      usetz = TRUE
    )
    expected_eligible <- vapply(
      signal_rows$signal,
      function(signal) {
        sum(is.finite(data[[paste0(signal, "_eligible")]]))
      },
      integer(1)
    )
    if (
      any(normalized_paths != coverage_paths[[placement]]) ||
        any(signal_rows$input_sha256 != coverage_hashes[[placement]]) ||
        any(
          signal_rows$input_bytes !=
            unname(file.info(coverage_paths[[placement]])$size)
        ) ||
        any(signal_rows$input_sites != dplyr::n_distinct(data$site)) ||
        any(signal_rows$input_participants != expected_participants) ||
        any(signal_rows$input_participant_days != expected_days) ||
        any(signal_rows$input_true_utc_minutes != nrow(data)) ||
        any(signal_rows$input_true_utc_start != expected_start) ||
        any(signal_rows$input_true_utc_end != expected_end) ||
        any(signal_rows$eligible_true_utc_minutes != expected_eligible) ||
        any(signal_rows$clock_coordinate != "pseudo_local_wall_clock") ||
        any(
          signal_rows$absolute_coordinate != "datetime_utc_preserved_in_input"
        )
    ) {
      abort_pipeline(
        "Preparation 03 provenance disagrees with `%s` coverage",
        placement
      )
    }
  }
  invisible(provenance)
}

verify_mder_support_gate_artifacts <- function(
  root = project_root(),
  run_label = "full",
  coverage_run_root = NULL,
  profile_run_root = NULL,
  diagnostic_run_root = NULL,
  manifest_path = NULL,
  tolerance = 1e-12
) {
  if (
    length(tolerance) != 1L ||
      !is.numeric(tolerance) ||
      !is.finite(tolerance) ||
      tolerance < 0
  ) {
    abort_pipeline("`tolerance` must be one non-negative finite value")
  }
  layout <- mder_gate_verifier_layout(
    root = root,
    run_label = run_label,
    coverage_run_root = coverage_run_root,
    profile_run_root = profile_run_root,
    diagnostic_run_root = diagnostic_run_root,
    manifest_path = manifest_path
  )
  output_paths <- mder_gate_verifier_output_paths(
    layout$diagnostic_run_root
  )
  if (!all(file.exists(output_paths))) {
    abort_pipeline(
      "MDER support-gate output is missing: %s",
      paste(output_paths[!file.exists(output_paths)], collapse = ", ")
    )
  }

  source_paths <- c(
    coverage_settings = file.path(
      layout$coverage_run_root,
      "coverage_settings.csv"
    ),
    profile_settings = file.path(
      layout$profile_run_root,
      "reference_profile_settings.csv"
    ),
    profile_provenance = file.path(
      layout$profile_run_root,
      "reference_profile_input_provenance.csv"
    ),
    profiles = file.path(
      layout$profile_run_root,
      "reference_profiles.rds"
    ),
    maps = file.path(
      layout$profile_run_root,
      "metric_relevance_maps.rds"
    )
  )
  if (!all(file.exists(source_paths))) {
    abort_pipeline(
      "MDER support-gate source input is missing: %s",
      paste(source_paths[!file.exists(source_paths)], collapse = ", ")
    )
  }
  initial_hashes <- list(
    manifest = artifact_sha256(layout$manifest_path),
    outputs = vapply(output_paths, artifact_sha256, character(1)),
    sources = vapply(source_paths, artifact_sha256, character(1))
  )

  manifest <- readr::read_csv(
    layout$manifest_path,
    show_col_types = FALSE,
    progress = FALSE,
    col_types = readr::cols(
      input_hashes = readr::col_character(),
      candidate_cutoffs = readr::col_character()
    )
  )
  manifest_check <- mder_gate_verifier_assert_manifest(
    manifest,
    layout,
    output_paths
  )
  daily <- readr::read_csv(
    output_paths[["mder_support_gate_daily"]],
    show_col_types = FALSE,
    progress = FALSE,
    col_types = readr::cols(
      local_date = readr::col_date(),
      failure_reason = readr::col_character()
    )
  )
  summary <- readr::read_csv(
    output_paths[["mder_support_candidate_summary"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  site_summary <- readr::read_csv(
    output_paths[["mder_support_candidate_by_site"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  participant_summary <- readr::read_csv(
    output_paths[["mder_support_candidate_by_participant"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  inputs <- readr::read_csv(
    output_paths[["mder_support_gate_inputs"]],
    show_col_types = FALSE,
    progress = FALSE,
    col_types = readr::cols(candidate_cutoffs = readr::col_character())
  )
  coverage_settings <- readr::read_csv(
    source_paths[["coverage_settings"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  profile_settings <- readr::read_csv(
    source_paths[["profile_settings"]],
    show_col_types = FALSE,
    progress = FALSE,
    col_types = readr::cols(input_hashes = readr::col_character())
  )
  profile_provenance <- readr::read_csv(
    source_paths[["profile_provenance"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  profiles <- dplyr::ungroup(readRDS(source_paths[["profiles"]]))
  maps <- dplyr::ungroup(readRDS(source_paths[["maps"]]))
  mder_gate_verifier_assert_no_l5(
    daily = daily,
    summary = summary,
    site_summary = site_summary,
    participant_summary = participant_summary,
    inputs = inputs,
    manifest = manifest,
    coverage_settings = coverage_settings,
    profile_settings = profile_settings,
    profile_provenance = profile_provenance,
    profiles = profiles,
    maps = maps
  )

  placements <- sort(unique(as.character(coverage_settings$placement)))
  mder_gate_verifier_assert_rule_a(
    coverage_settings,
    layout$run_label,
    placements
  )
  verified_inputs <- mder_gate_verifier_validate_inputs(
    inputs = inputs,
    layout = layout,
    placements = placements,
    output_manifest = manifest_check,
    coverage_settings_path = normalizePath(
      source_paths[["coverage_settings"]],
      winslash = "/",
      mustWork = TRUE
    ),
    profile_settings_path = normalizePath(
      source_paths[["profile_settings"]],
      winslash = "/",
      mustWork = TRUE
    ),
    profile_path = normalizePath(
      source_paths[["profiles"]],
      winslash = "/",
      mustWork = TRUE
    ),
    map_path = normalizePath(
      source_paths[["maps"]],
      winslash = "/",
      mustWork = TRUE
    )
  )
  mder_gate_verifier_assert_profile_settings(
    profile_settings,
    run_label = layout$run_label,
    coverage_settings_path = normalizePath(
      source_paths[["coverage_settings"]],
      winslash = "/",
      mustWork = TRUE
    ),
    coverage_settings_sha256 = initial_hashes$sources[["coverage_settings"]],
    coverage_hashes = verified_inputs$coverage_hashes
  )
  selected_maps <- mder_gate_verifier_validate_profiles(
    profiles,
    maps,
    placements,
    tolerance = tolerance
  )

  coverage_objects <- vector("list", length(placements))
  names(coverage_objects) <- placements
  reconstructed <- vector("list", length(placements))
  names(reconstructed) <- placements
  for (placement in placements) {
    coverage <- readRDS(verified_inputs$coverage_paths[[placement]])
    coverage_objects[[placement]] <- coverage
    validated <- mder_gate_verifier_validate_coverage(
      coverage,
      placement = placement
    )
    reconstructed[[placement]] <- mder_gate_verifier_reconstruct_daily(
      validated,
      maps = selected_maps,
      placement = placement,
      run_label = layout$run_label,
      tolerance = tolerance
    )
  }
  mder_gate_verifier_assert_profile_provenance(
    profile_provenance,
    coverage = coverage_objects,
    coverage_paths = verified_inputs$coverage_paths,
    coverage_hashes = verified_inputs$coverage_hashes
  )
  expected_daily <- dplyr::bind_rows(reconstructed) |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$Id,
      .data$local_date
    )
  mder_gate_verifier_assert_table(
    daily,
    expected_daily,
    key = mder_gate_verifier_day_key,
    object = "daily MDER support-gate artifact",
    tolerance = tolerance
  )
  mder_gate_verifier_assert_cutoffs(
    summary$candidate_support_cutoff,
    "MDER candidate summary"
  )
  mder_gate_verifier_assert_cutoffs(
    site_summary$candidate_support_cutoff,
    "site MDER candidate summary"
  )
  mder_gate_verifier_assert_cutoffs(
    participant_summary$candidate_support_cutoff,
    "participant MDER candidate summary"
  )
  classified <- mder_gate_verifier_classify(expected_daily)
  expected_summary <- mder_gate_verifier_summarise(
    classified,
    layout$run_label
  )
  expected_site_summary <- mder_gate_verifier_summarise_site(
    classified,
    layout$run_label
  )
  expected_participant_summary <-
    mder_gate_verifier_summarise_participant(
      classified,
      layout$run_label
    )
  mder_gate_verifier_assert_table(
    summary,
    expected_summary,
    key = c("position", "candidate_support_cutoff"),
    object = "MDER candidate summary",
    tolerance = tolerance
  )
  mder_gate_verifier_assert_table(
    site_summary,
    expected_site_summary,
    key = c("position", "site", "candidate_support_cutoff"),
    object = "site MDER candidate summary",
    tolerance = tolerance
  )
  mder_gate_verifier_assert_table(
    participant_summary,
    expected_participant_summary,
    key = c(
      "position",
      "site",
      "Id",
      "candidate_support_cutoff"
    ),
    object = "participant MDER candidate summary",
    tolerance = tolerance
  )
  if (
    any(daily$ratio_value_calculated) ||
      any(daily$ratio_scaled_or_weighted)
  ) {
    abort_pipeline(
      "The MDER support gate contains a calculated or corrected ratio"
    )
  }

  final_hashes <- list(
    manifest = artifact_sha256(layout$manifest_path),
    outputs = vapply(output_paths, artifact_sha256, character(1)),
    sources = vapply(source_paths, artifact_sha256, character(1)),
    coverage = vapply(
      verified_inputs$coverage_paths,
      artifact_sha256,
      character(1)
    )
  )
  immutable <- identical(initial_hashes$manifest, final_hashes$manifest) &&
    identical(initial_hashes$outputs, final_hashes$outputs) &&
    identical(initial_hashes$sources, final_hashes$sources) &&
    identical(
      unname(verified_inputs$coverage_hashes[names(final_hashes$coverage)]),
      unname(final_hashes$coverage)
    )
  if (!immutable) {
    abort_pipeline(
      "MDER gate outputs, profiles, provenance, or coverage inputs changed during verification"
    )
  }
  structure(
    list(
      status = "PASS",
      run_label = layout$run_label,
      manifest_path = layout$manifest_path,
      manifest_sha256 = initial_hashes$manifest,
      manifest = manifest_check,
      daily_rows = nrow(expected_daily),
      summary_rows = nrow(expected_summary),
      site_summary_rows = nrow(expected_site_summary),
      participant_summary_rows = nrow(expected_participant_summary),
      placements = placements,
      cutoffs = mder_gate_verifier_cutoffs,
      overall_counts = expected_summary,
      site_counts = expected_site_summary,
      participant_counts = expected_participant_summary,
      l5_present = FALSE,
      strict_medi_upper_bound = 100000,
      ratio_value_calculated = FALSE,
      immutable_inputs = TRUE
    ),
    class = c("mder_support_gate_artifact_verification", "list")
  )
}

if (sys.nframe() == 0L) {
  root_override <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "")
  execution_root <- if (nzchar(root_override)) {
    normalizePath(root_override, winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  }
  source(file.path(
    execution_root,
    "scripts",
    "pipeline",
    "paths_io.R"
  ))
  source(file.path(
    execution_root,
    "scripts",
    "pipeline",
    "assertions.R"
  ))
  run_label <- Sys.getenv(
    "NATHEALTH_MDER_SUPPORT_VERIFY_RUN_LABEL",
    unset = "full"
  )
  result <- verify_mder_support_gate_artifacts(
    root = execution_root,
    run_label = run_label
  )
  print(result$manifest, n = Inf)
  print(result$overall_counts, n = Inf)
  print(result[c(
    "status",
    "daily_rows",
    "summary_rows",
    "site_summary_rows",
    "participant_summary_rows",
    "placements",
    "cutoffs",
    "l5_present",
    "strict_medi_upper_bound",
    "ratio_value_calculated",
    "immutable_inputs"
  )])
}
