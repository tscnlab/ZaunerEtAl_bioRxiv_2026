#!/usr/bin/env Rscript

# Re-export the five accepted H08 reader figures at the REPORT-011 reference
# width of 170 mm. Every layer reads existing H08 source-data CSVs; this script
# does not rebuild data, fit a model, recalculate an estimate, or resample.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    paste0(
      "The H08 reader-figure repair requires R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H08/rebuild_h08_reader_figures.R"
figure_dir <- file.path(root, "artifacts/10_figures/H08")
source_dir <- file.path(root, "artifacts/11_source_data/H08")
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H08/H08_figure_manifest.csv"
)
metric_registry <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H08/H08_metric_registry.csv"),
  show_col_types = FALSE
)

read_source <- function(filename) {
  readr::read_csv(
    file.path(source_dir, filename),
    show_col_types = FALSE
  )
}

wrap_caption <- function(text, width = 72L) {
  paste(strwrap(text, width = width), collapse = "\n")
}

save_figure <- function(plot, stem, height_mm, write_pdf = FALSE) {
  ggplot2::ggsave(
    file.path(figure_dir, paste0(stem, ".png")),
    plot,
    width = 170,
    height = height_mm,
    units = "mm",
    dpi = 300,
    bg = "white"
  )
  if (write_pdf) {
    ggplot2::ggsave(
      file.path(figure_dir, paste0(stem, ".pdf")),
      plot,
      width = 170,
      height = height_mm,
      units = "mm",
      bg = "white"
    )
  }
  invisible(NULL)
}

effect_plot <- function(data, title, colour) {
  data <- data |>
    mutate(
      metric_label = factor(
        .data$metric_label,
        levels = rev(metric_registry$manuscript_name)
      )
    )
  ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data$plot_estimate,
      y = .data$metric_label,
      xmin = .data$plot_conf_low,
      xmax = .data$plot_conf_high
    )
  ) +
    ggplot2::geom_vline(
      xintercept = 0,
      colour = "grey55",
      linewidth = 0.45
    ) +
    ggplot2::geom_errorbar(
      orientation = "y",
      width = 0.18,
      linewidth = 0.6,
      colour = colour
    ) +
    ggplot2::geom_point(
      size = 2.3,
      shape = 21,
      fill = "white",
      colour = colour
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$plot_scale),
      ncol = 1,
      scales = "free",
      space = "free_y",
      strip.position = "right"
    ) +
    ggplot2::labs(
      title = title,
      subtitle = paste0(
        "Adjusted association per ",
        sprintf("%.4f", unique(data$score_participant_sd)),
        " VLSQ-8 points; points and bars are estimates and 95% Wald intervals"
      ),
      x = NULL,
      y = NULL,
      caption = wrap_caption(paste0(
        "Ratios are shown as percent change. Time below 10 lx melEDI before ",
        "sleep uses an identity-Gaussian difference in hours."
      ))
    ) +
    ggplot2::theme_minimal(base_size = 9.5) +
    ggplot2::theme(
      plot.title.position = "plot",
      panel.grid.minor = ggplot2::element_blank(),
      strip.text.y = ggplot2::element_text(
        angle = 0,
        hjust = 0,
        size = 8
      ),
      axis.text.y = ggplot2::element_text(size = 8),
      plot.caption = ggplot2::element_text(hjust = 0, size = 7.5)
    )
}

near <- read_source("H08_near_eye_effects_data.csv")
chest <- read_source("H08_chest_effects_data.csv")
stopifnot(nrow(near) == 9L, nrow(chest) == 9L)
save_figure(
  effect_plot(near, "Near-eye VLSQ-8 associations", "#0072B2"),
  "H08_near_eye_effects",
  height_mm = 136,
  write_pdf = TRUE
)
save_figure(
  effect_plot(chest, "Chest VLSQ-8 associations", "#D55E00"),
  "H08_chest_effects",
  height_mm = 136,
  write_pdf = TRUE
)

paired <- read_source("H08_paired_placement_effects_data.csv") |>
  filter(.data$included_in_identity_plot)
stopifnot(nrow(paired) == 8L, all(paired$exact_sample_match))
paired_plot <- ggplot2::ggplot(
  paired,
  ggplot2::aes(
    x = .data$comparison_estimate_glasses,
    y = .data$comparison_estimate_chest,
    colour = .data$manuscript_category,
    shape = .data$manuscript_category
  )
) +
  ggplot2::geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    colour = "grey45",
    linewidth = 0.6
  ) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey70", linewidth = 0.5) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.5) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      ymin = .data$comparison_low_chest,
      ymax = .data$comparison_high_chest
    ),
    width = 0,
    linewidth = 0.45
  ) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      xmin = .data$comparison_low_glasses,
      xmax = .data$comparison_high_glasses
    ),
    orientation = "y",
    width = 0,
    linewidth = 0.45
  ) +
  ggplot2::geom_point(size = 2.8, stroke = 0.9) +
  ggplot2::geom_text(
    ggplot2::aes(label = .data$abbreviation),
    nudge_y = 0.018,
    size = 2.8,
    show.legend = FALSE,
    check_overlap = TRUE
  ) +
  ggplot2::coord_equal() +
  ggplot2::scale_colour_manual(
    values = c(
      "level-based" = "#0072B2",
      "duration-based" = "#009E73",
      "exposure-history-based" = "#CC79A7"
    )
  ) +
  ggplot2::labs(
    title = "Paired near-eye and chest association estimates",
    subtitle = paste0(
      "Separate models use identical participant-days;\n",
      "ratio outcomes use the natural-log ratio scale per one VLSQ-8 SD"
    ),
    x = "Near-eye estimate",
    y = "Chest estimate",
    colour = "Metric category",
    shape = "Metric category",
    caption = wrap_caption(paste0(
      "Dashed line: identical estimates; grey lines: null; component bars: ",
      "95% Wald intervals. ",
      "The identity-Gaussian pre-sleep metric remains in the paired source ",
      "table because hours and log ratios must not share an axis."
    ))
  ) +
  ggplot2::theme_minimal(base_size = 9) +
  ggplot2::theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    panel.grid.minor = ggplot2::element_blank(),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7.5)
  )
save_figure(
  paired_plot,
  "H08_paired_placement_effects",
  height_mm = 170,
  write_pdf = TRUE
)

gap <- read_source("H08_gap_common_sample_effects_data.csv") |>
  filter(.data$included_in_identity_plot)
stopifnot(nrow(gap) == 16L, all(gap$exact_common_keys))
gap_plot <- ggplot2::ggplot(
  gap,
  ggplot2::aes(
    x = .data$primary_log_ratio,
    y = .data$gap_log_ratio,
    colour = .data$placement_label,
    shape = .data$placement_label,
    label = .data$abbreviation
  )
) +
  ggplot2::geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    colour = "grey45"
  ) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey70") +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70") +
  ggplot2::geom_point(size = 2.6, stroke = 0.8) +
  ggplot2::geom_text(
    nudge_y = 0.015,
    size = 2.8,
    show.legend = FALSE,
    check_overlap = TRUE
  ) +
  ggplot2::coord_equal() +
  ggplot2::scale_colour_manual(
    values = c("Near eye" = "#0072B2", "Chest" = "#D55E00")
  ) +
  ggplot2::labs(
    title = "Primary and gap-timing-unaware estimates on common samples",
    subtitle = "Ratio outcomes; natural-log ratio per one VLSQ-8 SD",
    x = "Primary dataset estimate",
    y = "Gap-timing-unaware dataset estimate",
    colour = "Placement",
    shape = "Placement",
    caption = wrap_caption(paste0(
      "Dashed line: identical estimates; grey lines: null. Each scenario ",
      "uses the same participant-days within metric and placement."
    ))
  ) +
  ggplot2::theme_minimal(base_size = 9) +
  ggplot2::theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    panel.grid.minor = ggplot2::element_blank(),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7.5)
  )
save_figure(
  gap_plot,
  "H08_gap_common_sample_effects",
  height_mm = 170
)

adequacy <- read_source("H08_near_eye_model_adequacy_data.csv") |>
  mutate(
    manuscript_name = factor(
      .data$manuscript_name,
      levels = metric_registry$manuscript_name
    )
  )
stopifnot(nrow(adequacy) == 7011L)
adequacy_plot_data <- bind_rows(
  adequacy |>
    transmute(
      .data$manuscript_name,
      panel = "Residual versus fitted",
      x = .data$fitted_model_scale,
      y = .data$residual_pearson
    ),
  adequacy |>
    transmute(
      .data$manuscript_name,
      panel = "Normal Q-Q",
      x = .data$qq_theoretical,
      y = .data$qq_observed
    )
)
adequacy_plot <- ggplot2::ggplot(
  adequacy_plot_data,
  ggplot2::aes(x = .data$x, y = .data$y)
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.4) +
  ggplot2::geom_point(alpha = 0.35, size = 0.7, colour = "#0072B2") +
  ggplot2::facet_grid(
    rows = ggplot2::vars(.data$manuscript_name),
    cols = ggplot2::vars(.data$panel),
    scales = "free"
  ) +
  ggplot2::labs(
    title = "Near-eye additive-model adequacy",
    subtitle = "Conditional Pearson residual screens; no simulation or resampling",
    x = NULL,
    y = NULL,
    caption = wrap_caption(paste0(
      "The Q-Q panels are descriptive residual-shape checks. Formal ",
      "numerical fit, bound, zero-mass, and serial-dependence diagnostics ",
      "are reported separately."
    ))
  ) +
  ggplot2::theme_minimal(base_size = 9) +
  ggplot2::theme(
    plot.title.position = "plot",
    strip.text.y = ggplot2::element_text(
      angle = 0,
      hjust = 0,
      size = 7.5
    ),
    strip.text.x = ggplot2::element_text(size = 8),
    panel.grid.minor = ggplot2::element_blank(),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7.5)
  )
save_figure(
  adequacy_plot,
  "H08_near_eye_model_adequacy",
  height_mm = 250
)

figure_manifest <- tibble::tribble(
  ~figure_path,
  ~source_data_path,
  ~width_in,
  ~height_in,
  ~native_width_mm,
  ~intended_width_mm,
  ~smallest_essential_nominal_text_pt,
  ~alt_text,
  "artifacts/10_figures/H08/H08_near_eye_effects.png",
  "artifacts/11_source_data/H08/H08_near_eye_effects_data.csv",
  170 / 25.4,
  136 / 25.4,
  170,
  170,
  7.5,
  paste0(
    "Forest plot of nine site-adjusted near-eye associations per one VLSQ-8 ",
    "standard deviation. Points show estimates and horizontal bars show 95% ",
    "Wald intervals; a vertical zero line marks no change."
  ),
  "artifacts/10_figures/H08/H08_chest_effects.png",
  "artifacts/11_source_data/H08/H08_chest_effects_data.csv",
  170 / 25.4,
  136 / 25.4,
  170,
  170,
  7.5,
  paste0(
    "Forest plot of nine complementary chest associations per one VLSQ-8 ",
    "standard deviation. Points show estimates and horizontal bars show 95% ",
    "Wald intervals; a vertical zero line marks no change."
  ),
  "artifacts/10_figures/H08/H08_paired_placement_effects.png",
  "artifacts/11_source_data/H08/H08_paired_placement_effects_data.csv",
  170 / 25.4,
  170 / 25.4,
  170,
  170,
  7.5,
  paste0(
    "Scatterplot comparing separately fitted near-eye and chest log-ratio ",
    "associations on identical participant-days. Error bars show component ",
    "95% intervals, grey lines show the null, and the dashed diagonal shows ",
    "identical placement estimates."
  ),
  "artifacts/10_figures/H08/H08_gap_common_sample_effects.png",
  "artifacts/11_source_data/H08/H08_gap_common_sample_effects_data.csv",
  170 / 25.4,
  170 / 25.4,
  170,
  170,
  7.5,
  paste0(
    "Scatterplot comparing primary and gap-timing-unaware log-ratio ",
    "associations on identical participant-days. Grey lines show the null and ",
    "the dashed diagonal shows identical scenario estimates."
  ),
  "artifacts/10_figures/H08/H08_near_eye_model_adequacy.png",
  "artifacts/11_source_data/H08/H08_near_eye_model_adequacy_data.csv",
  170 / 25.4,
  250 / 25.4,
  170,
  170,
  7.5,
  paste0(
    "Eighteen-panel diagnostic plot showing residual-versus-fitted and normal ",
    "Q-Q screens for each of the nine primary near-eye additive models."
  )
)
figure_manifest <- figure_manifest |>
  mutate(
    scaling_factor = .data$intended_width_mm / .data$native_width_mm,
    effective_final_text_pt = .data$smallest_essential_nominal_text_pt *
      .data$scaling_factor,
    reporting_rule = "REPORT-011",
    producer = producer,
    r_version = as.character(getRversion())
  )

stopifnot(
  nrow(figure_manifest) == 5L,
  all(figure_manifest$scaling_factor == 1),
  all(figure_manifest$effective_final_text_pt >= 7),
  all(file.exists(file.path(root, figure_manifest$figure_path))),
  all(file.exists(file.path(root, figure_manifest$source_data_path)))
)
write_csv_artifact(figure_manifest, manifest_path, producer)

message(
  "Re-exported five H08 reader figures directly at 170 mm from stored source ",
  "data; smallest effective essential text is 7.5 pt"
)
