#!/usr/bin/env Rscript

# Focused identity and contract test for H06-D-G2P-TIMING-REPAIR.

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
  "digest", "dplyr", "glmmTMB", "readr", "sandwich", "tibble", "xml2"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf(
      "Missing synchronized packages: %s",
      paste(missing_packages, collapse = ", ")
    ),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R"
))

h06d_tr_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Focused test requires R 4.6.1"
)
h06d_tr_assert(
  identical(as.character(utils::packageVersion("sandwich")), "3.1.1") &&
    identical(as.character(utils::packageVersion("glmmTMB")), "1.1.14"),
  "Focused test package identities changed"
)

read_h06d <- function(stage, file) {
  readr::read_csv(
    file.path(root, "artifacts", stage, "H06_daily", file),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}
verify_file_manifest <- function(manifest) {
  paths <- file.path(root, manifest$relative_path)
  h06d_tr_assert(all(file.exists(paths)), "A manifest path is missing")
  actual_hash <- unname(vapply(paths, h06d_tr_sha256, character(1L)))
  actual_bytes <- as.numeric(file.info(paths)$size)
  h06d_tr_assert(
    identical(actual_hash, manifest$sha256),
    "A manifest SHA-256 identity failed"
  )
  h06d_tr_assert(
    identical(actual_bytes, as.numeric(manifest$bytes)),
    "A manifest byte count failed"
  )
  invisible(TRUE)
}

authorization <- h06d_tr_authorization()
h06d_tr_assert(
  identical(
    h06d_tr_sha256(file.path(root, authorization$relative_path)),
    authorization$expected_sha256
  ),
  "H06-D-009 authorization identity failed"
)

input_manifest <- read_h06d(
  "12_manifests",
  "H06_daily_timing_repair_input_manifest.csv"
)
pipeline_manifest <- read_h06d(
  "12_manifests",
  "H06_daily_timing_repair_pipeline_manifest.csv"
)
figure_manifest <- read_h06d(
  "12_manifests",
  "H06_daily_timing_repair_figure_manifest.csv"
)
report_manifest <- read_h06d(
  "12_manifests",
  "H06_daily_timing_repair_report_manifest.csv"
)
h06d_tr_assert(
  nrow(input_manifest) == 34L &&
    all(input_manifest$verification_status == "PASS") &&
    identical(input_manifest$expected_sha256, input_manifest$actual_sha256),
  "The 34-row expanded input contract failed"
)
verify_file_manifest(pipeline_manifest)
verify_file_manifest(figure_manifest)
verify_file_manifest(report_manifest)
h06d_tr_assert(
  nrow(figure_manifest) == 9L,
  "The residual figure manifest must contain four PNGs, four CSVs, and a summary"
)
h06d_tr_assert(
  !any(grepl("H06_daily_timing_repair_report_manifest.csv$", report_manifest$relative_path)),
  "The report manifest is circular"
)

frame_contract <- read_h06d(
  "06_model_data",
  "H06_daily_timing_repair_frame_contract.csv"
)
frame_pins <- h06d_tr_frame_pins()
h06d_tr_assert(
  nrow(frame_contract) == 12L &&
    all(frame_contract$frame_verification_status == "PASS") &&
    all(frame_contract$participants == frame_pins$participants) &&
    all(frame_contract$participant_days == frame_pins$participant_days) &&
    all(frame_contract$sites == 9L) &&
    identical(
      frame_contract$actual_frame_object_sha256,
      frame_pins$frame_object_sha256
    ),
  "The 12 exact frame contracts failed"
)

candidate_models <- read_h06d(
  "08_diagnostics",
  "H06_daily_timing_repair_candidate_models.csv"
)
candidate_cells <- read_h06d(
  "08_diagnostics",
  "H06_daily_timing_repair_candidate_cells.csv"
)
h06d_tr_assert(
  nrow(candidate_models) == 36L &&
    identical(sort(unique(candidate_models$structure)),
              c("additive", "interaction", "reduced")) &&
    all(candidate_models$design_full_rank) &&
    all(candidate_models$finite_coefficients) &&
    all(candidate_models$finite) &&
    all(candidate_models$symmetric) &&
    all(candidate_models$positive_semidefinite) &&
    all(candidate_models$hc3_leverage_numerically_usable) &&
    all(candidate_models$covariance_warning_count == 0L) &&
    all(candidate_models$candidate_model_gate_pass) &&
    all(grepl("fix = FALSE", candidate_models$covariance, fixed = TRUE)),
  "The 36 candidate LM/HC3 gate rows failed"
)
h06d_tr_assert(
  nrow(candidate_cells) == 12L && all(candidate_cells$candidate_gate_pass),
  "Not all 12 candidate cells pass"
)

student <- read_h06d(
  "08_diagnostics",
  "H06_daily_timing_repair_student_t.csv"
)
ar <- read_h06d(
  "08_diagnostics",
  "H06_daily_timing_repair_no_nugget_ar.csv"
)
sensitivity <- read_h06d(
  "08_diagnostics",
  "H06_daily_timing_repair_sensitivity_stability.csv"
)
h06d_tr_assert(
  nrow(student) == 36L && all(student$converged) &&
    all(student$positive_definite_hessian) &&
    all(student$warning_count == 0L),
  "Student-t diagnostic fits changed"
)
h06d_tr_assert(
  nrow(ar) == 36L && all(ar$no_nugget_verified) &&
    all(ar$dispformula == "~0") &&
    sum(!ar$converged) == 10L &&
    sum(!ar$converged & ar$structure == "additive") == 3L &&
    sum(!ar$converged & ar$structure == "interaction") == 5L &&
    all(!ar$temporal_threshold_pass),
  "No-nugget AR diagnostic dispositions changed"
)
h06d_tr_assert(
  nrow(sensitivity) == 48L &&
    sum(
      sensitivity$sensitivity_id == "student_t_identity" &
        sensitivity$component == "predictor_additive" &
        sensitivity$sensitivity_classification == "STABLE"
    ) == 11L &&
    sum(
      sensitivity$sensitivity_id == "student_t_identity" &
        sensitivity$component == "predictor_additive" &
        sensitivity$sensitivity_classification == "SUBSTANTIAL_LIMITATION"
    ) == 1L &&
    sum(
      sensitivity$sensitivity_id == "student_t_identity" &
        sensitivity$component == "predictor_by_site_block" &
        sensitivity$sensitivity_classification == "UNSTABLE"
    ) == 10L &&
    sum(
      sensitivity$sensitivity_id == "no_nugget_gap_aware_ar1" &
        sensitivity$component == "predictor_additive" &
        sensitivity$sensitivity_classification == "STABLE"
    ) == 8L &&
    sum(
      sensitivity$sensitivity_id == "no_nugget_gap_aware_ar1" &
        sensitivity$component == "predictor_additive" &
        sensitivity$sensitivity_classification == "SUBSTANTIAL_LIMITATION"
    ) == 1L &&
    sum(
      sensitivity$sensitivity_id == "no_nugget_gap_aware_ar1" &
        sensitivity$component == "predictor_additive" &
        sensitivity$sensitivity_classification ==
          "UNRESOLVED_NUMERICAL_FAILURE"
    ) == 3L &&
    sum(
      sensitivity$sensitivity_id == "no_nugget_gap_aware_ar1" &
        sensitivity$component == "predictor_by_site_block" &
        sensitivity$sensitivity_classification ==
          "UNRESOLVED_NUMERICAL_FAILURE"
    ) == 5L,
  "Sensitivity classifications changed"
)

effects <- read_h06d(
  "09_tables",
  "H06_daily_timing_repair_effects.csv"
)
tests <- read_h06d(
  "09_tables",
  "H06_daily_timing_repair_raw_tests.csv"
)
verdict <- read_h06d(
  "09_tables",
  "H06_daily_timing_repair_outcome_verdict.csv"
)
h06d_tr_assert(
  nrow(effects) == 12L && all(is.finite(effects$estimate_hours)) &&
    all(is.finite(effects$lower_95_hours)) &&
    all(is.finite(effects$upper_95_hours)) &&
    all(effects$interval_type ==
      "participant-cluster HC3 pointwise 95% confidence interval"),
  "Candidate pointwise intervals changed"
)
h06d_tr_assert(
  nrow(tests) == 24L &&
    all(tests$test_status == "PILOT_RAW_ONLY_NO_BH_UPDATE") &&
    all(tests$multiplicity_status == "PILOT_RAW_ONLY_NO_BH_UPDATE") &&
    all(is.na(tests$adjusted_p_value)) &&
    all(is.finite(tests$raw_p_value)),
  "The raw-only no-BH boundary failed"
)
h06d_tr_assert(
  nrow(verdict) == 4L &&
    all(verdict$all_three_predictors_candidate_acceptable) &&
    all(verdict$worst_sensitivity_rank == 4L) &&
    all(verdict$timing_repair_disposition ==
      "AUTHOR_REVIEW_CANDIDATE_ACCEPTABLE_SENSITIVITY_UNRESOLVED") &&
    all(verdict$gate_status ==
      "H06-D-G2P-TIMING-REPAIR_AWAITING_AUTHOR_REVIEW"),
  "The four outcome stop-gate verdicts changed"
)

bundle <- readRDS(file.path(
  root,
  "artifacts/07_models/H06_daily/H06_daily_timing_repair_pilot_models.rds"
))
h06d_tr_assert(
  identical(bundle$gate, "H06-D-G2P-TIMING-REPAIR") &&
    length(bundle$cells) == 12L &&
    identical(bundle$authorization$expected_sha256, authorization$expected_sha256),
  "The sealed model bundle header failed"
)
for (index in seq_len(nrow(frame_pins))) {
  pin <- frame_pins[index, , drop = FALSE]
  cell <- bundle$cells[[pin$cell_id]]
  predictor <- h06d_tr_predictor_registry() |>
    dplyr::filter(.data$predictor_id == pin$predictor_id)
  expected_fixed <- h06d_tr_formula_set(predictor$column[[1L]], ar = FALSE)
  expected_ar <- h06d_tr_formula_set(predictor$column[[1L]], ar = TRUE)
  h06d_tr_assert(
    identical(cell$frame_object_sha256, pin$frame_object_sha256),
    "A sealed cell frame identity failed"
  )
  h06d_tr_assert(
    all(vapply(names(expected_fixed), function(structure) {
      fit <- cell$candidate$fits[[structure]]$value
      inherits(fit, "lm") && identical(
        h06d_tr_normalize_formula(stats::formula(fit)),
        h06d_tr_normalize_formula(expected_fixed[[structure]])
      )
    }, logical(1L))),
    "A candidate model formula/class failed"
  )
  h06d_tr_assert(
    all(vapply(names(expected_ar), function(structure) {
      fit <- cell$no_nugget_ar$fits[[structure]]$value
      inherits(fit, "glmmTMB") &&
        identical(
          h06d_tr_normalize_formula(stats::formula(fit)),
          h06d_tr_normalize_formula(expected_ar[[structure]])
        ) &&
        identical(
          h06d_tr_normalize_formula(fit$modelInfo$allForm$dispformula),
          "~0"
        )
    }, logical(1L))),
    "A no-nugget AR model formula/class failed"
  )
}

preservation <- read_h06d(
  "08_diagnostics",
  "H06_daily_timing_repair_preservation_final.csv"
)
preservation_baseline <- read_h06d(
  "08_diagnostics",
  "H06_daily_timing_repair_preservation_baseline.csv"
)
live_preservation <- h06d_tr_verify_preservation(root, preservation_baseline)
h06d_tr_assert(
  nrow(preservation) == 571L &&
    nrow(live_preservation) == 571L &&
    all(live_preservation$identity_status == "BYTE_IDENTICAL") &&
    all(preservation$identity_status == "BYTE_IDENTICAL") &&
    identical(preservation$sha256, preservation$baseline_sha256) &&
    identical(as.numeric(preservation$bytes),
              as.numeric(preservation$baseline_bytes)),
  "The 571 protected historical identities failed"
)

html_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/11_timing_repair_pilot.html"
)
document <- xml2::read_html(html_path)
images <- xml2::xml_find_all(document, "//main//img")
tables <- xml2::xml_find_all(document, "//main//table")
alt_text <- xml2::xml_attr(images, "alt")
main_text <- xml2::xml_text(xml2::xml_find_first(document, "//main"))
h06d_tr_assert(
  length(images) == 4L && all(nzchar(alt_text)) &&
    length(tables) == 4L &&
    grepl("H06-D-G2P-TIMING-REPAIR", main_text, fixed = TRUE) &&
    grepl("PILOT_RAW_ONLY_NO_BH_UPDATE", main_text, fixed = TRUE) &&
    grepl("pointwise 95%", tolower(main_text), fixed = TRUE) &&
    !grepl("simultaneous interval", tolower(main_text), fixed = TRUE),
  "Rendered report structural QA failed"
)

cat(sprintf(
  paste0(
    "H06-D-G2P-TIMING-REPAIR PASS: 34 pins; 12 frames; 108 fits; ",
    "36 PSD HC3 matrices; 24 raw-only tests; 48 sensitivity rows; ",
    "4 residual figures; 571 protected identities; %d report identities.\n"
  ),
  nrow(report_manifest)
))
