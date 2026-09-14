#!/usr/bin/env Rscript

# Apply three exploratory nine-site multiplicity screens to the accepted H06
# contrasts and derive reference-profile predictions from the frozen model.
# This script never fits or refits a model.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_robust_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "H06 Stage 3 site-specific screening requires R 4.6.1; found %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

required_packages <- c(
  "cowplot", "dplyr", "ggplot2", "readr", "scales", "tibble"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

qa_status <- Sys.getenv("H06_FIGURE_QA_STATUS", unset = "NOT TESTED")
if (!qa_status %in% c("NOT TESTED", "PASS")) {
  stop("H06_FIGURE_QA_STATUS must be `NOT TESTED` or `PASS`", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H06/",
  "build_h06_stage3_site_specific_screening.R"
)
input_path <- file.path(
  root,
  "artifacts/09_tables/H06/H06_robust_site_specific_effects.csv"
)
model_path <- file.path(
  root,
  "artifacts/07_models/H06/H06_robust_core_models.rds"
)
table_path <- file.path(
  root,
  "artifacts/09_tables/H06/H06_stage3_site_specific_significance_screen.csv"
)
source_path <- file.path(
  root,
  paste0(
    "artifacts/11_source_data/H06/",
    "H06_stage3_site_specific_significance_screen_figure.csv"
  )
)
figure_root <- file.path(root, "artifacts/10_figures/H06")
figure_id <- "H06_stage3_site_specific_significance_screen"
manifest_root <- file.path(root, "artifacts/12_manifests/H06")
qa_root <- file.path(manifest_root, "qa")
qa_path <- file.path(
  manifest_root,
  "H06_stage3_site_specific_significance_figure_readability_qa.csv"
)
invisible(vapply(
  c(dirname(table_path), dirname(source_path), figure_root, qa_root),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

input_contract <- h06_input_contract(root)
input_hashes_match <- vapply(
  seq_len(nrow(input_contract)),
  function(index) {
    identical(
      artifact_sha256(input_contract$path[[index]]),
      input_contract$expected_sha256[[index]]
    )
  },
  logical(1)
)
if (any(!input_hashes_match)) {
  stop(
    "Frozen H06 Stage 3 input(s) changed: ",
    paste(input_contract$input_role[!input_hashes_match], collapse = ", "),
    call. = FALSE
  )
}

stage2_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H06/H06_stage2_artifacts.csv"),
  show_col_types = FALSE
)
input_relative <- c(
  "artifacts/09_tables/H06/H06_robust_site_specific_effects.csv",
  "artifacts/07_models/H06/H06_robust_core_models.rds"
)
input_manifest <- stage2_manifest[
  match(input_relative, stage2_manifest$path),
  ,
  drop = FALSE
]
if (
  anyNA(input_manifest$path) ||
    !all(file.exists(file.path(root, input_relative))) ||
    !identical(
      unname(vapply(
        file.path(root, input_relative),
        artifact_sha256,
        character(1)
      )),
      input_manifest$sha256
    )
) {
  stop("An accepted H06 site-screen input changed", call. = FALSE)
}

run_id <- "main__glasses__all_available"
planned_size <- 9L
alpha <- 0.05
effect_labels <- c(
  work_free_day = "Free day versus work day",
  activity_status = "Active versus sedentary",
  previous_sleep_duration_centered_h =
    "Previous sleep duration (per hour)"
)
effect_order <- unname(effect_labels)

site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order)

accepted <- readr::read_csv(
  input_path,
  show_col_types = FALSE,
  na = ""
) |>
  dplyr::filter(.data$run_id == .env$run_id) |>
  dplyr::arrange(
    match(.data$predictor_id, names(.env$effect_labels)),
    match(.data$site, .env$site_registry$site)
  )

recalculated_p <- 2 * stats::pt(
  abs(accepted$statistic),
  df = accepted$denominator_df,
  lower.tail = FALSE
)
if (
  nrow(accepted) != 27L ||
    any(table(accepted$predictor_id) != 9L) ||
    any(table(accepted$site) != 3L) ||
    anyDuplicated(accepted[c("predictor_id", "site")]) ||
    !all(accepted$status == "ESTIMABLE") ||
    !all(accepted$covariance_type == "HC3") ||
    !all(accepted$denominator_df == 136L) ||
    any(!is.finite(accepted$p_raw)) ||
    any(accepted$p_raw < 0 | accepted$p_raw > 1) ||
    !isTRUE(all.equal(accepted$p_raw, recalculated_p, tolerance = 1e-12)) ||
    any(accepted$estimate_ratio <= 0) ||
    any(accepted$conf_low_ratio <= 0) ||
    any(accepted$conf_high_ratio <= 0)
) {
  stop("The frozen H06 site-specific estimates failed validation", call. = FALSE)
}

model_archive <- readRDS(model_path)
if (
  !identical(model_archive$contract_version, "h06_002_robust_core_v1") ||
    !run_id %in% names(model_archive$runs) ||
    !identical(
      model_archive$frame_hashes[[run_id]],
      "ec9049b3a0c0f3b237c66a471ffdbaa1a86afe8e8e4983f6fd5deea97472950e"
    )
) {
  stop("The frozen H06 robust model archive failed validation", call. = FALSE)
}

bundle <- model_archive$runs[[run_id]]$full
formula_text <- gsub(
  "[[:space:]]+",
  " ",
  paste(deparse(bundle$formula), collapse = " ")
)
expected_formula <- gsub(
  "[[:space:]]+",
  " ",
  paste(deparse(h06_formula_set()$full), collapse = " ")
)
covariance <- bundle$covariance$HC3$value
coefficients <- stats::coef(bundle$fit)
degrees_freedom <- nlevels(bundle$data$participant_key) - 1L
if (
  !identical(formula_text, expected_formula) ||
    !isTRUE(bundle$fit$converged) ||
    bundle$fit$rank != length(coefficients) ||
    !is.matrix(covariance) ||
    any(!is.finite(covariance)) ||
    degrees_freedom != 136L
) {
  stop("The frozen H06 site-interaction fit failed validation", call. = FALSE)
}

sleep_by_day <- bundle$data |>
  dplyr::group_by(.data$participant_day_key) |>
  dplyr::summarise(
    sleep_values = dplyr::n_distinct(
      .data$previous_sleep_duration_centered_h
    ),
    sleep_centered_h = dplyr::first(
      .data$previous_sleep_duration_centered_h
    ),
    .groups = "drop"
  )
if (
  nrow(sleep_by_day) != 715L ||
    any(sleep_by_day$sleep_values != 1L)
) {
  stop("The fitted-sample sleep reference is inconsistent", call. = FALSE)
}
sleep_center_h <- 8
reference_sleep_centered_h <- mean(sleep_by_day$sleep_centered_h)
reference_sleep_h <- sleep_center_h + reference_sleep_centered_h

sites <- levels(bundle$data$site)
reference_data <- h06_prediction_defaults(bundle, sites)
reference_data$previous_sleep_duration_centered_h <-
  reference_sleep_centered_h
reference_matrix <- h06_model_matrix_newdata(bundle, reference_data)
reference_average_gradient <- colMeans(reference_matrix)

reference_site_tests <- dplyr::bind_rows(lapply(
  seq_along(sites),
  function(site_index) {
    site_gradient <- reference_matrix[site_index, ]
    deviation_gradient <- site_gradient - reference_average_gradient
    deviation <- h06_log_delta(
      drop(crossprod(deviation_gradient, coefficients)),
      deviation_gradient,
      covariance,
      degrees_freedom
    )
    tibble::tibble(
      site = sites[[site_index]],
      reference_vs_equal_site_ratio = deviation$estimate_ratio,
      reference_vs_equal_site_conf_low_ratio = deviation$conf_low_ratio,
      reference_vs_equal_site_conf_high_ratio = deviation$conf_high_ratio,
      reference_vs_equal_site_p_raw = deviation$p_raw
    )
  }
)) |>
  dplyr::mutate(
    reference_family_id = "reference_profile__nine_site_screen",
    reference_family_method = "Benjamini-Hochberg",
    reference_planned_size = .env$planned_size,
    reference_observed_size = dplyr::n(),
    reference_vs_equal_site_p_adjusted = stats::p.adjust(
      .data$reference_vs_equal_site_p_raw,
      method = "BH",
      n = .env$planned_size
    ),
    reference_vs_equal_site_adjusted_significant_0_05 =
      .data$reference_vs_equal_site_p_adjusted <= .env$alpha,
    reference_test_scope = paste(
      "Exploratory reference-profile contrast against the equal-site",
      "geometric mean; nine sites adjusted together"
    )
  )

if (
  nrow(reference_site_tests) != 9L ||
    any(!is.finite(reference_site_tests$reference_vs_equal_site_ratio)) ||
    any(!is.finite(reference_site_tests$reference_vs_equal_site_p_adjusted)) ||
    any(reference_site_tests$reference_vs_equal_site_p_adjusted <
      reference_site_tests$reference_vs_equal_site_p_raw)
) {
  stop("The reference-profile site screen failed validation", call. = FALSE)
}

scenario_registry <- tibble::tribble(
  ~predictor_id, ~comparison_label,
  "work_free_day", "Free day",
  "activity_status", "Active",
  "previous_sleep_duration_centered_h",
  sprintf("%.1f h previous sleep", reference_sleep_h + 1)
)

scenario_outputs <- lapply(
  seq_len(nrow(scenario_registry)),
  function(scenario_index) {
    predictor_id <- scenario_registry$predictor_id[[scenario_index]]
    comparison_label <- scenario_registry$comparison_label[[scenario_index]]
    comparison_data <- reference_data
    if (predictor_id == "work_free_day") {
      comparison_data[[predictor_id]] <- factor(
        "Free day",
        levels = levels(bundle$data[[predictor_id]])
      )
    } else if (predictor_id == "activity_status") {
      comparison_data[[predictor_id]] <- factor(
        levels(bundle$data[[predictor_id]])[[2L]],
        levels = levels(bundle$data[[predictor_id]])
      )
    } else {
      comparison_data[[predictor_id]] <-
        reference_sleep_centered_h + 1
    }
    comparison_matrix <- h06_model_matrix_newdata(bundle, comparison_data)

    site_context <- dplyr::bind_rows(lapply(
      seq_along(sites),
      function(site_index) {
        reference_gradient <- reference_matrix[site_index, ]
        comparison_gradient <- comparison_matrix[site_index, ]
        reference_prediction <- h06_log_delta(
          drop(crossprod(reference_gradient, coefficients)),
          reference_gradient,
          covariance,
          degrees_freedom,
          null_log = NA_real_
        )
        comparison_prediction <- h06_log_delta(
          drop(crossprod(comparison_gradient, coefficients)),
          comparison_gradient,
          covariance,
          degrees_freedom,
          null_log = NA_real_
        )
        contrast_gradient <- comparison_gradient - reference_gradient
        contrast <- h06_log_delta(
          drop(crossprod(contrast_gradient, coefficients)),
          contrast_gradient,
          covariance,
          degrees_freedom
        )
        tibble::tibble(
          predictor_id = predictor_id,
          comparison_label = comparison_label,
          site = sites[[site_index]],
          reference_sleep_duration_h = reference_sleep_h,
          reference_expected_melEDI_lx =
            reference_prediction$estimate_ratio,
          reference_conf_low_melEDI_lx =
            reference_prediction$conf_low_ratio,
          reference_conf_high_melEDI_lx =
            reference_prediction$conf_high_ratio,
          comparison_expected_melEDI_lx =
            comparison_prediction$estimate_ratio,
          comparison_conf_low_melEDI_lx =
            comparison_prediction$conf_low_ratio,
          comparison_conf_high_melEDI_lx =
            comparison_prediction$conf_high_ratio,
          derived_log_estimate = contrast$log_estimate,
          derived_log_standard_error = contrast$log_standard_error,
          derived_p_raw = contrast$p_raw
        )
      }
    ))

    reference_average_gradient <- colMeans(reference_matrix)
    comparison_average_gradient <- colMeans(comparison_matrix)
    equal_site_reference <- h06_log_delta(
      drop(crossprod(reference_average_gradient, coefficients)),
      reference_average_gradient,
      covariance,
      degrees_freedom,
      null_log = NA_real_
    )
    equal_site_comparison <- h06_log_delta(
      drop(crossprod(comparison_average_gradient, coefficients)),
      comparison_average_gradient,
      covariance,
      degrees_freedom,
      null_log = NA_real_
    )
    equal_site_gradient <-
      comparison_average_gradient - reference_average_gradient
    equal_site_contrast <- h06_log_delta(
      drop(crossprod(equal_site_gradient, coefficients)),
      equal_site_gradient,
      covariance,
      degrees_freedom
    )
    equal_site_context <- tibble::tibble(
      predictor_id = predictor_id,
      interaction_equal_site_ratio = equal_site_contrast$estimate_ratio,
      interaction_equal_site_conf_low_ratio =
        equal_site_contrast$conf_low_ratio,
      interaction_equal_site_conf_high_ratio =
        equal_site_contrast$conf_high_ratio,
      interaction_equal_site_p_raw = equal_site_contrast$p_raw,
      interaction_equal_site_reference_expected_melEDI_lx =
        equal_site_reference$estimate_ratio,
      interaction_equal_site_reference_conf_low_melEDI_lx =
        equal_site_reference$conf_low_ratio,
      interaction_equal_site_reference_conf_high_melEDI_lx =
        equal_site_reference$conf_high_ratio,
      interaction_equal_site_comparison_expected_melEDI_lx =
        equal_site_comparison$estimate_ratio,
      interaction_equal_site_comparison_conf_low_melEDI_lx =
        equal_site_comparison$conf_low_ratio,
      interaction_equal_site_comparison_conf_high_melEDI_lx =
        equal_site_comparison$conf_high_ratio
    )
    list(site = site_context, equal_site = equal_site_context)
  }
)

site_context <- dplyr::bind_rows(lapply(
  scenario_outputs,
  function(output) output$site
))
equal_site_context <- dplyr::bind_rows(lapply(
  scenario_outputs,
  function(output) output$equal_site
)) |>
  dplyr::mutate(
    interaction_equal_site_p_adjusted = stats::p.adjust(
      .data$interaction_equal_site_p_raw,
      method = "BH",
      n = 3L
    )
  )

accepted_with_context <- accepted |>
  dplyr::left_join(
    site_context,
    by = c("predictor_id", "site"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    equal_site_context,
    by = "predictor_id",
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    reference_site_tests,
    by = "site",
    relationship = "many-to-one"
  )
if (
  anyNA(accepted_with_context$reference_expected_melEDI_lx) ||
    anyNA(accepted_with_context$reference_vs_equal_site_p_adjusted) ||
    !isTRUE(all.equal(
      accepted_with_context$log_estimate,
      accepted_with_context$derived_log_estimate,
      tolerance = 1e-12
    )) ||
    !isTRUE(all.equal(
      accepted_with_context$log_standard_error,
      accepted_with_context$derived_log_standard_error,
      tolerance = 1e-12
    )) ||
    !isTRUE(all.equal(
      accepted_with_context$p_raw,
      accepted_with_context$derived_p_raw,
      tolerance = 1e-12
    ))
) {
  stop("The frozen site estimates and derived model contrasts disagree", call. = FALSE)
}

screen <- accepted_with_context |>
  dplyr::group_by(.data$predictor_id) |>
  dplyr::mutate(
    p_adjusted = stats::p.adjust(
      .data$p_raw,
      method = "BH",
      n = .env$planned_size
    ),
    adjusted_significant_0_05 = .data$p_adjusted <= .env$alpha,
    observed_size = dplyr::n()
  ) |>
  dplyr::ungroup() |>
  dplyr::left_join(
    site_registry,
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(
    match(.data$predictor_id, names(.env$effect_labels)),
    .data$display_order
  ) |>
  dplyr::transmute(
    family_id = paste0(.data$predictor_id, "__nine_site_screen"),
    family_label = paste(
      "Exploratory site-specific",
      unname(.env$effect_labels[.data$predictor_id]),
      "associations across nine sites"
    ),
    family_method = "Benjamini-Hochberg",
    planned_size = .env$planned_size,
    .data$observed_size,
    alpha = .env$alpha,
    .data$run_id,
    model_role = "full site-interaction model",
    distribution = "equal-site",
    covariance_type = "participant-cluster HC3; fix = FALSE",
    .data$denominator_df,
    .data$predictor_id,
    predictor_label = unname(.env$effect_labels[.data$predictor_id]),
    .data$effect_id,
    null_ratio = 1,
    .data$site,
    .data$display_name,
    .data$display_order,
    .data$color_hex,
    .data$log_estimate,
    .data$log_standard_error,
    .data$estimate_ratio,
    .data$conf_low_ratio,
    .data$conf_high_ratio,
    .data$statistic,
    .data$p_raw,
    .data$p_adjusted,
    .data$adjusted_significant_0_05,
    .data$comparison_label,
    .data$reference_sleep_duration_h,
    .data$reference_expected_melEDI_lx,
    .data$reference_conf_low_melEDI_lx,
    .data$reference_conf_high_melEDI_lx,
    .data$reference_family_id,
    .data$reference_family_method,
    .data$reference_planned_size,
    .data$reference_observed_size,
    .data$reference_vs_equal_site_ratio,
    .data$reference_vs_equal_site_conf_low_ratio,
    .data$reference_vs_equal_site_conf_high_ratio,
    .data$reference_vs_equal_site_p_raw,
    .data$reference_vs_equal_site_p_adjusted,
    .data$reference_vs_equal_site_adjusted_significant_0_05,
    .data$reference_test_scope,
    .data$comparison_expected_melEDI_lx,
    .data$comparison_conf_low_melEDI_lx,
    .data$comparison_conf_high_melEDI_lx,
    .data$interaction_equal_site_ratio,
    .data$interaction_equal_site_conf_low_ratio,
    .data$interaction_equal_site_conf_high_ratio,
    .data$interaction_equal_site_p_raw,
    .data$interaction_equal_site_p_adjusted,
    .data$interaction_equal_site_reference_expected_melEDI_lx,
    .data$interaction_equal_site_reference_conf_low_melEDI_lx,
    .data$interaction_equal_site_reference_conf_high_melEDI_lx,
    .data$interaction_equal_site_comparison_expected_melEDI_lx,
    .data$interaction_equal_site_comparison_conf_low_melEDI_lx,
    .data$interaction_equal_site_comparison_conf_high_melEDI_lx,
    screen_result = ifelse(
      .data$adjusted_significant_0_05,
      "Retained after within-predictor nine-site BH adjustment",
      "Not retained after within-predictor nine-site BH adjustment"
    ),
    test_scope = paste(
      "Each test compares one site's predictor-specific expected-hour ratio",
      "with the null ratio 1"
    ),
    distinction = paste(
      "This is not a test of the site's deviation from the equal-site",
      "average and not a test of between-site heterogeneity"
    ),
    inferential_role = paste(
      "Exploratory post-hoc screen; the primary associations and",
      "site-interaction block tests remain controlling"
    ),
    accepted_input = input_relative[[1L]],
    accepted_input_sha256 = artifact_sha256(input_path),
    model_archive = input_relative[[2L]],
    model_archive_sha256 = artifact_sha256(model_path)
  )

retained_keys <- paste(
  screen$predictor_id[screen$adjusted_significant_0_05],
  screen$site[screen$adjusted_significant_0_05],
  sep = "__"
)
expected_retained <- c(
  "work_free_day__RISE",
  "work_free_day__BAUA",
  "activity_status__MPI"
)
if (
  nrow(screen) != 27L ||
    !identical(sort(retained_keys), sort(expected_retained)) ||
    !all(screen$observed_size == planned_size) ||
    dplyr::n_distinct(screen$family_id) != 3L ||
    any(!is.finite(screen$reference_expected_melEDI_lx)) ||
    any(!is.finite(screen$reference_vs_equal_site_p_adjusted)) ||
    dplyr::n_distinct(screen$reference_family_id) != 1L ||
    !all(screen$reference_planned_size == planned_size) ||
    !all(screen$reference_observed_size == planned_size) ||
    any(!is.finite(screen$comparison_expected_melEDI_lx)) ||
    any(!is.finite(screen$interaction_equal_site_p_adjusted)) ||
    any(!is.finite(screen$p_adjusted)) ||
    any(screen$p_adjusted < screen$p_raw)
) {
  stop("The exploratory H06 site-specific screen failed its contract", call. = FALSE)
}

invisible(write_csv_artifact(screen, table_path, producer = producer))

figure_source <- screen |>
  dplyr::mutate(
    predictor_label = factor(
      .data$predictor_label,
      levels = .env$effect_order
    ),
    predictor_display = factor(
      dplyr::recode(
        as.character(.data$predictor_label),
        `Free day versus work day` = "Free day versus\nwork day",
        `Active versus sedentary` = "Active versus\nsedentary",
        `Previous sleep duration (per hour)` =
          "Previous sleep\n(per additional hour)"
      ),
      levels = c(
        "Free day versus\nwork day",
        "Active versus\nsedentary",
        "Previous sleep\n(per additional hour)"
      )
    ),
    display_name = factor(
      .data$display_name,
      levels = rev(.env$site_registry$display_name)
    ),
    screen_result = factor(
      .data$screen_result,
      levels = c(
        "Retained after within-predictor nine-site BH adjustment",
        "Not retained after within-predictor nine-site BH adjustment"
      )
    ),
    screen_label = factor(
      ifelse(
        .data$adjusted_significant_0_05,
        "BH-retained",
        "Not BH-retained"
      ),
      levels = c("BH-retained", "Not BH-retained")
    )
  )
if (
  any(!is.finite(figure_source$interaction_equal_site_ratio)) ||
    any(figure_source$interaction_equal_site_ratio <= 0)
) {
  stop("The interaction-model figure references are invalid", call. = FALSE)
}
invisible(write_csv_artifact(figure_source, source_path, producer = producer))

interaction_references <- figure_source |>
  dplyr::distinct(
    .data$predictor_display,
    .data$interaction_equal_site_ratio
  )

site_plot <- ggplot2::ggplot(
  figure_source,
  ggplot2::aes(
    x = .data$estimate_ratio,
    y = .data$display_name,
    xmin = .data$conf_low_ratio,
    xmax = .data$conf_high_ratio,
    colour = .data$site
  )
) +
  ggplot2::geom_vline(
    xintercept = 1,
    colour = "grey70",
    linewidth = 0.45
  ) +
  ggplot2::geom_vline(
    data = interaction_references,
    ggplot2::aes(xintercept = .data$interaction_equal_site_ratio),
    inherit.aes = FALSE,
    colour = "grey30",
    linetype = "dashed",
    linewidth = 0.65
  ) +
  ggplot2::geom_errorbar(
    orientation = "y",
    width = 0,
    linewidth = 0.6
  ) +
  ggplot2::geom_point(
    data = dplyr::filter(
      figure_source,
      !.data$adjusted_significant_0_05
    ),
    shape = 21,
    fill = "white",
    size = 3,
    stroke = 0.8
  ) +
  ggplot2::geom_point(
    data = dplyr::filter(
      figure_source,
      .data$adjusted_significant_0_05
    ),
    ggplot2::aes(fill = .data$site),
    shape = 21,
    size = 3.4,
    stroke = 0.7
  ) +
  ggplot2::facet_wrap(
    ~predictor_display,
    ncol = 3
  ) +
  ggplot2::scale_x_log10(
    breaks = c(0.25, 0.5, 1, 2, 4, 8),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  ggplot2::scale_colour_manual(
    values = stats::setNames(site_registry$color_hex, site_registry$site),
    guide = "none"
  ) +
  ggplot2::scale_fill_manual(
    values = stats::setNames(site_registry$color_hex, site_registry$site),
    guide = "none"
  ) +
  ggplot2::labs(
    title = "Site-specific mean hourly near-eye melEDI ratios",
    subtitle = paste(
      "Dashed: site-average estimate from this model; filled: retained",
      "after nine-site FDR adjustments; open:",
      "not retained"
    ),
    x = "Site-specific ratio (log scale)",
    y = NULL,
    caption = paste0(
      "Bars are participant-cluster HC3 pointwise 95% confidence intervals from the current\n",
      "predictor-by-site interaction model. The grey line at 1 is the site-specific association null.\n",
      "The dashed line is the site-average geometric mean of the nine ratios in this same model.\n",
      "Filled points pass a separate nine-site FDR adjustment within that predictor; this does\n",
      "not test deviation from the site-average estimate or the overall predictor-by-site interaction."
    )
  ) +
  cowplot::theme_cowplot(font_size = 10.5) +
  ggplot2::theme(
    axis.text = ggplot2::element_text(size = 8, colour = "black"),
    axis.title = ggplot2::element_text(size = 9),
    strip.background = ggplot2::element_rect(
      fill = "#D9D9D9",
      colour = NA
    ),
    strip.text = ggplot2::element_text(size = 9, face = "bold"),
    plot.title = ggplot2::element_text(size = 10.5, face = "bold"),
    plot.subtitle = ggplot2::element_text(size = 8.5),
    plot.caption = ggplot2::element_text(
      size = 7.5,
      hjust = 0,
      lineheight = 1.03,
      margin = ggplot2::margin(t = 8, b = 4)
    ),
    panel.grid.major.y = ggplot2::element_line(
      colour = "#E3E6E8",
      linewidth = 0.35
    ),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    panel.spacing = grid::unit(1.1, "lines"),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.margin = ggplot2::margin(t = 7, r = 8, b = 10, l = 7)
  )

native_width_mm <- 170
native_height_mm <- 135
native_width_in <- native_width_mm / 25.4
native_height_in <- native_height_mm / 25.4
smallest_nominal_text_pt <- 8
ggplot2::ggsave(
  file.path(figure_root, paste0(figure_id, ".png")),
  plot = site_plot,
  width = native_width_in,
  height = native_height_in,
  units = "in",
  dpi = 320,
  bg = "white"
)
ggplot2::ggsave(
  file.path(figure_root, paste0(figure_id, ".pdf")),
  plot = site_plot,
  width = native_width_in,
  height = native_height_in,
  units = "in",
  device = grDevices::cairo_pdf,
  bg = "white"
)

preview_path <- file.path(qa_root, paste0(figure_id, "_A4_preview.pdf"))
grDevices::cairo_pdf(
  preview_path,
  width = 210 / 25.4,
  height = 297 / 25.4,
  bg = "white"
)
grid::grid.newpage()
grid::grid.rect(gp = grid::gpar(fill = "white", col = NA))
grid::pushViewport(grid::viewport(
  width = grid::unit(native_width_mm, "mm"),
  height = grid::unit(native_height_mm, "mm")
))
print(site_plot, newpage = FALSE)
grid::popViewport()
grDevices::dev.off()

qa_text <- if (qa_status == "PASS") {
  paste0(
    "PASS at 170 mm on an A4 portrait page with 20-mm side margins: ",
    "no clipping, overlap, harmful wrapping, distortion, or materially ",
    "imbalanced data region; filled and open point shapes remain ",
    "distinguishable without colour."
  )
} else {
  paste0(
    "NOT TESTED: inspect the A4 physical-size preview for clipping, overlap, ",
    "wrapping, distortion, data-region balance, and shape differentiation."
  )
}
figure_qa <- tibble::tibble(
  figure_id = figure_id,
  source_csv = substring(source_path, nchar(root) + 2L),
  a4_preview = substring(preview_path, nchar(root) + 2L),
  native_width_mm = native_width_mm,
  native_height_mm = native_height_mm,
  base_width_in = native_width_in,
  base_height_in = native_height_in,
  export_scale_multiplier = 1,
  export_width_in = native_width_in,
  export_height_in = native_height_in,
  raster_dpi = 320,
  intended_html_display_width_mm = 170,
  intended_print_display_width_mm = 170,
  scale_factor = 1,
  smallest_essential_nominal_text_pt = smallest_nominal_text_pt,
  effective_final_text_pt = smallest_nominal_text_pt,
  physical_size_inspection = qa_text,
  clipping_overlap_wrapping_distortion_balance = qa_text,
  report_011_status = qa_status
)
invisible(write_csv_artifact(figure_qa, qa_path, producer = producer))

message(
  paste0(
    "H06 Stage 3 site-specific screen built without refitting: ",
    "3 associations retained after separate nine-site BH adjustments; ",
    "figure QA ",
    qa_status
  )
)
