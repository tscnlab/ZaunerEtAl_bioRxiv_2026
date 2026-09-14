#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

suppressPackageStartupMessages({
  library(openssl)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
control_dir <- normalizePath(
  Sys.getenv("H10_ORDER58_CONTROL_DIR"),
  winslash = "/",
  mustWork = TRUE
)
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H10/report018_order58_result_render"
)
setwd(root)

stopifnot(
  dir.exists(evidence_dir),
  startsWith(control_dir, "/private/tmp/"),
  startsWith(semantic_dir, "/private/tmp/"),
  !startsWith(semantic_dir, paste0(root, "/"))
)

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  paste0(openssl::sha256(con))
}

file_bytes <- function(path) unname(file.info(path)$size)

file_exact <- function(path, sha256, bytes = NULL) {
  exact <- file.exists(path) && !dir.exists(path) &&
    identical(sha256_file(path), sha256)
  if (!is.null(bytes)) {
    exact <- exact && identical(as.numeric(file_bytes(path)), as.numeric(bytes))
  }
  exact
}

read_text <- function(path) {
  rawToChar(readBin(path, what = "raw", n = file_bytes(path)))
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

fixed_pins <- data.frame(
  path = c(
    "notebooks/hypotheses/H10.qmd",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
    "tests/hypotheses/H10/test_h10_preparation_report.R",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html",
    "audit/hypotheses/H10/H10_analysis_preparation.html",
    "artifacts/12_manifests/H10/H10_stage3_artifacts.csv",
    "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv",
    "audit/handoffs/H10_worker_handoff.md",
    "artifacts/06_model_data/normalized_inputs/demographics.rds",
    "artifacts/06_model_data/H10/H10_model_frames.rds",
    "artifacts/07_models/H10/H10_model_manifest.csv",
    "audit/hypotheses/H10/01_audit_and_plan.qmd",
    "_quarto-nathealth.yml",
    "scripts/report_harmonization/post_render_gt_html_semantics.R",
    "scripts/report_harmonization/repair_gt_html_semantics.R",
    "renv.lock",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "notebooks/hypotheses/H11.qmd"
  ),
  sha256 = c(
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "ad792acdb7c9d2fe9290a6837a2a3c994811d7f5c9a64eaea01b0edd9f9b4db1",
    "15d20f3c3fe4d5387eb64152479d07ea0e94b397b27b0a7b59b3d41c7a1924c4",
    "efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8",
    "efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8",
    "b556d9fdb19eeda766414bab30420846ee5c46138e9d7861f61e92da7516683e",
    "091c2661020dce63826ea7a21745dd3a1328681f343ba256b04f852b9fef518c",
    "70f4b211d329f893ce5f75ac3e494e634546e160f96761509259f7ba6518087f",
    "a11d0ff6615b51dbaa0be8c0790c1ea550750d9f1d4d7e8893609803f269dadf",
    "2d1c9119409c908f6890062c46827698aff19b12c3bcc93ce15cb37b28b8a6e7",
    "9ce9c4153d38122398c259ed9bec013ac91afd99a8f90b70a919390321c3baae",
    "cc3faa888ba932a7346e89463435b55608529045ad33111be6a5b57a6480cac4",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205",
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867"
  ),
  stringsAsFactors = FALSE
)
fixed_exact <- vapply(
  seq_len(nrow(fixed_pins)),
  function(i) file_exact(fixed_pins$path[[i]], fixed_pins$sha256[[i]]),
  logical(1)
)
fixed_pins$observed_sha256 <- vapply(fixed_pins$path, sha256_file, character(1))
fixed_pins$bytes <- vapply(fixed_pins$path, file_bytes, numeric(1))
fixed_pins$exact <- fixed_exact
write.csv(
  fixed_pins,
  file.path(evidence_dir, "fixed_identity_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "identity",
  "fixed_inputs_and_held_outputs",
  all(fixed_exact),
  sprintf("exact=%d/%d", sum(fixed_exact), length(fixed_exact))
)

html_path <- "_build/nathealth/notebooks/hypotheses/H10.html"
result_html_sha256 <- sha256_file(html_path)
result_html_bytes <- file_bytes(html_path)
add_check(
  "render",
  "fresh_result_html",
  identical(
    result_html_sha256,
    "37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14"
  ) && result_html_bytes == 359702,
  sprintf("sha256=%s bytes=%s", result_html_sha256, result_html_bytes)
)

doc <- read_html(html_path)
main <- xml_find_first(doc, "//main[@id='quarto-document-content']")
stopifnot(!inherits(main, "xml_missing"))
main_text <- gsub("[[:space:]]+", " ", xml_text(main))

required_html <- c(
  "Answer in brief",
  "Personal light exposure metrics depend on age and gender",
  "measured biological sex",
  "Age, per 10 years",
  "Female minus Male",
  "Time below 10 lx melEDI before sleep",
  "Current MDER associations",
  "702 participant-days from 137 participants",
  "687 participant-days from 137 participants",
  "Every finite primary and gap-timing-unaware MDER value is strictly positive",
  "A day with no viable momentary ratio is reason-coded missing",
  "Gaussian",
  "FDR-adjusted p",
  "Near eye (primary)",
  "Chest (complementary)",
  "Overview of statistically supported associations",
  "every main association that met its separately labelled 17-metric FDR rule",
  "295 de-identified participant display rows",
  "Twenty-five models were assessed acceptable",
  "43 acceptable with specified limitations",
  "zero not acceptable",
  "Core residual checks",
  "68-page diagnostic appendix",
  "gap-timing-unaware dataset",
  "applies the same general coverage rules as the primary dataset",
  paste0(
    "does not use the timing of remaining missing observations ",
    "for metric-specific adjustment"
  ),
  "not an equivalence margin",
  "IS and IV were unavailable",
  "R 4.6.1"
)
required_present <- vapply(required_html, grepl, logical(1), x = main_text, fixed = TRUE)
required_audit <- data.frame(
  required_text = required_html,
  present = required_present,
  stringsAsFactors = FALSE
)
write.csv(
  required_audit,
  file.path(evidence_dir, "reader_required_text_audit.csv"),
  row.names = FALSE,
  na = ""
)
missing_required <- required_html[!required_present]
qmd <- read_text("notebooks/hypotheses/H10.qmd")
add_check(
  "stopped_test",
  "single_missing_reader_assertion",
  length(missing_required) == 1L &&
    identical(missing_required, "Overview of statistically supported associations") &&
    !grepl(missing_required, qmd, fixed = TRUE) &&
    grepl(
      "The 11 main associations retained after FDR adjustment.",
      main_text,
      fixed = TRUE
    ),
  paste(missing_required, collapse = "|")
)

construct_required <- c(
  "Biological sex and gender were recorded as separate variables",
  "accepted analyses used biological sex, coded Female or Male",
  "gender was not analysed",
  "analysis provides no inference about gender identity",
  "gender was recorded separately but not analysed"
)
add_check(
  "construct",
  "rendered_sex_gender_boundary",
  all(vapply(construct_required, grepl, logical(1), x = main_text, fixed = TRUE)) &&
    !grepl("neither measured nor inferred", main_text, fixed = TRUE) &&
    !grepl("No gender field", main_text, fixed = TRUE),
  "positive=5/5 false_phrases=0"
)

gt_xpath <- paste0(
  ".//table[contains(concat(' ', normalize-space(@class), ' '),",
  " ' gt_table ')]"
)
gt_tables <- xml_find_all(main, gt_xpath)
figures <- xml_find_all(
  main,
  ".//figure//img[contains(concat(' ', normalize-space(@class), ' '), ' figure-img ')]"
)
table_endpoints <- vapply(gt_tables, function(table) {
  endpoint <- xml_find_first(table, "ancestor::*[@id and starts-with(@id,'tbl-')][1]")
  if (inherits(endpoint, "xml_missing")) return(NA_character_)
  xml_attr(endpoint, "id")
}, character(1))
figure_endpoints <- vapply(figures, function(image) {
  endpoint <- xml_find_first(image, "ancestor::*[@id and starts-with(@id,'fig-')][1]")
  if (inherits(endpoint, "xml_missing")) return(NA_character_)
  xml_attr(endpoint, "id")
}, character(1))
add_check(
  "structure",
  "native_tables_and_figures",
  length(gt_tables) == 15L && length(figures) == 8L &&
    !anyNA(table_endpoints) && !anyDuplicated(table_endpoints) &&
    !anyNA(figure_endpoints) && !anyDuplicated(figure_endpoints),
  sprintf("tables=%d figures=%d", length(gt_tables), length(figures))
)

summary_path <- file.path(semantic_dir, "gt_html_semantic_post_render_summary.csv")
ledger_path <- file.path(
  semantic_dir,
  "001__build__nathealth__notebooks__hypotheses__H10.html_gt_semantic_ledger.csv"
)
stopifnot(file.exists(summary_path), file.exists(ledger_path))
semantic_summary <- read.csv(summary_path, check.names = FALSE)
ledger <- read.csv(ledger_path, check.names = FALSE)

engine <- new.env(parent = globalenv())
sys.source("scripts/report_harmonization/repair_gt_html_semantics.R", envir = engine)
current_raw <- engine$read_file_raw(html_path)
reversed_raw <- engine$apply_raw_replacements(current_raw, ledger, reverse = TRUE)
reapplied_raw <- engine$apply_raw_replacements(reversed_raw, ledger, reverse = FALSE)
semantic_reverse <- data.frame(
  check = c(
    "current_matches_summary_post",
    "reverse_matches_summary_pre",
    "reapplication_matches_current",
    "ledger_rows_match_summary",
    "headers_rows",
    "id_rows"
  ),
  pass = c(
    identical(engine$sha256_raw(current_raw), semantic_summary$post_sha256[[1L]]),
    identical(engine$sha256_raw(reversed_raw), semantic_summary$pre_sha256[[1L]]),
    identical(reapplied_raw, current_raw),
    nrow(ledger) == semantic_summary$total_substitutions[[1L]],
    sum(ledger$attribute == "headers") == semantic_summary$headers_count[[1L]],
    sum(ledger$attribute == "id") == semantic_summary$id_count[[1L]]
  ),
  detail = c(
    engine$sha256_raw(current_raw),
    engine$sha256_raw(reversed_raw),
    engine$sha256_raw(reapplied_raw),
    as.character(nrow(ledger)),
    as.character(sum(ledger$attribute == "headers")),
    as.character(sum(ledger$attribute == "id"))
  ),
  stringsAsFactors = FALSE
)
write.csv(
  semantic_reverse,
  file.path(evidence_dir, "semantic_reverse_and_reapply_audit.csv"),
  row.names = FALSE,
  na = ""
)

doc_ids <- xml_attr(xml_find_all(doc, ".//*[@id]"), "id")
doc_ids <- doc_ids[!is.na(doc_ids) & nzchar(doc_ids)]
headers_valid <- all(vapply(gt_tables, function(table) {
  id_nodes <- xml_find_all(table, "self::*[@id] | .//*[@id]")
  ids <- xml_attr(id_nodes, "id")
  values <- xml_attr(xml_find_all(table, "self::*[@headers] | .//*[@headers]"), "headers")
  all(vapply(values, function(value) {
    tokens <- strsplit(value, "[[:space:]]+")[[1L]]
    positions <- match(tokens, ids)
    length(tokens) > 0L && !anyNA(positions) &&
      all(vapply(tokens, function(token) sum(ids == token) == 1L, logical(1))) &&
      all(xml_name(id_nodes[positions]) == "th") &&
      all(xml_attr(id_nodes[positions], "scope") %in% c("col", "row", "colgroup", "rowgroup"))
  }, logical(1)))
}, logical(1)))
add_check(
  "semantics",
  "repair_reverse_reapply_and_headers",
  nrow(semantic_summary) == 1L &&
    identical(semantic_summary$disposition[[1L]], "REPAIRED") &&
    semantic_summary$table_count[[1L]] == 15L &&
    all(semantic_reverse$pass) &&
    !anyDuplicated(doc_ids) && headers_valid,
  sprintf(
    "disposition=%s tables=%d ids=%d headers=%d substitutions=%d",
    semantic_summary$disposition[[1L]],
    semantic_summary$table_count[[1L]],
    semantic_summary$id_count[[1L]],
    semantic_summary$headers_count[[1L]],
    semantic_summary$total_substitutions[[1L]]
  )
)

stage3_manifest <- read.csv(
  "artifacts/12_manifests/H10/H10_stage3_artifacts.csv",
  check.names = FALSE
)
stage3_sha <- vapply(stage3_manifest$path, sha256_file, character(1))
stage3_mismatch <- stage3_manifest$path[stage3_sha != stage3_manifest$sha256]
expected_post_mismatch <- c(
  "audit/hypotheses/H10/H10_analysis_preparation.qmd",
  "tests/hypotheses/H10/test_h10_preparation_report.R",
  "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
  "_build/nathealth/notebooks/hypotheses/H10.html",
  "notebooks/hypotheses/H10.qmd",
  "_quarto-nathealth.yml"
)
write.csv(
  data.frame(
    path = stage3_mismatch,
    historical_sha256 = stage3_manifest$sha256[match(stage3_mismatch, stage3_manifest$path)],
    live_sha256 = stage3_sha[match(stage3_mismatch, stage3_manifest$path)],
    stringsAsFactors = FALSE
  ),
  file.path(evidence_dir, "stage3_historical_transition_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "historical_manifest",
  "six_post_render_transitions",
  length(stage3_mismatch) == 6L && setequal(stage3_mismatch, expected_post_mismatch),
  paste(sort(stage3_mismatch), collapse = "|")
)

scientific_assets <- sort(c(
  list.files("artifacts/09_tables/H10", full.names = TRUE, recursive = FALSE),
  list.files("artifacts/10_figures/H10", full.names = TRUE, recursive = FALSE),
  list.files("artifacts/11_source_data/H10", full.names = TRUE, recursive = FALSE)
))
scientific_assets <- scientific_assets[file.info(scientific_assets)$isdir %in% FALSE]
asset_rows <- match(scientific_assets, stage3_manifest$path)
asset_exact <- vapply(seq_along(scientific_assets), function(i) {
  row <- asset_rows[[i]]
  !is.na(row) && file_exact(
    scientific_assets[[i]],
    stage3_manifest$sha256[[row]],
    stage3_manifest$bytes[[row]]
  )
}, logical(1))
add_check(
  "scientific_assets",
  "fifty_seven_preserved",
  length(scientific_assets) == 57L && all(asset_exact),
  sprintf("exact=%d/%d", sum(asset_exact), length(asset_exact))
)

phase4 <- read.csv("audit/report_harmonization/phase4_corpus_manifest.csv", check.names = FALSE)
h10_phase4 <- phase4[phase4$expected_html == html_path, , drop = FALSE]
add_check(
  "phase4",
  "historical_result_transition",
  nrow(h10_phase4) == 1L &&
    identical(h10_phase4$html_sha256[[1L]], "6bd3da932b7f743c2c28b2b5abe7a3772fc2ee6587c75f6fff1dca8910332c84") &&
    !identical(h10_phase4$html_sha256[[1L]], result_html_sha256),
  sprintf("historical=%s live=%s", h10_phase4$html_sha256[[1L]], result_html_sha256)
)

inventory_tree <- function(directory) {
  base <- normalizePath(directory, winslash = "/", mustWork = TRUE)
  entries <- list.files(
    base,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    include.dirs = TRUE
  )
  links <- Sys.readlink(entries)
  info <- file.info(entries)
  is_file <- !info$isdir & !nzchar(links)
  hashes <- rep(NA_character_, length(entries))
  hashes[is_file] <- vapply(entries[is_file], sha256_file, character(1))
  data.frame(
    path = substring(entries, nchar(root) + 2L),
    type = ifelse(nzchar(links), "symlink", ifelse(info$isdir, "directory", "file")),
    sha256 = hashes,
    bytes = ifelse(is_file, as.numeric(info$size), NA_real_),
    link_target = links,
    stringsAsFactors = FALSE
  )
}

build_pre <- read.csv(file.path(control_dir, "build_inventory_prerender.csv"), check.names = FALSE)
build_post <- inventory_tree("_build/nathealth")
build_pre$sha256[!is.na(build_pre$sha256) & !nzchar(build_pre$sha256)] <- NA_character_
build_post$sha256[!is.na(build_post$sha256) & !nzchar(build_post$sha256)] <- NA_character_
all_build_paths <- sort(unique(c(build_pre$path, build_post$path)))
pre_index <- match(all_build_paths, build_pre$path)
post_index <- match(all_build_paths, build_post$path)
build_delta <- data.frame(
  path = all_build_paths,
  pre_sha256 = build_pre$sha256[pre_index],
  post_sha256 = build_post$sha256[post_index],
  pre_bytes = build_pre$bytes[pre_index],
  post_bytes = build_post$bytes[post_index],
  pre_type = build_pre$type[pre_index],
  post_type = build_post$type[post_index],
  stringsAsFactors = FALSE
)
same <- (is.na(build_delta$pre_sha256) & is.na(build_delta$post_sha256) &
  build_delta$pre_type == build_delta$post_type) |
  (!is.na(build_delta$pre_sha256) & !is.na(build_delta$post_sha256) &
    build_delta$pre_sha256 == build_delta$post_sha256 &
    build_delta$pre_type == build_delta$post_type)
same[is.na(same)] <- FALSE
build_delta <- build_delta[!same, , drop = FALSE]
write.csv(
  build_delta,
  file.path(evidence_dir, "build_delta_after_single_render.csv"),
  row.names = FALSE,
  na = ""
)
allowed_build_delta <- grepl(
  paste0(
    "^_build/nathealth/(notebooks/hypotheses/H10(?:\\.html|_files/)|",
    "search\\.json$|sitemap\\.xml$)"
  ),
  build_delta$path,
  perl = TRUE
)
add_check(
  "filesystem",
  "single_target_build_delta",
  nrow(build_delta) >= 1L && all(allowed_build_delta) &&
    sum(build_post$type == "symlink") == 0L,
  sprintf("delta_rows=%d symlinks=%d", nrow(build_delta), sum(build_post$type == "symlink"))
)

copied_preflight <- file.copy(
  file.path(control_dir, "preflight_checks.csv"),
  file.path(evidence_dir, "preflight_checks.csv"),
  overwrite = TRUE,
  copy.mode = TRUE
)
copied_diff <- file.copy(
  file.path(control_dir, "reader_test_zero_context.diff"),
  file.path(evidence_dir, "reader_test_zero_context.diff"),
  overwrite = TRUE,
  copy.mode = TRUE
)
add_check(
  "evidence",
  "preflight_and_transition_evidence_copied",
  isTRUE(copied_preflight) && isTRUE(copied_diff),
  "preflight checks and zero-context test diff retained"
)

execution <- data.frame(
  operation = c("quarto_result_render", "postimage_reader_test", "loopback_visual_qa"),
  invocation_count = c(1L, 1L, 0L),
  exit_status = c(0L, 1L, NA_integer_),
  disposition = c(
    "completed_first_and_only_invocation",
    "failed_required_rendered_text_contract_no_retry",
    "not_started_because_nonvisual_gate_failed"
  ),
  detail = c(
    paste0("fresh result HTML ", result_html_sha256),
    paste0(
      "missing exact phrase: Overview of statistically supported associations; ",
      "phrase absent from frozen accepted QMD and fresh HTML"
    ),
    "no loopback server or browser QA was started"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  execution,
  file.path(evidence_dir, "execution_and_stop_record.csv"),
  row.names = FALSE,
  na = ""
)

audit <- do.call(rbind, checks)
write.csv(
  audit,
  file.path(evidence_dir, "fail_closed_verification_checks.csv"),
  row.names = FALSE,
  na = ""
)
if (!all(audit$pass)) {
  print(audit[!audit$pass, , drop = FALSE])
  stop("The Order 58 fail-closed evidence seal itself failed.", call. = FALSE)
}

record <- c(
  "# REPORT-018 H10 order 58 fail-closed record",
  "",
  paste0("Sealed UTC: ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "",
  "## Disposition",
  "",
  "Order 58 is stopped after its single authorized result render and single authorized postimage reader-test execution. No retry, companion render, scientific recomputation, visual-QA server, browser QA, source-page edit, historical-manifest edit, profile edit, H11 action, commit, push, or upload was performed.",
  "",
  "The render itself exited 0 and produced the fresh result HTML at SHA-256 `37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14`. The semantic hook reported `REPAIRED` for all 15 native gt tables and its 1,130 substitutions reverse exactly to the recorded pre-hook HTML and reapply exactly to the current HTML.",
  "",
  "The exact accepted postimage test then exited 1 at its required rendered-text list. A read-only diagnosis found exactly one missing string: `Overview of statistically supported associations`. That string is absent from both the frozen accepted result QMD and the fresh result HTML. The rendered Table 4 instead carries the accepted caption `The 11 main associations retained after FDR adjustment.` All other 28 required rendered strings in that test list are present.",
  "",
  "This is an accepted-test/checker contract defect exposed by a genuine fresh render, not a source or scientific defect. The frozen QMD, held companion, 57 scientific assets, model and demographic inputs, historical manifests, profile, hook, engine, lockfile, phase-4 manifest, and H11 source retain their required identities. The corrected biological-sex and gender boundary is present in prose and Figure 3, both prohibited false phrases remain absent, and the no-inference-about-gender-identity limitation is intact.",
  "",
  "## Required next action",
  "",
  "The coordinator must issue a new sealed order with an independently accepted reader-test correction before any result test retry, rerender, or visual QA. The current fresh HTML and external semantic evidence directory are retained for that decision.",
  "",
  "## External semantic evidence",
  "",
  paste0("- `", summary_path, "`, SHA-256 `", sha256_file(summary_path), "`."),
  paste0("- `", ledger_path, "`, SHA-256 `", sha256_file(ledger_path), "`."),
  ""
)
record_path <- file.path(evidence_dir, "order58_fail_closed_record.md")
writeLines(record, record_path, useBytes = TRUE)

local_evidence <- list.files(
  evidence_dir,
  full.names = TRUE,
  recursive = FALSE,
  all.files = TRUE,
  no.. = TRUE
)
manifest_path <- file.path(evidence_dir, "order58_non_circular_evidence_manifest.csv")
local_evidence <- local_evidence[
  !dir.exists(local_evidence) & normalizePath(local_evidence, winslash = "/", mustWork = TRUE) !=
    normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
]
external_evidence <- c(summary_path, ledger_path)
manifest_files <- c(sort(local_evidence), external_evidence)
manifest <- data.frame(
  path = ifelse(
    startsWith(manifest_files, paste0(root, "/")),
    substring(manifest_files, nchar(root) + 2L),
    manifest_files
  ),
  sha256 = vapply(manifest_files, sha256_file, character(1)),
  bytes = vapply(manifest_files, file_bytes, numeric(1)),
  evidence_role = c(
    rep("order58_task_owned_evidence", length(local_evidence)),
    "external_semantic_summary",
    "external_semantic_ledger"
  ),
  stringsAsFactors = FALSE
)
stopifnot(!anyDuplicated(manifest$path), !manifest_path %in% manifest_files)
write.csv(manifest, manifest_path, row.names = FALSE, na = "")

cat(sprintf(
  paste0(
    "REPORT018_H10_ORDER58=FAIL_CLOSED sealed_checks=%d missing_reader_strings=1 ",
    "render_invocations=1 test_invocations=1 retries=0 visual_qa=0 ",
    "html=%s evidence_manifest=%s\n"
  ),
  nrow(audit),
  result_html_sha256,
  sha256_file(manifest_path)
))
