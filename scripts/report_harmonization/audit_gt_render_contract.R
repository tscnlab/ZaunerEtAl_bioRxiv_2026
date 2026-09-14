#!/usr/bin/env Rscript

# Structural audit of current Nature Health HTML for the 195 source-audited
# manuscript table endpoints. This script reads HTML only. It does not execute
# QMD chunks or inspect, calculate, or validate scientific values.

options(stringsAsFactors = FALSE)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "audit", "report_harmonization")
source_audit_path <- file.path(out_dir, "phase4_gt_source_audit.csv")

stopifnot(identical(as.character(getRversion()), "4.6.1"))

project_library <- file.path(
  root, "renv", "library", "macos", "R-4.6", "aarch64-apple-darwin23"
)
if (dir.exists(project_library)) {
  .libPaths(c(project_library, .libPaths()))
}
for (package in c("digest", "xml2")) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(package, " is required and is not available; no package was installed")
  }
}
if (!file.exists(source_audit_path)) {
  stop("Run audit_gt_source_contract.R first", call. = FALSE)
}

source_audit <- read.csv(source_audit_path, check.names = FALSE)
stopifnot(nrow(source_audit) == 195L)

html_map <- c(
  Descriptives = "_build/nathealth/notebooks/descriptives.html",
  setNames(
    file.path(
      "_build", "nathealth", "notebooks", "hypotheses",
      paste0("H", sprintf("%02d", 1:11), ".html")
    ),
    paste0("H", sprintf("%02d", 1:11))
  )
)

accepted_target_render <- c(
  Descriptives = TRUE,
  setNames(rep(FALSE, 11L), paste0("H", sprintf("%02d", 1:11)))
)

normalise_space <- function(x) {
  x <- gsub("\u00a0", " ", x, fixed = TRUE)
  trimws(gsub("[[:space:]]+", " ", x))
}

html_cache <- new.env(parent = emptyenv())
read_html <- function(relative_path) {
  if (exists(relative_path, envir = html_cache, inherits = FALSE)) {
    return(get(relative_path, envir = html_cache, inherits = FALSE))
  }
  path <- file.path(root, relative_path)
  doc <- if (file.exists(path)) xml2::read_html(path) else NULL
  assign(relative_path, doc, envir = html_cache)
  doc
}

audit_one <- function(i) {
  source <- source_audit[i, , drop = FALSE]
  document <- source$document[[1L]]
  label <- source$label[[1L]]
  caption <- source$caption[[1L]]
  html_path <- unname(html_map[[document]])
  full_html_path <- file.path(root, html_path)
  doc <- read_html(html_path)

  anchor_count <- table_count <- gt_table_count <- caption_count <- 0L
  figcaption_count <- table_caption_count <- thead_count <- tbody_count <- 0L
  column_header_count <- body_row_count <- aria_describedby_count <- 0L
  caption_relation_valid <- FALSE
  rendered_caption <- ""
  unresolved_reference <- FALSE

  if (!is.null(doc)) {
    anchors <- xml2::xml_find_all(
      doc,
      paste0("//*[@id=", "'", label, "']")
    )
    anchor_count <- length(anchors)
    if (anchor_count == 1L) {
      anchor <- anchors[[1L]]
      tables <- xml2::xml_find_all(anchor, "self::table | .//table")
      gt_tables <- xml2::xml_find_all(
        anchor,
        paste0(
          "self::table[contains(concat(' ', normalize-space(@class), ' '),",
          " ' gt_table ')] | .//table[contains(concat(' ',",
          " normalize-space(@class), ' '), ' gt_table ')]"
        )
      )
      figcaptions <- xml2::xml_find_all(anchor, ".//figcaption")
      table_captions <- xml2::xml_find_all(anchor, ".//table/caption")
      captions <- xml2::xml_find_all(
        anchor, ".//figcaption | .//table/caption"
      )
      table_count <- length(tables)
      gt_table_count <- length(gt_tables)
      figcaption_count <- length(figcaptions)
      table_caption_count <- length(table_captions)
      caption_count <- length(captions)
      if (caption_count == 1L) {
        rendered_caption <- normalise_space(xml2::xml_text(captions[[1L]]))
        unresolved_reference <- grepl("@tbl-", rendered_caption, fixed = TRUE)
      }
      if (table_count == 1L) {
        table <- tables[[1L]]
        thead_count <- length(xml2::xml_find_all(table, "./thead"))
        tbody_count <- length(xml2::xml_find_all(table, "./tbody"))
        column_header_count <- length(xml2::xml_find_all(table, "./thead//th"))
        body_row_count <- length(xml2::xml_find_all(table, "./tbody/tr"))
      }
      aria_nodes <- xml2::xml_find_all(anchor, ".//*[@aria-describedby]")
      aria_describedby_count <- length(aria_nodes)
      if (caption_count == 1L && aria_describedby_count >= 1L) {
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

  caption_matches_source <- nzchar(rendered_caption) &&
    grepl(caption, rendered_caption, fixed = TRUE)
  semantic_core <- table_count == 1L && thead_count == 1L &&
    tbody_count == 1L && column_header_count >= 1L && body_row_count >= 1L
  render_contract_complete <- anchor_count == 1L && table_count == 1L &&
    gt_table_count == 1L && caption_count == 1L &&
    figcaption_count == 1L && table_caption_count == 0L &&
    caption_relation_valid && caption_matches_source && semantic_core &&
    !unresolved_reference

  data.frame(
    document = document,
    manuscript_role = source$manuscript_role,
    label = label,
    caption = caption,
    source_qmd = source$source_qmd,
    source_sha256 = source$source_sha256,
    render_html = html_path,
    html_exists = !is.null(doc),
    html_sha256 = if (file.exists(full_html_path)) {
      digest::digest(full_html_path, algo = "sha256", file = TRUE)
    } else {
      ""
    },
    anchor_count = anchor_count,
    rendered_table_count = table_count,
    rendered_gt_table_count = gt_table_count,
    caption_count = caption_count,
    figcaption_count = figcaption_count,
    table_caption_count = table_caption_count,
    rendered_caption = rendered_caption,
    caption_matches_source = caption_matches_source,
    aria_describedby_count = aria_describedby_count,
    caption_relation_valid = caption_relation_valid,
    thead_count = thead_count,
    tbody_count = tbody_count,
    column_header_count = column_header_count,
    body_row_count = body_row_count,
    semantic_core_present = semantic_core,
    unresolved_reference = unresolved_reference,
    render_contract_complete = render_contract_complete,
    targeted_render_accepted = unname(accepted_target_render[[document]]),
    visual_qa_status = if (identical(document, "Descriptives")) {
      "accepted targeted HTML; principal role remains provisional"
    } else {
      "pending serial Phase 4 targeted render and visual QA"
    },
    integration_complete = render_contract_complete &&
      unname(accepted_target_render[[document]]),
    stringsAsFactors = FALSE
  )
}

audit <- do.call(rbind, lapply(seq_len(nrow(source_audit)), audit_one))
row.names(audit) <- NULL

write.csv(
  audit,
  file.path(out_dir, "phase4_gt_render_audit.csv"),
  row.names = FALSE,
  na = ""
)

summary <- aggregate(
  cbind(
    table_count = rep(1L, nrow(audit)),
    current_native_gt_render = as.integer(
      audit$rendered_gt_table_count == 1L
    ),
    render_contract_complete = as.integer(audit$render_contract_complete),
    integration_complete = as.integer(audit$integration_complete)
  ) ~ document,
  data = audit,
  FUN = sum
)
summary$targeted_render_accepted <- vapply(summary$document, function(x) {
  unique(audit$targeted_render_accepted[audit$document == x])
}, logical(1))
summary$pending_labels <- vapply(summary$document, function(x) {
  paste(audit$label[
    audit$document == x & !audit$integration_complete
  ], collapse = " | ")
}, character(1))

write.csv(
  summary,
  file.path(out_dir, "phase4_gt_render_document_summary.csv"),
  row.names = FALSE,
  na = ""
)

runtime <- c(
  paste0("Run timestamp: ", format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE)),
  paste0("Working directory: ", root),
  "Command: Rscript --vanilla scripts/report_harmonization/audit_gt_render_contract.R",
  "Scope: current Nature Health HTML structure for 195 source-audited tables",
  paste0("R: ", R.version.string),
  paste0("gt: ", as.character(utils::packageVersion("gt"))),
  paste0("xml2: ", as.character(utils::packageVersion("xml2"))),
  paste0("Quarto: ", system2("quarto", "--version", stdout = TRUE)),
  "No QMD chunk was executed; no scientific data or stored output was read",
  "No package was installed or updated"
)
writeLines(runtime, file.path(out_dir, "phase4_gt_render_audit_runtime.txt"))

cat(
  "Current table endpoints: ", nrow(audit), "\n",
  "Current native gt HTML endpoints at current labels: ",
  sum(audit$rendered_gt_table_count == 1L), "\n",
  "Current complete HTML table structures: ",
  sum(audit$render_contract_complete), "\n",
  "Accepted source/render/visual integrations: ",
  sum(audit$integration_complete), "\n",
  "Pending documents: ",
  paste(unique(audit$document[!audit$integration_complete]), collapse = ", "),
  "\n",
  sep = ""
)
