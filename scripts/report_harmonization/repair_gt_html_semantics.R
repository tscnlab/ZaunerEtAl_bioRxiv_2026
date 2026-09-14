suppressPackageStartupMessages({
  library(digest)
  library(gt)
  library(xml2)
})

normalize_space <- function(x) {
  trimws(gsub("[[:space:]]+", " ", x))
}

valid_html_id_gt_1_3_0 <- function(x) {
  valid_ids <- grepl("^[A-z]", x)
  x[!valid_ids] <- paste0("a", x[!valid_ids])
  gsub("\\s+", "-", x)
}

sha256_raw <- function(x) {
  digest(x, algo = "sha256", serialize = FALSE)
}

read_file_raw <- function(path) {
  size <- file.info(path)$size
  readBin(path, what = "raw", n = size)
}

raw_slice_text <- function(x, start, end) {
  if (end < start) {
    return("")
  }
  rawToChar(x[start:end])
}

regex_matches_bytes <- function(pattern, text) {
  matches <- gregexpr(pattern, text, perl = TRUE, useBytes = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) {
    return(data.frame(start = integer(), length = integer()))
  }
  data.frame(
    start = as.integer(matches),
    length = as.integer(attr(matches, "match.length"))
  )
}

find_table_ranges <- function(input_raw) {
  text <- rawToChar(input_raw)
  tags <- regex_matches_bytes("(?i)<table\\b[^>]*>|</table\\s*>", text)
  stopifnot(nrow(tags) > 0L)

  tag_text <- vapply(
    seq_len(nrow(tags)),
    function(i) {
      raw_slice_text(
        input_raw,
        tags$start[[i]],
        tags$start[[i]] + tags$length[[i]] - 1L
      )
    },
    character(1)
  )

  stack <- list()
  ranges <- list()
  for (i in seq_len(nrow(tags))) {
    current <- tag_text[[i]]
    if (grepl("(?i)^<table\\b", current, perl = TRUE)) {
      class_match <- regexec(
        '(?i)\\bclass="([^"]*)"',
        current,
        perl = TRUE,
        useBytes = TRUE
      )
      class_parts <- regmatches(current, class_match)[[1L]]
      classes <- if (length(class_parts) == 2L) {
        strsplit(class_parts[[2L]], "[[:space:]]+")[[1L]]
      } else {
        character()
      }
      stack[[length(stack) + 1L]] <- list(
        start = tags$start[[i]],
        open_end = tags$start[[i]] + tags$length[[i]] - 1L,
        is_gt = "gt_table" %in% classes
      )
    } else {
      stopifnot(length(stack) > 0L)
      opened <- stack[[length(stack)]]
      stack <- stack[-length(stack)]
      if (opened$is_gt) {
        ranges[[length(ranges) + 1L]] <- data.frame(
          start = opened$start,
          open_end = opened$open_end,
          end = tags$start[[i]] + tags$length[[i]] - 1L
        )
      }
    }
  }
  stopifnot(length(stack) == 0L, length(ranges) > 0L)
  ranges <- do.call(rbind, ranges)
  ranges[order(ranges$start), , drop = FALSE]
}

find_attribute_ranges <- function(input_raw, table_start, table_end, name) {
  table_text <- raw_slice_text(input_raw, table_start, table_end)
  pattern <- paste0('(?<![[:alnum:]_-])', name, '="[^"]*"')
  matches <- regex_matches_bytes(pattern, table_text)
  if (nrow(matches) == 0L) {
    return(data.frame(
      value_start_byte = integer(),
      value_end_byte = integer(),
      value = character()
    ))
  }
  prefix_bytes <- nchar(paste0(name, '="'), type = "bytes")
  value_start <- table_start - 1L + matches$start + prefix_bytes
  value_end <- table_start - 1L + matches$start + matches$length - 2L
  value <- vapply(
    seq_len(nrow(matches)),
    function(i) {
      raw_slice_text(input_raw, value_start[[i]], value_end[[i]])
    },
    character(1)
  )
  data.frame(
    value_start_byte = value_start,
    value_end_byte = value_end,
    value = value,
    stringsAsFactors = FALSE
  )
}

class_has <- function(node, class_name) {
  classes <- xml_attr(node, "class")
  !is.na(classes) && class_name %in% strsplit(classes, "[[:space:]]+")[[1L]]
}

table_metadata <- function(table) {
  id_nodes <- xml_find_all(table, "self::*[@id] | .//*[@id]")
  ids <- xml_attr(id_nodes, "id")
  stopifnot(
    length(ids) > 0L,
    !anyNA(ids),
    all(nzchar(ids)),
    !anyDuplicated(ids)
  )

  group_nodes <- id_nodes[vapply(
    id_nodes,
    function(node) {
      class_has(node, "gt_group_heading") ||
        class_has(node, "gt_stub_row_group")
    },
    logical(1)
  )]
  group_ids <- unique(xml_attr(group_nodes, "id"))
  group_ids <- group_ids[!is.na(group_ids) & nzchar(group_ids)]

  list(id_nodes = id_nodes, ids = ids, group_ids = group_ids)
}

resolve_header_relationship <- function(value, table, metadata) {
  value <- normalize_space(value)
  ids <- metadata$ids
  stub_match <- regexpr("stub_[0-9]+_[0-9]+", value, perl = TRUE)

  if (stub_match[[1L]] > 0L) {
    start <- stub_match[[1L]]
    length <- attr(stub_match, "match.length")
    row_id <- substr(value, start, start + length - 1L)
    group_raw <- normalize_space(substr(value, 1L, start - 1L))
    column_raw <- normalize_space(substr(value, start + length, nchar(value)))
    refs <- c(
      if (nzchar(group_raw)) group_raw,
      row_id,
      if (nzchar(column_raw)) valid_html_id_gt_1_3_0(column_raw)
    )
  } else {
    direct <- valid_html_id_gt_1_3_0(value)
    if (direct %in% ids) {
      refs <- direct
    } else {
      solutions <- list()
      for (group_id in metadata$group_ids) {
        prefix <- paste0(group_id, " ")
        if (startsWith(value, prefix)) {
          column_raw <- substring(value, nchar(prefix) + 1L)
          candidate <- c(group_id, valid_html_id_gt_1_3_0(column_raw))
          if (all(candidate %in% ids)) {
            solutions[[length(solutions) + 1L]] <- candidate
          }
        }
      }
      stopifnot(length(solutions) == 1L)
      refs <- solutions[[1L]]
    }
  }

  stopifnot(length(refs) > 0L, !anyDuplicated(refs), all(refs %in% ids))
  ref_nodes <- metadata$id_nodes[match(refs, ids)]
  stopifnot(
    all(xml_name(ref_nodes) == "th"),
    all(
      xml_attr(ref_nodes, "scope") %in% c("col", "row", "colgroup", "rowgroup")
    )
  )
  refs
}

inventory_unsupported_id_references <- function(doc, old_ids) {
  idref_attributes <- c(
    "aria-labelledby",
    "aria-describedby",
    "aria-controls",
    "aria-owns",
    "aria-flowto",
    "aria-activedescendant",
    "aria-details",
    "aria-errormessage",
    "for",
    "list",
    "form",
    "itemref"
  )
  findings <- list()
  all_nodes <- xml_find_all(doc, ".//*")

  for (node in all_nodes) {
    attributes <- xml_attrs(node)
    if (length(attributes) == 0L) {
      next
    }
    for (attribute in intersect(names(attributes), idref_attributes)) {
      value <- attributes[[attribute]]
      tokens <- strsplit(normalize_space(value), "[[:space:]]+")[[1L]]
      referenced <- unique(c(
        old_ids[old_ids == value],
        intersect(tokens, old_ids)
      ))
      if (length(referenced) > 0L) {
        findings[[length(findings) + 1L]] <- data.frame(
          element = xml_name(node),
          attribute = attribute,
          value = value,
          referenced_ids = paste(referenced, collapse = "|"),
          stringsAsFactors = FALSE
        )
      }
    }
    for (attribute in intersect(names(attributes), c("href", "xlink:href"))) {
      value <- attributes[[attribute]]
      if (startsWith(value, "#") && substring(value, 2L) %in% old_ids) {
        findings[[length(findings) + 1L]] <- data.frame(
          element = xml_name(node),
          attribute = attribute,
          value = value,
          referenced_ids = substring(value, 2L),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(findings) == 0L) {
    return(data.frame(
      element = character(),
      attribute = character(),
      value = character(),
      referenced_ids = character()
    ))
  }
  do.call(rbind, findings)
}

apply_raw_replacements <- function(input_raw, ledger, reverse = FALSE) {
  if (nrow(ledger) == 0L) {
    return(input_raw)
  }
  if (reverse) {
    starts <- ledger$post_value_start_byte
    ends <- ledger$post_value_end_byte
    values <- ledger$pre_value
  } else {
    starts <- ledger$pre_value_start_byte
    ends <- ledger$pre_value_end_byte
    values <- ledger$post_value
  }
  order_descending <- order(starts, decreasing = TRUE)
  output <- input_raw
  for (i in order_descending) {
    start <- starts[[i]]
    end <- ends[[i]]
    before <- if (start > 1L) output[seq_len(start - 1L)] else raw()
    after <- if (end < length(output))
      output[seq.int(end + 1L, length(output))] else raw()
    output <- c(before, charToRaw(enc2utf8(values[[i]])), after)
  }
  output
}

normalized_dom_without_mutable_values <- function(doc) {
  tables <- xml_find_all(
    doc,
    ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
  )
  for (table in tables) {
    id_nodes <- xml_find_all(table, "self::*[@id] | .//*[@id]")
    header_nodes <- xml_find_all(table, "self::*[@headers] | .//*[@headers]")
    if (length(id_nodes) > 0L) {
      xml_set_attr(id_nodes, "id", "__GT_INTERNAL_ID__")
    }
    if (length(header_nodes) > 0L) {
      xml_set_attr(header_nodes, "headers", "__GT_HEADERS__")
    }
  }
  as.character(doc)
}

verify_repaired_dom <- function(
  input_text,
  output_text,
  ledger,
  endpoint_count
) {
  input_doc <- read_html(input_text)
  output_doc <- read_html(output_text)
  table_xpath <- paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
  input_tables <- xml_find_all(input_doc, table_xpath)
  output_tables <- xml_find_all(output_doc, table_xpath)
  stopifnot(
    length(input_tables) == endpoint_count,
    length(output_tables) == endpoint_count
  )

  input_text_values <- vapply(input_tables, xml_text, character(1))
  output_text_values <- vapply(output_tables, xml_text, character(1))
  counts <- function(tables) {
    vapply(
      tables,
      function(table) {
        c(
          rows = length(xml_find_all(table, ".//tr")),
          cells = length(xml_find_all(table, ".//th | .//td")),
          header_cells = length(xml_find_all(table, ".//th")),
          ids = length(xml_find_all(table, "self::*[@id] | .//*[@id]")),
          headers = length(xml_find_all(
            table,
            "self::*[@headers] | .//*[@headers]"
          ))
        )
      },
      numeric(5)
    )
  }
  stopifnot(
    identical(input_text_values, output_text_values),
    identical(counts(input_tables), counts(output_tables)),
    identical(xml_text(input_doc), xml_text(output_doc))
  )

  output_ids <- xml_attr(xml_find_all(output_doc, ".//*[@id]"), "id")
  output_ids <- output_ids[!is.na(output_ids) & nzchar(output_ids)]
  stopifnot(!anyDuplicated(output_ids))

  for (table in output_tables) {
    ids <- xml_attr(xml_find_all(table, "self::*[@id] | .//*[@id]"), "id")
    ids <- ids[!is.na(ids) & nzchar(ids)]
    id_nodes <- xml_find_all(table, "self::*[@id] | .//*[@id]")
    header_values <- xml_attr(
      xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
      "headers"
    )
    for (value in header_values) {
      tokens <- strsplit(value, "[[:space:]]+")[[1L]]
      positions <- match(tokens, ids)
      stopifnot(
        !anyNA(positions),
        all(vapply(
          tokens,
          function(token) sum(ids == token) == 1L,
          logical(1)
        )),
        all(xml_name(id_nodes[positions]) == "th")
      )
    }
  }

  stopifnot(identical(
    normalized_dom_without_mutable_values(read_html(input_text)),
    normalized_dom_without_mutable_values(read_html(output_text))
  ))

  header_rows <- ledger$attribute == "headers"
  stopifnot(all(vapply(
    which(header_rows),
    function(i) {
      intended <- strsplit(
        ledger$intended_post_ids[[i]],
        "\\|",
        fixed = FALSE
      )[[1L]]
      rendered <- strsplit(ledger$post_value[[i]], "[[:space:]]+")[[1L]]
      identical(intended, rendered)
    },
    logical(1)
  )))

  invisible(TRUE)
}

repair_gt_html_semantics <- function(input_path, output_path, ledger_path) {
  stopifnot(
    as.character(getRversion()) == "4.6.1",
    as.character(packageVersion("gt")) == "1.3.0",
    file.exists(input_path),
    dir.exists(dirname(output_path)),
    dir.exists(dirname(ledger_path))
  )

  input_raw <- read_file_raw(input_path)
  input_text <- rawToChar(input_raw)
  input_doc <- read_html(input_text)
  tables <- xml_find_all(
    input_doc,
    paste0(
      ".//table[contains(concat(' ', normalize-space(@class), ' '),",
      " ' gt_table ')]"
    )
  )
  stopifnot(length(tables) > 0L)

  endpoints <- vapply(
    tables,
    function(table) {
      endpoint <- xml_find_first(
        table,
        "ancestor::*[@id and starts-with(@id,'tbl-')][1]"
      )
      stopifnot(!inherits(endpoint, "xml_missing"))
      xml_attr(endpoint, "id")
    },
    character(1)
  )
  stopifnot(all(nzchar(endpoints)), !anyDuplicated(endpoints))

  table_ranges <- find_table_ranges(input_raw)
  stopifnot(nrow(table_ranges) == length(tables))

  all_old_ids <- unlist(lapply(
    tables,
    function(table) table_metadata(table)$ids
  ))
  unsupported_refs <- inventory_unsupported_id_references(
    input_doc,
    all_old_ids
  )
  stopifnot(nrow(unsupported_refs) == 0L)

  ledger <- list()
  for (table_index in seq_along(tables)) {
    table <- tables[[table_index]]
    endpoint <- endpoints[[table_index]]
    metadata <- table_metadata(table)
    new_ids <- sprintf(
      "%s--gt-%04d",
      endpoint,
      seq_along(metadata$ids)
    )
    names(new_ids) <- metadata$ids

    id_ranges <- find_attribute_ranges(
      input_raw,
      table_ranges$start[[table_index]],
      table_ranges$end[[table_index]],
      "id"
    )
    header_ranges <- find_attribute_ranges(
      input_raw,
      table_ranges$start[[table_index]],
      table_ranges$end[[table_index]],
      "headers"
    )
    header_nodes <- xml_find_all(table, "self::*[@headers] | .//*[@headers]")
    header_values <- xml_attr(header_nodes, "headers")

    stopifnot(
      nrow(id_ranges) == length(metadata$ids),
      identical(id_ranges$value, unname(metadata$ids)),
      nrow(header_ranges) == length(header_values),
      identical(header_ranges$value, unname(header_values))
    )

    for (i in seq_along(metadata$ids)) {
      ledger[[length(ledger) + 1L]] <- data.frame(
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
      intended_pre <- resolve_header_relationship(
        header_values[[i]],
        table,
        metadata
      )
      intended_post <- unname(new_ids[intended_pre])
      stopifnot(!anyNA(intended_post))
      ledger[[length(ledger) + 1L]] <- data.frame(
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

  ledger <- do.call(rbind, ledger)
  ledger <- ledger[order(ledger$pre_value_start_byte), , drop = FALSE]
  rownames(ledger) <- NULL
  stopifnot(
    nrow(ledger) > 0L,
    all(ledger$attribute %in% c("id", "headers")),
    all(ledger$pre_value_start_byte <= ledger$pre_value_end_byte),
    all(
      head(ledger$pre_value_end_byte, -1L) <
        tail(ledger$pre_value_start_byte, -1L)
    )
  )

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

  output_raw <- apply_raw_replacements(input_raw, ledger)
  output_text <- rawToChar(output_raw)
  verify_repaired_dom(input_text, output_text, ledger, length(endpoints))

  reversed_raw <- apply_raw_replacements(output_raw, ledger, reverse = TRUE)
  stopifnot(identical(reversed_raw, input_raw))

  writeBin(output_raw, output_path)
  write.csv(ledger, ledger_path, row.names = FALSE, na = "")

  summary <- list(
    input_sha256 = sha256_raw(input_raw),
    output_sha256 = sha256_raw(output_raw),
    reversed_sha256 = sha256_raw(reversed_raw),
    input_bytes = length(input_raw),
    output_bytes = length(output_raw),
    table_count = length(endpoints),
    id_substitutions = sum(ledger$attribute == "id"),
    headers_substitutions = sum(ledger$attribute == "headers"),
    total_substitutions = nrow(ledger),
    unsupported_id_references = nrow(unsupported_refs),
    ledger_rows = nrow(ledger)
  )
  invisible(summary)
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  stopifnot(length(args) == 3L)
  result <- repair_gt_html_semantics(args[[1L]], args[[2L]], args[[3L]])
  cat(sprintf(
    paste0(
      "gt HTML semantic repair PASS: %d tables; %d id and %d headers ",
      "substitutions; pre %s; post %s; exact reverse %s.\n"
    ),
    result$table_count,
    result$id_substitutions,
    result$headers_substitutions,
    result$input_sha256,
    result$output_sha256,
    result$reversed_sha256
  ))
}

if (sys.nframe() == 0L) {
  main()
}
