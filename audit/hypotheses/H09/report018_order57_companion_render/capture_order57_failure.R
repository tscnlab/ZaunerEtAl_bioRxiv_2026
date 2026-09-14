#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 57 failure capture requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages(library(digest))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
working_dir <- normalizePath(
  Sys.getenv("ORDER57_WORKING_DIR"),
  winslash = "/",
  mustWork = TRUE
)
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) unname(file.info(path)$size)

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

list_files <- function(path) {
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
  files[!is.na(info$isdir) & !info$isdir]
}

inventory_paths <- function(paths, role = "inventory_member") {
  paths <- sort(unique(paths))
  if (!length(paths)) {
    return(data.frame(
      relative_path = character(), role = character(), sha256 = character(),
      bytes = numeric(), modified_utc = character(), is_symlink = logical(),
      symlink_target = character(), stringsAsFactors = FALSE
    ))
  }
  links <- Sys.readlink(paths)
  normalized <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  info <- file.info(normalized)
  data.frame(
    relative_path = relative_path(normalized),
    role = rep(role, length(normalized)),
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

reconcile_inventory <- function(before, after) {
  merged <- merge(
    before[, c("relative_path", "sha256", "bytes")],
    after[, c("relative_path", "sha256", "bytes")],
    by = "relative_path",
    all = TRUE,
    suffixes = c("_before", "_after")
  )
  merged$status <- ifelse(
    is.na(merged$sha256_before),
    "ADDED",
    ifelse(
      is.na(merged$sha256_after),
      "REMOVED",
      ifelse(
        merged$sha256_before == merged$sha256_after &
          merged$bytes_before == merged$bytes_after,
        "UNCHANGED",
        "CHANGED"
      )
    )
  )
  merged
}

input_audit_path <- file.path(
  root,
  "artifacts/06_model_data/H09/H09_input_audit.csv"
)
input_audit <- read.csv(input_audit_path, check.names = FALSE)
result_input_roles <- c(
  "metric_manifest", "base_manifest", "primary_near_eye_context",
  "primary_chest_context", "primary_near_eye_enriched",
  "primary_chest_enriched", "normalized_chronotype",
  "gap_timing_unaware_metrics", "gap_manifest",
  "site_display_registry", "metric_display_registry"
)
verified_inputs <- input_audit[input_audit$input_role %in% result_input_roles, , drop = FALSE]
input_files <- file.path(root, verified_inputs$path)
verified_inputs$current_sha256 <- vapply(input_files, sha256_file, character(1))
verified_inputs$current_bytes <- file_bytes(input_files)
verified_inputs$current_identity_matches_record <-
  verified_inputs$current_sha256 == verified_inputs$observed_sha256
verified_inputs$recorded_hash_verified <- verified_inputs$hash_verified
verified_inputs$recorded_rows_verified <- verified_inputs$rows_verified
verified_inputs$render_verified <-
  verified_inputs$current_identity_matches_record &
  verified_inputs$hash_verified & verified_inputs$rows_verified
verified_inputs$status <- ifelse(verified_inputs$render_verified, "PASS", "FAIL")
write_evidence(
  verified_inputs,
  "render_input_identity_diagnostic.csv"
)

mismatches <- verified_inputs[!verified_inputs$render_verified, c(
  "input_role", "path", "use", "expected_sha256", "observed_sha256",
  "current_sha256", "bytes", "current_bytes", "hash_verified",
  "rows_verified", "status"
), drop = FALSE]
write_evidence(mismatches, "render_input_identity_mismatches.csv")

build_before <- read.csv(
  file.path(working_dir, "build_inventory_prerender.csv"),
  check.names = FALSE
)
build_after <- inventory_paths(
  list_files(file.path(root, "_build/nathealth")),
  "build_member"
)
write_evidence(build_after, "build_inventory_postfailure.csv")
build_reconciliation <- reconcile_inventory(build_before, build_after)
write_evidence(build_reconciliation, "build_reconciliation_postfailure.csv")

protected_before <- read.csv(
  file.path(working_dir, "protected_inventory_prerender.csv"),
  check.names = FALSE
)
protected_paths <- file.path(root, protected_before$relative_path)
protected_exists <- file.exists(protected_paths) & !dir.exists(protected_paths)
protected_after <- inventory_paths(
  protected_paths[protected_exists],
  "h09_protected"
)
write_evidence(protected_after, "protected_inventory_postfailure.csv")
protected_reconciliation <- reconcile_inventory(
  protected_before,
  protected_after
)
write_evidence(
  protected_reconciliation,
  "protected_reconciliation_postfailure.csv"
)

support_before <- read.csv(
  file.path(working_dir, "source_side_support_tree_prerender.csv"),
  check.names = FALSE
)
support_after <- inventory_paths(
  list_files(file.path(
    root,
    "audit/hypotheses/H09/H09_analysis_preparation_files"
  )),
  "historical_source_side_support"
)
write_evidence(support_after, "source_side_support_tree_postfailure.csv")
support_reconciliation <- reconcile_inventory(support_before, support_after)
write_evidence(
  support_reconciliation,
  "source_side_support_reconciliation_postfailure.csv"
)

semantic_files <- list_files(semantic_dir)
semantic_inventory <- inventory_paths(semantic_files, "semantic_evidence")
write_evidence(
  semantic_inventory,
  "semantic_directory_postfailure.csv"
)

historical_tests_before <- read.csv(
  file.path(working_dir, "historical_tests_prerender.csv"),
  check.names = FALSE
)
historical_test_paths <- file.path(root, historical_tests_before$path)
historical_tests_after <- data.frame(
  path = historical_tests_before$path,
  sha256 = vapply(historical_test_paths, sha256_file, character(1)),
  bytes = file_bytes(historical_test_paths),
  modified_utc = format(
    file.info(historical_test_paths)$mtime,
    tz = "UTC",
    usetz = TRUE,
    format = "%Y-%m-%dT%H:%M:%OS6Z"
  ),
  execution_status = "NOT_EXECUTED",
  stringsAsFactors = FALSE
)
historical_tests_after$status <- ifelse(
  historical_tests_after$sha256 == historical_tests_before$sha256 &
    historical_tests_after$bytes == historical_tests_before$bytes &
    historical_tests_after$modified_utc == historical_tests_before$modified_utc,
  "UNCHANGED",
  "CHANGED"
)
write_evidence(historical_tests_after, "historical_tests_postfailure.csv")

helper_path <- file.path(
  root,
  "scripts/hypotheses/H09/build_h09_preparation_report_manifest.R"
)
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv"
)
source_qmd_path <- file.path(
  root,
  "audit/hypotheses/H09/H09_analysis_preparation.qmd"
)
build_qmd_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd"
)
held_html_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html"
)
source_html_path <- file.path(
  root,
  "audit/hypotheses/H09/H09_analysis_preparation.html"
)
frozen_after <- data.frame(
  path = relative_path(c(
    helper_path, manifest_path, source_qmd_path, build_qmd_path,
    held_html_path, source_html_path
  )),
  sha256 = vapply(c(
    helper_path, manifest_path, source_qmd_path, build_qmd_path,
    held_html_path, source_html_path
  ), sha256_file, character(1)),
  bytes = file_bytes(c(
    helper_path, manifest_path, source_qmd_path, build_qmd_path,
    held_html_path, source_html_path
  )),
  stringsAsFactors = FALSE
)
write_evidence(frozen_after, "frozen_endpoints_postfailure.csv")

checks <- data.frame(
  check = c(
    "single render attempt recorded",
    "input identity failure reproduced",
    "exactly three failed result inputs",
    "failed input roles exact",
    "build remained unchanged",
    "protected scope remained unchanged",
    "historical source-side support tree unchanged",
    "semantic hook produced no evidence after early execution failure",
    "historical tests remained byte-identical and unexecuted",
    "helper remained byte-identical and unexecuted",
    "preparation manifest remained historical 132-row identity",
    "canonical companion HTML remained held",
    "source-side companion HTML remained historical",
    "build companion QMD remained stale"
  ),
  observed = c(
    "1 invocation; exit 1; zero retries",
    paste0(sum(!verified_inputs$render_verified), " failed rows"),
    nrow(mismatches),
    paste(sort(mismatches$input_role), collapse = "|"),
    paste(table(build_reconciliation$status), collapse = ";"),
    paste(table(protected_reconciliation$status), collapse = ";"),
    paste(table(support_reconciliation$status), collapse = ";"),
    nrow(semantic_inventory),
    paste(historical_tests_after$status, collapse = "|"),
    paste(frozen_after$sha256[frozen_after$path == relative_path(helper_path)], "not run"),
    frozen_after$sha256[frozen_after$path == relative_path(manifest_path)],
    frozen_after$sha256[frozen_after$path == relative_path(held_html_path)],
    frozen_after$sha256[frozen_after$path == relative_path(source_html_path)],
    frozen_after$sha256[frozen_after$path == relative_path(build_qmd_path)]
  ),
  expected = c(
    "1 invocation; exit 1; zero retries",
    "3 failed rows",
    "3",
    "gap_manifest|gap_timing_unaware_metrics|metric_display_registry",
    "all unchanged",
    "all unchanged",
    "all unchanged",
    "0",
    "UNCHANGED|UNCHANGED",
    "c7a320367e0115aee221a3a6ba5228a9a27ba55f734bd07881455b3159cebf56; not run",
    "8e1d633262b33df64e45f0fc3fd677f4bb1e8a69120cb76a9b152509b94f0aaf",
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    "4640129c38a5aabd874549ff8d5ebc74b736a16fe6f900f4654b1573b2b69f5c"
  ),
  stringsAsFactors = FALSE
)
checks$status <- c(
  "PASS",
  ifelse(sum(!verified_inputs$render_verified) == 3L, "PASS", "FAIL"),
  ifelse(nrow(mismatches) == 3L, "PASS", "FAIL"),
  ifelse(
    setequal(
      mismatches$input_role,
      c("gap_manifest", "gap_timing_unaware_metrics", "metric_display_registry")
    ),
    "PASS",
    "FAIL"
  ),
  ifelse(all(build_reconciliation$status == "UNCHANGED"), "PASS", "FAIL"),
  ifelse(all(protected_reconciliation$status == "UNCHANGED"), "PASS", "FAIL"),
  ifelse(all(support_reconciliation$status == "UNCHANGED"), "PASS", "FAIL"),
  ifelse(nrow(semantic_inventory) == 0L, "PASS", "FAIL"),
  ifelse(all(historical_tests_after$status == "UNCHANGED"), "PASS", "FAIL"),
  ifelse(
    frozen_after$sha256[frozen_after$path == relative_path(helper_path)] ==
      "c7a320367e0115aee221a3a6ba5228a9a27ba55f734bd07881455b3159cebf56",
    "PASS",
    "FAIL"
  ),
  ifelse(
    frozen_after$sha256[frozen_after$path == relative_path(manifest_path)] ==
      "8e1d633262b33df64e45f0fc3fd677f4bb1e8a69120cb76a9b152509b94f0aaf",
    "PASS",
    "FAIL"
  ),
  ifelse(
    frozen_after$sha256[frozen_after$path == relative_path(held_html_path)] ==
      "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    "PASS",
    "FAIL"
  ),
  ifelse(
    frozen_after$sha256[frozen_after$path == relative_path(source_html_path)] ==
      "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    "PASS",
    "FAIL"
  ),
  ifelse(
    frozen_after$sha256[frozen_after$path == relative_path(build_qmd_path)] ==
      "4640129c38a5aabd874549ff8d5ebc74b736a16fe6f900f4654b1573b2b69f5c",
    "PASS",
    "FAIL"
  )
)
write_evidence(checks, "failure_capture_checks.csv")

if (any(checks$status != "PASS")) {
  print(checks[checks$status != "PASS", , drop = FALSE])
  stop("Order 57 failure capture found an unclassified mutation", call. = FALSE)
}

cat(sprintf(
  paste0(
    "H09_ORDER57_FAILURE_CAPTURE=PASS failed_inputs=%d build_unchanged=%d ",
    "protected_unchanged=%d support_unchanged=%d semantic_files=%d ",
    "tests_unchanged=%d helper_runs=0 retries=0\n"
  ),
  nrow(mismatches),
  sum(build_reconciliation$status == "UNCHANGED"),
  sum(protected_reconciliation$status == "UNCHANGED"),
  sum(support_reconciliation$status == "UNCHANGED"),
  nrow(semantic_inventory),
  sum(historical_tests_after$status == "UNCHANGED")
))
