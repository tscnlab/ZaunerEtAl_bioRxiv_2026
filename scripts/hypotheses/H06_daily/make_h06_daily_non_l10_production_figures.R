#!/usr/bin/env Rscript

# H06-D-013 reader-facing primary-effect figures from sealed Stage 2 tables.
# Pointwise 95% confidence intervals only; no model fitting or multiplicity.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "tibble", "readr", "ggplot2")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tibble)
  library(readr)
  library(ggplot2)
})
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_contract.R"
))

h06d_prod_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06-D-013 figure generation requires R 4.6.1"
)
state_path <- file.path(
  root,
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_production_state.rds"
)
state <- readRDS(state_path)
h06d_prod_assert(
  identical(state$phase, "POSTPROCESS_COMPLETE") &&
    identical(state$authorization, "H06-D-013"),
  "Postprocessed Stage 2 results are required before figure generation"
)

effects_path <- file.path(
  root,
  "artifacts/09_tables/H06_daily/",
  "H06_daily_non_l10_production_effects.csv"
)
effects <- readr::read_csv(effects_path, show_col_types = FALSE) |>
  dplyr::filter(
    .data$dataset_id == "primary",
    .data$placement_id == "near_eye",
    .data$sample_role == "all_available"
  ) |>
  dplyr::mutate(
    predictor = factor(
      .data$reader_name,
      levels = c(
        "Work/free day",
        "Daily activity status",
        "Previous-night sleep duration"
      )
    ),
    manuscript_name = factor(
      .data$manuscript_name,
      levels = rev(unique(.data$manuscript_name[order(.data$metric_slot)]))
    )
  )
h06d_prod_assert(
  nrow(effects) == 39L && all(effects$effect_status == "ESTIMABLE"),
  "The primary near-eye figure source must contain 13 x 3 estimates"
)

ratio <- effects |>
  dplyr::filter(grepl("^ratio", .data$effect_scale)) |>
  dplyr::transmute(
    metric_slot,
    metric_id,
    metric = manuscript_name,
    predictor,
    contrast,
    estimate = display_estimate,
    lower_95 = display_lower_95,
    upper_95 = display_upper_95,
    effect_scale,
    participant_days,
    participants,
    sites,
    interval_type
  )
absolute <- effects |>
  dplyr::filter(!grepl("^ratio", .data$effect_scale)) |>
  dplyr::transmute(
    metric_slot,
    metric_id,
    metric = manuscript_name,
    predictor,
    contrast,
    estimate = display_estimate,
    lower_95 = display_lower_95,
    upper_95 = display_upper_95,
    effect_scale,
    participant_days,
    participants,
    sites,
    interval_type
  )
h06d_prod_assert(
  nrow(ratio) == 21L && nrow(absolute) == 18L &&
    all(is.finite(ratio$lower_95)) && all(ratio$lower_95 > 0),
  "The primary-effect figure split or ratio support changed"
)

figure_dir <- file.path(root, "artifacts/10_figures/H06_daily")
source_dir <- file.path(root, "artifacts/11_source_data/H06_daily")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)

ratio_source <- file.path(
  source_dir,
  "H06_daily_non_l10_production_primary_ratio_effects.csv"
)
absolute_source <- file.path(
  source_dir,
  "H06_daily_non_l10_production_primary_absolute_effects.csv"
)
h06d_prod_write_csv(ratio, ratio_source)
h06d_prod_write_csv(absolute, absolute_source)

publication_theme <- ggplot2::theme_minimal(base_size = 12, base_family = "sans") +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(face = "bold", size = 11),
    axis.text.y = ggplot2::element_text(size = 9),
    axis.title = ggplot2::element_text(size = 11),
    plot.margin = ggplot2::margin(8, 12, 8, 8),
    legend.position = "none"
  )

ratio_plot <- ggplot2::ggplot(
  ratio,
  ggplot2::aes(x = .data$estimate, y = .data$metric)
) +
  ggplot2::geom_vline(xintercept = 1, colour = "#777777", linewidth = 0.45) +
  ggplot2::geom_errorbar(
    ggplot2::aes(xmin = .data$lower_95, xmax = .data$upper_95),
    orientation = "y",
    width = 0,
    linewidth = 0.55,
    colour = "#2B4C7E"
  ) +
  ggplot2::geom_point(size = 2.3, colour = "#2B4C7E") +
  ggplot2::facet_wrap(~ predictor, nrow = 1, scales = "free_x") +
  ggplot2::scale_x_log10() +
  ggplot2::labs(
    x = "Adjusted ratio (pointwise 95% CI)",
    y = NULL
  ) +
  publication_theme

absolute_plot <- ggplot2::ggplot(
  absolute,
  ggplot2::aes(x = .data$estimate, y = .data$metric)
) +
  ggplot2::geom_vline(xintercept = 0, colour = "#777777", linewidth = 0.45) +
  ggplot2::geom_errorbar(
    ggplot2::aes(xmin = .data$lower_95, xmax = .data$upper_95),
    orientation = "y",
    width = 0,
    linewidth = 0.55,
    colour = "#8B3A3A"
  ) +
  ggplot2::geom_point(size = 2.3, colour = "#8B3A3A") +
  ggplot2::facet_wrap(~ predictor, nrow = 1, scales = "free_x") +
  ggplot2::labs(
    x = "Adjusted difference in hours (pointwise 95% CI)",
    y = NULL
  ) +
  publication_theme

ratio_path <- file.path(
  figure_dir,
  "H06_daily_non_l10_production_primary_ratio_effects.png"
)
absolute_path <- file.path(
  figure_dir,
  "H06_daily_non_l10_production_primary_absolute_effects.png"
)
ggplot2::ggsave(
  ratio_path,
  ratio_plot,
  width = 12,
  height = 5.8,
  units = "in",
  dpi = 300,
  bg = "white"
)
ggplot2::ggsave(
  absolute_path,
  absolute_plot,
  width = 12,
  height = 5.4,
  units = "in",
  dpi = 300,
  bg = "white"
)

manifest <- dplyr::bind_rows(lapply(
  c(ratio_path, absolute_path, ratio_source, absolute_source),
  function(path) h06d_prod_file_record(
    root,
    path,
    dplyr::case_when(
      grepl("ratio_effects\\.png$", path) ~ "reader-facing ratio figure",
      grepl("absolute_effects\\.png$", path) ~
        "reader-facing absolute-difference figure",
      grepl("ratio_effects\\.csv$", path) ~ "ratio figure source data",
      TRUE ~ "absolute-difference figure source data"
    )
  )
)) |>
  dplyr::mutate(
    authorization = "H06-D-013",
    gate = "H06-D-G2",
    interval_type = "pointwise 95% confidence interval"
  )
h06d_prod_write_csv(
  manifest,
  file.path(
    root,
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_non_l10_production_figure_manifest.csv"
  )
)

message(sprintf(
  "H06-D-013 figures complete: %d PNGs and %d paired source-data CSVs.",
  sum(grepl("\\.png$", manifest$relative_path)),
  sum(grepl("\\.csv$", manifest$relative_path))
))
