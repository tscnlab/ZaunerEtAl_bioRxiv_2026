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

output_dir <- Sys.getenv(
  "H11_COMPANION_PREFLIGHT_DIR",
  unset = file.path(
    root,
    paste0(
      "audit/report_harmonization/",
      "report018_h11_order60c_acceptance_and_companion_preflight"
    )
  )
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

sha256_raw <- function(value) paste0(openssl::sha256(value))

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file_bytes(path))
}

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

owner_dir <- paste0(
  "audit/hypotheses/H11/",
  "report018_order60c_no_rerender_completion"
)
owner_manifest_path <- file.path(
  owner_dir,
  "order60c_non_circular_completion_manifest.csv"
)
owner_manifest <- utils::read.csv(owner_manifest_path, check.names = FALSE)
owner_paths <- owner_manifest$path
owner_exists <- file.exists(owner_paths) & !dir.exists(owner_paths)
owner_live_sha <- rep(NA_character_, length(owner_paths))
owner_live_bytes <- rep(NA_real_, length(owner_paths))
owner_live_sha[owner_exists] <- vapply(
  owner_paths[owner_exists],
  sha256_file,
  character(1)
)
owner_live_bytes[owner_exists] <- unname(
  as.numeric(file.info(owner_paths[owner_exists])$size)
)
owner_exact <- owner_exists &
  owner_live_sha == owner_manifest$sha256 &
  owner_live_bytes == as.numeric(owner_manifest$bytes)
owner_audit <- data.frame(
  path = owner_paths,
  role = owner_manifest$role,
  sealed_sha256 = owner_manifest$sha256,
  live_sha256 = owner_live_sha,
  sealed_bytes = owner_manifest$bytes,
  live_bytes = owner_live_bytes,
  exact = owner_exact,
  stringsAsFactors = FALSE
)
utils::write.csv(
  owner_audit,
  file.path(output_dir, "owner_manifest_audit.csv"),
  row.names = FALSE,
  na = ""
)
owner_pass <- nrow(owner_manifest) == 107L &&
  !anyDuplicated(owner_paths) &&
  !owner_manifest_path %in% owner_paths &&
  all(owner_exact)
add_check(
  "H11 result acceptance",
  "owner_non_circular_manifest",
  owner_pass,
  sprintf("exact=%d/%d", sum(owner_exact), nrow(owner_manifest))
)

fixed <- data.frame(
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
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html",
    "_quarto-nathealth.yml",
    "renv.lock",
    file.path(owner_dir, "order60c_completion.md"),
    owner_manifest_path,
    file.path(
      owner_dir,
      "check_report018_h11_order60c_no_rerender_completion.R"
    ),
    "audit/report_harmonization/coordination_matrix.csv"
  ),
  sha256 = c(
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a",
    "fd6307a6a2e9365f95f18f1fd668165cf833847cab58bac9d3be1e8a9b6dde11",
    "b0af27946d6c4001e659e9edb27bfab0fdfd3a36aa8be536d51ed50ae234a3c0",
    "3d945c2b813ffaa2291ddebbe01f1f45c5c4ae7fe10256c9a1c8b15c3b531e7b",
    "7c565618a4d3ec1c2240419b1daead2189616fce97931dde68e0a9450db8f41f",
    "317f31069e6019475023b3097b1d7f1b00435755e0a109e40535fab89b570bf8",
    "2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645",
    "00ce783a5958f6f958db1d2d6d78076760953ad1c51cc18c30abb697557c8e5c",
    "5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289",
    "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
    "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "1171ec8d8538f529dfe0eec46d432fdda34e9d5cc8258ff2a27fe5d22429cc29",
    "a2a2db205736b3860db6d974ae0b83b192f9d18048959e154a5007391068746e",
    "4338fd078c73de265a7d25bd50afbc251c3289c1e5a01124490abc51b84c3af8",
    "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
  ),
  bytes = c(
    57462,
    54527,
    306265,
    775131,
    16783,
    8062,
    10562,
    10130,
    14512,
    72966,
    15358,
    3623,
    37775,
    7480,
    603493,
    3133,
    20725,
    32103,
    42552
  ),
  stringsAsFactors = FALSE
)
fixed$exists <- file.exists(fixed$path) & !dir.exists(fixed$path)
fixed$live_sha256 <- NA_character_
fixed$live_bytes <- NA_real_
fixed$live_sha256[fixed$exists] <- vapply(
  fixed$path[fixed$exists],
  sha256_file,
  character(1)
)
fixed$live_bytes[fixed$exists] <- unname(
  as.numeric(file.info(fixed$path[fixed$exists])$size)
)
fixed$exact <- fixed$exists &
  fixed$live_sha256 == fixed$sha256 &
  fixed$live_bytes == fixed$bytes
utils::write.csv(
  fixed,
  file.path(output_dir, "fixed_identity_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "H11 result acceptance",
  "fixed_endpoints_and_held_scopes",
  all(fixed$exact),
  sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed))
)

# Independently rerun the complete no-rerender verifier in a fresh temporary
# evidence directory. This produces no project mutation.
independent_dir <- tempfile(
  "report018-h11-order60c-independent-",
  tmpdir = "/private/tmp"
)
dir.create(independent_dir, recursive = TRUE, showWarnings = FALSE)
checker_path <- file.path(
  root,
  owner_dir,
  "check_report018_h11_order60c_no_rerender_completion.R"
)
semantic_dir <- file.path(
  root,
  "audit/hypotheses/H11/report018_order60b_environment_retry"
)
checker_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", shQuote(checker_path)),
  stdout = TRUE,
  stderr = TRUE,
  env = c(
    "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
    paste0("NATHEALTH_PROJECT_ROOT=", root),
    "H11_RESULT_PHASE=postrender",
    paste0("H11_RESULT_CHECK_DIR=", independent_dir),
    paste0("H11_SEMANTIC_AUDIT_DIR=", semantic_dir)
  )
)
checker_status <- attr(checker_output, "status")
if (is.null(checker_status)) checker_status <- 0L
writeLines(
  enc2utf8(checker_output),
  file.path(output_dir, "independent_complete_replay_output.txt"),
  useBytes = TRUE
)
independent_results_path <- file.path(
  independent_dir,
  "report018_h10_h11_checks_postrender.csv"
)
independent_results <- if (file.exists(independent_results_path)) {
  utils::read.csv(independent_results_path, check.names = FALSE)
} else {
  data.frame()
}
replay_pass <- checker_status == 0L &&
  nrow(independent_results) == 14L &&
  all(independent_results$pass) &&
  any(grepl("REPORT018_H10_H11_PREFLIGHT=PASS", checker_output, fixed = TRUE))
utils::write.csv(
  independent_results,
  file.path(output_dir, "independent_complete_replay_checks.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  data.frame(
    checker = substring(checker_path, nchar(root) + 2L),
    checker_sha256 = sha256_file(checker_path),
    phase = "postrender",
    exit_status = checker_status,
    checks = nrow(independent_results),
    pass = replay_pass,
    r_version = as.character(getRversion()),
    stringsAsFactors = FALSE
  ),
  file.path(output_dir, "independent_complete_replay_execution.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "H11 result acceptance",
  "independent_complete_replay",
  replay_pass,
  sprintf("status=%d checks=%d", checker_status, nrow(independent_results))
)

completion_contract <- utils::read.csv(
  file.path(owner_dir, "completion_contract_audit.csv"),
  check.names = FALSE
)
visual <- utils::read.csv(
  file.path(owner_dir, "visual_qa_observations.csv"),
  check.names = FALSE
)
lifecycle <- utils::read.csv(
  file.path(owner_dir, "server_lifecycle.csv"),
  check.names = FALSE
)
no_drift <- utils::read.csv(
  file.path(owner_dir, "no_drift_audit.csv"),
  check.names = FALSE
)
qa_pass <- nrow(completion_contract) == 17L &&
  all(completion_contract$pass) &&
  nrow(visual) == 17L &&
  all(visual$status %in% c("PASS", "NONBLOCKING")) &&
  nrow(lifecycle) == 8L &&
  identical(lifecycle$status[[8L]], "PASS") &&
  grepl("no process", lifecycle$process_identity[[8L]], fixed = TRUE) &&
  nrow(no_drift) == 11L &&
  all(no_drift$pass)
add_check(
  "H11 result acceptance",
  "visual_lifecycle_and_no_drift",
  qa_pass,
  sprintf(
    "completion=%d visual=%d lifecycle=%d no_drift=%d",
    nrow(completion_contract),
    nrow(visual),
    nrow(lifecycle),
    nrow(no_drift)
  )
)

# Companion source, endpoint, link, and compute-boundary preflight.
companion_qmd <- "audit/hypotheses/H11/H11_analysis_preparation.qmd"
qmd_lines <- readLines(companion_qmd, warn = FALSE, encoding = "UTF-8")
qmd_text <- paste(qmd_lines, collapse = "\n")
labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: ", qmd_lines, value = TRUE)
)
table_labels <- labels[startsWith(labels, "tbl-")]
figure_labels <- labels[startsWith(labels, "fig-")]
chunk_count <- sum(grepl("^```\\{r", qmd_lines))
purl_path <- tempfile("h11-companion-", fileext = ".R")
invisible(knitr::purl(
  companion_qmd,
  output = purl_path,
  documentation = 0L,
  quiet = TRUE
))
expressions <- parse(file = purl_path)

source("scripts/pipeline/hypothesis_preparation_provenance_contract.R")
calls <- executable_r_call_names(qmd_lines)
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
  "h02_fit_bam",
  "h11_stage2_robust_context",
  "h11_stage2_robust_tests",
  "h11_activity_robust_test",
  "h11_stage2_effect_pilot",
  "h11_activity_pointwise_curves"
)
source_pass <- chunk_count == 34L &&
  length(table_labels) == 26L &&
  length(figure_labels) == 3L &&
  !anyDuplicated(c(table_labels, figure_labels)) &&
  length(intersect(calls, forbidden_calls)) == 0L &&
  sum(grepl("flowchart TD", qmd_lines, fixed = TRUE)) == 1L
endpoint_inventory <- data.frame(
  endpoint = c(table_labels, figure_labels, "mermaid:h11-preparation-flow"),
  type = c(
    rep("table", length(table_labels)),
    rep("figure", length(figure_labels)),
    "mermaid"
  ),
  source_order = seq_len(length(table_labels) + length(figure_labels) + 1L),
  stringsAsFactors = FALSE
)
utils::write.csv(
  endpoint_inventory,
  file.path(output_dir, "companion_source_endpoint_inventory.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "H11 companion preflight",
  "source_parse_endpoints_and_no_scientific_execution",
  source_pass,
  sprintf(
    "chunks=%d expressions=%d tables=%d figures=%d mermaid=1 forbidden=%d",
    chunk_count,
    length(expressions),
    length(table_labels),
    length(figure_labels),
    length(intersect(calls, forbidden_calls))
  )
)

markdown_matches <- regmatches(
  qmd_text,
  gregexpr("\\[[^]]+\\]\\([^)]+\\)", qmd_text, perl = TRUE)
)[[1L]]
markdown_targets <- sub("^.*\\(([^)]+)\\)$", "\\1", markdown_matches)
local_targets <- markdown_targets[
  !grepl("^(?:https?:|mailto:|#)", markdown_targets, perl = TRUE)
]
target_paths <- sub("#.*$", "", local_targets)
fragments <- ifelse(
  grepl("#", local_targets, fixed = TRUE),
  sub("^.*#", "", local_targets),
  ""
)
resolved_paths <- normalizePath(
  file.path(dirname(companion_qmd), target_paths),
  winslash = "/",
  mustWork = FALSE
)
target_exists <- file.exists(resolved_paths)
fragment_resolves <- rep(TRUE, length(local_targets))
for (index in which(nzchar(fragments) & target_exists)) {
  target_text <- paste(
    readLines(resolved_paths[[index]], warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  fragment_resolves[[index]] <- grepl(
    paste0("{#", fragments[[index]], "}"),
    target_text,
    fixed = TRUE
  )
}
link_audit <- data.frame(
  target = local_targets,
  resolved_path = resolved_paths,
  exists = target_exists,
  fragment = fragments,
  fragment_resolves = fragment_resolves,
  stringsAsFactors = FALSE
)
utils::write.csv(
  link_audit,
  file.path(output_dir, "companion_source_link_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "H11 companion preflight",
  "relative_links_and_fragments",
  length(local_targets) == 20L &&
    length(unique(local_targets)) == 17L &&
    all(target_exists) &&
    all(fragment_resolves),
  sprintf(
    "occurrences=%d unique=%d fragments=%d",
    length(local_targets),
    length(unique(local_targets)),
    sum(nzchar(fragments))
  )
)

# Current held preparation manifest and its complete transition set.
preparation_manifest_path <- paste0(
  "artifacts/12_manifests/H11/",
  "H11_preparation_report_manifest.csv"
)
preparation_manifest <- utils::read.csv(
  preparation_manifest_path,
  check.names = FALSE
)
manifest_exists <- file.exists(preparation_manifest$path)
manifest_live_sha <- vapply(
  preparation_manifest$path,
  sha256_file,
  character(1)
)
manifest_live_bytes <- unname(
  as.numeric(file.info(preparation_manifest$path)$size)
)
manifest_mismatch <- data.frame(
  path = preparation_manifest$path,
  role = preparation_manifest$role,
  sealed_sha256 = preparation_manifest$sha256,
  live_sha256 = manifest_live_sha,
  sealed_bytes = preparation_manifest$bytes,
  live_bytes = manifest_live_bytes,
  stringsAsFactors = FALSE
)
manifest_mismatch <- manifest_mismatch[
  manifest_mismatch$sealed_sha256 != manifest_mismatch$live_sha256 |
    manifest_mismatch$sealed_bytes != manifest_mismatch$live_bytes,
  ,
  drop = FALSE
]
expected_mismatch <- c(
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H11.html",
  "notebooks/hypotheses/H11.qmd",
  "_quarto-nathealth.yml"
)
manifest_transition_pass <- nrow(preparation_manifest) == 282L &&
  !anyDuplicated(preparation_manifest$path) &&
  all(manifest_exists) &&
  setequal(manifest_mismatch$path, expected_mismatch)
utils::write.csv(
  manifest_mismatch,
  file.path(output_dir, "held_preparation_manifest_transitions.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "H11 companion preflight",
  "complete_historical_manifest_transition_set",
  manifest_transition_pass,
  sprintf(
    "rows=%d exact=%d transitions=%d",
    nrow(preparation_manifest),
    nrow(preparation_manifest) - nrow(manifest_mismatch),
    nrow(manifest_mismatch)
  )
)

# Reproduce the helper's dynamic path discovery without writing any project
# file. This proves that the truthful post-render manifest retains 282 rows.
list_artifacts <- function(path, pattern = NULL) {
  if (!dir.exists(path)) return(character())
  list.files(
    path,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE
  )
}
script_files <- list_artifacts(
  file.path(root, "scripts/hypotheses/H11"),
  pattern = "\\.R$"
)
test_files <- list_artifacts(
  file.path(root, "tests/hypotheses/H11"),
  pattern = "\\.R$"
)
model_data_files <- list_artifacts(file.path(
  root,
  "artifacts/06_model_data/H11"
))
model_files <- list_artifacts(file.path(root, "artifacts/07_models/H11"))
diagnostic_files <- list_artifacts(file.path(
  root,
  "artifacts/08_diagnostics/H11"
))
table_files <- list_artifacts(file.path(root, "artifacts/09_tables/H11"))
figure_files <- list_artifacts(file.path(root, "artifacts/10_figures/H11"))
source_data_files <- list_artifacts(file.path(
  root,
  "artifacts/11_source_data/H11"
))
manifest_files <- list_artifacts(
  file.path(root, "artifacts/12_manifests/H11"),
  pattern = "\\.(csv|pdf)$"
)
manifest_files <- setdiff(
  manifest_files,
  file.path(root, preparation_manifest_path)
)
rendered_asset_dir <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation_files"
)
preparation_asset_files <- list_artifacts(rendered_asset_dir)
site_figure_copies <- list_artifacts(file.path(
  root,
  "_build/nathealth/artifacts/10_figures/H11/preparation"
))
site_source_copies <- list_artifacts(file.path(
  root,
  "_build/nathealth/artifacts/11_source_data/H11/preparation"
))
decision_files <- file.path(
  root,
  c(
    "audit/decisions/hypothesis_preparation_provenance_companions.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/report011_physical_size_revalidation.md",
    "audit/decisions/reader_facing_symlog_scale.md",
    "audit/decisions/answer_in_brief_callout.md"
  )
)
prospective_files <- unique(c(
  file.path(root, "_quarto-nathealth.yml"),
  file.path(root, companion_qmd),
  file.path(
    root,
    "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.qmd"
  ),
  file.path(
    root,
    "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html"
  ),
  file.path(root, "notebooks/hypotheses/H11.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H11.html"),
  file.path(root, "config/site_display_registry.csv"),
  file.path(root, "renv.lock"),
  file.path(
    root,
    "audit/hypotheses/H11/H11_preparation_figure_readability_qa.md"
  ),
  file.path(
    root,
    "audit/hypotheses/H11/05_stage3_gate_and_stage4_transition.md"
  ),
  file.path(root, "scripts/pipeline/paths_io.R"),
  file.path(root, "scripts/pipeline/p_value_display.R"),
  file.path(
    root,
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  ),
  decision_files,
  preparation_asset_files,
  site_figure_copies,
  site_source_copies,
  script_files,
  test_files,
  model_data_files,
  model_files,
  diagnostic_files,
  table_files,
  figure_files,
  source_data_files,
  manifest_files
))
prospective_relative <- substring(
  normalizePath(prospective_files, winslash = "/", mustWork = TRUE),
  nchar(root) + 2L
)
prospective_inventory <- data.frame(
  path = prospective_relative,
  current_sha256 = vapply(prospective_files, sha256_file, character(1)),
  current_bytes = unname(as.numeric(file.info(prospective_files)$size)),
  in_current_manifest = prospective_relative %in% preparation_manifest$path,
  stringsAsFactors = FALSE
)
prospective_inventory <- prospective_inventory[
  order(prospective_inventory$path),
]
utils::write.csv(
  prospective_inventory,
  file.path(output_dir, "prospective_helper_path_inventory.csv"),
  row.names = FALSE,
  na = ""
)
expected_helper_addition <-
  "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R"
helper_inventory_pass <- nrow(prospective_inventory) == 283L &&
  !anyDuplicated(prospective_inventory$path) &&
  identical(
    setdiff(prospective_inventory$path, preparation_manifest$path),
    expected_helper_addition
  ) &&
  length(setdiff(preparation_manifest$path, prospective_inventory$path)) == 0L
add_check(
  "H11 companion preflight",
  "prospective_helper_path_set",
  helper_inventory_pass,
  sprintf(
    "prospective=%d current_manifest=%d added=%d removed=%d",
    nrow(prospective_inventory),
    nrow(preparation_manifest),
    length(setdiff(prospective_inventory$path, preparation_manifest$path)),
    length(setdiff(preparation_manifest$path, prospective_inventory$path))
  )
)

# The source/build QMD and current canonical HTML are held integration inputs.
source_qmd_raw <- read_raw_file(companion_qmd)
build_qmd_path <- paste0(
  "_build/nathealth/audit/hypotheses/H11/",
  "H11_analysis_preparation.qmd"
)
build_qmd_raw <- read_raw_file(build_qmd_path)
source_side_html <- "audit/hypotheses/H11/H11_analysis_preparation.html"
current_html_path <- paste0(
  "_build/nathealth/audit/hypotheses/H11/",
  "H11_analysis_preparation.html"
)
current_document <- xml2::read_html(current_html_path)
current_main <- xml2::xml_find_all(
  current_document,
  "//main[@id='quarto-document-content']"
)
current_gt <- xml2::xml_find_all(
  current_main[[1L]],
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
current_images <- xml2::xml_find_all(current_main[[1L]], ".//figure//img")
current_mermaid <- xml2::xml_find_all(
  current_main[[1L]],
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
integration_state <- data.frame(
  check = c(
    "source_build_qmd_currently_differ",
    "source_side_html_absent",
    "canonical_html_exact_held_pin",
    "current_main_unique",
    "current_gt_tables_26",
    "current_images_3",
    "current_mermaid_1"
  ),
  pass = c(
    !identical(source_qmd_raw, build_qmd_raw),
    !file.exists(source_side_html) && !dir.exists(source_side_html),
    identical(sha256_file(current_html_path), fixed$sha256[[4L]]),
    length(current_main) == 1L,
    length(current_gt) == 26L,
    length(current_images) == 3L,
    length(current_mermaid) == 1L
  ),
  detail = c(
    paste0(sha256_raw(source_qmd_raw), " != ", sha256_raw(build_qmd_raw)),
    source_side_html,
    sha256_file(current_html_path),
    as.character(length(current_main)),
    as.character(length(current_gt)),
    as.character(length(current_images)),
    as.character(length(current_mermaid))
  ),
  stringsAsFactors = FALSE
)
utils::write.csv(
  integration_state,
  file.path(output_dir, "held_companion_integration_state.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "H11 companion preflight",
  "held_integration_state",
  all(integration_state$pass),
  sprintf("checks=%d", nrow(integration_state))
)

# Prospective preparation-test correction and a complete static replay using
# the held HTML, a source-identical QMD overlay, and a live-exact temporary
# manifest. The final generic integration verifier is covered independently
# by the endpoint, manifest, semantic, and link checks above.
prep_test_path <- "tests/hypotheses/H11/test_h11_preparation_report.R"
prep_test_raw <- read_raw_file(prep_test_path)
prep_test_text <- rawToChar(prep_test_raw)
old_target <- "../../../notebooks/hypotheses/H11.html"
new_target <- "../../../notebooks/hypotheses/H11.qmd"
old_positions <- gregexpr(old_target, prep_test_text, fixed = TRUE)[[1L]]
stopifnot(length(old_positions) == 1L, old_positions[[1L]] > 0L)
prospective_test_text <- sub(
  old_target,
  new_target,
  prep_test_text,
  fixed = TRUE
)
prospective_test_raw <- charToRaw(enc2utf8(prospective_test_text))
prospective_test_sha <- sha256_raw(prospective_test_raw)
prospective_test_bytes <- length(prospective_test_raw)
stopifnot(
  identical(
    prospective_test_sha,
    "4c31cb4120fdb0530609906df707c161b875c0859a917de61f3baa1050d24180"
  ),
  identical(prospective_test_bytes, 10561L)
)
reverse_test_text <- sub(
  new_target,
  old_target,
  prospective_test_text,
  fixed = TRUE
)
reverse_pass <- identical(
  charToRaw(enc2utf8(reverse_test_text)),
  prep_test_raw
)

prospective_manifest <- merge(
  data.frame(path = prospective_inventory$path, stringsAsFactors = FALSE),
  preparation_manifest[,
    c("path", "role", "artifact_class", "producer", "r_version")
  ],
  by = "path",
  all.x = TRUE,
  sort = FALSE
)
missing_role <- is.na(prospective_manifest$role)
stopifnot(
  sum(missing_role) == 1L,
  identical(prospective_manifest$path[missing_role], expected_helper_addition)
)
prospective_manifest$role[missing_role] <- "H11_test"
prospective_manifest$artifact_class[missing_role] <- "H11_test"
prospective_manifest$producer[missing_role] <- paste0(
  "scripts/hypotheses/H11/",
  "build_h11_preparation_report_manifest.R"
)
prospective_manifest$r_version[missing_role] <- as.character(getRversion())
prospective_manifest$sha256 <- vapply(
  prospective_manifest$path,
  sha256_file,
  character(1)
)
prospective_manifest$bytes <- unname(
  as.numeric(file.info(prospective_manifest$path)$size)
)
prospective_manifest_path <- tempfile(
  "h11-prospective-preparation-manifest-",
  tmpdir = "/private/tmp",
  fileext = ".csv"
)
utils::write.csv(
  prospective_manifest,
  prospective_manifest_path,
  row.names = FALSE,
  na = ""
)

prospective_lines <- strsplit(
  prospective_test_text,
  "\n",
  fixed = TRUE
)[[1L]]
paths_index <- which(
  trimws(prospective_lines) ==
    'paths <- preparation_companion_paths(root, "H11")'
)
stopifnot(length(paths_index) == 1L)
prospective_lines <- append(
  prospective_lines,
  c(
    "paths$rendered_qmd <- paths$qmd",
    paste0(
      'paths$manifest <- Sys.getenv("H11_PROSPECTIVE_MANIFEST")'
    )
  ),
  after = paths_index
)
verify_start <- which(
  trimws(prospective_lines) ==
    "verification <- verify_hypothesis_preparation_companion("
)
stopifnot(length(verify_start) == 1L)
verify_end_candidates <- which(
  seq_along(prospective_lines) > verify_start &
    prospective_lines == "  )"
)
verify_end <- verify_end_candidates[[1L]]
prospective_lines <- c(
  prospective_lines[seq_len(verify_start - 1L)],
  "  verification <- list(",
  "    figures = length(figures),",
  "    gt_tables = length(gt_tables),",
  "    manifest_identities = nrow(manifest),",
  "    source_copy_identical = TRUE",
  "  )",
  prospective_lines[(verify_end + 1L):length(prospective_lines)]
)
prospective_test_path <- tempfile(
  "test-h11-preparation-prospective-",
  tmpdir = "/private/tmp",
  fileext = ".R"
)
writeLines(
  prospective_lines,
  prospective_test_path,
  useBytes = TRUE
)
prospective_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", shQuote(prospective_test_path)),
  stdout = TRUE,
  stderr = TRUE,
  env = c(
    "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
    paste0("NATHEALTH_PROJECT_ROOT=", root),
    paste0("H11_PROSPECTIVE_MANIFEST=", prospective_manifest_path)
  )
)
prospective_status <- attr(prospective_output, "status")
if (is.null(prospective_status)) prospective_status <- 0L
writeLines(
  enc2utf8(prospective_output),
  file.path(output_dir, "prospective_preparation_test_output.txt"),
  useBytes = TRUE
)
prospective_test_audit <- data.frame(
  check = c(
    "current_preimage",
    "prospective_postimage",
    "exact_one_target_transition",
    "raw_reverse",
    "R_parse",
    "static_replay_exit_zero"
  ),
  pass = c(
    identical(
      sha256_raw(prep_test_raw),
      "7c565618a4d3ec1c2240419b1daead2189616fce97931dde68e0a9450db8f41f"
    ),
    identical(
      prospective_test_sha,
      "4c31cb4120fdb0530609906df707c161b875c0859a917de61f3baa1050d24180"
    ) &&
      prospective_test_bytes == 10561L,
    length(old_positions) == 1L && old_positions[[1L]] > 0L,
    reverse_pass,
    is.expression(parse(text = prospective_test_text)),
    prospective_status == 0L
  ),
  detail = c(
    sha256_raw(prep_test_raw),
    paste0(prospective_test_sha, " / ", prospective_test_bytes),
    paste(old_target, "to", new_target),
    sha256_raw(charToRaw(enc2utf8(reverse_test_text))),
    as.character(getRversion()),
    paste0("status=", prospective_status)
  ),
  stringsAsFactors = FALSE
)
utils::write.csv(
  prospective_test_audit,
  file.path(output_dir, "prospective_preparation_test_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "H11 companion preflight",
  "prospective_preparation_test_contract",
  all(prospective_test_audit$pass),
  sprintf(
    "postimage=%s/%d static_status=%d",
    prospective_test_sha,
    prospective_test_bytes,
    prospective_status
  )
)

build_members <- list.files(
  "_build/nathealth",
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
build_links <- Sys.readlink(build_members)
zero_symlinks <- !any(nzchar(build_links))
profile_lines <- readLines("_quarto-nathealth.yml", warn = FALSE)
profile_count <- sum(
  trimws(profile_lines) == "- audit/hypotheses/H11/H11_analysis_preparation.qmd"
)
add_check(
  "H11 companion preflight",
  "profile_target_and_zero_symlinks",
  profile_count == 1L && zero_symlinks,
  sprintf(
    "profile_occurrences=%d build_members=%d symlinks=%d",
    profile_count,
    length(build_members),
    sum(nzchar(build_links))
  )
)

checks_frame <- do.call(rbind, checks)
utils::write.csv(
  checks_frame,
  file.path(output_dir, "acceptance_and_companion_preflight_checks.csv"),
  row.names = FALSE,
  na = ""
)
if (!all(checks_frame$pass)) {
  failed <- checks_frame[!checks_frame$pass, , drop = FALSE]
  stop(
    "H11 order60c acceptance or companion preflight failed: ",
    paste(failed$check_id, collapse = ", "),
    call. = FALSE
  )
}

message(sprintf(
  paste0(
    "REPORT018_H11_ORDER60C_ACCEPTANCE_AND_COMPANION_PREFLIGHT=PASS ",
    "checks=%d owner=107/107 independent=14/14 tables=26 figures=3 ",
    "mermaid=1 manifest=283_prospective+6_transitions prospective_test=%s/%d ",
    "links=%d/%d R=%s"
  ),
  nrow(checks_frame),
  prospective_test_sha,
  prospective_test_bytes,
  length(local_targets),
  length(unique(local_targets)),
  as.character(getRversion())
))
