#!/usr/bin/env Rscript

# Build reader-facing H11 figures from stored Stage 3 reader source data. This
# is a display-only REPORT-011 repair: no model fitting, prediction, bootstrap,
# simulation, or other scientific recomputation is performed.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(LightLogR)
  library(patchwork)
  library(png)
  library(readr)
  library(scales)
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
      "H11 Stage 3 figures require R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H11/build_h11_stage3_figures.R"
figure_dir <- file.path(root, "artifacts/10_figures/H11/stage3")
manifest_dir <- file.path(root, "artifacts/12_manifests/H11")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(manifest_dir, recursive = TRUE, showWarnings = FALSE)

read_reader <- function(...) {
  path <- file.path(root, ...)
  if (!file.exists(path)) {
    stop(paste("Missing H11 reader-display input:", path), call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE)
}

curves <- read_reader(
  "artifacts", "11_source_data", "H11", "stage3",
  "H11_reader_sex_specific_curves.csv"
)
contrasts <- read_reader(
  "artifacts", "11_source_data", "H11", "stage3",
  "H11_reader_female_minus_male_contrasts.csv"
)
solar_context <- read_reader(
  "artifacts", "11_source_data", "H11", "stage3",
  "H11_reader_solar_context.csv"
)
samples <- read_reader(
  "artifacts", "09_tables", "H11", "stage3",
  "H11_reader_samples.csv"
)
residual_acf <- read_reader(
  "artifacts", "08_diagnostics", "H11", "stage3",
  "H11_reader_residual_acf.csv"
)
residual_summary <- read_reader(
  "artifacts", "08_diagnostics", "H11", "stage3",
  "H11_reader_primary_residual_summary.csv"
)
activity_contrasts <- read_reader(
  "artifacts", "11_source_data", "H11", "stage3",
  "H11_reader_activity_female_minus_male_contrasts.csv"
)
activity_samples <- read_reader(
  "artifacts", "09_tables", "H11", "stage3",
  "H11_reader_activity_samples.csv"
)

stopifnot(
  nrow(curves) == 384L,
  nrow(contrasts) == 192L,
  nrow(solar_context) == 4L,
  nrow(samples) == 4L,
  nrow(residual_acf) == 96L,
  nrow(residual_summary) == 6L,
  nrow(activity_contrasts) == 192L,
  nrow(activity_samples) == 2L,
  all(activity_contrasts$ratio_lower_pointwise_95 <=
    activity_contrasts$female_to_male_shifted_ratio),
  all(activity_contrasts$ratio_upper_pointwise_95 >=
    activity_contrasts$female_to_male_shifted_ratio)
)

figure_spec <- list(
  intended_width_mm = 170,
  base_width_in = 10.5,
  curve_base_height_in = 11,
  diagnostic_base_height_in = 6.5,
  diagnostic_summary_base_height_in = 9.0,
  activity_base_height_in = 7.2,
  export_scale_multiplier = 1,
  smallest_essential_nominal_text_pt = 12,
  smallest_minor_nominal_text_pt = 11,
  raster_dpi = 300,
  a4_width_mm = 210,
  a4_height_mm = 297,
  a4_side_margin_mm = 20
)
figure_spec$export_width_in <-
  figure_spec$base_width_in * figure_spec$export_scale_multiplier
figure_spec$export_width_mm <- figure_spec$export_width_in * 25.4
figure_spec$display_reduction_factor <-
  figure_spec$intended_width_mm / figure_spec$export_width_mm
figure_spec$effective_final_text_pt <-
  figure_spec$smallest_essential_nominal_text_pt *
  figure_spec$display_reduction_factor
figure_spec$effective_final_minor_text_pt <-
  figure_spec$smallest_minor_nominal_text_pt *
  figure_spec$display_reduction_factor

stopifnot(
  isTRUE(all.equal(figure_spec$export_width_in, 10.5)),
  figure_spec$effective_final_text_pt >= 7,
  figure_spec$effective_final_minor_text_pt >= 7,
  identical(
    LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)$name,
    "symlog-1-10-1"
  )
)

sex_palette <- c(Female = "#CC79A7", Male = "#0072B2")

wrap_label <- function(text, width) {
  paste(strwrap(text, width = width), collapse = "\n")
}

theme_h11 <- function() {
  cowplot::theme_cowplot(font_size = 14) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(
        colour = "grey88",
        linewidth = 0.35
      ),
      panel.spacing = grid::unit(5, "pt"),
      legend.position = "top",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(size = 12),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title = ggplot2::element_text(
        face = "bold", size = 14, lineheight = 1.06
      ),
      plot.subtitle = ggplot2::element_text(size = 12, lineheight = 1.13),
      plot.caption = ggplot2::element_text(size = 11, lineheight = 1.12),
      axis.title = ggplot2::element_text(size = 14),
      axis.text = ggplot2::element_text(size = 12),
      strip.text = ggplot2::element_text(size = 14, face = "bold"),
      plot.tag = ggplot2::element_text(size = 14, face = "bold"),
      plot.margin = ggplot2::margin(8, 10, 8, 8)
    )
}

build_curve_figure <- function(run_id, placement_title) {
  run_curves <- curves |>
    dplyr::filter(.data$run_id == .env$run_id) |>
    dplyr::mutate(sex = factor(.data$sex, levels = c("Female", "Male")))
  run_contrast <- contrasts |>
    dplyr::filter(.data$run_id == .env$run_id)
  solar <- solar_context |>
    dplyr::filter(.data$run_id == .env$run_id)
  sample <- samples |>
    dplyr::filter(.data$run_id == .env$run_id)

  if (
    nrow(run_curves) != 96L ||
      nrow(run_contrast) != 48L ||
      nrow(solar) != 1L ||
      nrow(sample) != 1L
  ) {
    stop(paste("Incomplete H11 display source for", run_id), call. = FALSE)
  }

  night <- tibble::tibble(
    xmin = c(0, solar$equal_site_mean_civil_dusk_hour),
    xmax = c(solar$equal_site_mean_civil_dawn_hour, 24)
  )

  curve_panel <- ggplot2::ggplot(run_curves) +
    ggplot2::geom_rect(
      data = night,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax),
      ymin = -Inf,
      ymax = Inf,
      inherit.aes = FALSE,
      fill = "grey92"
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        x = .data$time_hour,
        ymin = .data$lower_melEDI_lx_pointwise_95,
        ymax = .data$upper_melEDI_lx_pointwise_95,
        fill = .data$sex
      ),
      alpha = 0.24,
      colour = NA
    ) +
    ggplot2::geom_line(
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$estimate_melEDI_lx,
        colour = .data$sex
      ),
      linewidth = 1.5
    ) +
    ggplot2::scale_colour_manual(values = sex_palette, drop = FALSE) +
    ggplot2::scale_fill_manual(values = sex_palette, drop = FALSE) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 24, by = 6),
      limits = c(0, 24),
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 250, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::labs(
      title = wrap_label(
        paste0("A  Sex-specific ", placement_title),
        70
      ),
      subtitle = wrap_label(
        paste0(
          "Equal-site conditional means; ",
          sample$participants, " participants, ",
          sample$participant_days, " participant-days, ",
          format(sample$observations_30_minute, big.mark = ","),
          " 30-minute observations"
        ),
        78
      ),
      x = NULL,
      y = "melEDI (lx)"
    ) +
    theme_h11()

  pointwise_marks <- run_contrast |>
    dplyr::filter(
      .data$pointwise_direction != "not_distinguishable_pointwise"
    )
  all_bins_marked <- nrow(pointwise_marks) == nrow(run_contrast)
  pointwise_marks_for_plot <- if (all_bins_marked) {
    pointwise_marks[0, , drop = FALSE]
  } else {
    pointwise_marks
  }
  ratio_subtitle <- if (all_bins_marked) {
    paste(
      "All 48 displayed pointwise intervals exclude 1; circles are omitted",
      "to keep the curve readable. Intervals are not simultaneous."
    )
  } else {
    paste(
      "Ribbons are participant-cluster-robust pointwise 95% intervals;",
      "open circles mark displayed bins whose interval excludes 1."
    )
  }

  ratio_panel <- ggplot2::ggplot(run_contrast) +
    ggplot2::geom_rect(
      data = night,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax),
      ymin = -Inf,
      ymax = Inf,
      inherit.aes = FALSE,
      fill = "grey92"
    ) +
    ggplot2::geom_hline(
      yintercept = 1,
      linetype = "dashed",
      colour = "grey30"
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        x = .data$time_hour,
        ymin = .data$ratio_lower_pointwise_95,
        ymax = .data$ratio_upper_pointwise_95
      ),
      fill = "grey55",
      alpha = 0.45
    ) +
    ggplot2::geom_line(
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$female_to_male_shifted_ratio
      ),
      colour = "black",
      linewidth = 1.5
    ) +
    ggplot2::geom_point(
      data = pointwise_marks_for_plot,
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$female_to_male_shifted_ratio
      ),
      shape = 21,
      size = 3,
      stroke = 1,
      fill = "white",
      colour = "black"
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 24, by = 6),
      limits = c(0, 24),
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_log10(
      breaks = c(0.5, 0.75, 1, 1.5, 2),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::labs(
      title = "B  Female-to-Male shifted-value ratio",
      subtitle = wrap_label(ratio_subtitle, 78),
      x = "Local clock time (hours)",
      y = "Female / Male ratio"
    ) +
    theme_h11()

  curve_panel / ratio_panel +
    patchwork::plot_layout(heights = c(1.7, 1)) +
    patchwork::plot_annotation(
      caption = wrap_label(
        paste(
          "Grey shading spans midnight to equal-site mean civil dawn and",
          "equal-site mean civil dusk to midnight. Intervals are pointwise,",
          "not simultaneous; the global participant-cluster-robust curve",
          "test is the inferential test and the display cannot establish a",
          "familywise-significant time period. The melEDI axis uses the",
          "approved symlog scale: linear from 0 to 1 lx and base-10 above 1 lx."
        ),
        104
      ),
      theme = theme_h11()
    )
}

build_activity_figure <- function() {
  model_levels <- c(
    "Activity-complete sample, unadjusted",
    "Same sample, activity-adjusted"
  )
  display <- activity_contrasts |>
    dplyr::mutate(
      placement_label = factor(
        .data$placement_label,
        levels = c("Near eye", "Chest")
      ),
      analysis_step = factor(
        .data$analysis_step,
        levels = model_levels
      )
    )
  if (
    nrow(display) != 192L ||
      anyNA(display$placement_label) ||
      anyNA(display$analysis_step)
  ) {
    stop("Incomplete H11 activity-context display source", call. = FALSE)
  }
  palette <- c(
    "Activity-complete sample, unadjusted" = "#0072B2",
    "Same sample, activity-adjusted" = "#D55E00"
  )
  subtitle <- paste0(
    "Same sample within each placement: near eye, ",
    activity_samples$participants[
      activity_samples$placement_label == "Near eye"
    ],
    " participants and ",
    format(
      activity_samples$observations_30_minute[
        activity_samples$placement_label == "Near eye"
      ],
      big.mark = ","
    ),
    " observations;\nchest, ",
    activity_samples$participants[
      activity_samples$placement_label == "Chest"
    ],
    " participants and ",
    format(
      activity_samples$observations_30_minute[
        activity_samples$placement_label == "Chest"
      ],
      big.mark = ","
    ),
    "."
  )

  ggplot2::ggplot(display) +
    ggplot2::geom_hline(
      yintercept = 1,
      linetype = "dashed",
      colour = "grey30",
      linewidth = 0.9
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        x = .data$time_hour,
        ymin = .data$ratio_lower_pointwise_95,
        ymax = .data$ratio_upper_pointwise_95,
        fill = .data$analysis_step,
        group = .data$analysis_step
      ),
      alpha = 0.18,
      colour = NA
    ) +
    ggplot2::geom_line(
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$female_to_male_shifted_ratio,
        colour = .data$analysis_step,
        linetype = .data$analysis_step,
        group = .data$analysis_step
      ),
      linewidth = 1.5
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$placement_label),
      ncol = 1,
      scales = "free_y"
    ) +
    ggplot2::scale_colour_manual(values = palette, drop = FALSE) +
    ggplot2::scale_fill_manual(values = palette, drop = FALSE) +
    ggplot2::scale_linetype_manual(
      values = c(
        "Activity-complete sample, unadjusted" = "solid",
        "Same sample, activity-adjusted" = "longdash"
      ),
      drop = FALSE
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 24, by = 6),
      limits = c(0, 24),
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_log10(
      breaks = c(0.4, 0.5, 0.75, 1, 1.5, 2, 3),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::labs(
      title = "Activity-context sensitivity of the Female-to-Male curve",
      subtitle = subtitle,
      x = "Local clock time (hours)",
      y = "Female / Male shifted-value ratio",
      caption = wrap_label(
        paste(
          "Ribbons are participant-cluster-robust pointwise 95% confidence",
          "intervals for each fitted curve, not an interval for the change",
          "between models and not simultaneous over time. The ratio axis is",
          "logarithmic around the null ratio of 1."
        ),
        110
      )
    ) +
    theme_h11()
}

build_diagnostic_figure <- function(run_id, placement_title) {
  acf <- residual_acf |>
    dplyr::filter(.data$run_id == .env$run_id) |>
    dplyr::mutate(
      stage = factor(
        .data$stage,
        levels = c(
          "preliminary_rho0_response",
          "final_AR1_standardized"
        ),
        labels = c("Before AR(1)", "After AR(1)")
      )
    )
  if (nrow(acf) != 24L) {
    stop(paste("Incomplete residual source for", run_id), call. = FALSE)
  }

  ggplot2::ggplot(
    acf,
    ggplot2::aes(
      x = .data$lag_minutes,
      y = .data$correlation,
      colour = .data$stage
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey60") +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_colour_manual(
      values = c("Before AR(1)" = "#D55E00", "After AR(1)" = "#0072B2")
    ) +
    ggplot2::labs(
      title = wrap_label(
        paste0("Boundary-aware residual dependence: ", placement_title),
        60
      ),
      subtitle = wrap_label(
        "No pair crosses a participant-day or declared sequence boundary.",
        72
      ),
      x = "Lag (minutes)",
      y = "Residual correlation"
    ) +
    theme_h11()
}

build_residual_summary_figure <- function() {
  display <- residual_summary |>
    dplyr::mutate(
      placement_label = factor(
        .data$placement_label,
        levels = c("Near eye", "Chest")
      ),
      biological_sex = factor(
        .data$biological_sex,
        levels = c("Male", "Female", "Overall")
      )
    )
  if (
    nrow(display) != 6L ||
      anyNA(display$placement_label) ||
      anyNA(display$biological_sex)
  ) {
    stop("Incomplete H11 primary residual-summary source", call. = FALSE)
  }

  residual_palette <- c(
    Overall = "#4D4D4D",
    Female = sex_palette[["Female"]],
    Male = sex_palette[["Male"]]
  )

  quantile_panel <- ggplot2::ggplot(
    display,
    ggplot2::aes(y = .data$biological_sex, colour = .data$biological_sex)
  ) +
    ggplot2::geom_vline(
      xintercept = 0,
      linetype = "dashed",
      colour = "grey45",
      linewidth = 0.8
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$q01, xend = .data$q99, yend = .data$biological_sex),
      linewidth = 0.8
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$q05, xend = .data$q95, yend = .data$biological_sex),
      linewidth = 2.1
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$q25, xend = .data$q75, yend = .data$biological_sex),
      linewidth = 5.2,
      lineend = "round"
    ) +
    ggplot2::geom_point(ggplot2::aes(x = .data$median), size = 3.2) +
    ggplot2::facet_wrap(ggplot2::vars(.data$placement_label), nrow = 1) +
    ggplot2::scale_colour_manual(values = residual_palette, guide = "none") +
    ggplot2::scale_x_continuous(
      breaks = seq(-2, 2, by = 1),
      limits = c(-2.5, 2.7),
      expand = c(0, 0)
    ) +
    ggplot2::labs(
      title = "A  Residual location and tails",
      subtitle = wrap_label(
        "Thin: 1st-99th percentiles; medium: 5th-95th; thick: interquartile range; point: median.",
        94
      ),
      x = "Final standardized residual",
      y = "Recorded biological sex"
    ) +
    theme_h11()

  scale_panel <- ggplot2::ggplot(
    display,
    ggplot2::aes(
      x = .data$correlation_absolute_residual_fitted,
      y = .data$biological_sex,
      colour = .data$biological_sex
    )
  ) +
    ggplot2::geom_vline(
      xintercept = 0,
      linetype = "dashed",
      colour = "grey45",
      linewidth = 0.8
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = 0,
        xend = .data$correlation_absolute_residual_fitted,
        yend = .data$biological_sex
      ),
      linewidth = 1.2
    ) +
    ggplot2::geom_point(size = 3.2) +
    ggplot2::facet_wrap(ggplot2::vars(.data$placement_label), nrow = 1) +
    ggplot2::scale_colour_manual(values = residual_palette, guide = "none") +
    ggplot2::scale_x_continuous(
      limits = c(0, 0.26),
      breaks = c(0, 0.1, 0.2),
      labels = scales::label_number(accuracy = 0.01),
      expand = c(0, 0)
    ) +
    ggplot2::labs(
      title = "B  Residual magnitude changes with the fitted value",
      subtitle = wrap_label(
        "Positive correlations between absolute residuals and fitted values indicate remaining heteroscedasticity.",
        94
      ),
      x = "Correlation of absolute residual with fitted value",
      y = "Recorded biological sex"
    ) +
    theme_h11() +
    ggplot2::theme(panel.spacing.x = grid::unit(12, "pt"))

  quantile_panel / scale_panel +
    patchwork::plot_layout(heights = c(1.15, 1))
}

figure_registry <- tibble::tribble(
  ~figure_id, ~run_id, ~figure_kind, ~placement_title, ~filename,
  "primary_near_eye_curves", "main__glasses__all_available", "curve",
  "near-eye curves", "H11_reader_primary_near_eye_curves",
  "complementary_chest_curves", "main__chest__all_available", "curve",
  "chest curves", "H11_reader_complementary_chest_curves",
  "sensitivity_near_eye_curves",
  "manuscript_prepared_data__glasses__all_available", "curve",
  "near-eye curves in the gap-timing-unaware dataset",
  "H11_reader_gap_timing_unaware_near_eye_curves",
  "sensitivity_chest_curves",
  "manuscript_prepared_data__chest__all_available", "curve",
  "chest curves in the gap-timing-unaware dataset",
  "H11_reader_gap_timing_unaware_chest_curves",
  "activity_context_attenuation", "activity_context_common_sample", "activity",
  "activity-context sensitivity",
  "H11_reader_activity_context_female_to_male_curves",
  "primary_near_eye_residual_dependence", "main__glasses__all_available",
  "diagnostic", "near eye", "H11_reader_near_eye_residual_dependence",
  "complementary_chest_residual_dependence", "main__chest__all_available",
  "diagnostic", "chest", "H11_reader_chest_residual_dependence",
  "primary_residual_summary", "primary_common", "diagnostic_summary",
  "near eye and chest", "H11_reader_primary_residual_summary"
) |>
  dplyr::mutate(
    base_height_in = dplyr::case_when(
      .data$figure_kind == "curve" ~ figure_spec$curve_base_height_in,
      .data$figure_kind == "activity" ~ figure_spec$activity_base_height_in,
      .data$figure_kind == "diagnostic_summary" ~
        figure_spec$diagnostic_summary_base_height_in,
      TRUE ~ figure_spec$diagnostic_base_height_in
    ),
    export_height_in = .data$base_height_in *
      figure_spec$export_scale_multiplier,
    export_height_mm = .data$export_height_in * 25.4,
    intended_display_height_mm = figure_spec$intended_width_mm *
      .data$base_height_in / figure_spec$base_width_in
  )

plots <- vector("list", nrow(figure_registry))
names(plots) <- figure_registry$figure_id
manifest_rows <- list()

for (index in seq_len(nrow(figure_registry))) {
  row <- figure_registry[index, , drop = FALSE]
  plot <- if (row$figure_kind == "curve") {
    build_curve_figure(row$run_id, row$placement_title)
  } else if (row$figure_kind == "activity") {
    build_activity_figure()
  } else if (row$figure_kind == "diagnostic_summary") {
    build_residual_summary_figure()
  } else {
    build_diagnostic_figure(row$run_id, row$placement_title)
  }
  plots[[row$figure_id]] <- plot

  png_path <- file.path(figure_dir, paste0(row$filename, ".png"))
  pdf_path <- file.path(figure_dir, paste0(row$filename, ".pdf"))
  ggplot2::ggsave(
    png_path,
    plot = plot,
    width = figure_spec$base_width_in,
    height = row$base_height_in,
    units = "in",
    scale = figure_spec$export_scale_multiplier,
    dpi = figure_spec$raster_dpi,
    bg = "white"
  )
  ggplot2::ggsave(
    pdf_path,
    plot = plot,
    width = figure_spec$base_width_in,
    height = row$base_height_in,
    units = "in",
    scale = figure_spec$export_scale_multiplier,
    device = grDevices::cairo_pdf,
    bg = "white"
  )

  output_paths <- c(png_path, pdf_path)
  manifest_rows[[row$figure_id]] <- tibble::tibble(
    figure_id = row$figure_id,
    run_id = row$run_id,
    figure_kind = row$figure_kind,
    path = substring(output_paths, nchar(root) + 2L),
    file_format = tools::file_ext(output_paths),
    sha256 = unname(vapply(output_paths, artifact_sha256, character(1))),
    bytes = as.numeric(file.info(output_paths)$size),
    base_width_in = figure_spec$base_width_in,
    base_height_in = row$base_height_in,
    export_scale_multiplier = figure_spec$export_scale_multiplier,
    export_width_in = figure_spec$export_width_in,
    export_height_in = row$export_height_in,
    native_export_width_mm = figure_spec$export_width_mm,
    native_export_height_mm = row$export_height_mm,
    intended_display_width_mm = figure_spec$intended_width_mm,
    intended_display_height_mm = row$intended_display_height_mm,
    display_reduction_factor = figure_spec$display_reduction_factor,
    smallest_essential_nominal_text_pt =
      figure_spec$smallest_essential_nominal_text_pt,
    effective_final_essential_text_pt =
      figure_spec$effective_final_text_pt,
    smallest_minor_nominal_text_pt =
      figure_spec$smallest_minor_nominal_text_pt,
    effective_final_minor_text_pt =
      figure_spec$effective_final_minor_text_pt,
    melEDI_display_transform = dplyr::if_else(
      row$figure_kind == "curve",
      "LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)",
      "not applicable"
    ),
    untransformed_source_data = dplyr::case_when(
      row$figure_kind == "curve" ~
        "artifacts/11_source_data/H11/stage3/H11_reader_sex_specific_curves.csv",
      row$figure_kind == "activity" ~
        paste0(
          "artifacts/11_source_data/H11/stage3/",
          "H11_reader_activity_female_minus_male_contrasts.csv"
        ),
      row$figure_kind == "diagnostic_summary" ~
        paste0(
          "artifacts/08_diagnostics/H11/stage3/",
          "H11_reader_primary_residual_summary.csv"
        ),
      TRUE ~ "artifacts/08_diagnostics/H11/stage3/H11_reader_residual_acf.csv"
    ),
    raster_dpi = ifelse(tools::file_ext(output_paths) == "png", 300, NA_real_),
    policy_id = dplyr::if_else(
      row$figure_kind == "curve",
      "REPORT-011; REPORT-013",
      "REPORT-011"
    ),
    producer = producer,
    stringsAsFactors = FALSE
  )
}

proof_path <- file.path(
  manifest_dir,
  "H11_stage3_figure_A4_proofs.pdf"
)
grDevices::cairo_pdf(
  proof_path,
  width = figure_spec$a4_width_mm / 25.4,
  height = figure_spec$a4_height_mm / 25.4,
  onefile = TRUE,
  bg = "white"
)
for (index in seq_len(nrow(figure_registry))) {
  row <- figure_registry[index, , drop = FALSE]
  grid::grid.newpage()
  grid::grid.rect(gp = grid::gpar(fill = "white", col = NA))
  png_path <- file.path(figure_dir, paste0(row$filename, ".png"))
  proof_raster <- png::readPNG(png_path)
  grid::grid.raster(
    proof_raster,
    x = grid::unit(figure_spec$a4_side_margin_mm, "mm"),
    y = grid::unit(
      figure_spec$a4_height_mm - figure_spec$a4_side_margin_mm,
      "mm"
    ),
    width = grid::unit(figure_spec$intended_width_mm, "mm"),
    height = grid::unit(row$intended_display_height_mm, "mm"),
    just = c("left", "top"),
    interpolate = TRUE
  )
  grid::grid.text(
    paste0("Physical-size QA page ", index, ": ", row$figure_id),
    x = grid::unit(figure_spec$a4_side_margin_mm, "mm"),
    y = grid::unit(10, "mm"),
    just = c("left", "bottom"),
    gp = grid::gpar(fontsize = 6, col = "grey40")
  )
}
grDevices::dev.off()

figure_manifest <- dplyr::bind_rows(manifest_rows)
qa_manifest <- figure_registry |>
  dplyr::transmute(
    .data$figure_id,
    .data$run_id,
    .data$figure_kind,
    png_path = paste0(
      "artifacts/10_figures/H11/stage3/",
      .data$filename,
      ".png"
    ),
    base_width_in = figure_spec$base_width_in,
    base_height_in = .data$base_height_in,
    export_scale_multiplier = figure_spec$export_scale_multiplier,
    export_width_in = figure_spec$export_width_in,
    export_height_in = .data$export_height_in,
    native_export_width_mm = figure_spec$export_width_mm,
    native_export_height_mm = .data$export_height_mm,
    intended_display_width_mm = figure_spec$intended_width_mm,
    intended_display_height_mm = .data$intended_display_height_mm,
    display_reduction_factor = figure_spec$display_reduction_factor,
    smallest_essential_nominal_text_pt =
      figure_spec$smallest_essential_nominal_text_pt,
    effective_final_essential_text_pt =
      figure_spec$effective_final_text_pt,
    smallest_minor_nominal_text_pt =
      figure_spec$smallest_minor_nominal_text_pt,
    effective_final_minor_text_pt =
      figure_spec$effective_final_minor_text_pt,
    a4_page_width_mm = figure_spec$a4_width_mm,
    a4_side_margin_mm = figure_spec$a4_side_margin_mm,
    a4_proof_path = substring(proof_path, nchar(root) + 2L),
    a4_proof_page = dplyr::row_number(),
    final_asset_canvas = "tightly bounded to figure; A4 page excluded",
    physical_size_evidence = paste(
      "A4 portrait raster proof of the exported asset displayed at 170 mm;",
      "20-mm side margins; A4 is QA only"
    ),
    typography_status = "PASS_BY_CALCULATION_PENDING_VISUAL_INSPECTION",
    visual_status = "PENDING",
    overall_status = "NOT_TESTED_PENDING_VISUAL_INSPECTION",
    policy_id = dplyr::if_else(
      .data$figure_kind == "curve",
      "REPORT-011; REPORT-013",
      "REPORT-011"
    )
  )

invisible(write_csv_artifact(
  figure_manifest,
  file.path(manifest_dir, "H11_stage3_figure_manifest.csv"),
  producer = producer
))
invisible(write_csv_artifact(
  qa_manifest,
  file.path(manifest_dir, "H11_stage3_figure_readability_qa.csv"),
  producer = producer
))

message(
  "H11 Stage 3 display-only figures complete: ",
  nrow(figure_registry),
  " logical figures at 170 mm; source typography follows the approved",
  " 14/12/11-pt reference; minimum effective essential text ",
  sprintf("%.1f pt", figure_spec$effective_final_text_pt),
  ". Visual A4 proof inspection remains required."
)
