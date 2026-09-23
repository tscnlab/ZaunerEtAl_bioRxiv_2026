write_reader_csv <- function(data, path, role) {
  write_csv_artifact(data, path, producer)
  invisible(path)
}

h04_hour_level_reader_diagnostics <- function(
  data,
  fit,
  working_power,
  placement,
  residual,
  acf,
  bins = 24L
) {
  fitted_mean <- stats::fitted(fit)
  dispersion <- summary(fit)$dispersion
  if (is.null(dispersion) || !is.finite(dispersion)) {
    dispersion <- summary(fit)$scale
  }
  lambda <- fitted_mean^(2 - working_power) /
    (dispersion * (2 - working_power))
  rows <- data
  rows$fitted_mean_lx <- fitted_mean
  rows$pearson_residual <- residual
  rows$working_zero_probability <- exp(-lambda)
  points <- rows |>
    dplyr::group_by(.data$analysis_hour_id) |>
    dplyr::summarise(
      placement = .env$placement,
      participant = as.character(dplyr::first(.data$participant)),
      participant_day = as.character(dplyr::first(.data$participant_day)),
      site = as.character(dplyr::first(.data$site)),
      time_hour = dplyr::first(.data$time_hour),
      observed_mel_edi_lx = dplyr::first(.data$geo_medi_1h),
      fitted_mean_lx = stats::weighted.mean(
        .data$fitted_mean_lx,
        .data$analysis_weight
      ),
      pearson_residual = stats::weighted.mean(
        .data$pearson_residual,
        .data$analysis_weight
      ),
      working_zero_probability = stats::weighted.mean(
        .data$working_zero_probability,
        .data$analysis_weight
      ),
      observed_zero = dplyr::first(.data$geo_medi_1h) == 0,
      membership_rows = dplyr::n(),
      membership_weight_sum = sum(.data$analysis_weight),
      .groups = "drop"
    )
  if (any(abs(points$membership_weight_sum - 1) > 1e-8)) {
    h04_abort("H04 reader diagnostics found an hour whose weights do not sum to one")
  }
  residual_bins <- points |>
    dplyr::mutate(bin = dplyr::ntile(.data$fitted_mean_lx, bins)) |>
    dplyr::group_by(.data$placement, .data$bin) |>
    dplyr::summarise(
      unique_participant_hours = dplyr::n(),
      fitted_mean_lx = mean(.data$fitted_mean_lx),
      residual_mean = mean(.data$pearson_residual),
      residual_q25 = stats::quantile(
        .data$pearson_residual,
        0.25,
        names = FALSE
      ),
      residual_q75 = stats::quantile(
        .data$pearson_residual,
        0.75,
        names = FALSE
      ),
      .groups = "drop"
    )
  zero_bins <- points |>
    dplyr::mutate(bin = dplyr::ntile(.data$fitted_mean_lx, 10L)) |>
    dplyr::group_by(.data$placement, .data$bin) |>
    dplyr::summarise(
      unique_participant_hours = dplyr::n(),
      fitted_mean_lx = mean(.data$fitted_mean_lx),
      observed_zero_fraction = mean(.data$observed_zero),
      working_zero_fraction = mean(.data$working_zero_probability),
      .groups = "drop"
    )
  overall <- points |>
    dplyr::summarise(
      placement = .env$placement,
      unique_participant_hours = dplyr::n(),
      observed_zero_fraction = mean(.data$observed_zero),
      working_zero_fraction = mean(.data$working_zero_probability),
      difference_observed_minus_working =
        .data$observed_zero_fraction - .data$working_zero_fraction,
      diagnostic_unit = paste(
        "one original participant-hour; concurrent memberships combined",
        "with selected 1/k weights"
      )
    )
  list(
    points = points,
    residual_bins = residual_bins,
    zero_bins = zero_bins,
    overall = overall,
    acf = acf
  )
}

h04_heterogeneity_category_reader <- function(
  bundle,
  architecture,
  placement
) {
  prediction <- h04_interaction_prediction(bundle, architecture)
  grid <- prediction$grid
  design <- prediction$design
  variable <- prediction$activity_variable
  beta <- stats::coef(bundle$fit)
  covariance <- bundle$covariance
  df <- nlevels(bundle$data$participant) - 1L
  activities <- levels(bundle$data[[variable]])
  activity_value <- as.character(grid[[variable]])
  home <- "At home"
  x_home <- colMeans(design[activity_value == home, , drop = FALSE])
  eta_home <- drop(x_home %*% beta)
  mu_home <- exp(eta_home)
  support <- bundle$data |>
    dplyr::group_by(activity = as.character(.data[[variable]])) |>
    dplyr::summarise(
      unique_participant_hours = dplyr::n_distinct(.data$analysis_hour_id),
      long_rows = dplyr::n(),
      effective_weighted_hours = sum(.data$analysis_weight),
      participants = dplyr::n_distinct(.data$participant),
      participant_days = dplyr::n_distinct(.data$participant_day),
      sites = dplyr::n_distinct(.data$site),
      .groups = "drop"
    )
  result <- dplyr::bind_rows(lapply(activities, function(activity) {
    x_bar <- colMeans(design[activity_value == activity, , drop = FALSE])
    eta <- drop(x_bar %*% beta)
    mean_result <- h04_link_delta(
      eta,
      x_bar,
      covariance,
      df,
      null_log = NA_real_
    )
    if (identical(activity, home)) {
      ratio_result <- list(
        estimate = 1,
        conf_low = 1,
        conf_high = 1,
        standard_error = 0,
        statistic = NA_real_,
        p_raw = NA_real_,
        status = "REFERENCE"
      )
      difference_result <- list(
        estimate = 0,
        conf_low = 0,
        conf_high = 0,
        status = "REFERENCE"
      )
    } else {
      ratio_result <- h04_link_delta(
        eta - eta_home,
        x_bar - x_home,
        covariance,
        df
      )
      mu <- exp(eta)
      difference_result <- h04_difference_delta(
        mu - mu_home,
        mu * x_bar - mu_home * x_home,
        covariance,
        df
      )
    }
    tibble::tibble(
      placement = placement,
      architecture = architecture,
      activity = activity,
      standardized_mean_lx = mean_result$estimate,
      mean_conf_low_lx = mean_result$conf_low,
      mean_conf_high_lx = mean_result$conf_high,
      ratio_to_home = ratio_result$estimate,
      ratio_conf_low = ratio_result$conf_low,
      ratio_conf_high = ratio_result$conf_high,
      ratio_statistic = ratio_result$statistic,
      ratio_denominator_df = df,
      ratio_p_raw = ratio_result$p_raw,
      ratio_status = ratio_result$status,
      difference_from_home_lx = difference_result$estimate,
      difference_conf_low_lx = difference_result$conf_low,
      difference_conf_high_lx = difference_result$conf_high,
      difference_status = difference_result$status,
      inferential_role = ifelse(
        identical(activity, home),
        "REFERENCE",
        "NAMED_VERSUS_HOME"
      ),
      model_source = "site_heterogeneity",
      sites_standardized = length(unique(as.character(grid$site))),
      estimand = paste(
        "equal-site standardized category mean from the selected",
        "site-by-activity heterogeneity model"
      )
    )
  })) |>
    dplyr::left_join(support, by = "activity", relationship = "one-to-one") |>
    dplyr::left_join(
      h04_activity_registry() |>
        dplyr::select(
          "activity_code",
          activity = "activity_label",
          "display_order"
        ),
      by = "activity",
      relationship = "many-to-one"
    ) |>
    dplyr::arrange(.data$display_order)
  eligible <- result$inferential_role == "NAMED_VERSUS_HOME"
  if (sum(eligible) != 4L || any(!is.finite(result$ratio_p_raw[eligible]))) {
    h04_abort("Invalid H04 heterogeneity category ratio p-values")
  }
  result$ratio_p_adjusted <- NA_real_
  result$ratio_p_adjusted[eligible] <- stats::p.adjust(
    result$ratio_p_raw[eligible],
    method = "BH",
    n = 4L
  )
  if (
    nrow(result) != length(activities) ||
      any(!is.finite(result$standardized_mean_lx))
  ) {
    h04_abort("Invalid H04 heterogeneity category reader estimates")
  }
  result
}

h04_additive_other_reader <- function(bundle, placement) {
  h04_equal_site_estimands(bundle) |>
    dplyr::filter(.data$activity_code == "other") |>
    dplyr::transmute(
      placement = .env$placement,
      architecture = "additive_display_only",
      .data$activity,
      .data$standardized_mean_lx,
      .data$mean_conf_low_lx,
      .data$mean_conf_high_lx,
      .data$ratio_to_home,
      .data$ratio_conf_low,
      .data$ratio_conf_high,
      ratio_statistic = NA_real_,
      ratio_denominator_df = NA_real_,
      ratio_p_raw = NA_real_,
      ratio_p_adjusted = NA_real_,
      ratio_status = "DISPLAY_ONLY",
      .data$difference_from_home_lx,
      .data$difference_conf_low_lx,
      .data$difference_conf_high_lx,
      difference_status = "DISPLAY_ONLY",
      inferential_role = "DISPLAY_ONLY",
      model_source = "additive_display_only",
      sites_standardized = .data$sites,
      estimand = paste(
        "equal-site standardized display-only category mean from the",
        "additive primary model; Other is excluded from heterogeneity"
      ),
      .data$unique_participant_hours,
      .data$long_rows,
      .data$effective_weighted_hours,
      .data$participants,
      .data$participant_days,
      .data$sites,
      .data$activity_code,
      .data$display_order
    )
}

h04_fit_descriptive_quasi <- function(formula, data, working_power) {
  warnings <- character()
  fit <- withCallingHandlers(
    stats::glm(
      formula = formula,
      data = data,
      family = statmod::tweedie(
        var.power = working_power,
        link.power = 0
      ),
      weights = analysis_weight,
      control = stats::glm.control(epsilon = 1e-10, maxit = 100L),
      model = TRUE,
      x = TRUE,
      y = TRUE
    ),
    warning = function(condition) {
      warnings <<- c(warnings, conditionMessage(condition))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = fit, warnings = unique(warnings))
}

h04_heterogeneity_r_squared <- function(
  bundle,
  architecture,
  placement
) {
  data <- bundle$data
  response <- data$geo_medi_1h
  activity_variable <- if (architecture == "five_named") {
    "activity_named"
  } else {
    "activity_core"
  }
  formulas <- list(
    intercept = stats::reformulate(character(), response = "geo_medi_1h"),
    site = stats::reformulate("site", response = "geo_medi_1h"),
    category = stats::reformulate(activity_variable, response = "geo_medi_1h"),
    additive = stats::reformulate(
      c("site", activity_variable),
      response = "geo_medi_1h"
    ),
    full = bundle$formula
  )
  fits <- lapply(formulas, function(formula) {
    h04_fit_descriptive_quasi(formula, data, bundle$working_power)
  })
  stored_fitted <- stats::fitted(bundle$fit)
  rebuilt_fitted <- stats::fitted(fits$full$fit)
  if (max(abs(stored_fitted - rebuilt_fitted)) > 1e-6) {
    h04_abort("Descriptive H04 full heterogeneity refit changed fitted means")
  }
  participant_hours <- data |>
    dplyr::distinct(.data$participant, .data$analysis_hour_id) |>
    dplyr::count(.data$participant, name = "participant_hours")
  participant_balanced_weight <- data |>
    dplyr::select(
      "participant",
      "analysis_weight"
    ) |>
    dplyr::left_join(
      participant_hours,
      by = "participant",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      weight = .data$analysis_weight / .data$participant_hours
    ) |>
    dplyr::pull(.data$weight)
  weight_sets <- list(
    participant_hour_weighted = data$analysis_weight,
    participant_balanced = participant_balanced_weight
  )
  build_row <- function(losses, loss_basis, weighting) {
    overall <- 1 - losses[["full"]] / losses[["intercept"]]
    site_shapley <- 0.5 * (
      (losses[["intercept"]] - losses[["site"]]) +
        (losses[["category"]] - losses[["additive"]])
    ) / losses[["intercept"]]
    category_shapley <- 0.5 * (
      (losses[["intercept"]] - losses[["category"]]) +
        (losses[["site"]] - losses[["additive"]])
    ) / losses[["intercept"]]
    interaction <- (
      losses[["additive"]] - losses[["full"]]
    ) / losses[["intercept"]]
    tibble::tibble(
      placement = placement,
      model_id = "quasi_tweedie_log",
      model_label = "Quasi-Tweedie, log link",
      heterogeneity_architecture = architecture,
      loss_basis = loss_basis,
      weighting = weighting,
      overall_r_squared = overall,
      category_shapley_r_squared = category_shapley,
      site_shapley_r_squared = site_shapley,
      interaction_r_squared = interaction,
      category_shapley_share_percent = 100 * category_shapley / overall,
      site_shapley_share_percent = 100 * site_shapley / overall,
      interaction_share_percent = 100 * interaction / overall,
      interaction_partial_r_squared_conditional_on_additive =
        1 - losses[["full"]] / losses[["additive"]],
      intercept_loss = losses[["intercept"]],
      site_only_loss = losses[["site"]],
      category_only_loss = losses[["category"]],
      additive_loss = losses[["additive"]],
      full_loss = losses[["full"]],
      concurrent_memberships_fractionally_weighted = TRUE,
      inferential_role = paste(
        "descriptive in-sample point estimate; no resampling interval;",
        "not an additional effect test"
      )
    )
  }
  rows <- list()
  for (weighting in names(weight_sets)) {
    weight <- weight_sets[[weighting]]
    weight <- weight / sum(weight)
    losses <- vapply(fits, function(item) {
      prediction <- stats::fitted(item$fit)
      sum(weight * (response - prediction)^2)
    }, numeric(1))
    rows[[weighting]] <- build_row(losses, "squared_error", weighting)
  }
  deviance_losses <- vapply(fits, function(item) item$fit$deviance, numeric(1))
  rows$model_deviance <- build_row(
    deviance_losses,
    "model_deviance",
    "model-defined fractional prior weights"
  )
  result <- dplyr::bind_rows(rows)
  if (
    any(!vapply(fits, function(item) item$fit$converged, logical(1))) ||
      any(!is.finite(result$overall_r_squared))
  ) {
    h04_abort("H04 descriptive heterogeneity R-squared assessment failed")
  }
  result
}

save_reader_figure <- function(plot, stem, width, height) {
  h04_save_plot(
    plot,
    stem,
    roots$figures,
    width,
    height,
    producer
  )

}
