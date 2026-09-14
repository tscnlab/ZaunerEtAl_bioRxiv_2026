#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
stopifnot(dir.exists(project_library))
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(svglite)
  library(tibble)
  library(tidyr)
})

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  Sys.getenv("RENV_CONFIG_AUTOLOADER_ENABLED", unset = "") == "FALSE"
)

owner_relative <-
  "audit/hypotheses/H07/report018_order72j_split_svg_export"
owner_root <- normalizePath(
  file.path(root, owner_relative),
  winslash = "/",
  mustWork = TRUE
)
attempt_dir <- file.path(owner_root, "attempts", "attempt_01")
evidence_dir <- file.path(owner_root, "evidence")
stopifnot(dir.exists(attempt_dir), dir.exists(evidence_dir))

attempt_name <- "H07_revised_smooth_derivative_pairs_near_eye.svg"
attempt_path <- file.path(attempt_dir, attempt_name)
candidate_path <- file.path(owner_root, "candidate", attempt_name)
stopifnot(!file.exists(attempt_path), !file.exists(candidate_path))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

write_evidence <- function(object, filename) {
  target <- normalizePath(
    file.path(evidence_dir, filename),
    winslash = "/",
    mustWork = FALSE
  )
  if (!startsWith(target, paste0(owner_root, "/"))) {
    stop("Attempted write outside the Order72j H07 owner root", call. = FALSE)
  }
  utils::write.csv(
    object,
    target,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

input_paths <- c(
  curves = "artifacts/09_tables/H07/H07_main_curve_points.csv",
  derivatives = "artifacts/09_tables/H07/H07_revised_derivative_points.csv",
  plateaus = "artifacts/09_tables/H07/H07_revised_plateau_summary.csv",
  rugs = "artifacts/09_tables/H07/H07_revised_derivative_photoperiod_rows.csv",
  settings = "artifacts/09_tables/H07/H07_revised_paired_figure_settings.csv",
  metric_registry = "artifacts/06_model_data/H05/H05_metric_registry.csv"
)
input_hashes <- c(
  curves = "e92a5a89e0eda37c57de0dfa6a68d2e8c4f08b08d0ebfab5e7f2c332c9bdb034",
  derivatives = "8fd527ef2800217e78d4de4ce9dc55246dfd301f6a85b47cbfa91236131540e4",
  plateaus = "e8ad47e76a8386fea3a9115cab2f0d477700ac55d82cc4133bd712d377fa15c1",
  rugs = "541dc9f86fcb7bd4740016815c988d05a6d69580af41d1e941fae46085f849cb",
  settings = "e7fe343dca5b2d10efce3cea245f95f52bfbd27f997933346c50696b949ee4e2",
  metric_registry = "25a3df408dad73b657ea1ee20631195c93fe33340fafa7250ed6e76727c65bb7"
)
input_files <- stats::setNames(
  file.path(root, unname(input_paths)),
  names(input_paths)
)
observed_hashes <- vapply(input_files, sha256_file, character(1))
stopifnot(identical(unname(observed_hashes), unname(input_hashes)))

input_use <- data.frame(
  input = names(input_paths),
  path = unname(input_paths),
  expected_sha256 = unname(input_hashes),
  observed_sha256 = unname(observed_hashes),
  bytes = as.numeric(file.info(input_files)$size),
  role = c(
    "frozen fitted response-scale points",
    "frozen model-scale derivative points and intervals",
    "frozen qualifying-transition annotations",
    "frozen observed photoperiod rug rows",
    "frozen accepted canvas and method settings",
    "frozen metric labels and display units"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_evidence(input_use, "attempt_01_input_use.csv")

read_input <- function(name) {
  readr::read_csv(input_files[[name]], show_col_types = FALSE, na = "")
}

curve_points <- read_input("curves")
derivative_points_all <- read_input("derivatives")
plateau_summary_all <- read_input("plateaus")
photoperiod_rows <- read_input("rugs")
figure_settings <- read_input("settings")
metric_registry <- read_input("metric_registry")

metric_source_map <- tibble::tribble(
  ~metric_order, ~metric_id,
  1L, "daily_geometric_mean_medi",
  2L, "m10_mean_medi",
  3L, "l10_mean_medi",
  4L, "duration_above_1000",
  5L, "duration_above_250_wake",
  6L, "duration_below_10_pre_sleep",
  7L, "duration_below_1_sleep_environment",
  8L, "longest_bout_above_250",
  9L, "dose_time_sensitive_corrected_medi"
)
metric_ids <- metric_source_map$metric_id
primary_derivative_method <- "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE"
panel_levels <- c("Fitted metric value", "First derivative")

metric_display <- metric_registry |>
  dplyr::filter(.data$metric_id %in% .env$metric_ids) |>
  dplyr::select("metric_id", "manuscript_name", "display_unit") |>
  dplyr::inner_join(metric_source_map, by = "metric_id") |>
  dplyr::arrange(.data$metric_order)
stopifnot(
  nrow(metric_display) == 9L,
  identical(metric_display$metric_id, metric_ids),
  !anyNA(metric_display$manuscript_name),
  !anyNA(metric_display$display_unit)
)

label_sources <- dplyr::bind_rows(
  curve_points |>
    dplyr::distinct(.data$metric_id, .data$manuscript_name),
  derivative_points_all |>
    dplyr::distinct(.data$metric_id, .data$manuscript_name),
  plateau_summary_all |>
    dplyr::distinct(.data$metric_id, .data$manuscript_name),
  photoperiod_rows |>
    dplyr::distinct(.data$metric_id, .data$manuscript_name)
) |>
  dplyr::distinct()
label_check <- label_sources |>
  dplyr::filter(.data$metric_id %in% .env$metric_ids) |>
  dplyr::left_join(
    metric_display |>
      dplyr::select(
        "metric_id",
        registry_name = "manuscript_name"
      ),
    by = "metric_id"
  )
stopifnot(
  nrow(label_check) == 9L,
  all(label_check$manuscript_name == label_check$registry_name)
)

derivative_points <- derivative_points_all |>
  dplyr::filter(.data$method_id == .env$primary_derivative_method)
plateau_summary <- plateau_summary_all |>
  dplyr::filter(.data$method_id == .env$primary_derivative_method)

expected_pairs <- tidyr::crossing(
  placement = c("near_eye", "chest"),
  metric_id = metric_ids
)
stopifnot(
  nrow(derivative_points) == 1800L,
  nrow(plateau_summary) == 18L,
  nrow(dplyr::distinct(curve_points, .data$placement, .data$metric_id)) ==
    nrow(expected_pairs),
  nrow(dplyr::distinct(derivative_points, .data$placement, .data$metric_id)) ==
    nrow(expected_pairs),
  nrow(dplyr::distinct(plateau_summary, .data$placement, .data$metric_id)) ==
    nrow(expected_pairs),
  nrow(dplyr::distinct(photoperiod_rows, .data$placement, .data$metric_id)) ==
    nrow(expected_pairs)
)

facet_registry <- tidyr::crossing(
  metric_id = metric_ids,
  panel_kind = factor(panel_levels, levels = panel_levels)
) |>
  dplyr::left_join(metric_display, by = "metric_id") |>
  dplyr::arrange(.data$metric_order, .data$panel_kind) |>
  dplyr::mutate(
    facet_label = dplyr::if_else(
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
  dplyr::mutate(
    facet_label = factor(.data$facet_label, levels = .env$facet_levels)
  )

recorded_ranges <- derivative_points |>
  dplyr::group_by(.data$placement, .data$metric_id) |>
  dplyr::summarise(
    recorded_min = min(.data$photoperiod_hours),
    recorded_max = max(.data$photoperiod_hours),
    .groups = "drop"
  )

smooth_source_frame <- curve_points |>
  dplyr::inner_join(recorded_ranges, by = c("placement", "metric_id")) |>
  dplyr::filter(
    .data$photoperiod_hours >= .data$recorded_min,
    .data$photoperiod_hours <= .data$recorded_max
  ) |>
  dplyr::transmute(
    placement = .data$placement,
    metric_id = .data$metric_id,
    metric_order = .data$metric_order,
    panel_kind = "Fitted metric value",
    photoperiod_hours = .data$photoperiod_hours,
    estimate = .data$response_estimate,
    lower = .data$response_lower_pointwise,
    upper = .data$response_upper_pointwise
  )

derivative_source_frame <- derivative_points |>
  dplyr::transmute(
    placement = .data$placement,
    metric_id = .data$metric_id,
    metric_order = .data$metric_order,
    panel_kind = "First derivative",
    photoperiod_hours = .data$photoperiod_hours,
    estimate = .data$derivative_estimate,
    lower = .data$derivative_lower,
    upper = .data$derivative_upper
  )

paired_points <- dplyr::bind_rows(
  smooth_source_frame,
  derivative_source_frame
) |>
  dplyr::left_join(
    facet_registry |>
      dplyr::select("metric_id", "panel_kind", "facet_label"),
    by = c("metric_id", "panel_kind")
  )

rug_points <- photoperiod_rows |>
  dplyr::mutate(panel_kind = "Fitted metric value") |>
  dplyr::left_join(
    facet_registry |>
      dplyr::select("metric_id", "panel_kind", "facet_label"),
    by = c("metric_id", "panel_kind")
  )

transition_rectangles <- tidyr::crossing(
  plateau_summary |>
    dplyr::filter(.data$revised_plateau_pattern),
  panel_kind = panel_levels
) |>
  dplyr::left_join(
    facet_registry |>
      dplyr::select("metric_id", "panel_kind", "facet_label"),
    by = c("metric_id", "panel_kind")
  )

stopifnot(
  !anyNA(paired_points$facet_label),
  !anyNA(rug_points$facet_label),
  !anyNA(transition_rectangles$facet_label),
  nrow(dplyr::distinct(paired_points, .data$placement, .data$facet_label)) == 36L
)

placement_value <- "near_eye"
placement_title <- "Near-eye — primary"
plot_points <- paired_points |>
  dplyr::filter(.data$placement == .env$placement_value)
plot_rug <- rug_points |>
  dplyr::filter(.data$placement == .env$placement_value)
plot_transitions <- transition_rectangles |>
  dplyr::filter(.data$placement == .env$placement_value)
derivative_zero_lines <- facet_registry |>
  dplyr::filter(.data$panel_kind == "First derivative") |>
  dplyr::transmute(.data$facet_label, yintercept = 0)

near_setting <- figure_settings |>
  dplyr::filter(.data$placement == .env$placement_value)
stopifnot(
  nrow(near_setting) == 1L,
  near_setting$filename ==
    "H07_revised_smooth_derivative_pairs_near_eye.png",
  near_setting$arrangement ==
    "nine rows; fitted value left and first derivative right",
  near_setting$width_in == 9,
  near_setting$height_in == 18,
  near_setting$derivative_method == primary_derivative_method,
  near_setting$interval ==
    "unconditional pointwise 95% confidence interval"
)

plot <- ggplot2::ggplot(
  plot_points,
  ggplot2::aes(.data$photoperiod_hours, .data$estimate)
) +
  ggplot2::geom_rect(
    data = plot_transitions,
    ggplot2::aes(
      xmin = .data$plateau_start,
      xmax = .data$recorded_photoperiod_max,
      ymin = -Inf,
      ymax = Inf
    ),
    inherit.aes = FALSE,
    fill = "#56B4E9",
    alpha = 0.12
  ) +
  ggplot2::geom_hline(
    data = derivative_zero_lines,
    ggplot2::aes(yintercept = .data$yintercept),
    inherit.aes = FALSE,
    colour = "#4b5563",
    linewidth = 0.4
  ) +
  ggplot2::geom_ribbon(
    ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
    fill = "#9ca3af",
    alpha = 0.24,
    colour = NA
  ) +
  ggplot2::geom_line(colour = "#111827", linewidth = 0.7) +
  ggplot2::geom_vline(
    data = plot_transitions,
    ggplot2::aes(xintercept = .data$plateau_start),
    inherit.aes = FALSE,
    colour = "#0072B2",
    linewidth = 0.6,
    linetype = 2
  ) +
  ggplot2::geom_rug(
    data = plot_rug,
    ggplot2::aes(x = .data$photoperiod_hours),
    inherit.aes = FALSE,
    sides = "b",
    alpha = 0.035,
    linewidth = 0.22
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$facet_label),
    ncol = 2,
    scales = "free_y",
    axes = "all_x",
    axis.labels = "all_x",
    drop = FALSE
  ) +
  ggplot2::scale_x_continuous(
    breaks = seq(10, 20, by = 2),
    expand = ggplot2::expansion(mult = c(0.01, 0.01))
  ) +
  ggplot2::labs(
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
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    panel.spacing.x = grid::unit(1.1, "lines"),
    panel.spacing.y = grid::unit(0.9, "lines"),
    strip.text = ggplot2::element_text(
      face = "bold",
      size = 12,
      lineheight = 0.98
    ),
    strip.background = ggplot2::element_rect(fill = "#f3f4f6", colour = NA),
    plot.title = ggplot2::element_text(face = "bold", size = 18),
    plot.subtitle = ggplot2::element_text(size = 12, margin = ggplot2::margin(b = 12)),
    plot.title.position = "plot",
    plot.margin = ggplot2::margin(12, 14, 12, 14),
    axis.title.x = ggplot2::element_text(size = 11, margin = ggplot2::margin(t = 3)),
    axis.text = ggplot2::element_text(size = 10.5),
    axis.text.x = ggplot2::element_text(margin = ggplot2::margin(t = 2))
  )

plot_build <- ggplot2::ggplot_build(plot)
layer_names <- c(
  "qualifying-tail rectangles",
  "derivative zero reference",
  "pointwise interval ribbons",
  "fitted and derivative lines",
  "qualifying-transition lines",
  "observed photoperiod rugs"
)
layer_sources <- c(
  input_paths[["plateaus"]],
  "literal zero reference by derivative facet",
  paste(input_paths[["curves"]], input_paths[["derivatives"]], sep = " | "),
  paste(input_paths[["curves"]], input_paths[["derivatives"]], sep = " | "),
  input_paths[["plateaus"]],
  input_paths[["rugs"]]
)
layer_map <- data.frame(
  layer = seq_along(plot_build$data),
  layer_name = layer_names,
  frozen_source = layer_sources,
  source_rows = c(
    nrow(plot_transitions),
    nrow(derivative_zero_lines),
    nrow(plot_points),
    nrow(plot_points),
    nrow(plot_transitions),
    nrow(plot_rug)
  ),
  built_rows = vapply(plot_build$data, nrow, integer(1)),
  panels = vapply(
    plot_build$data,
    function(frame) length(unique(frame$PANEL)),
    integer(1)
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(layer_map) == 6L,
  all(layer_map$source_rows == layer_map$built_rows)
)
write_evidence(layer_map, "attempt_01_layer_row_map.csv")

frame_hash <- function(frame) {
  digest::digest(frame, algo = "sha256", serialize = TRUE)
}
numeric_frames <- list(
  smooth = plot_points |>
    dplyr::filter(.data$panel_kind == "Fitted metric value") |>
    dplyr::select(
      "metric_id",
      "photoperiod_hours",
      "estimate",
      "lower",
      "upper"
    ) |>
    dplyr::arrange(
      match(.data$metric_id, .env$metric_ids),
      .data$photoperiod_hours
    ),
  derivative = plot_points |>
    dplyr::filter(.data$panel_kind == "First derivative") |>
    dplyr::select(
      "metric_id",
      "photoperiod_hours",
      "estimate",
      "lower",
      "upper"
    ) |>
    dplyr::arrange(
      match(.data$metric_id, .env$metric_ids),
      .data$photoperiod_hours
    ),
  transitions = plot_transitions |>
    dplyr::select(
      "metric_id",
      "panel_kind",
      "plateau_start",
      "recorded_photoperiod_max",
      "revised_plateau_pattern"
    ) |>
    dplyr::arrange(
      match(.data$metric_id, .env$metric_ids),
      .data$panel_kind
    ),
  rugs = plot_rug |>
    dplyr::select("metric_id", "photoperiod_hours") |>
    dplyr::arrange(
      match(.data$metric_id, .env$metric_ids),
      .data$photoperiod_hours
    )
)
numeric_audit <- data.frame(
  component = names(numeric_frames),
  rows = vapply(numeric_frames, nrow, integer(1)),
  columns = vapply(numeric_frames, ncol, integer(1)),
  serialized_sha256 = vapply(numeric_frames, frame_hash, character(1)),
  missing_numeric_values = c(
    sum(!stats::complete.cases(numeric_frames$smooth)),
    sum(!stats::complete.cases(numeric_frames$derivative)),
    sum(!stats::complete.cases(numeric_frames$transitions)),
    sum(!stats::complete.cases(numeric_frames$rugs))
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(all(numeric_audit$missing_numeric_values == 0L))
write_evidence(numeric_audit, "attempt_01_numeric_input_audit.csv")

label_order <- facet_registry |>
  dplyr::transmute(
    metric_order = .data$metric_order,
    metric_id = .data$metric_id,
    manuscript_name = .data$manuscript_name,
    display_unit = .data$display_unit,
    panel_kind = as.character(.data$panel_kind),
    facet_label = as.character(.data$facet_label),
    status = "PASS"
  )
stopifnot(
  nrow(label_order) == 18L,
  identical(unique(label_order$metric_id), metric_ids),
  identical(label_order$facet_label, facet_levels)
)
write_evidence(label_order, "attempt_01_label_and_panel_order.csv")

state_summary <- derivative_points |>
  dplyr::filter(.data$placement == .env$placement_value) |>
  dplyr::count(.data$derivative_state, name = "rows") |>
  dplyr::arrange(.data$derivative_state) |>
  dplyr::mutate(status = "PASS")
transition_state <- data.frame(
  item = c(
    "near-eye metric panels",
    "near-eye derivative rows",
    "near-eye qualifying metrics",
    "non-estimable smooth/derivative rows"
  ),
  observed = c(
    length(unique(plot_points$metric_id)),
    sum(plot_points$panel_kind == "First derivative"),
    nrow(
      plateau_summary |>
        dplyr::filter(
          .data$placement == .env$placement_value,
          .data$revised_plateau_pattern
        )
    ),
    sum(!stats::complete.cases(
      plot_points[, c("estimate", "lower", "upper")]
    ))
  ),
  expected = c(9L, 900L, 6L, 0L),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(all(transition_state$observed == transition_state$expected))
write_evidence(state_summary, "attempt_01_derivative_state_counts.csv")
write_evidence(transition_state, "attempt_01_state_contract.csv")

svglite::svglite(
  attempt_path,
  width = near_setting$width_in,
  height = near_setting$height_in,
  bg = "white"
)
device_id <- grDevices::dev.cur()
tryCatch(
  print(plot),
  finally = {
    if (device_id %in% grDevices::dev.list()) {
      grDevices::dev.off(device_id)
    }
  }
)
stopifnot(file.exists(attempt_path), file.info(attempt_path)$size > 0)

export_record <- data.frame(
  attempt = "attempt_01",
  status = "EXPORTED_AWAITING_STATIC_GATE",
  device = "svglite::svglite",
  path = substring(attempt_path, nchar(root) + 2L),
  sha256 = sha256_file(attempt_path),
  bytes = as.numeric(file.info(attempt_path)$size),
  width_in = near_setting$width_in,
  height_in = near_setting$height_in,
  method_id = primary_derivative_method,
  placement = placement_value,
  candidate_written = FALSE,
  stringsAsFactors = FALSE
)
write_evidence(export_record, "attempt_01_export_record.csv")

cat(sprintf(
  "ORDER72J_H07_EXPORT_ATTEMPT_01=PASS sha256=%s bytes=%d layers=%d\n",
  export_record$sha256,
  export_record$bytes,
  nrow(layer_map)
))
