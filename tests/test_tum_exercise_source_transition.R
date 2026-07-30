source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/import_sources.R")
source("scripts/pipeline/model_input_acquisition.R")

canonical_column_sha256 <- function(column) {
  values <- if (is.factor(column)) {
    as.integer(column)
  } else if (inherits(column, c("Date", "POSIXt", "difftime"))) {
    as.numeric(column)
  } else if (is.character(column)) {
    enc2utf8(column)
  } else {
    column
  }
  canonical <- list(
    class = class(column),
    type = typeof(column),
    values = values,
    levels = levels(column),
    label = attr(column, "label", exact = TRUE),
    units = attr(column, "units", exact = TRUE),
    tzone = attr(column, "tzone", exact = TRUE)
  )
  unname(unclass(as.character(openssl::sha256(
    serialize(canonical, NULL, version = 3)
  ))))
}

message("Checking the fail-closed TUM exercise source transition")
root <- project_root()
contract_path <- file.path(
  root,
  "audit",
  "reconciliation",
  "preparation06",
  "tum_exercise_source_transition_columns.csv"
)
contract <- readr::read_csv(
  contract_path,
  show_col_types = FALSE,
  progress = FALSE
)
expected_contract_columns <- c(
  "site",
  "modality",
  "predecessor_commit",
  "predecessor_sha256",
  "predecessor_bytes",
  "current_commit",
  "current_sha256",
  "current_bytes",
  "column",
  "analytic_disposition",
  "excluded_from_analytic_rds",
  "content_exported",
  "predecessor_column_sha256",
  "current_column_sha256",
  "expected_value_differences",
  "expected_missingness_differences",
  "expected_changed_rows"
)
stopifnot(
  identical(names(contract), expected_contract_columns),
  nrow(contract) == 12L,
  all(contract$site == "TUM"),
  all(contract$modality == "exercisediary"),
  !any(contract$content_exported)
)

manifest <- readr::read_csv(
  file.path(
    root,
    "artifacts",
    "12_manifests",
    "model_input_acquisition.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
source_row <- manifest[
  manifest$site == "TUM" &
    manifest$modality == "exercisediary",
  ,
  drop = FALSE
]
stopifnot(
  nrow(source_row) == 1L,
  isTRUE(source_row$source_pin_applied),
  source_row$commit == unique(contract$current_commit),
  source_row$sha256 == unique(contract$current_sha256),
  source_row$bytes == unique(contract$current_bytes),
  source_row$expected_sha256 == source_row$sha256,
  source_row$expected_bytes == source_row$bytes
)

source_path <- model_input_absolute_path(
  source_row$cache_path,
  root = root,
  must_work = TRUE
)
source_environment <- new.env(parent = emptyenv())
loaded_name <- load(source_path, envir = source_environment)
stopifnot(identical(loaded_name, "exercisediary"))
exercise_source <- source_environment[[loaded_name]]
stopifnot(
  identical(names(exercise_source), contract$column),
  artifact_sha256(source_path) == unique(contract$current_sha256),
  unname(file.info(source_path)$size) == unique(contract$current_bytes)
)

observed_column_sha256 <- vapply(
  exercise_source,
  canonical_column_sha256,
  character(1)
)
stopifnot(identical(
  unname(observed_column_sha256),
  contract$current_column_sha256
))

changed_columns <- contract$column[
  contract$predecessor_column_sha256 != contract$current_column_sha256
]
unchanged_columns <- setdiff(contract$column, changed_columns)
stopifnot(
  identical(changed_columns, c("Id", "type_english")),
  all(
    contract$predecessor_column_sha256[
      match(unchanged_columns, contract$column)
    ] ==
      contract$current_column_sha256[
        match(unchanged_columns, contract$column)
      ]
  )
)

id_contract <- contract[contract$column == "Id", , drop = FALSE]
translated_text_contract <- contract[
  contract$column == "type_english",
  ,
  drop = FALSE
]
stopifnot(
  id_contract$analytic_disposition == "retained_analytic_key",
  !id_contract$excluded_from_analytic_rds,
  id_contract$expected_value_differences == 4L,
  id_contract$expected_missingness_differences == 0L,
  id_contract$expected_changed_rows == "4|5|6|7",
  translated_text_contract$analytic_disposition == "excluded_free_text",
  translated_text_contract$excluded_from_analytic_rds,
  !translated_text_contract$content_exported,
  translated_text_contract$expected_value_differences == 3L,
  translated_text_contract$expected_missingness_differences == 3L,
  translated_text_contract$expected_changed_rows == "4|5|7"
)

stopifnot(
  identical(exercise_source$Id[4:7], rep("TUM_S001", 4L)),
  identical(
    as.character(exercise_source$Date[4:7]),
    as.character(as.Date("2024-05-16") + 0:3)
  ),
  sum(exercise_source$Id == "TUM_S001") == 7L,
  sum(exercise_source$Id == "TUM_S101") == 0L,
  !anyDuplicated(exercise_source[c("Id", "Date")]),
  all(is.na(exercise_source$type_english[c(4L, 5L, 7L)]))
)

analytic_changes <- contract$column[
  contract$predecessor_column_sha256 != contract$current_column_sha256 &
    !contract$excluded_from_analytic_rds
]
stopifnot(identical(analytic_changes, "Id"))

normalized <- readRDS(file.path(
  root,
  "artifacts",
  "06_model_data",
  "normalized_inputs",
  "exercisediary.rds"
))
normalized_tum <- normalized[
  normalized$site == "TUM",
  ,
  drop = FALSE
]
normalized_tum <- normalized_tum[
  order(normalized_tum$source_row),
  ,
  drop = FALSE
]
stopifnot(
  identical(normalized_tum$Id, exercise_source$Id),
  identical(normalized_tum$Date, exercise_source$Date),
  all(normalized_tum$source_commit == unique(contract$current_commit)),
  all(normalized_tum$source_sha256 == unique(contract$current_sha256)),
  !any(
    c(
      "type",
      "type_english",
      "source_Id",
      "source_key_correction_applied",
      "source_key_correction_id"
    ) %in%
      names(normalized)
  )
)

tampered_source <- exercise_source
tampered_source$sedentary[1L] <- tampered_source$sedentary[1L] +
  as.difftime(1, units = "mins")
stopifnot(
  canonical_column_sha256(tampered_source$sedentary) !=
    contract$current_column_sha256[
      contract$column == "sedentary"
    ]
)

message("TUM exercise source transition test passed")
