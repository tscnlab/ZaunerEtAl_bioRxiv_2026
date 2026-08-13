#!/usr/bin/env Rscript

# Seal the H06-D-003 shifted-log pilot, report, and preservation manifests.
# This script performs no model fit or scientific transformation.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
required_packages <- c("digest", "dplyr", "readr", "tibble")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
manifest_frame <- function(rows, producer) {
  rows <- rows |>
    dplyr::distinct(.data$relative_path, .keep_all = TRUE)
  absolute <- file.path(root, rows$relative_path)
  stopifnot(all(file.exists(absolute)))
  rows |>
    dplyr::mutate(
      sha256 = unname(vapply(absolute, sha256, character(1))),
      bytes = unname(file.info(absolute)$size),
      producer = producer,
      r_version = as.character(getRversion()),
      .after = "relative_path"
    ) |>
    dplyr::select(
      "relative_path",
      "sha256",
      "bytes",
      "role",
      "producer",
      "r_version"
    )
}
write_manifest <- function(rows, relative_output, producer) {
  manifest <- manifest_frame(rows, producer)
  readr::write_csv(manifest, file.path(root, relative_output), na = "")
  manifest
}
path_rows <- function(paths, roles) {
  stopifnot(length(paths) == length(roles))
  tibble::tibble(relative_path = paths, role = roles)
}

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "build_h06_daily_l10_shiftlog_pilot_manifests.R"
)
manifest_root <- "artifacts/12_manifests/H06_daily"
diagnostic_root <- "artifacts/08_diagnostics/H06_daily"

####
# Final historical preservation seal
####

historical_baseline_path <- file.path(
  root,
  diagnostic_root,
  "H06_daily_l10_shiftlog_historical_preservation_baseline.csv"
)
historical <- readr::read_csv(
  historical_baseline_path,
  show_col_types = FALSE,
  na = c("", "NA")
)
historical_absolute <- file.path(root, historical$relative_path)
stopifnot(nrow(historical) == 118L, all(file.exists(historical_absolute)))
historical_final <- historical |>
  dplyr::mutate(
    sha256_final = unname(vapply(
      historical_absolute,
      sha256,
      character(1)
    )),
    bytes_final = unname(file.info(historical_absolute)$size),
    preserved_final = .data$sha256 == .data$sha256_final &
      .data$bytes == .data$bytes_final,
    verification_stage = "H06-D-003 shifted-log pilot author gate"
  )
stopifnot(all(historical_final$preserved_final))
historical_final_relative <- file.path(
  diagnostic_root,
  "H06_daily_l10_shiftlog_historical_preservation_final.csv"
)
readr::write_csv(
  historical_final,
  file.path(root, historical_final_relative),
  na = ""
)

####
# Input manifest
####

input_contract_relative <- file.path(
  diagnostic_root,
  "H06_daily_l10_shiftlog_input_contract.csv"
)
input_contract <- readr::read_csv(
  file.path(root, input_contract_relative),
  show_col_types = FALSE,
  na = c("", "NA")
)
stopifnot(
  nrow(input_contract) == 14L,
  all(input_contract$identity_pass),
  identical(input_contract$expected_sha256, input_contract$actual_sha256)
)
frame_registry_relative <- paste0(
  "artifacts/06_model_data/H06_daily/",
  "H06_daily_l10_shiftlog_pilot_frame_registry.csv"
)
frame_registry <- readr::read_csv(
  file.path(root, frame_registry_relative),
  show_col_types = FALSE,
  na = c("", "NA")
)
stopifnot(nrow(frame_registry) == 3L)

static_paths <- c(
  input_contract_relative,
  file.path(diagnostic_root, "H06_daily_l10_shiftlog_static_verdict.csv"),
  file.path(
    diagnostic_root,
    "H06_daily_l10_shiftlog_exact_reuse_verification.csv"
  ),
  file.path(
    diagnostic_root,
    "H06_daily_l10_shiftlog_reference_registry.csv"
  ),
  frame_registry_relative,
  "artifacts/09_tables/H06_daily/H06_daily_l10_shiftlog_formula_registry.csv",
  file.path(
    diagnostic_root,
    "H06_daily_l10_shiftlog_historical_preservation_baseline.csv"
  ),
  file.path(
    manifest_root,
    "H06_daily_l10_shiftlog_static_software_manifest.csv"
  )
)
static_roles <- c(
  "passed 14-input identity contract",
  "passed no-fit static verdict",
  "three-object exact-reuse verification",
  "historical subobject provenance registry",
  "three-frame pilot registry",
  "prespecified formula and fit-action registry",
  "118-entry historical preservation baseline",
  "static-audit software versions"
)
input_rows <- dplyr::bind_rows(
  input_contract |>
    dplyr::transmute(
      relative_path = .data$relative_path,
      role = paste0("sealed input: ", .data$role)
    ),
  path_rows(static_paths, static_roles),
  path_rows(
    frame_registry$frame_path,
    paste0("exact shifted-log pilot frame: ", frame_registry$predictor_id)
  )
)
input_manifest_relative <- file.path(
  manifest_root,
  "H06_daily_l10_shiftlog_pilot_input_manifest.csv"
)
input_manifest <- write_manifest(
  input_rows,
  input_manifest_relative,
  producer
)

####
# Code manifest
####

code_paths <- c(
  paste0(
    "scripts/hypotheses/H06_daily/",
    c(
      "h06_daily_l10_shiftlog_contract.R",
      "h06_daily_l10_shiftlog_data.R",
      "h06_daily_l10_shiftlog_modeling.R",
      "audit_h06_daily_l10_shiftlog.R",
      "run_h06_daily_l10_shiftlog_pilot.R",
      "build_h06_daily_l10_shiftlog_pilot_manifests.R"
    )
  ),
  paste0(
    "tests/hypotheses/H06_daily/",
    c(
      "test_h06_daily_l10_shiftlog_static.R",
      "test_h06_daily_l10_shiftlog_pilot.R"
    )
  )
)
code_roles <- c(
  "shifted-log decision contract and registries",
  "current-frame construction and exact-reuse helpers",
  "one-part fits, diagnostics, AR, and pointwise summaries",
  "no-fit static contract and reuse audit",
  "compute-cleared representative production-code pilot",
  "no-fit pilot/report manifest builder",
  "focused no-fit static verification",
  "focused no-refit pilot/report verification"
)
code_manifest_relative <- file.path(
  manifest_root,
  "H06_daily_l10_shiftlog_pilot_code_manifest.csv"
)
code_manifest <- write_manifest(
  path_rows(code_paths, code_roles),
  code_manifest_relative,
  producer
)

####
# Scientific output manifest
####

output_paths <- c(
  "artifacts/07_models/H06_daily/H06_daily_l10_shiftlog_pilot_new_models.rds",
  paste0(
    "artifacts/09_tables/H06_daily/H06_daily_l10_shiftlog_pilot_",
    c(
      "samples.csv",
      "effects.csv",
      "model_tests.csv",
      "equal_site_estimates.csv",
      "equal_site_contrasts.csv"
    )
  ),
  paste0(
    diagnostic_root,
    "/H06_daily_l10_shiftlog_pilot_",
    c(
      "diagnostics.csv",
      "zero_mass.csv",
      "family_sensitivity.csv",
      "residual_lag.csv",
      "site_residual_lag.csv",
      "post_ar_site_residual_lag.csv",
      "ar_counterparts.csv",
      "registered_benchmark.csv",
      "runtime.csv",
      "runtime_projection.csv",
      "model_provenance.csv",
      "verdict.csv"
    )
  ),
  file.path(
    diagnostic_root,
    "H06_daily_l10_shiftlog_historical_preservation_after_pilot.csv"
  ),
  historical_final_relative,
  paste0(
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_l10_shiftlog_pilot_equal_site_grid.csv"
  )
)
output_roles <- c(
  "new pilot-only comparison, sensitivity, benchmark, and AR model bundle",
  rep("pilot reader table", 5L),
  rep("pilot diagnostic and gate evidence", 12L),
  "118-entry preservation check immediately after fitting",
  "118-entry preservation check at report seal",
  "equal-site prediction grid supporting reader tables"
)
output_manifest_relative <- file.path(
  manifest_root,
  "H06_daily_l10_shiftlog_pilot_output_manifest.csv"
)
output_manifest <- write_manifest(
  path_rows(output_paths, output_roles),
  output_manifest_relative,
  producer
)

####
# Software manifest
####

software_packages <- c(
  "digest",
  "dplyr",
  "glmmTMB",
  "gt",
  "knitr",
  "lme4",
  "readr",
  "reformulas",
  "tibble",
  "tidyr"
)
quarto_version <- tryCatch(
  trimws(system2("quarto", "--version", stdout = TRUE, stderr = FALSE)[[1L]]),
  error = function(condition) NA_character_
)
stopifnot(is.character(quarto_version), length(quarto_version) == 1L)
software_manifest <- tibble::tibble(
  software = c("R", software_packages, "Quarto"),
  version = c(
    as.character(getRversion()),
    vapply(
      software_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    ),
    quarto_version
  ),
  role = c(
    "authoritative research computation language",
    rep("synchronized project package", length(software_packages)),
    "single-document author-gate renderer"
  ),
  producer = producer,
  r_version = as.character(getRversion())
)
software_manifest_relative <- file.path(
  manifest_root,
  "H06_daily_l10_shiftlog_pilot_software_manifest.csv"
)
readr::write_csv(
  software_manifest,
  file.path(root, software_manifest_relative),
  na = ""
)

####
# Durable report manifest
####

report_paths <- c(
  "audit/hypotheses/H06_daily/09_l10_shiftlog_pilot.qmd",
  "audit/hypotheses/H06_daily/09_l10_shiftlog_pilot.html",
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_l10_shiftlog_pilot_transition.md"
  ),
  "audit/handoffs/H06_daily_worker_handoff.md",
  code_paths,
  input_manifest_relative,
  code_manifest_relative,
  output_manifest_relative,
  software_manifest_relative,
  output_paths
)
report_roles <- c(
  "author-gate Quarto source",
  "self-contained author-gate HTML",
  "H06-D-G2P-L10-SHIFTLOG stop-gate transition",
  "current H06_daily worker handoff",
  rep("executed or verification code", length(code_paths)),
  "pilot input manifest",
  "pilot code manifest",
  "pilot scientific output manifest",
  "pilot software manifest",
  rep("durable shifted-log pilot output", length(output_paths))
)
report_manifest_relative <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_l10_shiftlog_pilot_report_manifest.csv"
)
report_manifest <- write_manifest(
  path_rows(report_paths, report_roles),
  report_manifest_relative,
  producer
)

stopifnot(
  nrow(input_manifest) >= 20L,
  nrow(code_manifest) == 8L,
  nrow(output_manifest) == 21L,
  nrow(software_manifest) == 12L,
  nrow(report_manifest) > nrow(output_manifest),
  all(historical_final$preserved_final)
)
message(
  "H06-D-003 pilot manifests sealed: ",
  nrow(input_manifest),
  " inputs, ",
  nrow(code_manifest),
  " code files, ",
  nrow(output_manifest),
  " outputs, and 118 historical entries preserved."
)
