# Contract for the H06_daily exploratory mutually adjusted context analysis.

h06d_joint_abort <- function(..., call. = FALSE) {
  stop(sprintf(...), call. = call.)
}

h06d_joint_assert <- function(condition, ...) {
  if (!isTRUE(condition)) h06d_joint_abort(...)
  invisible(TRUE)
}

h06d_joint_sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

h06d_joint_input_contract <- function() {
  tibble::tribble(
    ~input_id, ~relative_path, ~expected_sha256, ~role,
    "task_authorization",
    "audit/hypotheses/H06_daily/H06_daily_joint_context_exploratory_authorization.md",
    "2f83d045f7c117b4c1849904f3be54dbeea44c601edd8e5fe2a40525123b0026",
    "bounded author-requested exploratory scope",
    "stage3_transition",
    "audit/decisions/h06_daily_stage2_acceptance_stage3_transition.md",
    "26e3cf5302db74156a2ad929a80a1352eac6967ccf0e0e1adb5cdcfa71b9954e",
    "accepted Stage 2 and complementary Stage 3 role",
    "diagnostic_alignment",
    "audit/decisions/h06_daily_h01_diagnostic_alignment.md",
    "64be7a03f6982d175e4372d8488d84ed3e427a9bd38e1eddbc55f0ce1c49375e",
    "H01-aligned hard and nonblocking diagnostic roles",
    "timing_route_acceptance",
    "audit/decisions/h06_daily_timing_repair_acceptance.md",
    "739c654b9920f08b7da44fe3ecd667cfd30eb56fece91a3efae137c256623869",
    "participant-cluster HC3 route for four repaired clock outcomes",
    "mder_estimand",
    "audit/decisions/mder_mean_of_viable_ratios.md",
    "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
    "accepted momentary-ratio MDER estimand",
    "primary_near_eye_source",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
    "b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42",
    "current participant-day metrics including METRIC-010 and METRIC-011 repairs",
    "exercise_diary",
    "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
    "5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107",
    "immutable daily activity context",
    "sleep_diary",
    "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
    "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
    "immutable Work/Free and previous-night sleep contexts",
    "site_registry",
    "config/site_display_registry.csv",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "submitted site order, names, and colours",
    "metric_registry",
    "config/metric_display_registry.csv",
    "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0",
    "manuscript metric names and units",
    "accepted_non_l10_effects",
    "artifacts/09_tables/H06_daily/H06_daily_non_l10_production_effects.csv",
    "367d5a3c5ccdad1e8a17924743886e1f05d795544c9a4557252aaf3e0fc6424f",
    "accepted predictor-specific estimates used only for stability comparison",
    "accepted_mder_effects",
    "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_effect_estimates.csv",
    "8150ca587e15870cc693806edb7fd401adf8930af2ab948444b2319e7cb19eab",
    "accepted MDER predictor-specific estimates used only for comparison",
    "accepted_stage3_primary",
    "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_results.csv",
    "c81af8827137259ab6bd6c8188971039ddd8e2aca71827a50a0ae94f2ea19e9a",
    "accepted primary result and multiplicity display"
  )
}

h06d_joint_metric_registry <- function() {
  dplyr::bind_rows(
    h06d_nl_metric_registry(),
    tibble::tibble(
      metric_slot = 15L,
      metric_id = "mder_mean_of_viable_ratios",
      source_column = "mder",
      manuscript_name = "Melanopic daylight efficacy ratio",
      display_unit = "dimensionless",
      response_family = "gaussian",
      response_transform = "identity",
      effect_scale = "absolute MDER difference",
      lower_bound = 0,
      upper_bound = Inf,
      analysis_unit = "participant-day",
      is_timing = FALSE
    )
  ) |>
    dplyr::arrange(.data$metric_slot)
}

h06d_joint_slot_registry <- function() {
  h06d_nl_full_slot_registry() |>
    dplyr::mutate(
      exploratory_disposition = dplyr::case_when(
        .data$metric_slot == 3L ~ "NAMED_NA_ACCEPTED_L10_ESTIMAND_NOT_REPLACED",
        TRUE ~ "EXPLORATORY_JOINT_CONTEXT_FIT"
      )
    )
}

h06d_joint_predictor_registry <- function() {
  h06d_nl_predictor_registry() |>
    dplyr::mutate(
      exploratory_association_family = sprintf(
        "H06D-JOINT-A-%02d",
        .data$predictor_order
      ),
      exploratory_heterogeneity_family = sprintf(
        "H06D-JOINT-H-%02d",
        .data$predictor_order
      )
    )
}

h06d_joint_fixed_terms <- function() {
  c(
    "work_free_day",
    "activity_status",
    "previous_sleep_duration_centered_h"
  )
}

h06d_joint_formula <- function(
  structure = c("separate", "joint", "reduced", "interaction"),
  predictor_column = NULL,
  random_intercept = TRUE
) {
  structure <- match.arg(structure)
  all_terms <- h06d_joint_fixed_terms()
  h06d_joint_assert(
    structure == "joint" || predictor_column %in% all_terms,
    "A recognized predictor column is required for `%s`",
    structure
  )
  fixed <- switch(
    structure,
    separate = c("site", predictor_column),
    joint = c("site", all_terms),
    reduced = c("site", setdiff(all_terms, predictor_column)),
    interaction = c(
      sprintf("site * %s", predictor_column),
      setdiff(all_terms, predictor_column)
    )
  )
  rhs <- paste(fixed, collapse = " + ")
  if (isTRUE(random_intercept)) {
    rhs <- paste(rhs, "+ (1 | participant_key)")
  }
  stats::as.formula(paste("response_value ~", rhs))
}

h06d_joint_artifact_roots <- function(root) {
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
