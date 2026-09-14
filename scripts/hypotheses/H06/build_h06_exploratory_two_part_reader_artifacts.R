# Build H06 exploratory two-part reader figures from stored prediction CSV data.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H06 exploratory two-part figures require R 4.6.1", call. = FALSE)
}

required_packages <- c(
  "dplyr",
  "readr",
  "ggplot2",
  "scales",
  "LightLogR"
)
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H06/",
  "build_h06_exploratory_two_part_reader_artifacts.R"
)
figure_root <- file.path(root, "artifacts/10_figures/H06")
source_root <- file.path(root, "artifacts/11_source_data/H06")
qa_root <- file.path(root, "artifacts/12_manifests/H06/qa")
manifest_root <- file.path(root, "artifacts/12_manifests/H06")
invisible(vapply(
  c(figure_root, source_root, qa_root, manifest_root),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

write_h06_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

day_type_predictions <- readr::read_csv(
  file.path(source_root, "H06_exploratory_two_part_day_type_predictions.csv"),
  show_col_types = FALSE
)
activity_predictions <- readr::read_csv(
  file.path(source_root, "H06_exploratory_two_part_activity_predictions.csv"),
  show_col_types = FALSE
)

required_prediction_columns <- c(
  "clock_hour",
  "positive_probability",
  "conditional_positive_mean_melEDI_lx",
  "expected_melEDI_lx",
  "expected_low_melEDI_lx",
  "expected_high_melEDI_lx",
  "participants",
  "participant_days",
  "sites_standardized",
  "standardization",
  "population_prediction"
)
if (
  !all(required_prediction_columns %in% names(day_type_predictions)) ||
    !all(required_prediction_columns %in% names(activity_predictions)) ||
    !"work_free_day" %in% names(day_type_predictions) ||
    !"activity_status" %in% names(activity_predictions) ||
    "site" %in% names(day_type_predictions) ||
    "site" %in% names(activity_predictions) ||
    nrow(day_type_predictions) != 194L ||
    nrow(activity_predictions) != 194L ||
    any(!is.finite(day_type_predictions$expected_melEDI_lx)) ||
    any(!is.finite(activity_predictions$expected_melEDI_lx)) ||
    any(day_type_predictions$expected_melEDI_lx < 0) ||
    any(activity_predictions$expected_melEDI_lx < 0) ||
    !all(day_type_predictions$sites_standardized == 9L) ||
    !all(activity_predictions$sites_standardized == 9L)
) {
  stop(
    "The H06 exploratory marginal prediction sources are invalid",
    call. = FALSE
  )
}

day_type_source <- day_type_predictions |>
  dplyr::mutate(
    work_free_day = factor(
      work_free_day,
      levels = c("Work day", "Free day")
    ),
    display_scale = paste(
      "LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)"
    )
  ) |>
  dplyr::select(
    clock_hour,
    work_free_day,
    expected_melEDI_lx,
    expected_low_melEDI_lx,
    expected_high_melEDI_lx,
    positive_probability,
    conditional_positive_mean_melEDI_lx,
    participants,
    participant_days,
    observations,
    positive_observations,
    zero_observations,
    zero_fraction,
    sites_with_support,
    sites_standardized,
    standardization,
    population_prediction,
    display_scale,
    interval_scope,
    inferential_role
  )

activity_source <- activity_predictions |>
  dplyr::mutate(
    activity_status = factor(
      dplyr::if_else(
        grepl("^Sedentary", activity_status),
        "Sedentary",
        "Active"
      ),
      levels = c("Sedentary", "Active")
    ),
    display_scale = paste(
      "LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)"
    )
  ) |>
  dplyr::select(
    clock_hour,
    activity_status,
    expected_melEDI_lx,
    expected_low_melEDI_lx,
    expected_high_melEDI_lx,
    positive_probability,
    conditional_positive_mean_melEDI_lx,
    participants,
    participant_days,
    observations,
    positive_observations,
    zero_observations,
    zero_fraction,
    sites_with_support,
    sites_standardized,
    standardization,
    population_prediction,
    display_scale,
    interval_scope,
    inferential_role
  )
write_h06_csv(
  day_type_source,
  file.path(
    source_root,
    "H06_exploratory_two_part_day_type_expected_figure.csv"
  )
)
write_h06_csv(
  activity_source,
  file.path(
    source_root,
    "H06_exploratory_two_part_activity_expected_figure.csv"
  )
)

day_type_colours <- c("Work day" = "#0072B2", "Free day" = "#D55E00")
day_type_linetypes <- c("Work day" = "solid", "Free day" = "22")
activity_colours <- c("Sedentary" = "#0072B2", "Active" = "#D55E00")
activity_linetypes <- c("Sedentary" = "solid", "Active" = "22")

theme_h06_gamm <- function() {
  ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(size = 8, colour = "#333333"),
      axis.title = ggplot2::element_text(size = 9),
      strip.text = ggplot2::element_text(size = 9, face = "bold"),
      legend.text = ggplot2::element_text(size = 8),
      legend.title = ggplot2::element_text(size = 8.5),
      legend.position = "bottom",
      legend.key.width = grid::unit(12, "mm"),
      panel.spacing = grid::unit(2.5, "mm"),
      plot.margin = ggplot2::margin(4, 5, 4, 4, unit = "mm")
    )
}

make_expected_plot <- function(
  data,
  comparison_column,
  colours,
  linetypes,
  legend_title
) {
  ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = clock_hour,
      y = expected_melEDI_lx,
      colour = .data[[comparison_column]],
      fill = .data[[comparison_column]],
      linetype = .data[[comparison_column]],
      group = .data[[comparison_column]]
    )
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = expected_low_melEDI_lx,
        ymax = expected_high_melEDI_lx
      ),
      alpha = 0.14,
      colour = NA
    ) +
    ggplot2::geom_line(linewidth = 0.75, lineend = "round") +
    ggplot2::scale_colour_manual(values = colours, name = legend_title) +
    ggplot2::scale_fill_manual(values = colours, guide = "none") +
    ggplot2::scale_linetype_manual(
      values = linetypes,
      name = legend_title
    ) +
    ggplot2::scale_x_continuous(
      breaks = c(0, 6, 12, 18, 24),
      limits = c(0, 24),
      expand = ggplot2::expansion(mult = c(0, 0.01))
    ) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 250, 1000),
      labels = scales::label_number(big.mark = ",", accuracy = 1),
      limits = c(0, NA),
      expand = ggplot2::expansion(mult = c(0, 0.04))
    ) +
    ggplot2::labs(
      x = "Local clock hour",
      y = "Exploratory expected hourly melEDI (lx; symlog scale)",
      colour = legend_title,
      linetype = legend_title
    ) +
    theme_h06_gamm()
}

day_type_plot <- make_expected_plot(
  day_type_source,
  comparison_column = "work_free_day",
  colours = day_type_colours,
  linetypes = day_type_linetypes,
  legend_title = "Day type"
)
activity_plot <- make_expected_plot(
  activity_source,
  comparison_column = "activity_status",
  colours = activity_colours,
  linetypes = activity_linetypes,
  legend_title = "Activity status"
)

base_width_in <- 170 / 25.4
base_height_in <- 112 / 25.4
save_plot <- function(plot, filename) {
  ggplot2::ggsave(
    file.path(figure_root, paste0(filename, ".png")),
    plot = plot,
    width = base_width_in,
    height = base_height_in,
    units = "in",
    dpi = 320,
    bg = "white"
  )
  ggplot2::ggsave(
    file.path(figure_root, paste0(filename, ".pdf")),
    plot = plot,
    width = base_width_in,
    height = base_height_in,
    units = "in",
    device = grDevices::cairo_pdf,
    bg = "white"
  )
  grDevices::cairo_pdf(
    file.path(qa_root, paste0(filename, "_A4_preview.pdf")),
    width = 210 / 25.4,
    height = 297 / 25.4,
    bg = "white"
  )
  grid::grid.newpage()
  print(
    plot,
    vp = grid::viewport(
      width = grid::unit(170, "mm"),
      height = grid::unit(112, "mm")
    )
  )
  grDevices::dev.off()
}

save_plot(day_type_plot, "H06_exploratory_two_part_day_type_expected")
save_plot(activity_plot, "H06_exploratory_two_part_activity_expected")

qa_status <- Sys.getenv("H06_FIGURE_QA_STATUS", unset = "NOT TESTED")
if (!qa_status %in% c("NOT TESTED", "PASS")) {
  stop("H06_FIGURE_QA_STATUS must be `NOT TESTED` or `PASS`", call. = FALSE)
}
inspection <- if (qa_status == "PASS") {
  paste(
    "PASS at 170 mm on A4 portrait with 20-mm side margins: no clipping,",
    "overlap, unwanted wrapping, distortion, or poor data-region balance;",
    "comparison curves, ribbons, and legends remain distinguishable in greyscale"
  )
} else {
  paste(
    "NOT TESTED: inspect the A4 physical-size previews before classifying",
    "the figures as reader ready"
  )
}
qa <- tibble::tibble(
  figure_id = c(
    "H06_exploratory_two_part_day_type_expected",
    "H06_exploratory_two_part_activity_expected"
  ),
  base_width_in = base_width_in,
  base_height_in = base_height_in,
  export_scale_multiplier = 1,
  export_width_in = base_width_in,
  export_height_in = base_height_in,
  raster_dpi = 320L,
  native_width_mm = 170,
  native_height_mm = 112,
  intended_html_display_width_mm = 170,
  intended_print_display_width_mm = 170,
  scale_factor = 1,
  smallest_essential_nominal_text_pt = 8,
  effective_final_text_pt = 8,
  physical_size_inspection = inspection,
  clipping_overlap_wrapping_distortion_balance = inspection,
  greyscale_and_redundant_encoding = inspection,
  source_values_untransformed = TRUE,
  exact_report_013_symlog = TRUE,
  report_011_status = qa_status
)
write_h06_csv(
  qa,
  file.path(
    manifest_root,
    "H06_exploratory_two_part_figure_readability_qa.csv"
  )
)

message("H06 exploratory two-part reader artifacts built")
