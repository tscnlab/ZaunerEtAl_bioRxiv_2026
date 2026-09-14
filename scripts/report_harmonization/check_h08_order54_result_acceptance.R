#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_rel <- "audit/hypotheses/H08/report018_order54_result_render"
evidence_dir <- file.path(root, evidence_rel)
manifest_rel <- file.path(evidence_rel, "order54_evidence_manifest.csv")
manifest_path <- file.path(root, manifest_rel)
html_rel <- "_build/nathealth/notebooks/hypotheses/H08.html"
html_path <- file.path(root, html_rel)
output_rel <-
  "audit/report_harmonization/report018_h08_result_independent_verification.csv"
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
add_check("owner manifest rows", nrow(manifest), 174L, nrow(manifest) == 174L)
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
  file.path(evidence_rel, "ORDER54_COMPLETION.md"),
  "d2594bd1b63cac66ead98c378cdc05686fc79cc9c4988ec523c60d330c39b15d",
  7062
)
require_file(
  manifest_rel,
  "f89ae6a67f8f2c965ce8d4e071c7d826973a9d791e4f382a7f0c1b8a518ee829",
  30043
)
require_file(
  "notebooks/hypotheses/H08.qmd",
  "1b6b50b21e22d60909a65b125ce74be54829e5efc10de33f888fcd294c7374b1",
  44031
)
require_file(
  html_rel,
  "472848d0da3e3996fa1727151048e3cab4a7e363dba3dc8eda8b024eb5a4ca9a",
  340040
)
require_file(
  "audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d",
  57777
)
require_file(
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html",
  "95f5ba0aede0ee6cf0d1b65fcdc53623d52810f8316c846cb214b4fb34a5f135",
  675700
)
require_file(
  "_quarto-nathealth.yml",
  "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  7480
)
require_file(
  "tests/hypotheses/H08/test_h08_stage3_reader_report.R",
  "3049ecd80bc7f6c83dce7370b2877a92c6693dd9585f1f45ed7ac19fdf64be8f",
  18954
)
require_file(
  "tests/hypotheses/H08/test_h08_preparation_report.R",
  "2e83542b120021e0c337a3769127e6eba2fe61ebc4d56014693b34066a3fc2a4",
  13024
)
require_file(
  "artifacts/12_manifests/H08/H08_stage3_artifacts.csv",
  "e8dcec4bfdaf129002c875681f22b0f9d226ebbc95f706309c98ae4e21244af2",
  23368
)
require_file(
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
  11937
)

render <- all_pass("render_console_classification.csv", 5L)
nonvisual <- all_pass("nonvisual_status.csv", 16L)
tables <- all_pass("table_endpoint_audit.csv", 15L)
figures <- all_pass("figure_endpoint_audit.csv", 5L)
formulas <- all_pass("formula_table_audit.csv", 9L)
headers <- all_pass("table_header_reference_audit.csv", 864L)
semantic_reverse <- all_pass("semantic_reverse_audit.csv", 6L)
semantic_invariance <- all_pass("semantic_invariance_audit.csv", 7L)
dynamic_links <- all_pass("dynamic_link_audit.csv", 4L)
reader_links <- all_pass("reader_link_audit.csv", 26L)
visual <- all_pass("visual_qa_status.csv", 13L)
figure_typography <- all_pass("figure_final_size_typography_audit.csv", 5L)
phase4 <- all_pass("phase4_manifest_transition.csv", 1L)
build_delta <- all_pass("build_delta_postrender.csv", 3L)
protected_delta <- all_pass("protected_reconciliation_postrender.csv", 153L)
postqa <- all_pass("postqa_rehash_reconciliation.csv", 2L)
source_freeze <- all_pass("final_source_freeze_audit.csv", 7L)

stage3 <- read_evidence("stage3_manifest_postrender_audit.csv")
stage3_pass <- nrow(stage3) == 102L &&
  sum(stage3$exact) == 99L &&
  sum(stage3$classification == "expected historical-to-fresh transition") ==
    3L &&
  all(
    stage3$classification %in%
      c(
        "live-exact",
        "expected historical-to-fresh transition"
      )
  )
add_check(
  "historical Stage 3 manifest classification",
  paste0(
    sum(stage3$exact),
    "/",
    nrow(stage3),
    "; transitions=",
    sum(!stage3$exact)
  ),
  "99/102; transitions=3",
  stage3_pass
)

build_postrender <- read_evidence("build_inventory_postrender.csv")
build_postqa <- read_evidence("build_inventory_postqa.csv")
add_check(
  "post-QA build inventory identity",
  paste(
    nrow(build_postqa),
    sha256_file(file.path(evidence_dir, "build_inventory_postqa.csv")),
    sep = "/"
  ),
  paste(
    851L,
    sha256_file(file.path(evidence_dir, "build_inventory_postrender.csv")),
    sep = "/"
  ),
  nrow(build_postrender) == 851L &&
    identical(build_postrender, build_postqa)
)

protected_postrender <- read_evidence("protected_inventory_postrender.csv")
protected_postqa <- read_evidence("protected_inventory_postqa.csv")
add_check(
  "post-QA protected inventory identity",
  paste(
    nrow(protected_postqa),
    sha256_file(file.path(evidence_dir, "protected_inventory_postqa.csv")),
    sep = "/"
  ),
  paste(
    153L,
    sha256_file(file.path(evidence_dir, "protected_inventory_postrender.csv")),
    sep = "/"
  ),
  nrow(protected_postrender) == 153L &&
    identical(protected_postrender, protected_postqa)
)

symlink_files <- c(
  "build_symlink_inventory_prerender.csv",
  "build_symlink_inventory_postrender.csv",
  "build_symlink_inventory_postqa.csv"
)
symlink_rows <- vapply(
  symlink_files,
  function(filename) {
    nrow(read_evidence(filename))
  },
  integer(1)
)
add_check(
  "build symlinks absent throughout",
  paste(symlink_rows, collapse = "/"),
  "0/0/0",
  identical(unname(symlink_rows), c(0L, 0L, 0L))
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
  15L,
  length(table_nodes) == 15L
)

expected_table_ids <- tables$endpoint
observed_table_counts <- vapply(
  expected_table_ids,
  function(endpoint) {
    length(xml2::xml_find_all(doc, sprintf("//*[@id='%s']", endpoint)))
  },
  integer(1)
)
add_check(
  "unique table endpoints",
  paste(observed_table_counts, collapse = "/"),
  paste(rep(1L, 15L), collapse = "/"),
  identical(unname(observed_table_counts), rep(1L, 15L))
)

expected_figure_ids <- figures$endpoint
observed_figure_counts <- vapply(
  expected_figure_ids,
  function(endpoint) {
    length(xml2::xml_find_all(doc, sprintf("//*[@id='%s']", endpoint)))
  },
  integer(1)
)
add_check(
  "unique figure endpoints",
  paste(observed_figure_counts, collapse = "/"),
  paste(rep(1L, 5L), collapse = "/"),
  identical(unname(observed_figure_counts), rep(1L, 5L))
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
  864L,
  length(header_tokens) == 864L
)
add_check(
  "table header token resolution",
  header_resolution_pass,
  TRUE,
  header_resolution_pass
)

render_execution <- read_evidence("render_execution.csv")
render_pass <- nrow(render_execution) == 1L &&
  render_execution$attempts[[1]] == 1L &&
  render_execution$exit_status[[1]] == 0L &&
  render_execution$r_version[[1]] == "4.6.1" &&
  render_execution$quarto_version[[1]] == "1.9.37" &&
  render_execution$semantic_disposition[[1]] == "REPAIRED" &&
  render_execution$semantic_id_substitutions[[1]] == 86L &&
  render_execution$semantic_header_substitutions[[1]] == 855L &&
  render_execution$semantic_total_substitutions[[1]] == 941L &&
  !render_execution$rerendered[[1]] &&
  render_execution$status[[1]] == "PASS"
add_check(
  "single render execution",
  paste(
    render_execution$attempts[[1]],
    render_execution$exit_status[[1]],
    render_execution$semantic_total_substitutions[[1]],
    sep = "/"
  ),
  "1/0/941",
  render_pass
)

screenshot_manifest <- read_evidence("visual_screenshot_manifest.csv")
screenshot_paths <- file.path(evidence_dir, screenshot_manifest$file)
screenshot_exact <- file.exists(screenshot_paths) &
  vapply(screenshot_paths, file_bytes, numeric(1)) == screenshot_manifest$bytes
add_check(
  "visual screenshot evidence",
  paste0(sum(screenshot_exact), "/", nrow(screenshot_manifest)),
  "74/74",
  nrow(screenshot_manifest) == 74L && all(screenshot_exact)
)

add_check(
  "170-mm typography floor",
  min(figure_typography$effective_final_essential_text_pt),
  ">=7",
  min(figure_typography$effective_final_essential_text_pt) >= 7
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
  stop("H08 order 54 independent result acceptance failed")
}

cat(
  sprintf(
    paste0(
      "H08_ORDER54_RESULT_INDEPENDENT_ACCEPTANCE=PASS checks=%d/%d ",
      "owner_manifest=%d/%d tables=%d figures=%d headers=%d ",
      "build=%d protected=%d screenshots=%d semantic=15/86/855/941 ",
      "R=%s digest=%s xml2=%s\n"
    ),
    nrow(checks),
    nrow(checks),
    sum(manifest_exact),
    nrow(manifest),
    length(table_nodes),
    length(expected_figure_ids),
    length(header_tokens),
    nrow(build_postqa),
    nrow(protected_postqa),
    nrow(screenshot_manifest),
    as.character(getRversion()),
    as.character(utils::packageVersion("digest")),
    as.character(utils::packageVersion("xml2"))
  )
)
