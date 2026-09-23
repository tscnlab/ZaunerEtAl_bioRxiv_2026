read_reader <- function(...) {
  path <- file.path(root, ...)
  if (!file.exists(path)) {
    stop(paste("Missing H11 reader-display input:", path), call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE)
}

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
          "specified symlog scale: linear from 0 to 1 lx and base-10 above 1 lx."
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

with_reader_labels <- function(data) {
  data |>
    dplyr::left_join(run_labels, by = "run_id", relationship = "many-to-one") |>
    dplyr::relocate(
      dataset_label,
      placement_label,
      reader_role,
      .after = run_id
    )
}

format_clock <- function(minutes) {
  ifelse(
    minutes == 1440,
    "24:00",
    sprintf("%02d:%02d", (minutes %/% 60) %% 24, minutes %% 60)
  )
}

write_reader <- function(data, directory, filename) {
  invisible(write_csv_artifact(
    data,
    file.path(directory, filename),
    producer = producer
  ))
}
