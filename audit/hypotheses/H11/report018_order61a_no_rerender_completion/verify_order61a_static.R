#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

stopifnot(identical(as.character(getRversion()), "4.6.1"))
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H11/report018_order61a_no_rerender_completion"
)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)
setwd(root)

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

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

write_evidence <- function(value, filename) {
  readr::write_csv(value, file.path(evidence_dir, filename), na = "")
}

replace_ranges <- function(content, starts, ends, replacements) {
  for (index in order(starts, decreasing = TRUE)) {
    before <- if (starts[[index]] > 1L) {
      content[seq_len(starts[[index]] - 1L)]
    } else {
      raw()
    }
    after <- if (ends[[index]] < length(content)) {
      content[seq.int(ends[[index]] + 1L, length(content))]
    } else {
      raw()
    }
    content <- c(
      before,
      charToRaw(enc2utf8(replacements[[index]])),
      after
    )
  }
  content
}

inventory_files <- function(paths) {
  paths <- sort(unique(paths))
  stopifnot(length(paths) > 0L, all(file.exists(paths)), all(!dir.exists(paths)))
  data.frame(
    path = relative_path(paths),
    sha256 = vapply(paths, sha256_file, character(1)),
    bytes = unname(as.numeric(file.info(paths)$size)),
    link_target = Sys.readlink(paths),
    stringsAsFactors = FALSE
  )
}

inventory_tree <- function(path) {
  members <- list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
  members <- sort(unique(members))
  links <- Sys.readlink(members)
  directories <- dir.exists(members) & !nzchar(links)
  regular_files <- file.exists(members) & !directories & !nzchar(links)
  hashes <- rep(NA_character_, length(members))
  hashes[regular_files] <- vapply(
    members[regular_files],
    sha256_file,
    character(1)
  )
  bytes <- rep(NA_real_, length(members))
  bytes[regular_files] <- unname(
    as.numeric(file.info(members[regular_files])$size)
  )
  data.frame(
    path = relative_path(members),
    type = ifelse(
      nzchar(links),
      "symlink",
      ifelse(directories, "directory", "file")
    ),
    sha256 = hashes,
    bytes = bytes,
    link_target = links,
    stringsAsFactors = FALSE
  )
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

audit_seal <- function(
  path,
  expected_rows,
  filename,
  expected_transition_paths = character()
) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  exists <- file.exists(manifest$path) & !dir.exists(manifest$path)
  live_sha <- rep(NA_character_, nrow(manifest))
  live_bytes <- rep(NA_real_, nrow(manifest))
  live_sha[exists] <- vapply(
    manifest$path[exists],
    sha256_file,
    character(1)
  )
  live_bytes[exists] <- unname(
    as.numeric(file.info(manifest$path[exists])$size)
  )
  exact <- exists & live_sha == manifest$sha256 &
    live_bytes == as.numeric(manifest$bytes)
  audit <- data.frame(
    path = manifest$path,
    sealed_sha256 = manifest$sha256,
    live_sha256 = live_sha,
    sealed_bytes = manifest$bytes,
    live_bytes = live_bytes,
    exact = exact,
    stringsAsFactors = FALSE
  )
  write_evidence(audit, filename)
  transition_paths <- manifest$path[!exact]
  list(
    pass = nrow(manifest) == expected_rows &&
      !anyDuplicated(manifest$path) &&
      !path %in% manifest$path &&
      setequal(transition_paths, expected_transition_paths),
    rows = nrow(manifest),
    exact = sum(exact),
    transitions = length(transition_paths)
  )
}

authorized_transition_paths <- c(
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  "tests/hypotheses/H11/test_h11_preparation_report.R"
)

dispatch <- audit_seal(
  "audit/report_harmonization/report018_h11_order61a_dispatch_manifest.csv",
  38L,
  "dispatch_manifest_audit.csv",
  authorized_transition_paths
)
acceptance <- audit_seal(
  paste0(
    "audit/report_harmonization/",
    "report018_h11_order61_rendered_stop_independent_acceptance_manifest.csv"
  ),
  31L,
  "independent_acceptance_manifest_audit.csv",
  authorized_transition_paths
)
owner <- audit_seal(
  paste0(
    "audit/hypotheses/H11/report018_order61_companion_render/",
    "order61_fail_closed_non_circular_manifest.csv"
  ),
  44L,
  "order61_owner_manifest_audit.csv"
)
add_check(
  "authority",
  "dispatch_acceptance_and_owner_seals",
  dispatch$pass && acceptance$pass && owner$pass,
  sprintf(
    "dispatch=%d+%d/%d acceptance=%d+%d/%d owner=%d+%d/%d",
    dispatch$exact,
    dispatch$transitions,
    dispatch$rows,
    acceptance$exact,
    acceptance$transitions,
    acceptance$rows,
    owner$exact,
    owner$transitions,
    owner$rows
  )
)

fixed <- data.frame(
  path = c(
    "audit/report_harmonization/owner_orders/61a_h11_companion_no_rerender_local_test_and_acceptance.md",
    "audit/report_harmonization/report018_h11_order61a_dispatch_manifest.csv",
    "audit/report_harmonization/report018_h11_order61_rendered_stop_independent_acceptance.md",
    "audit/report_harmonization/report018_h11_order61_rendered_stop_independent_acceptance_manifest.csv",
    "scripts/report_harmonization/check_report018_h11_order61_stop_and_no_rerender_completion.R",
    "notebooks/hypotheses/H11.qmd",
    "_build/nathealth/notebooks/hypotheses/H11.html",
    "audit/hypotheses/H11/H11_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html",
    "tests/hypotheses/H11/test_h11_preparation_report.R",
    "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
    "scripts/hypotheses/H11/build_h11_preparation_report_manifest.R",
    "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
    "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
    "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
    "audit/handoffs/H11_worker_handoff.md",
    "_quarto-nathealth.yml",
    "renv.lock",
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html",
    "audit/report_harmonization/coordination_matrix.csv"
  ),
  expected_sha256 = c(
    "74f1a6f8161d0cc5f524c821d7b894e66b0e21e7f77b7aa947d1359534de1dca",
    "adf40e1399b14fa554ad9cd621fe55cc9a93512db359996fb2e1cf15c31e061d",
    "878fb256fc2fd4a932c6a795b8d4ad9995c06a2641002d5bab21227aa1e16f24",
    "6d1f88dbb62ba748bfc89a07558210cfe0aee416d7d840a616b152db44397ab2",
    "69f8f02fbd67ec283846a15e90515db622ebf4ddd9c7a6f583f02475cd23872f",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
    "2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "58518d708e4feb6145bd8eb773b6b9ae4937afdf4a9e44e19d4215d9ca86162c",
    "64b427b4bc11f79a1ea2cd539eee7e30184271ef05cbba7b3f511a2f105a15a3",
    "bd34dbfd6d2e929c825fe76281dfd384d8b0ef851b3d99a52b155c3216cfc6d9",
    "6afff45a29a0bb96a49dbf46e611fce15dfd1618b4699da40d4b1f15cdbed026",
    "317f31069e6019475023b3097b1d7f1b00435755e0a109e40535fab89b570bf8",
    "b0af27946d6c4001e659e9edb27bfab0fdfd3a36aa8be536d51ed50ae234a3c0",
    "3d945c2b813ffaa2291ddebbe01f1f45c5c4ae7fe10256c9a1c8b15c3b531e7b",
    "2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645",
    "5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
    "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780",
    "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
  ),
  stringsAsFactors = FALSE
)
fixed$live_sha256 <- vapply(fixed$path, sha256_file, character(1))
fixed$exact <- fixed$live_sha256 == fixed$expected_sha256
write_evidence(fixed, "fixed_identity_audit.csv")
add_check(
  "identity",
  "fixed_current_and_held_identities",
  all(fixed$exact),
  sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed))
)

manifest_path <- "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv"
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
manifest_exists <- file.exists(manifest$path) & !dir.exists(manifest$path)
manifest_live_sha <- rep(NA_character_, nrow(manifest))
manifest_live_bytes <- rep(NA_real_, nrow(manifest))
manifest_live_sha[manifest_exists] <- vapply(
  manifest$path[manifest_exists],
  sha256_file,
  character(1)
)
manifest_live_bytes[manifest_exists] <- unname(
  as.numeric(file.info(manifest$path[manifest_exists])$size)
)
manifest_exact <- manifest_exists &
  manifest_live_sha == manifest$sha256 &
  manifest_live_bytes == as.numeric(manifest$bytes)
manifest_audit <- data.frame(
  path = manifest$path,
  sealed_sha256 = manifest$sha256,
  live_sha256 = manifest_live_sha,
  sealed_bytes = manifest$bytes,
  live_bytes = manifest_live_bytes,
  exact = manifest_exact,
  stringsAsFactors = FALSE
)
write_evidence(manifest_audit, "preparation_manifest_live_audit.csv")
manifest_pass <- nrow(manifest) == 283L &&
  !anyDuplicated(manifest$path) &&
  !manifest_path %in% manifest$path &&
  all(manifest_exact)
add_check(
  "manifest",
  "truthful_current_manifest",
  manifest_pass,
  sprintf("exact=%d/%d", sum(manifest_exact), nrow(manifest))
)

owner_dir <- "audit/hypotheses/H11/report018_order61_companion_render"
semantic_summary <- readr::read_csv(
  file.path(owner_dir, "gt_html_semantic_post_render_summary.csv"),
  show_col_types = FALSE
)
semantic_ledger <- readr::read_csv(
  file.path(owner_dir, "H11_gt_semantic_ledger.csv"),
  show_col_types = FALSE
)
html_path <- paste0(
  "_build/nathealth/audit/hypotheses/H11/",
  "H11_analysis_preparation.html"
)
post_raw <- read_raw_file(html_path)
pre_raw <- replace_ranges(
  post_raw,
  as.integer(semantic_ledger$post_value_start_byte),
  as.integer(semantic_ledger$post_value_end_byte),
  semantic_ledger$pre_value
)
reapplied_raw <- replace_ranges(
  pre_raw,
  as.integer(semantic_ledger$pre_value_start_byte),
  as.integer(semantic_ledger$pre_value_end_byte),
  semantic_ledger$post_value
)
semantic_pass <- nrow(semantic_summary) == 1L &&
  semantic_summary$disposition[[1L]] == "REPAIRED" &&
  semantic_summary$table_count[[1L]] == 26L &&
  semantic_summary$id_count[[1L]] == 179L &&
  semantic_summary$headers_count[[1L]] == 801L &&
  semantic_summary$total_substitutions[[1L]] == 980L &&
  semantic_summary$pre_sha256[[1L]] == sha256_raw(pre_raw) &&
  semantic_summary$post_sha256[[1L]] == sha256_raw(post_raw) &&
  nrow(semantic_ledger) == 980L &&
  identical(reapplied_raw, post_raw)
add_check(
  "semantic",
  "exact_reverse_and_reapplication",
  semantic_pass,
  sprintf(
    "tables=%d ids=%d headers=%d substitutions=%d",
    semantic_summary$table_count[[1L]],
    semantic_summary$id_count[[1L]],
    semantic_summary$headers_count[[1L]],
    semantic_summary$total_substitutions[[1L]]
  )
)

document <- xml2::read_html(rawToChar(post_raw))
main_nodes <- xml2::xml_find_all(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(length(main_nodes) == 1L)
main <- main_nodes[[1L]]
gt_tables <- xml2::xml_find_all(
  main,
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
images <- xml2::xml_find_all(main, ".//figure//img")
captions <- xml2::xml_find_all(main, ".//figure/figcaption")
mermaid <- xml2::xml_find_all(
  main,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
all_ids <- xml2::xml_attr(xml2::xml_find_all(document, ".//*[@id]"), "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]

header_rows <- list()
for (table_index in seq_along(gt_tables)) {
  table <- gt_tables[[table_index]]
  table_ids <- xml2::xml_attr(
    xml2::xml_find_all(table, "self::*[@id] | .//*[@id]"),
    "id"
  )
  headers <- xml2::xml_attr(
    xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
    "headers"
  )
  for (value in headers) {
    tokens <- strsplit(trimws(value), "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    for (token in tokens) {
      header_rows[[length(header_rows) + 1L]] <- data.frame(
        table_index = table_index,
        token = token,
        resolves = sum(table_ids == token),
        stringsAsFactors = FALSE
      )
    }
  }
}
header_audit <- do.call(rbind, header_rows)
write_evidence(header_audit, "table_header_resolution_audit.csv")

qmd_path <- "audit/hypotheses/H11/H11_analysis_preparation.qmd"
qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
table_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: tbl-", qmd_lines, value = TRUE)
)
figure_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: fig-", qmd_lines, value = TRUE)
)
endpoint_labels <- c(table_labels, figure_labels)
table_endpoint_xpath <- paste0(
  ".//*[@id='",
  paste(table_labels, collapse = "' or @id='"),
  "']"
)
figure_endpoint_xpath <- paste0(
  ".//*[@id='",
  paste(figure_labels, collapse = "' or @id='"),
  "']"
)
table_endpoint_nodes <- xml2::xml_find_all(main, table_endpoint_xpath)
figure_endpoint_nodes <- xml2::xml_find_all(main, figure_endpoint_xpath)
endpoint_order <- c(
  xml2::xml_attr(table_endpoint_nodes, "id"),
  xml2::xml_attr(figure_endpoint_nodes, "id")
)
endpoint_audit <- data.frame(
  expected_order = endpoint_labels,
  rendered_order = endpoint_order,
  exact = endpoint_labels == endpoint_order,
  stringsAsFactors = FALSE
)
write_evidence(endpoint_audit, "endpoint_order_audit.csv")

result_href <- "../../../notebooks/hypotheses/H11.html"
result_links <- xml2::xml_find_all(
  main,
  paste0(".//a[contains(@href, '", result_href, "')]")
)
bad_nodes <- xml2::xml_find_all(
  main,
  paste0(
    ".//*[contains(@class, 'error') or contains(@class, 'warning') or ",
    "contains(@class, 'stderr') or contains(@class, 'unresolved')]"
  )
)
unresolved_links <- xml2::xml_find_all(
  main,
  ".//a[@data-unresolved-ref or (contains(@class, 'quarto-xref') and not(@href))]"
)
main_text <- xml2::xml_text(main)
dom_pass <- length(gt_tables) == 26L &&
  length(images) == 3L &&
  all(nzchar(xml2::xml_attr(images, "alt"))) &&
  length(captions) >= 3L &&
  all(nzchar(trimws(xml2::xml_text(captions)))) &&
  length(mermaid) == 1L &&
  sum(grepl("flowchart TD", qmd_lines, fixed = TRUE)) == 1L &&
  !anyDuplicated(all_ids) &&
  nrow(header_audit) == 1193L &&
  all(header_audit$resolves == 1L) &&
  length(table_labels) == 26L &&
  length(figure_labels) == 3L &&
  nrow(endpoint_audit) == 29L &&
  all(endpoint_audit$exact) &&
  length(result_links) == 2L &&
  length(bad_nodes) == 0L &&
  length(unresolved_links) == 0L &&
  !grepl("Execution halted", main_text, fixed = TRUE) &&
  !grepl("\\?@", main_text, perl = TRUE)
add_check(
  "DOM",
  "complete_rendered_structure",
  dom_pass,
  sprintf(
    paste0(
      "main=1 tables=%d images=%d captions=%d mermaid=%d ids=%d ",
      "headers=%d endpoints=%d result_links=%d bad=%d unresolved=%d"
    ),
    length(gt_tables),
    length(images),
    length(captions),
    length(mermaid),
    length(all_ids),
    nrow(header_audit),
    nrow(endpoint_audit),
    length(result_links),
    length(bad_nodes),
    length(unresolved_links)
  )
)

qmd_text <- paste(qmd_lines, collapse = "\n")
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
  file.path(dirname(qmd_path), target_paths),
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
write_evidence(link_audit, "source_link_audit.csv")
link_pass <- length(local_targets) == 20L &&
  length(unique(local_targets)) == 17L &&
  sum(nzchar(fragments)) == 14L &&
  all(target_exists) &&
  all(fragment_resolves) &&
  sum(grepl("H02_analysis_preparation", local_targets, fixed = TRUE)) >= 1L &&
  sum(grepl("preregistration_deviations", local_targets, fixed = TRUE)) >= 1L &&
  sum(grepl("^\\[Paired ", markdown_matches, ignore.case = TRUE)) >= 1L
add_check(
  "links",
  "source_and_rendered_link_contract",
  link_pass,
  sprintf(
    "occurrences=%d unique=%d fragments=%d rendered_result_links=%d",
    length(local_targets),
    length(unique(local_targets)),
    sum(nzchar(fragments)),
    length(result_links)
  )
)

old_owner_dir <- "audit/hypotheses/H11/report018_order61_companion_render"
science_before <- readr::read_csv(
  file.path(old_owner_dir, "scientific_inventory_postfailure.csv"),
  show_col_types = FALSE
)
science_current <- inventory_files(file.path(root, science_before$path))
science_pass <- nrow(science_current) == 193L &&
  identical(science_current$path, science_before$path) &&
  identical(science_current$sha256, science_before$sha256) &&
  identical(science_current$bytes, as.numeric(science_before$bytes))
write_evidence(science_current, "scientific_inventory_preqa.csv")
add_check(
  "preservation",
  "scientific_assets",
  science_pass,
  sprintf("exact=%d/193", nrow(science_current))
)

protected_before <- readr::read_csv(
  file.path(old_owner_dir, "protected_inventory_postfailure.csv"),
  show_col_types = FALSE
)
protected_current <- inventory_files(file.path(root, protected_before$path))
write_evidence(protected_current, "protected_inventory_preqa.csv")
protected_changed <- protected_current$path[
  protected_current$sha256 != protected_before$sha256 |
    protected_current$bytes != as.numeric(protected_before$bytes)
]
expected_protected_changes <- c(
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  "tests/hypotheses/H11/test_h11_preparation_report.R"
)
protected_pass <- setequal(protected_changed, expected_protected_changes)
write_evidence(
  data.frame(
    path = protected_changed,
    expected = protected_changed %in% expected_protected_changes,
    stringsAsFactors = FALSE
  ),
  "authorized_protected_transitions.csv"
)
add_check(
  "preservation",
  "only_authorized_project_transitions",
  protected_pass,
  paste(sort(protected_changed), collapse = " | ")
)

build_inventory <- inventory_tree(file.path(root, "_build/nathealth"))
write_evidence(build_inventory, "build_inventory_preqa.csv")
zero_symlinks <- !any(build_inventory$type == "symlink")
add_check(
  "build",
  "zero_symlinks",
  zero_symlinks,
  sprintf(
    "members=%d symlinks=%d",
    nrow(build_inventory),
    sum(build_inventory$type == "symlink")
  )
)

critical_paths <- unique(c(
  fixed$path,
  file.path(old_owner_dir, "gt_html_semantic_post_render_summary.csv"),
  file.path(old_owner_dir, "H11_gt_semantic_ledger.csv"),
  qmd_path,
  html_path
))
critical_inventory <- inventory_files(file.path(root, critical_paths))
write_evidence(critical_inventory, "critical_identities_preqa.csv")

checks_frame <- do.call(rbind, checks)
write_evidence(checks_frame, "static_acceptance_checks.csv")
if (!all(checks_frame$pass)) {
  failed <- checks_frame[!checks_frame$pass, , drop = FALSE]
  stop(
    "Order 61a static verification failed: ",
    paste(failed$check_id, collapse = ", "),
    call. = FALSE
  )
}

message(sprintf(
  paste0(
    "REPORT018_H11_ORDER61A_STATIC=PASS checks=%d dispatch=38/38 ",
    "acceptance=31/31 owner=44/44 manifest=283/283 ",
    "semantic=26+179+801+980 headers=1193/1193 links=20/17/14 ",
    "science=193/193 symlinks=0 R=4.6.1"
  ),
  nrow(checks_frame)
))
