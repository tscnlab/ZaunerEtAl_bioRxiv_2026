#!/usr/bin/env Rscript

# Export two native H09 SVG trials from the two frozen paired source CSVs.

options(stringsAsFactors = FALSE, warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

required_packages <- c(
  digest = "0.6.39",
  dplyr = "1.2.1",
  ggplot2 = "4.0.3",
  patchwork = "1.3.2",
  readr = "2.2.0",
  svglite = "2.2.2",
  tidyr = "1.3.2"
)
missing_packages <- names(required_packages)[
  !vapply(
    names(required_packages),
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages)) {
  stop(
    "Missing pinned display package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}
observed_versions <- vapply(
  names(required_packages),
  function(package) as.character(utils::packageVersion(package)),
  character(1)
)
assert_true(
  identical(unname(observed_versions), unname(required_packages)),
  "An installed display package does not match its Order72j pin."
)
assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("Order72j requires R 4.6.1, found %s.", getRversion())
)

suppressPackageStartupMessages(library(dplyr))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

normalize_roots <- function() {
  configured_project_root <- Sys.getenv("H09_ORDER72J_PROJECT_ROOT", unset = "")
  configured_owner_root <- Sys.getenv("H09_ORDER72J_OWNER_ROOT", unset = "")
  assert_true(
    nzchar(configured_project_root) && nzchar(configured_owner_root),
    "Both Order72j root environment variables must be explicit."
  )
  project_root <- normalizePath(
    configured_project_root,
    winslash = "/",
    mustWork = TRUE
  )
  owner_root <- normalizePath(
    configured_owner_root,
    winslash = "/",
    mustWork = TRUE
  )
  expected_owner_root <- file.path(
    project_root,
    "audit/hypotheses/H09/report018_order72j_split_svg_export"
  )
  assert_true(
    identical(owner_root, expected_owner_root),
    "The write root is not the sole Order72j H09 owner root."
  )
  list(project_root = project_root, owner_root = owner_root)
}

validate_output_path <- function(path, owner_root) {
  parent <- normalizePath(dirname(path), winslash = "/", mustWork = TRUE)
  owner_prefix <- paste0(owner_root, "/")
  assert_true(
    startsWith(paste0(parent, "/"), owner_prefix),
    "An SVG output path escapes the sole Order72j H09 owner root."
  )
  assert_true(
    identical(tolower(tools::file_ext(path)), "svg"),
    "Every export trial must be a native SVG."
  )
  invisible(path)
}

read_frozen_display_inputs <- function(project_root) {
  paths <- c(
    primary = file.path(
      project_root,
      "artifacts/11_source_data/H09/H09_primary_effects_data.csv"
    ),
    observed = file.path(
      project_root,
      "artifacts/11_source_data/H09/H09_observed_timing_patterns_data.csv"
    )
  )
  expected_hashes <- c(
    primary = "3972ae75c9aef8551cc85f50d7a438b35b7a55dca58d81f3630133132a25aaf6",
    observed = "34640aba210181b973902e00cd6924f79f6ae76faf01fa3c5b66078e2e2e7cee"
  )
  expected_bytes <- c(primary = 6778, observed = 3028981)
  assert_all(file.exists(paths), "A frozen H09 display CSV is missing.")
  actual_hashes <- vapply(paths, sha256_file, character(1))
  actual_bytes <- unname(file.info(paths)$size)
  assert_true(
    identical(unname(actual_hashes), unname(expected_hashes)) &&
      identical(as.numeric(actual_bytes), as.numeric(expected_bytes)),
    "A frozen H09 display CSV does not match its Order72j pin."
  )
  list(
    paths = paths,
    expected_hashes = expected_hashes,
    expected_bytes = expected_bytes,
    primary = readr::read_csv(
      paths[["primary"]],
      show_col_types = FALSE,
      progress = FALSE,
      na = ""
    ),
    observed = readr::read_csv(
      paths[["observed"]],
      show_col_types = FALSE,
      progress = FALSE,
      na = ""
    )
  )
}

prepare_primary_plot_data <- function(data) {
  expected_columns <- c(
    "metric_order",
    "metric_id",
    "manuscript_name",
    "metric_label",
    "instrument_id",
    "instrument_name",
    "instrument_label",
    "effect_unit",
    "placement",
    "placement_label",
    "participants",
    "participant_days",
    "observations",
    "sites",
    "derivation_hours",
    "estimate",
    "std_error",
    "conf_low",
    "conf_high",
    "main_p_raw",
    "main_p_adjusted",
    "main_adjusted_significant",
    "main_family_id"
  )
  assert_true(
    identical(names(data), expected_columns) && nrow(data) == 20L,
    "The frozen primary-effects CSV has an unexpected schema or row count."
  )
  expected_metrics <- data.frame(
    metric_order = as.numeric(1:5),
    metric_id = c(
      "m10_midpoint",
      "l10_midpoint",
      "first_timing_above_250",
      "last_timing_above_250",
      "longest_period_midpoint"
    ),
    manuscript_name = c(
      "Midpoint of the brightest 10 hours",
      "Midpoint of the darkest 10 hours",
      "First light timing above 250 lx melEDI",
      "Last light timing above 250 lx melEDI",
      "Midpoint of the longest continuous period above 250 lx melEDI"
    ),
    metric_label = c(
      "M10 midpoint",
      "L10 midpoint",
      "First >250",
      "Last >250",
      "Longest-period midpoint"
    ),
    stringsAsFactors = FALSE
  )
  observed_metrics <- data |>
    dplyr::distinct(
      .data$metric_order,
      .data$metric_id,
      .data$manuscript_name,
      .data$metric_label
    ) |>
    dplyr::arrange(.data$metric_order) |>
    as.data.frame()
  assert_true(
    identical(observed_metrics, expected_metrics),
    "The primary metric order or label mapping changed."
  )
  expected_grid <- tidyr::expand_grid(
    metric_id = expected_metrics$metric_id,
    instrument_id = c("MCTQ", "MEQ"),
    placement = c("glasses", "chest")
  )
  observed_grid <- data |>
    dplyr::select("metric_id", "instrument_id", "placement")
  assert_true(
    nrow(dplyr::anti_join(
      expected_grid,
      observed_grid,
      by = c("metric_id", "instrument_id", "placement")
    )) ==
      0L &&
      !anyDuplicated(observed_grid),
    "The primary metric, instrument, and placement key set changed."
  )
  assert_true(
    identical(sort(unique(data$instrument_label)), c("MCTQ MSFsc", "MEQ")) &&
      identical(sort(unique(data$placement_label)), c("Chest", "Near eye")),
    "A primary instrument or placement label changed."
  )
  assert_all(
    is.finite(data$estimate) &
      is.finite(data$conf_low) &
      is.finite(data$conf_high) &
      data$conf_low <= data$estimate &
      data$estimate <= data$conf_high,
    "A primary estimate or interval is unavailable or invalid."
  )
  metric_levels <- observed_metrics$metric_label
  data |>
    dplyr::mutate(
      metric_label = factor(.data$metric_label, levels = rev(metric_levels)),
      instrument_label = factor(
        .data$instrument_label,
        levels = c("MCTQ MSFsc", "MEQ")
      ),
      placement_label = factor(
        .data$placement_label,
        levels = c("Near eye", "Chest")
      )
    )
}

validate_observed_plot_data <- function(layers) {
  expected_columns <- c(
    "layer_role",
    "frame_id",
    "source_row",
    "data_scenario_id",
    "placement",
    "placement_label",
    "instrument_order",
    "instrument_id",
    "instrument_name",
    "predictor_value",
    "predictor_centered_value",
    "predictor_unit",
    "predictor_direction",
    "metric_order",
    "metric_id",
    "metric_name",
    "metric_abbreviation",
    "timing_hour",
    "timing_conf_low",
    "timing_conf_high",
    "timing_unit",
    "site",
    "participants",
    "participant_days",
    "observations",
    "main_p_adjusted",
    "fdr_supported",
    "prediction_scope",
    "row_key_hash",
    "model_frame_hash",
    "source_artifact_sha256",
    "site_order",
    "site_name",
    "site_colour"
  )
  assert_true(
    identical(names(layers), expected_columns) && nrow(layers) == 5678L,
    "The observed-pattern CSV has an unexpected schema or row count."
  )
  expected_roles <- c(
    chronotype_participant = 371L,
    model_line = 606L,
    participant_day = 4701L
  )
  observed_roles <- table(layers$layer_role)
  assert_true(
    identical(
      as.integer(observed_roles[names(expected_roles)]),
      unname(expected_roles)
    ),
    "The observed-pattern layer-role counts changed."
  )
  panel_keys <- layers |>
    dplyr::filter(.data$layer_role != "chronotype_participant") |>
    dplyr::transmute(
      panel_key = paste(.data$instrument_id, .data$metric_id, sep = "__")
    ) |>
    dplyr::distinct() |>
    dplyr::arrange(.data$panel_key) |>
    dplyr::pull(.data$panel_key)
  expected_panel_keys <- sort(c(
    "MCTQ__m10_midpoint",
    "MCTQ__l10_midpoint",
    "MCTQ__first_timing_above_250",
    "MEQ__m10_midpoint",
    "MEQ__l10_midpoint",
    "MEQ__first_timing_above_250"
  ))
  assert_true(
    identical(panel_keys, expected_panel_keys),
    "The six observed association panels changed."
  )
  expected_sites <- data.frame(
    site_order = as.numeric(1:9),
    site = c(
      "RISE",
      "THUAS",
      "BAUA",
      "MPI",
      "TUM",
      "FUSPCEU",
      "IZTECH",
      "UCR",
      "KNUST"
    ),
    site_name = c(
      "Borås (SE)",
      "Delft (NL)",
      "Dortmund (DE)",
      "Tübingen (DE)",
      "Munich (DE)",
      "Madrid (ES)",
      "Izmir (TR)",
      "San José (CR)",
      "Kumasi (GH)"
    ),
    site_colour = c(
      "#88CCEE",
      "#117733",
      "#DDCC77",
      "#DDCC77",
      "#DDCC77",
      "#CC6677",
      "#332288",
      "#44AA99",
      "#AA4499"
    ),
    stringsAsFactors = FALSE
  )
  observed_sites <- layers |>
    dplyr::filter(!is.na(.data$site)) |>
    dplyr::distinct(
      .data$site_order,
      .data$site,
      .data$site_name,
      .data$site_colour
    ) |>
    dplyr::arrange(.data$site_order) |>
    as.data.frame()
  assert_true(
    identical(observed_sites, expected_sites),
    "The accepted site order, labels, codes, or colours changed."
  )
  points <- layers |> dplyr::filter(.data$layer_role == "participant_day")
  lines <- layers |> dplyr::filter(.data$layer_role == "model_line")
  overview <- layers |>
    dplyr::filter(.data$layer_role == "chronotype_participant")
  assert_true(
    all(points$fdr_supported) &&
      all(lines$fdr_supported) &&
      all(is.na(overview$fdr_supported)) &&
      all(
        lines$prediction_scope ==
          "equal-site-average fixed effect; random effect zero"
      ) &&
      all(
        overview$prediction_scope ==
          "descriptive participant-level distribution"
      ),
    "An accepted display state or prediction scope changed."
  )
  assert_all(
    is.finite(points$predictor_value) & is.finite(points$timing_hour),
    "An observed participant-day point is unavailable."
  )
  assert_all(
    is.finite(lines$predictor_value) &
      is.finite(lines$timing_hour) &
      is.finite(lines$timing_conf_low) &
      is.finite(lines$timing_conf_high) &
      lines$timing_conf_low <= lines$timing_hour &
      lines$timing_hour <= lines$timing_conf_high,
    "An observed model line or interval is unavailable or invalid."
  )
  assert_true(
    !any(c("Id", "participant_key", "private_order_key") %in% names(layers)),
    "The frozen display CSV unexpectedly exposes a participant identifier."
  )
  layers
}

# Preserve the accepted builder geometry while containing its ggplot2 4.0
# lifecycle warning inside this exact historical-display reconstruction.
geom_errorbarh_frozen <- function(...) {
  suppressWarnings(ggplot2::geom_errorbarh(...))
}

make_primary_plot <- function(data, theme_mode) {
  plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data$estimate,
      y = .data$metric_label,
      colour = .data$placement_label,
      shape = .data$placement_label
    )
  ) +
    ggplot2::geom_vline(
      xintercept = 0,
      colour = "grey55",
      linewidth = 0.45
    ) +
    geom_errorbarh_frozen(
      ggplot2::aes(xmin = .data$conf_low, xmax = .data$conf_high),
      height = 0.12,
      position = ggplot2::position_dodge(width = 0.42),
      linewidth = 0.7
    ) +
    ggplot2::geom_point(
      position = ggplot2::position_dodge(width = 0.42),
      size = 2.8,
      stroke = 0.9
    ) +
    ggplot2::facet_wrap(~instrument_label, scales = "free_x", nrow = 1) +
    ggplot2::scale_colour_manual(
      values = c("Near eye" = "#0072B2", "Chest" = "#D55E00")
    ) +
    ggplot2::scale_shape_manual(values = c("Near eye" = 16, "Chest" = 17)) +
    ggplot2::labs(
      x = "Difference in local exposure timing (hours)",
      y = NULL,
      colour = "Placement",
      shape = "Placement"
    ) +
    ggplot2::theme_bw(base_size = 14) +
    ggplot2::theme(
      legend.position = "top",
      strip.text = ggplot2::element_text(face = "bold", size = 14),
      axis.text = ggplot2::element_text(size = 12),
      axis.title = ggplot2::element_text(size = 14),
      panel.grid.minor = ggplot2::element_blank()
    )

  if (theme_mode == "repaired") {
    plot <- plot +
      ggplot2::theme(
        text = ggplot2::element_text(size = 17),
        legend.text = ggplot2::element_text(size = 17),
        legend.title = ggplot2::element_text(size = 17),
        strip.text = ggplot2::element_text(face = "bold", size = 17),
        axis.text = ggplot2::element_text(size = 17),
        axis.title = ggplot2::element_text(size = 17),
        panel.spacing = grid::unit(12, "pt"),
        plot.margin = ggplot2::margin(12, 16, 12, 12)
      )
  }
  plot
}

h09_clock_labels <- function(hours) {
  total_minutes <- as.integer(((round(hours * 60) %% 1440) + 1440) %% 1440)
  sprintf("%02d:%02d", total_minutes %/% 60L, total_minutes %% 60L)
}

h09_make_stage3_observed_plot <- function(layers) {
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
  site_colours <- stats::setNames(
    site_lookup$site_colour,
    site_lookup$site_name
  )
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
      strip.text = ggplot2::element_text(face = "bold", size = 17),
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

  dependency_plot +
    overview_plot +
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

build_frozen_plots <- function(inputs) {
  primary <- prepare_primary_plot_data(inputs$primary)
  observed <- validate_observed_plot_data(inputs$observed)
  list(
    primary_data = primary,
    observed_data = observed,
    primary_plot = make_primary_plot(primary, theme_mode = "repaired"),
    observed_plot = h09_make_stage3_observed_plot(observed)
  )
}

export_svg_trials <- function(plots, owner_root) {
  trial_dir <- file.path(owner_root, "attempts", "trial_01")
  candidate_dir <- file.path(owner_root, "candidate")
  assert_true(
    !dir.exists(trial_dir),
    "The single allowed trial directory already exists."
  )
  assert_true(
    dir.exists(candidate_dir) &&
      length(list.files(candidate_dir, all.files = TRUE, no.. = TRUE)) == 0L,
    "The candidate directory must be empty before the single export trial."
  )
  dir.create(trial_dir, recursive = FALSE, showWarnings = FALSE)
  assert_true(dir.exists(trial_dir), "Could not create the trial directory.")
  primary_path <- file.path(trial_dir, "H09_primary_effects.svg")
  observed_path <- file.path(trial_dir, "H09_observed_timing_patterns.svg")
  validate_output_path(primary_path, owner_root)
  validate_output_path(observed_path, owner_root)

  ggplot2::ggsave(
    filename = primary_path,
    plot = plots$primary_plot,
    width = 10.5,
    height = 6.5,
    scale = 1.5,
    device = svglite::svglite,
    limitsize = FALSE
  )
  ggplot2::ggsave(
    filename = observed_path,
    plot = plots$observed_plot,
    width = 10.5,
    height = 8.5,
    scale = 1.5,
    device = svglite::svglite,
    limitsize = FALSE
  )
  assert_all(
    file.exists(c(primary_path, observed_path)) &
      file.info(c(primary_path, observed_path))$size > 0,
    "A native SVG trial was not created."
  )
  invisible(c(primary = primary_path, observed = observed_path))
}

h09_order72j_main <- function() {
  arguments <- commandArgs(trailingOnly = TRUE)
  assert_true(
    length(arguments) == 1L && arguments %in% c("preflight", "export"),
    "Supply exactly one mode: `preflight` or `export`."
  )
  roots <- normalize_roots()
  inputs <- read_frozen_display_inputs(roots$project_root)
  plots <- build_frozen_plots(inputs)
  if (identical(arguments, "export")) {
    paths <- export_svg_trials(plots, roots$owner_root)
    cat(sprintf(
      "ORDER72J_H09_EXPORT=PASS primary=%s observed=%s\n",
      sha256_file(paths[["primary"]]),
      sha256_file(paths[["observed"]])
    ))
  } else {
    cat(sprintf(
      "ORDER72J_H09_PREFLIGHT=PASS primary_rows=%d observed_rows=%d\n",
      nrow(plots$primary_data),
      nrow(plots$observed_data)
    ))
  }
}

if (sys.nframe() == 0L) {
  h09_order72j_main()
}
