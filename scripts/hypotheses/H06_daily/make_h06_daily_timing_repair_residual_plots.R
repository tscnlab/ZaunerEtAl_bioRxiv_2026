#!/usr/bin/env Rscript

# Build residual displays from the sealed H06_daily timing-repair pilot fits.

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
  "digest", "dplyr", "ggplot2", "patchwork", "readr", "tibble"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf(
      "Missing synchronized packages: %s",
      paste(missing_packages, collapse = ", ")
    ),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R"
))

h06d_tr_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Residual display requires R 4.6.1; found %s",
  as.character(getRversion())
)

roots <- h06d_tr_artifact_roots(root)
source_data_root <- file.path(root, "artifacts/10_source_data/H06_daily")
dir.create(source_data_root, recursive = TRUE, showWarnings = FALSE)

model_path <- file.path(
  roots$models,
  "H06_daily_timing_repair_pilot_models.rds"
)
frame_path <- file.path(
  roots$model_data,
  "H06_daily_non_l10_pilot_timing_frames.rds"
)
site_path <- file.path(root, "config/site_display_registry.csv")

models <- readRDS(model_path)
frames <- readRDS(frame_path)
sites <- readr::read_csv(site_path, show_col_types = FALSE) |>
  dplyr::arrange(.data$display_order)
site_colours <- stats::setNames(sites$color_hex, sites$display_name)

h06d_tr_assert(
  identical(models$gate, "H06-D-G2P-TIMING-REPAIR"),
  "The model bundle does not belong to the timing-repair gate"
)
h06d_tr_assert(
  identical(
    models$authorization$expected_sha256,
    h06d_tr_authorization()$expected_sha256
  ),
  "The model bundle authorization identity is not current"
)

metrics <- h06d_tr_metric_registry()
predictors <- h06d_tr_predictor_registry()
frame_pins <- h06d_tr_frame_pins()
predictor_labels <- stats::setNames(
  c(
    "Work day versus free day",
    "Sedentary versus Active day",
    "Previous-night sleep duration"
  ),
  predictors$predictor_id
)
predictor_plot_labels <- stats::setNames(
  c("Work/free day", "Activity status", "Previous-night sleep"),
  predictors$predictor_id
)

theme_residual <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 10.5),
      plot.subtitle = ggplot2::element_text(size = 9),
      legend.position = "bottom",
      legend.title = ggplot2::element_text(face = "bold")
    )
}

write_png <- function(plot, path) {
  temporary <- tempfile(
    pattern = paste0(basename(path), "_"),
    tmpdir = dirname(path),
    fileext = ".png"
  )
  on.exit(unlink(temporary), add = TRUE)
  ggplot2::ggsave(
    filename = temporary,
    plot = plot,
    width = 16,
    height = 13,
    units = "in",
    dpi = 180,
    bg = "white"
  )
  if (!file.rename(temporary, path)) {
    h06d_tr_abort("Could not atomically write `%s`", path)
  }
  invisible(path)
}

plot_paths <- character()
source_paths <- character()
summary_rows <- list()

for (metric_index in seq_len(nrow(metrics))) {
  metric <- metrics[metric_index, , drop = FALSE]
  plot_panels <- list()
  metric_source <- list()

  for (predictor_index in seq_len(nrow(predictors))) {
    predictor <- predictors[predictor_index, , drop = FALSE]
    cell_id <- paste(
      metric$metric_id,
      predictor$predictor_id,
      sep = "__"
    )
    pin <- dplyr::filter(frame_pins, .data$cell_id == .env$cell_id)
    frame <- frames[[pin$frame_key]]
    cell <- models$cells[[cell_id]]
    h06d_tr_assert(!is.null(frame), "Missing frame `%s`", pin$frame_key)
    h06d_tr_assert(!is.null(cell), "Missing fitted cell `%s`", cell_id)
    h06d_tr_assert(
      identical(h06d_tr_object_sha256(frame), pin$frame_object_sha256),
      "Frame identity changed for `%s`",
      cell_id
    )

    candidate <- cell$candidate$fits$additive$value
    ar_model <- cell$no_nugget_ar$fits$additive$value
    h06d_tr_assert(!is.null(candidate), "Missing candidate fit `%s`", cell_id)
    h06d_tr_assert(!is.null(ar_model), "Missing AR fit `%s`", cell_id)

    residual <- as.numeric(stats::residuals(candidate))
    fitted <- as.numeric(stats::fitted(candidate))
    standardized <- residual / stats::sd(residual)
    h06d_tr_assert(
      length(residual) == nrow(frame),
      "Candidate residual length changed for `%s`",
      cell_id
    )

    residual_data <- tibble::tibble(
      metric_id = metric$metric_id,
      predictor_id = predictor$predictor_id,
      row_id = seq_len(nrow(frame)),
      site = as.character(frame$site),
      fitted_hour = fitted,
      residual_hour = residual,
      standardized_residual = standardized
    ) |>
      dplyr::left_join(
        sites |>
          dplyr::select("site", "display_order", "display_name", "color_hex"),
        by = "site",
        relationship = "many-to-one"
      )
    h06d_tr_assert(
      !anyNA(residual_data$display_name),
      "Site display metadata are incomplete for `%s`",
      cell_id
    )

    qq_order <- order(standardized)
    qq_theoretical <- stats::qnorm(stats::ppoints(length(standardized)))
    qq_data <- residual_data[qq_order, , drop = FALSE] |>
      dplyr::mutate(
        theoretical_quantile = qq_theoretical,
        sample_quantile = sort(standardized)
      )
    qq_quartiles <- stats::quantile(
      standardized,
      probs = c(0.25, 0.75),
      names = FALSE,
      type = 8
    )
    theoretical_quartiles <- stats::qnorm(c(0.25, 0.75))
    qq_slope <- diff(qq_quartiles) / diff(theoretical_quartiles)
    qq_intercept <- qq_quartiles[[1L]] -
      qq_slope * theoretical_quartiles[[1L]]

    candidate_lag <- h06d_tr_lag_screen(frame, residual)
    ar_frame <- h06d_tr_add_day_sequences(frame)
    ar_residual <- as.numeric(stats::residuals(ar_model))
    h06d_tr_assert(
      length(ar_residual) == nrow(ar_frame),
      "AR residual length changed for `%s`",
      cell_id
    )
    ar_lag <- h06d_tr_lag_screen(ar_frame, ar_residual)
    ar_scale <- stats::sd(ar_residual)
    lag_data <- ar_lag$pairs |>
      dplyr::transmute(
        metric_id = metric$metric_id,
        predictor_id = predictor$predictor_id,
        participant_key = as.character(.data$participant_key),
        local_date = as.character(.data$local_date),
        site = as.character(.data$site),
        previous_standardized_residual = .data$previous_residual / ar_scale,
        current_standardized_residual = .data$.residual / ar_scale
      ) |>
      dplyr::left_join(
        sites |>
          dplyr::select("site", "display_order", "display_name", "color_hex"),
        by = "site",
        relationship = "many-to-one"
      )

    status <- h06d_tr_glmmtmb_status(
      ar_model,
      cell$no_nugget_ar$fits$additive
    )
    parameters <- h06d_tr_ar_parameters(ar_model)
    residual_diagnostic <- h06d_tr_residual_diagnostics(candidate, frame)
    summary_rows[[cell_id]] <- tibble::tibble(
      metric_id = metric$metric_id,
      predictor_id = predictor$predictor_id,
      participant_days = nrow(frame),
      participants = dplyr::n_distinct(frame$participant_key),
      residual_qq_correlation =
        residual_diagnostic$overall$residual_qq_correlation,
      absolute_residual_fitted_spearman =
        residual_diagnostic$overall$absolute_residual_fitted_spearman,
      standardized_residual_gt4_fraction =
        residual_diagnostic$overall$standardized_residual_gt4_fraction,
      candidate_residual_lag1 = candidate_lag$overall$residual_lag1,
      candidate_maximum_absolute_site_lag1 =
        candidate_lag$overall$maximum_absolute_site_lag1,
      ar_converged = status$converged,
      ar_positive_definite_hessian = status$positive_definite_hessian,
      ar_warning_count = status$warning_count,
      ar_rho = parameters$ar_rho,
      ar_no_nugget_verified = parameters$no_nugget_verified,
      post_ar_residual_lag1 = ar_lag$overall$residual_lag1,
      post_ar_maximum_absolute_site_lag1 =
        ar_lag$overall$maximum_absolute_site_lag1,
      post_ar_temporal_threshold_pass =
        ar_lag$overall$temporal_threshold_pass
    )

    qq_plot <- ggplot2::ggplot(
      qq_data,
      ggplot2::aes(
        x = .data$theoretical_quantile,
        y = .data$sample_quantile,
        colour = .data$display_name
      )
    ) +
      ggplot2::geom_abline(
        intercept = qq_intercept,
        slope = qq_slope,
        linewidth = 0.7,
        colour = "#B2182B"
      ) +
      ggplot2::geom_point(alpha = 0.50, size = 1.05) +
      ggplot2::scale_colour_manual(
        values = site_colours,
        limits = names(site_colours),
        breaks = names(site_colours),
        drop = FALSE
      ) +
      ggplot2::guides(colour = "none") +
      ggplot2::labs(
        title = paste0(
          predictor_plot_labels[[predictor$predictor_id]],
          ": Q–Q"
        ),
        subtitle = sprintf(
          "Q–Q r = %.3f; |z| > 4 = %.1f%%",
          residual_diagnostic$overall$residual_qq_correlation,
          100 * residual_diagnostic$overall$standardized_residual_gt4_fraction
        ),
        x = "Theoretical normal quantile",
        y = "Standardized residual",
        colour = "Site"
      ) +
      theme_residual()

    fitted_plot <- ggplot2::ggplot(
      residual_data,
      ggplot2::aes(
        x = .data$fitted_hour,
        y = .data$standardized_residual,
        colour = .data$display_name
      )
    ) +
      ggplot2::geom_hline(
        yintercept = 0,
        linewidth = 0.45,
        colour = "#6C757D"
      ) +
      ggplot2::geom_point(alpha = 0.42, size = 1.05) +
      ggplot2::geom_smooth(
        ggplot2::aes(group = 1L),
        method = "loess",
        formula = y ~ x,
        se = FALSE,
        linewidth = 0.8,
        colour = "#B2182B"
      ) +
      ggplot2::scale_colour_manual(
        values = site_colours,
        limits = names(site_colours),
        breaks = names(site_colours),
        drop = FALSE
      ) +
      ggplot2::guides(colour = "none") +
      ggplot2::labs(
        title = "Residuals versus fitted",
        subtitle = sprintf(
          "|Spearman(|residual|, fitted)| = %.3f",
          residual_diagnostic$overall$absolute_residual_fitted_spearman
        ),
        x = "Fitted clock hour",
        y = "Standardized residual",
        colour = "Site"
      ) +
      theme_residual()

    lag_plot <- ggplot2::ggplot(
      lag_data,
      ggplot2::aes(
        x = .data$previous_standardized_residual,
        y = .data$current_standardized_residual,
        colour = .data$display_name
      )
    ) +
      ggplot2::geom_hline(
        yintercept = 0,
        linewidth = 0.35,
        colour = "#AAB2B8"
      ) +
      ggplot2::geom_vline(
        xintercept = 0,
        linewidth = 0.35,
        colour = "#AAB2B8"
      ) +
      ggplot2::geom_point(alpha = 0.46, size = 1.05) +
      ggplot2::geom_smooth(
        ggplot2::aes(group = 1L),
        method = "lm",
        formula = y ~ x,
        se = FALSE,
        linewidth = 0.8,
        colour = "#111111"
      ) +
      ggplot2::scale_colour_manual(
        values = site_colours,
        limits = names(site_colours),
        breaks = names(site_colours),
        drop = FALSE
      ) +
      ggplot2::guides(colour = "none") +
      ggplot2::labs(
        title = if (isTRUE(status$converged)) {
          "Consecutive-day residuals after no-nugget AR(1)"
        } else {
          "NONCONVERGED no-nugget AR(1) residuals"
        },
        subtitle = sprintf(
          "%spooled r = %.3f; max site |r| = %.3f",
          if (isTRUE(status$converged)) "" else "descriptive only; ",
          ar_lag$overall$residual_lag1,
          ar_lag$overall$maximum_absolute_site_lag1
        ),
        x = "Previous-day standardized residual",
        y = "Current-day standardized residual",
        colour = "Site"
      ) +
      theme_residual()

    plot_panels <- c(
      plot_panels,
      list(
        qq_plot + ggplot2::theme(legend.position = "none"),
        fitted_plot + ggplot2::theme(legend.position = "none"),
        lag_plot
      )
    )

    metric_source[[paste0(cell_id, "__qq")]] <- qq_data |>
      dplyr::transmute(
        .data$metric_id,
        .data$predictor_id,
        panel = "normal_qq",
        .data$row_id,
        participant_key = NA_character_,
        local_date = NA_character_,
        .data$site,
        .data$display_name,
        x_value = .data$theoretical_quantile,
        y_value = .data$sample_quantile,
        x_variable = "theoretical_normal_quantile",
        y_variable = "standardized_candidate_residual"
      )
    metric_source[[paste0(cell_id, "__fitted")]] <- residual_data |>
      dplyr::transmute(
        .data$metric_id,
        .data$predictor_id,
        panel = "residual_vs_fitted",
        .data$row_id,
        participant_key = NA_character_,
        local_date = NA_character_,
        .data$site,
        .data$display_name,
        x_value = .data$fitted_hour,
        y_value = .data$standardized_residual,
        x_variable = "candidate_fitted_clock_hour",
        y_variable = "standardized_candidate_residual"
      )
    metric_source[[paste0(cell_id, "__lag")]] <- lag_data |>
      dplyr::mutate(row_id = dplyr::row_number()) |>
      dplyr::transmute(
        .data$metric_id,
        .data$predictor_id,
        panel = "post_ar_consecutive_day_residual",
        .data$row_id,
        .data$participant_key,
        .data$local_date,
        .data$site,
        .data$display_name,
        x_value = .data$previous_standardized_residual,
        y_value = .data$current_standardized_residual,
        x_variable = "previous_day_standardized_ar_residual",
        y_variable = "current_day_standardized_ar_residual"
      )
  }

  combined <- patchwork::wrap_plots(plot_panels, ncol = 3L) +
    patchwork::plot_layout(guides = "collect") +
    patchwork::plot_annotation(
      title = metric$manuscript_name,
      subtitle = paste(
        "Primary near-eye all-available timing-repair pilot;",
        "participant-cluster HC3 candidate and diagnostic AR residuals."
      ),
      caption = paste(
        "AR lag thresholds are descriptive for HC3 inference:",
        "|pooled lag-1| < 0.20 and every site |lag-1| < 0.30."
      ),
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold", size = 16),
        plot.subtitle = ggplot2::element_text(size = 11),
        plot.caption = ggplot2::element_text(size = 9, hjust = 0)
      )
    )

  plot_path <- file.path(
    roots$diagnostics,
    paste0(
      "H06_daily_timing_repair_residuals_",
      metric$metric_id,
      ".png"
    )
  )
  source_path <- file.path(
    source_data_root,
    paste0(
      "H06_daily_timing_repair_residuals_",
      metric$metric_id,
      ".csv"
    )
  )
  write_png(combined, plot_path)
  h06d_tr_write_csv(dplyr::bind_rows(metric_source), source_path)
  plot_paths <- c(plot_paths, plot_path)
  source_paths <- c(source_paths, source_path)
}

summary_path <- file.path(
  roots$diagnostics,
  "H06_daily_timing_repair_residual_plot_summary.csv"
)
h06d_tr_write_csv(dplyr::bind_rows(summary_rows), summary_path)

manifest_path <- file.path(
  roots$manifests,
  "H06_daily_timing_repair_figure_manifest.csv"
)
figure_manifest <- dplyr::bind_rows(lapply(
  c(plot_paths, source_paths, summary_path),
  function(path) {
    h06d_tr_file_record(
      root,
      path,
      "timing-repair residual display or paired source data"
    )
  }
)) |>
  dplyr::arrange(.data$relative_path)
h06d_tr_write_csv(figure_manifest, manifest_path)

message(sprintf(
  "Wrote %d residual panels, %d paired source files, and one summary.",
  length(plot_paths),
  length(source_paths)
))
