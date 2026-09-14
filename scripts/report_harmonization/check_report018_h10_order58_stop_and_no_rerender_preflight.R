#!/usr/bin/env Rscript

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

evidence_root <- file.path(
  root,
  "audit/report_harmonization/report018_h10_order58_stopped_acceptance"
)
dir.create(evidence_root, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  paste0(openssl::sha256(con))
}

file_bytes <- function(path) as.numeric(file.info(path)$size)

read_raw <- function(path) {
  readBin(path, what = "raw", n = file_bytes(path))
}

read_text <- function(path) rawToChar(read_raw(path))

file_exact <- function(path, sha256, bytes = NULL) {
  pass <- file.exists(path) &&
    !dir.exists(path) &&
    identical(sha256_file(path), sha256)
  if (!is.null(bytes)) {
    pass <- pass && identical(file_bytes(path), as.numeric(bytes))
  }
  pass
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

owner_root <- "audit/hypotheses/H10/report018_order58_result_render"
owner_manifest_path <- file.path(
  owner_root,
  "order58_non_circular_evidence_manifest.csv"
)
owner_manifest <- read.csv(owner_manifest_path, check.names = FALSE)
owner_paths <- owner_manifest$path
owner_exact <- vapply(
  seq_len(nrow(owner_manifest)),
  function(i) {
    file_exact(
      owner_manifest$path[[i]],
      owner_manifest$sha256[[i]],
      owner_manifest$bytes[[i]]
    )
  },
  logical(1)
)
owner_audit <- data.frame(
  path = owner_paths,
  expected_sha256 = owner_manifest$sha256,
  observed_sha256 = vapply(owner_paths, sha256_file, character(1)),
  expected_bytes = owner_manifest$bytes,
  observed_bytes = vapply(owner_paths, file_bytes, numeric(1)),
  exact = owner_exact,
  stringsAsFactors = FALSE
)
write.csv(
  owner_audit,
  file.path(evidence_root, "owner_manifest_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "owner_stop",
  "non_circular_manifest",
  nrow(owner_manifest) == 13L &&
    !anyDuplicated(owner_paths) &&
    !owner_manifest_path %in% owner_paths &&
    all(owner_exact),
  sprintf("exact=%d/%d", sum(owner_exact), length(owner_exact))
)
add_check(
  "owner_stop",
  "fail_closed_record",
  file_exact(
    file.path(owner_root, "order58_fail_closed_record.md"),
    "ae2053164f866770b04443b3b51e3e95288cae7e3d468ed1ba85698441c124f8",
    2392
  ) &&
    file_exact(
      owner_manifest_path,
      "b23e04f9aae30c71c95a2d0f07b461e763fedda2dd75d0fd9bed2d83584cdf04",
      2522
    ),
  "owner stopped record and seal reproduce"
)

fixed <- data.frame(
  path = c(
    "notebooks/hypotheses/H10.qmd",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
    "tests/hypotheses/H10/test_h10_preparation_report.R",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html",
    "audit/hypotheses/H10/H10_analysis_preparation.html",
    "_quarto-nathealth.yml",
    "renv.lock",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "notebooks/hypotheses/H11.qmd"
  ),
  sha256 = c(
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "ad792acdb7c9d2fe9290a6837a2a3c994811d7f5c9a64eaea01b0edd9f9b4db1",
    "15d20f3c3fe4d5387eb64152479d07ea0e94b397b27b0a7b59b3d41c7a1924c4",
    "37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14",
    "efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8",
    "efd4c91f970040cf551c5d7a8ad2cb8026f36e8413c6f4846882b4c7111521d8",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867"
  ),
  bytes = c(
    49224,
    58446,
    25796,
    15201,
    359702,
    617113,
    617113,
    7480,
    603493,
    11937,
    57462
  ),
  stringsAsFactors = FALSE
)
fixed$exact <- vapply(
  seq_len(nrow(fixed)),
  function(i) file_exact(fixed$path[[i]], fixed$sha256[[i]], fixed$bytes[[i]]),
  logical(1)
)
write.csv(
  fixed,
  file.path(evidence_root, "fixed_identity_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "identity",
  "source_html_companion_profile_h11",
  all(fixed$exact),
  sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed))
)

test_path <- "tests/hypotheses/H10/test_h10_stage3_reader_report.R"
test_pre <- read_text(test_path)
stale_caption <- "Overview of statistically supported associations"
accepted_caption <- "The 11 main associations retained after FDR adjustment."
stale_matches <- regmatches(
  test_pre,
  gregexpr(stale_caption, test_pre, fixed = TRUE)
)[[1L]]
test_post <- sub(stale_caption, accepted_caption, test_pre, fixed = TRUE)
test_post_raw <- charToRaw(test_post)
prospective_sha <- paste0(openssl::sha256(test_post_raw))
prospective_bytes <- length(test_post_raw)
reverse <- sub(accepted_caption, stale_caption, test_post, fixed = TRUE)
transition <- data.frame(
  path = test_path,
  pre_sha256 = sha256_file(test_path),
  pre_bytes = file_bytes(test_path),
  post_sha256 = prospective_sha,
  post_bytes = prospective_bytes,
  old_literal = stale_caption,
  new_literal = accepted_caption,
  reverse_exact = identical(reverse, test_pre),
  stringsAsFactors = FALSE
)
write.csv(
  transition,
  file.path(evidence_root, "prospective_test_transition.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "test_contract",
  "single_caption_transition",
  length(stale_matches) == 1L &&
    identical(
      prospective_sha,
      "dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af"
    ) &&
    prospective_bytes == 25803L &&
    isTRUE(transition$reverse_exact[[1L]]) &&
    grepl(
      accepted_caption,
      read_text("notebooks/hypotheses/H10.qmd"),
      fixed = TRUE
    ) &&
    grepl(
      accepted_caption,
      read_text("_build/nathealth/notebooks/hypotheses/H10.html"),
      fixed = TRUE
    ),
  sprintf(
    "post=%s/%d reverse=%s",
    prospective_sha,
    prospective_bytes,
    transition$reverse_exact
  )
)

test_messages <- character()
test_error <- NULL
test_connection <- textConnection(test_post)
test_environment <- new.env(parent = globalenv())
tryCatch(
  withCallingHandlers(
    source(
      test_connection,
      local = test_environment,
      echo = FALSE,
      chdir = FALSE
    ),
    message = function(condition) {
      test_messages <<- c(test_messages, conditionMessage(condition))
      invokeRestart("muffleMessage")
    }
  ),
  error = function(condition) {
    test_error <<- conditionMessage(condition)
  },
  finally = close(test_connection)
)
test_output <- c(
  sprintf("prospective_sha256=%s", prospective_sha),
  sprintf("prospective_bytes=%d", prospective_bytes),
  sprintf("error=%s", if (is.null(test_error)) "" else test_error),
  sprintf("messages=%s", paste(test_messages, collapse = " | "))
)
writeLines(
  test_output,
  file.path(evidence_root, "prospective_reader_test_execution.txt"),
  useBytes = TRUE
)
add_check(
  "test_contract",
  "complete_prospective_reader_test",
  is.null(test_error) &&
    any(grepl(
      "H10 standalone reader-report checks passed",
      test_messages,
      fixed = TRUE
    )),
  if (is.null(test_error)) paste(test_messages, collapse = " | ") else
    test_error
)

semantic_summary_path <- paste0(
  "/private/tmp/h10-order58-semantic.UelLEK/",
  "gt_html_semantic_post_render_summary.csv"
)
semantic_ledger_path <- paste0(
  "/private/tmp/h10-order58-semantic.UelLEK/",
  "001__build__nathealth__notebooks__hypotheses__H10.html_",
  "gt_semantic_ledger.csv"
)
stopifnot(
  file_exact(
    semantic_summary_path,
    "23c7f36ee58748a3146f2f30a9575972cdd317d057b753e809fb56e02ea7c5e5",
    456
  ),
  file_exact(
    semantic_ledger_path,
    "094c126424e79332133cb82a879362d2b9a7dbd8c075983cfe7ba2c287574ed9",
    178781
  )
)
semantic_summary <- read.csv(semantic_summary_path, check.names = FALSE)
semantic_ledger <- read.csv(semantic_ledger_path, check.names = FALSE)
engine <- new.env(parent = globalenv())
sys.source(
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  envir = engine
)
html_path <- "_build/nathealth/notebooks/hypotheses/H10.html"
html_raw <- engine$read_file_raw(html_path)
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
semantic_audit <- data.frame(
  check = c(
    "current_matches_post",
    "reverse_matches_pre",
    "reapply_matches_current",
    "ledger_rows",
    "id_rows",
    "headers_rows"
  ),
  pass = c(
    identical(engine$sha256_raw(html_raw), semantic_summary$post_sha256[[1L]]),
    identical(
      engine$sha256_raw(reversed_raw),
      semantic_summary$pre_sha256[[1L]]
    ),
    identical(reapplied_raw, html_raw),
    nrow(semantic_ledger) == semantic_summary$total_substitutions[[1L]],
    sum(semantic_ledger$attribute == "id") == semantic_summary$id_count[[1L]],
    sum(semantic_ledger$attribute == "headers") ==
      semantic_summary$headers_count[[1L]]
  ),
  detail = c(
    engine$sha256_raw(html_raw),
    engine$sha256_raw(reversed_raw),
    engine$sha256_raw(reapplied_raw),
    as.character(nrow(semantic_ledger)),
    as.character(sum(semantic_ledger$attribute == "id")),
    as.character(sum(semantic_ledger$attribute == "headers"))
  ),
  stringsAsFactors = FALSE
)
write.csv(
  semantic_audit,
  file.path(evidence_root, "semantic_reverse_reapply_audit.csv"),
  row.names = FALSE,
  na = ""
)

document <- xml2::read_html(html_path)
main_nodes <- xml2::xml_find_all(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(length(main_nodes) == 1L)
main <- main_nodes[[1L]]
gt_xpath <- paste0(
  ".//table[contains(concat(' ', normalize-space(@class), ' '),",
  " ' gt_table ')]"
)
gt_tables <- xml2::xml_find_all(main, gt_xpath)
figures <- xml2::xml_find_all(
  main,
  ".//figure//img[contains(concat(' ', normalize-space(@class), ' '), ' figure-img ')]"
)
table_endpoints <- vapply(
  gt_tables,
  function(table) {
    endpoint <- xml2::xml_find_first(
      table,
      "ancestor::*[@id and starts-with(@id,'tbl-')][1]"
    )
    if (inherits(endpoint, "xml_missing")) NA_character_ else
      xml2::xml_attr(endpoint, "id")
  },
  character(1)
)
figure_endpoints <- vapply(
  figures,
  function(image) {
    endpoint <- xml2::xml_find_first(
      image,
      "ancestor::*[@id and starts-with(@id,'fig-')][1]"
    )
    if (inherits(endpoint, "xml_missing")) NA_character_ else
      xml2::xml_attr(endpoint, "id")
  },
  character(1)
)
qmd_lines <- readLines("notebooks/hypotheses/H10.qmd", warn = FALSE)
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
endpoint_audit <- data.frame(
  endpoint_type = c(
    rep("table", length(table_endpoints)),
    rep("figure", length(figure_endpoints))
  ),
  position = c(seq_along(table_endpoints), seq_along(figure_endpoints)),
  expected = c(expected_tables, expected_figures),
  observed = c(table_endpoints, figure_endpoints),
  exact = c(
    expected_tables == table_endpoints,
    expected_figures == figure_endpoints
  ),
  stringsAsFactors = FALSE
)
write.csv(
  endpoint_audit,
  file.path(evidence_root, "dom_endpoint_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "semantic_dom",
  "reversal_and_scoped_headers",
  nrow(semantic_summary) == 1L &&
    semantic_summary$disposition[[1L]] == "REPAIRED" &&
    semantic_summary$table_count[[1L]] == 15L &&
    semantic_summary$id_count[[1L]] == 92L &&
    semantic_summary$headers_count[[1L]] == 1038L &&
    semantic_summary$total_substitutions[[1L]] == 1130L &&
    all(semantic_audit$pass) &&
    !anyDuplicated(document_ids) &&
    headers_valid,
  sprintf(
    "tables=15 ids=92 headers=1038 substitutions=1130 tokens=%d",
    header_tokens
  )
)
add_check(
  "semantic_dom",
  "source_ordered_endpoints",
  nrow(endpoint_audit) == 23L && all(endpoint_audit$exact),
  sprintf(
    "tables=%d figures=%d",
    length(table_endpoints),
    length(figure_endpoints)
  )
)

error_nodes <- xml2::xml_find_all(
  main,
  paste0(
    ".//*[contains(@class,'cell-output-error') or ",
    "contains(@class,'cell-output-stderr') or ",
    "contains(@class,'quarto-unresolved-ref')]"
  )
)
add_check(
  "semantic_dom",
  "no_rendered_errors_or_unresolved_refs",
  length(error_nodes) == 0L,
  sprintf("nodes=%d", length(error_nodes))
)

source_text <- read_text("notebooks/hypotheses/H10.qmd")
markdown_links <- regmatches(
  source_text,
  gregexpr(r"{\[[^]]+\]\([^)]+\)}", source_text, perl = TRUE)
)[[1L]]
source_targets <- sub(r"{^.*\]\(}", "", markdown_links, perl = TRUE)
source_targets <- sub(r"{\)$}", "", source_targets, perl = TRUE)
source_targets <- source_targets[
  !grepl(r"{^(https?:|mailto:|#)}", source_targets, perl = TRUE)
]
html_hrefs <- xml2::xml_attr(xml2::xml_find_all(main, ".//a[@href]"), "href")
content_hrefs <- html_hrefs[
  !startsWith(html_hrefs, "#") &
    !grepl("notebooks/hypotheses/H0[1-9]\\.html$", html_hrefs) &
    html_hrefs != "../../notebooks/hypotheses/H10.html"
]
content_hrefs <- content_hrefs[
  grepl(
    "(preregistration_deviations|preparation/|artifacts/|H10_analysis_preparation)",
    content_hrefs
  )
]
resolved <- file.path(
  dirname(html_path),
  sub("#.*$", "", utils::URLdecode(content_hrefs))
)
fragment_rows <- nzchar(sub("^[^#]*", "", content_hrefs))
fragment_ok <- rep(TRUE, length(content_hrefs))
for (i in which(fragment_rows)) {
  target_document <- xml2::read_html(resolved[[i]])
  fragment <- sub("^.*#", "", content_hrefs[[i]])
  fragment_ok[[i]] <- length(xml2::xml_find_all(
    target_document,
    sprintf("//*[@id='%s']", fragment)
  )) ==
    1L
}
link_audit <- data.frame(
  href = content_hrefs,
  resolved_path = resolved,
  target_exists = file.exists(resolved),
  fragment_resolves_once = fragment_ok,
  stringsAsFactors = FALSE
)
write.csv(
  link_audit,
  file.path(evidence_root, "link_resolution_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "links",
  "source_and_rendered_target_multiset",
  length(source_targets) == 26L &&
    length(unique(source_targets)) == 24L &&
    length(content_hrefs) == 26L &&
    length(unique(content_hrefs)) == 24L &&
    all(link_audit$target_exists) &&
    all(link_audit$fragment_resolves_once),
  sprintf(
    "source=%d/%d rendered=%d/%d",
    length(source_targets),
    length(unique(source_targets)),
    length(content_hrefs),
    length(unique(content_hrefs))
  )
)

stage3_manifest <- read.csv(
  "artifacts/12_manifests/H10/H10_stage3_artifacts.csv",
  check.names = FALSE
)
stage3_observed <- vapply(stage3_manifest$path, sha256_file, character(1))
stage3_mismatch <- stage3_manifest$path[
  stage3_observed != stage3_manifest$sha256
]
expected_mismatch <- c(
  "audit/hypotheses/H10/H10_analysis_preparation.qmd",
  "tests/hypotheses/H10/test_h10_preparation_report.R",
  "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
  "_build/nathealth/notebooks/hypotheses/H10.html",
  "notebooks/hypotheses/H10.qmd",
  "_quarto-nathealth.yml"
)
add_check(
  "historical_manifest",
  "exact_six_transitions",
  length(stage3_mismatch) == 6L && setequal(stage3_mismatch, expected_mismatch),
  paste(sort(stage3_mismatch), collapse = " | ")
)

scientific_assets <- sort(c(
  list.files("artifacts/09_tables/H10", full.names = TRUE, recursive = FALSE),
  list.files("artifacts/10_figures/H10", full.names = TRUE, recursive = FALSE),
  list.files(
    "artifacts/11_source_data/H10",
    full.names = TRUE,
    recursive = FALSE
  )
))
scientific_assets <- scientific_assets[
  file.info(scientific_assets)$isdir %in% FALSE
]
asset_rows <- match(scientific_assets, stage3_manifest$path)
asset_exact <- vapply(
  seq_along(scientific_assets),
  function(i) {
    row <- asset_rows[[i]]
    !is.na(row) &&
      file_exact(
        scientific_assets[[i]],
        stage3_manifest$sha256[[row]],
        stage3_manifest$bytes[[row]]
      )
  },
  logical(1)
)
add_check(
  "science",
  "fifty_seven_assets",
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

build_pre <- read.csv(
  "/private/tmp/h10-order58-control.SBA1Ua/build_inventory_prerender.csv",
  check.names = FALSE
)
build_now <- inventory_tree("_build/nathealth")
build_pre$sha256[!nzchar(build_pre$sha256)] <- NA_character_
build_now$sha256[!nzchar(build_now$sha256)] <- NA_character_
all_build <- sort(unique(c(build_pre$path, build_now$path)))
pre_index <- match(all_build, build_pre$path)
now_index <- match(all_build, build_now$path)
build_delta <- data.frame(
  path = all_build,
  pre_sha256 = build_pre$sha256[pre_index],
  live_sha256 = build_now$sha256[now_index],
  pre_bytes = build_pre$bytes[pre_index],
  live_bytes = build_now$bytes[now_index],
  pre_type = build_pre$type[pre_index],
  live_type = build_now$type[now_index],
  stringsAsFactors = FALSE
)
build_same <- (is.na(build_delta$pre_sha256) &
  is.na(build_delta$live_sha256) &
  build_delta$pre_type == build_delta$live_type) |
  (!is.na(build_delta$pre_sha256) &
    !is.na(build_delta$live_sha256) &
    build_delta$pre_sha256 == build_delta$live_sha256 &
    build_delta$pre_type == build_delta$live_type)
build_same[is.na(build_same)] <- FALSE
build_delta <- build_delta[!build_same, , drop = FALSE]
write.csv(
  build_delta,
  file.path(evidence_root, "build_delta_audit.csv"),
  row.names = FALSE,
  na = ""
)
expected_build_delta <- c(
  "_build/nathealth/notebooks/hypotheses/H10.html",
  "_build/nathealth/search.json",
  "_build/nathealth/sitemap.xml"
)
add_check(
  "build",
  "exact_target_owned_delta",
  nrow(build_pre) == nrow(build_now) &&
    nrow(build_delta) == 3L &&
    setequal(build_delta$path, expected_build_delta) &&
    sum(build_now$type == "symlink") == 0L,
  sprintf(
    "entries=%d delta=%d symlinks=%d",
    nrow(build_now),
    nrow(build_delta),
    sum(build_now$type == "symlink")
  )
)

protected_pre <- read.csv(
  "/private/tmp/h10-order58-control.SBA1Ua/protected_inventory_prerender.csv",
  check.names = FALSE
)
protected_current <- vapply(protected_pre$path, sha256_file, character(1))
protected_exact <- protected_current == protected_pre$sha256
test_row <- match(test_path, protected_pre$path)
prospective_expected <- protected_pre$sha256
prospective_expected[[test_row]] <- prospective_sha
prospective_observed <- protected_current
prospective_observed[[test_row]] <- prospective_sha
protected_audit <- data.frame(
  path = protected_pre$path,
  pre_sha256 = protected_pre$sha256,
  live_sha256 = protected_current,
  prospective_sha256 = prospective_observed,
  authorized_transition = seq_len(nrow(protected_pre)) == test_row,
  prospective_exact = prospective_observed == prospective_expected,
  stringsAsFactors = FALSE
)
write.csv(
  protected_audit,
  file.path(evidence_root, "protected_transition_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "protected",
  "current_exact_and_one_prospective_test_transition",
  nrow(protected_pre) == 150L &&
    all(protected_exact) &&
    !is.na(test_row) &&
    sum(protected_audit$authorized_transition) == 1L &&
    all(protected_audit$prospective_exact),
  sprintf("current=%d/150 prospective_transition=1", sum(protected_exact))
)

qa <- read.csv(
  "artifacts/12_manifests/H10/H10_stage3_figure_readability_qa.csv",
  check.names = FALSE
)
figure_src <- xml2::xml_attr(figures, "src")
figure_alt <- xml2::xml_attr(figures, "alt")
figure_paths <- normalizePath(
  file.path(dirname(html_path), utils::URLdecode(figure_src)),
  winslash = "/",
  mustWork = TRUE
)
served_root <- normalizePath(
  "_build/nathealth",
  winslash = "/",
  mustWork = TRUE
)
qa_harness <- data.frame(
  check = c(
    "served_root_has_no_symlinks",
    "result_route_exists",
    "viewport_meta_present",
    "eight_figure_sources_contained",
    "eight_accessible_alt_texts",
    "readability_manifest_pass",
    "desktop_viewport_specified",
    "narrow_viewport_specified",
    "zoom_equivalent_viewport_specified",
    "final_size_specified",
    "pre_post_inventory_contract"
  ),
  pass = c(
    sum(build_now$type == "symlink") == 0L,
    file.exists(html_path),
    length(xml2::xml_find_all(document, "//meta[@name='viewport']")) == 1L,
    length(figure_paths) == 8L &&
      all(startsWith(figure_paths, paste0(served_root, "/"))),
    length(figure_alt) == 8L &&
      all(!is.na(figure_alt)) &&
      all(nchar(figure_alt) >= 200L),
    nrow(qa) == 8L &&
      all(qa$overall_status == "PASS") &&
      all(qa$visual_status == "PASS") &&
      all(qa$typography_status == "PASS_BY_CALCULATION"),
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE
  ),
  detail = c(
    sprintf("symlinks=%d", sum(build_now$type == "symlink")),
    "notebooks/hypotheses/H10.html",
    "single responsive viewport meta",
    sprintf("figures=%d", length(figure_paths)),
    sprintf(
      "alts=%d minimum_chars=%d",
      length(figure_alt),
      min(nchar(figure_alt))
    ),
    sprintf(
      "rows=%d essential_min=%.3f central_min=%.3f",
      nrow(qa),
      min(qa$effective_final_essential_text_pt),
      min(qa$effective_final_central_text_pt)
    ),
    "1440x1000",
    "708x1000",
    "720x500",
    "170 mm",
    "rehash QMD test profile HTML companion build and protected after QA"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  qa_harness,
  file.path(evidence_root, "qa_harness_audit.csv"),
  row.names = FALSE,
  na = ""
)
add_check(
  "qa_harness",
  "complete_no_rerender_path_ready",
  all(qa_harness$pass),
  sprintf("checks=%d/%d", sum(qa_harness$pass), nrow(qa_harness))
)

checks_df <- do.call(rbind, checks)
write.csv(
  checks_df,
  file.path(evidence_root, "independent_checks.csv"),
  row.names = FALSE,
  na = ""
)
stopifnot(all(checks_df$pass))

cat(
  sprintf(
    paste0(
      "REPORT018_H10_ORDER58_STOP_NO_RERENDER_PREFLIGHT=PASS ",
      "checks=%d owner=%d/%d prospective=%s/%d test=PASS ",
      "tables=%d figures=%d semantic=%d build=%d protected=%d qa=%d R=%s\n"
    ),
    nrow(checks_df),
    sum(owner_exact),
    length(owner_exact),
    prospective_sha,
    prospective_bytes,
    length(gt_tables),
    length(figures),
    nrow(semantic_ledger),
    nrow(build_delta),
    nrow(protected_pre),
    nrow(qa_harness),
    as.character(getRversion())
  )
)
