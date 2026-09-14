#!/usr/bin/env Rscript

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2, lifecycle_verbosity = "quiet")

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 57a preflight requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
working_dir <- normalizePath(
  Sys.getenv("ORDER57A_WORKING_DIR"),
  winslash = "/",
  mustWork = TRUE
)
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

stopifnot(
  !startsWith(working_dir, paste0(root, "/")),
  !startsWith(semantic_dir, paste0(root, "/")),
  length(list.files(semantic_dir, all.files = TRUE, no.. = TRUE)) == 0L
)

source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

sha256_text <- function(value) {
  digest::digest(charToRaw(value), algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) unname(file.info(path)$size)

read_exact_text <- function(path) {
  readChar(path, nchars = file_bytes(path), useBytes = TRUE)
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(working_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

list_files <- function(path, exclude_prefix = character()) {
  if (!dir.exists(path)) return(character())
  files <- list.files(
    path,
    all.files = TRUE,
    full.names = TRUE,
    recursive = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
  info <- file.info(files)
  files <- files[!is.na(info$isdir) & !info$isdir]
  if (length(exclude_prefix)) {
    normalized <- normalizePath(files, winslash = "/", mustWork = FALSE)
    excluded <- Reduce(
      `|`,
      lapply(exclude_prefix, function(prefix) {
        normalized_prefix <- normalizePath(
          prefix,
          winslash = "/",
          mustWork = FALSE
        )
        normalized == normalized_prefix |
          startsWith(normalized, paste0(normalized_prefix, "/"))
      })
    )
    files <- files[!excluded]
  }
  files
}

inventory_paths <- function(paths, role = "inventory_member") {
  paths <- sort(unique(paths))
  stopifnot(length(paths) > 0L, all(file.exists(paths)))
  links <- Sys.readlink(paths)
  normalized <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  info <- file.info(normalized)
  stopifnot(all(!info$isdir))
  data.frame(
    relative_path = relative_path(normalized),
    role = if (length(role) == 1L) rep(role, length(normalized)) else role,
    sha256 = vapply(normalized, sha256_file, character(1)),
    bytes = as.numeric(info$size),
    modified_utc = format(
      info$mtime,
      tz = "UTC",
      usetz = TRUE,
      format = "%Y-%m-%dT%H:%M:%OS6Z"
    ),
    is_symlink = nzchar(links),
    symlink_target = links,
    stringsAsFactors = FALSE
  )
}

replace_once <- function(text, from, to, label) {
  hits <- gregexpr(from, text, fixed = TRUE)[[1L]]
  if (identical(hits, -1L) || length(hits) != 1L) {
    stop("Reverse proof failed for ", label, call. = FALSE)
  }
  sub(from, to, text, fixed = TRUE)
}

checks <- data.frame(
  domain = character(),
  check = character(),
  observed = character(),
  expected = character(),
  status = character()
)

add_check <- function(domain, check, observed, expected, pass) {
  checks <<- rbind(
    checks,
    data.frame(
      domain = domain,
      check = check,
      observed = paste(observed, collapse = "|"),
      expected = paste(expected, collapse = "|"),
      status = if (isTRUE(pass)) "PASS" else "FAIL"
    )
  )
}

order_rel <- paste0(
  "audit/report_harmonization/owner_orders/",
  "57a_h09_companion_input_provenance_repair_and_retry.md"
)
acceptance_rel <- paste0(
  "audit/report_harmonization/",
  "report018_h09_order57_stopped_independent_acceptance.md"
)
acceptance_manifest_rel <- paste0(
  "audit/report_harmonization/",
  "report018_h09_order57_stopped_independent_acceptance_manifest.csv"
)
dispatch_rel <- paste0(
  "audit/report_harmonization/",
  "report018_h09_order57a_dispatch_manifest.csv"
)
checker_rel <- paste0(
  "scripts/report_harmonization/",
  "check_report018_h09_order57_stop_and_scientific_scope.R"
)
matrix_rel <- "audit/report_harmonization/coordination_matrix.csv"

fixed <- data.frame(
  path = c(order_rel, acceptance_rel, acceptance_manifest_rel, dispatch_rel, checker_rel),
  sha256 = c(
    "9615f4d7d78051a1deea1d3f48807b855889b39ff8b2ea1cdac78b3fc8bbe560",
    "497f20015921c576dcf210b686c3156e3320f1677424d4f938fdc097e633d998",
    "dc59c40745e4fc8ced3465cedce556245d1b48802e9e5d6d05fd959f7d849b9b",
    "fc63a882cff7cbb852161aa4057b24ef8684d78dbcfad3dfd87b67b6033d48a7",
    "4671036544a7ad9104eec432c829788f9cbb0486b5dd4ee06841552e5d3bef37"
  ),
  bytes = c(11853, 4670, 4829, 7823, 24526),
  stringsAsFactors = FALSE
)
fixed_files <- file.path(root, fixed$path)
fixed$observed_sha256 <- vapply(fixed_files, sha256_file, character(1))
fixed$observed_bytes <- file_bytes(fixed_files)
fixed$status <- ifelse(
  fixed$observed_sha256 == fixed$sha256 & fixed$observed_bytes == fixed$bytes,
  "PASS",
  "FAIL"
)
write_evidence(fixed, "controlling_identities_prerender.csv")
add_check(
  "authority",
  "order, acceptance, seals, and checker",
  sum(fixed$status == "PASS"),
  nrow(fixed),
  all(fixed$status == "PASS")
)

matrix_observation <- data.frame(
  path = matrix_rel,
  sha256 = sha256_file(file.path(root, matrix_rel)),
  bytes = file_bytes(file.path(root, matrix_rel)),
  hard_pin = FALSE,
  role = "coordination evidence only",
  stringsAsFactors = FALSE
)
write_evidence(matrix_observation, "coordination_matrix_observation.csv")

authoring_paths <- c(
  "scripts/hypotheses/H09/h09_contract.R",
  "artifacts/06_model_data/H09/H09_input_audit.csv",
  "audit/hypotheses/H09/H09_analysis_preparation.qmd"
)
preimage_paths <- setNames(
  file.path(working_dir, c(
    "h09_contract.R.preimage",
    "H09_input_audit.csv.preimage",
    "H09_analysis_preparation.qmd.preimage"
  )),
  authoring_paths
)
postimage_sha <- c(
  "scripts/hypotheses/H09/h09_contract.R" =
    "866b0f8736c8a25f50a3f1ce6e38c5d33d4666d4bf06031f0021ee1cb6d0b701",
  "artifacts/06_model_data/H09/H09_input_audit.csv" =
    "1ea3910539378434533dcaeeaee6ab613e325468d99ffd10e02bdc868a4175ed",
  "audit/hypotheses/H09/H09_analysis_preparation.qmd" =
    "286c391fb228268804ba199d38bd5341509b3a66d434e30aa09fc1007a19443e"
)
postimage_bytes <- c(
  "scripts/hypotheses/H09/h09_contract.R" = 16374,
  "artifacts/06_model_data/H09/H09_input_audit.csv" = 4401,
  "audit/hypotheses/H09/H09_analysis_preparation.qmd" = 48400
)

dispatch <- read.csv(file.path(root, dispatch_rel), check.names = FALSE)
dispatch_observed_path <- vapply(
  dispatch$path,
  function(path) {
    if (path %in% authoring_paths) preimage_paths[[path]] else file.path(root, path)
  },
  character(1)
)
dispatch$observed_from <- ifelse(
  dispatch$path %in% authoring_paths,
  "external byte-identical preimage",
  "live project file"
)
dispatch$current_or_preimage_sha256 <- vapply(
  dispatch_observed_path,
  sha256_file,
  character(1)
)
dispatch$current_or_preimage_bytes <- file_bytes(dispatch_observed_path)
dispatch$status <- ifelse(
  dispatch$current_or_preimage_sha256 == dispatch$sha256 &
    dispatch$current_or_preimage_bytes == as.numeric(dispatch$bytes),
  "PASS",
  "FAIL"
)
write_evidence(dispatch, "dispatch_reconciliation_prerender.csv")
add_check(
  "authority",
  "49-row dispatch reproduced",
  paste(sum(dispatch$status == "PASS"), nrow(dispatch), sep = "/"),
  "49/49 exact unique non-circular",
  nrow(dispatch) == 49L && !anyDuplicated(dispatch$path) &&
    !dispatch_rel %in% dispatch$path && all(dispatch$status == "PASS")
)

acceptance_manifest <- read.csv(
  file.path(root, acceptance_manifest_rel),
  check.names = FALSE
)
acceptance_observed_path <- vapply(
  acceptance_manifest$path,
  function(path) {
    if (path %in% authoring_paths) preimage_paths[[path]] else file.path(root, path)
  },
  character(1)
)
acceptance_manifest$observed_from <- ifelse(
  acceptance_manifest$path %in% authoring_paths,
  "external byte-identical preimage",
  "live project file"
)
acceptance_manifest$observed_sha256 <- vapply(
  acceptance_observed_path,
  sha256_file,
  character(1)
)
acceptance_manifest$observed_bytes <- file_bytes(acceptance_observed_path)
acceptance_manifest$status <- ifelse(
  acceptance_manifest$observed_sha256 == acceptance_manifest$sha256 &
    acceptance_manifest$observed_bytes == as.numeric(acceptance_manifest$bytes),
  "PASS",
  "FAIL"
)
write_evidence(
  acceptance_manifest,
  "stopped_acceptance_manifest_audit_prerender.csv"
)
add_check(
  "authority",
  "30-row stopped-state acceptance seal",
  paste(
    sum(acceptance_manifest$status == "PASS"),
    nrow(acceptance_manifest),
    sep = "/"
  ),
  "30/30 exact unique non-circular",
  nrow(acceptance_manifest) == 30L &&
    !anyDuplicated(acceptance_manifest$path) &&
    !acceptance_manifest_rel %in% acceptance_manifest$path &&
    all(acceptance_manifest$status == "PASS")
)

stop_manifest_rel <- paste0(
  "audit/hypotheses/H09/report018_order57_companion_render/",
  "order57_fail_closed_evidence_manifest.csv"
)
stop_manifest <- read.csv(file.path(root, stop_manifest_rel), check.names = FALSE)
stop_files <- file.path(root, stop_manifest$path)
stop_exact <- file.exists(stop_files) & !dir.exists(stop_files) &
  vapply(stop_files, sha256_file, character(1)) == stop_manifest$sha256 &
  file_bytes(stop_files) == as.numeric(stop_manifest$bytes)
stop_audit <- transform(
  stop_manifest,
  observed_sha256 = vapply(stop_files, sha256_file, character(1)),
  observed_bytes = file_bytes(stop_files),
  status = ifelse(stop_exact, "PASS", "FAIL")
)
write_evidence(stop_audit, "order57_owner_seal_audit_prerender.csv")
stop_dir_files <- list_files(file.path(
  root,
  "audit/hypotheses/H09/report018_order57_companion_render"
))
add_check(
  "history",
  "complete order-57 failed history",
  paste(sum(stop_exact), nrow(stop_manifest), length(stop_dir_files), sep = "/"),
  "45/45 sealed rows plus one non-circular seal file",
  nrow(stop_manifest) == 45L && !anyDuplicated(stop_manifest$path) &&
    !stop_manifest_rel %in% stop_manifest$path && all(stop_exact) &&
    length(stop_dir_files) == 46L
)

postimage_files <- file.path(root, authoring_paths)
postimage_audit <- data.frame(
  path = authoring_paths,
  expected_sha256 = unname(postimage_sha[authoring_paths]),
  observed_sha256 = vapply(postimage_files, sha256_file, character(1)),
  expected_bytes = unname(postimage_bytes[authoring_paths]),
  observed_bytes = file_bytes(postimage_files),
  stringsAsFactors = FALSE
)
postimage_audit$status <- ifelse(
  postimage_audit$expected_sha256 == postimage_audit$observed_sha256 &
    postimage_audit$expected_bytes == postimage_audit$observed_bytes,
  "PASS",
  "FAIL"
)
write_evidence(postimage_audit, "authorized_postimages_prerender.csv")
add_check(
  "source repair",
  "three exact postimages",
  sum(postimage_audit$status == "PASS"),
  3L,
  all(postimage_audit$status == "PASS")
)

contract_text <- read_exact_text(postimage_files[[1L]])
contract_reverse <- replace_once(
  contract_text,
  "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
  "28266064c6213eae6046ec6469d0dae39529f56e60933dcd581cf96c8590e1a4",
  "contract gap RDS"
)
contract_reverse <- replace_once(
  contract_reverse,
  "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
  "af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267",
  "contract gap manifest"
)
contract_reverse <- replace_once(
  contract_reverse,
  "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0",
  "6c0adc3ca061ac49591d71243dd7ff0693311eb1f499836cf52c2742328b8154",
  "contract display registry"
)

input_text <- read_exact_text(postimage_files[[2L]])
input_new <- c(
  paste0(
    "gap_timing_unaware_metrics,artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds,",
    "Current MDER-repaired shared identity; all 40 H09 gap frames reproduce exactly,",
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1,",
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1,TRUE,,,TRUE,88248"
  ),
  paste0(
    "gap_manifest,artifacts/12_manifests/manuscript_prepared_data_artifacts.csv,",
    "Current provenance for the MDER-only shared repair; H09 gap frames unchanged,",
    "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935,",
    "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935,TRUE,,,TRUE,4497"
  ),
  paste0(
    "metric_display_registry,config/metric_display_registry.csv,",
    "Current display registry; only the unused MDER row changed and all H09 rows remain exact,",
    "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0,",
    "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0,TRUE,,,TRUE,3203"
  )
)
input_old <- c(
  paste0(
    "gap_timing_unaware_metrics,artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds,",
    "Approved prepared-data sensitivity,",
    "28266064c6213eae6046ec6469d0dae39529f56e60933dcd581cf96c8590e1a4,",
    "28266064c6213eae6046ec6469d0dae39529f56e60933dcd581cf96c8590e1a4,TRUE,,,TRUE,88760"
  ),
  paste0(
    "gap_manifest,artifacts/12_manifests/manuscript_prepared_data_artifacts.csv,",
    "Gap-timing-unaware provenance,",
    "af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267,",
    "af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267,TRUE,,,TRUE,3970"
  ),
  paste0(
    "metric_display_registry,config/metric_display_registry.csv,Manuscript metric display names,",
    "6c0adc3ca061ac49591d71243dd7ff0693311eb1f499836cf52c2742328b8154,",
    "6c0adc3ca061ac49591d71243dd7ff0693311eb1f499836cf52c2742328b8154,TRUE,,,TRUE,3182"
  )
)
input_reverse <- input_text
for (i in seq_along(input_new)) {
  input_reverse <- replace_once(
    input_reverse,
    input_new[[i]],
    input_old[[i]],
    paste("input audit row", i)
  )
}

qmd_text <- read_exact_text(postimage_files[[3L]])
qmd_new_paragraph <- paste(
  c(
    "Eleven current inputs reproduce the accepted H09 analysis: preparation",
    "records, near-eye and chest participant-day data, the normalized chronotype",
    "table, the preparation-sensitivity data, and the site and metric display",
    "registries. Eight retain their execution-time identities. Three shared inputs",
    "changed later through an MDER-only repair: the preparation-sensitivity data,",
    "its manifest, and the metric display registry. H09 does not use MDER, and all",
    "40 stored H09 gap-sensitivity model frames reproduce exactly from the current",
    "data. The table therefore reports current reproducibility identities, while",
    "the historical execution identities remain preserved in the REPORT-018",
    "transition evidence."
  ),
  collapse = "\n"
)
qmd_old_paragraph <- paste(
  c(
    "Eleven verified inputs define the current result-producing chain: preparation",
    "records, near-eye and chest participant-day data, the normalized chronotype",
    "table, the preparation-sensitivity data, and the site and metric display",
    "registries. Their complete 64-character SHA-256 values were recorded before",
    "analysis."
  ),
  collapse = "\n"
)
qmd_new_caption <-
  "#| tbl-cap: \"Current reproducibility inputs for the accepted H09 analysis.\""
qmd_old_caption <-
  "#| tbl-cap: \"Verified inputs used by the current H09 result-producing analysis.\""
qmd_new_note <- paste(
  c(
    "  gt::tab_source_note(",
    "    paste(",
    "      \"Current identities remain in artifacts/06_model_data/H09/H09_input_audit.csv.\",",
    "      \"The three execution-time identities remain in the REPORT-018 order-57 transition evidence.\"",
    "    )",
    "  ) |>"
  ),
  collapse = "\n"
)
qmd_old_note <- paste(
  c(
    "  gt::tab_source_note(",
    "    \"Complete identities remain in artifacts/06_model_data/H09/H09_input_audit.csv.\"",
    "  ) |>"
  ),
  collapse = "\n"
)
qmd_reverse <- replace_once(
  qmd_text,
  qmd_new_paragraph,
  qmd_old_paragraph,
  "companion provenance paragraph"
)
qmd_reverse <- replace_once(
  qmd_reverse,
  qmd_new_caption,
  qmd_old_caption,
  "companion input table caption"
)
qmd_reverse <- replace_once(
  qmd_reverse,
  qmd_new_note,
  qmd_old_note,
  "companion input table source note"
)

reversed <- list(contract_reverse, input_reverse, qmd_reverse)
reverse_audit <- data.frame(
  path = authoring_paths,
  reversed_sha256 = vapply(reversed, sha256_text, character(1)),
  expected_preimage_sha256 = vapply(preimage_paths, sha256_file, character(1)),
  reversed_bytes = vapply(reversed, function(x) length(charToRaw(x)), numeric(1)),
  expected_preimage_bytes = file_bytes(preimage_paths),
  stringsAsFactors = FALSE
)
reverse_audit$status <- ifelse(
  reverse_audit$reversed_sha256 == reverse_audit$expected_preimage_sha256 &
    reverse_audit$reversed_bytes == reverse_audit$expected_preimage_bytes,
  "PASS",
  "FAIL"
)
write_evidence(reverse_audit, "source_reverse_proof_prerender.csv")
add_check(
  "source repair",
  "exact reversal to three preimages",
  sum(reverse_audit$status == "PASS"),
  3L,
  all(reverse_audit$status == "PASS")
)

input_audit <- read.csv(
  file.path(root, "artifacts/06_model_data/H09/H09_input_audit.csv"),
  check.names = FALSE
)
input_files <- file.path(root, input_audit$path)
input_audit$current_sha256 <- vapply(input_files, sha256_file, character(1))
input_audit$current_bytes <- file_bytes(input_files)
input_audit$current_identity_exact <-
  input_audit$expected_sha256 == input_audit$current_sha256 &
  input_audit$observed_sha256 == input_audit$current_sha256 &
  as.numeric(input_audit$bytes) == input_audit$current_bytes
input_audit$status <- ifelse(
  input_audit$current_identity_exact & input_audit$hash_verified &
    input_audit$rows_verified,
  "PASS",
  "FAIL"
)
write_evidence(input_audit, "input_audit_current_identity_prerender.csv")
result_roles <- c(
  "metric_manifest", "base_manifest", "primary_near_eye_context",
  "primary_chest_context", "primary_near_eye_enriched",
  "primary_chest_enriched", "normalized_chronotype",
  "gap_timing_unaware_metrics", "gap_manifest",
  "site_display_registry", "metric_display_registry"
)
add_check(
  "source repair",
  "all input-audit rows and result roles current",
  paste(
    sum(input_audit$status == "PASS"),
    sum(input_audit$input_role %in% result_roles & input_audit$status == "PASS"),
    sep = "/"
  ),
  "16/11",
  nrow(input_audit) == 16L && all(input_audit$status == "PASS") &&
    sum(input_audit$input_role %in% result_roles) == 11L
)

excluded_path <- file.path(
  root,
  "artifacts/06_model_data/H09/H09_METRIC-011_excluded_shared_drift.csv"
)
add_check(
  "history",
  "historical excluded shared drift record",
  paste(sha256_file(excluded_path), file_bytes(excluded_path), sep = "/"),
  paste(
    "91d9781466273385338432c7d86c68f35ae65ba828e547659d0cf69720b5b5b9",
    1266,
    sep = "/"
  ),
  sha256_file(excluded_path) ==
    "91d9781466273385338432c7d86c68f35ae65ba828e547659d0cf69720b5b5b9" &&
    file_bytes(excluded_path) == 1266
)

checker_path <- file.path(root, checker_rel)
checker_sha_before <- sha256_file(checker_path)
checker_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", checker_path),
  stdout = TRUE,
  stderr = TRUE
)
checker_status <- attr(checker_output, "status")
if (is.null(checker_status)) checker_status <- 0L
writeLines(
  checker_output,
  file.path(working_dir, "scientific_scope_checker_console.log"),
  useBytes = TRUE
)
checker_expected_line <- paste0(
  "REPORT018_H09_ORDER57_SCOPE=PASS stop=45/45 verification=14/14 ",
  "gap_evidence=7/7 non_mder=25620 frames=40/40 frame_rows=32492 ",
  "registry=MDER_only scientific=65/65 checks=20/20 R=4.6.1"
)
checker_execution <- data.frame(
  invocation_count = 1L,
  exit_code = checker_status,
  expected_output_present = any(grepl(
    checker_expected_line,
    checker_output,
    fixed = TRUE
  )),
  checker_sha256_before = checker_sha_before,
  checker_sha256_after = sha256_file(checker_path),
  status = "PASS",
  stringsAsFactors = FALSE
)
checker_execution$status <- ifelse(
  checker_execution$exit_code == 0L &
    checker_execution$expected_output_present &
    checker_execution$checker_sha256_before == checker_execution$checker_sha256_after &
    checker_execution$checker_sha256_after ==
      "4671036544a7ad9104eec432c829788f9cbb0486b5dd4ee06841552e5d3bef37",
  "PASS",
  "FAIL"
)
write_evidence(checker_execution, "scientific_scope_checker_execution.csv")

scope_audit <- read.csv(
  file.path(
    root,
    "audit/report_harmonization/report018_h09_order57_scientific_scope_audit.csv"
  ),
  check.names = FALSE
)
frame_audit <- read.csv(
  file.path(
    root,
    "audit/report_harmonization/report018_h09_order57_gap_frame_identity.csv"
  ),
  check.names = FALSE
)
scientific_audit <- read.csv(
  file.path(
    root,
    "audit/report_harmonization/report018_h09_order57_scientific_identity_audit.csv"
  ),
  check.names = FALSE
)
registry_audit <- read.csv(
  file.path(
    root,
    "audit/report_harmonization/report018_h09_order57_registry_transition_audit.csv"
  ),
  check.names = FALSE
)
gap_evidence <- read.csv(
  file.path(
    root,
    "audit/reconciliation/mder_METRIC-010_gap_repair/gap_repair_evidence_manifest.csv"
  ),
  check.names = FALSE
)
add_check(
  "scientific scope",
  "unchanged durable scope checker",
  paste(
    checker_execution$status,
    sum(scope_audit$status == "PASS"),
    sum(frame_audit$status == "PASS"),
    sum(frame_audit$current_rows),
    sum(scientific_audit$classification == "LIVE_EXACT"),
    sum(scientific_audit$classification == "ORDER56_ACCEPTED_DISPLAY_TRANSITION"),
    nrow(registry_audit),
    sum(gap_evidence$status == "PASS"),
    sep = "/"
  ),
  "PASS/20/40/32492/57/8/8/7",
  checker_execution$status == "PASS" && nrow(scope_audit) == 20L &&
    all(scope_audit$status == "PASS") && nrow(frame_audit) == 40L &&
    all(frame_audit$status == "PASS") && sum(frame_audit$current_rows) == 32492L &&
    nrow(scientific_audit) == 65L &&
    sum(scientific_audit$classification == "LIVE_EXACT") == 57L &&
    sum(scientific_audit$classification ==
      "ORDER56_ACCEPTED_DISPLAY_TRANSITION") == 8L &&
    nrow(registry_audit) == 8L && all(registry_audit$status == "PASS") &&
    nrow(gap_evidence) == 7L && all(gap_evidence$status == "PASS")
)

dispatch_after_checker <- dispatch
dispatch_after_files <- dispatch_observed_path
dispatch_after_checker$observed_sha256_after_checker <- vapply(
  dispatch_after_files,
  sha256_file,
  character(1)
)
dispatch_after_checker$observed_bytes_after_checker <- file_bytes(
  dispatch_after_files
)
dispatch_after_checker$status_after_checker <- ifelse(
  dispatch_after_checker$observed_sha256_after_checker == dispatch_after_checker$sha256 &
    dispatch_after_checker$observed_bytes_after_checker ==
      as.numeric(dispatch_after_checker$bytes),
  "PASS",
  "FAIL"
)
write_evidence(
  dispatch_after_checker,
  "dispatch_reconciliation_after_scope_checker.csv"
)
add_check(
  "scientific scope",
  "checker outputs reproduce dispatch identities",
  sum(dispatch_after_checker$status_after_checker == "PASS"),
  49L,
  all(dispatch_after_checker$status_after_checker == "PASS")
)

qmd_rel <- "audit/hypotheses/H09/H09_analysis_preparation.qmd"
qmd_path <- file.path(root, qmd_rel)
qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd_text_lines <- paste(qmd_lines, collapse = "\n")
chunks <- extract_executable_r_chunks(qmd_lines)
chunk_parse <- vapply(
  chunks,
  function(chunk) !inherits(try(parse(text = chunk), silent = TRUE), "try-error"),
  logical(1)
)
write_evidence(
  data.frame(
    chunk = seq_along(chunks),
    parse_status = ifelse(chunk_parse, "PASS", "FAIL")
  ),
  "source_chunk_audit_prerender.csv"
)

expected_tables <- c(
  "tbl-h09-prep-input-identities",
  "tbl-h09-prep-integrity-checks",
  "tbl-h09-prep-score-audit",
  "tbl-h09-prep-predictor-contract",
  "tbl-h09-prep-metric-contract",
  "tbl-h09-prep-primary-samples",
  "tbl-h09-prep-common-samples",
  "tbl-h09-prep-primary-formulas",
  "tbl-h09-prep-sensitivity-formulas",
  "tbl-h09-prep-families",
  "tbl-h09-prep-diagnostic-summary",
  "tbl-h09-prep-sensitivity-map",
  "tbl-h09-prep-boundary",
  "tbl-h09-prep-intermediate-artifacts",
  "tbl-h09-prep-code-map",
  "tbl-h09-prep-script-map",
  "tbl-h09-prep-reader-manifest-check",
  "tbl-h09-prep-key-output-identities",
  "tbl-h09-prep-execution"
)
tables <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: tbl-h09-", qmd_lines, value = TRUE)
)
figures <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: fig-h09-", qmd_lines, value = TRUE)
)
mermaid <- sum(trimws(qmd_lines) == "flowchart TD")
write_evidence(
  data.frame(
    type = c(rep("table", length(tables)), rep("figure", length(figures))),
    source_order = seq_len(length(tables) + length(figures)),
    endpoint = c(tables, figures),
    status = "PASS"
  ),
  "source_endpoint_contract_prerender.csv"
)

calls <- executable_r_call_names(qmd_lines)
forbidden_calls <- c(
  "mgcv::gam", "mgcv::bam", "gam", "bam", "lme4::lmer", "lmer",
  "glmmTMB::glmmTMB", "glmmTMB", "nlme::lme", "lme",
  "stats::predict", "predict", "stats::simulate", "simulate",
  "boot::boot", "boot", "emmeans::emmeans", "emmeans",
  "h09_fit_model", "h09_fit_bundle", "h09_fit_models",
  "h09_model_diagnostics", "h09_residual_diagnostics",
  "h09_leave_one_site_out", "h09_participant_influence",
  "h09_photoperiod_sensitivity", "h09_participant_summary_sensitivity",
  "h09_ar1_sensitivity"
)
forbidden_observed <- intersect(calls, forbidden_calls)
write_evidence(
  data.frame(
    prohibited_call = forbidden_calls,
    observed = forbidden_calls %in% forbidden_observed,
    status = ifelse(forbidden_calls %in% forbidden_observed, "FAIL", "PASS")
  ),
  "source_prohibited_call_audit_prerender.csv"
)

relative_matches <- gregexpr(
  "\\]\\((\\.\\./[^)]+)\\)",
  qmd_text_lines,
  perl = TRUE
)
relative_values <- regmatches(qmd_text_lines, relative_matches)[[1L]]
relative_targets <- sub("^\\]\\(", "", relative_values)
relative_targets <- sub("\\)$", "", relative_targets)
relative_files <- sub("#.*$", "", relative_targets)
relative_fragments <- ifelse(
  grepl("#", relative_targets, fixed = TRUE),
  sub("^[^#]*#", "", relative_targets),
  ""
)
resolved_targets <- file.path(dirname(qmd_path), relative_files)
link_audit <- data.frame(
  occurrence = seq_along(relative_targets),
  target = relative_targets,
  file = relative_files,
  fragment = relative_fragments,
  resolves = file.exists(resolved_targets),
  stringsAsFactors = FALSE
)
link_audit$status <- ifelse(link_audit$resolves, "PASS", "FAIL")
write_evidence(link_audit, "source_reader_targets_prerender.csv")
expected_dynamic_links <- c(
  "../../../notebooks/hypotheses/H09.qmd",
  "../../../notebooks/hypotheses/H09.qmd#h09-preregistration-deviations"
)
dynamic_links <- grep(
  "^../../../notebooks/hypotheses/H09\\.qmd",
  relative_targets,
  value = TRUE
)
add_check(
  "source",
  "chunks, endpoints, Mermaid, links, and prohibited calls",
  paste(
    sum(chunk_parse), length(chunks), length(tables), length(figures),
    mermaid, length(relative_targets), length(unique(relative_targets)),
    length(forbidden_observed),
    sep = "/"
  ),
  "22/22/19/1/1/23/22/0",
  length(chunks) == 22L && all(chunk_parse) &&
    identical(tables, expected_tables) &&
    identical(figures, "fig-h09-prep-sample-support") &&
    mermaid == 1L && length(relative_targets) == 23L &&
    length(unique(relative_targets)) == 22L && all(link_audit$resolves) &&
    setequal(dynamic_links, expected_dynamic_links) &&
    length(forbidden_observed) == 0L
)

manifest_rel <- "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv"
manifest <- read.csv(file.path(root, manifest_rel), check.names = FALSE)
manifest_files <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_size <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- vapply(
  manifest_files[manifest_exists],
  sha256_file,
  character(1)
)
manifest_size[manifest_exists] <- file_bytes(manifest_files[manifest_exists])
manifest_exact <- manifest_exists & manifest_sha == manifest$sha256 &
  manifest_size == as.numeric(manifest$bytes)
expected_mismatches <- c(
  "scripts/hypotheses/H09/h09_contract.R",
  "scripts/hypotheses/H09/run_h09_stage2.R",
  "audit/decisions/figure_readability_and_layout.md",
  "_quarto-nathealth.yml",
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "artifacts/10_figures/H09/H09_diagnostics_chest.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_chest.png",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.png",
  "artifacts/10_figures/H09/H09_paired_placement_effects.pdf",
  "artifacts/10_figures/H09/H09_paired_placement_effects.png",
  "artifacts/10_figures/H09/H09_primary_effects.pdf",
  "artifacts/10_figures/H09/H09_primary_effects.png",
  "artifacts/12_manifests/H09/H09_figure_manifest.csv",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "notebooks/hypotheses/H09.qmd",
  "config/metric_display_registry.csv",
  "artifacts/06_model_data/H09/H09_base_bundle_audit.csv",
  "artifacts/06_model_data/H09/H09_input_audit.csv"
)
manifest_audit <- transform(
  manifest,
  observed_sha256 = manifest_sha,
  observed_bytes = manifest_size,
  status = ifelse(manifest_exact, "LIVE_EXACT", "HISTORICAL_TRANSITION")
)
write_evidence(manifest_audit, "preparation_manifest_audit_prerender.csv")
write_evidence(
  manifest_audit[!manifest_exact, , drop = FALSE],
  "preparation_manifest_historical_transitions_prerender.csv"
)
add_check(
  "manifest",
  "historical preparation manifest",
  paste(sum(manifest_exact), sum(!manifest_exact), sep = "/"),
  "113/19 exact accepted path set",
  nrow(manifest) == 132L && !anyDuplicated(manifest$path) &&
    sum(manifest_exact) == 113L &&
    setequal(manifest$path[!manifest_exact], expected_mismatches)
)

source_support_root <- file.path(
  root,
  "audit/hypotheses/H09/H09_analysis_preparation_files"
)
source_support <- inventory_paths(
  list_files(source_support_root),
  "historical_source_side_support"
)
write_evidence(source_support, "source_side_support_tree_prerender.csv")
add_check(
  "history",
  "historical source-side support",
  nrow(source_support),
  16L,
  nrow(source_support) == 16L && !any(source_support$is_symlink)
)

build_root <- file.path(root, "_build/nathealth")
build_files <- list_files(build_root)
build_inventory <- inventory_paths(build_files, "build_member")
write_evidence(build_inventory, "build_inventory_prerender.csv")
build_entries <- list.files(
  build_root,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
build_symlinks <- build_entries[nzchar(Sys.readlink(build_entries))]
write_evidence(
  data.frame(
    relative_path = relative_path(build_symlinks),
    symlink_target = Sys.readlink(build_symlinks)
  ),
  "build_symlink_inventory_prerender.csv"
)
add_check(
  "build",
  "build files and symlinks",
  paste(length(build_files), length(build_symlinks), sep = "/"),
  "851/0",
  length(build_files) == 851L && length(build_symlinks) == 0L
)

h09_roots <- file.path(root, c(
  "artifacts/06_model_data/H09",
  "artifacts/07_models/H09",
  "artifacts/08_diagnostics/H09",
  "artifacts/09_tables/H09",
  "artifacts/10_figures/H09",
  "artifacts/11_source_data/H09",
  "artifacts/12_manifests/H09",
  "audit/hypotheses/H09",
  "scripts/hypotheses/H09",
  "tests/hypotheses/H09"
))
h09_paths <- unlist(lapply(h09_roots, list_files), use.names = FALSE)
handoff_paths <- list.files(
  file.path(root, "audit/handoffs"),
  pattern = "^H09.*[.](md|csv)$",
  full.names = TRUE
)
decision_paths <- file.path(root, c(
  "audit/decisions/answer_in_brief_callout.md",
  "audit/decisions/bootstrap_execution_policy.md",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/gap_timing_unaware_dataset_terminology.md",
  "audit/decisions/hypothesis_preparation_provenance_companions.md",
  "audit/decisions/model_reporting.md",
  "audit/decisions/p_value_display_conventions.md",
  "audit/decisions/paired_placement_comparison_display.md",
  "audit/decisions/placement_decision.md",
  "audit/decisions/reader_facing_symlog_scale.md",
  "audit/decisions/site_display_conventions.md",
  "audit/decisions/l10_numerical_zero_normalization.md",
  "audit/decisions/mder_mean_of_viable_ratios.md"
))
ledger_paths <- list_files(file.path(root, "audit/ledgers"))
dispatch_paths <- file.path(root, dispatch$path)
protected_paths <- sort(unique(c(
  h09_paths, handoff_paths, decision_paths, ledger_paths, dispatch_paths,
  file.path(root, c(
    "notebooks/hypotheses/H09.qmd",
    "_build/nathealth/notebooks/hypotheses/H09.html",
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd",
    "_quarto-nathealth.yml", "_quarto.yml",
    "scripts/report_harmonization/post_render_gt_html_semantics.R",
    "scripts/report_harmonization/repair_gt_html_semantics.R",
    "scripts/pipeline/paths_io.R",
    "scripts/pipeline/p_value_display.R",
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
    "config/metric_display_registry.csv", "config/site_display_registry.csv",
    "audit/evidence/preregistration_contract.md",
    "audit/hypotheses/H03-H11_gated_workflow.qmd",
    "audit/hypotheses/H09-H11_migration_map.md",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "audit/report_harmonization/phase4_gt_source_audit.csv",
    "audit/report_harmonization/deviation_link_plan.csv",
    "notebooks/preregistration_deviations.qmd",
    "_build/nathealth/supplementary_information.html",
    "renv.lock"
  ))
)))
protected_exists <- file.exists(protected_paths) & !dir.exists(protected_paths)
write_evidence(
  data.frame(
    relative_path = relative_path(protected_paths[!protected_exists]),
    status = rep("MISSING", sum(!protected_exists))
  ),
  "protected_missing_prerender.csv"
)
stopifnot(all(protected_exists))
protected_paths <- protected_paths[protected_exists]
protected_relative <- relative_path(protected_paths)
protected_role <- rep("h09_protected", length(protected_paths))
protected_role[startsWith(protected_relative, "audit/ledgers/")] <- "central_ledger"
protected_role[protected_relative %in% dispatch$path] <- "dispatch_contract"
protected_role[protected_relative == matrix_rel] <- "coordination_evidence"
protected_role[
  protected_relative ==
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html"
] <- "expected_companion_render_target"
protected_role[
  protected_relative ==
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd"
] <- "expected_source_identical_build_qmd"
protected_role[
  protected_relative ==
    "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv"
] <- "expected_live_preparation_manifest"
protected_inventory <- inventory_paths(protected_paths, protected_role)
write_evidence(protected_inventory, "protected_inventory_prerender.csv")
add_check(
  "protected",
  "complete H09 protected inventory",
  nrow(protected_inventory),
  "all present regular nonsymlink files",
  nrow(protected_inventory) > 0L && !any(protected_inventory$is_symlink)
)

helper_path <- file.path(
  root,
  "scripts/hypotheses/H09/build_h09_preparation_report_manifest.R"
)
helper_text <- paste(
  readLines(helper_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
helper_contract <- c(
  grepl(
    "if (!file.copy(paths$qmd, paths$rendered_qmd, overwrite = TRUE))",
    gsub("[[:space:]]+", " ", helper_text),
    fixed = TRUE
  ),
  grepl(
    "files <- setdiff(files, output_path)",
    gsub("[[:space:]]+", " ", helper_text),
    fixed = TRUE
  ),
  grepl(
    "write_csv_artifact(inventory, output_path, producer)",
    gsub("[[:space:]]+", " ", helper_text),
    fixed = TRUE
  )
)
add_check(
  "helper",
  "unchanged confined non-circular helper",
  paste(sha256_file(helper_path), sum(helper_contract), sep = "/"),
  paste(
    "c7a320367e0115aee221a3a6ba5228a9a27ba55f734bd07881455b3159cebf56",
    3,
    sep = "/"
  ),
  sha256_file(helper_path) ==
    "c7a320367e0115aee221a3a6ba5228a9a27ba55f734bd07881455b3159cebf56" &&
    all(helper_contract)
)

preparation_assets <- list_files(file.path(
  root,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation_files"
))
helper_h09_files <- unlist(lapply(h09_roots, list_files), use.names = FALSE)
helper_decisions <- file.path(root, c(
  "audit/decisions/answer_in_brief_callout.md",
  "audit/decisions/bootstrap_execution_policy.md",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/gap_timing_unaware_dataset_terminology.md",
  "audit/decisions/hypothesis_preparation_provenance_companions.md",
  "audit/decisions/model_reporting.md",
  "audit/decisions/p_value_display_conventions.md",
  "audit/decisions/paired_placement_comparison_display.md",
  "audit/decisions/placement_decision.md",
  "audit/decisions/reader_facing_symlog_scale.md",
  "audit/decisions/site_display_conventions.md"
))
helper_support <- file.path(root, c(
  "AGENTS.md", "renv.lock", "_quarto.yml", "_quarto-nathealth.yml",
  "notebooks/hypotheses/H09.qmd",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "config/metric_display_registry.csv", "config/site_display_registry.csv",
  "audit/evidence/preregistration_contract.md",
  "audit/hypotheses/H03-H11_gated_workflow.qmd",
  "audit/hypotheses/H09-H11_migration_map.md",
  "scripts/pipeline/paths_io.R", "scripts/pipeline/p_value_display.R",
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))
predicted_files <- unique(c(
  file.path(root, qmd_rel),
  file.path(root, "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html"),
  file.path(root, "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd"),
  file.path(root, "notebooks/hypotheses/H09.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H09.html"),
  file.path(root, "_quarto-nathealth.yml"),
  helper_h09_files,
  preparation_assets,
  helper_decisions,
  helper_support
))
predicted_files <- predicted_files[
  !grepl(
    "audit/handoffs/H09_(?:worker_handoff|shared_change_request)\\.md$",
    predicted_files,
    perl = TRUE
  )
]
predicted_files <- setdiff(
  predicted_files,
  file.path(root, manifest_rel)
)
predicted_files <- predicted_files[
  file.exists(predicted_files) & !dir.exists(predicted_files)
]
predicted_relative <- substring(
  sort(unique(normalizePath(
    predicted_files,
    winslash = "/",
    mustWork = TRUE
  ))),
  nchar(root) + 2L
)
write_evidence(
  data.frame(path = predicted_relative, status = "PROSPECTIVE_MEMBER"),
  "prospective_helper_inventory_prerender.csv"
)
add_check(
  "helper",
  "prospective helper inventory",
  paste(length(predicted_relative), length(preparation_assets), sep = "/"),
  "495/0 before render, then 496 after one target-owned figure",
  length(predicted_relative) == 495L && length(preparation_assets) == 0L &&
    !anyDuplicated(predicted_relative) && !manifest_rel %in% predicted_relative
)

profile_lines <- trimws(readLines(
  file.path(root, "_quarto-nathealth.yml"),
  warn = FALSE,
  encoding = "UTF-8"
))
result_profile_index <- which(profile_lines == "- notebooks/hypotheses/H09.qmd")
companion_profile_index <- which(
  profile_lines == "- audit/hypotheses/H09/H09_analysis_preparation.qmd"
)
add_check(
  "profile",
  "result and companion adjacency",
  paste(result_profile_index, companion_profile_index, sep = "/"),
  "single adjacent entries",
  length(result_profile_index) == 1L && length(companion_profile_index) == 1L &&
    companion_profile_index == result_profile_index + 1L
)

process_probe <- read.csv(
  file.path(working_dir, "process_probe_prerender.csv"),
  check.names = FALSE
)
add_check(
  "process",
  "no competing task process",
  sum(process_probe$status == "PASS"),
  nrow(process_probe),
  nrow(process_probe) == 1L && all(process_probe$status == "PASS")
)

semantic_status <- data.frame(
  path = semantic_dir,
  absolute = startsWith(semantic_dir, "/"),
  outside_project = !startsWith(semantic_dir, paste0(root, "/")),
  entries = length(list.files(semantic_dir, all.files = TRUE, no.. = TRUE)),
  status = "PASS",
  stringsAsFactors = FALSE
)
semantic_status$status <- ifelse(
  semantic_status$absolute & semantic_status$outside_project &
    semantic_status$entries == 0L,
  "PASS",
  "FAIL"
)
write_evidence(semantic_status, "semantic_directory_prerender.csv")
add_check(
  "environment",
  "fresh external semantic directory",
  paste(semantic_status$outside_project, semantic_status$entries, sep = "/"),
  "TRUE/0",
  semantic_status$status == "PASS"
)

quarto_version <- trimws(system2("quarto", "--version", stdout = TRUE))
versions <- data.frame(
  component = c("R", "digest", "dplyr", "Quarto"),
  version = c(
    as.character(getRversion()),
    as.character(packageVersion("digest")),
    as.character(packageVersion("dplyr")),
    quarto_version[[1L]]
  ),
  expected = c("4.6.1", "0.6.39", "1.2.1", "1.9.37"),
  stringsAsFactors = FALSE
)
versions$status <- ifelse(versions$version == versions$expected, "PASS", "FAIL")
write_evidence(versions, "versions_prerender.csv")
add_check(
  "environment",
  "authoritative software versions",
  paste(versions$version, collapse = "/"),
  paste(versions$expected, collapse = "/"),
  all(versions$status == "PASS")
)

write_evidence(checks, "preflight_summary.csv")
if (any(checks$status != "PASS")) {
  print(checks[checks$status != "PASS", , drop = FALSE])
  stop("Order 57a complete preflight failed", call. = FALSE)
}

cat(sprintf(
  paste0(
    "H09_ORDER57A_PRERENDER=PASS checks=%d/%d dispatch=49/49 acceptance=30/30 ",
    "stop=45/45 postimages=3/3 reversals=3/3 inputs=16/16 results=11/11 ",
    "scope=20/20 non_mder=25620 frames=40/40 frame_rows=32492 ",
    "scientific=57+8 chunks=22/22 tables=19 figure=1 mermaid=1 links=23/22 ",
    "manifest=113/132+19 prospective=495->496 build=851 symlinks=0 ",
    "support=16 protected=%d processes=0 R=%s quarto=%s\n"
  ),
  nrow(checks),
  nrow(checks),
  nrow(protected_inventory),
  as.character(getRversion()),
  quarto_version[[1L]]
))
