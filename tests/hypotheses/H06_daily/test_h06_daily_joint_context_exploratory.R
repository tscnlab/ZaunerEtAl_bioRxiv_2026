#!/usr/bin/env Rscript

# Focused no-refit verification of the exploratory joint-context H06_daily
# analysis requested for the Stage 3 reader revision.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "readr")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing synchronized packages: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

read_project_csv <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}

assert(
  identical(as.character(getRversion()), "4.6.1"),
  "The joint-context verification requires R 4.6.1"
)

manifest_dir <- "artifacts/12_manifests/H06_daily"
input_manifest <- read_project_csv(file.path(
  manifest_dir,
  "H06_daily_joint_context_exploratory_input_manifest.csv"
))
output_manifest <- read_project_csv(file.path(
  manifest_dir,
  "H06_daily_joint_context_exploratory_output_manifest.csv"
))
effects <- read_project_csv(
  "artifacts/09_tables/H06_daily/H06_daily_joint_context_exploratory_effects_long.csv"
)
tests <- read_project_csv(
  "artifacts/09_tables/H06_daily/H06_daily_joint_context_exploratory_tests.csv"
)
families <- read_project_csv(
  "artifacts/09_tables/H06_daily/H06_daily_joint_context_exploratory_family_summary.csv"
)
stability <- read_project_csv(
  "artifacts/11_source_data/H06_daily/H06_daily_joint_context_exploratory_stability.csv"
)
site_estimates <- read_project_csv(
  "artifacts/11_source_data/H06_daily/H06_daily_joint_context_exploratory_site_estimates.csv"
)
diagnostics <- read_project_csv(
  "artifacts/08_diagnostics/H06_daily/H06_daily_joint_context_exploratory_diagnostics.csv"
)
visual_review <- read_project_csv(
  "artifacts/08_diagnostics/H06_daily/H06_daily_joint_context_exploratory_visual_review.csv"
)

assert(
  all(input_manifest$verification_status == "PASS") &&
    all(input_manifest$expected_sha256 == input_manifest$actual_sha256),
  "The exploratory joint-context input contract is incomplete or changed"
)
output_paths <- file.path(root, output_manifest$relative_path)
assert(
  nrow(output_manifest) == 27L &&
    !anyDuplicated(output_manifest$relative_path) &&
    all(file.exists(output_paths)) &&
    identical(
      unname(vapply(output_paths, sha256, character(1L))),
      output_manifest$sha256
    ) &&
    identical(as.numeric(file.info(output_paths)$size), output_manifest$bytes),
  "The exploratory joint-context output manifest contains a changed identity"
)

assert(
  nrow(effects) == 90L &&
    nrow(tests) == 90L &&
    nrow(families) == 6L &&
    nrow(stability) == 45L &&
    nrow(site_estimates) == 378L &&
    nrow(diagnostics) == 14L &&
    nrow(visual_review) == 14L,
  "The exploratory joint-context result grids are incomplete"
)

l10_tests <- tests |>
  dplyr::filter(.data$metric_slot == 3L)
estimable_tests <- tests |>
  dplyr::filter(.data$metric_slot != 3L)
assert(
  nrow(l10_tests) == 6L &&
    all(l10_tests$test_status == "NAMED_NA_ACCEPTED_L10_ESTIMAND_NOT_REPLACED") &&
    all(is.na(l10_tests$raw_p_value)) &&
    all(is.na(l10_tests$bh_adjusted_p_value)) &&
    nrow(estimable_tests) == 84L &&
    all(estimable_tests$test_status == "ESTIMABLE_EXPLORATORY") &&
    all(estimable_tests$multiplicity_family_size == 15L),
  "The named L10 slot or exploratory estimability contract changed"
)

assert(
  all(families$named_slots == 15L) &&
    all(families$estimable_slots == 14L) &&
    all(families$named_na_slots == 1L) &&
    all(families$family_valid) &&
    identical(
      as.integer(families$fdr_supported_slots),
      c(10L, 6L, 6L, 0L, 10L, 0L)
    ),
  "The six exploratory 15-slot family summaries changed"
)

stability_counts <- stability |>
  dplyr::count(.data$predictor_id, .data$covariate_stability) |>
  dplyr::arrange(.data$predictor_id, .data$covariate_stability)
expected_stability_counts <- tibble::tribble(
  ~predictor_id, ~covariate_stability, ~n,
  "activity_status", "NAMED_NA_ACCEPTED_L10_ESTIMAND_NOT_REPLACED", 1L,
  "activity_status", "STABLE_LT_1_SE", 14L,
  "previous_sleep_duration_centered_h", "NAMED_NA_ACCEPTED_L10_ESTIMAND_NOT_REPLACED", 1L,
  "previous_sleep_duration_centered_h", "STABLE_LT_1_SE", 11L,
  "previous_sleep_duration_centered_h", "SUBSTANTIAL_LIMITATION_1_TO_LT_2_SE", 3L,
  "work_free_day", "NAMED_NA_ACCEPTED_L10_ESTIMAND_NOT_REPLACED", 1L,
  "work_free_day", "STABLE_LT_1_SE", 9L,
  "work_free_day", "SUBSTANTIAL_LIMITATION_1_TO_LT_2_SE", 4L,
  "work_free_day", "UNSTABLE_GE_2_SE_OR_DIRECTION_REVERSAL", 1L
)
assert(
  isTRUE(all.equal(
    as.data.frame(stability_counts),
    as.data.frame(expected_stability_counts),
    check.attributes = FALSE
  )),
  "The common-sample covariate-stability classifications changed"
)

mean_rows <- stability |>
  dplyr::filter(.data$metric_slot == 1L) |>
  dplyr::arrange(.data$predictor_order)
assert(
  nrow(mean_rows) == 3L &&
    isTRUE(all.equal(
      mean_rows$display_estimate_mutually_adjusted_joint,
      c(0.749511802817991, 1.15615796592824, 0.901893428603129),
      tolerance = 1e-12
    )) &&
    identical(
      mean_rows$covariate_stability,
      c(
        "SUBSTANTIAL_LIMITATION_1_TO_LT_2_SE",
        "STABLE_LT_1_SE",
        "SUBSTANTIAL_LIMITATION_1_TO_LT_2_SE"
      )
    ),
  "The mutually adjusted mean-melEDI estimates or classifications changed"
)

assert(
  all(diagnostics$hard_gate_status == "PASS_PENDING_VISUAL_REVIEW") &&
    all(visual_review$visual_status == "REVIEW_LIMITATION") &&
    all(nzchar(visual_review$visual_explanation)) &&
    all(nzchar(visual_review$residual_fitted_plot_sha256)) &&
    all(nzchar(visual_review$qq_plot_sha256)) &&
    all(nzchar(visual_review$residual_source_sha256)),
  "The joint-context hard-gate or visual-review record changed"
)

assert(
  all(site_estimates$site_name %in% c(
    "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
    "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
    "Kumasi (GH)"
  )) &&
    all(table(site_estimates$metric_slot, site_estimates$predictor_id) == 9L),
  "The conditional equal-site contrast grid is incomplete"
)

cat(
  paste0(
    "PASS: exploratory H06_daily joint-context analysis verified under R ",
    as.character(getRversion()),
    ": 14 estimable metrics, six fixed 15-slot families, 90 tests, 378 ",
    "conditional site contrasts, unchanged named L10 slots, and 14 visual ",
    "REVIEW_LIMITATION classifications.\n"
  )
)
