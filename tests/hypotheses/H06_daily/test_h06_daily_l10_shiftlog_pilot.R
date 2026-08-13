#!/usr/bin/env Rscript

# Focused no-refit verification of the H06-D-003 shifted-log pilot gate.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
required_packages <- c("digest", "dplyr", "glmmTMB", "lme4", "readr")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}
read_csv <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}
read_diagnostic <- function(file) {
  read_csv(file.path(
    "artifacts/08_diagnostics/H06_daily",
    file
  ))
}
read_table <- function(file) {
  read_csv(file.path("artifacts/09_tables/H06_daily", file))
}
near <- function(observed, expected, tolerance = 1e-7) {
  isTRUE(all.equal(
    unname(observed),
    unname(expected),
    tolerance = tolerance,
    check.attributes = FALSE
  ))
}
verify_manifest <- function(relative_path) {
  manifest <- read_csv(relative_path)
  absolute <- file.path(root, manifest$relative_path)
  stopifnot(
    nrow(manifest) > 0L,
    all(file.exists(absolute)),
    identical(
      unname(vapply(absolute, sha256, character(1))),
      manifest$sha256
    ),
    identical(unname(file.info(absolute)$size), manifest$bytes)
  )
  manifest
}

decision_path <- file.path(
  root,
  "audit/decisions/h06_daily_l10_shifted_log_amendment.md"
)
decision_text <- paste(readLines(decision_path, warn = FALSE), collapse = "\n")
stopifnot(
  sha256(decision_path) ==
    "4ddc2cd9ebdf0c98ca5ef7b56b0965e0c661dc85680db34bcfbde6b61342ec3a",
  grepl("Decision ID: `H06-D-003`", decision_text, fixed = TRUE),
  grepl("Gate: `H06-D-G2P-L10-SHIFTLOG`", decision_text, fixed = TRUE)
)

input_contract <- read_diagnostic(
  "H06_daily_l10_shiftlog_input_contract.csv"
)
stopifnot(
  nrow(input_contract) == 14L,
  all(input_contract$identity_pass),
  identical(input_contract$expected_sha256, input_contract$actual_sha256)
)

samples <- read_table("H06_daily_l10_shiftlog_pilot_samples.csv")
stopifnot(
  nrow(samples) == 3L,
  identical(
    samples$predictor_id,
    c(
      "work_free_day",
      "activity_status",
      "previous_sleep_duration_centered_h"
    )
  ),
  identical(as.integer(samples$participant_days), c(784L, 734L, 784L)),
  identical(as.integer(samples$participants), c(141L, 137L, 141L)),
  all(samples$sites == 9L),
  identical(as.integer(samples$exact_zeros), c(107L, 92L, 107L)),
  identical(as.integer(samples$positive_values), c(677L, 642L, 677L)),
  near(samples$exact_zero_fraction, c(107 / 784, 92 / 734, 107 / 784))
)
for (index in seq_len(nrow(samples))) {
  path <- file.path(root, samples$frame_path[[index]])
  frame <- readRDS(path)
  stopifnot(
    sha256(path) == samples$frame_file_sha256[[index]],
    object_sha256(frame) == samples$frame_object_sha256[[index]],
    nrow(frame) == samples$participant_days[[index]],
    identical(frame$response_value, log10(frame$response_source + 0.1)),
    all(frame$response_value[frame$response_source == 0] == -1)
  )
}

effects <- read_table("H06_daily_l10_shiftlog_pilot_effects.csv")
gaussian <- effects |>
  dplyr::filter(grepl("^Gaussian", .data$family)) |>
  dplyr::arrange(.data$predictor_order)
student_t <- effects |>
  dplyr::filter(grepl("^Student-t", .data$family)) |>
  dplyr::arrange(.data$predictor_order)
stopifnot(
  nrow(effects) == 6L,
  nrow(gaussian) == 3L,
  nrow(student_t) == 3L,
  all(effects$interval_type == "model-based pointwise 95% confidence interval"),
  all(grepl("not an unshifted raw-L10 ratio", effects$effect_scale)),
  near(
    gaussian$shifted_geometric_mean_ratio,
    c(0.9883529, 0.9287157, 0.8989508)
  ),
  near(gaussian$ratio_lower_95, c(0.9175317, 0.8446951, 0.8755535)),
  near(gaussian$ratio_upper_95, c(1.0646405, 1.0210936, 0.9229734)),
  near(
    student_t$shifted_geometric_mean_ratio,
    c(0.9669599, 0.9882642, 0.9139328)
  )
)

model_tests <- read_table("H06_daily_l10_shiftlog_pilot_model_tests.csv") |>
  dplyr::arrange(.data$predictor_order, .data$test_type)
expected_p <- c(
  0.7504179,
  0.01562982,
  0.1245559,
  0.003772416,
  5.935529e-15,
  0.02766125
)
stopifnot(
  nrow(model_tests) == 6L,
  all(model_tests$metric_slot == 3L),
  all(model_tests$test_status == "ESTIMABLE_PILOT_RAW_ONLY"),
  all(model_tests$multiplicity_status == "PILOT_RAW_ONLY_NO_BH_UPDATE"),
  all(is.na(model_tests$bh_adjusted_p_value)),
  all(is.na(model_tests$adjusted_decision)),
  near(model_tests$raw_p_value, expected_p, tolerance = 1e-6)
)

diagnostics <- read_diagnostic(
  "H06_daily_l10_shiftlog_pilot_diagnostics.csv"
)
stopifnot(
  nrow(diagnostics) == 3L,
  all(diagnostics$numerical_disposition == "ACCEPTABLE"),
  all(diagnostics$converged),
  all(diagnostics$positive_definite_hessian),
  !any(diagnostics$singular),
  all(
    diagnostics$residual_disposition ==
      "ACCEPTABLE_ONLY_WITH_GAUSSIAN_RESIDUAL_LIMITATION"
  ),
  identical(
    diagnostics$bound_disposition,
    c(
      "ACCEPTABLE",
      "ACCEPTABLE",
      "ACCEPTABLE_ONLY_WITH_NEGATIVE_BACK_TRANSFORM_LIMITATION"
    )
  ),
  all(
    diagnostics$zero_mass_disposition ==
      "OPEN_AUTHOR_DISPOSITION_ZERO_MASS_GE_10_PERCENT"
  ),
  all(diagnostics$residual_qq_correlation > 0.97),
  all(diagnostics$residual_variance_ratio > 6),
  all(diagnostics$residual_variance_ratio < 8),
  all(diagnostics$standardized_residual_gt4_fraction < 0.01),
  diagnostics$raw_back_transform_below_zero_fraction[[3L]] > 0.02,
  all(diagnostics$raw_back_transform_below_minus_0_05_fraction == 0)
)

family <- read_diagnostic(
  "H06_daily_l10_shiftlog_pilot_family_sensitivity.csv"
)
stopifnot(
  nrow(family) == 3L,
  !any(family$direction_reversal),
  near(family$effect_shift_in_gaussian_se, c(0.5768377, 1.2845171, 1.2284100)),
  identical(
    family$family_sensitivity_disposition,
    c(
      "ACCEPTABLE_ONLY_WITH_FAMILY_SENSITIVITY_LIMITATION",
      "ACCEPTABLE_ONLY_WITH_MAJOR_FAMILY_SENSITIVITY_LIMITATION",
      "ACCEPTABLE_ONLY_WITH_MAJOR_FAMILY_SENSITIVITY_LIMITATION"
    )
  )
)

lag <- read_diagnostic("H06_daily_l10_shiftlog_pilot_residual_lag.csv")
lag_by_site <- read_diagnostic(
  "H06_daily_l10_shiftlog_pilot_site_residual_lag.csv"
)
post_ar_by_site <- read_diagnostic(
  "H06_daily_l10_shiftlog_pilot_post_ar_site_residual_lag.csv"
)
ar <- read_diagnostic("H06_daily_l10_shiftlog_pilot_ar_counterparts.csv")
stopifnot(
  nrow(lag) == 3L,
  nrow(lag_by_site) == 27L,
  nrow(post_ar_by_site) == 27L,
  all(lag$ar_trigger),
  all(lag$ar_support_adequate),
  identical(as.integer(lag$adjacent_pairs), c(612L, 554L, 612L)),
  identical(as.integer(lag$participants), c(139L, 133L, 139L)),
  all(abs(lag$residual_lag1) < 0.10),
  all(lag$maximum_absolute_site_lag1 >= 0.30),
  all(ar$independent_engine_converged),
  all(ar$independent_engine_positive_definite_hessian),
  !any(ar$independent_engine_singular),
  all(ar$ar_converged),
  all(ar$ar_positive_definite_hessian),
  !any(ar$ar_singular),
  all(ar$ar_minimum_random_effect_standard_deviation > 0.12),
  all(ar$ar_minimum_scaled_covariance_eigenvalue > 0.08),
  all(abs(ar$ar_rho) < 0.95),
  all(ar$ar_effect_shift_in_gaussian_se < 1),
  all(abs(ar$post_ar_residual_lag1) >= 0.20),
  all(ar$post_ar_maximum_absolute_site_lag1 >= 0.30),
  all(ar$ar_disposition == "NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE")
)
worst_post_ar <- post_ar_by_site |>
  dplyr::group_by(.data$predictor_id) |>
  dplyr::slice_max(abs(.data$residual_lag1), n = 1L, with_ties = FALSE) |>
  dplyr::ungroup()
stopifnot(
  nrow(worst_post_ar) == 3L,
  all(worst_post_ar$site == "MPI"),
  setequal(as.integer(worst_post_ar$adjacent_pairs), c(115L, 119L)),
  all(worst_post_ar$participants == 26L)
)

registered <- read_diagnostic(
  "H06_daily_l10_shiftlog_pilot_registered_benchmark.csv"
)
stopifnot(
  nrow(registered) == 3L,
  identical(
    registered$disposition,
    c(
      "ESTIMABLE_BENCHMARK_ONLY",
      "ESTIMABLE_BENCHMARK_ONLY",
      "NON_ESTIMABLE_BENCHMARK"
    )
  ),
  all(grepl("never promoted", registered$inferential_role))
)

equal_site <- read_table(
  "H06_daily_l10_shiftlog_pilot_equal_site_estimates.csv"
)
equal_site_contrasts <- read_table(
  "H06_daily_l10_shiftlog_pilot_equal_site_contrasts.csv"
)
stopifnot(
  nrow(equal_site) == 6L,
  nrow(equal_site_contrasts) == 3L,
  all(
    equal_site$interval_type == "model-based pointwise 95% confidence interval"
  ),
  all(equal_site$clipping_rule == "unclipped 10^eta - 0.1 lx"),
  !any(equal_site$negative_point_back_transform),
  near(
    equal_site$equal_site_raw_back_transform_lx,
    c(
      0.15431634620975304,
      0.15135429050767699,
      0.16963030535007140,
      0.15040988720283693,
      0.14877930333209383,
      0.12364036507859208
    )
  )
)

verdict <- read_diagnostic("H06_daily_l10_shiftlog_pilot_verdict.csv")
runtime <- read_diagnostic(
  "H06_daily_l10_shiftlog_pilot_runtime_projection.csv"
)
stopifnot(
  nrow(verdict) == 3L,
  all(verdict$overall_pilot_disposition == "NOT_ACCEPTABLE"),
  all(verdict$recommendation == "DO_NOT_RELEASE_FULL_L10_SHIFTED_LOG_BATCH"),
  nrow(runtime) == 1L,
  runtime$pilot_predictors == 3L,
  runtime$pilot_scenarios == 1L,
  runtime$reused_additive_reml_objects == 3L,
  runtime$triggered_ar_predictors == 3L,
  runtime$pilot_wall_seconds > 0,
  runtime$projected_full_seconds > 0,
  runtime$projected_full_seconds < 120,
  runtime$projected_full_predictor_scenarios == 18L,
  runtime$projected_influence_refits == 440L
)

provenance <- read_diagnostic(
  "H06_daily_l10_shiftlog_pilot_model_provenance.csv"
)
bundle_path <- file.path(
  root,
  "artifacts/07_models/H06_daily/H06_daily_l10_shiftlog_pilot_new_models.rds"
)
bundle <- readRDS(bundle_path)
stopifnot(
  nrow(provenance) == 3L,
  all(provenance$reuse_verified),
  !any(provenance$relabel_refit_performed),
  all(
    provenance$reuse_disposition ==
      "REUSE_EXACT_HISTORICAL_REML_ADDITIVE_OBJECT"
  ),
  identical(sort(names(bundle$new_models)), sort(samples$predictor_id)),
  all(vapply(
    bundle$new_models,
    function(entry) {
      !"gaussian_reml" %in% names(entry) &&
        !is.null(entry$reduced_ml$value) &&
        !is.null(entry$additive_ml$value) &&
        !is.null(entry$heterogeneity_ml$value) &&
        !is.null(entry$student_t$value) &&
        !is.null(entry$registered_benchmark$value) &&
        !is.null(entry$independent_glmmtmb$value) &&
        !is.null(entry$ar$value)
    },
    logical(1)
  ))
)

historical <- read_diagnostic(
  "H06_daily_l10_shiftlog_historical_preservation_final.csv"
)
stopifnot(
  nrow(historical) == 118L,
  all(historical$preserved_final),
  all(
    vapply(
      file.path(root, historical$relative_path),
      sha256,
      character(1)
    ) ==
      historical$sha256
  ),
  sha256(file.path(
    root,
    "audit/hypotheses/H06_daily/08_l10_metric011_amendment.qmd"
  )) ==
    "2a13894ed53f0cbe660f2855e3f994ce2041d6408ac36b650a0a4bbff2d6cade",
  sha256(file.path(
    root,
    "audit/hypotheses/H06_daily/08_l10_metric011_amendment.html"
  )) ==
    "db255bc7d5aba1f71fa8c42ab4de0ebef3807210d45c99f805cfad6074b8a109"
)

forbidden <- unlist(lapply(
  c(
    "artifacts/06_model_data/H06_daily",
    "artifacts/07_models/H06_daily",
    "artifacts/08_diagnostics/H06_daily",
    "artifacts/09_tables/H06_daily",
    "artifacts/10_figures/H06_daily",
    "artifacts/11_source_data/H06_daily"
  ),
  function(directory) {
    list.files(
      file.path(root, directory),
      pattern = "^H06_daily_l10_shiftlog_(production|influence|bh)",
      full.names = TRUE
    )
  }
))
stopifnot(length(forbidden) == 0L)

report_source <- file.path(
  root,
  "audit/hypotheses/H06_daily/09_l10_shiftlog_pilot.qmd"
)
report_html <- sub("[.]qmd$", ".html", report_source)
report_text <- paste(readLines(report_source, warn = FALSE), collapse = "\n")
html_text <- paste(readLines(report_html, warn = FALSE), collapse = "\n")
stopifnot(
  file.exists(report_source),
  file.exists(report_html),
  grepl("Answer in brief", report_text, fixed = TRUE),
  grepl("\\log_{10}", report_text, fixed = TRUE),
  grepl("pointwise", report_text, fixed = TRUE),
  grepl("not simultaneous", report_text, fixed = TRUE),
  grepl("DO NOT release", report_text, fixed = TRUE),
  grepl("PILOT_RAW_ONLY_NO_BH_UPDATE", report_text, fixed = TRUE),
  grepl("H06-D-G2P-L10-SHIFTLOG", html_text, fixed = TRUE),
  !grepl("[ Z = _{10}(Y + 0.1 ). ]", html_text, fixed = TRUE)
)

manifest_paths <- file.path(
  "artifacts/12_manifests/H06_daily",
  paste0(
    "H06_daily_l10_shiftlog_pilot_",
    c("input", "code", "output"),
    "_manifest.csv"
  )
)
manifests <- lapply(manifest_paths, verify_manifest)
names(manifests) <- c("input", "code", "output")
software <- read_csv(file.path(
  "artifacts/12_manifests/H06_daily",
  "H06_daily_l10_shiftlog_pilot_software_manifest.csv"
))
report_manifest <- verify_manifest(file.path(
  "audit/hypotheses/H06_daily",
  "H06_daily_l10_shiftlog_pilot_report_manifest.csv"
))
stopifnot(
  nrow(manifests$input) >= 20L,
  nrow(manifests$code) >= 7L,
  nrow(manifests$output) >= 18L,
  nrow(software) >= 10L,
  software$version[software$software == "R"] == "4.6.1",
  all(c("glmmTMB", "lme4", "Quarto") %in% software$software),
  nrow(report_manifest) > nrow(manifests$output)
)

cat(
  paste0(
    "H06-D-003 shifted-log pilot tests passed: 3 exact reused REML objects; ",
    "3 samples; 6 raw-only tests with no BH update; 3 triggered AR fits ",
    "numerically valid but failing post-AR residual dependence; 118 ",
    "historical entries preserved; full batch remains stopped.\n"
  )
)
