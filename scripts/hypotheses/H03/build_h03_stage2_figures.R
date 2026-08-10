# Rebuild H03 Stage 2 primary figures from immutable saved source CSVs.

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
source(file.path(root, "scripts/hypotheses/H03/h03_contract.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_data.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_reporting.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 figure rebuild requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c(
  "dplyr", "tidyr", "readr", "ggplot2", "scales", "LightLogR", "cowplot",
  "patchwork", "svglite", "ragg"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h03_abort(
    "Missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H03/build_h03_stage2_figures.R"
source_root <- file.path(root, "artifacts/11_source_data/H03")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H03")
figure_root <- file.path(root, "artifacts/10_figures/H03")
manifest_root <- file.path(root, "artifacts/12_manifests/H03")
inputs <- h03_load_inputs(root)
read_source <- function(name) {
  readr::read_csv(file.path(source_root, name), show_col_types = FALSE)
}
read_diagnostic <- function(name) {
  readr::read_csv(file.path(diagnostic_root, name), show_col_types = FALSE)
}

primary <- read_source("H03_primary_category_figure_data.csv")
site <- read_source("H03_near_eye_site_context_figure_data.csv")
paired <- read_source("H03_paired_placement_figure_data.csv")
residual <- read_source("H03_primary_residual_plot_data.csv")
residual_points <- read_source("H03_primary_residual_points.csv")
residual_acf <- read_diagnostic("H03_primary_residual_acf.csv")
zero_bins <- read_diagnostic("H03_zero_mass_calibration_bins.csv")
temporal_curves <- read_source("H03_temporal_category_curves.csv")
temporal_deviations <- read_source("H03_temporal_category_deviations.csv")
temporal_global <- read_source("H03_temporal_global_curves.csv")
temporal_support <- read_source("H03_temporal_clock_support.csv")

plots <- list(
  primary_figure = list(
    plot = h03_primary_category_figure(primary, inputs$categories),
    stem = "H03_primary_category_estimates",
    width = 12,
    height = 10
  ),
  site_figure = list(
    plot = h03_site_context_figure(site, inputs$categories, inputs$sites),
    stem = "H03_near_eye_site_context_estimates",
    width = 15,
    height = 10
  ),
  paired_figure = list(
    plot = h03_paired_placement_figure(paired, inputs$categories),
    stem = "H03_paired_placement_comparison",
    width = 8,
    height = 8
  ),
  residual_figure = list(
    plot = h03_residual_figure(
      residual,
      residual_points,
      residual_acf,
      zero_bins
    ),
    stem = "H03_primary_residual_diagnostics",
    width = 12,
    height = 15
  )
)

for (placement in c("Near-eye", "Chest")) {
  id <- if (identical(placement, "Near-eye")) "near_eye" else "chest"
  plots[[paste0("temporal_", id)]] <- list(
    plot = h03_temporal_figure(
      dplyr::filter(temporal_curves, .data$placement == .env$placement),
      dplyr::filter(
        temporal_deviations,
        .data$placement == .env$placement
      ),
      dplyr::filter(temporal_global, .data$placement == .env$placement),
      dplyr::filter(temporal_support, .data$placement == .env$placement),
      inputs$categories,
      placement
    ),
    stem = paste0("H03_temporal_", id),
    width = 16,
    height = 19.5
  )
}

metadata <- list()
for (id in names(plots)) {
  item <- plots[[id]]
  saved <- h03_save_plot(
    item$plot,
    item$stem,
    figure_root,
    width = item$width,
    height = item$height,
    producer = producer
  )
  for (extension in names(saved)) {
    metadata[[paste(id, extension, sep = "_")]] <- saved[[extension]]
  }
}

new_rows <- dplyr::bind_rows(lapply(metadata, manifest_row))
run_manifest_path <- file.path(manifest_root, "H03_stage2_run_manifest.csv")
run_manifest <- if (file.exists(run_manifest_path)) {
  readr::read_csv(run_manifest_path, show_col_types = FALSE)
} else {
  new_rows[0, ]
}
run_manifest <- run_manifest |>
  dplyr::filter(!.data$path %in% new_rows$path) |>
  dplyr::bind_rows(new_rows) |>
  dplyr::arrange(.data$path)
write_csv_artifact(run_manifest, run_manifest_path, producer)

message("H03 Stage 2 primary figures rebuilt from saved source CSVs")
