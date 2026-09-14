#!/usr/bin/env Rscript

# Rebuild H03-aligned H04 reader figures from durable paired source data.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_reporting.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_temporal.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H04 Stage 3 reader figures require R 4.6.1", call. = FALSE)
}
required <- c(
  "cowplot", "dplyr", "ggplot2", "LightLogR", "patchwork", "readr",
  "scales", "svglite", "tidyr"
)
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0L) {
  stop("Missing synchronized package(s): ", paste(missing, collapse = ", "))
}

producer <- "scripts/hypotheses/H04/build_h04_stage3_reader_figures.R"
source_root <- file.path(root, "artifacts/11_source_data/H04")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H04")
figure_root <- file.path(root, "artifacts/10_figures/H04")
read_source <- function(directory, name) {
  path <- file.path(directory, name)
  if (!file.exists(path)) {
    stop("Missing H04 reader source data: ", path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE)
}
figure_metadata <- list()
save_reader <- function(plot, stem, width, height) {
  saved <- h04_save_plot(
    plot,
    stem,
    figure_root,
    width,
    height,
    producer
  )
  for (extension in names(saved)) {
    figure_metadata[[paste(stem, extension, sep = "_")]] <<-
      saved[[extension]]
  }
  invisible(saved)
}

save_reader(
  h04_primary_figure(
    read_source(
      source_root,
      "H04_reader_heterogeneity_category_figure.csv"
    ),
    mean_title = "Heterogeneity-model standardized one-hour melEDI",
    ratio_title = "Activity-by-site ratios versus At home",
    caption_extra = paste(
      "The five named categories come from the activity-by-site interaction model.",
      "Other is an additive-model display-only estimate."
    )
  ),
  "H04_reader_heterogeneity_category_estimates",
  12.8,
  10.2
)
save_reader(
  h04_site_activity_figure(read_source(
    source_root,
    "H04_site_activity_figure.csv"
  )),
  "H04_site_activity_estimates",
  16,
  10.5
)
save_reader(
  h04_paired_figure(read_source(
    source_root,
    "H04_paired_placement_figure.csv"
  )),
  "H04_paired_placement_comparison",
  9.5,
  7.2
)
save_reader(
  h04_reader_diagnostic_figure(
    read_source(source_root, "H04_reader_primary_residual_bins.csv"),
    read_source(source_root, "H04_reader_primary_residual_points.csv"),
    read_source(diagnostic_root, "H04_reader_primary_residual_acf.csv"),
    read_source(source_root, "H04_reader_primary_zero_calibration.csv")
  ),
  "H04_primary_diagnostics",
  13.4,
  12.2
)

for (id in c("near_eye", "chest")) {
  curves <- read_source(
    source_root,
    paste0("H04_reader_temporal_", id, "_curves.csv")
  )
  placement <- unique(curves$placement)
  stopifnot(length(placement) == 1L)
  save_reader(
    h04_temporal_reader_figure(
      curves,
      read_source(
        source_root,
        paste0("H04_reader_temporal_", id, "_ratios.csv")
      ),
      read_source(
        source_root,
        paste0("H04_reader_temporal_", id, "_global.csv")
      ),
      read_source(
        source_root,
        paste0("H04_reader_temporal_", id, "_support.csv")
      ),
      placement
    ),
    paste0("H04_temporal_", id),
    15.75,
    12.5
  )
}

save_reader(
  h04_reader_diagnostic_figure(
    read_source(source_root, "H04_reader_temporal_residual_bins.csv"),
    read_source(source_root, "H04_reader_temporal_residual_points.csv"),
    read_source(diagnostic_root, "H04_reader_temporal_residual_acf.csv"),
    read_source(source_root, "H04_reader_temporal_zero_calibration.csv"),
    title_prefix = "Exploratory temporal-model",
    caption_text = paste0(
      "Residual and zero-mass panels combine concurrent activity memberships back to one 1/k-weighted participant-hour.\n",
      "The autocorrelation panel retains activity-specific boundary-aware runs; concurrent rows never become lag neighbours.\n",
      "All panels are descriptive model checks; the temporal curves remain exploratory pointwise summaries."
    )
  ),
  "H04_temporal_diagnostics",
  13.4,
  12.2
)

derivation_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H04/H04_stage3_reader_derivation_manifest.csv"
)
if (!file.exists(derivation_manifest_path)) {
  stop("Missing H04 reader derivation manifest", call. = FALSE)
}
derivation_manifest <- readr::read_csv(
  derivation_manifest_path,
  show_col_types = FALSE
)
figure_manifest <- dplyr::bind_rows(lapply(
  names(figure_metadata),
  function(role) {
    item <- figure_metadata[[role]]
    tibble::tibble(
      role = role,
      path = item$path,
      sha256 = item$sha256,
      bytes = item$bytes,
      rows = NA_integer_,
      columns = NA_integer_,
      producer = item$producer,
      r_version = item$r_version,
      written_utc = item$written_utc
    )
  }
))
missing_roles <- setdiff(figure_manifest$role, derivation_manifest$role)
if (length(missing_roles) > 0L) {
  stop(
    "Unregistered H04 reader figure role(s): ",
    paste(missing_roles, collapse = ", "),
    call. = FALSE
  )
}
role_order <- derivation_manifest$role
derivation_manifest <- derivation_manifest |>
  dplyr::filter(!.data$role %in% figure_manifest$role) |>
  dplyr::bind_rows(figure_manifest) |>
  dplyr::mutate(role_order = match(.data$role, .env$role_order)) |>
  dplyr::arrange(.data$role_order) |>
  dplyr::select(-dplyr::all_of("role_order"))
if (anyDuplicated(derivation_manifest$role)) {
  stop("Duplicated H04 reader derivation role", call. = FALSE)
}
invisible(write_csv_artifact(
  derivation_manifest,
  derivation_manifest_path,
  producer
))

message("H04 H03-aligned reader figures rebuilt from durable source data")
