#!/usr/bin/env Rscript

# Rebuild four H06_daily reader figures from frozen display CSVs only.

options(stringsAsFactors = FALSE)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c(
  "digest",
  "dplyr",
  "ggplot2",
  "png",
  "readr",
  "svglite",
  "tibble"
)
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
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
  library(ggplot2)
  library(readr)
  library(tibble)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 48a display refresh requires R 4.6.1.", call. = FALSE)
}

arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 1L) {
  stop(
    "Supply exactly one phase: baseline, candidate, or promote.",
    call. = FALSE
  )
}
phase <- match.arg(arguments[[1L]], c("baseline", "candidate", "promote"))

work_dir <- Sys.getenv("H06_DAILY_ORDER48A_WORK_DIR", unset = "")
if (
  !nzchar(work_dir) ||
    !grepl("^/private/tmp/", work_dir) ||
    !dir.exists(work_dir)
) {
  stop(
    "`H06_DAILY_ORDER48A_WORK_DIR` must be an existing directory under `/private/tmp`.",
    call. = FALSE
  )
}
work_dir <- normalizePath(work_dir, winslash = "/", mustWork = TRUE)

sha256_file <- function(path) {
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

write_evidence <- function(data, path) {
  readr::write_csv(data, path, na = "")
}

input_paths <- c(
  ratio = file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06_daily/",
      "H06_daily_non_l10_production_primary_ratio_effects.csv"
    )
  ),
  absolute = file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06_daily/",
      "H06_daily_non_l10_production_primary_absolute_effects.csv"
    )
  ),
  fdr = file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06_daily/",
      "H06_daily_stage3_fdr_overview_figure.csv"
    )
  ),
  site = file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06_daily/",
      "H06_daily_stage3_primary_site_deviation_figure.csv"
    )
  ),
  site_registry = file.path(root, "config/site_display_registry.csv")
)
expected_input_hashes <- c(
  ratio = "c7a1c0018e82db71e2fb0fe74d6e3e5a6645948017b10dd938fce18f6c5c2a9d",
  absolute = "2b695be686e6fdfdef9bdad4082be1fdcd1100e0d3d763fac35b4a75b8df11a7",
  fdr = "4a9a7c3f0877872e2efe7bfddd73afac1c50299f60474bd8d328ce945f17ddf1",
  site = "12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc",
  site_registry = "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809"
)
observed_input_hashes <- vapply(input_paths, sha256_file, character(1))
if (!identical(unname(observed_input_hashes), unname(expected_input_hashes))) {
  stop(
    "A frozen display input does not match its order-48a pin.",
    call. = FALSE
  )
}

ratio_source <- readr::read_csv(input_paths[["ratio"]], show_col_types = FALSE)
absolute_source <- readr::read_csv(
  input_paths[["absolute"]],
  show_col_types = FALSE
)
fdr_source <- readr::read_csv(input_paths[["fdr"]], show_col_types = FALSE)
site_source <- readr::read_csv(input_paths[["site"]], show_col_types = FALSE)
site_registry <- readr::read_csv(
  input_paths[["site_registry"]],
  show_col_types = FALSE
)

predictor_levels <- c(
  "Work/free day",
  "Daily activity status",
  "Previous-night sleep duration"
)
fdr_predictor_levels <- c(
  "Free vs Work",
  "Active vs Sedentary",
  "+1 h previous sleep"
)
dataset_levels <- c(
  "Primary daily metrics",
  "Gap-timing-unaware sensitivity"
)
status_levels <- c(
  "FDR-supported with limitations",
  "Not FDR-supported",
  "L10 non-estimable",
  "MDER result (not FDR-supported)"
)
expected_site_names <- c(
  "Borås (SE)",
  "Delft (NL)",
  "Dortmund (DE)",
  "Tübingen (DE)",
  "Munich (DE)",
  "Madrid (ES)",
  "Izmir (TR)",
  "San José (CR)",
  "Kumasi (GH)"
)

if (
  nrow(ratio_source) != 21L ||
    nrow(absolute_source) != 18L ||
    nrow(fdr_source) != 90L ||
    nrow(site_source) != 90L ||
    nrow(site_registry) != 9L ||
    !identical(as.integer(site_registry$display_order), seq_len(9L)) ||
    !identical(site_registry$display_name, expected_site_names) ||
    anyNA(ratio_source[c("estimate", "lower_95", "upper_95")]) ||
    anyNA(absolute_source[c("estimate", "lower_95", "upper_95")]) ||
    anyNA(site_source[c(
      "site_adjustment_factor",
      "site_adjustment_lower_95",
      "site_adjustment_upper_95"
    )])
) {
  stop("A frozen display frame failed its structural contract.", call. = FALSE)
}

site_map <- site_source |>
  distinct(
    .data$site,
    .data$display_order,
    .data$display_name,
    .data$color_hex
  ) |>
  arrange(.data$display_order)
registry_map <- site_registry |>
  select("site", "display_order", "display_name", "color_hex")
if (!identical(site_map, registry_map)) {
  stop("The frozen site source and display registry disagree.", call. = FALSE)
}

prepare_primary_source <- function(data) {
  data |>
    mutate(
      predictor = factor(.data$predictor, levels = predictor_levels),
      metric = factor(
        .data$metric,
        levels = rev(unique(.data$metric[order(.data$metric_slot)]))
      )
    )
}

prepare_fdr_source <- function(data) {
  data |>
    mutate(
      predictor_label = factor(
        .data$predictor_label,
        levels = fdr_predictor_levels
      ),
      dataset_label = factor(.data$dataset_label, levels = dataset_levels),
      metric_label = factor(
        .data$metric_label,
        levels = rev(unique(.data$metric_label[order(.data$metric_slot)]))
      ),
      display_status = factor(.data$display_status, levels = status_levels)
    )
}

prepare_site_source <- function(data) {
  interaction_levels <- data |>
    distinct(
      .data$predictor_order,
      .data$metric_slot,
      .data$interaction_label
    ) |>
    arrange(.data$predictor_order, .data$metric_slot) |>
    pull(.data$interaction_label)
  data |>
    mutate(
      interaction_label = factor(
        .data$interaction_label,
        levels = interaction_levels
      ),
      display_name = factor(
        .data$display_name,
        levels = rev(site_registry$display_name)
      )
    )
}

ratio_data <- prepare_primary_source(ratio_source)
absolute_data <- prepare_primary_source(absolute_source)
fdr_data <- prepare_fdr_source(fdr_source)
site_data <- prepare_site_source(site_source)
site_colours <- stats::setNames(
  site_registry$color_hex,
  site_registry$display_name
)

primary_theme <- ggplot2::theme_minimal(
  base_size = 12,
  base_family = "sans"
) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(face = "bold", size = 11),
    axis.text.y = ggplot2::element_text(size = 9),
    axis.title = ggplot2::element_text(size = 11),
    plot.margin = ggplot2::margin(8, 12, 8, 8),
    legend.position = "none"
  )

make_ratio_plot <- function(candidate = FALSE) {
  plot <- ggplot2::ggplot(
    ratio_data,
    ggplot2::aes(x = .data$estimate, y = .data$metric)
  ) +
    ggplot2::geom_vline(
      xintercept = 1,
      colour = "#777777",
      linewidth = 0.45
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = .data$lower_95, xmax = .data$upper_95),
      orientation = "y",
      width = 0,
      linewidth = 0.55,
      colour = "#2B4C7E"
    ) +
    ggplot2::geom_point(size = 2.3, colour = "#2B4C7E") +
    ggplot2::facet_wrap(~predictor, nrow = 1, scales = "free_x") +
    ggplot2::scale_x_log10() +
    ggplot2::labs(
      x = "Adjusted ratio (pointwise 95% CI)",
      y = NULL
    ) +
    primary_theme

  if (candidate) {
    plot <- plot +
      ggplot2::theme(
        text = ggplot2::element_text(size = 12.8),
        strip.text = ggplot2::element_text(face = "bold", size = 13),
        axis.text = ggplot2::element_text(size = 12.8),
        axis.title = ggplot2::element_text(size = 12.8),
        plot.margin = ggplot2::margin(10, 14, 10, 10)
      )
  }
  plot
}

make_absolute_plot <- function(candidate = FALSE) {
  plot <- ggplot2::ggplot(
    absolute_data,
    ggplot2::aes(x = .data$estimate, y = .data$metric)
  ) +
    ggplot2::geom_vline(
      xintercept = 0,
      colour = "#777777",
      linewidth = 0.45
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = .data$lower_95, xmax = .data$upper_95),
      orientation = "y",
      width = 0,
      linewidth = 0.55,
      colour = "#8B3A3A"
    ) +
    ggplot2::geom_point(size = 2.3, colour = "#8B3A3A") +
    ggplot2::facet_wrap(~predictor, nrow = 1, scales = "free_x") +
    ggplot2::labs(
      x = "Adjusted difference in hours (pointwise 95% CI)",
      y = NULL
    ) +
    primary_theme

  if (candidate) {
    plot <- plot +
      ggplot2::theme(
        text = ggplot2::element_text(size = 12.8),
        strip.text = ggplot2::element_text(face = "bold", size = 13),
        axis.text = ggplot2::element_text(size = 12.8),
        axis.title = ggplot2::element_text(size = 12.8),
        plot.margin = ggplot2::margin(10, 14, 10, 10)
      )
  }
  plot
}

make_fdr_plot <- function(candidate = FALSE) {
  plot <- ggplot2::ggplot(
    fdr_data,
    ggplot2::aes(
      x = .data$predictor_label,
      y = .data$metric_label,
      shape = .data$display_status,
      colour = .data$display_status
    )
  ) +
    ggplot2::geom_point(size = 4.2, stroke = 1.15) +
    ggplot2::facet_grid(
      rows = ggplot2::vars(.data$dataset_label),
      scales = "free_y"
    ) +
    ggplot2::scale_shape_manual(
      values = c(
        "FDR-supported with limitations" = 16,
        "Not FDR-supported" = 1,
        "L10 non-estimable" = 4,
        "MDER result (not FDR-supported)" = 18
      ),
      drop = FALSE
    ) +
    ggplot2::scale_colour_manual(
      values = c(
        "FDR-supported with limitations" = "#0072B2",
        "Not FDR-supported" = "#7A7A7A",
        "L10 non-estimable" = "#D55E00",
        "MDER result (not FDR-supported)" = "#CC79A7"
      ),
      drop = FALSE
    ) +
    ggplot2::labs(
      x = NULL,
      y = NULL,
      shape = NULL,
      colour = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12.5) +
    ggplot2::theme(
      panel.grid.major.x = ggplot2::element_line(
        colour = "#E8E8E8",
        linewidth = 0.4
      ),
      panel.grid.major.y = ggplot2::element_line(
        colour = "#F0F0F0",
        linewidth = 0.35
      ),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(
        size = 11,
        face = "bold",
        margin = ggplot2::margin(t = 6)
      ),
      axis.text.y = ggplot2::element_text(size = 10.5, colour = "#202020"),
      strip.text = ggplot2::element_text(
        size = 12.5,
        face = "bold",
        colour = "#202020"
      ),
      strip.background = ggplot2::element_rect(
        fill = "#F4F4F4",
        colour = NA
      ),
      legend.position = "bottom",
      legend.text = ggplot2::element_text(size = 10.5),
      legend.box = "vertical",
      plot.margin = ggplot2::margin(10, 14, 8, 8)
    ) +
    ggplot2::guides(
      shape = ggplot2::guide_legend(nrow = 2L, byrow = TRUE),
      colour = ggplot2::guide_legend(nrow = 2L, byrow = TRUE)
    )

  if (candidate) {
    plot <- plot +
      ggplot2::theme(
        text = ggplot2::element_text(size = 12.8),
        axis.text.x = ggplot2::element_text(
          size = 12.8,
          face = "bold",
          margin = ggplot2::margin(t = 7)
        ),
        axis.text.y = ggplot2::element_text(size = 12.8, colour = "#202020"),
        strip.text = ggplot2::element_text(
          size = 13.2,
          face = "bold",
          colour = "#202020"
        ),
        legend.text = ggplot2::element_text(size = 12.8),
        plot.margin = ggplot2::margin(12, 16, 10, 10)
      )
  }
  plot
}

make_site_plot <- function(candidate = FALSE, wording = "site_average") {
  wording <- match.arg(wording, c("site_average", "equal_site"))
  if (wording == "site_average") {
    title <- "Site deviations from the site-average context association"
    subtitle <- paste(
      "Adjustment factor = full site-specific comparison/reference ratio ÷",
      "site-average comparison/reference ratio"
    )
    caption <- paste0(
      "Points and bars are adjustment factors with pointwise 95% confidence intervals.\n",
      "Values below 1 indicate a weaker site-specific comparison/reference ratio ",
      "than the site-average contrast; values above 1 indicate a stronger ratio.\n",
      "Intervals are descriptive localizations after a globally FDR-supported ",
      "interaction and are not multiplicity adjusted across the nine sites."
    )
  } else {
    title <- "Site deviations from the equal-site context association"
    subtitle <- paste(
      "Adjustment factor = full site-specific comparison/reference ratio ÷",
      "equal-site comparison/reference ratio"
    )
    caption <- paste0(
      "Points and bars are adjustment factors with pointwise 95% confidence intervals.\n",
      "Values below 1 indicate a weaker site-specific comparison/reference ratio ",
      "than the equal-site contrast; values above 1 indicate a stronger ratio.\n",
      "Intervals are descriptive localizations after a globally FDR-supported ",
      "interaction and are not multiplicity adjusted across the nine sites."
    )
  }

  if (candidate && wording == "site_average") {
    caption <- paste0(
      "Points and bars are adjustment factors with pointwise 95% confidence intervals.\n",
      "Values below 1 indicate a weaker site-specific comparison/reference ratio\n",
      "than the site-average contrast; values above 1 indicate a stronger ratio.\n",
      "Intervals are descriptive localizations after a globally FDR-supported\n",
      "interaction and are not multiplicity adjusted across the nine sites."
    )
  }

  plot <- ggplot2::ggplot(
    site_data,
    ggplot2::aes(
      x = .data$site_adjustment_factor,
      y = .data$display_name,
      xmin = .data$site_adjustment_lower_95,
      xmax = .data$site_adjustment_upper_95,
      colour = .data$display_name,
      fill = .data$display_name
    )
  ) +
    ggplot2::geom_vline(
      xintercept = 1,
      colour = "grey45",
      linewidth = 0.55
    ) +
    ggplot2::geom_errorbar(
      orientation = "y",
      width = 0,
      linewidth = 0.55
    ) +
    ggplot2::geom_point(shape = 21, size = 2.8, stroke = 0.55) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$interaction_label),
      ncol = 2,
      labeller = ggplot2::label_wrap_gen(width = if (candidate) 38 else 42)
    ) +
    ggplot2::scale_x_log10(
      breaks = c(0.125, 0.25, 0.5, 1, 2, 4, 8, 16),
      labels = function(value) {
        format(value, trim = TRUE, scientific = FALSE)
      }
    ) +
    ggplot2::scale_colour_manual(values = site_colours, guide = "none") +
    ggplot2::scale_fill_manual(values = site_colours, guide = "none") +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Site adjustment factor (log scale)",
      y = NULL,
      caption = caption
    ) +
    ggplot2::theme_minimal(base_size = 10.5) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(colour = "black", size = 8.2),
      axis.title.x = ggplot2::element_text(size = 9.5),
      strip.text = ggplot2::element_text(face = "bold", size = 9),
      strip.background = ggplot2::element_rect(
        fill = "#E8EEF3",
        colour = NA
      ),
      panel.spacing = grid::unit(10, "pt"),
      plot.title = ggplot2::element_text(face = "bold", size = 13),
      plot.subtitle = ggplot2::element_text(size = 10),
      plot.caption = ggplot2::element_text(hjust = 0, size = 8.2),
      plot.margin = ggplot2::margin(8, 10, 8, 8)
    )

  if (candidate) {
    plot <- plot +
      ggplot2::theme(
        text = ggplot2::element_text(size = 11.2),
        axis.text = ggplot2::element_text(colour = "black", size = 11.2),
        axis.title.x = ggplot2::element_text(size = 11.2),
        strip.text = ggplot2::element_text(face = "bold", size = 11.2),
        panel.spacing = grid::unit(12, "pt"),
        plot.title = ggplot2::element_text(face = "bold", size = 14),
        plot.subtitle = ggplot2::element_text(size = 11.2),
        plot.caption = ggplot2::element_text(hjust = 0, size = 10.8),
        plot.margin = ggplot2::margin(10, 12, 10, 10)
      )
  }
  plot
}

historical_plots <- list(
  ratio = make_ratio_plot(FALSE),
  absolute = make_absolute_plot(FALSE),
  fdr = make_fdr_plot(FALSE),
  site_png = make_site_plot(FALSE, "site_average"),
  site_svg = make_site_plot(FALSE, "equal_site")
)
candidate_plots <- list(
  ratio = make_ratio_plot(TRUE),
  absolute = make_absolute_plot(TRUE),
  fdr = make_fdr_plot(TRUE),
  site = make_site_plot(TRUE, "site_average")
)

figure_names <- c(
  ratio_png = "H06_daily_non_l10_production_primary_ratio_effects.png",
  absolute_png = "H06_daily_non_l10_production_primary_absolute_effects.png",
  fdr_png = "H06_daily_stage3_fdr_overview.png",
  fdr_svg = "H06_daily_stage3_fdr_overview.svg",
  site_png = "H06_daily_stage3_primary_site_deviations.png",
  site_svg = "H06_daily_stage3_primary_site_deviations.svg"
)
durable_paths <- file.path(
  root,
  "artifacts/10_figures/H06_daily",
  unname(figure_names)
)
names(durable_paths) <- names(figure_names)
expected_preimage_hashes <- c(
  ratio_png = "a50f6b25c1c09abca1700870594d26a15e2085ec1c2a4c8eb5f6bc0f727cfa66",
  absolute_png = "da67b5f8a27b49d7c4d0e6426563d79aaa540ef835e350d02fd952a3a134c686",
  fdr_png = "48283afc83e9ebcd0f7d02177dacc162287940126c335b47efab11cc54c9edd9",
  fdr_svg = "ef8a3ba3d502804c5b7a01f9d21fada9d598006b8d6fcd83f0c721bd96dbda84",
  site_png = "a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1",
  site_svg = "b23f9a6838c2ecc476bdb5e68c203e0c7a85d05479a65841f75ee02d21e20b1c"
)

save_plot_set <- function(directory, candidate = FALSE) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  paths <- file.path(directory, unname(figure_names))
  names(paths) <- names(figure_names)

  if (candidate) {
    ratio_plot <- candidate_plots$ratio
    absolute_plot <- candidate_plots$absolute
    fdr_plot <- candidate_plots$fdr
    site_png_plot <- candidate_plots$site
    site_svg_plot <- candidate_plots$site
    heights <- c(ratio = 6.3, absolute = 5.9, fdr = 11.5, site_mm = 414)
  } else {
    ratio_plot <- historical_plots$ratio
    absolute_plot <- historical_plots$absolute
    fdr_plot <- historical_plots$fdr
    site_png_plot <- historical_plots$site_png
    site_svg_plot <- historical_plots$site_svg
    heights <- c(ratio = 5.8, absolute = 5.4, fdr = 10.2, site_mm = 360)
  }

  ggplot2::ggsave(
    paths[["ratio_png"]],
    ratio_plot,
    width = 12,
    height = heights[["ratio"]],
    units = "in",
    dpi = 300,
    bg = "white"
  )
  ggplot2::ggsave(
    paths[["absolute_png"]],
    absolute_plot,
    width = 12,
    height = heights[["absolute"]],
    units = "in",
    dpi = 300,
    bg = "white"
  )
  ggplot2::ggsave(
    paths[["fdr_png"]],
    fdr_plot,
    width = 11.8,
    height = heights[["fdr"]],
    units = "in",
    dpi = 320,
    bg = "white"
  )
  ggplot2::ggsave(
    paths[["fdr_svg"]],
    fdr_plot,
    width = 11.8,
    height = heights[["fdr"]],
    units = "in",
    device = svglite::svglite,
    bg = "white"
  )
  ggplot2::ggsave(
    paths[["site_png"]],
    site_png_plot,
    width = 260,
    height = heights[["site_mm"]],
    units = "mm",
    dpi = 300,
    bg = "white"
  )
  ggplot2::ggsave(
    paths[["site_svg"]],
    site_svg_plot,
    width = 260,
    height = heights[["site_mm"]],
    units = "mm",
    device = svglite::svglite,
    bg = "white"
  )
  paths
}

decoded_png_identical <- function(first, second) {
  first_pixels <- png::readPNG(first, native = TRUE)
  second_pixels <- png::readPNG(second, native = TRUE)
  identical(first_pixels, second_pixels)
}

normalized_svg <- function(path) {
  text <- paste(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  text <- gsub("[[:space:]]+", " ", text)
  trimws(text)
}

layer_data_identical <- function(historical, candidate) {
  historical_data <- ggplot2::ggplot_build(historical)$data
  candidate_data <- ggplot2::ggplot_build(candidate)$data
  identical(historical_data, candidate_data)
}

baseline_dir <- file.path(work_dir, "baseline")
candidate_dir <- file.path(work_dir, "candidate")

if (phase == "baseline") {
  observed_preimages <- vapply(durable_paths, sha256_file, character(1))
  if (
    !identical(unname(observed_preimages), unname(expected_preimage_hashes))
  ) {
    stop(
      "A durable figure does not match its authorized preimage.",
      call. = FALSE
    )
  }

  baseline_paths <- save_plot_set(baseline_dir, candidate = FALSE)
  rows <- lapply(names(baseline_paths), function(id) {
    extension <- tools::file_ext(baseline_paths[[id]])
    exact_bytes <- identical(
      sha256_file(baseline_paths[[id]]),
      sha256_file(durable_paths[[id]])
    )
    decoded_or_normalized <- if (exact_bytes) {
      TRUE
    } else if (extension == "png") {
      decoded_png_identical(baseline_paths[[id]], durable_paths[[id]])
    } else {
      identical(
        normalized_svg(baseline_paths[[id]]),
        normalized_svg(durable_paths[[id]])
      )
    }
    tibble(
      figure_id = id,
      baseline_path = baseline_paths[[id]],
      durable_path = durable_paths[[id]],
      baseline_sha256 = sha256_file(baseline_paths[[id]]),
      durable_sha256 = sha256_file(durable_paths[[id]]),
      exact_bytes = exact_bytes,
      decoded_png_or_normalized_svg_identical = decoded_or_normalized,
      status = ifelse(decoded_or_normalized, "PASS", "FAIL")
    )
  })
  baseline_audit <- bind_rows(rows)
  write_evidence(
    baseline_audit,
    file.path(work_dir, "historical_baseline_reproduction.csv")
  )
  if (!all(baseline_audit$status == "PASS")) {
    stop("Historical-theme baseline reproduction failed.", call. = FALSE)
  }
  cat(sprintf(
    "ORDER48A_BASELINE=PASS figures=%d exact_bytes=%d equivalent=%d\n",
    nrow(baseline_audit),
    sum(baseline_audit$exact_bytes),
    sum(!baseline_audit$exact_bytes)
  ))
}

if (phase == "candidate") {
  baseline_audit_path <- file.path(
    work_dir,
    "historical_baseline_reproduction.csv"
  )
  if (!file.exists(baseline_audit_path)) {
    stop("The baseline phase has not been completed.", call. = FALSE)
  }
  baseline_audit <- readr::read_csv(
    baseline_audit_path,
    show_col_types = FALSE
  )
  if (!all(baseline_audit$status == "PASS")) {
    stop("The baseline phase is not acceptable.", call. = FALSE)
  }

  candidate_paths <- save_plot_set(candidate_dir, candidate = TRUE)
  layer_audit <- tribble(
    ~figure_id,
    ~historical_layer_data_identical,
    "ratio_png",
    layer_data_identical(historical_plots$ratio, candidate_plots$ratio),
    "absolute_png",
    layer_data_identical(historical_plots$absolute, candidate_plots$absolute),
    "fdr_png_svg",
    layer_data_identical(historical_plots$fdr, candidate_plots$fdr),
    "site_png_svg",
    layer_data_identical(historical_plots$site_png, candidate_plots$site)
  ) |>
    mutate(
      status = ifelse(.data$historical_layer_data_identical, "PASS", "FAIL")
    )
  if (!all(layer_audit$status == "PASS")) {
    stop("A candidate changed a plotted data layer.", call. = FALSE)
  }
  write_evidence(layer_audit, file.path(work_dir, "candidate_layer_audit.csv"))

  typography <- tribble(
    ~figure_id,
    ~width_in,
    ~historical_height,
    ~candidate_height,
    ~height_unit,
    ~nominal_minimum_pt,
    "ratio_png",
    12,
    5.8,
    6.3,
    "in",
    12.8,
    "absolute_png",
    12,
    5.4,
    5.9,
    "in",
    12.8,
    "fdr_png_svg",
    11.8,
    10.2,
    11.5,
    "in",
    12.8,
    "site_png_svg",
    260 / 25.4,
    360,
    414,
    "mm",
    10.8
  ) |>
    mutate(
      height_increase_fraction = .data$candidate_height /
        .data$historical_height -
        1,
      effective_pt_at_170mm = .data$nominal_minimum_pt *
        (170 / 25.4) /
        .data$width_in,
      effective_pt_at_642px = .data$nominal_minimum_pt *
        642 /
        (.data$width_in * 96),
      nominal_range_ok = case_when(
        .data$figure_id %in% c("ratio_png", "absolute_png") ~
          .data$nominal_minimum_pt >= 12.6 &
            .data$nominal_minimum_pt <= 14,
        .data$figure_id == "fdr_png_svg" ~
          .data$nominal_minimum_pt >= 12.5 &
            .data$nominal_minimum_pt <= 14,
        TRUE ~
          .data$nominal_minimum_pt >= 10.8 &
            .data$nominal_minimum_pt <= 12
      ),
      height_increase_ok = .data$height_increase_fraction <= 0.15 + 1e-12,
      final_size_ok = .data$effective_pt_at_170mm >= 7 &
        .data$effective_pt_at_642px >= 7,
      status = ifelse(
        .data$nominal_range_ok &
          .data$height_increase_ok &
          .data$final_size_ok,
        "PASS",
        "FAIL"
      )
    )
  if (!all(typography$status == "PASS")) {
    stop("A candidate failed its bounded typography contract.", call. = FALSE)
  }
  write_evidence(
    typography,
    file.path(work_dir, "candidate_typography_contract.csv")
  )

  candidate_inventory <- tibble(
    figure_id = names(candidate_paths),
    candidate_path = unname(candidate_paths),
    sha256 = vapply(candidate_paths, sha256_file, character(1)),
    bytes = as.numeric(file.info(candidate_paths)$size)
  )
  write_evidence(
    candidate_inventory,
    file.path(work_dir, "candidate_inventory.csv")
  )

  qa_html <- c(
    "<!doctype html>",
    "<html lang='en'><head><meta charset='utf-8'>",
    "<meta name='viewport' content='width=device-width, initial-scale=1'>",
    "<title>H06_daily order 48a candidate QA</title>",
    "<style>body{font-family:sans-serif;margin:18px;background:white;color:#111}",
    ".figure{margin:0 0 32px 0}.final{width:170mm;max-width:none;border:1px solid #ddd}",
    "h1{font-size:22px}h2{font-size:18px;margin-top:24px}</style></head><body>",
    "<h1>H06_daily order 48a candidate figures at 170 mm</h1>",
    paste0(
      "<div class='figure'><h2>",
      names(candidate_paths)[c(1L, 2L, 3L, 5L)],
      "</h2><img class='final' src='candidate/",
      basename(candidate_paths[c(1L, 2L, 3L, 5L)]),
      "' alt='Candidate display QA'></div>"
    ),
    "</body></html>"
  )
  writeLines(qa_html, file.path(work_dir, "candidate_qa.html"), useBytes = TRUE)

  input_inventory <- tibble(
    input_id = names(input_paths),
    path = unname(input_paths),
    expected_sha256 = unname(expected_input_hashes),
    observed_sha256 = vapply(input_paths, sha256_file, character(1)),
    bytes = as.numeric(file.info(input_paths)$size),
    status = ifelse(
      .data$expected_sha256 == .data$observed_sha256,
      "PASS",
      "FAIL"
    )
  )
  write_evidence(
    input_inventory,
    file.path(work_dir, "source_input_inventory.csv")
  )
  cat(sprintf(
    "ORDER48A_CANDIDATE=PASS outputs=%d layers=4 typography=4 qa=%s\n",
    nrow(candidate_inventory),
    file.path(work_dir, "candidate_qa.html")
  ))
}

if (phase == "promote") {
  required_evidence <- c(
    "historical_baseline_reproduction.csv",
    "candidate_layer_audit.csv",
    "candidate_typography_contract.csv",
    "candidate_inventory.csv",
    "candidate_visual_qa.csv",
    "source_input_inventory.csv"
  )
  required_paths <- file.path(work_dir, required_evidence)
  if (!all(file.exists(required_paths))) {
    stop("The complete candidate evidence set is not present.", call. = FALSE)
  }
  visual_qa <- readr::read_csv(
    file.path(work_dir, "candidate_visual_qa.csv"),
    show_col_types = FALSE
  )
  if (nrow(visual_qa) != 4L || !all(visual_qa$status == "PASS")) {
    stop(
      "The complete four-figure candidate visual QA has not passed.",
      call. = FALSE
    )
  }

  candidate_paths <- file.path(candidate_dir, unname(figure_names))
  names(candidate_paths) <- names(figure_names)
  if (!all(file.exists(candidate_paths))) {
    stop("A candidate output is missing.", call. = FALSE)
  }
  candidate_inventory <- readr::read_csv(
    file.path(work_dir, "candidate_inventory.csv"),
    show_col_types = FALSE
  )
  candidate_hashes <- vapply(candidate_paths, sha256_file, character(1))
  if (!identical(unname(candidate_hashes), candidate_inventory$sha256)) {
    stop("A candidate changed after validation.", call. = FALSE)
  }

  observed_preimages <- vapply(durable_paths, sha256_file, character(1))
  if (
    !identical(unname(observed_preimages), unname(expected_preimage_hashes))
  ) {
    stop("A durable preimage changed before promotion.", call. = FALSE)
  }

  evidence_dir <- file.path(
    root,
    "audit/hypotheses/H06_daily/report018_order48a_display_repair"
  )
  preimage_dir <- file.path(evidence_dir, "recoverable_preimages")
  promotion_record <- file.path(evidence_dir, "promotion_record.csv")
  if (dir.exists(preimage_dir) || file.exists(promotion_record)) {
    stop(
      "The one-time durable promotion has already been attempted.",
      call. = FALSE
    )
  }
  dir.create(preimage_dir, recursive = TRUE, showWarnings = FALSE)

  preimage_copies <- file.path(preimage_dir, basename(durable_paths))
  copied_preimages <- file.copy(
    durable_paths,
    preimage_copies,
    overwrite = FALSE,
    copy.mode = TRUE,
    copy.date = TRUE
  )
  if (!all(copied_preimages)) {
    stop("Could not preserve every recoverable preimage.", call. = FALSE)
  }
  if (
    !identical(
      unname(vapply(preimage_copies, sha256_file, character(1))),
      unname(expected_preimage_hashes)
    )
  ) {
    stop("A recoverable preimage copy is not exact.", call. = FALSE)
  }

  promoted <- file.copy(
    candidate_paths,
    durable_paths,
    overwrite = TRUE,
    copy.mode = TRUE,
    copy.date = FALSE
  )
  if (!all(promoted)) {
    stop("The six-file durable promotion did not complete.", call. = FALSE)
  }
  postimage_hashes <- vapply(durable_paths, sha256_file, character(1))
  if (!identical(unname(postimage_hashes), unname(candidate_hashes))) {
    stop(
      "A durable output differs from its validated candidate.",
      call. = FALSE
    )
  }

  copied_evidence <- file.copy(
    required_paths,
    file.path(evidence_dir, required_evidence),
    overwrite = FALSE,
    copy.mode = TRUE,
    copy.date = TRUE
  )
  if (!all(copied_evidence)) {
    stop("Could not preserve the complete candidate evidence.", call. = FALSE)
  }

  transition <- tibble(
    figure_id = names(durable_paths),
    durable_path = sub(paste0("^", root, "/"), "", unname(durable_paths)),
    preimage_sha256 = unname(expected_preimage_hashes),
    preimage_bytes = as.numeric(file.info(preimage_copies)$size),
    recoverable_preimage = sub(
      paste0("^", root, "/"),
      "",
      preimage_copies
    ),
    postimage_sha256 = unname(postimage_hashes),
    postimage_bytes = as.numeric(file.info(durable_paths)$size),
    candidate_sha256 = unname(candidate_hashes),
    candidate_identical = .data$postimage_sha256 == .data$candidate_sha256,
    promotion_count = 1L,
    status = ifelse(.data$candidate_identical, "PASS", "FAIL")
  )
  write_evidence(
    transition,
    file.path(evidence_dir, "preimage_postimage_ledger.csv")
  )

  promotion <- tibble(
    authorization = "REPORT-018 order 48a",
    files_promoted = nrow(transition),
    promotion_count = 1L,
    all_preimages_recoverable = TRUE,
    all_outputs_candidate_identical = all(transition$candidate_identical),
    status = "PASS"
  )
  write_evidence(promotion, promotion_record)

  source_inventory <- readr::read_csv(
    file.path(work_dir, "source_input_inventory.csv"),
    show_col_types = FALSE
  )
  write_evidence(
    source_inventory,
    file.path(evidence_dir, "source_input_inventory.csv")
  )

  figure5_path <- file.path(
    root,
    paste0(
      "artifacts/10_figures/H06_daily/",
      "H06_daily_temporal_h02_primary_context_functions.png"
    )
  )
  figure5_hash <- sha256_file(figure5_path)
  if (
    !identical(
      figure5_hash,
      "e28c639f23b3f33687ca046a77069153bb66073d29cd03d96fd03408c4317d98"
    )
  ) {
    stop("Protected Figure 5 changed during promotion.", call. = FALSE)
  }

  manifest_path <- file.path(
    root,
    "artifacts/12_manifests/H06_daily/H06_daily_order48a_display_manifest.csv"
  )
  if (file.exists(manifest_path)) {
    stop("The order-48a display manifest already exists.", call. = FALSE)
  }
  manifest_members <- c(
    input_paths,
    durable_paths,
    figure5 = figure5_path,
    qmd = file.path(root, "notebooks/hypotheses/H06_daily.qmd"),
    refresh = file.path(
      root,
      "scripts/hypotheses/H06_daily/refresh_h06_daily_order48_figures.R"
    ),
    verifier = file.path(
      root,
      "tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R"
    ),
    preimage_copies,
    file.path(
      evidence_dir,
      c(
        required_evidence,
        "preimage_postimage_ledger.csv",
        "promotion_record.csv",
        "source_input_inventory.csv"
      )
    )
  )
  manifest_members <- sort(unique(manifest_members))
  manifest_roles <- case_when(
    manifest_members %in% unname(input_paths) ~ "frozen display input",
    manifest_members %in% unname(durable_paths) ~ "current durable display",
    manifest_members == figure5_path ~ "protected unchanged Figure 5",
    grepl("recoverable_preimages", manifest_members) ~ "recoverable preimage",
    grepl("[.]R$", manifest_members) ~ "order-48a implementation or verifier",
    grepl("H06_daily[.]qmd$", manifest_members) ~ "authorized QMD postimage",
    TRUE ~ "order-48a display evidence"
  )
  display_manifest <- tibble(
    path = sub(paste0("^", root, "/"), "", manifest_members),
    role = manifest_roles,
    sha256 = vapply(manifest_members, sha256_file, character(1)),
    bytes = as.numeric(file.info(manifest_members)$size)
  )
  if (
    anyDuplicated(display_manifest$path) ||
      any(
        display_manifest$path == sub(paste0("^", root, "/"), "", manifest_path)
      )
  ) {
    stop(
      "The current display manifest is not unique and non-circular.",
      call. = FALSE
    )
  }
  write_evidence(display_manifest, manifest_path)

  cat(sprintf(
    paste0(
      "ORDER48A_PROMOTION=PASS promoted=%d preimages=%d manifest=%d ",
      "figure5_unchanged=1\n"
    ),
    nrow(transition),
    length(preimage_copies),
    nrow(display_manifest)
  ))
}
