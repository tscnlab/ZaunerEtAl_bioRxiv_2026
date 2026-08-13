#!/usr/bin/env Rscript

# No-refit finalization after the coordinator's separation disposition.

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
  "digest", "dplyr", "ggplot2", "glmmTMB", "lme4", "readr", "svglite",
  "tibble", "tidyr"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)
source(file.path(root, "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_contract.R"))
roots <- h06d_l10_artifact_roots(root)

effects_path <- file.path(roots$tables, "H06_daily_l10_metric011_effect_estimates.csv")
diagnostics_path <- file.path(
  roots$diagnostics,
  "H06_daily_l10_metric011_model_diagnostics.csv"
)
sensitivity_path <- file.path(
  roots$diagnostics,
  "H06_daily_l10_metric011_positive_family_sensitivity.csv"
)
primary_verdict_path <- file.path(
  roots$diagnostics,
  "H06_daily_l10_metric011_primary_verdict.csv"
)
model_path <- file.path(
  roots$models,
  "H06_daily_l10_metric011_production_models.rds"
)

effects <- readr::read_csv(effects_path, show_col_types = FALSE)
diagnostics <- readr::read_csv(diagnostics_path, show_col_types = FALSE)
sensitivity <- readr::read_csv(sensitivity_path, show_col_types = FALSE)
ar_summary <- readr::read_csv(
  file.path(roots$diagnostics, "H06_daily_l10_metric011_ar_counterparts.csv"),
  show_col_types = FALSE
)

classify_positive <- function(old_status, shift, reversal) {
  dplyr::case_when(
    grepl("T_SENSITIVITY_FAILED|T_NUMERICAL_FAILURE", old_status) ~
      "SENSITIVITY_UNRESOLVED_T_NUMERICAL_FAILURE_NO_STANDALONE_CLAIM",
    shift > 2 ~ "NOT_ACCEPTABLE_FAMILY_SENSITIVITY",
    reversal | shift >= 1 ~ paste0(
      "ACCEPTABLE_ONLY_WITH_MAJOR_FAMILY_SENSITIVITY_LIMITATION_",
      "NO_DIRECTIONAL_CLAIM"
    ),
    shift >= 0.5 ~ paste0(
      "ACCEPTABLE_ONLY_WITH_FAMILY_SENSITIVITY_LIMITATION_",
      "NO_CONFIRMATORY_CLAIM"
    ),
    TRUE ~ "ACCEPTABLE_FOR_DESCRIPTIVE_POSITIVE_COMPONENT_NO_CONFIRMATORY_CLAIM"
  )
}

sensitivity <- sensitivity |>
  dplyr::mutate(
    preliminary_status = .data$positive_family_status,
    positive_family_status = classify_positive(
      .data$preliminary_status,
      .data$student_t_effect_shift_in_gaussian_se,
      .data$student_t_direction_reversal
    ),
    coordinator_rule = paste0(
      "1–2 SE or direction reversal: major family-sensitivity limitation and ",
      "no directional/confirmatory claim; failed t fit: sensitivity unresolved"
    )
  )
readr::write_csv(sensitivity, sensitivity_path)

status_lookup <- sensitivity |>
  dplyr::select("run_id", "predictor_id", "positive_family_status")
effects <- effects |>
  dplyr::left_join(
    status_lookup,
    by = c("run_id", "predictor_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    inferential_status = dplyr::if_else(
      .data$component == "positive_magnitude" &
        grepl("Gaussian identity on log10-positive|Student-t", .data$family),
      .data$positive_family_status,
      .data$inferential_status
    )
  ) |>
  dplyr::select(-"positive_family_status")
readr::write_csv(effects, effects_path)

diagnostics <- diagnostics |>
  dplyr::left_join(
    status_lookup,
    by = c("run_id", "predictor_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    component_disposition = dplyr::if_else(
      .data$component == "positive_magnitude",
      .data$positive_family_status,
      .data$component_disposition
    )
  ) |>
  dplyr::select(-"positive_family_status")
readr::write_csv(diagnostics, diagnostics_path)

primary_verdict <- diagnostics |>
  dplyr::filter(.data$run_id == "primary__near_eye__all_available") |>
  dplyr::select(
    "predictor_order", "predictor_id", "component", "participant_days",
    "participants", "sites", "component_disposition"
  ) |>
  dplyr::left_join(
    ar_summary |>
      dplyr::filter(.data$run_id == "primary__near_eye__all_available") |>
      dplyr::select(
        "predictor_order", "predictor_id", "component", "ar_trigger",
        "ar_fitted", "ar_rho", "effect_shift_in_primary_se",
        "ar_acceptable", "disposition"
      ) |>
      dplyr::rename(ar_disposition = "disposition"),
    by = c("predictor_order", "predictor_id", "component"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    claim_disposition = dplyr::case_when(
      .data$component == "zero_occurrence" ~
        "NO_OCCURRENCE_OR_JOINT_ASSOCIATION_CLAIM",
      grepl("MAJOR", .data$component_disposition) ~
        "DESCRIPTIVE_POSITIVE_ONLY_MAJOR_FAMILY_LIMITATION_NO_DIRECTIONAL_CLAIM",
      grepl("UNRESOLVED", .data$component_disposition) ~
        "DESCRIPTIVE_POSITIVE_ONLY_SENSITIVITY_UNRESOLVED",
      grepl("NOT_ACCEPTABLE", .data$component_disposition) ~
        "DESCRIPTIVE_POSITIVE_ONLY_NOT_ACCEPTABLE_FOR_CLAIM",
      TRUE ~ "DESCRIPTIVE_POSITIVE_ONLY_NO_CONFIRMATORY_CLAIM"
    )
  )
readr::write_csv(primary_verdict, primary_verdict_path)

# Seal a direct primary-versus-gap comparison for the positive component. It is
# descriptive and cannot replace the unavailable joint sensitivity slot.
gap_comparison <- effects |>
  dplyr::filter(
    .data$placement_id == "near_eye",
    .data$sample_role == "all_available",
    .data$family %in% c(
      "Gaussian identity on log10-positive L10",
      "Student-t identity on log10-positive L10 sensitivity"
    )
  ) |>
  dplyr::select(
    "dataset_id", "predictor_order", "predictor_id", "family",
    "link_estimate", "link_standard_error", "estimate", "lower_95",
    "upper_95", "inferential_status"
  ) |>
  tidyr::pivot_wider(
    names_from = "dataset_id",
    values_from = c(
      "link_estimate", "link_standard_error", "estimate", "lower_95",
      "upper_95", "inferential_status"
    ),
    names_sep = "__"
  ) |>
  dplyr::mutate(
    gap_minus_primary_link_shift =
      .data$link_estimate__gap_timing_unaware - .data$link_estimate__primary,
    absolute_gap_shift_in_primary_se = abs(.data$gap_minus_primary_link_shift) /
      .data$link_standard_error__primary,
    comparison_role = paste0(
      "positive-L10 descriptive dataset sensitivity only; joint two-part ",
      "sensitivity is non-estimable"
    )
  )
readr::write_csv(
  gap_comparison,
  file.path(roots$tables, "H06_daily_l10_metric011_gap_comparison.csv")
)

# Update only disposition strings in the task-owned model bundle. Verify every
# fitted model object is byte-identical in serialized-object space; no fit is
# rerun or reconstructed.
collect_fit_hashes <- function(object, path = "bundle") {
  if (inherits(object, c("merMod", "glmmTMB"))) {
    return(tibble::tibble(
      subobject_path = path,
      object_sha256 = h06d_l10_object_sha256(object)
    ))
  }
  if (!is.list(object)) {
    return(tibble::tibble())
  }
  names_object <- names(object)
  if (is.null(names_object)) names_object <- as.character(seq_along(object))
  dplyr::bind_rows(lapply(seq_along(object), function(index) {
    collect_fit_hashes(
      object[[index]],
      paste0(path, "$`,", names_object[[index]], "`")
    )
  }))
}

model_sha256_before <- h06d_l10_sha256(model_path)
bundle <- readRDS(model_path)
fit_hash_before <- collect_fit_hashes(bundle$models)
h06d_l10_assert(nrow(fit_hash_before) > 0L, "No fitted objects found in L10 bundle")
for (key in names(bundle$models)) {
  run_id <- sub("__(work_free_day|activity_status|previous_sleep_duration_centered_h)$", "", key)
  predictor_id <- sub("^.*__(work_free_day|activity_status|previous_sleep_duration_centered_h)$", "\\1", key)
  status <- sensitivity |>
    dplyr::filter(
      .data$run_id == .env$run_id,
      .data$predictor_id == .env$predictor_id
    ) |>
    dplyr::pull(.data$positive_family_status)
  h06d_l10_assert(length(status) == 1L, "Bundle status lookup failed")
  bundle$models[[key]]$positive_family_status <- status
}
fit_hash_after <- collect_fit_hashes(bundle$models)
h06d_l10_assert(
  identical(fit_hash_before, fit_hash_after),
  "A fitted L10 model changed during no-refit disposition finalization"
)
saveRDS(bundle, model_path, compress = "xz")
model_sha256_after <- h06d_l10_sha256(model_path)
fit_equivalence <- fit_hash_before |>
  dplyr::rename(object_sha256_before = "object_sha256") |>
  dplyr::left_join(
    fit_hash_after |>
      dplyr::rename(object_sha256_after = "object_sha256"),
    by = "subobject_path",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    object_identical = .data$object_sha256_before == .data$object_sha256_after,
    parent_bundle_sha256_before = model_sha256_before,
    parent_bundle_sha256_after = model_sha256_after,
    change_scope = "disposition strings only; no fit rerun"
  )
h06d_l10_assert(all(fit_equivalence$object_identical), "No-refit equivalence failed")
readr::write_csv(
  fit_equivalence,
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_no_refit_model_equivalence.csv"
  )
)

# Reader-facing positive-component figure. Ratios and intervals are pointwise;
# none is an overall L10 or confirmatory association result.
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
    lower_95 = .data$lower_95,
    upper_95 = .data$upper_95,
    interval_type = .data$interval_type,
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
    linewidth = 0.55
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
figure_stem <- file.path(
  roots$figures,
  "H06_daily_l10_metric011_positive_component_sensitivity"
)
ggplot2::ggsave(
  paste0(figure_stem, ".png"),
  plot,
  width = 7.4,
  height = 8.0,
  units = "in",
  dpi = 300,
  bg = "white"
)
ggplot2::ggsave(
  paste0(figure_stem, ".pdf"),
  plot,
  width = 7.4,
  height = 8.0,
  units = "in",
  device = grDevices::cairo_pdf,
  bg = "white"
)
ggplot2::ggsave(
  paste0(figure_stem, ".svg"),
  plot,
  width = 7.4,
  height = 8.0,
  units = "in",
  device = svglite::svglite,
  bg = "white"
)
alt_text <- tibble::tibble(
  figure_id = "fig-l10-positive-component-sensitivity",
  alt_text = paste0(
    "Forest plot of Gaussian and Student-t point estimates with pointwise 95% ",
    "intervals for the conditional geometric-mean L10 ratio among positive ",
    "participant-days. Six primary, paired-placement, chest, and gap-timing-",
    "unaware scenarios are shown for work/free day, activity status, and ",
    "previous-night sleep duration. The reference ratio is one. These ",
    "positive-only estimates do not represent the overall L10 association."
  )
)
readr::write_csv(
  alt_text,
  file.path(
    roots$source_data,
    "H06_daily_l10_metric011_figure_alt_text.csv"
  )
)
readr::write_csv(
  tibble::tibble(
    figure_id = "fig-l10-positive-component-sensitivity",
    width_inches = 7.4,
    height_inches = 8.0,
    dpi_png = 300L,
    panels = 3L,
    scenarios_per_panel = 6L,
    series_per_scenario = 2L,
    clipping_check = "PASS_COORDINATES_FINITE_AND_MARGINS_SET",
    interval_type = "pointwise, not simultaneous",
    disposition = "PENDING_VISUAL_INSPECTION_THEN_PASS"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_figure_readability_qa.csv"
  )
)

message(
  "METRIC-011 no-refit finalization complete; ",
  nrow(fit_equivalence),
  " fitted objects preserved exactly."
)
