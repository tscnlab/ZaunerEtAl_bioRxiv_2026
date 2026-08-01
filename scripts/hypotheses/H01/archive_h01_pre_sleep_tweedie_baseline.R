# Archive the superseded H01 pre-sleep Tweedie baseline before replacement.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H01 superseded-family archive requires R 4.6.1", call. = FALSE)
}

producer <-
  "scripts/hypotheses/H01/archive_h01_pre_sleep_tweedie_baseline.R"
metric_id <- "duration_below_10_pre_sleep"
current_spec <- h01_metric_registry() |>
  dplyr::filter(.data$metric_id == !!metric_id)
if (
  nrow(current_spec) != 1L ||
    current_spec$response_family != "tweedie_log" ||
    current_spec$response_transform != "identity"
) {
  stop(
    "Archive must run while the canonical pre-sleep specification is Tweedie/log",
    call. = FALSE
  )
}

archive_root <- file.path(
  root,
  "audit/hypotheses/H01/superseded_pre_sleep_tweedie"
)
archive_file_root <- file.path(archive_root, "files")
archive_table_root <- file.path(archive_root, "rows")
dir.create(archive_file_root, recursive = TRUE, showWarnings = FALSE)
dir.create(archive_table_root, recursive = TRUE, showWarnings = FALSE)

run_registry <- h01_run_registry()
source_paths <- character()
for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  model_directory <- file.path(
    root,
    "artifacts/07_models/H01",
    run$data_scenario_id,
    run$placement,
    run$sample_scenario
  )
  diagnostic_directory <- file.path(
    root,
    "artifacts/08_diagnostics/H01",
    run$data_scenario_id,
    run$placement,
    run$sample_scenario
  )
  source_directory <- file.path(
    root,
    "artifacts/11_source_data/H01",
    run$data_scenario_id,
    run$placement,
    run$sample_scenario
  )
  source_paths <- c(
    source_paths,
    file.path(model_directory, paste0(metric_id, "_model_frame.rds")),
    file.path(model_directory, paste0(metric_id, "_models.rds")),
    file.path(
      model_directory,
      paste0(metric_id, "_r2_bootstrap_draws.rds")
    ),
    file.path(
      diagnostic_directory,
      paste0(metric_id, "_diagnostics.png")
    ),
    file.path(
      source_directory,
      paste0(metric_id, "_model_frame.csv")
    ),
    file.path(
      source_directory,
      paste0(metric_id, "_diagnostic_plot_data.csv")
    )
  )
}
source_paths <- sort(unique(source_paths))
if (length(source_paths) != 48L || !all(file.exists(source_paths))) {
  stop("The superseded H01 pre-sleep file set is incomplete", call. = FALSE)
}

archive_rows <- lapply(source_paths, function(source_path) {
  relative_path <- substring(source_path, nchar(root) + 2L)
  archive_path <- file.path(archive_file_root, relative_path)
  dir.create(dirname(archive_path), recursive = TRUE, showWarnings = FALSE)
  source_hash <- artifact_sha256(source_path)
  if (file.exists(archive_path)) {
    if (!identical(artifact_sha256(archive_path), source_hash)) {
      stop("Existing H01 archive copy differs: ", relative_path, call. = FALSE)
    }
  } else if (!file.copy(source_path, archive_path, overwrite = FALSE)) {
    stop("Failed to archive H01 artifact: ", relative_path, call. = FALSE)
  }
  archive_hash <- artifact_sha256(archive_path)
  if (!identical(source_hash, archive_hash)) {
    stop("Archived H01 artifact hash differs: ", relative_path, call. = FALSE)
  }
  tibble::tibble(
    source_path = relative_path,
    source_sha256 = source_hash,
    archive_path = substring(archive_path, nchar(root) + 2L),
    archive_sha256 = archive_hash,
    bytes = as.numeric(file.info(source_path)$size),
    artifact_role = dplyr::case_when(
      grepl("r2_bootstrap_draws", source_path) ~
        "superseded_production_bootstrap_draws",
      grepl("_models[.]rds$", source_path) ~ "superseded_point_models",
      grepl("model_frame", source_path) ~ "superseded_model_frame",
      grepl("diagnostic", source_path) ~ "superseded_diagnostic",
      TRUE ~ "superseded_supporting_artifact"
    )
  )
})
archive_manifest <- dplyr::bind_rows(archive_rows)

aggregate_paths <- c(
  "artifacts/09_tables/H01/H01_r2_bootstrap_summaries.csv",
  "artifacts/08_diagnostics/H01/H01_r2_bootstrap_audit.csv",
  "artifacts/08_diagnostics/H01/H01_r2_bootstrap_failures.csv"
)
aggregate_audit <- lapply(aggregate_paths, function(relative_path) {
  path <- file.path(root, relative_path)
  data <- readr::read_csv(path, show_col_types = FALSE)
  if (!"metric_id" %in% names(data)) {
    stop("H01 bootstrap aggregate lacks metric_id: ", relative_path)
  }
  superseded <- data |>
    dplyr::filter(.data$metric_id == !!metric_id)
  retained <- data |>
    dplyr::filter(.data$metric_id != !!metric_id)
  archive_path <- file.path(
    archive_table_root,
    paste0(tools::file_path_sans_ext(basename(path)), "_rows.csv")
  )
  write_csv_artifact(superseded, archive_path, producer = producer)
  write_csv_artifact(retained, path, producer = producer)
  tibble::tibble(
    aggregate_path = relative_path,
    superseded_rows = nrow(superseded),
    retained_rows = nrow(retained),
    archived_rows_path = substring(archive_path, nchar(root) + 2L),
    archived_rows_sha256 = artifact_sha256(archive_path),
    retained_aggregate_sha256 = artifact_sha256(path)
  )
}) |>
  dplyr::bind_rows()

draw_paths <- source_paths[grepl("r2_bootstrap_draws[.]rds$", source_paths)]
if (length(draw_paths) != 8L) {
  stop("Expected eight superseded H01 draw files", call. = FALSE)
}
draw_removal <- vapply(draw_paths, file.remove, logical(1))
if (!all(draw_removal) || any(file.exists(draw_paths))) {
  stop("Failed to retire superseded canonical H01 draw copies", call. = FALSE)
}
archive_manifest <- archive_manifest |>
  dplyr::mutate(
    canonical_copy_retired = source_path %in% substring(
      draw_paths,
      nchar(root) + 2L
    ),
    recovery_status = "RECOVERABLE_FROM_HASH_VERIFIED_ARCHIVE"
  )

manifest_path <- file.path(archive_root, "archive_manifest.csv")
aggregate_path <- file.path(archive_root, "aggregate_row_archive.csv")
provenance_path <- file.path(archive_root, "archive_provenance.csv")
write_csv_artifact(archive_manifest, manifest_path, producer = producer)
write_csv_artifact(aggregate_audit, aggregate_path, producer = producer)
write_csv_artifact(
  tibble::tibble(
    r_version = as.character(getRversion()),
    metric_id = metric_id,
    superseded_response_family = current_spec$response_family,
    superseded_response_transform = current_spec$response_transform,
    archived_files = nrow(archive_manifest),
    retired_canonical_draw_copies = sum(
      archive_manifest$canonical_copy_retired
    ),
    main_input_manifest_sha256 =
      h01_input_contract(root)$main$manifest_sha256,
    manuscript_prepared_input_manifest_sha256 =
      h01_input_contract(root)$manuscript_prepared_data$manifest_sha256,
    pre_archive_model_results_manifest_sha256 = artifact_sha256(file.path(
      root,
      "artifacts/12_manifests/H01_model_results_artifacts.csv"
    )),
    archive_manifest_sha256 = artifact_sha256(manifest_path),
    aggregate_row_archive_sha256 = artifact_sha256(aggregate_path),
    producer_path = producer,
    producer_sha256 = artifact_sha256(file.path(root, producer)),
    completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  provenance_path,
  producer = producer
)

message(
  "Archived the superseded H01 pre-sleep Tweedie baseline: ",
  nrow(archive_manifest),
  " files; retired ",
  sum(archive_manifest$canonical_copy_retired),
  " canonical draw copies"
)
