# Build compact H04 Stage 2 support artifacts from the frozen fitted frames.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H04 support building requires R 4.6.1", call. = FALSE)
}
required <- c("dplyr", "tibble", "readr", "openssl")
missing <- required[
  !vapply(required, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing) > 0L) {
  stop("Missing synchronized package(s): ", paste(missing, collapse = ", "))
}

producer <- "scripts/hypotheses/H04/build_h04_stage2_support.R"
model_data_directory <- file.path(root, "artifacts/06_model_data/H04")
frame_path <- file.path(model_data_directory, "H04_model_frames.rds")
if (!file.exists(frame_path)) {
  stop("Missing H04 fitted-frame artifact: ", frame_path, call. = FALSE)
}
frames <- readRDS(frame_path)$main
long <- dplyr::bind_rows(frames$near_eye, frames$chest)

hour <- long |>
  dplyr::distinct(
    .data$placement,
    .data$analysis_hour_id,
    .data$site,
    .data$participant,
    .data$participant_day,
    .data$k
  )
k_distribution <- hour |>
  dplyr::group_by(.data$placement, .data$k) |>
  dplyr::summarise(
    unique_participant_hours = dplyr::n(),
    participants = dplyr::n_distinct(.data$participant),
    participant_days = dplyr::n_distinct(.data$participant_day),
    .groups = "drop"
  ) |>
  dplyr::group_by(.data$placement) |>
  dplyr::mutate(
    percent_of_fitted_hours = 100 *
      .data$unique_participant_hours /
      sum(.data$unique_participant_hours)
  ) |>
  dplyr::ungroup()

summarise_support <- function(data) {
  data |>
    dplyr::summarise(
      unique_participant_hours = dplyr::n_distinct(.data$analysis_hour_id),
      long_rows = dplyr::n(),
      effective_weighted_hours = sum(.data$analysis_weight),
      participants = dplyr::n_distinct(.data$participant),
      participant_days = dplyr::n_distinct(.data$participant_day),
      .groups = "drop"
    )
}
weighted_support <- dplyr::bind_rows(
  long |>
    dplyr::group_by(.data$placement) |>
    summarise_support() |>
    dplyr::mutate(
      summary_level = "placement",
      site = NA_character_,
      activity = NA_character_,
      .before = 1
    ),
  long |>
    dplyr::group_by(.data$placement, .data$site) |>
    summarise_support() |>
    dplyr::mutate(
      summary_level = "site",
      activity = NA_character_,
      site = as.character(.data$site),
      .before = 1
    ),
  long |>
    dplyr::group_by(.data$placement, .data$activity) |>
    summarise_support() |>
    dplyr::mutate(
      summary_level = "category",
      site = NA_character_,
      activity = as.character(.data$activity),
      .before = 1
    )
) |>
  dplyr::ungroup() |>
  dplyr::select(
    "summary_level",
    "placement",
    "site",
    "activity",
    "unique_participant_hours",
    "long_rows",
    "effective_weighted_hours",
    "participants",
    "participant_days"
  )

weight_check <- long |>
  dplyr::group_by(.data$placement, .data$analysis_hour_id) |>
  dplyr::summarise(
    rows = dplyr::n(),
    k = dplyr::first(.data$k),
    weight_sum = sum(.data$analysis_weight),
    .groups = "drop"
  )
stopifnot(
  all(weight_check$rows == weight_check$k),
  max(abs(weight_check$weight_sum - 1)) < 1e-10,
  all(
    abs(
      weighted_support$unique_participant_hours[
        weighted_support$summary_level == "placement"
      ] -
        weighted_support$effective_weighted_hours[
          weighted_support$summary_level == "placement"
        ]
    ) <
      1e-10
  )
)

write_csv_artifact(
  k_distribution,
  file.path(model_data_directory, "H04_k_distribution.csv"),
  producer
)
write_csv_artifact(
  weighted_support,
  file.path(model_data_directory, "H04_weighted_support_totals.csv"),
  producer
)

message("H04 Stage 2 fitted support artifacts built")
