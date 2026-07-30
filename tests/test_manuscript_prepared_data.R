source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/metric_display_registry.R")
source("scripts/pipeline/manuscript_prepared_data.R")
source("scripts/pipeline/build_manuscript_prepared_data.R")
source("scripts/pipeline/verify_manuscript_prepared_data_artifacts.R")

expect_manuscript_prepared_error <- function(expression, pattern) {
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

message("Checking scenario and metric contracts")
mapping <- manuscript_prepared_metric_mapping(project_root())
output_mapping <- manuscript_prepared_output_metric_mapping(project_root())
stopifnot(
  manuscript_prepared_scenario_id() == "manuscript_prepared_data",
  manuscript_prepared_model_implementation_id() == "new_h01_h11",
  nrow(mapping) == 20L,
  sum(mapping$selected_for_h01) == 17L,
  !any(
    grepl(
      "(^|_)(m10|l10)_(onset|offset)($|_)",
      mapping$metric_id,
      perl = TRUE
    )
  ),
  setequal(
    mapping$metric_id,
    read_metric_display_registry(project_root())$metric_id[
      read_metric_display_registry(project_root())$metric_id %in%
        mapping$metric_id
    ]
  ),
  output_mapping$variant_label[
    output_mapping$metric_id == "dose_time_sensitive_corrected_medi"
  ] ==
    "Uncorrected manuscript-prepared dose",
  output_mapping$variant_label[
    output_mapping$metric_id == "mder_ratio_of_integrals"
  ] ==
    "Mean of epoch-wise melEDI/illuminance ratios"
)

message("Checking isolated RData object-name enforcement")
temporary_rdata <- tempfile(fileext = ".RData")
isolated_one <- data.frame(value = 1)
save(isolated_one, file = temporary_rdata)
loaded_one <- manuscript_prepared_load_rdata(
  temporary_rdata,
  "isolated_one"
)
stopifnot(
  identical(names(loaded_one), "isolated_one"),
  identical(loaded_one$isolated_one$value, 1)
)
expect_manuscript_prepared_error(
  manuscript_prepared_load_rdata(
    temporary_rdata,
    "unexpected_object"
  ),
  "contains object"
)
unlink(temporary_rdata)

message("Checking repeated local-clock occurrence keys")
synthetic_clock <- tibble::tibble(
  site = "TEST",
  Id = "TEST_S001",
  Datetime = as.POSIXct(
    c(
      "2025-10-26 02:00:00",
      "2025-10-26 02:00:00",
      "2025-10-26 02:01:00"
    ),
    tz = "UTC"
  )
)
synthetic_keyed <- manuscript_prepared_add_occurrence(synthetic_clock)
stopifnot(
  identical(synthetic_keyed$local_occurrence, c(1L, 2L, 1L))
)
assert_unique_key(
  synthetic_keyed,
  c("site", "Id", "Datetime", "local_occurrence"),
  "synthetic repeated clock"
)

message("Checking the only allowed correction")
correction <- manuscript_prepared_correction_manifest(project_root())
stopifnot(
  identical(correction$correction_id, "DEV-056"),
  correction$affected_rows == 7L,
  identical(correction$corrected_value, "TUM_S001"),
  identical(correction$erroneous_value, "TUM_S101"),
  !correction$scientific_light_values_changed
)

message("Independently verifying production scenario artifacts")
production_verification <-
  verify_manuscript_prepared_data_artifacts(project_root())
stopifnot(
  identical(production_verification$status, "PASS"),
  identical(
    production_verification$output_rows,
    c(
      participant_metrics = 590L,
      participant_day_metrics = 27328L,
      thirty_minute_data = 81744L,
      one_hour_data = 40464L
    )
  ),
  identical(production_verification$correction_ids, "DEV-056"),
  identical(
    production_verification$paired_csv_rds_artifacts,
    c(
      "participant_metrics",
      "participant_day_metrics",
      "thirty_minute_data",
      "one_hour_data",
      "normalized_input_references"
    )
  ),
  identical(
    production_verification$one_hour_rows$one_hour_rows,
    c(21288L, 19176L)
  )
)

message("Checking isolated build and byte-stable regeneration")
temporary_output <- tempfile("manuscript-prepared-data-")
dir.create(temporary_output, recursive = TRUE)
on.exit(unlink(temporary_output, recursive = TRUE), add = TRUE)
invisible(
  build_manuscript_prepared_data(
    root = project_root(),
    output_root = temporary_output
  )
)
temporary_verification <- verify_manuscript_prepared_data_artifacts(
  root = project_root(),
  output_root = temporary_output
)
temporary_manifest <- manuscript_prepared_output_paths(
  project_root(),
  temporary_output
)$manifest
first_manifest_sha256 <- artifact_sha256(temporary_manifest)
invisible(
  build_manuscript_prepared_data(
    root = project_root(),
    output_root = temporary_output
  )
)
second_manifest_sha256 <- artifact_sha256(temporary_manifest)
stopifnot(
  identical(temporary_verification$status, "PASS"),
  identical(first_manifest_sha256, second_manifest_sha256)
)

message("Checking paired-CSV tamper rejection after manifest update")
temporary_paths <- manuscript_prepared_output_paths(
  project_root(),
  temporary_output
)
tampered_csv <- readr::read_csv(
  temporary_paths$csv[["participant_metrics"]],
  show_col_types = FALSE
)
tampered_csv$manuscript_prepared_value[[1L]] <-
  tampered_csv$manuscript_prepared_value[[1L]] + 1
readr::write_csv(
  tampered_csv,
  temporary_paths$csv[["participant_metrics"]],
  na = ""
)
tampered_manifest <- readr::read_csv(
  temporary_paths$manifest,
  show_col_types = FALSE
)
tampered_row <-
  tampered_manifest$artifact_id == "participant_metrics_csv"
tampered_manifest$sha256[tampered_row] <- artifact_sha256(
  temporary_paths$csv[["participant_metrics"]]
)
tampered_manifest$bytes[tampered_row] <- as.numeric(
  file.info(temporary_paths$csv[["participant_metrics"]])$size
)
readr::write_csv(tampered_manifest, temporary_paths$manifest, na = "")
expect_manuscript_prepared_error(
  verify_manuscript_prepared_data_artifacts(
    root = project_root(),
    output_root = temporary_output
  ),
  "differs from its RDS authority"
)

message("Manuscript-prepared-data sensitivity tests passed")
