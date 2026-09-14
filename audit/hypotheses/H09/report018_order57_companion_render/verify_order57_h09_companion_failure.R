#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 57 verifier requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages(library(digest))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_rel <-
  "audit/hypotheses/H09/report018_order57_companion_render"
evidence_dir <- file.path(root, evidence_rel)
setwd(root)

stopifnot(dir.exists(evidence_dir))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) unname(file.info(path)$size)

read_evidence <- function(name) {
  read.csv(file.path(evidence_dir, name), check.names = FALSE)
}

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
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

required_evidence <- c(
  "ORDER57_FAIL_CLOSED.md",
  "preflight_summary.csv",
  "dispatch_hard_pin_audit_prerender.csv",
  "release_manifest_audit_prerender.csv",
  "release_pins_audit_prerender.csv",
  "result_acceptance_audit_prerender.csv",
  "source_chunk_audit_prerender.csv",
  "source_endpoint_contract_prerender.csv",
  "source_prohibited_call_audit_prerender.csv",
  "source_reader_targets_prerender.csv",
  "preparation_manifest_audit_prerender.csv",
  "preparation_manifest_historical_transitions_prerender.csv",
  "build_inventory_prerender.csv",
  "protected_inventory_prerender.csv",
  "source_side_support_tree_prerender.csv",
  "process_probe_prerender.csv",
  "render_execution.csv",
  "render_console.log",
  "render_input_identity_diagnostic.csv",
  "render_input_identity_mismatches.csv",
  "failure_capture_checks.csv",
  "build_inventory_postfailure.csv",
  "build_reconciliation_postfailure.csv",
  "protected_inventory_postfailure.csv",
  "protected_reconciliation_postfailure.csv",
  "source_side_support_tree_postfailure.csv",
  "source_side_support_reconciliation_postfailure.csv",
  "semantic_directory_postfailure.csv",
  "historical_tests_postfailure.csv",
  "frozen_endpoints_postfailure.csv",
  "process_probe_postfailure.csv",
  "sass_cache_inventory_before.csv",
  "sass_cache_inventory_after.csv",
  "capture_order57_preflight.R",
  "capture_order57_failure.R",
  "verify_order57_h09_companion_failure.R"
)
required_paths <- file.path(evidence_dir, required_evidence)
add_check(
  "evidence",
  "required fail-closed evidence present",
  sum(file.exists(required_paths) & !dir.exists(required_paths)),
  length(required_paths),
  all(file.exists(required_paths) & !dir.exists(required_paths))
)

preflight <- read_evidence("preflight_summary.csv")
add_check(
  "preflight",
  "complete pre-render gate",
  paste(sum(preflight$status == "PASS"), nrow(preflight), sep = "/"),
  "18/18",
  nrow(preflight) == 18L && all(preflight$status == "PASS")
)

dispatch <- read_evidence("dispatch_hard_pin_audit_prerender.csv")
release <- read_evidence("release_manifest_audit_prerender.csv")
pins <- read_evidence("release_pins_audit_prerender.csv")
result <- read_evidence("result_acceptance_audit_prerender.csv")
add_check(
  "preflight",
  "sealed authority and result identities",
  paste(
    sum(dispatch$status == "PASS"),
    sum(release$status == "PASS"),
    sum(pins$status == "PASS"),
    sum(result$status == "PASS"),
    sep = "/"
  ),
  "8/25/34/37",
  nrow(dispatch) == 8L && all(dispatch$status == "PASS") &&
    nrow(release) == 25L && all(release$status == "PASS") &&
    nrow(pins) == 34L && all(pins$status == "PASS") &&
    nrow(result) == 37L && all(result$status == "PASS")
)

chunks <- read_evidence("source_chunk_audit_prerender.csv")
endpoints <- read_evidence("source_endpoint_contract_prerender.csv")
prohibited <- read_evidence("source_prohibited_call_audit_prerender.csv")
links <- read_evidence("source_reader_targets_prerender.csv")
add_check(
  "preflight",
  "source structure and prohibited-call gate",
  paste(
    nrow(chunks),
    sum(endpoints$type == "table"),
    sum(endpoints$type == "figure"),
    nrow(links),
    length(unique(links$target)),
    sum(prohibited$observed),
    sep = "/"
  ),
  "22/19/1/23/22/0",
  nrow(chunks) == 22L && all(chunks$parse_status == "PASS") &&
    sum(endpoints$type == "table") == 19L &&
    sum(endpoints$type == "figure") == 1L &&
    all(endpoints$status == "PASS") &&
    nrow(links) == 23L && length(unique(links$target)) == 22L &&
    all(links$status == "PASS") && !any(prohibited$observed)
)

historical_manifest <- read_evidence("preparation_manifest_audit_prerender.csv")
historical_transitions <- read_evidence(
  "preparation_manifest_historical_transitions_prerender.csv"
)
add_check(
  "preflight",
  "historical preparation-manifest classification",
  paste(
    sum(historical_manifest$status == "LIVE_EXACT"),
    nrow(historical_transitions),
    sep = "/"
  ),
  "113/19",
  nrow(historical_manifest) == 132L &&
    sum(historical_manifest$status == "LIVE_EXACT") == 113L &&
    nrow(historical_transitions) == 19L
)

render <- read_evidence("render_execution.csv")
render_value <- setNames(as.character(render$value), render$field)
console <- paste(
  readLines(file.path(evidence_dir, "render_console.log"), warn = FALSE),
  collapse = "\n"
)
add_check(
  "execution",
  "sole render failed at bounded input identity gate",
  paste(
    render_value[["invocation_count"]],
    render_value[["exit_code"]],
    render_value[["retry_count"]],
    render_value[["helper_invocation_count"]],
    sep = "/"
  ),
  "1/1/0/0",
  identical(render_value[["invocation_count"]], "1") &&
    identical(render_value[["exit_code"]], "1") &&
    identical(render_value[["retry_count"]], "0") &&
    identical(render_value[["helper_invocation_count"]], "0") &&
    grepl(
      "all(verified_inputs$Verified == \"PASS\") is not TRUE",
      console,
      fixed = TRUE
    ) &&
    grepl("tbl-h09-prep-input-identities", console, fixed = TRUE)
)

mismatches <- read_evidence("render_input_identity_mismatches.csv")
expected_mismatches <- data.frame(
  input_role = c(
    "gap_timing_unaware_metrics",
    "gap_manifest",
    "metric_display_registry"
  ),
  path = c(
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds",
    "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
    "config/metric_display_registry.csv"
  ),
  recorded_sha256 = c(
    "28266064c6213eae6046ec6469d0dae39529f56e60933dcd581cf96c8590e1a4",
    "af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267",
    "6c0adc3ca061ac49591d71243dd7ff0693311eb1f499836cf52c2742328b8154"
  ),
  current_sha256 = c(
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
    "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
    "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0"
  ),
  recorded_bytes = c(88760, 3970, 3182),
  current_bytes = c(88248, 4497, 3203),
  stringsAsFactors = FALSE
)
mismatch_match <- merge(
  mismatches,
  expected_mismatches,
  by = c("input_role", "path"),
  all = TRUE
)
live_paths <- file.path(root, expected_mismatches$path)
live_sha <- vapply(live_paths, sha256_file, character(1))
live_bytes <- file_bytes(live_paths)
add_check(
  "failure",
  "exact upstream identity discrepancy",
  paste(sort(mismatches$input_role), collapse = "|"),
  paste(sort(expected_mismatches$input_role), collapse = "|"),
  nrow(mismatches) == 3L && nrow(mismatch_match) == 3L &&
    all(mismatch_match$observed_sha256 == mismatch_match$recorded_sha256) &&
    all(mismatch_match$current_sha256.x == mismatch_match$current_sha256.y) &&
    all(as.numeric(mismatch_match$bytes) == mismatch_match$recorded_bytes) &&
    all(as.numeric(mismatch_match$current_bytes.x) == mismatch_match$current_bytes.y) &&
    identical(unname(live_sha), expected_mismatches$current_sha256) &&
    identical(as.numeric(live_bytes), expected_mismatches$current_bytes)
)

reconcile_live <- function(inventory_name, root_prefix = root) {
  before <- read_evidence(inventory_name)
  paths <- file.path(root_prefix, before$relative_path)
  exists <- file.exists(paths) & !dir.exists(paths)
  live_sha <- rep(NA_character_, length(paths))
  live_bytes <- rep(NA_real_, length(paths))
  live_sha[exists] <- vapply(paths[exists], sha256_file, character(1))
  live_bytes[exists] <- file_bytes(paths[exists])
  data.frame(
    relative_path = before$relative_path,
    expected_sha256 = before$sha256,
    observed_sha256 = live_sha,
    expected_bytes = before$bytes,
    observed_bytes = live_bytes,
    status = ifelse(
      exists & live_sha == before$sha256 & live_bytes == as.numeric(before$bytes),
      "UNCHANGED",
      "MISMATCH"
    ),
    stringsAsFactors = FALSE
  )
}

build_live <- reconcile_live("build_inventory_prerender.csv")
add_check(
  "preservation",
  "build unchanged after stopped render",
  paste(sum(build_live$status == "UNCHANGED"), nrow(build_live), sep = "/"),
  "851/851",
  nrow(build_live) == 851L && all(build_live$status == "UNCHANGED")
)

protected_live <- reconcile_live("protected_inventory_prerender.csv")
matrix_row <-
  protected_live$relative_path == "audit/report_harmonization/coordination_matrix.csv"
add_check(
  "preservation",
  "protected scope unchanged after stopped render",
  paste(
    sum(protected_live$status[!matrix_row] == "UNCHANGED"),
    sum(!matrix_row),
    sep = "/"
  ),
  "all non-matrix protected rows unchanged",
  all(protected_live$status[!matrix_row] == "UNCHANGED")
)

support_live <- reconcile_live("source_side_support_tree_prerender.csv")
add_check(
  "preservation",
  "historical source-side support tree unchanged",
  paste(sum(support_live$status == "UNCHANGED"), nrow(support_live), sep = "/"),
  "16/16",
  nrow(support_live) == 16L && all(support_live$status == "UNCHANGED")
)

semantic <- read_evidence("semantic_directory_postfailure.csv")
tests <- read_evidence("historical_tests_postfailure.csv")
failure_capture <- read_evidence("failure_capture_checks.csv")
process_before <- read_evidence("process_probe_prerender.csv")
process_after <- read_evidence("process_probe_postfailure.csv")
add_check(
  "preservation",
  "semantic, tests, capture, and teardown gates",
  paste(
    nrow(semantic),
    sum(tests$status == "UNCHANGED"),
    sum(failure_capture$status == "PASS"),
    sum(process_before$status == "PASS"),
    sum(process_after$status == "PASS"),
    sep = "/"
  ),
  "0/2/14/2/3",
  nrow(semantic) == 0L && nrow(tests) == 2L &&
    all(tests$status == "UNCHANGED") && nrow(failure_capture) == 14L &&
    all(failure_capture$status == "PASS") &&
    all(process_before$status == "PASS") &&
    all(process_after$status == "PASS")
)

cache_before <- read_evidence("sass_cache_inventory_before.csv")
cache_after <- read_evidence("sass_cache_inventory_after.csv")
add_check(
  "environment",
  "Sass cache unchanged",
  paste(cache_after$sha256, cache_after$bytes, sep = "/"),
  paste(cache_before$sha256, cache_before$bytes, sep = "/"),
  identical(cache_before$sha256, cache_after$sha256) &&
    identical(as.numeric(cache_before$bytes), as.numeric(cache_after$bytes))
)

frozen <- read_evidence("frozen_endpoints_postfailure.csv")
expected_frozen <- c(
  "scripts/hypotheses/H09/build_h09_preparation_report_manifest.R" =
    "c7a320367e0115aee221a3a6ba5228a9a27ba55f734bd07881455b3159cebf56",
  "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv" =
    "8e1d633262b33df64e45f0fc3fd677f4bb1e8a69120cb76a9b152509b94f0aaf",
  "audit/hypotheses/H09/H09_analysis_preparation.qmd" =
    "7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd" =
    "4640129c38a5aabd874549ff8d5ebc74b736a16fe6f900f4654b1573b2b69f5c",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html" =
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
  "audit/hypotheses/H09/H09_analysis_preparation.html" =
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05"
)
observed_frozen <- setNames(frozen$sha256, frozen$path)
add_check(
  "preservation",
  "helper, manifest, source, and held outputs exact",
  sum(observed_frozen[names(expected_frozen)] == expected_frozen),
  length(expected_frozen),
  all(observed_frozen[names(expected_frozen)] == expected_frozen)
)

add_check(
  "boundary",
  "conditional postrender actions correctly withheld",
  "helper 0; browser QA 0; retry 0",
  "helper 0; browser QA 0; retry 0",
  identical(render_value[["helper_invocation_count"]], "0") &&
    identical(render_value[["retry_count"]], "0")
)

checks$r_version <- as.character(getRversion())
checks$digest_version <- as.character(utils::packageVersion("digest"))
write_evidence(checks, "order57_failure_verification.csv")

if (any(checks$status != "PASS")) {
  print(checks[checks$status != "PASS", , drop = FALSE])
  stop("Order 57 fail-closed verification failed", call. = FALSE)
}

manifest_name <- "order57_fail_closed_evidence_manifest.csv"
manifest_path <- file.path(evidence_dir, manifest_name)
evidence_files <- list.files(
  evidence_dir,
  all.files = TRUE,
  full.names = TRUE,
  recursive = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
)
evidence_files <- evidence_files[
  normalizePath(evidence_files, winslash = "/", mustWork = FALSE) !=
    normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
]
evidence_files <- sort(unique(evidence_files))
manifest <- data.frame(
  path = file.path(
    evidence_rel,
    substring(evidence_files, nchar(evidence_dir) + 2L)
  ),
  sha256 = vapply(evidence_files, sha256_file, character(1)),
  bytes = file_bytes(evidence_files),
  role = ifelse(
    basename(evidence_files) == "ORDER57_FAIL_CLOSED.md",
    "consolidated fail-closed record",
    ifelse(
      grepl("verify_order57", basename(evidence_files), fixed = TRUE),
      "new order-specific verifier",
      "order 57 fail-closed evidence"
    )
  ),
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(manifest) > 0L,
  !anyDuplicated(manifest$path),
  !any(manifest$path == file.path(evidence_rel, manifest_name)),
  !any(Sys.readlink(evidence_files) != "")
)
write_evidence(manifest, manifest_name)

sealed <- read_evidence(manifest_name)
sealed_files <- file.path(root, sealed$path)
sealed_exact <- file.exists(sealed_files) & !dir.exists(sealed_files) &
  vapply(sealed_files, sha256_file, character(1)) == sealed$sha256 &
  file_bytes(sealed_files) == as.numeric(sealed$bytes)
stopifnot(
  nrow(sealed) == nrow(manifest),
  !anyDuplicated(sealed$path),
  !any(sealed$path == file.path(evidence_rel, manifest_name)),
  all(sealed_exact)
)

cat(sprintf(
  paste0(
    "H09_ORDER57_FAIL_CLOSED=PASS checks=%d/%d mismatch=3 render=1 ",
    "exit=1 retries=0 helper=0 browser=0 build=851 protected=%d ",
    "support=16 evidence=%d R=%s digest=%s\n"
  ),
  nrow(checks),
  nrow(checks),
  sum(!matrix_row),
  nrow(sealed),
  as.character(getRversion()),
  as.character(utils::packageVersion("digest"))
))
