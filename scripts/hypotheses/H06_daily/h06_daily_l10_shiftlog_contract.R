# H06_daily L10 shifted-log amendment contract under H06-D-003 / CHG-111.

h06d_shiftlog_abort <- function(..., call. = FALSE) {
  stop(sprintf(...), call. = call.)
}

h06d_shiftlog_assert <- function(condition, ...) {
  if (!isTRUE(condition)) {
    h06d_shiftlog_abort(...)
  }
  invisible(TRUE)
}

h06d_shiftlog_sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

h06d_shiftlog_object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}

h06d_shiftlog_decision_sha256 <- function() {
  "4ddc2cd9ebdf0c98ca5ef7b56b0965e0c661dc85680db34bcfbde6b61342ec3a"
}

h06d_shiftlog_offset_lx <- function() {
  0.1
}

h06d_shiftlog_input_contract <- function() {
  tibble::tribble(
    ~input_id,
    ~relative_path,
    ~expected_sha256,
    ~role,
    "shiftlog_amendment",
    "audit/decisions/h06_daily_l10_shifted_log_amendment.md",
    h06d_shiftlog_decision_sha256(),
    "controlling H06-D-003 / CHG-111 amendment",
    "metric011_decision",
    "audit/decisions/l10_numerical_zero_normalization.md",
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
    "controlling exact-zero normalization decision",
    "metric011_evidence_manifest",
    "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
    "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
    "independent METRIC-011 evidence",
    "metric_manifest",
    "artifacts/12_manifests/metric_artifacts.csv",
    "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
    "current shared metric manifest",
    "site_context_manifest",
    "artifacts/12_manifests/site_solar_context_artifacts.csv",
    "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
    "current shared site/context manifest",
    "base_manifest",
    "artifacts/12_manifests/base_model_data_artifacts.csv",
    "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
    "current shared base-model-data manifest",
    "primary_near_eye",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_context.rds",
    "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a",
    "current near-eye participant-day L10 source",
    "exercise_diary",
    "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
    "5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107",
    "immutable daily activity context",
    "sleep_diary",
    "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
    "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
    "immutable work/free and previous-night sleep context",
    "site_registry",
    "config/site_display_registry.csv",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "submitted site order and display names",
    "historical_frame_registry",
    "artifacts/06_model_data/H06_daily/H06_daily_l10_metric011_frame_registry.csv",
    "ff771012e7b81a16aa0e311660f425548bbbb9404b441de26c9bda6b5ca04475",
    "sealed METRIC-011 component-frame registry",
    "historical_one_part_bundle",
    "artifacts/07_models/H06_daily/H06_daily_l10_metric011_production_models.rds",
    "8dede8ff6e506b5dfdd9d7ff37dd675a7ee030c7361c39a16b97c69524ca9419",
    "sealed parent composite containing diagnostic one-part fits",
    "historical_effect_table",
    "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_effect_estimates.csv",
    "8139a8b58ccc4e4e5b6528158b18078b07d7b9172ac86a2ba3c9a6c0f1be97f4",
    "historical diagnostic-effect record; never reused for estimand labels",
    "historical_report_manifest",
    "audit/hypotheses/H06_daily/H06_daily_l10_metric011_report_manifest.csv",
    "1890a978ba39789f45dc2474bba4567834d79a8468fbf6a154075e47a74edde8",
    "118-entry H06-D-001/H06-D-002 historical preservation contract"
  )
}

h06d_shiftlog_metric_contract <- function() {
  tibble::tibble(
    metric_slot = 3L,
    metric_id = "l10_mean_medi",
    source_column = "l10_mean_medi_lx",
    manuscript_name = "Darkest 10 h mean melEDI",
    analysis_unit = "participant-day",
    display_unit = "lx melEDI",
    lower_bound = 0,
    upper_bound = Inf,
    offset_lx = h06d_shiftlog_offset_lx(),
    response_family = "Gaussian",
    response_link = "identity",
    response_transform = "log10(L10 mean melEDI + 0.1 lx)",
    coefficient_scale = paste0(
      "ratio for fitted geometric means of L10 mean melEDI + 0.1 lx"
    ),
    zero_rule = "retain exact zero; transformed response equals -1",
    raw_back_transform = "10^eta - 0.1 lx; never silently clipped"
  )
}

h06d_shiftlog_predictor_registry <- function() {
  tibble::tribble(
    ~predictor_order,
    ~predictor_id,
    ~column,
    ~reader_name,
    ~type,
    ~reference,
    ~contrast_label,
    ~term,
    1L,
    "work_free_day",
    "work_free_day",
    "Work/free day",
    "categorical",
    "Work day",
    "Free day versus Work day",
    "work_free_dayFree day",
    3L,
    "activity_status",
    "activity_status",
    "Daily activity status",
    "categorical",
    "Sedentary",
    "Active versus Sedentary",
    "activity_statusActive",
    11L,
    "previous_sleep_duration_centered_h",
    "previous_sleep_duration_centered_h",
    "Previous-night sleep duration",
    "continuous",
    "8 h",
    "Per 1 h greater previous-night sleep duration",
    "previous_sleep_duration_centered_h"
  ) |>
    dplyr::mutate(
      association_family_id = sprintf("H06-D-A%02d", .data$predictor_order),
      heterogeneity_family_id = sprintf("H06-D-H%02d", .data$predictor_order)
    )
}

h06d_shiftlog_scenario_registry <- function() {
  tibble::tribble(
    ~run_order,
    ~run_id,
    ~dataset_id,
    ~placement_id,
    ~sample_role,
    ~analysis_role,
    ~test_role,
    1L,
    "primary__near_eye__all_available",
    "primary",
    "near_eye",
    "all_available",
    "primary",
    "primary_raw_slot",
    2L,
    "primary__chest__all_available",
    "primary",
    "chest",
    "all_available",
    "contextual_complement",
    "estimate_only",
    3L,
    "primary__near_eye__paired_common",
    "primary",
    "near_eye",
    "paired_common",
    "paired_complement",
    "estimate_only",
    4L,
    "primary__chest__paired_common",
    "primary",
    "chest",
    "paired_common",
    "paired_complement",
    "estimate_only",
    5L,
    "gap_timing_unaware__near_eye__all_available",
    "gap_timing_unaware",
    "near_eye",
    "all_available",
    "dataset_sensitivity",
    "gap_raw_slot",
    6L,
    "gap_timing_unaware__chest__all_available",
    "gap_timing_unaware",
    "chest",
    "all_available",
    "dataset_sensitivity_context",
    "estimate_only"
  )
}

h06d_shiftlog_pilot_run_id <- function() {
  "primary__near_eye__all_available"
}

h06d_shiftlog_formula_set <- function(predictor_column, ar = FALSE) {
  ar_term <- if (isTRUE(ar)) {
    " + ar1(day_index_factor + 0 | day_sequence_id)"
  } else {
    ""
  }
  list(
    registered_random_site = stats::as.formula(sprintf(
      paste0(
        "response_value ~ %s + (%s | site) + ",
        "(1 | site:participant_key)"
      ),
      predictor_column,
      predictor_column
    )),
    fixed_site_reduced = stats::as.formula(paste0(
      "response_value ~ site + (1 | participant_key)",
      ar_term
    )),
    fixed_site_additive = stats::as.formula(sprintf(
      "response_value ~ site + %s + (1 | participant_key)%s",
      predictor_column,
      ar_term
    )),
    fixed_site_heterogeneity = stats::as.formula(sprintf(
      "response_value ~ site * %s + (1 | participant_key)%s",
      predictor_column,
      ar_term
    ))
  )
}

h06d_shiftlog_artifact_roots <- function(root) {
  list(
    model_data = file.path(root, "artifacts/06_model_data/H06_daily"),
    models = file.path(root, "artifacts/07_models/H06_daily"),
    diagnostics = file.path(root, "artifacts/08_diagnostics/H06_daily"),
    tables = file.path(root, "artifacts/09_tables/H06_daily"),
    figures = file.path(root, "artifacts/10_figures/H06_daily"),
    source_data = file.path(root, "artifacts/11_source_data/H06_daily"),
    manifests = file.path(root, "artifacts/12_manifests/H06_daily")
  )
}

h06d_shiftlog_model_key <- function(run_id, predictor_id) {
  paste(run_id, predictor_id, sep = "__")
}

h06d_shiftlog_frame_stem <- function(predictor_id) {
  paste0("H06_daily_l10_shiftlog_pilot__", predictor_id, "__frame")
}
