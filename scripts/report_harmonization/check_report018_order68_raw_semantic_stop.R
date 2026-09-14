#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop(
    "Usage: check_report018_order68_raw_semantic_stop.R <checks-csv>",
    call. = FALSE
  )
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("R 4.6.1 is required.", call. = FALSE)
}
for (package in c("digest", "xml2")) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(sprintf("The %s package is required.", package), call. = FALSE)
  }
}

project_root <- normalizePath(getwd(), mustWork = TRUE)
output_path <- args[[1L]]
if (!grepl("^/", output_path)) {
  output_path <- file.path(project_root, output_path)
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}
checks <- list()
record_check <- function(check_id, observed, expected, status = "PASS") {
  checks[[length(checks) + 1L]] <<- data.frame(
    check_id = check_id,
    observed = as.character(observed),
    expected = as.character(expected),
    status = status,
    stringsAsFactors = FALSE
  )
}
check_file <- function(path, sha256, bytes, check_id) {
  absolute <- file.path(project_root, path)
  assert_true(file.exists(absolute), sprintf("Missing file: %s", path))
  observed_sha <- sha256_file(absolute)
  observed_bytes <- unname(file.info(absolute)$size)
  assert_true(
    identical(observed_sha, sha256) &&
      identical(observed_bytes, as.numeric(bytes)),
    sprintf("Identity mismatch: %s", path)
  )
  record_check(
    check_id,
    sprintf("%s/%s", observed_sha, observed_bytes),
    sprintf("%s/%s", sha256, bytes)
  )
  invisible(absolute)
}
has_class <- function(name) {
  sprintf("contains(concat(' ', normalize-space(@class), ' '), ' %s ')", name)
}

raw_html <- check_file(
  "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html",
  "c9156f078af52713a71a58adda545e03687a8b206d164d4d548b93ebae9732ee",
  30864003,
  "raw_html"
)
failed_copy <- check_file(
  paste0(
    "audit/manuscript_nature_health/final_production_render_2026_09_02/",
    "failed_render_ZaunerEtAl2026_NatHealth_phase3_brown.html"
  ),
  "c9156f078af52713a71a58adda545e03687a8b206d164d4d548b93ebae9732ee",
  30864003,
  "raw_html_evidence_copy"
)
raw_docx <- check_file(
  "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx",
  "b8eeca31794e06c7c2ec2d6a474ae812b77b2b8c2dcadf7d341e3b6178430cdd",
  9872181,
  "raw_docx"
)
raw_docx_copy <- check_file(
  paste0(
    "audit/manuscript_nature_health/final_production_render_2026_09_02/",
    "raw_quarto_ZaunerEtAl2026_NatHealth_phase3_brown.docx"
  ),
  "b8eeca31794e06c7c2ec2d6a474ae812b77b2b8c2dcadf7d341e3b6178430cdd",
  9872181,
  "raw_docx_evidence_copy"
)
check_file(
  paste0(
    "audit/manuscript_nature_health/final_production_render_2026_09_02/",
    "preimage_ZaunerEtAl2026_NatHealth_phase3_brown.html"
  ),
  "498bc0ad5e9d08841f48411e290ae7ec8912a7af89c8fa8397c44d3f46864d99",
  30528489,
  "html_preimage"
)
check_file(
  paste0(
    "audit/manuscript_nature_health/final_production_render_2026_09_02/",
    "preimage_ZaunerEtAl2026_NatHealth_phase3_brown.docx"
  ),
  "d3ffb9abb583d91d4dffffea69fce870987b59494c76c462f9dfa53b1bf53a02",
  52450,
  "docx_preimage"
)
repair_script <- check_file(
  paste0(
    "audit/manuscript_nature_health/final_serial_render_2026_09_01/",
    "repair_mixed_gt_semantics.R"
  ),
  "30fe707420758a2f0207c4601bb8343e3d63ae2b1bf6965aa05469283af8f0b1",
  7275,
  "historical_repair_script"
)
engine_path <- check_file(
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
  17747,
  "semantic_engine"
)
validator_path <- check_file(
  paste0(
    "audit/manuscript_nature_health/final_production_render_2026_09_02/",
    "verify_final_html.R"
  ),
  "285c0edaa3b98eb7fffa298b4f50fd76fb47daa266f156b0407730d28ea1804c",
  6522,
  "stopped_validator"
)

assert_true(
  identical(
    readBin(raw_html, "raw", n = file.info(raw_html)$size),
    readBin(failed_copy, "raw", n = file.info(failed_copy)$size)
  ),
  "The raw HTML and its evidence copy differ."
)
assert_true(
  identical(
    readBin(raw_docx, "raw", n = file.info(raw_docx)$size),
    readBin(raw_docx_copy, "raw", n = file.info(raw_docx_copy)$size)
  ),
  "The raw DOCX and its evidence copy differ."
)
record_check(
  "raw_evidence_copies",
  "HTML and DOCX exact",
  "HTML and DOCX exact"
)

raw_document <- xml2::read_html(raw_html)
raw_ids <- xml2::xml_attr(xml2::xml_find_all(raw_document, "//*[@id]"), "id")
duplicates <- sort(unique(raw_ids[
  duplicated(raw_ids) | duplicated(raw_ids, fromLast = TRUE)
]))
expected_duplicates <- sort(c("a::stub", paste0("stub_1_", seq_len(7L))))
assert_true(
  identical(duplicates, expected_duplicates),
  "The raw duplicate-ID set is not the accepted eight-ID set."
)
assert_true(
  all(vapply(duplicates, function(id) sum(raw_ids == id) == 2L, logical(1))),
  "A raw duplicate ID does not occur exactly twice."
)
record_check("raw_duplicate_ids", length(duplicates), 8)

candidate_dir <- tempfile("order68-independent-semantic-")
dir.create(candidate_dir, recursive = FALSE, showWarnings = FALSE)
assert_true(
  dir.exists(candidate_dir),
  "Could not create the temporary candidate directory."
)
on.exit(unlink(candidate_dir, recursive = TRUE, force = TRUE), add = TRUE)
candidate_path <- file.path(candidate_dir, "candidate.html")
ledger_path <- file.path(candidate_dir, "ledger.csv")
repair_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", repair_script, raw_html, candidate_path, ledger_path),
  stdout = TRUE,
  stderr = TRUE
)
repair_status <- attr(repair_output, "status")
if (is.null(repair_status)) repair_status <- 0L
assert_true(
  identical(as.integer(repair_status), 0L),
  paste(
    c("The historical semantic repair failed:", repair_output),
    collapse = "\n"
  )
)
assert_true(
  any(grepl("MIXED_GT_SEMANTIC_REPAIR=PASS", repair_output, fixed = TRUE)),
  "The historical semantic repair did not emit its PASS token."
)
assert_true(
  identical(
    sha256_file(candidate_path),
    "8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac"
  ) &&
    identical(unname(file.info(candidate_path)$size), 30881505),
  "The independent semantic candidate identity differs."
)
assert_true(
  identical(
    sha256_file(ledger_path),
    "225b5d37818850dca9b6cb5dcf39d78e5fd76c1e79745bbf09f981a70a980287"
  ) &&
    identical(unname(file.info(ledger_path)$size), 70290),
  "The independent semantic ledger identity differs."
)
record_check(
  "semantic_candidate",
  sprintf("%s/%s", sha256_file(candidate_path), file.info(candidate_path)$size),
  "8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac/30881505"
)
record_check(
  "semantic_ledger",
  sprintf("%s/%s", sha256_file(ledger_path), file.info(ledger_path)$size),
  "225b5d37818850dca9b6cb5dcf39d78e5fd76c1e79745bbf09f981a70a980287/70290"
)

ledger <- utils::read.csv(
  ledger_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
target_endpoints <- c(
  "tbl-plan-h01-metric-synthesis-candidate",
  "tbl-plan-person-level-synthesis-gt-candidate"
)
assert_true(
  nrow(ledger) == 191L &&
    sum(ledger$attribute == "id") == 47L &&
    sum(ledger$attribute == "headers") == 144L &&
    identical(sort(unique(ledger$table_endpoint)), sort(target_endpoints)),
  "The semantic ledger shape or target set differs."
)
record_check("semantic_ledger_contract", "191/47/144/2", "191/47/144/2")

engine <- new.env(parent = globalenv())
sys.source(engine_path, envir = engine)
raw_bytes <- engine$read_file_raw(raw_html)
candidate_bytes <- engine$read_file_raw(candidate_path)
reversed_bytes <- engine$apply_raw_replacements(
  candidate_bytes,
  ledger,
  reverse = TRUE
)
assert_true(
  identical(reversed_bytes, raw_bytes),
  "The semantic ledger does not reverse exactly to the raw HTML."
)
raw_dom <- engine$normalized_dom_without_mutable_values(raw_document)
candidate_document <- xml2::read_html(candidate_path)
candidate_dom <- engine$normalized_dom_without_mutable_values(
  candidate_document
)
assert_true(
  identical(raw_dom, candidate_dom),
  "The semantic candidate changes non-ID or non-headers DOM content."
)
record_check(
  "semantic_reverse_and_dom",
  sha256_file(raw_html),
  sha256_file(raw_html)
)

candidate_document <- xml2::read_html(candidate_path)
main <- xml2::xml_find_all(
  candidate_document,
  "//main[@id='quarto-document-content']"
)
assert_true(
  length(main) == 1L,
  "The candidate lacks one unique manuscript main element."
)
candidate_ids <- xml2::xml_attr(
  xml2::xml_find_all(candidate_document, "//*[@id]"),
  "id"
)
assert_true(
  !anyNA(candidate_ids) && !anyDuplicated(candidate_ids),
  "The candidate contains a missing or duplicate ID."
)
record_check("candidate_document_ids", length(candidate_ids), 582)

expected_figures <- c(
  "fig-study-overview",
  "fig-daily-architecture",
  "fig-activity-context",
  paste0("fig-s", seq_len(17L))
)
figure_endpoints <- xml2::xml_find_all(main, ".//*[@id]")
figure_endpoint_ids <- xml2::xml_attr(figure_endpoints, "id")
figures <- figure_endpoints[figure_endpoint_ids %in% expected_figures]
figure_ids <- xml2::xml_attr(figures, "id")
assert_true(
  identical(figure_ids, expected_figures),
  "The candidate figure endpoint order differs."
)
assert_true(
  all(vapply(
    figures,
    function(x) length(xml2::xml_find_all(x, ".//img")) == 1L,
    logical(1)
  )),
  "A candidate figure does not contain exactly one image."
)
assert_true(
  all(vapply(
    figures,
    function(x) length(xml2::xml_find_all(x, ".//figcaption")) >= 1L,
    logical(1)
  )),
  "A candidate figure lacks a caption."
)
figure_alts <- vapply(
  figures,
  function(x) xml2::xml_attr(xml2::xml_find_first(x, ".//img"), "alt"),
  character(1)
)
assert_true(
  all(!is.na(figure_alts) & nzchar(trimws(figure_alts))),
  "A candidate figure lacks alt text."
)
record_check("candidate_figures", length(figures), 20)

tables <- xml2::xml_find_all(
  main,
  paste0(".//table[", has_class("gt_table"), "]")
)
assert_true(
  length(tables) == 19L,
  "The candidate does not contain 19 gt tables."
)
header_tokens <- 0L
for (table in tables) {
  table_ids <- xml2::xml_attr(xml2::xml_find_all(table, ".//th[@id]"), "id")
  header_values <- xml2::xml_attr(
    xml2::xml_find_all(table, ".//*[@headers]"),
    "headers"
  )
  for (value in header_values) {
    tokens <- strsplit(value, "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    assert_true(
      length(tokens) > 0L &&
        all(vapply(
          tokens,
          function(token) sum(table_ids == token) == 1L,
          logical(1)
        )),
      "A candidate table-header token is unresolved or nonunique."
    )
    header_tokens <- header_tokens + length(tokens)
  }
}
assert_true(header_tokens == 2762L, "The candidate header-token count differs.")
record_check("candidate_tables_and_headers", "19/2762", "19/2762")

fragment_hrefs <- xml2::xml_attr(
  xml2::xml_find_all(main, ".//a[starts-with(@href, '#')]"),
  "href"
)
fragment_ids <- sub("^#", "", fragment_hrefs)
fragment_ids <- fragment_ids[nzchar(fragment_ids)]
assert_true(
  length(fragment_ids) == 124L,
  "The internal-fragment count differs."
)
assert_true(
  all(vapply(
    fragment_ids,
    function(id) sum(candidate_ids == id) == 1L,
    logical(1)
  )),
  "An internal fragment is unresolved or nonunique."
)
record_check("candidate_internal_fragments", length(fragment_ids), 124)

image_sources <- xml2::xml_attr(
  xml2::xml_find_all(candidate_document, "//img[@src]"),
  "src"
)
assert_true(
  all(startsWith(image_sources, "data:image/")),
  "The candidate has a non-embedded image."
)
embedded_resources <- c(
  xml2::xml_attr(
    xml2::xml_find_all(candidate_document, "//script[@src]"),
    "src"
  ),
  xml2::xml_attr(
    xml2::xml_find_all(candidate_document, "//link[@rel='stylesheet'][@href]"),
    "href"
  )
)
embedded_resources <- embedded_resources[
  !is.na(embedded_resources) & nzchar(embedded_resources)
]
assert_true(
  length(embedded_resources) > 0L &&
    all(startsWith(embedded_resources, "data:")),
  "The candidate has a non-embedded script or stylesheet."
)
record_check(
  "candidate_self_contained_resources",
  sprintf(
    "images=%d resources=%d",
    length(image_sources),
    length(embedded_resources)
  ),
  sprintf("images=%d all-data-uris", length(image_sources))
)

validator_code <- readChar(
  validator_path,
  nchars = file.info(validator_path)$size,
  useBytes = TRUE
)
old_figures <- paste(
  c(
    "figures <- xml2::xml_find_all(",
    "  main,",
    "  \".//figure[@id and starts-with(@id, 'fig-')]\"",
    ")",
    "figure_ids <- xml2::xml_attr(figures, \"id\")"
  ),
  collapse = "\n"
)
new_figures <- paste(
  c(
    "figure_endpoint_nodes <- xml2::xml_find_all(main, \".//*[@id]\")",
    "figure_endpoint_ids <- xml2::xml_attr(figure_endpoint_nodes, \"id\")",
    "figures <- figure_endpoint_nodes[figure_endpoint_ids %in% expected_figures]",
    "figure_ids <- xml2::xml_attr(figures, \"id\")"
  ),
  collapse = "\n"
)
old_resources <- paste0(
  "assert_true(length(external_resources) == 0L, ",
  "\"The HTML contains a non-embedded script or stylesheet.\")"
)
new_resources <- paste(
  c(
    "assert_true(",
    "  all(startsWith(external_resources, \"data:\")),",
    "  \"The HTML contains a non-embedded script or stylesheet.\"",
    ")"
  ),
  collapse = "\n"
)
assert_true(
  grepl(old_figures, validator_code, fixed = TRUE),
  "The stopped figure-selector hunk is absent."
)
assert_true(
  grepl(old_resources, validator_code, fixed = TRUE),
  "The stopped embedded-resource hunk is absent."
)
prospective_validator <- sub(
  old_figures,
  new_figures,
  validator_code,
  fixed = TRUE
)
prospective_validator <- sub(
  old_resources,
  new_resources,
  prospective_validator,
  fixed = TRUE
)
prospective_sha <- digest::digest(
  charToRaw(prospective_validator),
  algo = "sha256",
  serialize = FALSE
)
prospective_bytes <- nchar(prospective_validator, type = "bytes")
assert_true(
  identical(
    prospective_sha,
    "7054f6da946edf858813378017dd606283dbdf0816e2bc41a8f7237fd681c55c"
  ) &&
    identical(prospective_bytes, 6657L),
  "The prospective two-hunk validator identity differs."
)
invisible(parse(text = prospective_validator))
record_check(
  "prospective_validator",
  sprintf("%s/%d", prospective_sha, prospective_bytes),
  "7054f6da946edf858813378017dd606283dbdf0816e2bc41a8f7237fd681c55c/6657"
)

checks_frame <- do.call(rbind, checks)
assert_true(
  !anyDuplicated(checks_frame$check_id),
  "Check identifiers are duplicated."
)
assert_true(
  all(checks_frame$status == "PASS"),
  "A recorded check did not pass."
)
utils::write.csv(checks_frame, output_path, row.names = FALSE, na = "")

cat(sprintf(
  paste0(
    "REPORT018_ORDER68_RAW_SEMANTIC_STOP=PASS checks=%d duplicate_ids=8 ",
    "candidate=%s ledger=191 figures=20 tables=19 headers=2762 fragments=124 ",
    "prospective_validator=%s R=%s\n"
  ),
  nrow(checks_frame),
  sha256_file(candidate_path),
  prospective_sha,
  as.character(getRversion())
))
