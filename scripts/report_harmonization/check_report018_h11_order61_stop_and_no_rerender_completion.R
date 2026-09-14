#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

output_dir <- Sys.getenv(
  "H11_ORDER61_REVIEW_DIR",
  unset = file.path(
    root,
    paste0(
      "audit/report_harmonization/",
      "report018_h11_order61_stop_and_no_rerender_replay"
    )
  )
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)

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

owner_dir <- paste0(
  "audit/hypotheses/H11/",
  "report018_order61_companion_render"
)
owner_manifest_path <- file.path(
  owner_dir,
  "order61_fail_closed_non_circular_manifest.csv"
)
owner_manifest <- readr::read_csv(owner_manifest_path, show_col_types = FALSE)
owner_exists <- file.exists(owner_manifest$path) &
  !dir.exists(owner_manifest$path)
owner_live_sha <- rep(NA_character_, nrow(owner_manifest))
owner_live_bytes <- rep(NA_real_, nrow(owner_manifest))
owner_live_sha[owner_exists] <- vapply(
  owner_manifest$path[owner_exists],
  sha256_file,
  character(1)
)
owner_live_bytes[owner_exists] <- unname(
  as.numeric(file.info(owner_manifest$path[owner_exists])$size)
)
owner_exact <- owner_exists &
  owner_live_sha == owner_manifest$sha256 &
  owner_live_bytes == as.numeric(owner_manifest$bytes)
owner_audit <- data.frame(
  path = owner_manifest$path,
  role = owner_manifest$role,
  sealed_sha256 = owner_manifest$sha256,
  live_sha256 = owner_live_sha,
  sealed_bytes = owner_manifest$bytes,
  live_bytes = owner_live_bytes,
  exact = owner_exact,
  stringsAsFactors = FALSE
)
readr::write_csv(owner_audit, file.path(output_dir, "owner_manifest_audit.csv"))
owner_pass <- nrow(owner_manifest) == 44L &&
  !anyDuplicated(owner_manifest$path) &&
  !owner_manifest_path %in% owner_manifest$path &&
  all(owner_exact)
add_check(
  "Order 61 stop",
  "owner_non_circular_manifest",
  owner_pass,
  sprintf("exact=%d/%d", sum(owner_exact), nrow(owner_manifest))
)

fixed <- data.frame(
  path = c(
    file.path(owner_dir, "order61_rendered_test_failure.md"),
    owner_manifest_path,
    "notebooks/hypotheses/H11.qmd",
    "_build/nathealth/notebooks/hypotheses/H11.html",
    "audit/hypotheses/H11/H11_analysis_preparation.qmd",
    paste0(
      "_build/nathealth/audit/hypotheses/H11/",
      "H11_analysis_preparation.qmd"
    ),
    paste0(
      "_build/nathealth/audit/hypotheses/H11/",
      "H11_analysis_preparation.html"
    ),
    "tests/hypotheses/H11/test_h11_preparation_report.R",
    "scripts/hypotheses/H11/build_h11_preparation_report_manifest.R",
    "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
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
  sha256 = c(
    "5b6e5f73386a0f99160e2b1c857dfd174a02101d79d2d7efc2fed440675428d3",
    "bcacb72f9fc9796c346546081b8bdf306a4ef80079fadb606d96306bc3ad559c",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
    "2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "58518d708e4feb6145bd8eb773b6b9ae4937afdf4a9e44e19d4215d9ca86162c",
    "4c31cb4120fdb0530609906df707c161b875c0859a917de61f3baa1050d24180",
    "317f31069e6019475023b3097b1d7f1b00435755e0a109e40535fab89b570bf8",
    "3dbd92632afd32d392ef7ed456dc6f61d32e58ec73b03bd8d8e3451dfcb1afe8",
    "6afff45a29a0bb96a49dbf46e611fce15dfd1618b4699da40d4b1f15cdbed026",
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
fixed$exists <- file.exists(fixed$path) & !dir.exists(fixed$path)
fixed$live_sha256 <- NA_character_
fixed$live_sha256[fixed$exists] <- vapply(
  fixed$path[fixed$exists],
  sha256_file,
  character(1)
)
fixed$exact <- fixed$exists & fixed$live_sha256 == fixed$sha256
readr::write_csv(fixed, file.path(output_dir, "fixed_identity_audit.csv"))
add_check(
  "Order 61 stop",
  "rendered_and_held_identities",
  all(fixed$exact),
  sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed))
)

manifest_path <- "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv"
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
manifest_files <- manifest$path
manifest_live_sha <- vapply(manifest_files, sha256_file, character(1))
manifest_live_bytes <- unname(as.numeric(file.info(manifest_files)$size))
manifest_exact <- manifest_live_sha == manifest$sha256 &
  manifest_live_bytes == as.numeric(manifest$bytes)
manifest_audit <- data.frame(
  path = manifest$path,
  role = manifest$role,
  sealed_sha256 = manifest$sha256,
  live_sha256 = manifest_live_sha,
  sealed_bytes = manifest$bytes,
  live_bytes = manifest_live_bytes,
  exact = manifest_exact,
  stringsAsFactors = FALSE
)
readr::write_csv(
  manifest_audit,
  file.path(output_dir, "preparation_manifest_live_audit.csv")
)
manifest_pass <- nrow(manifest) == 283L &&
  !anyDuplicated(manifest$path) &&
  all(manifest_exact) &&
  sum(
    manifest$path ==
      "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R"
  ) ==
    1L
add_check(
  "Order 61 stop",
  "truthful_283_row_manifest",
  manifest_pass,
  sprintf("exact=%d/%d", sum(manifest_exact), nrow(manifest))
)

# Exact semantic reversal and reapplication.
semantic_summary <- readr::read_csv(
  file.path(owner_dir, "gt_html_semantic_post_render_summary.csv"),
  show_col_types = FALSE
)
semantic_ledger <- readr::read_csv(
  file.path(owner_dir, "H11_gt_semantic_ledger.csv"),
  show_col_types = FALSE
)
post_raw <- read_raw_file(
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html"
)
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
  semantic_summary$disposition == "REPAIRED" &&
  semantic_summary$table_count == 26L &&
  semantic_summary$id_count == 179L &&
  semantic_summary$headers_count == 801L &&
  semantic_summary$total_substitutions == 980L &&
  semantic_summary$pre_sha256 == sha256_raw(pre_raw) &&
  semantic_summary$post_sha256 == sha256_raw(post_raw) &&
  nrow(semantic_ledger) == 980L &&
  identical(reapplied_raw, post_raw)
add_check(
  "Order 61 stop",
  "semantic_reverse_and_reapply",
  semantic_pass,
  sprintf(
    "tables=%d ids=%d headers=%d substitutions=%d",
    semantic_summary$table_count,
    semantic_summary$id_count,
    semantic_summary$headers_count,
    semantic_summary$total_substitutions
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
mermaid <- xml2::xml_find_all(
  main,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
ids <- xml2::xml_attr(xml2::xml_find_all(document, ".//*[@id]"), "id")
ids <- ids[!is.na(ids) & nzchar(ids)]
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
readr::write_csv(
  header_audit,
  file.path(output_dir, "table_header_resolution_audit.csv")
)
rendered_result_href <- "../../../notebooks/hypotheses/H11.html"
rendered_result_links <- xml2::xml_find_all(
  main,
  paste0(".//a[contains(@href, '", rendered_result_href, "')]")
)
dom_pass <- length(gt_tables) == 26L &&
  length(images) == 3L &&
  all(nzchar(xml2::xml_attr(images, "alt"))) &&
  length(mermaid) == 1L &&
  !anyDuplicated(ids) &&
  nrow(header_audit) == 1193L &&
  all(header_audit$resolves == 1L) &&
  length(rendered_result_links) >= 1L &&
  length(xml2::xml_find_all(main, ".//*[contains(@class, 'error')]")) == 0L &&
  length(xml2::xml_find_all(main, ".//*[contains(@class, 'warning')]")) == 0L
add_check(
  "Order 61 stop",
  "fresh_companion_dom",
  dom_pass,
  sprintf(
    "tables=%d images=%d mermaid=%d headers=%d result_links=%d",
    length(gt_tables),
    length(images),
    length(mermaid),
    nrow(header_audit),
    length(rendered_result_links)
  )
)

# Classify the shared generic source-link assumption without changing it.
companion_sources <- list.files(
  "audit/hypotheses",
  pattern = "^H[0-9]{2}_analysis_preparation\\.qmd$",
  recursive = TRUE,
  full.names = TRUE
)
companion_sources <- companion_sources[
  grepl("/H[0-9]{2}/H[0-9]{2}_analysis_preparation\\.qmd$", companion_sources)
]
source_link_rows <- lapply(companion_sources, function(path) {
  hypothesis_id <- basename(dirname(path))
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  qmd_target <- paste0(
    "../../../notebooks/hypotheses/",
    hypothesis_id,
    ".qmd"
  )
  html_target <- paste0(
    "../../../notebooks/hypotheses/",
    hypothesis_id,
    ".html"
  )
  data.frame(
    hypothesis_id = hypothesis_id,
    path = path,
    qmd_occurrences = length(grep(
      qmd_target,
      strsplit(text, "\n")[[1L]],
      fixed = TRUE
    )),
    html_occurrences = length(grep(
      html_target,
      strsplit(text, "\n")[[1L]],
      fixed = TRUE
    )),
    stringsAsFactors = FALSE
  )
})
source_link_audit <- do.call(rbind, source_link_rows)
readr::write_csv(
  source_link_audit,
  file.path(output_dir, "shared_source_link_convention_audit.csv")
)
shared_text <- paste(
  readLines(
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
    warn = FALSE
  ),
  collapse = "\n"
)
shared_classification_pass <- nrow(source_link_audit) == 11L &&
  all(source_link_audit$qmd_occurrences >= 1L) &&
  all(source_link_audit$html_occurrences == 0L) &&
  grepl(
    'result_href <- paste0(\n    "../../../notebooks/hypotheses/",\n    hypothesis_id,\n    ".html"',
    shared_text,
    fixed = TRUE
  )
add_check(
  "Order 61 stop",
  "shared_contract_inconsistency_classified",
  shared_classification_pass,
  sprintf(
    "sources=%d qmd=%d html=%d shared_fixed=%s",
    nrow(source_link_audit),
    sum(source_link_audit$qmd_occurrences),
    sum(source_link_audit$html_occurrences),
    sha256_file("scripts/pipeline/hypothesis_preparation_provenance_contract.R")
  )
)

# Build the exact H11-local test-only correction. It preserves the shared
# function and replaces only the final generic call with strict H11-local
# checks using the already loaded source, DOM, manifest, and profile objects.
test_path <- "tests/hypotheses/H11/test_h11_preparation_report.R"
test_lines <- readLines(test_path, warn = FALSE, encoding = "UTF-8")
verification_start <- which(
  trimws(test_lines) ==
    "verification <- verify_hypothesis_preparation_companion("
)
stopifnot(length(verification_start) == 1L)
verification_end_candidates <- which(
  seq_along(test_lines) > verification_start & test_lines == "  )"
)
verification_end <- verification_end_candidates[[1L]]
original_block <- test_lines[verification_start:verification_end]
replacement_block <- c(
  '  rendered_result_href <- "../../../notebooks/hypotheses/H11.html"',
  "  rendered_result_links <- xml2::xml_find_all(",
  "    main,",
  "    paste0(\".//a[contains(@href, '\", rendered_result_href, \"')]\")",
  "  )",
  "  note_callouts <- xml2::xml_find_all(",
  "    main,",
  paste0(
    '    ".//*[contains(concat(\' \', normalize-space(@class), ',
    '\' \'), \' callout-note \')]"'
  ),
  "  )",
  "  warning_callouts <- xml2::xml_find_all(",
  "    main,",
  paste0(
    '    ".//*[contains(@class, \'callout-important\') or ',
    'contains(@class, \'callout-warning\') or ',
    'contains(@class, \'callout-caution\') or ',
    'contains(@class, \'callout-danger\')]"'
  ),
  "  )",
  '  result_path <- "notebooks/hypotheses/H11.qmd"',
  paste0(
    '  prep_path <- ',
    '"audit/hypotheses/H11/H11_analysis_preparation.qmd"'
  ),
  "  assert_adjacent_profile_entries(profile_lines, result_path, prep_path)",
  "  required_manifest_paths <- c(",
  "    prep_path,",
  paste0(
    '    "_build/nathealth/audit/hypotheses/H11/',
    'H11_analysis_preparation.qmd",'
  ),
  paste0(
    '    "_build/nathealth/audit/hypotheses/H11/',
    'H11_analysis_preparation.html",'
  ),
  '    "_quarto-nathealth.yml"',
  "  )",
  "  stopifnot(",
  "    length(rendered_result_links) >= 1L,",
  "    length(note_callouts) >= 1L,",
  "    length(warning_callouts) == 0L,",
  "    all(required_manifest_paths %in% manifest$path),",
  paste0(
    '    any(startsWith(manifest$path, ',
    '"scripts/hypotheses/H11/")),'
  ),
  paste0(
    '    any(startsWith(manifest$path, ',
    '"artifacts/11_source_data/H11/"))'
  ),
  "  )",
  "  verification <- data.frame(",
  '    hypothesis_id = "H11",',
  "    figures = length(images),",
  "    gt_tables = length(gt_tables),",
  "    manifest_identities = nrow(manifest),",
  "    executable_r_calls = length(calls),",
  "    source_copy_identical = identical(",
  "      read_file_bytes(paths$qmd),",
  "      read_file_bytes(paths$rendered_qmd)",
  "    ),",
  "    stringsAsFactors = FALSE",
  "  )"
)
prospective_lines <- c(
  test_lines[seq_len(verification_start - 1L)],
  replacement_block,
  test_lines[(verification_end + 1L):length(test_lines)]
)
prospective_text <- paste0(paste(prospective_lines, collapse = "\n"), "\n")
prospective_raw <- charToRaw(enc2utf8(prospective_text))
prospective_sha <- sha256_raw(prospective_raw)
prospective_bytes <- length(prospective_raw)
reversed_lines <- c(
  prospective_lines[seq_len(verification_start - 1L)],
  original_block,
  prospective_lines[
    (verification_start + length(replacement_block)):length(prospective_lines)
  ]
)
reverse_raw <- charToRaw(enc2utf8(paste0(
  paste(reversed_lines, collapse = "\n"),
  "\n"
)))
reverse_pass <- identical(reverse_raw, read_raw_file(test_path))

prospective_manifest <- manifest
test_row <- prospective_manifest$path == test_path
stopifnot(sum(test_row) == 1L)
prospective_manifest$sha256[test_row] <- prospective_sha
prospective_manifest$bytes[test_row] <- prospective_bytes
prospective_manifest_path <- tempfile(
  "h11-order61-prospective-manifest-",
  tmpdir = "/private/tmp",
  fileext = ".csv"
)
readr::write_csv(prospective_manifest, prospective_manifest_path)
prospective_manifest_sha <- sha256_file(prospective_manifest_path)
prospective_manifest_bytes <- file_bytes(prospective_manifest_path)

# The read-only replay executes a temporary copy of the prospective test while
# the project-owned test remains at its sealed preimage. Use a second temporary
# manifest with the current self-row so the existing live-identity gate remains
# truthful during that replay. The separately sealed prospective manifest above
# records the one direct row transition that the owner would apply.
execution_manifest_path <- tempfile(
  "h11-order61-execution-manifest-",
  tmpdir = "/private/tmp",
  fileext = ".csv"
)
readr::write_csv(manifest, execution_manifest_path)

run_lines <- prospective_lines
paths_index <- which(
  trimws(run_lines) == 'paths <- preparation_companion_paths(root, "H11")'
)
stopifnot(length(paths_index) == 1L)
run_lines <- append(
  run_lines,
  'paths$manifest <- Sys.getenv("H11_PROSPECTIVE_MANIFEST")',
  after = paths_index
)
prospective_test_path <- tempfile(
  "test-h11-order61-no-rerender-",
  tmpdir = "/private/tmp",
  fileext = ".R"
)
writeLines(run_lines, prospective_test_path, useBytes = TRUE)
prospective_output <- suppressWarnings(
  system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(prospective_test_path)),
    stdout = TRUE,
    stderr = TRUE,
    env = c(
      "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
      paste0("NATHEALTH_PROJECT_ROOT=", root),
      paste0("H11_PROSPECTIVE_MANIFEST=", execution_manifest_path)
    )
  )
)
prospective_status <- attr(prospective_output, "status")
if (is.null(prospective_status)) prospective_status <- 0L
writeLines(
  enc2utf8(prospective_output),
  file.path(output_dir, "prospective_preparation_test_output.txt"),
  useBytes = TRUE
)
prospective_contract <- data.frame(
  check = c(
    "current_test_preimage",
    "prospective_test_postimage",
    "exact_raw_reverse",
    "R_parse",
    "shared_contract_unchanged",
    "prospective_manifest_283",
    "prospective_manifest_one_row_transition",
    "complete_test_exit_zero"
  ),
  pass = c(
    identical(
      sha256_file(test_path),
      "4c31cb4120fdb0530609906df707c161b875c0859a917de61f3baa1050d24180"
    ),
    nchar(prospective_sha) == 64L && prospective_bytes > file_bytes(test_path),
    reverse_pass,
    is.expression(parse(text = prospective_text)),
    identical(
      sha256_file(
        "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
      ),
      "6afff45a29a0bb96a49dbf46e611fce15dfd1618b4699da40d4b1f15cdbed026"
    ),
    nrow(prospective_manifest) == 283L &&
      !anyDuplicated(prospective_manifest$path),
    sum(
      prospective_manifest$sha256 != manifest$sha256 |
        prospective_manifest$bytes != manifest$bytes
    ) ==
      1L,
    prospective_status == 0L
  ),
  detail = c(
    sha256_file(test_path),
    paste0(prospective_sha, " / ", prospective_bytes),
    sha256_raw(reverse_raw),
    as.character(getRversion()),
    sha256_file(
      "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
    ),
    paste0("rows=", nrow(prospective_manifest)),
    test_path,
    paste0("status=", prospective_status)
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(
  prospective_contract,
  file.path(output_dir, "prospective_no_rerender_contract.csv")
)
readr::write_csv(
  data.frame(
    path = c(test_path, manifest_path),
    pre_sha256 = c(sha256_file(test_path), sha256_file(manifest_path)),
    post_sha256 = c(prospective_sha, prospective_manifest_sha),
    pre_bytes = c(file_bytes(test_path), file_bytes(manifest_path)),
    post_bytes = c(prospective_bytes, prospective_manifest_bytes),
    stringsAsFactors = FALSE
  ),
  file.path(output_dir, "prospective_direct_transitions.csv")
)
add_check(
  "No-rerender continuation",
  "prospective_local_test_and_manifest",
  all(prospective_contract$pass),
  sprintf(
    "test=%s/%d manifest=%s/%d status=%d",
    prospective_sha,
    prospective_bytes,
    prospective_manifest_sha,
    prospective_manifest_bytes,
    prospective_status
  )
)

science_same <- identical(
  read_raw_file(file.path(owner_dir, "scientific_inventory_prerender.csv")),
  read_raw_file(file.path(owner_dir, "scientific_inventory_postfailure.csv"))
)
sass_same <- identical(
  read_raw_file(file.path(owner_dir, "sass_cache_inventory_prerender.csv")),
  read_raw_file(file.path(owner_dir, "sass_cache_inventory_postfailure.csv"))
)
process_status <- readr::read_csv(
  file.path(owner_dir, "server_lifecycle.csv"),
  show_col_types = FALSE
)
preservation_pass <- science_same &&
  sass_same &&
  sum(process_status$event == "final_process_inventory") == 1L &&
  process_status$status[process_status$event == "final_process_inventory"] ==
    "PASS"
add_check(
  "Order 61 stop",
  "science_cache_and_process_preservation",
  preservation_pass,
  sprintf(
    "science_same=%s sass_same=%s lifecycle_rows=%d",
    science_same,
    sass_same,
    nrow(process_status)
  )
)

checks_frame <- do.call(rbind, checks)
readr::write_csv(
  checks_frame,
  file.path(output_dir, "order61_stop_and_no_rerender_checks.csv")
)
if (!all(checks_frame$pass)) {
  failed <- checks_frame[!checks_frame$pass, , drop = FALSE]
  stop(
    "H11 Order 61 review failed: ",
    paste(failed$check_id, collapse = ", "),
    call. = FALSE
  )
}

message(sprintf(
  paste0(
    "REPORT018_H11_ORDER61_REVIEW=PASS checks=%d owner=44/44 ",
    "manifest=283/283 semantic=26+179+801 test=%s/%d ",
    "manifest_post=%s/%d prospective_test=PASS R=%s"
  ),
  nrow(checks_frame),
  prospective_sha,
  prospective_bytes,
  prospective_manifest_sha,
  prospective_manifest_bytes,
  as.character(getRversion())
))
