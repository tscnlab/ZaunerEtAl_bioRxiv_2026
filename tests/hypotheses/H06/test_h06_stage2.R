# Focused structural and analytical-contract tests for H06-002 Stage 2.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_modeling.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_robust_modeling.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))
h06_validate_contract()

formulas <- h06_formula_set()
formula_text <- vapply(
  formulas,
  function(formula) paste(deparse(formula), collapse = " "),
  character(1)
)
formula_text <- gsub("[[:space:]]+", " ", formula_text)
stopifnot(
  length(formulas) == 10L,
  identical(
    formula_text[["additive"]],
    paste(
      "response_value ~ site + work_free_day + activity_status +",
      "previous_sleep_duration_centered_h"
    )
  ),
  identical(
    formula_text[["full"]],
    paste(
      "response_value ~ site * work_free_day + site * activity_status +",
      "site * previous_sleep_duration_centered_h"
    )
  ),
  !any(grepl("\\|", formula_text)),
  !any(grepl("ar1", formula_text, fixed = TRUE)),
  !any(grepl("clock_hour", formula_text, fixed = TRUE)),
  !any(grepl("exercise_intensity", formula_text, fixed = TRUE)),
  identical(
    h06_activity_levels(),
    c(
      "Sedentary (no reported exercise)",
      "Active (light, moderate, or vigorous exercise)"
    )
  )
)

input_contract <- h06_input_contract(root)
stopifnot(
  identical(
    input_contract$expected_sha256[
      input_contract$input_role == "approved_stage1_source"
    ],
    "393fd87c908302c1681925dcc451b27be31e652758592da8a81c775ff09aaf26"
  ),
  identical(
    input_contract$expected_sha256[
      input_contract$input_role == "approved_stage1_render"
    ],
    "186ab355deb0ba41f276c55c0490e9e0edbe7be1060c40fe2f4c366ed8eee8ae"
  ),
  identical(
    input_contract$expected_sha256[
      input_contract$input_role == "stage2_gate_decision"
    ],
    "882057ec11ce5e6a56d5b7268b3b501d372c2ec5a34de21a1ef0fa4ebcf07a52"
  ),
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

model_data <- file.path(root, "artifacts/06_model_data/H06")
models <- file.path(root, "artifacts/07_models/H06")
diagnostics <- file.path(root, "artifacts/08_diagnostics/H06")
tables <- file.path(root, "artifacts/09_tables/H06")
figures <- file.path(root, "artifacts/10_figures/H06")
source_data <- file.path(root, "artifacts/11_source_data/H06")
manifests <- file.path(root, "artifacts/12_manifests/H06")

read_h06_csv <- function(directory, filename) {
  readr::read_csv(
    file.path(directory, filename),
    show_col_types = FALSE,
    na = ""
  )
}

samples <- read_h06_csv(model_data, "H06_exact_samples.csv")
expected_counts <- c(
  main__glasses__all_available = 16596L,
  main__chest__all_available = 18352L,
  main__glasses__paired_common = 12842L,
  main__chest__paired_common = 12842L,
  gap_timing_unaware__glasses__all_available = 16329L,
  gap_timing_unaware__chest__all_available = 18112L
)
observed_counts <- stats::setNames(
  samples$one_hour_observations,
  samples$run_id
)
stopifnot(
  nrow(samples) == 6L,
  isTRUE(all.equal(
    unname(observed_counts[names(expected_counts)]),
    as.numeric(unname(expected_counts)),
    check.attributes = FALSE
  )),
  all(samples$sites >= 8L),
  all(samples$minimum_supported_hours_per_day >= 19L),
  all(samples$maximum_supported_hours_per_day == 24L)
)

for (run_id in samples$run_id) {
  frame <- readRDS(file.path(model_data, paste0(run_id, "__frame.rds")))
  stopifnot(
    nrow(frame) == samples$one_hour_observations[samples$run_id == run_id],
    !anyDuplicated(frame$.model_row_id),
    all(frame$interval_seconds %in% c(3600, 7200)),
    all(frame$AR_start == (frame$hour_sequence_position == 1L)),
    identical(
      h06_model_frame_hash(frame),
      samples$frame_sha256[samples$run_id == run_id]
    )
  )
}

tum_rows <- read_h06_csv(model_data, "H06_TUM_S001_assertion.csv")
tum_summary <- read_h06_csv(model_data, "H06_TUM_identity_summary.csv")
knust <- read_h06_csv(model_data, "H06_KNUST_S005_exploratory_adapter.csv")
stopifnot(
  nrow(tum_rows) == 7L,
  all(tum_rows$Id == "TUM_S001"),
  nrow(tum_summary) == 1L,
  tum_summary$tum_s001_rows == 7L,
  tum_summary$tum_s101_rows == 0L,
  !tum_summary$local_identifier_rewrite,
  tum_summary$assertion_pass,
  nrow(knust) == 1L,
  knust$Id == "KNUST_S005",
  knust$sedentary_source_minutes == 3600,
  knust$sedentary_h == 1,
  grepl("3,600 seconds", knust$sedentary_reinterpretation, fixed = TRUE)
)

fit_diagnostics <- read_h06_csv(
  diagnostics,
  "H06_robust_fit_diagnostics.csv"
)
stopifnot(
  nrow(fit_diagnostics) == 12L,
  all(fit_diagnostics$working_power == 1),
  all(fit_diagnostics$converged),
  all(fit_diagnostics$full_rank),
  all(fit_diagnostics$finite_coefficients),
  all(fit_diagnostics$hc3_covariance_finite),
  all(fit_diagnostics$hc3_covariance_positive_definite),
  all(fit_diagnostics$numerical_gate_pass),
  all(is.na(fit_diagnostics$fit_error)),
  max(fit_diagnostics$hc3_covariance_condition_number) < 7000
)

covariance_diagnostics <- read_h06_csv(
  diagnostics,
  "H06_robust_covariance_diagnostics.csv"
)
stopifnot(
  nrow(covariance_diagnostics) == 48L,
  identical(
    sort(unique(covariance_diagnostics$covariance_type)),
    c("HC0", "HC1", "HC2", "HC3")
  ),
  all(table(covariance_diagnostics$covariance_type) == 12L),
  all(covariance_diagnostics$finite),
  all(covariance_diagnostics$positive_definite),
  all(is.na(covariance_diagnostics$covariance_error))
)

wald <- read_h06_csv(tables, "H06_robust_wald_tests.csv")
stopifnot(
  nrow(wald) == 12L,
  all(table(wald$family_id) == 3L),
  all(wald$planned_size == 3L),
  all(wald$available_rank == 3L),
  all(wald$status == "ESTIMABLE"),
  all(wald$covariance_type == "HC3"),
  all(wald$clusters == 137L),
  all(wald$denominator_df == 136L),
  all(wald$p_adjusted >= wald$p_raw - 1e-15)
)
for (family in unique(wald$family_id)) {
  rows <- wald[wald$family_id == family, ]
  stopifnot(isTRUE(all.equal(
    rows$p_adjusted,
    stats::p.adjust(rows$p_raw, method = "BH", n = 3L),
    tolerance = 1e-12
  )))
}

f3 <- read_h06_csv(tables, "H06_robust_F3_practical_contrasts.csv")
stopifnot(
  nrow(f3) == 3L,
  all(f3$family_id == "H06-F3-practical-contrasts"),
  all(f3$distribution == "equal_site"),
  isTRUE(all.equal(
    f3$p_adjusted,
    stats::p.adjust(f3$p_raw, method = "BH", n = 3L),
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    f3$estimate_ratio,
    c(1.4511694, 2.0620958, 0.9777939),
    tolerance = 1e-6
  ))
)

gap_samples <- read_h06_csv(model_data, "H06_gap_exact_common_samples.csv")
gap_fit <- read_h06_csv(
  diagnostics,
  "H06_robust_gap_exact_common_fit_diagnostics.csv"
)
gap_wald <- read_h06_csv(
  tables,
  "H06_robust_gap_exact_common_wald_tests.csv"
)
stopifnot(
  nrow(gap_samples) == 2L,
  all(gap_samples$exact_common_hours == c(16329L, 18112L)),
  all(gap_samples$primary_only_hours == c(267L, 240L)),
  all(gap_samples$gap_timing_unaware_only_hours == 0L),
  nrow(gap_fit) == 8L,
  all(gap_fit$numerical_gate_pass),
  nrow(gap_wald) == 12L,
  all(gap_wald$status == "ESTIMABLE")
)

common_key <- c("site", "Id", "local_date", "clock_minute")
primary_common <- readRDS(file.path(
  model_data,
  "main__glasses__gap_exact_common__frame.rds"
))
gap_common <- readRDS(file.path(
  model_data,
  "gap_timing_unaware__glasses__gap_exact_common__frame.rds"
))
common_response <- primary_common |>
  dplyr::select(dplyr::all_of(common_key), "response_value") |>
  dplyr::rename(primary = "response_value") |>
  dplyr::inner_join(
    gap_common |>
      dplyr::select(dplyr::all_of(common_key), "response_value") |>
      dplyr::rename(gap = "response_value"),
    by = common_key,
    relationship = "one-to-one"
  )
stopifnot(
  nrow(common_response) == 16329L,
  sum(abs(common_response$primary - common_response$gap) > 1e-12) == 12L
)

sensitivity <- read_h06_csv(
  tables,
  "H06_robust_sensitivity_comparisons.csv"
)
stopifnot(
  nrow(sensitivity) == 30L,
  length(unique(sensitivity$comparison_id)) == 10L,
  all(table(sensitivity$comparison_id) == 3L),
  all(
    sensitivity$stability_classification == "stable within model uncertainty" |
      sensitivity$comparison_id == "quasi_poisson_vs_fixed_p1_8" &
        sensitivity$predictor_id == "work_free_day"
  ),
  sensitivity$stability_classification[
    sensitivity$comparison_id == "quasi_poisson_vs_fixed_p1_8" &
      sensitivity$predictor_id == "work_free_day"
  ] ==
    "multiplicity-conclusion-sensitive"
)

p18 <- read_h06_csv(tables, "H06_robust_p18_effects.csv") |>
  dplyr::filter(.data$run_id == "main__glasses__all_available")
p18_wald <- read_h06_csv(tables, "H06_robust_p18_wald_tests.csv") |>
  dplyr::filter(.data$run_id == "main__glasses__all_available")
stopifnot(
  nrow(p18) == 3L,
  isTRUE(all.equal(
    p18$estimate_ratio,
    c(1.1494066, 1.9104976, 0.9526663),
    tolerance = 1e-6
  )),
  p18_wald$p_adjusted[
    p18_wald$family_id == "H06-F2-heterogeneity" &
      p18_wald$predictor_id == "work_free_day"
  ] <
    0.05
)

weekend <- read_h06_csv(tables, "H06_robust_weekday_weekend_effects.csv")
exploratory <- read_h06_csv(tables, "H06_robust_exploratory_effects.csv")
stopifnot(
  nrow(weekend) == 3L,
  all(is.na(weekend$statistic)),
  all(is.na(weekend$p_raw)),
  nrow(exploratory) == 6L,
  all(
    exploratory$inferential_role ==
      "exploratory_estimate_and_95CI_no_p_value_screen"
  ),
  all(is.na(exploratory$p_raw))
)

influence <- read_h06_csv(
  diagnostics,
  "H06_robust_influence_deletions.csv"
) |>
  dplyr::mutate(
    ci_excludes_one = .data$deletion_conf_low_ratio > 1 |
      .data$deletion_conf_high_ratio < 1
  )
stopifnot(
  nrow(influence) == 48L,
  all(influence$additive_converged),
  all(influence$additive_full_rank),
  all(influence$additive_hc3_positive_definite),
  all(influence$full_converged),
  all(influence$full_design_full_rank),
  all(influence$full_hc3_positive_definite),
  sum(influence$ci_excludes_one[
    influence$predictor_id == "activity_status"
  ]) ==
    16L,
  sum(influence$ci_excludes_one[
    influence$predictor_id == "previous_sleep_duration_centered_h"
  ]) ==
    0L,
  sum(influence$ci_excludes_one[
    influence$predictor_id == "work_free_day" &
      influence$deletion_type == "participant"
  ]) ==
    7L,
  sum(influence$ci_excludes_one[
    influence$predictor_id == "work_free_day" &
      influence$deletion_type == "site"
  ]) ==
    7L
)

near_pair <- readRDS(file.path(
  model_data,
  "main__glasses__paired_common__frame.rds"
))
chest_pair <- readRDS(file.path(
  model_data,
  "main__chest__paired_common__frame.rds"
))
near_keys <- dplyr::distinct(
  near_pair,
  dplyr::across(dplyr::all_of(common_key))
)
chest_keys <- dplyr::distinct(
  chest_pair,
  dplyr::across(dplyr::all_of(common_key))
)
stopifnot(
  nrow(near_keys) == 12842L,
  nrow(chest_keys) == 12842L,
  nrow(dplyr::inner_join(near_keys, chest_keys, by = common_key)) == 12839L,
  nrow(dplyr::anti_join(near_keys, chest_keys, by = common_key)) == 3L,
  nrow(dplyr::anti_join(chest_keys, near_keys, by = common_key)) == 3L
)

v0_performance <- read_h06_csv(
  tables,
  "H06_current_pin_V0_method_performance.csv"
)
stopifnot(
  all(v0_performance$observations == c(16500L, 18218L)),
  all(v0_performance$converged),
  all(v0_performance$positive_definite_hessian),
  !any(v0_performance$singular),
  all(v0_performance$convergence_code == 0L)
)

two_part <- readRDS(file.path(
  models,
  "H06_exploratory_time_of_day_two_part.rds"
))
two_part_fit <- read_h06_csv(
  diagnostics,
  "H06_exploratory_two_part_fit_summary.csv"
)
two_part_closure <- read_h06_csv(
  diagnostics,
  "H06_exploratory_two_part_cyclic_closure.csv"
)
stopifnot(
  identical(
    two_part$contract_version,
    paste0(
      "v3_two_part_cyclic_factor_by_group_equal_site_",
      "k16_selected_discrete_working_ar"
    )
  ),
  two_part$base_fits$occurrence$k == 16L,
  two_part$base_fits$positive_magnitude$k == 16L,
  two_part$lower_basis_sensitivity$occurrence$k == 12L,
  two_part$lower_basis_sensitivity$positive_magnitude$k == 12L,
  nrow(two_part_fit) == 4L,
  all(two_part_fit$converged),
  all(two_part_fit$discrete),
  all(two_part_fit$full_fixed_smooth_rank),
  max(two_part_closure$maximum_absolute_closure_difference) < 1e-12
)

h06_scripts <- list.files(
  file.path(root, "scripts/hypotheses/H06"),
  pattern = "[.]R$",
  full.names = TRUE
)
producer_text <- paste(
  unlist(lapply(h06_scripts, readLines, warn = FALSE), use.names = FALSE),
  collapse = "\n"
)
stopifnot(!grepl("discrete\\s*=\\s*FALSE", producer_text))

figure_qa <- read_h06_csv(
  manifests,
  "H06_stage2_figure_readability_qa.csv"
)
two_part_figure_qa <- read_h06_csv(
  manifests,
  "H06_exploratory_two_part_figure_readability_qa.csv"
)
all_figure_qa <- dplyr::bind_rows(figure_qa, two_part_figure_qa)
stopifnot(
  nrow(all_figure_qa) == 7L,
  all(all_figure_qa$native_width_mm == 170),
  all(all_figure_qa$intended_print_display_width_mm == 170),
  all(all_figure_qa$scale_factor == 1),
  all(all_figure_qa$effective_final_text_pt >= 7),
  all(all_figure_qa$report_011_status == "PASS"),
  all(grepl("PASS at 170 mm", all_figure_qa$physical_size_inspection))
)

required_reader_files <- c(
  file.path(
    figures,
    paste0(
      c(
        "H06_core_effects",
        "H06_primary_site_effects",
        "H06_V0_comparison",
        "H06_primary_residual_clock",
        "H06_paired_placement_effects",
        "H06_exploratory_two_part_day_type_expected",
        "H06_exploratory_two_part_activity_expected"
      ),
      ".png"
    )
  ),
  file.path(
    source_data,
    paste0(
      c(
        "H06_core_effects_figure",
        "H06_primary_site_effects_figure",
        "H06_V0_comparison_figure",
        "H06_primary_residual_clock_figure",
        "H06_paired_placement_effects_figure",
        "H06_exploratory_two_part_day_type_expected_figure",
        "H06_exploratory_two_part_activity_expected_figure"
      ),
      ".csv"
    )
  )
)
stopifnot(all(file.exists(required_reader_files)))

report_qmd <- file.path(
  root,
  "audit/hypotheses/H06/02_implementation_and_v0_comparison.qmd"
)
report_html <- sub("[.]qmd$", ".html", report_qmd)
report_text <- paste(readLines(report_qmd, warn = FALSE), collapse = "\n")
html_text <- paste(readLines(report_html, warn = FALSE), collapse = "\n")
stopifnot(
  file.exists(report_html),
  grepl("H06-G2 author-review gate", html_text, fixed = TRUE),
  grepl(
    "Neither reconstructed V0 model is singular",
    report_text,
    fixed = TRUE
  ),
  grepl("Stage 3 remains blocked", report_text, fixed = TRUE),
  !grepl("H06_likelihood_ratio_tests.csv", report_text, fixed = TRUE),
  !grepl("H06_model_manifest.csv", report_text, fixed = TRUE),
  !grepl("H06_DHARMa_100_simulations.csv", report_text, fixed = TRUE)
)

message("H06-002 Stage 2 focused tests passed")
