# Verify the H06 exploratory two-part GAMM and strengthened stored-BAM audit.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H06 GAMM amendment tests require R 4.6.1", call. = FALSE)
}

read_h06 <- function(...) {
  readr::read_csv(
    file.path(root, "artifacts", ...),
    show_col_types = FALSE,
    na = ""
  )
}

script_paths <- file.path(
  root,
  "scripts/hypotheses/H06",
  c(
    "run_h06_exploratory_time_of_day_two_part.R",
    "diagnose_h06_exploratory_two_part.R",
    "audit_h06_stored_bam_models.R",
    "build_h06_exploratory_two_part_reader_artifacts.R"
  )
)
invisible(lapply(script_paths, parse))
script_text <- paste(
  vapply(
    script_paths,
    function(path) paste(readLines(path, warn = FALSE), collapse = "\n"),
    character(1)
  ),
  collapse = "\n"
)
stopifnot(!grepl("discrete[[:space:]]*=[[:space:]]*FALSE", script_text))

selected_formulas <- h06_exploratory_two_part_gamm_formulas(k = 16L)
selected_formula_text <- vapply(
  selected_formulas,
  function(formula) paste(deparse(formula), collapse = " "),
  character(1)
)
stopifnot(
  length(selected_formulas) == 2L,
  all(grepl('bs = "cc"', selected_formula_text, fixed = TRUE)),
  all(grepl(
    "by = day_activity_group",
    selected_formula_text,
    fixed = TRUE
  )),
  all(grepl("id = 1", selected_formula_text, fixed = TRUE)),
  all(grepl(
    "work_free_day * activity_status",
    selected_formula_text,
    fixed = TRUE
  )),
  !any(grepl('bs = "sz"', selected_formula_text, fixed = TRUE)),
  !any(grepl("s(clock_hour, site", selected_formula_text, fixed = TRUE))
)

formula_registry <- read_h06(
  "06_model_data",
  "H06",
  "H06_exploratory_two_part_formula_registry.csv"
)
support <- read_h06(
  "06_model_data",
  "H06",
  "H06_exploratory_two_part_support.csv"
)
fits <- read_h06(
  "08_diagnostics",
  "H06",
  "H06_exploratory_two_part_fit_summary.csv"
)
closure <- read_h06(
  "08_diagnostics",
  "H06",
  "H06_exploratory_two_part_cyclic_closure.csv"
)
k_sensitivity <- read_h06(
  "08_diagnostics",
  "H06",
  "H06_exploratory_two_part_k_sensitivity.csv"
)
residual <- read_h06(
  "08_diagnostics",
  "H06",
  "H06_exploratory_two_part_residual_summary.csv"
)
calibration <- read_h06(
  "08_diagnostics",
  "H06",
  "H06_exploratory_two_part_calibration_summary.csv"
)
predictions <- read_h06(
  "11_source_data",
  "H06",
  "H06_exploratory_two_part_predictions.csv"
)
day_type_predictions <- read_h06(
  "11_source_data",
  "H06",
  "H06_exploratory_two_part_day_type_predictions.csv"
)
activity_predictions <- read_h06(
  "11_source_data",
  "H06",
  "H06_exploratory_two_part_activity_predictions.csv"
)
day_type_source <- read_h06(
  "11_source_data",
  "H06",
  "H06_exploratory_two_part_day_type_expected_figure.csv"
)
activity_source <- read_h06(
  "11_source_data",
  "H06",
  "H06_exploratory_two_part_activity_expected_figure.csv"
)
figure_qa <- read_h06(
  "12_manifests",
  "H06",
  "H06_exploratory_two_part_figure_readability_qa.csv"
)
bam_audit <- read_h06(
  "08_diagnostics",
  "H06",
  "H06_v0_scaffold_pilot_bam_gamm_audit.csv"
)
bam_lag <- read_h06(
  "08_diagnostics",
  "H06",
  "H06_v0_scaffold_pilot_bam_per_sequence_residual_lag.csv"
)
artifact_manifest <- read_h06(
  "12_manifests",
  "H06",
  "H06_stage2_artifacts.csv"
)

model_bundle <- readRDS(file.path(
  root,
  "artifacts/07_models/H06/H06_exploratory_time_of_day_two_part.rds"
))

selected_fits <- fits[fits$selected_for_exploratory_display, , drop = FALSE]
selected_standardized_lag <- residual[
  residual$basis_k == 16L & residual$residual_type == "AR_standardized",
  ,
  drop = FALSE
]

expected_day_type_from_joint <- predictions |>
  dplyr::group_by(.data$clock_hour, .data$work_free_day) |>
  dplyr::summarise(
    expected_melEDI_lx = mean(.data$expected_melEDI_lx),
    .groups = "drop"
  ) |>
  dplyr::arrange(.data$clock_hour, .data$work_free_day)
observed_day_type <- day_type_predictions |>
  dplyr::select(dplyr::all_of(c(
    "clock_hour",
    "work_free_day",
    "expected_melEDI_lx"
  ))) |>
  dplyr::arrange(.data$clock_hour, .data$work_free_day)

expected_activity_from_joint <- predictions |>
  dplyr::group_by(.data$clock_hour, .data$activity_status) |>
  dplyr::summarise(
    expected_melEDI_lx = mean(.data$expected_melEDI_lx),
    .groups = "drop"
  ) |>
  dplyr::arrange(.data$clock_hour, .data$activity_status)
observed_activity <- activity_predictions |>
  dplyr::select(dplyr::all_of(c(
    "clock_hour",
    "activity_status",
    "expected_melEDI_lx"
  ))) |>
  dplyr::arrange(.data$clock_hour, .data$activity_status)

stopifnot(
  identical(
    model_bundle$contract_version,
    paste0(
      "v3_two_part_cyclic_factor_by_group_equal_site_",
      "k16_selected_discrete_working_ar"
    )
  ),
  identical(
    sort(names(model_bundle$base_fits)),
    c(
      "occurrence",
      "positive_magnitude"
    )
  ),
  all(vapply(model_bundle$base_fits, function(fit) fit$k == 16L, logical(1))),
  nrow(formula_registry) == 2L,
  identical(
    stats::setNames(
      formula_registry$selected_formula,
      formula_registry$component
    )[
      names(selected_formula_text)
    ],
    selected_formula_text
  ),
  all(formula_registry$selected_basis_k == 16L),
  all(formula_registry$lower_basis_sensitivity_k == 12L),
  all(formula_registry$discrete),
  !any(formula_registry$duplicated_parametric_site_day_activity_terms),
  all(formula_registry$cyclic_factor_by_group_smooths),
  all(formula_registry$shared_smoothing_parameter_across_four_group_curves),
  !any(formula_registry$sum_to_zero_smooths),
  !any(formula_registry$site_specific_clock_smooth),
  nrow(support) == 864L,
  sum(support$observations) == 16596L,
  sum(support$positive_observations) == 11899L,
  sum(support$zero_observations) == 4697L,
  !any(support$observations == 0L),
  sum(support$positive_observations == 0L) == 70L,
  sum(support$positive_observations < 3L) == 150L,
  sum(support$positive_observations < 5L) == 248L,
  sum(support$participants < 5L) == 172L,
  sum(support$participants < 10L) == 418L,
  nrow(fits) == 4L,
  nrow(selected_fits) == 2L,
  all(selected_fits$basis_k == 16L),
  all(selected_fits$converged),
  all(selected_fits$full_fixed_smooth_rank),
  identical(selected_fits$observations, c(16596, 11899)),
  identical(selected_fits$analysis_sequences, c(1052, 1370)),
  all(is.na(selected_fits$final_warnings)),
  max(closure$maximum_absolute_closure_difference) < 1e-10,
  identical(k_sensitivity$lower_basis_k, rep(12, 3)),
  identical(k_sensitivity$selected_k, rep(16, 3)),
  nrow(selected_standardized_lag) == 2L,
  all(abs(selected_standardized_lag$median_sequence_lag1) < 0.1),
  nrow(calibration) == 2L,
  nrow(predictions) == 388L,
  !"site" %in% names(predictions),
  dplyr::n_distinct(predictions$day_activity_group) == 4L,
  all(predictions$sites_standardized == 9L),
  all(is.finite(predictions$positive_probability)),
  all(
    predictions$positive_probability > 0 & predictions$positive_probability < 1
  ),
  all(predictions$conditional_positive_mean_melEDI_lx > 0),
  all(predictions$expected_melEDI_lx > 0),
  isTRUE(all.equal(
    predictions$product_of_standardized_components_melEDI_lx,
    predictions$positive_probability *
      predictions$conditional_positive_mean_melEDI_lx,
    tolerance = 1e-10
  )),
  all(predictions$expected_low_melEDI_lx <= predictions$expected_melEDI_lx),
  all(predictions$expected_high_melEDI_lx >= predictions$expected_melEDI_lx),
  nrow(day_type_predictions) == 194L,
  nrow(activity_predictions) == 194L,
  !"site" %in% names(day_type_predictions),
  !"site" %in% names(activity_predictions),
  dplyr::n_distinct(day_type_predictions$work_free_day) == 2L,
  dplyr::n_distinct(activity_predictions$activity_status) == 2L,
  all(day_type_predictions$sites_standardized == 9L),
  all(activity_predictions$sites_standardized == 9L),
  all(grepl(
    "equal weight to sedentary and active status",
    day_type_predictions$standardization,
    fixed = TRUE
  )),
  all(grepl(
    "equal weight to work and free days",
    activity_predictions$standardization,
    fixed = TRUE
  )),
  identical(
    observed_day_type[c("clock_hour", "work_free_day")],
    expected_day_type_from_joint[c("clock_hour", "work_free_day")]
  ),
  isTRUE(all.equal(
    observed_day_type$expected_melEDI_lx,
    expected_day_type_from_joint$expected_melEDI_lx,
    tolerance = 1e-10
  )),
  identical(
    observed_activity[c("clock_hour", "activity_status")],
    expected_activity_from_joint[c("clock_hour", "activity_status")]
  ),
  isTRUE(all.equal(
    observed_activity$expected_melEDI_lx,
    expected_activity_from_joint$expected_melEDI_lx,
    tolerance = 1e-10
  )),
  all(
    day_type_predictions$expected_low_melEDI_lx <=
      day_type_predictions$expected_melEDI_lx
  ),
  all(
    day_type_predictions$expected_high_melEDI_lx >=
      day_type_predictions$expected_melEDI_lx
  ),
  all(
    activity_predictions$expected_low_melEDI_lx <=
      activity_predictions$expected_melEDI_lx
  ),
  all(
    activity_predictions$expected_high_melEDI_lx >=
      activity_predictions$expected_melEDI_lx
  ),
  nrow(day_type_source) == 194L,
  nrow(activity_source) == 194L,
  !"site" %in% names(day_type_source),
  !"site" %in% names(activity_source),
  all(day_type_source$sites_standardized == 9L),
  all(activity_source$sites_standardized == 9L),
  all(
    day_type_source$display_scale ==
      paste(
        "LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)"
      )
  ),
  all(
    activity_source$display_scale ==
      paste(
        "LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)"
      )
  ),
  nrow(figure_qa) == 2L,
  all(figure_qa$native_width_mm == 170),
  all(figure_qa$intended_print_display_width_mm == 170),
  all(figure_qa$scale_factor == 1),
  all(figure_qa$native_height_mm == 112),
  all(figure_qa$effective_final_text_pt >= 8),
  all(figure_qa$report_011_status == "PASS"),
  all(figure_qa$exact_report_013_symlog),
  identical(
    sort(figure_qa$figure_id),
    sort(c(
      "H06_exploratory_two_part_day_type_expected",
      "H06_exploratory_two_part_activity_expected"
    ))
  ),
  nrow(bam_audit) == 2L,
  all(bam_audit$random_effect_penalties_effectively_absent),
  all(bam_audit$simulated_zero_fraction_100 > 0.8),
  all(bam_audit$observed_zero_fraction < 0.3),
  all(bam_audit$positive_tail_calibration == "NOT TESTED in the stored pilot"),
  all(c("pearson", "AR_standardized") %in% unique(bam_lag$residual_type))
)

required_manifest_paths <- c(
  "scripts/hypotheses/H06/run_h06_exploratory_time_of_day_two_part.R",
  "scripts/hypotheses/H06/diagnose_h06_exploratory_two_part.R",
  "scripts/hypotheses/H06/audit_h06_stored_bam_models.R",
  paste0(
    "scripts/hypotheses/H06/",
    "build_h06_exploratory_two_part_reader_artifacts.R"
  ),
  "tests/hypotheses/H06/test_h06_gamm_amendment.R",
  "artifacts/07_models/H06/H06_exploratory_time_of_day_two_part.rds",
  paste0(
    "artifacts/08_diagnostics/H06/",
    "H06_v0_scaffold_pilot_bam_gamm_audit.csv"
  ),
  paste0(
    "artifacts/10_figures/H06/",
    "H06_exploratory_two_part_day_type_expected.pdf"
  ),
  paste0(
    "artifacts/10_figures/H06/",
    "H06_exploratory_two_part_activity_expected.pdf"
  ),
  paste0(
    "artifacts/12_manifests/H06/qa/",
    "H06_v0_scaffold_pilot_effects_A4_preview.pdf"
  )
)
manifest_required <- artifact_manifest[
  match(required_manifest_paths, artifact_manifest$path),
  ,
  drop = FALSE
]
manifest_files <- file.path(root, manifest_required$path)
observed_hashes <- vapply(manifest_files, artifact_sha256, character(1))
stopifnot(
  !anyNA(manifest_required$path),
  all(file.exists(manifest_files)),
  identical(unname(observed_hashes), manifest_required$sha256),
  !any(grepl(
    "artifacts/10_figures/H06/.*A4_preview",
    artifact_manifest$path
  ))
)

message("H06 GAMM amendment tests passed")
