#!/usr/bin/env Rscript

# Audit the table rendering system used by every currently catalogued
# descriptives/H01--H11 main or supplemental table candidate. This script is
# structural only: it reads QMD/catalog metadata and rendered HTML. It does not
# execute QMD code or calculate, validate, or alter a scientific result.

options(stringsAsFactors = FALSE)

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(project_root, "audit", "report_harmonization")
catalog_path <- file.path(
  out_dir, "phase2_main_supplement_output_catalog.csv"
)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

project_library <- file.path(
  project_root, "renv", "library", "macos", "R-4.6",
  "aarch64-apple-darwin23"
)
if (dir.exists(project_library)) {
  .libPaths(c(project_library, .libPaths()))
}
if (!requireNamespace("xml2", quietly = TRUE)) {
  stop("xml2 is required and is not available; no package was installed")
}

catalog <- read.csv(catalog_path, check.names = FALSE, na.strings = "")
tables <- catalog[catalog$type == "table", , drop = FALSE]
stopifnot(nrow(tables) == 195L)

html_cache <- new.env(parent = emptyenv())

read_html_cached <- function(relative_path) {
  if (exists(relative_path, envir = html_cache, inherits = FALSE)) {
    return(get(relative_path, envir = html_cache, inherits = FALSE))
  }
  full_path <- file.path(project_root, relative_path)
  value <- if (file.exists(full_path)) xml2::read_html(full_path) else NULL
  assign(relative_path, value, envir = html_cache)
  value
}

normalise_space <- function(x) {
  x <- gsub("\u00a0", " ", x, fixed = TRUE)
  trimws(gsub("[[:space:]]+", " ", x))
}

xpath_literal <- function(value) {
  if (!grepl("'", value, fixed = TRUE)) {
    return(paste0("'", value, "'"))
  }
  if (!grepl('"', value, fixed = TRUE)) {
    return(paste0('"', value, '"'))
  }
  pieces <- strsplit(value, "'", fixed = TRUE)[[1L]]
  paste0("concat('", paste(pieces, collapse = "', \"'\", '"), "')")
}

audit_one <- function(i) {
  row <- tables[i, , drop = FALSE]
  path_anchor <- strsplit(row$render_path, "#", fixed = TRUE)[[1L]]
  html_path <- path_anchor[[1L]]
  anchor_id <- if (length(path_anchor) >= 2L) path_anchor[[2L]] else row$label
  doc <- read_html_cached(html_path)

  anchor_count <- 0L
  table_count <- 0L
  gt_table_count <- 0L
  non_gt_table_count <- 0L
  caption_count <- 0L
  caption_text <- NA_character_
  resolved_reference <- FALSE
  render_locator <- "unresolved"
  figcaption_count <- 0L
  table_caption_count <- 0L
  thead_count <- 0L
  tbody_count <- 0L
  column_header_count <- 0L
  body_row_count <- 0L
  body_cell_count <- 0L
  stub_cell_count <- 0L
  row_group_count <- 0L
  spanner_count <- 0L
  footnote_block_count <- 0L
  source_note_block_count <- 0L
  aria_describedby_count <- 0L
  caption_relation_valid <- FALSE

  if (!is.null(doc)) {
    anchor_xpath <- paste0("//*[@id='", anchor_id, "']")
    anchors <- xml2::xml_find_all(doc, anchor_xpath)
    anchor_count <- length(anchors)
    targets <- anchors
    if (anchor_count >= 1L) {
      render_locator <- "Quarto anchor"
    } else if (!is.na(row$caption) && nzchar(row$caption)) {
      caption_xpath <- paste0(
        "//*[@data-tbl-cap=", xpath_literal(row$caption), "]"
      )
      targets <- xml2::xml_find_all(doc, caption_xpath)
      if (length(targets) >= 1L) {
        render_locator <- "nonconforming chunk located by data-tbl-cap"
      }
    }
    if (length(targets) >= 1L) {
      anchor <- targets[[1L]]
      rendered_tables <- xml2::xml_find_all(
        anchor, "self::table | .//table"
      )
      gt_tables <- xml2::xml_find_all(
        anchor,
        paste0(
          "self::table[contains(concat(' ', normalize-space(@class), ' '),",
          " ' gt_table ')] | ",
          ".//table[contains(concat(' ', normalize-space(@class), ' '),",
          " ' gt_table ')]"
        )
      )
      figcaptions <- xml2::xml_find_all(anchor, ".//figcaption")
      table_captions <- xml2::xml_find_all(anchor, ".//table/caption")
      captions <- xml2::xml_find_all(
        anchor,
        ".//figcaption | .//table/caption"
      )
      table_count <- length(rendered_tables)
      gt_table_count <- length(gt_tables)
      non_gt_table_count <- table_count - gt_table_count
      figcaption_count <- length(figcaptions)
      table_caption_count <- length(table_captions)
      caption_count <- length(captions)
      if (caption_count >= 1L) {
        caption_text <- normalise_space(xml2::xml_text(captions[[1L]]))
        resolved_reference <- !grepl("@tbl-", caption_text, fixed = TRUE)
      }
      if (table_count >= 1L) {
        rendered_table <- rendered_tables[[1L]]
        thead_count <- length(xml2::xml_find_all(rendered_table, "./thead"))
        tbody_count <- length(xml2::xml_find_all(rendered_table, "./tbody"))
        column_header_count <- length(xml2::xml_find_all(
          rendered_table, "./thead//th"
        ))
        body_row_count <- length(xml2::xml_find_all(
          rendered_table, "./tbody/tr"
        ))
        body_cell_count <- length(xml2::xml_find_all(
          rendered_table, "./tbody//td | ./tbody//th"
        ))
        stub_cell_count <- length(xml2::xml_find_all(
          rendered_table,
          ".//*[contains(concat(' ', normalize-space(@class), ' '), ' gt_stub ')]"
        ))
        row_group_count <- length(xml2::xml_find_all(
          rendered_table,
          paste0(
            ".//*[contains(concat(' ', normalize-space(@class), ' '),",
            " ' gt_group_heading ')]"
          )
        ))
        spanner_count <- length(xml2::xml_find_all(
          rendered_table,
          paste0(
            ".//*[contains(concat(' ', normalize-space(@class), ' '),",
            " ' gt_column_spanner ')]"
          )
        ))
        footnote_block_count <- length(xml2::xml_find_all(
          rendered_table,
          paste0(
            ".//*[contains(concat(' ', normalize-space(@class), ' '),",
            " ' gt_footnotes ')]"
          )
        ))
        source_note_block_count <- length(xml2::xml_find_all(
          rendered_table,
          paste0(
            ".//*[contains(concat(' ', normalize-space(@class), ' '),",
            " ' gt_sourcenotes ')]"
          )
        ))
      }
      aria_nodes <- xml2::xml_find_all(anchor, ".//*[@aria-describedby]")
      aria_describedby_count <- length(aria_nodes)
      if (caption_count >= 1L && aria_describedby_count >= 1L) {
        caption_ids <- xml2::xml_attr(captions, "id")
        caption_ids <- caption_ids[!is.na(caption_ids) & nzchar(caption_ids)]
        described_ids <- unlist(strsplit(
          xml2::xml_attr(aria_nodes, "aria-describedby"),
          "[[:space:]]+"
        ))
        caption_relation_valid <- any(caption_ids %in% described_ids)
      }
    }
  }

  native_gt <- gt_table_count >= 1L && non_gt_table_count == 0L
  semantic_core_present <- table_count == 1L && thead_count >= 1L &&
    tbody_count >= 1L && column_header_count >= 1L
  quarto_caption_owned <- anchor_count == 1L && figcaption_count == 1L &&
    table_caption_count == 0L
  caption_matches_source <- !is.na(caption_text) && !is.na(row$caption) &&
    grepl(row$caption, caption_text, fixed = TRUE)
  publication_structure_current <- native_gt && row$identifier_conforms &&
    semantic_core_present && caption_count == 1L && resolved_reference &&
    quarto_caption_owned && caption_relation_valid && caption_matches_source
  implementation <- if (native_gt) {
    if (identical(row$current_style, "semantic gt HTML table")) {
      "native gt: constructor visible in labelled chunk"
    } else {
      "native gt: labelled chunk calls a helper returning gt_tbl"
    }
  } else if (non_gt_table_count >= 1L) {
    if (identical(row$current_style, "semantic knitr table")) {
      "non-gt: knitr::kable"
    } else {
      "non-gt: other rendered HTML table"
    }
  } else if (anchor_count >= 1L && caption_count >= 1L) {
    "non-gt: code/stdout content placed under a Quarto table caption"
  } else {
    "unresolved rendered table"
  }

  manuscript_role <- if (grepl(
    "proposed main|component of proposed", row$proposed_role
  )) {
    "main-table component"
  } else {
    "supplemental-table candidate"
  }

  required_action <- if (native_gt && !row$identifier_conforms) {
    paste(
      "Retain native gt and all prepared values/order; replace the chunk",
      "label with the approved unique tbl-h06-* identifier so Quarto owns",
      "a valid table anchor and caption relationship."
    )
  } else if (native_gt) {
    paste(
      "Retain native gt; preserve prepared input, raw values, row order,",
      "Quarto caption ownership, and semantic table anatomy."
    )
  } else if (non_gt_table_count >= 1L) {
    paste(
      "Convert the existing display to native gt without changing prepared",
      "input, values, units, missingness, row/column order, or caption."
    )
  } else if (anchor_count >= 1L && caption_count >= 1L) {
    paste(
      "Convert the code/stdout pseudo-table to native gt without changing",
      "the evaluated formula strings, their order, or the Quarto caption."
    )
  } else {
    paste(
      "Resolve the missing/stale targeted render before implementation;",
      "the accepted endpoint must be a native gt table."
    )
  }

  data.frame(
    document = row$document,
    manuscript_role = manuscript_role,
    label = row$label,
    caption = row$caption,
    source_qmd = row$source_qmd,
    source_line = row$source_line,
    render_html = html_path,
    render_anchor = anchor_id,
    html_exists = !is.null(doc),
    anchor_count = anchor_count,
    rendered_table_count = table_count,
    rendered_gt_table_count = gt_table_count,
    rendered_non_gt_table_count = non_gt_table_count,
    caption_count = caption_count,
    figcaption_count = figcaption_count,
    table_caption_count = table_caption_count,
    rendered_caption = caption_text,
    caption_matches_source = caption_matches_source,
    reference_resolved = resolved_reference,
    aria_describedby_count = aria_describedby_count,
    caption_relation_valid = caption_relation_valid,
    render_locator = render_locator,
    identifier_conforms = row$identifier_conforms,
    thead_count = thead_count,
    tbody_count = tbody_count,
    column_header_count = column_header_count,
    body_row_count = body_row_count,
    body_cell_count = body_cell_count,
    stub_cell_count = stub_cell_count,
    row_group_count = row_group_count,
    spanner_count = spanner_count,
    footnote_block_count = footnote_block_count,
    source_note_block_count = source_note_block_count,
    semantic_core_present = semantic_core_present,
    quarto_caption_owned = quarto_caption_owned,
    current_implementation = implementation,
    native_gt_current = native_gt,
    publication_structure_current = publication_structure_current,
    manual_visual_accessibility_review_required = TRUE,
    manual_review_scope = paste(
      "Normal and narrow width; 200% zoom; clipping/wrapping; header/stub",
      "reading order; notes; contrast; and colour-independent meaning."
    ),
    target_implementation = "native gt_tbl printed from labelled knitr cell",
    conversion_required = !native_gt,
    required_action = required_action,
    evidence = "QMD source location plus current targeted Nature Health HTML",
    stringsAsFactors = FALSE
  )
}

audit <- do.call(rbind, lapply(seq_len(nrow(tables)), audit_one))
row.names(audit) <- NULL

write.csv(
  audit,
  file.path(out_dir, "phase2_gt_table_audit.csv"),
  row.names = FALSE,
  na = ""
)

conversion_targets <- audit[audit$conversion_required, , drop = FALSE]
write.csv(
  conversion_targets,
  file.path(out_dir, "phase2_gt_conversion_targets.csv"),
  row.names = FALSE,
  na = ""
)

document_levels <- unique(audit$document)
document_summary <- do.call(rbind, lapply(document_levels, function(document) {
  current <- audit[audit$document == document, , drop = FALSE]
  data.frame(
    document = document,
    table_candidates = nrow(current),
    native_gt_current = sum(current$native_gt_current),
    conversion_required = sum(current$conversion_required),
    conversion_labels = if (any(current$conversion_required)) {
      paste(current$label[current$conversion_required], collapse = " | ")
    } else {
      ""
    },
    nonconforming_identifier_count = sum(!current$identifier_conforms),
    nonconforming_identifiers = if (any(!current$identifier_conforms)) {
      paste(current$label[!current$identifier_conforms], collapse = " | ")
    } else {
      ""
    },
    semantic_core_current = sum(current$semantic_core_present),
    publication_structure_current = sum(
      current$publication_structure_current
    ),
    structure_change_required = sum(
      !current$publication_structure_current
    ),
    final_requirement = paste(
      "Every main and supplemental table is a native gt_tbl printed from a",
      "labelled knitr cell."
    ),
    stringsAsFactors = FALSE
  )
}))
row.names(document_summary) <- NULL
write.csv(
  document_summary,
  file.path(out_dir, "phase2_gt_document_summary.csv"),
  row.names = FALSE,
  na = ""
)

summary_lines <- c(
  "# Phase 2 `gt` table audit",
  "",
  paste0("- Current table candidates audited: ", nrow(audit)),
  paste0("- Current native `gt` renders: ", sum(audit$native_gt_current)),
  paste0("- Current non-`gt` renders: ", sum(audit$conversion_required)),
  paste0(
    "- Resolved unique table anchors: ",
    sum(audit$anchor_count == 1L)
  ),
  paste0(
    "- Tables with exactly one resolved Quarto caption: ",
    sum(audit$caption_count == 1L & audit$reference_resolved)
  ),
  paste0(
    "- Tables whose rendered caption matches the source caption: ",
    sum(audit$caption_matches_source)
  ),
  paste0(
    "- Rendered semantic table cores (`thead` + `tbody` + headers): ",
    sum(audit$semantic_core_present)
  ),
  paste0(
    "- Current complete native-`gt` publication structures: ",
    sum(audit$publication_structure_current)
  ),
  paste0(
    "- Nonconforming `tbl-` identifiers: ",
    sum(!audit$identifier_conforms)
  ),
  paste0(
    "- Endpoints requiring conversion or identifier repair: ",
    sum(!audit$publication_structure_current)
  ),
  "",
  "All manuscript main and supplemental table endpoints are proposed to use",
  "native `gt_tbl` objects printed from labelled knitr cells. The current",
  "non-`gt` conversion targets are listed in",
  "`phase2_gt_conversion_targets.csv`. This audit does not execute QMD code",
  "or assess scientific values."
)
writeLines(
  summary_lines,
  file.path(out_dir, "phase2_gt_table_audit_summary.md")
)

context <- c(
  paste0("Run timestamp: ", format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE)),
  paste0("Working directory: ", project_root),
  "Command: Rscript --vanilla scripts/report_harmonization/audit_gt_tables.R",
  "Scope: QMD/catalog metadata and current targeted HTML structure only",
  paste0("R: ", R.version.string),
  paste0("gt: ", as.character(utils::packageVersion("gt"))),
  paste0("knitr: ", as.character(utils::packageVersion("knitr"))),
  paste0("xml2: ", as.character(utils::packageVersion("xml2"))),
  paste0("Quarto: ", system2("quarto", "--version", stdout = TRUE)),
  "Nature Health configured target: HTML",
  "Submission-stage DOCX: deferred by _quarto-nathealth.yml commentary",
  "No packages installed or updated"
)
writeLines(context, file.path(out_dir, "phase2_gt_table_audit_runtime.txt"))

message(paste(summary_lines, collapse = "\n"))
