# Build the H01 manuscript-prepared-data sensitivity artifact without fitting
# models.
#
# Source paths_io.R, assertions.R, metric_display_registry.R,
# manuscript_prepared_data.R, build_manuscript_prepared_data.R,
# verify_manuscript_prepared_data_artifacts.R, h01_model_data.R,
# build_h01_model_data.R, verify_h01_model_data_artifacts.R,
# verify_site_solar_context_artifacts.R, and
# h01_manuscript_prepared_adapter.R first.

h01_manuscript_prepared_object_contract <- function() {
  c(
    h01_output_contract()$top_level[
      h01_output_contract()$top_level != "metadata"
    ],
    "contract_equivalence",
    "timing_conversion_audit",
    "metadata"
  )
}

h01_manuscript_prepared_manifest_columns <- function() {
  c(
    "artifact_id",
    "artifact_type",
    "data_scenario_id",
    "model_implementation_id",
    "path",
    "sha256",
    "bytes",
    "rows",
    "columns",
    "input_bundle_sha256",
    "scenario_input_manifest_sha256",
    "site_context_manifest_sha256",
    "implementation_contract_sha256",
    "shared_implementation_sha256",
    "producer",
    "r_version",
    "status"
  )
}

h01_manuscript_prepared_inspect_input <- function(path) {
  if (grepl("\\.rds$", path, ignore.case = TRUE)) {
    object <- readRDS(path)
    if (is.data.frame(object)) {
      return(c(rows = nrow(object), columns = ncol(object)))
    }
    if (is.list(object) && is.data.frame(object$model_rows)) {
      return(c(
        rows = nrow(object$model_rows),
        columns = ncol(object$model_rows)
      ))
    }
    return(c(rows = NA_real_, columns = NA_real_))
  }
  if (grepl("\\.csv$", path, ignore.case = TRUE)) {
    object <- readr::read_csv(
      path,
      show_col_types = FALSE,
      progress = FALSE
    )
    return(c(rows = nrow(object), columns = ncol(object)))
  }
  c(rows = NA_integer_, columns = NA_integer_)
}

h01_manuscript_prepared_input_provenance <- function(root, paths) {
  scenario_manifest <- paths$source$manifest
  site_manifest <- file.path(
    root,
    "artifacts",
    "12_manifests",
    "site_solar_context_artifacts.csv"
  )
  inputs <- tibble::tribble(
    ~input_id,
    ~input_role,
    ~path,
    ~upstream_manifest_path,
    "manuscript_prepared_participant_day_metrics",
    "scenario_participant_day_metric_rds",
    paths$source$rds[["participant_day_metrics"]],
    scenario_manifest,
    "manuscript_prepared_participant_metrics",
    "scenario_participant_metric_rds",
    paths$source$rds[["participant_metrics"]],
    scenario_manifest,
    "manuscript_prepared_metric_crosswalk",
    "scenario_metric_crosswalk_csv",
    paths$source$csv[["metric_crosswalk"]],
    scenario_manifest,
    "manuscript_prepared_normalized_input_references",
    "scenario_normalized_input_reference_rds",
    paths$source$rds[["normalized_input_references"]],
    scenario_manifest,
    "manuscript_prepared_artifact_manifest",
    "scenario_input_manifest_csv",
    scenario_manifest,
    NA_character_,
    "main_h01_model_data",
    "main_h01_model_data_rds",
    h01_model_data_paths(root, root)$rds,
    h01_model_data_paths(root, root)$manifest,
    "main_h01_model_data_manifest",
    "main_h01_model_data_manifest_csv",
    h01_model_data_paths(root, root)$manifest,
    NA_character_,
    "site_solar_context",
    "verified_site_solar_context_rds",
    file.path(
      root,
      "artifacts",
      "06_model_data",
      "context",
      "site_solar_context.rds"
    ),
    site_manifest,
    "site_solar_context_manifest",
    "site_context_manifest_csv",
    site_manifest,
    NA_character_,
    "metric_display_registry",
    "display_registry_csv",
    file.path(root, "config", "metric_display_registry.csv"),
    NA_character_,
    "shared_h01_model_data_implementation",
    "shared_r_implementation",
    file.path(root, "scripts", "pipeline", "h01_model_data.R"),
    NA_character_,
    "manuscript_prepared_h01_adapter",
    "scenario_r_adapter",
    file.path(
      root,
      "scripts",
      "pipeline",
      "h01_manuscript_prepared_adapter.R"
    ),
    NA_character_,
    "manuscript_prepared_h01_builder",
    "scenario_r_builder",
    file.path(
      root,
      "scripts",
      "pipeline",
      "build_h01_manuscript_prepared_data.R"
    ),
    NA_character_
  )
  if (any(!file.exists(inputs$path))) {
    h01_abort(
      "H01 manuscript-prepared provenance input is missing: %s",
      paste(inputs$path[!file.exists(inputs$path)], collapse = ", ")
    )
  }
  inspected <- lapply(
    inputs$path,
    h01_manuscript_prepared_inspect_input
  )
  inputs |>
    dplyr::mutate(
      path = vapply(
        .data$path,
        h01_relative_path,
        character(1),
        anchor = root
      ),
      sha256 = vapply(
        .data$path,
        function(path) artifact_sha256(file.path(root, path)),
        character(1)
      ),
      bytes = vapply(
        .data$path,
        function(path) unname(file.info(file.path(root, path))$size),
        numeric(1)
      ),
      rows = vapply(inspected, function(value) value[["rows"]], numeric(1)),
      columns = vapply(
        inspected,
        function(value) value[["columns"]],
        numeric(1)
      ),
      upstream_manifest_sha256 = vapply(
        .data$upstream_manifest_path,
        function(path) {
          if (is.na(path)) {
            return(NA_character_)
          }
          artifact_sha256(path)
        },
        character(1)
      ),
      upstream_manifest_path = vapply(
        .data$upstream_manifest_path,
        function(path) {
          if (is.na(path)) {
            return(NA_character_)
          }
          h01_relative_path(path, root)
        },
        character(1)
      ),
      r_version = as.character(getRversion()),
      status = "PASS"
    ) |>
    dplyr::select(
      "input_id",
      "input_role",
      "path",
      "sha256",
      "bytes",
      "rows",
      "columns",
      "upstream_manifest_path",
      "upstream_manifest_sha256",
      "r_version",
      "status"
    )
}

h01_manuscript_prepared_manifest_row <- function(
  metadata,
  artifact_id,
  artifact_type,
  rows,
  columns,
  paths,
  input_bundle_sha256,
  scenario_input_manifest_sha256,
  site_context_manifest_sha256,
  implementation_contract_sha256,
  shared_implementation_sha256,
  producer
) {
  tibble::tibble(
    artifact_id = artifact_id,
    artifact_type = artifact_type,
    data_scenario_id = h01_manuscript_prepared_scenario_id(),
    model_implementation_id = h01_manuscript_prepared_model_implementation_id(),
    path = h01_relative_path(metadata$path, paths$output_root),
    sha256 = metadata$sha256,
    bytes = metadata$bytes,
    rows = rows,
    columns = columns,
    input_bundle_sha256 = input_bundle_sha256,
    scenario_input_manifest_sha256 = scenario_input_manifest_sha256,
    site_context_manifest_sha256 = site_context_manifest_sha256,
    implementation_contract_sha256 = implementation_contract_sha256,
    shared_implementation_sha256 = shared_implementation_sha256,
    producer = producer,
    r_version = as.character(getRversion()),
    status = "PASS"
  )
}

build_h01_manuscript_prepared_data_artifacts <- function(
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
      paste0(
        "H01 manuscript-prepared build requires R 4.6.1; found %s"
      ),
      as.character(getRversion())
    )
  }
  upstream <- verify_manuscript_prepared_data_artifacts(
    root = root,
    output_root = root
  )
  if (!identical(upstream$status, "PASS")) {
    h01_abort("Manuscript-prepared sensitivity inputs did not verify")
  }
  main_verification <- verify_h01_model_data_artifacts(
    root = root,
    output_root = root
  )
  if (
    !identical(
      main_verification$status,
      "PASS_WITH_DECLARED_UNAVAILABLE_SCENARIO"
    )
  ) {
    h01_abort("Main H01 model data did not verify")
  }
  site_verification <- verify_site_solar_context_artifacts(
    root = root,
    supplemental_date_paths =
      h01_manuscript_prepared_site_date_path(root),
    input_root = root
  )
  if (!identical(site_verification$status, "PASS")) {
    h01_abort("Site and solar context did not verify")
  }
  paths <- h01_manuscript_prepared_output_paths(root, output_root)
  adapted <- h01_build_manuscript_prepared_inputs(root)
  data_scenario_id <- h01_manuscript_prepared_scenario_id()
  model_implementation_id <-
    h01_manuscript_prepared_model_implementation_id()
  main_object <- readRDS(h01_model_data_paths(root, root)$rds)
  if (
    !identical(
      main_object$metadata$implementation_contract_sha256,
      adapted$implementation_contract_sha256
    ) ||
      !identical(
        main_object$metadata$shared_implementation_sha256,
        artifact_sha256(file.path(
          root,
          "scripts",
          "pipeline",
          "h01_model_data.R"
        ))
      ) ||
      !identical(main_object$metadata$data_scenario_id, "main") ||
      identical(main_object$metadata$data_scenario_id, data_scenario_id) ||
      !identical(
        main_object$metadata$model_implementation_id,
        model_implementation_id
      )
  ) {
    h01_abort(
      paste0(
        "Main and manuscript-prepared H01 data do not prove a distinct ",
        "data scenario under the same implementation"
      )
    )
  }
  contract_equivalence <- adapted$contract_equivalence |>
    dplyr::mutate(
      main_data_scenario_id = main_object$metadata$data_scenario_id,
      data_scenario_ids_differ = .data$main_data_scenario_id !=
        .data$data_scenario_id,
      main_model_implementation_id = main_object$metadata$model_implementation_id,
      model_implementation_ids_match = .data$main_model_implementation_id ==
        .data$model_implementation_id,
      main_shared_implementation_sha256 = main_object$metadata$shared_implementation_sha256,
      .after = "model_implementation_id"
    )
  centered <- h01_build_model_rows_from_inputs(
    inputs = adapted$inputs,
    contract = adapted$contract,
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
    adapted$contract,
    data_scenario_id = data_scenario_id,
    model_implementation_id = model_implementation_id
  )
  sample_flow <- h01_build_sample_flow(model_rows, scenario_status)
  exclusion_reasons <- h01_build_exclusion_summary(
    model_rows,
    scenario_status
  )
  input_provenance <- h01_manuscript_prepared_input_provenance(
    root,
    paths
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
  scenario_input_manifest_sha256 <- artifact_sha256(
    paths$source$manifest
  )
  site_context_manifest_path <- file.path(
    root,
    "artifacts",
    "12_manifests",
    "site_solar_context_artifacts.csv"
  )
  site_context_manifest_sha256 <- artifact_sha256(
    site_context_manifest_path
  )
  shared_implementation_sha256 <- artifact_sha256(file.path(
    root,
    "scripts",
    "pipeline",
    "h01_model_data.R"
  ))
  producer <-
    "scripts/pipeline/build_h01_manuscript_prepared_data.R"
  status <- paste0(
    "PASS_WITH_DECLARED_UNAVAILABLE_SUPPORT_",
    "AND_PAIRED_PARTICIPANT_METRICS"
  )
  object <- list(
    hypothesis_id = "H01",
    status = status,
    model_rows = model_rows,
    metric_contract = adapted$contract,
    sample_flow = sample_flow,
    exclusion_reasons = exclusion_reasons,
    scenario_status = scenario_status,
    predictor_centers = centered$centers,
    variable_dictionary = h01_variable_dictionary(),
    input_provenance = input_provenance,
    contract_equivalence = contract_equivalence,
    timing_conversion_audit = adapted$timing_conversion_audit,
    metadata = list(
      r_version = as.character(getRversion()),
      dplyr_version = as.character(utils::packageVersion("dplyr")),
      readr_version = as.character(utils::packageVersion("readr")),
      tidyr_version = as.character(utils::packageVersion("tidyr")),
      tibble_version = as.character(utils::packageVersion("tibble")),
      data_scenario_id = data_scenario_id,
      model_implementation_id = model_implementation_id,
      implementation_contract_sha256 = adapted$implementation_contract_sha256,
      shared_implementation_sha256 = shared_implementation_sha256,
      scenario_input_manifest_sha256 = scenario_input_manifest_sha256,
      site_context_manifest_sha256 = site_context_manifest_sha256,
      input_bundle_sha256 = input_bundle_sha256,
      site_levels = sort(unique(model_rows$site)),
      exact_metric_support_status = "unavailable_in_manuscript_prepared_artifacts",
      paired_participant_metric_status = "unavailable_pending_minute_level_recomputation"
    )
  )
  if (
    !identical(
      names(object),
      h01_manuscript_prepared_object_contract()
    )
  ) {
    h01_abort(
      "H01 manuscript-prepared RDS fields differ from its contract"
    )
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
    model_rows = object$model_rows,
    metric_contract = object$metric_contract,
    sample_flow = object$sample_flow,
    exclusion_reasons = object$exclusion_reasons,
    scenario_status = object$scenario_status,
    predictor_centers = object$predictor_centers,
    variable_dictionary = object$variable_dictionary,
    input_provenance = object$input_provenance,
    contract_equivalence = object$contract_equivalence,
    timing_conversion_audit = object$timing_conversion_audit
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
    h01_manuscript_prepared_manifest_row(
      rds_metadata,
      artifact_id = "H01",
      artifact_type = "rds",
      rows = nrow(model_rows),
      columns = ncol(model_rows),
      paths = paths,
      input_bundle_sha256 = input_bundle_sha256,
      scenario_input_manifest_sha256 = scenario_input_manifest_sha256,
      site_context_manifest_sha256 = site_context_manifest_sha256,
      implementation_contract_sha256 = adapted$implementation_contract_sha256,
      shared_implementation_sha256 = shared_implementation_sha256,
      producer = producer
    )
  )
  for (artifact_id in names(csv_metadata)) {
    manifest_rows[[length(manifest_rows) + 1L]] <-
      h01_manuscript_prepared_manifest_row(
        csv_metadata[[artifact_id]],
        artifact_id = artifact_id,
        artifact_type = "csv",
        rows = nrow(csv_objects[[artifact_id]]),
        columns = ncol(csv_objects[[artifact_id]]),
        paths = paths,
        input_bundle_sha256 = input_bundle_sha256,
        scenario_input_manifest_sha256 = scenario_input_manifest_sha256,
        site_context_manifest_sha256 = site_context_manifest_sha256,
        implementation_contract_sha256 = adapted$implementation_contract_sha256,
        shared_implementation_sha256 = shared_implementation_sha256,
        producer = producer
      )
  }
  manifest <- dplyr::bind_rows(manifest_rows) |>
    dplyr::select(
      dplyr::all_of(
        h01_manuscript_prepared_manifest_columns()
      )
    )
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
