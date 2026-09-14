#!/usr/bin/env Rscript

# Provenance-only H09 reseal for METRIC-011. This script verifies current
# shared/base identities, proves that current L10 midpoint values reproduce
# every stored primary H09 L10 frame, and updates provenance records only. It
# must not fit, predict, diagnose, simulate, bootstrap, or alter a result.

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(stringr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H09/h09_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    paste0("H09 METRIC-011 resealing requires R 4.6.1; found ", getRversion()),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H09/reseal_h09_metric011.R"

expected_identities <- c(
  decision = "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  evidence_manifest =
    "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
  metric_manifest =
    "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
  site_context_manifest =
    "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
  base_manifest =
    "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
  primary_near_eye_context =
    "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a",
  primary_chest_context =
    "497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057"
)
identity_paths <- c(
  decision = "audit/decisions/l10_numerical_zero_normalization.md",
  evidence_manifest = paste0(
    "audit/reconciliation/l10_METRIC-011/",
    "METRIC-011_evidence_manifest.csv"
  ),
  metric_manifest = "artifacts/12_manifests/metric_artifacts.csv",
  site_context_manifest =
    "artifacts/12_manifests/site_solar_context_artifacts.csv",
  base_manifest = "artifacts/12_manifests/base_model_data_artifacts.csv",
  primary_near_eye_context = paste0(
    "artifacts/06_model_data/base/",
    "metrics_glasses_participant_day_context.rds"
  ),
  primary_chest_context = paste0(
    "artifacts/06_model_data/base/",
    "metrics_chest_participant_day_context.rds"
  )
)
identity_absolute <- file.path(root, identity_paths)
stopifnot(all(file.exists(identity_absolute)))
observed_identities <- unname(vapply(
  identity_absolute,
  artifact_sha256,
  character(1)
))
stopifnot(identical(observed_identities, unname(expected_identities)))

evidence <- readr::read_csv(
  file.path(root, identity_paths[["evidence_manifest"]]),
  show_col_types = FALSE
)
evidence_absolute <- file.path(root, evidence$path)
stopifnot(
  nrow(evidence) == 7L,
  all(evidence$status == "PASS"),
  all(evidence$r_version == "4.6.1"),
  all(file.exists(evidence_absolute)),
  all(as.numeric(file.info(evidence_absolute)$size) == evidence$bytes),
  identical(
    unname(vapply(evidence_absolute, artifact_sha256, character(1))),
    evidence$sha256
  )
)

base_manifest <- readr::read_csv(
  file.path(root, identity_paths[["base_manifest"]]),
  show_col_types = FALSE
)
expected_bundle <-
  "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916"
stopifnot(
  identical(unique(base_manifest$input_bundle_sha256), expected_bundle),
  identical(
    unique(base_manifest$metric_manifest_sha256),
    expected_identities[["metric_manifest"]]
  ),
  identical(
    unique(base_manifest$site_context_manifest_sha256),
    expected_identities[["site_context_manifest"]]
  )
)

target_roles <- c(
  "metric_manifest",
  "base_manifest",
  "primary_near_eye_context",
  "primary_chest_context",
  "primary_near_eye_enriched",
  "primary_chest_enriched"
)
prior_pins <- c(
  metric_manifest =
    "6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8",
  base_manifest =
    "142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4",
  primary_near_eye_context =
    "2326428dde8d0be1eb1b8d7e84ea3d2eac12db5e595d4966955d546fce27d4fc",
  primary_chest_context =
    "f8106f1c5ecaf7488a59f94f11bee472356be6c39d72564b1e6de3b4c3a5d8d3",
  primary_near_eye_enriched =
    "fc80f8a2a94a447c5470db36c1ad1915868463501f04e9db3218f8156efc59d2",
  primary_chest_enriched =
    "ce81c159fe018f35bec9bff44c9cd12f91fd4be1ea2696c56a8e91e628a9e2d3"
)

input_contract <- h09_input_contract(root)
target_contract <- input_contract |>
  filter(.data$input_role %in% target_roles) |>
  arrange(match(.data$input_role, target_roles))
stopifnot(
  identical(target_contract$input_role, target_roles),
  all(file.exists(target_contract$absolute_path))
)
target_observed <- unname(vapply(
  target_contract$absolute_path,
  artifact_sha256,
  character(1)
))
stopifnot(identical(target_observed, target_contract$expected_sha256))

base_rows <- base_manifest |>
  filter(.data$path %in% target_contract$path) |>
  select("path", base_manifest_sha256 = "sha256")
direct_base_targets <- target_contract |>
  filter(str_detect(.data$input_role, "context|enriched")) |>
  left_join(base_rows, by = "path", relationship = "one-to-one")
stopifnot(
  !anyNA(direct_base_targets$base_manifest_sha256),
  identical(
    direct_base_targets$expected_sha256,
    direct_base_targets$base_manifest_sha256
  )
)

input_audit_path <- file.path(
  root,
  "artifacts/06_model_data/H09/H09_input_audit.csv"
)
input_audit <- readr::read_csv(input_audit_path, show_col_types = FALSE)
stopifnot(all(target_roles %in% input_audit$input_role))

input_transition <- target_contract |>
  transmute(
    input_role = .data$input_role,
    path = .data$path,
    prior_sha256 = unname(prior_pins[.data$input_role]),
    current_sha256 = .data$expected_sha256,
    observed_sha256 = target_observed,
    bytes = as.numeric(file.info(.data$absolute_path)$size),
    rows = map_int(
      seq_len(n()),
      function(index) {
        if (is.na(target_contract$expected_rows[index])) return(NA_integer_)
        nrow(readRDS(target_contract$absolute_path[index]))
      }
    ),
    identity_verified = .data$expected_sha256 == target_observed,
    scientific_scope = if_else(
      .data$input_role %in% c("metric_manifest", "base_manifest"),
      "shared provenance identity only",
      "primary/base file identity; H09 fields invariant"
    )
  )
stopifnot(
  all(input_transition$identity_verified),
  all(input_transition$prior_sha256 != input_transition$current_sha256)
)

# Do not absorb concurrent shared changes that are outside METRIC-011. The
# three mismatches below pre-date or are independent of this decision. They
# are recorded explicitly so that the bounded reseal cannot silently broaden
# into a new gap-sensitivity or display-registry approval.
expected_excluded_observed <- c(
  gap_timing_unaware_metrics =
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
  gap_manifest =
    "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
  metric_display_registry =
    "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0"
)
non_target_contract <- input_contract |>
  filter(!.data$input_role %in% target_roles)
non_target_observed <- unname(vapply(
  non_target_contract$absolute_path,
  artifact_sha256,
  character(1)
))
excluded_shared_drift <- non_target_contract |>
  transmute(
    input_role = .data$input_role,
    path = .data$path,
    contract_sha256 = .data$expected_sha256,
    observed_sha256 = non_target_observed,
    bytes = as.numeric(file.info(.data$absolute_path)$size),
    identity_verified = .data$expected_sha256 == non_target_observed
  ) |>
  filter(!.data$identity_verified) |>
  mutate(
    metric011_scope = case_when(
      .data$input_role %in% c(
        "gap_timing_unaware_metrics",
        "gap_manifest"
      ) ~ paste(
        "The controlling METRIC-011 transition records the shared gap",
        "manifest as unchanged; this older H09 pin drift is not repinned here."
      ),
      TRUE ~ paste(
        "The shared metric-display registry is outside the METRIC-011",
        "scientific and provenance transition."
      )
    ),
    action = "not repinned in the bounded METRIC-011 reseal"
  )
stopifnot(
  nrow(excluded_shared_drift) == length(expected_excluded_observed),
  setequal(
    excluded_shared_drift$input_role,
    names(expected_excluded_observed)
  ),
  identical(
    excluded_shared_drift |>
      arrange(match(.data$input_role, names(expected_excluded_observed))) |>
      pull("observed_sha256"),
    unname(expected_excluded_observed)
  )
)

for (role in target_roles) {
  audit_index <- which(input_audit$input_role == role)
  contract_index <- which(target_contract$input_role == role)
  stopifnot(length(audit_index) == 1L, length(contract_index) == 1L)
  input_audit$use[audit_index] <- target_contract$use[contract_index]
  input_audit$expected_sha256[audit_index] <-
    target_contract$expected_sha256[contract_index]
  input_audit$observed_sha256[audit_index] <-
    target_observed[contract_index]
  input_audit$hash_verified[audit_index] <- TRUE
  input_audit$bytes[audit_index] <- as.numeric(file.info(
    target_contract$absolute_path[contract_index]
  )$size)
  if (!is.na(target_contract$expected_rows[contract_index])) {
    input_audit$expected_rows[audit_index] <-
      target_contract$expected_rows[contract_index]
    input_audit$observed_rows[audit_index] <-
      input_transition$rows[input_transition$input_role == role]
    input_audit$rows_verified[audit_index] <-
      input_audit$expected_rows[audit_index] ==
      input_audit$observed_rows[audit_index]
  }
}
stopifnot(all(input_audit$hash_verified[input_audit$input_role %in% target_roles]))

base_audit_path <- file.path(
  root,
  "artifacts/06_model_data/H09/H09_base_bundle_audit.csv"
)
base_audit <- readr::read_csv(base_audit_path, show_col_types = FALSE)
stopifnot(nrow(base_audit) == 1L)
base_audit$expected_input_bundle_sha256 <- expected_bundle
base_audit$observed_input_bundle_sha256 <- expected_bundle
base_audit$input_bundle_verified <- TRUE
metric011_qualification <- paste(
  "METRIC-011 changes only L10 mean numerical zeros; H09 uses L10 midpoint",
  "and is scientifically unchanged."
)
if (!str_detect(base_audit$provenance_qualification, fixed("METRIC-011"))) {
  base_audit$provenance_qualification <- paste(
    base_audit$provenance_qualification,
    metric011_qualification
  )
}

changes <- readr::read_csv(
  file.path(
    root,
    "audit/reconciliation/l10_METRIC-011/primary_scientific_cell_changes.csv"
  ),
  show_col_types = FALSE
)
stopifnot(
  nrow(changes) == 8L,
  all(changes$metric == "l10_mean_medi"),
  all(changes$new_value_lx == 0),
  sum(changes$position == "glasses") == 3L,
  sum(changes$position == "chest") == 5L
)

metric_registry <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H09/H09_metric_registry.csv"),
  show_col_types = FALSE
)
l10_contract <- metric_registry |>
  filter(.data$metric_id == "l10_midpoint")
stopifnot(
  nrow(l10_contract) == 1L,
  identical(l10_contract$source_column, "l10_hour"),
  !any(str_detect(metric_registry$source_column, "l10_mean")),
  !any(str_detect(metric_registry$metric_id, "l10_mean"))
)

read_current_l10 <- function(path, placement) {
  readRDS(path) |>
    transmute(
      placement = placement,
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      current_l10_raw_hour =
        as.numeric(.data$l10_midpoint_clock_minute) / 60,
      current_l10_hour = if_else(
        .data$current_l10_raw_hour > 16,
        .data$current_l10_raw_hour - 24,
        .data$current_l10_raw_hour
      )
    )
}
current_l10 <- bind_rows(
  read_current_l10(
    target_contract$absolute_path[
      target_contract$input_role == "primary_near_eye_enriched"
    ],
    "glasses"
  ),
  read_current_l10(
    target_contract$absolute_path[
      target_contract$input_role == "primary_chest_enriched"
    ],
    "chest"
  )
)
stopifnot(!anyDuplicated(current_l10[c("placement", "site", "Id", "local_date")]))

model_frames <- readRDS(file.path(
  root,
  "artifacts/06_model_data/H09/H09_model_frames.rds"
))
is_primary_l10 <- vapply(
  model_frames,
  function(frame) {
    nrow(frame) > 0L &&
      all(frame$data_scenario_id == "primary") &&
      all(frame$metric_id == "l10_midpoint")
  },
  logical(1)
)
primary_l10_frames <- model_frames[is_primary_l10]
stopifnot(length(primary_l10_frames) > 0L)

l10_frame_checks <- imap_dfr(primary_l10_frames, function(frame, frame_id) {
  checked <- frame |>
    transmute(
      placement = as.character(.data$placement),
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      stored_l10_hour = as.numeric(.data$timing_hour),
      stored_l10_raw_hour = as.numeric(.data$l10_raw_hour)
    ) |>
    left_join(
      current_l10,
      by = c("placement", "site", "Id", "local_date"),
      relationship = "many-to-one"
    )
  stopifnot(
    !anyNA(checked$current_l10_hour),
    !anyNA(checked$current_l10_raw_hour)
  )
  tibble(
    frame_id = frame_id,
    rows = nrow(checked),
    row_keys_matched = nrow(checked),
    l10_hour_exact = identical(
      checked$stored_l10_hour,
      checked$current_l10_hour
    ),
    l10_raw_hour_exact = identical(
      checked$stored_l10_raw_hour,
      checked$current_l10_raw_hour
    ),
    max_abs_l10_hour_difference = max(
      abs(checked$stored_l10_hour - checked$current_l10_hour)
    ),
    max_abs_l10_raw_hour_difference = max(
      abs(checked$stored_l10_raw_hour - checked$current_l10_raw_hour)
    )
  )
})
stopifnot(
  all(l10_frame_checks$l10_hour_exact),
  all(l10_frame_checks$l10_raw_hour_exact),
  all(l10_frame_checks$max_abs_l10_hour_difference == 0),
  all(l10_frame_checks$max_abs_l10_raw_hour_difference == 0)
)

reader_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"),
  show_col_types = FALSE
)
scientific_prefixes <- paste0(
  "^artifacts/(06_model_data|07_models|08_diagnostics|09_tables|",
  "10_figures|11_source_data)/H09/"
)
provenance_only_files <- c(
  "artifacts/06_model_data/H09/H09_input_audit.csv",
  "artifacts/06_model_data/H09/H09_base_bundle_audit.csv"
)
scientific_identity <- reader_manifest |>
  filter(
    str_detect(.data$path, scientific_prefixes),
    !.data$path %in% provenance_only_files
  ) |>
  transmute(
    path = .data$path,
    sealed_sha256 = .data$sha256,
    sealed_bytes = .data$bytes,
    current_sha256 = vapply(
      file.path(root, .data$path),
      artifact_sha256,
      character(1)
    ),
    current_bytes = as.numeric(file.info(file.path(root, .data$path))$size),
    identity_verified =
      .data$sealed_sha256 == .data$current_sha256 &
      .data$sealed_bytes == .data$current_bytes,
    metric011_action = "none; scientific artifact retained byte-identically"
  )
stopifnot(nrow(scientific_identity) > 50L, all(scientific_identity$identity_verified))

summary <- tibble::tribble(
  ~check, ~status, ~observed, ~expected, ~detail,
  "Controlling decision identity", "PASS", observed_identities[[1L]], expected_identities[["decision"]], "METRIC-011 approved and implemented.",
  "Evidence manifest identity", "PASS", observed_identities[[2L]], expected_identities[["evidence_manifest"]], "All seven evidence members independently match their sealed hashes and byte counts.",
  "Current shared/base pins", "PASS", paste0(length(expected_identities) + 3L, " identities"), "10 identities", "Decision, evidence, metric, site/context, base, bundle, two context RDS, and two enriched RDS identities verified.",
  "Primary scientific cell changes", "PASS", paste0(nrow(changes), " L10 mean cells: 3 near-eye, 5 chest"), "8 L10 mean cells only", "Every changed value is outside the H09 metric registry.",
  "H09 registered L10 estimand", "PASS", paste(l10_contract$metric_id, l10_contract$source_column, sep = " / "), "l10_midpoint / l10_hour", "H09 uses midpoint timing and contains no L10 mean response.",
  "Stored primary L10 frames", "PASS", paste0(nrow(l10_frame_checks), " frames; ", sum(l10_frame_checks$rows), " stored rows; maximum difference 0 h"), "Exact current midpoint and row-key matches", "Both MCTQ and MEQ, all-available, paired-common, and gap-common primary frames are unchanged.",
  "Stored scientific artifact identities", "PASS", paste0(sum(scientific_identity$identity_verified), " / ", nrow(scientific_identity)), "All identities match", "Model frames, model objects, results, diagnostics, sensitivities, figures, and source data remain byte-identical.",
  "Unrelated shared drift excluded", "PASS", paste(excluded_shared_drift$input_role, collapse = "; "), "3 non-METRIC-011 roles not repinned", "The gap preparation manifest did not change under METRIC-011; older gap and current display-registry drift remain outside this bounded reseal.",
  "Inferential model fitting", "NOT_RUN", "0 fits", "0 fits", "Provenance-only reseal; existing 540 model objects retained.",
  "Diagnostics and sensitivities", "NOT_RUN", "0 reruns", "0 reruns", "Existing diagnostic and sensitivity artifacts retained.",
  "H09 result and claim status", "PASS", "scientifically unchanged", "scientifically unchanged", "METRIC-011 is an upstream numerical-zero normalization outside H09's scientific estimand."
)

transition_path <- file.path(
  root,
  "artifacts/06_model_data/H09/H09_METRIC-011_input_transition.csv"
)
frame_check_path <- file.path(
  root,
  "artifacts/06_model_data/H09/H09_METRIC-011_l10_frame_identity.csv"
)
scientific_identity_path <- file.path(
  root,
  "artifacts/12_manifests/H09/H09_METRIC-011_scientific_identity.csv"
)
excluded_drift_path <- file.path(
  root,
  "artifacts/06_model_data/H09/H09_METRIC-011_excluded_shared_drift.csv"
)
summary_path <- file.path(
  root,
  "audit/hypotheses/H09/H09_METRIC-011_provenance_reseal.csv"
)
provenance_note_path <- file.path(
  root,
  "audit/hypotheses/H09/H09_METRIC-011_provenance_reseal.md"
)
reseal_manifest_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H09/",
    "H09_METRIC-011_provenance_reseal_manifest.csv"
  )
)

invisible(write_csv_artifact(input_audit, input_audit_path, producer))
invisible(write_csv_artifact(base_audit, base_audit_path, producer))
invisible(write_csv_artifact(input_transition, transition_path, producer))
invisible(write_csv_artifact(l10_frame_checks, frame_check_path, producer))
invisible(write_csv_artifact(
  scientific_identity,
  scientific_identity_path,
  producer
))
invisible(write_csv_artifact(
  excluded_shared_drift,
  excluded_drift_path,
  producer
))
invisible(write_csv_artifact(summary, summary_path, producer))

# Seal only the evidence and provenance records touched by this follow-up.
# Existing Stage 2, Stage 3, and preparation manifests remain historical
# scientific/reporting seals and are not rebuilt against concurrent shared
# work. The handoff cites this overlay manifest and is intentionally excluded
# to avoid a checksum cycle.
reseal_support <- file.path(
  root,
  c(
    "scripts/hypotheses/H09/h09_contract.R",
    "scripts/hypotheses/H09/run_h09_stage2.R",
    "scripts/hypotheses/H09/reseal_h09_metric011.R",
    "tests/hypotheses/H09/test_h09_metric011_reseal.R",
    "audit/hypotheses/H09/H09_METRIC-011_provenance_reseal.md",
    "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
  )
)
reseal_files <- unique(c(
  identity_absolute,
  evidence_absolute,
  target_contract$absolute_path,
  reseal_support,
  input_audit_path,
  base_audit_path,
  transition_path,
  frame_check_path,
  scientific_identity_path,
  excluded_drift_path,
  summary_path
))
stopifnot(
  file.exists(provenance_note_path),
  all(file.exists(reseal_files)),
  !any(dir.exists(reseal_files))
)
reseal_files <- sort(unique(normalizePath(
  reseal_files,
  winslash = "/",
  mustWork = TRUE
)))
reseal_relative <- substring(reseal_files, nchar(root) + 2L)
scientific_identity_relative <- substring(
  scientific_identity_path,
  nchar(root) + 2L
)
reseal_manifest <- tibble(
  path = reseal_relative,
  role = case_when(
    reseal_relative == identity_paths[["decision"]] ~
      "controlling_decision",
    reseal_relative == identity_paths[["evidence_manifest"]] ~
      "evidence_manifest",
    str_starts(
      reseal_relative,
      "audit/reconciliation/l10_METRIC-011/"
    ) ~ "evidence_member",
    reseal_relative %in% target_contract$path ~
      "repinned_shared_or_base_input",
    reseal_relative == identity_paths[["site_context_manifest"]] ~
      "verified_base_dependency",
    reseal_relative ==
      "artifacts/12_manifests/H09/H09_stage3_artifacts.csv" ~
      "prior_scientific_seal",
    reseal_relative == scientific_identity_relative ~
      "unchanged_scientific_identity_proof",
    str_starts(reseal_relative, "scripts/hypotheses/H09/") ~
      "H09_provenance_code",
    str_starts(reseal_relative, "tests/hypotheses/H09/") ~
      "H09_provenance_test",
    str_starts(reseal_relative, "audit/hypotheses/H09/") ~
      "H09_provenance_record",
    TRUE ~ "H09_repinned_provenance_artifact"
  ),
  sha256 = unname(vapply(reseal_files, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(reseal_files)$size),
  producer = producer,
  r_version = as.character(getRversion()),
  status = "PASS"
) |>
  arrange(.data$role, .data$path)
stopifnot(
  !anyDuplicated(reseal_manifest$path),
  all(nchar(reseal_manifest$sha256) == 64L),
  !any(str_detect(reseal_manifest$path, "audit/handoffs/H09_")),
  !reseal_manifest_path %in% file.path(root, reseal_manifest$path)
)
invisible(write_csv_artifact(
  reseal_manifest,
  reseal_manifest_path,
  producer
))

message(
  "H09 METRIC-011 provenance reseal complete: ",
  nrow(l10_frame_checks),
  " primary L10 frames and ",
  nrow(scientific_identity),
  " scientific artifacts retained exactly; no model or diagnostic rerun"
)
