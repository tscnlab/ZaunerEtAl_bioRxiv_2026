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

suppressPackageStartupMessages(library(digest))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
working_dir <- normalizePath(
  Sys.getenv("ORDER55_WORKING_DIR"),
  winslash = "/",
  mustWork = TRUE
)
semantic_dir <- normalizePath(
  Sys.getenv("ORDER55_SEMANTIC_DIR"),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

assert_true(
  !dir.exists(file.path(
    root,
    "audit/hypotheses/H08/report018_order55_companion_render"
  )),
  "Durable order-55 evidence directory exists before helper"
)
assert_true(
  length(list.files(semantic_dir, all.files = TRUE, no.. = TRUE)) == 0L,
  "Semantic audit directory is not empty"
)

source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) unname(file.info(path)$size)

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(working_dir, name),
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

inventory <- function(files) {
  files <- unique(files[file.exists(files) & !dir.exists(files)])
  files <- normalizePath(files, winslash = "/", mustWork = TRUE)
  files <- files[order(relative_path(files))]
  data.frame(
    path = relative_path(files),
    sha256 = unname(vapply(files, sha256_file, character(1))),
    bytes = unname(file.info(files)$size),
    stringsAsFactors = FALSE
  )
}

list_artifacts <- function(path, pattern = NULL) {
  if (!dir.exists(path)) return(character())
  list.files(
    path,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE,
    all.files = TRUE,
    no.. = TRUE
  )
}

order_rel <-
  "audit/report_harmonization/owner_orders/55_h08_companion_report018_render.md"
dispatch_rel <-
  "audit/report_harmonization/report018_h08_companion_order55_dispatch_manifest.csv"
release_pins_rel <-
  "audit/report_harmonization/report018_h08_companion_release_pins.csv"
qmd_rel <- "audit/hypotheses/H08/H08_analysis_preparation.qmd"
build_qmd_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H08/",
  "H08_analysis_preparation.qmd"
)
html_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H08/",
  "H08_analysis_preparation.html"
)
manifest_rel <- "artifacts/12_manifests/H08/H08_preparation_report_manifest.csv"

order_path <- file.path(root, order_rel)
dispatch_path <- file.path(root, dispatch_rel)
pins_path <- file.path(root, release_pins_rel)
qmd_path <- file.path(root, qmd_rel)
build_qmd_path <- file.path(root, build_qmd_rel)
html_path <- file.path(root, html_rel)
manifest_path <- file.path(root, manifest_rel)

assert_true(
  sha256_file(order_path) ==
    "8e62ebd57daeccb8decf0e79d95b3c4443fe198e66ec7565f40e095a8679df67" &&
    file_bytes(order_path) == 8591,
  "Order 55 identity differs"
)
assert_true(
  sha256_file(dispatch_path) ==
    "0d0ad43037cd82084b63d45e509b3f26e537fd7ce727c46d934eb301d14d4861" &&
    file_bytes(dispatch_path) == 1530,
  "Order 55 dispatch identity differs"
)

dispatch <- read.csv(dispatch_path, check.names = FALSE)
assert_true(nrow(dispatch) == 9L, "Dispatch must contain 9 rows")
assert_true(!anyDuplicated(dispatch$path), "Dispatch paths are not unique")
assert_true(!dispatch_rel %in% dispatch$path, "Dispatch is circular")
dispatch_files <- file.path(root, dispatch$path)
dispatch_exists <- file.exists(dispatch_files) & !dir.exists(dispatch_files)
dispatch_sha <- rep(NA_character_, nrow(dispatch))
dispatch_bytes <- rep(NA_real_, nrow(dispatch))
dispatch_sha[dispatch_exists] <- unname(vapply(
  dispatch_files[dispatch_exists], sha256_file, character(1)
))
dispatch_bytes[dispatch_exists] <- unname(file.info(
  dispatch_files[dispatch_exists]
)$size)
dispatch_exact <- dispatch_exists & dispatch_sha == dispatch$sha256 &
  dispatch_bytes == as.numeric(dispatch$bytes)
matrix_row <- dispatch$path == "audit/report_harmonization/coordination_matrix.csv"
assert_true(sum(matrix_row) == 1L, "Dispatch matrix row is not unique")
assert_all(dispatch_exact[!matrix_row], "A non-matrix dispatch member differs")
assert_true(!dispatch_exact[matrix_row], "Coordination matrix did not transition")
dispatch_audit <- data.frame(
  path = dispatch$path,
  expected_sha256 = dispatch$sha256,
  current_sha256 = dispatch_sha,
  expected_bytes = dispatch$bytes,
  current_bytes = dispatch_bytes,
  classification = ifelse(
    matrix_row,
    "expected dispatch-time coordination transition",
    "hard pin"
  ),
  status = ifelse(!matrix_row & dispatch_exact, "PASS", ifelse(
    matrix_row & !dispatch_exact, "PASS", "FAIL"
  ))
)
assert_all(dispatch_audit$status == "PASS", "Dispatch reconciliation failed")
write_evidence(dispatch_audit, "dispatch_reconciliation_prerender.csv")

pins <- read.csv(pins_path, check.names = FALSE)
assert_true(nrow(pins) == 34L, "Release pins must contain 34 rows")
assert_true(!anyDuplicated(pins$relative_path), "Release pin paths are not unique")
assert_true(!release_pins_rel %in% pins$relative_path, "Release pins are circular")
pin_files <- file.path(root, pins$relative_path)
pin_exists <- file.exists(pin_files) & !dir.exists(pin_files)
pin_sha <- rep(NA_character_, nrow(pins))
pin_bytes <- rep(NA_real_, nrow(pins))
pin_sha[pin_exists] <- unname(vapply(
  pin_files[pin_exists], sha256_file, character(1)
))
pin_bytes[pin_exists] <- unname(file.info(pin_files[pin_exists])$size)
pin_exact <- pin_exists & pin_sha == pins$sha256 &
  pin_bytes == as.numeric(pins$bytes)
assert_all(pin_exact, "A release hard pin differs")
pin_audit <- data.frame(
  role = pins$role,
  path = pins$relative_path,
  expected_sha256 = pins$sha256,
  current_sha256 = pin_sha,
  expected_bytes = pins$bytes,
  current_bytes = pin_bytes,
  status = ifelse(pin_exact, "PASS", "FAIL")
)
write_evidence(pin_audit, "release_pin_reconciliation_prerender.csv")

result_manifest_rel <-
  "audit/report_harmonization/report018_h08_result_independent_acceptance_manifest.csv"
result_manifest <- read.csv(file.path(root, result_manifest_rel), check.names = FALSE)
assert_true(nrow(result_manifest) == 31L, "Result acceptance manifest must have 31 rows")
assert_true(!anyDuplicated(result_manifest$path), "Result acceptance paths duplicate")
assert_true(!result_manifest_rel %in% result_manifest$path, "Result acceptance manifest is circular")
result_files <- file.path(root, result_manifest$path)
result_exact <- file.exists(result_files) & !dir.exists(result_files) &
  unname(vapply(result_files, sha256_file, character(1))) == result_manifest$sha256 &
  unname(file.info(result_files)$size) == as.numeric(result_manifest$bytes)
assert_all(result_exact, "A result acceptance member differs")
write_evidence(
  data.frame(
    path = result_manifest$path,
    sha256 = result_manifest$sha256,
    bytes = result_manifest$bytes,
    status = ifelse(result_exact, "PASS", "FAIL")
  ),
  "result_acceptance_reconciliation_prerender.csv"
)

qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd_text <- paste(qmd_lines, collapse = "\n")
qmd_compact <- gsub("[[:space:]]+", " ", qmd_text)
chunks <- extract_executable_r_chunks(qmd_lines)
chunk_parse <- vapply(chunks, function(chunk) {
  !inherits(try(parse(text = chunk), silent = TRUE), "try-error")
}, logical(1))
assert_true(length(chunks) == 24L, "Expected exactly 24 R chunks")
assert_all(chunk_parse, "An R chunk does not parse")

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
expected_figures <- c(
  "fig-h08-prep-vlsq-distribution",
  "fig-h08-prep-sample-support",
  "fig-h08-prep-site-range"
)
table_labels <- sub(
  "^#\\| label: ", "",
  grep("^#\\| label: tbl-h08-", qmd_lines, value = TRUE)
)
figure_labels <- sub(
  "^#\\| label: ", "",
  grep("^#\\| label: fig-h08-", qmd_lines, value = TRUE)
)
assert_true(identical(table_labels, expected_tables), "Table endpoint order differs")
assert_true(identical(figure_labels, expected_figures), "Figure endpoint order differs")
assert_true(sum(trimws(qmd_lines) == "flowchart TD") == 1L, "Expected one top-down Mermaid")

calls <- executable_r_call_names(qmd_lines)
forbidden_calls <- c(
  "mgcv::gam", "mgcv::bam", "gam", "bam",
  "lme4::lmer", "lmer", "glmmTMB::glmmTMB", "glmmTMB",
  "stats::glm", "glm", "stats::predict", "predict",
  "stats::simulate", "simulate", "boot::boot", "boot",
  "h08_fit_model", "h08_fit_bundle", "h08_fit_inferential_bundle",
  "h08_model_diagnostics", "h08_leave_one_site_out",
  "h08_photoperiod_sensitivity", "h08_participant_summary_sensitivity"
)
forbidden_observed <- intersect(calls, forbidden_calls)
assert_true(!length(forbidden_observed), "A prohibited scientific call is present")

relative_matches <- gregexpr("\\]\\((\\.\\./[^)]+)\\)", qmd_text, perl = TRUE)
relative_values <- regmatches(qmd_text, relative_matches)[[1L]]
relative_targets <- sub("^\\]\\(", "", relative_values)
relative_targets <- sub("\\)$", "", relative_targets)
assert_true(length(relative_targets) == 25L, "Expected exactly 25 relative targets")
relative_files <- sub("#.*$", "", relative_targets)
relative_fragments <- ifelse(
  grepl("#", relative_targets, fixed = TRUE),
  sub("^[^#]*#", "", relative_targets),
  ""
)
resolved_targets <- normalizePath(
  file.path(dirname(qmd_path), relative_files),
  winslash = "/",
  mustWork = FALSE
)
target_exists <- file.exists(resolved_targets) & !dir.exists(resolved_targets)
fragment_exact <- vapply(seq_along(relative_targets), function(index) {
  fragment <- relative_fragments[[index]]
  if (!nzchar(fragment) || !target_exists[[index]]) return(TRUE)
  text <- paste(
    readLines(resolved_targets[[index]], warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  grepl(paste0("{#", fragment, "}"), text, fixed = TRUE) ||
    grepl(paste0("id=\"", fragment, "\""), text, fixed = TRUE) ||
    grepl(paste0("id='", fragment, "'"), text, fixed = TRUE)
}, logical(1))
assert_all(target_exists, "A relative target file is missing")
assert_all(fragment_exact, "A relative target fragment is missing")
dynamic_expected <- c(
  rep("../../../notebooks/hypotheses/H08.qmd", 2L),
  "../../../notebooks/hypotheses/H08.qmd#h08-preregistration-deviations"
)
dynamic_observed <- relative_targets[grepl(
  "^../../../notebooks/hypotheses/H08\\.qmd", relative_targets
)]
assert_true(
  identical(sort(dynamic_observed), sort(dynamic_expected)),
  "Dynamic result links differ"
)
write_evidence(
  data.frame(
    target = relative_targets,
    resolved_path = relative_path(resolved_targets),
    file_exists = target_exists,
    fragment = relative_fragments,
    fragment_resolves = fragment_exact,
    status = ifelse(target_exists & fragment_exact, "PASS", "FAIL")
  ),
  "source_link_audit_prerender.csv"
)

profile_lines <- trimws(readLines(
  file.path(root, "_quarto-nathealth.yml"),
  warn = FALSE,
  encoding = "UTF-8"
))
result_profile_index <- which(profile_lines == "- notebooks/hypotheses/H08.qmd")
companion_profile_index <- which(
  profile_lines == "- audit/hypotheses/H08/H08_analysis_preparation.qmd"
)
assert_true(
  length(result_profile_index) == 1L &&
    length(companion_profile_index) == 1L &&
    companion_profile_index == result_profile_index + 1L,
  "Profile adjacency differs"
)
assert_true(
  !file.exists(file.path(root, "audit/hypotheses/H08/H08_analysis_preparation.html")),
  "Source-side companion HTML must remain absent"
)

manifest <- read.csv(manifest_path, check.names = FALSE)
assert_true(nrow(manifest) == 125L, "Preparation manifest must have 125 rows")
assert_true(!anyDuplicated(manifest$path), "Preparation manifest paths duplicate")
manifest_files <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- unname(vapply(
  manifest_files[manifest_exists], sha256_file, character(1)
))
manifest_bytes[manifest_exists] <- unname(file.info(
  manifest_files[manifest_exists]
)$size)
manifest_exact <- manifest_exists & manifest_sha == manifest$sha256 &
  manifest_bytes == as.numeric(manifest$bytes)
expected_mismatch <- c(
  "audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H08.html",
  "notebooks/hypotheses/H08.qmd",
  "_quarto-nathealth.yml"
)
assert_true(sum(manifest_exact) == 121L, "Preparation manifest must have 121 exact rows")
assert_true(
  setequal(manifest$path[!manifest_exact], expected_mismatch),
  "Preparation manifest mismatch set differs"
)
write_evidence(
  data.frame(
    path = manifest$path,
    current_sha256 = manifest_sha,
    manifest_sha256 = manifest$sha256,
    current_bytes = manifest_bytes,
    manifest_bytes = manifest$bytes,
    live_exact = manifest_exact,
    classification = ifelse(
      manifest_exact,
      "live exact",
      "accepted historical transition"
    ),
    status = ifelse(
      manifest_exact | manifest$path %in% expected_mismatch,
      "PASS",
      "FAIL"
    )
  ),
  "preparation_manifest_prerender_audit.csv"
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
assert_true(
  identical(unname(source_rows), unname(source_data_contract)),
  "Frozen source-data row counts differ"
)

family_audit <- read.csv(
  file.path(root, "artifacts/09_tables/H08/H08_family_audit.csv"),
  check.names = FALSE
)
assert_true(
  nrow(family_audit) == 8L &&
    all(family_audit$planned_n == 9L) &&
    all(family_audit$observed_raw_p == 9L) &&
    all(family_audit$complete_nine_member_family) &&
    all(family_audit$independent_recalculation_matches) &&
    sum(family_audit$adjusted_significant_n) == 0L,
  "Stored FDR family contract differs"
)

qa <- read.csv(
  file.path(root, "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv"),
  check.names = FALSE
)
companion_qa <- qa[qa$figure_id %in% expected_figures, , drop = FALSE]
qa_paths <- file.path(root, companion_qa$path)
assert_true(
  nrow(companion_qa) == 3L &&
    all(companion_qa$effective_final_essential_text_pt >= 7) &&
    all(companion_qa$status == "PASS") &&
    all(unname(vapply(qa_paths, sha256_file, character(1))) ==
      companion_qa$figure_sha256),
  "Companion physical-size baseline differs"
)

required_phrases <- c(
  "gap-timing-unaware dataset",
  "at least 50% valid minutes per hour",
  "at least 80% valid hours per day",
  "timing of the remaining missing observations",
  "time-sensitive primary metric dataset",
  "Exact evaluated Wilkinson formulae",
  "complete nine-test",
  "no FDR-adjusted p-value met the 0.050 criterion",
  "bounded maintenance rebuilt only the six primary-dataset L10 model branches"
)
phrase_present <- vapply(
  required_phrases, grepl, logical(1), x = qmd_compact, fixed = TRUE
)
assert_all(phrase_present, "A required scientific preservation phrase is absent")

phase4_path <- file.path(root, "audit/report_harmonization/phase4_corpus_manifest.csv")
phase4 <- read.csv(phase4_path, check.names = FALSE)
h08_phase4 <- phase4[phase4$source %in% c(
  "notebooks/hypotheses/H08.qmd",
  "audit/hypotheses/H08/H08_analysis_preparation.qmd"
), , drop = FALSE]
assert_true(
  nrow(h08_phase4) == 2L &&
    setequal(h08_phase4$html_sha256, c(
      "a08a888a40ec58669c61a47b7500159388577eaad49ece5440b9bee9da6a93e1",
      "95f5ba0aede0ee6cf0d1b65fcdc53623d52810f8316c846cb214b4fb34a5f135"
    )),
  "Phase-4 H08 historical identities differ"
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
build_files <- build_entries[file.exists(build_entries) & !dir.exists(build_entries)]
assert_true(length(build_files) == 851L, "Build must contain 851 files")
assert_true(!length(build_symlinks), "Build contains a symlink")
write_evidence(inventory(build_files), "build_inventory_prerender.csv")
write_evidence(
  data.frame(path = relative_path(build_symlinks)),
  "build_symlink_inventory_prerender.csv"
)

decision_files <- file.path(root, c(
  "audit/decisions/answer_in_brief_callout.md",
  "audit/decisions/bootstrap_execution_policy.md",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/gap_timing_unaware_dataset_terminology.md",
  "audit/decisions/hypothesis_preparation_provenance_companions.md",
  "audit/decisions/model_reporting.md",
  "audit/decisions/p_value_display_conventions.md",
  "audit/decisions/paired_placement_comparison_display.md",
  "audit/decisions/site_display_conventions.md",
  "audit/decisions/l10_numerical_zero_normalization.md"
))
protected_files <- unique(c(
  file.path(root, dispatch_rel),
  file.path(root, order_rel),
  dispatch_files[!matrix_row],
  pin_files,
  qmd_path,
  file.path(root, "notebooks/hypotheses/H08.qmd"),
  file.path(root, "_quarto-nathealth.yml"),
  file.path(root, "audit/handoffs/H08_worker_handoff.md"),
  file.path(root, "audit/report_harmonization/phase4_corpus_manifest.csv"),
  file.path(root, "renv.lock"),
  decision_files,
  file.path(root, c(
    "config/site_display_registry.csv",
    "config/metric_display_registry.csv",
    "audit/hypotheses/H03-H11_gated_workflow.qmd",
    "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
    "audit/reconciliation/l10_METRIC-011/primary_scientific_cell_changes.csv",
    "scripts/pipeline/paths_io.R",
    "scripts/pipeline/multiplicity.R",
    "scripts/pipeline/p_value_display.R",
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  )),
  list_artifacts(file.path(root, "audit/hypotheses/H08")),
  list_artifacts(file.path(root, "scripts/hypotheses/H08")),
  list_artifacts(file.path(root, "tests/hypotheses/H08")),
  list_artifacts(file.path(root, "artifacts/06_model_data/H08")),
  list_artifacts(file.path(root, "artifacts/07_models/H08")),
  list_artifacts(file.path(root, "artifacts/08_diagnostics/H08")),
  list_artifacts(file.path(root, "artifacts/09_tables/H08")),
  list_artifacts(file.path(root, "artifacts/10_figures/H08")),
  list_artifacts(file.path(root, "artifacts/11_source_data/H08")),
  list_artifacts(file.path(root, "artifacts/12_manifests/H08"))
))
protected_files <- protected_files[
  !grepl("/report018_order55_companion_render(?:/|$)", protected_files)
]
protected_inventory <- inventory(protected_files)
assert_true(!anyDuplicated(protected_inventory$path), "Protected inventory duplicates")
write_evidence(protected_inventory, "protected_inventory_prerender.csv")

process_evidence <- read.csv(
  file.path(working_dir, "process_prerender_external.csv"),
  check.names = FALSE
)
assert_true(
  nrow(process_evidence) == 1L &&
    identical(process_evidence$status[[1L]], "PASS") &&
    process_evidence$matching_processes[[1L]] == 0L,
  "External process preflight did not pass"
)

quarto_version <- trimws(system2("quarto", "--version", stdout = TRUE))
assert_true(identical(quarto_version[[1L]], "1.9.37"), "Quarto version differs")
versions <- data.frame(
  component = c("R", "digest", "Quarto"),
  version = c(
    as.character(getRversion()),
    as.character(utils::packageVersion("digest")),
    quarto_version[[1L]]
  ),
  status = "PASS"
)
assert_true(versions$version[[2L]] == "0.6.39", "digest version differs")
write_evidence(versions, "versions_prerender.csv")

endpoint_status <- data.frame(
  check = c(
    "R chunks", "parseable chunks", "native gt tables", "figures",
    "top-down Mermaid", "relative targets", "prohibited calls",
    "preparation manifest live rows", "build files", "build symlinks",
    "release pins", "result acceptance rows", "protected files"
  ),
  observed = c(
    length(chunks), sum(chunk_parse), length(table_labels), length(figure_labels),
    1L, length(relative_targets), length(forbidden_observed),
    sum(manifest_exact), length(build_files), length(build_symlinks),
    sum(pin_exact), sum(result_exact), nrow(protected_inventory)
  ),
  expected = c(24L, 24L, 19L, 3L, 1L, 25L, 0L, 121L, 851L, 0L, 34L, 31L, nrow(protected_inventory)),
  status = "PASS"
)
write_evidence(endpoint_status, "prerender_status.csv")

cat(sprintf(
  paste0(
    "ORDER55_PRERENDER=PASS dispatch=%d/8 matrix=TRANSITION pins=%d/34 ",
    "result_acceptance=%d/31 chunks=%d tables=%d figures=%d mermaid=1 ",
    "links=%d manifest=%d/125+4 build=%d protected=%d symlinks=0 ",
    "R=%s digest=%s quarto=%s\n"
  ),
  sum(dispatch_exact[!matrix_row]),
  sum(pin_exact),
  sum(result_exact),
  length(chunks),
  length(table_labels),
  length(figure_labels),
  length(relative_targets),
  sum(manifest_exact),
  length(build_files),
  nrow(protected_inventory),
  as.character(getRversion()),
  as.character(utils::packageVersion("digest")),
  quarto_version[[1L]]
))
