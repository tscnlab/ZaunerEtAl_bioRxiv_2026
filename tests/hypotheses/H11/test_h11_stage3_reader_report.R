# Focused integrity and rendered-structure tests for the H11 Stage 3 report.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(xml2)
})

options(stringsAsFactors = FALSE, scipen = 999)

test_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(test_argument) != 1L) {
  stop("Could not determine the H11 Stage 3 test location", call. = FALSE)
}
test_path <- normalizePath(
  sub("^--file=", "", test_argument),
  winslash = "/",
  mustWork = TRUE
)
root <- dirname(dirname(dirname(dirname(test_path))))
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

read_h11 <- function(relative_path) {
  path <- file.path(root, relative_path)
  stopifnot(file.exists(path), file.info(path)$size > 0)
  readr::read_csv(path, show_col_types = FALSE)
}

message("Testing frozen-result selection and exact fitted samples")
samples <- read_h11(
  "artifacts/09_tables/H11/stage3/H11_reader_samples.csv"
)
expected_samples <- tibble::tribble(
  ~run_id, ~participants, ~female_participants, ~male_participants,
  ~participant_days, ~observations_30_minute, ~sites,
  "main__glasses__all_available", 141L, 79L, 62L, 816L, 37756L, 9L,
  "main__chest__all_available", 154L, 86L, 68L, 902L, 41842L, 8L,
  "manuscript_prepared_data__glasses__all_available",
  141L, 79L, 62L, 809L, 37603L, 9L,
  "manuscript_prepared_data__chest__all_available",
  154L, 86L, 68L, 894L, 41664L, 8L
)
observed_samples <- samples |>
  dplyr::select(dplyr::all_of(names(expected_samples)))
stopifnot(
  nrow(samples) == 4L,
  isTRUE(all.equal(
    observed_samples,
    expected_samples,
    check.attributes = FALSE
  )),
  identical(
    samples$reader_role,
    c("Primary", "Complementary", "Sensitivity", "Sensitivity")
  )
)

reconciliation <- read_h11(
  "artifacts/06_model_data/H11/stage3/H11_stage2_identity_reconciliation.csv"
)
stopifnot(
  nrow(reconciliation) == 113L,
  all(reconciliation$identity_status %in% c(
    "unchanged",
    "authorized_non_scientific_post_stage2_update"
  )),
  setequal(
    reconciliation$path[
      reconciliation$identity_status ==
        "authorized_non_scientific_post_stage2_update"
    ],
    c(
      "audit/decisions/figure_readability_and_layout.md",
      "audit/decisions/model_reporting.md",
      "audit/hypotheses/implementation_result_comparison_contract.qmd",
      "audit/handoffs/H11_shared_change_request.md",
      "audit/handoffs/H11_worker_handoff.md"
    )
  )
)

message("Testing accepted inferential decisions and pointwise uncertainty")
global_tests <- read_h11(
  "artifacts/09_tables/H11/stage3/H11_reader_global_tests.csv"
)
decomposition <- read_h11(
  "artifacts/09_tables/H11/stage3/H11_reader_level_shape_decomposition.csv"
)
parametric <- read_h11(
  "artifacts/09_tables/H11/stage3/H11_reader_parametric_level_estimates.csv"
)
curve_effects <- read_h11(
  "artifacts/09_tables/H11/stage3/H11_reader_curve_variation_effect_size.csv"
)
pointwise <- read_h11(
  "artifacts/09_tables/H11/stage3/H11_reader_pointwise_context.csv"
)
curves <- read_h11(
  "artifacts/11_source_data/H11/stage3/H11_reader_sex_specific_curves.csv"
)
contrasts <- read_h11(
  "artifacts/11_source_data/H11/stage3/H11_reader_female_minus_male_contrasts.csv"
)

global_display <- nh_p_value_display(
  global_tests$p_adjusted,
  significant = global_tests$p_adjusted < 0.05
)
stopifnot(
  nrow(global_tests) == 4L,
  all(global_tests$p_adjusted < 0.05),
  all(global_tests$support_status == "supported"),
  identical(
    global_display$p_display,
    c("0.028", "0.029", "0.026", "0.037")
  ),
  all(global_display$p_bold),
  nrow(decomposition) == 8L,
  !any(decomposition$p_adjusted < 0.05),
  nrow(parametric) == 2L,
  nrow(curve_effects) == 2L,
  all(startsWith(parametric$run_id, "main__")),
  all(startsWith(curve_effects$run_id, "main__")),
  all(parametric$ratio_lower_95 <= parametric$female_to_male_shifted_ratio),
  all(parametric$ratio_upper_95 >= parametric$female_to_male_shifted_ratio),
  all(curve_effects$lower_95 <= curve_effects$estimate),
  all(curve_effects$upper_95 >= curve_effects$estimate),
  nrow(pointwise) == 4L,
  all(pointwise$displayed_bins == 48L),
  substr(as.character(pointwise$minimum_clock[
    pointwise$run_id == "main__glasses__all_available"
  ]), 1L, 5L) == "08:45",
  substr(as.character(pointwise$maximum_clock[
    pointwise$run_id == "main__glasses__all_available"
  ]), 1L, 5L) == "22:15",
  nrow(curves) == 384L,
  nrow(contrasts) == 192L,
  all(grepl("pointwise", curves$interval_scope, fixed = TRUE)),
  all(grepl("not simultaneous", curves$interval_scope, fixed = TRUE)),
  all(contrasts$ratio_lower_pointwise_95 <=
    contrasts$female_to_male_shifted_ratio),
  all(contrasts$ratio_upper_pointwise_95 >=
    contrasts$female_to_male_shifted_ratio)
)

message("Testing exploratory same-sample activity-context sensitivity")
activity_samples <- read_h11(
  "artifacts/09_tables/H11/stage3/H11_reader_activity_samples.csv"
)
activity_comparison <- read_h11(
  "artifacts/09_tables/H11/stage3/H11_reader_activity_global_comparison.csv"
)
activity_pointwise <- read_h11(
  "artifacts/09_tables/H11/stage3/H11_reader_activity_pointwise_context.csv"
)
activity_diagnostics <- read_h11(
  paste0(
    "artifacts/08_diagnostics/H11/stage3/",
    "H11_reader_activity_diagnostic_assessment.csv"
  )
)
activity_formulas <- read_h11(
  paste0(
    "artifacts/06_model_data/H11/stage3/",
    "H11_reader_activity_formula_registry.csv"
  )
)
activity_reconciliation <- read_h11(
  paste0(
    "artifacts/06_model_data/H11/stage3/",
    "H11_activity_identity_reconciliation.csv"
  )
)

activity_display <- nh_p_value_display(
  activity_comparison$p_adjusted,
  significant = activity_comparison$p_adjusted < 0.05
)
stopifnot(
  identical(activity_samples$participants, c(126, 150)),
  identical(activity_samples$female_participants, c(71, 83)),
  identical(activity_samples$male_participants, c(55, 67)),
  identical(activity_samples$participant_days, c(724, 875)),
  identical(activity_samples$observations_30_minute, c(30499, 36711)),
  identical(activity_samples$sites, c(9, 8)),
  nrow(activity_comparison) == 6L,
  identical(
    activity_display$p_display,
    c("0.028", "0.160", "0.364", "0.029", "0.025", "0.050")
  ),
  identical(
    activity_display$p_bold,
    c(TRUE, FALSE, FALSE, TRUE, TRUE, FALSE)
  ),
  activity_comparison$p_raw[
    activity_comparison$placement_label == "Chest" &
      activity_comparison$analysis_step == "Same sample, activity-adjusted"
  ] > 0.05,
  nrow(activity_pointwise) == 4L,
  all(activity_pointwise$displayed_bins == 48L),
  all(activity_pointwise$pointwise_bins_excluding_one[
    activity_pointwise$model_variant == "activity_adjusted"
  ] == 0L),
  nrow(activity_diagnostics) == 4L,
  all(activity_diagnostics$classification ==
    "acceptable with specified limitations"),
  all(activity_diagnostics$converged),
  all(activity_diagnostics$serious_warning_absent),
  nrow(activity_formulas) == 2L,
  setequal(
    activity_formulas$formula_id,
    c("restricted_unadjusted", "activity_adjusted")
  ),
  grepl(
    "activity +",
    activity_formulas$formula[
      activity_formulas$formula_id == "activity_adjusted"
    ],
    fixed = TRUE
  ),
  nrow(activity_reconciliation) == 48L,
  all(activity_reconciliation$identity_status == "unchanged")
)

stage3_reader_files <- list.files(
  file.path(root, "artifacts"),
  pattern = "H11_reader_",
  recursive = TRUE,
  full.names = FALSE
)
stage3_reader_files <- stage3_reader_files[
  grepl("/H11/stage3/", stage3_reader_files, fixed = TRUE)
]
stopifnot(
  length(stage3_reader_files) > 0L,
  !any(grepl("pilot|bootstrap", stage3_reader_files, ignore.case = TRUE))
)

message("Testing formula, diagnostics, and placement-display constraints")
formula <- read_h11(
  "artifacts/06_model_data/H11/stage3/H11_reader_formula_registry.csv"
)
stage2_formula <- read_h11(
  "artifacts/06_model_data/H11/stage2/formula_and_fit_manifest.csv"
) |>
  dplyr::filter(
    .data$data_scenario_id == "main",
    .data$placement == "glasses",
    .data$model_id == "mpattern_final_fREML"
  ) |>
  dplyr::distinct(.data$formula)
diagnostics <- read_h11(
  "artifacts/08_diagnostics/H11/stage3/H11_reader_diagnostic_assessment.csv"
)
robust_diagnostics <- read_h11(
  "artifacts/08_diagnostics/H11/stage3/H11_reader_robust_diagnostics.csv"
)
residual_summary <- read_h11(
  paste0(
    "artifacts/08_diagnostics/H11/stage3/",
    "H11_reader_primary_residual_summary.csv"
  )
)
placement <- read_h11(
  "artifacts/06_model_data/H11/stage3/H11_reader_placement_comparison_assessment.csv"
)
stopifnot(
  nrow(formula) == 1L,
  identical(formula$formula, stage2_formula$formula),
  formula$method == "fREML",
  formula$discrete,
  nrow(diagnostics) == 4L,
  all(diagnostics$classification ==
    "acceptable with specified limitations"),
  all(diagnostics$final_boundary_aware_lag1_correlation < 0.09),
  nrow(robust_diagnostics) == 4L,
  all(robust_diagnostics$maximum_participant_unscaled_meat_share < 0.08),
  nrow(residual_summary) == 6L,
  setequal(residual_summary$biological_sex, c("Overall", "Female", "Male")),
  all(abs(residual_summary$median) < 0.04),
  all(residual_summary$q01 < 0),
  all(residual_summary$q99 > 0),
  all(residual_summary$correlation_absolute_residual_fitted > 0.19),
  all(residual_summary$correlation_absolute_residual_fitted < 0.25),
  nrow(placement) == 1L,
  placement$stored_common_sample_participants == 112L,
  placement$stored_common_sample_participant_days == 643L,
  placement$stored_common_sample_observations == 29786L,
  placement$stored_common_sample_sites == 8L,
  !placement$common_sample_H11_fitted_outputs_available,
  !placement$predeclared_scalar_temporal_estimand_available,
  !placement$scalar_identity_plot_applicable,
  !placement$paired_source_data_created
)

message("Testing REPORT-011 physical-size figure evidence")
figure_manifest <- read_h11(
  "artifacts/12_manifests/H11/H11_stage3_figure_manifest.csv"
)
figure_qa <- read_h11(
  "artifacts/12_manifests/H11/H11_stage3_figure_readability_qa.csv"
)
proof_path <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_stage3_figure_A4_proofs.pdf"
)
old_proof_path <- file.path(
  root,
  "artifacts/10_figures/H11/stage3/H11_reader_figure_A4_proofs.pdf"
)
figure_builder <- paste(readLines(
  file.path(root, "scripts/hypotheses/H11/build_h11_stage3_figures.R"),
  warn = FALSE
), collapse = "\n")
stopifnot(
  nrow(figure_manifest) == 16L,
  nrow(figure_qa) == 8L,
  all(abs(figure_qa$base_width_in - 10.5) < 1e-12),
  all(abs(figure_qa$export_scale_multiplier - 1) < 1e-12),
  all(abs(figure_qa$export_width_in - 10.5) < 1e-12),
  all(abs(figure_qa$native_export_width_mm - 266.7) < 1e-8),
  all(figure_qa$intended_display_width_mm == 170),
  all(abs(figure_qa$display_reduction_factor - 170 / 266.7) < 1e-12),
  all(figure_qa$smallest_essential_nominal_text_pt == 12),
  all(figure_qa$effective_final_essential_text_pt >= 7),
  all(figure_qa$smallest_minor_nominal_text_pt == 11),
  all(figure_qa$effective_final_minor_text_pt >= 7),
  identical(as.integer(figure_qa$a4_proof_page), 1:8),
  all(figure_qa$a4_page_width_mm == 210),
  all(figure_qa$a4_side_margin_mm == 20),
  all(grepl("REPORT-011", figure_qa$policy_id, fixed = TRUE)),
  all(figure_qa$final_asset_canvas ==
    "tightly bounded to figure; A4 page excluded"),
  all(figure_qa$typography_status == "PASS"),
  all(figure_qa$visual_status == "PASS"),
  all(figure_qa$overall_status == "PASS"),
  all(figure_qa$clipping_or_cropping == "PASS"),
  all(figure_qa$overlaps == "PASS"),
  all(figure_qa$wrapping_and_units == "PASS"),
  all(figure_qa$marks_and_lines_distinguishable == "PASS"),
  file.exists(proof_path),
  file.info(proof_path)$size > 0,
  !file.exists(old_proof_path),
  all(
    figure_manifest$melEDI_display_transform[
      figure_manifest$figure_kind == "curve"
    ] == "LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)"
  ),
  grepl(
    "LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)",
    figure_builder,
    fixed = TRUE
  ),
  !grepl("pseudo_log_trans", figure_builder, fixed = TRUE),
  any(figure_manifest$figure_kind == "activity")
)

message("Testing reader-facing Quarto and rendered HTML")
qmd_path <- file.path(root, "notebooks/hypotheses/H11.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H11.html"
)
stopifnot(file.exists(qmd_path), file.exists(html_path))
qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl('title="Answer in brief"', qmd, fixed = TRUE),
  !grepl('title="Results in brief"', qmd, fixed = TRUE),
  grepl("participant-cluster-robust pointwise 95%", qmd, fixed = TRUE),
  grepl("They are not a leave-one-participant-out", qmd, fixed = TRUE) |
    grepl("not a leave-one-participant-out", qmd, fixed = TRUE),
  grepl("echo: true", qmd, fixed = TRUE),
  grepl("H11_reader_primary_near_eye_curves.png", qmd, fixed = TRUE),
  grepl("H11_reader_complementary_chest_curves.png", qmd, fixed = TRUE),
  grepl(
    "H11_reader_activity_context_female_to_male_curves.png",
    qmd,
    fixed = TRUE
  ),
  grepl("H11_reader_primary_residual_summary.png", qmd, fixed = TRUE),
  grepl("activity_h11_formulas", qmd, fixed = TRUE),
  grepl("does not make the global result invalid", qmd, fixed = TRUE),
  grepl("restriction precedes it", qmd, fixed = TRUE),
  !grepl("identity_plot.png", qmd, fixed = TRUE)
)

doc <- xml2::read_html(html_path)
main <- xml2::xml_find_first(doc, "//main")
if (inherits(main, "xml_missing")) {
  stop("Rendered H11 report has no main element", call. = FALSE)
}
main_text <- gsub("[[:space:]]+", " ", xml2::xml_text(main))
required_text <- c(
  "H11: Diurnal exposure patterns differ by sex.",
  "Answer in brief",
  "biological sex",
  "Gender is a distinct construct",
  "pointwise 95% intervals",
  "not simultaneous",
  "gap-timing-unaware dataset",
  "50%-per-hour and 80%-per-day coverage rules",
  "timing of the remaining missing observations",
  "time-sensitive primary metric dataset",
  "Why there is no direct placement identity plot",
  "Exploratory activity-context sensitivity",
  "Activity-complete sample, unadjusted",
  "Same sample, activity-adjusted",
  "sample restriction precedes it",
  "does not make the global result invalid",
  "0.050214",
  "linear from 0 to 1 lx",
  "acceptable with specified limitations"
)
stopifnot(all(vapply(
  required_text,
  function(value) grepl(value, main_text, fixed = TRUE),
  logical(1)
)))
forbidden_text <- c(
  "V0",
  "legacy",
  "manuscript-prepared",
  "alternative manuscript-prepared",
  "Results in brief"
)
stopifnot(!any(vapply(
  forbidden_text,
  function(value) grepl(value, main_text, fixed = TRUE),
  logical(1)
)))

reader_images <- xml2::xml_find_all(
  main,
  ".//img[contains(@src, 'H11_reader_')]"
)
reader_alt <- xml2::xml_attr(reader_images, "alt")
stopifnot(
  length(reader_images) == 8L,
  all(!is.na(reader_alt)),
  all(nzchar(reader_alt)),
  length(xml2::xml_find_all(main, ".//figcaption")) >= 8L
)

html_source <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("<strong>0.043</strong>", html_source, fixed = TRUE),
  grepl("<strong>0.029</strong>", html_source, fixed = TRUE),
  grepl("0.075", main_text, fixed = TRUE),
  grepl("0.057", main_text, fixed = TRUE),
  grepl("<strong>0.025</strong>", html_source, fixed = TRUE),
  !grepl("<strong>0.050</strong>", html_source, fixed = TRUE),
  !grepl("p = \\.[0-9]", main_text),
  !grepl("p-value = \\.[0-9]", main_text)
)

source_links <- xml2::xml_attr(
  xml2::xml_find_all(main, ".//a[contains(@href, 'H11_reader_')]"),
  "href"
)
stopifnot(
  length(source_links) >= 12L,
  all(vapply(source_links, function(href) {
    file.exists(normalizePath(
      file.path(dirname(html_path), href),
      winslash = "/",
      mustWork = FALSE
    ))
  }, logical(1)))
)

message("Testing the sealed Stage 3 inventory")
stage3_manifest <- read_h11(
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv"
)
manifest_paths <- file.path(root, stage3_manifest$path)
stopifnot(
  nrow(stage3_manifest) >= 50L,
  all(file.exists(manifest_paths)),
  all(stage3_manifest$r_version == "4.6.1"),
  all(stage3_manifest$sha256 == unname(vapply(
    manifest_paths,
    artifact_sha256,
    character(1)
  ))),
  any(stage3_manifest$role == "rendered_report"),
  any(stage3_manifest$role == "audit_or_gate"),
  any(stage3_manifest$path ==
    "audit/hypotheses/H11/05_reader_diagnostic_figure_addition.md"),
  any(stage3_manifest$role == "read_only_policy_input")
)

message("H11 Stage 3 reader report tests passed")
