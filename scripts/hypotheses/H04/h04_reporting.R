# H04 Stage 2 publication-scale figures and plot persistence.

h04_figure_theme <- function() {
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
      panel.grid.minor = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(8, 12, 8, 8)
    )
}

h04_wrap_label <- function(value, width = 21L) {
  vapply(
    value,
    function(item) paste(strwrap(item, width = width), collapse = "\n"),
    character(1)
  )
}

h04_reader_activity_registry <- function() {
  reader_order <- c(
    "home", "working_indoor", "outdoors", "road_vehicle", "sleeping", "other"
  )
  reader_labels <- c(
    home = "At home",
    working_indoor = "Office/home working",
    outdoors = "Outdoors",
    road_vehicle = "Vehicle/public transport",
    sleeping = "Sleeping",
    other = "Other"
  )
  h04_activity_registry() |>
    dplyr::mutate(
      reader_display_order = match(.data$activity_code, .env$reader_order),
      reader_label = unname(.env$reader_labels[.data$activity_code])
    ) |>
    dplyr::arrange(.data$reader_display_order)
}

h04_save_plot <- function(plot, stem, directory, width, height, producer) {
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
      dpi = 300,
      bg = "white",
      limitsize = FALSE
    )
    atomic_replace_artifact(temporary, path)
    info <- file.info(path)
    output[[extension]] <- list(
      path = normalizePath(path, winslash = "/", mustWork = TRUE),
      sha256 = artifact_sha256(path),
      bytes = unname(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
    )
  }
  output
}

h04_primary_figure <- function(
  data,
  mean_title = "Equal-site standardized one-hour melEDI by reported activity",
  ratio_title = "Named-category ratios versus At home",
  caption_extra = NULL
) {
  registry <- h04_reader_activity_registry()
  axis_levels <- h04_wrap_label(registry$reader_label, width = 20L)
  display <- data |>
    dplyr::mutate(
      activity = factor(
        .data$activity,
        levels = registry$activity_label
      ),
      activity_axis = factor(
        h04_wrap_label(
          registry$reader_label[
            match(.data$activity_code, registry$activity_code)
          ],
          width = 20L
        ),
        levels = axis_levels
      ),
      placement = factor(.data$placement, levels = c("Near-eye", "Chest")),
      display_role = ifelse(
        .data$activity == "Other/unspecified activity",
        "Other",
        "Named category"
      )
    )
  positions <- ggplot2::position_dodge(width = 0.52)
  mean_plot <- ggplot2::ggplot(
    display,
    ggplot2::aes(
      x = .data$activity_axis,
      y = .data$standardized_mean_lx,
      colour = .data$placement,
      shape = .data$display_role,
      group = .data$placement
    )
  ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = .data$mean_conf_low_lx,
        ymax = .data$mean_conf_high_lx
      ),
      width = 0,
      linewidth = 0.7,
      position = positions
    ) +
    ggplot2::geom_point(size = 2.8, position = positions) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 100, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::scale_colour_manual(
      values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
    ) +
    ggplot2::scale_shape_manual(
      values = c("Named category" = 16, "Other" = 1)
    ) +
    ggplot2::labs(
      title = mean_title,
      x = NULL,
      y = "melEDI (lx)",
      colour = "Placement",
      shape = NULL
    ) +
    h04_figure_theme() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 0, hjust = 0.5),
      legend.position = "top"
    )

  ratios <- display |>
    dplyr::filter(
      .data$inferential_role == "NAMED_VERSUS_HOME"
    )
  ratio_plot <- ggplot2::ggplot(
    ratios,
    ggplot2::aes(
      x = .data$activity_axis,
      y = .data$ratio_to_home,
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
      linewidth = 0.7,
      position = positions
    ) +
    ggplot2::geom_point(size = 2.8, position = positions) +
    ggplot2::scale_y_log10(
      breaks = c(0.03, 0.1, 0.3, 1, 3, 10, 30),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::scale_colour_manual(
      values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
    ) +
    ggplot2::labs(
      title = ratio_title,
      x = NULL,
      y = "Ratio to At home",
      colour = "Placement"
    ) +
    h04_figure_theme() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 0, hjust = 0.5),
      legend.position = "none"
    )
  patchwork::wrap_plots(mean_plot, ratio_plot, ncol = 1, heights = c(1.15, 1)) +
    patchwork::plot_annotation(
      tag_levels = "A",
      caption = paste(
        "Points and bars are estimates and participant-cluster-robust 95% confidence intervals.",
        "\nSites receive equal weight on the fitted log-mean scale.",
        if (is.null(caption_extra)) "" else paste0("\n", caption_extra),
        "\n",
        "The melEDI transformation is display-only."
      ),
      theme = h04_figure_theme()
    )
}

h04_site_activity_figure <- function(data) {
  registry <- h04_reader_activity_registry()
  activity_labels <- stats::setNames(
    registry$reader_label,
    registry$activity_label
  )
  display <- data |>
    dplyr::filter(
      .data$reporting_status %in%
        c(
          "ESTIMABLE",
          "SUPPORT_NON_ESTIMABLE"
        )
    ) |>
    dplyr::mutate(
      activity = factor(
        .data$activity,
        levels = registry$activity_label
      ),
      placement = factor(.data$placement, levels = c("Near-eye", "Chest")),
      site_display_name = factor(
        .data$site_display_name,
        levels = rev(unique(
          .data$site_display_name[order(.data$site_display_order)]
        ))
      )
    )
  estimable <- display |>
    dplyr::filter(.data$reporting_status == "ESTIMABLE")
  significant <- estimable |>
    dplyr::filter(.data$site_deviation_p_adjusted < 0.05)
  not_significant <- estimable |>
    dplyr::filter(.data$site_deviation_p_adjusted >= 0.05)
  unsupported <- display |>
    dplyr::filter(.data$reporting_status == "SUPPORT_NON_ESTIMABLE")
  averages <- display |>
    dplyr::filter(is.finite(.data$category_standardized_mean_lx)) |>
    dplyr::distinct(
      .data$placement,
      .data$activity,
      .data$category_standardized_mean_lx
    )
  site_colours <- display |>
    dplyr::distinct(
      .data$site,
      .data$site_color_hex,
      .data$site_display_order
    ) |>
    dplyr::arrange(.data$site_display_order)
  ggplot2::ggplot(
    estimable,
    ggplot2::aes(
      x = .data$cell_mean_lx,
      y = .data$site_display_name,
      colour = .data$site
    )
  ) +
    ggplot2::geom_vline(
      data = averages,
      ggplot2::aes(
        xintercept = .data$category_standardized_mean_lx
      ),
      inherit.aes = FALSE,
      colour = "grey35",
      linetype = "dashed",
      linewidth = 0.65
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        xmin = .data$cell_conf_low_lx,
        xmax = .data$cell_conf_high_lx
      ),
      orientation = "y",
      width = 0,
      linewidth = 0.55
    ) +
    ggplot2::geom_point(
      data = not_significant,
      shape = 21,
      fill = "white",
      size = 2.7,
      stroke = 0.8
    ) +
    ggplot2::geom_point(
      data = significant,
      ggplot2::aes(fill = .data$site),
      shape = 21,
      size = 2.9,
      stroke = 0.8
    ) +
    ggplot2::geom_point(
      data = unsupported,
      ggplot2::aes(x = 0),
      shape = 4,
      size = 3.2,
      stroke = 1
    ) +
    ggplot2::scale_x_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 100, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::scale_colour_manual(
      values = stats::setNames(site_colours$site_color_hex, site_colours$site)
    ) +
    ggplot2::scale_fill_manual(
      values = stats::setNames(site_colours$site_color_hex, site_colours$site)
    ) +
    ggplot2::facet_grid(
      rows = ggplot2::vars(placement),
      cols = ggplot2::vars(activity),
      scales = "free_y",
      space = "free_y",
      labeller = ggplot2::labeller(
        activity = ggplot2::as_labeller(activity_labels)
      )
    ) +
    ggplot2::labs(
      title = "Support-gated site-specific activity-associated melEDI",
      subtitle = paste(
        "Dashed line: equal-site category mean; filled points:",
        "BH-adjusted site deviation p < 0.050"
      ),
      x = "melEDI (lx)",
      y = NULL,
      colour = "Site",
      fill = "Site",
      caption = paste0(
        "Estimates and dashed site-average values come from the five-category activity-by-site interaction model; Other is excluded.\n",
        "The dashed line is the geometric mean of site-cell expectations with every site weighted equally on the fitted log scale.\n",
        "Filled points pass the complete placement-specific BH adjustment; open points are other supported estimates; crosses are support non-estimable."
      )
    ) +
    h04_figure_theme() +
    ggplot2::theme(
      legend.position = "none",
      axis.text.y = ggplot2::element_text(size = 9),
      panel.spacing.x = grid::unit(0.8, "lines"),
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

h04_paired_figure <- function(data) {
  display <- data |>
    dplyr::filter(.data$inferential_role == "NAMED_VERSUS_HOME") |>
    dplyr::mutate(
      placement_id = dplyr::if_else(
        .data$placement == "Near-eye",
        "near",
        "chest"
      ),
      short_label = dplyr::recode(
        .data$activity_code,
        sleeping = "Sleeping",
        road_vehicle = "Travel",
        working_indoor = "Working",
        outdoors = "Outdoors"
      )
    ) |>
    dplyr::select(
      "activity_code", "short_label", "placement_id", "ratio_to_home",
      "ratio_conf_low", "ratio_conf_high"
    ) |>
    tidyr::pivot_wider(
      names_from = "placement_id",
      values_from = c("ratio_to_home", "ratio_conf_low", "ratio_conf_high"),
      names_glue = "{placement_id}_{.value}"
    ) |>
    dplyr::mutate(
      label_x = dplyr::case_when(
        .data$activity_code == "sleeping" ~ .data$near_ratio_to_home * 0.82,
        .data$activity_code == "outdoors" ~ .data$near_ratio_to_home * 0.82,
        TRUE ~ .data$near_ratio_to_home * 1.08
      ),
      label_y = dplyr::case_when(
        .data$activity_code == "sleeping" ~ .data$chest_ratio_to_home * 0.82,
        .data$activity_code == "outdoors" ~ .data$chest_ratio_to_home * 1.18,
        TRUE ~ .data$chest_ratio_to_home * 1.12
      )
    )
  ggplot2::ggplot(
    display,
    ggplot2::aes(
      x = .data$near_ratio_to_home,
      y = .data$chest_ratio_to_home,
      label = .data$short_label
    )
  ) +
    ggplot2::geom_abline(
      slope = 1,
      intercept = 0,
      colour = "grey50",
      linetype = "dashed"
    ) +
    ggplot2::geom_vline(xintercept = 1, colour = "grey70") +
    ggplot2::geom_hline(yintercept = 1, colour = "grey70") +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = .data$chest_ratio_conf_low,
        ymax = .data$chest_ratio_conf_high
      ),
      width = 0,
      linewidth = 0.6
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        xmin = .data$near_ratio_conf_low,
        xmax = .data$near_ratio_conf_high
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
    ggplot2::scale_x_log10(
      breaks = c(0.05, 0.1, 0.3, 1, 3, 10, 30),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::scale_y_log10(
      breaks = c(0.05, 0.1, 0.3, 1, 3, 10, 30),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = "Paired/common-sample placement comparison",
      x = "Near-eye ratio to At home",
      y = "Chest ratio to At home",
      caption = paste0(
        "Models are fitted separately to identical participant-hours.\n",
        "Horizontal and vertical bars are participant-cluster-robust 95% confidence intervals.\n",
        "The identity line is a concordance reference, not an equivalence test."
      )
    ) +
    h04_figure_theme()
}

h04_reader_diagnostic_figure <- function(
  residual_bins,
  residual_points,
  acf,
  zero_bins,
  title_prefix = "Primary-model",
  caption_text = NULL
) {
  placement_levels <- c("Near-eye", "Chest")
  residual_bins <- residual_bins |>
    dplyr::mutate(
      placement = factor(.data$placement, levels = placement_levels)
    )
  residual_points <- residual_points |>
    dplyr::mutate(
      placement = factor(.data$placement, levels = placement_levels)
    )
  acf <- acf |>
    dplyr::mutate(
      placement = factor(.data$placement, levels = placement_levels)
    )
  zero_bins <- zero_bins |>
    dplyr::mutate(
      placement = factor(.data$placement, levels = placement_levels)
    )

  residual_plot <- ggplot2::ggplot(
    residual_bins,
    ggplot2::aes(
      x = .data$fitted_mean_lx,
      y = .data$residual_mean,
      colour = .data$placement
    )
  ) +
    ggplot2::geom_hline(
      yintercept = 0,
      colour = "grey55",
      linetype = "dashed"
    ) +
    ggplot2::geom_point(
      data = residual_points,
      ggplot2::aes(
        x = .data$fitted_mean_lx,
        y = .data$pearson_residual,
        colour = .data$placement
      ),
      inherit.aes = FALSE,
      alpha = 0.10,
      size = 0.45
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = .data$residual_q25,
        ymax = .data$residual_q75,
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
      y = "Pearson residual"
    ) +
    h04_figure_theme()

  acf_plot <- ggplot2::ggplot(
    dplyr::filter(acf, .data$lag_hours > 0),
    ggplot2::aes(
      x = .data$lag_hours,
      y = .data$correlation,
      colour = .data$placement,
      group = .data$placement
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey55") +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::facet_wrap(ggplot2::vars(.data$placement)) +
    ggplot2::scale_x_continuous(breaks = 1:6) +
    ggplot2::scale_colour_manual(
      values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00"),
      guide = "none"
    ) +
    ggplot2::labs(
      title = "Boundary-aware residual autocorrelation",
      x = "Lag (hours)",
      y = "Pearson-residual correlation"
    ) +
    h04_figure_theme()

  zero_long <- zero_bins |>
    tidyr::pivot_longer(
      cols = c("observed_zero_fraction", "working_zero_fraction"),
      names_to = "series",
      values_to = "zero_fraction"
    ) |>
    dplyr::mutate(
      series = factor(
        .data$series,
        levels = c("observed_zero_fraction", "working_zero_fraction"),
        labels = c("Observed", "Working Tweedie")
      )
    )
  zero_plot <- ggplot2::ggplot(
    zero_long,
    ggplot2::aes(
      x = .data$fitted_mean_lx,
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
      x = "Mean fitted melEDI in decile (lx)",
      y = "Zero fraction",
      colour = NULL,
      linetype = NULL
    ) +
    h04_figure_theme() +
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
      caption = if (is.null(caption_text)) {
        paste0(
          title_prefix,
          " diagnostics aggregate concurrent activity memberships back to one contribution per original participant-hour.\n",
          "Participant-cluster covariance changes inferential uncertainty; it does not remove serial correlation or zero-mass mismatch."
        )
      } else {
        caption_text
      },
      theme = h04_figure_theme() +
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

h04_diagnostic_figure <- function(calibration, acf) {
  calibration <- calibration |>
    dplyr::mutate(
      placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
    )
  acf <- acf |>
    dplyr::mutate(
      placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
    )
  calibration_plot <- ggplot2::ggplot(
    calibration,
    ggplot2::aes(
      x = .data$fitted_mean_lx,
      y = .data$observed_mean_lx,
      colour = .data$placement
    )
  ) +
    ggplot2::geom_abline(
      intercept = 0,
      slope = 1,
      colour = "grey45",
      linetype = "dashed"
    ) +
    ggplot2::geom_point(size = 2.2) +
    ggplot2::scale_x_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 100, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
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
      title = "Weighted calibration by fitted-mean bin",
      x = "Fitted mean melEDI (lx)",
      y = "Observed weighted mean melEDI (lx)",
      colour = "Placement"
    ) +
    h04_figure_theme() +
    ggplot2::theme(legend.position = "top")

  acf_plot <- ggplot2::ggplot(
    dplyr::filter(acf, .data$lag_hours > 0),
    ggplot2::aes(
      x = .data$lag_hours,
      y = .data$correlation,
      fill = .data$placement
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey45") +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.75)) +
    ggplot2::scale_fill_manual(
      values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
    ) +
    ggplot2::scale_x_continuous(breaks = 1:6) +
    ggplot2::labs(
      title = "Unique-hour Pearson residual autocorrelation",
      x = "Lag within valid participant-day runs (hours)",
      y = "Correlation",
      fill = "Placement"
    ) +
    h04_figure_theme() +
    ggplot2::theme(legend.position = "none")
  patchwork::wrap_plots(calibration_plot, acf_plot, ncol = 2) +
    patchwork::plot_annotation(
      tag_levels = "A",
      caption = paste(
        "Calibration bins retain fractional activity weights; residual autocorrelation uses one aggregated row per participant-hour.",
        "\n",
        "Participant-clustered inference encompasses concurrent memberships and longitudinal dependence."
      ),
      theme = h04_figure_theme()
    )
}
