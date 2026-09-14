options(warn = 2)

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/base_model_data.R")
source("scripts/pipeline/build_base_model_data.R")
source("scripts/pipeline/verify_base_model_data_artifacts.R")

expect_base_model_error <- function(expression, pattern) {
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

with_base_model_working_directory <- function(path, expression) {
  previous <- setwd(path)
  on.exit(setwd(previous), add = TRUE)
  force(expression)
}

message("Checking pure participant-metadata and availability contracts")
synthetic_factor <- factor(
  c("low", "high"),
  levels = c("low", "high")
)
attr(synthetic_factor, "label") <- "Synthetic ordered response"
synthetic_duration <- as.difftime(c(1, 2), units = "hours")
attr(synthetic_duration, "label") <- "Synthetic duration"
synthetic_normalized <- list(
  demographics = tibble::tibble(
    site = "TEST",
    Id = c("P01", "P02"),
    age = c(20, 30)
  ),
  chronotype = tibble::tibble(
    site = "TEST",
    Id = c("P01", "P02"),
    duration = synthetic_duration
  ),
  leba = tibble::tibble(
    site = "TEST",
    Id = c("P01", "P02"),
    response = synthetic_factor
  ),
  vlsq8 = tibble::tibble(
    site = "TEST",
    Id = c("P01", "P02"),
    score = c(4, 8)
  ),
  exercisediary = tibble::tibble(
    site = "TEST",
    Id = c("P01", "P03"),
    Date = as.Date(c("2026-01-01", "2026-01-01"))
  ),
  lightexposurediary = tibble::tibble(
    site = "TEST",
    source_row = 1:2,
    Id = c("P01", "P02")
  ),
  sleepdiaries = tibble::tibble(
    site = "TEST",
    source_row = 1:2,
    Id = c("P01", "P02")
  )
)
synthetic_metrics <- list(
  glasses_participant = tibble::tibble(
    site = "TEST",
    Id = "P01",
    position = "glasses",
    value = 1
  ),
  chest_participant = tibble::tibble(
    site = "TEST",
    Id = "P02",
    position = "chest",
    value = 2
  )
)
synthetic_metadata <- base_model_build_participant_metadata(
  synthetic_normalized,
  synthetic_metrics
)
stopifnot(
  nrow(synthetic_metadata) == 3L,
  identical(synthetic_metadata$Id, c("P01", "P02", "P03")),
  identical(levels(synthetic_metadata$response), c("low", "high")),
  identical(
    attr(synthetic_metadata$response, "label", exact = TRUE),
    "Synthetic ordered response"
  ),
  identical(
    attr(synthetic_metadata$duration, "label", exact = TRUE),
    "Synthetic duration"
  ),
  synthetic_metadata$has_glasses_metrics[
    synthetic_metadata$Id == "P01"
  ],
  synthetic_metadata$has_chest_metrics[
    synthetic_metadata$Id == "P02"
  ],
  synthetic_metadata$has_exercisediary[
    synthetic_metadata$Id == "P03"
  ],
  !synthetic_metadata$has_demographics[
    synthetic_metadata$Id == "P03"
  ]
)
synthetic_availability <- base_model_build_participant_availability_audit(
  synthetic_metadata
)
stopifnot(
  nrow(synthetic_availability) == 3L,
  synthetic_availability$metric_scope[
    synthetic_availability$Id == "P03"
  ] ==
    "no_light_metric",
  synthetic_availability$no_participant_questionnaire[
    synthetic_availability$Id == "P03"
  ],
  all(!synthetic_availability$filtering_applied)
)

message("Checking explicit duplicate normalized-key rejection")
duplicate_normalized <- synthetic_normalized
duplicate_normalized$demographics <- dplyr::bind_rows(
  duplicate_normalized$demographics,
  duplicate_normalized$demographics[1L, , drop = FALSE]
)
expect_base_model_error(
  base_model_build_participant_metadata(
    duplicate_normalized,
    synthetic_metrics
  ),
  "duplicated row"
)

message("Checking zero-loss many-to-one site-context joining")
synthetic_day <- tibble::tibble(
  site = "TEST",
  Id = "P01",
  position = "glasses",
  local_date = as.Date("2026-01-01"),
  metric_value = 10
)
synthetic_context <- tibble::tibble(
  site = "TEST",
  local_date = as.Date("2026-01-01"),
  photoperiod_hours = 8
)
synthetic_join <- base_model_join_context(
  synthetic_day,
  synthetic_context,
  placement = "glasses",
  resolution = "participant_day",
  input_id = "synthetic_day"
)
stopifnot(
  nrow(synthetic_join$data) == 1L,
  synthetic_join$data$metric_value == 10,
  synthetic_join$data$photoperiod_hours == 8,
  synthetic_join$audit$unmatched_rows == 0L,
  synthetic_join$audit$row_order_preserved,
  synthetic_join$audit$key_set_preserved
)

message("Checking the M10/L10 model-ready registry firewall")
synthetic_boundary_day <- synthetic_day
synthetic_boundary_day$m10_onset_clock_minute <- 480
synthetic_boundary_day$m10_offset_clock_minute <- 1080
synthetic_boundary_day$l10_onset_clock_minute <- 1200
synthetic_boundary_day$l10_offset_clock_minute <- 360
synthetic_firewall <- base_model_apply_metric_registry_firewall(
  synthetic_boundary_day,
  input_id = "synthetic_boundary_day",
  placement = "glasses",
  resolution = "participant_day"
)
stopifnot(
  nrow(synthetic_firewall$data) == nrow(synthetic_boundary_day),
  ncol(synthetic_firewall$data) == ncol(synthetic_boundary_day) - 4L,
  synthetic_firewall$audit$prohibited_column_count == 4L,
  synthetic_firewall$audit$row_order_preserved,
  synthetic_firewall$audit$key_set_preserved,
  !synthetic_firewall$audit$outcome_values_recalculated,
  synthetic_firewall$audit$status == "PASS",
  length(intersect(
    names(synthetic_firewall$data),
    base_model_internal_window_boundary_columns()
  )) ==
    0L
)
expect_base_model_error(
  base_model_apply_metric_registry_firewall(
    dplyr::select(
      synthetic_boundary_day,
      -dplyr::all_of("local_date")
    ),
    input_id = "synthetic_participant_with_boundary",
    placement = "glasses",
    resolution = "participant"
  ),
  "unexpected"
)

expect_base_model_error(
  base_model_join_context(
    synthetic_day,
    dplyr::mutate(
      synthetic_context,
      local_date = as.Date("2026-01-02")
    ),
    placement = "glasses",
    resolution = "participant_day",
    input_id = "synthetic_day"
  ),
  "1 unmatched"
)

message("Building and verifying production inputs in an isolated output root")
canonical_root <- project_root()
test_root <- tempfile("nathealth-base-model-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
outside_working_directory <- tempfile("nathealth-base-model-cwd-")
dir.create(outside_working_directory, recursive = TRUE)
on.exit(unlink(outside_working_directory, recursive = TRUE), add = TRUE)
first_build <- with_base_model_working_directory(
  outside_working_directory,
  build_base_model_data_artifacts(
    root = canonical_root,
    output_root = test_root
  )
)
first_verification <- with_base_model_working_directory(
  outside_working_directory,
  verify_base_model_data_artifacts(
    root = canonical_root,
    output_root = test_root
  )
)
stopifnot(
  first_build$status == "PASS",
  first_verification$status == "PASS",
  nrow(first_build$manifest) == 21L,
  first_verification$participant_metadata_rows == 191L,
  nrow(first_build$data$glasses_participant_day_context) == 816L,
  nrow(first_build$data$chest_participant_day_context) == 902L,
  nrow(first_build$data$glasses_participant) == 141L,
  nrow(first_build$data$chest_participant) == 154L,
  nrow(first_build$data$glasses_30_minute_context) == 39168L,
  nrow(first_build$data$chest_30_minute_context) == 43296L,
  nrow(first_build$data$glasses_one_hour_context) == 19584L,
  nrow(first_build$data$chest_one_hour_context) == 21648L,
  all(first_build$audits$metric_key_join$status == "PASS"),
  nrow(first_build$audits$metric_registry_firewall) == 8L,
  all(first_build$audits$metric_registry_firewall$status == "PASS"),
  all(
    first_build$audits$metric_registry_firewall$prohibited_column_count[
      first_build$audits$metric_registry_firewall$resolution ==
        "participant_day"
    ] ==
      4L
  ),
  all(
    first_build$audits$metric_registry_firewall$prohibited_column_count[
      first_build$audits$metric_registry_firewall$resolution !=
        "participant_day"
    ] ==
      0L
  ),
  all(vapply(
    first_build$data,
    function(data) {
      length(intersect(
        names(data),
        base_model_internal_window_boundary_columns()
      )) ==
        0L
    },
    logical(1)
  )),
  all(first_build$audits$modality_key_join$status == "PASS"),
  all(first_build$audits$metadata_fields$status == "PASS"),
  all(
    !first_build$audits$metric_metadata_availability$filtering_applied
  )
)

message("Checking the corrected upstream TUM_S001 availability")
tum_s001 <- first_build$audits$participant_availability |>
  dplyr::filter(.data$site == "TUM", .data$Id == "TUM_S001")
stopifnot(
  nrow(tum_s001) == 1L,
  tum_s001$metric_scope == "glasses_and_chest",
  tum_s001$has_any_light_metric,
  tum_s001$has_demographics,
  tum_s001$has_chronotype,
  tum_s001$has_leba,
  tum_s001$has_vlsq8,
  tum_s001$has_exercisediary,
  tum_s001$has_lightexposurediary,
  tum_s001$has_sleepdiaries,
  !tum_s001$no_participant_questionnaire,
  !any(
    first_build$audits$participant_availability$site == "TUM" &
      first_build$audits$participant_availability$Id == "TUM_S101"
  ),
  all(!is.na(first_build$audits$input_provenance$bytes))
)

message("Checking byte-stable regeneration")
first_paths <- c(
  first_build$paths$data_paths,
  first_build$paths$audit_paths,
  manifest = first_build$paths$manifest
)
first_hashes <- vapply(first_paths, artifact_sha256, character(1))
second_build <- build_base_model_data_artifacts(
  root = canonical_root,
  output_root = test_root
)
second_verification <- verify_base_model_data_artifacts(
  root = canonical_root,
  output_root = test_root
)
second_hashes <- vapply(first_paths, artifact_sha256, character(1))
stopifnot(
  second_build$status == "PASS",
  second_verification$status == "PASS",
  identical(first_hashes, second_hashes),
  identical(
    first_build$input_bundle_sha256,
    second_build$input_bundle_sha256
  )
)

message("Checking independent output-manifest tamper rejection")
tampered_manifest <- readr::read_csv(
  second_build$paths$manifest,
  show_col_types = FALSE,
  progress = FALSE
)
tampered_manifest$sha256[[1L]] <- paste(rep("0", 64L), collapse = "")
readr::write_csv(
  tampered_manifest,
  second_build$paths$manifest,
  na = ""
)
expect_base_model_error(
  verify_base_model_data_artifacts(
    root = canonical_root,
    output_root = test_root
  ),
  "manifest integrity failed"
)

message("Base-model data tests passed")
