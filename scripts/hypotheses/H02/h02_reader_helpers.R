read_h02_csv <- function(...) {
  readr::read_csv(file.path(root, ...), show_col_types = FALSE)
}

fmt_number <- function(x, digits = 2L) {
  formatC(x, digits = digits, format = "f", big.mark = ",")
}

fmt_ci <- function(estimate, lower, upper, digits = 2L) {
  paste0(
    fmt_number(estimate, digits),
    " (95% CI ",
    fmt_number(lower, digits),
    " to ",
    fmt_number(upper, digits),
    ")"
  )
}

fmt_percent_ci <- function(estimate, lower, upper, digits = 1L) {
  paste0(
    fmt_number(100 * estimate, digits),
    "% (95% CI ",
    fmt_number(100 * lower, digits),
    "% to ",
    fmt_number(100 * upper, digits),
    "%)"
  )
}

fmt_p_value <- function(value, significant = FALSE) {
  display <- nh_p_value_display(value, significant)
  ifelse(
    display$p_bold,
    paste0("**", display$p_display, "**"),
    display$p_display
  )
}

h02_gt <- function(table) {
  table |>
    gt::opt_row_striping() |>
    gt::sub_missing(missing_text = "Not available") |>
    gt::tab_options(
      table.width = gt::pct(100),
      table.font.size = gt::px(12),
      data_row.padding = gt::px(5),
      column_labels.font.weight = "600",
      source_notes.font.size = gt::px(10),
      container.overflow.x = "auto"
    )
}

sample_overall <- function(run_id) {
  sample_counts |>
    filter(.data$run_id == .env$run_id, .data$site == "ALL_SITES")
}

sample_by_site <- function(run_id) {
  sample_counts |>
    filter(.data$run_id == .env$run_id) |>
    left_join(site_registry, by = "site", relationship = "many-to-one") |>
    mutate(
      display_order = if_else(.data$site == "ALL_SITES", 0L, .data$display_order),
      display_site = if_else(
        .data$site == "ALL_SITES",
        "All sites",
        .data$display_name
      )
    ) |>
    arrange(.data$display_order) |>
    transmute(
      Site = .data$display_site,
      Participants = .data$participants,
      `Participant-days` = .data$participant_days,
      `30-minute observations` = .data$observations_30_minute,
      `Exact-zero observations` = .data$exact_zero_observations,
      `AR sequences` = .data$ar_sequences
    )
}

variation_table_data <- function(run_id) {
  labels <- c(
    site_curve_variation = "Site curves",
    participant_curve_variation = "Participant curves",
    participant_day_intercept_variation = "Participant-day shifts",
    participant_plus_day_variation = "Participant curves + day shifts",
    participant_to_site_ratio = "Participant / site",
    participant_plus_day_to_site_ratio =
      "(Participant + day) / site"
  )
  variation |>
    filter(.data$run_id == .env$run_id) |>
    mutate(
      Section = if_else(
        grepl("_ratio$", .data$summary_id),
        "Relative curve dispersion",
        "Integrated fitted-curve variation"
      ),
      Quantity = unname(labels[.data$summary_id]),
      digits = if_else(grepl("_ratio$", .data$summary_id), 2L, 3L),
      Estimate = mapply(
        fmt_number,
        .data$estimate,
        .data$digits,
        USE.NAMES = FALSE
      ),
      `95% CI` = mapply(
        fmt_ci,
        .data$estimate,
        .data$lower_95,
        .data$upper_95,
        .data$digits,
        USE.NAMES = FALSE
      )
    ) |>
    select(.data$Section, .data$Quantity, .data$Estimate, .data$`95% CI`)
}

dominance_table_data <- function(run_id) {
  labels <- c(
    common_time = "Global time effect",
    site_pattern = "Site pattern",
    participant_pattern = "Participant pattern",
    participant_day = "Participant-day shift"
  )
  dominance |>
    filter(.data$run_id == .env$run_id) |>
    mutate(
      Component = unname(labels[.data$component]),
      `Allocated R² (95% CI)` = fmt_ci(
        .data$allocated_R2,
        .data$allocated_R2_lower_95,
        .data$allocated_R2_upper_95,
        3
      ),
      `Share of full-model R² (95% CI)` = fmt_percent_ci(
        .data$share_of_full_model_R2,
        .data$share_of_full_model_R2_lower_95,
        .data$share_of_full_model_R2_upper_95,
        1
      )
    ) |>
    select(
      .data$Component,
      .data$`Allocated R² (95% CI)`,
      .data$`Share of full-model R² (95% CI)`
    )
}

dominance_comparison_data <- function(run_id) {
  labels <- c(
    participant_to_site_shapley_ratio =
      "Participant pattern / site pattern",
    participant_plus_day_to_site_shapley_ratio =
      "(Participant pattern + day shift) / site pattern",
    participant_plus_day_share_of_heterogeneity =
      "Participant pattern + day shift: share beyond global time effect"
  )
  dominance_comparison |>
    filter(
      .data$run_id == .env$run_id,
      .data$comparison_id %in% names(labels)
    ) |>
    mutate(
      Comparison = unname(labels[.data$comparison_id]),
      Result = if_else(
        grepl("share", .data$comparison_id),
        fmt_percent_ci(.data$estimate, .data$lower_95, .data$upper_95, 1),
        paste0(
          fmt_ci(.data$estimate, .data$lower_95, .data$upper_95, 2),
          " times"
        )
      )
    ) |>
    select(.data$Comparison, .data$Result)
}

window_table_data <- function(run_id) {
  fitted_sites <- sample_counts |>
    filter(.data$run_id == .env$run_id, .data$site != "ALL_SITES") |>
    distinct(.data$site) |>
    left_join(site_registry, by = "site", relationship = "many-to-one") |>
    arrange(.data$display_order)

  windows <- pointwise_windows |>
    filter(.data$run_id == .env$run_id) |>
    mutate(
      window = paste0(
        if_else(.data$direction == "higher", "Higher", "Lower"),
        " ",
        .data$start_local_clock,
        "–",
        .data$end_local_clock,
        " (",
        fmt_number(.data$minimum_point_ratio, 2),
        "–",
        fmt_number(.data$maximum_point_ratio, 2),
        "×)"
      )
    ) |>
    group_by(.data$site) |>
    summarise(
      `Pointwise windows (fitted factor range)` =
        paste(.data$window, collapse = "; "),
      .groups = "drop"
    )

  fitted_sites |>
    left_join(windows, by = "site", relationship = "one-to-one") |>
    transmute(
      Site = .data$display_name,
      `Pointwise windows (fitted factor range)` = coalesce(
        .data$`Pointwise windows (fitted factor range)`,
        "No 30-minute bin excluded 1"
      )
    )
}

diagnostic_table_data <- function(run_id) {
  fit <- model_fits |>
    filter(.data$run_id == .env$run_id) |>
    arrange(desc(.data$model_id == "site_pattern_final_fREML")) |>
    slice(1L)
  rsum <- residual_summary |>
    filter(.data$run_id == .env$run_id)
  acf_pre <- residual_acf |>
    filter(
      .data$run_id == .env$run_id,
      .data$stage == "preliminary_no_AR1",
      .data$lag_30_minute_bins == 1L
    )
  acf_post <- residual_acf |>
    filter(
      .data$run_id == .env$run_id,
      .data$stage == "final_AR1_standardized",
      .data$lag_30_minute_bins == 1L
    )
  day_acf <- cluster_acf |>
    filter(
      .data$run_id == .env$run_id,
      .data$cluster_level == "participant_day"
    )
  k_common <- k_checks |>
    filter(
      .data$run_id == .env$run_id,
      .data$smooth == "s(time_hour)"
    )
  k_participant <- k_checks |>
    filter(
      .data$run_id == .env$run_id,
      .data$smooth == "s(time_hour,participant)"
    )
  sz <- sz_checks |>
    filter(.data$run_id == .env$run_id)
  conc <- concurvity |>
    filter(
      .data$run_id == .env$run_id,
      .data$.type == "observed",
      .data$.term %in% c("s(time_hour)", "s(time_hour,site)")
    )
  conc_common <- conc$.concurvity[conc$.term == "s(time_hour)"]
  conc_site <- conc$.concurvity[conc$.term == "s(time_hour,site)"]
  r2 <- dominance |>
    filter(.data$run_id == .env$run_id) |>
    slice(1L)
  convergence_label <- if (
    isTRUE(as.logical(fit$convergence[[1L]]))
  ) {
    "Converged"
  } else {
    as.character(fit$convergence[[1L]])
  }

  tibble::tibble(
    Check = c(
      "Convergence and coefficient rank",
      "Full-model in-sample R²",
      "AR(1) correction",
      "Participant-day residual dependence",
      "Residual spread",
      "Basis-dimension checks",
      "Sum-to-zero site constraint",
      "Nonlinear-term overlap (concurvity)"
    ),
    Result = c(
      paste0(
        convergence_label,
        "; rank ",
        format(fit$rank, big.mark = ","),
        "/",
        format(fit$coefficients, big.mark = ",")
      ),
      fmt_ci(
        r2$full_model_R2,
        r2$full_model_R2_lower_95,
        r2$full_model_R2_upper_95,
        3
      ),
      paste0(
        "ρ = ",
        fmt_number(fit$rho, 3),
        "; lag-1 ",
        fmt_number(acf_pre$correlation, 3),
        " → ",
        fmt_number(acf_post$correlation, 3)
      ),
      paste0(
        "median lag-1 ",
        fmt_number(day_acf$median_lag1_correlation, 3),
        "; 95th percentile ",
        fmt_number(day_acf$q95_lag1_correlation, 3)
      ),
      paste0(
        "RMSE ",
        fmt_number(rsum$rmse, 3),
        "; cor(|residual|, fitted) ",
        fmt_number(rsum$correlation_absolute_residual_fitted, 3),
        "; max |residual| ",
        fmt_number(rsum$maximum_absolute_residual, 2)
      ),
      paste0(
        "common k-index ",
        fmt_number(k_common$k_index, 3),
        " (check p = ",
        nh_format_p_value(k_common$p_value),
        "); participant ",
        fmt_number(k_participant$k_index, 3),
        " (check p = ",
        nh_format_p_value(k_participant$p_value),
        ")"
      ),
      paste0(
        "verified; max |sum| = ",
        formatC(
          sz$maximum_absolute_sum_site_deviation_eta,
          format = "e",
          digits = 2
        )
      ),
      paste0(
        "common/site = ",
        fmt_number(conc_common, 3),
        "/",
        fmt_number(conc_site, 3)
      )
    ),
    Reading = c(
      "Numerical fit completed at full coefficient rank.",
      "Describes fit to these observations; it is not cross-validated performance.",
      "Most average 30-minute residual dependence was removed.",
      "Some days retain appreciable positive autocorrelation.",
      "Residual spread changes with fitted exposure and tails remain.",
      "No evidence that the available temporal basis was too small.",
      "Site curves are identifiable deviations around the global time effect.",
      "The global and site bases overlap strongly; interpret complete curves and contrasts, not isolated coefficients."
    )
  )
}

ratio_row <- function(run_id, summary_id) {
  variation |>
    filter(
      .data$run_id == .env$run_id,
      .data$summary_id == .env$summary_id
    )
}

make_sensitivity_row <- function(
  scenario,
  participants,
  participant_days,
  observations,
  participant_estimate,
  participant_lower,
  participant_upper,
  combined_estimate,
  combined_lower,
  combined_upper,
  interpretation
) {
  tibble::tibble(
    Scenario = scenario,
    `Fitted sample` = paste0(
      format(participants, big.mark = ","),
      " participants; ",
      format(participant_days, big.mark = ","),
      " days; ",
      format(observations, big.mark = ","),
      " observations"
    ),
    `Participant / site` = fmt_ci(
      participant_estimate,
      participant_lower,
      participant_upper,
      2
    ),
    `(Participant + day) / site` = fmt_ci(
      combined_estimate,
      combined_lower,
      combined_upper,
      2
    ),
    Interpretation = interpretation
  )
}

extract_ratio <- function(run_id, summary_id) {
  ratio_row(run_id, summary_id) |>
    select(.data$estimate, .data$lower_95, .data$upper_95)
}
