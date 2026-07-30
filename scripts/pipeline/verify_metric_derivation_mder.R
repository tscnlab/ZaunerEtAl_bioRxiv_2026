# Independently verify MDER integration in canonical Preparation 04 outputs.
#
# Source paths_io.R and assertions.R before calling
# verify_metric_derivation_mder(). This verifier does not source the metric
# builder, metric_derivation.R, or time_support.R, and it never calculates an
# MDER ratio. The independently verified MDER support gate is its support
# reference.

metric_mder_verifier_day_key <- c("site", "Id", "position", "local_date")
metric_mder_verifier_cutoff <- 0.80
metric_mder_verifier_metric <- "mder_ratio_of_integrals"

metric_mder_verifier_run_label <- function(run_label = "full") {
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

metric_mder_verifier_path <- function(path, default, must_work = TRUE) {
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

metric_mder_verifier_layout <- function(
  root,
  run_label = "full",
  metric_run_root = NULL,
  metric_manifest_path = NULL,
  gate_run_root = NULL,
  gate_manifest_path = NULL
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  run_label <- metric_mder_verifier_run_label(run_label)
  paths <- pipeline_paths(root)
  suffix <- if (identical(run_label, "full")) {
    ""
  } else {
    paste0("_", run_label)
  }
  metric_default <- if (identical(run_label, "full")) {
    paths$metrics
  } else {
    file.path(paths$metrics, "runs", run_label)
  }
  gate_default <- if (identical(run_label, "full")) {
    file.path(paths$diagnostics, "mder_support_gate")
  } else {
    file.path(
      paths$diagnostics,
      "runs",
      run_label,
      "mder_support_gate"
    )
  }
  list(
    root = root,
    run_label = run_label,
    paths = paths,
    metric_run_root = metric_mder_verifier_path(
      metric_run_root,
      metric_default
    ),
    metric_manifest_path = metric_mder_verifier_path(
      metric_manifest_path,
      file.path(paths$manifests, paste0("metric_artifacts", suffix, ".csv"))
    ),
    gate_run_root = metric_mder_verifier_path(
      gate_run_root,
      gate_default
    ),
    gate_manifest_path = metric_mder_verifier_path(
      gate_manifest_path,
      file.path(
        paths$manifests,
        paste0("mder_support_gate_artifacts", suffix, ".csv")
      )
    )
  )
}

metric_mder_verifier_output_paths <- function(metric_run_root, placement) {
  prefix <- paste0("metrics_", placement, "_")
  c(
    participant_day_metrics_rds = file.path(
      metric_run_root,
      paste0(prefix, "participant_day.rds")
    ),
    participant_day_metrics_csv = file.path(
      metric_run_root,
      paste0(prefix, "participant_day.csv")
    ),
    long_metric_values = file.path(
      metric_run_root,
      paste0(prefix, "values_long.csv")
    ),
    metric_support_diagnostics = file.path(
      metric_run_root,
      paste0(prefix, "support_diagnostics.csv")
    )
  )
}

metric_mder_verifier_discover_placements <- function(metric_run_root) {
  files <- list.files(
    metric_run_root,
    pattern = "^metrics_[A-Za-z0-9._-]+_participant_day[.]rds$",
    full.names = FALSE
  )
  sort(unique(sub(
    "^metrics_(.+)_participant_day[.]rds$",
    "\\1",
    files
  )))
}

metric_mder_verifier_resolve_placements <- function(
  placements,
  metric_run_root
) {
  available <- metric_mder_verifier_discover_placements(metric_run_root)
  if (length(available) == 0L) {
    abort_pipeline(
      "No Preparation 04 participant-day RDS outputs were found under %s",
      metric_run_root
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
    abort_pipeline("`placements` must contain safe non-empty labels")
  }
  missing <- setdiff(placements, available)
  if (length(missing) > 0L) {
    abort_pipeline(
      "Preparation 04 outputs are missing placement(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  placements
}

metric_mder_verifier_read_csv <- function(path) {
  header <- names(readr::read_csv(
    path,
    n_max = 0L,
    show_col_types = FALSE,
    progress = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  ))
  parsers <- list(
    run_label = readr::col_character(),
    status = readr::col_character(),
    site = readr::col_character(),
    Id = readr::col_character(),
    position = readr::col_character(),
    placement = readr::col_character(),
    local_date = readr::col_date(),
    profile_variant = readr::col_character(),
    metric = readr::col_character(),
    analysis_unit = readr::col_character(),
    failure_reason = readr::col_character(),
    mder_failure_reason = readr::col_character(),
    path = readr::col_character(),
    sha256 = readr::col_character(),
    artifact_type = readr::col_character(),
    producer = readr::col_character(),
    mder_support_candidates = readr::col_character(),
    mder_support_sensitivity_cutoffs = readr::col_character(),
    candidate_cutoffs = readr::col_character(),
    bytes = readr::col_double(),
    rows = readr::col_double(),
    columns = readr::col_double(),
    expected_true_minutes = readr::col_double(),
    paired_finite_medi_light_minutes = readr::col_double(),
    ordinary_paired_coverage = readr::col_double(),
    medi_paired_profile_coverage = readr::col_double(),
    light_paired_profile_coverage = readr::col_double(),
    expected_real_minutes = readr::col_double(),
    mder = readr::col_double(),
    mder_ordinary_paired_coverage = readr::col_double(),
    mder_medi_profile_coverage = readr::col_double(),
    mder_light_profile_coverage = readr::col_double(),
    mder_minimum_support = readr::col_double(),
    value = readr::col_double(),
    ordinary_support = readr::col_double(),
    relevance_support = readr::col_double(),
    valid_minutes = readr::col_double(),
    expected_minutes = readr::col_double(),
    medi_profile_support = readr::col_double(),
    light_profile_support = readr::col_double(),
    minimum_support = readr::col_double(),
    mder_support_cutoff = readr::col_double(),
    eligible_participant_days = readr::col_double(),
    positive_light_integral = readr::col_logical(),
    has_paired_observation = readr::col_logical(),
    retained_at_0_80 = readr::col_logical(),
    ratio_value_calculated = readr::col_logical(),
    ratio_scaled_or_weighted = readr::col_logical(),
    estimable = readr::col_logical(),
    state_domain_complete = readr::col_logical(),
    passes_ordinary_support = readr::col_logical(),
    passes_medi_profile_support = readr::col_logical(),
    passes_light_profile_support = readr::col_logical(),
    support_threshold_enforced = readr::col_logical(),
    mder_passes_ordinary_paired_support = readr::col_logical(),
    mder_passes_medi_profile_support = readr::col_logical(),
    mder_passes_light_profile_support = readr::col_logical(),
    mder_support_threshold_enforced = readr::col_logical(),
    mder_ratio_scaled_or_weighted = readr::col_logical(),
    mder_estimable = readr::col_logical()
  )
  parsers <- parsers[intersect(names(parsers), header)]
  col_types <- do.call(
    readr::cols,
    c(list(.default = readr::col_guess()), parsers)
  )
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    col_types = col_types
  )
}

metric_mder_verifier_normalise_keys <- function(data) {
  assert_columns(
    data,
    metric_mder_verifier_day_key,
    object = "MDER verification table"
  )
  data |>
    dplyr::mutate(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      position = as.character(.data$position),
      local_date = as.Date(.data$local_date)
    )
}

metric_mder_verifier_values_equal <- function(
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
    inherits(observed, "Date") ||
      inherits(expected, "Date") ||
      inherits(observed, "POSIXt") ||
      inherits(expected, "POSIXt")
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
  if (is.logical(observed) && is.logical(expected)) {
    return(identical(observed[available], expected[available]))
  }
  identical(
    as.character(observed[available]),
    as.character(expected[available])
  )
}

metric_mder_verifier_assert_equal <- function(
  observed,
  expected,
  object,
  column,
  tolerance = 1e-12
) {
  if (
    !metric_mder_verifier_values_equal(
      observed,
      expected,
      tolerance = tolerance
    )
  ) {
    abort_pipeline(
      "%s disagrees with the independent MDER support gate in `%s`",
      object,
      column
    )
  }
  invisible(TRUE)
}

metric_mder_verifier_arrange <- function(data) {
  dplyr::arrange(
    data,
    dplyr::across(dplyr::all_of(metric_mder_verifier_day_key))
  )
}

metric_mder_verifier_assert_key_set <- function(
  observed,
  expected,
  object
) {
  assert_unique_key(
    observed,
    metric_mder_verifier_day_key,
    object = object
  )
  assert_unique_key(
    expected,
    metric_mder_verifier_day_key,
    object = "independently verified MDER support-gate days"
  )
  observed_key <- metric_mder_verifier_arrange(
    observed[metric_mder_verifier_day_key]
  )
  expected_key <- metric_mder_verifier_arrange(
    expected[metric_mder_verifier_day_key]
  )
  same_keys <- nrow(observed_key) == nrow(expected_key)
  if (same_keys) {
    same_keys <- all(vapply(
      metric_mder_verifier_day_key,
      function(column) {
        metric_mder_verifier_values_equal(
          observed_key[[column]],
          expected_key[[column]]
        )
      },
      logical(1)
    ))
  }
  if (!same_keys) {
    abort_pipeline(
      "%s does not retain exactly one row for every eligible support-gate day",
      object
    )
  }
  invisible(TRUE)
}

metric_mder_verifier_fingerprint <- function(paths) {
  paths <- unique(normalizePath(
    paths,
    winslash = "/",
    mustWork = TRUE
  ))
  tibble::tibble(
    path = paths,
    sha256 = vapply(paths, artifact_sha256, character(1)),
    bytes = unname(file.info(paths)$size)
  ) |>
    dplyr::arrange(.data$path)
}

metric_mder_verifier_assert_immutable <- function(before, after) {
  if (!identical(before, after)) {
    abort_pipeline(
      "An MDER gate or Preparation 04 artifact changed during verification"
    )
  }
  invisible(TRUE)
}

metric_mder_verifier_expected_failure <- function(gate) {
  dplyr::case_when(
    !gate$has_paired_observation ~ "no_paired_observation",
    !gate$positive_light_integral ~ "nonpositive_paired_light_integral",
    gate$ordinary_paired_coverage < metric_mder_verifier_cutoff ~
      "below_ordinary_paired_support",
    gate$medi_paired_profile_coverage < metric_mder_verifier_cutoff ~
      "below_medi_profile_support",
    gate$light_paired_profile_coverage < metric_mder_verifier_cutoff ~
      "below_light_profile_support",
    TRUE ~ NA_character_
  )
}

metric_mder_verifier_assert_gate <- function(gate, run_label, placements) {
  required <- c(
    "run_label",
    "status",
    metric_mder_verifier_day_key,
    "profile_variant",
    "expected_true_minutes",
    "paired_finite_medi_light_minutes",
    "ordinary_paired_coverage",
    "medi_paired_profile_coverage",
    "light_paired_profile_coverage",
    "positive_light_integral",
    "has_paired_observation",
    "retained_at_0_80",
    "failure_reason",
    "support_role",
    "ratio_value_calculated",
    "ratio_scaled_or_weighted"
  )
  assert_columns(gate, required, object = "MDER support-gate daily output")
  assert_unique_key(
    gate,
    metric_mder_verifier_day_key,
    object = "MDER support-gate daily output"
  )
  if (
    nrow(gate) < 1L ||
      anyNA(gate[setdiff(required, "failure_reason")]) ||
      !setequal(as.character(unique(gate$position)), placements) ||
      any(gate$run_label != run_label) ||
      any(gate$status != "AUTHOR_GATE_INPUT_NOT_A_SELECTED_RULE") ||
      any(gate$profile_variant != "pooled") ||
      any(gate$support_role != "author_gate_input_only") ||
      any(gate$ratio_value_calculated) ||
      any(gate$ratio_scaled_or_weighted) ||
      any(gate$expected_true_minutes < 1L) ||
      any(gate$paired_finite_medi_light_minutes < 0L) ||
      any(
        gate$paired_finite_medi_light_minutes > gate$expected_true_minutes
      )
  ) {
    abort_pipeline(
      "MDER support-gate daily metadata or denominators are inconsistent"
    )
  }
  for (column in c(
    "ordinary_paired_coverage",
    "medi_paired_profile_coverage",
    "light_paired_profile_coverage"
  )) {
    value <- gate[[column]]
    if (anyNA(value) || any(!is.finite(value) | value < 0 | value > 1)) {
      abort_pipeline(
        "MDER support-gate `%s` must contain complete probabilities",
        column
      )
    }
  }
  if (
    !is.logical(gate$positive_light_integral) ||
      !is.logical(gate$has_paired_observation) ||
      !is.logical(gate$retained_at_0_80)
  ) {
    abort_pipeline("MDER support-gate decision fields must be logical")
  }
  expected_gate_failure <- dplyr::case_when(
    !gate$has_paired_observation ~ "no_paired_observation",
    !gate$positive_light_integral ~ "nonpositive_paired_light_integral",
    TRUE ~ NA_character_
  )
  expected_retention <- gate$has_paired_observation &
    gate$positive_light_integral &
    gate$ordinary_paired_coverage >= metric_mder_verifier_cutoff &
    gate$medi_paired_profile_coverage >= metric_mder_verifier_cutoff &
    gate$light_paired_profile_coverage >= metric_mder_verifier_cutoff
  if (
    !metric_mder_verifier_values_equal(
      gate$failure_reason,
      expected_gate_failure
    ) ||
      !identical(gate$retained_at_0_80, expected_retention)
  ) {
    abort_pipeline(
      "MDER support-gate 0.80 retention or base failure reason is inconsistent"
    )
  }
  invisible(gate)
}

metric_mder_verifier_assert_gate_manifest <- function(
  manifest,
  layout,
  gate_path
) {
  required <- c(
    "path",
    "sha256",
    "bytes",
    "rows",
    "columns",
    "producer",
    "artifact_type",
    "run_label",
    "status",
    "candidate_cutoffs",
    "ratio_value_calculated",
    "ratio_scaled_or_weighted"
  )
  assert_columns(
    manifest,
    required,
    object = "MDER support-gate artifact manifest"
  )
  selected <- manifest |>
    dplyr::filter(.data$artifact_type == "mder_support_gate_daily")
  if (
    nrow(selected) != 1L ||
      anyNA(selected[required]) ||
      selected$producer != "scripts/pipeline/build_mder_support_gate.R" ||
      selected$run_label != layout$run_label ||
      selected$status != "diagnostic_only_not_final" ||
      selected$candidate_cutoffs != "0.7|0.8|0.9" ||
      selected$ratio_value_calculated ||
      selected$ratio_scaled_or_weighted
  ) {
    abort_pipeline(
      "MDER support-gate manifest daily row is incomplete or inconsistent"
    )
  }
  recorded_path <- normalizePath(
    selected$path,
    winslash = "/",
    mustWork = TRUE
  )
  if (!identical(recorded_path, gate_path)) {
    abort_pipeline(
      "MDER support-gate manifest does not identify the selected daily gate"
    )
  }
  gate <- metric_mder_verifier_read_csv(gate_path)
  exact <- selected$sha256 == artifact_sha256(gate_path) &&
    selected$bytes == unname(file.info(gate_path)$size) &&
    selected$rows == nrow(gate) &&
    selected$columns == ncol(gate)
  if (!isTRUE(exact)) {
    abort_pipeline(
      "MDER support-gate manifest hash/bytes/rows/columns disagree"
    )
  }
  invisible(selected)
}

metric_mder_verifier_expected_manifest_rows <- function(
  metric_run_root,
  placements
) {
  placement_rows <- dplyr::bind_rows(lapply(placements, function(placement) {
    paths <- metric_mder_verifier_output_paths(
      metric_run_root,
      placement
    )
    tibble::tibble(
      artifact_type = names(paths),
      placement = placement,
      expected_path = unname(paths)
    )
  }))
  dplyr::bind_rows(
    placement_rows,
    tibble::tibble(
      artifact_type = "metric_derivation_settings",
      placement = NA_character_,
      expected_path = file.path(
        metric_run_root,
        "metric_derivation_settings.csv"
      )
    )
  )
}

metric_mder_verifier_assert_metric_manifest <- function(
  manifest,
  layout,
  placements
) {
  required <- c(
    "path",
    "sha256",
    "bytes",
    "producer",
    "artifact_type",
    "run_label",
    "placement"
  )
  assert_columns(
    manifest,
    required,
    object = "Preparation 04 metric artifact manifest"
  )
  expected <- metric_mder_verifier_expected_manifest_rows(
    layout$metric_run_root,
    placements
  )
  selected <- dplyr::inner_join(
    manifest,
    expected[c("artifact_type", "placement")],
    by = c("artifact_type", "placement"),
    relationship = "many-to-one"
  )
  if (nrow(selected) != nrow(expected)) {
    abort_pipeline(
      "Preparation 04 metric manifest does not contain the exact relevant MDER artifact set"
    )
  }
  manifest_key <- selected |>
    dplyr::mutate(
      placement_key = dplyr::coalesce(
        .data$placement,
        "__combined__"
      )
    )
  assert_unique_key(
    manifest_key,
    c("artifact_type", "placement_key"),
    object = "relevant Preparation 04 manifest rows"
  )
  selected <- dplyr::left_join(
    selected,
    expected,
    by = c("artifact_type", "placement"),
    relationship = "one-to-one"
  )
  if (
    anyNA(selected[c(
      "path",
      "sha256",
      "bytes",
      "producer",
      "artifact_type",
      "run_label",
      "expected_path"
    )]) ||
      any(
        selected$producer != "scripts/pipeline/build_metric_derivation.R"
      ) ||
      any(selected$run_label != layout$run_label) ||
      any(!grepl("^[0-9a-f]{64}$", selected$sha256))
  ) {
    abort_pipeline(
      "Relevant Preparation 04 manifest metadata is incomplete or inconsistent"
    )
  }
  selected$path <- normalizePath(
    selected$path,
    winslash = "/",
    mustWork = TRUE
  )
  selected$expected_path <- normalizePath(
    selected$expected_path,
    winslash = "/",
    mustWork = TRUE
  )
  if (!identical(selected$path, selected$expected_path)) {
    abort_pipeline(
      "Preparation 04 manifest paths do not match the relevant metric outputs"
    )
  }
  actual_sha256 <- unname(vapply(
    selected$path,
    artifact_sha256,
    character(1)
  ))
  actual_bytes <- unname(file.info(selected$path)$size)
  if (
    !identical(actual_sha256, as.character(selected$sha256)) ||
      !identical(actual_bytes, as.numeric(selected$bytes))
  ) {
    abort_pipeline(
      "Preparation 04 manifest hash/bytes disagree for a relevant MDER artifact"
    )
  }
  csv_rows <- grepl("[.]csv$", selected$path)
  if (any(csv_rows)) {
    assert_columns(
      selected,
      c("rows", "columns"),
      object = "Preparation 04 metric artifact manifest"
    )
    actual_shape <- lapply(selected$path[csv_rows], function(path) {
      data <- metric_mder_verifier_read_csv(path)
      c(rows = nrow(data), columns = ncol(data))
    })
    actual_rows <- vapply(actual_shape, `[[`, numeric(1), "rows")
    actual_columns <- vapply(actual_shape, `[[`, numeric(1), "columns")
    exact_shape <- actual_rows == selected$rows[csv_rows] &
      actual_columns == selected$columns[csv_rows]
    if (anyNA(exact_shape) || !all(exact_shape)) {
      abort_pipeline(
        "Preparation 04 manifest rows/columns disagree for a relevant CSV artifact"
      )
    }
  }
  placement_rows <- !is.na(selected$placement)
  mder_metadata <- c(
    "profile_variant",
    "mder_support_cutoff",
    "mder_support_decision_id",
    "mder_support_status",
    "mder_support_candidates",
    "mder_support_sensitivity_cutoffs",
    "mder_support_rule",
    "mder_failure_scope",
    "mder_ratio_definition",
    "mder_ratio_scaled_or_weighted"
  )
  assert_columns(
    selected,
    mder_metadata,
    object = "Preparation 04 metric artifact manifest"
  )
  placement_metadata <- selected[placement_rows, , drop = FALSE]
  if (
    anyNA(placement_metadata[mder_metadata]) ||
      any(placement_metadata$profile_variant != "pooled") ||
      any(
        abs(
          placement_metadata$mder_support_cutoff -
            metric_mder_verifier_cutoff
        ) >
          1e-12
      ) ||
      any(
        placement_metadata$mder_support_decision_id != "METRIC-003"
      ) ||
      any(placement_metadata$mder_support_status != "author_approved") ||
      any(
        placement_metadata$mder_support_candidates != "0.7|0.8|0.9"
      ) ||
      any(
        placement_metadata$mder_support_sensitivity_cutoffs != "0.7|0.9"
      ) ||
      any(
        placement_metadata$mder_support_rule !=
          "ordinary_and_both_fixed_signal_profile_supports_gte_cutoff"
      ) ||
      any(
        placement_metadata$mder_failure_scope !=
          "metric_specific_only_day_retained"
      ) ||
      any(
        placement_metadata$mder_ratio_definition !=
          "ratio_of_observed_paired_integrals"
      ) ||
      any(placement_metadata$mder_ratio_scaled_or_weighted)
  ) {
    abort_pipeline(
      "Preparation 04 manifest does not record the approved 0.80 unscaled MDER rule"
    )
  }
  invisible(selected)
}

metric_mder_verifier_assert_settings <- function(
  settings,
  run_label,
  placements,
  gate
) {
  required <- c(
    "run_label",
    "placement",
    "profile_variant",
    "mder_support_cutoff",
    "mder_support_decision_id",
    "mder_support_status",
    "mder_support_candidates",
    "mder_support_sensitivity_cutoffs",
    "mder_support_rule",
    "mder_failure_scope",
    "mder_ratio_definition",
    "mder_ratio_scaled_or_weighted",
    "eligible_participant_days"
  )
  assert_columns(
    settings,
    required,
    object = "Preparation 04 metric settings"
  )
  assert_unique_key(
    settings,
    "placement",
    object = "Preparation 04 metric settings"
  )
  selected <- settings |>
    dplyr::filter(.data$placement %in% placements) |>
    dplyr::arrange(.data$placement)
  expected_days <- gate |>
    dplyr::count(.data$position, name = "expected_days") |>
    dplyr::arrange(.data$position)
  if (
    nrow(selected) != length(placements) ||
      !identical(as.character(selected$placement), sort(placements)) ||
      anyNA(selected[required]) ||
      any(selected$run_label != run_label) ||
      any(selected$profile_variant != "pooled") ||
      any(
        abs(
          selected$mder_support_cutoff -
            metric_mder_verifier_cutoff
        ) >
          1e-12
      ) ||
      any(selected$mder_support_decision_id != "METRIC-003") ||
      any(selected$mder_support_status != "author_approved") ||
      any(selected$mder_support_candidates != "0.7|0.8|0.9") ||
      any(selected$mder_support_sensitivity_cutoffs != "0.7|0.9") ||
      any(
        selected$mder_support_rule !=
          "ordinary_and_both_fixed_signal_profile_supports_gte_cutoff"
      ) ||
      any(
        selected$mder_failure_scope != "metric_specific_only_day_retained"
      ) ||
      any(
        selected$mder_ratio_definition != "ratio_of_observed_paired_integrals"
      ) ||
      any(selected$mder_ratio_scaled_or_weighted) ||
      !identical(
        as.integer(selected$eligible_participant_days),
        as.integer(expected_days$expected_days)
      )
  ) {
    abort_pipeline(
      "Preparation 04 settings do not record the approved 0.80 unscaled MDER rule and retained day counts"
    )
  }
  invisible(selected)
}

metric_mder_verifier_required_daily_columns <- function() {
  c(
    metric_mder_verifier_day_key,
    "profile_variant",
    "expected_real_minutes",
    "mder",
    "mder_ordinary_paired_coverage",
    "mder_medi_profile_coverage",
    "mder_light_profile_coverage",
    "mder_minimum_support",
    "mder_passes_ordinary_paired_support",
    "mder_passes_medi_profile_support",
    "mder_passes_light_profile_support",
    "mder_support_threshold_enforced",
    "mder_ratio_scaled_or_weighted",
    "mder_estimable",
    "mder_failure_reason"
  )
}

metric_mder_verifier_required_long_columns <- function() {
  c(
    metric_mder_verifier_day_key,
    "profile_variant",
    "analysis_unit",
    "metric",
    "value",
    "units",
    "state_domain",
    "estimable",
    "failure_reason",
    "ordinary_support",
    "relevance_support",
    "valid_minutes",
    "expected_minutes",
    "medi_profile_support",
    "light_profile_support",
    "minimum_support",
    "passes_ordinary_support",
    "passes_medi_profile_support",
    "passes_light_profile_support",
    "support_threshold_enforced",
    "ratio_scaled_or_weighted"
  )
}

metric_mder_verifier_required_support_columns <- function() {
  setdiff(
    metric_mder_verifier_required_long_columns(),
    c("analysis_unit", "value", "units")
  )
}

metric_mder_verifier_assert_wide_csv <- function(
  daily_rds,
  daily_csv,
  placement,
  tolerance
) {
  columns <- metric_mder_verifier_required_daily_columns()
  assert_columns(
    daily_rds,
    columns,
    object = paste0(placement, " participant-day RDS")
  )
  assert_columns(
    daily_csv,
    columns,
    object = paste0(placement, " participant-day CSV")
  )
  daily_rds <- metric_mder_verifier_normalise_keys(daily_rds)
  daily_csv <- metric_mder_verifier_normalise_keys(daily_csv)
  assert_unique_key(
    daily_rds,
    metric_mder_verifier_day_key,
    object = paste0(placement, " participant-day RDS")
  )
  assert_unique_key(
    daily_csv,
    metric_mder_verifier_day_key,
    object = paste0(placement, " participant-day CSV")
  )
  daily_rds <- metric_mder_verifier_arrange(daily_rds)
  daily_csv <- metric_mder_verifier_arrange(daily_csv)
  if (nrow(daily_rds) != nrow(daily_csv)) {
    abort_pipeline(
      "%s participant-day RDS and CSV contain different day counts",
      placement
    )
  }
  for (column in columns) {
    if (
      !metric_mder_verifier_values_equal(
        daily_rds[[column]],
        daily_csv[[column]],
        tolerance = tolerance
      )
    ) {
      abort_pipeline(
        "%s participant-day RDS and CSV disagree in `%s`",
        placement,
        column
      )
    }
  }
  daily_rds
}

metric_mder_verifier_assert_placement <- function(
  placement,
  paths,
  gate,
  tolerance = 1e-12
) {
  daily_rds <- readRDS(paths[["participant_day_metrics_rds"]])
  if (!is.data.frame(daily_rds)) {
    abort_pipeline("%s participant-day RDS must be a data frame", placement)
  }
  daily_csv <- metric_mder_verifier_read_csv(
    paths[["participant_day_metrics_csv"]]
  )
  daily <- metric_mder_verifier_assert_wide_csv(
    dplyr::ungroup(daily_rds),
    daily_csv,
    placement,
    tolerance
  )
  gate <- gate |>
    dplyr::filter(.data$position == placement) |>
    metric_mder_verifier_normalise_keys() |>
    metric_mder_verifier_arrange()
  metric_mder_verifier_assert_key_set(
    daily,
    gate,
    paste0(placement, " participant-day metrics")
  )

  values <- metric_mder_verifier_read_csv(
    paths[["long_metric_values"]]
  )
  assert_columns(
    values,
    metric_mder_verifier_required_long_columns(),
    object = paste0(placement, " long metric values")
  )
  values <- values |>
    dplyr::filter(
      .data$analysis_unit == "participant_day",
      .data$metric == metric_mder_verifier_metric
    ) |>
    metric_mder_verifier_normalise_keys() |>
    metric_mder_verifier_arrange()
  metric_mder_verifier_assert_key_set(
    values,
    gate,
    paste0(placement, " long MDER metric values")
  )

  support <- metric_mder_verifier_read_csv(
    paths[["metric_support_diagnostics"]]
  )
  assert_columns(
    support,
    metric_mder_verifier_required_support_columns(),
    object = paste0(placement, " MDER support diagnostics")
  )
  support <- support |>
    dplyr::filter(.data$metric == metric_mder_verifier_metric) |>
    metric_mder_verifier_normalise_keys() |>
    metric_mder_verifier_arrange()
  metric_mder_verifier_assert_key_set(
    support,
    gate,
    paste0(placement, " MDER support diagnostics")
  )

  daily <- metric_mder_verifier_arrange(daily)
  expected_failure <- metric_mder_verifier_expected_failure(gate)
  expected_retained <- gate$retained_at_0_80
  expected_ordinary_pass <-
    gate$ordinary_paired_coverage >= metric_mder_verifier_cutoff
  expected_medi_pass <-
    gate$medi_paired_profile_coverage >= metric_mder_verifier_cutoff
  expected_light_pass <-
    gate$light_paired_profile_coverage >= metric_mder_verifier_cutoff
  expected_relevance <- pmin(
    gate$medi_paired_profile_coverage,
    gate$light_paired_profile_coverage
  )

  daily_expectations <- list(
    expected_real_minutes = gate$expected_true_minutes,
    mder_ordinary_paired_coverage = gate$ordinary_paired_coverage,
    mder_medi_profile_coverage = gate$medi_paired_profile_coverage,
    mder_light_profile_coverage = gate$light_paired_profile_coverage,
    mder_minimum_support = rep(metric_mder_verifier_cutoff, nrow(gate)),
    mder_passes_ordinary_paired_support = expected_ordinary_pass,
    mder_passes_medi_profile_support = expected_medi_pass,
    mder_passes_light_profile_support = expected_light_pass,
    mder_support_threshold_enforced = rep(TRUE, nrow(gate)),
    mder_ratio_scaled_or_weighted = rep(FALSE, nrow(gate)),
    mder_estimable = expected_retained,
    mder_failure_reason = expected_failure
  )
  for (column in names(daily_expectations)) {
    metric_mder_verifier_assert_equal(
      daily[[column]],
      daily_expectations[[column]],
      paste0(placement, " participant-day MDER output"),
      column,
      tolerance
    )
  }
  if (
    any(daily$profile_variant != "pooled") ||
      any(values$profile_variant != "pooled") ||
      any(support$profile_variant != "pooled") ||
      any(values$units != "dimensionless") ||
      any(values$state_domain != "full_day_paired_channels") ||
      any(support$state_domain != "full_day_paired_channels") ||
      any(is.finite(daily$mder) != expected_retained) ||
      any(is.finite(values$value) != expected_retained)
  ) {
    abort_pipeline(
      "%s MDER output has inconsistent profile, domain, units, or estimability",
      placement
    )
  }

  long_expectations <- list(
    ordinary_support = gate$ordinary_paired_coverage,
    relevance_support = expected_relevance,
    valid_minutes = gate$paired_finite_medi_light_minutes,
    expected_minutes = gate$expected_true_minutes,
    medi_profile_support = gate$medi_paired_profile_coverage,
    light_profile_support = gate$light_paired_profile_coverage,
    minimum_support = rep(metric_mder_verifier_cutoff, nrow(gate)),
    passes_ordinary_support = expected_ordinary_pass,
    passes_medi_profile_support = expected_medi_pass,
    passes_light_profile_support = expected_light_pass,
    support_threshold_enforced = rep(TRUE, nrow(gate)),
    ratio_scaled_or_weighted = rep(FALSE, nrow(gate)),
    estimable = expected_retained,
    failure_reason = expected_failure
  )
  for (column in names(long_expectations)) {
    metric_mder_verifier_assert_equal(
      values[[column]],
      long_expectations[[column]],
      paste0(placement, " long MDER output"),
      column,
      tolerance
    )
    metric_mder_verifier_assert_equal(
      support[[column]],
      long_expectations[[column]],
      paste0(placement, " MDER support output"),
      column,
      tolerance
    )
  }

  metric_mder_verifier_assert_equal(
    values$value,
    daily$mder,
    paste0(placement, " wide/long MDER output"),
    "value",
    tolerance
  )
  wide_long_columns <- c(
    mder_ordinary_paired_coverage = "ordinary_support",
    mder_medi_profile_coverage = "medi_profile_support",
    mder_light_profile_coverage = "light_profile_support",
    mder_minimum_support = "minimum_support",
    mder_passes_ordinary_paired_support = "passes_ordinary_support",
    mder_passes_medi_profile_support = "passes_medi_profile_support",
    mder_passes_light_profile_support = "passes_light_profile_support",
    mder_support_threshold_enforced = "support_threshold_enforced",
    mder_ratio_scaled_or_weighted = "ratio_scaled_or_weighted",
    mder_estimable = "estimable",
    mder_failure_reason = "failure_reason"
  )
  for (daily_column in names(wide_long_columns)) {
    long_column <- wide_long_columns[[daily_column]]
    if (
      !metric_mder_verifier_values_equal(
        daily[[daily_column]],
        values[[long_column]],
        tolerance = tolerance
      ) ||
        !metric_mder_verifier_values_equal(
          values[[long_column]],
          support[[long_column]],
          tolerance = tolerance
        )
    ) {
      abort_pipeline(
        "%s wide/long/support MDER outputs disagree in `%s`",
        placement,
        long_column
      )
    }
  }

  tibble::tibble(
    placement = placement,
    eligible_participant_days = nrow(gate),
    retained_at_0_80 = sum(expected_retained),
    excluded_at_0_80 = sum(!expected_retained),
    no_paired_observation = sum(
      expected_failure == "no_paired_observation",
      na.rm = TRUE
    ),
    nonpositive_paired_light_integral = sum(
      expected_failure == "nonpositive_paired_light_integral",
      na.rm = TRUE
    ),
    below_ordinary_paired_support = sum(
      expected_failure == "below_ordinary_paired_support",
      na.rm = TRUE
    ),
    below_medi_profile_support = sum(
      expected_failure == "below_medi_profile_support",
      na.rm = TRUE
    ),
    below_light_profile_support = sum(
      expected_failure == "below_light_profile_support",
      na.rm = TRUE
    )
  )
}

verify_metric_derivation_mder <- function(
  root = project_root(),
  run_label = "full",
  metric_run_root = NULL,
  metric_manifest_path = NULL,
  gate_run_root = NULL,
  gate_manifest_path = NULL,
  placements = NULL,
  tolerance = 1e-12
) {
  if (
    !is.numeric(tolerance) ||
      length(tolerance) != 1L ||
      is.na(tolerance) ||
      !is.finite(tolerance) ||
      tolerance < 0
  ) {
    abort_pipeline("`tolerance` must be one finite non-negative value")
  }
  layout <- metric_mder_verifier_layout(
    root = root,
    run_label = run_label,
    metric_run_root = metric_run_root,
    metric_manifest_path = metric_manifest_path,
    gate_run_root = gate_run_root,
    gate_manifest_path = gate_manifest_path
  )
  placements <- metric_mder_verifier_resolve_placements(
    placements,
    layout$metric_run_root
  )
  metric_paths <- lapply(
    placements,
    metric_mder_verifier_output_paths,
    metric_run_root = layout$metric_run_root
  )
  names(metric_paths) <- placements
  gate_path <- normalizePath(
    file.path(layout$gate_run_root, "mder_support_gate_daily.csv"),
    winslash = "/",
    mustWork = TRUE
  )
  settings_path <- normalizePath(
    file.path(layout$metric_run_root, "metric_derivation_settings.csv"),
    winslash = "/",
    mustWork = TRUE
  )
  read_paths <- c(
    layout$metric_manifest_path,
    layout$gate_manifest_path,
    gate_path,
    settings_path,
    unlist(metric_paths, use.names = FALSE)
  )
  before <- metric_mder_verifier_fingerprint(read_paths)

  gate_manifest <- metric_mder_verifier_read_csv(
    layout$gate_manifest_path
  )
  metric_mder_verifier_assert_gate_manifest(
    gate_manifest,
    layout,
    gate_path
  )
  gate <- metric_mder_verifier_read_csv(gate_path) |>
    metric_mder_verifier_normalise_keys() |>
    metric_mder_verifier_arrange()
  metric_mder_verifier_assert_gate(
    gate,
    run_label = layout$run_label,
    placements = placements
  )

  metric_manifest <- metric_mder_verifier_read_csv(
    layout$metric_manifest_path
  )
  relevant_manifest <- metric_mder_verifier_assert_metric_manifest(
    metric_manifest,
    layout,
    placements
  )
  settings <- metric_mder_verifier_read_csv(settings_path)
  metric_mder_verifier_assert_settings(
    settings,
    run_label = layout$run_label,
    placements = placements,
    gate = gate
  )

  placement_summary <- dplyr::bind_rows(lapply(
    placements,
    function(placement) {
      metric_mder_verifier_assert_placement(
        placement,
        metric_paths[[placement]],
        gate,
        tolerance = tolerance
      )
    }
  )) |>
    dplyr::arrange(.data$placement)

  after <- metric_mder_verifier_fingerprint(read_paths)
  metric_mder_verifier_assert_immutable(before, after)
  list(
    status = "PASS",
    run_label = layout$run_label,
    cutoff = metric_mder_verifier_cutoff,
    placements = placements,
    placement_summary = placement_summary,
    eligible_participant_days = sum(
      placement_summary$eligible_participant_days
    ),
    retained_at_0_80 = sum(placement_summary$retained_at_0_80),
    excluded_at_0_80 = sum(placement_summary$excluded_at_0_80),
    relevant_manifest_rows = nrow(relevant_manifest),
    immutable_inputs = TRUE,
    ratio_recalculated = FALSE,
    gate_path = gate_path,
    metric_manifest_path = layout$metric_manifest_path,
    gate_manifest_path = layout$gate_manifest_path
  )
}
