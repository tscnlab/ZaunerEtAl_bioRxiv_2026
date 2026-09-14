#!/usr/bin/env Rscript

# Seal the fail-closed REPORT-017 order-32g state after the first focused-test
# failure. This script inventories identities only and performs no scientific
# computation.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(tibble)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32g_continuation"
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

inventory_paths <- function(paths) {
  tibble(path = paths) |>
    rowwise() |>
    mutate(
      present = file.exists(.data$path),
      sha256 = if (.data$present) sha256_file(.data$path) else NA_character_,
      bytes = if (.data$present) as.numeric(file.info(.data$path)$size) else NA_real_
    ) |>
    ungroup()
}

dispatch_path <- file.path(
  root,
  "audit/report_harmonization/report017_h01_order32g_dispatch_manifest.csv"
)
dispatch <- read_csv(dispatch_path, show_col_types = FALSE, progress = FALSE) |>
  rowwise() |>
  mutate(
    current_sha256 = if (file.exists(file.path(root, .data$path))) {
      sha256_file(file.path(root, .data$path))
    } else {
      NA_character_
    },
    current_bytes = if (file.exists(file.path(root, .data$path))) {
      as.numeric(file.info(file.path(root, .data$path))$size)
    } else {
      NA_real_
    },
    exact = .data$sha256 == .data$current_sha256 &
      as.numeric(.data$bytes) == .data$current_bytes
  ) |>
  ungroup()
write_csv(dispatch, file.path(evidence_dir, "order32g_stopped_dispatch_audit.csv"))

manifest_paths <- c(
  "artifacts/12_manifests/H01_reporting_artifacts.csv",
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv",
  "artifacts/12_manifests/H01_worker_artifacts.csv"
)
manifest_audit <- bind_rows(lapply(manifest_paths, function(manifest_relative) {
  current_manifest <- read_csv(
    file.path(root, manifest_relative),
    show_col_types = FALSE,
    progress = FALSE
  )
  current_manifest |>
    rowwise() |>
    mutate(
      manifest = manifest_relative,
      present = file.exists(file.path(root, .data$path)),
      current_sha256 = if (.data$present) {
        sha256_file(file.path(root, .data$path))
      } else {
        NA_character_
      },
      current_bytes = if (.data$present) {
        as.numeric(file.info(file.path(root, .data$path))$size)
      } else {
        NA_real_
      },
      exact = .data$present && .data$sha256 == .data$current_sha256 &&
        as.numeric(.data$bytes) == .data$current_bytes
    ) |>
    ungroup() |>
    select(
      "manifest", "path", expected_sha256 = "sha256", "current_sha256",
      expected_bytes = "bytes", "current_bytes", "present", "exact"
    )
}))
write_csv(
  manifest_audit,
  file.path(evidence_dir, "order32g_stopped_manifest_audit.csv")
)
write_csv(
  filter(manifest_audit, !.data$exact),
  file.path(evidence_dir, "order32g_stopped_manifest_mismatches.csv")
)

core_manifest_relative <- paste0(
  "audit/hypotheses/H01/report017_model_support_fdr_refresh/",
  "H01_model_support_fdr_refresh_core_manifest.csv"
)
core_manifest <- read_csv(
  file.path(root, core_manifest_relative),
  show_col_types = FALSE,
  progress = FALSE
)
historical_substitutions <- c(
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png" =
    "audit/hypotheses/H01/report017_order32g_continuation/durable_pre32g/H01_stage3_model_support.png",
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg" =
    "audit/hypotheses/H01/report017_order32g_continuation/durable_pre32g/H01_stage3_model_support.svg",
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R" =
    "audit/hypotheses/H01/report017_order32g_continuation/build_h01_stage3_reporting_inputs_pre32g.R"
)
core_audit <- core_manifest |>
  rowwise() |>
  mutate(
    resolved_path = if (.data$path %in% names(historical_substitutions)) {
      unname(historical_substitutions[[.data$path]])
    } else {
      .data$path
    },
    current_sha256 = sha256_file(file.path(root, .data$resolved_path)),
    current_bytes = as.numeric(file.info(file.path(root, .data$resolved_path))$size),
    exact = .data$sha256 == .data$current_sha256 &
      as.numeric(.data$bytes) == .data$current_bytes
  ) |>
  ungroup()
write_csv(
  core_audit,
  file.path(evidence_dir, "order32g_stopped_core_manifest_audit.csv")
)

candidate_dir <- "/private/tmp/H01-order32g-candidates.Q1iS0N/attempt01"
durable_specs <- tribble(
  ~figure_id, ~format, ~durable_relative,
  "model_support", "png", "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
  "model_support", "svg", "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg",
  "paired_placement", "png", "artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.png",
  "paired_placement", "svg", "artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.svg",
  "diagnostic_assessment", "png", "artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.png",
  "diagnostic_assessment", "svg", "artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.svg"
) |>
  rowwise() |>
  mutate(
    candidate_path = file.path(
      candidate_dir,
      paste0("H01_stage3_", .data$figure_id, ".", .data$format)
    ),
    durable_path = file.path(root, .data$durable_relative),
    candidate_sha256 = sha256_file(.data$candidate_path),
    durable_sha256 = sha256_file(.data$durable_path),
    candidate_bytes = as.numeric(file.info(.data$candidate_path)$size),
    durable_bytes = as.numeric(file.info(.data$durable_path)$size),
    exact = .data$candidate_sha256 == .data$durable_sha256 &
      .data$candidate_bytes == .data$durable_bytes
  ) |>
  ungroup()
write_csv(
  durable_specs,
  file.path(evidence_dir, "order32g_stopped_candidate_durable_audit.csv")
)

order32f_inventory <- read_csv(
  file.path(
    root,
    "audit/hypotheses/H01/report017_order32f_continuation/partial_candidate_inventory.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
) |>
  mutate(set = "order32f")
order32e_seal <- read_csv(
  file.path(
    root,
    "audit/report_harmonization/report017_h01_order32e_stopped_state_independent_manifest.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
order32e_inventory <- order32e_seal |>
  filter(startsWith(.data$path, "/private/tmp/H01-order32e-candidates.hltKEs/")) |>
  mutate(set = "order32e")
quarantine_inventory <- read_csv(
  file.path(
    root,
    "audit/hypotheses/H01/report017_order32d_display_repair/quarantine_recovery_evidence.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
) |>
  transmute(
    path = .data$recovery_path,
    sha256 = .data$expected_sha256,
    bytes = .data$expected_bytes,
    set = "quarantine"
  )
retained <- bind_rows(
  order32f_inventory |> select("path", "sha256", "bytes", "set"),
  order32e_inventory |> select("path", "sha256", "bytes", "set"),
  quarantine_inventory
) |>
  rowwise() |>
  mutate(
    present = file.exists(.data$path),
    current_sha256 = if (.data$present) sha256_file(.data$path) else NA_character_,
    current_bytes = if (.data$present) as.numeric(file.info(.data$path)$size) else NA_real_,
    exact = .data$present && .data$sha256 == .data$current_sha256 &&
      as.numeric(.data$bytes) == .data$current_bytes
  ) |>
  ungroup()
write_csv(
  retained,
  file.path(evidence_dir, "order32g_stopped_retained_temporary_audit.csv")
)

pin_paths <- c(
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html",
  "_quarto-nathealth.yml",
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  "scripts/hypotheses/H01/refresh_h01_order32d_figures.R",
  "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R",
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R",
  "tests/hypotheses/H01/test_h01_order32g_display_repair.R"
)
write_csv(
  inventory_paths(file.path(root, pin_paths)) |>
    mutate(path = pin_paths),
  file.path(evidence_dir, "order32g_stopped_current_identities.csv")
)

summary <- tribble(
  ~check, ~value, ~status,
  "R version", as.character(getRversion()), "PASS",
  "dispatch exact rows", as.character(sum(dispatch$exact)), ifelse(sum(dispatch$exact) == 26L, "PASS", "REVIEW"),
  "dispatch transition rows", as.character(sum(!dispatch$exact)), ifelse(sum(!dispatch$exact) == 9L, "PASS", "REVIEW"),
  "reporting manifest mismatches", as.character(sum(!manifest_audit$exact & manifest_audit$manifest == manifest_paths[[1]])), "PASS",
  "Stage 3 manifest mismatches", as.character(sum(!manifest_audit$exact & manifest_audit$manifest == manifest_paths[[2]])), "EXPECTED_STOP",
  "worker manifest mismatches", as.character(sum(!manifest_audit$exact & manifest_audit$manifest == manifest_paths[[3]])), "EXPECTED_STOP",
  "historical core mismatches", as.character(sum(!core_audit$exact)), "STOP",
  "candidate durable exact", paste0(sum(durable_specs$exact), "/", nrow(durable_specs)), ifelse(all(durable_specs$exact), "PASS", "FAIL"),
  "retained temporary exact", paste0(sum(retained$exact), "/", nrow(retained)), ifelse(all(retained$exact), "PASS", "FAIL"),
  "result render executed", "no", "PASS"
)
write_csv(summary, file.path(evidence_dir, "order32g_stopped_summary.csv"))

stopifnot(
  nrow(dispatch) == 35L,
  all(durable_specs$exact),
  nrow(retained) == 31L,
  all(retained$exact),
  sum(!core_audit$exact) == 1L,
  identical(
    core_audit$path[!core_audit$exact],
    "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R"
  ),
  identical(
    sha256_file(file.path(root, "_build/nathealth/notebooks/hypotheses/H01.html")),
    "d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410"
  ),
  identical(
    sha256_file(file.path(root, "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html")),
    "5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38"
  )
)

cat("ORDER32G_STOPPED_STATE_SEAL=PASS\n")
cat("HISTORICAL_CORE_MISMATCHES=1\n")
cat("RENDER_EXECUTED=NO\n")
