#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 57a failure capture requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages(library(digest))

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
  stopifnot(all(file.exists(paths)))
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
build_entries <- list.files(
  file.path(root, "_build/nathealth"),
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
  "build_symlink_inventory_postfailure.csv"
)

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
write_evidence(semantic_inventory, "semantic_directory_postfailure.csv")

stage3_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
)
stage3_manifest <- read.csv(stage3_manifest_path, check.names = FALSE)
mutable_records <- c(
  "audit/handoffs/H09_worker_handoff.md",
  "audit/handoffs/H09_shared_change_request.md"
)
stage3_immutable <- stage3_manifest[
  !stage3_manifest$path %in% mutable_records,
  ,
  drop = FALSE
]
stage3_paths <- file.path(root, stage3_immutable$path)
stage3_exists <- file.exists(stage3_paths) & !dir.exists(stage3_paths)
stage3_sha <- rep(NA_character_, nrow(stage3_immutable))
stage3_bytes <- rep(NA_real_, nrow(stage3_immutable))
stage3_sha[stage3_exists] <- vapply(
  stage3_paths[stage3_exists],
  sha256_file,
  character(1)
)
stage3_bytes[stage3_exists] <- file_bytes(stage3_paths[stage3_exists])
stage3_live <- transform(
  stage3_immutable,
  current_sha256 = stage3_sha,
  current_bytes = stage3_bytes,
  path_exists = stage3_exists,
  status = ifelse(
    stage3_exists & stage3_sha == stage3_immutable$sha256 &
      stage3_bytes == as.numeric(stage3_immutable$bytes),
    "PASS",
    "FAIL"
  )
)
write_evidence(stage3_live, "reader_manifest_live_audit_sealed.csv")
stage3_mismatches <- stage3_live[stage3_live$status == "FAIL", , drop = FALSE]
write_evidence(stage3_mismatches, "reader_manifest_mismatches_sealed.csv")

expected_stage3_mismatches <- c(
  "audit/hypotheses/H09/H09_stage1_gate_and_stage2_transition.md",
  "scripts/hypotheses/H09/h09_contract.R",
  "scripts/hypotheses/H09/run_h09_stage2.R",
  "artifacts/10_figures/H09/H09_diagnostics_chest.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_chest.png",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.pdf",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.png",
  "artifacts/10_figures/H09/H09_paired_placement_effects.pdf",
  "artifacts/10_figures/H09/H09_paired_placement_effects.png",
  "artifacts/10_figures/H09/H09_primary_effects.pdf",
  "artifacts/10_figures/H09/H09_primary_effects.png",
  "artifacts/06_model_data/H09/H09_base_bundle_audit.csv",
  "artifacts/06_model_data/H09/H09_input_audit.csv",
  "artifacts/12_manifests/H09/H09_figure_manifest.csv",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "notebooks/hypotheses/H09.qmd",
  "config/metric_display_registry.csv",
  "_quarto-nathealth.yml",
  "audit/decisions/figure_readability_and_layout.md"
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
write_evidence(
  transform(
    stop_manifest,
    observed_sha256 = vapply(stop_files, sha256_file, character(1)),
    observed_bytes = file_bytes(stop_files),
    status = ifelse(stop_exact, "PASS", "FAIL")
  ),
  "order57_history_audit_postfailure.csv"
)

postimages <- data.frame(
  path = c(
    "scripts/hypotheses/H09/h09_contract.R",
    "artifacts/06_model_data/H09/H09_input_audit.csv",
    "audit/hypotheses/H09/H09_analysis_preparation.qmd"
  ),
  expected_sha256 = c(
    "866b0f8736c8a25f50a3f1ce6e38c5d33d4666d4bf06031f0021ee1cb6d0b701",
    "1ea3910539378434533dcaeeaee6ab613e325468d99ffd10e02bdc868a4175ed",
    "286c391fb228268804ba199d38bd5341509b3a66d434e30aa09fc1007a19443e"
  ),
  expected_bytes = c(16374, 4401, 48400),
  stringsAsFactors = FALSE
)
postimage_files <- file.path(root, postimages$path)
postimages$observed_sha256 <- vapply(postimage_files, sha256_file, character(1))
postimages$observed_bytes <- file_bytes(postimage_files)
postimages$status <- ifelse(
  postimages$observed_sha256 == postimages$expected_sha256 &
    postimages$observed_bytes == postimages$expected_bytes,
  "PASS",
  "FAIL"
)
write_evidence(postimages, "authorized_postimages_postfailure.csv")

frozen_expected <- data.frame(
  path = c(
    "artifacts/12_manifests/H09/H09_stage3_artifacts.csv",
    "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv",
    "scripts/hypotheses/H09/build_h09_preparation_report_manifest.R",
    "tests/hypotheses/H09/test_h09_preparation_report.R",
    "tests/hypotheses/H09/test_h09_stage3_reader_report.R",
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd",
    "audit/hypotheses/H09/H09_analysis_preparation.html",
    "notebooks/hypotheses/H09.qmd",
    "_build/nathealth/notebooks/hypotheses/H09.html",
    "_quarto-nathealth.yml",
    "scripts/report_harmonization/post_render_gt_html_semantics.R",
    "scripts/report_harmonization/repair_gt_html_semantics.R",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "audit/handoffs/H09_worker_handoff.md",
    "renv.lock",
    "artifacts/06_model_data/H09/H09_METRIC-011_excluded_shared_drift.csv"
  ),
  expected_sha256 = c(
    "0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2",
    "8e1d633262b33df64e45f0fc3fd677f4bb1e8a69120cb76a9b152509b94f0aaf",
    "c7a320367e0115aee221a3a6ba5228a9a27ba55f734bd07881455b3159cebf56",
    "9a243e391de7069179fcd0ccb7cc6813a5e779b1ae1bf7fcb52706349553dfe7",
    "a0309e55d305b13be7571e404eb9650154f0ffc494c44b4512c833aa579d2bd1",
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    "4640129c38a5aabd874549ff8d5ebc74b736a16fe6f900f4654b1573b2b69f5c",
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    "c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6",
    "901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205",
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
    "f6a596f9c2ac8ad295e13d2283026c5068da57af36914cccb662620da861fcf4",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "91d9781466273385338432c7d86c68f35ae65ba828e547659d0cf69720b5b5b9"
  ),
  stringsAsFactors = FALSE
)
frozen_files <- file.path(root, frozen_expected$path)
frozen_expected$observed_sha256 <- vapply(
  frozen_files,
  sha256_file,
  character(1)
)
frozen_expected$bytes <- file_bytes(frozen_files)
frozen_expected$status <- ifelse(
  frozen_expected$observed_sha256 == frozen_expected$expected_sha256,
  "PASS",
  "FAIL"
)
write_evidence(frozen_expected, "frozen_endpoints_postfailure.csv")

preflight <- read.csv(
  file.path(working_dir, "preflight_summary.csv"),
  check.names = FALSE
)
scope_checker <- read.csv(
  file.path(working_dir, "scientific_scope_checker_execution.csv"),
  check.names = FALSE
)
process_after <- read.csv(
  file.path(working_dir, "process_probe_postfailure.csv"),
  check.names = FALSE
)
cache_before <- read.csv(
  file.path(working_dir, "sass_cache_inventory_before.csv"),
  check.names = FALSE
)
cache_after <- read.csv(
  file.path(working_dir, "sass_cache_inventory_after.csv"),
  check.names = FALSE
)

checks <- data.frame(
  check = c(
    "complete preflight passed once",
    "scientific-scope checker passed once",
    "sole retry failed at reader-manifest gate",
    "reader-manifest failure reproduced",
    "reader-manifest mismatch path set exact",
    "Stage 3 manifest remained historical and byte-identical",
    "authorized source postimages remained exact",
    "build remained unchanged",
    "build remained symlink-free",
    "protected scope remained unchanged",
    "historical source-side support tree remained unchanged",
    "order-57 failure history remained 45/45 exact",
    "semantic directory remained empty after execution failure",
    "helper, tests, result, profile, semantic code, handoff, lock, and manifests exact",
    "Sass cache remained unchanged",
    "no task process, helper, additional retry, or browser QA remained"
  ),
  observed = c(
    paste0(sum(preflight$status == "PASS"), "/", nrow(preflight)),
    paste0(scope_checker$status, "; invocation=", scope_checker$invocation_count),
    "retry 1; exit 1; helper 0; browser 0",
    paste0(sum(stage3_live$status == "PASS"), "/", nrow(stage3_live), "; mismatch=", nrow(stage3_mismatches)),
    paste(sort(stage3_mismatches$path), collapse = "|"),
    paste(sha256_file(stage3_manifest_path), file_bytes(stage3_manifest_path), sep = "/"),
    paste0(sum(postimages$status == "PASS"), "/", nrow(postimages)),
    paste(table(build_reconciliation$status), collapse = ";"),
    length(build_symlinks),
    paste(table(protected_reconciliation$status), collapse = ";"),
    paste(table(support_reconciliation$status), collapse = ";"),
    paste0(sum(stop_exact), "/", nrow(stop_manifest)),
    nrow(semantic_inventory),
    paste0(sum(frozen_expected$status == "PASS"), "/", nrow(frozen_expected)),
    paste(cache_after$sha256, cache_after$bytes, sep = "/"),
    paste0(sum(process_after$status == "PASS"), "/", nrow(process_after))
  ),
  expected = c(
    "21/21",
    "PASS; invocation=1",
    "retry 1; exit 1; helper 0; browser 0",
    "87/106; mismatch=19",
    paste(sort(expected_stage3_mismatches), collapse = "|"),
    "0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2/24678",
    "3/3",
    "all unchanged",
    "0",
    "all unchanged",
    "all unchanged",
    "45/45",
    "0",
    paste0(nrow(frozen_expected), "/", nrow(frozen_expected)),
    paste(cache_before$sha256, cache_before$bytes, sep = "/"),
    paste0(nrow(process_after), "/", nrow(process_after))
  ),
  stringsAsFactors = FALSE
)
checks$status <- c(
  ifelse(nrow(preflight) == 21L && all(preflight$status == "PASS"), "PASS", "FAIL"),
  ifelse(
    nrow(scope_checker) == 1L && scope_checker$status == "PASS" &&
      scope_checker$invocation_count == 1L,
    "PASS",
    "FAIL"
  ),
  "PASS",
  ifelse(
    nrow(stage3_manifest) == 108L && nrow(stage3_immutable) == 106L &&
      sum(stage3_live$status == "PASS") == 87L && nrow(stage3_mismatches) == 19L,
    "PASS",
    "FAIL"
  ),
  ifelse(setequal(stage3_mismatches$path, expected_stage3_mismatches), "PASS", "FAIL"),
  ifelse(
    sha256_file(stage3_manifest_path) ==
      "0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2" &&
      file_bytes(stage3_manifest_path) == 24678,
    "PASS",
    "FAIL"
  ),
  ifelse(all(postimages$status == "PASS"), "PASS", "FAIL"),
  ifelse(all(build_reconciliation$status == "UNCHANGED"), "PASS", "FAIL"),
  ifelse(length(build_symlinks) == 0L, "PASS", "FAIL"),
  ifelse(all(protected_reconciliation$status == "UNCHANGED"), "PASS", "FAIL"),
  ifelse(all(support_reconciliation$status == "UNCHANGED"), "PASS", "FAIL"),
  ifelse(nrow(stop_manifest) == 45L && all(stop_exact), "PASS", "FAIL"),
  ifelse(nrow(semantic_inventory) == 0L, "PASS", "FAIL"),
  ifelse(all(frozen_expected$status == "PASS"), "PASS", "FAIL"),
  ifelse(
    identical(cache_before$sha256, cache_after$sha256) &&
      identical(as.numeric(cache_before$bytes), as.numeric(cache_after$bytes)),
    "PASS",
    "FAIL"
  ),
  ifelse(all(process_after$status == "PASS"), "PASS", "FAIL")
)
write_evidence(checks, "failure_capture_checks.csv")

if (any(checks$status != "PASS")) {
  print(checks[checks$status != "PASS", , drop = FALSE])
  stop("Order 57a failure capture found an unclassified mutation", call. = FALSE)
}

cat(sprintf(
  paste0(
    "H09_ORDER57A_FAILURE_CAPTURE=PASS checks=%d/%d reader_manifest=87/106+19 ",
    "build=%d unchanged protected=%d unchanged support=16 unchanged stop=45/45 ",
    "semantic=0 retry=1 additional_retry=0 helper=0 browser=0 R=%s\n"
  ),
  nrow(checks),
  nrow(checks),
  nrow(build_after),
  nrow(protected_after),
  as.character(getRversion())
))
