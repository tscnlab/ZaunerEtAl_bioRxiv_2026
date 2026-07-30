# Build deterministic pre-analysis comparison tables and distribution figures.
#
# Source paths_io.R, assertions.R, metric_display_registry.R, and
# preanalysis_comparison.R first.

preanalysis_output_paths <- function(output_root) {
  diagnostic_root <- file.path(
    output_root,
    "artifacts",
    "08_diagnostics",
    "preanalysis_comparison"
  )
  csv_stems <- c(
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
  list(
    diagnostic_root = diagnostic_root,
    csv = stats::setNames(
      file.path(diagnostic_root, paste0(csv_stems, ".csv")),
      csv_stems
    ),
    figures = c(
      numeric_distribution_overview = file.path(
        diagnostic_root,
        "numeric_distribution_overview.png"
      ),
      categorical_distribution_overview = file.path(
        diagnostic_root,
        "categorical_distribution_overview.png"
      )
    ),
    audit_report = file.path(diagnostic_root, "audit_report.md"),
    manifest = file.path(
      output_root,
      "artifacts",
      "12_manifests",
      "preanalysis_comparison_artifacts.csv"
    )
  )
}

preanalysis_input_paths <- function(root) {
  base_root <- file.path(root, "artifacts", "06_model_data", "base")
  metric_root <- file.path(root, "artifacts", "05_metrics")
  normalized_root <- file.path(
    root,
    "artifacts",
    "06_model_data",
    "normalized_inputs"
  )
  list(
    display_registry = metric_display_registry_path(root),
    manifests = c(
      baseline = file.path(
        root,
        "audit",
        "baseline",
        "data_artifact_hashes.csv"
      ),
      metrics = file.path(
        root,
        "artifacts",
        "12_manifests",
        "metric_artifacts.csv"
      ),
      normalization = file.path(
        root,
        "artifacts",
        "12_manifests",
        "model_input_normalization.csv"
      ),
      base = file.path(
        root,
        "artifacts",
        "12_manifests",
        "base_model_data_artifacts.csv"
      )
    ),
    baseline = stats::setNames(
      file.path(
        root,
        "data",
        paste0("metrics_", preanalysis_placements(), ".RData")
      ),
      preanalysis_placements()
    ),
    metric_values = stats::setNames(
      file.path(
        metric_root,
        paste0("metrics_", preanalysis_placements(), "_values_long.csv")
      ),
      preanalysis_placements()
    ),
    participant_enriched = stats::setNames(
      file.path(
        base_root,
        paste0(
          "metrics_",
          preanalysis_placements(),
          "_participant_enriched.rds"
        )
      ),
      preanalysis_placements()
    ),
    participant_day_enriched = stats::setNames(
      file.path(
        base_root,
        paste0(
          "metrics_",
          preanalysis_placements(),
          "_participant_day_enriched.rds"
        )
      ),
      preanalysis_placements()
    ),
    grid_30_minute = stats::setNames(
      file.path(
        base_root,
        paste0("metrics_", preanalysis_placements(), "_30_minute_context.rds")
      ),
      preanalysis_placements()
    ),
    grid_one_hour = stats::setNames(
      file.path(
        base_root,
        paste0("metrics_", preanalysis_placements(), "_one_hour_context.rds")
      ),
      preanalysis_placements()
    ),
    normalized = c(
      exercise_diary = file.path(normalized_root, "exercisediary.rds"),
      light_diary = file.path(normalized_root, "lightexposurediary.rds"),
      sleep_diary = file.path(normalized_root, "sleepdiaries.rds")
    )
  )
}

preanalysis_attach_metric_display <- function(crosswalk, root) {
  light_metric <- crosswalk$domain == "light_metric"
  registry <- read_metric_display_registry(root)
  if (
    !setequal(
      crosswalk$metric_id[light_metric],
      registry$metric_id
    )
  ) {
    missing <- setdiff(
      crosswalk$metric_id[light_metric],
      registry$metric_id
    )
    extra <- setdiff(
      registry$metric_id,
      crosswalk$metric_id[light_metric]
    )
    abort_pipeline(
      paste(
        "Comparison/display metric registries differ; missing display:",
        "%s; display-only: %s"
      ),
      paste(missing, collapse = ", "),
      paste(extra, collapse = ", ")
    )
  }
  display <- attach_metric_display(
    data.frame(
      metric_id = crosswalk$metric_id[light_metric],
      stringsAsFactors = FALSE
    ),
    root = root
  )
  expected_analysis_unit <- unname(c(
    participant = "participant",
    participant_day = "participant-day",
    `30_minute` = "participant-30-minute",
    one_hour = "participant-hour"
  )[crosswalk$analysis_unit[light_metric]])
  if (
    anyNA(expected_analysis_unit) ||
      !identical(display$analysis_unit, expected_analysis_unit)
  ) {
    abort_pipeline(
      "Comparison and manuscript display analysis units do not reconcile"
    )
  }

  crosswalk$manuscript_name <- crosswalk$technical_estimand
  crosswalk$abbreviation <- ""
  crosswalk$manuscript_category <- gsub(
    "_",
    " ",
    crosswalk$domain,
    fixed = TRUE
  )
  crosswalk$display_unit <- crosswalk$comparison_unit
  crosswalk$analytical_role <- "predictor_or_context"
  crosswalk$variant_label <- "Main analysis variable"
  display_columns <- c(
    "manuscript_name",
    "abbreviation",
    "manuscript_category",
    "display_unit",
    "analytical_role",
    "variant_label"
  )
  for (column in display_columns) {
    crosswalk[[column]][light_metric] <- display[[column]]
  }
  prohibited <- grepl(
    paste(
      "support[- ]aware|support[- ]corrected|time[- ]sensitive|",
      "ratio of integrals"
    ),
    paste(
      crosswalk$manuscript_name[light_metric],
      crosswalk$manuscript_category[light_metric]
    ),
    ignore.case = TRUE,
    perl = TRUE
  )
  if (
    any(prohibited) ||
      any(!nzchar(crosswalk$manuscript_name[light_metric])) ||
      any(!nzchar(crosswalk$manuscript_category[light_metric]))
  ) {
    abort_pipeline(
      "Comparison has invalid manuscript-facing metric labels"
    )
  }
  preferred <- c(
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
  if (!setequal(names(crosswalk), preferred)) {
    abort_pipeline("Display-enriched comparison crosswalk schema drifted")
  }
  crosswalk[preferred]
}

preanalysis_absolute_path <- function(path, root) {
  vapply(
    path,
    function(value) {
      candidate <- if (grepl("^/", value)) value else file.path(root, value)
      normalizePath(candidate, winslash = "/", mustWork = TRUE)
    },
    character(1)
  )
}

preanalysis_relative_path <- function(path, root) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  if (startsWith(path, prefix)) substring(path, nchar(prefix) + 1L) else path
}

preanalysis_file_dimensions <- function(path) {
  extension <- tolower(tools::file_ext(path))
  if (extension == "rds") {
    object <- readRDS(path)
    if (!is.data.frame(object)) {
      abort_pipeline("Pre-analysis RDS input is not one data frame: %s", path)
    }
    return(c(rows = nrow(object), columns = ncol(object)))
  }
  if (extension == "csv") {
    object <- readr::read_csv(
      path,
      show_col_types = FALSE,
      progress = FALSE
    )
    return(c(rows = nrow(object), columns = ncol(object)))
  }
  c(rows = NA_integer_, columns = NA_integer_)
}

preanalysis_manifest_match <- function(path, manifest, root, object) {
  assert_columns(
    manifest,
    c("path", "sha256", "r_version"),
    object = object
  )
  manifest_path <- preanalysis_absolute_path(manifest$path, root)
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  match <- which(manifest_path == path)
  if (length(match) != 1L) {
    abort_pipeline("%s must identify input exactly once: %s", object, path)
  }
  row <- manifest[match, , drop = FALSE]
  actual_hash <- artifact_sha256(path)
  if (
    row$sha256[[1L]] != actual_hash ||
      row$r_version[[1L]] != "4.6.1"
  ) {
    abort_pipeline("%s provenance failed for %s", object, path)
  }
  row
}

preanalysis_input_row <- function(
  input_id,
  input_kind,
  path,
  root,
  expected_sha256,
  verification_source,
  dimensions = preanalysis_file_dimensions(path)
) {
  actual_sha256 <- artifact_sha256(path)
  if (!identical(actual_sha256, expected_sha256)) {
    abort_pipeline("Exact input hash failed for `%s`", input_id)
  }
  data.frame(
    input_id = input_id,
    input_kind = input_kind,
    path = preanalysis_relative_path(path, root),
    sha256 = actual_sha256,
    expected_sha256 = expected_sha256,
    bytes = unname(file.info(path)$size),
    rows = unname(dimensions[["rows"]]),
    columns = unname(dimensions[["columns"]]),
    verification_source = verification_source,
    r_version = "4.6.1",
    status = "PASS",
    stringsAsFactors = FALSE
  )
}

preanalysis_verify_inputs <- function(
  root,
  input_paths,
  expected_normalization_manifest_sha256,
  expected_base_manifest_sha256
) {
  required <- unlist(input_paths, recursive = TRUE, use.names = FALSE)
  missing <- required[!file.exists(required)]
  if (length(missing) > 0L) {
    abort_pipeline(
      "Pre-analysis comparison input(s) are missing: %s",
      paste(missing, collapse = ", ")
    )
  }
  manifests <- lapply(input_paths$manifests, function(path) {
    readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  })
  normalization_hash <- artifact_sha256(
    input_paths$manifests[["normalization"]]
  )
  base_hash <- artifact_sha256(input_paths$manifests[["base"]])
  if (
    !identical(
      normalization_hash,
      expected_normalization_manifest_sha256
    ) ||
      !identical(base_hash, expected_base_manifest_sha256)
  ) {
    abort_pipeline(
      paste(
        "Preparation 06 manifests do not match the explicitly approved",
        "stable hashes"
      )
    )
  }
  assert_columns(
    manifests$base,
    c(
      "normalization_manifest_sha256",
      "input_bundle_sha256",
      "status"
    ),
    object = "base-model manifest"
  )
  if (
    any(manifests$base$status != "PASS") ||
      any(
        manifests$base$normalization_manifest_sha256 != normalization_hash
      ) ||
      length(unique(manifests$base$input_bundle_sha256)) != 1L
  ) {
    abort_pipeline(
      "Base-model manifest is not a stable PASS over the exact normalization manifest"
    )
  }

  provenance <- list()
  index <- 0L
  for (name in names(input_paths$manifests)) {
    path <- input_paths$manifests[[name]]
    index <- index + 1L
    provenance[[index]] <- preanalysis_input_row(
      input_id = paste0(name, "_manifest"),
      input_kind = "manifest_csv",
      path = path,
      root = root,
      expected_sha256 = artifact_sha256(path),
      verification_source = "self_hash"
    )
  }

  display_registry <- read_metric_display_registry(root)
  index <- index + 1L
  provenance[[index]] <- preanalysis_input_row(
    input_id = "metric_display_registry",
    input_kind = "manuscript_display_registry_csv",
    path = input_paths$display_registry,
    root = root,
    expected_sha256 = artifact_sha256(input_paths$display_registry),
    verification_source = "validated_display_registry_contract",
    dimensions = c(
      rows = nrow(display_registry),
      columns = ncol(display_registry)
    )
  )

  baseline_ledger <- manifests$baseline
  assert_columns(
    baseline_ledger,
    c("path", "sha256", "bytes", "baseline_status"),
    object = "frozen baseline ledger"
  )
  for (placement in preanalysis_placements()) {
    path <- input_paths$baseline[[placement]]
    relative <- preanalysis_relative_path(path, root)
    row <- baseline_ledger[
      baseline_ledger$path == relative,
      ,
      drop = FALSE
    ]
    if (
      nrow(row) != 1L ||
        row$baseline_status[[1L]] != "tracked-baseline" ||
        as.numeric(row$bytes[[1L]]) != unname(file.info(path)$size)
    ) {
      abort_pipeline("Frozen baseline ledger failed for %s", relative)
    }
    index <- index + 1L
    provenance[[index]] <- preanalysis_input_row(
      input_id = paste0("baseline_metrics_", placement),
      input_kind = "frozen_baseline_rdata",
      path = path,
      root = root,
      expected_sha256 = row$sha256[[1L]],
      verification_source = preanalysis_relative_path(
        input_paths$manifests[["baseline"]],
        root
      ),
      dimensions = c(rows = 22L, columns = 4L)
    )
  }

  for (placement in preanalysis_placements()) {
    path <- input_paths$metric_values[[placement]]
    row <- preanalysis_manifest_match(
      path,
      manifests$metrics,
      root,
      "canonical metric manifest"
    )
    if (
      row$artifact_type[[1L]] != "long_metric_values" ||
        row$placement[[1L]] != placement
    ) {
      abort_pipeline(
        "Canonical long-metric manifest role failed for %s",
        placement
      )
    }
    index <- index + 1L
    provenance[[index]] <- preanalysis_input_row(
      input_id = paste0("metric_values_", placement),
      input_kind = "canonical_metric_csv",
      path = path,
      root = root,
      expected_sha256 = row$sha256[[1L]],
      verification_source = preanalysis_relative_path(
        input_paths$manifests[["metrics"]],
        root
      )
    )
  }

  base_inputs <- c(
    stats::setNames(
      input_paths$participant_enriched,
      paste0(names(input_paths$participant_enriched), "_participant")
    ),
    stats::setNames(
      input_paths$participant_day_enriched,
      paste0(names(input_paths$participant_day_enriched), "_participant_day")
    ),
    stats::setNames(
      input_paths$grid_30_minute,
      paste0(names(input_paths$grid_30_minute), "_30_minute")
    ),
    stats::setNames(
      input_paths$grid_one_hour,
      paste0(names(input_paths$grid_one_hour), "_one_hour")
    )
  )
  for (input_id in names(base_inputs)) {
    path <- base_inputs[[input_id]]
    row <- preanalysis_manifest_match(
      path,
      manifests$base,
      root,
      "base-model artifact manifest"
    )
    if (row$status[[1L]] != "PASS") {
      abort_pipeline("Base-model input is not PASS: %s", path)
    }
    index <- index + 1L
    provenance[[index]] <- preanalysis_input_row(
      input_id = paste0("base_", input_id),
      input_kind = "canonical_base_rds",
      path = path,
      root = root,
      expected_sha256 = row$sha256[[1L]],
      verification_source = preanalysis_relative_path(
        input_paths$manifests[["base"]],
        root
      )
    )
  }

  modality_map <- c(
    exercise_diary = "exercisediary",
    light_diary = "lightexposurediary",
    sleep_diary = "sleepdiaries"
  )
  for (input_id in names(input_paths$normalized)) {
    path <- input_paths$normalized[[input_id]]
    row <- manifests$normalization[
      manifests$normalization$modality == modality_map[[input_id]] &
        manifests$normalization$artifact_type == "rds",
      ,
      drop = FALSE
    ]
    if (
      nrow(row) != 1L ||
        normalizePath(
          file.path(root, row$path[[1L]]),
          winslash = "/",
          mustWork = TRUE
        ) !=
          normalizePath(path, winslash = "/", mustWork = TRUE) ||
        row$sha256[[1L]] != artifact_sha256(path) ||
        row$r_version[[1L]] != "4.6.1"
    ) {
      abort_pipeline("Normalized input provenance failed for %s", input_id)
    }
    index <- index + 1L
    provenance[[index]] <- preanalysis_input_row(
      input_id = paste0("normalized_", input_id),
      input_kind = "canonical_normalized_rds",
      path = path,
      root = root,
      expected_sha256 = row$sha256[[1L]],
      verification_source = preanalysis_relative_path(
        input_paths$manifests[["normalization"]],
        root
      )
    )
  }
  list(
    provenance = do.call(rbind, provenance),
    normalization_manifest_sha256 = normalization_hash,
    base_manifest_sha256 = base_hash,
    base_input_bundle_sha256 = unique(
      manifests$base$input_bundle_sha256
    )[[1L]],
    metric_display_registry_sha256 = artifact_sha256(
      input_paths$display_registry
    )
  )
}

preanalysis_load_baseline <- function(path, placement) {
  environment <- new.env(parent = baseenv())
  expected_object <- paste0("metrics_", placement)
  loaded <- load(path, envir = environment)
  if (!identical(loaded, expected_object)) {
    abort_pipeline(
      "Frozen baseline `%s` must contain only `%s`",
      path,
      expected_object
    )
  }
  object <- environment[[expected_object]]
  rm(list = loaded, envir = environment)
  invisible(gc())
  if (
    !is.data.frame(object) ||
      nrow(object) != 22L ||
      !all(c("name", "type", "data") %in% names(object))
  ) {
    abort_pipeline("Frozen baseline metric object is structurally invalid")
  }
  object
}

preanalysis_read_metric_values <- function(path, placement) {
  data <- readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    col_types = readr::cols(
      local_date = readr::col_date(),
      .default = readr::col_guess()
    )
  )
  assert_columns(
    data,
    c(
      "site",
      "Id",
      "position",
      "local_date",
      "analysis_unit",
      "metric",
      "value",
      "estimable"
    ),
    object = paste0(placement, " canonical metric values")
  )
  if (any(data$position != placement)) {
    abort_pipeline("Canonical metric values contain another placement")
  }
  data
}

preanalysis_baseline_source_data <- function(
  baseline,
  specification
) {
  if (specification$domain[[1L]] == "light_metric") {
    row <- which(
      as.character(baseline$name) == specification$baseline_variable[[1L]]
    )
  } else if (specification$analysis_unit[[1L]] == "participant") {
    row <- which(as.character(baseline$name) == "interdaily_stability")
  } else {
    row <- which(as.character(baseline$name) == "Mean")
  }
  if (length(row) != 1L) {
    abort_pipeline(
      "Frozen baseline source cannot identify `%s` exactly once",
      specification$variable_id[[1L]]
    )
  }
  data <- baseline$data[[row]]
  if (!is.data.frame(data)) {
    abort_pipeline("Frozen baseline nested input is not a data frame")
  }
  data
}

preanalysis_baseline_rows <- function(
  baseline,
  specification,
  placement
) {
  data <- preanalysis_baseline_source_data(baseline, specification)
  value_column <- if (specification$domain[[1L]] == "light_metric") {
    "metric"
  } else {
    specification$baseline_variable[[1L]]
  }
  assert_columns(
    data,
    c("site", "Id", value_column),
    object = "frozen baseline nested input"
  )
  local_date <- if (specification$analysis_unit[[1L]] == "participant") {
    NULL
  } else {
    assert_columns(data, "Date", object = "frozen baseline day input")
    as.Date(as.character(data$Date))
  }
  preanalysis_value_rows(
    data = data,
    specification = specification,
    series = "baseline",
    placement = placement,
    value = data[[value_column]],
    local_date = local_date,
    estimable = !is.na(data[[value_column]])
  )
}

preanalysis_canonical_rows <- function(
  specification,
  placement,
  inputs
) {
  source <- specification$canonical_source[[1L]]
  variable <- specification$canonical_variable[[1L]]
  if (identical(source, "metric_values_long")) {
    data <- inputs$metric_values[[placement]]
    data <- data[data$metric == variable, , drop = FALSE]
    if (nrow(data) == 0L) {
      abort_pipeline("Canonical metric is absent: %s", variable)
    }
    return(preanalysis_value_rows(
      data = data,
      specification = specification,
      series = "canonical",
      placement = placement,
      value = data$value,
      local_date = if (specification$analysis_unit[[1L]] == "participant") {
        NULL
      } else {
        data$local_date
      },
      estimable = data$estimable
    ))
  }
  if (identical(source, "grid_30_minute")) {
    data <- inputs$grid_30_minute[[placement]]
    return(preanalysis_value_rows(
      data = data,
      specification = specification,
      series = "canonical",
      placement = placement,
      value = data[[variable]],
      local_date = data$local_date,
      subkey = sprintf("%04d", as.integer(data$clock_bin)),
      estimable = data$bin_admissible
    ))
  }
  if (identical(source, "grid_one_hour")) {
    data <- inputs$grid_one_hour[[placement]]
    assert_columns(
      data,
      variable,
      object = "canonical one-hour base input"
    )
    return(preanalysis_value_rows(
      data = data,
      specification = specification,
      series = "canonical",
      placement = placement,
      value = data[[variable]],
      local_date = data$local_date,
      subkey = sprintf("%04d", as.integer(data$clock_minute)),
      estimable = if (variable == "metric_value_lx") {
        data$bin_admissible
      } else {
        rep(TRUE, nrow(data))
      }
    ))
  }
  if (identical(source, "participant_enriched")) {
    data <- inputs$participant_enriched[[placement]]
    assert_columns(data, variable, object = "canonical participant input")
    return(preanalysis_value_rows(
      data = data,
      specification = specification,
      series = "canonical",
      placement = placement,
      value = data[[variable]]
    ))
  }
  if (identical(source, "participant_day_enriched")) {
    data <- inputs$participant_day_enriched[[placement]]
    assert_columns(data, variable, object = "canonical participant-day input")
    return(preanalysis_value_rows(
      data = data,
      specification = specification,
      series = "canonical",
      placement = placement,
      value = data[[variable]],
      local_date = data$local_date
    ))
  }
  if (source %in% c("exercise_diary", "sleep_diary")) {
    data <- inputs$normalized[[source]]
    assert_columns(data, variable, object = paste0(source, " input"))
    local_date <- if (identical(source, "exercise_diary")) {
      as.Date(data$Date)
    } else {
      wake_date <- as.Date(data$wake_local_label)
      fallback_date <- as.Date(data$sleepprep_local_label) + 1
      ifelse(is.na(wake_date), fallback_date, wake_date) |>
        as.Date(origin = "1970-01-01")
    }
    return(preanalysis_value_rows(
      data = data,
      specification = specification,
      series = "canonical",
      placement = "all",
      value = data[[variable]],
      local_date = local_date
    ))
  }
  if (identical(source, "light_diary")) {
    data <- inputs$normalized$light_diary
    assert_columns(
      data,
      c(variable, "source_row", "interval_analysis_eligible"),
      object = "canonical light-diary input"
    )
    return(preanalysis_value_rows(
      data = data,
      specification = specification,
      series = "canonical",
      placement = "all",
      value = data[[variable]],
      local_date = as.Date(data$Date),
      subkey = sprintf("%08d", as.integer(data$source_row)),
      estimable = if (
        variable %in%
          c(
            "interval_analysis_eligible",
            "interval_quarantined",
            "interval_issue_code",
            "diary_date_missing"
          )
      ) {
        rep(TRUE, nrow(data))
      } else {
        data$interval_analysis_eligible
      }
    ))
  }
  abort_pipeline("Unknown canonical pre-analysis source: %s", source)
}

preanalysis_compare_variable <- function(
  specification,
  placement,
  baseline,
  inputs
) {
  canonical <- preanalysis_canonical_rows(
    specification,
    placement,
    inputs
  )
  applicable <- specification$comparison_status[[1L]] ==
    "applicable_field_key_mapping"
  baseline_rows <- if (applicable) {
    preanalysis_baseline_rows(
      baseline,
      specification,
      placement
    )
  } else {
    NULL
  }
  summaries <- list(
    preanalysis_series_summary(canonical, specification)
  )
  quantiles <- list()
  levels <- list()
  if (specification$value_type[[1L]] == "numeric") {
    quantiles[[1L]] <- preanalysis_numeric_quantiles(
      canonical,
      specification
    )
  } else {
    levels[[1L]] <- preanalysis_categorical_levels(
      canonical,
      specification
    )
  }
  if (applicable) {
    summaries[[2L]] <- preanalysis_series_summary(
      baseline_rows,
      specification
    )
    if (specification$value_type[[1L]] == "numeric") {
      quantiles[[2L]] <- preanalysis_numeric_quantiles(
        baseline_rows,
        specification
      )
    } else {
      levels[[2L]] <- preanalysis_categorical_levels(
        baseline_rows,
        specification
      )
    }
  }
  list(
    summary = do.call(rbind, summaries),
    quantiles = if (length(quantiles) > 0L) {
      do.call(rbind, quantiles)
    } else {
      NULL
    },
    levels = if (length(levels) > 0L) do.call(rbind, levels) else NULL,
    key_reconciliation = preanalysis_reconcile_keys(
      baseline_rows,
      canonical,
      specification
    ),
    paired = preanalysis_paired_summary(
      baseline_rows,
      canonical,
      specification
    ),
    shape = preanalysis_distribution_shape(
      baseline_rows,
      canonical,
      specification
    )
  )
}

preanalysis_load_inputs <- function(input_paths) {
  list(
    baseline = stats::setNames(
      lapply(preanalysis_placements(), function(placement) {
        preanalysis_load_baseline(
          input_paths$baseline[[placement]],
          placement
        )
      }),
      preanalysis_placements()
    ),
    metric_values = stats::setNames(
      Map(
        preanalysis_read_metric_values,
        path = unname(input_paths$metric_values),
        placement = names(input_paths$metric_values)
      ),
      names(input_paths$metric_values)
    ),
    participant_enriched = lapply(
      input_paths$participant_enriched,
      readRDS
    ),
    participant_day_enriched = lapply(
      input_paths$participant_day_enriched,
      readRDS
    ),
    grid_30_minute = lapply(input_paths$grid_30_minute, readRDS),
    grid_one_hour = lapply(input_paths$grid_one_hour, readRDS),
    normalized = lapply(input_paths$normalized, readRDS)
  )
}

preanalysis_assert_discarded_metric_firewall <- function(
  inputs,
  crosswalk,
  tables = NULL
) {
  prohibited_metric <- preanalysis_discarded_clock_metric_ids()
  prohibited_variable <- preanalysis_discarded_clock_variable_ids()
  prohibited_column <- preanalysis_discarded_clock_base_columns()
  if (
    any(prohibited_metric %in% crosswalk$metric_id) ||
      any(prohibited_variable %in% crosswalk$variable_id)
  ) {
    abort_pipeline(
      "Discarded M10/L10 onset/offset entered the comparison registry"
    )
  }
  leaked_column <- unique(unlist(lapply(
    inputs$participant_day_enriched,
    function(data) intersect(names(data), prohibited_column)
  )))
  if (length(leaked_column) > 0L) {
    abort_pipeline(
      "Discarded M10/L10 onset/offset entered model-ready base data: %s",
      paste(leaked_column, collapse = ", ")
    )
  }
  if (!is.null(tables)) {
    leaked_table <- names(tables)[vapply(
      tables,
      function(data) {
        is.data.frame(data) &&
          "variable_id" %in% names(data) &&
          any(prohibited_variable %in% data$variable_id)
      },
      logical(1)
    )]
    if (length(leaked_table) > 0L) {
      abort_pipeline(
        "Discarded M10/L10 onset/offset entered comparison output: %s",
        paste(leaked_table, collapse = ", ")
      )
    }
  }
  invisible(TRUE)
}

preanalysis_bind_non_null <- function(results, element) {
  value <- lapply(results, `[[`, element)
  value <- value[!vapply(value, is.null, logical(1))]
  if (length(value) == 0L) {
    return(data.frame())
  }
  result <- do.call(rbind, value)
  rownames(result) <- NULL
  result
}

preanalysis_build_tables <- function(inputs, crosswalk) {
  results <- list()
  index <- 0L
  for (row in seq_len(nrow(crosswalk))) {
    specification <- crosswalk[row, , drop = FALSE]
    placements <- if (
      specification$canonical_source[[1L]] %in%
        c("exercise_diary", "sleep_diary", "light_diary")
    ) {
      "all"
    } else {
      preanalysis_placements()
    }
    for (placement in placements) {
      index <- index + 1L
      baseline <- if (placement %in% preanalysis_placements()) {
        inputs$baseline[[placement]]
      } else {
        NULL
      }
      results[[index]] <- preanalysis_compare_variable(
        specification,
        placement,
        baseline,
        inputs
      )
    }
  }
  series_summary <- preanalysis_bind_non_null(results, "summary")
  numeric_quantiles <- preanalysis_bind_non_null(results, "quantiles")
  categorical_levels <- preanalysis_bind_non_null(results, "levels")
  key_reconciliation <- preanalysis_bind_non_null(
    results,
    "key_reconciliation"
  )
  paired <- preanalysis_bind_non_null(results, "paired")
  shape <- preanalysis_bind_non_null(results, "shape")
  order_key <- match(series_summary$variable_id, crosswalk$variable_id)
  series_summary <- series_summary[
    order(order_key, series_summary$placement, series_summary$series),
    ,
    drop = FALSE
  ]
  numeric_quantiles <- numeric_quantiles[
    order(
      match(numeric_quantiles$variable_id, crosswalk$variable_id),
      numeric_quantiles$placement,
      numeric_quantiles$series,
      numeric_quantiles$probability
    ),
    ,
    drop = FALSE
  ]
  categorical_levels <- categorical_levels[
    order(
      match(categorical_levels$variable_id, crosswalk$variable_id),
      categorical_levels$placement,
      categorical_levels$series,
      categorical_levels$level
    ),
    ,
    drop = FALSE
  ]
  list(
    series_summary = series_summary,
    numeric_quantiles = numeric_quantiles,
    categorical_levels = categorical_levels,
    key_reconciliation = key_reconciliation,
    paired = paired,
    shape = shape,
    overview = preanalysis_comparison_overview(
      series_summary,
      shape,
      key_reconciliation,
      paired,
      crosswalk
    ),
    numeric_figure_data = preanalysis_numeric_figure_data(
      numeric_quantiles,
      crosswalk
    ),
    categorical_figure_data = preanalysis_categorical_figure_data(
      categorical_levels,
      crosswalk
    )
  )
}

preanalysis_save_plot <- function(plot, path, width, height) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path),
    fileext = ".png"
  )
  on.exit(unlink(temporary), add = TRUE)
  ggplot2::ggsave(
    filename = temporary,
    plot = plot,
    device = "png",
    width = width,
    height = height,
    units = "in",
    dpi = 180,
    bg = "white"
  )
  atomic_replace_artifact(temporary, path)
  invisible(path)
}

preanalysis_numeric_plot <- function(data) {
  plot_data <- data
  plot_data$axis_key <- paste0(
    sprintf("%04d", plot_data$variable_order),
    "__",
    plot_data$variable_id
  )
  axis_label <- unique(
    plot_data[c("axis_key", "manuscript_name", "variant_label")]
  )
  duplicate_manuscript_name <-
    duplicated(axis_label$manuscript_name) |
    duplicated(axis_label$manuscript_name, fromLast = TRUE)
  axis_label$display_label <- axis_label$manuscript_name
  axis_label$display_label[duplicate_manuscript_name] <- paste(
    axis_label$manuscript_name[duplicate_manuscript_name],
    axis_label$variant_label[duplicate_manuscript_name],
    sep = " — "
  )
  plot_data$series <- factor(
    plot_data$series,
    levels = c("baseline", "canonical")
  )
  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$standardized_value,
      y = stats::reorder(.data$axis_key, -.data$variable_order),
      colour = .data$series,
      group = interaction(.data$series, .data$variable_id)
    )
  ) +
    ggplot2::geom_line(linewidth = 0.35, alpha = 0.75) +
    ggplot2::geom_point(
      ggplot2::aes(shape = factor(.data$probability)),
      size = 1.1
    ) +
    ggplot2::geom_vline(
      xintercept = 0,
      colour = "grey70",
      linewidth = 0.3
    ) +
    ggplot2::facet_grid(
      rows = ggplot2::vars(.data$manuscript_category),
      cols = ggplot2::vars(.data$placement),
      scales = "free_y",
      space = "free_y"
    ) +
    ggplot2::scale_colour_manual(
      values = c(baseline = "#6B7280", canonical = "#0072B2"),
      labels = c(
        baseline = "Manuscript-prepared",
        canonical = "Main analysis"
      ),
      drop = FALSE
    ) +
    ggplot2::scale_y_discrete(
      labels = stats::setNames(
        axis_label$display_label,
        axis_label$axis_key
      )
    ) +
    ggplot2::labs(
      x = "Quantiles standardized to the main-analysis median and IQR",
      y = NULL,
      colour = "Series",
      shape = "Quantile",
      title = "Numeric distribution overview",
      subtitle = paste(
        "Points show 5th, 25th, 50th, 75th and 95th percentiles;",
        "native values and units are in the paired source CSV."
      )
    ) +
    ggplot2::theme_minimal(base_size = 8) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      strip.text.y = ggplot2::element_text(angle = 0)
    )
}

preanalysis_categorical_plot <- function(data) {
  plot_data <- data
  plot_data$display_level <- paste(
    plot_data$manuscript_name,
    plot_data$level,
    sep = " — "
  )
  plot_data$series <- factor(
    plot_data$series,
    levels = c("baseline", "canonical")
  )
  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$proportion,
      y = stats::reorder(
        .data$display_level,
        -.data$variable_order
      ),
      colour = .data$series,
      shape = .data$series
    )
  ) +
    ggplot2::geom_point(size = 1.3, alpha = 0.9) +
    ggplot2::facet_grid(
      rows = ggplot2::vars(.data$manuscript_category),
      cols = ggplot2::vars(.data$placement),
      scales = "free_y",
      space = "free_y"
    ) +
    ggplot2::scale_x_continuous(
      labels = scales::label_percent(accuracy = 1)
    ) +
    ggplot2::scale_colour_manual(
      values = c(baseline = "#6B7280", canonical = "#D55E00"),
      labels = c(
        baseline = "Manuscript-prepared",
        canonical = "Main analysis"
      ),
      drop = FALSE
    ) +
    ggplot2::scale_shape_manual(
      values = c(baseline = 16, canonical = 17),
      labels = c(
        baseline = "Manuscript-prepared",
        canonical = "Main analysis"
      ),
      drop = FALSE
    ) +
    ggplot2::labs(
      x = "Proportion among estimable rows",
      y = NULL,
      colour = "Series",
      shape = "Series",
      title = "Categorical distribution overview",
      subtitle = paste(
        "Up to eight most frequent levels per variable and series;",
        "complete level counts are in the paired source CSV."
      )
    ) +
    ggplot2::theme_minimal(base_size = 7) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      strip.text.y = ggplot2::element_text(angle = 0)
    )
}

preanalysis_write_audit_report <- function(
  path,
  metadata,
  crosswalk,
  tables
) {
  non_applicable_metric <- crosswalk[
    crosswalk$domain == "light_metric" &
      crosswalk$comparison_status == "not_applicable_no_field_key_mapping",
    ,
    drop = FALSE
  ]
  non_applicable_label <- paste0(
    non_applicable_metric$manuscript_name,
    " [",
    non_applicable_metric$variant_label,
    "]"
  )
  line <- c(
    "# Pre-analysis comparison gate",
    "",
    "Status: `PASS`",
    "Runtime: R 4.6.1",
    "",
    "## Stable Preparation 06 inputs",
    "",
    paste0(
      "- Normalization manifest SHA-256: `",
      metadata$normalization_manifest_sha256,
      "`"
    ),
    paste0(
      "- Base-model manifest SHA-256: `",
      metadata$base_manifest_sha256,
      "`"
    ),
    paste0(
      "- Base input-bundle SHA-256: `",
      metadata$base_input_bundle_sha256,
      "`"
    ),
    paste0(
      "- Metric display registry SHA-256: `",
      metadata$metric_display_registry_sha256,
      "`"
    ),
    "- The corrected exercise participant key is reflected in the verified 191-participant union; the obsolete extra key is absent.",
    "",
    "## Scope",
    "",
    paste0(
      "- ",
      sum(crosswalk$domain == "light_metric"),
      " main-analysis light metrics and outcomes are summarized for each placement."
    ),
    paste0(
      "- ",
      sum(crosswalk$domain != "light_metric"),
      paste(
        " key participant, participant-day, participant-hour, and",
        "diary-interval predictor/domain variables are summarized."
      )
    ),
    paste0(
      "- ",
      sum(crosswalk$comparison_status == "applicable_field_key_mapping"),
      paste(
        " variables have directly matching manuscript-prepared fields and",
        " record keys; all other main-analysis variables are explicitly",
        " marked not applicable."
      )
    ),
    "- No participant-level rows, participant identifiers, raw timestamps, or free-text content are exported.",
    "- M10/L10 onset and offset diagnostics are deliberately absent from the analytical registry, comparison rows, figures, and author-facing claims; only their level/mean and midpoint metrics are retained.",
    "",
    "## Outputs and interpretation",
    "",
    "- `comparison_overview.csv` is the compact author-facing wide comparison table, including series n/statistics, key additions/drops, common-key n, paired changes/agreement, and distribution-shape descriptions.",
    "- Manuscript-facing metric names, abbreviations, categories, analytical roles, and variant labels come only from `config/metric_display_registry.csv`; internal snake-case identifiers remain technical join keys.",
    "- `series_summary.csv` contains observation, participant, participant-day, estimability, missingness, mean, median, SD/IQR, key quantiles, zero, and non-finite summaries.",
    "- `categorical_levels.csv` contains complete level counts and proportions; `<missing>` is an explicit level only when a value is missing among rows declared estimable.",
    "- `key_reconciliation.csv` and `paired_comparison_summary.csv` separate key changes from value changes.",
    "- `distribution_shape_summary.csv` reports empirical ECDF, Wasserstein-1, total-variation, and robust linear-shape descriptions without inferential tests or p-values. Its scope is all estimable rows: numeric distances use finite values only, while categorical distances retain missing values as the explicit `<missing>` level.",
    "- All descriptive clock variables use declared linear unwrapped axes. Daytime threshold timings and M10 midpoint use ordinary 0-24 hours; L10 midpoint uses the midnight-centred half-open `[-12, 12)` axis; MSFsc remains linear on its observed post-midnight range.",
    "- Linear paired differences, ECDF/Wasserstein distances, and shape summaries are used for clock variables. Circular-summary and circular-Kuiper fields are deliberately blank.",
    "- Circular behavior remains internal to mean-timing/L10 metric calculation and is reserved for future cyclic clock models; it is not used for these descriptive distributions.",
    "- The standardized numeric quantile figure includes clock metrics on those declared linear axes.",
    "- Every durable PNG has an exact paired figure-data CSV.",
    "- The light-diary predictors are labelled `diary_interval`, not main-analysis outcome hours; 30,199 retained source intervals include 27 explicitly visible quarantined or missing-date rows.",
    "",
    "## Limitations and deliberate non-comparisons",
    "",
    paste0(
      "- Changed/new estimands remain baseline non-applicable: ",
      paste(non_applicable_label, collapse = ", "),
      "."
    ),
    "- Midnight-centred L10 midpoint values subtract 24 hours from values at or after 12:00. This half-open `[-12, 12)` representation must be retained downstream.",
    "- A field/key mapping does not assert computational or estimand equivalence. Repaired light metrics are labelled same nominal construct with changed computation/admissibility and are descriptive only.",
    "- Descriptive distribution distances are not sample-size tests and must not be interpreted as inferential evidence.",
    "",
    "## Rerun hook",
    "",
    "```sh",
    paste(
      "Rscript --vanilla scripts/pipeline/run_preanalysis_comparison.R",
      paste0(
        "--expected-normalization-sha256=",
        metadata$normalization_manifest_sha256
      ),
      paste0(
        "--expected-base-sha256=",
        metadata$base_manifest_sha256
      )
    ),
    "```",
    "",
    "Reopen and rerun this gate after any baseline hash, metric manifest, normalized input, base-model input bundle, crosswalk, transformation, estimand, or summary implementation changes."
  )
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path)
  )
  on.exit(unlink(temporary), add = TRUE)
  writeLines(line, temporary, useBytes = TRUE)
  atomic_replace_artifact(temporary, path)
  invisible(path)
}

preanalysis_manifest_row <- function(
  artifact_id,
  path,
  output_root,
  artifact_type
) {
  dimensions <- if (artifact_type == "csv") {
    preanalysis_file_dimensions(path)
  } else {
    c(rows = NA_integer_, columns = NA_integer_)
  }
  data.frame(
    artifact_id = artifact_id,
    artifact_type = artifact_type,
    path = preanalysis_relative_path(path, output_root),
    sha256 = artifact_sha256(path),
    bytes = unname(file.info(path)$size),
    rows = unname(dimensions[["rows"]]),
    columns = unname(dimensions[["columns"]]),
    producer = "scripts/pipeline/build_preanalysis_comparison.R",
    r_version = "4.6.1",
    status = "PASS",
    stringsAsFactors = FALSE
  )
}

build_preanalysis_comparison_artifacts <- function(
  root = project_root(),
  output_root = root,
  expected_normalization_manifest_sha256,
  expected_base_manifest_sha256
) {
  if (!identical(as.character(getRversion()), "4.6.1")) {
    abort_pipeline(
      "Pre-analysis comparison requires R 4.6.1; found %s",
      as.character(getRversion())
    )
  }
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_root <- normalizePath(
    output_root,
    winslash = "/",
    mustWork = TRUE
  )
  input_paths <- preanalysis_input_paths(root)
  verified <- preanalysis_verify_inputs(
    root,
    input_paths,
    expected_normalization_manifest_sha256,
    expected_base_manifest_sha256
  )
  crosswalk <- preanalysis_attach_metric_display(
    preanalysis_variable_crosswalk(),
    root
  )
  inputs <- preanalysis_load_inputs(input_paths)
  preanalysis_assert_discarded_metric_firewall(inputs, crosswalk)
  tables <- preanalysis_build_tables(inputs, crosswalk)
  preanalysis_assert_discarded_metric_firewall(
    inputs,
    crosswalk,
    tables
  )
  paths <- preanalysis_output_paths(output_root)
  dir.create(paths$diagnostic_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(paths$manifest), recursive = TRUE, showWarnings = FALSE)

  run_metadata <- data.frame(
    field = c(
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
    ),
    value = c(
      "PASS",
      "stable",
      "4.6.1",
      "UTC",
      "main_analysis_minus_manuscript_prepared",
      "descriptive_only_no_inferential_test",
      "FALSE",
      "FALSE",
      "FALSE",
      verified$normalization_manifest_sha256,
      verified$base_manifest_sha256,
      verified$base_input_bundle_sha256,
      verified$metric_display_registry_sha256
    ),
    stringsAsFactors = FALSE
  )
  csv_data <- list(
    input_provenance = verified$provenance,
    variable_crosswalk = crosswalk,
    series_summary = tables$series_summary,
    numeric_quantiles = tables$numeric_quantiles,
    categorical_levels = tables$categorical_levels,
    key_reconciliation = tables$key_reconciliation,
    paired_comparison_summary = tables$paired,
    distribution_shape_summary = tables$shape,
    comparison_overview = tables$overview,
    figure_numeric_distribution_data = tables$numeric_figure_data,
    figure_categorical_distribution_data = tables$categorical_figure_data,
    run_metadata = run_metadata
  )
  for (name in names(csv_data)) {
    write_csv_artifact(
      csv_data[[name]],
      paths$csv[[name]],
      producer = "scripts/pipeline/build_preanalysis_comparison.R"
    )
  }
  preanalysis_save_plot(
    preanalysis_numeric_plot(tables$numeric_figure_data),
    paths$figures[["numeric_distribution_overview"]],
    width = 14,
    height = 18
  )
  preanalysis_save_plot(
    preanalysis_categorical_plot(tables$categorical_figure_data),
    paths$figures[["categorical_distribution_overview"]],
    width = 14,
    height = 20
  )
  preanalysis_write_audit_report(
    paths$audit_report,
    verified,
    crosswalk,
    tables
  )

  manifest_rows <- list()
  index <- 0L
  for (name in names(paths$csv)) {
    index <- index + 1L
    manifest_rows[[index]] <- preanalysis_manifest_row(
      name,
      paths$csv[[name]],
      output_root,
      "csv"
    )
  }
  for (name in names(paths$figures)) {
    index <- index + 1L
    manifest_rows[[index]] <- preanalysis_manifest_row(
      name,
      paths$figures[[name]],
      output_root,
      "png"
    )
  }
  index <- index + 1L
  manifest_rows[[index]] <- preanalysis_manifest_row(
    "audit_report",
    paths$audit_report,
    output_root,
    "md"
  )
  manifest <- do.call(rbind, manifest_rows)
  readr::write_csv(manifest, paths$manifest, na = "")

  list(
    status = "PASS",
    paths = paths,
    manifest = manifest,
    input_provenance = verified$provenance,
    crosswalk = crosswalk,
    tables = tables,
    run_metadata = run_metadata
  )
}
