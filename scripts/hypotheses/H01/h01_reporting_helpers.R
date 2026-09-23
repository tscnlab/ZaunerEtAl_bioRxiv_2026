read_required <- function(relative_path) {
  path <- file.path(root, relative_path)
  if (!file.exists(path)) {
    stop("Missing required H01 reporting input: ", relative_path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

format_family <- function(response_family, response_transform) {
  dplyr::case_when(
    response_family == "tweedie_log" ~ "Tweedie with log link",
    response_transform == "log10_offset_0.1" ~
      "Gaussian after log10(value + 0.1)",
    response_transform == "logit" ~ "Gaussian after logit transformation",
    response_transform == "clock_hours_midnight_after_16" ~
      "Gaussian on the linear clock scale (strict after-16:00 cut)",
    response_transform == "clock_hours" ~
      "Gaussian on the linear clock scale",
    TRUE ~ "Gaussian on the identity scale"
  )
}

unwrap_density_clock <- function(value, metric_id) {
  centers <- c(
    m10_midpoint = 840,
    l10_midpoint = 180,
    first_timing_above_250 = 540,
    last_timing_above_250 = 1080,
    mean_timing_above_250 = 810
  )
  center <- unname(centers[[metric_id]])
  if (is.null(center) || !is.finite(center)) {
    stop("No density-display clock centre for ", metric_id, call. = FALSE)
  }
  (value - center + 720) %% 1440 - 720 + center
}

make_metric_density_plot <- function(metric_id, scaling) {
  density_data <- descriptive_metric_values |>
    filter(
      .data$placement == "near_eye",
      .data$metric_id == .env$metric_id,
      .data$finite,
      is.finite(.data$value)
    ) |>
    transmute(
      site = factor(.data$site, levels = rev(site_registry$site)),
      display_value = .data$value
    )
  if (
    nrow(density_data) == 0L ||
      anyNA(density_data$site) ||
      dplyr::n_distinct(density_data$site) != nrow(site_registry)
  ) {
    stop("Incomplete density-display data for ", metric_id, call. = FALSE)
  }
  if (identical(scaling, "Circular clock")) {
    density_data$display_value <- unwrap_density_clock(
      density_data$display_value,
      metric_id
    )
  } else if (identical(scaling, "Symlog")) {
    density_data$display_value <- LightLogR::symlog_trans(
      base = 10,
      thr = 1,
      scale = 1
    )$transform(density_data$display_value)
  }

  site_palette <- stats::setNames(
    site_registry$color_hex,
    site_registry$site
  )
  site_labels <- stats::setNames(
    site_registry$display_name,
    site_registry$site
  )
  ggplot(
    density_data,
    aes(
      x = .data$display_value,
      y = .data$site,
      fill = .data$site,
      colour = .data$site
    )
  ) +
    ggridges::geom_density_ridges(
      alpha = 0.42,
      linewidth = 0.42,
      scale = 0.82,
      rel_min_height = 0.008,
      show.legend = FALSE
    ) +
    scale_fill_manual(values = site_palette, drop = FALSE) +
    scale_colour_manual(values = site_palette, drop = FALSE) +
    scale_y_discrete(labels = site_labels, drop = FALSE) +
    scale_x_continuous(expand = expansion(mult = c(0.025, 0.025))) +
    labs(x = NULL, y = NULL) +
    ggridges::theme_ridges(font_size = 9, grid = FALSE) +
    theme(
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      axis.text.y = element_text(size = 7.2, lineheight = 0.9),
      panel.grid = element_blank(),
      plot.margin = margin(2, 2, 2, 2)
    )
}

make_contrast_scale_panel <- function(data, scale_group, show_legend) {
  data <- data |>
    filter(.data$scale_group == .env$scale_group)
  facet_levels <- data |>
    distinct(.data$metric_order, .data$metric_facet_label) |>
    arrange(.data$metric_order) |>
    pull(.data$metric_facet_label)
  site_panel_levels <- data |>
    distinct(.data$metric_order, .data$display_order, .data$site_panel_key) |>
    arrange(.data$metric_order, desc(.data$display_order)) |>
    pull(.data$site_panel_key)
  site_panel_labels <- data |>
    distinct(.data$site_panel_key, .data$site_axis_label) |>
    tibble::deframe()
  panel_limits <- data |>
    distinct(
      .data$metric_order,
      .data$metric_facet_label,
      .data$display_x_min,
      .data$display_x_max
    ) |>
    pivot_longer(
      cols = c("display_x_min", "display_x_max"),
      names_to = "limit_name",
      values_to = "display_limit"
    )
  data <- data |>
    mutate(
      site_panel_key = factor(.data$site_panel_key, levels = site_panel_levels),
      metric_facet_label = factor(
        .data$metric_facet_label,
        levels = facet_levels
      ),
      support_display = factor(
        .data$support_display,
        levels = c("Adjusted p < 0.050", "Adjusted p ≥ 0.050")
      )
    )
  panel_limits <- panel_limits |>
    mutate(
      metric_facet_label = factor(
        .data$metric_facet_label,
        levels = facet_levels
      )
    )
  nulls <- data |>
    distinct(.data$metric_facet_label, .data$null_value)
  ggplot(
    data,
    aes(
      x = .data$estimate_practical,
      y = .data$site_panel_key,
      colour = .data$display_name
    )
  ) +
    geom_blank(
      data = panel_limits,
      aes(x = .data$display_limit),
      inherit.aes = FALSE
    ) +
    geom_vline(
      data = nulls,
      aes(xintercept = .data$null_value),
      inherit.aes = FALSE,
      colour = "#555555",
      linetype = 2,
      linewidth = 0.35
    ) +
    geom_errorbar(
      aes(
        xmin = .data$conf_low_practical,
        xmax = .data$conf_high_practical,
        linewidth = .data$support_display
      ),
      width = 0,
      orientation = "y"
    ) +
    geom_point(
      aes(
        shape = .data$support_display,
        fill = .data$display_name
      ),
      size = 2.7,
      stroke = 0.7
    ) +
    facet_wrap(vars(.data$metric_facet_label), scales = "free", ncol = 2) +
    scale_x_continuous(expand = expansion(mult = c(0.04, 0.04))) +
    scale_y_discrete(labels = site_panel_labels) +
    scale_colour_manual(values = site_colors, drop = FALSE, guide = "none") +
    scale_fill_manual(values = site_colors, drop = FALSE, guide = "none") +
    scale_shape_manual(
      name = "Within-metric contrast",
      values = c(
        "Adjusted p < 0.050" = 21,
        "Adjusted p ≥ 0.050" = 1
      )
    ) +
    scale_linewidth_manual(
      values = c(
        "Adjusted p < 0.050" = 0.9,
        "Adjusted p ≥ 0.050" = 0.38
      ),
      guide = "none"
    ) +
    labs(
      title = paste0(
        if (scale_group == "Ratios") "A" else "B",
        ". ", scale_group
      ),
      x = if (
        scale_group == "Ratios"
      ) {
        "Ratio versus the equally weighted site mean"
      } else {
        "Difference versus the equally weighted site mean"
      },
      y = NULL
    ) +
    theme_minimal(base_size = 11.5) +
    theme(
      panel.grid.minor = element_blank(),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 11),
      strip.text = element_text(face = "bold", size = 10.5),
      plot.title = element_text(face = "bold", size = 13, hjust = 0),
      plot.title.position = "plot",
      legend.position = if (show_legend) "bottom" else "none",
      legend.title = element_text(size = 10),
      legend.text = element_text(size = 10)
    ) +
    guides(
      shape = guide_legend(
        override.aes = list(
          colour = "#444444",
          fill = c("#444444", "white"),
          size = 2.7,
          linewidth = c(0.9, 0.38)
        )
      )
    )
}

make_contrast_plot <- function(data, placement_name) {
  selected <- data |>
    filter(.data$placement_label == .env$placement_name)
  metric_counts <- selected |>
    distinct(.data$scale_group, .data$metric_id) |>
    count(.data$scale_group, name = "metrics")
  ratios <- make_contrast_scale_panel(selected, "Ratios", show_legend = FALSE)
  differences <- make_contrast_scale_panel(
    selected,
    "Differences",
    show_legend = TRUE
  )
  ratio_rows <- ceiling(
    metric_counts$metrics[metric_counts$scale_group == "Ratios"] / 2
  )
  difference_rows <- ceiling(
    metric_counts$metrics[metric_counts$scale_group == "Differences"] / 2
  )
  cowplot::plot_grid(
    ratios,
    differences,
    ncol = 1,
    align = "v",
    axis = "lr",
    rel_heights = c(ratio_rows + 0.45, difference_rows + 0.80)
  )
}

make_photoperiod_plot <- function(data, selected_placement) {
  data <- data |>
    filter(.data$placement == .env$selected_placement) |>
    mutate(site = factor(.data$site, levels = site_registry$site))
  present_sites <- site_registry$site[site_registry$site %in% unique(as.character(data$site))]
  colors <- stats::setNames(site_registry$color_hex, site_registry$site)
  x_limits <- range(
    c(
      photoperiod_bounds$minimum_possible_photoperiod_hours,
      photoperiod_bounds$maximum_possible_photoperiod_hours
    ),
    na.rm = TRUE
  )
  ggplot() +
    geom_ribbon(
      data = photoperiod_bounds,
      aes(
        y = .data$absolute_latitude_deg,
        xmin = 0,
        xmax = .data$minimum_possible_photoperiod_hours
      ),
      orientation = "y",
      fill = "black"
    ) +
    geom_ribbon(
      data = photoperiod_bounds,
      aes(
        y = .data$absolute_latitude_deg,
        xmin = .data$maximum_possible_photoperiod_hours,
        xmax = 24
      ),
      orientation = "y",
      fill = "black"
    ) +
    geom_point(
      data = data,
      aes(
        x = .data$photoperiod_hours,
        y = .data$plot_latitude_deg,
        colour = .data$site
      ),
      shape = 16,
      size = 1.05,
      alpha = 0.38
    ) +
    ggridges::geom_density_ridges(
      data = data,
      aes(
        x = .data$photoperiod_hours,
        y = .data$absolute_latitude_deg,
        fill = .data$site,
        colour = .data$site,
        group = .data$site
      ),
      scale = 2,
      position = position_nudge(y = 1),
      bandwidth = 0.15,
      alpha = 0.74,
      linewidth = 0.45,
      rel_min_height = 0.01,
      show.legend = TRUE,
      key_glyph = "rect"
    ) +
    annotate(
      "text",
      y = 3,
      x = 15.2,
      label = "possible photoperiods",
      colour = "white",
      hjust = 0,
      size = 3.8
    ) +
    annotate(
      "curve",
      y = 3,
      x = 15,
      xend = 13.3,
      yend = 5.1,
      curvature = -0.1,
      arrow = grid::arrow(
        type = "closed",
        length = grid::unit(0.2, "cm")
      ),
      colour = "white",
      linewidth = 0.55
    ) +
    scale_colour_manual(
      values = colors,
      breaks = present_sites,
      labels = site_registry$display_name[match(present_sites, site_registry$site)],
      name = "Site"
    ) +
    scale_fill_manual(
      values = colors,
      breaks = present_sites,
      labels = site_registry$display_name[match(present_sites, site_registry$site)],
      name = "Site"
    ) +
    guides(
      colour = "none",
      fill = guide_legend(override.aes = list(alpha = 1, colour = NA))
    ) +
    coord_cartesian(xlim = x_limits, ylim = c(0, 63), expand = FALSE) +
    labs(x = "Photoperiod (hr)", y = "Absolute latitude (°)") +
    cowplot::theme_cowplot(font_size = 10) +
    theme(
      legend.position = "inside",
      legend.position.inside = c(0.65, 0.40),
      legend.justification = c(0.5, 0.5),
      legend.background = element_rect(fill = "transparent", colour = NA),
      legend.key = element_rect(fill = "transparent", colour = NA),
      legend.title = element_blank(),
      legend.text = element_text(colour = "white", size = 8),
      axis.text = element_text(colour = "white"),
      axis.title = element_text(colour = "white"),
      axis.ticks = element_line(colour = "white"),
      axis.line = element_line(colour = "white"),
      plot.background = element_rect(fill = "black", colour = NA),
      panel.background = element_rect(fill = "black", colour = NA),
      plot.margin = margin(5.5, 5.5, 5.5, 5.5)
    )
}

make_paired_placement_panel <- function(data, scale_name) {
  panel_data <- data |>
    filter(.data$effect_scale == scale_name)
  axis_range <- range(
    c(
      panel_data$near_estimate_practical,
      panel_data$chest_estimate_practical,
      panel_data$null_value
    ),
    na.rm = TRUE
  )
  padding <- max(diff(axis_range) * 0.12, 0.02)
  axis_limits <- axis_range + c(-padding, padding)
  ggplot(
    panel_data,
    aes(
      x = .data$near_estimate_practical,
      y = .data$chest_estimate_practical
    )
  ) +
    geom_abline(
      intercept = 0,
      slope = 1,
      colour = "#555555",
      linewidth = 0.55,
      linetype = 2
    ) +
    geom_vline(
      xintercept = unique(panel_data$null_value),
      colour = "#111111",
      linewidth = 0.45,
      linetype = 3
    ) +
    geom_hline(
      yintercept = unique(panel_data$null_value),
      colour = "#111111",
      linewidth = 0.45,
      linetype = 3
    ) +
    geom_point(
      aes(colour = .data$predictor, shape = .data$predictor),
      size = 2.1
    ) +
    ggrepel::geom_text_repel(
      aes(label = .data$point_label, colour = .data$predictor),
      size = 3.1,
      seed = 20260801,
      min.segment.length = 0,
      box.padding = 0.55,
      point.padding = 0.32,
      force = 8,
      force_pull = 0.05,
      max.iter = 100000,
      max.time = 10,
      max.overlaps = Inf,
      show.legend = FALSE
    ) +
    scale_colour_manual(
      values = c(Photoperiod = "#117733", `Latitude per 10°` = "#332288")
    ) +
    scale_shape_manual(
      values = c(Photoperiod = 16, `Latitude per 10°` = 17)
    ) +
    coord_equal(xlim = axis_limits, ylim = axis_limits, expand = TRUE) +
    labs(
      title = scale_name,
      x = "Near-eye estimate",
      y = "Chest estimate",
      colour = NULL,
      shape = NULL
    ) +
    theme_minimal(base_size = 10.5) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold"),
      legend.position = "bottom"
    )
}
