#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_rel <- "audit/hypotheses/H08/report018_order55_companion_render"
evidence_dir <- file.path(root, evidence_rel)
manifest_rel <- file.path(evidence_rel, "order55_evidence_manifest.csv")
manifest_path <- file.path(root, manifest_rel)
html_rel <-
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html"
html_path <- file.path(root, html_rel)
preparation_manifest_rel <-
  "artifacts/12_manifests/H08/H08_preparation_report_manifest.csv"
preparation_manifest_path <- file.path(root, preparation_manifest_rel)
output_rel <- paste0(
  "audit/report_harmonization/",
  "report018_h08_companion_independent_verification.csv"
)
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

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Independent acceptance requires R 4.6.1")
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

read_evidence <- function(filename) {
  read.csv(file.path(evidence_dir, filename), check.names = FALSE)
}

all_pass <- function(filename, expected_rows, status_column = "status") {
  value <- read_evidence(filename)
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

audit_manifest <- function(
  manifest,
  manifest_self_rel,
  expected_rows,
  path_column = "path"
) {
  paths <- manifest[[path_column]]
  resolved <- ifelse(grepl("^/", paths), paths, file.path(root, paths))
  exists <- file.exists(resolved) & !dir.exists(resolved)
  observed_sha <- rep(NA_character_, length(resolved))
  observed_bytes <- rep(NA_real_, length(resolved))
  observed_sha[exists] <- vapply(
    resolved[exists],
    sha256_file,
    character(1)
  )
  observed_bytes[exists] <- vapply(
    resolved[exists],
    file_bytes,
    numeric(1)
  )
  exact <- exists &
    observed_sha == manifest$sha256 &
    observed_bytes == as.numeric(manifest$bytes)
  list(
    rows = nrow(manifest),
    unique = !anyDuplicated(paths),
    non_circular = !manifest_self_rel %in% paths,
    exact = exact,
    pass = nrow(manifest) == expected_rows &&
      !anyDuplicated(paths) &&
      !manifest_self_rel %in% paths &&
      all(exact)
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
owner_audit <- audit_manifest(manifest, manifest_rel, 209L)
add_check(
  "owner manifest rows",
  owner_audit$rows,
  209L,
  owner_audit$rows == 209L
)
add_check(
  "owner manifest paths unique",
  length(unique(manifest$path)),
  209L,
  owner_audit$unique
)
add_check(
  "owner manifest non-circular",
  sum(manifest$path == manifest_rel),
  0L,
  owner_audit$non_circular
)
add_check(
  "owner manifest live identities",
  sum(owner_audit$exact),
  209L,
  all(owner_audit$exact)
)

require_file(
  file.path(evidence_rel, "ORDER55_COMPLETION.md"),
  "abf3b15798008c5c1b0d81f2ba639260437ce9ec45c26a72f2bd8d1b366d897d",
  8750
)
require_file(
  manifest_rel,
  "13d90bbf8b8efb088429daa9ec0aee6d7a2514c898837761a4a6f032303e825d",
  37977
)
require_file(
  "notebooks/hypotheses/H08.qmd",
  "1b6b50b21e22d60909a65b125ce74be54829e5efc10de33f888fcd294c7374b1",
  44031
)
require_file(
  "_build/nathealth/notebooks/hypotheses/H08.html",
  "472848d0da3e3996fa1727151048e3cab4a7e363dba3dc8eda8b024eb5a4ca9a",
  340040
)
require_file(
  "audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d",
  57777
)
require_file(
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d",
  57777
)
require_file(
  html_rel,
  "cd0ce2210949559408d07bcbccac502d3b0a372b4229da70bdfc6dbe0c52f66b",
  732155
)
require_file(
  preparation_manifest_rel,
  "53264f81daed1b69ff8e78e7afcdab0e7d34b473ddb2f20b9f6820ffca5c1720",
  64474
)
require_file(
  "scripts/hypotheses/H08/build_h08_preparation_report_manifest.R",
  "55fb72225d86ae694778339f395c0bd23f1870ea587bff1a29741af729727014",
  9383
)
require_file(
  "tests/hypotheses/H08/test_h08_preparation_report.R",
  "2e83542b120021e0c337a3769127e6eba2fe61ebc4d56014693b34066a3fc2a4",
  13024
)
require_file(
  "tests/hypotheses/H08/test_h08_stage3_reader_report.R",
  "3049ecd80bc7f6c83dce7370b2877a92c6693dd9585f1f45ed7ac19fdf64be8f",
  18954
)
require_file(
  "_quarto-nathealth.yml",
  "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  7480
)
require_file(
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
  11937
)

pass_files <- c(
  nonvisual_status.csv = 20L,
  table_endpoint_audit.csv = 19L,
  figure_endpoint_audit.csv = 3L,
  mermaid_endpoint_audit.csv = 6L,
  table_header_reference_audit.csv = 1581L,
  semantic_reverse_audit.csv = 7L,
  semantic_invariance_audit.csv = 7L,
  reader_link_and_fragment_audit.csv = 25L,
  reader_phrase_audit.csv = 12L,
  source_data_contract_audit.csv = 6L,
  scientific_table_contract_audit.csv = 12L,
  exact_formula_table_audit.csv = 9L,
  model_setting_audit.csv = 9L,
  fdr_family_contract_audit.csv = 1L,
  score_and_sample_support_audit.csv = 8L,
  target_png_transition_audit.csv = 3L,
  visual_qa_status.csv = 13L,
  figure_final_size_typography_audit.csv = 3L,
  release_pin_reconciliation_postqa.csv = 34L,
  result_acceptance_reconciliation_postqa.csv = 31L,
  phase4_manifest_transition_audit.csv = 2L,
  stage3_manifest_historical_audit.csv = 102L,
  protected_reconciliation_postrender.csv = 276L,
  build_delta_postrender.csv = 5L,
  postqa_rehash_reconciliation.csv = 2L,
  render_and_helper_execution_audit.csv = 9L,
  helper_execution.csv = 9L,
  final_source_freeze_audit.csv = 11L
)
pass_evidence <- lapply(
  names(pass_files),
  function(filename) all_pass(filename, pass_files[[filename]])
)
names(pass_evidence) <- names(pass_files)

preparation_manifest <- read.csv(
  preparation_manifest_path,
  check.names = FALSE
)
expected_preparation_columns <- c(
  "path",
  "role",
  "artifact_class",
  "sha256",
  "bytes",
  "producer",
  "r_version"
)
add_check(
  "preparation manifest columns",
  paste(names(preparation_manifest), collapse = "|"),
  paste(expected_preparation_columns, collapse = "|"),
  identical(names(preparation_manifest), expected_preparation_columns)
)
preparation_audit <- audit_manifest(
  preparation_manifest,
  preparation_manifest_rel,
  258L
)
add_check(
  "preparation manifest rows and identities",
  paste0(sum(preparation_audit$exact), "/", preparation_audit$rows),
  "258/258",
  preparation_audit$pass
)

build_postrender <- read_evidence("build_inventory_postrender.csv")
build_postqa <- read_evidence("build_inventory_postqa.csv")
add_check(
  "post-QA build inventory identity",
  paste(
    nrow(build_postqa),
    identical(build_postrender, build_postqa),
    sep = "/"
  ),
  "851/TRUE",
  nrow(build_postqa) == 851L && identical(build_postrender, build_postqa)
)

protected_postrender <- read_evidence("protected_inventory_postrender.csv")
protected_postqa <- read_evidence("protected_inventory_postqa.csv")
add_check(
  "post-QA protected inventory identity",
  paste(
    nrow(protected_postqa),
    identical(protected_postrender, protected_postqa),
    sep = "/"
  ),
  "276/TRUE",
  nrow(protected_postqa) == 276L &&
    identical(protected_postrender, protected_postqa)
)

symlink_files <- c(
  "build_symlink_inventory_prerender.csv",
  "build_symlink_inventory_postrender.csv",
  "build_symlink_inventory_postqa.csv"
)
symlink_rows <- vapply(
  symlink_files,
  function(filename) nrow(read_evidence(filename)),
  integer(1)
)
add_check(
  "build symlinks absent throughout",
  paste(symlink_rows, collapse = "/"),
  "0/0/0",
  identical(unname(symlink_rows), c(0L, 0L, 0L))
)

semantic_summary <- read_evidence("gt_html_semantic_post_render_summary.csv")
semantic_ledger <- read_evidence(
  paste0(
    "001__build__nathealth__audit__hypotheses__H08__",
    "H08_analysis_preparation.html_gt_semantic_ledger.csv"
  )
)
semantic_pass <- nrow(semantic_summary) == 1L &&
  semantic_summary$disposition[[1]] == "REPAIRED" &&
  semantic_summary$post_sha256[[1]] ==
    "cd0ce2210949559408d07bcbccac502d3b0a372b4229da70bdfc6dbe0c52f66b" &&
  semantic_summary$table_count[[1]] == 19L &&
  semantic_summary$id_count[[1]] == 193L &&
  semantic_summary$headers_count[[1]] == 878L &&
  semantic_summary$total_substitutions[[1]] == 1071L &&
  nrow(semantic_ledger) == 1071L
add_check(
  "semantic summary and ledger",
  paste(
    semantic_summary$table_count[[1]],
    semantic_summary$id_count[[1]],
    semantic_summary$headers_count[[1]],
    nrow(semantic_ledger),
    sep = "/"
  ),
  "19/193/878/1071",
  semantic_pass
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
  main_nodes,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
add_check(
  "native gt table count",
  length(table_nodes),
  19L,
  length(table_nodes) == 19L
)

tables <- pass_evidence[["table_endpoint_audit.csv"]]
figures <- pass_evidence[["figure_endpoint_audit.csv"]]
table_counts <- vapply(
  tables$endpoint,
  function(endpoint) {
    length(xml2::xml_find_all(doc, sprintf("//*[@id='%s']", endpoint)))
  },
  integer(1)
)
figure_counts <- vapply(
  figures$endpoint,
  function(endpoint) {
    length(xml2::xml_find_all(doc, sprintf("//*[@id='%s']", endpoint)))
  },
  integer(1)
)
add_check(
  "unique table endpoints",
  paste(table_counts, collapse = "/"),
  paste(rep(1L, 19L), collapse = "/"),
  identical(unname(table_counts), rep(1L, 19L))
)
add_check(
  "unique figure endpoints",
  paste(figure_counts, collapse = "/"),
  "1/1/1",
  identical(unname(figure_counts), rep(1L, 3L))
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
  "table header token count",
  length(header_tokens),
  1581L,
  length(header_tokens) == 1581L
)
add_check(
  "table header token resolution",
  header_resolution_pass,
  TRUE,
  header_resolution_pass
)

execution <- read_evidence("render_execution.csv")
render_execution <- execution[
  execution$operation == "companion_quarto_render",
  ,
  drop = FALSE
]
helper_execution <- execution[
  execution$operation == "preparation_manifest_helper",
  ,
  drop = FALSE
]
render_pass <- nrow(execution) == 2L &&
  nrow(render_execution) == 1L &&
  render_execution$attempts[[1]] == 1L &&
  render_execution$exit_status[[1]] == 0L &&
  render_execution$semantic_disposition[[1]] == "REPAIRED" &&
  render_execution$status[[1]] == "PASS"
helper_pass <- nrow(helper_execution) == 1L &&
  helper_execution$attempts[[1]] == 1L &&
  helper_execution$exit_status[[1]] == 0L &&
  helper_execution$output_sha256[[1]] ==
    "53264f81daed1b69ff8e78e7afcdab0e7d34b473ddb2f20b9f6820ffca5c1720" &&
  helper_execution$status[[1]] == "PASS"
add_check(
  "single render and helper execution",
  paste(
    render_execution$attempts[[1]],
    helper_execution$attempts[[1]],
    sep = "/"
  ),
  "1/1",
  render_pass && helper_pass
)

screenshot_manifest <- read_evidence("visual_screenshot_manifest.csv")
screenshot_paths <- file.path(evidence_dir, screenshot_manifest$file)
screenshot_exact <- file.exists(screenshot_paths) &
  vapply(screenshot_paths, file_bytes, numeric(1)) == screenshot_manifest$bytes
add_check(
  "visual screenshot evidence",
  paste0(sum(screenshot_exact), "/", nrow(screenshot_manifest)),
  "82/82",
  nrow(screenshot_manifest) == 82L && all(screenshot_exact)
)

typography <- pass_evidence[["figure_final_size_typography_audit.csv"]]
transition <- read_evidence("figure_visual_transition_audit.csv")
add_check(
  "170-mm typography floor",
  min(typography$effective_final_essential_text_pt),
  ">=7",
  min(typography$effective_final_essential_text_pt) >= 7
)
add_check(
  "single classified PNG transition",
  sum(transition$dispatch_sha256 != transition$fresh_sha256),
  1L,
  nrow(transition) == 3L &&
    sum(transition$dispatch_sha256 != transition$fresh_sha256) == 1L &&
    all(transition$status == "PASS") &&
    all(transition$visible_scientific_content_same)
)

loopback <- read_evidence("loopback_lifecycle.csv")
loopback_pass <- nrow(loopback) == 10L &&
  sum(loopback$status == "PASS") == 9L &&
  sum(loopback$status == "NO_SERVER_CREATED") == 1L &&
  loopback$status[loopback$event == "server_stop"] == "PASS" &&
  loopback$status[loopback$event == "listener_postcheck"] == "PASS"
add_check(
  "loopback lifecycle and teardown",
  paste0(sum(loopback$status == "PASS"), "/", nrow(loopback)),
  "9 PASS plus 1 no-server-created precheck",
  loopback_pass
)

checks$r_version <- as.character(getRversion())
checks$digest_version <- as.character(utils::packageVersion("digest"))
checks$xml2_version <- as.character(utils::packageVersion("xml2"))

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(checks, output_path, row.names = FALSE, na = "")

failures <- checks$status != "PASS"
if (any(failures)) {
  print(checks[failures, , drop = FALSE])
  stop("H08 order 55 independent companion acceptance failed")
}

cat(
  sprintf(
    paste0(
      "H08_ORDER55_COMPANION_INDEPENDENT_ACCEPTANCE=PASS checks=%d/%d ",
      "owner_manifest=%d/%d preparation_manifest=%d/%d tables=%d ",
      "figures=%d headers=%d semantic=19/193/878/1071 build=%d ",
      "protected=%d screenshots=%d R=%s digest=%s xml2=%s\n"
    ),
    nrow(checks),
    nrow(checks),
    sum(owner_audit$exact),
    owner_audit$rows,
    sum(preparation_audit$exact),
    preparation_audit$rows,
    length(table_nodes),
    length(figures$endpoint),
    length(header_tokens),
    nrow(build_postqa),
    nrow(protected_postqa),
    nrow(screenshot_manifest),
    as.character(getRversion()),
    as.character(utils::packageVersion("digest")),
    as.character(utils::packageVersion("xml2"))
  )
)
