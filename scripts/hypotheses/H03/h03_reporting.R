h03_figure_theme <- function() {
  cowplot::theme_cowplot(font_size = 14) +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 12, colour = "black"),
      axis.title = ggplot2::element_text(size = 14),
      strip.text = ggplot2::element_text(size = 14, face = "bold"),
      plot.title = ggplot2::element_text(size = 14, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 12),
      plot.caption = ggplot2::element_text(size = 11, hjust = 0),
      plot.tag = ggplot2::element_text(size = 14, face = "bold"),
      legend.text = ggplot2::element_text(size = 12),
      legend.title = ggplot2::element_text(size = 12),
      panel.grid.major.y = ggplot2::element_line(
        colour = "#E3E6E8",
        linewidth = 0.35
      ),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    )
}

h03_save_plot <- function(
  plot,
  stem,
  directory,
  width,
  height,
  producer
) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  output <- list()
  for (extension in c("png", "pdf", "svg")) {
    path <- file.path(directory, paste0(stem, ".", extension))
    temporary <- tempfile(
      pattern = paste0(stem, "."),
      tmpdir = directory,
      fileext = paste0(".", extension)
    )
    ggplot2::ggsave(
      filename = temporary,
      plot = plot,
      width = width,
      height = height,
      units = "in",
      dpi = if (extension == "png") 300 else 300,
      bg = "white",
      limitsize = FALSE
    )
    atomic_replace_artifact(temporary, path)
    info <- file.info(path)
    output[[extension]] <- list(
      path = normalizePath(path, winslash = "/", mustWork = TRUE),
      bytes = unname(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
    )
  }
  output
}

h03_primary_category_figure <- function(
  data,
  category_registry,
  caption_extra = NULL
) {
  display <- data |>
    dplyr::filter(.data$distribution == "site_standardized") |>
    dplyr::left_join(
      category_registry |>
        dplyr::select("category_code", "figure_label"),
      by = "category_code"
    ) |>
    dplyr::mutate(
      figure_label = factor(
        .data$figure_label,
        levels = category_registry$figure_label
      ),
      placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
    )

  absolute <- ggplot2::ggplot(
    display,
    ggplot2::aes(
      x = .data$figure_label,
      y = .data$expected_mel_edi_lx,
      colour = .data$placement,
      group = .data$placement
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey75", linewidth = 0.4) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = .data$expected_conf_low_lx,
        ymax = .data$expected_conf_high_lx
      ),
      width = 0,
      position = ggplot2::position_dodge(width = 0.42),
      linewidth = 0.7,
      na.rm = TRUE
    ) +
    ggplot2::geom_point(
      position = ggplot2::position_dodge(width = 0.42),
      size = 2.8,
      na.rm = TRUE
    ) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 100, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::scale_colour_manual(
      values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
    ) +
    ggplot2::labs(
      title = "Site-standardized expected one-hour melEDI",
      x = NULL,
      y = "melEDI (lx)",
      colour = "Placement"
    ) +
    h03_figure_theme() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 0, hjust = 0.5),
      legend.position = "top"
    )

  ratios <- display |>
    dplyr::filter(.data$category_order != 1L)
  relative <- ggplot2::ggplot(
    ratios,
    ggplot2::aes(
      x = .data$figure_label,
      y = .data$ratio_to_indoor,
      colour = .data$placement,
      group = .data$placement
    )
  ) +
    ggplot2::geom_hline(
      yintercept = 1,
      colour = "grey45",
      linetype = "dashed",
      linewidth = 0.6
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = .data$ratio_conf_low,
        ymax = .data$ratio_conf_high
      ),
      width = 0,
      position = ggplot2::position_dodge(width = 0.42),
      linewidth = 0.7,
      na.rm = TRUE
    ) +
    ggplot2::geom_point(
      position = ggplot2::position_dodge(width = 0.42),
      size = 2.8,
      na.rm = TRUE
    ) +
    ggplot2::scale_y_log10(
      breaks = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::scale_colour_manual(
      values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
    ) +
    ggplot2::labs(
      title = "Ratio to indoor electric light",
      x = NULL,
      y = "Ratio",
      colour = "Placement"
    ) +
    h03_figure_theme() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 0, hjust = 0.5),
      legend.position = "none"
    )

  patchwork::wrap_plots(absolute, relative, ncol = 1) +
    patchwork::plot_annotation(
      tag_levels = "A",
      caption = paste0(
        "Points and bars are estimates and participant-cluster-robust 95% ",
        "confidence intervals.\n",
        "Sites receive equal standardization weight; the melEDI axis ",
        "transformation is display-only.",
        if (is.null(caption_extra)) "" else paste0("\n", caption_extra)
      ),
      theme = h03_figure_theme()
    )
}

h03_site_context_figure <- function(data, category_registry, site_registry) {
  display <- data |>
    dplyr::filter(.data$site %in% site_registry$site) |>
    dplyr::left_join(
      category_registry |>
        dplyr::select("category_code", "figure_label"),
      by = "category_code"
    ) |>
    dplyr::mutate(
      site_display_name = factor(
        .data$site_display_name,
        levels = rev(site_registry$display_name)
      ),
      figure_label = factor(
        .data$figure_label,
        levels = category_registry$figure_label
      ),
      differs_from_site_standardized_mean =
        .data$reporting_status == "ESTIMABLE" &
        is.finite(.data$site_deviation_p_adjusted) &
        .data$site_deviation_p_adjusted < 0.05
    )
  averages <- display |>
    dplyr::filter(is.finite(.data$site_standardized_category_mean_lx)) |>
    dplyr::distinct(
      .data$figure_label,
      .data$site_standardized_category_mean_lx
    )
  family_sizes <- unique(stats::na.omit(display$family_n))
  family_size_text <- if (length(family_sizes) == 1L) {
    as.character(family_sizes)
  } else {
    "the registered"
  }
  ggplot2::ggplot(
    display,
    ggplot2::aes(
      x = .data$cell_mean_lx,
      y = .data$site_display_name,
      colour = .data$site
    )
  ) +
    ggplot2::geom_vline(
      data = averages,
      ggplot2::aes(
        xintercept = .data$site_standardized_category_mean_lx
      ),
      inherit.aes = FALSE,
      colour = "grey35",
      linetype = "dashed",
      linewidth = 0.65
    ) +
    ggplot2::geom_errorbar(
      data = dplyr::filter(display, .data$reporting_status == "ESTIMABLE"),
      ggplot2::aes(
        xmin = .data$cell_conf_low_lx,
        xmax = .data$cell_conf_high_lx
      ),
      orientation = "y",
      width = 0,
      linewidth = 0.6
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        display,
        .data$reporting_status == "ESTIMABLE",
        !.data$differs_from_site_standardized_mean
      ),
      shape = 21,
      fill = "white",
      size = 3,
      stroke = 0.8
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        display,
        .data$reporting_status == "ESTIMABLE",
        .data$differs_from_site_standardized_mean
      ),
      ggplot2::aes(fill = .data$site),
      shape = 21,
      size = 3.4,
      stroke = 0.7
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        display,
        .data$reporting_status != "NOT_APPLICABLE",
        .data$reporting_status != "ESTIMABLE"
      ),
      ggplot2::aes(x = 0),
      shape = 4,
      size = 2.6,
      stroke = 0.9
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$figure_label),
      ncol = 4
    ) +
    ggplot2::scale_x_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 100, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::scale_colour_manual(
      values = stats::setNames(site_registry$color_hex, site_registry$site),
      guide = "none"
    ) +
    ggplot2::scale_fill_manual(
      values = stats::setNames(site_registry$color_hex, site_registry$site),
      guide = "none"
    ) +
    ggplot2::labs(
      title = "Near-eye expected one-hour melEDI by site and light source",
      subtitle = paste(
        "Dashed line: site-standardized category mean; filled points:",
        "BH-adjusted site deviation p < 0.05; open points: label not passed"
      ),
      x = "Expected one-hour melEDI (lx)",
      y = NULL,
      caption = paste0(
        "Estimates use the selected seven-category interaction model; bars are participant-cluster-robust 95% confidence intervals.\n",
        "The dashed line is the geometric mean of model cell expectations with each site contributing equally on the fitted log scale. ",
        "Filled points differ from that mean after BH adjustment across ",
        family_size_text, " H03-F4 site-deviation contrasts.\n",
        "Crosses at zero mark cells that failed the predeclared support rule; the melEDI axis transformation is display-only."
      )
    ) +
    h03_figure_theme() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 10),
      panel.spacing = grid::unit(1, "lines"),
      plot.caption = ggplot2::element_text(
        size = 11,
        lineheight = 1.05,
        hjust = 0,
        margin = ggplot2::margin(t = 10, b = 8)
      ),
      plot.caption.position = "plot",
      plot.margin = ggplot2::margin(t = 8, r = 14, b = 16, l = 8)
    )
}

h03_paired_placement_figure <- function(data, category_registry) {
  display <- data |>
    dplyr::left_join(
      category_registry |>
        dplyr::select("category_code", "short_label"),
      by = "category_code"
    ) |>
    dplyr::filter(
      .data$near_estimability_status %in% c("ESTIMABLE", "REFERENCE"),
      .data$chest_estimability_status %in% c("ESTIMABLE", "REFERENCE"),
      .data$category_order != 1L
    ) |>
    dplyr::mutate(
      label_x = dplyr::case_when(
        .data$category_code == "display" ~ 0.72,
        .data$category_code == "sleep_external_light" ~ 0.31,
        .data$category_code == "sleep_darkness" ~ 0.060,
        .data$category_code == "daylight_indoor" ~ 2.10,
        .data$category_code == "daylight_outdoor" ~ 10.8,
        TRUE ~ .data$near_ratio
      ),
      label_y = dplyr::case_when(
        .data$category_code == "display" ~ 0.69,
        .data$category_code == "sleep_external_light" ~ 0.49,
        .data$category_code == "sleep_darkness" ~ 0.061,
        .data$category_code == "daylight_indoor" ~ 2.55,
        .data$category_code == "daylight_outdoor" ~ 17.0,
        TRUE ~ .data$chest_ratio
      )
    )
  ggplot2::ggplot(
    display,
    ggplot2::aes(
      x = .data$near_ratio,
      y = .data$chest_ratio,
      label = .data$short_label
    )
  ) +
    ggplot2::geom_abline(
      slope = 1,
      intercept = 0,
      linetype = "dashed",
      colour = "grey50"
    ) +
    ggplot2::geom_vline(xintercept = 1, colour = "grey70") +
    ggplot2::geom_hline(yintercept = 1, colour = "grey70") +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = .data$chest_conf_low,
        ymax = .data$chest_conf_high
      ),
      width = 0,
      linewidth = 0.6
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        xmin = .data$near_conf_low,
        xmax = .data$near_conf_high
      ),
      orientation = "y",
      width = 0,
      linewidth = 0.6
    ) +
    ggplot2::geom_point(size = 3, colour = "#333333") +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$label_x, y = .data$label_y),
      size = 3.5
    ) +
    ggplot2::scale_x_log10() +
    ggplot2::scale_y_log10() +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = "Paired/common-sample placement comparison",
      x = "Near-eye ratio to indoor electric",
      y = "Chest ratio to indoor electric",
      caption = paste0(
        "Models are fitted separately to identical participant-hours.\n",
        "The identity line is a concordance reference, not an equivalence test."
      )
    ) +
    h03_figure_theme()
}

h03_residual_figure <- function(
  data,
  points = NULL,
  acf = NULL,
  zero_bins = NULL
) {
  display <- data |>
    dplyr::mutate(
      placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
    )
  if (!is.null(points)) {
    points <- points |>
      dplyr::mutate(
        placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
      )
  }
  residual_plot <- ggplot2::ggplot(
    display,
    ggplot2::aes(
      x = .data$fitted_mean,
      y = .data$pearson_mean,
      colour = .data$placement
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey55", linetype = "dashed") +
    {
      if (is.null(points)) {
        ggplot2::geom_blank()
      } else {
        ggplot2::geom_point(
          data = points,
          ggplot2::aes(
            x = .data$fitted_mean,
            y = .data$pearson_residual,
            colour = .data$placement
          ),
          inherit.aes = FALSE,
          alpha = 0.10,
          size = 0.45
        )
      }
    } +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = .data$pearson_q25,
        ymax = .data$pearson_q75,
        fill = .data$placement
      ),
      alpha = 0.18,
      colour = NA
    ) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::facet_wrap(ggplot2::vars(.data$placement), scales = "free_x") +
    ggplot2::scale_x_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 100, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::scale_y_continuous(
      trans = scales::pseudo_log_trans(base = 10, sigma = 1),
      breaks = c(-5, -1, 0, 1, 5, 20, 100, 500, 2000)
    ) +
    ggplot2::scale_colour_manual(
      values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00"),
      guide = "none"
    ) +
    ggplot2::scale_fill_manual(
      values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00"),
      guide = "none"
    ) +
    ggplot2::labs(
      title = "Individual and binned working Pearson residuals",
      x = "Fitted mean melEDI (lx)",
      y = "Pearson residual",
      caption = paste(
        "Faint points are individual participant-hours; lines show bin",
        "means and ribbons show interquartile ranges. Both axes use",
        "display-only transformations."
      )
    ) +
    h03_figure_theme()

  if (is.null(acf) || is.null(zero_bins)) {
    return(residual_plot)
  }

  acf <- acf |>
    dplyr::mutate(
      placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
    )
  zero_bins <- zero_bins |>
    dplyr::mutate(
      placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
    )
  acf_plot <- ggplot2::ggplot(
    acf,
    ggplot2::aes(
      x = .data$lag,
      y = .data$correlation,
      colour = .data$placement
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey55") +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::facet_wrap(ggplot2::vars(.data$placement)) +
    ggplot2::scale_x_continuous(breaks = sort(unique(acf$lag))) +
    ggplot2::scale_colour_manual(
      values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00"),
      guide = "none"
    ) +
    ggplot2::labs(
      title = "Boundary-aware residual autocorrelation",
      x = "Lag (hours)",
      y = "Pearson-residual correlation"
    ) +
    h03_figure_theme()

  zero_long <- zero_bins |>
    tidyr::pivot_longer(
      cols = c(
        "observed_zero_fraction",
        "working_expected_zero_fraction"
      ),
      names_to = "series",
      values_to = "zero_fraction"
    ) |>
    dplyr::mutate(
      series = factor(
        .data$series,
        levels = c(
          "observed_zero_fraction",
          "working_expected_zero_fraction"
        ),
        labels = c("Observed", "Working Tweedie")
      )
    )
  zero_plot <- ggplot2::ggplot(
    zero_long,
    ggplot2::aes(
      x = .data$fitted_mean_median_lx,
      y = .data$zero_fraction,
      colour = .data$series,
      linetype = .data$series
    )
  ) +
    ggplot2::geom_line(linewidth = 0.85) +
    ggplot2::geom_point(size = 2.1) +
    ggplot2::facet_wrap(ggplot2::vars(.data$placement)) +
    ggplot2::scale_x_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 100, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 1),
      labels = scales::label_percent(accuracy = 1)
    ) +
    ggplot2::scale_colour_manual(
      values = c("Observed" = "#0072B2", "Working Tweedie" = "#D55E00")
    ) +
    ggplot2::labs(
      title = "Observed and working zero mass",
      x = "Median fitted mean in decile (lx)",
      y = "Zero fraction",
      colour = NULL,
      linetype = NULL
    ) +
    h03_figure_theme() +
    ggplot2::theme(legend.position = "top")

  patchwork::wrap_plots(
    residual_plot,
    acf_plot,
    zero_plot,
    ncol = 1,
    heights = c(1.15, 0.9, 0.9)
  ) +
    patchwork::plot_annotation(
      tag_levels = "A",
      caption = paste0(
        "All panels diagnose the primary additive quasi-Tweedie fits.\n",
        "Participant-cluster covariance changes inferential uncertainty; it does not remove serial correlation from the residuals."
      ),
      theme = h03_figure_theme() +
        ggplot2::theme(
          plot.caption = ggplot2::element_text(
            size = 11,
            lineheight = 1.05,
            hjust = 0,
            margin = ggplot2::margin(t = 10, b = 8)
          ),
          plot.caption.position = "plot",
          plot.margin = ggplot2::margin(t = 8, r = 14, b = 16, l = 8)
        )
    )
}

h03_temporal_figure <- function(
  curves,
  deviations,
  global,
  support,
  category_registry,
  placement,
  ratio_data = NULL,
  curve_title = NULL,
  model_caption = NULL,
  facet_ncol = 4L,
  curve_breaks = c(0, 1, 10, 100, 1000, 10000),
  ratio_title = NULL,
  ratio_y_label = NULL,
  ratio_caption = NULL
) {
  ratio_panel <- !is.null(ratio_data)
  v0_style_exclusions <- "estimated_mel_edi_lx" %in% names(curves)
  if (ratio_panel) {
    deviations <- ratio_data |>
      dplyr::mutate(
        deviation_log10 = log10(.data$ratio_to_global),
        pointwise_conf_low_log10 = log10(.data$ratio_conf_low),
        pointwise_conf_high_log10 = log10(.data$ratio_conf_high)
      )
  }
  palette <- stats::setNames(
    c("#4477AA", "#EE6677", "#228833", "#CCBB44", "#66CCEE", "#AA3377", "#777777"),
    category_registry$category_code
  )
  levels_figure <- category_registry$figure_label
  curves <- curves |>
    dplyr::left_join(
      support |>
        dplyr::select(
          "category_code",
          "time_hour",
          "participant_hours",
          "participants",
          "participant_days",
          "sites",
          "locally_sparse"
        ),
      by = c("category_code", "time_hour"),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      display_mel_edi_lx = if ("estimated_mel_edi_lx" %in% names(curves)) {
        .data$estimated_mel_edi_lx
      } else {
        .data$site_standardized_mel_edi_lx
      },
      figure_label = factor(.data$figure_label, levels = levels_figure)
    ) |>
    dplyr::group_by(.data$category_code) |>
    dplyr::arrange(.data$time_hour, .by_group = TRUE) |>
    dplyr::mutate(
      has_observations = .data$participant_hours > 0,
      observed_run = cumsum(
        .data$has_observations &
          !dplyr::lag(.data$has_observations, default = FALSE)
      )
    ) |>
    dplyr::ungroup()
  deviations <- deviations |>
    dplyr::left_join(
      support |>
        dplyr::select(
          "category_code", "time_hour", "participant_hours", "locally_sparse"
        ),
      by = c("category_code", "time_hour"),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      figure_label = factor(.data$figure_label, levels = levels_figure)
    ) |>
    dplyr::group_by(.data$category_code) |>
    dplyr::arrange(.data$time_hour, .by_group = TRUE) |>
    dplyr::mutate(
      has_observations = .data$participant_hours > 0,
      observed_run = cumsum(
        .data$has_observations &
          !dplyr::lag(.data$has_observations, default = FALSE)
      )
    ) |>
    dplyr::ungroup()
  support <- support |>
    dplyr::mutate(
      figure_label = factor(.data$figure_label, levels = levels_figure)
    )
  global_facets <- tidyr::crossing(
    global,
    category_code = category_registry$category_code
  ) |>
    dplyr::left_join(
      category_registry |>
        dplyr::select("category_code", "figure_label"),
      by = "category_code"
    ) |>
    dplyr::mutate(
      figure_label = factor(.data$figure_label, levels = levels_figure)
    ) |>
    dplyr::left_join(
      support |>
        dplyr::select("category_code", "time_hour", "participant_hours"),
      by = c("category_code", "time_hour"),
      relationship = "one-to-one"
    ) |>
    dplyr::group_by(.data$category_code) |>
    dplyr::arrange(.data$time_hour, .by_group = TRUE) |>
    dplyr::mutate(
      has_observations = .data$participant_hours > 0,
      observed_run = cumsum(
        .data$has_observations &
          !dplyr::lag(.data$has_observations, default = FALSE)
      )
    ) |>
    dplyr::ungroup()
  unsupported <- support |>
    dplyr::filter(.data$participant_hours == 0) |>
    dplyr::transmute(
      .data$figure_label,
      xmin = pmax(.data$time_hour - 0.5, 0),
      xmax = pmin(.data$time_hour + 0.5, 24),
      ymin = -Inf,
      ymax = Inf
    )

  curve_plot <- ggplot2::ggplot(
    curves,
    ggplot2::aes(
      x = .data$time_hour,
      y = .data$display_mel_edi_lx,
      colour = .data$category_code,
      fill = .data$category_code
    )
  ) +
    ggplot2::geom_rect(
      data = unsupported,
      ggplot2::aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = .data$ymin,
        ymax = .data$ymax
      ),
      inherit.aes = FALSE,
      fill = "#F2F2F2",
      colour = NA
    ) +
    ggplot2::geom_ribbon(
      data = dplyr::filter(curves, .data$has_observations),
      ggplot2::aes(
        ymin = .data$pointwise_conf_low_lx,
        ymax = .data$pointwise_conf_high_lx,
        group = interaction(.data$category_code, .data$observed_run)
      ),
      alpha = 0.18,
      colour = NA
    ) +
    ggplot2::geom_line(
      data = dplyr::filter(curves, .data$has_observations),
      ggplot2::aes(
        group = interaction(.data$category_code, .data$observed_run)
      ),
      linewidth = 0.9
    ) +
    ggplot2::geom_line(
      data = dplyr::filter(global_facets, .data$has_observations),
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$global_mel_edi_lx,
        colour = NULL,
        fill = NULL,
        group = interaction(.data$category_code, .data$observed_run)
      ),
      inherit.aes = FALSE,
      colour = "black",
      linetype = "dashed",
      linewidth = 0.55
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        curves,
        .data$has_observations,
        !.data$locally_sparse
      ),
      shape = 21,
      size = 2.0,
      stroke = 0.55
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        curves,
        .data$has_observations,
        .data$locally_sparse
      ),
      shape = 21,
      fill = "white",
      size = 2.0,
      stroke = 0.55
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$figure_label),
      ncol = facet_ncol
    ) +
    ggplot2::scale_x_continuous(breaks = c(0, 6, 12, 18, 24), limits = c(0, 24)) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = curve_breaks,
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::scale_colour_manual(values = palette, guide = "none") +
    ggplot2::scale_fill_manual(values = palette, guide = "none") +
    ggplot2::labs(
      title = if (is.null(curve_title)) {
        paste0(placement, ": global plus light-source time-of-day curves")
      } else {
        curve_title
      },
      subtitle = paste(
        "Dashed black line: global cyclic smooth; filled points: observed;",
        "open points: locally sparse; grey hours: no observations"
      ),
      x = NULL,
      y = "melEDI (lx)"
    ) +
    h03_figure_theme()

  deviation_plot <- ggplot2::ggplot(
    deviations,
    ggplot2::aes(
      x = .data$time_hour,
      y = .data$deviation_log10,
      colour = .data$category_code,
      fill = .data$category_code
    )
  ) +
    ggplot2::geom_rect(
      data = unsupported,
      ggplot2::aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = .data$ymin,
        ymax = .data$ymax
      ),
      inherit.aes = FALSE,
      fill = "#F2F2F2",
      colour = NA
    ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey45", linetype = "dashed") +
    ggplot2::geom_ribbon(
      data = dplyr::filter(deviations, .data$has_observations),
      ggplot2::aes(
        ymin = .data$pointwise_conf_low_log10,
        ymax = .data$pointwise_conf_high_log10,
        group = interaction(.data$category_code, .data$observed_run)
      ),
      alpha = 0.18,
      colour = NA
    ) +
    ggplot2::geom_line(
      data = dplyr::filter(deviations, .data$has_observations),
      ggplot2::aes(
        group = interaction(.data$category_code, .data$observed_run)
      ),
      linewidth = 0.9
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        deviations,
        .data$has_observations,
        !.data$locally_sparse
      ),
      shape = 21,
      size = 2.0,
      stroke = 0.55
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        deviations,
        .data$has_observations,
        .data$locally_sparse
      ),
      shape = 21,
      fill = "white",
      size = 2.0,
      stroke = 0.55
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$figure_label),
      ncol = facet_ncol
    ) +
    ggplot2::scale_x_continuous(breaks = c(0, 6, 12, 18, 24), limits = c(0, 24)) +
    ggplot2::scale_colour_manual(values = palette, guide = "none") +
    ggplot2::scale_fill_manual(values = palette, guide = "none") +
    {
      if (ratio_panel) {
        ggplot2::scale_y_continuous(
          breaks = log10(c(0.1, 0.2, 0.5, 1, 2, 5, 10)),
          labels = c("0.1", "0.2", "0.5", "1", "2", "5", "10")
        )
      } else {
        ggplot2::scale_y_continuous()
      }
    } +
    ggplot2::labs(
      title = if (ratio_panel) {
        if (is.null(ratio_title)) {
          "Light-source ratio to the global time-of-day mean"
        } else {
          ratio_title
        }
      } else {
        "Light-source deviation from the global time-of-day smooth"
      },
      subtitle = paste(
        "Filled points: observed; open points: locally sparse;",
        "grey hours: no observations"
      ),
      x = NULL,
      y = if (ratio_panel) {
        if (is.null(ratio_y_label)) {
          "Ratio to global mean"
        } else {
          ratio_y_label
        }
      } else {
        "Deviation on log10(melEDI + 0.1) scale"
      }
    ) +
    h03_figure_theme()

  support_plot <- ggplot2::ggplot(
    support,
    ggplot2::aes(
      x = .data$time_hour,
      y = .data$participant_hours,
      fill = .data$category_code
    )
  ) +
    ggplot2::geom_col(width = 0.88) +
    ggplot2::geom_point(
      data = dplyr::filter(support, .data$participant_hours == 0),
      ggplot2::aes(y = 0),
      shape = 4,
      size = 1.8,
      stroke = 0.7
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        support,
        .data$participant_hours > 0,
        .data$locally_sparse
      ),
      ggplot2::aes(y = .data$participant_hours),
      shape = 1,
      size = 1.7,
      stroke = 0.6
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$figure_label),
      ncol = facet_ncol
    ) +
    ggplot2::scale_x_continuous(breaks = c(0, 6, 12, 18, 24), limits = c(0, 24)) +
    ggplot2::scale_fill_manual(values = palette, guide = "none") +
    ggplot2::labs(
      title = "Available participant-hours by local time",
      subtitle = "×: no observations; open circle: nonzero but locally sparse",
      x = "Local time (hour)",
      y = "Participant-hours (rows)"
    ) +
    h03_figure_theme()

  patchwork::wrap_plots(
    curve_plot,
    deviation_plot,
    support_plot,
    ncol = 1,
    heights = c(1.15, 1, 0.75)
  ) +
    patchwork::plot_annotation(
      tag_levels = "A",
      caption = paste0(
        "Bands are conditional pointwise 95% intervals; no simultaneous-band or curve-wide inferential claim is made. ",
        if (v0_style_exclusions) {
          paste0(
            "Site, participant, and participant-day smooths remain in the fitted model but are excluded from the displayed curves.\n"
          )
        } else {
          "Site curves use equal site weights on the fitted link scale and are then back-transformed.\n"
        },
        if (ratio_panel) {
          if (is.null(ratio_caption)) {
            paste0(
              "Panel B divides each displayed category-specific mean by the displayed global time-of-day mean; ",
              "the dashed null is 1; pointwise intervals do not support whole-curve significance claims.\n"
            )
          } else {
            paste0(ratio_caption, "\n")
          }
        } else {
          ""
        },
        "In panels A and B, filled circles mark observed support; open circles mark nonzero but locally sparse support ",
        "(<20 participant-hours, <5 participants, or <3 sites at that category-hour). Grey regions and × mark zero observations.\n",
        "The melEDI axis transformation is display-only.",
        if (is.null(model_caption)) "" else paste0(" ", model_caption)
      ),
      theme = h03_figure_theme() +
        ggplot2::theme(
          plot.caption = ggplot2::element_text(
            size = 10.5,
            lineheight = 1.05,
            hjust = 0,
            margin = ggplot2::margin(t = 10, b = 8)
          ),
          plot.caption.position = "plot",
          plot.margin = ggplot2::margin(t = 8, r = 14, b = 16, l = 8)
        )
    )
}
