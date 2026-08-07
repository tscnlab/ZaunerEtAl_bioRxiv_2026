source("scripts/hypotheses/H07/h07_stage2_core.R")

normal_critical <- stats::qnorm(0.975)

h07_sensitivity_inverse <- function(eta, spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    exp(eta)
  } else if (identical(spec$response_transform[[1L]], "log10_offset_0.1")) {
    10^eta - 0.1
  } else {
    eta
  }
}

h07_sensitivity_curve <- function(fit, frame, grid) {
  spec <- attr(frame, "h07_spec")
  newdata <- frame[rep(1L, length(grid)), , drop = FALSE]
  newdata$photoperiod_hours <- grid
  labels <- vapply(fit$smooth, function(smooth) smooth$label, character(1))
  excluded <- intersect(labels, c("s(site)", "s(site_participant)"))
  prediction <- stats::predict(
    fit,
    newdata = newdata,
    type = "link",
    se.fit = TRUE,
    unconditional = TRUE,
    exclude = excluded
  )
  estimate <- as.numeric(prediction$fit)
  se <- as.numeric(prediction$se.fit)
  tibble::tibble(
    photoperiod_hours = round(grid, 1),
    response_estimate = h07_sensitivity_inverse(estimate, spec),
    response_lower_pointwise = h07_sensitivity_inverse(
      estimate - normal_critical * se,
      spec
    ),
    response_upper_pointwise = h07_sensitivity_inverse(
      estimate + normal_critical * se,
      spec
    )
  )
}

h07_sensitivity_aggregate_support <- function(data) {
  if (nrow(data) == 0L) {
    return(c(
      sites = 0,
      participants = 0,
      participant_days = 0,
      max_site_share = NA_real_,
      passes = 0
    ))
  }
  participant_days <- sum(data$participant_days)
  max_site_share <- if (participant_days > 0) {
    max(data$participant_days / participant_days)
  } else {
    NA_real_
  }
  c(
    sites = nrow(data),
    participants = sum(data$participants),
    participant_days = participant_days,
    max_site_share = max_site_share,
    passes = as.numeric(
      nrow(data) >= 3L &&
        sum(data$participants) >= 20L &&
        participant_days >= 60L &&
        is.finite(max_site_share) &&
        max_site_share <= 0.50
    )
  )
}

h07_sensitivity_support_point <- function(frame, value) {
  by_site <- frame |>
    group_by(.data$site) |>
    summarise(
      q05 = stats::quantile(.data$photoperiod_hours, 0.05, names = FALSE),
      q95 = stats::quantile(.data$photoperiod_hours, 0.95, names = FALSE),
      participants = n_distinct(
        .data$Id[abs(.data$photoperiod_hours - .env$value) <= 0.5]
      ),
      participant_days = sum(abs(.data$photoperiod_hours - .env$value) <= 0.5),
      .groups = "drop"
    ) |>
    filter(
      .env$value >= .data$q05,
      .env$value <= .data$q95,
      .data$participants >= 5L,
      .data$participant_days >= 15L
    )
  pooled <- h07_sensitivity_aggregate_support(by_site)
  omitted <- levels(frame$site)
  loso <- all(vapply(
    omitted,
    function(site_value) {
      h07_sensitivity_aggregate_support(
        by_site |>
          filter(as.character(.data$site) != .env$site_value)
      )[["passes"]] == 1
    },
    logical(1)
  ))
  tibble::tibble(
    photoperiod_hours = round(value, 1),
    support_sites = pooled[["sites"]],
    support_participants = pooled[["participants"]],
    support_participant_days = pooled[["participant_days"]],
    support_max_site_share = pooled[["max_site_share"]],
    pooled_eligible = pooled[["passes"]] == 1,
    loso_eligible = loso
  )
}

h07_sensitivity_support <- function(frame, grid) {
  purrr::map_dfr(grid, ~ h07_sensitivity_support_point(frame, .x))
}

sensitivity_registry <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_sensitivity_run_registry.csv"),
  show_col_types = FALSE
)
sensitivity_samples <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_sensitivity_samples.csv"),
  show_col_types = FALSE
)

sensitivity_curve_points <- tibble::tibble()
for (row_index in seq_len(nrow(sensitivity_samples))) {
  sample <- sensitivity_samples[row_index, , drop = FALSE]
  run <- sensitivity_registry |>
    filter(.data$run_id == sample$run_id[[1L]])
  if (nrow(run) != 1L) {
    h07_stage2_abort("Could not resolve H07 sensitivity run: %s", sample$run_id)
  }
  frame <- readRDS(file.path(
    h07_stage2_paths$models,
    "frames",
    sample$run_id,
    paste0(sample$metric_id, ".rds")
  ))
  checkpoint <- readRDS(file.path(
    h07_stage2_paths$models,
    "fits",
    sample$run_id,
    sample$metric_id,
    "adapted_photoperiod_smooth.rds"
  ))
  grid <- seq(
    floor(min(frame$photoperiod_hours) * 10) / 10,
    ceiling(max(frame$photoperiod_hours) * 10) / 10,
    by = 0.1
  )
  curve <- h07_sensitivity_curve(checkpoint$fit, frame, grid) |>
    left_join(h07_sensitivity_support(frame, grid), by = "photoperiod_hours")
  metric <- h07_stage2_metric_contract |>
    filter(.data$metric_id == sample$metric_id[[1L]])
  sensitivity_curve_points <- bind_rows(
    sensitivity_curve_points,
    curve |>
      mutate(
        run_id = sample$run_id[[1L]],
        sensitivity = run$sensitivity[[1L]],
        data_scenario = run$data_scenario[[1L]],
        placement = run$placement[[1L]],
        metric_id = sample$metric_id[[1L]],
        metric_order = metric$metric_order[[1L]],
        manuscript_name = metric$manuscript_name[[1L]],
        .before = 1L
      )
  )
  message(sprintf(
    "H07 SENSITIVITY CURVE DONE %s / %s",
    sample$run_id,
    sample$metric_id
  ))
  rm(frame, checkpoint, curve)
  invisible(gc())
}

main_curve_points <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_main_curve_points.csv"),
  show_col_types = FALSE
) |>
  mutate(photoperiod_hours = round(.data$photoperiod_hours, 1))
all_curve_points <- bind_rows(
  main_curve_points |>
    transmute(
      run_id,
      sensitivity = "primary_all_available",
      data_scenario = "primary",
      placement,
      metric_id,
      metric_order,
      manuscript_name,
      photoperiod_hours,
      response_estimate,
      response_lower_pointwise,
      response_upper_pointwise,
      support_sites = sites,
      support_participants = participants,
      support_participant_days = participant_days,
      support_max_site_share = max_site_share,
      pooled_eligible,
      loso_eligible
    ),
  sensitivity_curve_points
)

base_comparisons <- tidyr::crossing(
  placement = c("near_eye", "chest"),
  metric_id = h07_stage2_metric_ids
)
comparison_registry <- bind_rows(
  base_comparisons |>
    transmute(
      comparison_id = paste0("paired_sample__", .data$placement),
      comparison_role = "placement_sample_restriction",
      placement = .data$placement,
      metric_id = .data$metric_id,
      run_a = paste("primary", .data$placement, sep = "__"),
      run_b = paste("paired", .data$placement, sep = "__")
    ),
  base_comparisons |>
    transmute(
      comparison_id = paste0("gap_total__", .data$placement),
      comparison_role = "preparation_total_difference",
      placement = .data$placement,
      metric_id = .data$metric_id,
      run_a = paste("primary", .data$placement, sep = "__"),
      run_b = paste("gap_timing_unaware", .data$placement, sep = "__")
    ),
  base_comparisons |>
    transmute(
      comparison_id = paste0("gap_value_common__", .data$placement),
      comparison_role = "preparation_value_on_exact_common_rows",
      placement = .data$placement,
      metric_id = .data$metric_id,
      run_a = paste("prep_common_primary", .data$placement, sep = "__"),
      run_b = paste("prep_common_gap", .data$placement, sep = "__")
    ),
  tibble::tibble(
    comparison_id = paste0("exact_period__", c("near_eye", "chest")),
    comparison_role = "longest_period_exact_only",
    placement = c("near_eye", "chest"),
    metric_id = "longest_bout_above_250",
    run_a = paste("primary", c("near_eye", "chest"), sep = "__"),
    run_b = paste("exact_period", c("near_eye", "chest"), sep = "__")
  ),
  tibble::tibble(
    comparison_id = paste0("observed_dose__", c("near_eye", "chest")),
    comparison_role = "observed_vs_corrected_dose_exact_common_rows",
    placement = c("near_eye", "chest"),
    metric_id = "dose_time_sensitive_corrected_medi",
    run_a = paste("dose_common_corrected", c("near_eye", "chest"), sep = "__"),
    run_b = paste("dose_common_observed", c("near_eye", "chest"), sep = "__")
  )
) |>
  left_join(
    h07_stage2_metric_contract |>
      select(
        "metric_id",
        "metric_order",
        "manuscript_name",
        "effect_scale",
        "display_unit"
      ),
    by = "metric_id"
  )

h07_compare_curves <- function(comparison) {
  curve_a <- all_curve_points |>
    filter(
      .data$run_id == comparison$run_a[[1L]],
      .data$metric_id == comparison$metric_id[[1L]]
    ) |>
    select(
      "photoperiod_hours",
      estimate_a = "response_estimate",
      pooled_a = "pooled_eligible"
    )
  curve_b <- all_curve_points |>
    filter(
      .data$run_id == comparison$run_b[[1L]],
      .data$metric_id == comparison$metric_id[[1L]]
    ) |>
    select(
      "photoperiod_hours",
      estimate_b = "response_estimate",
      pooled_b = "pooled_eligible"
    )
  common <- inner_join(curve_a, curve_b, by = "photoperiod_hours") |>
    filter(.data$pooled_a, .data$pooled_b) |>
    arrange(.data$photoperiod_hours) |>
    mutate(
      difference_b_minus_a = .data$estimate_b - .data$estimate_a,
      ratio_b_over_a = if_else(
        .data$estimate_a > 0 & .data$estimate_b > 0,
        .data$estimate_b / .data$estimate_a,
        NA_real_
      )
    )
  if (nrow(common) == 0L) {
    return(comparison |>
      mutate(
        common_supported_points = 0L,
        common_support_min = NA_real_,
        common_support_max = NA_real_,
        net_change_a = NA_real_,
        net_change_b = NA_real_,
        maximum_absolute_difference = NA_real_,
        median_absolute_difference = NA_real_,
        maximum_absolute_log_ratio = NA_real_,
        direction_agreement = NA,
        stability_classification = "NON_ESTIMABLE_NO_COMMON_POOLED_SUPPORT"
      ))
  }
  net_a <- common$estimate_a[[nrow(common)]] - common$estimate_a[[1L]]
  net_b <- common$estimate_b[[nrow(common)]] - common$estimate_b[[1L]]
  direction_agreement <- sign(net_a) == sign(net_b)
  comparison |>
    mutate(
      common_supported_points = nrow(common),
      common_support_min = min(common$photoperiod_hours),
      common_support_max = max(common$photoperiod_hours),
      net_change_a = net_a,
      net_change_b = net_b,
      maximum_absolute_difference = max(abs(common$difference_b_minus_a)),
      median_absolute_difference = stats::median(abs(common$difference_b_minus_a)),
      maximum_absolute_log_ratio = if (any(is.finite(common$ratio_b_over_a))) {
        max(abs(log(common$ratio_b_over_a)), na.rm = TRUE)
      } else {
        NA_real_
      },
      direction_agreement = direction_agreement,
      stability_classification = if_else(
        direction_agreement,
        "SAME_DIRECTION_MAGNITUDE_THRESHOLD_NOT_AVAILABLE",
        "DIRECTION_SENSITIVE"
      )
    )
}

sensitivity_comparison_summary <- purrr::map_dfr(
  seq_len(nrow(comparison_registry)),
  ~ h07_compare_curves(comparison_registry[.x, , drop = FALSE])
) |>
  mutate(
    inferential_stability =
      "NON_ESTIMABLE_ALL_RELEVANT_SMOOTHS_WARN_CONCURVITY"
  ) |>
  arrange(.data$comparison_role, .data$placement, .data$metric_order)

readr::write_csv(
  sensitivity_curve_points,
  file.path(h07_stage2_paths$tables, "H07_sensitivity_curve_points.csv"),
  na = ""
)
readr::write_csv(
  comparison_registry,
  file.path(h07_stage2_paths$tables, "H07_sensitivity_comparison_registry.csv"),
  na = ""
)
readr::write_csv(
  sensitivity_comparison_summary,
  file.path(h07_stage2_paths$tables, "H07_sensitivity_comparison_summary.csv"),
  na = ""
)

loso_registry <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_loso_run_registry.csv"),
  show_col_types = FALSE
)
loso_diagnostics <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_loso_diagnostics.csv"),
  show_col_types = FALSE
)
loso_curve_points <- tibble::tibble()

for (row_index in seq_len(nrow(loso_registry))) {
  run <- loso_registry[row_index, , drop = FALSE]
  frame <- readRDS(file.path(
    h07_stage2_paths$models,
    "frames",
    run$run_id,
    paste0(run$metric_id, ".rds")
  ))
  checkpoint <- readRDS(file.path(
    h07_stage2_paths$models,
    "fits",
    run$run_id,
    run$metric_id,
    "adapted_photoperiod_smooth.rds"
  ))
  main <- main_curve_points |>
    filter(
      .data$placement == run$placement[[1L]],
      .data$metric_id == run$metric_id[[1L]]
    ) |>
    select(
      "photoperiod_hours",
      main_response_estimate = "response_estimate",
      main_pooled_eligible = "pooled_eligible",
      main_loso_eligible = "loso_eligible"
    )
  curve <- h07_sensitivity_curve(
    checkpoint$fit,
    frame,
    main$photoperiod_hours
  ) |>
    left_join(main, by = "photoperiod_hours") |>
    mutate(
      within_omission_observed_range =
        .data$photoperiod_hours >= min(frame$photoperiod_hours) &
        .data$photoperiod_hours <= max(frame$photoperiod_hours),
      difference_from_main =
        .data$response_estimate - .data$main_response_estimate,
      ratio_to_main = if_else(
        .data$response_estimate > 0 & .data$main_response_estimate > 0,
        .data$response_estimate / .data$main_response_estimate,
        NA_real_
      ),
      run_id = run$run_id[[1L]],
      placement = run$placement[[1L]],
      metric_id = run$metric_id[[1L]],
      omitted_site = run$omitted_site[[1L]],
      .before = 1L
    )
  loso_curve_points <- bind_rows(loso_curve_points, curve)
  message(sprintf(
    "H07 LOSO CURVE DONE %s / %s / omit %s",
    run$placement,
    run$metric_id,
    run$omitted_site
  ))
  rm(frame, checkpoint, curve, main)
  invisible(gc())
}

loso_influence_summary <- loso_curve_points |>
  filter(
    .data$main_pooled_eligible,
    .data$within_omission_observed_range
  ) |>
  group_by(.data$placement, .data$metric_id, .data$omitted_site, .data$run_id) |>
  arrange(.data$photoperiod_hours, .by_group = TRUE) |>
  summarise(
    evaluated_grid_points = n(),
    evaluated_grid_min = min(.data$photoperiod_hours),
    evaluated_grid_max = max(.data$photoperiod_hours),
    maximum_absolute_difference = max(abs(.data$difference_from_main)),
    median_absolute_difference = stats::median(abs(.data$difference_from_main)),
    maximum_absolute_log_ratio = if (any(is.finite(.data$ratio_to_main))) {
      max(abs(log(.data$ratio_to_main)), na.rm = TRUE)
    } else {
      NA_real_
    },
    net_change_loso =
      .data$response_estimate[[n()]] - .data$response_estimate[[1L]],
    net_change_main =
      .data$main_response_estimate[[n()]] -
        .data$main_response_estimate[[1L]],
    direction_agreement = sign(.data$net_change_loso) == sign(.data$net_change_main),
    any_full_loso_supported_point = any(.data$main_loso_eligible),
    .groups = "drop"
  ) |>
  left_join(
    loso_diagnostics |>
      select(
        "run_id",
        "metric_id",
        "omitted_site",
        "fit_status",
        "concurvity_estimate",
        "smooth_edf",
        "k_index",
        "k_p_value",
        "pooled_consecutive_day_lag1"
      ),
    by = c("run_id", "metric_id", "omitted_site")
  ) |>
  left_join(
    h07_stage2_metric_contract |>
      select(
        "metric_id",
        "metric_order",
        "manuscript_name",
        "effect_scale",
        "display_unit"
      ),
    by = "metric_id"
  ) |>
  mutate(
    influence_disposition = case_when(
      .data$fit_status %in% c("FAIL_FIT", "FAIL_CONVERGENCE", "FAIL_HESSIAN") ~
        "FAILED_OMISSION_FIT",
      !.data$direction_agreement ~ "DIRECTION_SENSITIVE",
      !.data$any_full_loso_supported_point ~
        "NUMERIC_INFLUENCE_ONLY_SUPPORT_COLLAPSES_UNDER_FULL_LOSO_RULE",
      TRUE ~ "SAME_DIRECTION_MAGNITUDE_THRESHOLD_NOT_AVAILABLE"
    )
  ) |>
  arrange(.data$placement, .data$metric_order, .data$omitted_site)

loso_no_pooled_support <- loso_registry |>
  select("placement", "metric_id", "omitted_site", "run_id") |>
  anti_join(
    loso_influence_summary |>
      select("placement", "metric_id", "omitted_site", "run_id"),
    by = c("placement", "metric_id", "omitted_site", "run_id")
  ) |>
  left_join(
    loso_diagnostics |>
      select(
        "run_id",
        "metric_id",
        "omitted_site",
        "fit_status",
        "concurvity_estimate",
        "smooth_edf",
        "k_index",
        "k_p_value",
        "pooled_consecutive_day_lag1"
      ),
    by = c("run_id", "metric_id", "omitted_site")
  ) |>
  left_join(
    h07_stage2_metric_contract |>
      select(
        "metric_id",
        "metric_order",
        "manuscript_name",
        "effect_scale",
        "display_unit"
      ),
    by = "metric_id"
  ) |>
  mutate(
    evaluated_grid_points = 0L,
    evaluated_grid_min = NA_real_,
    evaluated_grid_max = NA_real_,
    maximum_absolute_difference = NA_real_,
    median_absolute_difference = NA_real_,
    maximum_absolute_log_ratio = NA_real_,
    net_change_loso = NA_real_,
    net_change_main = NA_real_,
    direction_agreement = NA,
    any_full_loso_supported_point = FALSE,
    influence_disposition =
      "NO_POOLED_SUPPORT_FOR_NUMERIC_CURVE_INFLUENCE"
  )

loso_influence_summary <- bind_rows(
  loso_influence_summary,
  loso_no_pooled_support
) |>
  arrange(.data$placement, .data$metric_order, .data$omitted_site)

loso_metric_summary <- loso_influence_summary |>
  group_by(
    .data$placement,
    .data$metric_id,
    .data$metric_order,
    .data$manuscript_name,
    .data$effect_scale,
    .data$display_unit
  ) |>
  summarise(
    omission_fits = n(),
    failed_omission_fits = sum(grepl("^FAIL", .data$fit_status)),
    direction_sensitive_omissions = sum(!.data$direction_agreement, na.rm = TRUE),
    largest_absolute_difference = if (
      any(is.finite(.data$maximum_absolute_difference))
    ) {
      max(.data$maximum_absolute_difference, na.rm = TRUE)
    } else {
      NA_real_
    },
    site_largest_absolute_difference = if (
      any(is.finite(.data$maximum_absolute_difference))
    ) {
      .data$omitted_site[[which.max(.data$maximum_absolute_difference)]]
    } else {
      NA_character_
    },
    largest_absolute_log_ratio = if (any(is.finite(.data$maximum_absolute_log_ratio))) {
      max(.data$maximum_absolute_log_ratio, na.rm = TRUE)
    } else {
      NA_real_
    },
    full_loso_support = any(.data$any_full_loso_supported_point),
    pooled_support_available_for_numeric_influence =
      any(.data$evaluated_grid_points > 0),
    inferential_disposition = if_else(
      .data$pooled_support_available_for_numeric_influence,
      "NON_ESTIMABLE_CONCURVITY_AND_NO_FULL_LOSO_SUPPORT",
      "NON_ESTIMABLE_NO_POOLED_SUPPORT_AND_CONCURVITY"
    ),
    .groups = "drop"
  ) |>
  arrange(.data$placement, .data$metric_order)

readr::write_csv(
  loso_curve_points,
  file.path(h07_stage2_paths$tables, "H07_loso_curve_points.csv"),
  na = ""
)
readr::write_csv(
  loso_influence_summary,
  file.path(h07_stage2_paths$tables, "H07_loso_influence_by_site.csv"),
  na = ""
)
readr::write_csv(
  loso_metric_summary,
  file.path(h07_stage2_paths$tables, "H07_loso_influence_summary.csv"),
  na = ""
)

near_eye_loso_plot <- loso_curve_points |>
  filter(
    .data$placement == "near_eye",
    .data$main_pooled_eligible,
    .data$within_omission_observed_range
  ) |>
  left_join(
    h07_stage2_metric_contract |>
      select("metric_id", "metric_order", "manuscript_name"),
    by = "metric_id"
  ) |>
  left_join(
    h07_stage2_site_display |>
      select("site", "display_name", "color_hex"),
    by = c("omitted_site" = "site")
  ) |>
  mutate(
    manuscript_name = factor(
      .data$manuscript_name,
      levels = h07_stage2_metric_contract$manuscript_name
    ),
    omitted_display = factor(
      .data$display_name,
      levels = h07_stage2_site_display$display_name
    )
  )

loso_plot <- ggplot(
  near_eye_loso_plot,
  aes(
    .data$photoperiod_hours,
    .data$response_estimate,
    group = .data$omitted_site,
    colour = .data$omitted_display
  )
) +
  geom_line(linewidth = 0.45, alpha = 0.75) +
  geom_line(
    aes(y = .data$main_response_estimate, group = 1L),
    colour = "#111827",
    linewidth = 0.95
  ) +
  facet_wrap(
    vars(.data$manuscript_name),
    scales = "free_y",
    ncol = 3,
    labeller = label_wrap_gen(27)
  ) +
  scale_colour_manual(
    values = setNames(
      h07_stage2_site_display$color_hex,
      h07_stage2_site_display$display_name
    ),
    drop = FALSE
  ) +
  scale_x_continuous(breaks = scales::breaks_pretty(n = 3)) +
  labs(
    x = "Civil photoperiod (h)",
    y = "Estimated metric value",
    colour = "Site omitted",
    title = "Near-eye leave-one-site-out influence",
    subtitle = paste(
      "Black: full adapted curve; coloured: one-site-omitted curves.",
      "Display is descriptive because the full LOSO support rule fails."
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 9),
    legend.position = "bottom",
    legend.text = element_text(size = 8),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, margin = margin(b = 10)),
    plot.title.position = "plot",
    plot.margin = margin(10, 10, 10, 10)
  ) +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE))

ggplot2::ggsave(
  file.path(h07_stage2_paths$figures, "H07_loso_influence_near_eye.png"),
  loso_plot,
  width = 13,
  height = 10.5,
  units = "in",
  dpi = 180,
  bg = "white"
)

message("H07 Stage 2 sensitivity and leave-one-site-out summaries complete")
