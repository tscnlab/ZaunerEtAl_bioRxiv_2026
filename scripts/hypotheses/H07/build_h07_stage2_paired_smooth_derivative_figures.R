source("scripts/hypotheses/H07/h07_stage2_core.R")

paired_figure_version <- "H07-STAGE2-PAIRED-FIGURES-2026-08-07-B"
primary_derivative_method <- "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE"
panel_levels <- c("Fitted metric value", "First derivative")

read_h07_table <- function(file) {
  readr::read_csv(
    file.path(h07_stage2_paths$tables, file),
    show_col_types = FALSE,
    na = ""
  )
}

curve_points <- read_h07_table("H07_main_curve_points.csv")
derivative_points <- read_h07_table("H07_revised_derivative_points.csv") |>
  filter(.data$method_id == .env$primary_derivative_method)
plateau_summary <- read_h07_table("H07_revised_plateau_summary.csv") |>
  filter(.data$method_id == .env$primary_derivative_method)
photoperiod_rows <- read_h07_table(
  "H07_revised_derivative_photoperiod_rows.csv"
)

expected_pairs <- tidyr::crossing(
  placement = c("near_eye", "chest"),
  metric_id = h07_stage2_metric_ids
)

stopifnot(
  nrow(derivative_points) == 1800L,
  nrow(plateau_summary) == 18L,
  nrow(dplyr::distinct(derivative_points, .data$placement, .data$metric_id)) ==
    nrow(expected_pairs),
  nrow(dplyr::distinct(curve_points, .data$placement, .data$metric_id)) ==
    nrow(expected_pairs),
  nrow(dplyr::distinct(photoperiod_rows, .data$placement, .data$metric_id)) ==
    nrow(expected_pairs)
)

metric_display <- h07_stage2_metric_contract |>
  select(
    "metric_id",
    "metric_order",
    "manuscript_name",
    "display_unit"
  )

facet_registry <- tidyr::crossing(
  metric_id = h07_stage2_metric_ids,
  panel_kind = factor(panel_levels, levels = panel_levels)
) |>
  left_join(metric_display, by = "metric_id") |>
  arrange(.data$metric_order, .data$panel_kind) |>
  mutate(
    facet_label = if_else(
      .data$panel_kind == "Fitted metric value",
      paste0(
        stringr::str_wrap(.data$manuscript_name, width = 36),
        "\nFitted value (",
        .data$display_unit,
        ")"
      ),
      paste0(
        stringr::str_wrap(.data$manuscript_name, width = 36),
        "\nFirst derivative (model scale/h)"
      )
    )
  )
facet_levels <- facet_registry$facet_label
facet_registry <- facet_registry |>
  mutate(facet_label = factor(.data$facet_label, levels = .env$facet_levels))

recorded_ranges <- derivative_points |>
  group_by(.data$placement, .data$metric_id) |>
  summarise(
    recorded_min = min(.data$photoperiod_hours),
    recorded_max = max(.data$photoperiod_hours),
    .groups = "drop"
  )

smooth_plot_points <- curve_points |>
  inner_join(recorded_ranges, by = c("placement", "metric_id")) |>
  filter(
    .data$photoperiod_hours >= .data$recorded_min,
    .data$photoperiod_hours <= .data$recorded_max
  ) |>
  transmute(
    placement,
    metric_id,
    metric_order,
    manuscript_name,
    panel_kind = "Fitted metric value",
    photoperiod_hours,
    estimate = response_estimate,
    lower = response_lower_pointwise,
    upper = response_upper_pointwise
  )

derivative_plot_points <- derivative_points |>
  transmute(
    placement,
    metric_id,
    metric_order,
    manuscript_name,
    panel_kind = "First derivative",
    photoperiod_hours,
    estimate = derivative_estimate,
    lower = derivative_lower,
    upper = derivative_upper
  )

paired_points <- bind_rows(smooth_plot_points, derivative_plot_points) |>
  left_join(
    facet_registry |>
      select("metric_id", "panel_kind", "facet_label"),
    by = c("metric_id", "panel_kind")
  )

rug_points <- photoperiod_rows |>
  mutate(panel_kind = "Fitted metric value") |>
  left_join(
    facet_registry |>
      select("metric_id", "panel_kind", "facet_label"),
    by = c("metric_id", "panel_kind")
  )

transition_rectangles <- tidyr::crossing(
  plateau_summary |>
    filter(.data$revised_plateau_pattern),
  panel_kind = panel_levels
) |>
  left_join(
    facet_registry |>
      select("metric_id", "panel_kind", "facet_label"),
    by = c("metric_id", "panel_kind")
  )

stopifnot(
  !anyNA(paired_points$facet_label),
  !anyNA(rug_points$facet_label),
  !anyNA(transition_rectangles$facet_label),
  nrow(dplyr::distinct(paired_points, .data$placement, .data$facet_label)) == 36L
)

figure_settings <- tibble::tibble()

for (placement_value in c("near_eye", "chest")) {
  placement_title <- if (placement_value == "near_eye") {
    "Near-eye — primary"
  } else {
    "Chest — complementary"
  }
  plot_points <- paired_points |>
    filter(.data$placement == .env$placement_value)
  plot_rug <- rug_points |>
    filter(.data$placement == .env$placement_value)
  plot_transitions <- transition_rectangles |>
    filter(.data$placement == .env$placement_value)
  derivative_zero_lines <- facet_registry |>
    filter(.data$panel_kind == "First derivative") |>
    transmute(facet_label, yintercept = 0)

  plot <- ggplot(
    plot_points,
    aes(.data$photoperiod_hours, .data$estimate)
  ) +
    geom_rect(
      data = plot_transitions,
      aes(
        xmin = .data$plateau_start,
        xmax = .data$recorded_photoperiod_max,
        ymin = -Inf,
        ymax = Inf
      ),
      inherit.aes = FALSE,
      fill = "#56B4E9",
      alpha = 0.12
    ) +
    geom_hline(
      data = derivative_zero_lines,
      aes(yintercept = .data$yintercept),
      inherit.aes = FALSE,
      colour = "#4b5563",
      linewidth = 0.4
    ) +
    geom_ribbon(
      aes(ymin = .data$lower, ymax = .data$upper),
      fill = "#9ca3af",
      alpha = 0.24,
      colour = NA
    ) +
    geom_line(colour = "#111827", linewidth = 0.7) +
    geom_vline(
      data = plot_transitions,
      aes(xintercept = .data$plateau_start),
      inherit.aes = FALSE,
      colour = "#0072B2",
      linewidth = 0.6,
      linetype = 2
    ) +
    geom_rug(
      data = plot_rug,
      aes(x = .data$photoperiod_hours),
      inherit.aes = FALSE,
      sides = "b",
      alpha = 0.035,
      linewidth = 0.22
    ) +
    facet_wrap(
      vars(.data$facet_label),
      ncol = 2,
      scales = "free_y",
      axes = "all_x",
      axis.labels = "all_x",
      drop = FALSE
    ) +
    scale_x_continuous(
      breaks = seq(10, 20, by = 2),
      expand = expansion(mult = c(0.01, 0.01))
    ) +
    labs(
      x = "Civil photoperiod (h)",
      y = NULL,
      title = placement_title,
      subtitle = paste0(
        "Each row pairs the response-scale fitted metric value (left)\n",
        "with the model-scale first derivative used for classification ",
        "(right).\n",
        "Grey ribbons are unconditional pointwise 95% intervals; dashed ",
        "lines\n",
        "and blue tails mark the derivative-defined plateau pattern."
      )
    ) +
    theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      panel.spacing.x = grid::unit(1.1, "lines"),
      panel.spacing.y = grid::unit(0.9, "lines"),
      strip.text = element_text(face = "bold", size = 12, lineheight = 0.98),
      strip.background = element_rect(fill = "#f3f4f6", colour = NA),
      plot.title = element_text(face = "bold", size = 18),
      plot.subtitle = element_text(size = 12, margin = margin(b = 12)),
      plot.title.position = "plot",
      plot.margin = margin(12, 14, 12, 14),
      axis.title.x = element_text(size = 11, margin = margin(t = 3)),
      axis.text = element_text(size = 10.5),
      axis.text.x = element_text(margin = margin(t = 2))
    )

  filename <- paste0(
    "H07_revised_smooth_derivative_pairs_",
    placement_value,
    ".png"
  )
  ggplot2::ggsave(
    file.path(h07_stage2_paths$figures, filename),
    plot,
    width = 9,
    height = 18,
    units = "in",
    dpi = 270,
    bg = "white"
  )

  figure_settings <- bind_rows(
    figure_settings,
    tibble::tibble(
      figure_version = paired_figure_version,
      placement = placement_value,
      filename = filename,
      arrangement = "nine rows; fitted value left and first derivative right",
      smooth_scale = "response scale",
      derivative_scale = "model/link scale per photoperiod hour",
      interval = "unconditional pointwise 95% confidence interval",
      derivative_method = primary_derivative_method,
      width_in = 9,
      height_in = 18,
      dpi = 270L,
      curve_source = "H07_main_curve_points.csv",
      derivative_source = "H07_revised_derivative_points.csv",
      transition_source = "H07_revised_plateau_summary.csv",
      rug_source = "H07_revised_derivative_photoperiod_rows.csv"
    )
  )
}

h07_stage2_write_table(
  figure_settings,
  "H07_revised_paired_figure_settings.csv"
)

message("H07 paired fitted-smooth and derivative figures complete")
