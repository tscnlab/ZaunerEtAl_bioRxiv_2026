#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

project_root <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "")
if (!nzchar(project_root) || !dir.exists(project_root)) {
  stop("NATHEALTH_PROJECT_ROOT must name the existing project root.")
}
project_root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)

evidence_rel <- "audit/hypotheses/H07/report018_order53_companion_render"
evidence_dir <- file.path(project_root, evidence_rel)
finalizer_path <- file.path(evidence_dir, "finalize_order53_stopped_state.R")
record_path <- file.path(evidence_dir, "ORDER53_FAIL_CLOSED_STOP.txt")
manifest_path <- file.path(evidence_dir, "ORDER53_STOPPED_STATE_MANIFEST.csv")

if (file.exists(record_path) || file.exists(manifest_path)) {
  stop("The stopped-state record or manifest already exists; refusing a second finalization.")
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

relative_to_root <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(project_root, "/")
  if (startsWith(normalized, prefix)) {
    substring(normalized, nchar(prefix) + 1L)
  } else {
    normalized
  }
}

identity_row <- function(category, endpoint, path, expected_sha256 = "") {
  exists <- file.exists(path)
  data.frame(
    category = category,
    endpoint = endpoint,
    path = relative_to_root(path),
    exists = exists,
    sha256 = if (exists) sha256_file(path) else "",
    bytes = if (exists) unname(file.info(path)$size) else NA_real_,
    expected_sha256 = expected_sha256,
    status = if (exists) "PRESENT" else "MISSING",
    stringsAsFactors = FALSE
  )
}

read_evidence_csv <- function(name) {
  read.csv(file.path(evidence_dir, name), check.names = FALSE)
}

required_evidence <- c(
  "nonvisual_acceptance_checks.csv",
  "fail_closed_defects.csv",
  "protected_delta_posthelper.csv",
  "reader_link_audit.csv",
  "table_endpoint_audit.csv",
  "png_figure_endpoint_audit.csv",
  "mermaid_endpoint_audit.csv",
  "gt_html_semantic_post_render_summary.csv",
  "001__build__nathealth__audit__hypotheses__H07__H07_analysis_preparation.html_gt_semantic_ledger.csv",
  "live_manifest_audit.csv",
  "result_reader_test_audit.csv",
  "held_preparation_test_audit.csv"
)
missing_evidence <- required_evidence[
  !file.exists(file.path(evidence_dir, required_evidence))
]
if (length(missing_evidence)) {
  stop("Required evidence missing: ", paste(missing_evidence, collapse = ", "))
}

historical_html_rel <- "audit/hypotheses/H07/H07_analysis_preparation.html"
historical_html <- file.path(project_root, historical_html_rel)
historical_asset_rel <- "audit/hypotheses/H07/H07_analysis_preparation_files"
historical_asset_dir <- file.path(project_root, historical_asset_rel)
if (file.exists(historical_html) || dir.exists(historical_asset_dir)) {
  stop("The fail-closed missing historical endpoint state has changed.")
}

protected_delta <- read_evidence_csv("protected_delta_posthelper.csv")
removed <- protected_delta[protected_delta$delta == "REMOVED", , drop = FALSE]
if (nrow(removed) != 16L || !historical_html_rel %in% removed$relative_path) {
  stop("Expected exactly 16 removed protected paths including the historical HTML.")
}
removed_assets <- removed[startsWith(removed$relative_path, paste0(historical_asset_rel, "/")), , drop = FALSE]
if (nrow(removed_assets) != 15L) {
  stop("Expected exactly 15 removed historical companion assets.")
}

links <- read_evidence_csv("reader_link_audit.csv")
links$applicable_file_or_fragment_link <- !grepl(
  "^javascript:",
  links$href,
  ignore.case = TRUE
)
links$corrected_status <- ifelse(
  links$applicable_file_or_fragment_link,
  links$status,
  "EXCLUDED_QUARTO_CONTROL"
)
corrected_link_path <- file.path(evidence_dir, "reader_link_corrected_audit.csv")
write.csv(links, corrected_link_path, row.names = FALSE, na = "")
applicable_links <- links[links$applicable_file_or_fragment_link, , drop = FALSE]
if (nrow(applicable_links) != 405L || any(applicable_links$corrected_status != "PASS")) {
  stop("Corrected applicable-link check did not produce 405 of 405 PASS.")
}
if (sum(!links$applicable_file_or_fragment_link) != 3L ||
    !all(links$href[!links$applicable_file_or_fragment_link] == "javascript:void(0)")) {
  stop("Unexpected excluded-link set.")
}

ps_output <- system2(
  "ps",
  c("-axo", "pid=,ppid=,command="),
  stdout = TRUE,
  stderr = TRUE
)
process_pattern <- paste(
  c(
    "quarto",
    "pandoc",
    "post_render_gt_html_semantics",
    "repair_gt_html_semantics",
    "H07-order53-semantic",
    "http[.]server"
  ),
  collapse = "|"
)
process_matches <- ps_output[grepl(process_pattern, ps_output, ignore.case = TRUE)]
process_path <- file.path(evidence_dir, "process_teardown_audit.csv")
process_audit <- data.frame(
  check = c(
    "relevant process matches",
    "Order 53 loopback listener started",
    "browser QA",
    "teardown"
  ),
  observed = c(
    as.character(length(process_matches)),
    "FALSE",
    "NOT_RUN_GATED",
    "NO_OP_NO_LISTENER_AND_NO_RELEVANT_PROCESS"
  ),
  expected = c("0", "FALSE", "NOT_RUN_GATED", "NO_OP_NO_LISTENER_AND_NO_RELEVANT_PROCESS"),
  status = c(
    if (length(process_matches) == 0L) "PASS" else "FAIL",
    "PASS",
    "PASS",
    if (length(process_matches) == 0L) "PASS" else "FAIL"
  ),
  stringsAsFactors = FALSE
)
write.csv(process_audit, process_path, row.names = FALSE, na = "")
if (any(process_audit$status != "PASS")) {
  stop("A relevant Order 53 process remains.")
}

semantic_dir <- "/private/tmp/H07-order53-semantic.tbIeZC"
semantic_summary_external <- file.path(
  semantic_dir,
  "gt_html_semantic_post_render_summary.csv"
)
semantic_ledger_external <- file.path(
  semantic_dir,
  "001__build__nathealth__audit__hypotheses__H07__H07_analysis_preparation.html_gt_semantic_ledger.csv"
)

file_endpoints <- list(
  identity_row(
    "control",
    "order 53",
    file.path(project_root, "audit/report_harmonization/owner_orders/53_h07_companion_report018_render.md"),
    "988d0773e2b2ed05696a0fb1d2d717384a5d80f80ae976612706f82c7eed7c9b"
  ),
  identity_row(
    "control",
    "central release",
    file.path(project_root, "audit/report_harmonization/report018_h07_companion_release.md"),
    "4d3948848ad229e128dbeee6be98b3142e688b47eb2d6d0f2cb8f1baf8ddb085"
  ),
  identity_row(
    "control",
    "dispatch manifest",
    file.path(project_root, "audit/report_harmonization/report018_h07_companion_order53_dispatch_manifest.csv"),
    "d5a405c26a998f9a2944262ff44cb78bfe4eaa3925d26b8ec8c69914d9ea138b"
  ),
  identity_row(
    "control",
    "current coordination matrix",
    file.path(project_root, "audit/report_harmonization/coordination_matrix.csv")
  ),
  identity_row(
    "result",
    "accepted result source",
    file.path(project_root, "notebooks/hypotheses/H07.qmd"),
    "c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226"
  ),
  identity_row(
    "result",
    "accepted result HTML",
    file.path(project_root, "_build/nathealth/notebooks/hypotheses/H07.html"),
    "7814860467f71311c56e22960e757059524ccc3890b0721708eda7a5c661ab40"
  ),
  identity_row(
    "companion",
    "released companion source",
    file.path(project_root, "audit/hypotheses/H07/H07_analysis_preparation.qmd"),
    "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b"
  ),
  identity_row(
    "companion",
    "source-identical build QMD",
    file.path(project_root, "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.qmd"),
    "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b"
  ),
  identity_row(
    "companion",
    "rendered and semantically repaired build HTML",
    file.path(project_root, "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html"),
    "4c03a3e3cdfa1c6eac13d5785ceee8306e6d0941278b679a1eb88e357b270d93"
  ),
  identity_row(
    "companion",
    "missing source-side historical HTML",
    historical_html,
    "53c261b88b5d10238e18e33323ad705c61c92215c040fc84880385cdc434fd2f"
  ),
  identity_row(
    "manifest",
    "preparation report manifest",
    file.path(project_root, "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv"),
    "db1b00058848d27eed9d5ece9d9eae97851d1bdc997c4f2fe28d2ce9abd3c8e2"
  ),
  identity_row(
    "profile",
    "normal nathealth profile",
    file.path(project_root, "_quarto-nathealth.yml"),
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3"
  ),
  identity_row(
    "helper",
    "dedicated preparation manifest helper",
    file.path(project_root, "scripts/hypotheses/H07/build_h07_preparation_report_manifest.R"),
    "9e961ec8746f512f34d1330b227118e407a75260168619a6457413a3ecb74508"
  ),
  identity_row(
    "test",
    "held preparation test",
    file.path(project_root, "tests/hypotheses/H07/test_h07_preparation_report.R"),
    "89fd3eaa2f4f9928234280844e480ff5b863e104366af17675fe36366c456558"
  ),
  identity_row(
    "test",
    "executed unchanged result reader test",
    file.path(project_root, "tests/hypotheses/H07/test_h07_stage3_reader_report.R"),
    "84e96a523bf1d9051be8abe3cabbef9837dfe98ab978a30bd846d0f2d728cd17"
  ),
  identity_row(
    "semantic",
    "external semantic summary",
    semantic_summary_external,
    "43df6cca4556ed9ce4d42f19207940dcfa435f67290a317120c2188690d98334"
  ),
  identity_row(
    "semantic",
    "external semantic ledger",
    semantic_ledger_external,
    "5269f9d8ea846195387a15372772d0d286fabc0661d9e8eb7181f448372e5a1f"
  ),
  identity_row(
    "semantic",
    "durable semantic summary copy",
    file.path(evidence_dir, "gt_html_semantic_post_render_summary.csv"),
    "43df6cca4556ed9ce4d42f19207940dcfa435f67290a317120c2188690d98334"
  ),
  identity_row(
    "semantic",
    "durable semantic ledger copy",
    file.path(evidence_dir, "001__build__nathealth__audit__hypotheses__H07__H07_analysis_preparation.html_gt_semantic_ledger.csv"),
    "5269f9d8ea846195387a15372772d0d286fabc0661d9e8eb7181f448372e5a1f"
  ),
  identity_row(
    "figure",
    "fig-h07-prep-metric-sample-support source PNG",
    file.path(project_root, "artifacts/10_figures/H07/preparation/H07_preparation_metric_sample_support.png"),
    "603afa8def8ff640003daaef806ee390d513df9bb6f6307fa300dba4ad5ba8a7"
  ),
  identity_row(
    "figure",
    "fig-h07-prep-site-photoperiod-ranges source PNG",
    file.path(project_root, "artifacts/10_figures/H07/preparation/H07_preparation_site_photoperiod_ranges.png"),
    "00d687082780c65d07467fdf730ac8bcf0bd97af11a03af156dc38020b815eb4"
  )
)
endpoint_identities <- do.call(rbind, file_endpoints)

expected_rows <- endpoint_identities$expected_sha256 != "" & endpoint_identities$exists
if (any(endpoint_identities$sha256[expected_rows] != endpoint_identities$expected_sha256[expected_rows])) {
  stop("A current endpoint identity drifted before stopped-state sealing.")
}

tables <- read_evidence_csv("table_endpoint_audit.csv")
pngs <- read_evidence_csv("png_figure_endpoint_audit.csv")
mermaid <- read_evidence_csv("mermaid_endpoint_audit.csv")
if (nrow(tables) != 21L || any(tables$status != "PASS") ||
    nrow(pngs) != 2L || any(pngs$status != "PASS") ||
    nrow(mermaid) != 1L || any(mermaid$status != "PASS")) {
  stop("Rendered endpoint contract changed before stopped-state sealing.")
}

build_html_rel <- "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html"
build_html_hash <- "4c03a3e3cdfa1c6eac13d5785ceee8306e6d0941278b679a1eb88e357b270d93"
build_html_bytes <- 654955

table_rows <- data.frame(
  category = "native_gt_table",
  endpoint = tables$endpoint,
  path = build_html_rel,
  exists = TRUE,
  sha256 = build_html_hash,
  bytes = build_html_bytes,
  expected_sha256 = build_html_hash,
  status = tables$status,
  stringsAsFactors = FALSE
)
png_rows <- data.frame(
  category = "png_figure",
  endpoint = pngs$endpoint,
  path = vapply(pngs$resolved_path, relative_to_root, character(1)),
  exists = pngs$image_exists,
  sha256 = pngs$image_sha256,
  bytes = vapply(pngs$resolved_path, function(path) unname(file.info(path)$size), numeric(1)),
  expected_sha256 = pngs$expected_sha256,
  status = pngs$status,
  stringsAsFactors = FALSE
)
mermaid_rows <- data.frame(
  category = "mermaid_diagram",
  endpoint = mermaid$endpoint,
  path = build_html_rel,
  exists = TRUE,
  sha256 = mermaid$node_text_sha256,
  bytes = NA_real_,
  expected_sha256 = mermaid$node_text_sha256,
  status = mermaid$status,
  stringsAsFactors = FALSE
)
removed_rows <- data.frame(
  category = ifelse(
    removed$relative_path == historical_html_rel,
    "missing_historical_html",
    "missing_historical_asset"
  ),
  endpoint = basename(removed$relative_path),
  path = removed$relative_path,
  exists = FALSE,
  sha256 = "",
  bytes = NA_real_,
  expected_sha256 = removed$sha256_pre,
  status = "MISSING",
  stringsAsFactors = FALSE
)
endpoint_identities <- rbind(endpoint_identities, table_rows, png_rows, mermaid_rows, removed_rows)
endpoint_identity_path <- file.path(evidence_dir, "current_endpoint_identities.csv")
write.csv(endpoint_identities, endpoint_identity_path, row.names = FALSE, na = "")

semantic_summary <- read_evidence_csv("gt_html_semantic_post_render_summary.csv")
if (nrow(semantic_summary) != 1L ||
    semantic_summary$disposition != "REPAIRED" ||
    semantic_summary$table_count != 21L ||
    semantic_summary$total_substitutions != 850L) {
  stop("Semantic-hook summary changed before stopped-state sealing.")
}

live_manifest <- read_evidence_csv("live_manifest_audit.csv")
if (nrow(live_manifest) != 1235L || any(!live_manifest$exact)) {
  stop("The helper manifest is no longer 1235 of 1235 live-exact.")
}
helper_manifest <- read.csv(
  file.path(project_root, "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv"),
  check.names = FALSE
)
if (anyDuplicated(helper_manifest$path) ||
    nrow(helper_manifest) != 1235L ||
    "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv" %in% helper_manifest$path) {
  stop("The helper manifest is not unique and non-circular.")
}

result_test <- read_evidence_csv("result_reader_test_audit.csv")
held_test <- read_evidence_csv("held_preparation_test_audit.csv")
if (nrow(result_test) != 1L || result_test$status != "PASS" ||
    nrow(held_test) != 1L || held_test$status != "PASS" || held_test$executed) {
  stop("Test-state evidence changed before stopped-state sealing.")
}

asset_lines <- sprintf(
  "  - %s | pre SHA-256 %s | %s bytes | current MISSING",
  removed_assets$relative_path,
  removed_assets$sha256_pre,
  format(removed_assets$bytes_pre, scientific = FALSE, trim = TRUE)
)
table_lines <- sprintf("  - %02d %s", tables$order, tables$endpoint)
figure_lines <- c(
  sprintf(
    "  - %s | SHA-256 %s | %s",
    pngs$endpoint,
    pngs$image_sha256,
    vapply(pngs$resolved_path, relative_to_root, character(1))
  ),
  sprintf(
    "  - %s | TD Mermaid node-text SHA-256 %s | %s",
    mermaid$endpoint,
    mermaid$node_text_sha256,
    build_html_rel
  )
)
file_identity_lines <- vapply(seq_len(nrow(endpoint_identities[endpoint_identities$category %in% c(
  "control", "result", "companion", "manifest", "profile", "helper", "test", "semantic", "figure"
), , drop = FALSE])), function(index) {
  rows <- endpoint_identities[endpoint_identities$category %in% c(
    "control", "result", "companion", "manifest", "profile", "helper", "test", "semantic", "figure"
  ), , drop = FALSE]
  row <- rows[index, ]
  shown_hash <- if (row$exists) row$sha256 else paste0("MISSING; expected ", row$expected_sha256)
  shown_bytes <- if (row$exists) format(row$bytes, scientific = FALSE, trim = TRUE) else "NA"
  sprintf("  - %s | %s | SHA-256 %s | %s bytes", row$endpoint, row$path, shown_hash, shown_bytes)
}, character(1))

record_lines <- c(
  "REPORT-018 H07 Order 53 fail-closed stopped-state record",
  "",
  paste0("Recorded UTC: ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "Status: STOPPED_FAIL_CLOSED",
  "Decision: The sole render and hook succeeded, and the sole helper succeeded, but the render removed the protected source-side historical companion HTML and its complete 15-file asset tree. The preservation contract therefore failed before browser QA.",
  "",
  "Execution ledger",
  "  - Render count: exactly 1.",
  "  - Render command: GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H07-order53-semantic.tbIeZC quarto render audit/hypotheses/H07/H07_analysis_preparation.qmd --profile nathealth",
  "  - Render exit: 0. R 4.6.1 and Quarto 1.9.37.",
  "  - Analytical chunks: 26 of 26 completed. No scientific recomputation was separately invoked.",
  "  - Render retry count: 0. No result, later-page, or full-project render was run.",
  "  - Semantic hook count: exactly 1 as part of the sole render.",
  sprintf(
    "  - Semantic hook: %s; pre %s (%s bytes); post %s (%s bytes); %s tables; %s IDs; %s headers; %s substitutions.",
    semantic_summary$disposition,
    semantic_summary$pre_sha256,
    semantic_summary$pre_bytes,
    semantic_summary$post_sha256,
    semantic_summary$post_bytes,
    semantic_summary$table_count,
    semantic_summary$id_count,
    semantic_summary$headers_count,
    semantic_summary$total_substitutions
  ),
  "  - Helper count: exactly 1 after the successful render and hook.",
  paste0("  - Helper command: NATHEALTH_PROJECT_ROOT=", project_root, " Rscript --vanilla scripts/hypotheses/H07/build_h07_preparation_report_manifest.R"),
  "  - Helper exit: 0. It recorded 1,235 identities with a byte-identical build QMD and shared profile integration TRUE.",
  "  - Helper retry count: 0.",
  "",
  "Fail-closed defect",
  paste0("  - Exact missing historical HTML: ", historical_html_rel),
  "  - Historical HTML pre-render identity: SHA-256 53c261b88b5d10238e18e33323ad705c61c92215c040fc84880385cdc434fd2f, 641597 bytes.",
  paste0("  - Exact missing historical asset root: ", historical_asset_rel, "/"),
  "  - The complete 15-file asset tree is missing:",
  asset_lines,
  "  - Protected delta: 16 removed paths, comprising the HTML and 15 assets.",
  "  - Helper manifest: 1,235 unique, non-circular rows; 1,235 of 1,235 are live-exact. The missing historical HTML and assets are not restored and are not represented as live rows.",
  "",
  "Nonvisual acceptance",
  "  - Raw prepared audit: 28 checks, 24 PASS, 4 FAIL.",
  "  - Three real failed preservation checks share the same 16-path deletion: historical HTML presence, historical asset coverage, and zero removed protected paths.",
  "  - The fourth raw failure was a checker-construction false negative: Show All Code, Hide All Code, and View Source use javascript:void(0) and are not file links.",
  "  - Corrected applicable reader-link check: 405 of 405 PASS; three Quarto JavaScript controls excluded explicitly.",
  "  - Result reader test: unchanged, exit 0, PASS.",
  "  - Held preparation test: unchanged and not executed.",
  "",
  "Current file identities",
  file_identity_lines,
  "",
  "Current rendered table endpoints",
  table_lines,
  "",
  "Current rendered figure endpoints",
  figure_lines,
  "",
  "Browser and teardown state",
  "  - Browser QA: NOT_RUN_GATED.",
  "  - Unrun viewports: 1440 x 1000; 708 x 1000; 720 x 500 at 200-percent equivalent; 170 mm figure inspection.",
  "  - Secure loopback server: never started for Order 53.",
  "  - Screenshots, browser console inspection, and interactive link checks: not run.",
  "  - Corrected elevated process scan: zero matching Quarto, Pandoc, semantic-hook, semantic-directory, or http.server processes.",
  "  - Teardown: no-op because no browser QA listener was started; no relevant process remains.",
  "",
  "Stop boundaries",
  "  - No rerender, restoration, browser QA, source patch, source/test/helper/profile edit, retry, scientific recomputation, full-project render, commit, push, or upload followed the defect.",
  "  - The stopped-state manifest excludes itself, contains unique paths, and is validated live-exact immediately after creation."
)
writeLines(record_lines, record_path, useBytes = TRUE)

all_evidence <- list.files(
  evidence_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
all_evidence <- all_evidence[file.info(all_evidence)$isdir %in% FALSE]
all_evidence <- setdiff(normalizePath(all_evidence, winslash = "/", mustWork = TRUE), normalizePath(manifest_path, winslash = "/", mustWork = FALSE))
all_evidence <- sort(unique(all_evidence))

stopped_manifest <- data.frame(
  path = vapply(all_evidence, relative_to_root, character(1)),
  sha256 = vapply(all_evidence, sha256_file, character(1)),
  bytes = unname(file.info(all_evidence)$size),
  role = ifelse(
    basename(all_evidence) == basename(record_path),
    "consolidated fail-closed record",
    ifelse(
      basename(all_evidence) == basename(finalizer_path),
      "stopped-state finalizer",
      "Order 53 stopped-state evidence"
    )
  ),
  stringsAsFactors = FALSE
)

if (anyDuplicated(stopped_manifest$path) ||
    relative_to_root(manifest_path) %in% stopped_manifest$path) {
  stop("Stopped-state manifest would be duplicated or circular.")
}
write.csv(stopped_manifest, manifest_path, row.names = FALSE, na = "")

manifest_check <- read.csv(manifest_path, check.names = FALSE)
manifest_files <- file.path(project_root, manifest_check$path)
manifest_exact <- file.exists(manifest_files) &
  vapply(manifest_files, sha256_file, character(1)) == manifest_check$sha256 &
  unname(file.info(manifest_files)$size) == manifest_check$bytes
if (anyDuplicated(manifest_check$path) ||
    relative_to_root(manifest_path) %in% manifest_check$path ||
    !all(manifest_exact)) {
  stop("Stopped-state manifest failed final uniqueness, non-circularity, or live-exact validation.")
}

cat(
  sprintf(
    "ORDER53_STOPPED=PASS evidence_rows=%d record_sha256=%s manifest_sha256=%s process_matches=%d browser_qa=NOT_RUN_GATED\n",
    nrow(manifest_check),
    sha256_file(record_path),
    sha256_file(manifest_path),
    length(process_matches)
  )
)
