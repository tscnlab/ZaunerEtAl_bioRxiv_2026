# Verify the H06-003 reader report and frozen-model temporal contrasts.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H06 Stage 3 tests require R 4.6.1", call. = FALSE)
}

read_h06 <- function(...) {
  readr::read_csv(
    file.path(root, "artifacts", ...),
    show_col_types = FALSE,
    na = ""
  )
}

input_contract <- h06_input_contract(root)
stopifnot(
  identical(
    input_contract$expected_sha256[
      input_contract$input_role == "approved_stage2_source"
    ],
    "736926de3576a7dceaed7b92fb65f65a05d8f6d32604d533fd9eb6e45e26a36d"
  ),
  identical(
    input_contract$expected_sha256[
      input_contract$input_role == "approved_stage2_render"
    ],
    "eea3da853bb23db96a59759d11a8f7eeb838e2e42960bf71ab96830030289b75"
  ),
  identical(
    input_contract$expected_sha256[
      input_contract$input_role == "approved_stage2_manifest"
    ],
    "2407f2045d960be1025dbd5e338d0df9a733bd4caf2afc29f16a9680fb355752"
  ),
  identical(
    input_contract$expected_sha256[
      input_contract$input_role == "stage3_gate_decision"
    ],
    "88fb0bae10e24d3fb300de64d8c6959865a5cfa7ed9ced98e66ae2dffbe0617d"
  ),
  all(vapply(
    seq_len(nrow(input_contract)),
    function(index) {
      identical(
        artifact_sha256(input_contract$path[[index]]),
        input_contract$expected_sha256[[index]]
      )
    },
    logical(1)
  ))
)

builder_path <- file.path(
  root,
  "scripts/hypotheses/H06/build_h06_stage3_temporal_contrasts.R"
)
invisible(parse(builder_path))
builder_text <- paste(readLines(builder_path, warn = FALSE), collapse = "\n")
stopifnot(
  !grepl("mgcv::bam[[:space:]]*\\(", builder_text),
  !grepl("mgcv::gam[[:space:]]*\\(", builder_text),
  !grepl("discrete[[:space:]]*=[[:space:]]*FALSE", builder_text),
  grepl('type = "lpmatrix"', builder_text, fixed = TRUE),
  grepl("occurrence-magnitude cross-component", builder_text, fixed = TRUE),
  grepl("covariance set to zero", builder_text, fixed = TRUE)
)

site_builder_path <- file.path(
  root,
  "scripts/hypotheses/H06/build_h06_stage3_site_deviations.R"
)
invisible(parse(site_builder_path))
site_builder_text <- paste(
  readLines(site_builder_path, warn = FALSE),
  collapse = "\n"
)
stopifnot(
  !grepl("stats::glm[[:space:]]*\\(", site_builder_text),
  !grepl("h06_fit_marginal[[:space:]]*\\(", site_builder_text),
  grepl("H06_robust_core_models.rds", site_builder_text, fixed = TRUE),
  grepl("site_gradient - average_gradient", site_builder_text, fixed = TRUE)
)

screen_builder_path <- file.path(
  root,
  paste0(
    "scripts/hypotheses/H06/",
    "build_h06_stage3_site_specific_screening.R"
  )
)
invisible(parse(screen_builder_path))
screen_builder_text <- paste(
  readLines(screen_builder_path, warn = FALSE),
  collapse = "\n"
)
stopifnot(
  !grepl("stats::glm[[:space:]]*\\(", screen_builder_text),
  !grepl("h06_fit_marginal[[:space:]]*\\(", screen_builder_text),
  grepl("readRDS[[:space:]]*\\(", screen_builder_text),
  grepl("p.adjust", screen_builder_text, fixed = TRUE),
  grepl("n = .env$planned_size", screen_builder_text, fixed = TRUE),
  grepl("planned_size <- 9L", screen_builder_text, fixed = TRUE),
  grepl("reference_sleep_duration_h", screen_builder_text, fixed = TRUE),
  grepl("reference_site_tests", screen_builder_text, fixed = TRUE),
  grepl("site_gradient - reference_average_gradient", screen_builder_text,
        fixed = TRUE),
  grepl("reference_vs_equal_site_p_adjusted", screen_builder_text,
        fixed = TRUE)
)

reader_builder_path <- file.path(
  root,
  "scripts/hypotheses/H06/build_h06_stage3_reader_displays.R"
)
invisible(parse(reader_builder_path))
reader_builder_text <- paste(
  readLines(reader_builder_path, warn = FALSE),
  collapse = "\n"
)
stopifnot(
  !grepl("stats::glm[[:space:]]*\\(", reader_builder_text),
  !grepl("mgcv::bam[[:space:]]*\\(", reader_builder_text),
  !grepl("mgcv::gam[[:space:]]*\\(", reader_builder_text),
  !grepl("readRDS[[:space:]]*\\(", reader_builder_text),
  grepl("H06_core_effects_figure.csv", reader_builder_text, fixed = TRUE),
  grepl("H06_reader_primary_effects", reader_builder_text, fixed = TRUE),
  grepl("H06_reader_temporal_day_type", reader_builder_text, fixed = TRUE),
  grepl("H06_reader_temporal_activity", reader_builder_text, fixed = TRUE),
  grepl('"Sedentary" = "#009E73"', reader_builder_text, fixed = TRUE),
  grepl('"Active" = "#CC79A7"', reader_builder_text, fixed = TRUE)
)

frozen_core_source <- read_h06(
  "11_source_data", "H06", "H06_core_effects_figure.csv"
)
reader_primary_source <- read_h06(
  "11_source_data", "H06", "H06_reader_primary_effects_figure.csv"
)
stopifnot(
  nrow(reader_primary_source) == 18L,
  identical(
    names(reader_primary_source),
    c(names(frozen_core_source), "effect_display")
  ),
  isTRUE(all.equal(
    reader_primary_source[names(frozen_core_source)],
    frozen_core_source,
    tolerance = 0,
    check.attributes = FALSE
  ))
)

contrasts <- read_h06(
  "11_source_data",
  "H06",
  "H06_exploratory_two_part_temporal_contrasts.csv"
)
expected_columns <- c(
  "contrast_id",
  "contrast_label",
  "clock_hour",
  "numerator",
  "denominator",
  "numerator_expected_melEDI_lx",
  "denominator_expected_melEDI_lx",
  "expected_melEDI_ratio",
  "pointwise_low_ratio",
  "pointwise_high_ratio",
  "log_ratio",
  "standard_error_log_ratio",
  "occurrence_standard_error_contribution",
  "positive_magnitude_standard_error_contribution",
  "numerator_observations",
  "numerator_positive_observations",
  "numerator_zero_observations",
  "numerator_participants",
  "numerator_participant_days",
  "numerator_sites_with_support",
  "denominator_observations",
  "denominator_positive_observations",
  "denominator_zero_observations",
  "denominator_participants",
  "denominator_participant_days",
  "denominator_sites_with_support",
  "null_reference_ratio",
  "basis_k",
  "sites_standardized",
  "other_factor_levels_standardized",
  "standardization",
  "model_components",
  "occurrence_working_rho",
  "positive_magnitude_working_rho",
  "random_effects",
  "interval_scope",
  "inferential_role",
  "pointwise_highlighting",
  "display_scale"
)
stopifnot(
  identical(names(contrasts), expected_columns),
  nrow(contrasts) == 194L,
  identical(
    sort(unique(contrasts$contrast_id)),
    c("active_vs_sedentary", "free_vs_work")
  ),
  all(table(contrasts$contrast_id) == 97L),
  all(vapply(
    split(contrasts$clock_hour, contrasts$contrast_id),
    function(clock) identical(clock, seq(0, 24, by = 0.25)),
    logical(1)
  )),
  all(is.finite(contrasts$expected_melEDI_ratio)),
  all(is.finite(contrasts$pointwise_low_ratio)),
  all(is.finite(contrasts$pointwise_high_ratio)),
  all(contrasts$pointwise_low_ratio > 0),
  all(contrasts$pointwise_high_ratio > 0),
  all(
    contrasts$pointwise_low_ratio <= contrasts$expected_melEDI_ratio &
      contrasts$expected_melEDI_ratio <= contrasts$pointwise_high_ratio
  ),
  all(contrasts$null_reference_ratio == 1),
  all(contrasts$basis_k == 16L),
  all(contrasts$sites_standardized == 9L),
  all(contrasts$other_factor_levels_standardized == 2L),
  all(contrasts$pointwise_highlighting == "none"),
  all(grepl("pointwise 95%", contrasts$interval_scope, fixed = TRUE)),
  all(grepl(
    "smoothing parameters fixed",
    contrasts$interval_scope,
    fixed = TRUE
  )),
  all(grepl(
    "cross-component covariance set to zero",
    contrasts$interval_scope,
    fixed = TRUE
  )),
  all(grepl("not simultaneous", contrasts$interval_scope, fixed = TRUE)),
  all(grepl(
    "no confirmatory whole-curve test",
    contrasts$inferential_role,
    fixed = TRUE
  ))
)

pointwise_direction <- dplyr::case_when(
  contrasts$pointwise_low_ratio > 1 ~ "higher",
  contrasts$pointwise_high_ratio < 1 ~ "lower",
  TRUE ~ "includes_null"
)
activity_higher_clock <- contrasts$clock_hour[
  contrasts$contrast_id == "active_vs_sedentary" &
    pointwise_direction == "higher"
]
activity_lower_clock <- contrasts$clock_hour[
  contrasts$contrast_id == "active_vs_sedentary" &
    pointwise_direction == "lower"
]
free_lower_clock <- contrasts$clock_hour[
  contrasts$contrast_id == "free_vs_work" &
    pointwise_direction == "lower"
]
stopifnot(
  identical(activity_higher_clock, seq(7.25, 19, by = 0.25)),
  identical(
    activity_lower_clock,
    c(seq(0, 5.25, by = 0.25), seq(23.5, 24, by = 0.25))
  ),
  identical(
    free_lower_clock,
    c(seq(6.75, 9.25, by = 0.25), seq(18.75, 19.25, by = 0.25))
  ),
  !any(
    contrasts$contrast_id == "free_vs_work" &
      pointwise_direction == "higher"
  )
)

site_deviations <- read_h06(
  "11_source_data",
  "H06",
  "H06_primary_work_free_site_deviations.csv"
)
above_average <- site_deviations |>
  dplyr::filter(.data$pointwise_deviation == "above_average")
stopifnot(
  nrow(site_deviations) == 9L,
  identical(
    above_average$display_name,
    c("Borås (SE)", "Dortmund (DE)")
  ),
  !any(site_deviations$pointwise_deviation == "below_average"),
  isTRUE(all.equal(
    unique(site_deviations$equal_site_heterogeneity_model_ratio),
    1.15495727277359,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    unique(site_deviations[[
      "equal_site_heterogeneity_model_conf_low_ratio"
    ]]),
    0.926410139391625,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    unique(site_deviations[[
      "equal_site_heterogeneity_model_conf_high_ratio"
    ]]),
    1.43988741618114,
    tolerance = 1e-12
  )),
  sum(site_deviations$site_to_average_ratio > 1) == 3L,
  sum(site_deviations$site_to_average_ratio < 1) == 6L,
  abs(sum(log(site_deviations$site_to_average_ratio))) < 1e-12,
  isTRUE(all.equal(
    above_average$site_to_average_ratio,
    c(1.68851375312749, 2.11591534417969),
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    above_average$site_to_average_conf_low_ratio,
    c(1.08591397933453, 1.24642173670216),
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    above_average$site_to_average_conf_high_ratio,
    c(2.62551062861157, 3.59196057955533),
    tolerance = 1e-12
  )),
  all(grepl(
    "not multiplicity adjusted across nine sites",
    site_deviations$interval_scope,
    fixed = TRUE
  )),
  all(site_deviations$denominator_df == 136L)
)

site_screen <- read_h06(
  "09_tables",
  "H06",
  "H06_stage3_site_specific_significance_screen.csv"
)
frozen_site_effects <- read_h06(
  "09_tables",
  "H06",
  "H06_robust_site_specific_effects.csv"
) |>
  dplyr::filter(.data$run_id == "main__glasses__all_available") |>
  dplyr::group_by(.data$predictor_id) |>
  dplyr::mutate(
    expected_adjusted = stats::p.adjust(.data$p_raw, method = "BH", n = 9L)
  ) |>
  dplyr::ungroup()
expected_adjusted <- frozen_site_effects$expected_adjusted[match(
  paste(site_screen$predictor_id, site_screen$site),
  paste(frozen_site_effects$predictor_id, frozen_site_effects$site)
)]
retained_site_screen <- site_screen |>
  dplyr::filter(.data$adjusted_significant_0_05)
reference_site_screen <- site_screen |>
  dplyr::distinct(
    .data$site,
    .data$display_order,
    .data$reference_family_id,
    .data$reference_family_method,
    .data$reference_planned_size,
    .data$reference_observed_size,
    .data$reference_vs_equal_site_ratio,
    .data$reference_vs_equal_site_conf_low_ratio,
    .data$reference_vs_equal_site_conf_high_ratio,
    .data$reference_vs_equal_site_p_raw,
    .data$reference_vs_equal_site_p_adjusted,
    .data$reference_vs_equal_site_adjusted_significant_0_05
  ) |>
  dplyr::arrange(.data$display_order)
expected_reference_adjusted <- stats::p.adjust(
  reference_site_screen$reference_vs_equal_site_p_raw,
  method = "BH",
  n = 9L
)
stopifnot(
  nrow(site_screen) == 27L,
  all(table(site_screen$predictor_id) == 9L),
  all(table(site_screen$site) == 3L),
  dplyr::n_distinct(site_screen$family_id) == 3L,
  all(endsWith(site_screen$family_id, "__nine_site_screen")),
  all(site_screen$planned_size == 9L),
  all(site_screen$observed_size == 9L),
  all(site_screen$family_method == "Benjamini-Hochberg"),
  nrow(reference_site_screen) == 9L,
  dplyr::n_distinct(reference_site_screen$reference_family_id) == 1L,
  all(reference_site_screen$reference_family_method == "Benjamini-Hochberg"),
  all(reference_site_screen$reference_planned_size == 9L),
  all(reference_site_screen$reference_observed_size == 9L),
  isTRUE(all.equal(
    reference_site_screen$reference_vs_equal_site_p_adjusted,
    expected_reference_adjusted,
    tolerance = 1e-15
  )),
  !any(
    reference_site_screen$
      reference_vs_equal_site_adjusted_significant_0_05
  ),
  isTRUE(all.equal(
    reference_site_screen$reference_vs_equal_site_p_adjusted,
    rep(0.738359730336228, 9L),
    tolerance = 1e-12
  )),
  abs(sum(log(
    reference_site_screen$reference_vs_equal_site_ratio
  ))) < 1e-12,
  all(reference_site_screen$reference_vs_equal_site_conf_low_ratio > 0),
  all(reference_site_screen$reference_vs_equal_site_conf_high_ratio > 0),
  all(site_screen$alpha == 0.05),
  all(site_screen$denominator_df == 136L),
  isTRUE(all.equal(
    site_screen$p_adjusted,
    expected_adjusted,
    tolerance = 1e-15
  )),
  identical(
    paste(
      retained_site_screen$predictor_id,
      retained_site_screen$site,
      sep = "__"
    ),
    c(
      "work_free_day__RISE",
      "work_free_day__BAUA",
      "activity_status__MPI"
    )
  ),
  isTRUE(all.equal(
    retained_site_screen$p_adjusted,
    c(0.0125318107379304, 0.0125318107379304, 0.0153587515873889),
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    unique(site_screen$reference_sleep_duration_h),
    7.79695637695638,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    site_screen |>
      dplyr::distinct(
        .data$predictor_id,
        .data$interaction_equal_site_ratio
      ) |>
      dplyr::arrange(match(
        .data$predictor_id,
        c(
          "work_free_day",
          "activity_status",
          "previous_sleep_duration_centered_h"
        )
      )) |>
      dplyr::pull(.data$interaction_equal_site_ratio),
    c(1.15495727277359, 1.9321153431106, 0.973480978614073),
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    site_screen |>
      dplyr::distinct(
        .data$predictor_id,
        .data$interaction_equal_site_p_adjusted
      ) |>
      dplyr::arrange(match(
        .data$predictor_id,
        c(
          "work_free_day",
          "activity_status",
          "previous_sleep_duration_centered_h"
        )
      )) |>
      dplyr::pull(.data$interaction_equal_site_p_adjusted),
    c(0.297808387458044, 0.000129924202423846, 0.613131681754188),
    tolerance = 1e-12
  )),
  all(is.finite(site_screen$reference_expected_melEDI_lx)),
  all(is.finite(site_screen$comparison_expected_melEDI_lx)),
  all(grepl("not a test", site_screen$distinction, fixed = TRUE)),
  all(grepl("ratio 1", site_screen$test_scope, fixed = TRUE))
)

closure <- contrasts |>
  dplyr::filter(.data$clock_hour %in% c(0, 24)) |>
  dplyr::select(dplyr::all_of(c(
    "contrast_id",
    "clock_hour",
    "expected_melEDI_ratio",
    "pointwise_low_ratio",
    "pointwise_high_ratio"
  ))) |>
  tidyr::pivot_wider(
    names_from = "clock_hour",
    values_from = c(
      "expected_melEDI_ratio",
      "pointwise_low_ratio",
      "pointwise_high_ratio"
    ),
    names_sep = "_"
  )
stopifnot(
  max(abs(
    closure$expected_melEDI_ratio_0 -
      closure$expected_melEDI_ratio_24
  )) <
    1e-10,
  max(abs(
    closure$pointwise_low_ratio_0 -
      closure$pointwise_low_ratio_24
  )) <
    1e-10,
  max(abs(
    closure$pointwise_high_ratio_0 -
      closure$pointwise_high_ratio_24
  )) <
    1e-10
)

activity <- read_h06(
  "11_source_data",
  "H06",
  "H06_exploratory_two_part_activity_predictions.csv"
)
activity_expected <- activity |>
  dplyr::group_by(.data$clock_hour) |>
  dplyr::summarise(
    expected_ratio = .data$expected_melEDI_lx[grepl(
      "^Active",
      .data$activity_status
    )] /
      .data$expected_melEDI_lx[grepl("^Sedentary", .data$activity_status)],
    .groups = "drop"
  )
day_type <- read_h06(
  "11_source_data",
  "H06",
  "H06_exploratory_two_part_day_type_predictions.csv"
)
day_type_expected <- day_type |>
  dplyr::group_by(.data$clock_hour) |>
  dplyr::summarise(
    expected_ratio = .data$expected_melEDI_lx[
      .data$work_free_day == "Free day"
    ] /
      .data$expected_melEDI_lx[.data$work_free_day == "Work day"],
    .groups = "drop"
  )
stopifnot(
  isTRUE(all.equal(
    contrasts$expected_melEDI_ratio[
      contrasts$contrast_id == "active_vs_sedentary"
    ],
    activity_expected$expected_ratio,
    tolerance = 1e-10
  )),
  isTRUE(all.equal(
    contrasts$expected_melEDI_ratio[
      contrasts$contrast_id == "free_vs_work"
    ],
    day_type_expected$expected_ratio,
    tolerance = 1e-10
  ))
)

reader_day_curves <- read_h06(
  "11_source_data", "H06", "H06_reader_temporal_day_type_curves.csv"
)
reader_day_ratios <- read_h06(
  "11_source_data", "H06", "H06_reader_temporal_day_type_ratios.csv"
)
reader_day_support <- read_h06(
  "11_source_data", "H06", "H06_reader_temporal_day_type_support.csv"
)
reader_activity_curves <- read_h06(
  "11_source_data", "H06", "H06_reader_temporal_activity_curves.csv"
)
reader_activity_ratios <- read_h06(
  "11_source_data", "H06", "H06_reader_temporal_activity_ratios.csv"
)
reader_activity_support <- read_h06(
  "11_source_data", "H06", "H06_reader_temporal_activity_support.csv"
)
frozen_day_figure_source <- read_h06(
  "11_source_data", "H06",
  "H06_exploratory_two_part_day_type_expected_figure.csv"
)
frozen_activity_figure_source <- read_h06(
  "11_source_data", "H06",
  "H06_exploratory_two_part_activity_expected_figure.csv"
)
stopifnot(
  nrow(reader_day_curves) == 194L,
  nrow(reader_activity_curves) == 194L,
  isTRUE(all.equal(
    reader_day_curves[names(frozen_day_figure_source)],
    frozen_day_figure_source,
    tolerance = 0,
    check.attributes = FALSE
  )),
  isTRUE(all.equal(
    reader_activity_curves[names(frozen_activity_figure_source)],
    frozen_activity_figure_source,
    tolerance = 0,
    check.attributes = FALSE
  )),
  nrow(reader_day_ratios) == 97L,
  nrow(reader_activity_ratios) == 97L,
  "pointwise_ci_excludes_one" %in% names(reader_day_ratios),
  "pointwise_ci_excludes_one" %in% names(reader_activity_ratios),
  identical(
    reader_day_ratios$pointwise_ci_excludes_one,
    reader_day_ratios$pointwise_low_ratio > 1 |
      reader_day_ratios$pointwise_high_ratio < 1
  ),
  identical(
    reader_activity_ratios$pointwise_ci_excludes_one,
    reader_activity_ratios$pointwise_low_ratio > 1 |
      reader_activity_ratios$pointwise_high_ratio < 1
  ),
  isTRUE(all.equal(
    reader_day_ratios[names(contrasts)],
    dplyr::filter(contrasts, .data$contrast_id == "free_vs_work"),
    tolerance = 0,
    check.attributes = FALSE
  )),
  isTRUE(all.equal(
    reader_activity_ratios[names(contrasts)],
    dplyr::filter(contrasts, .data$contrast_id == "active_vs_sedentary"),
    tolerance = 0,
    check.attributes = FALSE
  )),
  nrow(reader_day_support) == 48L,
  nrow(reader_activity_support) == 48L,
  all(reader_day_support$participant_hours > 0),
  all(reader_activity_support$participant_hours > 0),
  all(reader_day_support$sites_with_support == 9L),
  all(reader_activity_support$sites_with_support == 9L),
  all(reader_day_support$support_state ==
    "Observed in all nine study sites"),
  all(reader_activity_support$support_state ==
    "Observed in all nine study sites"),
  all(vapply(
    split(reader_day_support$clock_hour, reader_day_support$display_group),
    function(clock) identical(clock, as.double(0:23)),
    logical(1)
  )),
  all(vapply(
    split(
      reader_activity_support$clock_hour,
      reader_activity_support$display_group
    ),
    function(clock) identical(clock, as.double(0:23)),
    logical(1)
  ))
)

reader_figure_stems <- c(
  "H06_reader_primary_effects",
  "H06_reader_temporal_day_type",
  "H06_reader_temporal_activity"
)
reader_figure_paths <- file.path(
  root,
  "artifacts/10_figures/H06",
  paste0(reader_figure_stems, ".png")
)
reader_figure_pdfs <- sub("[.]png$", ".pdf", reader_figure_paths)
reader_qa <- read_h06(
  "12_manifests",
  "H06",
  "H06_stage3_reader_display_figure_readability_qa.csv"
)
stopifnot(
  all(file.exists(reader_figure_paths)),
  all(file.exists(reader_figure_pdfs)),
  nrow(reader_qa) == 3L,
  identical(reader_qa$figure_id, reader_figure_stems),
  all(reader_qa$native_width_mm == 170),
  identical(reader_qa$native_height_mm, c(118, 205, 205)),
  all(reader_qa$intended_print_display_width_mm == 170),
  all(reader_qa$scale_factor == 1),
  all(reader_qa$smallest_essential_nominal_text_pt == 7.5),
  all(reader_qa$effective_final_text_pt == 7.5),
  all(reader_qa$report_011_status == "PASS"),
  all(grepl(
    "no clipping",
    reader_qa$physical_size_inspection,
    fixed = TRUE
  ))
)

site_screen_figure_path <- file.path(
  root,
  paste0(
    "artifacts/10_figures/H06/",
    "H06_stage3_site_specific_significance_screen.png"
  )
)
site_screen_figure_pdf <- sub(
  "[.]png$",
  ".pdf",
  site_screen_figure_path
)
site_screen_figure_source <- read_h06(
  "11_source_data",
  "H06",
  "H06_stage3_site_specific_significance_screen_figure.csv"
)
site_screen_qa <- read_h06(
  "12_manifests",
  "H06",
  "H06_stage3_site_specific_significance_figure_readability_qa.csv"
)
stopifnot(
  file.exists(site_screen_figure_path),
  file.exists(site_screen_figure_pdf),
  nrow(site_screen_figure_source) == 27L,
  sum(site_screen_figure_source$adjusted_significant_0_05) == 3L,
  "interaction_equal_site_ratio" %in% names(site_screen_figure_source),
  all(c(
    "interaction_equal_site_conf_low_ratio",
    "interaction_equal_site_conf_high_ratio",
    "interaction_equal_site_p_adjusted",
    "reference_expected_melEDI_lx",
    "reference_conf_low_melEDI_lx",
    "reference_conf_high_melEDI_lx",
    "reference_vs_equal_site_p_adjusted",
    "reference_vs_equal_site_adjusted_significant_0_05",
    "comparison_expected_melEDI_lx"
  ) %in% names(site_screen_figure_source)),
  all(is.finite(site_screen_figure_source$interaction_equal_site_ratio)),
  isTRUE(all.equal(
    site_screen_figure_source |>
      dplyr::distinct(
        .data$predictor_id,
        .data$interaction_equal_site_ratio
      ) |>
      dplyr::arrange(match(
        .data$predictor_id,
        c(
          "work_free_day",
          "activity_status",
          "previous_sleep_duration_centered_h"
        )
      )) |>
      dplyr::pull(.data$interaction_equal_site_ratio),
    c(1.15495727277359, 1.9321153431106, 0.973480978614073),
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    site_screen_figure_source |>
      dplyr::distinct(
        .data$predictor_id,
        .data$interaction_equal_site_p_adjusted
      ) |>
      dplyr::arrange(match(
        .data$predictor_id,
        c(
          "work_free_day",
          "activity_status",
          "previous_sleep_duration_centered_h"
        )
      )) |>
      dplyr::pull(.data$interaction_equal_site_p_adjusted),
    c(0.297808387458044, 0.000129924202423846, 0.613131681754188),
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    unique(
      site_screen_figure_source$
        interaction_equal_site_reference_expected_melEDI_lx
    ),
    88.9743672761171,
    tolerance = 1e-12
  )),
  all(is.finite(site_screen_figure_source$reference_expected_melEDI_lx)),
  all(is.finite(site_screen_figure_source$comparison_expected_melEDI_lx)),
  identical(
    levels(factor(site_screen_figure_source$screen_label)),
    c("BH-retained", "Not BH-retained")
  ),
  nrow(site_screen_qa) == 1L,
  site_screen_qa$native_width_mm == 170,
  site_screen_qa$native_height_mm == 135,
  site_screen_qa$intended_print_display_width_mm == 170,
  site_screen_qa$scale_factor == 1,
  site_screen_qa$smallest_essential_nominal_text_pt == 8,
  site_screen_qa$effective_final_text_pt == 8,
  site_screen_qa$report_011_status == "PASS",
  grepl(
    "filled and open point shapes",
    site_screen_qa$physical_size_inspection,
    fixed = TRUE
  )
)

qmd_path <- file.path(root, "notebooks/hypotheses/H06.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H06.html"
)
stopifnot(file.exists(qmd_path), file.exists(html_path))
qmd_text <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
qmd_flat <- gsub("[[:space:]]+", " ", qmd_text)
stopifnot(
  length(grep(
    'title="Answer in brief."',
    readLines(qmd_path, warn = FALSE),
    fixed = TRUE
  )) ==
    1L,
  !grepl("Results in brief", qmd_text, fixed = TRUE),
  grepl("H06-G3 author-review gate", qmd_text, fixed = TRUE),
  grepl("Stage 4 remains blocked", qmd_text, fixed = TRUE),
  grepl("07:15 to 19:00", qmd_flat, fixed = TRUE),
  grepl("23:30 to 05:15", qmd_flat, fixed = TRUE),
  grepl("06:45 to 09:15", qmd_flat, fixed = TRUE),
  grepl("18:45 to 19:15", qmd_flat, fixed = TRUE),
  grepl("equivalent to excluding", qmd_flat, fixed = TRUE),
  grepl("Borås and Dortmund", qmd_flat, fixed = TRUE),
  grepl("three separate", qmd_flat, ignore.case = TRUE),
  grepl("nine-site", qmd_flat, fixed = TRUE),
  !grepl("27-test", qmd_text, fixed = TRUE),
  !grepl("Raw p", qmd_text, fixed = TRUE),
  !grepl("raw p", qmd_text, fixed = TRUE),
  grepl("active/sedentary association at Tübingen", qmd_flat, fixed = TRUE),
  grepl("geometric mean on the ratio scale", qmd_flat, fixed = TRUE),
  grepl("1.15 (95% CI 0.93–1.44)", qmd_flat, fixed = TRUE),
  !grepl("H03 reader-display grammar", qmd_text, fixed = TRUE),
  grepl("H06_reader_primary_effects.png", qmd_text, fixed = TRUE),
  grepl("H06_reader_temporal_day_type.png", qmd_text, fixed = TRUE),
  grepl("H06_reader_temporal_activity.png", qmd_text, fixed = TRUE),
  grepl("Bold ratios", qmd_text, fixed = TRUE),
  grepl("Reference profile", qmd_text, fixed = TRUE),
  grepl("participant-day mean in the fitted sample", qmd_flat, fixed = TRUE),
  grepl("H06.css", qmd_text, fixed = TRUE),
  grepl("- **Primary associations.**", qmd_text, fixed = TRUE),
  grepl("- **Site and model dependence.**", qmd_text, fixed = TRUE),
  grepl("- **Exploratory site screens.**", qmd_text, fixed = TRUE),
  grepl("- **Exploratory clock-time patterns.**", qmd_text, fixed = TRUE),
  grepl("**BH-adjusted p < 0.001**", qmd_flat, fixed = TRUE),
  grepl("**BH-adjusted p = 0.004**", qmd_flat, fixed = TRUE),
  grepl("vs equal-site BH p", qmd_text, fixed = TRUE),
  grepl("fourth nine-site adjustment", qmd_flat, fixed = TRUE),
  grepl("comparison_conf_low_melEDI_lx", qmd_text, fixed = TRUE),
  grepl("comparison_conf_high_melEDI_lx", qmd_text, fixed = TRUE),
  grepl("All six reader-facing figures", qmd_flat, fixed = TRUE),
  grepl("no site was pointwise below it", qmd_flat, fixed = TRUE),
  !grepl("V0", qmd_text, fixed = TRUE),
  !grepl("discrete = FALSE", qmd_text, fixed = TRUE)
)

html <- xml2::read_html(html_path)
main <- xml2::xml_find_first(html, "//main")
images <- xml2::xml_find_all(main, ".//img")
answer_callout <- xml2::xml_find_first(
  main,
  ".//section[@id='analytical-question']//div[contains(@class,'callout')]"
)
site_screen_table <- xml2::xml_find_first(
  main,
  paste0(
    ".//table[caption[contains(normalize-space(.),",
    "'Site-specific near-eye associations')]]"
  )
)
site_screen_table_text <- gsub(
  "[[:space:]]+",
  " ",
  xml2::xml_text(site_screen_table)
)
site_colour_markers <- xml2::xml_find_all(
  site_screen_table,
  ".//span[@title='Study-site colour marker']"
)
bold_site_cells <- xml2::xml_find_all(
  site_screen_table,
  ".//td[1]//strong[span[@title='Study-site colour marker']]"
)
source_links <- xml2::xml_find_all(
  main,
  paste0(
    ".//a[contains(translate(normalize-space(.),",
    "'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),",
    "'source csv')]"
  )
)
hrefs <- xml2::xml_attr(source_links, "href")
expected_source_hrefs <- c(
  "../../artifacts/11_source_data/H06/H06_reader_primary_effects_figure.csv",
  paste0(
    "../../artifacts/11_source_data/H06/",
    "H06_stage3_site_specific_significance_screen_figure.csv"
  ),
  "../../artifacts/11_source_data/H06/H06_paired_placement_effects_figure.csv",
  "../../artifacts/11_source_data/H06/H06_primary_residual_clock_figure.csv",
  "../../artifacts/11_source_data/H06/H06_reader_temporal_day_type_curves.csv",
  "../../artifacts/11_source_data/H06/H06_reader_temporal_day_type_ratios.csv",
  "../../artifacts/11_source_data/H06/H06_reader_temporal_day_type_support.csv",
  "../../artifacts/11_source_data/H06/H06_reader_temporal_activity_curves.csv",
  "../../artifacts/11_source_data/H06/H06_reader_temporal_activity_ratios.csv",
  "../../artifacts/11_source_data/H06/H06_reader_temporal_activity_support.csv",
  paste0(
    "../../artifacts/11_source_data/H06/",
    "H06_primary_work_free_site_deviations.csv"
  )
)
site_deviation_link <- xml2::xml_find_first(
  main,
  paste0(
    ".//a[normalize-space(.)=",
    "'Site-to-average deviation source CSV']"
  )
)
site_screen_table_link <- xml2::xml_find_first(
  main,
  paste0(
    ".//a[normalize-space(.)=",
    "'Site-specific results CSV']"
  )
)
linked_files <- normalizePath(
  file.path(dirname(html_path), hrefs),
  winslash = "/",
  mustWork = FALSE
)
stopifnot(
  length(images) == 6L,
  all(nzchar(xml2::xml_attr(images, "alt"))),
  length(source_links) == 11L,
  all(expected_source_hrefs %in% hrefs),
  all(startsWith(hrefs, "../../artifacts/")),
  all(file.exists(linked_files)),
  !is.na(site_deviation_link),
  file.exists(normalizePath(
    file.path(dirname(html_path), xml2::xml_attr(site_deviation_link, "href")),
    winslash = "/",
    mustWork = FALSE
  )),
  !is.na(site_screen_table_link),
  file.exists(normalizePath(
    file.path(
      dirname(html_path),
      xml2::xml_attr(site_screen_table_link, "href")
    ),
    winslash = "/",
    mustWork = FALSE
  )),
  length(xml2::xml_find_all(
    main,
    ".//*[contains(@class,'cell-output-error')]"
  )) ==
    0L,
  length(xml2::xml_find_all(main, ".//table")) >= 13L,
  !is.na(answer_callout),
  length(xml2::xml_find_all(answer_callout, ".//li")) == 4L,
  length(xml2::xml_find_all(
    answer_callout,
    ".//strong[contains(.,'p')]"
  )) >= 4L,
  !is.na(site_screen_table),
  grepl(
    "214 lx (95% CI 97–471 lx)",
    site_screen_table_text,
    fixed = TRUE
  ),
  grepl(
    "vs equal-site BH p 0.738",
    site_screen_table_text,
    fixed = TRUE
  ),
  !grepl("Free day:", site_screen_table_text, fixed = TRUE),
  !grepl("Active:", site_screen_table_text, fixed = TRUE),
  length(site_colour_markers) == 9L,
  all(xml2::xml_text(site_colour_markers) == "●"),
  length(bold_site_cells) == 9L,
  grepl("Answer in brief[.]", xml2::xml_text(main)),
  grepl("Reference", xml2::xml_text(main), fixed = TRUE),
  grepl("7.8 h sleep", xml2::xml_text(main), fixed = TRUE),
  !grepl("27-test", xml2::xml_text(main), fixed = TRUE),
  grepl("H06-G3 author-review gate", xml2::xml_text(main), fixed = TRUE)
)

manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H06/H06_stage3_artifacts.csv"
)
stopifnot(file.exists(manifest_path))
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
expected_manifest_columns <- c(
  "path",
  "artifact_class",
  "artifact_type",
  "sha256",
  "bytes",
  "producer",
  "r_version",
  "written_utc"
)
expected_manifest_paths <- c(
  "notebooks/hypotheses/H06.qmd",
  "notebooks/hypotheses/H06.css",
  "_build/nathealth/notebooks/hypotheses/H06.html",
  "scripts/hypotheses/H06/build_h06_stage3_temporal_contrasts.R",
  "scripts/hypotheses/H06/build_h06_stage3_site_deviations.R",
  paste0(
    "scripts/hypotheses/H06/",
    "build_h06_stage3_site_specific_screening.R"
  ),
  "scripts/hypotheses/H06/build_h06_stage3_reader_displays.R",
  "scripts/hypotheses/H06/build_h06_stage3_manifest.R",
  "tests/hypotheses/H06/test_h06_stage3.R",
  "audit/hypotheses/H06/02_implementation_and_v0_comparison.qmd",
  "audit/hypotheses/H06/02_implementation_and_v0_comparison.html",
  "audit/handoffs/H06_worker_handoff.md",
  "audit/decisions/h06_stage2_gate_and_stage3_transition.md",
  "artifacts/12_manifests/H06/H06_stage2_artifacts.csv",
  "artifacts/10_figures/H06/H06_exploratory_two_part_temporal_contrasts.png",
  "artifacts/11_source_data/H06/H06_exploratory_two_part_temporal_contrasts.csv",
  "artifacts/10_figures/H06/H06_reader_primary_effects.png",
  "artifacts/10_figures/H06/H06_reader_temporal_day_type.png",
  "artifacts/10_figures/H06/H06_reader_temporal_activity.png",
  "artifacts/11_source_data/H06/H06_reader_primary_effects_figure.csv",
  "artifacts/11_source_data/H06/H06_reader_temporal_day_type_curves.csv",
  "artifacts/11_source_data/H06/H06_reader_temporal_day_type_ratios.csv",
  "artifacts/11_source_data/H06/H06_reader_temporal_day_type_support.csv",
  "artifacts/11_source_data/H06/H06_reader_temporal_activity_curves.csv",
  "artifacts/11_source_data/H06/H06_reader_temporal_activity_ratios.csv",
  "artifacts/11_source_data/H06/H06_reader_temporal_activity_support.csv",
  paste0(
    "artifacts/12_manifests/H06/",
    "H06_stage3_reader_display_figure_readability_qa.csv"
  ),
  "artifacts/11_source_data/H06/H06_primary_work_free_site_deviations.csv",
  paste0(
    "artifacts/09_tables/H06/",
    "H06_stage3_site_specific_significance_screen.csv"
  ),
  paste0(
    "artifacts/10_figures/H06/",
    "H06_stage3_site_specific_significance_screen.png"
  ),
  paste0(
    "artifacts/11_source_data/H06/",
    "H06_stage3_site_specific_significance_screen_figure.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06/",
    "H06_stage3_site_specific_significance_figure_readability_qa.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H06/",
    "H06_exploratory_two_part_temporal_contrasts.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H06/",
    "H06_primary_work_free_site_deviations.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/09_tables/H06/",
    "H06_stage3_site_specific_significance_screen.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H06/",
    "H06_stage3_site_specific_significance_screen_figure.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H06/",
    "H06_reader_primary_effects_figure.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H06/",
    "H06_reader_temporal_day_type_curves.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H06/",
    "H06_reader_temporal_day_type_ratios.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H06/",
    "H06_reader_temporal_day_type_support.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H06/",
    "H06_reader_temporal_activity_curves.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H06/",
    "H06_reader_temporal_activity_ratios.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H06/",
    "H06_reader_temporal_activity_support.csv"
  )
)
stopifnot(
  identical(names(manifest), expected_manifest_columns),
  !anyDuplicated(manifest$path),
  all(expected_manifest_paths %in% manifest$path),
  !"artifacts/12_manifests/H06/H06_stage3_artifacts.csv" %in%
    manifest$path,
  all(manifest$r_version == "4.6.1"),
  all(nchar(manifest$sha256) == 64L)
)
manifest_paths <- file.path(root, manifest$path)
stopifnot(
  all(file.exists(manifest_paths)),
  identical(
    unname(vapply(manifest_paths, artifact_sha256, character(1))),
    manifest$sha256
  )
)

message(
  "H06 Stage 3 tests passed: frozen-model temporal contrasts, exploratory ",
  "three-family site-ratio screen plus the nine-site reference-profile ",
  "screen, six accessible reader figures, linked source data, and sealed ",
  "provenance"
)
