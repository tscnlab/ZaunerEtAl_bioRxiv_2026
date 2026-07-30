# Build Preparation 06 normalized model inputs from verified pinned releases.

build_model_input_normalization <- function(
  root = project_root(),
  site_sources_path = file.path(root, "config", "site_sources.csv"),
  availability_path = file.path(
    root,
    "config",
    "model_input_availability.csv"
  ),
  preparation01_manifest_path = file.path(
    root,
    "artifacts",
    "12_manifests",
    "pinned_downloads.csv"
  ),
  acquisition_manifest_path = model_input_acquisition_paths(root)$manifest,
  acquisition_object_audit_path =
    model_input_acquisition_paths(root)$object_audit,
  acquisition_column_audit_path =
    model_input_acquisition_paths(root)$column_audit
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  paths <- model_input_normalization_paths(root)
  producer <- "scripts/pipeline/build_model_input_normalization.R"

  acquisition_verification <- verify_model_input_acquisition(
    root = root,
    site_sources_path = site_sources_path,
    availability_path = availability_path,
    preparation01_manifest_path = preparation01_manifest_path,
    manifest_path = acquisition_manifest_path,
    object_audit_path = acquisition_object_audit_path,
    column_audit_path = acquisition_column_audit_path
  )
  if (!identical(acquisition_verification$status, "PASS")) {
    abort_pipeline(
      "Model-input normalization requires a PASS acquisition verification"
    )
  }

  acquisition_manifest <- readr::read_csv(
    acquisition_manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  input_manifest_sha256 <- artifact_sha256(acquisition_manifest_path)
  site_sources <- read_site_sources(site_sources_path)
  records <- collect_model_input_records(
    manifest = acquisition_manifest,
    site_sources = site_sources,
    root = root
  )

  audits <- build_model_input_source_audits(records)
  validate_model_input_source_audits(audits)
  normalized <- build_normalized_model_inputs(
    records = records,
    audits = audits
  )
  key_audit <- build_model_input_key_audit(normalized)
  interval_audits <- build_model_input_interval_audits(normalized)
  value_preservation <- build_model_input_value_preservation_audit(
    records = records,
    normalized = normalized,
    labels = audits$labels
  )
  validate_normalized_model_inputs(
    normalized = normalized,
    key_audit = key_audit,
    interval_audits = interval_audits,
    value_preservation = value_preservation
  )

  expected_rows <- vapply(
    model_input_normalization_modalities(),
    function(modality) {
      sum(vapply(
        records[
          vapply(records, `[[`, character(1), "modality") == modality
        ],
        function(record) nrow(record$data),
        integer(1)
      ))
    },
    integer(1)
  )
  observed_rows <- vapply(normalized, nrow, integer(1))
  if (!identical(expected_rows, observed_rows)) {
    abort_pipeline(
      "Normalized row counts do not exactly match verified source rows"
    )
  }

  dir.create(paths$normalized_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(paths$audit_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(paths$manifest), recursive = TRUE, showWarnings = FALSE)

  modality_metadata <- lapply(names(normalized), function(modality) {
    write_rds_artifact(
      normalized[[modality]],
      paths$modality_paths[[modality]],
      producer = producer,
      metadata = list(
        rows = nrow(normalized[[modality]]),
        columns = ncol(normalized[[modality]])
      )
    )
  })
  names(modality_metadata) <- names(normalized)

  audit_data <- list(
    source_schema = audits$source_schema,
    labels = audits$labels,
    keys = key_audit,
    missingness = audits$missingness,
    intervals = interval_audits$intervals,
    interval_issues = interval_audits$interval_issues,
    free_text = audits$free_text,
    value_preservation = value_preservation
  )
  audit_metadata <- lapply(names(audit_data), function(audit_name) {
    write_csv_artifact(
      audit_data[[audit_name]],
      paths$audit_paths[[audit_name]],
      producer = producer
    )
  })
  names(audit_metadata) <- names(audit_data)

  manifest_rows <- c(
    lapply(names(modality_metadata), function(modality) {
      model_input_normalization_manifest_row(
        metadata = modality_metadata[[modality]],
        artifact_id = paste0("normalized_", modality),
        artifact_type = "rds",
        modality = modality,
        root = root,
        input_manifest_sha256 = input_manifest_sha256
      )
    }),
    lapply(names(audit_metadata), function(audit_name) {
      model_input_normalization_manifest_row(
        metadata = audit_metadata[[audit_name]],
        artifact_id = paste0("audit_", audit_name),
        artifact_type = "csv",
        modality = NA_character_,
        root = root,
        input_manifest_sha256 = input_manifest_sha256
      )
    })
  )
  normalization_manifest <- dplyr::bind_rows(manifest_rows) |>
    dplyr::select(
      dplyr::all_of(model_input_normalization_manifest_columns())
    )
  if (
    !identical(
      normalization_manifest$artifact_id,
      model_input_normalization_expected_artifacts()
    )
  ) {
    abort_pipeline(
      "Normalization manifest artifact order differs from the contract"
    )
  }
  manifest_metadata <- write_csv_artifact(
    normalization_manifest,
    paths$manifest,
    producer = producer
  )

  list(
    status = "PASS",
    acquisition_verification = acquisition_verification,
    normalized = normalized,
    source_audits = audits,
    key_audit = key_audit,
    interval_audits = interval_audits,
    value_preservation = value_preservation,
    manifest = normalization_manifest,
    paths = paths,
    artifact_metadata = list(
      modalities = modality_metadata,
      audits = audit_metadata,
      manifest = manifest_metadata
    )
  )
}
