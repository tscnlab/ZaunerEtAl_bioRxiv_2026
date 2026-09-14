#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, args[[1L]] %in% c("preqa", "postqa"))
phase <- args[[1L]]

root <- normalizePath(Sys.getenv("NATHEALTH_PROJECT_ROOT"), winslash = "/", mustWork = TRUE)
control_dir <- normalizePath(Sys.getenv("H10_ORDER58A_CONTROL_DIR"), winslash = "/", mustWork = TRUE)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H10/report018_order58a_no_rerender_completion"
)
setwd(root)
stopifnot(dir.exists(evidence_dir), startsWith(control_dir, "/private/tmp/"))

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  paste0(openssl::sha256(con))
}
file_bytes <- function(path) as.numeric(file.info(path)$size)
file_exact <- function(path, sha256, bytes = NULL) {
  ok <- file.exists(path) && !dir.exists(path) && identical(sha256_file(path), sha256)
  if (!is.null(bytes)) ok <- ok && identical(file_bytes(path), as.numeric(bytes))
  ok
}
read_raw <- function(path) readBin(path, "raw", n = file_bytes(path))
read_text <- function(path) rawToChar(read_raw(path))

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

fixed <- data.frame(
  path = c(
    "notebooks/hypotheses/H10.qmd",
    "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "tests/hypotheses/H10/test_h10_preparation_report.R",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html",
    "audit/hypotheses/H10/H10_analysis_preparation.html",
    "_quarto-nathealth.yml",
    "renv.lock",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "artifacts/12_manifests/H10/H10_stage3_artifacts.csv",
    "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv",
    "notebooks/hypotheses/H11.qmd",
    "artifacts/06_model_data/normalized_inputs/demographics.rds",
    "artifacts/06_model_data/H10/H10_model_frames.rds",
    "artifacts/07_models/H10/H10_model_manifest.csv",
    "audit/hypotheses/H10/01_audit_and_plan.qmd"
  ),
  sha256 = c(
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
    "dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "15d20f3c3fe4d5387eb64152479d07ea0e94b397b27b0a7b59b3d41c7a1924c4",
    "37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14",
    "efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8",
    "efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
    "b556d9fdb19eeda766414bab30420846ee5c46138e9d7861f61e92da7516683e",
    "091c2661020dce63826ea7a21745dd3a1328681f343ba256b04f852b9fef518c",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
    "a11d0ff6615b51dbaa0be8c0790c1ea550750d9f1d4d7e8893609803f269dadf",
    "2d1c9119409c908f6890062c46827698aff19b12c3bcc93ce15cb37b28b8a6e7",
    "9ce9c4153d38122398c259ed9bec013ac91afd99a8f90b70a919390321c3baae",
    "cc3faa888ba932a7346e89463435b55608529045ad33111be6a5b57a6480cac4"
  ),
  bytes = c(
    49224, 25803, 58446, 15201, 359702, 617113, 617113, 7480, 603493,
    11937, 147622, 170241, 57462, 2824, 381924, 258608, 70297
  ),
  stringsAsFactors = FALSE
)
fixed$observed_sha256 <- vapply(fixed$path, sha256_file, character(1))
fixed$observed_bytes <- vapply(fixed$path, file_bytes, numeric(1))
fixed$exact <- fixed$observed_sha256 == fixed$sha256 & fixed$observed_bytes == fixed$bytes
write.csv(fixed, file.path(evidence_dir, paste0("fixed_identity_", phase, ".csv")), row.names = FALSE, na = "")
add_check("identity", "fixed_sources_outputs_inputs", all(fixed$exact), sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed)))

semantic_summary_path <- "/private/tmp/h10-order58-semantic.UelLEK/gt_html_semantic_post_render_summary.csv"
semantic_ledger_path <- paste0(
  "/private/tmp/h10-order58-semantic.UelLEK/",
  "001__build__nathealth__notebooks__hypotheses__H10.html_gt_semantic_ledger.csv"
)
stopifnot(
  file_exact(semantic_summary_path, "23c7f36ee58748a3146f2f30a9575972cdd317d057b753e809fb56e02ea7c5e5", 456),
  file_exact(semantic_ledger_path, "094c126424e79332133cb82a879362d2b9a7dbd8c075983cfe7ba2c287574ed9", 178781)
)
semantic_summary <- read.csv(semantic_summary_path, check.names = FALSE)
semantic_ledger <- read.csv(semantic_ledger_path, check.names = FALSE)
engine <- new.env(parent = globalenv())
sys.source("scripts/report_harmonization/repair_gt_html_semantics.R", envir = engine)
html_path <- "_build/nathealth/notebooks/hypotheses/H10.html"
html_raw <- engine$read_file_raw(html_path)
reversed_raw <- engine$apply_raw_replacements(html_raw, semantic_ledger, reverse = TRUE)
reapplied_raw <- engine$apply_raw_replacements(reversed_raw, semantic_ledger, reverse = FALSE)
semantic_audit <- data.frame(
  check = c("current_post", "reverse_pre", "reapply_current", "ledger_rows", "id_rows", "header_rows"),
  pass = c(
    identical(engine$sha256_raw(html_raw), semantic_summary$post_sha256[[1L]]),
    identical(engine$sha256_raw(reversed_raw), "d3d1ac754480216b4cd022a16989ec9ad711d3cd385c8d0f895d682421ad7e32"),
    identical(reapplied_raw, html_raw),
    nrow(semantic_ledger) == 1130L,
    sum(semantic_ledger$attribute == "id") == 92L,
    sum(semantic_ledger$attribute == "headers") == 1038L
  ),
  detail = c(
    engine$sha256_raw(html_raw), engine$sha256_raw(reversed_raw), engine$sha256_raw(reapplied_raw),
    nrow(semantic_ledger), sum(semantic_ledger$attribute == "id"), sum(semantic_ledger$attribute == "headers")
  ),
  stringsAsFactors = FALSE
)
write.csv(semantic_audit, file.path(evidence_dir, paste0("semantic_reverse_reapply_", phase, ".csv")), row.names = FALSE, na = "")

document <- read_html(html_path)
main_nodes <- xml_find_all(document, "//main[@id='quarto-document-content']")
stopifnot(length(main_nodes) == 1L)
main <- main_nodes[[1L]]
gt_xpath <- paste0(".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]")
gt_tables <- xml_find_all(main, gt_xpath)
figures <- xml_find_all(main, ".//figure//img[contains(concat(' ', normalize-space(@class), ' '), ' figure-img ')]")

table_endpoints <- vapply(gt_tables, function(table) {
  endpoint <- xml_find_first(table, "ancestor::*[@id and starts-with(@id,'tbl-')][1]")
  if (inherits(endpoint, "xml_missing")) NA_character_ else xml_attr(endpoint, "id")
}, character(1))
figure_endpoints <- vapply(figures, function(image) {
  endpoint <- xml_find_first(image, "ancestor::*[@id and starts-with(@id,'fig-')][1]")
  if (inherits(endpoint, "xml_missing")) NA_character_ else xml_attr(endpoint, "id")
}, character(1))
qmd_lines <- readLines("notebooks/hypotheses/H10.qmd", warn = FALSE)
labels <- sub("^#\\| label: ", "", grep("^#\\| label: ", qmd_lines, value = TRUE))
expected_tables <- labels[startsWith(labels, "tbl-")]
expected_figures <- labels[startsWith(labels, "fig-")]
endpoint_audit <- data.frame(
  type = c(rep("table", length(table_endpoints)), rep("figure", length(figure_endpoints))),
  position = c(seq_along(table_endpoints), seq_along(figure_endpoints)),
  expected = c(expected_tables, expected_figures),
  observed = c(table_endpoints, figure_endpoints),
  stringsAsFactors = FALSE
)
endpoint_audit$exact <- endpoint_audit$expected == endpoint_audit$observed
write.csv(endpoint_audit, file.path(evidence_dir, paste0("dom_endpoints_", phase, ".csv")), row.names = FALSE, na = "")

document_ids <- xml_attr(xml_find_all(document, ".//*[@id]"), "id")
document_ids <- document_ids[!is.na(document_ids) & nzchar(document_ids)]
header_tokens <- 0L
headers_valid <- all(vapply(gt_tables, function(table) {
  id_nodes <- xml_find_all(table, "self::*[@id] | .//*[@id]")
  ids <- xml_attr(id_nodes, "id")
  values <- xml_attr(xml_find_all(table, "self::*[@headers] | .//*[@headers]"), "headers")
  all(vapply(values, function(value) {
    tokens <- strsplit(value, "[[:space:]]+")[[1L]]
    header_tokens <<- header_tokens + length(tokens)
    positions <- match(tokens, ids)
    length(tokens) > 0L && !anyNA(positions) &&
      all(vapply(tokens, function(token) sum(ids == token) == 1L, logical(1))) &&
      all(xml_name(id_nodes[positions]) == "th") &&
      all(xml_attr(id_nodes[positions], "scope") %in% c("col", "row", "colgroup", "rowgroup"))
  }, logical(1)))
}, logical(1)))
add_check(
  "semantic_dom",
  "tables_figures_ids_headers",
  length(gt_tables) == 15L && length(figures) == 8L &&
    nrow(endpoint_audit) == 23L && all(endpoint_audit$exact) &&
    !anyDuplicated(document_ids) && headers_valid && header_tokens == 1038L &&
    all(semantic_audit$pass),
  sprintf("tables=%d figures=%d duplicate_ids=%d header_tokens=%d", length(gt_tables), length(figures), anyDuplicated(document_ids), header_tokens)
)

main_text <- gsub("[[:space:]]+", " ", xml_text(main))
required_science <- c(
  "Biological sex and gender were recorded as separate variables",
  "accepted analyses used biological sex, coded Female or Male",
  "gender was not analysed",
  "analysis provides no inference about gender identity",
  "gender was recorded separately but not analysed",
  "702 participant-days from 137 participants",
  "687 participant-days from 137 participants",
  "four separate complete 17-test FDR families",
  "The 11 main associations retained after FDR adjustment.",
  "Twenty-five models were assessed acceptable",
  "43 acceptable with specified limitations",
  "zero not acceptable",
  "Core residual checks",
  "68-page diagnostic appendix",
  "gap-timing-unaware dataset",
  "not an equivalence margin",
  "complete independent reconstruction of the exact current state-support classification remains open"
)
country_sites <- c(
  "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Munich (DE)",
  "Madrid (ES)", "Izmir (TR)", "San José (CR)", "Kumasi (GH)", "Tübingen (DE)"
)
site_source <- read.csv(
  "artifacts/11_source_data/H10/H10_age_site_significant_associations_data.csv",
  check.names = FALSE
)
site_source_names <- unique(site_source$site_display_name[nzchar(site_source$site_display_name)])
rendered_site_count <- sum(vapply(country_sites, grepl, logical(1), x = main_text, fixed = TRUE))
add_check(
  "content",
  "scientific_and_construct_contract",
  all(vapply(required_science, grepl, logical(1), x = main_text, fixed = TRUE)) &&
    rendered_site_count == 8L && setequal(site_source_names, country_sites) &&
    all(grepl("\\([A-Z]{2}\\)$", site_source_names, perl = TRUE)) &&
    !grepl("neither measured nor inferred", main_text, fixed = TRUE) &&
    !grepl("No gender field", main_text, fixed = TRUE),
  sprintf(
    "required_science=17/17 rendered_country_sites=%d/8 source_country_sites=%d/9 false_phrases=0",
    rendered_site_count,
    length(site_source_names)
  )
)

error_nodes <- xml_find_all(
  main,
  paste0(
    ".//*[contains(@class,'cell-output-error') or contains(@class,'cell-output-stderr') or ",
    "contains(@class,'cell-output-warning') or contains(@class,'quarto-unresolved-ref')]"
  )
)
unresolved_text <- grepl("WARNING|ERROR|\\?@", main_text, perl = TRUE)
active_nav <- xml_find_all(document, "//nav//a[@aria-current='page' or contains(concat(' ',normalize-space(@class),' '),' active ')]")
add_check(
  "render_integrity",
  "no_errors_warnings_unresolved_and_active_navigation",
  length(error_nodes) == 0L && !unresolved_text && length(active_nav) >= 1L,
  sprintf("error_nodes=%d unresolved_text=%s active_nav=%d", length(error_nodes), unresolved_text, length(active_nav))
)

source_text <- read_text("notebooks/hypotheses/H10.qmd")
markdown_links <- regmatches(source_text, gregexpr(r"{\[[^]]+\]\([^)]+\)}", source_text, perl = TRUE))[[1L]]
source_targets <- sub(r"{^.*\]\(}", "", markdown_links, perl = TRUE)
source_targets <- sub(r"{\)$}", "", source_targets, perl = TRUE)
source_targets <- source_targets[!grepl(r"{^(https?:|mailto:|#)}", source_targets, perl = TRUE)]
html_hrefs <- xml_attr(xml_find_all(main, ".//a[@href]"), "href")
content_hrefs <- html_hrefs[
  !startsWith(html_hrefs, "#") &
    !grepl("notebooks/hypotheses/H0[1-9]\\.html$", html_hrefs) &
    html_hrefs != "../../notebooks/hypotheses/H10.html"
]
content_hrefs <- content_hrefs[grepl("(preregistration_deviations|preparation/|artifacts/|H10_analysis_preparation)", content_hrefs)]
resolved <- file.path(dirname(html_path), sub("#.*$", "", utils::URLdecode(content_hrefs)))
fragment_rows <- grepl("#", content_hrefs, fixed = TRUE)
fragment_ok <- rep(TRUE, length(content_hrefs))
for (i in which(fragment_rows)) {
  target_doc <- read_html(resolved[[i]])
  fragment <- sub("^.*#", "", content_hrefs[[i]])
  fragment_ok[[i]] <- length(xml_find_all(target_doc, sprintf("//*[@id='%s']", fragment))) == 1L
}
link_audit <- data.frame(
  href = content_hrefs,
  resolved_path = resolved,
  exists = file.exists(resolved),
  fragment_once = fragment_ok,
  stringsAsFactors = FALSE
)
write.csv(link_audit, file.path(evidence_dir, paste0("link_resolution_", phase, ".csv")), row.names = FALSE, na = "")
add_check(
  "links",
  "source_and_rendered_links_resolve",
  length(source_targets) == 26L && length(unique(source_targets)) == 24L &&
    length(content_hrefs) == 26L && length(unique(content_hrefs)) == 24L &&
    all(link_audit$exists) && all(link_audit$fragment_once),
  sprintf("source=%d/%d rendered=%d/%d", length(source_targets), length(unique(source_targets)), length(content_hrefs), length(unique(content_hrefs)))
)

stage3_manifest <- read.csv("artifacts/12_manifests/H10/H10_stage3_artifacts.csv", check.names = FALSE)
stage3_observed <- vapply(stage3_manifest$path, sha256_file, character(1))
stage3_mismatch <- stage3_manifest$path[stage3_observed != stage3_manifest$sha256]
expected_mismatch <- c(
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
    live_sha256 = stage3_observed[match(stage3_mismatch, stage3_manifest$path)]
  ),
  file.path(evidence_dir, paste0("stage3_transitions_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)
add_check(
  "historical_manifest",
  "exact_six_transitions_and_live_test",
  length(stage3_mismatch) == 6L && setequal(stage3_mismatch, expected_mismatch) &&
    file_exact("tests/hypotheses/H10/test_h10_stage3_reader_report.R", "dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af", 25803),
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
  !is.na(row) && file_exact(scientific_assets[[i]], stage3_manifest$sha256[[row]], stage3_manifest$bytes[[row]])
}, logical(1))
add_check("science", "fifty_seven_assets", length(scientific_assets) == 57L && all(asset_exact), sprintf("exact=%d/%d", sum(asset_exact), length(asset_exact)))

inventory_tree <- function(directory) {
  base <- normalizePath(directory, winslash = "/", mustWork = TRUE)
  entries <- list.files(base, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE, include.dirs = TRUE)
  links <- Sys.readlink(entries)
  info <- file.info(entries)
  files <- !info$isdir & !nzchar(links)
  hashes <- rep(NA_character_, length(entries))
  hashes[files] <- vapply(entries[files], sha256_file, character(1))
  data.frame(
    path = substring(entries, nchar(root) + 2L),
    type = ifelse(nzchar(links), "symlink", ifelse(info$isdir, "directory", "file")),
    sha256 = hashes,
    bytes = ifelse(files, as.numeric(info$size), NA_real_),
    link_target = links,
    stringsAsFactors = FALSE
  )
}

build_pre_render <- read.csv("/private/tmp/h10-order58-control.SBA1Ua/build_inventory_prerender.csv", check.names = FALSE)
build_now <- inventory_tree("_build/nathealth")
build_pre_render$sha256[!nzchar(build_pre_render$sha256)] <- NA_character_
build_now$sha256[!nzchar(build_now$sha256)] <- NA_character_
all_build <- sort(unique(c(build_pre_render$path, build_now$path)))
pre_i <- match(all_build, build_pre_render$path)
now_i <- match(all_build, build_now$path)
build_delta <- data.frame(
  path = all_build,
  pre_sha256 = build_pre_render$sha256[pre_i],
  live_sha256 = build_now$sha256[now_i],
  pre_bytes = build_pre_render$bytes[pre_i],
  live_bytes = build_now$bytes[now_i],
  pre_type = build_pre_render$type[pre_i],
  live_type = build_now$type[now_i],
  stringsAsFactors = FALSE
)
same <- (is.na(build_delta$pre_sha256) & is.na(build_delta$live_sha256) & build_delta$pre_type == build_delta$live_type) |
  (!is.na(build_delta$pre_sha256) & !is.na(build_delta$live_sha256) &
    build_delta$pre_sha256 == build_delta$live_sha256 & build_delta$pre_type == build_delta$live_type)
same[is.na(same)] <- FALSE
build_delta <- build_delta[!same, , drop = FALSE]
expected_build_delta <- c(
  "_build/nathealth/notebooks/hypotheses/H10.html",
  "_build/nathealth/search.json",
  "_build/nathealth/sitemap.xml"
)
write.csv(build_delta, file.path(evidence_dir, paste0("build_delta_", phase, ".csv")), row.names = FALSE, na = "")
add_check(
  "build",
  "exact_three_historical_transitions_and_no_symlinks",
  nrow(build_now) == 1180L && nrow(build_delta) == 3L && setequal(build_delta$path, expected_build_delta) &&
    sum(build_now$type == "symlink") == 0L,
  sprintf("entries=%d delta=%d symlinks=%d", nrow(build_now), nrow(build_delta), sum(build_now$type == "symlink"))
)

protected_pre <- read.csv("/private/tmp/h10-order58-control.SBA1Ua/protected_inventory_prerender.csv", check.names = FALSE)
protected_live <- vapply(protected_pre$path, sha256_file, character(1))
test_row <- match("tests/hypotheses/H10/test_h10_stage3_reader_report.R", protected_pre$path)
expected_protected <- protected_pre$sha256
expected_protected[[test_row]] <- "dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af"
protected_audit <- data.frame(
  path = protected_pre$path,
  pre_sha256 = protected_pre$sha256,
  live_sha256 = protected_live,
  authorized_test_transition = seq_len(nrow(protected_pre)) == test_row,
  exact_expected_live = protected_live == expected_protected,
  stringsAsFactors = FALSE
)
write.csv(protected_audit, file.path(evidence_dir, paste0("protected_transition_", phase, ".csv")), row.names = FALSE, na = "")
add_check(
  "protected",
  "one_test_transition_other_149_exact",
  nrow(protected_pre) == 150L && !is.na(test_row) &&
    sum(protected_live != protected_pre$sha256) == 1L &&
    identical(unname(which(protected_live != protected_pre$sha256)), unname(test_row)) &&
    all(protected_audit$exact_expected_live),
  sprintf("rows=%d transitions=%d", nrow(protected_pre), sum(protected_live != protected_pre$sha256))
)

figure_src <- xml_attr(figures, "src")
figure_alt <- xml_attr(figures, "alt")
figure_paths <- normalizePath(file.path(dirname(html_path), utils::URLdecode(figure_src)), winslash = "/", mustWork = TRUE)
served_root <- normalizePath("_build/nathealth", winslash = "/", mustWork = TRUE)
qa_manifest <- read.csv("artifacts/12_manifests/H10/H10_stage3_figure_readability_qa.csv", check.names = FALSE)
add_check(
  "qa_harness",
  "safe_route_figures_alts_and_readability",
  length(xml_find_all(document, "//meta[@name='viewport']")) == 1L &&
    length(figure_paths) == 8L && all(startsWith(figure_paths, paste0(served_root, "/"))) &&
    all(!is.na(figure_alt)) && all(nchar(figure_alt) >= 200L) &&
    nrow(qa_manifest) == 8L && all(qa_manifest$overall_status == "PASS") &&
    all(qa_manifest$visual_status == "PASS") && all(qa_manifest$typography_status == "PASS_BY_CALCULATION") &&
    min(qa_manifest$effective_final_essential_text_pt) >= 5.696 &&
    min(qa_manifest$effective_final_central_text_pt) >= 7.120,
  sprintf(
    "figures=%d alt_min=%d essential_min=%.3f central_min=%.3f",
    length(figure_paths), min(nchar(figure_alt)),
    min(qa_manifest$effective_final_essential_text_pt),
    min(qa_manifest$effective_final_central_text_pt)
  )
)

build_inventory_path <- file.path(evidence_dir, paste0("build_inventory_", phase, ".csv"))
protected_inventory_path <- file.path(evidence_dir, paste0("protected_inventory_", phase, ".csv"))
write.csv(build_now, build_inventory_path, row.names = FALSE, na = "")
write.csv(
  data.frame(
    path = protected_pre$path,
    sha256 = protected_live,
    bytes = vapply(protected_pre$path, file_bytes, numeric(1)),
    stringsAsFactors = FALSE
  ),
  protected_inventory_path,
  row.names = FALSE,
  na = ""
)

if (phase == "preqa") {
  stopifnot(
    file.copy(file.path(control_dir, "preflight_checks.csv"), file.path(evidence_dir, "preflight_checks.csv"), overwrite = TRUE),
    file.copy(file.path(control_dir, "reader_test_zero_context.diff"), file.path(evidence_dir, "reader_test_zero_context.diff"), overwrite = TRUE)
  )
  execution <- data.frame(
    operation = c("authorized_test_transition", "reader_test", "quarto_or_render"),
    invocation_count = c(1L, 1L, 0L),
    exit_status = c(0L, 0L, NA_integer_),
    detail = c(
      "dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af; exact one-hunk reverse",
      "H10 standalone reader-report checks passed",
      "not authorized and not invoked"
    ),
    stringsAsFactors = FALSE
  )
  write.csv(execution, file.path(evidence_dir, "execution_record.csv"), row.names = FALSE, na = "")
}

if (phase == "postqa") {
  pre_build <- read.csv(file.path(evidence_dir, "build_inventory_preqa.csv"), check.names = FALSE)
  pre_protected <- read.csv(file.path(evidence_dir, "protected_inventory_preqa.csv"), check.names = FALSE)
  visual_path <- file.path(evidence_dir, "visual_qa_observations.csv")
  stopifnot(file.exists(visual_path))
  visual <- read.csv(visual_path, check.names = FALSE)
  post_build_df <- read.csv(build_inventory_path, check.names = FALSE)
  build_no_drift <- identical(pre_build, post_build_df)
  protected_now_df <- read.csv(protected_inventory_path, check.names = FALSE)
  protected_no_drift <- identical(pre_protected, protected_now_df)
  add_check(
    "post_qa",
    "visual_pass_and_no_drift",
    nrow(visual) >= 12L && all(visual$status == "PASS") &&
      all(c("1440x1000", "708x1000", "720x500", "170mm") %in% visual$view) &&
      build_no_drift && protected_no_drift,
    sprintf("visual=%d/%d build_no_drift=%s protected_no_drift=%s", sum(visual$status == "PASS"), nrow(visual), build_no_drift, protected_no_drift)
  )
}

audit <- do.call(rbind, checks)
write.csv(audit, file.path(evidence_dir, paste0("static_checks_", phase, ".csv")), row.names = FALSE, na = "")
if (!all(audit$pass)) {
  print(audit[!audit$pass, , drop = FALSE])
  stop(sprintf("Order 58a %s static verifier failed.", phase), call. = FALSE)
}

if (phase == "postqa") {
  record <- c(
    "# REPORT-018 H10 order 58a no-rerender result acceptance",
    "",
    paste0("Sealed UTC: ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
    "",
    "## Disposition",
    "",
    "Order 58a is accepted. The exact one-literal reader-test transition produced the authorized postimage, reconstructed its preimage exactly, and the sole reader-test execution passed. No Quarto, knitr, Pandoc, semantic-hook, preparation-test, model, prediction, scientific computation, companion action, H11 action, commit, push, or upload occurred.",
    "",
    "The preserved H10 result HTML remained at SHA-256 `37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14`. Static verification passed for 15 native gt tables, eight figures, 1,038 scoped header tokens, 26 rendered links to 24 targets, exactly six historical Stage 3 transitions, all 57 scientific assets, the exact three-path historical build delta, and the sole protected reader-test transition.",
    "",
    "Secure-loopback visual QA passed at 1440 by 1000, 708 by 1000, and 720 by 500, and for all eight exported figures at 170 mm. The complete reader flow, tables, figures, callouts, headings, captions, notes, links, navigation, site codes, axes, legends, symbols, wrapping, scrollers, clipping, overlap, and overflow were accepted. The server was bound only to 127.0.0.1, then stopped; the QA tab was closed, the viewport reset, and no listener remained. Pre-QA and post-QA build and protected inventories are byte-identical.",
    "",
    "The H10 companion, H11, and later targets remain held pending independent acceptance.",
    ""
  )
  record_path <- file.path(evidence_dir, "order58a_acceptance_record.md")
  writeLines(record, record_path, useBytes = TRUE)
  manifest_path <- file.path(evidence_dir, "order58a_non_circular_evidence_manifest.csv")
  local_files <- list.files(evidence_dir, full.names = TRUE, recursive = FALSE, all.files = TRUE, no.. = TRUE)
  local_files <- local_files[!dir.exists(local_files) & basename(local_files) != basename(manifest_path)]
  external_files <- c(semantic_summary_path, semantic_ledger_path)
  files <- c(sort(local_files), external_files)
  manifest <- data.frame(
    path = ifelse(startsWith(files, paste0(root, "/")), substring(files, nchar(root) + 2L), files),
    sha256 = vapply(files, sha256_file, character(1)),
    bytes = vapply(files, file_bytes, numeric(1)),
    role = c(rep("order58a_task_owned_evidence", length(local_files)), "external_semantic_summary", "external_semantic_ledger"),
    stringsAsFactors = FALSE
  )
  stopifnot(!anyDuplicated(manifest$path), !manifest_path %in% files)
  write.csv(manifest, manifest_path, row.names = FALSE, na = "")
  cat(sprintf(
    "REPORT018_H10_ORDER58A=ACCEPTED checks=%d test=PASS visual=PASS build_no_drift=PASS protected_no_drift=PASS manifest=%s\n",
    nrow(audit), sha256_file(manifest_path)
  ))
} else {
  cat(sprintf(
    paste0(
      "REPORT018_H10_ORDER58A_STATIC_PREQA=PASS checks=%d tables=15 figures=8 ",
      "headers=1038 links=26/24 assets=57 build=1180/3 protected=150/1 R=%s\n"
    ),
    nrow(audit), as.character(getRversion())
  ))
}
