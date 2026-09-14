# Verify the isolated H01 METRIC-010 point refit and required stop gates.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

point_root <- file.path(
  root,
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/",
    "point_refit_repaired_gap"
  )
)
gate_root <- file.path(
  root,
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/",
    "author_gate_post_repair"
  )
)
read_gate <- function(name) {
  path <- file.path(gate_root, name)
  stopifnot(file.exists(path))
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

message("Checking the displayed METRIC-010 decision identity")
decision_path <- "audit/decisions/mder_mean_of_viable_ratios.md"
gate_doc_path <- paste0(
  "audit/hypotheses/H01/mder_METRIC-010/",
  "H01_METRIC-010_author_gate.md"
)
gate_manifest <- read_gate("H01_METRIC-010_author_gate_manifest.csv")
decision_manifest_row <- gate_manifest$path == decision_path
gate_doc_lines <- readLines(file.path(root, gate_doc_path), warn = FALSE)
displayed_decision_line <- grep(
  "^\\| METRIC-010 decision \\| `[0-9a-f]{64}` \\|$",
  gate_doc_lines,
  value = TRUE
)
stopifnot(
  length(displayed_decision_line) == 1L,
  sum(decision_manifest_row) == 1L
)
displayed_decision_sha256 <- sub(
  "^.*`([0-9a-f]{64})`.*$",
  "\\1",
  displayed_decision_line
)
current_decision_sha256 <- artifact_sha256(file.path(root, decision_path))
manifest_decision_sha256 <- gate_manifest$sha256[decision_manifest_row]
stopifnot(
  identical(displayed_decision_sha256, current_decision_sha256),
  identical(displayed_decision_sha256, manifest_decision_sha256)
)

message("Checking the METRIC-010 H01 contract and isolated target registry")
registry <- h01_metric_registry()
stopifnot(
  registry$metric_id[registry$metric_order == 17L] ==
    "mder_mean_of_viable_ratios",
  registry$response_family[registry$metric_order == 17L] == "gaussian",
  registry$response_transform[registry$metric_order == 17L] == "identity"
)

point_samples <- readr::read_csv(
  file.path(
    point_root,
    "artifacts/09_tables/H01/H01_exact_samples.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
stopifnot(
  nrow(point_samples) == 8L,
  all(point_samples$metric_id == "mder_mean_of_viable_ratios"),
  all(point_samples$sample_status == "FITTED"),
  all(point_samples$participants > 0L),
  all(point_samples$participant_days == point_samples$observations)
)
expected_days <- c(
  main__chest__all_available = 732L,
  main__chest__paired_common_sample = 489L,
  main__glasses__all_available = 702L,
  main__glasses__paired_common_sample = 489L,
  manuscript_prepared_data__chest__all_available = 723L,
  manuscript_prepared_data__chest__paired_common_sample = 478L,
  manuscript_prepared_data__glasses__all_available = 687L,
  manuscript_prepared_data__glasses__paired_common_sample = 478L
)
observed_days <- stats::setNames(
  point_samples$participant_days,
  point_samples$run_id
)
stopifnot(identical(
  as.integer(unname(observed_days[names(expected_days)])),
  as.integer(unname(expected_days))
))

message("Checking the provisional complete 17-test BH families")
tests <- read_gate("H01_METRIC-010_provisional_model_level_tests.csv")
stopifnot(
  nrow(tests) == 8L * 4L * 17L,
  all(tests$family_n == 17L),
  all(tests$family_status == "COMPLETE")
)
families <- split(tests, tests$family_instance_id)
stopifnot(all(vapply(families, nrow, integer(1)) == 17L))
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

impact <- read_gate("H01_METRIC-010_complete_BH_impact.csv")
non_mder <- impact$metric_order != 17L
stopifnot(all(
  impact$raw_p_unchanged_for_non_mder[non_mder],
  na.rm = TRUE
))
primary_change <- impact[
  impact$run_id == "main__glasses__all_available" &
    impact$support_changed,
  ,
  drop = FALSE
]
stopifnot(
  nrow(primary_change) == 4L,
  sum(primary_change$metric_order == 17L) == 3L,
  sum(
    primary_change$new_metric_id == "duration_below_10_pre_sleep",
    na.rm = TRUE
  ) == 1L
)

message("Checking the repaired gap-timing-unaware construct")
invalid <- read_gate("H01_METRIC-010_construct_impossible_gap_rows.csv")
stopifnot(nrow(invalid) == 0L)
common_day <- read_gate(
  "H01_METRIC-010_gap_primary_common_day_comparison.csv"
)
stopifnot(
  identical(common_day$common_participant_days, c(687, 723)),
  all(abs(common_day$mean_paired_difference_gap_minus_primary) < 0.0001)
)
paired_placement <- read_gate(
  "H01_METRIC-010_paired_placement_point_comparison.csv"
)
stopifnot(
  nrow(paired_placement) == 4L,
  all(paired_placement$sample_exactly_matched),
  all(paired_placement$same_side_of_null),
  sum(paired_placement$support_switch) == 2L,
  file.exists(file.path(
    gate_root,
    "H01_METRIC-010_paired_placement_point_comparison.png"
  ))
)
gate <- read_gate("H01_METRIC-010_gate_summary.csv")
stopifnot(
  gate$point_runs_with_major_diagnostic_failure == 0L,
  gate$primary_mder_family_support_changes == 3L,
  gate$primary_non_mder_family_support_changes == 1L,
  gate$construct_impossible_gap_fit_rows == 0L,
  gate$construct_impossible_gap_physical_days == 0L,
  !gate$bootstrap_pilot_launched,
  gate$shared_change_request_status == "RESOLVED_BY_COORDINATOR_REPAIR",
  gate$gate_status == "STOP_AUTHOR_GATE_MATERIAL_INFERENCE_CHANGE"
)

message("Checking that accepted non-MDER artifacts remain frozen")
frozen <- read_gate("H01_METRIC-010_frozen_non_mder_artifact_baseline.csv")
frozen_paths <- file.path(root, frozen$path)
stopifnot(
  nrow(frozen) > 0L,
  all(file.exists(frozen_paths)),
  identical(
    unname(vapply(frozen_paths, artifact_sha256, character(1))),
    unname(frozen$sha256)
  )
)

message("Checking point-refit and author-gate manifests")
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
  all(file.exists(point_paths)),
  identical(
    unname(vapply(point_paths, artifact_sha256, character(1))),
    unname(point_manifest$sha256)
  )
)

gate_paths <- file.path(root, gate_manifest$path)
stopifnot(
  all(file.exists(gate_paths)),
  identical(
    unname(vapply(gate_paths, artifact_sha256, character(1))),
    unname(gate_manifest$sha256)
  )
)

message("H01 METRIC-010 author-gate verification passed")
