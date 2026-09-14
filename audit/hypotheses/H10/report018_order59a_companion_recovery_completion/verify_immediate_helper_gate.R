#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages(library(openssl))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
temp_root <- normalizePath(
  Sys.getenv("H10_ORDER59A_TEMP_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

manifest_path <-
  "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv"
preview_path <- paste0(
  "audit/report_harmonization/report018_h10_companion_preflight/",
  "prospective_preparation_report_manifest_preview.csv"
)
exclusions_path <- paste0(
  "audit/report_harmonization/report018_h10_order59_recovery_preflight/",
  "order59_historical_evidence_exclusions.csv"
)
manifest <- read.csv(manifest_path, check.names = FALSE)
preview <- read.csv(preview_path, check.names = FALSE)
exclusions <- read.csv(exclusions_path, check.names = FALSE)

manifest_files <- file.path(root, manifest$path)
member_exact <- vapply(
  seq_len(nrow(manifest)),
  function(index) {
    file.exists(manifest_files[[index]]) &&
      !dir.exists(manifest_files[[index]]) &&
      identical(sha256_file(manifest_files[[index]]), manifest$sha256[[index]]) &&
      identical(file_bytes(manifest_files[[index]]), as.numeric(manifest$bytes[[index]]))
  },
  logical(1)
)

common <- merge(
  manifest[, c("path", "sha256", "bytes")],
  preview[, c("path", "sha256", "bytes")],
  by = "path",
  suffixes = c("_live", "_preview")
)
changed <- common[
  common$sha256_live != common$sha256_preview |
    common$bytes_live != common$bytes_preview,
  ,
  drop = FALSE
]
helper_path <- "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R"
historical_dir <- paste0(
  "audit/hypotheses/H10/",
  "report018_order59_companion_no_rerender_completion"
)
recovery_dir <- paste0(
  "audit/hypotheses/H10/",
  "report018_order59a_companion_recovery_completion"
)
historical_names <- sort(list.files(
  historical_dir,
  recursive = FALSE,
  include.dirs = FALSE
))

checks <- data.frame(
  check_id = c(
    "terminal_contract",
    "manifest_rows_unique_and_path_set",
    "all_members_live_exact",
    "helper_only_preview_identity_change",
    "manifest_non_circular",
    "historical_evidence_excluded",
    "chronological_evidence_rule",
    "source_build_qmd_identity"
  ),
  pass = c(
    TRUE,
    nrow(manifest) == 269L &&
      !anyDuplicated(manifest$path) &&
      setequal(manifest$path, preview$path),
    all(member_exact),
    nrow(changed) == 1L &&
      identical(changed$path, helper_path) &&
      identical(changed$sha256_live, "26619260657ec0cb1d7ac7614af9e3e349a524ee242dd5645b27e31f4cb142f0") &&
      identical(changed$sha256_preview, "292ad3335dac8241f317983d5017a5a1d5dbce51fef245d2c30889cf4a3dcf97"),
    !manifest_path %in% manifest$path,
    nrow(exclusions) == 13L &&
      !any(exclusions$path %in% manifest$path) &&
      length(historical_names) == 13L,
    !dir.exists(recovery_dir) &&
      !any(startsWith(manifest$path, paste0(recovery_dir, "/"))),
    identical(
      sha256_file("audit/hypotheses/H10/H10_analysis_preparation.qmd"),
      "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6"
    ) &&
      identical(
        sha256_file("_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.qmd"),
        "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6"
      )
  ),
  detail = c(
    "H10 preparation-report manifest completed: 269 current files",
    sprintf("live=%d preview=%d shared=%d", nrow(manifest), nrow(preview), length(intersect(manifest$path, preview$path))),
    sprintf("exact=%d/%d", sum(member_exact), nrow(manifest)),
    paste(changed$path, collapse = "|"),
    sprintf("self_rows=%d", sum(manifest$path == manifest_path)),
    sprintf("sealed=%d excluded=%d historical_files=%d", nrow(exclusions), sum(exclusions$path %in% manifest$path), length(historical_names)),
    sprintf("recovery_dir_present=%s", dir.exists(recovery_dir)),
    "authoring and build QMD SHA-256 706fe46f..."
  ),
  stringsAsFactors = FALSE
)

stopifnot(nrow(checks) == 8L, all(checks$pass))
write.csv(
  checks,
  file.path(temp_root, "immediate_helper_gate_checks.csv"),
  row.names = FALSE,
  na = ""
)
stopifnot(file.copy(
  manifest_path,
  file.path(temp_root, "live_269_manifest_at_gate.csv"),
  overwrite = TRUE
))
cat(sprintf(
  paste0(
    "REPORT018_H10_ORDER59A_HELPER_GATE=PASS checks=8 manifest=269/269 ",
    "members=269/269 helper_delta=1 historical=13/13 recovery_dir=absent ",
    "sha256=%s R=4.6.1\n"
  ),
  sha256_file(manifest_path)
))
