root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/assertions.R"))
source(file.path(root, "scripts/pipeline/state_alignment.R"))
source(file.path(root, "scripts/pipeline/time_axes.R"))
source(file.path(root, "scripts/pipeline/time_support.R"))
source(file.path(root, "scripts/pipeline/reference_profiles.R"))
source(file.path(root, "scripts/pipeline/state_interval_projection.R"))
source(file.path(root, "scripts/pipeline/metric_derivation.R"))

targets <- tibble::tribble(
  ~site, ~Id, ~local_date,
  "KNUST", "KNUST_S001", as.Date("2024-10-13"),
  "KNUST", "KNUST_S005", as.Date("2024-11-08"),
  "KNUST", "KNUST_S010", as.Date("2024-12-14")
)

metric_path <- file.path(
  root,
  "artifacts/05_metrics/metrics_glasses_participant_day.rds"
)
coverage_path <- file.path(
  root,
  "artifacts/03_coverage/light_glasses_coverage.rds"
)
censoring_path <- file.path(
  root,
  "artifacts/05_metrics/metrics_glasses_censoring_diagnostics.csv"
)

metric <- readRDS(metric_path)
coverage <- readRDS(coverage_path)
censoring <- readr::read_csv(
  censoring_path,
  show_col_types = FALSE,
  progress = FALSE
)

paths <- pipeline_paths(root)
state_inputs <- read_metric_state_interval_inputs(
  state_interval_root = file.path(paths$aligned, "state_intervals"),
  state_interval_manifest_path = file.path(
    paths$manifests,
    "state_interval_artifacts.csv"
  ),
  sites = sort(unique(as.character(coverage$site))),
  run_label = "full"
)
true_grid <- build_complete_metric_grid(
  coverage,
  state_intervals = state_inputs,
  placement = "glasses",
  object = "canonical glasses coverage"
)

target_metrics <- metric |>
  dplyr::inner_join(targets, by = c("site", "Id", "local_date")) |>
  dplyr::select(
    .data$site,
    .data$Id,
    .data$position,
    .data$local_date,
    .data$l10_mean_medi_lx,
    .data$l10_onset_clock_minute,
    .data$l10_midpoint_clock_minute,
    .data$l10_offset_clock_minute
  )

target_censoring <- censoring |>
  dplyr::mutate(local_date = as.Date(.data$local_date)) |>
  dplyr::inner_join(targets, by = c("site", "Id", "local_date"))

if (!"MEDI_eligible" %in% names(coverage)) {
  stop("Coverage artifact lacks MEDI_eligible")
}

window_evidence <- purrr::pmap_dfr(target_metrics, function(
  site,
  Id,
  position,
  local_date,
  l10_mean_medi_lx,
  l10_onset_clock_minute,
  l10_midpoint_clock_minute,
  l10_offset_clock_minute
) {
  day <- true_grid |>
    dplyr::filter(
      .data$site == .env$site,
      .data$Id == .env$Id,
      as.Date(.data$local_date) == .env$local_date
    ) |>
    dplyr::arrange(.data$datetime_utc)

  wall <- collapse_metric_wall_minutes(day)
  onset <- as.integer(l10_onset_clock_minute)
  selected_clock <- (onset + 0:599) %% 1440L
  selected <- wall |>
    dplyr::filter(.data$clock_minute %in% .env$selected_clock)
  valid <- is.finite(selected$MEDI)
  shifted <- selected$MEDI[valid] + 0.1
  log_mean <- mean(log10(shifted))
  shifted_mean <- 10^log_mean
  restored_raw <- shifted_mean - 0.1
  tolerance <- 100 * .Machine$double.eps *
    max(1, abs(shifted_mean), 0.1)

  tibble::tibble(
    site = site,
    Id = Id,
    position = position,
    local_date = local_date,
    selected_onset_clock_minute = onset,
    selected_midpoint_clock_minute = l10_midpoint_clock_minute,
    selected_offset_clock_minute = l10_offset_clock_minute,
    expected_window_minutes = 600L,
    wall_rows = nrow(selected),
    observed_weight_minutes = sum(valid),
    valid_wall_minutes = sum(valid),
    missing_wall_minutes = sum(!valid),
    zero_valid_wall_minutes = sum(selected$MEDI[valid] == 0),
    positive_valid_wall_minutes = sum(selected$MEDI[valid] > 0),
    minimum_valid_medi_lx = min(selected$MEDI[valid]),
    maximum_valid_medi_lx = max(selected$MEDI[valid]),
    selected_log_mean = log_mean,
    shifted_mean_lx = shifted_mean,
    raw_restored_mean_lx = restored_raw,
    current_metric_value_lx = l10_mean_medi_lx,
    numerical_zero_tolerance_lx = tolerance,
    raw_within_tolerance = abs(restored_raw) <= tolerance
  )
})

scan_metric_values <- function(path, placement, dataset) {
  data <- readRDS(path)
  fields <- intersect(
    c(
      "daily_geometric_mean_medi_lx",
      "m10_mean_medi_lx",
      "l10_mean_medi_lx"
    ),
    names(data)
  )
  purrr::map_dfr(fields, function(field) {
    value <- data[[field]]
    tolerance <- 100 * .Machine$double.eps *
      pmax(1, abs(value + 0.1), 0.1)
    index <- which(is.finite(value) & value != 0 & abs(value) <= tolerance)
    if (length(index) == 0L) {
      return(tibble::tibble(
        dataset = character(),
        placement = character(),
        metric_field = character(),
        site = character(),
        Id = character(),
        local_date = as.Date(character()),
        value = numeric(),
        tolerance = numeric()
      ))
    }
    tibble::tibble(
      dataset = dataset,
      placement = placement,
      metric_field = field,
      site = as.character(data$site[index]),
      Id = as.character(data$Id[index]),
      local_date = as.Date(data$local_date[index]),
      value = value[index],
      tolerance = tolerance[index]
    )
  })
}

primary_scan <- dplyr::bind_rows(
  scan_metric_values(
    file.path(root, "artifacts/05_metrics/metrics_glasses_participant_day.rds"),
    "glasses",
    "primary"
  ),
  scan_metric_values(
    file.path(root, "artifacts/05_metrics/metrics_chest_participant_day.rds"),
    "chest",
    "primary"
  )
)

scan_hourly_values <- function(path, placement, dataset) {
  data <- readRDS(path)
  value <- data$metric_value_lx
  tolerance <- 100 * .Machine$double.eps *
    pmax(1, abs(value + 0.1), 0.1)
  index <- which(is.finite(value) & value != 0 & abs(value) <= tolerance)
  tibble::tibble(
    dataset = dataset,
    placement = placement,
    metric_field = "one_hour_zero_aware_geometric_mean_medi",
    site = as.character(data$site[index]),
    Id = as.character(data$Id[index]),
    local_date = as.Date(data$local_date[index]),
    clock_hour = data$clock_hour[index],
    value = value[index],
    tolerance = tolerance[index]
  )
}

hourly_scan <- dplyr::bind_rows(
  scan_hourly_values(
    file.path(root, "artifacts/05_metrics/metrics_glasses_one_hour.rds"),
    "glasses",
    "primary"
  ),
  scan_hourly_values(
    file.path(root, "artifacts/05_metrics/metrics_chest_one_hour.rds"),
    "chest",
    "primary"
  )
)

gap_path <- file.path(
  root,
  "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds"
)
gap <- readRDS(gap_path)
gap_metric_ids <- sort(unique(as.character(gap$metric_id)))
gap_value <- gap$manuscript_prepared_value
gap_tolerance <- 100 * .Machine$double.eps *
  pmax(1, abs(gap_value + 0.1), 0.1)
gap_index <- which(
  is.finite(gap_value) & gap_value != 0 & abs(gap_value) <= gap_tolerance
)
gap_scan <- tibble::tibble(
  dataset = "gap_timing_unaware",
  placement = as.character(gap$position[gap_index]),
  metric_field = as.character(gap$metric_id[gap_index]),
  site = as.character(gap$site[gap_index]),
  Id = as.character(gap$Id[gap_index]),
  local_date = as.Date(gap$local_date[gap_index]),
  value = gap_value[gap_index],
  tolerance = gap_tolerance[gap_index]
)

output <- list(
  r_version = R.version.string,
  package_versions = c(
    dplyr = as.character(utils::packageVersion("dplyr")),
    tibble = as.character(utils::packageVersion("tibble")),
    readr = as.character(utils::packageVersion("readr"))
  ),
  input_sha256 = c(
    metrics = digest::digest(file = metric_path, algo = "sha256"),
    coverage = digest::digest(file = coverage_path, algo = "sha256"),
    censoring = digest::digest(file = censoring_path, algo = "sha256"),
    gap = digest::digest(file = gap_path, algo = "sha256")
  ),
  target_metrics = target_metrics,
  target_censoring = target_censoring,
  window_evidence = window_evidence,
  primary_scan = primary_scan,
  hourly_scan = hourly_scan,
  gap_metric_ids = gap_metric_ids,
  gap_scan = gap_scan,
  gap_names = names(gap),
  gap_dimensions = dim(gap)
)

saveRDS(output, file.path(root, "tmp/audit_l10_numerical_zero_output.rds"))
print(output[c(
  "r_version",
  "package_versions",
  "input_sha256",
  "target_metrics",
  "window_evidence",
  "primary_scan",
  "hourly_scan",
  "gap_metric_ids",
  "gap_scan",
  "gap_dimensions"
)])
