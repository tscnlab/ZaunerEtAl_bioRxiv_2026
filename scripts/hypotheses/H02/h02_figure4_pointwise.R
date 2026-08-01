# Shared near-eye/chest builder for the submitted Figure 4 visual contract.
# Scientific calculations are performed from stored H02 BAM fits in R. The
# builder does not refit models and uses pointwise conditional 95% intervals.

h02_build_figure_contract <- function(
    run_id,
    placement_label,
    frame_path,
    model_path,
    contribution_path,
    base_path,
    prediction_path,
    site_registry) {
  frame <- readRDS(frame_path)
  fit <- readRDS(model_path)
  contributions <- readRDS(contribution_path)
  predictions <- readr::read_csv(
    prediction_path,
    show_col_types = FALSE
  ) |>
    dplyr::filter(.data$run_id == .env$run_id)

  fitted_sites <- unique(as.character(frame$site))
  fitted_registry <- site_registry |>
    dplyr::filter(.data$site %in% .env$fitted_sites) |>
    dplyr::arrange(.data$display_order)
  if (
    !setequal(fitted_sites, fitted_registry$site) ||
      nrow(predictions) != length(fitted_sites) * 48L
  ) {
    h02_abort("DISPLAY-001 or prediction coverage failed for %s", run_id)
  }
  display_levels <- fitted_registry$display_name
  palette <- stats::setNames(
    fitted_registry$color_hex,
    fitted_registry$display_name
  )

  prepared <- h02_prepare_fit_data(frame)
  sites <- levels(prepared$site)
  time_hour <- (seq.int(0L, 1410L, by = 30L) + 15) / 60
  grid <- tidyr::crossing(
    site = factor(sites, levels = sites),
    time_hour = time_hour
  ) |>
    dplyr::mutate(
      site_smooth = ordered(as.character(.data$site), levels = sites),
      participant = factor(
        levels(prepared$participant)[1],
        levels = levels(prepared$participant)
      ),
      participant_day = factor(
        levels(prepared$participant_day)[1],
        levels = levels(prepared$participant_day)
      )
    )
  L <- mgcv::predict.gam(
    fit,
    newdata = as.data.frame(grid),
    type = "lpmatrix",
    newdata.guaranteed = TRUE
  )
  random_columns <- h02_random_smooth_indices(fit)
  if (length(random_columns) > 0L) {
    L[, random_columns] <- 0
  }

  beta <- stats::coef(fit)
  Vp <- fit$Vp
  eta <- drop(L %*% beta)
  se_conditional <- sqrt(pmax(0, rowSums((L %*% Vp) * L)))
  prediction_check <- grid |>
    dplyr::transmute(
      site = as.character(.data$site),
      time_hour = .data$time_hour,
      eta_reconstructed = .env$eta,
      se_reconstructed = .env$se_conditional
    ) |>
    dplyr::left_join(
      predictions |>
        dplyr::select("site", "time_hour", "eta", "standard_error"),
      by = c("site", "time_hour"),
      relationship = "one-to-one"
    )
  if (
    anyNA(prediction_check) ||
      max(abs(
        prediction_check$eta_reconstructed - prediction_check$eta
      )) > 1e-8 ||
      max(abs(
        prediction_check$se_reconstructed -
          prediction_check$standard_error
      )) > 1e-8
  ) {
    h02_abort("Stored and reconstructed predictions disagree for %s", run_id)
  }

  time_rows <- split(seq_len(nrow(grid)), grid$time_hour)
  L_common <- do.call(
    rbind,
    lapply(time_rows, function(rows) {
      colMeans(L[rows, , drop = FALSE])
    })
  )
  time_lookup <- match(grid$time_hour, sort(unique(grid$time_hour)))
  L_deviation <- L - L_common[time_lookup, , drop = FALSE]
  common_eta <- drop(L_common %*% beta)
  common_se <- sqrt(pmax(
    0,
    rowSums((L_common %*% Vp) * L_common)
  ))
  deviation_eta <- drop(L_deviation %*% beta)
  deviation_se <- sqrt(pmax(
    0,
    rowSums((L_deviation %*% Vp) * L_deviation)
  ))
  deviation_check <- grid |>
    dplyr::transmute(
      site = as.character(.data$site),
      time_hour = .data$time_hour,
      eta_reconstructed = .env$deviation_eta,
      se_reconstructed = .env$deviation_se
    ) |>
    dplyr::left_join(
      predictions |>
        dplyr::select(
          "site",
          "time_hour",
          "equal_site_deviation_eta",
          "deviation_standard_error"
        ),
      by = c("site", "time_hour"),
      relationship = "one-to-one"
    )
  if (
    anyNA(deviation_check) ||
      max(abs(
        deviation_check$eta_reconstructed -
          deviation_check$equal_site_deviation_eta
      )) > 1e-8 ||
      max(abs(
        deviation_check$se_reconstructed -
          deviation_check$deviation_standard_error
      )) > 1e-8
  ) {
    h02_abort("Stored and reconstructed deviations disagree for %s", run_id)
  }

  critical <- stats::qnorm(0.975)
  common_curve <- tibble::tibble(
    time_hour = time_hour,
    eta = common_eta,
    standard_error_conditional = common_se,
    estimate_melEDI_lx = h02_inverse_transform(common_eta),
    pointwise_lower_melEDI_lx = h02_inverse_transform(
      common_eta - critical * common_se
    ),
    pointwise_upper_melEDI_lx = h02_inverse_transform(
      common_eta + critical * common_se
    )
  )
  participant_curves <- contributions$participant |>
    dplyr::left_join(
      common_curve |>
        dplyr::select("time_hour", common_eta = "eta"),
      by = "time_hour",
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      fitted_registry,
      by = "site",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      display_name = factor(
        .data$display_name,
        levels = display_levels
      ),
      fitted_melEDI_lx = h02_inverse_transform(
        .data$common_eta + .data$participant_eta
      )
    )
  site_curves <- predictions |>
    dplyr::left_join(
      fitted_registry,
      by = "site",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      display_name = factor(
        .data$display_name,
        levels = display_levels
      ),
      pointwise_lower_melEDI_lx = h02_inverse_transform(
        .data$eta - critical * .data$standard_error
      ),
      pointwise_upper_melEDI_lx = h02_inverse_transform(
        .data$eta + critical * .data$standard_error
      )
    ) |>
    dplyr::arrange(.data$display_order, .data$clock_bin)
  primary_deviations <- grid |>
    dplyr::transmute(
      site = as.character(.data$site),
      clock_bin = as.integer(round(.data$time_hour * 60 - 15)),
      time_hour = .data$time_hour,
      deviation_eta = .env$deviation_eta,
      standard_error = .env$deviation_se,
      lower_eta = .env$deviation_eta - critical * .env$deviation_se,
      upper_eta = .env$deviation_eta + critical * .env$deviation_se,
      ratio = 10^.env$deviation_eta,
      ratio_lower = 10^.data$lower_eta,
      ratio_upper = 10^.data$upper_eta,
      direction = dplyr::case_when(
        .data$ratio_lower > 1 ~ "higher",
        .data$ratio_upper < 1 ~ "lower",
        TRUE ~ "not_distinguishable"
      )
    ) |>
    dplyr::left_join(
      fitted_registry,
      by = "site",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      display_name = factor(
        .data$display_name,
        levels = display_levels
      )
    ) |>
    dplyr::arrange(.data$display_order, .data$clock_bin) |>
    dplyr::group_by(.data$site) |>
    dplyr::mutate(
      segment_start = dplyr::row_number() == 1L |
        .data$direction != dplyr::lag(
          .data$direction,
          default = dplyr::first(.data$direction)
        ),
      segment_id = cumsum(.data$segment_start)
    ) |>
    dplyr::ungroup()

  base <- readRDS(base_path)
  fitted_days <- frame |>
    dplyr::distinct(.data$site, .data$Id, .data$local_date)
  solar_days <- base |>
    dplyr::select(
      "site",
      "Id",
      "local_date",
      "civil_dawn_wall_minute",
      "civil_dusk_wall_minute"
    ) |>
    dplyr::distinct() |>
    dplyr::semi_join(
      fitted_days,
      by = c("site", "Id", "local_date")
    )
  if (
    nrow(solar_days) != nrow(fitted_days) ||
      anyNA(solar_days[c(
        "civil_dawn_wall_minute",
        "civil_dusk_wall_minute"
      )])
  ) {
    h02_abort("Civil dawn/dusk context is incomplete for %s", run_id)
  }
  site_solar <- solar_days |>
    dplyr::group_by(.data$site) |>
    dplyr::summarise(
      fitted_participant_days = dplyr::n(),
      mean_civil_dawn_hour = mean(.data$civil_dawn_wall_minute) / 60,
      mean_civil_dusk_hour = mean(.data$civil_dusk_wall_minute) / 60,
      .groups = "drop"
    ) |>
    dplyr::left_join(
      fitted_registry,
      by = "site",
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      display_name = factor(
        .data$display_name,
        levels = display_levels
      )
    ) |>
    dplyr::arrange(.data$display_order)
  overall_solar <- site_solar |>
    dplyr::summarise(
      mean_civil_dawn_hour = mean(.data$mean_civil_dawn_hour),
      mean_civil_dusk_hour = mean(.data$mean_civil_dusk_hour)
    )
  overall_night <- tibble::tibble(
    xmin = c(0, overall_solar$mean_civil_dusk_hour),
    xmax = c(overall_solar$mean_civil_dawn_hour, 24)
  )
  site_night <- site_solar |>
    dplyr::select(
      "site",
      "display_name",
      "display_order",
      "mean_civil_dawn_hour",
      "mean_civil_dusk_hour"
    ) |>
    tidyr::uncount(2L, .id = "night_segment") |>
    dplyr::mutate(
      xmin = dplyr::if_else(
        .data$night_segment == 1L,
        0,
        .data$mean_civil_dusk_hour
      ),
      xmax = dplyr::if_else(
        .data$night_segment == 1L,
        .data$mean_civil_dawn_hour,
        24
      )
    )
  background_site_curves <- tidyr::crossing(
    panel_display_name = factor(
      display_levels,
      levels = display_levels
    ),
    site_curves |>
      dplyr::transmute(
        source_site = .data$site,
        time_hour = .data$time_hour,
        estimate_melEDI_lx = .data$estimate_melEDI_lx,
        pointwise_lower_melEDI_lx = .data$pointwise_lower_melEDI_lx,
        pointwise_upper_melEDI_lx = .data$pointwise_upper_melEDI_lx
      )
  )

  list(
    run_id = run_id,
    placement_label = placement_label,
    participant_days = nrow(fitted_days),
    display_registry = fitted_registry,
    display_levels = display_levels,
    palette = palette,
    common_curve = common_curve,
    participant_curves = participant_curves,
    site_curves = site_curves,
    background_site_curves = background_site_curves,
    primary_deviations = primary_deviations,
    site_solar = site_solar,
    overall_solar = overall_solar,
    overall_night = overall_night,
    site_night = site_night
  )
}

h02_pointwise_windows <- function(contracts) {
  format_clock <- function(minutes) {
    ifelse(
      is.na(minutes),
      NA_character_,
      sprintf("%02d:%02d", (minutes %/% 60L) %% 24L, minutes %% 60L)
    )
  }
  dplyr::bind_rows(lapply(contracts, function(contract) {
    contract$primary_deviations |>
      dplyr::filter(.data$direction != "not_distinguishable") |>
      dplyr::group_by(
        .data$site,
        .data$display_order,
        .data$display_name,
        .data$segment_id,
        .data$direction
      ) |>
      dplyr::summarise(
        start_clock_bin = min(.data$clock_bin),
        end_clock_bin_exclusive = max(.data$clock_bin) + 30L,
        bins_30_minute = dplyr::n(),
        minimum_point_ratio = min(.data$ratio),
        maximum_point_ratio = max(.data$ratio),
        minimum_pointwise_lower = min(.data$ratio_lower),
        maximum_pointwise_upper = max(.data$ratio_upper),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        run_id = contract$run_id,
        placement = contract$placement_label,
        start_local_clock = format_clock(.data$start_clock_bin),
        end_local_clock = dplyr::if_else(
          .data$end_clock_bin_exclusive == 1440L,
          "24:00",
          format_clock(.data$end_clock_bin_exclusive)
        ),
        display_name = as.character(.data$display_name)
      ) |>
      dplyr::select(
        "run_id",
        "placement",
        "site",
        "display_order",
        "display_name",
        "direction",
        "start_clock_bin",
        "end_clock_bin_exclusive",
        "start_local_clock",
        "end_local_clock",
        "bins_30_minute",
        "minimum_point_ratio",
        "maximum_point_ratio",
        "minimum_pointwise_lower",
        "maximum_pointwise_upper"
      )
  })) |>
    dplyr::arrange(.data$run_id, .data$display_order, .data$start_clock_bin)
}

h02_build_figure4_layout <- function(contract) {
  horizontal_melEDI_guides <- c(1, 10, 100, 250, 1000)
  melEDI_breaks <- c(0, 1, 10, 100, 250, 1000)
  clock_breaks <- c(0, 6, 12, 18, 24)
  participant_day_label <- paste0(
    "n = ",
    format(contract$participant_days, big.mark = ","),
    " participant-days (d)"
  )
  figure_theme <- cowplot::theme_cowplot(font_size = 15) +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 12),
      axis.title = ggplot2::element_text(size = 14),
      panel.spacing = grid::unit(0.9, "lines"),
      legend.position = "none",
      plot.margin = ggplot2::margin(7, 7, 7, 7)
    )

  panel_a <- ggplot2::ggplot(
    contract$common_curve,
    ggplot2::aes(x = .data$time_hour)
  ) +
    ggplot2::geom_hline(
      yintercept = horizontal_melEDI_guides,
      colour = "grey70",
      linetype = "dashed",
      linewidth = 0.50
    ) +
    ggplot2::geom_rect(
      data = contract$overall_night,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax),
      ymin = -Inf,
      ymax = Inf,
      inherit.aes = FALSE,
      fill = "grey45",
      alpha = 0.18
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = .data$pointwise_lower_melEDI_lx,
        ymax = .data$pointwise_upper_melEDI_lx
      ),
      fill = "grey35",
      alpha = 0.34
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$estimate_melEDI_lx),
      linewidth = 1.25
    ) +
    ggplot2::annotate(
      "label",
      x = 23.4,
      y = 1150,
      label = participant_day_label,
      hjust = 1,
      size = 3.8,
      linewidth = 0.30,
      label.padding = grid::unit(0.13, "lines"),
      fill = "white",
      colour = "grey20"
    ) +
    ggplot2::scale_x_continuous(breaks = clock_breaks) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(),
      breaks = melEDI_breaks
    ) +
    ggplot2::coord_cartesian(
      xlim = c(0, 24),
      ylim = c(0, 1500),
      expand = FALSE
    ) +
    ggplot2::labs(
      x = "Local time (hrs)",
      y = paste0(contract$placement_label, " melEDI (lx)")
    ) +
    ggplot2::guides(
      y = ggplot2::guide_axis_stack(Brown_bracket, "axis")
    ) +
    figure_theme

  panel_b <- ggplot2::ggplot(
    contract$participant_curves,
    ggplot2::aes(
      x = .data$time_hour,
      y = .data$fitted_melEDI_lx,
      group = .data$participant,
      colour = .data$display_name
    )
  ) +
    ggplot2::geom_hline(
      yintercept = horizontal_melEDI_guides,
      colour = "grey70",
      linetype = "dashed",
      linewidth = 0.50
    ) +
    ggplot2::geom_rect(
      data = contract$overall_night,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax),
      ymin = -Inf,
      ymax = Inf,
      inherit.aes = FALSE,
      fill = "grey45",
      alpha = 0.18
    ) +
    ggplot2::geom_line(linewidth = 0.72, alpha = 0.42) +
    ggplot2::scale_colour_manual(values = contract$palette, drop = FALSE) +
    ggplot2::scale_x_continuous(breaks = clock_breaks) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(),
      breaks = melEDI_breaks
    ) +
    ggplot2::coord_cartesian(
      xlim = c(0, 24),
      ylim = c(0, 15000),
      expand = FALSE
    ) +
    ggplot2::labs(
      x = "Local time (hrs)",
      y = paste0(contract$placement_label, " melEDI (lx)")
    ) +
    ggplot2::guides(
      y = ggplot2::guide_axis_stack(Brown_bracket, "axis")
    ) +
    figure_theme

  panel_c_labels <- contract$display_registry |>
    dplyr::transmute(
      display_name = factor(
        .data$display_name,
        levels = contract$display_levels
      ),
      label = .data$display_name,
      x = 12,
      y = 4300
    )
  panel_c_sample_labels <- contract$site_solar |>
    dplyr::transmute(
      display_name = factor(
        .data$display_name,
        levels = contract$display_levels
      ),
      label = paste0(
        "n = ",
        format(.data$fitted_participant_days, big.mark = ","),
        " d"
      ),
      x = 15,
      y = 0.28
    )
  panel_c <- ggplot2::ggplot() +
    ggplot2::geom_hline(
      yintercept = horizontal_melEDI_guides,
      colour = "grey70",
      linetype = "dashed",
      linewidth = 0.45
    ) +
    ggplot2::geom_rect(
      data = contract$site_night,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax),
      ymin = -Inf,
      ymax = Inf,
      inherit.aes = FALSE,
      fill = "grey45",
      alpha = 0.18
    ) +
    ggplot2::geom_ribbon(
      data = contract$background_site_curves,
      ggplot2::aes(
        x = .data$time_hour,
        ymin = .data$pointwise_lower_melEDI_lx,
        ymax = .data$pointwise_upper_melEDI_lx,
        group = interaction(.data$panel_display_name, .data$source_site)
      ),
      fill = "grey70",
      alpha = 0.06
    ) +
    ggplot2::geom_line(
      data = contract$background_site_curves,
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$estimate_melEDI_lx,
        group = interaction(.data$panel_display_name, .data$source_site)
      ),
      colour = "grey70",
      linewidth = 0.45,
      alpha = 0.65
    ) +
    ggplot2::geom_ribbon(
      data = contract$site_curves,
      ggplot2::aes(
        x = .data$time_hour,
        ymin = .data$pointwise_lower_melEDI_lx,
        ymax = .data$pointwise_upper_melEDI_lx,
        fill = .data$display_name
      ),
      alpha = 0.34
    ) +
    ggplot2::geom_line(
      data = contract$site_curves,
      ggplot2::aes(x = .data$time_hour, y = .data$estimate_melEDI_lx),
      colour = "black",
      linewidth = 1.15
    ) +
    ggplot2::geom_label(
      data = panel_c_labels,
      ggplot2::aes(
        x = .data$x,
        y = .data$y,
        label = .data$label,
        colour = .data$display_name
      ),
      fill = "white",
      linewidth = 0.40,
      size = 4.0,
      label.padding = grid::unit(0.16, "lines"),
      show.legend = FALSE
    ) +
    ggplot2::geom_label(
      data = panel_c_sample_labels,
      ggplot2::aes(
        x = .data$x,
        y = .data$y,
        label = .data$label
      ),
      fill = "white",
      colour = "grey25",
      linewidth = 0.25,
      size = 3.15,
      hjust = 0.5,
      label.padding = grid::unit(0.10, "lines"),
      show.legend = FALSE
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$display_name),
      ncol = 3,
      drop = TRUE
    ) +
    ggplot2::scale_fill_manual(values = contract$palette, drop = FALSE) +
    ggplot2::scale_colour_manual(values = contract$palette, drop = FALSE) +
    ggplot2::scale_x_continuous(breaks = clock_breaks) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(),
      breaks = melEDI_breaks
    ) +
    ggplot2::coord_cartesian(
      xlim = c(0, 24),
      ylim = c(0, 10000),
      expand = FALSE
    ) +
    ggplot2::labs(
      x = "Local time (hrs)",
      y = paste0(contract$placement_label, " melEDI (lx)")
    ) +
    figure_theme +
    ggplot2::theme(
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_blank()
    )

  panel_d <- ggplot2::ggplot(
    contract$primary_deviations,
    ggplot2::aes(x = .data$time_hour, y = .data$ratio)
  ) +
    ggplot2::geom_hline(
      yintercept = c(0.1, 0.2, 0.5, 2, 5, 10),
      colour = "grey70",
      linetype = "dashed",
      linewidth = 0.45
    ) +
    ggplot2::geom_rect(
      data = contract$site_night,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax),
      ymin = -Inf,
      ymax = Inf,
      inherit.aes = FALSE,
      fill = "grey45",
      alpha = 0.18
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = .data$ratio_lower,
        ymax = .data$ratio_upper,
        fill = .data$display_name
      ),
      alpha = 0.34
    ) +
    ggplot2::geom_hline(
      yintercept = 1,
      linewidth = 1.0,
      linetype = "dashed"
    ) +
    ggplot2::geom_line(colour = "black", linewidth = 1.15) +
    ggplot2::geom_line(
      data = dplyr::filter(
        contract$primary_deviations,
        .data$direction != "not_distinguishable"
      ),
      ggplot2::aes(
        group = interaction(.data$display_name, .data$segment_id)
      ),
      colour = "red",
      linewidth = 1.50
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$display_name),
      ncol = 3,
      drop = TRUE
    ) +
    ggplot2::scale_fill_manual(values = contract$palette, drop = FALSE) +
    ggplot2::scale_x_continuous(breaks = clock_breaks) +
    ggplot2::scale_y_log10(
      breaks = c(0.1, 0.2, 0.5, 1, 2, 5, 10),
      labels = expression(10^{-1}, 5^{-1}, 2^{-1}, 1, 2, 5, 10)
    ) +
    ggplot2::coord_cartesian(
      xlim = c(0, 24),
      ylim = c(0.05, 20),
      expand = FALSE
    ) +
    ggplot2::labs(
      x = "Local time (hrs)",
      y = "Site / global time effect"
    ) +
    figure_theme +
    ggplot2::theme(
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_blank()
    )

  ((panel_a / panel_b) | (panel_c / panel_d)) +
    patchwork::plot_annotation(
      tag_levels = list(c("A", "C", "B", "D")),
      theme = ggplot2::theme(
        plot.tag = ggplot2::element_text(size = 19, face = "bold")
      )
    )
}
