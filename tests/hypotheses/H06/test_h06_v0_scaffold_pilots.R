# Focused contract tests for the H06 V0-scaffold feasibility pilots.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_modeling.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

model_data <- file.path(root, "artifacts/06_model_data/H06")
models <- file.path(root, "artifacts/07_models/H06")
diagnostics <- file.path(root, "artifacts/08_diagnostics/H06")
tables <- file.path(root, "artifacts/09_tables/H06")
figures <- file.path(root, "artifacts/10_figures/H06")
source_data <- file.path(root, "artifacts/11_source_data/H06")
qa_artifacts <- file.path(root, "artifacts/12_manifests/H06/qa")

registry <- readr::read_csv(
  file.path(model_data, "H06_v0_scaffold_pilot_registry.csv"),
  show_col_types = FALSE
)
samples <- readr::read_csv(
  file.path(model_data, "H06_v0_scaffold_pilot_samples.csv"),
  show_col_types = FALSE
)
fit_status <- readr::read_csv(
  file.path(diagnostics, "H06_v0_scaffold_pilot_fit_status.csv"),
  show_col_types = FALSE
)
temporal <- readr::read_csv(
  file.path(diagnostics, "H06_v0_scaffold_pilot_temporal.csv"),
  show_col_types = FALSE
)
dharma <- readr::read_csv(
  file.path(diagnostics, "H06_v0_scaffold_pilot_DHARMa_100.csv"),
  show_col_types = FALSE
)
runtime <- readr::read_csv(
  file.path(diagnostics, "H06_v0_scaffold_pilot_simulation_runtime.csv"),
  show_col_types = FALSE
)
assessment <- readr::read_csv(
  file.path(tables, "H06_v0_scaffold_pilot_assessment.csv"),
  show_col_types = FALSE
)
effects <- readr::read_csv(
  file.path(tables, "H06_v0_scaffold_pilot_effects.csv"),
  show_col_types = FALSE
)
robust_assessment <- readr::read_csv(
  file.path(tables, "H06_v0_scaffold_pilot_robust_assessment.csv"),
  show_col_types = FALSE
)
robust_covariance <- readr::read_csv(
  file.path(
    diagnostics,
    "H06_v0_scaffold_pilot_robust_covariance_sensitivity.csv"
  ),
  show_col_types = FALSE
)
robust_deletions <- readr::read_csv(
  file.path(
    diagnostics,
    "H06_v0_scaffold_pilot_robust_targeted_deletions.csv"
  ),
  show_col_types = FALSE
)
robust_leave_site <- readr::read_csv(
  file.path(diagnostics, "H06_v0_scaffold_pilot_robust_leave_site.csv"),
  show_col_types = FALSE
)
figure_audit <- readr::read_csv(
  file.path(source_data, "H06_v0_scaffold_pilot_figure_readability.csv"),
  show_col_types = FALSE
)

fixed_scaffold <- paste(
  "site * work_free_day + site * activity_status +",
  "site * previous_sleep_duration_centered_h"
)
stopifnot(
  nrow(registry) == 6L,
  identical(as.integer(registry$candidate_order), seq_len(6L)),
  all(registry$fixed_effect_scaffold == fixed_scaffold),
  all(registry$collapsed_activity),
  !any(registry$confirmatory_clock_term),
  !any(grepl("clock_hour", registry$formula, fixed = TRUE)),
  !any(grepl("exercise_intensity", registry$formula, fixed = TRUE)),
  all(registry$inferential_status ==
    "feasibility_pilot_not_accepted_inference"),
  registry$diagnostic_simulations[
    registry$candidate_id != "glm_participant_cluster_robust"
  ] == 100L,
  is.na(registry$diagnostic_simulations[
    registry$candidate_id == "glm_participant_cluster_robust"
  ])
)

expected_samples <- data.frame(
  placement = c("glasses", "chest"),
  one_hour_observations = c(16596L, 18352L),
  participant_days = c(715L, 789L),
  participants = c(137L, 149L),
  sites = c(9L, 8L)
)
stopifnot(
  nrow(samples) == 2L,
  identical(samples$placement, expected_samples$placement),
  identical(
    as.integer(samples$one_hour_observations),
    expected_samples$one_hour_observations
  ),
  identical(as.integer(samples$participant_days), expected_samples$participant_days),
  identical(as.integer(samples$participants), expected_samples$participants),
  identical(as.integer(samples$sites), expected_samples$sites),
  all(samples$fixed_design_full_rank),
  all(samples$fixed_design_rank == samples$fixed_design_columns)
)

pilot_objects <- readRDS(
  file.path(models, "H06_v0_scaffold_pilot_models.rds")
)
stopifnot(identical(names(pilot_objects), c("glasses", "chest")))
for (placement in names(pilot_objects)) {
  object <- pilot_objects[[placement]]
  expected <- samples[samples$placement == placement, ]
  stopifnot(
    length(object$frame_row_ids) == expected$one_hour_observations,
    !anyDuplicated(object$frame_row_ids),
    identical(object$frame_sha256, expected$frame_sha256),
    identical(names(object$candidates), registry$candidate_id)
  )
  for (candidate_id in names(object$candidates)) {
    candidate <- object$candidates[[candidate_id]]
    stopifnot(
      nrow(candidate$data) == expected$one_hour_observations,
      identical(candidate$data$.model_row_id, object$frame_row_ids)
    )
  }
}

stopifnot(
  nrow(fit_status) == 12L,
  all(fit_status$converged),
  all(is.na(fit_status$error)),
  all(!fit_status$singular[
    fit_status$candidate_id %in% c(
      "tmb_v0_participant", "tmb_participant_day"
    )
  ]),
  all(fit_status$singular[
    fit_status$candidate_id %in% c(
      "tmb_participant_latent_ar", "tmb_participant_day_latent_ar"
    )
  ]),
  all(fit_status$random_component_boundary[
    fit_status$candidate_id == "bam_participant_day_working_ar"
  ]),
  all(!fit_status$random_component_boundary[
    fit_status$candidate_id == "glm_participant_cluster_robust"
  ])
)

stopifnot(
  nrow(temporal) == 12L,
  all(temporal$pearson_residual_lag1[
    temporal$candidate_id %in% c(
      "tmb_v0_participant", "tmb_participant_day"
    )
  ] > 0.25),
  all(temporal$pearson_residual_lag1[
    temporal$candidate_id %in% c(
      "tmb_participant_latent_ar", "tmb_participant_day_latent_ar"
    )
  ] < 0.06),
  temporal$standardized_residual_lag1[
    temporal$placement == "glasses" &
      temporal$candidate_id == "bam_participant_day_working_ar"
  ] > 0.10,
  temporal$standardized_residual_lag1[
    temporal$placement == "chest" &
      temporal$candidate_id == "bam_participant_day_working_ar"
  ] < 0.10
)

stopifnot(
  nrow(dharma) == 10L,
  all(dharma$simulations == 100L),
  all(dharma$uniformity_p < 0.001),
  all(dharma$zero_inflation_p < 0.001),
  all(dharma$outlier_p[
    !(dharma$placement == "glasses" &
      dharma$candidate_id == "tmb_participant_day")
  ] < 0.001),
  nrow(runtime) == 10L,
  all(runtime$simulations == 100L),
  all(runtime$production_status == "not_run_not_authorized")
)

stopifnot(
  nrow(assessment) == 12L,
  all(assessment$automated_pilot_screen[
    assessment$candidate_id == "glm_participant_cluster_robust"
  ] == "structurally_estimable_marginal_candidate"),
  all(assessment$structural_screen[
    assessment$candidate_id == "glm_participant_cluster_robust"
  ]),
  all(!assessment$distribution_screen[
    assessment$candidate_id != "glm_participant_cluster_robust"
  ]),
  nrow(effects) == 36L,
  all(effects$inferential_status ==
    "feasibility_pilot_not_accepted_inference")
)

stopifnot(
  nrow(robust_covariance) == 24L,
  identical(sort(unique(robust_covariance$covariance_type)),
    c("HC0", "HC1", "HC2", "HC3")),
  all(robust_covariance$participant_cluster_adjustment),
  all(robust_covariance$inferential_status ==
    "covariance_feasibility_pilot_not_accepted_inference")
)
for (placement in c("glasses", "chest")) {
  for (effect_id in unique(robust_covariance$effect_id)) {
    rows <- robust_covariance[
      robust_covariance$placement == placement &
        robust_covariance$effect_id == effect_id,
    ]
    stopifnot(
      rows$standard_error[rows$covariance_type == "HC3"] >=
        rows$standard_error[rows$covariance_type == "HC1"]
    )
  }
}

stopifnot(
  nrow(robust_deletions) == 30L,
  all(robust_deletions$refit_converged),
  all(is.finite(robust_deletions$shift_in_full_robust_se)),
  max(abs(robust_deletions$shift_in_full_robust_se[
    robust_deletions$placement == "chest"
  ])) > 1,
  nrow(robust_leave_site) == 51L,
  all(robust_leave_site$refit_converged),
  all(is.finite(robust_leave_site$shift_link)),
  nrow(robust_assessment) == 2L,
  !any(robust_assessment$confirmatory_clock_term),
  all(robust_assessment$inferential_status ==
    "feasibility_pilot_not_accepted_inference")
)

required_reader_files <- c(
  file.path(figures, "H06_v0_scaffold_pilot_effects.png"),
  file.path(figures, "H06_v0_scaffold_pilot_effects.pdf"),
  file.path(qa_artifacts, "H06_v0_scaffold_pilot_effects_A4_preview.pdf"),
  file.path(source_data, "H06_v0_scaffold_pilot_effects_figure.csv")
)
stopifnot(
  all(file.exists(required_reader_files)),
  nrow(figure_audit) == 1L,
  figure_audit$native_width_mm == 170,
  figure_audit$intended_width_mm == 170,
  figure_audit$scale_factor == 1,
  figure_audit$smallest_essential_nominal_text_pt == 7.5,
  figure_audit$effective_final_text_pt == 7.5,
  figure_audit$side_margin_mm == 20,
  figure_audit$a4_preview == paste0(
    "artifacts/12_manifests/H06/qa/",
    "H06_v0_scaffold_pilot_effects_A4_preview.pdf"
  ),
  figure_audit$report_011_status == "PASS"
)

implementation_files <- c(
  "pilot_h06_v0_scaffold_models.R",
  "assess_h06_v0_scaffold_robust_candidate.R",
  "build_h06_v0_scaffold_pilot_reader_artifacts.R"
)
implementation_text <- paste(unlist(lapply(implementation_files, function(file) {
  readLines(file.path(root, "scripts/hypotheses/H06", file), warn = FALSE)
})), collapse = "\n")
stopifnot(!grepl("discrete\\s*=\\s*FALSE", implementation_text))

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06/02a_v0_scaffold_model_pilots.qmd"
)
html_path <- sub("\\.qmd$", ".html", qmd_path)
stopifnot(file.exists(qmd_path), file.exists(html_path), file.info(html_path)$size > 1e6)
stopifnot(requireNamespace("xml2", quietly = TRUE))
html_text <- xml2::xml_text(xml2::read_html(html_path))
stopifnot(
  grepl("The V0 fixed-effects scaffold can be retained", html_text, fixed = TRUE),
  grepl("no H06 result is accepted", html_text, fixed = TRUE),
  grepl("REPORT-011 physical-size verification", html_text, fixed = TRUE),
  grepl("Participant-cluster robust marginal", html_text, fixed = TRUE)
)

message("H06 V0-scaffold pilot tests passed")
