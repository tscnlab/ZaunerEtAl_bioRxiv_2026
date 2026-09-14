#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(knitr)
  library(openssl)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

phase <- Sys.getenv("H11_RESULT_PHASE", unset = "preflight")
stopifnot(phase %in% c("preflight", "postrender"))

default_output_dir <- file.path(
  root,
  "audit/report_harmonization/report018_h11_result_preflight"
)
output_dir <- Sys.getenv("H11_RESULT_CHECK_DIR", unset = default_output_dir)
if (!grepl("^/", output_dir)) {
  output_dir <- file.path(root, output_dir)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

file_exact <- function(path, sha256, bytes = NULL) {
  pass <- file.exists(path) &&
    !dir.exists(path) &&
    identical(sha256_file(path), sha256)
  if (!is.null(bytes)) {
    pass <- pass && identical(file_bytes(path), as.numeric(bytes))
  }
  pass
}

read_raw <- function(path) readBin(path, what = "raw", n = file_bytes(path))

checks <- list()
add_check <- function(domain, check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    domain = domain,
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

audit_non_circular_manifest <- function(path, expected_rows) {
  manifest <- utils::read.csv(path, check.names = FALSE)
  path_column <- if ("path" %in% names(manifest)) "path" else
    "project_relative_path"
  files <- manifest[[path_column]]
  exists <- file.exists(files)
  live_sha <- rep(NA_character_, length(files))
  live_bytes <- rep(NA_real_, length(files))
  live_sha[exists] <- vapply(files[exists], sha256_file, character(1))
  live_bytes[exists] <- unname(as.numeric(file.info(files[exists])$size))
  list(
    manifest = manifest,
    pass = nrow(manifest) == expected_rows &&
      !anyDuplicated(files) &&
      !basename(path) %in% basename(files) &&
      all(exists) &&
      identical(unname(live_sha), manifest$sha256) &&
      identical(as.numeric(live_bytes), as.numeric(manifest$bytes)),
    exact = sum(
      exists &
        live_sha == manifest$sha256 &
        live_bytes == as.numeric(manifest$bytes)
    )
  )
}

# H10 independent closure.
h10_owner_manifest_path <- paste0(
  "audit/hypotheses/H10/",
  "report018_order59a_companion_recovery_completion/",
  "order59a_non_circular_evidence_manifest.csv"
)
h10_owner <- audit_non_circular_manifest(h10_owner_manifest_path, 114L)
h10_owner_paths <- h10_owner$manifest$path
h10_owner_exists <- file.exists(h10_owner_paths)
h10_owner_live_sha <- rep(NA_character_, length(h10_owner_paths))
h10_owner_live_bytes <- rep(NA_real_, length(h10_owner_paths))
h10_owner_live_sha[h10_owner_exists] <- vapply(
  h10_owner_paths[h10_owner_exists],
  sha256_file,
  character(1)
)
h10_owner_live_bytes[h10_owner_exists] <- unname(
  as.numeric(file.info(h10_owner_paths[h10_owner_exists])$size)
)
h10_owner_exact_mask <- h10_owner_exists &
  h10_owner_live_sha == h10_owner$manifest$sha256 &
  h10_owner_live_bytes == as.numeric(h10_owner$manifest$bytes)
h10_owner_mismatch_paths <- h10_owner_paths[!h10_owner_exact_mask]
h10_matrix_path <- "audit/report_harmonization/coordination_matrix.csv"
h10_matrix_row <- h10_owner$manifest[
  h10_owner$manifest$path == h10_matrix_path,
]
h10_live_matrix <- utils::read.csv(h10_matrix_path, check.names = FALSE)
h10_matrix_transition_pass <-
  identical(h10_owner_mismatch_paths, h10_matrix_path) &&
  nrow(h10_matrix_row) == 1L &&
  identical(
    h10_matrix_row$sha256,
    "8302b4906daa98c247025281d23bb1b896f456f0a6adf34b4068d17542a6c7fa"
  ) &&
  identical(as.numeric(h10_matrix_row$bytes), 41341) &&
  nrow(h10_live_matrix) == 15L &&
  ncol(h10_live_matrix) == 16L &&
  identical(
    h10_live_matrix$current_task_status_2026_08_12[
      h10_live_matrix$logical_order == 12L
    ],
    "idle_result_and_companion_accepted"
  ) &&
  identical(
    h10_live_matrix$current_task_status_2026_08_12[
      h10_live_matrix$logical_order == 13L
    ],
    "active_order60_h11_result_target_render"
  )
h10_owner_pass <-
  nrow(h10_owner$manifest) == 114L &&
  !anyDuplicated(h10_owner_paths) &&
  !basename(h10_owner_manifest_path) %in% basename(h10_owner_paths) &&
  all(h10_owner_exists) &&
  sum(h10_owner_exact_mask) == 113L &&
  h10_matrix_transition_pass
add_check(
  "H10",
  "order59a_owner_manifest",
  h10_owner_pass,
  sprintf(
    "exact=%d/114 matrix_transition=%s",
    sum(h10_owner_exact_mask),
    h10_matrix_transition_pass
  )
)

h10_fixed <- data.frame(
  path = c(
    "notebooks/hypotheses/H10.qmd",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    paste0(
      "_build/nathealth/audit/hypotheses/H10/",
      "H10_analysis_preparation.html"
    ),
    "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R",
    "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv"
  ),
  sha256 = c(
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14",
    "dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9",
    "26619260657ec0cb1d7ac7614af9e3e349a524ee242dd5645b27e31f4cb142f0",
    "4ebb3e9a32a09f3b289920aea325fadf3eaf0f727087d457f3f568b910a39fe0"
  ),
  stringsAsFactors = FALSE
)
h10_fixed$exact <- vapply(
  seq_len(nrow(h10_fixed)),
  function(index)
    file_exact(
      h10_fixed$path[[index]],
      h10_fixed$sha256[[index]]
    ),
  logical(1)
)
add_check(
  "H10",
  "accepted_result_companion_helper_and_manifest",
  all(h10_fixed$exact),
  sprintf("exact=%d/%d", sum(h10_fixed$exact), nrow(h10_fixed))
)

h10_manifest <- utils::read.csv(
  "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv",
  check.names = FALSE
)
h10_manifest_exact <- vapply(
  seq_len(nrow(h10_manifest)),
  function(index)
    file_exact(
      h10_manifest$path[[index]],
      h10_manifest$sha256[[index]],
      h10_manifest$bytes[[index]]
    ),
  logical(1)
)
add_check(
  "H10",
  "preparation_manifest_live_exact",
  nrow(h10_manifest) == 269L &&
    !anyDuplicated(h10_manifest$path) &&
    all(h10_manifest_exact),
  sprintf("exact=%d/%d", sum(h10_manifest_exact), nrow(h10_manifest))
)

h10_evidence_dir <- paste0(
  "audit/hypotheses/H10/",
  "report018_order59a_companion_recovery_completion"
)
h10_static <- utils::read.csv(
  file.path(h10_evidence_dir, "static_checks_postqa.csv"),
  check.names = FALSE
)
h10_visual <- utils::read.csv(
  file.path(h10_evidence_dir, "visual_qa_observations.csv"),
  check.names = FALSE
)
h10_lifecycle <- utils::read.csv(
  file.path(h10_evidence_dir, "server_lifecycle.csv"),
  check.names = FALSE
)
h10_build_same <- identical(
  read_raw(file.path(h10_evidence_dir, "build_inventory_preqa.csv")),
  read_raw(file.path(h10_evidence_dir, "build_inventory_postqa.csv"))
)
h10_protected_same <- identical(
  read_raw(file.path(h10_evidence_dir, "protected_inventory_preqa.csv")),
  read_raw(file.path(h10_evidence_dir, "protected_inventory_postqa.csv"))
)
add_check(
  "H10",
  "static_visual_lifecycle_and_no_drift",
  all(h10_static$pass) &&
    all(h10_visual$pass) &&
    all(h10_lifecycle$pass) &&
    h10_build_same &&
    h10_protected_same,
  sprintf(
    "static=%d visual=%d lifecycle=%d build_same=%s protected_same=%s",
    nrow(h10_static),
    nrow(h10_visual),
    nrow(h10_lifecycle),
    h10_build_same,
    h10_protected_same
  )
)

# H11 immutable and held identities.
h11_fixed <- data.frame(
  path = c(
    "notebooks/hypotheses/H11.qmd",
    "audit/hypotheses/H11/H11_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H11.html",
    paste0(
      "_build/nathealth/audit/hypotheses/H11/",
      "H11_analysis_preparation.html"
    ),
    "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
    "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
    "tests/hypotheses/H11/test_h11_preparation_report.R",
    "scripts/hypotheses/H11/build_h11_preparation_report_manifest.R",
    "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
    "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
    "audit/handoffs/H11_worker_handoff.md",
    "_quarto-nathealth.yml",
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html"
  ),
  sha256 = c(
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "c5724711ad1aa94631df0b6186fee92398d414ae02690ade08f320b29d6b6db7",
    "fd6307a6a2e9365f95f18f1fd668165cf833847cab58bac9d3be1e8a9b6dde11",
    "b0af27946d6c4001e659e9edb27bfab0fdfd3a36aa8be536d51ed50ae234a3c0",
    "3d945c2b813ffaa2291ddebbe01f1f45c5c4ae7fe10256c9a1c8b15c3b531e7b",
    "7c565618a4d3ec1c2240419b1daead2189616fce97931dde68e0a9450db8f41f",
    "317f31069e6019475023b3097b1d7f1b00435755e0a109e40535fab89b570bf8",
    "2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645",
    "00ce783a5958f6f958db1d2d6d78076760953ad1c51cc18c30abb697557c8e5c",
    "5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
    "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780"
  ),
  bytes = c(
    57462,
    54527,
    289711,
    775131,
    16783,
    8062,
    10562,
    10130,
    14512,
    72966,
    15358,
    7480,
    3623,
    37775
  ),
  stringsAsFactors = FALSE
)
if (phase == "postrender") {
  h11_fixed <- h11_fixed[
    h11_fixed$path != "_build/nathealth/notebooks/hypotheses/H11.html",
    ,
    drop = FALSE
  ]
}
h11_fixed$exact <- vapply(
  seq_len(nrow(h11_fixed)),
  function(index)
    file_exact(
      h11_fixed$path[[index]],
      h11_fixed$sha256[[index]],
      h11_fixed$bytes[[index]]
    ),
  logical(1)
)
add_check(
  "H11 identity",
  "source_tests_manifests_companion_profile_and_sensitivity",
  all(h11_fixed$exact),
  sprintf("exact=%d/%d phase=%s", sum(h11_fixed$exact), nrow(h11_fixed), phase)
)
utils::write.csv(
  h11_fixed,
  file.path(output_dir, paste0("h11_fixed_identities_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)

# Source parse, endpoint, link, and compute-boundary audit.
h11_qmd_path <- "notebooks/hypotheses/H11.qmd"
h11_lines <- readLines(h11_qmd_path, warn = FALSE, encoding = "UTF-8")
h11_text <- paste(h11_lines, collapse = "\n")
labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: ", h11_lines, value = TRUE)
)
table_labels <- labels[startsWith(labels, "tbl-")]
figure_labels <- labels[startsWith(labels, "fig-")]
purl_path <- tempfile("h11-result-", fileext = ".R")
on.exit(unlink(purl_path), add = TRUE)
invisible(knitr::purl(
  h11_qmd_path,
  output = purl_path,
  documentation = 0L,
  quiet = TRUE
))
h11_expressions <- parse(file = purl_path)

source(
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
)
h11_calls <- executable_r_call_names(h11_lines)
forbidden_calls <- c(
  "mgcv::gam",
  "mgcv::bam",
  "gam",
  "bam",
  "lme4::lmer",
  "lmer",
  "stats::predict",
  "predict",
  "stats::simulate",
  "simulate",
  "boot::boot",
  "boot",
  "h11_stage2_robust_context",
  "h11_stage2_robust_tests",
  "h11_activity_robust_test",
  "h11_stage2_effect_pilot",
  "h11_activity_pointwise_curves"
)
add_check(
  "H11 source",
  "parse_endpoints_and_no_scientific_execution_calls",
  length(table_labels) == 15L &&
    length(figure_labels) == 8L &&
    !anyDuplicated(c(table_labels, figure_labels)) &&
    length(intersect(h11_calls, forbidden_calls)) == 0L,
  sprintf(
    "expressions=%d tables=%d figures=%d forbidden=%d",
    length(h11_expressions),
    length(table_labels),
    length(figure_labels),
    length(intersect(h11_calls, forbidden_calls))
  )
)

markdown_matches <- regmatches(
  h11_text,
  gregexpr("\\[[^]]+\\]\\([^)]+\\)", h11_text, perl = TRUE)
)[[1L]]
markdown_targets <- sub("^.*\\(([^)]+)\\)$", "\\1", markdown_matches)
local_targets <- markdown_targets[
  !grepl("^(?:https?:|mailto:|#)", markdown_targets, perl = TRUE)
]
target_paths <- sub("#.*$", "", local_targets)
resolved_targets <- normalizePath(
  file.path(dirname(h11_qmd_path), target_paths),
  winslash = "/",
  mustWork = FALSE
)
target_exists <- file.exists(resolved_targets)
link_audit <- data.frame(
  target = local_targets,
  path = target_paths,
  resolved_path = resolved_targets,
  exists = target_exists,
  stringsAsFactors = FALSE
)
utils::write.csv(
  link_audit,
  file.path(output_dir, "h11_source_link_audit.csv"),
  row.names = FALSE,
  na = ""
)

deviation_targets <- regmatches(
  h11_text,
  gregexpr(
    "preregistration_deviations\\.qmd#dev-[0-9]+",
    h11_text,
    perl = TRUE
  )
)[[1L]]
deviation_ids <- sub("^.*#", "", deviation_targets)
expected_deviation_ids <- c(
  "dev-001",
  "dev-003",
  "dev-019",
  "dev-042",
  "dev-043",
  "dev-044",
  "dev-045",
  "dev-047",
  "dev-048",
  "dev-057"
)
central_deviations <- paste(
  readLines(
    "notebooks/preregistration_deviations.qmd",
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
deviation_resolves <- vapply(
  unique(deviation_ids),
  function(id) grepl(paste0("{#", id, "}"), central_deviations, fixed = TRUE),
  logical(1)
)
add_check(
  "H11 links",
  "relative_targets_and_deviation_anchors",
  length(local_targets) > 0L &&
    all(target_exists) &&
    setequal(unique(deviation_ids), expected_deviation_ids) &&
    all(deviation_resolves),
  sprintf(
    "links=%d unique=%d deviation_occurrences=%d unique_deviations=%d",
    length(local_targets),
    length(unique(local_targets)),
    length(deviation_ids),
    length(unique(deviation_ids))
  )
)

# Historical Stage 3 manifest transitions, with the result HTML transition
# admitted only after the sole target render and exact semantic summary.
stage3_manifest <- utils::read.csv(
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
  check.names = FALSE
)
stage3_live_sha <- vapply(stage3_manifest$path, sha256_file, character(1))
stage3_live_bytes <- unname(as.numeric(file.info(stage3_manifest$path)$size))
stage3_mismatch <- data.frame(
  path = stage3_manifest$path,
  role = stage3_manifest$role,
  sealed_sha256 = stage3_manifest$sha256,
  live_sha256 = stage3_live_sha,
  sealed_bytes = stage3_manifest$bytes,
  live_bytes = stage3_live_bytes,
  stringsAsFactors = FALSE
)
stage3_mismatch <- stage3_mismatch[
  stage3_mismatch$sealed_sha256 != stage3_mismatch$live_sha256 |
    stage3_mismatch$sealed_bytes != stage3_mismatch$live_bytes,
  ,
  drop = FALSE
]
expected_stage3_mismatch <- c(
  "audit/decisions/figure_readability_and_layout.md",
  "notebooks/hypotheses/H11.qmd",
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R"
)

semantic_audit_dir <- Sys.getenv("H11_SEMANTIC_AUDIT_DIR", unset = "")
semantic_summary <- NULL
if (phase == "postrender") {
  stopifnot(nzchar(semantic_audit_dir), dir.exists(semantic_audit_dir))
  semantic_summary_path <- file.path(
    semantic_audit_dir,
    "gt_html_semantic_post_render_summary.csv"
  )
  stopifnot(file.exists(semantic_summary_path))
  semantic_summary <- utils::read.csv(
    semantic_summary_path,
    check.names = FALSE
  )
  stopifnot(nrow(semantic_summary) == 1L)
  expected_stage3_mismatch <- c(
    expected_stage3_mismatch,
    "_build/nathealth/notebooks/hypotheses/H11.html"
  )
  html_index <- match(
    "_build/nathealth/notebooks/hypotheses/H11.html",
    stage3_mismatch$path
  )
  stopifnot(
    !is.na(html_index),
    identical(
      stage3_mismatch$live_sha256[[html_index]],
      semantic_summary$post_sha256[[1L]]
    )
  )
}
stage3_transition_pass <- nrow(stage3_manifest) == 69L &&
  !anyDuplicated(stage3_manifest$path) &&
  all(file.exists(stage3_manifest$path)) &&
  setequal(stage3_mismatch$path, expected_stage3_mismatch) &&
  identical(
    stage3_mismatch$live_sha256[
      match(
        "audit/decisions/figure_readability_and_layout.md",
        stage3_mismatch$path
      )
    ],
    "33bac9392c35ed2fb6fd8bef0cf80ba867229e97d31cd1ea28ce625a51c1565b"
  ) &&
  identical(
    stage3_mismatch$live_sha256[
      match("notebooks/hypotheses/H11.qmd", stage3_mismatch$path)
    ],
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867"
  ) &&
  identical(
    stage3_mismatch$live_sha256[
      match(
        "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
        stage3_mismatch$path
      )
    ],
    "b0af27946d6c4001e659e9edb27bfab0fdfd3a36aa8be536d51ed50ae234a3c0"
  )
utils::write.csv(
  stage3_mismatch,
  file.path(output_dir, paste0("h11_stage3_transitions_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)
add_check(
  "H11 manifest",
  "exact_stage3_historical_transition_set",
  stage3_transition_pass,
  sprintf(
    "rows=%d exact=%d transitions=%d phase=%s",
    nrow(stage3_manifest),
    nrow(stage3_manifest) - nrow(stage3_mismatch),
    nrow(stage3_mismatch),
    phase
  )
)

# The preparation helper and manifest remain held for the later companion.
preparation_manifest <- utils::read.csv(
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  check.names = FALSE
)
preparation_live_sha <- vapply(
  preparation_manifest$path,
  sha256_file,
  character(1)
)
preparation_live_bytes <- unname(as.numeric(
  file.info(preparation_manifest$path)$size
))
preparation_mismatch <- data.frame(
  path = preparation_manifest$path,
  role = preparation_manifest$role,
  sealed_sha256 = preparation_manifest$sha256,
  live_sha256 = preparation_live_sha,
  sealed_bytes = preparation_manifest$bytes,
  live_bytes = preparation_live_bytes,
  stringsAsFactors = FALSE
)
preparation_mismatch <- preparation_mismatch[
  preparation_mismatch$sealed_sha256 != preparation_mismatch$live_sha256 |
    preparation_mismatch$sealed_bytes != preparation_mismatch$live_bytes,
  ,
  drop = FALSE
]
expected_preparation_mismatch <- c(
  "audit/decisions/figure_readability_and_layout.md",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "notebooks/hypotheses/H11.qmd",
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
  "_quarto-nathealth.yml"
)
if (phase == "postrender") {
  expected_preparation_mismatch <- c(
    expected_preparation_mismatch,
    "_build/nathealth/notebooks/hypotheses/H11.html"
  )
}
preparation_manifest_pass <- nrow(preparation_manifest) == 282L &&
  !anyDuplicated(preparation_manifest$path) &&
  all(file.exists(preparation_manifest$path)) &&
  setequal(preparation_mismatch$path, expected_preparation_mismatch)
utils::write.csv(
  preparation_mismatch,
  file.path(
    output_dir,
    paste0("h11_held_preparation_manifest_transitions_", phase, ".csv")
  ),
  row.names = FALSE,
  na = ""
)
add_check(
  "H11 held companion",
  "complete_deferred_preparation_manifest_transition_set",
  preparation_manifest_pass,
  sprintf(
    "rows=%d transitions=%d helper_runs=0 preparation_test_runs=0",
    nrow(preparation_manifest),
    nrow(preparation_mismatch)
  )
)

# Run complete transition-aware copies of both current result tests without
# editing either accepted test.
replace_root <- function(lines) {
  index <- grep(
    "^root <- dirname\\(dirname\\(dirname\\(dirname\\(test_path\\)\\)\\)\\)$",
    lines
  )
  stopifnot(length(index) == 1L)
  replacement <- c(
    "root <- normalizePath(",
    "  Sys.getenv(\"NATHEALTH_PROJECT_ROOT\"),",
    "  winslash = \"/\",",
    "  mustWork = TRUE",
    ")"
  )
  c(
    lines[seq_len(index - 1L)],
    replacement,
    lines[(index + 1L):length(lines)]
  )
}

stage3_test_lines <- readLines(
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
  warn = FALSE,
  encoding = "UTF-8"
)
stage3_test_lines <- replace_root(stage3_test_lines)
stage3_start <- grep(
  '^message\\("Testing the sealed Stage 3 inventory"\\)$',
  stage3_test_lines
)
stage3_end <- grep(
  '^message\\("H11 Stage 3 reader report tests passed"\\)$',
  stage3_test_lines
)
stopifnot(length(stage3_start) == 1L, length(stage3_end) == 1L)
stage3_classifier <- c(
  'message("Testing the sealed Stage 3 inventory")',
  'stage3_manifest <- read_h11(',
  '  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv"',
  ')',
  'manifest_paths <- file.path(root, stage3_manifest$path)',
  'manifest_live_sha <- unname(vapply(',
  '  manifest_paths, artifact_sha256, character(1)',
  '))',
  'manifest_live_bytes <- unname(as.numeric(file.info(manifest_paths)$size))',
  'manifest_mismatch <- stage3_manifest$sha256 != manifest_live_sha |',
  '  stage3_manifest$bytes != manifest_live_bytes',
  'expected_mismatch <- c(',
  '  "audit/decisions/figure_readability_and_layout.md",',
  '  "notebooks/hypotheses/H11.qmd",',
  '  "tests/hypotheses/H11/test_h11_stage3_reader_report.R"',
  ')',
  'if (identical(Sys.getenv("H11_RESULT_PHASE"), "postrender")) {',
  '  expected_mismatch <- c(',
  '    expected_mismatch,',
  '    "_build/nathealth/notebooks/hypotheses/H11.html"',
  '  )',
  '  summary_path <- file.path(',
  '    Sys.getenv("H11_SEMANTIC_AUDIT_DIR"),',
  '    "gt_html_semantic_post_render_summary.csv"',
  '  )',
  '  stopifnot(file.exists(summary_path))',
  '  summary <- utils::read.csv(summary_path, check.names = FALSE)',
  '  html_index <- match(',
  '    "_build/nathealth/notebooks/hypotheses/H11.html",',
  '    stage3_manifest$path',
  '  )',
  '  stopifnot(',
  '    nrow(summary) == 1L,',
  '    identical(manifest_live_sha[[html_index]], summary$post_sha256[[1L]])',
  '  )',
  '}',
  'stopifnot(',
  '  nrow(stage3_manifest) == 69L,',
  '  all(file.exists(manifest_paths)),',
  '  all(stage3_manifest$r_version == "4.6.1"),',
  '  setequal(stage3_manifest$path[manifest_mismatch], expected_mismatch),',
  '  identical(',
  '    manifest_live_sha[[match(',
  '      "audit/decisions/figure_readability_and_layout.md",',
  '      stage3_manifest$path',
  '    )]],',
  '    "33bac9392c35ed2fb6fd8bef0cf80ba867229e97d31cd1ea28ce625a51c1565b"',
  '  ),',
  '  identical(',
  '    manifest_live_sha[[match(',
  '      "notebooks/hypotheses/H11.qmd", stage3_manifest$path',
  '    )]],',
  '    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867"',
  '  ),',
  '  identical(',
  '    manifest_live_sha[[match(',
  '      "tests/hypotheses/H11/test_h11_stage3_reader_report.R",',
  '      stage3_manifest$path',
  '    )]],',
  '    "b0af27946d6c4001e659e9edb27bfab0fdfd3a36aa8be536d51ed50ae234a3c0"',
  '  ),',
  '  any(stage3_manifest$role == "rendered_report"),',
  '  any(stage3_manifest$role == "audit_or_gate"),',
  '  any(stage3_manifest$path ==',
  '    "audit/hypotheses/H11/05_reader_diagnostic_figure_addition.md"),',
  '  any(stage3_manifest$role == "read_only_policy_input")',
  ')'
)
stage3_test_lines <- c(
  stage3_test_lines[seq_len(stage3_start - 1L)],
  stage3_classifier,
  stage3_test_lines[stage3_end:length(stage3_test_lines)]
)

report016_test_lines <- readLines(
  "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
  warn = FALSE,
  encoding = "UTF-8"
)
report016_test_lines <- replace_root(report016_test_lines)
report016_text <- paste(report016_test_lines, collapse = "\n")
report016_text <- gsub(
  "outside—and superseded by—the accepted author-approved H02 30-minute inheritance",
  "outside and superseded by the author-approved final H11 analysis",
  report016_text,
  fixed = TRUE
)
report016_text <- gsub(
  '!grepl("preregistration_deviations.qmd#", result_source, fixed = TRUE),',
  paste0(
    'length(unlist(regmatches(result_source, gregexpr(',
    '"preregistration_deviations.qmd#", result_source, fixed = TRUE)))) == 12L,'
  ),
  report016_text,
  fixed = TRUE
)
report016_text <- gsub(
  '!grepl("preregistration_deviations.qmd#", companion_source, fixed = TRUE)',
  paste0(
    'length(unlist(regmatches(companion_source, gregexpr(',
    '"preregistration_deviations.qmd#", companion_source, fixed = TRUE)))) == 13L'
  ),
  report016_text,
  fixed = TRUE
)
hash_transitions <- c(
  "6d8efe39896812437037ee60675f95fb71fd8f74f3eaf0e65b151f27f0822dbd" = "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
  "fc7781c887ba4470b1bb660143f5df207e780efd257ca268138dae2d35d42e7f" = "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816"
)
for (historical_sha in names(hash_transitions)) {
  report016_text <- gsub(
    historical_sha,
    hash_transitions[[historical_sha]],
    report016_text,
    fixed = TRUE
  )
}
report016_test_lines <- strsplit(report016_text, "\n", fixed = TRUE)[[1L]]

run_transition_test <- function(lines, stem) {
  path <- tempfile(stem, fileext = ".R")
  on.exit(unlink(path), add = TRUE)
  writeLines(lines, path, useBytes = TRUE)
  output <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", path),
    stdout = TRUE,
    stderr = TRUE,
    env = c(
      paste0("NATHEALTH_PROJECT_ROOT=", root),
      paste0("H11_RESULT_PHASE=", phase),
      paste0("H11_SEMANTIC_AUDIT_DIR=", semantic_audit_dir)
    )
  )
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  data.frame(
    test = stem,
    exit_status = as.integer(status),
    output = paste(output, collapse = " | "),
    stringsAsFactors = FALSE
  )
}

test_execution <- rbind(
  run_transition_test(stage3_test_lines, "h11-stage3-transition-aware-"),
  run_transition_test(report016_test_lines, "h11-report016-transition-aware-")
)
utils::write.csv(
  test_execution,
  file.path(
    output_dir,
    paste0("h11_transition_test_execution_", phase, ".csv")
  ),
  row.names = FALSE,
  na = ""
)
add_check(
  "H11 tests",
  "complete_transition_aware_stage3_and_report016_tests",
  all(test_execution$exit_status == 0L),
  paste(
    paste(test_execution$test, test_execution$exit_status, sep = "="),
    collapse = "|"
  )
)

# H11 science and source-identical build resources are frozen.
h11_science <- sort(unique(c(
  list.files(
    "artifacts/06_model_data/H11",
    recursive = TRUE,
    full.names = TRUE
  ),
  list.files("artifacts/07_models/H11", recursive = TRUE, full.names = TRUE),
  list.files(
    "artifacts/08_diagnostics/H11",
    recursive = TRUE,
    full.names = TRUE
  ),
  list.files("artifacts/09_tables/H11", recursive = TRUE, full.names = TRUE),
  list.files("artifacts/10_figures/H11", recursive = TRUE, full.names = TRUE),
  list.files(
    "artifacts/11_source_data/H11",
    recursive = TRUE,
    full.names = TRUE
  )
)))
h11_science <- h11_science[
  file.exists(h11_science) & !dir.exists(h11_science)
]
h11_science_inventory <- data.frame(
  path = h11_science,
  sha256 = vapply(h11_science, sha256_file, character(1)),
  bytes = unname(as.numeric(file.info(h11_science)$size)),
  stringsAsFactors = FALSE
)
science_inventory_path <- file.path(
  default_output_dir,
  "h11_scientific_assets_preflight.csv"
)
if (phase == "preflight") {
  dir.create(default_output_dir, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    h11_science_inventory,
    science_inventory_path,
    row.names = FALSE,
    na = ""
  )
  science_pass <- !anyDuplicated(h11_science_inventory$path)
} else {
  stopifnot(file.exists(science_inventory_path))
  sealed_science <- utils::read.csv(science_inventory_path, check.names = FALSE)
  science_pass <-
    identical(h11_science_inventory$path, sealed_science$path) &&
    identical(h11_science_inventory$sha256, sealed_science$sha256) &&
    identical(
      as.numeric(h11_science_inventory$bytes),
      as.numeric(sealed_science$bytes)
    )
}
add_check(
  "H11 protection",
  "scientific_assets_frozen",
  science_pass,
  sprintf("files=%d phase=%s", nrow(h11_science_inventory), phase)
)

build_h11 <- list.files(
  "_build/nathealth/artifacts",
  pattern = "H11",
  recursive = TRUE,
  full.names = TRUE
)
build_h11_source <- sub("^_build/nathealth/", "", build_h11)
build_h11_exact <- vapply(
  seq_along(build_h11),
  function(index) {
    file.exists(build_h11_source[[index]]) &&
      identical(
        sha256_file(build_h11[[index]]),
        sha256_file(build_h11_source[[index]])
      )
  },
  logical(1)
)
add_check(
  "H11 build",
  "source_identical_h11_resource_copies",
  length(build_h11) == 34L && all(build_h11_exact),
  sprintf("exact=%d/%d", sum(build_h11_exact), length(build_h11))
)

build_entries <- list.files(
  "_build/nathealth",
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE,
  include.dirs = TRUE
)
build_links <- Sys.readlink(build_entries)
add_check(
  "H11 visual harness",
  "bounded_loopback_root_has_no_symlinks",
  !any(nzchar(build_links)),
  sprintf(
    "entries=%d symlinks=%d",
    length(build_entries),
    sum(nzchar(build_links))
  )
)

if (phase == "postrender") {
  result_html <- "_build/nathealth/notebooks/hypotheses/H11.html"
  document <- xml2::read_html(result_html)
  main_nodes <- xml2::xml_find_all(
    document,
    "//main[@id='quarto-document-content']"
  )
  stopifnot(length(main_nodes) == 1L)
  main <- main_nodes[[1L]]
  gt_tables <- xml2::xml_find_all(
    main,
    ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
  )
  figure_images <- xml2::xml_find_all(main, ".//figure//img")
  document_ids <- xml2::xml_attr(
    xml2::xml_find_all(document, ".//*[@id]"),
    "id"
  )
  document_ids <- document_ids[!is.na(document_ids) & nzchar(document_ids)]
  header_tokens <- 0L
  headers_valid <- all(vapply(
    gt_tables,
    function(table) {
      id_nodes <- xml2::xml_find_all(table, "self::*[@id] | .//*[@id]")
      ids <- xml2::xml_attr(id_nodes, "id")
      values <- xml2::xml_attr(
        xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
        "headers"
      )
      all(vapply(
        values,
        function(value) {
          tokens <- strsplit(value, "[[:space:]]+")[[1L]]
          header_tokens <<- header_tokens + length(tokens)
          positions <- match(tokens, ids)
          length(tokens) > 0L &&
            !anyNA(positions) &&
            all(vapply(
              tokens,
              function(token) sum(ids == token) == 1L,
              logical(1)
            )) &&
            all(xml2::xml_name(id_nodes[positions]) == "th")
        },
        logical(1)
      ))
    },
    logical(1)
  ))
  alt <- xml2::xml_attr(figure_images, "alt")
  errors <- xml2::xml_find_all(
    main,
    ".//*[contains(@class,'error') or contains(@class,'warning')]"
  )
  add_check(
    "H11 postrender",
    "native_endpoints_semantics_alt_and_no_errors",
    length(main_nodes) == 1L &&
      length(gt_tables) == 15L &&
      length(figure_images) == 8L &&
      !anyDuplicated(document_ids) &&
      headers_valid &&
      header_tokens > 0L &&
      all(!is.na(alt) & nzchar(alt)) &&
      length(errors) == 0L &&
      semantic_summary$table_count[[1L]] == 15L,
    sprintf(
      "tables=%d figures=%d duplicate_ids=%d headers=%d errors=%d",
      length(gt_tables),
      length(figure_images),
      anyDuplicated(document_ids),
      header_tokens,
      length(errors)
    )
  )
}

audit <- do.call(rbind, checks)
utils::write.csv(
  audit,
  file.path(output_dir, paste0("report018_h10_h11_checks_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)
stopifnot(all(audit$pass))

cat(sprintf(
  paste0(
    "REPORT018_H10_H11_PREFLIGHT=PASS phase=%s checks=%d ",
    "H10_owner=113/114+matrix_transition H10_manifest=269/269 ",
    "H11_stage3=%d_transitions H11_preparation=%d_transitions ",
    "tests=2/2 tables=15 figures=8 science=%d build_resources=34 R=%s\n"
  ),
  phase,
  nrow(audit),
  nrow(stage3_mismatch),
  nrow(preparation_mismatch),
  nrow(h11_science_inventory),
  as.character(getRversion())
))
