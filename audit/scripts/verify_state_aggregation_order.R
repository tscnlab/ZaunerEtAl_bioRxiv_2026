library(dplyr)
library(readr)

source("scripts/pipeline/assertions.R")
source("scripts/pipeline/import_sources.R")
source("scripts/pipeline/time_axes.R")
source("scripts/pipeline/state_alignment.R")

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
manifest <- read_csv(
  file.path(root, "artifacts/12_manifests/pinned_downloads.csv"),
  show_col_types = FALSE
)
site_sources <- read_site_sources(file.path(root, "config/site_sources.csv"))

load_one <- function(site, modality) {
  row <- manifest |>
    filter(
      .data$site == .env$site,
      .data$modality == .env$modality
    )
  stopifnot(nrow(row) == 1L)
  environment <- new.env(parent = emptyenv())
  object_name <- load(row$local_path, envir = environment)
  stopifnot(length(object_name) == 1L)
  environment[[object_name]]
}

boundary_rows <- list()
boundary_index <- 1L
for (site in site_sources$site) {
  for (modality in c("sleepdiaries", "wearlog")) {
    source_data <- load_one(site, modality)
    columns <- if (identical(modality, "sleepdiaries")) {
      c("sleepprep", "wake")
    } else {
      c("start", "end")
    }
    for (column in columns) {
      value <- source_data[[column]]
      seconds <- as.numeric(value) %% 60
      boundary_rows[[boundary_index]] <- tibble(
        site = site,
        modality = modality,
        column = column,
        records = length(value),
        finite_boundaries = sum(is.finite(as.numeric(value))),
        nonminute_boundaries = sum(
          is.finite(as.numeric(value)) & abs(seconds) > 1e-9
        )
      )
      boundary_index <- boundary_index + 1L
    }
  }
}
boundary_audit <- bind_rows(boundary_rows)
print(as.data.frame(boundary_audit))

rise_sleep <- load_one("RISE", "sleepdiaries")
nonminute_sleep <- rise_sleep |>
  mutate(seconds_within_minute = as.numeric(.data$sleepprep) %% 60) |>
  filter(
    is.finite(.data$seconds_within_minute),
    .data$seconds_within_minute > 0
  ) |>
  select("Id", "sleepprep", "wake", "seconds_within_minute")
stopifnot(
  sum(boundary_audit$nonminute_boundaries) == 3L,
  nrow(nonminute_sleep) == 3L,
  all(nonminute_sleep$seconds_within_minute > 30)
)
print(as.data.frame(nonminute_sleep))

timezone <- site_sources$timezone[site_sources$site == "RISE"]
wear <- load_one("RISE", "wearlog")
sleep_intervals <- prepare_sleep_intervals(
  rise_sleep,
  timezone = timezone,
  id_cols = "Id"
)$intervals
wear_intervals <- prepare_wear_intervals(
  wear,
  timezone = timezone,
  id_cols = "Id"
)$intervals

mode_like_lightlogr <- function(value) {
  names(which.max(table(value, useNA = "ifany")))
}

affected_ids <- sort(unique(nonminute_sleep$Id))
results <- list()
for (placement in c("glasses", "chest")) {
  raw <- load_one("RISE", paste0("light_", placement)) |>
    ungroup() |>
    filter(.data$Id %in% affected_ids)
  annotated <- annotate_time_axes(
    raw,
    timezone = timezone,
    datetime_col = "Datetime",
    site = "RISE"
  )
  annotated$position <- placement
  raw_states <- attach_states_checked(
    annotated,
    sleep_intervals,
    stream_keys = "Id"
  )
  raw_states <- attach_states_checked(
    raw_states,
    wear_intervals,
    stream_keys = "Id"
  )
  raw_modal <- raw_states |>
    mutate(
      minute_utc = as.POSIXct(
        floor(as.numeric(.data$datetime_utc) / 60) * 60,
        origin = "1970-01-01",
        tz = "UTC"
      )
    ) |>
    group_by(.data$Id, .data$minute_utc) |>
    summarise(
      raw_modal_sleep = mode_like_lightlogr(.data$sleep),
      raw_modal_brown = mode_like_lightlogr(.data$State.Brown),
      raw_modal_wear = mode_like_lightlogr(.data$wear),
      native_epochs = n(),
      .groups = "drop"
    )
  minute_target <- raw_modal |>
    transmute(
      .data$Id,
      Datetime = .data$minute_utc,
      datetime_utc = .data$minute_utc
    )
  minute_states <- attach_states_checked(
    minute_target,
    sleep_intervals,
    stream_keys = "Id"
  )
  minute_states <- attach_states_checked(
    minute_states,
    wear_intervals,
    stream_keys = "Id"
  )
  comparison <- raw_modal |>
    left_join(
      select(
        minute_states,
        "Id",
        minute_utc = "datetime_utc",
        minute_sleep = "sleep",
        minute_brown = "State.Brown",
        minute_wear = "wear"
      ),
      by = c("Id", "minute_utc"),
      relationship = "one-to-one"
    ) |>
    mutate(
      sleep_equal = dplyr::coalesce(
        .data$raw_modal_sleep == .data$minute_sleep,
        is.na(.data$raw_modal_sleep) & is.na(.data$minute_sleep)
      ),
      brown_equal = dplyr::coalesce(
        .data$raw_modal_brown == .data$minute_brown,
        is.na(.data$raw_modal_brown) & is.na(.data$minute_brown)
      ),
      wear_equal = dplyr::coalesce(
        .data$raw_modal_wear == .data$minute_wear,
        is.na(.data$raw_modal_wear) & is.na(.data$minute_wear)
      )
    )
  results[[placement]] <- tibble(
    placement = placement,
    participants = n_distinct(comparison$Id),
    minutes = nrow(comparison),
    sleep_mismatches = sum(!comparison$sleep_equal),
    brown_mismatches = sum(!comparison$brown_equal),
    wear_mismatches = sum(!comparison$wear_equal)
  )
}

result <- bind_rows(results)
print(as.data.frame(result))
stopifnot(
  all(result$sleep_mismatches == 0L),
  all(result$brown_mismatches == 0L),
  all(result$wear_mismatches == 0L)
)
