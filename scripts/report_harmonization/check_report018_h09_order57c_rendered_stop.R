#!/usr/bin/env Rscript

# Independently audit the rendered REPORT-018 H09 order-57c stop. This
# checker is read-only with respect to H09 authoring, scientific, build, and
# historical evidence files. It writes only coordinator-owned audit tables.

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2, lifecycle_verbosity = "quiet")

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H09 order-57c rendered-stop audit requires R 4.6.1.", call. = FALSE)
}

required_packages <- c("digest", "dplyr", "knitr", "tibble", "xml2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tibble)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv(
    "NATHEALTH_PROJECT_ROOT",
    unset = paste0(
      "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/",
      "WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
    )
  ),
  winslash = "/",
  mustWork = TRUE
)
owner_dir <- normalizePath(
  Sys.getenv(
    "H09_ORDER57C_OWNER_DIR",
    unset = file.path(
      root,
      "audit/hypotheses/H09/report018_order57c_companion_retry"
    )
  ),
  winslash = "/",
  mustWork = TRUE
)
working_dir <- normalizePath(
  Sys.getenv(
    "H09_ORDER57C_WORKING_DIR",
    unset = "/private/tmp/h09-order57c-working.mx4s2k"
  ),
  winslash = "/",
  mustWork = TRUE
)
semantic_dir <- normalizePath(
  Sys.getenv(
    "H09_ORDER57C_SEMANTIC_DIR",
    unset = "/private/tmp/h09-order57c-semantic.wgVojR"
  ),
  winslash = "/",
  mustWork = TRUE
)
output_prefix <- file.path(
  root,
  "audit/report_harmonization/report018_h09_order57c_rendered_stop_independent"
)
setwd(root)

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256")
}

sha256_raw <- function(value) {
  digest::digest(value, algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) unname(file.info(path)$size)

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file_bytes(path))
}

replace_ranges <- function(content, starts, ends, replacements) {
  for (i in order(starts, decreasing = TRUE)) {
    before <- if (starts[[i]] > 1L) {
      content[seq_len(starts[[i]] - 1L)]
    } else {
      raw()
    }
    after <- if (ends[[i]] < length(content)) {
      content[seq.int(ends[[i]] + 1L, length(content))]
    } else {
      raw()
    }
    content <- c(before, charToRaw(enc2utf8(replacements[[i]])), after)
  }
  content
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  ifelse(
    startsWith(normalized, paste0(root, "/")),
    substring(normalized, nchar(root) + 2L),
    normalized
  )
}

inventory_files <- function(directory) {
  entries <- list.files(
    directory,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
  symlinks <- entries[nzchar(Sys.readlink(entries))]
  files <- entries[file.exists(entries) & !dir.exists(entries)]
  stopifnot(length(symlinks) == 0L)
  files <- sort(normalizePath(files, winslash = "/", mustWork = TRUE))
  tibble(
    relative_path = relative_path(files),
    sha256 = vapply(files, sha256_file, character(1)),
    bytes = file_bytes(files)
  )
}

checks <- tibble(
  domain = character(),
  check = character(),
  observed = character(),
  expected = character(),
  status = character()
)

add_check <- function(domain, check, observed, expected, pass) {
  checks <<- bind_rows(
    checks,
    tibble(
      domain = domain,
      check = check,
      observed = paste(observed, collapse = "/"),
      expected = paste(expected, collapse = "/"),
      status = if (isTRUE(pass)) "PASS" else "FAIL"
    )
  )
}

require_identity <- function(path, sha256, bytes, label) {
  exists <- file.exists(path) && !dir.exists(path)
  observed_sha <- if (exists) sha256_file(path) else NA_character_
  observed_bytes <- if (exists) file_bytes(path) else NA_real_
  pass <- exists &&
    identical(observed_sha, sha256) &&
    identical(observed_bytes, as.numeric(bytes))
  add_check(
    "identity",
    label,
    paste(observed_sha, observed_bytes, sep = "/"),
    paste(sha256, bytes, sep = "/"),
    pass
  )
  stopifnot(pass)
}

owner_record <- file.path(owner_dir, "ORDER57C_FAIL_CLOSED.md")
owner_manifest_path <- file.path(
  owner_dir,
  "order57c_fail_closed_evidence_manifest.csv"
)
owner_verifier <- file.path(owner_dir, "verify_order57c_fail_closed.R")
require_identity(
  owner_record,
  "87f92fe75d8c7378275ec5a51147ae580166f1ebc228ce7ae59f98adc09b3bd4",
  5195,
  "owner fail-closed record"
)
require_identity(
  owner_manifest_path,
  "8090069f94b1cf891fd7644c53f161ab11ec7958be21c7d86a1293974e13b63c",
  19010,
  "owner non-circular manifest"
)
require_identity(
  owner_verifier,
  "b3e3c47b095ef4c3a5e8c33d064f9e77d03b8ff9a3da0f29289fde15dee78df0",
  20266,
  "owner fail-closed verifier"
)

owner_manifest <- utils::read.csv(owner_manifest_path, check.names = FALSE)
stopifnot(
  nrow(owner_manifest) == 63L,
  !anyDuplicated(owner_manifest$path),
  !owner_manifest_path %in% owner_manifest$observed_path,
  all(owner_manifest$r_version == "4.6.1")
)
owner_exists <- file.exists(owner_manifest$observed_path) &
  !dir.exists(owner_manifest$observed_path)
owner_sha <- rep(NA_character_, nrow(owner_manifest))
owner_bytes <- rep(NA_real_, nrow(owner_manifest))
owner_sha[owner_exists] <- vapply(
  owner_manifest$observed_path[owner_exists],
  sha256_file,
  character(1)
)
owner_bytes[owner_exists] <- file_bytes(owner_manifest$observed_path[
  owner_exists
])
owner_audit <- owner_manifest |>
  mutate(
    observed_sha256 = owner_sha,
    observed_bytes = owner_bytes,
    status = if_else(
      owner_exists &
        .data$sha256 == .data$observed_sha256 &
        as.numeric(.data$bytes) == .data$observed_bytes,
      "PASS",
      "FAIL"
    )
  )
stopifnot(all(owner_audit$status == "PASS"))
add_check(
  "owner stop",
  "63-row owner evidence manifest",
  paste0(sum(owner_audit$status == "PASS"), "/63"),
  "63/63 exact, unique, non-circular",
  all(owner_audit$status == "PASS")
)

invocations <- utils::read.csv(
  file.path(owner_dir, "order57c_invocation_ledger.csv"),
  check.names = FALSE
)
stopifnot(
  nrow(invocations) == 5L,
  identical(as.integer(invocations$invocation_count), c(1L, 1L, 1L, 0L, 0L)),
  identical(
    invocations$status,
    c("PASS", "PASS", "FAIL_CONTRACT", "NOT_RUN", "NOT_RUN")
  )
)
add_check(
  "invocations",
  "one render and helper; no retry, post verifier, or browser",
  paste(invocations$invocation_count, collapse = "/"),
  "1/1/1/0/0",
  TRUE
)

current_pins <- tribble(
  ~path,
  ~sha256,
  ~bytes,
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "394a976e52faf002cb2034a13353a053aae8bfda8942a79c2eb007017cae014f",
  51736,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "394a976e52faf002cb2034a13353a053aae8bfda8942a79c2eb007017cae014f",
  51736,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
  "09b604b011ef14c138c15720b419a9ca200e15f71ce3e40a9b85c23f6803f96d",
  631401,
  "notebooks/hypotheses/H09.qmd",
  "c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6",
  36970,
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16",
  244127,
  "artifacts/12_manifests/H09/H09_stage3_artifacts.csv",
  "0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2",
  24678,
  "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv",
  "90a47a6070a692d0089ef68f821b781998428f189d2718e12a8cdda046868ae2",
  158291,
  "scripts/hypotheses/H09/build_h09_preparation_report_manifest.R",
  "c7a320367e0115aee221a3a6ba5228a9a27ba55f734bd07881455b3159cebf56",
  9753,
  "tests/hypotheses/H09/test_h09_preparation_report.R",
  "9a243e391de7069179fcd0ccb7cc6813a5e779b1ae1bf7fcb52706349553dfe7",
  12824,
  "_quarto-nathealth.yml",
  "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  7480,
  "renv.lock",
  "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
  603493,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation_files/figure-html/fig-h09-prep-sample-support-1.png",
  "3116032e2bab0ad904a5cca5cb6353b5c0554e576cf076596671e31ed2caa775",
  129472
)
pin_files <- file.path(root, current_pins$path)
pin_exact <- file.exists(pin_files) &
  !dir.exists(pin_files) &
  vapply(pin_files, sha256_file, character(1)) == current_pins$sha256 &
  file_bytes(pin_files) == as.numeric(current_pins$bytes)
stopifnot(all(pin_exact))
add_check(
  "identity",
  "current rendered and protected pins",
  paste0(sum(pin_exact), "/", nrow(current_pins)),
  paste0(nrow(current_pins), "/", nrow(current_pins)),
  all(pin_exact)
)

manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv"
)
manifest <- utils::read.csv(manifest_path, check.names = FALSE)
manifest_files <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- vapply(
  manifest_files[manifest_exists],
  sha256_file,
  character(1)
)
manifest_bytes[manifest_exists] <- file_bytes(manifest_files[manifest_exists])
manifest_exact <- manifest_exists &
  manifest_sha == manifest$sha256 &
  manifest_bytes == as.numeric(manifest$bytes)
stopifnot(
  nrow(manifest) == 553L,
  !anyDuplicated(manifest$path),
  !relative_path(manifest_path) %in% manifest$path,
  !any(grepl(
    "report018_order57c_companion_retry",
    manifest$path,
    fixed = TRUE
  )),
  all(manifest_exact)
)
add_check(
  "preparation manifest",
  "current helper output",
  paste0(sum(manifest_exact), "/553"),
  "553/553 live-exact, unique, non-circular",
  all(manifest_exact)
)

pre_manifest <- utils::read.csv(
  file.path(working_dir, "helper_inventory_pre.csv"),
  check.names = FALSE
)
stopifnot(nrow(pre_manifest) == 554L, !anyDuplicated(pre_manifest$path))
common_paths <- intersect(pre_manifest$path, manifest$path)
missing_paths <- setdiff(pre_manifest$path, manifest$path)
added_paths <- setdiff(manifest$path, pre_manifest$path)
pre_common <- pre_manifest[match(common_paths, pre_manifest$path), ]
post_common <- manifest[match(common_paths, manifest$path), ]
common_exact <- pre_common$sha256 == post_common$sha256 &
  as.numeric(pre_common$bytes) == as.numeric(post_common$bytes)
common_changed_paths <- common_paths[!common_exact]
expected_common_changed <- c(
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd"
)
stopifnot(
  length(common_paths) == 537L,
  sum(common_exact) == 535L,
  setequal(common_changed_paths, expected_common_changed),
  length(missing_paths) == 17L,
  length(added_paths) == 16L
)
manifest_transition <- bind_rows(
  tibble(
    path = common_paths,
    transition = if_else(
      common_exact,
      "UNCHANGED",
      "EXPECTED_RENDERED_ENDPOINT_TRANSITION"
    ),
    pre_sha256 = pre_common$sha256,
    post_sha256 = post_common$sha256,
    pre_bytes = as.numeric(pre_common$bytes),
    post_bytes = as.numeric(post_common$bytes),
    status = if_else(
      common_exact | common_paths %in% expected_common_changed,
      "PASS",
      "FAIL"
    )
  ),
  tibble(
    path = missing_paths,
    transition = "EXPECTED_SOURCE_SIDE_CANONICAL_CLEANUP",
    pre_sha256 = pre_manifest$sha256[match(missing_paths, pre_manifest$path)],
    post_sha256 = NA_character_,
    pre_bytes = as.numeric(pre_manifest$bytes[match(
      missing_paths,
      pre_manifest$path
    )]),
    post_bytes = NA_real_,
    status = "PASS"
  ),
  tibble(
    path = added_paths,
    transition = "EXPECTED_CANONICAL_PAGE_ASSET",
    pre_sha256 = NA_character_,
    post_sha256 = manifest$sha256[match(added_paths, manifest$path)],
    pre_bytes = NA_real_,
    post_bytes = as.numeric(manifest$bytes[match(added_paths, manifest$path)]),
    status = "PASS"
  )
)
stopifnot(
  nrow(manifest_transition) == 570L,
  all(manifest_transition$status == "PASS")
)
add_check(
  "preparation manifest",
  "pre-render to post-helper membership transition",
  paste(
    sum(common_exact),
    length(common_changed_paths),
    length(missing_paths),
    length(added_paths),
    sep = "/"
  ),
  "535 unchanged/2 target changes/17 removed/16 added",
  TRUE
)

support_audit <- utils::read.csv(
  file.path(owner_dir, "source_side_support_missing_audit.csv"),
  check.names = FALSE
)
stopifnot(nrow(support_audit) == 16L, all(!support_audit$current_exists))
canonical_support <- sub(
  "^audit/hypotheses/H09/",
  "_build/nathealth/audit/hypotheses/H09/",
  support_audit$relative_path
)
canonical_files <- file.path(root, canonical_support)
canonical_exact <- file.exists(canonical_files) &
  !dir.exists(canonical_files) &
  vapply(canonical_files, sha256_file, character(1)) == support_audit$sha256 &
  file_bytes(canonical_files) == as.numeric(support_audit$bytes)
source_html_absent <- !file.exists(file.path(
  root,
  "audit/hypotheses/H09/H09_analysis_preparation.html"
))
stopifnot(all(canonical_exact), source_html_absent)
source_cleanup_audit <- support_audit |>
  transmute(
    historical_path = .data$relative_path,
    canonical_path = canonical_support,
    sha256 = .data$sha256,
    bytes = as.numeric(.data$bytes),
    historical_absent = !.data$current_exists,
    canonical_exact = canonical_exact,
    status = if_else(
      .data$historical_absent & .data$canonical_exact,
      "PASS",
      "FAIL"
    )
  )
stopifnot(all(source_cleanup_audit$status == "PASS"))
add_check(
  "canonical output",
  "historical support maps byte-for-byte to canonical support",
  paste0(sum(canonical_exact), "/16; source HTML absent=", source_html_absent),
  "16/16; TRUE",
  all(canonical_exact) && source_html_absent
)

build_pre <- utils::read.csv(
  file.path(working_dir, "build_inventory_prerender.csv"),
  check.names = FALSE
)
build_current <- inventory_files(file.path(root, "_build/nathealth"))
build_delta <- full_join(
  build_pre |>
    select(
      .data$relative_path,
      pre_sha256 = .data$sha256,
      pre_bytes = .data$bytes
    ),
  build_current |>
    select(
      .data$relative_path,
      post_sha256 = .data$sha256,
      post_bytes = .data$bytes
    ),
  by = "relative_path",
  relationship = "one-to-one"
) |>
  mutate(
    disposition = case_when(
      !is.na(.data$pre_sha256) &
        !is.na(.data$post_sha256) &
        .data$pre_sha256 == .data$post_sha256 &
        as.numeric(.data$pre_bytes) == as.numeric(.data$post_bytes) ~
        "UNCHANGED",
      is.na(.data$pre_sha256) ~ "ADDED",
      is.na(.data$post_sha256) ~ "MISSING",
      TRUE ~ "CHANGED"
    )
  )
expected_build_changed <- c(
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd",
  "_build/nathealth/search.json",
  "_build/nathealth/sitemap.xml"
)
expected_resource_additions <- c(
  "_build/nathealth/artifacts/06_model_data/H09/H09_model_frame_index.csv",
  "_build/nathealth/artifacts/09_tables/H09/H09_paired_placement_effects.csv",
  "_build/nathealth/artifacts/12_manifests/H09/H09_package_versions.csv",
  "_build/nathealth/artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
)
expected_page_additions <- canonical_support
observed_changed <- build_delta$relative_path[
  build_delta$disposition == "CHANGED"
]
observed_added <- build_delta$relative_path[build_delta$disposition == "ADDED"]
observed_missing <- build_delta$relative_path[
  build_delta$disposition == "MISSING"
]
resource_source <- sub("^_build/nathealth/", "", expected_resource_additions)
resource_source_files <- file.path(root, resource_source)
resource_target_files <- file.path(root, expected_resource_additions)
resource_exact <- file.exists(resource_source_files) &
  file.exists(resource_target_files) &
  vapply(resource_source_files, sha256_file, character(1)) ==
    vapply(resource_target_files, sha256_file, character(1)) &
  file_bytes(resource_source_files) == file_bytes(resource_target_files)
build_qmd_exact <- identical(
  read_raw_file(file.path(root, current_pins$path[[1L]])),
  read_raw_file(file.path(root, current_pins$path[[2L]]))
)
stopifnot(
  nrow(build_pre) == 851L,
  nrow(build_current) == 871L,
  sum(build_delta$disposition == "UNCHANGED") == 847L,
  setequal(observed_changed, expected_build_changed),
  setequal(
    observed_added,
    c(expected_resource_additions, expected_page_additions)
  ),
  length(observed_missing) == 0L,
  all(resource_exact),
  build_qmd_exact
)
build_delta <- build_delta |>
  mutate(
    classification = case_when(
      .data$disposition == "UNCHANGED" ~ "UNCHANGED",
      .data$relative_path == expected_build_changed[[1L]] ~ "TARGET_HTML",
      .data$relative_path == expected_build_changed[[2L]] ~
        "SOURCE_IDENTICAL_BUILD_QMD",
      .data$relative_path %in% expected_build_changed[3:4] ~
        "SITE_INDEX_UPDATE",
      .data$relative_path %in% expected_resource_additions ~
        "SOURCE_IDENTICAL_LINKED_RESOURCE",
      .data$relative_path %in% expected_page_additions ~ "TARGET_PAGE_ASSET",
      TRUE ~ "UNEXPECTED"
    ),
    status = if_else(.data$classification == "UNEXPECTED", "FAIL", "PASS")
  )
stopifnot(all(build_delta$status == "PASS"))
add_check(
  "build",
  "exact target-owned render transition",
  paste(
    nrow(build_pre),
    nrow(build_current),
    length(observed_changed),
    length(observed_added),
    sep = "/"
  ),
  "851/871/4/20 with zero missing",
  TRUE
)

semantic_summary_path <- file.path(
  semantic_dir,
  "gt_html_semantic_post_render_summary.csv"
)
semantic_ledger_path <- file.path(
  semantic_dir,
  paste0(
    "001__build__nathealth__audit__hypotheses__H09__",
    "H09_analysis_preparation.html_gt_semantic_ledger.csv"
  )
)
semantic_summary <- utils::read.csv(semantic_summary_path, check.names = FALSE)
ledger <- utils::read.csv(semantic_ledger_path, check.names = FALSE)
html_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html"
)
post_raw <- read_raw_file(html_path)
pre_raw <- replace_ranges(
  post_raw,
  as.integer(ledger$post_value_start_byte),
  as.integer(ledger$post_value_end_byte),
  ledger$pre_value
)
reapplied_raw <- replace_ranges(
  pre_raw,
  as.integer(ledger$pre_value_start_byte),
  as.integer(ledger$pre_value_end_byte),
  ledger$post_value
)
stopifnot(
  nrow(semantic_summary) == 1L,
  semantic_summary$disposition == "REPAIRED",
  semantic_summary$table_count == 19L,
  semantic_summary$id_count == 102L,
  semantic_summary$headers_count == 591L,
  semantic_summary$total_substitutions == 693L,
  semantic_summary$pre_sha256 == sha256_raw(pre_raw),
  semantic_summary$post_sha256 == sha256_raw(post_raw),
  semantic_summary$pre_bytes == length(pre_raw),
  semantic_summary$post_bytes == length(post_raw),
  nrow(ledger) == 693L,
  sum(ledger$attribute == "id") == 102L,
  sum(ledger$attribute == "headers") == 591L,
  identical(reapplied_raw, post_raw)
)

document <- xml2::read_html(rawToChar(post_raw))
main <- xml2::xml_find_all(document, "//main[@id='quarto-document-content']")
tables <- xml2::xml_find_all(
  main,
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
document_ids <- xml2::xml_attr(xml2::xml_find_all(document, "//*[@id]"), "id")
document_ids <- document_ids[!is.na(document_ids) & nzchar(document_ids)]
header_token_rows <- list()
for (i in seq_along(tables)) {
  table <- tables[[i]]
  endpoint <- xml2::xml_find_first(
    table,
    "ancestor::*[@id and starts-with(@id,'tbl-h09-')][1]"
  )
  endpoint_id <- xml2::xml_attr(endpoint, "id")
  header_nodes <- xml2::xml_find_all(table, ".//*[@headers]")
  header_values <- xml2::xml_attr(header_nodes, "headers")
  for (j in seq_along(header_values)) {
    tokens <- strsplit(trimws(header_values[[j]]), "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    for (token in tokens) {
      matches <- xml2::xml_find_all(table, sprintf(".//*[@id='%s']", token))
      one_th <- length(matches) == 1L && xml2::xml_name(matches[[1L]]) == "th"
      valid_scope <- one_th &&
        xml2::xml_attr(matches[[1L]], "scope") %in%
          c("col", "row", "colgroup", "rowgroup")
      header_token_rows[[length(header_token_rows) + 1L]] <- tibble(
        table_index = i,
        table_endpoint = endpoint_id,
        headers_index = j,
        token = token,
        match_count = length(matches),
        matched_th = one_th,
        valid_scope = valid_scope,
        status = if_else(one_th && valid_scope, "PASS", "FAIL")
      )
    }
  }
}
header_token_audit <- bind_rows(header_token_rows)
stopifnot(
  length(main) == 1L,
  length(tables) == 19L,
  !anyDuplicated(document_ids),
  nrow(header_token_audit) > 0L,
  all(header_token_audit$status == "PASS")
)

old_ledger <- utils::read.csv(
  file.path(
    working_dir,
    paste0(
      "semantic_probe_audit/001__build__nathealth__audit__hypotheses__H09__",
      "H09_analysis_preparation.html_gt_semantic_ledger.csv"
    )
  ),
  check.names = FALSE
)
old_counts <- old_ledger |>
  count(.data$table_endpoint, .data$attribute, name = "old_count")
new_counts <- ledger |>
  count(.data$table_endpoint, .data$attribute, name = "new_count")
semantic_transition <- full_join(
  old_counts,
  new_counts,
  by = c("table_endpoint", "attribute"),
  relationship = "one-to-one"
) |>
  mutate(
    old_count = coalesce(.data$old_count, 0L),
    new_count = coalesce(.data$new_count, 0L),
    delta = .data$new_count - .data$old_count,
    status = "PASS"
  )
observed_semantic_delta <- semantic_transition |>
  filter(.data$delta != 0L) |>
  arrange(.data$table_endpoint, .data$attribute)
expected_delta <- tibble(
  table_endpoint = c(
    "tbl-h09-prep-key-output-identities",
    "tbl-h09-prep-reader-manifest-check"
  ),
  attribute = c("headers", "headers"),
  delta = c(-3L, 6L)
)
stopifnot(
  nrow(old_ledger) == 690L,
  sum(old_ledger$attribute == "id") == 102L,
  sum(old_ledger$attribute == "headers") == 588L,
  nrow(observed_semantic_delta) == 2L,
  identical(
    observed_semantic_delta$table_endpoint,
    expected_delta$table_endpoint
  ),
  identical(observed_semantic_delta$attribute, expected_delta$attribute),
  identical(as.integer(observed_semantic_delta$delta), expected_delta$delta)
)
add_check(
  "semantics",
  "raw reversal, reapplication, IDs, and scoped header tokens",
  paste(
    length(tables),
    sum(ledger$attribute == "id"),
    sum(ledger$attribute == "headers"),
    nrow(ledger),
    nrow(header_token_audit),
    sep = "/"
  ),
  paste0("19/102/591/693/", nrow(header_token_audit)),
  TRUE
)
add_check(
  "semantics",
  "three additional substitutions localized to accepted table shapes",
  paste0(
    observed_semantic_delta$table_endpoint,
    ":",
    observed_semantic_delta$delta,
    collapse = "|"
  ),
  "key-output:-3|reader-manifest:+6",
  TRUE
)

qmd_path <- file.path(root, "audit/hypotheses/H09/H09_analysis_preparation.qmd")
qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd_text <- paste(qmd_lines, collapse = "\n")
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
table_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: tbl-h09-", qmd_lines, value = TRUE)
)
figure_labels <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: fig-h09-", qmd_lines, value = TRUE)
)
html_table_endpoints <- xml2::xml_attr(
  xml2::xml_find_all(main, ".//div[starts-with(@id, 'tbl-h09-')]"),
  "id"
)
html_figure_endpoints <- xml2::xml_attr(
  xml2::xml_find_all(main, ".//div[starts-with(@id, 'fig-h09-')]"),
  "id"
)
mermaid_nodes <- xml2::xml_find_all(
  main,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
manifest_rows <- length(xml2::xml_find_all(
  main,
  ".//*[@id='tbl-h09-prep-reader-manifest-check']//tbody/tr"
))
key_output_rows <- length(xml2::xml_find_all(
  main,
  ".//*[@id='tbl-h09-prep-key-output-identities']//tbody/tr"
))
table_captions <- trimws(xml2::xml_text(xml2::xml_find_all(
  main,
  paste0(
    ".//figcaption",
    "[contains(concat(' ', normalize-space(@class), ' '),",
    " ' quarto-float-tbl ')]"
  )
)))
figure_captions <- trimws(xml2::xml_text(xml2::xml_find_all(
  main,
  paste0(
    ".//figcaption",
    "[contains(concat(' ', normalize-space(@class), ' '),",
    " ' quarto-float-fig ')]"
  )
)))
figure_alts <- xml2::xml_attr(
  xml2::xml_find_all(
    main,
    ".//*[@id='fig-h09-prep-sample-support']//img"
  ),
  "alt"
)
html_text <- rawToChar(post_raw)
forbidden_html <- c(
  "Execution halted",
  "Quitting from lines",
  "Error in ",
  "Traceback",
  "WARNING: unresolved",
  "?@tbl-",
  "?@fig-",
  "?@sec-"
)
forbidden_present <- vapply(
  forbidden_html,
  grepl,
  logical(1),
  x = html_text,
  fixed = TRUE
)
privacy_patterns <- c(
  "participant_id[[:space:]]*=[[:space:]]*[A-Za-z0-9_-]+",
  "participant[-_ ]?[0-9]{3,}",
  "subject[-_ ]?[0-9]{3,}"
)
visible_text <- xml2::xml_text(main)
privacy_hits <- vapply(
  privacy_patterns,
  grepl,
  logical(1),
  x = visible_text,
  perl = TRUE,
  ignore.case = TRUE
)
stopifnot(
  identical(table_labels, expected_tables),
  identical(figure_labels, "fig-h09-prep-sample-support"),
  identical(html_table_endpoints, expected_tables),
  identical(html_figure_endpoints, "fig-h09-prep-sample-support"),
  length(mermaid_nodes) == 1L,
  manifest_rows == 6L,
  key_output_rows == 9L,
  length(table_captions) == 19L,
  all(nzchar(table_captions)),
  length(figure_captions) == 1L,
  nzchar(figure_captions),
  length(figure_alts) == 1L,
  !is.na(figure_alts),
  nzchar(figure_alts),
  !any(forbidden_present),
  !any(privacy_hits)
)
dom_audit <- tribble(
  ~check,
  ~observed,
  ~expected,
  ~status,
  "unique main",
  length(main),
  1L,
  "PASS",
  "duplicate document IDs",
  sum(duplicated(document_ids)),
  0L,
  "PASS",
  "native gt tables",
  length(tables),
  19L,
  "PASS",
  "table endpoints in source order",
  length(html_table_endpoints),
  19L,
  "PASS",
  "figure endpoints",
  length(html_figure_endpoints),
  1L,
  "PASS",
  "top-down Mermaid",
  length(mermaid_nodes),
  1L,
  "PASS",
  "manifest-check rows",
  manifest_rows,
  6L,
  "PASS",
  "key-output rows",
  key_output_rows,
  9L,
  "PASS",
  "nonempty table captions",
  sum(nzchar(table_captions)),
  19L,
  "PASS",
  "nonempty figure caption",
  sum(nzchar(figure_captions)),
  1L,
  "PASS",
  "nonempty figure alt text",
  sum(nzchar(figure_alts)),
  1L,
  "PASS",
  "embedded failure markers",
  sum(forbidden_present),
  0L,
  "PASS",
  "privacy identifier patterns",
  sum(privacy_hits),
  0L,
  "PASS"
)
add_check(
  "DOM",
  "endpoints, captions, alt text, clean HTML, and privacy",
  paste(
    length(tables),
    length(html_figure_endpoints),
    length(mermaid_nodes),
    sum(forbidden_present),
    sum(privacy_hits),
    sep = "/"
  ),
  "19/1/1/0/0",
  all(dom_audit$status == "PASS")
)

relative_matches <- gregexpr("\\]\\((\\.\\./[^)]+)\\)", qmd_text, perl = TRUE)
relative_values <- regmatches(qmd_text, relative_matches)[[1L]]
relative_targets <- sub("^\\]\\(", "", relative_values)
relative_targets <- sub("\\)$", "", relative_targets)
relative_files <- sub("#.*$", "", relative_targets)
source_link_exists <- file.exists(file.path(dirname(qmd_path), relative_files))
stopifnot(
  length(relative_targets) == 23L,
  length(unique(relative_targets)) == 22L,
  all(source_link_exists)
)

anchor_nodes <- xml2::xml_find_all(main, ".//a[@href]")
anchor_hrefs <- xml2::xml_attr(anchor_nodes, "href")
is_external <- grepl(
  "^(?:https?:|mailto:|tel:|data:|javascript:)",
  anchor_hrefs,
  perl = TRUE
)
is_internal_fragment <- startsWith(anchor_hrefs, "#")
local_hrefs <- anchor_hrefs[
  !is_external & !is_internal_fragment & nzchar(anchor_hrefs)
]
local_files <- sub("[?#].*$", "", local_hrefs)
local_fragments <- ifelse(
  grepl("#", local_hrefs, fixed = TRUE),
  sub("^[^#]*#", "", local_hrefs),
  ""
)
resolved_local_files <- normalizePath(
  file.path(dirname(html_path), utils::URLdecode(local_files)),
  winslash = "/",
  mustWork = FALSE
)
local_exists <- file.exists(resolved_local_files) &
  !dir.exists(resolved_local_files)
fragment_resolves <- rep(TRUE, length(local_hrefs))
for (i in which(nzchar(local_fragments) & local_exists)) {
  target_doc <- xml2::read_html(resolved_local_files[[i]])
  fragment_resolves[[i]] <- length(xml2::xml_find_all(
    target_doc,
    sprintf("//*[@id='%s']", utils::URLdecode(local_fragments[[i]]))
  )) ==
    1L
}
link_audit <- tibble(
  href = local_hrefs,
  resolved_path = relative_path(resolved_local_files),
  fragment = local_fragments,
  file_exists = local_exists,
  fragment_resolves = fragment_resolves,
  status = if_else(.data$file_exists & .data$fragment_resolves, "PASS", "FAIL")
)
stopifnot(nrow(link_audit) > 0L, all(link_audit$status == "PASS"))
add_check(
  "links",
  "source targets and rendered local links",
  paste(
    length(relative_targets),
    length(unique(relative_targets)),
    sum(link_audit$status == "PASS"),
    nrow(link_audit),
    sep = "/"
  ),
  paste0("23/22/", nrow(link_audit), "/", nrow(link_audit)),
  TRUE
)

source_replay_dir <- tempfile(
  "h09-order57c-source-replay.",
  tmpdir = "/private/tmp"
)
stopifnot(dir.create(source_replay_dir, recursive = TRUE))
source_replay_file <- file.path(source_replay_dir, "H09_analysis_preparation.R")
invisible(knitr::purl(
  qmd_path,
  output = source_replay_file,
  quiet = TRUE,
  documentation = 0L
))
invisible(parse(file = source_replay_file))
source_env <- new.env(parent = globalenv())
sys.source(source_replay_file, envir = source_env, chdir = FALSE)
manifest_audit <- get("manifest_audit", envir = source_env, inherits = FALSE)
manifest_check <- get("manifest_check", envir = source_env, inherits = FALSE)
sample_plot_data <- get(
  "sample_plot_data",
  envir = source_env,
  inherits = FALSE
)
execution <- get("execution", envir = source_env, inherits = FALSE)
stopifnot(
  nrow(manifest_audit) == 106L,
  sum(manifest_audit$Status == "LIVE_EXACT") == 87L,
  sum(manifest_audit$Status == "ACCEPTED_HISTORICAL_TO_LIVE") == 19L,
  !any(manifest_audit$Status == "FAIL"),
  nrow(manifest_check) == 6L,
  all(manifest_check$Status == "PASS"),
  nrow(sample_plot_data) == 40L,
  execution$r_version == "4.6.1"
)
source_replay_summary <- tibble(
  chunks = 22L,
  immutable_manifest_rows = nrow(manifest_audit),
  live_exact = sum(manifest_audit$Status == "LIVE_EXACT"),
  accepted_historical = sum(
    manifest_audit$Status == "ACCEPTED_HISTORICAL_TO_LIVE"
  ),
  manifest_checks = sum(manifest_check$Status == "PASS"),
  sample_plot_rows = nrow(sample_plot_data),
  r_version = as.character(getRversion()),
  status = "PASS"
)
add_check(
  "source replay",
  "all remaining executable companion logic",
  "22 chunks; 87+19 manifest; 6/6 checks; 40 figure rows",
  "PASS",
  TRUE
)

protected <- utils::read.csv(
  file.path(owner_dir, "protected_postrender_audit.csv"),
  check.names = FALSE
)
stopifnot(nrow(protected) == 545L, !anyDuplicated(protected$relative_path))
protected_files <- file.path(root, protected$relative_path)
protected_exists <- file.exists(protected_files) & !dir.exists(protected_files)
protected_sha <- rep(NA_character_, nrow(protected))
protected_bytes <- rep(NA_real_, nrow(protected))
protected_sha[protected_exists] <- vapply(
  protected_files[protected_exists],
  sha256_file,
  character(1)
)
protected_bytes[protected_exists] <- file_bytes(protected_files[
  protected_exists
])
protected_disposition <- case_when(
  protected_exists &
    protected_sha == protected$sha256 &
    protected_bytes == as.numeric(protected$bytes) ~
    "HISTORICAL_EXACT",
  !protected_exists &
    protected$relative_path %in%
      c(
        "audit/hypotheses/H09/H09_analysis_preparation.html",
        support_audit$relative_path
      ) ~
    "EXPECTED_CANONICAL_OUTPUT_CLEANUP",
  protected$relative_path ==
    "audit/hypotheses/H09/H09_analysis_preparation.qmd" &
    protected_sha ==
      current_pins$sha256[
        current_pins$path == "audit/hypotheses/H09/H09_analysis_preparation.qmd"
      ] ~
    "ACCEPTED_SOURCE_TRANSITION",
  protected$relative_path ==
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd" &
    protected_sha ==
      current_pins$sha256[
        current_pins$path ==
          "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd"
      ] ~
    "SOURCE_IDENTICAL_BUILD_QMD",
  protected$relative_path ==
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html" &
    protected_sha ==
      current_pins$sha256[
        current_pins$path ==
          "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html"
      ] ~
    "TARGET_HTML",
  protected$relative_path ==
    "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv" &
    protected_sha ==
      current_pins$sha256[
        current_pins$path ==
          "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv"
      ] ~
    "CURRENT_PREPARATION_MANIFEST",
  TRUE ~ "UNEXPECTED"
)
protected_transition <- protected |>
  mutate(
    observed_exists = protected_exists,
    observed_sha256 = protected_sha,
    observed_bytes = protected_bytes,
    independent_disposition = protected_disposition,
    status = if_else(
      .data$independent_disposition == "UNEXPECTED",
      "FAIL",
      "PASS"
    )
  )
stopifnot(
  sum(protected_disposition == "HISTORICAL_EXACT") == 524L,
  sum(protected_disposition == "EXPECTED_CANONICAL_OUTPUT_CLEANUP") == 17L,
  sum(
    protected_disposition %in%
      c(
        "ACCEPTED_SOURCE_TRANSITION",
        "SOURCE_IDENTICAL_BUILD_QMD",
        "TARGET_HTML",
        "CURRENT_PREPARATION_MANIFEST"
      )
  ) ==
    4L,
  all(protected_transition$status == "PASS")
)
add_check(
  "protected",
  "historical, canonical-cleanup, and accepted live transitions",
  "524 exact/17 cleanup/4 accepted transitions",
  "545/545 classified",
  TRUE
)

historical_test <- paste(
  readLines(
    file.path(root, "tests/hypotheses/H09/test_h09_preparation_report.R"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
result_source <- paste(
  readLines(file.path(root, "notebooks/hypotheses/H09.qmd"), warn = FALSE),
  collapse = "\n"
)
profile <- paste(
  readLines(file.path(root, "_quarto-nathealth.yml"), warn = FALSE),
  collapse = "\n"
)
historical_test_classifications <- c(
  companion_html_literal = grepl(
    "../../../notebooks/hypotheses/H09.html",
    historical_test,
    fixed = TRUE
  ) &&
    !grepl("../../../notebooks/hypotheses/H09.html", qmd_text, fixed = TRUE),
  reciprocal_html_literal = grepl(
    "../../audit/hypotheses/H09/H09_analysis_preparation.html",
    historical_test,
    fixed = TRUE
  ) &&
    !grepl(
      "../../audit/hypotheses/H09/H09_analysis_preparation.html",
      result_source,
      fixed = TRUE
    ),
  profile_absence = grepl(
    "stopifnot(!grepl(prep_profile_path, profile, fixed = TRUE))",
    historical_test,
    fixed = TRUE
  ) &&
    grepl(
      "- audit/hypotheses/H09/H09_analysis_preparation.qmd",
      profile,
      fixed = TRUE
    )
)
stopifnot(all(historical_test_classifications))
add_check(
  "historical test",
  "three REPORT-018 stale literal classifications",
  paste0(sum(historical_test_classifications), "/3"),
  "3/3; test remains byte-identical and deferred",
  TRUE
)

stopifnot(all(checks$status == "PASS"))

utils::write.csv(
  owner_audit,
  paste0(output_prefix, "_owner_manifest_audit.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  manifest_transition,
  paste0(output_prefix, "_manifest_transition_audit.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  source_cleanup_audit,
  paste0(output_prefix, "_canonical_cleanup_audit.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  build_delta,
  paste0(output_prefix, "_build_transition_audit.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  semantic_transition,
  paste0(output_prefix, "_semantic_transition_audit.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  header_token_audit,
  paste0(output_prefix, "_semantic_header_token_audit.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  dom_audit,
  paste0(output_prefix, "_dom_contract_audit.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  link_audit,
  paste0(output_prefix, "_link_audit.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  source_replay_summary,
  paste0(output_prefix, "_source_replay_summary.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  protected_transition,
  paste0(output_prefix, "_protected_transition_audit.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  checks,
  paste0(output_prefix, "_verification.csv"),
  row.names = FALSE,
  na = ""
)

cat(sprintf(
  paste0(
    "REPORT018_H09_ORDER57C_RENDERED_STOP=PASS owner=63/63 manifest=553/553 ",
    "transition=537+17+16 build=851->871+20 semantics=19/102/591/693 ",
    "headers=%d endpoints=19/1/1 links=%d/%d source=22+87+19 ",
    "protected=524+17+4 historical_test=3/3 R=%s\n"
  ),
  nrow(header_token_audit),
  sum(link_audit$status == "PASS"),
  nrow(link_audit),
  as.character(getRversion())
))
