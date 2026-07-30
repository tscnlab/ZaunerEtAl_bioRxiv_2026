# Build the H01 model-data artifact and its audit-facing CSV contract.
#
# Source paths_io.R, assertions.R, metric_display_registry.R,
# base_model_data.R, verify_base_model_data_artifacts.R, and
# h01_model_data.R before this file.

h01_relative_path <- function(path, anchor) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  anchor <- normalizePath(anchor, winslash = "/", mustWork = TRUE)
  prefix <- paste0(anchor, "/")
  if (startsWith(path, prefix)) {
    return(substring(path, nchar(prefix) + 1L))
  }
  path
}

h01_declared_absolute_path <- function(path, root) {
  candidate <- if (grepl("^/", path)) path else file.path(root, path)
  normalizePath(candidate, winslash = "/", mustWork = TRUE)
}

h01_text_sha256 <- function(text) {
  unname(unclass(as.character(openssl::sha256(charToRaw(text)))))
}

h01_add_main_support_status <- function(model_inputs) {
  for (placement in h01_placements()) {
    model_inputs[[placement]]$participant_day <-
      model_inputs[[placement]]$participant_day |>
      dplyr::mutate(
        prepared_record_support_available = TRUE,
        prepared_record_support_unavailability_reason = NA_character_,
        .after = "measurement_construct"
      )
    model_inputs[[placement]]$participant <-
      model_inputs[[placement]]$participant |>
      dplyr::mutate(
        prepared_record_support_available = TRUE,
        prepared_record_support_unavailability_reason = NA_character_,
        .after = "measurement_construct"
      )
    model_inputs[[placement]]$metric_support <-
      model_inputs[[placement]]$metric_support |>
      dplyr::mutate(
        metric_support_available = is.finite(.data$valid_minutes) &
          is.finite(.data$expected_minutes),
        metric_support_unavailability_reason = ifelse(
          .data$metric_support_available,
          NA_character_,
          "metric_producer_did_not_export_exact_support_minutes"
        ),
        .after = "failure_reason"
      )
  }
  model_inputs
}

h01_verify_metric_csv_inputs <- function(
  root,
  input_paths,
  metric_manifest_path,
  artifact_type
) {
  metric_manifest <- readr::read_csv(
    metric_manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  required <- c(
    "path",
    "sha256",
    "bytes",
    "producer",
    "r_version",
    "artifact_type",
    "placement",
    "rows",
    "columns"
  )
  assert_columns(
    metric_manifest,
    required,
    object = "metric artifact manifest"
  )
  manifest_paths <- vapply(
    metric_manifest$path,
    h01_declared_absolute_path,
    character(1),
    root = root
  )
  rows <- list()
  for (placement in h01_placements()) {
    path <- normalizePath(
      input_paths[[placement]],
      winslash = "/",
      mustWork = TRUE
    )
    matches <- which(
      metric_manifest$artifact_type == artifact_type &
        metric_manifest$placement == placement &
        manifest_paths == path
    )
    if (length(matches) != 1L) {
      h01_abort(
        paste0(
          "Metric manifest must identify `%s` H01 `%s` ",
          "exactly once"
        ),
        placement,
        artifact_type
      )
    }
    row <- metric_manifest[matches, , drop = FALSE]
    data <- readr::read_csv(
      path,
      show_col_types = FALSE,
      progress = FALSE
    )
    actual_hash <- artifact_sha256(path)
    if (
      row$sha256[[1L]] != actual_hash ||
        row$bytes[[1L]] != unname(file.info(path)$size) ||
        row$rows[[1L]] != nrow(data) ||
        row$columns[[1L]] != ncol(data) ||
        row$producer[[1L]] != "scripts/pipeline/build_metric_derivation.R" ||
        row$r_version[[1L]] != "4.6.1"
    ) {
      h01_abort(
        "Metric-manifest provenance failed for `%s` `%s`",
        placement,
        artifact_type
      )
    }
    rows[[placement]] <- list(data = data, manifest_row = row)
  }
  list(
    inputs = rows,
    manifest = metric_manifest,
    manifest_sha256 = artifact_sha256(metric_manifest_path)
  )
}

h01_verify_base_input_manifest <- function(root, base_paths) {
  manifest_path <- file.path(
    root,
    "artifacts",
    "12_manifests",
    "base_model_data_artifacts.csv"
  )
  manifest <- readr::read_csv(
    manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  assert_columns(
    manifest,
    c(
      "artifact_id",
      "artifact_type",
      "path",
      "sha256",
      "bytes",
      "rows",
      "columns",
      "r_version",
      "status"
    ),
    object = "base-model manifest"
  )
  expected <- c(
    glasses_participant_day_enriched = base_paths$glasses[["participant_day"]],
    glasses_participant_enriched = base_paths$glasses[["participant"]],
    chest_participant_day_enriched = base_paths$chest[["participant_day"]],
    chest_participant_enriched = base_paths$chest[["participant"]]
  )
  for (artifact_id in names(expected)) {
    path <- normalizePath(
      expected[[artifact_id]],
      winslash = "/",
      mustWork = TRUE
    )
    matches <- which(manifest$artifact_id == artifact_id)
    if (length(matches) != 1L) {
      h01_abort(
        "Base-model manifest must identify `%s` exactly once",
        artifact_id
      )
    }
    row <- manifest[matches, , drop = FALSE]
    declared_path <- h01_declared_absolute_path(row$path[[1L]], root)
    data <- readRDS(path)
    if (
      declared_path != path ||
        row$sha256[[1L]] != artifact_sha256(path) ||
        row$bytes[[1L]] != unname(file.info(path)$size) ||
        row$rows[[1L]] != nrow(data) ||
        row$columns[[1L]] != ncol(data) ||
        row$r_version[[1L]] != "4.6.1" ||
        row$status[[1L]] != "PASS"
    ) {
      h01_abort(
        "Base-model manifest provenance failed for `%s`",
        artifact_id
      )
    }
  }
  list(
    manifest = manifest,
    manifest_path = manifest_path,
    manifest_sha256 = artifact_sha256(manifest_path)
  )
}

h01_build_input_provenance <- function(
  root,
  base_paths,
  admissibility_paths,
  metric_support_paths,
  base_manifest,
  metric_manifest_path,
  metric_manifest_sha256
) {
  rows <- list()
  row_index <- 0L
  add_row <- function(
    input_id,
    input_role,
    placement,
    path,
    upstream_manifest_path = NA_character_,
    upstream_manifest_sha256 = NA_character_
  ) {
    object <- if (grepl("\\.rds$", path, ignore.case = TRUE)) {
      readRDS(path)
    } else {
      readr::read_csv(
        path,
        show_col_types = FALSE,
        progress = FALSE
      )
    }
    row_index <<- row_index + 1L
    rows[[row_index]] <<- tibble::tibble(
      input_id = input_id,
      input_role = input_role,
      placement = placement,
      path = h01_relative_path(path, root),
      sha256 = artifact_sha256(path),
      bytes = unname(file.info(path)$size),
      rows = nrow(object),
      columns = ncol(object),
      upstream_manifest_path = if (is.na(upstream_manifest_path)) {
        NA_character_
      } else {
        h01_relative_path(upstream_manifest_path, root)
      },
      upstream_manifest_sha256 = upstream_manifest_sha256,
      r_version = "4.6.1",
      status = "PASS"
    )
  }
  for (placement in h01_placements()) {
    add_row(
      input_id = paste0(placement, "_participant_day_enriched"),
      input_role = "base_participant_day_rds",
      placement = placement,
      path = base_paths[[placement]][["participant_day"]],
      upstream_manifest_path = base_manifest$manifest_path,
      upstream_manifest_sha256 = base_manifest$manifest_sha256
    )
    add_row(
      input_id = paste0(placement, "_participant_enriched"),
      input_role = "base_participant_rds",
      placement = placement,
      path = base_paths[[placement]][["participant"]],
      upstream_manifest_path = base_manifest$manifest_path,
      upstream_manifest_sha256 = base_manifest$manifest_sha256
    )
    add_row(
      input_id = paste0(placement, "_metric_admissibility"),
      input_role = "metric_admissibility_csv",
      placement = placement,
      path = admissibility_paths[[placement]],
      upstream_manifest_path = metric_manifest_path,
      upstream_manifest_sha256 = metric_manifest_sha256
    )
    add_row(
      input_id = paste0(placement, "_metric_support"),
      input_role = "metric_values_long_csv",
      placement = placement,
      path = metric_support_paths[[placement]],
      upstream_manifest_path = metric_manifest_path,
      upstream_manifest_sha256 = metric_manifest_sha256
    )
  }
  display_path <- file.path(root, "config", "metric_display_registry.csv")
  add_row(
    input_id = "metric_display_registry",
    input_role = "display_registry_csv",
    placement = NA_character_,
    path = display_path
  )
  dplyr::bind_rows(rows)
}

h01_manifest_columns <- function() {
  c(
    "artifact_id",
    "artifact_type",
    "path",
    "sha256",
    "bytes",
    "rows",
    "columns",
    "input_bundle_sha256",
    "base_manifest_sha256",
    "metric_manifest_sha256",
    "producer",
    "r_version",
    "status"
  )
}

h01_manifest_row <- function(
  metadata,
  artifact_id,
  artifact_type,
  rows,
  columns,
  paths,
  input_bundle_sha256,
  base_manifest_sha256,
  metric_manifest_sha256,
  producer
) {
  tibble::tibble(
    artifact_id = artifact_id,
    artifact_type = artifact_type,
    path = h01_relative_path(metadata$path, paths$output_root),
    sha256 = metadata$sha256,
    bytes = metadata$bytes,
    rows = rows,
    columns = columns,
    input_bundle_sha256 = input_bundle_sha256,
    base_manifest_sha256 = base_manifest_sha256,
    metric_manifest_sha256 = metric_manifest_sha256,
    producer = producer,
    r_version = as.character(getRversion()),
    status = "PASS"
  )
}

build_h01_model_data_artifacts <- function(
  root = project_root(),
  output_root = root
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_root <- normalizePath(
    output_root,
    winslash = "/",
    mustWork = TRUE
  )
  if (!identical(as.character(getRversion()), "4.6.1")) {
    h01_abort(
      "H01 model-data build requires R 4.6.1; found %s",
      as.character(getRversion())
    )
  }
  data_scenario_id <- "main"
  model_implementation_id <- "new_h01_h11"
  producer <- "scripts/pipeline/build_h01_model_data.R"
  paths <- h01_model_data_paths(root, output_root)
  base_verification <- verify_base_model_data_artifacts(
    root = root,
    output_root = root
  )
  if (!identical(base_verification$status, "PASS")) {
    h01_abort("Preparation 06 base-model verification did not pass")
  }

  contract <- h01_metric_contract(root)
  base_paths <- h01_base_input_paths(root)
  admissibility_paths <- h01_admissibility_input_paths(root)
  metric_support_paths <- h01_metric_support_input_paths(root)
  required_inputs <- c(
    unlist(base_paths, use.names = FALSE),
    admissibility_paths,
    metric_support_paths
  )
  if (any(!file.exists(required_inputs))) {
    h01_abort(
      "H01 model-data build is missing input(s): %s",
      paste(required_inputs[!file.exists(required_inputs)], collapse = ", ")
    )
  }
  base_manifest <- h01_verify_base_input_manifest(root, base_paths)
  metric_manifest_path <- file.path(
    root,
    "artifacts",
    "12_manifests",
    "metric_artifacts.csv"
  )
  admissibility_inputs <- h01_verify_metric_csv_inputs(
    root,
    admissibility_paths,
    metric_manifest_path,
    artifact_type = "metric_admissibility"
  )
  metric_support_inputs <- h01_verify_metric_csv_inputs(
    root,
    metric_support_paths,
    metric_manifest_path,
    artifact_type = "long_metric_values"
  )

  model_inputs <- list()
  for (placement in h01_placements()) {
    model_inputs[[placement]] <- list(
      participant_day = readRDS(
        base_paths[[placement]][["participant_day"]]
      ),
      participant = readRDS(base_paths[[placement]][["participant"]]),
      admissibility = admissibility_inputs$inputs[[placement]]$data,
      metric_support = metric_support_inputs$inputs[[placement]]$data
    )
  }
  model_inputs <- h01_add_main_support_status(model_inputs)
  implementation_contract_sha256 <-
    h01_implementation_contract_sha256(contract)
  shared_implementation_sha256 <- artifact_sha256(file.path(
    root,
    "scripts",
    "pipeline",
    "h01_model_data.R"
  ))
  centered <- h01_build_model_rows_from_inputs(
    inputs = model_inputs,
    contract = contract,
    data_scenario_id = data_scenario_id,
    model_implementation_id = model_implementation_id
  )
  model_rows <- centered$rows |>
    dplyr::arrange(
      factor(.data$scenario, levels = h01_scenarios()),
      factor(.data$placement, levels = h01_placements()),
      .data$metric_order,
      .data$site,
      .data$Id,
      .data$local_date
    )
  scenario_status <- h01_scenario_status(
    contract,
    data_scenario_id = data_scenario_id,
    model_implementation_id = model_implementation_id
  )
  sample_flow <- h01_build_sample_flow(model_rows, scenario_status)
  exclusion_reasons <- h01_build_exclusion_summary(
    model_rows,
    scenario_status
  )
  variable_dictionary <- h01_variable_dictionary()
  input_provenance <- h01_build_input_provenance(
    root,
    base_paths,
    admissibility_paths,
    metric_support_paths,
    base_manifest,
    metric_manifest_path,
    admissibility_inputs$manifest_sha256
  )
  input_bundle_text <- paste(
    paste(
      input_provenance$input_id,
      input_provenance$sha256,
      input_provenance$upstream_manifest_sha256,
      sep = "="
    ),
    collapse = "|"
  )
  input_bundle_sha256 <- h01_text_sha256(input_bundle_text)
  status <- "PASS_WITH_DECLARED_UNAVAILABLE_SCENARIO"
  object <- list(
    hypothesis_id = "H01",
    status = status,
    model_rows = model_rows,
    metric_contract = contract,
    sample_flow = sample_flow,
    exclusion_reasons = exclusion_reasons,
    scenario_status = scenario_status,
    predictor_centers = centered$centers,
    variable_dictionary = variable_dictionary,
    input_provenance = input_provenance,
    metadata = list(
      r_version = as.character(getRversion()),
      dplyr_version = as.character(utils::packageVersion("dplyr")),
      readr_version = as.character(utils::packageVersion("readr")),
      tidyr_version = as.character(utils::packageVersion("tidyr")),
      tibble_version = as.character(utils::packageVersion("tibble")),
      base_manifest_sha256 = base_manifest$manifest_sha256,
      metric_manifest_sha256 = admissibility_inputs$manifest_sha256,
      input_bundle_sha256 = input_bundle_sha256,
      data_scenario_id = data_scenario_id,
      model_implementation_id = model_implementation_id,
      implementation_contract_sha256 = implementation_contract_sha256,
      shared_implementation_sha256 = shared_implementation_sha256,
      site_levels = sort(unique(model_rows$site)),
      paired_participant_metric_status = "unavailable_pending_minute_level_recomputation"
    )
  )
  if (!identical(names(object), h01_output_contract()$top_level)) {
    h01_abort("H01 RDS top-level fields differ from the output contract")
  }

  rds_metadata <- write_rds_artifact(
    object,
    paths$rds,
    producer = producer,
    metadata = list(
      rows = nrow(model_rows),
      columns = ncol(model_rows)
    )
  )
  csv_objects <- list(
    model_rows = model_rows,
    metric_contract = contract,
    sample_flow = sample_flow,
    exclusion_reasons = exclusion_reasons,
    scenario_status = scenario_status,
    predictor_centers = centered$centers,
    variable_dictionary = variable_dictionary,
    input_provenance = input_provenance
  )
  csv_metadata <- lapply(names(csv_objects), function(artifact_id) {
    write_csv_artifact(
      csv_objects[[artifact_id]],
      paths$csv[[artifact_id]],
      producer = producer
    )
  })
  names(csv_metadata) <- names(csv_objects)

  manifest_rows <- list(
    h01_manifest_row(
      rds_metadata,
      artifact_id = "H01",
      artifact_type = "rds",
      rows = nrow(model_rows),
      columns = ncol(model_rows),
      paths = paths,
      input_bundle_sha256 = input_bundle_sha256,
      base_manifest_sha256 = base_manifest$manifest_sha256,
      metric_manifest_sha256 = admissibility_inputs$manifest_sha256,
      producer = producer
    )
  )
  for (artifact_id in names(csv_metadata)) {
    manifest_rows[[length(manifest_rows) + 1L]] <- h01_manifest_row(
      csv_metadata[[artifact_id]],
      artifact_id = artifact_id,
      artifact_type = "csv",
      rows = nrow(csv_objects[[artifact_id]]),
      columns = ncol(csv_objects[[artifact_id]]),
      paths = paths,
      input_bundle_sha256 = input_bundle_sha256,
      base_manifest_sha256 = base_manifest$manifest_sha256,
      metric_manifest_sha256 = admissibility_inputs$manifest_sha256,
      producer = producer
    )
  }
  manifest <- dplyr::bind_rows(manifest_rows) |>
    dplyr::select(dplyr::all_of(h01_manifest_columns()))
  manifest_metadata <- write_csv_artifact(
    manifest,
    paths$manifest,
    producer = producer
  )

  list(
    status = status,
    paths = paths,
    object = object,
    manifest = manifest,
    artifact_metadata = list(
      rds = rds_metadata,
      csv = csv_metadata,
      manifest = manifest_metadata
    )
  )
}
