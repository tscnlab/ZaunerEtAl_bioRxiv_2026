source("scripts/hypotheses/H07/h07_stage2_core.R")

revision_id <- "H07-STAGE2-DERIVATIVE-REVISION-2026-08-07-A"
grid_points <- 100L
confidence_level <- 0.95
central_step_hours <- 0.01
v0_step_hours <- 1e-7

revision_registry <- tidyr::crossing(
  placement = c("near_eye", "chest"),
  metric_id = h07_stage2_metric_ids
) |>
  left_join(
    h07_stage2_metric_contract |>
      select(
        "metric_id",
        "metric_order",
        "manuscript_name",
        "display_unit",
        "response_family",
        "response_transform"
      ),
    by = "metric_id"
  ) |>
  arrange(
    factor(.data$placement, levels = c("near_eye", "chest")),
    .data$metric_order
  ) |>
  mutate(run_id = paste("primary", .data$placement, sep = "__"))

h07_revised_derivative_grid <- function(frame) {
  seq(
    min(frame$photoperiod_hours),
    max(frame$photoperiod_hours),
    length.out = grid_points
  )
}

h07_revised_derivatives <- function(
    fit,
    frame,
    method_id,
    type,
    eps,
    unconditional,
    boundary_aware = FALSE) {
  grid <- h07_revised_derivative_grid(frame)
  newdata <- frame[rep(1L, length(grid)), , drop = FALSE]
  newdata$photoperiod_hours <- grid

  derivative_call <- function(difference_type) {
    gratia::derivatives(
      fit,
      select = "s(photoperiod_hours)",
      data = newdata,
      order = 1L,
      type = difference_type,
      eps = eps,
      interval = "confidence",
      level = confidence_level,
      unconditional = unconditional,
      frequentist = FALSE,
      partial_match = FALSE
    ) |>
      as_tibble()
  }

  derivative <- derivative_call(type)
  if (boundary_aware) {
    forward <- derivative_call("forward")
    backward <- derivative_call("backward")
    derivative[1L, ] <- forward[1L, ]
    derivative[nrow(derivative), ] <- backward[nrow(backward), ]
  }

  required <- c(
    ".smooth",
    ".derivative",
    ".se",
    ".crit",
    ".lower_ci",
    ".upper_ci",
    "photoperiod_hours"
  )
  if (!all(required %in% names(derivative)) || nrow(derivative) != grid_points) {
    h07_stage2_abort("Unexpected revised H07 derivative output")
  }

  derivative |>
    transmute(
      method_id = method_id,
      photoperiod_hours = .data$photoperiod_hours,
      derivative_estimate = .data$.derivative,
      derivative_se = .data$.se,
      critical_value = .data$.crit,
      derivative_lower = .data$.lower_ci,
      derivative_upper = .data$.upper_ci,
      pointwise_detected_increase = .data$.lower_ci > 0,
      pointwise_detected_decrease = .data$.upper_ci < 0,
      pointwise_compatible_with_zero =
        .data$.lower_ci <= 0 & .data$.upper_ci >= 0
    ) |>
    arrange(.data$photoperiod_hours) |>
    mutate(
      zero_compatible_to_recorded_end =
        rev(cumall(rev(.data$pointwise_compatible_with_zero))),
      previous_point_detected_increase = lag(
        .data$pointwise_detected_increase,
        default = FALSE
      ),
      qualifying_transition =
        .data$previous_point_detected_increase &
        .data$pointwise_compatible_with_zero &
        .data$zero_compatible_to_recorded_end,
      derivative_state = case_when(
        .data$pointwise_detected_increase ~ "POINTWISE_DETECTED_INCREASE",
        .data$pointwise_detected_decrease ~ "POINTWISE_DETECTED_DECREASE",
        TRUE ~ "POINTWISE_COMPATIBLE_WITH_ZERO"
      )
    )
}

h07_revised_summary <- function(points) {
  transition_index <- which(points$qualifying_transition)
  transition_index <- if (length(transition_index)) {
    transition_index[[1L]]
  } else {
    NA_integer_
  }
  positive_index <- which(points$pointwise_detected_increase)
  negative_index <- which(points$pointwise_detected_decrease)
  has_transition <- is.finite(transition_index)
  end_index <- nrow(points)

  disposition <- if (has_transition) {
    "DERIVATIVE_DEFINED_PLATEAU_PATTERN"
  } else if (length(positive_index) == 0L) {
    "NO_POINTWISE_DETECTED_PRIOR_INCREASE"
  } else if (points$pointwise_detected_increase[[end_index]]) {
    "POINTWISE_DETECTED_INCREASE_AT_RECORDED_END"
  } else if (
    length(negative_index) > 0L &&
      any(negative_index > max(positive_index))
  ) {
    "LATER_POINTWISE_DETECTED_DECREASE"
  } else {
    "NO_SUSTAINED_ZERO_COMPATIBLE_TAIL"
  }

  tibble::tibble(
    method_id = points$method_id[[1L]],
    grid_points = nrow(points),
    recorded_photoperiod_min = min(points$photoperiod_hours),
    recorded_photoperiod_max = max(points$photoperiod_hours),
    any_pointwise_detected_increase = length(positive_index) > 0L,
    any_pointwise_detected_decrease = length(negative_index) > 0L,
    revised_plateau_pattern = has_transition,
    last_detected_increase = if (length(positive_index)) {
      points$photoperiod_hours[[max(positive_index)]]
    } else {
      NA_real_
    },
    plateau_transition_lower = if (has_transition) {
      points$photoperiod_hours[[transition_index - 1L]]
    } else {
      NA_real_
    },
    plateau_start = if (has_transition) {
      points$photoperiod_hours[[transition_index]]
    } else {
      NA_real_
    },
    plateau_tail_span_hours = if (has_transition) {
      points$photoperiod_hours[[end_index]] -
        points$photoperiod_hours[[transition_index]]
    } else {
      NA_real_
    },
    plateau_start_fraction_of_recorded_range = if (has_transition) {
      (points$photoperiod_hours[[transition_index]] -
         points$photoperiod_hours[[1L]]) /
        (points$photoperiod_hours[[end_index]] -
           points$photoperiod_hours[[1L]])
    } else {
      NA_real_
    },
    derivative_before_transition = if (has_transition) {
      points$derivative_estimate[[transition_index - 1L]]
    } else {
      NA_real_
    },
    derivative_before_lower = if (has_transition) {
      points$derivative_lower[[transition_index - 1L]]
    } else {
      NA_real_
    },
    derivative_before_upper = if (has_transition) {
      points$derivative_upper[[transition_index - 1L]]
    } else {
      NA_real_
    },
    derivative_at_plateau_start = if (has_transition) {
      points$derivative_estimate[[transition_index]]
    } else {
      NA_real_
    },
    derivative_at_plateau_start_lower = if (has_transition) {
      points$derivative_lower[[transition_index]]
    } else {
      NA_real_
    },
    derivative_at_plateau_start_upper = if (has_transition) {
      points$derivative_upper[[transition_index]]
    } else {
      NA_real_
    },
    derivative_at_recorded_end = points$derivative_estimate[[end_index]],
    derivative_at_recorded_end_lower = points$derivative_lower[[end_index]],
    derivative_at_recorded_end_upper = points$derivative_upper[[end_index]],
    disposition = disposition
  )
}

derivative_points <- tibble::tibble()
plateau_summary <- tibble::tibble()
photoperiod_rows <- tibble::tibble()

for (row_index in seq_len(nrow(revision_registry))) {
  row <- revision_registry[row_index, , drop = FALSE]
  frame <- readRDS(file.path(
    h07_stage2_paths$models,
    "frames",
    row$run_id,
    paste0(row$metric_id, ".rds")
  ))
  checkpoint <- readRDS(file.path(
    h07_stage2_paths$models,
    "fits",
    row$run_id,
    row$metric_id,
    "adapted_photoperiod_smooth.rds"
  ))
  if (is.null(checkpoint$fit)) {
    h07_stage2_abort(
      "Missing adapted H07 fit for %s / %s",
      row$placement,
      row$metric_id
    )
  }

  primary_points <- h07_revised_derivatives(
    fit = checkpoint$fit,
    frame = frame,
    method_id = "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE",
    type = "central",
    eps = central_step_hours,
    unconditional = TRUE,
    boundary_aware = TRUE
  )
  comparison_points <- h07_revised_derivatives(
    fit = checkpoint$fit,
    frame = frame,
    method_id = "V0_SETTINGS_FORWARD_CONDITIONAL_POINTWISE",
    type = "forward",
    eps = v0_step_hours,
    unconditional = FALSE,
    boundary_aware = FALSE
  )
  identity <- row |>
    select(
      "run_id",
      "placement",
      "metric_id",
      "metric_order",
      "manuscript_name",
      "display_unit",
      "response_family",
      "response_transform"
    )

  derivative_points <- bind_rows(
    derivative_points,
    bind_cols(
      identity[rep(1L, nrow(primary_points)), ],
      primary_points
    ),
    bind_cols(
      identity[rep(1L, nrow(comparison_points)), ],
      comparison_points
    )
  )
  plateau_summary <- bind_rows(
    plateau_summary,
    bind_cols(identity, h07_revised_summary(primary_points)),
    bind_cols(identity, h07_revised_summary(comparison_points))
  )
  photoperiod_rows <- bind_rows(
    photoperiod_rows,
    frame |>
      transmute(
        run_id = row$run_id,
        placement = row$placement,
        metric_id = row$metric_id,
        metric_order = row$metric_order,
        manuscript_name = row$manuscript_name,
        photoperiod_hours = .data$photoperiod_hours
      )
  )
  message(sprintf(
    "H07 REVISED DERIVATIVE DONE %s / %s",
    row$placement,
    row$metric_id
  ))
  rm(frame, checkpoint, primary_points, comparison_points)
  invisible(gc())
}

primary_summary <- plateau_summary |>
  filter(.data$method_id == "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE")
comparison_summary <- plateau_summary |>
  filter(.data$method_id == "V0_SETTINGS_FORWARD_CONDITIONAL_POINTWISE") |>
  select(
    "run_id",
    "metric_id",
    comparison_plateau_pattern = "revised_plateau_pattern",
    comparison_plateau_start = "plateau_start",
    comparison_disposition = "disposition"
  )

method_comparison <- primary_summary |>
  select(
    "run_id",
    "placement",
    "metric_id",
    "metric_order",
    "manuscript_name",
    primary_plateau_pattern = "revised_plateau_pattern",
    primary_plateau_start = "plateau_start",
    primary_disposition = "disposition"
  ) |>
  left_join(comparison_summary, by = c("run_id", "metric_id")) |>
  mutate(
    classification_agrees =
      .data$primary_plateau_pattern == .data$comparison_plateau_pattern,
    boundary_difference_hours = if_else(
      .data$primary_plateau_pattern & .data$comparison_plateau_pattern,
      .data$primary_plateau_start - .data$comparison_plateau_start,
      NA_real_
    )
  )

main_reference <- primary_summary |>
  select(
    "placement",
    "metric_id",
    main_plateau_pattern = "revised_plateau_pattern",
    main_plateau_start = "plateau_start",
    main_disposition = "disposition"
  )

sensitivity_registry <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_sensitivity_run_registry.csv"),
  show_col_types = FALSE,
  na = ""
) |>
  select(
    "run_id",
    "data_scenario",
    "placement",
    "sensitivity",
    "key_rule"
  )
sensitivity_samples <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_sensitivity_samples.csv"),
  show_col_types = FALSE,
  na = ""
)
sensitivity_plateau_summary <- tibble::tibble()

for (row_index in seq_len(nrow(sensitivity_samples))) {
  row <- sensitivity_samples[row_index, , drop = FALSE] |>
    left_join(sensitivity_registry, by = "run_id") |>
    left_join(
      h07_stage2_metric_contract |>
        select("metric_id", "metric_order", "manuscript_name"),
      by = "metric_id"
    )
  frame <- readRDS(file.path(
    h07_stage2_paths$models,
    "frames",
    row$run_id,
    paste0(row$metric_id, ".rds")
  ))
  checkpoint <- readRDS(file.path(
    h07_stage2_paths$models,
    "fits",
    row$run_id,
    row$metric_id,
    "adapted_photoperiod_smooth.rds"
  ))
  points <- h07_revised_derivatives(
    fit = checkpoint$fit,
    frame = frame,
    method_id = "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE",
    type = "central",
    eps = central_step_hours,
    unconditional = TRUE,
    boundary_aware = TRUE
  )
  identity <- row |>
    select(
      "run_id",
      "data_scenario",
      "placement",
      "sensitivity",
      "key_rule",
      "metric_id",
      "metric_order",
      "manuscript_name"
    )
  sensitivity_plateau_summary <- bind_rows(
    sensitivity_plateau_summary,
    bind_cols(identity, h07_revised_summary(points))
  )
  rm(frame, checkpoint, points)
  invisible(gc())
}

sensitivity_comparison <- sensitivity_plateau_summary |>
  left_join(main_reference, by = c("placement", "metric_id")) |>
  mutate(
    classification_agrees =
      .data$revised_plateau_pattern == .data$main_plateau_pattern,
    boundary_difference_hours = if_else(
      .data$revised_plateau_pattern & .data$main_plateau_pattern,
      .data$plateau_start - .data$main_plateau_start,
      NA_real_
    )
  )

main_diagnostic_registry <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_main_diagnostics.csv"),
  show_col_types = FALSE,
  na = ""
)
model_form_plateau_summary <- tibble::tibble()
for (row_index in seq_len(nrow(revision_registry))) {
  row <- revision_registry[row_index, , drop = FALSE]
  frame <- readRDS(file.path(
    h07_stage2_paths$models,
    "frames",
    row$run_id,
    paste0(row$metric_id, ".rds")
  ))
  for (model_id in c(
    "adapted_photoperiod_expanded_basis",
    "adapted_photoperiod_fixed_site"
  )) {
    diagnostic <- main_diagnostic_registry |>
      filter(
        .data$run_id == row$run_id,
        .data$metric_id == row$metric_id,
        .data$model_id == .env$model_id
      )
    if (nrow(diagnostic) != 1L) {
      h07_stage2_abort("Missing H07 model-form diagnostic")
    }
    if (diagnostic$fit_status == "FAIL_HESSIAN") {
      model_form_plateau_summary <- bind_rows(
        model_form_plateau_summary,
        row |>
          select(
            "run_id",
            "placement",
            "metric_id",
            "metric_order",
            "manuscript_name"
          ) |>
          mutate(
            model_id = model_id,
            fit_status = diagnostic$fit_status,
            revised_plateau_pattern = NA,
            plateau_start = NA_real_,
            disposition = "MODEL_DIAGNOSTIC_FAILURE"
          )
      )
      next
    }
    checkpoint <- readRDS(file.path(
      h07_stage2_paths$models,
      "fits",
      row$run_id,
      row$metric_id,
      paste0(model_id, ".rds")
    ))
    points <- h07_revised_derivatives(
      fit = checkpoint$fit,
      frame = frame,
      method_id = "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE",
      type = "central",
      eps = central_step_hours,
      unconditional = TRUE,
      boundary_aware = TRUE
    )
    model_form_plateau_summary <- bind_rows(
      model_form_plateau_summary,
      bind_cols(
        row |>
          select(
            "run_id",
            "placement",
            "metric_id",
            "metric_order",
            "manuscript_name"
          ) |>
          mutate(model_id = model_id, fit_status = diagnostic$fit_status),
        h07_revised_summary(points) |>
          select(
            "revised_plateau_pattern",
            "plateau_start",
            "disposition"
          )
      )
    )
    rm(checkpoint, points)
    invisible(gc())
  }
  rm(frame)
  invisible(gc())
}

model_form_comparison <- model_form_plateau_summary |>
  left_join(main_reference, by = c("placement", "metric_id")) |>
  mutate(
    classification_agrees = if_else(
      is.na(.data$revised_plateau_pattern),
      NA,
      .data$revised_plateau_pattern == .data$main_plateau_pattern
    ),
    boundary_difference_hours = if_else(
      .data$revised_plateau_pattern & .data$main_plateau_pattern,
      .data$plateau_start - .data$main_plateau_start,
      NA_real_
    )
  )

loso_samples <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_loso_samples.csv"),
  show_col_types = FALSE,
  na = ""
) |>
  left_join(
    h07_stage2_metric_contract |>
      select("metric_id", "metric_order", "manuscript_name"),
    by = "metric_id"
  )
loso_plateau_summary <- tibble::tibble()

for (row_index in seq_len(nrow(loso_samples))) {
  row <- loso_samples[row_index, , drop = FALSE]
  frame <- readRDS(file.path(
    h07_stage2_paths$models,
    "frames",
    row$run_id,
    paste0(row$metric_id, ".rds")
  ))
  checkpoint <- readRDS(file.path(
    h07_stage2_paths$models,
    "fits",
    row$run_id,
    row$metric_id,
    "adapted_photoperiod_smooth.rds"
  ))
  points <- h07_revised_derivatives(
    fit = checkpoint$fit,
    frame = frame,
    method_id = "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE",
    type = "central",
    eps = central_step_hours,
    unconditional = TRUE,
    boundary_aware = TRUE
  )
  identity <- row |>
    select(
      "run_id",
      "placement",
      "metric_id",
      "metric_order",
      "manuscript_name",
      "omitted_site"
    )
  loso_plateau_summary <- bind_rows(
    loso_plateau_summary,
    bind_cols(identity, h07_revised_summary(points))
  )
  rm(frame, checkpoint, points)
  invisible(gc())
}

loso_comparison <- loso_plateau_summary |>
  left_join(main_reference, by = c("placement", "metric_id")) |>
  mutate(
    classification_agrees =
      .data$revised_plateau_pattern == .data$main_plateau_pattern,
    boundary_difference_hours = if_else(
      .data$revised_plateau_pattern & .data$main_plateau_pattern,
      .data$plateau_start - .data$main_plateau_start,
      NA_real_
    )
  )

loso_influence_summary <- loso_comparison |>
  group_by(
    .data$placement,
    .data$metric_id,
    .data$metric_order,
    .data$manuscript_name,
    .data$main_plateau_pattern,
    .data$main_plateau_start
  ) |>
  summarise(
    omissions = n(),
    omissions_with_pattern = sum(.data$revised_plateau_pattern),
    omissions_matching_main = sum(.data$classification_agrees),
    all_classifications_agree = all(.data$classification_agrees),
    discordant_omissions = if (all(.data$classification_agrees)) {
      "None"
    } else {
      paste(.data$omitted_site[!.data$classification_agrees], collapse = "; ")
    },
    plateau_start_min = if (any(.data$revised_plateau_pattern)) {
      min(.data$plateau_start[.data$revised_plateau_pattern])
    } else {
      NA_real_
    },
    plateau_start_max = if (any(.data$revised_plateau_pattern)) {
      max(.data$plateau_start[.data$revised_plateau_pattern])
    } else {
      NA_real_
    },
    .groups = "drop"
  )

v0_derivative_points <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_v0_derivative_points.csv"),
  show_col_types = FALSE,
  na = ""
)
v0_aic <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_v0_aic_reconstruction.csv"),
  show_col_types = FALSE,
  na = ""
)
v0_revised_plateau_summary <- v0_derivative_points |>
  group_by(
    .data$placement,
    .data$metric_id,
    .data$metric_order,
    .data$manuscript_name
  ) |>
  group_split() |>
  purrr::map_dfr(function(group) {
    points <- group |>
      transmute(
        method_id = "V0_FIT_AND_DERIVATIVE_SETTINGS",
        photoperiod_hours = .data$photoperiod,
        derivative_estimate = .data$.derivative,
        derivative_se = .data$.se,
        critical_value = .data$.crit,
        derivative_lower = .data$.lower_ci,
        derivative_upper = .data$.upper_ci,
        pointwise_detected_increase = .data$.lower_ci > 0,
        pointwise_detected_decrease = .data$.upper_ci < 0,
        pointwise_compatible_with_zero =
          .data$.lower_ci <= 0 & .data$.upper_ci >= 0
      ) |>
      arrange(.data$photoperiod_hours) |>
      mutate(
        zero_compatible_to_recorded_end =
          rev(cumall(rev(.data$pointwise_compatible_with_zero))),
        previous_point_detected_increase = lag(
          .data$pointwise_detected_increase,
          default = FALSE
        ),
        qualifying_transition =
          .data$previous_point_detected_increase &
          .data$pointwise_compatible_with_zero &
          .data$zero_compatible_to_recorded_end
      )
    bind_cols(
      group[1L, c(
        "placement",
        "metric_id",
        "metric_order",
        "manuscript_name"
      )],
      h07_revised_summary(points)
    )
  }) |>
  left_join(
    v0_aic |>
      select(
        "placement",
        "metric_id",
        "reconstructed_retained",
        "reconstructed_dAIC"
      ),
    by = c("placement", "metric_id")
  )

assessment_settings <- tibble::tribble(
  ~setting, ~value,
  "revision_id", revision_id,
  "scientific_target", "Observed pooled photoperiod association within each metric and placement",
  "model", "adapted_photoperiod_smooth",
  "smooth", "s(photoperiod_hours, k = 6, bs = 'tp')",
  "grid", "100 equally spaced points from exact metric-specific minimum to maximum recorded photoperiod",
  "derivative", "First derivative of the fitted photoperiod smooth on its model/link scale",
  "primary_difference", "Central; forward at the lower boundary and backward at the upper boundary",
  "primary_eps_hours", as.character(central_step_hours),
  "primary_uncertainty", "95% pointwise interval using unconditional covariance where available",
  "transition", "Previous grid point has lower interval limit > 0; current and every later point have intervals containing 0",
  "pooled_support_role", "Diagnostic only; not an eligibility gate",
  "leave_one_site_out_role", "Influence diagnostic only; not an eligibility gate",
  "multiplicity", "No curve-wide or cross-metric adjustment; post-result descriptive rule",
  "interpretation", "Derivative-defined plateau pattern; not equivalence, a mechanistic ceiling, or a causal effect"
)

h07_stage2_write_table(
  derivative_points,
  "H07_revised_derivative_points.csv"
)
h07_stage2_write_table(
  plateau_summary,
  "H07_revised_plateau_summary.csv"
)
h07_stage2_write_table(
  method_comparison,
  "H07_revised_derivative_method_comparison.csv"
)
h07_stage2_write_table(
  assessment_settings,
  "H07_revised_derivative_settings.csv"
)
h07_stage2_write_table(
  photoperiod_rows,
  "H07_revised_derivative_photoperiod_rows.csv"
)
h07_stage2_write_table(
  sensitivity_plateau_summary,
  "H07_revised_sensitivity_plateau_summary.csv"
)
h07_stage2_write_table(
  sensitivity_comparison,
  "H07_revised_sensitivity_plateau_comparison.csv"
)
h07_stage2_write_table(
  model_form_comparison,
  "H07_revised_model_form_plateau_comparison.csv"
)
h07_stage2_write_table(
  loso_comparison,
  "H07_revised_loso_plateau_comparison.csv"
)
h07_stage2_write_table(
  loso_influence_summary,
  "H07_revised_loso_plateau_influence_summary.csv"
)
h07_stage2_write_table(
  v0_revised_plateau_summary,
  "H07_revised_v0_plateau_summary.csv"
)

plot_points <- derivative_points |>
  filter(.data$method_id == "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE") |>
  mutate(
    manuscript_name = factor(
      .data$manuscript_name,
      levels = h07_stage2_metric_contract$manuscript_name
    )
  )
plot_summary <- primary_summary |>
  mutate(
    manuscript_name = factor(
      .data$manuscript_name,
      levels = h07_stage2_metric_contract$manuscript_name
    )
  )
plot_rug <- photoperiod_rows |>
  mutate(
    manuscript_name = factor(
      .data$manuscript_name,
      levels = h07_stage2_metric_contract$manuscript_name
    )
  )

for (placement_value in c("near_eye", "chest")) {
  placement_points <- plot_points |>
    filter(.data$placement == .env$placement_value)
  placement_summary <- plot_summary |>
    filter(
      .data$placement == .env$placement_value,
      .data$revised_plateau_pattern
    )
  placement_rug <- plot_rug |>
    filter(.data$placement == .env$placement_value)
  placement_title <- if (placement_value == "near_eye") {
    "Near-eye — primary"
  } else {
    "Chest — complementary"
  }

  plot <- ggplot(
    placement_points,
    aes(.data$photoperiod_hours, .data$derivative_estimate)
  ) +
    geom_rect(
      data = placement_summary,
      aes(
        xmin = .data$plateau_start,
        xmax = .data$recorded_photoperiod_max,
        ymin = -Inf,
        ymax = Inf
      ),
      inherit.aes = FALSE,
      fill = "#56B4E9",
      alpha = 0.12
    ) +
    geom_hline(yintercept = 0, colour = "#4b5563", linewidth = 0.4) +
    geom_ribbon(
      aes(ymin = .data$derivative_lower, ymax = .data$derivative_upper),
      fill = "#999999",
      alpha = 0.24,
      colour = NA
    ) +
    geom_line(colour = "#111827", linewidth = 0.75) +
    geom_vline(
      data = placement_summary,
      aes(xintercept = .data$plateau_start),
      inherit.aes = FALSE,
      colour = "#0072B2",
      linewidth = 0.65,
      linetype = 2
    ) +
    geom_rug(
      data = placement_rug,
      aes(x = .data$photoperiod_hours),
      inherit.aes = FALSE,
      sides = "b",
      alpha = 0.035,
      linewidth = 0.25
    ) +
    facet_wrap(
      vars(.data$manuscript_name),
      scales = "free_y",
      ncol = 3,
      labeller = label_wrap_gen(27)
    ) +
    scale_x_continuous(breaks = seq(10, 20, by = 2)) +
    labs(
      x = "Civil photoperiod (h)",
      y = "First derivative of fitted smooth (model scale per h)",
      title = placement_title,
      subtitle = paste(
        "Grey ribbon: pointwise 95% interval.",
        "Dashed line and blue tail: requested derivative-defined plateau pattern."
      )
    ) +
    theme_minimal(base_size = 10) +
    theme(
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold", size = 9),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 10, margin = margin(b = 10)),
      plot.title.position = "plot",
      plot.margin = margin(10, 10, 10, 10),
      axis.title = element_text(size = 10)
    )

  ggplot2::ggsave(
    file.path(
      h07_stage2_paths$figures,
      paste0("H07_revised_derivative_", placement_value, ".png")
    ),
    plot,
    width = 13,
    height = 10,
    units = "in",
    dpi = 180,
    bg = "white"
  )
}

if (!all(method_comparison$classification_agrees)) {
  warning(
    "The revised derivative classification differs under the V0 settings",
    call. = FALSE
  )
}

message("H07 revised derivative-defined plateau assessment complete")
