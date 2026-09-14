#!/usr/bin/env Rscript

# Refresh three reader-facing labels in the frozen H06_daily site-deviation figure.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(ggplot2)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The display refresh requires R 4.6.1.", call. = FALSE)
}

figure_source_path <- file.path(
  root,
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_site_deviation_figure.csv"
)
site_registry_path <- file.path(root, "config/site_display_registry.csv")
output_path <- file.path(
  root,
  "artifacts/10_figures/H06_daily/H06_daily_stage3_primary_site_deviations.png"
)

expected_hashes <- c(
  figure_source = "12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc",
  site_registry = "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809"
)
observed_hashes <- c(
  figure_source = digest::digest(
    figure_source_path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  ),
  site_registry = digest::digest(
    site_registry_path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  )
)

if (!identical(observed_hashes, expected_hashes)) {
  stop(
    "A frozen display input does not match its accepted SHA-256.",
    call. = FALSE
  )
}

figure_source <- readr::read_csv(
  figure_source_path,
  show_col_types = FALSE,
  na = c("", "NA")
)
site_registry <- readr::read_csv(
  site_registry_path,
  show_col_types = FALSE,
  na = c("", "NA")
)

plot_columns <- c(
  "metric_slot",
  "predictor_order",
  "interaction_label",
  "site",
  "display_order",
  "display_name",
  "color_hex",
  "site_adjustment_factor",
  "site_adjustment_lower_95",
  "site_adjustment_upper_95"
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
  nrow(figure_source) != 90L ||
    ncol(figure_source) != 29L ||
    !all(plot_columns %in% names(figure_source)) ||
    anyNA(figure_source[plot_columns]) ||
    dplyr::n_distinct(figure_source$interaction_label) != 10L ||
    dplyr::n_distinct(figure_source$display_name) != 9L ||
    nrow(site_registry) != 9L ||
    !identical(as.integer(site_registry$display_order), seq_len(9L)) ||
    !identical(site_registry$display_name, expected_site_names)
) {
  stop(
    "The frozen display frame or site registry failed its structural contract.",
    call. = FALSE
  )
}

panel_support <- figure_source |>
  dplyr::count(.data$interaction_label, name = "sites")
if (nrow(panel_support) != 10L || any(panel_support$sites != 9L)) {
  stop("Every interaction panel must contain all nine sites.", call. = FALSE)
}

source_site_map <- figure_source |>
  dplyr::distinct(
    .data$site,
    .data$display_order,
    .data$display_name,
    .data$color_hex
  ) |>
  dplyr::arrange(.data$display_order)
registry_site_map <- site_registry |>
  dplyr::select(dplyr::all_of(c(
    "site",
    "display_order",
    "display_name",
    "color_hex"
  )))
if (!identical(source_site_map, registry_site_map)) {
  stop(
    "The frozen figure source and site registry do not map identically.",
    call. = FALSE
  )
}

interaction_levels <- figure_source |>
  dplyr::distinct(
    .data$predictor_order,
    .data$metric_slot,
    .data$interaction_label
  ) |>
  dplyr::arrange(.data$predictor_order, .data$metric_slot) |>
  dplyr::pull(.data$interaction_label)
site_colors <- stats::setNames(
  site_registry$color_hex,
  site_registry$display_name
)
figure_data <- figure_source |>
  dplyr::mutate(
    interaction_label = factor(
      .data$interaction_label,
      levels = interaction_levels
    ),
    display_name = factor(
      .data$display_name,
      levels = rev(site_registry$display_name)
    )
  )

site_deviation_plot <- ggplot2::ggplot(
  figure_data,
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
    labeller = ggplot2::label_wrap_gen(width = 42)
  ) +
  ggplot2::scale_x_log10(
    breaks = c(0.125, 0.25, 0.5, 1, 2, 4, 8, 16),
    labels = function(value) {
      format(value, trim = TRUE, scientific = FALSE)
    }
  ) +
  ggplot2::scale_colour_manual(values = site_colors, guide = "none") +
  ggplot2::scale_fill_manual(values = site_colors, guide = "none") +
  ggplot2::labs(
    title = "Site deviations from the site-average context association",
    subtitle = paste(
      "Adjustment factor = full site-specific comparison/reference ratio ÷",
      "site-average comparison/reference ratio"
    ),
    x = "Site adjustment factor (log scale)",
    y = NULL,
    caption = paste0(
      "Points and bars are adjustment factors with pointwise 95% confidence intervals.\n",
      "Values below 1 indicate a weaker site-specific comparison/reference ratio ",
      "than the site-average contrast; values above 1 indicate a stronger ratio.\n",
      "Intervals are descriptive localizations after a globally FDR-supported ",
      "interaction and are not multiplicity adjusted across the nine sites."
    )
  ) +
  ggplot2::theme_minimal(base_size = 10.5) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_blank(),
    axis.text = ggplot2::element_text(colour = "black", size = 8.2),
    axis.title.x = ggplot2::element_text(size = 9.5),
    strip.text = ggplot2::element_text(face = "bold", size = 9),
    strip.background = ggplot2::element_rect(fill = "#E8EEF3", colour = NA),
    panel.spacing = grid::unit(10, "pt"),
    plot.title = ggplot2::element_text(face = "bold", size = 13),
    plot.subtitle = ggplot2::element_text(size = 10),
    plot.caption = ggplot2::element_text(hjust = 0, size = 8.2),
    plot.margin = ggplot2::margin(8, 10, 8, 8)
  )

run_started <- proc.time()[["elapsed"]]
ggplot2::ggsave(
  filename = output_path,
  plot = site_deviation_plot,
  width = 260,
  height = 360,
  units = "mm",
  dpi = 300,
  bg = "white"
)
elapsed_seconds <- proc.time()[["elapsed"]] - run_started

cat("status=PASS\n")
cat("r_version=", as.character(getRversion()), "\n", sep = "")
cat(
  "digest_version=",
  as.character(utils::packageVersion("digest")),
  "\n",
  sep = ""
)
cat(
  "dplyr_version=",
  as.character(utils::packageVersion("dplyr")),
  "\n",
  sep = ""
)
cat(
  "ggplot2_version=",
  as.character(utils::packageVersion("ggplot2")),
  "\n",
  sep = ""
)
cat(
  "readr_version=",
  as.character(utils::packageVersion("readr")),
  "\n",
  sep = ""
)
cat("figure_rows=", nrow(figure_source), "\n", sep = "")
cat(
  "interaction_panels=",
  dplyr::n_distinct(figure_source$interaction_label),
  "\n",
  sep = ""
)
cat(
  "country_coded_sites=",
  dplyr::n_distinct(figure_source$display_name),
  "\n",
  sep = ""
)
cat("elapsed_seconds=", sprintf("%.3f", elapsed_seconds), "\n", sep = "")
