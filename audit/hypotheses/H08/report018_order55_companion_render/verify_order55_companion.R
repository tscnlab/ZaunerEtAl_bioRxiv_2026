#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

assert_none <- function(value, message) {
  if (length(value) && any(value)) stop(message, call. = FALSE)
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)

suppressPackageStartupMessages({
  library(digest)
  library(readr)
  library(rvest)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

stage <- Sys.getenv("ORDER55_STAGE", unset = "postrender")
assert_true(
  stage %in% c("postrender", "postqa"),
  "ORDER55_STAGE must be postrender or postqa"
)

evidence_relative <-
  "audit/hypotheses/H08/report018_order55_companion_render"
evidence_dir <- file.path(root, evidence_relative)
assert_true(dir.exists(evidence_dir), "Order-55 evidence directory is missing")

html_relative <- paste0(
  "_build/nathealth/audit/hypotheses/H08/",
  "H08_analysis_preparation.html"
)
qmd_relative <- "audit/hypotheses/H08/H08_analysis_preparation.qmd"
build_qmd_relative <- paste0(
  "_build/nathealth/audit/hypotheses/H08/",
  "H08_analysis_preparation.qmd"
)
manifest_relative <-
  "artifacts/12_manifests/H08/H08_preparation_report_manifest.csv"
html_path <- file.path(root, html_relative)
qmd_path <- file.path(root, qmd_relative)
build_qmd_path <- file.path(root, build_qmd_relative)
manifest_path <- file.path(root, manifest_relative)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

hash_text <- function(value) {
  digest::digest(enc2utf8(value), algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) unname(file.info(path)$size)

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
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

list_files <- function(path, exclude_prefix = character()) {
  if (!dir.exists(path)) return(character())
  files <- list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE,
    all.files = TRUE,
    no.. = TRUE
  )
  files <- files[file.exists(files) & !dir.exists(files)]
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

inventory_paths <- function(paths) {
  paths <- sort(unique(paths))
  assert_true(length(paths) > 0L, "Inventory is unexpectedly empty")
  assert_all(file.exists(paths), "An inventory member is missing")
  normalized <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  assert_none(file.info(normalized)$isdir, "A directory entered an inventory")
  data.frame(
    path = relative_path(normalized),
    sha256 = unname(vapply(
      normalized,
      sha256_file,
      character(1)
    )),
    bytes = as.numeric(file.info(normalized)$size),
    stringsAsFactors = FALSE
  )
}

clean_text <- function(node) {
  if (!length(node) || inherits(node, "xml_missing")) return("")
  value <- rvest::html_text2(node)
  value <- gsub("[[:space:]]+", " ", value)
  trimws(value)
}

node_text <- function(nodes) {
  if (!length(nodes)) return(character())
  vapply(nodes, clean_text, character(1))
}

outside_source_modal <- function(nodes) {
  if (!length(nodes)) return(logical())
  !vapply(
    nodes,
    function(node) {
      length(xml2::xml_find_all(
        node,
        "ancestor::*[@id='quarto-embedded-source-code-modal']"
      )) > 0L
    },
    logical(1)
  )
}

png_dimensions <- function(path) {
  bytes <- readBin(path, what = "raw", n = 24L)
  assert_true(length(bytes) == 24L, paste("Short PNG:", path))
  signature <- as.integer(bytes[seq_len(8L)])
  assert_true(
    identical(signature, c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L)),
    paste("Invalid PNG signature:", path)
  )
  value <- function(index) {
    sum(as.integer(bytes[index]) * 256^(3:0))
  }
  c(width = value(17:20), height = value(21:24))
}

compare_inventory <- function(before, after, scope) {
  merged <- merge(
    before[, c("path", "sha256", "bytes")],
    after[, c("path", "sha256", "bytes")],
    by = "path",
    all = TRUE,
    suffixes = c("_before", "_after")
  )
  merged$exact <- !is.na(merged$sha256_before) &
    !is.na(merged$sha256_after) &
    merged$sha256_before == merged$sha256_after &
    merged$bytes_before == merged$bytes_after
  merged$scope <- scope
  merged
}

expected_tables <- c(
  "tbl-h08-prep-input-identities",
  "tbl-h08-prep-integrity-checks",
  "tbl-h08-prep-score-audit",
  "tbl-h08-prep-metric-contract",
  "tbl-h08-prep-availability",
  "tbl-h08-prep-primary-samples",
  "tbl-h08-prep-site-support",
  "tbl-h08-prep-exact-formulas",
  "tbl-h08-prep-model-settings",
  "tbl-h08-prep-family-audit",
  "tbl-h08-prep-response-gate",
  "tbl-h08-prep-site-influence",
  "tbl-h08-prep-sensitivity-map",
  "tbl-h08-prep-boundary",
  "tbl-h08-prep-metric011",
  "tbl-h08-prep-module-map",
  "tbl-h08-prep-script-map",
  "tbl-h08-prep-output-identities",
  "tbl-h08-prep-environment"
)

expected_table_rows <- c(
  14L, 11L, 1L, 9L, 10L, 20L, 19L, 12L, 9L, 8L,
  9L, 18L, 8L, 5L, 5L, 6L, 8L, 13L, 8L
)

expected_figures <- c(
  "fig-h08-prep-vlsq-distribution",
  "fig-h08-prep-sample-support",
  "fig-h08-prep-site-range"
)

expected_figure_paths <- c(
  paste0(
    "_build/nathealth/audit/hypotheses/H08/",
    "H08_analysis_preparation_files/figure-html/",
    "fig-h08-prep-vlsq-distribution-1.png"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H08/",
    "H08_analysis_preparation_files/figure-html/",
    "fig-h08-prep-sample-support-1.png"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H08/",
    "H08_analysis_preparation_files/figure-html/",
    "fig-h08-prep-site-range-1.png"
  )
)

expected_figure_sources <- c(
  "../../../artifacts/11_source_data/H08/H08_preparation_vlsq_score_distribution.csv",
  "../../../artifacts/11_source_data/H08/H08_preparation_sample_support.csv",
  "../../../artifacts/11_source_data/H08/H08_preparation_site_support_summary.csv"
)

expected_formulas <- c(
  "response_value ~ site + (1 | site:Id)",
  "response_value ~ site + VLSQ8_c + (1 | site:Id)",
  "response_value ~ site * VLSQ8_c + (1 | site:Id)",
  "response_value ~ site + photoperiod_c + (1 | site:Id)",
  "response_value ~ site + photoperiod_c + VLSQ8_c + (1 | site:Id)",
  "response_value ~ site * VLSQ8_c + photoperiod_c + (1 | site:Id)",
  "participant_response ~ site",
  "participant_response ~ site + VLSQ8_c",
  "participant_response ~ site * VLSQ8_c"
)

expected_model_setting_labels <- c(
  "Gaussian outcomes",
  "Non-negative duration outcomes",
  "Site adjustment",
  "Repeated observations",
  "Site-average association test",
  "VLSQ-8-by-site interaction test",
  "Practical estimand",
  "Uncertainty",
  "Multiplicity"
)

assert_true(file.exists(html_path), "Fresh companion HTML is missing")
assert_true(
  sha256_file(html_path) ==
    "cd0ce2210949559408d07bcbccac502d3b0a372b4229da70bdfc6dbe0c52f66b" &&
    file_bytes(html_path) == 732155,
  "Fresh companion HTML identity differs"
)
assert_true(
  sha256_file(qmd_path) ==
    "3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d" &&
    sha256_file(build_qmd_path) ==
    "3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d",
  "Companion source or build copy differs"
)
assert_true(
  identical(
    readBin(qmd_path, "raw", n = file_bytes(qmd_path)),
    readBin(build_qmd_path, "raw", n = file_bytes(build_qmd_path))
  ),
  "Companion source and build copy are not byte-identical"
)
assert_true(
  !file.exists(file.path(
    root,
    "audit/hypotheses/H08/H08_analysis_preparation.html"
  )),
  "Source-side companion HTML exists"
)

execution <- read.csv(
  file.path(evidence_dir, "render_execution.csv"),
  check.names = FALSE
)
assert_true(nrow(execution) == 2L, "Execution record must have two rows")
assert_true(
  identical(
    execution$operation,
    c("companion_quarto_render", "preparation_manifest_helper")
  ) &&
    all(execution$attempts == 1L) &&
    all(execution$exit_status == 0L) &&
    all(execution$status == "PASS") &&
    execution$output_sha256[[1L]] == sha256_file(html_path) &&
    execution$output_sha256[[2L]] == sha256_file(manifest_path),
  "Render or helper execution record differs"
)

historical_tests <- data.frame(
  path = c(
    "tests/hypotheses/H08/test_h08_preparation_report.R",
    "tests/hypotheses/H08/test_h08_stage3_reader_report.R"
  ),
  expected_sha256 = c(
    "2e83542b120021e0c337a3769127e6eba2fe61ebc4d56014693b34066a3fc2a4",
    "3049ecd80bc7f6c83dce7370b2877a92c6693dd9585f1f45ed7ac19fdf64be8f"
  ),
  executed = FALSE,
  stringsAsFactors = FALSE
)
historical_tests$current_sha256 <- vapply(
  file.path(root, historical_tests$path),
  sha256_file,
  character(1)
)
historical_tests$status <- ifelse(
  historical_tests$current_sha256 == historical_tests$expected_sha256 &
    !historical_tests$executed,
  "PASS",
  "FAIL"
)
assert_all(historical_tests$status == "PASS", "A historical H08 test changed")
write_evidence(historical_tests, "historical_test_audit.csv")

pins <- read.csv(
  file.path(
    root,
    "audit/report_harmonization/report018_h08_companion_release_pins.csv"
  ),
  check.names = FALSE
)
assert_true(nrow(pins) == 34L, "Release pin set must have 34 rows")
pin_files <- file.path(root, pins$relative_path)
pin_exists <- file.exists(pin_files) & !dir.exists(pin_files)
pin_sha <- rep(NA_character_, nrow(pins))
pin_bytes <- rep(NA_real_, nrow(pins))
pin_sha[pin_exists] <- unname(vapply(
  pin_files[pin_exists],
  sha256_file,
  character(1)
))
pin_bytes[pin_exists] <- as.numeric(file.info(pin_files[pin_exists])$size)
pin_exact <- pin_exists & pin_sha == pins$sha256 &
  pin_bytes == as.numeric(pins$bytes)
expected_pin_transitions <- c(
  "stale_build_companion_source",
  "stale_companion_html",
  "current_preparation_manifest",
  "stale_sample_support_png"
)
pin_status <- ifelse(
  pins$role %in% expected_pin_transitions,
  !pin_exact,
  pin_exact
)
pin_audit <- data.frame(
  role = pins$role,
  path = pins$relative_path,
  expected_sha256 = pins$sha256,
  current_sha256 = pin_sha,
  expected_bytes = pins$bytes,
  current_bytes = pin_bytes,
  classification = ifelse(
    pins$role %in% expected_pin_transitions,
    "authorized historical-to-fresh transition",
    "hard pin preserved"
  ),
  status = ifelse(pin_status, "PASS", "FAIL")
)
assert_all(pin_audit$status == "PASS", "A post-render release pin failed")
assert_true(
  setequal(pins$role[!pin_exact], expected_pin_transitions),
  "Post-render pin transition set differs"
)
write_evidence(pin_audit, paste0("release_pin_reconciliation_", stage, ".csv"))

result_acceptance_relative <-
  "audit/report_harmonization/report018_h08_result_independent_acceptance_manifest.csv"
result_acceptance <- read.csv(
  file.path(root, result_acceptance_relative),
  check.names = FALSE
)
result_files <- file.path(root, result_acceptance$path)
result_exact <- file.exists(result_files) & !dir.exists(result_files) &
  unname(vapply(result_files, sha256_file, character(1))) ==
    result_acceptance$sha256 &
  as.numeric(file.info(result_files)$size) ==
    as.numeric(result_acceptance$bytes)
result_historical_transition <- result_acceptance$path == html_relative
assert_true(
  nrow(result_acceptance) == 31L &&
    !anyDuplicated(result_acceptance$path) &&
    !result_acceptance_relative %in% result_acceptance$path &&
    sum(result_exact) == 30L &&
    identical(
      result_acceptance$path[!result_exact],
      html_relative
    ) &&
    all(result_exact | result_historical_transition),
  "Accepted result package differs"
)
write_evidence(
  data.frame(
    path = result_acceptance$path,
    historical_sha256 = result_acceptance$sha256,
    current_sha256 = vapply(result_files, sha256_file, character(1)),
    historical_bytes = result_acceptance$bytes,
    current_bytes = as.numeric(file.info(result_files)$size),
    classification = ifelse(
      result_historical_transition,
      "authorized companion historical-to-fresh transition",
      "accepted result package member remains exact"
    ),
    status = ifelse(
      result_exact | result_historical_transition,
      "PASS",
      "FAIL"
    )
  ),
  paste0("result_acceptance_reconciliation_", stage, ".csv")
)

manifest <- read.csv(manifest_path, check.names = FALSE)
assert_true(nrow(manifest) == 258L, "Preparation manifest must have 258 rows")
assert_true(!anyDuplicated(manifest$path), "Preparation manifest paths duplicate")
assert_true(!manifest_relative %in% manifest$path, "Preparation manifest is circular")
assert_none(
  grepl("report018_order55_companion_render", manifest$path, fixed = TRUE),
  "Preparation manifest contains order-55 evidence"
)
manifest_files <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- unname(vapply(
  manifest_files[manifest_exists],
  sha256_file,
  character(1)
))
manifest_bytes[manifest_exists] <- as.numeric(
  file.info(manifest_files[manifest_exists])$size
)
manifest_exact <- manifest_exists & manifest_sha == manifest$sha256 &
  manifest_bytes == as.numeric(manifest$bytes)
assert_all(manifest_exact, "A preparation manifest member is not live exact")
manifest_audit <- data.frame(
  path = manifest$path,
  role = manifest$role,
  expected_sha256 = manifest$sha256,
  current_sha256 = manifest_sha,
  expected_bytes = manifest$bytes,
  current_bytes = manifest_bytes,
  live_exact = manifest_exact,
  status = "PASS"
)
write_evidence(
  manifest_audit,
  paste0("preparation_manifest_", stage, "_audit.csv")
)

build_root <- file.path(root, "_build/nathealth")
build_entries <- list.files(
  build_root,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
build_symlinks <- build_entries[nzchar(Sys.readlink(build_entries))]
assert_true(!length(build_symlinks), "Build contains a symlink")
build_files <- build_entries[file.exists(build_entries) & !dir.exists(build_entries)]
build_inventory <- inventory_paths(build_files)
assert_true(nrow(build_inventory) == 851L, "Build file count differs")
write_evidence(build_inventory, paste0("build_inventory_", stage, ".csv"))
write_evidence(
  data.frame(path = relative_path(build_symlinks)),
  paste0("build_symlink_inventory_", stage, ".csv")
)

protected_pre <- read.csv(
  file.path(evidence_dir, "protected_inventory_prerender.csv"),
  check.names = FALSE
)
protected_paths <- file.path(root, protected_pre$path)
protected_inventory <- inventory_paths(protected_paths)
assert_true(
  nrow(protected_inventory) == nrow(protected_pre),
  "Protected inventory row count differs"
)
write_evidence(
  protected_inventory,
  paste0("protected_inventory_", stage, ".csv")
)

source_data_contract <- c(
  "artifacts/11_source_data/H08/H08_preparation_sample_support.csv" = 18L,
  "artifacts/11_source_data/H08/H08_preparation_vlsq_score_distribution.csv" = 24L,
  "artifacts/11_source_data/H08/H08_preparation_vlsq_site_support.csv" = 9L,
  "artifacts/11_source_data/H08/H08_preparation_site_support.csv" = 153L,
  "artifacts/11_source_data/H08/H08_preparation_site_support_summary.csv" = 17L,
  "artifacts/11_source_data/H08/H08_preparation_metric_availability.csv" = 56L
)
source_rows <- vapply(names(source_data_contract), function(path) {
  nrow(read.csv(file.path(root, path), check.names = FALSE))
}, integer(1))
source_data_audit <- data.frame(
  path = names(source_data_contract),
  observed_rows = unname(source_rows),
  expected_rows = unname(source_data_contract),
  status = ifelse(
    unname(source_rows) == unname(source_data_contract),
    "PASS",
    "FAIL"
  )
)
assert_all(source_data_audit$status == "PASS", "A source-data row count differs")
write_evidence(source_data_audit, "source_data_contract_audit.csv")

score_distribution <- read.csv(
  file.path(
    root,
    "artifacts/11_source_data/H08/H08_preparation_vlsq_score_distribution.csv"
  ),
  check.names = FALSE
)
score_sites <- read.csv(
  file.path(
    root,
    "artifacts/11_source_data/H08/H08_preparation_vlsq_site_support.csv"
  ),
  check.names = FALSE
)
sample_support <- read.csv(
  file.path(
    root,
    "artifacts/11_source_data/H08/H08_preparation_sample_support.csv"
  ),
  check.names = FALSE
)
score_audit <- data.frame(
  check = c(
    "score rows",
    "score participants",
    "score range",
    "score percentages",
    "site rows",
    "site participants",
    "sample-support rows",
    "sample-support metric-placement cells"
  ),
  observed = c(
    nrow(score_distribution),
    sum(score_distribution$participants),
    paste(range(score_distribution$stored_VLSQ8), collapse = ":"),
    sprintf("%.12f", sum(score_distribution$percentage)),
    nrow(score_sites),
    sum(score_sites$participants),
    nrow(sample_support),
    nrow(unique(sample_support[c("metric_order", "placement")]))
  ),
  expected = c("24", "184", "13:39", "100.000000000000", "9", "184", "18", "18"),
  stringsAsFactors = FALSE
)
score_audit$status <- ifelse(score_audit$observed == score_audit$expected, "PASS", "FAIL")
assert_all(score_audit$status == "PASS", "Stored VLSQ-8 or sample-support audit differs")
write_evidence(score_audit, "score_and_sample_support_audit.csv")

family_audit <- read.csv(
  file.path(root, "artifacts/09_tables/H08/H08_family_audit.csv"),
  check.names = FALSE
)
family_pass <- nrow(family_audit) == 8L &&
  all(family_audit$planned_n == 9L) &&
  all(family_audit$observed_raw_p == 9L) &&
  all(family_audit$complete_nine_member_family) &&
  all(family_audit$independent_recalculation_matches) &&
  sum(family_audit$adjusted_significant_n) == 0L
assert_true(family_pass, "Stored FDR family contract differs")
write_evidence(
  data.frame(
    families = nrow(family_audit),
    planned_tests = sum(family_audit$planned_n),
    adjusted_significant = sum(family_audit$adjusted_significant_n),
    complete = all(family_audit$complete_nine_member_family),
    independently_reproduced = all(family_audit$independent_recalculation_matches),
    status = "PASS"
  ),
  "fdr_family_contract_audit.csv"
)

qa_path <-
  file.path(root, "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv")
assert_true(
  sha256_file(qa_path) ==
    "f4680525e3252153bf3020caf436fd6eb701dd9fa21d2c34011ce5799636670b",
  "Physical-size QA manifest changed"
)
figure_qa <- read.csv(qa_path, check.names = FALSE)
companion_qa <- figure_qa[
  match(expected_figures, figure_qa$figure_id),
  ,
  drop = FALSE
]
assert_true(
  nrow(companion_qa) == 3L &&
    identical(companion_qa$figure_id, expected_figures),
  "Companion figure QA rows differ"
)
proof_files <- file.path(root, companion_qa$a4_proof_path)
proof_exact <- vapply(proof_files, sha256_file, character(1)) ==
  companion_qa$a4_proof_sha256
assert_true(
  all(proof_exact) &&
    all(companion_qa$effective_final_essential_text_pt >= 7) &&
    all(companion_qa$status == "PASS"),
  "Companion physical-size baseline differs"
)

target_files <- file.path(root, expected_figure_paths)
target_dimensions <- t(vapply(target_files, png_dimensions, numeric(2)))
target_hashes <- vapply(target_files, sha256_file, character(1))
target_bytes <- as.numeric(file.info(target_files)$size)
target_transition <- data.frame(
  figure_id = expected_figures,
  path = expected_figure_paths,
  historical_sha256 = companion_qa$figure_sha256,
  current_sha256 = target_hashes,
  historical_bytes = companion_qa$figure_bytes,
  current_bytes = target_bytes,
  width_px = target_dimensions[, "width"],
  expected_width_px = companion_qa$pixel_width,
  height_px = target_dimensions[, "height"],
  expected_height_px = companion_qa$pixel_height,
  source_data_path = companion_qa$source_data_path,
  source_data_live_exact = TRUE,
  geometry_exact = target_dimensions[, "width"] == companion_qa$pixel_width &
    target_dimensions[, "height"] == companion_qa$pixel_height,
  transition = ifelse(
    target_hashes == companion_qa$figure_sha256,
    "byte-identical historical target",
    "authorized target-resource byte transition requiring visual equivalence"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
assert_all(target_transition$geometry_exact, "A target PNG geometry differs")
assert_true(
  identical(
    target_transition$current_sha256 != target_transition$historical_sha256,
    c(FALSE, TRUE, FALSE)
  ),
  "Target PNG transition set differs"
)
write_evidence(target_transition, "target_png_transition_audit.csv")
write_evidence(companion_qa, "figure_final_size_typography_audit.csv")

phase4_path <- file.path(
  root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
assert_true(
  sha256_file(phase4_path) ==
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
  "Phase-4 corpus manifest changed"
)
phase4 <- read.csv(phase4_path, check.names = FALSE)
h08_phase4 <- phase4[phase4$source %in% c(
  "notebooks/hypotheses/H08.qmd",
  qmd_relative
), , drop = FALSE]
phase4_fresh <- vapply(
  file.path(root, h08_phase4$expected_html),
  sha256_file,
  character(1)
)
phase4_audit <- data.frame(
  source = h08_phase4$source,
  source_manifest_sha256 = h08_phase4$source_sha256,
  source_current_sha256 = vapply(
    file.path(root, h08_phase4$source),
    sha256_file,
    character(1)
  ),
  html_historical_sha256 = h08_phase4$html_sha256,
  html_current_sha256 = phase4_fresh,
  classification = "byte-identical historical manifest with accepted fresh page",
  status = "PASS"
)
assert_true(nrow(phase4_audit) == 2L, "Phase-4 H08 rows differ")
assert_all(
  phase4_audit$source_manifest_sha256 == phase4_audit$source_current_sha256,
  "A phase-4 H08 source differs"
)
assert_true(
  setequal(
    phase4_audit$html_historical_sha256,
    c(
      "a08a888a40ec58669c61a47b7500159388577eaad49ece5440b9bee9da6a93e1",
      "95f5ba0aede0ee6cf0d1b65fcdc53623d52810f8316c846cb214b4fb34a5f135"
    )
  ) &&
    setequal(
      phase4_audit$html_current_sha256,
      c(
        "472848d0da3e3996fa1727151048e3cab4a7e363dba3dc8eda8b024eb5a4ca9a",
        "cd0ce2210949559408d07bcbccac502d3b0a372b4229da70bdfc6dbe0c52f66b"
      )
    ),
  "Phase-4 historical-to-current classification differs"
)
write_evidence(phase4_audit, "phase4_manifest_transition_audit.csv")

stage3_path <- file.path(
  root,
  "artifacts/12_manifests/H08/H08_stage3_artifacts.csv"
)
assert_true(
  sha256_file(stage3_path) ==
    "e8dcec4bfdaf129002c875681f22b0f9d226ebbc95f706309c98ae4e21244af2",
  "Historical Stage 3 manifest changed"
)
stage3 <- read.csv(stage3_path, check.names = FALSE)
stage3_files <- file.path(root, stage3$path)
stage3_exists <- file.exists(stage3_files) & !dir.exists(stage3_files)
stage3_sha <- rep(NA_character_, nrow(stage3))
stage3_bytes <- rep(NA_real_, nrow(stage3))
stage3_sha[stage3_exists] <- vapply(
  stage3_files[stage3_exists],
  sha256_file,
  character(1)
)
stage3_bytes[stage3_exists] <- as.numeric(file.info(stage3_files[stage3_exists])$size)
stage3_exact <- stage3_exists & stage3_sha == stage3$sha256 &
  stage3_bytes == stage3$bytes
stage3_expected_historical <- c(
  "notebooks/hypotheses/H08.qmd",
  "_quarto-nathealth.yml",
  "_build/nathealth/notebooks/hypotheses/H08.html"
)
assert_true(
  nrow(stage3) == 102L &&
    sum(stage3_exact) == 99L &&
    setequal(stage3$path[!stage3_exact], stage3_expected_historical),
  "Historical Stage 3 manifest classification differs"
)
write_evidence(
  data.frame(
    path = stage3$path,
    live_exact = stage3_exact,
    classification = ifelse(
      stage3_exact,
      "live exact",
      "accepted historical transition"
    ),
    status = "PASS"
  ),
  "stage3_manifest_historical_audit.csv"
)

if (identical(stage, "postrender")) {
  semantic_summary_path <- file.path(
    evidence_dir,
    "gt_html_semantic_post_render_summary.csv"
  )
  semantic_summary <- read.csv(semantic_summary_path, check.names = FALSE)
  assert_true(nrow(semantic_summary) == 1L, "Semantic summary must have one row")
  assert_true(
    semantic_summary$target == html_relative &&
      semantic_summary$disposition == "REPAIRED" &&
      semantic_summary$post_sha256 == sha256_file(html_path) &&
      semantic_summary$post_bytes == file_bytes(html_path) &&
      semantic_summary$table_count == 19L &&
      semantic_summary$id_count == 193L &&
      semantic_summary$headers_count == 878L &&
      semantic_summary$total_substitutions == 1071L,
    "Semantic summary differs"
  )
  ledger_path <- file.path(evidence_dir, semantic_summary$ledger_file)
  assert_true(file.exists(ledger_path), "Semantic ledger is missing")
  ledger <- read.csv(ledger_path, check.names = FALSE)
  assert_true(
    nrow(ledger) == 1071L &&
      sum(ledger$attribute == "id") == 193L &&
      sum(ledger$attribute == "headers") == 878L &&
      setequal(unique(ledger$table_endpoint), expected_tables),
    "Semantic ledger coverage differs"
  )

  engine <- new.env(parent = globalenv())
  sys.source(
    file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
    envir = engine
  )
  final_raw <- engine$read_file_raw(html_path)
  reversed_raw <- engine$apply_raw_replacements(
    final_raw,
    ledger,
    reverse = TRUE
  )
  reapplied_raw <- engine$apply_raw_replacements(
    reversed_raw,
    ledger,
    reverse = FALSE
  )
  semantic_reverse <- data.frame(
    check = c(
      "summary post hash equals final HTML",
      "reverse hash equals pre-hook hash",
      "forward reapplication equals final HTML",
      "ledger rows equal substitutions",
      "ledger IDs equal summary",
      "ledger headers equal summary",
      "all 19 table endpoints represented"
    ),
    observed = c(
      engine$sha256_raw(final_raw),
      engine$sha256_raw(reversed_raw),
      engine$sha256_raw(reapplied_raw),
      nrow(ledger),
      sum(ledger$attribute == "id"),
      sum(ledger$attribute == "headers"),
      length(unique(ledger$table_endpoint))
    ),
    expected = c(
      semantic_summary$post_sha256,
      semantic_summary$pre_sha256,
      semantic_summary$post_sha256,
      semantic_summary$total_substitutions,
      semantic_summary$id_count,
      semantic_summary$headers_count,
      19L
    ),
    stringsAsFactors = FALSE
  )
  semantic_reverse$status <- ifelse(
    semantic_reverse$observed == semantic_reverse$expected,
    "PASS",
    "FAIL"
  )
  assert_all(semantic_reverse$status == "PASS", "Semantic reverse audit failed")
  assert_true(identical(final_raw, reapplied_raw), "Semantic reapplication differs")
  write_evidence(semantic_reverse, "semantic_reverse_audit.csv")

  pre_document <- xml2::read_html(rawToChar(reversed_raw))
  document <- xml2::read_html(rawToChar(final_raw))
  pre_main_nodes <- rvest::html_elements(pre_document, "main#quarto-document-content")
  main_nodes <- rvest::html_elements(document, "main#quarto-document-content")
  assert_true(length(pre_main_nodes) == 1L, "Pre-hook main is not unique")
  assert_true(length(main_nodes) == 1L, "Post-hook main is not unique")
  pre_main <- pre_main_nodes[[1L]]
  main <- main_nodes[[1L]]

  pre_elements <- xml2::xml_find_all(pre_document, "//*")
  post_elements <- xml2::xml_find_all(document, "//*")
  pre_links <- xml2::xml_attr(
    xml2::xml_find_all(pre_document, "//a[@href]"),
    "href"
  )
  post_links <- xml2::xml_attr(
    xml2::xml_find_all(document, "//a[@href]"),
    "href"
  )
  pre_captions <- node_text(rvest::html_elements(
    pre_main,
    "figcaption.quarto-float-caption"
  ))
  post_captions <- node_text(rvest::html_elements(
    main,
    "figcaption.quarto-float-caption"
  ))
  pre_notes <- node_text(rvest::html_elements(pre_main, ".gt_sourcenotes"))
  post_notes <- node_text(rvest::html_elements(main, ".gt_sourcenotes"))
  semantic_invariance <- data.frame(
    check = c(
      "normalized DOM excluding repaired gt attributes",
      "whole-document visible text",
      "main visible text and values",
      "element tag sequence",
      "link target sequence",
      "caption sequence",
      "source-note sequence"
    ),
    pre_value = c(
      hash_text(engine$normalized_dom_without_mutable_values(pre_document)),
      hash_text(xml2::xml_text(pre_document)),
      hash_text(xml2::xml_text(pre_main)),
      hash_text(paste(xml2::xml_name(pre_elements), collapse = "|")),
      hash_text(paste(pre_links, collapse = "|")),
      hash_text(paste(pre_captions, collapse = "|")),
      hash_text(paste(pre_notes, collapse = "|"))
    ),
    post_value = c(
      hash_text(engine$normalized_dom_without_mutable_values(document)),
      hash_text(xml2::xml_text(document)),
      hash_text(xml2::xml_text(main)),
      hash_text(paste(xml2::xml_name(post_elements), collapse = "|")),
      hash_text(paste(post_links, collapse = "|")),
      hash_text(paste(post_captions, collapse = "|")),
      hash_text(paste(post_notes, collapse = "|"))
    ),
    stringsAsFactors = FALSE
  )
  semantic_invariance$status <- ifelse(
    semantic_invariance$pre_value == semantic_invariance$post_value,
    "PASS",
    "FAIL"
  )
  assert_all(
    semantic_invariance$status == "PASS",
    "Semantic hook changed visible or structural content"
  )
  write_evidence(semantic_invariance, "semantic_invariance_audit.csv")

  # normalized_dom_without_mutable_values intentionally mutates its XML input.
  # Reparse the unchanged final bytes before document-level identity checks.
  document <- xml2::read_html(rawToChar(final_raw))
  main_nodes <- rvest::html_elements(document, "main#quarto-document-content")
  assert_true(length(main_nodes) == 1L, "Reparsed post-hook main is not unique")
  main <- main_nodes[[1L]]

  ids <- xml2::xml_attr(xml2::xml_find_all(document, "//*[@id]"), "id")
  duplicate_ids <- unique(ids[duplicated(ids)])
  write_evidence(
    data.frame(duplicate_id = duplicate_ids),
    "duplicate_id_audit.csv"
  )
  assert_true(length(duplicate_ids) == 0L, "Rendered HTML has duplicate IDs")

  table_endpoints <- rvest::html_elements(
    main,
    '.quarto-float[id^="tbl-h08-"]'
  )
  table_endpoints <- table_endpoints[outside_source_modal(table_endpoints)]
  table_ids <- rvest::html_attr(table_endpoints, "id")
  assert_true(
    identical(table_ids, expected_tables),
    "Rendered table endpoint order differs"
  )
  table_audit <- do.call(rbind, lapply(seq_along(table_endpoints), function(index) {
    endpoint <- table_endpoints[[index]]
    table <- rvest::html_elements(endpoint, "table.gt_table")
    captions <- rvest::html_elements(endpoint, "figcaption.quarto-float-caption")
    notes <- rvest::html_elements(endpoint, ".gt_sourcenotes")
    cells <- rvest::html_elements(table, "thead th, tbody th, tbody td")
    labels <- rvest::html_elements(table, "thead th, tbody th")
    data.frame(
      order = index,
      endpoint = table_ids[[index]],
      native_gt_count = length(table),
      caption_count = length(captions),
      caption = clean_text(captions),
      body_rows = length(rvest::html_elements(table, "tbody tr")),
      expected_body_rows = expected_table_rows[[index]],
      cell_count = length(cells),
      label_count = length(labels),
      note_count = length(notes),
      notes_nonempty = !length(notes) || all(nzchar(node_text(notes))),
      status = ifelse(
        length(table) == 1L &&
          length(captions) == 1L &&
          nzchar(clean_text(captions)) &&
          length(rvest::html_elements(table, "tbody tr")) ==
            expected_table_rows[[index]] &&
          length(cells) > 0L &&
          length(labels) > 0L &&
          (!length(notes) || all(nzchar(node_text(notes)))),
        "PASS",
        "FAIL"
      ),
      stringsAsFactors = FALSE
    )
  }))
  assert_true(nrow(table_audit) == 19L, "Rendered table count differs")
  assert_all(table_audit$status == "PASS", "A rendered table endpoint failed")
  write_evidence(table_audit, "table_endpoint_audit.csv")

  formula_table <- rvest::html_element(
    table_endpoints[[match("tbl-h08-prep-exact-formulas", table_ids)]],
    "table.gt_table"
  )
  formula_cells <- node_text(rvest::html_elements(formula_table, "tbody th, tbody td"))
  observed_formulas <- formula_cells[
    startsWith(formula_cells, "response_value ~") |
      startsWith(formula_cells, "participant_response ~")
  ]
  formula_audit <- data.frame(
    order = seq_along(expected_formulas),
    observed = observed_formulas,
    expected = expected_formulas,
    status = ifelse(observed_formulas == expected_formulas, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
  assert_true(nrow(formula_audit) == 9L, "Exact formula row count differs")
  assert_all(formula_audit$status == "PASS", "An exact formula differs")
  write_evidence(formula_audit, "exact_formula_table_audit.csv")

  model_table <- rvest::html_element(
    table_endpoints[[match("tbl-h08-prep-model-settings", table_ids)]],
    "table.gt_table"
  )
  model_rows <- rvest::html_elements(model_table, "tbody tr")
  model_labels <- vapply(model_rows, function(row) {
    clean_text(rvest::html_element(row, "th, td"))
  }, character(1))
  model_text <- clean_text(model_table)
  model_setting_audit <- data.frame(
    check = c(
      "row labels",
      "lme4 maximum likelihood",
      "glmmTMB Tweedie log link",
      "sum-to-zero site contrasts",
      "participant nested within site",
      "separate likelihood-ratio tests",
      "one-SD practical estimand",
      "two-sided 95% interval",
      "complete-family FDR"
    ),
    observed = c(
      paste(model_labels, collapse = "|"),
      grepl("lme4::lmer, maximum likelihood", model_text, fixed = TRUE),
      grepl("glmmTMB::glmmTMB, Tweedie family with log link", model_text, fixed = TRUE),
      grepl("sum-to-zero contrasts", model_text, fixed = TRUE),
      grepl("participant nested within site", model_text, fixed = TRUE),
      sum(grepl("Likelihood-ratio test", node_text(model_rows), fixed = TRUE)),
      grepl("one participant VLSQ-8 SD", model_text, fixed = TRUE),
      grepl("Two-sided 95% Wald confidence interval", model_text, fixed = TRUE),
      grepl("complete nine-test family", model_text, fixed = TRUE)
    ),
    expected = c(
      paste(expected_model_setting_labels, collapse = "|"),
      "TRUE", "TRUE", "TRUE", "TRUE", "2", "TRUE", "TRUE", "TRUE"
    ),
    stringsAsFactors = FALSE
  )
  model_setting_audit$status <- ifelse(
    model_setting_audit$observed == model_setting_audit$expected,
    "PASS",
    "FAIL"
  )
  assert_all(model_setting_audit$status == "PASS", "A model setting differs")
  write_evidence(model_setting_audit, "model_setting_audit.csv")

  tables <- rvest::html_elements(main, "table.gt_table")
  header_rows <- list()
  header_index <- 0L
  for (table_index in seq_along(tables)) {
    table <- tables[[table_index]]
    endpoint <- expected_tables[[table_index]]
    header_nodes <- rvest::html_elements(table, "[headers]")
    for (node in header_nodes) {
      tokens <- strsplit(
        rvest::html_attr(node, "headers"),
        "[[:space:]]+"
      )[[1L]]
      tokens <- tokens[nzchar(tokens)]
      for (token in tokens) {
        header_index <- header_index + 1L
        local_matches <- xml2::xml_find_all(
          table,
          sprintf(".//th[@id='%s']", token)
        )
        document_matches <- xml2::xml_find_all(
          document,
          sprintf("//th[@id='%s']", token)
        )
        header_rows[[header_index]] <- data.frame(
          endpoint = endpoint,
          token = token,
          local_resolution_count = length(local_matches),
          document_resolution_count = length(document_matches),
          status = ifelse(
            length(local_matches) == 1L && length(document_matches) == 1L,
            "PASS",
            "FAIL"
          ),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  header_audit <- do.call(rbind, header_rows)
  assert_true(nrow(header_audit) > 0L, "No headers tokens were rendered")
  assert_all(header_audit$status == "PASS", "A headers token does not resolve")
  write_evidence(header_audit, "table_header_reference_audit.csv")

  figure_endpoints <- rvest::html_elements(
    main,
    '.quarto-float[id^="fig-h08-"]'
  )
  figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
  figure_ids <- rvest::html_attr(figure_endpoints, "id")
  assert_true(
    identical(figure_ids, expected_figures),
    "Rendered figure endpoint order differs"
  )
  hrefs <- rvest::html_attr(rvest::html_elements(main, "a[href]"), "href")
  figure_audit <- do.call(rbind, lapply(seq_along(figure_endpoints), function(index) {
    endpoint <- figure_endpoints[[index]]
    image <- rvest::html_element(endpoint, "img")
    captions <- rvest::html_elements(endpoint, "figcaption.quarto-float-caption")
    src <- rvest::html_attr(image, "src")
    resolved <- normalizePath(
      file.path(dirname(html_path), utils::URLdecode(src)),
      winslash = "/",
      mustWork = TRUE
    )
    data.frame(
      order = index,
      endpoint = figure_ids[[index]],
      image_src = src,
      resolved_path = relative_path(resolved),
      image_sha256 = sha256_file(resolved),
      image_alt = rvest::html_attr(image, "alt"),
      caption = clean_text(captions),
      source_target = expected_figure_sources[[index]],
      source_link_present = expected_figure_sources[[index]] %in% hrefs,
      status = ifelse(
        relative_path(resolved) == expected_figure_paths[[index]] &&
          nzchar(rvest::html_attr(image, "alt")) &&
          length(captions) == 1L &&
          nzchar(clean_text(captions)) &&
          expected_figure_sources[[index]] %in% hrefs,
        "PASS",
        "FAIL"
      ),
      stringsAsFactors = FALSE
    )
  }))
  assert_true(nrow(figure_audit) == 3L, "Rendered figure count differs")
  assert_all(figure_audit$status == "PASS", "A rendered figure endpoint failed")
  write_evidence(figure_audit, "figure_endpoint_audit.csv")

  mermaid_nodes <- rvest::html_elements(main, ".mermaid")
  mermaid_text <- clean_text(mermaid_nodes)
  mermaid_audit <- data.frame(
    check = c(
      "single Mermaid endpoint",
      "top-down declaration",
      "verified VLSQ-8 input",
      "personal light-exposure input",
      "nine metric frames",
      "site-average and interaction outputs"
    ),
    observed = c(
      length(mermaid_nodes),
      startsWith(mermaid_text, "flowchart TD"),
      grepl("Verified VLSQ-8 scores", mermaid_text, fixed = TRUE),
      grepl("Verified personal light exposure", mermaid_text, fixed = TRUE),
      grepl("Nine metric-specific", mermaid_text, fixed = TRUE),
      grepl("Site-average association", mermaid_text, fixed = TRUE) &&
        grepl("VLSQ-8-by-site interaction", mermaid_text, fixed = TRUE)
    ),
    expected = c("1", "1", "1", "1", "1", "1"),
    stringsAsFactors = FALSE
  )
  mermaid_audit$status <- ifelse(
    mermaid_audit$observed == mermaid_audit$expected,
    "PASS",
    "FAIL"
  )
  assert_all(mermaid_audit$status == "PASS", "Rendered Mermaid contract differs")
  write_evidence(mermaid_audit, "mermaid_endpoint_audit.csv")

  source_link_audit <- read.csv(
    file.path(evidence_dir, "source_link_audit_prerender.csv"),
    check.names = FALSE
  )
  expected_hrefs <- sub(
    "[.]qmd(?=#|$)",
    ".html",
    source_link_audit$target,
    perl = TRUE
  )
  observed_contract_hrefs <- hrefs[hrefs %in% expected_hrefs]
  assert_true(
    identical(observed_contract_hrefs, expected_hrefs),
    "Rendered 25-link source order differs"
  )
  link_audit <- do.call(rbind, lapply(seq_along(expected_hrefs), function(index) {
    href <- expected_hrefs[[index]]
    file_part <- sub("#.*$", "", href)
    fragment <- if (grepl("#", href, fixed = TRUE)) {
      sub("^[^#]*#", "", href)
    } else {
      ""
    }
    target_path <- normalizePath(
      file.path(dirname(html_path), utils::URLdecode(file_part)),
      winslash = "/",
      mustWork = FALSE
    )
    exists <- file.exists(target_path) && !dir.exists(target_path)
    fragment_count <- if (exists && nzchar(fragment) && grepl("[.]html$", target_path)) {
      target_document <- xml2::read_html(target_path)
      length(xml2::xml_find_all(
        target_document,
        sprintf("//*[@id='%s']", fragment)
      ))
    } else if (nzchar(fragment)) {
      0L
    } else {
      NA_integer_
    }
    data.frame(
      order = index,
      source_target = source_link_audit$target[[index]],
      rendered_href = href,
      resolved_path = relative_path(target_path),
      file_exists = exists,
      fragment = fragment,
      fragment_resolution_count = fragment_count,
      status = ifelse(
        exists && (!nzchar(fragment) || fragment_count == 1L),
        "PASS",
        "FAIL"
      ),
      stringsAsFactors = FALSE
    )
  }))
  assert_true(nrow(link_audit) == 25L, "Rendered link count differs")
  assert_all(link_audit$status == "PASS", "A rendered link or fragment failed")
  write_evidence(link_audit, "reader_link_and_fragment_audit.csv")

  result_document <- xml2::read_html(
    file.path(root, "_build/nathealth/notebooks/hypotheses/H08.html")
  )
  result_hrefs <- rvest::html_attr(
    rvest::html_elements(result_document, "a[href]"),
    "href"
  )
  active_hrefs <- rvest::html_attr(
    rvest::html_elements(document, "a.sidebar-link.active, a.nav-link.active"),
    "href"
  )
  navigation_audit <- data.frame(
    check = c(
      "active companion navigation",
      "companion-to-result links",
      "result-to-companion reciprocal link",
      "DEV-035 link",
      "DEV-036 link",
      "result deviation-section link"
    ),
    observed = c(
      any(grepl("audit/hypotheses/H08/H08_analysis_preparation[.]html$", active_hrefs)),
      sum(hrefs == "../../../notebooks/hypotheses/H08.html"),
      any(grepl("audit/hypotheses/H08/H08_analysis_preparation[.]html$", result_hrefs)),
      any(hrefs == "../../../notebooks/preregistration_deviations.html#dev-035"),
      any(hrefs == "../../../notebooks/preregistration_deviations.html#dev-036"),
      any(hrefs == "../../../notebooks/hypotheses/H08.html#h08-preregistration-deviations")
    ),
    expected = c("1", "2", "1", "1", "1", "1"),
    stringsAsFactors = FALSE
  )
  navigation_audit$status <- ifelse(
    navigation_audit$observed == navigation_audit$expected,
    "PASS",
    "FAIL"
  )
  assert_all(navigation_audit$status == "PASS", "Navigation contract differs")
  write_evidence(navigation_audit, "navigation_audit.csv")

  main_text <- clean_text(main)
  required_phrases <- c(
    "gap-timing-unaware dataset",
    "at least 50% valid minutes per hour",
    "at least 80% valid hours per day",
    "timing of the remaining missing observations",
    "time-sensitive primary metric dataset",
    "Exact evaluated Wilkinson formulae",
    "complete nine-test",
    "no FDR-adjusted p-value met the 0.050 criterion",
    "bounded maintenance rebuilt only the six primary-dataset L10 model branches",
    "Near eye",
    "Chest",
    "R 4.6.1"
  )
  phrase_audit <- data.frame(
    phrase = required_phrases,
    present = vapply(
      required_phrases,
      grepl,
      logical(1),
      x = main_text,
      fixed = TRUE
    ),
    stringsAsFactors = FALSE
  )
  phrase_audit$status <- ifelse(phrase_audit$present, "PASS", "FAIL")
  assert_all(phrase_audit$status == "PASS", "A scientific reporting phrase is absent")
  write_evidence(phrase_audit, "reader_phrase_audit.csv")

  site_registry <- read.csv(
    file.path(root, "config/site_display_registry.csv"),
    check.names = FALSE
  )
  site_names <- site_registry$display_name
  bare_names <- sub(" \\([A-Z]{2}\\)$", "", site_names)
  site_audit <- data.frame(
    site = site_names,
    coded_present = vapply(
      site_names,
      grepl,
      logical(1),
      x = main_text,
      fixed = TRUE
    ),
    uncoded_present = vapply(bare_names, function(site) {
      grepl(
        sprintf("%s(?! \\([A-Z]{2}\\))", site),
        main_text,
        perl = TRUE
      )
    }, logical(1)),
    stringsAsFactors = FALSE
  )
  site_audit$status <- ifelse(
    site_audit$coded_present & !site_audit$uncoded_present,
    "PASS",
    "FAIL"
  )
  assert_all(site_audit$status == "PASS", "A submitted site display differs")
  write_evidence(site_audit, "country_site_audit.csv")

  required_table_contract <- data.frame(
    endpoint = c(
      "tbl-h08-prep-score-audit",
      "tbl-h08-prep-primary-samples",
      "tbl-h08-prep-model-settings",
      "tbl-h08-prep-family-audit",
      "tbl-h08-prep-response-gate",
      "tbl-h08-prep-site-influence",
      "tbl-h08-prep-sensitivity-map",
      "tbl-h08-prep-metric011",
      "tbl-h08-prep-module-map",
      "tbl-h08-prep-script-map",
      "tbl-h08-prep-output-identities",
      "tbl-h08-prep-environment"
    ),
    contract = c(
      "score audit",
      "sample support",
      "model settings",
      "eight FDR families",
      "response gates",
      "influence summary",
      "sensitivity summary",
      "METRIC-011 provenance",
      "module map",
      "script map",
      "output identity map",
      "environment records"
    ),
    stringsAsFactors = FALSE
  )
  required_table_contract$rendered <- required_table_contract$endpoint %in% table_ids
  required_table_contract$body_rows <- table_audit$body_rows[
    match(required_table_contract$endpoint, table_audit$endpoint)
  ]
  required_table_contract$status <- ifelse(
    required_table_contract$rendered & required_table_contract$body_rows > 0L,
    "PASS",
    "FAIL"
  )
  assert_all(
    required_table_contract$status == "PASS",
    "A scientific preparation contract table is missing"
  )
  write_evidence(
    required_table_contract,
    "scientific_table_contract_audit.csv"
  )

  defect_patterns <- c(
    "Error in ",
    "Execution halted",
    "Quitting from",
    "Warning:",
    "stderr",
    "unresolved reference",
    "@tbl-h08-",
    "@fig-h08-",
    "???",
    "Traceback",
    "## [1]"
  )
  defect_audit <- data.frame(
    pattern = defect_patterns,
    present = vapply(
      defect_patterns,
      grepl,
      logical(1),
      x = main_text,
      fixed = TRUE
    ),
    stringsAsFactors = FALSE
  )
  defect_audit$status <- ifelse(defect_audit$present, "FAIL", "PASS")
  assert_none(defect_audit$present, "Rendered companion contains an execution defect")
  write_evidence(defect_audit, "embedded_defect_audit.csv")
  internal_path_audit <- data.frame(
    check = c("reader-visible build path", "internal build href"),
    observed = c(
      grepl("_build/", main_text, fixed = TRUE),
      any(grepl("_build/", hrefs, fixed = TRUE))
    ),
    expected = c(FALSE, FALSE),
    status = "PASS"
  )
  assert_none(internal_path_audit$observed, "Reader-visible build path remains")
  write_evidence(internal_path_audit, "reader_internal_path_audit.csv")

  pre_build <- read.csv(
    file.path(evidence_dir, "build_inventory_prerender.csv"),
    check.names = FALSE
  )
  build_compare <- compare_inventory(pre_build, build_inventory, "complete build")
  build_compare$transition <- ifelse(
    is.na(build_compare$sha256_before),
    "added",
    ifelse(
      is.na(build_compare$sha256_after),
      "removed",
      ifelse(build_compare$exact, "exact", "changed")
    )
  )
  build_delta <- build_compare[build_compare$transition != "exact", , drop = FALSE]
  expected_build_delta <- c(
    expected_figure_paths[[2L]],
    html_relative,
    build_qmd_relative,
    "_build/nathealth/search.json",
    "_build/nathealth/sitemap.xml"
  )
  build_delta$classification <- ifelse(
    build_delta$path == html_relative,
    "authorized companion target",
    ifelse(
      build_delta$path == build_qmd_relative,
      "authorized source-identical build QMD",
      ifelse(
        build_delta$path == expected_figure_paths[[2L]],
        "authorized target-owned sample-support resource",
        ifelse(
          build_delta$path %in% c(
            "_build/nathealth/search.json",
            "_build/nathealth/sitemap.xml"
          ),
          "expected website integration",
          "unclassified"
        )
      )
    )
  )
  build_delta$status <- ifelse(
    build_delta$path %in% expected_build_delta &
      build_delta$transition == "changed",
    "PASS",
    "FAIL"
  )
  assert_true(
    setequal(build_delta$path, expected_build_delta) &&
      nrow(build_delta) == 5L &&
      all(build_delta$status == "PASS"),
    "Build delta differs from the authorized set"
  )
  write_evidence(build_delta, "build_delta_postrender.csv")

  protected_compare <- compare_inventory(
    protected_pre,
    protected_inventory,
    "protected H08 scope"
  )
  expected_protected_delta <- c(
    expected_figure_paths[[2L]],
    html_relative,
    build_qmd_relative,
    manifest_relative
  )
  protected_compare$expected_transition <-
    protected_compare$path %in% expected_protected_delta
  protected_compare$status <- ifelse(
    protected_compare$exact | protected_compare$expected_transition,
    "PASS",
    "FAIL"
  )
  assert_true(
    setequal(
      protected_compare$path[!protected_compare$exact],
      expected_protected_delta
    ) &&
      all(protected_compare$status == "PASS"),
    "Protected transition set differs"
  )
  write_evidence(
    protected_compare,
    "protected_reconciliation_postrender.csv"
  )

  render_console_audit <- data.frame(
    check = c(
      "Quarto invocations",
      "render exit",
      "semantic disposition",
      "semantic table count",
      "embedded execution defects",
      "unresolved references",
      "raw traces",
      "helper executions",
      "historical tests executed"
    ),
    observed = c(
      execution$attempts[execution$operation == "companion_quarto_render"],
      execution$exit_status[execution$operation == "companion_quarto_render"],
      semantic_summary$disposition,
      semantic_summary$table_count,
      sum(defect_audit$present),
      sum(defect_audit$pattern == "unresolved reference" & defect_audit$present),
      sum(defect_audit$pattern %in% c("Traceback", "## [1]") & defect_audit$present),
      execution$attempts[execution$operation == "preparation_manifest_helper"],
      sum(historical_tests$executed)
    ),
    expected = c("1", "0", "REPAIRED", "19", "0", "0", "0", "1", "0"),
    stringsAsFactors = FALSE
  )
  render_console_audit$status <- ifelse(
    render_console_audit$observed == render_console_audit$expected,
    "PASS",
    "FAIL"
  )
  assert_all(render_console_audit$status == "PASS", "Execution classification differs")
  write_evidence(render_console_audit, "render_and_helper_execution_audit.csv")

  nonvisual_status <- data.frame(
    domain = c(
      "sole render and helper execution",
      "semantic disposition and exact reversal",
      "visible and structural semantic invariance",
      "native gt endpoints and cells",
      "exact formulas and model settings",
      "document IDs and table headers",
      "figures and paired source data",
      "top-down Mermaid",
      "25 links and exact fragments",
      "reciprocal navigation and deviations",
      "score and sample-support contract",
      "eight complete FDR families",
      "response influence and sensitivity summaries",
      "METRIC-011 code output and environment provenance",
      "country-coded sites and reporting terminology",
      "embedded defects and internal paths",
      "258-row preparation manifest",
      "protected and build transitions",
      "historical manifests and accepted result",
      "170 mm baseline and target PNG transition"
    ),
    details = c(
      "One successful companion render, one helper execution, zero retries, historical tests unexecuted",
      sprintf("REPAIRED with %d exactly reversible substitutions", semantic_summary$total_substitutions),
      "Visible text, values, order, captions, notes, links, and DOM structure are invariant",
      "19 native gt tables in accepted order with audited captions, rows, cells, labels, and notes",
      "Nine formulas and nine model-setting rows retain accepted content",
      sprintf("%d unique document IDs; %d header tokens resolve locally and globally", length(ids), nrow(header_audit)),
      "Three figure endpoints retain alt text, captions, frozen paired source rows, and exact geometry",
      "One top-down preparation flow is present",
      "All 25 reader targets appear in source order and resolve, including fragments",
      "Reciprocal H08 navigation, DEV-035, DEV-036, and result deviation anchor pass",
      "184 VLSQ-8 participants, 24 score rows, nine sites, and 18 metric-placement cells pass",
      "Eight complete nine-test families, 72 tests, and zero adjusted-positive tests pass",
      "Response gate, influence, and sensitivity tables are present with stored artifacts live exact",
      "METRIC-011, module, script, output identity, and environment tables are present",
      "All submitted site displays are country-coded and required dataset qualifications remain",
      "Zero embedded errors, warnings, unresolved references, raw traces, or reader-visible build paths",
      "258 of 258 unique non-circular rows are live exact and exclude order-55 evidence",
      sprintf("Five classified build deltas and four classified protected transitions across %d protected paths", nrow(protected_inventory)),
      "Accepted result and shared phase-4 and Stage 3 manifests remain exact with historical rows classified",
      "All three A4 proofs remain exact; only sample-support target bytes transitioned, with geometry exact and visual equivalence pending"
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  write_evidence(nonvisual_status, "nonvisual_status.csv")

  cat(sprintf(
    paste0(
      "ORDER55_POSTRENDER=PASS html=%s tables=%d figures=%d mermaid=1 ",
      "headers=%d semantic=%s substitutions=%d manifest=%d build_delta=%d ",
      "protected=%d symlinks=0\n"
    ),
    sha256_file(html_path),
    nrow(table_audit),
    nrow(figure_audit),
    nrow(header_audit),
    semantic_summary$disposition,
    semantic_summary$total_substitutions,
    nrow(manifest),
    nrow(build_delta),
    nrow(protected_inventory)
  ))
}

if (identical(stage, "postqa")) {
  post_build <- read.csv(
    file.path(evidence_dir, "build_inventory_postrender.csv"),
    check.names = FALSE
  )
  post_protected <- read.csv(
    file.path(evidence_dir, "protected_inventory_postrender.csv"),
    check.names = FALSE
  )
  build_compare <- compare_inventory(post_build, build_inventory, "complete build")
  protected_compare <- compare_inventory(
    post_protected,
    protected_inventory,
    "protected H08 scope"
  )
  reconciliation <- data.frame(
    scope = c("complete build", "protected H08 scope"),
    before_rows = c(nrow(post_build), nrow(post_protected)),
    after_rows = c(nrow(build_inventory), nrow(protected_inventory)),
    exact_rows = c(sum(build_compare$exact), sum(protected_compare$exact)),
    status = c(
      ifelse(all(build_compare$exact), "PASS", "FAIL"),
      ifelse(all(protected_compare$exact), "PASS", "FAIL")
    ),
    stringsAsFactors = FALSE
  )
  assert_all(reconciliation$status == "PASS", "QA changed build or protected files")
  write_evidence(reconciliation, "postqa_rehash_reconciliation.csv")
  assert_true(!length(build_symlinks), "Post-QA build contains a symlink")

  final_freeze <- data.frame(
    path = c(
      qmd_relative,
      build_qmd_relative,
      html_relative,
      "notebooks/hypotheses/H08.qmd",
      "_build/nathealth/notebooks/hypotheses/H08.html",
      "_quarto-nathealth.yml",
      "scripts/hypotheses/H08/build_h08_preparation_report_manifest.R",
      historical_tests$path,
      manifest_relative,
      "audit/report_harmonization/phase4_corpus_manifest.csv"
    ),
    stringsAsFactors = FALSE
  )
  final_freeze$sha256 <- vapply(
    file.path(root, final_freeze$path),
    sha256_file,
    character(1)
  )
  final_freeze$bytes <- as.numeric(
    file.info(file.path(root, final_freeze$path))$size
  )
  final_freeze$status <- "PASS"
  write_evidence(final_freeze, "final_source_freeze_audit.csv")

  cat(sprintf(
    "ORDER55_POSTQA=PASS build=%d protected=%d manifest=%d html=%s symlinks=0\n",
    nrow(build_inventory),
    nrow(protected_inventory),
    nrow(manifest),
    sha256_file(html_path)
  ))
}
