source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/metric_display_registry.R")

root <- project_root()
registry <- read_metric_display_registry(root)

stopifnot(
  nrow(registry) == 22L,
  identical(names(registry), metric_display_registry_columns()),
  setequal(
    unique(registry$manuscript_category),
    metric_display_categories()
  ),
  !any(grepl(
    "(^|_)(m10|l10)_(onset|offset)($|_)",
    registry$metric_id,
    perl = TRUE
  )),
  all(
    c(
      "m10_mean_medi",
      "m10_midpoint",
      "l10_mean_medi",
      "l10_midpoint",
      "mean_timing_above_250"
    ) %in%
      registry$metric_id
  ),
  registry$manuscript_name[
    registry$metric_id == "mean_timing_above_250"
  ] ==
    "Mean timing of exposure above 250 lx melEDI",
  registry$manuscript_category[
    registry$metric_id == "mean_timing_above_250"
  ] ==
    "timing-based"
)

probe <- data.frame(
  metric_id = c("m10_midpoint", "dose_time_sensitive_corrected_medi"),
  value = c(1, 2)
)
joined <- attach_metric_display(probe, root = root)
stopifnot(
  identical(
    joined$manuscript_name,
    c("Midpoint of the brightest 10 hours", "melEDI dose")
  ),
  identical(
    joined$manuscript_category,
    c("timing-based", "exposure-history-based")
  )
)

bad <- registry
bad$manuscript_name[bad$metric_id == "mean_timing_above_250"] <-
  "Support-aware mean timing"
stopifnot(inherits(
  try(validate_metric_display_registry(bad), silent = TRUE),
  "try-error"
))

message("Metric display registry tests passed")
