#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))
suppressPackageStartupMessages({
  library(rvest)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"))

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H02/report017_order33f_result_render"
)
html_path <- file.path(root, "_build/nathealth/notebooks/hypotheses/H02.html")
build_root <- file.path(root, "_build/nathealth")
semantic_dir <- Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR")
stopifnot(
  dir.exists(evidence_dir),
  file.exists(html_path),
  dir.exists(semantic_dir)
)

write_csv <- function(object, filename) {
  utils::write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

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

document <- read_html(html_path)
main_nodes <- html_elements(document, "main#quarto-document-content")
stopifnot(length(main_nodes) == 1L)
main <- main_nodes[[1L]]

expected_tables <- c(
  "tbl-h02-near-variation",
  "tbl-h02-near-dominance",
  "tbl-h02-near-relevance",
  "tbl-h02-near-windows",
  "tbl-h02-chest-variation",
  "tbl-h02-chest-dominance",
  "tbl-h02-chest-relevance",
  "tbl-h02-chest-windows",
  "tbl-h02-near-diagnostics",
  "tbl-h02-chest-diagnostics",
  "tbl-h02-sensitivity",
  "tbl-h02-near-sample",
  "tbl-h02-chest-sample",
  "tbl-h02-model-deviations",
  "tbl-h02-data-deviations"
)
expected_figures <- c(
  "fig-h02-near-patterns",
  "fig-h02-chest-patterns",
  "fig-h02-paired-placement-curves",
  "fig-h02-near-diagnostics",
  "fig-h02-chest-diagnostics"
)

table_endpoints <- html_elements(main, '.quarto-float[id^="tbl-h02-"]')
table_endpoints <- table_endpoints[outside_source_modal(table_endpoints)]
table_ids <- html_attr(table_endpoints, "id")
table_rows <- lapply(seq_along(table_endpoints), function(index) {
  endpoint <- table_endpoints[[index]]
  tables <- html_elements(endpoint, "table.gt_table")
  captions <- html_elements(endpoint, "figcaption.quarto-float-caption")
  data.frame(
    order = index,
    table_id = table_ids[[index]],
    native_gt_count = length(tables),
    caption_count = length(captions),
    caption = if (length(captions)) clean_text(captions[[1L]]) else "",
    thead_count = length(html_elements(endpoint, "table.gt_table thead")),
    tbody_count = length(html_elements(endpoint, "table.gt_table tbody")),
    header_cells = length(html_elements(endpoint, "table.gt_table thead th")),
    body_rows = length(html_elements(endpoint, "table.gt_table tbody tr")),
    body_cells = length(html_elements(endpoint, "table.gt_table tbody td")),
    pass = length(tables) == 1L &&
      length(captions) == 1L &&
      nzchar(if (length(captions)) clean_text(captions[[1L]]) else "") &&
      length(html_elements(endpoint, "table.gt_table thead")) == 1L &&
      length(html_elements(endpoint, "table.gt_table tbody")) == 1L &&
      length(html_elements(endpoint, "table.gt_table thead th")) > 0L &&
      length(html_elements(endpoint, "table.gt_table tbody tr")) > 0L,
    stringsAsFactors = FALSE
  )
})
table_audit <- do.call(rbind, table_rows)
write_csv(table_audit, "table_endpoint_audit.csv")

figure_endpoints <- html_elements(main, '.quarto-float[id^="fig-h02-"]')
figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
figure_ids <- html_attr(figure_endpoints, "id")
figure_rows <- lapply(seq_along(figure_endpoints), function(index) {
  endpoint <- figure_endpoints[[index]]
  captions <- html_elements(endpoint, "figcaption.quarto-float-caption")
  images <- html_elements(endpoint, "img")
  src <- if (length(images)) html_attr(images[[1L]], "src") else ""
  alt <- if (length(images)) html_attr(images[[1L]], "alt") else ""
  resolved <- if (nzchar(src)) {
    normalizePath(
      file.path(dirname(html_path), URLdecode(src)),
      winslash = "/",
      mustWork = FALSE
    )
  } else {
    ""
  }
  data.frame(
    order = index,
    figure_id = figure_ids[[index]],
    image_count = length(images),
    caption_count = length(captions),
    caption = if (length(captions)) clean_text(captions[[1L]]) else "",
    image_src = src,
    image_alt = alt,
    source_path = resolved,
    source_exists = nzchar(resolved) && file.exists(resolved),
    source_bytes = if (nzchar(resolved) && file.exists(resolved)) {
      as.numeric(file.info(resolved)$size)
    } else {
      NA_real_
    },
    pass = length(images) == 1L &&
      length(captions) == 1L &&
      nzchar(if (length(captions)) clean_text(captions[[1L]]) else "") &&
      !is.na(alt) && nzchar(alt) &&
      nzchar(resolved) && file.exists(resolved),
    stringsAsFactors = FALSE
  )
})
figure_audit <- do.call(rbind, figure_rows)
write_csv(figure_audit, "figure_endpoint_audit.csv")

all_id_nodes <- html_elements(document, "[id]")
all_ids <- html_attr(all_id_nodes, "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
duplicate_ids <- unique(all_ids[duplicated(all_ids)])
duplicate_audit <- if (length(duplicate_ids)) {
  data.frame(
    id = duplicate_ids,
    occurrences = vapply(duplicate_ids, function(id) sum(all_ids == id), integer(1)),
    pass = FALSE,
    stringsAsFactors = FALSE
  )
} else {
  data.frame(
    id = character(),
    occurrences = integer(),
    pass = logical(),
    stringsAsFactors = FALSE
  )
}
write_csv(duplicate_audit, "duplicate_id_audit.csv")

header_rows <- lapply(table_endpoints, function(endpoint) {
  endpoint_id <- html_attr(endpoint, "id")
  table <- html_element(endpoint, "table.gt_table")
  nodes <- html_elements(table, "[headers]")
  if (!length(nodes)) return(NULL)
  do.call(rbind, lapply(nodes, function(node) {
    tokens <- strsplit(trimws(html_attr(node, "headers")), "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    do.call(rbind, lapply(tokens, function(token) {
      matches <- xml_find_all(table, sprintf(".//*[@id='%s']", token))
      data.frame(
        endpoint = endpoint_id,
        element = xml_name(node),
        header_token = token,
        matches_in_table = length(matches),
        resolves_to_th = length(matches) == 1L &&
          identical(xml_name(matches[[1L]]), "th"),
        pass = length(matches) == 1L &&
          identical(xml_name(matches[[1L]]), "th"),
        stringsAsFactors = FALSE
      )
    }))
  }))
})
header_audit <- do.call(rbind, Filter(Negate(is.null), header_rows))
write_csv(header_audit, "table_header_reference_audit.csv")

idref_attributes <- c(
  "headers", "aria-labelledby", "aria-describedby", "for", "list",
  "aria-controls", "aria-owns", "aria-activedescendant"
)
idref_rows <- lapply(idref_attributes, function(attribute) {
  nodes <- html_elements(document, sprintf("[%s]", attribute))
  if (!length(nodes)) return(NULL)
  do.call(rbind, lapply(nodes, function(node) {
    tokens <- strsplit(trimws(html_attr(node, attribute)), "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    do.call(rbind, lapply(tokens, function(token) {
      matches <- sum(all_ids == token)
      data.frame(
        attribute = attribute,
        element = xml_name(node),
        token = token,
        matches_in_document = matches,
        pass = matches == 1L,
        stringsAsFactors = FALSE
      )
    }))
  }))
})
idref_audit <- do.call(rbind, Filter(Negate(is.null), idref_rows))
write_csv(idref_audit, "document_idref_audit.csv")

doc_cache <- new.env(parent = emptyenv())
fragment_resolves_once <- function(target_path, fragment) {
  if (!nzchar(fragment)) return(TRUE)
  if (!grepl("[.]html?$", target_path, ignore.case = TRUE)) return(TRUE)
  key <- normalizePath(target_path, winslash = "/", mustWork = TRUE)
  if (!exists(key, envir = doc_cache, inherits = FALSE)) {
    assign(key, read_html(key), envir = doc_cache)
  }
  target_doc <- get(key, envir = doc_cache, inherits = FALSE)
  target_ids <- html_attr(html_elements(target_doc, "[id]"), "id")
  sum(target_ids == fragment, na.rm = TRUE) == 1L
}

anchor_nodes <- html_elements(document, "a[href]")
anchor_nodes <- anchor_nodes[outside_source_modal(anchor_nodes)]
hrefs <- html_attr(anchor_nodes, "href")
link_text <- vapply(anchor_nodes, clean_text, character(1))
link_rows <- lapply(seq_along(anchor_nodes), function(index) {
  href <- hrefs[[index]]
  external <- grepl("^(https?|mailto|tel):", href, ignore.case = TRUE)
  data_uri <- grepl("^data:", href, ignore.case = TRUE)
  unsupported <- grepl("^[A-Za-z][A-Za-z0-9+.-]*:", href) &&
    !external && !data_uri
  forbidden <- !external && !data_uri && (
    grepl("[.]qmd($|[?#])", href, ignore.case = TRUE) ||
      grepl("file://", href, fixed = TRUE) ||
      grepl("_build", href, fixed = TRUE) ||
      grepl("/Users/", href, fixed = TRUE) ||
      grepl("^[A-Za-z]:[/\\\\]", href)
  )
  path_part <- sub("[?#].*$", "", href)
  fragment <- if (grepl("#", href, fixed = TRUE)) {
    URLdecode(sub("^[^#]*#", "", href))
  } else {
    ""
  }
  if (external || data_uri) {
    resolved <- ""
    target_exists <- TRUE
    fragment_ok <- TRUE
    kind <- if (external) "external" else "data"
  } else if (unsupported) {
    resolved <- ""
    target_exists <- FALSE
    fragment_ok <- FALSE
    kind <- "unsupported_scheme"
  } else {
    resolved <- if (!nzchar(path_part)) {
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
    }
    target_exists <- file.exists(resolved)
    fragment_ok <- target_exists && fragment_resolves_once(resolved, fragment)
    kind <- "local"
  }
  data.frame(
    link_text = link_text[[index]],
    href = href,
    kind = kind,
    resolved_path = resolved,
    target_exists = target_exists,
    fragment = fragment,
    fragment_resolves_once = fragment_ok,
    forbidden_internal_target = forbidden,
    pass = !forbidden && !unsupported && target_exists && fragment_ok,
    stringsAsFactors = FALSE
  )
})
link_audit <- do.call(rbind, link_rows)
write_csv(link_audit, "reader_link_audit.csv")

main_anchors <- html_elements(main, "a[href]")
main_anchors <- main_anchors[outside_source_modal(main_anchors)]
main_anchor_text <- vapply(main_anchors, clean_text, character(1))
registration_index <- grepl("^(DEV|REP|IMP)-[0-9]{3}$", main_anchor_text)
registration_nodes <- main_anchors[registration_index]
registration_text <- main_anchor_text[registration_index]
registration_href <- html_attr(registration_nodes, "href")
registration_fragment <- sub("^[^#]*#", "", registration_href)
registration_audit <- data.frame(
  link_text = registration_text,
  href = registration_href,
  fragment = registration_fragment,
  target_is_central = grepl(
    "preregistration_deviations[.]html#",
    registration_href
  ),
  pass = grepl("preregistration_deviations[.]html#", registration_href),
  stringsAsFactors = FALSE
)
write_csv(registration_audit, "registration_link_audit.csv")

site_labels <- c(
  "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
  "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
  "Kumasi (GH)"
)
main_text <- clean_text(main)
site_audit <- data.frame(
  display_name = site_labels,
  occurrences = vapply(
    site_labels,
    function(label) {
      starts <- gregexpr(label, main_text, fixed = TRUE)[[1L]]
      if (identical(starts[[1L]], -1L)) 0L else length(starts)
    },
    integer(1)
  ),
  stringsAsFactors = FALSE
)
site_audit$pass <- site_audit$occurrences > 0L
write_csv(site_audit, "country_site_audit.csv")

error_nodes <- html_elements(
  main,
  ".cell-output-error, .cell-output-warning, .cell-output-stderr"
)
raw_error_patterns <- c(
  "Error in ", "Execution halted", "Warning message:",
  "Quitting from lines"
)
raw_error_hits <- vapply(
  raw_error_patterns,
  function(pattern) grepl(pattern, main_text, fixed = TRUE),
  logical(1)
)
companion_links <- html_elements(
  document,
  "a[href*='H02_analysis_preparation.html']"
)
html_contracts <- data.frame(
  check = c(
    "main_unique",
    "table_count_and_order",
    "figure_count_and_order",
    "table_native_semantics",
    "figure_caption_alt_source",
    "unique_document_ids",
    "table_headers_resolve",
    "document_idrefs_resolve",
    "reader_links_resolve",
    "registration_links_22",
    "registration_anchors_18",
    "country_site_labels",
    "companion_navigation_link",
    "no_unresolved_crossrefs",
    "no_raw_error_warning_stderr"
  ),
  observed = c(
    length(main_nodes),
    length(table_ids),
    length(figure_ids),
    sum(table_audit$pass),
    sum(figure_audit$pass),
    length(duplicate_ids),
    sum(header_audit$pass),
    sum(idref_audit$pass),
    sum(link_audit$pass),
    nrow(registration_audit),
    length(unique(registration_audit$fragment)),
    sum(site_audit$pass),
    length(companion_links),
    sum(grepl("@(?:fig|tbl)-", main_text, perl = TRUE)),
    length(error_nodes) + sum(raw_error_hits)
  ),
  expected = c(
    "1", "15 in accepted order", "5 in accepted order", "15", "5",
    "0", as.character(nrow(header_audit)), as.character(nrow(idref_audit)),
    as.character(nrow(link_audit)), "22", "18", "9", ">=1", "0", "0"
  ),
  pass = c(
    length(main_nodes) == 1L,
    identical(table_ids, expected_tables),
    identical(figure_ids, expected_figures),
    all(table_audit$pass),
    all(figure_audit$pass),
    length(duplicate_ids) == 0L,
    all(header_audit$pass),
    all(idref_audit$pass),
    all(link_audit$pass),
    nrow(registration_audit) == 22L && all(registration_audit$pass),
    length(unique(registration_audit$fragment)) == 18L,
    all(site_audit$pass),
    length(companion_links) >= 1L,
    !grepl("@(?:fig|tbl)-", main_text, perl = TRUE),
    length(error_nodes) == 0L && !any(raw_error_hits)
  ),
  stringsAsFactors = FALSE
)
write_csv(html_contracts, "html_contracts.csv")

semantic_summary <- utils::read.csv(
  file.path(semantic_dir, "gt_html_semantic_post_render_summary.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(semantic_summary) == 1L)
ledger_path <- file.path(semantic_dir, semantic_summary$ledger_file[[1L]])
semantic_ledger <- utils::read.csv(
  ledger_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
post_raw <- read_file_raw(html_path)
reversed_raw <- apply_raw_replacements(post_raw, semantic_ledger, reverse = TRUE)
pre_document <- read_html(rawToChar(reversed_raw))
post_document <- read_html(rawToChar(post_raw))
normalized_dom_equal <- identical(
  normalized_dom_without_mutable_values(pre_document),
  normalized_dom_without_mutable_values(post_document)
)
pre_main <- html_element(pre_document, "main#quarto-document-content")
post_main <- html_element(post_document, "main#quarto-document-content")
visible_text_equal <- identical(clean_text(pre_main), clean_text(post_main))
semantic_reverse <- data.frame(
  semantic_dir = semantic_dir,
  disposition = semantic_summary$disposition,
  table_count = semantic_summary$table_count,
  id_count = semantic_summary$id_count,
  headers_count = semantic_summary$headers_count,
  total_substitutions = semantic_summary$total_substitutions,
  ledger_rows = nrow(semantic_ledger),
  expected_pre_sha256 = semantic_summary$pre_sha256,
  reversed_sha256 = sha256_raw(reversed_raw),
  expected_pre_bytes = semantic_summary$pre_bytes,
  reversed_bytes = length(reversed_raw),
  expected_post_sha256 = semantic_summary$post_sha256,
  current_post_sha256 = artifact_sha256(html_path),
  expected_post_bytes = semantic_summary$post_bytes,
  current_post_bytes = as.numeric(file.info(html_path)$size),
  normalized_dom_equal = normalized_dom_equal,
  visible_text_equal = visible_text_equal,
  pass = semantic_summary$disposition == "REPAIRED" &&
    semantic_summary$table_count == 15L &&
    semantic_summary$id_count == 152L &&
    semantic_summary$headers_count == 253L &&
    semantic_summary$total_substitutions == nrow(semantic_ledger) &&
    semantic_summary$pre_sha256 == sha256_raw(reversed_raw) &&
    semantic_summary$pre_bytes == length(reversed_raw) &&
    semantic_summary$post_sha256 == artifact_sha256(html_path) &&
    semantic_summary$post_bytes == as.numeric(file.info(html_path)$size) &&
    normalized_dom_equal && visible_text_equal,
  stringsAsFactors = FALSE
)
write_csv(semantic_reverse, "semantic_reverse_audit.csv")

stopifnot(
  all(table_audit$pass),
  all(figure_audit$pass),
  length(duplicate_ids) == 0L,
  all(header_audit$pass),
  all(idref_audit$pass),
  all(link_audit$pass),
  all(html_contracts$pass),
  semantic_reverse$pass
)

cat(sprintf(
  paste0(
    "HTML_SEMANTIC_AUDIT=PASS tables=%d figures=%d ids=%d headers=%d ",
    "idrefs=%d links=%d registration=%d/%d substitutions=%d\n"
  ),
  nrow(table_audit),
  nrow(figure_audit),
  length(all_ids),
  nrow(header_audit),
  nrow(idref_audit),
  nrow(link_audit),
  nrow(registration_audit),
  length(unique(registration_audit$fragment)),
  nrow(semantic_ledger)
))
