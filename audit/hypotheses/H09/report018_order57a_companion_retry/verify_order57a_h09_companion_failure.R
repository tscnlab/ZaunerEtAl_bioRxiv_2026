#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 57a fail-closed verifier requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages(library(digest))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_rel <-
  "audit/hypotheses/H09/report018_order57a_companion_retry"
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
  "ORDER57A_FAIL_CLOSED.md",
  "dispatch_baseline_before_authorized_edits.csv",
  "dispatch_reconciliation_prerender.csv",
  "stopped_acceptance_manifest_audit_prerender.csv",
  "order57_owner_seal_audit_prerender.csv",
  "authorized_postimages_prerender.csv",
  "source_reverse_proof_prerender.csv",
  "input_audit_current_identity_prerender.csv",
  "scientific_scope_checker_execution.csv",
  "scientific_scope_checker_console.log",
  "preflight_summary.csv",
  "source_chunk_audit_prerender.csv",
  "source_endpoint_contract_prerender.csv",
  "source_prohibited_call_audit_prerender.csv",
  "source_reader_targets_prerender.csv",
  "preparation_manifest_audit_prerender.csv",
  "prospective_helper_inventory_prerender.csv",
  "build_inventory_prerender.csv",
  "protected_inventory_prerender.csv",
  "source_side_support_tree_prerender.csv",
  "render_execution.csv",
  "render_console.log",
  "reader_manifest_live_audit_sealed.csv",
  "reader_manifest_mismatches_sealed.csv",
  "failure_capture_checks.csv",
  "build_inventory_postfailure.csv",
  "build_reconciliation_postfailure.csv",
  "protected_inventory_postfailure.csv",
  "protected_reconciliation_postfailure.csv",
  "source_side_support_tree_postfailure.csv",
  "source_side_support_reconciliation_postfailure.csv",
  "semantic_directory_postfailure.csv",
  "order57_history_audit_postfailure.csv",
  "authorized_postimages_postfailure.csv",
  "frozen_endpoints_postfailure.csv",
  "process_probe_prerender.csv",
  "process_probe_postfailure.csv",
  "sass_cache_inventory_before.csv",
  "sass_cache_inventory_after.csv",
  "verify_order57a_preflight.R",
  "diagnose_reader_manifest_failure.R",
  "capture_order57a_failure.R",
  "h09_contract.R.preimage",
  "H09_input_audit.csv.preimage",
  "H09_analysis_preparation.qmd.preimage",
  "verify_order57a_h09_companion_failure.R"
)
required_paths <- file.path(evidence_dir, required_evidence)
add_check(
  "evidence",
  "required evidence present",
  sum(file.exists(required_paths) & !dir.exists(required_paths)),
  length(required_paths),
  all(file.exists(required_paths) & !dir.exists(required_paths))
)

preflight <- read_evidence("preflight_summary.csv")
add_check(
  "preflight",
  "complete order-specific preflight",
  paste(sum(preflight$status == "PASS"), nrow(preflight), sep = "/"),
  "21/21",
  nrow(preflight) == 21L && all(preflight$status == "PASS")
)

dispatch <- read_evidence("dispatch_reconciliation_prerender.csv")
acceptance <- read_evidence("stopped_acceptance_manifest_audit_prerender.csv")
stop_seal <- read_evidence("order57_owner_seal_audit_prerender.csv")
add_check(
  "authority",
  "dispatch, independent acceptance, and owner stop",
  paste(
    sum(dispatch$status == "PASS"),
    sum(acceptance$status == "PASS"),
    sum(stop_seal$status == "PASS"),
    sep = "/"
  ),
  "49/30/45",
  nrow(dispatch) == 49L && all(dispatch$status == "PASS") &&
    nrow(acceptance) == 30L && all(acceptance$status == "PASS") &&
    nrow(stop_seal) == 45L && all(stop_seal$status == "PASS")
)

postimages <- read_evidence("authorized_postimages_postfailure.csv")
reversals <- read_evidence("source_reverse_proof_prerender.csv")
postimage_files <- file.path(root, postimages$path)
postimage_live <- file.exists(postimage_files) & !dir.exists(postimage_files) &
  vapply(postimage_files, sha256_file, character(1)) == postimages$expected_sha256 &
  file_bytes(postimage_files) == as.numeric(postimages$expected_bytes)
add_check(
  "source repair",
  "postimages and reversals exact",
  paste(sum(postimage_live), sum(reversals$status == "PASS"), sep = "/"),
  "3/3",
  nrow(postimages) == 3L && all(postimage_live) &&
    nrow(reversals) == 3L && all(reversals$status == "PASS")
)

preimage_names <- c(
  "h09_contract.R.preimage",
  "H09_input_audit.csv.preimage",
  "H09_analysis_preparation.qmd.preimage"
)
preimage_expected <- c(
  "458dc3c08f0cd74acecc790d30226d930839b3f8f252a3018085e35611de3cd1",
  "be258bf523eadc318cf8926298e83275f64b38f5c5c4d1cc499f7841c0c2cafb",
  "7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46"
)
preimage_files <- file.path(evidence_dir, preimage_names)
add_check(
  "source repair",
  "durable preimages exact",
  sum(vapply(preimage_files, sha256_file, character(1)) == preimage_expected),
  3L,
  all(vapply(preimage_files, sha256_file, character(1)) == preimage_expected)
)

inputs <- read_evidence("input_audit_current_identity_prerender.csv")
result_roles <- c(
  "metric_manifest", "base_manifest", "primary_near_eye_context",
  "primary_chest_context", "primary_near_eye_enriched",
  "primary_chest_enriched", "normalized_chronotype",
  "gap_timing_unaware_metrics", "gap_manifest",
  "site_display_registry", "metric_display_registry"
)
add_check(
  "source repair",
  "all current input identities",
  paste(
    sum(inputs$status == "PASS"),
    sum(inputs$input_role %in% result_roles & inputs$status == "PASS"),
    sep = "/"
  ),
  "16/11",
  nrow(inputs) == 16L && all(inputs$status == "PASS") &&
    sum(inputs$input_role %in% result_roles) == 11L
)

scope <- read_evidence("scientific_scope_checker_execution.csv")
scope_console <- paste(
  readLines(
    file.path(evidence_dir, "scientific_scope_checker_console.log"),
    warn = FALSE
  ),
  collapse = "\n"
)
scope_line <- paste0(
  "REPORT018_H09_ORDER57_SCOPE=PASS stop=45/45 verification=14/14 ",
  "gap_evidence=7/7 non_mder=25620 frames=40/40 frame_rows=32492 ",
  "registry=MDER_only scientific=65/65 checks=20/20 R=4.6.1"
)
add_check(
  "scientific scope",
  "checker ran once and reproduced invariant scope",
  paste(scope$invocation_count, scope$exit_code, scope$status, sep = "/"),
  "1/0/PASS",
  nrow(scope) == 1L && scope$invocation_count == 1L &&
    scope$exit_code == 0L && scope$status == "PASS" &&
    grepl(scope_line, scope_console, fixed = TRUE)
)

render <- read_evidence("render_execution.csv")
render_value <- setNames(as.character(render$value), render$field)
render_console <- paste(
  readLines(file.path(evidence_dir, "render_console.log"), warn = FALSE),
  collapse = "\n"
)
add_check(
  "execution",
  "sole retry failed at Stage 3 manifest assertion",
  paste(
    render_value[["retry_invocation_count"]],
    render_value[["exit_code"]],
    render_value[["additional_retry_count"]],
    render_value[["helper_invocation_count"]],
    render_value[["browser_qa_count"]],
    sep = "/"
  ),
  "1/1/0/0/0",
  identical(render_value[["retry_invocation_count"]], "1") &&
    identical(render_value[["exit_code"]], "1") &&
    identical(render_value[["additional_retry_count"]], "0") &&
    identical(render_value[["helper_invocation_count"]], "0") &&
    identical(render_value[["browser_qa_count"]], "0") &&
    grepl(
      "all(manifest_check$Status == \"PASS\") is not TRUE",
      render_console,
      fixed = TRUE
    ) &&
    grepl("tbl-h09-prep-reader-manifest-check", render_console, fixed = TRUE)
)

reader_live <- read_evidence("reader_manifest_live_audit_sealed.csv")
reader_mismatch <- read_evidence("reader_manifest_mismatches_sealed.csv")
expected_mismatch_paths <- c(
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
stage3_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
)
stage3_manifest <- read.csv(stage3_manifest_path, check.names = FALSE)
add_check(
  "failure",
  "frozen Stage 3 manifest failure reproduced exactly",
  paste(
    nrow(stage3_manifest), nrow(reader_live),
    sum(reader_live$status == "PASS"), nrow(reader_mismatch),
    sep = "/"
  ),
  "108/106/87/19",
  nrow(stage3_manifest) == 108L && nrow(reader_live) == 106L &&
    sum(reader_live$status == "PASS") == 87L &&
    nrow(reader_mismatch) == 19L &&
    setequal(reader_mismatch$path, expected_mismatch_paths) &&
    sha256_file(stage3_manifest_path) ==
      "0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2" &&
    file_bytes(stage3_manifest_path) == 24678
)

reconcile_live <- function(inventory_name) {
  before <- read_evidence(inventory_name)
  paths <- file.path(root, before$relative_path)
  exists <- file.exists(paths) & !dir.exists(paths)
  live_sha <- rep(NA_character_, length(paths))
  live_bytes <- rep(NA_real_, length(paths))
  live_sha[exists] <- vapply(paths[exists], sha256_file, character(1))
  live_bytes[exists] <- file_bytes(paths[exists])
  data.frame(
    relative_path = before$relative_path,
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
  "build remained unchanged and symlink-free",
  paste(sum(build_live$status == "UNCHANGED"), nrow(build_live), sep = "/"),
  "851/851",
  nrow(build_live) == 851L && all(build_live$status == "UNCHANGED") &&
    nrow(read_evidence("build_symlink_inventory_postfailure.csv")) == 0L
)

protected_live <- reconcile_live("protected_inventory_prerender.csv")
matrix_row <- protected_live$relative_path ==
  "audit/report_harmonization/coordination_matrix.csv"
add_check(
  "preservation",
  "non-matrix protected scope remained unchanged",
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
  "historical source-side support remained unchanged",
  paste(sum(support_live$status == "UNCHANGED"), nrow(support_live), sep = "/"),
  "16/16",
  nrow(support_live) == 16L && all(support_live$status == "UNCHANGED")
)

history <- read_evidence("order57_history_audit_postfailure.csv")
add_check(
  "preservation",
  "complete order-57 failure history exact",
  paste(sum(history$status == "PASS"), nrow(history), sep = "/"),
  "45/45",
  nrow(history) == 45L && all(history$status == "PASS")
)

frozen <- read_evidence("frozen_endpoints_postfailure.csv")
failure_capture <- read_evidence("failure_capture_checks.csv")
process_before <- read_evidence("process_probe_prerender.csv")
process_after <- read_evidence("process_probe_postfailure.csv")
semantic <- read_evidence("semantic_directory_postfailure.csv")
add_check(
  "preservation",
  "frozen endpoints, failure capture, semantic, and teardown",
  paste(
    sum(frozen$status == "PASS"),
    sum(failure_capture$status == "PASS"),
    nrow(semantic),
    sum(process_before$status == "PASS"),
    sum(process_after$status == "PASS"),
    sep = "/"
  ),
  paste0(nrow(frozen), "/16/0/1/3"),
  all(frozen$status == "PASS") && nrow(failure_capture) == 16L &&
    all(failure_capture$status == "PASS") && nrow(semantic) == 0L &&
    all(process_before$status == "PASS") &&
    all(process_after$status == "PASS")
)

semantic_pre <- read_evidence("semantic_directory_prerender.csv")
external_semantic <- semantic_pre$path[[1L]]
add_check(
  "environment",
  "external semantic directory retained and empty",
  paste(dir.exists(external_semantic), length(list.files(
    external_semantic,
    all.files = TRUE,
    no.. = TRUE
  )), sep = "/"),
  "TRUE/0",
  dir.exists(external_semantic) &&
    length(list.files(external_semantic, all.files = TRUE, no.. = TRUE)) == 0L
)

cache_before <- read_evidence("sass_cache_inventory_before.csv")
cache_after <- read_evidence("sass_cache_inventory_after.csv")
cache_path <- cache_after$path[[1L]]
add_check(
  "environment",
  "Sass cache remained unchanged",
  paste(sha256_file(cache_path), file_bytes(cache_path), sep = "/"),
  paste(cache_before$sha256, cache_before$bytes, sep = "/"),
  identical(cache_before$sha256, cache_after$sha256) &&
    identical(as.numeric(cache_before$bytes), as.numeric(cache_after$bytes)) &&
    sha256_file(cache_path) == cache_before$sha256 &&
    file_bytes(cache_path) == as.numeric(cache_before$bytes)
)

add_check(
  "boundary",
  "conditional actions correctly withheld",
  "additional retry 0; helper 0; browser QA 0",
  "additional retry 0; helper 0; browser QA 0",
  identical(render_value[["additional_retry_count"]], "0") &&
    identical(render_value[["helper_invocation_count"]], "0") &&
    identical(render_value[["browser_qa_count"]], "0")
)

checks$r_version <- as.character(getRversion())
checks$digest_version <- as.character(utils::packageVersion("digest"))
write_evidence(checks, "order57a_failure_verification.csv")

if (any(checks$status != "PASS")) {
  print(checks[checks$status != "PASS", , drop = FALSE])
  stop("Order 57a fail-closed verification failed", call. = FALSE)
}

manifest_name <- "order57a_fail_closed_evidence_manifest.csv"
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
    basename(evidence_files) == "ORDER57A_FAIL_CLOSED.md",
    "consolidated fail-closed record",
    ifelse(
      grepl("verify_order57a_h09", basename(evidence_files), fixed = TRUE),
      "new order-specific fail-closed verifier",
      "order 57a fail-closed evidence"
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
  !anyDuplicated(sealed$path),
  !any(sealed$path == file.path(evidence_rel, manifest_name)),
  all(sealed_exact)
)

cat(sprintf(
  paste0(
    "H09_ORDER57A_FAIL_CLOSED=PASS checks=%d/%d postimages=3 reversals=3 ",
    "scope=20 reader_manifest=87/106+19 retry=1 exit=1 additional_retry=0 ",
    "helper=0 browser=0 build=851 protected=%d support=16 stop=45 ",
    "evidence=%d R=%s digest=%s\n"
  ),
  nrow(checks),
  nrow(checks),
  sum(!matrix_row),
  nrow(sealed),
  as.character(getRversion()),
  as.character(utils::packageVersion("digest"))
))
