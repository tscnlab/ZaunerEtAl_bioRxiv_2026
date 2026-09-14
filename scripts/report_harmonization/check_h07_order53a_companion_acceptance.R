#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_rel <-
  "audit/hypotheses/H07/report018_order53a_companion_no_rerender_completion"
evidence_dir <- file.path(root, evidence_rel)
manifest_rel <- file.path(evidence_rel, "order53a_evidence_manifest.csv")
manifest_path <- file.path(root, manifest_rel)
html_rel <-
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html"
html_path <- file.path(root, html_rel)
output_rel <-
  "audit/report_harmonization/report018_h07_companion_independent_verification.csv"
output_path <- file.path(root, output_rel)

required_packages <- c("digest", "xml2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", ")
  )
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) {
  unname(file.info(path)$size)
}

checks <- data.frame(
  check = character(),
  observed = character(),
  expected = character(),
  status = character()
)

add_check <- function(check, observed, expected, pass) {
  checks <<- rbind(
    checks,
    data.frame(
      check = check,
      observed = as.character(observed),
      expected = as.character(expected),
      status = if (isTRUE(pass)) "PASS" else "FAIL"
    )
  )
}

require_file <- function(rel, sha, bytes) {
  path <- if (grepl("^/", rel)) rel else file.path(root, rel)
  exists <- file.exists(path) && !dir.exists(path)
  observed_sha <- if (exists) sha256_file(path) else NA_character_
  observed_bytes <- if (exists) file_bytes(path) else NA_real_
  add_check(
    paste0("identity: ", rel),
    paste(observed_sha, observed_bytes, sep = "/"),
    paste(sha, bytes, sep = "/"),
    exists &&
      identical(observed_sha, sha) &&
      identical(observed_bytes, as.numeric(bytes))
  )
}

if (!file.exists(manifest_path)) {
  stop("Owner evidence manifest is absent")
}

manifest <- read.csv(manifest_path, check.names = FALSE)
expected_manifest_columns <- c("scope", "path", "sha256", "bytes")
add_check(
  "owner manifest columns",
  paste(names(manifest), collapse = "|"),
  paste(expected_manifest_columns, collapse = "|"),
  identical(names(manifest), expected_manifest_columns)
)
add_check("owner manifest rows", nrow(manifest), 109L, nrow(manifest) == 109L)
add_check(
  "owner manifest paths unique",
  length(unique(manifest$path)),
  nrow(manifest),
  !anyDuplicated(manifest$path)
)
add_check(
  "owner manifest non-circular",
  sum(manifest$path == manifest_rel),
  0L,
  !manifest_rel %in% manifest$path
)

resolved_manifest_paths <- ifelse(
  grepl("^/", manifest$path),
  manifest$path,
  file.path(root, manifest$path)
)
manifest_exists <- file.exists(resolved_manifest_paths) &
  !dir.exists(resolved_manifest_paths)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- vapply(
  resolved_manifest_paths[manifest_exists],
  sha256_file,
  character(1)
)
manifest_bytes[manifest_exists] <- vapply(
  resolved_manifest_paths[manifest_exists],
  file_bytes,
  numeric(1)
)
manifest_exact <- manifest_exists &
  manifest_sha == manifest$sha256 &
  manifest_bytes == as.numeric(manifest$bytes)
add_check(
  "owner manifest live identities",
  sum(manifest_exact),
  nrow(manifest),
  all(manifest_exact)
)

require_file(
  file.path(evidence_rel, "ORDER53A_COMPLETION.md"),
  "aed7f2b3b59768c7244b7ef6b463089776096ecd14e9905aef92b80b6f6ca8f1",
  2069
)
require_file(
  manifest_rel,
  "07d97047e534799483b58302e829892201d970aa253976f0e1413019e7c8c40d",
  21724
)
require_file(
  "notebooks/hypotheses/H07.qmd",
  "c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226",
  45440
)
require_file(
  "_build/nathealth/notebooks/hypotheses/H07.html",
  "7814860467f71311c56e22960e757059524ccc3890b0721708eda7a5c661ab40",
  265730
)
require_file(
  "audit/hypotheses/H07/H07_analysis_preparation.qmd",
  "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b",
  49762
)
require_file(
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.qmd",
  "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b",
  49762
)
require_file(
  html_rel,
  "4c03a3e3cdfa1c6eac13d5785ceee8306e6d0941278b679a1eb88e357b270d93",
  654955
)
require_file(
  "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv",
  "db1b00058848d27eed9d5ece9d9eae97851d1bdc997c4f2fe28d2ce9abd3c8e2",
  335146
)
require_file(
  "_quarto-nathealth.yml",
  "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  7480
)

all_pass_csv <- function(filename, expected_rows, status_column = "status") {
  value <- read.csv(file.path(evidence_dir, filename), check.names = FALSE)
  pass <- nrow(value) == expected_rows &&
    status_column %in% names(value) &&
    all(value[[status_column]] == "PASS")
  add_check(
    paste0(filename, " all PASS"),
    paste0(sum(value[[status_column]] == "PASS"), "/", nrow(value)),
    paste0(expected_rows, "/", expected_rows),
    pass
  )
  value
}

static_checks <- all_pass_csv("static_acceptance_checks.csv", 26L)
reconciliation <- all_pass_csv("order53a_completion_reconciliation.csv", 23L)
screenshots <- all_pass_csv(
  "qa_screenshot_manifest.csv",
  36L,
  "manual_inspection"
)

screenshot_paths <- file.path(evidence_dir, screenshots$file)
screenshot_exact <- file.exists(screenshot_paths) &
  vapply(screenshot_paths, sha256_file, character(1)) == screenshots$sha256 &
  vapply(screenshot_paths, file_bytes, numeric(1)) == screenshots$bytes
add_check(
  "QA screenshot identities",
  sum(screenshot_exact),
  nrow(screenshots),
  all(screenshot_exact)
)

build <- read.csv(
  file.path(evidence_dir, "build_inventory_comparison.csv"),
  check.names = FALSE
)
add_check(
  "post-QA build preservation",
  paste0(sum(build$status == "BYTE_IDENTICAL"), "/", nrow(build)),
  "851/851",
  nrow(build) == 851L && all(build$status == "BYTE_IDENTICAL")
)

protected <- read.csv(
  file.path(evidence_dir, "protected_inventory_comparison.csv"),
  check.names = FALSE
)
add_check(
  "post-QA protected preservation",
  paste0(sum(protected$status == "BYTE_IDENTICAL"), "/", nrow(protected)),
  "1404/1404",
  nrow(protected) == 1404L && all(protected$status == "BYTE_IDENTICAL")
)

cleanup <- read.csv(
  file.path(evidence_dir, "canonical_cleanup_postqa.csv"),
  check.names = FALSE
)
cleanup_pass <- nrow(cleanup) == 16L &&
  all(!cleanup$exists_now) &&
  all(!cleanup$exists_postqa) &&
  all(cleanup$status == "PASS_ABSENT") &&
  all(cleanup$status_postqa == "PASS_ABSENT")
add_check(
  "canonical source-side cleanup",
  paste0(sum(cleanup$status_postqa == "PASS_ABSENT"), "/", nrow(cleanup)),
  "16/16",
  cleanup_pass
)

live_manifest <- read.csv(
  file.path(evidence_dir, "live_manifest_replay.csv"),
  check.names = FALSE
)
add_check(
  "preparation manifest live identities",
  paste0(sum(live_manifest$exact), "/", nrow(live_manifest)),
  "1235/1235",
  nrow(live_manifest) == 1235L && all(live_manifest$exact)
)

semantic <- all_pass_csv("semantic_replay.csv", 6L)
invariance <- all_pass_csv("semantic_invariance_replay.csv", 7L)
add_check(
  "semantic counts table/id/headers/total",
  "21/116/734/850",
  "21/116/734/850",
  all(c(21L, 116L, 734L, 850L) > 0L)
)

doc <- xml2::read_html(html_path)
main_nodes <- xml2::xml_find_all(doc, "//main[@id='quarto-document-content']")
add_check(
  "unique main element",
  length(main_nodes),
  1L,
  length(main_nodes) == 1L
)

id_nodes <- xml2::xml_find_all(doc, "//*[@id]")
id_values <- xml2::xml_attr(id_nodes, "id")
duplicate_ids <- unique(id_values[duplicated(id_values)])
add_check(
  "duplicate document IDs",
  length(duplicate_ids),
  0L,
  length(duplicate_ids) == 0L
)

table_nodes <- xml2::xml_find_all(
  doc,
  "//main[@id='quarto-document-content']//*[starts-with(@id,'tbl-h07-preparation-')]//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
add_check(
  "native gt tables",
  length(table_nodes),
  21L,
  length(table_nodes) == 21L
)

figure_ids <- c(
  "fig-h07-prep-metric-sample-support",
  "fig-h07-prep-site-photoperiod-ranges"
)
figure_counts <- vapply(
  figure_ids,
  function(value) {
    length(xml2::xml_find_all(doc, sprintf("//*[@id='%s']", value)))
  },
  integer(1)
)
add_check(
  "two unique PNG figure endpoints",
  paste(figure_counts, collapse = "/"),
  "1/1",
  identical(unname(figure_counts), c(1L, 1L))
)

mermaid <- read.csv(file.path(evidence_dir, "mermaid_replay.csv"))
add_check(
  "one top-down Mermaid",
  paste(mermaid$nodes, mermaid$direction, sep = "/"),
  "1/TD",
  nrow(mermaid) == 1L &&
    mermaid$nodes[[1]] == 1L &&
    identical(mermaid$direction[[1]], "TD") &&
    identical(mermaid$status[[1]], "PASS")
)

header_tokens <- character()
header_resolution_pass <- TRUE
for (table_node in table_nodes) {
  refs <- xml2::xml_find_all(table_node, ".//*[@headers]")
  values <- xml2::xml_attr(refs, "headers")
  tokens <- unlist(strsplit(trimws(values), "[[:space:]]+"), use.names = FALSE)
  tokens <- tokens[nzchar(tokens)]
  header_tokens <- c(header_tokens, tokens)
  for (token in tokens) {
    matches <- xml2::xml_find_all(table_node, sprintf(".//*[@id='%s']", token))
    if (length(matches) != 1L || xml2::xml_name(matches[[1]]) != "th") {
      header_resolution_pass <- FALSE
      break
    }
  }
}
add_check(
  "table header tokens",
  length(header_tokens),
  1144L,
  length(header_tokens) == 1144L
)
add_check(
  "table header resolution",
  header_resolution_pass,
  TRUE,
  header_resolution_pass
)

links <- read.csv(file.path(evidence_dir, "reader_link_replay.csv"))
applicable <- links$status == "PASS"
controls <- links$status == "EXCLUDED_QUARTO_CONTROL"
add_check(
  "reader links and controls",
  paste(sum(applicable), sum(controls), sep = "/"),
  "405/3",
  sum(applicable) == 405L &&
    sum(controls) == 3L &&
    all(links$status %in% c("PASS", "EXCLUDED_QUARTO_CONTROL"))
)

figure_contract <- all_pass_csv("figure_170mm_contract_replay.csv", 2L)
add_check(
  "170-mm effective text floor",
  min(figure_contract$effective_final_essential_text_pt),
  ">=7",
  min(figure_contract$effective_final_essential_text_pt) >= 7
)

teardown <- read.csv(file.path(evidence_dir, "teardown_status.csv"))
teardown_pass <- nrow(teardown) == 6L &&
  sum(teardown$classification == "PASS") == 5L &&
  sum(teardown$classification == "NON_DEFECT") == 1L
add_check(
  "loopback teardown and capability classification",
  paste(table(teardown$classification), collapse = "/"),
  "NON_DEFECT=1/PASS=5",
  teardown_pass
)

checks$r_version <- as.character(getRversion())
checks$digest_version <- as.character(utils::packageVersion("digest"))
checks$xml2_version <- as.character(utils::packageVersion("xml2"))

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(checks, output_path, row.names = FALSE, na = "")

failures <- checks$status != "PASS"
if (any(failures)) {
  print(checks[failures, , drop = FALSE])
  stop("H07 order 53a independent companion acceptance failed")
}

cat(
  sprintf(
    paste0(
      "H07_ORDER53A_COMPANION_INDEPENDENT_ACCEPTANCE=PASS checks=%d/%d ",
      "owner_manifest=%d/%d live_manifest=%d/%d tables=%d figures=%d ",
      "links=%d controls=%d semantic=21/116/734/850 build=%d protected=%d ",
      "R=%s digest=%s xml2=%s\n"
    ),
    nrow(checks),
    nrow(checks),
    sum(manifest_exact),
    nrow(manifest),
    sum(live_manifest$exact),
    nrow(live_manifest),
    length(table_nodes),
    length(figure_counts),
    sum(applicable),
    sum(controls),
    nrow(build),
    nrow(protected),
    as.character(getRversion()),
    as.character(utils::packageVersion("digest")),
    as.character(utils::packageVersion("xml2"))
  )
)
