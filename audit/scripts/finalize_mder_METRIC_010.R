# Finalize the independently verified METRIC-010 MDER audit artifacts.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/assertions.R"))
source(file.path(root, "scripts/pipeline/verify_metric_derivation_mder.R"))

paths <- pipeline_paths(root)
key <- c("site", "Id", "position", "local_date")
output_root <- file.path(paths$diagnostics, "mder_METRIC-010")
snapshot_root <- file.path(output_root, "superseded_METRIC-003")
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)

read_csv <- function(path) {
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    na = c("", "NA")
  )
}

load_named_object <- function(path, expected) {
  environment <- new.env(parent = emptyenv())
  loaded <- load(path, envir = environment)
  if (!expected %in% loaded) {
    abort_pipeline(
      "%s does not contain expected object `%s`; found: %s",
      path,
      expected,
      paste(loaded, collapse = ", ")
    )
  }
  environment[[expected]]
}

finite_summary <- function(data) {
  finite <- is.finite(data$value)
  value <- data$value[finite]
  tibble::tibble(
    participant_days_available = nrow(data),
    participant_days_estimable = sum(finite),
    participant_days_missing = sum(!finite),
    participants_available = dplyr::n_distinct(data$Id),
    participants_estimable = dplyr::n_distinct(data$Id[finite]),
    mean = mean(value),
    sd = stats::sd(value),
    minimum = min(value),
    q05 = as.numeric(stats::quantile(value, 0.05, names = FALSE)),
    q25 = as.numeric(stats::quantile(value, 0.25, names = FALSE)),
    median = stats::median(value),
    q75 = as.numeric(stats::quantile(value, 0.75, names = FALSE)),
    q95 = as.numeric(stats::quantile(value, 0.95, names = FALSE)),
    maximum = max(value)
  )
}

paired_summary <- function(data, comparator, comparator_label) {
  comparator_column <- paste0("value_", comparator)
  keep <- is.finite(data$value_primary) & is.finite(data[[comparator_column]])
  difference <- data$value_primary[keep] - data[[comparator_column]][keep]
  tibble::tibble(
    placement = unique(data$position),
    comparison = paste0("primary_minus_", comparator_label),
    common_key_rows = sum(
      !is.na(data$value_primary) | !is.na(data[[comparator_column]])
    ),
    paired_estimable_days = sum(keep),
    paired_participants = dplyr::n_distinct(data$Id[keep]),
    primary_mean_common = mean(data$value_primary[keep]),
    comparator_mean_common = mean(data[[comparator_column]][keep]),
    mean_difference = mean(difference),
    median_difference = stats::median(difference),
    mean_absolute_difference = mean(abs(difference)),
    correlation = stats::cor(
      data$value_primary[keep],
      data[[comparator_column]][keep]
    )
  )
}

verification <- verify_metric_derivation_mder(root)
if (!identical(verification$status, "PASS")) {
  abort_pipeline("Independent METRIC-010 verification did not pass")
}

placements <- verification$placements
primary <- lapply(placements, function(placement) {
  data <- readRDS(file.path(
    paths$metrics,
    paste0("metrics_", placement, "_participant_day.rds")
  ))
  data |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      position = as.character(.data$position),
      local_date = as.Date(.data$local_date),
      value = as.numeric(.data$mder),
      viable_ratio_minutes = as.integer(.data$mder_viable_ratio_minutes),
      viable_ratio_fraction = as.numeric(.data$mder_viable_ratio_fraction),
      estimable = as.logical(.data$mder_estimable),
      failure_reason = as.character(.data$mder_failure_reason)
    ) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(key)))
}) |>
  dplyr::bind_rows()

superseded <- lapply(placements, function(placement) {
  data <- read_csv(file.path(
    snapshot_root,
    paste0("mder_ratio_of_integrals_", placement, ".csv")
  ))
  data |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      position = as.character(.data$position),
      local_date = as.Date(.data$local_date),
      value = as.numeric(.data$mder)
    ) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(key)))
}) |>
  dplyr::bind_rows()

gap_timing_unaware <- lapply(placements, function(placement) {
  object_name <- paste0("metric_", placement, "_participantday")
  data <- load_named_object(
    file.path(root, "data", paste0("metrics_separate_", placement, ".RData")),
    object_name
  )
  assert_columns(
    data,
    c("site", "Id", "Date", "MDER"),
    object = paste0(placement, " gap-timing-unaware participant-day data")
  )
  data |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      position = placement,
      local_date = as.Date(as.character(.data$Date)),
      value = as.numeric(.data$MDER)
    ) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(key)))
}) |>
  dplyr::bind_rows()

for (object_name in c("primary", "superseded", "gap_timing_unaware")) {
  assert_unique_key(
    get(object_name),
    key,
    object = paste0(object_name, " MDER comparison data")
  )
}

distribution_summary <- dplyr::bind_rows(
  primary |>
    dplyr::group_by(.data$position) |>
    dplyr::group_modify(~ finite_summary(.x)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      dataset = "primary",
      estimand = "mean_of_viable_positive_one_minute_ratios"
    ),
  superseded |>
    dplyr::group_by(.data$position) |>
    dplyr::group_modify(~ finite_summary(.x)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      dataset = "superseded_ratio_of_integrals",
      estimand = "ratio_of_paired_channel_integrals"
    ),
  gap_timing_unaware |>
    dplyr::group_by(.data$position) |>
    dplyr::group_modify(~ finite_summary(.x)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      dataset = "gap_timing_unaware",
      estimand = "mean_of_available_epoch_ratios_under_V0_preparation"
    )
) |>
  dplyr::select(dplyr::all_of(c("dataset", "estimand")), dplyr::everything()) |>
  dplyr::arrange(.data$position, .data$dataset)

comparison_values <- primary |>
  dplyr::rename(value_primary = "value") |>
  dplyr::select(dplyr::all_of(c(key, "value_primary"))) |>
  dplyr::full_join(
    superseded |>
      dplyr::rename(value_superseded = "value"),
    by = key,
    relationship = "one-to-one"
  ) |>
  dplyr::full_join(
    gap_timing_unaware |>
      dplyr::rename(value_gap = "value"),
    by = key,
    relationship = "one-to-one"
  ) |>
  dplyr::arrange(dplyr::across(dplyr::all_of(key)))

paired_comparisons <- split(
  comparison_values,
  comparison_values$position
) |>
  lapply(function(data) {
    dplyr::bind_rows(
      paired_summary(data, "superseded", "superseded_ratio_of_integrals"),
      paired_summary(data, "gap", "gap_timing_unaware")
    )
  }) |>
  dplyr::bind_rows() |>
  dplyr::arrange(.data$placement, .data$comparison)

support_by_site <- primary |>
  dplyr::group_by(.data$position, .data$site) |>
  dplyr::summarise(
    participants = dplyr::n_distinct(.data$Id),
    participant_days = dplyr::n(),
    estimable_mder_days = sum(.data$estimable),
    excluded_mder_days = sum(!.data$estimable),
    median_viable_ratio_minutes = stats::median(.data$viable_ratio_minutes),
    median_viable_ratio_fraction = stats::median(.data$viable_ratio_fraction),
    below_viable_ratio_fraction = sum(
      .data$failure_reason == "below_viable_ratio_fraction",
      na.rm = TRUE
    ),
    no_viable_momentary_ratio = sum(
      .data$failure_reason == "no_viable_momentary_ratio",
      na.rm = TRUE
    ),
    .groups = "drop"
  ) |>
  dplyr::arrange(.data$position, .data$site)

non_mder_invariance <- lapply(placements, function(placement) {
  current <- readRDS(file.path(
    paths$metrics,
    paste0("metrics_", placement, "_participant_day.rds")
  )) |>
    dplyr::mutate(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      position = as.character(.data$position),
      local_date = as.Date(.data$local_date)
    ) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(key)))
  prior <- readRDS(file.path(
    paths$model_data,
    "base",
    paste0("metrics_", placement, "_participant_day_context.rds")
  )) |>
    dplyr::mutate(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      position = as.character(.data$position),
      local_date = as.Date(.data$local_date)
    ) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(key)))
  key_identical <- vapply(
    key,
    function(column) identical(current[[column]], prior[[column]]),
    logical(1)
  )
  if (!all(key_identical)) {
    abort_pipeline("%s current/prior participant-day keys differ", placement)
  }
  columns <- setdiff(
    intersect(names(current), names(prior)),
    c(key, grep("^mder($|_)", intersect(names(current), names(prior)), value = TRUE))
  )
  differences <- vapply(columns, function(column) {
    observed <- current[[column]]
    expected <- prior[[column]]
    if (is.numeric(observed) && is.numeric(expected)) {
      mismatch <- is.na(observed) != is.na(expected)
      paired <- !is.na(observed) & !is.na(expected)
      mismatch[paired] <- abs(observed[paired] - expected[paired]) > 1e-12
    } else {
      mismatch <- is.na(observed) != is.na(expected)
      paired <- !is.na(observed) & !is.na(expected)
      mismatch[paired] <- as.character(observed[paired]) != as.character(expected[paired])
    }
    sum(mismatch)
  }, integer(1))
  tibble::tibble(
    placement = placement,
    shared_non_mder_columns = length(columns),
    columns_with_any_difference = sum(differences > 0L),
    differing_cells = sum(differences),
    exact_non_mder_invariance = all(differences == 0L),
    prior_base_model_manifest_sha256 = artifact_sha256(file.path(
      paths$manifests,
      "base_model_data_artifacts.csv"
    ))
  )
}) |>
  dplyr::bind_rows()
if (!all(non_mder_invariance$exact_non_mder_invariance)) {
  abort_pipeline("A non-MDER participant-day field changed under METRIC-010")
}

verification_summary <- verification$placement_summary |>
  dplyr::mutate(
    status = verification$status,
    metric = verification$metric,
    minimum_viable_ratio_fraction = verification$viable_ratio_fraction,
    metric_manifest_sha256 = artifact_sha256(file.path(
      paths$manifests,
      "metric_artifacts.csv"
    )),
    immutable_inputs = verification$immutable_inputs,
    independently_recalculated = verification$ratio_recalculated,
    r_version = paste(R.version$major, R.version$minor, sep = ".")
  )

output_paths <- c(
  verification_summary = file.path(output_root, "verification_summary.csv"),
  distribution_summary = file.path(output_root, "distribution_summary.csv"),
  paired_comparisons = file.path(output_root, "paired_comparisons.csv"),
  support_by_site = file.path(output_root, "support_by_site.csv"),
  key_level_comparison = file.path(output_root, "key_level_comparison.csv"),
  non_mder_invariance = file.path(output_root, "non_mder_invariance.csv")
)
output_objects <- list(
  verification_summary,
  distribution_summary,
  paired_comparisons,
  support_by_site,
  comparison_values,
  non_mder_invariance
)
for (index in seq_along(output_paths)) {
  readr::write_csv(output_objects[[index]], output_paths[[index]], na = "")
}

input_paths <- c(
  file.path(paths$manifests, "metric_artifacts.csv"),
  file.path(snapshot_root, "snapshot_manifest.csv"),
  file.path(root, "data", "metrics_separate_glasses.RData"),
  file.path(root, "data", "metrics_separate_chest.RData"),
  file.path(paths$manifests, "base_model_data_artifacts.csv")
)
audit_manifest <- dplyr::bind_rows(
  tibble::tibble(
    role = "input",
    path = normalizePath(input_paths, winslash = "/", mustWork = TRUE)
  ),
  tibble::tibble(
    role = "output",
    path = normalizePath(output_paths, winslash = "/", mustWork = TRUE)
  ),
  tibble::tibble(
    role = "producer",
    path = normalizePath(
      file.path(root, "audit/scripts/finalize_mder_METRIC_010.R"),
      winslash = "/",
      mustWork = TRUE
    )
  )
) |>
  dplyr::mutate(
    sha256 = vapply(.data$path, artifact_sha256, character(1)),
    bytes = unname(file.info(.data$path)$size),
    decision_id = "METRIC-010",
    produced_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    r_version = paste(R.version$major, R.version$minor, sep = ".")
  )

audit_manifest_path <- file.path(output_root, "audit_manifest.csv")
readr::write_csv(audit_manifest, audit_manifest_path, na = "")
cat(
  "METRIC-010 audit PASS\n",
  "manifest=", artifact_sha256(audit_manifest_path), "\n",
  "metric_manifest=", verification_summary$metric_manifest_sha256[[1L]], "\n",
  sep = ""
)
print(distribution_summary)
print(paired_comparisons)
print(non_mder_invariance)
