#!/usr/bin/env Rscript

# Independent REPORT-018 acceptance of the H10 result and read-only downstream
# preflight for completion of the already rendered H10 preparation companion.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
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

evidence_dir <- file.path(
  root,
  "audit/report_harmonization/report018_h10_companion_preflight"
)
owner_dir <- file.path(
  root,
  "audit/hypotheses/H10/report018_order58a_no_rerender_completion"
)

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  paste0(openssl::sha256(con))
}

file_bytes <- function(path) as.numeric(file.info(path)$size)

file_exact <- function(path, sha256, bytes = NULL) {
  pass <- file.exists(path) &&
    !dir.exists(path) &&
    identical(sha256_file(path), sha256)
  if (!is.null(bytes)) {
    pass <- pass && identical(file_bytes(path), as.numeric(bytes))
  }
  pass
}

read_raw <- function(path) {
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

owner_manifest_path <- file.path(
  owner_dir,
  "order58a_non_circular_evidence_manifest.csv"
)
owner_manifest <- read.csv(owner_manifest_path, check.names = FALSE)
owner_manifest_exact <- vapply(
  seq_len(nrow(owner_manifest)),
  function(index) {
    file_exact(
      owner_manifest$path[[index]],
      owner_manifest$sha256[[index]],
      owner_manifest$bytes[[index]]
    )
  },
  logical(1)
)
add_check(
  "result_acceptance",
  "owner_manifest_30_of_30",
  nrow(owner_manifest) == 30L &&
    !anyDuplicated(owner_manifest$path) &&
    !owner_manifest_path %in% owner_manifest$path &&
    all(owner_manifest_exact),
  sprintf("exact=%d/%d", sum(owner_manifest_exact), nrow(owner_manifest))
)

result_fixed <- data.frame(
  path = c(
    "notebooks/hypotheses/H10.qmd",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "_quarto-nathealth.yml",
    "notebooks/hypotheses/H11.qmd"
  ),
  sha256 = c(
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af",
    "37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867"
  ),
  stringsAsFactors = FALSE
)
result_fixed$exact <- vapply(
  seq_len(nrow(result_fixed)),
  function(index) {
    file_exact(result_fixed$path[[index]], result_fixed$sha256[[index]])
  },
  logical(1)
)
add_check(
  "result_acceptance",
  "accepted_result_and_held_sources",
  all(result_fixed$exact),
  sprintf("exact=%d/%d", sum(result_fixed$exact), nrow(result_fixed))
)

result_static <- read.csv(
  file.path(owner_dir, "static_checks_postqa.csv"),
  check.names = FALSE
)
result_visual <- read.csv(
  file.path(owner_dir, "visual_qa_observations.csv"),
  check.names = FALSE
)
result_build_pre <- read.csv(
  file.path(owner_dir, "build_inventory_preqa.csv"),
  check.names = FALSE
)
result_build_post <- read.csv(
  file.path(owner_dir, "build_inventory_postqa.csv"),
  check.names = FALSE
)
result_protected_pre <- read.csv(
  file.path(owner_dir, "protected_inventory_preqa.csv"),
  check.names = FALSE
)
result_protected_post <- read.csv(
  file.path(owner_dir, "protected_inventory_postqa.csv"),
  check.names = FALSE
)
add_check(
  "result_acceptance",
  "static_visual_and_no_drift",
  nrow(result_static) == 11L &&
    all(result_static$pass) &&
    nrow(result_visual) == 22L &&
    all(result_visual$status == "PASS") &&
    identical(result_build_pre, result_build_post) &&
    identical(result_protected_pre, result_protected_post),
  sprintf(
    "static=%d/%d visual=%d/%d build=%d protected=%d",
    sum(result_static$pass),
    nrow(result_static),
    sum(result_visual$status == "PASS"),
    nrow(result_visual),
    nrow(result_build_post),
    nrow(result_protected_post)
  )
)

prospective_helper <- file.path(
  evidence_dir,
  "prospective_build_h10_preparation_report_manifest.R"
)
prospective_test <- file.path(
  evidence_dir,
  "prospective_test_h10_preparation_report.R"
)
prospective_preview <- file.path(
  evidence_dir,
  "prospective_preparation_report_manifest_preview.csv"
)
prospective_fixed <- data.frame(
  path = c(prospective_helper, prospective_test, prospective_preview),
  sha256 = c(
    "292ad3335dac8241f317983d5017a5a1d5dbce51fef245d2c30889cf4a3dcf97",
    "8b206d4cf565b6f5a767e6e99afb9e587db8255f2239cb3761eebaa8e69d1608",
    "440ad63b3a540c11c3ca86bf912399b9773167d1aac09b90a757708cb4424238"
  ),
  bytes = c(10437, 17039, 200487),
  stringsAsFactors = FALSE
)
prospective_fixed$exact <- vapply(
  seq_len(nrow(prospective_fixed)),
  function(index) {
    file_exact(
      prospective_fixed$path[[index]],
      prospective_fixed$sha256[[index]],
      prospective_fixed$bytes[[index]]
    )
  },
  logical(1)
)
parse_helper <- tryCatch(
  {
    parse(file = prospective_helper)
    TRUE
  },
  error = function(error) FALSE
)
parse_test <- tryCatch(
  {
    parse(file = prospective_test)
    TRUE
  },
  error = function(error) FALSE
)
air_output <- system2(
  "air",
  c("format", "--check", prospective_helper, prospective_test),
  stdout = TRUE,
  stderr = TRUE
)
air_status <- attr(air_output, "status")
if (is.null(air_status)) {
  air_status <- 0L
}
add_check(
  "companion_preflight",
  "prospective_helper_and_test_postimages",
  all(prospective_fixed$exact) &&
    parse_helper &&
    parse_test &&
    air_status == 0L,
  sprintf(
    "exact=%d/3 parse=%s/%s air_status=%d",
    sum(prospective_fixed$exact),
    parse_helper,
    parse_test,
    air_status
  )
)

preview <- read.csv(prospective_preview, check.names = FALSE)
preview_paths <- file.path(root, preview$path)
preview_paths[
  preview$path ==
    "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R"
] <- prospective_helper
preview_paths[
  preview$path == "tests/hypotheses/H10/test_h10_preparation_report.R"
] <- prospective_test
preview_paths[
  preview$path ==
    paste0(
      "_build/nathealth/audit/hypotheses/H10/",
      "H10_analysis_preparation.qmd"
    )
] <- file.path(root, "audit/hypotheses/H10/H10_analysis_preparation.qmd")
preview_exact <- vapply(
  seq_along(preview_paths),
  function(index) {
    file_exact(
      preview_paths[[index]],
      preview$sha256[[index]],
      preview$bytes[[index]]
    )
  },
  logical(1)
)
source_side_html <- "audit/hypotheses/H10/H10_analysis_preparation.html"
add_check(
  "companion_preflight",
  "prospective_manifest_269_live_exact",
  nrow(preview) == 269L &&
    !anyDuplicated(preview$path) &&
    all(preview_exact) &&
    !source_side_html %in% preview$path &&
    !file.exists(source_side_html),
  sprintf(
    "rows=%d exact=%d source_side_html_present=%s",
    nrow(preview),
    sum(preview_exact),
    file.exists(source_side_html)
  )
)

companion_html <- paste0(
  "_build/nathealth/audit/hypotheses/H10/",
  "H10_analysis_preparation.html"
)
semantic_summary_path <- file.path(
  evidence_dir,
  "gt_html_semantic_post_render_summary.csv"
)
semantic_ledger_path <- file.path(
  evidence_dir,
  "H10_analysis_preparation_gt_semantic_ledger.csv"
)
stopifnot(
  file_exact(
    companion_html,
    "dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9",
    652030
  ),
  file_exact(
    semantic_summary_path,
    "4a3848b85d2e454dea54a2577759498953f160a1c0c43921147408a88d480682"
  ),
  file_exact(
    semantic_ledger_path,
    "f43f701108cbdf5cdc9e62a2a2e231a6a00dd5e99ddc3700d03c4dd96de0324b"
  )
)
semantic_summary <- read.csv(semantic_summary_path, check.names = FALSE)
semantic_ledger <- read.csv(semantic_ledger_path, check.names = FALSE)
engine <- new.env(parent = globalenv())
sys.source(
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  envir = engine
)
html_raw <- read_raw(companion_html)
reversed_raw <- engine$apply_raw_replacements(
  html_raw,
  semantic_ledger,
  reverse = TRUE
)
reapplied_raw <- engine$apply_raw_replacements(
  reversed_raw,
  semantic_ledger,
  reverse = FALSE
)
semantic_pass <-
  identical(engine$sha256_raw(html_raw), semantic_summary$post_sha256[[1L]]) &&
  identical(
    engine$sha256_raw(reversed_raw),
    semantic_summary$pre_sha256[[1L]]
  ) &&
  identical(reapplied_raw, html_raw) &&
  nrow(semantic_ledger) == 1132L &&
  sum(semantic_ledger$attribute == "id") == 82L &&
  sum(semantic_ledger$attribute == "headers") == 1050L
add_check(
  "companion_render",
  "semantic_reverse_and_reapply",
  semantic_pass,
  sprintf(
    "tables=%d ids=%d headers=%d substitutions=%d",
    semantic_summary$table_count[[1L]],
    sum(semantic_ledger$attribute == "id"),
    sum(semantic_ledger$attribute == "headers"),
    nrow(semantic_ledger)
  )
)

document <- read_html(companion_html)
main_nodes <- xml_find_all(document, "//main[@id='quarto-document-content']")
stopifnot(length(main_nodes) == 1L)
main <- main_nodes[[1L]]
gt_tables <- xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
figures <- xml_find_all(main, ".//figure//img")
figure_endpoints <- vapply(
  figures,
  function(image) {
    endpoint <- xml_find_first(
      image,
      "ancestor::*[@id and starts-with(@id,'fig-')][1]"
    )
    if (inherits(endpoint, "xml_missing")) {
      NA_character_
    } else {
      xml_attr(endpoint, "id")
    }
  },
  character(1)
)
figure_rows <- !is.na(figure_endpoints)
figures <- figures[figure_rows]
figure_endpoints <- figure_endpoints[figure_rows]
table_endpoints <- vapply(
  gt_tables,
  function(table) {
    endpoint <- xml_find_first(
      table,
      "ancestor::*[@id and starts-with(@id,'tbl-')][1]"
    )
    if (inherits(endpoint, "xml_missing")) {
      NA_character_
    } else {
      xml_attr(endpoint, "id")
    }
  },
  character(1)
)
qmd_lines <- readLines(
  "audit/hypotheses/H10/H10_analysis_preparation.qmd",
  warn = FALSE,
  encoding = "UTF-8"
)
labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: ", qmd_lines, value = TRUE)
)
expected_tables <- labels[startsWith(labels, "tbl-")]
expected_figures <- labels[startsWith(labels, "fig-")]
document_ids <- xml_attr(xml_find_all(document, ".//*[@id]"), "id")
document_ids <- document_ids[!is.na(document_ids) & nzchar(document_ids)]
header_tokens <- 0L
headers_valid <- all(vapply(
  gt_tables,
  function(table) {
    id_nodes <- xml_find_all(table, "self::*[@id] | .//*[@id]")
    ids <- xml_attr(id_nodes, "id")
    values <- xml_attr(
      xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
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
          all(xml_name(id_nodes[positions]) == "th") &&
          all(
            xml_attr(id_nodes[positions], "scope") %in%
              c(
                "col",
                "row",
                "colgroup",
                "rowgroup"
              )
          )
      },
      logical(1)
    ))
  },
  logical(1)
))
mermaid_nodes <- xml_find_all(
  main,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
add_check(
  "companion_render",
  "endpoints_ids_headers_and_mermaid",
  length(gt_tables) == 19L &&
    identical(table_endpoints, expected_tables) &&
    length(figures) == 2L &&
    identical(figure_endpoints, expected_figures) &&
    !anyDuplicated(document_ids) &&
    headers_valid &&
    header_tokens == 1050L &&
    length(mermaid_nodes) >= 1L,
  sprintf(
    "tables=%d figures=%d duplicate_ids=%d header_tokens=%d mermaid=%d",
    length(gt_tables),
    length(figures),
    anyDuplicated(document_ids),
    header_tokens,
    length(mermaid_nodes)
  )
)

main_text <- gsub("[[:space:]]+", " ", xml_text(main))
required_text <- c(
  "H10 analysis preparation and provenance",
  "Personal light exposure metrics depend on age and gender",
  "Biological sex and gender were recorded as separate variables",
  "accepted analyses used biological sex, coded Female or Male",
  "gender was not analysed",
  "The gender variable and unsupported predictors did not enter any model",
  "816 near-eye and 902 chest participant-days",
  "68 frames",
  "612 fits",
  "Four separate complete 17-metric FDR families",
  "at least 720 viable minutes",
  "same general coverage rules as the primary dataset",
  "does not use the timing of remaining missing observations",
  "L10 numerical-zero normalization",
  "every finite gap MDER value is strictly positive",
  "complete independent reconstruction of the exact current state-support classification remains open"
)
forbidden_text <- c(
  "neither measured nor inferred",
  "No gender field",
  "Execution halted"
)
error_nodes <- xml_find_all(
  main,
  paste0(
    ".//*[contains(@class,'cell-output-error') or ",
    "contains(@class,'cell-output-stderr') or ",
    "contains(@class,'cell-output-warning') or ",
    "contains(@class,'quarto-unresolved-ref')]"
  )
)
active_nav <- xml_find_all(
  document,
  "//nav//a[@aria-current='page' or contains(concat(' ',normalize-space(@class),' '),' active ')]"
)
add_check(
  "companion_render",
  "reader_content_and_render_integrity",
  all(vapply(required_text, grepl, logical(1), x = main_text, fixed = TRUE)) &&
    !any(vapply(
      forbidden_text,
      grepl,
      logical(1),
      x = main_text,
      fixed = TRUE
    )) &&
    length(error_nodes) == 0L &&
    length(active_nav) >= 1L,
  sprintf(
    "required=%d/%d forbidden=0/%d error_nodes=%d active_nav=%d",
    sum(vapply(required_text, grepl, logical(1), x = main_text, fixed = TRUE)),
    length(required_text),
    length(forbidden_text),
    length(error_nodes),
    length(active_nav)
  )
)

hrefs <- xml_attr(xml_find_all(main, ".//a[@href]"), "href")
local_hrefs <- hrefs[
  !is.na(hrefs) &
    nzchar(hrefs) &
    !startsWith(hrefs, "#") &
    !grepl("^(https?:|mailto:|javascript:)", hrefs, perl = TRUE)
]
resolved <- file.path(
  dirname(companion_html),
  sub("#.*$", "", utils::URLdecode(local_hrefs))
)
fragment_rows <- grepl("#", local_hrefs, fixed = TRUE)
fragment_once <- rep(TRUE, length(local_hrefs))
for (index in which(fragment_rows)) {
  fragment <- sub("^.*#", "", local_hrefs[[index]])
  target_document <- read_html(resolved[[index]])
  fragment_once[[index]] <- length(xml_find_all(
    target_document,
    sprintf("//*[@id='%s']", fragment)
  )) ==
    1L
}
add_check(
  "companion_render",
  "local_links_and_fragments_resolve",
  all(file.exists(resolved)) && all(fragment_once),
  sprintf(
    "links=%d unique=%d files=%d/%d fragments=%d/%d",
    length(local_hrefs),
    length(unique(local_hrefs)),
    sum(file.exists(resolved)),
    length(resolved),
    sum(fragment_once[fragment_rows]),
    sum(fragment_rows)
  )
)

stage3_manifest <- read.csv(
  "artifacts/12_manifests/H10/H10_stage3_artifacts.csv",
  check.names = FALSE
)
scientific_assets <- sort(c(
  list.files("artifacts/09_tables/H10", full.names = TRUE),
  list.files("artifacts/10_figures/H10", full.names = TRUE),
  list.files("artifacts/11_source_data/H10", full.names = TRUE)
))
scientific_assets <- scientific_assets[
  file.info(scientific_assets)$isdir %in% FALSE
]
asset_rows <- match(scientific_assets, stage3_manifest$path)
asset_exact <- vapply(
  seq_along(scientific_assets),
  function(index) {
    row <- asset_rows[[index]]
    !is.na(row) &&
      file_exact(
        scientific_assets[[index]],
        stage3_manifest$sha256[[row]],
        stage3_manifest$bytes[[row]]
      )
  },
  logical(1)
)
add_check(
  "science",
  "fifty_seven_scientific_assets_preserved",
  length(scientific_assets) == 57L && all(asset_exact),
  sprintf("exact=%d/%d", sum(asset_exact), length(asset_exact))
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
  files <- !info$isdir & !nzchar(links)
  hashes <- rep(NA_character_, length(entries))
  hashes[files] <- vapply(entries[files], sha256_file, character(1))
  data.frame(
    path = substring(entries, nchar(root) + 2L),
    type = ifelse(
      nzchar(links),
      "symlink",
      ifelse(info$isdir, "directory", "file")
    ),
    sha256 = hashes,
    bytes = ifelse(files, as.numeric(info$size), NA_real_),
    link_target = links,
    stringsAsFactors = FALSE
  )
}

compare_inventory <- function(previous, current) {
  previous$sha256[!nzchar(previous$sha256)] <- NA_character_
  current$sha256[!nzchar(current$sha256)] <- NA_character_
  all_paths <- sort(unique(c(previous$path, current$path)))
  pre_i <- match(all_paths, previous$path)
  live_i <- match(all_paths, current$path)
  delta <- data.frame(
    path = all_paths,
    pre_sha256 = previous$sha256[pre_i],
    live_sha256 = current$sha256[live_i],
    pre_bytes = previous$bytes[pre_i],
    live_bytes = current$bytes[live_i],
    pre_type = previous$type[pre_i],
    live_type = current$type[live_i],
    stringsAsFactors = FALSE
  )
  same <- (is.na(delta$pre_sha256) &
    is.na(delta$live_sha256) &
    delta$pre_type == delta$live_type) |
    (!is.na(delta$pre_sha256) &
      !is.na(delta$live_sha256) &
      delta$pre_sha256 == delta$live_sha256 &
      delta$pre_type == delta$live_type)
  same[is.na(same)] <- FALSE
  delta[!same, , drop = FALSE]
}

current_build <- inventory_tree("_build/nathealth")
build_delta <- compare_inventory(result_build_post, current_build)
expected_build_paths <- c(
  "_build/nathealth/artifacts/12_manifests/H10/H10_stage3_artifacts.csv",
  companion_html,
  "_build/nathealth/search.json",
  "_build/nathealth/sitemap.xml"
)
expected_build_hashes <- c(
  "b556d9fdb19eeda766414bab30420846ee5c46138e9d7861f61e92da7516683e",
  "dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9",
  "a2c91ee1278975361e766ac222c67944d6f631f261b3294bc4f988a90c3687b4",
  "7459928e1bc22a5a75c3be04b0e04b8190d5aaa8cc07c0d1e7b46df06a7cac08"
)
add_check(
  "integration_delta",
  "exact_four_target_owned_build_transitions",
  nrow(current_build) == 1180L &&
    nrow(build_delta) == 4L &&
    identical(sort(build_delta$path), sort(expected_build_paths)) &&
    all(
      build_delta$live_sha256[match(
        expected_build_paths,
        build_delta$path
      )] ==
        expected_build_hashes
    ) &&
    sum(current_build$type == "symlink") == 0L,
  sprintf(
    "entries=%d delta=%d symlinks=%d paths=%s",
    nrow(current_build),
    nrow(build_delta),
    sum(current_build$type == "symlink"),
    paste(sort(build_delta$path), collapse = "|")
  )
)

protected_exists <- file.exists(result_protected_post$path)
protected_live <- rep(NA_character_, nrow(result_protected_post))
protected_live[protected_exists] <- vapply(
  result_protected_post$path[protected_exists],
  sha256_file,
  character(1)
)
protected_delta_rows <- which(
  !protected_exists |
    protected_live != result_protected_post$sha256
)
add_check(
  "integration_delta",
  "only_obsolete_source_side_html_removed",
  identical(
    protected_delta_rows,
    match(source_side_html, result_protected_post$path)
  ) &&
    !protected_exists[[protected_delta_rows]] &&
    all(
      protected_live[-protected_delta_rows] ==
        result_protected_post$sha256[-protected_delta_rows]
    ),
  sprintf(
    "protected=%d delta=%d path=%s",
    nrow(result_protected_post),
    length(protected_delta_rows),
    paste(result_protected_post$path[protected_delta_rows], collapse = "|")
  )
)

checks_df <- do.call(rbind, checks)
stopifnot(nrow(checks_df) == 12L, all(checks_df$pass))
write.csv(
  checks_df,
  file.path(evidence_dir, "independent_preflight_checks.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  build_delta,
  file.path(evidence_dir, "independent_build_delta.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  data.frame(
    path = result_protected_post$path[protected_delta_rows],
    pre_sha256 = result_protected_post$sha256[protected_delta_rows],
    live_sha256 = protected_live[protected_delta_rows],
    exists = protected_exists[protected_delta_rows],
    stringsAsFactors = FALSE
  ),
  file.path(evidence_dir, "independent_protected_delta.csv"),
  row.names = FALSE,
  na = ""
)

cat(sprintf(
  paste0(
    "REPORT018_H10_RESULT_AND_COMPANION_PREFLIGHT=PASS ",
    "checks=%d owner=30/30 prospective=269/269 ",
    "tables=19 figures=2 headers=1050 build=4 protected=1 ",
    "science=57 R=%s\n"
  ),
  nrow(checks_df),
  as.character(getRversion())
))
