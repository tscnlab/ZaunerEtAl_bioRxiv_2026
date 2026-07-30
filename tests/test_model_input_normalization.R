source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/import_sources.R")
source("scripts/pipeline/model_input_acquisition.R")
source("scripts/pipeline/verify_model_input_acquisition.R")
source("scripts/pipeline/model_input_normalization.R")
source("scripts/pipeline/build_model_input_normalization.R")
source("scripts/pipeline/verify_model_input_normalization.R")

expect_pipeline_error <- function(expression, pattern) {
  error <- tryCatch(
    {
      force(expression)
      NULL
    },
    error = identity
  )
  stopifnot(
    inherits(error, "error"),
    grepl(pattern, conditionMessage(error))
  )
  invisible(error)
}

message("Checking UTC/local/wall coordinates across a DST fall-back")
dst_source <- as.POSIXct(
  c("2025-10-26 00:30:00", "2025-10-26 01:30:00"),
  tz = "UTC"
)
dst_coordinates <- derive_model_input_time_coordinates(
  dst_source,
  timezone = "Europe/Berlin",
  prefix = "event"
)
stopifnot(
  identical(
    dst_coordinates$event_local_label,
    c("2025-10-26 02:30:00", "2025-10-26 02:30:00")
  ),
  identical(
    dst_coordinates$event_utc_offset_minutes,
    c(120L, 60L)
  ),
  identical(dst_coordinates$event_is_dst, c(TRUE, FALSE)),
  dst_coordinates$event_wall[1L] == dst_coordinates$event_wall[2L],
  as.numeric(dst_coordinates$event_utc[1L]) !=
    as.numeric(dst_coordinates$event_utc[2L])
)

message("Checking per-site normalization and free-text exclusion")
synthetic_start <- as.POSIXct(
  c("2025-01-15 08:00:00", NA_character_),
  tz = "Europe/Berlin"
)
synthetic_end <- as.POSIXct(
  c("2025-01-15 09:00:00", NA_character_),
  tz = "Europe/Berlin"
)
attr(synthetic_start, "label") <- "Beginning timestamp"
attr(synthetic_end, "label") <- "Ending timestamp"
synthetic_form <- as.POSIXct(
  c("2025-01-15 09:05:00", NA_character_),
  tz = "UTC"
)
attr(synthetic_form, "label") <- "Starting time to fill in questionnaire"
synthetic_factor <- factor(
  c("Daylight", "Electric light"),
  levels = c("Daylight", "Electric light")
)
attr(synthetic_factor, "label") <- "Primary light source"
synthetic_object <- tibble::tibble(
  Id = c("P01", "P01"),
  Date = as.Date(c("2025-01-15", NA_character_)),
  start = synthetic_start,
  end = synthetic_end,
  lightsource_primary = synthetic_factor,
  activity_desc = c("private response", "another response"),
  startdate = synthetic_form,
  activity_desc_english = c("private response", "another response")
)
attr(synthetic_object$Id, "label") <- "Record ID"
attr(synthetic_object$Date, "label") <- "Date"
synthetic_record <- list(
  site = "TEST",
  modality = "lightexposurediary",
  manifest = tibble::tibble(
    repository = "SyntheticRelease",
    commit = paste(rep("a", 40L), collapse = ""),
    doi = "10.0000/synthetic",
    relative_source_path = "data/lightexposurediary.RData",
    object_name = "lightexposurediary",
    sha256 = paste(rep("b", 64L), collapse = "")
  ),
  site_source = tibble::tibble(
    location = "Berlin, Germany",
    timezone = "Europe/Berlin"
  ),
  data = synthetic_object
)
synthetic_normalized <- normalize_model_input_site(synthetic_record)
stopifnot(
  !any(
    c(
      "activity_desc",
      "activity_desc_english",
      "start",
      "end",
      "startdate"
    ) %in%
      names(synthetic_normalized)
  ),
  identical(
    levels(synthetic_normalized$lightsource_primary),
    levels(synthetic_factor)
  ),
  identical(
    as.integer(synthetic_normalized$lightsource_primary),
    as.integer(synthetic_factor)
  ),
  identical(
    synthetic_normalized$interval_analysis_eligible,
    c(TRUE, FALSE)
  ),
  identical(
    synthetic_normalized$interval_issue_code,
    c(NA_character_, "missing_start_and_end")
  ),
  all(
    synthetic_normalized$form_timestamp_excluded_from_interval_analysis
  ),
  all(synthetic_normalized$site == "TEST"),
  all(synthetic_normalized$source_repository == "SyntheticRelease")
)
synthetic_audits <- build_model_input_source_audits(
  list(synthetic_record)
)
stopifnot(
  nrow(synthetic_audits$free_text) == 2L,
  all(synthetic_audits$free_text$nonblank_rows == 2L),
  !any(synthetic_audits$free_text$content_exported),
  synthetic_audits$labels$source_label[
    synthetic_audits$labels$source_column == "lightsource_primary"
  ] ==
    "Primary light source"
)

message("Checking explicit duplicate-key failure reporting")
duplicate_key_audit <- build_model_input_key_audit(
  list(
    demographics = tibble::tibble(
      site = c("A", "A"),
      Id = c("P01", "P01")
    )
  )
)
stopifnot(
  duplicate_key_audit$status[
    duplicate_key_audit$site == "_all_sites"
  ] ==
    "FAIL",
  duplicate_key_audit$duplicated_key_rows[
    duplicate_key_audit$site == "_all_sites"
  ] ==
    2L
)

message("Independently verifying the production normalized artifacts")
production_verification <- verify_model_input_normalization(
  root = project_root()
)
production_manifest_path <- model_input_normalization_paths(
  project_root()
)$manifest
production_manifest <- readr::read_csv(
  production_manifest_path,
  show_col_types = FALSE
)
stopifnot(
  production_verification$status == "PASS",
  identical(
    names(production_manifest),
    model_input_normalization_manifest_columns()
  ),
  !"written_utc" %in% names(production_manifest),
  nrow(production_verification$artifact_summary) == 15L,
  identical(
    as.integer(
      production_verification$artifact_summary$rows[seq_len(7L)]
    ),
    c(191L, 186L, 184L, 184L, 1174L, 30199L, 1276L)
  ),
  production_verification$interval_summary$analysis_eligible[
    production_verification$interval_summary$modality == "lightexposurediary" &
      production_verification$interval_summary$timestamp_role ==
        "analysis_interval"
  ] ==
    30172L,
  production_verification$interval_summary$quarantined[
    production_verification$interval_summary$modality == "sleepdiaries"
  ] ==
    1L
)

message("Checking byte-stable normalization regeneration")
first_manifest_sha256 <-
  production_verification$normalization_manifest_sha256
invisible(build_model_input_normalization(root = project_root()))
second_production_verification <- verify_model_input_normalization(
  root = project_root()
)
stopifnot(
  identical(second_production_verification$status, "PASS"),
  identical(
    second_production_verification$normalization_manifest_sha256,
    first_manifest_sha256
  )
)

message("Checking independent manifest-tamper rejection")
tampered_manifest <- readr::read_csv(
  production_manifest_path,
  show_col_types = FALSE
)
tampered_manifest$sha256[1L] <- paste(rep("0", 64L), collapse = "")
tampered_manifest_path <- tempfile(
  "model-input-normalization-tampered-",
  fileext = ".csv"
)
on.exit(unlink(tampered_manifest_path), add = TRUE)
readr::write_csv(tampered_manifest, tampered_manifest_path, na = "")
expect_pipeline_error(
  verify_model_input_normalization(
    root = project_root(),
    normalization_manifest_path = tampered_manifest_path
  ),
  "differs from manifest"
)

message("Model-input normalization tests passed")
