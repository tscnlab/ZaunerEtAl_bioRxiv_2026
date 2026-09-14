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

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H10/report018_order59a_companion_recovery_completion"
)
stopifnot(dir.exists(evidence_dir))

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
    bytes = ifelse(files, unname(as.numeric(info$size)), NA_real_),
    link_target = links,
    stringsAsFactors = FALSE
  )
}

compare_inventory <- function(previous, current) {
  previous$sha256[is.na(previous$sha256) | !nzchar(previous$sha256)] <- NA_character_
  current$sha256[is.na(current$sha256) | !nzchar(current$sha256)] <- NA_character_
  all_paths <- sort(unique(c(previous$path, current$path)))
  pre_index <- match(all_paths, previous$path)
  live_index <- match(all_paths, current$path)
  delta <- data.frame(
    path = all_paths,
    pre_sha256 = previous$sha256[pre_index],
    live_sha256 = current$sha256[live_index],
    pre_bytes = previous$bytes[pre_index],
    live_bytes = current$bytes[live_index],
    pre_type = previous$type[pre_index],
    live_type = current$type[live_index],
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

resolve_paths <- function(paths) {
  ifelse(startsWith(paths, "/"), paths, file.path(root, paths))
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

fixed <- data.frame(
  path = c(
    "audit/report_harmonization/owner_orders/59a_h10_companion_manifest_sequencing_recovery_and_completion.md",
    "audit/report_harmonization/report018_h10_order59a_dispatch.md",
    "audit/report_harmonization/report018_h10_order59a_dispatch_manifest.csv",
    "audit/report_harmonization/report018_h10_order59_stopped_independent_acceptance.md",
    "audit/report_harmonization/report018_h10_order59_stopped_independent_acceptance_manifest.csv",
    "audit/report_harmonization/coordination_matrix.csv",
    "notebooks/hypotheses/H10.qmd",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html",
    "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R",
    "tests/hypotheses/H10/test_h10_preparation_report.R",
    "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
    "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv",
    "audit/report_harmonization/report018_h10_companion_preflight/gt_html_semantic_post_render_summary.csv",
    "audit/report_harmonization/report018_h10_companion_preflight/H10_analysis_preparation_gt_semantic_ledger.csv",
    "_quarto-nathealth.yml",
    "notebooks/hypotheses/H11.qmd"
  ),
  sha256 = c(
    "ec44bd4160e356ec33a4312defbb54a31e5c70893c3f20a5a7ea825eed6767f9",
    "7f51102aeb314f874b877db219af7bb63aa25993bd2a97b8aeeaf5e14b2f8f8b",
    "5fe270b5cce6796d625a09a109d3ca00af56087a758cd7776699b22d84431102",
    "671bfbd72a9ee14de28472929eeaad4d0a25bee1b9ffb7dfaa78ed9812a91d82",
    "c4bb9a9412370fc9d3361e1fd4b9d58d32dd7a9b2808257158868571c4f72594",
    "8302b4906daa98c247025281d23bb1b896f456f0a6adf34b4068d17542a6c7fa",
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
    "37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9",
    "26619260657ec0cb1d7ac7614af9e3e349a524ee242dd5645b27e31f4cb142f0",
    "8b206d4cf565b6f5a767e6e99afb9e587db8255f2239cb3761eebaa8e69d1608",
    "dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af",
    "4ebb3e9a32a09f3b289920aea325fadf3eaf0f727087d457f3f568b910a39fe0",
    "4a3848b85d2e454dea54a2577759498953f160a1c0c43921147408a88d480682",
    "f43f701108cbdf5cdc9e62a2a2e231a6a00dd5e99ddc3700d03c4dd96de0324b",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867"
  ),
  stringsAsFactors = FALSE
)
fixed$exact <- vapply(
  seq_len(nrow(fixed)),
  function(index) file_exact(fixed$path[[index]], fixed$sha256[[index]]),
  logical(1)
)
write.csv(
  fixed,
  file.path(evidence_dir, paste0("fixed_identity_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)
add_check(
  "identity",
  "fixed_sources_html_tests_manifest_profile_and_h11",
  all(fixed$exact) &&
    !file.exists("audit/hypotheses/H10/H10_analysis_preparation.html"),
  sprintf(
    "exact=%d/%d obsolete_source_html_present=%s",
    sum(fixed$exact),
    nrow(fixed),
    file.exists("audit/hypotheses/H10/H10_analysis_preparation.html")
  )
)

manifest_path <-
  "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv"
preview_path <- paste0(
  "audit/report_harmonization/report018_h10_companion_preflight/",
  "prospective_preparation_report_manifest_preview.csv"
)
historical_exclusions_path <- paste0(
  "audit/report_harmonization/report018_h10_order59_recovery_preflight/",
  "order59_historical_evidence_exclusions.csv"
)
manifest <- read.csv(manifest_path, check.names = FALSE)
preview <- read.csv(preview_path, check.names = FALSE)
historical_exclusions <- read.csv(
  historical_exclusions_path,
  check.names = FALSE
)
manifest_files <- resolve_paths(manifest$path)
manifest_exact <- vapply(
  seq_len(nrow(manifest)),
  function(index) {
    file_exact(
      manifest_files[[index]],
      manifest$sha256[[index]],
      manifest$bytes[[index]]
    )
  },
  logical(1)
)
manifest_common <- merge(
  manifest[, c("path", "sha256", "bytes")],
  preview[, c("path", "sha256", "bytes")],
  by = "path",
  suffixes = c("_live", "_preview")
)
manifest_changed <- manifest_common[
  manifest_common$sha256_live != manifest_common$sha256_preview |
    manifest_common$bytes_live != manifest_common$bytes_preview,
  ,
  drop = FALSE
]
manifest_pass <-
  nrow(manifest) == 269L &&
  !anyDuplicated(manifest$path) &&
  setequal(manifest$path, preview$path) &&
  all(manifest_exact) &&
  nrow(manifest_changed) == 1L &&
  identical(
    manifest_changed$path,
    "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R"
  ) &&
  !manifest_path %in% manifest$path &&
  nrow(historical_exclusions) == 13L &&
  !any(historical_exclusions$path %in% manifest$path)
add_check(
  "manifest",
  "chronological_269_row_manifest",
  manifest_pass,
  sprintf(
    "rows=%d exact=%d paths=%d helper_delta=%d historical_rows=%d",
    nrow(manifest),
    sum(manifest_exact),
    length(intersect(manifest$path, preview$path)),
    nrow(manifest_changed),
    sum(historical_exclusions$path %in% manifest$path)
  )
)

historical_exact <- vapply(
  seq_len(nrow(historical_exclusions)),
  function(index) {
    file_exact(
      historical_exclusions$path[[index]],
      historical_exclusions$sha256[[index]],
      historical_exclusions$bytes[[index]]
    )
  },
  logical(1)
)
add_check(
  "history",
  "thirteen_order59_files_immutable",
  nrow(historical_exclusions) == 13L && all(historical_exact),
  sprintf("exact=%d/%d", sum(historical_exact), nrow(historical_exclusions))
)

owner_stop_manifest_path <- paste0(
  "audit/hypotheses/H10/",
  "report018_order59_companion_no_rerender_completion/",
  "order59_fail_closed_non_circular_evidence_manifest.csv"
)
owner_stop_manifest <- read.csv(owner_stop_manifest_path, check.names = FALSE)
owner_stop_files <- resolve_paths(owner_stop_manifest$path)
owner_stop_exists <- file.exists(owner_stop_files)
owner_stop_live_sha <- rep(NA_character_, nrow(owner_stop_manifest))
owner_stop_live_sha[owner_stop_exists] <- vapply(
  owner_stop_files[owner_stop_exists],
  sha256_file,
  character(1)
)
owner_stop_delta <- owner_stop_manifest[
  !owner_stop_exists | owner_stop_live_sha != owner_stop_manifest$sha256,
  c("path", "sha256", "bytes"),
  drop = FALSE
]
owner_stop_delta$live_sha256 <- owner_stop_live_sha[
  !owner_stop_exists | owner_stop_live_sha != owner_stop_manifest$sha256
]
expected_stop_delta <- c(
  "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv",
  "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R"
)
write.csv(
  owner_stop_delta,
  file.path(evidence_dir, paste0("stopped_state_protected_delta_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)
add_check(
  "protection",
  "exact_helper_and_manifest_transition_from_stopped_state",
  nrow(owner_stop_delta) == 2L &&
    identical(sort(owner_stop_delta$path), sort(expected_stop_delta)),
  sprintf(
    "delta=%d paths=%s",
    nrow(owner_stop_delta),
    paste(sort(owner_stop_delta$path), collapse = "|")
  )
)

companion_html <- paste0(
  "_build/nathealth/audit/hypotheses/H10/",
  "H10_analysis_preparation.html"
)
semantic_summary_path <- paste0(
  "audit/report_harmonization/report018_h10_companion_preflight/",
  "gt_html_semantic_post_render_summary.csv"
)
semantic_ledger_path <- paste0(
  "audit/report_harmonization/report018_h10_companion_preflight/",
  "H10_analysis_preparation_gt_semantic_ledger.csv"
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
    "c3014cafdd8a1d0906c7f570de8bd6f979a70153c9b83175e47a27703ca7c1b6"
  ) &&
  identical(reapplied_raw, html_raw) &&
  nrow(semantic_ledger) == 1132L &&
  sum(semantic_ledger$attribute == "id") == 82L &&
  sum(semantic_ledger$attribute == "headers") == 1050L
add_check(
  "semantic",
  "raw_reverse_and_exact_reapplication",
  semantic_pass,
  sprintf(
    "rows=%d ids=%d headers=%d",
    nrow(semantic_ledger),
    sum(semantic_ledger$attribute == "id"),
    sum(semantic_ledger$attribute == "headers")
  )
)

document <- xml2::read_html(companion_html)
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
figures <- xml2::xml_find_all(main, ".//figure//img")
figure_endpoints <- vapply(
  figures,
  function(image) {
    endpoint <- xml2::xml_find_first(
      image,
      "ancestor::*[@id and starts-with(@id,'fig-')][1]"
    )
    if (inherits(endpoint, "xml_missing")) {
      NA_character_
    } else {
      xml2::xml_attr(endpoint, "id")
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
    endpoint <- xml2::xml_find_first(
      table,
      "ancestor::*[@id and starts-with(@id,'tbl-')][1]"
    )
    if (inherits(endpoint, "xml_missing")) {
      NA_character_
    } else {
      xml2::xml_attr(endpoint, "id")
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
document_ids <- xml2::xml_attr(xml2::xml_find_all(document, ".//*[@id]"), "id")
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
          all(xml2::xml_name(id_nodes[positions]) == "th") &&
          all(
            xml2::xml_attr(id_nodes[positions], "scope") %in%
              c("col", "row", "colgroup", "rowgroup")
          )
      },
      logical(1)
    ))
  },
  logical(1)
))
mermaid_nodes <- xml2::xml_find_all(
  main,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
dom_pass <-
  length(gt_tables) == 19L &&
  identical(table_endpoints, expected_tables) &&
  length(figures) == 2L &&
  identical(figure_endpoints, expected_figures) &&
  !anyDuplicated(document_ids) &&
  headers_valid &&
  header_tokens == 1050L &&
  length(mermaid_nodes) == 1L &&
  grepl("flowchart TD", xml2::xml_text(mermaid_nodes[[1L]]), fixed = TRUE)
write.csv(
  rbind(
    data.frame(
      type = "table",
      position = seq_along(expected_tables),
      expected = expected_tables,
      observed = table_endpoints,
      exact = expected_tables == table_endpoints
    ),
    data.frame(
      type = "figure",
      position = seq_along(expected_figures),
      expected = expected_figures,
      observed = figure_endpoints,
      exact = expected_figures == figure_endpoints
    )
  ),
  file.path(evidence_dir, paste0("dom_endpoints_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)
add_check(
  "dom",
  "native_tables_figures_ids_headers_and_mermaid",
  dom_pass,
  sprintf(
    "tables=%d figures=%d duplicate_ids=%d headers=%d mermaid=%d",
    length(gt_tables),
    length(figures),
    anyDuplicated(document_ids),
    header_tokens,
    length(mermaid_nodes)
  )
)

main_text <- gsub("[[:space:]]+", " ", xml2::xml_text(main))
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
country_sites <- c(
  "Borås (SE)",
  "Delft (NL)",
  "Dortmund (DE)",
  "Tübingen (DE)",
  "Munich (DE)",
  "Madrid (ES)",
  "Izmir (TR)",
  "San José (CR)",
  "Kumasi (GH)"
)
error_nodes <- xml2::xml_find_all(
  main,
  paste0(
    ".//*[contains(@class,'cell-output-error') or ",
    "contains(@class,'cell-output-stderr') or ",
    "contains(@class,'cell-output-warning') or ",
    "contains(@class,'quarto-unresolved-ref')]"
  )
)
active_nav <- xml2::xml_find_all(
  document,
  "//nav//a[@aria-current='page' or contains(concat(' ',normalize-space(@class),' '),' active ')]"
)
content_pass <-
  all(vapply(required_text, grepl, logical(1), x = main_text, fixed = TRUE)) &&
  !any(vapply(forbidden_text, grepl, logical(1), x = main_text, fixed = TRUE)) &&
  all(vapply(country_sites, grepl, logical(1), x = main_text, fixed = TRUE)) &&
  length(error_nodes) == 0L &&
  length(active_nav) >= 1L
add_check(
  "content",
  "construct_coverage_provenance_integrity_and_sites",
  content_pass,
  sprintf(
    "required=%d/%d forbidden=%d sites=%d/%d errors=%d active_nav=%d",
    sum(vapply(required_text, grepl, logical(1), x = main_text, fixed = TRUE)),
    length(required_text),
    sum(vapply(forbidden_text, grepl, logical(1), x = main_text, fixed = TRUE)),
    sum(vapply(country_sites, grepl, logical(1), x = main_text, fixed = TRUE)),
    length(country_sites),
    length(error_nodes),
    length(active_nav)
  )
)

hrefs <- xml2::xml_attr(xml2::xml_find_all(main, ".//a[@href]"), "href")
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
  target_document <- xml2::read_html(resolved[[index]])
  fragment_once[[index]] <- length(xml2::xml_find_all(
    target_document,
    sprintf("//*[@id='%s']", fragment)
  )) == 1L
}
link_audit <- data.frame(
  href = local_hrefs,
  resolved_path = resolved,
  exists = file.exists(resolved),
  fragment_once = fragment_once,
  stringsAsFactors = FALSE
)
write.csv(
  link_audit,
  file.path(evidence_dir, paste0("link_resolution_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)
link_pass <-
  length(local_hrefs) == 23L &&
  length(unique(local_hrefs)) == 19L &&
  sum(fragment_rows) == 6L &&
  all(file.exists(resolved)) &&
  all(fragment_once)
add_check(
  "links",
  "twenty_three_local_links_and_six_fragments",
  link_pass,
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

result_build_post <- read.csv(
  paste0(
    "audit/hypotheses/H10/report018_order58a_no_rerender_completion/",
    "build_inventory_postqa.csv"
  ),
  check.names = FALSE
)
current_build <- inventory_tree("_build/nathealth")
build_delta <- compare_inventory(result_build_post, current_build)
expected_build_paths <- c(
  "_build/nathealth/artifacts/12_manifests/H10/H10_stage3_artifacts.csv",
  companion_html,
  "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.qmd",
  "_build/nathealth/search.json",
  "_build/nathealth/sitemap.xml"
)
expected_build_hashes <- c(
  "b556d9fdb19eeda766414bab30420846ee5c46138e9d7861f61e92da7516683e",
  "dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9",
  "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
  "a2c91ee1278975361e766ac222c67944d6f631f261b3294bc4f988a90c3687b4",
  "7459928e1bc22a5a75c3be04b0e04b8190d5aaa8cc07c0d1e7b46df06a7cac08"
)
build_pass <-
  nrow(current_build) == 1180L &&
  nrow(build_delta) == 5L &&
  identical(sort(build_delta$path), sort(expected_build_paths)) &&
  all(
    build_delta$live_sha256[match(expected_build_paths, build_delta$path)] ==
      expected_build_hashes
  ) &&
  sum(current_build$type == "symlink") == 0L
write.csv(
  current_build,
  file.path(evidence_dir, paste0("build_inventory_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)
write.csv(
  build_delta,
  file.path(evidence_dir, paste0("build_delta_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)
add_check(
  "build",
  "stopped_state_build_tree_preserved",
  build_pass,
  sprintf(
    "entries=%d delta=%d symlinks=%d",
    nrow(current_build),
    nrow(build_delta),
    sum(current_build$type == "symlink")
  )
)

protected_paths <- unique(c(
  fixed$path,
  owner_stop_manifest$path,
  manifest$path,
  scientific_assets,
  semantic_summary_path,
  semantic_ledger_path
))
protected_files <- resolve_paths(protected_paths)
stopifnot(all(file.exists(protected_files)), all(!file.info(protected_files)$isdir))
protected_inventory <- data.frame(
  path = protected_paths,
  sha256 = vapply(protected_files, sha256_file, character(1)),
  bytes = vapply(protected_files, file_bytes, numeric(1)),
  stringsAsFactors = FALSE
)
protected_inventory <- protected_inventory[order(protected_inventory$path), , drop = FALSE]
write.csv(
  protected_inventory,
  file.path(evidence_dir, paste0("protected_inventory_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)

qa <- read.csv(
  "artifacts/12_manifests/H10/H10_preparation_figure_readability_qa.csv",
  check.names = FALSE
)
qa_checks <- c(
  "no_clipping_or_cropping",
  "no_overlap",
  "no_text_distortion",
  "no_bad_wrapping",
  "important_text_readable",
  "data_region_proportionate",
  "marks_distinguishable",
  "caption_and_alt_text_present"
)
image_alts <- xml2::xml_attr(figures, "alt")
qa_pass <-
  nrow(qa) == 2L &&
  all(qa$intended_display_width_mm == 170) &&
  all(qa$overall_status == "PASS") &&
  all(vapply(qa[qa_checks], function(value) all(value == "PASS"), logical(1))) &&
  all(nchar(image_alts) >= 100L)
add_check(
  "qa_harness",
  "figure_readability_and_alt_contract",
  qa_pass,
  sprintf(
    "rows=%d status=%d/%d alt_min=%d",
    nrow(qa),
    sum(qa$overall_status == "PASS"),
    nrow(qa),
    min(nchar(image_alts))
  )
)

if (phase == "postqa") {
  visual <- read.csv(
    file.path(evidence_dir, "visual_qa_observations.csv"),
    check.names = FALSE
  )
  lifecycle <- read.csv(
    file.path(evidence_dir, "server_lifecycle.csv"),
    check.names = FALSE
  )
  pre_build <- read.csv(
    file.path(evidence_dir, "build_inventory_preqa.csv"),
    check.names = FALSE
  )
  pre_protected <- read.csv(
    file.path(evidence_dir, "protected_inventory_preqa.csv"),
    check.names = FALSE
  )
  post_build <- read.csv(
    file.path(evidence_dir, "build_inventory_postqa.csv"),
    check.names = FALSE
  )
  post_protected <- read.csv(
    file.path(evidence_dir, "protected_inventory_postqa.csv"),
    check.names = FALSE
  )
  build_no_drift <- identical(pre_build, post_build)
  protected_no_drift <- identical(pre_protected, post_protected)
  no_drift <-
    build_no_drift &&
    protected_no_drift
  visual_pass <-
    nrow(visual) >= 15L &&
    all(visual$status == "PASS") &&
    all(c("1440x1000", "708x1000", "720x500", "642px") %in% visual$view) &&
    all(lifecycle$status == "PASS") &&
    no_drift
  add_check(
    "post_qa",
    "visual_lifecycle_and_no_drift",
    visual_pass,
    sprintf(
      "visual=%d/%d lifecycle=%d/%d build_no_drift=%s protected_no_drift=%s",
      sum(visual$status == "PASS"),
      nrow(visual),
      sum(lifecycle$status == "PASS"),
      nrow(lifecycle),
      build_no_drift,
      protected_no_drift
    )
  )
}

audit <- do.call(rbind, checks)
write.csv(
  audit,
  file.path(evidence_dir, paste0("static_checks_", phase, ".csv")),
  row.names = FALSE,
  na = ""
)
if (!all(audit$pass)) {
  print(audit[!audit$pass, , drop = FALSE])
  stop(sprintf("Order 59a %s verifier failed", phase), call. = FALSE)
}

if (phase == "preqa") {
  validation_context <- data.frame(
    component = c("R", "gt", "xml2", "openssl", "Quarto command"),
    version_or_status = c(
      as.character(getRversion()),
      as.character(utils::packageVersion("gt")),
      as.character(utils::packageVersion("xml2")),
      as.character(utils::packageVersion("openssl")),
      "not invoked by Order 59a"
    ),
    stringsAsFactors = FALSE
  )
  write.csv(
    validation_context,
    file.path(evidence_dir, "validation_context.csv"),
    row.names = FALSE,
    na = ""
  )
  cat(sprintf(
    paste0(
      "REPORT018_H10_ORDER59A_STATIC_PREQA=PASS checks=%d manifest=269/269 ",
      "tables=19 figures=2 headers=1050 links=23/19 fragments=6 ",
      "science=57 build=1180/5 protected_delta=2 R=4.6.1\n"
    ),
    nrow(audit)
  ))
} else {
  record <- c(
    "# REPORT-018 H10 order 59a companion recovery acceptance",
    "",
    paste0("Sealed UTC: ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
    "",
    "## Disposition",
    "",
    "Order 59a is accepted. The sealed helper postimage excluded exactly the 13 immutable Order 59 historical evidence files and reversed exactly to the prior helper. The one authorized helper retry produced 269 current files, and the immediate 269-row gate passed with 269 of 269 live identities. The unchanged strict preparation test then ran once and passed for 19 native gt tables, two descriptive figures, and 68 frozen frames.",
    "",
    "No Quarto, knitr, Pandoc, semantic hook, QMD execution, render, scientific builder, model, prediction, simulation, bootstrap, sensitivity analysis, package operation, commit, push, or upload occurred. The preserved companion HTML remained byte-identical.",
    "",
    "Static verification passed for one document main element, 19 native gt tables, two figures, one top-down Mermaid diagram, zero duplicate IDs, 1,050 scoped header tokens, exact semantic reversal and reapplication, 23 local links including six fragments, all required construct and provenance wording, all nine country-coded sites, all 57 scientific assets, and the exact historical build and protected deltas.",
    "",
    "Secure-loopback visual QA passed at 1440 by 1000, 708 by 1000, 720 by 500, and 642-pixel figure width. The server was bound only to 127.0.0.1, then stopped. The QA tab was closed, the viewport reset, and no listener remained. Build and protected inventories were byte-identical before and after QA.",
    "",
    "H11 and all later targets remain held pending independent acceptance.",
    ""
  )
  record_path <- file.path(evidence_dir, "order59a_acceptance_record.md")
  writeLines(record, record_path, useBytes = TRUE)

  manifest_output <- file.path(
    evidence_dir,
    "order59a_non_circular_evidence_manifest.csv"
  )
  local_files <- list.files(
    evidence_dir,
    full.names = TRUE,
    recursive = FALSE,
    all.files = TRUE,
    no.. = TRUE
  )
  local_files <- local_files[
    !dir.exists(local_files) & basename(local_files) != basename(manifest_output)
  ]
  external_files <- resolve_paths(unique(c(
    fixed$path,
    historical_exclusions_path,
    preview_path,
    owner_stop_manifest_path,
    scientific_assets
  )))
  files <- unique(c(sort(local_files), external_files))
  stopifnot(all(file.exists(files)), !manifest_output %in% files)
  owner_manifest <- data.frame(
    path = ifelse(
      startsWith(files, paste0(root, "/")),
      substring(files, nchar(root) + 2L),
      files
    ),
    sha256 = vapply(files, sha256_file, character(1)),
    bytes = vapply(files, file_bytes, numeric(1)),
    role = ifelse(
      startsWith(files, paste0(evidence_dir, "/")),
      "order59a_owner_evidence",
      "protected_external_identity"
    ),
    stringsAsFactors = FALSE
  )
  stopifnot(
    !anyDuplicated(owner_manifest$path),
    !basename(manifest_output) %in% basename(owner_manifest$path)
  )
  write.csv(owner_manifest, manifest_output, row.names = FALSE, na = "")
  cat(sprintf(
    paste0(
      "REPORT018_H10_ORDER59A=ACCEPTED checks=%d manifest=269/269 test=PASS ",
      "static=PASS visual=PASS build_no_drift=PASS protected_no_drift=PASS ",
      "owner_manifest=%s\n"
    ),
    nrow(audit),
    sha256_file(manifest_output)
  ))
}
