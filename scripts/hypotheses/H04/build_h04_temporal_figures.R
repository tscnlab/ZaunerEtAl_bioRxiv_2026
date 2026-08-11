# Rebuild H04 temporal figures from H03-aligned pointwise-interval source data.

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
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_reporting.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_temporal.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H04 temporal figure building requires R 4.6.1", call. = FALSE)
}
required <- c(
  "dplyr",
  "readr",
  "ggplot2",
  "scales",
  "LightLogR",
  "patchwork"
)
missing <- required[
  !vapply(required, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing) > 0L) {
  stop("Missing synchronized package(s): ", paste(missing, collapse = ", "))
}

producer <- "scripts/hypotheses/H04/build_h04_temporal_figures.R"
source_directory <- file.path(root, "artifacts/11_source_data/H04")
figure_directory <- file.path(root, "artifacts/10_figures/H04")
read_source <- function(filename) {
  path <- file.path(source_directory, filename)
  if (!file.exists(path)) {
    stop("Missing H04 temporal source data: ", path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE)
}

for (id in c("near_eye", "chest")) {
  curves <- read_source(paste0("H04_temporal_", id, "_curves.csv"))
  support <- read_source(paste0("H04_temporal_", id, "_support.csv"))
  placement <- unique(curves$placement)
  stopifnot(length(placement) == 1L)
  invisible(h04_save_plot(
    h04_temporal_figure(curves, support, placement, interval = "pointwise"),
    paste0("H04_temporal_", id),
    figure_directory,
    width = 14,
    height = 12,
    producer = producer
  ))
}

message("H04 temporal figures rebuilt from durable source data")
