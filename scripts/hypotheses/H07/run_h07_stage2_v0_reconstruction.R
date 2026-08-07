source("scripts/hypotheses/H07/h07_stage2_core.R")

v0_reconstruction_version <- "H07-V0-RECONSTRUCTION-2026-08-06-A"
normal_critical <- stats::qnorm(0.975)
log_zero_inflated <- LightLogR::log_zero_inflated

v0_formulas <- list(
  H7_full = stats::as.formula(
    paste0(
      "log_zero_inflated(metric) ~ s(photoperiod) + ",
      "s(site, bs = 're') + s(Id, bs = 're')"
    )
  ),
  H7_null = stats::as.formula(
    "log_zero_inflated(metric) ~ s(site, bs = 're') + s(Id, bs = 're')"
  )
)

v0_candidate_registry <- tibble::tribble(
  ~placement, ~placement_label, ~v0_name, ~metric_id,
  "near_eye", "Near eye", "Mean", "daily_geometric_mean_medi",
  "near_eye", "Near eye", "brightest_10h_mean", "m10_mean_medi",
  "near_eye", "Near eye", "darkest_10h_mean", "l10_mean_medi",
  "near_eye", "Near eye", "duration_above_1000", "duration_above_1000",
  "near_eye", "Near eye", "period_above_250", "longest_bout_above_250",
  "near_eye", "Near eye", "dose", "dose_time_sensitive_corrected_medi",
  "near_eye", "Near eye", "duration_below_10_pre-sleep", "duration_below_10_pre_sleep",
  "near_eye", "Near eye", "duration_above_250_wake", "duration_above_250_wake",
  "chest", "Chest", "Mean", "daily_geometric_mean_medi",
  "chest", "Chest", "brightest_10h_mean", "m10_mean_medi",
  "chest", "Chest", "duration_above_1000", "duration_above_1000",
  "chest", "Chest", "period_above_250", "longest_bout_above_250",
  "chest", "Chest", "dose", "dose_time_sensitive_corrected_medi",
  "chest", "Chest", "duration_above_250_wake", "duration_above_250_wake"
) |>
  left_join(
    h07_stage2_metric_contract |>
      select("metric_id", "metric_order", "manuscript_name", "display_unit"),
    by = "metric_id"
  ) |>
  arrange(factor(.data$placement, levels = c("near_eye", "chest")), .data$metric_order)

h07_v0_read_metric_list <- function(path, placement) {
  environment <- new.env(parent = emptyenv())
  object_names <- load(path, envir = environment)
  if (length(object_names) != 1L) {
    h07_stage2_abort("Unexpected object count in V0 H07 metric file: %s", path)
  }
  environment[[object_names[[1L]]]] |>
    filter(.data$name %in% v0_candidate_registry$v0_name[
      v0_candidate_registry$placement == .env$placement
    ]) |>
    transmute(
      placement = .env$placement,
      v0_name = .data$name,
      v0_metric_type = .data$metric_type,
      data = .data$data
    )
}

v0_data <- bind_rows(
  h07_v0_read_metric_list(
    h07_stage2_path("data", "metrics_glasses.RData"),
    "near_eye"
  ),
  h07_v0_read_metric_list(
    h07_stage2_path("data", "metrics_chest.RData"),
    "chest"
  )
) |>
  inner_join(
    v0_candidate_registry,
    by = c("placement", "v0_name")
  ) |>
  arrange(factor(.data$placement, levels = c("near_eye", "chest")), .data$metric_order)

h07_v0_extract_rendered_aic <- function(path, placement) {
  tables <- rvest::html_table(
    rvest::html_elements(rvest::read_html(path), "table"),
    fill = TRUE
  )
  index <- which(vapply(tables, function(table) {
    "dAIC" %in% names(table)
  }, logical(1)))
  if (length(index) != 1L) {
    h07_stage2_abort("Could not resolve the V0 H07 AIC table in %s", path)
  }
  tables[[index]] |>
    transmute(
      placement = .env$placement,
      v0_name = .data$name,
      rendered_dAIC = as.numeric(stringr::str_replace_all(.data$dAIC, "−", "-"))
    )
}

rendered_aic <- bind_rows(
  h07_v0_extract_rendered_aic(
    h07_stage2_path("docs", "RQ2.html"),
    "near_eye"
  ),
  h07_v0_extract_rendered_aic(
    h07_stage2_path("docs", "RQ2_chest.html"),
    "chest"
  )
)

v0_model_root <- h07_stage2_dir(file.path(
  h07_stage2_paths$models,
  "v0_reconstruction"
))
v0_source_root <- h07_stage2_dir(file.path(
  h07_stage2_paths$figures,
  "v0_reconstruction"
))

h07_v0_fit_pair <- function(frame, placement, metric_id) {
  directory <- h07_stage2_dir(file.path(v0_model_root, placement, metric_id))
  path <- file.path(directory, "v0_fit_pair.rds")
  frame_hash <- h07_stage2_frame_hash(frame)
  if (file.exists(path)) {
    checkpoint <- readRDS(path)
    if (
      identical(checkpoint$version, v0_reconstruction_version) &&
        identical(checkpoint$frame_sha256, frame_hash)
    ) {
      return(checkpoint)
    }
    h07_stage2_abort("Stale H07 V0 checkpoint requires explicit review: %s", path)
  }
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  fits <- withCallingHandlers(
    lapply(v0_formulas, function(formula) {
      mgcv::bam(
        formula = formula,
        data = frame,
        discrete = TRUE,
        method = "fREML",
        nthreads = 10,
        na.action = stats::na.fail,
        drop.unused.levels = TRUE
      )
    }),
    warning = function(warning) {
      warnings <<- c(warnings, conditionMessage(warning))
      invokeRestart("muffleWarning")
    }
  )
  elapsed <- proc.time()[["elapsed"]] - started
  checkpoint <- list(
    version = v0_reconstruction_version,
    r_version = as.character(getRversion()),
    mgcv_version = as.character(utils::packageVersion("mgcv")),
    gratia_version = as.character(utils::packageVersion("gratia")),
    placement = placement,
    metric_id = metric_id,
    frame_sha256 = frame_hash,
    formulas = vapply(v0_formulas, h07_stage2_formula_text, character(1)),
    engine = "mgcv::bam",
    method = "fREML",
    discrete = TRUE,
    nthreads = 10L,
    warnings = unique(warnings),
    elapsed_seconds = elapsed,
    full = fits[["H7_full"]],
    null = fits[["H7_null"]]
  )
  saveRDS(checkpoint, path, compress = "xz")
  checkpoint
}

v0_samples <- tibble::tibble()
v0_aic <- tibble::tibble()
v0_derivatives <- tibble::tibble()
v0_smooths <- tibble::tibble()
v0_boundaries <- tibble::tibble()

for (row_index in seq_len(nrow(v0_data))) {
  row <- v0_data[row_index, , drop = FALSE]
  frame <- row$data[[1L]] |>
    filter(
      is.finite(.data$metric),
      is.finite(.data$photoperiod),
      !is.na(.data$site),
      !is.na(.data$Id)
    ) |>
    mutate(
      site = factor(.data$site),
      Id = factor(.data$Id)
    ) |>
    arrange(.data$site, .data$Id, .data$Date) |>
    droplevels()
  if (nrow(frame) == 0L) {
    h07_stage2_abort("The V0 H07 frame is empty for %s", row$v0_name)
  }
  checkpoint <- h07_v0_fit_pair(
    frame,
    row$placement[[1L]],
    row$metric_id[[1L]]
  )
  aic <- stats::AIC(checkpoint$full, checkpoint$null)
  dAIC <- as.numeric(aic$AIC[[1L]] - aic$AIC[[2L]])
  derivative <- gratia::derivatives(
    checkpoint$full,
    select = "s(photoperiod)",
    order = 1,
    type = "forward",
    n = 100,
    eps = 1e-7,
    interval = "confidence",
    level = 0.95,
    unconditional = FALSE
  )
  smooth <- gratia::smooth_estimates(
    checkpoint$full,
    select = "s(photoperiod)",
    n = 100
  )
  positive <- derivative |>
    filter(.data$.lower_ci > 0) |>
    slice_tail(n = 1L)
  identity <- tibble::tibble(
    placement = row$placement[[1L]],
    placement_label = row$placement_label[[1L]],
    metric_id = row$metric_id[[1L]],
    metric_order = row$metric_order[[1L]],
    v0_name = row$v0_name[[1L]],
    manuscript_name = row$manuscript_name[[1L]]
  )
  v0_samples <- bind_rows(
    v0_samples,
    identity |>
      mutate(
        participants = n_distinct(frame$site, frame$Id),
        participant_days = nrow(frame),
        observations = nrow(frame),
        sites = n_distinct(frame$site),
        photoperiod_min = min(frame$photoperiod),
        photoperiod_max = max(frame$photoperiod),
        frame_sha256 = checkpoint$frame_sha256
      )
  )
  v0_aic <- bind_rows(
    v0_aic,
    identity |>
      mutate(
        aic_full = as.numeric(aic$AIC[[1L]]),
        aic_null = as.numeric(aic$AIC[[2L]]),
        reconstructed_dAIC = dAIC,
        reconstructed_retained = dAIC < -2,
        edf2_full_available = !is.null(checkpoint$full$edf2),
        edf2_null_available = !is.null(checkpoint$null$edf2),
        elapsed_seconds = checkpoint$elapsed_seconds,
        warnings = paste(checkpoint$warnings, collapse = " | ")
      )
  )
  v0_derivatives <- bind_rows(
    v0_derivatives,
    bind_cols(identity[rep(1L, nrow(derivative)), ], as_tibble(derivative))
  )
  v0_smooths <- bind_rows(
    v0_smooths,
    bind_cols(identity[rep(1L, nrow(smooth)), ], as_tibble(smooth))
  )
  v0_boundaries <- bind_rows(
    v0_boundaries,
    identity |>
      mutate(
        last_detected_increase_photoperiod = if (nrow(positive)) {
          positive$photoperiod[[1L]]
        } else {
          NA_real_
        },
        last_detected_increase_derivative = if (nrow(positive)) {
          positive$.derivative[[1L]]
        } else {
          NA_real_
        },
        last_detected_increase_lower = if (nrow(positive)) {
          positive$.lower_ci[[1L]]
        } else {
          NA_real_
        },
        last_detected_increase_upper = if (nrow(positive)) {
          positive$.upper_ci[[1L]]
        } else {
          NA_real_
        },
        boundary_interpretation =
          "LAST_POINT_WITH_POINTWISE_DETECTED_INCREASE_NOT_A_CEILING"
      )
  )
  message(sprintf(
    "H07 V0 DONE %s / %s: dAIC %.3f",
    row$placement,
    row$metric_id,
    dAIC
  ))
  rm(frame, checkpoint, derivative, smooth)
  invisible(gc())
}

v0_aic_comparison <- v0_aic |>
  left_join(rendered_aic, by = c("placement", "v0_name")) |>
  mutate(
    rendered_retained = is.finite(.data$rendered_dAIC),
    rendered_minus_reconstructed =
      .data$rendered_dAIC - .data$reconstructed_dAIC,
    retention_reproduced =
      .data$rendered_retained == .data$reconstructed_retained,
    numeric_reproduction_status = case_when(
      !.data$rendered_retained & !.data$reconstructed_retained ~
        "RETENTION_REPRODUCED_RENDERED_VALUE_NOT_AVAILABLE",
      is.finite(.data$rendered_minus_reconstructed) &
        abs(.data$rendered_minus_reconstructed) <= 0.02 ~
        "PASS_WITHIN_RENDERED_ROUNDING",
      TRUE ~ "REVIEW_NUMERIC_DIFFERENCE"
    )
  ) |>
  arrange(factor(.data$placement, levels = c("near_eye", "chest")), .data$metric_order)

if (any(!v0_aic_comparison$retention_reproduced)) {
  h07_stage2_abort("The H07 V0 reconstruction did not reproduce model retention")
}

readr::write_csv(
  tibble::tibble(
    formula_id = names(v0_formulas),
    formula = vapply(v0_formulas, h07_stage2_formula_text, character(1)),
    engine = "mgcv::bam",
    method = "fREML",
    discrete = TRUE,
    nthreads = 10L
  ),
  file.path(h07_stage2_paths$tables, "H07_v0_formula_registry.csv")
)
readr::write_csv(
  v0_samples,
  file.path(h07_stage2_paths$tables, "H07_v0_samples.csv"),
  na = ""
)
readr::write_csv(
  v0_aic_comparison,
  file.path(h07_stage2_paths$tables, "H07_v0_aic_reconstruction.csv"),
  na = ""
)
readr::write_csv(
  v0_derivatives,
  file.path(h07_stage2_paths$tables, "H07_v0_derivative_points.csv"),
  na = ""
)
readr::write_csv(
  v0_smooths,
  file.path(h07_stage2_paths$tables, "H07_v0_smooth_points.csv"),
  na = ""
)
readr::write_csv(
  v0_boundaries |>
    left_join(
      v0_aic_comparison |>
        select("placement", "metric_id", "reconstructed_retained"),
      by = c("placement", "metric_id")
    ),
  file.path(h07_stage2_paths$tables, "H07_v0_last_detected_increase.csv"),
  na = ""
)

retained <- v0_aic_comparison |>
  filter(.data$reconstructed_retained) |>
  select("placement", "metric_id")
plot_smooth <- v0_smooths |>
  inner_join(retained, by = c("placement", "metric_id")) |>
  transmute(
    placement,
    metric_id,
    metric_order,
    manuscript_name,
    component = "V0 smooth term",
    photoperiod = .data$photoperiod,
    estimate = .data$.estimate,
    lower = .data$.estimate - normal_critical * .data$.se,
    upper = .data$.estimate + normal_critical * .data$.se
  )
plot_derivative <- v0_derivatives |>
  inner_join(retained, by = c("placement", "metric_id")) |>
  transmute(
    placement,
    metric_id,
    metric_order,
    manuscript_name,
    component = "V0 derivative",
    photoperiod = .data$photoperiod,
    estimate = .data$.derivative,
    lower = .data$.lower_ci,
    upper = .data$.upper_ci
  )
plot_data <- bind_rows(plot_smooth, plot_derivative) |>
  left_join(
    v0_boundaries |>
      select(
        "placement",
        "metric_id",
        "last_detected_increase_photoperiod"
      ),
    by = c("placement", "metric_id")
  ) |>
  mutate(
    component = factor(
      .data$component,
      levels = c("V0 smooth term", "V0 derivative")
    )
  )
readr::write_csv(
  plot_data,
  file.path(v0_source_root, "H07_v0_corrected_figure_source.csv"),
  na = ""
)

for (placement_value in c("near_eye", "chest")) {
  placement_data <- plot_data |>
    filter(.data$placement == .env$placement_value) |>
    mutate(
      manuscript_name = factor(
        .data$manuscript_name,
        levels = h07_stage2_metric_contract$manuscript_name
      )
    )
  plot <- ggplot(
    placement_data,
    aes(.data$photoperiod, .data$estimate)
  ) +
    geom_hline(
      data = ~ filter(.x, .data$component == "V0 derivative"),
      aes(yintercept = 0),
      inherit.aes = FALSE,
      colour = "#b91c1c",
      linewidth = 0.35
    ) +
    geom_ribbon(
      aes(ymin = .data$lower, ymax = .data$upper),
      fill = "#60a5fa",
      alpha = 0.22,
      colour = NA
    ) +
    geom_line(colour = "#1f2937", linewidth = 0.75) +
    geom_vline(
      aes(xintercept = .data$last_detected_increase_photoperiod),
      colour = "#b91c1c",
      linewidth = 0.45,
      linetype = 2
    ) +
    facet_grid(
      rows = vars(.data$manuscript_name),
      cols = vars(.data$component),
      scales = "free_y",
      labeller = label_wrap_gen(28)
    ) +
    scale_x_continuous(breaks = seq(10, 20, by = 2)) +
    labs(
      x = "Civil photoperiod (h)",
      y = "V0 model scale",
      title = paste0(
        "Corrected V0 H07 reconstruction — ",
        if_else(placement_value == "near_eye", "near eye", "chest")
      ),
      subtitle = paste(
        "Dashed red line: last grid point with a pointwise-detected increase;",
        "it is not a ceiling. Each retained metric appears once."
      )
    ) +
    theme_minimal(base_size = 10) +
    theme(
      panel.grid.minor = element_blank(),
      strip.text.y = element_text(face = "bold", size = 9, angle = 0),
      strip.text.x = element_text(face = "bold", size = 10),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 10)
    )
  retained_n <- n_distinct(placement_data$metric_id)
  ggplot2::ggsave(
    file.path(
      h07_stage2_paths$figures,
      paste0("H07_v0_corrected_", placement_value, ".png")
    ),
    plot,
    width = 13,
    height = 2.5 + retained_n * 2.15,
    units = "in",
    dpi = 180,
    bg = "white"
  )
}

message("H07 V0 model, derivative, boundary, and corrected-figure reconstruction complete")
