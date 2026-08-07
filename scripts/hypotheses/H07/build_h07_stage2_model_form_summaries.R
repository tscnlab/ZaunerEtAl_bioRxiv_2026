source("scripts/hypotheses/H07/h07_stage2_core.R")

h07_model_form_inverse <- function(eta, spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    exp(eta)
  } else if (identical(spec$response_transform[[1L]], "log10_offset_0.1")) {
    10^eta - 0.1
  } else {
    eta
  }
}

h07_model_form_curve <- function(fit, frame, grid, model_id) {
  spec <- attr(frame, "h07_spec")
  labels <- vapply(fit$smooth, function(smooth) smooth$label, character(1))
  participant_label <- intersect(labels, "s(site_participant)")
  if (model_id == "adapted_photoperiod_fixed_site") {
    sites <- levels(frame$site)
    site_curves <- purrr::map_dfr(sites, function(site_value) {
      newdata <- frame[rep(1L, length(grid)), , drop = FALSE]
      newdata$photoperiod_hours <- grid
      newdata$site <- factor(site_value, levels = levels(frame$site))
      prediction <- stats::predict(
        fit,
        newdata = newdata,
        type = "link",
        exclude = participant_label
      )
      tibble::tibble(
        site = site_value,
        photoperiod_hours = round(grid, 1),
        site_response = h07_model_form_inverse(
          as.numeric(prediction),
          spec
        )
      )
    })
    return(site_curves |>
      group_by(.data$photoperiod_hours) |>
      summarise(
        response_estimate = mean(.data$site_response),
        site_response_min = min(.data$site_response),
        site_response_max = max(.data$site_response),
        .groups = "drop"
      ) |>
      mutate(
        prediction_mode = "equal_site_response_average_fixed_site",
        pointwise_interval_available = FALSE
      ))
  }
  excluded <- intersect(labels, c("s(site)", "s(site_participant)"))
  newdata <- frame[rep(1L, length(grid)), , drop = FALSE]
  newdata$photoperiod_hours <- grid
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
    response_estimate = h07_model_form_inverse(estimate, spec),
    site_response_min = NA_real_,
    site_response_max = NA_real_,
    response_lower_pointwise = h07_model_form_inverse(
      estimate - stats::qnorm(0.975) * se,
      spec
    ),
    response_upper_pointwise = h07_model_form_inverse(
      estimate + stats::qnorm(0.975) * se,
      spec
    ),
    prediction_mode = "zero_random_effect_population_curve",
    pointwise_interval_available = TRUE
  )
}

main_curves <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_main_curve_points.csv"),
  show_col_types = FALSE
) |>
  mutate(photoperiod_hours = round(.data$photoperiod_hours, 1))
main_diagnostics <- readr::read_csv(
  file.path(h07_stage2_paths$tables, "H07_main_diagnostics.csv"),
  show_col_types = FALSE
)

registry <- tidyr::crossing(
  placement = c("near_eye", "chest"),
  metric_id = h07_stage2_metric_ids,
  model_id = c(
    "adapted_photoperiod_expanded_basis",
    "adapted_photoperiod_fixed_site"
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
  ) |>
  mutate(run_id = paste("primary", .data$placement, sep = "__")) |>
  arrange(
    factor(.data$placement, levels = c("near_eye", "chest")),
    .data$metric_order,
    .data$model_id
  )

curve_points <- tibble::tibble()
comparison_summary <- tibble::tibble()

for (row_index in seq_len(nrow(registry))) {
  run <- registry[row_index, , drop = FALSE]
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
    paste0(run$model_id, ".rds")
  ))
  main <- main_curves |>
    filter(
      .data$run_id == run$run_id[[1L]],
      .data$metric_id == run$metric_id[[1L]]
    ) |>
    arrange(.data$photoperiod_hours)
  alternative <- h07_model_form_curve(
    checkpoint$fit,
    frame,
    main$photoperiod_hours,
    run$model_id[[1L]]
  ) |>
    left_join(
      main |>
        select(
          "photoperiod_hours",
          main_response_estimate = "response_estimate",
          pooled_eligible,
          loso_eligible
        ),
      by = "photoperiod_hours"
    ) |>
    mutate(
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
      metric_order = run$metric_order[[1L]],
      manuscript_name = run$manuscript_name[[1L]],
      model_id = run$model_id[[1L]],
      .before = 1L
    )
  status <- main_diagnostics |>
    filter(
      .data$run_id == run$run_id[[1L]],
      .data$metric_id == run$metric_id[[1L]],
      .data$model_id == run$model_id[[1L]]
    )
  evaluated <- alternative |>
    filter(.data$pooled_eligible)
  comparison_summary <- bind_rows(
    comparison_summary,
    run |>
      transmute(
        run_id,
        placement,
        metric_id,
        metric_order,
        manuscript_name,
        effect_scale,
        display_unit,
        model_id,
        fit_status = status$fit_status[[1L]],
        evaluated_grid_points = nrow(evaluated),
        maximum_absolute_difference = if (nrow(evaluated)) {
          max(abs(evaluated$difference_from_main))
        } else {
          NA_real_
        },
        maximum_absolute_log_ratio = if (
          nrow(evaluated) && any(is.finite(evaluated$ratio_to_main))
        ) {
          max(abs(log(evaluated$ratio_to_main)), na.rm = TRUE)
        } else {
          NA_real_
        },
        main_net_change = if (nrow(evaluated)) {
          evaluated$main_response_estimate[[nrow(evaluated)]] -
            evaluated$main_response_estimate[[1L]]
        } else {
          NA_real_
        },
        alternative_net_change = if (nrow(evaluated)) {
          evaluated$response_estimate[[nrow(evaluated)]] -
            evaluated$response_estimate[[1L]]
        } else {
          NA_real_
        },
        direction_agreement = if (nrow(evaluated)) {
          sign(.data$main_net_change) == sign(.data$alternative_net_change)
        } else {
          NA
        },
        comparison_disposition = case_when(
          grepl("^FAIL", .data$fit_status) ~ "ALTERNATIVE_FIT_FAILED",
          .data$evaluated_grid_points == 0L ~ "NO_POOLED_SUPPORT_FOR_CURVE_COMPARISON",
          !.data$direction_agreement ~ "DIRECTION_SENSITIVE",
          TRUE ~ "SAME_DIRECTION_MAGNITUDE_THRESHOLD_NOT_AVAILABLE"
        )
      )
  )
  curve_points <- bind_rows(curve_points, alternative)
  message(sprintf(
    "H07 MODEL FORM DONE %s / %s / %s",
    run$placement,
    run$metric_id,
    run$model_id
  ))
  rm(frame, checkpoint, main, alternative)
  invisible(gc())
}

readr::write_csv(
  curve_points,
  file.path(h07_stage2_paths$tables, "H07_model_form_curve_points.csv"),
  na = ""
)
readr::write_csv(
  comparison_summary,
  file.path(h07_stage2_paths$tables, "H07_model_form_comparison_summary.csv"),
  na = ""
)

message("H07 Stage 2 basis and fixed-site curve summaries complete")
