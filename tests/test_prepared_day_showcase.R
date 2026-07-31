options(warn = 2)

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/prepared_day_showcase.R")

stopifnot(
  identical(prepared_day_showcase_seed(), 20260730L),
  identical(
    prepared_day_observed_runs(c(TRUE, TRUE, FALSE, TRUE, FALSE)),
    c(1L, 1L, NA_integer_, 2L, NA_integer_)
  )
)

root <- project_root()
paths <- prepared_day_showcase_paths(root)
coverage <- readRDS(paths$coverage)
solar_context <- readRDS(paths$solar_context)
site_metadata <- utils::read.csv(
  paths$site_metadata,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8"
)
first <- derive_prepared_day_showcase(
  coverage,
  solar_context,
  site_metadata
)
second <- derive_prepared_day_showcase(
  coverage,
  solar_context,
  site_metadata
)

stopifnot(
  identical(first$selected_summary, second$selected_summary),
  nrow(first$selected_summary) == 9L,
  nrow(first$source_data) == 9L * 1440L,
  all(first$selected_summary$valid_melEDI_percent >= 80),
  all(
    is.na(first$source_data$melEDI_lx[
      first$source_data$declared_nonwear
    ])
  ),
  setequal(
    unique(first$source_data$brown_reference_lx),
    c(1, 10, 250)
  )
)

plot <- make_prepared_day_showcase_plot(first$plot_data)
built <- ggplot2::ggplot_build(plot)
opaque_state_strips <- vapply(
  built$data,
  function(layer) {
    all(c("ymin", "ymax", "alpha") %in% names(layer)) &&
      nrow(layer) > 0L &&
      all(layer$ymin == -0.5) &&
      all(layer$ymax == 0) &&
      all(layer$alpha == 1)
  },
  logical(1)
)
stopifnot(sum(opaque_state_strips) == 2L)

message("Prepared-day showcase function tests: PASS")
