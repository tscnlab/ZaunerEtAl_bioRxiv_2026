#!/usr/bin/env Rscript

# Build reader inputs for the author-requested H06_daily Stage 3 revision.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(ggplot2)
  library(glmmTMB)
  library(lme4)
  library(readr)
  library(reformulas)
  library(tibble)
  library(tidyr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H06_daily Stage 3 revision build requires R 4.6.1", call. = FALSE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}

read_project_csv <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}

write_project_csv <- function(data, relative_path) {
  path <- file.path(root, relative_path)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(data, path, na = "")
  invisible(path)
}

inputs <- tibble::tribble(
  ~input_id, ~relative_path, ~expected_sha256, ~role,
  "joint_authorization",
  "audit/hypotheses/H06_daily/H06_daily_joint_context_exploratory_authorization.md",
  "2f83d045f7c117b4c1849904f3be54dbeea44c601edd8e5fe2a40525123b0026",
  "Task-local authorization for the mutually adjusted daily analysis",
  "accepted_primary_results",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_results.csv",
  "c81af8827137259ab6bd6c8188971039ddd8e2aca71827a50a0ae94f2ea19e9a",
  "Accepted predictor-specific primary daily results",
  "accepted_bh_families",
  "artifacts/09_tables/H06_daily/H06_daily_gap_clock_repair_bh_families.csv",
  "773e299346cbed58a4b3385f91ae58e3eb7effaba7d0b02353d595e06fc3232c",
  "Accepted primary and gap 15-slot FDR families",
  "accepted_cell_classification",
  "artifacts/08_diagnostics/H06_daily/H06_daily_gap_clock_repair_h01_classification.csv",
  "e7aa89e35d7857fc167940fab6f6e2113b22b47932e90a62e57c5aaf271f2d40",
  "Accepted cell, model, sample, and object identities",
  "joint_stability",
  "artifacts/11_source_data/H06_daily/H06_daily_joint_context_exploratory_stability.csv",
  "3f3012e1a2289f17b7fe104a61482c10ccc5a201e19df6d9edf514cf9a419a6f",
  "Common-sample predictor-specific versus mutually adjusted estimates",
  "joint_site_estimates",
  "artifacts/11_source_data/H06_daily/H06_daily_joint_context_exploratory_site_estimates.csv",
  "f3024b183e108370920e27b6ce69a56bae632d91cde20d43c6c02b427218464c",
  "Mutually adjusted site-specific estimates",
  "joint_family_summary",
  "artifacts/09_tables/H06_daily/H06_daily_joint_context_exploratory_family_summary.csv",
  "f80a157ad2c4045ff99b81199f04454c78e6512c534d3d4035941126123daa01",
  "Six exploratory 15-slot FDR-family summaries",
  "joint_visual_review",
  "artifacts/08_diagnostics/H06_daily/H06_daily_joint_context_exploratory_visual_review.csv",
  "158da70f80eebc9a4b764f4ec1e3c532b94b25c2177f9f6641e050a69c832f67",
  "Direct residual-plot review of the mutually adjusted models",
  "joint_output_manifest",
  "artifacts/12_manifests/H06_daily/H06_daily_joint_context_exploratory_output_manifest.csv",
  "90b458b251f023c4e9a4716164ceeb13942acf6bb976a61106b513d79164fb89",
  "Exploratory joint-model output identities before manual visual review",
  "temporal_context_summary",
  "artifacts/09_tables/H06_daily/H06_daily_temporal_h02_production_context_function_summary.csv",
  "5d0941a3f407198ecd017c34734217343b7ae952f0c0cf3a41a993bb3fd20a65",
  "Accepted exploratory temporal whole-function summaries",
  "temporal_whole_function_tests",
  "artifacts/09_tables/H06_daily/H06_daily_temporal_h02_production_whole_function_tests.csv",
  "c953f6b4074fcc8d26cf029ce4c33b44ed6985e2173bb7efffbd907b742124d1",
  "Accepted exploratory temporal whole-function tests",
  "temporal_support",
  "artifacts/08_diagnostics/H06_daily/H06_daily_temporal_h02_production_support_overall.csv",
  "f24ff12fce1a0a6d3c2060be54088bd7aefd6b383bf7dc16a635223c915f959f",
  "Exact exploratory temporal fitted samples",
  "temporal_diagnostic_verdict",
  "artifacts/08_diagnostics/H06_daily/H06_daily_temporal_h02_production_diagnostic_verdict.csv",
  "1405e56ff776df9fccd2a35df2d02894e01e9b49d2e85ef34a86cc2aed3e137a",
  "Accepted exploratory temporal diagnostic verdicts",
  "temporal_figure",
  "artifacts/10_figures/H06_daily/H06_daily_temporal_h02_primary_context_functions.png",
  "e28c639f23b3f33687ca046a77069153bb66073d29cd03d96fd03408c4317d98",
  "Accepted primary near-eye temporal context-function figure",
  "temporal_figure_source",
  "artifacts/11_source_data/H06_daily/H06_daily_temporal_h02_primary_context_functions_figure_source.csv",
  "4c104c16734f5b23d02b864fdc90aee445538823e41fb0119e2de7ac9bd4ef63",
  "Paired source data for the temporal context-function figure",
  "temporal_alt_text",
  "artifacts/11_source_data/H06_daily/H06_daily_temporal_h02_figure_alt_text.csv",
  "e5bba4c7f7ed670f477e945e71393e3f72483f75176310d22b4be6c8485fad7d",
  "Accepted temporal figure alt text",
  "main_h06_core_effects",
  "artifacts/09_tables/H06/H06_robust_core_effects.csv",
  "3b23890248665c5ebd9fa0b7914a5cad1a43cea3ae63f29723590de2f3674440",
  "Selected main hourly H06 equal-site associations",
  "main_h06_wald_tests",
  "artifacts/09_tables/H06/H06_robust_wald_tests.csv",
  "43c370cb42ca4b82fb55d72bdb5c288b3c3798fbce8277d1de71e6d5d4465e93",
  "Selected main hourly H06 association and interaction tests",
  "main_h06_site_screen",
  "artifacts/09_tables/H06/H06_stage3_site_specific_significance_screen.csv",
  "dacc1b3a1d92c0900f440a54ea9cb165bf1945563100eb29337e6e23f701b297",
  "Selected main hourly H06 site-specific screen",
  "site_registry",
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "Submitted site names, order, and colours"
)

inputs <- inputs |>
  mutate(
    exists = file.exists(file.path(root, .data$relative_path)),
    actual_sha256 = if_else(
      .data$exists,
      vapply(file.path(root, .data$relative_path), sha256, character(1L)),
      NA_character_
    ),
    verification_status = if_else(
      .data$exists & .data$actual_sha256 == .data$expected_sha256,
      "PASS",
      "FAIL"
    ),
    authorization = "author-requested-stage3-revision",
    gate = "H06-D-G3-revision",
    r_version = as.character(getRversion())
  )

if (any(inputs$verification_status != "PASS")) {
  stop(
    paste(
      "H06_daily Stage 3 revision input mismatch:",
      paste(inputs$relative_path[inputs$verification_status != "PASS"], collapse = ", ")
    ),
    call. = FALSE
  )
}

write_project_csv(
  inputs,
  "artifacts/12_manifests/H06_daily/H06_daily_stage3_revision_input_manifest.csv"
)

families <- read_project_csv(inputs$relative_path[inputs$input_id == "accepted_bh_families"])
classification <- read_project_csv(
  inputs$relative_path[inputs$input_id == "accepted_cell_classification"]
)
site_registry <- read_project_csv(inputs$relative_path[inputs$input_id == "site_registry"])

supported_interactions <- families |>
  filter(
    .data$dataset_id == "primary",
    .data$test_type == "site_heterogeneity",
    .data$fdr_supported,
    .data$h01_claim_eligible
  ) |>
  select(
    metric_slot,
    metric_id,
    manuscript_name,
    predictor_order,
    predictor_id,
    predictor = reader_name,
    global_interaction_raw_p = raw_p_value,
    global_interaction_bh_q = bh_adjusted_p_value,
    frame_key
  ) |>
  left_join(
    classification |>
      filter(
        .data$dataset_id == "primary",
        .data$placement_id == "near_eye",
        .data$sample_role == "all_available"
      ) |>
      select(
        metric_slot,
        predictor_id,
        frame_key,
        route,
        response_family,
        response_transform,
        effect_scale,
        participant_days,
        participants,
        sites,
        model_relative_path,
        model_file_sha256,
        additive_model_object_sha256 = model_object_sha256
      ),
    by = c("metric_slot", "predictor_id", "frame_key"),
    relationship = "one-to-one"
  ) |>
  arrange(.data$predictor_order, .data$metric_slot)

if (nrow(supported_interactions) != 10L || anyNA(supported_interactions$model_relative_path)) {
  stop("Expected exactly 10 accepted primary site interactions", call. = FALSE)
}

predictor_scenarios <- function(model_frame, predictor_id) {
  if (predictor_id == "work_free_day") {
    list(
      reference = factor("Work day", levels = levels(model_frame$work_free_day)),
      comparison = factor("Free day", levels = levels(model_frame$work_free_day)),
      reference_label = "Work day",
      comparison_label = "Free day"
    )
  } else if (predictor_id == "activity_status") {
    list(
      reference = factor("Sedentary", levels = levels(model_frame$activity_status)),
      comparison = factor("Active", levels = levels(model_frame$activity_status)),
      reference_label = "Sedentary",
      comparison_label = "Active"
    )
  } else if (predictor_id == "previous_sleep_duration_centered_h") {
    list(
      reference = 0,
      comparison = 1,
      reference_label = "8 h previous-night sleep",
      comparison_label = "9 h previous-night sleep"
    )
  } else {
    stop(paste("Unknown predictor", predictor_id), call. = FALSE)
  }
}

fixed_components <- function(fit) {
  if (inherits(fit, "lmerMod")) {
    list(
      beta = lme4::fixef(fit),
      covariance = as.matrix(stats::vcov(fit)),
      model_matrix = lme4::getME(fit, "X"),
      formula = reformulas::nobars(stats::formula(fit))
    )
  } else if (inherits(fit, "glmmTMB")) {
    list(
      beta = glmmTMB::fixef(fit)$cond,
      covariance = as.matrix(stats::vcov(fit)$cond),
      model_matrix = stats::model.matrix(fit, component = "cond"),
      formula = reformulas::nobars(stats::formula(fit))
    )
  } else {
    stop(paste("Unsupported interaction fit class", class(fit)[[1L]]), call. = FALSE)
  }
}

inverse_response <- function(eta, response_family, response_transform) {
  if (response_transform == "log10_offset_0.1") {
    return(10^eta - 0.1)
  }
  if (response_family == "tweedie_log") {
    return(exp(eta))
  }
  eta
}

display_contrast <- function(contrast, response_family, response_transform) {
  if (response_transform == "log10_offset_0.1") {
    return(10^contrast)
  }
  if (response_family == "tweedie_log") {
    return(exp(contrast))
  }
  contrast
}

equal_site_contrast <- function(
  contrast_design,
  components,
  response_family,
  response_transform
) {
  average_design <- matrix(
    colMeans(contrast_design),
    nrow = 1L,
    dimnames = list(NULL, colnames(contrast_design))
  )
  estimate <- drop(average_design %*% components$beta)
  standard_error <- sqrt(pmax(
    0,
    drop(average_design %*% components$covariance %*% t(average_design))
  ))
  critical <- stats::qnorm(0.975)
  lower <- estimate - critical * standard_error
  upper <- estimate + critical * standard_error
  tibble(
    equal_site_contrast_estimate = estimate,
    equal_site_contrast_standard_error = standard_error,
    equal_site_contrast_lower_95 = lower,
    equal_site_contrast_upper_95 = upper,
    equal_site_display_estimate = display_contrast(
      estimate,
      response_family,
      response_transform
    ),
    equal_site_display_lower_95 = display_contrast(
      lower,
      response_family,
      response_transform
    ),
    equal_site_display_upper_95 = display_contrast(
      upper,
      response_family,
      response_transform
    )
  )
}

extract_site_contrasts <- function(row) {
  model_path <- file.path(root, row$model_relative_path[[1L]])
  if (!identical(sha256(model_path), row$model_file_sha256[[1L]])) {
    stop(paste("Changed stored model file", row$model_relative_path[[1L]]), call. = FALSE)
  }
  archive <- readRDS(model_path)
  additive_fit <- archive$result$models$additive_reml$value
  deserialized_additive_model_object_sha256 <- object_sha256(additive_fit)
  fit <- archive$result$models$heterogeneity_reml$value
  heterogeneity_model_object_sha256 <- object_sha256(fit)

  model_frame <- stats::model.frame(fit)
  site_levels <- levels(model_frame$site)
  scenarios <- predictor_scenarios(model_frame, row$predictor_id[[1L]])
  predictor_id <- row$predictor_id[[1L]]

  newdata <- tibble(site = rep(site_levels, each = 2L))
  newdata$site <- factor(newdata$site, levels = site_levels)

  if (is.factor(model_frame[[predictor_id]])) {
    newdata[[predictor_id]] <- factor(
      rep(c(as.character(scenarios$reference), as.character(scenarios$comparison)),
        times = length(site_levels)
      ),
      levels = levels(model_frame[[predictor_id]])
    )
  } else {
    newdata[[predictor_id]] <- rep(
      c(scenarios$reference, scenarios$comparison),
      times = length(site_levels)
    )
  }

  components <- fixed_components(fit)
  matrix_contrasts <- attr(components$model_matrix, "contrasts")
  factor_names <- names(model_frame)[vapply(model_frame, is.factor, logical(1L))]
  fixed_factor_names <- intersect(factor_names, names(newdata))
  xlevels <- lapply(model_frame[fixed_factor_names], levels)
  design <- stats::model.matrix(
    stats::delete.response(stats::terms(components$formula)),
    data = newdata,
    contrasts.arg = matrix_contrasts,
    xlev = xlevels
  )
  if (!identical(colnames(design), names(components$beta))) {
    stop(paste("Fixed-effect design mismatch for", row$frame_key[[1L]]), call. = FALSE)
  }

  reference_rows <- seq.int(1L, nrow(design), by = 2L)
  comparison_rows <- reference_rows + 1L
  reference_design <- design[reference_rows, , drop = FALSE]
  comparison_design <- design[comparison_rows, , drop = FALSE]
  contrast_design <- comparison_design - reference_design
  reference_eta <- drop(reference_design %*% components$beta)
  comparison_eta <- drop(comparison_design %*% components$beta)
  contrast_eta <- drop(contrast_design %*% components$beta)
  contrast_se <- sqrt(pmax(
    0,
    rowSums((contrast_design %*% components$covariance) * contrast_design)
  ))
  critical <- stats::qnorm(0.975)
  lower_eta <- contrast_eta - critical * contrast_se
  upper_eta <- contrast_eta + critical * contrast_se
  estimate <- display_contrast(
    contrast_eta,
    row$response_family[[1L]],
    row$response_transform[[1L]]
  )
  lower <- display_contrast(
    lower_eta,
    row$response_family[[1L]],
    row$response_transform[[1L]]
  )
  upper <- display_contrast(
    upper_eta,
    row$response_family[[1L]],
    row$response_transform[[1L]]
  )
  null <- if (grepl("ratio", row$effect_scale[[1L]], fixed = TRUE)) 1 else 0
  equal_site <- equal_site_contrast(
    contrast_design,
    components,
    row$response_family[[1L]],
    row$response_transform[[1L]]
  )
  average_contrast_design <- colMeans(contrast_design)
  site_deviation_design <- sweep(
    contrast_design,
    MARGIN = 2L,
    STATS = average_contrast_design,
    FUN = "-"
  )
  site_deviation_eta <- drop(site_deviation_design %*% components$beta)
  site_deviation_se <- sqrt(pmax(
    0,
    rowSums(
      (site_deviation_design %*% components$covariance) *
        site_deviation_design
    )
  ))
  site_deviation_lower_eta <- site_deviation_eta - critical * site_deviation_se
  site_deviation_upper_eta <- site_deviation_eta + critical * site_deviation_se
  site_adjustment_factor <- display_contrast(
    site_deviation_eta,
    row$response_family[[1L]],
    row$response_transform[[1L]]
  )
  site_adjustment_lower_95 <- display_contrast(
    site_deviation_lower_eta,
    row$response_family[[1L]],
    row$response_transform[[1L]]
  )
  site_adjustment_upper_95 <- display_contrast(
    site_deviation_upper_eta,
    row$response_family[[1L]],
    row$response_transform[[1L]]
  )
  if (!grepl("ratio", row$effect_scale[[1L]], fixed = TRUE)) {
    stop(
      paste(
        "A supported primary interaction is not multiplicative:",
        row$metric_id[[1L]],
        predictor_id
      ),
      call. = FALSE
    )
  }

  tibble(
    metric_slot = row$metric_slot[[1L]],
    metric_id = row$metric_id[[1L]],
    manuscript_name = row$manuscript_name[[1L]],
    predictor_order = row$predictor_order[[1L]],
    predictor_id = predictor_id,
    predictor = row$predictor[[1L]],
    site = site_levels,
    reference_level = scenarios$reference_label,
    comparison_level = scenarios$comparison_label,
    reference_fitted = inverse_response(
      reference_eta,
      row$response_family[[1L]],
      row$response_transform[[1L]]
    ),
    comparison_fitted = inverse_response(
      comparison_eta,
      row$response_family[[1L]],
      row$response_transform[[1L]]
    ),
    contrast_estimate = contrast_eta,
    contrast_standard_error = contrast_se,
    contrast_lower_95 = lower_eta,
    contrast_upper_95 = upper_eta,
    display_estimate = estimate,
    display_lower_95 = lower,
    display_upper_95 = upper,
    effect_scale = row$effect_scale[[1L]],
    pointwise_interval_excludes_null = lower > null | upper < null,
    direction = case_when(
      estimate < null ~ "comparison lower",
      estimate > null ~ "comparison higher",
      TRUE ~ "null"
    ),
    global_interaction_raw_p = row$global_interaction_raw_p[[1L]],
    global_interaction_bh_q = row$global_interaction_bh_q[[1L]],
    participant_days = row$participant_days[[1L]],
    participants = row$participants[[1L]],
    sites = row$sites[[1L]],
    equal_site_contrast_estimate = equal_site$equal_site_contrast_estimate,
    equal_site_contrast_standard_error =
      equal_site$equal_site_contrast_standard_error,
    equal_site_contrast_lower_95 = equal_site$equal_site_contrast_lower_95,
    equal_site_contrast_upper_95 = equal_site$equal_site_contrast_upper_95,
    equal_site_display_estimate = equal_site$equal_site_display_estimate,
    equal_site_display_lower_95 = equal_site$equal_site_display_lower_95,
    equal_site_display_upper_95 = equal_site$equal_site_display_upper_95,
    site_deviation_contrast_estimate = site_deviation_eta,
    site_deviation_contrast_standard_error = site_deviation_se,
    site_deviation_contrast_lower_95 = site_deviation_lower_eta,
    site_deviation_contrast_upper_95 = site_deviation_upper_eta,
    site_adjustment_factor = site_adjustment_factor,
    site_adjustment_lower_95 = site_adjustment_lower_95,
    site_adjustment_upper_95 = site_adjustment_upper_95,
    site_adjustment_direction = case_when(
      site_adjustment_factor < 1 ~ "below_equal_site",
      site_adjustment_factor > 1 ~ "above_equal_site",
      TRUE ~ "equal_to_equal_site"
    ),
    site_adjustment_pointwise_classification = case_when(
      site_adjustment_upper_95 < 1 ~ "below_equal_site",
      site_adjustment_lower_95 > 1 ~ "above_equal_site",
      TRUE ~ "compatible_with_equal_site"
    ),
    model_relative_path = row$model_relative_path[[1L]],
    model_file_sha256 = row$model_file_sha256[[1L]],
    additive_model_object_sha256 = row$additive_model_object_sha256[[1L]],
    deserialized_additive_model_object_sha256 =
      deserialized_additive_model_object_sha256,
    heterogeneity_model_object_sha256 = heterogeneity_model_object_sha256
  ) |>
    left_join(site_registry, by = "site", relationship = "many-to-one") |>
    arrange(.data$display_order)
}

site_estimates <- bind_rows(lapply(
  seq_len(nrow(supported_interactions)),
  function(index) extract_site_contrasts(supported_interactions[index, , drop = FALSE])
))

if (
  nrow(site_estimates) != 90L ||
    anyNA(site_estimates$display_name) ||
    any(site_estimates$sites != 9L) ||
    any(!is.finite(site_estimates$site_adjustment_factor)) ||
    any(site_estimates$site_adjustment_lower_95 <= 0) ||
    any(site_estimates$site_adjustment_upper_95 <= 0) ||
    any(abs(
      site_estimates |>
        group_by(.data$metric_id, .data$predictor_id) |>
        summarise(
          geometric_mean_adjustment = exp(mean(log(.data$site_adjustment_factor))),
          .groups = "drop"
        ) |>
        pull(.data$geometric_mean_adjustment) - 1
    ) > 1e-12)
) {
  stop("The accepted site-contrast grid is incomplete", call. = FALSE)
}

format_site_effect <- function(
  name,
  color,
  estimate,
  lower,
  upper,
  effect_scale
) {
  site_label <- sprintf(
    paste0(
      "<span aria-hidden='true' style='color:%s;font-size:1.12em'>",
      "●</span>&nbsp;%s"
    ),
    color,
    name
  )
  if (grepl("ratio", effect_scale, fixed = TRUE)) {
    sprintf(
      "%s: %.2f times (%.2f to %.2f)",
      site_label,
      estimate,
      lower,
      upper
    )
  } else {
    sprintf(
      "%s: %+.2f h (%+.2f to %+.2f)",
      site_label,
      estimate,
      lower,
      upper
    )
  }
}

summarize_sites <- function(
  data,
  direction_value,
  exclude_value,
  effect_scale_value
) {
  selected <- data |>
    filter(
      .data$direction == direction_value,
      .data$pointwise_interval_excludes_null == exclude_value
    )
  if (!nrow(selected)) return("None")
  paste(
    mapply(
      format_site_effect,
      selected$display_name,
      selected$color_hex,
      selected$display_estimate,
      selected$display_lower_95,
      selected$display_upper_95,
      rep(effect_scale_value, nrow(selected)),
      USE.NAMES = FALSE
    ),
    collapse = "; "
  )
}

summarize_compatible_sites <- function(data, effect_scale_value) {
  selected <- data |>
    filter(!.data$pointwise_interval_excludes_null)
  if (!nrow(selected)) return("None")
  paste(
    mapply(
      format_site_effect,
      selected$display_name,
      selected$color_hex,
      selected$display_estimate,
      selected$display_lower_95,
      selected$display_upper_95,
      rep(effect_scale_value, nrow(selected)),
      USE.NAMES = FALSE
    ),
    collapse = "; "
  )
}

format_site_adjustment <- function(name, color, estimate, lower, upper) {
  site_label <- sprintf(
    paste0(
      "<span aria-hidden='true' style='color:%s;font-size:1.12em'>",
      "●</span>&nbsp;%s"
    ),
    color,
    name
  )
  sprintf(
    "%s: ×%.2f (%.2f to %.2f)",
    site_label,
    estimate,
    lower,
    upper
  )
}

summarize_site_adjustments <- function(data, classification_value) {
  selected <- data |>
    filter(.data$site_adjustment_pointwise_classification == classification_value)
  if (!nrow(selected)) return("None")
  paste(
    mapply(
      format_site_adjustment,
      selected$display_name,
      selected$color_hex,
      selected$site_adjustment_factor,
      selected$site_adjustment_lower_95,
      selected$site_adjustment_upper_95,
      USE.NAMES = FALSE
    ),
    collapse = "; "
  )
}

site_summary <- site_estimates |>
  group_by(
    metric_slot,
    metric_id,
    manuscript_name,
    predictor_order,
    predictor_id,
    predictor,
    global_interaction_raw_p,
    global_interaction_bh_q,
    effect_scale,
    participant_days,
    participants,
    sites
  ) |>
  group_modify(
    ~ tibble(
      pointwise_comparison_lower = summarize_sites(
        .x,
        "comparison lower",
        TRUE,
        .y$effect_scale[[1L]]
      ),
      pointwise_comparison_higher = summarize_sites(
        .x,
        "comparison higher",
        TRUE,
        .y$effect_scale[[1L]]
      ),
      pointwise_compatible_with_null = summarize_compatible_sites(
        .x,
        .y$effect_scale[[1L]]
      ),
      pointwise_adjustment_below_equal_site = summarize_site_adjustments(
        .x,
        "below_equal_site"
      ),
      pointwise_adjustment_above_equal_site = summarize_site_adjustments(
        .x,
        "above_equal_site"
      ),
      pointwise_adjustment_compatible_with_equal_site =
        summarize_site_adjustments(.x, "compatible_with_equal_site"),
      sites_pointwise_excluding_null = sum(.x$pointwise_interval_excludes_null),
      sites_pointwise_adjustment_excluding_one = sum(
        .x$site_adjustment_pointwise_classification !=
          "compatible_with_equal_site"
      ),
      equal_site_display_estimate = first(.x$equal_site_display_estimate),
      equal_site_display_lower_95 = first(.x$equal_site_display_lower_95),
      equal_site_display_upper_95 = first(.x$equal_site_display_upper_95),
      minimum_site_display_estimate = min(.x$display_estimate),
      maximum_site_display_estimate = max(.x$display_estimate)
    )
  ) |>
  ungroup() |>
  arrange(.data$predictor_order, .data$metric_slot)

write_project_csv(
  site_estimates,
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_site_interaction_estimates.csv"
)
write_project_csv(
  site_summary,
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_site_interaction_summary.csv"
)

site_deviation_figure_source <- site_estimates |>
  transmute(
    metric_slot,
    metric_id,
    manuscript_name,
    predictor_order,
    predictor_id,
    predictor,
    interaction_label = paste(.data$predictor, .data$manuscript_name, sep = ": "),
    site,
    display_order,
    display_name,
    color_hex,
    equal_site_comparison_reference = .data$equal_site_display_estimate,
    equal_site_comparison_reference_lower_95 = .data$equal_site_display_lower_95,
    equal_site_comparison_reference_upper_95 = .data$equal_site_display_upper_95,
    site_specific_comparison_reference = .data$display_estimate,
    site_specific_comparison_reference_lower_95 = .data$display_lower_95,
    site_specific_comparison_reference_upper_95 = .data$display_upper_95,
    site_adjustment_factor,
    site_adjustment_lower_95,
    site_adjustment_upper_95,
    site_adjustment_direction,
    site_adjustment_pointwise_classification,
    global_interaction_raw_p,
    global_interaction_bh_q,
    interval_scope = paste(
      "Pointwise 95% interval for the site's comparison/reference log-ratio",
      "minus the equal-site mean log-ratio; not multiplicity adjusted across sites"
    ),
    interpretation = paste(
      "Adjustment factor = full site-specific comparison/reference ratio",
      "divided by the equal-site comparison/reference ratio"
    ),
    model_relative_path,
    model_file_sha256,
    heterogeneity_model_object_sha256
  ) |>
  arrange(.data$predictor_order, .data$metric_slot, .data$display_order)

write_project_csv(
  site_deviation_figure_source,
  paste0(
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_stage3_primary_site_deviation_figure.csv"
  )
)

interaction_levels <- site_deviation_figure_source |>
  distinct(.data$predictor_order, .data$metric_slot, .data$interaction_label) |>
  arrange(.data$predictor_order, .data$metric_slot) |>
  pull(.data$interaction_label)
site_colors <- stats::setNames(site_registry$color_hex, site_registry$display_name)
figure_data <- site_deviation_figure_source |>
  mutate(
    interaction_label = factor(.data$interaction_label, levels = interaction_levels),
    display_name = factor(
      .data$display_name,
      levels = rev(site_registry$display_name)
    )
  )

site_deviation_plot <- ggplot(
  figure_data,
  aes(
    x = .data$site_adjustment_factor,
    y = .data$display_name,
    xmin = .data$site_adjustment_lower_95,
    xmax = .data$site_adjustment_upper_95,
    colour = .data$display_name,
    fill = .data$display_name
  )
) +
  geom_vline(xintercept = 1, colour = "grey45", linewidth = 0.55) +
  geom_errorbar(orientation = "y", width = 0, linewidth = 0.55) +
  geom_point(shape = 21, size = 2.8, stroke = 0.55) +
  facet_wrap(
    vars(.data$interaction_label),
    ncol = 2,
    labeller = label_wrap_gen(width = 42)
  ) +
  scale_x_log10(
    breaks = c(0.125, 0.25, 0.5, 1, 2, 4, 8, 16),
    labels = function(value) format(value, trim = TRUE, scientific = FALSE)
  ) +
  scale_colour_manual(values = site_colors, guide = "none") +
  scale_fill_manual(values = site_colors, guide = "none") +
  labs(
    title = "Site deviations from the equal-site context association",
    subtitle = paste(
      "Adjustment factor = full site-specific comparison/reference ratio ÷",
      "equal-site comparison/reference ratio"
    ),
    x = "Site adjustment factor (log scale)",
    y = NULL,
    caption = paste0(
      "Points and bars are adjustment factors with pointwise 95% confidence intervals.\n",
      "Values below 1 indicate a weaker site-specific comparison/reference ratio ",
      "than the equal-site contrast; values above 1 indicate a stronger ratio.\n",
      "Intervals are descriptive localizations after a globally FDR-supported ",
      "interaction and are not multiplicity adjusted across the nine sites."
    )
  ) +
  theme_minimal(base_size = 10.5) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    axis.text = element_text(colour = "black", size = 8.2),
    axis.title.x = element_text(size = 9.5),
    strip.text = element_text(face = "bold", size = 9),
    strip.background = element_rect(fill = "#E8EEF3", colour = NA),
    panel.spacing = grid::unit(10, "pt"),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10),
    plot.caption = element_text(hjust = 0, size = 8.2),
    plot.margin = margin(8, 10, 8, 8)
  )

figure_directory <- file.path(root, "artifacts/10_figures/H06_daily")
dir.create(figure_directory, recursive = TRUE, showWarnings = FALSE)
site_deviation_png <- file.path(
  figure_directory,
  "H06_daily_stage3_primary_site_deviations.png"
)
site_deviation_svg <- file.path(
  figure_directory,
  "H06_daily_stage3_primary_site_deviations.svg"
)
ggsave(
  site_deviation_png,
  site_deviation_plot,
  width = 260,
  height = 360,
  units = "mm",
  dpi = 300,
  bg = "white"
)
ggsave(
  site_deviation_svg,
  site_deviation_plot,
  width = 260,
  height = 360,
  units = "mm",
  bg = "white"
)

deviation_counts <- site_deviation_figure_source |>
  count(.data$site_adjustment_pointwise_classification, name = "sites")
deviation_count <- function(classification) {
  value <- deviation_counts$sites[
    deviation_counts$site_adjustment_pointwise_classification == classification
  ]
  if (!length(value)) 0L else value[[1L]]
}
site_deviation_alt <- tibble(
  figure_id = "primary_site_deviations",
  alt_text = paste0(
    "Ten faceted forest plots show nine site adjustment factors for each ",
    "globally supported primary predictor-by-site interaction. A factor below ",
    "1 means the site's comparison-to-reference ratio is lower than the ",
    "equal-site ratio, and a factor above 1 means it is higher. Horizontal ",
    "bars are pointwise 95% confidence intervals. Of 90 site adjustments, ",
    deviation_count("below_equal_site"),
    " are pointwise below 1, ",
    deviation_count("above_equal_site"),
    " are pointwise above 1, and ",
    deviation_count("compatible_with_equal_site"),
    " include 1. Filled points use the submitted site colours."
  ),
  source_data_relative_path = paste0(
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_stage3_primary_site_deviation_figure.csv"
  ),
  interval_type = "Pointwise 95% confidence intervals",
  multiplicity_scope = paste(
    "Descriptive localization after a globally FDR-supported interaction;",
    "no site-wise multiplicity adjustment"
  )
)
write_project_csv(
  site_deviation_alt,
  paste0(
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_stage3_primary_site_deviation_figure_alt_text.csv"
  )
)

joint_site_estimates <- read_project_csv(
  inputs$relative_path[inputs$input_id == "joint_site_estimates"]
) |>
  mutate(
    display_name = .data$site_name,
    color_hex = .data$site_color,
    null_value = if_else(
      grepl("ratio", .data$effect_scale, fixed = TRUE),
      1,
      0
    ),
    direction = case_when(
      .data$display_estimate < .data$null_value ~ "comparison lower",
      .data$display_estimate > .data$null_value ~ "comparison higher",
      TRUE ~ "null"
    )
  )

joint_output_manifest <- read_project_csv(
  inputs$relative_path[inputs$input_id == "joint_output_manifest"]
)
joint_model_manifest <- joint_output_manifest |>
  filter(grepl(
    "^artifacts/07_models/H06_daily/H06_daily_joint_context_exploratory_cells/.*\\.rds$",
    .data$relative_path,
    perl = TRUE
  ))

extract_joint_equal_site <- function(metric_id, predictor_id) {
  suffix <- paste0("_", metric_id, ".rds")
  model_row <- joint_model_manifest |>
    filter(endsWith(.data$relative_path, suffix))
  if (nrow(model_row) != 1L) {
    stop(paste("Missing unique joint model for", metric_id), call. = FALSE)
  }
  model_path <- file.path(root, model_row$relative_path[[1L]])
  if (
    !identical(sha256(model_path), model_row$sha256[[1L]]) ||
      !identical(as.numeric(file.info(model_path)$size), model_row$bytes[[1L]])
  ) {
    stop(paste("Changed joint model file", model_row$relative_path[[1L]]), call. = FALSE)
  }
  archive <- readRDS(model_path)
  fit <- archive$models$interactions_effect[[predictor_id]]$value
  if (is.null(fit)) {
    stop(paste("Missing joint interaction fit for", metric_id, predictor_id), call. = FALSE)
  }
  model_frame <- stats::model.frame(fit)
  site_levels <- levels(model_frame$site)
  scenarios <- predictor_scenarios(model_frame, predictor_id)
  newdata <- tibble(
    site = factor(rep(site_levels, each = 2L), levels = site_levels),
    work_free_day = factor(
      rep("Work day", length(site_levels) * 2L),
      levels = levels(model_frame$work_free_day)
    ),
    activity_status = factor(
      rep("Sedentary", length(site_levels) * 2L),
      levels = levels(model_frame$activity_status)
    ),
    previous_sleep_duration_centered_h = 0
  )
  if (is.factor(model_frame[[predictor_id]])) {
    newdata[[predictor_id]] <- factor(
      rep(
        c(as.character(scenarios$reference), as.character(scenarios$comparison)),
        times = length(site_levels)
      ),
      levels = levels(model_frame[[predictor_id]])
    )
  } else {
    newdata[[predictor_id]] <- rep(
      c(scenarios$reference, scenarios$comparison),
      times = length(site_levels)
    )
  }
  components <- fixed_components(fit)
  matrix_contrasts <- attr(components$model_matrix, "contrasts")
  factor_names <- names(model_frame)[vapply(model_frame, is.factor, logical(1L))]
  fixed_factor_names <- intersect(factor_names, names(newdata))
  xlevels <- lapply(model_frame[fixed_factor_names], levels)
  design <- stats::model.matrix(
    stats::delete.response(stats::terms(components$formula)),
    data = newdata,
    contrasts.arg = matrix_contrasts,
    xlev = xlevels
  )
  if (!identical(colnames(design), names(components$beta))) {
    stop(paste("Joint fixed-effect design mismatch for", metric_id), call. = FALSE)
  }
  reference_rows <- seq.int(1L, nrow(design), by = 2L)
  contrast_design <- design[reference_rows + 1L, , drop = FALSE] -
    design[reference_rows, , drop = FALSE]
  bind_cols(
    tibble(metric_id = metric_id, predictor_id = predictor_id),
    equal_site_contrast(
      contrast_design,
      components,
      archive$metric$response_family[[1L]],
      archive$metric$response_transform[[1L]]
    )
  )
}

joint_supported_pairs <- joint_site_estimates |>
  filter(.data$global_interaction_fdr_supported) |>
  distinct(.data$metric_id, .data$predictor_id)
joint_equal_site <- bind_rows(lapply(
  seq_len(nrow(joint_supported_pairs)),
  function(index) {
    row <- joint_supported_pairs[index, , drop = FALSE]
    extract_joint_equal_site(row$metric_id[[1L]], row$predictor_id[[1L]])
  }
))

joint_site_estimates <- joint_site_estimates |>
  left_join(
    joint_equal_site,
    by = c("metric_id", "predictor_id"),
    relationship = "many-to-one"
  )

joint_site_summary <- joint_site_estimates |>
  filter(.data$global_interaction_fdr_supported) |>
  group_by(
    metric_slot,
    metric_id,
    manuscript_name,
    predictor_order,
    predictor_id,
    predictor,
    global_interaction_raw_p,
    global_interaction_bh_q,
    effect_scale
  ) |>
  group_modify(
    ~ tibble(
      pointwise_comparison_lower = summarize_sites(
        .x,
        "comparison lower",
        TRUE,
        .y$effect_scale[[1L]]
      ),
      pointwise_comparison_higher = summarize_sites(
        .x,
        "comparison higher",
        TRUE,
        .y$effect_scale[[1L]]
      ),
      pointwise_compatible_with_null = summarize_compatible_sites(
        .x,
        .y$effect_scale[[1L]]
      ),
      sites_pointwise_excluding_null = sum(.x$pointwise_interval_excludes_null),
      equal_site_display_estimate = first(.x$equal_site_display_estimate),
      equal_site_display_lower_95 = first(.x$equal_site_display_lower_95),
      equal_site_display_upper_95 = first(.x$equal_site_display_upper_95),
      minimum_site_display_estimate = min(.x$display_estimate),
      maximum_site_display_estimate = max(.x$display_estimate),
      reporting_role = if_else(
        .y$metric_slot[[1L]] == 15L,
        "Descriptive MDER only; major heavy-tail and site-influence limitation",
        "Exploratory conditional site contrast"
      )
    )
  ) |>
  ungroup() |>
  arrange(.data$predictor_order, .data$metric_slot)

if (nrow(joint_site_summary) != 6L) {
  stop("Expected six numerical conditional site-interaction summaries", call. = FALSE)
}

write_project_csv(
  joint_site_summary,
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_joint_site_interaction_summary.csv"
)

primary <- read_project_csv(
  inputs$relative_path[inputs$input_id == "accepted_primary_results"]
)
joint_stability <- read_project_csv(
  inputs$relative_path[inputs$input_id == "joint_stability"]
)
main_effects <- read_project_csv(
  inputs$relative_path[inputs$input_id == "main_h06_core_effects"]
)
main_tests <- read_project_csv(
  inputs$relative_path[inputs$input_id == "main_h06_wald_tests"]
)
main_site_screen <- read_project_csv(
  inputs$relative_path[inputs$input_id == "main_h06_site_screen"]
)

main_equal_site <- main_effects |>
  filter(
    .data$run_id == "main__glasses__all_available",
    .data$model_role == "additive",
    .data$distribution == "equal_site"
  ) |>
  select(
    predictor_id,
    hourly_estimate = estimate_ratio,
    hourly_lower_95 = conf_low_ratio,
    hourly_upper_95 = conf_high_ratio,
    hourly_raw_p = p_raw,
    hourly_bh_q = p_adjusted
  )

main_test_wide <- main_tests |>
  filter(.data$run_id == "main__glasses__all_available") |>
  transmute(
    predictor_id,
    test_type = recode(
      .data$test_role,
      additive_main_association = "association",
      site_heterogeneity = "site_heterogeneity"
    ),
    raw_p = .data$p_raw,
    bh_q = .data$p_adjusted
  ) |>
  pivot_wider(
    names_from = test_type,
    values_from = c(raw_p, bh_q),
    names_glue = "hourly_{test_type}_{.value}"
  )

main_interaction_effects <- main_site_screen |>
  group_by(.data$predictor_id) |>
  summarise(
    hourly_interaction_estimate = first(.data$interaction_equal_site_ratio),
    hourly_interaction_lower_95 =
      first(.data$interaction_equal_site_conf_low_ratio),
    hourly_interaction_upper_95 =
      first(.data$interaction_equal_site_conf_high_ratio),
    hourly_interaction_site_minimum = min(.data$estimate_ratio),
    hourly_interaction_site_maximum = max(.data$estimate_ratio),
    .groups = "drop"
  )

daily_mean <- primary |>
  filter(.data$metric_slot == 1L) |>
  select(
    predictor_order,
    predictor_id,
    predictor,
    daily_predictor_specific_estimate = estimate,
    daily_predictor_specific_lower_95 = lower_95,
    daily_predictor_specific_upper_95 = upper_95,
    daily_predictor_specific_raw_p = association_raw_p_value,
    daily_predictor_specific_bh_q = association_bh_adjusted_p_value,
    daily_predictor_specific_site_raw_p = site_heterogeneity_raw_p_value,
    daily_predictor_specific_site_bh_q = site_heterogeneity_bh_adjusted_p_value,
    daily_predictor_specific_days = participant_days,
    daily_predictor_specific_participants = participants,
    daily_predictor_specific_sites = sites
  )

joint_mean <- joint_stability |>
  filter(.data$metric_slot == 1L) |>
  select(
    predictor_id,
    daily_joint_estimate = display_estimate_mutually_adjusted_joint,
    daily_joint_lower_95 = display_lower_95_mutually_adjusted_joint,
    daily_joint_upper_95 = display_upper_95_mutually_adjusted_joint,
    daily_joint_raw_p = conditional_association_raw_p,
    daily_joint_bh_q = conditional_association_bh_q,
    daily_joint_site_raw_p = conditional_heterogeneity_raw_p,
    daily_joint_site_bh_q = conditional_heterogeneity_bh_q,
    covariate_shift_in_common_se,
    covariate_stability,
    daily_joint_days = common_participant_days,
    daily_joint_participants = common_participants,
    daily_joint_sites = common_sites
  )

daily_primary_interaction_effects <- site_summary |>
  filter(.data$metric_slot == 1L) |>
  select(
    predictor_id,
    daily_predictor_specific_interaction_estimate =
      equal_site_display_estimate,
    daily_predictor_specific_interaction_lower_95 =
      equal_site_display_lower_95,
    daily_predictor_specific_interaction_upper_95 =
      equal_site_display_upper_95,
    daily_predictor_specific_interaction_site_minimum =
      minimum_site_display_estimate,
    daily_predictor_specific_interaction_site_maximum =
      maximum_site_display_estimate
  )

daily_joint_interaction_effects <- joint_site_summary |>
  filter(.data$metric_slot == 1L) |>
  select(
    predictor_id,
    daily_joint_interaction_estimate = equal_site_display_estimate,
    daily_joint_interaction_lower_95 = equal_site_display_lower_95,
    daily_joint_interaction_upper_95 = equal_site_display_upper_95,
    daily_joint_interaction_site_minimum = minimum_site_display_estimate,
    daily_joint_interaction_site_maximum = maximum_site_display_estimate
  )

main_comparison <- daily_mean |>
  left_join(main_equal_site, by = "predictor_id", relationship = "one-to-one") |>
  left_join(main_test_wide, by = "predictor_id", relationship = "one-to-one") |>
  left_join(
    main_interaction_effects,
    by = "predictor_id",
    relationship = "one-to-one"
  ) |>
  left_join(joint_mean, by = "predictor_id", relationship = "one-to-one") |>
  left_join(
    daily_primary_interaction_effects,
    by = "predictor_id",
    relationship = "one-to-one"
  ) |>
  left_join(
    daily_joint_interaction_effects,
    by = "predictor_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    hourly_uses_interaction = .data$hourly_site_heterogeneity_bh_q < 0.05,
    hourly_selected_model = if_else(
      .data$hourly_uses_interaction,
      "interaction model; equal-site full contrast",
      "additive model; common contrast"
    ),
    hourly_selected_estimate = if_else(
      .data$hourly_uses_interaction,
      .data$hourly_interaction_estimate,
      .data$hourly_estimate
    ),
    hourly_selected_lower_95 = if_else(
      .data$hourly_uses_interaction,
      .data$hourly_interaction_lower_95,
      .data$hourly_lower_95
    ),
    hourly_selected_upper_95 = if_else(
      .data$hourly_uses_interaction,
      .data$hourly_interaction_upper_95,
      .data$hourly_upper_95
    ),
    daily_predictor_specific_uses_interaction =
      .data$daily_predictor_specific_site_bh_q < 0.05,
    daily_predictor_specific_selected_model = if_else(
      .data$daily_predictor_specific_uses_interaction,
      "interaction model; equal-site full contrast",
      "additive model; common contrast"
    ),
    daily_predictor_specific_selected_estimate = if_else(
      .data$daily_predictor_specific_uses_interaction,
      .data$daily_predictor_specific_interaction_estimate,
      .data$daily_predictor_specific_estimate
    ),
    daily_predictor_specific_selected_lower_95 = if_else(
      .data$daily_predictor_specific_uses_interaction,
      .data$daily_predictor_specific_interaction_lower_95,
      .data$daily_predictor_specific_lower_95
    ),
    daily_predictor_specific_selected_upper_95 = if_else(
      .data$daily_predictor_specific_uses_interaction,
      .data$daily_predictor_specific_interaction_upper_95,
      .data$daily_predictor_specific_upper_95
    ),
    daily_joint_uses_interaction = .data$daily_joint_site_bh_q < 0.05,
    daily_joint_selected_model = if_else(
      .data$daily_joint_uses_interaction,
      "interaction model; equal-site full contrast",
      "additive model; common contrast"
    ),
    daily_joint_selected_estimate = if_else(
      .data$daily_joint_uses_interaction,
      .data$daily_joint_interaction_estimate,
      .data$daily_joint_estimate
    ),
    daily_joint_selected_lower_95 = if_else(
      .data$daily_joint_uses_interaction,
      .data$daily_joint_interaction_lower_95,
      .data$daily_joint_lower_95
    ),
    daily_joint_selected_upper_95 = if_else(
      .data$daily_joint_uses_interaction,
      .data$daily_joint_interaction_upper_95,
      .data$daily_joint_upper_95
    )
  ) |>
  arrange(.data$predictor_order)

if (
  nrow(main_comparison) != 3L ||
    anyNA(main_comparison$hourly_selected_estimate) ||
    anyNA(main_comparison$daily_predictor_specific_selected_estimate) ||
    anyNA(main_comparison$daily_joint_selected_estimate)
) {
  stop("The selected main-hourly versus daily comparison is incomplete", call. = FALSE)
}

write_project_csv(
  main_comparison,
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_main_hourly_comparison.csv"
)

temporal_summary <- read_project_csv(
  inputs$relative_path[inputs$input_id == "temporal_context_summary"]
) |>
  filter(
    .data$data_scenario_id == "primary",
    .data$placement_id == "near_eye",
    .data$sample_scenario == "all_available"
  ) |>
  arrange(.data$estimand_order)
temporal_support <- read_project_csv(
  inputs$relative_path[inputs$input_id == "temporal_support"]
) |>
  filter(.data$run_id == "primary__near_eye__all_available")

if (nrow(temporal_summary) != 4L || nrow(temporal_support) != 1L) {
  stop("The accepted primary temporal summary is incomplete", call. = FALSE)
}

temporal_reader <- temporal_summary |>
  mutate(
    observations_30_minute = temporal_support$observations_30_minute[[1L]],
    participant_days = temporal_support$participant_days[[1L]],
    participants = temporal_support$participants[[1L]],
    sites = temporal_support$sites[[1L]],
    interval_scope = "pointwise 95% confidence intervals over 48 half-hour midpoints",
    inference_scope = paste0(
      "approximate whole-function test in the primary four-test BH family; ",
      .data$pointwise_bins_excluding_null,
      " of ",
      .data$evaluated_half_hour_midpoints,
      " pointwise intervals exclude 1"
    )
  )

write_project_csv(
  temporal_reader,
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_temporal_gamm_summary.csv"
)

message(
  "Built H06_daily Stage 3 revision inputs: ",
  nrow(site_estimates),
  " primary site contrasts, ",
  nrow(site_summary),
  " interaction summaries, ",
  nrow(main_comparison),
  " main-hourly comparison rows, and ",
  nrow(temporal_reader),
  " temporal GAMM summaries."
)
