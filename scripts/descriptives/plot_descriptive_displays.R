# Descriptive figures for the manuscript and analysis webpage.
# Plot functions consume exported CSV source data only. The original panel
# arrangements and themes are retained wherever they do not conflict with the
# verified data and measurement rules.

display_double_clock_scale <- function(compact = FALSE) {
  breaks <- if (compact) {
    c(0, 720, 1440, 2160, 2880)
  } else {
    c(0, 360, 720, 1080, 1440, 1800, 2160, 2520, 2880)
  }
  labels <- if (compact) {
    c("00", "12", "00", "12", "24")
  } else {
    c(
      "00:00",
      "06:00",
      "12:00",
      "18:00",
      "00:00",
      "06:00",
      "12:00",
      "18:00",
      "24:00"
    )
  }
  ggplot2::scale_x_continuous(
    breaks = breaks,
    labels = labels,
    limits = c(0, 2880),
    expand = ggplot2::expansion(mult = c(0, 0))
  )
}

display_profile_y_scale <- function(
  include_context_baseline = FALSE,
  context_lower = -0.35,
  upper = 100000
) {
  lower <- if (include_context_baseline) context_lower else 0
  breaks <- c(0, 1, 10, 250, 10000, 100000)
  ggplot2::scale_y_continuous(
    trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
    breaks = breaks[breaks <= upper],
    labels = scales::label_number(big.mark = " ", accuracy = 1),
    limits = c(lower, upper),
    expand = ggplot2::expansion(mult = c(0, 0.015))
  )
}

display_recommendation_bracket <- function(
  compact = FALSE,
  text_size = if (compact) 7 else 9,
  label_hjust = rep(0.5, 3),
  line_width = if (compact) 0.16 else 0.28
) {
  stopifnot(length(label_hjust) == 3L)
  # Center each vertical label in its own recommendation interval. On the
  # threshold-1 symlog scale this places sleep at 0.5 lx and pre-sleep at the
  # logarithmic midpoint between 1 and 10 lx (about 3.2 lx).
  context_names <- c("sleep", "pre-sleep", "daytime")
  legendry::primitive_bracket(
    key = legendry::key_range_manual(
      start = c(0, 1.0001, 250),
      end = c(1, 10, Inf),
      name = context_names,
      hjust = label_hjust
    ),
    bracket = "square",
    theme = ggplot2::theme(
      legend.text = ggplot2::element_text(
        angle = 90,
        hjust = 0.5,
        size = text_size
      ),
      axis.text.y.left = ggplot2::element_text(
        angle = 90,
        hjust = 0.5,
        size = text_size
      ),
      legendry.bracket = ggplot2::element_line(linewidth = line_width)
    )
  )
}

display_time_series_y_scale <- function() {
  ggplot2::scale_y_continuous(
    trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
    breaks = c(0, 10, 250, 10000),
    labels = scales::label_number(big.mark = " ", accuracy = 1),
    limits = c(0, 100000),
    expand = ggplot2::expansion(mult = c(0, 0.02))
  )
}

duplicate_clock_day <- function(data, x = "clock_minute") {
  first <- data
  second <- data
  second[[x]] <- second[[x]] + 1440
  dplyr::bind_rows(first, second)
}

blend_with_black <- function(colour, fraction) {
  fraction <- pmax(0, pmin(1, fraction))
  if (length(colour) == 1L) colour <- rep(colour, length(fraction))
  mapply(
    function(single_colour, weight) {
      rgb <- grDevices::col2rgb(single_colour) / 255
      grDevices::rgb(
        rgb[[1L]] * weight,
        rgb[[2L]] * weight,
        rgb[[3L]] * weight
      )
    },
    colour,
    fraction,
    USE.NAMES = FALSE
  )
}

make_protocol_display_plot <- function(protocol_asset_path) {
  if (!file.exists(protocol_asset_path)) {
    stop("Protocol image is unavailable: ", protocol_asset_path, call. = FALSE)
  }
  cowplot::ggdraw() + cowplot::draw_image(protocol_asset_path)
}

format_coordinate_label <- function(latitude, longitude) {
  sprintf(
    "%.1f°%s, %.1f°%s",
    abs(latitude),
    ifelse(latitude >= 0, "N", "S"),
    abs(longitude),
    ifelse(longitude >= 0, "E", "W")
  )
}

make_site_map_display_plot <- function(site_locations, world_map) {
  world_sf <- sf::st_sf(
    region = world_map$region,
    geometry = sf::st_as_sfc(world_map$wkt, crs = 4326)
  )
  locations <- site_locations |>
    dplyr::mutate(
      reader_site = display_site_label(.data$site),
      label_text_colour = ifelse(.data$site == "IZTECH", "white", "black"),
      label = paste0(
        .data$reader_site,
        " ; ",
        .data$country,
        ", ",
        format_coordinate_label(.data$latitude_deg, .data$longitude_deg)
      )
    )
  # -127.2 degrees is the measured left edge of the right-aligned Dortmund
  # label at the fixed Figure 1 geometry; Delft and Madrid share that edge.
  label_layout <- data.frame(
    site = descriptive_site_order(),
    label_longitude = c(
      12.9,
      -127.2,
      0,
      20.6,
      20.6,
      -127.2,
      26.6,
      -84.1,
      -1.6
    ),
    label_latitude = c(77, 52, 65, 60, 48, 40.4, 30, 19, -2),
    label_hjust = c(0.5, 0, 1, 0, 0, 0, 0.5, 0.5, 0.5),
    stringsAsFactors = FALSE
  )
  connection_layout <- data.frame(
    site = c("BAUA", "MPI", "TUM"),
    connection_longitude = c(0, 20.6, 20.6),
    connection_latitude = c(62, 60, 48),
    stringsAsFactors = FALSE
  )
  locations <- locations |>
    dplyr::select(
      -dplyr::any_of(c(
        "label_longitude",
        "label_latitude",
        "label_hjust"
      ))
    ) |>
    dplyr::left_join(label_layout, by = "site")
  country_colours <- locations |>
    dplyr::group_by(.data$country) |>
    dplyr::summarise(
      colour = unname(descriptive_site_palette()[dplyr::first(.data$site)]),
      .groups = "drop"
    )
  world_sf$fill_key <- ifelse(
    world_sf$region %in% country_colours$country,
    world_sf$region,
    NA_character_
  )
  locations_sf <- sf::st_as_sf(
    locations,
    coords = c("longitude_deg", "latitude_deg"),
    crs = 4326,
    remove = FALSE
  )
  projection <- "+proj=eqc"
  world_projected <- sf::st_transform(world_sf, crs = projection)
  locations_projected <- sf::st_transform(locations_sf, crs = projection)
  label_locations_sf <- sf::st_as_sf(
    locations,
    coords = c("label_longitude", "label_latitude"),
    crs = 4326,
    remove = FALSE
  )
  label_locations_projected <- sf::st_transform(
    label_locations_sf,
    crs = projection
  )
  point_coordinates <- sf::st_coordinates(locations_projected)
  label_coordinates <- sf::st_coordinates(label_locations_projected)
  label_data <- locations |>
    dplyr::mutate(
      point_x = point_coordinates[, "X"],
      point_y = point_coordinates[, "Y"],
      label_x = label_coordinates[, "X"],
      label_y = label_coordinates[, "Y"]
    )
  connection_locations_sf <- sf::st_as_sf(
    connection_layout,
    coords = c("connection_longitude", "connection_latitude"),
    crs = 4326,
    remove = FALSE
  )
  connection_coordinates <- connection_locations_sf |>
    sf::st_transform(crs = projection) |>
    sf::st_coordinates()
  connection_data <- connection_layout |>
    dplyr::mutate(
      connection_x = connection_coordinates[, "X"],
      connection_y = connection_coordinates[, "Y"]
    )
  segment_data <- label_data |>
    dplyr::inner_join(connection_data, by = "site")
  fill_values <- c(
    stats::setNames(country_colours$colour, country_colours$country),
    descriptive_site_palette()
  )
  ggplot2::ggplot() +
    ggplot2::geom_sf(
      data = world_projected,
      ggplot2::aes(fill = .data$fill_key),
      colour = NA,
      linewidth = 0.25,
      alpha = 0.50,
      show.legend = FALSE
    ) +
    ggplot2::geom_segment(
      data = segment_data,
      ggplot2::aes(
        x = .data$point_x,
        y = .data$point_y,
        xend = .data$connection_x,
        yend = .data$connection_y
      ),
      colour = "grey25",
      linewidth = 0.28,
      inherit.aes = FALSE
    ) +
    ggplot2::geom_sf(
      data = locations_projected,
      ggplot2::aes(fill = .data$site),
      shape = 21,
      colour = "black",
      size = 3,
      stroke = 0.2,
      show.legend = FALSE
    ) +
    ggplot2::geom_label(
      data = label_data,
      ggplot2::aes(
        x = .data$label_x,
        y = .data$label_y,
        label = .data$label,
        fill = .data$site,
        colour = .data$label_text_colour,
        hjust = .data$label_hjust
      ),
      linewidth = 0,
      size = 3.5,
      alpha = 0.84,
      label.padding = grid::unit(0.16, "lines"),
      inherit.aes = FALSE,
      show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(
      values = fill_values,
      na.value = "#BDBDBD",
      guide = "none"
    ) +
    ggplot2::scale_colour_identity(guide = "none") +
    ggplot2::coord_sf(expand = FALSE) +
    ggplot2::labs(x = NULL, y = NULL) +
    cowplot::theme_cowplot() +
    ggplot2::theme(
      legend.position = "none",
      axis.line = ggplot2::element_blank()
    )
}

make_collection_display_plot <- function(collection_intervals) {
  reader_levels <- rev(unname(descriptive_site_reader_labels()))
  data <- collection_intervals |>
    dplyr::mutate(
      reader_site = factor(
        display_site_label(.data$site),
        levels = reader_levels
      ),
      site_index = as.numeric(.data$reader_site),
      xmin = .data$interval_start - 0.45,
      xmax = .data$interval_end + 0.45,
      ymin = .data$site_index - 0.13,
      ymax = .data$site_index + 0.13
    )
  ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = data,
      ggplot2::aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = .data$ymin,
        ymax = .data$ymax,
        fill = .data$site
      ),
      colour = NA,
      alpha = 0.92
    ) +
    ggplot2::scale_y_continuous(
      breaks = seq_along(reader_levels),
      labels = reader_levels,
      limits = c(0.5, length(reader_levels) + 0.5),
      expand = ggplot2::expansion(mult = c(0, 0))
    ) +
    ggplot2::scale_fill_manual(
      values = descriptive_site_palette(),
      guide = "none"
    ) +
    ggplot2::scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    ggplot2::labs(x = "Collection dates", y = NULL) +
    cowplot::theme_cowplot() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(
        angle = 0,
        hjust = 0.5
      ),
      legend.position = "none"
    )
}

make_photoperiod_display_plot <- function(collection_days) {
  data <- collection_days |>
    dplyr::distinct(
      .data$site,
      .data$Id,
      .data$local_date,
      .keep_all = TRUE
    ) |>
    dplyr::mutate(
      reader_site = factor(
        display_site_label(.data$site),
        levels = rev(unname(descriptive_site_reader_labels()))
      )
    )
  ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data$photoperiod_hours,
      y = .data$reader_site,
      fill = .data$site,
      colour = .data$site
    )
  ) +
    ggplot2::geom_boxplot(
      width = 0.25,
      fill = NA,
      linewidth = 0.5,
      outlier.shape = NA,
      position = ggplot2::position_nudge(y = -0.25),
      show.legend = FALSE
    ) +
    ggridges::geom_density_ridges(
      bandwidth = 0.25,
      alpha = 0.68,
      scale = 1,
      colour = "black",
      linewidth = 0.45,
      show.legend = FALSE
    ) +
    ggplot2::scale_x_continuous(
      breaks = 10:21,
      limits = range(data$photoperiod_hours, na.rm = TRUE)
    ) +
    ggplot2::scale_colour_manual(values = descriptive_site_palette()) +
    ggplot2::scale_fill_manual(values = descriptive_site_palette()) +
    ggplot2::labs(y = NULL, x = "Photoperiod (hours)") +
    cowplot::theme_cowplot() +
    ggplot2::guides(fill = "none", colour = "none")
}

prepare_profile_context <- function(state_source, placement, site = NULL) {
  context <- state_source |>
    dplyr::filter(.data$placement == .env$placement)
  if (!is.null(site)) {
    context <- context |> dplyr::filter(.data$site == .env$site)
  }
  dplyr::bind_rows(
    context,
    context |>
      dplyr::mutate(
        xmin = .data$xmin + 1440,
        xmax = .data$xmax + 1440
      )
  )
}

prepare_average_period_context <- function(
  period_source,
  placement,
  site = NULL
) {
  periods <- period_source |>
    dplyr::filter(.data$placement == .env$placement)
  if (!is.null(site)) {
    periods <- periods |>
      dplyr::filter(.data$site == .env$site)
  }
  expanded <- tidyr::crossing(
    periods,
    day_offset = c(0, 1440)
  )
  list(
    night = dplyr::bind_rows(
      expanded |>
        dplyr::transmute(
          dplyr::across(dplyr::everything()),
          xmin = .data$day_offset,
          xmax = .data$day_offset + .data$mean_civil_dawn_minute
        ),
      expanded |>
        dplyr::transmute(
          dplyr::across(dplyr::everything()),
          xmin = .data$day_offset + .data$mean_civil_dusk_minute,
          xmax = .data$day_offset + 1440
        )
    ),
    sleep = dplyr::bind_rows(
      expanded |>
        dplyr::transmute(
          dplyr::across(dplyr::everything()),
          xmin = .data$day_offset,
          xmax = .data$day_offset + .data$mean_sleep_end_minute
        ),
      expanded |>
        dplyr::transmute(
          dplyr::across(dplyr::everything()),
          xmin = .data$day_offset + .data$mean_sleep_start_minute,
          xmax = .data$day_offset + 1440
        )
    )
  )
}

make_overall_profile_display_plot <- function(
  profile,
  state_source,
  period_source
) {
  site_lines <- profile |>
    dplyr::filter(.data$placement == "near_eye", .data$site != "Overall") |>
    duplicate_clock_day()
  overall_day <- profile |>
    dplyr::filter(.data$placement == "near_eye", .data$site == "Overall")
  overall <- duplicate_clock_day(overall_day)
  periods <- prepare_average_period_context(
    period_source,
    "near_eye",
    "Overall"
  )
  outer_target <- overall_day[
    which.min(abs(overall_day$clock_minute - 510)),
    ,
    drop = FALSE
  ]
  inner_target <- overall_day[
    which.min(abs(overall_day$clock_minute - 600)),
    ,
    drop = FALSE
  ]
  median_target <- overall_day[
    which.min(abs(overall_day$clock_minute - 570)),
    ,
    drop = FALSE
  ]
  site_target <- profile |>
    dplyr::filter(.data$placement == "near_eye", .data$site == "UCR")
  site_target <- site_target[
    which.min(abs(site_target$clock_minute - 495)),
    ,
    drop = FALSE
  ]
  # At the fixed Figure 1 geometry, these lower-left anchors place every
  # unequal-width label centre at 01:00 on day two. The right-day target bins
  # make the straight leaders leave the lower-right corners at about 45 degrees.
  profile_annotations <- dplyr::bind_rows(
    outer_target |>
      dplyr::transmute(
        label = "Central 90% of values",
        label_center_x = 1500,
        label_center_y = 15000,
        label_x = 1241.631713,
        label_y = 11199.0143,
        arrow_x = 2 * .data$label_center_x - .data$label_x,
        arrow_y = .data$label_y,
        target_site = .data$site,
        target_x = .data$clock_minute + 1440,
        # End just outside the interval so the arrowhead does not enter it.
        target_y = pmax(.data$value_upper_90_lx * 1.08, 0.01)
      ),
    inner_target |>
      dplyr::transmute(
        label = "Central 50% of values",
        label_center_x = 1500,
        label_center_y = 6500,
        label_x = 1241.631713,
        label_y = 4852.9062,
        arrow_x = 2 * .data$label_center_x - .data$label_x,
        arrow_y = .data$label_y,
        target_site = .data$site,
        target_x = .data$clock_minute + 1440,
        target_y = pmax(.data$value_upper_50_lx * 1.08, 0.01)
      ),
    median_target |>
      dplyr::transmute(
        label = "Pooled median",
        label_center_x = 1500,
        label_center_y = 2800,
        label_x = 1321.002743,
        label_y = 2090.4827,
        arrow_x = 2 * .data$label_center_x - .data$label_x,
        arrow_y = .data$label_y,
        target_site = .data$site,
        target_x = .data$clock_minute + 1440,
        target_y = pmax(.data$median_lx * 1.08, 0.01)
      ),
    site_target |>
      dplyr::transmute(
        label = "Site median",
        label_center_x = 1500,
        label_center_y = 1200,
        label_x = 1355.015267,
        label_y = 895.9211,
        arrow_x = 2 * .data$label_center_x - .data$label_x,
        arrow_y = .data$label_y,
        target_site = .data$site,
        target_x = .data$clock_minute + 1440,
        target_y = pmax(.data$median_lx * 1.12, 0.01)
      )
  )

  ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = periods$night,
      ggplot2::aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = -Inf,
        ymax = Inf
      ),
      fill = "#001F5B",
      alpha = 0.10,
      colour = NA
    ) +
    ggplot2::geom_ribbon(
      data = overall,
      ggplot2::aes(
        x = .data$clock_minute,
        ymin = .data$value_lower_90_lx,
        ymax = .data$value_upper_90_lx
      ),
      fill = "#777777",
      alpha = 0.20,
      colour = NA
    ) +
    ggplot2::geom_ribbon(
      data = overall,
      ggplot2::aes(
        x = .data$clock_minute,
        ymin = .data$value_lower_50_lx,
        ymax = .data$value_upper_50_lx
      ),
      fill = "#777777",
      alpha = 0.38,
      colour = NA
    ) +
    ggplot2::geom_line(
      data = site_lines,
      ggplot2::aes(
        x = .data$clock_minute,
        y = .data$median_lx,
        colour = .data$site,
        group = .data$site
      ),
      linewidth = 0.48,
      alpha = 0.95,
      na.rm = TRUE
    ) +
    ggplot2::geom_line(
      data = overall,
      ggplot2::aes(x = .data$clock_minute, y = .data$median_lx),
      colour = "black",
      linewidth = 1.25,
      na.rm = TRUE
    ) +
    ggplot2::geom_hline(
      yintercept = c(1, 10, 250),
      colour = "grey65",
      linetype = "dashed",
      linewidth = 0.38
    ) +
    ggplot2::geom_rect(
      data = periods$sleep,
      ggplot2::aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = -Inf,
        ymax = -0.1
      ),
      fill = "#D73027",
      alpha = 1,
      colour = NA
    ) +
    ggplot2::geom_segment(
      data = profile_annotations,
      ggplot2::aes(
        x = .data$arrow_x,
        y = .data$arrow_y,
        xend = .data$target_x,
        yend = .data$target_y
      ),
      inherit.aes = FALSE,
      colour = "grey20",
      linewidth = 0.35,
      arrow = grid::arrow(
        type = "closed",
        length = grid::unit(0.11, "cm")
      )
    ) +
    ggplot2::geom_label(
      data = profile_annotations,
      ggplot2::aes(
        x = .data$label_x,
        y = .data$label_y,
        label = .data$label
      ),
      inherit.aes = FALSE,
      hjust = 0,
      vjust = 0,
      size = 3.6,
      linewidth = 0,
      label.padding = grid::unit(0.18, "lines"),
      fill = scales::alpha("white", 0.88),
      colour = "grey15"
    ) +
    display_double_clock_scale(compact = TRUE) +
    display_profile_y_scale(
      include_context_baseline = TRUE,
      context_lower = -0.35,
      upper = 20000
    ) +
    ggplot2::scale_colour_manual(
      values = descriptive_site_palette(),
      guide = "none"
    ) +
    ggplot2::guides(
      y = ggplot2::guide_axis_stack(
        display_recommendation_bracket(
          text_size = 12,
          label_hjust = rep(0.5, 3),
          line_width = 0.28
        ),
        "axis"
      )
    ) +
    ggplot2::labs(
      x = "Local time (hour)",
      y = "Melanopic EDI (lx)",
      caption = paste(
        "Contexts follow Brown et al. (2022).",
        "15-min median; nested central 50% and 90% value ribbons.",
        "Red: mean sleep; light blue-gray vertical bands: mean civil night.",
        sep = "\n"
      )
    ) +
    cowplot::theme_cowplot() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_line(colour = "grey98"),
      panel.grid.major.x = ggplot2::element_line(
        colour = "grey80",
        linetype = 2,
        linewidth = 0.25
      ),
      panel.grid.minor.x = ggplot2::element_line(
        colour = "grey80",
        linewidth = 0.25
      ),
      plot.caption = ggtext::element_markdown(),
      plot.margin = ggplot2::margin(10, 20, 10, 10, "pt"),
      legend.position = "none"
    )
}

make_overview_display_figure <- function(
  protocol_asset_path,
  site_locations,
  world_map,
  collection_intervals,
  collection_days,
  profile,
  state_source,
  period_source
) {
  p_protocol <- make_protocol_display_plot(protocol_asset_path)
  p_map <- make_site_map_display_plot(site_locations, world_map)
  p_collection <- make_collection_display_plot(collection_intervals)
  p_photoperiod <- make_photoperiod_display_plot(collection_days)
  p_profile <- make_overall_profile_display_plot(
    profile,
    state_source,
    period_source
  )
  middle <- patchwork::wrap_plots(
    p_map,
    p_collection,
    ncol = 2,
    widths = c(3, 2)
  )
  bottom <- patchwork::wrap_plots(
    p_photoperiod,
    p_profile,
    ncol = 2,
    widths = c(2, 3)
  )
  patchwork::wrap_plots(
    p_protocol,
    middle,
    bottom,
    ncol = 1,
    heights = c(1.3, 1, 1)
  ) +
    patchwork::plot_annotation(tag_levels = "A")
}

make_site_profile_display_figure <- function(
  profile,
  state_source,
  period_source,
  placement
) {
  focal <- profile |>
    dplyr::filter(.data$placement == .env$placement, .data$site != "Overall") |>
    duplicate_clock_day() |>
    dplyr::mutate(
      site_fill = unname(descriptive_site_palette()[.data$site]),
      reader_site = factor(
        display_site_label(.data$site),
        levels = unname(descriptive_site_reader_labels())
      )
    )
  ribbons <- dplyr::bind_rows(
    focal |>
      dplyr::mutate(
        interval = "95%",
        ribbon_lower_lx = .data$value_lower_95_lx,
        ribbon_upper_lx = .data$value_upper_95_lx
      ),
    focal |>
      dplyr::mutate(
        interval = "75%",
        ribbon_lower_lx = .data$value_lower_75_lx,
        ribbon_upper_lx = .data$value_upper_75_lx
      ),
    focal |>
      dplyr::mutate(
        interval = "50%",
        ribbon_lower_lx = .data$value_lower_50_lx,
        ribbon_upper_lx = .data$value_upper_50_lx
      )
  ) |>
    dplyr::mutate(
      interval = factor(.data$interval, levels = c("95%", "75%", "50%"))
    )
  periods <- prepare_average_period_context(period_source, placement)
  add_reader_site <- function(data) {
    data |>
      dplyr::filter(.data$site != "Overall") |>
      dplyr::mutate(
        reader_site = factor(
          display_site_label(.data$site),
          levels = unname(descriptive_site_reader_labels())
        )
      )
  }
  periods$night <- add_reader_site(periods$night)
  periods$sleep <- add_reader_site(periods$sleep)

  ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = periods$night,
      ggplot2::aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = -Inf,
        ymax = Inf
      ),
      fill = "#001F5B",
      alpha = 0.10,
      colour = NA
    ) +
    ggplot2::geom_ribbon(
      data = ribbons,
      ggplot2::aes(
        x = .data$clock_minute,
        ymin = .data$ribbon_lower_lx,
        ymax = .data$ribbon_upper_lx,
        fill = .data$site_fill,
        alpha = .data$interval,
        group = interaction(.data$site, .data$interval)
      ),
      colour = NA
    ) +
    ggplot2::geom_line(
      data = focal,
      ggplot2::aes(
        x = .data$clock_minute,
        y = .data$median_lx,
        group = .data$site
      ),
      colour = "black",
      linewidth = 0.32,
      na.rm = TRUE
    ) +
    ggplot2::geom_hline(
      yintercept = c(1, 10, 250),
      colour = "grey75",
      linetype = "dashed",
      linewidth = 0.16
    ) +
    ggplot2::geom_rect(
      data = periods$sleep,
      ggplot2::aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = -Inf,
        ymax = -0.1
      ),
      fill = "#D73027",
      alpha = 1,
      colour = NA
    ) +
    ggplot2::facet_wrap(
      ~reader_site,
      nrow = if (placement == "chest") 2 else 3,
      ncol = if (placement == "chest") 4 else 3,
      drop = TRUE
    ) +
    display_double_clock_scale(compact = TRUE) +
    display_profile_y_scale(
      include_context_baseline = TRUE,
      context_lower = -0.35
    ) +
    ggplot2::scale_fill_identity(guide = "none") +
    ggplot2::scale_colour_manual(
      values = descriptive_site_palette(),
      guide = "none"
    ) +
    ggplot2::scale_alpha_manual(
      values = c("50%" = 0.66, "75%" = 0.44, "95%" = 0.24),
      breaks = c("50%", "75%", "95%"),
      name = "Central data interval"
    ) +
    ggplot2::guides(
      y = ggplot2::guide_axis_stack(
        display_recommendation_bracket(
          compact = TRUE,
          text_size = 5,
          label_hjust = rep(0.5, 3),
          line_width = 0.16
        ),
        "axis"
      ),
      alpha = ggplot2::guide_legend(
        title.position = "left",
        override.aes = list(fill = "#4D4D4D", colour = NA)
      )
    ) +
    ggplot2::labs(
      x = "Local time (hour)",
      y = "Melanopic EDI (lx)",
      caption = paste(
        "Contexts follow Brown et al. (2022).",
        paste0(
          "Pooled 15-minute median with nested central 50%, 75%, and 95% ",
          "value intervals."
        ),
        paste0(
          "<span style='color:red'>Red: mean sleep</span>; light blue-gray ",
          "vertical bands: mean civil night."
        ),
        sep = "<br>"
      )
    ) +
    cowplot::theme_cowplot(font_size = 9.75) +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = "white", colour = NA),
      panel.grid.major = ggplot2::element_line(
        colour = "grey85",
        linewidth = 0.15
      ),
      panel.grid.minor = ggplot2::element_line(
        colour = "grey92",
        linetype = "dashed",
        linewidth = 0.10
      ),
      axis.line = ggplot2::element_line(linewidth = 0.18),
      axis.ticks = ggplot2::element_line(linewidth = 0.18),
      strip.background = ggplot2::element_rect(fill = "grey82", colour = NA),
      strip.text = ggplot2::element_text(colour = "black", size = 8),
      axis.text = ggplot2::element_text(colour = "black", size = 7),
      axis.title = ggplot2::element_text(colour = "black", size = 8),
      plot.background = ggplot2::element_rect(
        fill = "transparent",
        colour = NA
      ),
      plot.caption = ggtext::element_markdown(
        colour = "black",
        size = 7,
        hjust = 0
      ),
      plot.margin = ggplot2::margin(7, 8, 8, 8),
      panel.spacing.x = grid::unit(10, "pt"),
      panel.spacing.y = grid::unit(7, "pt"),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.title = ggplot2::element_text(size = 7),
      legend.text = ggplot2::element_text(size = 7),
      legend.key.width = grid::unit(18, "pt"),
      legend.spacing.x = grid::unit(4, "pt")
    )
}

display_metric_panel_contract <- function() {
  contract <- display_metric_contract()
  panel_ids <- c(
    "duration_above_1000",
    "duration_above_250_wake",
    "duration_below_10_pre_sleep",
    "duration_below_1_sleep_environment",
    "longest_bout_above_250",
    "interdaily_stability",
    "intradaily_variability",
    "dose_time_sensitive_corrected_medi",
    "daily_geometric_mean_medi",
    "m10_mean_medi",
    "mder_mean_of_viable_ratios",
    "m10_midpoint",
    "l10_midpoint",
    "first_timing_above_250",
    "last_timing_above_250",
    "mean_timing_above_250"
  )
  contract[match(panel_ids, contract$metric_id), , drop = FALSE]
}

unwrap_clock_for_panel <- function(value, metric_id) {
  centers <- c(
    m10_midpoint = 840,
    l10_midpoint = 180,
    first_timing_above_250 = 540,
    last_timing_above_250 = 1080,
    mean_timing_above_250 = 810
  )
  center <- unname(centers[[metric_id]])
  (value - center + 720) %% 1440 - 720 + center
}

display_compact_axis <- function(x) {
  vapply(
    x,
    function(value) {
      if (!is.finite(value)) return(NA_character_)
      if (value == 0) return("0")
      if (abs(value) < 1)
        return(trimws(formatC(value, format = "fg", digits = 2)))
      if (abs(value) < 1000)
        return(trimws(formatC(value, format = "fg", digits = 3)))
      paste0(trimws(formatC(value / 1000, format = "fg", digits = 3)), "K")
    },
    character(1)
  )
}

metric_panel_axis_label <- function(contract_row) {
  labels <- c(
    duration_above_1000 = "TAT1000 (HH:MM)",
    duration_above_250_wake = "TAT250,wake (HH:MM)",
    duration_below_10_pre_sleep = "TBT10,pre-sleep (HH:MM)",
    duration_below_1_sleep_environment = "TBT1,sleep env. (HH:MM)",
    longest_bout_above_250 = "PAT250 (HH:MM)",
    interdaily_stability = "IS (dimensionless)",
    intradaily_variability = "IV (dimensionless)",
    dose_time_sensitive_corrected_medi = "Corrected dose (klx·h)",
    daily_geometric_mean_medi = "Geometric mean (lx)",
    m10_mean_medi = "M10 mean (lx)",
    l10_mean_medi = "L10 mean (lx)",
    mder_mean_of_viable_ratios = "MDER (dimensionless)",
    m10_midpoint = "M10 midpoint (HH:MM)",
    l10_midpoint = "L10 midpoint (HH:MM)",
    first_timing_above_250 = "First >250 lx (HH:MM)",
    last_timing_above_250 = "Last >250 lx (HH:MM)",
    mean_timing_above_250 = "Mean >250 lx timing (HH:MM)"
  )
  metric_id <- contract_row$metric_id[[1L]]
  label <- unname(labels[[metric_id]])
  if (is.null(label))
    stop("No single-line metric label: ", metric_id, call. = FALSE)
  label
}

make_metric_display_panel <- function(
  metric_values,
  contract_row,
  panel_index
) {
  metric_id <- contract_row$metric_id[[1L]]
  data <- metric_values |>
    dplyr::filter(
      .data$placement == "near_eye",
      .data$metric_id == .env$metric_id,
      .data$finite,
      is.finite(.data$value)
    ) |>
    dplyr::mutate(
      reader_site = factor(
        display_site_label(.data$site),
        levels = rev(unname(descriptive_site_reader_labels()))
      ),
      plot_value = .data$value
    )
  is_duration <- grepl("duration|longest_bout", metric_id)
  is_timing <- grepl("timing|midpoint", metric_id)
  is_symlog <- metric_id %in%
    c(
      "daily_geometric_mean_medi",
      "m10_mean_medi",
      "l10_mean_medi"
    )
  if (metric_id == "dose_time_sensitive_corrected_medi") {
    data$plot_value <- data$plot_value / 1000
  }
  if (is_timing)
    data$plot_value <- unwrap_clock_for_panel(data$plot_value, metric_id)
  raw_range <- range(data$plot_value, na.rm = TRUE)
  symlog <- NULL
  symlog_breaks <- NULL
  if (is_symlog) {
    symlog <- LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)
    data$plot_value <- symlog$transform(data$plot_value)
    candidates <- c(0, 1, 10, 100, 1000, 10000, 100000)
    symlog_breaks <- candidates[
      candidates == 0 | candidates <= raw_range[[2L]] * 1.05
    ]
  }
  show_y <- panel_index %in% c(1L, 5L, 9L, 13L)
  range_x <- range(data$plot_value, na.rm = TRUE)

  plot <- ggplot2::ggplot(data, ggplot2::aes(x = .data$plot_value)) +
    ggplot2::geom_boxplot(
      ggplot2::aes(y = .data$reader_site, colour = .data$site),
      width = 0.25,
      fill = NA,
      linewidth = 0.20,
      outlier.size = 0.45,
      outlier.alpha = 0.65,
      outlier.stroke = 0.12,
      position = ggplot2::position_nudge(y = -0.25),
      show.legend = FALSE
    ) +
    ggridges::geom_density_ridges(
      ggplot2::aes(y = .data$reader_site, fill = .data$site),
      linewidth = 0.32,
      colour = NA,
      alpha = 0.5,
      scale = 1,
      from = range_x[[1L]],
      to = range_x[[2L]],
      show.legend = FALSE
    ) +
    ggridges::geom_density_ridges(
      ggplot2::aes(y = .data$reader_site, colour = .data$site),
      fill = NA,
      alpha = 1,
      linewidth = 0.32,
      scale = 1,
      quantile_lines = TRUE,
      quantiles = 2,
      vline_color = "red",
      from = range_x[[1L]],
      to = range_x[[2L]],
      show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(values = descriptive_site_palette()) +
    ggplot2::scale_colour_manual(values = descriptive_site_palette()) +
    ggplot2::guides(fill = "none", colour = "none") +
    ggplot2::labs(y = NULL, x = metric_panel_axis_label(contract_row)) +
    ggridges::theme_ridges() +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::theme(
      plot.margin = ggplot2::margin(r = 6, t = 8, b = 4, l = 2),
      axis.line = ggplot2::element_line(linewidth = 0.22),
      axis.ticks = ggplot2::element_line(linewidth = 0.22),
      axis.text.y = if (show_y) {
        ggplot2::element_text(vjust = 0, size = 6.5)
      } else {
        ggplot2::element_blank()
      },
      axis.text.x = ggplot2::element_text(size = 6.5),
      axis.title.x = ggplot2::element_text(
        size = 6.5,
        lineheight = 0.95,
        margin = ggplot2::margin(t = 5)
      )
    )
  if (is_duration) {
    plot <- plot +
      ggplot2::scale_x_continuous(
        breaks = scales::breaks_pretty(n = 3),
        labels = format_duration_hours
      )
  } else if (is_timing) {
    width <- if (diff(range_x) > 14 * 60) 480 else 240
    plot <- plot +
      ggplot2::scale_x_continuous(
        breaks = scales::breaks_width(width),
        labels = function(x) format_clock_minute(x %% 1440)
      )
  } else if (is_symlog) {
    if (length(symlog_breaks) > 4L) {
      keep <- unique(round(seq(1, length(symlog_breaks), length.out = 4)))
      symlog_breaks <- symlog_breaks[keep]
    }
    plot <- plot +
      ggplot2::scale_x_continuous(
        breaks = symlog$transform(symlog_breaks),
        labels = display_compact_axis(symlog_breaks)
      )
  } else {
    plot <- plot +
      ggplot2::scale_x_continuous(
        breaks = scales::breaks_pretty(n = 3)
      )
  }
  plot
}

make_metric_distributions_display_figure <- function(metric_values) {
  contract <- display_metric_panel_contract()
  panels <- lapply(seq_len(nrow(contract)), function(index) {
    make_metric_display_panel(
      metric_values,
      contract[index, , drop = FALSE],
      index
    )
  })
  patchwork::wrap_plots(panels, ncol = 4) +
    patchwork::plot_annotation(tag_levels = "A") &
    ggplot2::theme(
      plot.tag = ggplot2::element_text(face = "bold", size = 7.5)
    )
}

display_participant_palette <- function() {
  c(
    BAUA_S003 = "#0072B2",
    BAUA_S009 = "#E6AB02",
    BAUA_S022 = "#7F7F7F",
    MPI_S205 = "#D55E4B",
    MPI_S226 = "#77AADD",
    MPI_S227 = "#004C6D",
    TUM_S009 = "#9A7D00"
  )
}

make_time_series_display_figure <- function(series, states, metrics) {
  participant_levels <- metrics |>
    dplyr::distinct(.data$participant, .data$participant_order) |>
    dplyr::arrange(.data$participant_order) |>
    dplyr::pull("participant")
  series <- series |>
    dplyr::mutate(
      participant = factor(.data$participant, levels = participant_levels)
    )
  # Draw paths through finite light measurements while retaining missing bins
  # in the exported source data. Lines connect across isolated missing bins.
  series_plot <- series |>
    dplyr::filter(is.finite(.data$melEDI_lx))
  states <- states |>
    dplyr::mutate(
      participant = factor(.data$participant, levels = participant_levels)
    )
  metrics <- metrics |>
    dplyr::mutate(
      participant = factor(.data$participant, levels = participant_levels),
      weekday = factor(
        .data$weekday,
        levels = c("Wed", "Thu", "Fri", "Sat", "Sun")
      )
    )
  day_breaks <- (0:4) * 1440 + 720
  day_labels <- paste("12:00", c("Wed", "Thu", "Fri", "Sat", "Sun"))
  annotation_data <- data.frame(
    participant = factor(participant_levels[[1L]], levels = participant_levels),
    x = 640,
    y = 2400,
    label = "recommended daytime minimum"
  )
  curve_data <- data.frame(
    participant = factor(participant_levels[[1L]], levels = participant_levels),
    x = 610,
    xend = 390,
    y = 5000,
    yend = 250
  )

  p_a <- ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = dplyr::filter(states, .data$civil_night),
      ggplot2::aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = 0,
        ymax = 100000
      ),
      fill = "#D9D9D9",
      alpha = 1,
      colour = NA
    ) +
    ggplot2::geom_area(
      data = series_plot,
      ggplot2::aes(
        x = .data$aligned_minute,
        y = .data$melEDI_lx,
        fill = .data$participant,
        group = .data$participant
      ),
      alpha = 0.25,
      na.rm = TRUE
    ) +
    ggplot2::geom_line(
      data = series_plot,
      ggplot2::aes(
        x = .data$aligned_minute,
        y = .data$melEDI_lx,
        colour = .data$participant,
        group = .data$participant
      ),
      linewidth = 0.42,
      na.rm = TRUE
    ) +
    ggplot2::geom_hline(
      yintercept = 250,
      linetype = "dashed",
      linewidth = 0.32,
      colour = "black"
    ) +
    ggplot2::geom_text(
      data = annotation_data,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
      inherit.aes = FALSE,
      hjust = 0,
      vjust = 0,
      fontface = "bold",
      size = 3.2
    ) +
    ggplot2::geom_curve(
      data = curve_data,
      ggplot2::aes(
        x = .data$x,
        xend = .data$xend,
        y = .data$y,
        yend = .data$yend
      ),
      inherit.aes = FALSE,
      curvature = 0.4,
      linewidth = 0.32,
      arrow = grid::arrow(type = "closed", length = grid::unit(0.15, "cm"))
    ) +
    ggplot2::facet_wrap(~participant, ncol = 1) +
    ggplot2::scale_x_continuous(
      breaks = day_breaks,
      labels = day_labels,
      limits = c(0, 5 * 1440),
      expand = ggplot2::expansion(mult = c(0, 0))
    ) +
    display_time_series_y_scale() +
    ggplot2::scale_fill_manual(
      values = display_participant_palette(),
      guide = "none"
    ) +
    ggplot2::scale_colour_manual(
      values = display_participant_palette(),
      guide = "none"
    ) +
    ggplot2::labs(
      x = "Local date/time",
      y = "Melanopic EDI (lx)",
      tag = "A"
    ) +
    cowplot::theme_cowplot(font_size = 9.5) +
    ggplot2::theme(
      strip.text = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(
        colour = "grey80",
        linetype = 2,
        linewidth = 0.45
      ),
      panel.grid.minor.x = ggplot2::element_line(
        colour = "grey80",
        linewidth = 0.30
      ),
      panel.spacing = grid::unit(0.04, "in"),
      plot.tag.position = c(0, 1),
      plot.margin = ggplot2::margin(5, 8, 3, 5)
    )

  p_b <- ggplot2::ggplot(
    metrics,
    ggplot2::aes(
      x = .data$duration_above_250_daytime_h,
      y = forcats::fct_rev(.data$participant),
      fill = .data$participant
    )
  ) +
    ggplot2::geom_boxplot(alpha = 0.25, width = 0.55, na.rm = TRUE) +
    ggplot2::scale_fill_manual(
      values = display_participant_palette(),
      guide = "none"
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 12, by = 4),
      limits = c(0, NA)
    ) +
    ggplot2::labs(
      x = expression(TAT[250] ~ "(Hrs)"),
      y = NULL,
      tag = "B"
    ) +
    cowplot::theme_cowplot(font_size = 9.5) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      axis.line.y = ggplot2::element_blank(),
      plot.tag.position = c(0, 1),
      plot.margin = ggplot2::margin(5, 5, 3, 2)
    )

  p_c <- ggplot2::ggplot(
    metrics,
    ggplot2::aes(x = .data$weekday, y = .data$duration_above_250_daytime_h)
  ) +
    ggplot2::geom_boxplot(width = 0.5, fill = "white", na.rm = TRUE) +
    ggplot2::scale_x_discrete(expand = c(0, 0)) +
    ggplot2::coord_cartesian(xlim = c(0.5, 5.5)) +
    ggplot2::labs(
      y = expression(TAT[250] ~ "(Hrs)"),
      x = NULL,
      tag = "C"
    ) +
    cowplot::theme_cowplot(font_size = 9.5) +
    ggplot2::theme(
      # Keep the panel tag clear of the vertical axis title at the final
      # publication display size. The extra space belongs to the figure
      # canvas; it does not change the text-size contract.
      plot.margin = ggplot2::margin(3, 5, 5, 24),
      plot.tag.position = c(0.10, 0.99)
    )

  p_d <- ggplot2::ggplot(
    metrics,
    ggplot2::aes(x = .data$weekday, y = forcats::fct_rev(.data$participant))
  ) +
    ggplot2::geom_point(
      ggplot2::aes(
        size = .data$duration_above_250_daytime_h,
        colour = .data$participant
      ),
      alpha = 0.5,
      na.rm = TRUE
    ) +
    ggplot2::scale_colour_manual(
      values = display_participant_palette(),
      guide = "none"
    ) +
    ggplot2::scale_size_continuous(range = c(0.7, 3.2), guide = "none") +
    ggplot2::scale_x_discrete(
      breaks = "Fri",
      labels = expression(Size:TAT[250])
    ) +
    ggplot2::labs(y = NULL, x = NULL, tag = "D") +
    cowplot::theme_cowplot(font_size = 9.5) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.line.y = ggplot2::element_blank(),
      plot.tag.position = c(0, 1),
      plot.margin = ggplot2::margin(3, 5, 5, 2)
    )

  layout <- "AAAAB\nAAAAB\nAAAAB\nAAAAB\nCCCCD"
  patchwork::wrap_plots(
    A = p_a,
    B = p_b,
    C = p_c,
    D = p_d,
    design = layout
  ) +
    patchwork::plot_annotation(
      caption = paste(
        "TAT = time above threshold during daytime; subscripts give melEDI thresholds in lx.",
        "Lines and TAT250 values use the same alternative-preprocessing 30-minute samples.",
        sep = "\n"
      )
    ) &
    ggplot2::theme(
      plot.tag = ggplot2::element_text(face = "bold"),
      plot.caption = ggplot2::element_text(
        size = 7.5,
        hjust = 0,
        lineheight = 1,
        margin = ggplot2::margin(t = 5)
      )
    )
}

make_latitude_photoperiod_display_figure <- function(
  latitude_source,
  bounds_source
) {
  data <- latitude_source |>
    dplyr::mutate(
      site = factor(as.character(.data$site), levels = descriptive_site_order())
    )
  present_sites <- descriptive_site_order()[
    descriptive_site_order() %in% unique(as.character(data$site))
  ]
  x_limits <- range(
    c(
      bounds_source$minimum_possible_photoperiod_hours,
      bounds_source$maximum_possible_photoperiod_hours
    ),
    na.rm = TRUE
  )
  ggplot2::ggplot() +
    ggplot2::geom_point(
      data = data,
      ggplot2::aes(
        x = .data$photoperiod_hours,
        y = .data$absolute_latitude_deg,
        colour = .data$site
      ),
      shape = 16,
      alpha = 0.38,
      size = 1.05,
      position = ggplot2::position_jitter(
        width = 0.12,
        height = 0.55,
        seed = 20260810
      )
    ) +
    ggridges::geom_density_ridges(
      data = data,
      ggplot2::aes(
        x = .data$photoperiod_hours,
        y = .data$absolute_latitude_deg,
        fill = .data$site,
        group = .data$site
      ),
      scale = 2,
      position = ggplot2::position_nudge(y = 1),
      bandwidth = 0.15,
      alpha = 0.74,
      linewidth = 0.5,
      colour = "black",
      rel_min_height = 0.01,
      show.legend = TRUE,
      key_glyph = "rect"
    ) +
    ggplot2::geom_ribbon(
      data = bounds_source,
      ggplot2::aes(
        y = .data$absolute_latitude_deg,
        xmin = 0,
        xmax = .data$minimum_possible_photoperiod_hours
      ),
      orientation = "y",
      fill = "black"
    ) +
    ggplot2::geom_ribbon(
      data = bounds_source,
      ggplot2::aes(
        y = .data$absolute_latitude_deg,
        xmin = .data$maximum_possible_photoperiod_hours,
        xmax = 24
      ),
      orientation = "y",
      fill = "black"
    ) +
    ggplot2::annotate(
      "text",
      y = 3,
      x = 15.2,
      label = "possible photoperiods",
      colour = "white",
      hjust = 0,
      size = 4.2
    ) +
    ggplot2::annotate(
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
    ggplot2::scale_colour_manual(
      values = descriptive_site_palette(),
      breaks = present_sites,
      labels = unname(descriptive_site_reader_labels()[present_sites]),
      name = "Site"
    ) +
    ggplot2::scale_fill_manual(
      values = descriptive_site_palette(),
      breaks = present_sites,
      labels = unname(descriptive_site_reader_labels()[present_sites]),
      name = "Site"
    ) +
    ggplot2::guides(
      colour = "none",
      fill = ggplot2::guide_legend(
        override.aes = list(alpha = 1, colour = "black", linewidth = 0.45)
      )
    ) +
    ggplot2::coord_cartesian(
      xlim = x_limits,
      ylim = c(0, 63),
      expand = FALSE
    ) +
    ggplot2::labs(
      x = "Photoperiod (hr)",
      y = "Absolute latitude (°)"
    ) +
    cowplot::theme_cowplot(font_size = 13.5) +
    ggplot2::theme(
      legend.position = "inside",
      legend.position.inside = c(0.72, 0.40),
      legend.justification = c(0.5, 0.5),
      legend.background = ggplot2::element_rect(
        fill = "transparent",
        colour = NA
      ),
      legend.key = ggplot2::element_rect(fill = "transparent", colour = NA),
      legend.key.spacing.y = grid::unit(2.5, "pt"),
      legend.key.height = grid::unit(11, "pt"),
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour = "white", size = 10.75),
      plot.background = ggplot2::element_rect(
        fill = "transparent",
        colour = NA
      ),
      panel.background = ggplot2::element_rect(
        fill = "transparent",
        colour = NA
      ),
      plot.margin = ggplot2::margin(5.5, 5.5, 5.5, 5.5)
    )
}
