# Publication-oriented plots built only from exported descriptive source data.

theme_descriptive <- function(base_size = 9) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = "#E5E5E5", linewidth = 0.25),
      axis.title = ggplot2::element_text(face = "bold"),
      strip.text = ggplot2::element_text(face = "bold", colour = "black"),
      strip.background = ggplot2::element_rect(fill = "#F2F2F2", colour = NA),
      plot.title = ggplot2::element_text(face = "bold", size = base_size + 2),
      plot.subtitle = ggplot2::element_text(colour = "#333333"),
      plot.caption = ggplot2::element_text(colour = "#333333", hjust = 0),
      legend.position = "bottom",
      legend.box = "vertical"
    )
}

clock_x_scale <- function(include_end = TRUE) {
  breaks <- if (include_end) {
    c(0, 360, 720, 1080, 1440)
  } else {
    c(0, 360, 720, 1080)
  }
  labels <- if (include_end) {
    c("00:00", "06:00", "12:00", "18:00", "24:00")
  } else {
    c("00:00", "06:00", "12:00", "18:00")
  }
  ggplot2::scale_x_continuous(
    breaks = breaks,
    labels = labels,
    limits = c(0, 1440),
    expand = ggplot2::expansion(mult = c(0, 0))
  )
}

medi_y_scale <- function() {
  ggplot2::scale_y_continuous(
    trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
    breaks = c(0, 1, 10, 250, 1000, 10000, 100000),
    labels = scales::label_number(big.mark = ",", accuracy = 1),
    limits = c(0, 100000),
    expand = ggplot2::expansion(mult = c(0, 0.03))
  )
}

make_protocol_flow_plot <- function(protocol_flow) {
  nodes <- dplyr::filter(protocol_flow, .data$row_type == "node")
  edges <- dplyr::filter(protocol_flow, .data$row_type == "edge")
  fills <- c(
    not_applicable = "#F2F2F2", near_eye = "#CFE8F3", chest = "#F6E4B7",
    paired = "#DCE9D5"
  )
  ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = edges,
      ggplot2::aes(
        x = .data$x, y = .data$y, xend = .data$xend, yend = .data$yend
      ),
      linewidth = 0.5,
      colour = "#555555",
      arrow = grid::arrow(length = grid::unit(0.12, "in"), type = "closed")
    ) +
    ggplot2::geom_label(
      data = nodes,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$label, fill = .data$placement),
      size = 2.7,
      lineheight = 0.95,
      linewidth = 0.25,
      label.padding = grid::unit(0.12, "lines"),
      colour = "black"
    ) +
    ggplot2::scale_fill_manual(values = fills, guide = "none") +
    ggplot2::coord_cartesian(xlim = c(0.7, 4.3), ylim = c(0.35, 2.65), clip = "off") +
    ggplot2::labs(
      title = "A  Sample definition",
      subtitle = "Placements remain separate; exclusion of an all-zero day does not remove its participant."
    ) +
    ggplot2::theme_void(base_size = 9) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 11),
      plot.subtitle = ggplot2::element_text(size = 8, colour = "#333333")
    )
}

make_site_map_plot <- function(site_locations, world_map) {
  world_sf <- sf::st_sf(
    region = world_map$region,
    geometry = sf::st_as_sfc(world_map$wkt, crs = 4326)
  )
  palette <- descriptive_site_palette()
  ggplot2::ggplot() +
    ggplot2::geom_sf(
      data = world_sf,
      fill = "#F0F0F0",
      colour = "#B8B8B8",
      linewidth = 0.15
    ) +
    ggplot2::geom_segment(
      data = site_locations,
      ggplot2::aes(
        x = .data$longitude_deg, y = .data$latitude_deg,
        xend = .data$label_longitude, yend = .data$label_latitude
      ),
      colour = "#555555",
      linewidth = 0.25
    ) +
    ggplot2::geom_point(
      data = site_locations,
      ggplot2::aes(
        x = .data$longitude_deg, y = .data$latitude_deg, fill = .data$site
      ),
      shape = 21,
      size = 2.4,
      stroke = 0.45,
      colour = "black"
    ) +
    ggplot2::geom_label(
      data = site_locations,
      ggplot2::aes(
        x = .data$label_longitude, y = .data$label_latitude,
        label = .data$site
      ),
      size = 2.4,
      linewidth = 0.2,
      label.padding = grid::unit(0.08, "lines"),
      colour = "black",
      fill = "white"
    ) +
    ggplot2::scale_fill_manual(values = palette, guide = "none") +
    ggplot2::coord_sf(
      xlim = c(-100, 38), ylim = c(0, 66), expand = FALSE,
      default_crs = sf::st_crs(4326)
    ) +
    ggplot2::labs(title = "B  Study sites", x = NULL, y = NULL) +
    theme_descriptive(8) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank()
    )
}

make_collection_plot <- function(collection_counts) {
  collection_counts <- collection_counts |>
    dplyr::mutate(
      site = factor(.data$site, levels = rev(descriptive_site_order())),
      placement_label = factor(
        .data$placement_label,
        levels = c("Near-eye (primary)", "Chest (complementary)")
      )
    )
  ggplot2::ggplot(
    collection_counts,
    ggplot2::aes(
      x = .data$local_date, y = .data$site,
      size = .data$participant_days, colour = .data$photoperiod_hours
    )
  ) +
    ggplot2::geom_point(alpha = 0.8, stroke = 0) +
    ggplot2::facet_wrap(~placement_label, ncol = 1, scales = "free_x") +
    ggplot2::scale_colour_viridis_c(
      option = "C", end = 0.9, name = "Civil photoperiod (h)"
    ) +
    ggplot2::scale_size_continuous(
      range = c(0.8, 4.5), breaks = c(1, 3, 6), name = "Participant-days"
    ) +
    ggplot2::scale_x_date(date_breaks = "3 months", date_labels = "%b\n%Y") +
    ggplot2::labs(
      title = "C  Collection timing and photoperiod",
      x = "Local date", y = NULL
    ) +
    theme_descriptive(8) +
    ggplot2::theme(
      legend.position = "bottom",
      axis.text.x = ggplot2::element_text(size = 6.5)
    )
}

make_profile_plot <- function(
  profile,
  title = NULL,
  subtitle = NULL,
  show_legend = FALSE,
  include_end_label = TRUE
) {
  palette <- descriptive_site_palette()
  profile <- profile |>
    dplyr::mutate(
      site = factor(
        .data$site,
        levels = c("Overall", descriptive_site_order())
      )
    )
  ggplot2::ggplot(
    profile,
    ggplot2::aes(x = .data$clock_minute, group = .data$site)
  ) +
    ggplot2::geom_hline(
      yintercept = c(1, 10, 250),
      colour = "#696969",
      linetype = "dashed",
      linewidth = 0.35
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = .data$ci_lower_lx, ymax = .data$ci_upper_lx,
        fill = .data$site
      ),
      alpha = 0.23,
      colour = NA
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$median_lx, colour = .data$site),
      linewidth = 0.6,
      na.rm = TRUE
    ) +
    clock_x_scale(include_end = include_end_label) +
    medi_y_scale() +
    ggplot2::scale_fill_manual(
      values = c(Overall = "#4D4D4D", palette), guide = "none"
    ) +
    ggplot2::scale_colour_manual(
      values = c(Overall = "#000000", palette),
      guide = if (show_legend) "legend" else "none"
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Local wall-clock time",
      y = "melEDI (lx; symlog, base 10, threshold 1)",
      colour = "Site"
    ) +
    theme_descriptive(8)
}

make_context_band_plot <- function(state_source, title = NULL) {
  labels <- state_source |>
    dplyr::distinct(band_index, context_label) |>
    dplyr::arrange(.data$band_index)
  ggplot2::ggplot(state_source) +
    ggplot2::geom_rect(
      ggplot2::aes(
        xmin = .data$xmin, xmax = .data$xmax,
        ymin = .data$ymin, ymax = .data$ymax,
        fill = .data$fill_colour
      ),
      alpha = 1,
      colour = NA
    ) +
    ggplot2::scale_fill_identity() +
    clock_x_scale() +
    ggplot2::scale_y_continuous(
      breaks = labels$band_index,
      labels = labels$context_label,
      expand = ggplot2::expansion(mult = c(0.02, 0.02))
    ) +
    ggplot2::labs(
      title = title,
      x = "Local wall-clock time",
      y = NULL,
      caption = "Darker colour indicates a larger pooled minute fraction; every rectangle is opaque (alpha = 1)."
    ) +
    theme_descriptive(7) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 6.5),
      plot.caption = ggplot2::element_text(size = 6.5)
    )
}

make_overview_figure <- function(
  protocol_flow,
  site_locations,
  world_map,
  collection_counts,
  profile,
  state_source
) {
  profile_overall <- profile |>
    dplyr::filter(.data$placement == "near_eye", .data$site == "Overall")
  state_overall <- state_source |>
    dplyr::filter(.data$placement == "near_eye", .data$site == "Overall")
  p_flow <- make_protocol_flow_plot(protocol_flow)
  p_map <- make_site_map_plot(site_locations, world_map)
  p_collection <- make_collection_plot(collection_counts)
  p_profile <- make_profile_plot(
    profile_overall,
    title = "D  Main near-eye 24-hour profile",
    subtitle = "Participant-balanced median and exact pointwise 95% confidence interval"
  )
  p_state <- make_context_band_plot(
    state_overall,
    title = "Diary, non-wear, and civil-daylight context"
  )
  profile_stack <- patchwork::wrap_plots(
    p_profile, p_state, ncol = 1, heights = c(3.3, 1.35)
  )
  middle <- patchwork::wrap_plots(p_map, p_collection, ncol = 2)
  patchwork::wrap_plots(
    p_flow, middle, profile_stack,
    ncol = 1,
    heights = c(0.85, 1.2, 1.7)
  ) +
    patchwork::plot_annotation(
      title = "Nature Health descriptive overview",
      caption = paste(
        "Profiles use verified eligible one-minute values. Near-eye waking",
        "and bedside sleep-environment measurements form the planned 24-hour",
        "construct; the sleep portion is environmental, not ocular."
      ),
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold", size = 14),
        plot.caption = ggplot2::element_text(size = 8, hjust = 0)
      )
    )
}

make_site_profile_figure <- function(profile, placement) {
  data <- profile |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$site != "Overall"
    ) |>
    dplyr::mutate(
      site = factor(.data$site, levels = descriptive_site_order())
    )
  position_word <- if (placement == "near_eye") {
    "Main near-eye"
  } else {
    "Complementary chest"
  }
  make_profile_plot(
    data,
    title = paste0(position_word, " 24-hour profiles by site"),
    subtitle = paste(
      "Within each site and minute, days are summarized within participant",
      "before participants are weighted equally."
    ),
    include_end_label = FALSE
  ) +
    ggplot2::facet_wrap(~site, ncol = 3, drop = TRUE) +
    ggplot2::labs(
      caption = paste(
        "Band: exact pointwise 95% confidence interval for the participant",
        "median. Dashed guides mark 1, 10, and 250 lx melEDI."
      )
    ) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(size = 6.5),
      axis.text.y = ggplot2::element_text(size = 6.5),
      panel.spacing = grid::unit(0.12, "in")
    )
}

make_metric_distribution_figure <- function(metric_values, category) {
  data <- metric_values |>
    dplyr::filter(
      .data$placement == "near_eye",
      .data$manuscript_category == category,
      .data$finite
    ) |>
    dplyr::mutate(
      site = factor(.data$site, levels = rev(descriptive_site_order())),
      panel_label = paste0(
        .data$metric_label, "\n(", .data$display_unit, "; ",
        .data$analysis_unit, ")"
      )
    )
  title <- dplyr::recode(
    category,
    `level-based` = "Level-based near-eye metric distributions",
    `duration-based` = "Duration-based near-eye metric distributions",
    `exposure-history-based` = "Exposure-history near-eye metric distributions",
    `spectrum-based` = "Spectrum-based near-eye metric distributions",
    `dynamics-based` = "Dynamics-based near-eye metric distributions",
    .default = category
  )
  plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(x = .data$value, y = .data$site, fill = .data$site)
  ) +
    ggplot2::geom_violin(
      scale = "width", trim = TRUE, linewidth = 0.25,
      colour = "#4A4A4A", alpha = 0.72, na.rm = TRUE
    ) +
    ggplot2::geom_boxplot(
      width = 0.14, outlier.shape = NA, fill = "white",
      colour = "black", linewidth = 0.3, na.rm = TRUE
    ) +
    ggplot2::facet_wrap(~panel_label, scales = "free_x", ncol = 2) +
    ggplot2::scale_fill_manual(values = descriptive_site_palette(), guide = "none") +
    ggplot2::labs(
      title = title,
      subtitle = "Violin: full finite distribution; white box: median and middle 50%.",
      x = NULL, y = NULL,
      caption = "Sites are named on the axis, so interpretation does not rely on colour."
    ) +
    theme_descriptive(8) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 6.7),
      strip.text = ggplot2::element_text(size = 7.2)
    )
  if (category %in% c("level-based", "duration-based", "exposure-history-based")) {
    breaks <- switch(
      category,
      `duration-based` = c(0, 0.1, 1, 10, 24),
      `exposure-history-based` = c(0, 10, 100, 1000, 10000, 100000),
      c(0, 0.1, 1, 10, 100, 1000, 10000, 100000)
    )
    labels <- function(x) {
      vapply(x, function(value) {
        if (is.na(value)) return(NA_character_)
        if (value == 0) return("0")
        if (value < 1) return(trimws(formatC(value, format = "fg", digits = 2)))
        if (value < 1000) {
          return(trimws(formatC(value, format = "fg", digits = 3)))
        }
        if (value < 1000000) {
          return(paste0(
            trimws(formatC(value / 1000, format = "fg", digits = 3)), "K"
          ))
        }
        trimws(formatC(value, format = "e", digits = 1))
      }, character(1))
    }
    plot <- plot + ggplot2::scale_x_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = breaks,
      labels = labels
    )
  }
  plot
}

make_timing_distribution_figure <- function(metric_values) {
  data <- metric_values |>
    dplyr::filter(
      .data$placement == "near_eye",
      .data$manuscript_category == "timing-based",
      .data$finite
    ) |>
    dplyr::mutate(
      panel_label = paste0(.data$metric_label, "\n(participant-day)")
    )
  ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data$value, y = .data$timing_plot_y,
      colour = .data$site
    )
  ) +
    ggplot2::geom_point(alpha = 0.42, size = 0.55, stroke = 0) +
    ggplot2::facet_wrap(~panel_label, ncol = 2) +
    clock_x_scale(include_end = FALSE) +
    ggplot2::scale_y_continuous(
      breaks = seq_along(descriptive_site_order()),
      labels = descriptive_site_order(),
      limits = c(0.45, 9.55),
      expand = ggplot2::expansion(mult = c(0, 0))
    ) +
    ggplot2::scale_colour_manual(values = descriptive_site_palette(), guide = "none") +
    ggplot2::labs(
      title = "Clock-time near-eye metric distributions",
      subtitle = "Every point is one finite participant-day observation; deterministic vertical offsets reduce overlap.",
      x = "Local wall-clock time (axis wraps at midnight)", y = NULL,
      caption = "No linear boxplot is used because clock time is circular."
    ) +
    theme_descriptive(8) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(size = 6.5),
      axis.text.y = ggplot2::element_text(size = 6.7),
      strip.text = ggplot2::element_text(size = 7.2)
    )
}

make_other_metric_distribution_figure <- function(metric_values) {
  data <- metric_values |>
    dplyr::filter(
      .data$placement == "near_eye",
      .data$manuscript_category %in% c("spectrum-based", "dynamics-based"),
      .data$finite
    ) |>
    dplyr::mutate(
      site = factor(.data$site, levels = rev(descriptive_site_order())),
      panel_label = paste0(
        .data$metric_label, "\n(", .data$display_unit, "; ",
        .data$analysis_unit, ")"
      )
    )
  ggplot2::ggplot(
    data,
    ggplot2::aes(x = .data$value, y = .data$site, fill = .data$site)
  ) +
    ggplot2::geom_violin(
      scale = "width", trim = TRUE, linewidth = 0.25,
      colour = "#4A4A4A", alpha = 0.72, na.rm = TRUE
    ) +
    ggplot2::geom_boxplot(
      width = 0.14, outlier.shape = NA, fill = "white",
      colour = "black", linewidth = 0.3, na.rm = TRUE
    ) +
    ggplot2::facet_wrap(~panel_label, scales = "free_x", ncol = 2) +
    ggplot2::scale_fill_manual(values = descriptive_site_palette(), guide = "none") +
    ggplot2::labs(
      title = "Spectrum and dynamics distributions",
      subtitle = "Each panel states whether an observation is a participant-day or participant.",
      x = NULL, y = NULL,
      caption = "Sites are named on the axis; panels use independent numeric scales."
    ) +
    theme_descriptive(8) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 6.7),
      strip.text = ggplot2::element_text(size = 7.2)
    )
}

format_annotation_value <- function(value, unit) {
  if (identical(unit, "clock time")) {
    return(format_clock_minute(value))
  }
  digits <- if (unit %in% c("lx", "lx·h")) 4L else 3L
  paste(format_number_compact(value, digits), unit)
}

make_time_series_to_metrics_figure <- function(series, annotations) {
  daylight <- dplyr::distinct(
    series,
    .data$civil_dawn_wall_minute,
    .data$civil_dusk_wall_minute
  )
  timing_lines <- annotations |>
    dplyr::filter(
      .data$metric_id %in% c(
        "first_timing_above_250", "last_timing_above_250",
        "m10_midpoint", "l10_midpoint"
      ),
      is.finite(.data$value)
    ) |>
    dplyr::mutate(
      timing_type = dplyr::case_when(
        .data$metric_id == "m10_midpoint" ~ "Brightest 10 h midpoint",
        .data$metric_id == "l10_midpoint" ~ "Darkest 10 h midpoint",
        TRUE ~ "First/last above 250 lx"
      )
    )
  p_series <- ggplot2::ggplot(
    series,
    ggplot2::aes(x = .data$clock_minute, y = .data$melEDI_lx)
  ) +
    ggplot2::geom_rect(
      data = daylight,
      ggplot2::aes(
        xmin = .data$civil_dawn_wall_minute,
        xmax = .data$civil_dusk_wall_minute,
        ymin = 0,
        ymax = 100000
      ),
      inherit.aes = FALSE,
      fill = "#F0C808",
      alpha = 0.13
    ) +
    ggplot2::geom_hline(
      yintercept = c(1, 10, 250),
      linetype = "dashed",
      colour = "#555555",
      linewidth = 0.35
    ) +
    ggplot2::geom_line(linewidth = 0.42, colour = "#0072B2", na.rm = TRUE) +
    ggplot2::geom_vline(
      data = timing_lines,
      ggplot2::aes(xintercept = .data$value, colour = .data$timing_type),
      linewidth = 0.4,
      linetype = "longdash"
    ) +
    ggplot2::scale_colour_manual(
      values = c(
        "Brightest 10 h midpoint" = "#D55E00",
        "Darkest 10 h midpoint" = "#009E73",
        "First/last above 250 lx" = "#6B6B6B"
      )
    ) +
    clock_x_scale() +
    medi_y_scale() +
    ggplot2::labs(
      title = paste0(
        "From one-minute time series to verified metrics: ",
        series$participant[[1L]], " on ", series$local_date[[1L]]
      ),
      subtitle = "Yellow shading marks verified civil daylight; horizontal guides mark 1, 10, and 250 lx melEDI.",
      x = NULL,
      y = "melEDI (lx; symlog, base 10, threshold 1)",
      colour = "Verified timing annotation"
    ) +
    theme_descriptive(8)
  band_contract <- data.frame(
    band = c("Wake", "Pre-sleep", "Sleep", "Unavailable", "Declared non-wear"),
    band_index = c(5, 4, 3, 2, 1),
    colour = c("#0072B2", "#E69F00", "#6B6B6B", "#CC79A7", "#000000"),
    stringsAsFactors = FALSE
  )
  band_data <- dplyr::bind_rows(
    series |>
      dplyr::transmute(
        clock_minute = .data$clock_minute,
        band = dplyr::case_when(
          .data$brown_period == "Waking daytime" ~ "Wake",
          .data$brown_period == "Three hours before sleep" ~ "Pre-sleep",
          .data$brown_period == "Sleep" ~ "Sleep",
          TRUE ~ NA_character_
        ),
        active = !is.na(.data$band)
      ),
    series |>
      dplyr::transmute(
        clock_minute = .data$clock_minute,
        band = "Unavailable",
        active = .data$availability != "Prepared melEDI available"
      ),
    series |>
      dplyr::transmute(
        clock_minute = .data$clock_minute,
        band = "Declared non-wear",
        active = .data$declared_nonwear
      )
  ) |>
    dplyr::filter(!is.na(.data$band)) |>
    dplyr::left_join(band_contract, by = "band") |>
    dplyr::mutate(
      xmin = .data$clock_minute - 0.5,
      xmax = .data$clock_minute + 0.5,
      ymin = .data$band_index - 0.42,
      ymax = .data$band_index + 0.42,
      fill_colour = ifelse(.data$active, .data$colour, "#FFFFFF")
    )
  p_band <- ggplot2::ggplot(band_data) +
    ggplot2::geom_rect(
      ggplot2::aes(
        xmin = .data$xmin, xmax = .data$xmax,
        ymin = .data$ymin, ymax = .data$ymax,
        fill = .data$fill_colour
      ),
      alpha = 1,
      colour = NA
    ) +
    ggplot2::scale_fill_identity() +
    clock_x_scale() +
    ggplot2::scale_y_continuous(
      breaks = band_contract$band_index,
      labels = band_contract$band,
      expand = ggplot2::expansion(mult = c(0.02, 0.02))
    ) +
    ggplot2::labs(x = "Local wall-clock time", y = NULL) +
    theme_descriptive(7) +
    ggplot2::theme(panel.grid = ggplot2::element_blank())
  annotation_data <- annotations |>
    dplyr::mutate(
      display_value = mapply(
        format_annotation_value,
        .data$value,
        .data$display_unit,
        USE.NAMES = FALSE
      ),
      row = rev(seq_len(dplyr::n()))
    )
  p_annotations <- ggplot2::ggplot(annotation_data) +
    ggplot2::geom_text(
      ggplot2::aes(x = 0, y = .data$row, label = .data$manuscript_name),
      hjust = 0,
      size = 2.55,
      colour = "#222222"
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = 1, y = .data$row, label = .data$display_value),
      hjust = 1,
      size = 2.55,
      fontface = "bold",
      colour = "#222222"
    ) +
    ggplot2::coord_cartesian(xlim = c(0, 1), clip = "off") +
    ggplot2::labs(
      title = "Joined values from the verified participant-day metric artifact",
      subtitle = "The explanatory figure does not recalculate these metrics."
    ) +
    ggplot2::theme_void(base_size = 8) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 9),
      plot.subtitle = ggplot2::element_text(size = 7.5, colour = "#333333"),
      plot.margin = ggplot2::margin(5.5, 18, 5.5, 18)
    )
  patchwork::wrap_plots(
    p_series, p_band, p_annotations,
    ncol = 1,
    heights = c(3.3, 1.2, 2.3)
  ) +
    patchwork::plot_annotation(
      caption = paste(
        "The sleep interval is a bedside sleep-environment measurement and",
        "must not be interpreted as ocular exposure."
      ),
      theme = ggplot2::theme(
        plot.caption = ggplot2::element_text(size = 8, hjust = 0)
      )
    )
}

make_latitude_photoperiod_figure <- function(latitude_source) {
  summary <- latitude_source |>
    dplyr::mutate(
      site = factor(as.character(.data$site), levels = descriptive_site_order())
    ) |>
    dplyr::group_by(.data$site, .data$absolute_latitude_deg) |>
    dplyr::summarise(
      q1 = finite_quantile(.data$photoperiod_hours, 0.25),
      median = finite_median(.data$photoperiod_hours),
      q3 = finite_quantile(.data$photoperiod_hours, 0.75),
      participant_days = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::mutate(reader_site = display_site_label(.data$site))
  ggplot2::ggplot(
    latitude_source,
    ggplot2::aes(
      x = .data$photoperiod_hours,
      y = .data$plot_latitude_deg,
      colour = .data$site
    )
  ) +
    ggplot2::geom_point(alpha = 0.22, size = 0.85, stroke = 0) +
    ggplot2::geom_segment(
      data = summary,
      ggplot2::aes(
        x = .data$q1, xend = .data$q3,
        y = .data$absolute_latitude_deg,
        yend = .data$absolute_latitude_deg,
        colour = .data$site
      ),
      linewidth = 2.4,
      alpha = 0.85,
      lineend = "round"
    ) +
    ggplot2::geom_point(
      data = summary,
      ggplot2::aes(
        x = .data$median, y = .data$absolute_latitude_deg,
        fill = .data$site
      ),
      shape = 21,
      size = 2.5,
      stroke = 0.5,
      colour = "black"
    ) +
    ggplot2::geom_text(
      data = summary,
      ggplot2::aes(
        x = .data$median,
        y = .data$absolute_latitude_deg,
        label = .data$reader_site
      ),
      inherit.aes = FALSE,
      nudge_y = 0.7,
      size = 2.4,
      colour = "black",
      fontface = "bold",
      show.legend = FALSE
    ) +
    ggplot2::scale_colour_manual(values = descriptive_site_palette()) +
    ggplot2::scale_fill_manual(values = descriptive_site_palette()) +
    ggplot2::labs(
      title = "Supplemental diagnostic: latitude and observed photoperiod",
      subtitle = "Points are main near-eye participant-days; thick bars are site middle 50% and circles are site medians.",
      x = "Verified civil photoperiod (hours)",
      y = "Absolute latitude (degrees)",
      colour = "Site", fill = "Site",
      caption = paste(
        "Small deterministic vertical offsets reduce overlap. No theoretical",
        "photoperiod surface was recalculated."
      )
    ) +
    theme_descriptive(9) +
    ggplot2::guides(fill = "none")
}
