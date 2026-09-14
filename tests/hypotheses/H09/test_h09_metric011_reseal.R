# Verify the bounded H09 provenance-only reseal for METRIC-011. This test
# checks identities and stored values only; it never fits or diagnoses a model.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H09/h09_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H09 METRIC-011 verification requires R 4.6.1", call. = FALSE)
}

expected <- c(
  decision = "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  evidence = "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
  metric_manifest = "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
  site_context_manifest = "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
  base_manifest = "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
  base_bundle = "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916",
  near_context = "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a",
  chest_context = "497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057",
  near_enriched = "b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42",
  chest_enriched = "10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9"
)

identity_paths <- c(
  decision = "audit/decisions/l10_numerical_zero_normalization.md",
  evidence = paste0(
    "audit/reconciliation/l10_METRIC-011/",
    "METRIC-011_evidence_manifest.csv"
  ),
  metric_manifest = "artifacts/12_manifests/metric_artifacts.csv",
  site_context_manifest =
    "artifacts/12_manifests/site_solar_context_artifacts.csv",
  base_manifest = "artifacts/12_manifests/base_model_data_artifacts.csv",
  near_context = paste0(
    "artifacts/06_model_data/base/",
    "metrics_glasses_participant_day_context.rds"
  ),
  chest_context = paste0(
    "artifacts/06_model_data/base/",
    "metrics_chest_participant_day_context.rds"
  )
)
observed <- unname(vapply(
  file.path(root, identity_paths),
  artifact_sha256,
  character(1)
))
stopifnot(identical(observed, unname(expected[names(identity_paths)])))

evidence <- readr::read_csv(
  file.path(root, identity_paths[["evidence"]]),
  show_col_types = FALSE
)
evidence_files <- file.path(root, evidence$path)
stopifnot(
  nrow(evidence) == 7L,
  all(evidence$status == "PASS"),
  all(evidence$r_version == "4.6.1"),
  all(file.exists(evidence_files)),
  all(as.numeric(file.info(evidence_files)$size) == evidence$bytes),
  identical(
    unname(vapply(evidence_files, artifact_sha256, character(1))),
    evidence$sha256
  )
)

contract <- h09_input_contract(root)
contract_expected <- c(
  metric_manifest = expected[["metric_manifest"]],
  base_manifest = expected[["base_manifest"]],
  primary_near_eye_context = expected[["near_context"]],
  primary_chest_context = expected[["chest_context"]],
  primary_near_eye_enriched = expected[["near_enriched"]],
  primary_chest_enriched = expected[["chest_enriched"]]
)
contract_target <- contract |>
  filter(.data$input_role %in% names(contract_expected)) |>
  arrange(match(.data$input_role, names(contract_expected)))
stopifnot(
  identical(contract_target$input_role, names(contract_expected)),
  identical(contract_target$expected_sha256, unname(contract_expected)),
  identical(
    unname(vapply(
      contract_target$absolute_path,
      artifact_sha256,
      character(1)
    )),
    unname(contract_expected)
  )
)

base_manifest <- readr::read_csv(
  file.path(root, identity_paths[["base_manifest"]]),
  show_col_types = FALSE
)
stopifnot(
  identical(unique(base_manifest$input_bundle_sha256), expected[["base_bundle"]]),
  identical(
    unique(base_manifest$site_context_manifest_sha256),
    expected[["site_context_manifest"]]
  )
)

run_text <- paste(
  readLines(
    file.path(root, "scripts/hypotheses/H09/run_h09_stage2.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
stopifnot(str_count(run_text, fixed(expected[["base_bundle"]])) == 2L)

read_h09_csv <- function(...) {
  readr::read_csv(file.path(root, ...), show_col_types = FALSE)
}
input_audit <- read_h09_csv(
  "artifacts/06_model_data/H09/H09_input_audit.csv"
)
base_audit <- read_h09_csv(
  "artifacts/06_model_data/H09/H09_base_bundle_audit.csv"
)
transition <- read_h09_csv(
  "artifacts/06_model_data/H09/H09_METRIC-011_input_transition.csv"
)
frames <- read_h09_csv(
  "artifacts/06_model_data/H09/H09_METRIC-011_l10_frame_identity.csv"
)
excluded <- read_h09_csv(
  "artifacts/06_model_data/H09/H09_METRIC-011_excluded_shared_drift.csv"
)
scientific <- read_h09_csv(
  "artifacts/12_manifests/H09/H09_METRIC-011_scientific_identity.csv"
)
summary <- read_h09_csv(
  "audit/hypotheses/H09/H09_METRIC-011_provenance_reseal.csv"
)

target_audit <- input_audit |>
  filter(.data$input_role %in% names(contract_expected)) |>
  arrange(match(.data$input_role, names(contract_expected)))
stopifnot(
  nrow(target_audit) == 6L,
  all(target_audit$hash_verified),
  all(target_audit$rows_verified),
  identical(target_audit$expected_sha256, unname(contract_expected)),
  identical(target_audit$observed_sha256, unname(contract_expected)),
  isTRUE(base_audit$input_bundle_verified),
  identical(base_audit$expected_input_bundle_sha256, expected[["base_bundle"]]),
  identical(base_audit$observed_input_bundle_sha256, expected[["base_bundle"]]),
  str_detect(base_audit$provenance_qualification, fixed("METRIC-011"))
)

stopifnot(
  nrow(transition) == 6L,
  identical(transition$input_role, names(contract_expected)),
  all(transition$identity_verified),
  all(transition$prior_sha256 != transition$current_sha256),
  nrow(frames) == 12L,
  sum(frames$rows) == 9378L,
  all(frames$row_keys_matched == frames$rows),
  all(frames$l10_hour_exact),
  all(frames$l10_raw_hour_exact),
  all(frames$max_abs_l10_hour_difference == 0),
  all(frames$max_abs_l10_raw_hour_difference == 0),
  nrow(scientific) == 65L,
  all(scientific$identity_verified),
  nrow(excluded) == 3L,
  setequal(
    excluded$input_role,
    c(
      "gap_timing_unaware_metrics",
      "gap_manifest",
      "metric_display_registry"
    )
  ),
  !any(excluded$identity_verified),
  all(str_detect(excluded$action, fixed("not repinned"))),
  nrow(summary) == 11L,
  summary$status[summary$check == "Inferential model fitting"] == "NOT_RUN",
  summary$status[summary$check == "Diagnostics and sensitivities"] == "NOT_RUN",
  summary$observed[summary$check == "H09 result and claim status"] ==
    "scientifically unchanged"
)

scientific_files <- file.path(root, scientific$path)
stopifnot(
  all(file.exists(scientific_files)),
  identical(
    unname(vapply(scientific_files, artifact_sha256, character(1))),
    scientific$sealed_sha256
  ),
  identical(
    as.numeric(file.info(scientific_files)$size),
    as.numeric(scientific$sealed_bytes)
  )
)

manifest_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H09/",
    "H09_METRIC-011_provenance_reseal_manifest.csv"
  )
)
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
manifest_files <- file.path(root, manifest$path)
manifest_sha256 <- artifact_sha256(manifest_path)
stopifnot(
  nrow(manifest) > 20L,
  !anyDuplicated(manifest$path),
  all(manifest$status == "PASS"),
  all(manifest$r_version == "4.6.1"),
  all(file.exists(manifest_files)),
  identical(
    unname(vapply(manifest_files, artifact_sha256, character(1))),
    manifest$sha256
  ),
  identical(
    as.numeric(file.info(manifest_files)$size),
    as.numeric(manifest$bytes)
  ),
  !any(str_detect(manifest$path, "audit/handoffs/H09_")),
  !any(str_detect(
    manifest$path,
    "notebooks/hypotheses/H09.qmd|02_implementation|H09_analysis_preparation"
  ))
)

handoff_text <- vapply(
  file.path(
    root,
    c(
      "audit/handoffs/H09_worker_handoff.md",
      "audit/handoffs/H09_shared_change_request.md"
    )
  ),
  function(path) paste(readLines(path, warn = FALSE), collapse = "\n"),
  character(1)
)
stopifnot(all(str_detect(handoff_text, fixed(manifest_sha256))))

reseal_script <- file.path(
  root,
  "scripts/hypotheses/H09/reseal_h09_metric011.R"
)
script_calls <- unique(all.names(parse(reseal_script), functions = TRUE))
prohibited_calls <- c(
  "gam", "bam", "lmer", "glmer", "glmmTMB", "lme",
  "predict", "simulate", "boot", "emmeans",
  "h09_fit_model", "h09_fit_bundle", "h09_fit_models",
  "h09_model_diagnostics"
)
script_text <- paste(readLines(reseal_script, warn = FALSE), collapse = "\n")
stopifnot(
  !any(prohibited_calls %in% script_calls),
  !str_detect(script_text, fixed("h09_modeling.R"))
)

message(
  "H09 METRIC-011 provenance reseal verified: 12 L10-midpoint frames, ",
  "9,378 rows, 65 unchanged scientific artifacts, and zero model or ",
  "diagnostic reruns"
)
