# Independently verify the pre-analysis comparison gate artifacts.
#
# Source scripts/pipeline/paths_io.R and scripts/pipeline/assertions.R before
# calling verify_preanalysis_comparison_artifacts(). This verifier reads only
# completed artifacts. It deliberately does not source or call the comparison
# producer or any of its helpers.

preanalysis_verifier_csv_ids <- c(
  "input_provenance",
  "variable_crosswalk",
  "series_summary",
  "numeric_quantiles",
  "categorical_levels",
  "key_reconciliation",
  "paired_comparison_summary",
  "distribution_shape_summary",
  "comparison_overview",
  "figure_numeric_distribution_data",
  "figure_categorical_distribution_data",
  "run_metadata"
)

preanalysis_verifier_png_ids <- c(
  "numeric_distribution_overview",
  "categorical_distribution_overview"
)

preanalysis_verifier_markdown_ids <- "audit_report"

preanalysis_verifier_variable_key <- c(
  "variable_id",
  "placement",
  "analysis_unit"
)

preanalysis_verifier_probabilities <- c(
  0,
  0.025,
  0.05,
  0.25,
  0.5,
  0.75,
  0.95,
  0.975,
  1
)

preanalysis_verifier_variable_bearing_csv_ids <- c(
  "variable_crosswalk",
  "series_summary",
  "numeric_quantiles",
  "categorical_levels",
  "key_reconciliation",
  "paired_comparison_summary",
  "distribution_shape_summary",
  "comparison_overview",
  "figure_numeric_distribution_data",
  "figure_categorical_distribution_data"
)

preanalysis_verifier_forbidden_window_endpoint_pattern <- paste0(
  "(^|_)(m10|l10)_(onset|offset)($|_)",
  "|",
  "(^|_)(brightest|darkest)_10h_(onset|offset)($|_)"
)

preanalysis_verifier_crosswalk_schema <- c(
  "variable_order",
  "variable_id",
  "metric_id",
  "manuscript_name",
  "abbreviation",
  "manuscript_category",
  "analytical_role",
  "variant_label",
  "domain",
  "analysis_unit",
  "value_type",
  "canonical_source",
  "canonical_variable",
  "baseline_source",
  "baseline_variable",
  "native_unit",
  "comparison_unit",
  "display_unit",
  "canonical_transform",
  "baseline_transform",
  "difference_method",
  "technical_estimand",
  "comparison_status",
  "non_applicable_reason",
  "figure_priority",
  "axis_geometry",
  "linear_summary_interpretation",
  "mapping_scope",
  "semantic_comparability",
  "comparability_class",
  "comparability_note"
)

preanalysis_verifier_series_schema <- c(
  preanalysis_verifier_variable_key,
  "series",
  "domain",
  "value_type",
  "comparison_unit",
  "axis_geometry",
  "linear_summary_interpretation",
  "n_observations",
  "n_estimable",
  "n_nonestimable",
  "n_observed",
  "n_missing",
  "n_nonfinite",
  "n_estimable_missing",
  "n_participants",
  "n_participants_observed",
  "n_participant_days",
  "n_participant_days_observed",
  "mean",
  "sd",
  "median",
  "iqr",
  "q025",
  "q25",
  "q75",
  "q975",
  "minimum",
  "maximum",
  "n_zero",
  "zero_rate",
  "nonfinite_rate",
  "circular_mean",
  "circular_median",
  "circular_resultant_length",
  "circular_sd_hours"
)

preanalysis_verifier_quantile_schema <- c(
  preanalysis_verifier_variable_key,
  "series",
  "comparison_unit",
  "axis_geometry",
  "summary_interpretation",
  "probability",
  "value",
  "n_finite"
)

preanalysis_verifier_categorical_schema <- c(
  preanalysis_verifier_variable_key,
  "series",
  "level",
  "n",
  "proportion",
  "n_participants",
  "n_participant_days"
)

preanalysis_verifier_key_reconciliation_schema <- c(
  preanalysis_verifier_variable_key,
  "comparison_status",
  "baseline_n_keys",
  "canonical_n_keys",
  "common_n_keys",
  "baseline_only_n_keys",
  "canonical_only_n_keys",
  "baseline_n_participants",
  "canonical_n_participants",
  "baseline_n_participant_days",
  "canonical_n_participant_days"
)

preanalysis_verifier_paired_schema <- c(
  preanalysis_verifier_variable_key,
  "value_type",
  "comparison_status",
  "difference_method",
  "comparison_unit",
  "n_common_keys",
  "n_paired_observed",
  "mean_difference",
  "sd_difference",
  "median_difference",
  "iqr_difference",
  "q025_difference",
  "q975_difference",
  "mean_absolute_difference",
  "root_mean_square_difference",
  "pearson_correlation",
  "spearman_correlation",
  "n_equal",
  "agreement_rate"
)

preanalysis_verifier_shape_schema <- c(
  preanalysis_verifier_variable_key,
  "value_type",
  "comparison_status",
  "comparison_unit",
  "axis_geometry",
  "distance_scope",
  "distance_interpretation",
  "baseline_bowley_skew",
  "canonical_bowley_skew",
  "baseline_tail_asymmetry",
  "canonical_tail_asymmetry",
  "ecdf_max_distance",
  "wasserstein_1",
  "wasserstein_1_iqr_scaled",
  "circular_kuiper_distance",
  "total_variation_distance",
  "maximum_absolute_proportion_difference"
)

preanalysis_verifier_overview_schema <- c(
  "variable_id",
  "placement",
  "analysis_unit",
  "value_type",
  "comparison_status",
  "comparison_unit",
  "axis_geometry",
  "variable_order",
  "metric_id",
  "manuscript_name",
  "abbreviation",
  "manuscript_category",
  "analytical_role",
  "variant_label",
  "domain",
  "native_unit",
  "display_unit",
  "canonical_transform",
  "baseline_transform",
  "linear_summary_interpretation",
  "technical_estimand",
  "mapping_scope",
  "semantic_comparability",
  "comparability_class",
  "comparability_note",
  "non_applicable_reason",
  "canonical_n_observations",
  "canonical_n_estimable",
  "canonical_n_observed",
  "canonical_n_missing",
  "canonical_n_nonfinite",
  "canonical_n_participants",
  "canonical_n_participants_observed",
  "canonical_n_participant_days",
  "canonical_n_participant_days_observed",
  "canonical_mean",
  "canonical_median",
  "canonical_sd",
  "canonical_iqr",
  "canonical_q025",
  "canonical_q25",
  "canonical_q75",
  "canonical_q975",
  "canonical_zero_rate",
  "canonical_nonfinite_rate",
  "canonical_circular_mean",
  "canonical_circular_median",
  "canonical_circular_resultant_length",
  "canonical_circular_sd_hours",
  "baseline_n_observations",
  "baseline_n_estimable",
  "baseline_n_observed",
  "baseline_n_missing",
  "baseline_n_nonfinite",
  "baseline_n_participants",
  "baseline_n_participants_observed",
  "baseline_n_participant_days",
  "baseline_n_participant_days_observed",
  "baseline_mean",
  "baseline_median",
  "baseline_sd",
  "baseline_iqr",
  "baseline_q025",
  "baseline_q25",
  "baseline_q75",
  "baseline_q975",
  "baseline_zero_rate",
  "baseline_nonfinite_rate",
  "baseline_circular_mean",
  "baseline_circular_median",
  "baseline_circular_resultant_length",
  "baseline_circular_sd_hours",
  "delta_n_observations",
  "delta_n_estimable",
  "delta_n_observed",
  "delta_n_missing",
  "delta_n_nonfinite",
  "delta_n_participants",
  "delta_n_participants_observed",
  "delta_n_participant_days",
  "delta_n_participant_days_observed",
  "distance_scope",
  "distance_interpretation",
  "baseline_bowley_skew",
  "canonical_bowley_skew",
  "baseline_tail_asymmetry",
  "canonical_tail_asymmetry",
  "ecdf_max_distance",
  "wasserstein_1",
  "wasserstein_1_iqr_scaled",
  "circular_kuiper_distance",
  "total_variation_distance",
  "maximum_absolute_proportion_difference",
  "key_baseline_n_keys",
  "key_canonical_n_keys",
  "key_common_n_keys",
  "key_baseline_only_n_keys",
  "key_canonical_only_n_keys",
  "key_baseline_n_participants",
  "key_canonical_n_participants",
  "key_baseline_n_participant_days",
  "key_canonical_n_participant_days",
  "n_common_keys",
  "n_paired_observed",
  "mean_difference",
  "sd_difference",
  "median_difference",
  "iqr_difference",
  "q025_difference",
  "q975_difference",
  "mean_absolute_difference",
  "root_mean_square_difference",
  "pearson_correlation",
  "spearman_correlation",
  "n_equal",
  "agreement_rate"
)

preanalysis_verifier_numeric_figure_schema <- c(
  "variable_id",
  "variable_order",
  "metric_id",
  "manuscript_name",
  "abbreviation",
  "manuscript_category",
  "display_unit",
  "analytical_role",
  "variant_label",
  "domain",
  "placement",
  "analysis_unit",
  "series",
  "comparison_unit",
  "axis_geometry",
  "summary_interpretation",
  "probability",
  "value",
  "canonical_q0.25",
  "canonical_q0.5",
  "canonical_q0.75",
  "standardized_value",
  "display_axis",
  "n_finite"
)

preanalysis_verifier_categorical_figure_schema <- c(
  "variable_id",
  "variable_order",
  "metric_id",
  "manuscript_name",
  "abbreviation",
  "manuscript_category",
  "display_unit",
  "analytical_role",
  "variant_label",
  "domain",
  "placement",
  "analysis_unit",
  "series",
  "level",
  "n",
  "proportion",
  "n_participants",
  "n_participant_days"
)

preanalysis_verifier_path <- function(path, default, must_work = TRUE) {
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

preanalysis_verifier_layout <- function(
  root = project_root(),
  output_root = root
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  paths <- pipeline_paths(root)
  artifact_base <- preanalysis_verifier_path(
    output_root,
    root,
    must_work = TRUE
  )
  diagnostic_root <- preanalysis_verifier_path(
    file.path(
      artifact_base,
      "artifacts",
      "08_diagnostics",
      "preanalysis_comparison"
    ),
    "",
    must_work = TRUE
  )
  manifest_path <- preanalysis_verifier_path(
    file.path(
      artifact_base,
      "artifacts",
      "12_manifests",
      "preanalysis_comparison_artifacts.csv"
    ),
    "",
    must_work = TRUE
  )
  list(
    root = root,
    paths = paths,
    artifact_base = artifact_base,
    output_root = diagnostic_root,
    manifest_path = manifest_path
  )
}

preanalysis_verifier_output_paths <- function(output_root) {
  c(
    stats::setNames(
      file.path(
        output_root,
        paste0(preanalysis_verifier_csv_ids, ".csv")
      ),
      preanalysis_verifier_csv_ids
    ),
    stats::setNames(
      file.path(
        output_root,
        paste0(preanalysis_verifier_png_ids, ".png")
      ),
      preanalysis_verifier_png_ids
    ),
    stats::setNames(
      file.path(
        output_root,
        paste0(preanalysis_verifier_markdown_ids, ".md")
      ),
      preanalysis_verifier_markdown_ids
    )
  )
}

preanalysis_verifier_resolve_path <- function(path, root) {
  if (
    !is.character(path) ||
      length(path) != 1L ||
      is.na(path) ||
      !nzchar(trimws(path))
  ) {
    abort_pipeline("Artifact paths must be one non-empty character value")
  }
  path <- trimws(path)
  if (grepl("(^|/)[.][.](/|$)", path)) {
    abort_pipeline("Artifact paths may not contain `..`: %s", path)
  }
  candidate <- if (grepl("^/", path)) path else file.path(root, path)
  normalizePath(candidate, winslash = "/", mustWork = TRUE)
}

preanalysis_verifier_read_csv <- function(path) {
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    name_repair = "minimal"
  )
}

preanalysis_verifier_assert_schema <- function(data, expected, object) {
  if (anyDuplicated(names(data))) {
    abort_pipeline("%s contains duplicated column names", object)
  }
  if (!identical(names(data), expected)) {
    abort_pipeline(
      "%s schema differs; expected `%s`, observed `%s`",
      object,
      paste(expected, collapse = ","),
      paste(names(data), collapse = ",")
    )
  }
  invisible(data)
}

preanalysis_verifier_assert_nonempty_text <- function(value, object) {
  if (
    !is.character(value) ||
      length(value) == 0L ||
      anyNA(value) ||
      any(!nzchar(trimws(value)))
  ) {
    abort_pipeline("%s must contain non-empty text values", object)
  }
  invisible(value)
}

preanalysis_verifier_assert_no_window_endpoints <- function(data, object) {
  identifier_columns <- intersect(
    c(
      "variable_id",
      "metric_id",
      "canonical_variable",
      "baseline_variable"
    ),
    names(data)
  )
  if (length(identifier_columns) == 0L) {
    abort_pipeline(
      "%s has no identifier column for the endpoint-exclusion audit",
      object
    )
  }
  prohibited <- vapply(
    data[identifier_columns],
    function(value) {
      value <- as.character(value)
      any(
        !is.na(value) &
          grepl(
            preanalysis_verifier_forbidden_window_endpoint_pattern,
            value,
            ignore.case = TRUE,
            perl = TRUE
          )
      )
    },
    logical(1)
  )
  if (any(prohibited)) {
    abort_pipeline(
      paste0(
        "%s contains an M10/L10 onset or offset in identifier column(s): ",
        "%s"
      ),
      object,
      paste(names(prohibited)[prohibited], collapse = ", ")
    )
  }
  invisible(data)
}

preanalysis_verifier_assert_count <- function(
  value,
  object,
  allow_na = FALSE
) {
  if (!is.numeric(value)) {
    abort_pipeline("%s must be numeric", object)
  }
  missing <- is.na(value)
  if (!allow_na && any(missing)) {
    abort_pipeline("%s may not contain missing values", object)
  }
  observed <- value[!missing]
  if (
    any(!is.finite(observed)) ||
      any(observed < 0) ||
      any(observed != floor(observed))
  ) {
    abort_pipeline("%s must contain non-negative integer counts", object)
  }
  invisible(value)
}

preanalysis_verifier_equal <- function(
  observed,
  expected,
  tolerance = 1e-10
) {
  if (
    length(observed) != length(expected) ||
      !identical(is.na(observed), is.na(expected))
  ) {
    return(FALSE)
  }
  retained <- !is.na(observed)
  if (!any(retained)) {
    return(TRUE)
  }
  if (is.numeric(observed) && is.numeric(expected)) {
    return(isTRUE(all.equal(
      as.numeric(observed[retained]),
      as.numeric(expected[retained]),
      tolerance = tolerance,
      check.attributes = FALSE
    )))
  }
  identical(
    as.character(observed[retained]),
    as.character(expected[retained])
  )
}

preanalysis_verifier_token <- function(data, columns) {
  do.call(
    paste,
    c(lapply(data[columns], as.character), sep = "\034")
  )
}

preanalysis_verifier_key_token <- function(data) {
  preanalysis_verifier_token(
    data,
    preanalysis_verifier_variable_key
  )
}

preanalysis_verifier_series_token <- function(data) {
  preanalysis_verifier_token(
    data,
    c(preanalysis_verifier_variable_key, "series")
  )
}

preanalysis_verifier_assert_exact_keys <- function(
  observed,
  expected,
  columns,
  object
) {
  assert_unique_key(observed, columns, object = object)
  assert_unique_key(
    expected,
    columns,
    object = paste0(object, " expected rows")
  )
  observed_token <- preanalysis_verifier_token(observed, columns)
  expected_token <- preanalysis_verifier_token(expected, columns)
  if (
    nrow(observed) != nrow(expected) ||
      !setequal(observed_token, expected_token)
  ) {
    abort_pipeline("%s does not contain the exact required row keys", object)
  }
  match(observed_token, expected_token)
}

preanalysis_verifier_normalized_names <- function(data) {
  tolower(gsub("[^a-z0-9]+", "_", names(data)))
}

preanalysis_verifier_participant_pattern <- function() {
  paste0(
    "(^|[^A-Za-z0-9])",
    "(BAUA|FUSPCEU|IZTECH|KNUST|MPI|RISE|THUAS|TUM|UCR)_S[0-9]+",
    "([^A-Za-z0-9]|$)"
  )
}

preanalysis_verifier_assert_privacy <- function(data, object) {
  normalized <- preanalysis_verifier_normalized_names(data)
  forbidden <- names(data)[
    normalized %in%
      c(
        "id",
        "participant",
        "participant_id",
        "participant_identifier",
        "subject",
        "subject_id",
        "subject_identifier",
        "record_id",
        "person_id",
        "comments",
        "comments_english",
        "comment",
        "activity_desc",
        "activity_desc_english",
        "free_text",
        "participant_free_text",
        "response_text",
        "verbatim_response",
        "type_english"
      ) |
      grepl(
        "(^|_)(participant|subject|person)_?(identifier|id)($|_)",
        normalized
      ) |
      grepl(
        "(^|_)(free_?text|verbatim_?response|activity_?desc)($|_)",
        normalized
      )
  ]
  if (length(forbidden) > 0L) {
    abort_pipeline(
      "%s exposes participant identifiers or free-text columns: %s",
      object,
      paste(forbidden, collapse = ", ")
    )
  }
  character_columns <- names(data)[vapply(data, is.character, logical(1))]
  exposed <- character()
  for (column in character_columns) {
    value <- data[[column]]
    value <- value[!is.na(value)]
    if (
      length(value) > 0L &&
        any(grepl(
          preanalysis_verifier_participant_pattern(),
          value,
          perl = TRUE
        ))
    ) {
      exposed <- c(exposed, column)
    }
  }
  if (length(exposed) > 0L) {
    abort_pipeline(
      "%s contains participant-like identifier values in: %s",
      object,
      paste(unique(exposed), collapse = ", ")
    )
  }
  invisible(data)
}

preanalysis_verifier_assert_no_inference <- function(data, object) {
  normalized <- preanalysis_verifier_normalized_names(data)
  inferential_pattern <- paste0(
    "(^|_)",
    "(",
    "p_?value|pvalue|p_?val|p_?adj|adjusted_?p|",
    "q_?value|qvalue|test_?statistic|test_?method|test_?result|",
    "null_?hypothesis|alternative_?hypothesis|",
    "significance|significant|confidence_?interval|ci_?lower|ci_?upper",
    ")",
    "($|_)"
  )
  forbidden <- names(data)[
    normalized == "p" |
      grepl(inferential_pattern, normalized, perl = TRUE)
  ]
  if (length(forbidden) > 0L) {
    abort_pipeline(
      "%s contains inferential p-test or confidence-interval columns: %s",
      object,
      paste(forbidden, collapse = ", ")
    )
  }
  invisible(data)
}

preanalysis_verifier_png_dimensions <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  header <- readBin(connection, what = "raw", n = 24L)
  signature <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
  if (
    length(header) != 24L ||
      !identical(header[seq_len(8L)], signature) ||
      !identical(rawToChar(header[13:16]), "IHDR")
  ) {
    abort_pipeline("PNG artifact has an invalid header: %s", path)
  }
  raw_integer <- function(value) {
    sum(as.integer(value) * 256^(rev(seq_along(value)) - 1L))
  }
  c(
    width_px = raw_integer(header[17:20]),
    height_px = raw_integer(header[21:24])
  )
}

preanalysis_verifier_verify_manifest <- function(layout) {
  expected_paths <- preanalysis_verifier_output_paths(
    layout$output_root
  )
  expected_ids <- names(expected_paths)
  expected_types <- c(
    rep("csv", length(preanalysis_verifier_csv_ids)),
    rep("png", length(preanalysis_verifier_png_ids)),
    rep("md", length(preanalysis_verifier_markdown_ids))
  )
  manifest <- preanalysis_verifier_read_csv(layout$manifest_path)
  preanalysis_verifier_assert_schema(
    manifest,
    c(
      "artifact_id",
      "artifact_type",
      "path",
      "sha256",
      "bytes",
      "rows",
      "columns",
      "producer",
      "r_version",
      "status"
    ),
    "pre-analysis comparison artifact manifest"
  )
  assert_unique_key(
    manifest,
    "artifact_id",
    object = "pre-analysis comparison artifact manifest"
  )
  assert_unique_key(
    manifest,
    "path",
    object = "pre-analysis comparison artifact manifest"
  )
  if (
    !identical(as.character(manifest$artifact_id), expected_ids) ||
      !identical(as.character(manifest$artifact_type), expected_types)
  ) {
    abort_pipeline(
      "Pre-analysis comparison manifest has a non-exact artifact contract"
    )
  }
  if (
    anyNA(manifest$producer) ||
      any(
        manifest$producer != "scripts/pipeline/build_preanalysis_comparison.R"
      ) ||
      anyNA(manifest$r_version) ||
      any(manifest$r_version != "4.6.1") ||
      anyNA(manifest$status) ||
      any(manifest$status != "PASS")
  ) {
    abort_pipeline(
      "Pre-analysis comparison manifest producer/runtime/status is invalid"
    )
  }
  preanalysis_verifier_assert_count(
    manifest$bytes,
    "pre-analysis comparison manifest `bytes`"
  )
  if (
    any(manifest$bytes < 1L) ||
      anyNA(manifest$sha256) ||
      any(!grepl("^[0-9a-f]{64}$", manifest$sha256))
  ) {
    abort_pipeline(
      "Pre-analysis comparison manifest has invalid byte/hash metadata"
    )
  }

  resolved <- vapply(
    manifest$path,
    preanalysis_verifier_resolve_path,
    character(1),
    root = layout$artifact_base
  )
  expected_normalized <- vapply(
    expected_paths,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  if (!identical(unname(resolved), unname(expected_normalized))) {
    abort_pipeline(
      "Pre-analysis comparison manifest paths differ from declared outputs"
    )
  }

  directory_entries <- list.files(
    layout$output_root,
    all.files = FALSE,
    full.names = TRUE,
    recursive = FALSE,
    include.dirs = TRUE
  )
  directory_entries <- vapply(
    directory_entries,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  if (!setequal(directory_entries, expected_normalized)) {
    abort_pipeline(
      "Pre-analysis comparison output directory has a non-exact file set"
    )
  }

  observed_hash <- unname(vapply(
    resolved,
    artifact_sha256,
    character(1)
  ))
  observed_bytes <- as.numeric(unname(file.info(resolved)$size))
  if (
    !identical(observed_hash, as.character(manifest$sha256)) ||
      !identical(observed_bytes, as.numeric(manifest$bytes))
  ) {
    abort_pipeline(
      "Pre-analysis comparison manifest hashes or byte counts are stale"
    )
  }

  csv <- vector("list", length(preanalysis_verifier_csv_ids))
  names(csv) <- preanalysis_verifier_csv_ids
  for (artifact_id in preanalysis_verifier_csv_ids) {
    row <- match(artifact_id, manifest$artifact_id)
    data <- preanalysis_verifier_read_csv(resolved[[row]])
    if (
      is.na(manifest$rows[[row]]) ||
        is.na(manifest$columns[[row]]) ||
        manifest$rows[[row]] != nrow(data) ||
        manifest$columns[[row]] != ncol(data)
    ) {
      abort_pipeline("Manifest dimensions differ for `%s`", artifact_id)
    }
    csv[[artifact_id]] <- data
  }

  expected_png_dimensions <- list(
    numeric_distribution_overview = c(
      width_px = 2520,
      height_px = 3240
    ),
    categorical_distribution_overview = c(
      width_px = 2520,
      height_px = 3600
    )
  )
  png_dimensions <- list()
  for (artifact_id in preanalysis_verifier_png_ids) {
    row <- match(artifact_id, manifest$artifact_id)
    if (
      !is.na(manifest$rows[[row]]) ||
        !is.na(manifest$columns[[row]])
    ) {
      abort_pipeline(
        "PNG manifest rows/columns must be missing for `%s`",
        artifact_id
      )
    }
    dimensions <- preanalysis_verifier_png_dimensions(resolved[[row]])
    if (
      !identical(
        unname(dimensions),
        unname(expected_png_dimensions[[artifact_id]])
      )
    ) {
      abort_pipeline("PNG dimensions differ for `%s`", artifact_id)
    }
    png_dimensions[[artifact_id]] <- dimensions
  }
  audit_row <- match("audit_report", manifest$artifact_id)
  if (
    !is.na(manifest$rows[[audit_row]]) ||
      !is.na(manifest$columns[[audit_row]])
  ) {
    abort_pipeline("Markdown manifest rows/columns must be missing")
  }

  list(
    manifest = manifest,
    resolved_paths = stats::setNames(resolved, manifest$artifact_id),
    csv = csv,
    png_dimensions = png_dimensions
  )
}

preanalysis_verifier_relative_path <- function(path, root) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  if (startsWith(path, prefix)) {
    substring(path, nchar(prefix) + 1L)
  } else {
    path
  }
}

preanalysis_verifier_file_dimensions <- function(path) {
  extension <- tolower(tools::file_ext(path))
  object <- if (extension == "csv") {
    preanalysis_verifier_read_csv(path)
  } else if (extension == "rds") {
    readRDS(path)
  } else if (extension == "rdata") {
    environment <- new.env(parent = baseenv())
    loaded <- load(path, envir = environment)
    if (length(loaded) != 1L) {
      abort_pipeline("RData input must contain exactly one object: %s", path)
    }
    environment[[loaded[[1L]]]]
  } else {
    abort_pipeline("Unsupported dimension-bearing input: %s", path)
  }
  if (!is.data.frame(object)) {
    abort_pipeline("Input is not one data frame: %s", path)
  }
  c(rows = nrow(object), columns = ncol(object))
}

preanalysis_verifier_expected_inputs <- function(root) {
  placement <- c("glasses", "chest")
  manifest_path <- c(
    "audit/baseline/data_artifact_hashes.csv",
    "artifacts/12_manifests/metric_artifacts.csv",
    "artifacts/12_manifests/model_input_normalization.csv",
    "artifacts/12_manifests/base_model_data_artifacts.csv"
  )
  base_stem <- c(
    paste0("metrics_", placement, "_participant_enriched.rds"),
    paste0("metrics_", placement, "_participant_day_enriched.rds"),
    paste0("metrics_", placement, "_30_minute_context.rds"),
    paste0("metrics_", placement, "_one_hour_context.rds")
  )
  data.frame(
    input_id = c(
      "baseline_manifest",
      "metrics_manifest",
      "normalization_manifest",
      "base_manifest",
      "metric_display_registry",
      paste0("baseline_metrics_", placement),
      paste0("metric_values_", placement),
      paste0("base_", placement, "_participant"),
      paste0("base_", placement, "_participant_day"),
      paste0("base_", placement, "_30_minute"),
      paste0("base_", placement, "_one_hour"),
      "normalized_exercise_diary",
      "normalized_light_diary",
      "normalized_sleep_diary"
    ),
    input_kind = c(
      rep("manifest_csv", 4L),
      "manuscript_display_registry_csv",
      rep("frozen_baseline_rdata", 2L),
      rep("canonical_metric_csv", 2L),
      rep("canonical_base_rds", 8L),
      rep("canonical_normalized_rds", 3L)
    ),
    path = c(
      manifest_path,
      "config/metric_display_registry.csv",
      file.path("data", paste0("metrics_", placement, ".RData")),
      file.path(
        "artifacts",
        "05_metrics",
        paste0("metrics_", placement, "_values_long.csv")
      ),
      file.path("artifacts", "06_model_data", "base", base_stem),
      file.path(
        "artifacts",
        "06_model_data",
        "normalized_inputs",
        c(
          "exercisediary.rds",
          "lightexposurediary.rds",
          "sleepdiaries.rds"
        )
      )
    ),
    verification_source = c(
      rep("self_hash", 4L),
      "validated_display_registry_contract",
      rep(manifest_path[[1L]], 2L),
      rep(manifest_path[[2L]], 2L),
      rep(manifest_path[[4L]], 8L),
      rep(manifest_path[[3L]], 3L)
    ),
    stringsAsFactors = FALSE
  )
}

preanalysis_verifier_manifest_row_by_path <- function(
  manifest,
  path,
  root,
  object
) {
  assert_columns(manifest, "path", object = object)
  resolved <- vapply(
    manifest$path,
    preanalysis_verifier_resolve_path,
    character(1),
    root = root
  )
  target <- normalizePath(path, winslash = "/", mustWork = TRUE)
  index <- which(resolved == target)
  if (length(index) != 1L) {
    abort_pipeline("%s must identify input exactly once: %s", object, path)
  }
  manifest[index, , drop = FALSE]
}

preanalysis_verifier_verify_input_provenance <- function(
  provenance,
  layout,
  expected_normalization_manifest_sha256,
  expected_base_manifest_sha256
) {
  schema <- c(
    "input_id",
    "input_kind",
    "path",
    "sha256",
    "expected_sha256",
    "bytes",
    "rows",
    "columns",
    "verification_source",
    "r_version",
    "status"
  )
  preanalysis_verifier_assert_schema(
    provenance,
    schema,
    "pre-analysis comparison input provenance"
  )
  expected <- preanalysis_verifier_expected_inputs(layout$root)
  if (
    !identical(as.character(provenance$input_id), expected$input_id) ||
      !identical(as.character(provenance$input_kind), expected$input_kind)
  ) {
    abort_pipeline("Input provenance has a non-exact input ID/kind set")
  }
  assert_unique_key(
    provenance,
    "input_id",
    object = "pre-analysis comparison input provenance"
  )
  assert_unique_key(
    provenance,
    "path",
    object = "pre-analysis comparison input provenance"
  )
  resolved <- vapply(
    provenance$path,
    preanalysis_verifier_resolve_path,
    character(1),
    root = layout$root
  )
  expected_resolved <- vapply(
    file.path(layout$root, expected$path),
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  if (
    !identical(unname(resolved), unname(expected_resolved)) ||
      !identical(
        as.character(provenance$verification_source),
        expected$verification_source
      )
  ) {
    abort_pipeline("Input provenance paths or verification sources differ")
  }
  if (
    anyNA(provenance$sha256) ||
      any(!grepl("^[0-9a-f]{64}$", provenance$sha256)) ||
      !identical(
        as.character(provenance$sha256),
        as.character(provenance$expected_sha256)
      ) ||
      anyNA(provenance$r_version) ||
      any(provenance$r_version != "4.6.1") ||
      anyNA(provenance$status) ||
      any(provenance$status != "PASS")
  ) {
    abort_pipeline("Input provenance hash/runtime/status contract failed")
  }
  preanalysis_verifier_assert_count(
    provenance$bytes,
    "input provenance `bytes`"
  )
  preanalysis_verifier_assert_count(
    provenance$rows,
    "input provenance `rows`"
  )
  preanalysis_verifier_assert_count(
    provenance$columns,
    "input provenance `columns`"
  )
  observed_hash <- unname(vapply(
    resolved,
    artifact_sha256,
    character(1)
  ))
  observed_bytes <- as.numeric(unname(file.info(resolved)$size))
  if (
    !identical(observed_hash, as.character(provenance$sha256)) ||
      !identical(observed_bytes, as.numeric(provenance$bytes))
  ) {
    abort_pipeline("Pre-analysis comparison input provenance is stale")
  }
  for (index in seq_along(resolved)) {
    dimensions <- preanalysis_verifier_file_dimensions(resolved[[index]])
    if (
      dimensions[["rows"]] != provenance$rows[[index]] ||
        dimensions[["columns"]] != provenance$columns[[index]]
    ) {
      abort_pipeline(
        "Input provenance dimensions differ for `%s`",
        provenance$input_id[[index]]
      )
    }
  }

  registry_index <- match(
    "metric_display_registry",
    provenance$input_id
  )
  display_registry <- preanalysis_verifier_read_csv(
    resolved[[registry_index]]
  )
  validate_metric_display_registry(display_registry)
  if (nrow(display_registry) != 22L) {
    abort_pipeline(
      "Metric display registry must contain exactly 22 metrics"
    )
  }
  preanalysis_verifier_assert_no_window_endpoints(
    display_registry,
    "metric display registry"
  )

  manifests <- stats::setNames(
    lapply(
      c(
        baseline = "baseline_manifest",
        metrics = "metrics_manifest",
        normalization = "normalization_manifest",
        base = "base_manifest"
      ),
      function(input_id) {
        preanalysis_verifier_read_csv(
          resolved[[match(input_id, provenance$input_id)]]
        )
      }
    ),
    c("baseline", "metrics", "normalization", "base")
  )
  normalization_hash <- observed_hash[[
    match("normalization_manifest", provenance$input_id)
  ]]
  base_hash <- observed_hash[[
    match("base_manifest", provenance$input_id)
  ]]
  if (
    !identical(
      normalization_hash,
      expected_normalization_manifest_sha256
    ) ||
      !identical(base_hash, expected_base_manifest_sha256)
  ) {
    abort_pipeline(
      "Preparation 06 manifest hashes differ from approved exact hashes"
    )
  }

  assert_columns(
    manifests$base,
    c(
      "path",
      "sha256",
      "r_version",
      "status",
      "normalization_manifest_sha256",
      "input_bundle_sha256"
    ),
    object = "base-model artifact manifest"
  )
  if (
    nrow(manifests$base) == 0L ||
      anyNA(manifests$base$status) ||
      any(manifests$base$status != "PASS") ||
      anyNA(manifests$base$r_version) ||
      any(manifests$base$r_version != "4.6.1") ||
      anyNA(manifests$base$normalization_manifest_sha256) ||
      any(
        manifests$base$normalization_manifest_sha256 != normalization_hash
      ) ||
      length(unique(manifests$base$input_bundle_sha256)) != 1L ||
      is.na(unique(manifests$base$input_bundle_sha256)) ||
      !grepl(
        "^[0-9a-f]{64}$",
        unique(manifests$base$input_bundle_sha256)
      )
  ) {
    abort_pipeline(
      "Base-model manifest is not a stable PASS over normalization"
    )
  }

  for (input_id in paste0("baseline_metrics_", c("glasses", "chest"))) {
    index <- match(input_id, provenance$input_id)
    row <- preanalysis_verifier_manifest_row_by_path(
      manifests$baseline,
      resolved[[index]],
      layout$root,
      "frozen baseline ledger"
    )
    assert_columns(
      row,
      c("sha256", "bytes", "baseline_status"),
      object = "frozen baseline ledger"
    )
    if (
      row$sha256[[1L]] != provenance$sha256[[index]] ||
        as.numeric(row$bytes[[1L]]) != provenance$bytes[[index]] ||
        row$baseline_status[[1L]] != "tracked-baseline"
    ) {
      abort_pipeline("Frozen baseline provenance failed for `%s`", input_id)
    }
  }

  for (placement in c("glasses", "chest")) {
    input_id <- paste0("metric_values_", placement)
    index <- match(input_id, provenance$input_id)
    row <- preanalysis_verifier_manifest_row_by_path(
      manifests$metrics,
      resolved[[index]],
      layout$root,
      "canonical metric manifest"
    )
    assert_columns(
      row,
      c(
        "sha256",
        "r_version",
        "artifact_type",
        "placement"
      ),
      object = "canonical metric manifest"
    )
    if (
      row$sha256[[1L]] != provenance$sha256[[index]] ||
        row$r_version[[1L]] != "4.6.1" ||
        row$artifact_type[[1L]] != "long_metric_values" ||
        row$placement[[1L]] != placement
    ) {
      abort_pipeline(
        "Canonical metric provenance failed for `%s`",
        placement
      )
    }
  }
  base_ids <- provenance$input_id[
    provenance$input_kind == "canonical_base_rds"
  ]
  for (input_id in base_ids) {
    index <- match(input_id, provenance$input_id)
    row <- preanalysis_verifier_manifest_row_by_path(
      manifests$base,
      resolved[[index]],
      layout$root,
      "base-model artifact manifest"
    )
    if (
      row$sha256[[1L]] != provenance$sha256[[index]] ||
        row$r_version[[1L]] != "4.6.1" ||
        row$status[[1L]] != "PASS"
    ) {
      abort_pipeline("Base-model provenance failed for `%s`", input_id)
    }
  }

  modality <- c(
    normalized_exercise_diary = "exercisediary",
    normalized_light_diary = "lightexposurediary",
    normalized_sleep_diary = "sleepdiaries"
  )
  assert_columns(
    manifests$normalization,
    c(
      "modality",
      "artifact_type",
      "path",
      "sha256",
      "r_version"
    ),
    object = "model-input normalization manifest"
  )
  for (input_id in names(modality)) {
    index <- match(input_id, provenance$input_id)
    rows <- which(
      manifests$normalization$modality == modality[[input_id]] &
        manifests$normalization$artifact_type == "rds"
    )
    if (length(rows) != 1L) {
      abort_pipeline(
        "Normalization manifest must identify `%s` exactly once",
        input_id
      )
    }
    row <- manifests$normalization[rows, , drop = FALSE]
    normalized_path <- preanalysis_verifier_resolve_path(
      row$path[[1L]],
      layout$root
    )
    if (
      normalized_path != resolved[[index]] ||
        row$sha256[[1L]] != provenance$sha256[[index]] ||
        row$r_version[[1L]] != "4.6.1"
    ) {
      abort_pipeline(
        "Normalized input provenance failed for `%s`",
        input_id
      )
    }
  }

  list(
    resolved_paths = resolved,
    metric_display_registry = display_registry,
    metric_display_registry_sha256 = observed_hash[[registry_index]],
    normalization_manifest_sha256 = normalization_hash,
    base_manifest_sha256 = base_hash,
    base_input_bundle_sha256 = unique(
      manifests$base$input_bundle_sha256
    )[[1L]],
    preparation06_hashes_match = TRUE
  )
}

preanalysis_verifier_verify_crosswalk <- function(
  crosswalk,
  display_registry
) {
  preanalysis_verifier_assert_schema(
    crosswalk,
    preanalysis_verifier_crosswalk_schema,
    "pre-analysis comparison variable crosswalk"
  )
  assert_unique_key(
    crosswalk,
    "variable_id",
    object = "pre-analysis comparison variable crosswalk"
  )
  assert_unique_key(
    crosswalk,
    "variable_order",
    object = "pre-analysis comparison variable crosswalk"
  )
  if (nrow(crosswalk) != 72L) {
    abort_pipeline("Variable crosswalk must contain exactly 72 variables")
  }
  preanalysis_verifier_assert_count(
    crosswalk$variable_order,
    "crosswalk `variable_order`"
  )
  for (column in c(
    "variable_id",
    "manuscript_name",
    "manuscript_category",
    "analytical_role",
    "variant_label",
    "domain",
    "analysis_unit",
    "value_type",
    "canonical_source",
    "canonical_variable",
    "native_unit",
    "comparison_unit",
    "display_unit",
    "canonical_transform",
    "baseline_transform",
    "difference_method",
    "technical_estimand",
    "comparison_status",
    "axis_geometry",
    "linear_summary_interpretation",
    "mapping_scope",
    "semantic_comparability",
    "comparability_class",
    "comparability_note"
  )) {
    preanalysis_verifier_assert_nonempty_text(
      as.character(crosswalk[[column]]),
      paste0("crosswalk `", column, "`")
    )
  }
  light_metric <- crosswalk$domain == "light_metric"
  registry_index <- match(
    crosswalk$metric_id[light_metric],
    display_registry$metric_id
  )
  display_columns <- c(
    "manuscript_name",
    "abbreviation",
    "manuscript_category",
    "display_unit",
    "analytical_role",
    "variant_label"
  )
  expected_display_analysis_unit <- unname(c(
    participant = "participant",
    participant_day = "participant-day",
    `30_minute` = "participant-30-minute",
    one_hour = "participant-hour"
  )[crosswalk$analysis_unit[light_metric]])
  if (
    sum(light_metric) != 22L ||
      anyNA(crosswalk$metric_id[light_metric]) ||
      anyDuplicated(crosswalk$metric_id[light_metric]) ||
      any(!is.na(crosswalk$metric_id[!light_metric])) ||
      !setequal(
        crosswalk$metric_id[light_metric],
        display_registry$metric_id
      ) ||
      anyNA(registry_index) ||
      anyNA(expected_display_analysis_unit) ||
      !identical(
        display_registry$analysis_unit[registry_index],
        expected_display_analysis_unit
      ) ||
      any(vapply(
        display_columns,
        function(column) {
          !preanalysis_verifier_equal(
            crosswalk[[column]][light_metric],
            display_registry[[column]][registry_index]
          )
        },
        logical(1)
      ))
  ) {
    abort_pipeline(
      "Crosswalk light metrics differ from the metric display registry"
    )
  }
  if (
    any(grepl(
      paste0(
        "support[- ]aware|support[- ]corrected|time[- ]sensitive|",
        "ratio of integrals"
      ),
      paste(
        crosswalk$manuscript_name[light_metric],
        crosswalk$manuscript_category[light_metric]
      ),
      ignore.case = TRUE,
      perl = TRUE
    ))
  ) {
    abort_pipeline(
      "Implementation jargon entered a manuscript-facing crosswalk label"
    )
  }
  if (
    any(
      !crosswalk$analysis_unit %in%
        c(
          "participant",
          "participant_day",
          "30_minute",
          "one_hour",
          "diary_interval"
        )
    ) ||
      any(!crosswalk$value_type %in% c("numeric", "categorical")) ||
      any(!crosswalk$axis_geometry %in% c("linear", "categorical")) ||
      any(
        !crosswalk$comparison_status %in%
          c(
            "applicable_field_key_mapping",
            "not_applicable_no_field_key_mapping"
          )
      ) ||
      any(
        !crosswalk$comparability_class %in%
          c(
            "exact_field_key_and_scale_mapping",
            paste0(
              "same_nominal_construct_changed_computation_admissibility_",
              "descriptive_only"
            ),
            "changed_estimand_or_no_direct_mapping_no_numerical_comparison"
          )
      ) ||
      !is.logical(crosswalk$figure_priority) ||
      anyNA(crosswalk$figure_priority)
  ) {
    abort_pipeline(
      "Variable crosswalk has invalid unit, type, status, or figure flag"
    )
  }
  applicable <- crosswalk$comparison_status == "applicable_field_key_mapping"
  not_applicable <- !applicable
  if (
    any(is.na(crosswalk$baseline_source[applicable])) ||
      any(is.na(crosswalk$baseline_variable[applicable])) ||
      any(!is.na(crosswalk$non_applicable_reason[applicable])) ||
      any(!is.na(crosswalk$baseline_source[not_applicable])) ||
      any(!is.na(crosswalk$baseline_variable[not_applicable])) ||
      anyNA(crosswalk$non_applicable_reason[not_applicable]) ||
      any(
        !nzchar(trimws(
          crosswalk$non_applicable_reason[not_applicable]
        ))
      ) ||
      any(
        crosswalk$semantic_comparability[not_applicable] != "not_applicable"
      ) ||
      any(
        crosswalk$comparability_class[not_applicable] !=
          paste0(
            "changed_estimand_or_no_direct_mapping_",
            "no_numerical_comparison"
          )
      )
  ) {
    abort_pipeline(
      "Crosswalk exact-mapping status disagrees with baseline metadata"
    )
  }
  if (
    any(
      crosswalk$value_type == "categorical" &
        crosswalk$difference_method != "categorical_exact_agreement"
    ) ||
      any(
        crosswalk$value_type == "numeric" &
          crosswalk$difference_method != "linear_current_minus_baseline"
      )
  ) {
    abort_pipeline("Crosswalk difference methods are invalid")
  }
  expected_geometry <- ifelse(
    crosswalk$value_type == "categorical",
    "categorical",
    "linear"
  )
  if (
    any(crosswalk$axis_geometry != expected_geometry) ||
      any(
        crosswalk$axis_geometry == "categorical" &
          crosswalk$linear_summary_interpretation !=
            "Not applicable to categorical level distributions."
      )
  ) {
    abort_pipeline("Crosswalk axis-geometry interpretation is invalid")
  }
  centered_clock_ids <- "light_l10_midpoint"
  ordinary_clock_ids <- c(
    "light_first_timing_above_250",
    "light_last_timing_above_250",
    "light_mean_timing_above_250",
    "light_m10_midpoint",
    "hour_clock_hour"
  )
  all_clock_ids <- c(centered_clock_ids, ordinary_clock_ids)
  if (any(!all_clock_ids %in% crosswalk$variable_id)) {
    abort_pipeline("Crosswalk omits a declared linear clock variable")
  }
  centered_index <- match(centered_clock_ids, crosswalk$variable_id)
  ordinary_index <- match(ordinary_clock_ids, crosswalk$variable_id)
  hour_index <- match("hour_clock_hour", crosswalk$variable_id)
  ordinary_default <- setdiff(ordinary_index, hour_index)
  if (
    any(
      crosswalk$canonical_transform[centered_index] !=
        "clock_minute_to_centered_decimal_hour"
    ) ||
      any(crosswalk$baseline_transform[centered_index] != "identity") ||
      any(
        crosswalk$comparison_unit[centered_index] != "centered_decimal_hour"
      ) ||
      any(
        crosswalk$canonical_transform[ordinary_default] !=
          "clock_minute_to_decimal_hour"
      ) ||
      any(crosswalk$baseline_transform[ordinary_default] != "identity") ||
      any(
        crosswalk$comparison_unit[ordinary_default] != "decimal_hour"
      ) ||
      crosswalk$canonical_transform[[hour_index]] != "identity" ||
      crosswalk$baseline_transform[[hour_index]] != "identity" ||
      crosswalk$comparison_unit[[hour_index]] != "clock_hour"
  ) {
    abort_pipeline("Declared linear clock transformations are invalid")
  }
  if (
    any(
      !grepl(
        "[-12, 12)",
        crosswalk$linear_summary_interpretation[centered_index],
        fixed = TRUE
      )
    ) ||
      !grepl(
        "post-midnight",
        crosswalk$linear_summary_interpretation[
          match("participant_msf_sc", crosswalk$variable_id)
        ],
        fixed = TRUE
      )
  ) {
    abort_pipeline("Linear clock-axis explanations are incomplete")
  }
  light_applicable <- applicable & crosswalk$domain == "light_metric"
  nonlight_applicable <- applicable & !light_applicable
  if (
    any(
      crosswalk$comparability_class[light_applicable] !=
        paste0(
          "same_nominal_construct_changed_computation_admissibility_",
          "descriptive_only"
        )
    ) ||
      any(
        crosswalk$comparability_class[nonlight_applicable] !=
          "exact_field_key_and_scale_mapping"
      ) ||
      any(
        crosswalk$semantic_comparability[nonlight_applicable] !=
          "same_declared_field_and_scale"
      ) ||
      any(
        crosswalk$semantic_comparability[light_applicable] !=
          paste0(
            "same_named_or_directly_corresponding_construct_",
            "with_repaired_implementation"
          )
      )
  ) {
    abort_pipeline("Crosswalk comparability classification is invalid")
  }
  light_diary <- crosswalk$canonical_source == "light_diary"
  required_quality <- c(
    "hour_interval_analysis_eligible",
    "hour_interval_quarantined",
    "hour_interval_issue_code",
    "hour_diary_date_missing"
  )
  if (
    sum(light_diary) != 13L ||
      any(crosswalk$analysis_unit[light_diary] != "diary_interval") ||
      any(crosswalk$domain[light_diary] != "diary_interval_predictor") ||
      any(!required_quality %in% crosswalk$variable_id[light_diary])
  ) {
    abort_pipeline("Light-diary variables must use diary-interval keys")
  }
  crosswalk
}

preanalysis_verifier_effective_crosswalk <- function(crosswalk) {
  diary_source <- c(
    "exercise_diary",
    "sleep_diary",
    "light_diary"
  )
  result <- vector("list", nrow(crosswalk))
  for (index in seq_len(nrow(crosswalk))) {
    placement <- if (crosswalk$canonical_source[[index]] %in% diary_source) {
      "all"
    } else {
      c("glasses", "chest")
    }
    rows <- crosswalk[rep(index, length(placement)), , drop = FALSE]
    rows$placement <- placement
    result[[index]] <- rows
  }
  result <- do.call(rbind, result)
  rownames(result) <- NULL
  if (nrow(result) != 120L) {
    abort_pipeline("Effective crosswalk must contain exactly 120 rows")
  }
  assert_unique_key(
    result,
    preanalysis_verifier_variable_key,
    object = "effective pre-analysis crosswalk"
  )
  result
}

preanalysis_verifier_expected_series <- function(effective) {
  canonical <- effective[preanalysis_verifier_variable_key]
  canonical$series <- "canonical"
  baseline <- effective[
    effective$comparison_status == "applicable_field_key_mapping",
    preanalysis_verifier_variable_key,
    drop = FALSE
  ]
  baseline$series <- "baseline"
  rbind(canonical, baseline)
}

preanalysis_verifier_verify_series_summary <- function(
  series,
  crosswalk
) {
  preanalysis_verifier_assert_schema(
    series,
    preanalysis_verifier_series_schema,
    "pre-analysis series summary"
  )
  effective <- preanalysis_verifier_effective_crosswalk(crosswalk)
  expected <- preanalysis_verifier_expected_series(effective)
  if (nrow(series) != 172L) {
    abort_pipeline("Series summary must contain exactly 172 rows")
  }
  preanalysis_verifier_assert_exact_keys(
    series,
    expected,
    c(preanalysis_verifier_variable_key, "series"),
    "pre-analysis series summary"
  )
  crosswalk_index <- match(series$variable_id, crosswalk$variable_id)
  if (
    anyNA(crosswalk_index) ||
      !preanalysis_verifier_equal(
        series$analysis_unit,
        crosswalk$analysis_unit[crosswalk_index]
      ) ||
      !preanalysis_verifier_equal(
        series$domain,
        crosswalk$domain[crosswalk_index]
      ) ||
      !preanalysis_verifier_equal(
        series$value_type,
        crosswalk$value_type[crosswalk_index]
      ) ||
      !preanalysis_verifier_equal(
        series$comparison_unit,
        crosswalk$comparison_unit[crosswalk_index]
      ) ||
      !preanalysis_verifier_equal(
        series$axis_geometry,
        crosswalk$axis_geometry[crosswalk_index]
      ) ||
      !preanalysis_verifier_equal(
        series$linear_summary_interpretation,
        crosswalk$linear_summary_interpretation[crosswalk_index]
      ) ||
      any(!series$series %in% c("baseline", "canonical"))
  ) {
    abort_pipeline("Series summary descriptors differ from crosswalk")
  }

  count_columns <- c(
    "n_observations",
    "n_estimable",
    "n_nonestimable",
    "n_observed",
    "n_missing",
    "n_estimable_missing",
    "n_participants",
    "n_participants_observed"
  )
  for (column in count_columns) {
    preanalysis_verifier_assert_count(
      series[[column]],
      paste0("series summary `", column, "`")
    )
  }
  preanalysis_verifier_assert_count(
    series$n_nonfinite,
    "series summary `n_nonfinite`",
    allow_na = TRUE
  )
  for (column in c(
    "n_participant_days",
    "n_participant_days_observed"
  )) {
    preanalysis_verifier_assert_count(
      series[[column]],
      paste0("series summary `", column, "`"),
      allow_na = TRUE
    )
  }
  if (
    any(
      series$n_estimable + series$n_nonestimable != series$n_observations
    ) ||
      any(series$n_missing > series$n_observations) ||
      any(series$n_estimable_missing > series$n_estimable) ||
      any(series$n_participants_observed > series$n_participants)
  ) {
    abort_pipeline("Series summary observation counts do not reconcile")
  }
  participant <- series$analysis_unit == "participant"
  if (
    any(!is.na(series$n_participant_days[participant])) ||
      any(!is.na(series$n_participant_days_observed[participant])) ||
      anyNA(series$n_participant_days[!participant]) ||
      anyNA(series$n_participant_days_observed[!participant]) ||
      any(
        series$n_participant_days_observed[!participant] >
          series$n_participant_days[!participant]
      )
  ) {
    abort_pipeline("Series participant-day counts are invalid")
  }

  numeric <- series$value_type == "numeric"
  categorical <- !numeric
  if (
    anyNA(series$n_nonfinite[numeric]) ||
      any(
        series$n_observed[numeric] +
          series$n_estimable_missing[numeric] +
          series$n_nonfinite[numeric] !=
          series$n_estimable[numeric]
      ) ||
      any(!is.na(series$n_nonfinite[categorical])) ||
      any(
        series$n_observed[categorical] +
          series$n_estimable_missing[categorical] !=
          series$n_estimable[categorical]
      )
  ) {
    abort_pipeline("Series estimability counts do not reconcile")
  }

  numeric_statistics <- c(
    "mean",
    "sd",
    "median",
    "iqr",
    "q025",
    "q25",
    "q75",
    "q975",
    "minimum",
    "maximum",
    "n_zero",
    "zero_rate",
    "nonfinite_rate"
  )
  if (
    any(categorical) &&
      any(
        !is.na(as.matrix(series[
          categorical,
          c(
            numeric_statistics,
            "circular_mean",
            "circular_median",
            "circular_resultant_length",
            "circular_sd_hours"
          )
        ]))
      )
  ) {
    abort_pipeline("Categorical series contain numeric statistics")
  }

  positive <- numeric & series$n_observed > 0L
  empty <- numeric & series$n_observed == 0L
  required_positive <- c(
    "mean",
    "median",
    "iqr",
    "q025",
    "q25",
    "q75",
    "q975",
    "minimum",
    "maximum",
    "n_zero",
    "zero_rate"
  )
  if (
    any(positive) &&
      (anyNA(as.matrix(series[positive, required_positive])) ||
        any(
          !is.finite(as.matrix(
            series[
              positive,
              setdiff(required_positive, "n_zero")
            ]
          ))
        ))
  ) {
    abort_pipeline("Non-empty numeric series have missing statistics")
  }
  if (
    any(empty) &&
      (any(
        !is.na(as.matrix(
          series[
            empty,
            setdiff(numeric_statistics, c("n_zero", "nonfinite_rate"))
          ]
        ))
      ) ||
        any(series$n_zero[empty] != 0L))
  ) {
    abort_pipeline("Empty numeric series have invalid statistics")
  }
  more_than_one <- numeric & series$n_observed > 1L
  one_or_zero <- numeric & series$n_observed <= 1L
  if (
    anyNA(series$sd[more_than_one]) ||
      any(!is.finite(series$sd[more_than_one])) ||
      any(series$sd[more_than_one] < 0) ||
      any(!is.na(series$sd[one_or_zero]))
  ) {
    abort_pipeline("Numeric series SD contract failed")
  }
  if (
    any(
      positive &
        (series$minimum > series$q025 |
          series$q025 > series$q25 |
          series$q25 > series$median |
          series$median > series$q75 |
          series$q75 > series$q975 |
          series$q975 > series$maximum)
    ) ||
      any(
        positive &
          abs(series$iqr - (series$q75 - series$q25)) > 1e-10
      ) ||
      any(series$n_zero[numeric] > series$n_observed[numeric]) ||
      any(
        positive &
          abs(
            series$zero_rate -
              series$n_zero / series$n_observed
          ) >
            1e-10
      ) ||
      any(!is.na(series$zero_rate[empty]))
  ) {
    abort_pipeline("Numeric series distribution statistics are invalid")
  }
  estimable <- numeric & series$n_estimable > 0L
  no_estimable <- numeric & series$n_estimable == 0L
  if (
    anyNA(series$nonfinite_rate[estimable]) ||
      any(
        abs(
          series$nonfinite_rate[estimable] -
            series$n_nonfinite[estimable] /
              series$n_estimable[estimable]
        ) >
          1e-10
      ) ||
      any(!is.na(series$nonfinite_rate[no_estimable]))
  ) {
    abort_pipeline("Numeric non-finite rates do not reconcile")
  }
  circular_fields <- c(
    "circular_mean",
    "circular_median",
    "circular_resultant_length",
    "circular_sd_hours"
  )
  if (any(!is.na(as.matrix(series[circular_fields])))) {
    abort_pipeline(
      "Declared linear axes must leave every circular summary blank"
    )
  }

  diary <- series$analysis_unit == "diary_interval"
  quality_id <- c(
    "hour_interval_analysis_eligible",
    "hour_interval_quarantined",
    "hour_interval_issue_code",
    "hour_diary_date_missing"
  )
  quality <- diary & series$variable_id %in% quality_id
  ordinary_diary <- diary & !quality
  if (
    sum(diary) != 13L ||
      any(series$series[diary] != "canonical") ||
      any(series$placement[diary] != "all") ||
      any(series$n_observations[diary] != 30199L) ||
      any(series$n_estimable[quality] != 30199L) ||
      any(series$n_nonestimable[quality] != 0L) ||
      any(series$n_estimable[ordinary_diary] != 30172L) ||
      any(series$n_nonestimable[ordinary_diary] != 27L)
  ) {
    abort_pipeline(
      "Diary-interval rows do not expose the 27-row quality quarantine"
    )
  }
  series
}

preanalysis_verifier_verify_numeric_quantiles <- function(
  quantiles,
  crosswalk,
  series
) {
  preanalysis_verifier_assert_schema(
    quantiles,
    preanalysis_verifier_quantile_schema,
    "pre-analysis numeric quantiles"
  )
  assert_unique_key(
    quantiles,
    c(
      preanalysis_verifier_variable_key,
      "series",
      "probability"
    ),
    object = "pre-analysis numeric quantiles"
  )
  crosswalk_index <- match(quantiles$variable_id, crosswalk$variable_id)
  if (
    nrow(quantiles) != 1062L ||
      anyNA(crosswalk_index) ||
      any(crosswalk$value_type[crosswalk_index] != "numeric") ||
      any(!quantiles$series %in% c("baseline", "canonical")) ||
      !is.numeric(quantiles$probability) ||
      !is.numeric(quantiles$value)
  ) {
    abort_pipeline("Numeric quantiles have invalid keys or values")
  }
  expected_groups <- series[
    series$value_type == "numeric",
    c(preanalysis_verifier_variable_key, "series"),
    drop = FALSE
  ]
  observed_groups <- unique(quantiles[
    c(preanalysis_verifier_variable_key, "series")
  ])
  preanalysis_verifier_assert_exact_keys(
    observed_groups,
    expected_groups,
    c(preanalysis_verifier_variable_key, "series"),
    "numeric quantile groups"
  )
  preanalysis_verifier_assert_count(
    quantiles$n_finite,
    "numeric quantile `n_finite`"
  )

  group_token <- preanalysis_verifier_series_token(quantiles)
  series_token <- preanalysis_verifier_series_token(series)
  groups <- split(seq_len(nrow(quantiles)), group_token)
  summary_quantiles <- c(
    `0` = "minimum",
    `0.025` = "q025",
    `0.25` = "q25",
    `0.5` = "median",
    `0.75` = "q75",
    `0.975` = "q975",
    `1` = "maximum"
  )
  for (indices in groups) {
    indices <- indices[order(quantiles$probability[indices])]
    if (
      !isTRUE(all.equal(
        quantiles$probability[indices],
        preanalysis_verifier_probabilities,
        tolerance = 0,
        check.attributes = FALSE
      ))
    ) {
      abort_pipeline("Numeric quantile grid differs from contract")
    }
    summary_index <- match(
      group_token[[indices[[1L]]]],
      series_token
    )
    if (is.na(summary_index)) {
      abort_pipeline("Numeric quantiles lack a series summary")
    }
    if (
      any(
        quantiles$n_finite[indices] != series$n_observed[[summary_index]]
      ) ||
        any(
          quantiles$comparison_unit[indices] !=
            series$comparison_unit[[summary_index]]
        ) ||
        any(
          quantiles$axis_geometry[indices] !=
            series$axis_geometry[[summary_index]]
        ) ||
        any(
          quantiles$summary_interpretation[indices] !=
            series$linear_summary_interpretation[[summary_index]]
        )
    ) {
      abort_pipeline("Numeric quantile counts/units do not reconcile")
    }
    value <- quantiles$value[indices]
    if (series$n_observed[[summary_index]] == 0L) {
      if (any(!is.na(value))) {
        abort_pipeline("Empty numeric series must have missing quantiles")
      }
      next
    }
    if (anyNA(value) || any(!is.finite(value)) || any(diff(value) < -1e-10)) {
      abort_pipeline("Numeric quantiles are missing or non-monotone")
    }
    for (probability in names(summary_quantiles)) {
      value_index <- which(
        quantiles$probability[indices] == as.numeric(probability)
      )
      column <- summary_quantiles[[probability]]
      if (
        !preanalysis_verifier_equal(
          value[[value_index]],
          series[[column]][[summary_index]]
        )
      ) {
        abort_pipeline(
          "Numeric quantile `%s` disagrees with series summary",
          probability
        )
      }
    }
  }
  quantiles
}

preanalysis_verifier_verify_categorical_levels <- function(
  levels,
  crosswalk,
  series
) {
  preanalysis_verifier_assert_schema(
    levels,
    preanalysis_verifier_categorical_schema,
    "pre-analysis categorical levels"
  )
  assert_unique_key(
    levels,
    c(
      preanalysis_verifier_variable_key,
      "series",
      "level"
    ),
    object = "pre-analysis categorical levels"
  )
  preanalysis_verifier_assert_nonempty_text(
    as.character(levels$level),
    "categorical level labels"
  )
  preanalysis_verifier_assert_count(
    levels$n,
    "categorical level `n`"
  )
  preanalysis_verifier_assert_count(
    levels$n_participants,
    "categorical level `n_participants`"
  )
  preanalysis_verifier_assert_count(
    levels$n_participant_days,
    "categorical level `n_participant_days`",
    allow_na = TRUE
  )
  crosswalk_index <- match(levels$variable_id, crosswalk$variable_id)
  if (
    nrow(levels) != 239L ||
      anyNA(crosswalk_index) ||
      any(crosswalk$value_type[crosswalk_index] != "categorical") ||
      any(!levels$series %in% c("baseline", "canonical"))
  ) {
    abort_pipeline("Categorical levels have invalid keys or series")
  }
  expected_groups <- series[
    series$value_type == "categorical",
    c(preanalysis_verifier_variable_key, "series"),
    drop = FALSE
  ]
  observed_groups <- unique(levels[
    c(preanalysis_verifier_variable_key, "series")
  ])
  preanalysis_verifier_assert_exact_keys(
    observed_groups,
    expected_groups,
    c(preanalysis_verifier_variable_key, "series"),
    "categorical level groups"
  )
  group_token <- preanalysis_verifier_series_token(levels)
  series_token <- preanalysis_verifier_series_token(series)
  groups <- split(seq_len(nrow(levels)), group_token)
  for (indices in groups) {
    summary_index <- match(group_token[[indices[[1L]]]], series_token)
    if (is.na(summary_index)) {
      abort_pipeline("Categorical levels lack a series summary")
    }
    denominator <- series$n_estimable[[summary_index]]
    participant_unit <- series$analysis_unit[[summary_index]] == "participant"
    if (
      any(
        levels$n_participants[indices] > series$n_participants[[summary_index]]
      ) ||
        (participant_unit &&
          any(!is.na(levels$n_participant_days[indices]))) ||
        (!participant_unit &&
          (anyNA(levels$n_participant_days[indices]) ||
            any(
              levels$n_participant_days[indices] >
                series$n_participant_days[[summary_index]]
            )))
    ) {
      abort_pipeline("Categorical level participant counts are invalid")
    }
    if (denominator == 0L) {
      if (
        length(indices) != 1L ||
          levels$level[[indices]] != "<no_estimable_rows>" ||
          levels$n[[indices]] != 0L ||
          !is.na(levels$proportion[[indices]])
      ) {
        abort_pipeline("Empty categorical series sentinel is invalid")
      }
      next
    }
    if (
      any(levels$level[indices] == "<no_estimable_rows>") ||
        sum(levels$n[indices]) != denominator ||
        anyNA(levels$proportion[indices]) ||
        any(
          !is.finite(levels$proportion[indices]) |
            levels$proportion[indices] < 0 |
            levels$proportion[indices] > 1
        ) ||
        abs(sum(levels$proportion[indices]) - 1) > 1e-10 ||
        any(
          abs(
            levels$proportion[indices] -
              levels$n[indices] / denominator
          ) >
            1e-10
        )
    ) {
      abort_pipeline("Categorical counts or proportions do not reconcile")
    }
    missing_index <- indices[levels$level[indices] == "<missing>"]
    expected_missing <- series$n_estimable_missing[[summary_index]]
    observed_missing <- if (length(missing_index) == 0L) {
      0L
    } else {
      levels$n[[missing_index]]
    }
    if (length(missing_index) > 1L || observed_missing != expected_missing) {
      abort_pipeline("Categorical missing-level counts do not reconcile")
    }
  }
  quality_expected <- data.frame(
    variable_id = rep(
      c(
        "hour_interval_analysis_eligible",
        "hour_interval_quarantined",
        "hour_interval_issue_code",
        "hour_diary_date_missing"
      ),
      each = 2L
    ),
    level = c(
      "FALSE",
      "TRUE",
      "FALSE",
      "TRUE",
      "missing_start_and_end",
      "no_issue",
      "FALSE",
      "TRUE"
    ),
    n = c(
      27L,
      30172L,
      30172L,
      27L,
      27L,
      30172L,
      30172L,
      27L
    ),
    stringsAsFactors = FALSE
  )
  quality <- levels[
    levels$variable_id %in% unique(quality_expected$variable_id),
    ,
    drop = FALSE
  ]
  quality_index <- preanalysis_verifier_assert_exact_keys(
    quality,
    quality_expected,
    c("variable_id", "level"),
    "diary-interval quality levels"
  )
  if (
    any(quality$placement != "all") ||
      any(quality$analysis_unit != "diary_interval") ||
      any(quality$series != "canonical") ||
      any(quality$n != quality_expected$n[quality_index])
  ) {
    abort_pipeline(
      "Diary-interval quality levels do not expose the 27-row quarantine"
    )
  }
  levels
}

preanalysis_verifier_verify_key_reconciliation <- function(
  reconciliation,
  crosswalk,
  series
) {
  preanalysis_verifier_assert_schema(
    reconciliation,
    preanalysis_verifier_key_reconciliation_schema,
    "pre-analysis key reconciliation"
  )
  effective <- preanalysis_verifier_effective_crosswalk(crosswalk)
  effective_index <- preanalysis_verifier_assert_exact_keys(
    reconciliation,
    effective,
    preanalysis_verifier_variable_key,
    "pre-analysis key reconciliation"
  )
  if (
    !preanalysis_verifier_equal(
      reconciliation$comparison_status,
      effective$comparison_status[effective_index]
    )
  ) {
    abort_pipeline("Key reconciliation statuses differ from crosswalk")
  }
  count_columns <- setdiff(
    preanalysis_verifier_key_reconciliation_schema,
    c(preanalysis_verifier_variable_key, "comparison_status")
  )
  for (column in count_columns) {
    preanalysis_verifier_assert_count(
      reconciliation[[column]],
      paste0("key reconciliation `", column, "`"),
      allow_na = TRUE
    )
  }
  series_token <- preanalysis_verifier_series_token(series)
  reconciliation_token <- preanalysis_verifier_key_token(reconciliation)
  for (index in seq_len(nrow(reconciliation))) {
    canonical_index <- match(
      paste(
        reconciliation_token[[index]],
        "canonical",
        sep = "\034"
      ),
      series_token
    )
    if (
      is.na(canonical_index) ||
        reconciliation$canonical_n_keys[[index]] !=
          series$n_observations[[canonical_index]] ||
        reconciliation$canonical_n_participants[[index]] !=
          series$n_participants[[canonical_index]]
    ) {
      abort_pipeline(
        "Canonical key reconciliation disagrees with series summary"
      )
    }
    participant <- reconciliation$analysis_unit[[index]] == "participant"
    if (
      participant &&
        !is.na(reconciliation$canonical_n_participant_days[[index]])
    ) {
      abort_pipeline("Participant-unit key reconciliation reports days")
    }
    if (
      !participant &&
        reconciliation$canonical_n_participant_days[[index]] !=
          series$n_participant_days[[canonical_index]]
    ) {
      abort_pipeline(
        "Canonical participant-day counts do not reconcile"
      )
    }

    applicable <- reconciliation$comparison_status[[index]] ==
      "applicable_field_key_mapping"
    if (!applicable) {
      suppressed <- c(
        "baseline_n_keys",
        "common_n_keys",
        "baseline_only_n_keys",
        "canonical_only_n_keys",
        "baseline_n_participants",
        "baseline_n_participant_days"
      )
      if (any(!is.na(reconciliation[index, suppressed]))) {
        abort_pipeline(
          "Not-applicable key reconciliation has baseline/paired outputs"
        )
      }
      next
    }
    baseline_index <- match(
      paste(
        reconciliation_token[[index]],
        "baseline",
        sep = "\034"
      ),
      series_token
    )
    required <- c(
      "baseline_n_keys",
      "canonical_n_keys",
      "common_n_keys",
      "baseline_only_n_keys",
      "canonical_only_n_keys",
      "baseline_n_participants",
      "canonical_n_participants"
    )
    if (
      is.na(baseline_index) ||
        anyNA(reconciliation[index, required]) ||
        reconciliation$baseline_n_keys[[index]] !=
          series$n_observations[[baseline_index]] ||
        reconciliation$baseline_n_participants[[index]] !=
          series$n_participants[[baseline_index]] ||
        reconciliation$baseline_n_keys[[index]] !=
          reconciliation$common_n_keys[[index]] +
            reconciliation$baseline_only_n_keys[[index]] ||
        reconciliation$canonical_n_keys[[index]] !=
          reconciliation$common_n_keys[[index]] +
            reconciliation$canonical_only_n_keys[[index]]
    ) {
      abort_pipeline("Applicable key partitions do not reconcile")
    }
    if (
      participant &&
        (!is.na(reconciliation$baseline_n_participant_days[[index]]) ||
          !is.na(
            reconciliation$canonical_n_participant_days[[index]]
          ))
    ) {
      abort_pipeline("Participant-unit key reconciliation reports days")
    }
    if (
      !participant &&
        (is.na(reconciliation$baseline_n_participant_days[[index]]) ||
          reconciliation$baseline_n_participant_days[[index]] !=
            series$n_participant_days[[baseline_index]])
    ) {
      abort_pipeline("Baseline participant-day counts do not reconcile")
    }
  }
  reconciliation
}

preanalysis_verifier_verify_paired_summary <- function(
  paired,
  crosswalk,
  reconciliation
) {
  preanalysis_verifier_assert_schema(
    paired,
    preanalysis_verifier_paired_schema,
    "pre-analysis paired comparison summary"
  )
  effective <- preanalysis_verifier_effective_crosswalk(crosswalk)
  effective_index <- preanalysis_verifier_assert_exact_keys(
    paired,
    effective,
    preanalysis_verifier_variable_key,
    "pre-analysis paired comparison summary"
  )
  for (column in c(
    "value_type",
    "comparison_status",
    "difference_method",
    "comparison_unit"
  )) {
    if (
      !preanalysis_verifier_equal(
        paired[[column]],
        effective[[column]][effective_index]
      )
    ) {
      abort_pipeline("Paired summary `%s` differs from crosswalk", column)
    }
  }
  output_columns <- setdiff(
    preanalysis_verifier_paired_schema,
    c(
      preanalysis_verifier_variable_key,
      "value_type",
      "comparison_status",
      "difference_method",
      "comparison_unit"
    )
  )
  not_applicable <- paired$comparison_status ==
    "not_applicable_no_field_key_mapping"
  if (
    any(not_applicable) &&
      any(!is.na(as.matrix(paired[not_applicable, output_columns])))
  ) {
    abort_pipeline(
      "Not-applicable variables contain paired-comparison outputs"
    )
  }
  applicable <- !not_applicable
  for (column in c(
    "n_common_keys",
    "n_paired_observed",
    "n_equal"
  )) {
    preanalysis_verifier_assert_count(
      paired[[column]][applicable],
      paste0("paired summary `", column, "`"),
      allow_na = identical(column, "n_equal")
    )
  }
  reconciliation_index <- match(
    preanalysis_verifier_key_token(paired),
    preanalysis_verifier_key_token(reconciliation)
  )
  if (
    any(
      paired$n_common_keys[applicable] !=
        reconciliation$common_n_keys[
          reconciliation_index[applicable]
        ]
    ) ||
      any(
        paired$n_paired_observed[applicable] > paired$n_common_keys[applicable]
      )
  ) {
    abort_pipeline("Paired key counts do not reconcile")
  }

  difference_columns <- c(
    "mean_difference",
    "sd_difference",
    "median_difference",
    "iqr_difference",
    "q025_difference",
    "q975_difference",
    "mean_absolute_difference",
    "root_mean_square_difference",
    "pearson_correlation",
    "spearman_correlation"
  )
  numeric <- applicable & paired$value_type == "numeric"
  categorical <- applicable & paired$value_type == "categorical"
  positive_numeric <- numeric & paired$n_paired_observed > 0L
  empty_numeric <- numeric & paired$n_paired_observed == 0L
  required_numeric <- setdiff(
    difference_columns,
    c("sd_difference", "pearson_correlation", "spearman_correlation")
  )
  if (
    any(positive_numeric) &&
      anyNA(as.matrix(paired[positive_numeric, required_numeric]))
  ) {
    abort_pipeline("Non-empty numeric paired summaries are incomplete")
  }
  if (
    any(empty_numeric) &&
      any(!is.na(as.matrix(paired[empty_numeric, difference_columns])))
  ) {
    abort_pipeline("Empty numeric paired summaries contain statistics")
  }
  more_than_one <- numeric & paired$n_paired_observed > 1L
  one_or_zero <- numeric & paired$n_paired_observed <= 1L
  if (
    anyNA(paired$sd_difference[more_than_one]) ||
      any(paired$sd_difference[more_than_one] < 0) ||
      any(!is.na(paired$sd_difference[one_or_zero]))
  ) {
    abort_pipeline("Paired difference SD contract failed")
  }
  if (
    any(
      positive_numeric &
        (paired$q025_difference > paired$median_difference |
          paired$median_difference > paired$q975_difference |
          paired$iqr_difference < 0 |
          paired$mean_absolute_difference < 0 |
          paired$root_mean_square_difference < 0 |
          paired$root_mean_square_difference + 1e-10 <
            paired$mean_absolute_difference)
    ) ||
      any(!is.na(paired$n_equal[numeric])) ||
      any(!is.na(paired$agreement_rate[numeric]))
  ) {
    abort_pipeline("Numeric paired statistics are invalid")
  }
  correlation <- c(
    paired$pearson_correlation[numeric],
    paired$spearman_correlation[numeric]
  )
  correlation <- correlation[!is.na(correlation)]
  if (
    any(!is.finite(correlation)) ||
      any(correlation < -1 - 1e-10 | correlation > 1 + 1e-10)
  ) {
    abort_pipeline("Paired correlations are invalid")
  }
  if (
    any(categorical) &&
      any(
        !is.na(as.matrix(
          paired[categorical, difference_columns]
        ))
      )
  ) {
    abort_pipeline("Categorical paired rows contain numeric differences")
  }
  if (
    anyNA(paired$n_equal[categorical]) ||
      any(
        paired$n_equal[categorical] > paired$n_paired_observed[categorical]
      )
  ) {
    abort_pipeline("Categorical paired equality counts are invalid")
  }
  positive_categorical <- categorical &
    paired$n_paired_observed > 0L
  empty_categorical <- categorical &
    paired$n_paired_observed == 0L
  if (
    anyNA(paired$agreement_rate[positive_categorical]) ||
      any(
        abs(
          paired$agreement_rate[positive_categorical] -
            paired$n_equal[positive_categorical] /
              paired$n_paired_observed[positive_categorical]
        ) >
          1e-10
      ) ||
      any(paired$n_equal[empty_categorical] != 0L) ||
      any(!is.na(paired$agreement_rate[empty_categorical]))
  ) {
    abort_pipeline("Categorical agreement rates do not reconcile")
  }
  paired
}

preanalysis_verifier_assert_range <- function(
  value,
  lower,
  upper,
  object
) {
  retained <- value[!is.na(value)]
  if (
    any(!is.finite(retained)) ||
      any(retained < lower - 1e-10) ||
      any(retained > upper + 1e-10)
  ) {
    abort_pipeline("%s is outside [%s, %s]", object, lower, upper)
  }
  invisible(value)
}

preanalysis_verifier_verify_shape_summary <- function(
  shape,
  crosswalk,
  series
) {
  preanalysis_verifier_assert_schema(
    shape,
    preanalysis_verifier_shape_schema,
    "pre-analysis distribution shape summary"
  )
  effective <- preanalysis_verifier_effective_crosswalk(crosswalk)
  effective_index <- preanalysis_verifier_assert_exact_keys(
    shape,
    effective,
    preanalysis_verifier_variable_key,
    "pre-analysis distribution shape summary"
  )
  for (column in c(
    "value_type",
    "comparison_status",
    "comparison_unit",
    "axis_geometry"
  )) {
    if (
      !preanalysis_verifier_equal(
        shape[[column]],
        effective[[column]][effective_index]
      )
    ) {
      abort_pipeline("Distribution shape `%s` differs from crosswalk", column)
    }
  }
  expected_interpretation <- paste(
    "Descriptive empirical distance only; no hypothesis test or",
    "sample-size-driven p-value."
  )
  if (
    anyNA(shape$distance_scope) ||
      any(
        shape$distance_scope !=
          paste(
            "all_estimable_rows; numeric finite only;",
            "categorical missing retained as level"
          )
      ) ||
      anyNA(shape$distance_interpretation) ||
      any(shape$distance_interpretation != expected_interpretation)
  ) {
    abort_pipeline("Distribution-distance interpretation contract failed")
  }
  preanalysis_verifier_assert_range(
    c(shape$baseline_bowley_skew, shape$canonical_bowley_skew),
    -1,
    1,
    "Bowley skew"
  )
  preanalysis_verifier_assert_range(
    c(
      shape$baseline_tail_asymmetry,
      shape$canonical_tail_asymmetry
    ),
    -1,
    1,
    "tail asymmetry"
  )
  preanalysis_verifier_assert_range(
    shape$ecdf_max_distance,
    0,
    1,
    "ECDF maximum distance"
  )
  preanalysis_verifier_assert_range(
    shape$total_variation_distance,
    0,
    1,
    "total-variation distance"
  )
  preanalysis_verifier_assert_range(
    shape$maximum_absolute_proportion_difference,
    0,
    1,
    "maximum absolute proportion difference"
  )
  for (column in c("wasserstein_1", "wasserstein_1_iqr_scaled")) {
    retained <- shape[[column]][!is.na(shape[[column]])]
    if (any(!is.finite(retained)) || any(retained < 0)) {
      abort_pipeline("Distribution shape `%s` is invalid", column)
    }
  }

  numeric <- shape$value_type == "numeric"
  categorical <- !numeric
  if (
    any(!is.na(shape$total_variation_distance[numeric])) ||
      any(
        !is.na(
          shape$maximum_absolute_proportion_difference[numeric]
        )
      ) ||
      any(!is.na(shape$baseline_bowley_skew[categorical])) ||
      any(!is.na(shape$canonical_bowley_skew[categorical])) ||
      any(!is.na(shape$baseline_tail_asymmetry[categorical])) ||
      any(!is.na(shape$canonical_tail_asymmetry[categorical])) ||
      any(!is.na(shape$ecdf_max_distance[categorical])) ||
      any(!is.na(shape$wasserstein_1[categorical])) ||
      any(!is.na(shape$wasserstein_1_iqr_scaled[categorical])) ||
      any(!is.na(shape$circular_kuiper_distance[categorical]))
  ) {
    abort_pipeline("Distribution shape metrics disagree with value type")
  }
  if (any(!is.na(shape$circular_kuiper_distance))) {
    abort_pipeline(
      "Declared linear axes must leave circular Kuiper fields blank"
    )
  }
  not_applicable <- shape$comparison_status ==
    "not_applicable_no_field_key_mapping"
  suppressed <- c(
    "baseline_bowley_skew",
    "baseline_tail_asymmetry",
    "ecdf_max_distance",
    "wasserstein_1",
    "wasserstein_1_iqr_scaled",
    "circular_kuiper_distance",
    "total_variation_distance",
    "maximum_absolute_proportion_difference"
  )
  if (
    any(not_applicable) &&
      any(!is.na(as.matrix(shape[not_applicable, suppressed])))
  ) {
    abort_pipeline(
      "Not-applicable distribution rows contain baseline distances"
    )
  }

  series_token <- preanalysis_verifier_series_token(series)
  shape_token <- preanalysis_verifier_key_token(shape)
  for (index in seq_len(nrow(shape))) {
    canonical_index <- match(
      paste(shape_token[[index]], "canonical", sep = "\034"),
      series_token
    )
    applicable <- shape$comparison_status[[index]] ==
      "applicable_field_key_mapping"
    if (!applicable) {
      next
    }
    baseline_index <- match(
      paste(shape_token[[index]], "baseline", sep = "\034"),
      series_token
    )
    if (is.na(canonical_index) || is.na(baseline_index)) {
      abort_pipeline("Distribution shape lacks a source series")
    }
    if (shape$value_type[[index]] == "numeric") {
      both_observed <- series$n_observed[[canonical_index]] > 0L &&
        series$n_observed[[baseline_index]] > 0L
      if (
        both_observed &&
          (is.na(shape$ecdf_max_distance[[index]]) ||
            is.na(shape$wasserstein_1[[index]]))
      ) {
        abort_pipeline("Numeric distribution distances are incomplete")
      }
    } else {
      both_estimable <- series$n_estimable[[canonical_index]] > 0L &&
        series$n_estimable[[baseline_index]] > 0L
      if (
        both_estimable &&
          (is.na(shape$total_variation_distance[[index]]) ||
            is.na(
              shape$maximum_absolute_proportion_difference[[index]]
            ))
      ) {
        abort_pipeline("Categorical distribution distances are incomplete")
      }
    }
  }
  shape
}

preanalysis_verifier_verify_overview <- function(
  overview,
  crosswalk,
  series,
  shape,
  reconciliation,
  paired
) {
  preanalysis_verifier_assert_schema(
    overview,
    preanalysis_verifier_overview_schema,
    "pre-analysis comparison overview"
  )
  effective <- preanalysis_verifier_effective_crosswalk(crosswalk)
  effective_index <- preanalysis_verifier_assert_exact_keys(
    overview,
    effective,
    preanalysis_verifier_variable_key,
    "pre-analysis comparison overview"
  )
  descriptor_columns <- c(
    "value_type",
    "comparison_status",
    "comparison_unit",
    "axis_geometry",
    "variable_order",
    "metric_id",
    "manuscript_name",
    "abbreviation",
    "manuscript_category",
    "analytical_role",
    "variant_label",
    "domain",
    "native_unit",
    "display_unit",
    "canonical_transform",
    "baseline_transform",
    "linear_summary_interpretation",
    "technical_estimand",
    "mapping_scope",
    "semantic_comparability",
    "comparability_class",
    "comparability_note",
    "non_applicable_reason"
  )
  for (column in descriptor_columns) {
    if (
      !preanalysis_verifier_equal(
        overview[[column]],
        effective[[column]][effective_index]
      )
    ) {
      abort_pipeline("Overview `%s` differs from crosswalk", column)
    }
  }
  summary_fields <- c(
    "n_observations",
    "n_estimable",
    "n_observed",
    "n_missing",
    "n_nonfinite",
    "n_participants",
    "n_participants_observed",
    "n_participant_days",
    "n_participant_days_observed",
    "mean",
    "median",
    "sd",
    "iqr",
    "q025",
    "q25",
    "q75",
    "q975",
    "zero_rate",
    "nonfinite_rate",
    "circular_mean",
    "circular_median",
    "circular_resultant_length",
    "circular_sd_hours"
  )
  series_token <- preanalysis_verifier_series_token(series)
  overview_token <- preanalysis_verifier_key_token(overview)
  for (index in seq_len(nrow(overview))) {
    for (source in c("canonical", "baseline")) {
      series_index <- match(
        paste(overview_token[[index]], source, sep = "\034"),
        series_token
      )
      for (field in summary_fields) {
        observed <- overview[[paste0(source, "_", field)]][[index]]
        expected <- if (is.na(series_index)) {
          NA
        } else {
          series[[field]][[series_index]]
        }
        if (!preanalysis_verifier_equal(observed, expected)) {
          abort_pipeline(
            "Overview `%s_%s` disagrees with series summary",
            source,
            field
          )
        }
      }
    }
  }
  count_delta <- c(
    "n_observations",
    "n_estimable",
    "n_observed",
    "n_missing",
    "n_nonfinite",
    "n_participants",
    "n_participants_observed",
    "n_participant_days",
    "n_participant_days_observed"
  )
  for (field in count_delta) {
    expected <- overview[[paste0("canonical_", field)]] -
      overview[[paste0("baseline_", field)]]
    if (
      !preanalysis_verifier_equal(
        overview[[paste0("delta_", field)]],
        expected
      )
    ) {
      abort_pipeline(
        "Overview `delta_%s` is not canonical minus baseline",
        field
      )
    }
  }

  shape_index <- match(
    overview_token,
    preanalysis_verifier_key_token(shape)
  )
  shape_fields <- setdiff(
    preanalysis_verifier_shape_schema,
    c(
      preanalysis_verifier_variable_key,
      "value_type",
      "comparison_status",
      "comparison_unit"
    )
  )
  if (anyNA(shape_index)) {
    abort_pipeline("Overview lacks a distribution-shape source row")
  }
  for (field in shape_fields) {
    if (
      !preanalysis_verifier_equal(
        overview[[field]],
        shape[[field]][shape_index]
      )
    ) {
      abort_pipeline("Overview `%s` differs from shape summary", field)
    }
  }
  reconciliation_index <- match(
    overview_token,
    preanalysis_verifier_key_token(reconciliation)
  )
  if (anyNA(reconciliation_index)) {
    abort_pipeline("Overview lacks a key-reconciliation source row")
  }
  reconciliation_fields <- setdiff(
    preanalysis_verifier_key_reconciliation_schema,
    c(preanalysis_verifier_variable_key, "comparison_status")
  )
  for (field in reconciliation_fields) {
    if (
      !preanalysis_verifier_equal(
        overview[[paste0("key_", field)]],
        reconciliation[[field]][reconciliation_index]
      )
    ) {
      abort_pipeline(
        "Overview `key_%s` differs from key reconciliation",
        field
      )
    }
  }
  paired_index <- match(
    overview_token,
    preanalysis_verifier_key_token(paired)
  )
  if (anyNA(paired_index)) {
    abort_pipeline("Overview lacks a paired-comparison source row")
  }
  paired_fields <- setdiff(
    preanalysis_verifier_paired_schema,
    c(
      preanalysis_verifier_variable_key,
      "value_type",
      "comparison_status",
      "difference_method",
      "comparison_unit"
    )
  )
  for (field in paired_fields) {
    if (
      !preanalysis_verifier_equal(
        overview[[field]],
        paired[[field]][paired_index]
      )
    ) {
      abort_pipeline(
        "Overview `%s` differs from paired summary",
        field
      )
    }
  }
  overview
}

preanalysis_verifier_compare_table <- function(
  observed,
  expected,
  columns,
  key,
  object
) {
  preanalysis_verifier_assert_schema(observed, columns, object)
  expected <- expected[columns]
  expected_index <- preanalysis_verifier_assert_exact_keys(
    observed,
    expected,
    key,
    object
  )
  for (column in columns) {
    if (
      !preanalysis_verifier_equal(
        observed[[column]],
        expected[[column]][expected_index]
      )
    ) {
      abort_pipeline("%s `%s` differs from source data", object, column)
    }
  }
  invisible(observed)
}

preanalysis_verifier_verify_numeric_figure_data <- function(
  figure,
  quantiles,
  crosswalk
) {
  data <- quantiles[
    quantiles$probability %in% c(0.05, 0.25, 0.5, 0.75, 0.95),
    ,
    drop = FALSE
  ]
  crosswalk_index <- match(data$variable_id, crosswalk$variable_id)
  metadata_columns <- c(
    "variable_order",
    "metric_id",
    "manuscript_name",
    "abbreviation",
    "manuscript_category",
    "display_unit",
    "analytical_role",
    "variant_label",
    "domain"
  )
  for (column in metadata_columns) {
    data[[column]] <- crosswalk[[column]][crosswalk_index]
  }
  priority <- crosswalk$figure_priority[crosswalk_index]
  data <- data[
    priority & data$axis_geometry == "linear",
    ,
    drop = FALSE
  ]
  key <- c("variable_id", "placement", "analysis_unit")
  canonical <- quantiles[
    quantiles$series == "canonical" &
      quantiles$probability %in% c(0.25, 0.5, 0.75),
    ,
    drop = FALSE
  ]
  canonical_token <- preanalysis_verifier_key_token(canonical)
  data_token <- preanalysis_verifier_key_token(data)
  for (probability in c(0.25, 0.5, 0.75)) {
    selected <- canonical$probability == probability
    lookup <- stats::setNames(
      canonical$value[selected],
      canonical_token[selected]
    )
    data[[paste0("canonical_q", probability)]] <-
      unname(lookup[data_token])
  }
  denominator <- data$canonical_q0.75 - data$canonical_q0.25
  data$standardized_value <- ifelse(
    is.finite(denominator) & denominator > 0,
    (data$value - data$canonical_q0.5) / denominator,
    NA_real_
  )
  data$display_axis <- "Main-analysis median/IQR standardized value"
  expected <- data[
    is.finite(data$standardized_value),
    preanalysis_verifier_numeric_figure_schema,
    drop = FALSE
  ]
  if (nrow(figure) != 570L) {
    abort_pipeline("Numeric figure data must contain exactly 570 rows")
  }
  preanalysis_verifier_compare_table(
    figure,
    expected,
    preanalysis_verifier_numeric_figure_schema,
    c(key, "series", "probability"),
    "numeric distribution figure data"
  )
  figure
}

preanalysis_verifier_verify_categorical_figure_data <- function(
  figure,
  levels,
  crosswalk
) {
  crosswalk_index <- match(levels$variable_id, crosswalk$variable_id)
  data <- levels
  metadata_columns <- c(
    "variable_order",
    "metric_id",
    "manuscript_name",
    "abbreviation",
    "manuscript_category",
    "display_unit",
    "analytical_role",
    "variant_label",
    "domain"
  )
  for (column in metadata_columns) {
    data[[column]] <- crosswalk[[column]][crosswalk_index]
  }
  priority <- crosswalk$figure_priority[crosswalk_index]
  data <- data[
    priority & data$level != "<no_estimable_rows>",
    ,
    drop = FALSE
  ]
  group_columns <- c(
    preanalysis_verifier_variable_key,
    "series"
  )
  group_token <- preanalysis_verifier_token(data, group_columns)
  keep <- logical(nrow(data))
  for (indices in split(seq_len(nrow(data)), group_token)) {
    ranked <- indices[order(
      -data$proportion[indices],
      data$level[indices]
    )]
    keep[head(ranked, 8L)] <- TRUE
  }
  expected <- data[
    keep,
    preanalysis_verifier_categorical_figure_schema,
    drop = FALSE
  ]
  if (nrow(figure) != 209L) {
    abort_pipeline("Categorical figure data must contain exactly 209 rows")
  }
  preanalysis_verifier_compare_table(
    figure,
    expected,
    preanalysis_verifier_categorical_figure_schema,
    c(group_columns, "level"),
    "categorical distribution figure data"
  )
  figure
}

preanalysis_verifier_verify_run_metadata <- function(
  metadata,
  input_verification
) {
  preanalysis_verifier_assert_schema(
    metadata,
    c("field", "value"),
    "pre-analysis comparison run metadata"
  )
  fields <- c(
    "gate_status",
    "preparation06_status",
    "r_version",
    "timezone",
    "difference_direction",
    "distribution_distance_role",
    "participant_rows_exported",
    "participant_identifiers_exported",
    "free_text_content_exported",
    "normalization_manifest_sha256",
    "base_manifest_sha256",
    "base_input_bundle_sha256",
    "metric_display_registry_sha256"
  )
  if (!identical(as.character(metadata$field), fields)) {
    abort_pipeline("Run metadata has a non-exact ordered field set")
  }
  assert_unique_key(
    metadata,
    "field",
    object = "pre-analysis comparison run metadata"
  )
  preanalysis_verifier_assert_nonempty_text(
    as.character(metadata$value),
    "run metadata values"
  )
  value <- stats::setNames(
    as.character(metadata$value),
    as.character(metadata$field)
  )
  expected <- c(
    gate_status = "PASS",
    preparation06_status = "stable",
    r_version = "4.6.1",
    timezone = "UTC",
    difference_direction = "main_analysis_minus_manuscript_prepared",
    distribution_distance_role = "descriptive_only_no_inferential_test",
    participant_rows_exported = "FALSE",
    participant_identifiers_exported = "FALSE",
    free_text_content_exported = "FALSE",
    normalization_manifest_sha256 = input_verification$normalization_manifest_sha256,
    base_manifest_sha256 = input_verification$base_manifest_sha256,
    base_input_bundle_sha256 = input_verification$base_input_bundle_sha256,
    metric_display_registry_sha256 = input_verification$metric_display_registry_sha256
  )
  if (
    !identical(unname(value[fields]), unname(expected[fields])) ||
      !isTRUE(input_verification$preparation06_hashes_match)
  ) {
    abort_pipeline(
      paste0(
        "Gate PASS requires stable Preparation 06, exact manifest hashes, ",
        "R 4.6.1, and privacy-safe descriptive outputs"
      )
    )
  }
  list(
    values = value,
    preparation06_status = value[["preparation06_status"]],
    gate_status = value[["gate_status"]]
  )
}

preanalysis_verifier_verify_audit_report <- function(
  path,
  metadata,
  input_verification
) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) == 0L) {
    abort_pipeline("Pre-analysis comparison audit report may not be empty")
  }
  text <- paste(lines, collapse = "\n")
  lower <- tolower(text)
  if (
    grepl(
      preanalysis_verifier_participant_pattern(),
      text,
      perl = TRUE
    )
  ) {
    abort_pipeline(
      "Pre-analysis comparison audit report exposes a participant identifier"
    )
  }
  required <- c(
    pass = "status:[[:space:]]*`?pass`?",
    runtime = "r[[:space:]]*4[.]6[.]1",
    stable_preparation = "(stable[^\\n]*preparation[[:space:]_-]*0?6|preparation[[:space:]_-]*0?6[^\\n]*stable)",
    scope = "(^|\\n)#+[[:space:]]*scope",
    participant_hour_scope = "participant-hour",
    diary_interval_scope = "diary[-_]interval",
    descriptive_distance = "descriptive[^\\n]*distribution|distribution[^\\n]*descriptive",
    numeric_distance_scope = "all estimable rows[^\\n]*numeric distances use finite values only",
    categorical_distance_scope = "categorical distances retain missing values[^\\n]*<missing>",
    display_registry = "config/metric_display_registry[.]csv",
    endpoint_exclusion = "m10/l10 onset and offset diagnostics are deliberately absent",
    no_inference = "no hypothesis test|without inferential tests|not sample-size tests",
    limitations = "(^|\\n)#+[[:space:]]*(limitations?|deliberate non-comparisons)",
    rerun = "(^|\\n)#+[[:space:]]*rerun"
  )
  present <- vapply(
    required,
    grepl,
    logical(1),
    x = lower,
    perl = TRUE
  )
  if (any(!present)) {
    abort_pipeline(
      "Audit report is missing required content: %s",
      paste(names(present)[!present], collapse = ", ")
    )
  }
  if (
    !grepl(
      "rscript[[:space:]]+--vanilla[[:space:]]+scripts/pipeline/run_preanalysis_comparison[.]r",
      lower,
      perl = TRUE
    ) ||
      !identical(metadata$preparation06_status, "stable") ||
      !identical(metadata$gate_status, "PASS")
  ) {
    abort_pipeline("Audit report rerun/gate contract failed")
  }
  required_hashes <- c(
    input_verification$normalization_manifest_sha256,
    input_verification$base_manifest_sha256,
    input_verification$base_input_bundle_sha256,
    input_verification$metric_display_registry_sha256
  )
  if (
    any(
      !vapply(
        required_hashes,
        grepl,
        logical(1),
        x = text,
        fixed = TRUE
      )
    )
  ) {
    abort_pipeline("Audit report omits an exact preparation hash")
  }
  invisible(TRUE)
}

verify_preanalysis_comparison_artifacts <- function(
  root = project_root(),
  output_root = root,
  expected_normalization_manifest_sha256,
  expected_base_manifest_sha256
) {
  if (!identical(as.character(getRversion()), "4.6.1")) {
    abort_pipeline(
      "Pre-analysis comparison verification requires R 4.6.1; found %s",
      as.character(getRversion())
    )
  }
  for (hash in c(
    expected_normalization_manifest_sha256,
    expected_base_manifest_sha256
  )) {
    if (
      !is.character(hash) ||
        length(hash) != 1L ||
        is.na(hash) ||
        !grepl("^[0-9a-f]{64}$", hash)
    ) {
      abort_pipeline(
        "Verifier requires two exact lowercase 64-character SHA-256 values"
      )
    }
  }
  layout <- preanalysis_verifier_layout(
    root = root,
    output_root = output_root
  )
  verified <- preanalysis_verifier_verify_manifest(layout)
  tables <- verified$csv
  for (name in names(tables)) {
    preanalysis_verifier_assert_privacy(
      tables[[name]],
      paste0("pre-analysis artifact `", name, "`")
    )
    preanalysis_verifier_assert_no_inference(
      tables[[name]],
      paste0("pre-analysis artifact `", name, "`")
    )
  }
  for (name in preanalysis_verifier_variable_bearing_csv_ids) {
    preanalysis_verifier_assert_no_window_endpoints(
      tables[[name]],
      paste0("pre-analysis artifact `", name, "`")
    )
  }

  input_verification <- preanalysis_verifier_verify_input_provenance(
    tables$input_provenance,
    layout,
    expected_normalization_manifest_sha256,
    expected_base_manifest_sha256
  )
  crosswalk <- preanalysis_verifier_verify_crosswalk(
    tables$variable_crosswalk,
    input_verification$metric_display_registry
  )
  series <- preanalysis_verifier_verify_series_summary(
    tables$series_summary,
    crosswalk
  )
  quantiles <- preanalysis_verifier_verify_numeric_quantiles(
    tables$numeric_quantiles,
    crosswalk,
    series
  )
  levels <- preanalysis_verifier_verify_categorical_levels(
    tables$categorical_levels,
    crosswalk,
    series
  )
  reconciliation <- preanalysis_verifier_verify_key_reconciliation(
    tables$key_reconciliation,
    crosswalk,
    series
  )
  paired <- preanalysis_verifier_verify_paired_summary(
    tables$paired_comparison_summary,
    crosswalk,
    reconciliation
  )
  shape <- preanalysis_verifier_verify_shape_summary(
    tables$distribution_shape_summary,
    crosswalk,
    series
  )
  overview <- preanalysis_verifier_verify_overview(
    tables$comparison_overview,
    crosswalk,
    series,
    shape,
    reconciliation,
    paired
  )
  preanalysis_verifier_verify_numeric_figure_data(
    tables$figure_numeric_distribution_data,
    quantiles,
    crosswalk
  )
  preanalysis_verifier_verify_categorical_figure_data(
    tables$figure_categorical_distribution_data,
    levels,
    crosswalk
  )
  metadata <- preanalysis_verifier_verify_run_metadata(
    tables$run_metadata,
    input_verification
  )
  preanalysis_verifier_verify_audit_report(
    verified$resolved_paths[["audit_report"]],
    metadata,
    input_verification
  )

  list(
    status = "PASS",
    preparation06_status = metadata$preparation06_status,
    gate_status = metadata$gate_status,
    artifacts = nrow(verified$manifest),
    csv_artifacts = length(preanalysis_verifier_csv_ids),
    png_artifacts = length(preanalysis_verifier_png_ids),
    markdown_artifacts = length(preanalysis_verifier_markdown_ids),
    variables = nrow(crosswalk),
    applicable_variables = sum(
      crosswalk$comparison_status == "applicable_field_key_mapping"
    ),
    not_applicable_variables = sum(
      crosswalk$comparison_status == "not_applicable_no_field_key_mapping"
    ),
    numeric_variables = sum(crosswalk$value_type == "numeric"),
    categorical_variables = sum(crosswalk$value_type == "categorical"),
    series_rows = nrow(series),
    paired_rows = nrow(paired),
    shape_rows = nrow(shape),
    overview_rows = nrow(overview),
    normalization_manifest_sha256 = input_verification$normalization_manifest_sha256,
    base_manifest_sha256 = input_verification$base_manifest_sha256,
    base_input_bundle_sha256 = input_verification$base_input_bundle_sha256,
    png_dimensions = verified$png_dimensions,
    manifest_sha256 = artifact_sha256(layout$manifest_path)
  )
}
