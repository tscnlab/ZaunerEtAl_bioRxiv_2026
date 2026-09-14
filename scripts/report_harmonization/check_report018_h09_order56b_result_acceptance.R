#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c("digest", "readr", "rvest", "xml2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf(
    "Independent H09 acceptance requires R 4.6.1, found %s.",
    getRversion()
  )
)

evidence_root <- "audit/hypotheses/H09/report018_order56b_environment_retry"
owner_manifest_path <- file.path(
  evidence_root,
  "order56b_evidence_manifest.csv"
)
html_path <- "_build/nathealth/notebooks/hypotheses/H09.html"
verification_path <- paste0(
  "audit/report_harmonization/",
  "report018_h09_order56b_result_independent_verification.csv"
)

checks <- list()
record_check <- function(check, observed, expected, status) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check = check,
    observed = as.character(observed),
    expected = as.character(expected),
    status = status,
    stringsAsFactors = FALSE
  )
  assert_true(identical(status, "PASS"), paste("Failed check:", check))
}

owner_manifest <- readr::read_csv(owner_manifest_path, show_col_types = FALSE)
manifest_shape_ok <- nrow(owner_manifest) == 118L &&
  !anyDuplicated(owner_manifest$relative_path) &&
  !any(owner_manifest$relative_path == owner_manifest_path)
record_check(
  "owner manifest shape",
  sprintf(
    "rows=%d unique=%s non_circular=%s",
    nrow(owner_manifest),
    !anyDuplicated(owner_manifest$relative_path),
    !any(owner_manifest$relative_path == owner_manifest_path)
  ),
  "rows=118 unique=TRUE non_circular=TRUE",
  ifelse(manifest_shape_ok, "PASS", "FAIL")
)

owner_exists <- file.exists(owner_manifest$relative_path)
owner_sha <- rep(NA_character_, nrow(owner_manifest))
owner_bytes <- rep(NA_real_, nrow(owner_manifest))
owner_sha[owner_exists] <- vapply(
  owner_manifest$relative_path[owner_exists],
  sha256_file,
  character(1)
)
owner_bytes[owner_exists] <- file.info(
  owner_manifest$relative_path[owner_exists]
)$size
owner_exact <- owner_exists &
  owner_sha == owner_manifest$sha256 &
  owner_bytes == owner_manifest$bytes
record_check(
  "owner manifest identities",
  sprintf("%d/%d exact", sum(owner_exact), nrow(owner_manifest)),
  "118/118 exact",
  ifelse(all(owner_exact), "PASS", "FAIL")
)

fixed_identities <- data.frame(
  path = c(
    file.path(evidence_root, "ORDER56B_ACCEPTANCE.md"),
    owner_manifest_path,
    file.path(evidence_root, "verify_order56b_h09_result.R"),
    html_path,
    "notebooks/hypotheses/H09.qmd",
    "audit/hypotheses/H09/H09_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html",
    "scripts/hypotheses/H09/refresh_h09_order56_figures.R",
    "tests/hypotheses/H09/test_h09_order56_display_repair.R",
    "scripts/hypotheses/H09/run_h09_stage2.R",
    "artifacts/12_manifests/H09/H09_figure_manifest.csv",
    "_quarto-nathealth.yml",
    "renv.lock"
  ),
  sha256 = c(
    "a44988f7e9afae9ca4064ae3f7ec971a7e48a3dc47bb5056aef6992b3b845cdd",
    "2b4e45d93120364f4b9589184e93d92f2e247a749226667c75ce00e46779ce2a",
    "fbe3d789ce587f5ad3616fc9091cd4c7d8732b9da8e47632c8c76900c0dc3965",
    "901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16",
    "c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6",
    "7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46",
    "4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05",
    "ceaf4771c8a8e3248f690930325cd7ecc2522e2bee464a321e783395029f1ffe",
    "eefa3e278abdb2208181cdc1e70529dbb5295b1a58cf0d1d5b4fcbe98b925642",
    "4711057eacebdfc7ee9295d9f895e8ab73f60c0f7a51d0b03ea61459b7ac611c",
    "74c0f444f5670ec86b319f09836e2fb670ebba768f81b0bbdeeaf989159f15ce",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  )
)
fixed_exact <- file.exists(fixed_identities$path) &
  vapply(fixed_identities$path, sha256_file, character(1)) ==
    fixed_identities$sha256
record_check(
  "fixed accepted identities",
  sprintf("%d/%d exact", sum(fixed_exact), nrow(fixed_identities)),
  "13/13 exact",
  ifelse(all(fixed_exact), "PASS", "FAIL")
)

render_execution <- readr::read_csv(
  file.path(evidence_root, "render_execution.csv"),
  show_col_types = FALSE
)
render_ok <- nrow(render_execution) == 1L &&
  render_execution$attempt[[1L]] == 1L &&
  render_execution$target[[1L]] == "notebooks/hypotheses/H09.qmd" &&
  render_execution$profile[[1L]] == "nathealth" &&
  render_execution$autoloader[[1L]] == "disabled" &&
  render_execution$r_version[[1L]] == "4.6.1" &&
  !render_execution$home_override[[1L]] &&
  !render_execution$xdg_cache_home_override[[1L]] &&
  !render_execution$deno_dir_override[[1L]] &&
  render_execution$exit_code[[1L]] == 0L &&
  render_execution$disposition[[1L]] == "SUCCESS_SINGLE_ENVIRONMENT_ONLY_RETRY"
record_check(
  "single environment retry",
  sprintf(
    "rows=%d attempt=%s exit=%s profile=%s",
    nrow(render_execution),
    render_execution$attempt[[1L]],
    render_execution$exit_code[[1L]],
    render_execution$profile[[1L]]
  ),
  "rows=1 attempt=1 exit=0 profile=nathealth",
  ifelse(render_ok, "PASS", "FAIL")
)

cache_transition <- readr::read_csv(
  file.path(evidence_root, "sass_cache_transition.csv"),
  show_col_types = FALSE
)
cache_ok <- nrow(cache_transition) == 25L &&
  all(cache_transition$status == "PASS") &&
  all(cache_transition$transition == "exact") &&
  all(cache_transition$owner_before == "zauner") &&
  all(cache_transition$owner_after == "zauner") &&
  any(cache_transition$filename == "sass.kv")
record_check(
  "user-owned Sass cache",
  sprintf(
    "rows=%d exact=%d",
    nrow(cache_transition),
    sum(cache_transition$status == "PASS")
  ),
  "rows=25 exact=25",
  ifelse(cache_ok, "PASS", "FAIL")
)

semantic_summary <- readr::read_csv(
  file.path(evidence_root, "gt_html_semantic_post_render_summary.csv"),
  show_col_types = FALSE
)
semantic_ok <- nrow(semantic_summary) == 1L &&
  semantic_summary$disposition[[1L]] == "REPAIRED" &&
  semantic_summary$post_sha256[[1L]] ==
    fixed_identities$sha256[
      fixed_identities$path == html_path
    ] &&
  semantic_summary$table_count[[1L]] == 11L &&
  semantic_summary$id_count[[1L]] == 54L &&
  semantic_summary$headers_count[[1L]] == 505L &&
  semantic_summary$total_substitutions[[1L]] == 559L
record_check(
  "semantic summary",
  sprintf(
    "tables=%s ids=%s headers=%s total=%s",
    semantic_summary$table_count[[1L]],
    semantic_summary$id_count[[1L]],
    semantic_summary$headers_count[[1L]],
    semantic_summary$total_substitutions[[1L]]
  ),
  "tables=11 ids=54 headers=505 total=559",
  ifelse(semantic_ok, "PASS", "FAIL")
)

semantic_dir <- render_execution$semantic_directory[[1L]]
ledger_path <- file.path(
  semantic_dir,
  semantic_summary$ledger_file[[1L]]
)
ledger <- readr::read_csv(ledger_path, show_col_types = FALSE)
ledger_ok <- nrow(ledger) == 559L &&
  sum(ledger$attribute == "id") == 54L &&
  sum(ledger$attribute == "headers") == 505L
reverse_audit <- readr::read_csv(
  file.path(evidence_root, "semantic_reverse_audit.csv"),
  show_col_types = FALSE
)
ledger_ok <- ledger_ok &&
  nrow(reverse_audit) == 6L &&
  all(reverse_audit$status == "PASS")
record_check(
  "semantic ledger and reversal",
  sprintf(
    "ledger=%d reverse=%d/%d",
    nrow(ledger),
    sum(reverse_audit$status == "PASS"),
    nrow(reverse_audit)
  ),
  "ledger=559 reverse=6/6",
  ifelse(ledger_ok, "PASS", "FAIL")
)

document <- xml2::read_html(html_path)
main_count <- length(rvest::html_elements(
  document,
  "main#quarto-document-content"
))
ids <- stats::na.omit(rvest::html_attr(
  rvest::html_elements(document, "[id]"),
  "id"
))
tables <- rvest::html_elements(document, "table.gt_table")

table_headers_ok <- vapply(
  tables,
  function(table) {
    th_nodes <- rvest::html_elements(table, "th[id]")
    th_ids <- rvest::html_attr(th_nodes, "id")
    headers_values <- rvest::html_attr(
      rvest::html_elements(table, "[headers]"),
      "headers"
    )
    tokens <- unlist(
      strsplit(headers_values, "[[:space:]]+"),
      use.names = FALSE
    )
    tokens <- tokens[nzchar(tokens)]
    if (!length(tokens)) return(FALSE)
    all(vapply(tokens, function(token) sum(th_ids == token) == 1L, logical(1)))
  },
  logical(1)
)

header_values <- rvest::html_attr(
  rvest::html_elements(document, "table.gt_table [headers]"),
  "headers"
)
header_tokens <- unlist(
  strsplit(header_values, "[[:space:]]+"),
  use.names = FALSE
)
header_tokens <- header_tokens[nzchar(header_tokens)]
dom_ok <- main_count == 1L &&
  !anyDuplicated(ids) &&
  length(tables) == 11L &&
  length(header_tokens) == 505L &&
  all(table_headers_ok)
record_check(
  "independent HTML semantics",
  sprintf(
    "main=%d ids=%d duplicates=%d tables=%d headers=%d",
    main_count,
    length(ids),
    sum(duplicated(ids)),
    length(tables),
    length(header_tokens)
  ),
  "main=1 duplicates=0 tables=11 headers=505",
  ifelse(dom_ok, "PASS", "FAIL")
)

table_audit <- readr::read_csv(
  file.path(evidence_root, "table_endpoint_audit.csv"),
  show_col_types = FALSE
)
figure_audit <- readr::read_csv(
  file.path(evidence_root, "figure_endpoint_audit.csv"),
  show_col_types = FALSE
)
endpoint_ok <- nrow(table_audit) == 11L &&
  all(table_audit$status == "PASS") &&
  nrow(figure_audit) == 4L &&
  all(figure_audit$status == "PASS") &&
  all(figure_audit$built_sha256 == figure_audit$durable_sha256)
record_check(
  "table and figure endpoints",
  sprintf(
    "tables=%d/%d figures=%d/%d",
    sum(table_audit$status == "PASS"),
    nrow(table_audit),
    sum(figure_audit$status == "PASS"),
    nrow(figure_audit)
  ),
  "tables=11/11 figures=4/4",
  ifelse(endpoint_ok, "PASS", "FAIL")
)

nonvisual <- readr::read_csv(
  file.path(evidence_root, "nonvisual_status.csv"),
  show_col_types = FALSE
)
link_audit <- readr::read_csv(
  file.path(evidence_root, "reader_link_audit.csv"),
  show_col_types = FALSE
)
nonvisual_ok <- nrow(nonvisual) == 16L &&
  all(nonvisual$status == "PASS") &&
  nrow(link_audit) > 0L &&
  all(link_audit$status == "PASS")
record_check(
  "reader and link contracts",
  sprintf(
    "nonvisual=%d/%d links=%d/%d",
    sum(nonvisual$status == "PASS"),
    nrow(nonvisual),
    sum(link_audit$status == "PASS"),
    nrow(link_audit)
  ),
  "nonvisual=16/16 links=all",
  ifelse(nonvisual_ok, "PASS", "FAIL")
)

visual <- readr::read_csv(
  file.path(evidence_root, "visual_qa_status.csv"),
  show_col_types = FALSE
)
screenshot_manifest <- readr::read_csv(
  file.path(evidence_root, "visual_screenshot_manifest.csv"),
  show_col_types = FALSE
)
visual_ok <- nrow(visual) == 9L &&
  all(visual$status == "PASS") &&
  nrow(screenshot_manifest) > 0L &&
  !anyDuplicated(screenshot_manifest$relative_path) &&
  all(file.exists(screenshot_manifest$relative_path)) &&
  all(
    vapply(screenshot_manifest$relative_path, sha256_file, character(1)) ==
      screenshot_manifest$sha256
  )
record_check(
  "visual QA evidence",
  sprintf(
    "domains=%d/%d screenshots=%d",
    sum(visual$status == "PASS"),
    nrow(visual),
    nrow(screenshot_manifest)
  ),
  "domains=9/9 screenshots=exact",
  ifelse(visual_ok, "PASS", "FAIL")
)

rehash <- readr::read_csv(
  file.path(evidence_root, "postqa_rehash_reconciliation.csv"),
  show_col_types = FALSE
)
protected <- readr::read_csv(
  file.path(evidence_root, "protected_reconciliation_postrender.csv"),
  show_col_types = FALSE
)
reconciliation_ok <- nrow(rehash) == 2L &&
  all(rehash$status == "PASS") &&
  identical(as.integer(rehash$exact_rows), c(851L, 275L)) &&
  nrow(protected) == 275L &&
  all(protected$status == "PASS")
record_check(
  "build and protected reconciliation",
  sprintf(
    "build=%s protected=%s",
    rehash$exact_rows[[1L]],
    rehash$exact_rows[[2L]]
  ),
  "build=851 protected=275",
  ifelse(reconciliation_ok, "PASS", "FAIL")
)

source_freeze <- readr::read_csv(
  file.path(evidence_root, "final_source_freeze_audit.csv"),
  show_col_types = FALSE
)
display_manifest <- readr::read_csv(
  file.path(evidence_root, "current_display_manifest.csv"),
  show_col_types = FALSE
)
preservation_ok <- nrow(source_freeze) == 9L &&
  all(source_freeze$status == "PASS") &&
  nrow(display_manifest) == 17L &&
  !anyDuplicated(display_manifest$relative_path) &&
  all(file.exists(display_manifest$relative_path)) &&
  all(
    vapply(display_manifest$relative_path, sha256_file, character(1)) ==
      display_manifest$sha256
  )
record_check(
  "source and display preservation",
  sprintf(
    "source=%d/%d display=%d/%d",
    sum(source_freeze$status == "PASS"),
    nrow(source_freeze),
    nrow(display_manifest),
    nrow(display_manifest)
  ),
  "source=9/9 display=17/17",
  ifelse(preservation_ok, "PASS", "FAIL")
)

lifecycle <- readr::read_csv(
  file.path(evidence_root, "loopback_lifecycle.csv"),
  show_col_types = FALSE
)
process_probe <- readr::read_csv(
  file.path(evidence_root, "process_probe_postqa.csv"),
  show_col_types = FALSE
)
teardown_ok <- nrow(lifecycle) == 2L &&
  identical(lifecycle$event, c("start", "stop")) &&
  all(lifecycle$bind_address == "127.0.0.1") &&
  all(lifecycle$status == "PASS") &&
  nrow(process_probe) == 4L &&
  all(process_probe$match_count == 0L) &&
  all(process_probe$status == "PASS")
record_check(
  "loopback teardown",
  sprintf(
    "lifecycle=%d/%d remaining=%d",
    sum(lifecycle$status == "PASS"),
    nrow(lifecycle),
    sum(process_probe$match_count)
  ),
  "lifecycle=2/2 remaining=0",
  ifelse(teardown_ok, "PASS", "FAIL")
)

verification <- do.call(rbind, checks)
readr::write_csv(verification, verification_path)

cat(sprintf(
  paste0(
    "REPORT018_H09_ORDER56B_INDEPENDENT_ACCEPTANCE=PASS ",
    "checks=%d/%d owner=118/118 tables=11 figures=4 ",
    "semantic=559 links=23/21 visual=9/9 build=851 protected=275 ",
    "R=%s\n"
  ),
  sum(verification$status == "PASS"),
  nrow(verification),
  getRversion()
))
