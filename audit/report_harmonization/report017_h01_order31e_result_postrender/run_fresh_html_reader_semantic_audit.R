#!/usr/bin/env Rscript

stopifnot(getRversion() == "4.6.1")

suppressPackageStartupMessages({
  library(rvest)
  library(xml2)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H01.html"
)
build_root <- file.path(root, "_build/nathealth")
evidence_dir <- file.path(
  root,
  "audit/report_harmonization/report017_h01_order31e_result_postrender"
)

stopifnot(file.exists(html_path), dir.exists(evidence_dir))

doc <- read_html(html_path)
main_nodes <- html_elements(doc, "main#quarto-document-content")
stopifnot(length(main_nodes) == 1L)
main <- main_nodes[[1]]

clean_text <- function(node) {
  value <- html_text2(node)
  value <- gsub("[[:space:]]+", " ", value)
  trimws(value)
}

outside_source_modal <- function(nodes) {
  if (!length(nodes)) return(logical())
  !vapply(nodes, function(node) {
    length(xml_find_all(
      node,
      "ancestor::*[@id='quarto-embedded-source-code-modal']"
    )) > 0L
  }, logical(1))
}

table_endpoints <- html_elements(main, '.quarto-float[id^="tbl-h01-"]')
table_endpoints <- table_endpoints[outside_source_modal(table_endpoints)]
table_ids <- html_attr(table_endpoints, "id")

table_rows <- lapply(seq_along(table_endpoints), function(i) {
  endpoint <- table_endpoints[[i]]
  tables <- html_elements(endpoint, "table.gt_table")
  captions <- html_elements(endpoint, "figcaption.quarto-float-caption")
  heads <- html_elements(endpoint, "table.gt_table thead")
  bodies <- html_elements(endpoint, "table.gt_table tbody")
  data.frame(
    table_id = table_ids[[i]],
    native_gt_count = length(tables),
    quarto_caption_count = length(captions),
    caption = if (length(captions)) clean_text(captions[[1]]) else "",
    thead_count = length(heads),
    thead_cells = length(html_elements(endpoint, "table.gt_table thead th")),
    tbody_count = length(bodies),
    body_rows = length(html_elements(endpoint, "table.gt_table tbody tr")),
    body_cells = length(html_elements(endpoint, "table.gt_table tbody td")),
    pass = length(tables) == 1L &&
      length(captions) == 1L &&
      nzchar(if (length(captions)) clean_text(captions[[1]]) else "") &&
      length(heads) == 1L &&
      length(bodies) == 1L &&
      length(html_elements(endpoint, "table.gt_table thead th")) > 0L &&
      length(html_elements(endpoint, "table.gt_table tbody tr")) > 0L &&
      length(html_elements(endpoint, "table.gt_table tbody td")) > 0L,
    stringsAsFactors = FALSE
  )
})
table_audit <- do.call(rbind, table_rows)

figure_endpoints <- html_elements(main, '.quarto-float[id^="fig-h01-"]')
figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
figure_ids <- html_attr(figure_endpoints, "id")

figure_rows <- lapply(seq_along(figure_endpoints), function(i) {
  endpoint <- figure_endpoints[[i]]
  captions <- html_elements(endpoint, "figcaption.quarto-float-caption")
  images <- html_elements(endpoint, "img")
  image_src <- if (length(images)) html_attr(images[[1]], "src") else ""
  image_alt <- if (length(images)) html_attr(images[[1]], "alt") else ""
  endpoint_alt <- html_attr(endpoint, "alt")
  if (is.na(endpoint_alt)) endpoint_alt <- ""
  image_path <- if (nzchar(image_src)) {
    normalizePath(
      file.path(dirname(html_path), image_src),
      winslash = "/",
      mustWork = FALSE
    )
  } else {
    ""
  }
  data.frame(
    figure_id = figure_ids[[i]],
    image_count = length(images),
    quarto_caption_count = length(captions),
    caption = if (length(captions)) clean_text(captions[[1]]) else "",
    image_src = image_src,
    image_alt = image_alt,
    endpoint_alt = endpoint_alt,
    source_exists = nzchar(image_path) && file.exists(image_path),
    source_bytes = if (nzchar(image_path) && file.exists(image_path)) {
      file.info(image_path)$size
    } else {
      NA_real_
    },
    pass = length(images) == 1L &&
      length(captions) == 1L &&
      nzchar(if (length(captions)) clean_text(captions[[1]]) else "") &&
      !is.na(image_alt) && nzchar(image_alt) &&
      nzchar(endpoint_alt) &&
      nzchar(image_path) && file.exists(image_path),
    stringsAsFactors = FALSE
  )
})
figure_audit <- do.call(rbind, figure_rows)

all_id_nodes <- html_elements(doc, "[id]")
all_ids <- html_attr(all_id_nodes, "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
duplicate_ids <- unique(all_ids[duplicated(all_ids)])
duplicate_id_audit <- if (length(duplicate_ids)) {
  do.call(rbind, lapply(duplicate_ids, function(id) {
    nodes <- all_id_nodes[html_attr(all_id_nodes, "id") == id]
    endpoint <- vapply(nodes, function(node) {
      parent <- xml_find_first(
        node,
        "ancestor::*[starts-with(@id,'tbl-h01-') or starts-with(@id,'fig-h01-')][1]"
      )
      if (inherits(parent, "xml_missing")) "" else xml_attr(parent, "id")
    }, character(1))
    data.frame(
      id = id,
      occurrences = length(nodes),
      owning_endpoints = paste(unique(endpoint[nzchar(endpoint)]), collapse = "; "),
      all_within_gt_tables = all(vapply(nodes, function(node) {
        length(xml_find_all(node, "ancestor::table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]")) > 0L
      }, logical(1))),
      stringsAsFactors = FALSE
    )
  }))
} else {
  data.frame(
    id = character(),
    occurrences = integer(),
    owning_endpoints = character(),
    all_within_gt_tables = logical(),
    stringsAsFactors = FALSE
  )
}

reader_anchor_nodes <- html_elements(doc, "a[href]")
in_source_modal <- vapply(reader_anchor_nodes, function(node) {
  length(xml_find_all(
    node,
    "ancestor::*[@id='quarto-embedded-source-code-modal']"
  )) > 0L
}, logical(1))
reader_anchor_nodes <- reader_anchor_nodes[!in_source_modal]

hrefs <- html_attr(reader_anchor_nodes, "href")
link_text <- vapply(reader_anchor_nodes, clean_text, character(1))

doc_cache <- new.env(parent = emptyenv())
anchor_exists <- function(target_path, fragment) {
  if (!nzchar(fragment)) return(TRUE)
  if (!grepl("\\.html?$", target_path, ignore.case = TRUE)) return(TRUE)
  key <- normalizePath(target_path, winslash = "/", mustWork = TRUE)
  if (!exists(key, envir = doc_cache, inherits = FALSE)) {
    assign(key, read_html(key), envir = doc_cache)
  }
  target_doc <- get(key, envir = doc_cache, inherits = FALSE)
  length(html_elements(target_doc, paste0("#", fragment))) == 1L
}

link_rows <- lapply(seq_along(hrefs), function(i) {
  href <- hrefs[[i]]
  text <- link_text[[i]]
  external <- grepl("^(https?|mailto|tel):", href, ignore.case = TRUE)
  forbidden <- !external && (
    grepl("\\.qmd($|[?#])", href, ignore.case = TRUE) ||
      grepl("file://", href, fixed = TRUE) ||
      grepl("_build", href, fixed = TRUE) ||
      grepl("/Users/", href, fixed = TRUE) ||
      grepl("^[A-Za-z]:[/\\\\]", href)
  )
  unsupported_scheme <- grepl("^[A-Za-z][A-Za-z0-9+.-]*:", href) &&
    !external && !grepl("^data:", href, ignore.case = TRUE)
  path_part <- sub("[?#].*$", "", href)
  fragment <- if (grepl("#", href, fixed = TRUE)) {
    URLdecode(sub("^[^#]*#", "", href))
  } else {
    ""
  }
  if (external || grepl("^data:", href, ignore.case = TRUE)) {
    resolved_path <- ""
    target_exists <- TRUE
    fragment_resolves <- TRUE
    kind <- "external"
  } else if (unsupported_scheme) {
    resolved_path <- ""
    target_exists <- FALSE
    fragment_resolves <- FALSE
    kind <- "unsupported_scheme"
  } else {
    resolved_path <- suppressWarnings(if (!nzchar(path_part)) {
      html_path
    } else if (startsWith(path_part, "/")) {
      normalizePath(
        file.path(build_root, sub("^/+", "", path_part)),
        winslash = "/",
        mustWork = FALSE
      )
    } else {
      normalizePath(
        file.path(dirname(html_path), URLdecode(path_part)),
        winslash = "/",
        mustWork = FALSE
      )
    })
    target_exists <- file.exists(resolved_path)
    fragment_resolves <- target_exists &&
      anchor_exists(resolved_path, fragment)
    kind <- "local"
  }
  known_doc001_hold <- identical(text, "Supplementary information") &&
    identical(href, "../../supplementary_information.html") &&
    !target_exists
  data.frame(
    link_text = text,
    href = href,
    kind = kind,
    resolved_path = resolved_path,
    target_exists = target_exists,
    fragment = fragment,
    fragment_resolves = fragment_resolves,
    forbidden_reader_target = forbidden,
    known_doc001_hold = known_doc001_hold,
    pass = !forbidden && !unsupported_scheme &&
      target_exists && fragment_resolves,
    stringsAsFactors = FALSE
  )
})
link_audit <- do.call(rbind, link_rows)

main_reader_doc <- read_html(as.character(main))
main_reader <- html_element(main_reader_doc, "main#quarto-document-content")
xml_remove(html_elements(main_reader, "#quarto-embedded-source-code-modal"))
main_text <- clean_text(main_reader)
figure_caption_nodes <- do.call(c, lapply(figure_endpoints, function(endpoint) {
  html_elements(endpoint, "figcaption")
}))
compact_text <- paste(
  c(
    vapply(table_endpoints, clean_text, character(1)),
    vapply(
      figure_caption_nodes,
      clean_text,
      character(1)
    )
  ),
  collapse = " "
)

compact_nodes <- c(
  lapply(table_endpoints, function(endpoint) {
    html_elements(endpoint, "figcaption, th, td")
  }),
  list(figure_caption_nodes)
)
compact_nodes <- do.call(c, compact_nodes)
compact_values <- vapply(compact_nodes, clean_text, character(1))
bh_index <- grepl("\\bBH\\b", compact_values)
compact_bh_audit <- if (any(bh_index)) {
  nodes <- compact_nodes[bh_index]
  do.call(rbind, lapply(seq_along(nodes), function(i) {
    node <- nodes[[i]]
    parent <- xml_find_first(
      node,
      "ancestor::*[starts-with(@id,'tbl-h01-') or starts-with(@id,'fig-h01-')][1]"
    )
    data.frame(
      endpoint = if (inherits(parent, "xml_missing")) "" else xml_attr(parent, "id"),
      element = xml_name(node),
      text = clean_text(node),
      stringsAsFactors = FALSE
    )
  }))
} else {
  data.frame(
    endpoint = character(),
    element = character(),
    text = character(),
    stringsAsFactors = FALSE
  )
}

expected_sections <- c(
  "hypothesis-and-analytical-question",
  "h01-preregistration-deviations",
  "what-was-analysed",
  "statistical-models",
  "results-overview",
  "primary-near-eye-results",
  "complementary-chest-results",
  "matched-near-eye-and-chest-evidence",
  "exact-fitted-samples",
  "model-checks",
  "sensitivity-analyses",
  "interpretation",
  "limitations",
  "technical-formula-and-implementation-details",
  "figure-and-table-source-data"
)
missing_sections <- expected_sections[
  !vapply(expected_sections, function(id) {
    length(html_elements(doc, paste0("#", id))) == 1L
  }, logical(1))
]

companion_href <- "../../audit/hypotheses/H01/H01_analysis_preparation.html"
prep04_href <- "../../notebooks/preparation/04_metric_derivation.html"
prep06_href <- "../../notebooks/preparation/06_model_ready_datasets.html"

deviation_links <- link_audit[
  grepl("preregistration_deviations\\.html#(dev|imp|rep)-", link_audit$href),
  ,
  drop = FALSE
]
source_data_links <- link_audit[
  grepl("artifacts/11_source_data/H01/", link_audit$href, fixed = TRUE),
  ,
  drop = FALSE
]

active_links <- html_elements(doc, ".sidebar-link.active[href]")
active_hrefs <- html_attr(active_links, "href")

checks <- data.frame(
  check = c(
    "exact_native_gt_tables",
    "all_tables_semantically_complete",
    "principal_table_present",
    "exact_labelled_figures",
    "all_figures_semantically_complete",
    "principal_figure_present",
    "unique_document_ids",
    "expected_sections_present",
    "answer_in_brief_hierarchy",
    "no_cell_errors_or_warnings",
    "no_unresolved_reference_elements",
    "no_unresolved_reference_text",
    "no_raw_console_or_object_leak",
    "no_internal_workflow_terms",
    "fdr_not_bh_in_compact_displays",
    "all_reader_links_resolve_or_known_doc001_hold",
    "no_forbidden_reader_targets",
    "companion_link_resolves",
    "preparation_04_link_resolves",
    "preparation_06_link_resolves",
    "all_exact_deviation_anchors_resolve",
    "all_source_data_links_resolve",
    "active_h01_navigation"
  ),
  status = c(
    length(table_endpoints) == 36L && length(unique(table_ids)) == 36L,
    nrow(table_audit) == 36L && all(table_audit$pass),
    "tbl-h01-primary-publication-summary" %in% table_ids,
    length(figure_endpoints) == 10L && length(unique(figure_ids)) == 10L,
    nrow(figure_audit) == 10L && all(figure_audit$pass),
    "fig-h01-model-support" %in% figure_ids,
    length(duplicate_ids) == 0L,
    length(missing_sections) == 0L,
    length(html_elements(
      doc,
      "#hypothesis-and-analytical-question .callout-note[title='Answer in brief']"
    )) == 1L,
    length(html_elements(
      doc,
      ".cell-output-error, .cell-output-warning, .callout-warning"
    )) == 0L,
    length(html_elements(
      doc,
      ".quarto-unresolved-ref, .quarto-unresolved-cite"
    )) == 0L,
    !grepl("\\?@(fig|tbl|sec)-|\\(ref\\?\\)", main_text),
    !grepl(
      "<environment:|# A tibble|Rows: [0-9]+ Columns:|\\$site_full|\\$participant\\$",
      main_text
    ),
    !grepl(
      "\\bV0\\b|manuscript-prepared|submitted-versus|\\bStage [1-4]\\b|\\bGate [A-Z0-9]",
      main_text,
      ignore.case = TRUE
    ),
    !grepl("\\bBH\\b", compact_text),
    nrow(link_audit) > 0L && all(
      link_audit$pass | link_audit$known_doc001_hold
    ) && sum(link_audit$known_doc001_hold) == 1L,
    !any(link_audit$forbidden_reader_target),
    any(link_audit$href == companion_href & link_audit$pass),
    any(link_audit$href == prep04_href & link_audit$pass),
    any(link_audit$href == prep06_href & link_audit$pass),
    nrow(deviation_links) > 0L &&
      length(unique(deviation_links$fragment)) == 36L &&
      all(deviation_links$pass),
    nrow(source_data_links) > 0L && all(source_data_links$pass),
    length(active_hrefs) == 1L &&
      identical(active_hrefs, "../../notebooks/hypotheses/H01.html")
  ),
  evidence = c(
    sprintf("%d endpoints; %d unique labels", length(table_ids), length(unique(table_ids))),
    sprintf("%d of %d complete", sum(table_audit$pass), nrow(table_audit)),
    "tbl-h01-primary-publication-summary",
    sprintf("%d endpoints; %d unique labels", length(figure_ids), length(unique(figure_ids))),
    sprintf("%d of %d complete", sum(figure_audit$pass), nrow(figure_audit)),
    "fig-h01-model-support",
    if (length(duplicate_ids)) paste(duplicate_ids, collapse = "; ") else "zero duplicate IDs",
    if (length(missing_sections)) paste(missing_sections, collapse = "; ") else paste(length(expected_sections), "required sections"),
    "one Answer in brief note inside the hypothesis section",
    paste(length(html_elements(doc, ".cell-output-error")), "errors and", length(html_elements(doc, ".cell-output-warning")), "warnings"),
    "zero unresolved-reference elements",
    "zero unresolved-reference tokens in main reader text",
    "zero raw-console or leaked-object markers in main reader text",
    "zero prohibited internal workflow terms in main reader text",
    "zero standalone BH abbreviations in table and figure compact text",
    sprintf(
      "%d reader links checked; %d known DOC-001 hold",
      nrow(link_audit),
      sum(link_audit$known_doc001_hold)
    ),
    sprintf("%d forbidden targets", sum(link_audit$forbidden_reader_target)),
    companion_href,
    prep04_href,
    prep06_href,
    sprintf("%d links; %d unique exact anchors", nrow(deviation_links), length(unique(deviation_links$fragment))),
    sprintf("%d displayed source-data links", nrow(source_data_links)),
    paste(active_hrefs, collapse = "; ")
  ),
  stringsAsFactors = FALSE
)

checks$status <- ifelse(checks$status, "PASS", "FAIL")

write.csv(
  table_audit,
  file.path(evidence_dir, "table_semantic_audit.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  figure_audit,
  file.path(evidence_dir, "figure_semantic_audit.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  link_audit,
  file.path(evidence_dir, "link_audit.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  duplicate_id_audit,
  file.path(evidence_dir, "duplicate_id_audit.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  compact_bh_audit,
  file.path(evidence_dir, "compact_bh_audit.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  checks,
  file.path(evidence_dir, "semantic_status.csv"),
  row.names = FALSE,
  na = ""
)

if (any(checks$status != "PASS")) {
  if (length(warnings())) print(utils::head(warnings(), 20L))
  print(checks[checks$status != "PASS", , drop = FALSE])
  quit(status = 1L)
}

cat(sprintf(
  "Semantic audit passed: %d native gt tables, %d labelled figures, %d reader links, %d exact deviation anchors.\n",
  nrow(table_audit),
  nrow(figure_audit),
  nrow(link_audit),
  length(unique(deviation_links$fragment))
))
