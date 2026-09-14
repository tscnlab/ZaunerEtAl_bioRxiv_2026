#!/usr/bin/env Rscript

# Rebuild only the H10 gap-common display affected by the repaired MDER slot.
# This script reads sealed tabular results only; it does not fit, refit,
# predict, simulate, or resample a model.

suppressPackageStartupMessages({
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
  stop("H10 METRIC-010 figure rebuild requires R 4.6.1", call. = FALSE)
}

figure_dir <- file.path(root, "artifacts/10_figures/H10")
source_dir <- file.path(root, "artifacts/11_source_data/H10")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

read_h10 <- function(directory, file) {
  readr::read_csv(
    file.path(directory, file),
    show_col_types = FALSE,
    progress = FALSE
  )
}

gap_source <- read_h10(source_dir, "H10_gap_common_sample_effects_data.csv")

save_plot <- function(plot, stem, width, height) {
  ggplot2::ggsave(
    file.path(figure_dir, paste0(stem, ".png")),
    plot,
    width = width,
    height = height,
    units = "in",
    dpi = 300,
    bg = "white"
  )
  ggplot2::ggsave(
    file.path(figure_dir, paste0(stem, ".pdf")),
    plot,
    width = width,
    height = height,
    units = "in",
    device = grDevices::cairo_pdf,
    bg = "white"
  )
}

gap_limits <- range(
  c(
    gap_source$standardized_conf_low_primary,
    gap_source$standardized_conf_high_primary,
    gap_source$standardized_conf_low_gap_timing_unaware,
    gap_source$standardized_conf_high_gap_timing_unaware
  ),
  finite = TRUE
)
gap_plot <- ggplot(
  gap_source,
  aes(
    x = .data$standardized_estimate_primary,
    y = .data$standardized_estimate_gap_timing_unaware,
    colour = .data$placement_label
  )
) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", colour = "grey45") +
  geom_vline(xintercept = 0, colour = "grey70") +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_errorbar(
    aes(
      ymin = .data$standardized_conf_low_gap_timing_unaware,
      ymax = .data$standardized_conf_high_gap_timing_unaware
    ),
    width = 0,
    linewidth = 0.35,
    alpha = 0.65
  ) +
  geom_errorbar(
    aes(
      xmin = .data$standardized_conf_low_primary,
      xmax = .data$standardized_conf_high_primary
    ),
    orientation = "y",
    width = 0,
    linewidth = 0.35,
    alpha = 0.65
  ) +
  geom_point(size = 2.5, stroke = 0.85) +
  facet_wrap(vars(.data$predictor_label), nrow = 1) +
  coord_equal(xlim = gap_limits, ylim = gap_limits) +
  scale_colour_manual(values = c("Near eye" = "#0072B2", "Chest" = "#D55E00")) +
  labs(
    title = "Primary and gap-timing-unaware H10 associations",
    subtitle = "Identical within-metric samples; standardized model-scale effects",
    x = "Primary dataset effect",
    y = "Gap-timing-unaware dataset effect",
    colour = "Placement",
    caption = paste0(
      "The gap-timing-unaware dataset applies the 50%-per-hour and 80%-per-day ",
      "coverage rules but does not use the remaining gaps' time of day\n",
      "in metric-specific support decisions. Bars are component 95% confidence ",
      "intervals; the dashed line marks identical estimates."
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.caption = element_text(hjust = 0, size = 7)
  )
save_plot(gap_plot, "H10_gap_common_sample_effects", 9.4, 5.8)

message("H10 FIND-049/CHG-101 gap-common figure rebuilt")
