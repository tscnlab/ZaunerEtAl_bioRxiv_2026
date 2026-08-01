# Audit post-bootstrap H01 response-family checks without fitting replacements.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "The H01 response-family audit requires R 4.6.1; found %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H01/audit_h01_postbootstrap_response_families.R"
producer_path <- file.path(root, producer)
diagnostic_path <- file.path(
  root,
  "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv"
)
sample_path <- file.path(
  root,
  "artifacts/09_tables/H01/H01_exact_samples.csv"
)
bootstrap_path <- file.path(
  root,
  "artifacts/08_diagnostics/H01/H01_r2_bootstrap_audit.csv"
)
result_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_model_results_artifacts.csv"
)

required_paths <- c(
  producer_path,
  diagnostic_path,
  sample_path,
  bootstrap_path,
  result_manifest_path
)
if (!all(file.exists(required_paths))) {
  stop(
    "The H01 response-family audit is missing a required input",
    call. = FALSE
  )
}

diagnostics <- readr::read_csv(
  diagnostic_path,
  show_col_types = FALSE
)
samples <- readr::read_csv(sample_path, show_col_types = FALSE)
bootstrap <- readr::read_csv(bootstrap_path, show_col_types = FALSE)

gate_metrics <- tibble::tribble(
  ~metric_id, ~gate_role, ~named_alternative,
  "duration_below_1_sleep_environment",
  "common_replacement_required",
  "identity-scale Gaussian model",
  "duration_below_10_pre_sleep",
  "explicit_author_disposition_required",
  "none preapproved",
  "l10_mean_medi",
  "explicit_author_disposition_required",
  "Tweedie log-link model"
)

identity_columns <- c(
  "run_id",
  "data_scenario_id",
  "placement",
  "sample_scenario",
  "analytical_role",
  "metric_order",
  "metric_id",
  "analysis_unit",
  "response_family",
  "response_transform"
)

evidence <- diagnostics |>
  dplyr::inner_join(gate_metrics, by = "metric_id") |>
  dplyr::left_join(
    samples |>
      dplyr::select(
        dplyr::all_of(identity_columns),
        participants,
        participant_days,
        observations,
        sites,
        derivation_support_hours,
        derivation_support_status,
        sample_status
      ),
    by = identity_columns
  ) |>
  dplyr::left_join(
    bootstrap |>
      dplyr::select(
        dplyr::all_of(identity_columns),
        attempted_refits,
        successful_refits,
        used_refits,
        failed_refits,
        warning_refits,
        bootstrap_status = status
      ),
    by = identity_columns
  ) |>
  dplyr::mutate(
    primary_near_eye = placement == "glasses" &
      sample_scenario == "all_available",
    strong_residual_flag = residual_status %in% c(
      "WARN_STRONG_TWEEDIE_MISFIT",
      "WARN_STRONG_GAUSSIAN_MISFIT"
    ),
    predicted_support_flag = startsWith(
      prediction_bound_status,
      "WARN"
    ),
    postbootstrap_gate_status = dplyr::case_when(
      metric_id == "duration_below_1_sleep_environment" ~
        "OPEN_COMMON_REPLACEMENT_REQUIRED",
      strong_residual_flag ~ "OPEN_AUTHOR_DISPOSITION_REQUIRED",
      TRUE ~ "WARN_REVIEW"
    )
  ) |>
  dplyr::select(
    dplyr::all_of(identity_columns),
    gate_role,
    named_alternative,
    primary_near_eye,
    participants,
    participant_days,
    observations,
    sites,
    derivation_support_hours,
    derivation_support_status,
    sample_status,
    converged,
    positive_definite_hessian,
    singular,
    residual_status,
    shapiro_p,
    residual_variance_ratio,
    standardized_residual_over_3_fraction,
    standardized_residual_over_4_fraction,
    dharma_uniformity_p,
    dharma_dispersion_p,
    dharma_zero_inflation_p,
    dharma_outlier_p,
    observed_zero_fraction,
    simulated_zero_fraction,
    zero_fraction_ratio,
    prediction_bound_status,
    observed_below_bound_n,
    observed_above_bound_n,
    predicted_below_bound_n,
    predicted_above_bound_n,
    audit_threshold_status,
    observed_above_audit_threshold_n,
    predicted_above_audit_threshold_n,
    diagnostic_status,
    strong_residual_flag,
    predicted_support_flag,
    attempted_refits,
    successful_refits,
    used_refits,
    failed_refits,
    warning_refits,
    bootstrap_status,
    postbootstrap_gate_status
  ) |>
  dplyr::arrange(metric_order, data_scenario_id, placement, sample_scenario)

summary <- evidence |>
  dplyr::group_by(
    metric_order,
    metric_id,
    response_family,
    response_transform,
    gate_role,
    named_alternative
  ) |>
  dplyr::summarise(
    runs = dplyr::n(),
    primary_near_eye_runs = sum(primary_near_eye),
    strong_residual_runs = sum(strong_residual_flag),
    strong_primary_near_eye_runs = sum(
      strong_residual_flag & primary_near_eye
    ),
    predicted_support_warning_runs = sum(predicted_support_flag),
    minimum_successful_refits = min(successful_refits),
    minimum_used_refits = min(used_refits),
    postbootstrap_gate_status = if (
      dplyr::first(metric_id) == "duration_below_1_sleep_environment"
    ) {
      "OPEN_COMMON_REPLACEMENT_REQUIRED"
    } else if (any(strong_residual_flag)) {
      "OPEN_AUTHOR_DISPOSITION_REQUIRED"
    } else {
      "WARN_REVIEW"
    },
    .groups = "drop"
  )

stopifnot(
  nrow(evidence) == 24L,
  nrow(summary) == 3L,
  all(evidence$converged),
  all(evidence$positive_definite_hessian),
  !any(evidence$singular),
  all(evidence$used_refits >= 1000L),
  all(evidence$bootstrap_status == "PASS"),
  all(
    evidence$postbootstrap_gate_status[
      evidence$metric_id == "duration_below_1_sleep_environment"
    ] == "OPEN_COMMON_REPLACEMENT_REQUIRED"
  ),
  all(
    evidence$strong_residual_flag[
      evidence$metric_id == "duration_below_1_sleep_environment"
    ]
  )
)

audit_root <- file.path(root, "audit/hypotheses/H01")
evidence_path <- file.path(
  audit_root,
  "H01_postbootstrap_response_family_gate_evidence.csv"
)
summary_path <- file.path(
  audit_root,
  "H01_postbootstrap_response_family_gate_summary.csv"
)
provenance_path <- file.path(
  audit_root,
  "H01_postbootstrap_response_family_gate_provenance.csv"
)

evidence_metadata <- write_csv_artifact(
  evidence,
  evidence_path,
  producer = producer
)
summary_metadata <- write_csv_artifact(
  summary,
  summary_path,
  producer = producer
)

provenance <- tibble::tibble(
  r_version = as.character(getRversion()),
  dplyr_version = as.character(utils::packageVersion("dplyr")),
  readr_version = as.character(utils::packageVersion("readr")),
  diagnostic_path = "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv",
  diagnostic_sha256 = artifact_sha256(diagnostic_path),
  sample_path = "artifacts/09_tables/H01/H01_exact_samples.csv",
  sample_sha256 = artifact_sha256(sample_path),
  bootstrap_path = "artifacts/08_diagnostics/H01/H01_r2_bootstrap_audit.csv",
  bootstrap_sha256 = artifact_sha256(bootstrap_path),
  result_manifest_path =
    "artifacts/12_manifests/H01_model_results_artifacts.csv",
  result_manifest_sha256 = artifact_sha256(result_manifest_path),
  producer_path = producer,
  producer_sha256 = artifact_sha256(producer_path),
  evidence_sha256 = evidence_metadata$sha256,
  summary_sha256 = summary_metadata$sha256,
  replacement_fitted = FALSE,
  inferential_release_status = "WITHHELD_OPEN_MAJOR_GATE"
)
write_csv_artifact(
  provenance,
  provenance_path,
  producer = producer
)

message(
  "H01 post-bootstrap response-family gate audit completed: ",
  nrow(evidence),
  " run-metric rows"
)
