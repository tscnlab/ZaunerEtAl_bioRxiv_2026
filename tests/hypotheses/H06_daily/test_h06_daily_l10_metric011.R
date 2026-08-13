#!/usr/bin/env Rscript

# Focused no-refit verification of the bounded H06_daily METRIC-011 branch.

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
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = c("", "NA"))
}
artifact <- function(stage, file) {
  file.path(root, "artifacts", stage, "H06_daily", file)
}
verify_manifest <- function(path) {
  manifest <- read_csv(path)
  absolute <- file.path(root, manifest$relative_path)
  stopifnot(
    all(file.exists(absolute)),
    identical(
      unname(vapply(absolute, sha256, character(1))),
      manifest$sha256
    ),
    identical(unname(file.info(absolute)$size), manifest$bytes)
  )
  invisible(manifest)
}

# Central independent verification and explicit author acceptance.
author_gate_path <- file.path(
  root,
  "audit/decisions/h06_daily_metric011_l10_author_gate.md"
)
acceptance_path <- file.path(
  root,
  "audit/decisions/h06_daily_metric011_l10_acceptance.md"
)
stopifnot(
  sha256(author_gate_path) ==
    "e6816a31b5253675c93ab7f3cacac7f2d415d4fd7159762475fa65bf2a142c28",
  sha256(acceptance_path) ==
    "5c1e7204e9bdd7f76ffbb0f960f2505ac5a4b23a4c94018d0dff3a33fcf4d9ea"
)
acceptance_text <- paste(readLines(acceptance_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("Decision ID: `H06-D-002`", acceptance_text, fixed = TRUE),
  grepl("Status: approved", acceptance_text, fixed = TRUE),
  grepl("accepted without changing", acceptance_text, fixed = TRUE),
  grepl("all 12", acceptance_text, ignore.case = TRUE),
  grepl("NON_ESTIMABLE_COMPONENT_FAILURE", acceptance_text, fixed = TRUE),
  grepl("15-metric family", acceptance_text, fixed = TRUE),
  grepl("No model, refit, prediction, resampling", acceptance_text, fixed = TRUE)
)

# Direct controlling identities.
input_contract <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_input_contract.csv"
))
expected_inputs <- c(
  metric011_decision =
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  metric011_evidence_manifest =
    "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
  metric_manifest =
    "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
  site_context_manifest =
    "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
  base_manifest =
    "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
  primary_near_eye =
    "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a",
  primary_chest =
    "497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057"
)
stopifnot(
  nrow(input_contract) == 13L,
  all(input_contract$identity_pass),
  identical(input_contract$expected_sha256, input_contract$actual_sha256),
  all(vapply(
    names(expected_inputs),
    function(id) {
      identical(
        input_contract$expected_sha256[input_contract$input_id == id],
        unname(expected_inputs[[id]])
      )
    },
    logical(1)
  ))
)

static_verdict <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_static_verdict.csv"
))
stopifnot(
  static_verdict$input_pins_pass,
  static_verdict$base_bundle_pass,
  static_verdict$component_frames == 36L,
  static_verdict$expected_component_frames == 36L,
  static_verdict$current_primary_changed_cells == 8L,
  static_verdict$expected_primary_changed_cells == 8L,
  static_verdict$gap_components_exactly_invariant,
  static_verdict$accepted_fit_preservations == 0L,
  static_verdict$model_fits_run == 0L
)

# Component frames and exact-zero handling.
registry <- read_csv(artifact(
  "06_model_data",
  "H06_daily_l10_metric011_frame_registry.csv"
))
stopifnot(
  nrow(registry) == 36L,
  setequal(registry$component, c("zero_occurrence", "positive_magnitude")),
  all(file.exists(file.path(root, registry$frame_path)))
)
for (index in seq_len(nrow(registry))) {
  row <- registry[index, ]
  frame <- readRDS(file.path(root, row$frame_path[[1L]]))
  stopifnot(
    identical(sha256(file.path(root, row$frame_path[[1L]])),
              row$frame_file_sha256[[1L]]),
    identical(object_sha256(frame), row$frame_object_sha256[[1L]])
  )
  if (row$component[[1L]] == "zero_occurrence") {
    stopifnot(
      all(frame$response_source >= 0),
      identical(frame$response_value, as.integer(frame$response_source == 0))
    )
  } else {
    stopifnot(
      all(frame$response_source > 0),
      max(abs(frame$response_value - log10(frame$response_source))) < 1e-12
    )
  }
}

zero_audit <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_exact_zero_audit.csv"
))
stopifnot(
  nrow(zero_audit) == 493L,
  sum(zero_audit$metric011_changed_source_cell) == 8L,
  sum(zero_audit$metric011_changed_source_cell &
        zero_audit$placement_id == "near_eye") == 3L,
  sum(zero_audit$metric011_changed_source_cell &
        zero_audit$placement_id == "chest") == 5L,
  all(grepl(
    "retained as event in zero-occurrence component",
    zero_audit$component_handling,
    fixed = TRUE
  ))
)

inventory <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_scenario_component_change_inventory.csv"
))
stopifnot(
  nrow(inventory) == 36L,
  all(inventory$exact_frame_identity_to_pre_metric011[
    inventory$dataset_id == "gap_timing_unaware"
  ]),
  all(inventory$fit_action[inventory$dataset_id == "gap_timing_unaware"] ==
        "FIT_REQUIRED_TO_COMPLETE_PREVIOUSLY_HELD_BRANCH"),
  !any(inventory$fit_action == "PRESERVE_ACCEPTED_FIT_BYTE_FOR_BYTE")
)

# Primary occurrence and joint estimability dispositions.
tests <- read_csv(artifact(
  "09_tables",
  "H06_daily_l10_metric011_model_tests.csv"
))
joint_near_eye <- tests |>
  dplyr::filter(
    .data$placement_id == "near_eye",
    .data$run_id %in% c(
      "primary__near_eye__all_available",
      "gap_timing_unaware__near_eye__all_available"
    ),
    .data$component == "joint_two_part"
  )
stopifnot(
  nrow(joint_near_eye) == 12L,
  all(joint_near_eye$test_status == "NON_ESTIMABLE_COMPONENT_FAILURE"),
  all(is.na(joint_near_eye$raw_p_value)),
  all(joint_near_eye$multiplicity_status ==
        "RAW_JOINT_SLOT_FAMILY_INCOMPLETE")
)
primary_occurrence <- tests |>
  dplyr::filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$component == "zero_occurrence"
  )
stopifnot(
  nrow(primary_occurrence) == 6L,
  all(grepl("NON_ESTIMABLE", primary_occurrence$test_status)),
  all(is.na(primary_occurrence$raw_p_value))
)

primary_verdict <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_primary_verdict.csv"
))
expected_positive_status <- c(
  work_free_day =
    "ACCEPTABLE_ONLY_WITH_MAJOR_FAMILY_SENSITIVITY_LIMITATION_NO_DIRECTIONAL_CLAIM",
  activity_status =
    "ACCEPTABLE_ONLY_WITH_FAMILY_SENSITIVITY_LIMITATION_NO_CONFIRMATORY_CLAIM",
  previous_sleep_duration_centered_h =
    "SENSITIVITY_UNRESOLVED_T_NUMERICAL_FAILURE_NO_STANDALONE_CLAIM"
)
positive_verdict <- primary_verdict |>
  dplyr::filter(.data$component == "positive_magnitude")
stopifnot(
  nrow(positive_verdict) == 3L,
  all(vapply(
    names(expected_positive_status),
    function(id) {
      identical(
        positive_verdict$component_disposition[
          positive_verdict$predictor_id == id
        ],
        unname(expected_positive_status[[id]])
      )
    },
    logical(1)
  ))
)

ar <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_ar_counterparts.csv"
))
work_occurrence_ar <- ar |>
  dplyr::filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$predictor_id == "work_free_day",
    .data$component == "zero_occurrence"
  )
sleep_positive_ar <- ar |>
  dplyr::filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$predictor_id == "previous_sleep_duration_centered_h",
    .data$component == "positive_magnitude"
  )
stopifnot(
  nrow(work_occurrence_ar) == 1L,
  work_occurrence_ar$ar_trigger,
  work_occurrence_ar$ar_fitted,
  abs(work_occurrence_ar$ar_rho) > 0.95,
  !work_occurrence_ar$ar_acceptable,
  work_occurrence_ar$disposition == "NOT_ACCEPTABLE_RHO_BOUNDARY",
  nrow(sleep_positive_ar) == 1L,
  sleep_positive_ar$ar_acceptable,
  abs(sleep_positive_ar$effect_shift_in_primary_se - 0.0394873) < 1e-5
)

# Conditional positive estimates and mandatory family diagnostics.
effects <- read_csv(artifact(
  "09_tables",
  "H06_daily_l10_metric011_effect_estimates.csv"
))
primary_gaussian <- effects |>
  dplyr::filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$family == "Gaussian identity on log10-positive L10"
  ) |>
  dplyr::arrange(.data$predictor_order)
stopifnot(
  nrow(primary_gaussian) == 3L,
  max(abs(primary_gaussian$estimate - c(
    0.925330009446909,
    0.864001920293348,
    0.775071825255658
  ))) <
    1e-6,
  all(primary_gaussian$lower_95 < primary_gaussian$estimate),
  all(primary_gaussian$upper_95 > primary_gaussian$estimate),
  all(primary_gaussian$interval_type ==
        "model-based pointwise 95% confidence interval")
)
one_part <- effects |>
  dplyr::filter(grepl("one-part", .data$family, fixed = TRUE))
stopifnot(
  nrow(one_part) == 18L,
  all(one_part$inferential_status == "DIAGNOSTIC_SENSITIVITY_ONLY"),
  !any(one_part$family %in% c("joint_two_part", "zero_occurrence"))
)

family <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_positive_family_sensitivity.csv"
)) |>
  dplyr::filter(.data$run_id == "primary__near_eye__all_available")
stopifnot(
  family$student_t_direction_reversal[family$predictor_id == "work_free_day"],
  abs(family$student_t_effect_shift_in_gaussian_se[
    family$predictor_id == "work_free_day"
  ] - 1.35) < 0.01,
  family$preliminary_status[
    family$predictor_id == "previous_sleep_duration_centered_h"
  ] == "NOT_ACCEPTABLE_T_SENSITIVITY_FAILED"
)

figure_source <- read_csv(artifact(
  "11_source_data",
  "H06_daily_l10_metric011_positive_component_figure_source.csv"
))
failed_t <- figure_source$family == "Student-t sensitivity" &
  grepl("UNRESOLVED", figure_source$inferential_status)
stopifnot(
  all(figure_source$interval_available[
    figure_source$family == "Gaussian primary component"
  ]),
  any(failed_t),
  !any(figure_source$interval_available[failed_t]),
  all(is.na(figure_source$lower_95[failed_t])),
  all(is.na(figure_source$upper_95[failed_t])),
  all(grepl("conditional", figure_source$estimand, ignore.case = TRUE))
)

# MAP diagnostics are regularized sensitivities and have no inferential fields.
map_coefficients <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_map_occurrence_coefficients.csv"
))
stopifnot(
  setequal(map_coefficients$prior_standard_deviation, c(1.5, 3, 6)),
  all(map_coefficients$prior_class == "fixef"),
  all(map_coefficients$prior_coefficients == paste0(
    "(Intercept) explicitly and all remaining conditional fixed effects"
  )),
  all(map_coefficients$converged),
  !any(grepl("p_value|confidence", names(map_coefficients))),
  all(grepl("no ordinary", map_coefficients$inferential_role))
)

# Multiplicity keeps the L10 slot and does not substitute a component result.
bh <- read_csv(artifact(
  "09_tables",
  "H06_daily_l10_metric011_bh_slot_families.csv"
))
l10_slots <- bh |>
  dplyr::filter(.data$metric_slot == 3L)
stopifnot(
  nrow(l10_slots) == 12L,
  all(l10_slots$slot_status == "NON_ESTIMABLE_COMPONENT_FAILURE"),
  all(is.na(l10_slots$raw_p_value)),
  all(is.na(l10_slots$bh_adjusted_p_value)),
  all(l10_slots$family_slots_required == 15L),
  all(l10_slots$family_slots_available == 1L),
  all(l10_slots$family_status == "INCOMPLETE_1_OF_15_NO_BH_DECISION")
)
mder_slots <- bh |>
  dplyr::filter(.data$metric_slot == 15L)
mder_source <- read_csv(artifact(
  "09_tables",
  "H06_daily_mder_metric010_model_tests.csv"
)) |>
  dplyr::filter(.data$placement_id == "near_eye") |>
  dplyr::select(
    "dataset_id",
    "predictor_id",
    "test_type",
    source_raw_p_value = "raw_p_value"
  )
mder_join <- mder_slots |>
  dplyr::left_join(
    mder_source,
    by = c("dataset_id", "predictor_id", "test_type"),
    relationship = "many-to-one"
  )
stopifnot(
  nrow(mder_slots) == 12L,
  all(!is.na(mder_join$source_raw_p_value)),
  max(abs(mder_join$raw_p_value - mder_join$source_raw_p_value)) < 1e-15,
  all(is.na(mder_join$bh_adjusted_p_value))
)

# Influence and no-refit provenance.
influence_runtime <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_positive_influence_runtime.csv"
))
influence_summary <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_positive_influence_summary.csv"
))
stopifnot(
  influence_runtime$refits == 440L,
  influence_runtime$failures == 0L,
  influence_runtime$serial_processes == 1L,
  influence_runtime$component == "positive_magnitude",
  influence_runtime$occurrence_or_joint_refits == 0L,
  sum(influence_summary$participant_deletions) == 413L,
  sum(influence_summary$site_deletions) == 27L,
  influence_summary$maximum_site_shift_in_full_se[
    influence_summary$predictor_id == "activity_status"
  ] > 1
)

equivalence <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_no_refit_model_equivalence.csv"
))
stopifnot(
  nrow(equivalence) == 194L,
  all(equivalence$object_identical),
  all(equivalence$object_sha256_before == equivalence$object_sha256_after),
  all(equivalence$change_scope == "disposition strings only; no fit rerun")
)

preservation <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_l10_metric011_protected_preservation_final.csv"
))
stopifnot(
  nrow(preservation) == 294L,
  all(preservation$preserved_byte_for_byte),
  all(preservation$sha256_before == preservation$sha256_after)
)
historical <- c(
  "audit/hypotheses/H06_daily/06_daily_ar_repair_pilot.qmd" =
    "af4948a2b0338cf3e208379f5c9530706620cdac6c92a58c4ada15420512d231",
  "audit/hypotheses/H06_daily/06_daily_ar_repair_pilot.html" =
    "baf18696e5789433db3f1ee3f13d5acc8617282b4b3f8e4e7703646df38894af",
  "audit/hypotheses/H06_daily/07_pre_sleep_no_nugget_diagnostic.qmd" =
    "c613fb72617bec827d1cf1ebfdb346c1995de4a2ca37439983a85c925f838951",
  "audit/hypotheses/H06_daily/07_pre_sleep_no_nugget_diagnostic.html" =
    "c0c335c6862cd018e414b767c17cc71236386cf266ea9e8b563b9189f36bae3a"
)
stopifnot(identical(
  unname(vapply(file.path(root, names(historical)), sha256, character(1))),
  unname(historical)
))

# Report and manifest contract.
qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/08_l10_metric011_amendment.qmd"
)
html_path <- sub("[.]qmd$", ".html", qmd_path)
transition_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_l10_metric011_transition.md"
  )
)
report_text <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
transition_text <- paste(readLines(transition_path, warn = FALSE), collapse = "\n")
handoff_text <- paste(readLines(
  file.path(root, "audit/handoffs/H06_daily_worker_handoff.md"),
  warn = FALSE
), collapse = "\n")
stopifnot(
  file.exists(html_path),
  sha256(qmd_path) ==
    "2a13894ed53f0cbe660f2855e3f994ce2041d6408ac36b650a0a4bbff2d6cade",
  sha256(html_path) ==
    "db255bc7d5aba1f71fa8c42ab4de0ebef3807210d45c99f805cfad6074b8a109",
  grepl("H06-D-G2P-L10-METRIC011", report_text, fixed = TRUE),
  grepl("NON_ESTIMABLE_COMPONENT_FAILURE", report_text, fixed = TRUE),
  grepl("pointwise", report_text, ignore.case = TRUE),
  grepl(
    "no[[:space:]]+simultaneous interval",
    report_text,
    ignore.case = TRUE
  ),
  grepl("conditional", report_text, ignore.case = TRUE),
  grepl("no ordinary confidence interval", report_text, ignore.case = TRUE),
  !grepl("6.14e-5|6.14e-05|0.0000614", report_text),
  grepl("H06-D-002 / CHG-109", transition_text, fixed = TRUE),
  grepl("accepted exactly as recommended", transition_text, ignore.case = TRUE),
  grepl("all 12", transition_text, ignore.case = TRUE),
  grepl("NON_ESTIMABLE_COMPONENT_FAILURE", transition_text, fixed = TRUE),
  grepl("shifted-log estimand", transition_text, fixed = TRUE),
  grepl("not substituted", transition_text, fixed = TRUE),
  grepl("remaining daily production grid", transition_text, ignore.case = TRUE),
  grepl("H06-D-002 / CHG-109", handoff_text, fixed = TRUE),
  grepl("No further fit, remaining-grid work", handoff_text, fixed = TRUE)
)

manifest_names <- c(
  "H06_daily_l10_metric011_production_input_manifest.csv",
  "H06_daily_l10_metric011_production_code_manifest.csv",
  "H06_daily_l10_metric011_production_output_manifest.csv"
)
production_manifest_paths <- file.path(
  root,
  "artifacts/12_manifests/H06_daily",
  manifest_names
)
production_manifests <- lapply(production_manifest_paths, verify_manifest)
stopifnot(
  identical(vapply(production_manifests, nrow, integer(1)), c(55L, 11L, 91L)),
  identical(
    unname(vapply(production_manifest_paths, sha256, character(1))),
    c(
      "7772792dfa69eccd0941618193ede0b565abaa6856b151e77dde833b765a9339",
      "5261d2561a28e20ac5afc3bdb00c915790afa4c7a47b7c6d9aaa5c7013ef5538",
      "af89132e004e29d27351302b0f765ce9845da53fb6619d8d042aaa980165626c"
    )
  )
)
closure_manifest_names <- paste0(
  "H06_daily_l10_metric011_acceptance_closure_",
  c("input_manifest.csv", "code_manifest.csv", "output_manifest.csv")
)
closure_manifests <- lapply(
  file.path(
    root,
    "artifacts/12_manifests/H06_daily",
    closure_manifest_names
  ),
  verify_manifest
)
stopifnot(identical(
  vapply(closure_manifests, nrow, integer(1)),
  c(9L, 1L, 2L)
))
closure_software <- read_csv(file.path(
  root,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_l10_metric011_acceptance_closure_software_manifest.csv"
  )
))
stopifnot(
  nrow(closure_software) == 4L,
  setequal(closure_software$software, c("R", "digest", "dplyr", "readr")),
  closure_software$version[closure_software$software == "R"] == "4.6.1",
  all(closure_software$role == "no-refit acceptance-closure verification")
)
report_manifest <- verify_manifest(file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_l10_metric011_report_manifest.csv"
  )
))
stopifnot(
  nrow(report_manifest) == 118L,
  all(c(
    "audit/decisions/h06_daily_metric011_l10_author_gate.md",
    "audit/decisions/h06_daily_metric011_l10_acceptance.md"
  ) %in% report_manifest$relative_path),
  all(grepl("H06_daily_l10_metric011", basename(
    report_manifest$relative_path[
      grepl("^artifacts/", report_manifest$relative_path)
    ]
  ))),
  !any(grepl(
    "H06_daily_stage2.*production|notebooks/hypotheses/H06_daily",
    report_manifest$relative_path
  ))
)

cat(
  paste(
    "H06_daily METRIC-011 focused tests passed:",
    "13 pinned inputs; 36 component frames; 8 numerical-zero repairs;",
    "12 non-estimable near-eye joint slots; 15-slot families retained;",
    "440 positive-only influence refits; 194 unchanged model objects;",
    "294 protected files unchanged; H06-D-002 accepted;",
    "no-refit closure and 118-entry report manifest sealed.\n"
  )
)
