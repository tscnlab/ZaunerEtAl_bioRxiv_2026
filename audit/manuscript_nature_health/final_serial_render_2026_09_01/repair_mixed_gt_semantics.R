#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop(
    "Usage: repair_mixed_gt_semantics.R <input-html> <candidate-html> <ledger-csv>",
    call. = FALSE
  )
}

input_path <- normalizePath(args[[1L]], mustWork = TRUE)
output_path <- normalizePath(args[[2L]], mustWork = FALSE)
ledger_path <- normalizePath(args[[3L]], mustWork = FALSE)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("R 4.6.1 is required.", call. = FALSE)
}

project_root <- normalizePath(getwd(), mustWork = TRUE)
engine_path <- file.path(
  project_root,
  "scripts",
  "report_harmonization",
  "repair_gt_html_semantics.R"
)
engine <- new.env(parent = globalenv())
sys.source(engine_path, envir = engine)

target_endpoints <- c(
  "tbl-plan-h01-metric-synthesis-candidate",
  "tbl-plan-person-level-synthesis-gt-candidate"
)

input_raw <- engine$read_file_raw(input_path)
input_text <- rawToChar(input_raw)
input_document <- xml2::read_html(input_text)
tables <- xml2::xml_find_all(
  input_document,
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
endpoints <- vapply(
  tables,
  function(table) {
    endpoint <- xml2::xml_find_first(
      table,
      "ancestor::*[@id and starts-with(@id,'tbl-')][1]"
    )
    if (inherits(endpoint, "xml_missing")) {
      stop("A native gt table lacks a tbl-* endpoint.", call. = FALSE)
    }
    xml2::xml_attr(endpoint, "id")
  },
  character(1)
)
if (anyDuplicated(endpoints)) {
  stop("Native gt endpoints are not document-unique.", call. = FALSE)
}

target_indices <- match(target_endpoints, endpoints)
if (anyNA(target_indices)) {
  stop("A required mixed-semantic table endpoint is missing.", call. = FALSE)
}

table_ranges <- engine$find_table_ranges(input_raw)
if (nrow(table_ranges) != length(tables)) {
  stop("Raw table ranges do not match parsed tables.", call. = FALSE)
}

ledger_rows <- list()
for (table_index in target_indices) {
  table <- tables[[table_index]]
  endpoint <- endpoints[[table_index]]
  metadata <- engine$table_metadata(table)
  new_ids <- sprintf(
    "%s--gt-%04d",
    endpoint,
    seq_along(metadata$ids)
  )
  names(new_ids) <- metadata$ids

  if (any(grepl("^tbl-.*--gt-[0-9]{4}$", metadata$ids, perl = TRUE))) {
    stop("A target table is already or partly namespaced.", call. = FALSE)
  }

  id_ranges <- engine$find_attribute_ranges(
    input_raw,
    table_ranges$start[[table_index]],
    table_ranges$end[[table_index]],
    "id"
  )
  header_ranges <- engine$find_attribute_ranges(
    input_raw,
    table_ranges$start[[table_index]],
    table_ranges$end[[table_index]],
    "headers"
  )
  header_nodes <- xml2::xml_find_all(
    table,
    "self::*[@headers] | .//*[@headers]"
  )
  header_values <- xml2::xml_attr(header_nodes, "headers")

  stopifnot(
    nrow(id_ranges) == length(metadata$ids),
    identical(id_ranges$value, unname(metadata$ids)),
    nrow(header_ranges) == length(header_values),
    identical(header_ranges$value, unname(header_values))
  )

  for (i in seq_along(metadata$ids)) {
    ledger_rows[[length(ledger_rows) + 1L]] <- data.frame(
      table_index = table_index,
      table_endpoint = endpoint,
      attribute = "id",
      attribute_index = i,
      pre_value_start_byte = id_ranges$value_start_byte[[i]],
      pre_value_end_byte = id_ranges$value_end_byte[[i]],
      pre_value = metadata$ids[[i]],
      post_value = new_ids[[i]],
      intended_pre_ids = "",
      intended_post_ids = "",
      stringsAsFactors = FALSE
    )
  }

  for (i in seq_along(header_values)) {
    intended_pre <- engine$resolve_header_relationship(
      header_values[[i]],
      table,
      metadata
    )
    intended_post <- unname(new_ids[intended_pre])
    stopifnot(!anyNA(intended_post))
    ledger_rows[[length(ledger_rows) + 1L]] <- data.frame(
      table_index = table_index,
      table_endpoint = endpoint,
      attribute = "headers",
      attribute_index = i,
      pre_value_start_byte = header_ranges$value_start_byte[[i]],
      pre_value_end_byte = header_ranges$value_end_byte[[i]],
      pre_value = header_values[[i]],
      post_value = paste(intended_post, collapse = " "),
      intended_pre_ids = paste(intended_pre, collapse = "|"),
      intended_post_ids = paste(intended_post, collapse = "|"),
      stringsAsFactors = FALSE
    )
  }
}

ledger <- do.call(rbind, ledger_rows)
ledger <- ledger[order(ledger$pre_value_start_byte), , drop = FALSE]
rownames(ledger) <- NULL

pre_lengths <- ledger$pre_value_end_byte - ledger$pre_value_start_byte + 1L
post_lengths <- nchar(enc2utf8(ledger$post_value), type = "bytes")
stopifnot(identical(
  as.integer(pre_lengths),
  as.integer(nchar(enc2utf8(ledger$pre_value), type = "bytes"))
))
deltas <- post_lengths - pre_lengths
delta_before <- c(0L, head(cumsum(deltas), -1L))
ledger$post_value_start_byte <- ledger$pre_value_start_byte + delta_before
ledger$post_value_end_byte <- ledger$post_value_start_byte + post_lengths - 1L
ledger$pre_value_bytes <- pre_lengths
ledger$post_value_bytes <- post_lengths

output_raw <- engine$apply_raw_replacements(input_raw, ledger)
output_text <- rawToChar(output_raw)
output_document <- xml2::read_html(output_text)

stopifnot(identical(
  engine$normalized_dom_without_mutable_values(xml2::read_html(input_text)),
  engine$normalized_dom_without_mutable_values(xml2::read_html(output_text))
))

document_ids <- xml2::xml_attr(
  xml2::xml_find_all(output_document, "//*[@id]"),
  "id"
)
if (anyNA(document_ids) || anyDuplicated(document_ids)) {
  duplicate_ids <- unique(document_ids[
    duplicated(document_ids) | duplicated(document_ids, fromLast = TRUE)
  ])
  stop(
    sprintf(
      "The candidate contains duplicate document IDs: %s",
      paste(duplicate_ids, collapse = ", ")
    ),
    call. = FALSE
  )
}

output_tables <- xml2::xml_find_all(
  output_document,
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
header_tokens <- 0L
for (table in output_tables) {
  ids <- xml2::xml_attr(xml2::xml_find_all(table, ".//th[@id]"), "id")
  header_values <- xml2::xml_attr(
    xml2::xml_find_all(table, ".//*[@headers]"),
    "headers"
  )
  for (value in header_values) {
    tokens <- strsplit(value, "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    stopifnot(
      length(tokens) > 0L,
      all(vapply(
        tokens,
        function(token) sum(ids == token) == 1L,
        logical(1)
      ))
    )
    header_tokens <- header_tokens + length(tokens)
  }
}

reversed_raw <- engine$apply_raw_replacements(
  output_raw,
  ledger,
  reverse = TRUE
)
stopifnot(identical(reversed_raw, input_raw))

write_connection <- file(output_path, open = "wb")
writeBin(output_raw, write_connection)
close(write_connection)
write.csv(ledger, ledger_path, row.names = FALSE, na = "")

cat(sprintf(
  paste0(
    "MIXED_GT_SEMANTIC_REPAIR=PASS tables=%d targets=%d ids=%d headers=%d ",
    "substitutions=%d pre=%s post=%s reverse=%s\n"
  ),
  length(output_tables),
  length(target_indices),
  sum(ledger$attribute == "id"),
  sum(ledger$attribute == "headers"),
  nrow(ledger),
  engine$sha256_raw(input_raw),
  engine$sha256_raw(output_raw),
  engine$sha256_raw(reversed_raw)
))
