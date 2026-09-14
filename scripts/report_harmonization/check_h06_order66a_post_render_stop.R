#!/usr/bin/env Rscript

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

stopifnot(identical(as.character(getRversion()), "4.6.1"))
required_packages <- c("digest", "xml2")
stopifnot(all(vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)))

sha256_file <- function(path) {
  digest::digest(
    path,
    file = TRUE,
    algo = "sha256",
    serialize = FALSE
  )
}

read_raw <- function(path) {
  size <- unname(file.info(path)$size)
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = size)
}

resolve_path <- function(path) {
  ifelse(startsWith(path, "/"), path, file.path(root, path))
}

evidence_rel <- paste0(
  "audit/hypotheses/H06/employment_eligibility_sensitivity/",
  "order66a_result_render"
)
evidence_dir <- file.path(root, evidence_rel)
record_path <- file.path(
  evidence_dir,
  "H06_order66a_post_render_verification_fail_closed.md"
)
manifest_path <- file.path(
  evidence_dir,
  "H06_order66a_fail_closed_manifest.csv"
)
failed_checks_path <- file.path(evidence_dir, "post_render_verification.csv")
failed_verifier_path <- file.path(evidence_dir, "post_render_verification.R")
html_rel <- "_build/nathealth/notebooks/hypotheses/H06.html"
html_path <- file.path(root, html_rel)

stopifnot(
  identical(
    sha256_file(record_path),
    "5518c7304ab65c1b750e3fe0a94f25cfc96895c034b325857517836f541589c9"
  ),
  unname(file.info(record_path)$size) == 6775,
  identical(
    sha256_file(manifest_path),
    "eee5e8cec499db98425811277ebd9bac8e11b31a2676b777a07919bd1781b471"
  ),
  unname(file.info(manifest_path)$size) == 6091,
  identical(
    sha256_file(failed_verifier_path),
    "d6de04cd4d88f1b63bb686348aa1d1c3ba9478ab3b584946a3b8ca6626d93d1b"
  ),
  identical(
    sha256_file(html_path),
    "b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9"
  ),
  unname(file.info(html_path)$size) == 4898662
)

manifest <- read.csv(
  manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(manifest) == 33L,
  !anyDuplicated(manifest$path),
  !manifest_path %in% resolve_path(manifest$path)
)
manifest_files <- vapply(manifest$path, resolve_path, character(1))
stopifnot(
  all(file.exists(manifest_files)),
  identical(
    unname(vapply(manifest_files, sha256_file, character(1))),
    unname(manifest$sha256)
  ),
  identical(
    as.numeric(unname(file.info(manifest_files)$size)),
    as.numeric(manifest$bytes)
  )
)

failed_checks <- read.csv(
  failed_checks_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
expected_failures <- c(
  "unique document ids",
  "table-scoped header resolution",
  "table endpoints and captions",
  "no local, source, or build-path reader links",
  "dispatch paths after render"
)
stopifnot(
  identical(
    failed_checks$check[failed_checks$status == "FAIL"],
    expected_failures
  ),
  all(failed_checks$status %in% c("PASS", "FAIL"))
)

html_raw <- read_raw(html_path)
post_doc <- xml2::read_html(rawToChar(html_raw))
main <- xml2::xml_find_all(post_doc, "//main[@id='quarto-document-content']")
stopifnot(length(main) == 1L)
main <- main[[1L]]

document_ids <- xml2::xml_attr(xml2::xml_find_all(post_doc, "//*[@id]"), "id")
stopifnot(
  !anyNA(document_ids),
  all(nzchar(document_ids)),
  !anyDuplicated(document_ids)
)

expected_tables <- c(
  "tbl-h06-primary-effects",
  "tbl-h06-primary-site-interactions",
  "tbl-h06-site-specific-associations",
  "tbl-h06-gap-sensitivity-comparisons",
  "tbl-h06-employment-eligibility-sensitivity",
  "tbl-h06-key-sensitivities",
  "tbl-h06-influence-checks",
  "tbl-h06-model-checks",
  "tbl-h06-exploratory-diary-associations",
  "tbl-h06-exploratory-two-part-formulas",
  "tbl-h06-exact-samples",
  "tbl-h06-exact-confirmatory-formulas",
  "tbl-h06-fdr-adjustment",
  "tbl-h06-figure-readability-checks"
)
native_tables <- xml2::xml_find_all(
  main,
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
stopifnot(length(native_tables) == length(expected_tables))

header_count <- 0L
for (index in seq_along(expected_tables)) {
  endpoint <- expected_tables[[index]]
  wrappers <- xml2::xml_find_all(main, paste0(".//*[@id='", endpoint, "']"))
  stopifnot(length(wrappers) == 1L)
  wrapper <- wrappers[[1L]]
  table <- xml2::xml_find_all(
    wrapper,
    paste0(
      ".//table[contains(concat(' ', normalize-space(@class), ' '),",
      " ' gt_table ')]"
    )
  )
  stopifnot(length(table) == 1L)
  table <- table[[1L]]
  table_ids <- xml2::xml_attr(
    xml2::xml_find_all(table, "self::*[@id] | .//*[@id]"),
    "id"
  )
  id_nodes <- xml2::xml_find_all(table, "self::*[@id] | .//*[@id]")
  header_values <- xml2::xml_attr(
    xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
    "headers"
  )
  tokens <- unlist(strsplit(header_values, "[[:space:]]+"), use.names = FALSE)
  tokens <- tokens[nzchar(tokens)]
  header_count <- header_count + length(tokens)
  stopifnot(
    length(tokens) > 0L,
    all(vapply(
      tokens,
      function(token) {
        positions <- which(table_ids == token)
        length(positions) == 1L &&
          identical(xml2::xml_name(id_nodes[[positions]]), "th")
      },
      logical(1)
    ))
  )
  captions <- xml2::xml_find_all(wrapper, ".//figcaption")
  stopifnot(
    length(captions) == 1L,
    nzchar(trimws(xml2::xml_text(captions[[1L]])))
  )
}
stopifnot(header_count == 421L)

hrefs <- xml2::xml_attr(xml2::xml_find_all(post_doc, "//a[@href]"), "href")
is_external <- grepl("^[A-Za-z][A-Za-z0-9+.-]*:", hrefs) |
  startsWith(hrefs, "//")
internal_hrefs <- hrefs[!is_external]
external_qmd_rows <- hrefs[is_external & grepl("[.]qmd($|#)", hrefs)]
external_qmd <- unique(external_qmd_rows)
stopifnot(
  !any(grepl("^file:", internal_hrefs)),
  !any(grepl("/Users/", internal_hrefs, fixed = TRUE)),
  !any(grepl("_build/", internal_hrefs, fixed = TRUE)),
  !any(grepl("[.]qmd($|#)", internal_hrefs)),
  length(external_qmd_rows) == 2L,
  length(external_qmd) == 1L,
  grepl("^https://github[.]com/", external_qmd[[1L]])
)

semantic_summary <- read.csv(
  file.path(evidence_dir, "gt_html_semantic_post_render_summary.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
semantic_ledger <- read.csv(
  file.path(evidence_dir, "H06_html_gt_semantic_ledger.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
engine <- new.env(parent = globalenv())
sys.source(
  file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
  envir = engine
)
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
stopifnot(
  nrow(semantic_summary) == 1L,
  semantic_summary$table_count[[1L]] == 14L,
  semantic_summary$id_count[[1L]] == 69L,
  semantic_summary$headers_count[[1L]] == 355L,
  semantic_summary$total_substitutions[[1L]] == 424L,
  nrow(semantic_ledger) == 424L,
  identical(
    engine$sha256_raw(reversed_raw),
    semantic_summary$pre_sha256[[1L]]
  ),
  identical(reapplied_raw, html_raw)
)
engine$verify_repaired_dom(
  rawToChar(reversed_raw),
  rawToChar(html_raw),
  semantic_ledger,
  14L
)

mutation_probe <- xml2::read_html(rawToChar(html_raw))
invisible(engine$normalized_dom_without_mutable_values(mutation_probe))
mutated_ids <- xml2::xml_attr(
  xml2::xml_find_all(mutation_probe, "//*[@id]"),
  "id"
)
stopifnot(sum(duplicated(mutated_ids)) == 68L)

dispatch <- read.csv(
  file.path(
    root,
    "audit/report_harmonization/report018_h06_order66a_dispatch_manifest.csv"
  ),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
dispatch_files <- vapply(dispatch$path, resolve_path, character(1))
dispatch_exists <- file.exists(dispatch_files)
dispatch_sha <- rep(NA_character_, nrow(dispatch))
dispatch_bytes <- rep(NA_real_, nrow(dispatch))
dispatch_sha[dispatch_exists] <- vapply(
  dispatch_files[dispatch_exists],
  sha256_file,
  character(1)
)
dispatch_bytes[dispatch_exists] <- unname(
  file.info(dispatch_files[dispatch_exists])$size
)
authorized_html <- dispatch$path == html_rel
stopifnot(
  nrow(dispatch) == 21L,
  sum(authorized_html) == 1L,
  all(dispatch_exists),
  identical(
    dispatch_sha[authorized_html],
    "b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9"
  ),
  dispatch_bytes[authorized_html] == 4898662,
  all(dispatch_sha[!authorized_html] == dispatch$sha256[!authorized_html]),
  all(dispatch_bytes[!authorized_html] == dispatch$bytes[!authorized_html])
)

sass_path <- "/Users/zauner/Library/Caches/quarto/sass/sass.kv"
stopifnot(
  file.exists(sass_path),
  unname(file.info(sass_path)$size) == 36864,
  identical(
    sha256_file(sass_path),
    "22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853"
  ),
  !file.exists(paste0(sass_path, "-wal")),
  !file.exists(paste0(sass_path, "-shm"))
)

build_delta <- read.csv(
  file.path(evidence_dir, "classified_build_delta.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
expected_delta <- c(
  paste0(
    "artifacts/06_model_data/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_sample_flow.csv"
  ),
  paste0(
    "artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_effect_comparison.csv"
  ),
  paste0(
    "artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_heterogeneity_comparison.csv"
  ),
  "notebooks/hypotheses/H06.html",
  "search.json",
  "sitemap.xml"
)
stopifnot(
  nrow(build_delta) == 6L,
  identical(sort(build_delta$path), sort(expected_delta)),
  all(build_delta$status[build_delta$path %in% expected_delta[1:3]] == "added"),
  all(
    build_delta$status[build_delta$path %in% expected_delta[4:6]] == "changed"
  )
)

sensitivity_manifest_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_report_manifest.csv"
  )
)
sensitivity_manifest <- read.csv(
  sensitivity_manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
sensitivity_files <- file.path(root, sensitivity_manifest$path)
stopifnot(
  nrow(sensitivity_manifest) == 46L,
  !anyDuplicated(sensitivity_manifest$path),
  !sensitivity_manifest_path %in% sensitivity_files,
  all(file.exists(sensitivity_files)),
  identical(
    unname(vapply(sensitivity_files, sha256_file, character(1))),
    unname(sensitivity_manifest$sha256)
  ),
  identical(
    as.numeric(unname(file.info(sensitivity_files)$size)),
    as.numeric(sensitivity_manifest$bytes)
  ),
  all(sensitivity_manifest$R_version == "4.6.1")
)

report_checks <- read.csv(
  file.path(
    root,
    paste0(
      "artifacts/12_manifests/H06/employment_eligibility_sensitivity/",
      "report_finalization/H06_employment_eligibility_report_verification.csv"
    )
  ),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(report_checks) == 31L,
  all(report_checks$status == "PASS")
)

cat(sprintf(
  paste0(
    "H06_ORDER66A_STOP=ACCEPTED manifest=33/33 failures=5/5 ",
    "document_ids=%d unique=PASS tables=14 headers=%d captions=14 ",
    "external_qmd=1 dispatch=21/21 build_delta=6 semantic=424 ",
    "sensitivity=46/46 report=31/31 R=%s\n"
  ),
  length(document_ids),
  header_count,
  as.character(getRversion())
))
