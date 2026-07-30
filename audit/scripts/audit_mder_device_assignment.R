# Reproducible device-provenance audit for FIND-018.
#
# This audit uses only commit-pinned source artifacts and canonical
# Preparation 04 outputs. It does not alter analytical values or inclusion.

root_hint <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd())
source(file.path(root_hint, "scripts", "pipeline", "paths_io.R"))
root <- project_root(root_hint)
source(file.path(root, "scripts", "pipeline", "assertions.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

producer <- "audit/scripts/audit_mder_device_assignment.R"
output_root <- file.path(
  root,
  "audit",
  "reconciliation",
  "preparation04",
  "mder_device_qc"
)
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)

paths <- pipeline_paths(root)
pinned_manifest_path <- file.path(
  paths$manifests,
  "pinned_downloads.csv"
)
metric_manifest_path <- file.path(
  paths$manifests,
  "metric_artifacts.csv"
)
pinned_manifest <- readr::read_csv(
  pinned_manifest_path,
  show_col_types = FALSE,
  progress = FALSE
)
metric_manifest <- readr::read_csv(
  metric_manifest_path,
  show_col_types = FALSE,
  progress = FALSE
)

assert_columns(
  pinned_manifest,
  c(
    "site",
    "modality",
    "repository",
    "commit",
    "doi",
    "source_url",
    "local_path",
    "sha256"
  ),
  object = "pinned source manifest"
)
assert_unique_key(
  pinned_manifest,
  c("site", "modality"),
  object = "pinned source manifest"
)

knust_sources <- pinned_manifest |>
  dplyr::filter(
    .data$site == "KNUST",
    .data$modality %in% c("light_glasses", "light_chest")
  )
if (nrow(knust_sources) != 2L) {
  abort_pipeline(
    "Expected two KNUST light-source rows; found %d",
    nrow(knust_sources)
  )
}

extract_device_assignments <- function(source_row) {
  source_environment <- new.env(parent = emptyenv())
  loaded_names <- load(
    source_row$local_path[[1L]],
    envir = source_environment
  )
  if (length(loaded_names) != 1L) {
    abort_pipeline(
      "Expected one object in %s; found %d",
      source_row$local_path[[1L]],
      length(loaded_names)
    )
  }
  light <- as.data.frame(
    source_environment[[loaded_names[[1L]]]],
    stringsAsFactors = FALSE
  )
  assert_columns(
    light,
    c("Id", "file.name", "position"),
    object = paste0("KNUST/", source_row$modality[[1L]])
  )

  assignments <- light |>
    dplyr::filter(
      !is.na(.data$file.name),
      nzchar(.data$file.name)
    ) |>
    dplyr::distinct(.data$Id, .data$file.name, .data$position) |>
    dplyr::mutate(
      serial = stringr::str_match(
        .data$file.name,
        "_Log_([0-9]+)_"
      )[, 2L],
      source_modality = source_row$modality[[1L]],
      source_repository = source_row$repository[[1L]],
      source_commit = source_row$commit[[1L]],
      source_doi = source_row$doi[[1L]],
      source_url = source_row$source_url[[1L]],
      source_sha256 = source_row$sha256[[1L]]
    )

  if (anyNA(assignments$serial)) {
    abort_pipeline(
      "Could not extract a device serial from %d KNUST filename(s)",
      sum(is.na(assignments$serial))
    )
  }
  assert_unique_key(
    assignments,
    c("Id", "position"),
    object = "KNUST device assignments"
  )
  assignments
}

assignments <- dplyr::bind_rows(lapply(
  seq_len(nrow(knust_sources)),
  function(row) {
    extract_device_assignments(knust_sources[row, , drop = FALSE])
  }
)) |>
  dplyr::arrange(.data$Id, .data$position)

if (
  nrow(assignments) != 30L ||
    dplyr::n_distinct(assignments$Id) != 15L ||
    any(table(assignments$Id) != 2L)
) {
  abort_pipeline(
    paste0(
      "Expected two device assignments for each of 15 KNUST participants; ",
      "found %d rows across %d participants"
    ),
    nrow(assignments),
    dplyr::n_distinct(assignments$Id)
  )
}

metric_paths <- c(
  glasses = file.path(
    paths$metrics,
    "metrics_glasses_participant_day.rds"
  ),
  chest = file.path(
    paths$metrics,
    "metrics_chest_participant_day.rds"
  )
)
missing_metric_paths <- metric_paths[!file.exists(metric_paths)]
if (length(missing_metric_paths) > 0L) {
  abort_pipeline(
    "Missing canonical metric artifact(s): %s",
    paste(missing_metric_paths, collapse = ", ")
  )
}

daily_metrics <- dplyr::bind_rows(lapply(
  unname(metric_paths),
  readRDS
)) |>
  dplyr::filter(.data$site == "KNUST")
assert_columns(
  daily_metrics,
  c(
    "site",
    "Id",
    "position",
    "local_date",
    "mder",
    "mder_medi_integral_lx_h",
    "mder_light_integral_lx_h",
    "mder_ordinary_paired_coverage",
    "mder_medi_profile_coverage",
    "mder_light_profile_coverage",
    "mder_minimum_support",
    "mder_estimable",
    "mder_failure_reason"
  ),
  object = "canonical participant-day metrics"
)
assert_unique_key(
  daily_metrics,
  c("site", "Id", "position", "local_date"),
  object = "canonical KNUST participant-day metrics"
)

device_days <- daily_metrics |>
  dplyr::left_join(
    assignments |>
      dplyr::select(
        "Id",
        "position",
        "serial",
        "file.name",
        "source_modality",
        "source_repository",
        "source_commit",
        "source_doi",
        "source_sha256"
      ),
    by = c("Id", "position"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    approved_anomalous_day = (
      .data$Id == "KNUST_S003" &
        .data$position == "glasses" &
        .data$local_date == as.Date("2024-10-27")
    ) | (
      .data$Id == "KNUST_S007" &
        .data$position == "chest" &
        .data$local_date == as.Date("2024-11-19")
    ),
    passes_registered_90pct_support = .data$mder_estimable &
      .data$mder_ordinary_paired_coverage >= 0.90 &
      .data$mder_medi_profile_coverage >= 0.90 &
      .data$mder_light_profile_coverage >= 0.90
  ) |>
  dplyr::group_by(.data$position) |>
  dplyr::mutate(
    mder_descending_rank_within_position = dplyr::if_else(
      is.finite(.data$mder),
      rank(-.data$mder, ties.method = "min", na.last = "keep"),
      NA_real_
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::arrange(
    .data$serial,
    .data$position,
    .data$Id,
    .data$local_date
  )

if (anyNA(device_days$serial)) {
  abort_pipeline(
    "Device assignment is missing for %d KNUST metric row(s)",
    sum(is.na(device_days$serial))
  )
}
target_days <- device_days |>
  dplyr::filter(.data$approved_anomalous_day)
if (
  nrow(target_days) != 2L ||
    !all(target_days$serial == "2962") ||
    !setequal(target_days$position, c("glasses", "chest"))
) {
  abort_pipeline(
    paste0(
      "The two approved anomalous days did not resolve to serial 2962 ",
      "at both placements"
    )
  )
}

finite_quantile <- function(value, probability) {
  value <- value[is.finite(value)]
  if (length(value) == 0L) {
    return(NA_real_)
  }
  as.numeric(stats::quantile(
    value,
    probs = probability,
    names = FALSE,
    type = 7
  ))
}

summarise_device_group <- function(data, groups) {
  data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(groups))) |>
    dplyr::summarise(
      participant_assignments = dplyr::n_distinct(.data$Id),
      participant_days = dplyr::n(),
      estimable_mder_days = sum(is.finite(.data$mder)),
      mder_mean = mean(.data$mder, na.rm = TRUE),
      mder_median = stats::median(.data$mder, na.rm = TRUE),
      mder_p90 = finite_quantile(.data$mder, 0.90),
      mder_p95 = finite_quantile(.data$mder, 0.95),
      mder_p99 = finite_quantile(.data$mder, 0.99),
      mder_maximum = if (any(is.finite(.data$mder))) {
        max(.data$mder, na.rm = TRUE)
      } else {
        NA_real_
      },
      estimable_days_excluding_approved_anomalies = sum(
        is.finite(.data$mder) & !.data$approved_anomalous_day
      ),
      mder_mean_excluding_approved_anomalies = {
        retained <- is.finite(.data$mder) &
          !.data$approved_anomalous_day
        if (any(retained)) {
          mean(.data$mder[retained])
        } else {
          NA_real_
        }
      },
      mder_p99_excluding_approved_anomalies = finite_quantile(
        .data$mder[!.data$approved_anomalous_day],
        0.99
      ),
      mder_maximum_excluding_approved_anomalies = {
        retained <- is.finite(.data$mder) &
          !.data$approved_anomalous_day
        if (any(retained)) {
          max(.data$mder[retained])
        } else {
          NA_real_
        }
      },
      registered_90pct_support_days = sum(
        .data$passes_registered_90pct_support,
        na.rm = TRUE
      ),
      approved_anomalous_days = sum(.data$approved_anomalous_day),
      .groups = "drop"
    )
}

device_position_summary <- summarise_device_group(
  device_days,
  c("serial", "position")
)
device_overall_summary <- summarise_device_group(
  device_days,
  "serial"
)

metric_inputs <- tibble::tibble(
  input_role = c(
    "glasses_participant_day_metrics",
    "chest_participant_day_metrics",
    "metric_artifact_manifest",
    "pinned_download_manifest",
    "knust_glasses_native_source",
    "knust_chest_native_source"
  ),
  path = c(
    unname(metric_paths[["glasses"]]),
    unname(metric_paths[["chest"]]),
    metric_manifest_path,
    pinned_manifest_path,
    knust_sources$local_path[
      knust_sources$modality == "light_glasses"
    ],
    knust_sources$local_path[
      knust_sources$modality == "light_chest"
    ]
  )
) |>
  dplyr::mutate(
    path = normalizePath(.data$path, winslash = "/", mustWork = TRUE),
    sha256 = vapply(.data$path, artifact_sha256, character(1)),
    bytes = unname(file.info(.data$path)$size),
    r_version = as.character(getRversion()),
    producer = producer
  )

outputs <- list(
  device_assignments = assignments,
  device_days = device_days,
  device_position_summary = device_position_summary,
  device_overall_summary = device_overall_summary,
  approved_anomalous_days = target_days,
  input_provenance = metric_inputs
)
output_metadata <- list()
for (name in names(outputs)) {
  output_metadata[[name]] <- write_csv_artifact(
    outputs[[name]],
    file.path(output_root, paste0(name, ".csv")),
    producer,
    metadata = list(
      artifact_type = paste0("mder_device_qc_", name),
      finding_id = "FIND-021",
      related_finding_id = "FIND-018"
    )
  )
}

manifest <- dplyr::bind_rows(lapply(
  output_metadata,
  manifest_row
)) |>
  dplyr::arrange(.data$path)
manifest_metadata <- write_csv_artifact(
  manifest,
  file.path(output_root, "artifact_manifest.csv"),
  producer,
  metadata = list(
    artifact_type = "mder_device_qc_manifest",
    finding_id = "FIND-021",
    related_finding_id = "FIND-018"
  )
)

cat(
  "MDER device-provenance audit passed:",
  nrow(assignments),
  "assignments;",
  nrow(device_days),
  "KNUST participant-days;",
  "both approved anomalous days use serial 2962.\n"
)
print(device_position_summary)
