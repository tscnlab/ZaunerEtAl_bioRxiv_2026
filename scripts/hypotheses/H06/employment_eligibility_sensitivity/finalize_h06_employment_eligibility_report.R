suppressPackageStartupMessages({
  library(digest)
  library(gt)
  library(xml2)
})

assert_condition <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

locate_project_root <- function(start = getwd()) {
  candidate <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(candidate, "renv.lock")) &&
        file.exists(file.path(candidate, "_quarto.yml"))
    ) {
      return(candidate)
    }
    parent <- dirname(candidate)
    if (identical(parent, candidate)) {
      stop("Could not locate the project root", call. = FALSE)
    }
    candidate <- parent
  }
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

project_root <- locate_project_root()
arguments <- commandArgs(trailingOnly = TRUE)
assert_condition(
  length(arguments) == 1L,
  "Supply exactly one existing candidate directory outside the project."
)

candidate_dir <- normalizePath(
  arguments[[1L]],
  winslash = "/",
  mustWork = TRUE
)
assert_condition(
  !startsWith(candidate_dir, paste0(project_root, "/")),
  "The semantic candidate directory must be outside the project."
)
assert_condition(
  identical(as.character(getRversion()), "4.6.1"),
  "Semantic finalization requires R 4.6.1."
)
assert_condition(
  identical(as.character(packageVersion("gt")), "1.3.0"),
  "Semantic finalization requires gt 1.3.0."
)

relative_html <- file.path(
  "audit",
  "hypotheses",
  "H06",
  "employment_eligibility_sensitivity",
  "H06_employment_eligibility_sensitivity.html"
)
relative_qmd <- sub("[.]html$", ".qmd", relative_html)
html_path <- file.path(project_root, relative_html)
qmd_path <- file.path(project_root, relative_qmd)
engine_path <- file.path(
  project_root,
  "scripts",
  "report_harmonization",
  "repair_gt_html_semantics.R"
)
evidence_dir <- file.path(
  project_root,
  "artifacts",
  "12_manifests",
  "H06",
  "employment_eligibility_sensitivity",
  "report_finalization"
)
raw_copy_path <- file.path(
  evidence_dir,
  "H06_employment_eligibility_sensitivity_raw.html"
)
ledger_path <- file.path(
  evidence_dir,
  "H06_employment_eligibility_gt_semantic_ledger.csv"
)
summary_path <- file.path(
  evidence_dir,
  "H06_employment_eligibility_semantic_summary.csv"
)
invariance_path <- file.path(
  evidence_dir,
  "H06_employment_eligibility_semantic_invariance.csv"
)
candidate_path <- file.path(
  candidate_dir,
  "H06_employment_eligibility_sensitivity_semantic_candidate.html"
)

expected_raw_sha256 <-
  "1f2f3cf75fff0200c5653763676cd92d9a6139d05e8095979764f9bfdafc394c"
expected_qmd_sha256 <-
  "199808d90b0c282b64fe5fba4706bec4845f8f79a73e4365c471cb05ada4e80f"
expected_engine_sha256 <-
  "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1"

assert_condition(file.exists(html_path), "Rendered HTML is missing.")
assert_condition(file.exists(qmd_path), "Sensitivity QMD is missing.")
assert_condition(file.exists(engine_path), "Accepted semantic engine is missing.")
assert_condition(
  identical(sha256_file(html_path), expected_raw_sha256),
  "Rendered HTML does not match the accepted raw identity."
)
assert_condition(
  identical(sha256_file(qmd_path), expected_qmd_sha256),
  "Sensitivity QMD changed after the render."
)
assert_condition(
  identical(sha256_file(engine_path), expected_engine_sha256),
  "The accepted semantic engine identity changed."
)
assert_condition(
  !file.exists(raw_copy_path) &&
    !file.exists(ledger_path) &&
    !file.exists(summary_path) &&
    !file.exists(invariance_path) &&
    !file.exists(candidate_path),
  "Semantic finalization outputs must not exist before the one execution."
)

dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)
assert_condition(
  file.copy(html_path, raw_copy_path, overwrite = FALSE),
  "Could not preserve the raw rendered HTML."
)
assert_condition(
  identical(sha256_file(raw_copy_path), expected_raw_sha256),
  "The raw evidence copy does not reproduce the rendered identity."
)

source(engine_path, local = FALSE)
repair_summary <- repair_gt_html_semantics(
  input_path = raw_copy_path,
  output_path = candidate_path,
  ledger_path = ledger_path
)

raw_bytes <- read_file_raw(raw_copy_path)
candidate_bytes <- read_file_raw(candidate_path)
ledger <- utils::read.csv(
  ledger_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
raw_document <- xml2::read_html(rawToChar(raw_bytes))
candidate_document <- xml2::read_html(rawToChar(candidate_bytes))
table_xpath <- paste0(
  ".//table[contains(concat(' ', normalize-space(@class), ' '),",
  " ' gt_table ')]"
)
candidate_tables <- xml2::xml_find_all(candidate_document, table_xpath)
all_ids <- xml2::xml_attr(
  xml2::xml_find_all(candidate_document, ".//*[@id]"),
  "id"
)
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]

headers_resolve <- all(vapply(
  candidate_tables,
  function(table) {
    table_ids <- xml2::xml_attr(
      xml2::xml_find_all(table, "self::*[@id] | .//*[@id]"),
      "id"
    )
    table_id_nodes <- xml2::xml_find_all(
      table,
      "self::*[@id] | .//*[@id]"
    )
    values <- xml2::xml_attr(
      xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
      "headers"
    )
    if (length(values) == 0L) {
      return(TRUE)
    }
    all(vapply(
      values,
      function(value) {
        tokens <- strsplit(value, "[[:space:]]+")[[1L]]
        positions <- match(tokens, table_ids)
        !anyNA(positions) &&
          all(vapply(
            tokens,
            function(token) sum(table_ids == token) == 1L,
            logical(1)
          )) &&
          all(xml2::xml_name(table_id_nodes[positions]) == "th")
      },
      logical(1)
    ))
  },
  logical(1)
))

raw_links <- xml2::xml_attrs(
  xml2::xml_find_all(raw_document, ".//*[@href or @src]")
)
candidate_links <- xml2::xml_attrs(
  xml2::xml_find_all(candidate_document, ".//*[@href or @src]")
)
reversed_bytes <- apply_raw_replacements(
  candidate_bytes,
  ledger,
  reverse = TRUE
)

invariance <- data.frame(
  check = c(
    "raw_identity",
    "native_gt_table_count",
    "global_document_ids_unique",
    "headers_resolve_once_within_table",
    "visible_text_unchanged",
    "href_and_src_attributes_unchanged",
    "non_id_headers_dom_unchanged",
    "exact_reverse_to_raw",
    "unsupported_id_references_absent"
  ),
  observed = c(
    sha256_raw(raw_bytes),
    as.character(length(candidate_tables)),
    as.character(!anyDuplicated(all_ids)),
    as.character(headers_resolve),
    as.character(identical(
      xml2::xml_text(raw_document),
      xml2::xml_text(candidate_document)
    )),
    as.character(identical(raw_links, candidate_links)),
    as.character(identical(
      normalized_dom_without_mutable_values(raw_document),
      normalized_dom_without_mutable_values(candidate_document)
    )),
    sha256_raw(reversed_bytes),
    as.character(repair_summary$unsupported_id_references)
  ),
  expected = c(
    expected_raw_sha256,
    "9",
    "TRUE",
    "TRUE",
    "TRUE",
    "TRUE",
    "TRUE",
    expected_raw_sha256,
    "0"
  ),
  stringsAsFactors = FALSE
)
invariance$status <- ifelse(
  invariance$observed == invariance$expected,
  "PASS",
  "FAIL"
)

assert_condition(
  all(invariance$status == "PASS"),
  paste(
    "Semantic candidate invariance failed:",
    paste(invariance$check[invariance$status == "FAIL"], collapse = ", ")
  )
)
assert_condition(
  identical(repair_summary$table_count, 9L),
  "The semantic candidate does not contain exactly nine gt tables."
)
assert_condition(
  repair_summary$id_substitutions > 0L &&
    repair_summary$headers_substitutions > 0L,
  "The candidate did not repair both ID and headers attributes."
)

candidate_sha256 <- sha256_file(candidate_path)
assert_condition(
  file.copy(candidate_path, html_path, overwrite = TRUE),
  "Could not promote the verified semantic candidate."
)
assert_condition(
  identical(sha256_file(html_path), candidate_sha256),
  "The promoted HTML does not match the verified candidate."
)

summary <- data.frame(
  item = c(
    "scenario_id",
    "R_version",
    "gt_version",
    "xml2_version",
    "digest_version",
    "raw_html_sha256",
    "semantic_html_sha256",
    "exact_reverse_sha256",
    "raw_html_bytes",
    "semantic_html_bytes",
    "native_gt_tables",
    "id_substitutions",
    "headers_substitutions",
    "total_substitutions",
    "unsupported_id_references",
    "promotion_count"
  ),
  value = c(
    "H06-S-EMP-NE",
    as.character(getRversion()),
    as.character(packageVersion("gt")),
    as.character(packageVersion("xml2")),
    as.character(packageVersion("digest")),
    repair_summary$input_sha256,
    candidate_sha256,
    repair_summary$reversed_sha256,
    repair_summary$input_bytes,
    repair_summary$output_bytes,
    repair_summary$table_count,
    repair_summary$id_substitutions,
    repair_summary$headers_substitutions,
    repair_summary$total_substitutions,
    repair_summary$unsupported_id_references,
    1L
  ),
  stringsAsFactors = FALSE
)

utils::write.csv(invariance, invariance_path, row.names = FALSE, na = "")
utils::write.csv(summary, summary_path, row.names = FALSE, na = "")

cat(sprintf(
  paste0(
    "H06-S-EMP-NE semantic finalization PASS: %d tables; ",
    "%d ID and %d headers substitutions; raw %s; final %s.\n"
  ),
  repair_summary$table_count,
  repair_summary$id_substitutions,
  repair_summary$headers_substitutions,
  repair_summary$input_sha256,
  candidate_sha256
))
