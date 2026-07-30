# Build the manuscript-prepared-data sensitivity inputs without fitting models.
#
# Source paths_io.R, assertions.R, metric_display_registry.R, and
# manuscript_prepared_data.R first.

manuscript_prepared_output_variable_dictionary <- function() {
  dictionary <- manuscript_prepared_variable_dictionary()
  occurrence <- dictionary$variable == "local_occurrence"
  dictionary$definition[occurrence] <- paste(
    "Analytical occurrence key. Repeated fall-back measurements are",
    "averaged within the shared participant local hour, so this is 1."
  )
  dictionary$unit_or_values[occurrence] <- "1"
  dictionary
}

manuscript_prepared_output_metric_mapping <- function(root = project_root()) {
  mapping <- manuscript_prepared_metric_mapping(root)
  mapping$variant_label[
    mapping$metric_id == "dose_time_sensitive_corrected_medi"
  ] <- "Uncorrected manuscript-prepared dose"
  mapping$variant_label[
    mapping$metric_id == "mder_ratio_of_integrals"
  ] <- "Mean of epoch-wise melEDI/illuminance ratios"
  mapping
}

manuscript_prepared_output_paths <- function(
  root = project_root(),
  output_root = root
) {
  scenario_root <- file.path(
    output_root,
    "artifacts",
    "06_model_data",
    "scenarios",
    manuscript_prepared_scenario_id()
  )
  list(
    scenario_root = scenario_root,
    rds = stats::setNames(
      file.path(
        scenario_root,
        paste0(
          c(
            "participant_metrics",
            "participant_day_metrics",
            "thirty_minute_data",
            "one_hour_data",
            "normalized_input_references"
          ),
          ".rds"
        )
      ),
      c(
        "participant_metrics",
        "participant_day_metrics",
        "thirty_minute_data",
        "one_hour_data",
        "normalized_input_references"
      )
    ),
    csv = stats::setNames(
      file.path(
        scenario_root,
        paste0(
          c(
            "participant_metrics",
            "participant_day_metrics",
            "thirty_minute_data",
            "one_hour_data",
            "normalized_input_references",
            "source_manifest",
            "correction_manifest",
            "metric_crosswalk",
            "variable_dictionary"
          ),
          ".csv"
        )
      ),
      c(
        "participant_metrics",
        "participant_day_metrics",
        "thirty_minute_data",
        "one_hour_data",
        "normalized_input_references",
        "source_manifest",
        "correction_manifest",
        "metric_crosswalk",
        "variable_dictionary"
      )
    ),
    manifest = file.path(
      output_root,
      "artifacts",
      "12_manifests",
      "manuscript_prepared_data_artifacts.csv"
    )
  )
}

manuscript_prepared_write_pair <- function(
  data,
  id,
  paths,
  producer
) {
  rds_metadata <- write_rds_artifact(
    data,
    paths$rds[[id]],
    producer = producer
  )
  csv_data <- data
  posix <- vapply(csv_data, inherits, logical(1), what = "POSIXt")
  csv_data[posix] <- lapply(csv_data[posix], function(value) {
    format(value, "%Y-%m-%d %H:%M:%S", tz = "UTC")
  })
  csv_metadata <- write_csv_artifact(
    csv_data,
    paths$csv[[id]],
    producer = producer
  )
  list(
    rds = data.frame(
      artifact_id = paste0(id, "_rds"),
      artifact_type = "rds",
      path = manuscript_prepared_relative_path(rds_metadata$path, paths),
      sha256 = rds_metadata$sha256,
      bytes = as.numeric(rds_metadata$bytes),
      rows = nrow(data),
      columns = ncol(data),
      stringsAsFactors = FALSE
    ),
    csv = data.frame(
      artifact_id = paste0(id, "_csv"),
      artifact_type = "csv",
      path = manuscript_prepared_relative_path(csv_metadata$path, paths),
      sha256 = csv_metadata$sha256,
      bytes = as.numeric(csv_metadata$bytes),
      rows = nrow(csv_data),
      columns = ncol(csv_data),
      stringsAsFactors = FALSE
    )
  )
}

manuscript_prepared_relative_path <- function(path, paths) {
  output_root <- dirname(dirname(paths$scenario_root))
  output_root <- dirname(dirname(output_root))
  normalized_path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  normalized_root <- normalizePath(
    output_root,
    winslash = "/",
    mustWork = TRUE
  )
  prefix <- paste0(normalized_root, "/")
  if (!startsWith(normalized_path, prefix)) {
    abort_pipeline("Scenario output escaped the declared output root")
  }
  substring(normalized_path, nchar(prefix) + 1L)
}

manuscript_prepared_manifest_row <- function(
  artifact_id,
  artifact_type,
  path,
  data,
  output_root
) {
  full_path <- file.path(output_root, path)
  data.frame(
    artifact_id = artifact_id,
    artifact_type = artifact_type,
    path = path,
    sha256 = artifact_sha256(full_path),
    bytes = as.numeric(file.info(full_path)$size),
    rows = nrow(data),
    columns = ncol(data),
    stringsAsFactors = FALSE
  )
}

build_manuscript_prepared_data <- function(
  root = project_root(),
  output_root = root
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_root <- normalizePath(output_root, winslash = "/", mustWork = TRUE)
  paths <- manuscript_prepared_output_paths(root, output_root)
  dir.create(paths$scenario_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(paths$manifest), recursive = TRUE, showWarnings = FALSE)

  sources <- manuscript_prepared_load_sources(root)
  mapping <- manuscript_prepared_output_metric_mapping(root)
  references <- manuscript_prepared_normalized_input_references(root)
  correction_manifest <- manuscript_prepared_correction_manifest(root)

  participant <- list()
  participant_day <- list()
  thirty_minute <- list()
  one_hour <- list()

  for (position in manuscript_prepared_positions()) {
    nested <- sources$objects[[paste0("metrics_", position)]][[
      paste0("metrics_", position)
    ]]
    separate <- sources$objects[[paste0("metrics_separate_", position)]]
    preprocessed <- sources$objects[[paste0("preprocessed_", position, "_2")]][[
      paste0("light_", position, "_processed2")
    ]]

    participant[[position]] <- manuscript_prepared_extract_metric_rows(
      nested,
      mapping,
      position,
      analysis_unit = "participant"
    )
    participant_day[[position]] <- manuscript_prepared_extract_metric_rows(
      nested,
      mapping,
      position,
      analysis_unit = "participant_day"
    )
    thirty_source <- separate[[
      paste0("metric_", position, "_participanthour")
    ]] |>
      manuscript_prepared_add_occurrence()
    thirty_minute[[position]] <- manuscript_prepared_normalize_clock_data(
      thirty_source,
      position,
      analysis_unit = "30_minute"
    )
    hourly_source <- manuscript_prepared_build_one_hour(preprocessed)
    one_hour[[position]] <- manuscript_prepared_normalize_clock_data(
      hourly_source,
      position,
      analysis_unit = "one_hour"
    )
  }

  outputs <- list(
    participant_metrics = dplyr::bind_rows(participant),
    participant_day_metrics = dplyr::bind_rows(participant_day),
    thirty_minute_data = dplyr::bind_rows(thirty_minute),
    one_hour_data = dplyr::bind_rows(one_hour),
    normalized_input_references = references
  )
  producer <- "scripts/pipeline/build_manuscript_prepared_data.R"
  manifest_rows <- list()
  for (id in names(outputs)) {
    metadata <- manuscript_prepared_write_pair(
      outputs[[id]],
      id,
      paths,
      producer
    )
    manifest_rows <- c(manifest_rows, unname(metadata))
  }

  source_manifest <- dplyr::bind_rows(sources$manifest, references)
  csv_only <- list(
    source_manifest = source_manifest,
    correction_manifest = correction_manifest,
    metric_crosswalk = mapping,
    variable_dictionary = manuscript_prepared_output_variable_dictionary()
  )
  for (id in names(csv_only)) {
    metadata <- write_csv_artifact(
      csv_only[[id]],
      paths$csv[[id]],
      producer = producer
    )
    relative_path <- manuscript_prepared_relative_path(metadata$path, paths)
    manifest_rows[[length(manifest_rows) + 1L]] <-
      manuscript_prepared_manifest_row(
        artifact_id = paste0(id, "_csv"),
        artifact_type = "csv",
        path = relative_path,
        data = csv_only[[id]],
        output_root = output_root
      )
  }

  artifact_manifest <- dplyr::bind_rows(manifest_rows) |>
    dplyr::mutate(
      scenario_id = manuscript_prepared_scenario_id(),
      model_implementation_id = manuscript_prepared_model_implementation_id(),
      producer = producer,
      .before = 1L
    ) |>
    dplyr::arrange(.data$artifact_id)
  write_csv_artifact(
    artifact_manifest,
    paths$manifest,
    producer = producer
  )

  invisible(
    list(
      paths = paths,
      outputs = outputs,
      source_manifest = source_manifest,
      correction_manifest = correction_manifest,
      metric_crosswalk = mapping,
      artifact_manifest = artifact_manifest
    )
  )
}
