# Independently verify the canonical participant-day MDER calculation.
#
# Source paths_io.R and assertions.R before calling this verifier. It does not
# source or call the metric builder, metric_derivation.R, or time_support.R.
# The verifier independently flattens repeated local-clock minutes, constructs
# the complete 1,440-minute day, calculates positive finite momentary ratios,
# applies the inclusive 50% viable-ratio rule, and reconciles every stored MDER
# value and support field.

metric_mder_verifier_day_key <- c("site", "Id", "position", "local_date")
metric_mder_verifier_metric <- "mder_mean_of_viable_ratios"
metric_mder_verifier_fraction <- 0.50

metric_mder_verifier_run_label <- function(run_label = "full") {
  if (
    !is.character(run_label) || length(run_label) != 1L ||
      is.na(run_label) || !nzchar(trimws(run_label)) ||
      !grepl("^[A-Za-z0-9._-]+$", trimws(run_label))
  ) {
    abort_pipeline("`run_label` must be one safe non-empty label")
  }
  trimws(run_label)
}

metric_mder_verifier_optional_path <- function(path, default, must_work = TRUE) {
  selected <- if (is.null(path)) default else path
  if (
    !is.character(selected) || length(selected) != 1L ||
      is.na(selected) || !nzchar(trimws(selected))
  ) {
    abort_pipeline("Verifier paths must be one non-empty character value")
  }
  normalizePath(trimws(selected), winslash = "/", mustWork = must_work)
}

metric_mder_verifier_layout <- function(
  root,
  run_label = "full",
  metric_run_root = NULL,
  metric_manifest_path = NULL,
  coverage_run_root = NULL
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  run_label <- metric_mder_verifier_run_label(run_label)
  paths <- pipeline_paths(root)
  suffix <- if (identical(run_label, "full")) "" else paste0("_", run_label)
  metric_default <- if (identical(run_label, "full")) {
    paths$metrics
  } else {
    file.path(paths$metrics, "runs", run_label)
  }
  coverage_default <- if (identical(run_label, "full")) {
    paths$coverage
  } else {
    file.path(paths$coverage, "runs", run_label)
  }
  list(
    root = root,
    run_label = run_label,
    paths = paths,
    metric_run_root = metric_mder_verifier_optional_path(
      metric_run_root,
      metric_default
    ),
    metric_manifest_path = metric_mder_verifier_optional_path(
      metric_manifest_path,
      file.path(paths$manifests, paste0("metric_artifacts", suffix, ".csv"))
    ),
    coverage_run_root = metric_mder_verifier_optional_path(
      coverage_run_root,
      coverage_default
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

metric_mder_verifier_resolve_placements <- function(placements, metric_run_root) {
  available <- metric_mder_verifier_discover_placements(metric_run_root)
  if (length(available) == 0L) {
    abort_pipeline("No Preparation 04 participant-day outputs were found")
  }
  if (is.null(placements) || length(placements) == 0L) {
    return(available)
  }
  placements <- sort(unique(trimws(as.character(placements))))
  if (anyNA(placements) || any(!nzchar(placements))) {
    abort_pipeline("`placements` must contain non-empty labels")
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
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    na = c("", "NA")
  )
}

metric_mder_verifier_fingerprint <- function(paths) {
  paths <- sort(unique(normalizePath(paths, winslash = "/", mustWork = TRUE)))
  tibble::tibble(
    path = paths,
    sha256 = vapply(paths, artifact_sha256, character(1)),
    bytes = unname(file.info(paths)$size)
  )
}

metric_mder_verifier_assert_immutable <- function(before, after) {
  if (!identical(before, after)) {
    abort_pipeline("An MDER input or output changed during verification")
  }
  invisible(TRUE)
}

metric_mder_verifier_values_equal <- function(observed, expected, tolerance) {
  if (
    length(observed) != length(expected) ||
      !identical(is.na(observed), is.na(expected))
  ) {
    return(FALSE)
  }
  keep <- !is.na(observed)
  if (!any(keep)) return(TRUE)
  if (is.numeric(observed) && is.numeric(expected)) {
    return(isTRUE(all.equal(
      as.numeric(observed[keep]),
      as.numeric(expected[keep]),
      tolerance = tolerance,
      check.attributes = FALSE
    )))
  }
  identical(as.character(observed[keep]), as.character(expected[keep]))
}

metric_mder_verifier_assert_equal <- function(
  observed,
  expected,
  object,
  column,
  tolerance
) {
  if (!metric_mder_verifier_values_equal(observed, expected, tolerance)) {
    abort_pipeline("%s disagrees with independent MDER reconstruction in `%s`", object, column)
  }
  invisible(TRUE)
}

metric_mder_verifier_expected_day <- function(day) {
  collapsed <- day |>
    dplyr::group_by(.data$clock_minute) |>
    dplyr::summarise(
      medi = if (any(is.finite(.data$MEDI_eligible))) {
        mean(.data$MEDI_eligible[is.finite(.data$MEDI_eligible)])
      } else {
        NA_real_
      },
      light = if (any(is.finite(.data$LIGHT_eligible))) {
        mean(.data$LIGHT_eligible[is.finite(.data$LIGHT_eligible)])
      } else {
        NA_real_
      },
      .groups = "drop"
    )
  wall <- dplyr::left_join(
    tibble::tibble(clock_minute = 0:1439),
    collapsed,
    by = "clock_minute",
    relationship = "one-to-one"
  )
  finite_pair <- is.finite(wall$medi) & is.finite(wall$light)
  zero_medi <- finite_pair & wall$medi == 0
  zero_light <- finite_pair & wall$light == 0
  positive_pair <- finite_pair & wall$medi > 0 & wall$light > 0
  ratio <- rep(NA_real_, 1440L)
  ratio[positive_pair] <- suppressWarnings(
    wall$medi[positive_pair] / wall$light[positive_pair]
  )
  viable <- positive_pair & is.finite(ratio)
  viable_minutes <- sum(viable)
  viable_fraction <- viable_minutes / 1440
  pass <- viable_fraction >= metric_mder_verifier_fraction
  reason <- if (viable_minutes == 0L) {
    "no_viable_momentary_ratio"
  } else if (!pass) {
    "below_viable_ratio_fraction"
  } else {
    NA_character_
  }
  key <- day[1L, metric_mder_verifier_day_key, drop = FALSE]
  dplyr::bind_cols(
    key,
    tibble::tibble(
      mder = if (is.na(reason)) mean(ratio[viable]) else NA_real_,
      mder_viable_ratio_minutes = viable_minutes,
      mder_expected_minutes = 1440L,
      mder_viable_ratio_fraction = viable_fraction,
      mder_excluded_nonfinite_source_minutes = sum(!finite_pair),
      mder_excluded_zero_either_minutes = sum(finite_pair & (zero_medi | zero_light)),
      mder_excluded_zero_medi_minutes = sum(zero_medi),
      mder_excluded_zero_light_minutes = sum(zero_light),
      mder_excluded_both_zero_minutes = sum(zero_medi & zero_light),
      mder_excluded_nonfinite_ratio_minutes = sum(
        positive_pair & !is.finite(ratio)
      ),
      mder_minimum_viable_fraction = metric_mder_verifier_fraction,
      mder_passes_viable_ratio_support = pass,
      mder_support_threshold_enforced = TRUE,
      mder_ratio_scaled_or_weighted = FALSE,
      mder_estimable = is.na(reason),
      mder_failure_reason = reason
    )
  )
}

metric_mder_verifier_expected <- function(coverage, placement) {
  required <- c(
    metric_mder_verifier_day_key,
    "clock_minute",
    "day_eligible",
    "MEDI_eligible",
    "LIGHT_eligible"
  )
  assert_columns(coverage, required, object = paste0(placement, " coverage"))
  coverage <- coverage |>
    dplyr::mutate(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      position = as.character(.data$position),
      local_date = as.Date(.data$local_date),
      clock_minute = as.integer(.data$clock_minute)
    ) |>
    dplyr::filter(.data$day_eligible, .data$position == placement)
  if (nrow(coverage) == 0L || anyNA(coverage$clock_minute)) {
    abort_pipeline("%s coverage has no eligible complete clock keys", placement)
  }
  groups <- split(
    seq_len(nrow(coverage)),
    interaction(
      coverage$site,
      coverage$Id,
      coverage$position,
      coverage$local_date,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  purrr::map_dfr(groups, function(index) {
    metric_mder_verifier_expected_day(coverage[index, , drop = FALSE])
  }) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(metric_mder_verifier_day_key)))
}

metric_mder_verifier_assert_manifest <- function(
  manifest,
  layout,
  placements
) {
  required <- c(
    "path", "sha256", "bytes", "producer", "artifact_type", "run_label"
  )
  assert_columns(manifest, required, object = "metric artifact manifest")
  expected_paths <- c(
    unlist(lapply(
      placements,
      metric_mder_verifier_output_paths,
      metric_run_root = layout$metric_run_root
    ), use.names = FALSE),
    file.path(layout$metric_run_root, "metric_derivation_settings.csv")
  )
  expected_paths <- normalizePath(expected_paths, winslash = "/", mustWork = TRUE)
  manifest$normal_path <- normalizePath(
    manifest$path,
    winslash = "/",
    mustWork = TRUE
  )
  selected <- manifest[manifest$normal_path %in% expected_paths, , drop = FALSE]
  if (nrow(selected) != length(expected_paths) || anyDuplicated(selected$normal_path)) {
    abort_pipeline("Metric manifest does not contain the exact MDER verification files")
  }
  selected <- selected[match(expected_paths, selected$normal_path), , drop = FALSE]
  actual_sha <- vapply(expected_paths, artifact_sha256, character(1))
  actual_bytes <- unname(file.info(expected_paths)$size)
  if (
    any(selected$run_label != layout$run_label) ||
      any(selected$producer != "scripts/pipeline/build_metric_derivation.R") ||
      !identical(as.character(selected$sha256), unname(actual_sha)) ||
      !identical(as.numeric(selected$bytes), as.numeric(actual_bytes))
  ) {
    abort_pipeline("Metric manifest hash/bytes or provenance disagree")
  }
  placement_rows <- !is.na(selected$placement)
  required_metadata <- c(
    "mder_support_cutoff",
    "mder_support_decision_id",
    "mder_support_status",
    "mder_support_rule",
    "mder_failure_scope",
    "mder_ratio_definition",
    "mder_pair_resolution_minutes",
    "mder_zero_pair_rule",
    "mder_nonfinite_pair_rule",
    "mder_ratio_scaled_or_weighted"
  )
  assert_columns(selected, required_metadata, object = "metric artifact manifest")
  metadata <- selected[placement_rows, , drop = FALSE]
  if (
    any(abs(metadata$mder_support_cutoff - 0.50) > 1e-12) ||
      any(metadata$mder_support_decision_id != "METRIC-010") ||
      any(metadata$mder_support_status != "author_approved") ||
      any(metadata$mder_support_rule !=
        "positive_finite_one_minute_ratio_fraction_gte_0.50") ||
      any(metadata$mder_failure_scope != "metric_specific_only_day_retained") ||
      any(metadata$mder_ratio_definition !=
        "arithmetic_mean_of_positive_finite_one_minute_ratios") ||
      any(metadata$mder_pair_resolution_minutes != 1L) ||
      any(metadata$mder_zero_pair_rule != "exclude_if_either_channel_zero") ||
      any(metadata$mder_nonfinite_pair_rule !=
        "exclude_if_source_or_ratio_nonfinite") ||
      any(metadata$mder_ratio_scaled_or_weighted)
  ) {
    abort_pipeline("Metric manifest does not record the approved MDER rule")
  }
  selected
}

metric_mder_verifier_assert_placement <- function(
  placement,
  paths,
  expected,
  tolerance
) {
  daily_rds <- readRDS(paths[["participant_day_metrics_rds"]]) |>
    dplyr::mutate(local_date = as.Date(.data$local_date)) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(metric_mder_verifier_day_key)))
  daily_csv <- metric_mder_verifier_read_csv(
    paths[["participant_day_metrics_csv"]]
  ) |>
    dplyr::mutate(local_date = as.Date(.data$local_date)) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(metric_mder_verifier_day_key)))
  required_wide <- c(metric_mder_verifier_day_key, setdiff(names(expected), metric_mder_verifier_day_key))
  assert_columns(daily_rds, required_wide, object = paste0(placement, " daily RDS"))
  assert_columns(daily_csv, required_wide, object = paste0(placement, " daily CSV"))
  assert_unique_key(daily_rds, metric_mder_verifier_day_key, object = paste0(placement, " daily RDS"))
  if (nrow(daily_rds) != nrow(expected)) {
    abort_pipeline("%s daily output does not retain every eligible participant-day", placement)
  }
  for (column in required_wide) {
    metric_mder_verifier_assert_equal(
      daily_rds[[column]],
      expected[[column]],
      paste0(placement, " participant-day MDER output"),
      column,
      tolerance
    )
    metric_mder_verifier_assert_equal(
      daily_csv[[column]],
      expected[[column]],
      paste0(placement, " participant-day CSV"),
      column,
      tolerance
    )
  }

  long <- metric_mder_verifier_read_csv(paths[["long_metric_values"]]) |>
    dplyr::filter(.data$metric == metric_mder_verifier_metric) |>
    dplyr::mutate(local_date = as.Date(.data$local_date)) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(metric_mder_verifier_day_key)))
  support <- metric_mder_verifier_read_csv(
    paths[["metric_support_diagnostics"]]
  ) |>
    dplyr::filter(.data$metric == metric_mder_verifier_metric) |>
    dplyr::mutate(local_date = as.Date(.data$local_date)) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(metric_mder_verifier_day_key)))
  for (object_name in c("long", "support")) {
    object <- if (object_name == "long") long else support
    assert_unique_key(
      object,
      metric_mder_verifier_day_key,
      object = paste0(placement, " MDER ", object_name)
    )
    if (nrow(object) != nrow(expected)) {
      abort_pipeline("%s long/support MDER rows do not retain every day", placement)
    }
  }
  long_expected <- list(
    value = expected$mder,
    estimable = expected$mder_estimable,
    failure_reason = expected$mder_failure_reason,
    ordinary_support = expected$mder_viable_ratio_fraction,
    relevance_support = rep(NA_real_, nrow(expected)),
    valid_minutes = expected$mder_viable_ratio_minutes,
    expected_minutes = expected$mder_expected_minutes,
    minimum_support = expected$mder_minimum_viable_fraction,
    passes_ordinary_support = expected$mder_passes_viable_ratio_support,
    support_threshold_enforced = rep(TRUE, nrow(expected)),
    ratio_scaled_or_weighted = rep(FALSE, nrow(expected))
  )
  object_expected <- list(
    long = long_expected,
    support = long_expected[setdiff(names(long_expected), "value")]
  )
  for (object_name in names(object_expected)) {
    object <- if (object_name == "long") long else support
    for (column in names(object_expected[[object_name]])) {
      metric_mder_verifier_assert_equal(
        object[[column]],
        object_expected[[object_name]][[column]],
        paste0(placement, " MDER ", object_name, " output"),
        column,
        tolerance
      )
    }
  }
  tibble::tibble(
    placement = placement,
    eligible_participant_days = nrow(expected),
    estimable_mder_days = sum(expected$mder_estimable),
    excluded_mder_days = sum(!expected$mder_estimable),
    below_viable_ratio_fraction = sum(
      expected$mder_failure_reason == "below_viable_ratio_fraction",
      na.rm = TRUE
    ),
    no_viable_momentary_ratio = sum(
      expected$mder_failure_reason == "no_viable_momentary_ratio",
      na.rm = TRUE
    )
  )
}

verify_metric_derivation_mder <- function(
  root = project_root(),
  run_label = "full",
  metric_run_root = NULL,
  metric_manifest_path = NULL,
  coverage_run_root = NULL,
  placements = NULL,
  tolerance = 1e-12
) {
  if (
    !is.numeric(tolerance) || length(tolerance) != 1L ||
      is.na(tolerance) || !is.finite(tolerance) || tolerance < 0
  ) {
    abort_pipeline("`tolerance` must be one finite non-negative value")
  }
  layout <- metric_mder_verifier_layout(
    root = root,
    run_label = run_label,
    metric_run_root = metric_run_root,
    metric_manifest_path = metric_manifest_path,
    coverage_run_root = coverage_run_root
  )
  placements <- metric_mder_verifier_resolve_placements(
    placements,
    layout$metric_run_root
  )
  output_paths <- lapply(
    placements,
    metric_mder_verifier_output_paths,
    metric_run_root = layout$metric_run_root
  )
  names(output_paths) <- placements
  coverage_paths <- stats::setNames(
    file.path(
      layout$coverage_run_root,
      paste0("light_", placements, "_coverage.rds")
    ),
    placements
  )
  settings_path <- file.path(
    layout$metric_run_root,
    "metric_derivation_settings.csv"
  )
  read_paths <- c(
    layout$metric_manifest_path,
    settings_path,
    coverage_paths,
    unlist(output_paths, use.names = FALSE)
  )
  before <- metric_mder_verifier_fingerprint(read_paths)
  manifest <- metric_mder_verifier_read_csv(layout$metric_manifest_path)
  relevant_manifest <- metric_mder_verifier_assert_manifest(
    manifest,
    layout,
    placements
  )
  settings <- metric_mder_verifier_read_csv(settings_path)
  assert_columns(
    settings,
    c(
      "placement", "mder_support_cutoff", "mder_support_decision_id",
      "mder_ratio_definition", "eligible_participant_days"
    ),
    object = "metric derivation settings"
  )

  summaries <- lapply(placements, function(placement) {
    coverage <- readRDS(coverage_paths[[placement]])
    expected <- metric_mder_verifier_expected(coverage, placement)
    selected_settings <- settings[settings$placement == placement, , drop = FALSE]
    if (
      nrow(selected_settings) != 1L ||
        selected_settings$mder_support_cutoff != 0.50 ||
        selected_settings$mder_support_decision_id != "METRIC-010" ||
        selected_settings$mder_ratio_definition !=
          "arithmetic_mean_of_positive_finite_one_minute_ratios" ||
        selected_settings$eligible_participant_days != nrow(expected)
    ) {
      abort_pipeline("%s settings disagree with the approved MDER rule", placement)
    }
    metric_mder_verifier_assert_placement(
      placement,
      output_paths[[placement]],
      expected,
      tolerance
    )
  })
  placement_summary <- dplyr::bind_rows(summaries) |>
    dplyr::arrange(.data$placement)
  after <- metric_mder_verifier_fingerprint(read_paths)
  metric_mder_verifier_assert_immutable(before, after)
  list(
    status = "PASS",
    run_label = layout$run_label,
    viable_ratio_fraction = metric_mder_verifier_fraction,
    metric = metric_mder_verifier_metric,
    placements = placements,
    placement_summary = placement_summary,
    eligible_participant_days = sum(placement_summary$eligible_participant_days),
    estimable_mder_days = sum(placement_summary$estimable_mder_days),
    excluded_mder_days = sum(placement_summary$excluded_mder_days),
    relevant_manifest_rows = nrow(relevant_manifest),
    immutable_inputs = TRUE,
    ratio_recalculated = TRUE,
    metric_manifest_path = layout$metric_manifest_path
  )
}
