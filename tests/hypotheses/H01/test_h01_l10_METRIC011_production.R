# Verify isolated H01 METRIC-011 production bootstrap outputs without refits.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

audit_root <- file.path(
  root,
  "audit/hypotheses/H01/l10_METRIC-011"
)
production_root <- file.path(audit_root, "bootstrap_production")
diagnostic_root <- file.path(production_root, "diagnostics")
read_production <- function(path) {
  stopifnot(file.exists(path))
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

production_label <-
  "PRODUCTION — 1,000 successful joint bootstrap refits"
audit <- read_production(file.path(
  diagnostic_root,
  "H01_METRIC-011_bootstrap_production_audit.csv"
))
failures <- read_production(file.path(
  diagnostic_root,
  "H01_METRIC-011_bootstrap_production_failures.csv"
))
runtime <- read_production(file.path(
  diagnostic_root,
  "H01_METRIC-011_bootstrap_production_runtime.csv"
))
provenance <- read_production(file.path(
  diagnostic_root,
  "H01_METRIC-011_bootstrap_production_provenance.csv"
))
summaries <- read_production(file.path(
  production_root,
  "tables/H01_METRIC-011_bootstrap_production_r2_summaries.csv"
))

message("Checking four isolated 1,000-refit production targets")
target_key <- paste(audit$run_id, audit$metric_id, sep = "::")
stopifnot(
  nrow(audit) == 4L,
  length(unique(target_key)) == 4L,
  all(audit$data_scenario_id == "main"),
  all(audit$metric_id == "l10_mean_medi"),
  all(audit$inference_status == production_label),
  all(audit$status == "PASS"),
  all(audit$attempted_refits == 1500L),
  all(audit$successful_refits >= 1000L),
  all(audit$used_refits == 1000L),
  all(audit$failed_refits ==
    audit$attempted_refits - audit$successful_refits),
  nrow(failures) == sum(audit$failed_refits),
  nrow(runtime) == 4L,
  all(runtime$successful_draws == 1000L),
  all(runtime$inference_status == production_label),
  all(runtime$checkpoint_status %in% c(
    "WROTE_COMPLETED_TARGET_CHECKPOINT",
    "REUSED_COMPLETED_TARGET_CHECKPOINT"
  )),
  length(unique(audit$production_contract_sha256)) == 1L,
  identical(
    unique(audit$production_contract_sha256),
    unique(runtime$production_contract_sha256)
  )
)

draw_paths <- Sys.glob(file.path(
  production_root,
  "draws/*/*/l10_mean_medi_draws.rds"
))
stopifnot(length(draw_paths) == 4L)
measure_columns <- c(
  "marginal_r2",
  "conditional_r2",
  "participant_associated_share",
  "site_part_r2",
  "photoperiod_part_r2",
  "latitude_model_marginal_r2",
  "latitude_part_r2",
  "unrepresented_share"
)
for (draw_path in draw_paths) {
  draw <- readRDS(draw_path)
  stopifnot(
    nrow(draw) == 1000L,
    all(measure_columns %in% names(draw)),
    all(draw$status == "PASS"),
    identical(sort(unique(draw$bootstrap_replicate)), seq_len(1000L)),
    !anyDuplicated(draw[c("approximation", "bootstrap_replicate")]),
    all(draw$attempt >= 1L & draw$attempt <= 1500L),
    all(vapply(
      draw[measure_columns],
      function(value) all(is.finite(value) | is.na(value)),
      logical(1)
    ))
  )
}

message("Checking all production 95% interval rows")
stopifnot(
  nrow(summaries) == 4L * 8L,
  all(summaries$data_scenario_id == "main"),
  all(summaries$metric_id == "l10_mean_medi"),
  all(summaries$inference_status == production_label),
  all(summaries$bootstrap_successful_used == 1000L),
  all(summaries$interval_method == "joint_parametric_percentile"),
  all(summaries$status == "PASS"),
  all(is.finite(summaries$estimate)),
  all(is.finite(summaries$conf_low)),
  all(is.finite(summaries$conf_high)),
  all(summaries$conf_low <= summaries$conf_high),
  setequal(
    unique(paste(summaries$run_id, summaries$metric_id, sep = "::")),
    target_key
  )
)

message("Checking production provenance and author approval")
stopifnot(
  nrow(provenance) == 1L,
  provenance$inference_status == production_label,
  provenance$author_approval_token == "accepted_2026-08-12",
  grepl("Explicit author reply", provenance$author_approval, fixed = TRUE),
  provenance$coordinator_authorization_sha256 ==
    "ab0764bb55144d9c69caafc8373010f497561757ad2c576d88e32b450817ed4f",
  provenance$coordinator_gate_sha256 ==
    "30b43ef447a2310edd05b245c0c36d0c6a6966f2394f1a149db13d4afe384445",
  provenance$successful_refits_per_target == 1000L,
  provenance$planned_targets == 4L,
  provenance$completed_targets == 4L,
  provenance$total_used_refits == 4000L,
  provenance$total_failed_refits == sum(audit$failed_refits),
  provenance$total_warning_refits == sum(audit$warning_refits),
  provenance$preproduction_failed_attempts == 1L,
  file.exists(file.path(root, provenance$preproduction_incident_path)),
  artifact_sha256(file.path(root, provenance$preproduction_incident_path)) ==
    provenance$preproduction_incident_sha256,
  provenance$protected_artifact_hashes_unchanged,
  provenance$production_status == "PASS",
  provenance$production_contract_sha256 ==
    unique(audit$production_contract_sha256)
)

message("Checking the frozen non-L10, gap-L10, and METRIC-010 boundary")
protected <- readr::read_csv(
  file.path(
    audit_root,
    "author_gate/H01_METRIC-011_protected_artifact_baseline.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
protected_paths <- file.path(root, protected$path)
stopifnot(
  all(file.exists(protected_paths)),
  identical(
    unname(vapply(protected_paths, artifact_sha256, character(1))),
    unname(protected$sha256)
  )
)

message("Checking the isolated production manifest")
manifest_path <- file.path(
  production_root,
  "H01_METRIC-011_bootstrap_production_manifest.csv"
)
manifest <- readr::read_csv(
  manifest_path,
  show_col_types = FALSE,
  progress = FALSE
)
manifest_paths <- file.path(root, manifest$path)
observed_manifest_sha256 <- unname(vapply(
  manifest_paths,
  artifact_sha256,
  character(1)
))
historical_paths <- c(
  "scripts/hypotheses/H01/h01_contract.R",
  "tests/hypotheses/H01/test_h01_l10_METRIC011_gate.R"
)
historical_rows <- match(historical_paths, manifest$path)
stopifnot(
  nrow(manifest) == length(unique(manifest$path)),
  all(file.exists(manifest_paths)),
  all(manifest$r_version == "4.6.1"),
  all(manifest$inference_status == production_label),
  length(unique(manifest$production_contract_sha256)) == 1L,
  identical(
    unique(manifest$production_contract_sha256),
    unique(audit$production_contract_sha256)
  ),
  !anyNA(historical_rows),
  identical(
    unname(manifest$sha256[historical_rows]),
    c(
      "9151f2ca8ef549d16df1465768ed5b33c0aa33b37dc315a13e06d795ba20de2e",
      "fbbeab68b6680241c33a755f7aeb29e9f5e8b46a660968c642641d189b12d177"
    )
  ),
  identical(
    observed_manifest_sha256[historical_rows],
    c(
      "dfa35f7c8a1ca8a1f2132c6930a8ac219c461ffac769a7423bf85522430da81a",
      "dfff5a87121a6ac812931ebe2e451fa6064ce6479fb295e9a4013d59408709aa"
    )
  ),
  identical(
    observed_manifest_sha256[-historical_rows],
    unname(manifest$sha256[-historical_rows])
  )
)

message("H01 METRIC-011 isolated production verification passed")
