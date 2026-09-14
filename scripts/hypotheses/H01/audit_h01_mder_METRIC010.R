# Audit the H01-only consequences of the METRIC-010 MDER amendment.
#
# This script reads the accepted 16-metric H01 results and the isolated MDER
# point refit. It does not modify accepted model or reporting artifacts. It
# reconstructs the complete 17-test multiplicity families in a review area,
# checks the revised MDER distribution and influence, and prepares the author
# gate required before any bootstrap pilot or production update.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h01_abort(
    "The H01 METRIC-010 audit requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

producer <- "scripts/hypotheses/H01/audit_h01_mder_METRIC010.R"
old_metric_id <- "mder_ratio_of_integrals"
new_metric_id <- "mder_mean_of_viable_ratios"
point_root <- normalizePath(
  Sys.getenv(
    "H01_MDER_POINT_ROOT",
    unset = file.path(
      root,
      paste0(
        "audit/hypotheses/H01/mder_METRIC-010/",
        "point_refit_repaired_gap"
      )
    )
  ),
  winslash = "/",
  mustWork = TRUE
)
review_root <- file.path(
  root,
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/",
    "author_gate_post_repair"
  )
)
dir.create(review_root, recursive = TRUE, showWarnings = FALSE)

read_csv_required <- function(path) {
  if (!file.exists(path)) {
    h01_abort("Missing H01 METRIC-010 audit input: %s", path)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

accepted_table_path <- function(name) {
  file.path(root, "artifacts/09_tables/H01", name)
}

accepted_diagnostic_path <- function(name) {
  file.path(root, "artifacts/08_diagnostics/H01", name)
}

point_table_path <- function(name) {
  file.path(point_root, "artifacts/09_tables/H01", name)
}

point_diagnostic_path <- function(name) {
  file.path(point_root, "artifacts/08_diagnostics/H01", name)
}

write_review_csv <- function(data, name) {
  path <- file.path(review_root, name)
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

input_contract <- h01_input_contract(root)
stopifnot(
  identical(
    artifact_sha256(input_contract$main$manifest),
    input_contract$main$manifest_sha256
  ),
  identical(
    artifact_sha256(input_contract$manuscript_prepared_data$manifest),
    input_contract$manuscript_prepared_data$manifest_sha256
  )
)

metric_registry <- h01_metric_registry()
h01_validate_registry(metric_registry)
stopifnot(
  metric_registry$metric_id[metric_registry$metric_order == 17L] ==
    new_metric_id
)
run_registry <- h01_run_registry()

accepted_names <- c(
  tests = "H01_model_level_tests.csv",
  term_effects = "H01_term_effects.csv",
  site_estimates = "H01_site_estimates.csv",
  site_deviations = "H01_site_deviations.csv",
  marginalization = "H01_marginalization_comparison.csv",
  samples = "H01_exact_samples.csv",
  samples_by_site = "H01_exact_samples_by_site.csv",
  latitude_loo = "H01_latitude_leave_one_site_out.csv",
  random_site = "H01_random_site_descriptions.csv",
  r2_point = "H01_r2_point_summaries.csv",
  model_manifest = "H01_model_manifest.csv",
  preregistered_scope = "H01_preregistered_scope_sensitivity.csv"
)
accepted <- lapply(accepted_names, function(name) {
  if (name %in% c("H01_latitude_leave_one_site_out.csv")) {
    read_csv_required(accepted_diagnostic_path(name))
  } else {
    read_csv_required(accepted_table_path(name))
  }
})
accepted$diagnostics <- read_csv_required(
  accepted_diagnostic_path("H01_model_diagnostics.csv")
)
accepted$influence <- read_csv_required(
  accepted_diagnostic_path("H01_participant_influence.csv")
)

point <- lapply(accepted_names, function(name) {
  if (name %in% c("H01_latitude_leave_one_site_out.csv")) {
    read_csv_required(point_diagnostic_path(name))
  } else {
    read_csv_required(point_table_path(name))
  }
})
point$diagnostics <- read_csv_required(
  point_diagnostic_path("H01_model_diagnostics.csv")
)
point$influence <- read_csv_required(
  point_diagnostic_path("H01_participant_influence.csv")
)

for (name in names(point)) {
  data <- point[[name]]
  if (nrow(data) > 0L && "metric_id" %in% names(data)) {
    if (!all(data$metric_id == new_metric_id)) {
      h01_abort("The isolated point output `%s` contains another metric", name)
    }
  }
}
stopifnot(
  nrow(point$samples) == 8L,
  nrow(point$tests) == 32L,
  nrow(point$diagnostics) == 8L,
  all(point$samples$sample_status == "FITTED")
)

replace_metric_rows <- function(accepted_data, point_data) {
  accepted_data <- accepted_data[
    accepted_data$metric_id != old_metric_id,
    ,
    drop = FALSE
  ]
  dplyr::bind_rows(accepted_data, point_data)
}

primary_derived_columns <- c(
  "family_instance_id",
  "p_adjusted",
  "family_rank",
  "family_observed_tests",
  "family_status"
)
raw_accepted_tests <- accepted$tests |>
  dplyr::select(-dplyr::any_of(primary_derived_columns))
raw_point_tests <- point$tests |>
  dplyr::select(-dplyr::any_of(primary_derived_columns))
provisional_tests <- replace_metric_rows(
  raw_accepted_tests,
  raw_point_tests
) |>
  dplyr::mutate(
    family_instance_id = paste(.data$run_id, .data$family_id, sep = "::")
  )
provisional_tests <- adjust_result_families(
  provisional_tests,
  family_col = "family_instance_id",
  p_col = "p_raw",
  family_n_col = "family_n",
  output_col = "p_adjusted",
  method = "BH"
) |>
  dplyr::group_by(.data$family_instance_id) |>
  dplyr::mutate(
    family_rank = ifelse(
      is.na(.data$p_raw),
      NA_integer_,
      rank(.data$p_raw, ties.method = "min", na.last = "keep")
    ),
    family_observed_tests = sum(!is.na(.data$p_raw))
  ) |>
  dplyr::ungroup()

provisional_diagnostics <- replace_metric_rows(
  accepted$diagnostics,
  point$diagnostics
)
gated_runs <- unique(provisional_diagnostics$run_id[
  provisional_diagnostics$diagnostic_status == "FAIL_MAJOR_GATE"
])
provisional_tests <- provisional_tests |>
  dplyr::mutate(
    family_status = ifelse(
      .data$run_id %in% gated_runs,
      "INVALID_OPEN_MAJOR_GATE",
      "COMPLETE"
    ),
    p_adjusted = ifelse(
      .data$run_id %in% gated_runs,
      NA_real_,
      .data$p_adjusted
    )
  ) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$family_order
  )

provisional <- list(
  tests = provisional_tests,
  term_effects = replace_metric_rows(
    accepted$term_effects,
    point$term_effects
  ),
  site_estimates = replace_metric_rows(
    accepted$site_estimates,
    point$site_estimates
  ),
  marginalization = replace_metric_rows(
    accepted$marginalization,
    point$marginalization
  ),
  samples = replace_metric_rows(accepted$samples, point$samples),
  samples_by_site = replace_metric_rows(
    accepted$samples_by_site,
    point$samples_by_site
  ),
  diagnostics = provisional_diagnostics,
  influence = replace_metric_rows(accepted$influence, point$influence),
  latitude_loo = replace_metric_rows(
    accepted$latitude_loo,
    point$latitude_loo
  ),
  random_site = replace_metric_rows(
    accepted$random_site,
    point$random_site
  ),
  r2_point = replace_metric_rows(accepted$r2_point, point$r2_point),
  model_manifest = replace_metric_rows(
    accepted$model_manifest,
    point$model_manifest
  )
)

site_support <- provisional$tests |>
  dplyr::filter(.data$family_id == "H01-F1-site") |>
  dplyr::select(
    "run_id",
    "metric_id",
    overall_site_p_adjusted = "p_adjusted"
  )
provisional$site_deviations <- dplyr::bind_rows(
  accepted$site_deviations |>
    dplyr::filter(.data$metric_id != old_metric_id) |>
    dplyr::select(
      -dplyr::any_of(c(
        "overall_site_p_adjusted",
        "inferential_followup_supported"
      ))
    ),
  point$site_deviations |>
    dplyr::select(
      -dplyr::any_of(c(
        "overall_site_p_adjusted",
        "inferential_followup_supported"
      ))
    )
) |>
  dplyr::left_join(
    site_support,
    by = c("run_id", "metric_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    inferential_followup_supported =
      !is.na(.data$overall_site_p_adjusted) &
      .data$overall_site_p_adjusted < 0.05
  )

scope_derived_columns <- c(
  "family_order",
  "family_id",
  "family_label",
  "adjustment_method",
  "family_n",
  "family_instance_id",
  "p_adjusted",
  "family_status"
)
provisional_scope <- replace_metric_rows(
  accepted$preregistered_scope |>
    dplyr::select(-dplyr::any_of(scope_derived_columns)),
  point$preregistered_scope |>
    dplyr::select(-dplyr::any_of(scope_derived_columns))
) |>
  dplyr::mutate(
    family_id = dplyr::case_when(
      .data$comparison_id == "site_full_vs_no_site" ~
        "H01-S1-registered-site",
      .data$comparison_id == "latitude_full_vs_no_latitude" ~
        "H01-S2-registered-latitude",
      .data$comparison_id == "site_full_vs_latitude_full" ~
        "H01-S3-registered-adequacy",
      .data$comparison_id == "site_full_vs_no_photoperiod" ~
        "H01-S4-registered-photoperiod",
      TRUE ~ NA_character_
    ),
    family_n = ifelse(
      .data$family_id == "H01-S4-registered-photoperiod",
      5L,
      17L
    ),
    family_instance_id = paste(.data$run_id, .data$family_id, sep = "::")
  ) |>
  dplyr::filter(!is.na(.data$family_id))
provisional_scope <- adjust_result_families(
  provisional_scope,
  family_col = "family_instance_id",
  p_col = "p_raw",
  family_n_col = "family_n",
  output_col = "p_adjusted",
  method = "BH"
) |>
  dplyr::mutate(
    family_status = ifelse(
      .data$run_id %in% gated_runs,
      "INVALID_OPEN_MAJOR_GATE",
      "COMPLETE"
    ),
    p_adjusted = ifelse(
      .data$run_id %in% gated_runs,
      NA_real_,
      .data$p_adjusted
    )
  )
provisional$preregistered_scope <- provisional_scope

provisional_names <- c(
  tests = "H01_METRIC-010_provisional_model_level_tests.csv",
  term_effects = "H01_METRIC-010_provisional_term_effects.csv",
  site_estimates = "H01_METRIC-010_provisional_site_estimates.csv",
  site_deviations = "H01_METRIC-010_provisional_site_deviations.csv",
  marginalization = "H01_METRIC-010_provisional_marginalization.csv",
  samples = "H01_METRIC-010_provisional_exact_samples.csv",
  samples_by_site = "H01_METRIC-010_provisional_exact_samples_by_site.csv",
  diagnostics = "H01_METRIC-010_provisional_model_diagnostics.csv",
  influence = "H01_METRIC-010_provisional_participant_influence.csv",
  latitude_loo = "H01_METRIC-010_provisional_latitude_loo.csv",
  random_site = "H01_METRIC-010_provisional_random_site.csv",
  r2_point = "H01_METRIC-010_provisional_r2_point.csv",
  model_manifest = "H01_METRIC-010_provisional_model_manifest.csv",
  preregistered_scope =
    "H01_METRIC-010_provisional_preregistered_scope.csv"
)
invisible(mapply(
  function(name, path) write_review_csv(provisional[[name]], path),
  names(provisional_names),
  unname(provisional_names),
  SIMPLIFY = FALSE,
  USE.NAMES = FALSE
))

paired_samples <- provisional$samples |>
  dplyr::filter(
    .data$metric_id == new_metric_id,
    .data$sample_scenario == "paired_common_sample"
  ) |>
  dplyr::select(
    "data_scenario_id",
    "placement",
    "participants",
    "participant_days",
    "observations",
    "sites"
  )
paired_support <- provisional$tests |>
  dplyr::filter(
    .data$metric_id == new_metric_id,
    .data$sample_scenario == "paired_common_sample",
    .data$family_id %in% c("H01-F2-photoperiod", "H01-F3-latitude")
  ) |>
  dplyr::transmute(
    .data$data_scenario_id,
    .data$placement,
    term = dplyr::if_else(
      .data$family_id == "H01-F2-photoperiod",
      "photoperiod_centered_hours",
      "absolute_latitude_10deg_centered"
    ),
    model_p_raw = .data$p_raw,
    model_p_adjusted = .data$p_adjusted,
    model_supported = is.finite(.data$p_adjusted) & .data$p_adjusted < 0.05
  )
paired_effects <- provisional$term_effects |>
  dplyr::filter(
    .data$metric_id == new_metric_id,
    .data$sample_scenario == "paired_common_sample",
    .data$term %in% c(
      "photoperiod_centered_hours",
      "absolute_latitude_10deg_centered"
    )
  ) |>
  dplyr::select(
    "data_scenario_id",
    "placement",
    "term",
    estimate = "estimate_practical",
    conf_low = "conf_low_practical",
    conf_high = "conf_high_practical",
    term_p_raw = "p_raw"
  ) |>
  dplyr::left_join(
    paired_support,
    by = c("data_scenario_id", "placement", "term"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    paired_samples,
    by = c("data_scenario_id", "placement"),
    relationship = "many-to-one"
  )
paired_near <- paired_effects |>
  dplyr::filter(.data$placement == "glasses") |>
  dplyr::select(-"placement") |>
  dplyr::rename_with(
    ~ paste0("near_", .x),
    -dplyr::all_of(c("data_scenario_id", "term"))
  )
paired_chest <- paired_effects |>
  dplyr::filter(.data$placement == "chest") |>
  dplyr::select(-"placement") |>
  dplyr::rename_with(
    ~ paste0("chest_", .x),
    -dplyr::all_of(c("data_scenario_id", "term"))
  )
paired_placement <- dplyr::inner_join(
  paired_near,
  paired_chest,
  by = c("data_scenario_id", "term"),
  relationship = "one-to-one"
) |>
  dplyr::mutate(
    data_scenario_label = dplyr::recode(
      .data$data_scenario_id,
      main = "Primary dataset",
      manuscript_prepared_data = "Gap-timing-unaware dataset"
    ),
    effect_label = dplyr::recode(
      .data$term,
      photoperiod_centered_hours = "Photoperiod per hour",
      absolute_latitude_10deg_centered =
        "Absolute latitude per 10 degrees"
    ),
    point_difference_chest_minus_near =
      .data$chest_estimate - .data$near_estimate,
    same_side_of_null = sign(.data$near_estimate) == sign(.data$chest_estimate),
    support_switch =
      .data$near_model_supported != .data$chest_model_supported,
    sample_exactly_matched =
      .data$near_participants == .data$chest_participants &
      .data$near_participant_days == .data$chest_participant_days &
      .data$near_observations == .data$chest_observations &
      .data$near_sites == .data$chest_sites
  ) |>
  dplyr::arrange(.data$term, .data$data_scenario_id)
stopifnot(
  nrow(paired_placement) == 4L,
  all(paired_placement$sample_exactly_matched),
  all(paired_placement$near_participant_days ==
    paired_placement$near_observations)
)
write_review_csv(
  paired_placement,
  "H01_METRIC-010_paired_placement_point_comparison.csv"
)

if (requireNamespace("ggplot2", quietly = TRUE)) {
  paired_limit <- max(abs(c(
    paired_placement$near_conf_low,
    paired_placement$near_conf_high,
    paired_placement$chest_conf_low,
    paired_placement$chest_conf_high,
    0
  ))) * 1.15
  paired_plot <- ggplot2::ggplot(
    paired_placement,
    ggplot2::aes(
      x = .data$near_estimate,
      y = .data$chest_estimate,
      colour = .data$data_scenario_label,
      shape = .data$data_scenario_label
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dotted", colour = "grey45") +
    ggplot2::geom_vline(xintercept = 0, linetype = "dotted", colour = "grey45") +
    ggplot2::geom_abline(
      intercept = 0,
      slope = 1,
      linetype = "dashed",
      colour = "grey30"
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = .data$near_conf_low,
        xend = .data$near_conf_high,
        yend = .data$chest_estimate
      ),
      linewidth = 0.55
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(
        xend = .data$near_estimate,
        y = .data$chest_conf_low,
        yend = .data$chest_conf_high
      ),
      linewidth = 0.55
    ) +
    ggplot2::geom_point(size = 3.4, stroke = 1.1) +
    ggplot2::facet_wrap(~effect_label, nrow = 1L) +
    ggplot2::coord_equal(
      xlim = c(-paired_limit, paired_limit),
      ylim = c(-paired_limit, paired_limit),
      expand = FALSE
    ) +
    ggplot2::scale_colour_manual(
      values = c(
        "Primary dataset" = "#000000",
        "Gap-timing-unaware dataset" = "#0072B2"
      )
    ) +
    ggplot2::scale_shape_manual(
      values = c(
        "Primary dataset" = 21,
        "Gap-timing-unaware dataset" = 16
      )
    ) +
    ggplot2::scale_x_continuous(
      breaks = c(-0.04, 0, 0.04),
      labels = c("-0.04", "0", "0.04")
    ) +
    ggplot2::scale_y_continuous(
      breaks = c(-0.04, 0, 0.04),
      labels = c("-0.04", "0", "0.04")
    ) +
    ggplot2::labs(
      x = "Near-eye estimate",
      y = "Chest estimate",
      colour = NULL,
      shape = NULL,
      title = "MDER placement comparison in exact paired/common samples",
      subtitle = "Bars show component 95% confidence intervals; dashed line shows identity"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank(),
      panel.spacing.x = grid::unit(1.2, "cm"),
      strip.text = ggplot2::element_text(face = "bold")
    )
  ggplot2::ggsave(
    file.path(
      review_root,
      "H01_METRIC-010_paired_placement_point_comparison.png"
    ),
    plot = paired_plot,
    width = 8.6,
    height = 5.7,
    units = "in",
    dpi = 300,
    bg = "white"
  )
}

old_test_rows <- accepted$tests |>
  dplyr::transmute(
    .data$run_id,
    .data$family_id,
    .data$metric_order,
    old_metric_id = .data$metric_id,
    old_p_raw = .data$p_raw,
    old_p_adjusted = .data$p_adjusted,
    old_supported = !is.na(.data$p_adjusted) & .data$p_adjusted < 0.05
  )
new_test_rows <- provisional$tests |>
  dplyr::transmute(
    .data$run_id,
    .data$family_id,
    .data$metric_order,
    new_metric_id = .data$metric_id,
    new_p_raw = .data$p_raw,
    new_p_adjusted = .data$p_adjusted,
    new_supported = !is.na(.data$p_adjusted) & .data$p_adjusted < 0.05
  )
support_impact <- dplyr::left_join(
  old_test_rows,
  new_test_rows,
  by = c("run_id", "family_id", "metric_order"),
  relationship = "one-to-one"
) |>
  dplyr::mutate(
    p_adjusted_change = .data$new_p_adjusted - .data$old_p_adjusted,
    support_changed = .data$old_supported != .data$new_supported,
    raw_p_unchanged_for_non_mder = dplyr::if_else(
      .data$metric_order != 17L,
      dplyr::near(.data$old_p_raw, .data$new_p_raw, tol = 1e-14),
      NA
    )
  )
if (!all(
  support_impact$raw_p_unchanged_for_non_mder[
    support_impact$metric_order != 17L
  ],
  na.rm = TRUE
)) {
  h01_abort("A non-MDER raw model-level p-value changed")
}
write_review_csv(
  support_impact,
  "H01_METRIC-010_complete_BH_impact.csv"
)

mder_test_comparison <- support_impact |>
  dplyr::filter(.data$metric_order == 17L)
write_review_csv(
  mder_test_comparison,
  "H01_METRIC-010_mder_test_comparison.csv"
)

compare_metric_rows <- function(old_data, new_data, by) {
  old_data |>
    dplyr::filter(.data$metric_id == old_metric_id) |>
    dplyr::rename_with(
      ~paste0("old_", .x),
      -dplyr::all_of(by)
    ) |>
    dplyr::full_join(
      new_data |>
        dplyr::filter(.data$metric_id == new_metric_id) |>
        dplyr::rename_with(
          ~paste0("new_", .x),
          -dplyr::all_of(by)
        ),
      by = by,
      relationship = "one-to-one"
    )
}

sample_comparison <- compare_metric_rows(
  accepted$samples,
  provisional$samples,
  by = "run_id"
)
write_review_csv(
  sample_comparison,
  "H01_METRIC-010_exact_sample_comparison.csv"
)

effect_comparison <- compare_metric_rows(
  accepted$term_effects,
  provisional$term_effects,
  by = c("run_id", "term")
)
write_review_csv(
  effect_comparison,
  "H01_METRIC-010_term_effect_comparison.csv"
)

diagnostic_comparison <- compare_metric_rows(
  accepted$diagnostics,
  provisional$diagnostics,
  by = "run_id"
)
write_review_csv(
  diagnostic_comparison,
  "H01_METRIC-010_diagnostic_comparison.csv"
)

r2_point_comparison <- compare_metric_rows(
  accepted$r2_point,
  provisional$r2_point,
  by = c("run_id", "approximation")
)
write_review_csv(
  r2_point_comparison,
  "H01_METRIC-010_r2_point_comparison.csv"
)

model_frames <- list()
frame_index <- 1L
for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  path <- file.path(
    point_root,
    "artifacts/07_models/H01",
    run$data_scenario_id,
    run$placement,
    run$sample_scenario,
    paste0(new_metric_id, "_model_frame.rds")
  )
  frame <- readRDS(path)
  frame$run_id <- run$run_id
  frame$data_scenario_id <- run$data_scenario_id
  frame$placement <- run$placement
  frame$sample_scenario <- run$sample_scenario
  model_frames[[frame_index]] <- frame
  frame_index <- frame_index + 1L
}
model_frame_rows <- dplyr::bind_rows(model_frames)

common_day_source <- model_frame_rows |>
  dplyr::filter(.data$sample_scenario == "all_available") |>
  dplyr::transmute(
    .data$data_scenario_id,
    .data$placement,
    participant_key = as.character(.data$participant_key),
    local_date = as.character(.data$local_date),
    .data$value
  )
common_day_primary <- common_day_source |>
  dplyr::filter(.data$data_scenario_id == "main") |>
  dplyr::select(
    -"data_scenario_id",
    primary_value = "value"
  )
common_day_gap <- common_day_source |>
  dplyr::filter(.data$data_scenario_id == "manuscript_prepared_data") |>
  dplyr::select(
    -"data_scenario_id",
    gap_timing_unaware_value = "value"
  )
common_day_comparison <- dplyr::inner_join(
  common_day_primary,
  common_day_gap,
  by = c("placement", "participant_key", "local_date"),
  relationship = "one-to-one"
) |>
  dplyr::group_by(.data$placement) |>
  dplyr::summarise(
    common_participant_days = dplyr::n(),
    common_participants = dplyr::n_distinct(.data$participant_key),
    primary_mean = mean(.data$primary_value),
    gap_timing_unaware_mean = mean(.data$gap_timing_unaware_value),
    mean_paired_difference_gap_minus_primary = mean(
      .data$gap_timing_unaware_value - .data$primary_value
    ),
    maximum_absolute_paired_difference = max(abs(
      .data$gap_timing_unaware_value - .data$primary_value
    )),
    pearson_correlation = stats::cor(
      .data$primary_value,
      .data$gap_timing_unaware_value
    ),
    .groups = "drop"
  ) |>
  dplyr::arrange(match(.data$placement, c("glasses", "chest")))
stopifnot(
  identical(common_day_comparison$common_participant_days, c(687L, 723L)),
  all(abs(
    common_day_comparison$mean_paired_difference_gap_minus_primary
  ) < 0.0001)
)
write_review_csv(
  common_day_comparison,
  "H01_METRIC-010_gap_primary_common_day_comparison.csv"
)

skewness <- function(value) {
  centered <- value - mean(value)
  mean(centered^3) / stats::sd(value)^3
}

distribution <- model_frame_rows |>
  dplyr::group_by(
    .data$run_id,
    .data$data_scenario_id,
    .data$placement,
    .data$sample_scenario
  ) |>
  dplyr::summarise(
    participants = dplyr::n_distinct(.data$participant_key),
    participant_days = dplyr::n(),
    sites = dplyr::n_distinct(.data$site),
    minimum = min(.data$value),
    q01 = stats::quantile(.data$value, 0.01, names = FALSE),
    q05 = stats::quantile(.data$value, 0.05, names = FALSE),
    q25 = stats::quantile(.data$value, 0.25, names = FALSE),
    median = stats::median(.data$value),
    mean = mean(.data$value),
    q75 = stats::quantile(.data$value, 0.75, names = FALSE),
    q95 = stats::quantile(.data$value, 0.95, names = FALSE),
    q99 = stats::quantile(.data$value, 0.99, names = FALSE),
    maximum = max(.data$value),
    standard_deviation = stats::sd(.data$value),
    skewness = skewness(.data$value),
    exact_zero_n = sum(.data$value == 0),
    below_0_1_n = sum(.data$value < 0.1),
    above_1_n = sum(.data$value > 1),
    above_1_5_n = sum(.data$value > 1.5),
    above_2_n = sum(.data$value > 2),
    viable_minutes = if (
      all(is.na(.data$metric_support_valid_minutes))
    ) {
      NA_real_
    } else {
      sum(.data$metric_support_valid_minutes, na.rm = TRUE)
    },
    support_hours = .data$viable_minutes / 60,
    .groups = "drop"
  )
write_review_csv(
  distribution,
  "H01_METRIC-010_distribution_summary.csv"
)

extreme_rows <- model_frame_rows |>
  dplyr::group_by(.data$run_id) |>
  dplyr::slice_max(.data$value, n = 5L, with_ties = FALSE) |>
  dplyr::ungroup() |>
  dplyr::select(
    "run_id",
    "data_scenario_id",
    "placement",
    "sample_scenario",
    "site",
    "participant_key",
    "local_date",
    "value",
    "metric_support_valid_minutes",
    "metric_support_expected_minutes",
    ".model_row_id"
  )
write_review_csv(
  extreme_rows,
  "H01_METRIC-010_upper_tail_rows.csv"
)

construct_impossible_rows <- model_frame_rows |>
  dplyr::filter(
    .data$data_scenario_id == "manuscript_prepared_data",
    is.finite(.data$value),
    .data$value <= 0
  ) |>
  dplyr::distinct(
    .data$run_id,
    .data$placement,
    .data$sample_scenario,
    .data$site,
    .data$participant_key,
    .data$local_date,
    .data$value,
    .keep_all = TRUE
  ) |>
  dplyr::transmute(
    .data$run_id,
    .data$placement,
    .data$sample_scenario,
    .data$site,
    participant_key = as.character(.data$participant_key),
    .data$local_date,
    .data$value,
    expected_status = "missing_under_strict_positive_METRIC-010",
    observed_status = "retained_as_finite_MDER"
  )
write_review_csv(
  construct_impossible_rows,
  "H01_METRIC-010_construct_impossible_gap_rows.csv"
)

if (requireNamespace("ggplot2", quietly = TRUE)) {
  plot_rows <- model_frame_rows |>
    dplyr::mutate(
      scenario_label = dplyr::if_else(
        .data$data_scenario_id == "main",
        "Primary dataset",
        "Gap-timing-unaware dataset"
      ),
      placement_label = dplyr::recode(
        .data$placement,
        glasses = "near eye",
        chest = "chest"
      ),
      sample_label = dplyr::recode(
        .data$sample_scenario,
        all_available = "all available",
        paired_common_sample = "paired/common"
      ),
      panel_label = paste(
        .data$scenario_label,
        .data$placement_label,
        .data$sample_label,
        sep = " — "
      )
    )
  distribution_plot <- ggplot2::ggplot(
    plot_rows,
    ggplot2::aes(x = .data$value)
  ) +
    ggplot2::geom_histogram(
      bins = 35,
      boundary = 0,
      colour = "white",
      fill = "#0072B2",
      linewidth = 0.2
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$panel_label),
      ncol = 2,
      scales = "free_y"
    ) +
    ggplot2::labs(
      x = "Daily MDER (mean of viable one-minute ratios)",
      y = "Participant-days",
      title = "H01 METRIC-010 MDER distributions",
      subtitle = "Point-refit model frames; no bootstrap inference"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(size = 10),
      plot.title.position = "plot"
    )
  ggplot2::ggsave(
    filename = file.path(
      review_root,
      "H01_METRIC-010_distribution_histograms.png"
    ),
    plot = distribution_plot,
    width = 11,
    height = 10,
    dpi = 180
  )
}

point_influence <- point$influence |>
  dplyr::arrange(.data$run_id, dplyr::desc(.data$maximum_absolute_dfbeta))
write_review_csv(
  point_influence,
  "H01_METRIC-010_candidate_participant_influence.csv"
)

full_bh_for_metric <- function(run_id, raw_tests) {
  dplyr::bind_rows(lapply(seq_len(nrow(raw_tests)), function(index) {
    comparison <- raw_tests$comparison_id[[index]]
    family <- h01_family_registry() |>
      dplyr::filter(.data$comparison == .env$comparison)
    non_mder <- accepted$tests |>
      dplyr::filter(
        .data$run_id == .env$run_id,
        .data$family_id == family$family_id,
        .data$metric_order != 17L
      ) |>
      dplyr::pull(.data$p_raw)
    p_vector <- c(non_mder, raw_tests$p_raw[[index]])
    adjusted <- stats::p.adjust(
      p_vector,
      method = "BH",
      n = family$family_n
    )
    tibble::tibble(
      comparison_id = comparison,
      family_id = family$family_id,
      p_raw = raw_tests$p_raw[[index]],
      p_adjusted_complete_17 = adjusted[[length(adjusted)]]
    )
  }))
}

fit_influence_scenario <- function(
  run,
  frame,
  bundle,
  subset,
  sensitivity_id,
  omitted_participant = NA_character_,
  omitted_model_row_id = NA_character_
) {
  subset$participant_key <- droplevels(subset$participant_key)
  subset$site <- droplevels(subset$site)
  sensitivity_bundle <- h01_fit_metric_models(
    subset,
    bundle$spec,
    formulas = bundle$formulas
  )
  tests <- h01_model_tests(sensitivity_bundle)
  adjusted <- full_bh_for_metric(run$run_id, tests)
  site_model <- h01_unwrap_model(
    sensitivity_bundle,
    "final",
    "site_full"
  )
  latitude_model <- h01_unwrap_model(
    sensitivity_bundle,
    "final",
    "latitude_full"
  )
  effects <- dplyr::bind_rows(
    h01_extract_term_effect(
      site_model,
      "photoperiod_centered_hours",
      "Photoperiod per hour",
      bundle$spec
    ),
    h01_extract_term_effect(
      latitude_model,
      "absolute_latitude_10deg_centered",
      "Absolute latitude per 10 degrees",
      bundle$spec
    )
  ) |>
    dplyr::select(
      "term",
      "estimate_practical",
      "conf_low_practical",
      "conf_high_practical",
      term_p_raw = "p_raw"
    ) |>
    tidyr::pivot_wider(
      names_from = "term",
      values_from = c(
        "estimate_practical",
        "conf_low_practical",
        "conf_high_practical",
        "term_p_raw"
      )
    )
  diagnostic <- h01_model_diagnostics(
    sensitivity_bundle,
    subset,
    h01_primary_seed(
      17L,
      run$data_scenario_id,
      run$placement,
      run$sample_scenario
    ) + 700000L
  )
  dplyr::bind_cols(
    tibble::tibble(
      run_id = run$run_id,
      sensitivity_id = sensitivity_id,
      omitted_participant = omitted_participant,
      omitted_model_row_id = omitted_model_row_id,
      participants = dplyr::n_distinct(subset$participant_key),
      participant_days = nrow(subset),
      diagnostic_status = diagnostic$diagnostic_status,
      residual_status = diagnostic$residual_status
    ),
    adjusted |>
      dplyr::select(
        "family_id",
        "p_raw",
        "p_adjusted_complete_17"
      ) |>
      tidyr::pivot_wider(
        names_from = "family_id",
        values_from = c("p_raw", "p_adjusted_complete_17")
      ),
    effects
  )
}

influence_sensitivities <- list()
influence_index <- 1L
for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  frame <- model_frames[[run_index]]
  bundle_path <- file.path(
    point_root,
    "artifacts/07_models/H01",
    run$data_scenario_id,
    run$placement,
    run$sample_scenario,
    paste0(new_metric_id, "_models.rds")
  )
  bundle <- readRDS(bundle_path)
  candidate <- point_influence |>
    dplyr::filter(.data$run_id == run$run_id) |>
    dplyr::slice_max(
      .data$maximum_absolute_dfbeta,
      n = 1L,
      with_ties = FALSE
    ) |>
    dplyr::pull(.data$omitted_participant)
  participant_subset <- frame[
    as.character(frame$participant_key) != candidate,
    ,
    drop = FALSE
  ]
  influence_sensitivities[[influence_index]] <-
    fit_influence_scenario(
      run,
      frame,
      bundle,
      participant_subset,
      sensitivity_id = "omit_highest_dfbeta_participant",
      omitted_participant = candidate
    )
  influence_index <- influence_index + 1L

  maximum_index <- which.max(frame$value)
  maximum_row_id <- frame$.model_row_id[[maximum_index]]
  day_subset <- frame[-maximum_index, , drop = FALSE]
  influence_sensitivities[[influence_index]] <-
    fit_influence_scenario(
      run,
      frame,
      bundle,
      day_subset,
      sensitivity_id = "omit_maximum_mder_participant_day",
      omitted_participant = as.character(
        frame$participant_key[[maximum_index]]
      ),
      omitted_model_row_id = maximum_row_id
    )
  influence_index <- influence_index + 1L
}
influence_sensitivity <- dplyr::bind_rows(influence_sensitivities)
write_review_csv(
  influence_sensitivity,
  "H01_METRIC-010_influence_sensitivity.csv"
)

non_mder_ids <- metric_registry$metric_id[metric_registry$metric_order < 17L]
artifact_roots <- file.path(
  root,
  c(
    "artifacts/07_models/H01",
    "artifacts/08_diagnostics/H01",
    "artifacts/11_source_data/H01"
  )
)
all_artifacts <- sort(unique(unlist(lapply(
  artifact_roots,
  list.files,
  recursive = TRUE,
  full.names = TRUE
))))
all_artifacts <- all_artifacts[
  file.exists(all_artifacts) & !dir.exists(all_artifacts)
]
is_non_mder_artifact <- vapply(
  basename(all_artifacts),
  function(name) {
    any(vapply(
      non_mder_ids,
      function(metric_id) grepl(metric_id, name, fixed = TRUE),
      logical(1)
    ))
  },
  logical(1)
)
non_mder_artifacts <- all_artifacts[is_non_mder_artifact]
non_mder_manifest <- dplyr::bind_rows(lapply(
  non_mder_artifacts,
  function(path) {
    info <- file.info(path)
    tibble::tibble(
      path = substring(path, nchar(root) + 2L),
      sha256 = artifact_sha256(path),
      bytes = as.numeric(info$size)
    )
  }
))
write_review_csv(
  non_mder_manifest,
  "H01_METRIC-010_frozen_non_mder_artifact_baseline.csv"
)

primary_run <- "main__glasses__all_available"
primary_mder_changes <- support_impact |>
  dplyr::filter(
    .data$run_id == primary_run,
    .data$metric_order == 17L,
    .data$support_changed
  )
primary_non_mder_changes <- support_impact |>
  dplyr::filter(
    .data$run_id == primary_run,
    .data$metric_order != 17L,
    .data$support_changed
  )
gate_summary <- tibble::tibble(
  decision_id = "METRIC-010",
  metric_id = new_metric_id,
  isolated_point_runs = nrow(point$samples),
  point_runs_with_major_diagnostic_failure = length(gated_runs),
  primary_mder_family_support_changes = nrow(primary_mder_changes),
  primary_non_mder_family_support_changes = nrow(primary_non_mder_changes),
  any_primary_support_change =
    nrow(primary_mder_changes) + nrow(primary_non_mder_changes) > 0L,
  construct_impossible_gap_fit_rows = nrow(construct_impossible_rows),
  construct_impossible_gap_physical_days = dplyr::n_distinct(paste(
    construct_impossible_rows$placement,
    construct_impossible_rows$participant_key,
    construct_impossible_rows$local_date,
    sep = "::"
  )),
  bootstrap_intervals_required_for_final_reporting = TRUE,
  bootstrap_pilot_launched = FALSE,
  shared_change_request_status = "RESOLVED_BY_COORDINATOR_REPAIR",
  gate_status = "STOP_AUTHOR_GATE_MATERIAL_INFERENCE_CHANGE"
)
write_review_csv(
  gate_summary,
  "H01_METRIC-010_gate_summary.csv"
)

review_files <- sort(list.files(
  review_root,
  recursive = TRUE,
  full.names = TRUE
))
review_files <- review_files[
  file.exists(review_files) &
    !dir.exists(review_files) &
    basename(review_files) != "H01_METRIC-010_author_gate_manifest.csv"
]
provenance_files <- c(
  file.path(root, producer),
  file.path(root, "scripts/hypotheses/H01/h01_contract.R"),
  file.path(root, "scripts/hypotheses/H01/h01_modeling.R"),
  file.path(root, "scripts/hypotheses/H01/run_h01_models.R"),
  file.path(root, "scripts/hypotheses/H01/build_h01_reporting_inputs.R"),
  file.path(root, "tests/hypotheses/H01/test_h01_contract.R"),
  file.path(
    root,
    "tests/hypotheses/H01/test_h01_mder_METRIC010_gate.R"
  ),
  file.path(root, "audit/decisions/mder_mean_of_viable_ratios.md"),
  file.path(root, "audit/decisions/bootstrap_execution_policy.md"),
  file.path(
    root,
    paste0(
      "audit/hypotheses/H01/mder_METRIC-010/",
      "H01_METRIC-010_author_gate.md"
    )
  ),
  file.path(root, "audit/handoffs/H01_shared_change_request.md"),
  file.path(root, "audit/handoffs/H01_worker_handoff.md"),
  input_contract$main$manifest,
  input_contract$manuscript_prepared_data$manifest,
  file.path(
    point_root,
    "artifacts/12_manifests/H01_model_results_artifacts.csv"
  )
)
manifest_files <- sort(unique(c(review_files, provenance_files)))
manifest <- dplyr::bind_rows(lapply(manifest_files, function(path) {
  info <- file.info(path)
  tibble::tibble(
    path = if (startsWith(path, paste0(root, "/"))) {
      substring(path, nchar(root) + 2L)
    } else {
      path
    },
    sha256 = artifact_sha256(path),
    bytes = as.numeric(info$size),
    producer = producer,
    r_version = as.character(getRversion())
  )
}))
write_review_csv(
  manifest,
  "H01_METRIC-010_author_gate_manifest.csv"
)

message("H01 METRIC-010 author-gate audit completed")
