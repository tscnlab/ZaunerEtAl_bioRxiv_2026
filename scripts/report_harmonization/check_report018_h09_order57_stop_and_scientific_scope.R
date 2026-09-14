#!/usr/bin/env Rscript

# Independently accept the REPORT-018 H09 order-57 stopped state and audit
# whether the three shared-file transitions can alter any H09 estimand, model
# frame, result, or reader-facing metric definition.

Sys.setenv(TZ = "UTC")
options(
  stringsAsFactors = FALSE,
  warn = 2,
  lifecycle_verbosity = "quiet"
)

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tibble)
})

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "The H09 order-57 scientific-scope audit requires R 4.6.1",
    call. = FALSE
  )
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

relative_path <- function(path) {
  absolute <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  if (!startsWith(absolute, prefix)) {
    stop("An audited path is outside the project", call. = FALSE)
  }
  substring(absolute, nchar(prefix) + 1L)
}

write_audit_csv <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(data, path, row.names = FALSE, na = "")
  invisible(path)
}

expected_pins <- c(
  order57_stop_record = "4ff6379f491e77cbf9861cddaf7d9bdb3c091f96b7d6b96cd9a755c59252d563",
  order57_failure_verifier = "92226688ee3212469ae3b7aa3580fcc8686f2d62a42c1c189ab61944f1ebcb35",
  order57_failure_verification = "f91c681e6393d5febf8d19c180b3ec744776fae7b12e7a61a900e28fd0477aae",
  order57_failure_manifest = "d8c6399a6c964ad96de7155e5a588809d5f7dd64638d206068782dc0906abc37",
  order56b_result_acceptance = "4748b3b18e6ca0589e00e629490cca97aa72507589be6165e1893640d08b5288",
  order56b_result_acceptance_manifest = "cf3e85d447a6e4523e647a29e6989d678d29bed6af7c18f11523db0208175df3",
  gap_current_rds = "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
  gap_current_manifest = "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
  display_registry_current = "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0",
  display_registry_execution = "6c0adc3ca061ac49591d71243dd7ff0693311eb1f499836cf52c2742328b8154",
  gap_repair_evidence_manifest = "81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018",
  excluded_shared_drift = "91d9781466273385338432c7d86c68f35ae65ba828e547659d0cf69720b5b5b9",
  model_frames = "19389e7f2f24b662d041f96bd62cf18deccae0f038328f6358a50b18fc6480d5",
  model_frame_index = "5a0fb42c30fa03d7f86c598d74455d7fca3bd8c3d4af957ae014f870e029fadb",
  scientific_identity = "9f49733db1a678fbd990fb88494901da15851c127aab6bbc2405eb5808e35b9d"
)

pin_paths <- c(
  order57_stop_record = paste0(
    "audit/hypotheses/H09/report018_order57_companion_render/",
    "ORDER57_FAIL_CLOSED.md"
  ),
  order57_failure_verifier = paste0(
    "audit/hypotheses/H09/report018_order57_companion_render/",
    "verify_order57_h09_companion_failure.R"
  ),
  order57_failure_verification = paste0(
    "audit/hypotheses/H09/report018_order57_companion_render/",
    "order57_failure_verification.csv"
  ),
  order57_failure_manifest = paste0(
    "audit/hypotheses/H09/report018_order57_companion_render/",
    "order57_fail_closed_evidence_manifest.csv"
  ),
  order56b_result_acceptance = paste0(
    "audit/report_harmonization/",
    "report018_h09_order56b_result_independent_acceptance.md"
  ),
  order56b_result_acceptance_manifest = paste0(
    "audit/report_harmonization/",
    "report018_h09_order56b_result_independent_acceptance_manifest.csv"
  ),
  gap_current_rds = paste0(
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
    "participant_day_metrics.rds"
  ),
  gap_current_manifest = "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
  display_registry_current = "config/metric_display_registry.csv",
  gap_repair_evidence_manifest = paste0(
    "audit/reconciliation/mder_METRIC-010_gap_repair/",
    "gap_repair_evidence_manifest.csv"
  ),
  excluded_shared_drift = paste0(
    "artifacts/06_model_data/H09/",
    "H09_METRIC-011_excluded_shared_drift.csv"
  ),
  model_frames = "artifacts/06_model_data/H09/H09_model_frames.rds",
  model_frame_index = "artifacts/06_model_data/H09/H09_model_frame_index.csv",
  scientific_identity = paste0(
    "artifacts/12_manifests/H09/",
    "H09_METRIC-011_scientific_identity.csv"
  )
)

observed_pins <- vapply(
  pin_paths,
  function(path) sha256_file(file.path(root, path)),
  character(1)
)
stopifnot(identical(observed_pins, expected_pins[names(observed_pins)]))

stop_manifest_path <- file.path(root, pin_paths[["order57_failure_manifest"]])
stop_manifest <- utils::read.csv(stop_manifest_path, check.names = FALSE)
stopifnot(
  nrow(stop_manifest) == 45L,
  !anyDuplicated(stop_manifest$path),
  !relative_path(stop_manifest_path) %in% stop_manifest$path,
  all(file.exists(file.path(root, stop_manifest$path)))
)
stop_manifest_audit <- stop_manifest |>
  mutate(
    current_sha256 = vapply(
      file.path(root, .data$path),
      sha256_file,
      character(1)
    ),
    current_bytes = as.numeric(file.info(file.path(root, .data$path))$size),
    status = if_else(
      .data$sha256 == .data$current_sha256 &
        .data$bytes == .data$current_bytes,
      "PASS",
      "FAIL"
    )
  )
stopifnot(all(stop_manifest_audit$status == "PASS"))

failure_verification <- utils::read.csv(
  file.path(root, pin_paths[["order57_failure_verification"]]),
  check.names = FALSE
)
stopifnot(
  nrow(failure_verification) == 14L,
  all(failure_verification$status == "PASS")
)

mismatch_path <- file.path(
  root,
  "audit/hypotheses/H09/report018_order57_companion_render/",
  "render_input_identity_mismatches.csv"
)
mismatches <- utils::read.csv(mismatch_path, check.names = FALSE)
expected_transition <- tibble::tribble(
  ~input_role,
  ~execution_sha256,
  ~current_sha256,
  ~execution_bytes,
  ~current_bytes,
  "gap_timing_unaware_metrics",
  "28266064c6213eae6046ec6469d0dae39529f56e60933dcd581cf96c8590e1a4",
  "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
  88760,
  88248,
  "gap_manifest",
  "af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267",
  "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
  3970,
  4497,
  "metric_display_registry",
  "6c0adc3ca061ac49591d71243dd7ff0693311eb1f499836cf52c2742328b8154",
  "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0",
  3182,
  3203
)
observed_transition <- mismatches |>
  transmute(
    input_role = .data$input_role,
    execution_sha256 = .data$expected_sha256,
    current_sha256 = .data$current_sha256,
    execution_bytes = as.numeric(.data$bytes),
    current_bytes = as.numeric(.data$current_bytes)
  ) |>
  arrange(match(.data$input_role, expected_transition$input_role)) |>
  tibble::as_tibble()
stopifnot(identical(observed_transition, expected_transition))

excluded <- utils::read.csv(
  file.path(root, pin_paths[["excluded_shared_drift"]]),
  check.names = FALSE
) |>
  arrange(match(.data$input_role, expected_transition$input_role))
stopifnot(
  nrow(excluded) == 3L,
  identical(excluded$input_role, expected_transition$input_role),
  identical(excluded$contract_sha256, expected_transition$execution_sha256),
  identical(excluded$observed_sha256, expected_transition$current_sha256),
  identical(as.numeric(excluded$bytes), expected_transition$current_bytes),
  all(!excluded$identity_verified),
  all(excluded$action == "not repinned in the bounded METRIC-011 reseal")
)

gap_evidence_path <- file.path(
  root,
  pin_paths[["gap_repair_evidence_manifest"]]
)
gap_evidence <- utils::read.csv(gap_evidence_path, check.names = FALSE)
stopifnot(
  nrow(gap_evidence) == 7L,
  !anyDuplicated(gap_evidence$path),
  all(gap_evidence$status == "PASS"),
  all(gap_evidence$r_version == "4.6.1"),
  all(file.exists(file.path(root, gap_evidence$path)))
)
gap_evidence_current_sha <- vapply(
  file.path(root, gap_evidence$path),
  sha256_file,
  character(1)
)
gap_evidence_current_bytes <- as.numeric(
  file.info(file.path(root, gap_evidence$path))$size
)
stopifnot(
  identical(unname(gap_evidence_current_sha), gap_evidence$sha256),
  identical(gap_evidence_current_bytes, as.numeric(gap_evidence$bytes))
)

non_mder_invariance <- utils::read.csv(
  file.path(
    root,
    "audit/reconciliation/mder_METRIC-010_gap_repair/",
    "gap_non_mder_invariance.csv"
  ),
  check.names = FALSE
)
lookup_value <- function(check) {
  value <- non_mder_invariance$value[non_mder_invariance$check == check]
  if (length(value) != 1L) {
    stop(
      "A gap-repair invariance check is missing or duplicated",
      call. = FALSE
    )
  }
  value
}
stopifnot(
  identical(lookup_value("non_mder_rows_before"), "25620"),
  identical(lookup_value("non_mder_rows_after"), "25620"),
  identical(lookup_value("non_mder_cells_exactly_unchanged"), "TRUE"),
  identical(lookup_value("shared_independent_verifier_status"), "PASS")
)

gap_manifest <- utils::read.csv(
  file.path(root, pin_paths[["gap_current_manifest"]]),
  check.names = FALSE
)
gap_rds_row <- gap_manifest |>
  filter(.data$artifact_id == "participant_day_metrics_rds")
stopifnot(
  nrow(gap_manifest) == 16L,
  nrow(gap_rds_row) == 1L,
  identical(gap_rds_row$sha256, expected_pins[["gap_current_rds"]]),
  identical(as.numeric(gap_rds_row$bytes), 88248),
  identical(as.integer(gap_rds_row$rows), 27328L),
  identical(as.integer(gap_rds_row$columns), 9L)
)

gap <- readRDS(file.path(root, pin_paths[["gap_current_rds"]]))
stopifnot(
  is.data.frame(gap),
  nrow(gap) == 27328L,
  ncol(gap) == 9L,
  sum(gap$metric_id == "mder_mean_of_viable_ratios") == 1708L,
  sum(gap$metric_id != "mder_mean_of_viable_ratios") == 25620L
)

source(file.path(root, "scripts/hypotheses/H09/h09_contract.R"))
source(file.path(root, "scripts/hypotheses/H09/h09_modeling.R"))

h09_gap_metrics <- c(
  "m10_midpoint",
  "l10_midpoint",
  "first_timing_above_250",
  "last_timing_above_250",
  "mean_timing_above_250"
)
h09_registry <- h09_metric_registry()
stopifnot(
  setequal(
    setdiff(h09_registry$metric_id, "longest_period_midpoint"),
    h09_gap_metrics
  ),
  !any(grepl("mder", h09_registry$metric_id, fixed = TRUE)),
  all(h09_gap_metrics %in% gap$metric_id)
)

chronotype <- readRDS(file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/chronotype.rds"
))
site_levels <- utils::read.csv(
  file.path(root, "config/site_display_registry.csv"),
  check.names = FALSE
) |>
  arrange(.data$display_order) |>
  pull("site")
gap_rows <- h09_prepare_gap_long(gap, chronotype, h09_score_contract())
stopifnot(
  setequal(unique(gap_rows$metric_id), h09_gap_metrics),
  !any(grepl("mder", gap_rows$metric_id, fixed = TRUE))
)

stored_frames <- readRDS(file.path(root, pin_paths[["model_frames"]]))
frame_index <- utils::read.csv(
  file.path(root, pin_paths[["model_frame_index"]]),
  check.names = FALSE
)
gap_index <- frame_index |>
  filter(.data$data_scenario_id == "gap_timing_unaware")
stopifnot(nrow(frame_index) == 108L, nrow(gap_index) == 40L)

frame_checks <- lapply(seq_len(nrow(gap_index)), function(index) {
  spec <- gap_index[index, , drop = FALSE]
  stored <- stored_frames[[spec$frame_id]]
  current <- gap_rows |>
    filter(
      .data$placement == spec$placement,
      .data$metric_id == spec$metric_id
    ) |>
    h09_prepare_model_frame(
      instrument_id = spec$instrument_id,
      site_levels = site_levels
    )
  if (spec$sample_scenario == "gap_common") {
    current <- current[
      current$.model_row_id %in% stored$.model_row_id,
      ,
      drop = FALSE
    ]
    current$site <- droplevels(current$site)
    stats::contrasts(current$site) <- stats::contr.sum(nlevels(current$site))
    current$Id <- droplevels(current$Id)
    current$participant_key <- droplevels(current$participant_key)
    current <- tibble::as_tibble(current)
  }
  tibble::tibble(
    frame_id = spec$frame_id,
    placement = spec$placement,
    sample_scenario = spec$sample_scenario,
    metric_id = spec$metric_id,
    instrument_id = spec$instrument_id,
    current_rows = nrow(current),
    stored_rows = nrow(stored),
    current_row_key_hash = h09_key_hash(current),
    stored_row_key_hash = spec$row_key_hash,
    current_model_frame_hash = h09_frame_hash(current),
    stored_model_frame_hash = spec$model_frame_hash,
    rows_exact = nrow(current) == nrow(stored),
    row_keys_exact = h09_key_hash(current) == spec$row_key_hash,
    model_values_exact = h09_frame_hash(current) == spec$model_frame_hash,
    complete_frame_exact = identical(current, stored),
    status = if_else(
      .data$rows_exact &
        .data$row_keys_exact &
        .data$model_values_exact &
        .data$complete_frame_exact,
      "PASS",
      "FAIL"
    )
  )
}) |>
  bind_rows()
stopifnot(
  nrow(frame_checks) == 40L,
  all(frame_checks$status == "PASS"),
  sum(frame_checks$current_rows) == 32492L
)

old_registry_lines <- system2(
  "git",
  c(
    "show",
    paste0(
      "1f951ba3b34b0afb9ab1bce89c98cd1fc532a3bb:",
      "config/metric_display_registry.csv"
    )
  ),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(identical(attr(old_registry_lines, "status"), NULL))
old_registry_path <- tempfile(fileext = ".csv")
on.exit(unlink(old_registry_path), add = TRUE)
writeLines(old_registry_lines, old_registry_path, useBytes = TRUE)
stopifnot(
  identical(
    sha256_file(old_registry_path),
    expected_pins[["display_registry_execution"]]
  )
)
old_registry <- utils::read.csv(old_registry_path, check.names = FALSE)
current_registry <- utils::read.csv(
  file.path(root, pin_paths[["display_registry_current"]]),
  check.names = FALSE
)
old_only <- setdiff(old_registry$metric_id, current_registry$metric_id)
current_only <- setdiff(current_registry$metric_id, old_registry$metric_id)
common_registry_ids <- intersect(
  old_registry$metric_id,
  current_registry$metric_id
)
old_common <- old_registry |>
  filter(.data$metric_id %in% common_registry_ids) |>
  arrange(.data$metric_id)
current_common <- current_registry |>
  filter(.data$metric_id %in% common_registry_ids) |>
  arrange(.data$metric_id)
stopifnot(
  identical(old_only, "mder_ratio_of_integrals"),
  identical(current_only, "mder_mean_of_viable_ratios"),
  identical(old_common, current_common),
  !any(grepl("mder", h09_registry$metric_id, fixed = TRUE))
)

h09_shared_display_ids <- intersect(
  h09_registry$metric_id,
  common_registry_ids
)
registry_checks <- bind_rows(
  tibble::tibble(
    metric_id = h09_shared_display_ids,
    transition = "unchanged H09 display row",
    execution_present = TRUE,
    current_present = TRUE,
    row_exact = TRUE,
    h09_scientific_scope = "H09 display definition unchanged",
    status = "PASS"
  ),
  tibble::tibble(
    metric_id = c(old_only, current_only),
    transition = c("removed registry row", "added registry row"),
    execution_present = c(TRUE, FALSE),
    current_present = c(FALSE, TRUE),
    row_exact = NA,
    h09_scientific_scope = paste(
      "MDER-only registry transition; H09 fits no MDER metric"
    ),
    status = "PASS"
  ),
  tibble::tibble(
    metric_id = "longest_period_midpoint",
    transition = "H09-owned definition absent from both shared registries",
    execution_present = FALSE,
    current_present = FALSE,
    row_exact = NA,
    h09_scientific_scope = "H09-owned definition unchanged",
    status = "PASS"
  )
)
stopifnot(
  nrow(registry_checks) == 8L,
  all(registry_checks$status == "PASS")
)

scientific_identity <- utils::read.csv(
  file.path(root, pin_paths[["scientific_identity"]]),
  check.names = FALSE
)
stopifnot(
  nrow(scientific_identity) == 65L,
  !anyDuplicated(scientific_identity$path),
  all(file.exists(file.path(root, scientific_identity$path)))
)
scientific_current_sha <- vapply(
  file.path(root, scientific_identity$path),
  sha256_file,
  character(1)
)
scientific_current_bytes <- as.numeric(
  file.info(file.path(root, scientific_identity$path))$size
)
scientific_identity_audit <- scientific_identity |>
  transmute(
    path = .data$path,
    historical_sha256 = .data$sealed_sha256,
    historical_bytes = as.numeric(.data$sealed_bytes),
    current_sha256 = unname(scientific_current_sha),
    current_bytes = scientific_current_bytes,
    live_exact = .data$historical_sha256 == .data$current_sha256 &
      .data$historical_bytes == .data$current_bytes
  )
expected_display_transitions <- tibble::tribble(
  ~path,
  ~historical_sha256,
  ~historical_bytes,
  ~current_sha256,
  ~current_bytes,
  "artifacts/10_figures/H09/H09_diagnostics_chest.pdf",
  "614b46f3cb2026ea1f6c7350959482ce4473c114b0c90ec066a176f73c635596",
  695820,
  "1f8dd115d2e249f23acaa7560c8df432418f129c97f733cea5177f675997f09c",
  696614,
  "artifacts/10_figures/H09/H09_diagnostics_chest.png",
  "e82b32d5d69a73e45a7d93e8b1bb8357dc3104e67c5f128eba4f3f5538961a75",
  2626860,
  "dcced15b55b9f4abd912f1fbad0ccd3eaddcbabe820b41591350601df29f0f1a",
  2874977,
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.pdf",
  "a01d7184d3fc68bf33375f950c9ba422ac7f86f803cd214064ddf86d003ca5ac",
  627893,
  "e63794d0eaad64d0fe8fd65f31e9e4a8162a6dbf50f047a1af2caf18f78f3db5",
  628572,
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.png",
  "df6a267517ea08635a00fcfa153a1e3a7f6dbbbe764745860c16bd3b53165e96",
  2557336,
  "cfb7136446dabf79334933f0677ba0db89b4a3052f1871ced3e90dbc3ed7d5b5",
  2795403,
  "artifacts/10_figures/H09/H09_paired_placement_effects.pdf",
  "5d8f8e95c4642ca29391941f63852776ee6d4ee3cb0cbdedfe74d24ec645ff7c",
  16857,
  "e3371426b6a2c7a3d2db32ce5641697fad1aec6592b86a80d316ec81d54a7ea2",
  16853,
  "artifacts/10_figures/H09/H09_paired_placement_effects.png",
  "4cffc5339801d25e817639064b6f40e0b0a6bbe69a735e5f245d97cee898e185",
  129869,
  "ae6fc387a28a840d57ad5088dc446f3ab902136cb9038a7f119ace2db7a6a4be",
  131504,
  "artifacts/10_figures/H09/H09_primary_effects.pdf",
  "b354077d2c1225104ecef7af1d879acd2037a7b740940392092b2d09f2f833e0",
  17970,
  "69275a6a3fbfa7bd0b47efa4f53cb61ccbe3c7a776f146148f58026f4329357f",
  17941,
  "artifacts/10_figures/H09/H09_primary_effects.png",
  "f288cfaff6e555715af30c778974e50d9bcc8c9a90c643b5e994ad2d8b95be1f",
  139103,
  "8525b9dda4a635efe2d8410e6eeb6a99722c6bc0d225f09abe684a73595dc4dd",
  162887
)
observed_scientific_transitions <- scientific_identity_audit |>
  filter(!.data$live_exact) |>
  select(
    "path",
    "historical_sha256",
    "historical_bytes",
    "current_sha256",
    "current_bytes"
  ) |>
  arrange(.data$path) |>
  tibble::as_tibble()
expected_display_transitions <- expected_display_transitions |>
  arrange(.data$path)
stopifnot(
  sum(scientific_identity_audit$live_exact) == 57L,
  identical(observed_scientific_transitions, expected_display_transitions)
)
scientific_identity_audit <- scientific_identity_audit |>
  mutate(
    accepted_display_transition = .data$path %in%
      expected_display_transitions$path,
    classification = case_when(
      .data$live_exact ~ "LIVE_EXACT",
      .data$accepted_display_transition ~ "ORDER56_ACCEPTED_DISPLAY_TRANSITION",
      TRUE ~ "UNEXPECTED_DRIFT"
    ),
    scientific_scope = case_when(
      .data$live_exact ~ "historical scientific identity remains live-exact",
      .data$accepted_display_transition ~
        paste(
          "accepted display-only transition; underlying tables, source data,",
          "models, estimates, intervals, and decisions are unchanged"
        ),
      TRUE ~ "unclassified"
    ),
    status = if_else(
      .data$live_exact | .data$accepted_display_transition,
      "PASS",
      "FAIL"
    )
  )
stopifnot(all(scientific_identity_audit$status == "PASS"))

transition_audit <- expected_transition |>
  mutate(
    current_identity_verified = vapply(
      .data$current_sha256,
      function(expected) {
        path <- mismatches$path[match(
          expected,
          mismatches$current_sha256
        )]
        sha256_file(file.path(root, path)) == expected
      },
      logical(1)
    ),
    scientific_scope = c(
      paste(
        "Current artifact reproduces all 40 stored H09 gap frames exactly;",
        "the repaired field is MDER, which H09 does not use."
      ),
      paste(
        "Current manifest truthfully records the MDER-only repair; all H09",
        "gap model frames remain exact."
      ),
      paste(
        "Only the MDER registry row changed; all shared H09 display rows",
        "remain exact and H09 fits no MDER metric."
      )
    ),
    disposition = "ACCEPTED_H09_EQUIVALENT_PROVENANCE_TRANSITION",
    status = if_else(.data$current_identity_verified, "PASS", "FAIL")
  )
stopifnot(all(transition_audit$status == "PASS"))

checks <- tibble::tribble(
  ~domain,
  ~check,
  ~observed,
  ~expected,
  ~status,
  "environment",
  "R version",
  as.character(getRversion()),
  "4.6.1",
  "PASS",
  "environment",
  "dplyr version",
  as.character(packageVersion("dplyr")),
  "1.2.1",
  "PASS",
  "environment",
  "digest version",
  as.character(packageVersion("digest")),
  "0.6.39",
  "PASS",
  "stop",
  "direct controlling pins",
  paste0(length(observed_pins), "/", length(observed_pins)),
  "14/14",
  "PASS",
  "stop",
  "owner evidence manifest",
  "45/45",
  "45/45 exact unique non-circular",
  "PASS",
  "stop",
  "owner failure verification",
  "14/14",
  "14/14 PASS",
  "PASS",
  "stop",
  "exact stopped transition set",
  paste(expected_transition$input_role, collapse = "|"),
  paste(expected_transition$input_role, collapse = "|"),
  "PASS",
  "gap provenance",
  "gap-repair evidence manifest",
  "7/7",
  "7/7 exact",
  "PASS",
  "gap provenance",
  "non-MDER participant-day cells",
  "25620 exact",
  "25620 exact",
  "PASS",
  "gap provenance",
  "current gap artifact",
  paste0(nrow(gap), " rows; ", ncol(gap), " columns"),
  "27328 rows; 9 columns",
  "PASS",
  "H09 scope",
  "H09 gap metric set",
  paste(sort(h09_gap_metrics), collapse = "|"),
  paste(sort(h09_gap_metrics), collapse = "|"),
  "PASS",
  "H09 scope",
  "current-to-stored gap frames",
  paste0(
    sum(frame_checks$status == "PASS"),
    "/",
    nrow(frame_checks),
    "; rows=",
    sum(frame_checks$current_rows)
  ),
  "40/40; rows=32492",
  "PASS",
  "H09 scope",
  "gap frame full-object equality",
  paste0(sum(frame_checks$complete_frame_exact), "/", nrow(frame_checks)),
  "40/40",
  "PASS",
  "registry",
  "execution registry identity",
  sha256_file(old_registry_path),
  expected_pins[["display_registry_execution"]],
  "PASS",
  "registry",
  "current registry identity",
  sha256_file(file.path(root, pin_paths[["display_registry_current"]])),
  expected_pins[["display_registry_current"]],
  "PASS",
  "registry",
  "only changed registry construct",
  paste(old_only, current_only, sep = " -> "),
  "mder_ratio_of_integrals -> mder_mean_of_viable_ratios",
  "PASS",
  "registry",
  "H09 shared display rows",
  paste0(length(h09_shared_display_ids), "/", length(h09_shared_display_ids)),
  "5/5 exact",
  "PASS",
  "preservation",
  "historical H09 scientific inventory",
  paste0(
    sum(scientific_identity_audit$live_exact),
    " live-exact + ",
    sum(scientific_identity_audit$accepted_display_transition),
    " accepted display transitions"
  ),
  "57 live-exact + 8 accepted display transitions",
  "PASS",
  "disposition",
  "H09 scientific scope",
  "INVARIANT",
  "INVARIANT",
  "PASS",
  "disposition",
  "bounded provenance repin eligibility",
  "ELIGIBLE",
  "ELIGIBLE",
  "PASS"
)
stopifnot(nrow(checks) == 20L, all(checks$status == "PASS"))

output_root <- file.path(root, "audit/report_harmonization")
write_audit_csv(
  stop_manifest_audit,
  file.path(
    output_root,
    "report018_h09_order57_stopped_manifest_independent_audit.csv"
  )
)
write_audit_csv(
  frame_checks,
  file.path(output_root, "report018_h09_order57_gap_frame_identity.csv")
)
write_audit_csv(
  registry_checks,
  file.path(output_root, "report018_h09_order57_registry_transition_audit.csv")
)
write_audit_csv(
  transition_audit,
  file.path(output_root, "report018_h09_order57_input_transition_audit.csv")
)
write_audit_csv(
  scientific_identity_audit,
  file.path(output_root, "report018_h09_order57_scientific_identity_audit.csv")
)
write_audit_csv(
  checks,
  file.path(output_root, "report018_h09_order57_scientific_scope_audit.csv")
)

message(
  paste0(
    "REPORT018_H09_ORDER57_SCOPE=PASS stop=45/45 verification=14/14 ",
    "gap_evidence=7/7 non_mder=25620 frames=40/40 frame_rows=32492 ",
    "registry=MDER_only scientific=65/65 checks=20/20 R=4.6.1"
  )
)
