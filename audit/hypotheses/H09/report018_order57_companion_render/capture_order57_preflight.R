#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 57 preflight requires R 4.6.1", call. = FALSE)
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

fixed <- data.frame(
  path = c(
    "audit/report_harmonization/owner_orders/57_h09_companion_report018_render.md",
    "audit/report_harmonization/report018_h09_companion_release.md",
    "audit/report_harmonization/report018_h09_companion_release_manifest.csv",
    "audit/report_harmonization/report018_h09_companion_release_pins.csv",
    "scripts/report_harmonization/check_h09_companion_report018_release.R",
    "audit/report_harmonization/report018_h09_companion_release_verification.csv",
    "audit/report_harmonization/report018_h09_order57_dispatch_manifest.csv",
    "audit/report_harmonization/coordination_matrix.csv"
  ),
  sha256 = c(
    "677f81e850a24114363f5ab72433c684dcdf5829f11d09eb4ead9c2e9a655c5c",
    "f567e2a5b9b33816bdf355a957f438a1d9cf1520db305074f9577e6d3be113c7",
    "0bffe33d1bd30ed70a2002bb3a1c479d4cae2a3b68ab581857c456a40b31dd57",
    "16a181126f1978f7c18f6be621612ab1e422442f55889e302611c1db66f2e677",
    "9fcd89bc7d2585d927fd4527e0cbd8a893e52cb87f353cabb38ef04a9f5cffdc",
    "89a533044dac43c0f179761900b7f598bf2c43d14df915847f0b73bffa8d64a6",
    "4ce5a7819b3f1aa002ebbf97dfb2cb0b635528feeacffda30890dc2fd80e9fd0",
    "a172d43dfd96a3aa4d1e516f3c6c711a4a1d6311641400af06111ac88993e726"
  ),
  bytes = c(9912, 9391, 3807, 5319, 21154, 5811, 1548, 37094),
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
  "fixed controlling identities",
  sum(fixed$status == "PASS"),
  nrow(fixed),
  all(fixed$status == "PASS")
)

release_manifest_rel <-
  "audit/report_harmonization/report018_h09_companion_release_manifest.csv"
release_manifest <- read.csv(file.path(root, release_manifest_rel), check.names = FALSE)
release_files <- file.path(root, release_manifest$path)
release_exact <- file.exists(release_files) & !dir.exists(release_files) &
  vapply(release_files, sha256_file, character(1)) == release_manifest$sha256 &
  file_bytes(release_files) == as.numeric(release_manifest$bytes)
release_audit <- transform(
  release_manifest,
  observed_sha256 = vapply(release_files, sha256_file, character(1)),
  observed_bytes = file_bytes(release_files),
  status = ifelse(release_exact, "PASS", "FAIL")
)
write_evidence(release_audit, "release_manifest_audit_prerender.csv")
add_check(
  "authority",
  "25-row release manifest",
  paste(sum(release_exact), nrow(release_manifest), sep = "/"),
  "25/25 exact unique non-circular",
  nrow(release_manifest) == 25L && !anyDuplicated(release_manifest$path) &&
    !release_manifest_rel %in% release_manifest$path && all(release_exact)
)

dispatch_rel <-
  "audit/report_harmonization/report018_h09_order57_dispatch_manifest.csv"
dispatch <- read.csv(file.path(root, dispatch_rel), check.names = FALSE)
matrix_rel <- "audit/report_harmonization/coordination_matrix.csv"
dispatch_hard <- dispatch[dispatch$path != matrix_rel, , drop = FALSE]
dispatch_files <- file.path(root, dispatch_hard$path)
dispatch_hard$observed_sha256 <- vapply(
  dispatch_files,
  sha256_file,
  character(1)
)
dispatch_hard$observed_bytes <- file_bytes(dispatch_files)
dispatch_hard$status <- ifelse(
  dispatch_hard$observed_sha256 == dispatch_hard$sha256 &
    dispatch_hard$observed_bytes == as.numeric(dispatch_hard$bytes),
  "PASS",
  "FAIL"
)
write_evidence(dispatch_hard, "dispatch_hard_pin_audit_prerender.csv")
add_check(
  "authority",
  "non-matrix dispatch identities",
  paste(sum(dispatch_hard$status == "PASS"), nrow(dispatch_hard), sep = "/"),
  "8/8 exact unique non-circular",
  nrow(dispatch) == 9L && nrow(dispatch_hard) == 8L &&
    !anyDuplicated(dispatch$path) && !dispatch_rel %in% dispatch$path &&
    all(dispatch_hard$status == "PASS")
)

pins_rel <- "audit/report_harmonization/report018_h09_companion_release_pins.csv"
pins <- read.csv(file.path(root, pins_rel), check.names = FALSE)
pin_files <- file.path(root, pins$relative_path)
pins$observed_sha256 <- vapply(pin_files, sha256_file, character(1))
pins$observed_bytes <- file_bytes(pin_files)
pins$status <- ifelse(
  pins$observed_sha256 == pins$sha256 &
    pins$observed_bytes == as.numeric(pins$bytes),
  "PASS",
  "FAIL"
)
write_evidence(pins, "release_pins_audit_prerender.csv")
add_check(
  "authority",
  "34-row release pins",
  paste(sum(pins$status == "PASS"), nrow(pins), sep = "/"),
  "34/34 exact unique non-circular",
  nrow(pins) == 34L && !anyDuplicated(pins$relative_path) &&
    !pins_rel %in% pins$relative_path && all(pins$status == "PASS")
)

result_manifest_rel <- paste0(
  "audit/report_harmonization/",
  "report018_h09_order56b_result_independent_acceptance_manifest.csv"
)
result_manifest <- read.csv(file.path(root, result_manifest_rel), check.names = FALSE)
result_files <- ifelse(
  startsWith(result_manifest$path, "/"),
  result_manifest$path,
  file.path(root, result_manifest$path)
)
result_exact <- file.exists(result_files) & !dir.exists(result_files) &
  vapply(result_files, sha256_file, character(1)) == result_manifest$sha256 &
  file_bytes(result_files) == as.numeric(result_manifest$bytes)
result_audit <- transform(
  result_manifest,
  observed_sha256 = vapply(result_files, sha256_file, character(1)),
  observed_bytes = file_bytes(result_files),
  status = ifelse(result_exact, "PASS", "FAIL")
)
write_evidence(result_audit, "result_acceptance_audit_prerender.csv")
add_check(
  "authority",
  "accepted H09 result package",
  paste(sum(result_exact), nrow(result_manifest), sep = "/"),
  "37/37 exact unique non-circular",
  nrow(result_manifest) == 37L && !anyDuplicated(result_manifest$path) &&
    !result_manifest_rel %in% result_manifest$path && all(result_exact)
)

qmd_rel <- "audit/hypotheses/H09/H09_analysis_preparation.qmd"
qmd_path <- file.path(root, qmd_rel)
qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd_text <- paste(qmd_lines, collapse = "\n")
qmd_compact <- gsub("[[:space:]]+", " ", qmd_text)
chunks <- extract_executable_r_chunks(qmd_lines)
chunk_parse <- vapply(
  chunks,
  function(chunk) !inherits(try(parse(text = chunk), silent = TRUE), "try-error"),
  logical(1)
)
chunk_audit <- data.frame(
  chunk = seq_along(chunks),
  parse_status = ifelse(chunk_parse, "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
write_evidence(chunk_audit, "source_chunk_audit_prerender.csv")
add_check(
  "source",
  "parseable R chunks",
  paste(sum(chunk_parse), length(chunks), sep = "/"),
  "22/22",
  length(chunks) == 22L && all(chunk_parse)
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
observed_tables <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: tbl-h09-", qmd_lines, value = TRUE)
)
observed_figures <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: fig-h09-", qmd_lines, value = TRUE)
)
endpoint_audit <- data.frame(
  type = c(rep("table", length(observed_tables)), rep("figure", length(observed_figures))),
  source_order = seq_len(length(observed_tables) + length(observed_figures)),
  endpoint = c(observed_tables, observed_figures),
  status = c(
    ifelse(observed_tables == expected_tables, "PASS", "FAIL"),
    ifelse(observed_figures == "fig-h09-prep-sample-support", "PASS", "FAIL")
  ),
  stringsAsFactors = FALSE
)
write_evidence(endpoint_audit, "source_endpoint_contract_prerender.csv")
add_check(
  "source",
  "endpoint contract",
  paste(length(observed_tables), length(observed_figures), sep = "/"),
  "19 tables/1 figure in accepted order",
  identical(observed_tables, expected_tables) &&
    identical(observed_figures, "fig-h09-prep-sample-support")
)
mermaid_count <- sum(trimws(qmd_lines) == "flowchart TD")
add_check("source", "top-down Mermaid", mermaid_count, 1L, mermaid_count == 1L)

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
add_check(
  "source",
  "prohibited scientific-regeneration calls",
  paste(forbidden_observed, collapse = "|"),
  "none",
  length(forbidden_observed) == 0L
)

relative_matches <- gregexpr("\\]\\((\\.\\./[^)]+)\\)", qmd_text, perl = TRUE)
relative_values <- regmatches(qmd_text, relative_matches)[[1L]]
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
dynamic_links <- grep(
  "^../../../notebooks/hypotheses/H09\\.qmd",
  relative_targets,
  value = TRUE
)
expected_dynamic_links <- c(
  "../../../notebooks/hypotheses/H09.qmd",
  "../../../notebooks/hypotheses/H09.qmd#h09-preregistration-deviations"
)
add_check(
  "source",
  "relative reader targets",
  paste(length(relative_targets), length(unique(relative_targets)), sep = "/"),
  "23/22 all resolving with two dynamic result links",
  length(relative_targets) == 23L && length(unique(relative_targets)) == 22L &&
    all(link_audit$resolves) && setequal(dynamic_links, expected_dynamic_links)
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
  "132-row historical manifest",
  paste(sum(manifest_exact), sum(!manifest_exact), sep = "/"),
  "113 live exact/19 classified transitions",
  nrow(manifest) == 132L && !anyDuplicated(manifest$path) &&
    sum(manifest_exact) == 113L &&
    setequal(manifest$path[!manifest_exact], expected_mismatches)
)

required_phrases <- c(
  "gap-timing-unaware dataset", "50%-per-hour", "80%-per-day",
  "remaining gaps' time of day", "time-sensitive primary dataset",
  "mctq_hour_centered", "meq_10_centered",
  "one hour later corrected midsleep",
  "10 score points toward greater morning preference"
)
phrase_audit <- data.frame(
  phrase = required_phrases,
  present = vapply(required_phrases, grepl, logical(1), x = qmd_compact, fixed = TRUE),
  stringsAsFactors = FALSE
)
phrase_audit$status <- ifelse(phrase_audit$present, "PASS", "FAIL")
write_evidence(phrase_audit, "source_scientific_contract_prerender.csv")
add_check(
  "source",
  "scientific preservation phrases",
  sum(phrase_audit$present),
  length(required_phrases),
  all(phrase_audit$present)
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
  "result and companion profile adjacency",
  paste(result_profile_index, companion_profile_index, sep = "/"),
  "single adjacent entries",
  length(result_profile_index) == 1L && length(companion_profile_index) == 1L &&
    companion_profile_index == result_profile_index + 1L
)

model_index <- read.csv(
  file.path(root, "artifacts/06_model_data/H09/H09_model_frame_index.csv"),
  check.names = FALSE
)
add_check(
  "figure",
  "frozen sample-support input",
  paste(nrow(model_index), length(unique(model_index$frame_id)), sep = "/"),
  "108/108",
  nrow(model_index) == 108L && !anyDuplicated(model_index$frame_id)
)

source_support_root <- file.path(
  root,
  "audit/hypotheses/H09/H09_analysis_preparation_files"
)
source_support_files <- list_files(source_support_root)
source_support_inventory <- inventory_paths(
  source_support_files,
  "historical_source_side_support"
)
write_evidence(
  source_support_inventory,
  "source_side_support_tree_prerender.csv"
)
add_check(
  "historical",
  "source-side support tree",
  nrow(source_support_inventory),
  16L,
  nrow(source_support_inventory) == 16L &&
    !any(source_support_inventory$is_symlink)
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
build_symlink_paths <- build_entries[nzchar(Sys.readlink(build_entries))]
build_symlink_inventory <- data.frame(
  relative_path = relative_path(build_symlink_paths),
  symlink_target = Sys.readlink(build_symlink_paths),
  stringsAsFactors = FALSE
)
write_evidence(build_symlink_inventory, "build_symlink_inventory_prerender.csv")
add_check(
  "build",
  "build files and symlinks",
  paste(length(build_files), length(build_symlink_paths), sep = "/"),
  "851/0",
  length(build_files) == 851L && length(build_symlink_paths) == 0L
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
  "audit/decisions/l10_numerical_zero_normalization.md"
))
ledger_paths <- list_files(file.path(root, "audit/ledgers"))
dispatch_paths <- file.path(root, dispatch$path)
protected_paths <- sort(unique(c(
  h09_paths,
  handoff_paths,
  decision_paths,
  ledger_paths,
  dispatch_paths,
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
    "config/metric_display_registry.csv",
    "config/site_display_registry.csv",
    "audit/evidence/preregistration_contract.md",
    "audit/hypotheses/H03-H11_gated_workflow.qmd",
    "audit/hypotheses/H09-H11_migration_map.md",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "audit/report_harmonization/phase4_gt_source_audit.csv",
    "audit/report_harmonization/deviation_link_plan.csv",
    "audit/report_harmonization/report018_h09_companion_release.md",
    "audit/report_harmonization/report018_h09_companion_release_manifest.csv",
    "audit/report_harmonization/report018_h09_companion_release_pins.csv",
    "audit/report_harmonization/report018_h09_companion_release_verification.csv",
    "audit/report_harmonization/report018_h09_order56b_result_independent_acceptance.md",
    "audit/report_harmonization/report018_h09_order56b_result_independent_acceptance_manifest.csv",
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
  "complete protected H09 inventory",
  nrow(protected_inventory),
  "all present, regular, nonsymlink files",
  nrow(protected_inventory) > 0L && !any(protected_inventory$is_symlink)
)

preparation_test <- file.path(root, "tests/hypotheses/H09/test_h09_preparation_report.R")
result_test <- file.path(root, "tests/hypotheses/H09/test_h09_stage3_reader_report.R")
test_audit <- data.frame(
  path = relative_path(c(preparation_test, result_test)),
  sha256 = vapply(c(preparation_test, result_test), sha256_file, character(1)),
  bytes = file_bytes(c(preparation_test, result_test)),
  modified_utc = format(
    file.info(c(preparation_test, result_test))$mtime,
    tz = "UTC",
    usetz = TRUE,
    format = "%Y-%m-%dT%H:%M:%OS6Z"
  ),
  execution_status = "NOT_EXECUTED",
  stringsAsFactors = FALSE
)
write_evidence(test_audit, "historical_tests_prerender.csv")

quarto_version <- trimws(system2("quarto", "--version", stdout = TRUE))
versions <- data.frame(
  component = c("R", "digest", "Quarto"),
  version = c(
    as.character(getRversion()),
    as.character(utils::packageVersion("digest")),
    quarto_version[[1L]]
  ),
  expected = c("4.6.1", "0.6.39", "1.9.37"),
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

semantic_status <- data.frame(
  path = semantic_dir,
  absolute = startsWith(semantic_dir, "/"),
  outside_project = !startsWith(semantic_dir, paste0(root, "/")),
  entries = length(list.files(semantic_dir, all.files = TRUE, no.. = TRUE)),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_evidence(semantic_status, "semantic_directory_prerender.csv")

write_evidence(checks, "preflight_summary.csv")
if (any(checks$status != "PASS")) {
  print(checks[checks$status != "PASS", , drop = FALSE])
  stop("Order 57 pre-render gate failed", call. = FALSE)
}

cat(sprintf(
  paste0(
    "H09_ORDER57_PRERENDER=PASS checks=%d/%d dispatch=8/8 release=25/25 ",
    "pins=34/34 result=37/37 chunks=22/22 tables=19 figure=1 ",
    "mermaid=1 links=23/22 manifest=113/132+19 build=851 symlinks=0 ",
    "support=16 protected=%d R=%s quarto=%s\n"
  ),
  nrow(checks),
  nrow(checks),
  nrow(protected_inventory),
  as.character(getRversion()),
  quarto_version[[1L]]
))
