h09_clock_labels <- function(hours) {
  total_minutes <- as.integer(((round(hours * 60) %% 1440) + 1440) %% 1440)
  sprintf("%02d:%02d", total_minutes %/% 60L, total_minutes %% 60L)
}

h09_atomic_write_csv <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  candidate <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path),
    fileext = ".csv"
  )
  on.exit(unlink(candidate), add = TRUE)
  write_data <- data
  numeric_columns <- vapply(write_data, is.numeric, logical(1))
  write_data[numeric_columns] <- lapply(
    write_data[numeric_columns],
    function(value) ifelse(is.na(value), NA_character_, sprintf("%.17g", value))
  )
  readr::write_csv(write_data, candidate, na = "")
  if (!file.rename(candidate, path)) {
    stop("Could not promote the paired figure source CSV", call. = FALSE)
  }
  invisible(path)
}

h09_atomic_save_plot <- function(plot, path, width, height, scale, device) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  candidate <- tempfile(
    pattern = paste0(tools::file_path_sans_ext(basename(path)), "."),
    tmpdir = dirname(path),
    fileext = paste0(".", tools::file_ext(path))
  )
  on.exit(unlink(candidate), add = TRUE)
  save_arguments <- list(
    filename = candidate,
    plot = plot,
    width = width,
    height = height,
    scale = scale,
    device = device,
    limitsize = FALSE
  )
  if (identical(tools::file_ext(path), "png")) {
    save_arguments$dpi <- 300
  }
  do.call(ggplot2::ggsave, save_arguments)
  if (!file.rename(candidate, path)) {
    stop("Could not promote a candidate figure", call. = FALSE)
  }
  invisible(path)
}

h09_prepare_observed_layers <- function(root) {
  paths <- list(
    frames = file.path(
      root,
      "results/intermediate/model_data/H09/H09_model_frames.rds"
    ),
    frame_index = file.path(
      root,
      "results/intermediate/model_data/H09/H09_model_frame_index.csv"
    ),
    metric_registry = file.path(
      root,
      "results/intermediate/model_data/H09/H09_metric_registry.csv"
    ),
    predictor_registry = file.path(
      root,
      "results/intermediate/model_data/H09/H09_predictor_registry.csv"
    ),
    model_bundles = file.path(
      root,
      "results/models/H09/H09_model_bundles.rds"
    ),
    results = file.path(
      root,
      "results/tables/H09/H09_model_results_master.csv"
    ),
    chronotype = file.path(
      root,
      "results/intermediate/model_data/normalized_inputs/chronotype.rds"
    ),
    site_registry = file.path(root, "config/site_display_registry.csv")
  )
  if (!all(file.exists(unlist(paths)))) {
    stop("A H09 figure input is missing", call. = FALSE)
  }

  read_h09_csv <- function(path) {
    readr::read_csv(
      path,
      show_col_types = FALSE,
      progress = FALSE,
      na = ""
    )
  }
  frame_index <- read_h09_csv(paths$frame_index)
  metric_registry <- read_h09_csv(paths$metric_registry)
  predictor_registry <- read_h09_csv(paths$predictor_registry)
  results <- read_h09_csv(paths$results)
  site_registry <- read_h09_csv(paths$site_registry)
  model_frames <- readRDS(paths$frames)
  model_bundles <- readRDS(paths$model_bundles)

  registered_metrics <- metric_registry |>
    filter(.data$primary_family_member) |>
    arrange(.data$metric_order)
  primary_index <- frame_index |>
    filter(
      .data$data_scenario_id == "primary",
      .data$placement == "glasses",
      .data$sample_scenario == "all_available",
      .data$metric_id %in% registered_metrics$metric_id,
      .data$instrument_id %in% predictor_registry$instrument_id
    )
  expected_pairs <- tidyr::crossing(
    metric_id = registered_metrics$metric_id,
    instrument_id = predictor_registry$instrument_id
  )
  observed_pairs <- primary_index |>
    select("metric_id", "instrument_id")
  if (
    nrow(primary_index) != 10L ||
      nrow(dplyr::anti_join(expected_pairs, observed_pairs, by = c(
        "metric_id",
        "instrument_id"
      ))) != 0L ||
      any(primary_index$availability != "ESTIMABLE") ||
      any(!primary_index$frame_id %in% names(model_frames)) ||
      any(!primary_index$frame_id %in% names(model_bundles))
  ) {
    stop("The ten primary near-eye registered frames are unavailable", call. = FALSE)
  }

  primary_results <- results |>
    filter(
      .data$data_scenario_id == "primary",
      .data$placement == "glasses",
      .data$sample_scenario == "all_available",
      .data$primary_family_member
    )
  supported_results <- primary_results |>
    filter(.data$main_adjusted_significant) |>
    arrange(
      match(.data$instrument_id, c("MCTQ", "MEQ")),
      .data$metric_order
    )
  point_layers <- vector("list", nrow(supported_results))
  line_layers <- vector("list", nrow(supported_results))
  for (i in seq_len(nrow(supported_results))) {
    result_row <- supported_results[i, , drop = FALSE]
    index_row <- primary_index |>
      filter(.data$frame_id == result_row$frame_id)
    predictor <- predictor_registry |>
      filter(.data$instrument_id == result_row$instrument_id)
    metric <- registered_metrics |>
      filter(.data$metric_id == result_row$metric_id)
    frame <- model_frames[[result_row$frame_id]]
    bundle <- model_bundles[[result_row$frame_id]]

    fit <- bundle$reml$M1_main$model
    if (!inherits(fit, "lmerMod") || stats::nobs(fit) != nrow(frame)) {
      stop("The selected REML main-effect fit is unavailable", call. = FALSE)
    }
    centered_column <- predictor$centered_column
    raw_column <- predictor$predictor_column
    fixed_effects <- lme4::fixef(fit)
    fixed_vcov <- as.matrix(stats::vcov(fit))
    if (
      !all(c("(Intercept)", centered_column) %in% names(fixed_effects)) ||
        abs(fixed_effects[[centered_column]] - result_row$estimate) > 1e-12
    ) {
      stop("Stored model slope does not equal the selected result", call. = FALSE)
    }
    stored_se <- sqrt(fixed_vcov[centered_column, centered_column])
    stored_ci <- result_row$estimate + stats::qnorm(c(0.025, 0.975)) * stored_se
    if (max(abs(stored_ci - c(result_row$conf_low, result_row$conf_high))) > 1e-12) {
      stop("Stored covariance does not reproduce the selected 95% CI", call. = FALSE)
    }
    site_contrasts <- stats::contrasts(frame$site)
    if (
      is.null(site_contrasts) ||
        max(abs(colSums(site_contrasts))) > 1e-12
    ) {
      stop("The selected model no longer uses equal-site sum contrasts", call. = FALSE)
    }

    predictor_value <- as.numeric(frame[[raw_column]])
    centered_value <- as.numeric(frame[[centered_column]])
    coefficient_scale <- if (result_row$instrument_id == "MCTQ") 1 else 10
    centering_constant <- stats::median(
      predictor_value - coefficient_scale * centered_value
    )
    reconstructed_centered <-
      (predictor_value - centering_constant) / coefficient_scale
    if (max(abs(reconstructed_centered - centered_value)) > 1e-12) {
      stop("The chronotype transformation is no longer affine", call. = FALSE)
    }

    point_layers[[i]] <- tibble::tibble(
      layer_role = "participant_day",
      frame_id = as.character(result_row$frame_id),
      source_row = as.numeric(seq_len(nrow(frame))),
      data_scenario_id = "primary",
      placement = "glasses",
      placement_label = "Near eye",
      instrument_order = ifelse(result_row$instrument_id == "MCTQ", 1, 2),
      instrument_id = as.character(result_row$instrument_id),
      instrument_name = as.character(predictor$instrument_name),
      predictor_value = predictor_value,
      predictor_centered_value = centered_value,
      predictor_unit = as.character(predictor$effect_unit),
      predictor_direction = as.character(predictor$effect_direction),
      metric_order = as.numeric(metric$metric_order),
      metric_id = as.character(metric$metric_id),
      metric_name = as.character(metric$manuscript_name),
      metric_abbreviation = as.character(metric$abbreviation),
      timing_hour = as.numeric(frame$timing_hour),
      timing_conf_low = NA_real_,
      timing_conf_high = NA_real_,
      timing_unit = "local clock hour",
      site = as.character(frame$site),
      participants = as.numeric(index_row$participants),
      participant_days = as.numeric(index_row$participant_days),
      observations = as.numeric(index_row$observations),
      main_p_adjusted = as.numeric(result_row$main_p_adjusted),
      fdr_supported = TRUE,
      prediction_scope = NA_character_
    ) |>
      left_join(
        site_registry |>
          transmute(
            site = as.character(.data$site),
            site_order = as.numeric(.data$display_order),
            site_name = as.character(.data$display_name),
            site_colour = as.character(.data$color_hex)
          ),
        by = "site",
        relationship = "many-to-one"
      )

    predictor_grid <- seq(
      min(predictor_value),
      max(predictor_value),
      length.out = 101L
    )
    centered_grid <-
      (predictor_grid - centering_constant) / coefficient_scale
    design <- cbind(1, centered_grid)
    selected_vcov <- fixed_vcov[
      c("(Intercept)", centered_column),
      c("(Intercept)", centered_column),
      drop = FALSE
    ]
    timing_fit <- fixed_effects[["(Intercept)"]] +
      fixed_effects[[centered_column]] * centered_grid
    timing_se <- sqrt(rowSums((design %*% selected_vcov) * design))
    line_layers[[i]] <- tibble::tibble(
      layer_role = "model_line",
      frame_id = as.character(result_row$frame_id),
      source_row = as.numeric(seq_along(predictor_grid)),
      data_scenario_id = "primary",
      placement = "glasses",
      placement_label = "Near eye",
      instrument_order = ifelse(result_row$instrument_id == "MCTQ", 1, 2),
      instrument_id = as.character(result_row$instrument_id),
      instrument_name = as.character(predictor$instrument_name),
      predictor_value = predictor_grid,
      predictor_centered_value = centered_grid,
      predictor_unit = as.character(predictor$effect_unit),
      predictor_direction = as.character(predictor$effect_direction),
      metric_order = as.numeric(metric$metric_order),
      metric_id = as.character(metric$metric_id),
      metric_name = as.character(metric$manuscript_name),
      metric_abbreviation = as.character(metric$abbreviation),
      timing_hour = timing_fit,
      timing_conf_low = timing_fit - stats::qnorm(0.975) * timing_se,
      timing_conf_high = timing_fit + stats::qnorm(0.975) * timing_se,
      timing_unit = "local clock hour",
      site = NA_character_,
      participants = as.numeric(index_row$participants),
      participant_days = as.numeric(index_row$participant_days),
      observations = as.numeric(index_row$observations),
      main_p_adjusted = as.numeric(result_row$main_p_adjusted),
      fdr_supported = TRUE,
      prediction_scope = "equal-site-average fixed effect; random effect zero",
      site_order = NA_real_,
      site_name = NA_character_,
      site_colour = NA_character_
    )
  }

  chronotype <- readRDS(paths$chronotype)
  if (anyDuplicated(chronotype[c("site", "Id")])) {
    stop("The participant-level chronotype input contains duplicate keys", call. = FALSE)
  }
  overview <- bind_rows(
    tibble::tibble(
      site = as.character(chronotype$site),
      private_order_key = as.character(chronotype$Id),
      instrument_order = 1,
      instrument_id = "MCTQ",
      instrument_name = "MCTQ MSFsc",
      predictor_value = as.numeric(chronotype$msf_sc) / 3600,
      predictor_unit = "hours",
      predictor_direction = "later corrected midsleep"
    ) |>
      filter(is.finite(.data$predictor_value)),
    tibble::tibble(
      site = as.character(chronotype$site),
      private_order_key = as.character(chronotype$Id),
      instrument_order = 2,
      instrument_id = "MEQ",
      instrument_name = "MEQ",
      predictor_value = as.numeric(chronotype$meq),
      predictor_unit = "score points",
      predictor_direction = "greater morning preference"
    ) |>
      filter(is.finite(.data$predictor_value))
  ) |>
    left_join(
      site_registry |>
        transmute(
          site = as.character(.data$site),
          site_order = as.numeric(.data$display_order),
          site_name = as.character(.data$display_name),
          site_colour = as.character(.data$color_hex)
        ),
      by = "site",
      relationship = "many-to-one"
    ) |>
    arrange(
      .data$instrument_order,
      .data$site_order,
      .data$predictor_value,
      .data$private_order_key
    ) |>
    group_by(.data$instrument_id) |>
    mutate(source_row = as.numeric(row_number())) |>
    ungroup()
  overview <- overview |>
    transmute(
      layer_role = "chronotype_participant",
      frame_id = NA_character_,
      source_row = .data$source_row,
      data_scenario_id = "primary",
      placement = "glasses",
      placement_label = "Near eye",
      instrument_order = as.numeric(.data$instrument_order),
      instrument_id = .data$instrument_id,
      instrument_name = .data$instrument_name,
      predictor_value = as.numeric(.data$predictor_value),
      predictor_centered_value = NA_real_,
      predictor_unit = .data$predictor_unit,
      predictor_direction = .data$predictor_direction,
      metric_order = NA_real_,
      metric_id = NA_character_,
      metric_name = NA_character_,
      metric_abbreviation = NA_character_,
      timing_hour = NA_real_,
      timing_conf_low = NA_real_,
      timing_conf_high = NA_real_,
      timing_unit = NA_character_,
      site = .data$site,
      participants = NA_real_,
      participant_days = NA_real_,
      observations = NA_real_,
      main_p_adjusted = NA_real_,
      fdr_supported = NA,
      prediction_scope = "descriptive participant-level distribution",
      site_order = as.numeric(.data$site_order),
      site_name = .data$site_name,
      site_colour = .data$site_colour
    )

  layers <- bind_rows(
    bind_rows(point_layers),
    bind_rows(line_layers),
    overview
  ) |>
    arrange(
      factor(
        .data$layer_role,
        levels = c("participant_day", "model_line", "chronotype_participant")
      ),
      .data$instrument_order,
      .data$metric_order,
      .data$site_order,
      .data$source_row
    )
  unique_keys <- paste(
    layers$layer_role,
    ifelse(is.na(layers$frame_id), "", layers$frame_id),
    layers$instrument_id,
    layers$source_row,
    sep = "|"
  )
  if (
    anyDuplicated(unique_keys) ||
      anyNA(layers$site_name[layers$layer_role != "model_line"])
  ) {
    stop("Invalid composite plotting layers", call. = FALSE)
  }
  layers
}

h09_make_observed_plot <- function(layers) {
  points <- layers |>
    filter(.data$layer_role == "participant_day")
  lines <- layers |>
    filter(.data$layer_role == "model_line")
  overview <- layers |>
    filter(.data$layer_role == "chronotype_participant")
  panel_order <- c(
    "MCTQ__m10_midpoint",
    "MCTQ__l10_midpoint",
    "MCTQ__first_timing_above_250",
    "MEQ__m10_midpoint",
    "MEQ__l10_midpoint",
    "MEQ__first_timing_above_250"
  )
  panel_labels <- c(
    MCTQ__m10_midpoint = "MCTQ MSFsc (hours)\nM10 midpoint",
    MCTQ__l10_midpoint = "MCTQ MSFsc (hours)\nL10 midpoint",
    MCTQ__first_timing_above_250 = "MCTQ MSFsc (hours)\nFirst >250",
    MEQ__m10_midpoint = "MEQ (score points)\nM10 midpoint",
    MEQ__l10_midpoint = "MEQ (score points)\nL10 midpoint",
    MEQ__first_timing_above_250 = "MEQ (score points)\nFirst >250"
  )
  site_lookup <- layers |>
    filter(!is.na(.data$site)) |>
    distinct(.data$site_order, .data$site_name, .data$site_colour) |>
    arrange(.data$site_order)
  site_colours <- stats::setNames(site_lookup$site_colour, site_lookup$site_name)
  site_shapes <- stats::setNames(
    c(16, 17, 15, 18, 3, 7, 8, 0, 2)[seq_len(nrow(site_lookup))],
    site_lookup$site_name
  )
  add_panel_factor <- function(data) {
    data |>
      mutate(
        panel_key = paste(.data$instrument_id, .data$metric_id, sep = "__"),
        panel = factor(
          panel_labels[.data$panel_key],
          levels = unname(panel_labels[panel_order])
        ),
        site_name = factor(.data$site_name, levels = site_lookup$site_name)
      )
  }
  points <- add_panel_factor(points)
  lines <- add_panel_factor(lines)

  dependency_plot <- ggplot2::ggplot(
    points,
    ggplot2::aes(
      x = .data$predictor_value,
      y = .data$timing_hour,
      colour = .data$site_name,
      shape = .data$site_name
    )
  ) +
    ggplot2::geom_point(alpha = 0.48, size = 1.8, stroke = 0.45) +
    ggplot2::geom_ribbon(
      data = lines,
      ggplot2::aes(
        x = .data$predictor_value,
        ymin = .data$timing_conf_low,
        ymax = .data$timing_conf_high
      ),
      inherit.aes = FALSE,
      fill = "grey55",
      alpha = 0.18
    ) +
    ggplot2::geom_line(
      data = lines,
      ggplot2::aes(x = .data$predictor_value, y = .data$timing_hour),
      inherit.aes = FALSE,
      colour = "black",
      linewidth = 0.75
    ) +
    ggplot2::facet_wrap(~panel, scales = "free", ncol = 3) +
    ggplot2::scale_colour_manual(
      values = site_colours,
      breaks = site_lookup$site_name,
      drop = FALSE
    ) +
    ggplot2::scale_shape_manual(
      values = site_shapes,
      breaks = site_lookup$site_name,
      drop = FALSE
    ) +
    ggplot2::scale_y_continuous(labels = h09_clock_labels) +
    ggplot2::labs(
      x = "Chronotype (instrument units)",
      y = "Local clock time",
      colour = "Study site",
      shape = "Study site"
    ) +
    ggplot2::guides(
      colour = ggplot2::guide_legend(
        nrow = 2,
        byrow = TRUE,
        override.aes = list(alpha = 1, size = 3)
      ),
      shape = ggplot2::guide_legend(nrow = 2, byrow = TRUE)
    ) +
    ggplot2::theme_bw(base_size = 17) +
    ggplot2::theme(
      legend.position = "bottom",
      strip.text = ggplot2::element_text(face = "bold", size = 15),
      axis.text = ggplot2::element_text(size = 17),
      axis.title = ggplot2::element_text(size = 17),
      legend.text = ggplot2::element_text(size = 17),
      legend.title = ggplot2::element_text(size = 17),
      panel.grid.minor = ggplot2::element_blank(),
      panel.spacing = grid::unit(10, "pt"),
      plot.margin = ggplot2::margin(10, 12, 10, 10)
    )

  overview <- overview |>
    mutate(
      overview_panel = factor(
        ifelse(
          .data$instrument_id == "MCTQ",
          "MCTQ MSFsc (hours)",
          "MEQ score"
        ),
        levels = c("MCTQ MSFsc (hours)", "MEQ score")
      ),
      site_name = factor(
        .data$site_name,
        levels = rev(site_lookup$site_name)
      )
    )
  overview_plot <- ggplot2::ggplot(
    overview,
    ggplot2::aes(
      x = .data$predictor_value,
      y = .data$site_name,
      colour = .data$site_name
    )
  ) +
    ggplot2::geom_boxplot(outlier.shape = NA, linewidth = 0.7) +
    ggplot2::geom_point(alpha = 0.48, size = 1.8) +
    ggplot2::facet_wrap(~overview_panel, scales = "free_x", ncol = 1) +
    ggplot2::scale_colour_manual(values = site_colours, drop = FALSE) +
    ggplot2::labs(x = "Chronotype", y = NULL) +
    ggplot2::theme_bw(base_size = 17) +
    ggplot2::theme(
      legend.position = "none",
      strip.text = ggplot2::element_text(face = "bold", size = 17),
      axis.text = ggplot2::element_text(size = 17),
      axis.title = ggplot2::element_text(size = 17),
      panel.grid.minor = ggplot2::element_blank(),
      panel.spacing = grid::unit(10, "pt"),
      plot.margin = ggplot2::margin(10, 10, 10, 8)
    )

  dependency_plot + overview_plot +
    patchwork::plot_layout(widths = c(3.2, 1.35)) +
    patchwork::plot_annotation(
      title = "Primary near-eye chronotype and light-exposure timing",
      subtitle = paste(
        "FDR-supported associations (left) and descriptive chronotype",
        "distributions by site (right)"
      ),
      tag_levels = "A",
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold", size = 20),
        plot.subtitle = ggplot2::element_text(size = 17),
        plot.tag = ggplot2::element_text(face = "bold", size = 17),
        plot.margin = ggplot2::margin(12, 14, 12, 12)
      )
    )
}

h09_build_observed_figure <- function(root, output_root) {
  layers <- h09_prepare_observed_layers(root)
  source_path <- file.path(
    output_root,
    "results/csv/source_data/H09/H09_observed_timing_patterns_data.csv"
  )
  png_path <- file.path(
    output_root,
    "results/images/H09/H09_observed_timing_patterns.png"
  )
  pdf_path <- file.path(
    output_root,
    "results/images/H09/H09_observed_timing_patterns.pdf"
  )
  h09_atomic_write_csv(layers, source_path)
  plotted_layers <- readr::read_csv(
    source_path,
    show_col_types = FALSE,
    progress = FALSE,
    na = ""
  )
  round_trip <- all.equal(
    as.data.frame(plotted_layers),
    as.data.frame(layers),
    tolerance = 1e-12,
    check.attributes = FALSE
  )
  if (!isTRUE(round_trip)) {
    stop("Paired source CSV failed its numerical round-trip check", call. = FALSE)
  }
  plot <- h09_make_observed_plot(plotted_layers)
  h09_atomic_save_plot(
    plot,
    png_path,
    width = 10.5,
    height = 8.5,
    scale = 1.5,
    device = ragg::agg_png
  )
  h09_atomic_save_plot(
    plot,
    pdf_path,
    width = 10.5,
    height = 8.5,
    scale = 1.5,
    device = grDevices::cairo_pdf
  )
  tibble::tibble(
    path = c(source_path, png_path, pdf_path),
    bytes = as.numeric(file.info(c(source_path, png_path, pdf_path))$size)
  )
}
