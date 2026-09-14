# Verify the bounded H01 METRIC-011 L10 author gate.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

audit_root <- file.path(
  root,
  "audit/hypotheses/H01/l10_METRIC-011"
)
point_root <- file.path(audit_root, "point_refit")
pilot_root <- file.path(audit_root, "bootstrap_pilot")
gate_root <- file.path(audit_root, "author_gate")
read_gate <- function(name) {
  path <- file.path(gate_root, name)
  stopifnot(file.exists(path))
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

message("Checking METRIC-011 input pins and displayed decision identity")
pin_paths <- c(
  metric_decision = "audit/decisions/l10_numerical_zero_normalization.md",
  evidence_manifest = paste0(
    "audit/reconciliation/l10_METRIC-011/",
    "METRIC-011_evidence_manifest.csv"
  ),
  main_manifest = "artifacts/12_manifests/H01_model_data_artifacts.csv",
  main_rds = "artifacts/06_model_data/H01.rds",
  gap_manifest = paste0(
    "artifacts/12_manifests/",
    "H01_manuscript_prepared_data_artifacts.csv"
  ),
  gap_rds = paste0(
    "artifacts/06_model_data/H01/scenarios/",
    "manuscript_prepared_data/H01.rds"
  )
)
pin_sha256 <- c(
  metric_decision =
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  evidence_manifest =
    "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
  main_manifest =
    "25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72",
  main_rds =
    "0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00",
  gap_manifest =
    "e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b",
  gap_rds =
    "3c70363fc0468202a431904aa9d9444f2858af2e3add3475a56c872b49a18bd6"
)
absolute_pin_paths <- stats::setNames(
  file.path(root, unname(pin_paths)),
  names(pin_paths)
)
stopifnot(
  all(file.exists(absolute_pin_paths)),
  identical(
    unname(vapply(absolute_pin_paths, artifact_sha256, character(1))),
    unname(pin_sha256)
  )
)
pins <- read_gate("H01_METRIC-011_input_pins.csv")
pins <- pins[match(names(pin_paths), pins$input_id), , drop = FALSE]
stopifnot(
  identical(pins$path, unname(pin_paths)),
  identical(pins$sha256, unname(pin_sha256)),
  identical(pins$expected_sha256, unname(pin_sha256)),
  all(pins$status == "PASS")
)

gate_doc_path <- file.path(audit_root, "H01_METRIC-011_author_gate.md")
gate_doc_lines <- readLines(gate_doc_path, warn = FALSE)
displayed_decision_line <- grep(
  "^\\| METRIC-011 decision \\| `[0-9a-f]{64}` \\|$",
  gate_doc_lines,
  value = TRUE
)
stopifnot(length(displayed_decision_line) == 1L)
displayed_decision_sha256 <- sub(
  "^.*`([0-9a-f]{64})`.*$",
  "\\1",
  displayed_decision_line
)
stopifnot(identical(
  displayed_decision_sha256,
  artifact_sha256(absolute_pin_paths[["metric_decision"]])
))

message("Checking the isolated L10 model contract and exact samples")
registry <- h01_metric_registry()
l10 <- registry[registry$metric_order == 5L, , drop = FALSE]
stopifnot(
  nrow(l10) == 1L,
  l10$metric_id == "l10_mean_medi",
  l10$response_family == "gaussian",
  l10$response_transform == "log10_offset_0.1",
  l10$effect_scale == "ratio"
)
samples <- read_gate("H01_METRIC-011_exact_samples.csv")
stopifnot(
  nrow(samples) == 4L,
  all(samples$data_scenario_id == "main"),
  all(samples$metric_id == "l10_mean_medi"),
  all(samples$sample_status == "FITTED"),
  all(samples$participant_days == samples$observations),
  all(samples$derivation_support_status == "unavailable")
)
expected_samples <- tibble::tribble(
  ~run_id, ~participants, ~participant_days, ~sites,
  "main__chest__all_available", 154L, 902L, 8L,
  "main__chest__paired_common_sample", 112L, 643L, 8L,
  "main__glasses__all_available", 141L, 816L, 9L,
  "main__glasses__paired_common_sample", 112L, 643L, 8L
)
observed_samples <- samples |>
  dplyr::select(run_id, participants, participant_days, sites) |>
  dplyr::arrange(.data$run_id)
expected_samples <- expected_samples |>
  dplyr::arrange(.data$run_id)
stopifnot(isTRUE(all.equal(
  observed_samples,
  expected_samples,
  check.attributes = FALSE
)))

message("Checking exact-zero normalization scope and unchanged gap frames")
frames <- read_gate("H01_METRIC-011_model_frame_comparison.csv")
changed <- read_gate("H01_METRIC-011_changed_model_rows.csv")
stopifnot(
  nrow(frames) == 8L,
  all(frames$row_keys_identical),
  sum(
    frames$changed_value_rows[
      frames$data_scenario_id == "main" &
        frames$sample_scenario == "all_available"
    ]
  ) == 8L,
  sum(frames$changed_value_rows[frames$data_scenario_id == "main"]) == 16L,
  all(
    frames$changed_value_rows[
      frames$data_scenario_id == "manuscript_prepared_data"
    ] == 0L
  ),
  nrow(changed) == 16L,
  all(changed$current_value == 0),
  max(abs(changed$accepted_value)) < 5e-17
)
all_available_changed <- changed[
  changed$sample_scenario == "all_available",
  ,
  drop = FALSE
]
changed_physical_keys <- paste(
  all_available_changed$placement,
  all_available_changed$participant_key,
  all_available_changed$local_date,
  sep = "::"
)
stopifnot(length(unique(changed_physical_keys)) == 8L)

message("Checking complete four-by-17 Benjamini-Hochberg families")
tests <- read_gate("H01_METRIC-011_complete_model_level_tests.csv")
stopifnot(
  nrow(tests) == 4L * 4L * 17L,
  all(tests$family_n == 17L),
  all(tests$family_status == "COMPLETE")
)
families <- split(tests, tests$family_instance_id)
stopifnot(
  length(families) == 16L,
  all(vapply(families, nrow, integer(1)) == 17L)
)
for (family in families) {
  observed <- !is.na(family$p_raw)
  expected <- rep(NA_real_, nrow(family))
  expected[observed] <- stats::p.adjust(
    family$p_raw[observed],
    method = "BH",
    n = 17L
  )
  stopifnot(isTRUE(all.equal(
    expected,
    family$p_adjusted,
    tolerance = 1e-12,
    check.attributes = FALSE
  )))
}
impact <- read_gate("H01_METRIC-011_complete_BH_impact.csv")
non_l10 <- impact$metric_id != "l10_mean_medi"
stopifnot(
  all(impact$raw_p_unchanged_for_non_l10[non_l10]),
  !any(impact$support_changed),
  max(abs(impact$raw_p_delta[!non_l10]), na.rm = TRUE) < 1e-11,
  max(abs(impact$adjusted_p_delta), na.rm = TRUE) < 1e-11
)

message("Checking diagnostics, influence, and paired/common comparison")
diagnostics <- read_gate("H01_METRIC-011_model_diagnostics.csv")
stopifnot(
  nrow(diagnostics) == 4L,
  all(diagnostics$converged),
  all(diagnostics$positive_definite_hessian),
  !any(diagnostics$singular),
  !any(diagnostics$diagnostic_status == "FAIL_MAJOR_GATE"),
  all(diagnostics$diagnostic_status == "WARN_REVIEW")
)
diagnostic_comparison <- read_gate(
  "H01_METRIC-011_diagnostic_comparison.csv"
)
stopifnot(all(
  diagnostic_comparison$diagnostic_status_old ==
    diagnostic_comparison$diagnostic_status_new
))
influence <- read_gate("H01_METRIC-011_influence_comparison.csv")
stopifnot(
  nrow(influence) == 4L,
  all(influence$failed_refits_new == 0L),
  max(abs(
    influence$maximum_absolute_dfbeta_old -
      influence$maximum_absolute_dfbeta_new
  )) < 1e-6,
  identical(
    influence$maximum_participant_old,
    influence$maximum_participant_new
  ),
  identical(influence$maximum_term_old, influence$maximum_term_new)
)
paired <- read_gate("H01_METRIC-011_paired_placement_comparison.csv")
stopifnot(
  nrow(paired) == 2L,
  all(paired$sample_exactly_matched),
  all(paired$near_participants == 112L),
  all(paired$chest_participants == 112L),
  all(paired$near_participant_days == 643L),
  all(paired$chest_participant_days == 643L),
  all(paired$near_observations == 643L),
  all(paired$chest_observations == 643L),
  all(paired$near_sites == 8L),
  all(paired$chest_sites == 8L)
)

message("Checking the unchanged gap-timing-unaware sensitivity")
gap <- read_gate("H01_METRIC-011_gap_timing_unaware_comparison.csv")
gap_frames <- frames[frames$data_scenario_id == "manuscript_prepared_data", ]
stopifnot(
  nrow(gap) == 8L,
  all(gap$gap_status == "PASS"),
  all(gap_frames$changed_value_rows == 0L),
  all(gap_frames$current_frame_identical)
)

message("Checking the 50-refit pilot and its non-inferential status")
pilot_label <- "PILOT — NOT FOR INFERENCE OR MANUSCRIPT REPORTING"
pilot_provenance <- readr::read_csv(
  file.path(
    pilot_root,
    "diagnostics/H01_METRIC-011_bootstrap_pilot_provenance.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
pilot_audit <- readr::read_csv(
  file.path(
    pilot_root,
    "diagnostics/H01_METRIC-011_bootstrap_pilot_audit.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
stopifnot(
  nrow(pilot_provenance) == 1L,
  pilot_provenance$inference_status == pilot_label,
  pilot_provenance$successful_refits_per_target == 50L,
  pilot_provenance$planned_targets == 4L,
  pilot_provenance$completed_targets == 4L,
  pilot_provenance$total_failed_refits == 0L,
  pilot_provenance$total_warning_refits == 0L,
  pilot_provenance$pilot_status ==
    "PASS_AWAITING_AUTHOR_PRODUCTION_APPROVAL",
  nrow(pilot_audit) == 4L,
  all(pilot_audit$inference_status == pilot_label),
  all(pilot_audit$used_refits == 50L),
  all(pilot_audit$failed_refits == 0L),
  all(pilot_audit$warning_refits == 0L),
  all(pilot_audit$status == "PASS")
)
draw_paths <- Sys.glob(file.path(
  pilot_root,
  "draws/*/*/l10_mean_medi_draws.rds"
))
stopifnot(length(draw_paths) == 4L)
for (draw_path in draw_paths) {
  draws <- readRDS(draw_path)
  stopifnot(
    nrow(draws) == 50L,
    all(draws$status == "PASS"),
    all(draws$warning_count == 0L)
  )
}
gate <- read_gate("H01_METRIC-011_gate_summary.csv")
stopifnot(
  gate$unique_primary_cells_normalized == 8L,
  gate$changed_fitted_rows_across_all_primary_runs == 16L,
  gate$exact_sample_changes == 0L,
  gate$major_diagnostic_failures == 0L,
  gate$l10_support_changes == 0L,
  gate$non_l10_BH_support_changes == 0L,
  gate$gap_l10_changed_rows == 0L,
  gate$pilot_targets == 4L,
  gate$pilot_successful_refits_per_target == 50L,
  gate$pilot_failed_refits == 0L,
  gate$pilot_warning_refits == 0L,
  !gate$production_bootstrap_launched,
  !gate$reader_report_merge_started,
  gate$gate_status == "STOP_AUTHOR_GATE_PRODUCTION_BOOTSTRAP_APPROVAL"
)

message("Checking frozen non-L10, gap-L10, and METRIC-010 artifacts")
protected <- read_gate("H01_METRIC-011_protected_artifact_baseline.csv")
protected_paths <- file.path(root, protected$path)
stopifnot(
  nrow(protected) > 0L,
  all(c(
    "NON_L10_ACCEPTED_ARTIFACT",
    "UNCHANGED_GAP_L10_ARTIFACT",
    "METRIC-010_GATE_DO_NOT_DISTURB"
  ) %in% protected$protection_reason),
  all(file.exists(protected_paths)),
  identical(
    unname(vapply(protected_paths, artifact_sha256, character(1))),
    unname(protected$sha256)
  )
)

message("Checking point, pilot, and gate manifests")
historical_contract_sha256 <-
  "9151f2ca8ef549d16df1465768ed5b33c0aa33b37dc315a13e06d795ba20de2e"
current_contract_sha256 <-
  "dfa35f7c8a1ca8a1f2132c6930a8ac219c461ffac769a7423bf85522430da81a"
historical_gate_test_sha256 <-
  "fbbeab68b6680241c33a755f7aeb29e9f5e8b46a660968c642641d189b12d177"
verify_historical_gate_manifest <- function(
  manifest,
  paths,
  include_gate_test = FALSE
) {
  observed <- unname(vapply(paths, artifact_sha256, character(1)))
  historical_paths <- c(
    "scripts/hypotheses/H01/h01_contract.R"
  )
  historical_sha256 <- c(historical_contract_sha256)
  if (include_gate_test) {
    historical_paths <- c(
      historical_paths,
      "tests/hypotheses/H01/test_h01_l10_METRIC011_gate.R"
    )
    historical_sha256 <- c(
      historical_sha256,
      historical_gate_test_sha256
    )
  }
  historical_row <- match(historical_paths, manifest$path)
  current_sha256 <- c(
    current_contract_sha256,
    if (include_gate_test) observed[historical_row[[2L]]] else NULL
  )
  stopifnot(
    !anyNA(historical_row),
    identical(unname(manifest$sha256[historical_row]), historical_sha256),
    identical(observed[historical_row], current_sha256),
    identical(
      observed[-historical_row],
      unname(manifest$sha256[-historical_row])
    )
  )
  invisible(TRUE)
}
point_manifest <- readr::read_csv(
  file.path(
    point_root,
    "artifacts/12_manifests/H01_model_results_artifacts.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
point_paths <- ifelse(
  startsWith(point_manifest$path, "artifacts/"),
  file.path(point_root, point_manifest$path),
  file.path(root, point_manifest$path)
)
stopifnot(
  all(point_manifest$main_input_manifest_sha256 ==
    pin_sha256[["main_manifest"]]),
  all(point_manifest$manuscript_prepared_input_manifest_sha256 ==
    pin_sha256[["gap_manifest"]]),
  all(file.exists(point_paths))
)
verify_historical_gate_manifest(point_manifest, point_paths)
pilot_manifest <- readr::read_csv(
  file.path(pilot_root, "H01_METRIC-011_bootstrap_pilot_manifest.csv"),
  show_col_types = FALSE,
  progress = FALSE
)
pilot_manifest_paths <- file.path(root, pilot_manifest$path)
stopifnot(
  all(pilot_manifest$inference_status == pilot_label),
  all(file.exists(pilot_manifest_paths))
)
verify_historical_gate_manifest(pilot_manifest, pilot_manifest_paths)
gate_manifest <- read_gate("H01_METRIC-011_author_gate_manifest.csv")
decision_manifest_row <- gate_manifest$path == pin_paths[["metric_decision"]]
stopifnot(
  sum(decision_manifest_row) == 1L,
  identical(
    gate_manifest$sha256[decision_manifest_row],
    displayed_decision_sha256
  )
)
gate_manifest_paths <- file.path(root, gate_manifest$path)
stopifnot(
  all(file.exists(gate_manifest_paths))
)
verify_historical_gate_manifest(
  gate_manifest,
  gate_manifest_paths,
  include_gate_test = TRUE
)

message("H01 METRIC-011 bounded author-gate verification passed")
