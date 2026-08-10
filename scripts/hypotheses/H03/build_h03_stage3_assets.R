#!/usr/bin/env Rscript

# Build reader-facing H03 temporal assets from the approved saved raw-mean
# GAM fits. This script does not fit or refit a model and runs no resampling or
# simulation.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_contract.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_data.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_modeling.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_temporal.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_reporting.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 Stage 3 assets require R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tidyr", "tibble", "readr", "ggplot2", "scales",
  "gratia", "LightLogR", "cowplot", "patchwork", "svglite", "ragg"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h03_abort(
    "Missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H03/build_h03_stage3_assets.R"
model_root <- file.path(root, "artifacts/07_models/H03")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H03")
table_root <- file.path(root, "artifacts/09_tables/H03")
figure_root <- file.path(root, "artifacts/10_figures/H03")
source_root <- file.path(root, "artifacts/11_source_data/H03")
manifest_root <- file.path(root, "artifacts/12_manifests/H03")
invisible(lapply(
  c(diagnostic_root, table_root, figure_root, source_root, manifest_root),
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

raw_manifest_path <- file.path(
  manifest_root,
  "H03_temporal_raw_mean_pilot_manifest.csv"
)
raw_manifest <- readr::read_csv(raw_manifest_path, show_col_types = FALSE)
if (nrow(raw_manifest) != 16L || any(!file.exists(raw_manifest$path))) {
  h03_abort("The approved raw-mean temporal artifact set is incomplete")
}
observed_hashes <- unname(vapply(
  raw_manifest$path,
  artifact_sha256,
  character(1)
))
if (!identical(observed_hashes, raw_manifest$sha256)) {
  changed <- raw_manifest$path[observed_hashes != raw_manifest$sha256]
  h03_abort(
    "Approved raw-mean temporal artifact identity changed: %s",
    paste(basename(changed), collapse = ", ")
  )
}

inputs <- h03_load_inputs(root)
support_all <- readr::read_csv(
  file.path(source_root, "H03_temporal_clock_support.csv"),
  show_col_types = FALSE
)
working_power <- h03_specification()$working_tweedie_power
metadata <- list()

write_stage3_csv <- function(data, path, role) {
  metadata[[role]] <<- write_csv_artifact(data, path, producer)
  invisible(path)
}

placements <- list(
  near_eye = list(id = "near_eye", placement = "Near-eye"),
  chest = list(id = "chest", placement = "Chest")
)

model_summaries <- list()
weighted_r_squared <- list()
variance_allocations <- list()
variance_covariances <- list()
penalty_variances <- list()
k_checks <- list()
residual_points <- list()
residual_bins <- list()
residual_acf <- list()
zero_calibration <- list()

for (key in names(placements)) {
  entry <- placements[[key]]
  message("Processing saved raw-mean temporal fit: ", entry$placement)
  model_path <- file.path(
    model_root,
    paste0("H03_temporal_raw_mean_", entry$id, "_pilot_object.rds")
  )
  object <- readRDS(model_path)
  if (
    !inherits(object$final, "gam") ||
      !identical(object$placement, entry$placement) ||
      !isTRUE(all.equal(object$working_power, working_power)) ||
      nrow(object$data) < 1L
  ) {
    h03_abort("Saved temporal object violates the Stage 3 contract")
  }

  diagnostic_path <- file.path(
    diagnostic_root,
    paste0("H03_temporal_raw_mean_", entry$id, "_pilot_diagnostics.csv")
  )
  model_summaries[[key]] <- readr::read_csv(
    diagnostic_path,
    show_col_types = FALSE
  ) |>
    dplyr::mutate(
      run_id = paste0("reader_temporal_raw_mean__", entry$id),
      inferential_role = paste(
        "exploratory time-of-day conditional-mean context;",
        "no simultaneous-band or curve-wide inference"
      )
    )

  curve_source <- readr::read_csv(
    file.path(
      source_root,
      paste0("H03_temporal_raw_mean_", entry$id, "_pilot_curves.csv")
    ),
    show_col_types = FALSE
  ) |>
    dplyr::mutate(run_id = paste0("reader_temporal_raw_mean__", entry$id))
  ratio_source <- readr::read_csv(
    file.path(
      source_root,
      paste0("H03_temporal_raw_mean_", entry$id, "_pilot_ratios.csv")
    ),
    show_col_types = FALSE
  ) |>
    dplyr::mutate(run_id = paste0("reader_temporal_raw_mean__", entry$id))
  global_source <- readr::read_csv(
    file.path(
      source_root,
      paste0("H03_temporal_raw_mean_", entry$id, "_pilot_global.csv")
    ),
    show_col_types = FALSE
  ) |>
    dplyr::mutate(run_id = paste0("reader_temporal_raw_mean__", entry$id))
  support <- support_all |>
    dplyr::filter(.data$placement == entry$placement)

  write_stage3_csv(
    curve_source,
    file.path(
      source_root,
      paste0("H03_reader_temporal_", entry$id, "_curves.csv")
    ),
    paste0(key, "_curves")
  )
  write_stage3_csv(
    ratio_source,
    file.path(
      source_root,
      paste0("H03_reader_temporal_", entry$id, "_ratios.csv")
    ),
    paste0(key, "_ratios")
  )
  write_stage3_csv(
    global_source,
    file.path(
      source_root,
      paste0("H03_reader_temporal_", entry$id, "_global.csv")
    ),
    paste0(key, "_global")
  )
  write_stage3_csv(
    support,
    file.path(
      source_root,
      paste0("H03_reader_temporal_", entry$id, "_support.csv")
    ),
    paste0(key, "_support")
  )

  temporal_figure <- h03_temporal_figure(
    curves = curve_source,
    deviations = ratio_source,
    global = global_source,
    support = support,
    category_registry = inputs$categories,
    placement = entry$placement,
    ratio_data = ratio_source,
    curve_title = paste0(
      entry$placement,
      ": expected one-hour melEDI by time of day"
    ),
    model_caption = paste0(
      "Exploratory fixed-power Tweedie mean GAM (p = ",
      sprintf("%.6f", working_power),
      "; log link)."
    ),
    ratio_caption = paste(
      "Panel B divides each displayed category mean by the displayed global",
      "time-of-day mean; the dashed reference is 1."
    ),
    facet_ncol = 7L,
    curve_breaks = c(0, 1, 10, 100, 250, 1000, 10000)
  )
  saved_temporal <- h03_save_plot(
    temporal_figure,
    paste0("H03_reader_temporal_", entry$id),
    figure_root,
    width = 15.75,
    height = 10.4,
    producer = producer
  )
  for (extension in names(saved_temporal)) {
    metadata[[paste0(key, "_temporal_figure_", extension)]] <-
      saved_temporal[[extension]]
  }

  weights <- h03_temporal_weights(object$data)
  response <- object$data$geo_medi_1h
  fitted_mean <- stats::fitted(object$final)
  response_mean <- sum(weights * response)
  weighted_sse <- sum(weights * (response - fitted_mean)^2)
  weighted_sst <- sum(weights * (response - response_mean)^2)
  weighted_r_squared[[key]] <- tibble::tibble(
    run_id = paste0("reader_temporal_raw_mean__", entry$id),
    placement = entry$placement,
    estimand = paste(
      "site-standardized participant-balanced in-sample R-squared",
      "for the conditional arithmetic mean"
    ),
    scale = "raw one-hour geometric melEDI (lx)",
    r_squared = 1 - weighted_sse / weighted_sst,
    weighted_sse = weighted_sse,
    weighted_sst = weighted_sst,
    weight_sum = sum(weights),
    sites_equal_weight = TRUE,
    participants_equal_within_site = TRUE,
    hours_equal_within_participant = TRUE,
    uncertainty = "point estimate; no resampling interval computed"
  )

  term_names <- colnames(stats::predict(object$final, type = "terms"))
  expected_terms <- c(
    "s(time_hour)",
    "s(time_hour,light_source)",
    "s(time_hour,site)",
    "s(time_hour,participant)",
    "s(participant_day)"
  )
  if (!setequal(term_names, expected_terms)) {
    h03_abort(
      "Unexpected temporal terms for %s: %s",
      entry$placement,
      paste(term_names, collapse = "; ")
    )
  }
  groups <- list(
    global_time = "s(time_hour)",
    light_source_deviations = "s(time_hour,light_source)",
    site_deviations = "s(time_hour,site)",
    participant_curves = "s(time_hour,participant)",
    participant_day_shifts = "s(participant_day)"
  )
  partition <- gamm_variance_partition(
    object$final,
    data = object$data,
    groups = groups,
    weights = weights,
    n_draws = 0L
  )
  variance_allocations[[key]] <- partition$allocation |>
    dplyr::mutate(
      run_id = paste0("reader_temporal_raw_mean__", entry$id),
      placement = entry$placement,
      total_fitted_predictor_variance = partition$total_variance,
      shapley_efficiency_error = partition$shapley_efficiency_error,
      scale = "natural-log conditional-mean linear predictor",
      reference_distribution = paste(
        "sites equally weighted; participants equally weighted within site;",
        "hours equally weighted within participant"
      ),
      uncertainty = "point allocation; no simulation interval computed",
      .before = 1
    )
  variance_covariances[[key]] <- as.data.frame(
    as.table(partition$covariance)
  ) |>
    tibble::as_tibble() |>
    dplyr::rename(
      group_1 = "Var1",
      group_2 = "Var2",
      covariance = "Freq"
    ) |>
    dplyr::mutate(
      run_id = paste0("reader_temporal_raw_mean__", entry$id),
      placement = entry$placement,
      scale = "natural-log conditional-mean linear predictor",
      .before = 1
    )
  penalty_variances[[key]] <- h03_temporal_variance_components(
    object,
    entry$placement
  ) |>
    dplyr::mutate(
      run_id = paste0("reader_temporal_raw_mean__", entry$id),
      interpretation = paste(
        "penalty-scale variance/standard-deviation parameter;",
        "not a percentage of raw melEDI variance"
      )
    )
  k_checks[[key]] <- h03_temporal_k_check(object, entry$placement) |>
    dplyr::mutate(run_id = paste0("reader_temporal_raw_mean__", entry$id))

  standardized_residual <- if (
    !is.null(object$final$std.rsd) &&
      length(object$final$std.rsd) == nrow(object$data)
  ) {
    object$final$std.rsd
  } else {
    stats::residuals(object$final, type = "pearson")
  }
  dispersion <- summary(object$final)$scale
  lambda <- fitted_mean^(2 - working_power) /
    (dispersion * (2 - working_power))
  working_zero_probability <- exp(-lambda)
  points <- tibble::tibble(
    run_id = paste0("reader_temporal_raw_mean__", entry$id),
    placement = entry$placement,
    participant = as.character(object$data$participant),
    participant_day = as.character(object$data$participant_day),
    site = as.character(object$data$site),
    light_source = as.character(object$data$light_source),
    time_hour = object$data$time_hour,
    fitted_mean_lx = fitted_mean,
    observed_mel_edi_lx = response,
    standardized_residual = standardized_residual,
    observed_zero = response == 0,
    working_zero_probability = working_zero_probability,
    AR_start = object$data$AR_start
  )
  residual_points[[key]] <- points
  residual_bins[[key]] <- points |>
    dplyr::mutate(bin = dplyr::ntile(.data$fitted_mean_lx, 24L)) |>
    dplyr::group_by(.data$run_id, .data$placement, .data$bin) |>
    dplyr::summarise(
      observations = dplyr::n(),
      fitted_mean_lx = mean(.data$fitted_mean_lx),
      residual_mean = mean(.data$standardized_residual),
      residual_q25 = stats::quantile(
        .data$standardized_residual,
        0.25,
        names = FALSE
      ),
      residual_q75 = stats::quantile(
        .data$standardized_residual,
        0.75,
        names = FALSE
      ),
      .groups = "drop"
    )
  residual_acf[[key]] <- h03_temporal_residual_acf(
    object,
    entry$placement,
    max_lag = 6L
  ) |>
    dplyr::mutate(run_id = paste0("reader_temporal_raw_mean__", entry$id))
  zero_calibration[[key]] <- points |>
    dplyr::mutate(bin = dplyr::ntile(.data$fitted_mean_lx, 10L)) |>
    dplyr::group_by(.data$run_id, .data$placement, .data$bin) |>
    dplyr::summarise(
      observations = dplyr::n(),
      fitted_mean_lx = mean(.data$fitted_mean_lx),
      observed_zero_fraction = mean(.data$observed_zero),
      working_zero_fraction = mean(.data$working_zero_probability),
      .groups = "drop"
    )

  rm(object)
  invisible(gc())
}

model_summary_data <- dplyr::bind_rows(model_summaries)
weighted_r_squared_data <- dplyr::bind_rows(weighted_r_squared)
variance_allocation_data <- dplyr::bind_rows(variance_allocations)
variance_covariance_data <- dplyr::bind_rows(variance_covariances)
penalty_variance_data <- dplyr::bind_rows(penalty_variances)
k_check_data <- dplyr::bind_rows(k_checks)
residual_point_data <- dplyr::bind_rows(residual_points)
residual_bin_data <- dplyr::bind_rows(residual_bins)
residual_acf_data <- dplyr::bind_rows(residual_acf)
zero_calibration_data <- dplyr::bind_rows(zero_calibration)

if (any(abs(variance_allocation_data$shapley_efficiency_error) > 1e-10)) {
  h03_abort("Temporal Shapley allocation failed its efficiency identity")
}

write_stage3_csv(
  model_summary_data,
  file.path(table_root, "H03_reader_temporal_model_summary.csv"),
  "temporal_model_summary"
)
write_stage3_csv(
  weighted_r_squared_data,
  file.path(table_root, "H03_reader_temporal_weighted_r_squared.csv"),
  "temporal_weighted_r_squared"
)
write_stage3_csv(
  variance_allocation_data,
  file.path(table_root, "H03_reader_temporal_variance_allocation.csv"),
  "temporal_variance_allocation"
)
write_stage3_csv(
  variance_covariance_data,
  file.path(table_root, "H03_reader_temporal_component_covariance.csv"),
  "temporal_component_covariance"
)
write_stage3_csv(
  penalty_variance_data,
  file.path(table_root, "H03_reader_temporal_penalty_variances.csv"),
  "temporal_penalty_variances"
)
write_stage3_csv(
  k_check_data,
  file.path(diagnostic_root, "H03_reader_temporal_k_check.csv"),
  "temporal_k_check"
)
write_stage3_csv(
  residual_point_data,
  file.path(source_root, "H03_reader_temporal_residual_points.csv"),
  "temporal_residual_points"
)
write_stage3_csv(
  residual_bin_data,
  file.path(source_root, "H03_reader_temporal_residual_bins.csv"),
  "temporal_residual_bins"
)
write_stage3_csv(
  residual_acf_data,
  file.path(diagnostic_root, "H03_reader_temporal_residual_acf.csv"),
  "temporal_residual_acf"
)
write_stage3_csv(
  zero_calibration_data,
  file.path(source_root, "H03_reader_temporal_zero_calibration.csv"),
  "temporal_zero_calibration"
)

diagnostic_point_sample <- residual_point_data |>
  dplyr::group_by(.data$placement) |>
  dplyr::mutate(
    plot_row = dplyr::row_number(),
    plot_stride = ceiling(dplyr::n() / 8000L)
  ) |>
  dplyr::filter((.data$plot_row - 1L) %% .data$plot_stride == 0L) |>
  dplyr::select(-"plot_row", -"plot_stride") |>
  dplyr::ungroup()

diagnostic_a <- ggplot2::ggplot(
  diagnostic_point_sample,
  ggplot2::aes(
    x = .data$fitted_mean_lx,
    y = .data$standardized_residual
  )
) +
  ggplot2::geom_point(size = 0.45, alpha = 0.10, colour = "grey35") +
  ggplot2::geom_linerange(
    data = residual_bin_data,
    ggplot2::aes(
      x = .data$fitted_mean_lx,
      ymin = .data$residual_q25,
      ymax = .data$residual_q75
    ),
    inherit.aes = FALSE,
    linewidth = 0.6,
    colour = "#4477AA"
  ) +
  ggplot2::geom_line(
    data = residual_bin_data,
    ggplot2::aes(
      x = .data$fitted_mean_lx,
      y = .data$residual_mean,
      group = .data$placement
    ),
    inherit.aes = FALSE,
    linewidth = 0.8,
    colour = "#4477AA"
  ) +
  ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45") +
  ggplot2::facet_wrap(ggplot2::vars(.data$placement), nrow = 1) +
  ggplot2::scale_x_continuous(
    trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
    breaks = c(0, 1, 10, 100, 1000, 10000),
    labels = scales::label_number(big.mark = ",")
  ) +
  ggplot2::coord_cartesian(ylim = c(-4, 8)) +
  ggplot2::labs(
    title = "Residual pattern across fitted melEDI",
    x = "Fitted one-hour melEDI (lx)",
    y = "Standardized residual"
  ) +
  h03_figure_theme()

diagnostic_b <- ggplot2::ggplot(
  residual_acf_data,
  ggplot2::aes(
    x = .data$lag,
    y = .data$correlation,
    colour = .data$placement,
    group = .data$placement
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey45") +
  ggplot2::geom_line(linewidth = 0.85) +
  ggplot2::geom_point(size = 2.3) +
  ggplot2::scale_colour_manual(
    values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
  ) +
  ggplot2::scale_x_continuous(breaks = 1:6) +
  ggplot2::labs(
    title = "Residual dependence within uninterrupted sequences",
    x = "Lag (hours)",
    y = "Residual correlation",
    colour = "Placement"
  ) +
  h03_figure_theme() +
  ggplot2::theme(legend.position = "top")

zero_long <- zero_calibration_data |>
  tidyr::pivot_longer(
    c("observed_zero_fraction", "working_zero_fraction"),
    names_to = "series",
    values_to = "zero_fraction"
  ) |>
  dplyr::mutate(
    series = factor(
      .data$series,
      levels = c("observed_zero_fraction", "working_zero_fraction"),
      labels = c("Observed", "Working Tweedie")
    )
  )
diagnostic_c <- ggplot2::ggplot(
  zero_long,
  ggplot2::aes(
    x = .data$fitted_mean_lx,
    y = .data$zero_fraction,
    colour = .data$series,
    shape = .data$series,
    group = .data$series
  )
) +
  ggplot2::geom_line(linewidth = 0.8) +
  ggplot2::geom_point(size = 2.2) +
  ggplot2::facet_wrap(ggplot2::vars(.data$placement), nrow = 1) +
  ggplot2::scale_x_continuous(
    trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
    breaks = c(0, 1, 10, 100, 1000, 10000),
    labels = scales::label_number(big.mark = ",")
  ) +
  ggplot2::scale_y_continuous(
    limits = c(0, 1),
    labels = scales::label_percent(accuracy = 1)
  ) +
  ggplot2::scale_colour_manual(
    values = c("Observed" = "#0072B2", "Working Tweedie" = "#CC6677")
  ) +
  ggplot2::labs(
    title = "Observed and working-model zero fractions",
    x = "Mean fitted melEDI in decile (lx)",
    y = "Exact-zero fraction",
    colour = NULL,
    shape = NULL
  ) +
  h03_figure_theme() +
  ggplot2::theme(legend.position = "top")

diagnostic_figure <- patchwork::wrap_plots(
  diagnostic_a,
  diagnostic_b,
  diagnostic_c,
  ncol = 1,
  heights = c(1.2, 0.9, 1.1)
) +
  patchwork::plot_annotation(tag_levels = "A")
saved_diagnostics <- h03_save_plot(
  diagnostic_figure,
  "H03_reader_temporal_diagnostics",
  figure_root,
  width = 13.4,
  height = 12.2,
  producer = producer
)
for (extension in names(saved_diagnostics)) {
  metadata[[paste0("temporal_diagnostic_figure_", extension)]] <-
    saved_diagnostics[[extension]]
}

figure_qa <- tibble::tribble(
  ~figure, ~base_width_in, ~base_height_in, ~export_scale_multiplier,
  ~export_width_in, ~export_height_in, ~raster_dpi,
  ~intended_display_width_mm, ~display_reduction_factor,
  ~smallest_essential_nominal_pt, ~smallest_essential_effective_pt,
  ~final_asset_tightly_bounded,
  "H03_reader_temporal_near_eye", 15.75, 10.4, 1, 15.75, 10.4, 300,
  170, (170 / 25.4) / 15.75, 12, 12 * (170 / 25.4) / 15.75, TRUE,
  "H03_reader_temporal_chest", 15.75, 10.4, 1, 15.75, 10.4, 300,
  170, (170 / 25.4) / 15.75, 12, 12 * (170 / 25.4) / 15.75, TRUE,
  "H03_reader_temporal_diagnostics", 13.4, 12.2, 1, 13.4, 12.2, 300,
  170, (170 / 25.4) / 13.4, 12, 12 * (170 / 25.4) / 13.4, TRUE
)
write_stage3_csv(
  figure_qa,
  file.path(manifest_root, "H03_stage3_figure_readability_qa.csv"),
  "figure_readability_qa"
)

manifest <- dplyr::bind_rows(lapply(metadata, manifest_row)) |>
  dplyr::arrange(.data$path)
write_csv_artifact(
  manifest,
  file.path(manifest_root, "H03_stage3_reader_asset_manifest.csv"),
  producer
)

message(
  "H03 Stage 3 reader assets complete; saved fits only, no refit, ",
  "resampling, or simulation"
)
