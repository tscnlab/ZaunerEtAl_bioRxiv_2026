# Verify the fixed H01 response-family candidate assessment.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

diagnostic_path <- file.path(
  root,
  paste0(
    "artifacts/08_diagnostics/H01/response_family_candidates/",
    "H01_response_family_candidate_diagnostics.csv"
  )
)
scorecard_path <- file.path(
  root,
  paste0(
    "artifacts/09_tables/H01/response_family_candidates/",
    "H01_response_family_candidate_scorecard.csv"
  )
)
selection_path <- file.path(
  root,
  paste0(
    "artifacts/09_tables/H01/response_family_candidates/",
    "H01_response_family_candidate_selection.csv"
  )
)
sample_check_path <- file.path(
  root,
  paste0(
    "artifacts/08_diagnostics/H01/response_family_candidates/",
    "H01_response_family_candidate_sample_invariance.csv"
  )
)
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_response_family_candidate_artifacts.csv"
)

stopifnot(all(file.exists(c(
  diagnostic_path,
  scorecard_path,
  selection_path,
  sample_check_path,
  manifest_path
))))

diagnostics <- readr::read_csv(diagnostic_path, show_col_types = FALSE)
scorecard <- readr::read_csv(scorecard_path, show_col_types = FALSE)
selection <- readr::read_csv(selection_path, show_col_types = FALSE)
sample_check <- readr::read_csv(sample_check_path, show_col_types = FALSE)
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)

stopifnot(
  nrow(diagnostics) == 72L,
  nrow(scorecard) == 9L,
  nrow(selection) == 3L,
  nrow(sample_check) == 24L,
  all(sample_check$sample_invariant),
  all(sample_check$candidates == 3L),
  all(selection$selected_common_diagnostic_status %in%
    c(
      "GOOD_COMMON_DIAGNOSTICS",
      "INELIGIBLE_STRONG_RESIDUAL_WARNING"
    ))
)

selected <- stats::setNames(
  selection$selected_candidate_id,
  selection$metric_id
)
stopifnot(
  identical(
    unname(selected[["duration_below_10_pre_sleep"]]),
    "gaussian_identity"
  ),
  identical(
    unname(selected[["duration_below_1_sleep_environment"]]),
    "tweedie_log_identity"
  ),
  identical(
    unname(selected[["l10_mean_medi"]]),
    "gaussian_log10_offset_0.1"
  )
)

pre_sleep_gaussian <- scorecard |>
  dplyr::filter(
    metric_id == "duration_below_10_pre_sleep",
    candidate_id == "gaussian_identity"
  )
stopifnot(
  nrow(pre_sleep_gaussian) == 1L,
  pre_sleep_gaussian$strong_residual_warning_runs == 0L,
  pre_sleep_gaussian$primary_prediction_support_warning_runs == 0L,
  pre_sleep_gaussian$required_model_rows == 64L,
  pre_sleep_gaussian$full_fit_eligible,
  pre_sleep_gaussian$eligible
)

sleep_gaussian <- scorecard |>
  dplyr::filter(
    metric_id == "duration_below_1_sleep_environment",
    candidate_id == "gaussian_identity"
  )
stopifnot(
  nrow(sleep_gaussian) == 1L,
  sleep_gaussian$strong_residual_warning_runs == 0L,
  sleep_gaussian$primary_prediction_support_warning_runs > 0L,
  !sleep_gaussian$eligible
)

l10_tweedie <- scorecard |>
  dplyr::filter(
    metric_id == "l10_mean_medi",
    candidate_id == "tweedie_log_identity"
  )
stopifnot(
  nrow(l10_tweedie) == 1L,
  l10_tweedie$strong_residual_warning_runs > 0L,
  !l10_tweedie$eligible
)

stopifnot(
  all(c(
    "scripts/hypotheses/H01/assess_h01_response_family_candidates.R",
    "audit/hypotheses/H01/H01_response_family_candidate_protocol.md",
    paste0(
      "artifacts/09_tables/H01/response_family_candidates/",
      "H01_response_family_candidate_selection.csv"
    )
  ) %in% manifest$path)
)

message("H01 response-family candidate assessment tests passed")
