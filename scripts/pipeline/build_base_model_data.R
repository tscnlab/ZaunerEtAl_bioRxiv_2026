# Build Preparation 06 canonical base-model data and audit artifacts.
#
# Source paths_io.R, assertions.R, and base_model_data.R before this file.

resolve_base_model_named_paths <- function(
  paths,
  expected_names,
  argument
) {
  if (
    !is.character(paths) ||
      is.null(names(paths)) ||
      anyNA(paths) ||
      any(!nzchar(paths)) ||
      anyDuplicated(names(paths)) ||
      !setequal(names(paths), expected_names)
  ) {
    abort_pipeline(
      "`%s` must be named exactly: %s",
      argument,
      paste(expected_names, collapse = ", ")
    )
  }
  paths <- paths[expected_names]
  missing <- !file.exists(paths)
  if (any(missing)) {
    abort_pipeline(
      "Required `%s` input(s) do not exist: %s",
      argument,
      paste(paths[missing], collapse = ", ")
    )
  }
  vapply(
    paths,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
}

resolve_base_model_scalar_path <- function(path, argument) {
  if (
    !is.character(path) ||
      length(path) != 1L ||
      is.na(path) ||
      !nzchar(path)
  ) {
    abort_pipeline("`%s` must be one non-empty path", argument)
  }
  if (!file.exists(path)) {
    abort_pipeline("Required `%s` input does not exist: %s", argument, path)
  }
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

base_model_declared_absolute_path <- function(path, root) {
  vapply(
    path,
    function(value) {
      candidate <- if (grepl("^/", value)) {
        value
      } else {
        file.path(root, value)
      }
      normalizePath(candidate, winslash = "/", mustWork = TRUE)
    },
    character(1)
  )
}

base_model_relative_path <- function(path, anchor) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  anchor <- normalizePath(anchor, winslash = "/", mustWork = TRUE)
  prefix <- paste0(anchor, "/")
  if (startsWith(path, prefix)) {
    return(substring(path, nchar(prefix) + 1L))
  }
  path
}

base_model_text_sha256 <- function(text) {
  if (
    !is.character(text) ||
      length(text) != 1L ||
      is.na(text)
  ) {
    abort_pipeline("Text provenance hash input must be one string")
  }
  unname(unclass(as.character(openssl::sha256(charToRaw(text)))))
}

base_model_verify_upstream_inputs <- function(
  root,
  metric_specification,
  normalized_specification,
  metric_paths,
  normalized_paths,
  context_path,
  manifest_paths
) {
  metric_manifest <- readr::read_csv(
    manifest_paths[["metrics"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  normalization_manifest <- readr::read_csv(
    manifest_paths[["normalization"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  context_manifest <- readr::read_csv(
    manifest_paths[["site_context"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  assert_columns(
    metric_manifest,
    c("path", "sha256", "artifact_type", "placement", "r_version"),
    object = "metric artifact manifest"
  )
  assert_columns(
    normalization_manifest,
    c(
      "artifact_id",
      "path",
      "sha256",
      "r_version",
      "rows",
      "columns"
    ),
    object = "normalization artifact manifest"
  )
  assert_columns(
    context_manifest,
    c(
      "artifact_type",
      "path",
      "sha256",
      "r_version",
      "rows",
      "columns",
      "status"
    ),
    object = "site-context artifact manifest"
  )
  metric_manifest$.absolute_path <- base_model_declared_absolute_path(
    metric_manifest$path,
    root
  )
  normalization_manifest$.absolute_path <-
    base_model_declared_absolute_path(
      normalization_manifest$path,
      root
    )
  context_manifest$.absolute_path <- base_model_declared_absolute_path(
    context_manifest$path,
    root
  )
  manifest_hashes <- vapply(
    manifest_paths,
    artifact_sha256,
    character(1)
  )
  provenance <- list()
  row_index <- 0L

  for (index in seq_len(nrow(metric_specification))) {
    specification <- metric_specification[index, , drop = FALSE]
    input_id <- specification$input_id[[1L]]
    path <- metric_paths[[input_id]]
    matches <- which(metric_manifest$.absolute_path == path)
    if (length(matches) != 1L) {
      abort_pipeline(
        "Metric manifest must identify `%s` exactly once",
        input_id
      )
    }
    manifest_row_data <- metric_manifest[matches, , drop = FALSE]
    actual_hash <- artifact_sha256(path)
    if (
      manifest_row_data$artifact_type[[1L]] !=
        specification$artifact_type[[1L]] ||
        manifest_row_data$placement[[1L]] != specification$placement[[1L]] ||
        manifest_row_data$r_version[[1L]] != "4.6.1" ||
        manifest_row_data$sha256[[1L]] != actual_hash
    ) {
      abort_pipeline(
        "Metric manifest provenance failed for `%s`",
        input_id
      )
    }
    object <- readRDS(path)
    if (!is.data.frame(object)) {
      abort_pipeline("Metric input `%s` is not a data frame", input_id)
    }
    input_bytes <- unname(file.info(path)$size)
    row_index <- row_index + 1L
    provenance[[row_index]] <- tibble::tibble(
      input_id = input_id,
      input_kind = "metric_rds",
      placement = specification$placement[[1L]],
      resolution = specification$resolution[[1L]],
      modality = NA_character_,
      path = base_model_relative_path(path, root),
      sha256 = actual_hash,
      bytes = input_bytes,
      rows = nrow(object),
      columns = ncol(object),
      upstream_artifact_id = manifest_row_data$artifact_type[[1L]],
      upstream_manifest_path = base_model_relative_path(
        manifest_paths[["metrics"]],
        root
      ),
      upstream_manifest_sha256 = manifest_hashes[["metrics"]],
      upstream_declared_sha256 = manifest_row_data$sha256[[1L]],
      upstream_r_version = manifest_row_data$r_version[[1L]],
      status = "PASS"
    )
  }

  context_matches <- which(
    context_manifest$.absolute_path == context_path &
      context_manifest$artifact_type == "site_solar_context_rds"
  )
  if (length(context_matches) != 1L) {
    abort_pipeline(
      "Site-context manifest must identify its canonical RDS exactly once"
    )
  }
  context_row <- context_manifest[context_matches, , drop = FALSE]
  context_hash <- artifact_sha256(context_path)
  context_status <- context_row$status[[1L]]
  if (
    context_row$sha256[[1L]] != context_hash ||
      context_row$r_version[[1L]] != "4.6.1" ||
      !identical(context_status, "PASS")
  ) {
    abort_pipeline("Canonical site-context provenance failed")
  }
  context <- readRDS(context_path)
  if (!is.data.frame(context)) {
    abort_pipeline("Canonical site context is not a data frame")
  }
  row_index <- row_index + 1L
  provenance[[row_index]] <- tibble::tibble(
    input_id = "site_solar_context",
    input_kind = "context_rds",
    placement = NA_character_,
    resolution = "site_date",
    modality = NA_character_,
    path = base_model_relative_path(context_path, root),
    sha256 = context_hash,
    bytes = unname(file.info(context_path)$size),
    rows = nrow(context),
    columns = ncol(context),
    upstream_artifact_id = "site_solar_context_rds",
    upstream_manifest_path = base_model_relative_path(
      manifest_paths[["site_context"]],
      root
    ),
    upstream_manifest_sha256 = manifest_hashes[["site_context"]],
    upstream_declared_sha256 = context_row$sha256[[1L]],
    upstream_r_version = context_row$r_version[[1L]],
    status = "PASS"
  )

  for (index in seq_len(nrow(normalized_specification))) {
    specification <- normalized_specification[index, , drop = FALSE]
    modality <- specification$modality[[1L]]
    path <- normalized_paths[[modality]]
    matches <- which(
      normalization_manifest$artifact_id == specification$artifact_id[[1L]] &
        normalization_manifest$.absolute_path == path
    )
    if (length(matches) != 1L) {
      abort_pipeline(
        "Normalization manifest must identify `%s` exactly once",
        modality
      )
    }
    manifest_row_data <- normalization_manifest[matches, , drop = FALSE]
    actual_hash <- artifact_sha256(path)
    if (
      manifest_row_data$sha256[[1L]] != actual_hash ||
        manifest_row_data$r_version[[1L]] != "4.6.1"
    ) {
      abort_pipeline(
        "Normalization manifest provenance failed for `%s`",
        modality
      )
    }
    object <- readRDS(path)
    if (
      !is.data.frame(object) ||
        nrow(object) != manifest_row_data$rows[[1L]] ||
        ncol(object) != manifest_row_data$columns[[1L]]
    ) {
      abort_pipeline(
        "Normalized `%s` dimensions differ from its manifest",
        modality
      )
    }
    input_bytes <- unname(file.info(path)$size)
    row_index <- row_index + 1L
    provenance[[row_index]] <- tibble::tibble(
      input_id = paste0("normalized_", modality),
      input_kind = "normalized_rds",
      placement = NA_character_,
      resolution = NA_character_,
      modality = modality,
      path = base_model_relative_path(path, root),
      sha256 = actual_hash,
      bytes = input_bytes,
      rows = nrow(object),
      columns = ncol(object),
      upstream_artifact_id = manifest_row_data$artifact_id[[1L]],
      upstream_manifest_path = base_model_relative_path(
        manifest_paths[["normalization"]],
        root
      ),
      upstream_manifest_sha256 = manifest_hashes[["normalization"]],
      upstream_declared_sha256 = manifest_row_data$sha256[[1L]],
      upstream_r_version = manifest_row_data$r_version[[1L]],
      status = "PASS"
    )
  }
  input_provenance <- dplyr::bind_rows(provenance)
  list(
    input_provenance = input_provenance,
    manifest_hashes = manifest_hashes
  )
}

base_model_identity_audit <- function(
  data,
  input_id,
  placement,
  resolution
) {
  key <- base_model_metric_key(resolution)
  tibble::tibble(
    input_id = input_id,
    placement = placement,
    resolution = resolution,
    stage = "canonical_identity_copy",
    join_key = NA_character_,
    relationship = "identity",
    input_rows = nrow(data),
    output_rows = nrow(data),
    input_unique_keys = nrow(unique(data[key])),
    output_unique_keys = nrow(unique(data[key])),
    missing_key_rows = sum(!stats::complete.cases(data[key])),
    duplicated_key_rows = sum(
      duplicated(data[key]) |
        duplicated(data[key], fromLast = TRUE)
    ),
    unmatched_rows = 0L,
    row_order_preserved = TRUE,
    key_set_preserved = TRUE,
    status = "PASS"
  )
}

base_model_output_manifest_columns <- function() {
  c(
    "artifact_id",
    "artifact_type",
    "path",
    "sha256",
    "bytes",
    "rows",
    "columns",
    "input_bundle_sha256",
    "metric_manifest_sha256",
    "normalization_manifest_sha256",
    "site_context_manifest_sha256",
    "producer",
    "r_version",
    "status"
  )
}

base_model_manifest_row <- function(
  metadata,
  artifact_id,
  artifact_type,
  paths,
  input_bundle_sha256,
  manifest_hashes,
  producer
) {
  tibble::tibble(
    artifact_id = artifact_id,
    artifact_type = artifact_type,
    path = base_model_relative_path(
      metadata$path,
      paths$output_root
    ),
    sha256 = metadata$sha256,
    bytes = metadata$bytes,
    rows = metadata$rows,
    columns = metadata$columns,
    input_bundle_sha256 = input_bundle_sha256,
    metric_manifest_sha256 = manifest_hashes[["metrics"]],
    normalization_manifest_sha256 = manifest_hashes[["normalization"]],
    site_context_manifest_sha256 = manifest_hashes[["site_context"]],
    producer = producer,
    r_version = as.character(getRversion()),
    status = "PASS"
  )
}

build_base_model_data_artifacts <- function(
  root = project_root(),
  output_root = root,
  metric_paths = NULL,
  normalized_paths = NULL,
  context_path = file.path(
    root,
    "artifacts",
    "06_model_data",
    "context",
    "site_solar_context.rds"
  ),
  manifest_paths = base_model_input_manifest_paths(root)
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_root <- normalizePath(
    output_root,
    winslash = "/",
    mustWork = TRUE
  )
  if (!identical(as.character(getRversion()), "4.6.1")) {
    abort_pipeline(
      "Base-model data must be built under R 4.6.1; found %s",
      as.character(getRversion())
    )
  }
  metric_specification <- base_model_metric_specification(root)
  normalized_specification <- base_model_normalized_specification(root)
  if (is.null(metric_paths)) {
    metric_paths <- stats::setNames(
      metric_specification$path,
      metric_specification$input_id
    )
  }
  if (is.null(normalized_paths)) {
    normalized_paths <- stats::setNames(
      normalized_specification$path,
      normalized_specification$modality
    )
  }
  metric_paths <- resolve_base_model_named_paths(
    metric_paths,
    metric_specification$input_id,
    "metric_paths"
  )
  normalized_paths <- resolve_base_model_named_paths(
    normalized_paths,
    normalized_specification$modality,
    "normalized_paths"
  )
  context_path <- resolve_base_model_scalar_path(
    context_path,
    "context_path"
  )
  manifest_paths <- resolve_base_model_named_paths(
    manifest_paths,
    c("metrics", "normalization", "site_context"),
    "manifest_paths"
  )
  paths <- base_model_paths(root, output_root)
  producer <- "scripts/pipeline/build_base_model_data.R"

  upstream <- base_model_verify_upstream_inputs(
    root = root,
    metric_specification = metric_specification,
    normalized_specification = normalized_specification,
    metric_paths = metric_paths,
    normalized_paths = normalized_paths,
    context_path = context_path,
    manifest_paths = manifest_paths
  )
  input_provenance <- upstream$input_provenance
  input_bundle_text <- paste(
    paste(
      input_provenance$input_id,
      input_provenance$sha256,
      input_provenance$upstream_manifest_sha256,
      sep = "="
    ),
    collapse = "|"
  )
  input_bundle_sha256 <- base_model_text_sha256(input_bundle_text)

  metric_inputs <- stats::setNames(
    lapply(metric_paths, readRDS),
    names(metric_paths)
  )
  normalized_inputs <- stats::setNames(
    lapply(normalized_paths, readRDS),
    names(normalized_paths)
  )
  context <- readRDS(context_path)
  validate_base_model_context(context, object = "canonical site context")
  for (index in seq_len(nrow(metric_specification))) {
    specification <- metric_specification[index, , drop = FALSE]
    validate_base_model_metric_input(
      metric_inputs[[specification$input_id]],
      placement = specification$placement,
      resolution = specification$resolution,
      object = paste0("metric input `", specification$input_id, "`")
    )
  }
  for (modality in base_model_normalized_modalities()) {
    validate_base_model_normalized_input(
      normalized_inputs[[modality]],
      modality,
      object = paste0("normalized input `", modality, "`")
    )
  }

  registry_firewall_rows <- vector(
    "list",
    nrow(metric_specification)
  )
  for (index in seq_len(nrow(metric_specification))) {
    specification <- metric_specification[index, , drop = FALSE]
    filtered <- base_model_apply_metric_registry_firewall(
      metric_inputs[[specification$input_id]],
      input_id = specification$input_id,
      placement = specification$placement,
      resolution = specification$resolution
    )
    metric_inputs[[specification$input_id]] <- filtered$data
    registry_firewall_rows[[index]] <- filtered$audit
  }
  metric_registry_firewall <- dplyr::bind_rows(registry_firewall_rows)
  if (
    nrow(metric_registry_firewall) != nrow(metric_specification) ||
      any(metric_registry_firewall$status != "PASS") ||
      any(!metric_registry_firewall$row_order_preserved) ||
      any(!metric_registry_firewall$key_set_preserved) ||
      any(metric_registry_firewall$outcome_values_recalculated)
  ) {
    abort_pipeline("Metric-registry firewall audit did not pass")
  }

  participant_metadata <- base_model_build_participant_metadata(
    normalized_inputs,
    metric_inputs
  )
  data_artifacts <- list(participant_metadata = participant_metadata)
  metric_audits <- list()
  audit_index <- 0L

  for (placement in base_model_placements()) {
    participant_day_id <- paste0(placement, "_participant_day")
    participant_id <- paste0(placement, "_participant")
    participant_day_context <- base_model_join_context(
      metric_inputs[[participant_day_id]],
      context,
      placement,
      "participant_day",
      participant_day_id
    )
    data_artifacts[[paste0(
      placement,
      "_participant_day_context"
    )]] <- participant_day_context$data
    audit_index <- audit_index + 1L
    metric_audits[[audit_index]] <- participant_day_context$audit

    participant_data <- metric_inputs[[participant_id]]
    data_artifacts[[participant_id]] <- participant_data
    audit_index <- audit_index + 1L
    metric_audits[[audit_index]] <- base_model_identity_audit(
      participant_data,
      participant_id,
      placement,
      "participant"
    )

    for (resolution in c("30_minute", "one_hour")) {
      input_id <- paste(placement, resolution, sep = "_")
      joined <- base_model_join_context(
        metric_inputs[[input_id]],
        context,
        placement,
        resolution,
        input_id
      )
      data_artifacts[[paste0(input_id, "_context")]] <- joined$data
      audit_index <- audit_index + 1L
      metric_audits[[audit_index]] <- joined$audit
    }

    enriched_day <- base_model_join_participant_metadata(
      participant_day_context$data,
      participant_metadata,
      placement,
      "participant_day",
      paste0(participant_day_id, "_context")
    )
    data_artifacts[[paste0(
      placement,
      "_participant_day_enriched"
    )]] <- enriched_day$data
    audit_index <- audit_index + 1L
    metric_audits[[audit_index]] <- enriched_day$audit

    enriched_participant <- base_model_join_participant_metadata(
      participant_data,
      participant_metadata,
      placement,
      "participant",
      participant_id
    )
    data_artifacts[[paste0(
      placement,
      "_participant_enriched"
    )]] <- enriched_participant$data
    audit_index <- audit_index + 1L
    metric_audits[[audit_index]] <- enriched_participant$audit
  }
  data_artifacts <- data_artifacts[names(paths$data_paths)]
  if (
    any(vapply(data_artifacts, is.null, logical(1))) ||
      !identical(names(data_artifacts), names(paths$data_paths))
  ) {
    abort_pipeline(
      "Base-model data artifact assembly differs from the output contract"
    )
  }

  metric_key_join_audit <- dplyr::bind_rows(metric_audits) |>
    dplyr::arrange(
      factor(.data$placement, levels = base_model_placements()),
      factor(
        .data$resolution,
        levels = c(
          "participant_day",
          "participant",
          "30_minute",
          "one_hour"
        )
      ),
      .data$stage
    )
  modality_key_join_audit <- base_model_build_modality_audit(
    normalized_inputs,
    participant_metadata
  )
  participant_availability_audit <-
    base_model_build_participant_availability_audit(
      participant_metadata
    )
  metadata_field_audit <- base_model_build_metadata_field_audit(
    normalized_inputs,
    participant_metadata
  )
  metric_metadata_availability_audit <-
    base_model_build_metric_metadata_availability_audit(
      metric_inputs,
      normalized_inputs
    )
  contract <- base_model_contract()
  if (
    any(metric_registry_firewall$status != "PASS") ||
      any(metric_key_join_audit$status != "PASS") ||
      any(modality_key_join_audit$status != "PASS") ||
      any(participant_availability_audit$status != "PASS") ||
      any(metadata_field_audit$status != "PASS") ||
      any(metric_metadata_availability_audit$status != "PASS") ||
      any(contract$status != "PASS")
  ) {
    abort_pipeline("Base-model audit contains a non-PASS result")
  }
  audit_artifacts <- list(
    input_provenance = input_provenance,
    metric_registry_firewall = metric_registry_firewall,
    metric_key_join = metric_key_join_audit,
    modality_key_join = modality_key_join_audit,
    participant_availability = participant_availability_audit,
    metadata_fields = metadata_field_audit,
    metric_metadata_availability = metric_metadata_availability_audit,
    contract = contract
  )
  if (!identical(names(audit_artifacts), names(paths$audit_paths))) {
    abort_pipeline(
      "Base-model audit artifact assembly differs from the output contract"
    )
  }

  dir.create(paths$base_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(paths$manifest), recursive = TRUE, showWarnings = FALSE)
  data_metadata <- lapply(names(data_artifacts), function(artifact_id) {
    data <- data_artifacts[[artifact_id]]
    write_rds_artifact(
      data,
      paths$data_paths[[artifact_id]],
      producer = producer,
      metadata = list(rows = nrow(data), columns = ncol(data))
    )
  })
  names(data_metadata) <- names(data_artifacts)
  audit_metadata <- lapply(names(audit_artifacts), function(artifact_id) {
    write_csv_artifact(
      audit_artifacts[[artifact_id]],
      paths$audit_paths[[artifact_id]],
      producer = producer
    )
  })
  names(audit_metadata) <- names(audit_artifacts)

  manifest_rows <- c(
    lapply(names(data_metadata), function(artifact_id) {
      base_model_manifest_row(
        metadata = data_metadata[[artifact_id]],
        artifact_id = artifact_id,
        artifact_type = "rds",
        paths = paths,
        input_bundle_sha256 = input_bundle_sha256,
        manifest_hashes = upstream$manifest_hashes,
        producer = producer
      )
    }),
    lapply(names(audit_metadata), function(artifact_id) {
      base_model_manifest_row(
        metadata = audit_metadata[[artifact_id]],
        artifact_id = artifact_id,
        artifact_type = "csv",
        paths = paths,
        input_bundle_sha256 = input_bundle_sha256,
        manifest_hashes = upstream$manifest_hashes,
        producer = producer
      )
    })
  )
  manifest <- dplyr::bind_rows(manifest_rows) |>
    dplyr::select(
      dplyr::all_of(base_model_output_manifest_columns())
    )
  expected_ids <- c(names(paths$data_paths), names(paths$audit_paths))
  if (!identical(manifest$artifact_id, expected_ids)) {
    abort_pipeline("Base-model manifest artifact order differs")
  }
  manifest_metadata <- write_csv_artifact(
    manifest,
    paths$manifest,
    producer = producer
  )

  list(
    status = "PASS",
    paths = paths,
    input_provenance = input_provenance,
    input_bundle_sha256 = input_bundle_sha256,
    data = data_artifacts,
    audits = audit_artifacts,
    manifest = manifest,
    artifact_metadata = list(
      data = data_metadata,
      audits = audit_metadata,
      manifest = manifest_metadata
    )
  )
}
