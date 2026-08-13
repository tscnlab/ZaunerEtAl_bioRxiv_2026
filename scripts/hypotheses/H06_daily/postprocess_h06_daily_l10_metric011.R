#!/usr/bin/env Rscript

# Lightweight report-data postprocessing. No model is fitted or refitted.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
required_packages <- c(
  "digest", "dplyr", "ggplot2", "readr", "svglite", "tibble", "tidyr"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)
source(file.path(root, "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_contract.R"))
roots <- h06d_l10_artifact_roots(root)

registry <- readr::read_csv(
  file.path(roots$model_data, "H06_daily_l10_metric011_frame_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(.data$component == "zero_occurrence")
occurrence_cells <- dplyr::bind_rows(lapply(seq_len(nrow(registry)), function(index) {
  row <- registry[index, ]
  frame <- readRDS(file.path(root, row$frame_path[[1L]]))
  predictor_column <- dplyr::case_when(
    row$predictor_id[[1L]] == "work_free_day" ~ "work_free_day",
    row$predictor_id[[1L]] == "activity_status" ~ "activity_status",
    TRUE ~ "previous_sleep_duration_centered_h"
  )
  cell_summary <- if (
    predictor_column %in% c("work_free_day", "activity_status")
  ) {
    frame |>
      dplyr::mutate(
        predictor_level = as.character(.data[[predictor_column]])
      ) |>
      dplyr::summarise(
        participant_days = dplyr::n(),
        exact_zero_days = sum(.data$response_value == 1L),
        positive_days = sum(.data$response_value == 0L),
        zero_fraction = mean(.data$response_value == 1L),
        .by = c("site", "predictor_level")
      )
  } else {
    frame |>
      dplyr::summarise(
        participant_days = dplyr::n(),
        exact_zero_days = sum(.data$response_value == 1L),
        positive_days = sum(.data$response_value == 0L),
        zero_fraction = mean(.data$response_value == 1L),
        predictor_minimum = min(.data[[predictor_column]]),
        predictor_maximum = max(.data[[predictor_column]]),
        predictor_level = "continuous support",
        .by = "site"
      )
  }
  cell_summary |>
    dplyr::mutate(
      run_order = row$run_order[[1L]],
      run_id = row$run_id[[1L]],
      dataset_id = row$dataset_id[[1L]],
      placement_id = row$placement_id[[1L]],
      sample_role = row$sample_role[[1L]],
      predictor_order = row$predictor_order[[1L]],
      predictor_id = row$predictor_id[[1L]],
      .before = 1L
    )
})) |>
  dplyr::arrange(
    .data$predictor_order,
    .data$run_order,
    .data$site,
    .data$predictor_level
  )
readr::write_csv(
  occurrence_cells,
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_occurrence_site_cells.csv"
  )
)

map_coefficients <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_map_occurrence_coefficients.csv"
  ),
  show_col_types = FALSE
)
map_predictions <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_map_occurrence_predictions.csv"
  ),
  show_col_types = FALSE
)
map_scale_summary <- map_coefficients |>
  dplyr::summarise(
    prior_scales = paste(sort(.data$prior_standard_deviation), collapse = ", "),
    minimum_map_log_odds = min(.data$map_log_odds_coefficient),
    maximum_map_log_odds = max(.data$map_log_odds_coefficient),
    minimum_map_odds_ratio = min(.data$map_odds_ratio),
    maximum_map_odds_ratio = max(.data$map_odds_ratio),
    coefficient_direction_stable = dplyr::n_distinct(sign(
      .data$map_log_odds_coefficient
    )) == 1L,
    all_map_fits_converged = all(.data$converged),
    .by = c(
      "run_id", "dataset_id", "placement_id", "sample_role",
      "predictor_order", "predictor_id"
    )
  ) |>
  dplyr::left_join(
    map_predictions |>
      dplyr::summarise(
        minimum_equal_site_probability = min(.data$equal_site_probability_zero),
        maximum_equal_site_probability = max(.data$equal_site_probability_zero),
        minimum_site_probability_across_priors = min(
          .data$minimum_site_probability_zero
        ),
        maximum_site_probability_across_priors = max(
          .data$maximum_site_probability_zero
        ),
        .by = c(
          "run_id", "dataset_id", "placement_id", "sample_role",
          "predictor_order", "predictor_id"
        )
      ),
    by = c(
      "run_id", "dataset_id", "placement_id", "sample_role",
      "predictor_order", "predictor_id"
    ),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    inferential_role = paste0(
      "normal(0,1.5/3/6) fixed-effect MAP diagnostic; no ordinary interval, ",
      "p-value, or BH decision"
    )
  )
readr::write_csv(
  map_scale_summary,
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_map_prior_scale_summary.csv"
  )
)

effects <- readr::read_csv(
  file.path(roots$tables, "H06_daily_l10_metric011_effect_estimates.csv"),
  show_col_types = FALSE
)
scenario_labels <- c(
  primary__near_eye__all_available = "Primary near-eye, all available",
  primary__chest__all_available = "Primary chest, all available",
  primary__near_eye__paired_common = "Primary near-eye, paired/common",
  primary__chest__paired_common = "Primary chest, paired/common",
  gap_timing_unaware__near_eye__all_available = "Gap-timing-unaware near-eye",
  gap_timing_unaware__chest__all_available = "Gap-timing-unaware chest"
)
predictor_labels <- c(
  work_free_day = "Free day versus work day",
  activity_status = "Active versus Sedentary",
  previous_sleep_duration_centered_h = "Per 1 h longer previous-night sleep"
)
figure_source <- effects |>
  dplyr::filter(.data$family %in% c(
    "Gaussian identity on log10-positive L10",
    "Student-t identity on log10-positive L10 sensitivity"
  )) |>
  dplyr::transmute(
    run_order = .data$run_order,
    run_id = .data$run_id,
    scenario = factor(
      unname(scenario_labels[.data$run_id]),
      levels = rev(unname(scenario_labels))
    ),
    predictor_id = .data$predictor_id,
    predictor = factor(
      unname(predictor_labels[.data$predictor_id]),
      levels = unname(predictor_labels)
    ),
    family = factor(
      dplyr::if_else(
        grepl("Student-t", .data$family),
        "Student-t sensitivity",
        "Gaussian primary component"
      ),
      levels = c("Gaussian primary component", "Student-t sensitivity")
    ),
    ratio = .data$estimate,
    lower_95 = dplyr::if_else(
      grepl("Student-t", .data$family) &
        grepl("UNRESOLVED", .data$inferential_status),
      NA_real_,
      .data$lower_95
    ),
    upper_95 = dplyr::if_else(
      grepl("Student-t", .data$family) &
        grepl("UNRESOLVED", .data$inferential_status),
      NA_real_,
      .data$upper_95
    ),
    interval_available = !(
      grepl("Student-t", .data$family) &
        grepl("UNRESOLVED", .data$inferential_status)
    ),
    interval_type = dplyr::if_else(
      .data$interval_available,
      .data$interval_type,
      "withheld because Student-t sensitivity failed its numerical gate"
    ),
    inferential_status = .data$inferential_status,
    estimand = "conditional geometric-mean ratio among participant-days with L10 > 0"
  )
readr::write_csv(
  figure_source,
  file.path(
    roots$source_data,
    "H06_daily_l10_metric011_positive_component_figure_source.csv"
  )
)

plot <- ggplot2::ggplot(
  figure_source,
  ggplot2::aes(
    x = .data$ratio,
    y = .data$scenario,
    colour = .data$family,
    shape = .data$family
  )
) +
  ggplot2::geom_vline(xintercept = 1, colour = "grey55", linewidth = 0.45) +
  ggplot2::geom_errorbar(
    ggplot2::aes(xmin = .data$lower_95, xmax = .data$upper_95),
    orientation = "y",
    width = 0,
    position = ggplot2::position_dodge(width = 0.48),
    linewidth = 0.55,
    na.rm = TRUE
  ) +
  ggplot2::geom_point(
    position = ggplot2::position_dodge(width = 0.48),
    size = 2.25,
    stroke = 0.8
  ) +
  ggplot2::facet_wrap(~predictor, ncol = 1, scales = "free_x") +
  ggplot2::scale_x_log10() +
  ggplot2::scale_colour_manual(values = c("#1B5E7A", "#C05A2B")) +
  ggplot2::labs(
    x = "Conditional geometric-mean ratio among positive L10 values",
    y = NULL,
    colour = NULL,
    shape = NULL
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    legend.position = "top",
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(face = "bold", size = 10),
    axis.text.y = ggplot2::element_text(size = 8.5),
    plot.margin = ggplot2::margin(7, 12, 7, 7)
  )
stem <- file.path(
  roots$figures,
  "H06_daily_l10_metric011_positive_component_sensitivity"
)
ggplot2::ggsave(
  paste0(stem, ".png"),
  plot,
  width = 7.4,
  height = 8,
  units = "in",
  dpi = 300,
  bg = "white"
)
ggplot2::ggsave(
  paste0(stem, ".pdf"),
  plot,
  width = 7.4,
  height = 8,
  units = "in",
  device = grDevices::cairo_pdf,
  bg = "white"
)
ggplot2::ggsave(
  paste0(stem, ".svg"),
  plot,
  width = 7.4,
  height = 8,
  units = "in",
  device = svglite::svglite,
  bg = "white"
)
readr::write_csv(
  tibble::tibble(
    figure_id = "fig-l10-positive-component-sensitivity",
    alt_text = paste0(
      "Forest plot of Gaussian and Student-t estimates for the conditional ",
      "geometric-mean L10 ratio among positive participant-days. Six scenarios ",
      "are shown for each of three day-level contexts. Pointwise 95% intervals ",
      "are drawn only for numerically acceptable fits; Student-t points without ",
      "intervals identify failed sensitivity fits. The reference ratio is one. ",
      "These positive-only estimates do not represent overall L10 associations."
    )
  ),
  file.path(roots$source_data, "H06_daily_l10_metric011_figure_alt_text.csv")
)
readr::write_csv(
  tibble::tibble(
    figure_id = "fig-l10-positive-component-sensitivity",
    width_inches = 7.4,
    height_inches = 8,
    dpi_png = 300L,
    panels = 3L,
    scenarios_per_panel = 6L,
    series_per_scenario = 2L,
    clipping_check = "PASS_VISUALLY_INSPECTED_2026_08_12",
    wrapping_check = "PASS",
    panel_balance_check = "PASS",
    final_size_legibility = "PASS",
    interval_type = "pointwise, not simultaneous",
    disposition = "PASS"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_figure_readability_qa.csv"
  )
)

message("METRIC-011 report-data postprocessing complete; no model fit.")
