# Rebuild H04 Stage 2 figures from their durable paired source-data CSVs.

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
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_reporting.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H04 figure building requires R 4.6.1", call. = FALSE)
}
required <- c("dplyr", "readr", "ggplot2", "scales", "LightLogR", "patchwork")
missing <- required[
  !vapply(required, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing) > 0L) {
  stop("Missing synchronized package(s): ", paste(missing, collapse = ", "))
}

source_directory <- file.path(root, "artifacts/11_source_data/H04")
figure_directory <- file.path(root, "artifacts/10_figures/H04")
producer <- "scripts/hypotheses/H04/build_h04_stage2_figures.R"
read_source <- function(filename) {
  path <- file.path(source_directory, filename)
  if (!file.exists(path)) {
    stop("Missing H04 figure source data: ", path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE)
}

primary <- read_source("H04_primary_category_figure.csv")
site_activity <- read_source("H04_site_activity_figure.csv")
paired <- read_source("H04_paired_placement_figure.csv")
calibration <- read_source("H04_diagnostic_calibration_figure.csv")
acf <- read_source("H04_diagnostic_acf_figure.csv")

invisible(h04_save_plot(
  h04_primary_figure(primary),
  "H04_primary_category_estimates",
  figure_directory,
  width = 12.5,
  height = 9.5,
  producer = producer
))
invisible(h04_save_plot(
  h04_site_activity_figure(site_activity),
  "H04_site_activity_estimates",
  figure_directory,
  width = 16,
  height = 9.5,
  producer = producer
))
invisible(h04_save_plot(
  h04_paired_figure(paired),
  "H04_paired_placement_comparison",
  figure_directory,
  width = 9.5,
  height = 5.8,
  producer = producer
))
invisible(h04_save_plot(
  h04_diagnostic_figure(calibration, acf),
  "H04_primary_diagnostics",
  figure_directory,
  width = 13,
  height = 5.8,
  producer = producer
))

message("H04 Stage 2 figures rebuilt from paired source data")
