#!/usr/bin/env Rscript

# Structural source audit for every manuscript main or supplementary table in
# Descriptives and H01--H11. This script parses QMD chunks but never executes
# them, reads no scientific data, and does not adjudicate scientific values.

options(stringsAsFactors = FALSE)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "audit", "report_harmonization")

stopifnot(identical(as.character(getRversion()), "4.6.1"))

project_library <- file.path(
  root, "renv", "library", "macos", "R-4.6", "aarch64-apple-darwin23"
)
if (dir.exists(project_library)) {
  .libPaths(c(project_library, .libPaths()))
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("digest is required and is not available; no package was installed")
}

documents <- data.frame(
  document = c(
    "Descriptives", paste0("H", sprintf("%02d", 1:11))
  ),
  source_qmd = c(
    "notebooks/descriptives.qmd",
    file.path("notebooks", "hypotheses", paste0(
      "H", sprintf("%02d", 1:11), ".qmd"
    ))
  ),
  expected_tables = c(8L, 36L, 15L, 13L, 15L, 30L, 11L, 11L, 15L,
                      11L, 15L, 15L),
  stringsAsFactors = FALSE
)

main_contract <- read.csv(
  file.path(out_dir, "gt_main_table_contract.csv"),
  check.names = FALSE
)

normalise_option <- function(x) {
  x <- trimws(sub("^[^:]+:[[:space:]]*", "", x))
  if (nchar(x) >= 2L && substr(x, 1L, 1L) %in% c("\"", "'") &&
      substr(x, nchar(x), nchar(x)) == substr(x, 1L, 1L)) {
    x <- substr(x, 2L, nchar(x) - 1L)
  }
  x
}

parse_r_chunks <- function(path) {
  lines <- readLines(path, warn = FALSE)
  starts <- grep("^```\\{r(?:[[:space:],}]|$)", lines, perl = TRUE)
  chunks <- vector("list", length(starts))
  for (i in seq_along(starts)) {
    start <- starts[[i]]
    candidate_ends <- which(
      seq_along(lines) > start & grepl("^```[[:space:]]*$", lines)
    )
    if (!length(candidate_ends)) {
      stop("Unclosed R chunk in ", path, " at line ", start)
    }
    end <- candidate_ends[[1L]]
    body <- if (end > start + 1L) lines[(start + 1L):(end - 1L)] else character()
    option_lines <- body[grepl("^[[:space:]]*#\\|", body)]
    label_lines <- option_lines[grepl(
      "^[[:space:]]*#\\|[[:space:]]*label[[:space:]]*:", option_lines
    )]
    caption_lines <- option_lines[grepl(
      "^[[:space:]]*#\\|[[:space:]]*tbl-cap[[:space:]]*:", option_lines
    )]
    header <- lines[[start]]
    header_label <- sub(
      "^```\\{r[[:space:]]+([^,}[:space:]]+).*$", "\\1", header
    )
    if (identical(header_label, header)) header_label <- ""
    label <- if (length(label_lines)) {
      normalise_option(label_lines[[1L]])
    } else {
      header_label
    }
    caption <- if (length(caption_lines)) {
      normalise_option(caption_lines[[1L]])
    } else {
      ""
    }
    code <- body[!grepl("^[[:space:]]*#\\|", body)]
    chunks[[i]] <- list(
      start = start,
      end = end,
      label = label,
      caption = caption,
      label_option_count = length(label_lines),
      caption_option_count = length(caption_lines),
      code_lines = code,
      code = paste(code, collapse = "\n")
    )
  }
  chunks
}

parse_safely <- function(code, context) {
  tryCatch(
    parse(text = code, keep.source = FALSE),
    error = function(e) {
      stop("R parse failure in ", context, ": ", conditionMessage(e))
    }
  )
}

call_name <- function(x) {
  if (!is.call(x)) return("")
  head <- x[[1L]]
  if (is.symbol(head)) return(as.character(head))
  if (is.call(head) && length(head) == 3L &&
      identical(head[[1L]], as.name("::"))) {
    return(paste0(as.character(head[[2L]]), "::", as.character(head[[3L]])))
  }
  ""
}

collect_calls <- function(x) {
  text <- paste(deparse(x, width.cutoff = 500L), collapse = " ")
  hits <- regmatches(
    text,
    gregexpr(
      "(?<![[:alnum:]_.])(?:[[:alnum:]_.]+::)?[[:alpha:].][[:alnum:]_.]*[[:space:]]*\\(",
      text,
      perl = TRUE
    )
  )[[1L]]
  if (!length(hits) || identical(hits, "")) return(character())
  unique(trimws(sub("[[:space:]]*\\($", "", hits)))
}

collect_symbols <- function(x) {
  text <- paste(deparse(x, width.cutoff = 500L), collapse = " ")
  hits <- regmatches(
    text,
    gregexpr("[[:alpha:].][[:alnum:]_.]*", text, perl = TRUE)
  )[[1L]]
  if (!length(hits) || identical(hits, "")) return(character())
  unique(hits)
}

top_assignments <- function(expressions) {
  rows <- list()
  for (expr in as.list(expressions)) {
    if (!is.call(expr) || !call_name(expr) %in% c("<-", "=")) next
    if (length(expr) < 3L || !is.symbol(expr[[2L]])) next
    rows[[length(rows) + 1L]] <- list(
      name = as.character(expr[[2L]]),
      rhs = expr[[3L]],
      is_function = is.call(expr[[3L]]) &&
        identical(expr[[3L]][[1L]], as.name("function"))
    )
  }
  rows
}

gt_constructor_calls <- c("gt::gt", "gt")
prohibited_output_calls <- c(
  "knitr::kable", "kable", "kableExtra::kbl", "kbl",
  "DT::datatable", "datatable", "gt::as_raw_html", "as_raw_html",
  "gt::gtsave", "gtsave", "gt::tab_caption", "tab_caption"
)

analyse_document <- function(document, relative_path) {
  full_path <- file.path(root, relative_path)
  chunks <- parse_r_chunks(full_path)
  parsed <- lapply(seq_along(chunks), function(i) {
    parse_safely(chunks[[i]]$code, paste0(relative_path, ":", chunks[[i]]$start))
  })

  assignments <- unlist(lapply(parsed, top_assignments), recursive = FALSE)
  external_files <- if (identical(document, "Descriptives")) {
    file.path(root, "scripts", "descriptives", "build_publication_tables.R")
  } else {
    character()
  }
  if (length(external_files)) {
    external_assignments <- unlist(lapply(external_files, function(path) {
      expressions <- parse_safely(
        paste(readLines(path, warn = FALSE), collapse = "\n"), path
      )
      top_assignments(expressions)
    }), recursive = FALSE)
    assignments <- c(assignments, external_assignments)
  }
  functions <- assignments[vapply(assignments, `[[`, logical(1), "is_function")]
  objects <- assignments[!vapply(assignments, `[[`, logical(1), "is_function")]

  helper_names <- vapply(functions, `[[`, character(1), "name")
  helper_calls <- lapply(functions, function(x) collect_calls(x$rhs))
  names(helper_calls) <- helper_names
  gt_helpers <- names(helper_calls)[vapply(
    helper_calls,
    function(x) any(x %in% gt_constructor_calls),
    logical(1)
  )]
  repeat {
    additions <- names(helper_calls)[vapply(
      helper_calls,
      function(x) any(x %in% gt_helpers),
      logical(1)
    )]
    updated <- union(gt_helpers, additions)
    if (setequal(updated, gt_helpers)) break
    gt_helpers <- updated
  }

  object_names <- vapply(objects, `[[`, character(1), "name")
  object_calls <- lapply(objects, function(x) collect_calls(x$rhs))
  object_symbols <- lapply(objects, function(x) collect_symbols(x$rhs))
  names(object_calls) <- names(object_symbols) <- object_names
  gt_objects <- object_names[vapply(seq_along(objects), function(i) {
    any(object_calls[[i]] %in% c(gt_constructor_calls, gt_helpers))
  }, logical(1))]
  repeat {
    additions <- object_names[vapply(seq_along(objects), function(i) {
      any(object_calls[[i]] %in% c(gt_constructor_calls, gt_helpers)) ||
        any(object_symbols[[i]] %in% gt_objects)
    }, logical(1))]
    updated <- union(gt_objects, additions)
    if (setequal(updated, gt_objects)) break
    gt_objects <- updated
  }

  table_indices <- which(vapply(
    chunks,
    function(x) nzchar(x$caption) || startsWith(x$label, "tbl-"),
    logical(1)
  ))

  rows <- lapply(table_indices, function(i) {
    chunk <- chunks[[i]]
    expr <- parsed[[i]]
    calls <- collect_calls(expr)
    symbols <- collect_symbols(expr)
    helpers_used <- intersect(calls, gt_helpers)
    objects_used <- intersect(symbols, gt_objects)
    direct_gt <- any(calls %in% gt_constructor_calls)
    native_static <- direct_gt || length(helpers_used) > 0L ||
      length(objects_used) > 0L
    prohibited <- intersect(calls, prohibited_output_calls)
    duplicate_caption_call <- any(calls %in% c(
      "gt::tab_caption", "tab_caption"
    )) || grepl(
      "(?:gt::gt|gt)[[:space:]]*\\([^)]*caption[[:space:]]*=",
      chunk$code,
      perl = TRUE
    )
    backend_markup <- grepl(
      "<(?:span|strong|small|br|div|table|sup|sub)(?:[[:space:]/>])",
      chunk$code,
      ignore.case = TRUE,
      perl = TRUE
    ) || any(calls %in% c("gt::html", "gt::latex", "htmltools::HTML"))
    has_inherits_assertion <- grepl(
      "inherits[[:space:]]*\\([^)]*,[[:space:]]*[\"']gt_tbl[\"']",
      chunk$code,
      perl = TRUE
    )
    evidence <- c(
      if (direct_gt) "direct gt::gt constructor" else NULL,
      if (length(helpers_used)) paste0(
        "gt helper: ", paste(helpers_used, collapse = " | ")
      ) else NULL,
      if (length(objects_used)) paste0(
        "gt object: ", paste(objects_used, collapse = " | ")
      ) else NULL
    )
    data.frame(
      document = document,
      source_qmd = relative_path,
      source_sha256 = digest::digest(
        full_path, algo = "sha256", file = TRUE
      ),
      source_line = chunk$start,
      chunk_end_line = chunk$end,
      label = chunk$label,
      caption = chunk$caption,
      label_option_count = chunk$label_option_count,
      caption_option_count = chunk$caption_option_count,
      label_conforms = startsWith(chunk$label, "tbl-"),
      caption_nonempty = nzchar(chunk$caption),
      source_native_gt_static = native_static,
      native_gt_evidence = paste(evidence, collapse = "; "),
      prohibited_output_calls = paste(prohibited, collapse = " | "),
      duplicate_caption_call = duplicate_caption_call,
      backend_specific_markup_present = backend_markup,
      local_gt_tbl_assertion = has_inherits_assertion,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

audit <- do.call(rbind, lapply(seq_len(nrow(documents)), function(i) {
  analyse_document(documents$document[[i]], documents$source_qmd[[i]])
}))
row.names(audit) <- NULL

main_labels <- setNames(
  main_contract$proposed_main_table,
  main_contract$document
)
audit$manuscript_role <- "supplementary table"
for (i in seq_len(nrow(audit))) {
  document <- audit$document[[i]]
  label <- audit$label[[i]]
  is_main <- identical(label, main_labels[[document]]) ||
    (identical(document, "H05") && label %in% c(
      "tbl-h05-near-results-a", "tbl-h05-near-results-b"
    ))
  if (is_main) audit$manuscript_role[[i]] <- "main table"
}

audit$source_contract_complete <- with(
  audit,
  label_conforms & caption_nonempty & source_native_gt_static &
    prohibited_output_calls == "" & !duplicate_caption_call
)

expected_counts <- setNames(documents$expected_tables, documents$document)
actual_counts <- table(factor(audit$document, levels = documents$document))
stopifnot(
  nrow(audit) == 195L,
  identical(as.integer(actual_counts), as.integer(expected_counts)),
  !anyDuplicated(audit$label),
  all(audit$label_option_count == 1L),
  all(audit$caption_option_count == 1L)
)

audit_path <- file.path(out_dir, "phase4_gt_source_audit.csv")
write.csv(audit, audit_path, row.names = FALSE, na = "")

summary <- aggregate(
  cbind(
    table_count = rep(1L, nrow(audit)),
    native_gt_static = as.integer(audit$source_native_gt_static),
    source_contract_complete = as.integer(audit$source_contract_complete),
    backend_markup = as.integer(audit$backend_specific_markup_present),
    local_assertion = as.integer(audit$local_gt_tbl_assertion)
  ) ~ document,
  data = audit,
  FUN = sum
)
summary$main_table_count <- vapply(summary$document, function(x) {
  sum(audit$document == x & audit$manuscript_role == "main table")
}, integer(1))
summary$supplementary_table_count <- vapply(summary$document, function(x) {
  sum(audit$document == x & audit$manuscript_role == "supplementary table")
}, integer(1))
summary$nonconforming_labels <- vapply(summary$document, function(x) {
  paste(audit$label[audit$document == x & !audit$label_conforms], collapse = " | ")
}, character(1))
summary$unproven_native_gt <- vapply(summary$document, function(x) {
  paste(audit$label[
    audit$document == x & !audit$source_native_gt_static
  ], collapse = " | ")
}, character(1))
summary$prohibited_output_labels <- vapply(summary$document, function(x) {
  paste(audit$label[
    audit$document == x & audit$prohibited_output_calls != ""
  ], collapse = " | ")
}, character(1))

write.csv(
  summary,
  file.path(out_dir, "phase4_gt_source_document_summary.csv"),
  row.names = FALSE,
  na = ""
)

runtime <- c(
  paste0("Run timestamp: ", format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE)),
  paste0("Working directory: ", root),
  "Command: Rscript --vanilla scripts/report_harmonization/audit_gt_source_contract.R",
  "Scope: current Descriptives and H01--H11 QMD source structure only",
  paste0("R: ", R.version.string),
  paste0("gt: ", as.character(utils::packageVersion("gt"))),
  paste0("knitr: ", as.character(utils::packageVersion("knitr"))),
  paste0("Quarto: ", system2("quarto", "--version", stdout = TRUE)),
  "No QMD chunk was executed; no scientific data or stored output was read",
  "No package was installed or updated"
)
writeLines(
  runtime,
  file.path(out_dir, "phase4_gt_source_audit_runtime.txt")
)

cat(
  "Current source table endpoints: ", nrow(audit), "\n",
  "Native gt statically proven: ", sum(audit$source_native_gt_static), "\n",
  "Complete source contracts: ", sum(audit$source_contract_complete), "\n",
  "Unproven native gt endpoints: ",
  paste(audit$label[!audit$source_native_gt_static], collapse = ", "), "\n",
  "Prohibited output endpoints: ",
  paste(audit$label[audit$prohibited_output_calls != ""], collapse = ", "), "\n",
  sep = ""
)
