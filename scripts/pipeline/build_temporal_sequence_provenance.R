# Build H02/H11 true-time sequence provenance without altering wall outcomes.
#
# Source paths_io.R, assertions.R, and temporal_sequence_provenance.R first.

temporal_provenance_input_roles <- function() {
  tibble::tribble(
    ~input_role,
    ~placement,
    ~resolution,
    ~input_kind,
    ~filename,
    "glasses_coverage",
    "glasses",
    "all",
    "coverage",
    "light_glasses_coverage.rds",
    "chest_coverage",
    "chest",
    "all",
    "coverage",
    "light_chest_coverage.rds",
    "glasses_30_minute",
    "glasses",
    "30_minute",
    "metric",
    "metrics_glasses_30_minute.rds",
    "glasses_one_hour",
    "glasses",
    "one_hour",
    "metric",
    "metrics_glasses_one_hour.rds",
    "chest_30_minute",
    "chest",
    "30_minute",
    "metric",
    "metrics_chest_30_minute.rds",
    "chest_one_hour",
    "chest",
    "one_hour",
    "metric",
    "metrics_chest_one_hour.rds"
  )
}

temporal_provenance_default_input_paths <- function(root) {
  paths <- pipeline_paths(root)
  roles <- temporal_provenance_input_roles()
  roots <- ifelse(
    roles$input_kind == "coverage",
    paths$coverage,
    paths$metrics
  )
  stats::setNames(file.path(roots, roles$filename), roles$input_role)
}

temporal_provenance_artifact_paths <- function(root) {
  paths <- pipeline_paths(root)
  output_root <- file.path(paths$model_data, "temporal_provenance")
  list(
    root = normalizePath(root, winslash = "/", mustWork = TRUE),
    output_root = output_root,
    source_bins_rds = file.path(
      output_root,
      "true_utc_source_bins.rds"
    ),
    source_bins_csv = file.path(
      output_root,
      "true_utc_source_bins.csv"
    ),
    wall_links_rds = file.path(
      output_root,
      "wall_outcome_links.rds"
    ),
    wall_links_csv = file.path(
      output_root,
      "wall_outcome_links.csv"
    ),
    manifest = file.path(
      output_root,
      "artifact_manifest.csv"
    )
  )
}

resolve_temporal_provenance_input_paths <- function(input_paths, root) {
  expected <- temporal_provenance_input_roles()$input_role
  if (is.null(input_paths)) {
    input_paths <- temporal_provenance_default_input_paths(root)
  }
  if (
    !is.character(input_paths) ||
      is.null(names(input_paths)) ||
      anyNA(input_paths) ||
      any(!nzchar(input_paths)) ||
      anyDuplicated(names(input_paths)) ||
      !setequal(names(input_paths), expected)
  ) {
    abort_pipeline(
      "`input_paths` must be named exactly: %s",
      paste(expected, collapse = ", ")
    )
  }
  input_paths <- input_paths[expected]
  missing <- !file.exists(input_paths)
  if (any(missing)) {
    abort_pipeline(
      "Temporal-provenance input(s) do not exist: %s",
      paste(input_paths[missing], collapse = ", ")
    )
  }
  vapply(
    input_paths,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
}

temporal_provenance_relative_path <- function(path, anchor, object) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  anchor <- normalizePath(anchor, winslash = "/", mustWork = TRUE)
  prefix <- paste0(anchor, "/")
  if (!startsWith(path, prefix)) {
    abort_pipeline(
      "%s is outside its declared provenance root: %s",
      object,
      path
    )
  }
  substring(path, nchar(prefix) + 1L)
}

normalize_manifest_paths <- function(
  path,
  root,
  object = "Upstream manifest artifact"
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  vapply(
    path,
    function(value) {
      if (is.na(value) || !nzchar(value)) {
        abort_pipeline("%s has a missing or empty path", object)
      }
      candidate <- if (grepl("^/", value)) {
        value
      } else {
        file.path(root, value)
      }
      candidate <- normalizePath(
        candidate,
        winslash = "/",
        mustWork = TRUE
      )
      temporal_provenance_relative_path(
        candidate,
        root,
        object
      )
      candidate
    },
    character(1)
  )
}

verify_temporal_upstream_inputs <- function(input_root, input_paths) {
  input_root <- normalizePath(
    input_root,
    winslash = "/",
    mustWork = TRUE
  )
  paths <- pipeline_paths(input_root)
  manifest_paths <- c(
    coverage = file.path(paths$manifests, "coverage_artifacts.csv"),
    metric = file.path(paths$manifests, "metric_artifacts.csv")
  )
  missing_manifest <- !file.exists(manifest_paths)
  if (any(missing_manifest)) {
    abort_pipeline(
      "Required upstream manifest(s) do not exist: %s",
      paste(manifest_paths[missing_manifest], collapse = ", ")
    )
  }
  manifests <- lapply(manifest_paths, function(path) {
    manifest <- readr::read_csv(
      path,
      show_col_types = FALSE,
      progress = FALSE
    )
    assert_columns(
      manifest,
      c("path", "sha256", "artifact_type"),
      object = basename(path)
    )
    manifest$normalized_path <- normalize_manifest_paths(
      manifest$path,
      input_root,
      object = paste0(basename(path), " artifact")
    )
    manifest
  })
  roles <- temporal_provenance_input_roles()
  audit_rows <- vector("list", nrow(roles))
  for (index in seq_len(nrow(roles))) {
    role <- roles[index, , drop = FALSE]
    input_path <- input_paths[[role$input_role]]
    manifest <- manifests[[role$input_kind]]
    matches <- which(manifest$normalized_path == input_path)
    if (length(matches) != 1L) {
      abort_pipeline(
        "Upstream manifest does not identify `%s` exactly once",
        role$input_role
      )
    }
    manifest_row_data <- manifest[matches, , drop = FALSE]
    expected_type <- if (role$input_kind == "coverage") {
      "coverage_annotated_real_minutes"
    } else if (role$resolution == "30_minute") {
      "complete_30_minute_arithmetic_medi_grid_rds"
    } else {
      "complete_one_hour_geometric_medi_grid_rds"
    }
    actual_hash <- artifact_sha256(input_path)
    manifest_status <- if ("status" %in% names(manifest_row_data)) {
      manifest_row_data$status[[1L]]
    } else {
      NA_character_
    }
    status_invalid <- !is.na(manifest_status) &&
      nzchar(manifest_status) &&
      manifest_status != "PASS"
    if (
      manifest_row_data$artifact_type[[1L]] != expected_type ||
        manifest_row_data$sha256[[1L]] != actual_hash ||
        status_invalid
    ) {
      abort_pipeline(
        "Upstream manifest verification failed for `%s`",
        role$input_role
      )
    }
    audit_rows[[index]] <- tibble::tibble(
      input_role = role$input_role,
      placement = role$placement,
      resolution = role$resolution,
      input_kind = role$input_kind,
      path = temporal_provenance_relative_path(
        input_path,
        input_root,
        paste0("Temporal input `", role$input_role, "`")
      ),
      sha256 = actual_hash,
      manifest_path = temporal_provenance_relative_path(
        manifest_paths[[role$input_kind]],
        input_root,
        paste0(role$input_kind, " upstream manifest")
      ),
      manifest_sha256 = artifact_sha256(
        manifest_paths[[role$input_kind]]
      ),
      status = "PASS"
    )
  }
  dplyr::bind_rows(audit_rows)
}

compact_temporal_input_paths <- function(input_audit, kind) {
  selected <- input_audit |>
    dplyr::filter(.data$input_kind == .env$kind) |>
    dplyr::arrange(.data$input_role)
  paste(
    paste(selected$input_role, selected$path, sep = "="),
    collapse = ";"
  )
}

compact_temporal_input_hashes <- function(input_audit, kind) {
  selected <- input_audit |>
    dplyr::filter(.data$input_kind == .env$kind) |>
    dplyr::arrange(.data$input_role)
  paste(
    paste(selected$input_role, selected$sha256, sep = "="),
    collapse = ";"
  )
}

validate_combined_temporal_provenance <- function(
  source_bins,
  wall_links
) {
  assert_unique_key(
    source_bins,
    c("resolution", temporal_participant_key, "true_utc_start"),
    object = "combined true-UTC source bins"
  )
  assert_unique_key(
    source_bins,
    "source_bin_id",
    object = "combined true-UTC source-bin IDs"
  )
  assert_unique_key(
    wall_links,
    temporal_wall_key,
    object = "combined wall outcome links"
  )
  assert_unique_key(
    wall_links,
    "outcome_row_id",
    object = "combined wall outcome IDs"
  )
  if (
    any(
      source_bins$repeated_fall_back_source_bin &
        source_bins$sequence_eligible
    ) ||
      any(
        !wall_links$one_to_one_elapsed_coordinate &
          wall_links$source_bin_links == 2L &
          wall_links$relationship_type != "two_to_one_averaged_fall_back"
      )
  ) {
    abort_pipeline(
      "A fall-back averaged outcome is sequence-eligible or mislabeled"
    )
  }
  mapped_source <- source_bins |>
    dplyr::count(
      dplyr::across(dplyr::all_of(temporal_wall_key)),
      name = "reconstructed_links"
    )
  link_check <- wall_links |>
    dplyr::left_join(
      mapped_source,
      by = temporal_wall_key,
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      reconstructed_links = dplyr::coalesce(
        .data$reconstructed_links,
        0L
      )
    )
  if (any(link_check$source_bin_links != link_check$reconstructed_links)) {
    abort_pipeline("Combined wall-link cardinalities do not reconcile")
  }
  invisible(TRUE)
}

temporal_provenance_manifest_columns <- function() {
  c(
    "path",
    "sha256",
    "bytes",
    "producer",
    "r_version",
    "artifact_type",
    "run_label",
    "coverage_input_paths",
    "coverage_inputs",
    "metric_input_paths",
    "metric_inputs",
    "coverage_manifest_path",
    "coverage_manifest_sha256",
    "metric_manifest_path",
    "metric_manifest_sha256",
    "sequence_contract",
    "wall_outcome_contract",
    "status",
    "rows",
    "columns"
  )
}

temporal_provenance_manifest_row <- function(metadata, output_root) {
  row <- manifest_row(metadata)
  row$path <- temporal_provenance_relative_path(
    metadata$path,
    output_root,
    "Temporal-provenance output artifact"
  )
  row |>
    dplyr::select(
      dplyr::all_of(temporal_provenance_manifest_columns())
    )
}

build_temporal_sequence_provenance_artifacts <- function(
  root = project_root(),
  input_paths = NULL,
  run_label = "full",
  input_root = root
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  input_root <- normalizePath(
    input_root,
    winslash = "/",
    mustWork = TRUE
  )
  if (
    !is.character(run_label) ||
      length(run_label) != 1L ||
      is.na(run_label) ||
      !nzchar(run_label)
  ) {
    abort_pipeline("`run_label` must be one non-empty string")
  }
  producer <- "scripts/pipeline/build_temporal_sequence_provenance.R"
  output_paths <- temporal_provenance_artifact_paths(root)
  dir.create(
    output_paths$output_root,
    recursive = TRUE,
    showWarnings = FALSE
  )
  input_paths <- resolve_temporal_provenance_input_paths(
    input_paths,
    input_root
  )
  input_audit <- verify_temporal_upstream_inputs(
    input_root,
    input_paths
  )
  roles <- temporal_provenance_input_roles()

  source_outputs <- list()
  link_outputs <- list()
  output_index <- 0L
  for (placement in c("glasses", "chest")) {
    coverage_role <- paste0(placement, "_coverage")
    coverage <- read_rds_artifact(
      input_paths[[coverage_role]],
      expected_class = "data.frame"
    )
    for (resolution in c("30_minute", "one_hour")) {
      output_index <- output_index + 1L
      metric_role <- paste(placement, resolution, sep = "_")
      metric <- read_rds_artifact(
        input_paths[[metric_role]],
        expected_class = "data.frame"
      )
      result <- build_temporal_sequence_provenance(
        coverage = coverage,
        metric = metric,
        placement = placement,
        resolution = resolution
      )
      source_outputs[[output_index]] <- result$source_bins
      link_outputs[[output_index]] <- result$wall_links
    }
    rm(coverage)
    invisible(gc(verbose = FALSE))
  }
  source_bins <- dplyr::bind_rows(source_outputs) |>
    dplyr::arrange(
      .data$resolution,
      .data$site,
      .data$Id,
      .data$position,
      .data$true_utc_start
    )
  wall_links <- dplyr::bind_rows(link_outputs) |>
    dplyr::arrange(
      .data$resolution,
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$wall_bin_start_minute
    )
  attr(source_bins, "metric_settings") <- NULL
  attr(wall_links, "metric_settings") <- NULL
  validate_combined_temporal_provenance(source_bins, wall_links)

  common_metadata <- list(
    run_label = run_label,
    coverage_input_paths = compact_temporal_input_paths(
      input_audit,
      "coverage"
    ),
    coverage_inputs = compact_temporal_input_hashes(
      input_audit,
      "coverage"
    ),
    metric_input_paths = compact_temporal_input_paths(
      input_audit,
      "metric"
    ),
    metric_inputs = compact_temporal_input_hashes(
      input_audit,
      "metric"
    ),
    coverage_manifest_path = unique(
      input_audit$manifest_path[input_audit$input_kind == "coverage"]
    ),
    coverage_manifest_sha256 = unique(
      input_audit$manifest_sha256[input_audit$input_kind == "coverage"]
    ),
    metric_manifest_path = unique(
      input_audit$manifest_path[input_audit$input_kind == "metric"]
    ),
    metric_manifest_sha256 = unique(
      input_audit$manifest_sha256[input_audit$input_kind == "metric"]
    ),
    sequence_contract = "true_utc_adjacency_with_unusable_and_non_one_to_one_breaks",
    wall_outcome_contract = "clock_aligned_values_unchanged",
    status = "PASS"
  )
  artifact_specification <- list(
    list(
      artifact_type = "true_utc_source_bins_rds",
      data = source_bins,
      path = output_paths$source_bins_rds,
      writer = "rds"
    ),
    list(
      artifact_type = "true_utc_source_bins_csv",
      data = temporal_provenance_csv_data(source_bins),
      path = output_paths$source_bins_csv,
      writer = "csv"
    ),
    list(
      artifact_type = "wall_outcome_links_rds",
      data = wall_links,
      path = output_paths$wall_links_rds,
      writer = "rds"
    ),
    list(
      artifact_type = "wall_outcome_links_csv",
      data = temporal_provenance_csv_data(wall_links),
      path = output_paths$wall_links_csv,
      writer = "csv"
    )
  )
  manifest_rows <- vector("list", length(artifact_specification))
  for (index in seq_along(artifact_specification)) {
    specification <- artifact_specification[[index]]
    metadata <- if (specification$writer == "rds") {
      write_rds_artifact(
        specification$data,
        specification$path,
        producer,
        metadata = c(
          list(artifact_type = specification$artifact_type),
          common_metadata,
          list(
            rows = nrow(specification$data),
            columns = ncol(specification$data)
          )
        )
      )
    } else {
      write_csv_artifact(
        specification$data,
        specification$path,
        producer,
        metadata = c(
          list(artifact_type = specification$artifact_type),
          common_metadata
        )
      )
    }
    manifest_rows[[index]] <- temporal_provenance_manifest_row(
      metadata,
      root
    )
  }
  manifest <- dplyr::bind_rows(manifest_rows) |>
    dplyr::arrange(.data$artifact_type)
  write_csv_artifact(
    manifest,
    output_paths$manifest,
    producer,
    metadata = list(
      artifact_type = "temporal_provenance_manifest",
      run_label = run_label,
      status = "PASS"
    )
  )

  list(
    source_bins = source_bins,
    wall_links = wall_links,
    input_audit = input_audit,
    manifest = manifest,
    paths = output_paths
  )
}
