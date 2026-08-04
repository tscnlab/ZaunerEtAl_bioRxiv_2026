#!/usr/bin/env Rscript

# Build reader-facing H05 figures and their exact paired source data from the
# frozen, verified Stage 2 outputs. This script never fits or refits a model.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H05/h05_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h05_abort(
    "H05 reader artifacts require R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "readr", "ggplot2", "stringr", "scales", "tibble"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h05_abort(
    "Missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H05/build_h05_reader_artifacts.R"
source_dir <- file.path(root, "artifacts/11_source_data/H05")
figure_dir <- file.path(root, "artifacts/10_figures/H05")
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

stage2_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_stage2_artifacts.csv"
)
stage2_manifest <- readr::read_csv(
  stage2_manifest_path,
  show_col_types = FALSE
)

verified_path <- function(relative_path) {
  manifest_row <- stage2_manifest |>
    dplyr::filter(.data$path == .env$relative_path)
  if (nrow(manifest_row) != 1L) {
    h05_abort("Stage 2 manifest does not uniquely identify %s", relative_path)
  }
  path <- file.path(root, relative_path)
  observed <- artifact_sha256(path)
  if (!identical(observed, manifest_row$sha256[[1L]])) {
    h05_abort("Frozen Stage 2 identity changed for %s", relative_path)
  }
  path
}

verified_read <- function(relative_path) {
  readr::read_csv(
    verified_path(relative_path),
    show_col_types = FALSE
  )
}

master <- verified_read(
  "artifacts/09_tables/H05/H05_model_results_master.csv"
)
diagnostic_points <- verified_read(
  "artifacts/11_source_data/H05/H05_primary_diagnostic_plot_data.csv"
)
paired_effects <- verified_read(
  "artifacts/09_tables/H05/H05_paired_placement_comparison.csv"
)
v0_associations <- verified_read(
  "artifacts/09_tables/H05/H05_v0_reproduction.csv"
)
alternative_preparation <- verified_read(
  "artifacts/09_tables/H05/H05_manuscript_prepared_comparison.csv"
)

near_id <- "main__glasses__all_available"
chest_id <- "main__chest__all_available"
near <- master |>
  dplyr::filter(.data$run_id == .env$near_id) |>
  dplyr::mutate(
    reader_inference_status = dplyr::if_else(
      .data$metric_id == "duration_below_1_sleep_environment",
      "unfit_for_inference",
      "retained_for_inference"
    )
  ) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)
chest <- master |>
  dplyr::filter(.data$run_id == .env$chest_id) |>
  dplyr::mutate(
    reader_inference_status = dplyr::if_else(
      .data$metric_id == "duration_below_1_sleep_environment",
      "unfit_for_inference",
      "retained_for_inference"
    )
  ) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)

stopifnot(
  nrow(near) == 68L,
  nrow(chest) == 68L,
  sum(near$p_adjusted <= 0.05, na.rm = TRUE) == 0L,
  sum(chest$p_adjusted <= 0.05, na.rm = TRUE) == 0L,
  sum(near$reader_inference_status == "unfit_for_inference") == 4L,
  sum(chest$reader_inference_status == "unfit_for_inference") == 4L,
  all(near$family_observed_tests == 68L),
  all(chest$family_observed_tests == 68L)
)

reader_fields <- c(
  "run_id", "placement", "family_id", "metric_order", "metric_id",
  "manuscript_name", "analysis_unit", "response_family",
  "response_transform", "effect_scale", "factor_order", "factor_id",
  "factor_label", "estimate_model_per_point", "conf_low_model_per_point",
  "conf_high_model_per_point", "estimate_model_per_sd",
  "conf_low_model_per_sd", "conf_high_model_per_sd", "effect_type",
  "estimate_practical_per_point", "conf_low_practical_per_point",
  "conf_high_practical_per_point", "estimate_practical_per_sd",
  "conf_low_practical_per_sd", "conf_high_practical_per_sd",
  "interval_method", "p_raw", "p_adjusted", "family_rank",
  "family_observed_tests", "model_adequacy", "specified_limitations",
  "reader_inference_status",
  "observations", "participants", "participant_days", "represented_days",
  "sites", "leba_participant_mean", "leba_participant_sd",
  "model_frame_hash"
)

write_reader_csv <- function(data, filename) {
  path <- file.path(source_dir, filename)
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

write_reader_csv(
  dplyr::select(near, dplyr::all_of(reader_fields)),
  "H05_reader_near_eye_results.csv"
)
write_reader_csv(
  dplyr::select(chest, dplyr::all_of(reader_fields)),
  "H05_reader_chest_results.csv"
)
write_reader_csv(
  alternative_preparation,
  "H05_gap_timing_unaware_dataset.csv"
)

sample_fields <- c(
  "metric_order", "metric_id", "manuscript_name", "analysis_unit",
  "observations", "participants", "participant_days", "represented_days",
  "sites"
)
write_reader_csv(
  near |>
    dplyr::distinct(dplyr::across(dplyr::all_of(sample_fields))),
  "H05_reader_near_eye_samples.csv"
)
write_reader_csv(
  chest |>
    dplyr::distinct(dplyr::across(dplyr::all_of(sample_fields))),
  "H05_reader_chest_samples.csv"
)

factor_display <- function(factor_id, factor_label) {
  paste0(
    stringr::str_to_upper(stringr::str_remove(factor_id, "leba_")),
    ": ",
    factor_label
  )
}

effect_text <- function(effect_type, estimate, unit) {
  dplyr::case_when(
    effect_type %in% c("ratio", "odds_ratio") ~
      sprintf("×%.2f", estimate),
    unit %in% c("h", "clock time") ~ sprintf("%+.2f h", estimate),
    TRUE ~ sprintf("%+.2f", estimate)
  )
}

metric_registry <- verified_read(
  "artifacts/06_model_data/H05/H05_metric_registry.csv"
) |>
  dplyr::select("metric_id", "display_unit")

plot_data <- dplyr::bind_rows(
  near |> dplyr::mutate(reader_placement = "Near eye"),
  chest |> dplyr::mutate(reader_placement = "Chest")
) |>
  dplyr::left_join(metric_registry, by = "metric_id", relationship = "many-to-one") |>
  dplyr::mutate(
    metric_display = factor(
      .data$manuscript_name,
      levels = rev(unique(
        .data$manuscript_name[order(.data$metric_order)]
      ))
    ),
    factor_display = factor_display(.data$factor_id, .data$factor_label),
    factor_display = factor(
      .data$factor_display,
      levels = unique(.data$factor_display[order(.data$factor_order)])
    ),
    effect_label = effect_text(
      .data$effect_type,
      .data$estimate_practical_per_sd,
      .data$display_unit
    ),
    effect_label = dplyr::if_else(
      .data$reader_inference_status == "unfit_for_inference",
      "Unfit",
      .data$effect_label
    ),
    effect_fill = dplyr::if_else(
      .data$reader_inference_status == "unfit_for_inference",
      NA_real_,
      .data$estimate_model_per_sd
    )
  )

effect_limit <- max(abs(plot_data$effect_fill), na.rm = TRUE)

effect_plot <- function(data, placement_title) {
  ggplot2::ggplot(
    data,
    ggplot2::aes(x = .data$factor_display, y = .data$metric_display)
  ) +
    ggplot2::geom_tile(
      ggplot2::aes(fill = .data$effect_fill),
      colour = "white",
      linewidth = 0.4
    ) +
    ggplot2::geom_tile(
      data = data[data$p_adjusted <= 0.05, , drop = FALSE],
      fill = NA,
      colour = "black",
      linewidth = 1.1
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = .data$effect_label),
      size = 3.5
    ) +
    ggplot2::scale_fill_gradient2(
      low = "#3B4CC0",
      mid = "white",
      high = "#B40426",
      midpoint = 0,
      limits = c(-effect_limit, effect_limit),
      na.value = "grey80",
      name = "Model-scale effect\nper LEBA SD"
    ) +
    ggplot2::labs(
      title = paste0(
        placement_title,
        " associations between LEBA factors and personal light exposure"
      ),
      subtitle = paste0(
        "Cell values are reader-scale effects per participant SD;\n",
        "grey cells are unfit for inference; no association remained ",
        "after the 68-test adjustment"
      ),
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
      plot.title.position = "plot"
    )
}

save_plot <- function(plot, stem, width, height, pdf = FALSE) {
  ggplot2::ggsave(
    file.path(figure_dir, paste0(stem, ".png")),
    plot = plot,
    width = width,
    height = height,
    dpi = 300
  )
  if (pdf) {
    ggplot2::ggsave(
      file.path(figure_dir, paste0(stem, ".pdf")),
      plot = plot,
      width = width,
      height = height
    )
  }
}

near_plot_data <- plot_data |>
  dplyr::filter(.data$reader_placement == "Near eye")
chest_plot_data <- plot_data |>
  dplyr::filter(.data$reader_placement == "Chest")
write_reader_csv(
  near_plot_data,
  "H05_reader_near_eye_effect_figure_data.csv"
)
write_reader_csv(
  chest_plot_data,
  "H05_reader_chest_effect_figure_data.csv"
)
save_plot(
  effect_plot(near_plot_data, "Near-eye"),
  "H05_reader_near_eye_effects",
  9,
  9,
  pdf = TRUE
)
save_plot(
  effect_plot(chest_plot_data, "Chest"),
  "H05_reader_chest_effects",
  9,
  9,
  pdf = TRUE
)

adequacy_plot_data <- plot_data |>
  dplyr::select(
    "reader_placement",
    "metric_order",
    "metric_id",
    "manuscript_name",
    "metric_display",
    "factor_order",
    "factor_id",
    "factor_label",
    "factor_display",
    "model_adequacy",
    "reader_inference_status",
    "specified_limitations"
  ) |>
  dplyr::mutate(
    reader_model_assessment = dplyr::if_else(
      .data$reader_inference_status == "unfit_for_inference",
      "unfit_for_inference",
      .data$model_adequacy
    )
  )
write_reader_csv(
  adequacy_plot_data |>
    dplyr::filter(.data$reader_placement == "Near eye"),
  "H05_reader_near_eye_adequacy_figure_data.csv"
)
write_reader_csv(
  adequacy_plot_data |>
    dplyr::filter(.data$reader_placement == "Chest"),
  "H05_reader_chest_adequacy_figure_data.csv"
)

adequacy_plot <- function(data, placement_title) {
  ggplot2::ggplot(
    data,
    ggplot2::aes(x = .data$factor_display, y = .data$metric_display)
  ) +
    ggplot2::geom_tile(
      ggplot2::aes(fill = .data$reader_model_assessment),
      colour = "white",
      linewidth = 0.4
    ) +
    ggplot2::scale_fill_manual(
      values = c(
        acceptable = "#009E73",
        acceptable_with_specified_limitations = "#E69F00",
        unfit_for_inference = "#D55E00",
        not_acceptable = "#D55E00"
      ),
      labels = c(
        acceptable = "Acceptable",
        acceptable_with_specified_limitations =
          "Acceptable with specified limitations",
        unfit_for_inference = "Unfit for inference",
        not_acceptable = "Not acceptable"
      ),
      name = "Assessment"
    ) +
    ggplot2::labs(
      title = paste0(placement_title, " model assessment"),
      subtitle = paste0(
        "Classification combines fit, residual, response-support, ",
        "and dependence checks"
      ),
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
      plot.title.position = "plot"
    )
}

save_plot(
  adequacy_plot(
    adequacy_plot_data |>
      dplyr::filter(.data$reader_placement == "Near eye"),
    "Near-eye"
  ),
  "H05_reader_near_eye_adequacy",
  9,
  8.5
)
invisible(verified_path(
  "artifacts/10_figures/H05/H05_primary_model_adequacy.png"
))
save_plot(
  adequacy_plot(
    adequacy_plot_data |>
      dplyr::filter(.data$reader_placement == "Chest"),
    "Chest"
  ),
  "H05_reader_chest_adequacy",
  9,
  8.5
)

selected_metric_ids <- c(
  "duration_above_1000",
  "dose_time_sensitive_corrected_medi",
  "duration_below_1_sleep_environment"
)
selected_diagnostics <- diagnostic_points |>
  dplyr::filter(
    .data$factor_id == "leba_f2",
    .data$metric_id %in% .env$selected_metric_ids
  ) |>
  dplyr::mutate(
    manuscript_name = factor(
      .data$manuscript_name,
      levels = c(
        "Time above 1,000 lx melEDI",
        "melEDI dose",
        "Time below 1 lx melEDI during sleep"
      )
    )
  )
stopifnot(
  nrow(selected_diagnostics) == 2L * sum(c(816L, 761L, 778L)),
  all(c("residual_fitted", "normal_qq") %in% selected_diagnostics$panel)
)
write_reader_csv(
  selected_diagnostics,
  "H05_reader_near_eye_selected_diagnostics.csv"
)

residual_fitted_plot <- selected_diagnostics |>
  dplyr::filter(.data$panel == "residual_fitted") |>
  ggplot2::ggplot(ggplot2::aes(x = .data$x, y = .data$y)) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey60") +
  ggplot2::geom_point(alpha = 0.32, size = 0.8) +
  ggplot2::geom_smooth(
    se = FALSE,
    method = "loess",
    colour = "#0072B2",
    linewidth = 0.8
  ) +
  ggplot2::facet_wrap(~manuscript_name, scales = "free_x", ncol = 1) +
  ggplot2::labs(
    title = "Selected near-eye residual-versus-fitted checks",
    subtitle = paste0(
      "LEBA F2 models for the two leading estimates and the unfit ",
      "H05 sleep-environment outcome"
    ),
    x = "Fitted value",
    y = "Standardized Pearson residual"
  ) +
  ggplot2::theme_minimal(base_size = 11)

qq_plot <- selected_diagnostics |>
  dplyr::filter(.data$panel == "normal_qq") |>
  ggplot2::ggplot(ggplot2::aes(x = .data$x, y = .data$y)) +
  ggplot2::geom_abline(slope = 1, intercept = 0, colour = "grey60") +
  ggplot2::geom_point(alpha = 0.32, size = 0.8) +
  ggplot2::facet_wrap(~manuscript_name, scales = "free", ncol = 1) +
  ggplot2::labs(
    title = "Near-eye residual quantile checks",
    subtitle = paste0(
      "Gaussian normal-reference quantiles are descriptive;\n",
      "response-support and simulation failures make the H05 Tweedie ",
      "sleep model unfit for inference"
    ),
    x = "Theoretical normal quantile",
    y = "Observed standardized residual quantile"
  ) +
  ggplot2::theme_minimal(base_size = 11)

save_plot(
  residual_fitted_plot,
  "H05_reader_near_eye_residual_fitted",
  9,
  7.5
)
save_plot(
  qq_plot,
  "H05_reader_near_eye_residual_qq",
  9,
  7.5
)

paired_near_samples <- master |>
  dplyr::filter(.data$run_id == "main__glasses__paired_common_sample") |>
  dplyr::select(dplyr::all_of(c(
    "metric_id", "factor_id", "analysis_unit", "observations",
    "participants", "participant_days", "represented_days", "sites",
    "model_frame_hash"
  ))) |>
  dplyr::distinct() |>
  dplyr::rename(
    analysis_unit__near_eye = "analysis_unit",
    observations__near_eye = "observations",
    participants__near_eye = "participants",
    participant_days__near_eye = "participant_days",
    represented_days__near_eye = "represented_days",
    sites__near_eye = "sites",
    model_frame_hash__near_eye = "model_frame_hash"
  )
paired_chest_samples <- master |>
  dplyr::filter(.data$run_id == "main__chest__paired_common_sample") |>
  dplyr::select(dplyr::all_of(c(
    "metric_id", "factor_id", "analysis_unit", "observations",
    "participants", "participant_days", "represented_days", "sites",
    "model_frame_hash"
  ))) |>
  dplyr::distinct() |>
  dplyr::rename(
    analysis_unit__chest = "analysis_unit",
    observations__chest = "observations",
    participants__chest = "participants",
    participant_days__chest = "participant_days",
    represented_days__chest = "represented_days",
    sites__chest = "sites",
    model_frame_hash__chest = "model_frame_hash"
  )

paired_display <- paired_effects |>
  dplyr::left_join(
    paired_near_samples,
    by = c("metric_id", "factor_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    paired_chest_samples,
    by = c("metric_id", "factor_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    comparison_scale = paste(
      "Model-scale coefficient per participant SD of the matched LEBA factor;",
      "near eye on x and chest on y; null = 0"
    ),
    exact_sample_match =
      .data$observations__near_eye == .data$observations__chest &
      .data$participants__near_eye == .data$participants__chest &
      dplyr::coalesce(
        .data$participant_days__near_eye == .data$participant_days__chest,
        is.na(.data$participant_days__near_eye) &
          is.na(.data$participant_days__chest)
      ) &
      .data$sites__near_eye == .data$sites__chest
  )

stopifnot(
  nrow(paired_display) == 68L,
  all(paired_display$exact_sample_match),
  all(
    paired_display$analysis_unit__near_eye ==
      paired_display$analysis_unit__chest
  ),
  all(
    paired_display$effect_type__glasses ==
      paired_display$effect_type__chest
  ),
  all(paired_display$sites__near_eye == 8L),
  min(paired_display$participants__near_eye) == 110L,
  max(paired_display$participants__near_eye) == 112L,
  min(paired_display$participant_days__near_eye, na.rm = TRUE) == 505L,
  max(paired_display$participant_days__near_eye, na.rm = TRUE) == 643L
)

write_reader_csv(
  paired_display,
  "H05_paired_effect_comparison_data.csv"
)

paired_plot_data <- paired_display |>
  dplyr::mutate(
    factor_label = factor(
      .data$factor_label,
      levels = unique(.data$factor_label[order(.data$factor_order)])
    )
  )
paired_limit <- 1.08 * max(abs(c(
  paired_plot_data$estimate_model_per_sd__glasses,
  paired_plot_data$estimate_model_per_sd__chest
)), na.rm = TRUE)

paired_plot <- ggplot2::ggplot(
  paired_plot_data,
  ggplot2::aes(
    x = .data$estimate_model_per_sd__glasses,
    y = .data$estimate_model_per_sd__chest,
    colour = .data$factor_label
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey65", linewidth = 0.45) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey65", linewidth = 0.45) +
  ggplot2::geom_abline(
    slope = 1,
    intercept = 0,
    linetype = 2,
    colour = "black",
    linewidth = 0.55
  ) +
  ggplot2::geom_point(alpha = 0.85, size = 2.1) +
  ggplot2::facet_wrap(~factor_label) +
  ggplot2::coord_equal(
    xlim = c(-paired_limit, paired_limit),
    ylim = c(-paired_limit, paired_limit)
  ) +
  ggplot2::labs(
    title = "Paired/common-sample near-eye and chest effects",
    subtitle = paste0(
      "Matched model-scale estimands: 110–112 participants, 505–643 ",
      "participant-days, and 8 sites;\n",
      "IS/IV use 112 participant rows"
    ),
    x = "Near-eye estimate",
    y = "Chest estimate",
    caption = paste0(
      "The dashed line is identity; grey lines mark the null.\n",
      "Closeness describes concordance, not equivalence; paired tables ",
      "report component 95% confidence intervals."
    )
  ) +
  ggplot2::guides(colour = "none") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = ggplot2::element_text(
      hjust = 0,
      margin = ggplot2::margin(t = 6)
    )
  )

save_plot(
  paired_plot,
  "H05_reader_paired_placement_effects",
  9,
  8
)

v0_display_plot <- function(data, corrected = FALSE, title) {
  displayed_value <- if (corrected) {
    data$consistent_spearman_vector_bh
  } else {
    data$v0_display_p
  }
  displayed_significant <- if (corrected) {
    data$consistent_spearman_flag
  } else {
    data$v0_display_flag
  }
  p_display <- nh_p_value_display(
    displayed_value,
    significant = displayed_significant
  )
  p_prefix <- if (corrected) "BH-adj p=" else "scalar-adj p="

  display_data <- data |>
    dplyr::mutate(
      metric_label = stringr::str_to_sentence(
        stringr::str_replace_all(.data$v0_name, "_", " ")
      ),
      metric_label = factor(
        .data$metric_label,
        levels = unique(.data$metric_label[order(.data$v0_plot_order)])
      ),
      factor_display = factor_display(.data$factor_id, .data$factor_label),
      factor_display = factor(
        .data$factor_display,
        levels = rev(unique(
          .data$factor_display[order(.data$factor_order)]
        ))
      ),
      p_display = .env$p_display$p_display,
      p_bold = .env$p_display$p_bold,
      annotation = paste0(
        "rho=", sprintf("%.2f", .data$spearman_rho),
        "\n", .env$p_prefix, .data$p_display
      ),
      annotation_font = dplyr::if_else(
        .data$p_bold,
        "bold",
        "plain"
      )
    )

  plot <- ggplot2::ggplot(
    display_data,
    ggplot2::aes(x = .data$metric_label, y = .data$factor_display)
  ) +
    ggplot2::geom_blank()

  if (corrected) {
    display_data <- display_data |>
      dplyr::mutate(
        annotation_colour = dplyr::if_else(
          abs(.data$spearman_rho) >= 0.27,
          "white",
          "black"
        )
      )
    plot <- ggplot2::ggplot(
      display_data,
      ggplot2::aes(x = .data$metric_label, y = .data$factor_display)
    ) +
      ggplot2::geom_tile(
        ggplot2::aes(fill = .data$spearman_rho),
        colour = "white",
        linewidth = 0.25
      ) +
      ggplot2::scale_fill_gradient2(
        low = "#3B4CC0",
        mid = "white",
        high = "#B40426",
        midpoint = 0,
        limits = c(-0.4, 0.4),
        oob = scales::squish,
        name = "Spearman rho"
      )
  } else {
    display_data <- display_data |>
      dplyr::mutate(
        annotation_colour = dplyr::if_else(
          .data$p_bold,
          "white",
          "black"
        )
      )
    plot <- plot +
      ggplot2::geom_tile(
        data = display_data[display_data$p_bold, , drop = FALSE],
        ggplot2::aes(fill = abs(.data$spearman_rho)),
        linewidth = 0.25
      ) +
      ggplot2::scale_fill_viridis_c(limits = c(0, 1), guide = "none")
  }

  plot +
    ggplot2::geom_text(
      data = display_data,
      ggplot2::aes(
        label = .data$annotation,
        colour = .data$annotation_colour,
        fontface = .data$annotation_font
      ),
      size = 1.85,
      lineheight = 0.9
    ) +
    ggplot2::scale_colour_identity() +
    ggplot2::coord_fixed() +
    ggplot2::labs(
      title = title,
      subtitle = if (corrected) {
        paste0(
          "Spearman rho with one 68-cell BH family; BH-adjusted p is ",
          "bold only at alpha = 0.050"
        )
      } else {
        paste0(
          "Faithful Pearson-derived scalar adjustment; scalar-adjusted p is ",
          "bold only at alpha = 0.050"
        )
      },
      x = "Metrics",
      y = "LEBA factors"
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid = ggplot2::element_blank(),
      plot.title.position = "plot"
    )
}

stage2_comparison_stems <- c(
  "H05_v0_near_eye_faithful",
  "H05_v0_near_eye_corrected",
  "H05_v0_chest_faithful",
  "H05_v0_chest_corrected"
)
stage2_comparison_paths <- unlist(lapply(
  stage2_comparison_stems,
  function(stem) {
    paste0("artifacts/10_figures/H05/", stem, c(".png", ".pdf"))
  }
))
invisible(vapply(
  stage2_comparison_paths,
  verified_path,
  character(1)
))

message(
  "H05 reader artifacts built from frozen Stage 2 outputs: ",
  paste0(
    "two effect figures, two adequacy figures, two selected diagnostic ",
    "figures, and one paired-placement exemplar; frozen comparison ",
    "figures were identity-checked without being rewritten"
  )
)
