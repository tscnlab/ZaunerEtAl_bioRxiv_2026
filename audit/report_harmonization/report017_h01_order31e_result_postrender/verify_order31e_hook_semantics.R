root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stopifnot(identical(as.character(getRversion()), "4.6.1"))

evidence_dir <- file.path(
  root,
  "audit/report_harmonization/report017_h01_order31e_result_postrender"
)
external_dir <- normalizePath(
  "/private/tmp/H01_REPORT017_31e.owP2my",
  winslash = "/",
  mustWork = TRUE
)
external_files <- sort(list.files(external_dir, full.names = TRUE))
stopifnot(length(external_files) == 2L)

summary_path <- file.path(
  external_dir,
  "gt_html_semantic_post_render_summary.csv"
)
summary <- read.csv(summary_path, check.names = FALSE, stringsAsFactors = FALSE)
stopifnot(
  nrow(summary) == 1L,
  identical(
    summary$target,
    "_build/nathealth/notebooks/hypotheses/H01.html"
  ),
  identical(summary$disposition, "REPAIRED"),
  summary$table_count == 36L,
  summary$id_count == 783L,
  summary$headers_count == 4798L,
  summary$total_substitutions == 5581L,
  nzchar(summary$ledger_file)
)

ledger_path <- file.path(external_dir, summary$ledger_file)
stopifnot(file.exists(ledger_path))
ledger <- read.csv(ledger_path, check.names = FALSE, stringsAsFactors = FALSE)
stopifnot(
  nrow(ledger) == 5581L,
  sum(ledger$attribute == "id") == 783L,
  sum(ledger$attribute == "headers") == 4798L
)

engine <- new.env(parent = globalenv())
sys.source(
  file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
  envir = engine
)
html_path <- file.path(root, summary$target)
final_raw <- engine$read_file_raw(html_path)
stopifnot(
  identical(engine$sha256_raw(final_raw), summary$post_sha256),
  length(final_raw) == summary$post_bytes
)
reconstructed_raw <- engine$apply_raw_replacements(
  final_raw,
  ledger,
  reverse = TRUE
)
stopifnot(
  identical(engine$sha256_raw(reconstructed_raw), summary$pre_sha256),
  length(reconstructed_raw) == summary$pre_bytes
)

pre_text <- rawToChar(reconstructed_raw)
post_text <- rawToChar(final_raw)
stopifnot(isTRUE(engine$verify_repaired_dom(
  pre_text,
  post_text,
  ledger,
  endpoint_count = 36L
)))

pre_doc <- xml2::read_html(pre_text)
post_doc <- xml2::read_html(post_text)
table_xpath <- paste0(
  ".//table[contains(concat(' ', normalize-space(@class), ' '),",
  " ' gt_table ')]"
)
pre_tables <- xml2::xml_find_all(pre_doc, table_xpath)
post_tables <- xml2::xml_find_all(post_doc, table_xpath)
stopifnot(length(pre_tables) == 36L, length(post_tables) == 36L)

table_endpoint <- function(table) {
  endpoint <- xml2::xml_find_first(
    table,
    "ancestor::*[@id and starts-with(@id,'tbl-h01-')][1]"
  )
  stopifnot(!inherits(endpoint, "xml_missing"))
  xml2::xml_attr(endpoint, "id")
}
table_counts <- function(table) {
  data.frame(
    endpoint = table_endpoint(table),
    rows = length(xml2::xml_find_all(table, ".//tr")),
    cells = length(xml2::xml_find_all(table, ".//th | .//td")),
    header_cells = length(xml2::xml_find_all(table, ".//th")),
    internal_ids = length(xml2::xml_find_all(
      table,
      "self::*[@id] | .//*[@id]"
    )),
    headers_attributes = length(xml2::xml_find_all(
      table,
      "self::*[@headers] | .//*[@headers]"
    )),
    stringsAsFactors = FALSE
  )
}
pre_counts <- do.call(rbind, lapply(pre_tables, table_counts))
post_counts <- do.call(rbind, lapply(post_tables, table_counts))
stopifnot(
  identical(pre_counts$endpoint, post_counts$endpoint),
  identical(pre_counts$rows, post_counts$rows),
  identical(pre_counts$cells, post_counts$cells),
  identical(pre_counts$header_cells, post_counts$header_cells),
  identical(pre_counts$internal_ids, post_counts$internal_ids),
  identical(pre_counts$headers_attributes, post_counts$headers_attributes)
)
table_audit <- merge(
  pre_counts,
  post_counts,
  by = "endpoint",
  suffixes = c("_pre", "_post"),
  sort = FALSE
)
count_fields <- c(
  "rows", "cells", "header_cells", "internal_ids", "headers_attributes"
)
table_audit$pass <- Reduce(
  `&`,
  lapply(count_fields, function(field) {
    table_audit[[paste0(field, "_pre")]] ==
      table_audit[[paste0(field, "_post")]]
  })
)
stopifnot(all(table_audit$pass))

post_ids <- xml2::xml_attr(xml2::xml_find_all(post_doc, ".//*[@id]"), "id")
post_ids <- post_ids[!is.na(post_ids) & nzchar(post_ids)]
stopifnot(!anyDuplicated(post_ids))

pre_internal_ids <- unlist(lapply(pre_tables, function(table) {
  xml2::xml_attr(xml2::xml_find_all(
    table,
    "self::*[@id] | .//*[@id]"
  ), "id")
}), use.names = FALSE)
unsupported <- engine$inventory_unsupported_id_references(
  post_doc,
  pre_internal_ids
)
stopifnot(nrow(unsupported) == 0L)

id_reference_findings <- list()
record_reference <- function(element, attribute, token, reason) {
  id_reference_findings[[length(id_reference_findings) + 1L]] <<- data.frame(
    element = element,
    attribute = attribute,
    token = token,
    reason = reason,
    stringsAsFactors = FALSE
  )
}
idref_attributes <- c(
  "aria-labelledby", "aria-describedby", "aria-controls", "aria-owns",
  "aria-flowto", "aria-activedescendant", "aria-details",
  "aria-errormessage", "for", "list", "form", "itemref"
)
for (node in xml2::xml_find_all(post_doc, ".//*")) {
  attributes <- xml2::xml_attrs(node)
  for (attribute in intersect(names(attributes), idref_attributes)) {
    tokens <- strsplit(trimws(attributes[[attribute]]), "[[:space:]]+")[[1L]]
    for (token in tokens[nzchar(tokens)]) {
      if (sum(post_ids == token) != 1L) {
        record_reference(xml2::xml_name(node), attribute, token, "not_unique")
      }
    }
  }
  for (attribute in intersect(names(attributes), c("href", "xlink:href"))) {
    value <- attributes[[attribute]]
    if (startsWith(value, "#") && nchar(value) > 1L) {
      token <- substring(value, 2L)
      if (sum(post_ids == token) != 1L) {
        record_reference(xml2::xml_name(node), attribute, token, "not_unique")
      }
    }
  }
}
id_reference_audit <- if (length(id_reference_findings) == 0L) {
  data.frame(
    element = character(),
    attribute = character(),
    token = character(),
    reason = character()
  )
} else {
  do.call(rbind, id_reference_findings)
}
stopifnot(nrow(id_reference_audit) == 0L)

visible_text_identical <- identical(
  xml2::xml_text(pre_doc),
  xml2::xml_text(post_doc)
)
normalized_dom_identical <- identical(
  engine$normalized_dom_without_mutable_values(xml2::read_html(pre_text)),
  engine$normalized_dom_without_mutable_values(xml2::read_html(post_text))
)
stopifnot(visible_text_identical, normalized_dom_identical)

readr::write_csv(
  table_audit,
  file.path(evidence_dir, "hook_table_preservation_audit.csv"),
  na = ""
)
readr::write_csv(
  id_reference_audit,
  file.path(evidence_dir, "hook_id_reference_findings.csv"),
  na = ""
)
verification <- data.frame(
  check = c(
    "disposition_repaired",
    "native_gt_tables",
    "id_substitutions",
    "headers_substitutions",
    "total_substitutions",
    "reverse_sha256",
    "reverse_bytes",
    "visible_text_preserved",
    "normalized_dom_preserved",
    "table_row_cell_header_counts_preserved",
    "document_ids_unique",
    "headers_and_id_references_resolve"
  ),
  observed = c(
    summary$disposition,
    summary$table_count,
    sum(ledger$attribute == "id"),
    sum(ledger$attribute == "headers"),
    nrow(ledger),
    engine$sha256_raw(reconstructed_raw),
    length(reconstructed_raw),
    visible_text_identical,
    normalized_dom_identical,
    all(table_audit$pass),
    !anyDuplicated(post_ids),
    nrow(id_reference_audit) == 0L
  ),
  expected = c(
    "REPAIRED",
    "36",
    "783",
    "4798",
    "5581",
    summary$pre_sha256,
    summary$pre_bytes,
    "TRUE",
    "TRUE",
    "TRUE",
    "TRUE",
    "TRUE"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
readr::write_csv(
  verification,
  file.path(evidence_dir, "hook_semantic_reverse_verification.csv"),
  na = ""
)

cat(sprintf(
  paste0(
    "hook_semantics=PASS tables=%d ids=%d headers=%d total=%d ",
    "pre_sha256=%s post_sha256=%s duplicate_ids=0 dangling_refs=0\n"
  ),
  summary$table_count,
  sum(ledger$attribute == "id"),
  sum(ledger$attribute == "headers"),
  nrow(ledger),
  engine$sha256_raw(reconstructed_raw),
  engine$sha256_raw(final_raw)
))
